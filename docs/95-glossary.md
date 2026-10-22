# Glossary

The words the rest of this set uses without stopping to define them, in two
tiers that must not be confused:

- **The calculator's vocabulary is upstream's.** `item`, `TAM`, `real34`,
  `softmenu`, `calcMode` and the rest name things in the C47 product. z47 does
  not own those definitions and does not restate them here.
- **z47's vocabulary is this repository's.** `owner`, `seam`, `oracle`, `gate`,
  `ratchet` and the rest name things the port invented. None of them names a z47
  concept in the upstream source, and upstream is not obliged to agree with any
  of them.

A reader who cannot tell which tier a word is in will grep the imported tree
(`upstream/src/`) for `owner` and find only unrelated uses. That is the failure
this split exists to prevent.

Last verified: 2026-10-23, Zig `0.17.0` stable. The upstream pin is
`UPSTREAM_COMMIT` in `../.github/project/upstream-pin.env`.

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

- **TAM and SHOI are not expanded in the C.** Upstream's manual calls TAM
  "transient alpha mode" and its AN0025 file-format note reads ShoI as short
  integer; the companion glossary gives both sources, and `displayStackSHOIDISP`
  is a separate display setting.
- **`register` means two disjoint things** -- a lettered register (the stack,
  `L`, `I`/`J`) and a named variable in a wholly separate ID space. A register
  number is meaningless without knowing which space indexes it.

The terms z47's own pages lean on hardest, so you know what to look up: `item`
and the item table, `softmenu`, `calcMode`, `real34`/`complex34`/long integer,
`TAM`, `HAL`, `QSPI`/`TO_QSPI`, `DMCP`/`DMCP5`, `DMCP_PACKAGE`, `OLD_HW`/
`NEW_HW`, the `.p47`/`.s47`/`.d47` file extensions, and upstream's own coverage
cases: a **cov test** or **`*Cov` function** is a C coverage case inside
`upstream/src/testSuite/testSuite.c`, driven from a `*_cov.txt` corpus file, for
behaviour no keystroke sequence can reach.

## z47's Terms

None of these names a z47 concept in the imported upstream tree. Where a script
owns the definition, the script wins.

