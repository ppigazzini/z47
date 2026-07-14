const build_options = @import("firmware_io_build_options");

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

const IO_MODE_READ: c_int = 0;
const IO_MODE_WRITE: c_int = 1;
const IO_MODE_UPDATE: c_int = 2;

const STATE_FILE_NAME_VAR_LENGTH: usize = 20;

const lcd_clear_buf_offset: usize = 44;
const lcd_refresh_offset: usize = 48;
const lcd_set_line_offset: usize = 104;
const lcd_write_text_offset: usize = 124;
const set_reset_state_file_offset: usize = 284;
const disp_disk_info_offset: usize = 332;
const file_selection_screen_offset: usize = 336;
const wait_for_key_press_offset: usize = 408;
const runner_get_key_offset: usize = 412;
const wait_for_key_release_offset: usize = 420;
const is_menu_auto_off_offset: usize = 448;
const check_create_dir_offset: usize = 464;
const sys_disk_write_enable_offset: usize = 480;
const f_open_offset: usize = 564;
const f_close_offset: usize = 568;
const f_read_offset: usize = 572;
const f_write_offset: usize = 576;
const f_lseek_offset: usize = 580;
const lcd_refresh_wait_offset: usize = 648;
const f_unlink_offset: usize = 768;

var io_write_enabled: c_int = 0;
var io_read_enabled: c_int = 0;
var program_file: Fil = undefined;

const DispStat = extern struct {
    f: ?*const anyopaque,
    x: i16,
    y: i16,
    ln_offs: i16,
    y_top_grd: i16,
    ya: i8,
    yb: i8,
    xspc: i8,
    xoffs: i8,
    fixed: u8,
    inv: u8,
    bgfill: u8,
    lnfill: u8,
    newln: u8,
    post_offs: [*c]const u8,
};

const Fdid = extern struct {
    fs: ?*anyopaque,
    id: u16,
    attr: u8,
    stat: u8,
    sclust: u32,
    objsize: c_ulong,
    lockid: c_uint,
};

const Fil = extern struct {
    obj: Fdid,
    flag: u8,
    err: u8,
    fptr: c_ulong,
    clust: u32,
    sect: u32,
    dir_sect: u32,
    dir_ptr: [*c]u8,
    cltbl: [*c]u32,
    buf: [512]u8,
};

const SysSdb = extern struct {
    calc_state: u32,
    ppgm_fp: ?*anyopaque,
    key_to_alpha_table: [*c]const u8,
    run_menu_item_app: ?*const anyopaque,
    menu_line_str_app: ?*const anyopaque,
    after_fat_format: ?*const anyopaque,
    get_flag_dmy: ?*const anyopaque,
    set_flag_dmy: ?*const anyopaque,
    is_flag_clk24: ?*const anyopaque,
    set_flag_clk24: ?*const anyopaque,
    is_beep_mute: ?*const anyopaque,
    set_beep_mute: ?*const anyopaque,
    pds_t20: ?*DispStat,
    pds_t24: ?*DispStat,
    pds_fReg: ?*DispStat,
};

extern var fileNameSelected: [STATE_FILE_NAME_VAR_LENGTH]u8;
extern fn strtok(str: [*c]u8, delim: [*c]const u8) [*c]u8;

const LcdSetLineFn = *const fn (*DispStat, c_int) callconv(.c) void;
const LcdWriteTextFn = *const fn (*DispStat, [*c]const u8) callconv(.c) void;
const VoidFn = *const fn () callconv(.c) void;
const SetResetStateFileFn = *const fn ([*c]const u8) callconv(.c) void;
const StringFn = *const fn ([*c]const u8) callconv(.c) void;
const FileSelectionScreenFn = *const fn ([*c]const u8, [*c]const u8, [*c]const u8, ?*const anyopaque, c_int, c_int, ?*anyopaque) callconv(.c) c_int;
const RunnerGetKeyFn = *const fn (?*anyopaque) callconv(.c) c_int;
const WaitForKeyReleaseFn = *const fn (c_int) callconv(.c) void;
const IsMenuAutoOffFn = *const fn () callconv(.c) c_int;
const DiskWriteEnableFn = *const fn (c_int) callconv(.c) void;
const FileOpenFn = *const fn (?*anyopaque, [*c]const u8, u8) callconv(.c) c_uint;
const FileCloseFn = *const fn (?*anyopaque) callconv(.c) c_uint;
const FileReadFn = *const fn (?*anyopaque, ?*anyopaque, u32, [*c]u32) callconv(.c) c_uint;
const FileWriteFn = *const fn (?*anyopaque, ?*const anyopaque, u32, [*c]u32) callconv(.c) c_uint;
const FileSeekFn = *const fn (?*anyopaque, u32) callconv(.c) c_uint;
const FileUnlinkFn = *const fn ([*c]const u8) callconv(.c) c_uint;

