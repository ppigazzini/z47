const diagnostics_owned = @import("math_matrix_vector_diagnostics_owned.zig");
const matrix_owned = @import("math_matrix_vector_cross_matrix_owned.zig");
const runtime = @import("math_command_wrappers_runtime.zig");
const scalar_owned = @import("math_matrix_vector_cross_scalar_owned.zig");
const validation_owned = @import("math_matrix_vector_validation_owned.zig");

pub fn cross(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    if (matrix_owned.tryCrossMatrices()) {
        return;
    }

    if (validation_owned.classifyCurrentOperands().hasAnyMatrix()) {
        diagnostics_owned.crossDotMatrixTypeError("In function fnCross:");
        return;
    }

    scalar_owned.runScalarCross();
}
