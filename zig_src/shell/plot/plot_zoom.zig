//! Plot viewport zoom -- the pure core of frontier_graphs' multiplyZoomFactors.
//!
//! Zooming the plot pans the min/max bounds outward by dx/dy * zoomfactor, then
//! rescales symmetrically about the recomputed center by plotzoom * histofactor.
//! The range bounds (x_min/x_max/y_min/y_max/dx/dy) are real_t (decNumber), to
//! match c43 at an ABI-swappable level; the arithmetic runs through the decNumber
//! ops in the exact order of c43's multiplyZoomFactors, in &ctxtReal39. Only the
//! zoom scalars stay float (dimensionless fractions), combined in f64 and
//! converted once per use via convertDoubleToReal.
//!
//! Because the math now depends on decNumber/ctxtReal39 (only present in the
//! linked build), this module has no std-only native unit coverage; it is
//! verified through the C oracle path, like the graphs owner.

const abi = @import("abi"); // shared ABI bindings
const real_t = abi.Real;
const realContext_t = abi.RealContext;
const consts = abi.constants;
const const_1on2 = consts.const_1on2;

extern var ctxtReal39: realContext_t;

// decNumber/registerValueConversions primitives behind the real*/convert* macros.
extern fn decNumberAdd(r: *real_t, a: *align(1) const real_t, b: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberSubtract(r: *real_t, a: *align(1) const real_t, b: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberMultiply(r: *real_t, a: *align(1) const real_t, b: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn convertDoubleToReal(x: f64, destination: *real_t, ctxt: *realContext_t) void;

// realType.h macros (arg order matches the C macros: operand1, operand2, res).
inline fn realAdd(a: *align(1) const real_t, b: *align(1) const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberAdd(res, a, b, ctx);
}
inline fn realSubtract(a: *align(1) const real_t, b: *align(1) const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberSubtract(res, a, b, ctx);
}
inline fn realMultiply(a: *align(1) const real_t, b: *align(1) const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberMultiply(res, a, b, ctx);
}

/// Pan and rescale the plot bounds in place. `zoomfactor` is the pan step; the
/// `plotzoom*`/`histofactor` factors rescale about the center. The ranges are
/// real_t; every op mirrors c43's multiplyZoomFactors (graphs.c) in &ctxtReal39.
pub fn multiplyZoomFactors(
    plotzoomx: f32,
    plotzoomy: f32,
    histofactor: f32,
    zoomfactor: f32,
    x_min_: *real_t,
    x_max_: *real_t,
    y_min_: *real_t,
    y_max_: *real_t,
    dx: *real_t,
    dy: *real_t,
) void {
    // ranges in real_t; the zoom scalars are dimensionless fractions, combined in
    // float/double then converted once per use
    var k: real_t = undefined;
    var t: real_t = undefined;
    var xavg: real_t = undefined;
    var yavg: real_t = undefined;

    convertDoubleToReal(@as(f64, zoomfactor), &k, &ctxtReal39); // k = zoomfactor
    realMultiply(dx, &k, &t, &ctxtReal39); // t = dx * zoomfactor
    realSubtract(x_min_, &t, x_min_, &ctxtReal39); // x_min = x_min - dx * zoomfactor
    realAdd(x_max_, &t, x_max_, &ctxtReal39); // x_max = x_max + dx * zoomfactor
    realMultiply(dy, &k, &t, &ctxtReal39); // t = dy * zoomfactor
    realSubtract(y_min_, &t, y_min_, &ctxtReal39); // y_min = y_min - dy * zoomfactor
    realAdd(y_max_, &t, y_max_, &ctxtReal39); // y_max = y_max + dy * zoomfactor
    realSubtract(x_max_, x_min_, dx, &ctxtReal39); // dx = x_max - x_min
    realSubtract(y_max_, y_min_, dy, &ctxtReal39); // dy = y_max - y_min
    realAdd(x_max_, x_min_, &xavg, &ctxtReal39); // xavg = x_max + x_min
    realMultiply(&xavg, const_1on2(), &xavg, &ctxtReal39); // xavg = (x_max + x_min) / 2
    realAdd(y_max_, y_min_, &yavg, &ctxtReal39); // yavg = y_max + y_min
    realMultiply(&yavg, const_1on2(), &yavg, &ctxtReal39); // yavg = (y_max + y_min) / 2
    convertDoubleToReal(@as(f64, plotzoomy) * @as(f64, histofactor) / 2.0, &k, &ctxtReal39); // k = plotzoomy * histofactor / 2
    realMultiply(dy, &k, &t, &ctxtReal39); // t = dy/2 * plotzoomy * histofactor
    realSubtract(&yavg, &t, y_min_, &ctxtReal39); // y_min = yavg - dy/2 * plotzoomy * histofactor
    realAdd(&yavg, &t, y_max_, &ctxtReal39); // y_max = yavg + dy/2 * plotzoomy * histofactor
    convertDoubleToReal(@as(f64, plotzoomx) * @as(f64, histofactor) / 2.0, &k, &ctxtReal39); // k = plotzoomx * histofactor / 2
    realMultiply(dx, &k, &t, &ctxtReal39); // t = dx/2 * plotzoomx * histofactor
    realSubtract(&xavg, &t, x_min_, &ctxtReal39); // x_min = xavg - dx/2 * plotzoomx * histofactor
    realAdd(&xavg, &t, x_max_, &ctxtReal39); // x_max = xavg + dx/2 * plotzoomx * histofactor
}
