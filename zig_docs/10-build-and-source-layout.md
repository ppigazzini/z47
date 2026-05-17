# Build And Source Layout

This page is the canonical z47 ownership, build, and rebuild contract for the
live repository.

Read [00-project-and-upstream.md](00-project-and-upstream.md) first. This page
starts after the project and ownership boundary are already clear.

Use this page for build entrypoints, checked-in pins, build-domain layout, and
the local maintainer flow.

## Build At A Glance

- `build.zig` is the canonical maintained entrypoint.
- The repo-root `build.zig` stays small and routes work into `zig_build/`.
- `zig_build/` is build-only; live runtime Zig lives under `zig_src/` and
  retained runtime bridge C lives under `zig_bridge/`.
- imported upstream paths route through `UPSTREAM_ROOT` in
  `../.github/project/upstream-pin.env`; the current value `.` keeps the
  imported baseline at repo root
- `zig_build/zig_dist.py` now resolves imported packaging resources through
  that same `UPSTREAM_ROOT` pin instead of assuming repo-root `res/` paths.
- `../.github/project/nested-upstream-pilot.sh` is the tracked M13 helper for
  measuring an `upstream/` candidate in a linked worktree without changing the
  maintained baseline.
- The imported `Makefile` and Meson files remain audit and parity references,
  not the maintained z47 control plane.
- Host, docs, firmware, and packaging work all route through `zig build`.
- Deterministic generated sources and data refresh through public `zig build`
  steps rather than ad hoc scripts.

## Build-Relevant File Layout

```text
repo root
|- build.zig
|- zig_build/
|  |- common.zig
|  |- host.zig
|  |- host/
|  |- firmware.zig
|  |- dist.zig
|  |- tools/
|  |- leaf/
|  |- state/
|  `- zig_dist.py
|- zig_src/
|  |- leaf/
|  `- state/
|- zig_bridge/
|  `- state/
|- .github/
|  |- zig-toolchain.env
|  |- workflows/
|  `- project/
|     |- upstream-pin.env
|     |- source-ownership.txt
|     |- check-source-ownership.sh
|     |- zig-c-boundaries.txt
|     `- check-zig-c-boundaries.sh
|- zig_docs/
|- docs/code/
|  |- conf.py
|  |- Doxyfile
|  `- requirements.txt
|- src/
|  |- c47/
|  |- c47-gtk/
|  |- c47-dmcp/
|  `- c47-dmcp5/
|- dep/
|  |- decNumberICU/
|  |- DMCP_SDK/
|  `- DMCP5_SDK/
|- res/
|  |- fonts/
|  |- testPgms/
|  `- dist-docs/
|- LIBRARY/
|- BUILD.md
|- README.md
|- CONTRIBUTING.md
|- ZIG-README.md
|- Makefile
|- meson.build
|- meson_options.txt
`- tag2ver.py
```

## Install And Build Behavior

The live Zig build graph installs into the active Zig prefix. Keep the
maintained docs focused on the public `zig build` entrypoints and the tracked
source surfaces they act on, not on ignored build-output directories.

## Checked-In Defaults And Pins

Checked-in build defaults currently come from these files:

- `../.github/zig-toolchain.env`: pins Zig `0.16.0`
- `../.github/project/upstream-pin.env`: pins the imported upstream commit and
  repository URL plus the current imported upstream root
- `../.github/project/source-ownership.txt`: records the tracked top-level
  z47-owned roots and imported-upstream roots used by CI and source manifests
- `../.github/project/workflow-imported-root-paths.sh`: resolves the
  workflow-owned imported-root paths used by docs install,
  generated-artifact proof, and host package staging
- `../.github/project/zig-c-boundaries.txt`: records the approved checked-in
  `@cImport` and direct `extern` boundary files
- `../docs/code/requirements.txt`: pins the Python package set needed for
  `zig build docs`

The live project-specific Zig options are:

- `-Dci-commit-tag=<string>`: optional version tag input for packaging
- `-Draspberry=<bool>`: Raspberry Pi layout switch, default `false`
- `-Ddecnumber-fastmul=<bool>`: `DECNUMBER_FASTMUL` switch, default `true`
- `-Ddmcp-package=<int>`: DMCP package selector for `dmcp` and `dmcpr47`,
  default `4`

