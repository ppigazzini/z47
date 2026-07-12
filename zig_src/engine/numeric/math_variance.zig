// SPDX-License-Identifier: GPL-3.0-only
const abi = @import("abi");
const consts = abi.constants;
const const_1 = consts.const_1;
const const_2 = consts.const_2;
//
// Zig owner for src/c47/mathematics/variance.c: sample/population standard
// deviations, standard errors, covariances, correlation, sxy/sx/sy and the
// curve-fit error helpers (fnStatSa / processCurvefitSA / fnStatSMI etc).
// UNCOVERED by the testSuite (no gate); this is a faithful line-by-line
// translation preserving the exact real_t operation order (in particular the
// realFMA-based difference at the start of do_stddev). The static do_stddev /
// calculateStandardDeviation / calculateWeightedStandardDeviation helpers stay
// private; every header-declared fn* / fnStat* / processCurvefitSA is exported
// with C linkage. The STATDEBUG block is dropped (PC_BUILD only). The
// EXTRA_INFO_ON_CALC_ERROR hint becomes a fixed moreInfoOnError string.
//
// Statistical-sum register accessors (statisticalSumsPointer is real_t *,
// stride sizeof(real_t)==60): SIGMA_N=ptr[0], SIGMA_X=ptr[1], SIGMA_Y=ptr[2],
// SIGMA_X2=ptr[3], SIGMA_X2Y=ptr[4], SIGMA_Y2=ptr[5], SIGMA_XY=ptr[6],
// SIGMA_lnX=ptr[8], SIGMA_ln2X=ptr[9], SIGMA_lnY=ptr[11], SIGMA_ln2Y=ptr[12].
// Indices verified against defines.h SUM_*.
// Real ops: realDivide/realChangeSign/realFMA/realSubtract/realSquareRoot/
// realExp/realMultiply/realAdd/realToReal34, mostly &ctxtReal75 (some &ctxtReal39
// exactly as the C). do_stddev writes via registerReal34Ptr(regIndex) ==
// REGISTER_REAL34_DATA(regIndex). FLAG_ASLIFT == 0xc023 (real value). TI_* are
// the real defines.h values. CF_* and orOrtho match defines.h.

const runtime = @import("math_command_wrappers_runtime.zig");
const math_command_wrappers = @import("math_command_wrappers.zig"); // M-callconv: Zig-to-Zig

const real_t = runtime.real_t;
const real34_t = runtime.real34_t;
const realContext_t = runtime.realContext_t;
const calcRegister_t = runtime.calcRegister_t;

const REGISTER_X = runtime.REGISTER_X;
const REGISTER_Y = runtime.REGISTER_Y;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const amNone = runtime.amNone;
const dtReal34 = runtime.dtReal34;

const FLAG_ASLIFT: i32 = 0xc023;
const ERROR_NO_ERRORS_CALCULABLE: u8 = 40;

const CF_LINEAR_FITTING: u16 = 1;
const CF_EXPONENTIAL_FITTING: u16 = 2;
const CF_LOGARITHMIC_FITTING: u16 = 4;
const CF_POWER_FITTING: u16 = 8;
const CF_ORTHOGONAL_FITTING: u16 = 512;
inline fn orOrtho(a: u16) u16 {
    return if (a == 0) CF_ORTHOGONAL_FITTING else a;
}

const TI_SAMPLSTDDEV: u8 = 26;
const TI_POPLSTDDEV: u8 = 27;
const TI_STDERR: u8 = 28;
const TI_GEOMSAMPLSTDDEV: u8 = 29;
const TI_GEOMPOPLSTDDEV: u8 = 30;
const TI_GEOMSTDERR: u8 = 31;
const TI_WEIGHTEDSAMPLSTDDEV: u8 = 23;
const TI_WEIGHTEDPOPLSTDDEV: u8 = 24;
const TI_WEIGHTEDSTDERR: u8 = 25;
const TI_COV: u8 = 38;
const TI_SXY: u8 = 37;
const TI_CORR: u8 = 39;
const TI_SMI: u8 = 40;
const TI_SA: u8 = 47;

