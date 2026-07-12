// SPDX-License-Identifier: GPL-3.0-only
// Zig port of the vector cross-product cluster of
// src/c47/mathematics/matrix.c: crossRealVectors / crossComplexVectors (the
// 3D vector cross product, zero-padding 2D inputs). The vector angle and the
// rest of the engine stay in the matrix bridge.

const runtime = @import("../dispatch/command_wrappers_runtime.zig");
const abi = @import("abi");

const real_t = runtime.real_t;
const real34_t = runtime.real34_t;
const real34Matrix_t = runtime.real34Matrix_t;
const complex34Matrix_t = runtime.complex34Matrix_t;

const nim_register_line = runtime.REGISTER_X;

const constRealElems = abi.matrixConstRealElems;
const constComplexElems = abi.matrixConstComplexElems;
const realElems = abi.matrixRealElems;
const complexElems = abi.matrixComplexElems;

fn reportRamFull(comptime function_name: [*:0]const u8) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE, nim_register_line);
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
        runtime.realMultiply(&a2, &b3, &p, &runtime.ctxtReal39);
        runtime.realMultiply(&a3, &b2, &q, &runtime.ctxtReal39);
        runtime.realSubtract(&p, &q, &p, &runtime.ctxtReal39);
        runtime.realToReal34(&p, &re[0]);

        runtime.realMultiply(&a3, &b1, &p, &runtime.ctxtReal39);
        runtime.realMultiply(&a1, &b3, &q, &runtime.ctxtReal39);
        runtime.realSubtract(&p, &q, &p, &runtime.ctxtReal39);
        runtime.realToReal34(&p, &re[1]);

        runtime.realMultiply(&a1, &b2, &p, &runtime.ctxtReal39);
        runtime.realMultiply(&a2, &b1, &q, &runtime.ctxtReal39);
        runtime.realSubtract(&p, &q, &p, &runtime.ctxtReal39);
        runtime.realToReal34(&p, &re[2]);
    } else {
        reportRamFull("In function crossRealVectors:");
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
    var a1r: real_t = undefined;
    var a1i: real_t = undefined;
    var a2r: real_t = undefined;
    var a2i: real_t = undefined;
    var a3r: real_t = undefined;
    var a3i: real_t = undefined;
    var b1r: real_t = undefined;
    var b1i: real_t = undefined;
    var b2r: real_t = undefined;
    var b2i: real_t = undefined;
    var b3r: real_t = undefined;
    var b3i: real_t = undefined;
    var pr: real_t = undefined;
    var pi: real_t = undefined;
    var qr: real_t = undefined;
    var qi: real_t = undefined;

    runtime.real34ToReal(&ye[0].real, &a1r);
    runtime.real34ToReal(&ye[0].imag, &a1i);
    loadOrZero(elements_y >= 2, &ye[1].real, &a2r);
    loadOrZero(elements_y >= 2, &ye[1].imag, &a2i);
    loadOrZero(elements_y >= 3, &ye[2].real, &a3r);
    loadOrZero(elements_y >= 3, &ye[2].imag, &a3i);

    runtime.real34ToReal(&xe[0].real, &b1r);
    runtime.real34ToReal(&xe[0].imag, &b1i);
    loadOrZero(elements_x >= 2, &xe[1].real, &b2r);
    loadOrZero(elements_x >= 2, &xe[1].imag, &b2i);
    loadOrZero(elements_x >= 3, &xe[2].real, &b3r);
    loadOrZero(elements_x >= 3, &xe[2].imag, &b3i);

    if (runtime.complexMatrixInit(res, 1, 3)) {
        const re = complexElems(res);
        runtime.mulComplexComplex(&a2r, &a2i, &b3r, &b3i, &pr, &pi, &runtime.ctxtReal39);
        runtime.mulComplexComplex(&a3r, &a3i, &b2r, &b2i, &qr, &qi, &runtime.ctxtReal39);
        runtime.realSubtract(&pr, &qr, &pr, &runtime.ctxtReal39);
        runtime.realSubtract(&pi, &qi, &pi, &runtime.ctxtReal39);
        runtime.realToReal34(&pr, &re[0].real);
        runtime.realToReal34(&pi, &re[0].imag);

        runtime.mulComplexComplex(&a3r, &a3i, &b1r, &b1i, &pr, &pi, &runtime.ctxtReal39);
        runtime.mulComplexComplex(&a1r, &a1i, &b3r, &b3i, &qr, &qi, &runtime.ctxtReal39);
        runtime.realSubtract(&pr, &qr, &pr, &runtime.ctxtReal39);
        runtime.realSubtract(&pi, &qi, &pi, &runtime.ctxtReal39);
        runtime.realToReal34(&pr, &re[1].real);
        runtime.realToReal34(&pi, &re[1].imag);

        runtime.mulComplexComplex(&a1r, &a1i, &b2r, &b2i, &pr, &pi, &runtime.ctxtReal39);
        runtime.mulComplexComplex(&a2r, &a2i, &b1r, &b1i, &qr, &qi, &runtime.ctxtReal39);
        runtime.realSubtract(&pr, &qr, &pr, &runtime.ctxtReal39);
        runtime.realSubtract(&pi, &qi, &pi, &runtime.ctxtReal39);
        runtime.realToReal34(&pr, &re[2].real);
        runtime.realToReal34(&pi, &re[2].imag);
    } else {
        reportRamFull("In function crossComplexVectors:");
    }
}
