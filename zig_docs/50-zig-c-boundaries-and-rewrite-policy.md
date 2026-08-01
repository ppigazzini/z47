# Zig And C Boundaries And Rewrite Policy

This page records the seam-and-core architecture, the retained C surfaces, the
approved checked-in Zig/C boundaries, and the rules that keep those boundaries
reviewable.

Read [00-project-and-upstream.md](00-project-and-upstream.md) first. This page
assumes the ownership split and the "core fully in Zig, C retained for parity"
framing are already clear.

Audit basis: 2026-08-01, upstream pin `6559a9c59`, Zig `0.16.0` stable. The
Memory-Safety Posture section below was re-audited against the live tree on that
date; the supporting findings are in the maintainer working notes.

## Implementation Modes

z47 uses a small set of explicit modes. The calculator core is fully in the
"manual Zig owner" mode; the other modes cover retained dependencies, the
generated ABI seam, and narrow interop.

| Mode | Meaning | Current examples |
| --- | --- | --- |
| manual Zig owner | the implementation lives in idiomatic hand-written Zig and is parity-gated against the retained upstream C | the whole core under `zig_src/` (`abi`, `constants`, `frontier`, `mathematics`, `shortint`, `solver`, `state`, `ui`) and the Zig host/firmware/testSuite HAL under `zig_build/` |
| generated ABI seam | contract-mandated C-ABI shapes derived from upstream C via `translate-c` and regenerated per pin advance; not hand-edited | `extern struct` layout mirrors, dispatch `callconv(.c)` signatures, and decNumber constant-blob offsets (see Seam-And-Core below) |
| retained external C | a third-party library still compiled or linked as C | `dep/decNumberICU` (compiled by Zig); GTK 3, GMP, FreeType 2, optional PulseAudio (host); DMCP/DMCP5 SDKs (firmware) |
| retained parity C | upstream C kept only to prove the Zig owner matches it | `src/**` under the parity oracles and the shared testSuite; the fake-runtime and oracle doubles under `zig_build/tests/**` |
| narrow interop boundary | an approved checked-in `translate-c` root or direct `extern` binding | the generator `translate-c` roots and the allowlisted `*_runtime.zig` / HAL seams (see below) |

## Retained C Surfaces

The port is behavior-complete for the product; the C that remains is deliberate
and explicit:

- `dep/decNumberICU`: vendored decimal library, compiled by Zig into the product
  simulator, the firmware, and the constant/catalog/testPgms generators.
- GTK 3, GMP, FreeType 2, optional PulseAudio: external host libraries linked from
  Zig. The GTK application layer itself is ported to Zig
  (`zig_build/host/gtk_*.zig`); the upstream `src/c47-gtk` C files it replaces are
  filtered out of the build by `filterGtkSources`.
- SwissMicros DMCP and DMCP5 SDKs: external firmware inputs linked from Zig.
- Parity/oracle/test C: about 60 first-party C files (parity oracles, fake
  runtimes, and the shared testSuite reference) kept only for verification.
  `report-c-dependency-status.py` reports 0 of these in the active product build.

Do not imply the project is pure Zig. It is Zig-first with the retained C above.

## Approved Checked-In Boundary Files

The checked-in allowlist is `../.github/project/zig-c-boundaries.txt`, and it is
the source of truth -- prefer it over any list duplicated in prose, which rots.
It has three sections:

- `[translate-c-roots]`: the generator boundary headers under
  `zig_build/tools/translate_c/` plus the ABI-layout oracle root
  (`abi_layout_oracle.h`), consumed by `Build.addTranslateC` wiring.
- `[cimport]`: currently empty. No checked-in Zig file uses `@cImport`.
- `[extern-symbols]`: files allowed to carry direct `extern` bindings -- the
  firmware runtime seams (`zig_build/firmware_*_runtime.zig`), the Zig GTK host
  layer (`zig_build/host/gtk_*.zig`), the Zig testSuite HAL
  (`zig_build/tests/testsuite_hal.zig`), `zig_src/abi/runtime.zig`, and a few
  generator and parity-runtime files.

