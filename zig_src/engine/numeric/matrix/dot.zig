// SPDX-License-Identifier: GPL-3.0-only
// Zig port of the vector dot-product cluster of
// src/c47/mathematics/matrix.c: dotRealVectors / dotComplexVectors and the
// shared real_t worker _dotRealVectors. The cross products, the vector angle
// and the rest of the engine stay in the matrix bridge until the later B
// clusters land.

const runtime = @import("../command_wrappers_runtime.zig");
const abi = @import("abi");

const real_t = runtime.real_t;
const real34_t = runtime.real34_t;
const real34Matrix_t = runtime.real34Matrix_t;
const complex34Matrix_t = runtime.complex34Matrix_t;

const constRealElems = abi.matrixConstRealElems;
const constComplexElems = abi.matrixConstComplexElems;

// Static worker, exported so the vector-angle owner can reuse it. The bridge
// renames the legacy copy that the not-yet-ported vectorAngle still calls.
pub export fn _dotRealVectors(y: *const real34Matrix_t, x: *const real34Matrix_t, res: *real_t, real_context: *runtime.realContext_t) callconv(.c) void {
    const elements = runtime.realVectorSize(y);
    var sum: real_t = undefined;
    var p: real_t = undefined;
    var q: real_t = undefined;
    runtime.realSetZero(&sum);
    const ye = constRealElems(y);
    const xe = constRealElems(x);
    var i: usize = 0;
    while (i < elements) : (i += 1) {
        runtime.real34ToReal(&ye[i], &p);
        runtime.real34ToReal(&xe[i], &q);
        var temp_pq: real_t = undefined;
        runtime.realFMA(&p, &q, &sum, &temp_pq, real_context);
        sum = temp_pq;
    }
    res.* = sum;
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
    var sumr: real_t = undefined;
    var sumi: real_t = undefined;
    var prodr: real_t = undefined;
    var prodi: real_t = undefined;
    var pr: real_t = undefined;
    var pi: real_t = undefined;
    var qr: real_t = undefined;
    var qi: real_t = undefined;
    runtime.realSetZero(&sumr);
    runtime.realSetZero(&sumi);
    runtime.realSetZero(&prodr);
    runtime.realSetZero(&prodi);
    const ye = constComplexElems(y);
    const xe = constComplexElems(x);
    var i: usize = 0;
    while (i < elements) : (i += 1) {
        runtime.real34ToReal(&ye[i].real, &pr);
        runtime.real34ToReal(&ye[i].imag, &pi);
        runtime.real34ToReal(&xe[i].real, &qr);
        runtime.real34ToReal(&xe[i].imag, &qi);
        runtime.mulComplexComplex(&pr, &pi, &qr, &qi, &prodr, &prodi, &runtime.ctxtReal39);
        runtime.realAdd(&sumr, &prodr, &sumr, &runtime.ctxtReal39);
        runtime.realAdd(&sumi, &prodi, &sumi, &runtime.ctxtReal39);
    }
    runtime.realToReal34(&sumr, res_r);
    runtime.realToReal34(&sumi, res_i);
}
