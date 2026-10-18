// SPDX-License-Identifier: GPL-3.0-only
const abi = @import("abi");
const consts = abi.constants;
const const_NaN = consts.const_NaN;
const const__1 = consts.const__1;
const const_1on2 = consts.const_1on2;
const const39_pi = consts.const39_pi;
const const39_piOn2 = consts.const39_piOn2;
const const39_piOn4 = consts.const39_piOn4;
const const39_2pi = consts.const39_2pi;
const const75_pi = consts.const75_pi;
const const75_piOn2 = consts.const75_piOn2;
const const75_piOn4 = consts.const75_piOn4;
const const75_2pi = consts.const75_2pi;
const const34_0 = consts.const34_0;
const const34_2 = consts.const34_2;
const const34_3 = consts.const34_3;
const const34_4 = consts.const34_4;
//
// Zig owner for src/c47/mathematics/xthRoot.c: the x-th root command y^(1/x),
// real / complex / short-integer / long-integer. Faithful line-by-line
// translation preserving the exact order of every real_t / mpz operation
// (xthRoot.txt checks results to the last ULP). Exports fnXthRoot and the
// public xthRootReal helper; the static xthRootComplex / doXthRoot* helpers
// stay private. The EXTRA_INFO_ON_CALC_ERROR sprintf hints become fixed
// moreInfoOnError strings (no-op under TESTSUITE / DMCP). The
// C carries no build-option guard on this file, so the body is unconditional.

const runtime = @import("../command_wrappers/runtime.zig");

const std_plus_minus = "\x80\xb1"; // STD_PLUS_MINUS
const std_infinity = "\xa2\x1e"; // STD_INFINITY
const std_sup_x = "\xa4\x99"; // STD_SUP_x
const math_comparison_reals = @import("../compare/comparison_reals.zig");
const math_power = @import("power.zig");
const math_real_predicates = @import("../compare/real_predicates.zig");
const real_t = runtime.real_t;
const real34_t = runtime.real34_t;
const realContext_t = runtime.realContext_t;
const cplx_t = runtime.cplx_t;

const realMultiply = runtime.realMultiply;
const realDivide = runtime.realDivide;
const realAdd = runtime.realAdd;
const realSubtract = runtime.realSubtract;
const realFMA = runtime.realFMA;
const realIsZero = runtime.realIsZero;
const realIsNaN = runtime.realIsNaN;
const realIsSpecial = runtime.realIsSpecial;
const realIsNegative = runtime.realIsNegative;
const realIsInfinite = runtime.realIsInfinite;
const realIsAnInteger = runtime.realIsAnInteger;
const realSetNaN = runtime.realSetNaN;
const realSetZero = runtime.realSetZero;
const realSetOne = runtime.realSetOne;
const realChangeSign = runtime.realChangeSign;
const realPolarToRectangular = runtime.realPolarToRectangular;
const realToIntegralValue = runtime.realToIntegralValue;
const realToInt32C47 = runtime.realToInt32C47;
const int32ToReal = runtime.int32ToReal;
const realCompareEqual = runtime.realCompareEqual;
const realCompareLessThan = runtime.realCompareLessThan;
const realCompareGreaterThan = runtime.realCompareGreaterThan;
const realCompareGreaterEqual = runtime.realCompareGreaterEqual;
const realCompareAbsGreaterThan = runtime.realCompareAbsGreaterThan;
const realCompareAbsEqual = math_comparison_reals.realCompareAbsEqual;
const real34CompareAbsEqual = math_comparison_reals.real34CompareAbsEqual;

const REGISTER_X = runtime.REGISTER_X;
const REGISTER_Y = runtime.REGISTER_Y;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN = runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN;
const ERROR_NONE: u8 = 0;
const amNone = runtime.amNone;
const dtLongInteger = runtime.dtLongInteger;
const dtReal34 = runtime.dtReal34;
const dtComplex34 = runtime.dtComplex34;
const FLAG_SPCRES: i32 = 0x8017;
const FLAG_CPXRES: u16 = 0x8004;

const displayCalcErrorMessage = runtime.displayCalcErrorMessage;
const moreInfoOnError = runtime.moreInfoOnError;
const getSystemFlag = runtime.getSystemFlag;
const getFlag = runtime.getFlag;
const getRegisterDataType = runtime.getRegisterDataType;

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
const const39_3piOn4 = consts.const39_3piOn4;
const const75_3piOn4 = consts.const75_3piOn4;

