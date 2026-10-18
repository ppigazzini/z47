// SPDX-License-Identifier: GPL-3.0-only
const abi = @import("abi");
const consts = abi.constants;
const const__1 = consts.const__1;
const const_0 = consts.const_0;
const const_1 = consts.const_1;
const const_2 = consts.const_2;
const const_3 = consts.const_3;
//
// Zig owner for src/c47/mathematics/variance.c: sample/population standard
// deviations, standard errors, covariances, correlation, sxy/sx/sy and the
// curve-fit error helpers (fnStatSa / processCurvefitSA / fnStatSMI etc).
// UNCOVERED by the testSuite (no gate); this is a faithful line-by-line
// translation preserving the exact real_t operation order. Every centred sum
// is formed from the stored Real34 observations in STATS about their mean,
// one fused multiply-add per observation, and falls back to the stored sums
// (moment - sumX * sumY / number, the quotient at 150 digits) when STATS is
// gone or holds a long integer wider than 34 digits rounded. The static
// helpers stay private; every header-declared fn* / fnStat* / processCurvefitSA
// is exported with C linkage. The STATDEBUG block is dropped (PC_BUILD only).
// The EXTRA_INFO_ON_CALC_ERROR hint becomes a fixed moreInfoOnError string.
//
// Statistical-sum register accessors (statisticalSumsPointer is real_t *,
// stride sizeof(real_t)==60): SIGMA_N=ptr[0], SIGMA_X=ptr[1], SIGMA_Y=ptr[2],
// SIGMA_X2=ptr[3], SIGMA_X2Y=ptr[4], SIGMA_Y2=ptr[5], SIGMA_XY=ptr[6],
// SIGMA_lnXlnY=ptr[7], SIGMA_lnX=ptr[8], SIGMA_ln2X=ptr[9], SIGMA_YlnX=ptr[10],
// SIGMA_lnY=ptr[11], SIGMA_ln2Y=ptr[12], SIGMA_XlnY=ptr[13], SIGMA_XMIN=ptr[24],
// SIGMA_XMAX=ptr[25], SIGMA_YMIN=ptr[26], SIGMA_YMAX=ptr[27]. Indices verified
// against defines.h SUM_*. FLAG_ASLIFT == 0xc023 (real value). TI_* are the
// real defines.h values. CF_* and orOrtho match defines.h.

const runtime = @import("../command_wrappers/runtime.zig");
const math_command_wrappers = @import("../command_wrappers.zig");
const math_comparison_reals = @import("../compare/comparison_reals.zig");
const real_t = runtime.real_t;
const real34Matrix_t = runtime.real34Matrix_t;
const realContext_t = runtime.realContext_t;
const calcRegister_t = runtime.calcRegister_t;

const REGISTER_X = runtime.REGISTER_X;
const REGISTER_Y = runtime.REGISTER_Y;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const amNone = runtime.amNone;

const FLAG_ASLIFT: i32 = 0xc023;
const ERROR_TOO_FEW_DATA: u8 = 15;
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
const realMinus = runtime.realMinus;
const realToReal34 = runtime.realToReal34;
const real34ToReal = runtime.real34ToReal;
const realIsNegative = runtime.realIsNegative;
const realIsNaN = runtime.realIsNaN;
const realIsZero = runtime.realIsZero;
const realSetZero = runtime.realSetZero;
const realCompareEqual = runtime.realCompareEqual;
const realCompareLessThan = runtime.realCompareLessThan;
const realCompareLessEqual = runtime.realCompareLessEqual;
const realCompareGreaterThan = runtime.realCompareGreaterThan;
const realCompareAbsLessThan = math_comparison_reals.realCompareAbsLessThan;
const uInt32ToReal = runtime.uInt32ToReal;
const liftStack = runtime.liftStack;
const setSystemFlag = runtime.setSystemFlag;
const convertRealToReal34ResultRegister = runtime.convertRealToReal34ResultRegister;
const convertRealToResultRegister = runtime.convertRealToResultRegister;
const registerReal34Ptr = runtime.registerReal34Ptr;
const displayCalcErrorMessage = runtime.displayCalcErrorMessage;
const moreInfoOnError = runtime.moreInfoOnError;
const findNamedVariable = runtime.findNamedVariable;
const linkToRealMatrixRegister = runtime.linkToRealMatrixRegister;
const WP34S_Ln = runtime.WP34S_Ln;
const realElems = abi.matrixRealElems;

