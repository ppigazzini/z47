// Zig port of the MIM-routed matrix commands of src/c47/mathematics/matrix.c:
// fnGetMatrix / fnPutMatrix / fnSwapRows / fnSwapColumns (dispatched through the
// indexed-element dispatcher callByIndexedMatrix), the standalone fnRowColSum
// and fnPNorm, and getMatrixFromRegister (loads a matrix register into the MIM
// edit pointer). The numeric helpers (getArg, _swap*, get/putMatrix*,
// _row_columnNorm) are static in matrix.c, so they stay file-local here; only
// the public commands are bridge-renamed.
const std = @import("std");
const math_mim_util = @import("../math_mim_util.zig"); // std-only matrix-input helpers
const runtime = @import("../math_command_wrappers_runtime.zig");
const math_real_predicates = @import("../math_real_predicates.zig");
const math_comparison_reals = @import("../math_comparison_reals.zig"); // M-callconv: Zig-to-Zig
const math_matrix_elementwise = @import("elementwise.zig"); // M-callconv: Zig-to-Zig
const math_matrix_euclidean_norm_command = @import("euclidean_norm_command.zig"); // M-callconv: Zig-to-Zig
const math_matrix_swap = @import("swap.zig"); // M-callconv: Zig-to-Zig

const real_t = runtime.real_t;
const real34_t = runtime.real34_t;
const complex34_t = runtime.complex34_t;
const real34Matrix_t = runtime.real34Matrix_t;
const complex34Matrix_t = runtime.complex34Matrix_t;
const matrixHeader_t = runtime.matrixHeader_t;
const calcRegister_t = runtime.calcRegister_t;

const REGISTER_X = runtime.REGISTER_X;
const REGISTER_Y = runtime.REGISTER_Y;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const dtReal34Matrix = runtime.dtReal34Matrix;
const dtComplex34Matrix = runtime.dtComplex34Matrix;

const pNorm_0_NNZ: u16 = 0;
const pNorm_1_CNORM: u16 = 1;
const pNorm_2_ENORM: u16 = 2;
const pNorm_inf_RNORM: u16 = 924; // ITM_INFINITY

const any34Matrix_t = extern union {
    header: matrixHeader_t,
    realMatrix: real34Matrix_t,
    complexMatrix: complex34Matrix_t,
};
extern var openMatrixMIMPointer: any34Matrix_t;

extern fn getIRegisterAsInt(asArrayPointer: bool) i16;
extern fn getJRegisterAsInt(asArrayPointer: bool) i16;
// realCopy / realIsPositive are decNumber macros (not linkable symbols).
inline fn realCopy(source: *const real_t, destination: *real_t) void {
    destination.* = source.*;
}
// C realType.h:140: #define realIsPositive(x) (((bits) & 0x80) == 0x00) — sign bit
// clear, INCLUDING +0 (do NOT exclude zero; that diverged from C and made MIM
// swap/get/put range guards reject zero-valued indices/sizes at edges). The shared
// predicate keeps that convention.
const realIsPositive = math_real_predicates.realIsPositive;

inline fn rmEl(m: *const real34Matrix_t, i: usize) *real34_t {
    const e: [*]real34_t = @ptrCast(m.matrixElements);
    return &e[i];
}
inline fn cmEl(m: *const complex34Matrix_t, i: usize) *complex34_t {
    const e: [*]complex34_t = @ptrCast(m.matrixElements);
    return &e[i];
}
inline fn truncToU16(v: i32) u16 {
    return math_mim_util.truncToU16(v);
}

