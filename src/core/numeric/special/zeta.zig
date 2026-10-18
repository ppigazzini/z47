// SPDX-License-Identifier: GPL-3.0-only
const abi = @import("abi");
const consts = abi.constants;
const const39_pi = consts.const39_pi;
const const39_piOn2 = consts.const39_piOn2;
const const75_piOn2 = consts.const75_piOn2;
const const_8 = consts.const_8;
const const_4 = consts.const_4;
const const_3 = consts.const_3;
const const39_ln2 = consts.const39_ln2;
const const75_ln2 = consts.const75_ln2;
const const_10000 = consts.const_10000;
//
// Zig owner for src/c47/mathematics/zeta.c: the Riemann zeta function, real and
// complex (the complex path is Jean-Marc Baillard's algorithm). Faithful
// line-by-line translation preserving the exact order of every real_t operation
// (zeta.txt checks results to the last ULP). Exports fnZeta and ComplexZeta with
// C linkage; the static zeta_calc_complex / doRealZeta / doComplexZeta helpers
// stay private. OPTION_ZETA_BETA is defined for every target built here, so the
// body is unconditional.

const runtime = @import("../command_wrappers/runtime.zig");
const math_comparison_reals = @import("../compare/comparison_reals.zig");
const math_wp34s = @import("wp34s.zig");
const real_t = runtime.real_t;
const cplx_t = runtime.cplx_t;
const realContext_t = runtime.realContext_t;

const realAdd = runtime.realAdd;
const realSubtract = runtime.realSubtract;
const realMultiply = runtime.realMultiply;
const realDivide = runtime.realDivide;
const realSquareRoot = runtime.realSquareRoot;
const realPower = runtime.realPower;
const realMinus = runtime.realMinus;
const realChangeSign = runtime.realChangeSign;
const realSetOne = runtime.realSetOne;
const realSetZero = runtime.realSetZero;
const realSetNaN = runtime.realSetNaN;
const realSetPositiveSign = runtime.realSetPositiveSign;
const realToIntegralValue = runtime.realToIntegralValue;
const realIsZero = runtime.realIsZero;
const realIsNaN = runtime.realIsNaN;
const realIsSpecial = runtime.realIsSpecial;
const realIsInfinite = runtime.realIsInfinite;
const realIsNegative = runtime.realIsNegative;
const realToInt32C47 = runtime.realToInt32C47;
const DEC_ROUND_DOWN = runtime.DEC_ROUND_DOWN;

const REGISTER_X = runtime.REGISTER_X;
const amNone = runtime.amNone;

// Runtime const accessors.
inline fn const_0() *const real_t {
    return runtime.z47_math_wrappers_const_0();
}
inline fn const_1() *const real_t {
    return runtime.z47_math_wrappers_const_1();
}
inline fn const__1() *const real_t {
    return runtime.z47_math_wrappers_const_minus_1();
}
inline fn const_2() *const real_t {
    return runtime.z47_math_wrappers_const_2();
}
inline fn const_1on2() *const real_t {
    return runtime.z47_math_wrappers_const_1on2();
}
inline fn const75_pi() *const real_t {
    return runtime.z47_math_wrappers_const75_pi();
}

inline fn realCopy(source: *const real_t, destination: *real_t) void {
    destination.* = source.*;
}
inline fn realCopyAbs(source: *const real_t, destination: *real_t) void {
    destination.* = source.*;
    realSetPositiveSign(destination);
}

extern fn monitorExit(loop: *i32, str: [*:0]const u8) bool;

