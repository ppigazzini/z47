# Tests And Verification

This page maps the maintainer verification surfaces, the contracts they lock, and
the smallest rerun lane that should move with each kind of change.

Read [10-build-and-source-layout.md](10-build-and-source-layout.md) first. This
page assumes the build entrypoints and ownership split are already clear.

Audit basis: 2026-07-30, upstream pin `4697e526a`, Zig `0.16.0` stable.

## The One-Command Local Gate

Before pushing anything non-trivial, run:

```bash
bash .github/project/run-local-gate.sh
```

It runs the governance guards, then the host-parity build/test/oracle battery
(`run-host-parity-battery.sh`, byte-identical to the CI step, which now calls the
same script), then the firmware link for every DMCP package variant, then the
tracked-generated-artifact diff. It fails fast on the first red, and takes about
four minutes warm.

Step `[10b/11]` links **every DMCP package variant** (`zig build dmcp_pkgs_all`),
and it is not redundant with `zig build dmcp` / `dmcp5`. The OLD_HW package-3
layout asserts `_ebss <= 0x10002000` and sits exactly on it, so a few bytes of
static data in any firmware-linked owner fails the link -- in a package variant
only. That happened: one `@setRuntimeSafety(true)` added to `shell/config.zig`
pushed `_ebss` four bytes over, while this gate, `zig build test`, `test_asan`,
`pgm_load_fuzz`, `simulator_smoke` **and `dmcp` and `dmcp5`** were all green. The
step was added because of it, and reinstating that attribute is the check that
the step still works.

What the gate still does NOT cover, which its closing banner now states rather
than papering over: the Windows (LLP64) and macOS host lanes, and CI's firmware
PACKAGING and artifact publication. A green run is those Linux lanes, not the
whole CI verdict.

`zig build sim` and `zig build test:unit` are NOT the full gate. The first
all-Zig upstream resync shipped three CI-only failures that were green under
sim+test:unit -- a parity oracle that stopped compiling, a stale generated
artifact, and a source-ownership violation. The local gate catches all three. The
one class it cannot reproduce on Linux is the Windows LLP64 integer-width trap;
`check-portable-int-widths.sh` (inside the gate) approximates it, and the CI
Windows lane is the final adjudicator. See
`.github/project/upstream-resync-runbook.md`.

`zig build test` runs the shared upstream testSuite (12835 cases at the current
pin; the run prints the total, so read it there rather than trusting this number) plus the Zig-owned suites. Confirm it exits 0, not
just that it printed `0 TESTS FAILED` before any crash.

A green run is not proof a path executed. When the change routes a call through
an installable host hook, or adds a corpus file, or depends on a display-side
side effect, read the false-pass catalogue in
[75-debugging.md](75-debugging.md) before calling the lane evidence.

The corpus itself is shared with upstream, so its authoring rules are upstream's:
the companion c47-r47-ci doc set, `docs/04-testing.md`, owns them. See
[90-official-references.md](90-official-references.md).

## Contract Inventory