// real ops / predicates / copy. Some are C macros; reproduce them.
extern fn realSetPlusInfinity(value: *real_t) void;
extern fn realSetMinusInfinity(value: *real_t) void;
extern fn decNumberCopy(res: *real_t, source: *const real_t) *real_t;
extern fn decNumberRemainder(res: *real_t, lhs: *const real_t, rhs: *const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberCopyAbs(res: *real_t, source: *const real_t) *real_t;
extern fn decNumberReduce(res: *real_t, source: *const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberPlus(res: *real_t, source: *const real_t, ctxt: *realContext_t) *real_t;
inline fn realCopy(source: *const real_t, destination: *real_t) void {
    _ = decNumberCopy(destination, source);
}
inline fn realDivideRemainder(operand1: *const real_t, operand2: *const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberRemainder(res, operand1, operand2, ctxt);
}
inline fn realCopyAbs(source: *const real_t, destination: *real_t) void {
    _ = decNumberCopyAbs(destination, source);
}
inline fn realReduce(source: *const real_t, destination: *real_t, ctxt: *realContext_t) void {
    _ = decNumberReduce(destination, source, ctxt);
}
inline fn realPlus(source: *const real_t, destination: *real_t, ctxt: *realContext_t) void {
    _ = decNumberPlus(destination, source, ctxt);
}
const realIsPositive = math_real_predicates.realIsPositive;
inline fn realSetPositiveSign(source: *real_t) void {
    source.bits &= ~@as(@TypeOf(source.bits), 0x80);
}
inline fn realSetNegativeSign(source: *real_t) void {
    source.bits |= 0x80;
}
inline fn real34SetNegativeSign(value: *align(1) real34_t) void {
    value.bytes[15] |= 0x80;
}
inline fn real34Copy(source: *align(1) const real34_t, destination: *real34_t) void {
    destination.bytes = source.bytes;
}

// Complex helpers.
const lnComplex = runtime.lnComplex;
const expComplex = runtime.expComplex;
const divRealComplex = runtime.divRealComplex;
const mulComplexComplex = runtime.mulComplexComplex;

// Result-register conversions.
const convertRealToResultRegister = runtime.convertRealToResultRegister;
const convertComplexToResultRegister = runtime.convertComplexToResultRegister;
const convertComplexPartsToResultRegister = runtime.convertComplexPartsToResultRegister;
const convertReal34ToReal34Register = runtime.convertReal34ToReal34Register;
const convertReal34ToComplex34Register = runtime.convertReal34ToComplex34Register;

// ---------------------------------------------------------------------------
// GMP long integer (mpz).
// ---------------------------------------------------------------------------
const mpz_struct = abi.Mpz;

extern fn __gmpz_init(op: *mpz_struct) void;
extern fn __gmpz_clear(op: *mpz_struct) void;
extern fn __gmpz_set(rop: *mpz_struct, op: *const mpz_struct) void;
extern fn __gmpz_set_ui(rop: *mpz_struct, op: c_ulong) void;
extern fn __gmpz_get_si(op: *const mpz_struct) c_long;
extern fn __gmpz_cmp_si(op: *const mpz_struct, v: c_long) c_int;
extern fn __gmpz_cmp_ui(op: *const mpz_struct, v: c_ulong) c_int;
extern fn __gmpz_root(rop: *mpz_struct, op: *const mpz_struct, n: c_ulong) c_int;

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
inline fn longIntegerToInt32(op: *const mpz_struct) i32 {
    return @truncate(__gmpz_get_si(op));
}
const longIntegerIsZero = math_real_predicates.longIntegerIsZero;
inline fn longIntegerIsPositive(op: *const mpz_struct) bool {
    return op._mp_size > 0;
}
const longIntegerIsNegative = math_real_predicates.longIntegerIsNegative;
inline fn longIntegerIsOdd(op: *const mpz_struct) bool {
    return op._mp_size != 0 and (op._mp_d[0] & 1) != 0;
}
inline fn longIntegerChangeSign(op: *mpz_struct) void {
    op._mp_size = -op._mp_size;
}
inline fn longIntegerSetPositiveSign(op: *mpz_struct) void {
    if (op._mp_size < 0) {
        op._mp_size = -op._mp_size;
    }
}
inline fn longIntegerCompareInt(op: *const mpz_struct, sint: i32) i32 {
    return __gmpz_cmp_si(op, sint);
}
inline fn longIntegerCompareUInt(op: *const mpz_struct, u: u32) i32 {
    return __gmpz_cmp_ui(op, u);
}
inline fn longIntegerRoot(op: *const mpz_struct, n: u32, result: *mpz_struct) i32 {
    return __gmpz_root(result, op, n);
}

const convertLongIntegerToLongIntegerRegister = runtime.convertLongIntegerToLongIntegerRegister;
const getRegisterAsLongInt = runtime.getRegisterAsLongInt;
const rootLongIntegerToReal34 = runtime.rootLongIntegerToReal34;
const reciprocalRootLongIntegerToReal34 = runtime.reciprocalRootLongIntegerToReal34;

// Short-integer / register helpers.
extern fn convertShortIntegerRegisterToLongIntegerRegister(source: runtime.calcRegister_t, dest: runtime.calcRegister_t) void;
extern fn convertLongIntegerRegisterToShortIntegerRegister(source: runtime.calcRegister_t, dest: runtime.calcRegister_t) void;
// setRegisterShortIntegerBase/getRegisterShortIntegerBase are C macros over setRegisterTag/getRegisterTag.
inline fn setRegisterShortIntegerBase(reg: runtime.calcRegister_t, base: u32) void {
    runtime.setRegisterTag(reg, base);
}
inline fn getRegisterShortIntegerBase(reg: runtime.calcRegister_t) u32 {
    return runtime.getRegisterTag(reg);
}

// ===========================================================================
// correctExactReal34Root: replaces an approximation with an exact Real34 root
// when one exists.
//
// A nearest 34-digit candidate is reduced before verification. Each product is
// formed only while its exact coefficient has at most 34 digits, so a 39-digit
// multiplication cannot round it. A non-unit coefficient needs at most 112
// factors because 2^113 has 35 digits.
// ===========================================================================
fn correctExactReal34Root(operand: *const real_t, order: *const real_t, root: *real_t) linksection(runtime.code_section) void {
    var nearestContext: realContext_t = runtime.ctxtReal34;
    var nearest: real_t = undefined;
    var power: real_t = undefined;
    var reducedOperand: real_t = undefined;
    var conversionError: bool = undefined;

    if (realIsSpecial(operand) or realIsZero(operand) or realIsSpecial(order) or !realIsAnInteger(order) or !realIsPositive(order)) {
        return;
    }
    const n = realToInt32C47(order, &conversionError);
    if (conversionError) {
        return;
    }

    nearestContext.round = runtime.DEC_ROUND_HALF_EVEN;
    realPlus(root, &nearest, &nearestContext);
    realReduce(&nearest, &nearest, &runtime.ctxtReal39);
    if (n > 112) {
        realReduce(operand, &reducedOperand, &runtime.ctxtReal39);
        const negativePower = realIsNegative(&nearest) and (n & 1) != 0;
        if (nearest.digits == 1 and nearest.lsu[0] == 1 and reducedOperand.digits == 1 and reducedOperand.lsu[0] == 1 and
            negativePower == realIsNegative(&reducedOperand) and @as(i64, nearest.exponent) * n == reducedOperand.exponent)
        {
            realCopy(&nearest, root);
        }
        return;
    }

    realSetOne(&power);
    var factor: i32 = 0;
    while (factor < n) : (factor += 1) {
        if (power.digits + nearest.digits - 1 > 34) {
            return;
        }
        realMultiply(&power, &nearest, &power, &runtime.ctxtReal39);
    }
    if (realCompareEqual(&power, operand)) {
        realCopy(&nearest, root);
    }
}

// ===========================================================================
// lnXthRootComplex: Log Y with phase constants matching the working precision.
//
// The shared polar conversion uses 39-digit constants for axes and infinities.
// This function supplies the 75-digit constants needed by the Real34 complex
// root path and retains the side of a finite nonzero imaginary component.
// ===========================================================================
fn lnXthRootComplex(y: *const cplx_t, ln: *cplx_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    const wide = realContext.digits > 51;
    const pi: *const real_t = if (wide) const75_pi() else const39_pi();
    const piOn2: *const real_t = if (wide) const75_piOn2() else const39_piOn2();
    const piOn4: *const real_t = if (wide) const75_piOn4() else const39_piOn4();
    const pi3On4: *const real_t = if (wide) const75_3piOn4() else const39_3piOn4();

    lnComplex(y, ln, realContext);
    if (realIsNaN(&y.Real) or realIsNaN(&y.Imag)) {
        return;
    }

    if (realIsInfinite(&y.Real)) {
        if (realIsInfinite(&y.Imag)) {
            realCopy(if (realIsNegative(&y.Real)) pi3On4 else piOn4, &ln.Imag);
            if (realIsNegative(&y.Imag)) {
                realSetNegativeSign(&ln.Imag);
            }
        } else if (realIsPositive(&y.Real)) {
            realSetZero(&ln.Imag);
            if (realIsNegative(&y.Imag)) {
                realSetNegativeSign(&ln.Imag);
            }
        } else {
            realCopy(pi, &ln.Imag);
            if (realIsNegative(&y.Imag) and !realIsZero(&y.Imag)) {
                realSetNegativeSign(&ln.Imag);
            }
        }
    } else if (realIsInfinite(&y.Imag) or realIsZero(&y.Real)) {
        realCopy(piOn2, &ln.Imag);
        if (realIsNegative(&y.Imag)) {
            realSetNegativeSign(&ln.Imag);
        }
    } else if (realIsZero(&y.Imag)) {
        if (realIsNegative(&y.Real)) {
            realCopy(pi, &ln.Imag);
        } else {
            realSetZero(&ln.Imag);
            if (realIsNegative(&y.Imag)) {
                realSetNegativeSign(&ln.Imag);
            }
        }
    }
}

// Tests whether a phase is pi or pi/2 to the rounding of the working digits.
// A phase formed from pi/4 or pi/2 and X can miss the 75-digit pi or pi/2 in
// its last digits: twice pi/2 is one unit below pi. The bound is that of the
// test for -pi in cpxXthRoot. True when phase and axis differ by less than
// 1E(3 - digits).
fn phaseOnAxis(phase: *const real_t, axis: *const real_t, realContext: *realContext_t) linksection(runtime.code_section) bool {
    var difference: real_t = undefined;

    realSubtract(phase, axis, &difference, realContext);
    return realIsZero(&difference) or difference.exponent + difference.digits - 1 <= 2 - realContext.digits;
}

// ===========================================================================
// cpxXthRoot: find R such that R^X == Y
//
// Cases with no solution
// 1) X is pure imaginary and |yImag| > e^|xImag|, i.e. i-th root of 25i
// 2) xReal^2 + xImag^2 < |xReal|, also depending on Y being typically around
//    the negative real axis, i.e. the 0.5th root of -2
//
// exp(Log Y / X) is a root only when its imaginary part lands in [-pi, pi]. An
// r whose argument falls outside does NOT satisfy r^X = Y. Adding 2*pi*k to
// Arg Y before the division shifts Im into the strip when a suitable integer k
// exists -- and when no k does, Y has no X-th root.
//
// Im is linear in k, so the valid branches are exactly the integers in an
// interval. k = 0 is picked whenever it is valid (~99% of calls), otherwise the
// valid k closest to 0 is picked.
//
// The strip is tested CLOSED instead of the mathematically correct half-open
// ]-pi, pi]. Technically wrong, but it lets the X = -1 case through, and on the
// border of the roots' existence it may produce a wrong answer.
//
// If the residue cleanup below wants the result to be a negative real, i.e.
// -pi rad, it is not a possible root: xrooty(-5i, 0.5) is the 0.5th root of
// 5<-pi/2, which squares to 25<-pi; -pi is outside (-pi, pi], so add 2pi to get
// 25<+pi = -25, and -25^0.5 = 5i != -5i, so not a root.
//
// Returns true with the root in r; false when no such r exists.
// ===========================================================================
fn cpxXthRoot(y: *const cplx_t, x: *const cplx_t, r: *cplx_t, realContext: *realContext_t) linksection(runtime.code_section) bool {
    var x2: real_t = undefined;
    var k: real_t = undefined;
    var step: real_t = undefined;
    var lnY: cplx_t = undefined;
    var lnR: cplx_t = undefined;
    const wide = realContext.digits > 51;
    const pi: *const real_t = if (wide) const75_pi() else const39_pi();
    const piOn2: *const real_t = if (wide) const75_piOn2() else const39_piOn2();
    const pi2: *const real_t = if (wide) const75_2pi() else const39_2pi();

    if (realIsZero(&x.Real) and realIsZero(&x.Imag)) { // r^0 = 1 whatever r is
        if (realCompareEqual(&y.Real, const_1()) and realIsZero(&y.Imag)) {
            realSetOne(&r.Real);
            realSetZero(&r.Imag);
            return true;
        }
        return false;
    }

    if (realCompareEqual(&x.Real, const_1()) and realIsZero(&x.Imag) and !realIsNaN(&y.Real) and !realIsNaN(&y.Imag)) {
        realCopy(&y.Real, &r.Real);
        realCopy(&y.Imag, &r.Imag);
        return true;
    }

    if (realIsZero(&y.Real) and realIsZero(&y.Imag)) { // 0^X = 0 needs Re X > 0
        if (realCompareGreaterThan(&x.Real, const_0())) {
            realSetZero(&r.Real);
            realSetZero(&r.Imag);
            return true;
        }
        return false;
    }

    if (realCompareEqual(&x.Real, const__1()) and realIsZero(&x.Imag) and !realIsNaN(&y.Real) and !realIsNaN(&y.Imag)) {
        divRealComplex(const_1(), y, r, realContext);
        if (realIsZero(&y.Imag)) {
            realSetZero(&r.Imag);
        }
        return true;
    }

    if (realCompareAbsEqual(&x.Real, const_1on2()) and realIsZero(&x.Imag) and !realIsSpecial(&y.Real) and !realIsSpecial(&y.Imag)) {
        const positiveHalf = realIsPositive(&x.Real);

        if (!realCompareGreaterThan(&y.Real, const_0()) and
            !(realIsZero(&y.Real) and (if (positiveHalf) realCompareGreaterThan(&y.Imag, const_0()) else realCompareLessThan(&y.Imag, const_0()))))
        {
            return false;
        }
        mulComplexComplex(y, y, r, realContext);
        if (!positiveHalf) {
            divRealComplex(const_1(), r, r, realContext);
        }
        if (realIsZero(&r.Real)) {
            realSetZero(&r.Real);
        }
        if (realIsZero(&r.Imag)) {
            realSetZero(&r.Imag);
        }
        return true;
    }

    lnXthRootComplex(y, &lnY, realContext);
    realMultiply(&x.Real, &x.Real, &x2, realContext);
    realFMA(&x.Imag, &x.Imag, &x2, &x2, realContext); // |X|^2

    realMultiply(&x.Real, &lnY.Imag, &lnR.Imag, realContext);
    if (!realIsZero(&x.Imag)) { // a real X would make this 0*inf = NaN for an infinite Y
        realMultiply(&x.Imag, &lnY.Real, &lnR.Real, realContext);
        realSubtract(&lnR.Imag, &lnR.Real, &lnR.Imag, realContext);
    }
    realDivide(&lnR.Imag, &x2, &lnR.Imag, realContext); // Im(Log Y / X), branch 0

    if (realIsSpecial(&lnR.Imag)) {
        return false; // Arg r runs off: an infinite Y with a complex X, or NaN in
    }
    realSetZero(&k);

    if (realCompareAbsGreaterThan(&lnR.Imag, pi)) { // branch 0 is out
        if (realIsZero(&x.Real)) {
            return false; // Im does not depend on k
        }

        realCopyAbs(&x.Real, &step);
        realMultiply(&step, pi2, &step, realContext);
        realDivide(&step, &x2, &step, realContext); // k steps for Im

        // Steps to bring |Im| back to at most pi.
        realCopyAbs(&lnR.Imag, &k);
        realSubtract(&k, pi, &k, realContext);
        realDivide(&k, &step, &k, realContext);
        realToIntegralValue(&k, &k, runtime.DEC_ROUND_CEILING, realContext); // at least 1

        const imWasPositive = realIsPositive(&lnR.Imag);
        if (imWasPositive) {
            realChangeSign(&step);
        }
        realFMA(&k, &step, &lnR.Imag, &lnR.Imag, realContext);
        if (realCompareAbsGreaterThan(&lnR.Imag, pi)) {
            return false; // no k gives a valid root
        }

        if (imWasPositive == realIsPositive(&x.Real)) {
            realChangeSign(&k);
        }
        realMultiply(&k, pi2, &k, realContext); // k*2*pi
    }

    if (realIsNegative(&lnR.Imag) and realIsZero(&x.Imag) and !realIsAnInteger(&x.Real)) {
        realCopyAbs(&lnR.Imag, &step);
        realSubtract(pi, &step, &step, realContext);
        realSetPositiveSign(&step);
        if (realIsZero(&step) or step.exponent + step.digits - 1 <= 2 - realContext.digits) {
            return false;
        }
    }

    realAdd(&lnY.Imag, &k, &lnR.Real, realContext);
    realMultiply(&x.Imag, &lnR.Real, &lnR.Real, realContext);
    realFMA(&x.Real, &lnY.Real, &lnR.Real, &lnR.Real, realContext);
    realDivide(&lnR.Real, &x2, &lnR.Real, realContext); // Re(Log r)

    if (realIsInfinite(&lnR.Real)) {
        realPolarToRectangular(if (realIsPositive(&lnR.Real)) const_plusInfinity() else const_0(), &lnR.Imag, r, realContext);
    } else {
        expComplex(&lnR, r, realContext);
    }

    if (realIsZero(&lnR.Imag) and realIsZero(&r.Imag)) {
        realSetZero(&r.Imag);
        if (realIsNegative(&lnR.Imag)) {
            realSetNegativeSign(&r.Imag);
        }
    }
    if (realIsPositive(&y.Real) and realIsZero(&y.Imag) and realIsZero(&x.Imag) and realIsZero(&r.Imag)) {
        realSetZero(&r.Imag);
    }

    // Remove residue due to going through polar form and back
    realCopyAbs(&lnR.Imag, &k);
    if (phaseOnAxis(&k, pi, realContext)) {
        if (realIsNegative(&lnR.Imag) and !(realIsZero(&x.Imag) and realIsAnInteger(&x.Real))) {
            return false; // exp gives Arg r = +pi, so this r is not a root
        }
        realSetZero(&r.Imag);
    } else if (phaseOnAxis(&k, piOn2, realContext)) {
        realSetZero(&r.Real);
    }

    return true;
}

// ===========================================================================
// xthRootComplex: (a+ib) ^ (1/(c+id))
//
// Expecting Y = a + ib and X = c + id. REGISTER Y unchanged, REGISTER X with
// the result of (a+ib) ^ (1/(c+id)).
// ===========================================================================
fn xthRootComplex(y: *const cplx_t, x: *const cplx_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var r: cplx_t = undefined;

    // X = 0 is not tested here: cpxXthRoot does that.
    if (!getSystemFlag(FLAG_SPCRES) and (realIsNaN(&y.Real) or realIsNaN(&y.Imag) or realIsNaN(&x.Real) or realIsNaN(&x.Imag))) {
        convertComplexPartsToResultRegister(const_NaN(), const_NaN(), REGISTER_X);
        return;
    }

    if (cpxXthRoot(y, x, &r, realContext)) {
        if (realIsPositive(&y.Real) and realIsZero(&y.Imag) and realIsZero(&x.Imag) and realIsZero(&r.Imag)) {
            correctExactReal34Root(&y.Real, &x.Real, &r.Real);
        }
        convertComplexToResultRegister(&r, REGISTER_X);
        return;
    }

    // Y has no X-th root at all -- not "none on the branch we looked at". The
    // branches searched are branches of Log Y, and every one of them was ruled
    // out. This is a real answer, not a failure to compute: Y = (-8) with X = 0.5
    // asks for an R whose square root is -8, and no complex number has that.
    if (getSystemFlag(FLAG_SPCRES)) {
        if (getRegisterDataType(REGISTER_X) == dtComplex34 or getRegisterDataType(REGISTER_Y) == dtComplex34) {
            convertComplexPartsToResultRegister(const_NaN(), const_NaN(), REGISTER_X);
        } else {
            convertRealToResultRegister(const_NaN(), REGISTER_X, amNone); // real in, real NaN out
        }
    } else {
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE);
        moreInfoOnError("In function xthRootComplex:", "Y has no X-th root: no R satisfies R" ++ std_sup_x ++ " = Y", null, null);
    }
}

// ===========================================================================
// xthRootRealWithParity: y^(1/x)
//
// Expecting x, y. REGISTER Y unchanged, REGISTER X with the result of y^(1/x).
// integerParity is the parity of an integer X read exactly off its register
// (1 odd, 0 even), or -1 when X has to be examined as a real.
// ===========================================================================
fn xthRootRealWithParity(yy: *const real_t, xx: *const real_t, realContext: *realContext_t, integerParity: i32) linksection(runtime.code_section) void {
    var r: real_t = undefined;
    var o: real_t = undefined;
    var order: real_t = undefined;
    var x: real_t = undefined;
    var y: real_t = undefined;
    var haveResult = false;
    var orderIsInteger: bool = undefined;

    realCopy(xx, &x);
    realCopy(xx, &order);
    realCopy(yy, &y);
    if (integerParity >= 0) {
        orderIsInteger = true;
        int32ToReal(integerParity, &r);
    } else {
        orderIsInteger = realIsAnInteger(&x);
        realDivideRemainder(&x, const_2(), &r, realContext);
    }

    if (getSystemFlag(FLAG_SPCRES)) {
        //0
        if ((realIsZero(&y) and (realCompareGreaterEqual(&x, const_0()) or (realIsInfinite(&x) and realIsPositive(&x)))) or
            ((realIsInfinite(&y) and realIsPositive(&y)) and (realCompareLessThan(&x, const_0()) and !realIsInfinite(&x))))
        {
            haveResult = true;
            realSetZero(&o);
        }

        //1
        if ((realCompareGreaterEqual(&y, const_0()) or (realIsInfinite(&y) and realIsPositive(&y))) and realIsInfinite(&x)) {
            haveResult = true;
            realSetOne(&o);
        }

        //inf
        if (!realIsInfinite(&x) and // x finite, common to both cases
            ((realIsZero(&y) and realCompareLessThan(&x, const_0())) or // (y=0.)    AND (-inf < x < 0)
                ((realIsInfinite(&y) and realIsPositive(&y)) and realCompareGreaterEqual(&x, const_0())))) // (y=+inf)  AND (0 <= x < inf)
        {
            haveResult = true;
            realSetPlusInfinity(&o);
        }

        //NaN
        if ((realIsNaN(&x) or realIsNaN(&y)) or
            ((realCompareLessThan(&y, const_0()) or (realIsInfinite(&y) and realIsNegative(&y))) and realIsInfinite(&x)) or // (-inf <= y < 0)  AND (x =(inf or -inf))
            (realCompareLessThan(&y, const_0()) and !realIsInfinite(&y) and !orderIsInteger and !getFlag(FLAG_CPXRES)) or // (-inf < y < 0)  AND (x is non-integer)  AND no complex results allowed
            // with CPXRES set this falls through to xthRootComplex instead: a
            // negative base with a non-integer root order has a perfectly good
            // complex root whenever |x| >= 1, e.g. (-8) with x = 1.5
            ((realIsInfinite(&y) and realIsNegative(&y)) and (realIsZero(&r) and realCompareGreaterThan(&x, const_0())) and !getFlag(FLAG_CPXRES))) // (y=-inf) AND (x is even > 0) [zero r means x is a multiple of 2, so an even integer], which has a complex root when CPXRES is set
        {
            haveResult = true;
            realSetNaN(&o);
        }

        //-inf
        if ((realIsInfinite(&y) and realIsNegative(&y)) and (realCompareAbsEqual(&r, const_1()) and realCompareGreaterThan(&x, const_0()))) { // (y=-inf) AND (x is odd > 0) [r still holds x mod 2; only an odd integer leaves +-1]
            haveResult = true;
            realSetMinusInfinity(&o);
        }
    } else { // not DANGER
        if (realIsZero(&x)) {
            displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE);
            moreInfoOnError("In function xthRootReal: 0th Root is not defined!", null, null, null);
            return;
        }
        if (realIsNaN(&x) or realIsNaN(&y)) {
            haveResult = true;
            realSetNaN(&o);
        }
    }

    if (!haveResult) {
        const powerContext: *realContext_t = if (realContext.digits < 51) &runtime.ctxtReal51 else realContext; // y^(1/x) multiplies the error of 1/x by |ln y|, up to 14200

        if (realCompareEqual(&x, const_1())) {
            realCopy(&y, &o);
        } else if (realCompareEqual(&x, const__1())) {
            realDivide(const_1(), &y, &o, realContext);
        } else if (realIsPositive(&y)) { //positive base, no problem, get the power function y^(1/x)
            realDivide(const_1(), &x, &x, powerContext);
            math_power.PowerReal(&y, &x, &o, powerContext);
        } else {
            // negative base and odd exp: the root is real.
            if (orderIsInteger and realCompareAbsEqual(&r, const_1())) {
                realDivide(const_1(), &x, &x, powerContext);

                realSetPositiveSign(&y);
                math_power.PowerReal(&y, &x, &o, powerContext);
                realSetNegativeSign(&o);
            } else {
                // even exp, or neither odd nor even i.e. not integer: complex either way
                if (!getFlag(FLAG_CPXRES)) {
                    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE);
                    moreInfoOnError("In function xthRootReal:", "cannot do complex xthRoots when CPXRES is not set", null, null);
                    return;
                }
                var yc: cplx_t = undefined;
                var xc: cplx_t = undefined;

                realCopy(&y, &yc.Real);
                realSetZero(&yc.Imag);
                realCopy(&x, &xc.Real);
                realSetZero(&xc.Imag);
                xthRootComplex(&yc, &xc, &runtime.ctxtReal75);
                return;
            }
        }
    }

    if (realContext.digits == 39) {
        correctExactReal34Root(yy, &order, &o);
    }

    convertRealToResultRegister(&o, REGISTER_X, amNone);
}

