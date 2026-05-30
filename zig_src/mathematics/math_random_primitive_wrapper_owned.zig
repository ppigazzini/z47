const random_command_owned = @import("math_random_command_owned.zig");
const runtime = @import("math_command_wrappers_runtime.zig");

pub fn pcg32RandomR(rng: *runtime.pcg32_random_t) callconv(.c) u32 {
    return random_command_owned.pcg32RandomR(rng);
}

pub fn pcg32SrandomR(rng: *runtime.pcg32_random_t, initstate: u64, initseq: u64) callconv(.c) void {
    random_command_owned.pcg32SrandomR(rng, initstate, initseq);
}

pub fn pcg32Srandom(seed: u64, seq: u64) callconv(.c) void {
    random_command_owned.pcg32Srandom(seed, seq);
}

pub fn boundedRandExport(s: u32) callconv(.c) u32 {
    return random_command_owned.boundedRandExport(s);
}

pub fn realRandomU01(res: *runtime.real_t) callconv(.c) void {
    random_command_owned.realRandomU01(res);
}
