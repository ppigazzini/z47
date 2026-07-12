const runtime = @import("../math_command_wrappers_runtime.zig");
const abi = @import("abi"); // std-only PCG32 kernels (math owners keep abi private via runtime)

// The pure PCG32 kernels live in abi.pcg32; these owners keep the calculator-global
// rng state and thread it through, writing the advanced state back.
pub fn pcg32RandomR(rng: *runtime.pcg32_random_t) u32 {
    const step = abi.pcg32.random(rng.state, rng.inc);
    rng.state = step.next_state;
    return step.value;
}

pub fn pcg32SrandomR(rng: *runtime.pcg32_random_t, initstate: u64, initseq: u64) void {
    const seeded = abi.pcg32.seed(initstate, initseq);
    rng.state = seeded.state;
    rng.inc = seeded.inc;
}

pub fn pcg32Srandom(init_seed: u64, seq: u64) void {
    pcg32SrandomR(&runtime.pcg32_global, init_seed, seq);
}

fn boundedRand(s: u32) u32 {
    const r = abi.pcg32.bounded(runtime.pcg32_global.state, runtime.pcg32_global.inc, s);
    runtime.pcg32_global.state = r.next_state;
    return r.value;
}

pub fn boundedRandExport(s: u32) u32 {
    return boundedRand(s);
}

pub fn realRandomU01(res: *runtime.real_t) void {
    var t: runtime.real_t = undefined;

    runtime.uInt32ToReal(boundedRand(100000000), res);

    runtime.uInt32ToReal(boundedRand(100000000), &t);
    res.exponent += 8;
    runtime.realAdd(res, &t, res, &runtime.ctxtReal39);

    runtime.uInt32ToReal(boundedRand(1000000000), &t);
    res.exponent += 9;
    runtime.realAdd(res, &t, res, &runtime.ctxtReal39);

    runtime.uInt32ToReal(boundedRand(1000000000), &t);
    res.exponent += 9;
    runtime.realAdd(res, &t, res, &runtime.ctxtReal39);

    res.exponent -= 34;
}
