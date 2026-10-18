// SPDX-License-Identifier: GPL-3.0-only
// Zig port of the matrix-by-matrix product cluster of
// src/c47/mathematics/matrix.c: multiplyRealMatrices and
// multiplyComplexMatrices, and the compensated accumulator their inner products
// are summed with. The dot products, the cross products and the row and column
// sums share that accumulator, so the matrix owners that need it import this
// file; upstream keeps the helpers file-static, so none of them is exported.

const runtime = @import("../command_wrappers/runtime.zig");
const abi = @import("abi");
const math_comparison_reals = @import("../compare/comparison_reals.zig");
const math_matrix_lifecycle = @import("lifecycle.zig");

const real_t = runtime.real_t;
const cplx_t = runtime.cplx_t;
const realContext_t = runtime.realContext_t;
const real34Matrix_t = runtime.real34Matrix_t;
const complex34Matrix_t = runtime.complex34Matrix_t;

const nim_register_line = runtime.REGISTER_X;

const realElems = abi.matrixRealElems;
const constRealElems = abi.matrixConstRealElems;
const complexElems = abi.matrixComplexElems;
const constComplexElems = abi.matrixConstComplexElems;

inline fn realCopy(source: *const real_t, destination: *real_t) void {
    destination.* = source.*;
}

// realGetExponent(x): the exponent of the leading digit of x.
inline fn realGetExponent(source: *const real_t) i32 {
    return source.digits + source.exponent - 1;
}

fn reportRamFull(comptime function_name: [*:0]const u8) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE);
    if (runtime.extra_info_on_calc_error) {
        runtime.moreInfoOnError(function_name, "Ram full", null, null);
    }
}

// --- compensated accumulator ----------------------------------------------
//
// A sum is kept as a main term and a correction. Every addend goes through a
// FastTwoSum, whose rounding residual lands in the correction, and a product
// contributes its fused residual as a second addend, so the running sum carries
// about twice the working precision. The absolute sum records how much
// cancellation the result suffered: when it is wide of the result by more than
// twenty decades, or the result is zero, the caller replays the accumulation at
// 75 digits.

/// a + b, and the residual the rounding of that sum dropped. FastTwoSum needs
/// the greater-magnitude operand first, so the two are ordered here.
pub fn matrixTwoSum(a: *const real_t, b: *const real_t, sum: *real_t, err: *real_t, real_context: *realContext_t) void {
    var z: real_t = undefined;
    var larger = a;
    var smaller = b;

    if (math_comparison_reals.realCompareAbsLessThan(larger, smaller)) {
        larger = b;
        smaller = a;
    }
    runtime.realAdd(larger, smaller, sum, real_context);
    runtime.realSubtract(sum, larger, &z, real_context);
    runtime.realSubtract(smaller, &z, err, real_context);
}

/// Add one value to the two-term accumulator. A special value takes ordinary
/// addition, and a correction that has gone non-finite is dropped.
pub fn matrixAccumulate(value: *const real_t, sum: *real_t, correction: *real_t, real_context: *realContext_t) void {
    var next: real_t = undefined;
    var err: real_t = undefined;

    if (runtime.realIsSpecial(value) or runtime.realIsSpecial(sum) or runtime.realIsSpecial(correction)) {
        runtime.realAdd(sum, value, sum, real_context);
        runtime.realSetZero(correction);
        return;
    }
    matrixTwoSum(sum, value, &next, &err, real_context);
    runtime.realAdd(correction, &err, correction, real_context);
    realCopy(&next, sum);
}

/// Add a value to the compensated sum and its magnitude to the absolute sum.
pub fn matrixAccumulateValue(value: *const real_t, sum: *real_t, correction: *real_t, absolute_sum: *real_t, real_context: *realContext_t) void {
    var magnitude: real_t = undefined;

    if (!runtime.realIsSpecial(value)) {
        realCopy(value, &magnitude);
        runtime.realSetPositiveSign(&magnitude);
        runtime.realAdd(absolute_sum, &magnitude, absolute_sum, real_context);
    }
    matrixAccumulate(value, sum, correction, real_context);
}

/// Accumulate a * b, negated when `subtract` is set, together with the fused
/// residual of the product. Two Real34 operands give a product of at most 68
/// coefficient digits, so the residual of a 39-digit product has at most 29
/// digits and is exact. `absolute_sum` may be null.
pub fn matrixAccumulateProduct(a: *const real_t, b: *const real_t, subtract: bool, sum: *real_t, correction: *real_t, absolute_sum: ?*real_t, real_context: *realContext_t) void {
    var product: real_t = undefined;
    var residual: real_t = undefined;
    var magnitude: real_t = undefined;

    runtime.realMultiply(a, b, &product, real_context);
    if (runtime.realIsSpecial(a) or runtime.realIsSpecial(b) or runtime.realIsSpecial(&product)) {
        if (subtract) {
            runtime.realChangeSign(&product);
        }
        matrixAccumulate(&product, sum, correction, real_context);
        return;
    }
    if (absolute_sum) |abs_sum| {
        realCopy(&product, &magnitude);
        runtime.realSetPositiveSign(&magnitude);
        runtime.realAdd(abs_sum, &magnitude, abs_sum, real_context);
    }
    realCopy(&product, &residual);
    runtime.realChangeSign(&residual);
    runtime.realFMA(a, b, &residual, &residual, real_context);
    if (subtract) {
        runtime.realChangeSign(&product);
        runtime.realChangeSign(&residual);
    }
    matrixAccumulate(&product, sum, correction, real_context);
    matrixAccumulate(&residual, sum, correction, real_context);
}

