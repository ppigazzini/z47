// SPDX-License-Identifier: GPL-3.0-only
const abi = @import("abi");
const consts = abi.constants;
const const_NaN = consts.const_NaN;
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
const math_command_wrappers = @import("../command_wrappers.zig");
const math_comparison_reals = @import("../compare/comparison_reals.zig");
const math_division_cells = @import("../arithmetic/division_cells.zig");
const math_power = @import("power.zig");
const math_real_predicates = @import("../compare/real_predicates.zig");
const real_t = runtime.real_t;
const realContext_t = runtime.realContext_t;

const realMultiply = runtime.realMultiply;
const realDivide = runtime.realDivide;
const realAdd = runtime.realAdd;
const realFMA = runtime.realFMA;
const realIsZero = runtime.realIsZero;
const realIsNaN = runtime.realIsNaN;
const realIsNegative = runtime.realIsNegative;
const realIsInfinite = runtime.realIsInfinite;
const realIsAnInteger = runtime.realIsAnInteger;
const realSetNaN = runtime.realSetNaN;
const realSetZero = runtime.realSetZero;
const realSetOne = runtime.realSetOne;
const realChangeSign = runtime.realChangeSign;
const realRectangularToPolar = runtime.realRectangularToPolar;
const realPolarToRectangular = runtime.realPolarToRectangular;
const realCompareLessThan = runtime.realCompareLessThan;

const WP34S_Ln = runtime.WP34S_Ln;

const REGISTER_X = runtime.REGISTER_X;
const REGISTER_Y = runtime.REGISTER_Y;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN = runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN;
const amNone = runtime.amNone;
const dtLongInteger = runtime.dtLongInteger;
const FLAG_SPCRES: i32 = 0x8017;
const FLAG_CPXRES: u16 = 0x8004;

const displayCalcErrorMessage = runtime.displayCalcErrorMessage;
const moreInfoOnError = runtime.moreInfoOnError;
const getSystemFlag = runtime.getSystemFlag;

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

// Blob-offset constants without a runtime accessor.

// real ops / predicates / copy. Some are C macros; reproduce them.
extern fn realSetPlusInfinity(value: *real_t) void;
extern fn realSetMinusInfinity(value: *real_t) void;
extern fn decNumberCopy(res: *real_t, source: *const real_t) *real_t;
extern fn decNumberRemainder(res: *real_t, lhs: *const real_t, rhs: *const real_t, ctxt: *realContext_t) *real_t;
inline fn realCopy(source: *const real_t, destination: *real_t) void {
    _ = decNumberCopy(destination, source);
}
inline fn realDivideRemainder(operand1: *const real_t, operand2: *const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberRemainder(res, operand1, operand2, ctxt);
}
extern fn decNumberCopyAbs(res: *real_t, source: *const real_t) *real_t;
inline fn realCopyAbs(source: *const real_t, destination: *real_t) void {
    _ = decNumberCopyAbs(destination, source);
}
const realIsPositive = math_real_predicates.realIsPositive;
inline fn realSetPositiveSign(source: *real_t) void {
    source.bits &= ~@as(@TypeOf(source.bits), 0x80);
}
inline fn realSetNegativeSign(source: *real_t) void {
    source.bits |= 0x80;
}

// Complex helpers.
const lnComplex = runtime.lnComplex;
const expComplex = math_command_wrappers.expComplex;

// Cross-domain power helper (power.c owner).

// Result-register conversions accepting *align(1) const (blob constants here).
extern fn convertRealToResultRegister(real: *align(1) const real_t, dest: runtime.calcRegister_t, angle_mode: angularMode_t) void;
extern fn convertComplexToResultRegister(real: *align(1) const real_t, imag: *align(1) const real_t, dest: runtime.calcRegister_t) void;
const angularMode_t = runtime.angularMode_t;

// ---------------------------------------------------------------------------
// GMP long integer (mpz).
// ---------------------------------------------------------------------------
const mp_limb_t = usize;
const mpz_struct = abi.Mpz;

extern fn __gmpz_init(op: *mpz_struct) void;
extern fn __gmpz_clear(op: *mpz_struct) void;
extern fn __gmpz_set_ui(rop: *mpz_struct, op: c_ulong) void;
extern fn __gmpz_get_si(op: *const mpz_struct) c_long;
extern fn __gmpz_cmp_ui(op: *const mpz_struct, v: c_ulong) c_int;
extern fn __gmpz_root(rop: *mpz_struct, op: *const mpz_struct, n: c_ulong) c_int;

