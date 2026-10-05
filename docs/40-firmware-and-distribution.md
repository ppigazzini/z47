# Firmware And Distribution

This page defines the Zig-owned DMCP and DMCP5 firmware targets and the
host-package/distribution surface. Both replace the upstream Make and Meson
entrypoints. The firmware runs the ported Zig calculator core and a Zig HAL,
while still linking retained C: the SwissMicros DMCP/DMCP5 SDKs, the vendored
`../upstream/dep/decNumberICU`, and a cross-built GMP.

Read [20-zig-build-graph.md](20-zig-build-graph.md) first. This page assumes the
build-domain split is already clear.

Last verified: 2026-10-05, Zig `0.17.0` stable. The upstream pin is
`UPSTREAM_COMMIT` in `../.github/project/upstream-pin.env`.

The memory a firmware target actually has -- the arenas, which stack a running
program uses, what one nested engine level costs, and why a simulator run cannot
answer a DM42 question -- is upstream's subject, not the port's. The companion
c47-r47-ci doc set owns it in `docs/06-memory.md`; this page owns the build,
flash-budget and packaging side. See
[90-official-references.md](90-official-references.md).

## Firmware Surface At A Glance

Facts, verified from `../build/firmware.zig`:

- Firmware targets are invoked through `zig build` (no Make or Meson).
- The firmware ELF links the ported Zig calculator core as native ARM objects,
  not upstream C. `addFirmwareElfBuild` asserts `core_sources.len == 0`: no
  upstream `src/c47` core `.c` file is compiled into the firmware. The linked
  Zig owner objects include `constants`, `shortint`, `frontier`, `solver`,
  `mathematics` (math command wrappers), `state` (calc-state, flags,
  keyboard-state, memory, program-serialization, register-metadata, stack), and
  `ui` (tone).
- The firmware HAL is ported to Zig and linked as three separately-built ARM
  objects, from
  `../build/firmware_audio_runtime.zig`,
  `../build/firmware_io_runtime.zig`, and
  `../build/firmware_print_ir_runtime.zig`. A fourth HAL owner,
  `../build/firmware_console_runtime.zig`, is carried into the link by the io
  object rather than built separately: it defines the console entry points that
  DMCP hardware does not have, which is what keeps newlib's buffered stdio -- and
  the `FILE` array `findfp.o` would place in SRAM2 -- out of the image.
- Retained C still compiled into the firmware: the vendored
  `../upstream/dep/decNumberICU` sources, the SwissMicros SDK `pgm_syscalls.c` and
  `startup_pgm.s`, the generated constant-pointer and raster-font C, and a
  cross-built GMP archive (see below).
- The `-Ibridge` overlay is prepended ahead of the imported `../upstream/src/c47`
  include path. `../bridge/c47.h` `#include_next`s upstream's `c47.h` and then
  adjusts macros; in the firmware link it reaches only the generated
  `rasterFontsData.c`, `constantPointers.c` and `constantPointers2.c`. Owners take
  `OPTION_*` from their build options, not from this header.
- Per-package and DM42-board `OPTION_*` values are computed in
  `../build/firmware.zig` (`frontierDistributionStrip`,
  `mathematicsPackageOptions`, `solverPackageOptions`, `calcStateBoardOptions`,
  and inline values for keyboard-state and program-serialization) as build
  options that mirror the upstream `defines.h` blocks, not by editing imported
  C. Read the option names out of `defines.h` rather than from prose:
  upstream renames them, and the `SAVE_SPACE_DM42_*` family they replaced is gone.
- Package creation is still more than compilation: each firmware build also
  emits a QSPI image, a linker map, and a size report.

## Firmware Target Matrix

Verified from `registerSteps` in `../build/firmware.zig`:

| Step | Board family | Model | Program extension | Notes |
| --- | --- | --- | --- | --- |
| `dmcp` | DMCP (DM42, OLD_HW) | C47 | `.pgm` | honors `-Ddmcp-package`, default `4` |
| `dmcpr47` | DMCP (DM42, OLD_HW) | R47 | `.pgm` | honors `-Ddmcp-package`, default `4`; built `-DCALCMODEL=USER_R47` |
| `dmcp5` | DMCP5 (NEW_HW) | C47 | `.pg5` | fixed board family, no DMCP package switch |
| `dmcp5r47` | DMCP5 (NEW_HW) | R47 | `.pg5` | fixed board family, no DMCP package switch |
| `dmcp_pkg1` | DMCP | C47 | `.pgm` | fixed package `1` |
| `dmcp_pkg2` | DMCP | C47 | `.pgm` | fixed package `2` |
| `dmcp_pkg3` | DMCP | C47 | `.pgm` | fixed package `3` |
| `dmcp_pkgs_all` | DMCP | C47 | `.pgm` | grouped build of package variants 1, 2, and 3 |

