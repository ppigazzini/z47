const circular_trig_command_owned = @import("math_circular_trig_command_owned.zig");
const exponent_bernoulli_command_owned = @import("math_exponent_bernoulli_command_owned.zig");
const integer_part_owned = @import("math_integer_part_owned.zig");
const integer_residue_command_owned = @import("math_integer_residue_command_owned.zig");
const invert_command_owned = @import("math_invert_command_owned.zig");
const inverse_trig_command_owned = @import("math_inverse_trig_command_owned.zig");
const lambertw_command_owned = @import("math_lambertw_command_owned.zig");
const powlog_command_owned = @import("math_powlog_command_owned.zig");
const random_command_owned = @import("math_random_command_owned.zig");
const scalar_integer_inspection_command_owned = @import("math_scalar_integer_inspection_command_owned.zig");
const sign_command_owned = @import("math_sign_command_owned.zig");
const sinc_command_owned = @import("math_sinc_command_owned.zig");
const special_function_sequence_command_owned = @import("math_special_function_sequence_command_owned.zig");
const transform_command_owned = @import("math_transform_command_owned.zig");
const transcendental_command_owned = @import("math_transcendental_command_owned.zig");

pub fn fnRandom(unused_but_mandatory_parameter: u16) callconv(.c) void { random_command_owned.random(unused_but_mandatory_parameter); }
pub fn fnRandomI(unused_but_mandatory_parameter: u16) callconv(.c) void { random_command_owned.randomI(unused_but_mandatory_parameter); }
pub fn fnSeed(unused_but_mandatory_parameter: u16) callconv(.c) void { random_command_owned.seed(unused_but_mandatory_parameter); }

pub fn fnMin(unused_but_mandatory_parameter: u16) callconv(.c) void { integer_part_owned.min(unused_but_mandatory_parameter); }
pub fn fnMax(unused_but_mandatory_parameter: u16) callconv(.c) void { integer_part_owned.max(unused_but_mandatory_parameter); }
pub fn fnCeil(unused_but_mandatory_parameter: u16) callconv(.c) void { integer_part_owned.ceil(unused_but_mandatory_parameter); }
pub fn fnFloor(unused_but_mandatory_parameter: u16) callconv(.c) void { integer_part_owned.floor(unused_but_mandatory_parameter); }
pub fn fnIp(unused_but_mandatory_parameter: u16) callconv(.c) void { integer_part_owned.ip(unused_but_mandatory_parameter); }
pub fn fnLint(unused_but_mandatory_parameter: u16) callconv(.c) void { integer_part_owned.lint(unused_but_mandatory_parameter); }
pub fn fnSint(unused_but_mandatory_parameter: u16) callconv(.c) void { integer_part_owned.sint(unused_but_mandatory_parameter); }
pub fn fnFp(unused_but_mandatory_parameter: u16) callconv(.c) void { integer_part_owned.fp(unused_but_mandatory_parameter); }

pub fn fnSinc(unused_but_mandatory_parameter: u16) callconv(.c) void { sinc_command_owned.fnSinc(unused_but_mandatory_parameter); }
pub fn fnSincpi(unused_but_mandatory_parameter: u16) callconv(.c) void { sinc_command_owned.fnSincpi(unused_but_mandatory_parameter); }

pub fn fnSin(unused_but_mandatory_parameter: u16) callconv(.c) void { circular_trig_command_owned.fnSin(unused_but_mandatory_parameter); }
pub fn fnCos(unused_but_mandatory_parameter: u16) callconv(.c) void { circular_trig_command_owned.fnCos(unused_but_mandatory_parameter); }
pub fn fnTan(unused_but_mandatory_parameter: u16) callconv(.c) void { circular_trig_command_owned.fnTan(unused_but_mandatory_parameter); }

pub fn fnArcsin(unused_but_mandatory_parameter: u16) callconv(.c) void { inverse_trig_command_owned.fnArcsin(unused_but_mandatory_parameter); }
pub fn fnArccos(unused_but_mandatory_parameter: u16) callconv(.c) void { inverse_trig_command_owned.fnArccos(unused_but_mandatory_parameter); }
pub fn fnArctan(unused_but_mandatory_parameter: u16) callconv(.c) void { inverse_trig_command_owned.fnArctan(unused_but_mandatory_parameter); }
pub fn fnArcsinh(unused_but_mandatory_parameter: u16) callconv(.c) void { inverse_trig_command_owned.fnArcsinh(unused_but_mandatory_parameter); }
pub fn fnArccosh(unused_but_mandatory_parameter: u16) callconv(.c) void { inverse_trig_command_owned.fnArccosh(unused_but_mandatory_parameter); }
pub fn fnArctanh(unused_but_mandatory_parameter: u16) callconv(.c) void { inverse_trig_command_owned.fnArctanh(unused_but_mandatory_parameter); }

pub fn fnSinh(unused_but_mandatory_parameter: u16) callconv(.c) void { circular_trig_command_owned.fnSinh(unused_but_mandatory_parameter); }
pub fn fnCosh(unused_but_mandatory_parameter: u16) callconv(.c) void { circular_trig_command_owned.fnCosh(unused_but_mandatory_parameter); }
pub fn fnTanh(unused_but_mandatory_parameter: u16) callconv(.c) void { circular_trig_command_owned.fnTanh(unused_but_mandatory_parameter); }

pub fn fnExp(unused_but_mandatory_parameter: u16) callconv(.c) void { transcendental_command_owned.exp(unused_but_mandatory_parameter); }
pub fn fnExpM1(unused_but_mandatory_parameter: u16) callconv(.c) void { transcendental_command_owned.expM1(unused_but_mandatory_parameter); }
pub fn fnLn(unused_but_mandatory_parameter: u16) callconv(.c) void { transcendental_command_owned.ln(unused_but_mandatory_parameter); }
pub fn fnLnP1(unused_but_mandatory_parameter: u16) callconv(.c) void { transcendental_command_owned.lnP1(unused_but_mandatory_parameter); }

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
