const FILE_ERROR: c_int = 0;
const FILE_OK: c_int = 1;
const FILE_CANCEL: c_int = 2;

const MRET_EXIT: c_int = -2;
const MRET_SAVESTATE: c_int = 777;
const MRET_LOADSTATE: c_int = 888;

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

const FLAG_QUIET: u16 = 0x8019;
const FLAG_PRTACT: u16 = 0xc020;

var io_write_enabled: c_int = 0;
var io_read_enabled: c_int = 0;

extern fn start_buzzer_freq(frequency: u32) void;
extern fn sys_delay(ms: u32) void;
extern fn stop_buzzer() void;
extern fn getSystemFlag(flag: u16) c_int;
extern fn get_beep_volume() u16;
extern fn beep_volume_up() void;
extern fn beep_volume_down() void;
extern fn liftStack() void;
extern fn print_byte(byte: u8) void;
extern fn printer_get_delay() u16;
extern fn printer_set_delay(delay: u16) u16;

extern fn check_create_dir(path: [*c]const u8) void;
extern fn file_selection_screen(
    title: [*c]const u8,
    base_dir: [*c]const u8,
    ext: [*c]const u8,
    callback: ?*const anyopaque,
    disp_save: c_int,
    overwrite_check: c_int,
    data: ?*anyopaque,
) c_int;

extern fn f_open(fp: ?*anyopaque, path: [*c]const u8, mode: u8) c_uint;
extern fn f_write(fp: ?*anyopaque, buffer: ?*const anyopaque, size: u32, written: [*c]u32) c_uint;
extern fn f_read(fp: ?*anyopaque, buffer: ?*anyopaque, size: u32, read: [*c]u32) c_uint;
extern fn f_lseek(fp: ?*anyopaque, pos: u32) c_uint;
extern fn f_close(fp: ?*anyopaque) c_uint;
extern fn f_eof(fp: ?*anyopaque) c_int;
extern fn f_unlink(path: [*c]const u8) c_uint;
extern fn sys_disk_write_enable(enabled: c_int) void;

extern var ppgm_fp: ?*anyopaque;
extern var fileNameSelected: [*c]u8;

extern fn stringByteLength(s: [*c]const u8) c_int;
extern fn stringCopy(dst: [*c]u8, src: [*c]const u8) void;
extern fn max(a: c_int, b: c_int) c_int;
extern var stateFileNameVarLength: c_int;

extern fn lcd_puts(line: c_int, text: [*c]const u8) void;
extern fn lcd_putsRAt(line: c_int, col: c_int, text: [*c]const u8) void;
extern fn lcd_refresh() void;
extern fn lcd_refresh_wait() void;
extern fn lcd_clear_buf() void;
extern fn lcd_setLine(line: c_int, row: c_int) void;
extern var t24: c_int;
extern fn wait_for_key_release(timeout: c_int) void;
extern fn wait_for_key_press() void;
extern fn runner_get_key(arg: ?*anyopaque) c_int;
extern fn is_menu_auto_off() c_int;
extern fn disp_disk_info(title: [*c]const u8) void;
extern fn set_reset_state_file(path: [*c]const u8) void;

