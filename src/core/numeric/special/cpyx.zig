// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/mathematics/cpyx.c: combinations C(y, x) and
// permutations P(y, x) over long integer / short integer / real / complex
// operands. Faithful line-by-line translation preserving the exact order of
// every real_t operation (cyx.txt / pyx.txt check results to the last ULP).
// Exports fnCyx, fnPyx and logCyxReal with C linkage; the static dispatch
// helpers stay private. EXTRA_INFO_MESSAGE hints become fixed moreInfoOnError
// strings (no-op under TESTSUITE/DMCP).

const runtime = @import("../command_wrappers/runtime.zig");
const math_real_predicates = @import("../compare/real_predicates.zig");
const math_comparison_reals = @import("../compare/comparison_reals.zig");
const math_ln_complex = @import("../ln_complex.zig");
const math_lnbeta = @import("lnbeta.zig");
const math_transcendental = @import("transcendental_command.zig");
const math_wp34s = @import("wp34s.zig");
const real_t = runtime.real_t;
const cplx_t = runtime.cplx_t;
const realContext_t = runtime.realContext_t;
const mpz_struct = runtime.mpz_struct;
const calcRegister_t = runtime.calcRegister_t;

const realAdd = runtime.realAdd;
const realSubtract = runtime.realSubtract;
const realIsAnInteger = runtime.realIsAnInteger;
const realIsNegative = runtime.realIsNegative;
const realIsSpecial = runtime.realIsSpecial;
const realIsInfinite = runtime.realIsInfinite;
const realIsZero = runtime.realIsZero;
const realChangeSign = runtime.realChangeSign;
const realToIntegralValue = runtime.realToIntegralValue;
const DEC_ROUND_HALF_UP = runtime.DEC_ROUND_HALF_UP;

const REGISTER_X = runtime.REGISTER_X;
const REGISTER_Y = runtime.REGISTER_Y;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const ERROR_OUT_OF_RANGE = runtime.ERROR_OUT_OF_RANGE;
const FLAG_OVERFLOW = runtime.FLAG_OVERFLOW;
const FLAG_SPCRES = runtime.FLAG_SPCRES;
const amNone = runtime.amNone;

const displayCalcErrorMessage = runtime.displayCalcErrorMessage;
const moreInfoOnError = runtime.moreInfoOnError;

// defines.h:1855-1856
const CP_PERMUTATION: u16 = 0;
const CP_COMBINATION: u16 = 1;

inline fn const_0() *const real_t {
    return runtime.z47_math_wrappers_const_0();
}
inline fn const_1() *const real_t {
    return runtime.z47_math_wrappers_const_1();
}
inline fn realCopy(source: *const real_t, destination: *real_t) void {
    destination.* = source.*;
}
const realIsPositive = math_real_predicates.realIsPositive;

// Long integer <-> real / register conversions.
extern fn convertLongIntegerToReal(source: *mpz_struct, destination: *real_t, ctxt: *realContext_t) void;
extern fn convertRealToLongInteger(real: *const real_t, lgInt: *mpz_struct, mode: c_int) void;
extern fn convertLongIntegerToLongIntegerRegister(lgInt: *const mpz_struct, regist: calcRegister_t) void;
extern fn convertLongIntegerToShortIntegerRegister(lgInt: *const mpz_struct, base: u32, regist: calcRegister_t) void;
extern fn convertShortIntegerRegisterToLongInteger(reg: calcRegister_t, lgInt: *mpz_struct) void;

// GMP / long integer helpers (longIntegerType.h inlines / macros).
extern fn __gmpz_cmp_si(op: *const mpz_struct, v: c_long) c_int;
extern fn __gmpz_set(rop: *mpz_struct, op: *const mpz_struct) void;