// getArg -- read REGISTER_X/Y as an integral real_t (long integer or real34
// rounded toward zero); error on any other type.
fn getArg(regist: calcRegister_t, arg: *real_t) bool {
    if (runtime.getRegisterDataType(regist) == runtime.dtLongInteger) {
        runtime.convertLongIntegerRegisterToReal(regist, arg, &runtime.ctxtReal39);
    } else if (runtime.getRegisterDataType(regist) == runtime.dtReal34) {
        runtime.real34ToReal(runtime.registerReal34Data(regist), arg);
        runtime.realToIntegralValue(arg, arg, runtime.DEC_ROUND_DOWN, &runtime.ctxtReal39);
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        if (runtime.extra_info_on_calc_error) {
            var buf: [80]u8 = undefined;
            const tn = runtime.getRegisterDataTypeName(regist, true, false);
            const m = runtime.bufPrintZ(&buf, "cannot accept {s} as the argument", .{tn}) catch "bad arg";
            runtime.moreInfoOnError("In function getArg:", m, null, null);
        }
        return false;
    }
    return true;
}

// --- row/column swap (fnSwapRows / fnSwapColumns) -------------------------

fn _swapReal(matrix: *real34Matrix_t, isRow: bool) bool {
    var ry: real_t = undefined;
    var rx: real_t = undefined;
    var rlimit: real_t = undefined;
    runtime.int32ToReal(if (isRow) matrix.header.matrixRows else matrix.header.matrixColumns, &rlimit);
    if (!getArg(REGISTER_Y, &ry) or !getArg(REGISTER_X, &rx)) return false;
    const a = truncToU16(runtime.realToInt32C47(&ry, null));
    const b = truncToU16(runtime.realToInt32C47(&rx, null));
    if (realIsPositive(&rx) and realIsPositive(&ry) and math_comparison_reals.realCompareLessEqual(&rx, &rlimit) and math_comparison_reals.realCompareLessEqual(&ry, &rlimit)) {
        if (!runtime.realCompareEqual(&ry, &rx)) {
            if (isRow) {
                runtime.realMatrixSwapRows(matrix, matrix, a - 1, b - 1);
            } else {
                math_matrix_swap.realMatrixSwapColumns(matrix, matrix, a - 1, b - 1);
            }
        }
    } else {
        swapOutOfRange(isRow, a, b, "In function _swapReal:");
        return false;
    }
    return true;
}

fn _swapComplex(matrix: *complex34Matrix_t, isRow: bool) bool {
    var ry: real_t = undefined;
    var rx: real_t = undefined;
    var rlimit: real_t = undefined;
    runtime.int32ToReal(if (isRow) matrix.header.matrixRows else matrix.header.matrixColumns, &rlimit);
    if (!getArg(REGISTER_Y, &ry) or !getArg(REGISTER_X, &rx)) return false;
    const a = truncToU16(runtime.realToInt32C47(&ry, null));
    const b = truncToU16(runtime.realToInt32C47(&rx, null));
    if (realIsPositive(&rx) and realIsPositive(&ry) and math_comparison_reals.realCompareLessEqual(&rx, &rlimit) and math_comparison_reals.realCompareLessEqual(&ry, &rlimit)) {
        if (!runtime.realCompareEqual(&ry, &rx)) {
            if (isRow) {
                math_matrix_swap.complexMatrixSwapRows(matrix, matrix, a - 1, b - 1);
            } else {
                math_matrix_swap.complexMatrixSwapColumns(matrix, matrix, a - 1, b - 1);
            }
        }
    } else {
        swapOutOfRange(isRow, a, b, "In function swapComplex:");
        return false;
    }
    return true;
}

fn swapOutOfRange(isRow: bool, a: u16, b: u16, fnName: [*:0]const u8) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
    if (runtime.extra_info_on_calc_error) {
        var buf: [64]u8 = undefined;
        const m = runtime.bufPrintZ(&buf, "{s} {d} and/or {d} out of range", .{ if (isRow) "rows" else "columns", a, b }) catch "out of range";
        runtime.moreInfoOnError(fnName, m, null, null);
    }
}

fn swapRowsReal(matrix: *real34Matrix_t) callconv(.c) bool {
    return _swapReal(matrix, true);
}
fn swapColumnsReal(matrix: *real34Matrix_t) callconv(.c) bool {
    return _swapReal(matrix, false);
}
fn swapRowsComplex(matrix: *complex34Matrix_t) callconv(.c) bool {
    return _swapComplex(matrix, true);
}
fn swapColumnsComplex(matrix: *complex34Matrix_t) callconv(.c) bool {
    return _swapComplex(matrix, false);
}

