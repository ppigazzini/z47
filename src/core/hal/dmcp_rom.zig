// SPDX-License-Identifier: GPL-3.0-only
//
// DMCP ROM function-table shims for the state save/restore owners
// (calc_state_io_owned, program_serialization_io_owned). power_check_screen,
// sys_timer_disable and sys_timer_start are DMCP library function-table macros
// (lft_ifc.h), not linkable symbols, so a Zig extern cannot resolve them on
// firmware. This module reconstructs them as lane-aware ROM trampolines. On
// host (no power button / DMCP timers) they are trivial no-ops.
//
// Offsets verified against lft_ifc.h: power_check_screen LIBRARY_FN_BASE+340,
// sys_disk_write_enable +480, sys_timer_disable +500, sys_timer_start +504,
// f_unlink +768. LIBRARY_FN_BASE is selected by
// the firmware cpu model (cortex-m4 = old_hw, else cortex-m33). Verified by
// build/link across every target (the established frontier ROM-trampoline
// pattern; these are not testSuite-reachable).
const std = @import("std");
const builtin = @import("builtin");

const is_dmcp_build = builtin.target.os.tag == .freestanding;
const LIBRARY_FN_BASE: usize = if (builtin.target.cpu.model == &std.Target.arm.cpu.cortex_m4) 0x08000201 else 0x08000301;

const PowerCheckScreenFn = *const fn () callconv(.c) c_int;
const SysTimerDisableFn = *const fn (timer_ix: c_int) callconv(.c) void;
const SysTimerStartFn = *const fn (timer_ix: c_int, ms_value: u32) callconv(.c) void;
const SysDiskWriteEnableFn = *const fn (val: c_int) callconv(.c) c_int;
const FUnlinkFn = *const fn (path: [*:0]const u8) callconv(.c) c_uint;

fn powerCheckScreenNoop() callconv(.c) c_int {
    return 0;
}
fn sysTimerDisableNoop(timer_ix: c_int) callconv(.c) void {
    _ = timer_ix;
}
fn sysTimerStartNoop(timer_ix: c_int, ms_value: u32) callconv(.c) void {
    _ = timer_ix;
    _ = ms_value;
}
fn sysDiskWriteEnableNoop(val: c_int) callconv(.c) c_int {
    _ = val;
    return 0;
}
fn fUnlinkNoop(path: [*:0]const u8) callconv(.c) c_uint {
    _ = path;
    return 0;
}

// Function-pointer defaults keep the firmware/host split to a single comptime
// `if`, with no parameter discard in the trampoline bodies (which the comptime
// branches would otherwise flag as pointless).
const power_check_screen_impl: PowerCheckScreenFn = if (is_dmcp_build) @ptrFromInt(LIBRARY_FN_BASE + 340) else &powerCheckScreenNoop;
const sys_timer_disable_impl: SysTimerDisableFn = if (is_dmcp_build) @ptrFromInt(LIBRARY_FN_BASE + 500) else &sysTimerDisableNoop;
const sys_timer_start_impl: SysTimerStartFn = if (is_dmcp_build) @ptrFromInt(LIBRARY_FN_BASE + 504) else &sysTimerStartNoop;
const sys_disk_write_enable_impl: SysDiskWriteEnableFn = if (is_dmcp_build) @ptrFromInt(LIBRARY_FN_BASE + 480) else &sysDiskWriteEnableNoop;
const f_unlink_impl: FUnlinkFn = if (is_dmcp_build) @ptrFromInt(LIBRARY_FN_BASE + 768) else &fUnlinkNoop;

pub fn power_check_screen() bool {
    return power_check_screen_impl() != 0;
}
pub fn sys_timer_disable(timer_ix: c_int) void {
    sys_timer_disable_impl(timer_ix);
}
pub fn sys_timer_start(timer_ix: c_int, ms_value: u32) void {
    sys_timer_start_impl(timer_ix, ms_value);
}
pub fn sys_disk_write_enable(val: c_int) c_int {
    return sys_disk_write_enable_impl(val);
}
pub fn f_unlink(path: [*:0]const u8) c_uint {
    return f_unlink_impl(path);
}
