// SPDX-License-Identifier: GPL-3.0-only
//
// The DMCP ROM function table, the one place a build object declares it. Every
// lft_ifc.h macro an owner calls is one entry below, named as the SDK names it
// and typed by its dmcp.h or ff_ifc.h prototype: lcd_refresh, for one, is the
// function at LIBRARY_FN_BASE + 48. None of them is a linkable symbol, so a Zig
// extern cannot resolve them on firmware. LIBRARY_FN_BASE and the system data
// block address come from the board's SDK headers, through the build options;
// both are 0 on host, which has neither.
//
// An entry points into a ROM only the calculator has, so only firmware code may
// call one: an owner reaches the table from inside its
// `if (comptime dmcp_build)`-style branch, and keeps its own host path beside it.
// powerCheckScreen wraps power_check_screen with a host answer, for the state
// owners that call it on both lanes.
//
// get_flag_dmy, set_flag_dmy, is_flag_clk24 and set_flag_clk24 are not in the
// table: they are function pointers in the system data block (dmcp.h), read here
// on firmware and no-ops on host.
//
// rtc_read and rtc_write take abi's dt_t and tm_t, so an object whose owners
// call them gives this module its `abi` import.
const abi = @import("abi");
const builtin = @import("builtin");
const dmcp_rom_build_options = @import("dmcp_rom_build_options");

const is_dmcp_build = builtin.target.os.tag == .freestanding;
const LIBRARY_FN_BASE: usize = dmcp_rom_build_options.library_fn_base;

// The SDK's display state (dmcp.h disp_stat_t), only ever handed back to the ROM.
pub const disp_stat_t = opaque {};

// FatFs (ff_ifc.h). FRESULT is an enum with no negative value, which GCC lays out
// as unsigned int.
pub const FRESULT = u32;
pub const UINT = c_uint;
pub const FSIZE_t = u32;
const FATFS = opaque {};
const _FDID = extern struct {
    fs: ?*FATFS,
    id: u16,
    attr: u8,
    stat: u8,
    sclust: u32,
    objsize: FSIZE_t,
    lockid: UINT,
};
pub const FIL = extern struct {
    obj: _FDID,
    flag: u8,
    err: u8,
    fptr: FSIZE_t,
    clust: u32,
    sect: u32,
    dir_sect: u32,
    dir_ptr: ?[*]u8,
    cltbl: ?[*]u32,
    buf: [512]u8,
};

// lft_ifc.h, in table order.
pub const LCD_power_on: *const fn () callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 24);
pub const LCD_power_off: *const fn (clear: c_int) callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 28);
pub const LCD_write_line: *const fn (buf: [*]u8) callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 32);
pub const bitblt24: *const fn (x: u32, dx: u32, y: u32, val: u32, blt_op: c_int, fill: c_int) callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 36);
pub const lcd_line_addr: *const fn (y: c_int) callconv(.c) [*]u8 = @ptrFromInt(LIBRARY_FN_BASE + 40);
pub const lcd_clear_buf: *const fn () callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 44);
pub const lcd_refresh: *const fn () callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 48);
pub const lcd_forced_refresh: *const fn () callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 52);
pub const lcd_refresh_lines: *const fn (ln: c_int, cnt: c_int) callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 56);
pub const lcd_fill_rect: *const fn (x: u32, y: u32, dx: u32, dy: u32, val: c_int) callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 60);
pub const lcd_set_buf_cleared: *const fn (val: c_int) callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 84);
pub const lcd_get_buf_cleared: *const fn () callconv(.c) c_int = @ptrFromInt(LIBRARY_FN_BASE + 88);
pub const lcd_setLine: *const fn (ds: ?*disp_stat_t, ln_nr: c_int) callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 104);
pub const lcd_writeText: *const fn (ds: ?*disp_stat_t, text: [*]const u8) callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 124);
pub const rtc_read: *const fn (tm: *abi.TimeShort, dt: *abi.DateShort) callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 204);
pub const rtc_write: *const fn (tm: *abi.TimeShort, dt: *abi.DateShort) callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 208);
pub const rtc_wakeup_delay: *const fn () callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 228);
pub const get_vbat: *const fn () callconv(.c) c_int = @ptrFromInt(LIBRARY_FN_BASE + 240);
pub const start_buzzer_freq: *const fn (freq: u32) callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 244);
pub const stop_buzzer: *const fn () callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 248);
pub const usb_powered: *const fn () callconv(.c) c_int = @ptrFromInt(LIBRARY_FN_BASE + 288);
// The auxiliary buffer is the firmware's tmpString, which every owner reads
// 4-byte aligned.
pub const aux_buf_ptr: *const fn () callconv(.c) [*]align(4) u8 = @ptrFromInt(LIBRARY_FN_BASE + 292);
pub const write_buf_ptr: *const fn () callconv(.c) [*]u8 = @ptrFromInt(LIBRARY_FN_BASE + 296);
pub const printer_advance_buf: *const fn (what: c_int) callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 312);
pub const printer_busy_for: *const fn (what: c_int) callconv(.c) c_int = @ptrFromInt(LIBRARY_FN_BASE + 316);
pub const power_check_screen: *const fn () callconv(.c) c_int = @ptrFromInt(LIBRARY_FN_BASE + 340);
pub const create_screenshot: *const fn (report_error: c_int) callconv(.c) c_int = @ptrFromInt(LIBRARY_FN_BASE + 376);
pub const key_empty: *const fn () callconv(.c) c_int = @ptrFromInt(LIBRARY_FN_BASE + 380);
pub const key_push: *const fn (k1: c_int) callconv(.c) c_int = @ptrFromInt(LIBRARY_FN_BASE + 384);
pub const key_tail: *const fn () callconv(.c) c_int = @ptrFromInt(LIBRARY_FN_BASE + 388);
pub const key_pop: *const fn () callconv(.c) c_int = @ptrFromInt(LIBRARY_FN_BASE + 392);
pub const key_pop_all: *const fn () callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 400);
pub const wait_for_key_press: *const fn () callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 408);
pub const wait_for_key_release: *const fn (tout: c_int) callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 420);
pub const reset_auto_off: *const fn () callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 440);
pub const check_create_dir: *const fn (dir: [*]const u8) callconv(.c) c_int = @ptrFromInt(LIBRARY_FN_BASE + 464);
pub const sys_disk_write_enable: *const fn (val: c_int) callconv(.c) c_int = @ptrFromInt(LIBRARY_FN_BASE + 480);
pub const sys_is_disk_write_enable: *const fn () callconv(.c) c_int = @ptrFromInt(LIBRARY_FN_BASE + 488);
pub const sys_timer_disable: *const fn (timer_ix: c_int) callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 500);
pub const sys_timer_start: *const fn (timer_ix: c_int, ms_value: u32) callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 504);
pub const sys_delay: *const fn (ms_delay: u32) callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 516);
pub const sys_current_ms: *const fn () callconv(.c) u32 = @ptrFromInt(LIBRARY_FN_BASE + 524);
pub const sys_sleep: *const fn () callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 536);
pub const sys_reset: *const fn () callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 544);
pub const draw_power_off_image: *const fn (allow_errors: c_int) callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 556);
pub const f_open: *const fn (fp: ?*FIL, path: [*]const u8, mode: u8) callconv(.c) FRESULT = @ptrFromInt(LIBRARY_FN_BASE + 564);
pub const f_close: *const fn (fp: ?*FIL) callconv(.c) FRESULT = @ptrFromInt(LIBRARY_FN_BASE + 568);
pub const f_read: *const fn (fp: ?*FIL, buff: ?*anyopaque, btr: UINT, br: *UINT) callconv(.c) FRESULT = @ptrFromInt(LIBRARY_FN_BASE + 572);
pub const f_write: *const fn (fp: ?*FIL, buff: ?*const anyopaque, btw: UINT, bw: *UINT) callconv(.c) FRESULT = @ptrFromInt(LIBRARY_FN_BASE + 576);
pub const f_lseek: *const fn (fp: ?*FIL, ofs: FSIZE_t) callconv(.c) FRESULT = @ptrFromInt(LIBRARY_FN_BASE + 580);
pub const make_date_filename: *const fn (str: [*]u8, dir: [*]const u8, ext: [*]const u8) callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 604);
pub const lcd_refresh_dma: *const fn () callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 644);
pub const lcd_refresh_wait: *const fn () callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 648);
pub const run_menu_item_sys: *const fn (line_id: u8) callconv(.c) c_int = @ptrFromInt(LIBRARY_FN_BASE + 728);
pub const f_unlink: *const fn (path: [*]const u8) callconv(.c) FRESULT = @ptrFromInt(LIBRARY_FN_BASE + 768);

