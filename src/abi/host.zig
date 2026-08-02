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

const builtin = @import("builtin");

const bool_t = u8; // the C-ABI bool the shell owners export (realType.h)

// Every build object that reaches the ABI seam compiles its own copy of this
// file, so a plain module-scope `var` gives each object a PRIVATE hook table:
// the shell's install would reach only the object the installer itself was
// compiled into, and every core owner would keep the headless defaults for the
// whole run. That is not a theoretical concern -- it silently killed the
// solver's mid-solve refreshScreen, and with it the softmenu/calcMode fixup
// upstream performs there, which showed up as a program's ENTER being swallowed
// by the equation editor a dozen tests later.
//
// So the storage lives in host_state.zig, compiled into exactly one object per
// executable, and every slot reaches it through its C-ABI symbol. Weak linkage
// looks like it would do the same job with no build wiring; it does not,
// portably -- see host_state.zig.
fn Slot(comptime Hook: type, comptime symbol: [:0]const u8) type {
    return struct {
        const shared: *?Hook = @extern(*?Hook, .{ .name = symbol });

        fn get() ?Hook {
            return shared.*;
        }

        fn install(hook: Hook) void {
            shared.* = hook;
        }

        fn clear() void {
            shared.* = null;
        }
    };
}

// The firmware links the shell unconditionally -- program_main IS the shell --
// so there each forwarder binds to it at link time and the hook table costs
// nothing at all. That is not a micro-optimisation: the DM42's .bss ends 20
// bytes below the DMCP system data block, and a seven-slot table does not fit.
// The installable table is what the host lanes and the headless parity
// harnesses use, where the shell may be absent and the bytes are free.
const binds_shell_at_link = builtin.target.os.tag == .freestanding;

fn shellFn(comptime Fn: type, comptime symbol: [:0]const u8) *const Fn {
    return @extern(*const Fn, .{ .name = symbol });
}

// exitKeyWaiting: poll whether the user asked the running computation to abort
// (the EXIT key). The default reports "no abort pending", which is exactly the
// non-interactive behaviour the parity oracles rely on.
const exit_key_waiting_hook = Slot(*const fn () callconv(.c) bool_t, "z47HostExitKeyWaitingHook");

/// Install the shell's abort-poll implementation. Called once at app startup.
pub fn installExitKeyWaiting(hook: *const fn () callconv(.c) bool_t) void {
    if (binds_shell_at_link) return; // bound at link time; there is no slot to fill
    exit_key_waiting_hook.install(hook);
}

/// True when the user has asked the running computation to stop. Reports false
/// when the core runs headless (no hook installed).
pub fn exitKeyWaiting() bool {
    if (binds_shell_at_link) return shellFn(fn () callconv(.c) bool_t, "exitKeyWaiting")() != 0;
    const hook = exit_key_waiting_hook.get() orelse return false;
    return hook() != 0;
}

// checkHalfSec: has the half-second progress interval elapsed? The long
// computations poll it to decide when to refresh their on-screen progress. The
// default reports "not elapsed", so a headless core never takes the progress
// branch -- exactly the non-interactive behaviour.
const check_half_sec_hook = Slot(*const fn () callconv(.c) bool_t, "z47HostCheckHalfSecHook");

/// Install the shell's half-second progress-clock implementation.
pub fn installCheckHalfSec(hook: *const fn () callconv(.c) bool_t) void {
    if (binds_shell_at_link) return; // bound at link time; there is no slot to fill
    check_half_sec_hook.install(hook);
}

/// True when the half-second progress interval has elapsed. Reports false when
/// the core runs headless (no hook installed).
pub fn checkHalfSec() bool {
    if (binds_shell_at_link) return shellFn(fn () callconv(.c) bool_t, "checkHalfSec")() != 0;
    const hook = check_half_sec_hook.get() orelse return false;
    return hook() != 0;
}

// progressHalfSecUpdate_Integer: refresh the on-screen progress line of a long
// computation with an iteration label and counter, returning whether the user
// interrupted. The default reports "no interrupt", so a headless core runs to
// completion -- exactly the non-interactive behaviour. The hook keeps the shell
// owner's C-ABI shape (char* label, byte booleans); the forwarder exposes an
// idiomatic sentinel-string / bool signature to the callers.
const progress_half_sec_hook = Slot(*const fn (u8, [*c]u8, i32, bool_t, bool_t, bool_t) callconv(.c) bool_t, "z47HostProgressHalfSecHook");

/// Install the shell's progress-line refresh implementation.
pub fn installProgressHalfSec(hook: *const fn (u8, [*c]u8, i32, bool_t, bool_t, bool_t) callconv(.c) bool_t) void {
    if (binds_shell_at_link) return; // bound at link time; there is no slot to fill
    progress_half_sec_hook.install(hook);
}

/// Refresh the progress line; returns true when the user interrupted. Reports
/// false (no interrupt) when the core runs headless (no hook installed).
pub fn progressHalfSecUpdate_Integer(mode: u8, txt: [*:0]const u8, loop: i32, clearZ: bool, clearT: bool, disp: bool) bool {
    if (binds_shell_at_link) {
        const shell = shellFn(fn (u8, [*c]u8, i32, bool_t, bool_t, bool_t) callconv(.c) bool_t, "progressHalfSecUpdate_Integer");
        return shell(mode, @constCast(txt), loop, @intFromBool(clearZ), @intFromBool(clearT), @intFromBool(disp)) != 0;
    }
    const hook = progress_half_sec_hook.get() orelse return false;
    return hook(mode, @constCast(txt), loop, @intFromBool(clearZ), @intFromBool(clearT), @intFromBool(disp)) != 0;
}