inline fn longIntegerInit(op: *mpz_struct) void {
    __gmpz_init(op);
}
inline fn longIntegerFree(op: *mpz_struct) void {
    __gmpz_clear(op);
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
inline fn longIntegerCompareUInt(op: *const mpz_struct, u: u32) i32 {
    return __gmpz_cmp_ui(op, u);
}
inline fn longIntegerRoot(op: *const mpz_struct, n: u32, result: *mpz_struct) i32 {
    return __gmpz_root(result, op, n);
}

// Declared against the local mpz_struct (identical ABI; just a pointer).
extern fn convertLongIntegerToLongIntegerRegister(long_integer: *const mpz_struct, regist: runtime.calcRegister_t) void;
extern fn getRegisterAsLongInt(reg: runtime.calcRegister_t, val: *mpz_struct, fractional: ?*bool) bool;

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
// Returns true with r in rReal/rImag; false when no such r exists.
// ===========================================================================
fn cpxXthRoot(yReal: *const real_t, yImag: *const real_t, xReal: *const real_t, xImag: *const real_t, rReal: *real_t, rImag: *real_t, realContext: *realContext_t) linksection(runtime.code_section) bool {
    var x2: real_t = undefined;
    var lnYReal: real_t = undefined;
    var lnYImag: real_t = undefined;
    var lnRReal: real_t = undefined;
    var lnRImag: real_t = undefined;
    var k: real_t = undefined;
    var step: real_t = undefined;

    if (realIsZero(xReal) and realIsZero(xImag)) { // r^0 = 1 whatever r is
        if (runtime.realCompareEqual(yReal, const_1()) and realIsZero(yImag)) {
            realSetOne(rReal);
            realSetZero(rImag);
            return true;
        }
        return false;
    }

    if (realIsZero(yReal) and realIsZero(yImag)) { // 0^X = 0 needs Re X > 0
        if (math_comparison_reals.realCompareGreaterThan(xReal, const_0())) {
            realSetZero(rReal);
            realSetZero(rImag);
            return true;
        }
        return false;
    }

    lnComplex(yReal, yImag, &lnYReal, &lnYImag, realContext);
    realMultiply(xReal, xReal, &x2, realContext);
    realFMA(xImag, xImag, &x2, &x2, realContext); // |X|^2

    realMultiply(xReal, &lnYImag, &lnRImag, realContext);
    if (!realIsZero(xImag)) { // a real X would make this 0*inf = NaN for an infinite Y
        realMultiply(xImag, &lnYReal, &lnRReal, realContext);
        runtime.realSubtract(&lnRImag, &lnRReal, &lnRImag, realContext);
    }
    realDivide(&lnRImag, &x2, &lnRImag, realContext); // Im(Log Y / X), branch 0

    if (runtime.realIsSpecial(&lnRImag)) {
        return false; // Arg r runs off: an infinite Y with a complex X, or NaN in
    }
    realSetZero(&k);

    if (runtime.realCompareAbsGreaterThan(&lnRImag, consts.const39_pi())) { // branch 0 is out
        if (realIsZero(xReal)) {
            return false; // Im does not depend on k
        }

        realCopyAbs(xReal, &step);
        realMultiply(&step, consts.const39_2pi(), &step, realContext);
        realDivide(&step, &x2, &step, realContext); // k steps for Im

        // Steps to bring |Im| back to at most pi.
        realCopyAbs(&lnRImag, &k);
        runtime.realSubtract(&k, consts.const39_pi(), &k, realContext);
        realDivide(&k, &step, &k, realContext);
        runtime.realToIntegralValue(&k, &k, runtime.DEC_ROUND_CEILING, realContext); // at least 1

        const imWasPositive = realIsPositive(&lnRImag);
        if (imWasPositive) {
            realChangeSign(&step);
        }
        realFMA(&k, &step, &lnRImag, &lnRImag, realContext);
        if (runtime.realCompareAbsGreaterThan(&lnRImag, consts.const39_pi())) {
            return false; // no k gives a valid root
        }

        if (imWasPositive == realIsPositive(xReal)) {
            realChangeSign(&k);
        }
        realMultiply(&k, consts.const39_2pi(), &k, realContext); // k*2*pi
    }

    realAdd(&lnYImag, &k, &lnRReal, realContext);
    realMultiply(xImag, &lnRReal, &lnRReal, realContext);
    realFMA(xReal, &lnYReal, &lnRReal, &lnRReal, realContext);
    realDivide(&lnRReal, &x2, &lnRReal, realContext); // Re(Log r)

    if (realIsInfinite(&lnRReal)) {
        realPolarToRectangular(if (realIsPositive(&lnRReal)) const_plusInfinity() else const_0(), &lnRImag, rReal, rImag, realContext);
    } else {
        expComplex(&lnRReal, &lnRImag, rReal, rImag, realContext);
    }

    // Remove residue due to going through polar form and back
    realCopyAbs(&lnRImag, &k);
    if (runtime.realCompareEqual(&k, consts.const39_pi())) {
        if (realIsNegative(&lnRImag) and !(realIsZero(xImag) and realIsAnInteger(xReal))) {
            return false; // exp gives Arg r = +pi, so this r is not a root
        }
        realSetZero(rImag);
    } else if (runtime.realCompareEqual(&k, consts.const39_piOn2())) {
        realSetZero(rReal);
    }

    return true;
}

// ===========================================================================
// xthRootComplex: (a+ib) ^ (1/(c+id))
// ===========================================================================
fn xthRootComplex(aa: *const real_t, bb: *const real_t, cc: *const real_t, dd: *const real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var rReal: real_t = undefined;
    var rImag: real_t = undefined;

    // X = 0 is not tested here: cpxXthRoot does that.
    if (!getSystemFlag(FLAG_SPCRES) and (realIsNaN(aa) or realIsNaN(bb) or realIsNaN(cc) or realIsNaN(dd))) {
        convertComplexToResultRegister(const_NaN(), const_NaN(), REGISTER_X);
        return;
    }

    if (cpxXthRoot(aa, bb, cc, dd, &rReal, &rImag, realContext)) {
        convertComplexToResultRegister(&rReal, &rImag, REGISTER_X);
        return;
    }

    // Y has no X-th root at all -- not "none on the branch we looked at". The
    // branches searched are branches of Log Y, and every one of them was ruled
    // out. This is a real answer, not a failure to compute: Y = (-8) with
    // X = 0.5 asks for an R whose square root is -8, and no complex number has
    // that.
    if (getSystemFlag(FLAG_SPCRES)) {
        if (runtime.getRegisterDataType(REGISTER_X) == runtime.dtComplex34 or runtime.getRegisterDataType(REGISTER_Y) == runtime.dtComplex34) {
            convertComplexToResultRegister(const_NaN(), const_NaN(), REGISTER_X);
        } else {
            convertRealToResultRegister(const_NaN(), REGISTER_X, amNone); // real in, real NaN out
        }
    } else {
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function xthRootComplex:", "Y has no X-th root: no R satisfies R" ++ std_sup_x ++ " = Y", null, null);
    }
}

// ===========================================================================
// xthRootReal: y^(1/x)
// ===========================================================================
pub export fn xthRootReal(yy: *const real_t, xx: *const real_t, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    var r: real_t = undefined;
    var o: real_t = undefined;
    var x: real_t = undefined;
    var y: real_t = undefined;
    var haveResult = false;

    realCopy(xx, &x);
    realCopy(yy, &y);

    if (getSystemFlag(FLAG_SPCRES)) {
        //0
        if (((realIsZero(&y) and (math_comparison_reals.realCompareGreaterEqual(&x, const_0()) or (realIsInfinite(&x) and realIsPositive(&x))))) or ((realIsInfinite(&y) and realIsPositive(&y)) and (realCompareLessThan(&x, const_0()) and (!realIsInfinite(&x))))) {
            haveResult = true;
            realSetZero(&o);
        }

        //1
        if (((math_comparison_reals.realCompareGreaterEqual(&y, const_0()) or (realIsInfinite(&y) and realIsPositive(&y))) and realIsInfinite(&x))) {
            haveResult = true;
            realSetOne(&o);
        }

        //inf
        if ((!realIsInfinite(&x)) // x finite, common to both cases
        and ((realIsZero(&y) and realCompareLessThan(&x, const_0())) // (y=0.)    AND (-inf < x < 0)
            or ((realIsInfinite(&y) and realIsPositive(&y)) and math_comparison_reals.realCompareGreaterEqual(&x, const_0())))) // (y=+inf)  AND (0 <= x < inf)
        {
            haveResult = true;
            realSetPlusInfinity(&o);
        }

        //NaN
        realDivideRemainder(&x, const_2(), &r, realContext);
        // With CPXRES set a negative base with a non-integer root order falls through to
        // xthRootComplex instead: it has a perfectly good complex root whenever |x| >= 1,
        // e.g. (-8) with x = 1.5. Same for (y=-inf) with an even x > 0.
        if ((realIsNaN(&x) or realIsNaN(&y)) or ((realCompareLessThan(&y, const_0()) or (realIsInfinite(&y) and realIsNegative(&y))) and (realIsInfinite(&x))) or ((realCompareLessThan(&y, const_0()) and (!realIsInfinite(&y)) and (!realIsAnInteger(&x)) and (!runtime.getFlag(FLAG_CPXRES)))) or ((realIsInfinite(&y) and realIsNegative(&y)) and (realIsZero(&r) and math_comparison_reals.realCompareGreaterThan(&x, const_0())) and !runtime.getFlag(FLAG_CPXRES))) {
            haveResult = true;
            realSetNaN(&o);
        }

        //-inf
        // r still holds x mod 2; only an odd integer leaves +-1
        if ((realIsInfinite(&y) and realIsNegative(&y)) and (runtime.realCompareAbsEqual(&r, const_1()) and math_comparison_reals.realCompareGreaterThan(&x, const_0()))) {
            haveResult = true;
            realSetMinusInfinity(&o);
        }
    } else { // not DANGER
        if (realIsZero(&x)) {
            displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnError("In function xthRootReal: 0th Root is not defined!", null, null, null);
            return;
        }
        if (realIsNaN(&x) or realIsNaN(&y)) {
            haveResult = true;
            realSetNaN(&o);
        }
    }

    if (!haveResult) {
        if (realIsPositive(&y)) { // positive base, no problem, get the power function y^(1/x)
            realDivide(const_1(), &x, &x, realContext);
            math_power.PowerReal(&y, &x, &o, realContext);
        } else {
            // negative base and odd exp: the root is real.
            realDivideRemainder(&x, const_2(), &r, realContext);
            if (runtime.realCompareAbsEqual(&r, const_1())) {
                realDivide(const_1(), &x, &x, realContext);

                realSetPositiveSign(&y);
                math_power.PowerReal(&y, &x, &o, realContext);
                realSetNegativeSign(&o);
            } else {
                // even exp, or neither odd nor even i.e. not integer: complex either way
                if (!runtime.getFlag(FLAG_CPXRES)) {
                    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
                    moreInfoOnError("In function xthRootReal:", "cannot do complex xthRoots when CPXRES is not set", null, null);
                    return;
                }
                xthRootComplex(&y, const_0(), &x, const_0(), realContext);
                return;
            }
        }
    }

    convertRealToResultRegister(&o, REGISTER_X, amNone);
}

// ===========================================================================
// doXthRootLonI: Y(long integer) ^ 1/X(long integer)
// ===========================================================================
fn doXthRootLonI() linksection(runtime.code_section) callconv(.c) void {
    var x: real_t = undefined;
    var y: real_t = undefined;
    var base: mpz_struct = undefined;
    var exponent: mpz_struct = undefined;
    var l: mpz_struct = undefined;
    var exp: i32 = undefined;

    if (!getRegisterAsLongInt(REGISTER_Y, &base, null)) {
        longIntegerFree(&base);
        return;
    }
    // defer replaces the end1/end2 goto-cleanup in matching LIFO order (exponent
    // then base); the getRegisterAsLongInt init-then-fail paths keep an explicit
    // free before the defer is registered so there is no double-free. `l` stays
    // manually managed -- it is scoped to the root-check blocks.
    defer longIntegerFree(&base);
    if (!getRegisterAsLongInt(REGISTER_X, &exponent, null)) {
        longIntegerFree(&exponent);
        return;
    }
    defer longIntegerFree(&exponent);

    if (longIntegerIsZero(&exponent)) { // 1/0 is not possible
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function doXthRootLonI: Cannot divide by 0!", null, null, null);
        return;
    }

    if (longIntegerIsZero(&base)) { // base=0 -->  0
        uInt32ToLongInteger(0, &base);
        convertLongIntegerToLongIntegerRegister(&base, REGISTER_X);
        return;
    }

    if (longIntegerCompareUInt(&base, 2147483640) == -1) {
        exp = longIntegerToInt32(&exponent);
        if (longIntegerIsPositive(&base)) { // pos base
            longIntegerInit(&l);
            if (longIntegerRoot(&base, @bitCast(exp), &l) != 0) { // if integer xthRoot found, return
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
                    if (longIntegerRoot(&base, @bitCast(exp), &l) != 0) { // if negative integer xthRoot found, return
                        longIntegerChangeSign(&l);
                        convertLongIntegerToLongIntegerRegister(&l, REGISTER_X);
                        longIntegerFree(&l);
                        return;
                    }
                    longIntegerFree(&l);
                }
            }
        }
    }

    if (!runtime.getRegisterAsReal(REGISTER_X, &x) or !runtime.getRegisterAsReal(REGISTER_Y, &y)) {
        return;
    }

    xthRootReal(&y, &x, &runtime.ctxtReal75);
}

