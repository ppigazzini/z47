#!/usr/bin/env bash
# Negative test for check-core-shell-severance.py.
#
# WHY THIS EXISTS. The gate's headline invariant -- "a core file that @imports a
# shell source file: it must stay at ZERO" -- could not fire. It compared
# `commonpath(...)` against an unnormalized `os.path.join(root, "src", "shell")`,
# which is "./src/shell" when root is "." (how the local gate and CI both call
# it) while commonpath returns "src/shell". The two were never equal, so the cap
# read zero on every tree, clean or not. The docstring's "It is zero today" was an
# artifact of the bug rather than a measurement.
#
# A gate that cannot fail is worse than no gate: it reports a guarantee it is not
# providing. So each case here injects a real violation into the real tree and
# demands exit 1, then restores.
#
# Run from the repo root.
set -uo pipefail

cd "$(dirname "$0")/../.."
GATE=".github/project/check-core-shell-severance.py"
VICTIM="src/core/text/word_break.zig"
failures=0

restore() { [ -f "$VICTIM.bak" ] && mv "$VICTIM.bak" "$VICTIM"; }
trap restore EXIT

check() {
    if [ "$3" = "$2" ]; then echo "  ok   $1 (exit $3)"
    else echo "  FAIL $1: expected exit $2, got $3"; failures=$((failures + 1)); fi
}

echo "test-check-core-shell-severance:"

# 0. The clean tree must pass, or nothing below means anything.
python3 "$GATE" --repo-root . >/dev/null 2>&1
check "clean tree passes" 0 $?

# 1. THE CASE THAT WAS UNGUARDED: a core file importing a shell source.
#    This is the invariant the gate exists to hold, and it silently could not.
cp "$VICTIM" "$VICTIM.bak"
printf '\nconst injected_violation = @import("../../shell/config.zig");\n' >> "$VICTIM"
out=$(python3 "$GATE" --repo-root . 2>&1); rc=$?
check "a core->shell @import fails" 1 $rc
echo "$out" | grep -q "import" \
    || { echo "  FAIL: no diagnosis naming the import edge"; failures=$((failures + 1)); }
mv "$VICTIM.bak" "$VICTIM"

# 2. It must fail when invoked the way CI invokes it, not only with an absolute
#    root. The bug was invisible precisely because --repo-root "." is the caller.
cp "$VICTIM" "$VICTIM.bak"
printf '\nconst injected_violation = @import("../../shell/config.zig");\n' >> "$VICTIM"
python3 "$GATE" --repo-root "$(pwd)" >/dev/null 2>&1; abs=$?
python3 "$GATE" --repo-root . >/dev/null 2>&1; rel=$?
if [ "$abs" -eq "$rel" ]; then echo "  ok   relative and absolute --repo-root agree (exit $rel)"
else echo "  FAIL --repo-root . gives $rel but absolute gives $abs: path handling is broken"
     failures=$((failures + 1)); fi
mv "$VICTIM.bak" "$VICTIM"

# 3. A new core->shell extern must fail. backToSystem's only first-party pub export
#    is shell/config.zig, so consuming it from core is a new up-coupling.
cp "$VICTIM" "$VICTIM.bak"
printf '\nextern fn backToSystem(confirmation: u16) void;\n' >> "$VICTIM"
python3 "$GATE" --repo-root . >/dev/null 2>&1
check "a new core->shell extern fails" 1 $?
mv "$VICTIM.bak" "$VICTIM"

if [ "$failures" -ne 0 ]; then
    echo "test-check-core-shell-severance: $failures FAILED"
    exit 1
fi
echo "test-check-core-shell-severance: all cases passed"
