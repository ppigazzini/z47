#!/usr/bin/env bash
set -euo pipefail

repo_root="${1:-.}"

refresh_args=(
  --repo-root "$repo_root"
  --fetch
  --head-rev upstream/master
  --max-commits 120
  --max-paths 200
)

echo "[1/4] Upstream refresh report"
python3 .github/project/report-upstream-refresh.py "${refresh_args[@]}"

echo
echo "[2/4] Upstream pin and ledger validation"
python3 .github/project/check-upstream-port-ledger.py --repo-root "$repo_root"

echo
echo "[3/4] C dependency status split"
python3 .github/project/report-c-dependency-status.py --repo-root "$repo_root"

echo
echo "[4/5] Product first-party C strict-cap check (target: 0)"
if python3 .github/project/check-c-dependency-allowlist.py \
  --repo-root "$repo_root" \
  --config .github/project/c-dependency-product-allowlist.json \
  --max-first-party 0; then
  echo "PASS: strict product first-party C cap is satisfied."
else
  echo "FAIL: strict product first-party C cap is not yet satisfied." >&2
  exit 1
fi

