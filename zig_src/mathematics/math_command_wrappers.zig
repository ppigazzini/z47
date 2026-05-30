const std = @import("std");
const atan_owned = @import("math_atan_owned.zig");
const atan2_export = @import("math_atan2_export.zig");
const atan2_command_owned = @import("math_atan2_command_owned.zig");
const build_options = @import("math_command_wrappers_build_options");
const check_value_owned = @import("math_check_value_owned.zig");
const circular_trig_export = @import("math_circular_trig_export.zig");
const circular_trig_owned = @import("math_circular_trig_owned.zig");
const compare_owned = @import("math_compare_owned.zig");
const convergence_owned = @import("math_convergence_owned.zig");
const circular_trig_command_owned = @import("math_circular_trig_command_owned.zig");
const double_width_command_owned = @import("math_double_width_command_owned.zig");
const get_type_owned = @import("math_get_type_owned.zig");
const integer_part_owned = @import("math_integer_part_owned.zig");
const inverse_trig_command_owned = @import("math_inverse_trig_command_owned.zig");
const lambertw_command_owned = @import("math_lambertw_command_owned.zig");
const ln_complex_export = @import("math_ln_complex_export.zig");
const logxy_command_owned = @import("math_logxy_command_owned.zig");
const percent_command_owned = @import("math_percent_command_owned.zig");
const powlog_command_owned = @import("math_powlog_command_owned.zig");
const projection_owned = @import("math_projection_owned.zig");
const random_command_owned = @import("math_random_command_owned.zig");
const real_trig_export = @import("math_real_trig_export.zig");
const real_trig_owned = @import("math_real_trig_owned.zig");
const rectangular_to_polar_owned = @import("math_rectangular_to_polar_owned.zig");
const runtime = @import("math_command_wrappers_runtime.zig");
const sinc_command_owned = @import("math_sinc_command_owned.zig");
const transcendental_command_owned = @import("math_transcendental_command_owned.zig");
const transform_command_owned = @import("math_transform_command_owned.zig");

comptime {
    _ = atan2_export.z47_math_wrappers_owned_C47_WP34S_Atan2;
    _ = circular_trig_export.z47_math_wrappers_owned_C47_WP34S_Cvt2RadSinCosTan;
    _ = ln_complex_export.z47_math_wrappers_owned_lnComplex;
    _ = real_trig_export.z47_math_wrappers_owned_C47_WP34S_Asin;
    _ = real_trig_export.z47_math_wrappers_owned_C47_WP34S_Acos;
    _ = real_trig_export.z47_math_wrappers_owned_WP34S_SinhCosh;
    _ = real_trig_export.z47_math_wrappers_owned_WP34S_Tanh;
    _ = real_trig_export.z47_math_wrappers_owned_WP34S_ArcSinh;
    _ = real_trig_export.z47_math_wrappers_owned_WP34S_ArcTanh;
}

fn bufPrintZ(buffer: []u8, comptime format: []const u8, args: anytype) ![:0]u8 {
    const slice = try std.fmt.bufPrint(buffer[0 .. buffer.len - 1], format, args);
    buffer[slice.len] = 0;
    return buffer[0 .. slice.len :0];
}

const no_register = @as(runtime.calcRegister_t, -1);
const BranchFn = *const fn () callconv(.c) void;
const PowRealFn = *const fn (x: *const runtime.real_t, res: *runtime.real_t, real_context: *runtime.realContext_t) callconv(.c) void;
const long_integer_power_negative_exponent: i32 = -1;

const add_retained = runtime.retained.z47_math_wrappers_retained_fnAdd;
const subtract_retained = runtime.retained.z47_math_wrappers_retained_fnSubtract;
const multiply_retained = runtime.retained.z47_math_wrappers_retained_fnMultiply;
const divide_retained = runtime.retained.z47_math_wrappers_retained_fnDivide;
const integer_divide_retained = runtime.retained.z47_math_wrappers_retained_fnIDiv;
const integer_divide_remainder_retained = runtime.retained.z47_math_wrappers_retained_fnIDivR;
const round_retained = runtime.retained.z47_math_wrappers_retained_fnRound;
const decrement_retained = runtime.retained.z47_math_wrappers_retained_fnDec;
const increment_retained = runtime.retained.z47_math_wrappers_retained_fnInc;
const compare_less_than_retained = runtime.retained.z47_math_wrappers_retained_fnXLessThan;
const compare_less_equal_retained = runtime.retained.z47_math_wrappers_retained_fnXLessEqual;
const compare_greater_than_retained = runtime.retained.z47_math_wrappers_retained_fnXGreaterThan;
const compare_greater_equal_retained = runtime.retained.z47_math_wrappers_retained_fnXGreaterEqual;
const compare_equal_retained = runtime.retained.z47_math_wrappers_retained_fnXEqualsTo;
const compare_not_equal_retained = runtime.retained.z47_math_wrappers_retained_fnXNotEqual;
const compare_almost_equal_retained = runtime.retained.z47_math_wrappers_retained_fnXAlmostEqual;
const to_polar2_retained = runtime.retained.z47_math_wrappers_retained_fnToPolar2;
const to_rect2_retained = runtime.retained.z47_math_wrappers_retained_fnToRect2;
fn copyReal(destination: *runtime.real_t, source: *const runtime.real_t) void {
    destination.* = source.*;
}

fn negateReal(destination: *runtime.real_t, source: *const runtime.real_t) void {
    copyReal(destination, source);
    runtime.realChangeSign(destination);
}

fn realAbsLessThan(lhs: *const runtime.real_t, rhs: *const runtime.real_t) bool {
    return !runtime.realCompareAbsEqual(lhs, rhs) and !runtime.realCompareAbsGreaterThan(lhs, rhs);
}

pub export fn pcg32_random_r(rng: *runtime.pcg32_random_t) callconv(.c) u32 {
    return random_command_owned.pcg32RandomR(rng);
}

pub export fn pcg32_srandom_r(rng: *runtime.pcg32_random_t, initstate: u64, initseq: u64) callconv(.c) void {
    random_command_owned.pcg32SrandomR(rng, initstate, initseq);
}

pub export fn pcg32_srandom(seed: u64, seq: u64) callconv(.c) void {
    random_command_owned.pcg32Srandom(seed, seq);
}

pub export fn z47_math_wrappers_bounded_rand(s: u32) callconv(.c) u32 {
    return random_command_owned.boundedRandExport(s);
}

pub export fn realRandomU01(res: *runtime.real_t) callconv(.c) void {
    random_command_owned.realRandomU01(res);
}

pub export fn sinComplex(
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    res_real: *runtime.real_t,
    res_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    var sina: runtime.real_t = undefined;
    var cosa: runtime.real_t = undefined;
    var sinhb: runtime.real_t = undefined;
    var coshb: runtime.real_t = undefined;

    circular_trig_owned.convertAngleToSinCosTan(real, runtime.amRadian, &sina, &cosa, null, real_context);
    real_trig_owned.sinhCoshReal(imag, &sinhb, &coshb, real_context);
    runtime.realMultiply(&sina, &coshb, res_real, real_context);
    runtime.realMultiply(&cosa, &sinhb, res_imag, real_context);
}

pub export fn cosComplex(
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    res_real: *runtime.real_t,
    res_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    var sina: runtime.real_t = undefined;
    var cosa: runtime.real_t = undefined;
    var sinhb: runtime.real_t = undefined;
    var coshb: runtime.real_t = undefined;

    circular_trig_owned.convertAngleToSinCosTan(real, runtime.amRadian, &sina, &cosa, null, real_context);
    real_trig_owned.sinhCoshReal(imag, &sinhb, &coshb, real_context);
    runtime.realMultiply(&cosa, &coshb, res_real, real_context);
    runtime.realMultiply(&sina, &sinhb, res_imag, real_context);
    runtime.realChangeSign(res_imag);
}

pub export fn sinCosReal(trig_type: runtime.trigType_t) callconv(.c) void {
    var x: runtime.real_t = undefined;
    var x_angular_mode: runtime.angularMode_t = undefined;

    if (!runtime.getRegisterAsRealAngle(runtime.REGISTER_X, &x, &x_angular_mode, runtime.ifLongIntegerDoAngleReduction)) {
        return;
    }

    if (runtime.realIsSpecial(&x)) {
        runtime.realSetNaN(&x);
    } else if (trig_type == runtime.trigSin) {
        circular_trig_owned.convertAngleToSinCosTan(&x, x_angular_mode, &x, null, null, &runtime.ctxtReal75);
    } else {
        circular_trig_owned.convertAngleToSinCosTan(&x, x_angular_mode, null, &x, null, &runtime.ctxtReal75);
    }

    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
}

pub export fn sinCosCplx(trig_type: runtime.trigType_t) callconv(.c) void {
    var z_real: runtime.real_t = undefined;
    var z_imag: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &z_real, &z_imag)) {
        return;
    }

    if (trig_type == runtime.trigSin) {
        sinComplex(&z_real, &z_imag, &z_real, &z_imag, &runtime.ctxtReal75);
    } else {
        cosComplex(&z_real, &z_imag, &z_real, &z_imag, &runtime.ctxtReal75);
    }

    runtime.convertComplexToResultRegister(&z_real, &z_imag, runtime.REGISTER_X);
}

pub export fn sinhCoshReal(trig_type: runtime.trigType_t) callconv(.c) void {
    var x: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsInfinite(&x) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.z47_math_wrappers_report_sinh_cosh_real_domain_error();
        return;
    }

    if (trig_type == runtime.trigSin) {
        real_trig_owned.sinhCoshReal(&x, &x, null, &runtime.ctxtReal39);
    } else {
        real_trig_owned.sinhCoshReal(&x, null, &x, &runtime.ctxtReal39);
    }

    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
}

pub export fn sinhCoshCplx(trig_type: runtime.trigType_t) callconv(.c) void {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;
    var sinha: runtime.real_t = undefined;
    var cosha: runtime.real_t = undefined;
    var sinb: runtime.real_t = undefined;
    var cosb: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &a, &b)) {
        return;
    }

    real_trig_owned.sinhCoshReal(&a, &sinha, &cosha, &runtime.ctxtReal39);
    circular_trig_owned.convertAngleToSinCosTan(&b, runtime.amRadian, &sinb, &cosb, null, &runtime.ctxtReal39);

    if (trig_type == runtime.trigSin) {
        runtime.realMultiply(&sinha, &cosb, &a, &runtime.ctxtReal39);
        runtime.realMultiply(&cosha, &sinb, &b, &runtime.ctxtReal39);
    } else {
        runtime.realMultiply(&cosha, &cosb, &a, &runtime.ctxtReal39);
        runtime.realMultiply(&sinha, &sinb, &b, &runtime.ctxtReal39);
    }

    runtime.convertComplexToResultRegister(&a, &b, runtime.REGISTER_X);
}

pub export fn TanComplex(
    x_real: *const runtime.real_t,
    x_imag: *const runtime.real_t,
    r_real: *runtime.real_t,
    r_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) u8 {
    var sina: runtime.real_t = undefined;
    var cosa: runtime.real_t = undefined;
    var sinhb: runtime.real_t = undefined;
    var coshb: runtime.real_t = undefined;
    var numer_real: runtime.real_t = undefined;
    var numer_imag: runtime.real_t = undefined;
    var denom_real: runtime.real_t = undefined;
    var denom_imag: runtime.real_t = undefined;

    circular_trig_owned.convertAngleToSinCosTan(x_real, runtime.amRadian, &sina, &cosa, null, real_context);
    real_trig_owned.sinhCoshReal(x_imag, &sinhb, &coshb, real_context);

    runtime.realMultiply(&sina, &coshb, &numer_real, real_context);
    runtime.realMultiply(&cosa, &sinhb, &numer_imag, real_context);
    runtime.realMultiply(&cosa, &coshb, &denom_real, real_context);
    runtime.realMultiply(&sina, &sinhb, &denom_imag, real_context);
    runtime.realChangeSign(&denom_imag);

    runtime.divComplexComplex(&numer_real, &numer_imag, &denom_real, &denom_imag, r_real, r_imag, real_context);
    return runtime.ERROR_NONE;
}

pub export fn TanhComplex(
    x_real: *const runtime.real_t,
    x_imag: *const runtime.real_t,
    r_real: *runtime.real_t,
    r_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) u8 {
    var sin_value: runtime.real_t = undefined;
    var cos_value: runtime.real_t = undefined;
    var denom_real: runtime.real_t = undefined;
    var denom_imag: runtime.real_t = undefined;

    _ = real_context;

    if (runtime.realIsZero(x_imag)) {
        real_trig_owned.tanhReal(x_real, r_real, &runtime.ctxtReal39);
        runtime.realSetZero(r_imag);
    } else {
        real_trig_owned.tanhReal(x_real, r_real, &runtime.ctxtReal39);
        circular_trig_owned.convertAngleToSinCosTan(x_imag, runtime.amRadian, &sin_value, &cos_value, r_imag, &runtime.ctxtReal39);

        runtime.realSetOne(&denom_real);
        runtime.realMultiply(r_real, r_imag, &denom_imag, &runtime.ctxtReal39);
        runtime.divComplexComplex(r_real, r_imag, &denom_real, &denom_imag, r_real, r_imag, &runtime.ctxtReal39);
    }

    return runtime.ERROR_NONE;
}

fn setExpLimitResult(x: *const runtime.real_t, result: *runtime.real_t, zero: *const runtime.real_t) void {
    if (runtime.realIsNegative(x)) {
        copyReal(result, zero);
    } else {
        copyReal(result, runtime.z47_math_wrappers_const_plus_infinity());
    }
}

pub export fn realExpLimitCheck(
    x: *const runtime.real_t,
    result: *runtime.real_t,
    zero: *const runtime.real_t,
) callconv(.c) bool {
    return transcendental_command_owned.realExpLimitCheck(x, result, zero);
}

pub export fn realExp(
    x: *const runtime.real_t,
    result: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    transcendental_command_owned.realExp(x, result, real_context);
}

pub export fn expComplex(
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    res_real: *runtime.real_t,
    res_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    transcendental_command_owned.expComplex(real, imag, res_real, res_imag, real_context);
}

pub export fn realExpM1(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    transcendental_command_owned.realExpM1(x, res, real_context);
}

pub export fn realLog10(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    lnRealValue(x, res, real_context);
    runtime.realDivide(res, runtime.z47_math_wrappers_const_ln10(), res, real_context);
}

fn lnRealValue(
    x_in: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    transcendental_command_owned.lnRealValue(x_in, res, real_context);
}

fn expM1Complex(
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    res_real: *runtime.real_t,
    res_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    transcendental_command_owned.expM1Complex(real, imag, res_real, res_imag, real_context);
}

pub export fn realPower10(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    runtime.realMultiply(x, runtime.z47_math_wrappers_const_ln10(), res, real_context);
    realExp(res, res, real_context);
}

pub export fn realPower2(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    runtime.realMultiply(x, runtime.z47_math_wrappers_const_ln2(), res, real_context);
    realExp(res, res, real_context);
}

pub export fn intPowReal(powf: PowRealFn) callconv(.c) void {
    var x: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsSpecial(&x) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.z47_math_wrappers_report_int_pow_real_domain_error();
        return;
    }

    powf(&x, &x, &runtime.ctxtReal39);
    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
}

pub export fn intPowCplx(ln_base: *const runtime.real_t) callconv(.c) void {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;
    var factor: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &a, &b)) {
        return;
    }

    runtime.realMultiply(ln_base, &a, &a, &runtime.ctxtReal39);
    runtime.realMultiply(ln_base, &b, &b, &runtime.ctxtReal39);

    realExp(&a, &factor, &runtime.ctxtReal39);
    runtime.realPolarToRectangular(runtime.z47_math_wrappers_const_1(), &b, &a, &b, &runtime.ctxtReal39);
    runtime.realMultiply(&factor, &a, &a, &runtime.ctxtReal39);
    runtime.realMultiply(&factor, &b, &b, &runtime.ctxtReal39);

    runtime.convertComplexToResultRegister(&a, &b, runtime.REGISTER_X);
}

fn lnReal() callconv(.c) void {
    transcendental_command_owned.lnReal();
}

fn lnCplx() callconv(.c) void {
    transcendental_command_owned.lnCplx();
}

fn lnP1Complex(
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    ln_real: *runtime.real_t,
    ln_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    transcendental_command_owned.lnP1Complex(real, imag, ln_real, ln_imag, real_context);
}

fn expM1Real() callconv(.c) void {
    transcendental_command_owned.expM1Real();
}

fn expM1Cplx() callconv(.c) void {
    transcendental_command_owned.expM1Cplx();
}

fn lnP1Real() callconv(.c) void {
    transcendental_command_owned.lnP1Real();
}

fn lnP1Cplx() callconv(.c) void {
    transcendental_command_owned.lnP1Cplx();
}

pub export fn logxyReal(denom: *const runtime.real_t) callconv(.c) void {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &a)) {
        return;
    }

    if (runtime.realIsZero(&a)) {
        if (!runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            return;
        }

        copyReal(&a, runtime.z47_math_wrappers_const_minus_infinity());
    } else if (runtime.realIsInfinite(&a)) {
        if (!runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            return;
        }

        if (runtime.getFlag(@intCast(runtime.FLAG_CPXRES))) {
            if (!runtime.realIsNegative(&a)) {
                copyReal(&a, runtime.z47_math_wrappers_const_plus_infinity());
            } else {
                runtime.realDivide(runtime.z47_math_wrappers_const_pi(), denom, &a, &runtime.ctxtReal39);
                runtime.convertComplexToResultRegister(runtime.z47_math_wrappers_const_plus_infinity(), &a, runtime.REGISTER_X);
                return;
            }
        } else {
            runtime.realSetNaN(&a);
        }
    } else if (!runtime.realIsNegative(&a)) {
        lnRealValue(&a, &a, &runtime.ctxtReal39);
        runtime.realDivide(&a, denom, &a, &runtime.ctxtReal39);
    } else if (runtime.getFlag(@intCast(runtime.FLAG_CPXRES))) {
        runtime.realSetPositiveSign(&a);
        lnRealValue(&a, &a, &runtime.ctxtReal39);
        runtime.realDivide(&a, denom, &a, &runtime.ctxtReal39);
        runtime.realDivide(runtime.z47_math_wrappers_const_pi(), denom, &b, &runtime.ctxtReal39);
        runtime.convertComplexToResultRegister(&a, &b, runtime.REGISTER_X);
        return;
    } else if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.realSetNaN(&a);
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        return;
    }

    runtime.convertRealToResultRegister(&a, runtime.REGISTER_X, runtime.amNone);
}

