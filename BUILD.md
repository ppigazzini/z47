# Build Targets

## Simulator Builds
```
make                        - Build c47 simulator (default)
make all                    - Build c47 simulator (default)
make sim                    - Build c47 simulator
make simc47                 - Build c47 simulator (alias for make sim)
make simr47                 - Build r47 simulator
make both                   - Build both c47 and r47 simulators
make both_asan              - Build both simulators with AddressSanitizer (memory debugging)
```

## T47 Variant Builds
Append `t47` to a `sim`/`simc47`/`simr47`/`both` goal to build into build.sim.t47 with T47 defined. The built binary is also copied to ./t47. Does not apply to `both_asan`.
```
make t47                    - Build r47 simulator with T47 defined (alias for make simr47 t47)
make sim t47                - Build c47 simulator with T47 defined
make simc47 t47             - Build c47 simulator with T47 defined
make simr47 t47             - Build r47 simulator with T47 defined
make both t47               - Build both with T47 defined; ./t47 ends up the r47 build (simr47 copy runs last)
```

## Hardware Builds
```
make dmcp                   - Build c47 for DM42  (DMCP) using current DMCP_PACKAGE (default 4)
make dmcpr47                - Build r47 for DM42  (DMCP)
make dmcp5                  - Build c47 for DM42n (DMCP5)
make dmcp5r47               - Build r47 for R47   (DMCP5)
make dmcp f=1               - Fast c47 DMCP build, reuse build dir, skip GMP rebuild (example only, f=1 can be applied to any build in this block)
```

## Testing & Documentation
```
make test                   - Run test suite (cleans first to ensure no ASAN contamination)
make repeattest             - Run test suite incrementally (only rebuilds program if sources changed)
make test_asan              - Run test suite with AddressSanitizer enabled
make testPgms               - Generate test programs
make docs                   - Build documentation
```

## Distribution Packages
```
make dist_macos             - Create macOS distribution package
make dist_windows           - Create Windows distribution package
make dist_linux             - Create Linux distribution package
make dist_dmcp              - Create DM42 (DMCP) distribution package
make dist_dmcpr47           - Create DM42 (DMCP) r47 distribution package
make dist_dmcp5             - Create DM42n (DMCP5) distribution package
make dist_dmcp5r47          - Create R47 (DMCP5) distribution package
make dist_dmcp5 f=1         - Fast DMCP5 dist package, reuse build dir, skip GMP rebuild (example only, f=1 can be applied to any build in this block)

make DMCP_PACKAGE=1 dist_dmcp  - Create DM42 (DMCP) distribution package for feature set PACKAGE1_NOBESSEL_NOORTHO
make DMCP_PACKAGE=2 dist_dmcp  - Create DM42 (DMCP) distribution package for feature set PACKAGE2_NODISTR
make DMCP_PACKAGE=3 dist_dmcp  - Create DM42 (DMCP) distribution package for feature set PACKAGE3_NOBESSEL_NOORTHO_NOFBR
```

## Utilities
```
make clean                  - Remove all build artifacts and generated files
dist                        - Sequences all compiles and packages on Mac (modify script locally for dist_windows or dist_linux)
distS                       - Runs dist, with a pipe to display used/remaining space on all dmcp versions
```

## ASAN Debugging
- `make both_asan` automatically cleans before building to ensure ASAN is properly enabled.
- After using ASAN (both_asan), further simulator compiles will probably remain with ASAN installed. Use make clean after use.
- A colored banner will appear if ASAN fails to activate.


## Compiling for hardware tips
- For all commits after 728d36d (2025-12-12) will compile automatically wrt GMP. For commits before that, starting at df76632 (2025-12-09) going back in time, you need to manually delete subprojects/gmp-6.2.1 directory manually prior to hardware compile.
- Hardware and dist builds wipe the build directory and reconfigure each time by default, so GMP is cross-compiled from scratch on every build. Append `f=1` (e.g. `make dmcp f=1`, `make dist_dmcp5 f=1`) to reuse the existing build directory and skip the GMP rebuild. The first build of a directory still pays the GMP cross-compile, every `f=1` build after that reuses it. Reach for `f=1` during active development, drop it for a guaranteed clean build. Note `make clean` wipes all the build.dmcp* directories and subprojects/gmp-6.2.1, so the next build pays the full GMP cost regardless of `f=1`.
- Options: By default a hardware build wipes its build directory and reconfigures from scratch, which rebuilds GMP. Append `f=1` to any hardware or dist target to reuse the existing build directory and skip the GMP rebuild for a fast incremental build. Drop `f=1` when you want the clean rebuild. `f=1` works on `dmcp`, `dmcpr47`, `dmcp5`, `dmcp5r47` and all the `dist_dmcp*` targets.

