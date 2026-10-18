// SPDX-License-Identifier: GPL-3.0-only
// Zig port of the vector cross-product cluster of
// src/c47/mathematics/matrix.c: crossRealVectors / crossComplexVectors (the
// 3D vector cross product, zero-padding 2D inputs). A real component is the
// compensated two-product dotCplx computes; a complex component is the
// difference of two complex products through the product owner's compensated
// accumulator. The vector angle and the rest of the engine live in other
// matrix owners.

const runtime = @import("../command_wrappers/runtime.zig");
const abi = @import("abi");
const math_matrix_product = @import("product.zig");
const math_vector_dot_scalar = @import("vector_dot_scalar.zig");

const real_t = runtime.real_t;
const cplx_t = runtime.cplx_t;
const real34_t = runtime.real34_t;
const realContext_t = runtime.realContext_t;
const real34Matrix_t = runtime.real34Matrix_t;
const complex34Matrix_t = runtime.complex34Matrix_t;

const nim_register_line = runtime.REGISTER_X;

const constRealElems = abi.matrixConstRealElems;
const constComplexElems = abi.matrixConstComplexElems;
const realElems = abi.matrixRealElems;
const complexElems = abi.matrixComplexElems;

fn reportRamFull(comptime function_name: [*:0]const u8) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE);
    if (runtime.extra_info_on_calc_error) {
        runtime.moreInfoOnError(function_name, "Ram full", null, null);
    }
}

// real34ToReal of the upstream "elements >= n ? ptr : const34_0" reads the
// element when present and otherwise yields +0; realSetZero produces the same
// +0 element without needing the const34_0 pointer.
inline fn loadOrZero(present: bool, src: *const real34_t, dst: *real_t) void {
    if (present) {
        runtime.real34ToReal(src, dst);
    } else {
        runtime.realSetZero(dst);
    }
}

pub export fn crossRealVectors(y: *const real34Matrix_t, x: *const real34Matrix_t, res: *real34Matrix_t) callconv(.c) void {
    const elements_y = runtime.realVectorSize(y);
    const elements_x = runtime.realVectorSize(x);
    if (elements_y == 0 or elements_x == 0 or elements_y > 3 or elements_x > 3) {
        return; // Not a vector or mismatched
    }

    const ye = constRealElems(y);
    const xe = constRealElems(x);
    var a1: real_t = undefined;
    var a2: real_t = undefined;
    var a3: real_t = undefined;
    var b1: real_t = undefined;
    var b2: real_t = undefined;
    var b3: real_t = undefined;
    var p: real_t = undefined;
    var q: real_t = undefined;

    runtime.real34ToReal(&ye[0], &a1);
    loadOrZero(elements_y >= 2, &ye[1], &a2);
    loadOrZero(elements_y >= 3, &ye[2], &a3);
    runtime.real34ToReal(&xe[0], &b1);
    loadOrZero(elements_x >= 2, &xe[1], &b2);
    loadOrZero(elements_x >= 3, &xe[2], &b3);

    if (runtime.realMatrixInit(res, 1, 3)) {
        const re = realElems(res);
        // Each component a_i b_j - a_j b_i is the two-product a_i b_j + a_j (-b_i).
        q = b2;
        runtime.realChangeSign(&q);
        math_vector_dot_scalar.dotCplx(&a2, &a3, &b3, &q, &p, &runtime.ctxtReal39);
        runtime.realToReal34(&p, &re[0]);

        q = b3;
        runtime.realChangeSign(&q);
        math_vector_dot_scalar.dotCplx(&a3, &a1, &b1, &q, &p, &runtime.ctxtReal39);
        runtime.realToReal34(&p, &re[1]);

        q = b1;
        runtime.realChangeSign(&q);
        math_vector_dot_scalar.dotCplx(&a1, &a2, &b2, &q, &p, &runtime.ctxtReal39);
        runtime.realToReal34(&p, &re[2]);
    } else {
        reportRamFull("In function crossRealVectors:");
    }
}

