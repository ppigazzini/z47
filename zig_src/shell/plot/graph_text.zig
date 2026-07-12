const abi = @import("abi");
const std = @import("std");
// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/c47Extensions/graphText.c: preventFilenameTimeout, the
// CSV/text file export & import helpers (export_string_to_filename /
// import_string_from_filename / export_append_line / create_filename /
// export_xy_to_file plus the DMCP-only FatFs layer), and the on-screen text
// renderers (printStatus / print_linestr / print_numberstr / print_inlinestr /
// print_Register_line) shared by both builds. Faithful, line-by-line port.
//
// The file has fully distinct DMCP_BUILD and PC_BUILD bodies for the file I/O
// (DMCP uses the FatFs ROM layer, host uses stdio FILE*), both reproduced and
// gated on dmcp_build. The DMCP-only public symbols open_text / close_text /
// save_text and the static FatFs helpers (f_gets / f_getsline / putc_* / f_putc
// / f_puts / export_append_string_to_file[_n] / export_append_line_short) exist
// only on firmware. VERBOSE_LEVEL is -1 for every z47 build, so all the
// VERBOSE_LEVEL>=1/2 print_inlinestr/printf diagnostic blocks are dead and
// omitted. The DMCP-ROM FatFs/sys/check_create_dir/make_date_filename calls are
// fixed-address jump-table calls (LIBRARY_FN_BASE + verified offset); the host
// stdio path uses libc, only referenced under !dmcp_build.
//
// graphText.c is not reachable from the testSuite; verification is by build/link
// across every target plus the boundary gates.

const frontier_build_options = @import("frontier_build_options");
const frontier_char_string = @import("../display/text/char_string.zig"); // M-callconv: Zig-to-Zig
const frontier_screen = @import("../display/screen.zig"); // M-callconv: Zig-to-Zig
const frontier_sort = @import("../display/sort.zig"); // M-callconv: Zig-to-Zig
const frontier_textfiles = @import("../extensions/textfiles.zig"); // M-callconv: Zig-to-Zig
const frontier_timer = @import("../frontier_timer.zig"); // M-callconv: Zig-to-Zig
const dmcp_build: bool = frontier_build_options.dmcp_build;
const old_hw: bool = frontier_build_options.old_hw;

const LIBRARY_FN_BASE: usize = if (old_hw) 0x08000201 else 0x08000301;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const bool_t = bool;
const calcRegister_t = i16;
const font_t = abi.Font;

// ---------------------------------------------------------------------------
// Constants (verified via C probe against the sim build)
// ---------------------------------------------------------------------------
const TMP_STR_LENGTH: usize = 2560;
const FILENAMELEN: usize = 40;
const SCREEN_WIDTH: i16 = 400;
const SCREEN_HEIGHT: i16 = 240;
const Y_POSITION_OF_REGISTER_T_LINE: i16 = 24;
const vmNormal: c_int = 0;
const REGISTER_T: calcRegister_t = 103;
const CMP_NAME: i32 = 3;

// graphText.h
const APPEND: u8 = 0;
const OPEN: u8 = 2;
const CLOSE: u8 = 3;
const WRITE: u8 = 4;
const CSV_NEWLINE = "\n";
const CSV_TAB = "\t";

// screen.h
const force: u8 = 1;
const timed: u8 = 0;

const EOF: c_int = -1;

// FatFs (ff_ifc.h)
const FR_OK: c_int = 0;
const FA_READ: u8 = 0x01;
const FA_WRITE: u8 = 0x02;
const FA_CREATE_ALWAYS: u8 = 0x08;
const FA_OPEN_APPEND: u8 = 0x30;

// ---------------------------------------------------------------------------
// Globals (extern var) and graphText.c's own file globals
// ---------------------------------------------------------------------------
extern var mem__32: u32;
extern var cancelFilename: bool_t;
extern var filename_csv: [FILENAMELEN]u8;
extern var tmpString: [*c]u8;
extern const standardFont: font_t;

pub export var ttt: u32 = 0;
pub export var g_line_x: i16 = 0;
pub export var g_line_y: i16 = 0;
pub export var t_line_x: u32 = 0;
pub export var t_line_y: u32 = 0;

// ---------------------------------------------------------------------------
// Function externs (linkable everywhere)
// ---------------------------------------------------------------------------

