# Build And Source Layout

This page is the canonical z47 build-entrypoint, ownership, and source-layout
contract for the live repository. Use it for the `zig build` targets, the
one-command local gate, the tracked source domains, the checked-in pins, and the
build outputs.

Read [00-project-and-upstream.md](00-project-and-upstream.md) first. This page
starts after the project and ownership boundary are already clear.

Audit basis: 2026-07-10, upstream pin `0caee2adc`, Zig `0.16.0` stable.

## Build At A Glance

- `build.zig` is the canonical maintained entrypoint. The repo-root `build.zig`
  stays small and routes work into `zig_build/`.
- The calculator core is fully ported to Zig. `report-c-dependency-status.py`
  reports 0 active product-build first-party C files, so `zig build sim`,
  `zig build dmcp`, and `zig build dmcp5` compile no first-party calculator C.
- `zig_build/` is build-only Zig plus the Zig host/firmware/testSuite HAL
  replacements; the ported calculator core lives under `zig_src/`; `zig_bridge/`
  is near-retired and holds only two header shims.
- Retained C is explicit: the vendored `dep/decNumberICU` is compiled by Zig,
  and the build links GTK 3, GMP, FreeType 2, and optional PulseAudio (host) plus
  the SwissMicros DMCP/DMCP5 SDKs (firmware). The remaining first-party C in the
  tree is parity/oracle/testSuite verification only, not in the product.
- Imported upstream paths route through `UPSTREAM_ROOT` in
  `../.github/project/upstream-pin.env`; the current value `.` keeps the imported
  baseline at repo root. The imported `Makefile` and Meson files stay audit and
  parity references, not the maintained control plane.
- Host, docs, firmware, packaging, and generator work all route through
  `zig build`. Build output goes to `zig-out/`, which is gitignored.

## Canonical Build Entrypoints

Lead with these. The full grouped set is in `../ZIG-README.md`,
[20-zig-build-graph.md](20-zig-build-graph.md), and live `zig build --help`.

| Command | What it does |
| --- | --- |
| `zig build` / `zig build sim` | canonical host simulator build (C47) |
| `zig build simr47` / `zig build both` | R47 simulator / build both simulators |
| `zig build test` | grouped host regression lane: the shared upstream testSuite plus the Zig-owned suites |
| `zig build test:unit` | native Zig unit tests, no C oracle |
| `zig build generated` | refresh all tracked generated host artifacts |
| `zig build constants`, `zig build catalogs`, `zig build fonts`, `zig build testPgms` | individual generator lanes |
| `zig build docs` | docs build for `docs/code` |
| `zig build dmcp`, `zig build dmcpr47`, `zig build dmcp5`, `zig build dmcp5r47` | firmware targets (DMCP and DMCP5, C47 and R47) |
| `zig build dist_linux`, `zig build dist_macos`, `zig build dist_windows` | host-package build on the matching host OS |
| `zig build clean` | clear derived build state |

Verification entrypoints:

- `bash .github/project/run-local-gate.sh`: one command that reproduces the full
  Linux CI verdict before pushing. It runs the governance guards, the native unit
  tests, the host-parity build/test/oracle battery, and the tracked
  generated-artifact diff, failing fast on the first red.
- the per-owner parity and oracle lanes (for example `zig build calc_state_parity`,
  `zig build math_command_wrappers_parity`, `zig build eigen_parity`) prove each
  Zig owner matches its retained upstream C; see
  [70-tests-and-verification.md](70-tests-and-verification.md).

## Top-Level Locality Map

Use this compact map first when triaging where a change belongs.

| Bucket | Root count | Canonical source | Action rule |
| --- | ---: | --- | --- |
| z47-owned control roots | 10 | `../.github/project/source-ownership.txt` (`[z47-owned]`) | Place new maintained build, runtime-Zig, CI, and docs logic here. |
| imported upstream roots | 20 | `../.github/project/source-ownership.txt` (`[imported-upstream]`) | Treat as imported baseline; change only with an explicit reviewed exception. |
| local environment and build-output roots | untracked | live worktree (`.zig-cache`, `zig-out`, and other ignored paths) | Keep untracked and out of policy claims; do not treat as owned source roots. |

Root-clutter guardrails:

- `.github/project/check-source-ownership.sh` rejects missing or unclassified
  tracked top-level roots.
- `.github/project/source-ownership.txt` is the single classification surface
  for owned versus imported tracked roots (including the reviewed
  `[approved-z47-additions-under-imported]` exceptions).
- avoid adding new top-level roots; prefer adding paths under the existing
  `zig_build/`, `zig_src/`, `zig_bridge/`, `.github/`, or `zig_docs/` trees.

## Repo-Owned Source Domains

The ported calculator core lives under `zig_src/` as 366 `.zig` owners across
eight domains.

