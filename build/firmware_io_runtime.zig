// SPDX-License-Identifier: GPL-3.0-only
const build_options = @import("firmware_io_build_options");
const rom = @import("dmcp_rom");

// Console sinks (upstream's hal/console.c). Carried here rather than given
// their own build object because they are firmware-only io and this object is
// already linked into every board build; the force-import emits their exports.
// They must be in the link even though nothing here calls them -- see the file
// header for why leaving them undefined costs 316 bytes of SRAM2.
const console = @import("firmware_console_runtime.zig");
comptime {
    _ = console;
}

const FILE_ERROR: c_int = 0;
const FILE_OK: c_int = 1;
const FILE_CANCEL: c_int = 2;

const MRET_EXIT: c_int = -2;
const MRET_SAVESTATE: c_int = 777;
const MRET_LOADSTATE: c_int = 888;

const KEY_ENTER: c_int = 13;
const KEY_BSP: c_int = 17;
const KEY_EXIT: c_int = 33;

const FA_READ: u8 = 0x01;
const FA_WRITE: u8 = 0x02;
const FA_OPEN_EXISTING: u8 = 0x00;
const FA_CREATE_ALWAYS: u8 = 0x08;

// hal/io.h: the save files carry the model CALCMODEL builds.
const USER_R47: u8 = 66;
const built_for_r47 = build_options.calcmodel == USER_R47;
const SAVE_FILE = if (built_for_r47) "R47.sav" else "C47.sav";
const AUTO_SAVE_FILE = if (built_for_r47) "R47auto.sav" else "C47auto.sav";

const IO_PATH_MANUAL_SAVE: c_int = 0;
const IO_PATH_AUTO_SAVE: c_int = 1;
const IO_PATH_PGM_FILE: c_int = 2;
const IO_PATH_TEST_PGMS: c_int = 3;
const IO_PATH_REG_DUMP: c_int = 5;
const IO_PATH_SAVE_STATE_FILE: c_int = 6;
const IO_PATH_LOAD_STATE_FILE: c_int = 7;
const IO_PATH_SAVE_PROGRAM: c_int = 8;
const IO_PATH_EXPORT_RTF_PROGRAM: c_int = 10;
const IO_PATH_LOAD_PROGRAM: c_int = 11;
const IO_PATH_REG_IMPORT: c_int = 14;
const IO_PATH_REG_EXPORT: c_int = 15;

// The directories and extensions of hal/io.h.
const STATE_DIR = "STATE";
const STATE_EXT = ".s47";
const DATA_DIR = "DATA";
const DATA_EXT = ".d47";
const PROGRAMS_DIR = "PROGRAMS";
const PRGM_EXT = ".p47";
const RTF_EXT = ".rtf";

// clearScreenStatusBar (screen.h) and what it reaches: the status bar strip is
// the whole screen width, or the graph info box's width while a graph is up.
const SCREEN_WIDTH: u32 = 400;
const STATUS_BAR_HEIGHT: u32 = 20;
const widthGraphInfoBox: u32 = 158;
const LCD_SET_VALUE: c_int = 0;
const CM_PLOT_STAT: u8 = 8;
const CM_GRAPH: u8 = 15;
const SCRUPD_AUTO: u8 = 0x00;
extern var calcMode: u8;
extern var screenUpdatingMode: u8;
extern fn forceSBupdate() void;

const IO_MODE_READ: c_int = 0;
const IO_MODE_WRITE: c_int = 1;
const IO_MODE_UPDATE: c_int = 2;

const STATE_FILE_NAME_VAR_LENGTH: usize = 20;

var io_write_enabled: c_int = 0;
var io_read_enabled: c_int = 0;

extern var fileNameSelected: [STATE_FILE_NAME_VAR_LENGTH]u8;
extern fn strtok(str: [*c]u8, delim: [*c]const u8) [*c]u8;

fn menuDisplay() ?*rom.disp_stat_t {
    return rom.sdb().pds_t24;
}

// The file handle is DMCP's, not ours: upstream's hal/io.c passes the SDK's
// `ppgm_fp` (dmcp.h: `#define ppgm_fp (sdb.ppgm_fp)`) to every f_open/f_read/
// f_write, so the FIL -- and its 512-byte FatFS sector buffer -- lives in DMCP's
// memory. Owning a private FIL here both diverged from that shared handle and
// spent 564 bytes of the DM42's 8Kb .data+.bss budget below the system data
// block, which the linker script asserts.
fn programFile() ?*rom.FIL {
    return rom.sdb().ppgm_fp;
}

fn lcdSetLine(display: *rom.disp_stat_t, line: c_int) void {
    rom.lcd_setLine(display, line);
}

fn lcdWriteText(display: *rom.disp_stat_t, text: [*c]const u8) void {
    rom.lcd_writeText(display, text);
}

