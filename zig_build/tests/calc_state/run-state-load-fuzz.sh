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
# zig_docs/75-debugging.md.
#
# Usage: run-state-load-fuzz.sh <harness> <corpus-dir>
set -uo pipefail

harness="${1:?usage: run-state-load-fuzz.sh <harness> <corpus-dir>}"
corpus="${2:?usage: run-state-load-fuzz.sh <harness> <corpus-dir>}"

# The corpus is generated, not tracked: ~360 KB of derived .sav files that the
# generator rebuilds deterministically from the tracked c47Test.sav.
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
for f in "$corpus"/*.sav; do
  total=$((total + 1))
  out="$(timeout 60 "$harness" "$f" 2>&1)"
  rc=$?
  if printf '%s' "$out" | grep -qE "ERROR: AddressSanitizer|SUMMARY: AddressSanitizer|runtime error:"; then
    echo "FAIL (the sanitizer caught a bug): $f"
    printf '%s\n' "$out" | grep -E "AddressSanitizer|runtime error:|#[0-9]+ 0x" | head -6
    fail=$((fail + 1))
  elif printf '%s' "$out" | grep -qE "^thread [0-9]+ panic:"; then
    echo "FAIL (Zig safety check tripped on malformed input): $f"
    printf '%s\n' "$out" | grep -E "panic:|\.zig:[0-9]+" | head -6
    fail=$((fail + 1))
  elif [ "$rc" -eq 86 ]; then
    echo "FAIL (sanitizer exitcode): $f"
    fail=$((fail + 1))
  elif [ "$rc" -eq 124 ]; then
    echo "FAIL (hang / infinite loop on malformed input): $f"
    fail=$((fail + 1))
  elif [ "$rc" -gt 128 ]; then
    echo "FAIL (killed by signal $((rc - 128))): $f"
    fail=$((fail + 1))
  elif [ "$rc" -ne 0 ]; then
    echo "FAIL (harness error, exit $rc): $f"
    printf '%s\n' "$out" | tail -3
    fail=$((fail + 1))
  elif [ -f "$corpus/expectations.txt" ]; then
    # The restore path returned. Now check it returned the RIGHT thing, where the
    # corpus states one. Crash-detection alone cannot see a defect that makes the
    # parser silently ACCEPT what it should refuse -- the version forgery is
    # exactly that, and it never crashes.
    base="$(basename "$f")"
    want="$(awk -v n="$base" '$1 == n { print $2 }' "$corpus/expectations.txt")"
    if [ -n "$want" ] && [ "$want" != "any" ]; then
      got="$(printf '%s' "$out" | sed -n 's/.*loadedVersion=\([0-9]*\).*/\1/p' | tail -1)"
      if [ -z "$got" ]; then
        echo "FAIL (no loadedVersion in harness output): $f"
        fail=$((fail + 1))
      elif [ "$got" != "$want" ]; then
        echo "FAIL (wrong outcome): $f -- loadedVersion=$got, expected $want"
        fail=$((fail + 1))
      fi
    fi
  fi
  # rc 0 with a matching (or absent) expectation => PASS, no output.
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
  echo "M-SAFE-7 state_load_fuzz: $fail of $total malformed state files FAILED."
  exit 1
fi

echo "M-SAFE-7 state_load_fuzz: $total malformed state files handled with no crash / hang / safety panic."