Each firmware build produces these output classes:

- program image (`.pgm` or `.pg5`)
- QSPI image
- linker map file
- ELF section-size report (via `arm-none-eabi-readelf` and `../build/tools/size.py`)

## Flash Budget And QSPI XIP

Fact: DMCP flash is tight. The per-package `OPTION_*` strips exist
precisely because the DM42 packages must fit a bounded flash budget, and the DM42
family is compiled `OLD_HW` (static `freeMemoryRegions` array) while DMCP5 keeps
the newer pointer layout.

Decision and technique: heavy owner code is placed in QSPI and executed
in-place (XIP) rather than the main program flash. The firmware link discards
`.ARM.exidx` first (`../build/firmware/discard_exidx.ld`, applied ahead of
the upstream board linker script) so QSPI-placed owner code does not blow the
PREL31 exidx relocation range. Treat DMCP flash headroom as a real constraint:
a change that grows an owner can overflow a package even when the host build and
tests stay green.

The DM42 RAM budget is just as tight. Every DM42 link asserts
`_ebss <= 0x10002000` (`../upstream/src/c47-dmcp/stm32_program.ld`), and the
link's `ram` row prints the headroom that is left. Any new firmware-linked static
data spends it, and because the package variants strip different code, one
variant's link can fail while `dmcp` and `dmcp5` still link. Link every variant:
`zig build dmcp_pkgs_all` (the local gate runs it as step 10b), plus `dmcp`,
`dmcpr47`, `dmcp5` and `dmcp5r47`.

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
- `curl` or `wget`, to download the GMP 6.2.1 tarball

Retained C dependency inputs:

- `../upstream/dep/DMCP_SDK` and `../upstream/dep/DMCP5_SDK`: the SwissMicros hardware SDKs
  (SDK include dirs, `pgm_syscalls.c`, `startup_pgm.s`). These are git
  submodules; a fresh checkout needs `git submodule update --init` before
  `zig build dmcp` or `dmcp5` can link.
- `../upstream/dep/decNumberICU`: vendored decimal C, compiled by
  `arm-none-eabi-gcc` in the firmware link.
- `../upstream/src/c47-dmcp` and `../upstream/src/c47-dmcp5`: used as board include dirs and for
  the checked-in `stm32_program.ld` linker scripts. The upstream board HAL `.c`
  files are no longer compiled (`firmwareBoardHalSources` is empty for both
  boards); the HAL is the Zig runtime objects above.
- `../upstream/subprojects/gmp-6.2.1.wrap`: names the GMP 6.2.1 tarball and its
  SHA-256. A `gmp-6.2.1/` source tree beside it is used when present; it is
  gitignored, so a fresh clone has none.
- `../upstream/dep/forcecrc32.c`, compiled by Zig as the host CRC tool, and the
  `../upstream/tools/modify_crc`, `gen_qspi_crc` and `add_pgm_chsum` scripts that
  stamp the program and QSPI images.

## Cross-GMP Bootstrap Contract

`../build/firmware.zig` bootstraps an ARM-targeted GMP archive as part of the
Zig-owned build flow. This is a retained C dependency build, not a Zig-native
GMP rewrite.

Current behavior (`addArmGmpBuild`):

- use an unpacked tree at `../upstream/subprojects/gmp-6.2.1` when present
- otherwise (always, on a fresh clone) download `gmp-6.2.1.tar.bz2` from a mirror
  list
- verify the tarball SHA-256 before use
- configure GMP for `arm-none-eabi` with per-board CPU flags (Cortex-M4 for
  DMCP, Cortex-M33 for DMCP5)
- build and install it with upstream Autoconf and Make
- feed the resulting `gmp.h` and `libgmp.a` into the firmware ELF link

## Distribution Surface

