const build_options = @import("stack_state_build_options");
const product_real_owned = @import("stack_runtime_product_real_owned.zig");
const register_range_owned = @import("stack_runtime_register_range_owned.zig");

const use_fake_stack_state_harness_surface =
    @hasDecl(build_options, "use_fake_stack_state_harness_surface") and
    build_options.use_fake_stack_state_harness_surface;

const PRODUCT_DEC_ROUND_DOWN = product_real_owned.PRODUCT_DEC_ROUND_DOWN;
const product_rounding_t = product_real_owned.product_rounding_t;
const ProductReal = product_real_owned.ProductReal;
const ProductReal34 = product_real_owned.ProductReal34;
const ProductRealContext = product_real_owned.ProductRealContext;

const calcRegister_t = i16;

const REGISTER_X: calcRegister_t = 100;
const FIRST_LOCAL_REGISTER: calcRegister_t = 7000;
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

fn validateRegisterSourceRange(load_into_memory: ?bool, start: u16, count: *u16, local_register_count: u8) u8 {
    const register_x: u16 = @intCast(REGISTER_X);
    const first_local_register: u16 = @intCast(FIRST_LOCAL_REGISTER);
    return register_range_owned.validateRegisterSourceRange(
        load_into_memory,
        start,
        count,
        register_x,
        first_local_register,
        local_register_count,
        ERROR_OUT_OF_RANGE,
        ERROR_NONE,
    );
}

fn validateRegisterDestinationRange(start: u16, count: u16, local_register_count: u8) u8 {
    const register_x: u16 = @intCast(REGISTER_X);
    const first_local_register: u16 = @intCast(FIRST_LOCAL_REGISTER);
    return register_range_owned.validateRegisterDestinationRange(
        start,
        count,
        register_x,
        first_local_register,
        local_register_count,
        ERROR_OUT_OF_RANGE,
        ERROR_NONE,
    );
}

pub fn getRegParamProduct(load_into_memory: ?*bool, start: *u16, count: *u16, destination: ?*u16, local_register_count: u8) u8 {
    if (use_fake_stack_state_harness_surface) {
        return ERROR_OUT_OF_RANGE;
    }

    var x: ProductReal = undefined;
    var integer_part: ProductReal = undefined;
    var thousand: ProductReal = undefined;

    if (getRegisterDataType(REGISTER_X) != dtReal34) {
        return ERROR_INVALID_DATA_TYPE_FOR_OP;
    }

    start.* = 0;
    count.* = 0;
    if (destination) |dest| {
        dest.* = 0;
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
    start.* = @intCast(realToInt32C47(&integer_part, null));

    productRealSubtract(&x, &integer_part, &x, product_real_owned.realContext39());
    x.exponent += 2;
    realToIntegralValue(&x, &integer_part, PRODUCT_DEC_ROUND_DOWN, product_real_owned.realContext39());
    count.* = @intCast(realToInt32C47(&integer_part, null));

    if (destination) |dest| {
        productRealSubtract(&x, &integer_part, &x, product_real_owned.realContext39());
        x.exponent += 3;
        realToIntegralValue(&x, &integer_part, PRODUCT_DEC_ROUND_DOWN, product_real_owned.realContext39());
        dest.* = @intCast(realToInt32C47(&integer_part, null));
    }

    const source_error = validateRegisterSourceRange(
        if (load_into_memory) |load| load.* else null,
        start.*,
        count,
        local_register_count,
    );
    if (source_error != ERROR_NONE) {
        return source_error;
    }

    if (destination) |dest| {
        return validateRegisterDestinationRange(dest.*, count.*, local_register_count);
    }

    return ERROR_NONE;
}
