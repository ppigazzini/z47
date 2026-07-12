// SPDX-License-Identifier: GPL-3.0-only
// Zig port of the OPTION_VECTOR coordinate-conversion helpers of
// src/c47/mathematics/matrix.c: the rectangular <-> spherical / cylindrical /
// polar conversions used by the 2D/3D vector commands (items.c, addons.c, the
// matrix editor). These are pure decNumber numerics -- no MIM/register
// dispatch -- so they port 1:1 against the WP34S trig + real arithmetic the
// runtime already exposes.
//
// The firmware math object is built once (package-agnostic, no SAVE_SPACE
// defines), so OPTION_VECTOR is always on for the matrix bridge in every build;
// these helpers are therefore unconditional, matching the existing C object.
//
// realCopy(src, dst) is decNumberCopy(dst, src), i.e. a real_t struct copy; the
// matrix owners already express that as `dst.* = src.*` (math_matrix_insert,
// math_matrix_determinant), so no runtime helper is needed.

const runtime = @import("../math_command_wrappers_runtime.zig");
const abi = @import("abi");

const real_t = runtime.real_t;
const real34_t = runtime.real34_t;
const real34Matrix_t = runtime.real34Matrix_t;
const realContext_t = runtime.realContext_t;
const angularMode_t = runtime.angularMode_t;
const amRadian = runtime.amRadian;

const readElements = abi.matrixConstRealElems;
const writeElements = abi.matrixRealElems;

pub export fn convert3DtoSPH(matrix: *const real34Matrix_t, r: *real_t, th1: *real_t, th2: *real_t, am: u8, ctxtRealDisplay: *realContext_t) callconv(.c) void {
    var x: real_t = undefined;
    var y: real_t = undefined;
    var z: real_t = undefined;
    runtime._euclideanNormRealMatrix(matrix, 2, r, &runtime.ctxtReal39);

    const elements = readElements(matrix);
    runtime.real34ToReal(&elements[0], &x);
    runtime.real34ToReal(&elements[1], &y);
    runtime.real34ToReal(&elements[2], &z);

    if (runtime.realIsZero(&x) and runtime.realIsZero(&y) and runtime.realIsZero(&z)) {
        // By convention [0 0 0] leaves both angles undefined; use 0.
        runtime.realSetZero(r);
        runtime.realSetZero(th1);
        runtime.realSetZero(th2);
    } else {
        runtime.C47_WP34S_Atan2(&y, &x, th1, ctxtRealDisplay);
        runtime.realDivide(&z, r, &z, ctxtRealDisplay);
        runtime.C47_WP34S_Acos(&z, th2, ctxtRealDisplay);
    }

    runtime.convertAngleFromTo(th1, amRadian, @as(angularMode_t, am), ctxtRealDisplay);
    if (runtime.realIsZero(th1)) {
        runtime.realSetZero(th1);
    }
    runtime.convertAngleFromTo(th2, amRadian, @as(angularMode_t, am), ctxtRealDisplay);
    if (runtime.realIsZero(th2)) {
        runtime.realSetZero(th2);
    }
}

pub export fn convertSPHto3D(r: *real_t, th1: *real_t, th2: *real_t, am: u8, matrix: *real34Matrix_t, ctxtRealDisplay: *realContext_t) callconv(.c) void {
    var x: real_t = undefined;
    var y: real_t = undefined;
    var z: real_t = undefined;
    var theta1: real_t = th1.*;
    var theta2: real_t = th2.*;
    var sinTh2: real_t = undefined;

    runtime.convertAngleFromTo(&theta1, @as(angularMode_t, am), amRadian, ctxtRealDisplay);
    runtime.convertAngleFromTo(&theta2, @as(angularMode_t, am), amRadian, ctxtRealDisplay);

    runtime.C47_WP34S_Cvt2RadSinCosTan(&theta2, amRadian, null, &z, null, ctxtRealDisplay);
    runtime.realMultiply(r, &z, &z, ctxtRealDisplay);
    runtime.C47_WP34S_Cvt2RadSinCosTan(&theta2, amRadian, &sinTh2, null, null, ctxtRealDisplay);
    runtime.C47_WP34S_Cvt2RadSinCosTan(&theta1, amRadian, null, &x, null, ctxtRealDisplay);
    runtime.realMultiply(r, &x, &x, ctxtRealDisplay);
    runtime.realMultiply(&x, &sinTh2, &x, ctxtRealDisplay);

    runtime.C47_WP34S_Cvt2RadSinCosTan(&theta1, amRadian, &y, null, null, ctxtRealDisplay);
    runtime.realMultiply(r, &y, &y, ctxtRealDisplay);
    runtime.realMultiply(&y, &sinTh2, &y, ctxtRealDisplay);

    const elements = writeElements(matrix);
    runtime.realToReal34(&x, &elements[0]);
    runtime.realToReal34(&y, &elements[1]);
    runtime.realToReal34(&z, &elements[2]);
}

