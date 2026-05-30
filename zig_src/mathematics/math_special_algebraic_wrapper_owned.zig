const runtime = @import("math_command_wrappers_runtime.zig");
const special_algebraic_command_owned = @import("math_special_algebraic_command_owned.zig");

pub fn sqrt1Px2Complex(
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    res_real: *runtime.real_t,
    res_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    special_algebraic_command_owned.sqrt1Px2Complex(real, imag, res_real, res_imag, real_context);
}

pub fn eulersFormula(
    in_real: *const runtime.real_t,
    in_imag: *const runtime.real_t,
    out_real: *runtime.real_t,
    out_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    special_algebraic_command_owned.eulersFormula(in_real, in_imag, out_real, out_imag, real_context);
}

pub fn fnSqrt1Px2(unused_but_mandatory_parameter: u16) callconv(.c) void {
    special_algebraic_command_owned.fnSqrt1Px2(unused_but_mandatory_parameter);
}

pub fn fnM1Pow(unused_but_mandatory_parameter: u16) callconv(.c) void {
    special_algebraic_command_owned.fnM1Pow(unused_but_mandatory_parameter);
}

pub fn fnEulersFormula(unused_but_mandatory_parameter: u16) callconv(.c) void {
    special_algebraic_command_owned.fnEulersFormula(unused_but_mandatory_parameter);
}
