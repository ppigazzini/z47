# Zig And C Boundaries And Rewrite Policy

This page records the seam-and-core architecture, the retained C surfaces, the
approved checked-in Zig/C boundaries, and the rules that keep those boundaries
reviewable.

Read [00-project-and-upstream.md](00-project-and-upstream.md) first. This page
assumes the ownership split and the "core fully in Zig, C retained for parity"
framing are already clear.

Audit basis: 2026-07-10, upstream pin `0caee2adc`, Zig `0.16.0` stable.

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

The ratchet now sits at its C-ABI ceiling: the remaining `callconv(.c)`,
`extern`, `extern struct`, and offset metrics are mandated by the upstream
testSuite dispatch contract and the firmware object layout, not reducible debt.
Ongoing owner work is idiomatic refinement within that ceiling. See the
churn-driven notes in [80-maintainer-workflow.md](80-maintainer-workflow.md).

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
  `../zig_src/state/calc_state.zig`
- direct legacy-boundary bindings: `*_runtime.zig`, for example
  `../zig_src/state/calc_state_runtime.zig`
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
