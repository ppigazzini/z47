#!/usr/bin/env bash
#
# M-SAFE-7 (REPORT-30): drive a corpus of MALFORMED state files through the real
# restore path (fnLoad -> doLoad -> restoreOneSection -> restoreRegister).
#
# PASS: the harness returns. That includes a file the parser REFUSES -- refusing
#       malformed input is the correct outcome, so "accepted" is not the
#       assertion. It also includes the one deliberately-VALID corpus file, which
#       must keep loading exactly as it always did.
# FAIL: any crash, any Zig safety panic, any sanitizer report, any hang.
#
# The harness is built at the default optimize level, so Zig's own safety checks
# are live: an out-of-range @intCast or an overflowing add on the load path traps
# here rather than wrapping silently as it would in the ReleaseSmall firmware.
# That is the detector this lane actually depends on -- the C is UBSan-
# instrumented too (M-SAFE-13), but there is no AddressSanitizer anywhere in this
# tree, so an overrun INSIDE the `ram` pool is still invisible. See
# docs/75-debugging.md.
#
# Usage: run-state-load-fuzz.sh <harness> <corpus-dir>
set -uo pipefail

harness="${1:?usage: run-state-load-fuzz.sh <harness> <corpus-dir>}"
corpus="${2:?usage: run-state-load-fuzz.sh <harness> <corpus-dir>}"

# The corpus is generated, not tracked: derived .sav files the generator rebuilds
# deterministically from build/tests/calc_state/save_load_golden.sav.
#
# That base has to be TRACKED. This comment used to name c47Test.sav and call it
# tracked; it is the name the testSuite HAL maps ioPathManualSave to, .gitignore
# ignores it, and it exists only where the testSuite has already run and saved. So
# the lane passed on a developer machine and died in CI on a clean checkout with a
# FileNotFoundError. If this base ever changes, check `git ls-files` on it first.
if [ ! -d "$corpus" ] || [ -z "$(ls -A "$corpus"/*.sav 2>/dev/null)" ]; then
  echo "generating the malformed state corpus..."
  python3 "$corpus/generate_corpus.py" >/dev/null || {
    echo "FAIL: could not generate the corpus"
    exit 1
  }
fi

# abort_on_error=0 so a sanitizer prints its report and exits with the code below
# rather than dying on a signal we would report less precisely.
export ASAN_OPTIONS="detect_leaks=0:abort_on_error=0:exitcode=86:handle_segv=1"
export UBSAN_OPTIONS="halt_on_error=1:print_stacktrace=1"

total=0
fail=0
# The restore path branches on the load mode, so sweeping only LM_ALL leaves a
# third of the 31fb6f755 guard commit's arms unreachable no matter how broad the
# corpus gets -- restoreProgramsSection's LM_PROGRAMS arm and restoreOneSection's
# skip-the-matrix-data else-arm are both mode-gated. Measured: LM_ALL alone
# reached 19 of 30 added arms.
#   0 = LM_ALL   1 = LM_PROGRAMS   2 = LM_REGISTERS   5 = LM_SYSTEM_STATE
LOAD_MODES="0 1 2 5"

# M-SAFE-15's pool poison detector is NEW, and on its first run it reported two
# files whose writer is not yet identified (finding 22). Per the rule this tree
# applies to every new heuristic -- calibrate before you judge -- it lands as a
# REPORT with a known-list rather than a gate. A poison report from any OTHER file
# FAILS, so the detector protects from today onward while these two are chased.
#
# Do NOT add a file here to quieten a report. Each entry is an open finding, and
# the list shrinking is the measure of progress on finding 22.
POISON_KNOWN="matrix_dims_at_u16_block_limit.sav matrix_rows_exceed_header_12_bits.sav"