extern fn strcpy(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strtok(str: [*c]u8, delim: [*c]const u8) [*c]u8;

pub export fn audioTone(frequency: u32) callconv(.c) void {
    start_buzzer_freq(frequency);
    sys_delay(250);
    stop_buzzer();
}

pub export fn dm42_squeak() callconv(.c) void {
    if (getSystemFlag(FLAG_QUIET) == 0) {
        start_buzzer_freq(1835000);
        sys_delay(125);
        stop_buzzer();
    }
}

pub export fn fnSetVolume(volume: u16) callconv(.c) void {
    var current = get_beep_volume();
    while (current < volume) : (current += 1) {
        beep_volume_up();
    }
    while (current > volume) : (current -= 1) {
        beep_volume_down();
    }
}

pub export fn getBeepVolume() callconv(.c) u16 {
    return get_beep_volume();
}

pub export fn fnGetVolume(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    liftStack();
}

pub export fn fnVolumeUp(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    beep_volume_up();
    audioTone(440000);
}

pub export fn fnVolumeDown(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    beep_volume_down();
    audioTone(440000);
}

pub export fn _Buzz(frequency: u32, ms_delay: u32) callconv(.c) void {
    if (ms_delay == 0) return;

    var safe_delay = ms_delay;
    if (safe_delay > 2000) safe_delay = 2000;

    if (frequency != 0) {
        var safe_frequency = frequency;
        if (safe_frequency > 20000) safe_frequency = 20000;
        start_buzzer_freq(safe_frequency * 1000);
        sys_delay(safe_delay);
        stop_buzzer();
    } else {
        sys_delay(safe_delay);
    }
}

pub export fn fnBuzz(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
}

pub export fn fnPlay(regist: u16) callconv(.c) void {
    _ = regist;
}

pub export fn getLineDelay() callconv(.c) u32 {
    return @divTrunc(printer_get_delay(), 100);
}

pub export fn setLineDelay(delay: u16) callconv(.c) void {
    _ = printer_set_delay(delay * 100);
}

pub export fn sendByteIR(byte: u8) callconv(.c) void {
    if (getSystemFlag(FLAG_PRTACT) != 0) {
        print_byte(byte);
    }
}

pub export fn _ioFileNameFromFilePath(path: c_int, filename: [*c]u8) callconv(.c) c_int {
    var ret: c_int = 0;
    switch (path) {
        IO_PATH_MANUAL_SAVE => {
            check_create_dir("SAVFILES");
            _ = strcpy(filename, "SAVFILES\\C47.sav");
            return FILE_OK;
        },
        IO_PATH_AUTO_SAVE => {
            check_create_dir("SAVFILES");
            _ = strcpy(filename, "SAVFILES\\C47auto.sav");
            return FILE_OK;
        },
        IO_PATH_PGM_FILE => {
            check_create_dir("LIBRARY");
            _ = strcpy(filename, "LIBRARY\\C47.dat");
            return FILE_OK;
        },
        IO_PATH_TEST_PGMS => {
            _ = strcpy(filename, "testPgms.bin");
            return FILE_OK;
        },
        IO_PATH_REG_DUMP => return FILE_OK,
        IO_PATH_SAVE_STATE_FILE => {
            check_create_dir("STATE");
            ret = file_selection_screen("Save Calculator State", "STATE", ".s47", @ptrCast(&save_statefile), 1, 1, filename);
            return if (ret == MRET_EXIT) FILE_CANCEL else FILE_OK;
        },
        IO_PATH_LOAD_STATE_FILE => {
            check_create_dir("STATE");
            ret = file_selection_screen("Load Calculator State", "STATE", ".s47", @ptrCast(&load_statefile), 0, 0, filename);
            return if (ret == MRET_EXIT) FILE_CANCEL else FILE_OK;
        },
        IO_PATH_SAVE_PROGRAM => {
            check_create_dir("PROGRAMS");
            ret = file_selection_screen("Save Program", "PROGRAMS", ".p47", @ptrCast(&save_programfile), 1, 1, filename);
            return if (ret == MRET_EXIT) FILE_CANCEL else FILE_OK;
        },
        IO_PATH_EXPORT_RTF_PROGRAM => {
            check_create_dir("PROGRAMS");
            ret = file_selection_screen("Export Program RTF", "PROGRAMS", ".rtf", @ptrCast(&save_programfile), 1, 1, filename);
            return if (ret == MRET_EXIT) FILE_CANCEL else FILE_OK;
        },
        IO_PATH_LOAD_PROGRAM => {
            check_create_dir("PROGRAMS");
            ret = file_selection_screen("Load Program", "PROGRAMS", ".p47", @ptrCast(&load_programfile), 0, 0, filename);
            return if (ret == MRET_EXIT) FILE_CANCEL else FILE_OK;
        },
        else => return FILE_ERROR,
    }
}

pub export fn ioFileOpen(path: c_int, mode: c_int) callconv(.c) c_int {
    var filename: [40]u8 = [_]u8{0} ** 40;
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
        sys_disk_write_enable(1);
    }

    const result = f_open(ppgm_fp, &filename, filemode);
    if (result != 0) {
        if (mode != IO_MODE_READ) {
            sys_disk_write_enable(0);
        }
        io_write_enabled = 0;
        io_read_enabled = 0;
        return FILE_ERROR;
    }

    if (mode == IO_MODE_READ) {
        var jj: c_int = stringByteLength(&filename);
        const kk: c_int = max(0, jj - stateFileNameVarLength + 1);
        while (jj > kk) {
            const c = filename[@intCast(jj - 1)];
            if (c != '\\' and c != '/' and c != 0) {
                jj -= 1;
            } else {
                break;
            }
        }
        stringCopy(fileNameSelected, (&filename)[@intCast(jj)..]);
    }

    return FILE_OK;
}