pub export fn logxyCplx(denom: *const runtime.real_t) callconv(.c) void {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &a, &b)) {
        return;
    }

    if (runtime.realIsZero(&a) and runtime.realIsZero(&b)) {
        if (!runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            return;
        }

        copyReal(&a, runtime.z47_math_wrappers_const_minus_infinity());
        runtime.realSetZero(&b);
    } else {
        runtime.realRectangularToPolar(&a, &b, &a, &b, &runtime.ctxtReal39);
        lnRealValue(&a, &a, &runtime.ctxtReal39);
        runtime.realDivide(&a, denom, &a, &runtime.ctxtReal39);
        runtime.realDivide(&b, denom, &b, &runtime.ctxtReal39);
    }

    runtime.convertComplexToResultRegister(&a, &b, runtime.REGISTER_X);
}

pub export fn logxyLonI(denom: *const runtime.real_t) callconv(.c) void {
    var x: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsNegative(&x) or runtime.realIsZero(&x)) {
        logxyReal(denom);
        return;
    }

    lnRealValue(&x, &x, &runtime.ctxtReal39);
    runtime.realDivide(&x, denom, &x, &runtime.ctxtReal34);
    if (!runtime.realIsAnInteger(&x)) {
        runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
    } else {
        runtime.convertRealToLongIntegerRegister(&x, runtime.REGISTER_X, runtime.DEC_ROUND_HALF_EVEN);
    }
}

fn sqrtComplexLocal(
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    res_real: *runtime.real_t,
    res_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;

    copyReal(&a, real);
    copyReal(&b, imag);

    if (runtime.realIsZero(&b)) {
        if (runtime.realIsNegative(&a)) {
            negateReal(res_imag, &a);
            runtime.realSquareRoot(res_imag, res_imag, real_context);
            runtime.realSetZero(res_real);
        } else {
            runtime.realSquareRoot(&a, res_real, real_context);
            runtime.realSetZero(res_imag);
        }
        return;
    }

    runtime.realRectangularToPolar(&a, &b, res_real, res_imag, real_context);
    runtime.realSquareRoot(res_real, res_real, real_context);
    runtime.realMultiply(res_imag, runtime.z47_math_wrappers_const_1on2(), res_imag, real_context);
    runtime.realPolarToRectangular(res_real, res_imag, res_real, res_imag, real_context);
}

pub export fn sqrt1Px2Complex(
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    res_real: *runtime.real_t,
    res_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    var x: runtime.real_t = undefined;
    var y: runtime.real_t = undefined;

    if (runtime.realIsZero(imag)) {
        if (runtime.realIsInfinite(real)) {
            copyReal(res_real, runtime.z47_math_wrappers_const_plus_infinity());
            runtime.realSetZero(res_imag);
            return;
        }

        runtime.realFMA(real, real, runtime.z47_math_wrappers_const_1(), res_real, real_context);
        runtime.realSquareRoot(res_real, res_real, real_context);
        runtime.realSetZero(res_imag);
        return;
    }

    if (runtime.realIsSpecial(real) or runtime.realIsSpecial(imag)) {
        runtime.realSetNaN(res_real);
        runtime.realSetNaN(res_imag);
        return;
    }

    runtime.realFMA(imag, imag, runtime.z47_math_wrappers_const_minus_1(), &x, real_context);
    runtime.realChangeSign(&x);
    runtime.realFMA(real, real, &x, &x, real_context);
    runtime.realMultiply(real, imag, &y, real_context);
    runtime.realAdd(&y, &y, &y, real_context);
    sqrtComplexLocal(&x, &y, res_real, res_imag, real_context);
}

fn sqrt1Px2Real() callconv(.c) void {
    var x: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsInfinite(&x) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        return;
    }

    if (runtime.realIsInfinite(&x)) {
        copyReal(&x, runtime.z47_math_wrappers_const_plus_infinity());
    } else if (runtime.realIsSpecial(&x)) {
        runtime.realSetNaN(&x);
    } else {
        runtime.realFMA(&x, &x, runtime.z47_math_wrappers_const_1(), &x, &runtime.ctxtReal51);
        runtime.realSquareRoot(&x, &x, &runtime.ctxtReal51);
    }

    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
}

fn sqrt1Px2Cplx() callconv(.c) void {
    var z_real: runtime.real_t = undefined;
    var z_imag: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &z_real, &z_imag)) {
        return;
    }

    sqrt1Px2Complex(&z_real, &z_imag, &z_real, &z_imag, &runtime.ctxtReal75);
    runtime.convertComplexToResultRegister(&z_real, &z_imag, runtime.REGISTER_X);
}

fn m1PowLonI() callconv(.c) void {
    var result: runtime.longInteger_t = undefined;
    var exponent: runtime.longInteger_t = undefined;

    runtime.__gmpz_init(&result[0]);
    defer runtime.__gmpz_clear(&result[0]);
    runtime.__gmpz_set_ui(&result[0], 1);

    runtime.convertLongIntegerRegisterToLongInteger(runtime.REGISTER_X, &exponent[0]);
    defer runtime.__gmpz_clear(&exponent[0]);

    if (exponent[0]._mp_size != 0 and (exponent[0]._mp_d[0] & 1) != 0) {
        result[0]._mp_size = -result[0]._mp_size;
    }

    runtime.convertLongIntegerToLongIntegerRegister(&result[0], runtime.REGISTER_X);
}

fn m1PowShoI() callconv(.c) void {
    var sign_exponent: i32 = undefined;
    const exponent_value = runtime.WP34S_extract_value(
        runtime.registerShortIntegerPtr(runtime.REGISTER_X).*,
        &sign_exponent,
    );
    const odd: i32 = @intCast(exponent_value & 1);

    if (runtime.shortIntegerMode == runtime.SIM_UNSIGN and odd != 0) {
        runtime.setSystemFlag(runtime.FLAG_OVERFLOW);
    } else {
        runtime.clearSystemFlag(runtime.FLAG_OVERFLOW);
    }

    runtime.registerShortIntegerPtr(runtime.REGISTER_X).* = runtime.WP34S_build_value(1, odd);
}

fn m1PowReal() callconv(.c) void {
    var x: runtime.real_t = undefined;
    var y: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsInfinite(&x) or runtime.realIsNaN(&x)) {
        runtime.realSetNaN(&x);
        runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
        return;
    }

    runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.amNone);
    runtime.WP34S_Mod(&x, runtime.z47_math_wrappers_const_2(), &x, &runtime.ctxtReal39);
    if (runtime.realIsZero(&x)) {
        runtime.convertRealToResultRegister(runtime.z47_math_wrappers_const_1(), runtime.REGISTER_X, runtime.amNone);
    } else if (runtime.realCompareEqual(&x, runtime.z47_math_wrappers_const_1())) {
        runtime.convertRealToResultRegister(runtime.z47_math_wrappers_const_minus_1(), runtime.REGISTER_X, runtime.amNone);
    } else {
        runtime.fnSetFlag(runtime.FLAG_CPXRES);
        runtime.fnRefreshState();

        runtime.realMultiply(&x, runtime.z47_math_wrappers_const_pi(), &x, &runtime.ctxtReal75);
        eulersFormula(&x, runtime.z47_math_wrappers_const_0(), &x, &y, &runtime.ctxtReal39);

        runtime.convertComplexToResultRegister(&x, &y, runtime.REGISTER_X);
    }
}

fn m1PowCplx() callconv(.c) void {
    var z_real: runtime.real_t = undefined;
    var z_imag: runtime.real_t = undefined;

    runtime.fnSetFlag(runtime.FLAG_CPXRES);
    runtime.fnRefreshState();
    runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.amNone);

    _ = runtime.decimal128ToNumber(runtime.registerReal34Ptr(runtime.REGISTER_X), &z_real);
    runtime.WP34S_Mod(&z_real, runtime.z47_math_wrappers_const_2(), &z_real, &runtime.ctxtReal39);

    _ = runtime.decimal128ToNumber(runtime.registerImag34Ptr(runtime.REGISTER_X), &z_imag);
    if (runtime.realIsZero(&z_imag)) {
        if (runtime.realIsZero(&z_real)) {
            runtime.convertComplexToResultRegister(
                runtime.z47_math_wrappers_const_1(),
                runtime.z47_math_wrappers_const_0(),
                runtime.REGISTER_X,
            );
            return;
        }

        if (runtime.realCompareEqual(&z_real, runtime.z47_math_wrappers_const_1())) {
            runtime.convertComplexToResultRegister(
                runtime.z47_math_wrappers_const_minus_1(),
                runtime.z47_math_wrappers_const_0(),
                runtime.REGISTER_X,
            );
            return;
        }
    }

    runtime.mulComplexReal(
        &z_real,
        &z_imag,
        runtime.z47_math_wrappers_const_pi(),
        &z_real,
        &z_imag,
        &runtime.ctxtReal75,
    );
    eulersFormula(&z_real, &z_imag, &z_real, &z_imag, &runtime.ctxtReal75);

    runtime.convertComplexToResultRegister(&z_real, &z_imag, runtime.REGISTER_X);
}

pub export fn eulersFormula(
    in_real: *const runtime.real_t,
    in_imag: *const runtime.real_t,
    out_real: *runtime.real_t,
    out_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    var z_real: runtime.real_t = undefined;
    var z_imag: runtime.real_t = undefined;

    runtime.mulComplexi(in_real, in_imag, &z_real, &z_imag);
    expComplex(&z_real, &z_imag, out_real, out_imag, real_context);
}

fn finishEulersFormula(real: *const runtime.real_t, imag: *const runtime.real_t) void {
    runtime.convertComplexToResultRegister(real, imag, runtime.REGISTER_X);
    runtime.fnSetFlag(runtime.FLAG_CPXRES);
    runtime.fnRefreshState();
}

fn eulersFormulaCplx() callconv(.c) void {
    var z_real: runtime.real_t = undefined;
    var z_imag: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &z_real, &z_imag)) {
        return;
    }

    if (runtime.realIsInfinite(&z_real) or runtime.realIsInfinite(&z_imag)) {
        if (!runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.z47_math_wrappers_report_eulers_formula_complex_domain_error();
            return;
        }

        runtime.realSetNaN(&z_real);
        runtime.realSetNaN(&z_imag);
        finishEulersFormula(&z_real, &z_imag);
        return;
    }

    eulersFormula(&z_real, &z_imag, &z_real, &z_imag, &runtime.ctxtReal39);
    finishEulersFormula(&z_real, &z_imag);
}

fn eulersFormulaReal() callconv(.c) void {
    var c: runtime.real_t = undefined;
    var i: runtime.real_t = undefined;
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &c)) {
        return;
    }

    if (runtime.realIsInfinite(&c) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.z47_math_wrappers_report_eulers_formula_real_domain_error();
        return;
    }

    if (register_data_type == runtime.dtReal34) {
        const x_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_X);
        if (x_angular_mode != runtime.amNone) {
            runtime.convertAngleFromTo(&c, x_angular_mode, runtime.amRadian, &runtime.ctxtReal39);
        }
    }

    eulersFormula(&c, runtime.z47_math_wrappers_const_0(), &c, &i, &runtime.ctxtReal39);
    finishEulersFormula(&c, &i);
}

fn realMatrixElementCount(matrix: *const runtime.real34Matrix_t) usize {
    return @as(usize, matrix.header.matrixRows) * @as(usize, matrix.header.matrixColumns);
}

fn complexMatrixElementCount(matrix: *const runtime.complex34Matrix_t) usize {
    return @as(usize, matrix.header.matrixRows) * @as(usize, matrix.header.matrixColumns);
}

fn realMatrixElementPtr(matrix: *runtime.real34Matrix_t, index: usize) *runtime.real34_t {
    if (build_options.use_fake_wp34s_model) {
        return &matrix.matrixElements[index];
    }

    return &@as([*]runtime.real34_t, @ptrCast(matrix.matrixElements))[index];
}

fn complexMatrixElementPtr(matrix: *runtime.complex34Matrix_t, index: usize) *runtime.complex34_t {
    if (build_options.use_fake_wp34s_model) {
        return &matrix.matrixElements[index];
    }

    return &@as([*]runtime.complex34_t, @ptrCast(matrix.matrixElements))[index];
}

fn complexMatrixRealPtr(matrix: *runtime.complex34Matrix_t, index: usize) *runtime.real34_t {
    return &complexMatrixElementPtr(matrix, index).real;
}

fn complexMatrixImagPtr(matrix: *runtime.complex34Matrix_t, index: usize) *runtime.real34_t {
    return &complexMatrixElementPtr(matrix, index).imag;
}

fn getExponent(result: *i32) bool {
    var x_value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value)) {
        return false;
    }

    if (runtime.realIsNaN(&x_value)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function getExponent:", "cannot use NaN as X input of EXPT", null, null);
        return false;
    }

    if (runtime.realIsInfinite(&x_value)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function getExponent:", "cannot use +/-inf as an input of EXPT", null, null);
        return false;
    }

    result.* = if (runtime.realIsZero(&x_value)) 0 else x_value.exponent + x_value.digits - 1;
    return true;
}

fn exptReal() callconv(.c) void {
    var exponent: i32 = undefined;
    var x_value: runtime.real_t = undefined;

    if (!getExponent(&exponent)) {
        return;
    }

    runtime.int32ToReal(exponent, &x_value);
    runtime.convertRealToResultRegister(&x_value, runtime.REGISTER_X, runtime.amNone);
}

fn exptLonI() callconv(.c) void {
    var exponent: i32 = undefined;

    if (!getExponent(&exponent)) {
        return;
    }

    runtime.z47_math_wrappers_build_sign_result(exponent);
}

fn bnCommon(bnstar: bool) void {
    var x_value: runtime.real_t = undefined;
    var result: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value)) {
        return;
    }

    if (!runtime.saveLastX()) {
        return;
    }

    runtime.WP34S_Bernoulli(&x_value, &result, bnstar, &runtime.ctxtReal39);
    if (runtime.realIsNaN(&result)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function fnBn:", if (bnstar) "k must be a non-negative integer" else "k must be a positive integer", null, null);
    } else {
        runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
        runtime.convertRealToReal34ResultRegister(&result, runtime.REGISTER_X);
    }

    runtime.adjustResult(runtime.REGISTER_X, false, true, runtime.REGISTER_X, no_register, no_register);
}

fn mantLonI() void {
    var x_value: runtime.real_t = undefined;

    runtime.convertLongIntegerRegisterToReal(runtime.REGISTER_X, &x_value, &runtime.ctxtReal39);
    x_value.exponent = 1 - x_value.digits;
    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
    runtime.convertRealToReal34ResultRegister(&x_value, runtime.REGISTER_X);
}

fn mantReal() void {
    if (runtime.real34IsNaN(runtime.registerReal34Ptr(runtime.REGISTER_X))) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function mantReal:", "cannot use NaN as X input of MANT", null, null);
        return;
    }

    var result: runtime.real_t = undefined;
    _ = runtime.decimal128ToNumber(runtime.registerReal34Ptr(runtime.REGISTER_X), &result);
    result.exponent = 1 - result.digits;
    runtime.convertRealToReal34ResultRegister(&result, runtime.REGISTER_X);
    runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.amNone);
}

fn roundiReal() callconv(.c) void {
    if (runtime.real34IsNaN(runtime.registerReal34Ptr(runtime.REGISTER_X))) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function roundiReal:", "cannot use NaN as X input of ROUNDI", null, null);
        return;
    }

    if (runtime.real34IsInfinite(runtime.registerReal34Ptr(runtime.REGISTER_X))) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function roundiReal:", "cannot use +/-inf as an input of ROUNDI", null, null);
        return;
    }

    const exponent = runtime.real34GetExponent(runtime.registerReal34Ptr(runtime.REGISTER_X));
    if (exponent > 1001) {
        const error_code = if (runtime.decQuadIsNegative(runtime.registerReal34Ptr(runtime.REGISTER_X)) == 0)
            runtime.ERROR_OVERFLOW_PLUS_INF
        else
            runtime.ERROR_OVERFLOW_MINUS_INF;
        runtime.displayCalcErrorMessage(error_code, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function roundiReal:", "real exponent exceeds long-integer range", null, null);
        return;
    }

    runtime.convertReal34ToLongIntegerRegister(runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.REGISTER_X, runtime.DEC_ROUND_HALF_UP);
}

fn ulpLongInteger() void {
    runtime.z47_math_wrappers_build_sign_result(1);
}

fn ulpShortInteger() void {
    runtime.convertUInt64ToShortIntegerRegister(0, 1, runtime.getRegisterTag(runtime.REGISTER_X), runtime.REGISTER_X);
}

fn ulpReal() void {
    var next_value: runtime.real34_t = undefined;

    if (runtime.real34IsInfinite(runtime.registerReal34Ptr(runtime.REGISTER_X))) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function fnUlp:", "cannot use +/-inf input of ULP", null, null);
    }

    runtime.real34NextPlus(runtime.registerReal34Ptr(runtime.REGISTER_X), &next_value);
    if (runtime.real34IsInfinite(&next_value)) {
        runtime.real34NextMinus(runtime.registerReal34Ptr(runtime.REGISTER_X), &next_value);
        runtime.real34Subtract(runtime.registerReal34Ptr(runtime.REGISTER_X), &next_value, runtime.registerReal34Ptr(runtime.REGISTER_X));
    } else {
        runtime.real34Subtract(&next_value, runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.registerReal34Ptr(runtime.REGISTER_X));
    }

    runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.amNone);
}

fn realCompareGreaterEqual(lhs: *const runtime.real_t, rhs: *const runtime.real_t) bool {
    return !runtime.realCompareLessThan(lhs, rhs);
}

fn realCompareLessEqual(lhs: *const runtime.real_t, rhs: *const runtime.real_t) bool {
    return !runtime.realCompareLessThan(rhs, lhs);
}

fn realCompareGreaterThan(lhs: *const runtime.real_t, rhs: *const runtime.real_t) bool {
    return runtime.realCompareLessThan(rhs, lhs);
}

fn factReal() callconv(.c) void {
    var x_value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value)) {
        return;
    }

    runtime.WP34S_Factorial(&x_value, &x_value, &runtime.ctxtReal39);
    runtime.convertRealToResultRegister(&x_value, runtime.REGISTER_X, runtime.amNone);
}

fn factCplx() callconv(.c) void {
    var real_value: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &real_value, &imag_value)) {
        return;
    }

    runtime.realAdd(&real_value, runtime.z47_math_wrappers_const_1(), &real_value, &runtime.ctxtReal39);
    runtime.WP34S_ComplexGamma(&real_value, &imag_value, &real_value, &imag_value, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&real_value, &imag_value, runtime.REGISTER_X);
}

