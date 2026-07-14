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
const abi = @import("abi"); // shared ABI bindings
const frontier_char_string = @import("display/text/char_string.zig");
const frontier_date_time = @import("convert/date_time.zig");
const frontier_debug = @import("debug.zig");
const frontier_display = @import("display/display.zig");
const frontier_error = @import("error.zig");
const frontier_integers = @import("convert/integers.zig");
const frontier_real_type = @import("real_type.zig");
const c_lconv = extern struct { decimal_point: [*c]u8 };
extern fn localeconv() *c_lconv;
extern fn strtod(s: [*c]const u8, endptr: ?*[*c]u8) f64;
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
// real34SetZero moved to engine/kernel/register_convert_bulk.zig.

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
// dataPtr moved to engine/kernel/register_convert_bulk.zig.
const reg34 = abi.registerReal34;
// regImag34 moved to engine/kernel/register_convert_bulk.zig.
// regLongIntData moved to engine/kernel/register_convert_bulk.zig.
const regShortInt = abi.registerShortInteger;
// regMatrixHeader moved to engine/kernel/register_convert_bulk.zig.
// regRealMatrixElems moved to engine/kernel/register_convert_bulk.zig.
// regComplexMatrixElems moved to engine/kernel/register_convert_bulk.zig.
// getRegisterAngularMode moved to engine/kernel/register_convert_bulk.zig.
inline fn getRegisterShortIntegerBase(reg: calcRegister_t) u32 {
    return getRegisterTag(reg);
}
inline fn getRegisterLongIntegerSign(reg: calcRegister_t) u32 {
    return getRegisterTag(reg);
}
// setComplexRegisterAngularMode moved to engine/kernel/register_convert_bulk.zig.
// setComplexRegisterPolarMode moved to engine/kernel/register_convert_bulk.zig.
const amNoneU: u32 = @bitCast(amNone);

// TO_BLOCKS / TO_BYTES
// toBlocks moved to engine/kernel/register_convert_bulk.zig.
inline fn toBytes(n: u16) u32 {
    return @as(u32, n) << 2;
}

// long integer helpers.
// longIntegerSizeInBytes moved to engine/kernel/register_convert_bulk.zig.
// longIntegerSignTag moved to engine/kernel/register_convert_bulk.zig.
inline fn longIntegerIsNegative(lg: *const mpz_struct) bool {
    return lg._mp_size < 0;
}
inline fn longIntegerIsZero(lg: *const mpz_struct) bool {
    return lg._mp_size == 0;
}
// longIntegerChangeSign moved to engine/kernel/register_convert_bulk.zig.
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
// realIsNaN moved to engine/kernel/register_convert_bulk.zig.
// realIsNegative moved to engine/kernel/register_convert_bulk.zig.
// realIsPositive moved to engine/kernel/register_convert_bulk.zig.
// realIsSpecial moved to engine/kernel/register_convert_bulk.zig.
// realIsZero moved to engine/kernel/register_convert_bulk.zig.
// realSetPositiveSign moved to engine/kernel/register_convert_bulk.zig.
inline fn realSetNegativeSign(v: *real_t) void {
    v.bits |= 0x80;
}
// realGetExponent moved to engine/kernel/register_convert_bulk.zig.

// real34 ops (use &ctxtReal34).
inline fn uInt32ToReal34(src: u32, dst: *real34_t) void {
    _ = decQuadFromUInt32(dst, src);
}
inline fn int32ToReal34(src: i32, dst: *real34_t) void {
    _ = decQuadFromInt32(dst, src);
}
// real34FMA moved to engine/kernel/register_convert_bulk.zig.
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
// real34GetCoefficient moved to engine/kernel/register_convert_bulk.zig.
// real34GetExponent moved to engine/kernel/register_convert_bulk.zig.
inline fn real34ToInt32(src: *align(1) const real34_t) i32 {
    return decQuadToInt32(src, &ctxtReal34, DEC_ROUND_DOWN);
}
// real34ToReal moved to engine/kernel/register_convert_bulk.zig.
// stringToReal34 moved to engine/kernel/register_convert_bulk.zig.

// real ops.
// uInt32ToReal moved to engine/kernel/register_convert_bulk.zig.
inline fn realFMA(f1: *align(1) const real_t, f2: *align(1) const real_t, term: *align(1) const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberFMA(res, f1, f2, term, ctx);
}
// realGetCoefficient moved to engine/kernel/register_convert_bulk.zig.
// realPlus moved to engine/kernel/register_convert_bulk.zig.
// stringToReal moved to engine/kernel/register_convert_bulk.zig.

