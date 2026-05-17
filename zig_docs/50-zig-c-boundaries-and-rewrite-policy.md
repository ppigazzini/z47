# Zig And C Boundaries And Rewrite Policy

This page records the current Zig rewrite slices, the approved checked-in
Zig or C boundaries, and the rules that keep those boundaries reviewable.

Read [00-project-and-upstream.md](00-project-and-upstream.md) first. This page
assumes the imported upstream ownership split is already clear.

## Three Implementation Modes

z47 uses three explicit implementation modes.

| Mode | Meaning | Current examples |
| --- | --- | --- |
| existing C compiled by Zig | imported or retained C sources are still the executable implementation even though Zig drives the build | `src/c47`, `src/c47-gtk`, `src/c47-dmcp`, `src/c47-dmcp5`, `dep/decNumberICU` |
| explicit Zig or C boundary | checked-in `translate-c` root headers and direct `extern` usage are allowed only in approved boundary files; checked-in `@cImport` is currently avoided | generator boundary roots under `zig_build/tools/translate_c/`, plus runtime seams under `zig_src/leaf/`, `zig_src/mathematics/`, `zig_src/state/`, and `zig_src/ui/` |
| manual Zig rewrite | the implementation itself now lives in Zig and is parity-gated | `zig_build/tools/` generators plus the live runtime slices under `zig_src/leaf/`, `zig_src/mathematics/`, `zig_src/state/`, and `zig_src/ui/` |

## Current Surface Classification

| Surface | Current classification | Notes |
| --- | --- | --- |
| `../src/c47` core | existing C compiled by Zig, with selected leaf, mathematics-wrapper, state, and UI replacements | broad stateful core still mostly remains imported C |
| `../src/c47-gtk` | existing C compiled by Zig | desktop simulator and host HAL remain imported C |
| `../src/c47-dmcp` and `../src/c47-dmcp5` | existing C compiled by Zig | hardware HAL and packaging inputs remain imported C |
| `../dep/decNumberICU` | retained vendored C dependency | still compiled as C |
| GTK 3, FreeType 2, GMP, libm, optional PulseAudio | external C libraries linked from Zig | retained host dependency stack |
| `../zig_build/tools/translate_c/` | approved build-managed `translate-c` boundary roots | checked-in generator header roots consumed by `../zig_build/host/generated.zig` |
| `../zig_build/tools/generate_constants.zig` | manual Zig executable with build-managed `translate-c` boundary | deterministic generator entrypoint |
| `../zig_build/tools/generate_catalogs.zig` | manual Zig executable with build-managed `translate-c` and `extern` boundary | deterministic generator entrypoint |
| `../zig_build/tools/generate_testpgms.zig` | manual Zig executable with build-managed `translate-c` and `extern` boundary | deterministic generator entrypoint |
| `../zig_build/tools/ttf2_raster_fonts.zig` | manual Zig executable with build-managed `translate-c` boundary | raster font generator entrypoint |
| `../zig_src/leaf/shortint_core.zig` and logical leaf files | manual Zig rewrite | parity-gated short-integer leaf slice, including mask, count, boolean operators, bit toggles, rotate or justify, mirror, byte swap, zip, and unzip helpers |
| `../zig_src/mathematics/math_command_wrappers.zig` plus `../zig_build/mathematics/math_command_wrapper_rewrites.zig` | manual Zig rewrite | parity-gated mathematics command and shared-helper slice for `min`, `max`, `ceil`, `floor`, `sign`, `changeSign`, `sin`, `cos`, `tan`, `sinh`, `cosh`, `square`, and `cube`, plus shared exports such as `chsReal`, `chsCplx`, `chsShoI`, `sinComplex`, `cosComplex`, `TanComplex`, `sinCosReal`, `sinCosCplx`, `sinhCoshReal`, and `sinhCoshCplx` |
| `../zig_src/state/stack.zig` plus `../zig_build/state/stack_rewrites.zig` | manual Zig rewrite | parity-gated live stack and undo owner slice |
| `../zig_src/state/register_metadata.zig` plus `../zig_build/state/register_metadata_rewrites.zig` | manual Zig rewrite | parity-gated live register-metadata accessor slice |
| `../zig_src/state/flags.zig` plus `../zig_build/state/flags_rewrites.zig` | manual Zig rewrite | parity-gated live system-flag accessor and change-tracking slice |
| `../zig_src/state/memory.zig` plus `../zig_build/state/memory_rewrites.zig` | manual Zig rewrite | parity-gated live memory-helper slice |
| `../zig_src/state/program_serialization.zig` plus `../zig_build/state/program_serialization_rewrites.zig` | manual Zig rewrite | parity-gated live program-serialization slice |
| `../zig_src/state/calc_state.zig` plus `../zig_build/state/calc_state_rewrites.zig` | manual Zig rewrite | parity-gated save or restore owner slice with retained firmware entrypoints routed through a runtime seam |
| `../zig_src/state/keyboard_state.zig` plus `../zig_build/state/keyboard_state_rewrites.zig` | manual Zig rewrite | parity-gated keyboard helper and command-state slice while some firmware-sized public entrypoints still stay retained C |
| `../zig_bridge/state/` retained helper shims | existing C compiled by Zig | explicit runtime bridge helpers paired with the live Zig owners |
| `../zig_src/ui/tone.zig` plus `../zig_build/ui/tone_rewrites.zig` | manual Zig rewrite | parity-gated UI tone command slice for `fnTone` and `fnBeep` |
| `../zig_bridge/mathematics/math_wrappers_runtime_helpers.c` | existing C compiled by Zig | retained long-integer, extra-info, and error-message shim paired with the mathematics command and shared-helper slice |
| `../zig_bridge/ui/tone_runtime_helpers.c` | existing C compiled by Zig | retained target-specific refresh helper paired with the live Zig tone owner |
| `../zig_src/leaf/shortint_runtime.zig` | approved direct `extern` boundary | retained runtime seam for the rewrite slice |
| `../zig_src/mathematics/math_command_wrappers_runtime.zig` | approved direct `extern` boundary | retained runtime seam for the mathematics command and shared-helper slice |
| `../zig_src/state/calc_state_runtime.zig` | approved direct `extern` boundary | retained runtime seam for the calc-state slice |
| `../zig_src/state/stack_runtime.zig` | approved direct `extern` boundary | retained runtime seam for the stack-state slice |
| `../zig_src/state/register_metadata_runtime.zig` | approved direct `extern` boundary | retained runtime seam for the register-metadata slice |
| `../zig_src/state/flags_runtime.zig` | approved direct `extern` boundary | retained runtime seam for the system-flag slice |
| `../zig_src/state/keyboard_state_runtime.zig` | approved direct `extern` boundary | retained runtime seam for the keyboard-state slice |
| `../zig_src/state/memory_runtime.zig` | approved direct `extern` boundary | retained runtime seam for the memory slice |
| `../zig_src/state/program_serialization_runtime.zig` | approved direct `extern` boundary | retained runtime seam for the program-serialization slice |
| `../zig_src/ui/tone_runtime.zig` | approved direct `extern` boundary | retained runtime seam for the UI tone slice |

