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
| imported upstream pin and repo-root import contract | `../.github/project/upstream-pin.env` | upstream-branch reachability check plus source-manifest job | `git fetch <upstream-url> <upstream-branch> && git merge-base --is-ancestor <pinned-upstream> FETCH_HEAD` |
| tracked top-level ownership contract | `../.github/project/source-ownership.txt`, `../.github/project/check-source-ownership.sh` | source-ownership guard script | `git fetch <upstream-url> <upstream-branch> && bash .github/project/check-source-ownership.sh` |
| workflow imported-root CI vocabulary | `../.github/project/workflow-imported-root-paths.sh`, `../.github/workflows/upstream-oracle.yml` | workflow imported-root guard script | `bash .github/project/workflow-imported-root-paths.sh check-workflow` |
| checked-in Zig or C boundaries | `../.github/project/zig-c-boundaries.txt`, `../.github/project/check-zig-c-boundaries.sh` | boundary guard script | `bash .github/project/check-zig-c-boundaries.sh` |
| short-integer mask, count, and bit-toggle parity | `../zig_src/leaf/`, `../zig_build/tests/` | focused parity executable | `zig build logical_shortint_parity --summary none` |
| rotate, justify, mirror, byte-swap, zip, and unzip parity | `../zig_src/leaf/`, `../zig_build/tests/rotate_bits/` | focused parity executable covering the live `logicalOps/rotateBits.c` owner replacement | `zig build rotate_bits_parity --summary none` |
| logical boolean operator rewrite regression | `../zig_src/leaf/`, `../zig_build/tests/testSuiteList_logical_boolean_ops.txt`, `../src/testSuite/tests/` | focused host test-suite list covering `and`, `or`, `not`, `nand`, `nor`, `xor`, and `xnor` after the live owner replacement | `zig build logical_boolean_ops_suite --summary none` |
| stack-state rewrite parity | `../zig_src/state/`, `../zig_build/tests/stack_state/` | focused parity executable | `zig build stack_state_parity --summary none` |
| register-metadata rewrite parity | `../zig_src/state/`, `../zig_bridge/state/`, `../zig_build/tests/register_metadata/` | focused parity executable | `zig build register_metadata_parity --summary none` |
| system-flag rewrite parity | `../zig_src/state/`, `../zig_bridge/state/`, `../zig_build/tests/flags/` | focused parity executable | `zig build flags_parity --summary none` |
| memory-helper rewrite parity | `../zig_src/state/`, `../zig_bridge/state/`, `../zig_build/tests/memory/` | focused parity executable | `zig build memory_parity --summary none` |
| program-serialization rewrite parity | `../zig_src/state/`, `../zig_bridge/state/`, `../zig_build/tests/program_serialization/` | focused parity executable | `zig build program_serialization_parity --summary none` |
| calc-state rewrite parity | `../zig_src/state/`, `../zig_bridge/state/`, `../zig_build/tests/calc_state/` | focused parity executable covering state-file wrappers plus simulator-only backup entrypoints | `zig build calc_state_parity --summary none` |
| mathematics command-wrapper rewrite parity | `../zig_src/mathematics/`, `../zig_bridge/mathematics/`, `../zig_build/tests/math_wrappers/` | focused parity executable covering the command owners plus shared trig and hyperbolic helper exports | `zig build math_command_wrappers_parity --summary none` |
| tone UI rewrite parity | `../zig_src/ui/`, `../zig_bridge/ui/`, `../zig_build/tests/tone/` | focused parity executable covering `fnTone` and `fnBeep` dispatch and refresh behavior | `zig build tone_parity --summary none` |
| keyboard command-surface rewrite parity | `../zig_src/state/`, `../zig_bridge/state/`, `../zig_build/tests/keyboard_state/` | focused parity executable covering the broader public keyboard command entrypoints | `zig build keyboard_state_parity --summary none` |
| keyboard stop-statusbar mask regression | `../zig_bridge/state/keyboard_state_overlay.c`, `../zig_bridge/state/keyboard_state_retained.c`, `../zig_bridge/state/keyboard_statusbar_mask.h`, `../zig_build/tests/keyboard_statusbar_flags_regression.c` | focused host regression executable | `zig build keyboard_statusbar_flags_regression --summary none` |
| host simulator build boundary | `../zig_build/host/`, `../src/c47-gtk/` | simulator build surface | `zig build sim --summary none` |
| host simulator live behavior boundary | `../zig_build/host/`, `../zig_build/host/simulator_smoke.sh`, `../src/c47-gtk/` | live X11 smoke covering LCD, keyboard, and pointer behavior for both simulators | `zig build simulator_smoke --summary none` |
| host core regression | `../zig_build/host/`, `../src/testSuite/` | grouped native test suite | `zig build test --summary none` |
| native Zig C sanitizer lane | `../zig_build/host/steps.zig` | sanitized host build and tests | `zig build both_asan --summary none` then `zig build test_asan --summary none` |
| deterministic generated outputs | `../zig_build/tools/`, tracked generated files | generator refresh plus targeted diff | `zig build generated --summary none` |
| docs surface under `docs/code` | `../docs/code/`, `../docs/code/requirements.txt` | Sphinx and Doxygen lane | `zig build docs --summary none` |
| firmware outputs | `../zig_build/firmware.zig`, imported SDKs, linker scripts | smallest affected firmware target | `zig build dmcp --summary none` or `zig build dmcp5 --summary none` |
| host or firmware packages | `../zig_build/dist.zig`, `../zig_build/zig_dist.py` | matching distribution target plus a fresh archive extraction when packaged runtime behavior matters | `zig build -Doptimize=ReleaseFast dist_linux --summary none` for Linux host-release parity, or the matching host or firmware package target on the relevant platform |

