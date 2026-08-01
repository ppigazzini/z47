# Debugging z47

This page is about finding a defect the gate did not catch. Read
[70-tests-and-verification.md](70-tests-and-verification.md) first: it owns the
lanes and what each one locks. This page owns what to reach for when a lane is
green and the calculator is still wrong, and what each detector is blind to.

The port's defining advantage is that **the reference implementation is
runnable**. Upstream C47 at the pinned commit answers any question about
intended behaviour exactly, so the first move on a behavioural divergence is
never to reason about the Zig -- it is to make the C say what it does.

Audit basis: 2026-07-30, upstream pin `4697e526a`, Zig `0.16.0` stable.

## What This Page Does Not Cover

| subject | owner |
| --- | --- |
| the lanes, the gate, and which to rerun | [70-tests-and-verification.md](70-tests-and-verification.md) |
| the memory-safety posture and boundary rules | [50-zig-c-boundaries-and-rewrite-policy.md](50-zig-c-boundaries-and-rewrite-policy.md) |
| upstream's own detectors (pool canary, leak scans, Valgrind, Frama-C, coverage floors) | the companion c47-r47-ci doc set, `docs/05-debugging.md` |
| upstream memory limits per platform | the companion set, `docs/06-memory.md` |
| a term you do not recognise | [95-glossary.md](95-glossary.md) |

## Detector To Bug Class

| Bug class | Detector that CAN see it | Blind to it |
| --- | --- | --- |
| wrong value, right shape | the corpus (`zig build test`), with a value assertion | every sanitizer |
| wrong value in one owner | that owner's parity lane, `zig build <owner>_parity` | the corpus, if no case reaches it |
| out-of-bounds index, integer overflow, bad cast in Zig | Zig's own safety checks in a Debug build -- they panic with a stack trace | ASan, which never sees a checked access |
| heap overflow / use-after-free in retained C | `zig build both_asan` then `zig build test_asan` | the corpus, the parity lanes |
| malformed untrusted input (`.p47`, state files) | `zig build pgm_load_fuzz` | the corpus, which only round-trips valid files |
| ABI drift after a pin advance (struct layout, constant blob, item table) | `check-constant-offsets.py`, `audit-constant-parity.py`, `audit-item-table-parity.py`, `abi-layout-parity` | the corpus, which passes until the drift is reached |
| the same constant given two values in two owners | a cross-owner consistency scan: extract the value from each owner and diff | every runtime lane, until one path is exercised |
| the same global given two widths in two owners | `check-extern-var-widths.py` and `check-c-type-alias-widths.sh` | every runtime lane on ELF, where the overrun lands in padding |
| **behavioural divergence from upstream with no crash** | **the C-vs-Zig differential (below)** | everything else, by construction |
| **a code path that never runs** | reading the C, and asking what calls it | every green lane -- see the false-pass catalogue |

Two rows deserve emphasis.

**Zig's safety checks are a detector the C never had.** An index that upstream
reads out of bounds silently becomes a panic here. That is a feature, but it
means a faithful port of an unguarded C read is a crash waiting for the input
that reaches it. When one fires, first establish what upstream does with the
same input -- if the C also reads out of bounds, the fix is a guard whose
behaviour matches what the C's garbage read happened to produce.

**A green lane is not evidence a path ran.** The whole callback boundary between
core and shell was inert for months while the suite was green; see the
catalogue.

**A defect can be real on every target and observable on only one.** A store
that runs past the end of a global writes into whatever the linker put next, and
the linkers disagree about what that is. ELF lays z47's globals out in
definition order with alignment padding between them, so the stray bytes land in
padding and no lane anywhere can see them. COFF gives every export its own
`.bss$name` COMDAT and reorders them, so the same store lands on a live object.
When one target fails alone, the question is not what that target does
differently -- it is which latent write the other targets are absorbing.

## The C-vs-Zig Differential

The procedure that finds a behavioural divergence with no crash, no assertion
and no clue. It is the highest-value technique in this repo.

**1. Build the reference at the pin.** Never at upstream `master` -- a
divergence against an unpinned reference may be a port gap or may be an upstream
change you have not imported yet, and you cannot tell which.

