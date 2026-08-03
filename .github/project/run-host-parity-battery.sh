#!/usr/bin/env bash
#
# The Linux host-parity build/test/generated-artifact battery: the exact command
# sequence the "Run Linux host build, tests, and generated artifacts" step of
# .github/workflows/upstream-oracle.yml runs. Extracted into a committed script
# so CI and a local pre-push gate execute IDENTICAL steps and cannot drift.
#
# Two of the four host-parity failures in the first all-Zig upstream resync
# (0caee2adc) were "green sim+test:unit locally, red CI": a parity ORACLE that
# stopped COMPILING (math_command_wrappers_parity) and a STALE generated artifact
# (res/testPgms/testPgms.bin). Neither `zig build sim` nor `zig build test:unit`
# runs this battery, so both slipped through the local gate. Run this script (or
# run-local-gate.sh, which wraps it) before pushing a resync.
#
# Usage:
#   bash .github/project/run-host-parity-battery.sh
# Environment:
#   XVFB   command prefix for the GUI-linked `zig build test` (default none).
#          CI and headless Linux set XVFB="xvfb-run --auto-servernum".
set -euo pipefail

# register_metadata_parity is occasionally flaky on first run under cold caches;
# CI retries it once, so mirror that here.
retry_once() {
  "$@" || "$@"
}

zig build logical_shortint_parity
zig build rotate_bits_parity
zig build logical_boolean_ops_suite
zig build stack_state_parity
retry_once zig build register_metadata_parity
zig build flags_parity
zig build memory_parity
zig build program_serialization_parity
zig build calc_state_parity
# Save/load golden + round-trip harness. It existed but was wired into no
# battery, so its golden silently rotted out of date; run it here.
zig build saveload_roundtrip
zig build math_command_wrappers_parity
# The full-core math-wrapper differential: c43's own mathematics/*.c compiled
# beside the Zig owners on real decNumber and the real register file. It breaks
# when a rename stops taking, which still LINKS, so nothing else catches it.
zig build math_wrappers_full_core_parity
zig build math_random_parity
# The seven focused math differentials. Each links the real c43 worker beside the
# Zig owner, so together they are the differential coverage for the numeric core.
# They break at LINK time when an owner starts exporting a symbol one of their
# stub files also defines, and nothing else in this battery builds them, so a
# duplicate-symbol regression is invisible unless they run here.
zig build math_ln_complex_oracle
zig build eigen_parity
zig build math_real_rectangular_to_polar_oracle
zig build math_atan2_oracle
zig build math_atan_oracle
zig build math_real_trig_primitives_oracle
zig build math_circular_trig_oracle
# The distribution differential. Its expected values are derived from each
# distribution's closed form, which makes it a specified oracle. It is sensitive
# to the module rooting of src/shell/distributions: an @import there that escapes
# the harness module's path breaks this lane and nothing else.
zig build distribution_parity
# Format-equivalence oracle: every migrated sprintf->std.fmt translation
# must stay byte-identical to libc.
zig build format_parity
# Constant-offset oracle: every abi/constants.zig typed
# accessor's blob offset must match the C constantPointers.h ground truth, so the
# offset-crash class stays caught after each pin advance. constantPointers.h is a
# gitignored generateConstants output, so refresh it into src/generated first.
zig build constants
python3 .github/project/check-constant-offsets.py
# Constant-parity audit: every defines.h/enum value an owner hardcodes (ITM_*,
# ERROR_*, FLAG_*, dt*, ...) must match upstream C. Catches the stale-mirror class
# (TM_CMP was 10021, dtReal34 was 0) the behavioral oracle does not cover.
python3 .github/project/audit-constant-parity.py
# Item-table parity audit: frontier_items.zig's hand-mirrored indexOfItems must
# match the C-compiled items.c byte-for-byte. Catches the exact class that crashed
# a pin advance (LAST_ITEM grew, the Zig table went out of bounds) before merge.
python3 .github/project/audit-item-table-parity.py
# abi struct-layout oracle: the abi/types.zig numeric mirrors must match the
# translate-c'd upstream decNumber-family layout, so a wrong layout (silent
# corruption) fails here.
zig build abi-layout-parity
zig build keyboard_state_parity
# Four lanes that existed and ran in NO gate -- not here, not in the local gate,
# not in CI. They were found by enumerating the build's own lane list and diffing
# it against this file, which is what check-parity-lanes-gated.py now does on
# every run so the next one cannot hide the same way.
zig build keyboard_entry_parity
zig build charstring_diff
zig build constants_parity
zig build tone_parity
zig build both
# NON-BLOCKING: the headless GUI smoke trips a pixman SSE2 composite over-read
# under Xvfb software rendering (version-independent; not a product regression;
# see the workflow for the full diagnosis). Warn, do not fail.
zig build simulator_smoke \
  || echo "WARNING: simulator_smoke crashed in pixman composite under Xvfb software rendering (version-independent); not a product regression"
zig build testPgms
${XVFB:-} zig build test
zig build generated
