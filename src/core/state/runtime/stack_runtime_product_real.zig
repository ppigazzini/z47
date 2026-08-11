const std = @import("std");
const abi = @import("abi");
const build_options = @import("stack_state_build_options");

const use_fake_stack_state_harness_surface =
    build_options.use_fake_stack_state_harness_surface;

pub const product_rounding_t = c_int;
pub const PRODUCT_DEC_ROUND_DOWN: product_rounding_t = 5;
pub const product_real_negative_bit: u8 = 0x80;

// These are the decNumber real/real34/context layouts (oracle-verified in abi);
// the product path reached them through local re-mirrors. Alias to the shared
// abi types. product_rounding_t is c_int, matching abi.RealContext.round.
pub const ProductReal = abi.Real;
pub const ProductReal34 = abi.Real34;
pub const ProductRealContext = abi.RealContext;

extern var ctxtReal39: ProductRealContext;
extern fn decimal128ToNumber(source: *const ProductReal34, destination: *ProductReal) *ProductReal;
extern fn decNumberFromUInt32(result: *ProductReal, rhs: u32) *ProductReal;
extern fn decNumberSubtract(result: *ProductReal, lhs: *const ProductReal, rhs: *const ProductReal, real_context: *ProductRealContext) *ProductReal;

var fake_real_context: ProductRealContext = .{
    .digits = 0,
    .emax = 0,
    .emin = 0,
    .round = PRODUCT_DEC_ROUND_DOWN,
    .traps = 0,
    .status = 0,
    .clamp = 0,
};

pub fn realContext39() *ProductRealContext {
    if (use_fake_stack_state_harness_surface) {
        return &fake_real_context;
    }

    return &ctxtReal39;
}

pub fn productReal34ToReal(source: *const ProductReal34, destination: *ProductReal) void {
    if (use_fake_stack_state_harness_surface) {
        destination.* = .{ .digits = 0, .exponent = 0, .bits = 0, .lsu = std.mem.zeroes([25]u16) };
        return;
    }

    _ = decimal128ToNumber(source, destination);
}

pub fn productUInt32ToReal(source: u32, destination: *ProductReal) void {
    if (use_fake_stack_state_harness_surface) {
        destination.* = .{ .digits = 0, .exponent = 0, .bits = 0, .lsu = std.mem.zeroes([25]u16) };
        return;
    }

    _ = decNumberFromUInt32(destination, source);
}

pub fn productRealIsNegative(value: *const ProductReal) bool {
    return (value.bits & product_real_negative_bit) != 0;
}

// decNumber's DECSPECIAL: the infinity and the two NaN bits together.
const product_real_special_bits: u8 = 0x70;

/// decNumberIsZero: a single zero digit and no special bits set. Decimal zero
/// carries a sign, so this is true for -0 as well, which is what separates "the
/// value is below zero" from "the sign bit is set".
pub fn productRealIsZero(value: *const ProductReal) bool {
    return value.lsu[0] == 0 and value.digits == 1 and (value.bits & product_real_special_bits) == 0;
}

pub fn productRealSetPositiveSign(value: *ProductReal) void {
    value.bits &= 0x7f;
}

pub fn productRealSubtract(lhs: *const ProductReal, rhs: *const ProductReal, result: *ProductReal, real_context: *ProductRealContext) void {
    if (use_fake_stack_state_harness_surface) {
        result.* = .{ .digits = 0, .exponent = 0, .bits = 0, .lsu = std.mem.zeroes([25]u16) };
        return;
    }

    _ = decNumberSubtract(result, lhs, rhs, real_context);
}
