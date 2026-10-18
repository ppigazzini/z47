// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/mathematics/elliptic.c: the elliptic-integral and
// Jacobi-function family. Exports the elliptic.h commands (fnEllipse, fnKtoM,
// fnMtoK, fnMtoTheta, fnThetatoM, fnJacobiSn/Cn/Dn/Amplitude, fnEllipticK/E/Pi/
// Fphi/Ephi, fnJacobiZeta) plus the public engines jacobiElliptic,
// jacobiComplexAm/Sn/Cn/Dn, ellipticKE, ellipticComplexKE, ellipticF,
// ellipticE, jacobiZeta and ellipticPi, every complex value a cplx_t. The
// static helpers (Carlson RF/RD/RJ/RC, the AGM back-substitution, the A&S
// transformations) stay private. Faithful line-by-line translation preserving
// the order of every real_t operation (ellipticE/Ephi/Fphi/K/Pi.txt and
// jacobi_*.txt check results to the last ULP).
// OPTION_ELLIPTIC is LIVE: upstream keeps it for some DM42 packages and empties
// these commands on the rest (build/firmware.zig's dm42Package table), which is
// what the option_elliptic early returns below are. Do not read the gate as dead
// code.

const std = @import("std");
const abi = @import("abi");
const runtime = @import("../command_wrappers/runtime.zig");
const math_agm = @import("agm.zig");
const math_circular_trig_command = @import("../trig/circular_trig_command.zig");
const math_command_wrappers = @import("../command_wrappers.zig");
const math_comparison_reals = @import("../compare/comparison_reals.zig");
const math_gd = @import("gd.zig");
const math_inverse_trig_command = @import("../trig/inverse_trig_command.zig");
const math_real_predicates = @import("../compare/real_predicates.zig");

const consts = abi.constants;
const real_t = runtime.real_t;
const cplx_t = runtime.cplx_t;
const realContext_t = runtime.realContext_t;
const calcRegister_t = runtime.calcRegister_t;
const angularMode_t = runtime.angularMode_t;

