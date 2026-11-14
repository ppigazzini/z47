# Zig And C Boundaries And Rewrite Policy

This page records the seam-and-core architecture, the retained C surfaces, the
approved checked-in Zig/C boundaries, and the rules that keep those boundaries
reviewable.

Read [00-project-and-upstream.md](00-project-and-upstream.md) first. This page
assumes the ownership split and the "core fully in Zig, C retained for parity"
framing are already clear.

Last verified: 2026-10-23, Zig `0.17.0` stable. The upstream pin is
`UPSTREAM_COMMIT` in `../.github/project/upstream-pin.env`; no page repeats it.
The flash and trap-site figures in the Memory-Safety Posture section were
measured on 2026-08-16 and not re-taken; the supporting findings are in the
maintainer working notes.

## Implementation Modes

z47 uses a small set of explicit modes. The calculator core is fully in the
"manual Zig owner" mode; the other modes cover retained dependencies, the
generated seam, and narrow interop.

| Mode | Meaning | Current examples |
| --- | --- | --- |
| manual Zig owner | the implementation lives in hand-written Zig and is parity-gated against the retained upstream C | the whole tree under `src/` (`abi/`, `core/`, `shell/`, and the `frontier.zig` object root) and the Zig host/firmware/testSuite HAL under `build/` |
| generated seam | pure-data tables regenerated from upstream C by a checked generator; not hand-edited | the printer-font glyph tables under `src/shell/generated/`, produced by `../.github/project/generate-font-seams.py` (see Seam-And-Core below) |
| retained external C | a third-party library still compiled or linked as C | `upstream/dep/decNumberICU` (compiled by Zig for the host, by `arm-none-eabi-gcc` in the firmware link); GTK 3, GMP, FreeType 2, optional PulseAudio (host); the DMCP/DMCP5 SDKs and a cross-built GMP 6.2.1 (firmware) |
| retained parity C | upstream C kept only to prove the Zig owner matches it | `upstream/src/**` compiled by the parity oracles and the shared testSuite; the fake-runtime and oracle doubles under `build/tests/**`, which is where every first-party `.c` file lives |
| narrow interop boundary | an approved checked-in `translate-c` root or direct C binding | the `translate-c` roots and the files listed under `[extern-symbols]` (see below) |

## Retained C Surfaces

The C that remains is deliberate and explicit:

- `upstream/dep/decNumberICU`: vendored decimal library, compiled by Zig into the
  simulator and the constant/catalog/testPgms generators, and by
  `arm-none-eabi-gcc` into the firmware.
- Generator-emitted C (`rasterFontsData.c`, `constantPointers.c`,
  `constantPointers2.c`), compiled by Zig into the simulator and by
  `arm-none-eabi-gcc` into the firmware, and `upstream/dep/forcecrc32.c`,
  compiled by Zig as the firmware's host CRC tool.
  [30-host-and-generated-surfaces.md](30-host-and-generated-surfaces.md) and
  [40-firmware-and-distribution.md](40-firmware-and-distribution.md) own them.
- GTK 3, GMP, FreeType 2, optional PulseAudio: external host libraries linked from
  Zig. The GTK application layer itself is ported to Zig
  (`build/host/gtk_*.zig`); the upstream `src/c47-gtk` C files it replaces are
  filtered out of the build by `filterGtkSources`.
- SwissMicros DMCP and DMCP5 SDKs and a cross-built GMP: external firmware
  inputs, compiled and linked by `arm-none-eabi-gcc` as driven from
  `../build/firmware.zig`.
- Parity/oracle/test C: the first-party `.c` files under `build/tests/**` (parity
  oracles, fake runtimes, and harnesses) kept only for verification.
  `report-c-dependency-status.py` owns the count and reports 0 of them in the
  active product build. None of it is under `src/`, which carries no `.c` or `.h`
  at all. The only other first-party headers are the `translate-c` roots in
  `../build/tools/translate_c/`.

Do not imply the project is pure Zig. It is Zig-first with the retained C above.

## Approved Checked-In Boundary Files

The checked-in allowlist is `../.github/project/zig-c-boundaries.txt`, and it is
the source of truth -- prefer it over any list duplicated in prose, which rots.
It has two sections:

- `[translate-c-roots]`: the generator boundary headers under
  `build/tools/translate_c/` plus the ABI-layout oracle root
  (`abi_layout_oracle.h`), translated by the official `translate-c` package
  through `addTranslator` in `../build/common.zig`.