extern fn strlen(s: [*c]const u8) usize;
extern fn strcpy(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strcat(dst: [*c]u8, src: [*c]const u8) [*c]u8;

// host-only libc / glib (referenced under !dmcp_build).
const FILE = opaque {};
extern fn fopen(path: [*c]const u8, mode: [*c]const u8) ?*FILE;
extern fn fclose(f: *FILE) c_int;
extern fn fputs(s: [*c]const u8, f: *FILE) c_int;
extern fn fread(ptr: ?*anyopaque, size: usize, n: usize, f: *FILE) usize;
extern fn fflush(f: ?*FILE) c_int;
extern fn printf(fmt: [*:0]const u8, ...) c_int;
extern fn g_get_monotonic_time() i64;
const time_t = c_long;
const tm = opaque {};
extern fn time(t: ?*time_t) time_t;
extern fn localtime(t: *const time_t) *tm;
extern fn strftime(s: [*c]u8, maxsize: usize, format: [*:0]const u8, timeptr: *const tm) usize;

inline fn stringByteLength(s: [*c]const u8) i32 {
    return @intCast(strlen(s));
}

// ===========================================================================
// preventFilenameTimeout (both builds)
// ===========================================================================
pub export fn preventFilenameTimeout() callconv(.c) void {
    const tmp__32: u32 = frontier_timer.getUptimeMs();
    mem__32 = tmp__32;
    cancelFilename = false;
}

// ===========================================================================
// printStatus (both builds; the PC_BUILD diagnostic printf is host-only)
// ===========================================================================
pub export fn printStatus(row: u8, line1: [*c]const u8, forced: u8) callconv(.c) void {
    if (comptime !dmcp_build) {
        if (ttt == 0) {
            ttt = @truncate(@as(u64, @bitCast(g_get_monotonic_time())));
        }
        _ = printf("Status: %10u, %s\n", @as(u32, @truncate(@as(u64, @bitCast(g_get_monotonic_time())))) -% ttt, line1);
        _ = fflush(null);
    }
    var line_x: i16 = undefined;
    var line_y: i16 = undefined;
    line_y = Y_POSITION_OF_REGISTER_T_LINE; // 20
    line_x = 20 * @as(i16, row);

    frontier_screen.clearRegisterLine(REGISTER_T, true, true);

    line_x = @intCast(frontier_screen.showString(line1, &standardFont, @intCast(line_x), @intCast(line_y), vmNormal, @intFromBool(true), @intFromBool(true)));

    if (forced == force) {
        frontier_screen.force_refresh(force);
    } else {
        frontier_screen.force_refresh(timed);
    }
}

// ===========================================================================
// print_linestr (both builds; the DMCP lcd_refresh_wait tail is firmware-only)
// ===========================================================================
pub export fn print_linestr(line1: [*c]const u8, line_init: bool_t) callconv(.c) void {
    var l1: [200]u8 = undefined;
    l1[0] = 0;
    var ix: i16 = 0;
    var ixx: i16 = undefined;

    if (line_init) {
        g_line_y = 20;
        g_line_x = 0;
    }
    _ = strcat(&l1, "-");
    ixx = @intCast(stringByteLength(line1));
    while (ix < ixx and ix < 98 and frontier_char_string.stringWidth(&l1, &standardFont, true, true) < SCREEN_WIDTH - 12 - g_line_x) {
        _ = frontier_char_string.xcopy(&l1, line1, @intCast(ix + 1));
        l1[@intCast(ix + 1 + 1)] = 0;
        ix = frontier_char_string.stringNextGlyph(line1, ix);
    }
    while (stringByteLength(&l1) < 200 and frontier_char_string.stringWidth(&l1, &standardFont, true, true) < SCREEN_WIDTH - 12 - g_line_x) {
        _ = strcat(&l1, ".");
    }

    if (g_line_y < SCREEN_HEIGHT) {
        ixx = @intCast(frontier_screen.showString(&l1, &standardFont, @intCast(g_line_x), @intCast(g_line_y), vmNormal, @intFromBool(true), @intFromBool(true)));
    }
    if (!line_init) {
        g_line_y += 20;
    }
    if (g_line_y > SCREEN_HEIGHT - 20) {
        g_line_y = 40;
        g_line_x += 4;
    }
    frontier_screen.force_refresh(timed);
    if (comptime dmcp_build) {
        lcd_refresh_wait();
    }
}

// ===========================================================================
// print_numberstr (both builds)
// ===========================================================================
pub export fn print_numberstr(line1: [*c]const u8, line_init: bool_t) callconv(.c) void {
    if (line_init or g_line_y >= SCREEN_HEIGHT) {
        g_line_y = 0;
        g_line_x = 0;
    }
    g_line_y += 20;
    if (g_line_y < SCREEN_HEIGHT) {
        var cnt: i16 = 0;
        var tt: [2]u8 = undefined;
        while (line1[@intCast(cnt)] != 0 and g_line_x < SCREEN_WIDTH - 8 + 1) {
            tt[0] = line1[@intCast(cnt)];
            tt[1] = 0;
            g_line_x = @intCast(frontier_screen.showString(&tt, &standardFont, @as(u32, @intCast(cnt)) * 8, @intCast(g_line_y), vmNormal, @intFromBool(true), @intFromBool(true)));
            cnt += 1;
        }
    }
    g_line_x = 0;
    frontier_screen.force_refresh(timed);
    if (comptime dmcp_build) {
        lcd_refresh_wait();
    }
}

// ===========================================================================
// print_inlinestr (both builds)
// ===========================================================================
pub export fn print_inlinestr(line1: [*c]const u8, endline: bool_t) callconv(.c) void {
    var l1: [100]u8 = undefined; // Clip the string at 40
    l1[0] = 0;
    var ix: i16 = 0;
    var ixx: i16 = undefined;
    ixx = @intCast(stringByteLength(line1));
    while (ix < ixx and ix < 98 and t_line_x + @as(u32, @intCast(@as(i32, frontier_char_string.stringWidth(&l1, &standardFont, true, true)))) < SCREEN_WIDTH - 12) {
        _ = frontier_char_string.xcopy(&l1, line1, @intCast(ix + 1));
        l1[@intCast(ix + 1)] = 0;
        ix = frontier_char_string.stringNextGlyph(line1, ix);
    }
    if (t_line_y < SCREEN_HEIGHT) {
        t_line_x = frontier_screen.showString(&l1, &standardFont, t_line_x, t_line_y, vmNormal, @intFromBool(true), @intFromBool(true));
    }
    if (endline) {
        t_line_y += 20;
        t_line_x = 0;
    }
    frontier_screen.force_refresh(force);
    if (comptime dmcp_build) {
        lcd_refresh_wait();
    }
}

// ===========================================================================
// print_Register_line (both builds)
// ===========================================================================
pub export fn print_Register_line(regist: calcRegister_t, before: [*c]u8, after: [*c]u8, line_init: bool_t) callconv(.c) void {
    var str: [TMP_STR_LENGTH]u8 = undefined;

    frontier_textfiles.copyRegisterToClipboardString2(regist, &str);
    frontier_char_string.addStrBothSides(&str, before, after);

    print_numberstr(&str, line_init);
}

// ===========================================================================
// create_filename (distinct DMCP / PC bodies)
// ===========================================================================
pub export fn create_filename(fn_arg: [*c]const u8) callconv(.c) void {
    if (comptime dmcp_build) {
        const tmp__32: u32 = frontier_timer.getUptimeMs();
        if (cancelFilename or (mem__32 == 0) or (tmp__32 > mem__32 + 120000) or (stringByteLength(&filename_csv) > 10 and frontier_sort.compareString(&filename_csv[@intCast(stringByteLength(&filename_csv) - 9)], fn_arg, CMP_NAME) != 0)) {
            _ = check_create_dir("DATA");
            make_date_filename(&filename_csv, "DATA\\", fn_arg);
            _ = check_create_dir("DATA");
        }
        mem__32 = tmp__32;
        cancelFilename = false;
    } else {
        // PC-only guard (C: present in PC create_filename, absent in the DMCP body)
        if (stringByteLength(&filename_csv) > 9 and frontier_sort.compareString(&filename_csv[@intCast(stringByteLength(&filename_csv) - 8)], ".T47.TSV", CMP_NAME) == 0) {
            return; // already a .T47.TSV name; file management is done in the DSL
        }
        const tmp__32: u32 = frontier_timer.getUptimeMs();
        if (cancelFilename or (mem__32 == 0) or (tmp__32 > mem__32 + 120000) or (stringByteLength(&filename_csv) > 10 and frontier_sort.compareString(&filename_csv[@intCast(stringByteLength(&filename_csv) - 9)], fn_arg, CMP_NAME) != 0)) {
            var rawTime: time_t = undefined;
            _ = time(&rawTime);
            const timeInfo: *tm = localtime(&rawTime);
            _ = strftime(&filename_csv, FILENAMELEN, "%Y%m%d-%H%M%S00", timeInfo);
            _ = strcat(&filename_csv, fn_arg);
        }
        mem__32 = tmp__32;
        cancelFilename = false;
    }
}

// ===========================================================================
// export_string_to_filename (distinct DMCP / PC bodies)
// ===========================================================================
pub export fn export_string_to_filename(line1: [*c]const u8, mode: u8, dirname: [*c]const u8, filename: [*c]const u8) callconv(.c) i16 {
    if (comptime dmcp_build) {
        var dirfile: [40]u8 = undefined;
        _ = strcpy(&dirfile, dirname);
        _ = strcat(&dirfile, "\\");
        _ = strcat(&dirfile, filename);

        abi.fmtBufZ(tmpString[0..2560], "{s}" ++ CSV_NEWLINE, .{std.mem.span(line1)});
        _ = check_create_dir(dirname);
        if (export_append_string_to_file(tmpString, mode, &dirfile) != 0) {
            return 1;
        }
        return 0;
    } else {
        var outfile: ?*FILE = undefined;
        var dirfile: [40]u8 = undefined;
        var frr: c_int = 0;
        var line: [200]u8 = undefined; // Line buffer

        _ = strcpy(&dirfile, dirname);
        _ = strcat(&dirfile, "/");
        _ = strcat(&dirfile, filename);

        if (mode == APPEND) {
            outfile = fopen(&dirfile, "ab");
        } else {
            outfile = fopen(&dirfile, "wb");
        }

        if (outfile == null) {
            _ = printf("Cannot open ID008: %s %s\n", &dirfile, line1);
            _ = fflush(null);
            return 1;
        }

        abi.fmtBufZ(tmpString[0..2560], "{s}" ++ CSV_NEWLINE, .{std.mem.span(line1)});
        frr = fputs(tmpString, outfile.?);
        if (frr == EOF) {
            abi.fmtBufZ(&line, "Write error ID009 --> {d}    \n", .{frr});
            _ = printf("%s", line1);
            _ = fflush(null);
            if (outfile != null) {
                _ = fclose(outfile.?);
            }
            return @intCast(frr);
        } else {
            _ = printf("Exported %i chars to %s: %s\n", frr, &dirfile, line1);
            _ = fflush(null);
            _ = fclose(outfile.?);
        }
        return 0;
    }
}

// ===========================================================================
// import_string_from_filename (distinct DMCP / PC bodies; VERBOSE_LEVEL<1 so
// all diagnostic blocks are dead)
// ===========================================================================
pub export fn import_string_from_filename(line1: [*c]u8, dirname: [*c]u8, filename_short: [*c]u8, filename: [*c]u8, fallback: [*c]u8, scanning: bool_t) callconv(.c) i16 {
    if (comptime dmcp_build) {
        var dirfile: [200]u8 = undefined;
        dirfile[0] = 0;
        var fil: FIL = undefined;
        var fr: c_int = undefined;

        _ = check_create_dir(dirname);

        _ = strcpy(&dirfile, dirname);
        _ = strcat(&dirfile, "\\");
        _ = strcat(&dirfile, filename_short);

        fr = f_open(&fil, &dirfile, FA_READ);
        if (fr != FR_OK) {
            _ = f_close(&fil);

            if (filename[0] != 0) {
                _ = strcpy(&dirfile, dirname);
                _ = strcat(&dirfile, "\\");
                _ = strcat(&dirfile, filename);

                fr = f_open(&fil, &dirfile, FA_READ);
                if (fr != FR_OK) {
                    _ = f_close(&fil);
                    _ = strcpy(line1, fallback);
                    return 1;
                }
            } else {
                _ = strcpy(line1, fallback);
                return 1;
            }
        }

        line1[0] = 0;
        _ = f_getsline(line1, if (scanning) @min(@as(c_int, 100), @as(c_int, @intCast(TMP_STR_LENGTH))) else @as(c_int, @intCast(TMP_STR_LENGTH)), &fil);
        _ = f_close(&fil);

        if (stringByteLength(line1) >= TMP_STR_LENGTH - 1) {
            _ = strcpy(line1, fallback);
            return 1;
        }
        return 0;
    } else {
        var dirfile: [200]u8 = undefined;
        dirfile[0] = 0;
        var infile: ?*FILE = undefined;
        var onechar: [2]u8 = undefined;

        _ = strcpy(&dirfile, dirname);
        _ = strcat(&dirfile, "/");
        _ = strcat(&dirfile, filename_short);

        infile = fopen(&dirfile, "rb");
        if (infile == null) {
            if (filename[0] != 0) {
                _ = strcpy(&dirfile, dirname);
                _ = strcat(&dirfile, "/");
                _ = strcat(&dirfile, filename);

                infile = fopen(&dirfile, "rb");
                if (infile == null) {
                    _ = strcpy(line1, fallback);
                    return 1;
                }
            } else {
                _ = strcpy(line1, fallback);
                return 1;
            }
        }

        line1[0] = 0;
        onechar[1] = 0;
        while (fread(&onechar, 1, 1, infile.?) != 0) {
            _ = strcat(line1, &onechar);
        }
        _ = fclose(infile.?);

        if (stringByteLength(line1) >= TMP_STR_LENGTH - 1) {
            _ = strcpy(line1, fallback);
            _ = printf("ERROR too long file using fallback\n");
            _ = fflush(null);
            return 1;
        }
        return 0;
    }
}

// ===========================================================================
// export_append_line (distinct DMCP / PC bodies)
// ===========================================================================
pub export fn export_append_line(inputstring: [*c]const u8) callconv(.c) i16 {
    if (comptime dmcp_build) {
        var ix: i32 = 0;
        var buf: [200]u8 = undefined;
        var fr: c_int = undefined;
        const linesize: i32 = 128;

        while (stringByteLength(inputstring + @as(usize, @intCast(ix))) > linesize) {
            _ = frontier_char_string.xcopy(&buf, inputstring + @as(usize, @intCast(ix)), @intCast(linesize));
            buf[@intCast(linesize)] = 0;
            fr = export_append_line_short(&buf);
            if (fr != 0) {
                return @intCast(fr);
            }
            ix += linesize;
        }
        if (stringByteLength(inputstring + @as(usize, @intCast(ix))) > 0) {
            fr = export_append_line_short(inputstring + @as(usize, @intCast(ix)));
            if (fr != 0) {
                return @intCast(fr);
            }
        }
        return 0;
    } else {
        var outfile: ?*FILE = undefined;

        outfile = fopen(&filename_csv, "ab");
        if (outfile == null) {
            _ = printf("Cannot open to append ID011: %s %s\n", &filename_csv, inputstring);
            _ = fflush(null);
            return 1;
        }
        var frr: c_int = 0;
        var line: [200]u8 = undefined; // Line buffer
        frr = fputs(inputstring, outfile.?);
        if (frr == EOF) {
            abi.fmtBufZ(&line, "Write error ID012 --> {d} {s}\n", .{ frr, std.mem.span(inputstring) });
            _ = fflush(null);
            _ = printf("%s", &line);
            _ = fflush(null);
            if (outfile != null) {
                _ = fclose(outfile.?);
            }
            return @intCast(frr);
        } else {
            _ = printf("Exported %i chars to %s: %s\n", frr, &filename_csv, inputstring);
            _ = fflush(null);
            _ = fclose(outfile.?);
        }
        return 0;
    }
}

// ===========================================================================
// export_xy_to_file (distinct DMCP / PC bodies)
// ===========================================================================
pub export fn export_xy_to_file(x: f32, y: f32) callconv(.c) i16 {
    if (comptime dmcp_build) {
        var line: [TMP_STR_LENGTH]u8 = undefined; // Line buffer
        create_filename(".STAT.TSV");
        var xb: [64]u8 = undefined;
        var yb: [64]u8 = undefined;
        abi.fmtCStr(&line, "{s}\t{s}\n", .{ abi.fmtExpBuf(&xb, 16, @as(f64, x)), abi.fmtExpBuf(&yb, 16, @as(f64, y)) });
        if (export_append_string_to_file(&line, APPEND, &filename_csv) != 0) {
            return 1;
        }
        return 0;
    } else {
        var line: [200]u8 = undefined; // Line buffer
        create_filename(".STAT.TSV");
        var xb: [64]u8 = undefined;
        var yb: [64]u8 = undefined;
        abi.fmtCStr(&line, "{s}\t{s}\n", .{ abi.fmtExpBuf(&xb, 16, @as(f64, x)), abi.fmtExpBuf(&yb, 16, @as(f64, y)) });
        _ = export_append_line(&line);
        return 0;
    }
}

// ===========================================================================
// DMCP-only FatFs layer. Everything below is compiled only on firmware.
// ===========================================================================
const WORD = u16;
const DWORD = u32;
const FSIZE_t = DWORD;
const UINT = c_uint;
const BYTE = u8;
const TCHAR = u8;
const FATFS = opaque {};
const _FDID = extern struct {
    fs: ?*FATFS,
    id: WORD,
    attr: BYTE,
    stat: BYTE,
    sclust: DWORD,
    objsize: FSIZE_t,
    lockid: UINT,
};
const FIL = extern struct {
    obj: _FDID,
    flag: BYTE,
    err: BYTE,
    fptr: FSIZE_t,
    clust: DWORD,
    sect: DWORD,
    dir_sect: DWORD,
    dir_ptr: [*c]BYTE,
    cltbl: [*c]DWORD,
    buf: [512]BYTE,
};
inline fn f_size(fp: *FIL) FSIZE_t {
    return fp.obj.objsize;
}

// DMCP-ROM trampolines (fixed-address on firmware; verified in lft_ifc.h).
inline fn check_create_dir(dir: [*c]const u8) c_int {
    const f: *const fn ([*c]const u8) callconv(.c) c_int = @ptrFromInt(LIBRARY_FN_BASE + 464);
    return f(dir);
}
inline fn make_date_filename(str: [*c]u8, dir: [*c]const u8, ext: [*c]const u8) void {
    const f: *const fn ([*c]u8, [*c]const u8, [*c]const u8) callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 604);
    f(str, dir, ext);
}
inline fn sys_disk_write_enable(val: c_int) c_int {
    const f: *const fn (c_int) callconv(.c) c_int = @ptrFromInt(LIBRARY_FN_BASE + 480);
    return f(val);
}
inline fn sys_is_disk_write_enable() c_int {
    const f: *const fn () callconv(.c) c_int = @ptrFromInt(LIBRARY_FN_BASE + 488);
    return f();
}
inline fn f_open(fp: *FIL, path: [*c]const u8, mode: u8) c_int {
    const f: *const fn (*FIL, [*c]const u8, u8) callconv(.c) c_int = @ptrFromInt(LIBRARY_FN_BASE + 564);
    return f(fp, path, mode);
}
inline fn f_close(fp: *FIL) c_int {
    const f: *const fn (*FIL) callconv(.c) c_int = @ptrFromInt(LIBRARY_FN_BASE + 568);
    return f(fp);
}
inline fn f_read(fp: *FIL, buff: ?*anyopaque, btr: UINT, br: *UINT) c_int {
    const f: *const fn (*FIL, ?*anyopaque, UINT, *UINT) callconv(.c) c_int = @ptrFromInt(LIBRARY_FN_BASE + 572);
    return f(fp, buff, btr, br);
}
inline fn f_write(fp: *FIL, buff: ?*const anyopaque, btw: UINT, bw: *UINT) c_int {
    const f: *const fn (*FIL, ?*const anyopaque, UINT, *UINT) callconv(.c) c_int = @ptrFromInt(LIBRARY_FN_BASE + 576);
    return f(fp, buff, btw, bw);
}
inline fn f_lseek(fp: *FIL, ofs: FSIZE_t) c_int {
    const f: *const fn (*FIL, FSIZE_t) callconv(.c) c_int = @ptrFromInt(LIBRARY_FN_BASE + 580);
    return f(fp, ofs);
}
// lcd_refresh_wait is a fixed-address ROM jump-table call on firmware
// (LIBRARY_FN_BASE + 648, lft_ifc.h:208), not a linkable symbol there. It is
// only ever invoked under `if (comptime dmcp_build)` at the call sites, so the
// host body is unreachable.
fn lcd_refresh_wait() void {
    if (comptime dmcp_build) {
        const f: *const fn () callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 648);
        f();
    }
}

