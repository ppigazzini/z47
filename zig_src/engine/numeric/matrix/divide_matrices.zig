// SPDX-License-Identifier: GPL-3.0-only
// Zig port of the matrix-by-matrix divide cluster of
// src/c47/mathematics/matrix.c: divideRealMatrices / divideComplexMatrices
// compute y * inverse(x) by inverting x (invCpxMat) and multiplying (mulCpxMat)
// on interleaved-complex real_t scratch arrays. The dense core invCpxMat /
// mulCpxMat is owned by math_matrix_complex_core.zig; this owner drives
// it and packs/unpacks the real34/complex34 matrices.

const runtime = @import("../math_command_wrappers_runtime.zig");
const abi = @import("abi");

const real_t = runtime.real_t;
const real34_t = runtime.real34_t;
const complex34_t = runtime.complex34_t;
const real34Matrix_t = runtime.real34Matrix_t;
const complex34Matrix_t = runtime.complex34Matrix_t;

const nim_register_line = runtime.REGISTER_X;

// REAL_SIZE_IN_BLOCKS(75) == 15.
const real_size_in_blocks: usize = (@sizeOf(real_t) + 3) >> 2;

const constRealElems = abi.matrixConstRealElems;
const realElems = abi.matrixRealElems;
const constComplexElems = abi.matrixConstComplexElems;
const complexElems = abi.matrixComplexElems;

inline fn distinctFromRes(y: anytype, x: anytype, res: anytype) bool {
    return @intFromPtr(y) != @intFromPtr(res) and @intFromPtr(x) != @intFromPtr(res);
}

fn clearResult(res: anytype) void {
    res.matrixElements = null;
    res.header.matrixRows = 0;
    res.header.matrixColumns = 0;
}

fn reportRamFull(comptime function_name: [*:0]const u8, comptime info: [*:0]const u8) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE, nim_register_line);
    if (runtime.extra_info_on_calc_error) {
        runtime.moreInfoOnError(function_name, info, null, null);
    }
}

pub export fn divideRealMatrices(y: *const real34Matrix_t, x: *const real34Matrix_t, res: *real34Matrix_t) callconv(.c) void {
    const size_y = y.header.matrixRows;
    const size = x.header.matrixRows;

    if (y.header.matrixColumns != x.header.matrixRows or x.header.matrixRows != x.header.matrixColumns) {
        clearResult(res); // Matrix mismatch
        return;
    }

    const yx_blocks = @as(usize, size_y) * size * real_size_in_blocks * 2;
    const xx_blocks = @as(usize, size) * size * real_size_in_blocks * 2;
    if (runtime.allocC47Blocks(yx_blocks)) |yy_raw| {
        const yy: [*]real_t = @ptrCast(@alignCast(yy_raw));
        if (runtime.allocC47Blocks(xx_blocks)) |xx_raw| {
            const xx: [*]real_t = @ptrCast(@alignCast(xx_raw));
            if (runtime.allocC47Blocks(yx_blocks)) |rr_raw| {
                const rr: [*]real_t = @ptrCast(@alignCast(rr_raw));
                const xe = constRealElems(x);
                var i: usize = 0;
                while (i < @as(usize, size) * size) : (i += 1) {
                    runtime.real34ToReal(&xe[i], &xx[i * 2]);
                    runtime.realSetZero(&xx[i * 2 + 1]);
                }
                if (runtime.invCpxMat(xx, size, &runtime.ctxtReal39)) {
                    const ye = constRealElems(y);
                    i = 0;
                    while (i < @as(usize, size_y) * size) : (i += 1) {
                        runtime.real34ToReal(&ye[i], &yy[i * 2]);
                        runtime.realSetZero(&yy[i * 2 + 1]);
                    }
                    runtime.mulCpxMat(yy, xx, size_y, size, size, rr, &runtime.ctxtReal39);
                    if (runtime.realMatrixInit(res, size_y, size)) {
                        const re = realElems(res);
                        i = 0;
                        while (i < @as(usize, size_y) * size) : (i += 1) {
                            runtime.realToReal34(&rr[i * 2], &re[i]);
                        }
                    } else {
                        if (distinctFromRes(y, x, res)) clearResult(res);
                        reportRamFull("In function divideRealMatrices:", "Ram full, 1y");
                    }
                } else { // singular matrix
                    if (distinctFromRes(y, x, res)) clearResult(res);
                }
                runtime.freeC47Blocks(rr_raw, yx_blocks);
            } else {
                if (distinctFromRes(y, x, res)) clearResult(res);
                reportRamFull("In function divideRealMatrices:", "Ram full, 2z");
            }
            runtime.freeC47Blocks(xx_raw, xx_blocks);
        } else {
            if (distinctFromRes(y, x, res)) clearResult(res);
            reportRamFull("In function divideRealMatrices:", "Ram full, 3aa");
        }
        runtime.freeC47Blocks(yy_raw, yx_blocks);
    } else {
        if (distinctFromRes(y, x, res)) clearResult(res);
        reportRamFull("In function divideRealMatrices:", "Ram full, 4ab");
    }
}

