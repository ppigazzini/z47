const std = @import("std");
const random_primitives_owned = @import("math_random_primitives_owned.zig");
const runtime = @import("math_command_wrappers_runtime.zig");

const no_register = @as(runtime.calcRegister_t, -1);

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

    random_primitives_owned.realRandomU01(&unit);
    runtime.realFMA(&unit, &difference, lower, &reg_x, &runtime.ctxtReal39);
    runtime.convertRealToResultRegister(&reg_x, runtime.REGISTER_X, runtime.amNone);
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
    max_rand = random_primitives_owned.boundedRandExport(max_rand + 1);

    var result: runtime.longInteger_t = undefined;
    runtime.__gmpz_init(&result[0]);
    defer runtime.__gmpz_clear(&result[0]);
    runtime.__gmpz_add_ui(&result[0], min_value, max_rand);

    runtime.convertLongIntegerToLongIntegerRegister(&result[0], runtime.REGISTER_X);
    runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, no_register, no_register);
}

fn readSeedWord(lsu_bytes: *const [50]u8, offset: usize) u64 {
    const word_bytes: *const [8]u8 = @ptrCast(&lsu_bytes[offset]);
    return std.mem.readInt(u64, word_bytes, .native);
}

pub fn random(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    var value: runtime.real_t = undefined;

    random_primitives_owned.realRandomU01(&value);
    runtime.liftStack();
    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
    runtime.convertRealToReal34ResultRegister(&value, runtime.REGISTER_X);
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

    random_primitives_owned.pcg32Srandom(seed_value, sequence);
}