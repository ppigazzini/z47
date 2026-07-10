# Host And Generated Surfaces

This page maps the host simulator, the generated-artifact flows and their
generators, the docs build, and the retained host dependency contract owned by
the current Zig build graph. It is precise about which host pieces are Zig and
which are retained C.

Read [20-zig-build-graph.md](20-zig-build-graph.md) first. This page assumes the
domain split is already clear.

Audit basis: 2026-07-10, upstream pin `0caee2adc`, Zig `0.16.0` stable.

## Host Surface At A Glance

The host-facing build graph lives under `../zig_build/host/` and owns:

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
ported to Zig (the owners under `../zig_src/`). The host still links external C
libraries and compiles one vendored C library. Be honest about the split:

| Host piece | State |
| --- | --- |
| GTK simulator application layer | ported to Zig (`../zig_build/host/gtk_*.zig`) |
| calculator core | ported to Zig (the `../zig_src/` owners) |
| `../src/c47-gtk/*.c` (the C the Zig host replaces) | filtered out of the build |
| `dep/decNumberICU` | retained vendored C, compiled by Zig |
| GTK 3 | retained external C library, linked from Zig |
| GMP | retained external C library, linked from Zig |
| FreeType 2 | retained external C library, linked by the fonts generator |
| PulseAudio (optional) | retained external C library, linked when present |

The presence of a Zig-owned host build graph does not make the host simulator a
pure-Zig application: it still links GTK 3, GMP, and (optionally) PulseAudio, and
it still compiles the vendored `dep/decNumberICU`.

## The GTK Filter Boundary

`../zig_build/host/context.zig` collects the upstream `../src/c47-gtk` C files,
then `../zig_build/host/gtk_gui.zig` `filterGtkSources` drops every path listed in
`../zig_build/host/gtk_gui_legacy_gtk_sources.txt`. That manifest currently lists
all seven upstream GTK C files (`c47-gtk.c`, `gtkGui.c`, and the `hal/` set), so
no first-party GTK C reaches the simulator link. The former
`gtk_gui_legacy.c` re-entry bridge is retired; the ported main, GUI, HAL, I/O, and
LCD surfaces run entirely from the Zig objects added by
`gtk_gui.addToModule` (`gtk_gui_runtime.zig`, `gtk_hal_runtime.zig`,
`gtk_io_runtime.zig`, `gtk_lcd_runtime.zig`, and the wider `gtk_gui_*.zig` set).

The imported `../src/c47-gtk/*.c` files stay in the tree as read-only audit and
parity reference; they are not compiled.

## Host Simulator Steps

| Step | What it builds |
| --- | --- |
| `sim` (or bare `zig build`) | the C47 simulator |
| `simr47` | the R47 simulator |
| `both` | both host simulators |
| `both_asan` | both host simulators with native Zig C sanitizing |
| `simulator_smoke` | both simulators plus the Xvfb-backed LCD, keyboard, and pointer smoke probe |

## Host Regression And Parity Lanes

The host build graph also registers the grouped regression lanes (`test`,
`test_asan`, `repeattest`), the native Zig unit lane (`test:unit`), and the
per-owner parity and oracle lanes. `test`, `test_asan`, and `repeattest` run both
the upstream corpus at `../src/testSuite/tests/testSuiteList.txt` and the z47
overlay list at `../zig_build/tests/testSuiteList_z47.txt`, so z47 adds focused
coverage without editing the imported upstream corpus. These lanes depend on the
`testPgms` refresh, so the tracked test-program image is regenerated before they
run.

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

The vendored `dep/decNumberICU` is compiled by Zig into the simulator and the
generators; it is not a system dependency.

The fonts generator needs the catalog sorting order extracted from
`res/fonts/sortingOrder.xlsx`. It prefers the `xlsxio_xlsx2csv` helper when it is
on `PATH` (using `$HOME/.local/lib` as an extra library path) and otherwise falls
back to the checked-in `../zig_build/tools/xlsx_to_sorting_csv.py` Python
converter, so the xlsxio helper is now optional rather than a hard runtime
requirement.

## Generated Artifact Inventory

The generator executables live under `../zig_build/tools/`. Each refresh step
runs a generator and copies its output over the tracked source-tree path.

| Step | Generator | Tracked outputs |
| --- | --- | --- |
| `fonts` | `ttf2_raster_fonts.zig` | `src/generated/rasterFontsData.c` |
| `constants` | `generate_constants.zig` | `src/generated/constantPointers.c`, `constantPointers.h`, `constantPointers2.c` |
| `catalogs` | `generate_catalogs.zig` | `src/generated/softmenuCatalogs.h` |
| `testPgms` (alias `testpgms`) | `generate_testpgms.zig` | `res/testPgms/testPgms.bin` |
| `generated` | all of the above | every tracked output above |

Regenerate `res/testPgms/testPgms.bin` (via `zig build testPgms` or
`zig build generated`) after any item-table growth; a stale image fails the host
regression lanes.

## Generator Boundary And Retained C

The generator executables are manual Zig owners, but they still cross explicit,
build-managed C boundaries rather than ad hoc `@cImport` blocks:

- their narrow C interop enters through the checked-in `translate-c` root headers
  under `../zig_build/tools/translate_c/` and the `Build.addTranslateC` wiring in
  `../zig_build/host/generated.zig`
- every generator compiles the vendored `dep/decNumberICU` sources
- the fonts generator links FreeType 2 (via its `translate-c` root and
  `linkRasterFontsFreetype`)
- `generate_catalogs` and `generate_testpgms` additionally compile a subset of
  upstream `../src/c47` sources and link GTK 3 and GMP

These boundaries are governed by the allowlist and guard described in
[50-zig-c-boundaries-and-rewrite-policy.md](50-zig-c-boundaries-and-rewrite-policy.md).

## Docs Surface

`zig build docs` is the canonical docs lane for the imported `../docs/code` tree.

Current requirements:

- `python3`
- `doxygen`
- the Python docs packages (`sphinx`, `breathe`, `furo`) from
  `../docs/code/requirements.txt`

After verifying those tools and packages are present, the step runs
`python3 -m sphinx -M html docs/code <install-prefix>/docs/code`.

This lane documents the imported code surface under `docs/code`. It does not
replace the maintainer-facing `zig_docs/` set.

## Platform Notes That Matter

- `../zig_build/host/platform.zig` is the central host-platform glue surface.
- Windows host builds and packaging need explicit native-path and import-library
  handling for GTK and FreeType rather than generic `-lfoo` names.
- The macOS smoke lane expects the checked-out `res/` asset tree to be visible
  from the executable directory during startup.

## Change Rules

- Keep new host build or platform glue inside `../zig_build/host/`.
- Keep generated output ownership explicit through the public `zig build` refresh
  steps instead of standalone scripts.
- Keep host dependency docs honest. Do not imply the host simulator is pure Zig
  while it still links GTK 3, GMP, or PulseAudio and compiles `dep/decNumberICU`.
- Route any new generator C interop through a checked-in `translate-c` root and
  the allowlist in
  [50-zig-c-boundaries-and-rewrite-policy.md](50-zig-c-boundaries-and-rewrite-policy.md);
  do not add `@cImport` blocks to generator sources.
- Update [70-tests-and-verification.md](70-tests-and-verification.md) whenever a
  host-facing command name, generated output path, or smallest rerun lane
  changes.