No other checked-in Zig file may introduce `@cImport` or a direct `extern fn`,
`extern const`, or `extern var` without updating the allowlist and guard in the
same change.

## Guard And CI Enforcement

`../.github/project/check-zig-c-boundaries.sh` enforces the allowlist:

1. load the allowlisted files from `zig-c-boundaries.txt`
2. verify each allowlisted `translate-c` root still exists and exposes real C
   includes
3. verify each allowlisted Zig file still matches the expected `@cImport` or
   direct-`extern` pattern
4. scan all working-tree `translate_c/*.h` roots and all tracked `*.zig` files
5. fail if a checked-in `translate-c` root, `@cImport`, or direct `extern`
   binding appears outside the approved lists

The guard runs in CI through the `zig-c-boundary-guard` job in
`../.github/workflows/upstream-oracle.yml`, and locally through
`bash .github/project/run-local-gate.sh`.

Maintainer finding: when an owner already has a `*_runtime.zig` seam, keep any new
direct legacy-C `extern` bindings there and call them through seam helpers from
the owner file. Moving those bindings into the owner file is boundary drift and
fails the guard.

## Seam-And-Core Architecture

Every owner surface splits into two layers so the port stays idiomatic while
still tracking upstream by construction.

- Seam layer (generated, faithful): the C-ABI shapes the upstream testSuite and
  parity oracles mandate -- `extern struct` layout mirrors, dispatch-table
  `callconv(.c)` signatures, and decNumber constant-blob offsets. Derived from
  upstream C through `translate-c` roots and regenerated on each pin advance.
  Seam files are not hand-edited.
- Core layer (hand-written, idiomatic): owner logic behind the seam -- slices over
  `[*c]`, error sets over sentinel returns, real modules over monolithic files.

Enforcement split:

- The idiom ratchet (`report-idiom-status.py` / `check-idiom-ratchet.sh`) grades
  the CORE layer only. Generated seam files are classified out of the ceiling
  totals and reported separately.
- A seam file lives under a `generated/` path in `zig_src/` AND carries the
  `// SEAM-GENERATED` marker. The reporter fails closed if a file has one but not
  the other, so a hand-written owner cannot smuggle `extern struct` / `[*c]` debt
  out of the ceiling.
- The reporter matches its patterns against the file with `//` comments removed,
  so prose that merely DISCUSSES a token is not counted as carrying it. Before
  that, a doc comment containing the many-item-C-pointer spelling breached the
  `cptr_files` ceiling and failed the gate on writing.
- **Do not extend that to string literals.** Two of the patterns deliberately
  target a string that appears in code -- `qspi_section_files` matches the
  `".qspi_data"` argument of `linksection`, and `constants_blob_sites` matches an
  extern symbol name -- so stripping strings would zero them. The patterns are
  not all the same kind of thing: some describe code shape and some describe a
  literal, and nothing in the table says which. Check what a pattern is looking
  at before normalising anything else away.

The ratchet now sits at its C-ABI ceiling: the remaining `callconv(.c)`,
`extern`, `extern struct`, and offset metrics are mandated by the upstream
testSuite dispatch contract and the firmware object layout, not reducible debt.
Ongoing owner work is idiomatic refinement within that ceiling. See the
churn-driven notes in [80-maintainer-workflow.md](80-maintainer-workflow.md).

## Memory-Safety Posture

Safety here is a property you **place**, and every placement needs a reason and a
gate. This project cannot adopt a blanket posture in either direction: it must
stay byte-compatible with an upstream C tree that is resynced continuously, and
it ships to a device that compiles every runtime check away. So the useful
question is never "is z47 memory safe" but "which surface, defended by what,
proved by which lane".

### What Is Settled

The low idiomatic-Zig metrics (many `[*c]` pointers, `callconv(.c)`, `extern`
sites) are a property of the transliteration contract, not latent memory-safety
debt. A blanket `[*c]`-to-slice sweep of the transliterated spine is explicitly
NOT on the roadmap: it would break the line-for-line upstream re-sync map without
closing a real hazard.

