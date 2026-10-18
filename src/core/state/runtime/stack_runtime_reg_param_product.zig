const build_options = @import("stack_state_build_options");
const product_real_owned = @import("stack_runtime_product_real.zig");
const register_range_owned = @import("stack_runtime_register_range.zig");

const use_fake_stack_state_harness_surface =
    build_options.use_fake_stack_state_harness_surface;

const PRODUCT_DEC_ROUND_DOWN = product_real_owned.PRODUCT_DEC_ROUND_DOWN;
const product_rounding_t = product_real_owned.product_rounding_t;
const ProductReal = product_real_owned.ProductReal;
const ProductReal34 = product_real_owned.ProductReal34;
const ProductRealContext = product_real_owned.ProductRealContext;

const calcRegister_t = i16;

const REGISTER_X: calcRegister_t = 100;
const FIRST_LOCAL_REGISTER: calcRegister_t = 7000;
const NUMBER_OF_LOCAL_REGISTERS: i16 = 99;
const REGISTER_X_IN_KS_CODE: i16 = 100;
const LAST_LETTERED_REGISTER_IN_KS_CODE: i16 = 111;
const FIRST_LOCAL_REGISTER_IN_KS_CODE: i16 = 112;
const LAST_LOCAL_REGISTER_IN_KS_CODE: i16 = 210;
const FIRST_STAT_REGISTER_IN_KS_CODE: i16 = 211;
const LAST_SPARE_REGISTERS_IN_KS_CODE: i16 = 224;
const dtReal34: u32 = 1;
const ERROR_NONE: u8 = 0;
const ERROR_OUT_OF_RANGE: u8 = 8;
const ERROR_INVALID_DATA_TYPE_FOR_OP: u8 = 24;

extern fn getRegisterDataPointer(reg: calcRegister_t) ?*anyopaque;
extern fn getRegisterDataType(reg: calcRegister_t) u32;
extern fn realCompareAbsLessThan(number1: *const ProductReal, number2: *const ProductReal) bool;
extern fn realToIntegralValue(source: *const ProductReal, destination: *ProductReal, mode: product_rounding_t, real_context: *ProductRealContext) void;
extern fn realToInt32C47(source: *const ProductReal, err: ?*bool) i32;

fn registerReal34Ptr(reg: calcRegister_t) *align(1) ProductReal34 {
    const ptr = getRegisterDataPointer(reg) orelse unreachable;
    return @ptrCast(ptr);
}

fn productReal34ToReal(source: *const ProductReal34, destination: *ProductReal) void {
    product_real_owned.productReal34ToReal(source, destination);
}

fn productUInt32ToReal(source: u32, destination: *ProductReal) void {
    product_real_owned.productUInt32ToReal(source, destination);
}

fn productRealIsNegative(value: *const ProductReal) bool {
    return product_real_owned.productRealIsNegative(value);
}

fn productRealSetPositiveSign(value: *ProductReal) void {
    product_real_owned.productRealSetPositiveSign(value);
}

fn productRealSubtract(lhs: *const ProductReal, rhs: *const ProductReal, result: *ProductReal, real_context: *ProductRealContext) void {
    product_real_owned.productRealSubtract(lhs, rhs, result, real_context);
}

// defines.h regKStoC: a keystroke register code to the internal register number.
// Its parameter is a uint8_t, so a code above 255 wraps before it is converted.
fn regKStoC(reg_ks: u8) i16 {
    const ks: i16 = reg_ks;
    const stat_or_spare: i16 = if (FIRST_STAT_REGISTER_IN_KS_CODE <= ks and ks <= LAST_SPARE_REGISTERS_IN_KS_CODE) NUMBER_OF_LOCAL_REGISTERS else 0;
    const local: i16 = if (FIRST_LOCAL_REGISTER_IN_KS_CODE <= ks and ks <= LAST_LOCAL_REGISTER_IN_KS_CODE) FIRST_LOCAL_REGISTER - FIRST_LOCAL_REGISTER_IN_KS_CODE else 0;
    return ks - stat_or_spare + local;
}

