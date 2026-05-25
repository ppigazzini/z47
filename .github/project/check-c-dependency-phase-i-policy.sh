#!/usr/bin/env bash
set -euo pipefail

# Phase I policy:
# - Transitional mode: enforce baseline/no-regression while first-party count > 0.
# - External-only mode: once count reaches zero, also enforce strict zero caps.

repo_root="${1:-.}"

python3 .github/project/check-c-dependency-allowlist.py \
  --repo-root "$repo_root" \
  --config .github/project/c-dependency-allowlist.json

python3 .github/project/check-c-dependency-allowlist.py \
  --repo-root "$repo_root" \
  --config .github/project/c-dependency-product-allowlist.json

product_count="$({
  python3 .github/project/check-c-dependency-allowlist.py \
    --repo-root "$repo_root" \
    --config .github/project/c-dependency-product-allowlist.json \
    --print-first-party-count
} | tr -d '[:space:]')"

if [[ -z "$product_count" ]]; then
  echo "ERROR: could not determine product first-party dependency count" >&2
  exit 2
fi

if [[ "$product_count" == "0" ]]; then
  echo "Phase I policy: product first-party count is zero; enforcing strict zero gates."

  python3 .github/project/check-c-dependency-allowlist.py \
    --repo-root "$repo_root" \
    --config .github/project/c-dependency-product-allowlist.json \
    --max-first-party 0

  python3 .github/project/check-c-dependency-allowlist.py \
    --repo-root "$repo_root" \
    --config .github/project/c-dependency-allowlist.json \
    --max-first-party 0
else
  echo "Phase I policy: transitional baseline mode active (product first-party count: $product_count)."
fi
