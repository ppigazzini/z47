# Project And Upstream Contract

This page defines what z47 is, what it owns, what the imported upstream C47 tree
owns, and where the Zig port boundary now sits.

Read this page first. The rest of the set assumes the ownership split and the
current upstream pin are already clear.

Audit basis: 2026-07-30, upstream pin `4697e526a`, Zig `0.16.0` stable.

## At A Glance

- z47 is the Zig-first build, CI, packaging, documentation, and port of the
  upstream C47 calculator application.
- The calculator core is fully ported to Zig. The product builds (host simulator
  and DMCP/DMCP5 firmware) contain no first-party calculator C:
  `report-c-dependency-status.py` reports 0 active product-build first-party C
  files.
- The upstream C tree (`src/`, `dep/`) is retained as a read-only audit input and
  the verification reference (the shared testSuite plus per-owner parity oracles).
  z47 never edits it during normal work.
- The authoritative upstream source repository is
  `https://gitlab.com/rpncalculators/c43.git`. The GitLab path still uses the
  historical `c43` name even though the project identifies itself as C47.
- The imported upstream working tree is mounted under `upstream/`, pinned at
  commit `b9e1cc0c18717423a5f7b9e9a78fe866f1c14d01` (verified fact from
  `.github/project/upstream-pin.env`).
- `build.zig` is the canonical maintained build entrypoint.

## What This Repository Is

z47 is the working repository that ports the upstream C47 calculator application
to a Zig-first build and maintenance model while preserving upstream behavior,
proven by the shared testSuite and per-owner parity oracles.

This repo owns:

- the repo-root `build.zig` control plane
- the ported calculator core under `src/` (the Zig owners)
- the Zig build-domain code under `build/` (host, firmware, distribution,
  generators, tests, and the Zig host/firmware/testSuite HAL replacements)
- the near-retired legacy header shims under `bridge/`
- GitHub Actions workflows, pins, governance guards, and packaging helpers under
  `.github/`
- the maintained developer-doc set under `docs/`

The imported upstream tree still owns the original calculator C sources, assets,
legacy build graph, and legacy third-party dependency layout carried at the repo
root, kept as audit and parity reference.

## What This Repository Is Not

- not a clean-room rewrite: the Zig owners are parity-gated against the imported
  upstream C, which stays in the tree as the oracle
- not pure Zig at the dependency level: the build still compiles the vendored
  `dep/decNumberICU` and links GTK 3, GMP, FreeType 2, optional PulseAudio, and
  the SwissMicros SDKs (see the dependency table below)
- not a license to treat `zig translate-c` or ad hoc `@cImport` as a migration
  path for owner logic: `translate-c` is confined to the generated ABI seam and a
  few narrow generator boundaries (see
  [50-zig-c-boundaries-and-rewrite-policy.md](50-zig-c-boundaries-and-rewrite-policy.md))

## Imported Upstream Baseline

The imported upstream pin is recorded in `../.github/project/upstream-pin.env`.

Current checked-in values:

| Field | Value |
| --- | --- |
| `UPSTREAM_PROJECT_NAME` | `C47` |
| `UPSTREAM_REPOSITORY_URL` | `https://gitlab.com/rpncalculators/c43.git` |
| `UPSTREAM_REMOTE_NAME` | `upstream` |
| `UPSTREAM_BRANCH` | `master` |
| `UPSTREAM_COMMIT` | `b9e1cc0c18717423a5f7b9e9a78fe866f1c14d01` |
| `UPSTREAM_ROOT` | `upstream` |
| `UPSTREAM_IMPORT_LAYOUT` | `nested-upstream` |
| `UPSTREAM_PIN_UPDATED` | `2026-08-02` |

`UPSTREAM_ROOT=upstream` means the imported upstream tree is mounted under
`upstream/`, so z47's own owners can hold the canonical `src/` and `docs/` names.
That imported tree includes the source, dependency, resource, packaging, and docs
inputs under `upstream/src/`, `upstream/dep/`, `upstream/res/`,
`upstream/LIBRARY/`, `upstream/docs/`, `upstream/Makefile`,
`upstream/meson.build`, and related files. `.gitmodules` and `.gitattributes` are
deliberate root exceptions: git honours them only at the repo root. Advancing the pin is the upstream resync
flow; see [80-maintainer-workflow.md](80-maintainer-workflow.md) and the committed
`.github/project/upstream-resync-runbook.md`.

