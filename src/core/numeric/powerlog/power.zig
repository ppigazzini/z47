// SPDX-License-Identifier: GPL-3.0-only
const abi = @import("abi");
const consts = abi.constants;
const const_4 = consts.const_4;
const const_8 = consts.const_8;
const const_1on2 = consts.const_1on2;
const const_1on4 = consts.const_1on4;
//
// Zig owner for src/c47/mathematics/power.c: the y^x POWER command, real /
// complex / short-integer / long-integer, plus the exported helpers PowerReal,
// PowerComplex and longIntegerPower (used cross-domain). Faithful line-by-line
// translation preserving the exact order of every real_t / mpz operation
// (power_real / power_complex / power_longInteger / square / cube tests check
// results to the last ULP). The static powReal / powCplx / powShoI / powLonI
// helpers stay private; PowerReal / PowerComplex / longIntegerPower / fnPower
// keep C linkage. The EXTRA_INFO_ON_CALC_ERROR sprintf hints become fixed
// moreInfoOnError strings (no-op under TESTSUITE / DMCP).

const runtime = @import("../command_wrappers/runtime.zig");
const math_command_wrappers = @import("../command_wrappers.zig");
const math_comparison_reals = @import("../compare/comparison_reals.zig");
const math_real_predicates = @import("../compare/real_predicates.zig");
const real_t = runtime.real_t;
const real34_t = runtime.real34_t;
const realContext_t = runtime.realContext_t;
const cplx_t = runtime.cplx_t;

const realMultiply = runtime.realMultiply;
const realDivide = runtime.realDivide;
const realFMA = runtime.realFMA;
const realSubtract = runtime.realSubtract;
const realIsZero = runtime.realIsZero;
const realIsNaN = runtime.realIsNaN;
const realIsNegative = runtime.realIsNegative;
const realIsInfinite = runtime.realIsInfinite;
const realIsAnInteger = runtime.realIsAnInteger;
const realSetNaN = runtime.realSetNaN;
const realSetZero = runtime.realSetZero;
const realChangeSign = runtime.realChangeSign;
const realToInt32C47 = runtime.realToInt32C47;
const realPolarToRectangular = runtime.realPolarToRectangular;
const realSetPositiveSign = runtime.realSetPositiveSign;
inline fn realSetNegativeSign(operand: *real_t) void {
    operand.bits |= 0x80;
}
const int32ToReal = runtime.int32ToReal;
const realAdd = runtime.realAdd;

// Sector-boundary infinite-angle helpers (conversionAngles.c owner, shell object).
const getInfiniteComplexAngle = runtime.getInfiniteComplexAngle;
const setInfiniteComplexAngle = runtime.setInfiniteComplexAngle;

const WP34S_Ln = runtime.WP34S_Ln;
const WP34S_Ln1P = runtime.WP34S_Ln1P;
const WP34S_Mod = runtime.WP34S_Mod;
const WP34S_Real34Remainder = runtime.WP34S_Real34Remainder;
const C47_WP34S_Atan2 = runtime.C47_WP34S_Atan2;

const REGISTER_X = runtime.REGISTER_X;
const REGISTER_Y = runtime.REGISTER_Y;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN = runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN;
const ERROR_NONE: u8 = 0;
const amNone = runtime.amNone;
const FLAG_CPXRES: u16 = 0x8004;
const dtLongInteger = runtime.dtLongInteger;
const dtReal34 = runtime.dtReal34;

const displayCalcErrorMessage = runtime.displayCalcErrorMessage;
const moreInfoOnError = runtime.moreInfoOnError;

inline fn const_0() *const real_t {
    return runtime.z47_math_wrappers_const_0();
}
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

