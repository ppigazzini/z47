#!/usr/bin/env bash
#
# Formatting gate (REPORT-27 M-IDIOM-1): fail if any z47-owned Zig source is not
# canonically formatted by `zig fmt`. Idiomatic Zig is `zig fmt`-clean by
# definition; this gate keeps the tree that way so unformatted code cannot land.
#
# Scope: z47-owned Zig only (src/, build/, build.zig). The imported
# upstream tree (src/, dep/, ...) is never formatted or checked here -- it is a
# read-only audit input.
#
# Usage: check-fmt.sh          # enforce (zig fmt --check)
#        check-fmt.sh --fix     # rewrite files in place with zig fmt
# Exit: 0 if the tree is fully formatted; 1 on any unformatted file.
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

targets=(src build build.zig)

if [[ "${1:-}" == "--fix" ]]; then
  zig fmt "${targets[@]}"
  echo "check-fmt: formatted ${targets[*]}"
  exit 0
fi

if out="$(zig fmt --check "${targets[@]}" 2>&1)" && [[ -z "$out" ]]; then
  echo "check-fmt: OK (zig fmt clean across ${targets[*]})"
  exit 0
fi

echo "check-fmt: FAIL -- the following z47-owned Zig files are not zig fmt clean:" >&2
printf '%s\n' "$out" >&2
echo "check-fmt: run '.github/project/check-fmt.sh --fix' to format them." >&2
exit 1
