// SPDX-License-Identifier: GPL-3.0-only
// Zig port of the vector-angle function of src/c47/mathematics/matrix.c:
// vectorAngle computes the angle between two 2D or 3D vectors via the dot
// product divided by the product of the euclidean (p=2) norms, fed through
// arc-cosine. The remaining matrix engine stays in the matrix bridge.

const runtime = @import("../dispatch/command_wrappers_runtime.zig");

const real_t = runtime.real_t;
const real34_t = runtime.real34_t;
const real34Matrix_t = runtime.real34Matrix_t;

pub export fn vectorAngle(y: *const real34Matrix_t, x: *const real34Matrix_t, radians: *real34_t) callconv(.c) void {
    const elements = runtime.realVectorSize(y);

    if (elements == 0 or runtime.realVectorSize(x) == 0 or elements != runtime.realVectorSize(x)) {
        runtime.realToReal34(runtime.const_NaN, radians); // Not a vector or mismatched
        return;
    }

    if (elements == 2 or elements == 3) {
        var a: real_t = undefined;
        var b: real_t = undefined;
        runtime._dotRealVectors(y, x, &a, &runtime.ctxtReal39);
        runtime._euclideanNormRealMatrix(y, 2, &b, &runtime.ctxtReal39);
        runtime.realDivide(&a, &b, &a, &runtime.ctxtReal39);
        runtime._euclideanNormRealMatrix(x, 2, &b, &runtime.ctxtReal39);
        runtime.realDivide(&a, &b, &a, &runtime.ctxtReal39);
        runtime.C47_WP34S_Acos(&a, &a, &runtime.ctxtReal39);
        runtime.realToReal34(&a, radians);
    } else {
        runtime.realToReal34(runtime.const_NaN, radians);
    }
}
