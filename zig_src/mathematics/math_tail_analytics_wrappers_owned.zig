const logxy_command_owned = @import("math_logxy_command_owned.zig");
const matrix_vector_command_owned = @import("math_matrix_vector_command_owned.zig");
const percent_command_owned = @import("math_percent_command_owned.zig");
const special_function_sequence_command_owned = @import("math_special_function_sequence_command_owned.zig");

pub fn fnPercentMRR(unused_but_mandatory_parameter: u16) callconv(.c) void { percent_command_owned.percentMRR(unused_but_mandatory_parameter); }
pub fn fnPercentPlusMG(unused_but_mandatory_parameter: u16) callconv(.c) void { percent_command_owned.percentPlusMG(unused_but_mandatory_parameter); }
pub fn fnPercentT(unused_but_mandatory_parameter: u16) callconv(.c) void { percent_command_owned.percentT(unused_but_mandatory_parameter); }
pub fn fnDeltaPercent(unused_but_mandatory_parameter: u16) callconv(.c) void { percent_command_owned.deltaPercent(unused_but_mandatory_parameter); }

pub fn fnFib(unused_but_mandatory_parameter: u16) callconv(.c) void { special_function_sequence_command_owned.fnFib(unused_but_mandatory_parameter); }

pub fn fnLINPOL(unused_but_mandatory_parameter: u16) callconv(.c) void { matrix_vector_command_owned.fnLINPOL(unused_but_mandatory_parameter); }
pub fn fnCross(unused_but_mandatory_parameter: u16) callconv(.c) void { matrix_vector_command_owned.fnCross(unused_but_mandatory_parameter); }
pub fn fnDot(unused_but_mandatory_parameter: u16) callconv(.c) void { matrix_vector_command_owned.fnDot(unused_but_mandatory_parameter); }

pub fn fnLogXY(unused_but_mandatory_parameter: u16) callconv(.c) void { logxy_command_owned.fnLogXY(unused_but_mandatory_parameter); }