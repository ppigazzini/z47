# Zig Build Guide

`build.zig` is the canonical z47 build entrypoint.

Use `zig build ...` for simulator builds, tests, docs, firmware, and
distribution packaging. The imported `Makefile` and Meson files remain audit
surfaces, not the maintained z47 control plane.

## Pinned Toolchain

- Zig version: `0.16.0`
- This repo pins the toolchain in `.github/zig-toolchain.env`

## Output Locations

- host simulator installs: `zig-out/bin/`
- docs HTML output: `zig-out/docs/code/html/`
- firmware installs: `zig-out/firmware/<target>/`
- distribution archives: `zig-out/dist/`

## Helper Layout

- `build.zig` is now the small root entrypoint that parses options and wires
  the build domains together
- `zig_build/common.zig` owns shared source lists, C flag tables, and common
  build helpers
- `zig_build/host.zig` is the stable facade consumed by `build.zig`,
  `zig_build/dist.zig`, and `zig_build/firmware.zig`
- `zig_build/host/types.zig` owns the shared host-side data structures
- `zig_build/host/context.zig` owns host context creation
- `zig_build/host/generated.zig` owns version-header and generator output setup
- `zig_build/host/builders.zig` owns simulator and host test executable builders
- `zig_build/host/steps.zig` owns host step registration plus docs and clean
- `zig_build/host/platform.zig` owns GTK, FreeType, Windows pkg-config, and
  system path glue
- `zig_build/firmware.zig` owns `forcecrc32`, the cross-GMP bootstrap,
  firmware build orchestration, and the DMCP package matrix
- `zig_build/dist.zig` owns distribution-step registration and packaging
- `zig_build/zig_dist.py` is the z47-owned packaging helper used by the Zig
  distribution steps
- `tag2ver.py` intentionally remains at the repo root because the imported
  `meson.build` still calls it directly

## Host Prerequisites

Host simulator, generator, test, and host-package builds depend on:

- `pkg-config`
- GTK 3 development files
- FreeType 2 development files
- GMP development files
- optional PulseAudio development files for audio support
- `python3`

Generator-dependent host builds also need the xlsxio helper available at
runtime.

- expected helper on `PATH`: `xlsxio_xlsx2csv`
- expected shared library visibility: `libxlsxio_read` via the platform loader
  path (`LD_LIBRARY_PATH` on Linux or the platform equivalent)

## Documentation Prerequisites

`zig build docs` requires all of:

- `python3`
- `doxygen`
- Python packages from `docs/code/requirements.txt`
  (`sphinx`, `breathe`, and `furo`)

## Firmware Prerequisites

The DMCP and DMCP5 targets are Zig-owned, but they still retain the upstream C,
SDK, and cross-GMP dependency stack.

Required tools:

- `arm-none-eabi-gcc`
- `arm-none-eabi-objcopy`
- `arm-none-eabi-readelf`
- `python3`
- `tar`
- `make`
- native `cc` or `gcc` for the GMP bootstrap

Notes:

- the firmware helper resolves SDK assets from `dep/DMCP_SDK` and
  `dep/DMCP5_SDK`
- the firmware helper uses the SDK startup and syscall sources from the
  `dep/DMCP*_SDK/dmcp/` trees, the project linker scripts from
  `src/c47-dmcp*/stm32_program.ld`, and the board HAL sources from
  `src/c47-dmcp*/hal/`
- the cross-GMP archive is bootstrapped from upstream GMP sources inside the
  Zig-owned step; that retained bootstrap still uses upstream Autoconf and Make
  internally

## Core Commands

Simulator and tests:

```sh
zig build sim
zig build simr47
zig build both
zig build both_asan
zig build test
zig build repeattest
zig build test_asan
```

Generated artifacts:

```sh
zig build fonts
zig build constants
zig build catalogs
zig build testPgms
zig build generated
```

Documentation:

```sh
zig build docs
```

Firmware:

```sh
zig build dmcp
zig build dmcpr47
zig build dmcp5
zig build dmcp5r47

zig build dmcp_pkg1
zig build dmcp_pkg2
zig build dmcp_pkg3
zig build dmcp_pkgs_all
```

Distribution archives:

```sh
zig build dist_linux
zig build dist_macos
zig build dist_windows

zig build dist_dmcp
zig build dist_dmcpr47
zig build dist_dmcp5
zig build dist_dmcp5r47

zig build dist_dmcp_pkg1
zig build dist_dmcp_pkg2
zig build dist_dmcp_pkg3
zig build dist_dmcp_pkgs_all
zig build dist_dmcp_pkgs_1_2
zig build dist_dmcp_pkgs_small

zig build dist
zig build distS
```

Cleanup:

```sh
zig build clean
```

## Package Notes

- `dist_linux` is meant to run on Linux hosts
- `dist_macos` is meant to run on macOS hosts
- `dist_windows` is meant to run on Windows hosts
- those host-specific steps fail explicitly on the wrong host OS
- `dist` builds the current-host archive plus all registered firmware archives
- `distS` aliases the same Zig-owned aggregate package sequence

## DMCP Package Variants

The upstream `DMCP_PACKAGE` contract is exposed as the Zig option
`-Ddmcp-package=<n>` for the default `dmcp` and `dmcpr47` targets.

Examples:

```sh
zig build -Ddmcp-package=1 dmcp
zig build -Ddmcp-package=2 dmcpr47
zig build -Ddmcp-package=3 dist_dmcp
```

The dedicated fixed-package targets are:

- `dmcp_pkg1`
- `dmcp_pkg2`
- `dmcp_pkg3`
- `dist_dmcp_pkg1`
- `dist_dmcp_pkg2`
- `dist_dmcp_pkg3`

## Validated In This Iteration

Verified locally:

- `zig build --help --summary none`
- `zig build dist_linux --summary none`
- `zig build test --summary none`
  - `9530` tests passed and `0` failed
- `zig build dmcp --summary none`
- `zig build dmcp5 --summary none`
  - both passed after restoring the firmware SDK, HAL, and linker-script path
    helpers to the checked-in project layout

Validation note:

- the commands had to run outside the VS Code terminal sandbox because the
  sandbox wrapper failed before command execution with an invalid
  `network.allowedDomains` setting and `ReadOnlyFileSystem`