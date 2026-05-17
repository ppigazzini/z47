# Host And Generated Surfaces

This page maps the host simulator, host test, generated-artifact, and docs
build surfaces owned by the current Zig build graph.

Read [20-zig-build-graph.md](20-zig-build-graph.md) first. This page assumes
the domain split is already clear.

## Host Surface At A Glance

The current host-facing build graph owns all of these surfaces through
`../zig_build/host/`:

- desktop simulator builds for C47 and R47
- live X11 simulator smoke coverage for C47 and R47
- focused rewrite-parity executables for the live Zig slices
- grouped host regression lanes
- native Zig C-sanitized host builds and tests
- deterministic generator execution
- tracked generated artifact refresh
- Sphinx and Doxygen docs orchestration

## Value Boundary

This page records the live host build surface. It does not claim that the
current amount of Zig host orchestration is valuable by itself.

For this repo, a Zig-owned host layer earns its keep only when it replaces
buggy or intentionally retired C owners, fixes real platform or packaging
defects, or deletes more legacy build debt than it adds. If the same working
imported C simulator and the same effective dependency story still remain in
place, extra Zig orchestration is maintenance overhead rather than delivered
user value.

## Retained Host Dependency Split

Host simulator, generator, test, and host-package builds currently depend on:

- `pkg-config`
- GTK 3 development files
- FreeType 2 development files
- GMP development files
- optional PulseAudio development files for audio support
- `python3`

Generator-dependent host builds also require the xlsxio helper at runtime.

Current runtime expectations:

- executable on `PATH`: `xlsxio_xlsx2csv`
- loader-visible shared library: `libxlsxio_read`

If the helper is installed in a non-system prefix, export the matching library
path for the active platform before running generator-dependent lanes.

## Host Simulator Steps

Current public host simulator steps:

- `zig build sim`: builds the C47 simulator
- `zig build simr47`: builds the R47 simulator
- `zig build both`: builds both host simulators
- `zig build simulator_smoke`: builds both host simulators and runs the
  Xvfb-backed LCD, keyboard, and pointer smoke probe
- `zig build both_asan`: builds both host simulators with native Zig C
  sanitizing enabled

The host build graph still compiles imported upstream C sources for the main
simulator and GTK surfaces, but it now replaces the imported `stack.c` owner
with `../zig_src/state/stack.zig` plus the explicit helper seam in
`../zig_bridge/state/stack_runtime_helpers.c`, replaces the exported register
metadata accessors from `registers.c` with
`../zig_src/state/register_metadata.zig`, and replaces the exported
system-flag accessor and change-tracking surface from `flags.c` with
`../zig_src/state/flags.zig` plus retained wrapper sources under
`../zig_bridge/state/`. The current host lane also replaces the remaining
short-integer boolean logical owners under `../src/c47/logicalOps/` with
`../zig_src/leaf/logical_boolean_ops.zig`. The current host
lane also replaces the broader public keyboard command-entry surface with
`../zig_src/state/keyboard_state.zig` while freestanding firmware keeps the
retained owner through `../zig_bridge/state/keyboard_state_retained.c`.

The retained GTK boundary is still explicit: the imported
`../src/c47-gtk/gtkGui.c` path enters the host build through
`../zig_build/host/gtk_gui_retained.c` and
`../zig_build/host/gtk_button_signal_wrappers.c`. The presence of a Zig-owned
build graph still does not mean the host simulator is already a pure-Zig
application.

## Host Test Steps

Current grouped host test steps:

- `zig build logical_shortint_parity`
- `zig build rotate_bits_parity`
- `zig build logical_boolean_ops_suite`
- `zig build stack_state_parity`
- `zig build register_metadata_parity`
- `zig build flags_parity`
- `zig build memory_parity`
- `zig build program_serialization_parity`
- `zig build calc_state_parity`
- `zig build math_command_wrappers_parity`
- `zig build keyboard_state_parity`
- `zig build test`
- `zig build test_asan`
- `zig build repeattest`