// Arithmetic ops accepting *align(1) const operands (blob constants pass here).
extern fn decNumberAdd(result: *real_t, lhs: *align(1) const real_t, rhs: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberSubtract(result: *real_t, lhs: *align(1) const real_t, rhs: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberMultiply(result: *real_t, lhs: *align(1) const real_t, rhs: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberDivide(result: *real_t, lhs: *align(1) const real_t, rhs: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberSquareRoot(result: *real_t, rhs: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberFMA(result: *real_t, f1: *align(1) const real_t, f2: *align(1) const real_t, term: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberCopy(res: *real_t, source: *align(1) const real_t) *real_t;
extern fn decNumberCopyAbs(res: *real_t, source: *align(1) const real_t) *real_t;
extern fn decNumberCopySign(res: *real_t, source: *align(1) const real_t, sign_source: *align(1) const real_t) *real_t;
extern fn decNumberMinus(res: *real_t, operand: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberPlus(res: *real_t, operand: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberRemainder(res: *real_t, lhs: *align(1) const real_t, rhs: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn realSetPlusInfinity(value: *real_t) void;
extern fn realSetMinusInfinity(value: *real_t) void;

inline fn realAdd(lhs: *align(1) const real_t, rhs: *align(1) const real_t, result: *real_t, ctxt: *realContext_t) void {
    _ = decNumberAdd(result, lhs, rhs, ctxt);
}
inline fn realSubtract(lhs: *align(1) const real_t, rhs: *align(1) const real_t, result: *real_t, ctxt: *realContext_t) void {
    _ = decNumberSubtract(result, lhs, rhs, ctxt);
}
inline fn realMultiply(lhs: *align(1) const real_t, rhs: *align(1) const real_t, result: *real_t, ctxt: *realContext_t) void {
    _ = decNumberMultiply(result, lhs, rhs, ctxt);
}
inline fn realDivide(lhs: *align(1) const real_t, rhs: *align(1) const real_t, result: *real_t, ctxt: *realContext_t) void {
    _ = decNumberDivide(result, lhs, rhs, ctxt);
}
inline fn realSquareRoot(rhs: *align(1) const real_t, result: *real_t, ctxt: *realContext_t) void {
    _ = decNumberSquareRoot(result, rhs, ctxt);
}
inline fn realFMA(f1: *align(1) const real_t, f2: *align(1) const real_t, term: *align(1) const real_t, result: *real_t, ctxt: *realContext_t) void {
    _ = decNumberFMA(result, f1, f2, term, ctxt);
}
inline fn realCopy(source: *align(1) const real_t, destination: *real_t) void {
    _ = decNumberCopy(destination, source);
}
inline fn realCopyAbs(source: *align(1) const real_t, destination: *real_t) void {
    _ = decNumberCopyAbs(destination, source);
}
// realSetSignFrom(source, destination): the destination keeps its magnitude and takes the source's sign.
inline fn realSetSignFrom(source: *align(1) const real_t, destination: *real_t) void {
    _ = decNumberCopySign(destination, destination, source);
}
inline fn realMinus(operand: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberMinus(res, operand, ctxt);
}
inline fn realPlus(operand: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberPlus(res, operand, ctxt);
}
inline fn realDivideRemainder(operand1: *align(1) const real_t, operand2: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberRemainder(res, operand1, operand2, ctxt);
}
inline fn realSetNegativeSign(value: *real_t) void {
    value.bits |= 0x80;
}

const realIsZero = math_real_predicates.realIsZero;
const realIsNegative = math_real_predicates.realIsNegative;
const realIsPositive = math_real_predicates.realIsPositive;
const realIsSpecial = math_real_predicates.realIsSpecial;
const realIsInfinite = math_real_predicates.realIsInfinite;
const realIsNaN = math_real_predicates.realIsNaN;
const realSetZero = runtime.realSetZero;
const realSetOne = runtime.realSetOne;
const realSetNegativeOne = runtime.realSetNegativeOne;
const realSetNaN = runtime.realSetNaN;
const realChangeSign = runtime.realChangeSign;
const realSetPositiveSign = runtime.realSetPositiveSign;
const realToIntegralValue = runtime.realToIntegralValue;

const realCompareEqual = math_comparison_reals.realCompareEqual;
const realCompareLessThan = math_comparison_reals.realCompareLessThan;
const realCompareLessEqual = math_comparison_reals.realCompareLessEqual;
const realCompareGreaterThan = math_comparison_reals.realCompareGreaterThan;
const realCompareGreaterEqual = math_comparison_reals.realCompareGreaterEqual;
const realCompareAbsLessThan = math_comparison_reals.realCompareAbsLessThan;
const realCompareAbsGreaterThan = math_comparison_reals.realCompareAbsGreaterThan;

const REGISTER_X = runtime.REGISTER_X;
const REGISTER_Y = runtime.REGISTER_Y;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN = runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN;
const ERROR_INVALID_DATA_TYPE_FOR_OP = runtime.ERROR_INVALID_DATA_TYPE_FOR_OP;
const ERROR_RAM_FULL = runtime.ERROR_RAM_FULL;
const amNone = runtime.amNone;
const amRadian = runtime.amRadian;
const dtComplex34 = runtime.dtComplex34;
const DEC_ROUND_DOWN = runtime.DEC_ROUND_DOWN;
const DEC_ROUND_HALF_EVEN = runtime.DEC_ROUND_HALF_EVEN;
const FLAG_CPXRES: u16 = 0x8004;
const NOPARAM: u16 = 9876;
const ifLongIntegerDoAngleReduction = runtime.ifLongIntegerDoAngleReduction;

const TI_ELLIPSE_K: u8 = 133;
const TI_ELLIPSE_M: u8 = 134;
const TI_ELLIPSE_Theta: u8 = 135;

const ELLIPTIC_N: usize = 24;
const REAL_SIZE_IN_BLOCKS_75: usize = 15; // REAL_SIZE_IN_BLOCKS(75)

extern var temporaryInformation: u8;
extern var currentAngularMode: angularMode_t;

inline fn const_0() *const real_t {
    return runtime.z47_math_wrappers_const_0();
}
inline fn const_1() *const real_t {
    return runtime.z47_math_wrappers_const_1();
}
inline fn const_2() *const real_t {
    return runtime.z47_math_wrappers_const_2();
}

// ELLIPTIC_PI and friends: the 75-digit constant above 39 digits of context.
inline fn ellipticPiConst(c: *const realContext_t) *const real_t {
    return if (c.digits > 39) runtime.z47_math_wrappers_const75_pi() else consts.const39_pi();
}
inline fn ellipticPiOn2(c: *const realContext_t) *const real_t {
    return if (c.digits > 39) consts.const75_piOn2() else consts.const39_piOn2();
}
inline fn ellipticPiOn4(c: *const realContext_t) *const real_t {
    return if (c.digits > 39) runtime.z47_math_wrappers_const75_piOn4() else consts.const39_piOn4();
}
inline fn elliptic2Pi(c: *const realContext_t) *const real_t {
    return if (c.digits > 39) consts.const75_2pi() else consts.const39_2pi();
}

inline fn moreInfo(where: [*:0]const u8, what: [*:0]const u8) void {
    if (comptime runtime.extra_info_on_calc_error) {
        runtime.moreInfoOnError(where, what, null, null);
    }
}

inline fn realBlocks(p: *anyopaque) [*]real_t {
    return @ptrCast(@alignCast(p));
}
inline fn cplxBlocks(p: *anyopaque) [*]cplx_t {
    return @ptrCast(@alignCast(p));
}

// ===========================================================================
// _ellipseE / fnEllipse / fnKtoM / fnMtoK / fnMtoTheta / fnThetatoM
// ===========================================================================
fn _ellipseE() linksection(runtime.code_section) callconv(.c) void {
    var x: real_t = undefined;
    var y: real_t = undefined;
    if (!runtime.getRegisterAsReal(REGISTER_Y, &y) or !runtime.getRegisterAsReal(REGISTER_X, &x)) {
        return;
    }
    if (!runtime.saveLastX()) {
        return;
    }
    var reX: real_t = undefined;
    var a: real_t = undefined;
    var b: real_t = undefined;
    var sum: real_t = undefined;
    realCopyAbs(&x, &x);
    realCopyAbs(&y, &y);
    // ensure a <= b: a is smaller, b is larger
    if (realCompareGreaterThan(&x, &y)) {
        realCopy(&y, &a);
        realCopy(&x, &b);
    } else {
        realCopy(&x, &a);
        realCopy(&y, &b);
    }
    // e^2 = 1 - (a/b)^2, formed as ((b - a) / b) (1 + a / b)
    realSubtract(&b, &a, &reX, &runtime.ctxtReal39);
    realDivide(&reX, &b, &reX, &runtime.ctxtReal39);
    realDivide(&a, &b, &sum, &runtime.ctxtReal39);
    realAdd(const_1(), &sum, &sum, &runtime.ctxtReal39);
    realMultiply(&reX, &sum, &reX, &runtime.ctxtReal39);
    runtime.convertRealToResultRegister(&reX, REGISTER_X, amNone);
    runtime.adjustResult(REGISTER_X, false, false, -1, -1, -1);
    temporaryInformation = TI_ELLIPSE_M;
}

pub export fn fnEllipse(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    if (comptime !runtime.option_elliptic) return;
    _ = unusedButMandatoryParameter;
    runtime.processIntRealComplexDyadicFunction(&_ellipseE, null, &_ellipseE, &_ellipseE);
}

pub export fn fnKtoM(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    if (comptime !runtime.option_elliptic) return;
    _ = unusedButMandatoryParameter;
    math_command_wrappers.fnSquare(NOPARAM);
    temporaryInformation = TI_ELLIPSE_M;
}

pub export fn fnMtoK(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    if (comptime !runtime.option_elliptic) return;
    _ = unusedButMandatoryParameter;
    math_command_wrappers.fnSquareRoot(NOPARAM);
    temporaryInformation = TI_ELLIPSE_K;
}

pub export fn fnMtoTheta(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    if (comptime !runtime.option_elliptic) return;
    _ = unusedButMandatoryParameter;
    math_command_wrappers.fnSquareRoot(NOPARAM);
    math_inverse_trig_command.fnArcsin(NOPARAM);
    temporaryInformation = TI_ELLIPSE_Theta;
}

pub export fn fnThetatoM(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    if (comptime !runtime.option_elliptic) return;
    _ = unusedButMandatoryParameter;
    math_circular_trig_command.fnSin(NOPARAM);
    math_command_wrappers.fnSquare(NOPARAM);
    temporaryInformation = TI_ELLIPSE_M;
}

// ===========================================================================
// The real Jacobi functions
// ===========================================================================
fn snCnDnNaN(sn: *real_t, cn: *real_t, dn: *real_t) void {
    runtime.displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE);
    realSetNaN(sn);
    realSetNaN(cn);
    realSetNaN(dn);
}

fn _calc_real_elliptic(sn: *real_t, cn: *real_t, dn: *real_t, u: *const real_t, m: *const real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var a: real_t = undefined;
    var b: real_t = undefined;
    var e: real_t = undefined;
    var f: real_t = undefined;
    var g: real_t = undefined;
    var sin_umu: real_t = undefined;
    var cos_umu: real_t = undefined;
    var t: real_t = undefined;
    var r: real_t = undefined;

    const blocks = ELLIPTIC_N * REAL_SIZE_IN_BLOCKS_75;
    const MU_p = runtime.allocC47Blocks(blocks) orelse return snCnDnNaN(sn, cn, dn);
    defer runtime.freeC47Blocks(MU_p, blocks);
    const NU_p = runtime.allocC47Blocks(blocks) orelse return snCnDnNaN(sn, cn, dn);
    defer runtime.freeC47Blocks(NU_p, blocks);
    const C_p = runtime.allocC47Blocks(blocks) orelse return snCnDnNaN(sn, cn, dn);
    defer runtime.freeC47Blocks(C_p, blocks);
    const D_p = runtime.allocC47Blocks(blocks) orelse return snCnDnNaN(sn, cn, dn);
    defer runtime.freeC47Blocks(D_p, blocks);
    const MU = realBlocks(MU_p);
    const NU = realBlocks(NU_p);
    const C = realBlocks(C_p);
    const D = realBlocks(D_p);

    if (realIsNegative(m) or realCompareLessThan(const_1(), m)) {
        realSetNaN(sn);
        realSetNaN(cn);
        realSetNaN(dn);
        return;
    }
    if (realIsZero(m)) {
        runtime.C47_WP34S_Cvt2RadSinCosTan(u, amRadian, sn, cn, null, realContext);
        realSetOne(dn);
        return;
    }
    realSubtract(m, const_1(), &a, realContext);
    if (realIsZero(&a)) {
        runtime.WP34S_SinhCosh(u, &a, &b, realContext);
        realDivide(const_1(), &b, cn, realContext);
        realMultiply(&a, cn, sn, realContext);
        realCopy(cn, dn);
        return;
    }

    realSubtract(const_1(), m, &a, realContext);
    realSquareRoot(&a, &a, realContext);
    var n: usize = math_agm.realAgmStep(const_1(), &a, &b, MU, NU, ELLIPTIC_N, realContext);
    if (n == 0) {
        // No AGM step for |m| below about 1e-71: e = 0 selects the branch below
        // that gives sin u, cos u and 1, the m = 0 limit to 75 digits.
        realSetZero(&e);
    } else {
        realSubtract(&MU[n - 1], &NU[n - 1], &e, realContext);
    }

    realMultiply(u, &MU[n], &a, realContext);
    runtime.C47_WP34S_Cvt2RadSinCosTan(&a, amRadian, &sin_umu, &cos_umu, null, realContext);
    realCopyAbs(&cos_umu, &b);
    realDivide(&cos_umu, &sin_umu, &t, realContext);
    if (realIsZero(&sin_umu)) {
        realSetZero(sn);
        realSetOne(cn);
        realSetOne(dn);
        return;
    }

    realMultiply(&MU[n], &t, &C[n], realContext);
    realSetOne(&D[n]);

    while (n > 0) {
        n -= 1;
        realMultiply(&D[n + 1], &C[n + 1], &C[n], realContext);
        realMultiply(&C[n + 1], &C[n + 1], &a, realContext);
        realDivide(&a, &MU[n + 1], &r, realContext);
        realAdd(&r, &NU[n], &a, realContext);
        realAdd(&r, &MU[n], &b, realContext);
        realDivide(&a, &b, &D[n], realContext);
    }
    realFMA(&C[0], &C[0], const_1(), &f, realContext); // f = |1 + i c(0)|
    realSquareRoot(&f, &f, realContext);
    if (realIsNegative(&e)) {
        realSubtract(const_1(), m, &a, realContext);
        realSquareRoot(&a, &g, realContext);
        realDivide(&g, &D[0], dn, realContext);

        realDivide(dn, &f, cn, realContext);
        if (realIsNegative(&cos_umu)) {
            realChangeSign(cn);
        }

        realDivide(&C[0], &g, &a, realContext);
        realMultiply(cn, &a, sn, realContext);
    } else {
        realCopy(&D[0], dn);

        realDivide(const_1(), &f, sn, realContext);
        if (realIsNegative(&sin_umu)) {
            realChangeSign(sn);
        }
        realMultiply(&C[0], sn, cn, realContext);
    }
}

fn calc_real_elliptic(sn_in: ?*real_t, cn_in: ?*real_t, dn_in: ?*real_t, u: *const real_t, m: *const real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var s_n: real_t = undefined;
    var c_n: real_t = undefined;
    var d_n: real_t = undefined;
    const sn: *real_t = sn_in orelse &s_n;
    const cn: *real_t = cn_in orelse &c_n;
    const dn: *real_t = dn_in orelse &d_n;

    if (realCompareLessThan(const_1(), m)) {
        var k: real_t = undefined;
        var uk: real_t = undefined;
        var m_1: real_t = undefined;
        realSquareRoot(m, &k, realContext);
        realMultiply(&k, u, &uk, realContext);
        realDivide(const_1(), m, &m_1, realContext);
        _calc_real_elliptic(sn, dn, cn, &uk, &m_1, realContext);
        realDivide(sn, &k, sn, realContext);
    } else if (realIsNegative(m)) {
        var mu: real_t = undefined;
        var mu1: real_t = undefined;
        var v: real_t = undefined;
        var s: real_t = undefined;
        var c: real_t = undefined;
        var d: real_t = undefined;
        realSubtract(const_1(), m, &mu1, realContext);
        realDivide(const_1(), &mu1, &mu1, realContext);
        realMultiply(&mu1, m, &mu, realContext);
        realChangeSign(&mu);
        realSquareRoot(&mu1, &mu1, realContext);
        realDivide(u, &mu1, &v, realContext);
        _calc_real_elliptic(&s, &c, &d, &v, &mu, realContext);
        realDivide(&s, &d, sn, realContext);
        realDivide(&c, &d, cn, realContext);
        realDivide(const_1(), &d, dn, realContext);
        realMultiply(sn, &mu1, sn, realContext);
    } else {
        _calc_real_elliptic(sn, cn, dn, u, m, realContext);
    }
}

fn elliptic_setup_cpx_real(r: *real_t, snuk: *real_t, cnuk: *real_t, dnuk: *real_t, snvki: *real_t, cnvki: *real_t, dnvki: *real_t, u: *const real_t, v: *const real_t, m: *const real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var m_1: real_t = undefined;
    realSubtract(const_1(), m, &m_1, realContext);

    calc_real_elliptic(snuk, cnuk, dnuk, u, m, realContext);
    calc_real_elliptic(snvki, cnvki, dnvki, v, &m_1, realContext);

    realMultiply(m, snuk, r, realContext);
    realMultiply(r, snuk, r, realContext);
    realMultiply(r, snvki, r, realContext);
    realMultiply(r, snvki, r, realContext);
    realFMA(cnvki, cnvki, r, r, realContext);
}

fn jacobi_check_inputs(m: *real_t, u: *cplx_t, realInput: *bool) linksection(runtime.code_section) bool {
    var cmplx: bool = false;

    if (!runtime.getRegisterAsComplexOrReal(REGISTER_X, u, &cmplx) or !runtime.getRegisterAsReal(REGISTER_Y, m) or !runtime.saveLastX()) {
        return false;
    }
    realInput.* = !cmplx;
    return true;
}

fn jacobi_check_inputs_phi(m: *real_t, phi: *cplx_t, realInput: *bool) linksection(runtime.code_section) bool {
    if (runtime.getRegisterDataType(REGISTER_X) == dtComplex34) {
        return jacobi_check_inputs(m, phi, realInput);
    }
    var xAngularMode: angularMode_t = undefined;
    if (!runtime.getRegisterAsRealAngle(REGISTER_X, &phi.Real, &xAngularMode, !ifLongIntegerDoAngleReduction) or !runtime.getRegisterAsReal(REGISTER_Y, m) or !runtime.saveLastX()) {
        return false;
    }

    // No angle reduction here: the reduction of an elliptic amplitude is a lot
    // more complicated than a modulo 2 pi.
    runtime.convertAngleFromTo(&phi.Real, xAngularMode, amRadian, &runtime.ctxtReal75);
    realSetZero(&phi.Imag);
    realInput.* = true;
    return true;
}

/// Adds 2 pi n to am, the angle of cn + i sn in (-pi, pi], with
/// n = round(u / (4K) - am / (2 pi)) the winding count. For m < 1 am rises by pi
/// each 2K; subtracting the wrapped angle before rounding keeps n exact at an odd
/// multiple of 2K, where u / (4K) alone lands on a half-integer and the round tie
/// disagrees with the atan2 branch.
fn _jacobiAmUnfold(u: *const real_t, m: *const real_t, am: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var k: real_t = undefined;
    var t: real_t = undefined;

    ellipticKE(m, &k, null, realContext);
    realDivide(u, &k, &k, realContext);
    realMultiply(&k, consts.const_1on4(), &k, realContext);
    realDivide(am, consts.const75_2pi(), &t, realContext);
    realSubtract(&k, &t, &k, realContext);
    realToIntegralValue(&k, &k, DEC_ROUND_HALF_EVEN, realContext);
    realFMA(&k, consts.const75_2pi(), am, am, realContext);
}

pub export fn jacobiElliptic(u: *const real_t, m: *const real_t, am: ?*real_t, sn_in: ?*real_t, cn_in: ?*real_t, dn: ?*real_t, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    if (comptime !runtime.option_elliptic) return;
    var _sn: real_t = undefined;
    var _cn: real_t = undefined;
    const sn: *real_t = sn_in orelse &_sn;
    const cn: *real_t = cn_in orelse &_cn;

    calc_real_elliptic(sn, cn, dn, u, m, realContext);
    if (am) |amp| {
        // For m < 1 am is atan2(sn, cn) unfolded, which keeps its digits next to
        // u = K where asin(sn) folds into [-pi/2, pi/2]. For m >= 1, am stays
        // within asin(1 / sqrt m) of 0 and is asin(sn).
        if (realCompareLessThan(m, const_1())) {
            runtime.C47_WP34S_Atan2(sn, cn, amp, realContext);
            _jacobiAmUnfold(u, m, amp, realContext);
        } else {
            runtime.C47_WP34S_Asin(sn, amp, realContext);
        }
    }
}

pub export fn jacobiComplexAm(u: *const cplx_t, m: *const real_t, r: *cplx_t, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    if (comptime !runtime.option_elliptic) return;
    if (realCompareLessThan(m, const_1())) {
        // am = -i ln(cn + i sn), its real part unfolded as for a real u
        var s: cplx_t = undefined;
        var c: cplx_t = undefined;

        jacobiComplexSn(u, m, &s, realContext);
        jacobiComplexCn(u, m, &c, realContext);
        realSubtract(&c.Real, &s.Imag, &c.Real, realContext);
        realAdd(&c.Imag, &s.Real, &c.Imag, realContext);
        runtime.lnComplex(&c, &s, realContext);
        realCopy(&s.Imag, &r.Real);
        realCopy(&s.Real, &r.Imag);
        realChangeSign(&r.Imag);
        _jacobiAmUnfold(&u.Real, m, &r.Real, realContext);
    } else {
        jacobiComplexSn(u, m, r, realContext);
        _ = runtime.ArcsinComplex(r, r, realContext);
    }
}

pub export fn jacobiComplexSn(u: *const cplx_t, m: *const real_t, r: *cplx_t, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    if (comptime !runtime.option_elliptic) return;
    // SN(u + i v, m) = sn(u, m) . dn(v, 1-m) / denom
    //                  + i . cn(u, m) . dn(u, m) . sn(v, 1-m) . cn(v, 1-m) / denom
    // where
    //    denom = cn(v, 1-m)^2 + m * dn(u, m)^2 * sn(v, 1-m)^2
    var a: real_t = undefined;
    var b: real_t = undefined;
    var denom: real_t = undefined;
    var snuk: real_t = undefined;
    var cnuk: real_t = undefined;
    var dnuk: real_t = undefined;
    var snvki: real_t = undefined;
    var cnvki: real_t = undefined;
    var dnvki: real_t = undefined;
    elliptic_setup_cpx_real(&denom, &snuk, &cnuk, &dnuk, &snvki, &cnvki, &dnvki, &u.Real, &u.Imag, m, realContext);

    realMultiply(&snuk, &dnvki, &a, realContext);
    realDivide(&a, &denom, &r.Real, realContext);

    realMultiply(&cnuk, &dnuk, &a, realContext);
    realMultiply(&a, &snvki, &b, realContext);
    realMultiply(&b, &cnvki, &a, realContext);
    realDivide(&a, &denom, &r.Imag, realContext);
}

pub export fn jacobiComplexCn(u: *const cplx_t, m: *const real_t, r: *cplx_t, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    if (comptime !runtime.option_elliptic) return;
    // CN(u + i v, m) = cn(u, m) . cn(v, 1-m) / denom
    //                  - i . sn(u, m) . dn(u, m) . sn(v, 1-m) . dn(v, 1-m) / denom
    // where
    //    denom = cn(v, 1-m)^2 + m * dn(u, m)^2 * sn(v, 1-m)^2
    var a: real_t = undefined;
    var b: real_t = undefined;
    var denom: real_t = undefined;
    var snuk: real_t = undefined;
    var cnuk: real_t = undefined;
    var dnuk: real_t = undefined;
    var snvki: real_t = undefined;
    var cnvki: real_t = undefined;
    var dnvki: real_t = undefined;
    elliptic_setup_cpx_real(&denom, &snuk, &cnuk, &dnuk, &snvki, &cnvki, &dnvki, &u.Real, &u.Imag, m, realContext);

    realMultiply(&cnuk, &cnvki, &a, realContext);
    realDivide(&a, &denom, &r.Real, realContext);

    realMultiply(&snuk, &dnuk, &a, realContext);
    realMultiply(&a, &snvki, &b, realContext);
    realMultiply(&b, &dnvki, &a, realContext);
    realDivide(&a, &denom, &b, realContext);
    realMinus(&b, &r.Imag, realContext);
}

pub export fn jacobiComplexDn(u: *const cplx_t, m: *const real_t, r: *cplx_t, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    if (comptime !runtime.option_elliptic) return;
    // DN(u + i v, m) = dn(u, m) . cn(v, 1-m) . dn(v, 1-m) / denom
    //                  - i . m . sn(u, m) . cn(u, m) . sn(v, 1-m) / denom
    // where
    //    denom = cn(v, 1-m)^2 + m * dn(u, m)^2 * sn(v, 1-m)^2
    var a: real_t = undefined;
    var b: real_t = undefined;
    var denom: real_t = undefined;
    var snuk: real_t = undefined;
    var cnuk: real_t = undefined;
    var dnuk: real_t = undefined;
    var snvki: real_t = undefined;
    var cnvki: real_t = undefined;
    var dnvki: real_t = undefined;
    elliptic_setup_cpx_real(&denom, &snuk, &cnuk, &dnuk, &snvki, &cnvki, &dnvki, &u.Real, &u.Imag, m, realContext);

    realMultiply(&dnuk, &cnvki, &a, realContext);
    realMultiply(&a, &dnvki, &b, realContext);
    realDivide(&b, &denom, &r.Real, realContext);

    realMinus(m, &b, realContext);
    realMultiply(&b, &snuk, &a, realContext);
    realMultiply(&a, &cnuk, &b, realContext);
    realMultiply(&b, &snvki, &a, realContext);
    realDivide(&a, &denom, &r.Imag, realContext);
}

// ===========================================================================
// Complete integrals K and E
// ===========================================================================
/// K(m) and E(m) for real m; k or e may be null. NaN for m > 1, where the
/// integrals are complex: ellipticComplexKE gives those.
pub export fn ellipticKE(m: *const real_t, k: ?*real_t, e: ?*real_t, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    if (comptime !runtime.option_elliptic) return;
    if (k) |p| realSetNaN(p);
    if (e) |p| realSetNaN(p);

    if (realCompareLessEqual(m, const_1())) {
        if (realCompareEqual(m, const_1())) {
            if (k) |p| realSetPlusInfinity(p);
            if (e) |p| realSetOne(p);
        } else if (realCompareEqual(m, const_0())) {
            if (k) |p| realCopy(ellipticPiOn2(realContext), p);
            if (e) |p| realCopy(ellipticPiOn2(realContext), p);
        } else {
            var a: real_t = undefined;
            var b: real_t = undefined;

            realSubtract(const_1(), m, &b, realContext);
            realSquareRoot(&b, &b, realContext);
            realCopy(m, &a);
            _ = math_agm.realAgmForE(const_1(), &b, &a, &b, realContext);
            realDivide(ellipticPiOn2(realContext), &b, &b, realContext);
            if (k) |p| realCopy(&b, p);

            if (e) |p| {
                realSubtract(&a, const_1(), &a, realContext);
                realChangeSign(&a);
                realMultiply(&a, &b, &b, realContext);
                realCopy(&b, p);
            }
        }
    }
}

/// K(m) and E(m), complex for m > 1; k or e may be null.
pub export fn ellipticComplexKE(m: *const real_t, k: ?*cplx_t, e: ?*cplx_t, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    if (comptime !runtime.option_elliptic) return;
    if (realCompareLessEqual(m, const_1())) {
        ellipticKE(m, if (k) |p| &p.Real else null, if (e) |p| &p.Real else null, realContext);
        if (k) |p| realSetZero(&p.Imag);
        if (e) |p| realSetZero(&p.Imag);
    } else if (k != null and e == null) {
        // K(m) = (K(1/m) - i K(1 - 1/m)) / sqrt(m) and K(x) = pi/2 / AGM(1, sqrt(1 - x))
        // give K(m) = pi/2 / AGM(sqrt(m), sqrt(m - 1)) - i pi/2 / AGM(sqrt(m), 1), as
        // the AGM scales with its arguments. No 1 - 1/m is rounded on the way, which at
        // p39 keeps only 39 - log10(m) digits of 1/m. An infinite m gives the limit 0
        // and a NaN gives NaN, here without the AGM.
        const kk = k.?;
        var a: real_t = undefined;
        var b: real_t = undefined;

        if (realIsSpecial(m)) {
            realDivide(const_1(), m, &kk.Real, realContext);
            realDivide(consts.const__1(), m, &kk.Imag, realContext);
        } else {
            realSquareRoot(m, &a, realContext);
            realSubtract(m, const_1(), &b, realContext);
            realSquareRoot(&b, &b, realContext);
            _ = math_agm.realAgm(&a, &b, &b, realContext);
            _ = math_agm.realAgm(&a, const_1(), &a, realContext);
            realDivide(ellipticPiOn2(realContext), &b, &kk.Real, realContext);
            realDivide(ellipticPiOn2(realContext), &a, &kk.Imag, realContext);
            realChangeSign(&kk.Imag);
        }
    } else {
        var a: cplx_t = undefined;
        var c: cplx_t = undefined;
        var one: cplx_t = undefined;

        realSubtract(m, const_1(), &a.Imag, realContext);
        realSquareRoot(&a.Imag, &a.Imag, realContext);
        realSetZero(&a.Real);
        realCopy(m, &c.Real);
        realSetZero(&c.Imag);
        realSetOne(&one.Real);
        realSetZero(&one.Imag);
        _ = math_agm.complexAgmForE(&one, &a, &c, &a, realContext);
        runtime.divRealComplex(ellipticPiOn2(realContext), &a, &a, realContext);
        if (k) |p| {
            realCopy(&a.Real, &p.Real);
            realCopy(&a.Imag, &p.Imag);
        }

        if (e) |p| {
            realSubtract(&c.Real, const_1(), &c.Real, realContext);
            realChangeSign(&c.Real);
            realChangeSign(&c.Imag);
            runtime.mulComplexComplex(&a, &c, p, realContext);
        }
    }
}

fn rcSqrt(x: *const real_t, res: *cplx_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var xx: real_t = undefined;

    realCopy(x, &xx);
    if (realIsNegative(&xx)) {
        realSetPositiveSign(&xx);
        realSquareRoot(&xx, &res.Imag, realContext);
        realSetZero(&res.Real);
    } else {
        realSquareRoot(&xx, &res.Real, realContext);
        realSetZero(&res.Imag);
    }
}

fn atanRealOrComplex(z: *cplx_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    if (realIsZero(&z.Imag)) {
        runtime.C47_WP34S_Atan(&z.Real, &z.Real, realContext);
    } else {
        _ = runtime.ArctanComplex(z, z, realContext);
    }
}

fn _ellipticFE_lambda_mu(amplitude: *const cplx_t, m: *const real_t, lambda: *cplx_t, mu: *cplx_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    const phi = &amplitude.Real;
    const psi = &amplitude.Imag;
    // Abramowitz & Stegun §17.4.11
    var m1: real_t = undefined;
    var b: real_t = undefined;
    var c: real_t = undefined;
    var csc2Phi: real_t = undefined;
    var tan2Phi: real_t = undefined;
    var cot2Phi: real_t = undefined;
    var sinh2Psi: real_t = undefined;
    var cot2Lambda: cplx_t = undefined;

    realSubtract(const_1(), m, &m1, realContext);

    runtime.C47_WP34S_Cvt2RadSinCosTan(phi, amRadian, &csc2Phi, &cot2Phi, &tan2Phi, realContext);
    realDivide(const_1(), &csc2Phi, &csc2Phi, realContext);
    realMultiply(&csc2Phi, &csc2Phi, &csc2Phi, realContext);
    realDivide(const_1(), &tan2Phi, &cot2Phi, realContext);
    realMultiply(&tan2Phi, &tan2Phi, &tan2Phi, realContext);
    realMultiply(&cot2Phi, &cot2Phi, &cot2Phi, realContext);
    runtime.WP34S_SinhCosh(psi, &sinh2Psi, null, realContext);
    realMultiply(&sinh2Psi, &sinh2Psi, &sinh2Psi, realContext);

    realMultiply(m, &sinh2Psi, &b, realContext);
    realFMA(&b, &csc2Phi, &cot2Phi, &b, realContext);
    realSubtract(&b, &m1, &b, realContext);
    realChangeSign(&b);
    realMultiply(&m1, &cot2Phi, &c, realContext);
    realChangeSign(&c);

    realMultiply(consts.const__4(), &c, &cot2Lambda.Real, realContext);
    realFMA(&b, &b, &cot2Lambda.Real, &cot2Lambda.Real, realContext);
    rcSqrt(&cot2Lambda.Real, &cot2Lambda, realContext);
    realSubtract(&cot2Lambda.Real, &b, &cot2Lambda.Real, realContext);
    realMultiply(&cot2Lambda.Real, consts.const_1on2(), &cot2Lambda.Real, realContext);
    realMultiply(&cot2Lambda.Imag, consts.const_1on2(), &cot2Lambda.Imag, realContext);

    if (realIsZero(&cot2Lambda.Imag)) {
        realDivide(const_1(), &cot2Lambda.Real, &lambda.Real, realContext);
        rcSqrt(&lambda.Real, lambda, realContext);
        atanRealOrComplex(lambda, realContext);

        if (realIsZero(&cot2Lambda.Real) and realIsZero(&cot2Lambda.Imag)) {
            realSetNegativeOne(&mu.Real);
        } else {
            realFMA(&tan2Phi, &cot2Lambda.Real, consts.const__1(), &mu.Real, realContext);
        }
        realDivide(&mu.Real, m, &mu.Real, realContext);
        rcSqrt(&mu.Real, mu, realContext);
        atanRealOrComplex(mu, realContext);
    } else {
        runtime.divRealComplex(const_1(), &cot2Lambda, lambda, realContext);
        runtime.sqrtComplex(lambda, lambda, realContext);
        _ = runtime.ArctanComplex(lambda, lambda, realContext);

        if (realIsZero(&cot2Lambda.Real) and realIsZero(&cot2Lambda.Imag)) {
            realSetNegativeOne(&mu.Real);
            realSetZero(&mu.Imag);
        } else {
            realFMA(&tan2Phi, &cot2Lambda.Real, consts.const__1(), &mu.Real, realContext);
            realMultiply(&tan2Phi, &cot2Lambda.Imag, &mu.Imag, realContext);
        }
        realDivide(&mu.Real, m, &mu.Real, realContext);
        realDivide(&mu.Imag, m, &mu.Imag, realContext);
        runtime.sqrtComplex(mu, mu, realContext);
        _ = runtime.ArctanComplex(mu, mu, realContext);
    }
}

// ===========================================================================
// Carlson symmetric integrals
// ===========================================================================
inline fn carlsonTolerance(realContext: *const realContext_t) *const real_t {
    return if (realContext.digits <= 39) consts.const_1e_37() else consts.const_1e_49();
}

/// Carlson RF via duplication, DLMF 19.26.17: RF(x,y,z) = 1/sqrt(A) at convergence.
fn carlsonRF(x0: *const real_t, y0: *const real_t, z0: *const real_t, res: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var x: real_t = undefined;
    var y: real_t = undefined;
    var z: real_t = undefined;
    var sx: real_t = undefined;
    var sy: real_t = undefined;
    var sz: real_t = undefined;
    var lam: real_t = undefined;
    var lam4: real_t = undefined;
    const tol = carlsonTolerance(realContext);
    realCopy(x0, &x);
    realCopy(y0, &y);
    realCopy(z0, &z);
    while (true) {
        realSquareRoot(&x, &sx, realContext);
        realSquareRoot(&y, &sy, realContext);
        realSquareRoot(&z, &sz, realContext);
        realMultiply(&sx, &sy, &lam, realContext);
        realFMA(&sy, &sz, &lam, &lam, realContext); // lam = sqrt(xy)+sqrt(yz)+sqrt(zx)
        realFMA(&sz, &sx, &lam, &lam, realContext);
        realMultiply(&lam, consts.const_1on4(), &lam4, realContext); // lam4 = lam/4
        realFMA(&x, consts.const_1on4(), &lam4, &x, realContext); // x = x/4 + lam/4
        realFMA(&y, consts.const_1on4(), &lam4, &y, realContext); // y = y/4 + lam/4
        realFMA(&z, consts.const_1on4(), &lam4, &z, realContext); // z = z/4 + lam/4
        if (runtime.WP34S_RelativeError(&x, &y, tol, realContext) and runtime.WP34S_RelativeError(&x, &z, tol, realContext)) break;
    }
    realSquareRoot(&x, res, realContext);
    realDivide(const_1(), res, res, realContext);
}

/// Carlson RD via the duplication algorithm, Carlson 1995 eq. 2.7:
/// RD(x,y,z) = 3*sum_k fac_k/(sz_k*(z_k+lam_k)) + fac_n/A^(3/2).
fn carlsonRD(x0: *const real_t, y0: *const real_t, z0: *const real_t, res: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var x: real_t = undefined;
    var y: real_t = undefined;
    var z: real_t = undefined;
    var sx: real_t = undefined;
    var sy: real_t = undefined;
    var sz: real_t = undefined;
    var lam: real_t = undefined;
    var lam4: real_t = undefined;
    var sum: real_t = undefined;
    var fac: real_t = undefined;
    var t: real_t = undefined;
    const tol = carlsonTolerance(realContext);
    realCopy(x0, &x);
    realCopy(y0, &y);
    realCopy(z0, &z);
    realSetZero(&sum);
    realSetOne(&fac);
    while (true) {
        realSquareRoot(&x, &sx, realContext);
        realSquareRoot(&y, &sy, realContext);
        realSquareRoot(&z, &sz, realContext);
        realMultiply(&sx, &sy, &lam, realContext);
        realFMA(&sy, &sz, &lam, &lam, realContext); // lam = sqrt(xy)+sqrt(yz)+sqrt(zx)
        realFMA(&sz, &sx, &lam, &lam, realContext);
        realAdd(&z, &lam, &t, realContext); // t = z + lam
        realMultiply(&t, &sz, &t, realContext); // t = sz*(z+lam)
        realDivide(&fac, &t, &t, realContext); // t = fac/(sz*(z+lam))
        realAdd(&sum, &t, &sum, realContext); // sum += fac/(sz*(z+lam))
        realMultiply(&lam, consts.const_1on4(), &lam4, realContext); // lam4 = lam/4
        realFMA(&x, consts.const_1on4(), &lam4, &x, realContext); // x = x/4 + lam/4
        realFMA(&y, consts.const_1on4(), &lam4, &y, realContext); // y = y/4 + lam/4
        realFMA(&z, consts.const_1on4(), &lam4, &z, realContext); // z = z/4 + lam/4
        realMultiply(&fac, consts.const_1on4(), &fac, realContext); // fac /= 4
        if (runtime.WP34S_RelativeError(&x, &y, tol, realContext) and runtime.WP34S_RelativeError(&x, &z, tol, realContext)) break;
    }
    realSquareRoot(&x, &sx, realContext); // sx = sqrt(A)
    realMultiply(&x, &sx, res, realContext); // res = A^(3/2)
    realDivide(&fac, res, res, realContext); // res = fac/A^(3/2)
    realFMA(consts.const_3(), &sum, res, res, realContext); // RD = 3*sum + fac/A^(3/2)
}

/// Carlson RC(1, 1+x) for x greater than -1.
fn carlsonRC1p(x: *const real_t, res: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var root: real_t = undefined;

    if (realIsZero(x)) {
        realSetOne(res);
    } else if (realIsPositive(x)) {
        realSquareRoot(x, &root, realContext);
        runtime.C47_WP34S_Atan(&root, res, realContext);
        realDivide(res, &root, res, realContext);
    } else {
        realCopyAbs(x, &root);
        realSquareRoot(&root, &root, realContext);
        runtime.WP34S_ArcTanh(&root, res, realContext);
        realDivide(res, &root, res, realContext);
    }
}

/// Carlson RJ for nonnegative x, y, z and positive p.
fn carlsonRJ(x0: *const real_t, y0: *const real_t, z0: *const real_t, p0: *const real_t, res: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var x: real_t = undefined;
    var y: real_t = undefined;
    var z: real_t = undefined;
    var p: real_t = undefined;
    var sx: real_t = undefined;
    var sy: real_t = undefined;
    var sz: real_t = undefined;
    var sp: real_t = undefined;
    var lam: real_t = undefined;
    var dm: real_t = undefined;
    var em: real_t = undefined;
    var rc: real_t = undefined;
    var sum: real_t = undefined;
    var fac: real_t = undefined;
    var a: real_t = undefined;
    var b: real_t = undefined;
    var delta: real_t = undefined;
    const tol = carlsonTolerance(realContext);

    realCopy(x0, &x);
    realCopy(y0, &y);
    realCopy(z0, &z);
    realCopy(p0, &p);
    realSubtract(p0, x0, &delta, realContext);
    realSubtract(p0, y0, &a, realContext);
    realMultiply(&delta, &a, &delta, realContext);
    realSubtract(p0, z0, &a, realContext);
    realMultiply(&delta, &a, &delta, realContext);
    realSetZero(&sum);
    realSetOne(&fac);

    while (true) {
        realSquareRoot(&x, &sx, realContext);
        realSquareRoot(&y, &sy, realContext);
        realSquareRoot(&z, &sz, realContext);
        realSquareRoot(&p, &sp, realContext);
        realMultiply(&sx, &sy, &lam, realContext);
        realFMA(&sx, &sz, &lam, &lam, realContext);
        realFMA(&sy, &sz, &lam, &lam, realContext);

        realAdd(&sp, &sx, &dm, realContext);
        realAdd(&sp, &sy, &a, realContext);
        realMultiply(&dm, &a, &dm, realContext);
        realAdd(&sp, &sz, &a, realContext);
        realMultiply(&dm, &a, &dm, realContext);
        realMultiply(&fac, &fac, &em, realContext);
        realMultiply(&em, &fac, &em, realContext);
        realMultiply(&em, &delta, &em, realContext);
        realMultiply(&dm, &dm, &a, realContext);
        realDivide(&em, &a, &em, realContext);
        carlsonRC1p(&em, &rc, realContext);
        realMultiply(&fac, &rc, &a, realContext);
        realDivide(&a, &dm, &a, realContext);
        realAdd(&sum, &a, &sum, realContext);

        realMultiply(&lam, consts.const_1on4(), &a, realContext);
        realFMA(&x, consts.const_1on4(), &a, &x, realContext);
        realFMA(&y, consts.const_1on4(), &a, &y, realContext);
        realFMA(&z, consts.const_1on4(), &a, &z, realContext);
        realFMA(&p, consts.const_1on4(), &a, &p, realContext);
        realMultiply(&fac, consts.const_1on4(), &fac, realContext);
        if (runtime.WP34S_RelativeError(&x, &y, tol, realContext) and
            runtime.WP34S_RelativeError(&x, &z, tol, realContext) and
            runtime.WP34S_RelativeError(&x, &p, tol, realContext)) break;
    }

    realAdd(&x, &y, &a, realContext);
    realAdd(&a, &z, &a, realContext);
    realFMA(&p, const_2(), &a, &a, realContext);
    realDivide(&a, consts.const_5(), &a, realContext);
    realSquareRoot(&a, &b, realContext);
    realMultiply(&a, &b, &a, realContext);
    realDivide(&fac, &a, res, realContext);
    realFMA(consts.const_6(), &sum, res, res, realContext);
}

// ===========================================================================
// Incomplete integrals of the first and second kind
// ===========================================================================
/// F(phi, m) = sin(phi) * RF(cos^2(phi), 1 - m*sin^2(phi), 1).
fn _ellipticF(phi: *const real_t, m: *const real_t, res: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var s: real_t = undefined;
    var c: real_t = undefined;
    var s2: real_t = undefined;
    var y: real_t = undefined;
    runtime.C47_WP34S_Cvt2RadSinCosTan(phi, amRadian, &s, &c, null, realContext);
    realMultiply(&s, &s, &s2, realContext); // s2 = sin²phi
    realMultiply(&c, &c, &c, realContext); // c  = cos²phi
    realMultiply(m, &s2, &y, realContext);
    realSubtract(const_1(), &y, &y, realContext); // y = 1 - m*sin²phi
    carlsonRF(&c, &y, const_1(), res, realContext); // RF(cos²,1-m*sin²,1)
    realMultiply(&s, res, res, realContext); // F = sin*RF
}

/// The real incomplete elliptic integral of the second kind on the reduced interval.
fn _ellipticE(phi: *const real_t, m: *const real_t, res: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var s: real_t = undefined;
    var c: real_t = undefined;
    var s2: real_t = undefined;
    var y: real_t = undefined;
    var rf: real_t = undefined;
    var rd: real_t = undefined;
    var a: real_t = undefined;

    runtime.C47_WP34S_Cvt2RadSinCosTan(phi, amRadian, &s, &c, null, realContext);
    realMultiply(&s, &s, &s2, realContext);
    realMultiply(&c, &c, &c, realContext);
    realMultiply(m, &s2, &y, realContext);
    realSubtract(const_1(), &y, &y, realContext);
    carlsonRF(&c, &y, const_1(), &rf, realContext);
    carlsonRD(&c, &y, const_1(), &rd, realContext);
    realMultiply(&s, &rf, res, realContext);
    realMultiply(&s2, &s, &a, realContext);
    realMultiply(&a, m, &a, realContext);
    realDivide(&a, consts.const_3(), &a, realContext);
    realChangeSign(&a);
    realFMA(&a, &rd, res, res, realContext);
}

/// True when m sin^2(phi) is at most 1, where the Carlson forms of F(phi|m) and
/// E(phi|m) are real. The product is rounded as in _ellipticF and _ellipticE, so
/// their 1 - m sin^2(phi) is not negative when this returns true.
fn _ellipticCarlsonReal(phi: *const real_t, m: *const real_t, realContext: *realContext_t) linksection(runtime.code_section) bool {
    var s: real_t = undefined;

    runtime.C47_WP34S_Cvt2RadSinCosTan(phi, amRadian, &s, null, null, realContext);
    realMultiply(&s, &s, &s, realContext);
    realMultiply(m, &s, &s, realContext);
    return !realCompareGreaterThan(&s, const_1());
}

/// Carlson RF handles the full [0, pi/2] range without cancellation; no
/// transformation is needed.
fn _ellipticF_1(phi: *const real_t, m: *const real_t, res: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    _ellipticF(phi, m, res, realContext);
}

/// Real phi and 0 <= m <= 1. Abramowitz & Stegun §17.4.1, §17.4.3.
fn _ellipticF_2(phi: *const real_t, m: *const real_t, res: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var phi1: real_t = undefined;
    var phiQuotient: real_t = undefined;
    var phiRemainder: real_t = undefined;
    var remainderNegative = false;

    realCopyAbs(phi, &phi1);
    realDivide(&phi1, ellipticPiConst(realContext), &phiQuotient, realContext);
    realToIntegralValue(&phiQuotient, &phiQuotient, DEC_ROUND_DOWN, realContext);
    realDivideRemainder(&phi1, ellipticPiConst(realContext), &phiRemainder, realContext);
    if (realCompareGreaterThan(&phiRemainder, ellipticPiOn2(realContext))) {
        realAdd(&phiQuotient, const_1(), &phiQuotient, realContext);
        realSubtract(ellipticPiConst(realContext), &phiRemainder, &phiRemainder, realContext);
        remainderNegative = true;
    }

    if (realIsZero(&phiQuotient)) {
        _ellipticF_1(&phiRemainder, m, res, realContext);
    } else {
        realAdd(&phiQuotient, &phiQuotient, &phiQuotient, realContext);
        ellipticKE(m, &phi1, null, realContext);
        _ellipticF_1(&phiRemainder, m, res, realContext);
        if (remainderNegative) {
            realChangeSign(res);
        }
        realFMA(&phiQuotient, &phi1, res, res, realContext);
    }

    if (realIsNegative(phi)) {
        realChangeSign(res);
    }
}

fn _ellipticF_3(phi: *const real_t, m: *const real_t, res: *cplx_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    if (realIsZero(m)) {
        // Abramowitz & Stegun §17.4.19-20
        realCopy(phi, &res.Real);
        realSetZero(&res.Imag);
    } else if (realCompareGreaterThan(m, const_1())) {
        // Abramowitz & Stegun §17.4.15. One precision level above the caller
        // absorbs the cancellation in ArcsinComplex for |sqrt(m) sin(phi)| > 1,
        // which calculates the complex theta with a loss of precision.
        var m_1: real_t = undefined;
        var k: cplx_t = undefined;
        var a: cplx_t = undefined;
        var theta: cplx_t = undefined;
        const hCtx = &runtime.ctxtReal75;
        runtime.mod2Pi(phi, &theta.Real, hCtx);
        runtime.C47_WP34S_Cvt2RadSinCosTan(&theta.Real, amRadian, &a.Real, null, null, hCtx);
        realSquareRoot(m, &k.Real, hCtx);
        realSetZero(&k.Imag);
        realDivide(const_1(), m, &m_1, hCtx);
        realMultiply(&k.Real, &a.Real, &a.Real, hCtx);
        realSetZero(&a.Imag);
        _ = runtime.ArcsinComplex(&a, &theta, hCtx);
        ellipticF(&theta, &m_1, res, hCtx); // recurses with m_1 = 1/m
        runtime.divComplexComplex(res, &k, res, hCtx);
        realPlus(&res.Real, &res.Real, realContext); // round back to the caller's precision
        realPlus(&res.Imag, &res.Imag, realContext);
    } else if (realIsPositive(m)) {
        _ellipticF_2(phi, m, &res.Real, realContext);
        realSetZero(&res.Imag);
    } else {
        _ellipticF(phi, m, &res.Real, realContext);
        realSetZero(&res.Imag);
    }
}

fn _ellipticF_4(amplitude: *const cplx_t, m: *const real_t, res: *cplx_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    const phi = &amplitude.Real;
    const psi = &amplitude.Imag;
    if (realIsZero(psi)) {
        _ellipticF_3(phi, m, res, realContext);
    } else if (realIsZero(phi)) {
        // Abramowitz & Stegun §17.4.8
        var m1: real_t = undefined;
        var theta: real_t = undefined;

        realSubtract(const_1(), m, &m1, realContext);
        _ = math_gd.GudermannianReal(psi, &theta, realContext);
        _ellipticF_3(&theta, &m1, res, realContext);
        runtime.mulComplexi(res, res);
    } else {
        // Abramowitz & Stegun §17.4.11
        var m1: real_t = undefined;
        var lambda: cplx_t = undefined;
        var mu: cplx_t = undefined;
        var f: cplx_t = undefined;

        realSubtract(const_1(), m, &m1, realContext);
        _ellipticFE_lambda_mu(amplitude, m, &lambda, &mu, realContext);

        if (realIsZero(&lambda.Imag)) {
            _ellipticF_3(&lambda.Real, m, &f, realContext);
        } else {
            ellipticF(&lambda, m, &f, realContext); // recurses here
        }
        realCopy(&f.Real, &res.Real);
        realCopy(&f.Imag, &res.Imag);
        if (realIsZero(&mu.Imag)) {
            _ellipticF_3(&mu.Real, &m1, &f, realContext);
        } else {
            _ellipticF_4(&mu, &m1, &f, realContext); // recurses here
        }
        realAdd(&res.Imag, &f.Real, &res.Imag, realContext);
        realSubtract(&res.Real, &f.Imag, &res.Real, realContext);
    }
}

fn _ellipticF_5(amplitude: *const cplx_t, m: *const real_t, res: *cplx_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    const phi = &amplitude.Real;
    const psi = &amplitude.Imag;
    if (realIsInfinite(psi) and !realIsZero(phi)) {
        // F(phi + i inf | m) = i K(1 - m) for 0 < phi <= pi/2, the limit of
        // Abramowitz & Stegun §17.4.8 at phi = 0 from the right: far above the real
        // axis the integrand falls as e^-Im, so the limit does not depend on phi.
        // phi = 0 takes §17.4.8 in _ellipticF_4, as for m < 0 the imaginary axis is
        // a cut where F is odd. ellipticF sets the sign of the imaginary part and
        // adds the half turns as for a finite psi.
        var m1: real_t = undefined;
        var k: cplx_t = undefined;

        realSubtract(const_1(), m, &m1, realContext);
        ellipticComplexKE(&m1, &k, null, realContext);
        realMinus(&k.Imag, &res.Real, realContext);
        realCopy(&k.Real, &res.Imag);
        return;
    }
    // Abramowitz & Stegun §17.4.13
    if (realCompareAbsGreaterThan(phi, ellipticPiOn4(realContext))) {
        var m1: real_t = undefined;
        var psiZ: cplx_t = undefined;
        var k1: cplx_t = undefined;
        var tanPhi: cplx_t = undefined;
        var k: cplx_t = undefined;
        if (realIsZero(psi) and realCompareAbsLessThan(phi, ellipticPiOn2(realContext)) and (!realCompareGreaterThan(m, const_1()) or _ellipticCarlsonReal(phi, m, realContext))) {
            // Real phi in (pi/4, pi/2), m sin^2(phi) <= 1: Carlson RF avoids the K - F cancellation.
            _ellipticF(phi, m, &res.Real, realContext);
            realSetZero(&res.Imag);
            return;
        }
        ellipticComplexKE(m, &k, null, realContext);
        if (realIsNegative(psi)) {
            realChangeSign(&k.Imag); // conjugate
        }
        realCopy(phi, &tanPhi.Real);
        realCopy(psi, &tanPhi.Imag);
        _ = runtime.TanComplex(&tanPhi, &tanPhi, realContext);
        realSubtract(const_1(), m, &m1, realContext);
        rcSqrt(&m1, &k1, realContext);
        runtime.mulComplexComplex(&k1, &tanPhi, &psiZ, realContext);
        runtime.divRealComplex(const_1(), &psiZ, &psiZ, realContext);
        atanRealOrComplex(&psiZ, realContext);
        _ellipticF_4(&psiZ, m, res, realContext);

        if (!realIsZero(&k.Imag)) {
            if (realIsPositive(&k.Imag)) {
                realSetPositiveSign(&res.Imag);
            } else {
                realSetNegativeSign(&res.Imag);
            }
        }
        realSubtract(&k.Real, &res.Real, &res.Real, realContext);
        realSubtract(&k.Imag, &res.Imag, &res.Imag, realContext);

        if (realIsPositive(psi)) {
            realSetPositiveSign(&res.Imag);
        } else {
            realSetNegativeSign(&res.Imag);
        }
        if (!realIsZero(&k.Imag) and realIsNegative(&k.Imag)) {
            realChangeSign(&res.Imag);
        }
    } else {
        _ellipticF_4(amplitude, m, res, realContext);
    }
}

/// F(phi|m), E(phi|m) or Z(phi|m) for a NaN or infinite amplitude or parameter:
/// NaN, with a zero imaginary part when the amplitude is real. With grows set, a
/// real amplitude of +-inf and a finite m of at most 1 give +-inf, since F and E
/// rise by 2K(m) or 2E(m) each half turn there.
fn _ellipticSpecialArguments(amplitude: *const cplx_t, m: *const real_t, grows: bool, res: *cplx_t) linksection(runtime.code_section) void {
    const phi = &amplitude.Real;
    const psi = &amplitude.Imag;

    if (grows and realIsInfinite(phi) and realIsZero(psi) and !realIsSpecial(m) and realCompareLessEqual(m, const_1())) {
        realCopy(phi, &res.Real);
    } else {
        realSetNaN(&res.Real);
    }
    if (realIsZero(psi)) {
        realSetZero(&res.Imag);
    } else {
        realSetNaN(&res.Imag);
    }
}

pub export fn ellipticF(amplitude: *const cplx_t, m: *const real_t, res: *cplx_t, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    if (comptime !runtime.option_elliptic) return;
    const phi = &amplitude.Real;
    const psi = &amplitude.Imag;
    // Abramowitz & Stegun §17.4.1, §17.4.3
    var phi1: real_t = undefined;
    var phiQuotient: real_t = undefined;
    var reduced: cplx_t = undefined;
    var remainderNegative = false;

    // _ellipticF_5 and _ellipticF_4 hand a NaN amplitude back to ellipticF, which
    // would repeat without end. An infinite psi with a finite phi and m takes the
    // route below, where _ellipticF_5 returns its limit.
    if (realIsSpecial(phi) or realIsNaN(psi) or realIsSpecial(m)) {
        _ellipticSpecialArguments(amplitude, m, true, res);
        return;
    }
    realCopy(phi, &phi1);
    realCopy(psi, &reduced.Imag);
    if (realIsNegative(phi)) {
        realChangeSign(&phi1);
        realChangeSign(&reduced.Imag);
    }
    realDivide(&phi1, ellipticPiConst(realContext), &phiQuotient, realContext);
    realToIntegralValue(&phiQuotient, &phiQuotient, DEC_ROUND_DOWN, realContext);
    realDivideRemainder(&phi1, ellipticPiConst(realContext), &reduced.Real, realContext);
    if (realCompareGreaterThan(&reduced.Real, ellipticPiOn2(realContext))) {
        realAdd(&phiQuotient, const_1(), &phiQuotient, realContext);
        realSubtract(ellipticPiConst(realContext), &reduced.Real, &reduced.Real, realContext);
        remainderNegative = true;
    }

    if (realIsZero(phi) and realIsZero(psi)) {
        realSetZero(&res.Real);
        realSetZero(&res.Imag);
        return;
    } else if (realIsZero(m)) {
        realCopy(phi, &res.Real);
        realCopy(psi, &res.Imag);
        return;
    } else if (realCompareEqual(m, const_1())) {
        var p: cplx_t = undefined;
        realFMA(phi, consts.const_1on2(), ellipticPiOn4(realContext), &p.Real, realContext);
        realMultiply(psi, consts.const_1on2(), &p.Imag, realContext);
        if (realIsZero(&p.Imag)) {
            runtime.C47_WP34S_Cvt2RadSinCosTan(&p.Real, amRadian, &res.Real, &res.Imag, &p.Imag, realContext);
            runtime.WP34S_Ln(&p.Imag, &res.Real, realContext);
            realSetZero(&res.Imag);
        } else {
            _ = runtime.TanComplex(&p, &p, realContext);
            runtime.lnComplex(&p, res, realContext);
            if (realIsZero(&p.Real)) {
                realSetZero(&res.Real);
            }
        }
        return;
    } else if (realIsZero(&phiQuotient)) {
        _ellipticF_5(&reduced, m, res, realContext);
        if (remainderNegative) {
            realChangeSign(&res.Real);
            realChangeSign(&res.Imag);
        }
        if (realIsNegative(phi)) {
            realChangeSign(&res.Real);
            realChangeSign(&res.Imag);
        }
    } else {
        var k: cplx_t = undefined;

        realAdd(&phiQuotient, &phiQuotient, &phiQuotient, realContext);
        _ellipticF_5(&reduced, m, res, realContext);
        if (remainderNegative) {
            realChangeSign(&res.Real);
            realChangeSign(&res.Imag);
        }
        if (!realIsZero(psi)) {
            realSetSignFrom(&reduced.Imag, &res.Imag);
        }
        ellipticComplexKE(m, &k, null, realContext);
        realFMA(&phiQuotient, &k.Real, &res.Real, &res.Real, realContext);
        realFMA(&phiQuotient, &k.Imag, &res.Imag, &res.Imag, realContext);
        if (realIsNegative(phi)) {
            realChangeSign(&res.Real);
            realChangeSign(&res.Imag);
        }
    }

    if (realCompareGreaterThan(m, const_1()) and (realCompareAbsGreaterThan(phi, ellipticPiOn2(realContext)) or realIsZero(psi))) {
        if (realIsPositive(phi)) {
            realSetNegativeSign(&res.Imag);
        } else {
            realSetPositiveSign(&res.Imag);
        }
    } else {
        if (realIsPositive(psi)) {
            realSetPositiveSign(&res.Imag);
        } else if (realIsNegative(psi)) {
            realSetNegativeSign(&res.Imag);
        }
    }
}

/// E(phi|m) from the Jacobi zeta function.
fn _ellipticE_fromZeta(amplitude: *const cplx_t, m: *const real_t, res: *cplx_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var k: cplx_t = undefined;
    var e: cplx_t = undefined;
    var f: cplx_t = undefined;
    var z: cplx_t = undefined;

    ellipticComplexKE(m, &k, &e, realContext);
    ellipticF(amplitude, m, &f, realContext);
    jacobiZeta(amplitude, m, &z, realContext);
    runtime.divComplexComplex(&e, &k, res, realContext);
    runtime.mulComplexComplex(res, &f, res, realContext);
    realAdd(&res.Real, &z.Real, &res.Real, realContext);
    realAdd(&res.Imag, &z.Imag, &res.Imag, realContext);
}

// The 25-real scratch block of the complex E(phi + i psi | m) branch: twelve
// complex slots and M1 in the real half of slot 12, the last real of the block.
const ETmp = struct {
    const LAMBDA = 0;
    const MU = 1;
    const B1 = 2;
    const B2 = 3;
    const B3 = 4;
    const SIN_LAMBDA = 5;
    const SIN2_LAMBDA = 6;
    const COS_LAMBDA = 7;
    const SIN_MU = 8;
    const SIN2_MU = 9;
    const COS_MU = 10;
    const COS2_MU = 11;
    const M1_SLOT = 12;
};
const E_TMP_BLOCKS: usize = 25 * REAL_SIZE_IN_BLOCKS_75;

pub export fn ellipticE(amplitude: *const cplx_t, m: *const real_t, res: *cplx_t, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    if (comptime !runtime.option_elliptic) return;
    const phi = &amplitude.Real;
    const psi = &amplitude.Imag;
    var phi1: real_t = undefined;
    var phiQuotient: real_t = undefined;
    var reduced: cplx_t = undefined;

    if (realIsSpecial(phi) or realIsSpecial(psi) or realIsSpecial(m)) {
        _ellipticSpecialArguments(amplitude, m, true, res);
        return;
    }
    realCopyAbs(phi, &phi1);
    realCopyAbs(psi, &reduced.Imag);
    realDivide(&phi1, ellipticPiConst(realContext), &phiQuotient, realContext);
    realToIntegralValue(&phiQuotient, &phiQuotient, DEC_ROUND_DOWN, realContext);
    realDivideRemainder(&phi1, ellipticPiConst(realContext), &reduced.Real, realContext);
    if (realCompareGreaterThan(&reduced.Real, ellipticPiOn2(realContext))) {
        realAdd(&phiQuotient, const_1(), &phiQuotient, realContext);
        realSubtract(&reduced.Real, ellipticPiConst(realContext), &reduced.Real, realContext);
    }
    if (realIsNegative(phi)) {
        realChangeSign(&phi1);
        realChangeSign(&phiQuotient);
        realChangeSign(&reduced.Real);
        realChangeSign(&reduced.Imag);
    }

    if (realIsZero(m)) {
        realCopy(phi, &res.Real);
        realCopy(psi, &res.Imag);
    } else if (realCompareEqual(m, const_1())) {
        if (realIsZero(psi)) {
            runtime.C47_WP34S_Cvt2RadSinCosTan(&reduced.Real, amRadian, &res.Real, null, null, realContext);
            realSetZero(&res.Imag);
            realAdd(&res.Real, &phiQuotient, &res.Real, realContext);
            realAdd(&res.Real, &phiQuotient, &res.Real, realContext);
        } else {
            realCopy(&reduced.Real, &res.Real);
            realCopy(psi, &res.Imag);
            runtime.sinComplex(res, res, realContext);
            realAdd(&res.Real, &phiQuotient, &res.Real, realContext);
            realAdd(&res.Real, &phiQuotient, &res.Real, realContext);
        }
    } else if (realIsZero(psi) and realCompareGreaterThan(m, const_1()) and (!realIsZero(&phiQuotient) or !_ellipticCarlsonReal(phi, m, realContext))) {
        // For |phi| <= pi/2 and m sin^2(phi) <= 1 E is real, and the Carlson form
        // below returns it where E from Z leaves an imaginary part. Beyond that E is
        // complex.
        var realPhi: cplx_t = undefined;

        realCopy(phi, &realPhi.Real);
        realSetZero(&realPhi.Imag);
        _ellipticE_fromZeta(&realPhi, m, res, realContext);
    } else if (realIsZero(psi)) {
        var e: real_t = undefined;
        _ellipticE(&reduced.Real, m, &res.Real, realContext);
        if (!realIsZero(&phiQuotient)) {
            ellipticKE(m, null, &e, realContext);
            realAdd(&phiQuotient, &phiQuotient, &phiQuotient, realContext);
            realFMA(&phiQuotient, &e, &res.Real, &res.Real, realContext);
        }
        realSetZero(&res.Imag);
    } else if (realIsZero(phi)) {
        var m1: real_t = undefined;
        var a: cplx_t = undefined;
        var c: cplx_t = undefined;
        var theta: cplx_t = undefined;

        _ = math_gd.GudermannianReal(psi, &theta.Real, realContext);
        realSetZero(&theta.Imag);
        realSubtract(const_1(), m, &m1, realContext);

        runtime.C47_WP34S_Cvt2RadSinCosTan(&theta.Real, amRadian, &c.Real, &c.Imag, &a.Real, realContext);

        realMultiply(&c.Real, &c.Real, &c.Real, realContext);
        realMultiply(&c.Real, &m1, &c.Real, realContext);
        realSubtract(const_1(), &c.Real, &c.Real, realContext);
        rcSqrt(&c.Real, &c, realContext);
        realSetZero(&a.Imag);
        runtime.mulComplexComplex(&a, &c, &a, realContext);

        ellipticF(&theta, &m1, &c, realContext);
        realAdd(&a.Real, &c.Real, &a.Real, realContext);
        realAdd(&a.Imag, &c.Imag, &a.Imag, realContext);
        ellipticE(&theta, &m1, &c, realContext);
        realSubtract(&a.Real, &c.Real, &a.Real, realContext);
        realSubtract(&a.Imag, &c.Imag, &a.Imag, realContext);

        runtime.mulComplexi(&a, res);
    } else {
        const tmp_p = runtime.allocC47Blocks(E_TMP_BLOCKS) orelse {
            runtime.displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE);
            realSetNaN(&res.Real);
            realSetNaN(&res.Imag);
            return;
        };
        defer runtime.freeC47Blocks(tmp_p, E_TMP_BLOCKS);
        const tmpVal = cplxBlocks(tmp_p);
        const LAMBDA = &tmpVal[ETmp.LAMBDA];
        const MU = &tmpVal[ETmp.MU];
        const B1 = &tmpVal[ETmp.B1];
        const B2 = &tmpVal[ETmp.B2];
        const B3 = &tmpVal[ETmp.B3];
        const SIN_LAMBDA = &tmpVal[ETmp.SIN_LAMBDA];
        const SIN2_LAMBDA = &tmpVal[ETmp.SIN2_LAMBDA];
        const COS_LAMBDA = &tmpVal[ETmp.COS_LAMBDA];
        const SIN_MU = &tmpVal[ETmp.SIN_MU];
        const SIN2_MU = &tmpVal[ETmp.SIN2_MU];
        const COS_MU = &tmpVal[ETmp.COS_MU];
        const COS2_MU = &tmpVal[ETmp.COS2_MU];
        const M1 = &tmpVal[ETmp.M1_SLOT].Real;

        const remainderNegative = realIsNegative(&reduced.Real);
        const realContext2 = &runtime.ctxtReal75;
        const realContext3 = &runtime.ctxtReal75;

        if (remainderNegative) {
            realChangeSign(&reduced.Real);
        }
        realSubtract(const_1(), m, M1, realContext2);
        _ellipticFE_lambda_mu(&reduced, m, LAMBDA, MU, realContext2);
        runtime.sinComplex(LAMBDA, SIN_LAMBDA, realContext2);
        runtime.cosComplex(LAMBDA, COS_LAMBDA, realContext2);
        runtime.sinComplex(MU, SIN_MU, realContext2);
        runtime.cosComplex(MU, COS_MU, realContext2);
        runtime.mulComplexComplex(SIN_LAMBDA, SIN_LAMBDA, SIN2_LAMBDA, realContext2);
        runtime.mulComplexComplex(SIN_MU, SIN_MU, SIN2_MU, realContext2);
        runtime.mulComplexComplex(COS_MU, COS_MU, COS2_MU, realContext2);

        realMultiply(m, &SIN2_LAMBDA.Real, &B1.Real, realContext2);
        realMultiply(m, &SIN2_LAMBDA.Imag, &B1.Imag, realContext2);
        realSubtract(const_1(), &B1.Real, &B2.Real, realContext2);
        realSubtract(const_0(), &B1.Imag, &B2.Imag, realContext2);
        runtime.sqrtComplex(B2, B1, realContext2);
        runtime.mulComplexComplex(SIN2_MU, B1, B1, realContext2);
        runtime.mulComplexComplex(COS_LAMBDA, B1, B1, realContext2);
        runtime.mulComplexComplex(SIN_LAMBDA, B1, B1, realContext2);
        realMultiply(m, &B1.Real, &B1.Real, realContext2);
        realMultiply(m, &B1.Imag, &B1.Imag, realContext2);

        realMultiply(M1, &SIN2_MU.Real, &B3.Real, realContext2);
        realMultiply(M1, &SIN2_MU.Imag, &B3.Imag, realContext2);
        realSubtract(const_1(), &B3.Real, &B3.Real, realContext2);
        realSubtract(const_0(), &B3.Imag, &B3.Imag, realContext2);
        runtime.sqrtComplex(B3, B3, realContext2);
        runtime.mulComplexComplex(B2, B3, B2, realContext2);
        runtime.mulComplexComplex(B2, SIN_MU, B2, realContext2);
        runtime.mulComplexComplex(B2, COS_MU, B2, realContext2);

        realMultiply(m, &SIN2_LAMBDA.Real, &B3.Real, realContext2);
        realMultiply(m, &SIN2_LAMBDA.Imag, &B3.Imag, realContext2);
        runtime.mulComplexComplex(B3, SIN2_MU, B3, realContext2);
        realAdd(&COS2_MU.Real, &B3.Real, &B3.Real, realContext2);
        realAdd(&COS2_MU.Imag, &B3.Imag, &B3.Imag, realContext2);

        realSubtract(&B1.Real, &B2.Imag, &res.Real, realContext2);
        realAdd(&B1.Imag, &B2.Real, &res.Imag, realContext2);
        runtime.divComplexComplex(res, B3, res, realContext2);

        ellipticE(LAMBDA, m, B1, realContext3);
        ellipticE(MU, M1, B2, realContext3);
        ellipticF(MU, M1, B3, realContext3);

        realSubtract(&res.Real, &B3.Imag, &res.Real, realContext);
        realAdd(&res.Imag, &B3.Real, &res.Imag, realContext);
        realAdd(&res.Real, &B2.Imag, &res.Real, realContext);
        realSubtract(&res.Imag, &B2.Real, &res.Imag, realContext);
        realAdd(&res.Real, &B1.Real, &res.Real, realContext);
        realAdd(&res.Imag, &B1.Imag, &res.Imag, realContext);

        if (remainderNegative) {
            realChangeSign(&res.Real);
        }

        if (realIsNegative(psi)) {
            realChangeSign(&res.Imag);
        }

        if (!realIsZero(&phiQuotient)) {
            ellipticComplexKE(m, null, B1, realContext);
            realAdd(&phiQuotient, &phiQuotient, &phiQuotient, realContext);
            realMultiply(&phiQuotient, &B1.Real, &B1.Real, realContext);
            realMultiply(&phiQuotient, &B1.Imag, &B1.Imag, realContext);
            realAdd(&res.Real, &B1.Real, &res.Real, realContext);
            realAdd(&res.Imag, &B1.Imag, &res.Imag, realContext);
        }
    }
}

// ===========================================================================
// Jacobi zeta function
// ===========================================================================
fn _jacobiZeta_Agm(amplitude: *const cplx_t, m: *const real_t, res: *cplx_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    if (realIsZero(m)) {
        realSetZero(&res.Real);
        realSetZero(&res.Imag);
        return;
    }
    if (realCompareEqual(m, const_1())) {
        var k: cplx_t = undefined;
        ellipticF(amplitude, m, &k, realContext);
        _ = runtime.TanhComplex(&k, res, realContext);
        return;
    }
    const blocks = ELLIPTIC_N * 2 * REAL_SIZE_IN_BLOCKS_75;
    const a_p = runtime.allocC47Blocks(blocks) orelse {
        runtime.displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE);
        realSetNaN(&res.Real);
        realSetNaN(&res.Imag);
        return;
    };
    defer runtime.freeC47Blocks(a_p, blocks);
    const b_p = runtime.allocC47Blocks(blocks) orelse {
        runtime.displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE);
        realSetNaN(&res.Real);
        realSetNaN(&res.Imag);
        return;
    };
    defer runtime.freeC47Blocks(b_p, blocks);
    const a = cplxBlocks(a_p);
    const b = cplxBlocks(b_p);

    var k: cplx_t = undefined;
    var c: cplx_t = undefined;
    var s: cplx_t = undefined;
    var q: real_t = undefined;

    realSetZero(&res.Real);
    realSetZero(&res.Imag);
    realSubtract(const_1(), m, &k.Real, realContext);
    rcSqrt(&k.Real, &k, realContext);
    realSetOne(&s.Real); // s takes 1 + 0i, the first AGM argument, until sinComplex() below
    realSetZero(&s.Imag);
    const n: usize = math_agm.complexAgmStep(&s, &k, &c, a, b, ELLIPTIC_N, realContext);
    ellipticF(amplitude, m, &k, realContext);
    runtime.mulComplexComplex(&k, &a[n], &k, realContext);
    for (0..n) |_| {
        realAdd(&k.Real, &k.Real, &k.Real, realContext);
        realAdd(&k.Imag, &k.Imag, &k.Imag, realContext);
    }
    var i: usize = n;
    while (i > 0) : (i -= 1) {
        realCopy(&k.Real, &q);
        runtime.mod2Pi(&q, &k.Real, realContext);
        if (realCompareGreaterThan(&k.Real, ellipticPiConst(realContext))) {
            realSubtract(&k.Real, elliptic2Pi(realContext), &k.Real, realContext); // shift k to (-pi, pi]
        }
        realSubtract(&q, &k.Real, &q, realContext);
        realSubtract(&a[i - 1].Real, &b[i - 1].Real, &c.Real, realContext);
        realSubtract(&a[i - 1].Imag, &b[i - 1].Imag, &c.Imag, realContext);
        realMultiply(&c.Real, consts.const_1on2(), &c.Real, realContext);
        realMultiply(&c.Imag, consts.const_1on2(), &c.Imag, realContext);
        runtime.sinComplex(&k, &s, realContext);
        runtime.mulComplexComplex(&s, &c, &s, realContext);
        realAdd(&s.Real, &res.Real, &res.Real, realContext);
        realAdd(&s.Imag, &res.Imag, &res.Imag, realContext);
        runtime.divComplexComplex(&s, &a[i], &s, realContext);
        if (realIsZero(&s.Imag) and !realCompareAbsLessThan(const_1(), &s.Real)) {
            runtime.C47_WP34S_Asin(&s.Real, &s.Real, realContext);
        } else {
            _ = runtime.ArcsinComplex(&s, &s, realContext);
        }
        realAdd(&s.Real, &k.Real, &s.Real, realContext);
        realAdd(&s.Imag, &k.Imag, &s.Imag, realContext);
        realAdd(&s.Real, &q, &s.Real, realContext);
        realMultiply(&s.Real, consts.const_1on2(), &k.Real, realContext);
        realMultiply(&s.Imag, consts.const_1on2(), &k.Imag, realContext);
    }
}

/// Z(phi|m) = E(phi|m) - (E(m)/K(m)) F(phi|m) for real phi and 0 <= m <= 1 only,
/// from Carlson RF and RD so that it does not recurse through ellipticE:
/// E(phi|m) = sin(phi) RF(cos²phi, 1-m sin²phi, 1) - (m/3) sin³(phi) RD(cos²phi, 1-m sin²phi, 1)
/// F(phi|m) = sin(phi) RF(cos²phi, 1-m sin²phi, 1)
fn _jacobiZeta_carlson(phi: *const real_t, m: *const real_t, res: *cplx_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var s: real_t = undefined;
    var c: real_t = undefined;
    var s2: real_t = undefined;
    var c2: real_t = undefined;
    var y: real_t = undefined;
    var rf: real_t = undefined;
    var rd: real_t = undefined;
    var e_phi: real_t = undefined;
    var f_phi: real_t = undefined;
    var ek: real_t = undefined;
    var em: real_t = undefined;
    var delta: real_t = undefined;
    var delta2: real_t = undefined;
    var limit: real_t = undefined;
    var root: real_t = undefined;
    if (realIsZero(m)) {
        realSetZero(&res.Real);
        realSetZero(&res.Imag);
        return;
    }
    if (realCompareEqual(m, const_1())) {
        var k: cplx_t = undefined;
        var realPhi: cplx_t = undefined;
        realCopy(phi, &realPhi.Real);
        realSetZero(&realPhi.Imag);
        ellipticF(&realPhi, m, &k, realContext);
        _ = runtime.TanhComplex(&k, res, realContext);
        return;
    }
    if (realCompareLessThan(m, consts.const_1e_37())) {
        runtime.C47_WP34S_Cvt2RadSinCosTan(phi, amRadian, &s, &c, null, realContext);
        realMultiply(m, &s, &res.Real, realContext);
        realMultiply(&res.Real, &c, &res.Real, realContext);
        realMultiply(&res.Real, consts.const_1on2(), &res.Real, realContext);
        realSetZero(&res.Imag);
        return;
    }
    realSubtract(phi, ellipticPiOn2(realContext), &delta, realContext);
    realMultiply(&delta, &delta, &delta2, realContext);
    realSubtract(const_1(), m, &y, realContext);
    realMultiply(&y, consts.const_1e_37(), &limit, realContext);
    if (realCompareLessThan(&delta2, &limit)) {
        ellipticKE(m, &ek, &em, realContext);
        realDivide(&em, &ek, &em, realContext);
        realSubtract(&y, &em, &em, realContext);
        realSquareRoot(&y, &root, realContext);
        realDivide(&em, &root, &em, realContext);
        realMultiply(&delta, &em, &res.Real, realContext);
        realSetZero(&res.Imag);
        return;
    }
    runtime.C47_WP34S_Cvt2RadSinCosTan(phi, amRadian, &s, &c, null, realContext);
    realMultiply(&s, &s, &s2, realContext); // s2 = sin²phi
    realMultiply(&c, &c, &c2, realContext); // c2 = cos²phi
    realFMA(m, &s2, consts.const__1(), &y, realContext);
    realChangeSign(&y); // y = 1 - m*sin²phi
    carlsonRF(&c2, &y, const_1(), &rf, realContext); // RF(cos²,1-m*sin²,1)
    carlsonRD(&c2, &y, const_1(), &rd, realContext); // RD(cos²,1-m*sin²,1)
    realMultiply(&s, &rf, &f_phi, realContext); // F(phi|m) = sin*RF
    realMultiply(&s2, &s, &s2, realContext); // sin³
    realMultiply(m, &s2, &s2, realContext);
    realDivide(&s2, consts.const_3(), &s2, realContext); // (m/3)*sin³
    realChangeSign(&s2); // -(m/3)*sin³
    realFMA(&s2, &rd, &f_phi, &e_phi, realContext); // E(phi|m) = f_phi - (m/3)*sin³*RD
    ellipticKE(m, &ek, &em, realContext); // ek = K(m), em = E(m), real for 0 <= m <= 1
    realDivide(&em, &ek, &em, realContext); // E(m)/K(m)
    realChangeSign(&em); // -E(m)/K(m)
    realFMA(&em, &f_phi, &e_phi, &res.Real, realContext); // Z = e_phi - E(m)/K(m)*F(phi|m)
    realSetZero(&res.Imag);
}

fn _jacobiZeta(amplitude: *const cplx_t, m: *const real_t, res: *cplx_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    const phi = &amplitude.Real;
    const psi = &amplitude.Imag;
    if (realCompareLessEqual(m, const_1())) {
        if (realIsZero(psi) and !realIsNegative(m)) {
            // Real phi, 0 <= m <= 1: Carlson RF/RD; _jacobiZeta_Agm is wrong here.
            _jacobiZeta_carlson(phi, m, res, realContext);
        } else {
            // Complex phi or negative m: the AGM back-substitution handles these.
            _jacobiZeta_Agm(amplitude, m, res, realContext);
        }
    } else {
        var n: u32 = 0;
        var pp: real_t = undefined;
        var phiZ: cplx_t = undefined;
        var u: cplx_t = undefined;
        realCopy(phi, &phiZ.Real);
        realCopy(psi, &phiZ.Imag);
        ellipticF(&phiZ, m, &u, realContext);

        if (realCompareLessEqual(m, const_2())) {
            realCopy(consts.const_1on4(), &pp);
        } else {
            realDivide(consts.const_1on2(), m, &pp, realContext);
        }

        while (realCompareGreaterThan(&phiZ.Real, &pp)) {
            n += 1;
            realMultiply(&u.Real, consts.const_1on2(), &u.Real, realContext);
            realMultiply(&u.Imag, consts.const_1on2(), &u.Imag, realContext);
            jacobiComplexAm(&u, m, &phiZ, realContext);
        }

        _jacobiZeta_Agm(&phiZ, m, res, realContext);
        while (n > 0) : (n -= 1) {
            var a: cplx_t = undefined;
            var c: cplx_t = undefined;
            realAdd(&res.Real, &res.Real, &res.Real, realContext);
            realAdd(&res.Imag, &res.Imag, &res.Imag, realContext);
            jacobiComplexSn(&u, m, &a, realContext);
            runtime.mulComplexComplex(&a, &a, &a, realContext);
            realMultiply(&a.Real, m, &a.Real, realContext);
            realMultiply(&a.Imag, m, &a.Imag, realContext);
            realAdd(&u.Real, &u.Real, &u.Real, realContext);
            realAdd(&u.Imag, &u.Imag, &u.Imag, realContext);
            jacobiComplexSn(&u, m, &c, realContext);
            runtime.mulComplexComplex(&a, &c, &a, realContext);
            realSubtract(&res.Real, &a.Real, &res.Real, realContext);
            realSubtract(&res.Imag, &a.Imag, &res.Imag, realContext);
        }
    }
}

pub export fn jacobiZeta(amplitude: *const cplx_t, m: *const real_t, res: *cplx_t, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    if (comptime !runtime.option_elliptic) return;
    const phi = &amplitude.Real;
    const psi = &amplitude.Imag;
    var reduced: cplx_t = undefined;
    var negative = realIsNegative(phi);

    if (realIsSpecial(phi) or realIsSpecial(psi) or realIsSpecial(m)) { // Z repeats with period pi in phi
        _ellipticSpecialArguments(amplitude, m, false, res);
        return;
    }
    if (realIsZero(m)) {
        realSetZero(&res.Real);
        realSetZero(&res.Imag);
        return;
    }

    realCopy(phi, &reduced.Real);
    realCopy(psi, &reduced.Imag);
    if (negative) {
        realChangeSign(&reduced.Real);
        realChangeSign(&reduced.Imag);
    }
    realSetNaN(&res.Real);
    realSetNaN(&res.Imag);

    runtime.WP34S_Mod(&reduced.Real, ellipticPiConst(realContext), &reduced.Real, realContext);
    if (realCompareGreaterThan(&reduced.Real, ellipticPiOn2(realContext))) {
        realSubtract(ellipticPiConst(realContext), &reduced.Real, &reduced.Real, realContext);
        realChangeSign(&reduced.Imag);
        negative = !negative;
    }
    if (realIsZero(&reduced.Imag)) {
        _jacobiZeta(&reduced, m, res, realContext);
    } else {
        var a: cplx_t = undefined;
        var c: cplx_t = undefined;
        ellipticComplexKE(m, &a, &c, realContext);
        runtime.divComplexComplex(&c, &a, &a, realContext);
        ellipticF(&reduced, m, &c, realContext);
        runtime.mulComplexComplex(&a, &c, &a, realContext);
        ellipticE(&reduced, m, &c, realContext);
        realSubtract(&c.Real, &a.Real, &res.Real, realContext);
        realSubtract(&c.Imag, &a.Imag, &res.Imag, realContext);
    }

    if (negative) {
        realChangeSign(&res.Real);
        realChangeSign(&res.Imag);
    }
}

// ===========================================================================
// Complete integral of the third kind
// ===========================================================================
/// The Cauchy principal value of the complete Pi(n, m) for n greater than one.
fn ellipticPiPrincipalValue(n: *const real_t, m: *const real_t, res: *cplx_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var nn: real_t = undefined;
    var m1: real_t = undefined;
    var p: real_t = undefined;
    var rj: real_t = undefined;

    realDivide(m, n, &nn, realContext);
    realSubtract(const_1(), m, &m1, realContext);
    realSubtract(const_1(), &nn, &p, realContext);
    carlsonRJ(const_0(), &m1, const_1(), &p, &rj, realContext);
    realMultiply(&nn, &rj, &res.Real, realContext);
    realDivide(&res.Real, consts.const_3(), &res.Real, realContext);
    realChangeSign(&res.Real);
    realSetZero(&res.Imag);
}

/// The complete Pi(n, m) directly from Carlson RF and RJ for n less than one.
fn ellipticPiCarlson(n: *const real_t, m: *const real_t, res: *cplx_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var m1: real_t = undefined;
    var p: real_t = undefined;
    var rf: real_t = undefined;
    var rj: real_t = undefined;
    var a: real_t = undefined;

    realSubtract(const_1(), m, &m1, realContext);
    realSubtract(const_1(), n, &p, realContext);
    carlsonRF(const_0(), &m1, const_1(), &rf, realContext);
    carlsonRJ(const_0(), &m1, const_1(), &p, &rj, realContext);
    realMultiply(n, &rj, &a, realContext);
    realDivide(&a, consts.const_3(), &a, realContext);
    realAdd(&rf, &a, &res.Real, realContext);
    realSetZero(&res.Imag);
}

/// The complete Pi(n, m) after mapping n less than -1 into the bounded interval (-1, 0).
fn ellipticPiNegative(n: *const real_t, m: *const real_t, res: *cplx_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var q: real_t = undefined;
    var m1: real_t = undefined;
    var p: real_t = undefined;
    var rj: real_t = undefined;
    var h: real_t = undefined;
    var a: real_t = undefined;
    var b: real_t = undefined;

    realDivide(m, n, &q, realContext);
    realSubtract(const_1(), m, &m1, realContext);
    realSubtract(const_1(), &q, &p, realContext);
    carlsonRJ(const_0(), &m1, const_1(), &p, &rj, realContext);
    realMultiply(&q, &rj, &res.Real, realContext);
    realDivide(&res.Real, consts.const_3(), &res.Real, realContext);
    realChangeSign(&res.Real);

    realSubtract(const_1(), n, &a, realContext);
    realSubtract(n, m, &b, realContext);
    realMultiply(n, &b, &h, realContext);
    realMultiply(&h, &a, &h, realContext);
    realSquareRoot(&h, &h, realContext);
    realMultiply(n, ellipticPiOn2(realContext), &a, realContext);
    realDivide(&a, &h, &a, realContext);
    realSubtract(&res.Real, &a, &res.Real, realContext);
    realSetZero(&res.Imag);
}

pub export fn ellipticPi(n: *const real_t, m: *const real_t, res: *cplx_t, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    if (comptime !runtime.option_elliptic) return;
    if (realIsNaN(n) or realIsNaN(m)) {
        realSetNaN(&res.Real);
        realSetZero(&res.Imag);
    } else if (realIsZero(n)) {
        ellipticComplexKE(m, res, null, realContext);
    } else if (realIsZero(m)) {
        // Abramowitz & Stegun §17.7.20
        if (realCompareLessThan(n, const_1())) {
            // pi / (2 sqrt(1 - n)), the limit of Arctan(sqrt(1-n) tan(phi)) / sqrt(1-n) as phi -> pi/2
            var piOn2: cplx_t = undefined;

            realSubtract(const_1(), n, &res.Real, realContext);
            rcSqrt(&res.Real, res, realContext);
            realCopy(ellipticPiOn2(realContext), &piOn2.Real);
            realSetZero(&piOn2.Imag);
            runtime.divComplexComplex(&piOn2, res, res, realContext);
        } else if (realCompareGreaterThan(n, const_1())) {
            // -(pi/2) i / sqrt(n-1), the limit of Arctanh(sqrt(n-1) tan(phi)) / sqrt(n-1) as phi -> pi/2
            var i: cplx_t = undefined;

            realSubtract(n, const_1(), &res.Real, realContext);
            rcSqrt(&res.Real, res, realContext);
            realSetZero(&i.Real);
            realSetOne(&i.Imag);
            runtime.divComplexComplex(&i, res, res, realContext);
            realMultiply(ellipticPiOn2(realContext), &res.Real, &res.Real, realContext);
            realMultiply(ellipticPiOn2(realContext), &res.Imag, &res.Imag, realContext);
            realChangeSign(&res.Real);
            realChangeSign(&res.Imag);
        } else { // n = 1
            realSetNaN(&res.Real);
            realSetZero(&res.Imag); // unsigned infinity
        }
    } else if (realCompareEqual(m, const_1())) {
        if (realCompareLessThan(n, const_1())) {
            realSetPlusInfinity(&res.Real);
            realSetZero(&res.Imag);
        } else if (realCompareGreaterThan(n, const_1())) {
            realSetMinusInfinity(&res.Real);
            realSetZero(&res.Imag);
        } else { // n = 1
            realSetNaN(&res.Real);
            realSetZero(&res.Imag); // unsigned infinity
        }
    } else if (realCompareGreaterThan(n, const_1())) {
        ellipticPiPrincipalValue(n, m, res, realContext);
    } else if (realIsInfinite(n)) {
        realSetZero(&res.Real);
        realSetZero(&res.Imag);
    } else if (realCompareLessThan(n, consts.const__1())) {
        ellipticPiNegative(n, m, res, realContext);
    } else {
        ellipticPiCarlson(n, m, res, realContext);
    }
}

// ===========================================================================
// Commands
// ===========================================================================
const JacobiFunction = enum { sn, cn, dn };

fn jacobiCommand(comptime which: JacobiFunction) void {
    var realInput: bool = undefined;
    var m: real_t = undefined;
    var u: cplx_t = undefined;
    var r: cplx_t = undefined;

    if (!jacobi_check_inputs(&m, &u, &realInput)) {
        return;
    }

    if (realInput) {
        switch (which) {
            .sn => jacobiElliptic(&u.Real, &m, null, &r.Real, null, null, &runtime.ctxtReal75),
            .cn => jacobiElliptic(&u.Real, &m, null, null, &r.Real, null, &runtime.ctxtReal75),
            .dn => jacobiElliptic(&u.Real, &m, null, null, null, &r.Real, &runtime.ctxtReal75),
        }
        runtime.convertRealToResultRegister(&r.Real, REGISTER_X, amNone);
    } else {
        switch (which) {
            .sn => jacobiComplexSn(&u, &m, &r, &runtime.ctxtReal75),
            .cn => jacobiComplexCn(&u, &m, &r, &runtime.ctxtReal75),
            .dn => jacobiComplexDn(&u, &m, &r, &runtime.ctxtReal75),
        }
        runtime.convertComplexToResultRegister(&r, REGISTER_X);
    }

    runtime.adjustResult(REGISTER_X, true, true, REGISTER_X, -1, -1);
}

pub export fn fnJacobiSn(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    if (comptime !runtime.option_elliptic) return;
    _ = unusedButMandatoryParameter;
    jacobiCommand(.sn);
}

pub export fn fnJacobiCn(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    if (comptime !runtime.option_elliptic) return;
    _ = unusedButMandatoryParameter;
    jacobiCommand(.cn);
}

pub export fn fnJacobiDn(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    if (comptime !runtime.option_elliptic) return;
    _ = unusedButMandatoryParameter;
    jacobiCommand(.dn);
}

pub export fn fnJacobiAmplitude(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    if (comptime !runtime.option_elliptic) return;
    _ = unusedButMandatoryParameter;
    var realInput: bool = undefined;
    var m: real_t = undefined;
    var u: cplx_t = undefined;
    var r: cplx_t = undefined;

    if (!jacobi_check_inputs(&m, &u, &realInput)) {
        return;
    }

    if (realInput) {
        jacobiElliptic(&u.Real, &m, &r.Real, null, null, null, &runtime.ctxtReal75);
        runtime.convertAngleFromTo(&r.Real, amRadian, currentAngularMode, &runtime.ctxtReal39);
        runtime.convertRealToResultRegister(&r.Real, REGISTER_X, currentAngularMode);
    } else {
        jacobiComplexAm(&u, &m, &r, &runtime.ctxtReal75);
        runtime.convertComplexToResultRegister(&r, REGISTER_X);
    }

    runtime.adjustResult(REGISTER_X, true, true, REGISTER_X, -1, -1);
}

pub export fn fnEllipticK(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    if (comptime !runtime.option_elliptic) return;
    _ = unusedButMandatoryParameter;
    var m: real_t = undefined;
    var k: cplx_t = undefined;

    if (!runtime.saveLastX()) {
        return;
    }

    if (!runtime.getRegisterAsReal(REGISTER_X, &m)) {
        return;
    }

    if (realCompareLessEqual(&m, const_1())) {
        ellipticKE(&m, &k.Real, null, &runtime.ctxtReal39);
        runtime.convertRealToResultRegister(&k.Real, REGISTER_X, amNone);
    } else if (runtime.getFlag(FLAG_CPXRES)) {
        ellipticComplexKE(&m, &k, null, &runtime.ctxtReal39);
        runtime.convertComplexToResultRegister(&k, REGISTER_X);
    } else {
        runtime.displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE);
        moreInfo("In function fnEllipticK:", "Cannot calculate K(m) for m > 1 if CPXRES is not set");
    }

    runtime.adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}

pub export fn fnEllipticE(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    if (comptime !runtime.option_elliptic) return;
    _ = unusedButMandatoryParameter;
    var m: real_t = undefined;
    var e: cplx_t = undefined;

    if (!runtime.saveLastX()) {
        return;
    }

    if (!runtime.getRegisterAsReal(REGISTER_X, &m)) {
        return;
    }

    if (realCompareLessEqual(&m, const_1())) {
        ellipticKE(&m, null, &e.Real, &runtime.ctxtReal39);
        runtime.convertRealToResultRegister(&e.Real, REGISTER_X, amNone);
    } else if (runtime.getFlag(FLAG_CPXRES)) {
        ellipticComplexKE(&m, null, &e, &runtime.ctxtReal75);
        runtime.convertComplexToResultRegister(&e, REGISTER_X);
    } else {
        runtime.displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE);
        moreInfo("In function fnEllipticE:", "Cannot calculate K(m) for m > 1 if CPXRES is not set");
    }

    runtime.adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}

pub export fn fnEllipticPi(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    if (comptime !runtime.option_elliptic) return;
    _ = unusedButMandatoryParameter;
    var m: real_t = undefined;
    var u: cplx_t = undefined;
    var r: cplx_t = undefined;
    var realInput: bool = undefined;

    if (!jacobi_check_inputs(&m, &u, &realInput)) {
        return;
    }

    if (realIsNegative(&m) or realCompareGreaterEqual(&m, const_1())) {
        runtime.displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE);
        moreInfo("In function fnEllipticPi:", "m is out of range (must in 0 ≤ m < 1)");
    } else if (realInput) {
        ellipticPi(&u.Real, &m, &r, &runtime.ctxtReal39);
        if (realIsZero(&r.Imag)) {
            runtime.convertRealToResultRegister(&r.Real, REGISTER_X, amNone);
        } else if (runtime.getFlag(FLAG_CPXRES)) {
            runtime.convertComplexToResultRegister(&r, REGISTER_X);
        } else {
            runtime.displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE);
            moreInfo("In function fnEllipticPi:", "Π(n|m) cannot return complex result without CPXRES set");
        }
    } else {
        runtime.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE);
        if (comptime runtime.extra_info_on_calc_error) {
            // ERROR_MESSAGE_LENGTH is 512 (defines.h); upstream formats this hint
            // into the shared errorMessage buffer of that size.
            var buffer: [512]u8 = undefined;
            const type_name = std.mem.span(runtime.getRegisterDataTypeName(REGISTER_X, true, false));
            const message = runtime.bufPrintZ(&buffer, "cannot calculate elliptic integral with {s} in X", .{type_name}) catch "";
            runtime.moreInfoOnError("In function fnEllipticPi:", message, null, null);
        }
    }

    runtime.adjustResult(REGISTER_X, true, true, REGISTER_X, -1, -1);
}

