const circular_trig_command_owned = @import("math_circular_trig_command_owned.zig");
const integer_part_owned = @import("math_integer_part_owned.zig");
const inverse_trig_command_owned = @import("math_inverse_trig_command_owned.zig");
const random_command_owned = @import("math_random_command_owned.zig");
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