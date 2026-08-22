const abi = @import("abi");
const build_options = @import("math_command_wrappers_build_options");
const runtime = @import("../command_wrappers/runtime.zig");

// c43's arctanReal (mathematics/arctan.c) reaches atan through C47_WP34S_Atan.
// This owner carries a second reading of what that helper does at 39 digits, so
// the math_atan lane is a differential between two implementations rather than a
// function compared with itself; every other precision is handed to the helper.
// At the 9af328a87 pin the 39-digit answer stopped coming from the Taylor series
// with sqrt halving and started coming from a tenth-spaced table, and this copy
// followed it.

const atan_table_step: i32 = 10;
const atan_coefficients: i32 = 13;
const atan_guard_digits: i32 = 2;

/// atan(j/10) for j in 0..10; the ends are 0 and pi/4.
fn tableEntry(j: usize) *const runtime.real_t {
    return switch (j) {
        0 => abi.constants.const_0(),
        1 => abi.constants.const39_atan1on10(),
        2 => abi.constants.const39_atan2on10(),
        3 => abi.constants.const39_atan3on10(),
        4 => abi.constants.const39_atan4on10(),
        5 => abi.constants.const39_atan5on10(),
        6 => abi.constants.const39_atan6on10(),
        7 => abi.constants.const39_atan7on10(),
        8 => abi.constants.const39_atan8on10(),
        9 => abi.constants.const39_atan9on10(),
        else => abi.constants.const39_piOn4(),
    };
}

/// P(v) with v = u*u, magnitudes only: the first eight are the Taylor
/// coefficients 1/(2k+1), the last five a minimax fit over |u| <= 1/20.
fn polyCoefficient(k: usize) *const runtime.real_t {
    return switch (k) {
        0 => runtime.z47_math_wrappers_const_1(),
        1 => runtime.z47_math_wrappers_const_1on3(),
        2 => abi.constants.const_1on5(),
        3 => abi.constants.const39_1on7(),
        4 => abi.constants.const39_1on9(),
        5 => abi.constants.const39_1on11(),
        6 => abi.constants.const39_1on13(),
        7 => abi.constants.const39_1on15(),
        8 => abi.constants.const39_atanP08(),
        9 => abi.constants.const39_atanP09(),
        10 => abi.constants.const39_atanP10(),
        11 => abi.constants.const39_atanP11(),
        else => abi.constants.const39_atanP12(),
    };
}

fn copyAbs(destination: *runtime.real_t, source: *const runtime.real_t) void {
    destination.* = source.*;
    runtime.realSetPositiveSign(destination);
}

fn adjustedExponent(value: *const runtime.real_t) i32 {
    return value.digits + value.exponent - 1;
}

/// The number of leading terms worth evaluating: v^k falls below the last digit
/// being computed once k * |log10 v| passes that many digits.
fn hornerTop(v: *const runtime.real_t, digits: i32) i32 {
    if (runtime.realIsZero(v)) {
        return 0;
    }
    const exponent = -adjustedExponent(v);
    if (exponent <= 0) {
        return atan_coefficients - 1;
    }
    const needed = @divTrunc(digits + 6 + exponent - 1, exponent);
    return if (needed < atan_coefficients - 1) needed else atan_coefficients - 1;
}

pub fn arctanReal(
    x: *const runtime.real_t,
    angle: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    if (build_options.use_fake_wp34s_model or real_context.digits != runtime.ctxtReal39.digits) {
        runtime.C47_WP34S_Atan(x, angle, real_context);
        return;
    }

    if (runtime.realIsNaN(x)) {
        runtime.realSetNaN(angle);
        return;
    }

    var a: runtime.real_t = undefined;
    var u: runtime.real_t = undefined;
    var v: runtime.real_t = undefined;
    var c: runtime.real_t = undefined;

    const saved_digits = real_context.digits;
    const with_guard = saved_digits + atan_guard_digits;
    real_context.digits = if (with_guard > 39) 39 else with_guard;

    const negative = runtime.realIsNegative(x);
    copyAbs(&a, x);

    // atan(a) = pi/2 - atan(1/a) puts every argument inside the table's range.
    const inverted = runtime.realCompareGreaterThan(&a, runtime.z47_math_wrappers_const_1());
    if (inverted) {
        runtime.realDivide(runtime.z47_math_wrappers_const_1(), &a, &a, real_context);
    }

    // j = round(10a), always in 0..atan_table_step. Scaling by ten is a shift of
    // the decimal exponent, so both it and c = j/10 are exact.
    c = a;
    c.exponent += 1;
    runtime.realToIntegralValue(&c, &c, runtime.DEC_ROUND_HALF_UP, real_context);
    const j: i32 = runtime.realToInt32C47(&c, null);

    runtime.int32ToReal(j, &c);
    c.exponent -= 1;

    // u = (a - c) / (1 + a*c), so |u| <= 1/(2*atan_table_step).
    runtime.realMultiply(&a, &c, &v, real_context);
    runtime.realAdd(&v, runtime.z47_math_wrappers_const_1(), &v, real_context);
    runtime.realSubtract(&a, &c, &u, real_context);
    runtime.realDivide(&u, &v, &u, real_context);

    runtime.realMultiply(&u, &u, &v, real_context);

    // The series alternates, so negating v turns every Horner step into the same
    // multiply-and-add and the coefficients stay magnitudes.
    var k = hornerTop(&v, real_context.digits);
    runtime.realChangeSign(&v);
    a = polyCoefficient(@intCast(k)).*;
    while (k > 0) {
        k -= 1;
        runtime.realMultiply(&a, &v, &a, real_context);
        runtime.realAdd(&a, polyCoefficient(@intCast(k)), &a, real_context);
    }

    runtime.realMultiply(&a, &u, &a, real_context);
    runtime.realAdd(&a, tableEntry(@intCast(j)), angle, real_context);

    if (inverted) {
        runtime.realSubtract(runtime.z47_math_wrappers_const_piOn2(), angle, angle, real_context);
    }
    if (negative) {
        runtime.realChangeSign(angle);
    }

    real_context.digits = saved_digits;
}
