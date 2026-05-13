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
| explicit Zig or C boundary | checked-in `@cImport` or direct `extern` usage is allowed only in approved boundary files | generator boundary files under `zig_build/tools/`, runtime boundaries `zig_build/leaf/shortint_runtime.zig`, `zig_build/state/stack_runtime.zig`, `zig_build/state/register_metadata_runtime.zig`, and `zig_build/state/flags_runtime.zig` |
| manual Zig rewrite | the implementation itself now lives in Zig and is parity-gated | `zig_build/tools/` generators, `zig_build/leaf/` short-integer logical slice, and `zig_build/state/` stack-state, register-metadata, and system-flag slices |

## Current Surface Classification

| Surface | Current classification | Notes |
| --- | --- | --- |
| `../src/c47` core | existing C compiled by Zig, with selected leaf, stack, register-metadata, and system-flag replacements | broad stateful core still mostly remains imported C |
| `../src/c47-gtk` | existing C compiled by Zig | desktop simulator and host HAL remain imported C |
| `../src/c47-dmcp` and `../src/c47-dmcp5` | existing C compiled by Zig | hardware HAL and packaging inputs remain imported C |
| `../dep/decNumberICU` | retained vendored C dependency | still compiled as C |
| GTK 3, FreeType 2, GMP, libm, optional PulseAudio | external C libraries linked from Zig | retained host dependency stack |
| `../zig_build/tools/generate_constants.zig` | manual Zig executable with approved `@cImport` boundary | deterministic generator entrypoint |
| `../zig_build/tools/generate_catalogs.zig` | manual Zig executable with approved `@cImport` and `extern` boundary | deterministic generator entrypoint |
| `../zig_build/tools/generate_testpgms.zig` | manual Zig executable with approved `@cImport` and `extern` boundary | deterministic generator entrypoint |
| `../zig_build/tools/ttf2_raster_fonts.zig` | manual Zig executable with approved `@cImport` boundary | raster font generator entrypoint |
| `../zig_build/leaf/shortint_core.zig` and logical leaf files | manual Zig rewrite | parity-gated short-integer logical slice |
| `../zig_build/state/stack.zig` and `../zig_build/state/stack_rewrites.zig` | manual Zig rewrite | parity-gated live stack and undo owner slice |
| `../zig_build/state/register_metadata.zig` and `../zig_build/state/register_metadata_rewrites.zig` | manual Zig rewrite | parity-gated live register-metadata accessor slice |
| `../zig_build/state/flags.zig` and `../zig_build/state/flags_rewrites.zig` | manual Zig rewrite | parity-gated live system-flag accessor and change-tracking slice |
| `../zig_build/leaf/shortint_runtime.zig` | approved direct `extern` boundary | retained runtime seam for the rewrite slice |
| `../zig_build/state/stack_runtime.zig` | approved direct `extern` boundary | retained runtime seam for the stack-state slice |
| `../zig_build/state/register_metadata_runtime.zig` | approved direct `extern` boundary | retained runtime seam for the register-metadata slice |
| `../zig_build/state/flags_runtime.zig` | approved direct `extern` boundary | retained runtime seam for the system-flag slice |

## Approved Checked-In Boundary Files

The checked-in allowlist lives in `../.github/project/zig-c-boundaries.txt`.

Current approved `@cImport` files:

- `zig_build/tools/generate_constants.zig`
- `zig_build/tools/generate_catalogs.zig`
- `zig_build/tools/generate_testpgms.zig`
- `zig_build/tools/ttf2_raster_fonts.zig`

Current approved direct `extern` symbol files:

- `zig_build/tools/generate_catalogs.zig`
- `zig_build/tools/generate_testpgms.zig`
- `zig_build/leaf/shortint_runtime.zig`
- `zig_build/state/flags_runtime.zig`
- `zig_build/state/register_metadata_runtime.zig`
- `zig_build/state/stack_runtime.zig`

No other checked-in Zig file is allowed to introduce `@cImport` or direct
`extern fn`, `extern const`, or `extern var` usage without updating the
allowlist and guard at the same time.

## Guard And CI Enforcement

`../.github/project/check-zig-c-boundaries.sh` enforces the allowlist.

Current guard behavior:

1. load allowlisted files from `zig-c-boundaries.txt`
2. verify each allowlisted file still matches the expected `@cImport` or
   direct-`extern` pattern
3. scan all tracked `*.zig` files in the repository
4. fail if a checked-in Zig file contains an unapproved `@cImport` or direct
   `extern` binding

The guard runs in CI through the `zig-c-boundary-guard` job in
`../.github/workflows/upstream-oracle.yml`.

## Rewrite Status That Matters

The current checked-in manual Zig rewrite slices are intentionally narrow.

Verified slices:

- deterministic generators under `../zig_build/tools/`
- short-integer logical leaf modules under `../zig_build/leaf/`
- stack mutation plus undo snapshot or restore ownership under
  `../zig_build/state/`
- register-metadata accessors under `../zig_build/state/`
- exported system-flag accessor and change-tracking logic under
  `../zig_build/state/`

Not yet rewritten in broad verified form:

- broader flag-command and configuration control beyond the exported
  system-flag accessor surface, memory helpers, save or restore surfaces
  outside stack undo, and execution-state surfaces
- GTK simulator implementation
- broad firmware HAL or packaging logic

## `translate-c` Policy

Treat `translate-c` and checked-in `@cImport` use as narrow boundary tools, not
as a whole-project porting strategy.

Current repo policy requires:

- exact justification for every checked-in boundary file
- build-managed integration through `addCSourceFiles`, `addCSourceFile`,
  `linkSystemLibrary`, or other explicit build-graph ownership where practical
- parity or focused validation before widening a manual Zig rewrite slice

## Rules For New Boundaries

- Add new checked-in `@cImport` or direct `extern` usage only when a smaller
  build-system-owned or manually rewritten alternative is not practical yet.
- Update `../.github/project/zig-c-boundaries.txt`, the guard expectations, and
  this page in the same change.
- Keep the boundary file narrow and name the retained C surface it exposes.
- Add or update the focused validation lane in
  [70-tests-and-verification.md](70-tests-and-verification.md) when the new
  boundary affects behavior.

## Review Rules

- Prefer shrinking or clarifying boundaries over moving them around.
- Do not scatter direct C bindings across host, firmware, or future rewrite
  code.
- Keep docs honest about what is really rewritten in Zig and what is still C.