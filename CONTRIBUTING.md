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
  overlay files such as `build.zig`, `zig_build/`, `zig_src/`,
  `zig_bridge/`, `.github/`, `zig_docs/`, this contributor note, and the root
  entrypoint docs.
- `.github/project/upstream-pin.env` records `UPSTREAM_ROOT=.` for the current
  repo-root imported baseline, and `.github/project/source-ownership.txt`
  records the tracked top-level ownership split used by CI.
- `.github/project/nested-upstream-pilot.sh` is the tracked M13 helper for
  measuring a nested `upstream/` candidate in a linked worktree while the
  maintained baseline stays at `UPSTREAM_ROOT=.`.
- `build.zig` is the sole supported build entrypoint for maintained z47 work.

## Branch And CI Policy

- local `master` must track `upstream/master`
- GitHub `main` is the default z47 branch
- GitHub `github_ci` is the dedicated CI validation branch
- day-to-day work should happen on a local topic branch,
  then land on `main` or `github_ci` on GitHub to trigger CI
- GitHub CI is the primary validation surface; local checks should reproduce
  the smallest relevant CI lane before broader pushes

## Upstream Refresh Flow

When auditing or rehearsing an `upstream/master` refresh, use a linked worktree
instead of repurposing the active coding tree.

1. `git fetch upstream master`
2. `git worktree add --detach ../z47-upstream-refresh upstream/master`
3. Do the upstream audit, diff, or rebase rehearsal inside
  `../z47-upstream-refresh` while leaving the active tree on your topic branch.
4. `git worktree remove ../z47-upstream-refresh` when the refresh rehearsal is
  complete.

Keep tracked-doc updates focused on the main repository tree. Do not document
ignored local worktrees as if they were tracked repo surfaces.

## Nested-Upstream Pilot Flow

The current M13 recommendation is no-go: keep the repo-root import as the
maintained baseline. When you need to re-measure that decision, use the tracked
pilot helper instead of editing the maintained tree in place.

1. `bash .github/project/nested-upstream-pilot.sh prepare ../z47-m13-pilot <repo-relative-path ...>`
2. Run `bash .github/project/check-source-ownership.sh check-worktree` inside
  `../z47-m13-pilot`.
3. Run the smallest representative build or guard lane inside the pilot
  worktree.
4. `bash .github/project/nested-upstream-pilot.sh cleanup ../z47-m13-pilot`
  when the comparison is complete.

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
- imported-root layout, top-level ownership, or source-manifest changes: rerun
  `zig build --help --summary none`, then
  `bash .github/project/check-source-ownership.sh`; use
  `bash .github/project/check-source-ownership.sh check-worktree` inside a
  linked-worktree layout pilot before treating the candidate as valid
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