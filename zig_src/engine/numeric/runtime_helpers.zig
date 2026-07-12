// SPDX-License-Identifier: GPL-3.0-only
//! Zig owner for the math command wrapper runtime helper surface that used to
//! be provided to product builds by
//! zig_bridge/mathematics/math_wrappers_runtime_helpers.c (now parity-only,
//! relocated to zig_build/tests/math_wrappers/).
//!
//! Every `pub export` below keeps the exact symbol name and ABI of the retired
//! C definition. The error reporters live in
//! runtime_error_reporters.zig.

const std = @import("std");
const builtin = @import("builtin");
const runtime = @import("command_wrappers_runtime.zig");
const math_real_predicates = @import("real_predicates.zig");

const real_t = runtime.real_t;
const real34_t = runtime.real34_t;
const realContext_t = runtime.realContext_t;
const mpz_struct = runtime.mpz_struct;
const longInteger_t = runtime.longInteger_t;

// defines.h values (verified against src/c47/defines.h).
const MAX_FACTORIAL: u32 = 450; // defines.h line 482
const ERROR_MESSAGE_LENGTH: i32 = 512; // defines.h line 2362
const TMP_STR_LENGTH: usize = 2560; // defines.h
const SCREEN_WIDTH: i16 = 400; // defines.h line 1395

// ---------------------------------------------------------------------------
// decNumber / decQuad entry points. The upstream realXxx/real34Xxx names are
// macros (src/c47/realType.h), so the linkable decNumber symbols are used.
// real_t source pointers are declared align(1) because constant accessors can
// hand out pointers into the byte-packed generated `constants` blob.
// ---------------------------------------------------------------------------
extern fn decNumberFromInt32(result: *real_t, source: i32) *real_t;
extern fn decNumberNextToward(result: *real_t, x: *align(1) const real_t, y: *align(1) const real_t, set: *realContext_t) *real_t;
extern fn decNumberPower(result: *real_t, lhs: *align(1) const real_t, rhs: *align(1) const real_t, set: *realContext_t) *real_t;
extern fn decNumberAdd(result: *real_t, lhs: *align(1) const real_t, rhs: *align(1) const real_t, set: *realContext_t) *real_t;
// decQuadFromNumber is a macro over decimal128FromNumber (dep/decNumberICU/decQuad.h).
extern fn decimal128FromNumber(result: *real34_t, source: *align(1) const real_t, set: *realContext_t) *real34_t;
extern fn decQuadToIntegralValue(result: *real34_t, source: *const real34_t, set: *realContext_t, mode: c_int) *real34_t;
extern fn decQuadIsInfinite(value: *const real34_t) u32;
extern fn decQuadGetExponent(value: *const real34_t) i32;
extern fn decQuadNextPlus(result: *real34_t, source: *const real34_t, set: *realContext_t) *real34_t;
extern fn decQuadNextMinus(result: *real34_t, source: *const real34_t, set: *realContext_t) *real34_t;
extern fn decQuadSubtract(result: *real34_t, lhs: *const real34_t, rhs: *const real34_t, set: *realContext_t) *real34_t;

// Overflow-checked long integer arithmetic from src/c47/integers.c (linkable
// functions, unlike the longIntegerXxx static inlines).
extern fn longIntegerMultiply(op_y: *const mpz_struct, op_x: *const mpz_struct, result: *mpz_struct) void;
extern fn longIntegerSquare(op: *const mpz_struct, result: *mpz_struct) void;
extern fn longIntegerAdd(op_y: *const mpz_struct, op_x: *const mpz_struct, result: *mpz_struct) void;

// GMP entry points not present in the runtime module. Only the public
// __gmpz_* symbols link; mpz_* names are header macros.
extern fn __gmpz_init2(op: *mpz_struct, bits: c_ulong) void;
extern fn __gmpz_fib_ui(result: *mpz_struct, n: c_ulong) void;
extern fn __gmpz_fac_ui(result: *mpz_struct, n: c_ulong) void;

// Display helper and message buffers used by the EXTRA_INFO_ON_CALC_ERROR
// diagnostics (extern char * globals in the C core).
extern fn longIntegerRegisterToDisplayString(regist: runtime.calcRegister_t, display_string: [*]u8, str_lg: i32, max_width: i16, max_exp: i16, allow_largeli: bool) void;
extern var errorMessage: [*c]u8;
extern var tmpString: [*c]u8;

// ---------------------------------------------------------------------------
// Constant accessors.
//
// The generated constants blob (constantPointers.h / constantPointers.c) backs
// the accessors whose C implementation returned constantPointers.h macros in
// product builds. Offsets are byte offsets into `extern const uint8_t
// constants[]` and must match the generated constantPointers.h. align(1) is
// mandatory: the blob is a byte array (macOS alignment trap otherwise).
// ---------------------------------------------------------------------------
const abi = @import("abi");
const consts = abi.constants;
const constantPointer = consts.cstR;