// decNumberCopy moves the header plus only the units `digits` covers, which is
// also the one safe read of a blob constant shorter than a real_t.
extern fn decNumberCopy(res: *real_t, source: *const real_t) *real_t;
extern fn decNumberCopyAbs(res: *real_t, source: *const real_t) *real_t;
inline fn realCopy(source: *const real_t, destination: *real_t) void {
    _ = decNumberCopy(destination, source);
}
inline fn realCopyAbs(source: *const real_t, destination: *real_t) void {
    _ = decNumberCopyAbs(destination, source);
}

// constantPointers.h const_1e32: the magnitude from which a 34-digit STATS
// entry no longer squares to what addSigma summed.
inline fn const_1e32() *const real_t {
    return consts.const_1e32();
}

extern var ctxtReal34: realContext_t;
extern var ctxtReal39: realContext_t;
extern var ctxtReal51: realContext_t;
extern var ctxtReal75: realContext_t;
extern var lrChosen: u16;
extern var lrSelection: u16;
// stats.c: the name of the matrix the sums were taken from.
extern var statMx: [8]u8;

extern fn checkMinimumDataPoints(n: *const real_t) bool;
extern fn isStatsMatrix(rows: *u16, mx: [*:0]const u8) bool;
extern fn processCurvefitSelection(selection: u16, RR_: *real_t, SMI_: *real_t, aa0: *real_t, aa1: *real_t, aa2: *real_t) void;
extern fn processCurvefitSelectionAll(selection: u16, RR_: *real_t, MX: *real_t, MX2: *real_t, SX2: *real_t, SY2: *real_t, SMI_: *real_t, aa0: *real_t, aa1: *real_t, aa2: *real_t) void;
extern var statisticalSumsPointer: ?[*]real_t;

const IDX_SIGMA_N: usize = 0;
const IDX_SIGMA_X: usize = 1;
const IDX_SIGMA_Y: usize = 2;
const IDX_SIGMA_X2: usize = 3;
const IDX_SIGMA_X2Y: usize = 4;
const IDX_SIGMA_Y2: usize = 5;
const IDX_SIGMA_XY: usize = 6;
const IDX_SIGMA_lnXlnY: usize = 7;
const IDX_SIGMA_lnX: usize = 8;
const IDX_SIGMA_ln2X: usize = 9;
const IDX_SIGMA_YlnX: usize = 10;
const IDX_SIGMA_lnY: usize = 11;
const IDX_SIGMA_ln2Y: usize = 12;
const IDX_SIGMA_XlnY: usize = 13;
const IDX_SIGMA_XMIN: usize = 24;
const IDX_SIGMA_XMAX: usize = 25;
const IDX_SIGMA_YMIN: usize = 26;
const IDX_SIGMA_YMAX: usize = 27;

inline fn sigma(index: usize) *real_t {
    return &statisticalSumsPointer.?[index];
}
inline fn SIGMA_N() *real_t {
    return sigma(IDX_SIGMA_N);
}
inline fn SIGMA_X() *real_t {
    return sigma(IDX_SIGMA_X);
}
inline fn SIGMA_Y() *real_t {
    return sigma(IDX_SIGMA_Y);
}
inline fn SIGMA_XY() *real_t {
    return sigma(IDX_SIGMA_XY);
}

inline fn statMxName() [*:0]const u8 {
    return @ptrCast(&statMx);
}

// The observation component a centred sum is taken over, with its transformation.
const deviationSource_t = enum {
    DEVIATION_X,
    DEVIATION_Y,
    DEVIATION_LNX,
    DEVIATION_LNY,
    DEVIATION_WEIGHTED_X,
};

// Obtains one stored observation component with its requested transformation.
fn statisticalValue(stats: *real34Matrix_t, row: u16, cols: u16, source: deviationSource_t, value: *real_t) linksection(runtime.code_section) void {
    const yColumn: usize = if (source == .DEVIATION_Y or source == .DEVIATION_LNY) 1 else 0;
    real34ToReal(&realElems(stats)[@as(usize, row) * @as(usize, cols) + yColumn], value);
    if (source == .DEVIATION_LNX or source == .DEVIATION_LNY) {
        WP34S_Ln(value, value, &ctxtReal75);
    }
}

