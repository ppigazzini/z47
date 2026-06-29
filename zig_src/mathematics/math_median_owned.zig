// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/mathematics/median.c: median / quartiles / MAD / IQR /
// percentile of the STATS matrix. UNCOVERED by the testSuite (no gate); this is
// a faithful line-by-line translation preserving the exact real_t operation
// order and the exact sort. All static helpers stay private; fnMedianXY/
// fnLowerQuartileXY/fnUpperQuartileXY/fnMADXY/fnIQRXY/fnPercentileXY are exported
// with C linkage.
//
// Sort comparator: the C uses libc qsort(data, n, sizeof(real_t), statsRealCompare)
// where statsRealCompare does realCompare(r1, r2, &compare, &ctxtReal75) then
// returns 0 / -1 / +1 from realIsZero / realIsNegative(&compare). To be
// byte-identical (incl. any NaN ordering qsort produces from this comparator) we
// extern libc qsort and reimplement the SAME comparator exported with C linkage,
// so the sort is the identical algorithm fed the identical comparator.
//
// USE_PERCENTILE_FOR_MEDIAN is undefined (0) in c47, so the #else branches of
// computeQ1Sorted / computeQ3Sorted are ported.
//
// Matrix access: statMx is the char[8] scratch; findNamedVariable("STATS") gives
// the register, isStatsMatrix(&rows, statMx) validates it. linkToRealMatrixRegister
// links a real34Matrix_t; X column is matrixElements[i*cols], Y column is
// matrixElements[i*cols + 1]; real34ToReal converts each. data is allocC47Blocks(
// rows * REAL_SIZE_IN_BLOCKS(75)) where REAL_SIZE_IN_BLOCKS(75) == 15 (60 bytes,
// matching sizeof(real_t)); data+i strides sizeof(real_t)==60.
// Real ops: uInt32ToReal, realMultiply/realToIntegralValue(DEC_ROUND_DOWN)/
// realToInt32C47/realSubtract/realAdd (all &ctxtReal39 unless noted), linpol,
// realChangeSign, const_1on2.
// TI_* are the real defines.h values; FLAG_ASLIFT == 0xc023 (real value).

const runtime = @import("math_command_wrappers_runtime.zig");

const real_t = runtime.real_t;
const real34_t = runtime.real34_t;
const realContext_t = runtime.realContext_t;
const calcRegister_t = runtime.calcRegister_t;
const real34Matrix_t = runtime.real34Matrix_t;

const REGISTER_X = runtime.REGISTER_X;
const REGISTER_Y = runtime.REGISTER_Y;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const NIM_REGISTER_LINE: calcRegister_t = 100; // = REGISTER_X (was 105 = REGISTER_B)

const FLAG_ASLIFT: i32 = 0xc023;
const ERROR_NO_SUMMATION_DATA: u8 = 28;
const ERROR_RAM_FULL: u8 = 11;
const DEC_ROUND_DOWN = runtime.DEC_ROUND_DOWN;
const NOPARAM: u16 = 9876;

const REAL_SIZE_IN_BLOCKS_75: usize = 15;

const TI_MEDIANX_MEDIANY: u8 = 60;
const TI_Q1X_Q1Y: u8 = 61;
const TI_Q3X_Q3Y: u8 = 62;
const TI_MADX_MADY: u8 = 63;
const TI_IQRX_IQRY: u8 = 64;
const TI_PCTILEX_PCTILEY: u8 = 66;

const realIsZero = runtime.realIsZero;
const realIsNegative = runtime.realIsNegative;
const realIsNaN = runtime.realIsNaN;
const realMultiply = runtime.realMultiply;
const realSubtract = runtime.realSubtract;
const realAdd = runtime.realAdd;
const realChangeSign = runtime.realChangeSign;
const realSetZero = runtime.realSetZero;
const realSetOne = runtime.realSetOne;
const realToIntegralValue = runtime.realToIntegralValue;
const realToInt32C47 = runtime.realToInt32C47;
const realCompareLessThan = runtime.realCompareLessThan;
const uInt32ToReal = runtime.uInt32ToReal;
const liftStack = runtime.liftStack;
const setSystemFlag = runtime.setSystemFlag;
const fnDrop = runtime.fnDrop;
const adjustResult = runtime.adjustResult;
const getRegisterAsReal = runtime.getRegisterAsReal;
const convertRealToReal34ResultRegister = runtime.convertRealToReal34ResultRegister;
const real34ToReal = runtime.real34ToReal;
const linkToRealMatrixRegister = runtime.linkToRealMatrixRegister;
const displayCalcErrorMessage = runtime.displayCalcErrorMessage;

