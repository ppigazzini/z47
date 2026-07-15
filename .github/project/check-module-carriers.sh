#!/usr/bin/env bash
#
# Compilation-carrier gate (REPORT-28 §39, law L9).
#
# THE DEFECT THIS FREEZES. A Zig owner drags other owners into its object with
#   comptime { _ = @import("other.zig"); }
# Nothing links the carrier to what it carries, so the block silently makes the
# carrier the COMPILATION CARRIER of that code. Two consequences, both real:
#   1. The carried owners are pinned to the carrier's directory forever (a Zig
#      module is bounded by its root's directory), so they cannot be re-homed.
#   2. The carrier is pinned to THEM. In M1, calc_state.zig -- a persistence
#      owner -- carried 12 unrelated scalar-state owners, so persistence could
#      not leave core/kernel. Carving it looked safe by import-closure and then
#      failed on FileNotFound, because a closure walk that ignores force-import
#      blocks reports an unsafe carve as safe.
#
# THE RULE: a force-import block belongs ONLY in a MODULE ROOT -- a file named
# as some object's root_source_file, whose job IS to define that object's
# contents. A root that exists only to force-import (core/state/state.zig) is
# the CORRECT shape; the fix for a conscripted owner is to give the carried code
# its own root, never to work around the pin.
#
# WHY AN ALLOWLIST AND NOT A PARSER. Roots reach build.zig by several routes --
# a literal `root_source_file = b.path(..)`, a LazyPath threaded through a helper
# parameter (zig_build/state/keyboard_state.zig:203), a b.createModule for a
# registered module. A regex that recognises only the literal form reports true
# roots as violations (it flagged keyboard_state.zig during this gate's own
# development). Rather than ship a fragile parser, pin the sanctioned carriers by
# name: each entry below is a verified module root, and adding a sixth is then a
# deliberate act with a reviewer, which is exactly the intent.
#
# Usage: check-module-carriers.sh          # enforce
#        check-module-carriers.sh --bump   # re-pin (only with justification)
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"
baseline_file=".github/project/module-carriers-baseline.txt"

# Every zig_src file holding a force-import statement. Match the STATEMENT, not
# the enclosing `comptime { .. }` block: a block-spanning regex has to express
# "no brace in between", and the real blocks carry explanatory comments that
# contain braces, so it silently misses them (it dropped command_wrappers.zig
# and its 82 force-imports while reporting a pass). The statement form is the
# idiom itself and needs no brace matching.
force_re='^[[:space:]]*_[[:space:]]*=[[:space:]]*@import\("[^"]+\.zig"\)[[:space:]]*;'
mapfile -t carriers < <(git ls-files 'zig_src/*.zig' | xargs -r grep -lE "$force_re" | sort)

if [ "${#carriers[@]}" -eq 0 ]; then
    echo "check-module-carriers: BROKEN -- detected zero force-import carriers."
    echo "zig_src is known to contain several (module roots legitimately use them),"
    echo "so a zero count means the detector stopped working, not that the tree is"
    echo "clean. Refusing to report a false pass."
    exit 1
fi

if [ "${#carriers[@]}" -eq 0 ]; then
    echo "check-module-carriers: BROKEN -- detected zero force-import carriers."
    echo "zig_src is known to contain several (module roots legitimately use them),"
    echo "so a zero count means the detector stopped working, not that the tree is"
    echo "clean. Refusing to report a false pass."
    exit 1
fi

if [ "${1:-}" = "--bump" ]; then
    {
        echo "# Sanctioned compilation carriers (REPORT-28 §39, law L9)."
        echo "# Each file below MUST be a module root (some object's root_source_file)."
        echo "# A force-import block in a non-root conscripts that owner as a carrier and"
        echo "# pins it to the code it carries -- give the carried code its own root instead."
        echo "# Re-pin with: .github/project/check-module-carriers.sh --bump"
        printf '%s\n' "${carriers[@]}"
    } > "$baseline_file"
    echo "check-module-carriers: re-pinned ${#carriers[@]} carriers"
    exit 0
fi

mapfile -t sanctioned < <(grep -vE '^\s*(#|$)' "$baseline_file" | sort)
unexpected=$(comm -23 <(printf '%s\n' "${carriers[@]}") <(printf '%s\n' "${sanctioned[@]}"))
removed=$(comm -13 <(printf '%s\n' "${carriers[@]}") <(printf '%s\n' "${sanctioned[@]}"))

if [ -n "$unexpected" ]; then
    echo "NEW COMPILATION CARRIER: a force-import block appeared in a file that is not a sanctioned module root."
    echo "$unexpected" | sed 's/^/  /'
    echo ""
    echo "A comptime force-import makes this file the compilation carrier of what it"
    echo "imports: both it and the carried owners are then pinned to this directory."
    echo "If this file IS a module root, re-pin with --bump. If it is an owner that"
    echo "merely needed other code compiled, give that code its own root (see"
    echo "zig_src/core/state/state.zig) and import it by name instead."
    exit 1
fi

if [ -n "$removed" ]; then
    echo "check-module-carriers: sanctioned carriers no longer present (re-pin with --bump):"
    echo "$removed" | sed 's/^/  /'
    exit 1
fi

echo "check-module-carriers: OK (${#carriers[@]} force-import carriers, all sanctioned module roots)"
