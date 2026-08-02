const std = @import("std");
const build_options = @import("firmware_audio_build_options");

const KEY_EXIT: c_int = 33;

const FLAG_QUIET: u16 = 0x8019;

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

const DT_LONG_INTEGER: u32 = 0;
const DT_REAL34: u32 = 1;
const DT_REAL34_MATRIX: u32 = 6;
const DEC_ROUND_DOWN: c_int = 5;

const start_buzzer_freq_offset: usize = 244;
const stop_buzzer_offset: usize = 248;
const beep_volume_up_offset: usize = 252;
const beep_volume_down_offset: usize = 256;
const get_beep_volume_offset: usize = 260;
const key_empty_offset: usize = 380;
const key_pop_offset: usize = 392;
const key_pop_all_offset: usize = 400;
const sys_delay_offset: usize = 516;

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

extern fn getSystemFlag(flag: u16) c_int;
extern fn liftStack() void;
extern fn convertUInt64ToShortIntegerRegister(sign: i16, value: u64, base: u32, regist: i16) void;
extern fn convertShortIntegerRegisterToLongIntegerRegister(source: i16, destination: i16) void;
extern fn getRegisterAsLongIntQuiet(reg: i16, val: [*c]GmpInt, fractional: [*c]c_int) c_int;
extern fn getRegisterDataType(regist: i16) u32;
extern fn getRegisterDataPointer(regist: i16) ?*anyopaque;
extern fn displayCalcErrorMessage(error_code: u8, err_message_register_line: i16, err_register_line: i16) void;
extern var screenUpdatingMode: u8;
extern fn __gmpz_init(x: [*c]GmpInt) void;
extern fn __gmpz_clear(x: [*c]GmpInt) void;
extern fn __gmpz_get_ui(x: [*c]const GmpInt) c_ulong;
extern fn linkToRealMatrixRegister(regist: i16, linked_matrix: [*c]Real34Matrix) void;
extern fn decQuadToUInt32(source: [*c]const DecQuad, context: *DecContext, round: c_int) u32;
extern var ctxtReal34: DecContext;

const StartBuzzerFn = *const fn (u32) callconv(.c) void;
const StopBuzzerFn = *const fn () callconv(.c) void;
const VolumeUpFn = *const fn () callconv(.c) void;
const VolumeDownFn = *const fn () callconv(.c) void;
const GetVolumeFn = *const fn () callconv(.c) u16;
const KeyEmptyFn = *const fn () callconv(.c) c_int;
const KeyPopFn = *const fn () callconv(.c) c_int;
const KeyPopAllFn = *const fn () callconv(.c) void;
const SysDelayFn = *const fn (u32) callconv(.c) void;

fn startBuzzerFrequency(frequency: u32) void {
    const function: StartBuzzerFn = @ptrFromInt(build_options.library_fn_base + start_buzzer_freq_offset);
    function(frequency);
}

fn stopBuzzer() void {
    const function: StopBuzzerFn = @ptrFromInt(build_options.library_fn_base + stop_buzzer_offset);
    function();
}

fn volumeUp() void {
    const function: VolumeUpFn = @ptrFromInt(build_options.library_fn_base + beep_volume_up_offset);
    function();
}

fn volumeDown() void {
    const function: VolumeDownFn = @ptrFromInt(build_options.library_fn_base + beep_volume_down_offset);
    function();
}

fn getBeepVolumeRaw() u16 {
    const function: GetVolumeFn = @ptrFromInt(build_options.library_fn_base + get_beep_volume_offset);
    return function();
}

fn keyQueueEmpty() c_int {
    const function: KeyEmptyFn = @ptrFromInt(build_options.library_fn_base + key_empty_offset);
    return function();
}

fn popKey() c_int {
    const function: KeyPopFn = @ptrFromInt(build_options.library_fn_base + key_pop_offset);
    return function();
}

fn clearKeyQueue() void {
    const function: KeyPopAllFn = @ptrFromInt(build_options.library_fn_base + key_pop_all_offset);
    function();
}

fn delayMilliseconds(ms: u32) void {
    const function: SysDelayFn = @ptrFromInt(build_options.library_fn_base + sys_delay_offset);
    function(ms);
}

fn matrixRows(header_raw: u32) u16 {
    return @truncate(header_raw & 0x0fff);
}

fn matrixCols(header_raw: u32) u16 {
    return @truncate((header_raw >> 12) & 0x0fff);
}

fn real34ToUInt32(value: [*c]const DecQuad) u32 {
    return decQuadToUInt32(value, &ctxtReal34, DEC_ROUND_DOWN);
}

