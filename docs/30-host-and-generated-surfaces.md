# Host And Generated Surfaces

This page maps the host simulator, the generated-artifact flows and their
generators, the docs build, and the retained host dependency contract owned by
the current Zig build graph. It is precise about which host pieces are Zig and
which are retained C.

Read [20-zig-build-graph.md](20-zig-build-graph.md) first. This page assumes the
domain split is already clear.

Last verified: 2026-08-16, Zig `0.16.0` stable. The upstream pin is stated once, in
[00-project-and-upstream.md](00-project-and-upstream.md).

## Host Surface At A Glance

The host-facing build graph lives under `../build/host/` and owns:

- the C47 and R47 desktop simulator builds
- the Xvfb-backed X11 simulator smoke probe
- the deterministic generator executables and the tracked generated-artifact
  refresh steps
- the Sphinx and Doxygen docs orchestration
- the host-platform glue (native paths, import libraries, link config)

The host regression and per-owner parity lanes also register here, but their
canonical inventory lives in
[70-tests-and-verification.md](70-tests-and-verification.md).

## What Is Zig And What Is Retained C

The GTK host application layer is ported to Zig. The calculator core is fully
ported to Zig (the owners under `../src/`). The host still links external C
libraries and compiles one vendored C library. Be honest about the split:

| Host piece | State |
| --- | --- |
| GTK simulator application layer | ported to Zig (`../build/host/gtk_*.zig`) |
| calculator core | ported to Zig (the `../src/` owners) |
| `../upstream/src/c47-gtk/*.c` (the C the Zig host replaces) | filtered out of the build |
| `../upstream/dep/decNumberICU` | retained vendored C, compiled by Zig |
| GTK 3 | retained external C library, linked from Zig |
| GMP | retained external C library, linked from Zig |
| FreeType 2 | retained external C library, linked by the fonts generator |
| PulseAudio (optional) | retained external C library, linked when present |

The presence of a Zig-owned host build graph does not make the host simulator a
pure-Zig application: it still links GTK 3, GMP, and (optionally) PulseAudio, and
it still compiles the vendored `../upstream/dep/decNumberICU`.

## The GTK Filter Boundary

`../build/host/context.zig` collects the imported `../upstream/src/c47-gtk` C files,
then `../build/host/gtk_gui.zig` `filterGtkSources` drops every path listed in
`../build/host/gtk_gui_legacy_gtk_sources.txt`. That manifest currently lists
all seven upstream GTK C files (`c47-gtk.c`, `gtkGui.c`, and the `hal/` set), so
no first-party GTK C reaches the simulator link. The former
`gtk_gui_legacy.c` re-entry bridge is retired; the ported main, GUI, HAL, I/O, and
LCD surfaces run entirely from the Zig objects added by
`gtk_gui.addToModule` (`gtk_gui_runtime.zig`, `gtk_hal_runtime.zig`,
`gtk_io_runtime.zig`, `gtk_lcd_runtime.zig`, and the wider `gtk_gui_*.zig` set).

The imported `../upstream/src/c47-gtk/*.c` files stay in the tree as read-only audit and
parity reference; they are not compiled.

## Host Simulator Steps

| Step | What it builds |
| --- | --- |
| `sim` (or bare `zig build`) | the C47 simulator |
| `simr47` | the R47 simulator |
| `both` | both host simulators |
| `both_asan` | both host simulators built with UBSan instrumentation (build only, never run); the name says ASan and means UBSan -- see [75-debugging.md](75-debugging.md) |
| `simulator_smoke` | both simulators plus the Xvfb-backed LCD, keyboard, and pointer smoke probe |

## Host Regression And Parity Lanes

The host build graph also registers the grouped regression lanes (`test`,
`test_asan`, `repeattest`), the native Zig unit lane (`test:unit`), and the
per-owner parity and oracle lanes.

`test`, `test_asan`, and `repeattest` all run the imported upstream corpus list
`../upstream/src/testSuite/tests/testSuiteList.txt` and nothing else. That is the
point: the shared testSuite is the measuring instrument, so z47 runs it
unmodified and never appends to it. z47's own focused coverage goes in its own
lanes with their own lists -- `../build/tests/testSuiteList_logical_boolean_ops.txt`
driving `logical_boolean_ops_suite` is the pattern -- and in the per-owner parity
harnesses, never in the imported corpus.

These lanes depend on the `testPgms` refresh, so the generated test-program image
is rebuilt before they run.

The full lane inventory, the smallest rerun per owner, and the parity-oracle
model live in [70-tests-and-verification.md](70-tests-and-verification.md). Do not
duplicate that inventory here.

## Retained Host Dependency Contract

Host simulator, generator, test, and host-package builds depend on:

