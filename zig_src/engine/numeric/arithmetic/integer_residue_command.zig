const runtime = @import("../dispatch/command_wrappers_runtime.zig");

const no_register = @as(runtime.calcRegister_t, -1);

fn gcdShoI() callconv(.c) void {
    runtime.registerShortIntegerPtr(runtime.REGISTER_X).* = runtime.WP34S_intGCD(
        runtime.registerShortIntegerPtr(runtime.REGISTER_Y).*,
        runtime.registerShortIntegerPtr(runtime.REGISTER_X).*,
    );
}

fn lcmShoI() callconv(.c) void {
    runtime.registerShortIntegerPtr(runtime.REGISTER_X).* = runtime.WP34S_intLCM(
        runtime.registerShortIntegerPtr(runtime.REGISTER_Y).*,
        runtime.registerShortIntegerPtr(runtime.REGISTER_X).*,
    );
}

fn neighbShoI() callconv(.c) void {
    var subtract = false;
    var negx = false;
    var negy = false;
    var x: u64 = 0;
    var y: u64 = 0;

    if (runtime.getRegisterAsShortInt(runtime.REGISTER_X, &negx, &x, null, null) and
        runtime.getRegisterAsShortInt(runtime.REGISTER_Y, &negy, &y, null, null))
    {
        if (negx != negy) {
            subtract = negy;
        } else if (x == y) {
            return;
        } else if (negx) {
            subtract = y > x;
        } else {
            subtract = y < x;
        }

        if (subtract) {
            runtime.registerShortIntegerPtr(runtime.REGISTER_X).* = runtime.WP34S_intSubtract(
                runtime.registerShortIntegerPtr(runtime.REGISTER_X).*,
                1,
            );
        } else {
            runtime.registerShortIntegerPtr(runtime.REGISTER_X).* = runtime.WP34S_intAdd(
                runtime.registerShortIntegerPtr(runtime.REGISTER_X).*,
                1,
            );
        }
    }
}

fn neighbLonI() callconv(.c) void {
    var x: runtime.longInteger_t = undefined;
    var y: runtime.longInteger_t = undefined;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &x[0], null)) {
        return;
    }
    defer runtime.__gmpz_clear(&x[0]);

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_Y, &y[0], null)) {
        return;
    }
    defer runtime.__gmpz_clear(&y[0]);

    const cmp = runtime.__gmpz_cmp(&y[0], &x[0]);

    if (cmp != 0) {
        runtime.__gmpz_set_si(&y[0], if (cmp > 0) 1 else -1);
        runtime.__gmpz_add(&x[0], &x[0], &y[0]);
    }

    runtime.convertLongIntegerToLongIntegerRegister(&x[0], runtime.REGISTER_X);
}

fn gcdInt() callconv(.c) void {
    var x: runtime.longInteger_t = undefined;
    var y: runtime.longInteger_t = undefined;
    var frac_x = false;
    var frac_y = false;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_Y, &y[0], &frac_y)) {
        return;
    }
    defer runtime.__gmpz_clear(&y[0]);

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &x[0], &frac_x)) {
        return;
    }
    defer runtime.__gmpz_clear(&x[0]);

    if (frac_x) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        return;
    }
    if (frac_y) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_Y);
        return;
    }

    if (x[0]._mp_size < 0) {
        x[0]._mp_size = -x[0]._mp_size;
    }
    if (y[0]._mp_size < 0) {
        y[0]._mp_size = -y[0]._mp_size;
    }

    if (y[0]._mp_size == 0 and x[0]._mp_size == 0) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function _longIntegerGcd:", "(0, 0) is not in the function domain.", null, null);
        return;
    }

    runtime.__gmpz_gcd(&x[0], &y[0], &x[0]);
    runtime.convertLongIntegerToLongIntegerRegister(&x[0], runtime.REGISTER_X);
}

fn lcmInt() callconv(.c) void {
    var x: runtime.longInteger_t = undefined;
    var y: runtime.longInteger_t = undefined;
    var frac_x = false;
    var frac_y = false;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_Y, &y[0], &frac_y)) {
        return;
    }
    defer runtime.__gmpz_clear(&y[0]);

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &x[0], &frac_x)) {
        return;
    }
    defer runtime.__gmpz_clear(&x[0]);

    if (frac_x) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        return;
    }
    if (frac_y) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_Y);
        return;
    }

    if (x[0]._mp_size < 0) {
        x[0]._mp_size = -x[0]._mp_size;
    }
    if (y[0]._mp_size < 0) {
        y[0]._mp_size = -y[0]._mp_size;
    }

    runtime.__gmpz_lcm(&x[0], &y[0], &x[0]);
    runtime.convertLongIntegerToLongIntegerRegister(&x[0], runtime.REGISTER_X);
}

fn modReal() callconv(.c) void {
    var x_value: runtime.real_t = undefined;
    var y_value: runtime.real_t = undefined;
    var result: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value) or !runtime.getRegisterAsReal(runtime.REGISTER_Y, &y_value)) {
        return;
    }

    if (runtime.realIsZero(&x_value)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function modReal:", "cannot IDIVR a real34 by 0", null, null);
        return;
    }

    runtime.WP34S_BigMod(&y_value, &x_value, &result, &runtime.ctxtReal39);
    if (!runtime.realIsZero(&result) and (runtime.realIsNegative(&y_value) != runtime.realIsNegative(&x_value))) {
        runtime.realAdd(&result, &x_value, &result, &runtime.ctxtReal39);
    }

    runtime.convertRealToResultRegister(&result, runtime.REGISTER_X, runtime.amNone);
}