fn registerToUInt32(reg: i16) ?u32 {
    const data_type = getRegisterDataType(reg);
    if (data_type == DT_REAL34) {
        const raw_ptr = getRegisterDataPointer(reg) orelse return null;
        const real_ptr: [*c]const DecQuad = @ptrCast(@alignCast(raw_ptr));
        return real34ToUInt32(real_ptr);
    }

    if (data_type != DT_LONG_INTEGER) {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        return null;
    }

    var li: [1]GmpInt = undefined;
    __gmpz_init(&li[0]);
    defer __gmpz_clear(&li[0]);

    var fractional: c_int = 0;
    if (getRegisterAsLongIntQuiet(reg, &li[0], &fractional) != ERROR_NONE) {
        return null;
    }

    return @truncate(@as(u64, @intCast(__gmpz_get_ui(&li[0]))));
}

pub export fn audioTone(frequency: u32) callconv(.c) void {
    startBuzzerFrequency(frequency);
    delayMilliseconds(250);
    stopBuzzer();
}

pub export fn dm42_squeak() callconv(.c) void {
    if (getSystemFlag(FLAG_QUIET) == 0) {
        startBuzzerFrequency(1835000);
        delayMilliseconds(125);
        stopBuzzer();
    }
}

pub export fn fnSetVolume(volume: u16) callconv(.c) void {
    var current = getBeepVolumeRaw();
    while (current < volume) : (current += 1) {
        volumeUp();
    }
    while (current > volume) : (current -= 1) {
        volumeDown();
    }
}

pub export fn getBeepVolume() callconv(.c) u16 {
    return getBeepVolumeRaw();
}

pub export fn fnGetVolume(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    liftStack();
    convertUInt64ToShortIntegerRegister(0, @as(u64, getBeepVolumeRaw()), 10, REGISTER_X);
    convertShortIntegerRegisterToLongIntegerRegister(REGISTER_X, REGISTER_X);
}

pub export fn fnVolumeUp(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    volumeUp();
    audioTone(440000);
}

pub export fn fnVolumeDown(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    volumeDown();
    audioTone(440000);
}

pub export fn _Buzz(frequency: u32, ms_delay: u32) callconv(.c) void {
    if (ms_delay == 0) return;

    var safe_delay = ms_delay;
    if (safe_delay > 2000) safe_delay = 2000;

    if (frequency != 0) {
        var safe_frequency = frequency;
        if (safe_frequency > 20000) safe_frequency = 20000;
        startBuzzerFrequency(safe_frequency * 1000);
        delayMilliseconds(safe_delay);
        stopBuzzer();
    } else {
        delayMilliseconds(safe_delay);
    }
}

pub export fn fnBuzz(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    if (getSystemFlag(FLAG_QUIET) != 0) {
        return;
    }

    const frequency = registerToUInt32(REGISTER_Y) orelse return;
    const ms_delay = registerToUInt32(REGISTER_X) orelse return;
    _Buzz(frequency, ms_delay);
}

pub export fn fnPlay(regist: u16) callconv(.c) void {
    const reg: i16 = @intCast(regist);

    if (getRegisterDataType(reg) != DT_REAL34_MATRIX) {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
        return;
    }

    if (getSystemFlag(FLAG_QUIET) != 0) {
        return;
    }

    var matrix: Real34Matrix = undefined;
    linkToRealMatrixRegister(reg, &matrix);

    const cols = matrixCols(matrix.header_raw);
    if (cols != 2 and cols != 3) {
        displayCalcErrorMessage(ERROR_MATRIX_MISMATCH, ERR_REGISTER_LINE, REGISTER_X);
        return;
    }

    screenUpdatingMode = SCRUPD_AUTO;
    screenUpdatingMode |= SCRUPD_SKIP_STATUSBAR_ONE_TIME;

    const rows = matrixRows(matrix.header_raw);
    var i: u16 = 0;
    while (i < rows) : (i += 1) {
        const base: usize = @as(usize, i) * cols;
        const frequency = real34ToUInt32(&matrix.matrixElements[base]);
        const ms_delay = real34ToUInt32(&matrix.matrixElements[base + 1]);

        if (cols == 3) {
            const volume: u16 = @truncate(real34ToUInt32(&matrix.matrixElements[base + 2]));
            fnSetVolume(volume);
        }

        _Buzz(frequency, ms_delay);
        if (ms_delay > 0) {
            delayMilliseconds(@divTrunc(ms_delay, 8));
        }

        while (keyQueueEmpty() == 0) {
            if (popKey() == KEY_EXIT) {
                clearKeyQueue();
                return;
            }
        }
    }
}
