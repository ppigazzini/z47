const std = @import("std");
const runtime = @import("../command_wrappers/runtime.zig");

const math_matrix_kinds = @import("kinds.zig"); // std-only matrix operand kinds + size validity
pub const MatrixOperandKinds = math_matrix_kinds.MatrixOperandKinds;

const STD_CROSS = "\x80\xd7"; // fonts.h

// The two operand shapes a cross/dot matrix path names when it refuses them:
// the X operand first, then Y, in the order upstream's sprintf takes them.
pub const MatrixShapes = struct {
    x_rows: u12,
    x_columns: u12,
    y_rows: u12,
    y_columns: u12,
};

fn matrixMismatchError(function_name: [:0]const u8, comptime format: []const u8, shapes: MatrixShapes) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
    if (runtime.extra_info_on_calc_error) {
        var message_buffer: [96]u8 = undefined;
        const message = runtime.bufPrintZ(&message_buffer, format, .{ shapes.x_rows, shapes.x_columns, shapes.y_rows, shapes.y_columns }) catch "matrix dimension mismatch";
        runtime.moreInfoOnError(function_name, message, null, null);
    }
}

// CROSS between vectors whose element counts are zero or above three.
pub fn crossMatrixMismatchError(function_name: [:0]const u8, shapes: MatrixShapes) void {
    matrixMismatchError(function_name, "invalid numbers of elements of {d}" ++ STD_CROSS ++ "{d}-matrix to {d}" ++ STD_CROSS ++ "{d}-matrix", shapes);
}

// DOT between vectors whose element counts are zero or differ.
pub fn dotMatrixMismatchError(function_name: [:0]const u8, shapes: MatrixShapes) void {
    matrixMismatchError(function_name, "numbers of elements of {d}" ++ STD_CROSS ++ "{d}-matrix to {d}" ++ STD_CROSS ++ "{d}-matrix mismatch", shapes);
}

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