// a1 b1 - a2 b2 with every component sum compensated. The first pass runs at
// 39 digits; a component that lost more than twenty decimal places is
// evaluated again at 75. A special operand takes the plain products.
fn matrixComplexProductDifference(a1: *const cplx_t, b1: *const cplx_t, a2: *const cplx_t, b2: *const cplx_t, res: *cplx_t) void {
    var correction: cplx_t = undefined;
    var second: cplx_t = undefined;
    var sum: cplx_t = undefined;
    var absolute_sum: cplx_t = undefined;
    var work_context: *realContext_t = &runtime.ctxtReal39;

    if (runtime.realIsSpecial(&a1.Real) or runtime.realIsSpecial(&a1.Imag) or runtime.realIsSpecial(&b1.Real) or runtime.realIsSpecial(&b1.Imag) or
        runtime.realIsSpecial(&a2.Real) or runtime.realIsSpecial(&a2.Imag) or runtime.realIsSpecial(&b2.Real) or runtime.realIsSpecial(&b2.Imag))
    {
        runtime.mulComplexComplex(a1, b1, res, &runtime.ctxtReal39);
        runtime.mulComplexComplex(a2, b2, &second, &runtime.ctxtReal39);
        runtime.realSubtract(&res.Real, &second.Real, &res.Real, &runtime.ctxtReal39);
        runtime.realSubtract(&res.Imag, &second.Imag, &res.Imag, &runtime.ctxtReal39);
        return;
    }

    while (true) {
        runtime.realSetZero(&sum.Real);
        runtime.realSetZero(&sum.Imag);
        runtime.realSetZero(&absolute_sum.Real);
        runtime.realSetZero(&absolute_sum.Imag);
        runtime.realSetZero(&correction.Real);
        runtime.realSetZero(&correction.Imag);

        math_matrix_product.matrixAccumulateProduct(&a1.Real, &b1.Real, false, &sum.Real, &correction.Real, &absolute_sum.Real, work_context);
        math_matrix_product.matrixAccumulateProduct(&a1.Imag, &b1.Imag, true, &sum.Real, &correction.Real, &absolute_sum.Real, work_context);
        math_matrix_product.matrixAccumulateProduct(&a2.Real, &b2.Real, true, &sum.Real, &correction.Real, &absolute_sum.Real, work_context);
        math_matrix_product.matrixAccumulateProduct(&a2.Imag, &b2.Imag, false, &sum.Real, &correction.Real, &absolute_sum.Real, work_context);

        math_matrix_product.matrixAccumulateProduct(&a1.Real, &b1.Imag, false, &sum.Imag, &correction.Imag, &absolute_sum.Imag, work_context);
        math_matrix_product.matrixAccumulateProduct(&a1.Imag, &b1.Real, false, &sum.Imag, &correction.Imag, &absolute_sum.Imag, work_context);
        math_matrix_product.matrixAccumulateProduct(&a2.Real, &b2.Imag, true, &sum.Imag, &correction.Imag, &absolute_sum.Imag, work_context);
        math_matrix_product.matrixAccumulateProduct(&a2.Imag, &b2.Real, true, &sum.Imag, &correction.Imag, &absolute_sum.Imag, work_context);

        math_matrix_product.matrixFinishAccumulator(&sum.Real, &correction.Real, &res.Real, work_context);
        math_matrix_product.matrixFinishAccumulator(&sum.Imag, &correction.Imag, &res.Imag, work_context);
        if (work_context == &runtime.ctxtReal39 and (math_matrix_product.matrixNeedsExtendedAccumulator(&absolute_sum.Real, &res.Real) or math_matrix_product.matrixNeedsExtendedAccumulator(&absolute_sum.Imag, &res.Imag))) {
            work_context = &runtime.ctxtReal75;
        } else {
            break;
        }
    }
}

pub export fn crossComplexVectors(y: *const complex34Matrix_t, x: *const complex34Matrix_t, res: *complex34Matrix_t) callconv(.c) void {
    const elements_y = runtime.complexVectorSize(y);
    const elements_x = runtime.complexVectorSize(x);
    if (elements_y == 0 or elements_x == 0 or elements_y > 3 or elements_x > 3) {
        return; // Not a vector or mismatched
    }

    const ye = constComplexElems(y);
    const xe = constComplexElems(x);
    var a1: cplx_t = undefined;
    var a2: cplx_t = undefined;
    var a3: cplx_t = undefined;
    var b1: cplx_t = undefined;
    var b2: cplx_t = undefined;
    var b3: cplx_t = undefined;
    var p: cplx_t = undefined;

    runtime.real34ToReal(&ye[0].real, &a1.Real);
    runtime.real34ToReal(&ye[0].imag, &a1.Imag);
    loadOrZero(elements_y >= 2, &ye[1].real, &a2.Real);
    loadOrZero(elements_y >= 2, &ye[1].imag, &a2.Imag);
    loadOrZero(elements_y >= 3, &ye[2].real, &a3.Real);
    loadOrZero(elements_y >= 3, &ye[2].imag, &a3.Imag);

    runtime.real34ToReal(&xe[0].real, &b1.Real);
    runtime.real34ToReal(&xe[0].imag, &b1.Imag);
    loadOrZero(elements_x >= 2, &xe[1].real, &b2.Real);
    loadOrZero(elements_x >= 2, &xe[1].imag, &b2.Imag);
    loadOrZero(elements_x >= 3, &xe[2].real, &b3.Real);
    loadOrZero(elements_x >= 3, &xe[2].imag, &b3.Imag);

    if (runtime.complexMatrixInit(res, 1, 3)) {
        const re = complexElems(res);
        matrixComplexProductDifference(&a2, &b3, &a3, &b2, &p);
        runtime.realToReal34(&p.Real, &re[0].real);
        runtime.realToReal34(&p.Imag, &re[0].imag);

        matrixComplexProductDifference(&a3, &b1, &a1, &b3, &p);
        runtime.realToReal34(&p.Real, &re[1].real);
        runtime.realToReal34(&p.Imag, &re[1].imag);

        matrixComplexProductDifference(&a1, &b2, &a2, &b1, &p);
        runtime.realToReal34(&p.Real, &re[2].real);
        runtime.realToReal34(&p.Imag, &re[2].imag);
    } else {
        reportRamFull("In function crossComplexVectors:");
    }
}
