# z47

z47 is the maintained Zig-first build, CI, packaging, documentation, and staged
rewrite overlay for the upstream C47 calculator application.

The authoritative upstream source repository is
`https://gitlab.com/rpncalculators/c43.git`. That GitLab path still uses the
historical `c43` name even though the project identifies itself as C47.

The repo root carries a pinned imported upstream working tree plus the z47-owned
control plane under `build.zig`, `zig_build/`, `.github/`, `zig_docs/`, and the
root maintainer docs.

`build.zig` is the sole supported maintained build entry point. The imported
`Makefile` and Meson files remain audit and parity-reference surfaces, not the
maintained z47 control plane.

## Start Here

- [ZIG-README.md](ZIG-README.md): short Zig build quick start and command map
- [zig_docs/README.md](zig_docs/README.md): maintained developer-doc index and
	read order
- [CONTRIBUTING.md](CONTRIBUTING.md): branch policy, focused verification, and
	doc-promotion rules

## Current Retained Dependencies

The live build still keeps these retained C or vendor surfaces explicit:

- imported upstream calculator sources under `src/`
- `dep/decNumberICU`
- GTK 3
- FreeType 2
- GMP
- SwissMicros `DMCP_SDK` and `DMCP5_SDK`

Do not describe the repo as pure Zig while those dependencies remain in the
build and package graph.