- `pkg-config`
- GTK 3 development files
- GMP development files
- FreeType 2 development files (required by the fonts generator, not the
  simulator link)
- optional PulseAudio development files (`libpulse-simple`); audio is auto-enabled
  only when `pkg-config` finds it
- `python3`

The vendored `../upstream/dep/decNumberICU` is compiled by Zig into the simulator
and the generators; it is not a system dependency.

The fonts generator needs the catalog sorting order extracted from
`../upstream/res/fonts/sortingOrder.xlsx`. It prefers the `xlsxio_xlsx2csv` helper when it is
on `PATH` (using `$HOME/.local/lib` as an extra library path) and otherwise falls
back to the checked-in `../build/tools/xlsx_to_sorting_csv.py` Python
converter, so the xlsxio helper is now optional rather than a hard runtime
requirement.

## Generated Artifact Inventory

The generator executables live under `../build/tools/`. Each refresh step
runs a generator and copies its output over the tracked source-tree path.

| Step | Generator | Tracked outputs |
| --- | --- | --- |
| `fonts` | `ttf2_raster_fonts.zig` | `upstream/src/generated/rasterFontsData.c` |
| `constants` | `generate_constants.zig` | `upstream/src/generated/constantPointers.c`, `constantPointers.h`, `constantPointers2.c` |
| `catalogs` | `generate_catalogs.zig` | `upstream/src/generated/softmenuCatalogs.h` |
| `testPgms` (alias `testpgms`) | `generate_testpgms.zig` | `build/generated/testPgms.bin` |
| `generated` | all of the above | every tracked output above |

`../.github/project/workflow-imported-root-paths.sh generated-artifacts` prints
that list; it is the vocabulary CI and the local gate's final diff both consume,
so read it from there rather than from this table.

**The testPgms image is the one output that does NOT live in the imported tree.**
It is z47's own baseline under `build/generated/`, deliberately outside
`upstream/`: writing it to `upstream/res/testPgms/testPgms.bin` put a z47 build
product inside the imported tree and kept that tree from ever matching its pin.
Upstream's own copy stays byte-identical to the pin and
`check-imported-tree-pin.py` holds it there.

Regenerate `build/generated/testPgms.bin` (via `zig build testPgms` or
`zig build generated`) after any item-table growth; a stale image fails the host
regression lanes.

## Generator Boundary And Retained C

The generator executables are manual Zig owners, but they still cross explicit,
build-managed C boundaries rather than ad hoc `@cImport` blocks:

- their narrow C interop enters through the checked-in `translate-c` root headers
  under `../build/tools/translate_c/` and the `Build.addTranslateC` wiring in
  `../build/host/generated.zig`
- every generator compiles the vendored `../upstream/dep/decNumberICU` sources
- the fonts generator links FreeType 2 (via its `translate-c` root and
  `linkRasterFontsFreetype`)
- `generate_catalogs` and `generate_testpgms` additionally compile a subset of
  the imported `../upstream/src/c47` sources and link GTK 3 and GMP

These boundaries are governed by the allowlist and guard described in
[50-zig-c-boundaries-and-rewrite-policy.md](50-zig-c-boundaries-and-rewrite-policy.md).

## Docs Surface

`zig build docs` is the canonical docs lane for the imported `../upstream/docs/code` tree.

Current requirements:

- `python3`
- `doxygen`
- the Python docs packages (`sphinx`, `breathe`, `furo`) from
  `../upstream/docs/code/requirements.txt`

After verifying those tools and packages are present, the step runs
`python3 -m sphinx -M html upstream/docs/code zig-out/docs/code`.

This lane documents the imported code surface under `upstream/docs/code`. It does
not replace the maintainer-facing `docs/` set, which is this directory.

## Platform Notes That Matter

- `../build/host/platform.zig` is the central host-platform glue surface.
- Windows host builds and packaging need explicit native-path and import-library
  handling for GTK and FreeType rather than generic `-lfoo` names.
- The macOS smoke lane expects the checked-out `../upstream/res/` asset tree to be
  visible from the executable directory during startup.

## Change Rules

- Keep new host build or platform glue inside `../build/host/`.
- Keep generated output ownership explicit through the public `zig build` refresh
  steps instead of standalone scripts.
- Keep host dependency docs honest. Do not imply the host simulator is pure Zig
  while it still links GTK 3, GMP, or PulseAudio and compiles
  `../upstream/dep/decNumberICU`.
- Route any new generator C interop through a checked-in `translate-c` root and
  the allowlist in
  [50-zig-c-boundaries-and-rewrite-policy.md](50-zig-c-boundaries-and-rewrite-policy.md);
  do not add `@cImport` blocks to generator sources.
- Update [70-tests-and-verification.md](70-tests-and-verification.md) whenever a
  host-facing command name, generated output path, or smallest rerun lane
  changes.