fn menuDisplay() ?*DispStat {
    const sdb: *const SysSdb = @ptrFromInt(build_options.sdb_base);
    return sdb.pds_t24;
}

fn programFileHandle() ?*anyopaque {
    return &program_file;
}

fn programFileStruct() *Fil {
    return &program_file;
}

fn lcdSetLine(display: *DispStat, line: c_int) void {
    const function: LcdSetLineFn = @ptrFromInt(build_options.library_fn_base + lcd_set_line_offset);
    function(display, line);
}

fn lcdWriteText(display: *DispStat, text: [*c]const u8) void {
    const function: LcdWriteTextFn = @ptrFromInt(build_options.library_fn_base + lcd_write_text_offset);
    function(display, text);
}

fn lcdRefresh() void {
    const function: VoidFn = @ptrFromInt(build_options.library_fn_base + lcd_refresh_offset);
    function();
}

fn lcdRefreshWait() void {
    const function: VoidFn = @ptrFromInt(build_options.library_fn_base + lcd_refresh_wait_offset);
    function();
}

fn lcdClearBuffer() void {
    const function: VoidFn = @ptrFromInt(build_options.library_fn_base + lcd_clear_buf_offset);
    function();
}

fn setResetStateFile(path: [*c]const u8) void {
    const function: SetResetStateFileFn = @ptrFromInt(build_options.library_fn_base + set_reset_state_file_offset);
    function(path);
}

fn displayDiskInfo(title: [*c]const u8) void {
    const function: StringFn = @ptrFromInt(build_options.library_fn_base + disp_disk_info_offset);
    function(title);
}

fn checkCreateDir(path: [*c]const u8) void {
    const function: StringFn = @ptrFromInt(build_options.library_fn_base + check_create_dir_offset);
    function(path);
}

fn fileSelectionScreen(title: [*c]const u8, base_dir: [*c]const u8, ext: [*c]const u8, callback: ?*const anyopaque, disp_save: c_int, overwrite_check: c_int, data: ?*anyopaque) c_int {
    const function: FileSelectionScreenFn = @ptrFromInt(build_options.library_fn_base + file_selection_screen_offset);
    return function(title, base_dir, ext, callback, disp_save, overwrite_check, data);
}

fn waitForKeyPress() void {
    const function: VoidFn = @ptrFromInt(build_options.library_fn_base + wait_for_key_press_offset);
    function();
}

fn runnerGetKey(arg: ?*anyopaque) c_int {
    const function: RunnerGetKeyFn = @ptrFromInt(build_options.library_fn_base + runner_get_key_offset);
    return function(arg);
}

fn waitForKeyRelease(timeout: c_int) void {
    const function: WaitForKeyReleaseFn = @ptrFromInt(build_options.library_fn_base + wait_for_key_release_offset);
    function(timeout);
}

fn isMenuAutoOff() c_int {
    const function: IsMenuAutoOffFn = @ptrFromInt(build_options.library_fn_base + is_menu_auto_off_offset);
    return function();
}

fn sysDiskWriteEnable(enabled: c_int) void {
    const function: DiskWriteEnableFn = @ptrFromInt(build_options.library_fn_base + sys_disk_write_enable_offset);
    function(enabled);
}

fn fileOpen(file: ?*anyopaque, path: [*c]const u8, mode: u8) c_uint {
    const function: FileOpenFn = @ptrFromInt(build_options.library_fn_base + f_open_offset);
    return function(file, path, mode);
}

fn fileClose(file: ?*anyopaque) c_uint {
    const function: FileCloseFn = @ptrFromInt(build_options.library_fn_base + f_close_offset);
    return function(file);
}

fn fileRead(file: ?*anyopaque, buffer: ?*anyopaque, size: u32, read: [*c]u32) c_uint {
    const function: FileReadFn = @ptrFromInt(build_options.library_fn_base + f_read_offset);
    return function(file, buffer, size, read);
}

fn fileWrite(file: ?*anyopaque, buffer: ?*const anyopaque, size: u32, written: [*c]u32) c_uint {
    const function: FileWriteFn = @ptrFromInt(build_options.library_fn_base + f_write_offset);
    return function(file, buffer, size, written);
}

fn fileSeek(file: ?*anyopaque, position: u32) c_uint {
    const function: FileSeekFn = @ptrFromInt(build_options.library_fn_base + f_lseek_offset);
    return function(file, position);
}

