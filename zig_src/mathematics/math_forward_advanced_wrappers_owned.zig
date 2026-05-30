const exponent_bernoulli_command_owned = @import("math_exponent_bernoulli_command_owned.zig");
const integer_residue_command_owned = @import("math_integer_residue_command_owned.zig");
const invert_command_owned = @import("math_invert_command_owned.zig");
const lambertw_command_owned = @import("math_lambertw_command_owned.zig");
const powlog_command_owned = @import("math_powlog_command_owned.zig");
const scalar_integer_inspection_command_owned = @import("math_scalar_integer_inspection_command_owned.zig");
const sign_command_owned = @import("math_sign_command_owned.zig");
const special_function_sequence_command_owned = @import("math_special_function_sequence_command_owned.zig");
const transform_command_owned = @import("math_transform_command_owned.zig");

pub fn fnErf(unused_but_mandatory_parameter: u16) callconv(.c) void { special_function_sequence_command_owned.fnErf(unused_but_mandatory_parameter); }
pub fn fnErfc(unused_but_mandatory_parameter: u16) callconv(.c) void { special_function_sequence_command_owned.fnErfc(unused_but_mandatory_parameter); }

pub fn fn2Pow(unused_but_mandatory_parameter: u16) callconv(.c) void { powlog_command_owned.fn2Pow(unused_but_mandatory_parameter); }
pub fn fn10Pow(unused_but_mandatory_parameter: u16) callconv(.c) void { powlog_command_owned.fn10Pow(unused_but_mandatory_parameter); }
pub fn fnLog10(unused_but_mandatory_parameter: u16) callconv(.c) void { powlog_command_owned.fnLog10(unused_but_mandatory_parameter); }
pub fn fnLog2(unused_but_mandatory_parameter: u16) callconv(.c) void { powlog_command_owned.fnLog2(unused_but_mandatory_parameter); }

pub fn fnInvert(unused_but_mandatory_parameter: u16) callconv(.c) void { invert_command_owned.invert(unused_but_mandatory_parameter); }
pub fn fnSign(unused_but_mandatory_parameter: u16) callconv(.c) void { sign_command_owned.sign(unused_but_mandatory_parameter); }
pub fn fnChangeSign(unused_but_mandatory_parameter: u16) callconv(.c) void { sign_command_owned.changeSign(unused_but_mandatory_parameter); }

pub fn fnSquare(unused_but_mandatory_parameter: u16) callconv(.c) void { transform_command_owned.square(unused_but_mandatory_parameter); }
pub fn fnCube(unused_but_mandatory_parameter: u16) callconv(.c) void { transform_command_owned.cube(unused_but_mandatory_parameter); }

pub fn fnBn(unused_but_mandatory_parameter: u16) callconv(.c) void { exponent_bernoulli_command_owned.bn(unused_but_mandatory_parameter); }
pub fn fnBnStar(unused_but_mandatory_parameter: u16) callconv(.c) void { exponent_bernoulli_command_owned.bnStar(unused_but_mandatory_parameter); }
pub fn fnExpt(unused_but_mandatory_parameter: u16) callconv(.c) void { exponent_bernoulli_command_owned.expt(unused_but_mandatory_parameter); }

pub fn fnWpositive(unused_but_mandatory_parameter: u16) callconv(.c) void { lambertw_command_owned.fnWpositive(unused_but_mandatory_parameter); }
pub fn fnWnegative(unused_but_mandatory_parameter: u16) callconv(.c) void { lambertw_command_owned.fnWnegative(unused_but_mandatory_parameter); }
pub fn fnWinverse(unused_but_mandatory_parameter: u16) callconv(.c) void { lambertw_command_owned.fnWinverse(unused_but_mandatory_parameter); }

pub fn fnGcd(unused_but_mandatory_parameter: u16) callconv(.c) void { integer_residue_command_owned.fnGcd(unused_but_mandatory_parameter); }
pub fn fnLcm(unused_but_mandatory_parameter: u16) callconv(.c) void { integer_residue_command_owned.fnLcm(unused_but_mandatory_parameter); }
pub fn fnMod(unused_but_mandatory_parameter: u16) callconv(.c) void { integer_residue_command_owned.fnMod(unused_but_mandatory_parameter); }
pub fn fnRmd(unused_but_mandatory_parameter: u16) callconv(.c) void { integer_residue_command_owned.fnRmd(unused_but_mandatory_parameter); }
pub fn fnNeighb(unused_but_mandatory_parameter: u16) callconv(.c) void { integer_residue_command_owned.fnNeighb(unused_but_mandatory_parameter); }

pub fn fnUlp(unused_but_mandatory_parameter: u16) callconv(.c) void { scalar_integer_inspection_command_owned.fnUlp(unused_but_mandatory_parameter); }
pub fn fnMant(unused_but_mandatory_parameter: u16) callconv(.c) void { scalar_integer_inspection_command_owned.fnMant(unused_but_mandatory_parameter); }
pub fn fnRoundi(unused_but_mandatory_parameter: u16) callconv(.c) void { scalar_integer_inspection_command_owned.fnRoundi(unused_but_mandatory_parameter); }

pub fn fnIxyz(unused_but_mandatory_parameter: u16) callconv(.c) void { special_function_sequence_command_owned.fnIxyz(unused_but_mandatory_parameter); }
pub fn fnFactorial(unused_but_mandatory_parameter: u16) callconv(.c) void { special_function_sequence_command_owned.fnFactorial(unused_but_mandatory_parameter); }