// IOMsgs[] (DMCP-only TO_QSPI table). Only .itemName is read; .count is unused.
const IOMsgsT = extern struct { count: u8, itemName: [40]u8 };
fn ioRow(comptime c: u8, comptime s: []const u8) IOMsgsT {
    var row = IOMsgsT{ .count = c, .itemName = std.mem.zeroes([40]u8) };
    @memcpy(row.itemName[0..s.len], s);
    return row;
}
const IOMsgs = [_]IOMsgsT{
    ioRow(0, ""),
    ioRow(1, "Write error ID001--> "),
    ioRow(2, "File open error ID002--> "),
    ioRow(3, "Seek error ID003--> "),
    ioRow(4, "Write error ID004--> "),
    ioRow(5, "Close error ID005--> "),
    ioRow(6, "Not found ID006 --> "),
    ioRow(7, "No path ID007 --> "),
    ioRow(8, ". Using fallback."),
    ioRow(9, "ERROR too long file using fallback"),
    ioRow(100, "Msg List"),
};

// f_getsline (static)
fn f_getsline(buff: [*c]TCHAR, lenIn: c_int, fp: *FIL) [*c]TCHAR {
    var nc: c_int = 0;
    var p: [*c]TCHAR = buff;
    var s: [2]BYTE = undefined;
    var rc: UINT = undefined;
    var sc: BYTE = undefined;
    s[1] = 0;
    const len = lenIn - 1; // Make a room for the terminator
    while (nc < len) {
        _ = f_read(fp, &s, 1, &rc); // Get a byte
        if (rc != 1) break; // EOF?
        sc = s[0];
        p[0] = sc;
        p += 1;
        nc += 1;
    }
    p[0] = 0;
    return if (nc != 0) buff else null;
}

