const runtime = @import("../command_wrappers/runtime.zig");

// decNumber's +Infinity: a zero coefficient with the infinity bit set.
inline fn realSetPlusInfinity(res: *runtime.real_t) void {
    runtime.realSetZero(res);
    res.bits = 0x40;
}

// Linear interpolation between a and b by an amount p: p = 0 returns a, p = 1
// returns b, a = b returns a. An infinite endpoint carries the sign of its
// weight, (1 - p) for a and p for b; two infinities of opposite weighted sign
// give NaN.
pub fn linpolScalar(a: *const runtime.real_t, b: *const runtime.real_t, p: *const runtime.real_t, res: *runtime.real_t) void {
    var x: runtime.real_t = undefined;

    if (runtime.realIsNaN(a) or runtime.realIsNaN(b) or runtime.realIsNaN(p) or runtime.realIsInfinite(p)) {
        runtime.realSetNaN(res);
    } else if (runtime.realIsZero(p)) {
        res.* = a.*;
    } else if (runtime.realCompareEqual(p, runtime.z47_math_wrappers_const_1())) {
        res.* = b.*;
    } else if (runtime.realCompareEqual(a, b)) {
        res.* = a.*;
    } else if (runtime.realIsInfinite(a) or runtime.realIsInfinite(b)) {
        runtime.realSubtract(runtime.z47_math_wrappers_const_1(), p, &x, &runtime.ctxtReal75);
        const a_negative = runtime.realIsNegative(a) != runtime.realIsNegative(&x);
        const b_negative = runtime.realIsNegative(b) != runtime.realIsNegative(p);
        if (runtime.realIsInfinite(a) and runtime.realIsInfinite(b)) {
            if (a_negative != b_negative) {
                runtime.realSetNaN(res);
            } else {
                realSetPlusInfinity(res);
                if (a_negative) {
                    runtime.realChangeSign(res);
                }
            }
        } else if (runtime.realIsInfinite(a)) {
            res.* = a.*;
            if (runtime.realIsNegative(&x)) {
                runtime.realChangeSign(res);
            }
        } else {
            res.* = b.*;
            if (runtime.realIsNegative(p)) {
                runtime.realChangeSign(res);
            }
        }
    } else if (runtime.realIsNegative(a) != runtime.realIsNegative(b)) {
        // a * b < 0: linpol = (1 - p) * a + p * b
        x = p.*;
        runtime.realChangeSign(&x);
        runtime.realFMA(&x, a, a, &x, &runtime.ctxtReal75);
        runtime.realFMA(p, b, &x, res, &runtime.ctxtReal75);
    } else {
        runtime.realSubtract(b, a, &x, &runtime.ctxtReal75);
        runtime.realFMA(&x, p, a, res, &runtime.ctxtReal75);
    }
}
