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
const integer_residue_command_owned = @import("math_integer_residue_command_owned.zig");
const scalar_integer_inspection_command_owned = @import("math_scalar_integer_inspection_command_owned.zig");
const matrix_vector_command_owned = @import("math_matrix_vector_command_owned.zig");
const arithmetic_dispatch_command_owned = @import("math_arithmetic_dispatch_command_owned.zig");
const special_algebraic_command_owned = @import("math_special_algebraic_command_owned.zig");
const special_function_sequence_command_owned = @import("math_special_function_sequence_command_owned.zig");
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

pub export fn sqrt1Px2Complex(
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    res_real: *runtime.real_t,
    res_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    special_algebraic_command_owned.sqrt1Px2Complex(real, imag, res_real, res_imag, real_context);
}

pub export fn eulersFormula(
    in_real: *const runtime.real_t,
    in_imag: *const runtime.real_t,
    out_real: *runtime.real_t,
    out_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    special_algebraic_command_owned.eulersFormula(in_real, in_imag, out_real, out_imag, real_context);
}

pub export fn fnSqrt1Px2(unused_but_mandatory_parameter: u16) callconv(.c) void {
    special_algebraic_command_owned.fnSqrt1Px2(unused_but_mandatory_parameter);
}

pub export fn fnM1Pow(unused_but_mandatory_parameter: u16) callconv(.c) void {
    special_algebraic_command_owned.fnM1Pow(unused_but_mandatory_parameter);
}

pub export fn fnEulersFormula(unused_but_mandatory_parameter: u16) callconv(.c) void {
    special_algebraic_command_owned.fnEulersFormula(unused_but_mandatory_parameter);
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

pub export fn fnErf(unused_but_mandatory_parameter: u16) callconv(.c) void {
    special_function_sequence_command_owned.fnErf(unused_but_mandatory_parameter);
}

pub export fn fnErfc(unused_but_mandatory_parameter: u16) callconv(.c) void {
    special_function_sequence_command_owned.fnErfc(unused_but_mandatory_parameter);
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
    integer_residue_command_owned.fnGcd(unused_but_mandatory_parameter);
}

pub export fn fnLcm(unused_but_mandatory_parameter: u16) callconv(.c) void {
    integer_residue_command_owned.fnLcm(unused_but_mandatory_parameter);
}

pub export fn fnMod(unused_but_mandatory_parameter: u16) callconv(.c) void {
    integer_residue_command_owned.fnMod(unused_but_mandatory_parameter);
}

pub export fn fnRmd(unused_but_mandatory_parameter: u16) callconv(.c) void {
    integer_residue_command_owned.fnRmd(unused_but_mandatory_parameter);
}

pub export fn fnUlp(unused_but_mandatory_parameter: u16) callconv(.c) void {
    scalar_integer_inspection_command_owned.fnUlp(unused_but_mandatory_parameter);
}

pub export fn fnMant(unused_but_mandatory_parameter: u16) callconv(.c) void {
    scalar_integer_inspection_command_owned.fnMant(unused_but_mandatory_parameter);
}

pub export fn fnRoundi(unused_but_mandatory_parameter: u16) callconv(.c) void {
    scalar_integer_inspection_command_owned.fnRoundi(unused_but_mandatory_parameter);
}

pub export fn fnNeighb(unused_but_mandatory_parameter: u16) callconv(.c) void {
    integer_residue_command_owned.fnNeighb(unused_but_mandatory_parameter);
}

pub export fn fnIxyz(unused_but_mandatory_parameter: u16) callconv(.c) void {
    special_function_sequence_command_owned.fnIxyz(unused_but_mandatory_parameter);
}

pub export fn fnFactorial(unused_but_mandatory_parameter: u16) callconv(.c) void {
    special_function_sequence_command_owned.fnFactorial(unused_but_mandatory_parameter);
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

pub export fn fnAdd(unused_but_mandatory_parameter: u16) callconv(.c) void {
    arithmetic_dispatch_command_owned.fnAdd(unused_but_mandatory_parameter);
}

pub export fn fnSubtract(unused_but_mandatory_parameter: u16) callconv(.c) void {
    arithmetic_dispatch_command_owned.fnSubtract(unused_but_mandatory_parameter);
}

pub export fn fnMultiply(unused_but_mandatory_parameter: u16) callconv(.c) void {
    arithmetic_dispatch_command_owned.fnMultiply(unused_but_mandatory_parameter);
}

pub export fn fnDivide(unused_but_mandatory_parameter: u16) callconv(.c) void {
    arithmetic_dispatch_command_owned.fnDivide(unused_but_mandatory_parameter);
}

pub export fn fnIDiv(unused_but_mandatory_parameter: u16) callconv(.c) void {
    arithmetic_dispatch_command_owned.fnIDiv(unused_but_mandatory_parameter);
}

pub export fn fnIDivR(unused_but_mandatory_parameter: u16) callconv(.c) void {
    arithmetic_dispatch_command_owned.fnIDivR(unused_but_mandatory_parameter);
}

pub export fn fnDblMultiply(unused_but_mandatory_parameter: u16) callconv(.c) void {
    double_width_command_owned.dblMultiply(unused_but_mandatory_parameter);
}

pub export fn fnRound(unused_but_mandatory_parameter: u16) callconv(.c) void {
    scalar_integer_inspection_command_owned.fnRound(unused_but_mandatory_parameter);
}

pub export fn fnCheckInteger(mode: u16) callconv(.c) void {
    check_value_owned.checkInteger(mode);
}

pub export fn fnDecomp(unused_but_mandatory_parameter: u16) callconv(.c) void {
    scalar_integer_inspection_command_owned.fnDecomp(unused_but_mandatory_parameter);
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
    special_function_sequence_command_owned.fnFib(unused_but_mandatory_parameter);
}

pub export fn fnLINPOL(unused_but_mandatory_parameter: u16) callconv(.c) void {
    matrix_vector_command_owned.fnLINPOL(unused_but_mandatory_parameter);
}

pub export fn fnCross(unused_but_mandatory_parameter: u16) callconv(.c) void {
    matrix_vector_command_owned.fnCross(unused_but_mandatory_parameter);
}
pub export fn fnDot(unused_but_mandatory_parameter: u16) callconv(.c) void {
    matrix_vector_command_owned.fnDot(unused_but_mandatory_parameter);
}

pub export fn fnLogXY(unused_but_mandatory_parameter: u16) callconv(.c) void {
    logxy_command_owned.fnLogXY(unused_but_mandatory_parameter);
}
