// SPDX-License-Identifier: GPL-3.0-only
const cstR = consts.cstR;
const consts = abi.constants;
const const_2p32 = consts.const_2p32;
const const34_86400 = consts.const34_86400;
const const34_43200 = consts.const34_43200;
const const34_2p32 = consts.const34_2p32;
const const6147_2pi = consts.const6147_2pi;
const const_2p64 = consts.const_2p64;
const const_0 = consts.const_0;
const const34_100 = consts.const34_100;
const const34_1e_4 = consts.const34_1e_4;
const const_2p63 = consts.const_2p63;
const const34_3600 = consts.const34_3600;
const const34_1e6 = consts.const34_1e6;
//
// Zig owner for src/c47/registerValueConversions.c: the central register-datatype
// conversion layer. It bridges GMP long integers, real/real34, short integers,
// matrices, date/time and complex register payloads, hosts the getRegisterAs*
// family and the monadic/dyadic real/complex dispatchers. It is exercised by the
// entire testSuite, so correctness is verified by `zig build test`.
//
// This is a faithful, line-by-line port of the C. Numeric constants come from the
// shared `constants` blob by byte offset; cst34()/cstR() return align(1) pointers
// (the macOS host build has a byte-aligned blob base, so an align-4 deref would
// trap). real34 ops go through decQuad/decimal128 externs; long integers go
// straight to mpz_*; the firmware RTC path uses the fixed-address SDK call.

const builtin = @import("builtin");
const std = @import("std");
const frontier_build_options = @import("frontier_build_options");
const extra_info: bool = frontier_build_options.extra_info_on_calc_error;
const dmcp_build: bool = frontier_build_options.dmcp_build;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const DECNUMUNITS = 25;
const abi = @import("abi"); // L1 shared bindings (REPORT-23 §5)
const frontier_char_string = @import("frontier_char_string.zig"); // M-callconv: Zig-to-Zig
const frontier_date_time = @import("frontier_date_time.zig"); // M-callconv: Zig-to-Zig
const frontier_debug = @import("frontier_debug.zig"); // M-callconv: Zig-to-Zig
const frontier_display = @import("frontier_display.zig"); // M-callconv: Zig-to-Zig
const frontier_error = @import("frontier_error.zig"); // M-callconv: Zig-to-Zig
const frontier_integers = @import("frontier_integers.zig"); // M-callconv: Zig-to-Zig
const frontier_real_type = @import("frontier_real_type.zig"); // M-callconv: Zig-to-Zig
const real_t = abi.Real;
const real34_t = abi.Real34;
const realContext_t = abi.RealContext;
const complex34_t = abi.Complex34;
const matrixHeader_t = abi.MatrixHeader;
const real34Matrix_t = abi.Real34Matrix;
const complex34Matrix_t = abi.Complex34Matrix;

const calcRegister_t = i16;
const angularMode_t = c_int;

// GMP mpz_struct. The limb width == pointer width on every target z47 builds
// (64-bit on Linux and Win64, 32-bit on ARM32 firmware). NOT c_ulong: Win64 is
// LLP64, where `unsigned long` is 32-bit yet GMP limbs are 64-bit — that mismatch
// mis-sized _mp_d and broke the @ptrCast to [*]u64 below on the Windows CI lane.
const mp_limb_t = usize;
const mpz_struct = abi.Mpz;
const LIMB_SIZE: u32 = @sizeOf(mp_limb_t);
const is32: bool = @sizeOf(*anyopaque) == 4;

// ---------------------------------------------------------------------------
// Constants / enum values
// ---------------------------------------------------------------------------
const dtLongInteger: u32 = 0;
const dtReal34: u32 = 1;
const dtComplex34: u32 = 2;
const dtTime: u32 = 3;
const dtDate: u32 = 4;
const dtReal34Matrix: u32 = 6;
const dtComplex34Matrix: u32 = 7;
const dtShortInteger: u32 = 8;

const SIM_UNSIGN: u8 = 0;
const SIM_1COMPL: u8 = 1;
const SIM_2COMPL: u8 = 2;
const SIM_SIGNMT: u8 = 3;

const LI_ZERO: u32 = 0;
const LI_NEGATIVE: u32 = 1;
const LI_POSITIVE: u32 = 2;

const amRadian: angularMode_t = 0;
const amGrad: angularMode_t = 1;
const amDegree: angularMode_t = 2;
const amDMS: angularMode_t = 3;
const amMultPi: angularMode_t = 4;
const amNone: angularMode_t = 5;
const amAngleMask: u32 = 15;
const amPolar: u32 = 16;

const FLAG_OVERFLOW: c_int = 0x800c;
const FLAG_YMD: c_int = 0xc001;
const FLAG_MDY: c_int = 0xc003;
const FLAG_DMY: c_int = 0xc002;
const FLAG_ASLIFT: c_uint = 0xc023;
const FLAG_POLAR: c_int = 0x8006;

const ERROR_NONE: u8 = 0;
const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN: u8 = 1;
const ERROR_BAD_TIME_OR_DATE_INPUT: u8 = 2;
const ERROR_OUT_OF_RANGE: u8 = 8;
const ERROR_RAM_FULL: u8 = 11;
const ERROR_INVALID_DATA_TYPE_FOR_OP: u8 = 24;

const REGISTER_X: calcRegister_t = 100;
const REGISTER_Y: calcRegister_t = 101;
const REGISTER_Z: calcRegister_t = 102;
const REGISTER_T: calcRegister_t = 103;
const ERR_REGISTER_LINE: calcRegister_t = REGISTER_Z;
const NIM_REGISTER_LINE: calcRegister_t = REGISTER_X;

const YY_MASK_TRACKING: u16 = 0x4000;
const YY_MASK_OFF: u16 = 0x8000;

const DEC_ROUND_DOWN: c_int = 5;

const ITM_CHS: i16 = 97;

const REAL34_SIZE_IN_BLOCKS: u16 = 4;
const REAL34_SIZE_IN_BYTES: u32 = 16;
const COMPLEX34_SIZE_IN_BLOCKS: u16 = 8;
const COMPLEX34_SIZE_IN_BYTES: u32 = 32;
const SHORT_INTEGER_SIZE_IN_BLOCKS: u16 = 2;
const DECQUAD_Pmax: usize = 34;
const DECDPUN: i32 = 3;
const TMP_STR_LENGTH: i32 = 2560;
const DOUBLE_NOT_INIT: f64 = 3.402823466e+38;

// decNumber bits.
const DECNEG: u8 = 0x80;
const DECINF: u8 = 0x40;
const DECNAN: u8 = 0x20;
const DECSNAN: u8 = 0x10;
const DECSPECIAL: u8 = DECINF | DECNAN | DECSNAN; // 0x70

// ---------------------------------------------------------------------------
// Constant blob
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Globals
// ---------------------------------------------------------------------------
extern var tmpString: [*c]u8;
extern var errorMessage: [*c]u8;
extern var shortIntegerMode: u8;
extern var shortIntegerMask: u64;
extern var shortIntegerSignBit: u64;
extern var lastCenturyHighUsed: u16;
extern var significantDigits: u8;
extern var currentAngularMode: angularMode_t;
extern var lastErrorCode: u8;
extern var lastFunc: i16;
extern var lastIntegerBase: u32;
extern var ctxtReal34: realContext_t;
extern var ctxtReal39: realContext_t;
extern var ctxtReal75: realContext_t;

// ---------------------------------------------------------------------------
// Linkable function externs
// ---------------------------------------------------------------------------
extern fn reallocateRegister(regist: calcRegister_t, data_type: u32, size_blocks: u16, tag: u32) void;
extern fn getRegisterDataType(regist: calcRegister_t) u32;
extern fn getRegisterDataPointer(regist: calcRegister_t) *anyopaque;
extern fn getRegisterTag(regist: calcRegister_t) u32;
extern fn setRegisterTag(regist: calcRegister_t, tag: u32) void;
extern fn getRegisterMaxDataLengthInBlocks(regist: calcRegister_t) u16;
extern fn adjustResult(result: calcRegister_t, drop_y: bool, set_cpx: bool, op1: calcRegister_t, op2: calcRegister_t, op3: calcRegister_t) void;
extern fn saveLastX() bool;
extern fn liftStack() void;

const c_moreInfoOnError = @extern(*const fn (m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) callconv(.c) void, .{ .name = "moreInfoOnError" });

extern fn realMatrixInit(matrix: *real34Matrix_t, rows: u16, cols: u16) bool;
extern fn complexMatrixInit(matrix: *complex34Matrix_t, rows: u16, cols: u16) bool;
extern fn complexMatrixFree(matrix: *complex34Matrix_t) void;
extern fn linkToRealMatrixRegister(regist: calcRegister_t, linked: *real34Matrix_t) void;

