const logxy_command_owned = @import("math_logxy_command_owned.zig");
const matrix_vector_command_owned = @import("math_matrix_vector_command_owned.zig");
const percent_command_owned = @import("math_percent_command_owned.zig");
const special_function_sequence_command_owned = @import("math_special_function_sequence_command_owned.zig");
const tail_transform_wrappers_owned = @import("math_tail_transform_wrappers_owned.zig");

pub fn fnToPolar2(unused_but_mandatory_parameter: u16) callconv(.c) void { tail_transform_wrappers_owned.fnToPolar2(unused_but_mandatory_parameter); }
pub fn fnToRect2(unused_but_mandatory_parameter: u16) callconv(.c) void { tail_transform_wrappers_owned.fnToRect2(unused_but_mandatory_parameter); }
pub fn fnToRect(unused_but_mandatory_parameter: u16) callconv(.c) void { tail_transform_wrappers_owned.fnToRect(unused_but_mandatory_parameter); }
pub fn fnParallel(unused_but_mandatory_parameter: u16) callconv(.c) void { tail_transform_wrappers_owned.fnParallel(unused_but_mandatory_parameter); }
pub fn fnUnitVector(unused_but_mandatory_parameter: u16) callconv(.c) void { tail_transform_wrappers_owned.fnUnitVector(unused_but_mandatory_parameter); }

pub fn fnSdl(unused_but_mandatory_parameter: u16) callconv(.c) void { tail_transform_wrappers_owned.fnSdl(unused_but_mandatory_parameter); }
pub fn fnSdr(unused_but_mandatory_parameter: u16) callconv(.c) void { tail_transform_wrappers_owned.fnSdr(unused_but_mandatory_parameter); }

pub fn fnSquareRoot(unused_but_mandatory_parameter: u16) callconv(.c) void { tail_transform_wrappers_owned.fnSquareRoot(unused_but_mandatory_parameter); }
pub fn fnCubeRoot(unused_but_mandatory_parameter: u16) callconv(.c) void { tail_transform_wrappers_owned.fnCubeRoot(unused_but_mandatory_parameter); }

pub fn fnPercentMRR(unused_but_mandatory_parameter: u16) callconv(.c) void { percent_command_owned.percentMRR(unused_but_mandatory_parameter); }
pub fn fnPercentPlusMG(unused_but_mandatory_parameter: u16) callconv(.c) void { percent_command_owned.percentPlusMG(unused_but_mandatory_parameter); }
pub fn fnPercentT(unused_but_mandatory_parameter: u16) callconv(.c) void { percent_command_owned.percentT(unused_but_mandatory_parameter); }
pub fn fnDeltaPercent(unused_but_mandatory_parameter: u16) callconv(.c) void { percent_command_owned.deltaPercent(unused_but_mandatory_parameter); }

pub fn fnFib(unused_but_mandatory_parameter: u16) callconv(.c) void { special_function_sequence_command_owned.fnFib(unused_but_mandatory_parameter); }

pub fn fnLINPOL(unused_but_mandatory_parameter: u16) callconv(.c) void { matrix_vector_command_owned.fnLINPOL(unused_but_mandatory_parameter); }
pub fn fnCross(unused_but_mandatory_parameter: u16) callconv(.c) void { matrix_vector_command_owned.fnCross(unused_but_mandatory_parameter); }
pub fn fnDot(unused_but_mandatory_parameter: u16) callconv(.c) void { matrix_vector_command_owned.fnDot(unused_but_mandatory_parameter); }

pub fn fnLogXY(unused_but_mandatory_parameter: u16) callconv(.c) void { logxy_command_owned.fnLogXY(unused_but_mandatory_parameter); }