| term | what it is |
| --- | --- |
| **owner** | one `.zig` file under `src/` that owns all or part of an upstream C file's behaviour; a decomposed C file has several owners. The binding is recorded in `.github/project/upstream-correspondence.tsv` and checked by `check-upstream-correspondence.py`; a hot owner must keep the C file's shape (`check-transliteration-contract.py`), and a cold owner need only match its observable behaviour |
| **the ABI layer** | `src/abi/`: the `extern struct` layouts, `callconv(.c)` signatures and constant-blob offsets that upstream's ABI dictates, plus what owners share through it -- the host-hook table, the panic namespace, pure value helpers defined once, and registers.c's queries declared once in `abi/registers.zig`. The layouts and offsets are maintained by hand and proven by `zig build abi-layout-parity` and `check-constant-offsets.py`; the item table, proven by `audit-item-table-parity.py`, lives in `src/shell/display/items/items.zig` |
| **the seam** | the idiom ratchet's term for a generated file: one under a `src/*/generated/` path that carries `// SEAM-GENERATED`, regenerated from upstream C and never hand-edited. The ratchet counts seam files separately and does not grade them |
| **core and shell** | the two zones under `src/`. `core/` is the headless calculator; `shell/` is the interactive surface (display, menus, keyboard, plotting). `check-core-shell-severance.py` guards the direction of travel: core may not `@import` a shell source file, ever, and its `extern` edges into shell may not rise above the frozen ceiling the script prints |
| **host hook** | one installable callback in `src/abi/host.zig` through which the headless core signals the shell (redraw, abort poll, progress line, bug screen) without linking it. Each slot is one strong C-ABI export in `src/abi/host_state.zig`, compiled into one object per executable; the host entry points install the real implementations at startup, a headless link keeps the neutral default, and the firmware binds the shell at link time with no slot. See [75-debugging.md](75-debugging.md) for why an uninstalled hook is a false-pass hazard |
| **the frontier** | `src/frontier.zig`, the frontier object's module root: it force-imports owners so they land in the build even when nothing references them by name, and it still holds owner code of its own (the correspondence manifest lists the C files it co-owns) |
| **oracle**, **parity lane** | a focused test that compiles the retained upstream C for one owner and asserts the Zig produces the same result, or for a few lanes compares against golden values: `zig build <lane>`, one of the steps `check-parity-lanes-gated.py` matches by suffix (`_parity`, `_oracle`, `_diff`, `_suite`, `_test`, `-parity`, `-test`). This is what lets the C leave the product while the lanes keep checking it |
| **the corpus** | the upstream behavioural regression files under `upstream/src/testSuite/tests/`, including upstream's own `*_cov.txt` coverage files, replayed by `zig build test`. Shared with upstream, so a corpus file is a statement about the calculator, not about the port |
| **the gate** | `.github/project/run-local-gate.sh`, run with `.venv` on `PATH`: the Linux governance, host-parity and firmware-link lanes, run locally; the rest of CI, Windows and macOS included, runs only there. "Green" without an exit code is not green |
| **guard** | one governance check (`check-*.sh`, `check-*.py`, or a `report-*.py --check` mode), run by the gate or, for the ones its closing banner lists, by CI alone. Distinct from a Zig safety check and from ordinary "guarded by" prose |
| **ratchet** | a bound that may only move one way. The idiom ratchet (`.github/project/idiom-status-baseline.json`) caps transliteration anti-patterns and holds retired spellings at zero; the coverage ratchet (`check-coverage-ratchet.sh`) floors the functions under the C-vs-Zig differential, the full-core parity harness count, and the owner lines the keyboard coverage harness covers. Moving one against its direction -- raising a ceiling, lowering a floor -- is a deliberate act with a justification in the commit |
| **baseline**, **allowlist** | a checked-in file of accepted findings a guard diffs against. A new entry fails; a vanished one is a gain to be re-pinned |
| **the pin** | the upstream commit z47 is ported against, in `.github/project/upstream-pin.env`. Every parity claim is a claim *at the pin* and nowhere else |
| **the ledger** | `.github/project/upstream-port-ledger.tsv`, one row per upstream commit range recording what was ported and what was deliberately not |
| **resync**, **pin advance** | importing a newer upstream commit and re-porting what changed, per `.github/project/upstream-resync-runbook.md` |
| **retained C** | upstream C still compiled somewhere. Three disjoint kinds, and conflating them misreads the port's status: **product** (no hand-written first-party C in the sim and firmware; the generator-emitted `rasterFontsData.c` and `constantPointers*.c` are compiled into both, see [30-host-and-generated-surfaces.md](30-host-and-generated-surfaces.md)), **oracle** (compiled only by parity lanes), and **third-party** (decNumberICU, GMP, GTK, the SDKs) |
| **the imported tree** | everything under `upstream/` -- its own `src/`, `dep/`, `docs/`, `res/`, `LIBRARY/` and build files: read-only audit input, never edited to make a z47 change pass. It is ONE tracked root, and `check-imported-tree-pin.py` holds it byte-identical to the pin; `imported-tree-divergences.txt` is the reviewed exception list, and `source-ownership.txt` is the authority on which root is which. Do not read a bare `src/` or `docs/` anywhere in this set as the imported tree -- those names are z47's |
| **the differential** | running the same corpus against upstream's C build and z47's build and diffing an instrumented trace. The technique [75-debugging.md](75-debugging.md) is built around |
| **drawer** | a dumping-ground file named for how it was produced rather than what it owns (`*_bulk`, `misc`, ...); `check-filename-hygiene.sh` (gate step 1b) bans them, and `check-file-cohesion.sh` grades the opposite failure (dead files and the micro-file ratchet) |

## Words That Mean Two Things

Each of these has cost someone time here.

| word | meaning A | meaning B |
| --- | --- | --- |
| **owner** | a `.zig` file that owns a C file's behaviour | the zone that owns a *fact* in this doc set |
| **core** | `src/core/`, the headless zone | "the calculator core", the whole ported product |
| **seam** | a generated `// SEAM-GENERATED` file | any Zig/C boundary (a `*_runtime.zig` seam), or a byte-dumped ABI table such as the item seam `check-item-seam-drift.py` watches, in loose prose |
| **guard** | a governance check in the gate | a Zig safety check, and ordinary "guarded by" prose |
| **ratchet** | the idiom baseline | the coverage floor |
| **frontier** | `src/frontier.zig`, the carrier | `build/frontier/`, its build registration |
| **corpus** | the testSuite regression files | the malformed-input seed set `zig build pgm_load_fuzz` drives |
| **lane** | one CI job | one focused `zig build` verification target |
| **test** | `zig build test`, the corpus run | `zig build test:unit`, native Zig unit tests with no C oracle |
| **c43** | the upstream repository name | the local clone the differential builds from |
| **drawer** | a dumping-ground file the filename gate bans | one build-object directory, carved by dependencies, not by file count |