- The concern is CORRECTNESS, not security. z47 is offline and single-user, with
  no network, crypto, auth, or secrets surface, so it is out of scope for the
  CISA/NSA memory-safe-roadmap framing. The failure that matters is a corrupted
  read making the calculator show a wrong number, which needs no attacker.
- The real hazard surface is UNTRUSTED FILE IMPORT -- the state-load, program-load
  and text-import paths that parse a `.sav` / `.d47` / `.p47` / imported text file
  whose bytes the code did not produce. Upstream's own bug history concentrates
  memory fixes there (state-file overflow, restore/decode out-of-bounds). The
  arithmetic and display core takes no untrusted input.
- Firmware ships `.ReleaseSmall`, which compiles out all runtime safety checks by
  default. That is a statement about the DEFAULT, not a ceiling:
  `@setRuntimeSafety(true)` is a lexical per-function opt-in that works inside
  `ReleaseSmall`, so the device can be made to trap on exactly the untrusted-file
  path without building the whole binary `ReleaseSafe`. That was done: covering the
  22-function parse surface cost **64 bytes** of DMCP flash in total, and the
  synthetic estimate it replaced (~12 bytes per function, from a benchmark of
  array-indexing functions) was an order of magnitude too high -- because the real
  path indexes through many-item C pointers, which carry no length and so admit no
  bounds check at all. What it does buy is the integer class; see gap 1.
  The one-time cost that WOULD have dominated is the default panic handler's
  message formatting, ~710 bytes plus `__aeabi_memcpy`/`__aeabi_memset` as new link
  dependencies. `abi.trap_panic.namespace`, installed at the two load-path object
  roots, removes it: freestanding traps directly, hosted targets keep Zig's default
  handler and its stack trace. Whole-binary `ReleaseSafe` remains rejected on flash
  and speed; scoped safety on the load path is a different, much cheaper decision
  and was never blocked by it.

### The Rules, And What Holds Each One

