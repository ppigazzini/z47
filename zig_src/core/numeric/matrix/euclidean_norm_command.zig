// SPDX-License-Identifier: GPL-3.0-only
// Zig port of the euclidean-norm commands of src/c47/mathematics/matrix.c:
// fnVectorDist, with its worker _fnEuclideanNorm (kept private here). The
// sibling fnEuclideanNorm went with upstream's "remove two functions the tree
// no longer calls": no item row and no caller ever reached it. The numeric p-norm is the already
// Zig-owned euclideanNormRealMatrix / euclideanNormComplexMatrix; these are the
// command-level wrappers that link register X, drive the norm and store the
// scalar result. fnVectorDist is the distance |Y - X| = subtract then 2-norm.

const std = @import("std");
const runtime = @import("../command_wrappers/runtime.zig");

const real34_t = runtime.real34_t;
const real34Matrix_t = runtime.real34Matrix_t;
const complex34Matrix_t = runtime.complex34Matrix_t;

const nim_register_line = runtime.REGISTER_X;

inline fn real34Copy(source: *const real34_t, destination: *real34_t) void {
    destination.* = source.*;
}

fn bufPrintZ(buffer: []u8, comptime format: []const u8, args: anytype) ![:0]u8 {
    const slice = try std.fmt.bufPrint(buffer[0 .. buffer.len - 1], format, args);
    buffer[slice.len] = 0;
    return buffer[0..slice.len :0];
}

// Exported (was file-local) so fnPNorm in the MIM-commands owner can dispatch
// to it; _fnEuclideanNorm is static in matrix.c so there is no symbol clash.
pub export fn _fnEuclideanNorm(p_param: u16) callconv(.c) void {
    const data_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    if (data_type == runtime.dtReal34Matrix) {
        var matrix: real34Matrix_t = undefined;
        var sum: real34_t = undefined;
        runtime.linkToRealMatrixRegister(runtime.REGISTER_X, &matrix);
        runtime.euclideanNormRealMatrix(&matrix, p_param, &sum);
        // `matrix` invalidates here.
        runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
        real34Copy(&sum, runtime.registerReal34Data(runtime.REGISTER_X));
    } else if (data_type == runtime.dtComplex34Matrix) {
        var matrix: complex34Matrix_t = undefined;
        var sum: real34_t = undefined;
        runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &matrix);
        runtime.euclideanNormComplexMatrix(&matrix, p_param, &sum);
        // `matrix` invalidates here.
        runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
        real34Copy(&sum, runtime.registerReal34Data(runtime.REGISTER_X));
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, nim_register_line);
        if (runtime.extra_info_on_calc_error) {
            var buffer: [64]u8 = undefined;
            const message = bufPrintZ(&buffer, "DataType {d}", .{data_type}) catch "DataType";
            runtime.moreInfoOnError("In function _fnEuclideanNorm:", message, "is not a matrix.", "");
        }
    }

    runtime.adjustResult(runtime.REGISTER_X, false, true, runtime.REGISTER_X, -1, -1);
}

pub export fn fnVectorDist(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.fnSubtract(runtime.NOPARAM);
    _fnEuclideanNorm(2);
}