// --- get/put submatrix (fnGetMatrix / fnPutMatrix) -----------------------

fn getMatrixReal(matrix: *real34Matrix_t) callconv(.c) bool {
    var ry: real_t = undefined;
    var rx: real_t = undefined;
    var rrows: real_t = undefined;
    var rcols: real_t = undefined;
    const i = getIRegisterAsInt(true);
    const j = getJRegisterAsInt(true);
    const cols: usize = matrix.header.matrixColumns;
    runtime.int32ToReal(@as(i32, matrix.header.matrixRows) - i, &rrows);
    runtime.int32ToReal(@as(i32, matrix.header.matrixColumns) - j, &rcols);
    if (!getArg(REGISTER_Y, &ry) or !getArg(REGISTER_X, &rx)) return false;
    const a = truncToU16(runtime.realToInt32C47(&ry, null));
    const b = truncToU16(runtime.realToInt32C47(&rx, null));
    if (realIsPositive(&rx) and realIsPositive(&ry) and math_comparison_reals.realCompareLessEqual(&rx, &rcols) and math_comparison_reals.realCompareLessEqual(&ry, &rrows)) {
        var mat: real34Matrix_t = undefined;
        runtime.fnDropY(runtime.NOPARAM);
        if (runtime.lastErrorCode == runtime.ERROR_NONE) {
            if (runtime.initMatrixRegister(REGISTER_X, a, b, false)) {
                runtime.linkToRealMatrixRegister(REGISTER_X, &mat);
                var r: usize = 0;
                while (r < a) : (r += 1) {
                    var c: usize = 0;
                    while (c < b) : (c += 1) {
                        rmEl(&mat, r * b + c).* = rmEl(matrix, (r + @as(usize, @intCast(i))) * cols + c + @as(usize, @intCast(j))).*;
                    }
                }
            } else {
                getPutRamFull("In function getMatrixReal:");
                return false;
            }
        }
    } else {
        getPutOutOfRange(a, b, "In function getMatrixReal:");
        return false;
    }
    return false;
}

fn getMatrixComplex(matrix: *complex34Matrix_t) callconv(.c) bool {
    var ry: real_t = undefined;
    var rx: real_t = undefined;
    var rrows: real_t = undefined;
    var rcols: real_t = undefined;
    const i = getIRegisterAsInt(true);
    const j = getJRegisterAsInt(true);
    const cols: usize = matrix.header.matrixColumns;
    runtime.int32ToReal(@as(i32, matrix.header.matrixRows) - i, &rrows);
    runtime.int32ToReal(@as(i32, matrix.header.matrixColumns) - j, &rcols);
    if (!getArg(REGISTER_Y, &ry) or !getArg(REGISTER_X, &rx)) return false;
    const a = truncToU16(runtime.realToInt32C47(&ry, null));
    const b = truncToU16(runtime.realToInt32C47(&rx, null));
    if (realIsPositive(&rx) and realIsPositive(&ry) and math_comparison_reals.realCompareLessEqual(&rx, &rcols) and math_comparison_reals.realCompareLessEqual(&ry, &rrows)) {
        var mat: complex34Matrix_t = undefined;
        runtime.fnDropY(runtime.NOPARAM);
        if (runtime.lastErrorCode == runtime.ERROR_NONE) {
            if (runtime.initMatrixRegister(REGISTER_X, a, b, true)) {
                runtime.linkToComplexMatrixRegister(REGISTER_X, &mat);
                var r: usize = 0;
                while (r < a) : (r += 1) {
                    var c: usize = 0;
                    while (c < b) : (c += 1) {
                        cmEl(&mat, r * b + c).* = cmEl(matrix, (r + @as(usize, @intCast(i))) * cols + c + @as(usize, @intCast(j))).*;
                    }
                }
            } else {
                getPutRamFull("In function getMatrixComplex:");
            }
        }
    } else {
        getPutOutOfRange(a, b, "In function getMatrixComplex:");
        return false;
    }
    return false;
}