// Validates a public register range keyed in keystroke codes and expands a zero
// count to the rest of its band.
fn getRegParamRange(first: u16, number: *u16, local_register_count: u8) bool {
    return register_range_owned.getRegParamRange(
        first,
        number,
        @intCast(REGISTER_X_IN_KS_CODE),
        @intCast(LAST_LETTERED_REGISTER_IN_KS_CODE),
        @intCast(FIRST_LOCAL_REGISTER_IN_KS_CODE),
        local_register_count,
        @intCast(FIRST_STAT_REGISTER_IN_KS_CODE),
        @intCast(LAST_SPARE_REGISTERS_IN_KS_CODE),
    );
}

pub fn getRegParamProduct(load_into_memory: ?*bool, start: *u16, count: *u16, destination: ?*u16, local_register_count: u8) u8 {
    if (use_fake_stack_state_harness_surface) {
        return ERROR_OUT_OF_RANGE;
    }

    var x: ProductReal = undefined;
    var integer_part: ProductReal = undefined;
    var thousand: ProductReal = undefined;

    // Both arms of registers.c zero the out-parameters, the wrong-type arm
    // included, so a caller that inspects them after a refusal sees zeroes rather
    // than whatever the previous call left there.
    start.* = 0;
    count.* = 0;
    if (destination) |dest| {
        dest.* = 0;
    }

    if (getRegisterDataType(REGISTER_X) != dtReal34) {
        return ERROR_INVALID_DATA_TYPE_FOR_OP;
    }

    productReal34ToReal(registerReal34Ptr(REGISTER_X), &x);
    productUInt32ToReal(1000, &thousand);
    if (!realCompareAbsLessThan(&x, &thousand)) {
        return ERROR_OUT_OF_RANGE;
    }

    if (load_into_memory) |load| {
        load.* = productRealIsNegative(&x);
    } else if (productRealIsNegative(&x)) {
        return ERROR_OUT_OF_RANGE;
    }
    productRealSetPositiveSign(&x);

    realToIntegralValue(&x, &integer_part, PRODUCT_DEC_ROUND_DOWN, product_real_owned.realContext39());
    start.* = @truncate(@as(u32, @bitCast(realToInt32C47(&integer_part, null))));

    productRealSubtract(&x, &integer_part, &x, product_real_owned.realContext39());
    x.exponent += 2;
    realToIntegralValue(&x, &integer_part, PRODUCT_DEC_ROUND_DOWN, product_real_owned.realContext39());
    count.* = @truncate(@as(u32, @bitCast(realToInt32C47(&integer_part, null))));

    if (destination) |dest| {
        productRealSubtract(&x, &integer_part, &x, product_real_owned.realContext39());
        x.exponent += 3;
        realToIntegralValue(&x, &integer_part, PRODUCT_DEC_ROUND_DOWN, product_real_owned.realContext39());
        dest.* = @truncate(@as(u32, @bitCast(realToInt32C47(&integer_part, null))));
    }

    if (!getRegParamRange(start.*, count, local_register_count)) {
        return ERROR_OUT_OF_RANGE;
    }
    // A load into memory may not target the local registers.
    if (load_into_memory != null and load_into_memory.?.* and start.* >= @as(u16, @intCast(FIRST_LOCAL_REGISTER_IN_KS_CODE)) and start.* <= @as(u16, @intCast(LAST_LOCAL_REGISTER_IN_KS_CODE))) {
        return ERROR_OUT_OF_RANGE;
    }

    if (destination) |dest| {
        if (!getRegParamRange(dest.*, count, local_register_count)) {
            return ERROR_OUT_OF_RANGE;
        }
    }

    // The user keys a keystroke register number, 112 for R.00; the caller gets the
    // internal one, 7000.
    start.* = @intCast(regKStoC(@truncate(start.*)));
    if (destination) |dest| {
        dest.* = @intCast(regKStoC(@truncate(dest.*)));
    }
    return ERROR_NONE;
}