// Byte offsets from the generated constantPointers.h.
const offset_const_1 = 4932; // const_1
const offset_const_2 = 5004; // const_2
const offset_const_3 = 5088; // const_3
const offset_const_5 = 5148; // const_5
const offset_const_1on2 = 4656; // const_1on2
const offset_const39_1on3 = 4620; // const39_1on3
const offset_const39_1oneE = 4464; // const39_1oneE
const offset_const_90 = 7620; // const_90
const offset_const_100 = 7608; // const_100
const offset_const_180 = 7536; // const_180
const offset_const39_ln2 = 4704; // const39_ln2
const offset_const39_ln10 = 5016; // const39_ln10
const offset_const39_PHI = 1596; // const39_PHI
const offset_const39_pi = 1848; // const39_pi
const offset_const39_piOn4 = 4812; // const39_piOn4
const offset_const39_piOn2 = 4956; // const39_piOn2
const offset_const39_3piOn4 = 5052; // const39_3piOn4
const offset_const39_3piOn2 = 5112; // const39_3piOn2
const offset_const75_pi = 7464; // const75_pi
const offset_const75_piOn2 = 7548; // const75_piOn2
const offset_const75_piOn4 = 7632; // const75_piOn4
const offset_const_3600 = 5524; // const_3600

// Constants synthesized locally rather than read from the constants blob; here
// they are comptime real_t values with fixed bit patterns.
fn makeConstant(exponent: i32, bits: u8, lsu0: u16) real_t {
    var value = std.mem.zeroes(real_t);
    value.digits = 1;
    value.exponent = exponent;
    value.bits = bits;
    value.lsu[0] = lsu0;
    return value;
}

const const_0_value = makeConstant(0, 0, 0);
const const_1_value = makeConstant(0, 0, 1);
const const_minus_1_value = makeConstant(0, 0x80, 1);
const const_2e6_value = makeConstant(6, 0, 2);
const const_plus_infinity_value = makeConstant(0, 0x40, 0);
const const_minus_infinity_value = makeConstant(0, 0xc0, 0);

pub export fn z47_math_wrappers_const_0() linksection(runtime.code_section) callconv(.c) *align(1) const real_t {
    return &const_0_value;
}

pub export fn z47_math_wrappers_const_1() linksection(runtime.code_section) callconv(.c) *align(1) const real_t {
    return &const_1_value;
}

pub export fn z47_math_wrappers_const_minus_1() linksection(runtime.code_section) callconv(.c) *align(1) const real_t {
    return &const_minus_1_value;
}

pub export fn z47_math_wrappers_const_2() linksection(runtime.code_section) callconv(.c) *align(1) const real_t {
    return constantPointer(offset_const_2);
}

pub export fn z47_math_wrappers_const_3() linksection(runtime.code_section) callconv(.c) *align(1) const real_t {
    return constantPointer(offset_const_3);
}

pub export fn z47_math_wrappers_const_5() linksection(runtime.code_section) callconv(.c) *align(1) const real_t {
    return constantPointer(offset_const_5);
}

pub export fn z47_math_wrappers_const_1on2() linksection(runtime.code_section) callconv(.c) *align(1) const real_t {
    return constantPointer(offset_const_1on2);
}

pub export fn z47_math_wrappers_const_1on3() linksection(runtime.code_section) callconv(.c) *align(1) const real_t {
    return constantPointer(offset_const39_1on3);
}

pub export fn z47_math_wrappers_const_2e6() linksection(runtime.code_section) callconv(.c) *align(1) const real_t {
    return &const_2e6_value;
}

pub export fn z47_math_wrappers_const_1oneE() linksection(runtime.code_section) callconv(.c) *align(1) const real_t {
    return constantPointer(offset_const39_1oneE);
}

pub export fn z47_math_wrappers_const_90() linksection(runtime.code_section) callconv(.c) *align(1) const real_t {
    return constantPointer(offset_const_90);
}

pub export fn z47_math_wrappers_const_100() linksection(runtime.code_section) callconv(.c) *align(1) const real_t {
    return constantPointer(offset_const_100);
}

pub export fn z47_math_wrappers_const_180() linksection(runtime.code_section) callconv(.c) *align(1) const real_t {
    return constantPointer(offset_const_180);
}

pub export fn z47_math_wrappers_const_ln2() linksection(runtime.code_section) callconv(.c) *align(1) const real_t {
    return constantPointer(offset_const39_ln2);
}

pub export fn z47_math_wrappers_const_ln10() linksection(runtime.code_section) callconv(.c) *align(1) const real_t {
    return constantPointer(offset_const39_ln10);
}

pub export fn z47_math_wrappers_const_phi() linksection(runtime.code_section) callconv(.c) *align(1) const real_t {
    return constantPointer(offset_const39_PHI);
}

pub export fn z47_math_wrappers_const_pi() linksection(runtime.code_section) callconv(.c) *align(1) const real_t {
    return constantPointer(offset_const39_pi);
}

pub export fn z47_math_wrappers_const_piOn4() linksection(runtime.code_section) callconv(.c) *align(1) const real_t {
    return constantPointer(offset_const39_piOn4);
}

pub export fn z47_math_wrappers_const_piOn2() linksection(runtime.code_section) callconv(.c) *align(1) const real_t {
    return constantPointer(offset_const39_piOn2);
}

pub export fn z47_math_wrappers_const_3piOn4() linksection(runtime.code_section) callconv(.c) *align(1) const real_t {
    return constantPointer(offset_const39_3piOn4);
}

pub export fn z47_math_wrappers_const_3piOn2() linksection(runtime.code_section) callconv(.c) *align(1) const real_t {
    return constantPointer(offset_const39_3piOn2);
}

pub export fn z47_math_wrappers_const75_pi() linksection(runtime.code_section) callconv(.c) *align(1) const real_t {
    return constantPointer(offset_const75_pi);
}

