// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/mathematics/cpyx.c: combinations C(y, x) and
// permutations P(y, x) over long integer / short integer / real / complex
// operands. Faithful line-by-line translation preserving the exact order of
// every real_t operation (cyx.txt / pyx.txt check results to the last ULP).
// Exports fnCyx, fnPyx and logCyxReal with C linkage; the static dispatch
// helpers stay private. EXTRA_INFO_MESSAGE hints become fixed moreInfoOnError
// strings (no-op under TESTSUITE/DMCP).

const runtime = @import("math_command_wrappers_runtime.zig");

const real_t = runtime.real_t;
const realContext_t = runtime.realContext_t;
const mpz_struct = runtime.mpz_struct;
const calcRegister_t = runtime.calcRegister_t;

const realAdd = runtime.realAdd;
const realSubtract = runtime.realSubtract;
const realIsAnInteger = runtime.realIsAnInteger;
const realIsNegative = runtime.realIsNegative;
const realToIntegralValue = runtime.realToIntegralValue;
const DEC_ROUND_HALF_UP = runtime.DEC_ROUND_HALF_UP;

const REGISTER_X = runtime.REGISTER_X;
const REGISTER_Y = runtime.REGISTER_Y;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const ERROR_OUT_OF_RANGE = runtime.ERROR_OUT_OF_RANGE;
const FLAG_OVERFLOW = runtime.FLAG_OVERFLOW;
const amNone = runtime.amNone;

const displayCalcErrorMessage = runtime.displayCalcErrorMessage;
const moreInfoOnError = runtime.moreInfoOnError;

// defines.h:1855-1856
const CP_PERMUTATION: u16 = 0;
const CP_COMBINATION: u16 = 1;

inline fn const_1() *const real_t {
    return runtime.z47_math_wrappers_const_1();
}

