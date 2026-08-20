# AGENTS.md

z47 re-implements the C47 RPN calculator in Zig. Upstream's C is vendored under
`upstream/` as the reference the port is measured against, never as something to
edit or ship.

Read [docs/](docs/README.md) before changing code, [CONTRIBUTING.md](CONTRIBUTING.md)
for the workflow, and `.github/project/upstream-resync-runbook.md` before a resync.
This file is only what an agent gets wrong before it has read them.

The claim z47 makes is function parity with upstream, bounded by what the lanes
reach -- not equivalence over all inputs. Say which lane proved what, and do not
describe the port as bit-for-bit or byte-exact.

Two habits matter more here than the rules that follow. **Bind a fact to the
command that prints it** rather than transcribing the value, because nothing gates
prose in this repository and a transcribed count is wrong from the next commit
onward. And **verify a claim before repeating it**: paths, targets, flags and
counts are all checkable in seconds, and a plausible wrong one survives review.

## Setup

```sh
git submodule update --init   # required before any dmcp* target
uv sync                       # repo Python tooling into .venv
```

Host builds link GTK 3, GMP and FreeType 2 as external system libraries; firmware
needs `arm-none-eabi-gcc`. The Zig version is pinned in `.github/zig-toolchain.env`
together with the master snapshot a non-blocking CI lane tracks; idioms must be
valid under both, so neither `@hasDecl` nor version guards belong in owner code.

`zig build --help` lists every target. `zig build sim` is the C47 simulator,
`simr47` the R47 one, and the `dmcp*` family the firmware images.

## The oracle

`zig build test` runs upstream's testSuite unmodified. It is the measuring
instrument, so its pass count is only meaningful while it stays upstream's: never
add a case to it, and never insert a probe into the imported corpus, which
displaces the line numbers the suite reports failures against. z47's own checks
belong in the parity harnesses under `build/tests/`. Read the total off the run;
it moves with every pin advance. The run must also end with GMP holding nothing.

`upstream/` is read-only. Re-derive changed behaviour into the Zig owner and leave
the C alone -- a gate holds the tree byte-identical to its pin, and an edit there
destroys the reference the harnesses compile against.

## The gate

```sh
PATH="$PWD/.venv/bin:$PATH" bash .github/project/run-local-gate.sh
```

This is the gate. `zig build sim` and `zig build test:unit` are not, and pass over
failures the battery catches, so a change is not done until the gate says so.

It needs `.venv` on PATH, because the repo's Python tooling lives there and a bare
`python3` is missing what the governance scripts import; without it a step dies at
its own banner with no error. It also rewrites tracked owner files in place while
the negative control runs, so do not commit and do not edit a source until it
finishes -- a verdict over a tree that moved under it establishes nothing, and the
restore can overwrite the edit. Redirect it to a log rather than piping it, which
buffers the whole run, and read the exit code rather than any line of output: a
step that skipped for a missing tool is not a pass.

The gate reproduces the Linux lanes only; CI adjudicates Windows and macOS. The
`c_long`/`c_ulong` trap is what usually decides the Windows one, since both narrow
to 32 bits there and a value-carrying cast to either truncates and panics on that
target alone. Use fixed-width types in ported logic and keep C types at real ABI
boundaries.

## Resync

Advancing the pin is the dominant workflow and the runbook owns the procedure.
What agents get wrong before reading it:

Import only the paths that changed between the two pins. A whole-tree diff against
the new pin silently reverts every divergence z47 deliberately holds, and that
includes `.gitignore`, `.gitattributes` and `.gitmodules`, which have to be
reconciled by hand rather than taken whole.

Read the range, not the log. A merge makes older commits newly reachable, so the
subjects can promise changes whose files are byte-identical across the range. Diff
the files.

Port everything the range contains. There are no judgement calls about what is
worth carrying: a refactor with no visible behaviour is a port, and so is a
deletion. `report-resync-worklist.py` names the owner of each changed C file, so
get the worklist rather than grepping and hoping.