fn putMatrixReal(matrix: *real34Matrix_t) callconv(.c) bool {
    const i = getIRegisterAsInt(true);
    const j = getJRegisterAsInt(true);
    if (runtime.getRegisterDataType(REGISTER_X) != dtReal34Matrix) {
        putWrongType("In function putMatrixReal:", "is not a real matrix");
        return false;
    }
    var mat: real34Matrix_t = undefined;
    runtime.linkToRealMatrixRegister(REGISTER_X, &mat);
    const cols: usize = matrix.header.matrixColumns;
    if (@as(i32, mat.header.matrixRows) + i <= matrix.header.matrixRows and @as(i32, mat.header.matrixColumns) + j <= matrix.header.matrixColumns) {
        var r: usize = 0;
        while (r < mat.header.matrixRows) : (r += 1) {
            var c: usize = 0;
            while (c < mat.header.matrixColumns) : (c += 1) {
                rmEl(matrix, (r + @as(usize, @intCast(i))) * cols + c + @as(usize, @intCast(j))).* = rmEl(&mat, r * mat.header.matrixColumns + c).*;
            }
        }
    } else {
        getPutOutOfRange(mat.header.matrixRows, mat.header.matrixColumns, "In function putMatrixReal:");
        return false;
    }
    return true;
}

fn putMatrixComplex(matrix: *complex34Matrix_t) callconv(.c) bool {
    const i = getIRegisterAsInt(true);
    const j = getJRegisterAsInt(true);
    if (runtime.getRegisterDataType(REGISTER_X) != dtComplex34Matrix) {
        putWrongType("In function putMatrixComplex:", "is not a complex matrix");
        return false;
    }
    var mat: complex34Matrix_t = undefined;
    runtime.linkToComplexMatrixRegister(REGISTER_X, &mat);
    const cols: usize = matrix.header.matrixColumns;
    if (@as(i32, mat.header.matrixRows) + i <= matrix.header.matrixRows and @as(i32, mat.header.matrixColumns) + j <= matrix.header.matrixColumns) {
        var r: usize = 0;
        while (r < mat.header.matrixRows) : (r += 1) {
            var c: usize = 0;
            while (c < mat.header.matrixColumns) : (c += 1) {
                cmEl(matrix, (r + @as(usize, @intCast(i))) * cols + c + @as(usize, @intCast(j))).* = cmEl(&mat, r * mat.header.matrixColumns + c).*;
            }
        }
    } else {
        getPutOutOfRange(mat.header.matrixRows, mat.header.matrixColumns, "In function putMatrixComplex:");
        return false;
    }
    return true;
}

fn getPutRamFull(fnName: [*:0]const u8) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, ERR_REGISTER_LINE, REGISTER_X);
    if (runtime.extra_info_on_calc_error) runtime.moreInfoOnError(fnName, "Ram full", null, null);
}
fn getPutOutOfRange(a: u16, b: u16, fnName: [*:0]const u8) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
    if (runtime.extra_info_on_calc_error) {
        var buf: [64]u8 = undefined;
        const m = runtime.bufPrintZ(&buf, "{d} \xc3\x97 {d} out of range", .{ a, b }) catch "out of range";
        runtime.moreInfoOnError(fnName, m, null, null);
    }
}
fn putWrongType(fnName: [*:0]const u8, suffix: []const u8) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    if (runtime.extra_info_on_calc_error) {
        var buf: [80]u8 = undefined;
        const tn = runtime.getRegisterDataTypeName(REGISTER_X, true, false);
        const m = runtime.bufPrintZ(&buf, "{s} {s}", .{ tn, suffix }) catch "wrong type";
        runtime.moreInfoOnError(fnName, m, null, null);
    }
}

// --- public commands ------------------------------------------------------