```bash
git -C ../c43 worktree add --detach ../c43-pin "$(grep UPSTREAM_COMMIT .github/project/upstream-pin.env | cut -d= -f2)"
cd ../c43-pin
meson setup build.sim --buildtype=custom -DRASPBERRY="$(tools/onARaspberry)" -DDECNUMBER_FASTMUL=true
ninja -C build.sim src/c47/vcs.h            # first, or the build dies on a missing header
ninja -C build.sim src/testSuite/testSuite
```

Work in worktrees on both sides. The reference gets instrumented and thrown
away; the z47 side gets instrumented too, and nothing should be committed from
either.

**2. Reproduce with the smallest list that still diverges.** Both binaries take
a list file of corpus test names. Write it **inside `src/testSuite/tests/`** --
the runner resolves the corpus and `../../c47/items.h` from the list's own
directory, so a list in a scratch directory finds nothing and exits successfully
having run almost nothing.

Shrink by bisecting the list, not by truncating it: a truncated prefix can drop
the test that resets the state the failure depends on, so the C fails too and
the differential goes quiet. A state-dependent failure that survives down to two
files is worth the minutes it takes to find -- it turns a six-minute suite into
a two-second loop.

**3. Print the same line from the same place on both sides.** Add the probe to
the C in the throwaway worktree and to the Zig owner, with an identical format
string, then diff the two streams. The first differing line is the bug. Work
outward from it: state at entry, then per-iteration values, then per-step values.

**4. Instrument in z47-owned surfaces only.** Never edit the imported `src/`
tree in this repo to add a trace. The throwaway `../c43-pin` worktree is the
place for C probes.

`gdb` cannot attach to a running process here (`ptrace_scope` is restricted), so
a spin cannot be diagnosed by attaching. Print a counter from the suspect on
both sides and diff the sequences instead -- that is what located a solver that
never converged, in one pass.

## Finding A Stray Write On A Lane You Cannot Run

The differential above needs both sides in front of you. When a target fails and
you have no machine of that kind -- a CI lane, and nothing else -- the corpus and
a self-resolving data breakpoint replace it. Both are cheap; the ordering is what
matters, because each step must cost one CI round and no more.

**1. Turn the symptom into values before theorising.** An error string names a
branch, not the term that took it. `graphPlotstat` gates every plot on three
terms and reported only "There is no statistical data available!", which is
equally consistent with lost statistics and with a lost matrix name. A coverage
helper that reads each term back into `REGISTER_X` -- `fnPlotGuardCov` in
`src/testSuite/testSuite.c`, pinned by `graphs_cov.txt` -- answered it in one
round: `plotStatMx[0]` was `0`, the sums pointer was live, `SIGMA_N` was `5`. The
data had never been lost. **Prefer a corpus assertion to a print**: it survives as
regression coverage, it costs the same round, and it cannot be left behind.

**2. Bisect in time with a program, not with prints.** Staging a second program
that stops short of a suspect step says which side of it the damage falls on. A
`SCATR` with the `SNAP` dropped failed identically, which placed the corruption
in the plot rather than the screen capture and retired half the search space.

**3. Watch the byte, not the address.** A page-protection data breakpoint that
reports only when the faulting address *equals* the watched byte will miss every
store that begins below it and runs over it -- and will then report, with total
confidence, that nothing wrote the byte. That single wrong conclusion cost
several rounds here. Snapshot the byte on the fault, single-step the faulting
instruction, and report only if the byte **changed**. That catches the writer
whatever the store's width or start offset.

**4. Resolve symbols in-process, never from a hand-picked list.** Printing the
addresses of the functions you suspect only works if the answer is one of them;
twice it was not, and the reported address fell in a gap. Generate the whole
table instead -- every `pub export fn` and `pub export var` in `zig_src` as
link-time address constants -- and have the probe search it for the nearest
symbol at or below the faulting address. The report then names itself:

```
store is in  fnReturn+0x1c0
victim  is   pemCursorIsZerothStep+0x0
code: c7 05 f9 4f 08 01 01 00 00 00
```

