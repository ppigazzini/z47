#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
#
# Drive a sanitizer-instrumented pgm_run harness over a corpus
# of MALFORMED .p47 files. The load path (fnLoadProgram) is the empirical memory-bug
# surface upstream keeps fixing (577 statefile overflow, decode-literal-base-oob); the
# existing cov tests only exercise VALID round-trips, so this fills the malformed-input
# gap using the UBSan-instrumented harness z47 already builds.
#
# PASS: every malformed file is handled with a clean exit or a graceful load-failure
#       (the harness returns 1 on "no labels"). FAIL: any sanitizer report, any crash
#       signal, or a hang -- i.e. an out-of-bounds/undefined access on bad input.
#
# Usage (wired by `zig build pgm_load_fuzz`): run-pgm-load-fuzz.sh <harness> <corpus_dir>
set -uo pipefail

harness="${1:?harness binary path required}"
corpus="${2:?corpus dir required}"

# HARNESS_WRAPPER, when set, prefixes every harness run: memcheck_suite sets it
# to valgrind's memcheck, whose reports the checks below fail on.
read -r -a wrapper <<<"${HARNESS_WRAPPER:-}"

# abort_on_error=0 so a sanitizer prints its report and exits (exitcode below) rather than
# raising SIGABRT; the marker grep is the primary signal either way.
export PGM_LOAD_ONLY=1
# The lane is instrumented with UBSan, not AddressSanitizer: Zig's `sanitize_c`
# is the UBSan knob and Zig ships no ASan runtime at all.
export UBSAN_OPTIONS="halt_on_error=1:print_stacktrace=1"

total=0
fail=0
# An empty corpus must not run the literal pattern as one "file".
shopt -s nullglob
for f in "$corpus"/*.p47; do
  total=$((total + 1))
  # The harness bounds each file itself (harnessBudgetSetCase): a hang ends in its
  # BUDGET EXCEEDED report, never in a kill from out here.
  out="$("${wrapper[@]}" "$harness" "$f" 2>&1)"
  rc=$?
  if printf '%s' "$out" | grep -qE "^==[0-9]+== (Invalid (read|write|free)|Conditional jump|Use of uninitialised|Syscall param)"; then
    echo "FAIL (memcheck caught a bug): $f"
    printf '%s\n' "$out" | grep -E "^==[0-9]+==" | head -12
    fail=$((fail + 1))
  elif printf '%s' "$out" | grep -q "runtime error:"; then
    echo "FAIL (UBSan caught a bug): $f"
    printf '%s\n' "$out" | grep -E "runtime error:|#[0-9]+ 0x" | head -6
    fail=$((fail + 1))
  elif printf '%s' "$out" | grep -q "BUDGET EXCEEDED"; then
    echo "FAIL (unbounded on malformed input -- the harness budget stopped it): $f"
    fail=$((fail + 1))
  elif [ "$rc" -gt 128 ]; then
    echo "FAIL (killed by signal $((rc - 128))): $f"
    fail=$((fail + 1))
  elif [ "$rc" -ne 0 ] && [ "$rc" -ne 1 ]; then
    echo "FAIL (harness error, exit $rc): $f"
    printf '%s\n' "$out" | tail -3
    fail=$((fail + 1))
  fi
  # rc 0 (ran) or rc 1 (graceful "load produced no labels") => PASS, no output.
done

if [ "$total" -eq 0 ]; then
  echo "FAIL: no .p47 files in $corpus"
  exit 1
fi

if [ "$fail" -eq 0 ]; then
  echo "pgm_load_fuzz: $total malformed .p47 inputs handled with no crash / hang / sanitizer report (UBSan)."
else
  echo "pgm_load_fuzz: $fail of $total malformed inputs triggered a memory bug (see above)."
  exit 1
fi