extern var ctxtReal39: realContext_t;
extern var ctxtReal75: realContext_t;
extern var statMx: [8]u8;

extern fn decNumberCompare(res: *real_t, op1: *const real_t, op2: *const real_t, ctxt: *realContext_t) *real_t;
inline fn realCompare(op1: *const real_t, op2: *const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberCompare(res, op1, op2, ctxt);
}
extern fn decNumberCopy(res: *real_t, source: *const real_t) *real_t;
inline fn realCopy(source: *const real_t, destination: *real_t) void {
    _ = decNumberCopy(destination, source);
}

extern fn linpol(a: *const real_t, b: *const real_t, p: *const real_t, res: *real_t) void;
extern fn checkMinimumDataPoints(n: *const real_t) bool;
extern fn findNamedVariable(variableName: [*:0]const u8) calcRegister_t;
extern fn isStatsMatrix(rows: *u16, mx: [*:0]const u8) bool;
extern fn allocC47Blocks(sizeInBlocks: usize) ?*anyopaque;
extern fn freeC47Blocks(pcMemPtr: ?*anyopaque, sizeInBlocks: usize) void;
extern fn qsort(base: ?*anyopaque, nmemb: usize, size: usize, compar: *const fn (?*const anyopaque, ?*const anyopaque) callconv(.c) c_int) void;

// Blob constants.
const constants = @extern([*]align(4) const u8, .{ .name = "constants" });
inline fn cstR(comptime off: u32) *const real_t {
    return @ptrCast(@alignCast(constants + off));
}
const OFF_const_1: u32 = 4856;
const OFF_const_3: u32 = 5012;
const OFF_const_100: u32 = 7532;
const OFF_const_1on2: u32 = 4580;
inline fn const_1() *const real_t {
    return cstR(OFF_const_1);
}
inline fn const_3() *const real_t {
    return cstR(OFF_const_3);
}
inline fn const_100() *const real_t {
    return cstR(OFF_const_100);
}
inline fn const_1on2() *const real_t {
    return cstR(OFF_const_1on2);
}

const REAL_SIZE_IN_BYTES_75: usize = 60;
inline fn dataAt(data: [*]u8, index: usize) *real_t {
    return @ptrCast(@alignCast(data + index * REAL_SIZE_IN_BYTES_75));
}

export fn statsRealCompare(v1: ?*const anyopaque, v2: ?*const anyopaque) linksection(runtime.code_section) callconv(.c) c_int {
    const r1: *const real_t = @ptrCast(@alignCast(v1));
    const r2: *const real_t = @ptrCast(@alignCast(v2));
    var compare: real_t = undefined;

    realCompare(r1, r2, &compare, &ctxtReal75);

    if (realIsZero(&compare)) {
        return 0;
    }
    if (realIsNegative(&compare)) {
        return -1;
    }
    return 1;
}

const StatsFn = *const fn (data: [*]u8, n: u16, arg: ?*const real_t, res: *real_t) callconv(.c) void;

// Compute an arbitrary percentile. per is [0, 1] rather than a percentage.
fn computePercentileSorted(data: [*]u8, n: u16, p: *const real_t, percentile: *real_t) linksection(runtime.code_section) void {
    var d: real_t = undefined;
    var t: real_t = undefined;
    var k: i32 = undefined;

    uInt32ToReal(@as(u32, n) + 1, &d);
    realMultiply(&d, p, &t, &ctxtReal39);
    realToIntegralValue(&t, &d, DEC_ROUND_DOWN, &ctxtReal39);
    k = realToInt32C47(&d, null);

    if (k >= @as(i32, n)) {
        realCopy(dataAt(data, @as(usize, n) - 1), percentile);
    } else if (k < 1) {
        realCopy(dataAt(data, 0), percentile);
    } else {
        realSubtract(&t, &d, &d, &ctxtReal39); // d = FP(position)
        linpol(dataAt(data, @as(usize, @intCast(k)) - 1), dataAt(data, @intCast(k)), &d, percentile);
    }
}

