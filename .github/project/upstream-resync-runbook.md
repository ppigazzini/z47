# Upstream resync runbook

The ordered procedure for advancing the imported upstream C baseline (the pin in
`upstream-pin.env`) and re-deriving z47's Zig port on top of it. Written after the
first all-Zig resync (`f553b07f → 0caee2adc`), whose four CI failures are encoded
below as guardrails so the next resync is a checklist, not a rediscovery.

## 0. Scope the range (never a whole-tree diff)

- We track upstream **`master`** only. Feature/WIP branches ahead of master are NOT
  the mainline — do not import them.
- Import **only the changed paths that already exist in z47**:
  `git diff --name-only <oldpin>..<newpin>` intersected with the tracked tree.
  A whole-tree diff vs the new pin clobbers z47's own divergences (removed files,
  patched `tools/size.py`, etc.). See `upstream-sync-import-only-changed-paths`.
- z47's `src/` is a SNAPSHOT, not a git descendant of the pin — `merge-base(pin,
  HEAD)` is an old ancestor, so ownership/ledger diffs use the pin as the base.

## 1. Import + seam re-sync (mostly "free")

The seams re-sync deterministically; run their audits after importing:

- **Item table** — `LAST_ITEM` and `frontier_items.zig`'s `indexOfItems` mirror
  `items.c`. Re-emit with `audit-item-table-parity.py --emit`; the row→line splicer
  counts `.{ .func` rows (NOT `line = base + N`). Gate: `audit-item-table-parity.py`.
- **Constant blob offsets** — when upstream adds constants the whole blob shifts and
  every hardcoded offset breaks (stale offset → decNumber reads a garbage digit
  count → xcopy SEGV). Remap **by name**: regenerate the OLD `constantPointers.h`
  in a throwaway `git worktree`, pair old↔new offsets by constant name. Five owner
  classes carry offsets: abi `constants.zig` `at()`, `const NAME = constR(N)`
  (frontier_display/screen/addons), `conversionFactorOffsets[]`, `OFF_const_NAME`
  (frontier_conversion_units), `offset_const_*` (math_runtime_helpers) + the WP34S
  Lanczos base. Gate: `zig build constants && check-constant-offsets.py`.
- **abi struct layout** — gate: `zig build abi-layout-parity`.
- **Constant/enum mirrors** — gate: `audit-constant-parity.py`.

## 2. Re-port behavioral drift

Re-derive changed C behavior into the Zig owners (never edit `src/`). Prefer
**idiomatic fixed-width Zig** over transliterated C — see the Windows trap in §4 and
`c-abi-width-types-are-transliteration-debt`.

## 3. THE GATE — run the full local gate before every push

**`bash .github/project/run-local-gate.sh`**

This reproduces the Linux CI verdict: governance checks + the host-parity
build/test/oracle battery (`run-host-parity-battery.sh`, byte-identical to the CI
step) + the tracked-generated-artifact diff. `zig build sim` and `zig build
test:unit` are NOT the gate — three of the first resync's four failures were green
under sim+test:unit and only surfaced in CI:

1. **A parity oracle stopped COMPILING** (`math_command_wrappers_parity`: upstream
   moved a helper's call site to a TU included before its definition in the
   multi-`#include` oracle harness → needs a forward decl). Caught by the battery,
   not by sim/test:unit.
2. **A stale generated artifact** (`res/testPgms/testPgms.bin`): the item table grew
   but the tracked binary was not regenerated. `zig build testPgms` (deterministic)
   + commit. Caught by the artifact diff. Regenerate it on every item-table/pin
   advance.
3. **Source-ownership** red — see §5.

## 4. The Windows LLP64 trap (the one lane you can't run locally)

The fourth failure only reproduces on Windows: `c_long`/`c_ulong` are 64-bit on LP64
(Linux/macOS) but **32-bit on Windows LLP64**, so an `@intCast` of a wider value
truncates and PANICS at runtime on Win64 only. `saveStateValue` cast a full 64-bit
state word to `c_ulong` and panicked the Windows testSuite.

- Guard: **`check-portable-int-widths.sh`** (in the local gate and CI) flags
  value-carrying casts to `c_long`/`c_ulong`; use `i64`/`u64` instead, or allowlist
  a provably ≤32-bit value in `portable-int-width-allowlist.txt`.
- The lint is a Linux-runnable proxy, but it cannot catch every Windows-only issue.
  If a resync touches host serialization / RNG / time / file-offset code, either
  reason explicitly about LLP64 widths or run the Windows testSuite (locally via a
  `x86_64-windows` cross-build under Wine, or just let the CI Windows lane adjudicate
  and be ready to fix a width panic).

## 5. Finalize — pin + ownership + ledger, together

Do this as ONE step, and know that **until it lands, every pushed in-progress commit
fails the source-ownership lane** (the tree is at the new pin while `upstream-pin.env`
still names the old one, so newly-imported files read as unapproved). Either finalize
early, or expect (and ignore) source-ownership red until the finalize commit:

- `upstream-pin.env`: bump `UPSTREAM_COMMIT` + `UPSTREAM_PIN_UPDATED` (verify the new
  pin is an ancestor of `upstream/master`).
- `source-ownership.txt`: register any new imported files under
  `[approved-z47-additions-under-imported]`.
- `upstream-port-ledger.tsv`: add the required status row for the new pin.
- Raise any idiom-ratchet ceiling the resync legitimately needed (e.g. new mandated
  dispatch `callconv(.c)` exports).

Do **not** merge the sync branch to `main` until `run-local-gate.sh` is green and the
full CI matrix (Linux + macOS + **Windows**) is green.
