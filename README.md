# Zig Build Entry Point

`build.zig` is the canonical z47 build entrypoint.

This file is intentionally short. Use it as the top-level Zig quick start, then
use [zig_docs/README.md](zig_docs/README.md) for the detailed maintainer
documentation.

The imported `Makefile` and Meson files remain audit and parity-reference
surfaces. They are not the maintained z47 control plane.

Build orchestration lives under `zig_build/`. Live runtime Zig now lives under
`zig_src/`, and legacy runtime bridge C lives under `zig_bridge/`.

A Zig-owned build layer is not treated as value by itself in this repo. If a
new Zig surface does not replace buggy or retired C owners, fix a real build or
platform defect, or delete more legacy workflow debt than it adds, it is extra
maintenance overhead.

Current live runtime Zig owners are intentionally narrow: short-integer logical
leaf code plus the stack, register-metadata, flags, memory,
program-serialization, calc-state, and keyboard-state slices under `zig_src/`.

Imported upstream paths route through `UPSTREAM_ROOT` in
`.github/project/upstream-pin.env`; the current value `upstream` means the
imported baseline is mounted under `upstream/`, which is what leaves the
canonical `src/` and `docs/` names free for z47's own owners.

The May 2026 structural naming milestone is complete under the current
layer-scoped naming contract. For live owner, runtime, export, and legacy
naming rules, use
[zig_docs/10-build-and-source-layout.md](zig_docs/10-build-and-source-layout.md)
and
[zig_docs/50-zig-c-boundaries-and-rewrite-policy.md](zig_docs/50-zig-c-boundaries-and-rewrite-policy.md);
any future naming reopener must start from a fresh owner-specific inventory.

## Start Here

- [zig_docs/README.md](zig_docs/README.md): maintainer doc index and reading
  order
- [zig_docs/10-build-and-source-layout.md](zig_docs/10-build-and-source-layout.md):
  canonical build entrypoints, build layout, and local flow
- [zig_docs/20-zig-build-graph.md](zig_docs/20-zig-build-graph.md): live
  `build.zig` target map and domain split
- [zig_docs/40-firmware-and-distribution.md](zig_docs/40-firmware-and-distribution.md):
  firmware, package, and DMCP-variant details
- [zig_docs/70-tests-and-verification.md](zig_docs/70-tests-and-verification.md):
  smallest rerun lane for each change type
- [zig_docs/75-debugging.md](zig_docs/75-debugging.md): what each detector sees,
  the C-vs-Zig differential, and the false-pass catalogue
- [zig_docs/95-glossary.md](zig_docs/95-glossary.md): the calculator's
  vocabulary versus this port's

## Quick Start

Current pinned Zig baseline:

- Zig `0.16.0`
- pinned in `.github/zig-toolchain.env`

Common entrypoints:

```sh
zig build --help
zig build sim
zig build logical_shortint_parity
zig build rotate_bits_parity
zig build stack_state_parity
zig build register_metadata_parity
zig build flags_parity
zig build memory_parity
zig build program_serialization_parity
zig build calc_state_parity
zig build keyboard_state_parity
zig build keyboard_statusbar_flags_regression
zig build test
zig build generated
zig build docs
zig build dmcp
bash .github/project/check-zig-c-boundaries.sh
zig build dist_linux
bash .github/project/check-source-ownership.sh
bash .github/project/workflow-imported-root-paths.sh check-workflow
```

## Detailed Topics

Use `zig_docs/` for the detailed contract behind these areas:

- host simulator, generated artifacts, and docs build
- firmware prerequisites and legacy SDK or GMP dependencies
- distribution targets and host-specific package behavior
- approved Zig or C boundaries and current rewrite slices
- CI lanes, artifacts, and local reproduction commands
- debugging a divergence the lanes do not catch, and the vocabulary the pages use