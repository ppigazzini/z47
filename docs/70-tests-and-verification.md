# Tests And Verification

This page maps the maintainer verification surfaces, the contracts they lock, and
the smallest rerun lane that should move with each kind of change.

Read [10-build-and-source-layout.md](10-build-and-source-layout.md) first. This
page assumes the build entrypoints and ownership split are already clear.

Audit basis: 2026-08-03, upstream pin `b9e1cc0c1`, Zig `0.16.0` stable. The
per-owner parity section was re-audited on that date, when the last
hand-transliterated oracle FILE was converted. One lane still carries
hand-written reference FUNCTIONS inside a compiled oracle — see the rule below.

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

Step `[10a/11]` runs both malformed-input corpora through the real load paths.
They are the only adversarial coverage those paths have -- every other lane feeds
them files the calculator itself just wrote -- and they cost about a second each
once built. The state lane checks two things: that the restore path did not
crash, hang or trip a Zig safety check, and that it produced the outcome the
corpus states. The second is not redundant: the defect class includes SILENT
wrong-accepts, and a crash detector cannot see one. Both assertions are verified
to fire by reverting the fixes they guard.

**Know what the state corpus is before citing it.** It holds five files, and
every one is a reproducer of a bug that was already found and fixed -- four from
the matrix-dimension guard, one from the version forgery. It is a REGRESSION
suite: it will prove those fixes have not come undone, and it will not find a
sixth bug, because nothing in it explores input nobody has looked at. The
truncation sweep, section-count mutations and structural mutations that would
make it a real corpus are specified and unbuilt; the sibling `.p47` corpus has 27
files by comparison, and found three real bugs the afternoon it was written. Do
not read a green `state_load_fuzz` as "the restore path handles malformed input";
read it as "these five known cases still behave".

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
| constant-blob offset parity | `../src/abi/constants.zig`, `../.github/project/check-constant-offsets.py` | `zig build constants && python3 .github/project/check-constant-offsets.py` |
| constant/enum mirror parity | `../.github/project/audit-constant-parity.py` | `python3 .github/project/audit-constant-parity.py` |
| item-table parity | `../src/shell/display/items/items.zig`, `../.github/project/audit-item-table-parity.py` | `python3 .github/project/audit-item-table-parity.py` |
| abi struct-layout parity | `../build/tests/abi_layout/` | `zig build abi-layout-parity --summary none` |
| per-owner behavioral parity | `../src/<domain>/`, `../build/tests/<owner>/` | `zig build <owner>_parity --summary none` (see below) |
| native Zig unit tests (no C oracle) | `../build/`, `src` module tests | `zig build test:unit --summary none` |
| host simulator build | `../build/host/` | `zig build sim --summary none` |
| host live-behavior smoke | `../build/host/simulator_smoke.sh` | `zig build simulator_smoke --summary none` (non-blocking; known Xvfb pixman over-read) |
| host core regression | `../build/host/`, `../upstream/src/testSuite/` | `zig build test --summary none` |
| native C-sanitizer lane | `../build/host/steps.zig` | `zig build both_asan --summary none` then `zig build test_asan --summary none` |
| malformed-input load fuzz (untrusted `.p47`) | `../build/tests/pgm_run/malformed/`, `../build/tests/pgm_run/run-pgm-load-fuzz.sh` | `zig build pgm_load_fuzz --summary none` |
| malformed-input load fuzz (untrusted `.sav` / `.d47`) | `../build/tests/calc_state/malformed/`, `../build/tests/calc_state/state_load_harness.c`, `run-state-load-fuzz.sh` | `zig build state_load_fuzz --summary none` |
| deterministic generated outputs | `../build/tools/`, tracked generated files | `zig build generated --summary none` |
| docs surface | `../upstream/docs/code/` | `zig build docs --summary none` |
| firmware outputs | `../build/firmware.zig`, imported SDKs, linker scripts | `zig build dmcp --summary none` or `zig build dmcp5 --summary none` |
| host or firmware packages | `../build/dist.zig` | `zig build -Doptimize=ReleaseFast dist_linux --summary none`, or the matching package target |

## Per-Owner Parity Oracles

Each ported owner keeps a focused parity lane that compiles the retained upstream
C as an oracle and asserts the Zig output matches it. These are the verification
surface that lets the C be retired from the product while proving behavior. Run
the lane for the owner you touched, for example:

### The rule: an oracle must be compiled from c43 source

**Every parity oracle must be, or be compiled from, unmodified c43 source.** The
only question that matters about a parity reference is *when c43 changes, does this
reference change with it?* — and a hand-transliterated oracle answers no. It does
not merely fail to detect a divergence: it manufactures positive evidence that
parity holds, because the lane whose purpose is catching the change is the reason
nobody sees it. A missing test is visible in a coverage discussion; a passing one
is not.

Concretely, when writing or touching an oracle:

- `#include` the c43 `.c` under `oracle_*` renames. Where the file sits next to
  `src/c47/c47.h`, the harness header must claim upstream's own `C47_H` guard — a
  quoted `#include "c47.h"` searches the including file's directory first and no
  `-I` outranks that.