inline fn longIntegerInit(op: *mpz_struct) void {
    runtime.__gmpz_init(op);
}
inline fn longIntegerFree(op: *mpz_struct) void {
    runtime.__gmpz_clear(op);
}
inline fn longIntegerCopy(source: *const mpz_struct, destination: *mpz_struct) void {
    __gmpz_set(destination, source);
}
inline fn uInt32ToLongInteger(source: u32, destination: *mpz_struct) void {
    runtime.__gmpz_set_ui(destination, source);
}
inline fn longIntegerToUInt32(op: *const mpz_struct) u32 {
    // c_ulong is 32-bit on Win64 LLP64; truncate directly (a @bitCast to a
    // fixed-width usize would size-mismatch there).
    return @truncate(runtime.__gmpz_get_ui(op));
}
inline fn longIntegerCompareInt(op: *const mpz_struct, v: i32) i32 {
    return __gmpz_cmp_si(op, v);
}
inline fn longIntegerCompare(op1: *const mpz_struct, op2: *const mpz_struct) i32 {
    return runtime.__gmpz_cmp(op1, op2);
}
inline fn longIntegerAddUInt(op: *const mpz_struct, u: u32, result: *mpz_struct) void {
    runtime.__gmpz_add_ui(result, op, u);
}
inline fn longIntegerSubtractUInt(op: *const mpz_struct, u: u32, result: *mpz_struct) void {
    runtime.__gmpz_sub_ui(result, op, u);
}
inline fn longIntegerDivideUInt(op: *const mpz_struct, u: u32, result: *mpz_struct) void {
    _ = runtime.__gmpz_tdiv_q_ui(result, op, u);
}
const longIntegerIsNegative = math_real_predicates.longIntegerIsNegative;

inline fn getRegisterShortIntegerBase(reg: calcRegister_t) u32 {
    return runtime.getRegisterShortIntegerBase(reg);
}

// EXTRA_INFO_MESSAGE (defines.h): the macro prints three console lines -- the
// fixed "In function " prefix, the function name, then the message -- and is
// compiled out on the firmware and under the testSuite.
fn extraInfoMessage(function_name: [*:0]const u8, message: [*:0]const u8) void {
    if (runtime.extra_info_on_calc_error) {
        runtime.moreInfoOnError("In function ", function_name, message, null);
    }
}

pub export fn logCyxReal(y: *real_t, x: *real_t, result: *real_t, realContext: *realContext_t) callconv(.c) void {
    realSubtract(y, x, result, realContext);
    realAdd(result, const_1(), result, realContext);
    math_wp34s.WP34S_LnGamma(result, result, realContext); // r = ln((y-x)!)

    realAdd(x, const_1(), x, realContext);
    math_wp34s.WP34S_LnGamma(x, x, realContext); // x = ln(x!)

    realAdd(y, const_1(), y, realContext);
    math_wp34s.WP34S_LnGamma(y, y, realContext); // y = ln(y!)

    realSubtract(y, result, result, realContext);
    realSubtract(result, x, result, realContext); // r = ln(y!) - ln((y-x)!) - ln(x!)
}

// log(C(y,x)) for finite 0 <= x <= y. The beta form avoids subtraction between
// log-Gamma values of size proportional to y.
fn logCyxPositiveReal(y: *const real_t, x: *const real_t, result: *real_t, realContext: *realContext_t) void {
    var a: real_t = undefined;
    var b: real_t = undefined;
    var logBeta: real_t = undefined;
    var t: real_t = undefined;

    realAdd(x, const_1(), &a, realContext);
    realSubtract(y, x, &b, realContext);
    realAdd(&b, const_1(), &b, realContext);
    math_lnbeta.C47_LnBetaPositiveReal(&a, &b, &logBeta);

    realAdd(y, const_1(), &t, realContext);
    math_wp34s.WP34S_Ln(&t, &t, &runtime.ctxtReal75);
    realAdd(&t, &logBeta, result, realContext);
    realChangeSign(result);
}

// log(P(y,x)) for finite 0 <= x <= y.
fn logPyxPositiveReal(y: *const real_t, x: *const real_t, result: *real_t, realContext: *realContext_t) void {
    var xPlusOne: real_t = undefined;
    var logGamma: real_t = undefined;

    logCyxPositiveReal(y, x, result, realContext);
    realAdd(x, const_1(), &xPlusOne, realContext);
    math_wp34s.WP34S_LnGamma(&xPlusOne, &logGamma, &runtime.ctxtReal75);
    realAdd(result, &logGamma, result, realContext);
}