## Which Lane To Run First

- docs-only maintainer doc change rooted in `zig_docs/`, `CONTRIBUTING.md`, or
  `ZIG-README.md`: verify every key claim against live files, then rerun
  `zig build --help --summary none` if target names or options are described;
  rerun `bash .github/project/check-source-ownership.sh` as well when the
  change touches imported-root or tracked top-level ownership claims
- imported-root layout, source-manifest, or top-level ownership change:
  `zig build --help --summary none`, then
  `bash .github/project/check-source-ownership.sh`, then
  `bash .github/project/workflow-imported-root-paths.sh check-workflow`, then
  the smallest affected host or firmware target
- build-graph step rename, option change, or output-path change:
  `zig build --help --summary none`, then the smallest affected target
- generator or tracked generated-artifact change: `zig build generated --summary none`
- calc-state or simulator backup-entrypoint change: `bash .github/project/check-zig-c-boundaries.sh`, then `zig build calc_state_parity --summary none`, then `zig build sim --summary none`; if the slice adds or moves retained C bindings, keep them in `zig_src/state/calc_state_runtime.zig` rather than `zig_src/state/calc_state.zig`; if the slice must stay firmware-safe, rerun `zig build dist_dmcp_pkg3 --summary none`, and rerun `zig build dist_dmcp_pkg2 --summary none` as well when package-2 overlay trims are part of the change
- rotate, justify, byte-order, or zip-state leaf change: `bash .github/project/check-zig-c-boundaries.sh`, then `zig build rotate_bits_parity --summary none`, then `zig build test --summary none`, then `zig build dmcp --summary none`
- short-integer logical boolean operator change: `bash .github/project/check-zig-c-boundaries.sh`, then `zig build logical_boolean_ops_suite --summary none`, then `zig build test --summary none`, then `zig build dmcp --summary none`
- thin mathematics command-wrapper or shared trig-helper change: `bash .github/project/check-zig-c-boundaries.sh`, then `zig build math_command_wrappers_parity --summary none`, then `zig build sim --summary none`; rerun `zig build dmcp dmcp5 --summary none` when the slice must remain firmware-safe across both firmware targets
- tone command-surface change: `bash .github/project/check-zig-c-boundaries.sh`, then `zig build tone_parity --summary none`, then `zig build sim --summary none`, then `zig build -Ddmcp-package=3 dmcp --summary none`
- keyboard input, command-surface, or statusbar-flag change: `zig build keyboard_state_parity --summary none`; if the slice is limited to the stop-statusbar helper, rerun `zig build keyboard_statusbar_flags_regression --summary none`; then rerun `zig build simulator_smoke --summary none` and `zig build test --summary none`; if the slice must stay firmware-safe, rerun `zig build -Ddmcp-package=3 dmcp --summary none`
- host simulator UI, GTK callback, or desktop platform-glue change:
  `zig build sim --summary none`; if the change touches LCD paint, pointer
  routing, or keyboard dispatch, rerun `zig build simulator_smoke --summary none`
