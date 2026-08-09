// SPDX-License-Identifier: GPL-3.0-only
const abi = @import("abi");
const consts = abi.constants;
// Zig port of the determinant cluster of src/c47/mathematics/matrix.c:
// detRealMatrix / detComplexMatrix. Both pack the matrix into an interleaved
// real/imag real_t scratch array and run a partial-pivoting complex LU
// decomposition (the static worker detCpxMat is kept private here; the complex
// LU worker is shared, so this owner calls the one in complex_core),
// then multiply the diagonal and flip sign per pivot swap. The remaining
// linear-algebra engine (QR, eigen, inverse, sqrt) and the LU helpers that the
// not-yet-ported engine still calls stay in the matrix bridge as their own C
// statics; only the two public determinant entry points are renamed.

const runtime = @import("../command_wrappers/runtime.zig");
const math_matrix_complex_core = @import("complex_core.zig");
const math_comparison_reals = @import("../compare/comparison_reals.zig");
const real_t = runtime.real_t;
const real34_t = runtime.real34_t;
const real34Matrix_t = runtime.real34Matrix_t;
const complex34Matrix_t = runtime.complex34Matrix_t;

const nim_register_line = runtime.REGISTER_X;

// REAL_SIZE_IN_BLOCKS(75) == TO_BLOCKS(sizeof(real_t)) == 15; a packed real_t
// occupies exactly that, so the scratch arrays index real_t with native stride.
const real_size_in_blocks: usize = (@sizeOf(real_t) + 3) >> 2;

// matrix.c block allocator and the comparison / constant surface the LU needs.
extern fn allocC47Blocks(size_in_blocks: usize) callconv(.c) ?*anyopaque;
extern fn freeC47Blocks(ptr: ?*anyopaque, size_in_blocks: usize) callconv(.c) void;

// const_1e_37 is "#define const_1e_37 ((real_t *)(constants + 4436))" in the
// generated constantPointers.h; hand out the same pointer into the blob.
inline fn const_1e_37() *const real_t {
    return consts.c4436();
}

const constRealElems = abi.matrixConstRealElems;
const constComplexElems = abi.matrixConstComplexElems;

inline fn realCopy(source: *const real_t, destination: *real_t) void {
    destination.* = source.*;
}

fn reportRamFull(comptime function_name: [*:0]const u8, comptime info: [*:0]const u8) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE, nim_register_line);
    if (runtime.extra_info_on_calc_error) {
        runtime.moreInfoOnError(function_name, info, null, null);
    }
}

// Determinant of an interleaved-complex size*size matrix. Mirrors the static
// detCpxMat in matrix.c.
fn detCpxMat(matrix: [*]const real_t, size: u16, res_r: *real_t, res_i: *real_t, real_context: *runtime.realContext_t) void {
    const n: usize = size;
    const lu_blocks = n * n * real_size_in_blocks * 2;
    if (allocC47Blocks(lu_blocks)) |lu_raw| {
        const lu: [*]real_t = @ptrCast(@alignCast(lu_raw));
        @memcpy(lu[0 .. n * n * 2], matrix[0 .. n * n * 2]);
        const p_blocks = (n * @sizeOf(u16) + 3) >> 2;
        if (allocC47Blocks(p_blocks)) |p_raw| {
            const p: [*]u16 = @ptrCast(@alignCast(p_raw));
            var tr: real_t = undefined;
            var ti: real_t = undefined;
            runtime.realSetOne(&tr);
            runtime.realSetZero(&ti);
            if (math_matrix_complex_core.luCpxMat(lu, size, p, real_context)) {
                var i: usize = 0;
                while (i < n) : (i += 1) {
                    runtime.mulComplexComplex(&tr, &ti, &lu[(i * n + i) * 2], &lu[(i * n + i) * 2 + 1], &tr, &ti, real_context);
                }
                i = 0;
                while (i < n) : (i += 1) {
                    if (p[i] != @as(u16, @intCast(i))) {
                        runtime.realChangeSign(&tr);
                        runtime.realChangeSign(&ti);
                    }
                }
                realCopy(&tr, res_r);
                realCopy(&ti, res_i);
            } else { // singular
                runtime.realSetZero(res_r);
                runtime.realSetZero(res_i);
            }
            freeC47Blocks(p_raw, p_blocks);
        } else {
            reportRamFull("In function detCpxMat:", "Ram full, 1o");
            runtime.realSetNaN(res_r);
            runtime.realSetNaN(res_i);
        }
        freeC47Blocks(lu_raw, lu_blocks);
    } else {
        reportRamFull("In function detCpxMat:", "Ram full, 2p");
        runtime.realSetNaN(res_r);
        runtime.realSetNaN(res_i);
    }
}

pub export fn detRealMatrix(matrix: *const real34Matrix_t, res: *real34_t) callconv(.c) void {
    const n = matrix.header.matrixColumns;
    if (matrix.header.matrixRows != n) {
        runtime.realToReal34(runtime.const_NaN, res);
        return;
    }

    const nn = @as(usize, n) * @as(usize, n);
    const lu_blocks = nn * real_size_in_blocks * 2;
    if (allocC47Blocks(lu_blocks)) |lu_raw| {
        const lu: [*]real_t = @ptrCast(@alignCast(lu_raw));
        const me = constRealElems(matrix);
        var i: usize = 0;
        while (i < nn) : (i += 1) {
            runtime.real34ToReal(&me[i], &lu[i * 2]);
            runtime.realSetZero(&lu[i * 2 + 1]);
        }
        var tr: real_t = undefined;
        var ti: real_t = undefined;
        detCpxMat(lu, n, &tr, &ti, &runtime.ctxtReal51);
        freeC47Blocks(lu_raw, lu_blocks);
        runtime.realToReal34(&tr, res);
    } else {
        reportRamFull("In function detRealMatrix:", "Ram full");
        runtime.realToReal34(runtime.const_NaN, res);
    }
}

pub export fn detComplexMatrix(matrix: *const complex34Matrix_t, res_r: *real34_t, res_i: *real34_t) callconv(.c) void {
    const n = matrix.header.matrixColumns;
    if (matrix.header.matrixRows != n) {
        runtime.realToReal34(runtime.const_NaN, res_r);
        runtime.realToReal34(runtime.const_NaN, res_i);
        return;
    }

    const nn = @as(usize, n) * @as(usize, n);
    const lu_blocks = nn * real_size_in_blocks * 2;
    if (allocC47Blocks(lu_blocks)) |lu_raw| {
        const lu: [*]real_t = @ptrCast(@alignCast(lu_raw));
        const me = constComplexElems(matrix);
        var i: usize = 0;
        while (i < nn) : (i += 1) {
            runtime.real34ToReal(&me[i].real, &lu[i * 2]);
            runtime.real34ToReal(&me[i].imag, &lu[i * 2 + 1]);
        }
        var tr: real_t = undefined;
        var ti: real_t = undefined;
        detCpxMat(lu, n, &tr, &ti, &runtime.ctxtReal51);
        freeC47Blocks(lu_raw, lu_blocks);
        runtime.realToReal34(&tr, res_r);
        runtime.realToReal34(&ti, res_i);
    } else {
        reportRamFull("In function detComplexMatrix:", "Ram full");
        runtime.realToReal34(runtime.const_NaN, res_r);
        runtime.realToReal34(runtime.const_NaN, res_i);
    }
}