Paths in a diff taken against an upstream ref are upstream-relative and need the
`upstream/` hop applied before they name a file here. Ledgers, baselines and
correspondence tables stay upstream-relative and must not be rewritten.

Expect the harnesses to lag. A newly exported upstream symbol collides with the
rename block in each oracle that compiles that file, which shows up at link time;
re-derive those blocks from the object's own symbol table rather than from a header.

## Traps

Reference material, each documented where it belongs.

| trap | where |
|---|---|
| Megafile owners are 1:1 transliterations of upstream files. Their size is a sync contract, not debt, and a gate refuses a split. | [docs/50](docs/50-zig-c-boundaries-and-rewrite-policy.md) |
| Parity oracles include upstream C by relative path, so a layout move breaks lanes without any of them reporting a failure. | [docs/70](docs/70-tests-and-verification.md) |
| Build facts must come from an option that was passed, never from a target's name. Name-derived facts have disagreed with the real ones silently. | [docs/20](docs/20-zig-build-graph.md) |
| A destructive build step inherits upstream's vocabulary along with its behaviour, so a step named for one tree can delete another. Grep destructive commands after any rename. | [docs/20](docs/20-zig-build-graph.md) |
| Firmware budgets are tight on the DM42, and flash and `.bss` both sit close to their limits. Link every package variant, not just the default. | [docs/40](docs/40-firmware-and-distribution.md) |
| Resource budgets belong in harness code, never in `ulimit` or a shell `timeout`. A differential that is killed from outside executes the defect it should have reported. | [docs/70](docs/70-tests-and-verification.md) |
| A test lane that reads an untracked file passes here and fails in CI. Stage inputs before gating. | [docs/70](docs/70-tests-and-verification.md) |
| CI fails fast, so a red governance gate skips the parity job and hides everything behind it. Clear the gates first, then sweep the battery lane by lane. | [docs/60](docs/60-ci-and-release-workflow.md) |
| A red CI lane is frequently not your change. Read the failing log before assuming it is. | [docs/60](docs/60-ci-and-release-workflow.md) |
| Python hooks are scoped to z47-owned paths, because reformatting an imported file turns a clean import into a permanent conflict. | [docs/80](docs/80-maintainer-workflow.md) |
| The highest-yield audit is the cross-owner consistency scan: one symbol carrying different values in two owners. A fix landing in one owner and not its twin is the recurring defect class. | [docs/75](docs/75-debugging.md) |

Comments are authoritative about the code they sit beside. They carry no meta, no
history, and no report or milestone identifiers, and a tracked page never names a
file under the ignored `__DEV/`.

## Fleets

Charter a fleet only for tracks that are genuinely independent and large enough to
outweigh the coordination; one agent working end to end beats three that overlap,
and an agent whose job is to re-check finished work adds nothing a gate has not
already settled. Charter disjoint files rather than disjoint topics, since two
charters phrased by topic can reach the same owner and ship the same change twice.

Never `git stash`. Pre-commit stashes and restores every unstaged change in the
repository, so a commit taken mid-fan-out corrupts the other agents; commit once
per wave, after they report. Agents write only inside their own worktree, and the
integrator re-runs the gate on clean HEAD before anything counts as landed.

## Commits

One logical change per commit, with a Conventional Commits subject of 72
characters or fewer, lower case after the colon and no full stop. `git log` carries
the type and scope vocabulary in use; follow it rather than inventing a scope.

The body is wrapped at 80 and carries the evidence a fresh clone would otherwise
lack: what the gate reported and what it exited with. A resync commit also records
what was deliberately not ported, because that is the half a later reader cannot
reconstruct from the diff.

Commit locally and stop; pushing is the maintainer's call. Never add a
`Co-Authored-By:` for a tool or an assistant, or a generated-by trailer: a footer
naming a non-author is a false claim about who wrote the change, and every blame
view repeats it forever.
