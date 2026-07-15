// SPDX-License-Identifier: GPL-3.0-only
// Zig owner for src/c47/mathematics/comparisonReals.c.
//
// Defines the canonical comparison/tolerance symbols at the C export
// boundary.  This file must only be analyzed in product builds (gated in
// math_command_wrappers.zig on !use_fake_wp34s_harness_surface) because the
// parity fake runtime defines several of these symbols itself.
//
// Upstream compiles the realCompareAbs*/realIsAnInteger temporaries with
// 159-digit buffers when OPTION_CUBIC_159/OPTION_EIGEN_159 is defined
// (ALLOW_159) and 75-digit buffers otherwise.  This port always uses the
// 159-digit buffers: capacity is a superset, and inputs wider than 75 digits
// only exist in builds where ALLOW_159 is enabled, so behavior is identical.

const std = @import("std");
const abi = @import("abi");
const runtime = @import("../command_wrappers/runtime.zig");
const math_real_predicates = @import("real_predicates.zig");
const math_runtime_helpers = @import("../command_wrappers/helpers.zig");
// Product ABI globals (uint8_t in src/c47/c47.c).  This file is only built
// for the product surface, so the exact C types are used here even though
// the shared runtime declares the fake-harness ABI for significantDigits.
extern var significantDigits: u8;
extern var fractionDigits: u8;
extern var errorMessage: [*c]u8;

const displayBugScreen = abi.host.showBugScreen; // routed through the host-callback boundary
extern fn realSetOne(value: *runtime.real_t) void;
extern fn realToIntegralValue(
    source: *const runtime.real_t,
    destination: *runtime.real_t,
    mode: runtime.rounding_t,
    real_context: *runtime.realContext_t,
) void;
extern fn decNumberCopyAbs(result: *runtime.real_t, rhs: *align(1) const runtime.real_t) *runtime.real_t;
extern fn decQuadCompare(
    result: *runtime.real34_t,
    lhs: *const runtime.real34_t,
    rhs: *const runtime.real34_t,
    context: *runtime.realContext_t,
) *runtime.real34_t;
extern fn decQuadCopyAbs(result: *runtime.real34_t, source: *const runtime.real34_t) *runtime.real34_t;
extern fn decQuadZero(result: *runtime.real34_t) *runtime.real34_t;

// 159-digit decNumber storage (REAL_T_PTR(name, 159), 116 bytes); layout +
// ptr/constPtr accessors centralized in abi (size asserted there).
const Real159 = abi.Real159;

fn maxI32(lhs: i32, rhs: i32) i32 {
    return if (lhs > rhs) lhs else rhs;
}

fn bugScreen(comptime message: [:0]const u8) void {
    const destination = errorMessage[0 .. message.len + 1];
    @memcpy(destination, message[0 .. message.len + 1]);
    displayBugScreen(@ptrCast(errorMessage));
}

inline fn realCompare(
    operand1: *align(1) const runtime.real_t,
    operand2: *align(1) const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    _ = runtime.decNumberCompare(res, operand1, operand2, real_context);
}

const realIsPositive = math_real_predicates.realIsPositive;

inline fn real34Compare(
    operand1: *const runtime.real34_t,
    operand2: *const runtime.real34_t,
    res: *runtime.real34_t,
) void {
    _ = decQuadCompare(res, operand1, operand2, &runtime.ctxtReal34);
}

inline fn real34CopyAbs(source: *const runtime.real34_t, destination: *runtime.real34_t) void {
    _ = decQuadCopyAbs(destination, source);
}

inline fn real34IsPositive(value: *const runtime.real34_t) bool {
    return (value.bytes[15] & 0x80) == 0x00;
}

pub export fn convergenceTolerence(tol: *runtime.real_t) callconv(.c) void {
    realSetOne(tol);
    const digits: i32 = significantDigits;
    tol.exponent -= if (digits == 0 or digits >= 32) 32 else digits;
}

pub export fn irfractionTolerence(ii: i32, tol: *runtime.real_t) callconv(.c) void {
    math_runtime_helpers.int32ToReal(ii, tol);
    const digits: i32 = fractionDigits;
    tol.exponent -= if (digits == 0 or digits >= 34) 34 else digits;
}

pub export fn fractionTolerence(tol: *runtime.real_t) callconv(.c) void {
    irfractionTolerence(2, tol);
}

// Helper to make the exponent -999999 when the input is 0.
// This is used where the exponent is used to determine convergence close to
// 0, hence 0 is seen as a tiny power of ten.
pub export fn realGetExponentComp(val: *const runtime.real_t) callconv(.c) i32 {
    if (runtime.realIsZero(val)) {
        return -999999;
    }
    return val.digits + val.exponent - 1;
}