// Returns the stored second moment of an observation component: the sum of the
// squared component, weighted when source is DEVIATION_WEIGHTED_X.
fn secondMoment(source: deviationSource_t) linksection(runtime.code_section) *const real_t {
    return switch (source) {
        .DEVIATION_Y => sigma(IDX_SIGMA_Y2),
        .DEVIATION_LNX => sigma(IDX_SIGMA_ln2X),
        .DEVIATION_LNY => sigma(IDX_SIGMA_ln2Y),
        .DEVIATION_WEIGHTED_X => sigma(IDX_SIGMA_X2Y),
        else => sigma(IDX_SIGMA_X2),
    };
}

// Returns the stored product moment of two observation components.
fn productMoment(sourceX: deviationSource_t, sourceY: deviationSource_t) linksection(runtime.code_section) *const real_t {
    if (sourceX == .DEVIATION_LNX) {
        return if (sourceY == .DEVIATION_LNY) sigma(IDX_SIGMA_lnXlnY) else sigma(IDX_SIGMA_YlnX);
    }
    return if (sourceY == .DEVIATION_LNY) sigma(IDX_SIGMA_XlnY) else sigma(IDX_SIGMA_XY);
}

// Returns true when the observations in STATS give the stored sums of x^2 and y^2.
//
// A long integer wider than 34 digits enters the sums with all its digits and STATS rounded to 34, which changes its square. Every value below 1E32 is stored as
// it was summed, so the squares in STATS are summed again, as addSigma sums them, only when an extreme value reaches 1E32.
fn statsMatchSums() linksection(runtime.code_section) bool {
    var stats: real34Matrix_t = undefined;
    var value: real_t = undefined;
    var sumX2: real_t = undefined;
    var sumY2: real_t = undefined;

    if (realCompareAbsLessThan(sigma(IDX_SIGMA_XMIN), const_1e32()) and realCompareAbsLessThan(sigma(IDX_SIGMA_XMAX), const_1e32()) and
        realCompareAbsLessThan(sigma(IDX_SIGMA_YMIN), const_1e32()) and realCompareAbsLessThan(sigma(IDX_SIGMA_YMAX), const_1e32()))
    {
        return true;
    }
    linkToRealMatrixRegister(findNamedVariable(statMxName()), &stats);
    const rows: u16 = stats.header.matrixRows;
    const cols: u16 = stats.header.matrixColumns;
    realSetZero(&sumX2);
    realSetZero(&sumY2);
    var i: u16 = 0;
    while (i < rows) : (i += 1) {
        real34ToReal(&realElems(&stats)[@as(usize, i) * @as(usize, cols)], &value);
        realMultiply(&value, &value, &value, &ctxtReal75);
        realAdd(&sumX2, &value, &sumX2, &ctxtReal75);
        real34ToReal(&realElems(&stats)[@as(usize, i) * @as(usize, cols) + 1], &value);
        realMultiply(&value, &value, &value, &ctxtReal75);
        realAdd(&sumY2, &value, &sumY2, &ctxtReal75);
    }
    return realCompareEqual(&sumX2, sigma(IDX_SIGMA_X2)) and realCompareEqual(&sumY2, sigma(IDX_SIGMA_Y2));
}

// Forms a centred sum from the stored sums: moment - sumX * sumY / number.
//
// The FMA forms the product exactly. The quotient is formed to 150 digits, so its rounding moves the result by at most |sumX * sumY / number| * 5E-150: at 75 digits
// that bound is 1.5 for three long integers next to 1E37, whose centred square sum is 18.7. The 159-digit storage holds the 150-digit quotient.
fn centredFromSums(sumY: *const real_t, number: *const real_t, sumX: *const real_t, moment: *const real_t, res: *real_t) linksection(runtime.code_section) void {
    var context = ctxtReal75;
    var mean_b: abi.Real159 = undefined;
    const mean = mean_b.ptr();

    context.digits = 150;
    realDivide(sumY, number, mean, &context);
    realChangeSign(mean);
    realFMA(sumX, mean, moment, res, &ctxtReal75);
}

