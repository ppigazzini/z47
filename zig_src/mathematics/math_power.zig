// SPDX-License-Identifier: GPL-3.0-only
const abi = @import("abi");
const consts = abi.constants;
const const_4 = consts.const_4;
const const_8 = consts.const_8;
//
// Zig owner for src/c47/mathematics/power.c: the y^x POWER command, real /
// complex / short-integer / long-integer, plus the exported helpers PowerReal,
// PowerComplex and longIntegerPower (used cross-domain). Faithful line-by-line
// translation preserving the exact order of every real_t / mpz operation
// (power_real / power_complex / power_longInteger / square / cube tests check
// results to the last ULP). The static powReal / powCplx / powShoI / powLonI
// helpers stay private; PowerReal / PowerComplex / longIntegerPower / fnPower
// keep C linkage. The EXTRA_INFO_ON_CALC_ERROR sprintf hints become fixed
// moreInfoOnError strings (no-op under TESTSUITE / DMCP). The PC_BUILD
// fflush(stdout) has no calculation effect and is omitted.

const runtime = @import("math_command_wrappers_runtime.zig");
const math_command_wrappers = @import("math_command_wrappers.zig"); // M-callconv: Zig-to-Zig
const math_comparison_reals = @import("math_comparison_reals.zig"); // M-callconv: Zig-to-Zig

const math_real_predicates = @import("math_real_predicates.zig");
const real_t = runtime.real_t;
const realContext_t = runtime.realContext_t;

const realMultiply = runtime.realMultiply;
const realDivide = runtime.realDivide;
const realFMA = runtime.realFMA;
const realIsZero = runtime.realIsZero;
const realIsNaN = runtime.realIsNaN;
const realIsNegative = runtime.realIsNegative;
const realIsInfinite = runtime.realIsInfinite;
const realIsAnInteger = runtime.realIsAnInteger;
const realSetNaN = runtime.realSetNaN;
const realSetZero = runtime.realSetZero;
const realChangeSign = runtime.realChangeSign;
const realToInt32C47 = runtime.realToInt32C47;
const realRectangularToPolar = runtime.realRectangularToPolar;
const realPolarToRectangular = runtime.realPolarToRectangular;
const realSetPositiveSign = runtime.realSetPositiveSign;

const WP34S_Ln = runtime.WP34S_Ln;
const WP34S_Mod = runtime.WP34S_Mod;

const REGISTER_X = runtime.REGISTER_X;
const REGISTER_Y = runtime.REGISTER_Y;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN = runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN;
const ERROR_NONE: u8 = 0;
const amNone = runtime.amNone;
const FLAG_CPXRES: u16 = 0x8004;

const displayCalcErrorMessage = runtime.displayCalcErrorMessage;
const moreInfoOnError = runtime.moreInfoOnError;

inline fn const_1() *const real_t {
    return runtime.z47_math_wrappers_const_1();
}
inline fn const_2() *const real_t {
    return runtime.z47_math_wrappers_const_2();
}
inline fn const_plusInfinity() *const real_t {
    return runtime.z47_math_wrappers_const_plus_infinity();
}
inline fn const_minusInfinity() *const real_t {
    return runtime.z47_math_wrappers_const_minus_infinity();
}

// Blob-offset constants without a runtime accessor.

// real ops / predicates / copy. Some are C macros; reproduce them.
extern fn realSetPlusInfinity(value: *real_t) void;
extern fn decNumberCopy(res: *real_t, source: *const real_t) *real_t;
extern fn decNumberCopyAbs(res: *real_t, source: *const real_t) *real_t;
extern fn decNumberRemainder(res: *real_t, lhs: *align(1) const real_t, rhs: *align(1) const real_t, ctxt: *realContext_t) *real_t;
inline fn realCopy(source: *const real_t, destination: *real_t) void {
    _ = decNumberCopy(destination, source);
}
inline fn realCopyAbs(source: *const real_t, destination: *real_t) void {
    _ = decNumberCopyAbs(destination, source);
}
inline fn realDivideRemainder(operand1: *align(1) const real_t, operand2: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberRemainder(res, operand1, operand2, ctxt);
}
const realIsPositive = math_real_predicates.realIsPositive;

// ---------------------------------------------------------------------------
// GMP long integer (mpz). Limb width == pointer width on every z47 target.
// ---------------------------------------------------------------------------
const mp_limb_t = usize;
const mpz_struct = abi.Mpz;