pub export fn real34CompareAbsGreaterThan(number1: *const runtime.real34_t, number2: *const runtime.real34_t) callconv(.c) bool {
    var num1: runtime.real34_t = undefined;
    var num2: runtime.real34_t = undefined;

    real34CopyAbs(number1, &num1);
    real34CopyAbs(number2, &num2);
    real34Compare(&num1, &num2, &num2);
    return real34IsPositive(&num2) and !runtime.real34IsZero(&num2);
}

pub export fn real34CompareAbsLessThan(number1: *const runtime.real34_t, number2: *const runtime.real34_t) callconv(.c) bool {
    var num1: runtime.real34_t = undefined;
    var num2: runtime.real34_t = undefined;

    real34CopyAbs(number1, &num1);
    real34CopyAbs(number2, &num2);
    real34Compare(&num1, &num2, &num2);
    return runtime.real34IsNegative(&num2) and !runtime.real34IsZero(&num2);
}

pub export fn real34CompareEqual(number1: *const runtime.real34_t, number2: *const runtime.real34_t) callconv(.c) bool {
    var compare: runtime.real34_t = undefined;

    real34Compare(number1, number2, &compare);
    return runtime.real34IsZero(&compare);
}

pub export fn real34CompareAbsEqual(number1: *const runtime.real34_t, number2: *const runtime.real34_t) callconv(.c) bool {
    var compare: runtime.real34_t = undefined;
    var num1: runtime.real34_t = undefined;
    var num2: runtime.real34_t = undefined;

    real34CopyAbs(number1, &num1);
    real34CopyAbs(number2, &num2);

    real34Compare(&num1, &num2, &compare);
    return runtime.real34IsZero(&compare);
}

pub export fn real34CompareGreaterEqual(number1: *const runtime.real34_t, number2: *const runtime.real34_t) callconv(.c) bool {
    var compare: runtime.real34_t = undefined;

    real34Compare(number1, number2, &compare);
    return real34IsPositive(&compare) or runtime.real34IsZero(&compare);
}

pub export fn real34CompareGreaterThan(number1: *const runtime.real34_t, number2: *const runtime.real34_t) callconv(.c) bool {
    var compare: runtime.real34_t = undefined;

    real34Compare(number1, number2, &compare);
    return real34IsPositive(&compare) and !runtime.real34IsZero(&compare);
}

pub export fn real34CompareLessEqual(number1: *const runtime.real34_t, number2: *const runtime.real34_t) callconv(.c) bool {
    var compare: runtime.real34_t = undefined;

    real34Compare(number1, number2, &compare);
    return runtime.real34IsNegative(&compare) or runtime.real34IsZero(&compare);
}

pub export fn real34CompareLessThan(number1: *const runtime.real34_t, number2: *const runtime.real34_t) callconv(.c) bool {
    var compare: runtime.real34_t = undefined;

    real34Compare(number1, number2, &compare);
    return runtime.real34IsNegative(&compare) and !runtime.real34IsZero(&compare);
}

pub export fn realCompareAbsGreaterThan(number1: *align(1) const runtime.real_t, number2: *align(1) const runtime.real_t) callconv(.c) bool {
    var c: runtime.realContext_t = runtime.ctxtReal75;
    var num1: Real159 = undefined;
    var num2: Real159 = undefined;

    c.digits = maxI32(maxI32(75, number1.digits), number2.digits);
    if (c.digits > 159) {
        bugScreen("Exceed 159 digits :realCompareAbsGreaterThan");
    }
    _ = decNumberCopyAbs(num1.ptr(), number1);
    _ = decNumberCopyAbs(num2.ptr(), number2);
    realCompare(num1.constPtr(), num2.constPtr(), num2.ptr(), &c);
    return realIsPositive(num2.constPtr()) and !runtime.realIsZero(num2.constPtr());
}

pub export fn realCompareAbsLessThan(number1: *align(1) const runtime.real_t, number2: *align(1) const runtime.real_t) callconv(.c) bool {
    var c: runtime.realContext_t = runtime.ctxtReal75;
    var num1: Real159 = undefined;
    var num2: Real159 = undefined;

    c.digits = maxI32(maxI32(75, number1.digits), number2.digits);
    if (c.digits > 159) {
        bugScreen("Exceed 159 digits :realCompareAbsLessThan");
    }
    _ = decNumberCopyAbs(num1.ptr(), number1);
    _ = decNumberCopyAbs(num2.ptr(), number2);
    realCompare(num1.constPtr(), num2.constPtr(), num2.ptr(), &c);
    return runtime.realIsNegative(num2.constPtr()) and !runtime.realIsZero(num2.constPtr());
}

