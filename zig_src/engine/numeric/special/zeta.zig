// SPDX-License-Identifier: GPL-3.0-only
const abi = @import("abi");
const consts = abi.constants;
const const39_pi = consts.const39_pi;
const const39_piOn2 = consts.const39_piOn2;
const const_8 = consts.const_8;
const const_4 = consts.const_4;
const const_3 = consts.const_3;
const const39_ln2 = consts.const39_ln2;
//
// Zig owner for src/c47/mathematics/zeta.c: the Riemann zeta function, real and
// complex (the complex path is Jean-Marc Baillard's algorithm). Faithful
// line-by-line translation preserving the exact order of every real_t operation
// (zeta.txt checks results to the last ULP). Exports fnZeta and ComplexZeta with
// C linkage; the static zeta_calc_complex / doRealZeta / doComplexZeta helpers
// stay private. The SAVE_SPACE_DM42_12 gate is dead on every z47 build, so the
// body is ported unconditionally.

const runtime = @import("../command_wrappers_runtime.zig");
const math_comparison_reals = @import("../comparison_reals.zig");
const math_division_cells = @import("../arithmetic/division_cells.zig");
const math_multiplication_cells = @import("../arithmetic/multiplication_cells.zig");
const math_power = @import("../powerlog/power.zig");
const math_transform_complex_helpers = @import("../transform/transform_complex_helpers.zig");
const math_wp34s = @import("wp34s.zig");
const real_t = runtime.real_t;
const realContext_t = runtime.realContext_t;

const realAdd = runtime.realAdd;
const realSubtract = runtime.realSubtract;
const realMultiply = runtime.realMultiply;
const realDivide = runtime.realDivide;
const realSquareRoot = runtime.realSquareRoot;
const realChangeSign = runtime.realChangeSign;
const realSetOne = runtime.realSetOne;
const realSetZero = runtime.realSetZero;
const realToIntegralValue = runtime.realToIntegralValue;
const realIsZero = runtime.realIsZero;
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

// Blob-offset constants without a runtime accessor.
const cstR = consts.cstR;

