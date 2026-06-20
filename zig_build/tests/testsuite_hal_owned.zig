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
// lcd.c — no framebuffer in the testSuite.
// ---------------------------------------------------------------------------
pub export fn lcd_fill_rect(x: u32, y: u32, dx: u32, dy: u32, val: c_int) callconv(.c) void {
    _ = .{ x, y, dx, dy, val };
}
pub export fn _lcdRefresh() callconv(.c) void {}
pub export fn bitblt24(x: u32, dx: u32, y: u32, val: u32, blt_op: c_int, fill: c_int) callconv(.c) void {
    _ = .{ x, dx, y, val, blt_op, fill };
}
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
extern fn @"__errno_location"() *c_int;

const ioPathManualSave: c_int = 0;
const ioPathPgmFile: c_int = 2;
const ioPathTestPgms: c_int = 3;
const ioPathBackup: c_int = 4;
const ioModeRead: c_int = 0;
const ioModeWrite: c_int = 1;
const ioModeUpdate: c_int = 2;
const FILE_OK: c_int = 1;
const FILE_ERROR: c_int = 0;
const SEEK_SET: c_int = 0;

var _ioFileHandle: ?*FILE = null;

// The testSuite is the C47 model (-DCALCMODEL=USER_C47), so the backup file is
// "backup.cfg". Returns null for an unknown path (C returned `false`/NULL).
fn ioFileNameFromFilePath(path: c_int) ?[*:0]const u8 {
    return switch (path) {
        ioPathManualSave => "c47.sav",
        ioPathPgmFile => "c47.dat",
        ioPathTestPgms => "res/testPgms/testPgms.bin",
        ioPathBackup => "backup.cfg",
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
        errorNumber.?.* = @intCast(@"__errno_location"().*);
    }
    return if (result != -1) FILE_OK else FILE_ERROR;
}

pub export fn show_warning(str: [*:0]const u8) callconv(.c) void {
    _ = printf("Warning: %s\n", str);
}

pub export fn fnDiskInfo(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
}
