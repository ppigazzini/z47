# Firmware And Distribution

This page defines the Zig-owned DMCP and DMCP5 firmware targets and the
host-package/distribution surface. Both replace the upstream Make and Meson
entrypoints. The firmware runs the ported Zig calculator core and a Zig HAL,
while still linking retained C: the SwissMicros DMCP/DMCP5 SDKs, the vendored
`dep/decNumberICU`, and a cross-built GMP.

Read [20-zig-build-graph.md](20-zig-build-graph.md) first. This page assumes the
build-domain split is already clear.

Audit basis: 2026-07-30, upstream pin `4697e526a`, Zig `0.16.0` stable.

The memory a firmware target actually has -- the arenas, which stack a running
program uses, what one nested engine level costs, and why a simulator run cannot
answer a DM42 question -- is upstream's subject, not the port's. The companion
c47-r47-ci doc set owns it in `docs/06-memory.md`; this page owns the build,
flash-budget and packaging side. See
[90-official-references.md](90-official-references.md).

## Firmware Surface At A Glance

Facts, verified from `../zig_build/firmware.zig`:

- Firmware targets are invoked through `zig build` (no Make or Meson).
- The firmware ELF links the ported Zig calculator core as native ARM objects,
  not upstream C. `addFirmwareElfBuild` asserts `core_sources.len == 0`: no
  upstream `src/c47` core `.c` file is compiled into the firmware. The linked
  Zig owner objects include `constants`, `shortint`, `frontier`, `solver`,
  `mathematics` (math command wrappers), `state` (calc-state, flags,
  keyboard-state, memory, program-serialization, register-metadata, stack), and
  `ui` (tone).
- The firmware HAL is ported to Zig and linked as three ARM objects built from
  `../zig_build/firmware_audio_runtime.zig`,
  `../zig_build/firmware_io_runtime.zig`, and
  `../zig_build/firmware_print_ir_runtime.zig`.
- Retained C still compiled into the firmware: the vendored
  `../dep/decNumberICU` sources, the SwissMicros SDK `pgm_syscalls.c` and
  `startup_pgm.s`, the generated constant-pointer and raster-font C, and a
  cross-built GMP archive (see below).
- The `-Izig_bridge` overlay is prepended ahead of the imported `../src/c47`
  include path so z47-specific header shims win over imported `defines.h`
  without editing the imported tree.
- Per-package flash trims are computed in the Zig frontier build
  (`frontierDistributionStrip` in `../zig_build/firmware.zig`) as build options
  that mirror the upstream `defines.h` `SAVE_SPACE_DM42_*` and `OPTION_*`
  package blocks, not by editing imported C.
- Package creation is still more than compilation: each firmware build also
  emits a QSPI image, a linker map, and a size report.

## Firmware Target Matrix

Verified from `registerSteps` in `../zig_build/firmware.zig`:

| Step | Board family | Model | Program extension | Notes |
| --- | --- | --- | --- | --- |
| `dmcp` | DMCP (DM42, OLD_HW) | C47 | `.pgm` | honors `-Ddmcp-package`, default `4` |
| `dmcpr47` | DMCP (DM42, OLD_HW) | R47 | `.pgm` | honors `-Ddmcp-package`, default `4`; built `-DCALCMODEL=USER_R47` |
| `dmcp5` | DMCP5 (NEW_HW) | C47 | `.pg5` | fixed board family, no DMCP package switch |
| `dmcp5r47` | DMCP5 (NEW_HW) | R47 | `.pg5` | fixed board family, no DMCP package switch |
| `dmcp_pkg1` | DMCP | C47 | `.pgm` | fixed package `1` |
| `dmcp_pkg2` | DMCP | C47 | `.pgm` | fixed package `2` |
| `dmcp_pkg3` | DMCP | C47 | `.pgm` | fixed package `3` |
| `dmcp_pkgs_all` | DMCP | C47 | mixed | grouped build of package variants 1, 2, and 3 |

Each firmware build produces these output classes:

- program image (`.pgm` or `.pg5`)
- QSPI image
- linker map file
- ELF section-size report (via `arm-none-eabi-readelf` and `tools/size.py`)

