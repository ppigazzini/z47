const exponent_bernoulli_command_owned = @import("math_exponent_bernoulli_command_owned.zig");
const integer_residue_command_owned = @import("math_integer_residue_command_owned.zig");
const invert_command_owned = @import("math_invert_command_owned.zig");
const lambertw_command_owned = @import("math_lambertw_command_owned.zig");
const powlog_command_owned = @import("math_powlog_command_owned.zig");
const scalar_integer_inspection_command_owned = @import("math_scalar_integer_inspection_command_owned.zig");
const sign_command_owned = @import("math_sign_command_owned.zig");
const sinc_command_owned = @import("math_sinc_command_owned.zig");
const special_function_sequence_command_owned = @import("math_special_function_sequence_command_owned.zig");
const transform_command_owned = @import("math_transform_command_owned.zig");
const forward_core_wrappers_owned = @import("math_forward_core_wrappers_owned.zig");

pub fn fnSinc(unused_but_mandatory_parameter: u16) callconv(.c) void { sinc_command_owned.fnSinc(unused_but_mandatory_parameter); }
pub fn fnSincpi(unused_but_mandatory_parameter: u16) callconv(.c) void { sinc_command_owned.fnSincpi(unused_but_mandatory_parameter); }

pub fn fnRandom(unused_but_mandatory_parameter: u16) callconv(.c) void { forward_core_wrappers_owned.fnRandom(unused_but_mandatory_parameter); }
pub fn fnRandomI(unused_but_mandatory_parameter: u16) callconv(.c) void { forward_core_wrappers_owned.fnRandomI(unused_but_mandatory_parameter); }
pub fn fnSeed(unused_but_mandatory_parameter: u16) callconv(.c) void { forward_core_wrappers_owned.fnSeed(unused_but_mandatory_parameter); }

pub fn fnMin(unused_but_mandatory_parameter: u16) callconv(.c) void { forward_core_wrappers_owned.fnMin(unused_but_mandatory_parameter); }
pub fn fnMax(unused_but_mandatory_parameter: u16) callconv(.c) void { forward_core_wrappers_owned.fnMax(unused_but_mandatory_parameter); }
pub fn fnCeil(unused_but_mandatory_parameter: u16) callconv(.c) void { forward_core_wrappers_owned.fnCeil(unused_but_mandatory_parameter); }
pub fn fnFloor(unused_but_mandatory_parameter: u16) callconv(.c) void { forward_core_wrappers_owned.fnFloor(unused_but_mandatory_parameter); }
pub fn fnIp(unused_but_mandatory_parameter: u16) callconv(.c) void { forward_core_wrappers_owned.fnIp(unused_but_mandatory_parameter); }
pub fn fnLint(unused_but_mandatory_parameter: u16) callconv(.c) void { forward_core_wrappers_owned.fnLint(unused_but_mandatory_parameter); }
pub fn fnSint(unused_but_mandatory_parameter: u16) callconv(.c) void { forward_core_wrappers_owned.fnSint(unused_but_mandatory_parameter); }
pub fn fnFp(unused_but_mandatory_parameter: u16) callconv(.c) void { forward_core_wrappers_owned.fnFp(unused_but_mandatory_parameter); }

pub fn fnSin(unused_but_mandatory_parameter: u16) callconv(.c) void { forward_core_wrappers_owned.fnSin(unused_but_mandatory_parameter); }
pub fn fnCos(unused_but_mandatory_parameter: u16) callconv(.c) void { forward_core_wrappers_owned.fnCos(unused_but_mandatory_parameter); }
pub fn fnTan(unused_but_mandatory_parameter: u16) callconv(.c) void { forward_core_wrappers_owned.fnTan(unused_but_mandatory_parameter); }

pub fn fnArcsin(unused_but_mandatory_parameter: u16) callconv(.c) void { forward_core_wrappers_owned.fnArcsin(unused_but_mandatory_parameter); }
pub fn fnArccos(unused_but_mandatory_parameter: u16) callconv(.c) void { forward_core_wrappers_owned.fnArccos(unused_but_mandatory_parameter); }
pub fn fnArctan(unused_but_mandatory_parameter: u16) callconv(.c) void { forward_core_wrappers_owned.fnArctan(unused_but_mandatory_parameter); }
pub fn fnArcsinh(unused_but_mandatory_parameter: u16) callconv(.c) void { forward_core_wrappers_owned.fnArcsinh(unused_but_mandatory_parameter); }
pub fn fnArccosh(unused_but_mandatory_parameter: u16) callconv(.c) void { forward_core_wrappers_owned.fnArccosh(unused_but_mandatory_parameter); }
pub fn fnArctanh(unused_but_mandatory_parameter: u16) callconv(.c) void { forward_core_wrappers_owned.fnArctanh(unused_but_mandatory_parameter); }

pub fn fnSinh(unused_but_mandatory_parameter: u16) callconv(.c) void { forward_core_wrappers_owned.fnSinh(unused_but_mandatory_parameter); }
pub fn fnCosh(unused_but_mandatory_parameter: u16) callconv(.c) void { forward_core_wrappers_owned.fnCosh(unused_but_mandatory_parameter); }
pub fn fnTanh(unused_but_mandatory_parameter: u16) callconv(.c) void { forward_core_wrappers_owned.fnTanh(unused_but_mandatory_parameter); }

pub fn fnExp(unused_but_mandatory_parameter: u16) callconv(.c) void { forward_core_wrappers_owned.fnExp(unused_but_mandatory_parameter); }
pub fn fnExpM1(unused_but_mandatory_parameter: u16) callconv(.c) void { forward_core_wrappers_owned.fnExpM1(unused_but_mandatory_parameter); }
pub fn fnLn(unused_but_mandatory_parameter: u16) callconv(.c) void { forward_core_wrappers_owned.fnLn(unused_but_mandatory_parameter); }
pub fn fnLnP1(unused_but_mandatory_parameter: u16) callconv(.c) void { forward_core_wrappers_owned.fnLnP1(unused_but_mandatory_parameter); }

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
