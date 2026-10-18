// SPDX-License-Identifier: GPL-3.0-only
// Zig port of the OPTION_VECTOR coordinate-conversion helpers of
// src/c47/mathematics/matrix.c: the rectangular <-> spherical / cylindrical /
// polar conversions used by the 2D/3D vector commands (items.c, addons.c, the
// matrix editor). These are pure decNumber numerics -- no MIM/register
// dispatch -- built on the complex polar conversions and the WP34S atan2 the
// runtime already exposes.
//
// matrix.c compiles all six with an empty `{;}` body in its `#else //OPTION_VECTOR`
// arm. defines.h #undef's OPTION_VECTOR in the block common to packages 1-4, so
// no DM42 package carries the conversion arithmetic: each function returns
// leaving every output untouched. The math object is built per package, so the
// option is a real per-build value here, not a constant.

const runtime = @import("../command_wrappers/runtime.zig");
const abi = @import("abi");

const real_t = runtime.real_t;
const cplx_t = runtime.cplx_t;
const real34_t = runtime.real34_t;
const real34Matrix_t = runtime.real34Matrix_t;
const realContext_t = runtime.realContext_t;
const angularMode_t = runtime.angularMode_t;
const amRadian = runtime.amRadian;

const readElements = abi.matrixConstRealElems;
const writeElements = abi.matrixRealElems;

pub export fn convert3DtoSPH(matrix: *const real34Matrix_t, r: *real_t, th1: *real_t, th2: *real_t, am: u8, ctxtRealDisplay: *realContext_t) callconv(.c) void {
    if (comptime !runtime.option_vector) return;
    var z: real_t = undefined;
    var xy_radius: real_t = undefined;
    var xy: cplx_t = undefined;
    runtime._euclideanNormRealMatrix(matrix, 2, r, ctxtRealDisplay);

    const elements = readElements(matrix);
    runtime.real34ToReal(&elements[0], &xy.Real);
    runtime.real34ToReal(&elements[1], &xy.Imag);
    runtime.real34ToReal(&elements[2], &z);

    if (runtime.realIsZero(&xy.Real) and runtime.realIsZero(&xy.Imag) and runtime.realIsZero(&z)) {
        // By convention [0 0 0] leaves both angles undefined; use 0.
        runtime.realSetZero(r);
        runtime.realSetZero(th1);
        runtime.realSetZero(th2);
    } else {
        runtime.realRectangularToPolar(&xy, &xy_radius, th1, ctxtRealDisplay);
        runtime.C47_WP34S_Atan2(&xy_radius, &z, th2, ctxtRealDisplay);
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

// th1 is the azimuth in the angular mode am1, th2 the polar angle in am2.
pub export fn convertSPHto3D(r: *real_t, th1: *real_t, th2: *real_t, am1: u8, am2: u8, matrix: *real34Matrix_t, ctxtRealDisplay: *realContext_t) callconv(.c) void {
    if (comptime !runtime.option_vector) return;
    var xy: cplx_t = undefined;
    var z_radius: cplx_t = undefined;

    // z_radius.Real is z, z_radius.Imag the radius of the xy projection.
    runtime.realPolarToRectangularInUnit(r, th2, @as(angularMode_t, am2), &z_radius, ctxtRealDisplay);
    if (runtime.realIsZero(&z_radius.Imag)) {
        runtime.realSetZero(&xy.Real);
        runtime.realSetZero(&xy.Imag);
    } else {
        runtime.realPolarToRectangularInUnit(&z_radius.Imag, th1, @as(angularMode_t, am1), &xy, ctxtRealDisplay);
    }

    const elements = writeElements(matrix);
    runtime.realToReal34(&xy.Real, &elements[0]);
    runtime.realToReal34(&xy.Imag, &elements[1]);
    runtime.realToReal34(&z_radius.Real, &elements[2]);
}

pub export fn convert3DtoCYL(matrix: *const real34Matrix_t, r: *real_t, th1: *real_t, z: *real_t, am: u8, ctxtRealDisplay: *realContext_t) callconv(.c) void {
    if (comptime !runtime.option_vector) return;
    var xy: cplx_t = undefined;
    const elements = readElements(matrix);
    runtime.real34ToReal(&elements[0], &xy.Real);
    runtime.real34ToReal(&elements[1], &xy.Imag);
    runtime.real34ToReal(&elements[2], z);

    runtime.realRectangularToPolar(&xy, r, th1, ctxtRealDisplay);

    runtime.convertAngleFromTo(th1, amRadian, @as(angularMode_t, am), ctxtRealDisplay);
    if (runtime.realIsZero(th1)) {
        runtime.realSetZero(th1);
    }
}

pub export fn convertCYLto3D(r: *real_t, th1: *real_t, z: *real_t, am: u8, matrix: *real34Matrix_t, ctxtRealDisplay: *realContext_t) callconv(.c) void {
    if (comptime !runtime.option_vector) return;
    var xy: cplx_t = undefined;

    runtime.realPolarToRectangularInUnit(r, th1, @as(angularMode_t, am), &xy, ctxtRealDisplay);

    const elements = writeElements(matrix);
    runtime.realToReal34(&xy.Real, &elements[0]);
    runtime.realToReal34(&xy.Imag, &elements[1]);
    runtime.realToReal34(z, &elements[2]);
}

pub export fn convert2DtoPOL(matrix: *const real34Matrix_t, r: *real_t, th1: *real_t, am: u8, ctxtRealDisplay: *realContext_t) callconv(.c) void {
    if (comptime !runtime.option_vector) return;
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
    if (comptime !runtime.option_vector) return;
    var xy: cplx_t = undefined;
    runtime.realPolarToRectangularInUnit(r, th1, @as(angularMode_t, am), &xy, ctxtRealDisplay);
    const elements = writeElements(matrix);
    runtime.realToReal34(&xy.Real, &elements[0]);
    runtime.realToReal34(&xy.Imag, &elements[1]);
}
