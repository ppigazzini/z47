const std = @import("std");
const runtime = @import("../dispatch/command_wrappers_runtime.zig");

const math_matrix_kinds = @import("kinds.zig"); // std-only matrix operand kinds + size validity
pub const MatrixOperandKinds = math_matrix_kinds.MatrixOperandKinds;

// The type-error diagnostic raised when cross/dot validation rejects the current
// operands: reports "cannot raise <Y type> to <X type>" for the offending pair.
pub fn crossDotMatrixTypeError(function_name: [:0]const u8) void {
    var message1_buffer: [96]u8 = undefined;
    var message2_buffer: [64]u8 = undefined;
    const y_type_name = std.mem.span(runtime.getRegisterDataTypeName(runtime.REGISTER_Y, true, false));
    const x_type_name = std.mem.span(runtime.getRegisterDataTypeName(runtime.REGISTER_X, true, false));
    const message1 = runtime.bufPrintZ(&message1_buffer, "cannot raise {s}", .{y_type_name}) catch "cannot raise current Y type";
    const message2 = runtime.bufPrintZ(&message2_buffer, "to {s}", .{x_type_name}) catch "to current X type";

    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
    runtime.moreInfoOnError(function_name, message1, message2, null);
}

pub fn classifyCurrentOperands() MatrixOperandKinds {
    const type_x = runtime.getRegisterDataType(runtime.REGISTER_X);
    const type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);

    return .{
        .x_is_real_matrix = type_x == runtime.dtReal34Matrix,
        .x_is_complex_matrix = type_x == runtime.dtComplex34Matrix,
        .y_is_real_matrix = type_y == runtime.dtReal34Matrix,
        .y_is_complex_matrix = type_y == runtime.dtComplex34Matrix,
    };
}

pub fn isValidCrossRealVectors(x_matrix: *const runtime.real34Matrix_t, y_matrix: *const runtime.real34Matrix_t) bool {
    const x_size = runtime.realVectorSize(x_matrix);
    const y_size = runtime.realVectorSize(y_matrix);

    return math_matrix_kinds.crossSizesValid(x_size, y_size);
}

pub fn isValidCrossComplexVectors(x_matrix: *const runtime.complex34Matrix_t, y_matrix: *const runtime.complex34Matrix_t) bool {
    const x_size = runtime.complexVectorSize(x_matrix);
    const y_size = runtime.complexVectorSize(y_matrix);

    return math_matrix_kinds.crossSizesValid(x_size, y_size);
}

pub fn isValidDotRealVectors(x_matrix: *const runtime.real34Matrix_t, y_matrix: *const runtime.real34Matrix_t) bool {
    const x_size = runtime.realVectorSize(x_matrix);
    const y_size = runtime.realVectorSize(y_matrix);

    return math_matrix_kinds.dotSizesValid(x_size, y_size);
}

pub fn isValidDotComplexVectors(x_matrix: *const runtime.complex34Matrix_t, y_matrix: *const runtime.complex34Matrix_t) bool {
    const x_size = runtime.complexVectorSize(x_matrix);
    const y_size = runtime.complexVectorSize(y_matrix);

    return math_matrix_kinds.dotSizesValid(x_size, y_size);
}
