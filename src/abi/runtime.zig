// SPDX-License-Identifier: GPL-3.0-only
//
// Shared ABI bindings -- typed wrappers over the C decNumber complex runtime.
// The raw complex arithmetic extern and the `Complex`-taking wrapper
// (`addCplx`/`mulCplx`/`divCplx`) live once here, threading the shared ctxtReal39
// context so call sites read as complex arithmetic.

const types = @import("primitives.zig");
const Complex = types.Complex;
const RealContext = types.RealContext;

/// The 39-digit real context the electrical/complex transforms compute in.
pub extern var ctxtReal39: RealContext;

extern fn addComplex(a: *const Complex, b: *const Complex, res: *Complex, ctx: *RealContext) void;
extern fn mulComplexComplex(factor1: *const Complex, factor2: *const Complex, product: *Complex, ctx: *RealContext) void;
extern fn divComplexComplex(numer: *const Complex, denom: *const Complex, quotient: *Complex, ctx: *RealContext) void;

/// r = a + b  (in ctxtReal39).
pub fn add(a: *const Complex, b: *const Complex, r: *Complex) void {
    addComplex(a, b, r, &ctxtReal39);
}
/// r = a * b  (in ctxtReal39).
pub fn mul(a: *const Complex, b: *const Complex, r: *Complex) void {
    mulComplexComplex(a, b, r, &ctxtReal39);
}
/// r = a / b  (in ctxtReal39).
pub fn div(a: *const Complex, b: *const Complex, r: *Complex) void {
    divComplexComplex(a, b, r, &ctxtReal39);
}