| Rule | How this tree holds it | Gate |
| --- | --- | --- |
| **Confine `[*c]` to the C-ABI declaration surface on the load owners, and never let a helper take a pointer where the caller had a length.** A many-item pointer carries no length, so neither producer nor consumer can check one -- and a caller that writes `.ptr` is throwing away a bound it already held. | The four state-file owners (`calc_state_restore` / `_register_codec` / `_save` / `_backup`) carry 162 `[*c]` tokens; 96 are `extern` declarations of the C globals and libc functions they reach, 66 are body uses. `calc_state_load.zig`, `calc_state_policy.zig`, `calc_state_runtime.zig`, `calc_state_header.zig` and the `program_serialization` logic parts are `[*c]`-free; the header-line helpers take `[]const u8` and their walks are bounded by `std.mem.sliceTo` rather than by a NUL another function promises. | `check-idiom-ratchet.sh` (`cptr_files` ceiling), `zig build test:unit` |
| **Bound every count the file names, at the write and not at the loop.** A parser must keep reading one line per claimed entry to stay aligned with the stream; what must be checked is the index before it reaches the array. | `31fb6f755` -- `kbd_usr[37]`, `userMenuItems[18]`, `userAlphaItems[18]`, `userMenus[].menuItem[18]` and the 28 statistical sums; plus an empty `readLine()` treated as end of file, so a lying count cannot make one section parse the next section's header as its data. | `zig build test` (12835 cases) -- **and nothing adversarial; see the gap below** |
| **Bound what a file's dimensions IMPLY, in a width that cannot wrap.** A count the file states is not the hazard; the size it multiplies out to is. Do the capacity arithmetic wider than the field it will be stored in, or the product wraps before the test and the comparison is against a number the file never claimed. | `vector_shape.clampToRegisterCapacity` computes `rows * cols * element_blocks + header` in u64 and refuses anything past a u16 block count, which is what `reallocateRegister` takes. All three sites that turn file dimensions into a register go through it -- the `Rema` and `Cxma` branches of `restoreRegister` and `skipMatrixData` -- so the restore and skip sides cannot disagree on the element count. | `zig build test:unit` (the boundary is swept exhaustively for both element widths), `saveload_parity` |
| **A refused allocation is not a NULL to write through.** | `initUserKeyArgument`, `setUserKeyArgument`, `createMenu` and the EQUATIONS section check the result; `freeListAlloc` checks the region table's bound BEFORE the store, since past it the store is itself the overrun. | `zig build test`, `memory_parity` |
| **Port C's implicit narrowing as `@truncate` and its unsigned arithmetic as `+%`/`-%`.** This is a PARITY rule before it is a safety rule: where upstream assigns a wider value into a `uint16_t`, C truncates and that is defined; `@intCast` is illegal behaviour on the same input -- a trap in a safe build, silent UB in `ReleaseSmall`. Use `@intCast` only where the value provably fits, and saturating `+|`/`*|` where the intent is that an absurd size stays absurd. | The M1 fuzz found exactly this class: `parseU32LineZ` u32 overflow on an oversized size string and `loadProgram` `@intCast` overflow on `program_size > 0xFFFF`, both fixed parity-safe (saturating parse, explicit reject) so valid files are unchanged. | `zig build pgm_load_fuzz`; **the 5628 `@intCast` sites are otherwise unsorted -- see gap 4** |
| **Raise `@setRuntimeSafety(true)` over an untrusted parse, and price it before placing it.** The scope is lexical -- it does not follow calls, so it goes on each function -- and it works in `ReleaseSmall`, so it reaches the device. Keep it off the per-keystroke path, and off any loop where the cost is measured and the bound is already stated by the code itself. | 22 functions across the state-file and `.p47` parse surfaces (`calc_state_restore`, `calc_state_register_codec`, `calc_state_io_flow`, `program_serialization_header` / `_load_apply`). The two load-path object ROOTS install `abi.trap_panic.namespace`, so a firmware safety failure is a bare `udf` instead of dragging in Zig's message formatter; hosted targets keep the default handler and its stack trace. Measured: +64 bytes of flash, 4 trap sites emitted. | `zig build dmcp` size, `zig build test -Doptimize=ReleaseSmall`, `test:unit` |
| **Drive malformed input through the REAL path, not a unit stub.** | `zig_build/tests/pgm_run/malformed/` -- 27 `.p47` files (truncated at 12 offsets, corrupt magic, garbage/negative/overflowing size fields, all-zero and all-`0xFF` bodies) through the actual program-load code under ASan. | `zig build pgm_load_fuzz` |
| **Sanitize the retained C on a lane that actually runs.** | `zig build test_asan` runs the full shared testSuite with `sanitize_c` on; `both_asan` only BUILDS the two simulators, so it proves compilation, not execution. | `test_asan` |
| **Keep `catch unreachable` to provable cases.** | All 6 sites are `bufPrint` into a fixed local buffer whose size dominates the formatted output. The other 19 are 11 `orelse unreachable` on `getRegisterDataPointer` for a register the caller has already established, and 8 exhaustive-switch `else` arms. | review |

### The Open Gaps

These are lanes, language affordances and unanswered contracts -- not open
defects. Each entry states what would close it, and the sequenced plan behind them
(M-SAFE-1 through M-SAFE-10, ordered language-first and detectors-last) is in the
maintainer working notes.

Four of those milestones have landed, and the rules table above is where their
results live: the matrix-dimension capacity guard, runtime safety on the load
path, the narrowing split and its ratchet, and the line-boundary slices. Gaps 6
and 7 were found BY that work rather than planned -- every milestone so far has
surfaced something the one before it could not see -- so treat this list as live
rather than closed.

