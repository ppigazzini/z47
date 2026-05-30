const shift_digits_command_owned = @import("math_shift_digits_command_owned.zig");
const transform_command_owned = @import("math_transform_command_owned.zig");

pub fn fnToPolar2(unused_but_mandatory_parameter: u16) callconv(.c) void { transform_command_owned.toPolar2(unused_but_mandatory_parameter); }
pub fn fnToRect2(unused_but_mandatory_parameter: u16) callconv(.c) void { transform_command_owned.toRect2(unused_but_mandatory_parameter); }
pub fn fnToRect(unused_but_mandatory_parameter: u16) callconv(.c) void { transform_command_owned.toRect(unused_but_mandatory_parameter); }
pub fn fnParallel(unused_but_mandatory_parameter: u16) callconv(.c) void { transform_command_owned.parallel(unused_but_mandatory_parameter); }
pub fn fnUnitVector(unused_but_mandatory_parameter: u16) callconv(.c) void { transform_command_owned.unitVector(unused_but_mandatory_parameter); }

pub fn fnSdl(unused_but_mandatory_parameter: u16) callconv(.c) void { shift_digits_command_owned.sdl(unused_but_mandatory_parameter); }
pub fn fnSdr(unused_but_mandatory_parameter: u16) callconv(.c) void { shift_digits_command_owned.sdr(unused_but_mandatory_parameter); }

pub fn fnSquareRoot(unused_but_mandatory_parameter: u16) callconv(.c) void { transform_command_owned.squareRoot(unused_but_mandatory_parameter); }
pub fn fnCubeRoot(unused_but_mandatory_parameter: u16) callconv(.c) void { transform_command_owned.cubeRoot(unused_but_mandatory_parameter); }