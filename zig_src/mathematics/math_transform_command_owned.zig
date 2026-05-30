const parallel_command_owned = @import("math_transform_parallel_command_owned.zig");
const polar_rect_command_owned = @import("math_transform_polar_rect_command_owned.zig");
const power_command_owned = @import("math_transform_power_command_owned.zig");
const root_command_owned = @import("math_transform_root_command_owned.zig");
const unit_vector_command_owned = @import("math_transform_unit_vector_command_owned.zig");


pub fn square(unused_but_mandatory_parameter: u16) void {
    power_command_owned.square(unused_but_mandatory_parameter);
}

pub fn cube(unused_but_mandatory_parameter: u16) void {
    power_command_owned.cube(unused_but_mandatory_parameter);
}

pub fn squareRoot(unused_but_mandatory_parameter: u16) void {
    root_command_owned.squareRoot(unused_but_mandatory_parameter);
}

pub fn cubeRoot(unused_but_mandatory_parameter: u16) void {
    root_command_owned.cubeRoot(unused_but_mandatory_parameter);
}

pub fn toPolar2(unused_but_mandatory_parameter: u16) void {
    polar_rect_command_owned.toPolar2(unused_but_mandatory_parameter);
}

pub fn toRect2(unused_but_mandatory_parameter: u16) void {
    polar_rect_command_owned.toRect2(unused_but_mandatory_parameter);
}

pub fn toRect(unused_but_mandatory_parameter: u16) void {
    polar_rect_command_owned.toRect(unused_but_mandatory_parameter);
}

pub fn parallel(unused_but_mandatory_parameter: u16) void {
    parallel_command_owned.parallel(unused_but_mandatory_parameter);
}

pub fn unitVector(unused_but_mandatory_parameter: u16) void {
    unit_vector_command_owned.unitVector(unused_but_mandatory_parameter);
}