// ===========================================================================
// doXthRootShoI: Y(short integer) ^ 1/X(short integer)
// ===========================================================================
fn doXthRootShoI() linksection(runtime.code_section) callconv(.c) void {
    const base: u32 = getRegisterShortIntegerBase(REGISTER_Y);

    convertShortIntegerRegisterToLongIntegerRegister(REGISTER_X, REGISTER_X);
    convertShortIntegerRegisterToLongIntegerRegister(REGISTER_Y, REGISTER_Y);

    doXthRootLonI();

    if (runtime.getRegisterDataType(REGISTER_X) == dtLongInteger) {
        convertLongIntegerRegisterToShortIntegerRegister(REGISTER_X, REGISTER_X);
        setRegisterShortIntegerBase(REGISTER_X, base);
    }
}

// ===========================================================================
// doXthRootReal: Y(real34) ^ 1/X(real34)
// ===========================================================================
fn doXthRootReal() linksection(runtime.code_section) callconv(.c) void {
    var x: real_t = undefined;
    var y: real_t = undefined;

    if (!runtime.getRegisterAsReal(REGISTER_X, &x) or !runtime.getRegisterAsReal(REGISTER_Y, &y)) {
        return;
    }

    if ((realIsInfinite(&x) or realIsInfinite(&y)) and !getSystemFlag(FLAG_SPCRES)) {
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function doXthRootReal:", "cannot use " ++ std_plus_minus ++ std_infinity ++ " as X or Y input of xthRoot when flag SPCRES is not set", null, null);
        return;
    }

    xthRootReal(&y, &x, &runtime.ctxtReal39);
}