fn factShoI() callconv(.c) void {
    var sign: i16 = 0;
    var value: u64 = 0;

    runtime.convertShortIntegerRegisterToUInt64(runtime.REGISTER_X, &sign, &value);

    if (sign == 1) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function factShoI:", "cannot calculate factorial(short integer)", null, null);
        return;
    }

    if (value > 20) {
        runtime.displayCalcErrorMessage(runtime.ERROR_OUT_OF_RANGE, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function factShoI:", "cannot calculate factorial(short integer)", null, null);
        return;
    }

    var result: u64 = 1;
    var remaining = value;

    if (remaining > 1) {
        var multiplier = remaining;
        if ((remaining & 1) != 0) {
            multiplier += remaining;
            remaining -= 1;
        }
        result = multiplier;
        remaining -= 2;
        while (remaining > 0) : (remaining -= 2) {
            multiplier += remaining;
            result *= multiplier;
        }
    }

    if (result > runtime.shortIntegerMask) {
        runtime.setSystemFlag(runtime.FLAG_OVERFLOW);
    }

    runtime.convertUInt64ToShortIntegerRegister(0, result, runtime.getRegisterTag(runtime.REGISTER_X), runtime.REGISTER_X);
}

fn factLonI() callconv(.c) void {
    const max_factorial: u32 = 450;

    var value: runtime.longInteger_t = undefined;
    runtime.convertLongIntegerRegisterToLongInteger(runtime.REGISTER_X, &value[0]);
    defer runtime.__gmpz_clear(&value[0]);

    if (value[0]._mp_size < 0) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function factLonI:", "cannot calculate factorial(long integer)", null, null);
        return;
    }

    if (runtime.__gmpz_cmp_ui(&value[0], max_factorial) > 0) {
        runtime.convertLongIntegerRegisterToReal34Register(runtime.REGISTER_X, runtime.REGISTER_X);
        factReal();
        return;
    }

    const n: u32 = @intCast(runtime.__gmpz_get_ui(&value[0]));
    var result: runtime.longInteger_t = undefined;
    runtime.__gmpz_init(&result[0]);
    defer runtime.__gmpz_clear(&result[0]);
    runtime.__gmpz_set_ui(&result[0], 1);

    var multiplier: u32 = 2;
    while (multiplier <= n) : (multiplier += 1) {
        runtime.__gmpz_mul_ui(&result[0], &result[0], multiplier);
    }

    runtime.convertLongIntegerToLongIntegerRegister(&result[0], runtime.REGISTER_X);
}

fn modReal() callconv(.c) void {
    var x_value: runtime.real_t = undefined;
    var y_value: runtime.real_t = undefined;
    var result: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value) or !runtime.getRegisterAsReal(runtime.REGISTER_Y, &y_value)) {
        return;
    }

    if (runtime.realIsZero(&x_value)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function modReal:", "cannot IDIVR a real34 by 0", null, null);
        return;
    }

    runtime.WP34S_BigMod(&y_value, &x_value, &result, &runtime.ctxtReal39);
    if (!runtime.realIsZero(&result) and (runtime.realIsNegative(&y_value) != runtime.realIsNegative(&x_value))) {
        runtime.realAdd(&result, &x_value, &result, &runtime.ctxtReal39);
    }

    runtime.convertRealToResultRegister(&result, runtime.REGISTER_X, runtime.amNone);
}

fn rmdReal() callconv(.c) void {
    var x_value: runtime.real_t = undefined;
    var y_value: runtime.real_t = undefined;
    var result: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value) or !runtime.getRegisterAsReal(runtime.REGISTER_Y, &y_value)) {
        return;
    }

    if (runtime.realIsZero(&x_value)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function rmdReal:", "cannot IDIVR a real34 by 0", null, null);
        return;
    }

    runtime.WP34S_BigMod(&y_value, &x_value, &result, &runtime.ctxtReal39);
    runtime.convertRealToResultRegister(&result, runtime.REGISTER_X, runtime.amNone);
}

fn neighbReal() callconv(.c) void {
    var x_value: runtime.real_t = undefined;
    var y_value: runtime.real_t = undefined;
    var x_angular_mode = runtime.amNone;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value) or !runtime.getRegisterAsReal(runtime.REGISTER_Y, &y_value)) {
        return;
    }

    if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtReal34) {
        x_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_X);
    }

    runtime.realNextToward(&x_value, &y_value, &x_value, &runtime.ctxtReal34);
    runtime.convertRealToResultRegister(&x_value, runtime.REGISTER_X, x_angular_mode);
}

pub export fn integerPartNoOp() callconv(.c) void {
    integer_part_owned.integerPartNoOp();
}

pub export fn integerPartReal(mode: runtime.rounding_t) callconv(.c) void {
    integer_part_owned.integerPartReal(mode);
}

pub export fn integerPartCplx(mode: runtime.rounding_t) callconv(.c) void {
    integer_part_owned.integerPartCplx(mode);
}

pub export fn ArcsinComplex(
    x_real: *const runtime.real_t,
    x_imag: *const runtime.real_t,
    r_real: *runtime.real_t,
    r_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) u8 {
    return inverse_trig_command_owned.ArcsinComplex(x_real, x_imag, r_real, r_imag, real_context);
}

pub export fn ArctanComplex(
    x_real: *runtime.real_t,
    x_imag: *runtime.real_t,
    r_real: *runtime.real_t,
    r_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) u8 {
    return inverse_trig_command_owned.ArctanComplex(x_real, x_imag, r_real, r_imag, real_context);
}

pub export fn ArcsinhReal(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) u8 {
    return inverse_trig_command_owned.ArcsinhReal(x, res, real_context);
}

pub export fn ArcsinhComplex(
    x_real: *const runtime.real_t,
    x_imag: *const runtime.real_t,
    r_real: *runtime.real_t,
    r_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) u8 {
    return inverse_trig_command_owned.ArcsinhComplex(x_real, x_imag, r_real, r_imag, real_context);
}

pub export fn realArcosh(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    inverse_trig_command_owned.realArcosh(x, res, real_context);
}

fn expReal() callconv(.c) void {
    transcendental_command_owned.expReal();
}

fn expCplx() callconv(.c) void {
    transcendental_command_owned.expCplx();
}

fn invertReal() callconv(.c) void {
    var x: runtime.real_t = undefined;
    var result: *const runtime.real_t = &x;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsZero(&x)) {
        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            result = if (runtime.realIsNegative(&x))
                runtime.z47_math_wrappers_const_minus_infinity()
            else
                runtime.z47_math_wrappers_const_plus_infinity();
        } else {
            runtime.z47_math_wrappers_report_invert_real_divide_by_zero_error();
            return;
        }
    } else if (runtime.realIsInfinite(&x)) {
        const set_negative_zero = runtime.realIsNegative(&x) and runtime.getSystemFlag(runtime.FLAG_SPCRES);

        runtime.realSetZero(&x);
        if (set_negative_zero) {
            runtime.realChangeSign(&x);
        }
    } else if (runtime.realCompareAbsEqual(&x, runtime.z47_math_wrappers_const_1())) {
        return;
    } else {
        runtime.realDivide(runtime.z47_math_wrappers_const_1(), &x, &x, &runtime.ctxtReal39);
    }

    runtime.convertRealToResultRegister(result, runtime.REGISTER_X, runtime.amNone);
}

fn invertCplx() callconv(.c) void {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &a, &b)) {
        return;
    }

    runtime.divRealComplex(runtime.z47_math_wrappers_const_1(), &a, &b, &a, &b, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&a, &b, runtime.REGISTER_X);
}

fn signReal() callconv(.c) void {
    const x = runtime.registerReal34Ptr(runtime.REGISTER_X);

    if (runtime.real34IsNaN(x)) {
        runtime.z47_math_wrappers_report_sign_real_nan_error();
        return;
    }

    runtime.z47_math_wrappers_build_sign_result(
        if (runtime.real34IsZero(x))
            0
        else if (runtime.real34IsNegative(x))
            -1
        else
            1,
    );
}

fn signCplx() callconv(.c) void {
    runtime.unitVectorCplx();
}

fn signShoI() callconv(.c) void {
    var sign_value: i32 = 0;
    const value = runtime.WP34S_extract_value(runtime.registerShortIntegerPtr(runtime.REGISTER_X).*, &sign_value);

    runtime.z47_math_wrappers_build_sign_result(
        if (value == 0)
            0
        else
            2 * -sign_value + 1,
    );
}

fn signLonI() callconv(.c) void {
    const sign_result: i32 = switch (runtime.getRegisterLongIntegerSign(runtime.REGISTER_X)) {
        runtime.LI_ZERO => 0,
        runtime.LI_NEGATIVE => -1,
        runtime.LI_POSITIVE => 1,
        else => unreachable,
    };

    runtime.z47_math_wrappers_build_sign_result(sign_result);
}

fn chsZeroCheck(value: *runtime.real_t) void {
    runtime.realChangeSign(value);
    if (runtime.realIsZero(value) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.realSetPositiveSign(value);
    }
}

pub export fn chsReal() callconv(.c) void {
    var x: runtime.real_t = undefined;
    var mode = runtime.amNone;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtReal34) {
        mode = runtime.getRegisterAngularMode(runtime.REGISTER_X);
    }

    chsZeroCheck(&x);
    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, mode);
}

pub export fn chsCplx() callconv(.c) void {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &a, &b)) {
        return;
    }

    chsZeroCheck(&a);
    chsZeroCheck(&b);
    runtime.convertComplexToResultRegister(&a, &b, runtime.REGISTER_X);
}

pub export fn chsShoI() callconv(.c) void {
    runtime.registerShortIntegerPtr(runtime.REGISTER_X).* = runtime.WP34S_intChs(runtime.registerShortIntegerPtr(runtime.REGISTER_X).*);
}

fn chsLonI() callconv(.c) void {
    var x: runtime.longInteger_t = undefined;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &x[0], null)) {
        return;
    }
    defer runtime.__gmpz_clear(&x[0]);

    x[0]._mp_size = -x[0]._mp_size;
    runtime.convertLongIntegerToLongIntegerRegister(&x[0], runtime.REGISTER_X);
}

fn changeSignTime() void {
    const x = runtime.registerReal34Ptr(runtime.REGISTER_X);
    x.bytes[15] ^= runtime.DECNEG;

    if (runtime.real34IsZero(x) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        x.bytes[15] &= 0x7f;
    }
}

fn erfReal() callconv(.c) void {
    var x: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    runtime.WP34S_Erf(&x, &x, &runtime.ctxtReal39);
    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
}

fn erfcReal() callconv(.c) void {
    var x: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    runtime.WP34S_Erfc(&x, &x, &runtime.ctxtReal39);
    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
}

pub export fn fnRandom(unused_but_mandatory_parameter: u16) callconv(.c) void {
    random_command_owned.random(unused_but_mandatory_parameter);
}

pub export fn fnRandomI(unused_but_mandatory_parameter: u16) callconv(.c) void {
    random_command_owned.randomI(unused_but_mandatory_parameter);
}

pub export fn fnSeed(unused_but_mandatory_parameter: u16) callconv(.c) void {
    random_command_owned.seed(unused_but_mandatory_parameter);
}

pub export fn fnMin(unused_but_mandatory_parameter: u16) callconv(.c) void {
    integer_part_owned.min(unused_but_mandatory_parameter);
}

pub export fn fnMax(unused_but_mandatory_parameter: u16) callconv(.c) void {
    integer_part_owned.max(unused_but_mandatory_parameter);
}

pub export fn fnCeil(unused_but_mandatory_parameter: u16) callconv(.c) void {
    integer_part_owned.ceil(unused_but_mandatory_parameter);
}

pub export fn fnFloor(unused_but_mandatory_parameter: u16) callconv(.c) void {
    integer_part_owned.floor(unused_but_mandatory_parameter);
}

pub export fn fnIp(unused_but_mandatory_parameter: u16) callconv(.c) void {
    integer_part_owned.ip(unused_but_mandatory_parameter);
}

pub export fn fnLint(unused_but_mandatory_parameter: u16) callconv(.c) void {
    integer_part_owned.lint(unused_but_mandatory_parameter);
}

pub export fn fnSint(unused_but_mandatory_parameter: u16) callconv(.c) void {
    integer_part_owned.sint(unused_but_mandatory_parameter);
}

pub export fn fnFp(unused_but_mandatory_parameter: u16) callconv(.c) void {
    integer_part_owned.fp(unused_but_mandatory_parameter);
}

pub export fn fnSinc(unused_but_mandatory_parameter: u16) callconv(.c) void {
    sinc_command_owned.fnSinc(unused_but_mandatory_parameter);
}

pub export fn fnSincpi(unused_but_mandatory_parameter: u16) callconv(.c) void {
    sinc_command_owned.fnSincpi(unused_but_mandatory_parameter);
}

pub export fn fnSin(unused_but_mandatory_parameter: u16) callconv(.c) void {
    circular_trig_command_owned.fnSin(unused_but_mandatory_parameter);
}

pub export fn fnCos(unused_but_mandatory_parameter: u16) callconv(.c) void {
    circular_trig_command_owned.fnCos(unused_but_mandatory_parameter);
}

pub export fn fnTan(unused_but_mandatory_parameter: u16) callconv(.c) void {
    circular_trig_command_owned.fnTan(unused_but_mandatory_parameter);
}

pub export fn fnArcsin(unused_but_mandatory_parameter: u16) callconv(.c) void {
    inverse_trig_command_owned.fnArcsin(unused_but_mandatory_parameter);
}

pub export fn fnArccos(unused_but_mandatory_parameter: u16) callconv(.c) void {
    inverse_trig_command_owned.fnArccos(unused_but_mandatory_parameter);
}

pub export fn fnArctan(unused_but_mandatory_parameter: u16) callconv(.c) void {
    inverse_trig_command_owned.fnArctan(unused_but_mandatory_parameter);
}

pub export fn fnArcsinh(unused_but_mandatory_parameter: u16) callconv(.c) void {
    inverse_trig_command_owned.fnArcsinh(unused_but_mandatory_parameter);
}

pub export fn fnArccosh(unused_but_mandatory_parameter: u16) callconv(.c) void {
    inverse_trig_command_owned.fnArccosh(unused_but_mandatory_parameter);
}

pub export fn fnArctanh(unused_but_mandatory_parameter: u16) callconv(.c) void {
    inverse_trig_command_owned.fnArctanh(unused_but_mandatory_parameter);
}

pub export fn fnSinh(unused_but_mandatory_parameter: u16) callconv(.c) void {
    circular_trig_command_owned.fnSinh(unused_but_mandatory_parameter);
}

pub export fn fnCosh(unused_but_mandatory_parameter: u16) callconv(.c) void {
    circular_trig_command_owned.fnCosh(unused_but_mandatory_parameter);
}

pub export fn fnTanh(unused_but_mandatory_parameter: u16) callconv(.c) void {
    circular_trig_command_owned.fnTanh(unused_but_mandatory_parameter);
}

pub export fn fnExp(unused_but_mandatory_parameter: u16) callconv(.c) void {
    transcendental_command_owned.exp(unused_but_mandatory_parameter);
}

pub export fn fnExpM1(unused_but_mandatory_parameter: u16) callconv(.c) void {
    transcendental_command_owned.expM1(unused_but_mandatory_parameter);
}

pub export fn fnLn(unused_but_mandatory_parameter: u16) callconv(.c) void {
    transcendental_command_owned.ln(unused_but_mandatory_parameter);
}

pub export fn fnLnP1(unused_but_mandatory_parameter: u16) callconv(.c) void {
    transcendental_command_owned.lnP1(unused_but_mandatory_parameter);
}

pub export fn fnSqrt1Px2(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&sqrt1Px2Real, &sqrt1Px2Cplx);
}

pub export fn fnErf(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&erfReal, null);
}

pub export fn fnErfc(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&erfcReal, null);
}

pub export fn fn2Pow(unused_but_mandatory_parameter: u16) callconv(.c) void {
    powlog_command_owned.fn2Pow(unused_but_mandatory_parameter);
}

pub export fn fn10Pow(unused_but_mandatory_parameter: u16) callconv(.c) void {
    powlog_command_owned.fn10Pow(unused_but_mandatory_parameter);
}

pub export fn fnLog10(unused_but_mandatory_parameter: u16) callconv(.c) void {
    powlog_command_owned.fnLog10(unused_but_mandatory_parameter);
}

pub export fn fnLog2(unused_but_mandatory_parameter: u16) callconv(.c) void {
    powlog_command_owned.fnLog2(unused_but_mandatory_parameter);
}

pub export fn fnM1Pow(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexMonadicFunction(&m1PowReal, &m1PowCplx, &m1PowShoI, &m1PowLonI);
}

pub export fn fnEulersFormula(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&eulersFormulaReal, &eulersFormulaCplx);
}

pub export fn fnInvert(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);

    if (register_data_type == runtime.dtReal34Matrix or register_data_type == runtime.dtComplex34Matrix) {
        runtime.fnInvertMatrix(0);
        return;
    }

    _ = unused_but_mandatory_parameter;
    runtime.processRealComplexMonadicFunction(&invertReal, &invertCplx);
}

pub export fn fnSign(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexMonadicFunction(&signReal, &signCplx, &signShoI, &signLonI);
}

pub export fn fnChangeSign(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtTime) {
        changeSignTime();
        return;
    }

    runtime.processIntRealComplexMonadicFunction(&chsReal, &chsCplx, &chsShoI, &chsLonI);
}

pub export fn fnSquare(unused_but_mandatory_parameter: u16) callconv(.c) void {
    transform_command_owned.square(unused_but_mandatory_parameter);
}

pub export fn fnCube(unused_but_mandatory_parameter: u16) callconv(.c) void {
    transform_command_owned.cube(unused_but_mandatory_parameter);
}

pub export fn fnBn(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    bnCommon(false);
}

pub export fn fnBnStar(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    bnCommon(true);
}

pub export fn fnExpt(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexMonadicFunction(&exptReal, null, null, &exptLonI);
}

pub export fn fnWpositive(unused_but_mandatory_parameter: u16) callconv(.c) void {
    lambertw_command_owned.fnWpositive(unused_but_mandatory_parameter);
}

pub export fn fnWnegative(unused_but_mandatory_parameter: u16) callconv(.c) void {
    lambertw_command_owned.fnWnegative(unused_but_mandatory_parameter);
}

