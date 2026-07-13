// SPDX-License-Identifier: GPL-3.0-only
//
// Zig replacement for the testSuite HAL (src/testSuite/hal/*): the small
// platform-abstraction shims the headless test runner links instead of the real
// GTK/firmware hardware layers. Ported verbatim from gui.c / audio.c / lcd.c /
// io.c / print_ir.c. Linked as an object ONLY into the testSuite executables
// (the main testSuite + the math-oracle mini-suites) where those .c files used
// to be compiled; the product sim and DM42/DMCP5 firmware keep their own real
// HAL under src/c47-gtk/hal and src/c47-dmcp*/hal, so this object is
// testSuite-only and cannot clash with them.

const std = @import("std");

const NOVAL_U16: u16 = @bitCast(@as(i16, -126)); // NOVAL = -126 returned as uint16_t

// ---------------------------------------------------------------------------
// gui.c — calc-mode GUI transitions are inert in the headless testSuite.
// ---------------------------------------------------------------------------
pub export fn calcModeNormalGui() callconv(.c) void {}
pub export fn calcModeAimGui() callconv(.c) void {}
pub export fn calcModeTamGui() callconv(.c) void {}

// ---------------------------------------------------------------------------
// audio.c — no audio hardware in the testSuite.
// ---------------------------------------------------------------------------
pub export fn audioTone(frequency: u32) callconv(.c) void {
    _ = frequency;
}
pub export fn fnSetVolume(volume: u16) callconv(.c) void {
    _ = volume;
}
pub export fn getBeepVolume() callconv(.c) u16 {
    return NOVAL_U16;
}
pub export fn fnGetVolume(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
}
pub export fn fnVolumeUp(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
}
pub export fn fnVolumeDown(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
}
pub export fn fnBuzz(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
}
pub export fn fnPlay(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
}

// ---------------------------------------------------------------------------
// lcd.c — a real 1bpp frame buffer so plot/display output can be snapshotted
// and hashed (ported from src/testSuite/hal/lcd.c, the c47-gtk software
// blitter). lcd_buffer keeps the same 52-byte row stride (a two-byte prefix
// plus 50 data bytes) as the simulator, so screen.c/fnScreenDump address it
// identically. Defined (as null) in shell/c47.zig; allocated lazily here.
// ---------------------------------------------------------------------------
const SCREEN_WIDTH: u32 = 400;
const SCREEN_HEIGHT: u32 = 240;
const LCD_LINE_SIZE: u32 = 50;
const BLT_OR: c_int = 0;
const BLT_ANDN: c_int = 1;
const BLT_XOR: c_int = 2;
const BLT_NONE: c_int = 0;
const BLT_SET: c_int = 1;
extern var lcd_buffer: [*c]u8;
extern fn calloc(nmemb: usize, size: usize) [*c]u8;

fn ensureLcdBuffer() void {
    if (lcd_buffer == null) {
        lcd_buffer = calloc(SCREEN_HEIGHT * (SCREEN_WIDTH / 8 + 2) + 16, 1) + 2;
    }
}

pub export fn bitblt24(x_in: u32, dx: u32, y: u32, val: u32, blt_op: c_int, fill: c_int) callconv(.c) void {
    ensureLcdBuffer();
    if (dx < 1 or dx > 24) return;
    if (x_in >= SCREEN_WIDTH or x_in + dx > SCREEN_WIDTH) return;
    const x = SCREEN_WIDTH - dx - x_in;
    const byte_i = x >> 3;
    const bit_off: u5 = @intCast(x & 7);
    const lowmask = (@as(u32, 1) << @as(u5, @intCast(dx))) -% 1;
    const bytes_needed = (@as(u32, bit_off) + dx + 7) / 8;
    var srcbits: u32 = undefined;
    if (fill == BLT_SET and blt_op != BLT_XOR) {
        srcbits = if (blt_op == BLT_ANDN) lowmask << bit_off else 0;
    } else {
        srcbits = (val & lowmask) << bit_off;
    }
    const srcbytes = [4]u8{ @truncate(srcbits), @truncate(srcbits >> 8), @truncate(srcbits >> 16), @truncate(srcbits >> 24) };
    const base = y * (LCD_LINE_SIZE + 2) + byte_i + 2;
    var i: u32 = 0;
    switch (blt_op) {
        BLT_OR => while (i < bytes_needed) : (i += 1) {
            lcd_buffer[base + i] |= srcbytes[i];
        },
        BLT_XOR => while (i < bytes_needed) : (i += 1) {
            lcd_buffer[base + i] ^= srcbytes[i];
        },
        BLT_ANDN => while (i < bytes_needed) : (i += 1) {
            lcd_buffer[base + i] &= ~srcbytes[i];
        },
        else => return,
    }
    lcd_buffer[y * (LCD_LINE_SIZE + 2)] = 1; // mark line dirty
}

