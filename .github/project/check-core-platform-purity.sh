#!/usr/bin/env bash
#
# Core platform-leak gate (REPORT-28 §38, law L8). Supersedes the §36 version,
# which was WRONG in a way worth recording so it is not re-introduced.
#
# THE §36 ERROR: it treated every platform symbol core names as a violation and
# ratcheted the count toward 0. But ioFileOpen/ioFileClose/ioFileRead/ioFileWrite/
# readLine ARE upstream's hal (src/c47/hal/io.h), and upstream's OWN library calls
# them (saveRestoreCalcState.c, saveRestorePrograms.c, saveRestoreBackup.c).
# CALLING THE HAL IS THE ARCHITECTURE -- it is how a platform-independent library
# does I/O. Driving that to zero would mean core may not do file I/O at all, which
# upstream does. The gate's success condition would have been a PARITY VIOLATION.
#
# WHAT IS ACTUALLY WRONG: symbols that are NOT in any hal header -- the raw DMCP
# ROM/hardware entries (LIBRARY_FN_BASE offsets, power_check_screen, sys_timer_*,
# key_pop). Upstream leaks those into its own library too (key_pop in 7 src/c47
# files, sys_timer_start in 4, power_check_screen in 2), so z47's copies are
# FAITHFUL PORTS, frozen under law L6 (parity outranks purity), NOT debt.
#
# SO THIS GATE ASKS THE ONE QUESTION THAT HAS A RIGHT ANSWER:
#   "Did z47 introduce a platform reach that upstream does not have?"
# It is FROZEN at upstream-parity, not ratcheted to 0. Absorbing upstream's leak
# into the hal is a conscious value-add deviation (§37 class (b)) to be planned --
# never a silent ratchet.
#
# Usage: check-core-platform-purity.sh          # enforce
#        check-core-platform-purity.sh --bump   # re-pin (only with justification)
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"
baseline_file=".github/project/core-platform-purity-baseline.json"

# NOT flagged: the sanctioned hal surface (src/c47/hal/*.h) -- ioFile*, readLine,
# lcd_*, audio, print_ir, gui. Core is SUPPOSED to call these.
# Flagged: platform reach with NO hal contract behind it.
leak_re='\b(LIBRARY_FN_BASE|power_check_screen|sys_timer_disable|sys_timer_start|key_pop)\b'

mapfile -t offenders < <(git ls-files 'src/core/*.zig' | xargs -r grep -lE "$leak_re" 2>/dev/null | sort)
count=${#offenders[@]}
baseline=$(grep -oE '"platform_leak_files"[[:space:]]*:[[:space:]]*[0-9]+' "$baseline_file" | grep -oE '[0-9]+')

if [ "${1:-}" = "--bump" ]; then
    printf '{\n  "platform_leak_files": %d,\n  "note": "REPORT-28 §38 L8: core files reaching platform WITHOUT a hal contract (raw DMCP ROM/timers/keys). FROZEN at upstream parity -- upstream leaks these into its own library too, so z47 copies are faithful ports (L6). This is a NON-REGRESSION guard: it answers only \\"did z47 add a platform reach upstream does not have?\\". Calling the hal (ioFile*, readLine, lcd_*) is CORRECT and is not counted."\n}\n' "$count" > "$baseline_file"
    echo "check-core-platform-purity: re-pinned platform_leak_files baseline to $count"
    exit 0
fi

if [ "$count" -gt "$baseline" ]; then
    echo "CORE PLATFORM LEAK: $count core files reach the platform with no hal contract (frozen ceiling $baseline)."
    for f in "${offenders[@]}"; do
        echo "  $f -- $(grep -ohE "$leak_re" "$f" | sort -u | tr '\n' ' ')"
    done
    echo ""
    echo "z47 must not leak MORE platform than upstream does (L8). Route the need"
    echo "through the hal contract (src/c47/hal/*.h -- ioFile*, lcd_*, audio, gui,"
    echo "print_ir), which core is free to call. Do not raise the ceiling: the"
    echo "existing entries are faithful ports of upstream's own leak and are frozen."
    exit 1
fi

echo "check-core-platform-purity: OK (non-hal platform leaks: $count <= frozen $baseline; hal calls are correct and uncounted)"