pub export fn ioFileWrite(buffer: ?*const anyopaque, size: u32) callconv(.c) void {
    var bytes_written: u32 = 0;
    _ = f_write(ppgm_fp, buffer, size, &bytes_written);
}

pub export fn ioFileRead(buffer: ?*anyopaque, size: u32) callconv(.c) u32 {
    var bytes_read: u32 = 0;
    _ = f_read(ppgm_fp, buffer, size, &bytes_read);
    return bytes_read;
}

pub export fn ioFileSeek(position: u32) callconv(.c) void {
    _ = f_lseek(ppgm_fp, position);
}

pub export fn ioFileClose() callconv(.c) void {
    _ = f_close(ppgm_fp);
    if (io_write_enabled != 0) {
        sys_disk_write_enable(0);
    }
    io_write_enabled = 0;
    io_read_enabled = 0;
}

pub export fn ioEof() callconv(.c) c_int {
    return f_eof(ppgm_fp);
}

pub export fn ioFileRemove(path: c_int, error_number: ?*u32) callconv(.c) c_int {
    var filename: [40]u8 = [_]u8{0} ** 40;

    sys_disk_write_enable(1);
    const ret = _ioFileNameFromFilePath(path, &filename);
    if (ret != FILE_OK) {
        sys_disk_write_enable(0);
        return ret;
    }

    const result = f_unlink(&filename);
    if (result != 0 and error_number != null) {
        error_number.?.* = result;
    }
    sys_disk_write_enable(0);
    return if (result == 0) FILE_OK else FILE_ERROR;
}

pub export fn save_statefile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) callconv(.c) c_int {
    _ = fname;
    if (data != null) {
        _ = strcpy(@ptrCast(data.?), fpath);
    }
    set_reset_state_file(fpath);
    return MRET_SAVESTATE;
}

pub export fn load_statefile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) callconv(.c) c_int {
    _ = fname;
    if (data != null) {
        _ = strcpy(@ptrCast(data.?), fpath);
    }
    set_reset_state_file(fpath);
    return MRET_LOADSTATE;
}

pub export fn save_programfile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) callconv(.c) c_int {
    _ = fname;
    if (data != null) {
        _ = strcpy(@ptrCast(data.?), fpath);
    }
    return MRET_SAVESTATE;
}

pub export fn load_programfile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) callconv(.c) c_int {
    _ = fname;
    if (data != null) {
        _ = strcpy(@ptrCast(data.?), fpath);
    }
    return MRET_LOADSTATE;
}

pub export fn show_warning(str: [*c]u8) callconv(.c) void {
    var ptr = strtok(str, "\n");
    while (ptr != null and ptr[0] != 0) {
        ptr = strtok(null, "\n");
    }
}

pub export fn fnDiskInfo(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    disp_disk_info("Disk Info");
    wait_for_key_press();
}