extern fn __gmpz_init(op: *mpz_struct) void;
extern fn __gmpz_clear(op: *mpz_struct) void;
extern fn __gmpz_set(rop: *mpz_struct, op: *const mpz_struct) void;
extern fn __gmpz_set_ui(rop: *mpz_struct, op: c_ulong) void;
extern fn __gmpz_cmp_si(op: *const mpz_struct, v: c_long) c_int;
extern fn __gmpz_fdiv_q_2exp(q: *mpz_struct, n: *const mpz_struct, b: c_ulong) void;

// Overflow-guarded long-integer operators (integers owner).
extern fn longIntegerMultiply(opY: *mpz_struct, opX: *mpz_struct, result: *mpz_struct) void;
extern fn longIntegerSquare(op: *mpz_struct, result: *mpz_struct) void;

inline fn longIntegerInit(op: *mpz_struct) void {
    __gmpz_init(op);
}
inline fn longIntegerFree(op: *mpz_struct) void {
    __gmpz_clear(op);
}
inline fn longIntegerCopy(source: *const mpz_struct, destination: *mpz_struct) void {
    __gmpz_set(destination, source);
}
inline fn uInt32ToLongInteger(source: u32, destination: *mpz_struct) void {
    __gmpz_set_ui(destination, source);
}
const longIntegerIsZero = math_real_predicates.longIntegerIsZero;
const longIntegerIsNegative = math_real_predicates.longIntegerIsNegative;
inline fn longIntegerIsOdd(op: *const mpz_struct) bool {
    return op._mp_size != 0 and (op._mp_d[0] & 1) != 0;
}
inline fn longIntegerCompareInt(op: *const mpz_struct, sint: i32) i32 {
    return __gmpz_cmp_si(op, sint);
}
inline fn longIntegerDivide2(op: *const mpz_struct, result: *mpz_struct) void {
    __gmpz_fdiv_q_2exp(result, op, 1);
}

// Declared against the local mpz_struct (identical ABI; just a pointer).
extern fn convertLongIntegerToLongIntegerRegister(long_integer: *const mpz_struct, regist: runtime.calcRegister_t) void;
extern fn getRegisterAsLongInt(reg: runtime.calcRegister_t, val: *mpz_struct, fractional: ?*bool) bool;

// Short-integer helpers (integers domain).
const ShortInteger = u64;
extern fn WP34S_extract_value(val: ShortInteger, sign: *i32) ShortInteger;
extern fn WP34S_intPower(base: ShortInteger, exponent: ShortInteger) ShortInteger;
// setRegisterShortIntegerBase/getRegisterShortIntegerBase are C macros over setRegisterTag/getRegisterTag.
inline fn setRegisterShortIntegerBase(reg: runtime.calcRegister_t, base: u32) void {
    runtime.setRegisterTag(reg, base);
}
inline fn getRegisterShortIntegerBase(reg: runtime.calcRegister_t) u32 {
    return runtime.getRegisterTag(reg);
}
inline fn registerShortIntegerData(reg: runtime.calcRegister_t) *align(1) ShortInteger {
    return abi.registerShortInteger(reg);
}

// ===========================================================================
// PowerReal
// ===========================================================================
pub export fn PowerReal(y: *const real_t, x: *const real_t, res: *real_t, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    var lny: real_t = undefined;

    if (realIsNegative(y) and realIsAnInteger(x)) {
        realDivideRemainder(x, const_2(), &lny, realContext);
        const isOdd: bool = !realIsZero(&lny);
        realCopyAbs(y, &lny);
        WP34S_Ln(&lny, &lny, realContext);
        realMultiply(x, &lny, res, realContext);
        math_command_wrappers.realExp(res, res, realContext);
        if (isOdd) {
            realChangeSign(res);
        }
    } else {
        WP34S_Ln(y, &lny, realContext);
        realMultiply(x, &lny, res, realContext);
        math_command_wrappers.realExp(res, res, realContext);
    }
}

// ===========================================================================
// longIntegerPower
// ===========================================================================
pub export fn longIntegerPower(base: *mpz_struct, exponent: *mpz_struct, result: *mpz_struct) linksection(runtime.code_section) callconv(.c) void {
    if (longIntegerIsZero(exponent)) {
        uInt32ToLongInteger(1, result);
    } else if (longIntegerIsZero(base)) {
        uInt32ToLongInteger(0, result);
    } else if ((longIntegerCompareInt(base, 1) == 0 or longIntegerCompareInt(base, -1) == 0) and longIntegerCompareInt(exponent, -1) == 0) {
        longIntegerCopy(base, result);
    } else if (longIntegerIsNegative(exponent)) {
        uInt32ToLongInteger(0, result);
    } else {
        uInt32ToLongInteger(1, result);

        while (!longIntegerIsZero(exponent)) {
            if (longIntegerIsOdd(exponent)) {
                longIntegerMultiply(result, base, result);
            }

            longIntegerDivide2(exponent, exponent);

            if (!longIntegerIsZero(exponent)) {
                longIntegerSquare(base, base);
            }
        }
    }
}

