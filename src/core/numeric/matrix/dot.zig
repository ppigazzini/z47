// SPDX-License-Identifier: GPL-3.0-only
// Zig port of the vector dot-product cluster of
// src/c47/mathematics/matrix.c: dotRealVectors / dotComplexVectors and the
// shared real_t worker _dotRealVectors. Both sums go through the compensated
// accumulator the product owner holds and replay at 75 digits when the
// 39-digit pass cancelled. The cross products, the vector angle and the rest of
// the engine live in other matrix owners.

const runtime = @import("../command_wrappers/runtime.zig");
const abi = @import("abi");
const math_matrix_product = @import("product.zig");

const real_t = runtime.real_t;
const cplx_t = runtime.cplx_t;
const real34_t = runtime.real34_t;
const realContext_t = runtime.realContext_t;
const real34Matrix_t = runtime.real34Matrix_t;
const complex34Matrix_t = runtime.complex34Matrix_t;

const constRealElems = abi.matrixConstRealElems;
const constComplexElems = abi.matrixConstComplexElems;

// Static worker, exported so the vector-angle and coordinate owners can reuse
// it; the upstream copy is file-local, so the global symbol does not clash. A
// context of 39 digits or fewer is replayed at 75 when the sum cancelled.
pub export fn _dotRealVectors(y: *const real34Matrix_t, x: *const real34Matrix_t, res: *real_t, real_context: *realContext_t) callconv(.c) void {
    const elements = runtime.realVectorSize(y);
    var sum: real_t = undefined;
    var absolute_sum: real_t = undefined;
    var correction: real_t = undefined;
    var p: real_t = undefined;
    var q: real_t = undefined;
    var dot_context: *realContext_t = real_context;
    const ye = constRealElems(y);
    const xe = constRealElems(x);

    while (true) {
        runtime.realSetZero(&sum);
        runtime.realSetZero(&absolute_sum);
        runtime.realSetZero(&correction);
        var i: usize = 0;
        while (i < elements) : (i += 1) {
            runtime.real34ToReal(&ye[i], &p);
            runtime.real34ToReal(&xe[i], &q);
            math_matrix_product.matrixAccumulateProduct(&p, &q, false, &sum, &correction, &absolute_sum, dot_context);
        }
        math_matrix_product.matrixFinishAccumulator(&sum, &correction, res, dot_context);
        if (dot_context.digits <= 39 and math_matrix_product.matrixNeedsExtendedAccumulator(&absolute_sum, res)) {
            dot_context = &runtime.ctxtReal75;
        } else {
            break;
        }
    }
}

pub export fn dotRealVectors(y: *const real34Matrix_t, x: *const real34Matrix_t, res: *real34_t) callconv(.c) void {
    if (runtime.realVectorSize(y) == 0 or runtime.realVectorSize(x) == 0 or runtime.realVectorSize(y) != runtime.realVectorSize(x)) {
        runtime.realToReal34(runtime.const_NaN, res); // Not a vector or mismatched
        return;
    }
    var p: real_t = undefined;
    _dotRealVectors(y, x, &p, &runtime.ctxtReal39);
    runtime.realToReal34(&p, res);
}

pub export fn dotComplexVectors(y: *const complex34Matrix_t, x: *const complex34Matrix_t, res_r: *real34_t, res_i: *real34_t) callconv(.c) void {
    const elements = runtime.complexVectorSize(y);
    if (runtime.complexVectorSize(y) == 0 or runtime.complexVectorSize(x) == 0 or runtime.complexVectorSize(y) != runtime.complexVectorSize(x)) {
        runtime.realToReal34(runtime.const_NaN, res_r);
        runtime.realToReal34(runtime.const_NaN, res_i); // Not a vector or mismatched
        return;
    }

    var sum: cplx_t = undefined;
    var absolute_sum: cplx_t = undefined;
    var correction: cplx_t = undefined;
    var prod: cplx_t = undefined;
    var p: cplx_t = undefined;
    var q: cplx_t = undefined;
    var dot_context: *realContext_t = &runtime.ctxtReal39;
    const ye = constComplexElems(y);
    const xe = constComplexElems(x);

    while (true) {
        runtime.realSetZero(&sum.Real);
        runtime.realSetZero(&sum.Imag);
        runtime.realSetZero(&absolute_sum.Real);
        runtime.realSetZero(&absolute_sum.Imag);
        runtime.realSetZero(&correction.Real);
        runtime.realSetZero(&correction.Imag);
        var i: usize = 0;
        while (i < elements) : (i += 1) {
            runtime.real34ToReal(&ye[i].real, &p.Real);
            runtime.real34ToReal(&ye[i].imag, &p.Imag);
            runtime.real34ToReal(&xe[i].real, &q.Real);
            runtime.real34ToReal(&xe[i].imag, &q.Imag);
            if (runtime.realIsSpecial(&p.Real) or runtime.realIsSpecial(&p.Imag) or runtime.realIsSpecial(&q.Real) or runtime.realIsSpecial(&q.Imag)) {
                runtime.mulComplexComplex(&p, &q, &prod, dot_context);
                math_matrix_product.matrixAccumulate(&prod.Real, &sum.Real, &correction.Real, dot_context);
                math_matrix_product.matrixAccumulate(&prod.Imag, &sum.Imag, &correction.Imag, dot_context);
            } else {
                math_matrix_product.matrixAccumulateProduct(&p.Real, &q.Real, false, &sum.Real, &correction.Real, &absolute_sum.Real, dot_context);
                math_matrix_product.matrixAccumulateProduct(&p.Imag, &q.Imag, true, &sum.Real, &correction.Real, &absolute_sum.Real, dot_context);
                math_matrix_product.matrixAccumulateProduct(&p.Real, &q.Imag, false, &sum.Imag, &correction.Imag, &absolute_sum.Imag, dot_context);
                math_matrix_product.matrixAccumulateProduct(&p.Imag, &q.Real, false, &sum.Imag, &correction.Imag, &absolute_sum.Imag, dot_context);
            }
        }
        math_matrix_product.matrixFinishAccumulator(&sum.Real, &correction.Real, &sum.Real, dot_context);
        math_matrix_product.matrixFinishAccumulator(&sum.Imag, &correction.Imag, &sum.Imag, dot_context);
        if (dot_context == &runtime.ctxtReal39 and (math_matrix_product.matrixNeedsExtendedAccumulator(&absolute_sum.Real, &sum.Real) or math_matrix_product.matrixNeedsExtendedAccumulator(&absolute_sum.Imag, &sum.Imag))) {
            dot_context = &runtime.ctxtReal75;
        } else {
            break;
        }
    }
    runtime.realToReal34(&sum.Real, res_r);
    runtime.realToReal34(&sum.Imag, res_i);
}
