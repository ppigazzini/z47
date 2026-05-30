const audio_volume_owned = @import("firmware_hal_audio_volume_owned.zig");
const buzz_owned = @import("firmware_hal_buzz_owned.zig");
const play_owned = @import("firmware_hal_play_owned.zig");

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

const FLAG_QUIET: u16 = 0x8019;
const FLAG_PRTACT: u16 = 0xc020;

const REGISTER_X: i16 = 100;
const REGISTER_Y: i16 = 101;
const REGISTER_Z: i16 = 102;

const ERROR_NONE: c_int = 0;
const ERROR_MATRIX_MISMATCH: u8 = 21;
const ERROR_INVALID_DATA_TYPE_FOR_OP: u8 = 24;

const NIM_REGISTER_LINE: i16 = REGISTER_X;
const ERR_REGISTER_LINE: i16 = REGISTER_Z;

const SCRUPD_AUTO: u8 = 0x00;
const SCRUPD_SKIP_STATUSBAR_ONE_TIME: u8 = 0x10;

const DT_REAL34_MATRIX: u32 = 6;
const DT_LONG_INTEGER: u32 = 0;
const DT_REAL34: u32 = 1;
const DEC_ROUND_DOWN: c_int = 5;

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
extern fn convertUInt64ToShortIntegerRegister(sign: i16, value: u64, base: u32, regist: i16) void;
extern fn convertShortIntegerRegisterToLongIntegerRegister(source: i16, destination: i16) void;
extern fn getRegisterAsLongIntQuiet(reg: i16, val: [*c]GmpInt, fractional: [*c]c_int) c_int;
extern fn getRegisterDataType(regist: i16) u32;
extern fn getRegisterDataPointer(regist: i16) ?*anyopaque;
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
extern fn displayCalcErrorMessage(error_code: u8, err_message_register_line: i16, err_register_line: i16) void;
extern var screenUpdatingMode: u8;
extern fn key_empty() c_int;
extern fn key_pop() c_int;
extern fn key_pop_all() void;

extern fn strcpy(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strtok(str: [*c]u8, delim: [*c]const u8) [*c]u8;

const GmpInt = extern struct {
    mp_alloc: c_int,
    mp_size: c_int,
    mp_d: [*c]c_ulong,
};

const DecContext = opaque {};

const DecQuad = extern union {
    bytes: [16]u8,
    shorts: [8]u16,
    words: [4]u32,
};

const Real34Matrix = extern struct {
    header_raw: u32,
    matrixElements: [*c]DecQuad,
};

extern fn __gmpz_init(x: [*c]GmpInt) void;
extern fn __gmpz_clear(x: [*c]GmpInt) void;
extern fn __gmpz_get_ui(x: [*c]const GmpInt) c_ulong;
extern fn linkToRealMatrixRegister(regist: i16, linked_matrix: [*c]Real34Matrix) void;
extern fn decQuadToUInt32(source: [*c]const DecQuad, context: *DecContext, round: c_int) u32;
extern var ctxtReal34: DecContext;

pub export fn audioTone(frequency: u32) callconv(.c) void {
    audio_volume_owned.audioTone(frequency);
}

pub export fn dm42_squeak() callconv(.c) void {
    audio_volume_owned.dm42Squeak();
}

pub export fn fnSetVolume(volume: u16) callconv(.c) void {
    audio_volume_owned.fnSetVolume(volume);
}

pub export fn getBeepVolume() callconv(.c) u16 {
    return audio_volume_owned.getBeepVolume();
}

pub export fn fnGetVolume(unused_but_mandatory_parameter: u16) callconv(.c) void {
    audio_volume_owned.fnGetVolume(unused_but_mandatory_parameter);
}

pub export fn fnVolumeUp(unused_but_mandatory_parameter: u16) callconv(.c) void {
    audio_volume_owned.fnVolumeUp(unused_but_mandatory_parameter);
}

pub export fn fnVolumeDown(unused_but_mandatory_parameter: u16) callconv(.c) void {
    audio_volume_owned.fnVolumeDown(unused_but_mandatory_parameter);
}

pub export fn _Buzz(frequency: u32, ms_delay: u32) callconv(.c) void {
    buzz_owned.buzz(frequency, ms_delay);
}

pub export fn fnBuzz(unused_but_mandatory_parameter: u16) callconv(.c) void {
    buzz_owned.fnBuzz(unused_but_mandatory_parameter);
}

pub export fn fnPlay(regist: u16) callconv(.c) void {
    play_owned.fnPlay(regist);
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
        const selected: [*c]const u8 = @ptrCast((&filename)[@intCast(jj)..].ptr);
        stringCopy(fileNameSelected, selected);
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
    lcd_puts(t24, "Saving state ...");
    lcd_puts(t24, fname);
    lcd_refresh();

    if (data != null) {
        _ = strcpy(@ptrCast(data.?), fpath);
    }
    set_reset_state_file(fpath);
    return MRET_SAVESTATE;
}

pub export fn load_statefile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) callconv(.c) c_int {
    _ = fname;

    lcd_puts(t24, "");
    lcd_puts(t24, "WARNING: Current calculator state");
    lcd_puts(t24, "will be lost.");
    lcd_puts(t24, "");
    lcd_puts(t24, "");
    lcd_puts(t24, "Press [ENTER] to confirm.");
    lcd_refresh();

    wait_for_key_release(-1);

    while (true) {
        const key = runner_get_key(null);
        if (isExitKey(key)) {
            return 0;
        }
        if (is_menu_auto_off() != 0) {
            return MRET_EXIT;
        }
        if (key == KEY_ENTER) {
            break;
        }
    }

    lcd_putsRAt(t24, 6, "  Loading ...");
    lcd_refresh_wait();

    if (data != null) {
        _ = strcpy(@ptrCast(data.?), fpath);
    }
    set_reset_state_file(fpath);
    return MRET_LOADSTATE;
}

pub export fn save_programfile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) callconv(.c) c_int {
    lcd_puts(t24, "Saving program ...");
    lcd_puts(t24, fname);
    lcd_refresh();

    if (data != null) {
        _ = strcpy(@ptrCast(data.?), fpath);
    }
    return MRET_SAVESTATE;
}

pub export fn load_programfile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) callconv(.c) c_int {
    _ = fname;

    lcd_putsRAt(t24, 6, "  Loading ...");
    lcd_refresh_wait();

    if (data != null) {
        _ = strcpy(@ptrCast(data.?), fpath);
    }
    return MRET_LOADSTATE;
}

pub export fn show_warning(str: [*c]u8) callconv(.c) void {
    const delim = "\n";
    var ptr = strtok(str, "\n");

    lcd_clear_buf();
    lcd_putsRAt(t24, 0, "                   WARNING");
    lcd_setLine(t24, 1);

    while (ptr != null) {
        lcd_puts(t24, ptr);
        ptr = strtok(null, delim);
    }

    lcd_putsRAt(t24, 8, "Press [ENTER] to continue.");
    lcd_refresh();
    wait_for_key_release(-1);

    while (true) {
        const key = runner_get_key(null);
        if (key == KEY_ENTER or isExitKey(key) or is_menu_auto_off() != 0) {
            break;
        }
    }
}

pub export fn fnDiskInfo(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    disp_disk_info("Disk Info");
    wait_for_key_press();
}