// Forms the centred square sum from the stored Real34 observations. sumX is the
// stored first moment, weighted when source is DEVIATION_WEIGHTED_X; numberX the
// observation count or total weight.
fn centredSquareSum(sumX: *const real_t, numberX: *const real_t, source: deviationSource_t, res: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var stats: real34Matrix_t = undefined;
    var mean: real_t = undefined;
    var value: real_t = undefined;
    var weight: real_t = undefined;
    var square: real_t = undefined;
    var rows: u16 = undefined;

    realDivide(sumX, numberX, &mean, &ctxtReal75);
    realSetZero(res);

    if (!isStatsMatrix(&rows, statMxName()) or !statsMatchSums()) { // after DELVall, and for long integers wider than 34 digits, the stored sums replace the observations
        centredFromSums(sumX, numberX, sumX, secondMoment(source), res);
        return;
    }
    const regStats: calcRegister_t = findNamedVariable(statMxName());
    linkToRealMatrixRegister(regStats, &stats);
    rows = stats.header.matrixRows;
    const cols: u16 = stats.header.matrixColumns;

    var i: u16 = 0;
    while (i < rows) : (i += 1) {
        statisticalValue(&stats, i, cols, source, &value);
        realSubtract(&value, &mean, &value, realContext);

        if (source == .DEVIATION_WEIGHTED_X) {
            realMultiply(&value, &value, &square, realContext);
            real34ToReal(&realElems(&stats)[@as(usize, i) * @as(usize, cols) + 1], &weight);
            realFMA(&weight, &square, res, res, realContext);
        } else {
            realFMA(&value, &value, res, res, realContext);
        }
    }
}

// Forms the centred product sum from the stored Real34 observations.
fn centredProductSum(sumX: *const real_t, sumY: *const real_t, sourceX: deviationSource_t, sourceY: deviationSource_t, res: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var stats: real34Matrix_t = undefined;
    var meanX: real_t = undefined;
    var meanY: real_t = undefined;
    var x: real_t = undefined;
    var y: real_t = undefined;
    var rows: u16 = undefined;

    realDivide(sumX, SIGMA_N(), &meanX, &ctxtReal75);
    realDivide(sumY, SIGMA_N(), &meanY, &ctxtReal75);
    realSetZero(res);

    if (!isStatsMatrix(&rows, statMxName()) or !statsMatchSums()) {
        centredFromSums(sumY, SIGMA_N(), sumX, productMoment(sourceX, sourceY), res);
        return;
    }
    const regStats: calcRegister_t = findNamedVariable(statMxName());
    linkToRealMatrixRegister(regStats, &stats);
    rows = stats.header.matrixRows;
    const cols: u16 = stats.header.matrixColumns;

    var i: u16 = 0;
    while (i < rows) : (i += 1) {
        statisticalValue(&stats, i, cols, sourceX, &x);
        statisticalValue(&stats, i, cols, sourceY, &y);
        realSubtract(&x, &meanX, &x, realContext);
        realSubtract(&y, &meanY, &y, realContext);
        realFMA(&x, &y, res, res, realContext);
    }
}