- host core or test-surface change:
  `zig build test --summary none`
- boundary or rewrite-slice change: `bash .github/project/check-zig-c-boundaries.sh`, then `zig build logical_shortint_parity --summary none`, `zig build rotate_bits_parity --summary none`, `zig build logical_boolean_ops_suite --summary none`, `zig build stack_state_parity --summary none`, `zig build register_metadata_parity --summary none`, `zig build flags_parity --summary none`, `zig build memory_parity --summary none`, `zig build program_serialization_parity --summary none`, `zig build calc_state_parity --summary none`, or `zig build keyboard_state_parity --summary none` for the touched slice
- docs/code change: `zig build docs --summary none`
- firmware or linker-script change: smallest affected firmware target first
- package or release-proof change: matching `dist_<host>` or firmware package
  target on the matching host OS after
  `bash .github/project/workflow-imported-root-paths.sh check-workflow`; use
  `-Doptimize=ReleaseFast` when reproducing the published desktop host archive
  contract; for Linux firmware publication changes, use `dist_dmcp` plus the
  dedicated `dist_dmcp_pkg*` steps instead of repeating `-Ddmcp-package` on
  the generic `dist_dmcp` target
- packaged host runtime change: after the matching `dist_<host>` target,
  unpack a fresh `zig-out/dist/<archive>.zip` and run the packaged simulator
  from that extraction instead of reusing an older `___TMP` tree; when the
  published host artifact size matters, pair that extraction with
  `-Doptimize=ReleaseFast`
- host package portability change on x86 or x86_64: verify the matching
  `dist_<host>` target from a fresh archive extraction and confirm the packaged
  simulator does not inherit runner-native CPU instructions from the build host

## Full Linux Pre-CI Sweep

When a change touches multiple active surfaces and you want the closest local
match to the Linux CI lane, use this order after exporting the xlsxio helper:

1. `bash .github/project/check-zig-c-boundaries.sh`
2. `bash .github/project/check-source-ownership.sh`
3. `bash .github/project/workflow-imported-root-paths.sh check-workflow`
4. `zig build logical_shortint_parity --summary none`
5. `zig build rotate_bits_parity --summary none`
6. `zig build logical_boolean_ops_suite --summary none`
7. `zig build stack_state_parity --summary none`
8. `zig build register_metadata_parity --summary none`
9. `zig build flags_parity --summary none`
10. `zig build memory_parity --summary none`
11. `zig build program_serialization_parity --summary none`
12. `zig build calc_state_parity --summary none`
13. `zig build math_command_wrappers_parity --summary none`
14. `zig build tone_parity --summary none`
15. `zig build keyboard_state_parity --summary none`
16. `zig build both --summary none`
17. `zig build simulator_smoke --summary none`
18. `zig build testPgms --summary none`
19. `xvfb-run --auto-servernum zig build test --summary none`
20. `zig build generated --summary none`
21. `zig build both_asan --summary none`
22. `xvfb-run --auto-servernum zig build test_asan --summary none`
23. `zig build docs --summary none`
24. `zig build dmcp --summary none`
25. `zig build dmcpr47 --summary none`
26. `zig build dmcp5 --summary none`
27. `zig build dmcp5r47 --summary none`
28. `zig build -Doptimize=ReleaseFast dist_linux --summary none`
29. `zig build dist_dmcp --summary none`
30. `zig build dist_dmcp_pkg1 --summary none`
31. `zig build dist_dmcp_pkg2 --summary none`
32. `zig build dist_dmcp_pkg3 --summary none`
33. `zig build dist_dmcpr47 --summary none`
34. `zig build dist_dmcp5 --summary none`
35. `zig build dist_dmcp5r47 --summary none`

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