`zig build rotate_bits_parity` compares the live Zig `rotateBits.c` owner
replacement with the imported oracle against a fake runtime. `zig build
logical_boolean_ops_suite` runs the host test harness against the focused
`and`, `or`, `not`, `nand`, `nor`, `xor`, and `xnor` command corpus after the
live Zig owner replacement for those files. `zig build
stack_state_parity` compares the live Zig stack-state owner with the imported
`stack.c` oracle against a fake runtime. `zig build register_metadata_parity`
does the same for the live register-metadata accessors against the imported
`registers.c` oracle surface in the host lane. `zig build flags_parity` does
the same for the exported system-flag accessor and change-tracking surface
against the imported `flags.c` oracle, including refresh-state,
clear-status-bar, and integer-base side effects. `zig build memory_parity`,
`zig build program_serialization_parity`, `zig build calc_state_parity`,
`zig build math_command_wrappers_parity`, and `zig build keyboard_state_parity`
extend the focused host parity coverage across the live stateful and math
command-owner Zig slices, including the simulator-only backup path, the shared
exp or Euler helper surface, and the broader public keyboard command
entrypoints.
`zig build test`, `zig build test_asan`, and `zig build repeattest` cover the
broader retained host regression surface after those focused slices pass.

`zig build test`, `zig build test_asan`, and `zig build repeattest` run both:

- the upstream list at `../src/testSuite/tests/testSuiteList.txt`
- the z47-owned overlay list at `../zig_build/tests/testSuiteList_z47.txt`

That split lets z47 add focused regression coverage without editing the
imported upstream corpus.

## Generated Artifact Inventory

The deterministic generated-artifact surface currently refreshes these tracked
surfaces:

| Step | Tracked outputs |
| --- | --- |
| `fonts` | tracked raster-font source refresh |
| `constants` | tracked generated constant-source refresh |
| `catalogs` | tracked generated catalog-source refresh |
| `testPgms` or `testpgms` | tracked generated test-program data refresh |
| `generated` | all tracked generated refresh surfaces above |

The generator entrypoints now live under `../zig_build/tools/`. Their narrow C
interop now enters through the checked-in `translate-c` root headers under
`../zig_build/tools/translate_c/` and the build-managed translation steps in
`../zig_build/host/generated.zig` rather than checked-in `@cImport` blocks in
the generator Zig sources. The generator executables remain manual Zig owners
even though retained decNumber, FreeType, and host-header surfaces still cross
that explicit build-managed boundary.

## Docs Surface

`zig build docs` is the canonical docs lane for `../docs/code`.

Current requirements:

- `python3`
- `doxygen`
- Python packages from `../docs/code/requirements.txt`

The current implementation runs `python3 -m sphinx -M html docs/code
<install-prefix>/docs/code` after verifying the required tools are available.

This lane documents the imported code surface under `docs/code`. It does not
replace the maintainer-facing `zig_docs/` set.

## Platform Notes That Matter

- `../zig_build/host/platform.zig` is the central host-platform glue surface.
- Windows host builds and packaging need explicit native-path and import-library
  handling for GTK and FreeType rather than relying on generic `-lfoo` names.
- The macOS smoke lane expects the checked-out `res/` asset tree to be visible
  from the executable directory during startup.

## Change Rules

- Keep new host build or platform glue inside `../zig_build/host/`.
- Keep generated output ownership explicit through the public `zig build`
  update steps instead of standalone scripts.
- Do not treat a Zig-owned host build layer as a success by itself. If a new
  Zig host surface does not replace retained C owners, fix a real host defect,
  or delete more legacy workflow debt than it adds, it is overhead.
- Keep host dependency docs honest. Do not imply the host simulator is pure Zig
  while GTK, GMP, FreeType, and imported upstream C still participate in the
  build.
- Update [70-tests-and-verification.md](70-tests-and-verification.md) whenever a
  host-facing command name, generated output list, or smallest rerun lane
  changes.