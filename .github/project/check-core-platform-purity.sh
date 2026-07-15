#!/usr/bin/env bash
#
# Core platform-purity gate (REPORT-28 §36, law L7).
#
# The "headless core" milestone was UNFALSIFIABLE: check-core-shell-severance.py
# only counts a core extern when the symbol's sole first-party `pub export` lives
# in a Zig shell/ file. Every platform symbol core actually reaches -- ioFileOpen
# and friends (defined per target in src/{testSuite,c47-dmcp,c47-dmcp5}/hal/io.c)
# and the DMCP ROM trampolines (absolute LIBRARY_FN_BASE offsets) -- is a C symbol
# or an address, so the severance ratchet CANNOT see it. That number could reach
# zero while core still opened files and drove hardware timers.
#
# This gate closes that hole: core/ must be PLATFORM-FREE. A platform need crosses
# through abi.host (the Free42 shell-callback model already shipping in
# abi/host.zig), never by naming the platform symbol directly. Corollary: if a
# capability needs a per-target implementation (upstream proves it by keeping N
# copies under hal/), it does not belong in core.
#
# Ratchets on the COUNT OF CORE FILES that name a platform symbol; monotonic
# downward, exactly like the severance/cohesion ratchets.
#
# Usage: check-core-platform-purity.sh          # enforce
#        check-core-platform-purity.sh --bump   # re-pin after a real reduction
# Exit: 0 clean; 1 on a regression above the baseline.
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"
baseline_file=".github/project/core-platform-purity-baseline.json"

# Platform surfaces core must not name directly:
#   file I/O  -- the per-target hal/io.c surface
#   ROM/clock -- DMCP function-table trampolines and hardware timers
platform_re='\b(ioFileOpen|ioFileClose|ioFileRead|ioFileWrite|readLine|LIBRARY_FN_BASE|power_check_screen|sys_timer_disable|sys_timer_start|key_pop)\b'

mapfile -t offenders < <(git ls-files 'zig_src/core/*.zig' | xargs -r grep -lE "$platform_re" 2>/dev/null | sort)
count=${#offenders[@]}

baseline=$(grep -oE '"platform_files"[[:space:]]*:[[:space:]]*[0-9]+' "$baseline_file" | grep -oE '[0-9]+')

if [ "${1:-}" = "--bump" ]; then
    printf '{\n  "platform_files": %d,\n  "note": "REPORT-28 §36 L7: core files naming a platform symbol (hal/io.c surface or DMCP ROM). Monotonic downward -- core reaches the platform ONLY through abi.host."\n}\n' "$count" > "$baseline_file"
    echo "check-core-platform-purity: re-pinned platform_files baseline to $count"
    exit 0
fi

if [ "$count" -gt "$baseline" ]; then
    echo "CORE PLATFORM-PURITY REGRESSION: $count core files name a platform symbol (ceiling $baseline)."
    for f in "${offenders[@]}"; do
        echo "  $f -- $(grep -ohE "$platform_re" "$f" | sort -u | tr '\n' ' ')"
    done
    echo ""
    echo "core/ must be platform-free (L7): route the need through abi.host"
    echo "(install/call, like abi/host.zig already does for progress+render), or the"
    echo "owner belongs in shell/. Reduce the count -- do not raise the ceiling."
    exit 1
fi

echo "check-core-platform-purity: OK (core files reaching platform: $count <= ceiling $baseline)"