// real ops accepting an unaligned (*align(1)) const operand, for the blob
// constants. These wrap the same decNumber primitives the runtime helpers use.
extern fn decNumberCopy(res: *real_t, source: *align(1) const real_t) *real_t;
extern fn decNumberCopyAbs(res: *real_t, source: *align(1) const real_t) *real_t;
extern fn decNumberMinus(res: *real_t, operand: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberMultiply(result: *real_t, lhs: *align(1) const real_t, rhs: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberDivide(result: *real_t, lhs: *align(1) const real_t, rhs: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberAdd(result: *real_t, lhs: *align(1) const real_t, rhs: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberSubtract(result: *real_t, lhs: *align(1) const real_t, rhs: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberPower(result: *real_t, lhs: *align(1) const real_t, rhs: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberSquareRoot(result: *real_t, rhs: *align(1) const real_t, ctxt: *realContext_t) *real_t;

inline fn realCopy(source: *align(1) const real_t, destination: *real_t) void {
    _ = decNumberCopy(destination, source);
}
inline fn realCopyAbs(source: *align(1) const real_t, destination: *real_t) void {
    _ = decNumberCopyAbs(destination, source);
}
inline fn realMinus(operand: *const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberMinus(res, operand, ctxt);
}
inline fn realMul(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberMultiply(res, op1, op2, ctxt);
}
inline fn realDiv(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberDivide(res, op1, op2, ctxt);
}
inline fn realAddB(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberAdd(res, op1, op2, ctxt);
}
inline fn realSubB(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberSubtract(res, op1, op2, ctxt);
}
inline fn realPower(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberPower(res, op1, op2, ctxt);
}
inline fn realSquareRootB(op: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberSquareRoot(res, op, ctxt);
}

extern fn monitorExit(loop: *i32, str: [*:0]const u8) bool;

// Cross-domain externs.
extern fn realToInt32C47(source: *const real_t, err: ?*bool) i32;

fn zeta_calc_complex(reg4: *real_t, reg5: *real_t, reg6: *real_t, reg7: *real_t, realContext: *realContext_t) void {
    var s: real_t = undefined;
    var p: real_t = undefined;
    var q: real_t = undefined;
    var r: real_t = undefined;
    var reg0: real_t = undefined;
    var reg1: real_t = undefined;
    var reg2: real_t = undefined;
    var reg3: real_t = undefined;
    var reg8: real_t = undefined;
    var reg9: real_t = undefined;

    realCopyAbs(reg7, &p);
    realMul(const39_piOn2(), &p, &q, realContext);
    realMul(&p, const_2(), &p, realContext);
    math_wp34s.WP34S_Ln1P(&p, &p, realContext);
    realAdd(&q, &p, &p, realContext);
    realCopy(const_3(), &q);
    q.exponent += 10;
    math_wp34s.WP34S_Ln(&q, &q, realContext);
    realAdd(&p, &q, &p, realContext);
    realSquareRootB(const_8(), &q, realContext);
    realAddB(&q, const_3(), &q, realContext);
    math_wp34s.WP34S_Ln(&q, &q, realContext);
    realDivide(&p, &q, &p, realContext);
    realToIntegralValue(&p, &p, DEC_ROUND_DOWN, realContext);
    realAddB(&p, const_1(), &p, realContext);
    realMul(&p, const_4(), &p, realContext); // for extra digits we have
    realCopy(&p, &reg0);
    realSetOne(&reg1);
    realCopy(&p, &reg2);
    realSetOne(&reg3);
    realSetOne(reg4);
    realPower(const__1(), &p, &p, realContext);
    realChangeSign(&p);
    realCopy(&p, reg5);
    realSetZero(&reg8);
    realSetZero(&reg9);

    while (true) { // zeta_loop
        var loop: i32 = realToInt32C47(&reg0, null);
        if (monitorExit(&loop, "Iter: ")) {
            break;
        }

        realMinus(reg6, &q, realContext);
        realMinus(reg7, &p, realContext);
        _ = math_power.PowerComplex(&reg0, const_0(), &q, &p, &s, &r, realContext);
        realChangeSign(reg5);
        realMultiply(reg4, reg5, &p, realContext);
        realMultiply(&p, &r, &r, realContext);
        realMultiply(&p, &s, &s, realContext);
        realAdd(&reg8, &s, &reg8, realContext);
        realAdd(&reg9, &r, &reg9, realContext);
        realMul(&reg0, const_2(), &p, realContext);
        realMultiply(&p, &reg0, &p, realContext);
        realSubtract(&p, &reg0, &p, realContext);
        realMultiply(&p, &reg3, &p, realContext);
        realMultiply(&reg2, &reg2, &q, realContext);
        realSubB(&reg0, const_1(), &s, realContext);
        realMultiply(&s, &s, &s, realContext);
        realSubtract(&q, &s, &q, realContext);
        realMul(&q, const_2(), &q, realContext);
        realDivide(&p, &q, &p, realContext);
        realCopy(&p, &reg3);
        realAdd(reg4, &p, reg4, realContext);
        realSubB(&reg0, const_1(), &reg0, realContext);

        if (!math_comparison_reals.realCompareGreaterThan(&reg0, const_0())) break;
    }
    realDivide(&reg8, reg4, &reg8, realContext);
    realDivide(&reg9, reg4, &reg9, realContext);
    realSubB(const_1(), reg6, &p, realContext);
    realMul(const39_ln2(), &p, &p, realContext);
    math_wp34s.WP34S_ExpM1(&p, &reg1, realContext);
    realMinus(reg7, &p, realContext);
    realMul(&p, const39_ln2(), &p, realContext);
    math_transform_complex_helpers.realPolarToRectangular(const_1(), &p, &q, &p, realContext);
    realSubB(&q, const_1(), &r, realContext);
    realMultiply(&q, &reg1, &q, realContext);
    realMultiply(&reg1, &p, &s, realContext);
    realAdd(&s, &p, &s, realContext);
    realAdd(&q, &r, &q, realContext);

    math_division_cells.divComplexComplex(&reg8, &reg9, &q, &s, reg4, reg5, realContext);
}

pub export fn ComplexZeta(xReal: *const real_t, xImag: *const real_t, resReal: *real_t, resImag: *real_t, realContext: *realContext_t) callconv(.c) void {
    var p: real_t = undefined;
    var q: real_t = undefined;
    var r: real_t = undefined;
    var s: real_t = undefined;
    var reg4: real_t = undefined;
    var reg5: real_t = undefined;
    var reg6: real_t = undefined;
    var reg7: real_t = undefined;
    var reg10: real_t = undefined;
    var reg11: real_t = undefined;

    if (realIsZero(xReal) and realIsZero(xImag)) {
        realCopy(const_1on2(), resReal);
        realChangeSign(resReal);
        realSetZero(resImag);
        return;
    }

    realCopy(xReal, &reg6);
    realCopy(xImag, &reg7);
    realCopy(xReal, &reg10);
    realCopy(xImag, &reg11);
    if (math_comparison_reals.realCompareGreaterEqual(xReal, const_1on2())) {
        zeta_calc_complex(&reg4, &reg5, &reg6, &reg7, realContext);
        realCopy(&reg4, resReal);
        realCopy(&reg5, resImag);
    } else { // zeta_neg
        realSubB(const_1(), xReal, &reg6, realContext);
        realChangeSign(&reg7);
        zeta_calc_complex(&reg4, &reg5, &reg6, &reg7, realContext);
        realSubB(const_1(), &reg10, &q, realContext);
        realSubB(const_0(), &reg11, &p, realContext);
        realMul(&q, const_1on2(), &q, realContext);
        realMul(&p, const_1on2(), &p, realContext);
        math_wp34s.WP34S_ComplexGamma(&q, &p, &s, &r, realContext);
        math_multiplication_cells.mulComplexComplex(&s, &r, &reg4, &reg5, &reg4, &reg5, realContext);
        realCopy(&reg10, &q);
        realCopy(&reg11, &p);
        realMul(&q, const_1on2(), &reg10, realContext);
        realMul(&p, const_1on2(), &reg11, realContext);
        realSubB(&q, const_1on2(), &q, realContext);
        _ = math_power.PowerComplex(const39_pi(), const_0(), &q, &p, &s, &r, realContext);
        math_multiplication_cells.mulComplexComplex(&s, &r, &reg4, &reg5, &reg4, &reg5, realContext);
        math_wp34s.WP34S_ComplexGamma(&reg10, &reg11, &q, &p, realContext);

        math_division_cells.divComplexComplex(&reg4, &reg5, &q, &p, resReal, resImag, realContext);
    }
}

fn doRealZeta() callconv(.c) void {
    var x: real_t = undefined;
    var r: real_t = undefined;

    if (!runtime.getRegisterAsReal(REGISTER_X, &x)) {
        return;
    }

    math_wp34s.WP34S_Zeta(&x, &r, &runtime.ctxtReal39);
    runtime.convertRealToResultRegister(&r, REGISTER_X, amNone);
}

fn doComplexZeta() callconv(.c) void {
    var xr: real_t = undefined;
    var xi: real_t = undefined;
    var rr: real_t = undefined;
    var ri: real_t = undefined;

    if (!runtime.getRegisterAsComplex(REGISTER_X, &xr, &xi)) {
        return;
    }

    if (!runtime.saveLastX()) {
        return;
    }

    ComplexZeta(&xr, &xi, &rr, &ri, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&rr, &ri, REGISTER_X);
}

pub export fn fnZeta(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    runtime.processRealComplexMonadicFunction(&doRealZeta, &doComplexZeta);
}
