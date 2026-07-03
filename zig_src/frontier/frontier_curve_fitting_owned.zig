// SPDX-License-Identifier: GPL-3.0-only
const consts = abi.constants;
const const_1 = consts.const_1;
const const_2 = consts.const_2;
const const_0 = consts.const_0;
const const_1on2 = consts.const_1on2;
const const__4 = consts.const__4;
//
// Zig owner for src/c47/curveFitting.c: the L.R. / curve-fit engine.
// fnCurveFitting / fnCurveFitting_T / fnCurveFittingReset manage the
// lrSelection mask; fnProcessLR finds the best-fitting model and pushes the
// coefficients; processCurvefitSelection / processCurvefitSelectionAll
// compute r, smi, a0, a1, a2 for the 10 fitting models (the math owners
// extern both, plus lrChosen/lrSelection which stay defined in c47.c);
// yIsFnx / fnYIsFnx / xIsFny / fnXIsFny are the forecast functions (yIsFnx
// is also called by plotstat.c).
//
// Faithful, line-by-line port of the C. STATDEBUG / STAT_DISPLAY_ABCDEFG
// blocks are never defined for any z47 build and are omitted; the
// EXTRA_INFO_ON_CALC_ERROR printf hints are reproduced under the
// extra_info_on_calc_error build option. Not reachable from the testSuite
// (no L.R. regression test); verified by build/link on every target plus
// the boundary gates (and math_command_wrappers_parity for the externs the
// math owners consume).

const frontier_build_options = @import("frontier_build_options");
const extra_info: bool = frontier_build_options.extra_info_on_calc_error;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const DECNUMUNITS = 25;
const abi = @import("abi"); // L1 shared bindings (REPORT-23 §5)
const real_t = abi.Real;
const realContext_t = abi.RealContext;
const calcRegister_t = i16;
const angularMode_t = c_int;

// GMP mpz_struct (limb width == pointer width on every z47 target).
const mp_limb_t = usize;
const mpz_struct = extern struct {
    _mp_alloc: c_int,
    _mp_size: c_int,
    _mp_d: [*c]mp_limb_t,
};
extern fn @"__gmpz_init"(p: *mpz_struct) void;
extern fn @"__gmpz_clear"(p: *mpz_struct) void;
extern fn @"__gmpz_set_ui"(p: *mpz_struct, v: c_ulong) void;
const mpz_init = @"__gmpz_init";
const mpz_clear = @"__gmpz_clear";
const mpz_set_ui = @"__gmpz_set_ui";

comptime {
    if (@sizeOf(real_t) != 60) @compileError("real_t must be 60 bytes");
}

// ---------------------------------------------------------------------------
// Constants / enum values (verified against defines.h / plotstat.h)
// ---------------------------------------------------------------------------
const CF_LINEAR_FITTING: u16 = 1;
const CF_EXPONENTIAL_FITTING: u16 = 2;
const CF_LOGARITHMIC_FITTING: u16 = 4;
const CF_POWER_FITTING: u16 = 8;
const CF_ROOT_FITTING: u16 = 16;
const CF_HYPERBOLIC_FITTING: u16 = 32;
const CF_PARABOLIC_FITTING: u16 = 64;
const CF_CAUCHY_FITTING: u16 = 128;
const CF_GAUSS_FITTING: u16 = 256;
const CF_ORTHOGONAL_FITTING: u16 = 512;

const TI_LR: u8 = 41;
const TI_CALCX: u8 = 42;
const TI_CALCY: u8 = 43;
const TI_CALCX2: u8 = 44;
const TI_STATISTIC_LR: u8 = 45;
const TI_LR_A0: u8 = 124;
const TI_LR_A1: u8 = 125;
const TI_LR_A2: u8 = 126;

const ERROR_TOO_FEW_DATA: u8 = 15;

const REGISTER_X: calcRegister_t = 100;
const REGISTER_Z: calcRegister_t = 102;
const ERR_REGISTER_LINE: calcRegister_t = REGISTER_Z;

const FLAG_ASLIFT: c_uint = 0xc023;

const amNone: angularMode_t = 5;

const useREAL4: u8 = 4; // plotstat.h
const useREAL39: u8 = 39; // plotstat.h

// Statistical sums (defines.h).
const SUM_X = 1;
const SUM_Y = 2;
const SUM_X2 = 3;
const SUM_X2Y = 4;
const SUM_Y2 = 5;
const SUM_XY = 6;
const SUM_lnXlnY = 7;
const SUM_lnX = 8;
const SUM_ln2X = 9;
const SUM_YlnX = 10;
const SUM_lnY = 11;
const SUM_ln2Y = 12;
const SUM_XlnY = 13;
const SUM_X2lnY = 14;
const SUM_lnYonX = 15;
const SUM_X2onY = 16;
const SUM_1onX = 17;
const SUM_1onX2 = 18;
const SUM_XonY = 19;
const SUM_1onY = 20;
const SUM_1onY2 = 21;
const SUM_X3 = 22;
const SUM_X4 = 23;

// ---------------------------------------------------------------------------
// Constant blob (offsets from the generated constantPointers.h)
// ---------------------------------------------------------------------------
const constants = @extern([*]const u8, .{ .name = "constants" });
inline fn cstR(offset: u32) *align(1) const real_t {
    return @ptrCast(constants + offset);
}

// ---------------------------------------------------------------------------
// Globals
// ---------------------------------------------------------------------------
extern var lrSelection: u16;
extern var lrChosen: u16;
extern var temporaryInformation: u8;
extern var statisticalSumsPointer: ?[*]real_t;
extern var ctxtReal4: realContext_t;
extern var ctxtReal34: realContext_t;
extern var ctxtReal39: realContext_t;
extern var ctxtReal75: realContext_t;

// The C file's non-static context-pointer globals (kept exported with the
// same names and zero/undefined initial value as the C .bss definitions).
pub export var realContext: ?*realContext_t = null;
pub export var realContextForecast: ?*realContext_t = null;

// Curve fitting variables, available to the different functions (static in C).
var s_RR: real_t = undefined;
var s_RR2: real_t = undefined;
var s_RRMAX: real_t = undefined;
var s_SMI: real_t = undefined;
var s_aa0: real_t = undefined;
var s_aa1: real_t = undefined;
var s_aa2: real_t = undefined;

// ---------------------------------------------------------------------------
// Function externs
// ---------------------------------------------------------------------------
extern fn liftStack() void;
extern fn setSystemFlag(flag: c_uint) void;
extern fn displayCalcErrorMessage(error_code: u8, err_message_line: calcRegister_t, err_register_line: calcRegister_t) void;
const c_moreInfoOnError = @extern(*const fn (m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) callconv(.c) void, .{ .name = "moreInfoOnError" });
extern fn printf(fmt: [*:0]const u8, ...) c_int;
extern fn getCurveFitModeNames(selection: u16) [*c]const u8;
extern fn convertLongIntegerToLongIntegerRegister(longInteger: *const mpz_struct, regist: calcRegister_t) void;
extern fn convertRealToResultRegister(x: *align(1) const real_t, dest: calcRegister_t, angle: angularMode_t) void;
extern fn getRegisterAsReal(reg: calcRegister_t, val: *real_t) bool;
extern fn checkMinimumDataPoints(n: *align(1) const real_t) bool;
extern fn fnStatR(RR: *real_t, SXY: *real_t, SX: *real_t, SY: *real_t) void;
extern fn fnStatSMI(SMI: *real_t) void;
extern fn realToInt32C47(r: *align(1) const real_t, err: ?*bool) i32;
extern fn realSetZero(r: *real_t) void;
extern fn realExp(rhs: *align(1) const real_t, res: *real_t, set: *realContext_t) void;
extern fn realPower(base: *align(1) const real_t, exponent: *align(1) const real_t, result: *real_t, real_context: *realContext_t) void;
extern fn xthRootReal(yy: *real_t, xx: *real_t, real_context: *realContext_t) void;
extern fn WP34S_Ln(x: *align(1) const real_t, res: *real_t, realContext: *realContext_t) void;
extern fn realToFloat(vv: *const real_t, v: *f32) void;
extern fn realCompareGreaterThan(a: *align(1) const real_t, b: *align(1) const real_t) bool;
extern fn realCompareLessEqual(a: *align(1) const real_t, b: *align(1) const real_t) bool;