pub export fn z47_math_wrappers_const75_piOn2() linksection(runtime.code_section) callconv(.c) *align(1) const real_t {
    return constantPointer(offset_const75_piOn2);
}

pub export fn z47_math_wrappers_const75_piOn4() linksection(runtime.code_section) callconv(.c) *align(1) const real_t {
    return constantPointer(offset_const75_piOn4);
}

pub export fn z47_math_wrappers_const_3600() linksection(runtime.code_section) callconv(.c) *align(1) const real_t {
    return constantPointer(offset_const_3600);
}

pub export fn z47_math_wrappers_const_plus_infinity() linksection(runtime.code_section) callconv(.c) *align(1) const real_t {
    return &const_plus_infinity_value;
}

pub export fn z47_math_wrappers_const_minus_infinity() linksection(runtime.code_section) callconv(.c) *align(1) const real_t {
    return &const_minus_infinity_value;
}

// const_NaN global: the C file #undef'ed the constantPointers.h macro and
// published a pointer to a private NaN value initialized with realSetNaN
// (bits = DECNAN = 0x20, digits = 1, everything else zeroed).
const const_nan_value = makeConstant(0, 0x20, 0);
pub export var const_NaN: *const real_t = &const_nan_value;

// ---------------------------------------------------------------------------
// Thin linkable wrappers over decNumber/decQuad macros (Zig callers cannot
// expand C macros).
// ---------------------------------------------------------------------------
pub export fn int32ToReal(source: i32, destination: *real_t) linksection(runtime.code_section) callconv(.c) void {
    _ = decNumberFromInt32(destination, source);
}

pub export fn realNextToward(x: *align(1) const real_t, y: *align(1) const real_t, result: *real_t, real_context: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    _ = decNumberNextToward(result, x, y, real_context);
}

pub export fn realPower(base: *align(1) const real_t, exponent: *align(1) const real_t, result: *real_t, real_context: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    _ = decNumberPower(result, base, exponent, real_context);
}

pub export fn realToReal34(source: *align(1) const real_t, destination: *real34_t) linksection(runtime.code_section) callconv(.c) void {
    _ = decimal128FromNumber(destination, source, &runtime.ctxtReal34);
}

pub export fn real34ToIntegralValue(source: *const real34_t, destination: *real34_t, mode: runtime.rounding_t) linksection(runtime.code_section) callconv(.c) void {
    _ = decQuadToIntegralValue(destination, source, &runtime.ctxtReal34, mode);
}

pub export fn real34IsInfinite(value: *const real34_t) linksection(runtime.code_section) callconv(.c) bool {
    return decQuadIsInfinite(value) != 0;
}

pub export fn real34GetExponent(value: *const real34_t) linksection(runtime.code_section) callconv(.c) i32 {
    return decQuadGetExponent(value);
}

pub export fn real34NextPlus(source: *const real34_t, destination: *real34_t) linksection(runtime.code_section) callconv(.c) void {
    _ = decQuadNextPlus(destination, source, &runtime.ctxtReal34);
}

pub export fn real34NextMinus(source: *const real34_t, destination: *real34_t) linksection(runtime.code_section) callconv(.c) void {
    _ = decQuadNextMinus(destination, source, &runtime.ctxtReal34);
}

pub export fn real34Subtract(operand1: *const real34_t, operand2: *const real34_t, res: *real34_t) linksection(runtime.code_section) callconv(.c) void {
    _ = decQuadSubtract(res, operand1, operand2, &runtime.ctxtReal34);
}

// ---------------------------------------------------------------------------
// Complex helpers previously forwarded to the retained upstream copies of
// magnitude.c / conjugate.c; ported faithfully from those upstream sources.
// ---------------------------------------------------------------------------
pub export fn complexMagnitude2(a: *const real_t, b: *const real_t, c: *real_t, real_context: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    var t: real_t = undefined;

    runtime.realMultiply(a, a, &t, real_context);
    runtime.realFMA(b, b, &t, c, real_context);
}

pub export fn complexMagnitude(a: *const real_t, b: *const real_t, c: *real_t, real_context: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    var u: real_t = undefined;

    complexMagnitude2(a, b, &u, real_context);
    runtime.realSquareRoot(&u, c, real_context);
}

pub export fn conjCplx() linksection(runtime.code_section) callconv(.c) void {
    var r: real_t = undefined;
    var i: real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &r, &i)) {
        return;
    }

    runtime.realChangeSign(&i);
    if (runtime.realIsZero(&i) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.realSetPositiveSign(&i);
    }
    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtComplex34, 0, @intCast(runtime.amNone));
    runtime.convertComplexToResultRegister(&r, &i, runtime.REGISTER_X);
}

// ---------------------------------------------------------------------------
// Long integer inline helpers (src/c47/longIntegerType.h static inlines).
// ---------------------------------------------------------------------------
const longIntegerIsZero = math_real_predicates.longIntegerIsZero;

const longIntegerIsNegative = math_real_predicates.longIntegerIsNegative;

fn longIntegerSign(op: *const mpz_struct) i32 {
    if (op._mp_size < 0) {
        return -1;
    }
    return if (op._mp_size > 0) 1 else 0;
}

fn longIntegerSetPositiveSign(op: *mpz_struct) void {
    if (op._mp_size < 0) {
        op._mp_size = -op._mp_size;
    }
}