// ===========================================================================
// Long integer <-> register
// ===========================================================================
// convertLongIntegerToLongIntegerRegister moved to engine/kernel/register_convert_bulk.zig.
pub extern fn convertLongIntegerToLongIntegerRegister(lgInt: *const mpz_struct, regist: calcRegister_t) callconv(.c) void;

// convertLongIntegerRegisterToLongInteger moved to engine/kernel/register_integer_convert.zig.
pub extern fn convertLongIntegerRegisterToLongInteger(regist: calcRegister_t, lgInt: *mpz_struct) callconv(.c) void;

// convertLongIntegerRegisterToReal34Register moved to engine/kernel/register_convert_bulk.zig.
pub extern fn convertLongIntegerRegisterToReal34Register(source: calcRegister_t, destination: calcRegister_t) callconv(.c) void;

// convertLongIntegerRegisterToReal34 moved to engine/kernel/register_convert_bulk.zig.
pub extern fn convertLongIntegerRegisterToReal34(source: calcRegister_t, destination: *real34_t) callconv(.c) void;

// convertLongIntegerRegisterToReal moved to engine/kernel/register_integer_convert.zig.
pub extern fn convertLongIntegerRegisterToReal(source: calcRegister_t, destination: *real_t, ctxt: *realContext_t) callconv(.c) void;

// convertLongIntegerToReal moved to engine/kernel/register_integer_convert.zig.

// convertLongIntegerToReal34 moved to engine/kernel/register_convert_bulk.zig.
pub extern fn convertLongIntegerToReal34(source: *mpz_struct, destination: *real34_t) callconv(.c) void;

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
// convertShortIntegerRegisterToReal34Register moved to engine/kernel/register_convert_bulk.zig.
pub extern fn convertShortIntegerRegisterToReal34Register(source: calcRegister_t, destination: calcRegister_t) callconv(.c) void;

// convertShortIntegerRegisterToReal moved to engine/kernel/register_integer_convert.zig.
pub extern fn convertShortIntegerRegisterToReal(source: calcRegister_t, destination: *real_t, ctxt: *realContext_t) callconv(.c) void;

// convertShortIntegerRegisterToUInt64 moved to engine/kernel/register_integer_convert.zig.
pub extern fn convertShortIntegerRegisterToUInt64(regist: calcRegister_t, sign: *i16, value: *u64) callconv(.c) void;

// convertShortIntegerRegisterToLongInteger moved to engine/kernel/register_convert_bulk.zig.
pub extern fn convertShortIntegerRegisterToLongInteger(source: calcRegister_t, lgInt: *mpz_struct) callconv(.c) void;

// convertShortIntegerRegisterToLongIntegerRegister moved to engine/kernel/register_convert_bulk.zig.
pub extern fn convertShortIntegerRegisterToLongIntegerRegister(source: calcRegister_t, destination: calcRegister_t) callconv(.c) void;

// convertUInt64ToShortIntegerRegister moved to engine/kernel/register_convert_bulk.zig.
pub extern fn convertUInt64ToShortIntegerRegister(sign: i16, value_arg: u64, base: u32, regist: calcRegister_t) callconv(.c) void;

// ===========================================================================
// real34 / real <-> long integer
// ===========================================================================
// convertReal34ToLongInteger moved to engine/kernel/register_convert_bulk.zig.
pub extern fn convertReal34ToLongInteger(re34: *align(1) const real34_t, lgInt: *mpz_struct, roundingMode: c_int) callconv(.c) void;

// convertReal34ToLongIntegerRegister moved to engine/kernel/register_convert_bulk.zig.
pub extern fn convertReal34ToLongIntegerRegister(real34: *align(1) const real34_t, dest: calcRegister_t, roundingMode: c_int) callconv(.c) void;

// convertRealToLongInteger moved to engine/kernel/register_convert_bulk.zig.
pub extern fn convertRealToLongInteger(re: *const real_t, lgInt: *mpz_struct, roundingMode: c_int) callconv(.c) void;

// convertRealToLongIntegerRegister moved to engine/kernel/register_convert_bulk.zig.
pub extern fn convertRealToLongIntegerRegister(real: *const real_t, dest: calcRegister_t, roundingMode: c_int) callconv(.c) void;

// Moved to the base kernel (engine/kernel/register_real34_convert.zig).
pub extern fn realToIntegralValue(source: *const real_t, destination: *real_t, mode: c_int, realContext: *realContext_t) callconv(.c) void;