fn cyxReal(y: *real_t, x: *real_t, result: *real_t, realContext: *realContext_t) void {
    const inputAreIntegers = (realIsAnInteger(x) and realIsAnInteger(y));

    logCyxPositiveReal(y, x, result, realContext);

    math_transcendental.realExp(result, result, realContext); // r = y! / ((y-x)! x x!)

    if (inputAreIntegers and !realIsAnInteger(result)) {
        realToIntegralValue(result, result, DEC_ROUND_HALF_UP, realContext);
    }
}

fn cyxLong(y: *mpz_struct, x: *mpz_struct, result: *mpz_struct) void {
    if (longIntegerCompareInt(x, 0) == 0) {
        uInt32ToLongInteger(1, result);
    } else if (longIntegerCompareInt(x, 400) <= 0) {
        var loops: u32 = undefined;
        var counter: u32 = undefined;

        loops = longIntegerToUInt32(x);
        loops -%= 1;
        longIntegerSubtractUInt(y, loops, result);
        longIntegerCopy(result, y);
        counter = 1;
        while (counter <= loops) {
            counter += 1;
            longIntegerAddUInt(y, 1, y);
            runtime.longIntegerMultiply(result, y, result);
            longIntegerDivideUInt(result, counter, result);
        }
    } else {
        var xReal: real_t = undefined;
        var yReal: real_t = undefined;
        var resultReal: real_t = undefined;

        convertLongIntegerToReal(x, &xReal, &runtime.ctxtReal75);
        convertLongIntegerToReal(y, &yReal, &runtime.ctxtReal75);

        realSubtract(&yReal, &xReal, &resultReal, &runtime.ctxtReal75);
        realAdd(&resultReal, const_1(), &resultReal, &runtime.ctxtReal75);
        math_wp34s.WP34S_LnGamma(&resultReal, &resultReal, &runtime.ctxtReal75); // r = ln((y-x)!)

        realAdd(&xReal, const_1(), &xReal, &runtime.ctxtReal75);
        math_wp34s.WP34S_LnGamma(&xReal, &xReal, &runtime.ctxtReal75); // x = ln(x!)

        realAdd(&yReal, const_1(), &yReal, &runtime.ctxtReal75);
        math_wp34s.WP34S_LnGamma(&yReal, &yReal, &runtime.ctxtReal75); // y = ln(y!)

        realSubtract(&yReal, &resultReal, &resultReal, &runtime.ctxtReal75);
        realSubtract(&resultReal, &xReal, &resultReal, &runtime.ctxtReal75); // r = ln(y!) - ln((y-x)!) - ln(x!)

        math_transcendental.realExp(&resultReal, &resultReal, &runtime.ctxtReal75); // r = y! / ((y-x)! x x!)

        convertRealToLongInteger(&resultReal, result, DEC_ROUND_HALF_UP);
    }
}

// log(C(y,x)) through log-Beta in its stable half-plane. Returns true when the
// transformed arguments have positive real parts.
fn logCyxPositiveComplex(y: *const cplx_t, x: *const cplx_t, r: *cplx_t, realContext: *realContext_t) bool {
    var a: cplx_t = undefined;
    var b: cplx_t = undefined;
    var logBeta: cplx_t = undefined;
    var t: cplx_t = undefined;

    realAdd(&x.Real, const_1(), &a.Real, realContext);
    realCopy(&x.Imag, &a.Imag);
    realSubtract(&y.Real, &x.Real, &b.Real, realContext);
    realAdd(&b.Real, const_1(), &b.Real, realContext);
    realSubtract(&y.Imag, &x.Imag, &b.Imag, realContext);
    if (realIsSpecial(&a.Real) or realIsSpecial(&a.Imag) or realIsSpecial(&b.Real) or realIsSpecial(&b.Imag) or
        !math_comparison_reals.realCompareGreaterThan(&a.Real, const_0()) or !math_comparison_reals.realCompareGreaterThan(&b.Real, const_0()))
    {
        return false;
    }

    math_lnbeta.C47_LnBetaPositiveComplex(&a, &b, &logBeta);
    realAdd(&y.Real, const_1(), &t.Real, realContext);
    realCopy(&y.Imag, &t.Imag);
    math_ln_complex.lnComplex(&t, &t, realContext);
    realAdd(&t.Real, &logBeta.Real, &r.Real, realContext);
    realAdd(&t.Imag, &logBeta.Imag, &r.Imag, realContext);
    realChangeSign(&r.Real);
    realChangeSign(&r.Imag);
    return true;
}

