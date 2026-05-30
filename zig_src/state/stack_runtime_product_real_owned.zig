pub const product_rounding_t = c_int;
pub const PRODUCT_DEC_ROUND_DOWN: product_rounding_t = 5;
pub const product_real_negative_bit: u8 = 0x80;

pub const ProductReal = extern struct {
    digits: i32,
    exponent: i32,
    bits: u8,
    lsu: [25]u16,
};

pub const ProductReal34 = extern struct {
    bytes: [16]u8,
};

pub const ProductRealContext = extern struct {
    digits: i32,
    emax: i32,
    emin: i32,
    round: product_rounding_t,
    traps: u32,
    status: u32,
    clamp: u8,
};

extern var ctxtReal39: ProductRealContext;
extern fn decimal128ToNumber(source: *const ProductReal34, destination: *ProductReal) *ProductReal;
extern fn decNumberFromUInt32(result: *ProductReal, rhs: u32) *ProductReal;
extern fn decNumberSubtract(result: *ProductReal, lhs: *const ProductReal, rhs: *const ProductReal, real_context: *ProductRealContext) *ProductReal;

pub fn realContext39() *ProductRealContext {
    return &ctxtReal39;
}

pub fn productReal34ToReal(source: *const ProductReal34, destination: *ProductReal) void {
    _ = decimal128ToNumber(source, destination);
}

pub fn productUInt32ToReal(source: u32, destination: *ProductReal) void {
    _ = decNumberFromUInt32(destination, source);
}

pub fn productRealIsNegative(value: *const ProductReal) bool {
    return (value.bits & product_real_negative_bit) != 0;
}

pub fn productRealSetPositiveSign(value: *ProductReal) void {
    value.bits &= 0x7f;
}

pub fn productRealSubtract(lhs: *const ProductReal, rhs: *const ProductReal, result: *ProductReal, real_context: *ProductRealContext) void {
    _ = decNumberSubtract(result, lhs, rhs, real_context);
}