const runtime = @import("../command_wrappers/runtime.zig");

const no_register = @as(runtime.calcRegister_t, -1);

// REAL34_SIZE_IN_BLOCKS (realType.h): TO_BLOCKS(sizeof(real34_t)) = 16 bytes in
// 4-byte blocks.
const REAL34_SIZE_IN_BLOCKS: u16 = 4;

/// MOD and RMD over two integers are one routine. `floor_mod` brings the
/// remainder to the sign of the divisor, which is what makes MOD a floored
/// remainder and RMD a truncated one. `short_result` sends the answer back as a
/// short integer in Y's base instead of a long integer.
pub export fn integerRemainder(floor_mod: bool, short_result: bool) callconv(.c) void {
    var x: runtime.longInteger_t = undefined;
    var y: runtime.longInteger_t = undefined;
    var remainder: runtime.longInteger_t = undefined;
    var base_y: u32 = 0;

    // The reader initialises its value on every path, refusals included, so the
    // clear must cover the failure branch too.
    defer runtime.__gmpz_clear(&x[0]);
    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &x[0], null)) {
        return;
    }

    if (runtime.longIntegerIsZero(&x[0])) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
        runtime.moreInfoOnError("In function integerRemainder:", "cannot IDIVR an integer by 0", null, null);
        return;
    }

    // The reader initialises its value on every path, refusals included, so the
    // clear must cover the failure branch too.
    defer runtime.__gmpz_clear(&y[0]);
    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_Y, &y[0], null)) {
        return;
    }
    if (short_result) {
        base_y = runtime.getRegisterShortIntegerBase(runtime.REGISTER_Y);
    }

    runtime.__gmpz_init(&remainder[0]);
    defer runtime.__gmpz_clear(&remainder[0]);

    runtime.__gmpz_tdiv_r(&remainder[0], &y[0], &x[0]);
    if (floor_mod and !runtime.longIntegerIsZero(&remainder[0]) and runtime.longIntegerIsNegative(&y[0]) != runtime.longIntegerIsNegative(&x[0])) {
        runtime.longIntegerAdd(&remainder[0], &x[0], &remainder[0]);
    }

    if (short_result) {
        runtime.convertLongIntegerToShortIntegerRegister(&remainder[0], base_y, runtime.REGISTER_X);
    } else {
        runtime.convertLongIntegerToLongIntegerRegister(&remainder[0], runtime.REGISTER_X);
    }
}

