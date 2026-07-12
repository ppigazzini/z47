// SPDX-License-Identifier: GPL-3.0-only
// Extern surface shared by the multiplication/division dispatch cell owners.
// Values below mirror src/c47/defines.h and src/c47/typeDefinitions.h exactly.

const abi = @import("abi");
const runtime = @import("command_wrappers_runtime.zig");

pub const calcRegister_t = runtime.calcRegister_t;
pub const real_t = runtime.real_t;
pub const real34_t = runtime.real34_t;
pub const realContext_t = runtime.realContext_t;
pub const mpz_struct = runtime.mpz_struct;
pub const real34Matrix_t = runtime.real34Matrix_t;
pub const complex34Matrix_t = runtime.complex34Matrix_t;
pub const VoidCallback = runtime.VoidCallback;

// 159-digit decNumber work area: REAL_SIZE_IN_BYTES(159) == 116 bytes
// (10 header bytes rounded into the struct layout + 53 declets of 2 bytes).
// 159-digit decNumber storage (REAL_T_PTR(name, 159), 116 bytes); layout
// centralized in abi (size asserted there).
pub const real159_t = abi.Real159;

pub fn asReal(big: *real159_t) *real_t {
    return @ptrCast(big);
}

pub fn asConstReal(big: *const real159_t) *const real_t {
    return @ptrCast(big);
}

// defines.h values (verified against src/c47/defines.h).
pub const FLAG_FRACT: i32 = 0x8007;
pub const FLAG_PROPFR: i32 = 0x8008;
pub const FLAG_CARRY: i32 = 0x800b;
pub const FLAG_OVERFLOW: i32 = 0x800c;
pub const FLAG_SPCRES: i32 = 0x8017;
pub const FLAG_ASLIFT: i32 = 0xc023;

pub const ERROR_NONE: u8 = 0;
pub const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN: u8 = 1;
pub const ERROR_OUT_OF_RANGE: u8 = 8;
pub const ERROR_MATRIX_MISMATCH: u8 = 21;
pub const ERROR_SINGULAR_MATRIX: u8 = 22;
pub const ERROR_INVALID_DATA_TYPE_FOR_OP: u8 = 24;

pub const NOPARAM: u16 = 9876;
pub const DISPLAY_VALUE_LEN = 80;

// fonts.h glyphs used inside upstream error strings.
pub const STD_CROSS = "\x80\xd7";
pub const STD_DIVIDE = "\x80\xf7";

// realType.h: real34IsPositive is a raw sign-bit test (also true for +NaN),
// unlike decQuadIsNegative which is false for NaN and -0.
pub fn real34IsPositive(value: *align(1) const real34_t) bool {
    return (value.bytes[15] & 0x80) == 0;
}

// error.c / items.c
pub extern fn doNothing() void;
pub extern fn displayBugScreen(msg: [*:0]const u8) void;

// debug.c
pub extern fn getDataTypeName(dt: u16, article: bool, pad_with_blanks: bool) [*:0]const u8;

// conversionAngles.c
pub extern fn getInfiniteComplexAngle(x: *real_t, y: *real_t) u32;
pub extern fn setInfiniteComplexAngle(angle: u32, x: *real_t, y: *real_t) void;

// registerValueConversions.c
pub extern fn convertShortIntegerRegisterToReal34Register(source: calcRegister_t, destination: calcRegister_t) void;
pub extern fn convertShortIntegerRegisterToLongIntegerRegister(source: calcRegister_t, destination: calcRegister_t) void;
pub extern fn convertLongIntegerToReal34(source: *const mpz_struct, destination: *align(1) real34_t) void;

// integers.c (range-checked long integer arithmetic helpers)
pub extern fn longIntegerMultiply(op_y: *const mpz_struct, op_x: *const mpz_struct, result: *mpz_struct) void;
pub extern fn longIntegerAdd(op_y: *const mpz_struct, op_x: *const mpz_struct, result: *mpz_struct) void;
pub extern fn longIntegerSubtract(op_y: *const mpz_struct, op_x: *const mpz_struct, result: *mpz_struct) void;

// GMP entry points for longIntegerType.h inline helpers.
pub extern fn __gmpz_tdiv_q(quotient: *mpz_struct, dividend: *const mpz_struct, divisor: *const mpz_struct) void;
pub extern fn __gmpz_mod(result: *mpz_struct, op1: *const mpz_struct, op2: *const mpz_struct) void;
pub extern fn __gmpz_setbit(op: *mpz_struct, bit: c_ulong) void;

