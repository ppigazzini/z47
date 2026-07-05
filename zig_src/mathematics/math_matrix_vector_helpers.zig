// SPDX-License-Identifier: GPL-3.0-only
// Zig port of the OPTION_VECTOR register-side helpers of
// src/c47/mathematics/matrix.c:
//   - V3err raises the "2D/3D vector required" calc error (with the EXTRA_INFO
//     console hint reproduced) for the rectangular <-> polar vector commands.
//   - VtoAngleMode sets a vector register's angular mode when X holds a vector.
//   - fnComplexToVector converts X between a complex34 and a 2D-vector matrix.
// All are consumed by the already-ported addons owner (the fnToSpherical /
// fnToCylindrical / fnToPolar / fnVectorAngleMode / CPXexV commands).

const std = @import("std");
const abi = @import("abi");
const runtime = @import("math_command_wrappers_runtime.zig");

const calcRegister_t = runtime.calcRegister_t;
const angularMode_t = runtime.angularMode_t;
const real34_t = runtime.real34_t;
const real34Matrix_t = runtime.real34Matrix_t;

// defines.h: raised when X is not a 2D/3D vector for a polar/rect conversion.
const ERROR_INVALID_DATA_TYPE_FOR_POLAR_RECT: u8 = 52;
// registers.h FIRST_TEMP_REGISTER scratch slot; items.h vector<->complex codes.
const TEMP_REGISTER_1: calcRegister_t = 135;
const ITM_CPXexV: u16 = 2492;
const ITM_CPXtoV: u16 = 2493;
const ITM_VtoCPX: u16 = 2494;

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

// CPX <-> 2D-vector conversion command. Not MIM-routed -- a straight register
// reshape -- so it ports against the register accessors the runtime already
// exposes (and the Zig-owned initMatrixRegister). real34Copy is a real34_t
// struct copy (`dst.* = src.*`).
pub export fn fnComplexToVector(opType: u16) callconv(.c) void {
    var matrix: real34Matrix_t = undefined;
    if (runtime.isRegisterMatrix2dVector(runtime.REGISTER_X) and (opType == ITM_CPXexV or opType == ITM_VtoCPX)) {
        // MatrixVector2D ==> Complex
        runtime.copySourceRegisterToDestRegister(runtime.REGISTER_X, TEMP_REGISTER_1);
        runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtComplex34, 0, runtime.amNone);
        runtime.linkToRealMatrixRegister(TEMP_REGISTER_1, &matrix);
        const elements: [*]const real34_t = abi.matrixConstRealElems(matrix);
        runtime.registerReal34Data(runtime.REGISTER_X).* = elements[0];
        runtime.registerImag34Data(runtime.REGISTER_X).* = elements[1];
        runtime.adjustResult(runtime.REGISTER_X, false, true, runtime.REGISTER_X, -1, -1);
        runtime.setComplexRegisterAngularMode(runtime.REGISTER_X, runtime.getVectorRegisterAngularMode(TEMP_REGISTER_1));
        runtime.setComplexRegisterPolarMode(runtime.REGISTER_X, if (runtime.getVectorRegisterPolarMode(TEMP_REGISTER_1) == runtime.amPolar) runtime.amPolar else runtime.amNone);
        runtime.clearRegister(TEMP_REGISTER_1);
        return;
    } else if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtComplex34 and (opType == ITM_CPXexV or opType == ITM_CPXtoV)) {
        // Complex ==> MatrixVector2D
        runtime.copySourceRegisterToDestRegister(runtime.REGISTER_X, TEMP_REGISTER_1);
        // Initialize memory for the matrix; converting complex34 -> real 2D
        // vector needs no extra bytes, so an allocation failure is ignored.
        if (!runtime.initMatrixRegister(runtime.REGISTER_X, 1, 2, false)) {
            return;
        }
        runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, -1, -1);
        runtime.linkToRealMatrixRegister(runtime.REGISTER_X, &matrix);
        const elements: [*]real34_t = abi.matrixRealElems(matrix);
        elements[0] = runtime.registerReal34Data(TEMP_REGISTER_1).*;
        elements[1] = runtime.registerImag34Data(TEMP_REGISTER_1).*;
        runtime.adjustResult(runtime.REGISTER_X, false, true, runtime.REGISTER_X, -1, -1);
        runtime.setVectorRegisterAngularMode(runtime.REGISTER_X, runtime.getComplexRegisterAngularMode(TEMP_REGISTER_1));
        runtime.setVectorRegisterPolarMode(runtime.REGISTER_X, runtime.getComplexRegisterPolarMode(TEMP_REGISTER_1));
        runtime.clearRegister(TEMP_REGISTER_1);
        return;
    }

    // NIM_REGISTER_LINE is REGISTER_X (defines.h).
    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
    if (runtime.extra_info_on_calc_error) {
        var buffer: [128]u8 = undefined;
        const nameY = std.mem.span(runtime.getRegisterDataTypeName(runtime.REGISTER_Y, true, false));
        const nameX = std.mem.span(runtime.getRegisterDataTypeName(runtime.REGISTER_X, true, false));
        const message = bufPrintZ(&buffer, "invalid data type {s} and {s}", .{ nameY, nameX }) catch "invalid data type";
        runtime.moreInfoOnError("In function fnComplexToVector:", message, null, null);
    }
}