pub export fn fnWinverse(unused_but_mandatory_parameter: u16) callconv(.c) void {
    lambertw_command_owned.fnWinverse(unused_but_mandatory_parameter);
}

fn gcdShoI() callconv(.c) void {
    runtime.registerShortIntegerPtr(runtime.REGISTER_X).* = runtime.WP34S_intGCD(
        runtime.registerShortIntegerPtr(runtime.REGISTER_Y).*,
        runtime.registerShortIntegerPtr(runtime.REGISTER_X).*,
    );
}

fn lcmShoI() callconv(.c) void {
    runtime.registerShortIntegerPtr(runtime.REGISTER_X).* = runtime.WP34S_intLCM(
        runtime.registerShortIntegerPtr(runtime.REGISTER_Y).*,
        runtime.registerShortIntegerPtr(runtime.REGISTER_X).*,
    );
}

fn neighbShoI() callconv(.c) void {
    var subtract = false;
    var negx = false;
    var negy = false;
    var x: u64 = 0;
    var y: u64 = 0;

    if (runtime.getRegisterAsShortInt(runtime.REGISTER_X, &negx, &x, null, null) and
        runtime.getRegisterAsShortInt(runtime.REGISTER_Y, &negy, &y, null, null))
    {
        if (negx != negy) {
            subtract = negy;
        } else if (x == y) {
            return;
        } else if (negx) {
            subtract = y > x;
        } else {
            subtract = y < x;
        }

        if (subtract) {
            runtime.registerShortIntegerPtr(runtime.REGISTER_X).* = runtime.WP34S_intSubtract(
                runtime.registerShortIntegerPtr(runtime.REGISTER_X).*,
                1,
            );
        } else {
            runtime.registerShortIntegerPtr(runtime.REGISTER_X).* = runtime.WP34S_intAdd(
                runtime.registerShortIntegerPtr(runtime.REGISTER_X).*,
                1,
            );
        }
    }
}

fn neighbLonI() callconv(.c) void {
    var x: runtime.longInteger_t = undefined;
    var y: runtime.longInteger_t = undefined;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &x[0], null)) {
        return;
    }
    defer runtime.__gmpz_clear(&x[0]);

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_Y, &y[0], null)) {
        return;
    }
    defer runtime.__gmpz_clear(&y[0]);

    const cmp = runtime.__gmpz_cmp(&y[0], &x[0]);

    if (cmp != 0) {
        runtime.__gmpz_set_si(&y[0], if (cmp > 0) 1 else -1);
        runtime.__gmpz_add(&x[0], &x[0], &y[0]);
    }

    runtime.convertLongIntegerToLongIntegerRegister(&x[0], runtime.REGISTER_X);
}

fn longIntegerSetPositiveSign(value: *runtime.mpz_struct) void {
    if (value._mp_size < 0) {
        value._mp_size = -value._mp_size;
    }
}

fn longIntegerSetNegativeSign(value: *runtime.mpz_struct) void {
    if (value._mp_size > 0) {
        value._mp_size = -value._mp_size;
    }
}

fn gcdInt() callconv(.c) void {
    var x: runtime.longInteger_t = undefined;
    var y: runtime.longInteger_t = undefined;
    var frac_x = false;
    var frac_y = false;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_Y, &y[0], &frac_y)) {
        return;
    }
    defer runtime.__gmpz_clear(&y[0]);

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &x[0], &frac_x)) {
        return;
    }
    defer runtime.__gmpz_clear(&x[0]);

    if (frac_x) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        return;
    }
    if (frac_y) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_Y);
        return;
    }

    longIntegerSetPositiveSign(&y[0]);
    longIntegerSetPositiveSign(&x[0]);

    if (y[0]._mp_size == 0 and x[0]._mp_size == 0) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function _longIntegerGcd:", "(0, 0) is not in the function domain.", null, null);
        return;
    }

    runtime.__gmpz_gcd(&x[0], &y[0], &x[0]);
    runtime.convertLongIntegerToLongIntegerRegister(&x[0], runtime.REGISTER_X);
}

fn lcmInt() callconv(.c) void {
    var x: runtime.longInteger_t = undefined;
    var y: runtime.longInteger_t = undefined;
    var frac_x = false;
    var frac_y = false;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_Y, &y[0], &frac_y)) {
        return;
    }
    defer runtime.__gmpz_clear(&y[0]);

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &x[0], &frac_x)) {
        return;
    }
    defer runtime.__gmpz_clear(&x[0]);

    if (frac_x) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        return;
    }
    if (frac_y) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_Y);
        return;
    }

    longIntegerSetPositiveSign(&y[0]);
    longIntegerSetPositiveSign(&x[0]);
    runtime.__gmpz_lcm(&x[0], &y[0], &x[0]);
    runtime.convertLongIntegerToLongIntegerRegister(&x[0], runtime.REGISTER_X);
}

fn rmdLonI() callconv(.c) void {
    var x: runtime.longInteger_t = undefined;
    var y: runtime.longInteger_t = undefined;
    var remainder: runtime.longInteger_t = undefined;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &x[0], null)) {
        return;
    }
    defer runtime.__gmpz_clear(&x[0]);

    if (x[0]._mp_size == 0) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function rmdLonI:", "cannot IDIVR a long integer by 0", null, null);
        return;
    }

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_Y, &y[0], null)) {
        return;
    }
    defer runtime.__gmpz_clear(&y[0]);

    runtime.__gmpz_init(&remainder[0]);
    defer runtime.__gmpz_clear(&remainder[0]);

    runtime.__gmpz_tdiv_r(&remainder[0], &y[0], &x[0]);
    runtime.convertLongIntegerToLongIntegerRegister(&remainder[0], runtime.REGISTER_X);
}

fn rmdShoI() callconv(.c) void {
    var x: runtime.longInteger_t = undefined;
    var y: runtime.longInteger_t = undefined;
    var remainder: runtime.longInteger_t = undefined;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &x[0], null)) {
        return;
    }
    defer runtime.__gmpz_clear(&x[0]);

    if (x[0]._mp_size == 0) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function rmdShoI:", "cannot IDIVR a short integer by 0", null, null);
        return;
    }

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_Y, &y[0], null)) {
        return;
    }
    defer runtime.__gmpz_clear(&y[0]);

    runtime.__gmpz_init(&remainder[0]);
    defer runtime.__gmpz_clear(&remainder[0]);

    runtime.__gmpz_tdiv_r(&remainder[0], &y[0], &x[0]);
    runtime.convertLongIntegerToShortIntegerRegister(&remainder[0], runtime.getRegisterTag(runtime.REGISTER_Y), runtime.REGISTER_X);
}

fn modLonI() callconv(.c) void {
    var x: runtime.longInteger_t = undefined;
    var y: runtime.longInteger_t = undefined;
    var remainder: runtime.longInteger_t = undefined;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &x[0], null)) {
        return;
    }
    defer runtime.__gmpz_clear(&x[0]);

    if (x[0]._mp_size == 0) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function modLonI:", "cannot IDIVR a long integer by 0", null, null);
        return;
    }

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_Y, &y[0], null)) {
        return;
    }
    defer runtime.__gmpz_clear(&y[0]);

    runtime.__gmpz_init(&remainder[0]);
    defer runtime.__gmpz_clear(&remainder[0]);

    runtime.__gmpz_tdiv_r(&remainder[0], &y[0], &x[0]);
    runtime.__gmpz_add(&remainder[0], &remainder[0], &x[0]);
    runtime.__gmpz_tdiv_r(&remainder[0], &remainder[0], &x[0]);
    runtime.convertLongIntegerToLongIntegerRegister(&remainder[0], runtime.REGISTER_X);
}

fn modShoI() callconv(.c) void {
    var x: runtime.longInteger_t = undefined;
    var y: runtime.longInteger_t = undefined;
    var remainder: runtime.longInteger_t = undefined;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &x[0], null)) {
        return;
    }
    defer runtime.__gmpz_clear(&x[0]);

    if (x[0]._mp_size == 0) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function modShoI:", "cannot IDIVR a short integer by 0", null, null);
        return;
    }

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_Y, &y[0], null)) {
        return;
    }
    defer runtime.__gmpz_clear(&y[0]);

    runtime.__gmpz_init(&remainder[0]);
    defer runtime.__gmpz_clear(&remainder[0]);

    runtime.__gmpz_tdiv_r(&remainder[0], &y[0], &x[0]);
    runtime.__gmpz_add(&remainder[0], &remainder[0], &x[0]);
    runtime.__gmpz_tdiv_r(&remainder[0], &remainder[0], &x[0]);
    runtime.convertLongIntegerToShortIntegerRegister(&remainder[0], runtime.getRegisterTag(runtime.REGISTER_Y), runtime.REGISTER_X);
}

pub export fn fnGcd(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processIntRealComplexDyadicFunction(&gcdInt, null, &gcdShoI, &gcdInt);
}

pub export fn fnLcm(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processIntRealComplexDyadicFunction(&lcmInt, null, &lcmShoI, &lcmInt);
}

pub export fn fnMod(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processIntRealComplexDyadicFunction(&modReal, null, &modShoI, &modLonI);
}

pub export fn fnRmd(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processIntRealComplexDyadicFunction(&rmdReal, null, &rmdShoI, &rmdLonI);
}

pub export fn fnUlp(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);

    _ = unused_but_mandatory_parameter;

    if (!runtime.saveLastX()) {
        return;
    }

    switch (register_data_type) {
        runtime.dtLongInteger => ulpLongInteger(),
        runtime.dtShortInteger => ulpShortInteger(),
        runtime.dtReal34 => ulpReal(),
        else => {
            runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            runtime.moreInfoOnError("In function fnUlp:", "cannot calculate ULP for current X type", null, null);
            return;
        },
    }

    runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, no_register, no_register);
}

pub export fn fnMant(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    if (!runtime.saveLastX()) {
        return;
    }

    switch (runtime.getRegisterDataType(runtime.REGISTER_X)) {
        runtime.dtLongInteger => mantLonI(),
        runtime.dtReal34 => mantReal(),
        else => {
            runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            runtime.moreInfoOnError("In function mantError:", "cannot calculate MANT for current X type", null, null);
        },
    }

    runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, no_register, no_register);
}

pub export fn fnRoundi(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    if (!runtime.saveLastX()) {
        return;
    }

    switch (runtime.getRegisterDataType(runtime.REGISTER_X)) {
        runtime.dtLongInteger, runtime.dtShortInteger => {},
        runtime.dtReal34 => roundiReal(),
        runtime.dtReal34Matrix => runtime.elementwiseRema(&roundiReal),
        else => {
            runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            runtime.moreInfoOnError("In function roundiError:", "cannot calculate ROUNDI for current X type", null, null);
        },
    }

    runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, no_register, no_register);
}

pub export fn fnNeighb(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processIntRealComplexDyadicFunction(&neighbReal, null, &neighbShoI, &neighbLonI);
}

pub export fn fnIxyz(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    var x_value: runtime.real_t = undefined;
    var a_value: runtime.real_t = undefined;
    var b_value: runtime.real_t = undefined;
    var result: runtime.real_t = undefined;

    if (!runtime.saveLastX()) {
        return;
    }

    if (runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value) and runtime.getRegisterAsReal(runtime.REGISTER_Y, &a_value) and runtime.getRegisterAsReal(runtime.REGISTER_Z, &b_value)) {
        if (realCompareGreaterEqual(&x_value, runtime.z47_math_wrappers_const_0()) and
            realCompareLessEqual(&x_value, runtime.z47_math_wrappers_const_1()) and
            realCompareGreaterThan(&a_value, runtime.z47_math_wrappers_const_0()) and
            realCompareGreaterThan(&b_value, runtime.z47_math_wrappers_const_0()))
        {
            runtime.WP34S_betai(&b_value, &a_value, &x_value, &result, &runtime.ctxtReal39);
            runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
            runtime.convertRealToReal34ResultRegister(&result, runtime.REGISTER_X);
            runtime.fnDropY(0);
            if (runtime.lastErrorCode == runtime.ERROR_NONE) {
                runtime.fnDropY(0);
            }
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            runtime.moreInfoOnError("In function fnIxyz:", "not in 0<=x<=1, a>0, b>0", null, null);
        }
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function fnIxyz:", "cannot calculate Ixyz for current X, Y, Z types", null, null);
    }

    runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, no_register, no_register);
}

pub export fn fnFactorial(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processIntRealComplexMonadicFunction(&factReal, &factCplx, &factShoI, &factLonI);
}

pub export fn fnRealPart(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    projection_owned.realPart();
}

pub export fn fnImaginaryPart(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    projection_owned.imaginaryPart();
}

pub export fn fnArg(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    projection_owned.arg();
}

pub export fn fnMagnitude(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    projection_owned.magnitude();
}

pub export fn fnConjugate(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    projection_owned.conjugate();
}

pub export fn fnSwapRealImaginary(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    projection_owned.swapRealImaginary();
}

pub export fn fnAtan2(unused_but_mandatory_parameter: u16) callconv(.c) void {
    atan2_command_owned.atan2(unused_but_mandatory_parameter);
}

pub export fn fnPercent(unused_but_mandatory_parameter: u16) callconv(.c) void {
    percent_command_owned.percent(unused_but_mandatory_parameter);
}

const dyadic_integer_add: u8 = 0;
const dyadic_integer_subtract: u8 = 1;
const dyadic_integer_multiply: u8 = 2;

fn shortIntegerData(reg: runtime.calcRegister_t) *align(1) u64 {
    return @as(*align(1) u64, @ptrCast(runtime.getRegisterDataPointer(reg).?));
}

fn applyDyadicRealOperation(operation: u8, lhs: *const runtime.real_t, rhs: *const runtime.real_t, result: *runtime.real_t) void {
    switch (operation) {
        dyadic_integer_add => runtime.realAdd(lhs, rhs, result, &runtime.ctxtReal39),
        dyadic_integer_subtract => runtime.realSubtract(lhs, rhs, result, &runtime.ctxtReal39),
        dyadic_integer_multiply => runtime.realMultiply(lhs, rhs, result, &runtime.ctxtReal39),
        else => unreachable,
    }
}

fn applyDyadicReal34Operation(operation: u8, lhs: *const runtime.real34_t, rhs: *const runtime.real34_t, result: *runtime.real34_t) void {
    switch (operation) {
        dyadic_integer_add => runtime.real34Add(lhs, rhs, result),
        dyadic_integer_subtract => runtime.real34Subtract(lhs, rhs, result),
        dyadic_integer_multiply => runtime.real34Multiply(lhs, rhs, result),
        else => unreachable,
    }
}

fn selectRemainingAddBranch(type_y: u32, type_x: u32) ?BranchFn {
    return switch (type_y) {
        runtime.dtLongInteger => switch (type_x) {
            runtime.dtTime => &runtime.addLonITime,
            runtime.dtDate => &runtime.addLonIDate,
            runtime.dtComplex34 => &runtime.addLonICplx,
            runtime.dtReal34Matrix => &runtime.addLonIRema,
            runtime.dtComplex34Matrix => &runtime.addLonICxma,
            else => null,
        },
        runtime.dtShortInteger => switch (type_x) {
            runtime.dtComplex34 => &runtime.addShoICplx,
            runtime.dtReal34Matrix => &runtime.addShoIRema,
            runtime.dtComplex34Matrix => &runtime.addShoICxma,
            else => null,
        },
        runtime.dtReal34 => switch (type_x) {
            runtime.dtTime => &runtime.addRealTime,
            runtime.dtDate => &runtime.addRealDate,
            runtime.dtComplex34 => &runtime.addRealCplx,
            runtime.dtReal34Matrix => &runtime.addRealRema,
            runtime.dtComplex34Matrix => &runtime.addRealCxma,
            else => null,
        },
        runtime.dtComplex34 => switch (type_x) {
            runtime.dtLongInteger => &runtime.addCplxLonI,
            runtime.dtShortInteger => &runtime.addCplxShoI,
            runtime.dtReal34 => &runtime.addCplxReal,
            runtime.dtComplex34 => &runtime.addCplxCplx,
            runtime.dtReal34Matrix => &runtime.addCplxRema,
            runtime.dtComplex34Matrix => &runtime.addCplxCxma,
            else => null,
        },
        runtime.dtTime => switch (type_x) {
            runtime.dtLongInteger => &runtime.addTimeLonI,
            runtime.dtTime => &runtime.addTimeTime,
            runtime.dtReal34 => &runtime.addTimeReal,
            else => null,
        },
        runtime.dtDate => switch (type_x) {
            runtime.dtLongInteger => &runtime.addDateLonI,
            runtime.dtReal34 => &runtime.addDateReal,
            else => null,
        },
        runtime.dtReal34Matrix => switch (type_x) {
            runtime.dtLongInteger => &runtime.addRemaLonI,
            runtime.dtShortInteger => &runtime.addRemaShoI,
            runtime.dtReal34 => &runtime.addRemaReal,
            runtime.dtComplex34 => &runtime.addRemaCplx,
            runtime.dtReal34Matrix => &runtime.addRemaRema,
            runtime.dtComplex34Matrix => &runtime.addRemaCxma,
            else => null,
        },
        runtime.dtComplex34Matrix => switch (type_x) {
            runtime.dtLongInteger => &runtime.addCxmaLonI,
            runtime.dtShortInteger => &runtime.addCxmaShoI,
            runtime.dtReal34 => &runtime.addCxmaReal,
            runtime.dtComplex34 => &runtime.addCxmaCplx,
            runtime.dtReal34Matrix => &runtime.addCxmaRema,
            runtime.dtComplex34Matrix => &runtime.addCxmaCxma,
            else => null,
        },
        else => null,
    };
}

