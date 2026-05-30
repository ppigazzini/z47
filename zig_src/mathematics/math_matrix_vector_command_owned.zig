const cross_owned = @import("math_matrix_vector_cross_owned.zig");
const dot_owned = @import("math_matrix_vector_dot_owned.zig");
const linpol_owned = @import("math_matrix_vector_linpol_owned.zig");

pub fn fnCross(unused_but_mandatory_parameter: u16) callconv(.c) void {
    cross_owned.cross(unused_but_mandatory_parameter);
}

pub fn fnDot(unused_but_mandatory_parameter: u16) callconv(.c) void {
    dot_owned.dot(unused_but_mandatory_parameter);
}

pub fn fnLINPOL(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    linpol_owned.linpol();
}