// putbuff / putc_* (static)
const putbuff = extern struct {
    fp: ?*FIL,
    idx: c_int,
    nchr: c_int,
    buf: [64]BYTE,
};
fn putc_bfd(pb: *putbuff, c: TCHAR) void {
    var n: UINT = undefined;
    if (c == '\n') { // LF -> CRLF conversion
        putc_bfd(pb, '\r');
    }
    var i: c_int = pb.idx; // Write index of pb->buf[]
    if (i < 0) {
        return;
    }
    const nc: c_int = pb.nchr; // Write unit counter
    pb.buf[@intCast(i)] = @intCast(c);
    i += 1;
    if (i >= @as(c_int, @intCast(@sizeOf(@TypeOf(pb.buf)))) - 4) { // Write buffered characters
        _ = f_write(pb.fp.?, &pb.buf, @intCast(i), &n);
        i = if (n == @as(UINT, @intCast(i))) 0 else -1;
    }
    pb.idx = i;
    pb.nchr = nc + 1;
}
fn putc_flush(pb: *putbuff) c_int {
    var nw: UINT = undefined;
    if (pb.idx >= 0 and f_write(pb.fp.?, &pb.buf, @intCast(pb.idx), &nw) == FR_OK and @as(UINT, @intCast(pb.idx)) == nw) {
        return pb.nchr;
    }
    return EOF;
}
fn mem_set(dst: ?*anyopaque, val: c_int, cntIn: UINT) void {
    var d: [*c]BYTE = @ptrCast(dst);
    var cnt = cntIn;
    while (true) {
        d[0] = @intCast(val);
        d += 1;
        cnt -%= 1;
        if (cnt == 0) break;
    }
}
fn putc_init(pb: *putbuff, fp: *FIL) void {
    mem_set(pb, 0, @sizeOf(putbuff));
    pb.fp = fp;
}
fn f_puts(str_in: [*c]const TCHAR, fp: *FIL) c_int {
    var pb: putbuff = undefined;
    var str = str_in;
    putc_init(&pb, fp);
    while (str[0] != 0) {
        putc_bfd(&pb, str[0]);
        str += 1;
    }
    return putc_flush(&pb);
}

