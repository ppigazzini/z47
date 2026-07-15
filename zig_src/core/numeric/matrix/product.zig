// SPDX-License-Identifier: GPL-3.0-only
// Zig port of the matrix-by-matrix product cluster of
// src/c47/mathematics/matrix.c: multiplyRealMatrices and
// multiplyComplexMatrices (the triple-loop inner products at 39-digit
// precision). The divide family, the vector ops and the linear-algebra
// engine stay in the matrix bridge.

const runtime = @import("../command_wrappers/runtime.zig");
const abi = @import("abi");
const math_matrix_lifecycle = @import("lifecycle.zig");

const real34_t = runtime.real34_t;
const complex34_t = runtime.complex34_t;
const real_t = runtime.real_t;
const real34Matrix_t = runtime.real34Matrix_t;
const complex34Matrix_t = runtime.complex34Matrix_t;

const nim_register_line = runtime.REGISTER_X;

// Owned by math_matrix_lifecycle.zig.

const realElems = abi.matrixRealElems;
const constRealElems = abi.matrixConstRealElems;
const complexElems = abi.matrixComplexElems;
const constComplexElems = abi.matrixConstComplexElems;

fn reportRamFull(comptime function_name: [*:0]const u8) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE, nim_register_line);
    if (runtime.extra_info_on_calc_error) {
        runtime.moreInfoOnError(function_name, "Ram full", null, null);
    }
}

pub export fn multiplyRealMatrices(y: *const real34Matrix_t, x: *const real34Matrix_t, res: *real34Matrix_t) callconv(.c) void {
    const rows = y.header.matrixRows;
    const iter = y.header.matrixColumns;
    const cols = x.header.matrixColumns;

    if (y.header.matrixColumns != x.header.matrixRows) {
        res.matrixElements = null; // Matrix mismatch
        res.header.matrixRows = 0;
        res.header.matrixColumns = 0;
        return;
    }

    if (math_matrix_lifecycle.realMatrixInit(res, rows, cols)) {
        const ye = constRealElems(y);
        const xe = constRealElems(x);
        const re = realElems(res);
        var i: usize = 0;
        while (i < rows) : (i += 1) {
            var j: usize = 0;
            while (j < cols) : (j += 1) {
                var sum: real_t = undefined;
                var prod: real_t = undefined;
                runtime.realSetZero(&sum);
                runtime.realSetZero(&prod);
                var k: usize = 0;
                while (k < iter) : (k += 1) {
                    var p: real_t = undefined;
                    var q: real_t = undefined;
                    runtime.real34ToReal(&ye[i * iter + k], &p);
                    runtime.real34ToReal(&xe[k * cols + j], &q);
                    runtime.realMultiply(&p, &q, &prod, &runtime.ctxtReal39);
                    runtime.realAdd(&sum, &prod, &sum, &runtime.ctxtReal39);
                }
                runtime.realToReal34(&sum, &re[i * cols + j]);
            }
        }
    } else {
        reportRamFull("In function multiplyRealMatrices:");
    }
}

pub export fn multiplyComplexMatrices(y: *const complex34Matrix_t, x: *const complex34Matrix_t, res: *complex34Matrix_t) callconv(.c) void {
    const rows = y.header.matrixRows;
    const iter = y.header.matrixColumns;
    const cols = x.header.matrixColumns;

    if (y.header.matrixColumns != x.header.matrixRows) {
        res.matrixElements = null; // Matrix mismatch
        res.header.matrixRows = 0;
        res.header.matrixColumns = 0;
        return;
    }

    if (math_matrix_lifecycle.complexMatrixInit(res, rows, cols)) {
        const ye = constComplexElems(y);
        const xe = constComplexElems(x);
        const re = complexElems(res);
        var i: usize = 0;
        while (i < rows) : (i += 1) {
            var j: usize = 0;
            while (j < cols) : (j += 1) {
                var sumr: real_t = undefined;
                var sumi: real_t = undefined;
                var prodr: real_t = undefined;
                var prodi: real_t = undefined;
                runtime.realSetZero(&sumr);
                runtime.realSetZero(&sumi);
                runtime.realSetZero(&prodr);
                runtime.realSetZero(&prodi);
                var k: usize = 0;
                while (k < iter) : (k += 1) {
                    var pr: real_t = undefined;
                    var pi: real_t = undefined;
                    var qr: real_t = undefined;
                    var qi: real_t = undefined;
                    runtime.real34ToReal(&ye[i * iter + k].real, &pr);
                    runtime.real34ToReal(&ye[i * iter + k].imag, &pi);
                    runtime.real34ToReal(&xe[k * cols + j].real, &qr);
                    runtime.real34ToReal(&xe[k * cols + j].imag, &qi);
                    runtime.mulComplexComplex(&pr, &pi, &qr, &qi, &prodr, &prodi, &runtime.ctxtReal39);
                    runtime.realAdd(&sumr, &prodr, &sumr, &runtime.ctxtReal39);
                    runtime.realAdd(&sumi, &prodi, &sumi, &runtime.ctxtReal39);
                }
                runtime.realToReal34(&sumr, &re[i * cols + j].real);
                runtime.realToReal34(&sumi, &re[i * cols + j].imag);
            }
        }
    } else {
        reportRamFull("In function multiplyComplexMatrices:");
    }
}
