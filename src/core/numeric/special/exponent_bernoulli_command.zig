const runtime = @import("../command_wrappers/runtime.zig");

const no_register = @as(runtime.calcRegister_t, -1);
const TMP_STR_LENGTH: i32 = 2560; // defines.h

fn getExponent(result: *i32) bool {
    var x_value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value)) {
        return false;
    }

    if (runtime.realIsNaN(&x_value)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
        runtime.moreInfoOnError("In function getExponent:", "cannot use NaN as X input of EXPT", null, null);
        return false;
    }

    if (runtime.realIsInfinite(&x_value)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
        runtime.moreInfoOnError("In function getExponent:", "cannot use \xc2\xb1\xe2\x88\x9e as an input of EXPT", null, null);
        return false;
    }

    result.* = if (runtime.realIsZero(&x_value)) 0 else x_value.exponent + x_value.digits - 1;
    return true;
}

fn exptReal() callconv(.c) void {
    var exponent: i32 = undefined;
    var x_value: runtime.real_t = undefined;

    if (!getExponent(&exponent)) {
        return;
    }

    runtime.int32ToReal(exponent, &x_value);
    runtime.convertRealToResultRegister(&x_value, runtime.REGISTER_X, runtime.amNone);
}

// The decimal exponent of a long integer is one less than its digit count,
// read off its decimal rendering so that no width limit truncates it.
fn exptLonI() callconv(.c) void {
    var lg_int: runtime.longInteger_t = undefined;

    // The reader initialises its value on every path, refusals included, so the
    // clear has to cover the failure branch too.
    defer runtime.__gmpz_clear(&lg_int[0]);

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &lg_int[0], null)) {
        return;
    }

    runtime.longIntegerToAllocatedString(&lg_int[0], runtime.tmpString, TMP_STR_LENGTH);
    var digits: i32 = 0;
    while (runtime.tmpString[@intCast(digits)] != 0) : (digits += 1) {}
    if (runtime.tmpString[0] == '-') {
        digits -= 1;
    }
    runtime.__gmpz_set_si(&lg_int[0], digits - 1);
    runtime.convertLongIntegerToLongIntegerRegister(&lg_int[0], runtime.REGISTER_X);
}

fn bnCommon(bnstar: bool) void {
    var x_value: runtime.real_t = undefined;
    var result: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value)) {
        return;
    }

    if (!runtime.saveLastX()) {
        return;
    }

    runtime.WP34S_Bernoulli(&x_value, &result, bnstar, &runtime.ctxtReal39);
    if (runtime.realIsNaN(&result)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
        runtime.moreInfoOnError("In function fnBn:", "k must be a non-negative integer", null, null);
    } else {
        runtime.convertRealToResultRegister(&result, runtime.REGISTER_X, runtime.amNone);
    }

    runtime.adjustResult(runtime.REGISTER_X, false, true, runtime.REGISTER_X, no_register, no_register);
}

pub fn expt(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processIntRealComplexMonadicFunction(&exptReal, null, null, &exptLonI);
}

pub fn bn(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    bnCommon(false);
}

pub fn bnStar(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    bnCommon(true);
}