// matrix.c
pub extern fn multiplyRealMatrix(matrix: *const real34Matrix_t, x: *align(1) const real34_t, res: *real34Matrix_t) void;
pub extern fn _multiplyRealMatrix(matrix: *const real34Matrix_t, x: *const real_t, res: *real34Matrix_t, real_context: *realContext_t) void;
pub extern fn multiplyRealMatrices(y: *const real34Matrix_t, x: *const real34Matrix_t, res: *real34Matrix_t) void;
pub extern fn multiplyComplexMatrix(matrix: *const complex34Matrix_t, xr: *align(1) const real34_t, xi: *align(1) const real34_t, res: *complex34Matrix_t) void;
pub extern fn _multiplyComplexMatrix(matrix: *const complex34Matrix_t, xr: *const real_t, xi: *const real_t, res: *complex34Matrix_t, real_context: *realContext_t) void;
pub extern fn multiplyComplexMatrices(y: *const complex34Matrix_t, x: *const complex34Matrix_t, res: *complex34Matrix_t) void;
pub extern fn divideRealMatrix(matrix: *const real34Matrix_t, x: *align(1) const real34_t, res: *real34Matrix_t) void;
pub extern fn _divideRealMatrix(matrix: *const real34Matrix_t, x: *const real_t, res: *real34Matrix_t, real_context: *realContext_t) void;
pub extern fn divideByRealMatrix(y: *align(1) const real34_t, matrix: *const real34Matrix_t, res: *real34Matrix_t) void;
pub extern fn _divideByRealMatrix(y: *const real_t, matrix: *const real34Matrix_t, res: *real34Matrix_t, real_context: *realContext_t) void;
pub extern fn divideRealMatrices(y: *const real34Matrix_t, x: *const real34Matrix_t, res: *real34Matrix_t) void;
pub extern fn divideComplexMatrix(matrix: *const complex34Matrix_t, xr: *align(1) const real34_t, xi: *align(1) const real34_t, res: *complex34Matrix_t) void;
pub extern fn _divideComplexMatrix(matrix: *const complex34Matrix_t, xr: *const real_t, xi: *const real_t, res: *complex34Matrix_t, real_context: *realContext_t) void;
pub extern fn divideByComplexMatrix(yr: *align(1) const real34_t, yi: *align(1) const real34_t, matrix: *const complex34Matrix_t, res: *complex34Matrix_t) void;
pub extern fn _divideByComplexMatrix(yr: *const real_t, yi: *const real_t, matrix: *const complex34Matrix_t, res: *complex34Matrix_t, real_context: *realContext_t) void;
pub extern fn divideComplexMatrices(y: *const complex34Matrix_t, x: *const complex34Matrix_t, res: *complex34Matrix_t) void;
pub extern fn elementwiseRema(f: VoidCallback) void;
pub extern fn elementwiseCxma(f: VoidCallback) void;
pub extern fn elementwiseRealRema(f: VoidCallback) void;
pub extern fn elementwiseCxmaReal(f: VoidCallback) void;
pub extern fn elementwiseRealCxma(f: VoidCallback) void;

// screen.c / display globals used by round.c
pub extern fn refreshRegisterLine(regist: calcRegister_t) void;
pub extern fn stringToInt32(str: [*:0]const u8) i32;
pub extern var updateDisplayValueX: bool;
pub extern var displayValueX: [DISPLAY_VALUE_LEN]u8;
pub extern var timeDisplayFormatDigits: u8;
pub extern var roundingMode: u8;
pub extern const roundingModeTable: [7]c_int;

// decNumber / decQuad library entry points behind upstream macros.
pub extern fn decNumberCopy(destination: *real_t, source: *const real_t) *real_t;
pub extern fn decQuadZero(result: *real34_t) *real34_t;
pub extern fn decQuadFromInt32(result: *real34_t, source: i32) *real34_t;
pub extern fn decQuadScaleB(result: *real34_t, source: *const real34_t, shift: *const real34_t, context: *realContext_t) *real34_t;
pub extern fn decQuadFromString(result: *align(1) real34_t, source: [*:0]const u8, context: *realContext_t) *align(1) real34_t;