for f in "$corpus"/*.sav; do
 for mode in $LOAD_MODES; do
  total=$((total + 1))
  label="$f (mode $mode)"
  out="$(timeout 60 "$harness" "$f" "$mode" 2>&1)"
  rc=$?

  # Read the expectation up front: it decides whether a REFUSAL is acceptable for
  # this file, so the exit-code dispatch below needs it too, not just the
  # accepted-with-the-wrong-version check at the end. "any" (or no entry) means
  # the corpus asserts nothing about the outcome, only that it stayed safe.
  # ...but only in LM_ALL. expectations.txt records the version a file resolves
  # to on a FULL restore; a partial mode legitimately leaves loadedVersion
  # elsewhere, so asserting the same value across modes would encode noise.
  want=""
  if [ "$mode" = "0" ] && [ -f "$corpus/expectations.txt" ]; then
    want="$(awk -v n="$(basename "$f")" '$1 == n { print $2 }' "$corpus/expectations.txt")"
  fi

  if printf '%s' "$out" | grep -qE "ERROR: AddressSanitizer|SUMMARY: AddressSanitizer|runtime error:"; then
    echo "FAIL (the sanitizer caught a bug): $label"
    printf '%s\n' "$out" | grep -E "AddressSanitizer|runtime error:|#[0-9]+ 0x" | head -6
    fail=$((fail + 1))
  elif printf '%s' "$out" | grep -qE "^thread [0-9]+ panic:"; then
    echo "FAIL (Zig safety check tripped on malformed input): $label"
    printf '%s\n' "$out" | grep -E "panic:|\.zig:[0-9]+" | head -6
    fail=$((fail + 1))
  elif [ "$rc" -eq 86 ]; then
    echo "FAIL (sanitizer exitcode): $label"
    fail=$((fail + 1))
  elif [ "$rc" -eq 87 ]; then
    # The pool poison detector (M-SAFE-15). Something wrote past its allocation
    # into free pool space -- the class ASan cannot see here, because `ram` is one
    # allocation to it. This is finding 5's only detector.
    # ' %s ' on BOTH sides: '%s ' alone leaves the first entry without a leading
    # space, so it never matches and the list silently covers all but its head.
    if printf ' %s ' $POISON_KNOWN | grep -qF " $(basename "$f") "; then
      echo "KNOWN pool-poison report (finding 22, open): $label"
      printf '%s\n' "$out" | grep -E "POOL POISON DISTURBED" | head -1
    else
      echo "FAIL (pool poison disturbed -- in-pool overrun): $label"
      printf '%s\n' "$out" | grep -E "POOL POISON" | head -3
      fail=$((fail + 1))
    fi
  elif [ "$rc" -eq 124 ]; then
    echo "FAIL (hang / infinite loop on malformed input): $label"
    fail=$((fail + 1))
  elif [ "$rc" -eq 253 ] && printf '%s' "$out" | grep -q "OUT OF MEMORY"; then
    # exit(-3) -> 253, from resizeProgramMemory's out-of-memory path. That exit
    # is upstream's own (memory.c: `exit(-3)` on the !DMCP_BUILD side, where the
    # device instead does backToSystem), mirrored faithfully in
    # memory_runtime.zig, so it is a CONTROLLED refusal of an impossible
    # allocation and not memory unsafety. A forged program count is precisely
    # the input that reaches it. The banner is required as well as the code so a
    # different exit(-3) cannot pass as this one.
    #
    # But a file the corpus expects to LOAD must not reach it: refusing is only
    # correct for input that deserves refusal.
    if [ -n "$want" ] && [ "$want" != "any" ]; then
      echo "FAIL (refused with OUT OF MEMORY, but expected it to load): $label"
      fail=$((fail + 1))
    fi
  elif [ "$rc" -ge 129 ] && [ "$rc" -le 192 ]; then
    # Only this range is a signal death (128+signum). Codes above it are ordinary
    # exit statuses -- reporting 253 as "signal 125" sent an earlier run of this
    # lane chasing a crash that was a plain exit().
    echo "FAIL (killed by signal $((rc - 128))): $label"
    fail=$((fail + 1))
  elif [ "$rc" -ne 0 ]; then
    echo "FAIL (harness error, exit $rc): $label"
    printf '%s\n' "$out" | tail -3
    fail=$((fail + 1))
  elif [ -n "$want" ] && [ "$want" != "any" ]; then
    # The restore path returned. Now check it returned the RIGHT thing, where the
    # corpus states one. Crash-detection alone cannot see a defect that makes the
    # parser silently ACCEPT what it should refuse -- the version forgery is
    # exactly that, and it never crashes.
    got="$(printf '%s' "$out" | sed -n 's/.*loadedVersion=\([0-9]*\).*/\1/p' | tail -1)"
    if [ -z "$got" ]; then
      echo "FAIL (no loadedVersion in harness output): $label"
      fail=$((fail + 1))
    elif [ "$got" != "$want" ]; then
      echo "FAIL (wrong outcome): $label -- loadedVersion=$got, expected $want"
      fail=$((fail + 1))
    fi
  fi
  # rc 0 with a matching (or absent) expectation => PASS, no output.
 done
done

# The harness copies each corpus file over c47.sav to reach the restore path, so
# leave no malformed state file behind for the next lane -- or for a developer
# who runs the simulator next and wonders why it boots strangely.
rm -f c47.sav

if [ "$total" -eq 0 ]; then
  echo "FAIL: no .sav files in $corpus"
  exit 1
fi

if [ "$fail" -ne 0 ]; then
  echo "M-SAFE-7 state_load_fuzz: $fail of $total malformed state file x load-mode runs FAILED."
  exit 1
fi

echo "M-SAFE-7 state_load_fuzz: $total malformed state file x load-mode runs handled with no crash / hang / safety panic."