| Contract surface | Source of truth | First rerun lane |
| --- | --- | --- |
| full Linux CI verdict | `../.github/project/run-local-gate.sh`, `../.github/project/run-host-parity-battery.sh` | `bash .github/project/run-local-gate.sh` |
| toolchain pin and supported Zig version | `../.github/zig-toolchain.env` | `zig version` against the pinned manifest |
| imported upstream pin and repo-root import | `../.github/project/upstream-pin.env` | `git fetch <upstream-url> master && git merge-base --is-ancestor <pin> FETCH_HEAD` |
| upstream refresh report | `../.github/project/report-upstream-refresh.py` | `python3 .github/project/report-upstream-refresh.py --repo-root . --fetch` |
| upstream port ledger | `../.github/project/check-upstream-port-ledger.py` | `python3 .github/project/check-upstream-port-ledger.py --repo-root .` |
| split first-party C status | `../.github/project/report-c-dependency-status.py` | `python3 .github/project/report-c-dependency-status.py --repo-root .` |
| retained bridge review ledger | `../.github/project/retained-bridge-review.tsv`, `../.github/project/check-retained-bridge-ledger.py` | `python3 .github/project/check-retained-bridge-ledger.py --repo-root .` |
| tracked top-level ownership | `../.github/project/source-ownership.txt`, `../.github/project/check-source-ownership.sh` | `bash .github/project/check-source-ownership.sh` |
| workflow imported-root vocabulary | `../.github/project/workflow-imported-root-paths.sh` | `bash .github/project/workflow-imported-root-paths.sh check-workflow` |
| checked-in Zig/C boundaries | `../.github/project/zig-c-boundaries.txt`, `../.github/project/check-zig-c-boundaries.sh` | `bash .github/project/check-zig-c-boundaries.sh` |
| idiomatic-Zig ratchet | `../.github/project/idiom-status-baseline.json`, `../.github/project/check-idiom-ratchet.sh` | `bash .github/project/check-idiom-ratchet.sh` |
| Windows LLP64 int-width trap | `../.github/project/portable-int-width-allowlist.txt`, `../.github/project/check-portable-int-widths.sh` | `bash .github/project/check-portable-int-widths.sh` |
| cross-owner global widths | `../.github/project/check-extern-var-widths.py` | `python3 .github/project/check-extern-var-widths.py .` |
| cross-owner C type alias widths | `../.github/project/check-c-type-alias-widths.sh` | `bash .github/project/check-c-type-alias-widths.sh .` |
| constant-blob offset parity | `../zig_src/abi/constants.zig`, `../.github/project/check-constant-offsets.py` | `zig build constants && python3 .github/project/check-constant-offsets.py` |
| constant/enum mirror parity | `../.github/project/audit-constant-parity.py` | `python3 .github/project/audit-constant-parity.py` |
| item-table parity | `../zig_src/shell/display/items/items.zig`, `../.github/project/audit-item-table-parity.py` | `python3 .github/project/audit-item-table-parity.py` |
| abi struct-layout parity | `../zig_build/tests/abi_layout/` | `zig build abi-layout-parity --summary none` |
| per-owner behavioral parity | `../zig_src/<domain>/`, `../zig_build/tests/<owner>/` | `zig build <owner>_parity --summary none` (see below) |
| native Zig unit tests (no C oracle) | `../zig_build/`, `zig_src` module tests | `zig build test:unit --summary none` |
| host simulator build | `../zig_build/host/` | `zig build sim --summary none` |
| host live-behavior smoke | `../zig_build/host/simulator_smoke.sh` | `zig build simulator_smoke --summary none` (non-blocking; known Xvfb pixman over-read) |
| host core regression | `../zig_build/host/`, `../src/testSuite/` | `zig build test --summary none` |
| native C-sanitizer lane | `../zig_build/host/steps.zig` | `zig build both_asan --summary none` then `zig build test_asan --summary none` |
| malformed-input load fuzz (untrusted `.p47`) | `../zig_build/tests/pgm_run/malformed/`, `../zig_build/tests/pgm_run/run-pgm-load-fuzz.sh` | `zig build pgm_load_fuzz --summary none` |
| deterministic generated outputs | `../zig_build/tools/`, tracked generated files | `zig build generated --summary none` |
| docs surface | `../docs/code/` | `zig build docs --summary none` |
| firmware outputs | `../zig_build/firmware.zig`, imported SDKs, linker scripts | `zig build dmcp --summary none` or `zig build dmcp5 --summary none` |
| host or firmware packages | `../zig_build/dist.zig` | `zig build -Doptimize=ReleaseFast dist_linux --summary none`, or the matching package target |

## Per-Owner Parity Oracles

Each ported owner keeps a focused parity lane that compiles the retained upstream
C as an oracle and asserts the Zig output matches it. These are the verification
surface that lets the C be retired from the product while proving behavior. Run
the lane for the owner you touched, for example:

- `zig build logical_shortint_parity`, `zig build rotate_bits_parity`,
  `zig build logical_boolean_ops_suite` (short-integer owners)
- `zig build stack_state_parity`, `zig build register_metadata_parity`,
  `zig build flags_parity`, `zig build memory_parity`,
  `zig build program_serialization_parity`, `zig build calc_state_parity`,
  `zig build keyboard_state_parity` (state owners)
