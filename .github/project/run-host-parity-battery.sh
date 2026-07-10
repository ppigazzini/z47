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
zig build math_command_wrappers_parity
zig build math_random_parity
# Format-equivalence oracle (M24): every migrated sprintf->std.fmt translation
# must stay byte-identical to libc.
zig build format_parity
# Constant-offset oracle (REPORT-23 P3 / M22): every abi/constants.zig typed
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
zig build both
# NON-BLOCKING: the headless GUI smoke trips a pixman SSE2 composite over-read
# under Xvfb software rendering (version-independent; not a product regression;
# see the workflow for the full diagnosis). Warn, do not fail.
zig build simulator_smoke \
  || echo "WARNING: simulator_smoke crashed in pixman composite under Xvfb software rendering (version-independent); not a product regression"
zig build testPgms
${XVFB:-} zig build test
zig build generated