pub export fn realCompareEqual(number1: *align(1) const runtime.real_t, number2: *align(1) const runtime.real_t) callconv(.c) bool {
    var compare: runtime.real_t = undefined;
    var c: runtime.realContext_t = runtime.ctxtReal75;

    c.digits = maxI32(maxI32(75, number1.digits), number2.digits);
    realCompare(number1, number2, &compare, &c);
    return runtime.realIsZero(&compare);
}

pub export fn realCompareAbsEqual(number1: *align(1) const runtime.real_t, number2: *align(1) const runtime.real_t) callconv(.c) bool {
    var c: runtime.realContext_t = runtime.ctxtReal75;
    var num1: Real159 = undefined;
    var num2: Real159 = undefined;

    c.digits = maxI32(maxI32(75, number1.digits), number2.digits);
    if (c.digits > 159) {
        bugScreen("Exceed 159 digits :realCompareAbsEqual");
    }
    _ = decNumberCopyAbs(num1.ptr(), number1);
    _ = decNumberCopyAbs(num2.ptr(), number2);
    realCompare(num1.constPtr(), num2.constPtr(), num2.ptr(), &c);
    return runtime.realIsZero(num2.constPtr());
}

pub export fn realCompareGreaterEqual(number1: *align(1) const runtime.real_t, number2: *align(1) const runtime.real_t) callconv(.c) bool {
    var compare: runtime.real_t = undefined;
    var c: runtime.realContext_t = runtime.ctxtReal75;

    c.digits = maxI32(maxI32(75, number1.digits), number2.digits);
    realCompare(number1, number2, &compare, &c);
    return realIsPositive(&compare) or runtime.realIsZero(&compare);
}

pub export fn realCompareGreaterThan(number1: *align(1) const runtime.real_t, number2: *align(1) const runtime.real_t) callconv(.c) bool {
    var compare: runtime.real_t = undefined;
    var c: runtime.realContext_t = runtime.ctxtReal75;

    c.digits = maxI32(maxI32(75, number1.digits), number2.digits);
    realCompare(number1, number2, &compare, &c);
    return realIsPositive(&compare) and !runtime.realIsZero(&compare);
}

pub export fn realCompareLessEqual(number1: *align(1) const runtime.real_t, number2: *align(1) const runtime.real_t) callconv(.c) bool {
    var compare: runtime.real_t = undefined;
    var c: runtime.realContext_t = runtime.ctxtReal75;

    c.digits = maxI32(maxI32(75, number1.digits), number2.digits);
    realCompare(number1, number2, &compare, &c);
    return runtime.realIsNegative(&compare) or runtime.realIsZero(&compare);
}

pub export fn realCompareLessThan(number1: *align(1) const runtime.real_t, number2: *align(1) const runtime.real_t) callconv(.c) bool {
    var compare: runtime.real_t = undefined;
    var c: runtime.realContext_t = runtime.ctxtReal75;

    c.digits = maxI32(maxI32(75, number1.digits), number2.digits);
    realCompare(number1, number2, &compare, &c);
    return runtime.realIsNegative(&compare) and !runtime.realIsZero(&compare);
}

pub export fn real34IsAnInteger(x: *const runtime.real34_t) callconv(.c) bool {
    var y: runtime.real34_t = undefined;
    var zero34: runtime.real34_t = undefined;

    if (runtime.real34IsNaN(x) or runtime.real34IsInfinite(x)) {
        return false;
    }

    runtime.real34ToIntegralValue(x, &y, runtime.DEC_ROUND_DOWN);
    runtime.real34Subtract(x, &y, &y);

    // Upstream compares against const34_0; an explicitly zeroed decQuad is
    // numerically identical for this value comparison.
    _ = decQuadZero(&zero34);
    return real34CompareEqual(&y, &zero34);
}

pub export fn realIsAnInteger(x: *const runtime.real_t) callconv(.c) bool {
    var c: runtime.realContext_t = runtime.ctxtReal75;
    var y: Real159 = undefined;

    c.digits = maxI32(75, x.digits);
    if (c.digits > 159) {
        bugScreen("Exceed 159 digits :realIsAnInteger");
    }
    if (runtime.realIsNaN(x)) {
        return false;
    }

    if (runtime.realIsInfinite(x)) {
        return true;
    }

    realToIntegralValue(x, y.ptr(), runtime.DEC_ROUND_DOWN, &c);
    _ = runtime.decNumberSubtract(y.ptr(), x, y.constPtr(), &c);

    return realCompareEqual(y.constPtr(), @alignCast(math_runtime_helpers.z47_math_wrappers_const_0()));
}