## Flash Budget And QSPI XIP

Fact: DMCP flash is tight. The per-package `SAVE_SPACE_DM42_*` strips exist
precisely because the DM42 packages must fit a bounded flash budget, and the DM42
family is compiled `OLD_HW` (static `freeMemoryRegions` array) while DMCP5 keeps
the newer pointer layout.

Decision and technique: heavy owner code is placed in QSPI and executed
in-place (XIP) rather than the main program flash. The firmware link discards
`.ARM.exidx` first (`../zig_build/firmware/discard_exidx.ld`, applied ahead of
the upstream board linker script) so QSPI-placed owner code does not blow the
PREL31 exidx relocation range. Treat DMCP flash headroom as a real constraint:
a change that grows an owner can overflow a package even when the host build and
tests stay green.

## Retained Toolchain And Dependency Stack

Firmware host-tool prerequisites (from the cross-GMP bootstrap and the ELF
build commands):

- `arm-none-eabi-gcc`
- `arm-none-eabi-objcopy`
- `arm-none-eabi-readelf`
- `arm-none-eabi-ar`, `arm-none-eabi-ranlib` (GMP cross-build)
- `python3`
- `tar`
- `make`
- native `cc` or `gcc` for the cross-GMP bootstrap

Retained C dependency inputs:

- `../dep/DMCP_SDK` and `../dep/DMCP5_SDK`: the SwissMicros hardware SDKs
  (SDK include dirs, `pgm_syscalls.c`, `startup_pgm.s`). These are git
  submodules; a fresh checkout needs `git submodule update --init` before
  `zig build dmcp` or `dmcp5` can link.
- `../dep/decNumberICU`: vendored decimal C, compiled by Zig into the firmware.
- `../src/c47-dmcp` and `../src/c47-dmcp5`: used as board include dirs and for
  the checked-in `stm32_program.ld` linker scripts. The upstream board HAL `.c`
  files are no longer compiled (`firmwareBoardHalSources` is empty for both
  boards); the HAL is the Zig runtime objects above.
- `../subprojects/gmp-6.2.1`: GMP source for the ARM cross-build.

## Cross-GMP Bootstrap Contract

`../zig_build/firmware.zig` bootstraps an ARM-targeted GMP archive as part of the
Zig-owned build flow. This is a retained C dependency build, not a Zig-native
GMP rewrite.

Current behavior (`addArmGmpBuild`):

- prefer the checked-in source tree under `../subprojects/gmp-6.2.1`
- fall back to downloading `gmp-6.2.1.tar.bz2` from a mirror list when the source
  tree is absent
- verify the tarball SHA-256 before use
- configure GMP for `arm-none-eabi` with per-board CPU flags (Cortex-M4 for
  DMCP, Cortex-M33 for DMCP5)
- build and install it with upstream Autoconf and Make
- feed the resulting `gmp.h` and `libgmp.a` into the firmware ELF link

## Distribution Surface

The distribution domain is owned by `../zig_build/dist.zig` plus the helper
script `../zig_build/zig_dist.py`.

Verified package entrypoints:

- `dist`: current-host package plus all registered firmware archives
- `dist_linux`, `dist_macos`, `dist_windows`: host package on the matching host
  OS only (each fails explicitly on the wrong OS)
- `dist_dmcp`, `dist_dmcpr47`, `dist_dmcp5`, `dist_dmcp5r47`: per-firmware
  archives (`c47-dmcp.zip`, `r47-dmcp.zip`, `c47-dmcp5.zip`, `r47-dmcp5.zip`)
- `dist_dmcp_pkg1`, `dist_dmcp_pkg2`, `dist_dmcp_pkg3`: per-package DMCP archives
  (`c47-dmcp-pkg<n>.zip`)
- `dist_dmcp_pkgs_all`: all three DMCP package-variant archives
- `dist_dmcp_pkgs_1_2`: DMCP package 1 and 2 archives
- `dist_dmcp_pkgs_small`: the smaller DMCP package 2 and 3 archives
- `distS`: alias that runs the aggregate `dist` sequence under Zig-only
  orchestration