The imported tree answers *what the port must do*, but it is source, not prose.
For the reasoning behind the C -- the item table, the HAL, the memory model, the
control flow from a key press to a screen -- read the companion c47-r47-ci doc
set, which documents upstream C47 itself. z47's pages do not restate it; see the
page map in [90-official-references.md](90-official-references.md).

## Ownership Table

| Surface | Owner | Purpose |
| --- | --- | --- |
| `build.zig` | z47 | repo-root option parsing and top-level step registration |
| `src/` | z47 | the ported calculator core (Zig owners: `abi`, `constants`, `frontier`, `mathematics`, `shortint`, `solver`, `state`, `ui`) |
| `build/` | z47 | host, firmware, distribution, generator, and test build domains, plus the Zig host/firmware/testSuite HAL replacements |
| `bridge/` | z47 | near-retired legacy header shims (two headers) paired with a few owners |
| `.github/` and `.github/project/` | z47 | CI workflows, toolchain pin, upstream pin, governance guards, boundary and ownership manifests, package helpers |
| `docs/` | z47 | maintained developer documentation |
| `src/`, `dep/`, `res/`, `LIBRARY/`, `docs/`, `Makefile`, `meson.build`, `tools/` | imported upstream | original calculator C sources, assets, legacy build graph, and helper tools -- read-only audit and parity reference |
| `dep/DMCP_SDK` and `dep/DMCP5_SDK` | imported SwissMicros SDKs | hardware build inputs used by the Zig-owned firmware flow |

## Port Boundary Summary

| Surface | Current state |
| --- | --- |
| calculator core (`src/c47/**` logic) | fully ported to Zig under `src/`; the upstream C is retained only as the parity oracle |
| GTK host layer (`src/c47-gtk`) | ported to Zig under `build/host/gtk_*.zig`; the ported C files are filtered out of the build (`filterGtkSources`) |
| DMCP/DMCP5 firmware HAL (`src/c47-dmcp*`) | audio, file-I/O, and print-IR HAL ported to Zig under `build/firmware_*_runtime.zig`; firmware core is the Zig owners |
| testSuite HAL (`src/testSuite/hal/*.c`) | ported to Zig (`build/tests/testsuite_hal.zig`) and linked instead of the C HAL |
| `dep/decNumberICU` | retained vendored C, compiled by Zig into the product and generators |
| GTK 3, GMP, FreeType 2, optional PulseAudio | retained external C libraries linked from Zig (host) |
| SwissMicros DMCP/DMCP5 SDKs | retained external C inputs linked from Zig (firmware) |
| first-party C remaining in the tree | the ~60 parity/oracle/fake-runtime/test files under `build/tests/**` and `src/**` used only for verification -- not in the product |

## Runtime And Build Boundary Rules

- Fix shared calculator behavior in the Zig owner under `src/`, never in the
  imported upstream tree (which is the oracle) and never in notes or generated
  snapshots.
- Keep the imported root tree rebase-friendly against `upstream/master`.
- Keep retained C dependencies explicit in docs and review. Do not imply a
  pure-Zig state while the build still compiles decNumberICU or links GTK, GMP,
  FreeType, or the hardware SDKs.
- Update `../.github/project/upstream-pin.env`, the source-ownership manifest, the
  port ledger, and any affected maintainer docs together when the pin changes.

## What To Read Next

- [10-build-and-source-layout.md](10-build-and-source-layout.md) for the canonical
  build entrypoints, layout, and local flow.
- [20-zig-build-graph.md](20-zig-build-graph.md) for the Zig build-domain split.
- [50-zig-c-boundaries-and-rewrite-policy.md](50-zig-c-boundaries-and-rewrite-policy.md)
  before changing any `@cImport`, `extern`, generated seam, or retained C surface.
- [70-tests-and-verification.md](70-tests-and-verification.md) before choosing a
  rerun lane.