fn lcdRefresh() void {
    rom.lcd_refresh();
}

fn lcdRefreshWait() void {
    rom.lcd_refresh_wait();
}

fn lcdClearBuffer() void {
    rom.lcd_clear_buf();
}

fn lcdFillRect(x: u32, y: u32, dx: u32, dy: u32, val: c_int) void {
    rom.lcd_fill_rect(x, y, dx, dy, val);
}

inline fn graphMode() bool {
    return calcMode == CM_PLOT_STAT or calcMode == CM_GRAPH;
}

// screen.h's clearScreenStatusBar macro: blank the status bar strip and mark
// every status bar item as changed, so the next refresh paints it whole. The
// count is the macro's call-site tag and is not used.
fn clearScreenStatusBar(cnt: u16) void {
    _ = cnt;
    lcdFillRect(0, 0, if (graphMode()) widthGraphInfoBox else SCREEN_WIDTH, STATUS_BAR_HEIGHT, LCD_SET_VALUE);
    forceSBupdate();
}

fn setResetStateFile(path: [*c]const u8) void {
    rom.set_reset_state_file(path);
}

fn displayDiskInfo(title: [*c]const u8) void {
    rom.disp_disk_info(title);
}

fn checkCreateDir(path: [*c]const u8) void {
    _ = rom.check_create_dir(path);
}

fn fileSelectionScreen(title: [*c]const u8, base_dir: [*c]const u8, ext: [*c]const u8, callback: ?*const rom.file_sel_fn_t, disp_save: c_int, overwrite_check: c_int, data: ?[*]u8) c_int {
    return rom.file_selection_screen(title, base_dir, ext, callback, disp_save, overwrite_check, data);
}

fn waitForKeyPress() void {
    rom.wait_for_key_press();
}

fn runnerGetKey(arg: ?*c_int) c_int {
    return rom.runner_get_key(arg);
}

fn waitForKeyRelease(timeout: c_int) void {
    rom.wait_for_key_release(timeout);
}

fn isMenuAutoOff() c_int {
    return rom.is_menu_auto_off();
}

fn sysDiskWriteEnable(enabled: c_int) void {
    _ = rom.sys_disk_write_enable(enabled);
}

fn fileOpen(file: ?*rom.FIL, path: [*c]const u8, mode: u8) c_uint {
    return rom.f_open(file, path, mode);
}

fn fileClose(file: ?*rom.FIL) c_uint {
    return rom.f_close(file);
}

fn fileRead(file: ?*rom.FIL, buffer: ?*anyopaque, size: u32, read: *rom.UINT) c_uint {
    return rom.f_read(file, buffer, size, read);
}

fn fileWrite(file: ?*rom.FIL, buffer: ?*const anyopaque, size: u32, written: *rom.UINT) c_uint {
    return rom.f_write(file, buffer, size, written);
}

fn fileSeek(file: ?*rom.FIL, position: u32) c_uint {
    return rom.f_lseek(file, position);
}

fn fileUnlink(path: [*c]const u8) c_uint {
    return rom.f_unlink(path);
}

fn isExitKey(key: c_int) bool {
    return key == KEY_EXIT or key == KEY_BSP;
}

fn copyCString(dst: [*c]u8, src: [*c]const u8) void {
    var index: usize = 0;
    while (true) : (index += 1) {
        dst[index] = src[index];
        if (src[index] == 0) break;
    }
}

fn copyCStringBounded(dst: []u8, src: [*c]const u8) void {
    if (dst.len == 0) return;

    var index: usize = 0;
    while (index + 1 < dst.len and src[index] != 0) : (index += 1) {
        dst[index] = src[index];
    }
    dst[index] = 0;
}

fn cStringLength(str: [*c]const u8) c_int {
    var index: c_int = 0;
    while (str[@intCast(index)] != 0) : (index += 1) {}
    return index;
}

fn lcdPuts(text: [*c]const u8) void {
    const display = menuDisplay() orelse return;
    lcdWriteText(display, text);
}

fn lcdPutsRAt(line: c_int, text: [*c]const u8) void {
    const display = menuDisplay() orelse return;
    lcdSetLine(display, line);
    display.inv = 1;
    lcdWriteText(display, text);
    display.inv = 0;
}

// One file selection screen: the directory is created first, the DMCP menu
// takes the screen, and afterwards the status bar strip it drew over is
// blanked and the screen update mode put back to automatic.
fn fileSelectionHelper(title: [*c]const u8, base_dir: [*c]const u8, ext: [*c]const u8, sel_fn: ?*const rom.file_sel_fn_t, is_save: c_int, filename: [*c]u8) c_int {
    checkCreateDir(base_dir);
    const ret = fileSelectionScreen(title, base_dir, ext, sel_fn, is_save, is_save, filename);
    clearScreenStatusBar(204);
    screenUpdatingMode = SCRUPD_AUTO;
    return if (ret == MRET_EXIT) FILE_CANCEL else FILE_OK;
}