pub export fn divideComplexMatrices(y: *const complex34Matrix_t, x: *const complex34Matrix_t, res: *complex34Matrix_t) callconv(.c) void {
    const size_y = y.header.matrixRows;
    const size = x.header.matrixRows;

    if (y.header.matrixColumns != x.header.matrixRows or x.header.matrixRows != x.header.matrixColumns) {
        clearResult(res); // Matrix mismatch
        return;
    }

    const yx_blocks = @as(usize, size_y) * size * real_size_in_blocks * 2;
    const xx_blocks = @as(usize, size) * size * real_size_in_blocks * 2;
    if (runtime.allocC47Blocks(yx_blocks)) |yy_raw| {
        const yy: [*]real_t = @ptrCast(@alignCast(yy_raw));
        if (runtime.allocC47Blocks(xx_blocks)) |xx_raw| {
            const xx: [*]real_t = @ptrCast(@alignCast(xx_raw));
            if (runtime.allocC47Blocks(yx_blocks)) |rr_raw| {
                const rr: [*]real_t = @ptrCast(@alignCast(rr_raw));
                const xe = constComplexElems(x);
                var i: usize = 0;
                while (i < @as(usize, size) * size) : (i += 1) {
                    runtime.real34ToReal(&xe[i].real, &xx[i * 2]);
                    runtime.real34ToReal(&xe[i].imag, &xx[i * 2 + 1]);
                }
                if (runtime.invCpxMat(xx, size, &runtime.ctxtReal39)) {
                    const ye = constComplexElems(y);
                    i = 0;
                    while (i < @as(usize, size_y) * size) : (i += 1) {
                        runtime.real34ToReal(&ye[i].real, &yy[i * 2]);
                        runtime.real34ToReal(&ye[i].imag, &yy[i * 2 + 1]);
                    }
                    runtime.mulCpxMat(yy, xx, size_y, size, size, rr, &runtime.ctxtReal39);
                    if (runtime.complexMatrixInit(res, size_y, size)) {
                        const re = complexElems(res);
                        i = 0;
                        while (i < @as(usize, size_y) * size) : (i += 1) {
                            runtime.realToReal34(&rr[i * 2], &re[i].real);
                            runtime.realToReal34(&rr[i * 2 + 1], &re[i].imag);
                        }
                    } else {
                        if (distinctFromRes(y, x, res)) clearResult(res);
                        reportRamFull("In function divideComplexMatrices:", "Ram full, 1ac");
                    }
                } else { // singular matrix
                    if (distinctFromRes(y, x, res)) clearResult(res);
                }
                runtime.freeC47Blocks(rr_raw, yx_blocks);
            } else {
                if (distinctFromRes(y, x, res)) clearResult(res);
                reportRamFull("In function divideComplexMatrices:", "Ram full, 2ad");
            }
            runtime.freeC47Blocks(xx_raw, xx_blocks);
        } else {
            if (distinctFromRes(y, x, res)) clearResult(res);
            reportRamFull("In function divideComplexMatrices:", "Ram full, 3ae");
        }
        runtime.freeC47Blocks(yy_raw, yx_blocks);
    } else {
        if (distinctFromRes(y, x, res)) clearResult(res);
        reportRamFull("In function divideComplexMatrices:", "Ram full, 4af");
    }
}