- `zig build math_command_wrappers_parity`, `zig build math_random_parity`,
  and the focused `zig build math_*_oracle` lanes (mathematics owners)
- `zig build constants_parity`, `zig build tone_parity`,
  `zig build saveload_parity`, `zig build format_parity`,
  `zig build distribution_parity`, `zig build eigen_parity`

The full current set is discoverable with `zig build --help`.

## Which Lane To Run First

- docs-only change under `zig_docs/`, `CONTRIBUTING.md`, or `README.md`:
  verify every key claim against live files; rerun `zig build --help` if targets
  or options are described; rerun `bash .github/project/check-source-ownership.sh`
  if imported-root or ownership claims changed
- upstream pin advance (resync): follow
  `.github/project/upstream-resync-runbook.md`, then
  `bash .github/project/run-local-gate.sh`
- owner logic change: `zig build <owner>_parity`, then `zig build test`, then the
  smallest firmware target if it must stay firmware-safe (`zig build dmcp` /
  `zig build dmcp5`)
- Zig/C boundary or generated-seam change:
  `bash .github/project/check-zig-c-boundaries.sh`, then the affected owner parity
  lane, then `zig build generated`
- host serialization / RNG / time / file-offset change (Windows LLP64 risk):
  `bash .github/project/check-portable-int-widths.sh`, then the owner parity lane;
  let the CI Windows lane adjudicate the runtime width behavior
- state-load or program-load parse change (untrusted-file surface): the owner
  parity lane, then `zig build pgm_load_fuzz` to drive the malformed-input corpus
  through the real load path. NOT under AddressSanitizer, despite the harness
  name -- no lane in this tree runs a sanitizer, see [75-debugging.md](75-debugging.md);
  a finding here is a crash, a hang or a Zig safety panic. The per-owner cov tests only
  round-trip VALID files, so this lane is what covers truncated, oversized, and
  garbage input. See the memory-safety posture in
  [50-zig-c-boundaries-and-rewrite-policy.md](50-zig-c-boundaries-and-rewrite-policy.md).
- generated-artifact change: `zig build generated`, then
  `git diff --exit-code` on the tracked generated artifacts
- host simulator / GTK change: `zig build sim`; if it touches LCD paint, pointer,
  or keyboard dispatch, `zig build simulator_smoke`
- firmware or linker-script change: the smallest affected firmware target first
- package or release-proof change: the matching `dist_<host>` or firmware package
  target on the matching host OS; use `-Doptimize=ReleaseFast` for the published
  desktop archive contract, and unpack a fresh archive when packaged runtime
  behavior matters

## Full Linux Sweep

`bash .github/project/run-local-gate.sh` is the maintained full Linux sweep and
replaces the older hand-listed lane sequence. For platform surfaces the Linux
gate does not cover, rely on the CI matrix:

- macOS and Windows host lanes (build, test, generated outputs, app smoke)
- firmware validation and publication (`dmcp`, `dmcp5`, `dmcpr47`, `dmcp5r47`,
  and the `dist_dmcp*` package steps)

See [60-ci-and-release-workflow.md](60-ci-and-release-workflow.md) for the lane
split.

## Generated Artifact Diff Contract

After `zig build generated`, compare only the tracked generated sources and
generated test data refreshed by that step (the `run-local-gate.sh` final step
does this). Regenerate `res/testPgms/testPgms.bin` after any item-table growth --
a stale copy fails the diff. Do not use unrelated diffs as proof the
generated-artifact contract moved.

## Verification Change Rules

- When a lane is green and the behaviour is still wrong, switch tools rather
  than rerunning: [75-debugging.md](75-debugging.md) owns the differential
  procedure and the detector-to-bug-class map.
- Keep the smallest rerun lane explicit in docs and reviews.
- Update this page whenever a public target name, focused lane, guard script, or
  tracked generated-output list changes.
- Prefer executable checks over visual confidence; capture the actual exit code.
- If a lane cannot run locally, record the exact blocker and the narrower evidence
  checked instead.
