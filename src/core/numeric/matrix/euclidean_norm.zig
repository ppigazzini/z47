// SPDX-License-Identifier: GPL-3.0-only
// Zig port of the vector-size and euclidean-norm cluster of
// src/c47/mathematics/matrix.c: realVectorSize / complexVectorSize and the
// p-norm euclideanNormRealMatrix / euclideanNormComplexMatrix (with their
// shared real_t worker _euclideanNormRealMatrix). The norms are scaled by the
// largest element magnitude, so the sum of p-th powers can neither overflow nor
// underflow for the values the elements can hold. The dot/cross products, the
// vector angle and the rest of the engine live in other matrix owners.

const runtime = @import("../command_wrappers/runtime.zig");
const abi = @import("abi");

const real_t = runtime.real_t;
const cplx_t = runtime.cplx_t;
const real34_t = runtime.real34_t;
const realContext_t = runtime.realContext_t;
const real34Matrix_t = runtime.real34Matrix_t;
const complex34Matrix_t = runtime.complex34Matrix_t;

const constRealElems = abi.matrixConstRealElems;
const constComplexElems = abi.matrixConstComplexElems;

inline fn realCopy(source: *const real_t, destination: *real_t) void {
    destination.* = source.*;
}

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

// base^exponent for a finite base in [0, 1] and a positive integer exponent, by
// binary powering.
fn matrixPositiveIntegerPower(base: *const real_t, exponent_in: u16, result: *real_t, real_context: *realContext_t) void {
    var factor: real_t = undefined;
    var product: real_t = undefined;
    var exponent = exponent_in;

    realCopy(base, &factor);
    runtime.realSetOne(result);
    while (exponent != 0) {
        if (exponent & 1 != 0) {
            runtime.realMultiply(result, &factor, &product, real_context);
            realCopy(&product, result);
        }
        exponent >>= 1;
        if (exponent != 0) {
            runtime.realMultiply(&factor, &factor, &product, real_context);
            realCopy(&product, &factor);
        }
    }
}

// The positive p-th root that closes a scaled norm: a copy for p = 1, a square
// root for p = 2, exp(ln(value) / p) otherwise.
fn matrixPositiveIntegerRoot(value: *const real_t, p_real: *const real_t, p_param: u16, result: *real_t, real_context: *realContext_t) void {
    if (p_param == 1) {
        realCopy(value, result);
    } else if (p_param == 2) {
        runtime.realSquareRoot(value, result, real_context);
    } else {
        runtime.WP34S_Ln(value, result, real_context);
        runtime.realDivide(result, p_real, result, real_context);
        runtime.realExp(result, result, real_context);
    }
}

// Static worker, exported so the vector-angle and coordinate owners can reuse
// it (they share the p=2 norm); the upstream copy is file-local, so the global
// symbol does not clash. A NaN element is the result; an infinite or zero
// largest magnitude is the result too, without the scaled sum.
pub export fn _euclideanNormRealMatrix(matrix: *const real34Matrix_t, p_param: u16, res: *real_t, real_context: *realContext_t) callconv(.c) void {
    var elem: real_t = undefined;
    var scale: real_t = undefined;
    var p_real: real_t = undefined;
    const me = constRealElems(matrix);
    const count = @as(usize, matrix.header.matrixRows) * @as(usize, matrix.header.matrixColumns);

    runtime.realSetZero(&scale);
    var i: usize = 0;
    while (i < count) : (i += 1) {
        runtime.real34ToReal(&me[i], &elem);
        runtime.realSetPositiveSign(&elem);
        if (runtime.realIsNaN(&elem)) {
            realCopy(&elem, res);
            return;
        }
        if (runtime.realCompareGreaterThan(&elem, &scale)) {
            realCopy(&elem, &scale);
        }
    }
    if (runtime.realIsInfinite(&scale) or runtime.realIsZero(&scale)) {
        realCopy(&scale, res);
        return;
    }

    runtime.uInt32ToReal(p_param, &p_real);
    runtime.realSetZero(res);
    i = 0;
    while (i < count) : (i += 1) {
        runtime.real34ToReal(&me[i], &elem);
        runtime.realSetPositiveSign(&elem);
        runtime.realDivide(&elem, &scale, &elem, real_context);
        matrixPositiveIntegerPower(&elem, p_param, &elem, real_context);
        runtime.realAdd(res, &elem, res, real_context);
    }
    matrixPositiveIntegerRoot(res, &p_real, p_param, res, real_context);
    runtime.realMultiply(&scale, res, res, real_context);
}

pub export fn euclideanNormRealMatrix(matrix: *const real34Matrix_t, p_param: u16, res: *real34_t) callconv(.c) void {
    var sum: real_t = undefined;
    _euclideanNormRealMatrix(matrix, p_param, &sum, &runtime.ctxtReal39);
    runtime.realToReal34(&sum, res);
}

pub export fn euclideanNormComplexMatrix(matrix: *const complex34Matrix_t, p_param: u16, res: *real34_t) callconv(.c) void {
    var elem: cplx_t = undefined;
    var scale: real_t = undefined;
    var p_real: real_t = undefined;
    var sum: real_t = undefined;
    const me = constComplexElems(matrix);
    const count = @as(usize, matrix.header.matrixRows) * @as(usize, matrix.header.matrixColumns);

    runtime.realSetZero(&scale);
    var i: usize = 0;
    while (i < count) : (i += 1) {
        runtime.real34ToReal(&me[i].real, &elem.Real);
        runtime.real34ToReal(&me[i].imag, &elem.Imag);
        runtime.complexMagnitude(&elem, &elem.Real, &runtime.ctxtReal39);
        if (runtime.realIsNaN(&elem.Real)) {
            runtime.realToReal34(&elem.Real, res);
            return;
        }
        if (runtime.realCompareGreaterThan(&elem.Real, &scale)) {
            realCopy(&elem.Real, &scale);
        }
    }
    if (runtime.realIsInfinite(&scale) or runtime.realIsZero(&scale)) {
        runtime.realToReal34(&scale, res);
        return;
    }

    runtime.uInt32ToReal(p_param, &p_real);
    runtime.realSetZero(&sum);
    i = 0;
    while (i < count) : (i += 1) {
        runtime.real34ToReal(&me[i].real, &elem.Real);
        runtime.real34ToReal(&me[i].imag, &elem.Imag);
        runtime.complexMagnitude(&elem, &elem.Real, &runtime.ctxtReal39);
        runtime.realDivide(&elem.Real, &scale, &elem.Real, &runtime.ctxtReal39);
        matrixPositiveIntegerPower(&elem.Real, p_param, &elem.Real, &runtime.ctxtReal39);
        runtime.realAdd(&sum, &elem.Real, &sum, &runtime.ctxtReal39);
    }
    matrixPositiveIntegerRoot(&sum, &p_real, p_param, &sum, &runtime.ctxtReal39);
    runtime.realMultiply(&scale, &sum, &sum, &runtime.ctxtReal39);
    runtime.realToReal34(&sum, res);
}