fn longIntegerChangeSign(op: *mpz_struct) void {
    op._mp_size = -op._mp_size;
}

fn longIntegerIsOdd(op: *const mpz_struct) bool {
    return op._mp_size != 0 and (op._mp_d[0] & 1) != 0;
}

// ---------------------------------------------------------------------------
// Helper API.
// ---------------------------------------------------------------------------
pub export fn z47_math_wrappers_log(value: f64) linksection(runtime.code_section) callconv(.c) f64 {
    return if (value > 0.0) value else 0.0;
}

fn longIntegerGcdChecked(li_y: *const mpz_struct, li_x: *const mpz_struct, li_a: *mpz_struct) linksection(runtime.code_section) void {
    if (longIntegerIsZero(li_y) and longIntegerIsZero(li_x)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        if (runtime.extra_info_on_calc_error) {
            runtime.moreInfoOnError("In function _longIntegerGcd:", "(0, 0) is not in the function domain.", null, null);
        }
    } else {
        runtime.__gmpz_gcd(li_a, li_y, li_x);
    }
}

pub export fn z47_math_wrappers_gcd_int() linksection(runtime.code_section) callconv(.c) void {
    var li_x: longInteger_t = undefined;
    var li_y: longInteger_t = undefined;
    var frac_x: bool = undefined;
    var frac_y: bool = undefined;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_Y, &li_y[0], &frac_y)) {
        runtime.__gmpz_clear(&li_y[0]);
        return;
    }
    defer runtime.__gmpz_clear(&li_y[0]);

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &li_x[0], &frac_x)) {
        runtime.__gmpz_clear(&li_x[0]);
        return;
    }
    defer runtime.__gmpz_clear(&li_x[0]);

    if (frac_x) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        return;
    }
    if (frac_y) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_Y);
        return;
    }

    longIntegerSetPositiveSign(&li_y[0]);
    longIntegerSetPositiveSign(&li_x[0]);
    longIntegerGcdChecked(&li_y[0], &li_x[0], &li_x[0]);
    runtime.convertLongIntegerToLongIntegerRegister(&li_x[0], runtime.REGISTER_X);
}

pub export fn z47_math_wrappers_gcd_short_integer() linksection(runtime.code_section) callconv(.c) void {
    const x_data = runtime.registerShortIntegerPtr(runtime.REGISTER_X);
    const y_value = runtime.registerShortIntegerPtr(runtime.REGISTER_Y).*;

    x_data.* = runtime.WP34S_intGCD(y_value, x_data.*);
}

pub export fn z47_math_wrappers_lcm_int() linksection(runtime.code_section) callconv(.c) void {
    var li_x: longInteger_t = undefined;
    var li_y: longInteger_t = undefined;
    var frac_x: bool = undefined;
    var frac_y: bool = undefined;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_Y, &li_y[0], &frac_y)) {
        runtime.__gmpz_clear(&li_y[0]);
        return;
    }
    defer runtime.__gmpz_clear(&li_y[0]);

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &li_x[0], &frac_x)) {
        runtime.__gmpz_clear(&li_x[0]);
        return;
    }
    defer runtime.__gmpz_clear(&li_x[0]);

    if (frac_x) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        return;
    }
    if (frac_y) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_Y);
        return;
    }

    longIntegerSetPositiveSign(&li_y[0]);
    longIntegerSetPositiveSign(&li_x[0]);
    runtime.__gmpz_lcm(&li_x[0], &li_y[0], &li_x[0]);
    runtime.convertLongIntegerToLongIntegerRegister(&li_x[0], runtime.REGISTER_X);
}

pub export fn z47_math_wrappers_lcm_short_integer() linksection(runtime.code_section) callconv(.c) void {
    const x_data = runtime.registerShortIntegerPtr(runtime.REGISTER_X);
    const y_value = runtime.registerShortIntegerPtr(runtime.REGISTER_Y).*;

    x_data.* = runtime.WP34S_intLCM(y_value, x_data.*);
}

pub export fn z47_math_wrappers_long_integer_fibonacci(n: u32, result: *mpz_struct) linksection(runtime.code_section) callconv(.c) void {
    __gmpz_fib_ui(result, n);
}

pub export fn z47_math_wrappers_fact_real() linksection(runtime.code_section) callconv(.c) void {
    var x: real_t = undefined;

    if (runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        runtime.WP34S_Factorial(&x, &x, &runtime.ctxtReal39);
        runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
    }
}

pub export fn z47_math_wrappers_fact_cplx() linksection(runtime.code_section) callconv(.c) void {
    var z_real: real_t = undefined;
    var z_imag: real_t = undefined;

    if (runtime.getRegisterAsComplex(runtime.REGISTER_X, &z_real, &z_imag)) {
        _ = decNumberAdd(&z_real, &z_real, constantPointer(offset_const_1), &runtime.ctxtReal39);
        runtime.WP34S_ComplexGamma(&z_real, &z_imag, &z_real, &z_imag, &runtime.ctxtReal39);
        runtime.convertComplexToResultRegister(&z_real, &z_imag, runtime.REGISTER_X);
    }
}

