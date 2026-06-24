#!/usr/bin/env bash
#
# Re-port DRY-RUN / coverage-gap prove-out (Annex A7).
#
# Rehearses the M10 upstream re-port in a throwaway worktree to answer the only
# question that matters for M10 readiness: when the imported upstream C is
# advanced to the new pin, does ANY host suite go red -- or do the changes slip
# through green because the changed owners are compiled-out (Zig replaces them)
# and nothing compares the new upstream C against the Zig port?
#
# Demonstrated 2026-06-24 (pin bb439ccd -> upstream/master 52ab333b, 9 ported
# files changed): advancing all 14 changed src/c47 files to master left sim,
# keyboard_entry_parity, saveload_parity and the testSuite ALL GREEN. The
# upstream changes to the replaced owners (screen/softmenus/print/bufferize/items
# .c) are invisible on host. Any such file that is compiled-out AND green after
# refresh is a SILENT COVERAGE HOLE: a wrong or forgotten re-port of its Zig
# owner would be caught by nothing. The fix is a live C-vs-Zig differential
# (Annex A5) -- this script is what proves whether that gap is still open.
#
# Usage: run-upstream-reportgap-dryrun.sh [--classify-only]
#   (no arg)        full empirical dry-run: worktree + refresh + build + suites
#   --classify-only fast static classification of the changed ported files only
#
# Exit code: 0 if the dry-run completed (NOT a pass/fail gate -- read the report;
# a green run with compiled-out changed files is the FINDING, not success).
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$repo_root"
pin="$(grep -E '^UPSTREAM_COMMIT=' .github/project/upstream-pin.env | cut -d= -f2)"
branch="$(grep -E '^UPSTREAM_REMOTE_NAME=' .github/project/upstream-pin.env | cut -d= -f2)/$(grep -E '^UPSTREAM_BRANCH=' .github/project/upstream-pin.env | cut -d= -f2)"
# All replaced-source manifests: a file in ANY of them is compiled-out.
mapfile -t manifests < <(find zig_build -name '*replaced_core_sources.txt')

mapfile -t changed < <(git diff --name-only "$pin" "$branch" -- src/c47 2>/dev/null)
echo "pin $pin .. $branch : ${#changed[@]} changed src/c47 path(s)"

echo
echo "== classification (compiled-out owners are silent holes unless a"
echo "   differential or a golden case happens to exercise the changed behavior) =="
holes=0
for f in "${changed[@]}"; do
  rel="${f#src/c47/}"
  if grep -qh "$rel" "${manifests[@]}" 2>/dev/null; then
    echo "  SILENT-HOLE (Zig-replaced, C compiled out): $f"
    holes=$((holes + 1))
  else
    echo "  compiled-in (C still in product; behavior change is live): $f"
  fi
done
echo "  -> $holes of ${#changed[@]} changed files are compiled-out (silent on host)"

if [[ "${1:-}" == "--classify-only" ]]; then
  exit 0
fi

wt="$(mktemp -d)/a7-dryrun"
echo
echo "== empirical dry-run in throwaway worktree $wt =="
git worktree add --quiet --detach "$wt" HEAD
trap 'git worktree remove --force "$wt" 2>/dev/null; git worktree prune' EXIT
( cd "$wt"
  git checkout "$branch" -- "${changed[@]}"
  echo "refreshed ${#changed[@]} files to $branch; building + running suites..."
  rc=0
  for step in sim keyboard_entry_parity saveload_parity test; do
    if zig build "$step" >/dev/null 2>&1; then
      echo "  GREEN: $step"
    else
      echo "  RED:   $step   <-- a suite CAUGHT the refresh"
      rc=1
    fi
  done
  echo
  if [[ "$rc" == 0 ]]; then
    echo "VERDICT: all suites GREEN after refresh. Every compiled-out changed"
    echo "owner above is an unverified re-port -- host catches nothing. Close the"
    echo "gap with a C-vs-Zig differential (A5) before trusting M10 'run parity'."
  else
    echo "VERDICT: at least one suite went RED -- that change IS caught on host."
  fi
)
