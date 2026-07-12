#!/usr/bin/env bash
# rename-owner.sh — batch prefix-strip / move a z47 owner .zig file and sweep
# EVERY reference to it: repo-wide @import bare names, the per-dir aggregator,
# AND the build-system path literals (build.zig pure_modules + zig_build module
# roots) that a naive @import-only sweep misses. Runs a collision pre-check and
# preserves the semantic suffix strata the idiom ratchet keys on.
#
# See REPORT-28 §12 (design) and §14.2/§15b (why state/ is NOT an in-place strip
# and why one shortint file is skipped).
#
# Usage:
#   rename-owner.sh check  <dir> <prefix>    # dry-run collision + skip report
#   rename-owner.sh map    <dir> <prefix>    # emit old<TAB>new rename map (stdout)
#   rename-owner.sh apply  <mapfile>         # git mv + sweep all references
#   rename-owner.sh verify                   # assert no dangling owner @import
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

# Semantic suffixes the idiom ratchet (report-idiom-status.py) special-cases.
# A rename must never DROP one of these classifications. Stripping the *leading*
# dir prefix preserves a trailing suffix (math_x_export.zig -> x_export.zig), so
# the only danger is the degenerate case where the prefix stem IS the suffix
# token (shortint_runtime.zig -> runtime.zig loses the _runtime.zig ending).
PROTECTED_SUFFIXES=(_runtime.zig _shared.zig _export.zig _owned.zig)

# Files whose reference literals must be swept.
ref_files() { git ls-files 'zig_src/**/*.zig' 'zig_build/**/*.zig' build.zig \
                          '.github/project/upstream-port-ledger.tsv'; }

# Would stripping <prefix> from <basename> drop a protected suffix classification?
drops_protection() { # $1 = original basename, $2 = stripped basename
  local orig="$1" strip="$2" suf
  for suf in "${PROTECTED_SUFFIXES[@]}"; do
    case "$orig"  in *"$suf") case "$strip" in *"$suf") ;; *) return 0;; esac;; esac
  done
  return 1
}

cmd="${1:?check|map|apply|verify}"; shift || true

case "$cmd" in
check)
  dir="zig_src/${1:?dir}"; pre="${2:?prefix}"
  echo "# collision + protection pre-check for $dir (strip '$pre')"
  skipped=0
  for f in "$dir/$pre"*.zig; do
    [ -e "$f" ] || continue
    b=$(basename "$f"); s="${b#"$pre"}"
    if drops_protection "$b" "$s"; then echo "SKIP (would drop protected suffix): $b"; skipped=$((skipped+1)); fi
  done
  self=$(for f in "$dir/$pre"*.zig; do [ -e "$f" ] || continue; b=$(basename "$f"); s="${b#"$pre"}"
           drops_protection "$b" "$s" && continue; echo "$s"; done | sort | uniq -d)
  exist=$(comm -12 \
     <(for f in "$dir/$pre"*.zig; do [ -e "$f" ] || continue; b=$(basename "$f"); s="${b#"$pre"}"
         drops_protection "$b" "$s" && continue; echo "$s"; done | sort -u) \
     <(git ls-files "$dir/*.zig" | xargs -n1 basename | grep -v "^$pre" | sort -u) || true)
  n1=$(printf '%s' "$self"  | grep -c . || true)
  n2=$(printf '%s' "$exist" | grep -c . || true)
  echo "protected-skips: $skipped ; self-collisions: $n1 ; collide-with-existing: $n2"
  [ -n "$self" ]  && echo "$self"
  [ -n "$exist" ] && echo "$exist"
  [ "$n1" -eq 0 ] && [ "$n2" -eq 0 ] && echo "OK: safe to strip (skipping $skipped protected)"
  ;;
map)
  dir="zig_src/${1:?dir}"; pre="${2:?prefix}"
  for f in "$dir/$pre"*.zig; do
    [ -e "$f" ] || continue
    b=$(basename "$f"); s="${b#"$pre"}"
    drops_protection "$b" "$s" && continue      # skip protected-suffix collapse
    printf '%s\t%s/%s\n' "$f" "$dir" "$s"
  done
  ;;
apply)
  mapfile="${1:?mapfile}"
  awk -F'\t' 'NF{print $2}' "$mapfile" | sort | uniq -d | grep -q . && {
    echo "ABORT: batch produces duplicate targets"; exit 1; }
  while IFS=$'\t' read -r old new; do
    [ -n "$old" ] || continue
    oldb=$(basename "$old"); newb=$(basename "$new")
    git mv "$old" "$new"
    # (1) bare-name @imports, repo-wide. A legitimate "no match" is not an error;
    # guard the pipeline so set -e/pipefail does not abort the batch.
    { grep -rlZ "@import(\"$oldb\")" $(ref_files) 2>/dev/null || true; } \
      | { xargs -0 -r sed -i "s#@import(\"$oldb\")#@import(\"$newb\")#g" || true; }
    # (2) build-system path literals (b.path("zig_src/..") + bare string literals)
    { grep -rlZ -- "$old" $(ref_files) 2>/dev/null || true; } \
      | { xargs -0 -r sed -i "s#$old#$new#g" || true; }
  done < "$mapfile"
  ;;
verify)
  bad=0
  for tgt in $(grep -rho '@import("[a-z_0-9]*\.zig")' zig_src | sed -E 's/@import\("(.*)"\)/\1/' | sort -u); do
    git ls-files "zig_src/**/$tgt" | grep -q . || { echo "DANGLING @import: $tgt"; bad=1; }
  done
  [ $bad -eq 0 ] && echo "verify OK: no dangling owner @imports"
  ;;
*) echo "unknown: $cmd"; exit 2;;
esac