- `[extern-symbols]`: every file allowed to carry a direct C binding. Most are
  `src/` owners that bind a C-ABI symbol defined in another build object -- an
  upstream global or function a Zig owner there exports, decNumber, GMP or
  libc; the rest are the firmware runtime seams
  (`build/firmware_audio_runtime.zig`, `build/firmware_io_runtime.zig`,
  `build/firmware_print_ir_runtime.zig`), the Zig GTK host layer
  (`build/host/gtk_*.zig`), the Zig testSuite HAL and a few generator and
  parity-runtime files. The guard prints the count.

A direct C binding is an `extern fn`, `extern const` or `extern var` declaration,
with or without a library name (`extern "kernel32" fn`), or the `@extern`
builtin, which binds a symbol by name without declaring it. No other checked-in
Zig file may introduce one without updating the allowlist in the same change.
There is no `@cImport` section: Zig 0.17 removed the builtin, so the compiler
rejects it before any guard runs.

## Guard And CI Enforcement

`../.github/project/check-zig-c-boundaries.sh` enforces the allowlist:

1. load the allowlisted files from `zig-c-boundaries.txt`
2. verify each allowlisted `translate-c` root still exists and exposes real C
   includes
3. verify each allowlisted Zig file still carries a direct C binding
4. scan every tracked or untracked-unignored `*.zig` file and
   `build/tools/translate_c/*.h` root
5. fail if a `translate-c` root or a direct C binding appears outside the
   approved lists

The guard runs in CI through the `zig-c-boundary-guard` job in
`../.github/workflows/upstream-oracle.yml`, and locally through the gate
(`PATH="$PWD/.venv/bin:$PATH" bash .github/project/run-local-gate.sh`).

Maintainer finding: when an owner already has a `*_runtime.zig` seam, keep any new
direct legacy-C `extern` bindings there and call them through seam helpers from
the owner file. Moving those bindings into the owner file is boundary drift. The
guard works per file, so it catches that only when the owner is not already
listed under `[extern-symbols]`; for a listed owner it is a review rule.

## Seam-And-Core Architecture

Every owner surface splits into two layers so the port stays idiomatic while
still tracking upstream by construction.

- Seam layer (generated): files under a `generated/` path in `src/` that carry
  `// SEAM-GENERATED`, regenerated from upstream C by
  `../.github/project/generate-font-seams.py` (CI runs it with `--check`) and
  never hand-edited. `git grep -l SEAM-GENERATED -- src` lists them; today they
  are pure data tables.
- Core layer (hand-written): everything else, including the C-ABI shapes the
  upstream testSuite and the parity oracles mandate. The `extern struct` mirrors
  in `../src/abi/types.zig` are checked by `zig build abi-layout-parity`, and the
  constant-blob offsets in `../src/abi/constants.zig` by
  `check-constant-offsets.py`. Hot owners stay 1:1 transliterations of their
  upstream file: a resync applies upstream's C diff to them textually, so their
  size is a sync contract rather than debt, and `check-transliteration-contract.py`
  (gate step 6e) refuses a split. Cold owners may be idiomatised freely, their
  parity oracle proving the re-sync.

Enforcement split:

- The idiom ratchet (`report-idiom-status.py` / `check-idiom-ratchet.sh`) grades
  the CORE layer only. Generated seam files are classified out of the ceiling
  totals and reported separately.
- The same ratchet holds at zero the spellings the pinned Zig retires, so a
  ported line cannot bring one back: `int_from_float_sites` counts
  `@intFromFloat`, which the 0.17 language reference deprecates as equivalent to
  `@trunc`; `slice_by_end_sites` counts a slice written `s[a .. a + n]`, which
  the reference's *Slicing by Length* writes `s[a..][0..n]`; and
  `zeroes_scalar_array_sites` counts an array of numbers zero-filled through
  `std.mem.zeroes`, which is `@splat(0)`.
- It also holds `dmcp_board_address_sites` at zero: an address one of the DMCP
  SDK headers defines, either board's ROM function table or system data block.
  The build reads them from `lft_ifc.h` and `dmcp.h` (`build_common.libraryFnBase`
  and `systemDataBlockBase`) and hands each owner the value for its board.
- `has_decl_sites` holds `@hasDecl` and `@hasField` at zero: every options
  module emits all of its options, so a probe could only turn a missing one into
  a silent default.
- A metric with no recorded ceiling fails the check, so a new pattern cannot ship
  unenforced.
- A seam file lives under a `generated/` path in `src/` AND carries the
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

The C-ABI metrics -- `callconv(.c)`, `extern`, `extern struct` and the offsets --
are set by the upstream testSuite dispatch contract and the firmware object
layout, not by reducible debt. A resync that brings new upstream surface raises
their ceilings, with the reason in its commit, and collapsing duplicated ports
lowers them; `bash .github/project/check-idiom-ratchet.sh` prints each live value
against its ceiling. Ongoing owner work is idiomatic refinement within those
ceilings; how a resync re-derives an owner is in
`../.github/project/upstream-resync-runbook.md`.

