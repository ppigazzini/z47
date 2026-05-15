# Maintainer Workflow

This page explains how to keep the maintained docs aligned with the live,
tracked repository surfaces.

Use this page when a task changes the public maintainer contract documented in
`zig_docs/`, `README.md`, or `ZIG-README.md`.

## Doc Stack At A Glance

| Surface | Role | Update when |
| --- | --- | --- |
| `zig_docs/` | stable maintainer docs for the live repo | build, rewrite, CI, package, or verification contracts changed |
| `../README.md` | top-level project entrypoint | maintainers need a root docs pointer or short project-level note |
| `../CONTRIBUTING.md` | contributor workflow contract | branch policy, focused verification, or doc-promotion rules changed |
| `../ZIG-README.md` | short Zig build quick start | the main Zig entrypoint or doc routing changed |

## Promotion Workflow

Use one promotion workflow when a non-trivial change lands.

1. Gather evidence from the live tracked files and commands first.
2. Keep exploratory notes and unsettled claims out of the maintained docs while
   the code or workflow is still moving.
3. Promote the stable contract changes into every affected `zig_docs/` page and
   root entrypoint doc in one pass.
4. Re-run the smallest relevant validation lane after the final doc edit.

## Working Rules

- Document tracked repo surfaces, not ignored local worktrees or ignored build
  outputs.
- Keep `zig_docs/` focused on durable maintainer contracts, not temporary notes
  or iteration detail.
- Keep root entrypoint docs short and route detailed material into the numbered
  `zig_docs/` pages.
- Update the affected docs in the same change that updates the underlying build,
  workflow, or packaging contract.

## When To Update Which Page

- update `../README.md` when the top-level maintainer doc entrypoint changed
- update `../CONTRIBUTING.md` when branch policy, verification guidance, or
  maintainer promotion rules changed
- update `../ZIG-README.md` when the short Zig quick start changed
- update [README.md](README.md) when the maintainer doc index, read order, or
  page-routing contract changed
- update [10-build-and-source-layout.md](10-build-and-source-layout.md) when
  entrypoints, pins, or build-layout guidance changed
- update [20-zig-build-graph.md](20-zig-build-graph.md) when public targets,
  options, or build-domain ownership changed
- update [60-ci-and-release-workflow.md](60-ci-and-release-workflow.md) when CI
  jobs, artifacts, or local reproduction changed
- update [70-tests-and-verification.md](70-tests-and-verification.md) when the
  smallest rerun lane or generated-surface validation contract changed

## Maintenance Rules

- If a change affects more than one maintained page, update them together.
- Prefer linking to the one page that owns a topic instead of repeating the
  same contract in multiple places.
- Re-check local links and at least one focused command or behavior surface
  before finishing the change.