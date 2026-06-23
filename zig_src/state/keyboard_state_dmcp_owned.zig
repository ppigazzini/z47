// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for the firmware-only (`#if defined(DMCP_BUILD)`) keyboard handlers
// that the retired keyboard_state_legacy.c bridge once compiled out of keyboard.c.
// These are not reachable from the host sim or testSuite (they bind DMCP key-event
// ROM surfaces), so they are verified by build/link across the firmware targets +
// faithful-port review, then exported onto the DMCP lanes while the bridge renames
// the C copies away.
const std = @import("std");
const builtin = @import("builtin");

const is_dmcp_build = builtin.target.os.tag == .freestanding;
const bool_t = bool;

// defines.h
const TO_AUTO_REPEAT: u8 = 7;
const KEY_AUTOREPEAT_PERIOD: u32 = 200;

// Globals / helpers resolved from the C core or other Zig owners on firmware.
extern var shiftF: bool_t;
extern var shiftG: bool_t;
extern var screenUpdatingMode: u8;
extern fn sprintf(buf: [*c]u8, fmt: [*:0]const u8, ...) c_int;
extern fn fnTimerStart(nr: u8, param: u16, time: u32) void;
extern fn btnClicked(unused: ?*anyopaque, data: ?*anyopaque) void;

// refreshLcd is `void refreshLcd(void)` on DMCP (screen.c); the keyboard runtime
// binds the divergent PC_BUILD signature (gboolean refreshLcd(gpointer)), so bind
// the DMCP view here by symbol name. lcd_refresh_dma is a DMCP ROM function-table
// macro (lft_ifc.h, LIBRARY_FN_BASE + 644).
const refreshLcd = @extern(*const fn () callconv(.c) void, .{ .name = "refreshLcd" });
const LIBRARY_FN_BASE: usize = if (builtin.target.cpu.model == &std.Target.arm.cpu.cortex_m4) 0x08000201 else 0x08000301;
fn lcdRefreshDma() void {
    const f: *const fn () callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 644);
    f();
}

// keyboard.c execAutoRepeat (the #if DMCP_BUILD body): on the auto-repeat timer,
// re-fire the held key through btnClicked, preserving the f/g shift state and the
// screen-updating mode across the click, then force an LCD refresh.
fn execAutoRepeat(key: u16) callconv(.c) void {
    var char_key: [6]u8 = undefined;
    const f = shiftF;
    const g = shiftG;
    const orig_screen_updating_mode = screenUpdatingMode;
    _ = sprintf(&char_key[0], "%02d", @as(c_int, key) - 1);

    fnTimerStart(TO_AUTO_REPEAT, key, KEY_AUTOREPEAT_PERIOD);

    btnClicked(null, @ptrCast(&char_key[0]));
    screenUpdatingMode = orig_screen_updating_mode;
    shiftF = f;
    shiftG = g;
    refreshLcd();
    lcdRefreshDma();
}

comptime {
    if (is_dmcp_build) {
        @export(&execAutoRepeat, .{ .name = "execAutoRepeat" });
    }
}
