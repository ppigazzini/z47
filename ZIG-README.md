# Zig Build Guide

`build.zig` is the canonical z47 control plane.

Use `zig build ...` for simulator builds, tests, docs, firmware, and package
assembly. The imported `Makefile`, Meson files, Ninja files, and CMake calls
remain upstream audit inputs; they are no longer the maintained z47 entrypoint.

## Pinned Toolchain

- Zig version: `0.16.0`
- This repo pins the toolchain in `.github/zig-toolchain.env`
- Local validation in this iteration used `/home/usr00/.zig/zig-x86_64-linux-0.16.0/zig`

## Output Locations

- Host simulator installs: `zig-out/bin/`
- Docs HTML output: `zig-out/docs/code/html/`
- Firmware installs: `zig-out/firmware/<target>/`
- Distribution archives: `zig-out/dist/`

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

If any of those are missing, the Zig step now fails immediately with the
missing requirement instead of routing through Make or Meson.

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

Notes:

- the firmware path now fails early with `missing required firmware tool: ...`
  when the ARM toolchain is absent
- the cross GMP archive is bootstrapped from upstream GMP sources inside the
  Zig-owned step; that retained third-party bootstrap still uses upstream
  Autoconf and Make internally
- if `subprojects/gmp-6.2.1/` is absent, the build step fetches the GMP 6.2.1
  tarball, verifies its SHA-256, and extracts it into the Zig cache

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
- those host-specific steps now fail explicitly on the wrong host OS instead of
  silently delegating to upstream scripts
- `dist` builds the current-host simulator archive plus all DMCP and DMCP5
  firmware archives
- `distS` currently aliases the same Zig-owned aggregate package sequence

## DMCP Package Variants

The upstream `DMCP_PACKAGE` contract is exposed as the Zig option
`-Ddmcp-package=<n>` for the default `dmcp` and `dmcpr47` targets.

Examples:

```sh
zig build -Ddmcp-package=1 dmcp
zig build -Ddmcp-package=2 dmcpr47
zig build -Ddmcp-package=3 dist_dmcp
```

The dedicated archive helpers also exist as fixed targets:

- `dist_dmcp_pkg1`
- `dist_dmcp_pkg2`
- `dist_dmcp_pkg3`

## Validated In This Iteration

Verified locally:

- `zig build both_asan --summary all`
- `zig build test_asan --summary all`
- `zig build dist_linux --summary all`

Blocked locally by missing host tools:

- `zig build docs` because `doxygen` was not installed
- `zig build dmcp` because `arm-none-eabi-gcc` was not installed

That means the host packaging path is validated on Linux, while docs and
firmware remain environment-blocked in this workspace rather than graph-blocked.