// EXTRA_INFO_ON_CALC_ERROR diagnostic shared by factLonI/factShoI: format the
// X register into the global errorMessage buffer, then build the message in
// the global tmpString buffer, like the upstream sprintf-based code. The
// string is assembled by hand to keep std.fmt out of the firmware image.
fn reportFactorialArgument(comptime function_name: [*:0]const u8) linksection(runtime.code_section) void {
    if (!runtime.extra_info_on_calc_error) {
        return;
    }

    longIntegerRegisterToDisplayString(runtime.REGISTER_X, errorMessage, ERROR_MESSAGE_LENGTH, SCREEN_WIDTH, 50, false);

    const prefix = "cannot calculate factorial(";
    @memcpy(tmpString[0..prefix.len], prefix);
    var length: usize = prefix.len;
    var i: usize = 0;
    while (errorMessage[i] != 0 and length < TMP_STR_LENGTH - 2) : (i += 1) {
        tmpString[length] = errorMessage[i];
        length += 1;
    }
    tmpString[length] = ')';
    tmpString[length + 1] = 0;
    runtime.moreInfoOnError(function_name, @ptrCast(tmpString), null, null);
}

// Preallocation size estimate used by the LINUX branch of factLonI
// (1 + (uint32_t)((n*log(n) - n) / log(2)) in the C source). The C cast is
// undefined for n < 2; lossyCast keeps the conversion well defined while the
// value only serves as an allocation hint for mpz_init2.
fn factorialPreallocationBits(n: u32) linksection(runtime.code_section) c_ulong {
    const nf: f64 = @floatFromInt(n);
    const estimate = (nf * @log(nf) - nf) / comptime @log(2.0);
    const bits = std.math.lossyCast(u32, estimate);
    return 1 +% bits;
}

pub export fn z47_math_wrappers_fact_long_integer() linksection(runtime.code_section) callconv(.c) void {
    var x: longInteger_t = undefined;
    var f: longInteger_t = undefined;

    runtime.convertLongIntegerRegisterToLongInteger(runtime.REGISTER_X, &x[0]);

    if (longIntegerIsNegative(&x[0])) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        reportFactorialArgument("In function factLonI:");
        runtime.__gmpz_clear(&x[0]);
        return;
    }

    if (runtime.__gmpz_cmp_ui(&x[0], MAX_FACTORIAL) > 0) {
        runtime.convertLongIntegerRegisterToReal34Register(runtime.REGISTER_X, runtime.REGISTER_X);
        runtime.__gmpz_clear(&x[0]);
        z47_math_wrappers_fact_real();
        return;
    }

    const n: u32 = @truncate(runtime.__gmpz_get_ui(&x[0]));
    if (builtin.os.tag == .linux) {
        __gmpz_init2(&f[0], factorialPreallocationBits(n));
        runtime.__gmpz_set_ui(&f[0], 1);
        var i: u32 = 2;
        while (i <= n) : (i += 1) {
            runtime.__gmpz_mul_ui(&f[0], &f[0], i);
        }
    } else {
        runtime.__gmpz_init(&f[0]);
        __gmpz_fac_ui(&f[0], n);
    }

    runtime.convertLongIntegerToLongIntegerRegister(&f[0], runtime.REGISTER_X);

    runtime.__gmpz_clear(&f[0]);
    runtime.__gmpz_clear(&x[0]);
}

// uint64 factorial kernel with C unsigned wraparound semantics.
fn factorialUInt64(value_in: u64) linksection(runtime.code_section) u64 {
    var value = value_in;

    if (value <= 1) {
        return 1;
    }

    var m = value;

    if ((value & 1) != 0) {
        m +%= value;
        value -= 1;
    }

    var result = m;
    value -= 2;
    while (value > 0) {
        m +%= value;
        result *%= m;
        value -= 2;
    }

    return result;
}

pub export fn z47_math_wrappers_fact_short_integer() linksection(runtime.code_section) callconv(.c) void {
    var sign: i16 = undefined;
    var value: u64 = undefined;

    runtime.convertShortIntegerRegisterToUInt64(runtime.REGISTER_X, &sign, &value);

    if (sign == 1) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        reportFactorialArgument("In function factShoI:");
        return;
    }

    if (value > 20) {
        runtime.displayCalcErrorMessage(runtime.ERROR_OUT_OF_RANGE, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        reportFactorialArgument("In function factShoI:");
        return;
    }

    const f = factorialUInt64(value);
    if (f > runtime.shortIntegerMask) {
        runtime.setSystemFlag(runtime.FLAG_OVERFLOW);
    }

    runtime.convertUInt64ToShortIntegerRegister(0, f, runtime.getRegisterTag(runtime.REGISTER_X), runtime.REGISTER_X);
}

pub export fn z47_math_wrappers_mod_long_integer() linksection(runtime.code_section) callconv(.c) void {
    var x: longInteger_t = undefined;
    var y: longInteger_t = undefined;
    var remainder: longInteger_t = undefined;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &x[0], null)) {
        runtime.__gmpz_clear(&x[0]);
        return;
    }
    defer runtime.__gmpz_clear(&x[0]);

    if (longIntegerIsZero(&x[0])) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        if (runtime.extra_info_on_calc_error) {
            runtime.moreInfoOnError("In function modLonI:", "cannot IDIVR a long integer by 0", null, null);
        }
        return;
    }

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_Y, &y[0], null)) {
        runtime.__gmpz_clear(&y[0]);
        return;
    }
    defer runtime.__gmpz_clear(&y[0]);

    runtime.__gmpz_init(&remainder[0]);
    defer runtime.__gmpz_clear(&remainder[0]);
    runtime.__gmpz_tdiv_r(&remainder[0], &y[0], &x[0]);
    longIntegerAdd(&remainder[0], &x[0], &remainder[0]);
    runtime.__gmpz_tdiv_r(&remainder[0], &remainder[0], &x[0]);

    runtime.convertLongIntegerToLongIntegerRegister(&remainder[0], runtime.REGISTER_X);
}

