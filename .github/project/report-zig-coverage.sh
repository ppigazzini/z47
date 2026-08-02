#!/usr/bin/env bash
#
# Coverage report for the host harness (Annex A0).
#
# `zig build coverage` builds the keyboard harness with SanitizerCoverage
# trace-pc-guard (LLVM backend) + build/tests/coverage/sancov_handler.c, which
# writes the set of executed edges to cov_pcs.txt. This script symbolizes those
# PCs (llvm-symbolizer) and reports the covered source lines, grouped by area.
# kcov is unavailable here and Zig 0.16 has no -fprofile-instr path, so sancov is
# the coverage mechanism; the toy proof that Zig code IS instrumentable this way
# is in the commit that introduced the handler.
#
# SCOPE: the FRONTIER, KEYBOARD_STATE, and STACK_STATE owner objects are now
# instrumented (each threads a `coverage` flag onto its b.addObject when the
# coverage harness is built), so the report resolves those src/*.zig owners
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

# Areas are matched as repo-root-anchored PREFIXES, not as bare directory names.
# Since the imported tree moved under UPSTREAM_ROOT, "src" alone is ambiguous: it
# is both z47's own Zig owners (src/) and upstream's C (upstream/src/), and a
# bare /src/ match would silently fold the second into the first.
upstream_root="$(awk -F= '/^UPSTREAM_ROOT=/{print $2}' .github/project/upstream-pin.env)"
if [[ -z "$upstream_root" ]]; then
  echo "missing UPSTREAM_ROOT in .github/project/upstream-pin.env" >&2
  exit 1
fi
if [[ "$upstream_root" == "." ]]; then
  areas=(src build dep)
else
  areas=(src build "$upstream_root/src" "$upstream_root/dep")
fi

# Only `.` needs escaping for the ERE below; `\/` is undefined in POSIX ERE even
# though GNU grep tolerates it.
area_re="$(printf '%s\n' "${areas[@]}" | sed 's#\.#\\.#g' | paste -sd '|' -)"
lines="$(llvm-symbolizer --obj="$bin" < cov_pcs.txt 2>/dev/null \
         | grep -oE "$repo_root/($area_re)/[^:]+:[0-9]+" | sort -u)"
total="$(printf '%s\n' "$lines" | grep -c . || true)"

echo "host-harness coverage (executed edges: $(grep -c . cov_pcs.txt); distinct source lines: $total)"
echo
echo "by area:"
for area in "${areas[@]}"; do
  n="$(printf '%s\n' "$lines" | grep -cF "$repo_root/$area/" || true)"
  echo "  $area: $n line(s)"
done

zig_n="$(printf '%s\n' "$lines" | grep -cF "$repo_root/src/" || true)"
echo
if [[ "$zig_n" == 0 ]]; then
  echo "NOTE: 0 src/ owner lines -- the owners are linked as objects built"
  echo "without the coverage flag (see SCOPE in this script's header). The C"
  echo "coverage below confirms the mechanism + symbolization work end to end."
fi
echo "top covered files:"
printf '%s\n' "$lines" | cut -d: -f1 | sort | uniq -c | sort -rn | head -12 \
  | sed -E "s#^( *[0-9]+) $repo_root/#\1  #"