const realDivide = runtime.realDivide;
const realChangeSign = runtime.realChangeSign;
const realFMA = runtime.realFMA;
const realSubtract = runtime.realSubtract;
const realSquareRoot = runtime.realSquareRoot;
const realMultiply = runtime.realMultiply;
const realAdd = runtime.realAdd;
const realToReal34 = runtime.realToReal34;
const realIsNegative = runtime.realIsNegative;
const realIsZero = runtime.realIsZero;
const realSetZero = runtime.realSetZero;
const uInt32ToReal = runtime.uInt32ToReal;
const liftStack = runtime.liftStack;
const setSystemFlag = runtime.setSystemFlag;
const reallocateRegister = runtime.reallocateRegister;
const convertRealToReal34ResultRegister = runtime.convertRealToReal34ResultRegister;
const registerReal34Ptr = runtime.registerReal34Ptr;
const displayCalcErrorMessage = runtime.displayCalcErrorMessage;
const moreInfoOnError = runtime.moreInfoOnError;

extern var ctxtReal39: realContext_t;
extern var ctxtReal75: realContext_t;
extern var lrChosen: u16;
extern var lrSelection: u16;

extern fn checkMinimumDataPoints(n: *const real_t) bool;
extern fn processCurvefitSelection(selection: u16, RR_: *real_t, SMI_: *real_t, aa0: *real_t, aa1: *real_t, aa2: *real_t) void;
extern fn processCurvefitSelectionAll(selection: u16, RR_: *real_t, MX: *real_t, MX2: *real_t, SX2: *real_t, SY2: *real_t, SMI_: *real_t, aa0: *real_t, aa1: *real_t, aa2: *real_t) void;
extern var statisticalSumsPointer: ?[*]real_t;

inline fn sigma(index: usize) *real_t {
    return &statisticalSumsPointer.?[index];
}
inline fn SIGMA_N() *real_t {
    return sigma(0);
}
inline fn SIGMA_X() *real_t {
    return sigma(1);
}
inline fn SIGMA_Y() *real_t {
    return sigma(2);
}
inline fn SIGMA_X2() *real_t {
    return sigma(3);
}
inline fn SIGMA_X2Y() *real_t {
    return sigma(4);
}
inline fn SIGMA_Y2() *real_t {
    return sigma(5);
}
inline fn SIGMA_XY() *real_t {
    return sigma(6);
}
inline fn SIGMA_lnX() *real_t {
    return sigma(8);
}
inline fn SIGMA_ln2X() *real_t {
    return sigma(9);
}
inline fn SIGMA_lnY() *real_t {
    return sigma(11);
}
inline fn SIGMA_ln2Y() *real_t {
    return sigma(12);
}

// Blob constants.
const cstR = abi.constants.cstRAligned;

// Standard deviations and standard errors. The computation involves
// subtraction of large numbers that quite possibly are close to each other.
// Because of this, the start of the computation is performed using a FMA for
// the difference.
fn do_stddev(sumXX: *const real_t, sumX: *const real_t, numberX: *const real_t, sample: c_int, rootn: c_int, exp: c_int, regIndex: calcRegister_t) linksection(runtime.code_section) void {
    var tempReal1: real_t = undefined;
    var tempReal2: real_t = undefined;
    var tempReal3: real_t = undefined;
    var p: *const real_t = numberX;
    const realContext = &ctxtReal75; // Summation data with 75 digits

    realDivide(sumX, numberX, &tempReal2, realContext);
    realChangeSign(&tempReal2);
    realFMA(sumX, &tempReal2, sumXX, &tempReal1, realContext);
    if (sample != 0) {
        realSubtract(numberX, const_1(), &tempReal3, realContext);
        p = &tempReal3;
    }
    realDivide(&tempReal1, p, &tempReal2, realContext);
    if (realIsNegative(&tempReal2) or realIsZero(&tempReal2)) {
        realSetZero(&tempReal1);
    } else {
        realSquareRoot(&tempReal2, &tempReal1, realContext);
    }

    p = &tempReal1;
    if (rootn != 0) {
        realSquareRoot(numberX, &tempReal2, realContext);
        realDivide(&tempReal1, &tempReal2, &tempReal3, realContext);
        p = &tempReal3;
    }
    if (exp != 0) {
        math_command_wrappers.realExp(p, &tempReal2, realContext);
        p = &tempReal2;
    }
    realToReal34(p, registerReal34Ptr(regIndex));
}

fn calculateStandardDeviation(sumX2: *const real_t, sumX: *const real_t, number: *const real_t, sumY2: *const real_t, sumY: *const real_t, sample: c_int, rootn: c_int, exp: c_int, displayInfo: u8) linksection(runtime.code_section) void {
    if (checkMinimumDataPoints(const_2())) {
        liftStack();
        setSystemFlag(FLAG_ASLIFT);
        liftStack();

        do_stddev(sumX2, sumX, number, sample, rootn, exp, REGISTER_X);
        do_stddev(sumY2, sumY, number, sample, rootn, exp, REGISTER_Y);

        runtime.temporaryInformation = displayInfo;
    }
}

