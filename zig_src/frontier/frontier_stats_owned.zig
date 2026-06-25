// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/stats.c: the Sigma+/Sigma- accumulator engine over the
// 28 statistical sums (75-digit reals), the STATS matrix bookkeeping
// (isStatsMatrixN/isStatsMatrix, add/remove rows, reload/clear/init/calc of
// the sums), the sum/min/max/range readouts and the histogram section
// (LOBIN/HIBIN/NBINS, STATS->HISTO conversion). This is a faithful,
// line-by-line port of the C.
//
// ABI surface other owners depend on (must keep identical signatures):
//   - checkMinimumDataPoints / isStatsMatrix / isStatsMatrixN: externed by the
//     mathematics owners (mean/variance/percentSigma/median/linpol pipeline).
//   - calcSigma / clearStatisticalSums: externed by the store owner.
//   - fnClSigma(u16): externed by state/register_metadata_clear_sigma_owned.
//   - fnSigmaAddRem(u16): externed by math_command_wrappers.
// The statisticalSumsPointer / statMx / statisticalSumsUpdate globals stay
// defined in c47.c (compiled through the c47_legacy.c shim) and are externed
// here, exactly as the other Zig owners do.
//
// stats.c is not reachable from the testSuite; verification is by build/link
// across every target plus the boundary gates.

const frontier_build_options = @import("frontier_build_options");
const extra_info: bool = frontier_build_options.extra_info_on_calc_error;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const DECNUMUNITS = 25;
const real_t = extern struct {
    digits: i32,
    exponent: i32,
    bits: u8,
    lsu: [DECNUMUNITS]u16,
};
const real34_t = extern struct { bytes: [16]u8 };
const realContext_t = extern struct {
    digits: i32,
    emax: i32,
    emin: i32,
    round: c_int,
    traps: u32,
    status: u32,
    clamp: u8,
};
const matrixHeader_t = packed struct(u32) {
    matrixRows: u12,
    matrixColumns: u12,
    mtag: u6,
    notUsed: u2,
};
const real34Matrix_t = extern struct { header: matrixHeader_t, matrixElements: ?[*]real34_t };
const calcRegister_t = i16;
const angularMode_t = c_int;

// sizeof(real_t) must be 60 bytes: SIGMA_* index statisticalSumsPointer as a
// real_t array and REAL_SIZE_IN_BLOCKS(75) == 15 blocks == 60 bytes.
comptime {
    if (@sizeOf(real_t) != 60) @compileError("real_t must be 60 bytes");
}

// decNumber bits.
const DECNEG: u8 = 0x80;
const DECINF: u8 = 0x40;
const DECNAN: u8 = 0x20;
const DECSNAN: u8 = 0x10;
const DECSPECIAL: u8 = DECINF | DECNAN | DECSNAN;

// ---------------------------------------------------------------------------
// Constants / enum values (verified against defines.h / items.h / stats.h)
// ---------------------------------------------------------------------------
const dtReal34: u32 = 1;
const dtReal34Matrix: u32 = 6;

const amNone: angularMode_t = 5;

const ERROR_NONE: u8 = 0;
const ERROR_RAM_FULL: u8 = 11;
const ERROR_TOO_FEW_DATA: u8 = 15;
const ERROR_MATRIX_MISMATCH: u8 = 21;
const ERROR_NO_SUMMATION_DATA: u8 = 28;
const ERROR_NO_MATRIX_INDEXED: u8 = 38;
const ERROR_NOT_ENOUGH_MEMORY_FOR_NEW_MATRIX: u8 = 39;

const REGISTER_X: calcRegister_t = 100;
const REGISTER_Y: calcRegister_t = 101;
const REGISTER_Z: calcRegister_t = 102;
const FIRST_NAMED_VARIABLE: u16 = 256;
const INVALID_VARIABLE: calcRegister_t = 2199;
const ERR_REGISTER_LINE: calcRegister_t = REGISTER_Z;
const NIM_REGISTER_LINE: calcRegister_t = REGISTER_X;

const FLAG_ASLIFT: c_uint = 0xc023;

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
const SUM_XMIN = 24;
const SUM_XMAX = 25;
const SUM_YMIN = 26;
const SUM_YMAX = 27;
const NUMBER_OF_STATISTICAL_SUMS: i32 = 28;

// REAL_SIZE_IN_BLOCKS(75) == 15 (realType.h: (10 + 2*(75/3) bytes) / 4).
const REAL_75_SIZE_IN_BLOCKS: usize = 15;
const REAL34_SIZE_IN_BLOCKS: u16 = 4;

const SIGMA_PLUS: u16 = 1;
const SIGMA_MINUS: u16 = 2;

const TI_STATISTIC_SUMS: u8 = 7;
const TI_SUMX_SUMY: u8 = 16;
const TI_XMIN_YMIN: u8 = 34;
const TI_XMAX_YMAX: u8 = 35;
const TI_STATISTIC_HISTO: u8 = 46;
const TI_RANGEX_RANGEY: u8 = 65;

const ITM_X: u16 = 573;
const ITM_Y: u16 = 574;
const ITM_M_DIM: u16 = 1526;

const PLOT_NOTHING: u16 = 5;
const RECALC_SUMS = 105;
const NUMBER_OF_ERROR_CODES = 127;
const SIZE_OF_EACH_ERROR_MESSAGE = 48;

// screen.h
const timed: u8 = 0;
const force: u8 = 1;

const DEC_ROUND_DOWN: c_int = 5;
const DEC_ROUND_CEILING: c_int = 0;

// ---------------------------------------------------------------------------
// Constant blob (offsets from the generated constantPointers.h)
// ---------------------------------------------------------------------------
const constants = @extern([*]const u8, .{ .name = "constants" });
const OFF_const_1 = 4856;
const OFF_const_3 = 5012;
const OFF_const34_1 = 16312;
const OFF_const_1on2 = 4580;

inline fn cstR(offset: u32) *align(1) const real_t {
    return @ptrCast(constants + offset);
}
inline fn cst34(offset: u32) *align(1) const real34_t {
    return @ptrCast(constants + offset);
}

// ---------------------------------------------------------------------------
// Globals (defined in c47.c / plotstat.c, compiled through the legacy shims)
// ---------------------------------------------------------------------------
extern var statisticalSumsPointer: ?[*]real_t;
extern var statisticalSumsUpdate: bool;
extern var statMx: [8]u8;
extern var errorMessage: [*c]u8;
extern const errorMessages: [NUMBER_OF_ERROR_CODES][SIZE_OF_EACH_ERROR_MESSAGE]u8;
extern var lastErrorCode: u8;
extern var temporaryInformation: u8;
extern var lrChosen: u16;
extern var lastPlotMode: u16;
extern var plotSelection: u16;
extern var PLOT_ZOOM: i8;
extern var drawHistogram: u8;
extern var histElementXorY: i16;
extern var loBinR: real34_t;
extern var nBins: real34_t;
extern var hiBinR: real34_t;
extern var SAVED_SIGMA_LASTX: real_t;
extern var SAVED_SIGMA_LASTY: real_t;
extern var SAVED_SIGMA_lastAddRem: i8;
extern var ctxtReal34: realContext_t;
extern var ctxtReal39: realContext_t;
extern var ctxtReal75: realContext_t;

