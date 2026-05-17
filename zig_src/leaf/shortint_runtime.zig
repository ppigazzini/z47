const std = @import("std");

pub const calcRegister_t = i16;
pub const angularMode_t = c_int;
pub const VoidCallback = ?*const fn () callconv(.c) void;

pub const REGISTER_X: calcRegister_t = 100;
pub const REGISTER_Y: calcRegister_t = 101;
pub const REGISTER_Z: calcRegister_t = 102;
pub const REGISTER_L: calcRegister_t = 108;
pub const ERR_REGISTER_LINE: calcRegister_t = 102;

pub const dtLongInteger: u32 = 0;
pub const dtComplex34: u32 = 2;
pub const dtShortInteger: u32 = 8;
pub const SHORT_INTEGER_SIZE_IN_BLOCKS: u16 = 2;
pub const amNone: angularMode_t = 5;

pub const ERROR_INVALID_DATA_TYPE_FOR_OP: u8 = 24;
pub const ERROR_WORD_SIZE_TOO_SMALL: u8 = 14;
pub const TI_FALSE: u8 = 12;

pub const FLAG_CARRY: u32 = 0x800b;
pub const FLAG_ASLIFT: u32 = 0xc023;

const DECNUMUNITS = 25;
const DECSPECIAL: u8 = 0x70;

pub const real_t = extern struct {
    digits: i32,
    exponent: i32,
    bits: u8,
    lsu: [DECNUMUNITS]u16,
};

comptime {
    if (@sizeOf(real_t) != 60) {
        @compileError(std.fmt.comptimePrint("unexpected real_t size: {d}", .{@sizeOf(real_t)}));
    }
}

pub extern var shortIntegerWordSize: u8;
pub extern var shortIntegerMask: u64;
pub extern var shortIntegerSignBit: u64;
pub extern var thereIsSomethingToUndo: bool;
pub extern var temporaryInformation: u8;

pub extern fn getRegisterDataType(regist: calcRegister_t) u32;
pub extern fn getRegisterAsRawShortInt(reg: calcRegister_t, val: *u64, base: ?*u32) bool;
pub extern fn getRegisterAsComplex(reg: calcRegister_t, r: *real_t, i: *real_t) bool;
pub extern fn saveLastX() bool;
pub extern fn liftStack() void;
pub extern fn displayCalcErrorMessage(error_code: u8, err_message_register_line: calcRegister_t, err_register_line: calcRegister_t) void;
pub extern fn reallocateRegister(regist: calcRegister_t, data_type: u32, data_size_without_data_len_blocks: u16, tag: u32) void;
pub extern fn getRegisterDataPointer(regist: calcRegister_t) ?*anyopaque;
pub extern fn getRegisterTag(regist: calcRegister_t) u32;
pub extern fn setRegisterTag(regist: calcRegister_t, tag: u32) void;
pub extern fn getSystemFlag(sf: i32) bool;
pub extern fn setSystemFlag(sf: u32) void;
pub extern fn forceSystemFlag(sf: u32, set: c_int) void;
pub extern fn fnSetWordSize(ws: u16) void;
pub extern fn adjustResult(
    res: calcRegister_t,
    drop_y: bool,
    set_cpx_res: bool,
    op1: calcRegister_t,
    op2: calcRegister_t,
    op3: calcRegister_t,
) void;
pub extern fn processIntRealComplexMonadicFunction(
    realf: VoidCallback,
    complexf: VoidCallback,
    shortintf: VoidCallback,
    longintf: VoidCallback,
) void;
pub extern fn processIntRealComplexDyadicFunction(
    realf: VoidCallback,
    complexf: VoidCallback,
    shortintf: VoidCallback,
    longintf: VoidCallback,
) void;
pub extern fn convertRealToResultRegister(x: *const real_t, dest: calcRegister_t, angle: angularMode_t) void;
pub extern fn convertComplexToResultRegister(real: *const real_t, imag: *const real_t, dest: calcRegister_t) void;
pub extern fn convertUInt64ToShortIntegerRegister(sign: i16, value: u64, base: u32, regist: calcRegister_t) void;
pub extern fn convertShortIntegerRegisterToLongIntegerRegister(source: calcRegister_t, destination: calcRegister_t) void;

pub fn registerShortIntegerPtr(regist: calcRegister_t) *align(1) u64 {
    const ptr = getRegisterDataPointer(regist) orelse unreachable;
    return @ptrCast(ptr);
}

pub fn setRawShortIntegerRegister(regist: calcRegister_t, base: u32, value: u64) void {
    reallocateRegister(regist, dtShortInteger, SHORT_INTEGER_SIZE_IN_BLOCKS, base);
    registerShortIntegerPtr(regist).* = value;
}

pub fn getRegisterShortIntegerBase(regist: calcRegister_t) u32 {
    return getRegisterTag(regist);
}

pub fn setRegisterShortIntegerBase(regist: calcRegister_t, base: u32) void {
    setRegisterTag(regist, base);
}

pub fn zeroReal() real_t {
    return .{
        .digits = 1,
        .exponent = 0,
        .bits = 0,
        .lsu = [_]u16{0} ** DECNUMUNITS,
    };
}

pub fn realFromBoolean(value: bool) real_t {
    var result = zeroReal();
    result.lsu[0] = @intFromBool(value);
    return result;
}

pub fn isRealZero(value: *const real_t) bool {
    return value.digits == 1 and value.lsu[0] == 0 and (value.bits & DECSPECIAL) == 0;
}

pub fn setTemporaryInformation(condition: bool) void {
    temporaryInformation = TI_FALSE + @as(u8, @intFromBool(condition));
}

pub fn invalidShortIntegerError(regist: calcRegister_t) void {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, regist);
}

pub fn wordSizeError() void {
    displayCalcErrorMessage(ERROR_WORD_SIZE_TOO_SMALL, ERR_REGISTER_LINE, REGISTER_X);
}