pub export fn fnSampleStdDev(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    calculateStandardDeviation(SIGMA_X2(), SIGMA_X(), SIGMA_N(), SIGMA_Y2(), SIGMA_Y(), 1, 0, 0, TI_SAMPLSTDDEV);
}

pub export fn fnPopulationStdDev(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    calculateStandardDeviation(SIGMA_X2(), SIGMA_X(), SIGMA_N(), SIGMA_Y2(), SIGMA_Y(), 0, 0, 0, TI_POPLSTDDEV);
}

pub export fn fnStandardError(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    calculateStandardDeviation(SIGMA_X2(), SIGMA_X(), SIGMA_N(), SIGMA_Y2(), SIGMA_Y(), 1, 1, 0, TI_STDERR);
}

pub export fn fnGeometricSampleStdDev(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    calculateStandardDeviation(SIGMA_ln2X(), SIGMA_lnX(), SIGMA_N(), SIGMA_ln2Y(), SIGMA_lnY(), 1, 0, 1, TI_GEOMSAMPLSTDDEV);
}

pub export fn fnGeometricPopulationStdDev(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    calculateStandardDeviation(SIGMA_ln2X(), SIGMA_lnX(), SIGMA_N(), SIGMA_ln2Y(), SIGMA_lnY(), 0, 0, 1, TI_GEOMPOPLSTDDEV);
}

pub export fn fnGeometricStandardError(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    calculateStandardDeviation(SIGMA_ln2X(), SIGMA_lnX(), SIGMA_N(), SIGMA_ln2Y(), SIGMA_lnY(), 1, 1, 1, TI_GEOMSTDERR);
}

// Weighted standard deviation, standard error
fn calculateWeightedStandardDeviation(sample: c_int, rootn: c_int, exp: c_int, display: u8) linksection(runtime.code_section) void {
    if (checkMinimumDataPoints(const_2())) {
        liftStack();
        setSystemFlag(FLAG_ASLIFT);
        do_stddev(SIGMA_X2Y(), SIGMA_XY(), SIGMA_Y(), sample, rootn, exp, REGISTER_X);

        runtime.temporaryInformation = display;
    }
}

pub export fn fnWeightedSampleStdDev(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    calculateWeightedStandardDeviation(1, 0, 0, TI_WEIGHTEDSAMPLSTDDEV);
}

pub export fn fnWeightedPopulationStdDev(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    calculateWeightedStandardDeviation(0, 0, 0, TI_WEIGHTEDPOPLSTDDEV);
}

pub export fn fnWeightedStandardError(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    calculateWeightedStandardDeviation(1, 1, 0, TI_WEIGHTEDSTDERR);
}

pub export fn fnStatSX_SY(SX: *real_t, SY: *real_t) linksection(runtime.code_section) callconv(.c) void {
    const realContext = &ctxtReal75; // Summation data with 75 digits
    var TT: real_t = undefined;
    var UU: real_t = undefined;
    if (checkMinimumDataPoints(const_2())) {
        realMultiply(SIGMA_N(), SIGMA_X2(), &TT, realContext); //do sx
        realMultiply(SIGMA_X(), SIGMA_X(), &UU, realContext);
        realSubtract(&TT, &UU, &TT, realContext);
        realDivide(&TT, SIGMA_N(), &TT, realContext);
        realSubtract(SIGMA_N(), const_1(), &UU, realContext);
        realDivide(&TT, &UU, &TT, realContext);
        realSquareRoot(&TT, SX, realContext); //this is sx

        realMultiply(SIGMA_N(), SIGMA_Y2(), &TT, realContext); //do sy
        realMultiply(SIGMA_Y(), SIGMA_Y(), &UU, realContext);
        realSubtract(&TT, &UU, &TT, realContext);
        realDivide(&TT, SIGMA_N(), &TT, realContext);
        realSubtract(SIGMA_N(), const_1(), &UU, realContext);
        realDivide(&TT, &UU, &TT, realContext);
        realSquareRoot(&TT, SY, realContext); //this is sy
    }
}

pub export fn fnStatSXY(SXY: *real_t) linksection(runtime.code_section) callconv(.c) void {
    const realContext = &ctxtReal75; // Summation data with 75 digits
    var SS: real_t = undefined;
    var TT: real_t = undefined;
    if (checkMinimumDataPoints(const_2())) {
        realMultiply(SIGMA_N(), SIGMA_XY(), &SS, realContext); //do sxy
        realMultiply(SIGMA_X(), SIGMA_Y(), &TT, realContext);
        realSubtract(&SS, &TT, &SS, realContext);
        realDivide(&SS, SIGMA_N(), &SS, realContext);
        realSubtract(SIGMA_N(), const_1(), &TT, realContext);
        realDivide(&SS, &TT, SXY, realContext);
    }
}