## Memory-Safety Posture

Safety here is a property you **place**, and every placement needs a reason and a
gate. This project cannot adopt a blanket posture in either direction: it must
keep function parity with an upstream C tree that is resynced continuously, and
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
- Firmware ships in optimize mode `small` whatever `-Doptimize` says
  (`defaultFirmwareLeafOptimize` in `../build/firmware.zig`), and `small` compiles
  out all runtime safety checks by default. That is a statement about the DEFAULT,
  not a ceiling: `@setRuntimeSafety(true)` is a lexical opt-in for the scope it
  opens (z47 makes it the first statement of each function) that works in
  `small`, so the device can be made to trap on exactly the untrusted-file path
  without building the whole binary `safe`. That was done: covering the parse
  surface cost **64 bytes** of DMCP flash in total when measured, and the
  synthetic estimate it replaced (~12 bytes per function, from a benchmark of
  array-indexing functions) was an order of magnitude too high -- because the real
  path indexes through many-item C pointers, which carry no length and so admit no
  bounds check at all. What it does buy is the integer class; see gap 1.
  The one-time cost that WOULD have dominated is the default panic handler's
  message formatting, ~710 bytes plus `__aeabi_memcpy`/`__aeabi_memset` as new link
  dependencies. `abi.trap_panic.namespace`, installed at the two load-path object
  roots, removes it: freestanding traps directly, hosted targets keep Zig's default
  handler and its stack trace. Whole-binary `safe` remains rejected on flash and
  speed; scoped safety on the load path is a different, much cheaper decision
  and was never blocked by it.

### The Rules, And What Holds Each One