// ---------------------------------------------------------------------------
// Function externs
// ---------------------------------------------------------------------------
extern fn getRegisterDataType(regist: calcRegister_t) u32;
extern fn displayCalcErrorMessage(error_code: u8, err_message_line: calcRegister_t, err_register_line: calcRegister_t) void;
const c_moreInfoOnError = @extern(*const fn (m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) callconv(.c) void, .{ .name = "moreInfoOnError" });
extern fn sprintf(buf: [*c]u8, fmt: [*:0]const u8, ...) c_int;
extern fn strcpy(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn findNamedVariable(variableName: [*c]const u8) calcRegister_t;
extern fn allocateNamedVariable(variableName: [*c]const u8, dataType: c_uint, fullDataSizeInBlocks: u16) void;
extern fn allocateNamedMatrix(name: [*c]const u8, rows: u16, cols: u16) calcRegister_t;
extern fn appendRowAtMatrixRegister(regist: calcRegister_t) bool;
extern fn redimMatrixRegister(regist: calcRegister_t, rows: u16, cols: u16, dimMode: u16) bool;
extern fn fnDeleteVariable(regist: u16) void;
extern fn clearRegister(regist: calcRegister_t) void;
extern fn linkToRealMatrixRegister(regist: calcRegister_t, linkedMatrix: *real34Matrix_t) void;
extern fn allocC47Blocks(sizeInBlocks: usize) ?*anyopaque;
extern fn freeC47Blocks(pcMemPtr: ?*anyopaque, sizeInBlocks: usize) void;
extern fn printStatus(row: u8, line1: [*c]const u8, forced: u8) void;
extern fn saveLastX() bool;
extern fn liftStack() void;
extern fn setSystemFlag(flag: c_uint) void;
extern fn getSystemFlag(flag: c_int) bool;
extern fn getRegisterAsRealQuiet(reg: calcRegister_t, val: *real_t) bool;
extern fn getRegisterAsReal(reg: calcRegister_t, val: *real_t) bool;
extern fn badTypeError(reg: calcRegister_t) void;
extern fn convertRealToResultRegister(x: *const real_t, dest: calcRegister_t, angle: angularMode_t) void;
extern fn realToIntegralValue(source: *const real_t, destination: *real_t, mode: c_int, realContext: *realContext_t) void;
extern fn WP34S_Ln(x: *const real_t, res: *real_t, realContext: *realContext_t) void;
extern fn realSetZero(r: *real_t) void;
extern fn realSetPlusInfinity(r: *real_t) void;
extern fn realSetMinusInfinity(r: *real_t) void;
extern fn realCompareEqual(number1: *align(1) const real_t, number2: *align(1) const real_t) bool;
extern fn realCompareGreaterThan(number1: *align(1) const real_t, number2: *align(1) const real_t) bool;
extern fn realCompareGreaterEqual(number1: *align(1) const real_t, number2: *align(1) const real_t) bool;
extern fn realCompareLessThan(number1: *align(1) const real_t, number2: *align(1) const real_t) bool;
extern fn realCompareLessEqual(number1: *align(1) const real_t, number2: *align(1) const real_t) bool;
extern fn real34CompareLessThan(number1: *align(1) const real34_t, number2: *align(1) const real34_t) bool;

// decNumber / decQuad externs behind the real*/real34* macros.
extern fn decNumberAdd(r: *real_t, a: *align(1) const real_t, b: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberSubtract(r: *real_t, a: *align(1) const real_t, b: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberMultiply(r: *real_t, a: *align(1) const real_t, b: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberDivide(r: *real_t, a: *align(1) const real_t, b: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberSquareRoot(r: *real_t, a: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberCopy(r: *real_t, src: *align(1) const real_t) *real_t;
extern fn decimal128ToNumber(src: *align(1) const real34_t, dst: *real_t) *real_t;
extern fn decimal128FromNumber(dst: *align(1) real34_t, src: *const real_t, ctx: *realContext_t) *align(1) real34_t;
extern fn decQuadToInt32(r: *align(1) const real34_t, ctx: *realContext_t, round: c_int) i32;
extern fn decQuadAdd(r: *align(1) real34_t, a: *align(1) const real34_t, b: *align(1) const real34_t, ctx: *realContext_t) *align(1) real34_t;
extern fn decQuadZero(r: *align(1) real34_t) *align(1) real34_t;

// ---------------------------------------------------------------------------
// Inline wrappers (the C macros)
// ---------------------------------------------------------------------------
inline fn moreInfoOnError(m1: [*:0]const u8, m2: ?[*:0]const u8) void {
    if (comptime extra_info) c_moreInfoOnError(m1, m2, null, null);
}
inline fn sigma(sum: usize) *real_t {
    return &statisticalSumsPointer.?[sum];
}
inline fn realIsSpecial(v: *align(1) const real_t) bool {
    return (v.bits & DECSPECIAL) != 0;
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
inline fn real34ToReal(src: *align(1) const real34_t, dst: *real_t) void {
    _ = decimal128ToNumber(src, dst);
}
inline fn realToReal34(src: *const real_t, dst: *align(1) real34_t) void {
    _ = decimal128FromNumber(dst, src, &ctxtReal34);
}
inline fn real34ToInt32(src: *align(1) const real34_t) i32 {
    return decQuadToInt32(src, &ctxtReal34, DEC_ROUND_DOWN);
}
inline fn real34Add(a: *align(1) const real34_t, b: *align(1) const real34_t, res: *align(1) real34_t) void {
    _ = decQuadAdd(res, a, b, &ctxtReal34);
}
inline fn real34SetZero(dst: *align(1) real34_t) void {
    _ = decQuadZero(dst);
}
inline fn int32ToReal(src: i32, dst: *real_t) void {
    _ = decNumberFromInt32(dst, src);
}
extern fn decNumberFromInt32(r: *real_t, v: i32) *real_t;

// ===========================================================================
// isStatsMatrixN / isStatsMatrix
// ===========================================================================
pub export fn isStatsMatrixN(rows: *u16, regStats: calcRegister_t) callconv(.c) bool {
    rows.* = 0;
    if (regStats == INVALID_VARIABLE) {
        return false;
    } else {
        if (getRegisterDataType(regStats) != dtReal34Matrix) {
            return false;
        } else {
            var stats: real34Matrix_t = undefined;
            linkToRealMatrixRegister(regStats, &stats);
            rows.* = stats.header.matrixRows;
            if (@as(u16, stats.header.matrixColumns) != 2) {
                return false;
            }
        }
    }
    return true;
}

pub export fn isStatsMatrix(rows: *u16, mx: [*c]const u8) callconv(.c) bool {
    const regStats: calcRegister_t = findNamedVariable(mx);
    return isStatsMatrixN(rows, regStats);
}

// ===========================================================================
// Accumulation engine (static in the C)
// ===========================================================================
const AccumulateFn = *const fn (sum: *real_t, z: *align(1) const real_t) bool;
const MinMaxFn = *const fn (r1: *const real_t, r2: *const real_t) bool;
const accumulateFuncs_t = struct {
    accumulate: AccumulateFn,
    minimum: MinMaxFn,
    maximum: MinMaxFn,
};

fn accumulateToSigma(x: *const real_t, y: *const real_t, accum: *const accumulateFuncs_t) void {
    var tmpReal1: real_t = undefined;
    var tmpReal2: real_t = undefined;
    var tmpReal3: real_t = undefined;
    const acc: AccumulateFn = accum.accumulate;
    const realContext: *realContext_t = &ctxtReal75; // Summation data with 75 digits

    // xmax & ymax
    _ = accum.maximum(x, y);

    // xmin & ymin
    _ = accum.minimum(x, y);

    // n
    if (!acc(sigma(0), cstR(OFF_const_1))) {
        return;
    }

    // sigma x
    if (!acc(sigma(SUM_X), x)) {
        return;
    }

    // sigma y
    if (!acc(sigma(SUM_Y), y)) {
        return;
    }

    // sigma x^2
    realMultiply(x, x, &tmpReal1, realContext);
    if (!acc(sigma(SUM_X2), &tmpReal1)) {
        return;
    }

    // sigma x^3
    realMultiply(&tmpReal1, x, &tmpReal2, realContext);
    if (!acc(sigma(SUM_X3), &tmpReal2)) {
        return;
    }

    // sigma x^4
    realMultiply(&tmpReal2, x, &tmpReal2, realContext);
    if (!acc(sigma(SUM_X4), &tmpReal2)) {
        return;
    }

    // sigma x^2*y
    realMultiply(&tmpReal1, y, &tmpReal2, realContext);
    if (!acc(sigma(SUM_X2Y), &tmpReal2)) {
        return;
    }

    // sigma x^2/y
    realDivide(&tmpReal1, y, &tmpReal2, realContext);
    if (!acc(sigma(SUM_X2onY), &tmpReal2)) {
        return;
    }

    // sigma 1/x^2
    realDivide(cstR(OFF_const_1), &tmpReal1, &tmpReal2, realContext);
    if (!acc(sigma(SUM_1onX2), &tmpReal2)) {
        return;
    }

    // sigma y^2
    realMultiply(y, y, &tmpReal1, realContext);
    if (!acc(sigma(SUM_Y2), &tmpReal1)) {
        return;
    }

    // sigma 1/y^2
    realDivide(cstR(OFF_const_1), &tmpReal1, &tmpReal2, realContext);
    if (!acc(sigma(SUM_1onY2), &tmpReal2)) {
        return;
    }

    // sigma x*y
    realMultiply(x, y, &tmpReal1, realContext);
    if (!acc(sigma(SUM_XY), &tmpReal1)) {
        return;
    }

    // sigma ln(x)
    WP34S_Ln(x, &tmpReal1, realContext);
    realCopy(&tmpReal1, &tmpReal3);
    if (!acc(sigma(SUM_lnX), &tmpReal1)) {
        return;
    }

    // sigma ln^2(x)
    realMultiply(&tmpReal1, &tmpReal1, &tmpReal2, realContext);
    if (!acc(sigma(SUM_ln2X), &tmpReal2)) {
        return;
    }

    // sigma y*ln(x)
    realMultiply(&tmpReal1, y, &tmpReal1, realContext);
    if (!acc(sigma(SUM_YlnX), &tmpReal1)) {
        return;
    }

    // sigma ln(y)
    WP34S_Ln(y, &tmpReal1, realContext);
    if (!acc(sigma(SUM_lnY), &tmpReal1)) {
        return;
    }

    // sigma ln(x)*ln(y)
    realMultiply(&tmpReal3, &tmpReal1, &tmpReal3, realContext);
    if (!acc(sigma(SUM_lnXlnY), &tmpReal3)) {
        return;
    }

    // sigma ln(y)/x
    realDivide(&tmpReal1, x, &tmpReal2, realContext);
    if (!acc(sigma(SUM_lnYonX), &tmpReal2)) {
        return;
    }

    // sigma ln^2(y)
    realMultiply(&tmpReal1, &tmpReal1, &tmpReal2, realContext);
    if (!acc(sigma(SUM_ln2Y), &tmpReal2)) {
        return;
    }

    // sigma x*ln(y)
    realMultiply(&tmpReal1, x, &tmpReal1, realContext);
    if (!acc(sigma(SUM_XlnY), &tmpReal1)) {
        return;
    }

    // sigma x^2*ln(y)
    realMultiply(&tmpReal1, x, &tmpReal1, realContext);
    if (!acc(sigma(SUM_X2lnY), &tmpReal1)) {
        return;
    }

    // sigma 1/x
    realDivide(cstR(OFF_const_1), x, &tmpReal1, realContext);
    if (!acc(sigma(SUM_1onX), &tmpReal1)) {
        return;
    }

    // sigma x/y
    realDivide(x, y, &tmpReal1, realContext);
    if (!acc(sigma(SUM_XonY), &tmpReal1)) {
        return;
    }

    // sigma 1/y
    realDivide(cstR(OFF_const_1), y, &tmpReal1, realContext);
    if (!acc(sigma(SUM_1onY), &tmpReal1)) {
        return;
    }
}

fn addMax(x: *const real_t, y: *const real_t) bool {
    if (realCompareGreaterThan(x, sigma(SUM_XMAX))) {
        realCopy(x, sigma(SUM_XMAX));
    }

    if (realCompareGreaterThan(y, sigma(SUM_YMAX))) {
        realCopy(y, sigma(SUM_YMAX));
    }

    return true;
}

fn addMin(x: *const real_t, y: *const real_t) bool {
    if (realCompareLessThan(x, sigma(SUM_XMIN))) {
        realCopy(x, sigma(SUM_XMIN));
    }

    if (realCompareLessThan(y, sigma(SUM_YMIN))) {
        realCopy(y, sigma(SUM_YMIN));
    }

    return true;
}

fn subMax(x: *const real_t, y: *const real_t) bool {
    if (realIsSpecial(x) or realIsSpecial(sigma(SUM_XMAX)) or
        realIsSpecial(y) or realIsSpecial(sigma(SUM_YMAX)) or
        realCompareEqual(x, sigma(SUM_XMAX)) or
        realCompareEqual(y, sigma(SUM_YMAX)))
    {
        calcMax(1);
        return false;
    }
    return true;
}

fn subMin(x: *const real_t, y: *const real_t) bool {
    if (realIsSpecial(x) or realIsSpecial(sigma(SUM_XMIN)) or
        realIsSpecial(y) or realIsSpecial(sigma(SUM_YMIN)) or
        realCompareEqual(x, sigma(SUM_XMIN)) or
        realCompareEqual(y, sigma(SUM_YMIN)))
    {
        calcMin(1);
        return false;
    }
    return true;
}

fn accumulate(sum: *real_t, x: *align(1) const real_t) bool {
    realAdd(sum, x, sum, &ctxtReal75);
    return true;
}

fn unaccumulate(sum: *real_t, x: *align(1) const real_t) bool {
    if (realIsSpecial(sum) or realIsSpecial(x)) {
        calcSigma(1);
        return false;
    }
    realSubtract(sum, x, sum, &ctxtReal75);
    return true;
}

fn addSigma(x: *const real_t, y: *const real_t) void {
    const acc = accumulateFuncs_t{
        .accumulate = &accumulate,
        .minimum = &addMin,
        .maximum = &addMax,
    };
    accumulateToSigma(x, y, &acc);
}

fn subSigma(x: *const real_t, y: *const real_t) void {
    const deacc = accumulateFuncs_t{
        .accumulate = &unaccumulate,
        .minimum = &subMin,
        .maximum = &subMax,
    };
    accumulateToSigma(x, y, &deacc);
}

// ===========================================================================
// checkMinimumDataPoints
// ===========================================================================
pub export fn checkMinimumDataPoints(n: *align(1) const real_t) callconv(.c) bool {
    if (statisticalSumsPointer == null) {
        displayCalcErrorMessage(ERROR_NO_SUMMATION_DATA, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            moreInfoOnError("In function checkMinimumDataPoints:", "There is no statistical data available!");
        }
        return false;
    }

    if (realCompareLessThan(sigma(0), n)) {
        displayCalcErrorMessage(ERROR_TOO_FEW_DATA, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            moreInfoOnError("In function checkMinimumDataPoints:", "There is insufficient statistical data available!");
        }
        return false;
    }
    return true;
}

// ===========================================================================
// Sums lifecycle
// ===========================================================================
pub export fn reLoadStatisticalSums() callconv(.c) void {
    var rows: u16 = undefined;
    _ = strcpy(&statMx, "STATS"); // any stats operation restores the stats matrix. The purpose of the changed names are just to be able to exchange the matrixes for reading and graphing
    const regStats: calcRegister_t = findNamedVariable(&statMx);
    if (isStatsMatrixN(&rows, regStats) and rows > 0) {
        calcSigma(0);
    }
}

pub export fn clearStatisticalSums() callconv(.c) void {
    if (statisticalSumsPointer != null) {
        var sum: i32 = 0;
        while (sum < NUMBER_OF_STATISTICAL_SUMS - 4) : (sum += 1) {
            realSetZero(sigma(@intCast(sum)));
        }
        realSetPlusInfinity(sigma(SUM_XMIN));
        realSetPlusInfinity(sigma(SUM_YMIN));
        realSetMinusInfinity(sigma(SUM_XMAX));
        realSetMinusInfinity(sigma(SUM_YMAX));
    }
}

pub export fn initStatisticalSums() callconv(.c) void {
    if (statisticalSumsUpdate) {
        if (statisticalSumsPointer == null) {
            statisticalSumsPointer = @ptrCast(@alignCast(allocC47Blocks(@as(usize, @intCast(NUMBER_OF_STATISTICAL_SUMS)) * REAL_75_SIZE_IN_BLOCKS)));
            clearStatisticalSums();
            _ = strcpy(&statMx, "STATS"); // any stats operation restores the stats matrix. The purpose of the changed names are just to be able to exchange the matrixes for reading and graphing
        } else {
            displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
        }
    }
}

// ===========================================================================
// calcMax / calcMin / calcSigma
// ===========================================================================
fn calcMax(maxOffset: u16) void {
    realSetMinusInfinity(sigma(SUM_XMAX));
    realSetMinusInfinity(sigma(SUM_YMAX));

    const regStats: calcRegister_t = findNamedVariable(&statMx);
    if (regStats != INVALID_VARIABLE) {
        var stats: real34Matrix_t = undefined;
        linkToRealMatrixRegister(regStats, &stats);
        const rows: u16 = stats.header.matrixRows;
        const cols: u16 = stats.header.matrixColumns;

        var x: real_t = undefined;
        var y: real_t = undefined;
        var i: u16 = 0;
        while (@as(i32, i) < @as(i32, rows) - @as(i32, maxOffset)) : (i += 1) {
            real34ToReal(@ptrCast(&stats.matrixElements.?[@as(usize, i) * cols]), &x);
            real34ToReal(@ptrCast(&stats.matrixElements.?[@as(usize, i) * cols + 1]), &y);
            _ = addMax(&x, &y);
        }
    }
}

fn calcMin(maxOffset: u16) void {
    realSetPlusInfinity(sigma(SUM_XMIN));
    realSetPlusInfinity(sigma(SUM_YMIN));

    const regStats: calcRegister_t = findNamedVariable(&statMx);
    if (regStats != INVALID_VARIABLE) {
        var stats: real34Matrix_t = undefined;
        linkToRealMatrixRegister(regStats, &stats);
        const rows: u16 = stats.header.matrixRows;
        const cols: u16 = stats.header.matrixColumns;
        var x: real_t = undefined;
        var y: real_t = undefined;
        var i: u16 = 0;
        while (@as(i32, i) < @as(i32, rows) - @as(i32, maxOffset)) : (i += 1) {
            real34ToReal(@ptrCast(&stats.matrixElements.?[@as(usize, i) * cols]), &x);
            real34ToReal(@ptrCast(&stats.matrixElements.?[@as(usize, i) * cols + 1]), &y);
            _ = addMin(&x, &y);
        }
    }
}

pub export fn calcSigma(maxOffset: u16) callconv(.c) void {
    clearStatisticalSums();
    if (statisticalSumsPointer == null) {
        initStatisticalSums();
    }
    const regStats: calcRegister_t = findNamedVariable(&statMx);
    var rr: u16 = 1;
    if (regStats >= @as(calcRegister_t, @intCast(FIRST_NAMED_VARIABLE)) and isStatsMatrixN(&rr, regStats) and regStats != INVALID_VARIABLE) {
        var stats: real34Matrix_t = undefined;
        linkToRealMatrixRegister(regStats, &stats);
        const rows: u16 = stats.header.matrixRows;
        const cols: u16 = stats.header.matrixColumns;
        var x: real_t = undefined;
        var y: real_t = undefined;
        var aa: [100]u8 = undefined;
        var i: u16 = 0;
        while (@as(i32, i) < @as(i32, rows) - @as(i32, maxOffset)) : (i += 1) {
            _ = sprintf(&aa, "%s%s (%u of %u)", @as([*c]const u8, @ptrCast(&errorMessages[RECALC_SUMS])), @as([*c]const u8, @ptrCast(&statMx)), @as(c_uint, i), @as(c_uint, @bitCast(@as(c_int, rows) - @as(c_int, maxOffset))));
            printStatus(0, &aa, timed);
            real34ToReal(@ptrCast(&stats.matrixElements.?[@as(usize, i) * cols]), &x);
            real34ToReal(@ptrCast(&stats.matrixElements.?[@as(usize, i) * cols + 1]), &y);
            addSigma(&x, &y);
        }
    }
    printStatus(0, " ", force);
}

// ===========================================================================
// STATS matrix helpers (static in the C)
// ===========================================================================
fn getLastRowStatsMatrix(x: *real_t, y: *real_t) void {
    var rows: u16 = 0;
    var cols: u16 = undefined;
    const regStats: calcRegister_t = findNamedVariable(&statMx);

    if (regStats != INVALID_VARIABLE) {
        var stats: real34Matrix_t = undefined;
        linkToRealMatrixRegister(regStats, &stats);
        rows = stats.header.matrixRows;
        cols = stats.header.matrixColumns;
        real34ToReal(@ptrCast(&stats.matrixElements.?[@as(usize, rows - 1) * cols]), x);
        real34ToReal(@ptrCast(&stats.matrixElements.?[@as(usize, rows - 1) * cols + 1]), y);
    } else {
        displayCalcErrorMessage(ERROR_NO_SUMMATION_DATA, ERR_REGISTER_LINE, REGISTER_X); // Invalid input data type for this operation
        if (comptime extra_info) {
            _ = sprintf(errorMessage, "STATS matrix not found");
            moreInfoOnError("In function getLastRowStatsMatrix:", errorMessage);
        }
    }
}

fn AddtoStatsMatrix(x: *real_t, y: *real_t) void {
    var rows: u16 = 0;
    var cols: u16 = undefined;
    _ = strcpy(&statMx, "STATS"); // any stats operation restores the stats matrix. The purpose of the changed names are just to be able to exchange the matrixes for reading and graphing
    var regStats: calcRegister_t = findNamedVariable(&statMx);
    if (!isStatsMatrix(&rows, &statMx)) {
        regStats = allocateNamedMatrix(&statMx, 1, 2);
        var stats: real34Matrix_t = undefined;
        linkToRealMatrixRegister(regStats, &stats);
        // realMatrixInit(&stats, 1, 2);
    } else {
        if (appendRowAtMatrixRegister(regStats)) {} else {
            regStats = INVALID_VARIABLE;
        }
    }
    if (regStats != INVALID_VARIABLE) {
        var stats: real34Matrix_t = undefined;
        linkToRealMatrixRegister(regStats, &stats);
        rows = stats.header.matrixRows;
        cols = stats.header.matrixColumns;
        realToReal34(x, @ptrCast(&stats.matrixElements.?[@as(usize, rows - 1) * cols]));
        realToReal34(y, @ptrCast(&stats.matrixElements.?[@as(usize, rows - 1) * cols + 1]));
    } else {
        displayCalcErrorMessage(ERROR_NOT_ENOUGH_MEMORY_FOR_NEW_MATRIX, ERR_REGISTER_LINE, REGISTER_X); // Invalid input data type for this operation
        if (comptime extra_info) {
            _ = sprintf(errorMessage, "additional matrix line not added; rows = %i", @as(c_int, rows));
            moreInfoOnError("In function AddtoStatsMatrix:", errorMessage);
        }
    }
}

fn removeLastRowFromStatsMatrix() void {
    var rows: u16 = 0;
    _ = strcpy(&statMx, "STATS"); // any stats operation restores the stats matrix. The purpose of the changed names are just to be able to exchange the matrixes for reading and graphing
    if (!isStatsMatrix(&rows, &statMx)) {
        displayCalcErrorMessage(ERROR_NO_SUMMATION_DATA, ERR_REGISTER_LINE, REGISTER_X); // Invalid input data type for this operation
        if (comptime extra_info) {
            _ = sprintf(errorMessage, "no STATS matrix");
            moreInfoOnError("In function removeLastRowFromStatsMatrix:", errorMessage);
        }
        return;
    }

    var regStats: calcRegister_t = findNamedVariable(&statMx);
    if (rows <= 1) {
        fnClSigma(0);
        return;
    } else {
        if (!redimMatrixRegister(regStats, rows - 1, 2, ITM_M_DIM)) {
            regStats = INVALID_VARIABLE;
        }
    }
    if (regStats == INVALID_VARIABLE) {
        displayCalcErrorMessage(ERROR_NOT_ENOUGH_MEMORY_FOR_NEW_MATRIX, ERR_REGISTER_LINE, REGISTER_X); // Invalid input data type for this operation
        if (comptime extra_info) {
            _ = sprintf(errorMessage, "matrix/line not removed");
            moreInfoOnError("In function removeLastRowFromStatsMatrix:", errorMessage);
        }
    }
}

fn fnClHisto(deleteVariable: bool) calcRegister_t {
    var regHisto: calcRegister_t = findNamedVariable("HISTO");
    if (regHisto == INVALID_VARIABLE) {
        allocateNamedVariable("HISTO", dtReal34, REAL34_SIZE_IN_BLOCKS);
        regHisto = findNamedVariable("HISTO");
    }
    if (regHisto == INVALID_VARIABLE) {
        displayCalcErrorMessage(ERROR_NO_MATRIX_INDEXED, ERR_REGISTER_LINE, REGISTER_X); // Invalid input data type for this operation
        if (comptime extra_info) {
            _ = sprintf(errorMessage, "HISTO matrix not created");
            moreInfoOnError("In function fnClHisto:", errorMessage);
        }
        return INVALID_VARIABLE;
    }
    if (deleteVariable) {
        fnDeleteVariable(@intCast(regHisto));
        return INVALID_VARIABLE;
    } else {
        clearRegister(regHisto);
        return regHisto;
    }
}

// ===========================================================================
// setStatisticalSumsUpdate
// ===========================================================================
pub export fn setStatisticalSumsUpdate(para: bool) callconv(.c) void {
    // if going off auto, or confirming it is still on auto off, clear sums
    if (!para) {
        freeC47Blocks(@ptrCast(statisticalSumsPointer), @as(usize, @intCast(NUMBER_OF_STATISTICAL_SUMS)) * REAL_75_SIZE_IN_BLOCKS);
        statisticalSumsPointer = null;
        if (lastErrorCode != ERROR_NONE) {
            return;
        }
    }
    if (statisticalSumsUpdate and !para) {
        // It is on auto and it is being switched off auto. Stats sums already cleared, just set the flag.
        statisticalSumsUpdate = false;
    } else if (!statisticalSumsUpdate and para) {
        // it is off auto and it is swithing on to auto update. Clear and sums and calc up any existing matrix.
        statisticalSumsUpdate = true;
        initStatisticalSums(); // calcSigma is implied
        if (lastErrorCode != ERROR_NONE) {
            return;
        }
        reLoadStatisticalSums();
    }
    // it it is off auto and switched off, it must remain so. Not further actions
    // if it is on  auto and switched on, it must remain so. Not further actions
}

// ===========================================================================
// fnClSigma
// ===========================================================================
pub export fn fnClSigma(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    _ = fnClHisto(true);
    _ = strcpy(&statMx, "STATS"); // any stats operation restores the stats matrix. The purpose of the changed names are just to be able to exchange the matrixes for reading and graphing
    var regStats: calcRegister_t = findNamedVariable(&statMx);
    if (regStats == INVALID_VARIABLE) {
        allocateNamedVariable(&statMx, dtReal34, REAL34_SIZE_IN_BLOCKS);
        regStats = findNamedVariable(&statMx);
    }
    if (regStats == INVALID_VARIABLE) {
        displayCalcErrorMessage(ERROR_NO_MATRIX_INDEXED, ERR_REGISTER_LINE, REGISTER_X); // Invalid input data type for this operation
        if (comptime extra_info) {
            _ = sprintf(errorMessage, "STATS matrix not created");
            moreInfoOnError("In function fnClSigma:", errorMessage);
        }
    }
    fnDeleteVariable(@bitCast(regStats));
    lrChosen = 0; // linear regression selection
    lastPlotMode = PLOT_NOTHING; // last selected  plotmode
    plotSelection = 0; // Currently selected linear regression mode
    PLOT_ZOOM = 0; // Currently selected plot zoom level
    drawHistogram = 0;
    histElementXorY = 0;

    freeC47Blocks(@ptrCast(statisticalSumsPointer), @as(usize, @intCast(NUMBER_OF_STATISTICAL_SUMS)) * REAL_75_SIZE_IN_BLOCKS);
    statisticalSumsPointer = null;
}

// ===========================================================================
// fnSigmaAddRem
// ===========================================================================
pub export fn fnSigmaAddRem(plusMinusSelection: u16) callconv(.c) void {
    var x: real_t = undefined;
    var y: real_t = undefined;

    lrChosen = 0;

    if (plusMinusSelection == SIGMA_PLUS) { // SIGMA+
        if (getRegisterAsRealQuiet(REGISTER_X, &x) and getRegisterAsRealQuiet(REGISTER_Y, &y)) {
            if (statisticalSumsUpdate and statisticalSumsPointer == null) {
                initStatisticalSums();
                if (lastErrorCode != ERROR_NONE) {
                    return;
                }
                reLoadStatisticalSums();
            }

            if (statisticalSumsUpdate) {
                addSigma(&x, &y);
            }
            AddtoStatsMatrix(&x, &y);
            realCopy(&x, &SAVED_SIGMA_LASTX);
            realCopy(&y, &SAVED_SIGMA_LASTY);
            SAVED_SIGMA_lastAddRem = @intCast(SIGMA_PLUS);

            if (statisticalSumsPointer != null) {
                temporaryInformation = TI_STATISTIC_SUMS;
            }
        } else if (getRegisterDataType(REGISTER_X) == dtReal34Matrix and plusMinusSelection == SIGMA_PLUS) {
            var matrix: real34Matrix_t = undefined;
            linkToRealMatrixRegister(REGISTER_X, &matrix);

            if (@as(u16, matrix.header.matrixColumns) == 2) {
                if (statisticalSumsUpdate and statisticalSumsPointer == null) {
                    initStatisticalSums();
                    if (lastErrorCode != ERROR_NONE) {
                        return;
                    }
                    reLoadStatisticalSums();
                } else {
                    setStatisticalSumsUpdate(statisticalSumsUpdate); // ensure it deletes the sums anyway if clear
                    if (lastErrorCode != ERROR_NONE) {
                        return;
                    }
                }

                if (!saveLastX()) {
                    return;
                }
                var i: u16 = 0;
                while (i < @as(u16, matrix.header.matrixRows)) : (i += 1) {
                    real34ToReal(@ptrCast(&matrix.matrixElements.?[@as(usize, i) * 2]), &x);
                    real34ToReal(@ptrCast(&matrix.matrixElements.?[@as(usize, i) * 2 + 1]), &y);
                    if (statisticalSumsUpdate) {
                        addSigma(&x, &y);
                    }
                    AddtoStatsMatrix(&x, &y);
                }

                liftStack();
                convertRealToResultRegister(&y, REGISTER_Y, amNone);
                convertRealToResultRegister(&x, REGISTER_X, amNone);
                if (statisticalSumsPointer != null) {
                    temporaryInformation = TI_STATISTIC_SUMS;
                }
            } else {
                displayCalcErrorMessage(ERROR_MATRIX_MISMATCH, ERR_REGISTER_LINE, REGISTER_X); // Invalid input data type for this operation
                if (comptime extra_info) {
                    _ = sprintf(errorMessage, "cannot use %u\x80\xd7%d-matrix as statistical data!", @as(c_uint, @as(u16, matrix.header.matrixRows)), @as(c_int, @as(u16, matrix.header.matrixColumns)));
                    moreInfoOnError("In function fnSigmaAddRem:", errorMessage);
                }
            }
        } else {
            badTypeError(REGISTER_X);
        }
    } else if (plusMinusSelection == SIGMA_MINUS) { // SIGMA-
        if (checkMinimumDataPoints(cstR(OFF_const_1))) {
            getLastRowStatsMatrix(&x, &y);
            if (statisticalSumsUpdate) {
                subSigma(&x, &y);
            }
            removeLastRowFromStatsMatrix();

            if (statisticalSumsPointer != null) {
                temporaryInformation = TI_STATISTIC_SUMS;
            }
            liftStack();
            setSystemFlag(FLAG_ASLIFT);
            liftStack();
            convertRealToResultRegister(&x, REGISTER_X, amNone);
            convertRealToResultRegister(&y, REGISTER_Y, amNone);

            realCopy(&x, &SAVED_SIGMA_LASTX);
            realCopy(&y, &SAVED_SIGMA_LASTY);
            SAVED_SIGMA_lastAddRem = @intCast(SIGMA_MINUS);
        }
    }
}

// ===========================================================================
// Sum / min / max / range readouts
// ===========================================================================
pub export fn fnStatSum(sum: u16) callconv(.c) void {
    if (checkMinimumDataPoints(cstR(OFF_const_1))) {
        liftStack();
        convertRealToResultRegister(sigma(sum), REGISTER_X, amNone);
    }
}

pub export fn fnSumXY(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (checkMinimumDataPoints(cstR(OFF_const_1))) {
        liftStack();
        setSystemFlag(FLAG_ASLIFT);
        liftStack();

        convertRealToResultRegister(sigma(SUM_X), REGISTER_X, amNone);
        convertRealToResultRegister(sigma(SUM_Y), REGISTER_Y, amNone);

        temporaryInformation = TI_SUMX_SUMY;
    }
}

pub export fn fnXmin(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (checkMinimumDataPoints(cstR(OFF_const_1))) {
        liftStack();
        setSystemFlag(FLAG_ASLIFT);
        liftStack();

        convertRealToResultRegister(sigma(SUM_XMIN), REGISTER_X, amNone);
        convertRealToResultRegister(sigma(SUM_YMIN), REGISTER_Y, amNone);

        temporaryInformation = TI_XMIN_YMIN;
    }
}

pub export fn fnXmax(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (checkMinimumDataPoints(cstR(OFF_const_1))) {
        liftStack();
        setSystemFlag(FLAG_ASLIFT);
        liftStack();

        convertRealToResultRegister(sigma(SUM_XMAX), REGISTER_X, amNone);
        convertRealToResultRegister(sigma(SUM_YMAX), REGISTER_Y, amNone);

        temporaryInformation = TI_XMAX_YMAX;
    }
}

pub export fn fnRangeXY(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var t: real_t = undefined;

    if (checkMinimumDataPoints(cstR(OFF_const_1))) {
        liftStack();
        setSystemFlag(FLAG_ASLIFT);
        liftStack();

        realSubtract(sigma(SUM_XMAX), sigma(SUM_XMIN), &t, &ctxtReal39);
        convertRealToResultRegister(&t, REGISTER_X, amNone);

        realSubtract(sigma(SUM_YMAX), sigma(SUM_YMIN), &t, &ctxtReal39);
        convertRealToResultRegister(&t, REGISTER_Y, amNone);

        temporaryInformation = TI_RANGEX_RANGEY;
    }
}

// ----------- Histogram Section -----------------

fn isHistoMatrix(rows: *u16, mx: [*c]const u8) bool {
    rows.* = 0;
    const regHisto: calcRegister_t = findNamedVariable(mx);
    if (regHisto == INVALID_VARIABLE) {
        return false;
    } else {
        if (getRegisterDataType(regHisto) != dtReal34Matrix) {
            return false;
        } else {
            var histo: real34Matrix_t = undefined;
            linkToRealMatrixRegister(regHisto, &histo);
            rows.* = histo.header.matrixRows;
            if (@as(u16, histo.header.matrixColumns) != 2) {
                return false;
            }
        }
    }
    return true;
}

fn initHistoMatrix(s: *real_t) void {
    var rows: u16 = 0;
    var cols: u16 = undefined;
    var regHisto: calcRegister_t = findNamedVariable("HISTO");
    if (!isHistoMatrix(&rows, "HISTO")) {
        regHisto = allocateNamedMatrix("HISTO", 1, 2);
        var histo: real34Matrix_t = undefined;
        linkToRealMatrixRegister(regHisto, &histo);
        // realMatrixInit(&histo, 1, 2);
    } else {
        if (appendRowAtMatrixRegister(regHisto)) {} else {
            regHisto = INVALID_VARIABLE;
        }
    }
    if (regHisto != INVALID_VARIABLE) {
        var histo: real34Matrix_t = undefined;
        linkToRealMatrixRegister(regHisto, &histo);
        rows = histo.header.matrixRows;
        cols = histo.header.matrixColumns;
        realToReal34(s, @ptrCast(&histo.matrixElements.?[@as(usize, rows - 1) * cols]));
        real34SetZero(@ptrCast(&histo.matrixElements.?[@as(usize, rows - 1) * cols + 1]));
    } else {
        displayCalcErrorMessage(ERROR_NOT_ENOUGH_MEMORY_FOR_NEW_MATRIX, ERR_REGISTER_LINE, REGISTER_X); // Invalid input data type for this operation
        if (comptime extra_info) {
            _ = sprintf(errorMessage, "additional matrix line not added; rows = %i", @as(c_int, rows));
            moreInfoOnError("In function initHistoMatrix:", errorMessage);
        }
    }
}

pub export fn fnSetLoBin(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var x: real_t = undefined;

    if (histElementXorY == -1) {
        return;
    }

    if (!getRegisterAsReal(REGISTER_X, &x)) {
        return;
    }

    realToReal34(&x, &loBinR);
    convertStatsMatrixToHistoMatrix(if (histElementXorY == 1) ITM_Y else if (histElementXorY == 0) ITM_X else @bitCast(@as(i16, -1)));
}

pub export fn fnSetHiBin(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var x: real_t = undefined;

    if (histElementXorY == -1) {
        return;
    }

    if (!getRegisterAsReal(REGISTER_X, &x)) {
        return;
    }

    realToReal34(&x, &hiBinR);
    convertStatsMatrixToHistoMatrix(if (histElementXorY == 1) ITM_Y else if (histElementXorY == 0) ITM_X else @bitCast(@as(i16, -1)));
}

pub export fn fnSetNBins(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var x: real_t = undefined;

    if (histElementXorY == -1) {
        return;
    }

    if (!getRegisterAsReal(REGISTER_X, &x)) {
        return;
    }

    realToReal34(&x, &nBins);
    convertStatsMatrixToHistoMatrix(if (histElementXorY == 1) ITM_Y else if (histElementXorY == 0) ITM_X else @bitCast(@as(i16, -1)));
}

pub export fn fnConvertStatsToHisto(statsVariableToHistogram: u16) callconv(.c) void {
    var rows: u16 = undefined;
    var lb: real_t = undefined;
    var hb: real_t = undefined;
    var nb: real_t = undefined;
    var nn: real_t = undefined;

    if (statMx[0] == 'S' and isStatsMatrix(&rows, &statMx)) {
        if (checkMinimumDataPoints(cstR(OFF_const_3))) {
            if (statsVariableToHistogram == ITM_Y) {
                realToReal34(sigma(SUM_YMIN), &loBinR); // set up the user variables from auto estimates from the data
                realToReal34(sigma(SUM_YMAX), &hiBinR); // set up the user variables from auto estimates from the data
                histElementXorY = 1;
            } else if (statsVariableToHistogram == ITM_X) {
                realToReal34(sigma(SUM_XMIN), &loBinR); // set up the user variables from auto estimates from the data
                realToReal34(sigma(SUM_XMAX), &hiBinR); // set up the user variables from auto estimates from the data
                histElementXorY = 0;
            } else {
                return;
            }

            real34ToReal(&loBinR, &lb);
            real34ToReal(&hiBinR, &hb);
            realCopy(sigma(0), &nn);
            realSquareRoot(&nn, &nb, &ctxtReal39);
            realToIntegralValue(&nb, &nb, DEC_ROUND_CEILING, &ctxtReal39); // number of bins are defaulted to square root of data points  nb = CEIL (sqrt(SIGMA_N))
            realToReal34(&nb, &nBins); // set up the user variables from auto estimates from the data

            convertStatsMatrixToHistoMatrix(statsVariableToHistogram);
        }
    } else {
        displayCalcErrorMessage(ERROR_MATRIX_MISMATCH, ERR_REGISTER_LINE, REGISTER_X); // Invalid input data type for this operation
        if (comptime extra_info) {
            _ = sprintf(errorMessage, "Wrong statistical matrix is selected: %s!", @as([*c]const u8, @ptrCast(&statMx)));
            moreInfoOnError("In function fnConvertStatsToHisto:", errorMessage);
        }
        return;
    }
}

// Histogram bin limits are:
// data points larger than loBinR (inclusive) and smaller than hiBinR (exclusive), except the right most bin right hand limit is inclusive)
fn convertStatsMatrixToHistoMatrix(statsVariableToHistogram: u16) void {
    _ = statsVariableToHistogram;
    var ii: real_t = undefined;
    var lb: real_t = undefined;
    var hb: real_t = undefined;
    var nb: real_t = undefined;
    var bw: real_t = undefined;
    var bwon2: real_t = undefined;
    var i: u16 = 0;
    var j: u16 = 0;

    if (!checkMinimumDataPoints(cstR(OFF_const_3))) {
        return;
    }
    if (statMx[0] != 'S') {
        displayCalcErrorMessage(ERROR_MATRIX_MISMATCH, ERR_REGISTER_LINE, REGISTER_X); // Invalid input data type for this operation
        if (comptime extra_info) {
            _ = sprintf(errorMessage, "Wrong statistical matrix is selected: %s!", @as([*c]const u8, @ptrCast(&statMx)));
            moreInfoOnError("In function convertStatsMatrixToHistoMatrix:", errorMessage);
        }
        return;
    }

    const regStats: calcRegister_t = findNamedVariable(&statMx); // connect to STATS matrix
    const regHisto: calcRegister_t = fnClHisto(false); // clear and connect to HISTO matrix

    if (isStatsMatrix(&i, &statMx) and regStats != INVALID_VARIABLE and regHisto != INVALID_VARIABLE) {
        real34ToReal(&loBinR, &lb);
        real34ToReal(&hiBinR, &hb);
        real34ToReal(&nBins, &nb);
        const NN: i32 = real34ToInt32(&nBins);
        realSubtract(&hb, &lb, &bw, &ctxtReal39);
        realDivide(&bw, &nb, &bw, &ctxtReal39);
        realMultiply(&bw, cstR(OFF_const_1on2), &bwon2, &ctxtReal39); // calculate bin width bw and half bin width bw_on_2

        var stats: real34Matrix_t = undefined;
        var histo: real34Matrix_t = undefined;
        linkToRealMatrixRegister(regStats, &stats);
        const rows: u16 = stats.header.matrixRows;
        const cols: u16 = stats.header.matrixColumns;
        if (cols == 2) {
            i = 0;
            while (@as(i32, i) < NN) : (i += 1) {
                int32ToReal(i, &ii);
                realAdd(&ii, cstR(OFF_const_1on2), &ii, &ctxtReal39);
                realMultiply(&ii, &bw, &ii, &ctxtReal39);
                realAdd(&ii, &lb, &ii, &ctxtReal39); // bin midpoint
                initHistoMatrix(&ii); // Set up all x-mid-points of the bins in HISTO, with 0 in y
                linkToRealMatrixRegister(regHisto, &histo);
            }

            if (isStatsMatrix(&i, &statMx) and isHistoMatrix(&i, "HISTO")) {
                i = 0;
                while (i < rows) : (i += 1) {
                    j = 0;
                    while (@as(i32, j) < NN) : (j += 1) {
                        var t: real_t = undefined;
                        var tl: real_t = undefined;
                        var th: real_t = undefined;
                        real34ToReal(@ptrCast(&stats.matrixElements.?[@as(usize, i) * cols + @as(usize, @intCast(histElementXorY))]), &t); // from X or Y, depending
                        real34ToReal(@ptrCast(&histo.matrixElements.?[@as(usize, j) * @as(u16, histo.header.matrixColumns)]), &tl); // get the bin mid x
                        realSubtract(&tl, &bwon2, &tl, &ctxtReal39); // get the bin x low
                        realAdd(&tl, &bw, &th, &ctxtReal39); // get the bin x hi
                        if ((@as(i32, j) < NN - 1 and realCompareLessThan(&t, &th) and realCompareGreaterEqual(&t, &tl)) or
                            (@as(i32, j) == NN - 1 and realCompareLessEqual(&t, &th) and realCompareGreaterEqual(&t, &tl)))
                        {
                            real34Add(@ptrCast(&histo.matrixElements.?[@as(usize, j) * @as(u16, histo.header.matrixColumns) + 1]), cst34(OFF_const34_1), @ptrCast(&histo.matrixElements.?[@as(usize, j) * @as(u16, histo.header.matrixColumns) + 1]));
                            break;
                        }
                    }
                }
            }

            liftStack();
            setSystemFlag(FLAG_ASLIFT);
            liftStack();
            setSystemFlag(FLAG_ASLIFT);
            liftStack();
            convertRealToResultRegister(&nb, REGISTER_Z, amNone);
            convertRealToResultRegister(&lb, REGISTER_Y, amNone);
            convertRealToResultRegister(&hb, REGISTER_X, amNone);
            temporaryInformation = TI_STATISTIC_HISTO;
        } else {
            displayCalcErrorMessage(ERROR_MATRIX_MISMATCH, ERR_REGISTER_LINE, REGISTER_X); // Invalid input data type for this operation
            if (comptime extra_info) {
                _ = sprintf(errorMessage, " Matrix columns not right: %s!", @as([*c]const u8, @ptrCast(&statMx)));
                moreInfoOnError("In function convertStatsMatrixToHistoMatrix:", errorMessage);
            }
            return;
        }
    } else {
        displayCalcErrorMessage(ERROR_MATRIX_MISMATCH, ERR_REGISTER_LINE, REGISTER_X); // Invalid input data type for this operation
        if (comptime extra_info) {
            _ = sprintf(errorMessage, " invalid STATS or HISTO variable!");
            moreInfoOnError("In function convertStatsMatrixToHistoMatrix:", errorMessage);
        }
        return;
    }
}