pub export fn fnPopulationCovariance(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void { //COVxy
    _ = unusedButMandatoryParameter;
    const realContext = &ctxtReal75; // Summation data with 75 digits
    var TT: real_t = undefined;
    var SXY: real_t = undefined;
    if (checkMinimumDataPoints(const_2())) {
        fnStatSXY(&SXY);
        realSubtract(SIGMA_N(), const_1(), &TT, realContext);
        realMultiply(&SXY, &TT, &SXY, realContext);
        realDivide(&SXY, SIGMA_N(), &TT, realContext);

        liftStack();
        setSystemFlag(FLAG_ASLIFT);
        reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
        convertRealToReal34ResultRegister(&TT, REGISTER_X);
        runtime.temporaryInformation = TI_COV;
    }
}

pub export fn fnSampleCovariance(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void { //sxy
    _ = unusedButMandatoryParameter;
    var SXY: real_t = undefined;
    if (checkMinimumDataPoints(const_2())) {
        fnStatSXY(&SXY);
        liftStack();
        setSystemFlag(FLAG_ASLIFT);
        reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
        convertRealToReal34ResultRegister(&SXY, REGISTER_X);
        runtime.temporaryInformation = TI_SXY;
    }
}

pub export fn fnStatR(RR: *real_t, SXY: *real_t, SX: *real_t, SY: *real_t) linksection(runtime.code_section) callconv(.c) void {
    const realContext = &ctxtReal75; // Summation data with 75 digits
    if (checkMinimumDataPoints(const_2())) {
        fnStatSX_SY(SX, SY);
        fnStatSXY(SXY);
        realDivide(SXY, SX, RR, realContext); //this is sxy/sx
        realDivide(RR, SY, RR, realContext); //this is sxy/sx/sy
    }
}

pub export fn fnCoefficientDetermination(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void { //r
    _ = unusedButMandatoryParameter;
    var RR: real_t = undefined;
    var SMI: real_t = undefined;
    var aa0: real_t = undefined;
    var aa1: real_t = undefined;
    var aa2: real_t = undefined;
    if (checkMinimumDataPoints(const_2())) {
        if (lrChosen == 0) { //if lrChosen contains something, the stat data exists, otherwise set it to linear.
            lrChosen = CF_LINEAR_FITTING;
        }
        processCurvefitSelection(lrChosen, &RR, &SMI, &aa0, &aa1, &aa2);
        liftStack();
        setSystemFlag(FLAG_ASLIFT);
        reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
        convertRealToReal34ResultRegister(&RR, REGISTER_X);
        runtime.temporaryInformation = TI_CORR;
    }
}

pub export fn fnStatSMI(SMI: *real_t) linksection(runtime.code_section) callconv(.c) void {
    const realContext = &ctxtReal75; // Summation data with 75 digits
    var RR: real_t = undefined;
    var SXY: real_t = undefined;
    var SX: real_t = undefined;
    var SY: real_t = undefined;
    var RR2: real_t = undefined;
    var SX2: real_t = undefined;
    var SY2: real_t = undefined;
    var UU: real_t = undefined;
    var SS: real_t = undefined;
    var TT: real_t = undefined;
    if (checkMinimumDataPoints(const_2())) {
        fnStatR(&RR, &SXY, &SX, &SY);
        realMultiply(&SX, &SX, &SX2, realContext); //   --> sx^2
        realMultiply(&SY, &SY, &SY2, realContext); //   --> sy^2
        realMultiply(&RR, &RR, &RR2, realContext); //   --> r^2
        realSubtract(const_1(), &RR2, &SS, realContext); //  sqrt[ (1-r^2) / (r^2.SY2 - SX^2) * SX2.SY2 ]

        realMultiply(&RR2, &SY2, &TT, realContext);
        realAdd(&TT, &SX2, &TT, realContext);
        realDivide(&SS, &TT, &UU, realContext);
        realMultiply(&UU, &SX2, &UU, realContext);
        realMultiply(&UU, &SY2, &UU, realContext); //  --> smi2
        realSquareRoot(&UU, SMI, &ctxtReal39);
    }
}

pub export fn fnMinExpStdDev(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void { //smi
    _ = unusedButMandatoryParameter;
    var SMI: real_t = undefined;
    var RR: real_t = undefined;
    var aa0: real_t = undefined;
    var aa1: real_t = undefined;
    var aa2: real_t = undefined;
    var n30: real_t = undefined;
    uInt32ToReal(30, &n30);
    if (checkMinimumDataPoints(&n30)) {
        lrChosen = CF_ORTHOGONAL_FITTING; //force to ORTHOF only
        lrSelection = CF_ORTHOGONAL_FITTING;
        processCurvefitSelection(lrChosen, &RR, &SMI, &aa0, &aa1, &aa2);
        liftStack();
        setSystemFlag(FLAG_ASLIFT);
        reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
        convertRealToReal34ResultRegister(&SMI, REGISTER_X);
        runtime.temporaryInformation = TI_SMI;
    }
}

pub export fn processCurvefitSA(SA0: *real_t, SA1: *real_t) linksection(runtime.code_section) callconv(.c) bool {
    const realContext = &ctxtReal75; // Summation data with 75 digits
    var RR: real_t = undefined;
    var MX: real_t = undefined;
    var SX: real_t = undefined;
    var SY: real_t = undefined;
    var RR2: real_t = undefined;
    var MX2: real_t = undefined;
    var SX2: real_t = undefined;
    var SY2: real_t = undefined;
    var UU: real_t = undefined;
    var SS: real_t = undefined;
    var TT: real_t = undefined;
    var aa0: real_t = undefined;
    var aa1: real_t = undefined;
    var aa2: real_t = undefined;
    var SMI: real_t = undefined;

    if (checkMinimumDataPoints(const_2())) {
        realSetZero(&aa0);
        realSetZero(&aa1);
        realSetZero(&aa2);

        if (lrChosen == 0) { //if lrChosen contains something, the stat data exists, otherwise set it to linear.
            lrChosen = CF_LINEAR_FITTING;
        }
        //Replaced fnStatR (&RR, &SXY, &SX, &SY);
        processCurvefitSelectionAll(lrChosen, &RR, &MX, &MX2, &SX2, &SY2, &SMI, &aa0, &aa1, &aa2);
        realMultiply(&RR, &RR, &RR2, realContext); //   --> r^2

        switch (orOrtho(lrChosen)) {
            CF_LINEAR_FITTING, CF_ORTHOGONAL_FITTING, CF_EXPONENTIAL_FITTING, CF_POWER_FITTING, CF_LOGARITHMIC_FITTING => {
                //All parameters set from processCurvefitSelectionAll
            },
            else => {
                displayCalcErrorMessage(ERROR_NO_ERRORS_CALCULABLE, ERR_REGISTER_LINE, REGISTER_X);
                moreInfoOnError("In function processCurvefitSA:", "No errors are calculable for the selected/chosen model!", null, null);
                return false;
            },
        }

        realSquareRoot(&SX2, &SX, realContext);
        realSquareRoot(&SY2, &SY, realContext);

        //RR2, SY, SX, SX2, MX2 SS, TT, UU > SA1 SA0
        realSubtract(const_1(), &RR2, &SS, realContext); //SA1 = f( RR2, n, SY, SX )
        realSubtract(SIGMA_N(), const_2(), &TT, realContext);
        realDivide(&SS, &TT, &UU, realContext);
        realSquareRoot(&UU, &UU, &ctxtReal39);
        realMultiply(&UU, &SY, &UU, &ctxtReal39);
        realDivide(&UU, &SX, SA1, &ctxtReal39);

        realSubtract(SIGMA_N(), const_1(), &SS, realContext); //SA0 = f( n, SX2, MX2, SA1 )
        realDivide(&SS, SIGMA_N(), &SS, realContext); //SS = (n-1)/n
        realMultiply(&SS, &SX2, &SS, realContext); //SS = SS * SX^2
        realAdd(&SS, &MX2, &SS, realContext);
        realSquareRoot(&SS, &SS, &ctxtReal39);
        realMultiply(&SS, SA1, SA0, &ctxtReal39);
        return true;
    } else {
        return false;
    }
}

pub export fn fnStatSa(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var SA0: real_t = undefined;
    var SA1: real_t = undefined;

    if (processCurvefitSA(&SA0, &SA1)) {
        liftStack();
        setSystemFlag(FLAG_ASLIFT);
        liftStack();

        convertRealToReal34ResultRegister(&SA0, REGISTER_X);
        convertRealToReal34ResultRegister(&SA1, REGISTER_Y);
        runtime.temporaryInformation = TI_SA;
    }
}
