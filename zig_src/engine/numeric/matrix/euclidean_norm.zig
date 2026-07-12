// SPDX-License-Identifier: GPL-3.0-only
// Zig port of the vector-size and euclidean-norm cluster of
// src/c47/mathematics/matrix.c: realVectorSize / complexVectorSize and the
// p-norm euclideanNormRealMatrix / euclideanNormComplexMatrix (with their
// shared real_t worker _euclideanNormRealMatrix). The dot/cross products, the
// vector angle and the rest of the engine stay in the matrix bridge.

const runtime = @import("../dispatch/command_wrappers_runtime.zig");
const abi = @import("abi");

const real_t = runtime.real_t;
const real34_t = runtime.real34_t;
const real34Matrix_t = runtime.real34Matrix_t;
const complex34Matrix_t = runtime.complex34Matrix_t;

const constRealElems = abi.matrixConstRealElems;
const constComplexElems = abi.matrixConstComplexElems;

pub export fn realVectorSize(matrix: *const real34Matrix_t) callconv(.c) u16 {
    if (matrix.header.matrixColumns != 1 and matrix.header.matrixRows != 1) {
        return 0;
    }
    return @intCast(@as(u32, matrix.header.matrixColumns) * @as(u32, matrix.header.matrixRows));
}

pub export fn complexVectorSize(matrix: *const complex34Matrix_t) callconv(.c) u16 {
    // Upstream reinterpret-casts to a real matrix; the headers share a layout.
    return realVectorSize(@ptrCast(matrix));
}

// Static worker, exported so the vector-angle owner can reuse it (it shares the
// p=2 norm). The bridge renames the legacy copy so the not-yet-ported engine
// keeps calling its own static version.
pub export fn _euclideanNormRealMatrix(matrix: *const real34Matrix_t, p_param: u16, res: *real_t, real_context: *runtime.realContext_t) callconv(.c) void {
    var elem: real_t = undefined;
    var p_real: real_t = undefined;
    var p_inv: real_t = undefined;
    runtime.uInt32ToReal(p_param, &p_real);
    runtime.realDivide(runtime.z47_math_wrappers_const_1(), &p_real, &p_inv, real_context);
    runtime.realSetZero(res);
    const me = constRealElems(matrix);
    const count = @as(usize, matrix.header.matrixRows) * @as(usize, matrix.header.matrixColumns);
    var i: usize = 0;
    while (i < count) : (i += 1) {
        runtime.real34ToReal(&me[i], &elem);
        runtime.realSetPositiveSign(&elem);
        runtime.realPower(&elem, &p_real, &elem, real_context);
        runtime.realAdd(res, &elem, res, real_context);
    }
    runtime.realPower(res, &p_inv, res, real_context);
}

pub export fn euclideanNormRealMatrix(matrix: *const real34Matrix_t, p_param: u16, res: *real34_t) callconv(.c) void {
    var sum: real_t = undefined;
    _euclideanNormRealMatrix(matrix, p_param, &sum, &runtime.ctxtReal39);
    runtime.realToReal34(&sum, res);
}

pub export fn euclideanNormComplexMatrix(matrix: *const complex34Matrix_t, p_param: u16, res: *real34_t) callconv(.c) void {
    var elem: real_t = undefined;
    var imag: real_t = undefined;
    var p_real: real_t = undefined;
    var p_inv: real_t = undefined;
    var sum: real_t = undefined;
    runtime.uInt32ToReal(p_param, &p_real);
    runtime.realDivide(runtime.z47_math_wrappers_const_1(), &p_real, &p_inv, &runtime.ctxtReal39);
    runtime.realSetZero(&sum);
    const me = constComplexElems(matrix);
    const count = @as(usize, matrix.header.matrixRows) * @as(usize, matrix.header.matrixColumns);
    var i: usize = 0;
    while (i < count) : (i += 1) {
        runtime.real34ToReal(&me[i].real, &elem);
        runtime.real34ToReal(&me[i].imag, &imag);
        runtime.complexMagnitude(&elem, &imag, &elem, &runtime.ctxtReal39);
        runtime.realPower(&elem, &p_real, &elem, &runtime.ctxtReal39);
        runtime.realAdd(&sum, &elem, &sum, &runtime.ctxtReal39);
    }
    runtime.realPower(&sum, &p_inv, &sum, &runtime.ctxtReal39);
    runtime.realToReal34(&sum, res);
}
