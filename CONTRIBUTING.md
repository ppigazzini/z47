# Contributing To z47

## Page Contract

This page records the maintained contributor workflow for the live z47
repository.

Use it for branch policy, the supported build entrypoint, focused verification,
and the maintainer-doc promotion rules that must stay aligned with the tracked
repo surfaces.

## Project Baseline

- z47 is the maintained Zig-first build, CI, packaging, documentation, and
  staged rewrite overlay for the upstream C47 calculator application.
- The authoritative upstream source repository is
  `https://gitlab.com/rpncalculators/c43.git`.
- The repo root carries a pinned imported upstream working tree plus z47-owned
  overlay files such as `build.zig`, `zig_build/`, `.github/`, `zig_docs/`,
  this contributor note, and the root entrypoint docs.
- `build.zig` is the sole supported build entrypoint for maintained z47 work.

## Branch And CI Policy

- local `master` must track `upstream/master`
- GitHub `main` is the default z47 branch
- GitHub `github_ci` is the dedicated CI validation branch
- day-to-day work should happen on a local topic branch,
  then land on `main` or `github_ci` on GitHub to trigger CI
- GitHub CI is the primary validation surface; local checks should reproduce
  the smallest relevant CI lane before broader pushes

## Supported Build Entry Points

Use `zig build --help --summary none` to inspect the live public target set.

Common maintainer entrypoints:

- `zig build sim`
- `zig build simulator_smoke`
- `zig build logical_shortint_parity`
- `zig build stack_state_parity`
- `zig build register_metadata_parity`
- `zig build flags_parity`
- `zig build memory_parity`
- `zig build program_serialization_parity`
- `zig build calc_state_parity`
- `zig build keyboard_state_parity`
- `zig build keyboard_statusbar_flags_regression`
- `zig build test`
- `zig build generated`
- `zig build docs`
- `zig build dmcp`
- `zig build dmcp5`
- `zig build dist_linux`

The imported `Makefile` and Meson files remain audit and parity-reference
surfaces. They are not the maintained z47 control plane.

## Focused Verification Rules

- docs-only maintainer changes: verify each key claim against the live files,
  then rerun `zig build --help --summary none` when target names or options are
  described
- build-graph or target-surface changes: rerun `zig build --help --summary
  none`, then the smallest affected target
- rewrite or boundary changes: rerun the focused parity or regression lane for
  that slice before broader host or firmware checks
- package, firmware, or release-proof changes: rerun the matching `dist_*` or
  firmware target on the matching host OS when possible

If a lane cannot run locally, record the exact blocker and the narrower file or
workflow evidence that was checked instead.

## Documentation Promotion Rules

- keep `README.md` short and maintainer-facing
- keep `ZIG-README.md` as the short Zig quick start
- keep `zig_docs/` as the stable maintainer-doc surface for the live repo
- update this file, `README.md`, `ZIG-README.md`, and the affected `zig_docs/`
  pages in the same change when a public build, CI, packaging, or verification
  contract changes
- do not imply a pure-Zig result while retained C libraries or vendor code
  remain explicit dependencies

## Retained Dependency Reminder

The current maintained build still keeps these retained C or vendor surfaces
explicit:

- imported upstream calculator sources under `src/`
- `dep/decNumberICU`
- GTK 3
- FreeType 2
- GMP
- SwissMicros `DMCP_SDK` and `DMCP5_SDK`

Do not remove or downplay those dependencies in docs or reviews unless the same
change also lands the verified replacement and its parity proof.