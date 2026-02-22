# Build Targets

## Simulator Builds
```
make                        - Build c47 simulator (default)
make all                    - Build c47 simulator (default)
make sim                    - Build c47 simulator
make simr47                 - Build r47 simulator
make both                   - Build both c47 and r47 simulators
make both_asan              - Build both simulators with AddressSanitizer (memory debugging)
```

## Hardware Builds
```
make dmcp                   - Build c47 for DM42 (DMCP)
make dmcpr47                - Build r47 for DM42 (DMCP)
make dmcp5                  - Build c47 for DM42n (DMCP5)
make dmcp5r47               - Build r47 for R47 (DMCP5)
```

## Testing & Documentation
```
make test                   - Run test suite (cleans first to ensure no ASAN contamination)
make repeattest             - Run test suite incrementally (only rebuilds program if sources changed)
make testPgms               - Generate test programs
make docs                   - Build documentation
```

## Distribution Packages
```
make dist_windows           - Create Windows distribution package
make dist_macos             - Create macOS distribution package
make dist_linux             - Create Linux distribution package
make dist_dmcp5             - Create DM42n (DMCP5) distribution package
make dist_dmcp5r47          - Create R47 (DMCP5) distribution package

make dist_dmcp              - Create DM42 (DMCP) distribution package (builds BOTH package 1 and 2, producing two separate zip files). (Temporarily removed package 1 from this automatic release compilation on gitlab, due the size exceedance on the gitlab compiler).
make dist_dmcp_pkg1         - Create DM42 (DMCP) distribution package for feature set PACKAGE1 (produces c47-dmcp-pkg1.zip)
make dist_dmcp_pkg2         - Create DM42 (DMCP) distribution package for feature set PACKAGE2 (produces c47-dmcp-pkg2.zip)

make DMCP_PACKAGE=1 dmcp    - Build c47 for DM42 (DMCP) using feature set PACKAGE1_NOBESSEL_NOORTHO
make DMCP_PACKAGE=2 dmcp    - Build c47 for DM42 (DMCP) using feature set PACKAGE2_NODISTR
make DMCP_PACKAGE=3 dmcp    - Build c47 for DM42 (DMCP) using feature set PACKAGE3_NOBESSEL_NOORTHO_NOFBR
```

## Utilities
```
make clean                  - Remove all build artifacts and generated files
```

## ASAN Debugging
- `make both_asan` automatically cleans before building to ensure ASAN is properly enabled.
- After using ASAN (both_asan), further simulator compiles will probably remain with ASAN installed. Use make clean after use.
- A colored banner will appear if ASAN fails to activate.


## Compiling for hardware tips
- For all commits after 728d36d (2025-12-12) will compile automatically wrt GMP. For commits before that, starting at df76632 (2025-12-09) going back in time, you need to manually delete subprojects/gmp-6.2.1 directory manually prior to hardware compile.

