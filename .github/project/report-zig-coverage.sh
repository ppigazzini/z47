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

# Matching is LITERAL, never regex. $repo_root is a filesystem path and a path is
# not a safe regex: a `.` would match any character and a `+` or `*` would turn the
# preceding character into a quantifier, so a repo checked out at e.g.
# ~/proj.v2+beta stops matching its own files. The failure mode is "0 lines", which
# reads as "no coverage" rather than as an error -- so awk does prefix arithmetic
# with index() and the areas are compared as plain strings.
lines="$(llvm-symbolizer --obj="$bin" < cov_pcs.txt 2>/dev/null \
         | awk -v prefix="$repo_root/" -v areas="$(printf '%s\n' "${areas[@]}" | paste -sd '|' -)" '
             BEGIN { n = split(areas, a, "|") }
             {
               # Keep only "<file>:<line>" under the repo root.
               if (index($0, prefix) != 1) next
               if (match($0, /:[0-9]+/) == 0) next
               rel = substr($0, length(prefix) + 1)
               for (i = 1; i <= n; i++)
                 if (index(rel, a[i] "/") == 1) { print prefix rel; next }
             }' | sort -u)"
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
# Literal prefix strip again, for the same reason: sed would read $repo_root as a
# regex, and a `#` anywhere in the path would also close the s### delimiter.
printf '%s\n' "$lines" | cut -d: -f1 | sort | uniq -c | sort -rn | head -12 \
  | awk -v prefix="$repo_root/" '{
      rest = $0
      sub(/^ *[0-9]+ /, "", rest)
      if (index(rest, prefix) == 1) rest = substr(rest, length(prefix) + 1)
      printf "%7d  %s\n", $1, rest
    }'
