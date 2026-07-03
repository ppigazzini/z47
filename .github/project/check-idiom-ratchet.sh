#!/usr/bin/env bash
#
# Idiom ratchet (REPORT-23 §11): fail if any transliteration anti-pattern in
# zig_src grew above its committed ceiling in idiom-status-baseline.json. The
# ceilings are monotonic downward -- they protect the idiomatic-refactor progress
# so a later change cannot quietly re-add [*c]/@ptrCast/extern-struct debt. Lower
# a ceiling in the same commit that removes the debt (with --bump).
#
# Usage: check-idiom-ratchet.sh          # enforce
#        check-idiom-ratchet.sh --bump   # rewrite the baseline to current values
# Exit: 0 if every metric <= its ceiling; 1 on any regression.
#
# Per REPORT-23 §11 this is NOT wired blocking into CI until Phase 2 (to avoid
# churn while the L1 foundation lands); it is runnable now as the local gate.
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

if [[ "${1:-}" == "--bump" ]]; then
    python3 .github/project/report-idiom-status.py --repo-root . --write-baseline
    exit 0
fi

python3 .github/project/report-idiom-status.py --repo-root . --check