// config.c's DMCP ROM wrapper.
extern fn dmcpResetAutoOff() void;

pub export fn _ioFileNameFromFilePath(path: c_int, filename: [*c]u8) callconv(.c) c_int {
    // c47-dmcp/hal/io.c: a long keyless program run leaves the menu auto-off
    // timer expired, which makes file_selection_screen exit at once. DMCP5's
    // io.c has no such reset.
    if (comptime build_options.dm42_board) dmcpResetAutoOff();
    switch (path) {
        IO_PATH_MANUAL_SAVE => {
            checkCreateDir("SAVFILES");
            copyCString(filename, "SAVFILES\\" ++ SAVE_FILE);
            return FILE_OK;
        },
        IO_PATH_AUTO_SAVE => {
            checkCreateDir("SAVFILES");
            copyCString(filename, "SAVFILES\\" ++ AUTO_SAVE_FILE);
            return FILE_OK;
        },
        IO_PATH_PGM_FILE => {
            checkCreateDir("LIBRARY");
            copyCString(filename, "LIBRARY\\C47.dat");
            return FILE_OK;
        },
        IO_PATH_TEST_PGMS => {
            copyCString(filename, "testPgms.bin");
            return FILE_OK;
        },
        IO_PATH_REG_DUMP => return FILE_OK,
        IO_PATH_REG_EXPORT => return fileSelectionHelper("Export Register/Flag Data File", DATA_DIR, DATA_EXT, &save_datafile, 1, filename),
        IO_PATH_REG_IMPORT => return fileSelectionHelper("Import Register/Flag Data File", DATA_DIR, DATA_EXT, &load_datafile, 0, filename),
        IO_PATH_SAVE_STATE_FILE => return fileSelectionHelper("Save Calculator State", STATE_DIR, STATE_EXT, &save_statefile, 1, filename),
        IO_PATH_LOAD_STATE_FILE => return fileSelectionHelper("Load Calculator State", STATE_DIR, STATE_EXT, &load_statefile, 0, filename),
        IO_PATH_SAVE_PROGRAM => return fileSelectionHelper("Save Program", PROGRAMS_DIR, PRGM_EXT, &save_programfile, 1, filename),
        IO_PATH_EXPORT_RTF_PROGRAM => return fileSelectionHelper("Export Program RTF", PROGRAMS_DIR, RTF_EXT, &save_programfile, 1, filename),
        IO_PATH_LOAD_PROGRAM => return fileSelectionHelper("Load Program", PROGRAMS_DIR, PRGM_EXT, &load_programfile, 0, filename),
        else => return FILE_ERROR,
    }
}

pub export fn ioFileOpen(path: c_int, mode: c_int) callconv(.c) c_int {
    var filename: [40]u8 = @splat(0);
    var filemode: u8 = 0;

    fileNameSelected[0] = 0;

    const ret = _ioFileNameFromFilePath(path, &filename);
    if (ret != FILE_OK) return ret;

    switch (mode) {
        IO_MODE_READ => {
            filemode = FA_READ;
            io_read_enabled = 1;
        },
        IO_MODE_WRITE => {
            filemode = FA_CREATE_ALWAYS | FA_WRITE;
            io_write_enabled = 1;
        },
        IO_MODE_UPDATE => {
            filemode = FA_READ | FA_WRITE | FA_OPEN_EXISTING;
            io_write_enabled = 1;
            io_read_enabled = 1;
        },
        else => return FILE_ERROR,
    }

    if (mode != IO_MODE_READ) {
        sysDiskWriteEnable(1);
    }

    const result = fileOpen(programFile(), &filename, filemode);
    if (result != 0) {
        if (mode != IO_MODE_READ) {
            sysDiskWriteEnable(0);
        }
        io_write_enabled = 0;
        io_read_enabled = 0;
        return FILE_ERROR;
    }

    if (mode == IO_MODE_READ) {
        var jj: c_int = cStringLength(&filename);
        const kk: c_int = if (jj - @as(c_int, STATE_FILE_NAME_VAR_LENGTH) + 1 > 0) jj - @as(c_int, STATE_FILE_NAME_VAR_LENGTH) + 1 else 0;
        while (jj > kk) {
            const c = filename[@intCast(jj - 1)];
            if (c != '\\' and c != '/' and c != 0) {
                jj -= 1;
            } else {
                break;
            }
        }
        copyCStringBounded(fileNameSelected[0..], filename[@intCast(jj)..].ptr);
    }

    return FILE_OK;
}