fn computePercentileUnsorted(data: [*]u8, n: u16, x: ?*const real_t, percentile: *real_t) linksection(runtime.code_section) callconv(.c) void {
    qsort(data, n, REAL_SIZE_IN_BYTES_75, &statsRealCompare);
    computePercentileSorted(data, n, x.?, percentile);
}

fn computeMedianSorted(data: [*]u8, n: u16, median: *real_t) linksection(runtime.code_section) void {
    // Compute directly rather than using the percentile function to avoid rounding
    if ((n & 1) != 0) { // Odd number of values
        realCopy(dataAt(data, n / 2), median);
    } else { // Even number of values
        realAdd(dataAt(data, n / 2 - 1), dataAt(data, n / 2), median, &ctxtReal39);
        realMultiply(median, const_1on2(), median, &ctxtReal39);
    }
}

fn computeQ1Sorted(data: [*]u8, n: u16, quartile: *real_t) linksection(runtime.code_section) void {
    computeMedianSorted(data, n / 2, quartile);
}

fn computeQ3Sorted(data: [*]u8, n: u16, quartile: *real_t) linksection(runtime.code_section) void {
    computeMedianSorted(@ptrCast(dataAt(data, @as(usize, n) / 2 + (n & 1))), n / 2, quartile);
}

fn computeMedianUnsorted(data: [*]u8, n: u16, unusedButMandatoryParameter: ?*const real_t, median: *real_t) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    qsort(data, n, REAL_SIZE_IN_BYTES_75, &statsRealCompare);
    computeMedianSorted(data, n, median);
}

fn computeQ1Unsorted(data: [*]u8, n: u16, unusedButMandatoryParameter: ?*const real_t, quartile: *real_t) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    qsort(data, n, REAL_SIZE_IN_BYTES_75, &statsRealCompare);
    computeQ1Sorted(data, n, quartile);
}

fn computeQ3Unsorted(data: [*]u8, n: u16, unusedButMandatoryParameter: ?*const real_t, quartile: *real_t) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    qsort(data, n, REAL_SIZE_IN_BYTES_75, &statsRealCompare);
    computeQ3Sorted(data, n, quartile);
}

fn getXvalues(n: *u16) linksection(runtime.code_section) ?[*]u8 {
    var stats: real34Matrix_t = undefined;
    var rows: u16 = undefined;
    var cols: u16 = undefined;
    var i: u16 = undefined;
    var regStats: calcRegister_t = undefined;

    setStatMx();
    regStats = findNamedVariable(@ptrCast(&statMx));
    if (!isStatsMatrix(&rows, @ptrCast(&statMx))) {
        displayCalcErrorMessage(ERROR_NO_SUMMATION_DATA, ERR_REGISTER_LINE, REGISTER_X);
        return null;
    }
    const data_raw = allocC47Blocks(@as(usize, rows) * REAL_SIZE_IN_BLOCKS_75);
    if (data_raw == null) {
        displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
        return null;
    }
    const data: [*]u8 = @ptrCast(data_raw.?);
    linkToRealMatrixRegister(regStats, &stats);
    cols = stats.header.matrixColumns;
    i = 0;
    while (i < rows) : (i += 1) {
        real34ToReal(matrixElem(&stats, @as(usize, i) * cols), dataAt(data, i));
    }
    n.* = rows;
    return data;
}