const AmplitudeIntegral = enum { f, e, zeta };

fn amplitudeCommand(comptime which: AmplitudeIntegral) void {
    var realInput: bool = undefined;
    var m: real_t = undefined;
    var u: cplx_t = undefined;
    var r: cplx_t = undefined;

    if (!jacobi_check_inputs_phi(&m, &u, &realInput)) {
        return;
    }

    switch (which) {
        .f, .e => {
            const realContext = if (realInput and realCompareLessEqual(&m, const_1())) &runtime.ctxtReal39 else &runtime.ctxtReal75;
            if (which == .f) {
                ellipticF(&u, &m, &r, realContext);
            } else {
                ellipticE(&u, &m, &r, realContext);
            }
        },
        .zeta => jacobiZeta(&u, &m, &r, &runtime.ctxtReal75),
    }
    if (realInput) {
        if (realIsZero(&r.Imag)) {
            runtime.convertRealToResultRegister(&r.Real, REGISTER_X, amNone);
        } else if (runtime.getFlag(FLAG_CPXRES)) {
            runtime.convertComplexToResultRegister(&r, REGISTER_X);
        } else {
            runtime.displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE);
            switch (which) {
                .f => moreInfo("In function fnEllipticFphi:", "F(φ|m) cannot return complex result without CPXRES set"),
                .e => moreInfo("In function fnEllipticEphi:", "E(φ|m) cannot return complex result without CPXRES set"),
                .zeta => moreInfo("In function fnJacobiZeta:", "Ζ(φ|m) cannot return complex result without CPXRES set"),
            }
        }
    } else {
        runtime.convertComplexToResultRegister(&r, REGISTER_X);
    }

    runtime.adjustResult(REGISTER_X, true, true, REGISTER_X, -1, -1);
}

pub export fn fnEllipticFphi(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    if (comptime !runtime.option_elliptic) return;
    _ = unusedButMandatoryParameter;
    amplitudeCommand(.f);
}

pub export fn fnEllipticEphi(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    if (comptime !runtime.option_elliptic) return;
    _ = unusedButMandatoryParameter;
    amplitudeCommand(.e);
}

pub export fn fnJacobiZeta(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    if (comptime !runtime.option_elliptic) return;
    _ = unusedButMandatoryParameter;
    amplitudeCommand(.zeta);
}
