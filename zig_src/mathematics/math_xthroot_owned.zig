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
// SAVE_SPACE_DM42_12 guard is dead on every z47 build, so the body is ported
// unconditionally.

const runtime = @import("math_command_wrappers_runtime.zig");

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
extern fn realExp(x: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn realSetPlusInfinity(value: *real_t) void;
extern fn realSetMinusInfinity(value: *real_t) void;
extern fn realCompareGreaterThan(number1: *const real_t, number2: *const real_t) bool;
extern fn realCompareGreaterEqual(number1: *const real_t, number2: *const real_t) bool;
extern fn decNumberCopy(res: *real_t, source: *const real_t) *real_t;
extern fn decNumberRemainder(res: *real_t, lhs: *const real_t, rhs: *const real_t, ctxt: *realContext_t) *real_t;
inline fn realCopy(source: *const real_t, destination: *real_t) void {
    _ = decNumberCopy(destination, source);
}
inline fn realDivideRemainder(operand1: *const real_t, operand2: *const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberRemainder(res, operand1, operand2, ctxt);
}
inline fn realIsPositive(source: *const real_t) bool {
    return (source.bits & 0x80) == 0x00;
}
inline fn realSetPositiveSign(source: *real_t) void {
    source.bits &= ~@as(@TypeOf(source.bits), 0x80);
}
inline fn realSetNegativeSign(source: *real_t) void {
    source.bits |= 0x80;
}

// Complex helpers.
extern fn divRealComplex(numer: *const real_t, denom_real: *const real_t, denom_imag: *const real_t, quotient_real: *real_t, quotient_imag: *real_t, real_context: *realContext_t) void;

// Cross-domain power helper (power.c owner).
extern fn PowerReal(y: *const real_t, x: *const real_t, res: *real_t, realContext: *realContext_t) void;

// Result-register conversions accepting *align(1) const (blob constants here).
extern fn convertRealToResultRegister(real: *align(1) const real_t, dest: runtime.calcRegister_t, angle_mode: angularMode_t) void;
extern fn convertComplexToResultRegister(real: *align(1) const real_t, imag: *align(1) const real_t, dest: runtime.calcRegister_t) void;
const angularMode_t = runtime.angularMode_t;

// ---------------------------------------------------------------------------
// GMP long integer (mpz).
// ---------------------------------------------------------------------------
const mp_limb_t = usize;
const mpz_struct = abi.Mpz;

extern fn @"__gmpz_init"(op: *mpz_struct) void;
extern fn @"__gmpz_clear"(op: *mpz_struct) void;
extern fn @"__gmpz_set_ui"(rop: *mpz_struct, op: c_ulong) void;
extern fn @"__gmpz_get_si"(op: *const mpz_struct) c_long;
extern fn @"__gmpz_cmp_ui"(op: *const mpz_struct, v: c_ulong) c_int;
extern fn @"__gmpz_root"(rop: *mpz_struct, op: *const mpz_struct, n: c_ulong) c_int;

inline fn longIntegerInit(op: *mpz_struct) void {
    @"__gmpz_init"(op);
}
inline fn longIntegerFree(op: *mpz_struct) void {
    @"__gmpz_clear"(op);
}
inline fn uInt32ToLongInteger(source: u32, destination: *mpz_struct) void {
    @"__gmpz_set_ui"(destination, source);
}
inline fn longIntegerToInt32(op: *const mpz_struct) i32 {
    return @truncate(@"__gmpz_get_si"(op));
}
inline fn longIntegerIsZero(op: *const mpz_struct) bool {
    return op._mp_size == 0;
}
inline fn longIntegerIsPositive(op: *const mpz_struct) bool {
    return op._mp_size > 0;
}
inline fn longIntegerIsNegative(op: *const mpz_struct) bool {
    return op._mp_size < 0;
}
inline fn longIntegerIsOdd(op: *const mpz_struct) bool {
    return op._mp_size != 0 and (op._mp_d[0] & 1) != 0;
}
inline fn longIntegerChangeSign(op: *mpz_struct) void {
    op._mp_size = -op._mp_size;
}
inline fn longIntegerCompareUInt(op: *const mpz_struct, u: u32) i32 {
    return @"__gmpz_cmp_ui"(op, u);
}
inline fn longIntegerRoot(op: *const mpz_struct, n: u32, result: *mpz_struct) i32 {
    return @"__gmpz_root"(result, op, n);
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
// xthRootComplex: (a+ib) ^ (1/(c+id))
// ===========================================================================
fn xthRootComplex(aa: *const real_t, bb: *const real_t, cc: *const real_t, dd: *const real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var theta: real_t = undefined;
    var a: real_t = undefined;
    var b: real_t = undefined;
    var c: real_t = undefined;
    var d: real_t = undefined;

    realCopy(aa, &a);
    realCopy(bb, &b);
    realCopy(cc, &c);
    realCopy(dd, &d);

    if (!getSystemFlag(FLAG_SPCRES)) {
        if (realIsZero(&c) and realIsZero(&d)) {
            displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnError("In function xthRootComplex: 0th Root is not defined!", null, null, null);
            return;
        } else {
            if (realIsNaN(&a) or realIsNaN(&b) or realIsNaN(&c) or realIsNaN(&d)) {
                convertComplexToResultRegister(const_NaN(), const_NaN(), REGISTER_X);
                return;
            }
        }
    }

    if (realIsZero(&a) and realIsZero(&b) and !realIsZero(&c)) {
        convertComplexToResultRegister(const_0(), const_0(), REGISTER_X);
        return;
    }

    divRealComplex(const_1(), &c, &d, &c, &d, realContext);

    // From power.c
    realRectangularToPolar(&a, &b, &a, &theta, realContext);
    WP34S_Ln(&a, &a, realContext);
    realMultiply(&a, &d, &b, realContext);
    realFMA(&theta, &c, &b, &b, realContext);
    realChangeSign(&theta);
    realMultiply(&a, &c, &a, realContext);
    realFMA(&theta, &d, &a, &a, realContext);
    realExp(&a, &c, realContext);
    realPolarToRectangular(const_1(), &b, &a, &b, realContext);
    realMultiply(&c, &b, &d, realContext);
    realMultiply(&c, &a, &c, realContext);

    convertComplexToResultRegister(&c, &d, REGISTER_X);
}

// ===========================================================================
// xthRootReal: y^(1/x)
// ===========================================================================
pub export fn xthRootReal(yy: *real_t, xx: *real_t, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    var r: real_t = undefined;
    var o: real_t = undefined;
    var x: real_t = undefined;
    var y: real_t = undefined;
    var telltale: u8 = undefined;

    realCopy(xx, &x);
    realCopy(yy, &y);

    telltale = 0;
    if (getSystemFlag(FLAG_SPCRES)) {
        //0
        if (((realIsZero(&y) and (realCompareGreaterEqual(&x, const_0()) or (realIsInfinite(&x) and realIsPositive(&x))))) or ((realIsInfinite(&y) and realIsPositive(&y)) and (realCompareLessThan(&x, const_0()) and (!realIsInfinite(&x))))) {
            telltale += 1;
            realSetZero(&o);
        }

        //1
        if (((realCompareGreaterEqual(&y, const_0()) or (realIsInfinite(&y) and realIsPositive(&y))) and realIsInfinite(&x))) {
            telltale += 2;
            realSetOne(&o);
        }

        //inf
        if ((realIsZero(&y) and (realCompareLessThan(&x, const_0()) and (!realIsInfinite(&x)))) or ((realIsInfinite(&y) and realIsPositive(&y)) and (realCompareGreaterEqual(&x, const_0()) and (!realIsInfinite(&x))))) {
            telltale += 4;
            realSetPlusInfinity(&o);
        }

        //NaN
        realDivideRemainder(&x, const_2(), &r, realContext);
        if ((realIsNaN(&x) or realIsNaN(&y)) or ((realCompareLessThan(&y, const_0()) or (realIsInfinite(&y) and realIsNegative(&y))) and (realIsInfinite(&x))) or ((realCompareLessThan(&y, const_0()) and (!realIsInfinite(&y)) and (!realIsAnInteger(&x)))) or ((realIsInfinite(&y) and realIsNegative(&y)) and (realIsZero(&r) and realCompareGreaterThan(&x, const_0()) and realIsAnInteger(&x)))) {
            telltale += 8;
            realSetNaN(&o);
        }

        //-inf
        realAdd(&x, const_1(), &r, realContext);
        realDivideRemainder(&r, const_2(), &r, realContext);
        if ((realIsInfinite(&y) and realIsNegative(&y)) and (realIsZero(&r) and realCompareGreaterThan(&x, const_0()) and realIsAnInteger(&x))) {
            telltale += 16;
            realSetMinusInfinity(&o);
        }

        if (telltale != 0) {
            convertRealToResultRegister(&o, REGISTER_X, amNone);
            return;
        }
    } else { // not DANGER
        if (realIsZero(&x)) {
            displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnError("In function xthRootReal: 0th Root is not defined!", null, null, null);
            return;
        } else {
            if (realIsNaN(&x) or realIsNaN(&y)) {
                convertRealToResultRegister(const_NaN(), REGISTER_X, amNone);
                return;
            }
        }
    }

    if (realIsPositive(&y)) { // positive base, no problem, get the power function y^(1/x)
        realDivide(const_1(), &x, &x, realContext);

        PowerReal(&y, &x, &x, realContext);
        convertRealToResultRegister(&x, REGISTER_X, amNone);
        return;
    } // fall through, but returned
    else {
        if (realIsNegative(&y)) {
            realDivideRemainder(&x, const_2(), &r, realContext);
            if (realIsZero(&r)) { // negative base and even exp
                if (!runtime.getFlag(FLAG_CPXRES)) {
                    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
                    moreInfoOnError("In function xthRootReal:", "cannot do complex xthRoots when CPXRES is not set", null, null);
                    return;
                } else {
                    xthRootComplex(&y, const_0(), &x, const_0(), realContext);
                }
            } // fall through after Root CC
            else {
                realAdd(&x, const_1(), &r, realContext);
                realDivideRemainder(&r, const_2(), &r, realContext);
                if (realIsZero(&r)) { // negative base and odd exp
                    realDivide(const_1(), &x, &x, realContext);

                    realSetPositiveSign(&y);
                    PowerReal(&y, &x, &x, realContext);
                    realSetNegativeSign(&x);

                    convertRealToResultRegister(&x, REGISTER_X, amNone);
                    return;
                } // fall though, but returned
                else { // neither odd nor even, i.e. not integer
                    if (!runtime.getFlag(FLAG_CPXRES)) {
                        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
                        moreInfoOnError("In function xthRootReal:", "cannot do complex xthRoots when CPXRES is not set", null, null);
                        return;
                    } else {
                        xthRootComplex(&y, const_0(), &x, const_0(), realContext);
                    }
                }
            } // fall through
        } else {
            if (realIsZero(&y)) {
                convertRealToResultRegister(if (realIsZero(&x)) const_NaN() else const_1(), REGISTER_X, amNone);
            } // fall through, but returned
        }
    }
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
        // goto end1
        longIntegerFree(&base);
        return;
    }
    if (!getRegisterAsLongInt(REGISTER_X, &exponent, null)) {
        // goto end2
        longIntegerFree(&exponent);
        longIntegerFree(&base);
        return;
    }

    if (longIntegerIsZero(&exponent)) { // 1/0 is not possible
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function doXthRootLonI: Cannot divide by 0!", null, null, null);
        // goto end2
        longIntegerFree(&exponent);
        longIntegerFree(&base);
        return;
    }

    if (longIntegerIsZero(&base)) { // base=0 -->  0
        uInt32ToLongInteger(0, &base);
        convertLongIntegerToLongIntegerRegister(&base, REGISTER_X);
        // goto end2
        longIntegerFree(&exponent);
        longIntegerFree(&base);
        return;
    }

    if (longIntegerCompareUInt(&base, 2147483640) == -1) {
        exp = longIntegerToInt32(&exponent);
        if (longIntegerIsPositive(&base)) { // pos base
            longIntegerInit(&l);
            if (longIntegerRoot(&base, @bitCast(exp), &l) != 0) { // if integer xthRoot found, return
                convertLongIntegerToLongIntegerRegister(&l, REGISTER_X);
                longIntegerFree(&l);
                // goto end2
                longIntegerFree(&exponent);
                longIntegerFree(&base);
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
                        // goto end2
                        longIntegerFree(&exponent);
                        longIntegerFree(&base);
                        return;
                    }
                    longIntegerFree(&l);
                }
            }
        }
    }

    if (!runtime.getRegisterAsReal(REGISTER_X, &x) or !runtime.getRegisterAsReal(REGISTER_Y, &y)) {
        // goto end2
        longIntegerFree(&exponent);
        longIntegerFree(&base);
        return;
    }

    xthRootReal(&y, &x, &runtime.ctxtReal75);

    // end2:
    longIntegerFree(&exponent);
    // end1:
    longIntegerFree(&base);
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
        moreInfoOnError("In function doXthRootReal:", "cannot use +-Infinity as X or Y input of xthRoot when flag D is not set", null, null);
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

    if (realIsInfinite(&a) or realIsInfinite(&b)) {
        if (realIsZero(&c) and realIsZero(&d)) {
            convertComplexToResultRegister(const_NaN(), const_NaN(), REGISTER_X);
        } else {
            convertComplexToResultRegister(const_plusInfinity(), const_plusInfinity(), REGISTER_X);
        }
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