// export_append_string_to_file (DMCP)
fn export_append_string_to_file(line1: [*c]const u8, mode: u8, filedir: [*c]const u8) c_int {
    var line: [200]u8 = undefined; // Line buffer
    var fil: FIL = undefined;
    var fr: c_int = undefined;

    _ = sys_disk_write_enable(1);
    fr = sys_is_disk_write_enable();
    if (fr == 0) {
        abi.fmtBufZ(&line, "{s}{d}    \n", .{ std.mem.sliceTo(&IOMsgs[1].itemName, 0), fr });
        print_linestr(&line, true);
        _ = f_close(&fil);
        _ = sys_disk_write_enable(0);
        return fr;
    }

    if (mode == APPEND) {
        fr = f_open(&fil, filedir, FA_OPEN_APPEND | FA_WRITE);
    } else {
        fr = f_open(&fil, filedir, FA_WRITE | FA_CREATE_ALWAYS);
    }
    if (fr != 0) {
        abi.fmtBufZ(&line, "{s}{d}    \n", .{ std.mem.sliceTo(&IOMsgs[2].itemName, 0), fr });
        print_linestr(&line, false);
        _ = f_close(&fil);
        _ = sys_disk_write_enable(0);
        return fr;
    }

    if (mode == APPEND) {
        fr = f_lseek(&fil, f_size(&fil));
        if (fr != 0) {
            abi.fmtBufZ(&line, "{s}{d}    \n", .{ std.mem.sliceTo(&IOMsgs[3].itemName, 0), fr });
            print_linestr(&line, false);
            _ = f_close(&fil);
            _ = sys_disk_write_enable(0);
            return fr;
        }
    }

    fr = f_puts(line1, &fil);
    if (fr == EOF) {
        abi.fmtBufZ(&line, "{s}{d}    \n", .{ std.mem.sliceTo(&IOMsgs[4].itemName, 0), fr });
        print_linestr(&line, false);
        _ = f_close(&fil);
        _ = sys_disk_write_enable(0);
        return fr;
    }

    fr = f_close(&fil);
    if (fr != 0) {
        abi.fmtBufZ(&line, "{s}{d}    \n", .{ std.mem.sliceTo(&IOMsgs[4].itemName, 0), fr });
        print_linestr(&line, false);
        _ = f_close(&fil);
        _ = sys_disk_write_enable(0);
        return fr;
    }

    _ = sys_disk_write_enable(0);
    return 0;
}