fn selectRemainingSubtractBranch(type_y: u32, type_x: u32) ?BranchFn {
    return switch (type_y) {
        runtime.dtLongInteger => switch (type_x) {
            runtime.dtTime => &runtime.subLonITime,
            runtime.dtComplex34 => &runtime.subLonICplx,
            runtime.dtReal34Matrix => &runtime.subLonIRema,
            runtime.dtComplex34Matrix => &runtime.subLonICxma,
            else => null,
        },
        runtime.dtShortInteger => switch (type_x) {
            runtime.dtComplex34 => &runtime.subShoICplx,
            runtime.dtReal34Matrix => &runtime.subShoIRema,
            runtime.dtComplex34Matrix => &runtime.subShoICxma,
            else => null,
        },
        runtime.dtReal34 => switch (type_x) {
            runtime.dtTime => &runtime.subRealTime,
            runtime.dtComplex34 => &runtime.subRealCplx,
            runtime.dtReal34Matrix => &runtime.subRealRema,
            runtime.dtComplex34Matrix => &runtime.subRealCxma,
            else => null,
        },
        runtime.dtComplex34 => switch (type_x) {
            runtime.dtLongInteger => &runtime.subCplxLonI,
            runtime.dtShortInteger => &runtime.subCplxShoI,
            runtime.dtReal34 => &runtime.subCplxReal,
            runtime.dtComplex34 => &runtime.subCplxCplx,
            runtime.dtReal34Matrix => &runtime.subCplxRema,
            runtime.dtComplex34Matrix => &runtime.subCplxCxma,
            else => null,
        },
        runtime.dtTime => switch (type_x) {
            runtime.dtLongInteger => &runtime.subTimeLonI,
            runtime.dtTime => &runtime.subTimeTime,
            runtime.dtReal34 => &runtime.subTimeReal,
            else => null,
        },
        runtime.dtDate => switch (type_x) {
            runtime.dtLongInteger => &runtime.subDateLonI,
            runtime.dtDate => &runtime.subDateDate,
            runtime.dtReal34 => &runtime.subDateReal,
            else => null,
        },
        runtime.dtReal34Matrix => switch (type_x) {
            runtime.dtLongInteger => &runtime.subRemaLonI,
            runtime.dtShortInteger => &runtime.subRemaShoI,
            runtime.dtReal34 => &runtime.subRemaReal,
            runtime.dtComplex34 => &runtime.subRemaCplx,
            runtime.dtReal34Matrix => &runtime.subRemaRema,
            runtime.dtComplex34Matrix => &runtime.subRemaCxma,
            else => null,
        },
        runtime.dtComplex34Matrix => switch (type_x) {
            runtime.dtLongInteger => &runtime.subCxmaLonI,
            runtime.dtShortInteger => &runtime.subCxmaShoI,
            runtime.dtReal34 => &runtime.subCxmaReal,
            runtime.dtComplex34 => &runtime.subCxmaCplx,
            runtime.dtReal34Matrix => &runtime.subCxmaRema,
            runtime.dtComplex34Matrix => &runtime.subCxmaCxma,
            else => null,
        },
        else => null,
    };
}

fn selectRemainingMultiplyBranch(type_y: u32, type_x: u32) ?BranchFn {
    return switch (type_y) {
        runtime.dtLongInteger => switch (type_x) {
            runtime.dtTime => &runtime.mulLonITime,
            runtime.dtComplex34 => &runtime.mulLonICplx,
            runtime.dtReal34Matrix => &runtime.mulLonIRema,
            runtime.dtComplex34Matrix => &runtime.mulLonICxma,
            else => null,
        },
        runtime.dtShortInteger => switch (type_x) {
            runtime.dtTime => &runtime.mulShoITime,
            runtime.dtComplex34 => &runtime.mulShoICplx,
            runtime.dtReal34Matrix => &runtime.mulShoIRema,
            runtime.dtComplex34Matrix => &runtime.mulShoICxma,
            else => null,
        },
        runtime.dtReal34 => switch (type_x) {
            runtime.dtTime => &runtime.mulRealTime,
            runtime.dtComplex34 => &runtime.mulRealCplx,
            runtime.dtReal34Matrix => &runtime.mulRealRema,
            runtime.dtComplex34Matrix => &runtime.mulRealCxma,
            else => null,
        },
        runtime.dtComplex34 => switch (type_x) {
            runtime.dtLongInteger => &runtime.mulCplxLonI,
            runtime.dtShortInteger => &runtime.mulCplxShoI,
            runtime.dtReal34 => &runtime.mulCplxReal,
            runtime.dtComplex34 => &runtime.mulCplxCplx,
            runtime.dtReal34Matrix => &runtime.mulCplxRema,
            runtime.dtComplex34Matrix => &runtime.mulCplxCxma,
            else => null,
        },
        runtime.dtTime => switch (type_x) {
            runtime.dtLongInteger => &runtime.mulTimeLonI,
            runtime.dtShortInteger => &runtime.mulTimeShoI,
            runtime.dtReal34 => &runtime.mulTimeReal,
            else => null,
        },
        runtime.dtReal34Matrix => switch (type_x) {
            runtime.dtLongInteger => &runtime.mulRemaLonI,
            runtime.dtShortInteger => &runtime.mulRemaShoI,
            runtime.dtReal34 => &runtime.mulRemaReal,
            runtime.dtComplex34 => &runtime.mulRemaCplx,
            runtime.dtReal34Matrix => &runtime.mulRemaRema,
            runtime.dtComplex34Matrix => &runtime.mulRemaCxma,
            else => null,
        },
        runtime.dtComplex34Matrix => switch (type_x) {
            runtime.dtLongInteger => &runtime.mulCxmaLonI,
            runtime.dtShortInteger => &runtime.mulCxmaShoI,
            runtime.dtReal34 => &runtime.mulCxmaReal,
            runtime.dtComplex34 => &runtime.mulCxmaCplx,
            runtime.dtReal34Matrix => &runtime.mulCxmaRema,
            runtime.dtComplex34Matrix => &runtime.mulCxmaCxma,
            else => null,
        },
        else => null,
    };
}

fn selectRemainingDivideBranch(type_y: u32, type_x: u32) ?BranchFn {
    return switch (type_y) {
        runtime.dtLongInteger => switch (type_x) {
            runtime.dtTime => &runtime.divLonITime,
            runtime.dtComplex34 => &runtime.divLonICplx,
            runtime.dtReal34Matrix => &runtime.divLonIRema,
            runtime.dtComplex34Matrix => &runtime.divLonICxma,
            else => null,
        },
        runtime.dtShortInteger => switch (type_x) {
            runtime.dtTime => &runtime.divShoITime,
            runtime.dtComplex34 => &runtime.divShoICplx,
            runtime.dtReal34Matrix => &runtime.divShoIRema,
            runtime.dtComplex34Matrix => &runtime.divShoICxma,
            else => null,
        },
        runtime.dtReal34 => switch (type_x) {
            runtime.dtTime => &runtime.divRealTime,
            runtime.dtComplex34 => &runtime.divRealCplx,
            runtime.dtReal34Matrix => &runtime.divRealRema,
            runtime.dtComplex34Matrix => &runtime.divRealCxma,
            else => null,
        },
        runtime.dtComplex34 => switch (type_x) {
            runtime.dtLongInteger => &runtime.divCplxLonI,
            runtime.dtShortInteger => &runtime.divCplxShoI,
            runtime.dtReal34 => &runtime.divCplxReal,
            runtime.dtComplex34 => &runtime.divCplxCplx,
            runtime.dtReal34Matrix => &runtime.divCplxRema,
            runtime.dtComplex34Matrix => &runtime.divCplxCxma,
            else => null,
        },
        runtime.dtTime => switch (type_x) {
            runtime.dtLongInteger => &runtime.divTimeLonI,
            runtime.dtShortInteger => &runtime.divTimeShoI,
            runtime.dtReal34 => &runtime.divTimeReal,
            runtime.dtTime => &runtime.divTimeTime,
            else => null,
        },
        runtime.dtReal34Matrix => switch (type_x) {
            runtime.dtLongInteger => &runtime.divRemaLonI,
            runtime.dtShortInteger => &runtime.divRemaShoI,
            runtime.dtReal34 => &runtime.divRemaReal,
            runtime.dtComplex34 => &runtime.divRemaCplx,
            runtime.dtReal34Matrix => &runtime.divRemaRema,
            runtime.dtComplex34Matrix => &runtime.divRemaCxma,
            else => null,
        },
        runtime.dtComplex34Matrix => switch (type_x) {
            runtime.dtLongInteger => &runtime.divCxmaLonI,
            runtime.dtShortInteger => &runtime.divCxmaShoI,
            runtime.dtReal34 => &runtime.divCxmaReal,
            runtime.dtComplex34 => &runtime.divCxmaCplx,
            runtime.dtReal34Matrix => &runtime.divCxmaRema,
            runtime.dtComplex34Matrix => &runtime.divCxmaCxma,
            else => null,
        },
        else => null,
    };
}

fn tryRemainingArithmetic(select_branch: *const fn (u32, u32) ?BranchFn) bool {
    const branch = select_branch(runtime.getRegisterDataType(runtime.REGISTER_Y), runtime.getRegisterDataType(runtime.REGISTER_X)) orelse return false;

    if (!runtime.saveLastX()) {
        return true;
    }

    branch();
    runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, runtime.REGISTER_Y, no_register);
    return true;
}

fn tryRemainingDivide() bool {
    const branch = selectRemainingDivideBranch(runtime.getRegisterDataType(runtime.REGISTER_Y), runtime.getRegisterDataType(runtime.REGISTER_X)) orelse return false;

    runtime.copySourceRegisterToDestRegister(runtime.REGISTER_X, runtime.REGISTER_L);
    branch();
    runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, runtime.REGISTER_Y, no_register);
    return true;
}

fn tryScalarIntRealArithmetic(operation: u8) bool {
    const type_x = runtime.getRegisterDataType(runtime.REGISTER_X);
    const type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);
    const x_is_real = type_x == runtime.dtReal34;
    const y_is_real = type_y == runtime.dtReal34;
    const x_is_int = type_x == runtime.dtLongInteger or type_x == runtime.dtShortInteger;
    const y_is_int = type_y == runtime.dtLongInteger or type_y == runtime.dtShortInteger;

    if (!((x_is_real and y_is_int) or (y_is_real and x_is_int))) {
        return false;
    }

    if (!runtime.saveLastX()) {
        return true;
    }

    if (x_is_real) {
        var y_value: runtime.real_t = undefined;
        var x_value: runtime.real_t = undefined;
        const x_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_X);

        if (type_y == runtime.dtLongInteger) {
            runtime.convertLongIntegerRegisterToReal(runtime.REGISTER_Y, &y_value, &runtime.ctxtReal39);
        } else {
            runtime.convertShortIntegerRegisterToReal(runtime.REGISTER_Y, &y_value, &runtime.ctxtReal39);
        }
        runtime.real34ToReal(real34DataPointer(runtime.REGISTER_X), &x_value);
        if (x_angular_mode == runtime.amNone) {
            applyDyadicRealOperation(operation, &y_value, &x_value, &x_value);
            runtime.convertRealToReal34ResultRegister(&x_value, runtime.REGISTER_X);
        } else {
            runtime.convertAngleFromTo(&x_value, x_angular_mode, runtime.currentAngularMode, &runtime.ctxtReal39);
            applyDyadicRealOperation(operation, &y_value, &x_value, &x_value);
            runtime.convertRealToReal34ResultRegister(&x_value, runtime.REGISTER_X);
            runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.currentAngularMode);
        }
    } else {
        var y_value: runtime.real_t = undefined;
        var x_value: runtime.real_t = undefined;
        const y_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_Y);

        runtime.real34ToReal(real34DataPointer(runtime.REGISTER_Y), &y_value);
        if (type_x == runtime.dtLongInteger) {
            runtime.convertLongIntegerRegisterToReal(runtime.REGISTER_X, &x_value, &runtime.ctxtReal39);
        } else {
            runtime.convertShortIntegerRegisterToReal(runtime.REGISTER_X, &x_value, &runtime.ctxtReal39);
        }
        runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
        if (y_angular_mode == runtime.amNone) {
            applyDyadicRealOperation(operation, &y_value, &x_value, &x_value);
            runtime.convertRealToReal34ResultRegister(&x_value, runtime.REGISTER_X);
        } else {
            runtime.convertAngleFromTo(&y_value, y_angular_mode, runtime.currentAngularMode, &runtime.ctxtReal39);
            applyDyadicRealOperation(operation, &y_value, &x_value, &x_value);
            runtime.convertRealToReal34ResultRegister(&x_value, runtime.REGISTER_X);
            runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.currentAngularMode);
        }
    }

    runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, runtime.REGISTER_Y, no_register);
    return true;
}

fn tryScalarRealArithmetic(operation: u8) bool {
    if (runtime.getRegisterDataType(runtime.REGISTER_X) != runtime.dtReal34 or runtime.getRegisterDataType(runtime.REGISTER_Y) != runtime.dtReal34) {
        return false;
    }

    if (!runtime.saveLastX()) {
        return true;
    }

    const y_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_Y);
    const x_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_X);
    switch (operation) {
        dyadic_integer_add, dyadic_integer_subtract => {
            if (y_angular_mode == runtime.amNone and x_angular_mode == runtime.amNone) {
                applyDyadicReal34Operation(operation, real34DataPointer(runtime.REGISTER_Y), real34DataPointer(runtime.REGISTER_X), real34DataPointer(runtime.REGISTER_X));
            } else {
                var y_value: runtime.real_t = undefined;
                var x_value: runtime.real_t = undefined;
                var resolved_y_mode = y_angular_mode;
                var resolved_x_mode = x_angular_mode;

                runtime.real34ToReal(real34DataPointer(runtime.REGISTER_Y), &y_value);
                runtime.real34ToReal(real34DataPointer(runtime.REGISTER_X), &x_value);
                if (resolved_y_mode == runtime.amNone) {
                    resolved_y_mode = runtime.currentAngularMode;
                } else if (resolved_x_mode == runtime.amNone) {
                    resolved_x_mode = runtime.currentAngularMode;
                }
                runtime.convertAngleFromTo(&y_value, resolved_y_mode, runtime.currentAngularMode, &runtime.ctxtReal39);
                runtime.convertAngleFromTo(&x_value, resolved_x_mode, runtime.currentAngularMode, &runtime.ctxtReal39);
                applyDyadicRealOperation(operation, &y_value, &x_value, &x_value);
                runtime.convertRealToReal34ResultRegister(&x_value, runtime.REGISTER_X);
                runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.currentAngularMode);
            }
        },
        dyadic_integer_multiply => {
            if (y_angular_mode == runtime.amNone and x_angular_mode == runtime.amNone) {
                runtime.real34Multiply(real34DataPointer(runtime.REGISTER_Y), real34DataPointer(runtime.REGISTER_X), real34DataPointer(runtime.REGISTER_X));
            } else if (y_angular_mode != runtime.amNone and x_angular_mode != runtime.amNone) {
                runtime.real34Multiply(real34DataPointer(runtime.REGISTER_Y), real34DataPointer(runtime.REGISTER_X), real34DataPointer(runtime.REGISTER_X));
                runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.amNone);
            } else {
                var y_value: runtime.real_t = undefined;
                var x_value: runtime.real_t = undefined;

                runtime.real34ToReal(real34DataPointer(runtime.REGISTER_Y), &y_value);
                runtime.real34ToReal(real34DataPointer(runtime.REGISTER_X), &x_value);
                runtime.realMultiply(&y_value, &x_value, &x_value, &runtime.ctxtReal39);
                runtime.convertAngleFromTo(
                    &x_value,
                    if (y_angular_mode != runtime.amNone) y_angular_mode else x_angular_mode,
                    runtime.currentAngularMode,
                    &runtime.ctxtReal39,
                );
                runtime.convertRealToReal34ResultRegister(&x_value, runtime.REGISTER_X);
                runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.currentAngularMode);
            }
        },
        else => unreachable,
    }

    runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, runtime.REGISTER_Y, no_register);
    return true;
}

fn tryScalarIntegerOverRealDivide() bool {
    const type_x = runtime.getRegisterDataType(runtime.REGISTER_X);
    const type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);
    if (type_x != runtime.dtReal34 or (type_y != runtime.dtLongInteger and type_y != runtime.dtShortInteger)) {
        return false;
    }

    runtime.copySourceRegisterToDestRegister(runtime.REGISTER_X, runtime.REGISTER_L);

    var y_value: runtime.real_t = undefined;
    if (type_y == runtime.dtLongInteger) {
        runtime.convertLongIntegerRegisterToReal(runtime.REGISTER_Y, &y_value, &runtime.ctxtReal39);
    } else {
        runtime.convertShortIntegerRegisterToReal(runtime.REGISTER_Y, &y_value, &runtime.ctxtReal39);
    }

    runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.amNone);
    if (runtime.real34IsZero(real34DataPointer(runtime.REGISTER_X))) {
        if (runtime.realIsZero(&y_value)) {
            if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
                runtime.convertRealToReal34ResultRegister(runtime.const_NaN, runtime.REGISTER_X);
            } else {
                runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
                runtime.moreInfoOnError(
                    if (type_y == runtime.dtLongInteger) "In function divLonIReal:" else "In function divShoIReal:",
                    "cannot divide 0 by 0",
                    null,
                    null,
                );
            }
        } else if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.realToReal34(
                if (runtime.realIsNegative(&y_value)) runtime.z47_math_wrappers_const_minus_infinity() else runtime.z47_math_wrappers_const_plus_infinity(),
                real34DataPointer(runtime.REGISTER_X),
            );
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            runtime.moreInfoOnError(
                if (type_y == runtime.dtLongInteger) "In function divLonIReal:" else "In function divShoIReal:",
                if (type_y == runtime.dtLongInteger) "cannot divide a long integer by 0" else "cannot divide a short integer by 0",
                null,
                null,
            );
        }
    } else {
        var x_value: runtime.real_t = undefined;

        runtime.real34ToReal(real34DataPointer(runtime.REGISTER_X), &x_value);
        runtime.realDivide(&y_value, &x_value, &x_value, &runtime.ctxtReal39);
        runtime.convertRealToReal34ResultRegister(&x_value, runtime.REGISTER_X);
    }

    runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, runtime.REGISTER_Y, no_register);
    return true;
}