pub export fn z47_math_wrappers_mod_short_integer() linksection(runtime.code_section) callconv(.c) void {
    var x: longInteger_t = undefined;
    var y: longInteger_t = undefined;
    var remainder: longInteger_t = undefined;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &x[0], null)) {
        runtime.__gmpz_clear(&x[0]);
        return;
    }
    defer runtime.__gmpz_clear(&x[0]);

    if (longIntegerIsZero(&x[0])) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        if (runtime.extra_info_on_calc_error) {
            runtime.moreInfoOnError("In function modShoI:", "cannot IDIVR a short integer by 0", null, null);
        }
        return;
    }

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_Y, &y[0], null)) {
        runtime.__gmpz_clear(&y[0]);
        return;
    }
    defer runtime.__gmpz_clear(&y[0]);
    const base_y = runtime.getRegisterShortIntegerBase(runtime.REGISTER_Y);

    runtime.__gmpz_init(&remainder[0]);
    defer runtime.__gmpz_clear(&remainder[0]);
    runtime.__gmpz_tdiv_r(&remainder[0], &y[0], &x[0]);
    longIntegerAdd(&remainder[0], &x[0], &remainder[0]);
    runtime.__gmpz_tdiv_r(&remainder[0], &remainder[0], &x[0]);

    runtime.convertLongIntegerToShortIntegerRegister(&remainder[0], base_y, runtime.REGISTER_X);
}

pub export fn z47_math_wrappers_mod_real() linksection(runtime.code_section) callconv(.c) void {
    var x: real_t = undefined;
    var y: real_t = undefined;
    var r: real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x) or !runtime.getRegisterAsReal(runtime.REGISTER_Y, &y)) {
        return;
    }

    if (runtime.realIsZero(&x)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        if (runtime.extra_info_on_calc_error) {
            runtime.moreInfoOnError("In function modReal:", "cannot IDIVR a real34 by 0", null, null);
        }
        return;
    }

    runtime.WP34S_BigMod(&y, &x, &r, &runtime.ctxtReal39);
    if (!runtime.realIsZero(&r) and (y.bits & runtime.DECNEG) != (x.bits & runtime.DECNEG)) {
        runtime.realAdd(&r, &x, &r, &runtime.ctxtReal39);
    }

    runtime.convertRealToResultRegister(&r, runtime.REGISTER_X, runtime.amNone);
}

pub export fn z47_math_wrappers_rmd_long_integer() linksection(runtime.code_section) callconv(.c) void {
    var x: longInteger_t = undefined;
    var y: longInteger_t = undefined;
    var remainder: longInteger_t = undefined;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &x[0], null)) {
        runtime.__gmpz_clear(&x[0]);
        return;
    }
    defer runtime.__gmpz_clear(&x[0]);

    if (longIntegerIsZero(&x[0])) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        if (runtime.extra_info_on_calc_error) {
            runtime.moreInfoOnError("In function rmdLonI:", "cannot IDIVR a long integer by 0", null, null);
        }
        return;
    }

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_Y, &y[0], null)) {
        runtime.__gmpz_clear(&y[0]);
        return;
    }
    defer runtime.__gmpz_clear(&y[0]);

    runtime.__gmpz_init(&remainder[0]);
    defer runtime.__gmpz_clear(&remainder[0]);
    runtime.__gmpz_tdiv_r(&remainder[0], &y[0], &x[0]);

    runtime.convertLongIntegerToLongIntegerRegister(&remainder[0], runtime.REGISTER_X);
}

pub export fn z47_math_wrappers_rmd_short_integer() linksection(runtime.code_section) callconv(.c) void {
    var x: longInteger_t = undefined;
    var y: longInteger_t = undefined;
    var remainder: longInteger_t = undefined;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &x[0], null)) {
        runtime.__gmpz_clear(&x[0]);
        return;
    }
    defer runtime.__gmpz_clear(&x[0]);

    if (longIntegerIsZero(&x[0])) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        if (runtime.extra_info_on_calc_error) {
            runtime.moreInfoOnError("In function rmdShoI:", "cannot IDIVR a short integer by 0", null, null);
        }
        return;
    }

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_Y, &y[0], null)) {
        runtime.__gmpz_clear(&y[0]);
        return;
    }
    defer runtime.__gmpz_clear(&y[0]);
    const base_y = runtime.getRegisterShortIntegerBase(runtime.REGISTER_Y);

    runtime.__gmpz_init(&remainder[0]);
    defer runtime.__gmpz_clear(&remainder[0]);
    runtime.__gmpz_tdiv_r(&remainder[0], &y[0], &x[0]);

    runtime.convertLongIntegerToShortIntegerRegister(&remainder[0], base_y, runtime.REGISTER_X);
}

