#!/usr/bin/env bash
#
# Coverage report for the host harness (Annex A0).
#
# `zig build coverage` builds the keyboard harness with SanitizerCoverage
# trace-pc-guard (LLVM backend) + zig_build/tests/coverage/sancov_handler.c, which
# writes the set of executed edges to cov_pcs.txt. This script symbolizes those
# PCs (llvm-symbolizer) and reports the covered source lines, grouped by area.
# kcov is unavailable here and Zig 0.16 has no -fprofile-instr path, so sancov is
# the coverage mechanism; the toy proof that Zig code IS instrumentable this way
# is in the commit that introduced the handler.
#
# SCOPE: the FRONTIER, KEYBOARD_STATE, and STACK_STATE owner objects are now
# instrumented (each threads a `coverage` flag onto its b.addObject when the
# coverage harness is built), so the report resolves those zig_src/*.zig owners
# directly alongside the compiled-in C. The keyboard harness drives btnClicked
# dispatch + stack ops, so those owners execute and show up. The remaining owner
# groups (shortint / math_command_wrappers / solve) are still linked as objects
# built WITHOUT the flag; note the keyboard harness does not exercise the wp34s
# math commands or the solver, so instrumenting those two would add near-zero
# executed lines under THIS harness -- extend them only alongside a harness that
# drives them.
#
# Usage: report-zig-coverage.sh   (run `zig build coverage` first)
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$repo_root"

[[ -f cov_pcs.txt ]] || { echo "cov_pcs.txt missing -- run 'zig build coverage' first"; exit 1; }
bin="$(find .zig-cache -name keyboardEntryCov -type f -executable -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2)"
[[ -n "$bin" ]] || { echo "keyboardEntryCov binary not found -- run 'zig build coverage'"; exit 1; }

lines="$(llvm-symbolizer --obj="$bin" < cov_pcs.txt 2>/dev/null \
         | grep -oE "/(zig_src|src|dep|zig_build)/[^:]+:[0-9]+" | sort -u)"
total="$(printf '%s\n' "$lines" | grep -c . || true)"

echo "host-harness coverage (executed edges: $(grep -c . cov_pcs.txt); distinct source lines: $total)"
echo
echo "by area:"
for area in zig_src src dep zig_build; do
  n="$(printf '%s\n' "$lines" | grep -cE "/$area/" || true)"
  echo "  $area: $n line(s)"
done

zig_n="$(printf '%s\n' "$lines" | grep -cE "/zig_src/" || true)"
echo
if [[ "$zig_n" == 0 ]]; then
  echo "NOTE: 0 zig_src/ owner lines -- the owners are linked as objects built"
  echo "without the coverage flag (see SCOPE in this script's header). The C"
  echo "coverage below confirms the mechanism + symbolization work end to end."
fi
echo "top covered files:"
printf '%s\n' "$lines" | cut -d: -f1 | sort | uniq -c | sort -rn | head -12 \
  | sed -E 's#^( *[0-9]+) .*/(zig_src|src|dep|zig_build)/#\1  \2/#'
