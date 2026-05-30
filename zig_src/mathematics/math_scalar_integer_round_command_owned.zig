const runtime = @import("math_command_wrappers_runtime.zig");

const no_register = @as(runtime.calcRegister_t, -1);

pub fn round(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    if (register_data_type != runtime.dtLongInteger and register_data_type != runtime.dtShortInteger) {
        runtime.retained.z47_math_wrappers_retained_fnRound(unused_but_mandatory_parameter);
        return;
    }

    if (!runtime.saveLastX()) {
        return;
    }

    runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, no_register, no_register);
}
