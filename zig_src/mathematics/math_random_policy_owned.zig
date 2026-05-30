const random_integer_owned = @import("math_random_integer_owned.zig");
const random_real_owned = @import("math_random_real_owned.zig");
const random_seed_owned = @import("math_random_seed_owned.zig");
const runtime = @import("math_command_wrappers_runtime.zig");

pub fn random(unused_but_mandatory_parameter: u16) void {
    random_real_owned.random(unused_but_mandatory_parameter);
}

pub fn randomI(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexDyadicFunction(&random_real_owned.doRealRandomI, null, null, &random_integer_owned.doIntRandomI);
}

pub fn seed(unused_but_mandatory_parameter: u16) void {
    random_seed_owned.seed(unused_but_mandatory_parameter);
}