| Rule | How this tree holds it | Gate |
| --- | --- | --- |
| **Confine `[*c]` to the C-ABI declaration surface on the load owners, and never let a helper take a pointer where the caller had a length.** A many-item pointer carries no length, so neither producer nor consumer can check one -- and a caller that writes `.ptr` is throwing away a bound it already held. | The four state-file owners (`calc_state_restore` / `_register_codec` / `_save` / `_backup`) carry `[*c]` tokens (`grep -o '\[\*c\]' src/core/persist/calc_state_{restore,register_codec,save,backup}.zig \| wc -l` counts them), most of them on the `extern` declarations for the C globals and libc functions they reach. `calc_state_load.zig`, `calc_state_policy.zig`, `calc_state_runtime.zig`, `calc_state_header.zig` and `program_serialization.zig`, `_header`, `_load_apply`, `_save`, `_screen` and `_export` are `[*c]`-free; the header-line helpers take `[]const u8` and their walks are bounded by `std.mem.sliceTo` rather than by a NUL another function promises. | `check-idiom-ratchet.sh` (`cptr_files` ceiling), `zig build test:unit` |
| **Do not cast a pointer.** A cast asserts an alignment and a size the compiler then trusts, and on a 64-bit host a pool block promises only 4 bytes of alignment, so a cast that is harmless on the device traps or lies on the host. | Every C pointer is bound at the type the owner stores in it, and every byte buffer is read through `std.mem`. [Pointer Casts](#pointer-casts) lists the replacement for each need and the two exceptions, the graph engine's `PlotReal` and the UN display's in-place rescale. | `check-idiom-ratchet.sh` (`ptrcast_sites`, `constcast_sites` and `ptr_from_int_sites` ceilings), the cross-target object check in [75-debugging.md](75-debugging.md) |
| **Bound every count the file names, at the write and not at the loop.** A parser must keep reading one line per claimed entry to stay aligned with the stream; what must be checked is the index before it reaches the array. | `31fb6f755` -- `kbd_usr[37]`, `userMenuItems[18]`, `userAlphaItems[18]`, `userMenus[].menuItem[18]` and the 28 statistical sums; plus an empty `readLine()` treated as end of file, so a lying count cannot make one section parse the next section's header as its data. | `zig build state_load_fuzz` (the count mutations and overfill cases), `zig build test` -- the run prints its own case count; **and see the corpus note in [70](70-tests-and-verification.md)** |
| **Bound what a file's dimensions IMPLY, in a width that cannot wrap.** A count the file states is not the hazard; the size it multiplies out to is. Do the capacity arithmetic wider than the field it will be stored in, or the product wraps before the test and the comparison is against a number the file never claimed. | `vector_shape.clampToRegisterCapacity` computes `rows * cols * element_blocks + header` in u64 and refuses anything past a u16 block count, which is what `reallocateRegister` takes. All three sites that turn file dimensions into a register go through it -- the `Rema` and `Cxma` branches of `restoreRegister` and `skipMatrixData` -- so the restore and skip sides cannot disagree on the element count. | `zig build test:unit` (the boundary is swept exhaustively for both element widths), `saveload_roundtrip` |
| **A refused allocation is not a NULL to write through.** | `initUserKeyArgument`, `setUserKeyArgument`, `createMenu` and the EQUATIONS section check the result; `freeListAlloc` checks the region table's bound BEFORE the store, since past it the store is itself the overrun. | `zig build test`, `memory_parity` |
| **Port C's implicit narrowing as `@truncate` and its unsigned arithmetic as `+%`/`-%`.** This is a PARITY rule before it is a safety rule: where upstream assigns a wider value into a `uint16_t`, C truncates and that is defined; `@intCast` is illegal behaviour on the same input -- a trap in a safety-checked build, unchecked in `small`. Use `@intCast` only where the value provably fits, and saturating `+\|`/`*\|` where the intent is that an absurd size stays absurd. | The program-load fuzz found exactly this class: u32 overflow in the line parser on an oversized size string (the parser is `abi.line_parse.parseU32` today) and `loadProgram` `@intCast` overflow on `program_size > 0xFFFF`, both fixed parity-safe (saturating parse, explicit reject) so valid files are unchanged. | `zig build pgm_load_fuzz`; **every other `@intCast` site in the tree is unsorted -- see gap 4** |
| **Raise `@setRuntimeSafety(true)` over an untrusted parse, and price it before placing it.** The scope is lexical -- it does not follow calls, so it goes on each function -- and it works in `small`, so it reaches the device. Keep it off the per-keystroke path, and off any loop where the cost is measured and the bound is already stated by the code itself. | The state-file and `.p47` parse surfaces (`calc_state_restore`, `calc_state_register_codec`, `calc_state_io_flow`, `program_serialization_header` / `_load_apply`). `check-idiom-ratchet.sh` reports the live function count as `untrusted_fns` and holds it at a FLOOR, so it can only go up. The two load-path object ROOTS install `abi.trap_panic.namespace`, so a firmware safety failure is a bare `udf` instead of dragging in Zig's message formatter; hosted targets keep the default handler and its stack trace. Measured on 2026-08-16, when the floor was lower: +64 bytes of flash, 4 trap sites emitted. | `zig build dmcp` size, `zig build test -Doptimize=small`, `test:unit` |
| **Drive malformed input through the REAL path, not a unit stub -- and assert the OUTCOME, not just survival.** | STATE files: the corpus `build/tests/calc_state/malformed/generate_corpus.py` emits -- reproducers of fixed bugs plus exploratory mutation families, see [70-tests-and-verification.md](70-tests-and-verification.md) -- through the real `doLoad` (`zig build state_load_fuzz`), checked for crash, hang and Zig safety panic AND, for every file with a pinned expectation, against that `loadedVersion`. The second assertion is why the lane catches the version forgery, which never crashes. PROGRAMS: the `.p47` files under `build/tests/pgm_run/malformed/` (`ls build/tests/pgm_run/malformed/*.p47 \| wc -l`: truncations, corrupt magic, garbage/negative/overflowing size fields, all-zero and all-`0xFF` bodies) through the actual program-load code, UBSan-instrumented. A finding is a crash, a hang, a Zig safety panic or a sanitizer report. The `*_asan` lane names mean UBSan -- see [75-debugging.md](75-debugging.md). | `zig build state_load_fuzz`, `zig build pgm_load_fuzz` |
| **Sanitize the retained C on a lane that actually runs.** | `zig build test_asan` runs the full shared testSuite under **UBSan**, which found that `common_c_flags`' `-fno-sanitize=undefined` had been cancelling `sanitize_c` and the lanes had never instrumented anything. Two checks are excluded, each individually justified in `../build/common.zig`, and a `comptime` block now fails the build if the blanket cancelling flag returns. There is still NO AddressSanitizer: Zig ships no runtime and cannot link one, so heap overflow and use-after-free remain undetected. See [75-debugging.md](75-debugging.md). | `test_asan`, `pgm_load_fuzz` |
| **Keep `catch unreachable` to provable cases.** | Every `catch unreachable` formats into a buffer whose size dominates the output (`git grep -c 'catch unreachable' -- src` counts them). The `orelse unreachable` sites dereference a register or a block the caller has already established, and the remaining `unreachable`s are exhaustive-switch `else` arms. | review |

### The Open Gaps

These are lanes, language affordances and unanswered contracts -- not open
defects. Each entry states what would close it, and the sequenced plan behind them
(ordered language-first and detectors-last) is in the
maintainer working notes.

Work that closed a gap lives in the rules table above, not here. Every closed
gap so far has surfaced one the work before it could not see, so treat this list
as live rather than closed.

1. **Safety on the load path catches the integer class only, and cannot catch
   more until the regions become slices.** The covered functions emitted just
   **4 trap sites**, because almost every access on that path is through a
   many-item C pointer, which carries no length -- there is no bound for a check
   to test. What the device now traps on is overflowing arithmetic and
   out-of-range `@intCast`, which is not a small thing: it is the class of the
   three bugs the fuzz found and of the matrix-capacity defect.
   The spatial class stays invisible, and the way to reach it is the slice
   conversion described in gap 3, after which the attribute already in place starts
   checking bounds with no further work. Two readers on the untrusted surface stay
   uncovered by the attribute for a reason that is not scheduling --
   `addTestPrograms` and `import_string_from_filename` live in the frontier
   object, where gap 2 says the attribute cannot go at all. Both now carry
   explicit bounds instead, which is the answer wherever that budget applies.
2. **The OLD_HW `.bss` headroom is a few hundred bytes at most, so runtime safety in the
   frontier object is priced in RAM.** Every DM42 link asserts
   `_ebss <= 0x10002000` (`upstream/src/c47-dmcp/stm32_program.ld`), and the
   link's `ram` row prints the headroom. When it was four bytes, adding
   `@setRuntimeSafety(true)` to one function in `../src/shell/config.zig` moved
   `_ebss` past the assert and failed the package-3 link; the frontier object's
   `.bss` was byte-identical either way, so the growth is a `--gc-sections` effect
   -- the attribute keeps something alive that was otherwise collected -- and
   installing `abi.trap_panic.namespace` on `frontier.zig` does NOT recover it. So
   the per-function flash price quoted for the load-path objects does not transfer
   here. Write explicit bounds instead of relying on the backstop, and note at the
   site why the attribute is absent. The package variants strip different code,
   so one can fail while `dmcp` and `dmcp5` link: `dmcp_pkgs_all` (gate step 10b)
   is the lane that catches it.
3. **There is no ASan, and if there were it could not see the C47 block
   allocator.** The lanes named `*_asan` run UBSan, not AddressSanitizer -- see
   [75-debugging.md](75-debugging.md). Registers, variables, programs, formulae,
   menus and the GMP heap all live in `ram`, a single ~256 KiB allocation carved
   by `../src/shell/free_list.zig`. One block overrunning its neighbour is, to
   ASan, a write inside a live allocation; Zig's checks never see it either,
   because blocks are reached by `[*c]` arithmetic. Writes into FREE pool space
   are covered by a poison pattern that needs no sanitizer runtime
   (`../src/shell/pool_poison.zig`, armed by `zig build state_load_fuzz`, host
   only), and reads and writes of free blocks by Valgrind's memcheck, which the
   free list keeps informed (`zig build memcheck_suite` and `test_memcheck`, CI only). An overrun from
   one live block into another live block stays invisible;
   reaching it needs per-allocation redzones, which would change the pool layout
   and so the firmware.
4. **The narrowing population is split and ratcheted on the load owners, but the
   rest of the tree is still one undifferentiated number.** Each site is either
   (a) provably in range, where `@intCast` is correct and says something true;
   (b) standing where upstream narrows implicitly, where `@intCast` is a PARITY
   DEFECT because C truncates and Zig traps; or (c) standing where upstream's
   unsigned arithmetic wraps, where the spelling must be `+%` / `-%` / `*%` or a
   saturating `+|` / `*|`. On `persist/` and `program/` this is now measured:
   `report-narrowing-status.py` ranks the sites inside safety-raised functions
   and `check-idiom-ratchet.sh` holds the count, with a FLOOR on the number of
   safety-raised functions so the ceiling cannot be met by deleting a check. The
   several thousand sites outside those owners are unclassified
   (`grep -ro '@intCast' src --include='*.zig' | wc -l` counts them), and no
   gate tells a correct cast from a defect there. Extending the analysis there
   needs the same per-site upstream reading; do not sweep it.
5. **A fix lands in one owner and its sibling twin is missed.** z47 keeps a
   state-file family and a program-file family that parse different formats with
   structurally identical helpers, and a fix applied to one has twice not been
   applied to the other: upstream's matrix-dimension clamp (absent from the Zig
   for four resyncs) and the program-load fuzz's saturating u32 line parse,
   which was fixed in `program_serialization_runtime.zig` while the
   byte-identical twin in `calc_state_runtime.zig` kept wrapping for three
   weeks. Nothing can see this today: the parity oracles compare each owner
   against upstream C, so two owners that differ from each other look fine, and
   the ratchets count shapes rather than semantics. `report-twin-divergence.py`
   now ranks the drifted pairs: it pairs same-named functions across the two
   families, canonicalises each family's own name (without that the seam pairs
   score ~0.86 and crowd out the real defect -- measured, the line-parse bug
   ranked seventh of eight), and sorts by similarity descending, since a
   one-operator drift is the suspicious case and a wholesale rewrite is just two
   functions sharing a name. That cross-family ranking is a report, not a gate,
   until its false-positive rate is known.

   **Detecting drift is second-best. The better move is to leave nothing to
   drift:** the line-parse helpers now exist ONCE, in `../src/abi/line_parse.zig`,
   and both families call it. A shared module cannot diverge from itself. Prefer
   that wherever the two families genuinely do the same thing; keep the scan for
   where they legitimately differ. Section 2a of
   `../.github/project/upstream-resync-runbook.md` applies the same rule to a
   header macro z47 had copied into every owner that expands it.

   **Twins also live inside one file.** Upstream generates function families
   from a single `#define`, so the members' ports must agree with each other:
   `report-twin-divergence.py --macro-families` compares them, and `--check`
   (gate step 4d) holds the disagreeing count at zero.
