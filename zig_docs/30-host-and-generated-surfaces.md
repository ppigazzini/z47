# Host And Generated Surfaces

This page maps the host simulator, host test, generated-artifact, and docs
build surfaces owned by the current Zig build graph.

Read [20-zig-build-graph.md](20-zig-build-graph.md) first. This page assumes
the domain split is already clear.

## Host Surface At A Glance

The current host-facing build graph owns all of these surfaces through
`../zig_build/host/`:

- desktop simulator builds for C47 and R47
- focused rewrite-parity executables for the live Zig slices
- grouped host regression lanes
- native Zig C-sanitized host builds and tests
- deterministic generator execution
- tracked generated artifact refresh
- Sphinx and Doxygen docs orchestration

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
- `zig build both_asan`: builds both host simulators with native Zig C
  sanitizing enabled

The host build graph still compiles imported upstream C sources for the main
simulator and GTK surfaces, but it now replaces the imported `stack.c` owner
with `../zig_build/state/stack.zig` plus the explicit helper seam in
`../zig_build/state/stack_runtime_helpers.c`. The presence of a Zig-owned build
graph still does not mean the host simulator is already a pure-Zig application.

## Host Test Steps

Current grouped host test steps:

- `zig build logical_shortint_parity`
- `zig build stack_state_parity`
- `zig build test`
- `zig build test_asan`
- `zig build repeattest`

`zig build stack_state_parity` compares the live Zig stack-state owner with the
imported `stack.c` oracle against a fake runtime. `zig build test`,
`zig build test_asan`, and `zig build repeattest` cover the broader retained
host regression surface after that focused slice passes.

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

The generator entrypoints now live under `../zig_build/tools/`. They are
Zig-owned executables, but some still use narrow approved C boundaries rather
than full manual rewrites of every dependency they touch.

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
- Keep host dependency docs honest. Do not imply the host simulator is pure Zig
  while GTK, GMP, FreeType, and imported upstream C still participate in the
  build.
- Update [70-tests-and-verification.md](70-tests-and-verification.md) whenever a
  host-facing command name, generated output list, or smallest rerun lane
  changes.