// ===========================================================================
// real result registers
// ===========================================================================
// Moved to the base kernel (engine/kernel/register_real34_convert.zig); the shell
// owners that reach it through this module resolve it via this re-declaration.
pub extern fn convertRealToReal34ResultRegister(real: *const real_t, dest: calcRegister_t) callconv(.c) void;

// convertRealToImag34ResultRegister moved to engine/kernel/register_convert_bulk.zig.
pub extern fn convertRealToImag34ResultRegister(real: *const real_t, dest: calcRegister_t) callconv(.c) void;

// realToReal34 moved to engine/kernel/register_convert_bulk.zig.

// Moved to the base kernel (engine/kernel/register_real34_convert.zig).
pub extern fn convertRealToResultRegister(x: *const real_t, dest: calcRegister_t, angle: angularMode_t) callconv(.c) void;

// convertComplexToResultRegister moved to engine/kernel/register_convert_bulk.zig.
pub extern fn convertComplexToResultRegister(real: *const real_t, imag: *const real_t, dest: calcRegister_t) callconv(.c) void;

// convertComplexToResultRegisterRPangle moved to engine/kernel/register_convert_bulk.zig.
pub extern fn convertComplexToResultRegisterRPangle(real: *const real_t, imag: *const real_t, dest: calcRegister_t, angl: angularMode_t, polarTag: u8) callconv(.c) void;

// ===========================================================================
// Time / Date
// ===========================================================================
// convertTimeRegisterToReal34Register moved to engine/kernel/register_convert_bulk.zig.
pub extern fn convertTimeRegisterToReal34Register(source: calcRegister_t, destination: calcRegister_t) callconv(.c) void;

// convertReal34RegisterToTimeRegister moved to engine/kernel/register_convert_bulk.zig.
pub extern fn convertReal34RegisterToTimeRegister(source: calcRegister_t, destination: calcRegister_t) callconv(.c) void;

// convertLongIntegerRegisterToTimeRegister moved to engine/kernel/register_convert_bulk.zig.
pub extern fn convertLongIntegerRegisterToTimeRegister(source: calcRegister_t, destination: calcRegister_t) callconv(.c) void;

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
// convertReal34MatrixRegisterToReal34Matrix moved to engine/kernel/register_convert_bulk.zig.
pub extern fn convertReal34MatrixRegisterToReal34Matrix(regist: calcRegister_t, matrix: *real34Matrix_t) callconv(.c) void;

// convertReal34MatrixToReal34MatrixRegister moved to engine/kernel/register_convert_bulk.zig.
pub extern fn convertReal34MatrixToReal34MatrixRegister(matrix: *const real34Matrix_t, regist: calcRegister_t) callconv(.c) void;

// convertComplex34MatrixRegisterToComplex34Matrix moved to engine/kernel/register_convert_bulk.zig.
pub extern fn convertComplex34MatrixRegisterToComplex34Matrix(regist: calcRegister_t, matrix: *complex34Matrix_t) callconv(.c) void;

// convertComplex34MatrixToComplex34MatrixRegister moved to engine/kernel/register_convert_bulk.zig.
pub extern fn convertComplex34MatrixToComplex34MatrixRegister(matrix: *const complex34Matrix_t, regist: calcRegister_t) callconv(.c) void;

// convertReal34MatrixToComplex34Matrix moved to engine/kernel/register_convert_bulk.zig.
pub extern fn convertReal34MatrixToComplex34Matrix(source: *const real34Matrix_t, destination: *complex34Matrix_t) callconv(.c) void;

// convertReal34MatrixRegisterToComplex34Matrix moved to engine/kernel/register_convert_bulk.zig.
pub extern fn convertReal34MatrixRegisterToComplex34Matrix(source: calcRegister_t, destination: *complex34Matrix_t) callconv(.c) void;

// convertReal34MatrixRegisterToComplex34MatrixRegister moved to engine/kernel/register_convert_bulk.zig.
pub extern fn convertReal34MatrixRegisterToComplex34MatrixRegister(source: calcRegister_t, destination: calcRegister_t) callconv(.c) void;

// ===========================================================================
// Doubles and floats
// ===========================================================================
// sci_fmt moved to engine/kernel/register_convert_bulk.zig.
pub extern fn sci_fmt(buf: [*c]u8, n: c_int, x_arg: f64) callconv(.c) void;

// convertDoubleToString moved to engine/kernel/register_convert_bulk.zig.
pub extern fn convertDoubleToString(x: f64, n: i16, buff: [*c]u8) callconv(.c) void;