**5. Dump the instruction bytes.** Sixteen bytes at the faulting `RIP` are
disassembled locally without the failing target's binary. Above, `c7 05 <disp32>
01 00 00 00` is `MOV DWORD PTR [rip+disp], 1` -- a four-byte store of `1`, which
is the whole diagnosis: the flag is one byte.

**6. Turn the finding into a gate before deleting the probe.** The probe is
throwaway; the class is not. Write the check, prove it fails against the real
defect by restoring it, then remove the probe in the same commit.

## False-Pass Hazards

Every one of these has passed a broken thing at least once.

1. **A green suite says nothing about code that never runs.** The core-to-shell
   host-hook table was compiled once per build object, so the shell's install
   reached only its own object and every core-side `refreshScreen` was a silent
   no-op -- with the suite green. Making it live exposed three separate ported
   divergences in one afternoon, each invisible until then. **When a call is
   routed through an installable hook, prove the hook is installed in the lane
   you are trusting.** `nm <binary> | grep <hook>` returning more than one
   symbol is the tell.
2. **An error raised in a display path is not cosmetic.** The redraw runs inside
   the solver and the integrator, so an error code left behind by a paint
   routine aborts the next step of the program the engine is evaluating. A stray
   `lastErrorCode` is a wrong answer, not a stray message.
3. **`0 TESTS FAILED` printed before a crash is not a pass.** Capture the exit
   code; the suite prints its summary and can still abort afterwards.
4. **An orphaned `*_cov.txt` never runs.** A corpus file that is registered in
   `funcTestNoParam[]` but not added to the list file silently never executes,
   and the commit falsely claims coverage. After adding one, confirm the total
   case count rose by the number of new `Out:` lines.
5. **A stale plot bitmap fakes a graph pass.** The bitmap hash tests read
   `c47plotTest<N>.bmp` from disk and nothing unlinks it, so a graph program
   that errors before its snapshot is compared against the leftover from an
   earlier passing run. `rm -f c47plotTest*.bmp` before bisecting a plot test.
6. **A parity harness lags the owners it links.** The oracles link a hand-curated
   fake `c47.h` plus stub runtimes. A newly ported cross-owner call breaks them
   at link time, and the break is in the harness, not the port. Expect this class
   on every pin advance and fix it in the z47-owned test surface, never in the
   imported tree.
7. **A stale build is not evidence.** Confirm the binary you ran is the one your
   edit produced, especially when a build step and a run step share a command
   line.
8. **A suite that got faster deserves suspicion.** A run that ends early produces
   fewer findings, and fewer findings can pass a baseline diff.
9. **A width agreed within one owner can still be wrong.** `extern var` states a
   width; nothing checks it against the `export var` that defines the symbol. A
   declaration wider than the definition makes every store through it write past
   the end of the real object. Four owners aliased `bool_t` to `u32` where C
   defines it as one byte, so `pemCursorIsZerothStep = 1` compiled to
   `MOV DWORD PTR [rip+disp], 1` and put three zero bytes past a one-byte flag;
   on Windows the third landed on `plotStatMx[0]` and every stat plot lost its
   matrix name while its statistics stayed perfectly intact. Each owner was
   self-consistent and the corpus was green for eight days. **Only the
   combination is wrong, so only a cross-owner check finds it** --
   `check-extern-var-widths.py` resolves each file's type aliases and compares
   every declaration against its definition.

## Reading The Upstream C

The imported tree is the specification. Two habits pay for themselves:

- **Read the pinned C, not your memory of it.** `git -C ../c43 log -S<symbol>`
  finds the commit that introduced a behaviour, and its message usually explains
  the bug it fixed -- which is the fastest way to learn whether a z47 gap is a
  missed port or a deliberate divergence.
- **Check whether the hunk you are porting had siblings.** Upstream commits
  routinely fix one symptom in three files. `git show --stat <sha>` before
  porting, and confirm each hunk landed or was consciously skipped.

When the answer is "upstream changed this and z47 did not follow", the fix
belongs in the port and the finding belongs in the ledger. When it is "upstream
does this and it is wrong", the port matches upstream anyway: behavioural parity
is the contract, and a divergence -- however correct -- is a divergence.