fn rmdReal() callconv(.c) void {
    var x_value: runtime.real_t = undefined;
    var y_value: runtime.real_t = undefined;
    var result: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value) or !runtime.getRegisterAsReal(runtime.REGISTER_Y, &y_value)) {
        return;
    }

    if (runtime.realIsZero(&x_value)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function rmdReal:", "cannot IDIVR a real34 by 0", null, null);
        return;
    }

    runtime.WP34S_BigMod(&y_value, &x_value, &result, &runtime.ctxtReal39);
    runtime.convertRealToResultRegister(&result, runtime.REGISTER_X, runtime.amNone);
}

fn neighbReal() callconv(.c) void {
    var x_value: runtime.real_t = undefined;
    var y_value: runtime.real_t = undefined;
    var x_angular_mode = runtime.amNone;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value) or !runtime.getRegisterAsReal(runtime.REGISTER_Y, &y_value)) {
        return;
    }

    if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtReal34) {
        x_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_X);
    }

    runtime.realNextToward(&x_value, &y_value, &x_value, &runtime.ctxtReal34);
    runtime.convertRealToResultRegister(&x_value, runtime.REGISTER_X, x_angular_mode);
}

fn modLonI() callconv(.c) void {
    var x: runtime.longInteger_t = undefined;
    var y: runtime.longInteger_t = undefined;
    var remainder: runtime.longInteger_t = undefined;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &x[0], null)) {
        return;
    }
    defer runtime.__gmpz_clear(&x[0]);

    if (x[0]._mp_size == 0) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function modLonI:", "cannot IDIVR a long integer by 0", null, null);
        return;
    }

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_Y, &y[0], null)) {
        return;
    }
    defer runtime.__gmpz_clear(&y[0]);

    runtime.__gmpz_init(&remainder[0]);
    defer runtime.__gmpz_clear(&remainder[0]);

    runtime.__gmpz_tdiv_r(&remainder[0], &y[0], &x[0]);
    runtime.__gmpz_add(&remainder[0], &remainder[0], &x[0]);
    runtime.__gmpz_tdiv_r(&remainder[0], &remainder[0], &x[0]);
    runtime.convertLongIntegerToLongIntegerRegister(&remainder[0], runtime.REGISTER_X);
}

fn modShoI() callconv(.c) void {
    var x: runtime.longInteger_t = undefined;
    var y: runtime.longInteger_t = undefined;
    var remainder: runtime.longInteger_t = undefined;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &x[0], null)) {
        return;
    }
    defer runtime.__gmpz_clear(&x[0]);

    if (x[0]._mp_size == 0) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function modShoI:", "cannot IDIVR a short integer by 0", null, null);
        return;
    }

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_Y, &y[0], null)) {
        return;
    }
    defer runtime.__gmpz_clear(&y[0]);

    runtime.__gmpz_init(&remainder[0]);
    defer runtime.__gmpz_clear(&remainder[0]);

    runtime.__gmpz_tdiv_r(&remainder[0], &y[0], &x[0]);
    runtime.__gmpz_add(&remainder[0], &remainder[0], &x[0]);
    runtime.__gmpz_tdiv_r(&remainder[0], &remainder[0], &x[0]);
    runtime.convertLongIntegerToShortIntegerRegister(&remainder[0], runtime.getRegisterTag(runtime.REGISTER_Y), runtime.REGISTER_X);
}

fn rmdShoI() callconv(.c) void {
    var x: runtime.longInteger_t = undefined;
    var y: runtime.longInteger_t = undefined;
    var remainder: runtime.longInteger_t = undefined;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &x[0], null)) {
        return;
    }
    defer runtime.__gmpz_clear(&x[0]);

    if (x[0]._mp_size == 0) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function rmdShoI:", "cannot IDIVR a short integer by 0", null, null);
        return;
    }

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_Y, &y[0], null)) {
        return;
    }
    defer runtime.__gmpz_clear(&y[0]);

    runtime.__gmpz_init(&remainder[0]);
    defer runtime.__gmpz_clear(&remainder[0]);

    runtime.__gmpz_tdiv_r(&remainder[0], &y[0], &x[0]);
    runtime.convertLongIntegerToLongIntegerRegister(&remainder[0], runtime.REGISTER_X);
}

fn rmdLonI() callconv(.c) void {
    var x: runtime.longInteger_t = undefined;
    var y: runtime.longInteger_t = undefined;
    var remainder: runtime.longInteger_t = undefined;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &x[0], null)) {
        return;
    }
    defer runtime.__gmpz_clear(&x[0]);

    if (x[0]._mp_size == 0) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function rmdLonI:", "cannot IDIVR a long integer by 0", null, null);
        return;
    }

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_Y, &y[0], null)) {
        return;
    }
    defer runtime.__gmpz_clear(&y[0]);

    runtime.__gmpz_init(&remainder[0]);
    defer runtime.__gmpz_clear(&remainder[0]);

    runtime.__gmpz_tdiv_r(&remainder[0], &y[0], &x[0]);
    runtime.convertLongIntegerToShortIntegerRegister(&remainder[0], runtime.getRegisterTag(runtime.REGISTER_Y), runtime.REGISTER_X);
}

pub fn fnGcd(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processIntRealComplexDyadicFunction(&gcdInt, null, &gcdShoI, &gcdInt);
}

pub fn fnLcm(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processIntRealComplexDyadicFunction(&lcmInt, null, &lcmShoI, &lcmInt);
}

pub fn fnMod(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processIntRealComplexDyadicFunction(&modReal, null, &modShoI, &modLonI);
}

pub fn fnRmd(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processIntRealComplexDyadicFunction(&rmdReal, null, &rmdLonI, &rmdShoI);
}

pub fn fnNeighb(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processIntRealComplexDyadicFunction(&neighbReal, null, &neighbShoI, &neighbLonI);
}