pub export fn xthRootReal(yy: *const real_t, xx: *const real_t, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    xthRootRealWithParity(yy, xx, realContext, -1);
}

// The exact square root of a negative long integer, as the imaginary part of
// the complex result when CPXRES allows one; the reciprocal root carries the
// negative sign of 1/(i sqrt(n)).
fn exactNegativeLongIntegerSquareRoot(operand: *const mpz_struct, reciprocal: bool, result: *real34_t) linksection(runtime.code_section) bool {
    var magnitude: mpz_struct = undefined;

    if (!longIntegerIsNegative(operand) or !getFlag(FLAG_CPXRES)) {
        return false;
    }
    longIntegerInit(&magnitude);
    longIntegerCopy(operand, &magnitude);
    longIntegerSetPositiveSign(&magnitude);
    const ok = if (reciprocal) reciprocalRootLongIntegerToReal34(&magnitude, 2, result) else rootLongIntegerToReal34(&magnitude, 2, result);
    longIntegerFree(&magnitude);
    if (ok and reciprocal) {
        real34SetNegativeSign(result);
    }
    return ok;
}

// ===========================================================================
// doXthRootLonI: Y(long integer) ^ 1/X(long integer) ==> X(long integer)
// ===========================================================================
fn doXthRootLonI() linksection(runtime.code_section) callconv(.c) void {
    var x: real_t = undefined;
    var y: real_t = undefined;
    var exactRoot: real34_t = undefined;
    var reciprocal: real34_t = undefined;
    var base: mpz_struct = undefined;
    var exponent: mpz_struct = undefined;
    var l: mpz_struct = undefined;

    if (!getRegisterAsLongInt(REGISTER_Y, &base, null)) {
        longIntegerFree(&base);
        return;
    }
    defer longIntegerFree(&base);
    if (!getRegisterAsLongInt(REGISTER_X, &exponent, null)) {
        longIntegerFree(&exponent);
        return;
    }
    defer longIntegerFree(&exponent);

    if (longIntegerIsZero(&exponent) and !getSystemFlag(FLAG_SPCRES)) { // 1/0 is not possible
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE);
        moreInfoOnError("In function doXthRootLonI: Cannot divide by 0!", null, null, null);
        return;
    }

    if (longIntegerIsZero(&base) and longIntegerIsPositive(&exponent)) { //base=0 -->  0
        uInt32ToLongInteger(0, &base);
        convertLongIntegerToLongIntegerRegister(&base, REGISTER_X);
        return;
    }

    if (longIntegerCompareInt(&exponent, -1) == 0 and runtime.reciprocalLongIntegerRegisterToReal34(REGISTER_Y, &reciprocal)) {
        convertReal34ToReal34Register(&reciprocal, REGISTER_X);
        return;
    }

    if ((longIntegerCompareInt(&exponent, 2) == 0 or longIntegerCompareInt(&exponent, -2) == 0) and
        exactNegativeLongIntegerSquareRoot(&base, longIntegerIsNegative(&exponent), &exactRoot))
    {
        convertReal34ToComplex34Register(const34_0(), &exactRoot, REGISTER_X);
        return;
    }

    if ((longIntegerCompareInt(&exponent, -2) == 0 or longIntegerCompareInt(&exponent, -3) == 0 or longIntegerCompareInt(&exponent, -4) == 0) and
        reciprocalRootLongIntegerToReal34(&base, if (longIntegerCompareInt(&exponent, -2) == 0) 2 else if (longIntegerCompareInt(&exponent, -3) == 0) 3 else 4, &exactRoot))
    {
        convertReal34ToReal34Register(&exactRoot, REGISTER_X);
        return;
    }

    if (longIntegerIsPositive(&exponent) and longIntegerCompareUInt(&exponent, 2147483640) <= 0) {
        const exp = longIntegerToInt32(&exponent);
        if (longIntegerIsPositive(&base)) { // pos base
            longIntegerInit(&l);
            if (longIntegerRoot(&base, @intCast(exp), &l) != 0) { // if integer xthRoot found, return
                convertLongIntegerToLongIntegerRegister(&l, REGISTER_X);
                longIntegerFree(&l);
                return;
            }
            longIntegerFree(&l);
        } else {
            if (longIntegerIsNegative(&base)) { // neg base and even exponent
                if (longIntegerIsOdd(&exponent)) {
                    longIntegerChangeSign(&base);
                    longIntegerInit(&l);
                    if (longIntegerRoot(&base, @intCast(exp), &l) != 0) { // if negative integer xthRoot found, return
                        longIntegerChangeSign(&l);
                        convertLongIntegerToLongIntegerRegister(&l, REGISTER_X);
                        longIntegerFree(&l);
                        return;
                    }
                    longIntegerFree(&l);
                    longIntegerChangeSign(&base);
                }
            }
        }
        if (exp >= 2 and exp <= 4 and rootLongIntegerToReal34(&base, @intCast(exp), &exactRoot)) {
            convertReal34ToReal34Register(&exactRoot, REGISTER_X);
            return;
        }
    }

    if (!runtime.getRegisterAsReal(REGISTER_X, &x) or !runtime.getRegisterAsReal(REGISTER_Y, &y)) {
        return;
    }

    xthRootRealWithParity(&y, &x, &runtime.ctxtReal75, runtime.getRegisterIntegerParity(REGISTER_X));
}