The distribution domain is owned by `../build/dist.zig` plus the helper
script `../build/zig_dist.py`.

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
- The published desktop host artifacts use simulator binaries built with
  `-Doptimize=fast`: Linux via `zig build -Doptimize=fast dist_linux`, and the
  macOS and Windows workflow lanes rebuild `both` with `-Doptimize=fast` before
  smoke and staging.
- On x86 and x86_64 hosts, `../build/common.zig` resolves the host package
  target with a baseline CPU model instead of inheriting runner-native CPU
  features, so Linux and Windows artifacts do not accidentally pick up BMI2 or
  other newer instructions from the machine that built them.
- The Windows package lane stages GTK runtime directories, runtime tools,
  launcher helpers, and import-checked DLLs in addition to the simulator
  executables.
- The Linux and macOS package lanes publish `-Doptimize=fast` simulator bundles
  together with the checked-out `../upstream/res/` assets and generated notice
  metadata.
- The Linux CI lane also uploads a separate firmware artifact containing the C47
  SwissMicros package zips produced by `dist_dmcp`, `dist_dmcp_pkg1`,
  `dist_dmcp_pkg2`, `dist_dmcp_pkg3`, and `dist_dmcp5`.
- `dist_linux` and `dist_macos` strip both staged simulator copies before
  archiving them (`../build/zig_dist.py`), so an extracted Linux package can
  differ in hash from `zig-out/bin/c47` or `zig-out/bin/r47` while carrying the
  same non-BMI2 code path. The published macOS artifact is staged by the workflow
  straight from `zig-out/bin` and is not stripped.

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

After any change that reaches a firmware-linked owner, link every package
variant: `zig build dmcp_pkgs_all --summary none` (the local gate runs exactly
this), plus `dmcp`, `dmcpr47`, `dmcp5` and `dmcp5r47`.

### How An `OPTION_*` Value Is Established

Upstream's `OPTION_*` macros in `upstream/src/c47/defines.h` are **include**
flags. Defined means the feature is compiled in; the macro's *absence* is what
turns the guarded function bodies into empty stubs. A feature is therefore
removed from a package by an `#undef`, not by a `#define`.

`defines.h` settles each option in layers, in this order:

1. a default block that defines or undefines the option for every build;
2. the `DMCP_PACKAGE1..3` / `DMCP_PACKAGE4_NOOPT` block for the selected package;
3. a block common to hardware packages 1-4 that runs **after** the per-package
   blocks and overrides them;
4. dependency fixups after `#endif // DMCP_BUILD`, each an `#if !defined(...)`
   block that undefines an option whose prerequisite is absent (for example
   `OPTION_FACTOR` without `OPTION_PRIME`, and `OPTION_SLVP_POLY` and
   `OPTION_EIGEN_159` without `OPTION_EIGEN`); read the full list there.

Two consequences follow, and both have produced port defects:

- **The per-package block does not give the answer.** An option a package block
  defines can be undefined again by the common block below it. `OPTION_VECTOR`,
  `OPTION_XFN_1000` and the `*_159` family are settled that way for every DM42
  package.
- **The `check` and `ballot-box` markers in the comments do not track the
  resulting state.** They annotate the intent of individual lines, and reading
  them as the per-package matrix inverts it.

Derive the value instead, by preprocessing `defines.h` in the configuration you
are asking about: `-DPC_BUILD` for host, `-DDMCP_BUILD -DNEW_HW` for DMCP5, and
`-DDMCP_BUILD -DOLD_HW -DTWO_FILE_PGM -DDMCP_PACKAGE=<n>` for a DM42 package.

z47 records the derived value in the build -- the option sets in
`../build/frontier/frontier.zig`, `../build/mathematics/math_command_wrappers.zig`,
`../build/solver/solve.zig`, `../build/state/calc_state.zig`,
`../build/state/keyboard_state.zig` and `../build/state/program_serialization.zig`,
assigned per board and package in `../build/firmware.zig` -- and an owner reads it
from the
build-options module it imports. An owner must not re-derive an option from
`old_hw`, from the target OS tag, or from a package-name proxy: none of those is
the same predicate as the macro, so the owner and the build then disagree about
what the firmware contains. Which conditionals an owner may carry is ratcheted by
[check-owner-build-conditionals.py](../.github/project/check-owner-build-conditionals.py).

## Change Rules

- Fix shared firmware behavior in the Zig owners under `../src/` or the Zig
  HAL under `../build/firmware_*_runtime.zig`, never in the imported upstream
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