// convertDoubleToReal moved to engine/kernel/register_convert_bulk.zig.
pub extern fn convertDoubleToReal(x: f64, destination: *real_t, ctxt: *realContext_t) callconv(.c) void;

// convertDoubleToReal34Register moved to engine/kernel/register_convert_bulk.zig.
pub extern fn convertDoubleToReal34Register(x: f64, destination: calcRegister_t) callconv(.c) void;

// convertDoubleToReal34RegisterPush moved to engine/kernel/register_convert_bulk.zig.
pub extern fn convertDoubleToReal34RegisterPush(x: f64, destination: calcRegister_t) callconv(.c) void;

// convertRegisterToDouble moved to engine/kernel/register_convert_bulk.zig.
pub extern fn convertRegisterToDouble(regist: calcRegister_t) callconv(.c) f64;

// exps moved to engine/kernel/register_convert_bulk.zig.

// fnRealToFloat moved to engine/kernel/register_convert_bulk.zig.

// makeNanF32 moved to engine/kernel/register_convert_bulk.zig.
// makeInfF32 moved to engine/kernel/register_convert_bulk.zig.

// realToFloat moved to engine/kernel/register_convert_bulk.zig.
pub extern fn realToFloat(vv: *const real_t, v: *f32) callconv(.c) void;

// fnRealToDouble moved to engine/kernel/register_convert_bulk.zig.

// Locale-free strtod: normalise '.'/',' to the locale radix, then strtod.
// (Ports registerValueConversions.c stringToDouble; used by the save-state
// float->real migration path.)
// stringToDouble moved to engine/kernel/register_convert_bulk.zig.
pub extern fn stringToDouble(str: [*c]const u8) callconv(.c) f64;

// realToDouble moved to engine/kernel/register_convert_bulk.zig.
pub extern fn realToDouble(vv: *const real_t, v: *f64) callconv(.c) void;

// ===========================================================================
// Type checks / error helpers
// ===========================================================================
// typeIsNumber moved to engine/kernel/register_convert_bulk.zig.

// badTypeError moved to engine/kernel/register_integer_convert.zig.
pub extern fn badTypeError(reg: calcRegister_t) callconv(.c) void;

