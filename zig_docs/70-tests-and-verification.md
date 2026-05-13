# Tests And Verification

This page maps the maintainer verification surfaces, the contracts they lock,
and the smallest rerun lane that should move with each kind of change.

Read [10-build-and-source-layout.md](10-build-and-source-layout.md) first.
This page assumes the build entrypoints and ownership split are already clear.

## Verification Flow

```mermaid
flowchart TD
  A[Code or docs change]
  B{Changed surface}
  C[Boundary or rewrite slice]
  D[Host simulator or core regression]
  E[Generated artifact or docs surface]
  F[Firmware or package surface]
  G[Broader CI lanes]

  A --> B
  B -->|@cImport, extern, leaf rewrite| C
  B -->|host simulator, tests, platform glue| D
  B -->|generated outputs, docs| E
  B -->|firmware, dist, release proof| F
  C --> G
  D --> G
  E --> G
  F --> G
```

## Contract Inventory

| Contract surface | Source of truth | Focused verification surface | First rerun lane |
| --- | --- | --- | --- |
| toolchain pin and supported Zig version | `../.github/zig-toolchain.env` | live `zig version` plus pinned manifest check | `zig build --help --summary none` after confirming the pinned version |
| imported upstream pin and repo-root import contract | `../.github/project/upstream-pin.env` | ancestry check and source-manifest job | `git merge-base --is-ancestor <pinned-upstream> HEAD` |
| checked-in Zig or C boundaries | `../.github/project/zig-c-boundaries.txt`, `../.github/project/check-zig-c-boundaries.sh` | boundary guard script | `bash .github/project/check-zig-c-boundaries.sh` |
| short-integer leaf rewrite parity | `../zig_build/leaf/`, `../zig_build/tests/` | focused parity executable | `zig build logical_shortint_parity --summary none` |
| stack-state rewrite parity | `../zig_build/state/`, `../zig_build/tests/stack_state/` | focused parity executable | `zig build stack_state_parity --summary none` |
| register-metadata rewrite parity | `../zig_build/state/`, `../zig_build/tests/register_metadata/` | focused parity executable | `zig build register_metadata_parity --summary none` |
| system-flag rewrite parity | `../zig_build/state/`, `../zig_build/tests/flags/` | focused parity executable | `zig build flags_parity --summary none` |
| host simulator and core regression | `../zig_build/host/`, `../src/testSuite/` | grouped native test suite | `zig build test --summary none` |
| native Zig C sanitizer lane | `../zig_build/host/steps.zig` | sanitized host build and tests | `zig build both_asan --summary none` then `zig build test_asan --summary none` |
| deterministic generated outputs | `../zig_build/tools/`, tracked generated files | generator refresh plus targeted diff | `zig build generated --summary none` |
| docs surface under `docs/code` | `../docs/code/`, `../docs/code/requirements.txt` | Sphinx and Doxygen lane | `zig build docs --summary none` |
| firmware outputs | `../zig_build/firmware.zig`, imported SDKs, linker scripts | smallest affected firmware target | `zig build dmcp --summary none` or `zig build dmcp5 --summary none` |
| host or firmware packages | `../zig_build/dist.zig`, `../zig_build/zig_dist.py` | matching distribution target | `zig build dist_linux --summary none` or matching host or firmware package target |

## Which Lane To Run First

- docs-only maintainer doc change rooted in `zig_docs/`, `README.md`, or
  `ZIG-README.md`: verify every key claim against live files, then rerun
  `zig build --help --summary none` if target names or options are described
- build-graph step rename, option change, or output-path change:
  `zig build --help --summary none`, then the smallest affected target
- generator or tracked generated-artifact change: `zig build generated --summary none`
- host simulator, platform glue, or test-surface change:
  `zig build test --summary none`
- boundary or rewrite-slice change: `zig build logical_shortint_parity --summary none`, `zig build stack_state_parity --summary none`, `zig build register_metadata_parity --summary none`, or `zig build flags_parity --summary none` for the touched slice
- docs/code change: `zig build docs --summary none`
- firmware or linker-script change: smallest affected firmware target first
- package or release-proof change: matching `dist_<host>` or firmware package
  target on the matching host OS

## Full Linux Pre-CI Sweep

When a change touches multiple active surfaces and you want the closest local
match to the Linux CI lane, use this order after exporting the xlsxio helper:

1. `zig build logical_shortint_parity --summary none`
2. `zig build stack_state_parity --summary none`
3. `zig build register_metadata_parity --summary none`
4. `zig build flags_parity --summary none`
5. `zig build both --summary none`
6. `zig build test --summary none`
7. `zig build generated --summary none`
8. `zig build both_asan --summary none`
9. `zig build test_asan --summary none`
10. `zig build docs --summary none`
11. `zig build dmcp --summary none`
12. `zig build dmcpr47 --summary none`
13. `zig build dmcp5 --summary none`
14. `zig build dmcp5r47 --summary none`
15. `zig build dist_linux --summary none`

## Generated Artifact Diff Contract

After `zig build generated --summary none`, compare only the tracked generated
sources and generated test data refreshed by that step.

Do not use unrelated diffs as proof that the generated-artifact contract moved.

## When To Rebuild From The Top

Run a broader grouped lane when:

- the change crosses host, generated-artifact, and packaging ownership at the
  same time
- a focused lane passes but a CI job name or artifact contract changed
- a `zig build clean` run removed tracked generated outputs and you need to
  re-establish the full generated surface

## Verification Change Rules

- Keep the smallest rerun lane explicit in docs and reviews.
- Update this page whenever a public target name, focused test lane, or tracked
  generated output list changes.
- Prefer executable checks over visual confidence.
- If a lane cannot run locally, record the exact blocker and the narrower file
  or workflow evidence that was checked instead.