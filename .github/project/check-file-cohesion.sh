#!/usr/bin/env bash
#
# File-cohesion gate (REPORT-28 §33 NM11-0). The complement of the drawer ban:
# this fails the build on OVER-FRAGMENTATION -- micro-files that hold a single
# fn/var where a cohesive owner belonged. Granularity is cohesion in BOTH
# directions: don't pile unrelated things into a drawer (NM10-0), and don't split
# a cohesive thing into barnacles (this gate).
#
# Two checks:
#   1. DEAD FILE (absolute): a .zig file with zero top-level declarations is dead.
#   2. MICRO-FILE RATCHET: the count of <15-line .zig files under src must not
#      exceed the baseline in file-cohesion-baseline.json. It may only shrink, so
#      the barnacle count is driven down and can never grow.
#
# Usage: check-file-cohesion.sh          # enforce
#        check-file-cohesion.sh --bump    # re-pin the baseline to the current count
# Exit: 0 if clean; 1 on a dead file or a micro-file regression.
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"
baseline_file=".github/project/file-cohesion-baseline.json"

# --- count declarations in a file: any top-level decl keyword at line start
# (pub / const / var / fn / extern / inline / test / comptime). A file with none
# is genuinely dead. ---
decl_count() { grep -cE '^[[:space:]]*(pub|const|var|fn|extern|inline|test|comptime)[[:space:]]' "$1" || true; }

dead=0
micro=0
while IFS= read -r f; do
    lines=$(wc -l < "$f")
    if [ "$lines" -lt 15 ]; then micro=$((micro + 1)); fi
    if [ "$(decl_count "$f")" -eq 0 ]; then
        echo "DEAD FILE: '$f' has zero top-level declarations -- delete it or fold its purpose into a real owner."
        dead=$((dead + 1))
    fi
done < <(git ls-files 'src/*.zig')

baseline=$(grep -oE '"micro_files"[[:space:]]*:[[:space:]]*[0-9]+' "$baseline_file" | grep -oE '[0-9]+')

if [ "${1:-}" = "--bump" ]; then
    printf '{\n  "micro_files": %d,\n  "note": "REPORT-28 NM11: count of <15-line src files; monotonic downward -- barnacles only shrink."\n}\n' "$micro" > "$baseline_file"
    echo "check-file-cohesion: re-pinned micro_files baseline to $micro"
    exit 0
fi

fail=0
if [ "$dead" -ne 0 ]; then fail=1; fi
if [ "$micro" -gt "$baseline" ]; then
    echo "MICRO-FILE REGRESSION: $micro files under src are <15 lines (ceiling $baseline)."
    echo "  A <15-line file holding a single fn/var that shares a subsystem with a sibling is a"
    echo "  barnacle -- fold it into the cohesive owner. Reduce it, do not raise the ceiling."
    fail=1
fi

if [ "$fail" -ne 0 ]; then
    echo ""
    echo "check-file-cohesion: FAIL. Granularity is cohesion: not a drawer, not a barnacle."
    exit 1
fi
echo "check-file-cohesion: OK (no dead files; micro-files $micro <= ceiling $baseline)"
