// SPDX-License-Identifier: GPL-3.0-only
//
// Shared ABI bindings -- typed wrappers over the C decNumber complex runtime.
// Owners previously each declared the raw
// `extern fn addComplex(ar: *align(1) const real_t, ai: ..., ctx: *realContext_t)`
// (six `*align(1) const real_t` + a context) and a local `addCplx`/`mulCplx`/
// `divCplx` helper to marshal a `Complex` into it. This centralizes both: the
// raw extern and the typed `Complex`-taking wrapper live once, threading the
// shared ctxtReal39 context so call sites read as complex arithmetic, not six
// pointer args.

const types = @import("types.zig");
const Real = types.Real;
const Complex = types.Complex;
const RealContext = types.RealContext;

/// The 39-digit real context the electrical/complex transforms compute in.
pub extern var ctxtReal39: RealContext;

extern fn addComplex(ar: *align(1) const Real, ai: *align(1) const Real, br: *align(1) const Real, bi: *align(1) const Real, rr: *Real, ri: *Real, ctx: *RealContext) void;
extern fn mulComplexComplex(f1r: *align(1) const Real, f1i: *align(1) const Real, f2r: *align(1) const Real, f2i: *align(1) const Real, pr: *Real, pi: *Real, ctx: *RealContext) void;
extern fn divComplexComplex(nr: *align(1) const Real, ni: *align(1) const Real, dr: *align(1) const Real, di: *align(1) const Real, qr: *Real, qi: *Real, ctx: *RealContext) void;

/// r = a + b  (in ctxtReal39).
pub inline fn add(a: *const Complex, b: *const Complex, r: *Complex) void {
    addComplex(&a.Real, &a.Imag, &b.Real, &b.Imag, &r.Real, &r.Imag, &ctxtReal39);
}
/// r = a * b  (in ctxtReal39).
pub inline fn mul(a: *const Complex, b: *const Complex, r: *Complex) void {
    mulComplexComplex(&a.Real, &a.Imag, &b.Real, &b.Imag, &r.Real, &r.Imag, &ctxtReal39);
}
/// r = a / b  (in ctxtReal39).
pub inline fn div(a: *const Complex, b: *const Complex, r: *Complex) void {
    divComplexComplex(&a.Real, &a.Imag, &b.Real, &b.Imag, &r.Real, &r.Imag, &ctxtReal39);
}
