# Zig Build Entry Point

`build.zig` is the canonical z47 build entrypoint.

This file is intentionally short. Use it as the top-level Zig quick start, then
use [zig_docs/README.md](zig_docs/README.md) for the detailed maintainer
documentation.

The imported `Makefile` and Meson files remain audit and parity-reference
surfaces. They are not the maintained z47 control plane.

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

## Quick Start

Current pinned Zig baseline:

- Zig `0.16.0`
- pinned in `.github/zig-toolchain.env`

Common entrypoints:

```sh
zig build --help
zig build sim
zig build stack_state_parity
zig build test
zig build generated
zig build docs
zig build dmcp
zig build dist_linux
```

## Detailed Topics

Use `zig_docs/` for the detailed contract behind these areas:

- host simulator, generated artifacts, and docs build
- firmware prerequisites and retained SDK or GMP dependencies
- distribution targets and host-specific package behavior
- approved Zig or C boundaries and current rewrite slices
- CI lanes, artifacts, and local reproduction commands