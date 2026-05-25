#!/usr/bin/env bash
set -euo pipefail

repo_root="${1:-.}"
cd "$repo_root"

violations=0
while IFS= read -r file; do
  if rg -n "__DEV/" "$file" >/dev/null; then
    echo "CI locality violation in $file:" >&2
    rg -n "__DEV/" "$file" >&2
    violations=1
  fi
done < <(find .github/workflows -maxdepth 1 -type f \( -name "*.yml" -o -name "*.yaml" \) | sort)

if [[ "$violations" -ne 0 ]]; then
  echo >&2
  echo "ERROR: CI workflows must not reference local-only __DEV scripts." >&2
  exit 1
fi

echo "PASS: no __DEV workflow references found."
