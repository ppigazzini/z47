// SPDX-License-Identifier: GPL-3.0-only
const abi = @import("abi");
const consts = abi.constants;
const const__4 = consts.const__4;
const const_1on4 = consts.const_1on4;
const const39_1on3 = consts.const39_1on3;
const const_1on2 = consts.const_1on2;
const const39_pi = consts.const39_pi;
const const39_piOn2 = consts.const39_piOn2;
const const39_piOn4 = consts.const39_piOn4;
const const75_2pi = consts.const75_2pi;
const const_1e_32 = consts.const_1e_32;
const const_1e_37 = consts.const_1e_37;
const const_1e_49 = consts.const_1e_49;
const const__1Off = consts.const__1Off;
const const_3Off = consts.const_3Off;
//
// Zig owner for src/c47/mathematics/elliptic.c: the elliptic-integral and
// Jacobi-function family. Exports the elliptic.h commands (fnEllipse, fnKtoM,
// fnMtoK, fnMtoTheta, fnThetatoM, fnJacobiSn/Cn/Dn/Amplitude, fnEllipticK/E/Pi/
// Fphi/Ephi, fnJacobiZeta) plus the public engines jacobiElliptic,
// jacobiComplexAm/Sn/Cn/Dn, ellipticKE, ellipticF, ellipticE, jacobiZeta,
// ellipticPi. The static helpers (Carlson RF/RD, AGM back-substitution, the
// A&S transformations) stay private. Faithful line-by-line translation
// preserving the exact order of every real_t operation (ellipticE/Ephi/Fphi/K/
// Pi.txt and jacobi_*.txt check results to the last ULP). The
// EXTRA_INFO_ON_CALC_ERROR sprintf hints become fixed moreInfoOnError strings.
// The SAVE_SPACE_DM42_12ELLIP guard is dead on every z47 build.

const runtime = @import("math_command_wrappers_runtime.zig");
const math_agm = @import("math_agm.zig"); // M-callconv: Zig-to-Zig
const math_circular_trig_command = @import("math_circular_trig_command.zig"); // M-callconv: Zig-to-Zig
const math_command_wrappers = @import("math_command_wrappers.zig"); // M-callconv: Zig-to-Zig
const math_comparison_reals = @import("math_comparison_reals.zig"); // M-callconv: Zig-to-Zig
const math_division_cells = @import("math_division_cells.zig"); // M-callconv: Zig-to-Zig
const math_gd = @import("math_gd.zig"); // M-callconv: Zig-to-Zig
const math_inverse_trig_command = @import("math_inverse_trig_command.zig"); // M-callconv: Zig-to-Zig
const math_ln_complex = @import("math_ln_complex.zig"); // M-callconv: Zig-to-Zig
const math_multiplication_cells = @import("math_multiplication_cells.zig"); // M-callconv: Zig-to-Zig
const math_runtime_helpers = @import("math_runtime_helpers.zig"); // M-callconv: Zig-to-Zig
const math_transform_complex_helpers = @import("math_transform_complex_helpers.zig"); // M-callconv: Zig-to-Zig
const math_wp34s = @import("math_wp34s.zig"); // M-callconv: Zig-to-Zig

const real_t = runtime.real_t;
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
const realIsZero = runtime.realIsZero;
const realIsNegative = runtime.realIsNegative;
const realSetZero = runtime.realSetZero;
const realSetOne = runtime.realSetOne;
const realSetNaN = runtime.realSetNaN;
const realChangeSign = runtime.realChangeSign;
const realSetPositiveSign = runtime.realSetPositiveSign;
const realToIntegralValue = runtime.realToIntegralValue;
const realCompareEqual = runtime.realCompareEqual;

const WP34S_Ln = runtime.WP34S_Ln;
const getFlag = runtime.getFlag;
const getSystemFlag = runtime.getSystemFlag;
const getRegisterDataType = runtime.getRegisterDataType;
const getRegisterAsReal = runtime.getRegisterAsReal;
const getRegisterAsComplex = runtime.getRegisterAsComplex;
const getRegisterAsRealAngle = runtime.getRegisterAsRealAngle;
const saveLastX = runtime.saveLastX;
const adjustResult = runtime.adjustResult;
const convertAngleFromTo = runtime.convertAngleFromTo;
const convertRealToResultRegister = runtime.convertRealToResultRegister;
const convertComplexToResultRegister = runtime.convertComplexToResultRegister;

const REGISTER_X = runtime.REGISTER_X;
const REGISTER_Y = runtime.REGISTER_Y;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const NIM_REGISTER_LINE = REGISTER_X;
const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN = runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN;
const ERROR_INVALID_DATA_TYPE_FOR_OP = runtime.ERROR_INVALID_DATA_TYPE_FOR_OP;
const ERROR_RAM_FULL = runtime.ERROR_RAM_FULL;
const amNone = runtime.amNone;
const amRadian = runtime.amRadian;
const dtComplex34 = runtime.dtComplex34;
const DEC_ROUND_DOWN = runtime.DEC_ROUND_DOWN;
const FLAG_CPXRES: u16 = 0x8004;
const NOPARAM: u16 = 9876;
const ifLongIntegerDoAngleReduction = runtime.ifLongIntegerDoAngleReduction;

const TI_ELLIPSE_K: u8 = 133;
const TI_ELLIPSE_M: u8 = 134;
const TI_ELLIPSE_Theta: u8 = 135;

const ELLIPTIC_N: usize = 16;
const REAL_SIZE_IN_BLOCKS_75: usize = 15;

const displayCalcErrorMessage = runtime.displayCalcErrorMessage;
const moreInfoOnError = runtime.moreInfoOnError;
// Complex mul/div accepting *align(1) const operands (blob constants pass here).
const processIntRealComplexDyadicFunction = runtime.processIntRealComplexDyadicFunction;

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

// Blob-offset constants without a runtime accessor.