6. **`strtol` / `strtoul` results are platform-width, so upstream's own behaviour
   differs between targets.** `unsigned long` is 8 bytes on LP64 hosts and 4 on
   the arm-none-eabi firmware and on Windows (LLP64), so `strtoul` saturates at
   2^64 on one and 2^32 on the others. `toUint32("4304967321")` is 10000025 on a
   Linux host and 4294967295 on the device, from upstream's own code, and the
   parity oracles only run a host. No valid state file reaches the divergence, so
   it is decided per site rather than swept: every `strto*` call in `src/`
   carries a `// WIDTH-CONTRACT:` verdict (`no-width-question`, `unreachable`,
   `accepted` or `bounded`), and `check-strtoul-width-contract.py` (gate step 4e)
   fails a site without one.

### Rules For New Code

- Do not cast a pointer. [Pointer Casts](#pointer-casts) gives the typed
  replacement for each need and the conditions an exception must meet.
- Prefer `[]T` / `[N]T` over `[*c]` at z47-owned leaves and on the load owners
  where a length is known, but never on the transliterated spine, where matching
  upstream shape keeps re-sync cheap. On a file-backed region this is not cosmetic:
  a many-item pointer carries no length, so converting it to a slice is what makes
  a bound EXPRESSIBLE at all -- neither the producer nor any consumer can check one
  otherwise.
- Narrow with `@truncate` where upstream narrows implicitly, wrap with `+%`/`-%`
  where upstream's unsigned arithmetic wraps, and saturate with `+|`/`*|` where
  the intent is that an absurd size stays absurd. Reserve `@intCast` for values
  that provably fit. Getting this wrong is a parity bug before it is a safety
  bug. It is also a bug whose symptom depends on the build: a checked `@intCast`
  on a value C converts modularly panics on the safety-checked host and
  testSuite builds and is unchecked illegal behaviour in `small`, so the two
  disagree about what the program does and neither is reliably upstream's
  behaviour. Widen before the arithmetic where C's integer promotion widens -- C
  evaluates `rows - 1` and `a * b` in `int` even when both operands are
  narrower, and a port that does the same arithmetic in the operand width has
  changed the expression, not preserved it.
- Parenthesize an expression that mixes `%` with `*` or `/`, a shift with `+` or
  a bitwise operator, two of `&`, `|` and `^`, `and` with `or`, or `orelse` with
  a comparison. 0.17 groups each by its precedence table, as C does, but the
  monitored Zig master rejects them as ambiguous, so spell out the grouping the
  expression already has. `*` with `/`, and `+` with `-`, stay unparenthesized.
  A master snapshot's `zig ast-check <file>` finds them without a build; it
  reports the first in each function body, so run it again until it is clean.
- Raise `@setRuntimeSafety(true)` on a function that walks bytes z47 did not write.
  It works in `small`, so it reaches the device; it is lexical, so it does
  not follow calls and must go on each function; and it is a backstop under the
  explicit rejections, never a substitute for writing them.
- On any path that reads bytes the code did not produce, bound the write before
  it happens, not after. A length check that runs after the copy is not a check.
- When a ported reader has separate host and firmware bodies, bound both or
  neither, and say in the commit which upstream behaviour the bound preserves.
- A guard added to an unguarded upstream read must be behaviour-identical on
  valid input. That is what makes it portable back upstream and what keeps the
  parity oracles green -- see `31fb6f755` and the program-load fuzz fixes for the
  pattern.

## Pointer Casts

Do not cast a pointer. `@ptrCast` and `@alignCast` tell the compiler that memory
holds a type, at an alignment, that it cannot see, and the compiler takes the
claim on trust. A wrong claim is a misaligned access or a read past the end of an
object, and which one, if either, depends on the target: a C47 pool block is
4-byte aligned, which satisfies every type on the device and not an 8-byte field
on a 64-bit host, and Windows' 32-bit `c_long` gives one C declaration two sizes.
A pointer bound at its real type carries the same facts in its type, and the
compiler checks them on every target, including the Windows and macOS ones that
the cross-target object check in
[75-debugging.md](75-debugging.md#type-checking-another-targets-code-before-ci)
type-checks from Linux.

Among the ceilings `bash .github/project/check-idiom-ratchet.sh` prints and
holds, three count casts: `ptrcast_sites` (`@ptrCast` and `@alignCast`),
`constcast_sites` (`@constCast` and `@volatileCast`) and `ptr_from_int_sites`
(`@ptrFromInt`). A ceiling only moves down: lower it with `--bump` in the commit
that removes a site.

### What To Write Instead

| The code needs | Write |
| --- | --- |
| A pointer C hands back as `void *` | The `extern` bound at the type the owner stores, since C converts `void *` to any object pointer without a cast: `calc_state_backup.zig` binds `malloc` as `?[*]align(8) u8`, `wp34s.zig` as `?[*]u32`. |
| A C47 pool block for one type | `abi.allocC47BlocksAs(T, blocks)` for an array, `abi.allocC47BlocksFor(T, blocks)` for one value. Both carry the pool's 4-byte alignment in the type they return. |
| A value inside a byte buffer | `std.mem.bytesAsValue` for a pointer into the buffer, `std.mem.bytesToValue` for a copy, `std.mem.bytesAsSlice` for a run of values. Each takes a slice, so the size is checked, and the result has the buffer's alignment rather than a promised one. |
| The bytes of a value | `std.mem.asBytes`, or `std.mem.sliceAsBytes` for a slice. |
| An integer at a byte offset | `std.mem.readInt` and `std.mem.writeInt` over `bytes[offset..][0..@sizeOf(T)]`, in the byte order the bytes were written in: `.native` for the calculator's own memory. |
| A string handed to C | A sentinel slice of the buffer that holds it, `buf[0..n :0]`, which checks the terminator in a safety-checked build; `std.mem.sliceTo` and `std.mem.findScalar` read one back. |
| A record that follows another in one block | A typed view of the bytes after the first, as `localFlagsAfterHeader` in `register_metadata_local_registers.zig` reaches the flags after a subroutine level's header. |
| Storage sized by an upstream macro and read as a `real_t` | An `extern union` of the `real_t` and the storage when the storage is larger (`abi.Real159`, `BigReal` in `wp34s.zig` and `xfn.zig`), and a whole `real_t` when it is smaller (`julian` in `date_time.zig`). |
| One half of a complex number | Its `real` or `imag` field. |
| An optional pointer passed as `void *` | Nothing: `?[*]T` and `?*T` coerce to `?*anyopaque`. |
| An element of a `[*c]T` global | Index `@as([*]T, global)`. That is a coercion, which a safety-checked build checks for null. |
| A C callback that receives `const void *` | Bind the function that takes the callback at the parameter types the callback reads, as `softmenus.zig` binds `qsort` for `sortMenu`. |
| A pointer to C that is only read | A `const` parameter, not `@constCast` at the call. |
| A pointer into its argument that the caller writes through, as `strchr` returns | A mutable parameter, and the result formed from it: `stringAfterPixels` returns `str` plus the offset its width scan stopped at. |
| An empty result from a function whose other results are writable | A static writable buffer holding the empty value, as `dynmenuGetLabelWithDup`'s `no_label`, not a cast string literal. |
| A pool pointer from a block index, or the reverse | `progmem.Ram` in `calc_state_progmem.zig`: block indices and byte offsets against the typed `ram` base, and back to a pointer by adding the offset. |
| A frame that needs more alignment than the pool gives | `std.mem.alignInBytes` over the block's bytes, then `std.mem.bytesAsValue`, as `latticeAlloc` in `algdep.zig` does. |
| An element before the start of an array, which upstream reaches with a negative index | `elements - @abs(index)` on a many-item pointer, as `elementAt` in `mim_commands.zig` does. |
| An address the platform defines | `@ptrFromInt` of the SDK's constant, declared once: every DMCP ROM entry and the system data block in `../src/core/hal/dmcp_rom.zig`, which each object that calls the ROM imports; a GDK atom. Pointer arithmetic is not one: `p + n` on a many-item pointer or a typed view replaces `@ptrFromInt(@intFromPtr(p) + n)`. |
| A value read at another type of the same size | `@bitCast`, which the compiler checks for size. It reinterprets a value, not memory, and is how C's signed-to-unsigned conversions are ported. |

### The Exception

A pointer cast stays only where no typed view can describe the memory, and only
when all of these hold:

- An upstream constraint makes the storage differ from the type it is read as: a
  layout C fixes, or a size budget measured on the device. Convenience is not a
  constraint.
- The cast is the whole body of one accessor declared beside the storage, and
  nothing reaches the storage another way.
- The comment on the storage says why no union or typed view can express it, and
  which invariant keeps every access inside it.
- The commit that adds it raises the cast's ceiling, says why in its body, and
  names the cast in this section.

The graph engine's `PlotReal`, in `../src/core/analysis/graph.zig`, is the one
pointer cast in the tree. Upstream sizes every graph value for `PLOT_DIGITS`
digits, in `REAL_T_PTR`, `REAL_T_ALLOC` and the point records alike: storage
that decNumber fills in 24 bytes where a `real_t` takes 60, read through
`real_t` pointers. `graph_eqn` keeps buffers of plot points on its frame, three
values to a point, and takes the rest of its working set from the heap, against
the DM42's 6 kB program stack. Elsewhere a `REAL_T_PTR` smaller than a `real_t`
is ported as a whole `real_t`, which costs a few dozen bytes per value in a
function that holds a handful. The graph holds these values by the dozen in
every working block, so it keeps the short storage, and a union cannot hold it:
a union with a `real_t` member is as large as a `real_t`. `PlotReal.r()` is the
accessor. Nothing writes more digits than `ctxtGraphsLocal` allows, which is
what keeps every access inside the 24 bytes.

`real34ToDisplayString2`, in `../src/shell/display/display.zig`, is the one
`@constCast`. On the 2TO10 path of the UN display format, upstream rescales the
caller's value in place through a `const` pointer. It restores the value only
on the paths that reach the end of the function, so a value shown through one
of the early returns stays rescaled. Parity needs that write to land in the
caller's object. A local copy would not reproduce it, and a mutable parameter
would make every caller of `real34ToDisplayString` claim a write that only this
one path makes.

`@ptrFromInt` has no exception beyond the platform addresses the table names.
`grep -rn '@constCast\|@ptrFromInt' src --include='*.zig'` lists every site.

## `translate-c` Policy

Treat `translate-c` roots as narrow boundary tools, not a whole-project porting
strategy. Repo policy requires:

- generator and ABI-seam C translation to stay build-managed through explicit root
  headers under `../build/tools/translate_c/` and the official `translate-c`
  package, reached only through `addTranslator` in `../build/common.zig`
- exact justification for every checked-in boundary file
- build-managed integration through `addCSourceFiles`, `linkSystemLibrary`, or
  other explicit build-graph ownership where practical
- a parity or focused-validation lane behind every owner

## Rules For New Boundaries

- Add a new checked-in `translate-c` root or direct `extern` only when a
  build-managed or hand-written alternative is not practical.
- Update `../.github/project/zig-c-boundaries.txt`, the guard expectations, and
  this page in the same change.
- When an owner already has an approved `*_runtime.zig` seam, add new direct
  bindings there, not in the owner file.
- Declare a shared symbol once, not once per owner. A pure value helper lives in
  `../src/abi/` and every owner aliases it. Owners in the same build object
  `@import` a function over C state, and other objects bind it with one `extern`
  per object (registers.c's queries are declared once, in
  `../src/abi/registers.zig`). Section 2a of
  `../.github/project/upstream-resync-runbook.md` owns the procedure for a macro
  that becomes a function.
- A new `pub export` whose name is not in the pinned C widens z47's authored
  ABI. `check-authored-abi.py` (gate step 6h) fails when that set grows, so
  justify the symbol in the change or reach the definition through `@import`
  instead; `--list` prints the set.
- Keep the boundary file narrow and name the C surface it exposes.
- Add or update the focused validation lane in
  [70-tests-and-verification.md](70-tests-and-verification.md) when a new boundary
  affects behavior.

## Naming Rules

Naming policy is layer-specific, not one global rule.

- semantic owner file: the domain name, for example
  `../src/core/persist/calc_state.zig`
- direct legacy-boundary bindings: `*_runtime.zig`, for example
  `../src/core/persist/calc_state_runtime.zig`
- harness C helper files: `*_runtime_helpers.c`, under `../build/tests/` -- the
  only place first-party `.c` files live
- inside owner files and coherent internal-only helper clusters, use Zig casing
  only when the full internal-only family can move together in one bounded slice:
  directories and files `snake_case`, types `TitleCase`, functions `camelCase`,
  other values `snake_case`
- in `*_runtime.zig`, legacy C, `pub export`, and `extern`
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
