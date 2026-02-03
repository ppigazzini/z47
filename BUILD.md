# Build Targets

## Simulator Builds
```
make              - Build c47 simulator (default)
make all          - Build c47 simulator (default)
make sim          - Build c47 simulator
make simr47       - Build r47 simulator
make both         - Build both c47 and r47 simulators
make both_asan    - Build both simulators with AddressSanitizer (memory debugging)
```

## Hardware Builds
```
make dmcp         - Build c47 for DM42 (DMCP)
make dmcpr47      - Build r47 for DM42 (DMCP)
make dmcp5        - Build c47 for DM42n (DMCP5)
make dmcp5r47     - Build r47 for R47 (DMCP5)
```

## Testing & Documentation
```
make test         - Run test suite (cleans first to ensure no ASAN contamination)
make testPgms     - Generate test programs
make docs         - Build documentation
```

## Distribution Packages
```
make dist_windows - Create Windows distribution package
make dist_macos   - Create macOS distribution package
make dist_linux   - Create Linux distribution package
make dist_dmcp    - Create DM42 (DMCP) distribution package
make dist_dmcp5   - Create DM42n (DMCP5) distribution package
make dist_dmcp5r47- Create R47 (DMCP5) distribution package
```

## Utilities
```
make clean        - Remove all build artifacts and generated files
```

## ASAN Debugging
`make both_asan` automatically cleans before building to ensure ASAN is properly enabled.
A colored banner will appear if ASAN fails to activate.