// real ops / predicates / copy. Some are C macros; reproduce them.
extern fn realSetPlusInfinity(value: *real_t) void;
extern fn realSetMinusInfinity(value: *real_t) void;
inline fn realSetNegativeSign(value: *real_t) void {
    value.bits |= 0x80;
}
extern fn decNumberCopy(res: *real_t, source: *align(1) const real_t) *real_t;
extern fn decNumberCopyAbs(res: *real_t, source: *align(1) const real_t) *real_t;
extern fn decNumberMinus(res: *real_t, operand: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberPlus(res: *real_t, operand: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberRemainder(res: *real_t, lhs: *align(1) const real_t, rhs: *align(1) const real_t, ctxt: *realContext_t) *real_t;
inline fn realCopy(source: *align(1) const real_t, destination: *real_t) void {
    _ = decNumberCopy(destination, source);
}
inline fn realCopyAbs(source: *align(1) const real_t, destination: *real_t) void {
    _ = decNumberCopyAbs(destination, source);
}
// realMinus(operand, res, ctxt) => decNumberMinus(res, operand, ctxt)
inline fn realMinus(operand: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberMinus(res, operand, ctxt);
}
inline fn realPlus(operand: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberPlus(res, operand, ctxt);
}
inline fn realDivideRemainder(operand1: *align(1) const real_t, operand2: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberRemainder(res, operand1, operand2, ctxt);
}
inline fn realIsPositive(source: *const real_t) bool {
    return (source.bits & 0x80) == 0x00;
}

// Complex / transcendental helpers (cross-domain).

// AGM (agm.c owner, Zig-exported).

// Commands invoked from other owners.

extern fn getRegisterAsComplexOrReal(reg: calcRegister_t, r: *real_t, c: *real_t, cmplx: *bool) bool;

extern fn allocC47Blocks(sizeInBlocks: usize) ?*anyopaque;
extern fn freeC47Blocks(ptr: ?*anyopaque, sizeInBlocks: usize) void;

inline fn blkPtr(p: ?*anyopaque) [*]real_t {
    return @ptrCast(@alignCast(p));
}

// ===========================================================================
// _ellipseE / fnEllipse / fnKtoM / fnMtoK / fnMtoTheta / fnThetatoM
// ===========================================================================
fn _ellipseE() linksection(runtime.code_section) callconv(.c) void {
    var x: real_t = undefined;
    var y: real_t = undefined;
    if (!getRegisterAsReal(REGISTER_Y, &y) or !getRegisterAsReal(REGISTER_X, &x)) {
        return;
    }
    if (!saveLastX()) {
        return;
    }
    var reX: real_t = undefined;
    var a: real_t = undefined;
    var b: real_t = undefined;
    // ensure a <= b
    if (math_comparison_reals.realCompareGreaterThan(&x, &y)) {
        realCopy(&y, &a);
        realCopy(&x, &b);
    } else {
        realCopy(&x, &a);
        realCopy(&y, &b);
    }
    realDivide(&a, &b, &reX, &runtime.ctxtReal39);
    realMultiply(&reX, &reX, &reX, &runtime.ctxtReal39);
    realSubtract(const_1(), &reX, &reX, &runtime.ctxtReal39);
    convertRealToResultRegister(&reX, REGISTER_X, amNone);
    adjustResult(REGISTER_X, false, false, -1, -1, -1);
    temporaryInformation = TI_ELLIPSE_M;
}

pub export fn fnEllipse(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    processIntRealComplexDyadicFunction(&_ellipseE, null, &_ellipseE, &_ellipseE);
}

pub export fn fnKtoM(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    math_command_wrappers.fnSquare(NOPARAM);
    temporaryInformation = TI_ELLIPSE_M;
}

pub export fn fnMtoK(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    math_command_wrappers.fnSquareRoot(NOPARAM);
    temporaryInformation = TI_ELLIPSE_K;
}

pub export fn fnMtoTheta(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    math_command_wrappers.fnSquareRoot(NOPARAM);
    math_inverse_trig_command.fnArcsin(NOPARAM);
    temporaryInformation = TI_ELLIPSE_Theta;
}

pub export fn fnThetatoM(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    math_circular_trig_command.fnSin(NOPARAM);
    math_command_wrappers.fnSquare(NOPARAM);
    temporaryInformation = TI_ELLIPSE_M;
}

// ===========================================================================
// _calc_real_elliptic
// ===========================================================================
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
    var n: i32 = 0;

    const blocks = ELLIPTIC_N * REAL_SIZE_IN_BLOCKS_75;

    const MU_p = allocC47Blocks(blocks) orelse {
        displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
        realSetNaN(sn);
        realSetNaN(cn);
        realSetNaN(dn);
        return;
    };
    const MU = blkPtr(MU_p);
    const NU_p = allocC47Blocks(blocks) orelse {
        displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
        realSetNaN(sn);
        realSetNaN(cn);
        realSetNaN(dn);
        freeC47Blocks(MU_p, blocks);
        return;
    };
    const NU = blkPtr(NU_p);
    const C_p = allocC47Blocks(blocks) orelse {
        displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
        realSetNaN(sn);
        realSetNaN(cn);
        realSetNaN(dn);
        freeC47Blocks(NU_p, blocks);
        freeC47Blocks(MU_p, blocks);
        return;
    };
    const C = blkPtr(C_p);
    const D_p = allocC47Blocks(blocks) orelse {
        displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
        realSetNaN(sn);
        realSetNaN(cn);
        realSetNaN(dn);
        freeC47Blocks(C_p, blocks);
        freeC47Blocks(NU_p, blocks);
        freeC47Blocks(MU_p, blocks);
        return;
    };
    const D = blkPtr(D_p);

    const freeAll = struct {
        fn freeAllBlocks(mu_p: ?*anyopaque, nu_p: ?*anyopaque, c_p: ?*anyopaque, d_p: ?*anyopaque, blk: usize) linksection(runtime.code_section) void {
            freeC47Blocks(d_p, blk);
            freeC47Blocks(c_p, blk);
            freeC47Blocks(nu_p, blk);
            freeC47Blocks(mu_p, blk);
        }
    }.freeAllBlocks;

    if (realIsNegative(m) or math_comparison_reals.realCompareLessThan(const_1(), m)) {
        realSetNaN(sn);
        realSetNaN(cn);
        realSetNaN(dn);
        freeAll(MU_p, NU_p, C_p, D_p, blocks);
        return;
    }
    if (math_comparison_reals.realCompareLessThan(m, const_1e_32())) {
        math_wp34s.C47_WP34S_Cvt2RadSinCosTan(u, amRadian, sn, cn, null, realContext);
        realSetOne(dn);
        freeAll(MU_p, NU_p, C_p, D_p, blocks);
        return;
    }
    realSubtract(m, const_1(), &a, realContext);
    if (math_comparison_reals.realCompareAbsLessThan(&a, const_1e_32())) {
        math_wp34s.WP34S_SinhCosh(u, &a, &b, realContext);
        realDivide(const_1(), &b, cn, realContext);
        realMultiply(&a, cn, sn, realContext);
        realCopy(cn, dn);
        freeAll(MU_p, NU_p, C_p, D_p, blocks);
        return;
    }

    realSubtract(const_1(), m, &a, realContext);
    realSquareRoot(&a, &a, realContext);
    n = @intCast(math_agm.realAgmStep(const_1(), &a, &b, MU, NU, ELLIPTIC_N, realContext));
    realSubtract(&MU[@intCast(n - 1)], &NU[@intCast(n - 1)], &e, realContext);

    realMultiply(u, &MU[@intCast(n)], &a, realContext);
    math_wp34s.C47_WP34S_Cvt2RadSinCosTan(&a, amRadian, &sin_umu, &cos_umu, null, realContext);
    realCopyAbs(&cos_umu, &b);
    realDivide(&cos_umu, &sin_umu, &t, realContext);
    if (realIsZero(&sin_umu)) {
        realSetZero(sn);
        realSetOne(cn);
        realSetOne(dn);
        freeAll(MU_p, NU_p, C_p, D_p, blocks);
        return;
    }

    realMultiply(&MU[@intCast(n)], &t, &C[@intCast(n)], realContext);
    realSetOne(&D[@intCast(n)]);

    while (n > 0) {
        n -= 1;
        const ni: usize = @intCast(n);
        realMultiply(&D[ni + 1], &C[ni + 1], &C[ni], realContext);
        realMultiply(&C[ni + 1], &C[ni + 1], &a, realContext);
        realDivide(&a, &MU[ni + 1], &r, realContext);
        realAdd(&r, &NU[ni], &a, realContext);
        realAdd(&r, &MU[ni], &b, realContext);
        realDivide(&a, &b, &D[ni], realContext);
    }
    math_runtime_helpers.complexMagnitude(const_1(), &C[0], &f, realContext);
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

    freeAll(MU_p, NU_p, C_p, D_p, blocks);
}

fn calc_real_elliptic(sn_in: ?*real_t, cn_in: ?*real_t, dn_in: ?*real_t, u: *const real_t, m: *const real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var s_n: real_t = undefined;
    var c_n: real_t = undefined;
    var d_n: real_t = undefined;
    const sn: *real_t = sn_in orelse &s_n;
    const cn: *real_t = cn_in orelse &c_n;
    const dn: *real_t = dn_in orelse &d_n;

    if (math_comparison_reals.realCompareLessThan(const_1(), m)) {
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

fn jacobi_check_inputs(m: *real_t, uReal: *real_t, uImag: *real_t, realInput: *bool) linksection(runtime.code_section) i32 {
    var cmplx: bool = false;

    if (!getRegisterAsComplexOrReal(REGISTER_X, uReal, uImag, &cmplx) or !getRegisterAsReal(REGISTER_Y, m) or !saveLastX()) {
        return 0;
    }
    realInput.* = !cmplx;
    return 1;
}

fn jacobi_check_inputs_phi(m: *real_t, phiReal: *real_t, phiImag: *real_t, realInput: *bool) linksection(runtime.code_section) i32 {
    if (getRegisterDataType(REGISTER_X) == dtComplex34) {
        return jacobi_check_inputs(m, phiReal, phiImag, realInput);
    }
    var xAngularMode: angularMode_t = undefined;
    if (!getRegisterAsRealAngle(REGISTER_X, phiReal, &xAngularMode, !ifLongIntegerDoAngleReduction) or !getRegisterAsReal(REGISTER_Y, m) or !saveLastX()) {
        return 0;
    }

    convertAngleFromTo(phiReal, xAngularMode, amRadian, &runtime.ctxtReal75);
    realSetZero(phiImag);
    realInput.* = true;
    return 1;
}

pub export fn jacobiElliptic(u: *const real_t, m: *const real_t, am: ?*real_t, sn: ?*real_t, cn: ?*real_t, dn: ?*real_t, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    var _sn: real_t = undefined;
    calc_real_elliptic(if (sn) |s| s else &_sn, cn, dn, u, m, realContext);
    if (am) |amp| {
        math_wp34s.C47_WP34S_Asin(if (sn) |s| s else &_sn, amp, realContext);
    }
}

pub export fn jacobiComplexAm(ur: *const real_t, ui: *const real_t, m: *const real_t, rr: *real_t, ri: *real_t, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    jacobiComplexSn(ur, ui, m, rr, ri, realContext);
    _ = math_inverse_trig_command.ArcsinComplex(rr, ri, rr, ri, realContext);
}

pub export fn jacobiComplexSn(ur: *const real_t, ui: *const real_t, m: *const real_t, rr: *real_t, ri: *real_t, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    var a: real_t = undefined;
    var b: real_t = undefined;
    var denom: real_t = undefined;
    var snuk: real_t = undefined;
    var cnuk: real_t = undefined;
    var dnuk: real_t = undefined;
    var snvki: real_t = undefined;
    var cnvki: real_t = undefined;
    var dnvki: real_t = undefined;
    elliptic_setup_cpx_real(&denom, &snuk, &cnuk, &dnuk, &snvki, &cnvki, &dnvki, ur, ui, m, realContext);

    realMultiply(&snuk, &dnvki, &a, realContext);
    realDivide(&a, &denom, rr, realContext);

    realMultiply(&cnuk, &dnuk, &a, realContext);
    realMultiply(&a, &snvki, &b, realContext);
    realMultiply(&b, &cnvki, &a, realContext);
    realDivide(&a, &denom, ri, realContext);
}

pub export fn jacobiComplexCn(ur: *const real_t, ui: *const real_t, m: *const real_t, rr: *real_t, ri: *real_t, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    var a: real_t = undefined;
    var b: real_t = undefined;
    var denom: real_t = undefined;
    var snuk: real_t = undefined;
    var cnuk: real_t = undefined;
    var dnuk: real_t = undefined;
    var snvki: real_t = undefined;
    var cnvki: real_t = undefined;
    var dnvki: real_t = undefined;
    elliptic_setup_cpx_real(&denom, &snuk, &cnuk, &dnuk, &snvki, &cnvki, &dnvki, ur, ui, m, realContext);

    realMultiply(&cnuk, &cnvki, &a, realContext);
    realDivide(&a, &denom, rr, realContext);

    realMultiply(&snuk, &dnuk, &a, realContext);
    realMultiply(&a, &snvki, &b, realContext);
    realMultiply(&b, &dnvki, &a, realContext);
    realDivide(&a, &denom, &b, realContext);
    realMinus(&b, ri, realContext);
}

pub export fn jacobiComplexDn(ur: *const real_t, ui: *const real_t, m: *const real_t, rr: *real_t, ri: *real_t, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    var a: real_t = undefined;
    var b: real_t = undefined;
    var denom: real_t = undefined;
    var snuk: real_t = undefined;
    var cnuk: real_t = undefined;
    var dnuk: real_t = undefined;
    var snvki: real_t = undefined;
    var cnvki: real_t = undefined;
    var dnvki: real_t = undefined;
    elliptic_setup_cpx_real(&denom, &snuk, &cnuk, &dnuk, &snvki, &cnvki, &dnvki, ur, ui, m, realContext);

    realMultiply(&dnuk, &cnvki, &a, realContext);
    realMultiply(&a, &dnvki, &b, realContext);
    realDivide(&b, &denom, rr, realContext);

    realMinus(m, &b, realContext);
    realMultiply(&b, &snuk, &a, realContext);
    realMultiply(&a, &cnuk, &b, realContext);
    realMultiply(&b, &snvki, &a, realContext);
    realDivide(&a, &denom, ri, realContext);
}

pub export fn ellipticKE(m: *const real_t, k: ?*real_t, ki: ?*real_t, e: ?*real_t, ei: ?*real_t, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    var a: real_t = undefined;
    var b: real_t = undefined;
    var cr: real_t = undefined;
    var ci: real_t = undefined;

    if (k) |p| realSetNaN(p);
    if (ki) |p| realSetZero(p);
    if (e) |p| realSetNaN(p);
    if (ei) |p| realSetZero(p);

    if (math_comparison_reals.realCompareLessEqual(m, const_1())) {
        if (realCompareEqual(m, const_1())) {
            if (k) |p| realSetPlusInfinity(p);
            if (e) |p| realSetOne(p);
        } else if (realCompareEqual(m, const_0())) {
            if (k) |p| realCopy(const39_piOn2(), p);
            if (e) |p| realCopy(const39_piOn2(), p);
        } else {
            realSubtract(const_1(), m, &b, realContext);
            realSquareRoot(&b, &b, realContext);
            realCopy(m, &a);
            _ = math_agm.realAgmForE(const_1(), &b, &a, &b, realContext);
            realDivide(const39_piOn2(), &b, &b, realContext);
            if (k) |p| realCopy(&b, p);

            if (e) |p| {
                realSubtract(&a, const_1(), &a, realContext);
                realChangeSign(&a);
                realMultiply(&a, &b, &b, realContext);
                realCopy(&b, p);
            }
        }
    } else if (ki != null or ei != null) {
        if (k) |p| realSetNaN(p);
        if (e) |p| realSetNaN(p);

        realSubtract(m, const_1(), &b, realContext);
        realSquareRoot(&b, &b, realContext);
        realCopy(m, &cr);
        realSetZero(&ci);
        _ = math_agm.complexAgmForE(const_1(), const_0(), const_0(), &b, &cr, &ci, &a, &b, realContext);
        math_division_cells.divRealComplex(const39_piOn2(), &a, &b, &a, &b, realContext);
        if (k != null and ki != null) {
            realCopy(&a, k.?);
            realCopy(&b, ki.?);
        }

        if (e != null and ei != null) {
            realSubtract(&cr, const_1(), &cr, realContext);
            realChangeSign(&cr);
            realChangeSign(&ci);
            math_multiplication_cells.mulComplexComplex(&a, &b, &cr, &ci, &a, &b, realContext);
            realCopy(&a, e.?);
            realCopy(&b, ei.?);
        }
    }
}

fn rcSqrt(x: *const real_t, r: *real_t, i: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var xx: real_t = undefined;

    realCopy(x, &xx);
    if (realIsNegative(&xx)) {
        realSetPositiveSign(&xx);
        realSquareRoot(&xx, i, realContext);
        realSetZero(r);
    } else {
        realSquareRoot(&xx, r, realContext);
        realSetZero(i);
    }
}

fn _ellipticFE_lambda_mu(phi: *const real_t, psi: *const real_t, m: *const real_t, lambda: *real_t, lambdaI: *real_t, mu: *real_t, muI: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var m1: real_t = undefined;
    var b: real_t = undefined;
    var c: real_t = undefined;
    var csc2Phi: real_t = undefined;
    var tan2Phi: real_t = undefined;
    var cot2Phi: real_t = undefined;
    var sinh2Psi: real_t = undefined;
    var cot2Lambda: real_t = undefined;
    var cot2LambdaI: real_t = undefined;

    realSubtract(const_1(), m, &m1, realContext);

    math_wp34s.C47_WP34S_Cvt2RadSinCosTan(phi, amRadian, &csc2Phi, &cot2Phi, &tan2Phi, realContext);
    realDivide(const_1(), &csc2Phi, &csc2Phi, realContext);
    realMultiply(&csc2Phi, &csc2Phi, &csc2Phi, realContext);
    realDivide(const_1(), &tan2Phi, &cot2Phi, realContext);
    realMultiply(&tan2Phi, &tan2Phi, &tan2Phi, realContext);
    realMultiply(&cot2Phi, &cot2Phi, &cot2Phi, realContext);
    math_wp34s.WP34S_SinhCosh(psi, &sinh2Psi, null, realContext);
    realMultiply(&sinh2Psi, &sinh2Psi, &sinh2Psi, realContext);

    realMultiply(m, &sinh2Psi, &b, realContext);
    realFMA(&b, &csc2Phi, &cot2Phi, &b, realContext);
    realSubtract(&b, &m1, &b, realContext);
    realChangeSign(&b);
    realMultiply(&m1, &cot2Phi, &c, realContext);
    realChangeSign(&c);

    realMultiply(const__4(), &c, &cot2Lambda, realContext);
    realFMA(&b, &b, &cot2Lambda, &cot2Lambda, realContext);
    rcSqrt(&cot2Lambda, &cot2Lambda, &cot2LambdaI, realContext);
    realSubtract(&cot2Lambda, &b, &cot2Lambda, realContext);
    realMultiply(&cot2Lambda, const_1on2(), &cot2Lambda, realContext);
    realMultiply(&cot2LambdaI, const_1on2(), &cot2LambdaI, realContext);

    if (realIsZero(&cot2LambdaI)) {
        realDivide(const_1(), &cot2Lambda, lambda, realContext);
        rcSqrt(lambda, lambda, lambdaI, realContext);
        if (realIsZero(lambdaI)) {
            math_wp34s.C47_WP34S_Atan(lambda, lambda, realContext);
        } else {
            _ = math_inverse_trig_command.ArctanComplex(lambda, lambdaI, lambda, lambdaI, realContext);
        }

        if (realIsZero(&cot2Lambda) and realIsZero(&cot2LambdaI)) {
            realCopy(const__1Off(), mu);
        } else {
            realFMA(&tan2Phi, &cot2Lambda, const__1Off(), mu, realContext);
        }
        realDivide(mu, m, mu, realContext);
        rcSqrt(mu, mu, muI, realContext);
        if (realIsZero(muI)) {
            math_wp34s.C47_WP34S_Atan(mu, mu, realContext);
        } else {
            _ = math_inverse_trig_command.ArctanComplex(mu, muI, mu, muI, realContext);
        }
    } else {
        math_division_cells.divRealComplex(const_1(), &cot2Lambda, &cot2LambdaI, lambda, lambdaI, realContext);
        math_transform_complex_helpers.sqrtComplex(lambda, lambdaI, lambda, lambdaI, realContext);
        _ = math_inverse_trig_command.ArctanComplex(lambda, lambdaI, lambda, lambdaI, realContext);

        if (realIsZero(&cot2Lambda) and realIsZero(&cot2LambdaI)) {
            realCopy(const__1Off(), mu);
            realSetZero(muI);
        } else {
            realFMA(&tan2Phi, &cot2Lambda, const__1Off(), mu, realContext);
            realMultiply(&tan2Phi, &cot2LambdaI, muI, realContext);
        }
        realDivide(mu, m, mu, realContext);
        realDivide(muI, m, muI, realContext);
        math_transform_complex_helpers.sqrtComplex(mu, muI, mu, muI, realContext);
        _ = math_inverse_trig_command.ArctanComplex(mu, muI, mu, muI, realContext);
    }
}


inline fn carlsonTol(realContext: *realContext_t) *align(1) const real_t {
    return if (realContext.digits <= 39) const_1e_37() else const_1e_49();
}

fn carlsonRF(x0: *const real_t, y0: *const real_t, z0: *const real_t, res: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var x: real_t = undefined;
    var y: real_t = undefined;
    var z: real_t = undefined;
    var sx: real_t = undefined;
    var sy: real_t = undefined;
    var sz: real_t = undefined;
    var lam: real_t = undefined;
    var lam4: real_t = undefined;
    const tol = carlsonTol(realContext);
    realCopy(x0, &x);
    realCopy(y0, &y);
    realCopy(z0, &z);
    while (true) {
        realSquareRoot(&x, &sx, realContext);
        realSquareRoot(&y, &sy, realContext);
        realSquareRoot(&z, &sz, realContext);
        realMultiply(&sx, &sy, &lam, realContext);
        realFMA(&sy, &sz, &lam, &lam, realContext);
        realFMA(&sz, &sx, &lam, &lam, realContext);
        realMultiply(&lam, const_1on4(), &lam4, realContext);
        realFMA(&x, const_1on4(), &lam4, &x, realContext);
        realFMA(&y, const_1on4(), &lam4, &y, realContext);
        realFMA(&z, const_1on4(), &lam4, &z, realContext);
        if (math_wp34s.WP34S_RelativeError(&x, &y, tol, realContext) and math_wp34s.WP34S_RelativeError(&x, &z, tol, realContext)) {
            break;
        }
    }
    realSquareRoot(&x, res, realContext);
    realDivide(const_1(), res, res, realContext);
}

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
    const tol = carlsonTol(realContext);
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
        realFMA(&sy, &sz, &lam, &lam, realContext);
        realFMA(&sz, &sx, &lam, &lam, realContext);
        realAdd(&z, &lam, &t, realContext);
        realMultiply(&t, &sz, &t, realContext);
        realDivide(&fac, &t, &t, realContext);
        realAdd(&sum, &t, &sum, realContext);
        realMultiply(&lam, const_1on4(), &lam4, realContext);
        realFMA(&x, const_1on4(), &lam4, &x, realContext);
        realFMA(&y, const_1on4(), &lam4, &y, realContext);
        realFMA(&z, const_1on4(), &lam4, &z, realContext);
        realMultiply(&fac, const_1on4(), &fac, realContext);
        if (math_wp34s.WP34S_RelativeError(&x, &y, tol, realContext) and math_wp34s.WP34S_RelativeError(&x, &z, tol, realContext)) {
            break;
        }
    }
    realSquareRoot(&x, &sx, realContext);
    realMultiply(&x, &sx, res, realContext);
    realDivide(&fac, res, res, realContext);
    realFMA(const_3Off(), &sum, res, res, realContext);
}


fn _ellipticF(phi: *const real_t, m: *const real_t, res: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var s: real_t = undefined;
    var c: real_t = undefined;
    var s2: real_t = undefined;
    var y: real_t = undefined;
    math_wp34s.C47_WP34S_Cvt2RadSinCosTan(phi, amRadian, &s, &c, null, realContext);
    realMultiply(&s, &s, &s2, realContext);
    realMultiply(&c, &c, &c, realContext);
    realMultiply(m, &s2, &y, realContext);
    realSubtract(const_1(), &y, &y, realContext);
    carlsonRF(&c, &y, const_1(), res, realContext);
    realMultiply(&s, res, res, realContext);
}

fn _ellipticF_1(phi: *const real_t, m: *const real_t, res: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    _ellipticF(phi, m, res, realContext);
}

fn _ellipticF_2(phi: *const real_t, m: *const real_t, res: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var phi1: real_t = undefined;
    var phiQuotient: real_t = undefined;
    var phiRemainder: real_t = undefined;
    var remainderNegative: bool = false;

    realCopyAbs(phi, &phi1);
    realDivide(&phi1, const39_pi(), &phiQuotient, realContext);
    realToIntegralValue(&phiQuotient, &phiQuotient, DEC_ROUND_DOWN, realContext);
    realDivideRemainder(&phi1, const39_pi(), &phiRemainder, realContext);
    if (math_comparison_reals.realCompareGreaterThan(&phiRemainder, const39_piOn2())) {
        realAdd(&phiQuotient, const_1(), &phiQuotient, realContext);
        realSubtract(const39_pi(), &phiRemainder, &phiRemainder, realContext);
        remainderNegative = true;
    }

    if (realIsZero(&phiQuotient)) {
        _ellipticF_1(&phiRemainder, m, res, realContext);
    } else {
        realAdd(&phiQuotient, &phiQuotient, &phiQuotient, realContext);
        ellipticKE(m, &phi1, null, null, null, realContext);
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

fn _ellipticF_3(phi: *const real_t, m: *const real_t, res: *real_t, resi: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    if (realIsZero(m)) {
        realCopy(phi, res);
        realSetZero(resi);
    } else if (math_comparison_reals.realCompareGreaterThan(m, const_1())) {
        var k: real_t = undefined;
        var m_1: real_t = undefined;
        var theta: real_t = undefined;
        var thetai: real_t = undefined;
        var a: real_t = undefined;
        const hCtx: *realContext_t = &runtime.ctxtReal75;
        math_wp34s.mod2Pi(phi, &theta, hCtx);
        math_wp34s.C47_WP34S_Cvt2RadSinCosTan(&theta, amRadian, &a, null, null, hCtx);
        realSquareRoot(m, &k, hCtx);
        realDivide(const_1(), m, &m_1, hCtx);
        realMultiply(&k, &a, &a, hCtx);
        _ = math_inverse_trig_command.ArcsinComplex(&a, const_0(), &theta, &thetai, hCtx);
        ellipticF(&theta, &thetai, &m_1, res, resi, hCtx);
        math_division_cells.divComplexComplex(res, resi, &k, const_0(), res, resi, hCtx);
        realPlus(res, res, realContext);
        realPlus(resi, resi, realContext);
    } else if (realIsPositive(m)) {
        _ellipticF_2(phi, m, res, realContext);
        realSetZero(resi);
    } else {
        var absm: real_t = undefined;
        var mp1: real_t = undefined;
        var rtmp1: real_t = undefined;
        var k: real_t = undefined;
        var ki: real_t = undefined;
        var m2: real_t = undefined;
        var phi1: real_t = undefined;
        var f: real_t = undefined;
        var fi: real_t = undefined;

        realCopyAbs(m, &absm);
        realAdd(&absm, const_1(), &mp1, realContext);
        realSquareRoot(&mp1, &rtmp1, realContext);

        realDivide(&absm, &mp1, &m2, realContext);
        ellipticKE(&m2, &k, &ki, null, null, realContext);

        realSubtract(const39_piOn2(), phi, &phi1, realContext);
        ellipticF(&phi1, const_0(), &m2, &f, &fi, realContext);

        realSubtract(&k, &f, &k, realContext);
        realSubtract(&ki, &fi, &ki, realContext);
        math_division_cells.divComplexComplex(&k, &ki, &rtmp1, const_0(), res, resi, realContext);
    }
}

fn _ellipticF_4(phi: *const real_t, psi: *const real_t, m: *const real_t, res: *real_t, resi: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    if (realIsZero(psi)) {
        _ellipticF_3(phi, m, res, resi, realContext);
    } else if (realIsZero(phi)) {
        var m1: real_t = undefined;
        var theta: real_t = undefined;

        realSubtract(const_1(), m, &m1, realContext);
        _ = math_gd.GudermannianReal(psi, &theta, realContext);
        _ellipticF_3(&theta, &m1, resi, res, realContext);
        realChangeSign(res);
    } else {
        var m1: real_t = undefined;
        var lambda: real_t = undefined;
        var lambdaI: real_t = undefined;
        var mu: real_t = undefined;
        var muI: real_t = undefined;
        var b: real_t = undefined;
        var c: real_t = undefined;

        realSubtract(const_1(), m, &m1, realContext);
        _ellipticFE_lambda_mu(phi, psi, m, &lambda, &lambdaI, &mu, &muI, realContext);

        if (realIsZero(&lambdaI)) {
            _ellipticF_3(&lambda, m, &b, &c, realContext);
        } else {
            ellipticF(&lambda, &lambdaI, m, &b, &c, realContext);
        }
        realCopy(&b, res);
        realCopy(&c, resi);
        if (realIsZero(&muI)) {
            _ellipticF_3(&mu, &m1, &b, &c, realContext);
        } else {
            _ellipticF_4(&mu, &muI, &m1, &b, &c, realContext);
        }
        realAdd(resi, &b, resi, realContext);
        realSubtract(res, &c, res, realContext);
    }
}

fn _ellipticF_5(phi: *const real_t, psi: *const real_t, m: *const real_t, res: *real_t, resi: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    if (math_comparison_reals.realCompareAbsGreaterThan(phi, const39_piOn4())) {
        var psir: real_t = undefined;
        var psii: real_t = undefined;
        var m1: real_t = undefined;
        var k1: real_t = undefined;
        var k1i: real_t = undefined;
        var tanPhi: real_t = undefined;
        var tanPhiI: real_t = undefined;
        var k: real_t = undefined;
        var ki: real_t = undefined;
        if (realIsZero(psi) and math_comparison_reals.realCompareAbsLessThan(phi, const39_piOn2()) and !realIsNegative(m) and !math_comparison_reals.realCompareGreaterThan(m, const_1())) {
            _ellipticF(phi, m, res, realContext);
            realSetZero(resi);
            return;
        }
        ellipticKE(m, &k, &ki, null, null, realContext);
        if (realIsNegative(psi)) {
            realChangeSign(&ki);
        }
        _ = math_command_wrappers.TanComplex(phi, psi, &tanPhi, &tanPhiI, realContext);
        realSubtract(const_1(), m, &m1, realContext);
        rcSqrt(&m1, &k1, &k1i, realContext);
        math_multiplication_cells.mulComplexComplex(&k1, &k1i, &tanPhi, &tanPhiI, &psir, &psii, realContext);
        math_division_cells.divRealComplex(const_1(), &psir, &psii, &psir, &psii, realContext);
        if (realIsZero(&psii)) {
            math_wp34s.C47_WP34S_Atan(&psir, &psir, realContext);
        } else {
            _ = math_inverse_trig_command.ArctanComplex(&psir, &psii, &psir, &psii, realContext);
        }
        _ellipticF_4(&psir, &psii, m, res, resi, realContext);

        if (!realIsZero(&ki)) {
            if (realIsPositive(&ki)) {
                realSetPositiveSign(resi);
            } else {
                realSetNegativeSign(resi);
            }
        }
        realSubtract(&k, res, res, realContext);
        realSubtract(&ki, resi, resi, realContext);

        if (realIsPositive(psi)) {
            realSetPositiveSign(resi);
        } else {
            realSetNegativeSign(resi);
        }
        if (!realIsZero(&ki) and realIsNegative(&ki)) {
            realChangeSign(resi);
        }
    } else {
        _ellipticF_4(phi, psi, m, res, resi, realContext);
    }
}

pub export fn ellipticF(phi: *const real_t, psi: *const real_t, m: *const real_t, res: *real_t, resi: *real_t, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    var phi1: real_t = undefined;
    var phiQuotient: real_t = undefined;
    var phiRemainder: real_t = undefined;
    var psi1: real_t = undefined;
    var remainderNegative: bool = false;

    realCopy(phi, &phi1);
    realCopy(psi, &psi1);
    if (realIsNegative(phi)) {
        realChangeSign(&phi1);
        realChangeSign(&psi1);
    }
    realDivide(&phi1, const39_pi(), &phiQuotient, realContext);
    realToIntegralValue(&phiQuotient, &phiQuotient, DEC_ROUND_DOWN, realContext);
    realDivideRemainder(&phi1, const39_pi(), &phiRemainder, realContext);
    if (math_comparison_reals.realCompareGreaterThan(&phiRemainder, const39_piOn2())) {
        realAdd(&phiQuotient, const_1(), &phiQuotient, realContext);
        realSubtract(const39_pi(), &phiRemainder, &phiRemainder, realContext);
        remainderNegative = true;
    }

    if (realIsZero(phi) and realIsZero(psi)) {
        realSetZero(res);
        realSetZero(resi);
        return;
    } else if (realIsZero(m)) {
        realCopy(phi, res);
        realCopy(psi, resi);
        return;
    } else if (realCompareEqual(m, const_1())) {
        var p: real_t = undefined;
        var q: real_t = undefined;
        realFMA(phi, const_1on2(), const39_piOn4(), &p, realContext);
        realMultiply(psi, const_1on2(), &q, realContext);
        if (realIsZero(&q)) {
            math_wp34s.C47_WP34S_Cvt2RadSinCosTan(&p, amRadian, res, resi, &q, realContext);
            WP34S_Ln(&q, res, realContext);
            realSetZero(resi);
        } else {
            _ = math_command_wrappers.TanComplex(&p, &q, &p, &q, realContext);
            math_ln_complex.lnComplex(&p, &q, res, resi, realContext);
            if (realIsZero(&p)) {
                realSetZero(res);
            }
        }
        return;
    } else if (realIsZero(&phiQuotient)) {
        _ellipticF_5(&phiRemainder, &psi1, m, res, resi, realContext);
        if (remainderNegative) {
            realChangeSign(res);
            realChangeSign(resi);
        }
        if (realIsNegative(phi)) {
            realChangeSign(res);
            realChangeSign(resi);
        }
    } else {
        realAdd(&phiQuotient, &phiQuotient, &phiQuotient, realContext);
        _ellipticF_5(&phiRemainder, &psi1, m, res, resi, realContext);
        if (remainderNegative) {
            realChangeSign(res);
            realChangeSign(resi);
        }
        if (realIsNegative(phi)) {
            realChangeSign(res);
            realChangeSign(resi);
        }
        ellipticKE(m, &phi1, &psi1, null, null, realContext);
        realFMA(&phiQuotient, &phi1, res, res, realContext);
        realFMA(&phiQuotient, &psi1, resi, resi, realContext);
    }

    if (math_comparison_reals.realCompareGreaterThan(m, const_1()) and (math_comparison_reals.realCompareAbsGreaterThan(phi, const39_piOn2()) or realIsZero(psi))) {
        if (realIsPositive(phi)) {
            realSetNegativeSign(resi);
        } else {
            realSetPositiveSign(resi);
        }
    } else {
        if (realIsPositive(psi)) {
            realSetPositiveSign(resi);
        } else if (realIsNegative(psi)) {
            realSetNegativeSign(resi);
        } else if (realIsPositive(psi)) {
            realSetPositiveSign(resi);
        } else if (realIsNegative(psi)) {
            realSetNegativeSign(resi);
        }
    }
}

fn _ellipticE_fromZeta(phi: *const real_t, psi: *const real_t, m: *const real_t, res: *real_t, resi: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var k: real_t = undefined;
    var ki: real_t = undefined;
    var e: real_t = undefined;
    var ei: real_t = undefined;
    var f: real_t = undefined;
    var fi: real_t = undefined;
    var z: real_t = undefined;
    var zi: real_t = undefined;

    ellipticKE(m, &k, &ki, &e, &ei, realContext);
    ellipticF(phi, psi, m, &f, &fi, realContext);
    jacobiZeta(phi, psi, m, &z, &zi, realContext);
    math_division_cells.divComplexComplex(&e, &ei, &k, &ki, res, resi, realContext);
    math_multiplication_cells.mulComplexComplex(res, resi, &f, &fi, res, resi, realContext);
    realAdd(res, &z, res, realContext);
    realAdd(resi, &zi, resi, realContext);
}

pub export fn ellipticE(phi: *const real_t, psi: *const real_t, m: *const real_t, res: *real_t, resi: *real_t, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    var phi1: real_t = undefined;
    var phiQuotient: real_t = undefined;
    var phiRemainder: real_t = undefined;
    var psi1: real_t = undefined;

    realCopyAbs(phi, &phi1);
    realCopyAbs(psi, &psi1);
    realDivide(&phi1, const39_pi(), &phiQuotient, realContext);
    realToIntegralValue(&phiQuotient, &phiQuotient, DEC_ROUND_DOWN, realContext);
    realDivideRemainder(&phi1, const39_pi(), &phiRemainder, realContext);
    if (math_comparison_reals.realCompareGreaterThan(&phiRemainder, const39_piOn2())) {
        realAdd(&phiQuotient, const_1(), &phiQuotient, realContext);
        realSubtract(&phiRemainder, const39_pi(), &phiRemainder, realContext);
    }
    if (realIsNegative(phi)) {
        realChangeSign(&phi1);
        realChangeSign(&phiQuotient);
        realChangeSign(&phiRemainder);
        realChangeSign(&psi1);
    }

    if (realIsZero(m)) {
        realCopy(phi, res);
        realCopy(psi, resi);
    } else if (realCompareEqual(m, const_1())) {
        if (realIsZero(psi)) {
            math_wp34s.C47_WP34S_Cvt2RadSinCosTan(&phiRemainder, amRadian, res, null, null, realContext);
            realSetZero(resi);
            realAdd(res, &phiQuotient, res, realContext);
            realAdd(res, &phiQuotient, res, realContext);
        } else {
            math_command_wrappers.sinComplex(&phiRemainder, psi, res, resi, realContext);
            realAdd(res, &phiQuotient, res, realContext);
            realAdd(res, &phiQuotient, res, realContext);
        }
    } else if (realIsZero(psi) and math_comparison_reals.realCompareGreaterThan(m, const_1())) {
        var k: real_t = undefined;
        var ki: real_t = undefined;
        var m_1: real_t = undefined;
        var u: real_t = undefined;
        var ui: real_t = undefined;
        var a: real_t = undefined;
        var b: real_t = undefined;

        ellipticF(phi, const_0(), m, &u, &ui, realContext);
        rcSqrt(m, &k, &ki, realContext);
        realDivide(const_1(), m, &m_1, realContext);
        math_multiplication_cells.mulComplexComplex(&u, &ui, &k, &ki, &a, &b, realContext);
        jacobiComplexAm(&a, &b, &m_1, &a, &b, realContext);

        _ellipticE_fromZeta(phi, const_0(), m, res, resi, realContext);
        if (realIsZero(&b)) {
            realSetZero(resi);
        }
    } else if (realIsZero(psi)) {
        _ellipticE_fromZeta(phi, const_0(), m, res, resi, realContext);
    } else if (realIsZero(phi)) {
        var theta: real_t = undefined;
        var m1: real_t = undefined;
        var a: real_t = undefined;
        var b: real_t = undefined;
        var c: real_t = undefined;
        var d: real_t = undefined;

        _ = math_gd.GudermannianReal(psi, &theta, realContext);
        realSubtract(const_1(), m, &m1, realContext);

        math_wp34s.C47_WP34S_Cvt2RadSinCosTan(&theta, amRadian, &c, &d, &a, realContext);

        realMultiply(&c, &c, &c, realContext);
        realMultiply(&c, &m1, &c, realContext);
        realSubtract(const_1(), &c, &c, realContext);
        rcSqrt(&c, &c, &d, realContext);
        math_multiplication_cells.mulComplexComplex(&a, const_0(), &c, &d, &a, &b, realContext);

        ellipticF(&theta, const_0(), &m1, &c, &d, realContext);
        realAdd(&a, &c, &a, realContext);
        realAdd(&b, &d, &b, realContext);
        ellipticE(&theta, const_0(), &m1, &c, &d, realContext);
        realSubtract(&a, &c, &a, realContext);
        realSubtract(&b, &d, &b, realContext);

        realCopy(&a, resi);
        realCopy(&b, res);
        realChangeSign(res);
    } else {
        const blocks = 25 * REAL_SIZE_IN_BLOCKS_75;
        if (allocC47Blocks(blocks)) |tv| {
            const tmpVal = blkPtr(tv);
            const LAMBDA = &tmpVal[0];
            const LAMBDA_I = &tmpVal[1];
            const MU = &tmpVal[2];
            const MU_I = &tmpVal[3];
            const B1 = &tmpVal[4];
            const B1_I = &tmpVal[5];
            const B2 = &tmpVal[6];
            const B2_I = &tmpVal[7];
            const B3 = &tmpVal[8];
            const B3_I = &tmpVal[9];
            const SIN_LAMBDA = &tmpVal[10];
            const SIN_LAMBDA_I = &tmpVal[11];
            const SIN2_LAMBDA = &tmpVal[12];
            const SIN2_LAMBDA_I = &tmpVal[13];
            const COS_LAMBDA = &tmpVal[14];
            const COS_LAMBDA_I = &tmpVal[15];
            const SIN_MU = &tmpVal[16];
            const SIN_MU_I = &tmpVal[17];
            const SIN2_MU = &tmpVal[18];
            const SIN2_MU_I = &tmpVal[19];
            const COS_MU = &tmpVal[20];
            const COS_MU_I = &tmpVal[21];
            const COS2_MU = &tmpVal[22];
            const COS2_MU_I = &tmpVal[23];
            const M1 = &tmpVal[24];

            const remainderNegative: bool = realIsNegative(&phiRemainder);
            const realContext2: *realContext_t = &runtime.ctxtReal51;
            const realContext3: *realContext_t = &runtime.ctxtReal75;

            if (remainderNegative) {
                realChangeSign(&phiRemainder);
            }
            realSubtract(const_1(), m, M1, realContext2);
            _ellipticFE_lambda_mu(&phiRemainder, &psi1, m, LAMBDA, LAMBDA_I, MU, MU_I, realContext2);
            math_command_wrappers.sinComplex(LAMBDA, LAMBDA_I, SIN_LAMBDA, SIN_LAMBDA_I, realContext2);
            math_command_wrappers.cosComplex(LAMBDA, LAMBDA_I, COS_LAMBDA, COS_LAMBDA_I, realContext2);
            math_command_wrappers.sinComplex(MU, MU_I, SIN_MU, SIN_MU_I, realContext2);
            math_command_wrappers.cosComplex(MU, MU_I, COS_MU, COS_MU_I, realContext2);
            math_multiplication_cells.mulComplexComplex(SIN_LAMBDA, SIN_LAMBDA_I, SIN_LAMBDA, SIN_LAMBDA_I, SIN2_LAMBDA, SIN2_LAMBDA_I, realContext2);
            math_multiplication_cells.mulComplexComplex(SIN_MU, SIN_MU_I, SIN_MU, SIN_MU_I, SIN2_MU, SIN2_MU_I, realContext2);
            math_multiplication_cells.mulComplexComplex(COS_MU, COS_MU_I, COS_MU, COS_MU_I, COS2_MU, COS2_MU_I, realContext2);

            realMultiply(m, SIN2_LAMBDA, B1, realContext2);
            realMultiply(m, SIN2_LAMBDA_I, B1_I, realContext2);
            realSubtract(const_1(), B1, B2, realContext2);
            realSubtract(const_0(), B1_I, B2_I, realContext2);
            math_transform_complex_helpers.sqrtComplex(B2, B2_I, B1, B1_I, realContext2);
            math_multiplication_cells.mulComplexComplex(SIN2_MU, SIN2_MU_I, B1, B1_I, B1, B1_I, realContext2);
            math_multiplication_cells.mulComplexComplex(COS_LAMBDA, COS_LAMBDA_I, B1, B1_I, B1, B1_I, realContext2);
            math_multiplication_cells.mulComplexComplex(SIN_LAMBDA, SIN_LAMBDA_I, B1, B1_I, B1, B1_I, realContext2);
            realMultiply(m, B1, B1, realContext2);
            realMultiply(m, B1_I, B1_I, realContext2);

            realMultiply(M1, SIN2_MU, B3, realContext2);
            realMultiply(M1, SIN2_MU_I, B3_I, realContext2);
            realSubtract(const_1(), B3, B3, realContext2);
            realSubtract(const_0(), B3_I, B3_I, realContext2);
            math_transform_complex_helpers.sqrtComplex(B3, B3_I, B3, B3_I, realContext2);
            math_multiplication_cells.mulComplexComplex(B2, B2_I, B3, B3_I, B2, B2_I, realContext2);
            math_multiplication_cells.mulComplexComplex(B2, B2_I, SIN_MU, SIN_MU_I, B2, B2_I, realContext2);
            math_multiplication_cells.mulComplexComplex(B2, B2_I, COS_MU, COS_MU_I, B2, B2_I, realContext2);

            realMultiply(m, SIN2_LAMBDA, B3, realContext2);
            realMultiply(m, SIN2_LAMBDA_I, B3_I, realContext2);
            math_multiplication_cells.mulComplexComplex(B3, B3_I, SIN2_MU, SIN2_MU_I, B3, B3_I, realContext2);
            realAdd(COS2_MU, B3, B3, realContext2);
            realAdd(COS2_MU_I, B3_I, B3_I, realContext2);

            realSubtract(B1, B2_I, res, realContext2);
            realAdd(B1_I, B2, resi, realContext2);
            math_division_cells.divComplexComplex(res, resi, B3, B3_I, res, resi, realContext2);

            ellipticE(LAMBDA, LAMBDA_I, m, B1, B1_I, realContext3);
            ellipticE(MU, MU_I, M1, B2, B2_I, realContext3);
            ellipticF(MU, MU_I, M1, B3, B3_I, realContext3);

            realSubtract(res, B3_I, res, realContext);
            realAdd(resi, B3, resi, realContext);
            realAdd(res, B2_I, res, realContext);
            realSubtract(resi, B2, resi, realContext);
            realAdd(res, B1, res, realContext);
            realAdd(resi, B1_I, resi, realContext);

            if (remainderNegative) {
                realChangeSign(res);
            }

            if (!realIsZero(&phiQuotient)) {
                ellipticKE(m, null, null, B1, B1_I, realContext);
                realSetPositiveSign(&phiQuotient);
                realAdd(&phiQuotient, &phiQuotient, &phiQuotient, realContext);
                realMultiply(&phiQuotient, B1, B1, realContext);
                realMultiply(&phiQuotient, B1_I, B1_I, realContext);
                realAdd(res, B1, res, realContext);
                realAdd(resi, B1_I, resi, realContext);
            }

            if (realIsNegative(psi)) {
                realChangeSign(resi);
            }

            freeC47Blocks(tv, blocks);
        } else {
            displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
            realSetNaN(res);
            realSetNaN(resi);
        }
    }
}

fn _jacobiZeta_Agm(phi: *const real_t, psi: *const real_t, m: *const real_t, res: *real_t, resi: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var n: i32 = undefined;

    if (realIsZero(m)) {
        realSetZero(res);
        realSetZero(resi);
        return;
    }
    if (realCompareEqual(m, const_1())) {
        var k: real_t = undefined;
        var ki: real_t = undefined;
        ellipticF(phi, psi, m, &k, &ki, realContext);
        _ = math_command_wrappers.TanhComplex(&k, &ki, res, resi, realContext);
        return;
    }

    const blocks = ELLIPTIC_N * REAL_SIZE_IN_BLOCKS_75;
    const a_p = allocC47Blocks(blocks) orelse {
        displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
        realSetNaN(res);
        realSetNaN(resi);
        return;
    };
    const a = blkPtr(a_p);
    const ai_p = allocC47Blocks(blocks) orelse {
        displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
        realSetNaN(res);
        realSetNaN(resi);
        freeC47Blocks(a_p, blocks);
        return;
    };
    const ai = blkPtr(ai_p);
    const b_p = allocC47Blocks(blocks) orelse {
        displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
        realSetNaN(res);
        realSetNaN(resi);
        freeC47Blocks(ai_p, blocks);
        freeC47Blocks(a_p, blocks);
        return;
    };
    const b = blkPtr(b_p);
    const bi_p = allocC47Blocks(blocks) orelse {
        displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
        realSetNaN(res);
        realSetNaN(resi);
        freeC47Blocks(b_p, blocks);
        freeC47Blocks(ai_p, blocks);
        freeC47Blocks(a_p, blocks);
        return;
    };
    const bi = blkPtr(bi_p);

    var k: real_t = undefined;
    var ki: real_t = undefined;
    var c: real_t = undefined;
    var ci: real_t = undefined;
    var s: real_t = undefined;
    var si: real_t = undefined;
    var q: real_t = undefined;

    realSetZero(res);
    realSetZero(resi);
    realSubtract(const_1(), m, &k, realContext);
    rcSqrt(&k, &k, &ki, realContext);
    n = @intCast(math_agm.complexAgmStep(const_1(), const_0(), &k, &ki, &c, &ci, a, ai, b, bi, ELLIPTIC_N, realContext));
    ellipticF(phi, psi, m, &k, &ki, realContext);
    math_multiplication_cells.mulComplexComplex(&k, &ki, &a[@intCast(n)], &ai[@intCast(n)], &k, &ki, realContext);
    {
        var i: i32 = 0;
        while (i < n) : (i += 1) {
            realAdd(&k, &k, &k, realContext);
            realAdd(&ki, &ki, &ki, realContext);
        }
    }
    {
        var i: i32 = n;
        while (i > 0) : (i -= 1) {
            const ii: usize = @intCast(i);
            realCopy(&k, &q);
            math_wp34s.mod2Pi(&q, &k, realContext);
            if (math_comparison_reals.realCompareGreaterThan(&k, const39_pi())) {
                realSubtract(&k, const75_2pi(), &k, realContext);
            }
            realSubtract(&q, &k, &q, realContext);
            realSubtract(&a[ii - 1], &b[ii - 1], &c, realContext);
            realSubtract(&ai[ii - 1], &bi[ii - 1], &ci, realContext);
            realMultiply(&c, const_1on2(), &c, realContext);
            realMultiply(&ci, const_1on2(), &ci, realContext);
            math_command_wrappers.sinComplex(&k, &ki, &s, &si, realContext);
            math_multiplication_cells.mulComplexComplex(&s, &si, &c, &ci, &s, &si, realContext);
            realAdd(&s, res, res, realContext);
            realAdd(&si, resi, resi, realContext);
            math_division_cells.divComplexComplex(&s, &si, &a[ii], &ai[ii], &s, &si, realContext);
            if (realIsZero(&si) and !math_comparison_reals.realCompareAbsLessThan(const_1(), &s)) {
                math_wp34s.C47_WP34S_Asin(&s, &s, realContext);
            } else {
                _ = math_inverse_trig_command.ArcsinComplex(&s, &si, &s, &si, realContext);
            }
            realAdd(&s, &k, &s, realContext);
            realAdd(&si, &ki, &si, realContext);
            realAdd(&s, &q, &s, realContext);
            realMultiply(&s, const_1on2(), &k, realContext);
            realMultiply(&si, const_1on2(), &ki, realContext);
        }
    }
    freeC47Blocks(bi_p, blocks);
    freeC47Blocks(b_p, blocks);
    freeC47Blocks(ai_p, blocks);
    freeC47Blocks(a_p, blocks);
}

fn _jacobiZeta_carlson(phi: *const real_t, m: *const real_t, res: *real_t, resi: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
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
    if (realIsZero(m)) {
        realSetZero(res);
        realSetZero(resi);
        return;
    }
    if (realCompareEqual(m, const_1())) {
        var k: real_t = undefined;
        var ki: real_t = undefined;
        ellipticF(phi, const_0(), m, &k, &ki, realContext);
        _ = math_command_wrappers.TanhComplex(&k, &ki, res, resi, realContext);
        return;
    }
    math_wp34s.C47_WP34S_Cvt2RadSinCosTan(phi, amRadian, &s, &c, null, realContext);
    realMultiply(&s, &s, &s2, realContext);
    realMultiply(&c, &c, &c2, realContext);
    realFMA(m, &s2, const__1Off(), &y, realContext);
    realChangeSign(&y);
    carlsonRF(&c2, &y, const_1(), &rf, realContext);
    carlsonRD(&c2, &y, const_1(), &rd, realContext);
    realMultiply(&s, &rf, &f_phi, realContext);
    realMultiply(&s2, &s, &s2, realContext);
    realMultiply(m, &s2, &s2, realContext);
    realMultiply(&s2, const39_1on3(), &s2, realContext);
    realChangeSign(&s2);
    realFMA(&s2, &rd, &f_phi, &e_phi, realContext);
    ellipticKE(m, &ek, null, &em, null, realContext);
    realDivide(&em, &ek, &em, realContext);
    realChangeSign(&em);
    realFMA(&em, &f_phi, &e_phi, res, realContext);
    realSetZero(resi);
}

fn _jacobiZeta(phi: *const real_t, psi: *const real_t, m: *const real_t, res: *real_t, resi: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    if (math_comparison_reals.realCompareLessEqual(m, const_1())) {
        if (realIsZero(psi) and !realIsNegative(m)) {
            _jacobiZeta_carlson(phi, m, res, resi, realContext);
        } else {
            _jacobiZeta_Agm(phi, psi, m, res, resi, realContext);
        }
    } else if (math_comparison_reals.realCompareLessEqual(m, const_2())) {
        var n: i32 = 0;
        var phir: real_t = undefined;
        var phii: real_t = undefined;
        var ur: real_t = undefined;
        var ui: real_t = undefined;
        var pp: real_t = undefined;
        realCopy(phi, &phir);
        realCopy(psi, &phii);
        ellipticF(&phir, &phii, m, &ur, &ui, realContext);

        if (math_comparison_reals.realCompareLessEqual(m, const_2())) {
            realCopy(const_1on4(), &pp);
        } else {
            realDivide(const_1on2(), m, &pp, realContext);
        }

        while (math_comparison_reals.realCompareGreaterThan(&phir, &pp)) {
            n += 1;
            realMultiply(&ur, const_1on2(), &ur, realContext);
            realMultiply(&ui, const_1on2(), &ui, realContext);
            jacobiComplexAm(&ur, &ui, m, &phir, &phii, realContext);
        }

        _jacobiZeta_Agm(&phir, &phii, m, res, resi, realContext);
        while (true) {
            const old = n;
            n -= 1;
            if (old <= 0) break;
            var a: real_t = undefined;
            var b: real_t = undefined;
            var c: real_t = undefined;
            var d: real_t = undefined;
            realAdd(res, res, res, realContext);
            realAdd(resi, resi, resi, realContext);
            jacobiComplexSn(&ur, &ui, m, &a, &b, realContext);
            math_multiplication_cells.mulComplexComplex(&a, &b, &a, &b, &a, &b, realContext);
            realMultiply(&a, m, &a, realContext);
            realMultiply(&b, m, &b, realContext);
            realAdd(&ur, &ur, &ur, realContext);
            realAdd(&ui, &ui, &ui, realContext);
            jacobiComplexSn(&ur, &ui, m, &c, &d, realContext);
            math_multiplication_cells.mulComplexComplex(&a, &b, &c, &d, &a, &b, realContext);
            realSubtract(res, &a, res, realContext);
            realSubtract(resi, &b, resi, realContext);
        }
    }
}

pub export fn jacobiZeta(phi: *const real_t, psi: *const real_t, m: *const real_t, res: *real_t, resi: *real_t, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    var v: real_t = undefined;
    var vi: real_t = undefined;
    var negative: bool = realIsNegative(phi);

    if (realIsZero(m)) {
        realSetZero(res);
        realSetZero(resi);
        return;
    }

    realCopy(phi, &v);
    realCopy(psi, &vi);
    if (negative) {
        realChangeSign(&v);
        realChangeSign(&vi);
    }
    realSetNaN(res);
    realSetNaN(resi);

    math_wp34s.WP34S_Mod(&v, const39_pi(), &v, realContext);
    if (math_comparison_reals.realCompareGreaterThan(&v, const39_piOn2())) {
        realSubtract(const39_pi(), &v, &v, realContext);
        realChangeSign(&vi);
        negative = !negative;
    }
    if (realIsZero(&vi)) {
        _jacobiZeta(&v, &vi, m, res, resi, realContext);
    } else {
        var a: real_t = undefined;
        var b: real_t = undefined;
        var c: real_t = undefined;
        var d: real_t = undefined;
        ellipticKE(m, &a, &b, &c, &d, realContext);
        math_division_cells.divComplexComplex(&c, &d, &a, &b, &a, &b, realContext);
        ellipticF(&v, &vi, m, &c, &d, realContext);
        math_multiplication_cells.mulComplexComplex(&a, &b, &c, &d, &a, &b, realContext);
        ellipticE(&v, &vi, m, &c, &d, realContext);
        realSubtract(&c, &a, res, realContext);
        realSubtract(&d, &b, resi, realContext);
    }

    if (negative) {
        realChangeSign(res);
        realChangeSign(resi);
    }
}

fn heumanLambda(phi: *const real_t, psi: *const real_t, m: *const real_t, res: *real_t, resi: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var k: real_t = undefined;
    var ki: real_t = undefined;
    var k1: real_t = undefined;
    var k1i: real_t = undefined;
    var z: real_t = undefined;
    var zi: real_t = undefined;
    var f: real_t = undefined;
    var fi: real_t = undefined;
    var m1: real_t = undefined;

    realSubtract(const_1(), m, &m1, realContext);
    ellipticKE(m, &k, &ki, null, null, realContext);
    ellipticKE(&m1, &k1, &k1i, null, null, realContext);
    ellipticF(phi, psi, &m1, &f, &fi, realContext);
    jacobiZeta(phi, psi, &m1, &z, &zi, realContext);

    math_division_cells.divComplexComplex(&f, &fi, &k1, &k1i, res, resi, realContext);
    math_multiplication_cells.mulComplexComplex(&k, &ki, &z, &zi, &z, &zi, realContext);
    math_division_cells.divComplexComplex(&z, &zi, const39_piOn2(), const_0(), &z, &zi, realContext);
    realAdd(res, &z, res, realContext);
    realAdd(resi, &zi, resi, realContext);
}

fn _ellipticPi_1(n: *const real_t, m: *const real_t, res: *real_t, resi: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var epsilon: real_t = undefined;
    var epsiloni: real_t = undefined;
    var delta1: real_t = undefined;
    var delta1i: real_t = undefined;
    var k: real_t = undefined;
    var ki: real_t = undefined;
    var z: real_t = undefined;
    var zi: real_t = undefined;
    var p: real_t = undefined;

    realDivide(n, m, &epsilon, realContext);
    rcSqrt(&epsilon, &epsilon, &epsiloni, realContext);
    _ = math_inverse_trig_command.ArcsinComplex(&epsilon, &epsiloni, &epsilon, &epsiloni, realContext);

    realSubtract(const_1(), n, &delta1, realContext);
    realDivide(n, &delta1, &delta1, realContext);
    realSubtract(m, n, &p, realContext);
    realDivide(&delta1, &p, &delta1, realContext);
    rcSqrt(&delta1, &delta1, &delta1i, realContext);

    ellipticKE(m, &k, &ki, null, null, realContext);
    jacobiZeta(&epsilon, &epsiloni, m, &z, &zi, realContext);
    math_multiplication_cells.mulComplexComplex(&k, &ki, &z, &zi, res, resi, realContext);
    math_multiplication_cells.mulComplexComplex(res, resi, &delta1, &delta1i, res, resi, realContext);
    realAdd(res, &k, res, realContext);
    realAdd(resi, &ki, resi, realContext);
}

fn _ellipticPi_2(n: *const real_t, m: *const real_t, res: *real_t, resi: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var nn: real_t = undefined;
    var k: real_t = undefined;
    var ki: real_t = undefined;

    realDivide(m, n, &nn, realContext);
    ellipticKE(m, &k, &ki, null, null, realContext);
    _ellipticPi_1(&nn, m, res, resi, realContext);
    realSubtract(&k, res, res, realContext);
    realSubtract(&ki, resi, resi, realContext);
}

fn _ellipticPi_3(n: *const real_t, m: *const real_t, res: *real_t, resi: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var epsilon: real_t = undefined;
    var epsiloni: real_t = undefined;
    var delta2: real_t = undefined;
    var delta2i: real_t = undefined;
    var k: real_t = undefined;
    var ki: real_t = undefined;
    var n1: real_t = undefined;
    var m1: real_t = undefined;
    var p: real_t = undefined;

    realSubtract(const_1(), n, &n1, realContext);
    realSubtract(const_1(), m, &m1, realContext);

    realDivide(&n1, &m1, &epsilon, realContext);
    rcSqrt(&epsilon, &epsilon, &epsiloni, realContext);
    _ = math_inverse_trig_command.ArcsinComplex(&epsilon, &epsiloni, &epsilon, &epsiloni, realContext);

    realDivide(n, &n1, &delta2, realContext);
    realSubtract(n, m, &p, realContext);
    realDivide(&delta2, &p, &delta2, realContext);
    rcSqrt(&delta2, &delta2, &delta2i, realContext);

    ellipticKE(m, &k, &ki, null, null, realContext);

    heumanLambda(&epsilon, &epsiloni, m, res, resi, realContext);
    realSubtract(const_1(), res, res, realContext);
    realChangeSign(resi);
    math_multiplication_cells.mulComplexComplex(&delta2, &delta2i, res, resi, res, resi, realContext);
    realFMA(const39_piOn2(), res, &k, res, realContext);
    realFMA(const39_piOn2(), resi, &ki, resi, realContext);
}

fn _ellipticPi_4(n: *const real_t, m: *const real_t, res: *real_t, resi: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var nn: real_t = undefined;
    var k: real_t = undefined;
    var ki: real_t = undefined;
    var mmn: real_t = undefined;
    var n1: real_t = undefined;

    realSubtract(m, n, &mmn, realContext);
    realSubtract(const_1(), n, &n1, realContext);
    realDivide(&mmn, &n1, &nn, realContext);
    ellipticKE(m, &k, &ki, null, null, realContext);

    _ellipticPi_3(&nn, m, res, resi, realContext);
    math_division_cells.divComplexComplex(res, resi, &mmn, const_0(), res, resi, realContext);
    math_division_cells.divComplexComplex(res, resi, &n1, const_0(), res, resi, realContext);
    realMultiply(m, res, res, realContext);
    realMultiply(m, resi, resi, realContext);
    realMultiply(n, res, res, realContext);
    realMultiply(n, resi, resi, realContext);

    math_division_cells.divComplexComplex(&k, &ki, &mmn, const_0(), &k, &ki, realContext);
    realMultiply(m, &k, &k, realContext);
    realMultiply(m, &ki, &ki, realContext);

    realSubtract(&k, res, res, realContext);
    realSubtract(&ki, resi, resi, realContext);
}

pub export fn ellipticPi(n: *const real_t, m: *const real_t, res: *real_t, resi: *real_t, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    if (realIsZero(n)) {
        ellipticKE(m, res, resi, null, null, realContext);
    } else if (realIsZero(m)) {
        if (math_comparison_reals.realCompareLessThan(n, const_1())) {
            realSubtract(const_1(), n, res, realContext);
            rcSqrt(res, res, resi, realContext);
            math_division_cells.divComplexComplex(const39_piOn2(), const_0(), res, resi, res, resi, realContext);
        } else if (math_comparison_reals.realCompareGreaterThan(n, const_1())) {
            realSubtract(n, const_1(), res, realContext);
            rcSqrt(res, res, resi, realContext);
            math_division_cells.divComplexComplex(const_0(), const_1(), res, resi, res, resi, realContext);
            realMultiply(const39_piOn2(), res, res, realContext);
            realMultiply(const39_piOn2(), resi, resi, realContext);
            realChangeSign(res);
            realChangeSign(resi);
        } else { // n = 1
            realSetNaN(res);
            realSetZero(resi);
        }
    } else if (realCompareEqual(m, const_1())) {
        if (math_comparison_reals.realCompareLessThan(n, const_1())) {
            realSetPlusInfinity(res);
            realSetZero(resi);
        } else if (math_comparison_reals.realCompareGreaterThan(n, const_1())) {
            realSetMinusInfinity(res);
            realSetZero(resi);
        } else { // n = 1
            realSetNaN(res);
            realSetZero(resi);
        }
    } else if (realCompareEqual(m, n)) {
        var cos2Alpha: real_t = undefined;
        var e: real_t = undefined;
        var ei: real_t = undefined;

        realSubtract(const_1(), m, &cos2Alpha, realContext);
        ellipticKE(m, null, null, &e, &ei, realContext);
        math_division_cells.divComplexComplex(&e, &ei, &cos2Alpha, const_0(), res, resi, realContext);
    } else if (realCompareEqual(m, const_1())) {
        realSetNaN(res);
        realSetZero(resi);
    } else if (math_comparison_reals.realCompareGreaterThan(n, const_1())) {
        _ellipticPi_2(n, m, res, resi, realContext);
    } else if (realIsNegative(n)) {
        _ellipticPi_4(n, m, res, resi, realContext);
    } else if (math_comparison_reals.realCompareLessThan(n, m)) {
        _ellipticPi_1(n, m, res, resi, realContext);
    } else {
        _ellipticPi_3(n, m, res, resi, realContext);
    }
}

// ===========================================================================
// fnJacobiSn / Cn / Dn / Amplitude
// ===========================================================================
pub export fn fnJacobiSn(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var realInput: bool = undefined;
    var m: real_t = undefined;
    var uReal: real_t = undefined;
    var uImag: real_t = undefined;
    var rReal: real_t = undefined;
    var rImag: real_t = undefined;

    if (jacobi_check_inputs(&m, &uReal, &uImag, &realInput) == 0) {
        return;
    }

    if (realInput) {
        jacobiElliptic(&uReal, &m, null, &rReal, null, null, &runtime.ctxtReal39);
        convertRealToResultRegister(&rReal, REGISTER_X, amNone);
    } else {
        jacobiComplexSn(&uReal, &uImag, &m, &rReal, &rImag, &runtime.ctxtReal39);
        convertComplexToResultRegister(&rReal, &rImag, REGISTER_X);
    }

    adjustResult(REGISTER_X, true, true, REGISTER_X, -1, -1);
}

pub export fn fnJacobiCn(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var realInput: bool = undefined;
    var m: real_t = undefined;
    var uReal: real_t = undefined;
    var uImag: real_t = undefined;
    var rReal: real_t = undefined;
    var rImag: real_t = undefined;

    if (jacobi_check_inputs(&m, &uReal, &uImag, &realInput) == 0) {
        return;
    }

    if (realInput) {
        jacobiElliptic(&uReal, &m, null, null, &rReal, null, &runtime.ctxtReal39);
        convertRealToResultRegister(&rReal, REGISTER_X, amNone);
    } else {
        jacobiComplexCn(&uReal, &uImag, &m, &rReal, &rImag, &runtime.ctxtReal39);
        convertComplexToResultRegister(&rReal, &rImag, REGISTER_X);
    }

    adjustResult(REGISTER_X, true, true, REGISTER_X, -1, -1);
}

pub export fn fnJacobiDn(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var realInput: bool = undefined;
    var m: real_t = undefined;
    var uReal: real_t = undefined;
    var uImag: real_t = undefined;
    var rReal: real_t = undefined;
    var rImag: real_t = undefined;

    if (jacobi_check_inputs(&m, &uReal, &uImag, &realInput) == 0) {
        return;
    }

    if (realInput) {
        jacobiElliptic(&uReal, &m, null, null, null, &rReal, &runtime.ctxtReal39);
        convertRealToResultRegister(&rReal, REGISTER_X, amNone);
    } else {
        jacobiComplexDn(&uReal, &uImag, &m, &rReal, &rImag, &runtime.ctxtReal39);
        convertComplexToResultRegister(&rReal, &rImag, REGISTER_X);
    }

    adjustResult(REGISTER_X, true, true, REGISTER_X, -1, -1);
}

pub export fn fnJacobiAmplitude(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var realInput: bool = undefined;
    var m: real_t = undefined;
    var uReal: real_t = undefined;
    var uImag: real_t = undefined;
    var rReal: real_t = undefined;
    var rImag: real_t = undefined;

    if (jacobi_check_inputs(&m, &uReal, &uImag, &realInput) == 0) {
        return;
    }

    if (realInput) {
        jacobiElliptic(&uReal, &m, &rReal, null, null, null, &runtime.ctxtReal39);
        convertAngleFromTo(&rReal, amRadian, currentAngularMode, &runtime.ctxtReal39);
        convertRealToResultRegister(&rReal, REGISTER_X, currentAngularMode);
    } else {
        jacobiComplexAm(&uReal, &uImag, &m, &rReal, &rImag, &runtime.ctxtReal39);
        convertComplexToResultRegister(&rReal, &rImag, REGISTER_X);
    }

    adjustResult(REGISTER_X, true, true, REGISTER_X, -1, -1);
}

// L2 error surface (REPORT-23 P1/P5): the command cores return a domain error
// instead of calling displayCalcErrorMessage inline; the L3 shims map it and run
// the trailing adjustResult (which the C runs on every path, including the error).
const EllipticError = error{
    KNeedsCpxRes,
    ENeedsCpxRes,
    FphiNeedsCpxRes,
    EphiNeedsCpxRes,
    ZetaNeedsCpxRes,
    PiMOutOfRange,
    PiNeedsCpxRes,
    PiComplexInX,
};

fn reportEllipticError(e: EllipticError) void {
    switch (e) {
        error.KNeedsCpxRes => {
            displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnError("In function fnEllipticK:", "Cannot calculate K(m) for m > 1 if CPXRES is not set", null, null);
        },
        error.ENeedsCpxRes => {
            displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnError("In function fnEllipticE:", "Cannot calculate K(m) for m > 1 if CPXRES is not set", null, null);
        },
        error.FphiNeedsCpxRes => {
            displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnError("In function fnEllipticFphi:", "cannot return complex result without CPXRES set", null, null);
        },
        error.EphiNeedsCpxRes => {
            displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnError("In function fnEllipticEphi:", "cannot return complex result without CPXRES set", null, null);
        },
        error.ZetaNeedsCpxRes => {
            displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnError("In function fnJacobiZeta:", "cannot return complex result without CPXRES set", null, null);
        },
        error.PiMOutOfRange => {
            displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnError("In function fnEllipticPi:", "m is out of range (must in 0 <= m < 1)", null, null);
        },
        error.PiNeedsCpxRes => {
            displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnError("In function fnEllipticPi:", "cannot return complex result without CPXRES set", null, null);
        },
        error.PiComplexInX => {
            displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnError("In function fnEllipticPi:", "cannot calculate elliptic integral with complex in X", null, null);
        },
    }
}

fn fnEllipticKCore() EllipticError!void {
    var m: real_t = undefined;
    var a: real_t = undefined;
    var b: real_t = undefined;

    if (!saveLastX()) return;
    if (!getRegisterAsReal(REGISTER_X, &m)) return;

    if (math_comparison_reals.realCompareLessEqual(&m, const_1())) {
        ellipticKE(&m, &b, null, null, null, &runtime.ctxtReal39);
        convertRealToResultRegister(&b, REGISTER_X, amNone);
    } else if (getFlag(FLAG_CPXRES)) {
        ellipticKE(&m, &a, &b, null, null, &runtime.ctxtReal39);
        convertComplexToResultRegister(&a, &b, REGISTER_X);
    } else {
        return error.KNeedsCpxRes;
    }
    adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}

pub export fn fnEllipticK(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    fnEllipticKCore() catch |e| {
        reportEllipticError(e);
        adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
    };
}

fn fnEllipticECore() EllipticError!void {
    var m: real_t = undefined;
    var a: real_t = undefined;
    var b: real_t = undefined;

    if (!saveLastX()) return;
    if (!getRegisterAsReal(REGISTER_X, &m)) return;

    if (math_comparison_reals.realCompareLessEqual(&m, const_1())) {
        ellipticKE(&m, null, null, &b, null, &runtime.ctxtReal39);
        convertRealToResultRegister(&b, REGISTER_X, amNone);
    } else if (getFlag(FLAG_CPXRES)) {
        ellipticKE(&m, null, null, &a, &b, &runtime.ctxtReal39);
        convertComplexToResultRegister(&a, &b, REGISTER_X);
    } else {
        return error.ENeedsCpxRes;
    }
    adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}

pub export fn fnEllipticE(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    fnEllipticECore() catch |e| {
        reportEllipticError(e);
        adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
    };
}

fn fnEllipticPiCore() EllipticError!void {
    var m: real_t = undefined;
    var ur: real_t = undefined;
    var ui: real_t = undefined;
    var rr: real_t = undefined;
    var ri: real_t = undefined;
    var realInput: bool = undefined;

    if (jacobi_check_inputs(&m, &ur, &ui, &realInput) == 0) return;

    if (realIsNegative(&m) or math_comparison_reals.realCompareGreaterEqual(&m, const_1())) {
        return error.PiMOutOfRange;
    } else if (realInput) {
        ellipticPi(&ur, &m, &rr, &ri, &runtime.ctxtReal39);
        if (realIsZero(&ri)) {
            convertRealToResultRegister(&rr, REGISTER_X, amNone);
        } else if (getFlag(FLAG_CPXRES)) {
            convertComplexToResultRegister(&rr, &ri, REGISTER_X);
        } else {
            return error.PiNeedsCpxRes;
        }
    } else {
        return error.PiComplexInX;
    }

    adjustResult(REGISTER_X, true, true, REGISTER_X, -1, -1);
}

pub export fn fnEllipticPi(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    fnEllipticPiCore() catch |e| {
        reportEllipticError(e);
        adjustResult(REGISTER_X, true, true, REGISTER_X, -1, -1);
    };
}

fn fnEllipticFphiCore() EllipticError!void {
    var realInput: bool = undefined;
    var m: real_t = undefined;
    var uReal: real_t = undefined;
    var uImag: real_t = undefined;
    var rReal: real_t = undefined;
    var rImag: real_t = undefined;

    if (jacobi_check_inputs_phi(&m, &uReal, &uImag, &realInput) == 0) return;

    ellipticF(&uReal, &uImag, &m, &rReal, &rImag, &runtime.ctxtReal39);
    if (realInput) {
        if (realIsZero(&rImag)) {
            convertRealToResultRegister(&rReal, REGISTER_X, amNone);
        } else if (getFlag(FLAG_CPXRES)) {
            convertComplexToResultRegister(&rReal, &rImag, REGISTER_X);
        } else {
            return error.FphiNeedsCpxRes;
        }
    } else {
        convertComplexToResultRegister(&rReal, &rImag, REGISTER_X);
    }

    adjustResult(REGISTER_X, true, true, REGISTER_X, -1, -1);
}

pub export fn fnEllipticFphi(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    fnEllipticFphiCore() catch |e| {
        reportEllipticError(e);
        adjustResult(REGISTER_X, true, true, REGISTER_X, -1, -1);
    };
}

fn fnEllipticEphiCore() EllipticError!void {
    var realInput: bool = undefined;
    var m: real_t = undefined;
    var uReal: real_t = undefined;
    var uImag: real_t = undefined;
    var rReal: real_t = undefined;
    var rImag: real_t = undefined;

    if (jacobi_check_inputs_phi(&m, &uReal, &uImag, &realInput) == 0) return;

    ellipticE(&uReal, &uImag, &m, &rReal, &rImag, &runtime.ctxtReal39);
    if (realInput) {
        if (realIsZero(&rImag)) {
            convertRealToResultRegister(&rReal, REGISTER_X, amNone);
        } else if (getFlag(FLAG_CPXRES)) {
            convertComplexToResultRegister(&rReal, &rImag, REGISTER_X);
        } else {
            return error.EphiNeedsCpxRes;
        }
    } else {
        convertComplexToResultRegister(&rReal, &rImag, REGISTER_X);
    }

    adjustResult(REGISTER_X, true, true, REGISTER_X, -1, -1);
}

pub export fn fnEllipticEphi(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    fnEllipticEphiCore() catch |e| {
        reportEllipticError(e);
        adjustResult(REGISTER_X, true, true, REGISTER_X, -1, -1);
    };
}

fn fnJacobiZetaCore() EllipticError!void {
    var realInput: bool = undefined;
    var m: real_t = undefined;
    var uReal: real_t = undefined;
    var uImag: real_t = undefined;
    var rReal: real_t = undefined;
    var rImag: real_t = undefined;

    if (jacobi_check_inputs_phi(&m, &uReal, &uImag, &realInput) == 0) return;

    jacobiZeta(&uReal, &uImag, &m, &rReal, &rImag, &runtime.ctxtReal39);
    if (realInput) {
        if (realIsZero(&rImag)) {
            convertRealToResultRegister(&rReal, REGISTER_X, amNone);
        } else if (getFlag(FLAG_CPXRES)) {
            convertComplexToResultRegister(&rReal, &rImag, REGISTER_X);
        } else {
            return error.ZetaNeedsCpxRes;
        }
    } else {
        convertComplexToResultRegister(&rReal, &rImag, REGISTER_X);
    }

    adjustResult(REGISTER_X, true, true, REGISTER_X, -1, -1);
}

pub export fn fnJacobiZeta(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    fnJacobiZetaCore() catch |e| {
        reportEllipticError(e);
        adjustResult(REGISTER_X, true, true, REGISTER_X, -1, -1);
    };
}