## Approved Checked-In Boundary Files

The checked-in allowlist lives in `../.github/project/zig-c-boundaries.txt`.

Current approved build-managed `translate-c` root files:

- `zig_build/tools/translate_c/generate_constants.h`
- `zig_build/tools/translate_c/generate_catalogs.h`
- `zig_build/tools/translate_c/generate_testpgms.h`
- `zig_build/tools/translate_c/ttf2_raster_fonts.h`

Current approved checked-in `@cImport` files:

- none

Current approved direct `extern` symbol files:

- `zig_build/tools/generate_catalogs.zig`
- `zig_build/tools/generate_testpgms.zig`
- `zig_src/leaf/shortint_runtime.zig`
- `zig_src/mathematics/math_command_wrappers_runtime.zig`
- `zig_src/state/calc_state_runtime.zig`
- `zig_build/tests/keyboard_state/keyboard_state_parity_runtime.zig`
- `zig_src/state/flags_runtime.zig`
- `zig_src/state/keyboard_state_runtime.zig`
- `zig_src/state/memory_runtime.zig`
- `zig_src/state/program_serialization_runtime.zig`
- `zig_src/state/register_metadata_runtime.zig`
- `zig_src/state/stack_runtime.zig`
- `zig_src/ui/tone_runtime.zig`

No other checked-in Zig file is allowed to introduce `@cImport` or direct
`extern fn`, `extern const`, or `extern var` usage without updating the
allowlist and guard at the same time.

## Guard And CI Enforcement

