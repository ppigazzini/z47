const FLAG_QUIET: u16 = 0x8019;
const REGISTER_X: i16 = 100;
const REGISTER_Y: i16 = 101;
const REGISTER_Z: i16 = 102;
const DT_LONG_INTEGER: u32 = 0;
const DT_REAL34: u32 = 1;
const DEC_ROUND_DOWN: c_int = 5;
const ERROR_NONE: c_int = 0;
const ERROR_INVALID_DATA_TYPE_FOR_OP: u8 = 24;
const ERR_REGISTER_LINE: i16 = REGISTER_Z;

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

extern fn start_buzzer_freq(frequency: u32) void;
extern fn sys_delay(ms: u32) void;
extern fn stop_buzzer() void;
extern fn getSystemFlag(flag: u16) c_int;
extern fn getRegisterAsLongIntQuiet(reg: i16, val: [*c]GmpInt, fractional: [*c]c_int) c_int;
extern fn getRegisterDataType(regist: i16) u32;
extern fn getRegisterDataPointer(regist: i16) ?*anyopaque;
extern fn displayCalcErrorMessage(error_code: u8, err_message_register_line: i16, err_register_line: i16) void;
extern fn __gmpz_init(x: [*c]GmpInt) void;
extern fn __gmpz_clear(x: [*c]GmpInt) void;
extern fn __gmpz_get_ui(x: [*c]const GmpInt) c_ulong;
extern fn decQuadToUInt32(source: [*c]const DecQuad, context: *DecContext, round: c_int) u32;
extern var ctxtReal34: DecContext;

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

pub fn buzz(frequency: u32, ms_delay: u32) void {
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

pub fn fnBuzz(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    if (getSystemFlag(FLAG_QUIET) != 0) {
        return;
    }

    const frequency = registerToUInt32(REGISTER_Y) orelse return;
    const ms_delay = registerToUInt32(REGISTER_X) orelse return;
    buzz(frequency, ms_delay);
}
