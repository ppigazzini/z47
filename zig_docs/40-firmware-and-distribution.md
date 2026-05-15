# Firmware And Distribution

This page explains the Zig-owned firmware and packaging surfaces that replace
the maintained Make or Meson entrypoints while still retaining the upstream C,
SDK, and packaging dependency stack.

Read [20-zig-build-graph.md](20-zig-build-graph.md) first. This page assumes
the build-domain split is already clear.

## Firmware Surface At A Glance

The current firmware build graph is Zig-owned orchestration around retained C
inputs and retained third-party tools.

That means:

- firmware targets are invoked through `zig build`
- the firmware source and SDK inputs still come from imported upstream C and
  SwissMicros SDK trees
- the live firmware graph now filters imported `src/c47/stack.c` and links the
  Zig stack-state object from `../zig_src/state/stack.zig` plus
  `../zig_bridge/state/stack_runtime_helpers.c`
  while the rest of the core remains retained C
- the cross-GMP bootstrap still uses upstream Autoconf and Make internally
- package creation is still more than compilation; it includes program, QSPI,
  map, and archive outputs

## Firmware Target Matrix

| Step | Board family | Model | Program extension | Notes |
| --- | --- | --- | --- | --- |
| `dmcp` | DMCP | C47 | `.pgm` | honors `-Ddmcp-package`, default `4` |
| `dmcpr47` | DMCP | R47 | `.pgm` | honors `-Ddmcp-package`, default `4` |
| `dmcp5` | DMCP5 | C47 | `.pg5` | fixed board family, no DMCP package switch |
| `dmcp5r47` | DMCP5 | R47 | `.pg5` | fixed board family, no DMCP package switch |
| `dmcp_pkg1` | DMCP | C47 | `.pgm` | fixed package `1` |
| `dmcp_pkg2` | DMCP | C47 | `.pgm` | fixed package `2` |
| `dmcp_pkg3` | DMCP | C47 | `.pgm` | fixed package `3` |
| `dmcp_pkgs_all` | DMCP | C47 | mixed | grouped package-variant build |

Each firmware build produces these output classes:

- program image
- QSPI image
- linker map file

## Retained Toolchain And Dependency Stack

Current firmware prerequisites are:

- `arm-none-eabi-gcc`
- `arm-none-eabi-objcopy`
- `arm-none-eabi-readelf`
- `python3`
- `tar`
- `make`
- native `cc` or `gcc` for the cross-GMP bootstrap

Current retained dependency inputs are:

- `../dep/DMCP_SDK`
- `../dep/DMCP5_SDK`
- `../src/c47-dmcp/`
- `../src/c47-dmcp5/`
- `../subprojects/gmp-6.2.1`

The firmware helper also uses the checked-in linker scripts and HAL sources
from the imported upstream tree.

## Cross-GMP Bootstrap Contract

`../zig_build/firmware.zig` bootstraps an ARM-targeted GMP archive as part of
the Zig-owned build flow.

Current behavior:

- prefer the checked-in upstream source tree under `../subprojects/gmp-6.2.1`
- fall back to downloading a verified `gmp-6.2.1.tar.bz2` when the source tree
  is absent
- verify the tarball SHA-256 before use
- configure GMP for `arm-none-eabi`
- build it with retained Autoconf and Make tooling

This is still a retained C dependency build, not a Zig-native GMP rewrite.

## Distribution Surface

The distribution domain is owned by `../zig_build/dist.zig` plus the helper
script `../zig_build/zig_dist.py`.

Current package entrypoints:

- `dist`: current-host package plus all registered firmware archives
- `dist_linux`: Linux host package on Linux only
- `dist_macos`: macOS host package on macOS only
- `dist_windows`: Windows host package on Windows only
- `dist_dmcp`, `dist_dmcpr47`, `dist_dmcp5`, `dist_dmcp5r47`
- `dist_dmcp_pkg1`, `dist_dmcp_pkg2`, `dist_dmcp_pkg3`
- `dist_dmcp_pkgs_all`, `dist_dmcp_pkgs_1_2`, `dist_dmcp_pkgs_small`
- `distS`: alias for the aggregate Zig-owned distribution sequence

The distribution surface produces one host archive per supported desktop host
OS and one firmware archive per supported hardware or model combination.

## Host-Specific Packaging Notes

- `dist_linux`, `dist_macos`, and `dist_windows` fail explicitly on the wrong
  host OS.
- The host package lanes stage the same simulator binaries produced by the
  normal host build graph rather than compiling a separate dist-only host
  executable pair.
- On x86 and x86_64 hosts, `zig_build/common.zig` resolves the host package
  target with a baseline CPU model instead of inheriting runner-native CPU
  features, so Linux and Windows artifacts do not accidentally pick up BMI2 or
  other newer instructions from the machine that built them.
- The Windows package lane stages GTK runtime directories, runtime tools,
  launcher helpers, and import-checked DLLs in addition to the simulator
  executables.
- The Linux and macOS package lanes publish simulator bundles together with the
  checked-out `res/` assets and generated notice metadata.
- On Linux, the packaging helper strips the staged simulator copy before
  archiving it, so a freshly extracted `zig-out/dist/c47-linux.zip` package can
  differ in hash from `zig-out/bin/r47` while still carrying the same safe
  non-BMI2 code path.

## DMCP Package Control

The upstream `DMCP_PACKAGE` contract is exposed through the Zig option
`-Ddmcp-package=<n>` for the default `dmcp` and `dmcpr47` targets.

Examples:

- `zig build -Ddmcp-package=1 dmcp`
- `zig build -Ddmcp-package=2 dmcpr47`
- `zig build -Ddmcp-package=3 dist_dmcp`

Use the dedicated fixed-package steps when you want the package number encoded
in the step name instead of passed as an option.

## Change Rules

- Keep retained SDK, linker-script, CRC, and GMP dependencies explicit.
- Do not claim firmware parity without producing the actual firmware artifacts.
- Keep host-package behavior aligned with the workflow lanes that publish those
  artifacts.
- Update [60-ci-and-release-workflow.md](60-ci-and-release-workflow.md) and
  [70-tests-and-verification.md](70-tests-and-verification.md) when package
  names, artifact contents, or required verification lanes change.