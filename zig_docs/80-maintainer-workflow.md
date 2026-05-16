# Maintainer Workflow

This page explains how to keep the maintained docs aligned with the live,
tracked repository surfaces.

Use this page when a task changes the public maintainer contract documented in
`zig_docs/`, `CONTRIBUTING.md`, or `ZIG-README.md`.

## Doc Stack At A Glance

| Surface | Role | Update when |
| --- | --- | --- |
| `zig_docs/` | stable maintainer docs for the live repo | build, rewrite, CI, package, or verification contracts changed |
| `../CONTRIBUTING.md` | contributor workflow contract | branch policy, focused verification, or doc-promotion rules changed |
| `../ZIG-README.md` | short Zig build quick start | the main Zig entrypoint or doc routing changed |

## Promotion Workflow

Use one promotion workflow when a non-trivial change lands.

1. Gather evidence from the live tracked files and commands first.
2. Keep exploratory notes and unsettled claims out of the maintained docs while
   the code or workflow is still moving.
3. Promote the stable contract changes into every affected `zig_docs/` page and
  tracked maintainer doc in one pass.
4. Re-run the smallest relevant validation lane after the final doc edit.

## Working Rules

- Document tracked repo surfaces, not ignored local worktrees or ignored build
  outputs.
- Keep `zig_build/` documented as build-only, `zig_src/` as live runtime Zig,
  and `zig_bridge/` as retained runtime bridge C.
- Keep `../.github/project/source-ownership.txt`,
  `../.github/project/upstream-pin.env`,
  `../.github/project/workflow-imported-root-paths.sh`, and the affected docs
  aligned when the imported-root or tracked top-level ownership contract
  changes.
- Use `bash ../.github/project/check-source-ownership.sh check-worktree`
  inside a linked-worktree layout pilot; keep the plain `check` command for
  the maintained baseline and CI.
- Keep `zig_docs/` focused on durable maintainer contracts, not temporary notes
  or iteration detail.
- Keep tracked root maintainer docs short and route detailed material into the
  numbered `zig_docs/` pages.
- Update the affected docs in the same change that updates the underlying build,
  workflow, or packaging contract.

## Linked-Worktree Refresh Flow

Use a linked worktree when auditing or rehearsing an `upstream/master` refresh.

1. `git fetch upstream master`
2. `git worktree add --detach ../z47-upstream-refresh upstream/master`
3. Inspect, diff, or rehearse the upstream refresh inside
   `../z47-upstream-refresh` while leaving the active coding tree on your topic
   branch.
4. `git worktree remove ../z47-upstream-refresh` when the audit or rehearsal is
   complete.

Do not treat ignored local worktrees as tracked documentation surfaces.

## Nested-Upstream Pilot Flow

Use the tracked M13 helper when you need to re-measure a nested `upstream/`
candidate. The current stable recommendation is still no-go, so treat this as a
pilot flow, not as the default maintainer layout.

1. `bash ../.github/project/nested-upstream-pilot.sh prepare ../z47-m13-pilot <repo-relative-path ...>`
2. Run `bash .github/project/check-source-ownership.sh check-worktree` inside
  `../z47-m13-pilot`.
3. Run the smallest relevant build or guard lane inside the pilot worktree.
4. Use the helper report as the changed-path, rebase, and CI-clarity evidence.
5. `bash ../.github/project/nested-upstream-pilot.sh cleanup ../z47-m13-pilot`
  when the comparison is complete.

## When To Update Which Page

- update `../CONTRIBUTING.md` when branch policy, verification guidance, or
  maintainer promotion rules changed
- update `../ZIG-README.md` when the short Zig quick start changed
- update [README.md](README.md) when the maintainer doc index, read order, or
  page-routing contract changed
- update [00-project-and-upstream.md](00-project-and-upstream.md) when the
  imported-root pin, ownership vocabulary, or repo-baseline statement changed
- update [10-build-and-source-layout.md](10-build-and-source-layout.md) when
  entrypoints, pins, build-layout guidance, source-ownership manifest usage,
  or workflow imported-root helper usage changed
- update [20-zig-build-graph.md](20-zig-build-graph.md) when public targets,
  options, or build-domain ownership changed
- update [60-ci-and-release-workflow.md](60-ci-and-release-workflow.md) when CI
  jobs, artifacts, ownership guards, imported-root workflow guards, or local
  reproduction changed
- update [70-tests-and-verification.md](70-tests-and-verification.md) when the
  smallest rerun lane, ownership guard, workflow imported-root guard, or
  generated-surface validation contract changed

## Maintenance Rules

- If a change affects more than one maintained page, update them together.
- Prefer linking to the one page that owns a topic instead of repeating the
  same contract in multiple places.
- Re-check local links and at least one focused command or behavior surface
  before finishing the change.