fn cyxCplx(y: *cplx_t, x: *cplx_t, r: *cplx_t, realContext: *realContext_t) void {
    if (logCyxPositiveComplex(y, x, r, realContext)) {
        math_transcendental.expComplex(r, r, realContext);
        return;
    }

    realSubtract(&y.Real, &x.Real, &r.Real, realContext); // r = y - x
    realSubtract(&y.Imag, &x.Imag, &r.Imag, realContext);

    realAdd(&r.Real, const_1(), &r.Real, realContext); // r = t + 1
    runtime.WP34S_ComplexLnGamma(r, r, realContext); // r = lnGamma(t + 1) = ln((y - x)!)

    realAdd(&x.Real, const_1(), &x.Real, realContext); // x = x + 1
    runtime.WP34S_ComplexLnGamma(x, x, realContext); // x = lnGamma(x + 1) = ln(x!)

    realAdd(&y.Real, const_1(), &y.Real, realContext); // y = y + 1
    runtime.WP34S_ComplexLnGamma(y, y, realContext); // y = lnGamma(y + 1) = ln(y!)

    realSubtract(&y.Real, &r.Real, &r.Real, realContext); // r = ln(y!) - ln((y - x)!)
    realSubtract(&y.Imag, &r.Imag, &r.Imag, realContext);

    realSubtract(&r.Real, &x.Real, &r.Real, realContext); // r = ln(y!) - ln((y - x)!) - ln(x!)
    realSubtract(&r.Imag, &x.Imag, &r.Imag, realContext);

    math_transcendental.expComplex(r, r, realContext); // r = y! / ((y-x)! x x!)
}

fn pyxReal(y: *real_t, x: *real_t, result: *real_t, realContext: *realContext_t) void {
    const inputAreIntegers = (realIsAnInteger(x) and realIsAnInteger(y));

    logPyxPositiveReal(y, x, result, realContext);
    math_transcendental.realExp(result, result, realContext);

    if (inputAreIntegers and !realIsAnInteger(result)) {
        realToIntegralValue(result, result, DEC_ROUND_HALF_UP, realContext);
    }
}

fn pyxLong(y: *mpz_struct, x: *mpz_struct, result: *mpz_struct) void {
    if (longIntegerCompareInt(x, 0) == 0) {
        uInt32ToLongInteger(1, result);
    } else if (longIntegerCompareInt(x, 400) <= 0) {
        var loops: u32 = undefined;

        loops = longIntegerToUInt32(x);
        loops -%= 1;
        longIntegerSubtractUInt(y, loops, result);
        longIntegerCopy(result, y);
        while (true) {
            const cur = loops;
            loops -%= 1;
            if (cur == 0) break;
            longIntegerAddUInt(y, 1, y);
            runtime.longIntegerMultiply(result, y, result);
        }
    } else {
        var xReal: real_t = undefined;
        var yReal: real_t = undefined;
        var resultReal: real_t = undefined;

        convertLongIntegerToReal(x, &xReal, &runtime.ctxtReal75);
        convertLongIntegerToReal(y, &yReal, &runtime.ctxtReal75);

        realSubtract(&yReal, &xReal, &resultReal, &runtime.ctxtReal75);
        realAdd(&resultReal, const_1(), &resultReal, &runtime.ctxtReal75);
        math_wp34s.WP34S_LnGamma(&resultReal, &resultReal, &runtime.ctxtReal75); // r = ln((y-x)!)

        realAdd(&yReal, const_1(), &yReal, &runtime.ctxtReal75);
        math_wp34s.WP34S_LnGamma(&yReal, &yReal, &runtime.ctxtReal75); // y = ln(y!)

        realSubtract(&yReal, &resultReal, &resultReal, &runtime.ctxtReal75); // r = ln(y!) - ln((y-x)!)

        math_transcendental.realExp(&resultReal, &resultReal, &runtime.ctxtReal75); // r = y! / (y-x)!

        convertRealToLongInteger(&resultReal, result, DEC_ROUND_HALF_UP);
    }
}