/// Computes a mixed integer and Real34 remainder from exact coefficients.
/// `modulo` asks for the sign correction. Answers true when the mixed pair was
/// completed, false when the decimal path is required.
pub export fn mixedIntegerRealRemainder(modulo: bool) callconv(.c) bool {
    const type_x = runtime.getRegisterDataType(runtime.REGISTER_X);
    const type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);
    const x_real = type_x == runtime.dtReal34;
    const y_real = type_y == runtime.dtReal34;
    var exponent_x: i32 = 0;
    var exponent_y: i32 = 0;
    var remainder_exponent: i32 = 0;
    var x: runtime.longInteger_t = undefined;
    var y: runtime.longInteger_t = undefined;
    var quotient: runtime.longInteger_t = undefined;
    var remainder: runtime.longInteger_t = undefined;

    if (x_real == y_real) {
        return false;
    }
    if (!runtime.convertRegisterToScaledLongInteger(runtime.REGISTER_Y, &y[0], &exponent_y)) {
        return false;
    }

    if (x_real and runtime.real34IsInfinite(runtime.registerReal34Ptr(runtime.REGISTER_X))) {
        if (modulo and !runtime.longIntegerIsZero(&y[0]) and runtime.longIntegerIsNegative(&y[0]) != runtime.real34IsNegative(runtime.registerReal34Ptr(runtime.REGISTER_X))) {
            runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.amNone);
        } else {
            runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, REAL34_SIZE_IN_BLOCKS, @intCast(runtime.amNone));
            runtime.convertScaledLongIntegerToReal34(&y[0], exponent_y, runtime.registerReal34Ptr(runtime.REGISTER_X));
        }
        runtime.__gmpz_clear(&y[0]);
        return true;
    }

    if (!runtime.convertRegisterToScaledLongInteger(runtime.REGISTER_X, &x[0], &exponent_x)) {
        runtime.__gmpz_clear(&y[0]);
        return false;
    }
    if (runtime.longIntegerIsZero(&x[0])) {
        runtime.__gmpz_clear(&x[0]);
        runtime.__gmpz_clear(&y[0]);
        return false;
    }

    runtime.__gmpz_init(&quotient[0]);
    runtime.__gmpz_init(&remainder[0]);
    runtime.longIntegerScaledDivide(&y[0], exponent_y, &x[0], exponent_x, &quotient[0], &remainder[0], &remainder_exponent);

    if (modulo and !runtime.longIntegerIsZero(&remainder[0]) and runtime.longIntegerIsNegative(&y[0]) != runtime.longIntegerIsNegative(&x[0])) {
        var divisor: runtime.longInteger_t = undefined;
        var scale: runtime.longInteger_t = undefined;

        runtime.__gmpz_init(&divisor[0]);
        runtime.__gmpz_set(&divisor[0], &x[0]);
        if (exponent_x > remainder_exponent) {
            runtime.__gmpz_init(&scale[0]);
            runtime.__gmpz_ui_pow_ui(&scale[0], 10, @as(u32, @intCast(exponent_x - remainder_exponent)));
            runtime.__gmpz_mul(&divisor[0], &divisor[0], &scale[0]);
            runtime.__gmpz_clear(&scale[0]);
        }
        runtime.longIntegerAdd(&remainder[0], &divisor[0], &remainder[0]);
        runtime.__gmpz_clear(&divisor[0]);
    }

    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, REAL34_SIZE_IN_BLOCKS, @intCast(runtime.amNone));
    runtime.convertScaledLongIntegerToReal34(&remainder[0], remainder_exponent, runtime.registerReal34Ptr(runtime.REGISTER_X));
    runtime.__gmpz_clear(&remainder[0]);
    runtime.__gmpz_clear(&quotient[0]);
    runtime.__gmpz_clear(&x[0]);
    runtime.__gmpz_clear(&y[0]);
    return true;
}

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

    // The reader initialises its value on every path, refusals included, so the
    // clear must cover the failure branch too.
    defer runtime.__gmpz_clear(&x[0]);
    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &x[0], null)) {
        return;
    }

    // The reader initialises its value on every path, refusals included, so the
    // clear must cover the failure branch too.
    defer runtime.__gmpz_clear(&y[0]);
    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_Y, &y[0], null)) {
        return;
    }

    const cmp = runtime.__gmpz_cmp(&y[0], &x[0]);

    if (cmp != 0) {
        runtime.__gmpz_set_si(&y[0], if (cmp > 0) 1 else -1);
        runtime.longIntegerAdd(&x[0], &y[0], &x[0]);
    }

    runtime.convertLongIntegerToLongIntegerRegister(&x[0], runtime.REGISTER_X);
}

fn gcdInt() callconv(.c) void {
    var x: runtime.longInteger_t = undefined;
    var y: runtime.longInteger_t = undefined;
    var frac_x = false;
    var frac_y = false;

    // The reader initialises its value on every path, refusals included, so the
    // clear must cover the failure branch too.
    defer runtime.__gmpz_clear(&y[0]);
    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_Y, &y[0], &frac_y)) {
        return;
    }

    // The reader initialises its value on every path, refusals included, so the
    // clear must cover the failure branch too.
    defer runtime.__gmpz_clear(&x[0]);
    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &x[0], &frac_x)) {
        return;
    }

    if (frac_x) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
        return;
    }
    if (frac_y) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
        return;
    }

    if (x[0]._mp_size < 0) {
        x[0]._mp_size = -x[0]._mp_size;
    }
    if (y[0]._mp_size < 0) {
        y[0]._mp_size = -y[0]._mp_size;
    }

    // _longIntegerGcd raises the domain error and returns without touching its
    // result, so X still holds the operand and gcdInt writes it back: the
    // register is reallocated as a long integer even on the refused pair.
    if (y[0]._mp_size == 0 and x[0]._mp_size == 0) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
        runtime.moreInfoOnError("In function _longIntegerGcd:", "(0, 0) is not in the function domain.", null, null);
    } else {
        runtime.__gmpz_gcd(&x[0], &y[0], &x[0]);
    }

    runtime.convertLongIntegerToLongIntegerRegister(&x[0], runtime.REGISTER_X);
}

