# Project And Upstream Contract

This page defines what z47 is, what it owns, what the imported upstream C47
tree owns, and where the current Zig port boundary sits.

Read this page first. The rest of the set assumes the ownership split and the
current upstream pin are already clear.

## At A Glance

- z47 is not a generic Zig sample project and not a plain mirror of the
  upstream tree.
- z47 is the maintained Zig-first build, CI, packaging, documentation, and
  staged rewrite overlay for the upstream C47 calculator application.
- The authoritative upstream source repository is
  `https://gitlab.com/rpncalculators/c43.git`.
- The GitLab path still uses the historical `c43` repository name even though
  the project identifies itself as C47.
- The repo root currently carries the imported upstream working tree pinned at
  commit `fbe727accf7e6b777d0541160bc35c97680b45a1`.
- `build.zig` is the canonical maintained build entrypoint.
- The imported `Makefile`, `meson.build`, and related upstream files remain in
  the tree as audit and rebase reference surfaces.
- The current verified Zig-owned code slices are the deterministic generators
  under `zig_build/tools/`, the short-integer logical leaf rewrite under
  `zig_build/leaf/`, and the live stack or undo owner rewrite under
  `zig_build/state/`.

## What This Repository Is

z47 is the working repository for porting the upstream C47 calculator
application to a Zig-first build and maintenance model while preserving
upstream behavior.

In practice, that means this repo owns:

- the repo-root `build.zig` control plane
- the Zig build-domain code under `zig_build/`
- GitHub Actions workflows, pins, and packaging helpers under `.github/`
- the maintained developer-doc set under `zig_docs/`

The imported upstream tree still owns the main calculator sources, assets,
legacy build graph, and retained third-party dependency layout carried at the
repo root.

## What This Repository Is Not

- not a clean-room Zig rewrite of the whole calculator
- not a docs-only planning repo disconnected from live sources
- not a promise that GTK, FreeType, GMP, `decNumberICU`, or the SwissMicros SDK
  stack has already been replaced
- not a license to treat `zig translate-c` or ad hoc `@cImport` calls as the
  default migration strategy

## Imported Upstream Baseline

The current imported upstream pin is recorded in
`../.github/project/upstream-pin.env`.

Current checked-in values:

| Field | Value |
| --- | --- |
| `UPSTREAM_PROJECT_NAME` | `C47` |
| `UPSTREAM_REPOSITORY_URL` | `https://gitlab.com/rpncalculators/c43.git` |
| `UPSTREAM_REMOTE_NAME` | `upstream` |
| `UPSTREAM_BRANCH` | `master` |
| `UPSTREAM_COMMIT` | `fbe727accf7e6b777d0541160bc35c97680b45a1` |
| `UPSTREAM_IMPORT_LAYOUT` | `repo-root-import` |
| `UPSTREAM_PIN_UPDATED` | `2026-05-07` |

That imported tree includes the main source, dependency, resource, packaging,
and docs inputs under `src/`, `dep/`, `res/`, `LIBRARY/`, `docs/`,
`Makefile`, `meson.build`, and related root files.

## Ownership Table

| Surface | Owner | Purpose |
| --- | --- | --- |
| `build.zig` | z47 overlay | repo-root option parsing and top-level step registration |
| `zig_build/` | z47 overlay | host, firmware, distribution, generator, and rewrite build domains |
| `.github/` and `.github/project/` | z47 overlay | CI workflows, toolchain pin, upstream pin, boundary guard, package helpers |
| `zig_docs/` | z47 maintained docs | stable developer documentation for the live repo |
| `src/`, `dep/`, `res/`, `LIBRARY/`, `docs/`, `Makefile`, `meson.build`, `meson_options.txt`, `tools/` | imported upstream baseline | canonical calculator sources, assets, legacy build graph, and helper tools |
| `dep/DMCP_SDK` and `dep/DMCP5_SDK` | imported retained SDK inputs | SwissMicros hardware build inputs used by the Zig-owned firmware flow |

## Port Boundary Summary

| Surface | Current state | Notes |
| --- | --- | --- |
| `src/c47`, `src/c47-gtk`, `src/c47-dmcp`, `src/c47-dmcp5` | existing C compiled by Zig, with selected leaf and stack replacements | most calculator, simulator, and hardware code still comes from the imported upstream tree |
| `dep/decNumberICU` | retained C dependency compiled by Zig | vendored decimal arithmetic library remains explicit |
| GTK 3, FreeType 2, GMP, libm, optional PulseAudio | external C libraries linked from Zig | retained host dependencies remain explicit |
| `zig_build/tools/` generator entrypoints | manual Zig executables with narrow C boundaries | deterministic generators now run from Zig-owned entrypoints |
| `zig_build/leaf/` short-integer rewrite slice | manual Zig rewrite with parity coverage | low-coupling logical leaf modules have focused parity validation |
| `zig_build/state/` stack rewrite slice | manual Zig rewrite with parity coverage | the exported `stack.c` owner now lives in Zig for the live host and firmware graphs |
| `zig_build/leaf/shortint_runtime.zig`, `zig_build/state/stack_runtime.zig`, plus approved generator files | explicit Zig or C boundary | checked-in `@cImport` and direct `extern` usage is CI-gated |

## Runtime And Build Boundary Rules

- Fix shared calculator behavior in the canonical imported owner path or in an
  approved Zig rewrite slice, not in notes or generated output snapshots.
- Keep the imported root tree rebase-friendly against `upstream/master`.
- Keep retained C libraries explicit in docs and code review. Do not imply a
  pure-Zig state while the build still links or compiles retained C.
- Update `../.github/project/upstream-pin.env` and any affected maintainer docs
  together when the audited upstream pin changes.

## What To Read Next

- Read [10-build-and-source-layout.md](10-build-and-source-layout.md) next for
  the canonical build entrypoints, build layout, and local flow.
- Read [20-zig-build-graph.md](20-zig-build-graph.md) when you need the actual
  Zig build-domain split.
- Read [50-zig-c-boundaries-and-rewrite-policy.md](50-zig-c-boundaries-and-rewrite-policy.md)
  before changing any `@cImport`, `extern`, or rewrite slice.
- Read [70-tests-and-verification.md](70-tests-and-verification.md) before
  deciding which rerun lane to use.