pub export fn fnGetMatrix(unusedParamButMandatory: u16) callconv(.c) void {
    _ = unusedParamButMandatory;
    math_matrix_elementwise.callByIndexedMatrix(&getMatrixReal, &getMatrixComplex);
}
pub export fn fnPutMatrix(unusedParamButMandatory: u16) callconv(.c) void {
    _ = unusedParamButMandatory;
    math_matrix_elementwise.callByIndexedMatrix(&putMatrixReal, &putMatrixComplex);
}
pub export fn fnSwapRows(unusedParamButMandatory: u16) callconv(.c) void {
    _ = unusedParamButMandatory;
    math_matrix_elementwise.callByIndexedMatrix(&swapRowsReal, &swapRowsComplex);
}
pub export fn fnSwapColumns(unusedParamButMandatory: u16) callconv(.c) void {
    _ = unusedParamButMandatory;
    math_matrix_elementwise.callByIndexedMatrix(&swapColumnsReal, &swapColumnsComplex);
}

pub export fn fnRowColSum(isRow: u16) callconv(.c) void {
    if (!runtime.saveLastX()) return;
    const dt = runtime.getRegisterDataType(REGISTER_X);
    if (dt == dtReal34Matrix) {
        var x: real34Matrix_t = undefined;
        var res: real34Matrix_t = undefined;
        var sum: real_t = undefined;
        var elem: real_t = undefined;
        runtime.linkToRealMatrixRegister(REGISTER_X, &x);
        const cols: usize = x.header.matrixColumns;
        const outerLimit: usize = if (isRow != 0) x.header.matrixRows else cols;
        const innerLimit: usize = if (isRow != 0) cols else x.header.matrixRows;
        if (runtime.realMatrixInit(&res, if (isRow != 0) @intCast(outerLimit) else 1, if (isRow != 0) 1 else @intCast(outerLimit))) {
            var i: usize = 0;
            while (i < outerLimit) : (i += 1) {
                runtime.realSetZero(&sum);
                var j: usize = 0;
                while (j < innerLimit) : (j += 1) {
                    runtime.real34ToReal(rmEl(&x, if (isRow != 0) i * cols + j else j * cols + i), &elem);
                    runtime.realAdd(&sum, &elem, &sum, &runtime.ctxtReal39);
                }
                runtime.realToReal34(&sum, rmEl(&res, i));
            }
            runtime.convertReal34MatrixToReal34MatrixRegister(&res, REGISTER_X);
            runtime.realMatrixFree(&res);
        } else {
            rowColSumRamFull("Ram full, 1e");
        }
    } else if (dt == dtComplex34Matrix) {
        var x: complex34Matrix_t = undefined;
        var res: complex34Matrix_t = undefined;
        var sumr: real_t = undefined;
        var sumi: real_t = undefined;
        var elem: real_t = undefined;
        runtime.linkToComplexMatrixRegister(REGISTER_X, &x);
        const cols: usize = x.header.matrixColumns;
        const outerLimit: usize = if (isRow != 0) x.header.matrixRows else cols;
        const innerLimit: usize = if (isRow != 0) cols else x.header.matrixRows;
        if (runtime.complexMatrixInit(&res, if (isRow != 0) @intCast(outerLimit) else 1, if (isRow != 0) 1 else @intCast(outerLimit))) {
            var i: usize = 0;
            while (i < outerLimit) : (i += 1) {
                runtime.realSetZero(&sumr);
                runtime.realSetZero(&sumi);
                var j: usize = 0;
                while (j < innerLimit) : (j += 1) {
                    const idx: usize = if (isRow != 0) i * cols + j else j * cols + i;
                    runtime.real34ToReal(&cmEl(&x, idx).real, &elem);
                    runtime.realAdd(&sumr, &elem, &sumr, &runtime.ctxtReal39);
                    runtime.real34ToReal(&cmEl(&x, idx).imag, &elem);
                    runtime.realAdd(&sumi, &elem, &sumi, &runtime.ctxtReal39);
                }
                runtime.realToReal34(&sumr, &cmEl(&res, i).real);
                runtime.realToReal34(&sumi, &cmEl(&res, i).imag);
            }
            runtime.convertComplex34MatrixToComplex34MatrixRegister(&res, REGISTER_X);
            runtime.complexMatrixFree(&res);
        } else {
            rowColSumRamFull("Ram full, 2f");
        }
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        if (runtime.extra_info_on_calc_error) {
            var buf: [48]u8 = undefined;
            const m = runtime.bufPrintZ(&buf, "DataType {d}", .{dt}) catch "DataType";
            runtime.moreInfoOnError("In function fnRowColSum:", m, "is not a matrix.", "");
        }
    }
    runtime.adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}