fn pyxCplx(y: *cplx_t, x: *cplx_t, r: *cplx_t, realContext: *realContext_t) void {
    if (logCyxPositiveComplex(y, x, r, realContext)) {
        var xPlusOne: cplx_t = undefined;
        var logGamma: cplx_t = undefined;

        realAdd(&x.Real, const_1(), &xPlusOne.Real, realContext);
        realCopy(&x.Imag, &xPlusOne.Imag);
        runtime.WP34S_ComplexLnGamma(&xPlusOne, &logGamma, realContext);
        realAdd(&r.Real, &logGamma.Real, &r.Real, realContext);
        realAdd(&r.Imag, &logGamma.Imag, &r.Imag, realContext);
        math_transcendental.expComplex(r, r, realContext);
        return;
    }

    realSubtract(&y.Real, &x.Real, &r.Real, realContext); // r = y - x
    realSubtract(&y.Imag, &x.Imag, &r.Imag, realContext);

    realAdd(&r.Real, const_1(), &r.Real, realContext); // r = t + 1
    runtime.WP34S_ComplexLnGamma(r, r, realContext); // r = lnGamma(t + 1) = ln((y - x)!)

    realAdd(&y.Real, const_1(), &y.Real, realContext); // y = y + 1
    runtime.WP34S_ComplexLnGamma(y, y, realContext); // y = lnGamma(y + 1) = ln(y!)

    realSubtract(&y.Real, &r.Real, &r.Real, realContext); // r = ln(y!) - ln((y - x)!)
    realSubtract(&y.Imag, &r.Imag, &r.Imag, realContext);

    math_transcendental.expComplex(r, r, realContext); // r = y! / (y-x)!
}

fn cpyxLonI(combOrPerm: u16) void {
    var x: mpz_struct = undefined;
    var y: mpz_struct = undefined;

    if (!runtime.getRegisterAsLongInt(REGISTER_X, &x, null)) {
        longIntegerFree(&x);
        return;
    }
    defer longIntegerFree(&x);
    if (!runtime.getRegisterAsLongInt(REGISTER_Y, &y, null)) {
        longIntegerFree(&y);
        return;
    }
    defer longIntegerFree(&y);

    if (longIntegerIsNegative(&x) or longIntegerIsNegative(&y) or longIntegerCompare(&y, &x) < 0) {
        displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE);
        extraInfoMessage("cpyxLonILonI:", "cannot calculate Cyx/Pyx, conditions: x>=0, y>=0, and x<=y.");
    } else {
        var t: mpz_struct = undefined;
        longIntegerInit(&t);

        if (combOrPerm == CP_COMBINATION) cyxLong(&y, &x, &t) else pyxLong(&y, &x, &t);

        convertLongIntegerToLongIntegerRegister(&t, REGISTER_X);
        longIntegerFree(&t);
    }
}

fn cpyxReal(combOrPerm: u16) void {
    var x: real_t = undefined;
    var y: real_t = undefined;

    if (!runtime.getRegisterAsReal(REGISTER_X, &x) or !runtime.getRegisterAsReal(REGISTER_Y, &y)) {
        return;
    }

    if (realIsSpecial(&x) or realIsSpecial(&y)) {
        if (!runtime.getSystemFlag(FLAG_SPCRES)) {
            displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE);
            return;
        }
        var t: real_t = undefined;
        if (realIsInfinite(&y) and realIsPositive(&y) and !realIsSpecial(&x) and !realIsNegative(&x)) {
            if (realIsZero(&x)) {
                runtime.realSetOne(&t);
            } else {
                realCopy(runtime.z47_math_wrappers_const_plus_infinity(), &t);
            }
        } else {
            runtime.realSetNaN(&t);
        }
        runtime.convertRealToResultRegister(&t, REGISTER_X, amNone);
        return;
    }

    if (realIsNegative(&x) or realIsNegative(&y) or math_comparison_reals.realCompareGreaterThan(&x, &y)) {
        displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE);
        extraInfoMessage("cpyxRealReal:", "cannot calculate Cyx/Pyx, conditions: x>=0, y>=0, and x<=y.");
    } else {
        var t: real_t = undefined;

        if (combOrPerm == CP_COMBINATION) cyxReal(&y, &x, &t, &runtime.ctxtReal39) else pyxReal(&y, &x, &t, &runtime.ctxtReal39);

        runtime.convertRealToResultRegister(&t, REGISTER_X, amNone);
    }
}