1. **Safety on the load path catches the integer class only, and cannot catch
   more until the regions become slices.** The 22 covered functions emitted just
   **4 trap sites**, because almost every access on that path is through a
   many-item C pointer, which carries no length -- there is no bound for a check
   to test. What the device now traps on is overflowing arithmetic and
   out-of-range `@intCast`, which is not a small thing: it is the class of the
   three bugs the M1 fuzz found and of the matrix-capacity defect M-SAFE-1 fixed.
   The spatial class stays invisible, and the way to reach it is the slice
   conversion described in gap 4, after which the attribute already in place starts
   checking bounds with no further work. Two readers on the untrusted surface stay
   uncovered by the attribute for a reason that is not scheduling --
   `addTestPrograms` and `import_string_from_filename` live in the frontier
   object, where gap 3 says the attribute cannot go at all. Both now carry
   explicit bounds instead, which is the answer wherever that budget applies.
2. **The state-file restore path has no adversarial lane.** `31fb6f755` added
   137 lines to `calc_state_restore.zig` alone (137 in, 33 out), and the only
   thing that exercises them is a corpus of VALID files: `saveload_parity` and
   `saveload_golden` round-trip, and the 72 new testSuite cases came with the
   import. A malformed `.sav` / `.d47` corpus driven through `doLoad` -- the M1
   pattern, which found three real bugs the first afternoon it existed -- is the
   highest-value unbuilt lane in the tree. It is also the surface upstream's own
   worst memory bug (the 577 state-file overflow) lived on.
3. **The OLD_HW package-3 `.bss` budget is FOUR BYTES, so runtime safety cannot
   be placed in the frontier object.** Baseline `_ebss` is exactly the
   `0x10002000` the linker script asserts against. Adding `@setRuntimeSafety(true)`
   to one function in `../zig_src/shell/config.zig` moved it to `0x10002004` and
   failed the pkg3 link; the pkg3 frontier object's `.bss` is byte-identical
   either way, so the growth is a `--gc-sections` effect -- the attribute keeps
   something alive that was otherwise collected. Installing
   `abi.trap_panic.namespace` on `frontier.zig` does NOT recover it. So the
   per-function flash price quoted for the load-path objects does not transfer
   here: in the frontier object on OLD_HW the currency is RAM and there is none.
   Write explicit bounds instead of relying on the backstop, and note at the site
   why the attribute is absent. Note also that `dmcp_pkgs_all` is the only lane
   that catches this -- the gate, `dmcp` and `dmcp5` were all green.
4. **ASan cannot see the C47 block allocator.** Registers, variables, programs,
   formulae, menus and the GMP heap all live in `ram`, a single ~256 KiB
   allocation carved by `../zig_src/shell/free_list.zig`. One block overrunning
   its neighbour is, to ASan, a write inside a live allocation; Zig's checks
   never see it either, because blocks are reached by `[*c]` arithmetic. The
   remedy is ASan's manual-poisoning API for custom allocators -- poison the pool
   at startup, unpoison exactly the handed-out extent in `freeListAlloc`,
   re-poison in `freeListFree` -- compiled only where `sanitize_c` is on, so the
   firmware and the parity binaries are unchanged. Reasoning is in
   [75-debugging.md](75-debugging.md).
5. **The narrowing population is split and ratcheted on the load owners, but the
   rest of the tree is still one undifferentiated number.** Each site is either
   (a) provably in range, where `@intCast` is correct and says something true;
   (b) standing where upstream narrows implicitly, where `@intCast` is a PARITY
   DEFECT because C truncates and Zig traps; or (c) standing where upstream's
   unsigned arithmetic wraps, where the spelling must be `+%` / `-%` / `*%` or a
   saturating `+|` / `*|`. On `persist/` and `program/` this is now measured:
   `report-narrowing-status.py` ranks the sites inside safety-raised functions
   and `check-idiom-ratchet.sh` holds the count, with a FLOOR on the number of
   safety-raised functions so the ceiling cannot be met by deleting a check. The
   remaining ~5600 sites outside those owners are unclassified, and
   `report-idiom-status.py`'s single total cannot tell a correct cast from a
   defect. Extending the analysis there needs the same per-site upstream reading;
   do not sweep it.