// export_append_string_to_file_n (DMCP, static FIL fil)
var eastfn_fil: FIL = undefined;
fn export_append_string_to_file_n(line1: [*c]const u8, mode: u8, filedir: [*c]const u8) c_int {
    var line: [200]u8 = undefined; // Line buffer
    var fr: c_int = undefined;

    switch (mode) {
        OPEN, APPEND => {
            _ = sys_disk_write_enable(1);
            fr = sys_is_disk_write_enable();
            if (fr == 0) {
                abi.fmtBufZ(&line, "{s}{d}    \n", .{ std.mem.sliceTo(&IOMsgs[1].itemName, 0), fr });
                print_linestr(&line, true);
                _ = f_close(&eastfn_fil);
                _ = sys_disk_write_enable(0);
                return fr;
            }
            if (mode == APPEND) {
                fr = f_open(&eastfn_fil, filedir, FA_OPEN_APPEND | FA_WRITE);
            } else {
                fr = f_open(&eastfn_fil, filedir, FA_WRITE | FA_CREATE_ALWAYS);
            }
            if (fr != 0) {
                abi.fmtBufZ(&line, "{s}{d}    \n", .{ std.mem.sliceTo(&IOMsgs[2].itemName, 0), fr });
                print_linestr(&line, false);
                _ = f_close(&eastfn_fil);
                _ = sys_disk_write_enable(0);
                return fr;
            }
            if (mode == APPEND) {
                fr = f_lseek(&eastfn_fil, f_size(&eastfn_fil));
                if (fr != 0) {
                    abi.fmtBufZ(&line, "{s}{d}    \n", .{ std.mem.sliceTo(&IOMsgs[3].itemName, 0), fr });
                    print_linestr(&line, false);
                    _ = f_close(&eastfn_fil);
                    _ = sys_disk_write_enable(0);
                    return fr;
                }
            }
        },
        WRITE => {
            fr = f_puts(line1, &eastfn_fil);
            if (fr == EOF) {
                abi.fmtBufZ(&line, "{s}{d}    \n", .{ std.mem.sliceTo(&IOMsgs[4].itemName, 0), fr });
                print_linestr(&line, false);
                _ = f_close(&eastfn_fil);
                _ = sys_disk_write_enable(0);
                return fr;
            }
        },
        CLOSE => {
            fr = f_close(&eastfn_fil);
            if (fr != 0) {
                abi.fmtBufZ(&line, "{s}{d}    \n", .{ std.mem.sliceTo(&IOMsgs[5].itemName, 0), fr });
                print_linestr(&line, false);
                _ = f_close(&eastfn_fil);
                _ = sys_disk_write_enable(0);
                return fr;
            }
            _ = sys_disk_write_enable(0);
        },
        else => {},
    }
    return 0;
}