// libm (the double-precision forecast path).
extern fn exp(x: f64) f64;
extern fn log(x: f64) f64;
extern fn pow(x: f64, y: f64) f64;

// decNumber externs behind the real* macros.
extern fn decNumberAdd(r: *real_t, a: *align(1) const real_t, b: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberSubtract(r: *real_t, a: *align(1) const real_t, b: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberMultiply(r: *real_t, a: *align(1) const real_t, b: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberDivide(r: *real_t, a: *align(1) const real_t, b: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberSquareRoot(r: *real_t, a: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberCopy(r: *real_t, src: *align(1) const real_t) *real_t;
extern fn decNumberFromUInt32(r: *real_t, v: u32) *real_t;

// ---------------------------------------------------------------------------
// Inline wrappers (the C macros)
// ---------------------------------------------------------------------------
inline fn moreInfoOnError(m1: [*:0]const u8, m2: ?[*:0]const u8) void {
    if (comptime extra_info) c_moreInfoOnError(m1, m2, null, null);
}
inline fn sigma(sum: usize) *real_t {
    return &statisticalSumsPointer.?[sum];
}
inline fn realCopy(src: *align(1) const real_t, dst: *real_t) void {
    _ = decNumberCopy(dst, src);
}
inline fn realAdd(a: *align(1) const real_t, b: *align(1) const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberAdd(res, a, b, ctx);
}
inline fn realSubtract(a: *align(1) const real_t, b: *align(1) const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberSubtract(res, a, b, ctx);
}
inline fn realMultiply(a: *align(1) const real_t, b: *align(1) const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberMultiply(res, a, b, ctx);
}
inline fn realDivide(a: *align(1) const real_t, b: *align(1) const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberDivide(res, a, b, ctx);
}
inline fn realSquareRoot(operand: *align(1) const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberSquareRoot(res, operand, ctx);
}
inline fn realChangeSign(operand: *real_t) void {
    operand.bits ^= 0x80;
}
inline fn uInt32ToReal(source: u32, destination: *real_t) void {
    _ = decNumberFromUInt32(destination, source);
}
inline fn orOrtho(a: u16) u16 {
    return if (a == 0) CF_ORTHOGONAL_FITTING else a;
}

// ===========================================================================
// fnCurveFitting
// ===========================================================================
pub export fn fnCurveFitting(curveFitting_arg: u16) callconv(.c) void {
    var curveFitting = curveFitting_arg & 0x01FF;
    temporaryInformation = TI_STATISTIC_LR;

    if (curveFitting == 0) {
        curveFitting = 0x0200; // see above
    }

    lrSelection = curveFitting; // lrSelection stores the BestF method, in inverse: 1 = allowed method
    lrChosen = 0; // lrChosen indicates if there was a L.R. selection. Can be only one bit.

    if (comptime extra_info) {
        const numberOfOnes: u16 = lrCountOnes(curveFitting);
        if (numberOfOnes == 1) {
            _ = printf("Use the ");
        } else {
            _ = printf("Use the best fitting model out of\n");
        }
        _ = printf("%s", getCurveFitModeNames(curveFitting));
        if (numberOfOnes == 1) {
            _ = printf(" fitting model.\n");
        } else {
            _ = printf("\nfitting models.\n");
        }
    }
}

// ===========================================================================
// fnCurveFittingReset
// ===========================================================================
pub export fn fnCurveFittingReset(control: u16) callconv(.c) void {
    temporaryInformation = TI_STATISTIC_LR;
    if (control == 0) {
        lrSelection = CF_LINEAR_FITTING;
        lrChosen = 0;
    } else {
        lrSelection = CF_LINEAR_FITTING +
            CF_EXPONENTIAL_FITTING +
            CF_LOGARITHMIC_FITTING +
            CF_POWER_FITTING +
            CF_ROOT_FITTING +
            CF_HYPERBOLIC_FITTING +
            CF_PARABOLIC_FITTING +
            CF_CAUCHY_FITTING +
            CF_GAUSS_FITTING;
        lrChosen = 0;
    }
}

// ===========================================================================
// fnCurveFitting_T (toggle)
// ===========================================================================
pub export fn fnCurveFitting_T(curveFitting_arg: u16) callconv(.c) void {
    temporaryInformation = TI_STATISTIC_LR;
    var curveFitting = curveFitting_arg & 0x01FF; // clear ORTHO

    if (curveFitting == 0) {
        curveFitting = CF_ORTHOGONAL_FITTING;
    }

    if ((lrSelection & CF_ORTHOGONAL_FITTING) == CF_ORTHOGONAL_FITTING and curveFitting == CF_ORTHOGONAL_FITTING) { // if no curves selected (0) and Ortho is not chosen, then default to LIN
        lrSelection = CF_LINEAR_FITTING;
    } else if ((lrSelection & CF_ORTHOGONAL_FITTING) == 0 and curveFitting == CF_ORTHOGONAL_FITTING) { // if no curves selected (0) and Ortho is not chosen, then default to LIN
        lrSelection = CF_ORTHOGONAL_FITTING;
    } else if (lrCountOnes(curveFitting) == 1) { // toggle bits of the lrselection word
        lrSelection = (0x01FF & lrSelection) ^ curveFitting;
    } else {
        lrSelection = CF_LINEAR_FITTING;
    }

    lrChosen = 0;

    if (comptime extra_info) {
        const numberOfOnes: u16 = lrCountOnes(curveFitting);
        if (numberOfOnes == 1) {
            _ = printf("Use the ");
        } else {
            _ = printf("Use the best fitting model out of\n");
        }
        _ = printf("%s", getCurveFitModeNames(curveFitting));
        if (numberOfOnes == 1) {
            _ = printf(" fitting model.\n");
        } else {
            _ = printf("\nfitting models.\n");
        }
    }
}

// ===========================================================================
// fnCurveFittingLR
// ===========================================================================
pub export fn fnCurveFittingLR(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var lr: mpz_struct = undefined;
    liftStack();
    mpz_init(&lr);
    mpz_set_ui(&lr, lrSelection & 0x01FF); // Input mask 01 1111 1111 EXCLUDES 10 0000 0000, which is ORTHOF, as it is not in the OM
    convertLongIntegerToLongIntegerRegister(&lr, REGISTER_X);
    mpz_clear(&lr);
}

// ===========================================================================
// lrCountOnes / minLRDataPoints
// ===========================================================================
pub export fn lrCountOnes(curveFitting: u16) callconv(.c) u16 {
    return @popCount(curveFitting);
}

pub export fn minLRDataPoints(selection: u16) callconv(.c) u16 {
    if (selection > 1023) {
        return 65535;
    } else if (selection & 448 != 0) {
        return 3;
    } else if (selection & (63 + 512) != 0) {
        return 2;
    } else {
        return 65535; // if 0
    }
}

// ===========================================================================
// fnProcessLRfind (static) / fnProcessLR
// ===========================================================================
fn fnProcessLRfind(curveFitting: u16, resultType: u16) void {
    var NN: real_t = undefined;

    const nn: i32 = realToInt32C47(sigma(0), null);
    realSetZero(&s_aa0);
    realSetZero(&s_aa1);
    realSetZero(&s_aa2);
    if (comptime extra_info) {
        _ = printf("Processing for best fit: %s\n", getCurveFitModeNames(curveFitting));
    }
    realCopy(const__4(), &s_RRMAX);
    var s: u16 = 0; // default
    var jx: u16 = 0; // only a single graph can be evaluated at once, so retain the single lowest bit, and clear the higher order bits.
    var ix: u4 = 0;
    while (ix < 10) : (ix += 1) { // up to 2^9 inclusive of 512 which is ORTHOF. The ReM is respected by usage of 0 only, not by manual selection.
        jx = curveFitting & (@as(u16, 1) << ix);
        if (jx != 0) {
            if (comptime extra_info) {
                _ = printf("processCurvefitSelection curveFitting:%u sweep:%u %s\n", @as(c_uint, curveFitting), @as(c_uint, jx), getCurveFitModeNames(jx));
            }

            if (nn >= @as(i32, minLRDataPoints(jx))) {
                processCurvefitSelection(jx, &s_RR, &s_SMI, &s_aa0, &s_aa1, &s_aa2);
                realMultiply(&s_RR, &s_RR, &s_RR2, &ctxtReal39);

                if (realCompareGreaterThan(&s_RR2, &s_RRMAX) and realCompareLessEqual(&s_RR2, const_1())) { // Only consider L.R. models where R^2<=1
                    realCopy(&s_RR2, &s_RRMAX);
                    s = jx;
                }
            }
        }
    }
    if (lrCountOnes(s) > 1) {
        s = 0; // error condition, cannot have >1 solutions, do not do L.R.
    }

    if (comptime extra_info) {
        if (s != 0) {
            _ = printf("Found best fit: %u %s\n", @as(c_uint, s), getCurveFitModeNames(s));
        } else {
            _ = printf("Found no fit: %u\n", @as(c_uint, s));
        }
    }

    if (nn >= @as(i32, minLRDataPoints(s))) {
        processCurvefitSelection(s, &s_RR, &s_SMI, &s_aa0, &s_aa1, &s_aa2);
        lrChosen = s;

        // Set the TI
        if (resultType & (resultType -% 1) != 0) {
            temporaryInformation = TI_LR;
        } else if (resultType & 1 != 0) {
            temporaryInformation = TI_LR_A0;
        } else if (resultType & 2 != 0) {
            temporaryInformation = TI_LR_A1;
        } else if (resultType & 4 != 0) {
            temporaryInformation = TI_LR_A2;
        }

        if (s == CF_CAUCHY_FITTING or s == CF_GAUSS_FITTING or s == CF_PARABOLIC_FITTING) {
            if (resultType & 4 != 0) {
                liftStack();
                setSystemFlag(FLAG_ASLIFT);
                convertRealToResultRegister(&s_aa2, REGISTER_X, amNone);
            }
        } else if (resultType == 4) {
            liftStack();
            setSystemFlag(FLAG_ASLIFT);
            convertRealToResultRegister(const_0(), REGISTER_X, amNone);
        }
        if (resultType & 2 != 0) {
            liftStack();
            setSystemFlag(FLAG_ASLIFT);
            convertRealToResultRegister(&s_aa1, REGISTER_X, amNone);
        }
        if (resultType & 1 != 0) {
            liftStack();
            setSystemFlag(FLAG_ASLIFT);
            convertRealToResultRegister(&s_aa0, REGISTER_X, amNone);
        }
    } else {
        if (minLRDataPoints(s) == 65535) {
            displayCalcErrorMessage(ERROR_TOO_FEW_DATA, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnError("In function fnProcessLRfind:", "There is insufficient statistical data to do L.R., possibly due to data manipulation!");
        } else {
            uInt32ToReal(minLRDataPoints(s), &NN);
            _ = checkMinimumDataPoints(&NN); // Report an error
        }
    }
}

pub export fn fnProcessLR(resultType: u16) callconv(.c) void {
    if (checkMinimumDataPoints(const_2())) {
        fnProcessLRfind(lrSelection, resultType);
    }
}

// ===========================================================================
// calc_BCD / calc_AEFG (aux terms)
// ===========================================================================
pub export fn calc_BCD(BB: *real_t, CC: *real_t, DD: *real_t) callconv(.c) void {
    realContext = &ctxtReal75;
    const ctx = realContext.?;
    var SS: real_t = undefined;
    var TT: real_t = undefined;

    //        B = nn * sumx2y - sumx2 * sumy;
    realMultiply(sigma(0), sigma(SUM_X2Y), &SS, ctx);
    realMultiply(sigma(SUM_X2), sigma(SUM_Y), &TT, ctx);
    realSubtract(&SS, &TT, BB, ctx);

    //        C = nn * sumx3 - sumx2 * sumx;
    realMultiply(sigma(0), sigma(SUM_X3), &SS, ctx);
    realMultiply(sigma(SUM_X2), sigma(SUM_X), &TT, ctx);
    realSubtract(&SS, &TT, CC, ctx);

    //        D = nn * sumxy - sumx * sumy;
    realMultiply(sigma(0), sigma(SUM_XY), &SS, ctx);
    realMultiply(sigma(SUM_X), sigma(SUM_Y), &TT, ctx);
    realSubtract(&SS, &TT, DD, ctx);
}

pub export fn calc_AEFG(AA: *real_t, BB: *real_t, CC: *real_t, DD: *real_t, EE: *real_t, FF: *real_t, GG: *real_t) callconv(.c) void {
    realContext = &ctxtReal75;
    const ctx = realContext.?;
    var SS: real_t = undefined;
    var TT: real_t = undefined;
    var UU: real_t = undefined;

    //        A = nn * sumx2 - sumx * sumx;
    realMultiply(sigma(0), sigma(SUM_X2), &SS, ctx);
    realMultiply(sigma(SUM_X), sigma(SUM_X), &TT, ctx);
    realSubtract(&SS, &TT, AA, ctx);

    //        E = nn * sumx4 - sumx2 * sumx2;
    realMultiply(sigma(0), sigma(SUM_X4), &SS, ctx);
    realMultiply(sigma(SUM_X2), sigma(SUM_X2), &TT, ctx);
    realSubtract(&SS, &TT, EE, ctx);

    // USING COMPONENTS OF BCD
    //        F = (A*B - C*D) / (A*E - C*C);    //interchangably the a2 in PARABF
    realMultiply(AA, BB, &SS, ctx);
    realMultiply(CC, DD, &TT, ctx);
    realSubtract(&SS, &TT, &UU, ctx);
    realMultiply(AA, EE, &SS, ctx);
    realMultiply(CC, CC, &TT, ctx);
    realSubtract(&SS, &TT, &SS, ctx);
    realDivide(&UU, &SS, FF, ctx);

    //        G = (D - F * C) / A;
    realMultiply(FF, CC, &SS, ctx);
    realSubtract(DD, &SS, &SS, ctx);
    realDivide(&SS, AA, GG, ctx);
}

// ===========================================================================
// processCurvefitSelection / processCurvefitSelectionAll
// ===========================================================================
pub export fn processCurvefitSelection(selection: u16, RR_: *real_t, SMI_: *real_t, aa0: *real_t, aa1: *real_t, aa2: *real_t) callconv(.c) void {
    var MX: real_t = undefined;
    var MX2: real_t = undefined;
    var SX2: real_t = undefined;
    var SY2: real_t = undefined;
    processCurvefitSelectionAll(selection, RR_, &MX, &MX2, &SX2, &SY2, SMI_, aa0, aa1, aa2);
}

pub export fn processCurvefitSelectionAll(selection_arg: u16, RR_: *real_t, MX: *real_t, MX2: *real_t, SX2: *real_t, SY2: *real_t, SMI_: *real_t, aa0: *real_t, aa1: *real_t, aa2: *real_t) callconv(.c) void {
    var selection = selection_arg;
    var AA: real_t = undefined;
    var BB: real_t = undefined;
    var CC: real_t = undefined;
    var DD: real_t = undefined;
    var EE: real_t = undefined;
    var FF: real_t = undefined;
    var GG: real_t = undefined;
    var HH: real_t = undefined;
    var RR2: real_t = undefined;
    var SS: real_t = undefined;
    var TT: real_t = undefined;
    var UU: real_t = undefined;

    var jx: u16 = 0;
    var ix: u4 = 0;
    while (ix != 10) : (ix += 1) { // up to 2^9 inclusive of 512 which is ORTHOF.
        jx = selection & (@as(u16, 1) << ix);
        if (jx != 0) {
            break;
        }
    }
    selection = jx;

    realContext = &ctxtReal75; // Use 75 as the sums can reach high values and the accuracy of the regression depends on this.
    const ctx = realContext.?;
    var VV: real_t = undefined;
    var WW: real_t = undefined;
    var ZZ: real_t = undefined;
    var S_X: real_t = undefined;
    var S_Y: real_t = undefined;
    var S_XY: real_t = undefined;
    var M_X: real_t = undefined;
    var M_Y: real_t = undefined;
    realDivide(sigma(SUM_X), sigma(0), &M_X, ctx);
    realDivide(sigma(SUM_Y), sigma(0), &M_Y, ctx);
    fnStatR(RR_, &S_XY, &S_X, &S_Y);
    fnStatSMI(SMI_);

    realMultiply(&S_X, &S_X, SX2, ctx);
    realMultiply(&S_Y, &S_Y, SY2, ctx);
    realDivide(sigma(SUM_X), sigma(0), MX, ctx); // MX = SumX / N
    realMultiply(MX, MX, MX2, ctx); // MX2

    switch (orOrtho(selection)) {
        CF_LINEAR_FITTING => {
            //      a0 = (sumx2 * sumy  - sumx * sumxy) / (nn * sumx2 - sumx * sumx);
            realMultiply(sigma(SUM_X2), sigma(SUM_Y), &SS, ctx);
            realMultiply(sigma(SUM_X), sigma(SUM_XY), &TT, ctx);
            realSubtract(&SS, &TT, &SS, ctx);
            realMultiply(sigma(0), sigma(SUM_X2), &TT, ctx);
            realMultiply(sigma(SUM_X), sigma(SUM_X), &UU, ctx);
            realSubtract(&TT, &UU, &TT, ctx);
            realDivide(&SS, &TT, aa0, ctx);

            //      a1 = (nn  * sumxy - sumx * sumy ) / (nn * sumx2 - sumx * sumx);
            realMultiply(sigma(0), sigma(SUM_XY), &SS, ctx);
            realMultiply(sigma(SUM_X), sigma(SUM_Y), &TT, ctx);
            realSubtract(&SS, &TT, &SS, ctx);
            realMultiply(sigma(0), sigma(SUM_X2), &TT, ctx);
            realMultiply(sigma(SUM_X), sigma(SUM_X), &UU, ctx);
            realSubtract(&TT, &UU, &TT, ctx);
            realDivide(&SS, &TT, aa1, ctx);

            //       r  = (nn * sumxy - sumx * sumy) / (sqrt (nn * sumx2 - sumx * sumx) * sqrt(nn * sumy2 - sumy * sumy) );
            realMultiply(sigma(0), sigma(SUM_XY), &SS, ctx);
            realMultiply(sigma(SUM_X), sigma(SUM_Y), &TT, ctx);
            realSubtract(&SS, &TT, &SS, ctx); // SS is top

            realMultiply(sigma(0), sigma(SUM_X2), &TT, ctx);
            realMultiply(sigma(SUM_X), sigma(SUM_X), &UU, ctx);
            realSubtract(&TT, &UU, &TT, ctx);
            realSquareRoot(&TT, &TT, ctx); // TT is bottom, factor 1

            realMultiply(sigma(0), sigma(SUM_Y2), &UU, ctx);
            realMultiply(sigma(SUM_Y), sigma(SUM_Y), &VV, ctx);
            realSubtract(&UU, &VV, &UU, ctx);
            realSquareRoot(&UU, &UU, ctx); // UU is bottom factor 2

            realDivide(&SS, &TT, RR_, ctx);
            realDivide(RR_, &UU, RR_, ctx); // r
        },

        CF_EXPONENTIAL_FITTING => {
            //      a0 = exp( (sumx2 * sumlny  - sumx * sumxlny) / (nn * sumx2 - sumx * sumx) );
            realMultiply(sigma(SUM_X2), sigma(SUM_lnY), &SS, ctx);
            realMultiply(sigma(SUM_X), sigma(SUM_XlnY), &TT, ctx);
            realSubtract(&SS, &TT, &SS, ctx);
            realMultiply(sigma(0), sigma(SUM_X2), &TT, ctx);
            realMultiply(sigma(SUM_X), sigma(SUM_X), &UU, ctx);
            realSubtract(&TT, &UU, &TT, ctx);
            realDivide(&SS, &TT, aa0, ctx);
            realExp(aa0, aa0, ctx);

            // a1 = (nn  * sumxlny - sumx * sumlny ) / (nn * sumx2 - sumx * sumx);
            realMultiply(sigma(0), sigma(SUM_XlnY), &SS, ctx);
            realMultiply(sigma(SUM_X), sigma(SUM_lnY), &TT, ctx);
            realSubtract(&SS, &TT, &SS, ctx);
            realMultiply(sigma(0), sigma(SUM_X2), &TT, ctx);
            realMultiply(sigma(SUM_X), sigma(SUM_X), &UU, ctx);
            realSubtract(&TT, &UU, &TT, ctx);
            realDivide(&SS, &TT, aa1, ctx);

            //      r = (nn * sumxlny - sumx*sumlny) / (sqrt(nn*sumx2-sumx*sumx) * sqrt(nn*sumln2y-sumlny*sumlny)); //(rEXP)
            realMultiply(sigma(0), sigma(SUM_XlnY), &SS, ctx);
            realMultiply(sigma(SUM_X), sigma(SUM_lnY), &TT, ctx);
            realSubtract(&SS, &TT, &SS, ctx); // SS is top

            realMultiply(sigma(0), sigma(SUM_X2), &TT, ctx);
            realMultiply(sigma(SUM_X), sigma(SUM_X), &UU, ctx);
            realSubtract(&TT, &UU, &TT, ctx);
            realSquareRoot(&TT, &TT, ctx); // TT is bottom, factor 1

            realMultiply(sigma(0), sigma(SUM_ln2Y), &UU, ctx);
            realMultiply(sigma(SUM_lnY), sigma(SUM_lnY), &VV, ctx);
            realSubtract(&UU, &VV, &ZZ, ctx);
            realSquareRoot(&ZZ, &VV, ctx); // UU is bottom factor 2

            realDivide(&SS, &TT, RR_, ctx);
            realDivide(RR_, &VV, RR_, ctx); // r

            realSubtract(sigma(0), const_1(), &SS, ctx); // Section for s(a)
            realMultiply(sigma(0), &SS, &SS, ctx);
            realDivide(const_1(), &SS, &SS, ctx);
            realMultiply(&SS, &ZZ, SY2, ctx);
        },

        CF_LOGARITHMIC_FITTING => {
            //      a0 = (sumln2x * sumy  - sumlnx * sumylnx) / (nn * sumln2x - sumlnx * sumlnx);
            realMultiply(sigma(SUM_ln2X), sigma(SUM_Y), &SS, ctx);
            realMultiply(sigma(SUM_lnX), sigma(SUM_YlnX), &TT, ctx);
            realSubtract(&SS, &TT, &SS, ctx);
            realMultiply(sigma(0), sigma(SUM_ln2X), &TT, ctx);
            realMultiply(sigma(SUM_lnX), sigma(SUM_lnX), &UU, ctx);
            realSubtract(&TT, &UU, &TT, ctx);
            realDivide(&SS, &TT, aa0, ctx);

            // a1 = (nn  * sumylnx - sumlnx * sumy ) / (nn * sumln2x - sumlnx * sumlnx);
            realMultiply(sigma(0), sigma(SUM_YlnX), &SS, ctx);
            realMultiply(sigma(SUM_lnX), sigma(SUM_Y), &TT, ctx);
            realSubtract(&SS, &TT, &SS, ctx);
            realMultiply(sigma(0), sigma(SUM_ln2X), &TT, ctx);
            realMultiply(sigma(SUM_lnX), sigma(SUM_lnX), &UU, ctx);
            realSubtract(&TT, &UU, &TT, ctx);
            realDivide(&SS, &TT, aa1, ctx);

            //      r = (nn * sumylnx - sumlnx*sumy) / (sqrt(nn*sumln2x-sumlnx*sumlnx) * sqrt(nn*sumy2-sumy*sumy)); //(rLOG)
            realMultiply(sigma(0), sigma(SUM_YlnX), &SS, ctx);
            realMultiply(sigma(SUM_lnX), sigma(SUM_Y), &TT, ctx);
            realSubtract(&SS, &TT, &SS, ctx); // SS is top

            realMultiply(sigma(0), sigma(SUM_ln2X), &TT, ctx);
            realMultiply(sigma(SUM_lnX), sigma(SUM_lnX), &UU, ctx);
            realSubtract(&TT, &UU, &WW, ctx);
            realSquareRoot(&WW, &TT, ctx); // TT is bottom, factor 1

            realMultiply(sigma(0), sigma(SUM_Y2), &UU, ctx);
            realMultiply(sigma(SUM_Y), sigma(SUM_Y), &VV, ctx);
            realSubtract(&UU, &VV, &UU, ctx);
            realSquareRoot(&UU, &UU, ctx); // UU is bottom factor 2

            realDivide(&SS, &TT, RR_, ctx);
            realDivide(RR_, &UU, RR_, ctx); // r

            realSubtract(sigma(0), const_1(), &SS, ctx); // Section for s(a)
            realMultiply(sigma(0), &SS, &SS, ctx);
            realDivide(const_1(), &SS, &SS, ctx);
            realMultiply(&SS, &WW, SX2, ctx);
            realDivide(sigma(SUM_lnX), sigma(0), MX, ctx);
            realMultiply(MX, MX, MX2, ctx);
        },

        CF_POWER_FITTING => {
            //      a0 = exp( (sumln2x * sumlny  - sumlnx * sumlnxlny) / (nn * sumln2x - sumlnx * sumlnx)  );
            realMultiply(sigma(SUM_ln2X), sigma(SUM_lnY), &SS, ctx);
            realMultiply(sigma(SUM_lnX), sigma(SUM_lnXlnY), &TT, ctx);
            realSubtract(&SS, &TT, &SS, ctx);
            realMultiply(sigma(0), sigma(SUM_ln2X), &TT, ctx);
            realMultiply(sigma(SUM_lnX), sigma(SUM_lnX), &UU, ctx);
            realSubtract(&TT, &UU, &TT, ctx);
            realDivide(&SS, &TT, aa0, ctx);
            realExp(aa0, aa0, ctx);

            // a1 = (nn  * sumlnxlny - sumlnx * sumlny ) / (nn * sumln2x - sumlnx * sumlnx);
            realMultiply(sigma(0), sigma(SUM_lnXlnY), &SS, ctx);
            realMultiply(sigma(SUM_lnX), sigma(SUM_lnY), &TT, ctx);
            realSubtract(&SS, &TT, &SS, ctx);
            realMultiply(sigma(0), sigma(SUM_ln2X), &TT, ctx);
            realMultiply(sigma(SUM_lnX), sigma(SUM_lnX), &UU, ctx);
            realSubtract(&TT, &UU, &TT, ctx);
            realDivide(&SS, &TT, aa1, ctx);

            //      r = (nn * sumlnxlny - sumlnx*sumlny) / (sqrt(nn*sumln2x-sumlnx*sumlnx) * sqrt(nn*sumln2y-sumlny*sumlny)); //(rEXP)
            realMultiply(sigma(0), sigma(SUM_lnXlnY), &SS, ctx);
            realMultiply(sigma(SUM_lnX), sigma(SUM_lnY), &TT, ctx);
            realSubtract(&SS, &TT, &SS, ctx); // SS is top

            realMultiply(sigma(0), sigma(SUM_ln2X), &TT, ctx);
            realMultiply(sigma(SUM_lnX), sigma(SUM_lnX), &UU, ctx);
            realSubtract(&TT, &UU, &WW, ctx);
            realSquareRoot(&WW, &TT, ctx); // TT is bottom, factor 1

            realMultiply(sigma(0), sigma(SUM_ln2Y), &UU, ctx);
            realMultiply(sigma(SUM_lnY), sigma(SUM_lnY), &VV, ctx);
            realSubtract(&UU, &VV, &ZZ, ctx);
            realSquareRoot(&ZZ, &UU, ctx); // UU is bottom factor 2

            realDivide(&SS, &TT, RR_, ctx);
            realDivide(RR_, &UU, RR_, ctx); // r

            realSubtract(sigma(0), const_1(), &SS, ctx); // Section for s(a)
            realMultiply(sigma(0), &SS, &SS, ctx);
            realDivide(const_1(), &SS, &SS, ctx);
            realMultiply(&SS, &WW, SX2, ctx);
            realDivide(sigma(SUM_lnX), sigma(0), MX, ctx);
            realMultiply(MX, MX, MX2, ctx);

            realSubtract(sigma(0), const_1(), &SS, ctx); // Section for s(a)
            realMultiply(sigma(0), &SS, &SS, ctx);
            realDivide(const_1(), &SS, &SS, ctx);
            realMultiply(&SS, &ZZ, SY2, ctx);
        },

        CF_ROOT_FITTING => {
            //      A = nn * sum1onx2 - sum1onx * sum1onx;
            //      B = 1.0/A * (sum1onx2 * sumlny - sum1onx * sumlnyonx);
            //      C = 1.0/A * (nn * sumlnyonx - sum1onx * sumlny);
            realMultiply(sigma(0), sigma(SUM_1onX2), &SS, ctx);
            realMultiply(sigma(SUM_1onX), sigma(SUM_1onX), &AA, ctx);
            realSubtract(&SS, &AA, &AA, ctx); // err fixed

            realDivide(const_1(), &AA, &SS, ctx); // err fixed
            realMultiply(sigma(SUM_1onX2), sigma(SUM_lnY), &TT, ctx);
            realMultiply(sigma(SUM_1onX), sigma(SUM_lnYonX), &UU, ctx);
            realSubtract(&TT, &UU, &TT, ctx);
            realMultiply(&SS, &TT, &BB, ctx);

            realMultiply(sigma(0), sigma(SUM_lnYonX), &TT, ctx);
            realMultiply(sigma(SUM_1onX), sigma(SUM_lnY), &UU, ctx);
            realSubtract(&TT, &UU, &TT, ctx);
            realMultiply(&SS, &TT, &CC, ctx); // err due to SS above

            //      a0 = exp (B);
            realExp(&BB, aa0, ctx);

            //      a1 = exp (C);
            realExp(&CC, aa1, ctx);

            //     r = sqrt ( (B * sumlny + C * sumlnyonx - 1.0/nn * sumlny * sumlny) / (sumln2y - 1.0/nn * sumlny * sumlny) ); //(rROOT)
            realMultiply(&BB, sigma(SUM_lnY), &SS, ctx);
            realMultiply(&CC, sigma(SUM_lnYonX), &TT, ctx);
            realAdd(&SS, &TT, &SS, ctx); // t1+t2
            realDivide(const_1(), sigma(0), &TT, ctx);
            realMultiply(&TT, sigma(SUM_lnY), &TT, ctx);
            realMultiply(&TT, sigma(SUM_lnY), &TT, ctx); // t3
            realSubtract(&SS, &TT, &SS, ctx); // t1+t2-t3

            realSubtract(sigma(SUM_ln2Y), &TT, &TT, ctx);
            realDivide(&SS, &TT, &RR2, ctx);
            realSquareRoot(&RR2, RR_, ctx);
        },

        CF_HYPERBOLIC_FITTING => {
            //      a0 = (sumx2 * sum1ony - sumx * sumxony) / (nn*sumx2 - sumx * sumx);
            realMultiply(sigma(SUM_X2), sigma(SUM_1onY), &SS, ctx);
            realMultiply(sigma(SUM_X), sigma(SUM_XonY), &TT, ctx);
            realSubtract(&SS, &TT, &SS, ctx);
            realMultiply(sigma(0), sigma(SUM_X2), &TT, ctx);
            realMultiply(sigma(SUM_X), sigma(SUM_X), &UU, ctx);
            realSubtract(&TT, &UU, &TT, ctx);
            realDivide(&SS, &TT, aa0, ctx);

            //     a1 = (nn * sumxony - sumx * sum1ony) / (nn * sumx2 - sumx * sumx);
            realMultiply(sigma(0), sigma(SUM_XonY), &SS, ctx);
            realMultiply(sigma(SUM_X), sigma(SUM_1onY), &TT, ctx);
            realSubtract(&SS, &TT, &SS, ctx);
            realMultiply(sigma(0), sigma(SUM_X2), &TT, ctx);
            realMultiply(sigma(SUM_X), sigma(SUM_X), &UU, ctx);
            realSubtract(&TT, &UU, &TT, ctx);
            realDivide(&SS, &TT, aa1, ctx);

            //     r = sqrt ( (a0 * sum1ony + a1 * sumxony - 1.0/nn * sum1ony * sum1ony) / (sum1ony2 - 1.0/nn * sum1ony * sum1ony ) ); //(rHYP)
            realMultiply(aa0, sigma(SUM_1onY), &SS, ctx);
            realMultiply(aa1, sigma(SUM_XonY), &TT, ctx);
            realAdd(&SS, &TT, &SS, ctx); // ss=t1+t2
            realDivide(const_1(), sigma(0), &TT, ctx);
            realMultiply(&TT, sigma(SUM_1onY), &TT, ctx);
            realMultiply(&TT, sigma(SUM_1onY), &TT, ctx); // tt=t3
            realSubtract(&SS, &TT, &SS, ctx); // t1+t2-t3
            realSubtract(sigma(SUM_1onY2), &TT, &UU, ctx); // use t3
            realDivide(&SS, &UU, &RR2, ctx);
            realSquareRoot(&RR2, RR_, ctx);
        },

        CF_PARABOLIC_FITTING => {
            calc_BCD(&BB, &CC, &DD);
            calc_AEFG(&AA, &BB, &CC, &DD, &EE, &FF, &GG);

            //      a2 = F;
            realCopy(&FF, aa2);

            //      a1 = G;
            realCopy(&GG, aa1);

            //      a0 = 1.0/nn * (sumy - a2 * sumx2 - a1 * sumx);
            realMultiply(&FF, sigma(SUM_X2), &TT, ctx);
            realSubtract(sigma(SUM_Y), &TT, &HH, ctx);
            realMultiply(&GG, sigma(SUM_X), &TT, ctx);
            realSubtract(&HH, &TT, &HH, ctx);
            realDivide(&HH, sigma(0), aa0, ctx);

            //      r = sqrt( (a0 * sumy + a1 * sumxy + a2 * sumx2y - 1.0/nn * sumy * sumy) / (sumy2 - 1.0/nn * sumy * sumy) );
            realMultiply(aa0, sigma(SUM_Y), &SS, ctx);
            realMultiply(aa1, sigma(SUM_XY), &TT, ctx);
            realAdd(&SS, &TT, &SS, ctx);
            realMultiply(aa2, sigma(SUM_X2Y), &TT, ctx);
            realAdd(&SS, &TT, &SS, ctx); // interim in SS
            realMultiply(sigma(SUM_Y), sigma(SUM_Y), &TT, ctx);
            realDivide(&TT, sigma(0), &UU, ctx);
            realSubtract(&SS, &UU, &SS, ctx); // top in SS
            realSubtract(sigma(SUM_Y2), &UU, &TT, ctx);
            realDivide(&SS, &TT, &RR2, ctx); // R^2
            realSquareRoot(&RR2, RR_, ctx);
        },

        CF_GAUSS_FITTING => {
            //        B = n.sumx2lny - sumx2 . sumlny
            realMultiply(sigma(0), sigma(SUM_X2lnY), &SS, ctx);
            realMultiply(sigma(SUM_X2), sigma(SUM_lnY), &TT, ctx);
            realSubtract(&SS, &TT, &BB, ctx);

            //        C = nn * sumx3 - sumx2 * sumx;              //Copy from parabola
            realMultiply(sigma(0), sigma(SUM_X3), &SS, ctx);
            realMultiply(sigma(SUM_X2), sigma(SUM_X), &TT, ctx);
            realSubtract(&SS, &TT, &CC, ctx);

            //        D = n.sumxlny - sumx . sumlny
            realMultiply(sigma(0), sigma(SUM_XlnY), &SS, ctx);
            realMultiply(sigma(SUM_X), sigma(SUM_lnY), &TT, ctx);
            realSubtract(&SS, &TT, &DD, ctx);

            calc_AEFG(&AA, &BB, &CC, &DD, &EE, &FF, &GG);

            //        H = (1.0)/nn * (sumlny - F * sumx2 - G * sumx);
            realMultiply(&FF, sigma(SUM_X2), &TT, ctx);
            realSubtract(sigma(SUM_lnY), &TT, &HH, ctx);
            realMultiply(&GG, sigma(SUM_X), &TT, ctx);
            realSubtract(&HH, &TT, &HH, ctx);
            realDivide(&HH, sigma(0), &HH, ctx);

            //        a2 = (1.0)/F;
            realDivide(const_1(), &FF, aa2, ctx);

            //        a1 = -G/(2.0) * a2;
            realMultiply(&GG, const_1on2(), &TT, ctx);
            realChangeSign(&TT);
            realMultiply(&TT, aa2, aa1, ctx);

            // GAUSS  a0 = exp (H - F * a1 * a1); //maxy;
            realMultiply(aa1, aa1, &SS, ctx);
            realMultiply(&SS, &FF, &SS, ctx);
            realSubtract(&HH, &SS, aa0, ctx);
            realExp(aa0, aa0, ctx);

            //        r  = sqrt ( ( H * sumlny + G * sumxlny + F * sumx2lny - 1.0/nn * sumlny * sumlny ) / (sumln2y - 1.0/nn * sumlny * sumlny) );
            realMultiply(&HH, sigma(SUM_lnY), &SS, ctx);
            realMultiply(&GG, sigma(SUM_XlnY), &TT, ctx);
            realAdd(&SS, &TT, &SS, ctx);
            realMultiply(&FF, sigma(SUM_X2lnY), &TT, ctx);
            realAdd(&SS, &TT, &SS, ctx); // interim in SS
            realMultiply(sigma(SUM_lnY), sigma(SUM_lnY), &TT, ctx);
            realDivide(&TT, sigma(0), &UU, ctx);
            realSubtract(&SS, &UU, &SS, ctx); // top in SS

            realSubtract(sigma(SUM_ln2Y), &UU, &TT, ctx); // use UU from above
            realDivide(&SS, &TT, &RR2, ctx); // R^2
            realSquareRoot(&RR2, RR_, ctx);
        },

        CF_CAUCHY_FITTING => {
            //      B = nn * sumx2ony - sumx2 * sum1ony;
            realMultiply(sigma(0), sigma(SUM_X2onY), &SS, ctx);
            realMultiply(sigma(SUM_X2), sigma(SUM_1onY), &TT, ctx);
            realSubtract(&SS, &TT, &BB, ctx);

            //      C = nn * sumx3 - sumx * sumx2;                     //vv C copied from PARABF. Exactly the same
            realMultiply(sigma(0), sigma(SUM_X3), &SS, ctx);
            realMultiply(sigma(SUM_X2), sigma(SUM_X), &TT, ctx);
            realSubtract(&SS, &TT, &CC, ctx);

            //      D = nn * sumxony - sumx * sum1ony;
            realMultiply(sigma(0), sigma(SUM_XonY), &SS, ctx);
            realMultiply(sigma(SUM_X), sigma(SUM_1onY), &TT, ctx);
            realSubtract(&SS, &TT, &DD, ctx);

            calc_AEFG(&AA, &BB, &CC, &DD, &EE, &FF, &GG);

            //    H = 1.0/nn * (sum1ony - F * sumx2 - G * sumx);
            realMultiply(&FF, sigma(SUM_X2), &TT, ctx);
            realSubtract(sigma(SUM_1onY), &TT, &HH, ctx);
            realMultiply(&GG, sigma(SUM_X), &TT, ctx);
            realSubtract(&HH, &TT, &HH, ctx);
            realDivide(&HH, sigma(0), &HH, ctx);

            //        a0 = F;
            realCopy(&FF, aa0);

            //        a1 = G/2.0 * a0;
            realDivide(&GG, const_2(), &TT, ctx);
            realDivide(&TT, aa0, aa1, ctx); // err

            //      a2 = H - F * a1 * a1;
            realMultiply(aa1, aa1, &SS, ctx);
            realMultiply(&SS, &FF, &SS, ctx);
            realSubtract(&HH, &SS, aa2, ctx);

            //    r  = sqrt ( (H * sum1ony + G * sumxony + F * sumx2ony - 1.0/nn * sum1ony * sum1ony) / (sum1ony2 - 1.0/nn * sum1ony * sum1ony) );
            realMultiply(&HH, sigma(SUM_1onY), &SS, ctx);
            realMultiply(&GG, sigma(SUM_XonY), &TT, ctx);
            realAdd(&SS, &TT, &SS, ctx);
            realMultiply(&FF, sigma(SUM_X2onY), &TT, ctx);
            realAdd(&SS, &TT, &SS, ctx); // interim in SS
            realMultiply(sigma(SUM_1onY), sigma(SUM_1onY), &TT, ctx);
            realDivide(&TT, sigma(0), &UU, ctx);
            realSubtract(&SS, &UU, &SS, ctx); // top in SS

            realSubtract(sigma(SUM_1onY2), &UU, &TT, ctx); // use UU from above
            realDivide(&SS, &TT, &RR2, ctx); // R^2
            realSquareRoot(&RR2, RR_, ctx);
        },

        CF_ORTHOGONAL_FITTING => {
            // a1 = 1.0 / (2.0 * sxy) * ( sy * sy - sx * sx + sqrt( (sy * sy - sx * sx) * (sy * sy - sx * sx) + 4 * sxy * sxy) );
            // a0  = y_ - a1 * x_;
            realMultiply(&S_Y, &S_Y, &SS, ctx);
            realMultiply(&S_X, &S_X, &TT, ctx);
            realSubtract(&SS, &TT, &UU, ctx); // keep  uu = sy2-sx2
            realMultiply(&UU, &UU, &VV, ctx);
            realMultiply(&S_XY, &S_XY, &WW, ctx);
            realMultiply(&WW, const_2(), &WW, ctx);
            realMultiply(&WW, const_2(), &WW, ctx);
            realAdd(&WW, &VV, &VV, ctx);
            realSquareRoot(&VV, &VV, ctx); // sqrt term

            realMultiply(&UU, const_1on2(), &UU, ctx); // term1
            realDivide(&UU, &S_XY, &UU, ctx);

            realMultiply(&VV, const_1on2(), &VV, ctx); // term2
            realDivide(&VV, &S_XY, &VV, ctx);

            realAdd(&UU, &VV, aa1, ctx); // a1
            realMultiply(aa1, &M_X, &SS, ctx);
            realSubtract(&M_Y, &SS, aa0, ctx); // a0

            // r is copied from LINF
            //       r  = (nn * sumxy - sumx * sumy) / (sqrt (nn * sumx2 - sumx * sumx) * sqrt(nn * sumy2 - sumy * sumy) );
            realMultiply(sigma(0), sigma(SUM_XY), &SS, ctx);
            realMultiply(sigma(SUM_X), sigma(SUM_Y), &TT, ctx);
            realSubtract(&SS, &TT, &SS, ctx); // SS is top

            realMultiply(sigma(0), sigma(SUM_X2), &TT, ctx);
            realMultiply(sigma(SUM_X), sigma(SUM_X), &UU, ctx);
            realSubtract(&TT, &UU, &TT, ctx);
            realSquareRoot(&TT, &TT, ctx); // TT is bottom, factor 1

            realMultiply(sigma(0), sigma(SUM_Y2), &UU, ctx);
            realMultiply(sigma(SUM_Y), sigma(SUM_Y), &VV, ctx);
            realSubtract(&UU, &VV, &UU, ctx);
            realSquareRoot(&UU, &UU, ctx); // UU is bottom factor 2

            realDivide(&SS, &TT, RR_, ctx);
            realDivide(RR_, &UU, RR_, ctx); // r
        },

        else => {},
    }
}

// ===========================================================================
// yIsFnx
// ===========================================================================
pub export fn yIsFnx(USEFLOAT: u8, selection: u16, x: f64, y: *f64, a0: f64, a1: f64, a2: f64, XX: *real_t, YY: *real_t, RR: *real_t, SMI: *real_t, aa0: *real_t, aa1: *real_t, aa2: *real_t) callconv(.c) void {
    _ = RR;
    _ = SMI;
    y.* = 0;
    var yf: f32 = undefined;
    var SS: real_t = undefined;
    var TT: real_t = undefined;
    var UU: real_t = undefined;

    realSetZero(YY);
    if (USEFLOAT == useREAL4) {
        realContextForecast = &ctxtReal4;
    } else {
        if (USEFLOAT == useREAL39) {
            realContextForecast = &ctxtReal39;
        }
    }
    switch (orOrtho(selection)) {
        CF_LINEAR_FITTING, CF_ORTHOGONAL_FITTING => {
            if (USEFLOAT == 0) {
                y.* = a1 * x + a0;
            } else {
                realMultiply(XX, aa1, &UU, realContextForecast.?);
                realAdd(&UU, aa0, YY, realContextForecast.?);
                realToFloat(YY, &yf);
                y.* = @floatCast(yf);
            }
        },
        CF_EXPONENTIAL_FITTING => {
            if (USEFLOAT == 0) {
                y.* = a0 * exp(a1 * x);
            } else {
                realMultiply(XX, aa1, &UU, realContextForecast.?);
                realExp(&UU, &UU, realContextForecast.?);
                realMultiply(&UU, aa0, YY, realContextForecast.?);
                realToFloat(YY, &yf);
                y.* = @floatCast(yf);
            }
        },
        CF_LOGARITHMIC_FITTING => {
            if (USEFLOAT == 0) {
                y.* = a0 + a1 * log(x);
            } else {
                WP34S_Ln(XX, &SS, realContextForecast.?);
                realMultiply(&SS, aa1, &UU, realContextForecast.?);
                realAdd(&UU, aa0, YY, realContextForecast.?);
                realToFloat(YY, &yf);
                y.* = @floatCast(yf);
            }
        },
        CF_POWER_FITTING => {
            if (USEFLOAT == 0) {
                y.* = a0 * pow(x, a1);
            } else {
                realPower(XX, aa1, &SS, realContextForecast.?);
                realMultiply(&SS, aa0, YY, realContextForecast.?);
                realToFloat(YY, &yf);
                y.* = @floatCast(yf);
            }
        },
        CF_ROOT_FITTING => {
            if (USEFLOAT == 0) {
                y.* = a0 * pow(a1, 1 / x);
            } else {
                realDivide(const_1(), XX, &SS, realContextForecast.?);
                realPower(aa1, &SS, &SS, realContextForecast.?); // very very slow with a1=0.9982, probably in the 0.4 < x < 1.0 area
                realMultiply(&SS, aa0, YY, realContextForecast.?);
                realToFloat(YY, &yf);
                y.* = @floatCast(yf);
            }
        },
        CF_HYPERBOLIC_FITTING => {
            if (USEFLOAT == 0) {
                y.* = 1 / (a1 * x + a0);
            } else {
                realMultiply(XX, aa1, &UU, realContextForecast.?);
                realAdd(&UU, aa0, &TT, realContextForecast.?);
                realDivide(const_1(), &TT, YY, realContextForecast.?);
                realToFloat(YY, &yf);
                y.* = @floatCast(yf);
            }
        },
        CF_PARABOLIC_FITTING => {
            if (USEFLOAT == 0) {
                y.* = a2 * x * x + a1 * x + a0;
            } else {
                realMultiply(XX, XX, &TT, realContextForecast.?);
                realMultiply(&TT, aa2, &TT, realContextForecast.?);
                realMultiply(XX, aa1, &UU, realContextForecast.?);
                realAdd(&TT, &UU, &TT, realContextForecast.?);
                realAdd(&TT, aa0, YY, realContextForecast.?);
                realToFloat(YY, &yf);
                y.* = @floatCast(yf);
            }
        },
        CF_GAUSS_FITTING => {
            if (USEFLOAT == 0) {
                y.* = a0 * exp((x - a1) * (x - a1) / a2);
            } else {
                realSubtract(XX, aa1, &TT, realContextForecast.?);
                realMultiply(&TT, &TT, &TT, realContextForecast.?);
                realDivide(&TT, aa2, &TT, realContextForecast.?);
                realExp(&TT, &TT, realContextForecast.?);
                realMultiply(&TT, aa0, YY, realContextForecast.?);
                realToFloat(YY, &yf);
                y.* = @floatCast(yf);
            }
        },
        CF_CAUCHY_FITTING => {
            if (USEFLOAT == 0) {
                y.* = 1 / (a0 * (x + a1) * (x + a1) + a2);
            } else {
                realAdd(XX, aa1, &TT, realContextForecast.?);
                realMultiply(&TT, &TT, &TT, realContextForecast.?);
                realMultiply(&TT, aa0, &TT, realContextForecast.?);
                realAdd(&TT, aa2, &TT, realContextForecast.?);
                realDivide(const_1(), &TT, YY, realContextForecast.?);
                realToFloat(YY, &yf);
                y.* = @floatCast(yf);
            }
            // C falls through into the (empty) default here.
        },
        else => {},
    }
}

// ===========================================================================
// fnYIsFnx
// ===========================================================================
pub export fn fnYIsFnx(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var XX: real_t = undefined;
    var YY: real_t = undefined;
    var RR: real_t = undefined;
    var SMI: real_t = undefined;
    var aa0: real_t = undefined;
    var aa1: real_t = undefined;
    var aa2: real_t = undefined;
    const x: f64 = -99;
    var y: f64 = 0;
    const a0: f64 = -99;
    const a1: f64 = -99;
    const a2: f64 = -99;

    if (!getRegisterAsReal(REGISTER_X, &XX)) {
        return;
    }

    realSetZero(&aa0);
    realSetZero(&aa1);
    realSetZero(&aa2);
    if (checkMinimumDataPoints(const_2())) {
        if (lrChosen == 0) { // if lrChosen contains something, the stat data exists, otherwise set it to linear.
            lrChosen = CF_LINEAR_FITTING;
        }
        processCurvefitSelection(lrChosen, &RR, &SMI, &aa0, &aa1, &aa2);

        yIsFnx(useREAL39, lrChosen, x, &y, a0, a1, a2, &XX, &YY, &RR, &SMI, &aa0, &aa1, &aa2);
        convertRealToResultRegister(&YY, REGISTER_X, amNone);

        setSystemFlag(FLAG_ASLIFT);
        temporaryInformation = TI_CALCY;
    }
}

// ===========================================================================
// xIsFny
// ===========================================================================
pub export fn xIsFny(selection: u16, rootNo: u8, XX: *real_t, YY: *real_t, RR: *real_t, SMI: *real_t, aa0: *real_t, aa1: *real_t, aa2: *real_t) callconv(.c) void {
    _ = RR;
    _ = SMI;
    var SS: real_t = undefined;
    var TT: real_t = undefined;
    var UU: real_t = undefined;

    realSetZero(XX);
    realContextForecast = &ctxtReal39;
    switch (orOrtho(selection)) {
        CF_LINEAR_FITTING, CF_ORTHOGONAL_FITTING => {
            // x = (y - a0) / a1;
            realSubtract(YY, aa0, &UU, realContextForecast.?);
            realDivide(&UU, aa1, &TT, realContextForecast.?);
            realCopy(&TT, XX);
            temporaryInformation = TI_CALCX;
        },
        CF_EXPONENTIAL_FITTING => {
            realDivide(YY, aa0, &UU, realContextForecast.?);
            WP34S_Ln(&UU, &UU, realContextForecast.?);
            realDivide(&UU, aa1, XX, realContextForecast.?);
            temporaryInformation = TI_CALCX;
        },
        CF_LOGARITHMIC_FITTING => {
            realSubtract(YY, aa0, &UU, realContextForecast.?);
            realDivide(&UU, aa1, &UU, realContextForecast.?);
            realExp(&UU, XX, realContextForecast.?);
            temporaryInformation = TI_CALCX;
        },
        CF_POWER_FITTING => {
            realDivide(YY, aa0, &UU, realContextForecast.?);
            xthRootReal(&UU, aa1, realContextForecast.?); // Note X-register gets written here
            if (!getRegisterAsReal(REGISTER_X, XX)) {
                return;
            }
            temporaryInformation = TI_CALCX;
        },
        CF_ROOT_FITTING => {
            WP34S_Ln(YY, YY, realContextForecast.?);
            WP34S_Ln(aa0, &UU, realContextForecast.?);
            realSubtract(YY, &UU, YY, realContextForecast.?);
            WP34S_Ln(aa1, &UU, realContextForecast.?);
            realDivide(&UU, YY, XX, realContextForecast.?);
            temporaryInformation = TI_CALCX;
        },
        CF_HYPERBOLIC_FITTING => {
            realDivide(const_1(), YY, &UU, realContextForecast.?);
            realSubtract(&UU, aa0, &UU, realContextForecast.?);
            realDivide(&UU, aa1, XX, realContextForecast.?);
            temporaryInformation = TI_CALCX;
        },
        CF_PARABOLIC_FITTING => {
            // (1/(2.a2)) . ( -a1 +- sqrt(a1.a1 - 4a2.(a0 - y) ) )
            realSubtract(YY, aa0, &UU, realContextForecast.?);
            realMultiply(const_2(), &UU, &UU, realContextForecast.?);
            realMultiply(const_2(), &UU, &UU, realContextForecast.?);
            realMultiply(aa2, &UU, &UU, realContextForecast.?);
            realMultiply(aa1, aa1, &TT, realContextForecast.?);
            realAdd(&UU, &TT, &UU, realContextForecast.?); // swapped terms around minus, therefore add
            realSquareRoot(&UU, &UU, realContextForecast.?);

            realSubtract(const_0(), aa1, &SS, realContextForecast.?);
            if (rootNo == 1) {
                realSubtract(&SS, &UU, &SS, realContextForecast.?); // This term could be Add due to plus and minus
            }
            if (rootNo == 2) {
                realAdd(&SS, &UU, &SS, realContextForecast.?); // This term could be Add due to plus and minus
            }

            realMultiply(&SS, const_1on2(), &SS, realContextForecast.?);
            realDivide(&SS, aa2, XX, realContextForecast.?);
            temporaryInformation = TI_CALCX2;
        },
        CF_CAUCHY_FITTING => {
            realDivide(const_1(), YY, &UU, realContextForecast.?);
            realSubtract(&UU, aa2, &UU, realContextForecast.?);
            realDivide(&UU, aa0, &UU, realContextForecast.?);
            realSquareRoot(&UU, &UU, realContextForecast.?);
            realSubtract(const_0(), aa1, &SS, realContextForecast.?);
            if (rootNo == 1) {
                realSubtract(&SS, &UU, XX, realContextForecast.?);
            }
            if (rootNo == 2) {
                realAdd(&SS, &UU, XX, realContextForecast.?);
            }
            temporaryInformation = TI_CALCX2;
        },
        CF_GAUSS_FITTING => {
            realDivide(YY, aa0, &UU, realContextForecast.?);
            WP34S_Ln(&UU, &UU, realContextForecast.?);
            realMultiply(&UU, aa2, &UU, realContextForecast.?);
            realSquareRoot(&UU, &UU, realContextForecast.?);
            if (rootNo == 1) {
                realSubtract(aa1, &UU, XX, realContextForecast.?);
            }
            if (rootNo == 2) {
                realAdd(aa1, &UU, XX, realContextForecast.?);
            }
            temporaryInformation = TI_CALCX2;
        },
        else => {},
    }
}

// ===========================================================================
// fnXIsFny
// ===========================================================================
pub export fn fnXIsFny(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var XX: real_t = undefined;
    var YY: real_t = undefined;
    var RR: real_t = undefined;
    var SMI: real_t = undefined;
    var aa0: real_t = undefined;
    var aa1: real_t = undefined;
    var aa2: real_t = undefined;

    if (!getRegisterAsReal(REGISTER_X, &YY)) {
        return;
    }

    realSetZero(&aa0);
    realSetZero(&aa1);
    realSetZero(&aa2);
    if (checkMinimumDataPoints(const_2())) {
        if (lrChosen == 0) { // if lrChosen contains something, the stat data exists, otherwise set it to linear.
            lrChosen = CF_LINEAR_FITTING;
        }
        processCurvefitSelection(lrChosen, &RR, &SMI, &aa0, &aa1, &aa2);

        xIsFny(lrChosen, 1, &XX, &YY, &RR, &SMI, &aa0, &aa1, &aa2);
        convertRealToResultRegister(&XX, REGISTER_X, amNone);

        if (lrChosen == CF_PARABOLIC_FITTING or lrChosen == CF_GAUSS_FITTING or lrChosen == CF_CAUCHY_FITTING) {
            xIsFny(lrChosen, 2, &XX, &YY, &RR, &SMI, &aa0, &aa1, &aa2);
            liftStack();
            setSystemFlag(FLAG_ASLIFT);
            convertRealToResultRegister(&XX, REGISTER_X, amNone);
        }

        setSystemFlag(FLAG_ASLIFT);
    }
}