pub export fn lcd_fill_rect(x: u32, y: u32, dx: u32, dy: u32, val: c_int) callconv(.c) void {
    // C computes endX/endY with unsigned wraparound and rejects anything past
    // the screen; mirror the wrap so an off-screen rect is dropped, not panicked.
    const endX = x +% dx;
    const endY = y +% dy;
    if (endX > SCREEN_WIDTH or endY > SCREEN_HEIGHT) return;
    const blt_op: c_int = if (val != 0) BLT_OR else BLT_ANDN;
    var col = x;
    while (col < endX) : (col += 24) {
        const cols = if (24 < endX - col) @as(u32, 24) else endX - col;
        var line = y;
        while (line < endY) : (line += 1) {
            bitblt24(col, cols, line, 0xFFFFFF, blt_op, BLT_NONE);
        }
    }
}

pub export fn lcd_buffer_pixel_on(x: u32, y: u32) callconv(.c) u8 {
    ensureLcdBuffer();
    if (x >= SCREEN_WIDTH or y >= SCREEN_HEIGHT) return 0;
    const bitIndex = SCREEN_WIDTH - 1 - x;
    const byte_i = bitIndex >> 3;
    const bit_j: u3 = @intCast(bitIndex & 7);
    return (lcd_buffer[52 * y + 2 + byte_i] >> bit_j) & 1;
}
pub export fn _lcdRefresh() callconv(.c) void {}
pub export fn _lcdSBRefresh() callconv(.c) void {}
pub export fn _lcdBandRefresh(y: u32, dy: u32) callconv(.c) void {
    _ = .{ y, dy };
}
pub export fn lcd_refresh_lines(ln: u8, cnt: u8) callconv(.c) void {
    _ = .{ ln, cnt };
}
pub export fn refresh_gui() callconv(.c) void {}
pub export fn LCD_write_line(line_buf: [*c]u8) callconv(.c) void {
    _ = line_buf;
}
pub export fn lcd_refresh() callconv(.c) void {}

// ---------------------------------------------------------------------------
// print_ir.c — no infrared printer in the testSuite.
// ---------------------------------------------------------------------------
pub export fn getLineDelay() callconv(.c) u32 {
    return 0;
}
pub export fn setLineDelay(delay: u16) callconv(.c) void {
    _ = delay;
}
pub export fn sendByteIR(byte: u8) callconv(.c) void {
    _ = byte;
}

// ---------------------------------------------------------------------------
// io.c — real file I/O against the host filesystem (libc stdio).
// ---------------------------------------------------------------------------
const FILE = anyopaque;
extern fn fopen(filename: [*:0]const u8, mode: [*:0]const u8) ?*FILE;
extern fn fwrite(ptr: ?*const anyopaque, size: usize, n: usize, stream: ?*FILE) usize;
extern fn fread(ptr: ?*anyopaque, size: usize, n: usize, stream: ?*FILE) usize;
extern fn fseek(stream: ?*FILE, offset: c_long, whence: c_int) c_int;
extern fn fclose(stream: ?*FILE) c_int;
extern fn feof(stream: ?*FILE) c_int;
extern fn remove(path: [*:0]const u8) c_int;
extern fn printf(fmt: [*:0]const u8, ...) c_int;

const ioPathManualSave: c_int = 0;
const ioPathAutoSave: c_int = 1;
const ioPathPgmFile: c_int = 2;
const ioPathTestPgms: c_int = 3;
const ioPathBackup: c_int = 4;
// State-file paths (SAVEST / LOADST), used by the serialize-state coverage suite
// to round-trip the whole calculator state. io.h: SaveStateFile=6, LoadStateFile=7.
const ioPathSaveStateFile: c_int = 6;
const ioPathLoadStateFile: c_int = 7;
// Program write/export paths (WRITEP / EXPORTP / write-all), added upstream with
// the save/restore coverage suites. io.h: SaveProgram=8, ExportRTFProgram=10,
// SaveAllPrograms=12, ExportRTFAllPrograms=13.
const ioPathSaveProgram: c_int = 8;
const ioPathExportRTFProgram: c_int = 10;
const ioPathLoadProgram: c_int = 11;
const ioPathSaveAllPrograms: c_int = 12;
const ioPathExportRTFAllPrograms: c_int = 13;
const ioPathRegImport: c_int = 14;
const ioPathRegExport: c_int = 15;

