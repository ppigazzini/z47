const std = @import("std");
const register_storage_owned = @import("runtime_register_storage.zig");
const real_owned = @import("runtime_real.zig");
const error_info_owned = @import("runtime_error_info.zig");

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

const abi = @import("abi"); // shared ABI bindings
pub const real_t = abi.Real;

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

// EXTRA_INFO_ON_CALC_ERROR (defines.h), as far as this object can resolve it.
// The three short-integer command objects are compiled once and linked into
// both the simulator and the testSuite, so the TESTSUITE_BUILD half of the
// macro is not a compile-time fact here. It does not have to be: the
// moreInfoOnError symbol is a no-op stub on every build that compiles the hints
// out, so this gate only keeps the message formatting off the firmware.
pub const extra_info_on_calc_error = @import("builtin").target.os.tag != .freestanding;

pub extern fn getRegisterDataType(regist: calcRegister_t) u32;
pub extern fn getRegisterDataTypeName(regist: calcRegister_t, article: bool, abbreviated: bool) [*:0]const u8;
pub extern fn moreInfoOnError(m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) void;
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

/// longInteger_t is `mpz_t`, a one-element array, so it decays to a pointer at
/// every call site.
pub const longInteger_t = [1]abi.Mpz;
// longIntegerInit / longIntegerFree / uInt32ToLongInteger are static inline
// wrappers over GMP in longIntegerType.h, so the link names are GMP's own.
extern fn __gmpz_init(op: *abi.Mpz) void;
extern fn __gmpz_clear(op: *abi.Mpz) void;
extern fn __gmpz_set_ui(op: *abi.Mpz, value: c_ulong) void;
pub extern fn convertLongIntegerToLongIntegerRegister(op: *const abi.Mpz, destination: calcRegister_t) void;

pub inline fn longIntegerInit(op: *abi.Mpz) void {
    __gmpz_init(op);
}
pub inline fn longIntegerFree(op: *abi.Mpz) void {
    __gmpz_clear(op);
}
pub inline fn uInt32ToLongInteger(value: u32, op: *abi.Mpz) void {
    __gmpz_set_ui(op, value);
}

pub fn registerShortIntegerPtr(regist: calcRegister_t) *align(1) u64 {
    return register_storage_owned.registerShortIntegerPtr(getRegisterDataPointer, regist);
}

pub fn setRawShortIntegerRegister(regist: calcRegister_t, base: u32, value: u64) void {
    register_storage_owned.setRawShortIntegerRegister(
        reallocateRegister,
        getRegisterDataPointer,
        dtShortInteger,
        SHORT_INTEGER_SIZE_IN_BLOCKS,
        regist,
        base,
        value,
    );
}

pub fn getRegisterShortIntegerBase(regist: calcRegister_t) u32 {
    return getRegisterTag(regist);
}

pub fn setRegisterShortIntegerBase(regist: calcRegister_t, base: u32) void {
    setRegisterTag(regist, base);
}

pub fn zeroReal() real_t {
    return real_owned.zeroReal(real_t, DECNUMUNITS);
}

pub fn realFromBoolean(value: bool) real_t {
    return real_owned.realFromBoolean(real_t, DECNUMUNITS, value);
}

pub fn isRealZero(value: *const real_t) bool {
    return real_owned.isRealZero(value, DECSPECIAL);
}

pub fn setTemporaryInformation(condition: bool) void {
    error_info_owned.setTemporaryInformation(&temporaryInformation, TI_FALSE, condition);
}

// ERROR_MESSAGE_LENGTH is 512 (defines.h); upstream formats these hints into
// the shared errorMessage buffer of that size.
const ERROR_MESSAGE_LENGTH = 512;

pub fn invalidShortIntegerError(function_name: [*:0]const u8, regist: calcRegister_t) void {
    error_info_owned.invalidShortIntegerError(
        displayCalcErrorMessage,
        ERROR_INVALID_DATA_TYPE_FOR_OP,
        ERR_REGISTER_LINE,
        regist,
    );
    if (extra_info_on_calc_error) {
        var message: [ERROR_MESSAGE_LENGTH]u8 = undefined;
        const type_name = std.mem.span(getRegisterDataTypeName(regist, true, false));
        moreInfoOnError(function_name, bufPrintZ(&message, "cannot shift/rotate {s}", .{type_name}), null, null);
    }
}

pub fn wordSizeError(function_name: [*:0]const u8, operation_name: []const u8, requested_bits: u16) void {
    error_info_owned.wordSizeError(
        displayCalcErrorMessage,
        ERROR_WORD_SIZE_TOO_SMALL,
        ERR_REGISTER_LINE,
        REGISTER_X,
    );
    if (extra_info_on_calc_error) {
        var message: [ERROR_MESSAGE_LENGTH]u8 = undefined;
        moreInfoOnError(
            function_name,
            bufPrintZ(&message, "cannot calculate {s}({d}) word size is {d}", .{ operation_name, requested_bits, shortIntegerWordSize }),
            null,
            null,
        );
    }
}

// std.fmt.bufPrintZ was removed in Zig 0.17; std.fmt.bufPrint plus an explicit
// sentinel works on both 0.16 and master. Every format below is bounded far
// under ERROR_MESSAGE_LENGTH, so the truncating fallback is the empty string
// rather than a second message the C never prints.
fn bufPrintZ(buffer: []u8, comptime format: []const u8, args: anytype) [*:0]const u8 {
    const text = std.fmt.bufPrint(buffer[0 .. buffer.len - 1], format, args) catch buffer[0..0];
    buffer[text.len] = 0;
    return @ptrCast(buffer.ptr);
}