fn getYvalues(data: [*]u8) linksection(runtime.code_section) void {
    var stats: real34Matrix_t = undefined;
    var rows: u16 = undefined;
    var cols: u16 = undefined;
    var i: u16 = undefined;
    var regStats: calcRegister_t = undefined;

    setStatMx();
    regStats = findNamedVariable(@ptrCast(&statMx));
    linkToRealMatrixRegister(regStats, &stats);
    rows = stats.header.matrixRows;
    cols = stats.header.matrixColumns;
    i = 0;
    while (i < rows) : (i += 1) {
        real34ToReal(matrixElem(&stats, @as(usize, i) * cols + 1), dataAt(data, i));
    }
}

inline fn setStatMx() void {
    const s = "STATS";
    inline for (s, 0..) |ch, idx| {
        statMx[idx] = ch;
    }
    statMx[s.len] = 0;
}

inline fn matrixElem(stats: *real34Matrix_t, index: usize) *const real34_t {
    return @ptrCast(&stats.matrixElements[index]);
}

fn doStatsOperation(func: StatsFn, minDataPoints: *const real_t, arg: ?*const real_t, message: u8) linksection(runtime.code_section) void {
    var n: u16 = undefined;
    var x: real_t = undefined;

    if (checkMinimumDataPoints(minDataPoints)) {
        const data = getXvalues(&n);
        if (data != null) {
            liftStack();
            setSystemFlag(FLAG_ASLIFT);
            liftStack();

            func(data.?, n, arg, &x);
            convertRealToReal34ResultRegister(&x, REGISTER_X);

            getYvalues(data.?);
            func(data.?, n, arg, &x);
            convertRealToReal34ResultRegister(&x, REGISTER_Y);

            freeC47Blocks(data.?, @as(usize, n) * REAL_SIZE_IN_BLOCKS_75);
            runtime.temporaryInformation = message;
            adjustResult(REGISTER_X, false, false, -1, -1, -1);
            adjustResult(REGISTER_Y, false, false, -1, -1, -1);
        }
    }
}

pub export fn fnMedianXY(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    doStatsOperation(&computeMedianUnsorted, const_1(), null, TI_MEDIANX_MEDIANY);
}

pub export fn fnLowerQuartileXY(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    doStatsOperation(&computeQ1Unsorted, const_3(), null, TI_Q1X_Q1Y);
}

pub export fn fnUpperQuartileXY(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    doStatsOperation(&computeQ3Unsorted, const_3(), null, TI_Q3X_Q3Y);
}

// Sort the data and compute the median absolute deviation
fn computeMAD(data: [*]u8, n: u16, unusedButMandatoryParameter: ?*const real_t, mad: *real_t) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var i: u16 = undefined;

    computeMedianUnsorted(data, n, null, mad);
    i = 0;
    while (i < n) : (i += 1) {
        realSubtract(dataAt(data, i), mad, dataAt(data, i), &ctxtReal39);
        if (realIsNegative(dataAt(data, i))) {
            realChangeSign(dataAt(data, i));
        }
    }
    computeMedianUnsorted(data, n, null, mad);
}

pub export fn fnMADXY(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    doStatsOperation(&computeMAD, const_1(), null, TI_MADX_MADY);
}

// Sort the data and compute the inter-quartile range
fn computeIQR(data: [*]u8, n: u16, unusedButMandatoryParameter: ?*const real_t, iqr: *real_t) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var t: real_t = undefined;

    computeQ1Unsorted(data, n, null, &t);
    computeQ3Sorted(data, n, iqr);
    realSubtract(iqr, &t, iqr, &ctxtReal39);
}

pub export fn fnIQRXY(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    doStatsOperation(&computeIQR, const_3(), null, TI_IQRX_IQRY);
}

pub export fn fnPercentileXY(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var p: real_t = undefined;

    if (!getRegisterAsReal(REGISTER_X, &p)) {
        return;
    }

    // Range saturate if out of scope and scale away percentage
    if (realIsNegative(&p)) {
        realSetZero(&p);
    } else if (realCompareLessThan(&p, const_100())) {
        p.exponent -= 2; // p = p / 100
    } else if (!realIsNaN(&p)) {
        realSetOne(&p);
    }
    fnDrop(NOPARAM);
    doStatsOperation(&computePercentileUnsorted, const_1(), &p, TI_PCTILEX_PCTILEY);
}