fn tryScalarRealOverIntegerDivide() bool {
    const type_x = runtime.getRegisterDataType(runtime.REGISTER_X);
    const type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);
    if ((type_x != runtime.dtLongInteger and type_x != runtime.dtShortInteger) or type_y != runtime.dtReal34) {
        return false;
    }

    runtime.copySourceRegisterToDestRegister(runtime.REGISTER_X, runtime.REGISTER_L);

    var x_value: runtime.real_t = undefined;
    if (type_x == runtime.dtLongInteger) {
        runtime.convertLongIntegerRegisterToReal(runtime.REGISTER_X, &x_value, &runtime.ctxtReal39);
    } else {
        runtime.convertShortIntegerRegisterToReal(runtime.REGISTER_X, &x_value, &runtime.ctxtReal39);
    }

    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
    if (runtime.realIsZero(&x_value)) {
        if (runtime.real34IsZero(real34DataPointer(runtime.REGISTER_Y))) {
            if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
                runtime.convertRealToReal34ResultRegister(runtime.const_NaN, runtime.REGISTER_X);
            } else {
                runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
                runtime.moreInfoOnError(
                    if (type_x == runtime.dtLongInteger) "In function divRealLonI:" else "In function divRealShoI:",
                    "cannot divide 0 by 0",
                    null,
                    null,
                );
            }
        } else if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.realToReal34(
                if (runtime.real34IsNegative(real34DataPointer(runtime.REGISTER_Y))) runtime.z47_math_wrappers_const_minus_infinity() else runtime.z47_math_wrappers_const_plus_infinity(),
                real34DataPointer(runtime.REGISTER_X),
            );
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            runtime.moreInfoOnError(
                if (type_x == runtime.dtLongInteger) "In function divRealLonI:" else "In function divRealShoI:",
                "cannot divide a real34 by 0",
                null,
                null,
            );
        }
    } else {
        var y_value: runtime.real_t = undefined;
        const y_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_Y);

        runtime.real34ToReal(real34DataPointer(runtime.REGISTER_Y), &y_value);
        if (y_angular_mode == runtime.amNone) {
            runtime.realDivide(&y_value, &x_value, &x_value, &runtime.ctxtReal39);
            runtime.convertRealToReal34ResultRegister(&x_value, runtime.REGISTER_X);
        } else {
            runtime.convertAngleFromTo(&y_value, y_angular_mode, runtime.currentAngularMode, &runtime.ctxtReal39);
            runtime.realDivide(&y_value, &x_value, &x_value, &runtime.ctxtReal39);
            runtime.convertRealToReal34ResultRegister(&x_value, runtime.REGISTER_X);
            runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.currentAngularMode);
        }
    }

    runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, runtime.REGISTER_Y, no_register);
    return true;
}

fn tryScalarRealOverRealDivide() bool {
    if (runtime.getRegisterDataType(runtime.REGISTER_X) != runtime.dtReal34 or runtime.getRegisterDataType(runtime.REGISTER_Y) != runtime.dtReal34) {
        return false;
    }

    runtime.copySourceRegisterToDestRegister(runtime.REGISTER_X, runtime.REGISTER_L);
    if (runtime.real34IsZero(real34DataPointer(runtime.REGISTER_Y)) and runtime.real34IsZero(real34DataPointer(runtime.REGISTER_X))) {
        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.convertRealToReal34ResultRegister(runtime.const_NaN, runtime.REGISTER_X);
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            runtime.moreInfoOnError("In function divRealReal:", "cannot divide 0 by 0", null, null);
        }
    } else if (runtime.real34IsZero(real34DataPointer(runtime.REGISTER_X))) {
        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.realToReal34(
                if (runtime.real34IsNegative(real34DataPointer(runtime.REGISTER_Y))) runtime.z47_math_wrappers_const_minus_infinity() else runtime.z47_math_wrappers_const_plus_infinity(),
                real34DataPointer(runtime.REGISTER_X),
            );
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            runtime.moreInfoOnError("In function divRealReal:", "cannot divide a real34 by 0", null, null);
        }
    } else {
        const y_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_Y);
        const x_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_X);

        if (y_angular_mode == runtime.amNone) {
            runtime.real34Divide(real34DataPointer(runtime.REGISTER_Y), real34DataPointer(runtime.REGISTER_X), real34DataPointer(runtime.REGISTER_X));
            runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.amNone);
        } else {
            var y_value: runtime.real_t = undefined;
            var x_value: runtime.real_t = undefined;

            runtime.real34ToReal(real34DataPointer(runtime.REGISTER_Y), &y_value);
            runtime.real34ToReal(real34DataPointer(runtime.REGISTER_X), &x_value);
            if (x_angular_mode != runtime.amNone) {
                runtime.convertAngleFromTo(&x_value, x_angular_mode, y_angular_mode, &runtime.ctxtReal39);
                runtime.realDivide(&y_value, &x_value, &x_value, &runtime.ctxtReal39);
                runtime.convertRealToReal34ResultRegister(&x_value, runtime.REGISTER_X);
                runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.amNone);
            } else {
                runtime.realDivide(&y_value, &x_value, &x_value, &runtime.ctxtReal39);
                runtime.convertAngleFromTo(&x_value, y_angular_mode, runtime.currentAngularMode, &runtime.ctxtReal39);
                runtime.convertRealToReal34ResultRegister(&x_value, runtime.REGISTER_X);
                runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.currentAngularMode);
            }
        }
    }

    runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, runtime.REGISTER_Y, no_register);
    return true;
}

fn tryDyadicLongIntegerArithmetic(operation: u8) bool {
    const type_x = runtime.getRegisterDataType(runtime.REGISTER_X);
    const type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);
    const x_is_long = type_x == runtime.dtLongInteger;
    const y_is_long = type_y == runtime.dtLongInteger;
    const x_is_short = type_x == runtime.dtShortInteger;
    const y_is_short = type_y == runtime.dtShortInteger;

    if (!(x_is_long or x_is_short) or !(y_is_long or y_is_short)) {
        return false;
    }

    if (!runtime.saveLastX()) {
        return true;
    }

    if (x_is_short and y_is_short) {
        const x_value = shortIntegerData(runtime.REGISTER_X);
        const y_value = shortIntegerData(runtime.REGISTER_Y);

        runtime.setRegisterTag(runtime.REGISTER_X, runtime.getRegisterTag(runtime.REGISTER_Y));
        x_value.* = switch (operation) {
            dyadic_integer_add => runtime.WP34S_intAdd(y_value.*, x_value.*),
            dyadic_integer_subtract => runtime.WP34S_intSubtract(y_value.*, x_value.*),
            dyadic_integer_multiply => runtime.WP34S_intMultiply(y_value.*, x_value.*),
            else => unreachable,
        };

        runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, runtime.REGISTER_Y, no_register);
        return true;
    }

    var x_value: runtime.longInteger_t = undefined;
    var y_value: runtime.longInteger_t = undefined;

    if (x_is_long) {
        runtime.convertLongIntegerRegisterToLongInteger(runtime.REGISTER_X, &x_value[0]);
    } else {
        runtime.convertShortIntegerRegisterToLongInteger(runtime.REGISTER_X, &x_value[0]);
    }

    if (y_is_long) {
        runtime.convertLongIntegerRegisterToLongInteger(runtime.REGISTER_Y, &y_value[0]);
    } else {
        runtime.convertShortIntegerRegisterToLongInteger(runtime.REGISTER_Y, &y_value[0]);
    }

    defer runtime.__gmpz_clear(&x_value[0]);
    defer runtime.__gmpz_clear(&y_value[0]);

    switch (operation) {
        dyadic_integer_add => runtime.__gmpz_add(&x_value[0], &y_value[0], &x_value[0]),
        dyadic_integer_subtract => runtime.__gmpz_sub(&x_value[0], &y_value[0], &x_value[0]),
        dyadic_integer_multiply => runtime.__gmpz_mul(&x_value[0], &y_value[0], &x_value[0]),
        else => unreachable,
    }

    runtime.convertLongIntegerToLongIntegerRegister(&x_value[0], runtime.REGISTER_X);
    runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, runtime.REGISTER_Y, no_register);
    return true;
}

fn tryDyadicLongIntegerDivide(with_remainder: bool) bool {
    const type_x = runtime.getRegisterDataType(runtime.REGISTER_X);
    const type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);
    const x_is_long = type_x == runtime.dtLongInteger;
    const y_is_long = type_y == runtime.dtLongInteger;
    const x_is_short = type_x == runtime.dtShortInteger;
    const y_is_short = type_y == runtime.dtShortInteger;

    if (!(x_is_long or x_is_short) or !(y_is_long or y_is_short)) {
        return false;
    }

    if (!runtime.saveLastX()) {
        return true;
    }

    if (x_is_short and y_is_short and !with_remainder) {
        var divisor_magnitude: u64 = 0;
        var divisor_sign: i16 = 0;
        runtime.convertShortIntegerRegisterToUInt64(runtime.REGISTER_X, &divisor_sign, &divisor_magnitude);

        if (divisor_magnitude == 0) {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            runtime.moreInfoOnError(
                if (with_remainder) "In function fnIDivR:" else "In function fnIDiv:",
                "cannot divide current integer pair by 0",
                null,
                null,
            );
        } else {
            const x_raw = shortIntegerData(runtime.REGISTER_X);
            const y_raw = shortIntegerData(runtime.REGISTER_Y);

            x_raw.* = runtime.WP34S_intDivide(y_raw.*, x_raw.*);
            runtime.setRegisterTag(runtime.REGISTER_X, runtime.getRegisterShortIntegerBase(runtime.REGISTER_Y));
        }

        runtime.adjustResult(runtime.REGISTER_X, true, false, runtime.REGISTER_X, runtime.REGISTER_Y, no_register);
        return true;
    }

    var x_value: runtime.longInteger_t = undefined;
    var y_value: runtime.longInteger_t = undefined;

    if (x_is_long) {
        runtime.convertLongIntegerRegisterToLongInteger(runtime.REGISTER_X, &x_value[0]);
    } else {
        runtime.convertShortIntegerRegisterToLongInteger(runtime.REGISTER_X, &x_value[0]);
    }

    if (y_is_long) {
        runtime.convertLongIntegerRegisterToLongInteger(runtime.REGISTER_Y, &y_value[0]);
    } else {
        runtime.convertShortIntegerRegisterToLongInteger(runtime.REGISTER_Y, &y_value[0]);
    }

    defer runtime.__gmpz_clear(&x_value[0]);
    defer runtime.__gmpz_clear(&y_value[0]);

    if (x_value[0]._mp_size == 0) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError(
            if (with_remainder) "In function fnIDivR:" else "In function fnIDiv:",
            "cannot divide current integer pair by 0",
            null,
            null,
        );
    } else if (with_remainder) {
        var quotient: runtime.longInteger_t = undefined;
        var remainder: runtime.longInteger_t = undefined;

        runtime.__gmpz_init(&quotient[0]);
        runtime.__gmpz_init(&remainder[0]);
        defer runtime.__gmpz_clear(&quotient[0]);
        defer runtime.__gmpz_clear(&remainder[0]);

        runtime.__gmpz_tdiv_qr(&quotient[0], &remainder[0], &y_value[0], &x_value[0]);
        if (x_is_short and y_is_short) {
            const base_y = runtime.getRegisterShortIntegerBase(runtime.REGISTER_Y);
            runtime.convertLongIntegerToShortIntegerRegister(&quotient[0], base_y, runtime.REGISTER_X);
            runtime.convertLongIntegerToShortIntegerRegister(&remainder[0], base_y, runtime.REGISTER_Y);
        } else {
            runtime.convertLongIntegerToLongIntegerRegister(&quotient[0], runtime.REGISTER_X);
            if (y_is_short) {
                runtime.convertLongIntegerToShortIntegerRegister(&remainder[0], runtime.getRegisterShortIntegerBase(runtime.REGISTER_Y), runtime.REGISTER_Y);
            } else {
                runtime.convertLongIntegerToLongIntegerRegister(&remainder[0], runtime.REGISTER_Y);
            }
        }
    } else {
        var remainder: runtime.longInteger_t = undefined;

        runtime.__gmpz_init(&remainder[0]);
        defer runtime.__gmpz_clear(&remainder[0]);

        runtime.__gmpz_tdiv_qr(&x_value[0], &remainder[0], &y_value[0], &x_value[0]);
        runtime.convertLongIntegerToLongIntegerRegister(&x_value[0], runtime.REGISTER_X);
    }

    if (with_remainder) {
        runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, runtime.REGISTER_Y, no_register);
        runtime.adjustResult(runtime.REGISTER_Y, false, false, runtime.REGISTER_X, runtime.REGISTER_Y, no_register);
    } else {
        runtime.adjustResult(runtime.REGISTER_X, true, false, runtime.REGISTER_X, runtime.REGISTER_Y, no_register);
    }

    return true;
}

pub export fn fnAdd(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (tryDyadicLongIntegerArithmetic(dyadic_integer_add)) {
        return;
    }

    if (tryScalarIntRealArithmetic(dyadic_integer_add) or tryScalarRealArithmetic(dyadic_integer_add)) {
        return;
    }

    if (tryRemainingArithmetic(&selectRemainingAddBranch)) {
        return;
    }

    add_retained(unused_but_mandatory_parameter);
}

pub export fn fnSubtract(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (tryDyadicLongIntegerArithmetic(dyadic_integer_subtract)) {
        return;
    }

    if (tryScalarIntRealArithmetic(dyadic_integer_subtract) or tryScalarRealArithmetic(dyadic_integer_subtract)) {
        return;
    }

    if (tryRemainingArithmetic(&selectRemainingSubtractBranch)) {
        return;
    }

    subtract_retained(unused_but_mandatory_parameter);
}

pub export fn fnMultiply(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (tryDyadicLongIntegerArithmetic(dyadic_integer_multiply)) {
        return;
    }

    if (tryScalarIntRealArithmetic(dyadic_integer_multiply) or tryScalarRealArithmetic(dyadic_integer_multiply)) {
        return;
    }

    if (tryRemainingArithmetic(&selectRemainingMultiplyBranch)) {
        return;
    }

    multiply_retained(unused_but_mandatory_parameter);
}

pub export fn fnDivide(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (tryScalarIntegerOverRealDivide()) {
        return;
    }

    if (tryScalarRealOverIntegerDivide()) {
        return;
    }

    if (tryScalarRealOverRealDivide()) {
        return;
    }

    if (tryRemainingDivide()) {
        return;
    }

    divide_retained(unused_but_mandatory_parameter);
}

pub export fn fnIDiv(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (tryDyadicLongIntegerDivide(false)) {
        return;
    }

    integer_divide_retained(unused_but_mandatory_parameter);
}

pub export fn fnIDivR(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (tryDyadicLongIntegerDivide(true)) {
        return;
    }

    integer_divide_remainder_retained(unused_but_mandatory_parameter);
}

pub export fn fnDblMultiply(unused_but_mandatory_parameter: u16) callconv(.c) void {
    double_width_command_owned.dblMultiply(unused_but_mandatory_parameter);
}

pub export fn fnRound(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    if (register_data_type != runtime.dtLongInteger and register_data_type != runtime.dtShortInteger) {
        round_retained(unused_but_mandatory_parameter);
        return;
    }

    if (!runtime.saveLastX()) {
        return;
    }

    runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, no_register, no_register);
}

fn decompError() void {
    var message_buffer: [96]u8 = undefined;
    const type_name = std.mem.span(runtime.getRegisterDataTypeName(runtime.REGISTER_X, true, false));
    const message = bufPrintZ(&message_buffer, "cannot calculate Decomp for {s}", .{type_name}) catch "cannot calculate Decomp";

    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
    runtime.moreInfoOnError("In function fnDecomp:", message, null, null);
}

fn decompLongInteger() void {
    var value: runtime.longInteger_t = undefined;

    runtime.liftStack();
    runtime.__gmpz_init(&value[0]);
    defer runtime.__gmpz_clear(&value[0]);

    runtime.__gmpz_set_ui(&value[0], 1);
    runtime.convertLongIntegerToLongIntegerRegister(&value[0], runtime.REGISTER_X);
}

fn decompReal() void {
    const x_value = runtime.registerReal34Ptr(runtime.REGISTER_X).*;

    runtime.setSystemFlag(runtime.FLAG_ASLIFT);
    runtime.liftStack();

    if (runtime.real34IsNaN(&x_value)) {
        runtime.convertRealToLongIntegerRegister(runtime.z47_math_wrappers_const_0(), runtime.REGISTER_X, runtime.DEC_ROUND_HALF_DOWN);
        runtime.convertRealToLongIntegerRegister(runtime.z47_math_wrappers_const_0(), runtime.REGISTER_Y, runtime.DEC_ROUND_HALF_DOWN);
        return;
    }

    if (runtime.real34IsInfinite(&x_value)) {
        runtime.convertRealToLongIntegerRegister(runtime.z47_math_wrappers_const_0(), runtime.REGISTER_X, runtime.DEC_ROUND_HALF_DOWN);
        runtime.convertRealToLongIntegerRegister(
            if (runtime.real34IsNegative(&x_value)) runtime.z47_math_wrappers_const_minus_1() else runtime.z47_math_wrappers_const_1(),
            runtime.REGISTER_Y,
            runtime.DEC_ROUND_HALF_DOWN,
        );
        return;
    }

    const saved_system_flags0 = runtime.systemFlags0;
    const saved_system_flags1 = runtime.systemFlags1;
    var sign: i16 = 0;
    var int_part: u64 = 0;
    var numer: u64 = 0;
    var denom: u64 = 0;
    var less_equal_greater: i16 = 0;
    var value: runtime.longInteger_t = undefined;

    runtime.clearSystemFlag(runtime.FLAG_PROPFR);
    _ = runtime.fraction(runtime.REGISTER_Y, &sign, &int_part, &numer, &denom, &less_equal_greater);
    runtime.systemFlags0 = saved_system_flags0;
    runtime.systemFlags1 = saved_system_flags1;

    runtime.__gmpz_init(&value[0]);
    defer runtime.__gmpz_clear(&value[0]);

    runtime.__gmpz_set_ui(&value[0], @as(c_ulong, @intCast(numer)));
    if (sign == -1) {
        longIntegerSetNegativeSign(&value[0]);
    }
    runtime.convertLongIntegerToLongIntegerRegister(&value[0], runtime.REGISTER_Y);

    runtime.__gmpz_set_ui(&value[0], @as(c_ulong, @intCast(denom)));
    runtime.convertLongIntegerToLongIntegerRegister(&value[0], runtime.REGISTER_X);
}

pub export fn fnDecomp(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    if (!runtime.saveLastX()) {
        return;
    }

    switch (runtime.getRegisterDataType(runtime.REGISTER_X)) {
        runtime.dtLongInteger => decompLongInteger(),
        runtime.dtReal34 => decompReal(),
        else => decompError(),
    }

    runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, no_register, no_register);
    runtime.adjustResult(runtime.REGISTER_Y, false, false, runtime.REGISTER_Y, no_register, no_register);
}


pub export fn fnCheckInteger(mode: u16) callconv(.c) void {
    check_value_owned.checkInteger(mode);
}

pub export fn fnDec(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (unused_but_mandatory_parameter != runtime.REGISTER_X and unused_but_mandatory_parameter != runtime.REGISTER_Y and unused_but_mandatory_parameter != runtime.REGISTER_Z and unused_but_mandatory_parameter != runtime.REGISTER_T) {
        decrement_retained(unused_but_mandatory_parameter);
        return;
    }

    incDecRegister(@intCast(unused_but_mandatory_parameter), dec_flag);
}

