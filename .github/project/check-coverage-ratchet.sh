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
  zig_build/tests/charstring_diff/extract_oracle.sh \
  | grep -oE 'string[A-Za-z_]+' | grep -c . )"
cur_fullcore_harness_steps="$(grep -c 'addFullCoreHarness(' zig_build/host/steps.zig)"

metrics=(differential_functions fullcore_harness_steps)

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
exit $rc