// ===========================================================================
// doXthRootShoI: Y(short integer) ^ 1/X(short integer) ==> X(short integer)
// ===========================================================================
fn doXthRootShoI() linksection(runtime.code_section) callconv(.c) void {
    const base = getRegisterShortIntegerBase(REGISTER_Y);

    convertShortIntegerRegisterToLongIntegerRegister(REGISTER_X, REGISTER_X);
    convertShortIntegerRegisterToLongIntegerRegister(REGISTER_Y, REGISTER_Y);

    doXthRootLonI();

    if (getRegisterDataType(REGISTER_X) == dtLongInteger) {
        convertLongIntegerRegisterToShortIntegerRegister(REGISTER_X, REGISTER_X);
        setRegisterShortIntegerBase(REGISTER_X, base);
    }
}

// ===========================================================================
// doXthRootReal: Y(real34) ^ 1/X(real34) ==> X(real34)
// ===========================================================================
fn doXthRootReal() linksection(runtime.code_section) callconv(.c) void {
    var x: real_t = undefined;
    var y: real_t = undefined;
    var exactResult: real34_t = undefined;
    const x34 = runtime.registerReal34Ptr(REGISTER_X);

    if (getRegisterDataType(REGISTER_Y) == dtLongInteger and getRegisterDataType(REGISTER_X) == dtReal34 and
        (real34CompareAbsEqual(x34, const34_2()) or real34CompareAbsEqual(x34, const34_3()) or real34CompareAbsEqual(x34, const34_4())))
    {
        var operand: mpz_struct = undefined;
        const order: u32 = if (real34CompareAbsEqual(x34, const34_2())) 2 else if (real34CompareAbsEqual(x34, const34_3())) 3 else 4;

        runtime.convertLongIntegerRegisterToLongInteger(REGISTER_Y, &operand);
        const reciprocal = runtime.real34IsNegative(x34);
        const complexSquareRoot = order == 2 and exactNegativeLongIntegerSquareRoot(&operand, reciprocal, &exactResult);
        const exactRoot = complexSquareRoot or
            (if (reciprocal) reciprocalRootLongIntegerToReal34(&operand, order, &exactResult) else rootLongIntegerToReal34(&operand, order, &exactResult));
        longIntegerFree(&operand);
        if (exactRoot) {
            if (complexSquareRoot) {
                convertReal34ToComplex34Register(const34_0(), &exactResult, REGISTER_X);
            } else {
                convertReal34ToReal34Register(&exactResult, REGISTER_X);
            }
            return;
        }
    }

    if (!(getRegisterDataType(REGISTER_Y) == dtReal34 and runtime.real34IsInfinite(runtime.registerReal34Ptr(REGISTER_Y))) and
        runtime.registerIdentityExponentToReal34(REGISTER_Y, REGISTER_X, &exactResult))
    {
        convertReal34ToReal34Register(&exactResult, REGISTER_X);
        return;
    }

    if (getRegisterDataType(REGISTER_Y) == dtReal34 and runtime.real34IsZero(runtime.registerReal34Ptr(REGISTER_Y)) and
        runtime.real34IsNegative(runtime.registerReal34Ptr(REGISTER_Y)))
    {
        var signedZero: real34_t = undefined;

        if (!runtime.getRegisterAsReal(REGISTER_X, &x)) {
            return;
        }
        if (!realIsSpecial(&x) and realCompareGreaterThan(&x, const_0())) {
            real34Copy(runtime.registerReal34Ptr(REGISTER_Y), &signedZero);
            convertReal34ToReal34Register(&signedZero, REGISTER_X);
            return;
        }
    }

    if (!runtime.getRegisterAsReal(REGISTER_X, &x) or !runtime.getRegisterAsReal(REGISTER_Y, &y)) {
        return;
    }

    if ((realIsInfinite(&x) or realIsInfinite(&y)) and !getSystemFlag(FLAG_SPCRES)) {
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE);
        moreInfoOnError("In function doXthRootReal:", "cannot use " ++ std_plus_minus ++ std_infinity ++ " as X or Y input of xthRoot when flag SPCRES is not set", null, null);
        return;
    }

    xthRootRealWithParity(&y, &x, &runtime.ctxtReal39, runtime.getRegisterIntegerParity(REGISTER_X));
}