// Shell implementation of the host bad-register-type diagnostic hook: append the
// human-readable register data-type name to the error report. Debug-only
// (extra_info builds); the type-name table and info line are shell-owned.
pub export fn reportBadTypeDetail(reg: calcRegister_t) callconv(.c) void {
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

// badDomainError moved to engine/kernel/register_convert_bulk.zig.
pub extern fn badDomainError(reg: calcRegister_t) callconv(.c) void;

// badTypeErrorX moved to engine/kernel/register_convert_bulk.zig.
pub extern fn badTypeErrorX() callconv(.c) void;

// badDomainErrorX moved to engine/kernel/register_convert_bulk.zig.
pub extern fn badDomainErrorX() callconv(.c) void;

// ===========================================================================
// getRegisterAs* family
// ===========================================================================
// getRegisterAsComplex moved to engine/kernel/register_convert_bulk.zig.
pub extern fn getRegisterAsComplex(reg: calcRegister_t, r: *real_t, i: *real_t) callconv(.c) bool;

// getRegisterAsComplexOrAnyRealQuiet moved to engine/kernel/register_convert_bulk.zig.
pub extern fn getRegisterAsComplexOrAnyRealQuiet(reg: calcRegister_t, r: *real_t, i: *real_t, cmplx: ?*bool) callconv(.c) bool;

// getRegisterAsComplexOrAnyReal moved to engine/kernel/register_convert_bulk.zig.
pub extern fn getRegisterAsComplexOrAnyReal(reg: calcRegister_t, r: *real_t, i: *real_t, cmplx: ?*bool) callconv(.c) bool;

// getRegisterAsComplexOrRealQuiet moved to engine/kernel/register_convert_bulk.zig.
pub extern fn getRegisterAsComplexOrRealQuiet(reg: calcRegister_t, r: *real_t, i: *real_t, cmplx: ?*bool) callconv(.c) bool;

// getRegisterAsComplexOrReal moved to engine/kernel/register_convert_bulk.zig.
pub extern fn getRegisterAsComplexOrReal(reg: calcRegister_t, r: *real_t, i: *real_t, cmplx: ?*bool) callconv(.c) bool;

// getRegisterAsAnyRealQuiet moved to engine/kernel/register_integer_convert.zig.
pub extern fn getRegisterAsAnyRealQuiet(reg: calcRegister_t, val: *real_t) callconv(.c) bool;

// convertComplexRegisterToRealIfZeroImag moved to engine/kernel/register_convert_bulk.zig.
pub extern fn convertComplexRegisterToRealIfZeroImag(regist: calcRegister_t) callconv(.c) void;

inline fn real34IsZero(v: *align(1) const real34_t) bool {
    return decQuadIsZero(v) != 0;
}
extern fn decQuadIsZero(v: *align(1) const real34_t) u32;

// getRegisterAsRealQuiet moved to engine/kernel/register_integer_convert.zig.
pub extern fn getRegisterAsRealQuiet(reg: calcRegister_t, val: *real_t) callconv(.c) bool;

// getRegisterAsReal moved to engine/kernel/register_integer_convert.zig.
pub extern fn getRegisterAsReal(reg: calcRegister_t, val: *real_t) callconv(.c) bool;

// getRegisterAsAnyReal moved to engine/kernel/register_convert_bulk.zig.
pub extern fn getRegisterAsAnyReal(reg: calcRegister_t, val: *real_t) callconv(.c) bool;

// getRegisterAsReal34Quiet moved to engine/kernel/register_convert_bulk.zig.
pub extern fn getRegisterAsReal34Quiet(reg: calcRegister_t, val: *real34_t) callconv(.c) bool;

// getRegisterAsShortInt moved to engine/kernel/register_convert_bulk.zig.
pub extern fn getRegisterAsShortInt(reg: calcRegister_t, sign: *bool, val: *u64, overflow: ?*bool, fractional: ?*bool) callconv(.c) bool;

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

// getRegisterAsLongIntQuiet moved to engine/kernel/register_convert_bulk.zig.
pub extern fn getRegisterAsLongIntQuiet(reg: calcRegister_t, val: *mpz_struct, fractional: ?*bool) callconv(.c) c_int;

// getRegisterAsLongInt moved to engine/kernel/register_convert_bulk.zig.
pub extern fn getRegisterAsLongInt(reg: calcRegister_t, val: *mpz_struct, fractional: ?*bool) callconv(.c) bool;

// longIntegerAngleReduction moved to engine/kernel/register_convert_bulk.zig.

// longIntegerBase10Digits moved to engine/kernel/register_convert_bulk.zig.
// longIntegerModuloUInt moved to engine/kernel/register_convert_bulk.zig.

// REAL_SIZE_IN_BYTES(2139): REAL_MAX_DIGITS = ((2139+2)/6)*6+3 = 356*6+3 = 2139;
// REAL_SIZE_IN_BYTES = 10 + 2*(2139/3) = 10 + 2*713 = 1436; rounded to mult of 4.
// REAL_2139_BYTES moved to engine/kernel/register_convert_bulk.zig.

// getRegisterAsRealAngle moved to engine/kernel/register_convert_bulk.zig.
pub extern fn getRegisterAsRealAngle(reg: calcRegister_t, val: *real_t, xAngularMode: *angularMode_t, reduceLongintegerAngle: bool) callconv(.c) bool;

// ===========================================================================
// Monadic / dyadic dispatchers
// ===========================================================================
// processRealComplexMonadicFunction moved to engine/kernel/register_convert_bulk.zig.
pub extern fn processRealComplexMonadicFunction(realf: Fn0, complexf: Fn0) callconv(.c) void;

// processIntRealComplexMonadicFunction moved to engine/kernel/register_convert_bulk.zig.
pub extern fn processIntRealComplexMonadicFunction(realf: Fn0, complexf: Fn0, shortintf: Fn0, longintf: Fn0) callconv(.c) void;

// processRealComplexDyadicFunction moved to engine/kernel/register_convert_bulk.zig.
pub extern fn processRealComplexDyadicFunction(realf: Fn0, complexf: Fn0) callconv(.c) void;

// processIntRealComplexDyadicFunction moved to engine/kernel/register_convert_bulk.zig.
pub extern fn processIntRealComplexDyadicFunction(realf: Fn0, complexf: Fn0, shortintf: Fn0, longintf: Fn0) callconv(.c) void;

// bufPrintZ compat (std.fmt.bufPrintZ was removed upstream): removed in Zig 0.17 master; this form works in both
// pinned 0.16 and master (std.fmt.bufPrint + an explicit sentinel byte).
fn bufPrintZ(buf: []u8, comptime fmt: []const u8, args: anytype) ![:0]u8 {
    const s = try std.fmt.bufPrint(buf[0 .. buf.len - 1], fmt, args);
    buf[s.len] = 0;
    return buf[0..s.len :0];
}