// Forms the squared residual sum for a regression line. ratio is the regression
// slope, or its reciprocal for a steep line, which steep selects.
fn centredResidualSquareSum(sumX: *const real_t, sumY: *const real_t, sourceX: deviationSource_t, sourceY: deviationSource_t, ratio: *const real_t, steep: bool, res: *real_t) linksection(runtime.code_section) void {
    var stats: real34Matrix_t = undefined;
    var meanX: real_t = undefined;
    var meanY: real_t = undefined;
    var x: real_t = undefined;
    var y: real_t = undefined;
    var negativeRatio: real_t = undefined;
    var residual: real_t = undefined;
    var rows: u16 = undefined;

    realDivide(sumX, SIGMA_N(), &meanX, &ctxtReal75);
    realDivide(sumY, SIGMA_N(), &meanY, &ctxtReal75);
    realMinus(ratio, &negativeRatio, &ctxtReal75);
    realSetZero(res);

    if (!isStatsMatrix(&rows, statMxName()) or !statsMatchSums()) { // from the centred sums: Syy - 2 b Sxy + b^2 Sxx, or b^2 Syy - 2 b Sxy + Sxx for the reciprocal slope
        centredSquareSum(sumX, SIGMA_N(), sourceX, if (steep) &y else &x, &ctxtReal75);
        centredSquareSum(sumY, SIGMA_N(), sourceY, if (steep) &x else &y, &ctxtReal75);
        centredProductSum(sumX, sumY, sourceX, sourceY, &residual, &ctxtReal75);
        realAdd(&residual, &residual, &residual, &ctxtReal75);
        realChangeSign(&residual);
        realFMA(ratio, &x, &residual, &x, &ctxtReal75);
        realFMA(ratio, &x, &y, res, &ctxtReal75);
        return;
    }
    const regStats: calcRegister_t = findNamedVariable(statMxName());
    linkToRealMatrixRegister(regStats, &stats);
    rows = stats.header.matrixRows;
    const cols: u16 = stats.header.matrixColumns;

    var i: u16 = 0;
    while (i < rows) : (i += 1) {
        statisticalValue(&stats, i, cols, sourceX, &x);
        statisticalValue(&stats, i, cols, sourceY, &y);
        realSubtract(&x, &meanX, &x, &ctxtReal75);
        realSubtract(&y, &meanY, &y, &ctxtReal75);
        if (steep) {
            realChangeSign(&x);
            realFMA(ratio, &y, &x, &residual, &ctxtReal75);
        } else {
            realFMA(&negativeRatio, &x, &y, &residual, &ctxtReal75);
        }
        realFMA(&residual, &residual, res, res, &ctxtReal39);
    }
}

// Standard deviations and standard errors.
fn do_stddev(sumX: *const real_t, numberX: *const real_t, source: deviationSource_t, sample: c_int, rootn: c_int, exp: c_int, regIndex: calcRegister_t) linksection(runtime.code_section) void {
    var tempReal1: real_t = undefined;
    var tempReal2: real_t = undefined;
    var tempReal3: real_t = undefined;
    var p: *const real_t = numberX;
    const coreContext: *realContext_t = if (exp != 0) &ctxtReal51 else &ctxtReal39;
    const resultContext: *realContext_t = &ctxtReal39;

    centredSquareSum(sumX, numberX, source, &tempReal1, coreContext);
    if (sample != 0) {
        realSubtract(numberX, const_1(), &tempReal3, coreContext);
        p = &tempReal3;
    }
    realDivide(&tempReal1, p, &tempReal2, coreContext);
    if (rootn != 0) {
        // Divide before the root to remove a second root and division.
        realDivide(&tempReal2, numberX, &tempReal2, coreContext);
    }
    if (realIsNegative(&tempReal2) or realIsZero(&tempReal2)) {
        realSetZero(&tempReal1);
    } else {
        realSquareRoot(&tempReal2, &tempReal1, resultContext);
    }

    p = &tempReal1;
    if (exp != 0) {
        math_command_wrappers.realExp(p, &tempReal2, resultContext);
        p = &tempReal2;
    }
    realToReal34(p, registerReal34Ptr(regIndex));
}

// Sums are named by index, not by pointer, so that none of them is resolved out
// of statisticalSumsPointer before checkMinimumDataPoints has established there
// is summation data to resolve them from.
fn calculateStandardDeviation(sumX: usize, sourceX: deviationSource_t, number: usize, sumY: usize, sourceY: deviationSource_t, sample: c_int, rootn: c_int, exp: c_int, displayInfo: u8) linksection(runtime.code_section) void {
    if (checkMinimumDataPoints(const_2())) {
        liftStack();
        setSystemFlag(FLAG_ASLIFT);
        liftStack();

        do_stddev(sigma(sumX), sigma(number), sourceX, sample, rootn, exp, REGISTER_X);
        do_stddev(sigma(sumY), sigma(number), sourceY, sample, rootn, exp, REGISTER_Y);

        runtime.temporaryInformation = displayInfo;
    }
}