// Settable load-file path for the headless .p47 runner (pgm_run_harness.c).
// Null in every other harness, so ioPathLoadProgram keeps returning null there.
pub export var z47_pgm_run_file: ?[*:0]const u8 = null;
const ioModeRead: c_int = 0;
const ioModeWrite: c_int = 1;
const ioModeUpdate: c_int = 2;
const FILE_OK: c_int = 1;
const FILE_ERROR: c_int = 0;
const SEEK_SET: c_int = 0;

var _ioFileHandle: ?*FILE = null;

// _ioFileNameOverride: the graph coverage suite's covBmpName() sprintf's the next
// SNAP capture's bitmap path here; the screen SNAP writer consumes and clears it.
// Storage-only in the headless HAL, matching io.c's definition (the SNAP path in
// screen reads it). The array is unsized in io.h, so any adequate size links.
pub export var _ioFileNameOverride: [1024]u8 = std.mem.zeroes([1024]u8);

// The testSuite is the C47 model (-DCALCMODEL=USER_C47), so the backup file is
// "backup.cfg". Returns null for an unknown path (C returned `false`/NULL).
fn ioFileNameFromFilePath(path: c_int) ?[*:0]const u8 {
    return switch (path) {
        ioPathManualSave => "c47.sav",
        ioPathAutoSave => "c47auto.sav",
        // Whole-state save/load round-trip to one headless file.
        ioPathSaveStateFile, ioPathLoadStateFile => "c47state.bin",
        ioPathPgmFile => "c47.dat",
        ioPathTestPgms => "res/testPgms/testPgms.bin",
        ioPathBackup => "backup.cfg",
        // Register data-file (DATA_FILE) import/export. Both map to one headless
        // file so the save/load parity harness can round-trip; the real HAL would
        // resolve these to a user-chosen path via a file dialog.
        ioPathRegImport, ioPathRegExport => "c47.regs",
        // Program write/export to a headless file so the save/restore coverage
        // suite can round-trip (the real HAL resolves these via a file dialog).
        ioPathSaveProgram => "c47program.bin",
        ioPathExportRTFProgram => "c47program.rtf",
        ioPathSaveAllPrograms => "c47programs.bin",
        ioPathExportRTFAllPrograms => "c47programs.rtf",
        // Headless .p47 runner sets z47_pgm_run_file; otherwise the coverage
        // suites' covWriteAndLoadPgm writes c47programTest.bin and loads it back.
        ioPathLoadProgram => z47_pgm_run_file orelse "c47programTest.bin",
        else => null,
    };
}

pub export fn ioFileOpen(path: c_int, mode: c_int) callconv(.c) c_int {
    const filename = ioFileNameFromFilePath(path) orelse return FILE_ERROR;
    const filemode: [*:0]const u8 = switch (mode) {
        ioModeRead => "rb",
        ioModeWrite => "wb",
        ioModeUpdate => "r+b",
        else => return FILE_ERROR,
    };
    _ioFileHandle = fopen(filename, filemode);
    return if (_ioFileHandle != null) FILE_OK else FILE_ERROR;
}

pub export fn ioFileWrite(buffer: ?*const anyopaque, size: u32) callconv(.c) void {
    _ = fwrite(buffer, 1, size, _ioFileHandle);
}

pub export fn ioFileRead(buffer: ?*anyopaque, size: u32) callconv(.c) u32 {
    return @intCast(fread(buffer, 1, size, _ioFileHandle));
}

pub export fn ioFileSeek(position: u32) callconv(.c) void {
    _ = fseek(_ioFileHandle, @intCast(position), SEEK_SET);
}

pub export fn ioFileClose() callconv(.c) void {
    _ = fclose(_ioFileHandle);
    _ioFileHandle = null;
}

pub export fn ioEof() callconv(.c) c_int {
    return feof(_ioFileHandle);
}

pub export fn ioFileRemove(path: c_int, errorNumber: ?*u32) callconv(.c) c_int {
    const filename = ioFileNameFromFilePath(path) orelse return FILE_ERROR;
    const result = remove(filename);
    if (result == -1 and errorNumber != null) {
        errorNumber.?.* = @intCast(std.c._errno().*);
    }
    return if (result != -1) FILE_OK else FILE_ERROR;
}

pub export fn show_warning(str: [*:0]const u8) callconv(.c) void {
    _ = printf("Warning: %s\n", str);
}

pub export fn fnDiskInfo(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
}
