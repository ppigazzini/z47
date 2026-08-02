#!/usr/bin/env bash
#
# Guard against the Windows LLP64 integer-width trap that broke the first all-Zig
# upstream resync (0caee2adc): a value cast to c_long / c_ulong is 64-bit on LP64
# (Linux/macOS) but 32-bit on Windows LLP64, so @intCast of a wider value silently
# truncates and PANICS at runtime on Win64 only — invisible to the Linux local
# gate, caught only by the Windows CI lane. saveStateValue cast a full 64-bit state
# word to c_ulong and panicked the Windows testSuite ("integer does not fit in
# destination type"). See [[c-abi-width-types-are-transliteration-debt]].
#
# The '@as(c_long, ...)' / '@as(c_ulong, ...)' cast syntax (and ': c_(u)long ='
# bindings with @intCast/@bitCast) only appears in value-carrying LOGIC — never in
# 'extern fn' type positions — so targeting it flags the trap without touching the
# ~90 legitimate GMP/libc ABI declarations. Casts provably bounded to <=32 bits are
# exempted two ways: an inline @truncate / '>> 32' on the same line, or an entry in
# portable-int-width-allowlist.txt (matched by trimmed line content). A genuine
# 64-bit value must be fixed (use i64/u64), NOT allowlisted.
#
# Usage: bash .github/project/check-portable-int-widths.sh
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

allowlist=".github/project/portable-int-width-allowlist.txt"

# Candidate trap sites: casts/bindings producing a platform-variant width value,
# minus the inline-truncated (provably <=32-bit) ones.
mapfile -t candidates < <(
  grep -rnE "@as\(c_(u?long), *@(int|bit)Cast|@as\(c_(u?long), *[a-zA-Z_]|: *c_(u?long) *=.*@(int|bit)Cast" \
    src/ build/ --include='*.zig' 2>/dev/null \
    | grep -vE "@truncate|>> *32" || true
)

# Allowed code snippets (trimmed), comments/blanks stripped.
mapfile -t allowed < <(grep -vE '^\s*(#|$)' "$allowlist" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')

trim() { sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//'; }

violations=0
matched_allow=()
for entry in "${candidates[@]}"; do
  # entry is path:line:code — strip the path:line: prefix, keep the code.
  code="$(printf '%s\n' "$entry" | sed -E 's/^[^:]+:[0-9]+://' | trim)"
  ok=0
  for a in "${allowed[@]}"; do
    if [[ "$code" == "$a" ]]; then ok=1; matched_allow+=("$a"); break; fi
  done
  if [[ "$ok" -eq 0 ]]; then
    if [[ "$violations" -eq 0 ]]; then
      echo "Windows LLP64 int-width trap: value-carrying cast to c_long/c_ulong." >&2
      echo "A c_(u)long is 32-bit on Win64; carrying a 64-bit value here truncates" >&2
      echo "and panics the Windows testSuite. Use i64/u64, or (only if the value is" >&2
      echo "provably <=32-bit) add the line to $allowlist with a justification." >&2
      echo >&2
    fi
    echo "  $entry" >&2
    violations=$((violations + 1))
  fi
done

# Report stale allowlist entries (present but no longer matched) so the allowlist
# does not rot into hidden risk. Informational, non-failing.
for a in "${allowed[@]}"; do
  hit=0
  for m in "${matched_allow[@]:-}"; do
    if [[ "$m" == "$a" ]]; then hit=1; break; fi
  done
  if [[ "$hit" -eq 0 ]]; then
    echo "note: stale allowlist entry (no longer present), please prune: $a"
  fi
done

if [[ "$violations" -gt 0 ]]; then
  echo >&2
  echo "FAIL: $violations un-allowlisted platform-width cast(s)." >&2
  exit 1
fi
echo "PASS: no un-allowlisted value-carrying c_long/c_ulong casts (${#candidates[@]} bounded sites allowlisted)."
