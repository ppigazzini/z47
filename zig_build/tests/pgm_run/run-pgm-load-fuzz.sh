#!/usr/bin/env bash
#
# M1 (REPORT-27 ANNEX B): drive an ASAN-instrumented pgm_run harness over a corpus
# of MALFORMED .p47 files. The load path (fnLoadProgram) is the empirical memory-bug
# surface upstream keeps fixing (577 statefile overflow, decode-literal-base-oob); the
# existing cov tests only exercise VALID round-trips, so this fills the malformed-input
# gap using the AddressSanitizer lane z47 already builds.
#
# PASS: every malformed file is handled with a clean exit or a graceful load-failure
#       (the harness returns 1 on "no labels"). FAIL: any ASAN report, any crash
#       signal, or a hang -- i.e. an out-of-bounds/undefined access on bad input.
#
# Usage (wired by `zig build pgm_load_fuzz`): run-pgm-load-fuzz.sh <harness> <corpus_dir>
set -uo pipefail

harness="${1:?harness binary path required}"
corpus="${2:?corpus dir required}"

# abort_on_error=0 so ASAN prints its report and exits (exitcode below) rather than
# raising SIGABRT; the marker grep is the primary signal either way.
export PGM_LOAD_ONLY=1
export ASAN_OPTIONS="detect_leaks=0:abort_on_error=0:exitcode=86:handle_segv=1"

total=0
fail=0
for f in "$corpus"/*.p47; do
  total=$((total + 1))
  out="$(timeout 20 "$harness" "$f" 2>&1)"
  rc=$?
  if printf '%s' "$out" | grep -qE "ERROR: AddressSanitizer|SUMMARY: AddressSanitizer|runtime error:"; then
    echo "FAIL (ASAN caught a memory bug): $f"
    printf '%s\n' "$out" | grep -E "AddressSanitizer|runtime error:|#[0-9]+ 0x" | head -6
    fail=$((fail + 1))
  elif [ "$rc" -eq 86 ]; then
    echo "FAIL (ASAN exitcode): $f"
    fail=$((fail + 1))
  elif [ "$rc" -eq 124 ]; then
    echo "FAIL (hang / infinite loop on malformed input): $f"
    fail=$((fail + 1))
  elif [ "$rc" -gt 128 ]; then
    echo "FAIL (killed by signal $((rc - 128))): $f"
    fail=$((fail + 1))
  fi
  # rc 0 (ran) or rc 1 (graceful "load produced no labels") => PASS, no output.
done

if [ "$fail" -eq 0 ]; then
  echo "M1 pgm_load_fuzz: $total malformed .p47 inputs handled with no OOB / crash / hang under ASAN."
else
  echo "M1 pgm_load_fuzz: $fail of $total malformed inputs triggered a memory bug (see above)."
  exit 1
fi