fn lcmInt() callconv(.c) void {
    var x: runtime.longInteger_t = undefined;
    var y: runtime.longInteger_t = undefined;
    var frac_x = false;
    var frac_y = false;

    // The reader initialises its value on every path, refusals included, so the
    // clear must cover the failure branch too.
    defer runtime.__gmpz_clear(&y[0]);
    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_Y, &y[0], &frac_y)) {
        return;
    }

    // The reader initialises its value on every path, refusals included, so the
    // clear must cover the failure branch too.
    defer runtime.__gmpz_clear(&x[0]);
    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &x[0], &frac_x)) {
        return;
    }

    if (frac_x) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
        return;
    }
    if (frac_y) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
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
    const real34_operands = runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtReal34 and runtime.getRegisterDataType(runtime.REGISTER_Y) == runtime.dtReal34;

    if (mixedIntegerRealRemainder(true)) {
        return;
    }
    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value) or !runtime.getRegisterAsReal(runtime.REGISTER_Y, &y_value)) {
        return;
    }

    if (runtime.realIsZero(&x_value)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
        runtime.moreInfoOnError("In function modReal:", "cannot IDIVR a real34 by 0", null, null);
        return;
    }

    if (real34_operands) {
        runtime.WP34S_Real34Remainder(&y_value, &x_value, &result);
    } else {
        runtime.WP34S_BigMod(&y_value, &x_value, &result, &runtime.ctxtReal39);
    }
    if (runtime.realIsZero(&result)) {
        runtime.realSetPositiveSign(&result);
    } else if (runtime.realIsNegative(&y_value) != runtime.realIsNegative(&x_value)) {
        runtime.realAdd(&result, &x_value, &result, if (real34_operands) &runtime.ctxtReal34 else &runtime.ctxtReal39);
    }

    runtime.convertRealToResultRegister(&result, runtime.REGISTER_X, runtime.amNone);
}

fn rmdReal() callconv(.c) void {
    var x_value: runtime.real_t = undefined;
    var y_value: runtime.real_t = undefined;
    var result: runtime.real_t = undefined;
    const real34_operands = runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtReal34 and runtime.getRegisterDataType(runtime.REGISTER_Y) == runtime.dtReal34;

    if (mixedIntegerRealRemainder(false)) {
        return;
    }
    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value) or !runtime.getRegisterAsReal(runtime.REGISTER_Y, &y_value)) {
        return;
    }

    if (runtime.realIsZero(&x_value)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
        runtime.moreInfoOnError("In function rmdReal:", "cannot IDIVR a real34 by 0", null, null);
        return;
    }

    if (real34_operands) {
        runtime.WP34S_Real34Remainder(&y_value, &x_value, &result);
    } else {
        runtime.WP34S_BigMod(&y_value, &x_value, &result, &runtime.ctxtReal39);
    }
    if (runtime.realIsZero(&result)) {
        runtime.realSetPositiveSign(&result);
    }
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

    var comparison: i32 = 0;
    if (runtime.compareFiniteReal34LongIntegerRegisters(runtime.REGISTER_X, runtime.REGISTER_Y, &comparison)) {
        if (comparison < 0) {
            y_value = runtime.z47_math_wrappers_const_plus_infinity().*;
        } else if (comparison > 0) {
            y_value = runtime.z47_math_wrappers_const_minus_infinity().*;
        }
    }

    runtime.realNextToward(&x_value, &y_value, &x_value, &runtime.ctxtReal34);
    runtime.convertRealToResultRegister(&x_value, runtime.REGISTER_X, x_angular_mode);
}

fn modLonI() callconv(.c) void {
    integerRemainder(true, false);
}

fn modShoI() callconv(.c) void {
    integerRemainder(true, true);
}

fn rmdLonI() callconv(.c) void {
    integerRemainder(false, false);
}

fn rmdShoI() callconv(.c) void {
    integerRemainder(false, true);
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
    runtime.processIntRealComplexDyadicFunction(&rmdReal, null, &rmdShoI, &rmdLonI);
}

pub fn fnNeighb(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processIntRealComplexDyadicFunction(&neighbReal, null, &neighbShoI, &neighbLonI);
}