## Repository Ownership Map

Top-level z47-owned overlay paths:

- `build.zig`
- `zig_build/`
- `zig_src/`
- `zig_bridge/`
- `.github/`
- `zig_docs/`

The tracked top-level ownership split used by CI lives in
`../.github/project/source-ownership.txt`. The source-manifest job and the
source-ownership guard both read from that manifest, and the workflow
imported-root guard reads `../.github/project/workflow-imported-root-paths.sh`,
so docs and CI use tracked vocabulary files for the current repo-root
baseline.

Imported upstream-shaped paths consumed directly by the live build graph:

- `src/`
- `dep/`
- `docs/`
- `res/`
- `LIBRARY/`
- `Makefile`
- `meson.build`
- `meson_options.txt`
- `tag2ver.py`

Maintenance rule:

- add new z47-owned build logic under `zig_build/` or `.github/`
- add new live runtime Zig under `zig_src/`
- add new retained runtime bridge C under `zig_bridge/`
- do not place new z47-owned files under imported upstream-shaped directories
  unless the task is intentionally editing the canonical imported owner path
- use a linked worktree when rehearsing an `upstream/master` refresh instead of
  repurposing the active coding tree
- use `../.github/project/nested-upstream-pilot.sh` when you need to re-measure
  a nested `upstream/` layout; do not change `UPSTREAM_ROOT` in the maintained
  tree unless that pilot is explicitly promoted

## Build Entry Points

Public maintainer entrypoints currently exposed by `zig build --help` include:

- `zig build sim`
- `zig build simr47`
- `zig build both`
- `zig build both_asan`
- `zig build simulator_smoke`
- `zig build logical_shortint_parity`
- `zig build rotate_bits_parity`
- `zig build stack_state_parity`
- `zig build register_metadata_parity`
- `zig build flags_parity`
- `zig build memory_parity`
- `zig build program_serialization_parity`
- `zig build calc_state_parity`
- `zig build keyboard_state_parity`
- `zig build keyboard_statusbar_flags_regression`
- `zig build test`
- `zig build test_asan`
- `zig build repeattest`
- `zig build fonts`
- `zig build constants`
- `zig build catalogs`
- `zig build testPgms`
- `zig build generated`
- `zig build docs`
- `zig build dmcp`
- `zig build dmcpr47`
- `zig build dmcp5`
- `zig build dmcp5r47`
- `zig build dist_linux`
- `zig build dist_macos`
- `zig build dist_windows`
- `zig build dist`
- `zig build distS`

The full grouped command list is documented in `../ZIG-README.md`,
`20-zig-build-graph.md`, and the live `zig build --help` output.

## Local Start-To-End Pipeline

Use this order when you want the same local maintainer flow that the repo now
expects from a clean shell:

1. Ensure `zig version` matches the checked-in pin from
   `../.github/zig-toolchain.env`.
2. Ensure host prerequisites are installed for the lane you plan to run.
3. Export the `xlsxio_xlsx2csv` helper and its runtime library path when the
   lane depends on generated artifacts, docs, or packaging.
4. Run the smallest focused lane first, usually `zig build logical_shortint_parity`,
  `zig build rotate_bits_parity`, `zig build test`,
  `zig build stack_state_parity`, `zig build register_metadata_parity`,
  `zig build generated`, `zig build docs`, or one firmware target.
5. Rerun the broader host or package lane only after the focused lane passes.

## Generated And Cleaned Surfaces

`zig build generated` refreshes the tracked generated calculator sources and
test-program data owned by the host build graph.

`zig build clean` clears derived build state. After a clean-based lane, rerun
`zig build generated` before checking generated diffs or committing generated
output changes.

## Practical Maintenance Rules

- Keep `build.zig` small. Push domain-specific logic down into `zig_build/`.
- Keep `ZIG-README.md`, `zig_docs/`, and the live `zig build --help` surface
  aligned when target names or options change.
- Keep imported upstream build files readable and auditable even when they are
  no longer the maintained control plane.
- Change canonical owner paths first. Do not patch generated outputs by hand.
- Keep docs, CI workflows, and pins aligned in the same change when a contract
  changes.