// ===========================================================================
// doXthRootCplx: Y(complex34) ^ 1/X(complex34)
// ===========================================================================
fn doXthRootCplx() linksection(runtime.code_section) callconv(.c) void {
    var a: real_t = undefined;
    var b: real_t = undefined;
    var c: real_t = undefined;
    var d: real_t = undefined;

    if (!runtime.getRegisterAsComplex(REGISTER_Y, &a, &b) or !runtime.getRegisterAsComplex(REGISTER_X, &c, &d)) {
        return;
    }

    // An infinite Y used to answer inf + inf i whatever the direction. That is
    // only right for Arg Y = pi/4; crootComplex now derives the direction from
    // Arg Y like sqrt does. The 0th root of an infinity keeps its own answer.
    if ((realIsInfinite(&a) or realIsInfinite(&b)) and realIsZero(&c) and realIsZero(&d)) {
        convertComplexToResultRegister(const_NaN(), const_NaN(), REGISTER_X);
        return;
    }

    xthRootComplex(&a, &b, &c, &d, &runtime.ctxtReal39);
}

// ===========================================================================
// fnXthRoot
// ===========================================================================
pub export fn fnXthRoot(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    runtime.processIntRealComplexDyadicFunction(&doXthRootReal, &doXthRootCplx, &doXthRootShoI, &doXthRootLonI);
}