fn cpyxCplx(combOrPerm: u16) void {
    var x: cplx_t = undefined;
    var y: cplx_t = undefined;
    var t: cplx_t = undefined;

    if (!runtime.getRegisterAsComplex(REGISTER_X, &x) or !runtime.getRegisterAsComplex(REGISTER_Y, &y)) {
        return;
    }

    if (combOrPerm == CP_COMBINATION)
        cyxCplx(&y, &x, &t, &runtime.ctxtReal75)
    else
        pyxCplx(&y, &x, &t, &runtime.ctxtReal75);

    runtime.convertComplexToResultRegister(&t, REGISTER_X);
}

fn cpyxShoI(combOrPerm: u16) void {
    var x: mpz_struct = undefined;
    var y: mpz_struct = undefined;

    if (!runtime.getRegisterAsLongInt(REGISTER_X, &x, null)) {
        longIntegerFree(&x);
        return;
    }
    defer longIntegerFree(&x);
    if (!runtime.getRegisterAsLongInt(REGISTER_Y, &y, null)) {
        longIntegerFree(&y);
        return;
    }
    defer longIntegerFree(&y);

    if (longIntegerIsNegative(&x) or longIntegerIsNegative(&y) or longIntegerCompare(&y, &x) < 0) {
        displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE);
        extraInfoMessage("cpyxShoI:", "cannot calculate Cyx/Pyx, y and x must be greater or equal than zero.");
    } else {
        var t: mpz_struct = undefined;

        longIntegerInit(&t);
        if (combOrPerm == CP_COMBINATION) cyxLong(&y, &x, &t) else pyxLong(&y, &x, &t);

        convertLongIntegerToShortIntegerRegister(&t, getRegisterShortIntegerBase(REGISTER_Y), REGISTER_X);

        // frees the original x, then convertShortIntegerRegisterToLongInteger
        // re-inits it; the deferred free above releases this re-init'd x -- two
        // distinct lifetimes, no double-free.
        longIntegerFree(&x);
        convertShortIntegerRegisterToLongInteger(REGISTER_X, &x);
        if (longIntegerCompare(&t, &x) != 0) {
            runtime.setSystemFlag(FLAG_OVERFLOW);
        }

        longIntegerFree(&t);
    }
}

fn doCyxReal() callconv(.c) void {
    cpyxReal(CP_COMBINATION);
}

fn doPyxReal() callconv(.c) void {
    cpyxReal(CP_PERMUTATION);
}

fn doCyxCplx() callconv(.c) void {
    cpyxCplx(CP_COMBINATION);
}

fn doPyxCplx() callconv(.c) void {
    cpyxCplx(CP_PERMUTATION);
}

fn doCyxShoI() callconv(.c) void {
    cpyxShoI(CP_COMBINATION);
}

fn doPyxShoI() callconv(.c) void {
    cpyxShoI(CP_PERMUTATION);
}

fn doCyxLonI() callconv(.c) void {
    cpyxLonI(CP_COMBINATION);
}

fn doPyxLonI() callconv(.c) void {
    cpyxLonI(CP_PERMUTATION);
}

pub export fn fnCyx(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    runtime.processIntRealComplexDyadicFunction(&doCyxReal, &doCyxCplx, &doCyxShoI, &doCyxLonI);
}

pub export fn fnPyx(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    runtime.processIntRealComplexDyadicFunction(&doPyxReal, &doPyxCplx, &doPyxShoI, &doPyxLonI);
}