fn fileUnlink(path: [*c]const u8) c_uint {
    const function: FileUnlinkFn = @ptrFromInt(build_options.library_fn_base + f_unlink_offset);
    return function(path);
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

pub export fn _ioFileNameFromFilePath(path: c_int, filename: [*c]u8) callconv(.c) c_int {
    var ret: c_int = 0;
    switch (path) {
        IO_PATH_MANUAL_SAVE => {
            checkCreateDir("SAVFILES");
            copyCString(filename, "SAVFILES\\C47.sav");
            return FILE_OK;
        },
        IO_PATH_AUTO_SAVE => {
            checkCreateDir("SAVFILES");
            copyCString(filename, "SAVFILES\\C47auto.sav");
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
        IO_PATH_SAVE_STATE_FILE => {
            checkCreateDir("STATE");
            ret = fileSelectionScreen("Save Calculator State", "STATE", ".s47", @ptrCast(&save_statefile), 1, 1, filename);
            return if (ret == MRET_EXIT) FILE_CANCEL else FILE_OK;
        },
        IO_PATH_LOAD_STATE_FILE => {
            checkCreateDir("STATE");
            ret = fileSelectionScreen("Load Calculator State", "STATE", ".s47", @ptrCast(&load_statefile), 0, 0, filename);
            return if (ret == MRET_EXIT) FILE_CANCEL else FILE_OK;
        },
        IO_PATH_SAVE_PROGRAM => {
            checkCreateDir("PROGRAMS");
            ret = fileSelectionScreen("Save Program", "PROGRAMS", ".p47", @ptrCast(&save_programfile), 1, 1, filename);
            return if (ret == MRET_EXIT) FILE_CANCEL else FILE_OK;
        },
        IO_PATH_EXPORT_RTF_PROGRAM => {
            checkCreateDir("PROGRAMS");
            ret = fileSelectionScreen("Export Program RTF", "PROGRAMS", ".rtf", @ptrCast(&save_programfile), 1, 1, filename);
            return if (ret == MRET_EXIT) FILE_CANCEL else FILE_OK;
        },
        IO_PATH_LOAD_PROGRAM => {
            checkCreateDir("PROGRAMS");
            ret = fileSelectionScreen("Load Program", "PROGRAMS", ".p47", @ptrCast(&load_programfile), 0, 0, filename);
            return if (ret == MRET_EXIT) FILE_CANCEL else FILE_OK;
        },
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

    const result = fileOpen(programFileHandle(), &filename, filemode);
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
        copyCStringBounded(fileNameSelected[0..], @ptrCast((&filename)[@intCast(jj)..].ptr));
    }

    return FILE_OK;
}

pub export fn ioFileWrite(buffer: ?*const anyopaque, size: u32) callconv(.c) void {
    var bytes_written: u32 = 0;
    _ = fileWrite(programFileHandle(), buffer, size, &bytes_written);
}

pub export fn ioFileRead(buffer: ?*anyopaque, size: u32) callconv(.c) u32 {
    var bytes_read: u32 = 0;
    _ = fileRead(programFileHandle(), buffer, size, &bytes_read);
    return bytes_read;
}

pub export fn ioFileSeek(position: u32) callconv(.c) void {
    _ = fileSeek(programFileHandle(), position);
}

pub export fn ioFileClose() callconv(.c) void {
    _ = fileClose(programFileHandle());
    if (io_write_enabled != 0) {
        sysDiskWriteEnable(0);
    }
    io_write_enabled = 0;
    io_read_enabled = 0;
}

pub export fn ioEof() callconv(.c) c_int {
    const file = programFileStruct();
    return @intFromBool(file.fptr == file.obj.objsize);
}

pub export fn ioFileRemove(path: c_int, error_number: ?*u32) callconv(.c) c_int {
    var filename: [40]u8 = @splat(0);

    sysDiskWriteEnable(1);
    const ret = _ioFileNameFromFilePath(path, &filename);
    if (ret != FILE_OK) {
        sysDiskWriteEnable(0);
        return ret;
    }

    const result = fileUnlink(&filename);
    if (result != 0 and error_number != null) {
        error_number.?.* = result;
    }
    sysDiskWriteEnable(0);
    return if (result == 0) FILE_OK else FILE_ERROR;
}

pub export fn save_statefile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) callconv(.c) c_int {
    lcdPuts("Saving state ...");
    lcdPuts(fname);
    lcdRefresh();

    if (data != null) {
        copyCString(@ptrCast(data.?), fpath);
    }
    setResetStateFile(fpath);
    return MRET_SAVESTATE;
}

pub export fn load_statefile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) callconv(.c) c_int {
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
        copyCString(@ptrCast(data.?), fpath);
    }
    setResetStateFile(fpath);
    return MRET_LOADSTATE;
}

pub export fn save_programfile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) callconv(.c) c_int {
    lcdPuts("Saving program ...");
    lcdPuts(fname);
    lcdRefresh();

    if (data != null) {
        copyCString(@ptrCast(data.?), fpath);
    }
    return MRET_SAVESTATE;
}

pub export fn load_programfile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) callconv(.c) c_int {
    _ = fname;

    lcdPutsRAt(6, "  Loading ...");
    lcdRefreshWait();

    if (data != null) {
        copyCString(@ptrCast(data.?), fpath);
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
}

pub export fn fnDiskInfo(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    displayDiskInfo("Disk Info");
    waitForKeyPress();
}
