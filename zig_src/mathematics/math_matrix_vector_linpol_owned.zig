const pipeline_owned = @import("math_matrix_vector_linpol_pipeline_owned.zig");

pub fn linpol() callconv(.c) void {
    pipeline_owned.linpol();
}
