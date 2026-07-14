// SPDX-License-Identifier: GPL-3.0-only
//
// The host-callback boundary between the headless core and the interactive
// shell. The core signals the host through this installable hook table instead
// of linking the shell owners directly, so the core keeps no link-time
// dependency on the shell (the headless-engine severance goal). The host
// installs its implementations once at app startup; every hook defaults to a
// neutral value so an uninstalled core -- the parity harnesses and headless
// fuzzing -- runs correctly.
//
// This is the transitional home of the `core/host` port from the architecture
// design: it lives in the ABI seam because both zones already depend on the
// seam, so no owner reaches across the engine/shell boundary to reach it. Later
// capabilities (redraw, progress, text metrics) extend this table.

const bool_t = u8; // the C-ABI bool the shell owners export (realType.h)

// exitKeyWaiting: poll whether the user asked the running computation to abort
// (the EXIT key). The default reports "no abort pending", which is exactly the
// non-interactive behaviour the parity oracles rely on.
var exit_key_waiting_hook: ?*const fn () callconv(.c) bool_t = null;

/// Install the shell's abort-poll implementation. Called once at app startup.
pub fn installExitKeyWaiting(hook: *const fn () callconv(.c) bool_t) void {
    exit_key_waiting_hook = hook;
}

/// True when the user has asked the running computation to stop. Reports false
/// when the core runs headless (no hook installed).
pub fn exitKeyWaiting() bool {
    const hook = exit_key_waiting_hook orelse return false;
    return hook() != 0;
}

const std = @import("std");
const testing = std.testing;

test "exitKeyWaiting defaults to no-abort until a hook is installed" {
    exit_key_waiting_hook = null;
    try testing.expect(!exitKeyWaiting());
}

test "exitKeyWaiting reports the installed hook's result" {
    const S = struct {
        fn yes() callconv(.c) bool_t {
            return 1;
        }
    };
    installExitKeyWaiting(&S.yes);
    defer exit_key_waiting_hook = null;
    try testing.expect(exitKeyWaiting());
}
