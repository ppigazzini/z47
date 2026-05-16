# CI And Release Workflow

This page explains the GitHub Actions lane split for z47, what each workflow
verifies, which artifacts it publishes, and how to reproduce the same checks
locally.

Read [10-build-and-source-layout.md](10-build-and-source-layout.md) first.
This page assumes the build entrypoints and output paths are already clear.

## CI At A Glance

Current tracked workflows:

| Workflow file | Trigger | Purpose |
| --- | --- | --- |
| `../.github/workflows/upstream-oracle.yml` | pushes and pull requests targeting `main` or `github_ci`, plus manual dispatch | main host, docs, firmware, package, boundary, and monitored Zig master compatibility surface |
| `../.github/workflows/upstream-drift.yml` | daily schedule at `0 5 * * *`, plus manual dispatch | report whether the pinned upstream commit still matches upstream HEAD |

## Workflow Graph

```mermaid
flowchart TD
  A[push or pull request to main or github_ci]
  B[validate-toolchain]
  C[zig-master-compatibility]
  D[source-manifest]
  E[source-ownership-guard]
  F[zig-c-boundary-guard]
  G[workflow-imported-root-guard]
  H[linux-host-parity]
  I[macos-host-build]
  J[windows-host-build]
  K[daily or manual upstream-drift]

  A --> B
  A --> C
  A --> D
  A --> E
  A --> F
  A --> G
  B --> H
  D --> H
  E --> H
  F --> H
  G --> H
  B --> I
  D --> I
  E --> I
  F --> I
  G --> I
  B --> J
  D --> J
  E --> J
  F --> J
  G --> J
```

## Shared CI Inputs

The workflow keeps its shared checked-in control data in these files:

- `../.github/zig-toolchain.env`
- `../.github/project/upstream-pin.env`
- `../.github/project/source-ownership.txt`
- `../.github/project/workflow-imported-root-paths.sh`
- `../.github/project/zig-c-boundaries.txt`
- `../docs/code/requirements.txt`

The host platform jobs also resolve the current upstream HEAD of the xlsxio
helper repository and use that SHA in their cache keys.

The workflow imported-root guard uses
`../.github/project/workflow-imported-root-paths.sh` as the shared path
vocabulary for docs install, generated-artifact proof, and host package
staging. That keeps the workflow text aligned with `UPSTREAM_ROOT` instead of
repeating repo-root imported paths ad hoc.

## Job Graph

### `validate-toolchain`

Purpose:

- load the checked-in Zig pin
- verify the pinned version and Linux SHA-256 against
  `https://ziglang.org/download/index.json`
- install the pinned Zig version and verify `zig version`

### `zig-master-compatibility`

Purpose:

- load the checked-in monitored Zig master snapshot from
  `../.github/zig-toolchain.env`
- install that monitored snapshot through the same setup action used for the
  stable lane
- run `zig build --help --summary none` and
  `zig build logical_shortint_parity --summary none` as a narrow
  forward-compatibility probe

Current monitoring rule:

- this job is `continue-on-error: true`, so it reports compatibility drift
  without becoming the required merge gate

### `source-manifest`

Purpose:

- verify that the pinned upstream commit is still reachable from the current
  `upstream/master` tip
- upload a source manifest artifact for the imported root tree

Current source-manifest note:

- the artifact now takes its imported-root path list from
  `../.github/project/source-ownership.txt`, so the published source manifest
  and the ownership guard use the same tracked vocabulary

### `source-ownership-guard`

Purpose:

- run `bash .github/project/check-source-ownership.sh`
- verify that the tracked ownership manifest still covers the top-level tracked
  tree
- reject unapproved added files under imported upstream-shaped roots

Current ownership-guard note:

- the job fetches the configured upstream branch first so the guard can diff
  branch-added imported-root files from the merge base between `HEAD` and the
  pinned upstream commit even when the pin is ahead of the current branch tip

### `zig-c-boundary-guard`

Purpose:

- run `bash .github/project/check-zig-c-boundaries.sh`
- fail early if checked-in Zig boundary usage drifts from the approved allowlist

### `workflow-imported-root-guard`

Purpose:

- run `bash .github/project/workflow-imported-root-paths.sh check-workflow`
- fail early if workflow files reintroduce direct repo-root imported-path
  literals for docs inputs, generated-artifact proof, or host package staging

Current imported-root-guard note:

- the helper resolves the workflow-owned imported inputs through the same
  `UPSTREAM_ROOT` vocabulary used by the Zig build graph and the M13 pilot
  tooling, and the guard keeps the remaining direct workflow references at zero

### `linux-host-parity`

Purpose:

- build and test the host simulator surface on Linux
- run `logical_shortint_parity`, `stack_state_parity`,
  `register_metadata_parity`, `flags_parity`, `memory_parity`,
  `program_serialization_parity`, `calc_state_parity`,
  `keyboard_state_parity`, `both`, `simulator_smoke`, `testPgms`, `test`,
  `generated`, `both_asan`, `test_asan`, `docs`, firmware targets, and Linux
  distribution packaging
- build the published Linux host archive with
  `zig build -Doptimize=ReleaseFast dist_linux` so the uploaded package matches
  the desktop release-size contract
- build the C47 SwissMicros firmware zips through `dist_dmcp`,
  `dist_dmcp_pkg1`, `dist_dmcp_pkg2`, `dist_dmcp_pkg3`, and `dist_dmcp5`, and
  upload those zip outputs as a second Linux artifact without changing the host
  package publication shape
