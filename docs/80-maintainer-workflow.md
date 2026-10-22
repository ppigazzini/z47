# Maintainer Workflow

This page explains how to keep the maintained `docs/` set and the tracked
root entrypoint docs aligned with the live repository, and how to run the
upstream resync maintainer flow. It is about maintainer process, not build or
verification internals -- those live in the pages this one links to.

Use this page when a task changes the public maintainer contract documented in
`docs/`, `CONTRIBUTING.md`, or `README.md`, or when advancing the
imported upstream pin.

Last verified: 2026-10-23, Zig `0.17.0` stable. The upstream pin is
`UPSTREAM_COMMIT` in `../.github/project/upstream-pin.env`. Commands on this page
run from the repo root.

## Where The Port Stands

The calculator core is fully ported to Zig.
[00-project-and-upstream.md](00-project-and-upstream.md) owns the port-status
split, including the C the imported tree still supplies: the vendored decNumber
compiled into every product, the generators the build runs, and the parity
references.
Ongoing maintainer work is therefore idiomatic-Zig refinement and periodic
upstream resync, not further core porting. This page assumes that framing.

## Doc Stack At A Glance

| Surface | Role | Update when |
| --- | --- | --- |
| `docs/` | stable maintainer docs for the live repo | build, rewrite, CI, package, or verification contracts changed |
| `../CONTRIBUTING.md` | contributor workflow contract | branch policy, focused verification, or doc-promotion rules changed |
| `../README.md` | root entry point and short Zig build quick start | the main Zig entrypoint or doc routing changed |
| `../AGENTS.md` (loaded through `../CLAUDE.md`) | agent entry point: setup, the gate, and the trap table that routes into `docs/` | the gate, the setup, or the page that owns a listed trap changed |

## Doc Promotion Workflow

Use one promotion workflow when a non-trivial change lands.

1. Gather evidence from the live tracked files and commands first. Verify every
   script path, target name, and cross-link against the repo before asserting
   it.
2. Keep exploratory notes and unsettled claims out of the maintained docs while
   the code or workflow is still moving. `docs/` is for durable contracts;
   working notes belong on the ignored `__DEV/` surface and must never be
   committed or referenced by filename from a tracked page.
3. Promote the stable contract changes into every affected `docs/` page and
   tracked root maintainer doc (`CONTRIBUTING.md`, `README.md`) in one pass.
4. Re-run the smallest relevant validation lane after the final doc edit (see
   [70-tests-and-verification.md](70-tests-and-verification.md)).

## Working Rules

- Document tracked repo surfaces only, not ignored local worktrees or ignored
  build outputs.
- Keep `build/` documented as build-only, `src/` as the live runtime Zig
  owners, and `bridge/` as the near-retired legacy header shims
  (`git ls-files bridge/` lists them; the former product-lane bridge `.c` seams
  are all retired into their Zig owners).
- Keep these tracked control files and their affected docs aligned when the
  imported-root or tracked top-level ownership contract changes:
  `../.github/project/source-ownership.txt`,
  `../.github/project/upstream-pin.env`,
  `../.github/project/upstream-port-ledger.tsv`,
  `../.github/project/retained-bridge-review.tsv`,
  `../.github/project/check-retained-bridge-ledger.py`,
  `../.github/project/report-c-dependency-status.py`,
  `../.github/project/imported-tree-divergences.txt`,
  `../.github/project/report-upstream-refresh.py`, and
  `../.github/project/workflow-imported-root-paths.sh`.
- Run `bash .github/project/check-source-ownership.sh` in both of its modes
  (plain `check` and `check-worktree`) after a layout or ownership change, as
  `../CONTRIBUTING.md`'s focused-verification rules say; the local gate and CI
  run only the plain `check`.
- Keep tracked root maintainer docs short and route detailed material into the
  numbered `docs/` pages.
- Update the affected docs in the same change that updates the underlying build,
  workflow, or packaging contract.

## Python Tooling Flow

The repo-owned Python (the governance scripts under `.github/project/` and the
build/corpus helpers under `build/`) is linted, formatted and type-checked by
`ruff` and `ty`, configured once in `pyproject.toml` and run by
`.pre-commit-config.yaml`. The config targets Python 3.14 (`requires-python`,
ruff `target-version`, ty `python-version`); CI runs the same scripts on the
runner's unpinned `python3`, so they must stay valid there.

```sh
uv sync                          # install pre-commit, ruff and ty into .venv
export PATH="$PWD/.venv/bin:$PATH"   # the pinned tools, as the gate uses them
pre-commit install               # run the hooks on every commit
pre-commit run --all-files       # run them over the whole tree now
ruff check . && ruff format .    # or drive the tools directly
ty check
```

**The rule that matters, and the reason this config is not a copy of the sibling
repos': the hooks are scoped to what z47 authors.** Most of this tree is
imported verbatim from upstream C47 — everything under `upstream/` (its own
`src/`, `res/`, `docs/`, `tools/`, `dep/`, `Makefile` and `tag2ver.py`) — and
every resync diffs it against upstream's. The root `.gitattributes`,
`.gitignore` and `.gitmodules` are z47's, reconciled with upstream's by hand on
a resync. A hook that strips a trailing space from an imported file turns a
clean import into a permanent conflict on a file z47 has no opinion about. So:

- `pyproject.toml` carries a single `extend-exclude = ["upstream"]`, which covers
  every imported `.py` file in one entry. Since the imported tree was nested, that
  is the whole exclusion — there is no per-directory list to keep in sync.
- `.pre-commit-config.yaml` gives the whitespace hooks an explicit allowlist of
  z47-owned paths, and excludes byte-exact data (`.p47`, `.sav`, `.tsv`, …)
  even inside them — those are test inputs compared verbatim.

The hooks skip some z47-owned root files (`README.md`, `AGENTS.md`, `CLAUDE.md`,
`COPYING`, the git dotfiles); `.github/project/source-ownership.txt` is the
authority on ownership. Adding a z47-owned top-level path means adding it to
`Z47_OWNED` in `.pre-commit-config.yaml` and to `[z47-owned]` in
`source-ownership.txt`. ruff already covers everything outside `upstream/`, and
ty needs the path only if it holds Python.

The hooks deliberately do **not** run the governance gates in `.github/project/`;
those read the whole tree or build firmware and stay in
`.github/project/run-local-gate.sh`. Pre-commit owns the cheap per-file classes,
the gate owns the expensive whole-tree ones.

## Upstream Resync Flow

The ordered procedure for advancing the imported upstream pin and re-deriving
the Zig port on top of it is the committed runbook
`.github/project/upstream-resync-runbook.md`, from scoping the range to the
finalize step and the merge condition; follow it, and do not restate its steps
here. How a changed file is re-synced depends on whether its owner is hot or
cold, which
[50-zig-c-boundaries-and-rewrite-policy.md](50-zig-c-boundaries-and-rewrite-policy.md#seam-and-core-architecture)
defines, and the gate a resync ends on is in
[70-tests-and-verification.md](70-tests-and-verification.md).

## Linked-Worktree Refresh Flow

Use a linked worktree when auditing or rehearsing an `upstream/master` refresh
without disturbing your active coding tree.

1. `git fetch upstream master`
2. `python3 .github/project/report-upstream-refresh.py --repo-root . --head-rev upstream/master`
3. `git worktree add --detach ../z47-upstream-refresh upstream/master`
4. Inspect, diff, or rehearse the upstream refresh inside
   `../z47-upstream-refresh` while the active tree stays on your topic branch.
5. `git worktree remove ../z47-upstream-refresh` when the audit is complete.

Do not treat ignored local worktrees as tracked documentation surfaces.

## Codebase Status Flow

Use the tracked C-dependency status helper when a maintainer report needs
current first-party C telemetry.

1. Run `python3 .github/project/report-c-dependency-status.py --repo-root .`.
2. Run `python3 .github/project/check-retained-bridge-ledger.py --repo-root .`.
3. Keep these buckets separate in the maintained wording; do not collapse them
   into one closure sentence:
   - active product-build first-party C (target 0)
   - retained-bridge subset (the near-retired `bridge/` shims)
   - repo-wide non-product parity, oracle, fake-runtime, and test first-party C
4. Keep the retained-bridge set justified through
   `../.github/project/retained-bridge-review.tsv`.
5. Pair the split C report with
   `python3 .github/project/report-upstream-refresh.py --repo-root . --fetch`
   when the report also makes an upstream-sync freshness claim.

## Local Roadmap Sync Flow

Use the tracked roadmap guard when a local roadmap file is part of a milestone
close-out review.

1. Run
   `python3 .github/project/check-local-roadmap-sync.py --roadmap <local-roadmap.md>`.
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
- update [30-host-and-generated-surfaces.md](30-host-and-generated-surfaces.md)
  when the host simulator, a generated artifact, the docs build, or a retained
  host dependency changed
- update [40-firmware-and-distribution.md](40-firmware-and-distribution.md) when
  a firmware target, package variant, budget, or host-package rule changed
- update [60-ci-and-release-workflow.md](60-ci-and-release-workflow.md) when CI
  jobs, artifacts, ownership guards, upstream-ledger guards, imported-root
  workflow guards, or local reproduction changed
- update [70-tests-and-verification.md](70-tests-and-verification.md) when the
  smallest rerun lane, ownership guard, upstream-ledger guard, workflow
  imported-root guard, or generated-surface validation contract changed
- update [75-debugging.md](75-debugging.md) when a detector, what it is blind
  to, the differential procedure, or a false-pass hazard changed
- update [90-official-references.md](90-official-references.md) when an
  upstream, Zig, dependency, or companion-doc reference changed
- update [95-glossary.md](95-glossary.md) when a page introduces a term

## Maintenance Rules

- If a change affects more than one maintained page, update them together.
- Prefer linking to the one page that owns a topic instead of repeating the same
  contract in multiple places.
- Re-check local links and at least one focused command or behavior surface
  before finishing the change.
