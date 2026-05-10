# Build Targets

The maintained build and packaging entrypoint is now `zig build`.

Use [ZIG-README.md](ZIG-README.md) for the canonical command list, dependency
requirements, output locations, and current validation status.

Quick examples:

```sh
zig build sim
zig build both_asan
zig build test_asan
zig build docs
zig build dmcp
zig build dist_linux
zig build dist
```

The imported `Makefile`, Meson files, Ninja files, and related upstream build
assets remain in the tree as audit and rebase reference material. They are no
longer the maintained z47 control plane.

