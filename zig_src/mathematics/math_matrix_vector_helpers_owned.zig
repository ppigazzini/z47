// SPDX-License-Identifier: GPL-3.0-only
// Zig port of two OPTION_VECTOR helpers of src/c47/mathematics/matrix.c:
//   - V3err raises the "2D/3D vector required" calc error (with the EXTRA_INFO
//     console hint reproduced) for the rectangular <-> polar vector commands.
//   - VtoAngleMode sets a vector register's angular mode when X holds a vector.
// Both are consumed by the already-ported addons owner (the fnToSpherical /
// fnToCylindrical / fnToPolar / fnVectorAngleMode commands).

const std = @import("std");
const runtime = @import("math_command_wrappers_runtime.zig");

const calcRegister_t = runtime.calcRegister_t;
const angularMode_t = runtime.angularMode_t;

// defines.h: raised when X is not a 2D/3D vector for a polar/rect conversion.
const ERROR_INVALID_DATA_TYPE_FOR_POLAR_RECT: u8 = 52;

fn bufPrintZ(buffer: []u8, comptime format: []const u8, args: anytype) ![:0]u8 {
    const slice = try std.fmt.bufPrint(buffer[0 .. buffer.len - 1], format, args);
    buffer[slice.len] = 0;
    return buffer[0 .. slice.len :0];
}

pub export fn V3err(err: c_int) callconv(.c) void {
    runtime.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_POLAR_RECT, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
    // EXTRA_INFO_ON_CALC_ERROR is comptime-off in the testSuite build, so this
    // mirrors the upstream #if guard exactly (the hint is host-only).
    if (runtime.extra_info_on_calc_error) {
        var buffer: [128]u8 = undefined;
        const header = runtime.registerMatrixHeader(runtime.REGISTER_X);
        const name = std.mem.span(runtime.getRegisterDataTypeName(runtime.REGISTER_X, true, false));
        const message = bufPrintZ(&buffer, "Err {d}: 2D or 3D Vector required, not {s}, {d}x{d}", .{
            err,
            name,
            header.matrixRows,
            header.matrixColumns,
        }) catch "Err: 2D or 3D Vector required";
        runtime.moreInfoOnError("In function V3RectoToSph/V3RectoToCyl:", message, null, null);
    }
}

pub export fn VtoAngleMode(angleMode: angularMode_t) callconv(.c) bool {
    if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtReal34Matrix) {
        if (runtime.isRegisterMatrixVector(runtime.REGISTER_X)) {
            runtime.setVectorRegisterAngularMode(runtime.REGISTER_X, angleMode);
            runtime.temporaryInformation = runtime.TI_VECTOR;
        } else {
            return false;
        }
    } else {
        return false;
    }
    return true;
}