// power_check_screen paints the low-battery screen and reports whether the power
// is low; host has no battery, so it is never low there.
pub fn powerCheckScreen() bool {
    return is_dmcp_build and power_check_screen() != 0;
}

// sys_sdb_t (dmcp.h), the system data block. It sits at a fixed address on each
// board, and only firmware code may reach it.
const SDB_BASE: usize = dmcp_rom_build_options.sdb_base;
const GetFlagFn = *const fn () callconv(.c) c_int;
const SetFlagFn = *const fn (val: c_int) callconv(.c) void;
pub const SysSdb = extern struct {
    calc_state: u32,
    ppgm_fp: ?*FIL,
    key_to_alpha_table: ?[*:0]const u8,
    run_menu_item_app: ?*const anyopaque,
    menu_line_str_app: ?*const anyopaque,
    after_fat_format: ?*const anyopaque,
    get_flag_dmy: GetFlagFn,
    set_flag_dmy: SetFlagFn,
    is_flag_clk24: GetFlagFn,
    set_flag_clk24: SetFlagFn,
    is_beep_mute: GetFlagFn,
    set_beep_mute: SetFlagFn,
    pds_t20: ?*disp_stat_t,
    pds_t24: ?*disp_stat_t,
    pds_fReg: ?*disp_stat_t,
    timer2_counter: ?*u32,
    timer3_counter: ?*u32,
    msc_end_cb: ?*const fn () callconv(.c) void,
};
comptime {
    // dmcp.h's layout on the 32-bit boards, where the block exists.
    if (@sizeOf(usize) == 4 and @offsetOf(SysSdb, "pds_t24") != 52) @compileError("sys_sdb_t layout");
}

/// `sdb` (dmcp.h).
pub fn sdb() *volatile SysSdb {
    return @ptrFromInt(SDB_BASE);
}

// DMCP's date order, SYS_MDY, SYS_DMY or SYS_YMD, and its 24-hour clock flag.
pub fn get_flag_dmy() c_int {
    return if (is_dmcp_build) sdb().get_flag_dmy() else 0;
}
pub fn set_flag_dmy(val: c_int) void {
    if (is_dmcp_build) sdb().set_flag_dmy(val);
}
pub fn is_flag_clk24() bool {
    return is_dmcp_build and sdb().is_flag_clk24() != 0;
}
pub fn set_flag_clk24(val: c_int) void {
    if (is_dmcp_build) sdb().set_flag_clk24(val);
}