// open_text / close_text / save_text (DMCP-only public symbols)
fn open_textImpl(dirname: [*c]const u8, dirfile: [*c]const u8) callconv(.c) i16 {
    var rr: [2]u8 = undefined;
    rr[0] = 0;
    _ = check_create_dir(dirname);
    if (export_append_string_to_file_n(&rr, OPEN, dirfile) != 0) {
        return 1;
    }
    return 0;
}
fn close_textImpl(dirfile: [*c]const u8) callconv(.c) i16 {
    var rr: [2]u8 = undefined;
    rr[0] = 0;
    if (export_append_string_to_file_n(&rr, CLOSE, dirfile) != 0) {
        return 1;
    }
    return 0;
}
fn save_textImpl(line1: [*c]const u8, mode1: u8, mode2: u8, mode3: u8, nn: i16, dirfile: [*c]const u8) callconv(.c) i16 {
    var rr: [2]u8 = undefined;
    rr[1] = 0;
    switch (mode1) {
        OPEN, APPEND => {
            if (export_append_string_to_file_n(&rr, mode1, dirfile) != 0) {
                return 1;
            }
        },
        else => {},
    }

    var ii: i16 = undefined;
    var jj: i16 = undefined;
    switch (mode2) {
        WRITE => {
            ii = @min(nn, @as(i16, @intCast(strlen(line1))));
            jj = ii;
            while (ii != 0) {
                rr[0] = line1[@intCast(jj - ii)];
                if (export_append_string_to_file_n(&rr, mode2, dirfile) != 0) {
                    return 1;
                }
                ii -= 1;
            }
        },
        else => {},
    }

    switch (mode3) {
        CLOSE => {
            if (export_append_string_to_file_n(&rr, mode3, dirfile) != 0) {
                return 1;
            }
        },
        else => {},
    }

    return 0;
}