// Standard deviation (sample and population) and standard error for arithmetic mean
pub export fn fnSampleStdDev(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    calculateStandardDeviation(IDX_SIGMA_X, .DEVIATION_X, IDX_SIGMA_N, IDX_SIGMA_Y, .DEVIATION_Y, 1, 0, 0, TI_SAMPLSTDDEV);
}

pub export fn fnPopulationStdDev(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    calculateStandardDeviation(IDX_SIGMA_X, .DEVIATION_X, IDX_SIGMA_N, IDX_SIGMA_Y, .DEVIATION_Y, 0, 0, 0, TI_POPLSTDDEV);
}

pub export fn fnStandardError(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    calculateStandardDeviation(IDX_SIGMA_X, .DEVIATION_X, IDX_SIGMA_N, IDX_SIGMA_Y, .DEVIATION_Y, 1, 1, 0, TI_STDERR);
}

// Standard deviation (sample and population) and standard error for geometric mean
pub export fn fnGeometricSampleStdDev(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    calculateStandardDeviation(IDX_SIGMA_lnX, .DEVIATION_LNX, IDX_SIGMA_N, IDX_SIGMA_lnY, .DEVIATION_LNY, 1, 0, 1, TI_GEOMSAMPLSTDDEV);
}

pub export fn fnGeometricPopulationStdDev(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    calculateStandardDeviation(IDX_SIGMA_lnX, .DEVIATION_LNX, IDX_SIGMA_N, IDX_SIGMA_lnY, .DEVIATION_LNY, 0, 0, 1, TI_GEOMPOPLSTDDEV);
}

pub export fn fnGeometricStandardError(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    calculateStandardDeviation(IDX_SIGMA_lnX, .DEVIATION_LNX, IDX_SIGMA_N, IDX_SIGMA_lnY, .DEVIATION_LNY, 1, 1, 1, TI_GEOMSTDERR);
}