fn rowColSumRamFull(tag: [*:0]const u8) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, ERR_REGISTER_LINE, REGISTER_X);
    if (runtime.extra_info_on_calc_error) runtime.moreInfoOnError("In function fnRowColSum:", tag, null, null);
}

// _row_columnNorm -- 0-norm (non-zero count), 1-norm (max column abs-sum),
// inf-norm (max row abs-sum).
fn _row_columnNorm(pParam: u16) void {
    if (pParam != pNorm_inf_RNORM and pParam != pNorm_1_CNORM and pParam != pNorm_0_NNZ) {
        runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        return;
    }

    if (pParam == pNorm_0_NNZ) {
        if (!runtime.saveLastX()) return;
        const dt = runtime.getRegisterDataType(REGISTER_X);
        if (dt == dtReal34Matrix) {
            var x: real34Matrix_t = undefined;
            runtime.linkToRealMatrixRegister(REGISTER_X, &x);
            const n: usize = numEl(&x.header);
            var nnzi: u32 = 0;
            var k: usize = 0;
            while (k < n) : (k += 1) {
                if (!runtime.real34IsZero(rmEl(&x, k))) nnzi += 1;
            }
            writeNnz(nnzi);
        } else if (dt == dtComplex34Matrix) {
            var x: complex34Matrix_t = undefined;
            runtime.linkToComplexMatrixRegister(REGISTER_X, &x);
            const n: usize = numEl(&x.header);
            var nnzi: u32 = 0;
            var k: usize = 0;
            while (k < n) : (k += 1) {
                if (!runtime.real34IsZero(&cmEl(&x, k).real) or !runtime.real34IsZero(&cmEl(&x, k).imag)) nnzi += 1;
            }
            writeNnz(nnzi);
        } else {
            normNotMatrix();
        }
        runtime.adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
        return;
    }

    const isRow = (pParam == pNorm_inf_RNORM);
    if (!runtime.saveLastX()) return;
    const dt = runtime.getRegisterDataType(REGISTER_X);
    if (dt == dtReal34Matrix) {
        var x: real34Matrix_t = undefined;
        var norm: real_t = undefined;
        var sum: real_t = undefined;
        var elem: real_t = undefined;
        runtime.linkToRealMatrixRegister(REGISTER_X, &x);
        const cols: usize = x.header.matrixColumns;
        const outerLimit: usize = if (isRow) x.header.matrixRows else cols;
        const innerLimit: usize = if (isRow) cols else x.header.matrixRows;
        runtime.realSetZero(&norm);
        var i: usize = 0;
        while (i < outerLimit) : (i += 1) {
            runtime.realSetZero(&sum);
            var j: usize = 0;
            while (j < innerLimit) : (j += 1) {
                const idx: usize = if (isRow) i * cols + j else j * cols + i;
                runtime.real34ToReal(rmEl(&x, idx), &elem);
                runtime.realSetPositiveSign(&elem);
                runtime.realAdd(&sum, &elem, &sum, &runtime.ctxtReal39);
            }
            if (math_comparison_reals.realCompareGreaterThan(&sum, &norm)) realCopy(&sum, &norm);
        }
        writeNorm(&norm);
    } else if (dt == dtComplex34Matrix) {
        var x: complex34Matrix_t = undefined;
        var norm: real_t = undefined;
        var sum: real_t = undefined;
        var elem: real_t = undefined;
        var imag: real_t = undefined;
        runtime.linkToComplexMatrixRegister(REGISTER_X, &x);
        const cols: usize = x.header.matrixColumns;
        const outerLimit: usize = if (isRow) x.header.matrixRows else cols;
        const innerLimit: usize = if (isRow) cols else x.header.matrixRows;
        runtime.realSetZero(&norm);
        var i: usize = 0;
        while (i < outerLimit) : (i += 1) {
            runtime.realSetZero(&sum);
            var j: usize = 0;
            while (j < innerLimit) : (j += 1) {
                const idx: usize = if (isRow) i * cols + j else j * cols + i;
                runtime.real34ToReal(&cmEl(&x, idx).real, &elem);
                runtime.real34ToReal(&cmEl(&x, idx).imag, &imag);
                runtime.complexMagnitude(&elem, &imag, &elem, &runtime.ctxtReal39);
                runtime.realAdd(&sum, &elem, &sum, &runtime.ctxtReal39);
            }
            if (math_comparison_reals.realCompareGreaterThan(&sum, &norm)) realCopy(&sum, &norm);
        }
        writeNorm(&norm);
    } else {
        normNotMatrix();
    }
    runtime.adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}