pub export fn z47_math_wrappers_rmd_real() linksection(runtime.code_section) callconv(.c) void {
    var x: real_t = undefined;
    var y: real_t = undefined;
    var r: real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x) or !runtime.getRegisterAsReal(runtime.REGISTER_Y, &y)) {
        return;
    }

    if (runtime.realIsZero(&x)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        if (runtime.extra_info_on_calc_error) {
            runtime.moreInfoOnError("In function rmdReal:", "cannot IDIVR a real34 by 0", null, null);
        }
        return;
    }

    runtime.WP34S_BigMod(&y, &x, &r, &runtime.ctxtReal39);
    runtime.convertRealToResultRegister(&r, runtime.REGISTER_X, runtime.amNone);
}

pub export fn z47_math_wrappers_neighb_short_integer() linksection(runtime.code_section) callconv(.c) void {
    var neg_x: bool = undefined;
    var neg_y: bool = undefined;
    var x: u64 = undefined;
    var y: u64 = undefined;

    if (runtime.getRegisterAsShortInt(runtime.REGISTER_X, &neg_x, &x, null, null) and
        runtime.getRegisterAsShortInt(runtime.REGISTER_Y, &neg_y, &y, null, null))
    {
        var subtract: bool = undefined;
        if (neg_x != neg_y) {
            subtract = neg_y;
        } else if (x == y) {
            return;
        } else if (neg_x) {
            subtract = y > x;
        } else {
            subtract = y < x;
        }

        const x_data = runtime.registerShortIntegerPtr(runtime.REGISTER_X);
        if (subtract) {
            x_data.* = runtime.WP34S_intSubtract(x_data.*, 1);
        } else {
            x_data.* = runtime.WP34S_intAdd(x_data.*, 1);
        }
    }
}

pub export fn z47_math_wrappers_neighb_long_integer() linksection(runtime.code_section) callconv(.c) void {
    var x: longInteger_t = undefined;
    var y: longInteger_t = undefined;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &x[0], null)) {
        runtime.__gmpz_clear(&x[0]);
        return;
    }
    defer runtime.__gmpz_clear(&x[0]);

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_Y, &y[0], null)) {
        runtime.__gmpz_clear(&y[0]);
        return;
    }
    defer runtime.__gmpz_clear(&y[0]);

    const cmp = runtime.__gmpz_cmp(&y[0], &x[0]);

    if (cmp != 0) {
        runtime.__gmpz_set_si(&y[0], if (cmp > 0) 1 else -1);
        longIntegerAdd(&x[0], &y[0], &x[0]);
    }
    runtime.convertLongIntegerToLongIntegerRegister(&x[0], runtime.REGISTER_X);
}

pub export fn z47_math_wrappers_neighb_real() linksection(runtime.code_section) callconv(.c) void {
    var x: real_t = undefined;
    var y: real_t = undefined;
    var x_angular_mode: runtime.angularMode_t = runtime.amNone;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x) or !runtime.getRegisterAsReal(runtime.REGISTER_Y, &y)) {
        return;
    }

    if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtReal34) {
        x_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_X);
    }

    realNextToward(&x, &y, &x, &runtime.ctxtReal34);
    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, x_angular_mode);
}

pub export fn z47_math_wrappers_build_sign_result(r: i32) linksection(runtime.code_section) callconv(.c) void {
    var lg_int: longInteger_t = undefined;

    runtime.__gmpz_init(&lg_int[0]);
    defer runtime.__gmpz_clear(&lg_int[0]);
    runtime.__gmpz_set_si(&lg_int[0], r);
    runtime.convertLongIntegerToLongIntegerRegister(&lg_int[0], runtime.REGISTER_X);
}

pub export fn z47_math_wrappers_change_sign_long_integer() linksection(runtime.code_section) callconv(.c) void {
    var x: longInteger_t = undefined;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &x[0], null)) {
        runtime.__gmpz_clear(&x[0]);
        return;
    }
    defer runtime.__gmpz_clear(&x[0]);

    longIntegerChangeSign(&x[0]);
    runtime.convertLongIntegerToLongIntegerRegister(&x[0], runtime.REGISTER_X);
}

pub export fn z47_math_wrappers_integer_part_long_integer() linksection(runtime.code_section) callconv(.c) void {
    var val: longInteger_t = undefined;
    const data_type = runtime.getRegisterDataType(runtime.REGISTER_X);

    if (runtime.getRegisterAsLongInt(runtime.REGISTER_X, &val[0], null)) {
        runtime.convertLongIntegerToLongIntegerRegister(&val[0], runtime.REGISTER_X);
        if (data_type == runtime.dtShortInteger) {
            runtime.setLastintegerBasetoZero();
        }
    }
    runtime.__gmpz_clear(&val[0]);
}

pub export fn z47_math_wrappers_integer_part_short_integer() linksection(runtime.code_section) callconv(.c) void {
    var sign: bool = undefined;
    var overflow: bool = undefined;
    var frac: bool = undefined;
    var val: u64 = undefined;

    if (!runtime.getRegisterAsShortInt(runtime.REGISTER_X, &sign, &val, &overflow, &frac)) {
        return;
    }
    if (runtime.getRegisterDataType(runtime.REGISTER_X) != runtime.dtShortInteger) {
        runtime.convertUInt64ToShortIntegerRegister(@intFromBool(sign), val, 10, runtime.REGISTER_X);
    }
    runtime.forceSystemFlag(@intCast(runtime.FLAG_CARRY), @intFromBool(frac));
    runtime.forceSystemFlag(@intCast(runtime.FLAG_OVERFLOW), @intFromBool(overflow));
}

