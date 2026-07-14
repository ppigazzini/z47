// SPDX-License-Identifier: GPL-3.0-only
// Zig port of the fnLuDecomposition command of src/c47/mathematics/matrix.c:
// LU-decompose the square matrix in register X (real or complex) with partial
// pivoting, leaving the permutation matrix in Z, the unit-lower-triangular L in
// Y and the upper-triangular U in X. The numeric WP34S_LU_decomposition /
// complex_LU_decomposition still live in the matrix bridge; this is the
// command-level wrapper that drives them and splits the packed result into the
// L, U and permutation matrices.

const std = @import("std");
const runtime = @import("../dispatch/command_wrappers_runtime.zig");
const abi = @import("abi");

const real34_t = runtime.real34_t;
const real34Matrix_t = runtime.real34Matrix_t;
const complex34Matrix_t = runtime.complex34Matrix_t;

const nim_register_line = runtime.REGISTER_X;
const std_cross = "\x80\xd7";

const realElems = abi.matrixRealElems;
const complexElems = abi.matrixComplexElems;

fn bufPrintZ(buffer: []u8, comptime format: []const u8, args: anytype) ![:0]u8 {
    const slice = try std.fmt.bufPrint(buffer[0 .. buffer.len - 1], format, args);
    buffer[slice.len] = 0;
    return buffer[0..slice.len :0];
}

fn reportNotSquare(rows: u16, cols: u16) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
    if (runtime.extra_info_on_calc_error) {
        var buffer: [64]u8 = undefined;
        const message = bufPrintZ(&buffer, "not a square matrix ({d}" ++ std_cross ++ "{d})", .{ rows, cols }) catch "not a square matrix";
        runtime.moreInfoOnError("In function fnLuDecomposition:", message, null, null);
    }
}

fn reportSingular() void {
    runtime.displayCalcErrorMessage(runtime.ERROR_SINGULAR_MATRIX, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
    if (runtime.extra_info_on_calc_error) {
        runtime.moreInfoOnError("In function fnLuDecomposition:", "attempt to LU-decompose a singular matrix", null, null);
    }
}

fn reportRamFull(comptime info: [*:0]const u8) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE, nim_register_line);
    if (runtime.extra_info_on_calc_error) {
        runtime.moreInfoOnError("In function fnLuDecomposition:", info, null, null);
    }
}

fn luReal() void {
    var x: real34Matrix_t = undefined;
    runtime.convertReal34MatrixRegisterToReal34Matrix(runtime.REGISTER_X, &x);

    if (x.header.matrixRows != x.header.matrixColumns) {
        reportNotSquare(x.header.matrixRows, x.header.matrixColumns);
    } else if (runtime.allocC47Blocks(@as(usize, x.header.matrixRows) * @sizeOf(u16))) |p_raw| {
        const p: [*]u16 = @ptrCast(@alignCast(p_raw));
        var l: real34Matrix_t = undefined;
        runtime.WP34S_LU_decomposition(&x, &l, p);
        if (l.matrixElements != null) {
            var u: real34Matrix_t = undefined;
            runtime.copyRealMatrix(&l, &u);
            if (u.matrixElements != null) {
                const l_elems = realElems(&l);
                const u_elems = realElems(&u);
                const l_cols = l.header.matrixColumns;
                const u_cols = u.header.matrixColumns;
                var i: usize = 0;
                while (i < l.header.matrixRows) : (i += 1) {
                    var j: usize = i;
                    while (j < l_cols) : (j += 1) {
                        if (i == j) {
                            runtime.real34SetOne(&l_elems[i * l_cols + j]);
                        } else {
                            runtime.real34SetZero(&l_elems[i * l_cols + j]);
                        }
                    }
                }
                i = 1;
                while (i < u.header.matrixRows) : (i += 1) {
                    var j: usize = 0;
                    while (j < i) : (j += 1) {
                        runtime.real34SetZero(&u_elems[i * u_cols + j]);
                    }
                }
                runtime.realMatrixFree(&x);
                runtime.realMatrixIdentity(&x, l.header.matrixColumns);
                var k: u16 = 0;
                while (k < l.header.matrixColumns) : (k += 1) {
                    runtime.realMatrixSwapRows(&x, &x, k, p[k]);
                }
                runtime.transposeRealMatrix(&x, &x);
                runtime.liftStack();
                runtime.setSystemFlag(runtime.FLAG_ASLIFT);
                runtime.liftStack();
                runtime.convertReal34MatrixToReal34MatrixRegister(&x, runtime.REGISTER_Z);
                if (runtime.lastErrorCode == runtime.ERROR_NONE) {
                    runtime.convertReal34MatrixToReal34MatrixRegister(&l, runtime.REGISTER_Y);
                    if (runtime.lastErrorCode == runtime.ERROR_NONE) {
                        runtime.convertReal34MatrixToReal34MatrixRegister(&u, runtime.REGISTER_X);
                    }
                }
                runtime.setSystemFlag(runtime.FLAG_ASLIFT);
                runtime.realMatrixFree(&u);
            }
            runtime.realMatrixFree(&l);
        } else {
            reportSingular();
        }
        runtime.freeC47Blocks(p_raw, @as(usize, x.header.matrixRows) * @sizeOf(u16));
    } else {
        reportRamFull("Ram full, 1a");
    }

    runtime.realMatrixFree(&x);
}