pub export fn convert3DtoCYL(matrix: *const real34Matrix_t, r: *real_t, th1: *real_t, z: *real_t, am: u8, ctxtRealDisplay: *realContext_t) callconv(.c) void {
    var x: real_t = undefined;
    var y: real_t = undefined;
    var t: real_t = undefined;
    const elements = readElements(matrix);
    runtime.real34ToReal(&elements[0], &x);
    runtime.real34ToReal(&elements[1], &y);
    runtime.real34ToReal(&elements[2], z);

    runtime.realMultiply(&x, &x, r, ctxtRealDisplay);
    runtime.realMultiply(&y, &y, &t, ctxtRealDisplay);
    runtime.realAdd(&t, r, r, ctxtRealDisplay);
    runtime.realSquareRoot(r, r, ctxtRealDisplay);

    runtime.C47_WP34S_Atan2(&y, &x, th1, ctxtRealDisplay);

    runtime.convertAngleFromTo(th1, amRadian, @as(angularMode_t, am), ctxtRealDisplay);
    if (runtime.realIsZero(th1)) {
        runtime.realSetZero(th1);
    }
}

pub export fn convertCYLto3D(r: *real_t, th1: *real_t, z: *real_t, am: u8, matrix: *real34Matrix_t, ctxtRealDisplay: *realContext_t) callconv(.c) void {
    var x: real_t = undefined;
    var y: real_t = undefined;
    var theta1: real_t = th1.*;

    runtime.convertAngleFromTo(&theta1, @as(angularMode_t, am), amRadian, ctxtRealDisplay);

    runtime.C47_WP34S_Cvt2RadSinCosTan(&theta1, amRadian, null, &x, null, ctxtRealDisplay);
    runtime.realMultiply(r, &x, &x, ctxtRealDisplay);

    runtime.C47_WP34S_Cvt2RadSinCosTan(&theta1, amRadian, &y, null, null, ctxtRealDisplay);
    runtime.realMultiply(r, &y, &y, ctxtRealDisplay);

    const elements = writeElements(matrix);
    runtime.realToReal34(&x, &elements[0]);
    runtime.realToReal34(&y, &elements[1]);
    runtime.realToReal34(z, &elements[2]);
}

pub export fn convert2DtoPOL(matrix: *const real34Matrix_t, r: *real_t, th1: *real_t, am: u8, ctxtRealDisplay: *realContext_t) callconv(.c) void {
    var x: real_t = undefined;
    var y: real_t = undefined;
    runtime._euclideanNormRealMatrix(matrix, 2, r, ctxtRealDisplay);

    const elements = readElements(matrix);
    runtime.real34ToReal(&elements[0], &x);
    runtime.real34ToReal(&elements[1], &y);

    runtime.C47_WP34S_Atan2(&y, &x, th1, ctxtRealDisplay);
    runtime.convertAngleFromTo(th1, amRadian, @as(angularMode_t, am), ctxtRealDisplay);
    if (runtime.realIsZero(th1)) {
        runtime.realSetZero(th1);
    }
}

pub export fn convertPOLto2D(r: *real_t, th1: *real_t, am: u8, matrix: *real34Matrix_t, ctxtRealDisplay: *realContext_t) callconv(.c) void {
    var x: real_t = undefined;
    var y: real_t = undefined;
    var theta1: real_t = th1.*;
    runtime.convertAngleFromTo(&theta1, @as(angularMode_t, am), amRadian, ctxtRealDisplay);
    runtime.realPolarToRectangular(r, &theta1, &x, &y, ctxtRealDisplay);
    const elements = writeElements(matrix);
    runtime.realToReal34(&x, &elements[0]);
    runtime.realToReal34(&y, &elements[1]);
}