// ===========================================================================
// doXthRootCplx: Y(complex34) ^ 1/X(complex34) ==> X(complex34)
// ===========================================================================
fn doXthRootCplx() linksection(runtime.code_section) callconv(.c) void {
    var y: cplx_t = undefined;
    var x: cplx_t = undefined;

    if (!runtime.getRegisterAsComplex(REGISTER_Y, &y) or !runtime.getRegisterAsComplex(REGISTER_X, &x)) {
        return;
    }

    // An infinite Y used to answer inf + inf i whatever the direction. That is
    // only right for Arg Y = pi/4; crootComplex now derives the direction from
    // Arg Y like sqrt does. The 0th root of an infinity keeps its own answer.
    if ((realIsInfinite(&y.Real) or realIsInfinite(&y.Imag)) and realIsZero(&x.Real) and realIsZero(&x.Imag)) {
        convertComplexPartsToResultRegister(const_NaN(), const_NaN(), REGISTER_X);
        return;
    }

    xthRootComplex(&y, &x, &runtime.ctxtReal75);
}

// ===========================================================================
// fnXthRoot: regX ==> regL and regY ^ (1/regX) ==> regX
// Drops Y, enables stack lift and refreshes the stack
// ===========================================================================
pub export fn fnXthRoot(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var order: real_t = undefined;
    const preserveNegativeZero = getRegisterDataType(REGISTER_Y) == dtReal34 and
        runtime.real34IsZero(runtime.registerReal34Ptr(REGISTER_Y)) and
        runtime.real34IsNegative(runtime.registerReal34Ptr(REGISTER_Y)) and
        runtime.getRegisterAsRealQuiet(REGISTER_X, &order) and
        !realIsSpecial(&order) and
        realCompareGreaterThan(&order, const_0());

    runtime.processIntRealComplexDyadicFunction(&doXthRootReal, &doXthRootCplx, &doXthRootShoI, &doXthRootLonI);
    if (preserveNegativeZero and runtime.lastErrorCode == ERROR_NONE and getRegisterDataType(REGISTER_X) == dtReal34 and
        runtime.real34IsZero(runtime.registerReal34Ptr(REGISTER_X)))
    {
        real34SetNegativeSign(runtime.registerReal34Ptr(REGISTER_X));
    }
}