// real ops / predicates / copy. Some are C macros; reproduce them.
extern fn realSetPlusInfinity(value: *real_t) void;
extern fn decNumberCopy(res: *real_t, source: *const real_t) *real_t;
extern fn decNumberCopyAbs(res: *real_t, source: *const real_t) *real_t;
extern fn decNumberRemainder(res: *real_t, lhs: *align(1) const real_t, rhs: *align(1) const real_t, ctxt: *realContext_t) *real_t;
// real34ToInt32 (realType.h): decQuadToInt32 rounding down in the Real34 context.
extern fn decQuadToInt32(source: *align(1) const real34_t, ctxt: *realContext_t, round: c_int) i32;
inline fn realCopy(source: *const real_t, destination: *real_t) void {
    _ = decNumberCopy(destination, source);
}
inline fn realCopyAbs(source: *const real_t, destination: *real_t) void {
    _ = decNumberCopyAbs(destination, source);
}
inline fn realDivideRemainder(operand1: *align(1) const real_t, operand2: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberRemainder(res, operand1, operand2, ctxt);
}
inline fn real34ToInt32(source: *align(1) const real34_t) i32 {
    return decQuadToInt32(source, &runtime.ctxtReal34, runtime.DEC_ROUND_DOWN);
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
extern fn __gmpz_fdiv_ui(n: *const mpz_struct, d: c_ulong) c_ulong;

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
inline fn longIntegerModuloUInt(op: *const mpz_struct, u: u32) u32 {
    return @truncate(__gmpz_fdiv_ui(op, u));
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

// y^x with the exponent's parity known exactly: integerParity is 1 for an odd
// integer exponent, 0 for an even one, and -1 when the parity is not known, in
// which case it is read off the exponent itself.
fn powerRealWithParity(y: *const real_t, x: *const real_t, res: *real_t, realContext: *realContext_t, integerParity: i32) linksection(runtime.code_section) void {
    var lny: real_t = undefined;

    realCopyAbs(x, &lny);
    if (realIsAnInteger(x) and runtime.realCompareLessEqual(&lny, abi.constants.const_10p9__1())) {
        runtime.realPower(y, x, res, realContext);
    } else if (realIsNegative(y) and (integerParity >= 0 or realIsAnInteger(x))) {
        var isOdd: bool = false;

        if (integerParity >= 0) {
            isOdd = integerParity == 1;
        } else if (!realIsInfinite(x)) { // realIsAnInteger() is true for an infinity, which is neither odd nor even
            realDivideRemainder(x, const_2(), &lny, realContext);
            isOdd = !realIsZero(&lny);
        }
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

pub export fn PowerReal(y: *const real_t, x: *const real_t, res: *real_t, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    powerRealWithParity(y, x, res, realContext, -1);
}

// decContext status flags (DECEXTFLAG layout) that mark a power as not exact.
const DEC_Division_by_zero: u32 = 0x00000002;
const DEC_Inexact: u32 = 0x00000020;
const DEC_Invalid_operation: u32 = 0x00000080;
const DEC_Overflow: u32 = 0x00000200;
const DEC_Underflow: u32 = 0x00002000;

const realIsSpecial = runtime.realIsSpecial;
const realCompareEqual = runtime.realCompareEqual;
const realCompareGreaterThan = runtime.realCompareGreaterThan;

inline fn realGetExponent(source: *const real_t) i32 {
    return source.digits + source.exponent - 1;
}

inline fn realPlus(operand: *const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = runtime.decNumberPlus(res, operand, ctxt);
}

// ===========================================================================
// realIntegerPowerExact
// ===========================================================================

/// x to the integer power n, when the power is exact. The power is taken at 75
/// digits half even, by repeated multiplication. It is exact when no digit is
/// dropped, which the Inexact status of the context reports. True when n is an
/// integer below 10000 in magnitude and res is x^n exactly.
pub export fn realIntegerPowerExact(x: *const real_t, n: *const real_t, res: *real_t) linksection(runtime.code_section) callconv(.c) bool {
    var c: realContext_t = runtime.ctxtReal75;

    if (realIsSpecial(x) or realIsSpecial(n) or !realIsAnInteger(n) or (!realIsZero(n) and realGetExponent(n) > 3)) {
        return false;
    }
    c.round = runtime.DEC_ROUND_HALF_EVEN;
    c.status = 0;
    runtime.realPower(x, n, res, &c);
    return (c.status & (DEC_Inexact | DEC_Overflow | DEC_Underflow | DEC_Invalid_operation | DEC_Division_by_zero)) == 0 and !realIsSpecial(res);
}

// ===========================================================================
// realExactRoot
// ===========================================================================

/// The n-th root of x, exact where x is the n-th power of a number of 34
/// digits. root rounded half even to 34 digits is the exact root when one of 34
/// digits exists; the test is that its n-th power is x exactly. root holds the
/// root at working precision and is replaced by the exact root when there is
/// one, which the result reports.
pub export fn realExactRoot(x: *const real_t, n: *const real_t, root: *real_t) linksection(runtime.code_section) callconv(.c) bool {
    var c: real_t = undefined;
    var p: real_t = undefined;
    var c34: realContext_t = runtime.ctxtReal34;

    c34.round = runtime.DEC_ROUND_HALF_EVEN;
    realPlus(root, &c, &c34);
    if (!realIntegerPowerExact(&c, n, &p) or !realCompareEqual(&p, x)) {
        return false;
    }
    realCopy(&c, root);
    return true;
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
                runtime.longIntegerMultiply(result, base, result);
            }

            longIntegerDivide2(exponent, exponent);

            if (!longIntegerIsZero(exponent)) {
                runtime.longIntegerSquare(base, base);
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
    var exactPower: real34_t = undefined;
    var reciprocal: real34_t = undefined;

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
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE);
        moreInfoOnError("In function powLonI: Cannot calculate 0^0!", null, null, null);
        return;
    }

    // A small negative exponent is one Real34 rounding of the exact reciprocal power: -1 is the reciprocal, -2 to -4 go through powerLongIntegerToReal34.
    const smallNegativeExponent: i32 = if (longIntegerCompareInt(&exponent, -2) == 0) -2 else if (longIntegerCompareInt(&exponent, -3) == 0) -3 else if (longIntegerCompareInt(&exponent, -4) == 0) -4 else 0;

    if ((longIntegerCompareInt(&base, 1) == 0 or longIntegerCompareInt(&base, -1) == 0) and longIntegerCompareInt(&exponent, -1) == 0) {
        convertLongIntegerToLongIntegerRegister(&base, REGISTER_X);
        return;
    } else if (longIntegerCompareInt(&exponent, -1) == 0 and runtime.reciprocalLongIntegerRegisterToReal34(REGISTER_Y, &reciprocal)) {
        runtime.convertReal34ToReal34Register(&reciprocal, REGISTER_X);
        return;
    } else if (smallNegativeExponent != 0 and runtime.powerLongIntegerToReal34(&base, smallNegativeExponent, &exactPower)) {
        runtime.convertReal34ToReal34Register(&exactPower, REGISTER_X);
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
    var exactResult: real34_t = undefined;
    const integerParity = runtime.getRegisterIntegerParity(REGISTER_X);

    if (runtime.getRegisterDataType(REGISTER_Y) == dtLongInteger and runtime.getRegisterDataType(REGISTER_X) == dtReal34 and runtime.real34IsAnInteger(runtime.registerReal34Ptr(REGISTER_X))) {
        var base: mpz_struct = undefined;
        const exponent = real34ToInt32(runtime.registerReal34Ptr(REGISTER_X)); // 0 out of range; powerLongIntegerToReal34 takes +-2, +-3 and +-4 only

        runtime.convertLongIntegerRegisterToLongInteger(REGISTER_Y, &base);
        const exactPower = runtime.powerLongIntegerToReal34(&base, exponent, &exactResult);
        longIntegerFree(&base);
        if (exactPower) {
            runtime.convertReal34ToReal34Register(&exactResult, REGISTER_X);
            return;
        }
    }

    if (runtime.registerIdentityExponentToReal34(REGISTER_Y, REGISTER_X, &exactResult)) {
        runtime.convertReal34ToReal34Register(&exactResult, REGISTER_X);
        return;
    }

    if (!runtime.getRegisterAsReal(REGISTER_X, &x) or !runtime.getRegisterAsReal(REGISTER_Y, &y)) {
        return;
    }

    if ((realCompareEqual(&x, const_1on2()) or realCompareEqual(&x, const_1on4())) and
        runtime.rootRegisterToReal34(REGISTER_Y, if (realCompareEqual(&x, const_1on2())) 2 else 4, false, &exactResult))
    { // y^(1/n) is the n-th root of y, rounded once
        runtime.convertReal34ToReal34Register(&exactResult, REGISTER_X);
        return;
    }

    if (realCompareEqual(&x, const_1on2()) and realIsNegative(&y) and !realIsZero(&y) and !realIsInfinite(&y) and runtime.getFlag(FLAG_CPXRES)) { // (-y)^(1/2) is 0 + i sqrt(y), as sqrt gives it
        realSetPositiveSign(&y);
        runtime.realSquareRoot(&y, &y, &runtime.ctxtReal39);
        runtime.convertComplexPartsToResultRegister(const_0(), &y, REGISTER_X);
        return;
    }

    finish: {
        if (realIsInfinite(&y)) { // y (the base) is +/- infinity
            if (realIsNaN(&x)) { // inf ^ NaN is NaN; must precede the tests below, realIsPositive() is true for a NaN
                realSetNaN(&res);
            } else if (realIsZero(&x)) { // inf ^ 0 is indeterminate
                realSetNaN(&res);
            } else {
                var oddIntegerExponent: bool = false;
                if (!realIsInfinite(&x)) { // ReM p.202: y^(+/-inf) follows the exponent sign alone; realIsAnInteger() is true for an infinity
                    if (integerParity >= 0) {
                        oddIntegerExponent = integerParity == 1;
                    } else if (realIsAnInteger(&x)) {
                        WP34S_Mod(&x, const_2(), &res, &runtime.ctxtReal39);
                        oddIntegerExponent = !realIsZero(&res);
                    } else if (realIsNegative(&y)) { // (-inf) ^ non-integer is not a real number
                        if (runtime.getFlag(FLAG_CPXRES)) {
                            powCplx();
                            return;
                        }
                        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE);
                        moreInfoOnError("In function powReal:", "cannot do complex results if CPXRES is not set", null, null);
                        return;
                    }
                }
                if (realIsPositive(&x)) { // exponent > 0  ==> +/- infinity
                    realSetPlusInfinity(&res);
                } else { // exponent < 0  ==> +/- zero
                    realSetZero(&res);
                }
                if (realIsNegative(&y) and oddIntegerExponent) { // (-inf) ^ odd keeps the negative sign
                    realSetNegativeSign(&res);
                }
            }
            break :finish;
        }

        if (realIsZero(&y) and !realIsAnInteger(&x)) { // (-0) ^ non-integer is (+0) ^ non-integer, a real
            realSetPositiveSign(&y);
        }

        if (!realIsZero(&y) and realIntegerPowerExact(&y, &x, &res)) { // an integer exponent with an exact power: the power itself, rounded once by RM
            break :finish;
        }

        powerRealWithParity(&y, &x, &res, if (realIsAnInteger(&x)) &runtime.ctxtReal39 else &runtime.ctxtReal51, integerParity);

        if (realIsPositive(&y) and !realIsZero(&x) and !realIsSpecial(&res)) { // an exponent 1/n with an exact n-th root of y gives that root
            var n: real_t = undefined;
            realDivide(const_1(), &x, &n, &runtime.ctxtReal39);
            if (realIsAnInteger(&n) and realCompareGreaterThan(&n, const_1())) {
                _ = realExactRoot(&y, &n, &res);
            }
        }

        if (realIsNaN(&res) and realIsNegative(&y) and !realIsAnInteger(&x)) {
            if (runtime.getFlag(FLAG_CPXRES)) {
                powCplx();
                return;
            } else {
                displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE);
                moreInfoOnError("In function powReal:", "cannot do complex results if CPXRES is not set", null, null);
                return;
            }
        }
    }

    runtime.convertRealToResultRegister(&res, REGISTER_X, amNone);
}

// ===========================================================================
// PowerComplex
// ===========================================================================

// ReM p.B-18: a power of (r ; phi) is (r^x ; phi.x). An infinite base sits on one of the 8 sector boundaries that
// getInfiniteComplexAngle() reports, so phi.x is representable only when it lands on one too. Returns false when it does
// not, the exponent being infinite or the product fractional, leaving the caller to return an infinity of no angle.
fn setInfiniteComplexPower(y: *const cplx_t, xReal: *const real_t, exponentModulo8: i32, r: *cplx_t, realContext: *realContext_t) linksection(runtime.code_section) bool {
    var sector: real_t = undefined;
    var residue: real_t = undefined;
    var exponent: *const real_t = xReal;

    if (realIsInfinite(xReal)) { // phi.x is then unbounded, and WP34S_Mod() of it is a NaN
        return false;
    }

    int32ToReal(@intCast(getInfiniteComplexAngle(y)), &sector);
    if (exponentModulo8 >= 0) { // a long integer exponent above 75 digits comes rounded in xReal
        int32ToReal(exponentModulo8, &residue);
        exponent = &residue;
    }
    realMultiply(&sector, exponent, &sector, realContext);
    WP34S_Mod(&sector, const_8(), &sector, realContext); // remainder is truncated, so lift it into [0, 8) = one revolution
    if (realIsNegative(&sector)) {
        realAdd(&sector, const_8(), &sector, realContext);
    }

    if (!realIsAnInteger(&sector)) {
        return false;
    }
    setInfiniteComplexAngle(@intCast(realToInt32C47(&sector, null)), r);
    return true;
}

// The principal logarithm of a finite nonzero complex base: the logarithm of the
// magnitude in lnReal, the phase in radians in lnImag. At 75 digits a magnitude
// between 1/2 and 2 takes ln(1 + delta), the offset of the larger component from
// one and the square of the other, so the digits next to one are not lost.
fn lnPowerComplex(z: *const cplx_t, lnReal: *real_t, lnImag: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var delta: real_t = undefined;
    var sum: real_t = undefined;

    realMultiply(&z.Real, &z.Real, lnReal, realContext);
    realFMA(&z.Imag, &z.Imag, lnReal, lnReal, realContext);
    runtime.realSquareRoot(lnReal, lnReal, realContext);
    C47_WP34S_Atan2(&z.Imag, &z.Real, lnImag, realContext);

    if (realContext.digits == 75 and realCompareGreaterThan(lnReal, const_1on2()) and runtime.realCompareLessThan(lnReal, const_2())) {
        if (math_comparison_reals.realCompareAbsLessThan(&z.Real, &z.Imag)) {
            realSubtract(&z.Imag, const_1(), &delta, realContext);
            realAdd(&z.Imag, const_1(), &sum, realContext);
            realMultiply(&delta, &sum, &delta, realContext);
            realFMA(&z.Real, &z.Real, &delta, &delta, realContext);
        } else {
            realSubtract(&z.Real, const_1(), &delta, realContext);
            realAdd(&z.Real, const_1(), &sum, realContext);
            realMultiply(&delta, &sum, &delta, realContext);
            realFMA(&z.Imag, &z.Imag, &delta, &delta, realContext);
        }
        WP34S_Ln1P(&delta, lnReal, realContext);
        realMultiply(lnReal, const_1on2(), lnReal, realContext);
    } else {
        WP34S_Ln(lnReal, lnReal, realContext);
    }
}

// Reduces the real exponent for an exact-axis phase: a long integer exponent
// modulo 8 (a multiple of every period) when the real component rounded above
// 75 digits no longer gives it, otherwise the exact Real34 remainder where both
// operands fit 34 digits, and WP34S_Mod beyond that.
fn reducePowerExponent(exponent: *const real_t, period: *const real_t, exponentModulo8: i32, remainder: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    if (exponentModulo8 >= 0) {
        int32ToReal(exponentModulo8, remainder);
    } else if (exponent.digits <= 34 and period.digits <= 34) {
        WP34S_Real34Remainder(exponent, period, remainder);
    } else {
        WP34S_Mod(exponent, period, remainder, realContext);
    }
}

// Calculate y^x for complex numbers.
fn powerComplexWithResidue(y: *const cplx_t, x: *const cplx_t, r: *cplx_t, realContext: *realContext_t, exponentModulo8: i32) linksection(runtime.code_section) u8 {
    const errorCode: u8 = ERROR_NONE;

    if (realIsInfinite(&y.Real) or realIsInfinite(&y.Imag)) { // the base has an infinite component
        if (realIsNaN(&x.Real) or realIsNaN(&x.Imag)) { // inf ^ NaN is NaN
            realSetNaN(&r.Real);
            realSetNaN(&r.Imag);
        } else if (realIsZero(&x.Real) and realIsZero(&x.Imag)) { // inf ^ 0 is indeterminate
            realSetNaN(&r.Real);
            realSetNaN(&r.Imag);
        } else if (realIsZero(&x.Real)) { // Re(exponent) == 0 (pure imaginary) is indeterminate
            realSetNaN(&r.Real);
            realSetNaN(&r.Imag);
        } else if (realIsNegative(&x.Real)) { // Re(exponent) < 0 ==> modulus collapses to 0, where the angle no longer counts
            realSetZero(&r.Real);
            realSetZero(&r.Imag);
        } else { // Re(exponent) > 0 ==> infinite modulus
            var onSector: bool = false;

            if (realIsZero(&x.Imag)) { // Im(exponent) != 0 adds Im(x).ln r to the argument, leaving it unbounded
                onSector = setInfiniteComplexPower(y, &x.Real, exponentModulo8, r, realContext);
            }
            if (!onSector) {
                realSetPlusInfinity(&r.Real);
                realSetPlusInfinity(&r.Imag);
            }
        }
    } else if (realIsZero(&y.Real) and realIsZero(&y.Imag)) {
        if (realIsNaN(&x.Real) or realIsNaN(&x.Imag) or realIsZero(&x.Real)) {
            realSetNaN(&r.Real);
            realSetNaN(&r.Imag);
        } else {
            realSetZero(&r.Real);
            realSetZero(&r.Imag);
        }
    } else if (realCompareEqual(&x.Real, const_1()) and realIsZero(&x.Imag) and !realIsNaN(&y.Real) and !realIsNaN(&y.Imag)) {
        realCopy(&y.Real, &r.Real);
        realCopy(&y.Imag, &r.Imag);
    } else {
        var theta: real_t = undefined;
        var tmp: real_t = undefined;

        // y^x = (r.e^(i.theta))^(Xr + i.Xi) = EXP [ (Xr.LN r) * (-theta Xi)  +   i.(Xi.LN r + (theta . Xr)) ]
        lnPowerComplex(y, &r.Real, &theta, realContext);

        realMultiply(&r.Real, &x.Imag, &r.Imag, realContext); // rImag = Xi.LN r

        var xR: real_t = undefined;
        var md: i8 = undefined;
        var doZeroingReal: bool = false;
        var doZeroingImag: bool = false;
        if (math_comparison_reals.realCompareAbsEqual(&y.Real, &y.Imag)) {
            reducePowerExponent(&x.Real, const_8(), exponentModulo8, &xR, realContext); // yR = yI gives theta = pi/4 exactly, so Xr reduces modulo 8
            if (realIsZero(&x.Imag) and realIsAnInteger(&xR)) { // only compute md when exponent is integer
                md = @intCast(realToInt32C47(&xR, null));
                if (@mod(md, 4) == 0) {
                    doZeroingImag = true;
                } else if (@mod(md - 2, 4) == 0) {
                    doZeroingReal = true;
                }
            }
        } else if (realIsZero(&y.Real)) {
            reducePowerExponent(&x.Real, const_4(), exponentModulo8, &xR, realContext); // yR = 0 gives theta = pi/2 exactly, so Xr reduces modulo 4
            if (realIsZero(&x.Imag) and realIsAnInteger(&xR)) { // only compute md when exponent is integer
                md = @intCast(realToInt32C47(&xR, null));
                if (@mod(md, 2) == 0) {
                    doZeroingImag = true;
                } else {
                    doZeroingReal = true;
                }
            }
        } else if (realIsZero(&y.Imag) and realIsNegative(&y.Real)) {
            reducePowerExponent(&x.Real, const_2(), exponentModulo8, &xR, realContext);
            if (realIsZero(&x.Imag) and realIsAnInteger(&xR)) {
                doZeroingImag = true;
            }
        } else {
            realCopy(&x.Real, &xR);
        }

        realFMA(&theta, &xR, &r.Imag, &r.Imag, realContext); // rImag = Xi.LN r  +  theta . Xr: the angle, reduced above to one revolution
        realChangeSign(&theta);

        realMultiply(&r.Real, &x.Real, &r.Real, realContext); // rReal = Xr.LN r
        realFMA(&theta, &x.Imag, &r.Real, &r.Real, realContext); // rReal = Xr.LN r  -  theta . Xi

        math_command_wrappers.realExp(&r.Real, &tmp, realContext);
        realPolarToRectangular(const_1(), &r.Imag, r, realContext);
        if (doZeroingImag) {
            realSetZero(&r.Imag);
        } else {
            realMultiply(&tmp, &r.Imag, &r.Imag, realContext);
        }
        if (doZeroingReal) {
            realSetZero(&r.Real);
        } else {
            realMultiply(&tmp, &r.Real, &r.Real, realContext);
        }
    }

    return errorCode;
}

pub export fn PowerComplex(y: *const cplx_t, x: *const cplx_t, r: *cplx_t, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) u8 {
    return powerComplexWithResidue(y, x, r, realContext, -1);
}

// A long integer register value modulo 8: the residue from 0 to 7, or -1 for any
// other data type.
fn registerLongIntegerModulo8(regist: runtime.calcRegister_t) linksection(runtime.code_section) i32 {
    var integer: mpz_struct = undefined;

    if (runtime.getRegisterDataType(regist) != dtLongInteger) {
        return -1;
    }
    runtime.convertLongIntegerRegisterToLongInteger(regist, &integer);
    const residue: i32 = @intCast(longIntegerModuloUInt(&integer, 8));
    longIntegerFree(&integer);
    return residue;
}

// ===========================================================================
// powCplx: Y(complex34) ^ X(complex34)
// ===========================================================================
fn powCplx() linksection(runtime.code_section) callconv(.c) void {
    var y: cplx_t = undefined;
    var x: cplx_t = undefined;
    var r: cplx_t = undefined;

    if (!runtime.getRegisterAsComplex(REGISTER_Y, &y) or !runtime.getRegisterAsComplex(REGISTER_X, &x)) {
        return;
    }

    const errorCode: u8 = powerComplexWithResidue(&y, &x, &r, &runtime.ctxtReal75, registerLongIntegerModulo8(REGISTER_X));

    if (errorCode != ERROR_NONE) {
        displayCalcErrorMessage(errorCode, ERR_REGISTER_LINE);
        moreInfoOnError("In function powCplx:", "cannot raise", "to", null);
    } else {
        runtime.convertComplexToResultRegister(&r, REGISTER_X);
    }
}

// ===========================================================================
// fnPower
// ===========================================================================
pub export fn fnPower(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    runtime.processIntRealComplexDyadicFunction(&powReal, &powCplx, &powShoI, &powLonI);
}