extern fn roundToSignificantDigits(source: *const real_t, destination: *real_t, digits: u16, real_context: *realContext_t) void;
extern fn WP34S_Mod(x: *const real_t, y: *align(1) const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn getSystemFlag(flag: c_int) bool;
extern fn setSystemFlag(flag: c_uint) void;
extern fn clearSystemFlag(flag: c_uint) void;

// real linkable helpers.

extern fn realIsAnInteger(x: *const real_t) bool;
extern fn realCompareGreaterEqual(a: *align(1) const real_t, b: *align(1) const real_t) bool;
extern fn realCompareGreaterThan(a: *align(1) const real_t, b: *align(1) const real_t) bool;
extern fn real34CompareGreaterEqual(a: *align(1) const real34_t, b: *align(1) const real34_t) bool;
extern fn real34CompareLessThan(a: *align(1) const real34_t, b: *align(1) const real34_t) bool;
inline fn real34SetZero(dst: *real34_t) void {
    _ = decQuadZero(dst);
}

// elementwise matrix dispatchers.
const Fn0 = ?*const fn () callconv(.c) void;
extern fn elementwiseRema(f: Fn0) void;
extern fn elementwiseCxma(f: Fn0) void;
extern fn elementwiseRemaRema(f: Fn0) void;
extern fn elementwiseCxmaRema(f: Fn0) void;
extern fn elementwiseCplxRema(f: Fn0) void;
extern fn elementwiseRealRema(f: Fn0) void;
extern fn elementwiseRemaCxma(f: Fn0) void;
extern fn elementwiseCxmaCxma(f: Fn0) void;
extern fn elementwiseCplxCxma(f: Fn0) void;
extern fn elementwiseRemaReal(f: Fn0) void;
extern fn elementwiseRemaCplx(f: Fn0) void;
extern fn elementwiseCxmaCplx(f: Fn0) void;

// ---------------------------------------------------------------------------
// decNumber / decQuad externs
// ---------------------------------------------------------------------------
extern fn decQuadFromInt32(r: *real34_t, v: i32) *real34_t;
extern fn decQuadFromUInt32(r: *real34_t, v: u32) *real34_t;
extern fn decQuadFromString(r: *real34_t, s: [*c]const u8, ctx: *realContext_t) *real34_t;
extern fn decQuadGetCoefficient(r: *align(1) const real34_t, bcd: [*]u8) i32;
extern fn decQuadGetExponent(r: *align(1) const real34_t) i32;
extern fn decQuadToInt32(r: *align(1) const real34_t, ctx: *realContext_t, round: c_int) i32;
extern fn decQuadZero(r: *real34_t) *real34_t;
extern fn decQuadAdd(r: *real34_t, a: *align(1) const real34_t, b: *align(1) const real34_t, ctx: *realContext_t) *real34_t;
extern fn decQuadDivide(r: *real34_t, a: *align(1) const real34_t, b: *align(1) const real34_t, ctx: *realContext_t) *real34_t;
extern fn decQuadMultiply(r: *real34_t, a: *align(1) const real34_t, b: *align(1) const real34_t, ctx: *realContext_t) *real34_t;
extern fn decQuadSubtract(r: *real34_t, a: *align(1) const real34_t, b: *align(1) const real34_t, ctx: *realContext_t) *real34_t;
extern fn decQuadFMA(r: *real34_t, a: *align(1) const real34_t, b: *align(1) const real34_t, c: *align(1) const real34_t, ctx: *realContext_t) *real34_t;
extern fn decQuadToIntegralValue(r: *real34_t, a: *align(1) const real34_t, ctx: *realContext_t, round: c_int) *real34_t;
extern fn decQuadCopyAbs(r: *real34_t, a: *align(1) const real34_t) *real34_t;

extern fn decimal128ToNumber(src: *align(1) const real34_t, dst: *real_t) *real_t;
extern fn decimal128FromNumber(dst: *real34_t, src: *const real_t, ctx: *realContext_t) *real34_t;

extern fn decNumberFromUInt32(r: *real_t, v: u32) *real_t;
extern fn decNumberFromString(r: *real_t, s: [*c]const u8, ctx: *realContext_t) *real_t;
extern fn decNumberToString(r: *const real_t, s: [*]u8) [*c]u8;
extern fn decNumberToUInt64(r: *const real_t, ctx: *realContext_t) u64;
extern fn decNumberGetBCD(r: *const real_t, bcd: [*]u8) [*c]u8;
extern fn decNumberFMA(r: *real_t, a: *align(1) const real_t, b: *align(1) const real_t, c: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberPlus(r: *real_t, a: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberQuantize(r: *real_t, a: *align(1) const real_t, b: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberToIntegralValue(r: *real_t, a: *const real_t, ctx: *realContext_t) *real_t;

// ---------------------------------------------------------------------------
// GMP externs
// ---------------------------------------------------------------------------
// GMP exports its symbols with the __gmpz_ prefix (mpz_* are header macros).
extern fn __gmpz_init(p: *mpz_struct) void;
extern fn __gmpz_init2(p: *mpz_struct, bits: c_ulong) void;
extern fn __gmpz_clear(p: *mpz_struct) void;
extern fn __gmpz_set_ui(p: *mpz_struct, v: c_ulong) void;
extern fn __gmpz_add_ui(r: *mpz_struct, op: *const mpz_struct, c: c_ulong) void;
extern fn __gmpz_mul_ui(r: *mpz_struct, op: *const mpz_struct, c: c_ulong) void;
extern fn __gmpz_mul_2exp(r: *mpz_struct, op: *const mpz_struct, c: c_ulong) void;
extern fn __gmpz_fdiv_ui(op: *const mpz_struct, c: c_ulong) c_ulong;
extern fn __gmpz_get_str(str: [*c]u8, radix: c_int, op: *const mpz_struct) [*c]u8;
extern fn __gmpz_sizeinbase(op: *const mpz_struct, base: c_int) usize;
const mpz_init = __gmpz_init;
const mpz_init2 = __gmpz_init2;
const mpz_clear = __gmpz_clear;
const mpz_set_ui = __gmpz_set_ui;
const mpz_add_ui = __gmpz_add_ui;
const mpz_mul_ui = __gmpz_mul_ui;
const mpz_mul_2exp = __gmpz_mul_2exp;
const mpz_fdiv_ui = __gmpz_fdiv_ui;
const mpz_get_str = __gmpz_get_str;
const mpz_sizeinbase = __gmpz_sizeinbase;

// ---------------------------------------------------------------------------
// DMCP / PC date path
// ---------------------------------------------------------------------------
const dt_t = abi.DateShort;
const tm_t = abi.TimeShort;
const Tm = abi.Tm;
extern fn time(t: ?*i64) i64;
extern fn localtime(t: *const i64) *Tm;

// ---------------------------------------------------------------------------
// Inline wrappers (the C macros)
// ---------------------------------------------------------------------------
inline fn moreInfoOnError(m1: [*:0]const u8, m2: ?[*:0]const u8) void {
    if (comptime extra_info) c_moreInfoOnError(m1, m2, null, null);
}
inline fn dataPtr(reg: calcRegister_t) [*]u8 {
    return abi.registerBytes(reg);
}
const reg34 = abi.registerReal34;
inline fn regImag34(reg: calcRegister_t) *align(1) real34_t {
    return @ptrCast(dataPtr(reg) + REAL34_SIZE_IN_BYTES);
}
inline fn regLongIntData(reg: calcRegister_t) [*]u8 {
    return dataPtr(reg) + 4; // sizeof(strLgIntHeader_t)
}
const regShortInt = abi.registerShortInteger;
const regMatrixHeader = abi.registerMatrixHeader;
inline fn regRealMatrixElems(reg: calcRegister_t) [*]align(1) real34_t {
    return @ptrCast(dataPtr(reg) + 4);
}
inline fn regComplexMatrixElems(reg: calcRegister_t) [*]align(1) complex34_t {
    return @ptrCast(dataPtr(reg) + 4);
}
inline fn getRegisterAngularMode(reg: calcRegister_t) angularMode_t {
    return @intCast(getRegisterTag(reg) & amAngleMask);
}
inline fn getRegisterShortIntegerBase(reg: calcRegister_t) u32 {
    return getRegisterTag(reg);
}
inline fn getRegisterLongIntegerSign(reg: calcRegister_t) u32 {
    return getRegisterTag(reg);
}
inline fn setComplexRegisterAngularMode(reg: calcRegister_t, am: angularMode_t) void {
    const amu: u32 = @bitCast(am);
    setRegisterTag(reg, (amu & amAngleMask) | (getRegisterTag(reg) & amPolar));
}
inline fn setComplexRegisterPolarMode(reg: calcRegister_t, pm: u32) void {
    const base = if ((pm & amPolar) != 0) (getRegisterTag(reg) & amAngleMask) else amNoneU;
    setRegisterTag(reg, base | (pm & amPolar));
}
const amNoneU: u32 = @bitCast(amNone);

// TO_BLOCKS / TO_BYTES
inline fn toBlocks(n: u32) u16 {
    return @intCast((n + 3) >> 2);
}
inline fn toBytes(n: u16) u32 {
    return @as(u32, n) << 2;
}

// long integer helpers.
inline fn longIntegerSizeInBytes(lg: *const mpz_struct) u16 {
    return @intCast(absI(lg._mp_size) * @as(u32, LIMB_SIZE));
}
inline fn longIntegerSignTag(lg: *const mpz_struct) u32 {
    if (lg._mp_size == 0) return LI_ZERO;
    return if (lg._mp_size > 0) LI_POSITIVE else LI_NEGATIVE;
}
inline fn longIntegerIsNegative(lg: *const mpz_struct) bool {
    return lg._mp_size < 0;
}
inline fn longIntegerIsZero(lg: *const mpz_struct) bool {
    return lg._mp_size == 0;
}
inline fn longIntegerChangeSign(lg: *mpz_struct) void {
    lg._mp_size = -lg._mp_size;
}
inline fn absI(x: c_int) u32 {
    return if (x < 0) @intCast(-x) else @intCast(x);
}

// real34 bit macros.
inline fn real34IsNegative(v: *align(1) const real34_t) bool {
    return (v.bytes[15] & 0x80) == 0x80;
}
inline fn real34SetNegativeSign(v: *real34_t) void {
    v.bytes[15] |= 0x80;
}
inline fn real34SetPositiveSign(v: *real34_t) void {
    v.bytes[15] &= 0x7f;
}
inline fn real34Copy(src: *align(1) const real34_t, dst: *real34_t) void {
    dst.* = src.*;
}

// real bit macros.
inline fn realIsNaN(v: *const real_t) bool {
    return (v.bits & (DECNAN | DECSNAN)) != 0;
}
inline fn realIsNegative(v: *const real_t) bool {
    return (v.bits & 0x80) == 0x80;
}
inline fn realIsPositive(v: *const real_t) bool {
    return (v.bits & 0x80) == 0x00;
}
inline fn realIsSpecial(v: *const real_t) bool {
    return (v.bits & DECSPECIAL) != 0;
}
inline fn realIsZero(v: *const real_t) bool {
    return v.lsu[0] == 0 and v.digits == 1 and (v.bits & DECSPECIAL) == 0;
}
inline fn realSetPositiveSign(v: *real_t) void {
    v.bits &= 0x7f;
}
inline fn realSetNegativeSign(v: *real_t) void {
    v.bits |= 0x80;
}
inline fn realGetExponent(v: *const real_t) i32 {
    return v.digits + v.exponent - 1;
}

// real34 ops (use &ctxtReal34).
inline fn uInt32ToReal34(src: u32, dst: *real34_t) void {
    _ = decQuadFromUInt32(dst, src);
}
inline fn int32ToReal34(src: i32, dst: *real34_t) void {
    _ = decQuadFromInt32(dst, src);
}
inline fn real34FMA(f1: *align(1) const real34_t, f2: *align(1) const real34_t, term: *align(1) const real34_t, res: *real34_t) void {
    _ = decQuadFMA(res, f1, f2, term, &ctxtReal34);
}
inline fn real34Add(a: *align(1) const real34_t, b: *align(1) const real34_t, res: *real34_t) void {
    _ = decQuadAdd(res, a, b, &ctxtReal34);
}
inline fn real34Subtract(a: *align(1) const real34_t, b: *align(1) const real34_t, res: *real34_t) void {
    _ = decQuadSubtract(res, a, b, &ctxtReal34);
}
inline fn real34Multiply(a: *align(1) const real34_t, b: *align(1) const real34_t, res: *real34_t) void {
    _ = decQuadMultiply(res, a, b, &ctxtReal34);
}
inline fn real34Divide(a: *align(1) const real34_t, b: *align(1) const real34_t, res: *real34_t) void {
    _ = decQuadDivide(res, a, b, &ctxtReal34);
}
inline fn real34CopyAbs(src: *align(1) const real34_t, dst: *real34_t) void {
    _ = decQuadCopyAbs(dst, src);
}
inline fn real34ToIntegralValue(src: *align(1) const real34_t, dst: *real34_t, mode: c_int) void {
    _ = decQuadToIntegralValue(dst, src, &ctxtReal34, mode);
}
inline fn real34GetCoefficient(src: *align(1) const real34_t, bcd: [*]u8) i32 {
    return decQuadGetCoefficient(src, bcd);
}
inline fn real34GetExponent(src: *align(1) const real34_t) i32 {
    return decQuadGetExponent(src);
}
inline fn real34ToInt32(src: *align(1) const real34_t) i32 {
    return decQuadToInt32(src, &ctxtReal34, DEC_ROUND_DOWN);
}
inline fn real34ToReal(src: *align(1) const real34_t, dst: *real_t) void {
    _ = decimal128ToNumber(src, dst);
}
inline fn stringToReal34(src: [*c]const u8, dst: *real34_t) void {
    _ = decQuadFromString(dst, src, &ctxtReal34);
}

// real ops.
inline fn uInt32ToReal(src: u32, dst: *real_t) void {
    _ = decNumberFromUInt32(dst, src);
}
inline fn realFMA(f1: *align(1) const real_t, f2: *align(1) const real_t, term: *align(1) const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberFMA(res, f1, f2, term, ctx);
}
inline fn realGetCoefficient(src: *const real_t, bcd: [*]u8) void {
    _ = decNumberGetBCD(src, bcd);
}
inline fn realPlus(op: *align(1) const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberPlus(res, op, ctx);
}
inline fn stringToReal(src: [*c]const u8, dst: *real_t, ctx: *realContext_t) void {
    _ = decNumberFromString(dst, src, ctx);
}

// ===========================================================================
// Long integer <-> register
// ===========================================================================
pub export fn convertLongIntegerToLongIntegerRegister(lgInt: *const mpz_struct, regist: calcRegister_t) callconv(.c) void {
    const sizeInBytes: u16 = longIntegerSizeInBytes(lgInt);

    reallocateRegister(regist, dtLongInteger, toBlocks(sizeInBytes), longIntegerSignTag(lgInt));
    _ = frontier_char_string.xcopy(@ptrCast(regLongIntData(regist)), @ptrCast(lgInt._mp_d), sizeInBytes);
}

pub export fn convertLongIntegerRegisterToLongInteger(regist: calcRegister_t, lgInt: *mpz_struct) callconv(.c) void {
    var sizeInBytes: u32 = toBytes(getRegisterMaxDataLengthInBlocks(regist));

    mpz_init2(lgInt, 8 * @as(c_ulong, @max(sizeInBytes, LIMB_SIZE)));

    _ = frontier_char_string.xcopy(@ptrCast(lgInt._mp_d), @ptrCast(regLongIntData(regist)), sizeInBytes);

    // Trim trailing zero limbs.
    while (sizeInBytes >= LIMB_SIZE and lgInt._mp_d[sizeInBytes / LIMB_SIZE - 1] == 0) {
        sizeInBytes -= LIMB_SIZE;
    }

    if (sizeInBytes > 0 and getRegisterLongIntegerSign(regist) == LI_NEGATIVE) {
        lgInt._mp_size = -@as(c_int, @intCast(sizeInBytes / LIMB_SIZE));
    } else {
        lgInt._mp_size = @intCast(sizeInBytes / LIMB_SIZE);
    }
}

pub export fn convertLongIntegerRegisterToReal34Register(source: calcRegister_t, destination: calcRegister_t) callconv(.c) void {
    var lgInt: mpz_struct = undefined;

    convertLongIntegerRegisterToLongInteger(source, &lgInt);
    frontier_display.longIntegerToAllocatedString(&lgInt, tmpString, TMP_STR_LENGTH);
    mpz_clear(&lgInt);
    reallocateRegister(destination, dtReal34, REAL34_SIZE_IN_BLOCKS, amNoneU);
    stringToReal34(tmpString, reg34(destination));
}

pub export fn convertLongIntegerRegisterToReal34(source: calcRegister_t, destination: *real34_t) callconv(.c) void {
    var lgInt: mpz_struct = undefined;

    convertLongIntegerRegisterToLongInteger(source, &lgInt);
    frontier_display.longIntegerToAllocatedString(&lgInt, tmpString, TMP_STR_LENGTH);
    mpz_clear(&lgInt);
    stringToReal34(tmpString, destination);
}

pub export fn convertLongIntegerRegisterToReal(source: calcRegister_t, destination: *real_t, ctxt: *realContext_t) callconv(.c) void {
    var lgInt: mpz_struct = undefined;

    convertLongIntegerRegisterToLongInteger(source, &lgInt);
    convertLongIntegerToReal(&lgInt, destination, ctxt);
    mpz_clear(&lgInt);
}

pub export fn convertLongIntegerToReal(source: *mpz_struct, destination: *real_t, ctxt: *realContext_t) callconv(.c) void {
    frontier_display.longIntegerToAllocatedString(source, tmpString, TMP_STR_LENGTH);
    stringToReal(tmpString, destination, ctxt);
}

pub export fn convertLongIntegerToReal34(source: *mpz_struct, destination: *real34_t) callconv(.c) void {
    frontier_display.longIntegerToAllocatedString(source, tmpString, TMP_STR_LENGTH);
    stringToReal34(tmpString, destination);
}

pub export fn convertLongIntegerToShortIntegerRegister(lgInt: *mpz_struct, base: u32, destination: calcRegister_t) callconv(.c) void {
    var u64v: u64 = undefined;
    var overflow: bool = undefined;

    reallocateRegister(destination, dtShortInteger, SHORT_INTEGER_SIZE_IN_BLOCKS, base);
    if (longIntegerIsZero(lgInt)) {
        regShortInt(destination).* = 0;
    } else {
        if (comptime is32) {
            const d32: [*]u32 = @ptrCast(lgInt._mp_d);
            u64v = d32[0];
            if (absI(lgInt._mp_size) > 1) {
                u64v |= @as(u64, d32[1]) << 32;
            }
            overflow = absI(lgInt._mp_size) > 2 or (u64v & shortIntegerMask) != u64v;
            regShortInt(destination).* = u64v & shortIntegerMask;
        } else {
            const d64: [*]u64 = @ptrCast(lgInt._mp_d);
            u64v = d64[0];
            overflow = absI(lgInt._mp_size) > 1 or (u64v & shortIntegerMask) != u64v;
            regShortInt(destination).* = u64v & shortIntegerMask;
        }

        if (longIntegerIsNegative(lgInt)) {
            clearSystemFlag(@bitCast(FLAG_OVERFLOW));
            regShortInt(destination).* = frontier_integers.WP34S_intChs(regShortInt(destination).*);
        }

        if (overflow and !getSystemFlag(FLAG_OVERFLOW)) {
            setSystemFlag(@bitCast(FLAG_OVERFLOW));
        }
    }
}

pub export fn convertLongIntegerRegisterToShortIntegerRegister(source: calcRegister_t, destination: calcRegister_t) callconv(.c) void {
    var lgInt: mpz_struct = undefined;

    convertLongIntegerRegisterToLongInteger(source, &lgInt);
    convertLongIntegerToShortIntegerRegister(&lgInt, 10, destination);
    mpz_clear(&lgInt);
}

// ===========================================================================
// Short integer <-> register
// ===========================================================================
pub export fn convertShortIntegerRegisterToReal34Register(source: calcRegister_t, destination: calcRegister_t) callconv(.c) void {
    var value: u64 = undefined;
    var sign: i16 = undefined;
    var lowWord: real34_t = undefined;

    convertShortIntegerRegisterToUInt64(source, &sign, &value);
    reallocateRegister(destination, dtReal34, REAL34_SIZE_IN_BLOCKS, amNoneU);

    uInt32ToReal34(@intCast(value >> 32), reg34(destination));
    uInt32ToReal34(@intCast(value & 0x00000000ffffffff), &lowWord);
    real34FMA(reg34(destination), const34_2p32(), &lowWord, reg34(destination));

    if (sign != 0) {
        real34SetNegativeSign(reg34(destination));
    }
}

pub export fn convertShortIntegerRegisterToReal(source: calcRegister_t, destination: *real_t, ctxt: *realContext_t) callconv(.c) void {
    var value: u64 = undefined;
    var sign: i16 = undefined;
    var lowWord: real_t = undefined;

    convertShortIntegerRegisterToUInt64(source, &sign, &value);

    uInt32ToReal(@intCast(value >> 32), destination);
    uInt32ToReal(@intCast(value & 0x00000000ffffffff), &lowWord);
    realFMA(destination, const_2p32(), &lowWord, destination, ctxt);

    if (sign != 0) {
        realSetNegativeSign(destination);
    }
}

pub export fn convertShortIntegerRegisterToUInt64(regist: calcRegister_t, sign: *i16, value: *u64) callconv(.c) void {
    value.* = regShortInt(regist).* & shortIntegerMask;

    if (shortIntegerMode == SIM_UNSIGN) {
        sign.* = 0;
    } else {
        if ((value.* & shortIntegerSignBit) != 0) { // Negative value
            sign.* = 1;

            if (shortIntegerMode == SIM_2COMPL) {
                value.* = ((~value.*) +% 1) & shortIntegerMask;
            } else if (shortIntegerMode == SIM_1COMPL) {
                value.* = (~value.*) & shortIntegerMask;
            } else if (shortIntegerMode == SIM_SIGNMT) {
                value.* -%= shortIntegerSignBit;
            } else {
                frontier_error.displayBugScreen("convertShortIntegerRegisterToUInt64: bad shortIntegerMode");
                sign.* = 0;
                value.* = 0;
            }
        } else { // Positive value
            sign.* = 0;
        }
    }
}

pub export fn convertShortIntegerRegisterToLongInteger(source: calcRegister_t, lgInt: *mpz_struct) callconv(.c) void {
    var value: u64 = undefined;
    var sign: i16 = undefined;

    convertShortIntegerRegisterToUInt64(source, &sign, &value);

    mpz_init(lgInt);
    mpz_set_ui(lgInt, @intCast(@as(u32, @intCast(value >> 32))));
    mpz_mul_2exp(lgInt, lgInt, 32);
    mpz_add_ui(lgInt, lgInt, @intCast(value & 0x00000000ffffffff));

    if (sign != 0) {
        longIntegerChangeSign(lgInt);
    }
}

pub export fn convertShortIntegerRegisterToLongIntegerRegister(source: calcRegister_t, destination: calcRegister_t) callconv(.c) void {
    var lgInt: mpz_struct = undefined;

    convertShortIntegerRegisterToLongInteger(source, &lgInt);

    convertLongIntegerToLongIntegerRegister(&lgInt, destination);
    mpz_clear(&lgInt);
}

pub export fn convertUInt64ToShortIntegerRegister(sign: i16, value_arg: u64, base: u32, regist: calcRegister_t) callconv(.c) void {
    var value = value_arg;
    if (sign != 0) { // Negative value
        if ((shortIntegerMode == SIM_2COMPL) or (shortIntegerMode == SIM_UNSIGN)) {
            value = (~value) +% 1;
        } else if (shortIntegerMode == SIM_1COMPL) {
            value = ~value;
        } else if (shortIntegerMode == SIM_SIGNMT) {
            value +%= shortIntegerSignBit;
        } else {
            frontier_error.displayBugScreen("convertUInt64ToShortIntegerRegister: bad shortIntegerMode");
            value = 0;
        }
    }

    reallocateRegister(regist, dtShortInteger, SHORT_INTEGER_SIZE_IN_BLOCKS, base);
    regShortInt(regist).* = value & shortIntegerMask;
}

// ===========================================================================
// real34 / real <-> long integer
// ===========================================================================
pub export fn convertReal34ToLongInteger(re34: *align(1) const real34_t, lgInt: *mpz_struct, roundingMode: c_int) callconv(.c) void {
    var bcd: [DECQUAD_Pmax]u8 = undefined;
    var sign: i32 = undefined;
    var exponent: i32 = undefined;
    var real34: real34_t = undefined;

    real34ToIntegralValue(re34, &real34, roundingMode);
    sign = real34GetCoefficient(&real34, &bcd);
    exponent = real34GetExponent(&real34);

    mpz_init(lgInt);
    mpz_set_ui(lgInt, bcd[0]);

    var i: usize = 1;
    while (i < DECQUAD_Pmax) : (i += 1) {
        mpz_mul_ui(lgInt, lgInt, 10);
        mpz_add_ui(lgInt, lgInt, bcd[i]);
    }

    while (exponent > 0) {
        mpz_mul_ui(lgInt, lgInt, 10);
        exponent -= 1;
    }

    if (sign != 0) {
        longIntegerChangeSign(lgInt);
    }
}

pub export fn convertReal34ToLongIntegerRegister(real34: *align(1) const real34_t, dest: calcRegister_t, roundingMode: c_int) callconv(.c) void {
    var lgInt: mpz_struct = undefined;

    convertReal34ToLongInteger(real34, &lgInt, roundingMode);
    convertLongIntegerToLongIntegerRegister(&lgInt, dest);

    mpz_clear(&lgInt);
}

pub export fn convertRealToLongInteger(re: *const real_t, lgInt: *mpz_struct, roundingMode: c_int) callconv(.c) void {
    var bcd: [75]u8 = undefined;
    var sign: i32 = undefined;
    var exponent: i32 = undefined;
    var real: real_t = undefined;

    realToIntegralValue(re, &real, roundingMode, &ctxtReal39);
    realGetCoefficient(&real, &bcd);
    sign = if (realIsNegative(&real)) 1 else 0;
    exponent = real.exponent;

    mpz_set_ui(lgInt, bcd[0]);

    var i: i32 = 1;
    while (i < real.digits) : (i += 1) {
        mpz_mul_ui(lgInt, lgInt, 10);
        mpz_add_ui(lgInt, lgInt, bcd[@intCast(i)]);
    }

    while (exponent > 0) {
        mpz_mul_ui(lgInt, lgInt, 10);
        exponent -= 1;
    }

    if (sign != 0) {
        longIntegerChangeSign(lgInt);
    }
}

pub export fn convertRealToLongIntegerRegister(real: *const real_t, dest: calcRegister_t, roundingMode: c_int) callconv(.c) void {
    var lgInt: mpz_struct = undefined;

    mpz_init(&lgInt);

    convertRealToLongInteger(real, &lgInt, roundingMode);
    convertLongIntegerToLongIntegerRegister(&lgInt, dest);
    mpz_clear(&lgInt);
}

pub export fn realToIntegralValue(source: *const real_t, destination: *real_t, mode: c_int, realContext: *realContext_t) callconv(.c) void {
    const savedRoundingMode: c_int = realContext.round;
    realContext.round = mode;
    realContext.status = 0;
    _ = decNumberToIntegralValue(destination, source, realContext);
    realContext.round = savedRoundingMode;
}

// ===========================================================================
// real result registers
// ===========================================================================
pub export fn convertRealToReal34ResultRegister(real: *const real_t, dest: calcRegister_t) callconv(.c) void {
    var rounded: real_t = undefined;
    roundToSignificantDigits(real, &rounded, if (significantDigits == 0) 34 else significantDigits, &ctxtReal75);
    realToReal34(&rounded, reg34(dest));
}

pub export fn convertRealToImag34ResultRegister(real: *const real_t, dest: calcRegister_t) callconv(.c) void {
    var rounded: real_t = undefined;
    roundToSignificantDigits(real, &rounded, if (significantDigits == 0) 34 else significantDigits, &ctxtReal75);
    realToReal34(&rounded, regImag34(dest));
}

inline fn realToReal34(src: *const real_t, dst: *real34_t) void {
    _ = decimal128FromNumber(dst, src, &ctxtReal34);
}

pub export fn convertRealToResultRegister(x: *const real_t, dest: calcRegister_t, angle: angularMode_t) callconv(.c) void {
    reallocateRegister(dest, dtReal34, REAL34_SIZE_IN_BLOCKS, @bitCast(angle));
    convertRealToReal34ResultRegister(x, dest);
}

pub export fn convertComplexToResultRegister(real: *const real_t, imag: *const real_t, dest: calcRegister_t) callconv(.c) void {
    reallocateRegister(dest, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNoneU);
    convertRealToReal34ResultRegister(real, dest);
    convertRealToImag34ResultRegister(imag, dest);
}

pub export fn convertComplexToResultRegisterRPangle(real: *const real_t, imag: *const real_t, dest: calcRegister_t, angl: angularMode_t, polarTag: u8) callconv(.c) void {
    reallocateRegister(dest, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, @bitCast(angl));
    convertRealToReal34ResultRegister(real, dest);
    convertRealToImag34ResultRegister(imag, dest);
    setComplexRegisterPolarMode(dest, polarTag);
}

// ===========================================================================
// Time / Date
// ===========================================================================
pub export fn convertTimeRegisterToReal34Register(source: calcRegister_t, destination: calcRegister_t) callconv(.c) void {
    var real34: real34_t = undefined;
    real34Copy(reg34(source), &real34);
    reallocateRegister(destination, dtReal34, REAL34_SIZE_IN_BLOCKS, amNoneU);
    real34Divide(&real34, const34_3600(), reg34(destination));
}

pub export fn convertReal34RegisterToTimeRegister(source: calcRegister_t, destination: calcRegister_t) callconv(.c) void {
    var real34: real34_t = undefined;
    real34Copy(reg34(source), &real34);
    reallocateRegister(destination, dtTime, REAL34_SIZE_IN_BLOCKS, amNoneU);
    real34Multiply(&real34, const34_3600(), reg34(destination));
}

pub export fn convertLongIntegerRegisterToTimeRegister(source: calcRegister_t, destination: calcRegister_t) callconv(.c) void {
    convertLongIntegerRegisterToReal34Register(source, destination);
    convertReal34RegisterToTimeRegister(destination, destination);
}

pub export fn convertDateRegisterToReal34Register(source: calcRegister_t, destination: calcRegister_t) callconv(.c) void {
    var y: real34_t = undefined;
    var m: real34_t = undefined;
    var d: real34_t = undefined;
    var j: real34_t = undefined;
    var isNegative: bool = undefined;

    frontier_date_time.internalDateToJulianDay(reg34(source), &j);
    frontier_date_time.decomposeJulianDay(&j, &y, &m, &d);
    isNegative = real34IsNegative(&y);
    real34SetPositiveSign(&y);

    if (getSystemFlag(FLAG_YMD)) {
        real34Divide(&m, const34_100(), &m);
        real34Multiply(&d, const34_1e_4(), &d);
    } else if (getSystemFlag(FLAG_MDY)) {
        real34Divide(&d, const34_100(), &d);
        real34Divide(&y, const34_1e6(), &y);
    } else if (getSystemFlag(FLAG_DMY)) {
        real34Divide(&m, const34_100(), &m);
        real34Divide(&y, const34_1e6(), &y);
    }

    reallocateRegister(destination, dtReal34, REAL34_SIZE_IN_BLOCKS, amNoneU);
    real34Add(&y, &m, reg34(destination));
    real34Add(reg34(destination), &d, reg34(destination));
    if (isNegative) {
        real34SetNegativeSign(reg34(destination));
    }
}

const rtc_read: *const fn (*tm_t, *dt_t) callconv(.c) void = if (dmcp_build)
    @ptrFromInt(0x08000201 + 204)
else
    undefined;

pub export fn convertReal34RegisterToDateRegister(source: calcRegister_t, destination: calcRegister_t, handleYY: bool) callconv(.c) void {
    var part1: real34_t = undefined;
    var part2: real34_t = undefined;
    var part3: real34_t = undefined;
    var val: real34_t = undefined;
    var isNegative: bool = undefined;

    isNegative = real34IsNegative(reg34(source));
    real34CopyAbs(reg34(source), &part2);
    real34ToIntegralValue(&part2, &part1, DEC_ROUND_DOWN); // Y D or M

    real34Subtract(&part2, &part1, &part2);
    real34Multiply(&part2, const34_100(), &part2);
    real34Copy(&part2, &part3);
    real34ToIntegralValue(&part2, &part2, DEC_ROUND_DOWN); // M or D

    real34Subtract(&part3, &part2, &part3);
    int32ToReal34(if (getSystemFlag(FLAG_YMD)) 100 else 10000, &val);
    real34Multiply(&part3, &val, &part3);
    real34ToIntegralValue(&part3, &part3, DEC_ROUND_DOWN); // D or Y

    if (isNegative) {
        if (getSystemFlag(FLAG_YMD)) {
            real34SetNegativeSign(&part1);
        } else {
            real34SetNegativeSign(&part3);
        }
    }

    var lastCenturyHighUsedtmp: u16 = undefined;
    if (handleYY) {
        // get the actual active YYYY value, excluding the tracking flag
        lastCenturyHighUsedtmp = lastCenturyHighUsed & (YY_MASK_TRACKING - 1);

        // remember last used century if the century is not an abbreviation
        if (getSystemFlag(FLAG_YMD)) {
            if (real34CompareGreaterEqual(&part1, const34_100())) {
                const t: i16 = @truncate(@divTrunc(real34ToInt32(&part1), 100));
                lastCenturyHighUsedtmp = @bitCast(@as(i16, @truncate(@as(i32, 100) * t + 99)));
            }
        }
        // FLAG_MDY // FLAG_DMY
        else if (real34CompareGreaterEqual(&part3, const34_100())) {
            const t: i16 = @truncate(@divTrunc(real34ToInt32(&part3), 100));
            lastCenturyHighUsedtmp = @bitCast(@as(i16, @truncate(@as(i32, 100) * t + 99)));
        }

        // No YYYY digits, i.e. no year given at all, so we use the current year.
        if ((lastCenturyHighUsed & 0x8000) == 0) {
            var pcYear: i32 = undefined;
            if (comptime dmcp_build) {
                var timeInfo: tm_t = undefined;
                var dateInfo: dt_t = undefined;
                rtc_read(&timeInfo, &dateInfo);
                pcYear = dateInfo.year;
            } else {
                const epoch: i64 = time(null);
                const timeInfo = localtime(&epoch);
                pcYear = timeInfo.year + 1900;
            }

            if (getSystemFlag(FLAG_YMD)) {
                if (real34IsZero(&part1)) {
                    uInt32ToReal34(@intCast(pcYear), &part1);
                }
            }
            // FLAG_MDY // FLAG_DMY
            else if (real34IsZero(&part3)) {
                uInt32ToReal34(@intCast(pcYear), &part3);
            }
        }

        // Only YY digits
        const thresholdYYHigh: i16 = @max(0, @as(i16, @bitCast(lastCenturyHighUsed & (YY_MASK_TRACKING - 1))) - 99);
        if (getSystemFlag(FLAG_YMD)) {
            if ((lastCenturyHighUsed & YY_MASK_OFF) == 0 and real34CompareLessThan(&part1, const34_100())) {
                var yy: i16 = @intCast(real34ToInt32(&part1));
                if (yy >= @rem(thresholdYYHigh, 100)) {
                    yy += (thresholdYYHigh - @rem(thresholdYYHigh, 100));
                } else {
                    yy += (thresholdYYHigh - @rem(thresholdYYHigh, 100)) + 100;
                }
                int32ToReal34(@intCast(yy), &part1);
            }
        }
        // FLAG_MDY // FLAG_DMY
        else if ((lastCenturyHighUsed & YY_MASK_OFF) == 0 and real34CompareLessThan(&part3, const34_100())) {
            var yy: i16 = @intCast(real34ToInt32(&part3));
            if (yy >= @rem(thresholdYYHigh, 100)) {
                yy += (thresholdYYHigh - @rem(thresholdYYHigh, 100));
            } else {
                yy += (thresholdYYHigh - @rem(thresholdYYHigh, 100)) + 100;
            }
            int32ToReal34(@intCast(yy), &part3);
        }
    }

    if ((getSystemFlag(FLAG_YMD) and !frontier_date_time.isValidDay(&part1, &part2, &part3)) or
        (getSystemFlag(FLAG_MDY) and !frontier_date_time.isValidDay(&part3, &part1, &part2)) or
        (getSystemFlag(FLAG_DMY) and !frontier_date_time.isValidDay(&part3, &part2, &part1)))
    {
        frontier_error.displayCalcErrorMessage(ERROR_BAD_TIME_OR_DATE_INPUT, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
        moreInfoOnError("In function convertReal34RegisterToDateRegister:", "Invalid date input like 30 Feb.");
        return;
    }

    // update stored YYYY and add the control bits again
    if (handleYY and (lastCenturyHighUsed & YY_MASK_OFF) == 0 and (lastCenturyHighUsed & YY_MASK_TRACKING) != 0) {
        lastCenturyHighUsed = (lastCenturyHighUsed & ~(YY_MASK_TRACKING - 1)) | (lastCenturyHighUsedtmp & (YY_MASK_TRACKING - 1));
    }

    reallocateRegister(destination, dtDate, REAL34_SIZE_IN_BLOCKS, amNoneU);
    if (getSystemFlag(FLAG_YMD)) {
        frontier_date_time.composeJulianDay(&part1, &part2, &part3, reg34(destination));
    } else if (getSystemFlag(FLAG_MDY)) {
        frontier_date_time.composeJulianDay(&part3, &part1, &part2, reg34(destination));
    } else if (getSystemFlag(FLAG_DMY)) {
        frontier_date_time.composeJulianDay(&part3, &part2, &part1, reg34(destination));
    }

    real34Multiply(reg34(destination), const34_86400(), reg34(destination));
    real34Add(reg34(destination), const34_43200(), reg34(destination));
}

// ===========================================================================
// Matrices
// ===========================================================================
pub export fn convertReal34MatrixRegisterToReal34Matrix(regist: calcRegister_t, matrix: *real34Matrix_t) callconv(.c) void {
    const matrixHeader = regMatrixHeader(regist);

    if (realMatrixInit(matrix, matrixHeader.matrixRows, matrixHeader.matrixColumns)) {
        if (matrix.matrixElements) |elems| {
            _ = frontier_char_string.xcopy(@ptrCast(elems), @ptrCast(regRealMatrixElems(regist)), (@as(u32, matrix.header.matrixColumns) * matrix.header.matrixRows) * REAL34_SIZE_IN_BYTES);
        }
    } else {
        frontier_error.displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
    }
}

pub export fn convertReal34MatrixToReal34MatrixRegister(matrix: *const real34Matrix_t, regist: calcRegister_t) callconv(.c) void {
    const neededSizeInBytes: u32 = (@as(u32, matrix.header.matrixColumns) * matrix.header.matrixRows) * REAL34_SIZE_IN_BYTES;
    reallocateRegister(regist, dtReal34Matrix, toBlocks(neededSizeInBytes), amNoneU);
    if (lastErrorCode != ERROR_RAM_FULL) {
        _ = frontier_char_string.xcopy(@ptrCast(regMatrixHeader(regist)), @ptrCast(matrix), 4);
        _ = frontier_char_string.xcopy(@ptrCast(regRealMatrixElems(regist)), @ptrCast(matrix.matrixElements.?), neededSizeInBytes);
    }
}

pub export fn convertComplex34MatrixRegisterToComplex34Matrix(regist: calcRegister_t, matrix: *complex34Matrix_t) callconv(.c) void {
    const matrixHeader = regMatrixHeader(regist);

    if (complexMatrixInit(matrix, matrixHeader.matrixRows, matrixHeader.matrixColumns)) {
        if (matrix.matrixElements) |elems| {
            _ = frontier_char_string.xcopy(@ptrCast(elems), @ptrCast(regComplexMatrixElems(regist)), (@as(u32, matrix.header.matrixColumns) * matrix.header.matrixRows) * COMPLEX34_SIZE_IN_BYTES);
        }
    } else {
        frontier_error.displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
    }
}

pub export fn convertComplex34MatrixToComplex34MatrixRegister(matrix: *const complex34Matrix_t, regist: calcRegister_t) callconv(.c) void {
    const neededSizeInBytes: u32 = (@as(u32, matrix.header.matrixColumns) * matrix.header.matrixRows) * COMPLEX34_SIZE_IN_BYTES;
    reallocateRegister(regist, dtComplex34Matrix, toBlocks(neededSizeInBytes), amNoneU);
    if (lastErrorCode != ERROR_RAM_FULL) {
        _ = frontier_char_string.xcopy(@ptrCast(regMatrixHeader(regist)), @ptrCast(matrix), 4);
        _ = frontier_char_string.xcopy(@ptrCast(regComplexMatrixElems(regist)), @ptrCast(matrix.matrixElements.?), neededSizeInBytes);
    }
}

pub export fn convertReal34MatrixToComplex34Matrix(source: *const real34Matrix_t, destination: *complex34Matrix_t) callconv(.c) void {
    if (complexMatrixInit(destination, source.header.matrixRows, source.header.matrixColumns)) {
        if (destination.matrixElements) |delems| {
            const count: u16 = source.header.matrixRows * source.header.matrixColumns;
            var i: u16 = 0;
            while (i < count) : (i += 1) {
                real34Copy(&source.matrixElements.?[i], &delems[i].real);
                real34SetZero(&delems[i].imag);
            }
        }
    } else {
        frontier_error.displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
    }
}

pub export fn convertReal34MatrixRegisterToComplex34Matrix(source: calcRegister_t, destination: *complex34Matrix_t) callconv(.c) void {
    var matrix: real34Matrix_t = undefined;
    linkToRealMatrixRegister(source, &matrix);
    convertReal34MatrixToComplex34Matrix(&matrix, destination);
}

pub export fn convertReal34MatrixRegisterToComplex34MatrixRegister(source: calcRegister_t, destination: calcRegister_t) callconv(.c) void {
    var matrix: complex34Matrix_t = undefined;
    convertReal34MatrixRegisterToComplex34Matrix(source, &matrix);
    convertComplex34MatrixToComplex34MatrixRegister(&matrix, destination);
    setComplexRegisterAngularMode(destination, currentAngularMode);
    setComplexRegisterPolarMode(destination, if (getSystemFlag(FLAG_POLAR)) amPolar else 0);
    complexMatrixFree(&matrix);
}

// ===========================================================================
// Doubles and floats
// ===========================================================================
pub export fn sci_fmt(buf: [*c]u8, n: c_int, x_arg: f64) callconv(.c) void {
    abi.sci_format.sciFmt(buf[0..@intCast(n)], x_arg);
}

pub export fn convertDoubleToString(x: f64, n: i16, buff: [*c]u8) callconv(.c) void {
    // The PC_BUILD diagnostic printf path is host-only console output; dropped.
    abi.sci_format.normalizeDoubleString(buff[0..@intCast(n)], x);
}

pub export fn convertDoubleToReal(x: f64, destination: *real_t, ctxt: *realContext_t) callconv(.c) void {
    var buff: [100]u8 = undefined;

    buff[0] = 0;
    convertDoubleToString(x, 100, &buff);
    stringToReal(&buff, destination, ctxt);
}

pub export fn convertDoubleToReal34Register(x: f64, destination: calcRegister_t) callconv(.c) void {
    var buff: [100]u8 = undefined;

    reallocateRegister(destination, dtReal34, REAL34_SIZE_IN_BLOCKS, amNoneU);
    convertDoubleToString(x, 100, &buff);
    stringToReal34(&buff, reg34(destination));

    // PC_BUILD console error path dropped (host-only diagnostic).
}

pub export fn convertDoubleToReal34RegisterPush(x: f64, destination: calcRegister_t) callconv(.c) void {
    setSystemFlag(FLAG_ASLIFT);
    liftStack();
    convertDoubleToReal34Register(x, destination);
    setSystemFlag(FLAG_ASLIFT);
}

pub export fn convertRegisterToDouble(regist: calcRegister_t) callconv(.c) f64 {
    var regReal: real_t = undefined;
    var regImag: real_t = undefined;

    return if (getRegisterAsComplex(regist, &regReal, &regImag)) fnRealToFloat(&regReal) else DOUBLE_NOT_INIT;
}

const exps = [_]f32{
    1.e-45, 1.e-44, 1.e-43, 1.e-42, 1.e-41, 1.e-40, 1.e-39, 1.e-38,
    1.e-37, 1.e-36, 1.e-35, 1.e-34, 1.e-33, 1.e-32, 1.e-31, 1.e-30,
    1.e-29, 1.e-28, 1.e-27, 1.e-26, 1.e-25, 1.e-24, 1.e-23, 1.e-22,
    1.e-21, 1.e-20, 1.e-19, 1.e-18, 1.e-17, 1.e-16, 1.e-15, 1.e-14,
    1.e-13, 1.e-12, 1.e-11, 1.e-10, 1.e-9,  1.e-8,  1.e-7,  1.e-6,
    1.e-5,  1.e-4,  1.e-3,  1.e-2,  1.e-1,  1.e0,   1.e1,   1.e2,
    1.e3,   1.e4,   1.e5,   1.e6,   1.e7,   1.e8,   1.e9,   1.e10,
    1.e11,  1.e12,  1.e13,  1.e14,  1.e15,  1.e16,  1.e17,  1.e18,
    1.e19,  1.e20,  1.e21,  1.e22,  1.e23,  1.e24,  1.e25,  1.e26,
    1.e27,  1.e28,  1.e29,  1.e30,  1.e31,  1.e32,  1.e33,  1.e34,
    1.e35,  1.e36,  1.e37,  1.e38,
};

fn fnRealToFloat(r: *const real_t) f32 {
    var s: i32 = 0;
    var j: i32 = undefined;
    var n: i32 = undefined;
    var e: i32 = undefined;

    if (realIsSpecial(r)) {
        if (realIsNaN(r)) {
            return makeNanF32();
        }
        // goto infinite
        if (realIsPositive(r)) {
            return makeInfF32();
        }
        return -makeInfF32();
    }
    if (realIsZero(r)) {
        // goto zero
        return if (realIsPositive(r)) @as(f32, 0.0) else -@as(f32, 0.0);
    }

    j = @divTrunc(r.digits + DECDPUN - 1, DECDPUN);
    while (j > 0) {
        j -= 1;
        s = r.lsu[@intCast(j)];
        if (s != 0) {
            break;
        }
    }
    n = 0;
    while (true) {
        j -= 1;
        if (!(j >= 0 and n < 2)) break;
        s = (s * 1000) + r.lsu[@intCast(j)];
        n += 1;
    }
    if (realIsNegative(r)) {
        s = -s;
    }
    e = r.exponent + (j + 1) * DECDPUN;
    if (e < -45) {
        // zero:
        return if (realIsPositive(r)) @as(f32, 0.0) else -@as(f32, 0.0);
    }
    if (e > 38) {
        // infinite:
        if (realIsPositive(r)) {
            return makeInfF32();
        }
        return -makeInfF32();
    }
    return @as(f32, @floatFromInt(s)) * exps[@intCast(e + 45)];
}

inline fn makeNanF32() f32 {
    return std.math.nan(f32);
}
inline fn makeInfF32() f32 {
    return std.math.inf(f32);
}

pub export fn realToFloat(vv: *const real_t, v: *f32) callconv(.c) void {
    v.* = fnRealToFloat(vv);
}

fn fnRealToDouble(r: *const real_t) f64 {
    var buffer: [100]u8 = undefined;
    if (realIsSpecial(r)) {
        if (realIsNaN(r)) {
            return std.math.nan(f64);
        }
        return if (realIsPositive(r)) std.math.inf(f64) else -std.math.inf(f64);
    }
    if (realIsZero(r)) {
        return if (realIsPositive(r)) @as(f64, 0.0) else -@as(f64, 0.0);
    }
    _ = decNumberToString(r, &buffer);
    return strtod(&buffer, null);
}

extern fn strtod(s: [*c]const u8, endptr: ?*[*c]u8) f64;

pub export fn realToDouble(vv: *const real_t, v: *f64) callconv(.c) void {
    v.* = fnRealToDouble(vv);
}

// ===========================================================================
// Type checks / error helpers
// ===========================================================================
fn typeIsNumber(t: u32, cmplx: ?*bool) bool {
    if (t == dtComplex34) {
        if (cmplx) |c| c.* = true;
        return true;
    }
    if (t == dtLongInteger or t == dtShortInteger or t == dtReal34) {
        if (cmplx) |c| c.* = false;
        return true;
    }
    return false;
}

pub export fn badTypeError(reg: calcRegister_t) callconv(.c) void {
    frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_T);
    if (comptime extra_info) {
        const name = frontier_debug.getRegisterDataTypeName(reg, true, false);
        const slice = bufPrintZ(errorMessageBuf(), "cannot convert Register {d} from {s}", .{ reg, std.mem.span(name) }) catch return;
        c_moreInfoOnError("In function badTypeError:", slice.ptr, null, null);
    }
}

inline fn errorMessageBuf() []u8 {
    // errorMessage is a host buffer of ample size; bound to a reasonable slice.
    return errorMessage[0..256];
}

pub export fn badDomainError(reg: calcRegister_t) callconv(.c) void {
    _ = reg;
    frontier_error.displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_T);
    moreInfoOnError("In function badDomainError:", "The input value is outside of the domain.");
}

pub export fn badTypeErrorX() callconv(.c) void {
    badTypeError(REGISTER_X);
}

pub export fn badDomainErrorX() callconv(.c) void {
    badDomainError(REGISTER_X);
}

// ===========================================================================
// getRegisterAs* family
// ===========================================================================
pub export fn getRegisterAsComplex(reg: calcRegister_t, r: *real_t, i: *real_t) callconv(.c) bool {
    switch (getRegisterDataType(reg)) {
        dtLongInteger => convertLongIntegerRegisterToReal(reg, r, &ctxtReal75),
        dtShortInteger => convertShortIntegerRegisterToReal(reg, r, &ctxtReal34),
        dtReal34 => real34ToReal(reg34(reg), r),
        dtComplex34 => {
            real34ToReal(reg34(reg), r);
            real34ToReal(regImag34(reg), i);
            return true;
        },
        else => {
            badTypeError(reg);
            return false;
        },
    }
    frontier_real_type.realSetZero(i);
    return true;
}

pub export fn getRegisterAsComplexOrAnyRealQuiet(reg: calcRegister_t, r: *real_t, i: *real_t, cmplx: ?*bool) callconv(.c) bool {
    switch (getRegisterDataType(reg)) {
        dtLongInteger => convertLongIntegerRegisterToReal(reg, r, &ctxtReal75),
        dtShortInteger => convertShortIntegerRegisterToReal(reg, r, &ctxtReal34),
        dtTime, dtDate, dtReal34 => real34ToReal(reg34(reg), r),
        dtComplex34 => {
            real34ToReal(reg34(reg), r);
            real34ToReal(regImag34(reg), i);
            if (cmplx) |c| c.* = true;
            return true;
        },
        else => return false,
    }
    frontier_real_type.realSetZero(i);
    return true;
}

pub export fn getRegisterAsComplexOrAnyReal(reg: calcRegister_t, r: *real_t, i: *real_t, cmplx: ?*bool) callconv(.c) bool {
    const ret = getRegisterAsComplexOrAnyRealQuiet(reg, r, i, cmplx);
    if (!ret) {
        badTypeError(reg);
    }
    return ret;
}

pub export fn getRegisterAsComplexOrRealQuiet(reg: calcRegister_t, r: *real_t, i: *real_t, cmplx: ?*bool) callconv(.c) bool {
    const t = getRegisterDataType(reg);
    if (t == dtTime or t == dtDate) {
        return false;
    }
    return getRegisterAsComplexOrAnyRealQuiet(reg, r, i, cmplx);
}

pub export fn getRegisterAsComplexOrReal(reg: calcRegister_t, r: *real_t, i: *real_t, cmplx: ?*bool) callconv(.c) bool {
    const ret = getRegisterAsComplexOrRealQuiet(reg, r, i, cmplx);
    if (!ret) {
        badTypeError(reg);
    }
    return ret;
}

pub export fn getRegisterAsAnyRealQuiet(reg: calcRegister_t, val: *real_t) callconv(.c) bool {
    switch (getRegisterDataType(reg)) {
        dtLongInteger => convertLongIntegerRegisterToReal(reg, val, &ctxtReal75),
        dtShortInteger => convertShortIntegerRegisterToReal(reg, val, &ctxtReal34),
        dtDate, dtTime, dtReal34 => real34ToReal(reg34(reg), val),
        dtComplex34 => {
            if (real34IsZero(regImag34(reg))) {
                real34ToReal(reg34(reg), val);
            } else {
                return false;
            }
        },
        else => return false,
    }
    return true;
}

pub export fn convertComplexRegisterToRealIfZeroImag(regist: calcRegister_t) callconv(.c) void {
    var b: real_t = undefined;
    if (real34IsZero(regImag34(regist))) {
        real34ToReal(reg34(regist), &b);
        convertRealToResultRegister(&b, regist, amNone);
    }
}

inline fn real34IsZero(v: *align(1) const real34_t) bool {
    return decQuadIsZero(v) != 0;
}
extern fn decQuadIsZero(v: *align(1) const real34_t) u32;

pub export fn getRegisterAsRealQuiet(reg: calcRegister_t, val: *real_t) callconv(.c) bool {
    const t = getRegisterDataType(reg);
    if (t == dtDate or t == dtTime) {
        return false;
    }
    return getRegisterAsAnyRealQuiet(reg, val);
}

pub export fn getRegisterAsReal(reg: calcRegister_t, val: *real_t) callconv(.c) bool {
    const res = getRegisterAsRealQuiet(reg, val);
    if (!res) {
        badTypeError(reg);
    }
    return res;
}

pub export fn getRegisterAsAnyReal(reg: calcRegister_t, val: *real_t) callconv(.c) bool {
    const res = getRegisterAsAnyRealQuiet(reg, val);
    if (!res) {
        badTypeError(reg);
    }
    return res;
}

pub export fn getRegisterAsReal34Quiet(reg: calcRegister_t, val: *real34_t) callconv(.c) bool {
    var realVal: real_t = undefined;
    if (getRegisterAsRealQuiet(reg, &realVal)) {
        realToReal34(&realVal, val);
        return true;
    }
    return false;
}

pub export fn getRegisterAsShortInt(reg: calcRegister_t, sign: *bool, val: *u64, overflow: ?*bool, fractional: ?*bool) callconv(.c) bool {
    var rval: real_t = undefined;
    var ival: mpz_struct = undefined;
    var u64v: u64 = undefined;
    var sign16: i16 = undefined;
    var of: bool = false;
    var frac: bool = false;

    sw: switch (getRegisterDataType(reg)) {
        dtShortInteger => {
            convertShortIntegerRegisterToUInt64(reg, &sign16, val);
            sign.* = sign16 != 0;
        },
        dtLongInteger => {
            convertLongIntegerRegisterToLongInteger(reg, &ival);
            if (comptime is32) {
                const d32: [*]u32 = @ptrCast(ival._mp_d);
                u64v = d32[0];
                if (absI(ival._mp_size) > 1) {
                    u64v |= @as(u64, d32[1]) << 32;
                }
                of = absI(ival._mp_size) > 2 or (u64v & shortIntegerMask) != u64v;
                u64v &= shortIntegerMask;
            } else {
                const d64: [*]u64 = @ptrCast(ival._mp_d);
                u64v = d64[0] & shortIntegerMask;
                of = absI(ival._mp_size) > 1 or (u64v & shortIntegerMask) != u64v;
            }
            sign.* = longIntegerIsNegative(&ival);
            mpz_clear(&ival);
            val.* = u64v;
        },
        dtComplex34, dtReal34 => {
            if (getRegisterAsReal(reg, &rval)) {
                if (realIsSpecial(&rval)) {
                    badDomainError(reg);
                    return false;
                }
                sign.* = realIsNegative(&rval);
                realSetPositiveSign(&rval);
                frac = !realIsAnInteger(&rval);

                var iv: real_t = undefined;
                realToIntegralValue(&rval, &iv, DEC_ROUND_DOWN, &ctxtReal39);
                _ = decNumberQuantize(&iv, &iv, const_0(), &ctxtReal39);
                u64v = decNumberToUInt64(&iv, &ctxtReal39);

                of = (u64v & shortIntegerMask) != u64v;
                if (!of) {
                    switch (shortIntegerMode) {
                        SIM_UNSIGN => {
                            of = realCompareGreaterEqual(&rval, const_2p64());
                        },
                        SIM_2COMPL => {
                            if (sign.*) {
                                of = realCompareGreaterThan(&rval, const_2p63());
                            } else {
                                of = realCompareGreaterEqual(&rval, const_2p63());
                            }
                        },
                        SIM_1COMPL, SIM_SIGNMT => {
                            of = realCompareGreaterEqual(&rval, const_2p63());
                        },
                        else => {},
                    }
                }
                val.* = u64v;
                break :sw;
            }
            // fall through
            badTypeError(reg);
            return false;
        },
        else => {
            badTypeError(reg);
            return false;
        },
    }

    if (overflow) |o| {
        o.* = of;
    }
    if (fractional) |f| {
        f.* = frac;
    }
    return true;
}

pub export fn getRegisterAsRawShortInt(reg: calcRegister_t, val: *u64, base: ?*u32) callconv(.c) bool {
    var sign: bool = undefined;
    var overflow: bool = undefined;
    var fractional: bool = undefined;
    var v: u64 = undefined;
    var b: u32 = undefined;

    if (getRegisterDataType(reg) == dtShortInteger) {
        v = regShortInt(reg).*;
        b = getRegisterShortIntegerBase(reg);
    } else {
        if (!getRegisterAsShortInt(reg, &sign, &v, &overflow, &fractional)) {
            return false;
        }
        if (overflow or fractional) {
            badDomainError(reg);
            return false;
        }
        v = @bitCast(frontier_integers.WP34S_build_value(v, @intFromBool(sign)));
        b = if (lastIntegerBase != 0) lastIntegerBase else 10;
    }
    if (base) |bp| {
        bp.* = b;
    }
    val.* = v;
    return true;
}

pub export fn getRegisterAsLongIntQuiet(reg: calcRegister_t, val: *mpz_struct, fractional: ?*bool) callconv(.c) c_int {
    var rval: real_t = undefined;
    var frac: bool = false;

    // C inits val exactly once per path: the dtLongInteger/dtShortInteger callees
    // init it themselves (mpz_init2 / mpz_init), and the real and default/error
    // paths init explicitly. The port hoisted a single mpz_init to the top, which
    // double-initialises val on the long/short paths — the callee's init then
    // overwrites _mp_d and leaks the first allocation. Mirror C's per-path init.
    switch (getRegisterDataType(reg)) {
        dtLongInteger => convertLongIntegerRegisterToLongInteger(reg, val),
        dtShortInteger => convertShortIntegerRegisterToLongInteger(reg, val),
        dtComplex34, dtReal34 => {
            if (getRegisterAsReal(reg, &rval)) {
                mpz_init(val); // convertRealToLongInteger expects an initialised val
                if (realIsSpecial(&rval)) {
                    return ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN;
                }
                if (!realIsAnInteger(&rval)) {
                    realToIntegralValue(&rval, &rval, DEC_ROUND_DOWN, &ctxtReal39);
                    frac = true;
                }
                convertRealToLongInteger(&rval, val, DEC_ROUND_DOWN);
            } else {
                mpz_init(val); // C falls through to default, which inits val
                return ERROR_INVALID_DATA_TYPE_FOR_OP;
            }
        },
        else => {
            mpz_init(val);
            return ERROR_INVALID_DATA_TYPE_FOR_OP;
        },
    }
    if (fractional) |f| {
        f.* = frac;
    }
    return ERROR_NONE;
}

pub export fn getRegisterAsLongInt(reg: calcRegister_t, val: *mpz_struct, fractional: ?*bool) callconv(.c) bool {
    const err = getRegisterAsLongIntQuiet(reg, val, fractional);
    if (err != ERROR_NONE) {
        frontier_error.displayCalcErrorMessage(@intCast(err), ERR_REGISTER_LINE, REGISTER_T);
    }
    return err == ERROR_NONE;
}

fn longIntegerAngleReduction(regist: calcRegister_t, angularMode: angularMode_t, reducedAngle: *real_t, reduceLongintegerAngle: bool) void {
    var oneTurn: u32 = undefined;
    var angle: mpz_struct = undefined;

    if (reduceLongintegerAngle) {
        switch (angularMode) {
            amMultPi => {
                oneTurn = 2;
            },
            amGrad => {
                oneTurn = 400;
            },
            amDegree, amDMS => {
                oneTurn = 360;
            },
            amRadian => {
                var reducedAngleTmpBuf: [REAL_2139_BYTES / 4]u32 align(4) = undefined;
                var reducedAngleTmp2Buf: [REAL_2139_BYTES / 4]u32 align(4) = undefined;
                const reducedAngleTmp: *real_t = @ptrCast(&reducedAngleTmpBuf);
                const reducedAngleTmp2: *real_t = @ptrCast(&reducedAngleTmp2Buf);
                var c: realContext_t = ctxtReal75;
                c.digits = 2139;
                convertLongIntegerRegisterToLongInteger(regist, &angle);

                if (longIntegerBase10Digits(&angle) > 1000) {
                    frontier_error.displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
                    moreInfoOnError("In function longIntegerAngleReduction:", "Invalid integer size for angle reduction in radians: exponent too large.");
                    mpz_clear(&angle);
                    return;
                }

                _ = mpz_get_str(tmpString, 10, &angle);
                _ = decNumberFromString(reducedAngleTmp, tmpString, &c);
                WP34S_Mod(reducedAngleTmp, const6147_2pi(), reducedAngleTmp2, &c);
                realPlus(reducedAngleTmp2, reducedAngle, &ctxtReal75);
                mpz_clear(&angle);
                return;
            },
            else => { // amNone
                convertLongIntegerRegisterToReal(regist, reducedAngle, &ctxtReal75);
                return;
            },
        }
    }

    if (reduceLongintegerAngle) {
        convertLongIntegerRegisterToLongInteger(regist, &angle);
        uInt32ToReal(longIntegerModuloUInt(&angle, oneTurn), reducedAngle);
        mpz_clear(&angle);
    } else {
        convertLongIntegerRegisterToReal(regist, reducedAngle, &ctxtReal39);
    }
}

inline fn longIntegerBase10Digits(op: *const mpz_struct) u32 {
    return @intCast(mpz_sizeinbase(op, 10));
}
inline fn longIntegerModuloUInt(op: *const mpz_struct, u: u32) u32 {
    return @truncate(mpz_fdiv_ui(op, u));
}

// REAL_SIZE_IN_BYTES(2139): REAL_MAX_DIGITS = ((2139+2)/6)*6+3 = 356*6+3 = 2139;
// REAL_SIZE_IN_BYTES = 10 + 2*(2139/3) = 10 + 2*713 = 1436; rounded to mult of 4.
const REAL_2139_BYTES: usize = blk: {
    const maxd = ((2139 + 2) / 6) * 6 + 3;
    break :blk 10 + 2 * (maxd / 3);
};

pub export fn getRegisterAsRealAngle(reg: calcRegister_t, val: *real_t, xAngularMode: *angularMode_t, reduceLongintegerAngle: bool) callconv(.c) bool {
    switch (getRegisterDataType(reg)) {
        dtLongInteger => {
            longIntegerAngleReduction(reg, currentAngularMode, val, reduceLongintegerAngle);
            xAngularMode.* = currentAngularMode;
        },
        dtShortInteger => {
            convertShortIntegerRegisterToReal(reg, val, &ctxtReal34);
            xAngularMode.* = currentAngularMode;
        },
        dtReal34 => {
            real34ToReal(reg34(reg), val);
            xAngularMode.* = getRegisterAngularMode(reg);
            if (xAngularMode.* == amNone) {
                xAngularMode.* = currentAngularMode;
            }
            if (xAngularMode.* == amRadian and realGetExponent(val) > 999) {
                frontier_error.displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
                moreInfoOnError("In function getRegisterAsRealAngle:", "Invalid real input size for angle reduction in radians: exponent too large.");
                return false;
            }
        },
        dtComplex34 => {
            if (real34IsZero(regImag34(reg))) {
                real34ToReal(reg34(reg), val);
                xAngularMode.* = amRadian;
            } else {
                badTypeError(reg);
                return false;
            }
        },
        else => {
            badTypeError(reg);
            return false;
        },
    }
    return true;
}

// ===========================================================================
// Monadic / dyadic dispatchers
// ===========================================================================
pub export fn processRealComplexMonadicFunction(realf: Fn0, complexf: Fn0) callconv(.c) void {
    processIntRealComplexMonadicFunction(realf, complexf, null, null);
}

pub export fn processIntRealComplexMonadicFunction(realf: Fn0, complexf: Fn0, shortintf: Fn0, longintf: Fn0) callconv(.c) void {
    var aReal: real_t = undefined;
    var aImag: real_t = undefined;
    var cmplxRes: bool = false;
    const t = getRegisterDataType(REGISTER_X);

    if (lastFunc != ITM_CHS and !saveLastX()) {
        return;
    }

    done: {
        if (t == dtShortInteger) {
            if (shortintf) |f| {
                f();
                break :done;
            }
            if (longintf) |f| {
                f();
                break :done;
            }
        }

        if (t == dtLongInteger and longintf != null) {
            longintf.?();
        } else if (t == dtReal34Matrix and realf != null) {
            elementwiseRema(realf);
        } else if (t == dtComplex34Matrix and complexf != null) {
            elementwiseCxma(complexf);
        } else if (getRegisterAsComplexOrReal(REGISTER_X, &aReal, &aImag, &cmplxRes)) {
            if (!cmplxRes and realf != null) {
                realf.?();
            } else if (complexf != null) {
                complexf.?();
            } else {
                badTypeErrorX();
            }
        }
    }

    adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}

pub export fn processRealComplexDyadicFunction(realf: Fn0, complexf: Fn0) callconv(.c) void {
    var xReal: real_t = undefined;
    var xImag: real_t = undefined;
    var yReal: real_t = undefined;
    var yImag: real_t = undefined;
    const typeX = getRegisterDataType(REGISTER_X);
    const typeY = getRegisterDataType(REGISTER_Y);
    var xCmplx: bool = false;
    var yCmplx: bool = false;
    var cmplxRes: bool = false;
    const xNumber = typeIsNumber(typeX, &xCmplx);
    const yNumber = typeIsNumber(typeY, &yCmplx);

    if (!saveLastX()) {
        return;
    }

    fin: {
        if (typeX == dtReal34Matrix and realf != null) {
            if (typeY == dtReal34Matrix) {
                elementwiseRemaRema(realf);
                break :fin;
            } else if (typeY == dtComplex34Matrix) {
                if (complexf != null) {
                    elementwiseCxmaRema(complexf);
                } else {
                    badTypeError(REGISTER_Y);
                }
                break :fin;
            } else if (yNumber) {
                if (yCmplx) {
                    if (complexf != null) {
                        elementwiseCplxRema(complexf);
                    } else {
                        badTypeError(REGISTER_Y);
                    }
                } else {
                    elementwiseRealRema(realf);
                }
                break :fin;
            }
        } else if (typeX == dtComplex34Matrix and complexf != null) {
            if (typeY == dtReal34Matrix) {
                elementwiseRemaCxma(complexf);
                break :fin;
            } else if (typeY == dtComplex34Matrix) {
                elementwiseCxmaCxma(complexf);
                break :fin;
            } else if (yNumber) {
                elementwiseCplxCxma(complexf);
                break :fin;
            }
        } else if (typeY == dtReal34Matrix and xNumber) {
            if (!xCmplx and realf != null) {
                elementwiseRemaReal(realf);
            } else if (complexf != null) {
                elementwiseRemaCplx(complexf);
            } else {
                badTypeErrorX();
            }
            break :fin;
        } else if (typeY == dtComplex34Matrix and xNumber) {
            elementwiseCxmaCplx(complexf);
            break :fin;
        }

        // Fall through to numeric/numeric or error if not
        if (!getRegisterAsComplexOrReal(REGISTER_X, &xReal, &xImag, &cmplxRes) or !getRegisterAsComplexOrReal(REGISTER_Y, &yReal, &yImag, &cmplxRes)) {
            return;
        }

        if (!cmplxRes and realf != null) {
            realf.?();
        } else if (complexf != null) {
            complexf.?();
        } else {
            badTypeError(if (xCmplx) REGISTER_X else REGISTER_Y);
        }
    }

    adjustResult(REGISTER_X, true, true, REGISTER_X, REGISTER_Y, -1);
}

pub export fn processIntRealComplexDyadicFunction(realf: Fn0, complexf: Fn0, shortintf: Fn0, longintf: Fn0) callconv(.c) void {
    const typeX = getRegisterDataType(REGISTER_X);
    const typeY = getRegisterDataType(REGISTER_Y);
    const xInt = typeX == dtLongInteger or typeX == dtShortInteger;
    const yInt = typeY == dtLongInteger or typeY == dtShortInteger;

    if (typeX == dtShortInteger and typeY == dtShortInteger and shortintf != null) {
        if (saveLastX()) {
            shortintf.?();
        }
    } else if (xInt and yInt and longintf != null) {
        if (saveLastX()) {
            longintf.?();
        }
    } else {
        processRealComplexDyadicFunction(realf, complexf);
        return;
    }
    adjustResult(REGISTER_X, true, true, REGISTER_X, REGISTER_Y, -1);
}

// bufPrintZ compat (std.fmt.bufPrintZ was removed upstream): removed in Zig 0.17 master; this form works in both
// pinned 0.16 and master (std.fmt.bufPrint + an explicit sentinel byte).
fn bufPrintZ(buf: []u8, comptime fmt: []const u8, args: anytype) ![:0]u8 {
    const s = try std.fmt.bufPrint(buf[0 .. buf.len - 1], fmt, args);
    buf[s.len] = 0;
    return buf[0..s.len :0];
}