// requestRefresh (refreshScreen): the core signals the shell that the display is
// dirty and should redraw; the u16 argument is an upstream debug tag for the
// refresh source. The default is a no-op, which matches the no-op refreshScreen
// fakes the parity harnesses link. The shell installs its implementation once at
// startup, before any core code runs, so no interactive redraw is lost.
const request_refresh_hook = Slot(*const fn (u16) callconv(.c) void, "z47HostRequestRefreshHook");

/// Install the shell's screen-refresh implementation.
pub fn installRequestRefresh(hook: *const fn (u16) callconv(.c) void) void {
    if (binds_shell_at_link) return; // bound at link time; there is no slot to fill
    request_refresh_hook.install(hook);
}

/// Signal the host that the display should redraw. A no-op when the core runs
/// headless (no hook installed).
pub fn requestRefresh(source: u16) void {
    if (binds_shell_at_link) return shellFn(fn (u16) callconv(.c) void, "refreshScreen")(source);
    const hook = request_refresh_hook.get() orelse return;
    hook(source);
}

// reportBugError: the defensive branch of error reporting. It fires only for an
// out-of-range error code or register line (a programming error, never a normal
// calculation error), so the core hands the two raw values to the shell, which
// formats the diagnostic string and paints the bug screen. The default is a
// no-op, so a headless core simply ignores the malformed report.
const report_bug_error_hook = Slot(*const fn (u8, i16) callconv(.c) void, "z47HostReportBugErrorHook");

/// Install the shell's bug-screen reporter.
pub fn installReportBugError(hook: *const fn (u8, i16) callconv(.c) void) void {
    if (binds_shell_at_link) return; // bound at link time; there is no slot to fill
    report_bug_error_hook.install(hook);
}

/// Report a malformed error code / register line to the host for display. A
/// no-op when the core runs headless (no hook installed).
pub fn reportBugError(errorCode: u8, errMessageRegisterLine: i16) void {
    if (binds_shell_at_link) return shellFn(fn (u8, i16) callconv(.c) void, "reportBugError")(errorCode, errMessageRegisterLine);
    const hook = report_bug_error_hook.get() orelse return;
    hook(errorCode, errMessageRegisterLine);
}

// showBugScreen: paint the full-screen internal-error report with a formatted
// message the core already built. Genuine UI; a no-op when the core runs
// headless, which matches the no-op displayBugScreen fakes the harnesses link.
const show_bug_screen_hook = Slot(*const fn ([*:0]const u8) callconv(.c) void, "z47HostShowBugScreenHook");

/// Install the shell's bug-screen renderer.
pub fn installShowBugScreen(hook: *const fn ([*:0]const u8) callconv(.c) void) void {
    if (binds_shell_at_link) return; // bound at link time; there is no slot to fill
    show_bug_screen_hook.install(hook);
}

/// Paint the internal-error bug screen with the given message. A no-op when the
/// core runs headless (no hook installed).
pub fn showBugScreen(msg: [*c]const u8) void {
    if (binds_shell_at_link) return shellFn(fn ([*c]const u8) callconv(.c) void, "displayBugScreen")(msg);
    const hook = show_bug_screen_hook.get() orelse return;
    hook(msg);
}

// reportBadTypeDetail: the debug-only enrichment appended to a bad-register-type
// error -- the human-readable register data-type name. Pure diagnostics; the
// shell formats and appends it (it owns the type-name table and the info line).
// A no-op when the core runs headless or the extra-info diagnostics are off.
const report_bad_type_detail_hook = Slot(*const fn (i16) callconv(.c) void, "z47HostReportBadTypeDetailHook");

/// Install the shell's bad-register-type diagnostic enrichment.
pub fn installReportBadTypeDetail(hook: *const fn (i16) callconv(.c) void) void {
    if (binds_shell_at_link) return; // bound at link time; there is no slot to fill
    report_bad_type_detail_hook.install(hook);
}

/// Append the register data-type name to a bad-type error report. A no-op when
/// the core runs headless (no hook installed).
pub fn reportBadTypeDetail(reg: i16) void {
    if (binds_shell_at_link) return shellFn(fn (i16) callconv(.c) void, "reportBadTypeDetail")(reg);
    const hook = report_bad_type_detail_hook.get() orelse return;
    hook(reg);
}

const std = @import("std");
const testing = std.testing;

test "exitKeyWaiting defaults to no-abort until a hook is installed" {
    exit_key_waiting_hook.clear();
    try testing.expect(!exitKeyWaiting());
}

test "exitKeyWaiting reports the installed hook's result" {
    const S = struct {
        fn yes() callconv(.c) bool_t {
            return 1;
        }
    };
    installExitKeyWaiting(&S.yes);
    defer exit_key_waiting_hook.clear();
    try testing.expect(exitKeyWaiting());
}