// Weighted standard deviation, standard error
fn calculateWeightedStandardDeviation(sample: c_int, rootn: c_int, exp: c_int, display: u8) linksection(runtime.code_section) void {
    if (checkMinimumDataPoints(const_2())) {
        const invalidWeight = !realIsNaN(SIGMA_Y()) and
            (if (sample != 0) realCompareLessEqual(SIGMA_Y(), const_1()) else realCompareLessEqual(SIGMA_Y(), const_0()));
        if (invalidWeight) {
            displayCalcErrorMessage(ERROR_TOO_FEW_DATA, ERR_REGISTER_LINE);
            return;
        }
        liftStack();
        setSystemFlag(FLAG_ASLIFT);
        do_stddev(SIGMA_XY(), SIGMA_Y(), .DEVIATION_WEIGHTED_X, sample, rootn, exp, REGISTER_X);

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
    const realContext = &ctxtReal39;
    var TT: real_t = undefined;
    if (checkMinimumDataPoints(const_2())) {
        realSubtract(SIGMA_N(), const_1(), &TT, realContext);
        centredSquareSum(SIGMA_X(), SIGMA_N(), .DEVIATION_X, SX, realContext);
        realDivide(SX, &TT, SX, realContext);
        realSquareRoot(SX, SX, realContext);

        centredSquareSum(SIGMA_Y(), SIGMA_N(), .DEVIATION_Y, SY, realContext);
        realDivide(SY, &TT, SY, realContext);
        realSquareRoot(SY, SY, realContext);
    }
}

pub export fn fnStatSXY(SXY: *real_t) linksection(runtime.code_section) callconv(.c) void {
    const realContext = &ctxtReal75;
    var TT: real_t = undefined;
    if (checkMinimumDataPoints(const_2())) {
        centredProductSum(SIGMA_X(), SIGMA_Y(), .DEVIATION_X, .DEVIATION_Y, SXY, realContext);
        realSubtract(SIGMA_N(), const_1(), &TT, realContext);
        realDivide(SXY, &TT, SXY, realContext);
    }
}

pub export fn fnPopulationCovariance(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void { //COVxy
    _ = unusedButMandatoryParameter;
    var SXY: real_t = undefined;
    if (checkMinimumDataPoints(const_2())) {
        centredProductSum(SIGMA_X(), SIGMA_Y(), .DEVIATION_X, .DEVIATION_Y, &SXY, &ctxtReal75);
        realDivide(&SXY, SIGMA_N(), &SXY, &ctxtReal34);

        liftStack();
        setSystemFlag(FLAG_ASLIFT);
        convertRealToResultRegister(&SXY, REGISTER_X, amNone);
        runtime.temporaryInformation = TI_COV;
    }
}

pub export fn fnSampleCovariance(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void { //sxy
    _ = unusedButMandatoryParameter;
    var SXY: real_t = undefined;
    var TT: real_t = undefined;
    if (checkMinimumDataPoints(const_2())) {
        centredProductSum(SIGMA_X(), SIGMA_Y(), .DEVIATION_X, .DEVIATION_Y, &SXY, &ctxtReal75);
        realSubtract(SIGMA_N(), const_1(), &TT, &ctxtReal34);
        realDivide(&SXY, &TT, &SXY, &ctxtReal34);
        liftStack();
        setSystemFlag(FLAG_ASLIFT);
        convertRealToResultRegister(&SXY, REGISTER_X, amNone);
        runtime.temporaryInformation = TI_SXY;
    }
}

pub export fn fnStatR(RR: *real_t, SXY: *real_t, SX: *real_t, SY: *real_t) linksection(runtime.code_section) callconv(.c) void {
    const realContext = &ctxtReal75;
    var rootX: real_t = undefined;
    var rootY: real_t = undefined;
    var TT: real_t = undefined;
    if (checkMinimumDataPoints(const_2())) {
        centredSquareSum(SIGMA_X(), SIGMA_N(), .DEVIATION_X, SX, realContext);
        centredSquareSum(SIGMA_Y(), SIGMA_N(), .DEVIATION_Y, SY, realContext);
        centredProductSum(SIGMA_X(), SIGMA_Y(), .DEVIATION_X, .DEVIATION_Y, SXY, realContext);

        realSquareRoot(SX, &rootX, realContext);
        realSquareRoot(SY, &rootY, realContext);
        realDivide(SXY, &rootX, RR, realContext);
        realDivide(RR, &rootY, RR, realContext);
        if (!realIsNaN(RR) and realCompareGreaterThan(RR, const_1())) {
            realCopy(const_1(), RR);
        } else if (!realIsNaN(RR) and realCompareLessThan(RR, const__1())) {
            realCopy(const__1(), RR);
        }

        realSubtract(SIGMA_N(), const_1(), &TT, realContext);
        realDivide(SX, &TT, SX, realContext);
        realSquareRoot(SX, SX, realContext);
        realDivide(SY, &TT, SY, realContext);
        realSquareRoot(SY, SY, realContext);
        realDivide(SXY, &TT, SXY, realContext);
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
        convertRealToResultRegister(&RR, REGISTER_X, amNone);
        runtime.temporaryInformation = TI_CORR;
    }
}

pub export fn fnStatSMI(SMI: *real_t) linksection(runtime.code_section) callconv(.c) void {
    var absCXY: real_t = undefined;
    var CXX: real_t = undefined;
    var CXY: real_t = undefined;
    var ratio: real_t = undefined;
    var residualSum: real_t = undefined;
    var scale2: real_t = undefined;
    var denominator: real_t = undefined;
    if (checkMinimumDataPoints(const_2())) {
        centredSquareSum(SIGMA_X(), SIGMA_N(), .DEVIATION_X, &CXX, &ctxtReal75);
        centredProductSum(SIGMA_X(), SIGMA_Y(), .DEVIATION_X, .DEVIATION_Y, &CXY, &ctxtReal75);
        realCopyAbs(&CXY, &absCXY);
        if (realCompareLessEqual(&absCXY, &CXX)) {
            realDivide(&CXY, &CXX, &ratio, &ctxtReal75);
            centredResidualSquareSum(SIGMA_X(), SIGMA_Y(), .DEVIATION_X, .DEVIATION_Y, &ratio, false, &residualSum);
        } else {
            realDivide(&CXX, &CXY, &ratio, &ctxtReal75);
            centredResidualSquareSum(SIGMA_X(), SIGMA_Y(), .DEVIATION_X, .DEVIATION_Y, &ratio, true, &residualSum);
        }
        realFMA(&ratio, &ratio, const_1(), &scale2, &ctxtReal39);
        realSubtract(SIGMA_N(), const_1(), &denominator, &ctxtReal39);
        realMultiply(&denominator, &scale2, &denominator, &ctxtReal39);
        realDivide(&residualSum, &denominator, SMI, &ctxtReal39);
        realSquareRoot(SMI, SMI, &ctxtReal39);
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
        convertRealToResultRegister(&SMI, REGISTER_X, amNone);
        runtime.temporaryInformation = TI_SMI;
    }
}

pub export fn processCurvefitSA(SA0: *real_t, SA1: *real_t) linksection(runtime.code_section) callconv(.c) bool {
    const realContext = &ctxtReal75; // Summation data with 75 digits
    var RR: real_t = undefined;
    var MX: real_t = undefined;
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
    var CXX: real_t = undefined;
    var CXY: real_t = undefined;
    var meanX: real_t = undefined;
    var residualSum: real_t = undefined;
    var slope: real_t = undefined;

    //LINF:   SA0 & SA1: RR2, n, Sy, Sx, Sx^2, Mx^2
    //EXPF:   new value for SY2, SY and use REX
    //POWERF: new values for SX2, SX,  SY2, SY, MX
    //LOGF:   new values for SX2, SX, MX
    //ORTOF:  new values same as LINF

    if (checkMinimumDataPoints(const_3())) {
        realSetZero(&aa0);
        realSetZero(&aa1);
        realSetZero(&aa2);

        if (lrChosen == 0) { //if lrChosen contains something, the stat data exists, otherwise set it to linear.
            lrChosen = CF_LINEAR_FITTING;
        }
        //Replaced fnStatR (&RR, &SXY, &SX, &SY);
        processCurvefitSelectionAll(lrChosen, &RR, &MX, &MX2, &SX2, &SY2, &SMI, &aa0, &aa1, &aa2);
        realMultiply(&RR, &RR, &RR2, realContext); //   --> r^2

        var sumX: *const real_t = SIGMA_X();
        var sumY: *const real_t = SIGMA_Y();
        var sourceX: deviationSource_t = .DEVIATION_X;
        var sourceY: deviationSource_t = .DEVIATION_Y;
        switch (orOrtho(lrChosen)) {
            CF_LINEAR_FITTING, CF_ORTHOGONAL_FITTING => {},
            CF_EXPONENTIAL_FITTING => {
                sumY = sigma(IDX_SIGMA_lnY);
                sourceY = .DEVIATION_LNY;
            },
            CF_POWER_FITTING => {
                sumX = sigma(IDX_SIGMA_lnX);
                sumY = sigma(IDX_SIGMA_lnY);
                sourceX = .DEVIATION_LNX;
                sourceY = .DEVIATION_LNY;
            },
            CF_LOGARITHMIC_FITTING => {
                sumX = sigma(IDX_SIGMA_lnX);
                sourceX = .DEVIATION_LNX;
            },
            else => {
                displayCalcErrorMessage(ERROR_NO_ERRORS_CALCULABLE, ERR_REGISTER_LINE);
                moreInfoOnError("In function processCurvefitSA:", "No errors are calculable for the selected/chosen model!", null, null);
                return false;
            },
        }

        centredSquareSum(sumX, SIGMA_N(), sourceX, &CXX, &ctxtReal75);
        centredProductSum(sumX, sumY, sourceX, sourceY, &CXY, &ctxtReal75);
        realDivide(&CXY, &CXX, &slope, &ctxtReal75);
        centredResidualSquareSum(sumX, sumY, sourceX, sourceY, &slope, false, &residualSum);

        realSubtract(SIGMA_N(), const_2(), &TT, &ctxtReal39);
        realMultiply(&TT, &CXX, &UU, &ctxtReal39);
        realDivide(&residualSum, &UU, SA1, &ctxtReal39);
        realSquareRoot(SA1, SA1, &ctxtReal39);

        realDivide(sumX, SIGMA_N(), &meanX, &ctxtReal75);
        realDivide(&CXX, SIGMA_N(), &SS, &ctxtReal39);
        realFMA(&meanX, &meanX, &SS, &SS, &ctxtReal39);
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