pub export fn ioFileWrite(buffer: ?*const anyopaque, size: u32) callconv(.c) void {
    var bytes_written: rom.UINT = 0;
    _ = fileWrite(programFile(), buffer, size, &bytes_written);
}

pub export fn ioFileRead(buffer: ?*anyopaque, size: u32) callconv(.c) u32 {
    var bytes_read: rom.UINT = 0;
    _ = fileRead(programFile(), buffer, size, &bytes_read);
    return bytes_read;
}

pub export fn ioFileSeek(position: u32) callconv(.c) void {
    _ = fileSeek(programFile(), position);
}

pub export fn ioFileClose() callconv(.c) void {
    _ = fileClose(programFile());
    if (io_write_enabled != 0) {
        sysDiskWriteEnable(0);
    }
    io_write_enabled = 0;
    io_read_enabled = 0;
}

pub export fn ioEof() callconv(.c) c_int {
    const file = programFile() orelse return 1;
    return @intFromBool(file.fptr == file.obj.objsize);
}

pub export fn save_statefile(fpath: [*:0]const u8, fname: [*:0]const u8, data: ?[*]u8) callconv(.c) c_int {
    lcdPuts("Saving state ...");
    lcdPuts(fname);
    lcdRefresh();

    if (data != null) {
        copyCString(data.?, fpath);
    }
    setResetStateFile(fpath);
    return MRET_SAVESTATE;
}

pub export fn load_statefile(fpath: [*:0]const u8, fname: [*:0]const u8, data: ?[*]u8) callconv(.c) c_int {
    _ = fname;

    lcdPuts("");
    lcdPuts("WARNING: Current calculator state");
    lcdPuts("will be lost.");
    lcdPuts("");
    lcdPuts("");
    lcdPuts("Press [ENTER] to confirm.");
    lcdRefresh();

    waitForKeyRelease(-1);

    while (true) {
        const key = runnerGetKey(null);
        if (isExitKey(key)) {
            return 0;
        }
        if (isMenuAutoOff() != 0) {
            return MRET_EXIT;
        }
        if (key == KEY_ENTER) {
            break;
        }
    }

    lcdPutsRAt(6, "  Loading ...");
    lcdRefreshWait();

    if (data != null) {
        copyCString(data.?, fpath);
    }
    setResetStateFile(fpath);
    return MRET_LOADSTATE;
}

pub export fn save_datafile(fpath: [*:0]const u8, fname: [*:0]const u8, data: ?[*]u8) callconv(.c) c_int {
    lcdPuts("Saving register(s) ...");
    lcdPuts(fname);
    lcdRefresh();

    if (data != null) {
        copyCString(data.?, fpath);
    }
    return MRET_SAVESTATE;
}

pub export fn load_datafile(fpath: [*:0]const u8, fname: [*:0]const u8, data: ?[*]u8) callconv(.c) c_int {
    _ = fname;

    lcdPutsRAt(6, "  Loading ...");
    lcdRefreshWait();

    if (data != null) {
        copyCString(data.?, fpath);
    }
    return MRET_LOADSTATE;
}

pub export fn save_programfile(fpath: [*:0]const u8, fname: [*:0]const u8, data: ?[*]u8) callconv(.c) c_int {
    lcdPuts("Saving program ...");
    lcdPuts(fname);
    lcdRefresh();

    if (data != null) {
        copyCString(data.?, fpath);
    }
    return MRET_SAVESTATE;
}

pub export fn load_programfile(fpath: [*:0]const u8, fname: [*:0]const u8, data: ?[*]u8) callconv(.c) c_int {
    _ = fname;

    lcdPutsRAt(6, "  Loading ...");
    lcdRefreshWait();

    if (data != null) {
        copyCString(data.?, fpath);
    }
    return MRET_LOADSTATE;
}

pub export fn show_warning(str: [*c]u8) callconv(.c) void {
    const delim = "\n";
    var ptr = strtok(str, "\n");

    const display = menuDisplay() orelse return;
    lcdClearBuffer();
    lcdPutsRAt(0, "                   WARNING");
    lcdSetLine(display, 1);

    while (ptr != null) {
        lcdPuts(ptr);
        ptr = strtok(null, delim);
    }

    lcdPutsRAt(8, "Press [ENTER] to continue.");
    lcdRefresh();
    waitForKeyRelease(-1);

    while (true) {
        const key = runnerGetKey(null);
        if (key == KEY_ENTER or isExitKey(key) or isMenuAutoOff() != 0) {
            break;
        }
    }
    clearScreenStatusBar(205);
    screenUpdatingMode = SCRUPD_AUTO;
}

pub export fn fnDiskInfo(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    displayDiskInfo("Disk Info");
    waitForKeyPress();
    clearScreenStatusBar(206);
    screenUpdatingMode = SCRUPD_AUTO;
}
