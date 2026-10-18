// SPDX-License-Identifier: GPL-3.0-only
const abi = @import("abi");
const consts = abi.constants;
const const__1 = consts.const__1;
const const_1on4 = consts.const_1on4;
const const_1on2 = consts.const_1on2;
const const_3 = consts.const_3;
const const_4 = consts.const_4;
const const_5 = consts.const_5;
const const_8 = consts.const_8;
const const_24 = consts.const_24;
const const_90 = consts.const_90;
const const_45 = consts.const_45;
const const75_pi = runtime.z47_math_wrappers_const75_pi;
const const75_piOn4 = runtime.z47_math_wrappers_const75_piOn4;
const const75_piOn2 = consts.const75_piOn2;
const const75_2pi = consts.const75_2pi;
const const75_egamma = consts.const75_egamma;
//
// Zig owner for src/c47/mathematics/bessel.c: the Bessel J and Y commands
// (fnBesselJ / fnBesselY) plus the public WP34S_BesselJ / WP34S_BesselY
// engines and their static helpers (Hankel large-x, Debye large-order hyp/trig
// asymptotic expansions, Abramowitz & Stegun recurrence, digamma, the series).
// Faithful line-by-line translation preserving the exact order of every real_t
// operation (bessel_j.txt / bessel_y.txt check results to the last ULP). The
// static helpers stay private; fnBesselJ / fnBesselY keep C linkage, and
// WP34S_BesselJ / WP34S_BesselY keep it where OPTION_BESSEL compiles them in.
// The EXTRA_INFO_ON_CALC_ERROR sprintf hints
// become fixed moreInfoOnError strings (no-op under TESTSUITE / DMCP). The
// OPTION_BESSEL is LIVE: upstream drops it for some DM42 packages, where it
// empties fnBesselJ/fnBesselY rather than removing them. The
// two commands below return immediately when option_bessel is false, which is
// that empty body. Do not read the gate as dead code.

const runtime = @import("../command_wrappers/runtime.zig");
const math_command_wrappers = @import("../command_wrappers.zig");
const math_comparison_reals = @import("../compare/comparison_reals.zig");
const math_inverse_trig_command = @import("../trig/inverse_trig_command.zig");
const math_wp34s = @import("wp34s.zig");
const real_t = runtime.real_t;
const cplx_t = runtime.cplx_t;
const realContext_t = runtime.realContext_t;