// realExp and WP34S_LnGamma / WP34S_ComplexLnGamma / expComplex cross-domain.
extern fn realExp(x: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_LnGamma(x: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_ComplexLnGamma(zinReal: *const real_t, zinImag: *const real_t, resReal: *real_t, resImag: *real_t, real_context: *realContext_t) void;
extern fn expComplex(real: *const real_t, imag: *const real_t, res_real: *real_t, res_imag: *real_t, real_context: *realContext_t) void;

extern fn realCompareGreaterThan(number1: *const real_t, number2: *const real_t) bool;

// Long integer <-> real / register conversions.
extern fn convertLongIntegerToReal(source: *mpz_struct, destination: *real_t, ctxt: *realContext_t) void;
extern fn convertRealToLongInteger(real: *const real_t, lgInt: *mpz_struct, mode: c_int) void;
extern fn convertLongIntegerToLongIntegerRegister(lgInt: *const mpz_struct, regist: calcRegister_t) void;
extern fn convertLongIntegerToShortIntegerRegister(lgInt: *const mpz_struct, base: u32, regist: calcRegister_t) void;
extern fn convertShortIntegerRegisterToLongInteger(reg: calcRegister_t, lgInt: *mpz_struct) void;

// GMP / long integer helpers (longIntegerType.h inlines / macros).
extern fn @"__gmpz_cmp_si"(op: *const mpz_struct, v: c_long) c_int;
extern fn @"__gmpz_set"(rop: *mpz_struct, op: *const mpz_struct) void;
// Overflow-guarded multiply (integers.c).
extern fn longIntegerMultiply(opY: *mpz_struct, opX: *mpz_struct, result: *mpz_struct) void;

inline fn longIntegerInit(op: *mpz_struct) void {
    runtime.__gmpz_init(op);
}
inline fn longIntegerFree(op: *mpz_struct) void {
    runtime.__gmpz_clear(op);
}
inline fn longIntegerCopy(source: *const mpz_struct, destination: *mpz_struct) void {
    @"__gmpz_set"(destination, source);
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
    return @"__gmpz_cmp_si"(op, v);
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
inline fn longIntegerIsNegative(op: *const mpz_struct) bool {
    return op._mp_size < 0;
}

inline fn getRegisterShortIntegerBase(reg: calcRegister_t) u32 {
    return runtime.getRegisterShortIntegerBase(reg);
}

pub export fn logCyxReal(y: *real_t, x: *real_t, result: *real_t, realContext: *realContext_t) callconv(.c) void {
    realSubtract(y, x, result, realContext);
    realAdd(result, const_1(), result, realContext);
    WP34S_LnGamma(result, result, realContext); // r = ln((y-x)!)

    realAdd(x, const_1(), x, realContext);
    WP34S_LnGamma(x, x, realContext); // x = ln(x!)

    realAdd(y, const_1(), y, realContext);
    WP34S_LnGamma(y, y, realContext); // y = ln(y!)

    realSubtract(y, result, result, realContext);
    realSubtract(result, x, result, realContext); // r = ln(y!) - ln((y-x)!) - ln(x!)
}

fn cyxReal(y: *real_t, x: *real_t, result: *real_t, realContext: *realContext_t) void {
    const inputAreIntegers = (realIsAnInteger(x) and realIsAnInteger(y));

    logCyxReal(y, x, result, realContext);

    realExp(result, result, realContext); // r = y! / ((y-x)! x x!)

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
            longIntegerMultiply(result, y, result);
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
        WP34S_LnGamma(&resultReal, &resultReal, &runtime.ctxtReal75); // r = ln((y-x)!)

        realAdd(&xReal, const_1(), &xReal, &runtime.ctxtReal75);
        WP34S_LnGamma(&xReal, &xReal, &runtime.ctxtReal75); // x = ln(x!)

        realAdd(&yReal, const_1(), &yReal, &runtime.ctxtReal75);
        WP34S_LnGamma(&yReal, &yReal, &runtime.ctxtReal75); // y = ln(y!)

        realSubtract(&yReal, &resultReal, &resultReal, &runtime.ctxtReal75);
        realSubtract(&resultReal, &xReal, &resultReal, &runtime.ctxtReal75); // r = ln(y!) - ln((y-x)!) - ln(x!)

        realExp(&resultReal, &resultReal, &runtime.ctxtReal75); // r = y! / ((y-x)! x x!)

        convertRealToLongInteger(&resultReal, result, DEC_ROUND_HALF_UP);
    }
}

fn cyxCplx(yReal: *real_t, yImag: *real_t, xReal: *real_t, xImag: *real_t, rReal: *real_t, rImag: *real_t, realContext: *realContext_t) void {
    realSubtract(yReal, xReal, rReal, realContext); // r = y - x
    realSubtract(yImag, xImag, rImag, realContext);

    realAdd(rReal, const_1(), rReal, realContext); // r = t + 1
    WP34S_ComplexLnGamma(rReal, rImag, rReal, rImag, realContext); // r = lnGamma(t + 1) = ln((y - x)!)

    realAdd(xReal, const_1(), xReal, realContext); // x = x + 1
    WP34S_ComplexLnGamma(xReal, xImag, xReal, xImag, realContext); // x = lnGamma(x + 1) = ln(x!)

    realAdd(yReal, const_1(), yReal, realContext); // y = y + 1
    WP34S_ComplexLnGamma(yReal, yImag, yReal, yImag, realContext); // y = lnGamma(y + 1) = ln(y!)

    realSubtract(yReal, rReal, rReal, realContext); // r = ln(y!) - ln((y - x)!)
    realSubtract(yImag, rImag, rImag, realContext);

    realSubtract(rReal, xReal, rReal, realContext); // r = ln(y!) - ln((y - x)!) - ln(x!)
    realSubtract(rImag, xImag, rImag, realContext);

    expComplex(rReal, rImag, rReal, rImag, realContext); // r = y! / ((y-x)! x x!)
}

fn pyxReal(y: *real_t, x: *real_t, result: *real_t, realContext: *realContext_t) void {
    const inputAreIntegers = (realIsAnInteger(x) and realIsAnInteger(y));

    realSubtract(y, x, result, realContext);
    realAdd(result, const_1(), result, realContext);
    WP34S_LnGamma(result, result, realContext); // r = ln((y-x)!)

    realAdd(y, const_1(), y, realContext);
    WP34S_LnGamma(y, y, realContext); // y = ln(y!)

    realSubtract(y, result, result, realContext); // r = ln(y!) - ln((y-x)!)

    realExp(result, result, realContext); // r = y! / (y-x)!

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
            longIntegerMultiply(result, y, result);
        }
    } else {
        var xReal: real_t = undefined;
        var yReal: real_t = undefined;
        var resultReal: real_t = undefined;

        convertLongIntegerToReal(x, &xReal, &runtime.ctxtReal75);
        convertLongIntegerToReal(y, &yReal, &runtime.ctxtReal75);

        realSubtract(&yReal, &xReal, &resultReal, &runtime.ctxtReal75);
        realAdd(&resultReal, const_1(), &resultReal, &runtime.ctxtReal75);
        WP34S_LnGamma(&resultReal, &resultReal, &runtime.ctxtReal75); // r = ln((y-x)!)

        realAdd(&yReal, const_1(), &yReal, &runtime.ctxtReal75);
        WP34S_LnGamma(&yReal, &yReal, &runtime.ctxtReal75); // y = ln(y!)

        realSubtract(&yReal, &resultReal, &resultReal, &runtime.ctxtReal75); // r = ln(y!) - ln((y-x)!)

        realExp(&resultReal, &resultReal, &runtime.ctxtReal75); // r = y! / (y-x)!

        convertRealToLongInteger(&resultReal, result, DEC_ROUND_HALF_UP);
    }
}

fn pyxCplx(yReal: *real_t, yImag: *real_t, xReal: *real_t, xImag: *real_t, rReal: *real_t, rImag: *real_t, realContext: *realContext_t) void {
    realSubtract(yReal, xReal, rReal, realContext); // r = y - x
    realSubtract(yImag, xImag, rImag, realContext);

    realAdd(rReal, const_1(), rReal, realContext); // r = t + 1
    WP34S_ComplexLnGamma(rReal, rImag, rReal, rImag, realContext); // r = lnGamma(t + 1) = ln((y - x)!)

    realAdd(yReal, const_1(), yReal, realContext); // y = y + 1
    WP34S_ComplexLnGamma(yReal, yImag, yReal, yImag, realContext); // y = lnGamma(y + 1) = ln(y!)

    realSubtract(yReal, rReal, rReal, realContext); // r = ln(y!) - ln((y - x)!)
    realSubtract(yImag, rImag, rImag, realContext);

    expComplex(rReal, rImag, rReal, rImag, realContext); // r = y! / (y-x)!
}