pub export fn fnInc(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (unused_but_mandatory_parameter != runtime.REGISTER_X and unused_but_mandatory_parameter != runtime.REGISTER_Y and unused_but_mandatory_parameter != runtime.REGISTER_Z and unused_but_mandatory_parameter != runtime.REGISTER_T) {
        increment_retained(unused_but_mandatory_parameter);
        return;
    }

    incDecRegister(@intCast(unused_but_mandatory_parameter), inc_flag);
}

pub export fn fnXLessThan(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const regist: runtime.calcRegister_t = @intCast(unused_but_mandatory_parameter);

    if (!compare_owned.isOwnedCompareRegister(regist)) {
        compare_less_than_retained(unused_but_mandatory_parameter);
        return;
    }

    compare_owned.compareScalarRegister(regist, .less_than);
}

pub export fn fnXLessEqual(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const regist: runtime.calcRegister_t = @intCast(unused_but_mandatory_parameter);

    if (!compare_owned.isOwnedCompareRegister(regist)) {
        compare_less_equal_retained(unused_but_mandatory_parameter);
        return;
    }

    compare_owned.compareScalarRegister(regist, .less_equal);
}

pub export fn fnXGreaterThan(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const regist: runtime.calcRegister_t = @intCast(unused_but_mandatory_parameter);

    if (!compare_owned.isOwnedCompareRegister(regist)) {
        compare_greater_than_retained(unused_but_mandatory_parameter);
        return;
    }

    compare_owned.compareScalarRegister(regist, .greater_than);
}

pub export fn fnXGreaterEqual(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const regist: runtime.calcRegister_t = @intCast(unused_but_mandatory_parameter);

    if (!compare_owned.isOwnedCompareRegister(regist)) {
        compare_greater_equal_retained(unused_but_mandatory_parameter);
        return;
    }

    compare_owned.compareScalarRegister(regist, .greater_equal);
}

pub export fn fnXEqualsTo(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const regist: runtime.calcRegister_t = @intCast(unused_but_mandatory_parameter);

    if (!compare_owned.isOwnedCompareRegister(regist)) {
        compare_equal_retained(unused_but_mandatory_parameter);
        return;
    }

    compare_owned.compareScalarRegister(regist, .equal);
}

pub export fn fnXNotEqual(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const regist: runtime.calcRegister_t = @intCast(unused_but_mandatory_parameter);

    if (!compare_owned.isOwnedCompareRegister(regist)) {
        compare_not_equal_retained(unused_but_mandatory_parameter);
        return;
    }

    compare_owned.compareScalarRegister(regist, .not_equal);
}

pub export fn fnXAlmostEqual(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const regist: runtime.calcRegister_t = @intCast(unused_but_mandatory_parameter);
    const x_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    const regist_type = runtime.getRegisterDataType(regist);

    if (!compare_owned.isOwnedCompareRegister(regist) or !compare_owned.isOwnedAlmostEqualIntegerType(x_type) or !compare_owned.isOwnedAlmostEqualIntegerType(regist_type)) {
        compare_almost_equal_retained(unused_but_mandatory_parameter);
        return;
    }

    compare_owned.compareScalarRegister(regist, .equal);
}

pub export fn fnIsConverged(unused_but_mandatory_parameter: u16) callconv(.c) void {
    convergence_owned.isConverged(unused_but_mandatory_parameter);
}

pub export fn fnCheckType(type_: u16) callconv(.c) void {
    check_value_owned.checkType(type_);
}

pub export fn fnCheckReal(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    check_value_owned.checkReal();
}

pub export fn fnCheckNumber(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    check_value_owned.checkNumber();
}

pub export fn fnCheckAngle(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    check_value_owned.checkAngle();
}

pub export fn fnCheckMatrix(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    check_value_owned.checkMatrix();
}

fn compareTypeErrorX() void {
    runtime.setTemporaryInformation(false);
    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_T);
}

pub export fn fnCheckMatrixSquare(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    check_value_owned.checkMatrixSquare();
}

pub export fn fnCheckForZero(mode: u16) callconv(.c) void {
    check_value_owned.checkForZero(mode);
}

pub export fn fnCheckIsVect2d(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    check_value_owned.checkRealMatrixVector(2);
}

pub export fn fnCheckIsVect3d(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    check_value_owned.checkRealMatrixVector(3);
}

pub export fn fnCheckNaN(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    check_value_owned.checkNaN();
}

pub export fn fnCheckInfinite(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    check_value_owned.checkInfinite();
}

pub export fn fnCheckSpecial(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    check_value_owned.checkSpecial();
}

pub export fn fnCheckPlusZero(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    check_value_owned.checkPlusZero();
}

pub export fn fnCheckMinusZero(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    check_value_owned.checkMinusZero();
}

pub export fn fnGetType(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    get_type_owned.getType();
}

pub export fn fnDblDivide(unused_but_mandatory_parameter: u16) callconv(.c) void {
    double_width_command_owned.dblDivide(unused_but_mandatory_parameter);
}

pub export fn fnDblDivideRemainder(unused_but_mandatory_parameter: u16) callconv(.c) void {
    double_width_command_owned.dblDivideRemainder(unused_but_mandatory_parameter);
}

pub export fn fnToPolar2(unused_but_mandatory_parameter: u16) callconv(.c) void {
    transform_command_owned.toPolar2(unused_but_mandatory_parameter);
}

pub export fn fnToRect2(unused_but_mandatory_parameter: u16) callconv(.c) void {
    transform_command_owned.toRect2(unused_but_mandatory_parameter);
}

pub export fn fnToRect(unused_but_mandatory_parameter: u16) callconv(.c) void {
    transform_command_owned.toRect(unused_but_mandatory_parameter);
}

pub export fn fnParallel(unused_but_mandatory_parameter: u16) callconv(.c) void {
    transform_command_owned.parallel(unused_but_mandatory_parameter);
}

fn shiftDigitsError(function_name: [:0]const u8, operation_name: []const u8) void {
    var message_buffer: [96]u8 = undefined;
    const type_name = std.mem.span(runtime.getRegisterDataTypeName(runtime.REGISTER_X, true, false));
    const message = bufPrintZ(&message_buffer, "cannot {s} {s}", .{ operation_name, type_name }) catch "cannot shift digits";

    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
    runtime.moreInfoOnError(function_name, message, null, null);
}

pub export fn fnUnitVector(unused_but_mandatory_parameter: u16) callconv(.c) void {
    transform_command_owned.unitVector(unused_but_mandatory_parameter);
}

pub export fn fnSdl(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtReal34) {
        var real_value: runtime.real_t = undefined;

        if (!runtime.saveLastX()) {
            return;
        }

        runtime.real34ToReal(runtime.registerReal34Ptr(runtime.REGISTER_X), &real_value);
        real_value.exponent += @as(i32, @intCast(unused_but_mandatory_parameter));
        runtime.convertRealToReal34ResultRegister(&real_value, runtime.REGISTER_X);
        return;
    }

    if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtLongInteger) {
        var x_value: runtime.longInteger_t = undefined;

        if (!runtime.saveLastX()) {
            return;
        }

        runtime.convertLongIntegerRegisterToLongInteger(runtime.REGISTER_X, &x_value[0]);
        defer runtime.__gmpz_clear(&x_value[0]);

        for (0..unused_but_mandatory_parameter) |_| {
            runtime.__gmpz_mul_ui(&x_value[0], &x_value[0], 10);
        }

        runtime.convertLongIntegerToLongIntegerRegister(&x_value[0], runtime.REGISTER_X);
        return;
    }

    shiftDigitsError("In function fnSdl:", "SDL");
}

pub export fn fnSdr(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtReal34) {
        var real_value: runtime.real_t = undefined;

        if (!runtime.saveLastX()) {
            return;
        }

        runtime.real34ToReal(runtime.registerReal34Ptr(runtime.REGISTER_X), &real_value);
        real_value.exponent -= @as(i32, @intCast(unused_but_mandatory_parameter));
        runtime.convertRealToReal34ResultRegister(&real_value, runtime.REGISTER_X);
        return;
    }

    if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtLongInteger) {
        var x_value: runtime.longInteger_t = undefined;

        if (!runtime.saveLastX()) {
            return;
        }

        runtime.convertLongIntegerRegisterToLongInteger(runtime.REGISTER_X, &x_value[0]);
        defer runtime.__gmpz_clear(&x_value[0]);

        for (0..unused_but_mandatory_parameter) |_| {
            _ = runtime.__gmpz_tdiv_q_ui(&x_value[0], &x_value[0], 10);
            if (runtime.__gmpz_cmp_ui(&x_value[0], 0) == 0) {
                break;
            }
        }

        runtime.convertLongIntegerToLongIntegerRegister(&x_value[0], runtime.REGISTER_X);
        return;
    }

    shiftDigitsError("In function fnSdr:", "SDR");
}

fn fibonacciReal(n: *const runtime.real_t, res: *runtime.real_t, real_context: *runtime.realContext_t) void {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;

    runtime.realPower(runtime.z47_math_wrappers_const_phi(), n, &a, real_context);
    runtime.realDivide(runtime.z47_math_wrappers_const_1(), &a, &b, real_context);
    runtime.realMultiply(runtime.z47_math_wrappers_const_pi(), n, res, real_context);
    circular_trig_owned.convertAngleToSinCosTan(res, runtime.amRadian, null, res, null, real_context);
    runtime.realMultiply(&b, res, &b, real_context);
    runtime.realSquareRoot(runtime.z47_math_wrappers_const_5(), res, real_context);
    runtime.realSubtract(&a, &b, &a, real_context);
    runtime.realDivide(&a, res, res, real_context);
}

fn fibonacciComplex(
    n_real: *const runtime.real_t,
    n_imag: *const runtime.real_t,
    res_real: *runtime.real_t,
    res_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    var a_real: runtime.real_t = undefined;
    var a_imag: runtime.real_t = undefined;
    var b_real: runtime.real_t = undefined;
    var b_imag: runtime.real_t = undefined;

    _ = runtime.PowerComplex(runtime.z47_math_wrappers_const_phi(), runtime.z47_math_wrappers_const_0(), n_real, n_imag, &a_real, &a_imag, real_context);
    runtime.divRealComplex(runtime.z47_math_wrappers_const_1(), &a_real, &a_imag, &b_real, &b_imag, real_context);
    runtime.mulComplexComplex(runtime.z47_math_wrappers_const_pi(), runtime.z47_math_wrappers_const_0(), n_real, n_imag, res_real, res_imag, real_context);
    cosComplex(res_real, res_imag, res_real, res_imag, real_context);
    runtime.mulComplexComplex(&b_real, &b_imag, res_real, res_imag, &b_real, &b_imag, real_context);
    runtime.realSquareRoot(runtime.z47_math_wrappers_const_5(), res_real, real_context);
    runtime.realSetZero(res_imag);
    runtime.realSubtract(&a_real, &b_real, &a_real, real_context);
    runtime.realSubtract(&a_imag, &b_imag, &a_imag, real_context);
    runtime.divComplexComplex(&a_real, &a_imag, res_real, res_imag, res_real, res_imag, real_context);
}

fn fibReal() callconv(.c) void {
    var value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &value)) {
        return;
    }

    fibonacciReal(&value, &value, &runtime.ctxtReal39);
    runtime.convertRealToResultRegister(&value, runtime.REGISTER_X, runtime.amNone);
}

fn fibCplx() callconv(.c) void {
    var real_value: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &real_value, &imag_value)) {
        return;
    }

    if (runtime.realIsZero(&imag_value)) {
        fibonacciReal(&real_value, &real_value, &runtime.ctxtReal39);
    } else {
        fibonacciComplex(&real_value, &imag_value, &real_value, &imag_value, &runtime.ctxtReal39);
    }

    runtime.convertComplexToResultRegister(&real_value, &imag_value, runtime.REGISTER_X);
}

fn fibLonI() callconv(.c) void {
    var value: runtime.longInteger_t = undefined;
    var result: runtime.longInteger_t = undefined;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &value[0], null)) {
        return;
    }
    defer runtime.__gmpz_clear(&value[0]);

    const neg = value[0]._mp_size < 0;
    if (neg) {
        value[0]._mp_size = -value[0]._mp_size;
    }

    if (runtime.__gmpz_cmp_ui(&value[0], 4791) > 0) {
        runtime.displayCalcErrorMessage(runtime.ERROR_OUT_OF_RANGE, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        return;
    }

    runtime.__gmpz_init(&result[0]);
    defer runtime.__gmpz_clear(&result[0]);

    runtime.z47_math_wrappers_long_integer_fibonacci(@intCast(runtime.__gmpz_get_ui(&value[0])), &result[0]);
    if (neg and (value[0]._mp_size == 0 or (value[0]._mp_d[0] & 1) == 0)) {
        result[0]._mp_size = -result[0]._mp_size;
    }

    runtime.convertLongIntegerToLongIntegerRegister(&result[0], runtime.REGISTER_X);
}

fn imag34DataPointer(regist: runtime.calcRegister_t) *runtime.real34_t {
    const base: [*]u8 = @ptrCast(@alignCast(runtime.getRegisterDataPointer(regist).?));
    return @as(*runtime.real34_t, @ptrCast(@alignCast(base + @sizeOf(runtime.real34_t))));
}

fn linpolScalar(a: *const runtime.real_t, b: *const runtime.real_t, p: *const runtime.real_t, res: *runtime.real_t) void {
    var x: runtime.real_t = undefined;

    if (runtime.realIsNaN(a) or runtime.realIsNaN(b) or runtime.realIsNaN(p) or runtime.realIsInfinite(p)) {
        runtime.realSetNaN(res);
    } else if (runtime.realIsInfinite(a)) {
        if (runtime.realIsInfinite(b)) {
            if (runtime.realIsNegative(a) == runtime.realIsNegative(b)) {
                res.* = a.*;
            } else {
                runtime.realSetNaN(res);
            }
        } else {
            res.* = a.*;
        }
    } else if (runtime.realIsInfinite(b)) {
        res.* = b.*;
    } else if (runtime.realCompareEqual(a, b)) {
        res.* = a.*;
    } else if (runtime.realIsNegative(a) != runtime.realIsNegative(b)) {
        x = p.*;
        runtime.realChangeSign(&x);
        runtime.realFMA(&x, a, a, &x, &runtime.ctxtReal75);
        runtime.realFMA(p, b, &x, res, &runtime.ctxtReal75);
    } else {
        runtime.realSubtract(b, a, &x, &runtime.ctxtReal75);
        runtime.realFMA(&x, p, a, res, &runtime.ctxtReal75);
    }
}

fn linpolReadP(p: *runtime.real_t) bool {
    switch (runtime.getRegisterDataType(runtime.REGISTER_X)) {
        runtime.dtReal34 => {
            runtime.real34ToReal(real34DataPointer(runtime.REGISTER_X), p);
            return true;
        },
        runtime.dtLongInteger => {
            runtime.convertLongIntegerRegisterToReal(runtime.REGISTER_X, p, &runtime.ctxtReal75);
            return true;
        },
        else => return false,
    }
}

fn linpolReadCoeff(
    regist: runtime.calcRegister_t,
    data_type: u32,
    real_part: *runtime.real_t,
    imag_part: *runtime.real_t,
    real_coefs: *bool,
    data_tag: *runtime.angularMode_t,
) bool {
    switch (data_type) {
        runtime.dtLongInteger => {
            runtime.convertLongIntegerRegisterToReal(regist, real_part, &runtime.ctxtReal75);
            data_tag.* = runtime.amNone;
            return true;
        },
        runtime.dtShortInteger => {
            runtime.convertShortIntegerRegisterToReal(regist, real_part, &runtime.ctxtReal39);
            data_tag.* = runtime.amNone;
            return true;
        },
        runtime.dtReal34 => {
            runtime.real34ToReal(real34DataPointer(regist), real_part);
            data_tag.* = runtime.getRegisterAngularMode(regist);
            return true;
        },
        runtime.dtTime => {
            runtime.convertTimeRegisterToReal34Register(regist, regist);
            runtime.real34ToReal(real34DataPointer(regist), real_part);
            data_tag.* = runtime.amNone;
            return true;
        },
        runtime.dtDate => {
            runtime.internalDateToJulianDay(real34DataPointer(regist), real34DataPointer(regist));
            runtime.real34ToReal(real34DataPointer(regist), real_part);
            data_tag.* = runtime.amNone;
            return true;
        },
        runtime.dtComplex34 => {
            runtime.real34ToReal(real34DataPointer(regist), real_part);
            runtime.real34ToReal(imag34DataPointer(regist), imag_part);
            real_coefs.* = false;
            data_tag.* = runtime.amNone;
            return true;
        },
        else => return false,
    }
}

fn crossDotMatrixTypeError(function_name: [:0]const u8) void {
    var message1_buffer: [96]u8 = undefined;
    var message2_buffer: [64]u8 = undefined;
    const y_type_name = std.mem.span(runtime.getRegisterDataTypeName(runtime.REGISTER_Y, true, false));
    const x_type_name = std.mem.span(runtime.getRegisterDataTypeName(runtime.REGISTER_X, true, false));
    const message1 = bufPrintZ(&message1_buffer, "cannot raise {s}", .{y_type_name}) catch "cannot raise current Y type";
    const message2 = bufPrintZ(&message2_buffer, "to {s}", .{x_type_name}) catch "to current X type";

    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
    runtime.moreInfoOnError(function_name, message1, message2, null);
}

fn linpolInvalidXError() void {
    var message_buffer: [128]u8 = undefined;
    const type_name = std.mem.span(runtime.getRegisterDataTypeName(runtime.REGISTER_X, true, false));
    const message = bufPrintZ(&message_buffer, "cannot LINPOL with {s} in X", .{type_name}) catch "cannot LINPOL with current X type";

    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
    runtime.moreInfoOnError("In function fnLINPOL:", message, null, null);
}

fn linpolDifferingTypeError() void {
    var message_buffer: [192]u8 = undefined;
    const type_name_y = std.mem.span(runtime.getRegisterDataTypeName(runtime.REGISTER_Y, true, false));
    const type_name_z = std.mem.span(runtime.getRegisterDataTypeName(runtime.REGISTER_Z, true, false));
    const message = bufPrintZ(
        &message_buffer,
        "cannot LINPOL with differing data types in Y ({s}) and Z ({s})",
        .{ type_name_y, type_name_z },
    ) catch "cannot LINPOL with differing data types in Y and Z";

    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_Y);
    runtime.moreInfoOnError("In function fnLINPOL:", message, null, null);
}