The distribution surface produces one host archive per supported desktop host OS
and one firmware archive per supported hardware or model combination.

The local `zig build dist_*` steps emit these zip names under `zig-out/dist/`.
The Linux CI lane uploads the C47 SwissMicros firmware zip outputs as a separate
firmware artifact while keeping those checked-in build-surface names unchanged.

## Host-Specific Packaging Notes

- `dist_linux`, `dist_macos`, and `dist_windows` fail explicitly on the wrong
  host OS.
- The host package lanes stage the same simulator binaries produced by the host
  build graph rather than compiling a separate dist-only host executable pair.
- The published desktop host artifacts use `ReleaseFast` simulator binaries:
  Linux via `zig build -Doptimize=ReleaseFast dist_linux`, and the macOS and
  Windows workflow lanes rebuild `both` with `-Doptimize=ReleaseFast` before
  smoke and staging.
- On x86 and x86_64 hosts, `../zig_build/common.zig` resolves the host package
  target with a baseline CPU model instead of inheriting runner-native CPU
  features, so Linux and Windows artifacts do not accidentally pick up BMI2 or
  other newer instructions from the machine that built them.
- The Windows package lane stages GTK runtime directories, runtime tools,
  launcher helpers, and import-checked DLLs in addition to the simulator
  executables.
- The Linux and macOS package lanes publish ReleaseFast simulator bundles
  together with the checked-out `res/` assets and generated notice metadata.
- The Linux CI lane also uploads a separate firmware artifact containing the C47
  SwissMicros package zips produced by `dist_dmcp`, `dist_dmcp_pkg1`,
  `dist_dmcp_pkg2`, `dist_dmcp_pkg3`, and `dist_dmcp5`.
- On Linux and macOS, the packaging helper strips both staged simulator copies
  before archiving them, so a freshly extracted desktop host package can differ
  in hash from `zig-out/bin/c47` or `zig-out/bin/r47` while still carrying the
  same safe non-BMI2 code path.

## DMCP Package Control

The upstream `DMCP_PACKAGE` contract is exposed through the Zig option
`-Ddmcp-package=<n>` for the default `dmcp` and `dmcpr47` targets (default `4`).

Examples:

- `zig build -Ddmcp-package=1 dmcp`
- `zig build -Ddmcp-package=2 dmcpr47`
- `zig build dist_dmcp_pkg3`

Use the dedicated fixed-package steps (`dmcp_pkg1/2/3`, `dist_dmcp_pkg1/2/3`)
when you want the package number encoded in the step name instead of passed as
an option.

The Linux CI firmware artifact keeps the default C47 DMCP package from
`dist_dmcp` and uses `dist_dmcp_pkg1`, `dist_dmcp_pkg2`, and `dist_dmcp_pkg3` so
each smaller package variant is preserved instead of overwritten.

When a legacy-state, keyboard-helper, or package-trim change must stay safe on
old hardware, rerun `zig build dist_dmcp_pkg3 --summary none`; rerun
`zig build dist_dmcp_pkg2 --summary none` as well when the change touches the
package-2-only overlay trims.

## Change Rules

- Fix shared firmware behavior in the Zig owners under `../zig_src/` or the Zig
  HAL under `../zig_build/firmware_*_runtime.zig`, never in the imported upstream
  tree (which is the parity oracle).
- Keep the retained SDK, decNumberICU, linker-script, CRC, and GMP dependencies
  explicit in docs and review. Do not imply a pure-Zig firmware while the build
  still compiles decNumberICU or links the SDKs and GMP.
- Do not claim firmware parity without producing the actual firmware artifacts.
- Keep host-package behavior aligned with the workflow lanes that publish those
  artifacts.
- Update [60-ci-and-release-workflow.md](60-ci-and-release-workflow.md) and
  [70-tests-and-verification.md](70-tests-and-verification.md) when package
  names, artifact contents, or required verification lanes change. See
  [50-zig-c-boundaries-and-rewrite-policy.md](50-zig-c-boundaries-and-rewrite-policy.md)
  before changing any retained-C boundary in the firmware link.