- run the checked-in Xvfb-backed simulator smoke lane for both host
  simulators before the broader grouped host test lane
- run a Linux simulator smoke launch from the packaged archive
- refresh and diff tracked generated artifacts
- upload the Linux package artifact and a second artifact containing the golden
  generated files plus their hashes

### `macos-host-build`

Purpose:

- build and test the host simulator surface on macOS
- run `logical_shortint_parity`, `stack_state_parity`,
  `register_metadata_parity`, `flags_parity`, `both`, `test`, and `generated`
- rebuild `both` in `ReleaseFast` before the smoke and staging steps so the
  uploaded macOS archive uses release host binaries
- run a macOS simulator smoke launch from the built simulator artifact
- stage and upload a macOS package artifact

Current platform detail:

- the job only installs missing Homebrew formulae so repeated runs stay
  idempotent and warning-light

### `windows-host-build`

Purpose:

- build and test the host simulator surface on Windows under MSYS2 UCRT64
- run `logical_shortint_parity`, `stack_state_parity`,
  `register_metadata_parity`, `flags_parity`, `both`, `test`, and `generated`
- rebuild `both` in `ReleaseFast` before the direct smoke and staging lanes
- run a direct simulator smoke launch
- build a relocatable Windows package with GTK runtime assets, launcher files,
  runtime caches, and notice metadata
- inspect packaged imports and run a relocated launcher smoke test before
  artifact upload

## Artifacts And Release Proof

Current artifact classes include:

- source-manifest artifact from `source-manifest`
- source-ownership guard result from `source-ownership-guard`
- Linux generated-artifact proof from `linux-host-parity`
- packaged simulator artifacts named `z47-linux-<upstream_short>`,
  `z47-macos-<upstream_short>`, and `z47-windows-<upstream_short>`
- Linux SwissMicros firmware artifact named `z47-firmware-<upstream_short>`
  containing `c47-dmcp.zip`, `c47-dmcp-pkg1.zip`, `c47-dmcp-pkg2.zip`,
  `c47-dmcp-pkg3.zip`, and `c47-dmcp5.zip`
- the `upstream-drift` report artifact from the scheduled drift workflow

Linux packaging also stages explicit build metadata, source provenance, and
runtime notice inventory. Windows packaging additionally records staged GTK
runtime directories, runtime tools, launcher files, and DLL notice inventory.
The published desktop host artifacts now stage `ReleaseFast` simulator
binaries, and the Unix package helper strips the staged simulator copies before
archiving them.

## Local Reproduction Map

Use the smallest local lane that matches the workflow slice you changed.

| Workflow slice | Smallest local reproduction |
| --- | --- |
| toolchain pin | `zig version` plus a read of `../.github/zig-toolchain.env` |
| monitored Zig master compatibility | install the monitored `ZIG_MASTER_VERSION`, then run `zig build --help --summary none && zig build logical_shortint_parity --summary none` |
| source manifest or upstream pin | `. ./.github/project/upstream-pin.env && git fetch --no-tags "$UPSTREAM_REPOSITORY_URL" "$UPSTREAM_BRANCH" && git merge-base --is-ancestor "$UPSTREAM_COMMIT" FETCH_HEAD && bash .github/project/check-source-ownership.sh` |
| tracked source ownership contract | `. ./.github/project/upstream-pin.env && git fetch --no-tags "$UPSTREAM_REPOSITORY_URL" "$UPSTREAM_BRANCH" && bash .github/project/check-source-ownership.sh` |
| workflow imported-root contract | `bash .github/project/workflow-imported-root-paths.sh check-workflow` |
| Zig or C boundary guard | `bash .github/project/check-zig-c-boundaries.sh` |
| Linux host parity | `bash .github/project/check-zig-c-boundaries.sh && zig build logical_shortint_parity && zig build stack_state_parity && zig build register_metadata_parity && zig build flags_parity && zig build memory_parity && zig build program_serialization_parity && zig build calc_state_parity && zig build keyboard_state_parity && zig build both && zig build simulator_smoke && zig build testPgms && xvfb-run --auto-servernum zig build test && zig build generated` |
| Linux docs | `zig build docs` |
| Linux firmware | `zig build dmcp && zig build dmcpr47 && zig build dmcp5 && zig build dmcp5r47` |
| host package | run the matching `dist_<host>` target on the matching host OS; use `-Doptimize=ReleaseFast` when reproducing the published desktop host artifact size contract |
| Linux firmware artifact publication | run `zig build dist_dmcp && zig build dist_dmcp_pkg1 && zig build dist_dmcp_pkg2 && zig build dist_dmcp_pkg3 && zig build dist_dmcp5`, then copy those zips into the firmware artifact staging directory |

## Upstream Drift Workflow

`../.github/workflows/upstream-drift.yml` runs daily and on manual dispatch.

Current behavior:

- query the current upstream HEAD from the pinned repository URL
- compare it with the checked-in `UPSTREAM_COMMIT`
- write an artifact that records whether upstream moved or the query failed

This workflow is reporting-only. It does not auto-update the pin.

## CI Change Rules

- Keep the lane split explicit. Do not hide docs, firmware, package, and
  boundary validation behind one generic step.
- Keep the shared pins in the checked-in files listed above.
- Keep logs and artifacts uploadable even when a later verification step fails.
- Update this page when job names, artifact names, trigger branches, or local
  reproduction commands change.