6. **A fix lands in one owner and its sibling twin is missed.** z47 keeps a
   state-file family and a program-file family that parse different formats with
   structurally identical helpers, and a fix applied to one has twice not been
   applied to the other: upstream's matrix-dimension clamp (absent from the Zig
   for four resyncs) and the M1 fuzz's saturating `parseU32LineZ`, which was
   fixed in `program_serialization_runtime.zig` while the byte-identical twin in
   `calc_state_runtime.zig` kept wrapping for three weeks. Nothing can see this
   today: the parity oracles compare each owner against upstream C, so two owners
   that differ from each other look fine, and the ratchets count shapes rather
   than semantics. `report-twin-divergence.py` now ranks the drifted pairs: it
   pairs same-named functions across the two families, canonicalises each
   family's own name (without that the seam pairs score ~0.86 and crowd out the
   real defect -- measured, the parseU32LineZ bug ranked seventh of eight), and
   sorts by similarity descending, since a one-operator drift is the suspicious
   case and a wholesale rewrite is just two functions sharing a name. Report
   only, not a gate, until the false-positive rate is known.

   **Detecting drift is second-best. The better move is to leave nothing to
   drift:** the line-parse helpers now exist ONCE, in `../zig_src/abi/line_parse.zig`,
   and both families call it. A shared module cannot diverge from itself. Prefer
   that wherever the two families genuinely do the same thing; keep the scan for
   where they legitimately differ.

   **The scan's blind spot is inside a single file**, and gap 8 is an instance:
   "twin" is a relationship, not only a directory layout.
7. **`strtol` / `strtoul` results are platform-width, so upstream's own behaviour
   differs between host and firmware.** `sizeof(unsigned long)` is 8 on the LP64
   host and 4 on the arm-none-eabi firmware (measured), so `strtoul` saturates at
   2^64 on one and 2^32 on the other. `toUint32("4304967321")` is 10000025 on the
   host and 4294967295 on the device, from upstream's own code. z47 inherits this
   at seven load-path sites (`calc_state_text.zig`'s `toInt16`/`toUint8`/
   `toUint16`/`toUint32`, `calc_state.zig`'s `stringToInt8`/`stringToUint16`, and
   `calc_state_backup.zig`); `strtoll`/`strtoull` are clean, since `long long` is
   64-bit on both. "Be faithful to upstream" does not decide these, and the parity
   oracles only ever run the host side, so the device's answer is unverified. No
   valid state file reaches the divergence -- this is a contract to write down per
   site, not a defect to sweep. Same class as the `c_long` LLP64 trap already on
   record, on the untrusted-input path.
8. **One upstream macro family is ported two different ways inside one file.**
   Upstream generates `stringToUint8` / `stringToUint16` / `stringToUint32` from a
   single `stringToUintFunc` macro -- `(type)strtoul(str, NULL, 0)`. In
   `../zig_src/core/persist/calc_state.zig`, `stringToUint16` and its
   `stringToInt8` relative are ported faithfully as
   `@truncate(strtoul(str, null, 0))`, while `stringToUint8` and `stringToUint32`
   are `std.fmt.parseInt(.., 10) catch 0`. That differs twice over: base 0
   auto-detects `0x` hex and leading-zero octal where base 10 reads neither, and C
   truncates on overflow where the `catch` returns 0. Measured -- for the u8,
   `0x1F` is 31 in C and 0 here, `010` is 8 and 10, `300` is 44 and 0. Both
   writers emit plain decimal (`%PRIu8` / `{d}`), so no file z47 or upstream
   produces reaches it; a hand-edited one does. Neither the parity oracles (valid
   decimal only) nor the twin scan in gap 6 -- which pairs ACROSS families, and all
   four of these are one file -- can see it. Fix is to match the two correct
   siblings. The general lesson: a `#define`-generated family upstream is a set
   that must be ported identically, and nothing checks that.

### Rules For New Code