fn luComplex() void {
    var x: complex34Matrix_t = undefined;
    runtime.convertComplex34MatrixRegisterToComplex34Matrix(runtime.REGISTER_X, &x);

    if (x.header.matrixRows != x.header.matrixColumns) {
        reportNotSquare(x.header.matrixRows, x.header.matrixColumns);
    } else if (runtime.allocC47Blocks(@as(usize, x.header.matrixRows) * @sizeOf(u16))) |p_raw| {
        const p: [*]u16 = @ptrCast(@alignCast(p_raw));
        var l: complex34Matrix_t = undefined;
        runtime.complex_LU_decomposition(&x, &l, p);
        if (l.matrixElements != null) {
            var u: complex34Matrix_t = undefined;
            runtime.copyComplexMatrix(&l, &u);
            if (u.matrixElements != null) {
                const l_elems = complexElems(&l);
                const u_elems = complexElems(&u);
                const l_cols = l.header.matrixColumns;
                const u_cols = u.header.matrixColumns;
                var i: usize = 0;
                while (i < l.header.matrixRows) : (i += 1) {
                    var j: usize = i;
                    while (j < l_cols) : (j += 1) {
                        if (i == j) {
                            runtime.real34SetOne(&l_elems[i * l_cols + j].real);
                        } else {
                            runtime.real34SetZero(&l_elems[i * l_cols + j].real);
                        }
                        runtime.real34SetZero(&l_elems[i * l_cols + j].imag);
                    }
                }
                i = 1;
                while (i < u.header.matrixRows) : (i += 1) {
                    var j: usize = 0;
                    while (j < i) : (j += 1) {
                        runtime.real34SetZero(&u_elems[i * u_cols + j].real);
                        runtime.real34SetZero(&u_elems[i * u_cols + j].imag);
                    }
                }
                var pivot: real34Matrix_t = undefined;
                runtime.realMatrixIdentity(&pivot, l.header.matrixColumns);
                if (runtime.lastErrorCode == runtime.ERROR_NONE) {
                    var k: u16 = 0;
                    while (k < l.header.matrixColumns) : (k += 1) {
                        runtime.realMatrixSwapRows(&pivot, &pivot, k, p[k]);
                    }
                    runtime.transposeRealMatrix(&pivot, &pivot);
                    runtime.liftStack();
                    runtime.setSystemFlag(runtime.FLAG_ASLIFT);
                    runtime.liftStack();
                    runtime.setSystemFlag(runtime.FLAG_ASLIFT);
                    runtime.convertReal34MatrixToReal34MatrixRegister(&pivot, runtime.REGISTER_Z);
                    if (runtime.lastErrorCode == runtime.ERROR_NONE) {
                        runtime.convertComplex34MatrixToComplex34MatrixRegister(&l, runtime.REGISTER_Y);
                        if (runtime.lastErrorCode == runtime.ERROR_NONE) {
                            runtime.convertComplex34MatrixToComplex34MatrixRegister(&u, runtime.REGISTER_X);
                        }
                    }
                    runtime.realMatrixFree(&pivot);
                } else {
                    reportRamFull("Ram full, 2b");
                }
                runtime.complexMatrixFree(&u);
            } else {
                reportRamFull("Ram full, 3c");
            }
            runtime.complexMatrixFree(&l);
        } else {
            reportSingular();
        }
        runtime.freeC47Blocks(p_raw, @as(usize, x.header.matrixRows) * @sizeOf(u16));
    } else {
        reportRamFull("Ram full, 4d");
    }

    runtime.complexMatrixFree(&x);
}

pub export fn fnLuDecomposition(unused_param_but_mandatory: u16) callconv(.c) void {
    _ = unused_param_but_mandatory;
    if (!runtime.saveLastX()) {
        return;
    }

    const data_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    if (data_type == runtime.dtReal34Matrix) {
        luReal();
    } else if (data_type == runtime.dtComplex34Matrix) {
        luComplex();
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, nim_register_line);
        if (runtime.extra_info_on_calc_error) {
            var buffer: [64]u8 = undefined;
            const message = bufPrintZ(&buffer, "DataType {d}", .{data_type}) catch "DataType";
            runtime.moreInfoOnError("In function fnLuDecomposition:", message, "is not a matrix.", "");
        }
    }

    runtime.adjustResult(runtime.REGISTER_X, false, true, runtime.REGISTER_X, -1, -1);
}