inline fn numEl(h: *const matrixHeader_t) usize {
    return math_mim_util.numEl(h.matrixRows, h.matrixColumns);
}
fn writeNnz(nnzi: u32) void {
    var nnz: real_t = undefined;
    runtime.uInt32ToReal(nnzi, &nnz);
    runtime.reallocateRegister(REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
    runtime.convertRealToReal34ResultRegister(&nnz, REGISTER_X);
}
fn writeNorm(norm: *const real_t) void {
    runtime.reallocateRegister(REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
    runtime.convertRealToReal34ResultRegister(norm, REGISTER_X);
}
fn normNotMatrix() void {
    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    if (runtime.extra_info_on_calc_error) {
        var buf: [48]u8 = undefined;
        const m = runtime.bufPrintZ(&buf, "DataType {d}", .{runtime.getRegisterDataType(REGISTER_X)}) catch "DataType";
        runtime.moreInfoOnError("In function _row_columnNorm:", m, "is not a matrix.", "");
    }
}

pub export fn fnPNorm(param: u16) callconv(.c) void {
    switch (param) {
        pNorm_0_NNZ, pNorm_1_CNORM, pNorm_inf_RNORM => _row_columnNorm(param),
        else => {
            // pNorm_2_ENORM and default: Euclidean (Frobenius) norm.
            if (runtime.saveLastX()) math_matrix_euclidean_norm_command._fnEuclideanNorm(param);
        },
    }
}

// getMatrixFromRegister -- load a matrix register into the MIM edit pointer,
// freeing any previously held matrix and tagging with the source register tag.
pub export fn getMatrixFromRegister(regist: u16) callconv(.c) void {
    const mi: calcRegister_t = @intCast(regist);
    const dt = runtime.getRegisterDataType(mi);
    if (dt == dtReal34Matrix) {
        var matrix: real34Matrix_t = undefined;
        if (openMatrixMIMPointer.realMatrix.matrixElements != null) {
            runtime.realMatrixFree(&openMatrixMIMPointer.realMatrix);
        }
        runtime.convertReal34MatrixRegisterToReal34Matrix(mi, &matrix);
        matrix.header.mtag = @truncate(runtime.getRegisterTag(mi));
        openMatrixMIMPointer.realMatrix = matrix;
    } else if (dt == dtComplex34Matrix) {
        var matrix: complex34Matrix_t = undefined;
        if (openMatrixMIMPointer.complexMatrix.matrixElements != null) {
            runtime.complexMatrixFree(&openMatrixMIMPointer.complexMatrix);
        }
        runtime.convertComplex34MatrixRegisterToComplex34Matrix(mi, &matrix);
        matrix.header.mtag = @truncate(runtime.getRegisterTag(mi));
        openMatrixMIMPointer.complexMatrix = matrix;
    } else {
        if (runtime.extra_info_on_calc_error) {
            var buf: [48]u8 = undefined;
            const m = runtime.bufPrintZ(&buf, "DataType {d}", .{dt}) catch "DataType";
            runtime.moreInfoOnError("In function getMatrixFromRegister:", m, "is not dataType dtRealMatrix.", "");
        }
        runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    }
}
