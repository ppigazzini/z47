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
- The pinned imported upstream working tree is mounted under `upstream/`. The
  repo root carries only z47-owned files: `build.zig`, `build/`,
  `src/`, `bridge/`, `.github/`, `docs/`, this contributor note,
  and the root entrypoint docs.
- `.github/project/upstream-pin.env` records `UPSTREAM_ROOT=upstream`, and
  `.github/project/source-ownership.txt` records the tracked top-level
  ownership split used by CI. Two upstream dotfiles are deliberate root
  exceptions, hand-reconciled on resync because git only honours them there:
  `.gitmodules` (submodule paths) and `.gitattributes` (line-ending policy).
- `.github/project/upstream-port-ledger.tsv` records the maintainer triage
  ledger that must move with any tracked upstream pin change.
- `.github/project/report-upstream-refresh.py` summarizes new upstream commits,
  changed imported paths, and classifies the resulting z47 touchpoints so
  runtime/build Zig, legacy C wrappers, and manifest-only follow-up are
  visible before a pin change lands.
- `.github/project/workflow-imported-root-paths.sh` records the workflow-owned
  imported-root vocabulary used by docs install, generated-artifact proof, and
  host package staging in GitHub Actions.
- `.github/project/upstream_paths.py` resolves upstream-relative paths for the
  governance gates. Paths recorded *as data* -- correspondence TSVs, the port
  ledger, dependency baselines, generated seam comments -- stay upstream-relative
  (`src/c47/foo.c`), as do git pathspecs aimed at a sibling upstream clone. Only
  filesystem access resolves through `UPSTREAM_ROOT`.
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
2. `python3 .github/project/report-upstream-refresh.py --repo-root . --head-rev upstream/master`
3. `git worktree add --detach ../z47-upstream-refresh upstream/master`
4. Do the upstream audit, diff, or rebase rehearsal inside
  `../z47-upstream-refresh` while leaving the active tree on your topic branch.
5. When the maintained pin changes, update `.github/project/upstream-pin.env`
  and add the matching row in `.github/project/upstream-port-ledger.tsv` in the
  tracked repo tree before treating the refresh as ready.
6. `git worktree remove ../z47-upstream-refresh` when the refresh rehearsal is
  complete.

Keep tracked-doc updates focused on the main repository tree. Do not document
ignored local worktrees as if they were tracked repo surfaces.

## Supported Build Entry Points

Use `zig build --help --summary none` to inspect the live public target set.

Common maintainer entrypoints:

- `zig build sim`
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
- imported-root layout, upstream-pin, top-level ownership, or source-manifest
  changes: rerun
  `zig build --help --summary none`, then
  `python3 .github/project/report-upstream-refresh.py --repo-root . --fetch`, then
  `python3 .github/project/check-upstream-port-ledger.py --repo-root .`, then
  `bash .github/project/check-source-ownership.sh`, then
  `python3 .github/project/check-harness-includes.py --repo-root .`, then
  `python3 .github/project/check-clean-step-targets.py --repo-root .`, then
  `bash .github/project/workflow-imported-root-paths.sh check-workflow`.
  Run `check-source-ownership.sh` in BOTH modes: bare `check` audits the committed
  tree's added paths, `check-worktree` only validates manifest coverage, and a
  layout move has already landed with the first mode red while the second was green.
  Then run the host parity battery: a layout change breaks the parity ORACLE lanes,
  which include upstream `.c` by relative path, and no product build or governance
  gate can see that -- 13 of 14 once died silently this way
- build-graph or target-surface changes: rerun `zig build --help --summary
  none`, then the smallest affected target
- local roadmap or milestone-summary changes in reviewer-only docs: rerun
  `python3 .github/project/check-local-roadmap-sync.py --roadmap <local-roadmap.md>`
  against the local roadmap file and treat any drift as a real validation
  failure; keep tracked docs, tracked workflow files, and CI jobs free of hard
  references to local-only roadmap paths
- rewrite or boundary changes: rerun the focused parity or regression lane for
  that slice before broader host or firmware checks
- a lane is green and the behaviour is still wrong: stop rerunning and switch
  tools. `docs/75-debugging.md` owns the detector-to-bug-class map, the
  C-vs-Zig differential against the pinned upstream build, and the catalogue of
  ways a green run has hidden a defect here before
- package, firmware, or release-proof changes: rerun the matching `dist_*` or
  firmware target on the matching host OS when possible, and rerun
  `bash .github/project/workflow-imported-root-paths.sh check-workflow` when
  the change touches workflow-owned imported inputs or package staging

If a lane cannot run locally, record the exact blocker and the narrower file or
workflow evidence that was checked instead.

## Documentation Promotion Rules

- keep `README.md` short: the z47 root entry point and Zig quick start
- keep `docs/` as the stable maintainer-doc surface for the live repo
- update this file, `README.md`, and the affected `docs/` pages in the
  same change when a public build, CI, packaging, or verification contract
  changes
- update `docs/10-build-and-source-layout.md` and
  `docs/50-zig-c-boundaries-and-rewrite-policy.md` in the same change when
  naming strata, naming examples, or current naming-milestone status changes
- update `docs/README.md` when the maintainer-doc index, page-routing
  contract, or top-level project framing changes
- state a fact on one page only. When another page needs it, link the owner
  rather than repeating the value: an uncounted copy is how a stale number
  survives. Where a number must appear, put the command that derives it beside
  it
- upstream's own subjects -- the C architecture, its memory model per platform,
  its detectors, and the calculator's vocabulary -- belong to the companion
  c47-r47-ci doc set. Link it (`docs/90-official-references.md` holds the
  page map) instead of restating it here; the two repositories are not gated
  against each other, so a copied number cannot be kept honest
- do not imply a pure-Zig result while legacy C libraries or vendor code
  remain explicit dependencies

## Retained Dependency Reminder

The current maintained build still keeps these legacy C or vendor surfaces
explicit:

- imported upstream calculator sources under `src/`
- `dep/decNumberICU`
- GTK 3
- FreeType 2
- GMP
- SwissMicros `DMCP_SDK` and `DMCP5_SDK`

Do not remove or downplay those dependencies in docs or reviews unless the same
change also lands the verified replacement and its parity proof.
