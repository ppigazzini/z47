// SPDX-License-Identifier: GPL-3.0-only
// Zig port of the vector-angle function of src/c47/mathematics/matrix.c:
// vectorAngle computes the angle between two 2D or 3D real vectors as
// atan2(|y x x|, y . x), with the cross-product components kept wide through the
// compensated two-product dotCplx, so a small angle survives that a Real34
// conversion before the norm would lose. The remaining matrix engine lives in
// the other matrix owners.

const runtime = @import("../command_wrappers/runtime.zig");
const abi = @import("abi");
const math_vector_dot_scalar = @import("vector_dot_scalar.zig");

const real_t = runtime.real_t;
const cplx_t = runtime.cplx_t;
const real34_t = runtime.real34_t;
const real34Matrix_t = runtime.real34Matrix_t;

const constRealElems = abi.matrixConstRealElems;

inline fn realCopy(source: *const real_t, destination: *real_t) void {
    destination.* = source.*;
}

// One compensated component a*c - b*d of a real-vector cross product, as the
// two-product a*c + b*(-d). Any special operand gives NaN.
fn matrixRealVectorCrossComponent(a: *const real34_t, b: *const real34_t, c: *const real34_t, d: *const real34_t, component: *real_t) void {
    var a_real: real_t = undefined;
    var b_real: real_t = undefined;
    var c_real: real_t = undefined;
    var d_real: real_t = undefined;

    runtime.real34ToReal(a, &a_real);
    runtime.real34ToReal(b, &b_real);
    runtime.real34ToReal(c, &c_real);
    runtime.real34ToReal(d, &d_real);
    if (runtime.realIsSpecial(&a_real) or runtime.realIsSpecial(&b_real) or runtime.realIsSpecial(&c_real) or runtime.realIsSpecial(&d_real)) {
        runtime.realSetNaN(component);
        return;
    }
    runtime.realChangeSign(&d_real);
    math_vector_dot_scalar.dotCplx(&a_real, &b_real, &c_real, &d_real, component, &runtime.ctxtReal39);
}

// The magnitude of a two- or three-dimensional real-vector cross product, each
// component at 39 digits.
fn matrixRealVectorCrossMagnitude(y: *const real34Matrix_t, x: *const real34Matrix_t, magnitude: *real_t) void {
    const elements = runtime.realVectorSize(y);
    const ye = constRealElems(y);
    const xe = constRealElems(x);
    var c: cplx_t = undefined;

    if (elements == 2) {
        matrixRealVectorCrossComponent(&ye[0], &ye[1], &xe[1], &xe[0], magnitude);
        runtime.realSetPositiveSign(magnitude);
        return;
    }

    matrixRealVectorCrossComponent(&ye[1], &ye[2], &xe[2], &xe[1], &c.Real);
    matrixRealVectorCrossComponent(&ye[2], &ye[0], &xe[0], &xe[2], &c.Imag);
    runtime.complexMagnitude(&c, &c.Real, &runtime.ctxtReal39);
    matrixRealVectorCrossComponent(&ye[0], &ye[1], &xe[1], &xe[0], &c.Imag);
    runtime.complexMagnitude(&c, magnitude, &runtime.ctxtReal39);
}

// The angle between two real vectors in radians, at 39 digits; NaN for invalid
// vectors, and for two zero vectors.
pub export fn vectorAngle(y: *const real34Matrix_t, x: *const real34Matrix_t, radians: *real_t) callconv(.c) void {
    const elements = runtime.realVectorSize(y);
    var cross_magnitude: real_t = undefined;
    var dot: real_t = undefined;

    if (elements == 0 or runtime.realVectorSize(x) == 0 or elements != runtime.realVectorSize(x)) {
        runtime.realSetNaN(radians); // Not a vector or mismatched
        return;
    }

    if (elements == 2 or elements == 3) {
        matrixRealVectorCrossMagnitude(y, x, &cross_magnitude);
        if (runtime.realIsNaN(&cross_magnitude)) {
            realCopy(&cross_magnitude, radians);
            return;
        }
        runtime._dotRealVectors(y, x, &dot, &runtime.ctxtReal39);
        if (runtime.realIsZero(&cross_magnitude) and runtime.realIsZero(&dot)) {
            runtime.realSetNaN(radians);
            return;
        }
        runtime.C47_WP34S_Atan2(&cross_magnitude, &dot, radians, &runtime.ctxtReal39);
    } else {
        runtime.realSetNaN(radians);
    }
}
