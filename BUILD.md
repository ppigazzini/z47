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
make dmcp                   - Build c47 for DM42  (DMCP) using current DMCP_PACKAGE (default 4)
make dmcpr47                - Build r47 for DM42  (DMCP)
make dmcp5                  - Build c47 for DM42n (DMCP5)
make dmcp5r47               - Build r47 for R47   (DMCP5)
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
make dist_dmcp              - Create DM42 (DMCP) distribution package
make dist_dmcpr47           - Create DM42 (DMCP) r47 distribution package
make dist_dmcp5             - Create DM42n (DMCP5) distribution package
make dist_dmcp5r47          - Create R47 (DMCP5) distribution package

make DMCP_PACKAGE=1 dist_dmcp  - Create DM42 (DMCP) distribution package for feature set PACKAGE1_NOBESSEL_NOORTHO
make DMCP_PACKAGE=2 dist_dmcp  - Create DM42 (DMCP) distribution package for feature set PACKAGE2_NODISTR
make DMCP_PACKAGE=3 dist_dmcp  - Create DM42 (DMCP) distribution package for feature set PACKAGE3_NOBESSEL_NOORTHO_NOFBR
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