/// True when the cancellation the result suffered merits a 75-digit replay: a
/// finite non-zero absolute sum against a zero result, or one more than twenty
/// decades below it.
pub fn matrixNeedsExtendedAccumulator(absolute_sum: *const real_t, result: *const real_t) bool {
    if (runtime.realIsZero(absolute_sum) or runtime.realIsSpecial(absolute_sum) or runtime.realIsSpecial(result)) {
        return false;
    }
    return runtime.realIsZero(result) or realGetExponent(absolute_sum) - realGetExponent(result) > 20;
}

/// Collapse the two-term accumulator into one working result.
pub fn matrixFinishAccumulator(sum: *const real_t, correction: *const real_t, result: *real_t, real_context: *realContext_t) void {
    runtime.realAdd(sum, correction, result, real_context);
}

// --- matrix products -------------------------------------------------------

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
                var absolute_sum: real_t = undefined;
                var correction: real_t = undefined;
                var dot_context: *realContext_t = &runtime.ctxtReal39;
                while (true) {
                    runtime.realSetZero(&sum);
                    runtime.realSetZero(&absolute_sum);
                    runtime.realSetZero(&correction);
                    var k: usize = 0;
                    while (k < iter) : (k += 1) {
                        var p: real_t = undefined;
                        var q: real_t = undefined;
                        runtime.real34ToReal(&ye[i * iter + k], &p);
                        runtime.real34ToReal(&xe[k * cols + j], &q);
                        matrixAccumulateProduct(&p, &q, false, &sum, &correction, &absolute_sum, dot_context);
                    }
                    matrixFinishAccumulator(&sum, &correction, &sum, dot_context);
                    if (dot_context == &runtime.ctxtReal39 and matrixNeedsExtendedAccumulator(&absolute_sum, &sum)) {
                        dot_context = &runtime.ctxtReal75;
                    } else {
                        break;
                    }
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
                var sum: cplx_t = undefined;
                var absolute_sum: cplx_t = undefined;
                var correction: cplx_t = undefined;
                var prod: cplx_t = undefined;
                var dot_context: *realContext_t = &runtime.ctxtReal39;
                while (true) {
                    runtime.realSetZero(&sum.Real);
                    runtime.realSetZero(&sum.Imag);
                    runtime.realSetZero(&absolute_sum.Real);
                    runtime.realSetZero(&absolute_sum.Imag);
                    runtime.realSetZero(&correction.Real);
                    runtime.realSetZero(&correction.Imag);
                    var k: usize = 0;
                    while (k < iter) : (k += 1) {
                        var p: cplx_t = undefined;
                        var q: cplx_t = undefined;
                        runtime.real34ToReal(&ye[i * iter + k].real, &p.Real);
                        runtime.real34ToReal(&ye[i * iter + k].imag, &p.Imag);
                        runtime.real34ToReal(&xe[k * cols + j].real, &q.Real);
                        runtime.real34ToReal(&xe[k * cols + j].imag, &q.Imag);
                        if (runtime.realIsSpecial(&p.Real) or runtime.realIsSpecial(&p.Imag) or runtime.realIsSpecial(&q.Real) or runtime.realIsSpecial(&q.Imag)) {
                            runtime.mulComplexComplex(&p, &q, &prod, dot_context);
                            matrixAccumulate(&prod.Real, &sum.Real, &correction.Real, dot_context);
                            matrixAccumulate(&prod.Imag, &sum.Imag, &correction.Imag, dot_context);
                        } else {
                            matrixAccumulateProduct(&p.Real, &q.Real, false, &sum.Real, &correction.Real, &absolute_sum.Real, dot_context);
                            matrixAccumulateProduct(&p.Imag, &q.Imag, true, &sum.Real, &correction.Real, &absolute_sum.Real, dot_context);
                            matrixAccumulateProduct(&p.Real, &q.Imag, false, &sum.Imag, &correction.Imag, &absolute_sum.Imag, dot_context);
                            matrixAccumulateProduct(&p.Imag, &q.Real, false, &sum.Imag, &correction.Imag, &absolute_sum.Imag, dot_context);
                        }
                    }
                    matrixFinishAccumulator(&sum.Real, &correction.Real, &sum.Real, dot_context);
                    matrixFinishAccumulator(&sum.Imag, &correction.Imag, &sum.Imag, dot_context);
                    if (dot_context == &runtime.ctxtReal39 and (matrixNeedsExtendedAccumulator(&absolute_sum.Real, &sum.Real) or matrixNeedsExtendedAccumulator(&absolute_sum.Imag, &sum.Imag))) {
                        dot_context = &runtime.ctxtReal75;
                    } else {
                        break;
                    }
                }
                runtime.realToReal34(&sum.Real, &re[i * cols + j].real);
                runtime.realToReal34(&sum.Imag, &re[i * cols + j].imag);
            }
        }
    } else {
        reportRamFull("In function multiplyComplexMatrices:");
    }
}
