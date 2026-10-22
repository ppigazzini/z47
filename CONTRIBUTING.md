# Contributing To z47

## Page Contract

This page records the maintained contributor workflow for the live z47
repository.

Use it for branch policy, the supported build entrypoint, focused verification,
and the maintainer-doc promotion rules that must stay aligned with the tracked
repo surfaces.

## Project Baseline

- z47 re-implements the upstream C47 calculator application in Zig, with its own
  build, CI, packaging and documentation.
- The authoritative upstream source repository is
  `https://gitlab.com/rpncalculators/c43.git`.
- The pinned imported upstream working tree is mounted under `upstream/`. The
  rest of the repo root is z47's, listed under `[z47-owned]` in
  `.github/project/source-ownership.txt`.
- `.github/project/upstream-pin.env` records `UPSTREAM_ROOT=upstream`, and
  `.github/project/source-ownership.txt` records the tracked top-level
  ownership split used by CI. `.gitmodules`, `.gitattributes` and `.gitignore`
  are root files reconciled with upstream's by hand on a resync: git reads
  `.gitmodules` only at the root, and the other two must cover the whole
  repository, not only `upstream/`.
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

- upstream `master` is fetched through the `upstream` remote
  (`UPSTREAM_REMOTE_NAME` and `UPSTREAM_BRANCH` in
  `.github/project/upstream-pin.env`) and imported as a snapshot under
  `upstream/`, never merged
- GitHub `main` is the default z47 branch
- GitHub `github_ci` is the dedicated CI validation branch
- day-to-day work should happen on a local topic branch,
  then land on `main` or `github_ci` on GitHub to trigger CI
- run the local gate (`PATH="$PWD/.venv/bin:$PATH" bash
  .github/project/run-local-gate.sh`) before pushing; a change is not done until
  it passes, and CI adjudicates the lanes it cannot run, Windows and macOS among
  them

## Upstream Refresh Flow

Auditing an `upstream/master` refresh in a linked worktree is described in
`docs/80-maintainer-workflow.md`, and the resync itself, including everything
that moves with the pin, in `.github/project/upstream-resync-runbook.md`.

## Supported Build Entry Points

Use `zig build --help --summary none` to inspect the live public target set.

Common maintainer entrypoints are listed in `docs/README.md` (Build Entry
Points); `docs/20-zig-build-graph.md` owns the full graph.

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
  `python3 .github/project/check-imported-tree-pin.py --repo-root .`, then
  `bash .github/project/check-source-ownership.sh`, then
  `python3 .github/project/check-harness-includes.py --repo-root .`, then
  `python3 .github/project/check-clean-step-targets.py --repo-root .`, then
  `python3 .github/project/check-oracle-provenance.py --repo-root .`, then
  `python3 .github/project/check-harness-constant-copies.py --repo-root .`, then
  `python3 .github/project/check-imported-root-references.py --repo-root .`, then
  `bash .github/project/workflow-imported-root-paths.sh check-workflow`.
  Run `check-source-ownership.sh` in BOTH modes: bare `check` audits the committed
  tree's added paths, `check-worktree` only validates manifest coverage, and a
  layout move has already landed with the first mode red while the second was green.
  Then run the host parity battery (`bash .github/project/run-host-parity-battery.sh`,
  or the whole gate): a layout change breaks the parity ORACLE lanes,
  which include upstream `.c` by relative path, and no product build or governance
  gate can see that -- 13 of 14 once died silently this way
- build-graph or target-surface changes: rerun `zig build --help --summary
  none`, then the smallest affected target
- local roadmap or milestone-summary changes in reviewer-only docs: follow
  `docs/80-maintainer-workflow.md` (Local Roadmap Sync Flow)
- rewrite or boundary changes: rerun the focused parity or regression lane for
  that slice before broader host or firmware checks
- a lane is green and the behaviour is still wrong: stop rerunning and switch
  tools. `docs/75-debugging.md` owns the detector-to-bug-class map, the
  C-vs-Zig differential against the pinned upstream build, and the catalogue of
  ways a green run has hidden a defect here before
- package, firmware, or release-proof changes: rerun the matching `dist_*` or
  firmware target on the matching host OS when possible, `zig build
  dmcp_pkgs_all` whenever a firmware-linked owner changed (a package variant can
  fail to link while `dmcp` and `dmcp5` pass; see
  `docs/40-firmware-and-distribution.md`), and rerun
  `bash .github/project/workflow-imported-root-paths.sh check-workflow` when
  the change touches workflow-owned imported inputs or package staging

If a lane cannot run locally, record the exact blocker and the narrower file or
workflow evidence that was checked instead.

## Documentation Promotion Rules

- keep `README.md` short: the z47 root entry point and Zig quick start
- keep `docs/` as the stable maintainer-doc surface for the live repo
- update this file, `README.md`, `AGENTS.md`, and the affected `docs/` pages in the
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

- imported upstream calculator sources under `upstream/src/`
- `upstream/dep/decNumberICU`
- GTK 3
- FreeType 2
- GMP (a host system library; cross-built from source for the firmware)
- PulseAudio (optional, host)
- SwissMicros `DMCP_SDK` and `DMCP5_SDK`

Do not remove or downplay those dependencies in docs or reviews unless the same
change also lands the verified replacement and its parity proof.