pub export fn z47_math_wrappers_fractional_part_long_integer() linksection(runtime.code_section) callconv(.c) void {
    var x: longInteger_t = undefined;

    runtime.__gmpz_init(&x[0]);
    defer runtime.__gmpz_clear(&x[0]);
    runtime.convertLongIntegerToLongIntegerRegister(&x[0], runtime.REGISTER_X);
}

pub export fn z47_math_wrappers_fractional_part_short_integer() linksection(runtime.code_section) callconv(.c) void {
    var y: u64 = 0;

    if (runtime.shortIntegerMode == runtime.SIM_1COMPL or runtime.shortIntegerMode == runtime.SIM_SIGNMT) {
        const x = runtime.registerShortIntegerPtr(runtime.REGISTER_X).*;
        if ((x & runtime.shortIntegerSignBit) != 0) {
            y = if (runtime.shortIntegerMode == runtime.SIM_1COMPL) runtime.shortIntegerMask else runtime.shortIntegerSignBit;
        }
    }

    runtime.registerShortIntegerPtr(runtime.REGISTER_X).* = y;
}

pub export fn z47_math_wrappers_fractional_part_real() linksection(runtime.code_section) callconv(.c) void {
    var x: real34_t = undefined;
    const x_data = runtime.registerReal34Ptr(runtime.REGISTER_X);

    real34ToIntegralValue(x_data, &x, runtime.DEC_ROUND_DOWN);
    real34Subtract(x_data, &x, x_data);
}

pub export fn z47_math_wrappers_square_long_integer() linksection(runtime.code_section) callconv(.c) void {
    var lg_int: longInteger_t = undefined;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &lg_int[0], null)) {
        runtime.__gmpz_clear(&lg_int[0]);
        return;
    }
    defer runtime.__gmpz_clear(&lg_int[0]);

    longIntegerMultiply(&lg_int[0], &lg_int[0], &lg_int[0]);
    runtime.convertLongIntegerToLongIntegerRegister(&lg_int[0], runtime.REGISTER_X);
}

pub export fn z47_math_wrappers_cube_long_integer() linksection(runtime.code_section) callconv(.c) void {
    var x: longInteger_t = undefined;
    var c: longInteger_t = undefined;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &x[0], null)) {
        runtime.__gmpz_clear(&x[0]);
        return;
    }
    defer runtime.__gmpz_clear(&x[0]);

    runtime.__gmpz_init(&c[0]);
    defer runtime.__gmpz_clear(&c[0]);
    longIntegerMultiply(&x[0], &x[0], &c[0]);
    longIntegerMultiply(&c[0], &x[0], &c[0]);
    runtime.convertLongIntegerToLongIntegerRegister(&c[0], runtime.REGISTER_X);
}

pub export fn z47_math_wrappers_minus_one_power_long_integer() linksection(runtime.code_section) callconv(.c) void {
    var lg_int: longInteger_t = undefined;
    var exponent: longInteger_t = undefined;

    runtime.__gmpz_init(&lg_int[0]);
    defer runtime.__gmpz_clear(&lg_int[0]);
    runtime.__gmpz_set_ui(&lg_int[0], 1);

    runtime.convertLongIntegerRegisterToLongInteger(runtime.REGISTER_X, &exponent[0]);
    defer runtime.__gmpz_clear(&exponent[0]);
    if (longIntegerIsOdd(&exponent[0])) {
        longIntegerChangeSign(&lg_int[0]);
    }

    runtime.convertLongIntegerToLongIntegerRegister(&lg_int[0], runtime.REGISTER_X);
}

pub export fn z47_math_wrappers_small_base_power_long_integer(base_value: u32) linksection(runtime.code_section) callconv(.c) i32 {
    var base: longInteger_t = undefined;
    var exponent: longInteger_t = undefined;

    runtime.__gmpz_init(&base[0]);
    defer runtime.__gmpz_clear(&base[0]);
    runtime.__gmpz_set_ui(&base[0], base_value);
    runtime.convertLongIntegerRegisterToLongInteger(runtime.REGISTER_X, &exponent[0]);
    defer runtime.__gmpz_clear(&exponent[0]);

    longIntegerSetPositiveSign(&base[0]);

    const exponent_sign = longIntegerSign(&exponent[0]);
    longIntegerSetPositiveSign(&exponent[0]);

    if (longIntegerIsZero(&exponent[0])) {
        runtime.__gmpz_set_ui(&base[0], 1);
        runtime.convertLongIntegerToLongIntegerRegister(&base[0], runtime.REGISTER_X);
        return 1;
    } else if (exponent_sign == -1) {
        return -1;
    }

    var power: longInteger_t = undefined;

    runtime.__gmpz_init(&power[0]);
    defer runtime.__gmpz_clear(&power[0]);
    runtime.__gmpz_set_ui(&power[0], 1);

    while (!longIntegerIsZero(&exponent[0]) and runtime.lastErrorCode == 0) {
        if (longIntegerIsOdd(&exponent[0])) {
            longIntegerMultiply(&power[0], &base[0], &power[0]);
        }

        _ = runtime.__gmpz_tdiv_q_ui(&exponent[0], &exponent[0], 2);

        if (!longIntegerIsZero(&exponent[0])) {
            longIntegerSquare(&base[0], &base[0]);
        }
    }

    runtime.convertLongIntegerToLongIntegerRegister(&power[0], runtime.REGISTER_X);
    return 1;
}
