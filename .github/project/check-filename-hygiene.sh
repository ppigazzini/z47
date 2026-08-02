#!/usr/bin/env bash
#
# Filename hygiene gate (REPORT-28 §32 NM10-0). A source filename must name its
# RESPONSIBILITY, never how it was produced. This fails the build on any src
# filename that carries a migration-artifact / dumping-ground token, so the
# "*_bulk"-class regression that the NM9 severance push introduced cannot come
# back. See [[severance-destinations-must-be-designed-owners]].
#
# Banned tokens (as a whole word inside the snake_case basename): bulk, misc,
# extracted, moved, stuff, junk, tmp, temp, misc, various, part1/part2, etc.
#
# Exit 0 if every src filename is clean; 1 on any violation.
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

# whole-word banned tokens in the snake_case basename (without .zig). Only
# unambiguous migration/dumping artifacts -- words that are legitimate
# responsibilities elsewhere (copy, new, base) are NOT banned.
banned='^(.*_)?(bulk|misc|extracted|dumping|leftover|stuff|junk|tmp|temp|various|part[0-9]+)(_.*)?$'

violations=0
while IFS= read -r f; do
    base="$(basename "$f" .zig)"
    if printf '%s' "$base" | grep -Eq "$banned"; then
        echo "FILENAME HYGIENE: '$f' names a migration artifact, not a responsibility."
        echo "  -> rename it after WHAT it owns (the cohesive responsibility), not how it was created."
        violations=$((violations + 1))
    fi
done < <(git ls-files 'src/*.zig')

if [ "$violations" -ne 0 ]; then
    echo ""
    echo "check-filename-hygiene: FAIL ($violations file(s)). A file is a MODULE with a"
    echo "responsibility, never a landfill for whatever a migration displaced."
    exit 1
fi

echo "check-filename-hygiene: OK (no migration-artifact filenames under src)"
