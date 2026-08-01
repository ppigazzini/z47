# Official References

This page groups the canonical external and repo-local references that back the
maintainer docs and the checked-in z47 workflow.

Prefer these exact surfaces over broad summaries or secondary writeups.

Audit basis: 2026-08-01, upstream pin `6559a9c59`, Zig `0.16.0` stable. The
Zig memory-safety reference set was reviewed against upstream Zig on that date.

## Reference Map

```mermaid
flowchart TD
  A[Need a source of truth]
  B[Upstream C47 project]
  C[Zig toolchain and build system]
  G[Zig memory safety]
  D[Retained dependencies]
  E[CI and packaging]
  F[Repo-local audited files]

  A --> B
  A --> C
  C --> G
  A --> D
  A --> E
  A --> F
```

## Upstream Project Surfaces

- [C47 GitLab project](https://gitlab.com/rpncalculators/c43): authoritative
  upstream source repository consumed by z47. The path still uses the
  historical `c43` name even though the project identifies itself as C47.
- [BUILD.md](../BUILD.md): imported upstream build-target summary carried at
  the repo root.
- [Makefile](../Makefile): imported upstream human-facing command surface.
- [meson.build](../meson.build): imported upstream root build graph.
- [dep/meson.build](../dep/meson.build): imported upstream dependency build
  wiring.
- [src/c47/meson.build](../src/c47/meson.build): imported upstream main core
  build inputs.
- [src/c47-gtk/meson.build](../src/c47-gtk/meson.build): imported upstream GTK
  simulator build inputs.
- [src/c47-dmcp/meson.build](../src/c47-dmcp/meson.build): imported upstream
  DMCP build inputs.
- [src/c47-dmcp5/meson.build](../src/c47-dmcp5/meson.build): imported upstream
  DMCP5 build inputs.
- [docs/code/meson.build](../docs/code/meson.build): imported upstream code-doc
  build inputs.
- [subprojects/gmp-6.2.1.wrap](../subprojects/gmp-6.2.1.wrap): imported GMP wrap
  reference.

## Companion Upstream-Behaviour Doc Set

[c47-r47-ci](https://github.com/ppigazzini/c47-r47-ci) is the CI and test harness
for upstream C47/c43, and its `docs/` set is the maintained description of **the
product z47 ports** -- the C architecture, its memory model and its detectors.
z47 does not restate what that set owns; it links to it. Read it when the
question is "what does the calculator do, and why is the C shaped this way",
and read this set when the question is "how does the Zig port build, verify and
diverge".

| Their page | Owns, for z47's purposes |
| --- | --- |
| `docs/00-architecture.md` | the god header, the item table, the HAL, and the measured upstream dependency graph. Sections 9-11 are assessment and an unadopted proposal, not a plan of record |
| `docs/01-codebase.md` | the upstream source tree, the register file and memory model, and control flow from a key press to a screen |
| `docs/02-modules.md` | the subsystem inventory, each named by its literature term |
| `docs/04-testing.md` | the corpus, the three drivers, and the rules for writing a test that actually tests. z47 shares the corpus, so its authoring rules apply here unchanged |
| `docs/05-debugging.md` | the detectors z47 does not own: the pool canary (`POOL_GUARD`), pool and GMP leak scanning, Valgrind, coverage floors, Frama-C Eva, and the nesting-depth lane |
| `docs/06-memory.md` | the per-platform memory limits: the arenas, the DM42 stacks, what one nested engine level costs, and why a simulator run cannot answer a DM42 question |
| `docs/09-glossary.md` | the calculator's own vocabulary. [95-glossary.md](95-glossary.md) owns z47's |

The two sets are not gated against each other. Treat a number quoted across the
boundary as provenance, not as a live value, and re-derive it on the side that
owns it.

## Zig Toolchain And Build System

The pinned baseline is Zig `0.16.0` stable; the exact version, release date, and
checksum are recorded in [.github/zig-toolchain.env](../.github/zig-toolchain.env).

- [Zig download page](https://ziglang.org/download/): canonical release entry
  point.
- [Zig download index JSON](https://ziglang.org/download/index.json): canonical
  machine-readable release metadata used by the CI toolchain check.
- [Zig build system docs](https://ziglang.org/learn/build-system/): official
  build-system reference.
- [Zig C Translation CLI docs](https://ziglang.org/documentation/master/#C-Translation-CLI):
  official `translate-c` reference and limits.
- [Zig source repository](https://codeberg.org/ziglang/zig): canonical upstream
  Zig source tree.
- [README.md](../README.md): maintained z47 root entry point, command, and
  prerequisite summary.
- [CONTRIBUTING.md](../CONTRIBUTING.md): maintained contributor workflow and
  verification contract.
- [build.zig](../build.zig): live repo-root build router for this repository.

## Zig Memory-Safety References (primary)

Reviewed 2026-08-01. These are the sources the memory-safety posture in
[50-zig-c-boundaries-and-rewrite-policy.md](50-zig-c-boundaries-and-rewrite-policy.md)
is argued from. Read them as *what the toolchain does and does not give you* --
each entry ends with why it does or does not apply to a `ReleaseSmall`
freestanding calculator whose data lives in one static pool.

Language and toolchain:

- [Zig language reference -- Undefined Behavior](https://ziglang.org/documentation/master/#Undefined-Behavior):
  the canonical list of what is checked illegal behaviour (a panic in the safe
  modes) versus unchecked (silent in every mode). This is the authority for
  which of z47's 5628 `@intCast` sites are a trap on the host and a silent
  truncation on the device.
- [Zig 0.16.0 release notes](https://ziglang.org/download/0.16.0/release-notes.html):
  the pinned baseline. Safety-relevant changes: *forbid trivial local addresses
  returned from functions* (now a compile error, "returning address of expired
  local variable"), *forbid runtime vector indexes*, *forbid pointers in packed
  structs and unions*, *forbid unused bits in packed unions*, safe stack
  unwinding by default, and `heap.ThreadSafeAllocator` removed in favour of
  allocators that are lock-free themselves.
- [zig.guide -- Runtime Safety](https://zig.guide/language-basics/runtime-safety/):
  the per-build-mode table of which checks are live. The practical statement of
  why `ReleaseSmall` firmware is unchecked.

Allocator-level safety:

- [ziglang/zig#31186](https://codeberg.org/ziglang/zig/issues/31186): makes
  `DebugAllocator` and `ArenaAllocator` lock-free and thread-safe and deletes
  `ThreadSafeAllocator`; also the tracking issue for the planned
  `DebugAllocator` -> `SafeAllocator` rename with a ReleaseSafe-suitable
  configuration. `SafeAllocator` does not exist in 0.16 -- do not write it into
  a plan.
- [ziglang/zig#25978](https://github.com/ziglang/zig/issues/25978):
  `std.heap.DebugAllocator` with `.safety = true` is broken on **freestanding**
  targets. This rules out the otherwise-obvious "put a checking allocator on the
  device" move, independently of the flash cost.
- [AddressSanitizer manual poisoning](https://github.com/google/sanitizers/wiki/AddressSanitizerManualPoisoning):
  **Read the caveat first: z47 has no AddressSanitizer.** Zig 0.16 ships no ASan
  runtime and `-fsanitize=address` fails to link, so this API has nothing to talk
  to today; it is kept as the reference for what linking a system runtime would
  buy. See [75-debugging.md](75-debugging.md).
  `__asan_poison_memory_region` / `__asan_unpoison_memory_region`, the API that
  makes a custom arena visible to ASan. Chunks must be 8-aligned; C47 blocks are
  4 bytes, so a poisoning implementation must work in 8-byte shadow granules and
  accept that a 4-byte overrun into the next block's first word is not
  detectable. This is the only route to a detector for gap 2 in the posture.

What Zig does not give you:

- [How (memory) safe is Zig? (Jamie Brandon)](https://www.scattered-thoughts.net/writing/how-safe-is-zig/):
  the reference statement of the boundary. Zig catches bounds, null, tag
  confusion, overflow and alignment; it does **not** catch use-after-free,
  iterator invalidation, or interior-pointer invalidation. All three of those are
  live in a design that hands out indices into a relocatable pool, which is
  exactly what `freeListRealloc` does.
- [ziglang/zig#36237](https://codeberg.org/ziglang/zig/issues/36237): the
  accepted proposal (opened 2026-07-20) for a Fil-C-inspired memory-safe
  compilation mode -- a new "fil" ABI with pointer capabilities, no escape
  hatches, and no source changes required. **Not applicable to z47 and unlikely
  to become so**: it is defined for x86_64-linux only, the device is ARM
  freestanding, every linked object must use the same ABI (z47 links GMP,
  decNumber, GTK and the DMCP SDK), and the estimated 1-6x overhead is priced for
  a server, not a calculator. Track it for the host test lane only, and do not
  let a roadmap depend on it.

## Zig Idiom And Style Guidance (secondary)

There is no single official Zig style guide beyond `zig fmt` and the standard
library's naming conventions, so these are community/secondary sources plus a few
exemplar production codebases. They are the external basis for the idiom ratchet
([.github/project/report-idiom-status.py](../.github/project/report-idiom-status.py))
and for the code-quality assessment and refactor plan kept in the maintainer
working notes.

Domain match (which yardstick applies): z47 is a **safety-critical, no-heap,
embedded** calculator, so **TigerBeetle's TigerStyle is the primary calibration**
(static allocation, assertions, bounded loops, explicit limits). Ghostty is the
model for the comptime dispatch/platform seams. Bun's arena/heap idioms are
largely **out of domain** here and are kept only as a lint-discipline reference.

Scope caveat (important, do not misread): z47 is a faithful C→Zig transliteration
pinned for byte-for-byte upstream parity, so the transliterated owner surface is
deliberately **non-idiomatic** and cannot satisfy most of these rules — see the
C-ABI ceiling in
[50-zig-c-boundaries-and-rewrite-policy.md](50-zig-c-boundaries-and-rewrite-policy.md).
Only the std-only pure-core modules under `zig_src/*` registered in
[build.zig](../build.zig) `pure_modules` follow this guidance fully. Treat these
as the yardstick the code is *measured against*, not a description of the whole
codebase.

Exemplar production codebases (primary calibration for this domain):

- [TigerBeetle TigerStyle](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md):
  the closest domain peer — NASA-Power-of-Ten lineage: static allocation (none
  after init), ≥2 assertions per function, ≤70-line functions, bounded loops with
  asserted caps, explicitly-sized ints over `usize`/`c_int`. The primary yardstick
  for z47's firmware-facing code.
- [Ghostty — Useful Zig Patterns (Hashimoto)](https://mitchellh.com/writing/ghostty-and-useful-zig-patterns):
  comptime interfaces for platform code, comptime data tables + `@Type` enum
  generation + platform pruning (the model for a native item table), and
  Zig-as-C-library (which validates z47's C-ABI shell as a boundary technique).

General style / review references (secondary):

- [Bun / oven-sh Zig style guide](https://github.com/oven-sh/style-guide):
  production-scale Zig conventions (const over var, slices `[]T` over
  pointer+length, named error sets, tagged unions over bool params, small
  functions, minimal `@as`/`@intCast`). Its arena/heap idioms do not apply to the
  no-heap firmware path.
- [Zig naming conventions (Craddock)](https://nathancraddock.com/blog/zig-naming-conventions/):
  the camelCase-function / PascalCase-type / snake_case-variable conventions the
  owners follow.
- [Learning Zig: Style Guide](https://www.openmymind.net/learning_zig/style_guide/):
  community style reference.
- [zigcc/zig-idioms](https://github.com/zigcc/zig-idioms): common Zig idiom
  catalogue.
- [Zig memory-safety code-review checklist](https://pullpanda.io/blog/zig-code-review-checklist):
  the allocator / `errdefer` / bounds / optional / overflow checklist the pure
  cores are reviewed against.

## Retained Dependency References

z47 keeps these third-party surfaces as external or vendored C; none is a
Zig-native replacement (see
[50-zig-c-boundaries-and-rewrite-policy.md](50-zig-c-boundaries-and-rewrite-policy.md)).

- [GTK 3 docs](https://docs.gtk.org/gtk3/): canonical GTK 3 API and platform
  reference; retained external C library linked from Zig for the host simulator.
- [FreeType documentation](https://freetype.org/freetype2/docs/): canonical
  FreeType 2 reference; retained external C library linked from Zig (host).
- [GMP project page](https://gmplib.org/): canonical GMP project and release
  reference; retained external C library linked from Zig (host).
- [SwissMicros DMCP_SDK](https://github.com/swissmicros/DMCP_SDK): canonical
  DMCP hardware SDK repository (from upstream `.gitmodules`); retained external C
  input linked from Zig for DMCP firmware.
- [SwissMicros DMCP5_SDK](https://github.com/swissmicros/DMCP5_SDK): canonical
  DMCP5 hardware SDK repository (from upstream `.gitmodules`); retained external
  C input linked from Zig for DMCP5 firmware.
- PulseAudio: retained optional external host audio dependency, linked from Zig
  when present; no separate canonical doc surface is pinned here.
- The vendored `dep/decNumberICU` is compiled by Zig rather than linked as an
  external library; there is no external canonical doc surface to pin for it.

## Generator And Packaging Helper References

- [xlsxio repository](https://github.com/brechtsanders/xlsxio): build-time
  generator helper (`xlsxio_xlsx2csv` plus `libxlsxio_read`) used by the
  font-generator toolchain and its CI lanes; not a product-runtime dependency.
- [GitHub Actions workflow syntax](https://docs.github.com/actions/using-workflows/workflow-syntax-for-github-actions):
  workflow trigger, job, matrix, and artifact syntax reference.
- [GitHub Actions artifacts docs](https://docs.github.com/actions/using-workflows/storing-workflow-data-as-artifacts):
  artifact publishing and retention behavior.
- [GitHub Actions cache docs](https://docs.github.com/actions/using-workflows/caching-dependencies-to-speed-up-workflows):
  cache-key behavior used by the host-platform workflows.

## Repo-Local Governance And Pin Map

When a maintainer claim depends on the live repo state, inspect these checked-in
files before widening to external sources.

Pins and manifests:

- [.github/project/upstream-pin.env](../.github/project/upstream-pin.env):
  imported upstream commit, branch, and pin-updated date.
- [.github/zig-toolchain.env](../.github/zig-toolchain.env): pinned Zig stable
  version, release date, checksum, and the monitored Zig master snapshot.
- [.github/project/source-ownership.txt](../.github/project/source-ownership.txt):
  z47-owned versus imported-upstream surface manifest.
- [.github/project/upstream-port-ledger.tsv](../.github/project/upstream-port-ledger.tsv):
  per-surface port-state ledger.
- [.github/project/zig-c-boundaries.txt](../.github/project/zig-c-boundaries.txt):
  approved `@cImport`, `extern`, and generated-seam boundary manifest.
- [.github/project/idiom-status-baseline.json](../.github/project/idiom-status-baseline.json):
  idiomatic-Zig ratchet baseline.

Runbooks and gate scripts:

- [.github/project/upstream-resync-runbook.md](../.github/project/upstream-resync-runbook.md):
  the pin-advance (upstream resync) procedure.
- [.github/project/run-local-gate.sh](../.github/project/run-local-gate.sh):
  one command that reproduces the full Linux CI verdict before pushing.
- [.github/project/run-host-parity-battery.sh](../.github/project/run-host-parity-battery.sh):
  the host-parity build/test/oracle battery invoked by the local gate.
- [.github/project/check-portable-int-widths.sh](../.github/project/check-portable-int-widths.sh):
  portable integer-width governance guard.

Root entry points and CI workflows:

- [.github/project/check-extern-var-widths.py](../.github/project/check-extern-var-widths.py):
  every `extern var` declaration must be as wide as the `export var` defining it;
  a wider declaration makes each store through it write past the end of the real
  object, and only the linker decides what that hits
- [.github/project/check-c-type-alias-widths.sh](../.github/project/check-c-type-alias-widths.sh):
  a C type aliased in two owners must have the same width in both
- [README.md](../README.md)
- [BUILD.md](../BUILD.md)
- [zig_docs/README.md](README.md)
- [build.zig](../build.zig)
- [.github/workflows/upstream-oracle.yml](../.github/workflows/upstream-oracle.yml)
- [.github/workflows/upstream-drift.yml](../.github/workflows/upstream-drift.yml)
- [.github/workflows/c-dependency-zero.yml](../.github/workflows/c-dependency-zero.yml)

## Reference Rules

- Prefer canonical repo-local files over paraphrases when the live checked-in
  state matters.
- Prefer official vendor docs over blogs or forum threads when a toolchain or
  dependency claim matters.
- Record uncertainty explicitly when a claim was not revalidated against the
  live file or the canonical external page.