fn linpolCoeffTypeError(regist: runtime.calcRegister_t) void {
    var message_buffer: [128]u8 = undefined;
    const type_name = std.mem.span(runtime.getRegisterDataTypeName(regist, true, false));
    const register_name = if (regist == runtime.REGISTER_Y) "Y" else "Z";
    const message = bufPrintZ(&message_buffer, "cannot LINPOL with {s} in {s}", .{ type_name, register_name }) catch "cannot LINPOL with current coefficient type";

    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, regist);
    runtime.moreInfoOnError("In function fnLINPOL:", message, null, null);
}

const inc_flag: u8 = 0;
const dec_flag: u8 = 1;

fn incDecError(regist: runtime.calcRegister_t) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, regist);
    runtime.moreInfoOnError("In function incDecError:", "Cannot increment/decrement, incompatible type.", null, null);
}

fn incDecLonI(regist: runtime.calcRegister_t, flag: u8) void {
    var value: runtime.longInteger_t = undefined;

    runtime.convertLongIntegerRegisterToLongInteger(regist, &value[0]);
    defer runtime.__gmpz_clear(&value[0]);

    if (flag == inc_flag) {
        runtime.__gmpz_add_ui(&value[0], &value[0], 1);
    } else {
        runtime.__gmpz_sub_ui(&value[0], &value[0], 1);
    }

    runtime.convertLongIntegerToLongIntegerRegister(&value[0], regist);
}

fn real34DataPointer(regist: runtime.calcRegister_t) *runtime.real34_t {
    return @as(*runtime.real34_t, @ptrCast(@alignCast(runtime.getRegisterDataPointer(regist).?)));
}

fn incDecReal(regist: runtime.calcRegister_t, flag: u8) void {
    var value: runtime.real_t = undefined;

    runtime.real34ToReal(real34DataPointer(regist), &value);
    if (flag == inc_flag) {
        runtime.realAdd(&value, runtime.z47_math_wrappers_const_1(), &value, &runtime.ctxtReal39);
    } else {
        runtime.realSubtract(&value, runtime.z47_math_wrappers_const_1(), &value, &runtime.ctxtReal39);
    }
    runtime.realToReal34(&value, real34DataPointer(regist));
}

fn incDecCplx(regist: runtime.calcRegister_t, flag: u8) void {
    var value: runtime.real_t = undefined;

    runtime.real34ToReal(real34DataPointer(regist), &value);
    if (flag == inc_flag) {
        runtime.realAdd(&value, runtime.z47_math_wrappers_const_1(), &value, &runtime.ctxtReal39);
    } else {
        runtime.realSubtract(&value, runtime.z47_math_wrappers_const_1(), &value, &runtime.ctxtReal39);
    }
    runtime.realToReal34(&value, real34DataPointer(regist));
}

fn incDecShoI(regist: runtime.calcRegister_t, flag: u8) void {
    var sign: i16 = 0;
    var value: u64 = 0;

    runtime.convertShortIntegerRegisterToUInt64(regist, &sign, &value);
    if (sign != 0) {
        if (flag != inc_flag) {
            value += 1;
        } else {
            value -= 1;
        }
    } else {
        if (flag == inc_flag) {
            value += 1;
        } else {
            value -= 1;
        }
    }
    runtime.convertUInt64ToShortIntegerRegister(sign, value, runtime.getRegisterTag(regist), regist);
}

fn incDecRegister(regist: runtime.calcRegister_t, flag: u8) void {
    switch (runtime.getRegisterDataType(regist)) {
        runtime.dtLongInteger => incDecLonI(regist, flag),
        runtime.dtReal34 => incDecReal(regist, flag),
        runtime.dtComplex34 => incDecCplx(regist, flag),
        runtime.dtShortInteger => incDecShoI(regist, flag),
        else => incDecError(regist),
    }
}

pub export fn fnSquareRoot(unused_but_mandatory_parameter: u16) callconv(.c) void {
    transform_command_owned.squareRoot(unused_but_mandatory_parameter);
}

pub export fn fnCubeRoot(unused_but_mandatory_parameter: u16) callconv(.c) void {
    transform_command_owned.cubeRoot(unused_but_mandatory_parameter);
}

pub export fn fnPercentMRR(unused_but_mandatory_parameter: u16) callconv(.c) void {
    percent_command_owned.percentMRR(unused_but_mandatory_parameter);
}

pub export fn fnPercentPlusMG(unused_but_mandatory_parameter: u16) callconv(.c) void {
    percent_command_owned.percentPlusMG(unused_but_mandatory_parameter);
}

pub export fn fnPercentT(unused_but_mandatory_parameter: u16) callconv(.c) void {
    percent_command_owned.percentT(unused_but_mandatory_parameter);
}

pub export fn fnDeltaPercent(unused_but_mandatory_parameter: u16) callconv(.c) void {
    percent_command_owned.deltaPercent(unused_but_mandatory_parameter);
}

pub export fn fnFib(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexMonadicFunction(&fibReal, &fibCplx, null, &fibLonI);
}

pub export fn fnLINPOL(unused_but_mandatory_parameter: u16) callconv(.c) void {
    var a_real: runtime.real_t = undefined;
    var b_real: runtime.real_t = undefined;
    var a_imag: runtime.real_t = undefined;
    var b_imag: runtime.real_t = undefined;
    var p: runtime.real_t = undefined;
    var result_real: runtime.real_t = undefined;
    var result_imag: runtime.real_t = undefined;
    var real_coefs = true;
    var data_tag_y: runtime.angularMode_t = runtime.amNone;
    var data_tag_z: runtime.angularMode_t = runtime.amNone;
    const type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);
    const type_z = runtime.getRegisterDataType(runtime.REGISTER_Z);
    const is_y_angle = type_y == runtime.dtReal34 and runtime.getRegisterAngularMode(runtime.REGISTER_Y) != runtime.amNone;
    const is_z_angle = type_z == runtime.dtReal34 and runtime.getRegisterAngularMode(runtime.REGISTER_Z) != runtime.amNone;

    _ = unused_but_mandatory_parameter;
    runtime.realSetZero(&a_imag);
    runtime.realSetZero(&b_imag);

    if (!linpolReadP(&p)) {
        linpolInvalidXError();
        return;
    }

    if ((type_y != type_z and (type_y == runtime.dtTime or type_z == runtime.dtTime)) or
        (is_y_angle and !is_z_angle) or
        (is_z_angle and !is_y_angle))
    {
        linpolDifferingTypeError();
        return;
    }

    if (!linpolReadCoeff(runtime.REGISTER_Y, type_y, &b_real, &b_imag, &real_coefs, &data_tag_y)) {
        linpolCoeffTypeError(runtime.REGISTER_Y);
        return;
    }

    if (!linpolReadCoeff(runtime.REGISTER_Z, type_z, &a_real, &a_imag, &real_coefs, &data_tag_z)) {
        linpolCoeffTypeError(runtime.REGISTER_Z);
        return;
    }

    if (!runtime.saveLastX()) {
        return;
    }

    runtime.adjustResult(runtime.REGISTER_X, false, true, runtime.REGISTER_X, runtime.REGISTER_Y, runtime.REGISTER_Z);
    runtime.fnDrop(0);
    runtime.fnDrop(0);

    linpolScalar(&a_real, &b_real, &p, &result_real);
    if (real_coefs) {
        if (type_y == runtime.dtTime) {
            runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
            runtime.convertRealToReal34ResultRegister(&result_real, runtime.REGISTER_X);
            runtime.convertReal34RegisterToTimeRegister(runtime.REGISTER_X, runtime.REGISTER_X);
        } else if (type_y == runtime.dtDate) {
            runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtDate, 0, runtime.amNone);
            runtime.realToReal34(&result_real, runtime.registerReal34Ptr(runtime.REGISTER_X));
            runtime.real34ToIntegralValue(runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.DEC_ROUND_CEILING);
            runtime.julianDayToInternalDate(runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.registerReal34Ptr(runtime.REGISTER_X));
        } else {
            if (is_y_angle and is_z_angle) {
                if (data_tag_y != data_tag_z) {
                    data_tag_y = runtime.currentAngularMode;
                }
            } else {
                data_tag_y = runtime.amNone;
            }

            runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, @as(u32, @intCast(data_tag_y)));
            runtime.convertRealToReal34ResultRegister(&result_real, runtime.REGISTER_X);
        }

        return;
    }

    linpolScalar(&a_imag, &b_imag, &p, &result_imag);
    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtComplex34, 0, runtime.amNone);
    runtime.convertComplexToResultRegister(&result_real, &result_imag, runtime.REGISTER_X);
}

fn crossReal() callconv(.c) void {
    runtime.convertRealToResultRegister(runtime.z47_math_wrappers_const_0(), runtime.REGISTER_X, runtime.amNone);
}

fn crossCplx() callconv(.c) void {
    var x_real: runtime.real_t = undefined;
    var x_imag: runtime.real_t = undefined;
    var y_real: runtime.real_t = undefined;
    var y_imag: runtime.real_t = undefined;
    var result_real: runtime.real_t = undefined;
    var temp: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &x_real, &x_imag) or !runtime.getRegisterAsComplex(runtime.REGISTER_Y, &y_real, &y_imag)) {
        return;
    }

    runtime.realMultiply(&x_real, &y_imag, &temp, &runtime.ctxtReal75);
    runtime.realChangeSign(&temp);
    runtime.realFMA(&y_real, &x_imag, &temp, &result_real, &runtime.ctxtReal39);
    runtime.convertRealToResultRegister(&result_real, runtime.REGISTER_X, runtime.amNone);
}

fn tryCrossMatrices() bool {
    const type_x = runtime.getRegisterDataType(runtime.REGISTER_X);
    const type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);
    const x_is_real_matrix = type_x == runtime.dtReal34Matrix;
    const x_is_complex_matrix = type_x == runtime.dtComplex34Matrix;
    const y_is_real_matrix = type_y == runtime.dtReal34Matrix;
    const y_is_complex_matrix = type_y == runtime.dtComplex34Matrix;

    if (!(x_is_real_matrix or x_is_complex_matrix or y_is_real_matrix or y_is_complex_matrix)) {
        return false;
    }

    if (!((x_is_real_matrix or x_is_complex_matrix) and (y_is_real_matrix or y_is_complex_matrix))) {
        return false;
    }

    if (!runtime.saveLastX()) {
        return true;
    }

    if (x_is_real_matrix and y_is_real_matrix) {
        var x_matrix: runtime.real34Matrix_t = undefined;
        var y_matrix: runtime.real34Matrix_t = undefined;
        var result: runtime.real34Matrix_t = undefined;

        runtime.linkToRealMatrixRegister(runtime.REGISTER_X, &x_matrix);
        runtime.linkToRealMatrixRegister(runtime.REGISTER_Y, &y_matrix);

        if (runtime.realVectorSize(&x_matrix) == 0 or runtime.realVectorSize(&y_matrix) == 0 or runtime.realVectorSize(&x_matrix) > 3 or runtime.realVectorSize(&y_matrix) > 3) {
            runtime.displayCalcErrorMessage(runtime.ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        } else {
            runtime.crossRealVectors(&y_matrix, &x_matrix, &result);
            runtime.convertReal34MatrixToReal34MatrixRegister(&result, runtime.REGISTER_X);
        }

        runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, no_register, no_register);
        return true;
    }

    if (x_is_real_matrix) {
        runtime.convertReal34MatrixRegisterToComplex34MatrixRegister(runtime.REGISTER_X, runtime.REGISTER_X);
    } else if (y_is_real_matrix) {
        runtime.convertReal34MatrixRegisterToComplex34MatrixRegister(runtime.REGISTER_Y, runtime.REGISTER_Y);
    }

    var x_matrix: runtime.complex34Matrix_t = undefined;
    var y_matrix: runtime.complex34Matrix_t = undefined;
    var result: runtime.complex34Matrix_t = undefined;

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &x_matrix);
    runtime.linkToComplexMatrixRegister(runtime.REGISTER_Y, &y_matrix);

    if (runtime.complexVectorSize(&x_matrix) == 0 or runtime.complexVectorSize(&y_matrix) == 0 or runtime.complexVectorSize(&x_matrix) > 3 or runtime.complexVectorSize(&y_matrix) > 3) {
        runtime.displayCalcErrorMessage(runtime.ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
    } else {
        runtime.crossComplexVectors(&y_matrix, &x_matrix, &result);
        runtime.convertComplex34MatrixToComplex34MatrixRegister(&result, runtime.REGISTER_X);
    }

    runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, no_register, no_register);
    return true;
}

pub export fn fnCross(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const type_x = runtime.getRegisterDataType(runtime.REGISTER_X);
    const type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);

    _ = unused_but_mandatory_parameter;

    if (tryCrossMatrices()) {
        return;
    }

    if (type_x == runtime.dtReal34Matrix or type_x == runtime.dtComplex34Matrix or type_y == runtime.dtReal34Matrix or type_y == runtime.dtComplex34Matrix) {
        crossDotMatrixTypeError("In function fnCross:");
        return;
    }

    runtime.processRealComplexDyadicFunction(&crossReal, &crossCplx);
}

fn dotCplx(
    x_real: *const runtime.real_t,
    x_imag: *const runtime.real_t,
    y_real: *const runtime.real_t,
    y_imag: *const runtime.real_t,
    result_real: *runtime.real_t,
) void {
    var product: runtime.real_t = undefined;
    var temp: runtime.real_t = undefined;

    runtime.realMultiply(x_real, y_real, &product, &runtime.ctxtReal39);
    runtime.realFMA(x_imag, y_imag, &product, &temp, &runtime.ctxtReal39);
    runtime.realChangeSign(&product);
    runtime.realFMA(x_real, y_real, &product, result_real, &runtime.ctxtReal39);
    runtime.realAdd(result_real, &temp, result_real, &runtime.ctxtReal39);
}

fn doDotReal() callconv(.c) void {
    var x_value: runtime.real_t = undefined;
    var y_value: runtime.real_t = undefined;
    var result: runtime.real_t = undefined;

    if (runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value) and runtime.getRegisterAsReal(runtime.REGISTER_Y, &y_value)) {
        runtime.realMultiply(&x_value, &y_value, &result, &runtime.ctxtReal39);
        runtime.convertRealToResultRegister(&result, runtime.REGISTER_X, runtime.amNone);
    }
}

fn doDotCplx() callconv(.c) void {
    var x_real: runtime.real_t = undefined;
    var x_imag: runtime.real_t = undefined;
    var y_real: runtime.real_t = undefined;
    var y_imag: runtime.real_t = undefined;
    var result_real: runtime.real_t = undefined;

    if (runtime.getRegisterAsComplex(runtime.REGISTER_X, &x_real, &x_imag) and runtime.getRegisterAsComplex(runtime.REGISTER_Y, &y_real, &y_imag)) {
        dotCplx(&x_real, &x_imag, &y_real, &y_imag, &result_real);
        runtime.convertRealToResultRegister(&result_real, runtime.REGISTER_X, runtime.amNone);
    }
}

fn tryDotMatrices() bool {
    const type_x = runtime.getRegisterDataType(runtime.REGISTER_X);
    const type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);
    const x_is_real_matrix = type_x == runtime.dtReal34Matrix;
    const x_is_complex_matrix = type_x == runtime.dtComplex34Matrix;
    const y_is_real_matrix = type_y == runtime.dtReal34Matrix;
    const y_is_complex_matrix = type_y == runtime.dtComplex34Matrix;

    if (!(x_is_real_matrix or x_is_complex_matrix or y_is_real_matrix or y_is_complex_matrix)) {
        return false;
    }

    if (!((x_is_real_matrix or x_is_complex_matrix) and (y_is_real_matrix or y_is_complex_matrix))) {
        return false;
    }

    if (!runtime.saveLastX()) {
        return true;
    }

    if (x_is_real_matrix and y_is_real_matrix) {
        var x_matrix: runtime.real34Matrix_t = undefined;
        var y_matrix: runtime.real34Matrix_t = undefined;
        var result: runtime.real34_t = undefined;

        runtime.linkToRealMatrixRegister(runtime.REGISTER_X, &x_matrix);
        runtime.linkToRealMatrixRegister(runtime.REGISTER_Y, &y_matrix);

        if (runtime.realVectorSize(&x_matrix) == 0 or runtime.realVectorSize(&y_matrix) == 0 or runtime.realVectorSize(&x_matrix) != runtime.realVectorSize(&y_matrix)) {
            runtime.displayCalcErrorMessage(runtime.ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        } else {
            runtime.dotRealVectors(&y_matrix, &x_matrix, &result);
            runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
            runtime.registerReal34Ptr(runtime.REGISTER_X).* = result;
        }

        runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, no_register, no_register);
        return true;
    }

    if (x_is_real_matrix) {
        runtime.convertReal34MatrixRegisterToComplex34MatrixRegister(runtime.REGISTER_X, runtime.REGISTER_X);
    } else if (y_is_real_matrix) {
        runtime.convertReal34MatrixRegisterToComplex34MatrixRegister(runtime.REGISTER_Y, runtime.REGISTER_Y);
    }

    var x_matrix: runtime.complex34Matrix_t = undefined;
    var y_matrix: runtime.complex34Matrix_t = undefined;
    var result_real: runtime.real34_t = undefined;
    var result_imag: runtime.real34_t = undefined;

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &x_matrix);
    runtime.linkToComplexMatrixRegister(runtime.REGISTER_Y, &y_matrix);

    if (runtime.complexVectorSize(&x_matrix) == 0 or runtime.complexVectorSize(&y_matrix) == 0 or runtime.complexVectorSize(&x_matrix) != runtime.complexVectorSize(&y_matrix)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
    } else {
        runtime.dotComplexVectors(&y_matrix, &x_matrix, &result_real, &result_imag);
        runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtComplex34, 0, runtime.amNone);
        runtime.registerReal34Ptr(runtime.REGISTER_X).* = result_real;
        runtime.registerImag34Ptr(runtime.REGISTER_X).* = result_imag;
    }

    runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, no_register, no_register);
    return true;
}

pub export fn fnDot(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const type_x = runtime.getRegisterDataType(runtime.REGISTER_X);
    const type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);

    _ = unused_but_mandatory_parameter;

    if (tryDotMatrices()) {
        return;
    }

    if (type_x == runtime.dtReal34Matrix or type_x == runtime.dtComplex34Matrix or type_y == runtime.dtReal34Matrix or type_y == runtime.dtComplex34Matrix) {
        crossDotMatrixTypeError("In function fnDot:");
        return;
    }

    runtime.processRealComplexDyadicFunction(&doDotReal, &doDotCplx);
}

pub export fn fnLogXY(unused_but_mandatory_parameter: u16) callconv(.c) void {
    logxy_command_owned.fnLogXY(unused_but_mandatory_parameter);
}
