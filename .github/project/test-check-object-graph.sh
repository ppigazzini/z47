#!/usr/bin/env bash
# Negative test for check-object-graph.py.
#
# A gate is only worth its exit code if a violation actually turns it red. This
# repo has already shipped a gate that reported "OK (0 carriers)" because its
# pattern silently matched nothing -- a green light from an empty measurement is
# worse than no gate. So every assertion here injects a real violation and
# demands exit 1, and the last case demands the gate REFUSE an empty manifest
# rather than call it a clean graph.
#
# Run from the repo root. Requires `zig build object-manifest` to have run.
set -uo pipefail

cd "$(dirname "$0")/../.."
GATE=".github/project/check-object-graph.py"
BASELINE=".github/project/object-graph-baseline.json"
MANIFEST="zig-out/object-graph/sim-objects.txt"
failures=0

restore() {
    [ -f "$BASELINE.bak" ] && mv "$BASELINE.bak" "$BASELINE"
    [ -f "$MANIFEST.bak" ] && mv "$MANIFEST.bak" "$MANIFEST"
}
trap restore EXIT

check() {
    local name="$1" expected="$2" actual="$3"
    if [ "$actual" = "$expected" ]; then
        echo "  ok   $name (exit $actual)"
    else
        echo "  FAIL $name: expected exit $expected, got $actual"
        failures=$((failures + 1))
    fi
}

echo "test-check-object-graph:"

# 1. The unmodified tree must pass. If this fails, every case below is meaningless.
python3 "$GATE" --repo-root . >/dev/null 2>&1
check "clean tree passes" 0 $?

# 2. A cycle that GREW must fail. Claim a smaller largest cycle than reality.
cp "$BASELINE" "$BASELINE.bak"
python3 - <<'PY'
import json
p = ".github/project/object-graph-baseline.json"
d = json.load(open(p))
d["targets"]["sim"]["cycles"] = [17]
d["targets"]["sim"]["objects_in_cycles"] = 17
json.dump(d, open(p, "w"), indent=1, sort_keys=True)
PY
out=$(python3 "$GATE" --repo-root . 2>&1); rc=$?
check "a grown cycle fails" 1 $rc
echo "$out" | grep -q "largest object cycle grew" \
    || { echo "  FAIL: no diagnosis naming the grown cycle"; failures=$((failures + 1)); }
mv "$BASELINE.bak" "$BASELINE"

# 3. A new cyclic component must fail.
cp "$BASELINE" "$BASELINE.bak"
python3 - <<'PY'
import json
p = ".github/project/object-graph-baseline.json"
d = json.load(open(p))
d["targets"]["dmcp"]["cycles"] = []
d["targets"]["dmcp"]["objects_in_cycles"] = 0
json.dump(d, open(p, "w"), indent=1, sort_keys=True)
PY
python3 "$GATE" --repo-root . >/dev/null 2>&1
check "a new cycle fails" 1 $?
mv "$BASELINE.bak" "$BASELINE"

# 4. An EMPTY manifest must be refused, not passed. This is the failure mode the
#    gate exists to avoid: measuring nothing and reporting success.
cp "$MANIFEST" "$MANIFEST.bak"
: > "$MANIFEST"
out=$(python3 "$GATE" --repo-root . 2>&1); rc=$?
[ "$rc" -ne 0 ] \
    && echo "  ok   empty manifest refused (exit $rc)" \
    || { echo "  FAIL empty manifest was accepted"; failures=$((failures + 1)); }
echo "$out" | grep -q "BROKEN" \
    || { echo "  FAIL: refusal did not say BROKEN"; failures=$((failures + 1)); }
mv "$MANIFEST.bak" "$MANIFEST"

if [ "$failures" -ne 0 ]; then
    echo "test-check-object-graph: $failures FAILED"
    exit 1
fi
echo "test-check-object-graph: all cases passed"