`../.github/project/check-zig-c-boundaries.sh` enforces the allowlist.

Current guard behavior:

1. load allowlisted files from `zig-c-boundaries.txt`
2. verify each allowlisted `translate-c` root header still exists and still
  exposes real C includes for the checked-in generator boundary
3. verify each allowlisted checked-in Zig file still matches the expected
  `@cImport` or direct-`extern` pattern
4. scan all current working-tree `zig_build/tools/translate_c/*.h` roots plus
  all tracked `*.zig` files that exist in the repository
5. fail if a checked-in generator `translate-c` root header, checked-in
  `@cImport`, or direct `extern` binding appears outside the approved lists

The guard runs in CI through the `zig-c-boundary-guard` job in
`../.github/workflows/upstream-oracle.yml`.

Current maintainer finding:

- when a rewrite slice already has a `*_runtime.zig` seam, keep any new direct
  retained-C `extern` bindings there and call them through seam helpers from the
  owner file; moving those bindings into the owner file itself is treated as
  boundary drift and will fail the guard

## Rewrite Status That Matters

The current checked-in manual Zig rewrite slices are intentionally narrow.

Verified slices:

- deterministic generators under `../zig_build/tools/`
- short-integer leaf modules under `../zig_src/leaf/`, including the live
  `logicalOps/rotateBits.c` owner replacement and the live boolean operator
  owner replacements for `and.c`, `or.c`, `not.c`, `nand.c`, `nor.c`,
  `xor.c`, and `xnor.c`
- mathematics command-wrapper ownership under `../zig_src/mathematics/`,
  including the live `sign.c`, `changeSign.c`, `square.c`, and `cube.c`
  owner replacements, with retained helper entrypoints reached through
  `../zig_src/mathematics/math_command_wrappers_runtime.zig`
- stack mutation plus undo snapshot or restore ownership under
  `../zig_src/state/`
- register-metadata accessors under `../zig_src/state/`
- exported system-flag accessor and change-tracking logic under
  `../zig_src/state/`
- memory helper ownership under `../zig_src/state/`
- program-serialization ownership under `../zig_src/state/`
- calc-state save or restore ownership under `../zig_src/state/`, with retained
  firmware entrypoints still reached through `../zig_src/state/calc_state_runtime.zig`
- keyboard helper and command-state ownership under `../zig_src/state/`, with
  retained public entrypoints still used where firmware size requires them
- tone command ownership under `../zig_src/ui/`, with target-specific display
  refresh still routed through `../zig_src/ui/tone_runtime.zig` and the retained
  helper `../zig_bridge/ui/tone_runtime_helpers.c`

Not yet rewritten in broad verified form:

- broader flag-command and configuration control beyond the exported
  system-flag accessor surface and the current helper-level owner slices
- full keyboard public-entrypoint ownership on firmware-sized DMCP builds
- GTK simulator implementation
- broad firmware HAL or packaging logic

## `translate-c` Policy

Treat build-managed `translate-c` roots and any remaining checked-in
`@cImport` use as narrow boundary tools, not as a whole-project porting
strategy.

Current repo policy requires:

- generator C translation to stay build-managed through explicit root headers
  under `../zig_build/tools/translate_c/` and `Build.addTranslateC` wiring in
  `../zig_build/host/generated.zig`
- exact justification for every checked-in boundary file
- build-managed integration through `addCSourceFiles`, `addCSourceFile`,
  `linkSystemLibrary`, or other explicit build-graph ownership where practical
- parity or focused validation before widening a manual Zig rewrite slice

## Rules For New Boundaries

- Add new checked-in `translate-c` root headers, checked-in `@cImport`, or
  direct `extern` usage only when a smaller build-system-owned or manually
  rewritten alternative is not practical yet.
- Update `../.github/project/zig-c-boundaries.txt`, the guard expectations, and
  this page in the same change.
- When a slice already has an approved `*_runtime.zig` seam, add new direct
  retained-C bindings there instead of in the Zig owner file.
- Keep the boundary file narrow and name the retained C surface it exposes.
- Add or update the focused validation lane in
  [70-tests-and-verification.md](70-tests-and-verification.md) when the new
  boundary affects behavior.

## Review Rules

- Prefer shrinking or clarifying boundaries over moving them around.
- Do not scatter direct C bindings across host, firmware, or future rewrite
  code.
- Keep docs honest about what is really rewritten in Zig and what is still C.