// Returns false, with reg45 NaN, when the alternating series would need more than
// 10000 terms.
fn zeta_calc_complex(reg45: *cplx_t, reg67: *const cplx_t, realContext: *realContext_t) bool {
    var reg1: real_t = undefined;
    var reg2: real_t = undefined;
    var reg3: real_t = undefined;
    var sr: cplx_t = undefined;
    var qp: cplx_t = undefined;
    var reg0: cplx_t = undefined;
    var reg89: cplx_t = undefined;
    const ln2: *const real_t = if (realContext.digits > 39) const75_ln2() else const39_ln2();
    const piOn2: *const real_t = if (realContext.digits > 39) const75_piOn2() else const39_piOn2();

    realCopyAbs(&reg67.Imag, &qp.Imag);
    realMultiply(piOn2, &qp.Imag, &qp.Real, realContext);
    realMultiply(&qp.Imag, const_2(), &qp.Imag, realContext);
    math_wp34s.WP34S_Ln1P(&qp.Imag, &qp.Imag, realContext);
    realAdd(&qp.Real, &qp.Imag, &qp.Imag, realContext);
    realCopy(const_3(), &qp.Real);
    qp.Real.exponent += 10;
    math_wp34s.WP34S_Ln(&qp.Real, &qp.Real, realContext);
    realAdd(&qp.Imag, &qp.Real, &qp.Imag, realContext);
    realSquareRoot(const_8(), &qp.Real, realContext);
    realAdd(&qp.Real, const_3(), &qp.Real, realContext);
    math_wp34s.WP34S_Ln(&qp.Real, &qp.Real, realContext);
    realDivide(&qp.Imag, &qp.Real, &qp.Imag, realContext);
    realToIntegralValue(&qp.Imag, &qp.Imag, DEC_ROUND_DOWN, realContext);
    realAdd(&qp.Imag, const_1(), &qp.Imag, realContext);
    realMultiply(&qp.Imag, const_4(), &qp.Imag, realContext); // for extra digits we have
    if (math_comparison_reals.realCompareGreaterThan(&qp.Imag, const_10000())) {
        realSetNaN(&reg45.Real);
        realSetNaN(&reg45.Imag);
        return false;
    }
    realCopy(&qp.Imag, &reg0.Real);
    realSetZero(&reg0.Imag);
    realSetOne(&reg1);
    realCopy(&qp.Imag, &reg2);
    realSetOne(&reg3);
    realSetOne(&reg45.Real);
    realPower(const__1(), &qp.Imag, &qp.Imag, realContext);
    realChangeSign(&qp.Imag);
    realCopy(&qp.Imag, &reg45.Imag);
    realSetZero(&reg89.Real);
    realSetZero(&reg89.Imag);

    while (true) { // zeta_loop
        var loop: i32 = realToInt32C47(&reg0.Real, null);
        if (monitorExit(&loop, "Iter: ")) {
            break;
        }

        realMinus(&reg67.Real, &qp.Real, realContext);
        realMinus(&reg67.Imag, &qp.Imag, realContext);
        _ = runtime.PowerComplex(&reg0, &qp, &sr, realContext);
        realChangeSign(&reg45.Imag);
        realMultiply(&reg45.Real, &reg45.Imag, &qp.Imag, realContext);
        realMultiply(&qp.Imag, &sr.Imag, &sr.Imag, realContext);
        realMultiply(&qp.Imag, &sr.Real, &sr.Real, realContext);
        realAdd(&reg89.Real, &sr.Real, &reg89.Real, realContext);
        realAdd(&reg89.Imag, &sr.Imag, &reg89.Imag, realContext);
        realMultiply(&reg0.Real, const_2(), &qp.Imag, realContext);
        realMultiply(&qp.Imag, &reg0.Real, &qp.Imag, realContext);
        realSubtract(&qp.Imag, &reg0.Real, &qp.Imag, realContext);
        realMultiply(&qp.Imag, &reg3, &qp.Imag, realContext);
        realMultiply(&reg2, &reg2, &qp.Real, realContext);
        realSubtract(&reg0.Real, const_1(), &sr.Real, realContext);
        realMultiply(&sr.Real, &sr.Real, &sr.Real, realContext);
        realSubtract(&qp.Real, &sr.Real, &qp.Real, realContext);
        realMultiply(&qp.Real, const_2(), &qp.Real, realContext);
        realDivide(&qp.Imag, &qp.Real, &qp.Imag, realContext);
        realCopy(&qp.Imag, &reg3);
        realAdd(&reg45.Real, &qp.Imag, &reg45.Real, realContext);
        realSubtract(&reg0.Real, const_1(), &reg0.Real, realContext);

        if (!math_comparison_reals.realCompareGreaterThan(&reg0.Real, const_0())) break;
    }
    realDivide(&reg89.Real, &reg45.Real, &reg89.Real, realContext);
    realDivide(&reg89.Imag, &reg45.Real, &reg89.Imag, realContext);
    realSubtract(const_1(), &reg67.Real, &qp.Imag, realContext);
    realMultiply(ln2, &qp.Imag, &qp.Imag, realContext);
    math_wp34s.WP34S_ExpM1(&qp.Imag, &reg1, realContext);
    realMinus(&reg67.Imag, &qp.Imag, realContext);
    realMultiply(&qp.Imag, ln2, &qp.Imag, realContext);
    runtime.realPolarToRectangular(const_1(), &qp.Imag, &qp, realContext);
    realSubtract(&qp.Real, const_1(), &sr.Imag, realContext);
    realMultiply(&qp.Real, &reg1, &qp.Real, realContext);
    realMultiply(&reg1, &qp.Imag, &sr.Real, realContext);
    realAdd(&sr.Real, &qp.Imag, &qp.Imag, realContext);
    realAdd(&qp.Real, &sr.Imag, &qp.Real, realContext);

    runtime.divComplexComplex(&reg89, &qp, reg45, realContext);
    return true;
}