// ===========================================================================
// powShoI: Y(short integer) ^ X(short integer)
// ===========================================================================
fn powShoI() linksection(runtime.code_section) callconv(.c) void {
    var exponentSign: i32 = undefined;
    var baseSign: i32 = undefined;

    const exponent: ShortInteger = WP34S_extract_value(registerShortIntegerData(REGISTER_X).*, &exponentSign);
    const base: ShortInteger = WP34S_extract_value(registerShortIntegerData(REGISTER_Y).*, &baseSign);

    if (base == 1 and exponent == 1 and exponentSign != 0) {
        setRegisterShortIntegerBase(REGISTER_X, getRegisterShortIntegerBase(REGISTER_Y));
        registerShortIntegerData(REGISTER_X).* = registerShortIntegerData(REGISTER_Y).*;
    } else if (exponentSign != 0) { // exponent is negative
        powReal();
    } else {
        setRegisterShortIntegerBase(REGISTER_X, getRegisterShortIntegerBase(REGISTER_Y));
        registerShortIntegerData(REGISTER_X).* = WP34S_intPower(registerShortIntegerData(REGISTER_Y).*, registerShortIntegerData(REGISTER_X).*);
    }
}

// ===========================================================================
// powLonI: Y(long integer) ^ X(long integer)
// ===========================================================================
fn powLonI() linksection(runtime.code_section) callconv(.c) void {
    var base: mpz_struct = undefined;
    var exponent: mpz_struct = undefined;
    var result: mpz_struct = undefined;

    if (!getRegisterAsLongInt(REGISTER_Y, &base, null)) {
        longIntegerFree(&base);
        return;
    }
    // base is init'd (getRegisterAsLongInt inits even on the failure just handled);
    // defer replaces the finish1/finish2 goto-cleanup in matching LIFO order.
    defer longIntegerFree(&base);
    if (!getRegisterAsLongInt(REGISTER_X, &exponent, null)) {
        longIntegerFree(&exponent);
        return;
    }
    defer longIntegerFree(&exponent);

    if (longIntegerIsZero(&exponent) and longIntegerIsZero(&base)) {
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function powLonI: Cannot calculate 0^0!", null, null, null);
        return;
    }

    if ((longIntegerCompareInt(&base, 1) == 0 or longIntegerCompareInt(&base, -1) == 0) and longIntegerCompareInt(&exponent, -1) == 0) {
        convertLongIntegerToLongIntegerRegister(&base, REGISTER_X);
        return;
    } else if (longIntegerIsNegative(&exponent)) {
        powReal();
        return;
    }

    longIntegerInit(&result);
    defer longIntegerFree(&result);
    longIntegerPower(&base, &exponent, &result);

    convertLongIntegerToLongIntegerRegister(&result, REGISTER_X);
}

// ===========================================================================
// powReal: Y(real34) ^ X(real34)
// ===========================================================================
fn powReal() linksection(runtime.code_section) callconv(.c) void {
    var y: real_t = undefined;
    var x: real_t = undefined;
    var res: real_t = undefined;

    if (!runtime.getRegisterAsReal(REGISTER_X, &x) or !runtime.getRegisterAsReal(REGISTER_Y, &y)) {
        return;
    }

    if (realIsInfinite(&y)) {
        if (realIsZero(&x)) {
            realSetNaN(&res);
        } else {
            if (realIsPositive(&x) and realIsAnInteger(&x)) {
                WP34S_Mod(&x, const_2(), &res, &runtime.ctxtReal39);
                realCopy(if (realIsZero(&res)) const_plusInfinity() else const_minusInfinity(), &res);
            } else {
                realSetPlusInfinity(&res);
            }
        }
        // goto finish
        runtime.convertRealToResultRegister(&res, REGISTER_X, amNone);
        return;
    }

    PowerReal(&y, &x, &res, &runtime.ctxtReal39);

    if (realIsNaN(&res) and realIsNegative(&y) and !realIsAnInteger(&x)) {
        if (runtime.getFlag(FLAG_CPXRES)) {
            powCplx();
            return;
        } else {
            displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnError("In function powReal:", "cannot do complex results if CPXRES is not set", null, null);
            return;
        }
    }

    // finish:
    runtime.convertRealToResultRegister(&res, REGISTER_X, amNone);
}