| Domain | `.zig` owners | Role |
| --- | ---: | --- |
| `abi` | 13 | ABI mirror types and the generated C-boundary seam |
| `constants` | 2 | constant-table owner and its generator seam |
| `frontier` | 103 | menus, catalogs, display, keyboard/program-editor frontends |
| `mathematics` | 154 | math command entries, real/complex math, matrices, stats |
| `shortint` | 10 | short-integer and bit-logic owners |
| `solver` | 10 | solver and root-finding owners |
| `state` | 72 | calculator state, stack, flags, memory, program serialization |
| `ui` | 2 | tone and small UI-side owners |

`zig_build/` holds roughly 59 `.zig` files across the host, firmware,
distribution, generator, and test build domains, plus the Zig host, firmware, and
testSuite HAL replacements. Its top level includes `host.zig`, `firmware.zig`,
`dist.zig`, `common.zig`, `zig_dist.py`, the `firmware_*_runtime.zig` HAL files,
and the `host/`, `firmware/`, `tools/`, `tests/`, and per-domain subdirectories.

`zig_bridge/` is near-retired: it holds only `c47.h` and
`state/keyboard_statusbar_mask.h`.

## Build-Relevant File Layout

```text
repo root
|- build.zig
|- build.zig.zon
|- zig_build/
|  |- common.zig
|  |- host.zig
|  |- firmware.zig
|  |- dist.zig
|  |- firmware_audio_runtime.zig
|  |- firmware_io_runtime.zig
|  |- firmware_print_ir_runtime.zig
|  |- zig_dist.py
|  |- host/
|  |- firmware/
|  |- tools/
|  |- tests/
|  |- constants/
|  |- shortint/
|  |- state/
|  |- solver/
|  |- mathematics/
|  |- frontier/
|  `- ui/
|- zig_src/
|  |- abi/
|  |- constants/
|  |- frontier/
|  |- mathematics/
|  |- shortint/
|  |- solver/
|  |- state/
|  `- ui/
|- zig_bridge/
|  |- c47.h
|  `- state/keyboard_statusbar_mask.h
|- .github/
|  |- zig-toolchain.env
|  |- workflows/
|  `- project/
|     |- upstream-pin.env
|     |- upstream-port-ledger.tsv
|     |- check-upstream-port-ledger.py
|     |- source-ownership.txt
|     |- check-source-ownership.sh
|     |- zig-c-boundaries.txt
|     |- check-zig-c-boundaries.sh
|     |- report-c-dependency-status.py
|     |- run-local-gate.sh
|     |- run-host-parity-battery.sh
|     `- upstream-resync-runbook.md
|- zig_docs/
|- docs/code/
|  |- conf.py
|  |- Doxyfile
|  `- requirements.txt
|- src/
|  |- c47/
|  |- c47-gtk/
|  |- c47-dmcp/
|  `- c47-dmcp5/
|- dep/
|  |- decNumberICU/
|  |- DMCP_SDK/
|  `- DMCP5_SDK/
|- res/
|- LIBRARY/
|- Makefile
|- meson.build
|- meson_options.txt
`- tag2ver.py
```

The `.github/project/` list above is a triage subset; that directory also carries
the C-dependency baselines and allowlists, the retained-bridge review ledger, the
idiom ratchet, and other governance guards. Run `ls .github/project/` for the
full set.

## Checked-In Defaults And Pins

Checked-in build defaults come from these tracked files:

- `../.github/zig-toolchain.env`: pins Zig `0.16.0` (plus the audited Zig master
  snapshot used by the non-blocking compatibility lane and the setup-zig action
  ref)
- `../.github/project/upstream-pin.env`: pins the imported upstream commit,
  repository URL, branch, and the imported upstream root (`UPSTREAM_ROOT=.`)
- `../.github/project/upstream-port-ledger.tsv`: the maintainer triage ledger for
  the current pin and later audited upstream commits
- `../.github/project/check-upstream-port-ledger.py`: validates ledger shape,
  pinned-commit coverage, and pin-plus-ledger co-updates
- `../.github/project/c_dependency_audit.py`: shared path extraction and
  classification logic for tracked first-party C telemetry
- `../.github/project/c-dependency-first-party-baseline.txt` and
  `../.github/project/c-dependency-product-first-party-baseline.txt`: the tracked
  first-party C baselines the Phase I policy check compares against
- `../.github/project/report-c-dependency-status.py`: prints split first-party C
  metrics for the active product-build, retained-bridge, and parity/oracle/test
  buckets
- `../.github/project/retained-bridge-review.tsv` and
  `../.github/project/check-retained-bridge-ledger.py`: the file-by-file review
  ledger and guard for the remaining `zig_bridge` seams
- `../.github/project/report-upstream-refresh.py`: summarizes new upstream
  commits, changed imported paths, and z47-owned touchpoints before a refresh
  lands
- `../.github/project/source-ownership.txt` and
  `../.github/project/check-source-ownership.sh`: the tracked top-level ownership
  classification and its guard
- `../.github/project/workflow-imported-root-paths.sh`: resolves the
  workflow-owned imported-root paths used by docs install, generated-artifact
  proof, and host package staging
- `../.github/project/zig-c-boundaries.txt` and
  `../.github/project/check-zig-c-boundaries.sh`: the approved checked-in
  `@cImport` and direct `extern` boundary files and their guard
- `../docs/code/requirements.txt`: pins the Python package set needed for
  `zig build docs`

The live project-specific Zig options are:

- `-Dci-commit-tag=<string>`: optional version tag input for packaging (default
  empty)
- `-Draspberry=<bool>`: Raspberry Pi layout switch, default `false`
- `-Ddecnumber-fastmul=<bool>`: `DECNUMBER_FASTMUL` switch, default `true`
- `-Ddmcp-package=<int>`: DMCP package selector for `dmcp` and `dmcpr47`,
  default `4`

## Build Outputs

The live Zig build graph installs into `zig-out/`, which is gitignored along with
`.zig-cache/`. Keep the maintained docs focused on the public `zig build`
entrypoints and the tracked source surfaces they act on, not on ignored
build-output directories.

## File Naming Conventions

Use one naming stratum per file. The suffixes below are the layout-visible part
of that contract; the deeper layer-scoped casing policy lives in the naming
milestones under `__DEV/`.

- semantic owner files use the domain name directly, for example
  `zig_src/frontier/frontier.zig`, `zig_src/kernel/calc_state.zig`, and
  `zig_src/ui/tone.zig`
- direct legacy-boundary Zig seams use `*_runtime.zig`, for example
  `zig_src/frontier/frontier_runtime.zig` and
  `zig_src/kernel/calc_state_runtime.zig`
- pure ABI shim forwarders use `*_export.zig`, for example
  `zig_src/frontier/glyph_export.zig`
- internal implementation helpers that exist only behind a paired export shim use
  `*_owned.zig`, for example `zig_src/solver/solve_owned.zig`
- `*_runtime.zig`, `*_export.zig`, `pub export`, `extern`, ABI mirror types, and
  legacy public names may keep upstream-compatible spellings where ABI stability
  or upstream tracking requires them
- do not force one repo-wide casing rule across owner, runtime, and export
  layers; the repo needs layer-specific rules, not global churn

Avoid historical mixed forms such as `*_owned_export.zig` and owner-file
`*_entries.zig` suffixes. Keep upstream-compatible spellings at the legacy
boundary or export surface, not in the semantic owner filename.

## Local Maintainer Flow

1. Ensure `zig version` matches the checked-in pin in
   `../.github/zig-toolchain.env`.
2. Ensure host prerequisites are installed for the lane you plan to run.
3. Run the smallest focused lane first, usually `zig build test:unit`, a single
   owner parity lane (for example `zig build stack_state_parity`),
   `zig build generated`, `zig build docs`, or one firmware target.
4. Rerun the broader host or package lane only after the focused lane passes.
5. Before pushing (especially after an upstream resync) run
   `bash .github/project/run-local-gate.sh` for the full Linux CI verdict. The
   Windows LLP64 and macOS lanes still only run in CI.

## Generated And Cleaned Surfaces

`zig build generated` refreshes the tracked generated calculator sources and
test-program data owned by the host build graph. `zig build clean` clears derived
build state; after a clean-based lane, rerun `zig build generated` before
checking generated diffs or committing generated output changes. Change canonical
owner paths first and never patch generated outputs by hand.

## Practical Maintenance Rules

- Keep `build.zig` small. Push domain-specific logic down into `zig_build/`.
- Add new z47-owned build logic under `zig_build/` or `.github/`, new live
  runtime Zig under `zig_src/`, and do not place new z47-owned files under
  imported upstream-shaped directories without a reviewed exception.
- Keep retained C dependencies explicit. Do not imply a pure-Zig state while the
  build still compiles decNumberICU or links GTK, GMP, FreeType, or the hardware
  SDKs.
- Use a linked worktree (and `../.github/project/nested-upstream-pilot.sh` when
  re-measuring a nested `upstream/` layout) to rehearse an `upstream/master`
  refresh instead of repurposing the active coding tree; do not change
  `UPSTREAM_ROOT` in the maintained tree unless that pilot is promoted.
- Run `../.github/project/report-upstream-refresh.py` after fetching
  `upstream/master` so the refresh review records new commits, changed imported
  paths, and likely z47-owned follow-up surfaces before the pin moves.
- Run `../.github/project/report-c-dependency-status.py` when a maintainer report
  or closure claim needs live split first-party C telemetry; keep the active
  product-build, retained-bridge, and parity/oracle/test buckets separate.
- Keep `ZIG-README.md`, `zig_docs/`, and the live `zig build --help` surface
  aligned when target names or options change.
- Keep imported upstream build files readable and auditable even when they are no
  longer the maintained control plane.
- Keep docs, CI workflows, and pins aligned in the same change when a contract
  changes.