- Do not hand-copy c43 constants into the harness header either; that is the same
  defect one level down, and
  [check-harness-constant-copies.py](../.github/project/check-harness-constant-copies.py)
  now measures it, and `EXTRA_INFO_ON_CALC_ERROR` should be upstream's own value so
  c43's diagnostic branches COMPILE rather than being configured away.
  For a UNIT harness, prefer upstream's own `c47.h` outright:
  call `build/tests/c43_oracle.zig`'s `addUpstreamHeaderRoots` on the parity
  executable and the harness declares no constants at all. (No lane calls it
  today — the three conversions after it all went full-core — but the same four
  roots are exercised by `check-harness-constant-copies.py` on every gate run.) It puts `build/tests/common`
  (the stub `gtk`/`gdk` headers plus the six placeholder typedefs in
  `c43_harness_prelude.h`), `dep/decNumberICU`, `src/generated` and `src/c47` on
  the include path, with the same PC_BUILD/platform/word-size macros the product
  host build uses — a different macro set would make the oracle a different
  *configuration* of c43 rather than c43.
- Stubs in the harness are fine and expected. They are the *environment*, shared by
  both implementations; what may not be hand-written is the *reference*.
- A harness header must not `#define` a name that upstream declares as a function
  or defines as a macro. That is the constant-copy defect in its most damaging
  form: the substitution reaches c43's own source, so the reference computes the
  harness's answer and the lane can never report a divergence in the substituted
  behaviour. `grep` the harness `.h` for `#define`s of names that resolve to
  functions or to `STD_*` glyph macros upstream.
- A conversion is not verified until the lane has been **seen to fail**: patch a
  behavioural change into the c43 file, confirm red, revert. A conversion that
  cannot be shown to fail has been assumed, not verified. **Read the result off the
  built artifact** (`.zig-cache/o/*/<exe>`), not off `zig build <lane>` — a Run step
  can report success from cache while the new binary fails.

**A reference is a FUNCTION, not a file.** Every hand-transliterated oracle FILE
is converted and the `frozen` list in
`.github/project/oracle-provenance-manifest.json` is EMPTY — but that is not the
same claim. Hand-written reference bodies can live inside a file that *also*
`#include`s c43 source, which is exactly why such a file is never eligible for
that list. `check-oracle-provenance.py` counts those separately and **both counts
are now zero**. Keep them there: every reference in the tree is c43's own code,
and the ratchet does not go back up.

`math_wrappers` is a special case worth knowing before you touch it: its `real_t`
is a hand-declared struct, decNumber is not linked, and its `const39_*` are
placeholder decimals, so the 86 c43 files it compiles run on fake arithmetic and
what the lane compares is CONTROL FLOW. Compiling more c43 into it does not help —
measured twice, recorded in the file. **There are two math-wrapper lanes and they
answer different questions.** `math_command_wrappers_parity` drives 436 cases over
88 wrappers and tells you which paths a wrapper takes;
`math_wrappers_full_core_parity` drives 1140 cases over 32 and tells you what it
computes, because there both sides run on real decNumber and the real register
file. Neither substitutes for the other, which is why the first is not deleted.
In the vocabulary of
[90-official-references.md](90-official-references.md), that environment is a
**Fake** and its snapshot of 62 call counters is a **Spy** — so a green run there
says the wrappers *called* the same functions with the same arguments, and says
nothing about whether they computed the right number.

### The rule: an owner must not change what it does because it is tested

A build-option conditional inside an owner is fine when it mirrors an upstream
`#if` — z47 is a 1:1 port of a C program full of them, and `DMCP_BUILD`,
`SAVE_SPACE_*`, `OPTION_*` and even `TESTSUITE_BUILD` (which c43 uses itself) all
have to be mirrored. It is a defect when it exists only because z47 has a harness.

That distinction is not academic. An owner compiled
`ERROR_INVALID_DATA_TYPE_FOR_OP` as 2 for the unit harness and 24 for the product;
the harness header carried the same 2; the lane's two sides agreed perfectly about
a number c43 has never used, and error codes in that lane were held to nothing.
The same flag gave the harness build a matrix header with **no `mtag` field**, so
no matrix angular-mode behaviour was reachable from the only lane that tests
matrices.

[check-owner-build-conditionals.py](../.github/project/check-owner-build-conditionals.py)
ratchets these. Its most useful clause is that an option which is neither
allowed nor banned is **a decision nobody has made** — that is what surfaced
`free_regions_are_inline_array` and `use_array_backed_global_registers`, the same
seam under names that do not start with `use_fake_`.

Feathers calls this a preprocessing seam; see
[90-official-references.md](90-official-references.md).

### The rule: a parity lane that is in no gate is not a lane

Adding a lane is half the work; the half that keeps it alive is putting it in
[run-host-parity-battery.sh](../.github/project/run-host-parity-battery.sh).
An unrun lane is worse than a missing one — it reads as coverage while proving
nothing, which is the same failure mode as a hand-written oracle one level up.