// ===========================================================================
// PowerComplex
// ===========================================================================
pub export fn PowerComplex(yReal: *const real_t, yImag: *const real_t, xReal: *const real_t, xImag: *const real_t, rReal: *real_t, rImag: *real_t, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) u8 {
    const errorCode: u8 = ERROR_NONE;

    if (realIsInfinite(yReal) or realIsInfinite(yImag)) {
        if (realIsZero(xReal) and realIsZero(xImag)) {
            realSetNaN(rReal);
            realSetNaN(rImag);
        } else {
            realSetPlusInfinity(rReal);
            realSetPlusInfinity(rImag);
        }
    } else if (realIsZero(yReal) and realIsZero(yImag)) {
        if (realIsZero(xReal)) {
            realSetNaN(rReal);
            realSetNaN(rImag);
        } else {
            realSetZero(rReal);
            realSetZero(rImag);
        }
    } else {
        var theta: real_t = undefined;
        var tmp: real_t = undefined;

        realRectangularToPolar(yReal, yImag, rReal, &theta, realContext);
        WP34S_Ln(rReal, rReal, realContext);

        realMultiply(rReal, xImag, rImag, realContext); // rImag = Xi.LN r

        var xR: real_t = undefined;
        var md: i8 = undefined;
        var doZeroingReal: bool = false;
        var doZeroingImag: bool = false;
        if (math_comparison_reals.realCompareAbsEqual(yReal, yImag)) {
            realDivideRemainder(xReal, const_8(), &xR, realContext);
            if (realIsZero(xImag) and realIsAnInteger(&xR)) {
                md = @intCast(realToInt32C47(&xR, null));
                if (@mod(md, 4) == 0) {
                    doZeroingImag = true;
                } else if (@mod(md - 2, 4) == 0) {
                    doZeroingReal = true;
                }
            }
        } else if (realIsZero(yReal)) {
            realDivideRemainder(xReal, const_4(), &xR, realContext);
            if (realIsZero(xImag) and realIsAnInteger(&xR)) {
                md = @intCast(realToInt32C47(&xR, null));
                if (@mod(md, 2) == 0) {
                    doZeroingImag = true;
                } else {
                    doZeroingReal = true;
                }
            }
        } else {
            realCopy(xReal, &xR);
        }

        realFMA(&theta, &xR, rImag, rImag, realContext); // rImag = Xi.LN r  +  theta . Xr
        realChangeSign(&theta);

        realMultiply(rReal, xReal, rReal, realContext); // rReal = Xr.LN r
        realFMA(&theta, xImag, rReal, rReal, realContext); // rReal = Xr.LN r  *  -theta . Xi

        math_command_wrappers.realExp(rReal, &tmp, realContext);
        realPolarToRectangular(const_1(), rImag, rReal, rImag, realContext);
        if (doZeroingImag) {
            realSetZero(rImag);
        } else {
            realMultiply(&tmp, rImag, rImag, realContext);
        }
        if (doZeroingReal) {
            realSetZero(rReal);
        } else {
            realMultiply(&tmp, rReal, rReal, realContext);
        }
    }

    return errorCode;
}

// ===========================================================================
// powCplx: Y(complex34) ^ X(complex34)
// ===========================================================================
fn powCplx() linksection(runtime.code_section) callconv(.c) void {
    var yReal: real_t = undefined;
    var yImag: real_t = undefined;
    var xReal: real_t = undefined;
    var xImag: real_t = undefined;
    var rReal: real_t = undefined;
    var rImag: real_t = undefined;

    if (!runtime.getRegisterAsComplex(REGISTER_Y, &yReal, &yImag) or !runtime.getRegisterAsComplex(REGISTER_X, &xReal, &xImag)) {
        return;
    }

    const errorCode: u8 = PowerComplex(&yReal, &yImag, &xReal, &xImag, &rReal, &rImag, &runtime.ctxtReal39);

    if (errorCode != ERROR_NONE) {
        displayCalcErrorMessage(errorCode, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function powCplx:", "cannot raise", "to", null);
    } else {
        runtime.convertComplexToResultRegister(&rReal, &rImag, REGISTER_X);
    }
}

// ===========================================================================
// fnPower
// ===========================================================================
pub export fn fnPower(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    runtime.processIntRealComplexDyadicFunction(&powReal, &powCplx, &powShoI, &powLonI);
}