- Prefer `[]T` / `[N]T` over `[*c]` at z47-owned leaves and on the load owners
  where a length is known, but never on the transliterated spine, where matching
  upstream shape keeps re-sync cheap. On a file-backed region this is not cosmetic:
  a many-item pointer carries no length, so converting it to a slice is what makes
  a bound EXPRESSIBLE at all -- neither the producer nor any consumer can check one
  otherwise.
- Narrow with `@truncate` where upstream narrows implicitly, wrap with `+%`/`-%`
  where upstream's unsigned arithmetic wraps, and saturate with `+|`/`*|` where the
  intent is that an absurd size stays absurd. Reserve `@intCast` for values that
  provably fit. Getting this wrong is a parity bug before it is a safety bug.
- Raise `@setRuntimeSafety(true)` on a function that walks bytes z47 did not write.
  It works in `ReleaseSmall`, so it reaches the device; it is lexical, so it does
  not follow calls and must go on each function; and it is a backstop under the
  explicit rejections, never a substitute for writing them.
- On any path that reads bytes the code did not produce, bound the write before
  it happens, not after. A length check that runs after the copy is not a check.
- When a ported reader has separate host and firmware bodies, bound both or
  neither, and say in the commit which upstream behaviour the bound preserves.
- A guard added to an unguarded upstream read must be behaviour-identical on
  valid input. That is what makes it portable back upstream and what keeps the
  parity oracles green -- see `31fb6f755` and the M1 fixes for the pattern.

## `translate-c` Policy

Treat `translate-c` roots and any `@cImport` use as narrow boundary tools, not a
whole-project porting strategy. Repo policy requires:

- generator and ABI-seam C translation to stay build-managed through explicit root
  headers under `../zig_build/tools/translate_c/` and `Build.addTranslateC` wiring
- exact justification for every checked-in boundary file
- build-managed integration through `addCSourceFiles`, `linkSystemLibrary`, or
  other explicit build-graph ownership where practical
- a parity or focused-validation lane behind every owner

## Rules For New Boundaries

- Add a new checked-in `translate-c` root, `@cImport`, or direct `extern` only
  when a build-managed or hand-written alternative is not practical.
- Update `../.github/project/zig-c-boundaries.txt`, the guard expectations, and
  this page in the same change.
- When an owner already has an approved `*_runtime.zig` seam, add new direct
  bindings there, not in the owner file.
- Keep the boundary file narrow and name the C surface it exposes.
- Add or update the focused validation lane in
  [70-tests-and-verification.md](70-tests-and-verification.md) when a new boundary
  affects behavior.

## Naming Rules

Naming policy is layer-specific, not one global rule.

- semantic owner file: the domain name, for example
  `../zig_src/core/persist/calc_state.zig`
- direct legacy-boundary bindings: `*_runtime.zig`, for example
  `../zig_src/core/persist/calc_state_io.zig`
- thin ABI-facing forwarders: `*_export.zig`; the implementation behind a paired
  export shim: `*_owned.zig`
- legacy C helper files: `*_legacy.c` or `*_runtime_helpers.c`
- inside owner files and coherent internal-only helper clusters, use Zig casing
  only when the full internal-only family can move together in one bounded slice:
  directories and files `snake_case`, types `TitleCase`, functions `camelCase`,
  other values `snake_case`
- in `*_runtime.zig`, `*_export.zig`, legacy C, `pub export`, and `extern`
  surfaces, keep upstream-compatible spellings where they model ABI, layout, or
  exact public symbol names
- the structural naming milestone is complete under this layer-scoped contract;
  any future naming reopener must start from a fresh owner-specific inventory
- do not run repo-wide variable, parameter, or local-const case sweeps; defer a
  casing cleanup that cannot move a whole internal-only family coherently

Do not reintroduce mixed owner-plus-export spellings such as `*_owned_export.zig`.

## Review Rules

- Prefer shrinking or clarifying boundaries over moving them around.
- Do not scatter direct C bindings across host, firmware, or owner code.
- Keep docs honest about what is Zig and what is retained C.
