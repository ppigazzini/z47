const random_primitives_owned = @import("math_random_primitives.zig");
const runtime = @import("math_command_wrappers_runtime.zig");

const no_register = @as(runtime.calcRegister_t, -1);

fn loadIntegerRangeBounds(
    x: *runtime.longInteger_t,
    y: *runtime.longInteger_t,
    min_value: **runtime.mpz_struct,
    max_value: **runtime.mpz_struct,
) bool {
    var frac_x = false;
    var frac_y = false;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &x[0], &frac_x)) {
        return false;
    }
    if (frac_x) {
        return false;
    }

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_Y, &y[0], &frac_y)) {
        return false;
    }
    if (frac_y) {
        return false;
    }

    const cmp = runtime.__gmpz_cmp(&x[0], &y[0]);
    if (cmp == 0) {
        runtime.convertLongIntegerToLongIntegerRegister(&x[0], runtime.REGISTER_X);
        runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, no_register, no_register);
        return false;
    }

    min_value.* = if (cmp < 0) &x[0] else &y[0];
    max_value.* = if (cmp < 0) &y[0] else &x[0];
    return true;
}

pub fn doIntRandomI() callconv(.c) void {
    const range_limit: u32 = 0xFFFFFFFE;

    var x: runtime.longInteger_t = undefined;
    var y: runtime.longInteger_t = undefined;
    var min_value: *runtime.mpz_struct = undefined;
    var max_value: *runtime.mpz_struct = undefined;

    runtime.saveForUndo();
    runtime.thereIsSomethingToUndo = true;

    defer runtime.__gmpz_clear(&x[0]);
    defer runtime.__gmpz_clear(&y[0]);

    if (!loadIntegerRangeBounds(&x, &y, &min_value, &max_value)) {
        return;
    }

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
