# Glossary

The words the rest of this set uses without stopping to define them, in two
tiers that must not be confused:

- **The calculator's vocabulary is upstream's.** `item`, `TAM`, `real34`,
  `softmenu`, `calcMode` and the rest name things in the C47 product. z47 does
  not own those definitions and does not restate them here.
- **z47's vocabulary is this repository's.** `owner`, `seam`, `oracle`, `gate`,
  `ratchet` and the rest name things the port invented. None of them appears in
  the upstream source, and upstream is not obliged to agree with any of them.

A reader who cannot tell which tier a word is in will grep the imported `src/`
tree for `owner` and not find it. That is the failure this split exists to
prevent.

Audit basis: 2026-07-30, upstream pin `4697e526a`, Zig `0.16.0` stable.

## What This Page Does Not Cover

| subject | owner |
| --- | --- |
| the calculator's own terms | the companion c47-r47-ci doc set, `docs/09-glossary.md` (see [90-official-references.md](90-official-references.md)) |
| where a Zig owner lives | [10-build-and-source-layout.md](10-build-and-source-layout.md) |
| what a verification lane does | [70-tests-and-verification.md](70-tests-and-verification.md) |
| what a detector can and cannot see | [75-debugging.md](75-debugging.md) |
| the seam-and-core rules themselves | [50-zig-c-boundaries-and-rewrite-policy.md](50-zig-c-boundaries-and-rewrite-policy.md) |

No entry here carries a count. Counts belong on the page that can show how it
derived them, with the command beside the number.

## The Calculator's Terms

Upstream owns these. The companion c47-r47-ci doc set defines them against the C
source, and its `docs/09-glossary.md` is the page to read; two of its warnings
are worth repeating because they cost time in this repo too:

- **TAM and SHOI are never expanded in the upstream source.** Any expansion you
  have seen is folklore. The behaviour is verified; the letters are not.
- **`register` means two disjoint things** -- a lettered register (the stack,
  `L`, `I`/`J`) and a named variable in a wholly separate ID space. A register
  number is meaningless without knowing which space indexes it.

The terms z47's own pages lean on hardest, so you know what to look up: `item`
and the item table, `softmenu`, `calcMode`, `real34`/`complex34`/long integer,
`TAM`, `HAL`, `QSPI`/`TO_QSPI`, `DMCP`/`DMCP5`, `DMCP_PACKAGE`, `OLD_HW`/
`NEW_HW`, and the `.p47`/`.s47`/`.d47` file extensions.

## z47's Terms

None of these appear in the imported upstream tree. Where a script owns the
definition, the script wins.

| term | what it is |
| --- | --- |
| **owner** | one `.zig` file under `zig_src/` that owns an upstream C file's behaviour. The binding is recorded in `.github/project/upstream-correspondence.tsv` and checked by `check-upstream-correspondence.py`; an owner is not required to mirror the C file's shape, only its observable behaviour |
| **the seam** | the generated ABI layer under `zig_src/abi/`: the `extern struct` layouts, `callconv(.c)` signatures and constant-blob offsets that upstream's ABI dictates. Derived from the C, regenerated when the pin advances, and never hand-edited. The idiom ratchet counts seam files separately and does not grade them |
| **core and shell** | the two zones under `zig_src/`. `core/` is the headless calculator; `shell/` is the interactive surface (display, menus, keyboard, plotting). `check-core-shell-severance.py` guards the direction of travel: core may not `@import` a shell source file, ever |
| **host hook** | one installable callback in `zig_src/abi/host.zig` through which the headless core signals the shell (redraw, abort poll, progress line, bug screen) without linking it. Each slot is a single weakly-exported C-ABI symbol; the interactive entry points install the real implementations at startup and a headless link keeps the neutral default. See [75-debugging.md](75-debugging.md) for why an uninstalled hook is a false-pass hazard |
| **the frontier** | `zig_src/frontier.zig`, a module-root carrier that force-imports owners so they land in the build even when nothing references them by name. A carrier is not a layer -- it holds no logic |
| **oracle**, **parity lane** | a focused test that compiles the retained upstream C for one owner and asserts the Zig produces the same bytes: `zig build <owner>_parity`. This is what lets the C leave the product without losing the proof |
| **the corpus** | the upstream behavioural regression files under `src/testSuite/tests/`, replayed by `zig build test`, plus the `*_cov.txt` coverage extensions. Shared with upstream, so a corpus file is a statement about the calculator, not about the port |
| **cov test**, **`*Cov` function** | a coverage case written in C inside `src/testSuite/testSuite.c` and driven from a corpus `.txt` file, for behaviour no keystroke sequence can reach |
| **the gate** | `.github/project/run-local-gate.sh`, the one command that reproduces the Linux CI verdict locally. "Green" without an exit code is not green |
| **guard** | one governance check inside the gate (`check-*.sh`, `check-*.py`). Distinct from a Zig safety check and from ordinary "guarded by" prose |
| **ratchet** | a bound that may only move one way. The idiom ratchet (`.github/project/idiom-status-baseline.json`) caps transliteration anti-patterns; the coverage ratchet caps corpus shrinkage. Raising one is a deliberate act with a justification in the commit |
| **baseline**, **allowlist** | a checked-in file of accepted findings a guard diffs against. A new entry fails; a vanished one is a gain to be re-pinned |
| **the pin** | the upstream commit z47 is ported against, in `.github/project/upstream-pin.env`. Every parity claim is a claim *at the pin* and nowhere else |
| **the ledger** | `.github/project/upstream-port-ledger.tsv`, one row per upstream commit range recording what was ported and what was deliberately not |
| **resync**, **pin advance** | importing a newer upstream commit and re-porting what changed, per `.github/project/upstream-resync-runbook.md` |
| **retained C** | upstream C still compiled somewhere. Three disjoint kinds, and conflating them misreads the port's status: **product** (none -- zero first-party C in the sim and firmware), **oracle** (compiled only by parity lanes), and **third-party** (decNumberICU, GMP, GTK, the SDKs) |
| **the imported tree** | `src/`, `dep/`, `docs/`, `res/`, `LIBRARY/`, `PROGRAMS/` and the upstream build files: read-only audit input, never edited to make a z47 change pass. `.github/project/source-ownership.txt` is the authority on which root is which |
| **the differential** | running the same corpus against upstream's C build and z47's build and diffing an instrumented trace. The technique [75-debugging.md](75-debugging.md) is built around |
| **drawer** | one build-object directory: the unit `check-file-cohesion.sh` grades. Carved by dependencies, not by file count |

## Words That Mean Two Things

Each of these has cost someone time here.

| word | meaning A | meaning B |
| --- | --- | --- |
| **owner** | a `.zig` file that owns a C file's behaviour | the zone that owns a *fact* in this doc set |
| **core** | `zig_src/core/`, the headless zone | "the calculator core", the whole ported product |
| **seam** | the generated ABI layer | any Zig/C boundary, in loose prose |
| **guard** | a governance check in the gate | a Zig safety check, and ordinary "guarded by" prose |
| **ratchet** | the idiom baseline | the coverage floor |
| **frontier** | `zig_src/frontier.zig`, the carrier | `zig_build/frontier/`, its build registration |
| **corpus** | the testSuite regression files | the malformed-input seed set `zig build pgm_load_fuzz` drives |
| **lane** | one CI job | one focused `zig build` verification target |
| **test** | `zig build test`, the corpus run | `zig build test:unit`, native Zig unit tests with no C oracle |
| **c43** | the upstream repository name | the local clone the differential builds from |