fn cpyxLonI(combOrPerm: u16) void {
    var x: mpz_struct = undefined;
    var y: mpz_struct = undefined;

    if (!runtime.getRegisterAsLongInt(REGISTER_X, &x, null)) {
        // goto end1
        longIntegerFree(&x);
        return;
    }
    if (!runtime.getRegisterAsLongInt(REGISTER_Y, &y, null)) {
        // goto end2
        longIntegerFree(&y);
        longIntegerFree(&x);
        return;
    }

    if (longIntegerIsNegative(&x) or longIntegerIsNegative(&y) or longIntegerCompare(&y, &x) < 0) {
        displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function cpyxLonILonI:", "cannot calculate Cyx/Pyx, conditions: x>=0, y>=0, and x<=y.", null, null);
    } else {
        var t: mpz_struct = undefined;
        longIntegerInit(&t);

        if (combOrPerm == CP_COMBINATION) cyxLong(&y, &x, &t) else pyxLong(&y, &x, &t);

        convertLongIntegerToLongIntegerRegister(&t, REGISTER_X);
        longIntegerFree(&t);
    }

    // end2:
    longIntegerFree(&y);
    // end1:
    longIntegerFree(&x);
}

fn cpyxReal(combOrPerm: u16) void {
    var x: real_t = undefined;
    var y: real_t = undefined;

    if (!runtime.getRegisterAsReal(REGISTER_X, &x) or !runtime.getRegisterAsReal(REGISTER_Y, &y)) {
        return;
    }

    if (realIsNegative(&x) or realIsNegative(&y) or realCompareGreaterThan(&x, &y)) {
        displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function cpyxRealReal:", "cannot calculate Cyx/Pyx, conditions: x>=0, y>=0, and x<=y.", null, null);
    } else {
        var t: real_t = undefined;

        if (combOrPerm == CP_COMBINATION) cyxReal(&y, &x, &t, &runtime.ctxtReal39) else pyxReal(&y, &x, &t, &runtime.ctxtReal39);

        runtime.convertRealToResultRegister(&t, REGISTER_X, amNone);
    }
}

fn cpyxCplx(combOrPerm: u16) void {
    var xReal: real_t = undefined;
    var xImag: real_t = undefined;
    var yReal: real_t = undefined;
    var yImag: real_t = undefined;
    var tReal: real_t = undefined;
    var tImag: real_t = undefined;

    if (!runtime.getRegisterAsComplex(REGISTER_X, &xReal, &xImag) or !runtime.getRegisterAsComplex(REGISTER_Y, &yReal, &yImag)) {
        return;
    }

    if (combOrPerm == CP_COMBINATION)
        cyxCplx(&yReal, &yImag, &xReal, &xImag, &tReal, &tImag, &runtime.ctxtReal39)
    else
        pyxCplx(&yReal, &yImag, &xReal, &xImag, &tReal, &tImag, &runtime.ctxtReal39);

    runtime.convertComplexToResultRegister(&tReal, &tImag, REGISTER_X);
}

fn cpyxShoI(combOrPerm: u16) void {
    var x: mpz_struct = undefined;
    var y: mpz_struct = undefined;

    if (!runtime.getRegisterAsLongInt(REGISTER_X, &x, null)) {
        // goto end1
        longIntegerFree(&x);
        return;
    }
    if (!runtime.getRegisterAsLongInt(REGISTER_Y, &y, null)) {
        // goto end2
        longIntegerFree(&y);
        longIntegerFree(&x);
        return;
    }

    if (longIntegerIsNegative(&x) or longIntegerIsNegative(&y) or longIntegerCompare(&y, &x) < 0) {
        displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function cpyxShoI:", "cannot calculate Cyx/Pyx, y and x must be greater or equal than zero.", null, null);
    } else {
        var t: mpz_struct = undefined;

        longIntegerInit(&t);
        if (combOrPerm == CP_COMBINATION) cyxLong(&y, &x, &t) else pyxLong(&y, &x, &t);

        convertLongIntegerToShortIntegerRegister(&t, getRegisterShortIntegerBase(REGISTER_Y), REGISTER_X);

        longIntegerFree(&x); // Because convertShortIntegerRegisterToLongInteger reinits the long integer
        convertShortIntegerRegisterToLongInteger(REGISTER_X, &x);
        if (longIntegerCompare(&t, &x) != 0) {
            runtime.setSystemFlag(FLAG_OVERFLOW);
        }

        longIntegerFree(&t);
    }

    // end2:
    longIntegerFree(&y);
    // end1:
    longIntegerFree(&x);
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