### The rule: know which surfaces the oracle cannot reach

The imported c43 tree answers one question — *does this owner still do what
upstream does?* — and there are two surfaces where it cannot answer at all. Both
produce green gates that mean nothing, so they have to be verified some other way
rather than assumed.

**Owners with no upstream counterpart.** Part of `src/` is port scaffolding that
c43 has no file for: the shared ABI module, the typed constant-blob accessors,
the dispatch and predicate helpers, the command-wrapper runtime. Which owners
these are is recorded by the join in
`.github/project/upstream-correspondence.tsv` and checked by
[check-upstream-correspondence.py](../.github/project/check-upstream-correspondence.py)
— read the manifest for the current set rather than a number written here. A
1:1 diff says nothing about that code, and neither do the per-owner parity
oracles, because there is no c43 function to compile as the reference. It is held
by the shared testSuite and the native unit tests alone, and a change there needs
a behavioural test, not a reading.

**Code behind a firmware-only build guard.** Every lane that *runs* a program in
the local gate is a host build. An owner branch selected by `DMCP_BUILD`, by
`old_hw`, or by a `.freestanding` target test is compiled — step `[10b/11]` links
every DMCP package variant, which is what catches a branch that no longer builds
— but nothing in the gate executes it. So the gate proves those branches compile
and says nothing about what they do, by construction rather than because they are
correct. A guard that returns early on the firmware target changes what both
firmware images compute while every lane stays green. When a change adds or edits
a firmware-only branch, the evidence is a hardware or simulator check, and the
commit should say which one was run. `extra_info_on_calc_error` is a second case
of the same shape: it is forced off for the testSuite build, so the diagnostic
branches gated on it are outside the testSuite's reach even on the host.

This is not theoretical. Both known instances were found by accident, not by a
gate: the seven focused math differentials were broken at LINK time while the full
local gate stayed green, and `distribution_parity` had stopped COMPILING
entirely at HEAD — its module was rooted one directory too deep for its own
imports, and it had never been given the `abi` module, a second failure the first
one masked. Both are in the battery now.

The one exception, and state it out loud when you take it: **do not add a red lane
to the battery to "track" it.** A gate that is expected to fail is a gate somebody
disables. Fix it first, or leave it out and give it a milestone.

`check-oracle-provenance.py` (local gate and CI) keeps the file-level list empty:
re-adding an entry is a written admission that a lane cannot see c43 move, and it also
re-runs the one *generated* oracle's extractor (`charstring_diff`) and demands
byte-identical output. A compiled-from-c43 oracle needs no entry at all, because
`check-imported-tree-pin.py` already holds the source it includes to the pin.

Three of the five conversions took the FULL-CORE shape rather than a linked unit
oracle -- `calc_state`, `register_metadata`, `keyboard_state`. The rule for
choosing: if sharing the environment "for real" means sharing the register pool,
the value codecs or the GUI toolkit, the unit harness has to MODEL them, and then
the lane measures the model. In a full core they are shared by construction and
the stub burden is zero. `charstring_diff` is the precedent for the shape.

This is not a local invention. The external basis — and the table that classifies
every check kind in the tree, so a *new* check can be classified in one reading
instead of argued about — is in
[90-official-references.md](90-official-references.md) under *Test Oracle And
Differential-Testing References*. The short version: a `*_parity` lane is
**differential testing** (McKeeman 1998) against a **derived oracle** (Barr et
al. 2015), a hand-written oracle loses all of its power to **correlated failure**
(Knight & Leveson 1986) because it shares an author and a misreading with the
port, and a golden file is a **characterization test** (Feathers 2004) — a change
detector, never a parity reference.

- `zig build logical_shortint_parity`, `zig build rotate_bits_parity`,
  `zig build logical_boolean_ops_suite` (short-integer owners)
- `zig build stack_state_parity`, `zig build register_metadata_parity`,
  `zig build flags_parity`, `zig build memory_parity`,
  `zig build program_serialization_parity`, `zig build calc_state_parity`,
  `zig build keyboard_state_parity` (state owners). `calc_state_parity` is the
  one that holds the `.sav` **format** to c43: it links c43's own
  `saveRestoreCalcState.c` beside the Zig owner in a full core and compares the
  saved bytes, so a c43 format change turns it red rather than passing silently.
- `zig build math_command_wrappers_parity`, `zig build math_random_parity`,
  and the focused `zig build math_*_oracle` lanes (mathematics owners)
- `zig build constants_parity`, `zig build tone_parity`,
  `zig build saveload_roundtrip`, `zig build format_parity`,
  `zig build distribution_parity`, `zig build eigen_parity`

The full current set is discoverable with `zig build --help`.

## Which Lane To Run First

- docs-only change under `docs/`, `CONTRIBUTING.md`, or `README.md`:
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
  through the real load path under UBSan -- not AddressSanitizer, despite the
  harness name; see [75-debugging.md](75-debugging.md). The per-owner cov tests only
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
