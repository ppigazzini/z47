# Host And Generated Surfaces

This page maps the host simulator, the generated-artifact flows and their
generators, the docs build, and the retained host dependency contract owned by
the current Zig build graph. It is precise about which host pieces are Zig and
which are retained C.

Read [20-zig-build-graph.md](20-zig-build-graph.md) first. This page assumes the
domain split is already clear.

Last verified: 2026-10-05, Zig `0.17.0` stable. The upstream pin is
`UPSTREAM_COMMIT` in `../.github/project/upstream-pin.env`.

## Host Surface At A Glance

The host-facing build graph lives under `../build/host/` and owns:

- the C47 and R47 desktop simulator builds
- the Xvfb-backed X11 simulator smoke probe
- the deterministic generator executables and the generated-output refresh steps
- the Sphinx and Doxygen docs orchestration
- the host-platform glue (native paths, import libraries, link config)

The host regression and per-owner parity lanes also register here, but their
canonical inventory lives in
[70-tests-and-verification.md](70-tests-and-verification.md).

## What Is Zig And What Is Retained C

The GTK host application layer is ported to Zig. The calculator core is fully
ported to Zig (the owners under `../src/`). The host still links external C
libraries, compiles one vendored C library, and compiles the C its generators
emit. Be honest about the split:

| Host piece | State |
| --- | --- |
| GTK simulator application layer | ported to Zig (`../build/host/gtk_*.zig`) |
| calculator core | ported to Zig (the `../src/` owners) |
| `../upstream/src/c47-gtk/*.c` (the C the Zig host replaces) | filtered out of the build |
| `../upstream/dep/decNumberICU` | retained vendored C, compiled by Zig |
| generated `rasterFontsData.c`, `constantPointers.c`, `constantPointers2.c` | generator-emitted C, compiled by Zig into the simulator |
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
`test_asan`, `repeattest`) and the per-owner parity and oracle lanes;
`../build.zig` registers the native Zig unit lane (`test:unit`).

`test`, `test_asan`, and `repeattest` run the imported upstream corpus list
`../upstream/src/testSuite/tests/testSuiteList.txt` and no z47 list; `test` also
runs the `keyboard_statusbar_flags_regression` harness. That is the
point: the shared testSuite is the measuring instrument, so z47 runs it
unmodified and never appends to it. z47's own focused coverage goes in its own
lanes with their own lists -- `../build/tests/testSuiteList_logical_boolean_ops.txt`
driving `logical_boolean_ops_suite` is the pattern -- and in the per-owner parity
harnesses, never in the imported corpus.

These lanes depend on the `testPgms` refresh, so running one rewrites
`build/generated/testPgms.bin`.

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
- the `translate_c` package pinned in `../build.zig.zon`, fetched on the first
  configure into the ignored `zig-pkg/`; every `zig build` imports it through
  `../build/common.zig`

The vendored `../upstream/dep/decNumberICU` is compiled by Zig into the simulator
and into every generator except the fonts generator; it is not a system
dependency.

The fonts generator needs the catalog sorting order extracted from
`../upstream/res/fonts/sortingOrder.xlsx`. On Linux and macOS it prefers the
`xlsxio_xlsx2csv` helper when it is on `PATH` (with `$HOME/.local/lib` as an extra
library path) and otherwise falls back to the checked-in
`../build/tools/xlsx_to_sorting_csv.py` Python converter; on Windows it always
uses the Python converter. The xlsxio helper is optional.

## Generated Artifact Inventory

The generator executables live under `../build/tools/`. Each refresh step
runs a generator and copies its output to a source-tree path. Only the testPgms
image is tracked; the `upstream/src/generated/` outputs are gitignored, and the
build graph feeds the simulator and firmware from the generators directly, not
from those copies.

| Step | Generator | Outputs |
| --- | --- | --- |
| `fonts` | `ttf2_raster_fonts.zig` | `upstream/src/generated/rasterFontsData.c` |
| `constants` | `generate_constants.zig` | `upstream/src/generated/constantPointers.c`, `constantPointers.h`, `constantPointers2.c` |
| `catalogs` | `generate_catalogs.zig` | `upstream/src/generated/softmenuCatalogs.h` |
| `testPgms` (alias `testpgms`) | `generate_testpgms.zig` | `build/generated/testPgms.bin` |
| `generated` | all of the above | every output above |

`../.github/project/workflow-imported-root-paths.sh generated-artifacts` prints
that list; it is the vocabulary CI and the local gate's final diff both consume,
so read it from there rather than from this table. That diff is `git diff
--exit-code`, so of these paths it can only ever flag the tracked
`build/generated/testPgms.bin`.

**The testPgms image is the one output that does NOT live in the imported tree.**
It is z47's own baseline under `build/generated/`, deliberately outside
`upstream/`: writing it to `upstream/res/testPgms/testPgms.bin` put a z47 build
product inside the imported tree and kept that tree from ever matching its pin.
Upstream's own copy stays byte-identical to the pin and
`check-imported-tree-pin.py` holds it there.

Regenerate `build/generated/testPgms.bin` (`zig build testPgms` or
`zig build generated`) after any item-table growth. The testSuite does not read
it -- it loads upstream's `res/testPgms/testPgms.bin` from its upstream working
directory -- so a stale image fails the tracked-artifact diff (the local gate's
last step and CI's "Compare tracked generated artifacts"), not a test lane.

## Generator Boundary And Retained C

The generator executables are manual Zig owners, but they still cross explicit,
build-managed C boundaries:

- their narrow C interop enters through the checked-in `translate-c` root headers
  under `../build/tools/translate_c/`, translated by the official `translate-c`
  package through `addTranslator` in `../build/common.zig` and wired in
  `../build/host/generated.zig`
- `generate_constants`, `generate_catalogs` and `generate_testpgms` compile the
  vendored `../upstream/dep/decNumberICU` sources; the fonts generator does not
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
- the Python docs packages `breathe` and `furo` listed in
  `../upstream/docs/code/requirements.txt`, plus `sphinx` (the step checks
  `import sphinx, breathe, furo`)

After verifying those tools and packages are present, the step runs
`python3 -m sphinx -M html upstream/docs/code zig-out/docs/code`.

This lane documents the imported code surface under `upstream/docs/code`. It does
not replace the maintainer-facing `docs/` set, which is this directory.

## Platform Notes That Matter

- `../build/host/platform.zig` is the central host-platform glue surface.
- Windows host builds and packaging need explicit native-path and import-library
  handling for GTK and FreeType rather than generic `-lfoo` names.
- At startup the simulator walks up from its executable directory (up to eight
  levels) to the first directory holding `res/c47_pre.css` or
  `upstream/res/c47_pre.css` and changes into it (`relocateToResourceDir` in
  `../build/host/gtk_c47_main.zig`), so a build under `zig-out/bin` finds
  `../upstream/res/` with no copy or link.

## Change Rules

- Keep new host build or platform glue inside `../build/host/`.
- Keep generated output ownership explicit through the public `zig build` refresh
  steps instead of standalone scripts.
- Keep host dependency docs honest. Do not imply the host simulator is pure Zig
  while it still links GTK 3, GMP, or PulseAudio and compiles
  `../upstream/dep/decNumberICU`.
- Route any new generator C interop through a checked-in `translate-c` root and
  the allowlist in
  [50-zig-c-boundaries-and-rewrite-policy.md](50-zig-c-boundaries-and-rewrite-policy.md).
- Update [70-tests-and-verification.md](70-tests-and-verification.md) whenever a
  host-facing command name, generated output path, or smallest rerun lane
  changes.