pub export fn ComplexZeta(x: *const cplx_t, res: *cplx_t, realContext: *realContext_t) callconv(.c) void {
    var qp: cplx_t = undefined;
    var sr: cplx_t = undefined;
    var reg45: cplx_t = undefined;
    var reg67: cplx_t = undefined;
    var reg1011: cplx_t = undefined;
    const pi: *const real_t = if (realContext.digits > 39) const75_pi() else const39_pi();

    if (realIsZero(&x.Imag)) {
        math_wp34s.WP34S_Zeta(&x.Real, &res.Real, realContext);
        realCopy(&x.Imag, &res.Imag);
        return;
    }
    if (realIsNaN(&x.Real) or realIsSpecial(&x.Imag) or (realIsInfinite(&x.Real) and realIsNegative(&x.Real))) {
        realSetNaN(&res.Real);
        realSetNaN(&res.Imag);
        return;
    }
    if (realIsInfinite(&x.Real)) {
        realSetOne(&res.Real);
        realSetZero(&res.Imag);
        return;
    }

    realCopy(&x.Real, &reg67.Real);
    realCopy(&x.Imag, &reg67.Imag);
    realCopy(&x.Real, &reg1011.Real);
    realCopy(&x.Imag, &reg1011.Imag);
    if (math_comparison_reals.realCompareGreaterEqual(&x.Real, const_1on2())) {
        if (!zeta_calc_complex(&reg45, &reg67, realContext)) {
            realSetNaN(&res.Real);
            realSetNaN(&res.Imag);
            return;
        }
        realCopy(&reg45.Real, &res.Real);
        realCopy(&reg45.Imag, &res.Imag);
    } else { // zeta_neg
        realSubtract(const_1(), &x.Real, &reg67.Real, realContext);
        realChangeSign(&reg67.Imag);
        if (!zeta_calc_complex(&reg45, &reg67, realContext)) {
            realSetNaN(&res.Real);
            realSetNaN(&res.Imag);
            return;
        }
        realSubtract(const_1(), &reg1011.Real, &qp.Real, realContext);
        realSubtract(const_0(), &reg1011.Imag, &qp.Imag, realContext);
        realMultiply(&qp.Real, const_1on2(), &qp.Real, realContext);
        realMultiply(&qp.Imag, const_1on2(), &qp.Imag, realContext);
        runtime.WP34S_ComplexGamma(&qp, &sr, realContext);
        runtime.mulComplexComplex(&sr, &reg45, &reg45, realContext);
        realCopy(&reg1011.Real, &qp.Real);
        realCopy(&reg1011.Imag, &qp.Imag);
        realMultiply(&qp.Real, const_1on2(), &reg1011.Real, realContext);
        realMultiply(&qp.Imag, const_1on2(), &reg1011.Imag, realContext);
        realSubtract(&qp.Real, const_1on2(), &qp.Real, realContext);
        realCopy(pi, &reg67.Real);
        realSetZero(&reg67.Imag);
        _ = runtime.PowerComplex(&reg67, &qp, &sr, realContext);
        runtime.mulComplexComplex(&sr, &reg45, &reg45, realContext);
        runtime.WP34S_ComplexGamma(&reg1011, &qp, realContext);

        runtime.divComplexComplex(&reg45, &qp, res, realContext);
    }
}

fn doRealZeta() callconv(.c) void {
    var x: real_t = undefined;
    var r: real_t = undefined;

    if (!runtime.getRegisterAsReal(REGISTER_X, &x)) {
        return;
    }

    math_wp34s.WP34S_Zeta(&x, &r, &runtime.ctxtReal75);
    runtime.convertRealToResultRegister(&r, REGISTER_X, amNone);
}

fn doComplexZeta() callconv(.c) void {
    var x: cplx_t = undefined;
    var r: cplx_t = undefined;

    if (!runtime.getRegisterAsComplex(REGISTER_X, &x)) {
        return;
    }

    ComplexZeta(&x, &r, &runtime.ctxtReal75);
    runtime.convertComplexToResultRegister(&r, REGISTER_X);
}

pub export fn fnZeta(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    runtime.processRealComplexMonadicFunction(&doRealZeta, &doComplexZeta);
}
