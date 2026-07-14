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

// checkHalfSec: has the half-second progress interval elapsed? The long
// computations poll it to decide when to refresh their on-screen progress. The
// default reports "not elapsed", so a headless core never takes the progress
// branch -- exactly the non-interactive behaviour.
var check_half_sec_hook: ?*const fn () callconv(.c) bool_t = null;

/// Install the shell's half-second progress-clock implementation.
pub fn installCheckHalfSec(hook: *const fn () callconv(.c) bool_t) void {
    check_half_sec_hook = hook;
}

/// True when the half-second progress interval has elapsed. Reports false when
/// the core runs headless (no hook installed).
pub fn checkHalfSec() bool {
    const hook = check_half_sec_hook orelse return false;
    return hook() != 0;
}

// progressHalfSecUpdate_Integer: refresh the on-screen progress line of a long
// computation with an iteration label and counter, returning whether the user
// interrupted. The default reports "no interrupt", so a headless core runs to
// completion -- exactly the non-interactive behaviour. The hook keeps the shell
// owner's C-ABI shape (char* label, byte booleans); the forwarder exposes an
// idiomatic sentinel-string / bool signature to the callers.
var progress_half_sec_hook: ?*const fn (u8, [*c]u8, i32, bool_t, bool_t, bool_t) callconv(.c) bool_t = null;

/// Install the shell's progress-line refresh implementation.
pub fn installProgressHalfSec(hook: *const fn (u8, [*c]u8, i32, bool_t, bool_t, bool_t) callconv(.c) bool_t) void {
    progress_half_sec_hook = hook;
}

/// Refresh the progress line; returns true when the user interrupted. Reports
/// false (no interrupt) when the core runs headless (no hook installed).
pub fn progressHalfSecUpdate_Integer(mode: u8, txt: [*:0]const u8, loop: i32, clearZ: bool, clearT: bool, disp: bool) bool {
    const hook = progress_half_sec_hook orelse return false;
    return hook(mode, @constCast(txt), loop, @intFromBool(clearZ), @intFromBool(clearT), @intFromBool(disp)) != 0;
}

// requestRefresh (refreshScreen): the core signals the shell that the display is
// dirty and should redraw; the u16 argument is an upstream debug tag for the
// refresh source. The default is a no-op, which matches the no-op refreshScreen
// fakes the parity harnesses link. The shell installs its implementation once at
// startup, before any core code runs, so no interactive redraw is lost.
var request_refresh_hook: ?*const fn (u16) callconv(.c) void = null;

/// Install the shell's screen-refresh implementation.
pub fn installRequestRefresh(hook: *const fn (u16) callconv(.c) void) void {
    request_refresh_hook = hook;
}

/// Signal the host that the display should redraw. A no-op when the core runs
/// headless (no hook installed).
pub fn requestRefresh(source: u16) void {
    const hook = request_refresh_hook orelse return;
    hook(source);
}

// reportBugError: the defensive branch of error reporting. It fires only for an
// out-of-range error code or register line (a programming error, never a normal
// calculation error), so the core hands the two raw values to the shell, which
// formats the diagnostic string and paints the bug screen. The default is a
// no-op, so a headless core simply ignores the malformed report.
var report_bug_error_hook: ?*const fn (u8, i16) callconv(.c) void = null;

/// Install the shell's bug-screen reporter.
pub fn installReportBugError(hook: *const fn (u8, i16) callconv(.c) void) void {
    report_bug_error_hook = hook;
}

/// Report a malformed error code / register line to the host for display. A
/// no-op when the core runs headless (no hook installed).
pub fn reportBugError(errorCode: u8, errMessageRegisterLine: i16) void {
    const hook = report_bug_error_hook orelse return;
    hook(errorCode, errMessageRegisterLine);
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
