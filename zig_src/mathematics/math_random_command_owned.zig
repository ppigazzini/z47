const runtime = @import("math_command_wrappers_runtime.zig");
const random_policy_owned = @import("math_random_policy_owned.zig");
const random_primitives_owned = @import("math_random_primitives_owned.zig");

pub fn pcg32RandomR(rng: *runtime.pcg32_random_t) u32 {
    return random_primitives_owned.pcg32RandomR(rng);
}

pub fn pcg32SrandomR(rng: *runtime.pcg32_random_t, initstate: u64, initseq: u64) void {
    random_primitives_owned.pcg32SrandomR(rng, initstate, initseq);
}

pub fn pcg32Srandom(init_seed: u64, seq: u64) void {
    random_primitives_owned.pcg32Srandom(init_seed, seq);
}

fn boundedRand(s: u32) u32 {
    return random_primitives_owned.boundedRandExport(s);
}

pub fn boundedRandExport(s: u32) u32 {
    return random_primitives_owned.boundedRandExport(s);
}

pub fn realRandomU01(res: *runtime.real_t) void {
    random_primitives_owned.realRandomU01(res);
}

pub fn random(unused_but_mandatory_parameter: u16) void {
    random_policy_owned.random(unused_but_mandatory_parameter);
}

pub fn randomI(unused_but_mandatory_parameter: u16) void {
    random_policy_owned.randomI(unused_but_mandatory_parameter);
}

pub fn seed(unused_but_mandatory_parameter: u16) void {
    random_policy_owned.seed(unused_but_mandatory_parameter);
}