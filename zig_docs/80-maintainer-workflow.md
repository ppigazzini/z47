# Maintainer Workflow

This page explains how to keep the maintained `zig_docs/` set and the tracked
root entrypoint docs aligned with the live repository, and how to run the
upstream resync maintainer flow. It is about maintainer process, not build or
verification internals -- those live in the pages this one links to.

Use this page when a task changes the public maintainer contract documented in
`zig_docs/`, `CONTRIBUTING.md`, or `README.md`, or when advancing the
imported upstream pin.

Audit basis: 2026-07-10, upstream pin `0caee2adc`, Zig `0.16.0` stable.

## Where The Port Stands

The calculator core is fully ported to Zig; the upstream C tree is retained only
as the parity oracle (see [00-project-and-upstream.md](00-project-and-upstream.md)
and [50-zig-c-boundaries-and-rewrite-policy.md](50-zig-c-boundaries-and-rewrite-policy.md)).
Ongoing maintainer work is therefore idiomatic-Zig refinement and periodic
upstream resync, not further core porting. This page assumes that framing.

## Doc Stack At A Glance

| Surface | Role | Update when |
| --- | --- | --- |
| `zig_docs/` | stable maintainer docs for the live repo | build, rewrite, CI, package, or verification contracts changed |
| `../CONTRIBUTING.md` | contributor workflow contract | branch policy, focused verification, or doc-promotion rules changed |
| `../README.md` | root entry point and short Zig build quick start | the main Zig entrypoint or doc routing changed |

## Doc Promotion Workflow

Use one promotion workflow when a non-trivial change lands.

1. Gather evidence from the live tracked files and commands first. Verify every
   script path, target name, and cross-link against the repo before asserting
   it.
2. Keep exploratory notes and unsettled claims out of the maintained docs while
   the code or workflow is still moving. `zig_docs/` is for durable contracts;
   working notes belong on the ignored `__DEV/` surface and must never be
   committed or referenced by filename from a tracked page.
3. Promote the stable contract changes into every affected `zig_docs/` page and
   tracked root maintainer doc (`CONTRIBUTING.md`, `README.md`) in one pass.
4. Re-run the smallest relevant validation lane after the final doc edit (see
   [70-tests-and-verification.md](70-tests-and-verification.md)).

## Working Rules

- Document tracked repo surfaces only, not ignored local worktrees or ignored
  build outputs.
- Keep `zig_build/` documented as build-only, `zig_src/` as the live runtime Zig
  owners, and `zig_bridge/` as the near-retired legacy header shims (two
  headers; the former product-lane bridge `.c` seams are all retired into their
  Zig owners).
- Keep these tracked control files and their affected docs aligned when the
  imported-root or tracked top-level ownership contract changes:
  `../.github/project/source-ownership.txt`,
  `../.github/project/upstream-pin.env`,
  `../.github/project/upstream-port-ledger.tsv`,
  `../.github/project/retained-bridge-review.tsv`,
  `../.github/project/check-retained-bridge-ledger.py`,
  `../.github/project/report-c-dependency-status.py`,
  `../.github/project/report-upstream-refresh.py`, and
  `../.github/project/workflow-imported-root-paths.sh`.
- Use `bash ../.github/project/check-source-ownership.sh check-worktree` inside a
  linked-worktree layout pilot; keep the plain `check` subcommand for the
  maintained baseline and CI.
- Keep tracked root maintainer docs short and route detailed material into the
  numbered `zig_docs/` pages.
- Update the affected docs in the same change that updates the underlying build,
  workflow, or packaging contract.

## Upstream Resync Flow

The ordered procedure for advancing the imported upstream pin and re-deriving
the Zig port on top of it is the committed runbook
`.github/project/upstream-resync-runbook.md`. Follow it; do not duplicate its
steps here. The maintainer-process shape is:

1. Scope the changed paths only (never a whole-tree diff), then re-sync the
   deterministic seams (item table, constant-blob offsets, abi struct layout,
   constant/enum mirrors).
2. Re-port behavioral drift into the Zig owners in idiomatic fixed-width Zig,
   never by editing the imported `src/` oracle.
3. Run the one-command local gate before every push:
   ```bash
   bash .github/project/run-local-gate.sh
   ```
   This reproduces the full Linux CI verdict (governance guards + the
   host-parity build/test/oracle battery + the tracked-generated-artifact diff).
   `zig build sim` and `zig build test:unit` are NOT the gate. See
   [70-tests-and-verification.md](70-tests-and-verification.md).
4. Finalize the pin, ownership manifest, and port ledger together, and do not
   merge the sync branch to `main` until the local gate and the full CI matrix
   (Linux, macOS, and Windows) are green. The one lane the Linux gate cannot
   reproduce is the Windows LLP64 integer-width trap; the runbook records the
   guard and the CI Windows adjudicator.

### Re-syncing seam-and-core owners after a pin advance

The enforced contract on a pin advance is behavioral parity, not source-shape
correspondence (see
[50-zig-c-boundaries-and-rewrite-policy.md](50-zig-c-boundaries-and-rewrite-policy.md)).
How to re-sync a changed upstream file depends on which layer it maps to:

1. Seam layer (the build-managed `translate-c` roots): regenerate so the
   `extern struct` / `callconv(.c)` / offset shapes track the new pin. Seam
   drift is a generator rerun, never a hand edit.
2. Transliterated (hot) owner: apply the upstream C diff textually; shape
   correspondence still holds.
3. Idiomatized (cold) owner: do not expect a textual diff to apply. Run that
   owner's parity oracle (`zig build <owner>_parity`); a red oracle pinpoints
   the diverged function. Re-derive the behavior change in idiomatic Zig and
   confirm the oracle returns green -- a green oracle is proof of re-sync.

## Linked-Worktree Refresh Flow

Use a linked worktree when auditing or rehearsing an `upstream/master` refresh
without disturbing your active coding tree.

1. `git fetch upstream master`
2. `python3 ../.github/project/report-upstream-refresh.py --repo-root .. --head-rev upstream/master`
3. `git worktree add --detach ../z47-upstream-refresh upstream/master`
4. Inspect, diff, or rehearse the upstream refresh inside
   `../z47-upstream-refresh` while the active tree stays on your topic branch.
5. `git worktree remove ../z47-upstream-refresh` when the audit is complete.

Do not treat ignored local worktrees as tracked documentation surfaces.

## Codebase Status Flow

Use the tracked C-dependency status helper when a maintainer report needs
current first-party C telemetry.

1. Run `python3 ../.github/project/report-c-dependency-status.py --repo-root ..`.
2. Run `python3 ../.github/project/check-retained-bridge-ledger.py --repo-root ..`.
3. Keep these buckets separate in the maintained wording; do not collapse them
   into one closure sentence:
   - active product-build first-party C (target 0)
   - retained-bridge subset (the near-retired `zig_bridge/` shims)
   - repo-wide non-product parity, oracle, fake-runtime, and test first-party C
4. Keep the retained-bridge set justified through
   `../.github/project/retained-bridge-review.tsv`.
5. Pair the split C report with
   `python3 ../.github/project/report-upstream-refresh.py --repo-root .. --fetch`
   when the report also makes an upstream-sync freshness claim.

## Nested-Upstream Pilot Flow

Use the tracked pilot helper to re-measure a nested `upstream/` candidate. The
current stable recommendation is still no-go, so treat this as a pilot, not the
default maintainer layout.

1. `bash ../.github/project/nested-upstream-pilot.sh prepare ../z47-pilot <repo-relative-path ...>`
2. Run `bash .github/project/check-source-ownership.sh check-worktree` inside
   `../z47-pilot`.
3. Run the smallest relevant build or guard lane inside the pilot worktree.
4. `bash ../.github/project/nested-upstream-pilot.sh cleanup ../z47-pilot` when
   the comparison is complete.

## Local Roadmap Sync Flow

Use the tracked roadmap guard when a local roadmap file is part of a milestone
close-out review.

1. Run `python3 ../.github/project/check-local-roadmap-sync.py --roadmap <local-roadmap.md>`.
2. Treat any reported duplicate, missing, or drifted milestone row as a real
   validation failure, not editorial cleanup.
3. Keep tracked docs, tracked workflow files, and CI jobs free of hard
   references to local-only roadmap paths.

## When To Update Which Page

- update `../CONTRIBUTING.md` when branch policy, verification guidance, or
  maintainer promotion rules changed
- update `../README.md` when the root entry point or short Zig quick start
  changed
- update [README.md](README.md) when the maintainer doc index, read order, or
  page-routing contract changed
- update [00-project-and-upstream.md](00-project-and-upstream.md) when the
  imported-root pin, ownership vocabulary, or repo-baseline statement changed
- update [10-build-and-source-layout.md](10-build-and-source-layout.md) when
  entrypoints, pins, build-layout guidance, source-ownership manifest usage,
  upstream-ledger control files, or workflow imported-root helper usage changed
- update [10-build-and-source-layout.md](10-build-and-source-layout.md) and
  [50-zig-c-boundaries-and-rewrite-policy.md](50-zig-c-boundaries-and-rewrite-policy.md)
  together when naming strata, owner-vocabulary examples, or current
  naming-milestone closeout state changed
- update [20-zig-build-graph.md](20-zig-build-graph.md) when public targets,
  options, or build-domain ownership changed
- update [60-ci-and-release-workflow.md](60-ci-and-release-workflow.md) when CI
  jobs, artifacts, ownership guards, upstream-ledger guards, imported-root
  workflow guards, or local reproduction changed
- update [70-tests-and-verification.md](70-tests-and-verification.md) when the
  smallest rerun lane, ownership guard, upstream-ledger guard, workflow
  imported-root guard, or generated-surface validation contract changed

## Maintenance Rules

- If a change affects more than one maintained page, update them together.
- Prefer linking to the one page that owns a topic instead of repeating the same
  contract in multiple places.
- Re-check local links and at least one focused command or behavior surface
  before finishing the change.