// Arithmetic ops accepting *align(1) const operands (blob constants pass here).
extern fn decNumberAdd(result: *real_t, lhs: *align(1) const real_t, rhs: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberSubtract(result: *real_t, lhs: *align(1) const real_t, rhs: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberMultiply(result: *real_t, lhs: *align(1) const real_t, rhs: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberDivide(result: *real_t, lhs: *align(1) const real_t, rhs: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberSquareRoot(result: *real_t, rhs: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberPower(result: *real_t, lhs: *align(1) const real_t, rhs: *align(1) const real_t, ctxt: *realContext_t) *real_t;
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
inline fn realPower(lhs: *align(1) const real_t, rhs: *align(1) const real_t, result: *real_t, ctxt: *realContext_t) void {
    _ = decNumberPower(result, lhs, rhs, ctxt);
}
const realChangeSign = runtime.realChangeSign;
const realSetZero = runtime.realSetZero;
const realSetOne = runtime.realSetOne;
const realSetNaN = runtime.realSetNaN;
const realIsZero = runtime.realIsZero;
const realIsNaN = runtime.realIsNaN;
const realIsNegative = runtime.realIsNegative;
const realIsInfinite = runtime.realIsInfinite;
const realIsSpecial = runtime.realIsSpecial;
const realIsAnInteger = runtime.realIsAnInteger;
const realSetPositiveSign = runtime.realSetPositiveSign;
const realToIntegralValue = runtime.realToIntegralValue;
const realToInt32C47 = runtime.realToInt32C47;
const realCompareEqual = runtime.realCompareEqual;
const realCompareLessThan = runtime.realCompareLessThan;
const int32ToReal = runtime.int32ToReal;
const realPolarToRectangular = runtime.realPolarToRectangular;

const WP34S_Mod = runtime.WP34S_Mod;
const WP34S_Ln = runtime.WP34S_Ln;
const getSystemFlag = runtime.getSystemFlag;

const REGISTER_X = runtime.REGISTER_X;
const REGISTER_Y = runtime.REGISTER_Y;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const NIM_REGISTER_LINE = REGISTER_X;
const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN = runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN;
const ERROR_RAM_FULL = runtime.ERROR_RAM_FULL;
const ERROR_SOLVER_ABORT: u8 = 60;
const amNone = runtime.amNone;
const amRadian = runtime.amRadian;
const dtReal34 = runtime.dtReal34;
const dtComplex34 = runtime.dtComplex34;
const DEC_ROUND_FLOOR = runtime.DEC_ROUND_FLOOR;
const FLAG_CPXRES: u16 = 0x8004;

const displayCalcErrorMessage = runtime.displayCalcErrorMessage;
const moreInfoOnError = runtime.moreInfoOnError;
const saveLastX = runtime.saveLastX;
const adjustResult = runtime.adjustResult;
const reallocateRegister = runtime.reallocateRegister;
const getRegisterAsReal = runtime.getRegisterAsReal;
const convertRealToReal34ResultRegister = runtime.convertRealToReal34ResultRegister;
const convertComplexToResultRegister = runtime.convertComplexToResultRegister;

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
extern fn decNumberCopy(res: *real_t, source: *align(1) const real_t) *real_t;
extern fn decNumberMinus(res: *real_t, operand: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberRemainder(res: *real_t, lhs: *align(1) const real_t, rhs: *align(1) const real_t, ctxt: *realContext_t) *real_t;
inline fn realDivideRemainder(operand1: *align(1) const real_t, operand2: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberRemainder(res, operand1, operand2, ctxt);
}
inline fn realCopy(source: *align(1) const real_t, destination: *real_t) void {
    _ = decNumberCopy(destination, source);
}
inline fn realCopyAbs(source: *const real_t, destination: *real_t) void {
    _ = decNumberCopyAbs(destination, source);
}
extern fn decNumberCopyAbs(res: *real_t, source: *const real_t) *real_t;
// realMinus(operand, res, ctxt) => decNumberMinus(res, operand, ctxt)
inline fn realMinus(operand: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberMinus(res, operand, ctxt);
}

// Cross-domain WP34S / trig / hyperbolic helpers.

extern fn allocC47Blocks(sizeInBlocks: usize) ?*anyopaque;
extern fn freeC47Blocks(ptr: ?*anyopaque, sizeInBlocks: usize) void;
extern fn monitorExit(loop: *i32, str: [*:0]const u8) bool;

const REAL_SIZE_IN_BLOCKS_75: usize = 15;

// ===========================================================================
// fnBesselJ
// ===========================================================================
// Error surface: the Bessel command cores return a domain
// error instead of calling displayCalcErrorMessage inline; the shims map it and
// run the trailing adjustResult, which the C runs on every path except the
// saveLastX early-abort.
const BesselError = error{ BesselJNegArg, BesselYNegArg };

fn reportBesselError(e: BesselError) void {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE);
    switch (e) {
        error.BesselJNegArg => moreInfoOnError("In function fnBesselJ:", "negative argument for Bessel function of non-integer degree", null, null),
        error.BesselYNegArg => moreInfoOnError("In function fnBesselY:", "negative argument for Bessel function", null, null),
    }
}

fn fnBesselJCore() BesselError!void {
    var x: real_t = undefined;
    var n: real_t = undefined;
    var res: cplx_t = undefined;

    if (!saveLastX()) return;

    if (getRegisterAsReal(REGISTER_X, &x) and getRegisterAsReal(REGISTER_Y, &n)) {
        if (realIsAnInteger(&n) or (!realIsNegative(&x))) {
            WP34S_BesselJ(&n, &x, &res.Real, &runtime.ctxtReal75);
            reallocateRegister(REGISTER_X, dtReal34, 0, @intCast(amNone));
            convertRealToReal34ResultRegister(&res.Real, REGISTER_X);
        } else if (getSystemFlag(FLAG_CPXRES)) { // Real -> Complex
            realSetPositiveSign(&x);
            WP34S_BesselJ(&n, &x, res.mag(), &runtime.ctxtReal75);
            WP34S_Mod(&n, const_2(), res.arg(), &runtime.ctxtReal75);
            realMultiply(res.arg(), const75_pi(), res.arg(), &runtime.ctxtReal75);
            realPolarToRectangular(res.mag(), res.arg(), &res, &runtime.ctxtReal75);
            reallocateRegister(REGISTER_X, dtComplex34, 0, @intCast(amNone));
            convertComplexToResultRegister(&res, REGISTER_X);
        } else {
            return error.BesselJNegArg;
        }
    }

    adjustResult(REGISTER_X, true, true, REGISTER_X, REGISTER_Y, -1);
}

pub export fn fnBesselJ(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    if (comptime !runtime.option_bessel) return;
    _ = unusedButMandatoryParameter;
    fnBesselJCore() catch |e| {
        reportBesselError(e);
        adjustResult(REGISTER_X, true, true, REGISTER_X, REGISTER_Y, -1);
    };
}

// ===========================================================================
// fnBesselY
// ===========================================================================
fn fnBesselYCore() BesselError!void {
    var x: real_t = undefined;
    var n: real_t = undefined;
    var b: real_t = undefined;
    var c: real_t = undefined;
    var res: cplx_t = undefined;

    if (!saveLastX()) return;

    if (getRegisterAsReal(REGISTER_X, &x) and getRegisterAsReal(REGISTER_Y, &n)) {
        if (!realIsNegative(&x)) {
            WP34S_BesselY(&n, &x, &res.Real, &runtime.ctxtReal75);
            reallocateRegister(REGISTER_X, dtReal34, 0, @intCast(amNone));
            convertRealToReal34ResultRegister(&res.Real, REGISTER_X);
        } else if (getSystemFlag(FLAG_CPXRES)) { // Real -> Complex
            realSetPositiveSign(&x);
            WP34S_BesselY(&n, &x, res.mag(), &runtime.ctxtReal75);
            WP34S_Mod(&n, const_2(), res.arg(), &runtime.ctxtReal75);
            realMultiply(res.arg(), const75_pi(), &b, &runtime.ctxtReal75);
            realMinus(&b, res.arg(), &runtime.ctxtReal75); // the argument is -b
            realPolarToRectangular(res.mag(), res.arg(), &res, &runtime.ctxtReal75);

            runtime.C47_WP34S_Cvt2RadSinCosTan(&b, amRadian, null, &b, null, &runtime.ctxtReal75);
            WP34S_BesselJ(&n, &x, &c, &runtime.ctxtReal75);
            realMultiply(&b, &c, &b, &runtime.ctxtReal75);
            realAdd(&b, &b, &b, &runtime.ctxtReal75);
            realAdd(&res.Imag, &b, &res.Imag, &runtime.ctxtReal75);

            reallocateRegister(REGISTER_X, dtComplex34, 0, @intCast(amNone));
            convertComplexToResultRegister(&res, REGISTER_X);
        } else {
            return error.BesselYNegArg;
        }
    }

    adjustResult(REGISTER_X, true, true, REGISTER_X, REGISTER_Y, -1);
}

pub export fn fnBesselY(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    if (comptime !runtime.option_bessel) return;
    _ = unusedButMandatoryParameter;
    fnBesselYCore() catch |e| {
        reportBesselError(e);
        adjustResult(REGISTER_X, true, true, REGISTER_X, REGISTER_Y, -1);
    };
}

// Hankel's asymptotic expansion (Abramowitz and Stegun, p.364)
fn bessel_asymptotic_large_x(alpha: *const real_t, x: *const real_t, is_y: bool, res: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var p: real_t = undefined;
    var q: real_t = undefined;
    var pp: real_t = undefined;
    var qq: real_t = undefined;
    var chi: real_t = undefined;
    var sChi: real_t = undefined;
    var cChi: real_t = undefined;
    var mu: real_t = undefined;
    var z8: real_t = undefined;
    var k21: real_t = undefined;
    var k21sq: real_t = undefined;
    var nm: real_t = undefined;
    var tmp: real_t = undefined;
    var k: i32 = undefined;

    realMultiply(alpha, const_2(), &chi, realContext);
    realAdd(&chi, const_1(), &chi, realContext);
    realMultiply(&chi, const75_piOn4(), &chi, realContext);
    runtime.mod2Pi(x, &tmp, realContext);
    realSubtract(&tmp, &chi, &tmp, realContext);
    runtime.mod2Pi(&tmp, &chi, realContext);

    if (is_y) {
        math_wp34s.C47_WP34S_SinCosTanTaylor(&chi, false, &cChi, &sChi, null, realContext);
    } else {
        math_wp34s.C47_WP34S_SinCosTanTaylor(&chi, false, &sChi, &cChi, null, realContext);
    }

    realMultiply(alpha, alpha, &mu, realContext);
    realMultiply(&mu, const_4(), &mu, realContext);

    realSetOne(&p);
    realSubtract(&mu, const_1(), &q, realContext);
    realMultiply(x, const_8(), &z8, realContext);
    realDivide(&q, &z8, &q, realContext);
    realSetOne(&k21);
    realCopy(&q, &nm);
    realSetOne(&qq);
    k = 2;
    while (k < 1000) : (k += 1) {
        var loop: i32 = k;
        if (monitorExit(&loop, "Iter: ")) {
            break;
        }

        if (@rem(k, 2) == 0) {
            realCopy(&p, &pp);
        } else {
            realCopy(&q, &qq);
        }

        realAdd(&k21, const_2(), &k21, realContext);
        realMultiply(&k21, &k21, &k21sq, realContext);
        realSubtract(&mu, &k21sq, &k21sq, realContext);
        int32ToReal(k, &tmp);
        realMultiply(&tmp, &z8, &tmp, realContext);
        // The series is asymptotic. Once (2k - 1)^2 exceeds mu, the ratio
        // |mu - (2k - 1)^2| / (z8 k) of a term to the one before it rises with k, so
        // the first term larger than the one before it comes right after the
        // smallest term, and the sum diverges from there.
        if (realIsNegative(&k21sq) and math_comparison_reals.realCompareAbsGreaterThan(&k21sq, &tmp)) {
            break;
        }
        realMultiply(&nm, &k21sq, &nm, realContext);
        realDivide(&nm, &tmp, &nm, realContext);

        if (@rem(k, 4) < 2) {
            const dst: *real_t = if (@rem(k, 2) != 0) &q else &p;
            realAdd(dst, &nm, dst, realContext);
        } else {
            const dst: *real_t = if (@rem(k, 2) != 0) &q else &p;
            realSubtract(dst, &nm, dst, realContext);
        }

        realSetOne(&tmp);
        tmp.exponent -= 73;
        if (runtime.WP34S_RelativeError(&p, &pp, &tmp, realContext) and runtime.WP34S_RelativeError(&q, &qq, &tmp, realContext)) {
            break;
        }
    }

    realMultiply(&p, &cChi, &p, realContext);
    realMultiply(&q, &sChi, &q, realContext);
    if (is_y) {
        realAdd(&p, &q, &p, realContext);
    } else {
        realSubtract(&p, &q, &p, realContext);
    }

    realDivide(const_2(), const75_pi(), &q, realContext);
    realDivide(&q, x, &q, realContext);
    realSquareRoot(&q, &q, realContext);
    realMultiply(&p, &q, res, realContext);
}

const NUMBER_OF_COEFF: u32 = 100;

// Polynomial U[k] (Abramowitz and Stegun, p.366)
fn u_k(k: u32, coeff: [*]real_t, t: *const cplx_t, res: *cplx_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var t_n: cplx_t = undefined;
    var tmp: cplx_t = undefined;
    var i: u32 = undefined;

    realCopy(&t.Real, &t_n.Real);
    realCopy(&t.Imag, &t_n.Imag);
    realSetZero(&res.Real);
    realSetZero(&res.Imag);
    i = 1;
    while (i < k) : (i += 1) {
        runtime.mulComplexComplex(&t_n, t, &t_n, realContext);
    }
    i = 0;
    while (i < NUMBER_OF_COEFF) : (i += 1) {
        if (realIsZero(&coeff[i])) {
            break;
        }
        realCopy(&coeff[i], &tmp.Real);
        realSetZero(&tmp.Imag);
        runtime.mulComplexComplex(&tmp, &t_n, &tmp, realContext);
        realAdd(&res.Real, &tmp.Real, &res.Real, realContext);
        realAdd(&res.Imag, &tmp.Imag, &res.Imag, realContext);
        runtime.mulComplexComplex(&t_n, t, &t_n, realContext);
        runtime.mulComplexComplex(&t_n, t, &t_n, realContext);
    }
}

fn Sigma_u_k(nu: *const real_t, t: *const cplx_t, odd: i32, even: i32, res: *cplx_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var coeff_current: [*]real_t = undefined;
    var coeff_deriv: [*]real_t = undefined;
    var coeff_next: [*]real_t = undefined;
    var coeff_tmpptr: [*]real_t = undefined;
    var nu_k: cplx_t = undefined;
    var tmp: cplx_t = undefined;
    var prev_r: real_t = undefined;
    var prev_i: real_t = undefined;
    var coeff: real_t = undefined;
    var i: u32 = undefined;
    var j: u32 = undefined;

    const blocks = NUMBER_OF_COEFF * REAL_SIZE_IN_BLOCKS_75;

    if (allocC47Blocks(blocks)) |cc| {
        coeff_current = @ptrCast(@alignCast(cc));
        if (allocC47Blocks(blocks)) |cd| {
            coeff_deriv = @ptrCast(@alignCast(cd));
            if (allocC47Blocks(blocks)) |cn| {
                coeff_next = @ptrCast(@alignCast(cn));
                realSetZero(&prev_r);
                realSetZero(&prev_i);
                realCopy(if (even != 0) const_1() else const_0(), &res.Real);
                realSetZero(&res.Imag);
                realCopy(nu, &nu_k.Real);
                realSetZero(&nu_k.Imag);

                realDivide(const_3(), const_24(), &coeff_current[0], realContext);
                realDivide(const_5(), const_24(), &coeff_current[1], realContext);
                realChangeSign(&coeff_current[1]);
                i = 2;
                while (i < NUMBER_OF_COEFF) : (i += 1) {
                    realSetZero(&coeff_current[i]);
                }

                i = 0;
                while (i < NUMBER_OF_COEFF) : (i += 1) {
                    realSetZero(&coeff_deriv[i]);
                    realSetZero(&coeff_next[i]);
                }

                i = 1;
                while (i < NUMBER_OF_COEFF) : (i += 1) {
                    if (((i % 2 == 1) and odd != 0) or ((i % 2 == 0) and even != 0)) {
                        u_k(i, coeff_current, t, &tmp, realContext);
                        runtime.divComplexComplex(&tmp, &nu_k, &tmp, realContext);
                        if ((!realIsSpecial(&tmp.Real)) and !realIsSpecial(&tmp.Imag)) {
                            int32ToReal(if (i % 2 == 1) odd else even, &coeff);
                            realMultiply(&tmp.Real, &coeff, &tmp.Real, realContext);
                            realMultiply(&tmp.Imag, &coeff, &tmp.Imag, realContext);
                            realAdd(&res.Real, &tmp.Real, &res.Real, realContext);
                            realAdd(&res.Imag, &tmp.Imag, &res.Imag, realContext);
                        }
                        realSetOne(&tmp.Real);
                        tmp.Real.exponent -= 73;
                        if (runtime.WP34S_RelativeError(&res.Real, &prev_r, &tmp.Real, realContext) and runtime.WP34S_RelativeError(&res.Imag, &prev_i, &tmp.Real, realContext)) {
                            break;
                        }
                        realCopy(&res.Real, &prev_r);
                        realCopy(&res.Imag, &prev_i);
                    }

                    // for the next iteration
                    realMultiply(&nu_k.Real, nu, &nu_k.Real, realContext);

                    j = 0;
                    while (j < NUMBER_OF_COEFF) : (j += 1) { // coefficients of the derivative
                        int32ToReal(@intCast(i + j * 2), &tmp.Real);
                        realMultiply(&coeff_current[j], &tmp.Real, &coeff_deriv[j], realContext);
                        if (realIsZero(&coeff_deriv[j])) {
                            break;
                        }
                    }
                    j = 0;
                    while (j < NUMBER_OF_COEFF) : (j += 1) { // x^2
                        realCopy(&coeff_deriv[j], &coeff_next[j]);
                        if (realIsZero(&coeff_deriv[j])) {
                            break;
                        }
                    }
                    j = 1;
                    while (j < NUMBER_OF_COEFF) : (j += 1) { // -x^4
                        realSubtract(&coeff_next[j], &coeff_deriv[j - 1], &coeff_next[j], realContext);
                        if (realIsZero(&coeff_deriv[j - 1])) {
                            break;
                        }
                    }
                    j = 0;
                    while (j < NUMBER_OF_COEFF) : (j += 1) { // /2
                        realMultiply(&coeff_next[j], const_1on2(), &coeff_next[j], realContext);
                        if (realIsZero(&coeff_next[j])) {
                            break;
                        }
                    }

                    j = 0;
                    while (j < NUMBER_OF_COEFF) : (j += 1) { // 5x
                        realMultiply(&coeff_current[j], const_5(), &coeff_deriv[j], realContext);
                        if (realIsZero(&coeff_deriv[j])) {
                            break;
                        }
                    }
                    j = 1;
                    while (j < NUMBER_OF_COEFF) : (j += 1) { // (1-5t^2)x
                        realSubtract(&coeff_current[j], &coeff_deriv[j - 1], &coeff_current[j], realContext);
                        if (realIsZero(&coeff_deriv[j - 1])) {
                            break;
                        }
                    }
                    j = 0;
                    while (j < NUMBER_OF_COEFF) : (j += 1) { // integrate
                        int32ToReal(@intCast(i + j * 2 + 1), &tmp.Real);
                        realDivide(&coeff_current[j], &tmp.Real, &coeff_deriv[j], realContext);
                        if (realIsZero(&coeff_deriv[j])) {
                            break;
                        }
                    }
                    j = 0;
                    while (j < NUMBER_OF_COEFF) : (j += 1) { // 1/8
                        realDivide(&coeff_deriv[j], const_8(), &tmp.Real, realContext);
                        realAdd(&coeff_next[j], &tmp.Real, &coeff_next[j], realContext);
                        if (realIsZero(&coeff_deriv[j])) {
                            break;
                        }
                    }

                    coeff_tmpptr = coeff_current;
                    coeff_current = coeff_next;
                    coeff_next = coeff_tmpptr;
                }
                freeC47Blocks(coeff_next, blocks);
            } else {
                displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE);
            }
            freeC47Blocks(coeff_deriv, blocks);
        } else {
            displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE);
        }
        freeC47Blocks(coeff_current, blocks);
    } else {
        displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE);
    }
    return;
}

// Debye's asymptotic expansion (Abramowitz and Stegun, p.366). Its terms shrink
// to about exp(-2 nu xi) before they grow again, with xi = alpha - tanh(alpha)
// here and tan(beta) - beta in the trigonometric form. Below nu xi = 45 the
// smallest term is above 1E-39, and both forms return false and leave res unset.
fn bessel_asymptotic_large_order_hyp(nu: *const real_t, x: *const real_t, is_y: bool, res: *real_t, realContext: *realContext_t) linksection(runtime.code_section) bool {
    var alpha: real_t = undefined;
    var tanh_alpha: real_t = undefined;
    var coefficient: real_t = undefined;
    var tmp: real_t = undefined;
    var itrval: cplx_t = undefined;
    var t: cplx_t = undefined;

    // nu * sech(alpha) = nu / cosh(alpha) = x
    realDivide(nu, x, &alpha, realContext);
    math_inverse_trig_command.realArcosh(&alpha, &alpha, realContext);

    // coefficient numerator
    runtime.WP34S_Tanh(&alpha, &tanh_alpha, realContext);
    realSubtract(&tanh_alpha, &alpha, &coefficient, realContext);
    if (is_y) {
        realChangeSign(&coefficient);
    }
    realMultiply(nu, &coefficient, &coefficient, realContext);
    if (math_comparison_reals.realCompareAbsLessThan(&coefficient, const_45())) {
        return false;
    }
    math_command_wrappers.realExp(&coefficient, &coefficient, realContext);
    if (is_y) {
        realChangeSign(&coefficient);
    }

    // coefficient denominator
    realMultiply(if (is_y) const75_piOn2() else const75_2pi(), nu, &tmp, realContext);
    realMultiply(&tmp, &tanh_alpha, &tmp, realContext);
    realSquareRoot(&tmp, &tmp, realContext);
    realDivide(&coefficient, &tmp, &coefficient, realContext);

    realDivide(const_1(), &tanh_alpha, &t.Real, realContext);
    realSetZero(&t.Imag);
    Sigma_u_k(nu, &t, if (is_y) -1 else 1, 1, &itrval, realContext);
    realMultiply(&coefficient, &itrval.Real, res, realContext);
    return true;
}

fn bessel_asymptotic_large_order_trig(nu: *const real_t, x: *const real_t, is_y: bool, res: *real_t, realContext: *realContext_t) linksection(runtime.code_section) bool {
    var beta: real_t = undefined;
    var sin_beta: real_t = undefined;
    var cos_beta: real_t = undefined;
    var tan_beta: real_t = undefined;
    var coefficient: real_t = undefined;
    var psi: real_t = undefined;
    var sin_psi: real_t = undefined;
    var cos_psi: real_t = undefined;
    var t: cplx_t = undefined;
    var l: cplx_t = undefined;
    var m: cplx_t = undefined;

    // nu * sec(beta) = nu / cos(beta) = x
    realDivide(nu, x, &cos_beta, realContext);
    runtime.C47_WP34S_Acos(&cos_beta, &beta, realContext);

    realMultiply(&cos_beta, &cos_beta, &sin_beta, realContext); // cos²β
    realSubtract(const_1(), &sin_beta, &sin_beta, realContext); // sin²β
    realSquareRoot(&sin_beta, &sin_beta, realContext); // sinβ
    realDivide(&sin_beta, &cos_beta, &tan_beta, realContext); // tanβ

    // coefficient
    realDivide(const_2(), const75_pi(), &coefficient, realContext);
    realDivide(&coefficient, nu, &coefficient, realContext);
    realDivide(&coefficient, &tan_beta, &coefficient, realContext);
    realSquareRoot(&coefficient, &coefficient, realContext);

    // psi = nu * (tan(beta) - beta) - pi/4
    realSubtract(&tan_beta, &beta, &psi, realContext);
    realMultiply(&psi, nu, &psi, realContext);
    if (realCompareLessThan(&psi, const_45())) {
        return false;
    }
    realSubtract(&psi, const75_piOn4(), &psi, realContext);
    runtime.mod2Pi(&psi, &psi, realContext);
    if (is_y) {
        math_wp34s.C47_WP34S_SinCosTanTaylor(&psi, false, &cos_psi, &sin_psi, null, realContext);
    } else {
        math_wp34s.C47_WP34S_SinCosTanTaylor(&psi, false, &sin_psi, &cos_psi, null, realContext);
    }

    realSetZero(&t.Real);
    realDivide(const_1(), &tan_beta, &t.Imag, realContext); // t = i.cot(beta)
    Sigma_u_k(nu, &t, 0, 1, &l, realContext);
    Sigma_u_k(nu, &t, 1, 0, &m, realContext);
    realCopy(const__1(), &t.Imag); // t = -i
    runtime.mulComplexComplex(&m, &t, &m, realContext);
    // l.Imag == m.Imag == 0 ?

    realMultiply(&l.Real, &cos_psi, &l.Real, realContext);
    realMultiply(&m.Real, &sin_psi, &m.Real, realContext);
    if (is_y) {
        realChangeSign(&m.Real);
    }
    realAdd(&l.Real, &m.Real, res, realContext);
    realMultiply(res, &coefficient, res, realContext);
    return true;
}

// Recurrence relations (Abramowitz and Stegun, p.361)
fn plusMinus(subtracting: bool, a: *const real_t, b: *const real_t, res: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    if (subtracting) {
        realSubtract(a, b, res, realContext);
    } else {
        realAdd(a, b, res, realContext);
    }
}

fn bessel_recur(nu: *const real_t, x: *const real_t, is_y: bool, descending: bool, res: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var jnx: real_t = undefined;
    var jn_1x: real_t = undefined;
    var alpha: real_t = undefined;
    var floor_nu: real_t = undefined;
    var loop: i32 = 0;

    realToIntegralValue(nu, &floor_nu, DEC_ROUND_FLOOR, realContext);
    plusMinus(!descending, nu, &floor_nu, &alpha, realContext);
    if (is_y) {
        WP34S_BesselY(&alpha, x, &jn_1x, realContext);
    } else {
        WP34S_BesselJ(&alpha, x, &jn_1x, realContext);
    }
    plusMinus(descending, &alpha, const_1(), &alpha, realContext);
    if (is_y) {
        WP34S_BesselY(&alpha, x, &jnx, realContext);
    } else {
        WP34S_BesselJ(&alpha, x, &jnx, realContext);
    }
    while (realCompareLessThan(if (descending) nu else @as(*const real_t, &alpha), if (descending) @as(*const real_t, &alpha) else nu)) {
        realMultiply(const_2(), &alpha, res, realContext);
        realDivide(res, x, res, realContext);
        realMultiply(res, &jnx, res, realContext);
        realSubtract(res, &jn_1x, res, realContext);

        plusMinus(descending, &alpha, const_1(), &alpha, realContext);
        realCopy(&jnx, &jn_1x);
        realCopy(res, &jnx);

        if (monitorExit(&loop, "Iter: ")) {
            displayCalcErrorMessage(ERROR_SOLVER_ABORT, ERR_REGISTER_LINE);
            return;
        }
    }
}

// Digamma function (integer arguments only)
fn digamma(x: *const real_t, res: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    if (realIsAnInteger(x) and math_comparison_reals.realCompareGreaterThan(x, const_0())) {
        var a: real_t = undefined;
        var ar: real_t = undefined;
        realMinus(const75_egamma(), res, realContext);
        realSetOne(&a);
        while (realCompareLessThan(&a, x)) {
            realDivide(const_1(), &a, &ar, realContext);
            realAdd(res, &ar, res, realContext);
            realAdd(&a, const_1(), &a, realContext);
        }
    } else {
        realSetNaN(res);
    }
}

// Ported from the WP 34s repository (never implemented there)
fn bessel(alpha: *const real_t, x: *const real_t, neg: bool, res: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var q: real_t = undefined;
    var r: real_t = undefined;
    var m: real_t = undefined;
    var x2on4: real_t = undefined;
    var term: real_t = undefined;
    var gfac: real_t = undefined;
    var n: i16 = undefined;

    realMultiply(x, const_1on2(), &q, realContext); // q = x/2
    realMultiply(&q, &q, &x2on4, realContext); // factor each time around
    realPower(&q, alpha, &r, realContext); // (x/2)^(2m+alpha)

    realAdd(alpha, const_1(), &gfac, realContext);
    runtime.WP34S_Gamma(&gfac, &q, realContext);
    realDivide(&r, &q, &term, realContext);
    realCopy(&term, res); // first term in series

    realSetZero(&m);

    n = 0;
    while (n < 1000) : (n += 1) {
        var loop: i32 = n;
        if (monitorExit(&loop, "Iter: ")) {
            break;
        }

        realMultiply(&term, &x2on4, &q, realContext);
        realAdd(&m, const_1(), &m, realContext); // m = m+1
        realDivide(&q, &m, &r, realContext);
        realDivide(&r, &gfac, &term, realContext);
        realAdd(&gfac, const_1(), &gfac, realContext);
        if (neg) {
            realChangeSign(&term);
        }
        realAdd(&term, res, &q, realContext);
        if (realCompareEqual(res, &q)) {
            return;
        }
        realCopy(&q, res);
    }
    realSetNaN(res);
    return;
}

// ===========================================================================
// WP34S_BesselJ / WP34S_BesselY
//
// Both live inside `#if defined(OPTION_BESSEL)`, so without the option the two
// C symbols do not exist and any caller is a link error. The exports are gated
// the same way rather than left as no-ops that would hand a caller back an
// unwritten res.
// ===========================================================================
comptime {
    if (runtime.option_bessel) {
        @export(&WP34S_BesselJ, .{ .name = "WP34S_BesselJ", .linkage = .strong });
        @export(&WP34S_BesselY, .{ .name = "WP34S_BesselY", .linkage = .strong });
    }
}

/// Copies the order alpha to a, without its sign for an integer order, and
/// returns whether alpha is an odd integer: J and Y of order -n are (-1)^n times
/// those of order n.
fn bessel_order(alpha: *const real_t, a: *real_t, realContext: *realContext_t) linksection(runtime.code_section) bool {
    var parity: real_t = undefined;

    realCopy(alpha, a);
    if (!realIsAnInteger(alpha)) {
        return false;
    }
    realSetPositiveSign(a);
    realDivideRemainder(alpha, const_2(), &parity, realContext);
    return !realIsZero(&parity);
}

/// The routes for an order a above 90, and for x above 90 and above 1.25 a:
/// Debye's expansions, the recurrence and Hankel's expansion. Returns false, with
/// res unset, where none of them applies and the caller takes its power series.
fn bessel_large(a: *const real_t, x: *const real_t, is_y: bool, res: *real_t, realContext: *realContext_t) linksection(runtime.code_section) bool {
    var beta: real_t = undefined;
    var gamma: real_t = undefined;

    realSubtract(const_1(), const_1on4(), &beta, realContext);
    realMultiply(a, &beta, &beta, realContext);
    realAdd(const_1(), const_1on4(), &gamma, realContext);
    realMultiply(a, &gamma, &gamma, realContext);
    if (math_comparison_reals.realCompareGreaterThan(a, const_90())) {
        var recur = true;

        if (math_comparison_reals.realCompareAbsLessThan(x, &beta)) {
            recur = !bessel_asymptotic_large_order_hyp(a, x, is_y, res, realContext);
        } else if (math_comparison_reals.realCompareAbsGreaterThan(x, &gamma)) {
            recur = !bessel_asymptotic_large_order_trig(a, x, is_y, res, realContext);
        }
        if (recur) {
            bessel_recur(a, x, is_y, !is_y and math_comparison_reals.realCompareAbsLessThan(x, a), res, realContext);
        }
        return true;
    }
    if (math_comparison_reals.realCompareAbsGreaterThan(x, const_90()) and math_comparison_reals.realCompareAbsGreaterThan(x, &gamma)) {
        bessel_asymptotic_large_x(a, x, is_y, res, realContext);
        return true;
    }
    return false;
}

fn WP34S_BesselJ(alpha: *const real_t, x_in: *const real_t, res: *real_t, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    var a: real_t = undefined;
    var absx: real_t = undefined;
    var x = x_in;

    if (realIsSpecial(alpha) or realIsNaN(x)) {
        realSetNaN(res);
        return;
    }
    if (realIsInfinite(x)) {
        realSetZero(res);
        return;
    }
    const odd = bessel_order(alpha, &a, realContext);
    var negate = odd and realIsNegative(alpha);
    if (realIsZero(x)) {
        if (realIsZero(alpha)) {
            realSetOne(res);
            return;
        }
        realSetZero(res);
        if (negate) {
            realChangeSign(res);
        }
        return;
    }
    if (realIsNegative(x) and realIsAnInteger(alpha)) {
        // J(n, -x) = (-1)^n J(n, x)
        negate = (negate != odd);
        realCopyAbs(x, &absx);
        x = &absx;
    }
    if (!bessel_large(&a, x, false, res, realContext)) {
        bessel(&a, x, true, res, realContext);
    }
    if (negate) {
        realChangeSign(res);
    }
}

// See A&S page 360 section 9.1.11
fn bessel2_int_series(n_in: *const real_t, x: *const real_t, res: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var factor: real_t = undefined;
    var xon2: real_t = undefined;
    var xon2n: real_t = undefined;
    var x2on4: real_t = undefined;
    var k: real_t = undefined;
    var npk: real_t = undefined;
    var t: real_t = undefined;
    var u: real_t = undefined;
    var v: real_t = undefined;
    var s: real_t = undefined;
    var p: real_t = undefined;
    var nf: real_t = undefined;
    var absn: real_t = undefined;
    var i: i32 = undefined;
    var in: i32 = undefined;
    var n_neg: i32 = undefined;
    var loop: i32 = 0;

    var n: *const real_t = n_in;

    realDivide(const__1(), const75_pi(), &factor, realContext);

    if (realIsNegative(n)) {
        realCopyAbs(n, &absn);
        n = &absn;
        n_neg = 1;
    } else {
        n_neg = 0;
    }
    in = realToInt32C47(n, null);

    realMultiply(x, const_1on2(), &xon2, realContext); // xon2 = x/2
    realPower(&xon2, n, &xon2n, realContext); // xon2n = (x/2)^n
    realMultiply(&xon2, &xon2, &x2on4, realContext); // x2on4 = +/- x^2/4

    if (in > 0) {
        realSubtract(n, const_1(), &v, realContext); // v = n-k-1 = n-1
        realSetZero(&k);
        runtime.WP34S_Gamma(n, &p, realContext); // p = (n-1)!
        realCopy(&p, &s);
        realMultiply(&p, n, &nf, realContext); // nf = n!  (for later)
        realSetOne(&u);
        i = 1;
        while (i < in) : (i += 1) {
            realDivide(&p, &v, &t, realContext);
            realSubtract(&v, const_1(), &v, realContext);
            realAdd(&k, const_1(), &k, realContext);
            realDivide(&t, &k, &t, realContext);
            realMultiply(&t, &x2on4, &p, realContext);
            realAdd(&s, &p, &s, realContext);
        }
        realMultiply(&s, &factor, &t, realContext);
        realDivide(&t, &xon2n, res, realContext);
    } else {
        realSetZero(res);
        realSetOne(&nf);
    }

    WP34S_BesselJ(n, x, &u, realContext);
    realDivide(&u, const75_piOn2(), &t, realContext);

    WP34S_Ln(&xon2, &u, realContext);
    realMultiply(&u, &t, &v, realContext);
    realAdd(res, &v, res, realContext);

    realChangeSign(&x2on4);
    realAdd(n, const_1(), &t, realContext); // t = n+1
    digamma(&t, &u, realContext); // u = Psi(n+1)
    realSubtract(&u, const75_egamma(), &v, realContext); // v = psi(k+1) + psi(n+k+1)
    realSetZero(&k);
    realCopy(n, &npk);
    realDivide(const_1(), &nf, &p, realContext); // p = (x^2/4)^k/(k!(n+k)!)
    realMultiply(&v, &p, &s, realContext);

    i = 0;
    while (i < 1000) : (i += 1) {
        realAdd(&k, const_1(), &k, realContext);
        realAdd(&npk, const_1(), &npk, realContext);
        realMultiply(&p, &x2on4, &t, realContext);
        realMultiply(&k, &npk, &u, realContext);
        realDivide(&t, &u, &p, realContext);

        realDivide(const_1(), &k, &t, realContext);
        realAdd(&v, &t, &u, realContext);
        realDivide(const_1(), &npk, &t, realContext);
        realAdd(&u, &t, &v, realContext);

        realMultiply(&v, &p, &t, realContext);
        realAdd(&t, &s, &u, realContext);
        if (realCompareEqual(&u, &s)) {
            break;
        }
        realCopy(&u, &s);

        if (monitorExit(&loop, "Iter: ")) {
            displayCalcErrorMessage(ERROR_SOLVER_ABORT, ERR_REGISTER_LINE);
            return;
        }
    }
    realMultiply(&s, &xon2n, &t, realContext);

    realDivide(&t, const75_pi(), &u, realContext);

    realSubtract(res, &u, res, realContext);
    if (n_neg != 0) {
        realChangeSign(res);
    }
}

fn WP34S_BesselY(alpha: *const real_t, x: *const real_t, res: *real_t, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    var a: real_t = undefined;
    var t: real_t = undefined;
    var u: real_t = undefined;
    var s: real_t = undefined;
    var c: real_t = undefined;

    if (realIsNaN(alpha) or realIsNaN(x)) {
        realSetNaN(res);
        return;
    }
    if (realIsInfinite(x)) {
        realSetZero(res);
        return;
    }
    const negate = bessel_order(alpha, &a, realContext) and realIsNegative(alpha);
    if (realIsZero(x)) {
        realSetMinusInfinity(res);
        if (negate) {
            realChangeSign(res);
        }
        return;
    } else if (realIsInfinite(alpha) or realIsNegative(x)) {
        realSetNaN(res);
        return;
    }
    if (!realIsAnInteger(&a)) {
        WP34S_Mod(&a, const_2(), &t, realContext);
        realMultiply(&t, const75_pi(), &t, realContext);
        runtime.C47_WP34S_Cvt2RadSinCosTan(&t, amRadian, &s, &c, null, realContext);
        WP34S_BesselJ(&a, x, &t, realContext);
        realMultiply(&t, &c, &u, realContext);
        realMinus(&a, &c, realContext); // c = -a
        WP34S_BesselJ(&c, x, &t, realContext);
        realSubtract(&u, &t, &c, realContext);
        realDivide(&c, &s, res, realContext);
    } else if (!bessel_large(&a, x, true, res, realContext)) {
        bessel2_int_series(&a, x, res, realContext);
    }
    if (negate) {
        realChangeSign(res);
    }
}

extern fn realSetMinusInfinity(value: *real_t) void;
