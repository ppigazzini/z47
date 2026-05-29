const std = @import("std");
const runtime = @import("math_command_wrappers_runtime.zig");

const no_register = @as(runtime.calcRegister_t, -1);

pub fn pcg32RandomR(rng: *runtime.pcg32_random_t) u32 {
    const old_state = rng.state;
    const xorshifted: u32 = @truncate(((old_state >> 18) ^ old_state) >> 27);
    const rot: u5 = @intCast((old_state >> 59) & 31);
    const inv_rot: u5 = @intCast((32 - @as(u6, rot)) & 31);

    rng.state = old_state *% 6364136223846793005 +% rng.inc;
    return (xorshifted >> rot) | (xorshifted << inv_rot);
}

pub fn pcg32SrandomR(rng: *runtime.pcg32_random_t, initstate: u64, initseq: u64) void {
    rng.state = 0;
    rng.inc = (initseq << 1) | 1;
    _ = pcg32RandomR(rng);
    rng.state +%= initstate;
    _ = pcg32RandomR(rng);
}

pub fn pcg32Srandom(init_seed: u64, seq: u64) void {
    pcg32SrandomR(&runtime.pcg32_global, init_seed, seq);
}

fn boundedRand(s: u32) u32 {
    var rand = pcg32RandomR(&runtime.pcg32_global);
    const initial_product = @as(u64, s) * @as(u64, rand);
    const integer_part: u32 = @intCast(initial_product >> 32);
    var fractional_part: u32 = @truncate(initial_product);

    if (fractional_part <= 1 + ~s) {
        return integer_part;
    }

    var iterations: u4 = 0;
    while (iterations < 10) : (iterations += 1) {
        rand = pcg32RandomR(&runtime.pcg32_global);
        const product = @as(u64, s) * @as(u64, rand);
        const extra_fraction: u32 = @intCast(product >> 32);

        fractional_part +%= extra_fraction;
        if (fractional_part < extra_fraction) {
            return integer_part + 1;
        }
        if (fractional_part != 0xffff_ffff) {
            return integer_part;
        }

        fractional_part = @truncate(product);
    }

    return integer_part;
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

fn doRealRandomI() callconv(.c) void {
    var reg_x: runtime.real_t = undefined;
    var reg_y: runtime.real_t = undefined;
    var difference: runtime.real_t = undefined;
    var unit: runtime.real_t = undefined;
    var lower: *runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &reg_x) or !runtime.getRegisterAsReal(runtime.REGISTER_Y, &reg_y)) {
        return;
    }

    runtime.realSubtract(&reg_x, &reg_y, &difference, &runtime.ctxtReal39);
    if (runtime.realIsZero(&difference)) {
        runtime.convertRealToResultRegister(&reg_x, runtime.REGISTER_X, runtime.amNone);
        return;
    }

    if (runtime.realIsNegative(&difference)) {
        runtime.realChangeSign(&difference);
        lower = &reg_x;
    } else {
        lower = &reg_y;
    }

    realRandomU01(&unit);
    runtime.realFMA(&unit, &difference, lower, &reg_x, &runtime.ctxtReal39);
    runtime.convertRealToResultRegister(&reg_x, runtime.REGISTER_X, runtime.amNone);
}

fn readSeedWord(lsu_bytes: *const [50]u8, offset: usize) u64 {
    const word_bytes: *const [8]u8 = @ptrCast(&lsu_bytes[offset]);
    return std.mem.readInt(u64, word_bytes, .native);
}

pub fn random(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    var value: runtime.real_t = undefined;

    realRandomU01(&value);
    runtime.liftStack();
    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
    runtime.convertRealToReal34ResultRegister(&value, runtime.REGISTER_X);
    runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, no_register, no_register);
}

fn doIntRandomI() callconv(.c) void {
    const range_limit: u32 = 0xFFFFFFFE;

    var x: runtime.longInteger_t = undefined;
    var y: runtime.longInteger_t = undefined;
    var frac_x = false;
    var frac_y = false;

    runtime.saveForUndo();
    runtime.thereIsSomethingToUndo = true;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &x[0], &frac_x)) {
        return;
    }
    defer runtime.__gmpz_clear(&x[0]);
    if (frac_x) {
        return;
    }

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_Y, &y[0], &frac_y)) {
        return;
    }
    defer runtime.__gmpz_clear(&y[0]);
    if (frac_y) {
        return;
    }

    const cmp = runtime.__gmpz_cmp(&x[0], &y[0]);
    if (cmp == 0) {
        runtime.convertLongIntegerToLongIntegerRegister(&x[0], runtime.REGISTER_X);
        runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, no_register, no_register);
        return;
    }

    const min_value = if (cmp < 0) &x[0] else &y[0];
    const max_value = if (cmp < 0) &y[0] else &x[0];

    var range: runtime.longInteger_t = undefined;
    runtime.__gmpz_init(&range[0]);
    defer runtime.__gmpz_clear(&range[0]);
    runtime.__gmpz_sub(&range[0], max_value, min_value);

    if (runtime.__gmpz_cmp_ui(&range[0], range_limit) >= 0) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function doIntRandomI:", "cannot RANI# with |X - Y| >= 2^32", null, null);
        runtime.fnUndo(0);
        return;
    }

    var max_rand: u32 = @intCast(runtime.__gmpz_get_ui(&range[0]));
    max_rand = boundedRand(max_rand + 1);

    var result: runtime.longInteger_t = undefined;
    runtime.__gmpz_init(&result[0]);
    defer runtime.__gmpz_clear(&result[0]);
    runtime.__gmpz_add_ui(&result[0], min_value, max_rand);

    runtime.convertLongIntegerToLongIntegerRegister(&result[0], runtime.REGISTER_X);
    runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, no_register, no_register);
}

pub fn randomI(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexDyadicFunction(&doRealRandomI, null, null, &doIntRandomI);
}

pub fn seed(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    var register_x = std.mem.zeroes(runtime.real_t);

    if (!runtime.saveLastX()) {
        return;
    }

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &register_x)) {
        return;
    }

    runtime.fnDrop(0);

    const lsu_bytes: *const [50]u8 = @ptrCast(&register_x.lsu);
    var seed_value = readSeedWord(lsu_bytes, 0);
    var sequence = readSeedWord(lsu_bytes, @sizeOf(u64));

    if (seed_value == 0 and sequence == 0) {
        runtime.z47_math_wrappers_seed_defaults(&seed_value, &sequence);
    }

    pcg32Srandom(seed_value, sequence);
}