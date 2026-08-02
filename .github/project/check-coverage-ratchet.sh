#!/usr/bin/env bash
#
# Coverage ratchet (Annex A6): fail if a guarded coverage metric drops below its
# committed floor in coverage-ratchet-baseline.txt. The floors are monotonic --
# they protect the gains that actually catch a bad M10 re-port (the C-vs-Zig
# differential and the full-core parity harnesses), so a future change cannot
# quietly delete them. Raise a floor in the same commit that adds coverage.
#
# Usage: check-coverage-ratchet.sh        # enforce (CI)
#        check-coverage-ratchet.sh --bump # rewrite the baseline to current values
# Exit: 0 if every metric >= its floor; 1 on any regression.
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$repo_root"
baseline=".github/project/coverage-ratchet-baseline.txt"

# --- measure current values ---
cur_differential_functions="$(grep -E '^FUNCS=' \
  build/tests/charstring_diff/extract_oracle.sh \
  | grep -oE 'string[A-Za-z_]+' | grep -c . )"
cur_fullcore_harness_steps="$(grep -c 'addFullCoreHarness(' build/host/steps.zig)"

metrics=(differential_functions fullcore_harness_steps)

# Annex A0 owner-coverage floor: distinct src/ owner source lines executed by
# the instrumented keyboardEntryCov harness (frontier + keyboard_state + stack_state
# owner objects built with coverage=true). Measured only when a `zig build coverage`
# build is present, so this script stays usable in the nightly grep-only run.
#
# This count is NOT exact: llvm-symbolizer/inlining resolves a few lines differently
# run-to-run and across LLVM versions. It is therefore a COLLAPSE floor with a
# deliberate margin below the measured value -- it catches an owner object losing its
# coverage=true flag or the harness being gutted (hundreds of lines), NOT a +-few
# symbolizer wobble. Raise it BY HAND (not --bump) when a real coverage gain lands.
cur_zig_src_covered_lines=""
# `|| true`: in the grep-only nightly/drift run there is no build, so `.zig-cache`
# is absent and `find` exits non-zero -- under `set -euo pipefail` that would abort
# the whole script before the graceful "no coverage build present" skip below. Keep
# cov_bin empty instead so the skip path runs.
cov_bin="$(find .zig-cache -name keyboardEntryCov -type f -executable \
  -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2 || true)"
if [[ -f cov_pcs.txt && -n "$cov_bin" ]] && command -v llvm-symbolizer >/dev/null 2>&1; then
  cur_zig_src_covered_lines="$(llvm-symbolizer --obj="$cov_bin" < cov_pcs.txt 2>/dev/null \
    | grep -oE '/src/[^:]+:[0-9]+' | sort -u | grep -c . || true)"
fi

if [[ "${1:-}" == "--bump" ]]; then
  for m in "${metrics[@]}"; do
    cur="cur_$m"
    sed -i -E "s/^$m=[0-9]+/$m=${!cur}/" "$baseline"
    echo "bumped $m -> ${!cur}"
  done
  exit 0
fi

floor() { grep -E "^$1=" "$baseline" | cut -d= -f2; }

rc=0
for m in "${metrics[@]}"; do
  cur="cur_$m"; have="${!cur}"; want="$(floor "$m")"
  if (( have < want )); then
    echo "RATCHET REGRESSION: $m = $have, floor is $want -- a guarded coverage"
    echo "  gain was removed. Restore it, or lower the floor with an explicit"
    echo "  justification (and --bump)."
    rc=1
  elif (( have > want )); then
    echo "$m = $have (above floor $want) -- run --bump to lock the new gain."
  else
    echo "$m = $have (at floor)"
  fi
done

if [[ -n "$cur_zig_src_covered_lines" ]]; then
  have="$cur_zig_src_covered_lines"; want="$(floor zig_src_covered_lines)"
  if (( have < want )); then
    echo "RATCHET REGRESSION: zig_src_covered_lines = $have, floor is $want -- owner"
    echo "  coverage collapsed. An owner object likely lost its coverage=true flag or"
    echo "  the keyboardEntryCov harness was gutted. Restore it, or lower the floor"
    echo "  with an explicit justification."
    rc=1
  else
    echo "zig_src_covered_lines = $have (>= collapse floor $want; margined for symbolizer noise)"
  fi
else
  echo "zig_src_covered_lines: skipped (no coverage build present; run 'zig build coverage' first)"
fi
exit $rc