// export_append_line_short (DMCP)
fn export_append_line_short(inputstring: [*c]const u8) c_int {
    var line: [200]u8 = undefined; // Line buffer
    var fil: FIL = undefined;
    var fr: c_int = undefined;

    _ = sys_disk_write_enable(1);
    fr = sys_is_disk_write_enable();
    if (fr == 0) {
        abi.fmtBufZ(&line, "{s}{d}    \n", .{ std.mem.sliceTo(&IOMsgs[4].itemName, 0), fr });
        print_linestr(&line, false);
        _ = f_close(&fil);
        _ = sys_disk_write_enable(0);
        return fr;
    }

    fr = f_open(&fil, &filename_csv, FA_OPEN_APPEND | FA_WRITE);
    if (fr != 0) {
        abi.fmtBufZ(&line, "{s}{d}    \n", .{ std.mem.sliceTo(&IOMsgs[2].itemName, 0), fr });
        print_linestr(&line, false);
        _ = f_close(&fil);
        _ = sys_disk_write_enable(0);
        return fr;
    }

    fr = f_lseek(&fil, f_size(&fil));
    if (fr != 0) {
        abi.fmtBufZ(&line, "{s}{d}    \n", .{ std.mem.sliceTo(&IOMsgs[3].itemName, 0), fr });
        print_linestr(&line, false);
        _ = f_close(&fil);
        _ = sys_disk_write_enable(0);
        return fr;
    }

    fr = f_puts(inputstring, &fil);

    if (fr == 0) {
        abi.fmtBufZ(&line, "{s}{d}    \n", .{ std.mem.sliceTo(&IOMsgs[4].itemName, 0), fr });
        print_linestr(&line, false);
        _ = f_close(&fil);
        _ = sys_disk_write_enable(0);
        return fr;
    }

    fr = f_close(&fil);
    if (fr != 0) {
        abi.fmtBufZ(&line, "{s}{d}    \n", .{ std.mem.sliceTo(&IOMsgs[5].itemName, 0), fr });
        print_linestr(&line, false);
        _ = f_close(&fil);
        _ = sys_disk_write_enable(0);
        return fr;
    }

    _ = sys_disk_write_enable(0);
    return 0;
}

comptime {
    if (dmcp_build) {
        @export(&open_textImpl, .{ .name = "open_text", .linkage = .strong });
        @export(&close_textImpl, .{ .name = "close_text", .linkage = .strong });
        @export(&save_textImpl, .{ .name = "save_text", .linkage = .strong });
    }
}
