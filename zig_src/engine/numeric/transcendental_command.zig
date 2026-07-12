const std = @import("std");
const build_options = @import("math_command_wrappers_build_options");
const circular_trig_owned = @import("trig/circular_trig.zig");
const ln_complex_owned = @import("ln_complex.zig");
const rectangular_to_polar_owned = @import("transform/rectangular_to_polar.zig");
const runtime = @import("command_wrappers_runtime.zig");
const math_command_wrappers = @import("command_wrappers.zig"); // M-callconv: Zig-to-Zig

fn copyReal(destination: *runtime.real_t, source: *const runtime.real_t) void {
    destination.* = source.*;
}

fn realCompareGreaterThan(lhs: *const runtime.real_t, rhs: *const runtime.real_t) bool {
    return runtime.realCompareLessThan(rhs, lhs);
}

fn realCompareLessEqual(lhs: *const runtime.real_t, rhs: *const runtime.real_t) bool {
    return !runtime.realCompareLessThan(rhs, lhs);
}

fn realAbsLessThan(lhs: *const runtime.real_t, rhs: *const runtime.real_t) bool {
    return !runtime.realCompareAbsEqual(lhs, rhs) and !runtime.realCompareAbsGreaterThan(lhs, rhs);
}

fn setExpLimitResult(x: *const runtime.real_t, result: *runtime.real_t, zero: *const runtime.real_t) void {
    if (runtime.realIsNegative(x)) {
        copyReal(result, zero);
    } else {
        copyReal(result, runtime.z47_math_wrappers_const_plus_infinity());
    }
}

pub fn realExpLimitCheck(
    x: *const runtime.real_t,
    result: *runtime.real_t,
    zero: *const runtime.real_t,
) bool {
    if (runtime.realIsSpecial(x)) {
        if (runtime.realIsInfinite(x)) {
            setExpLimitResult(x, result, zero);
        } else {
            runtime.realSetNaN(result);
        }
        return false;
    }

    if (runtime.realCompareAbsGreaterThan(x, runtime.z47_math_wrappers_const_2e6())) {
        setExpLimitResult(x, result, zero);
        return false;
    }

    return true;
}

pub fn realExp(
    x: *const runtime.real_t,
    result: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    if (realExpLimitCheck(x, result, runtime.z47_math_wrappers_const_0())) {
        _ = runtime.decNumberExp(result, x, real_context);
    }
}

pub fn expComplex(
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    res_real: *runtime.real_t,
    res_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    var exp_real: runtime.real_t = undefined;
    var sin_value: runtime.real_t = undefined;
    var cos_value: runtime.real_t = undefined;

    if (runtime.realIsZero(imag)) {
        realExp(real, res_real, real_context);
        runtime.realSetZero(res_imag);
        return;
    }

    if (runtime.realIsSpecial(real) or runtime.realIsSpecial(imag)) {
        runtime.realSetNaN(res_real);
        runtime.realSetNaN(res_imag);
        return;
    }

    realExp(real, &exp_real, real_context);
    circular_trig_owned.convertAngleToSinCosTan(imag, runtime.amRadian, &sin_value, &cos_value, null, real_context);
    runtime.realMultiply(&exp_real, &cos_value, res_real, real_context);
    runtime.realMultiply(&exp_real, &sin_value, res_imag, real_context);
}

pub fn realExpM1(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    runtime.WP34S_ExpM1(x, res, real_context);
}

pub fn lnRealValue(
    x_in: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    if (build_options.use_fake_wp34s_model) {
        runtime.WP34S_Ln(x_in, res, real_context);
        return;
    }

    var z: runtime.real_t = undefined;
    var t: runtime.real_t = undefined;
    var f: runtime.real_t = undefined;
    var n: runtime.real_t = undefined;
    var m: runtime.real_t = undefined;
    var i: runtime.real_t = undefined;
    var v: runtime.real_t = undefined;
    var w: runtime.real_t = undefined;
    var e: runtime.real_t = undefined;
    var root2on2: runtime.real_t = undefined;
    var exponent_adjust: i32 = 0;

    if (runtime.realIsSpecial(x_in)) {
        if (runtime.realIsNaN(x_in) or runtime.realIsNegative(x_in)) {
            runtime.realSetNaN(res);
        } else {
            copyReal(res, runtime.z47_math_wrappers_const_plus_infinity());
        }
        return;
    }

    if (realCompareLessEqual(x_in, runtime.z47_math_wrappers_const_0())) {
        if (runtime.realIsNegative(x_in)) {
            runtime.realSetNaN(res);
        } else {
            copyReal(res, runtime.z47_math_wrappers_const_minus_infinity());
        }
        return;
    }

    copyReal(&z, x_in);
    copyReal(&f, runtime.z47_math_wrappers_const_2());
    runtime.realSubtract(x_in, runtime.z47_math_wrappers_const_1(), &t, real_context);
    copyReal(&v, &t);
    runtime.realSetPositiveSign(&v);

    if (realCompareGreaterThan(&v, runtime.z47_math_wrappers_const_1on2())) {
        exponent_adjust = z.exponent + z.digits;
        z.exponent = -z.digits;
    }

    copyReal(&root2on2, runtime.z47_math_wrappers_const_1on2());
    runtime.realSquareRoot(&root2on2, &root2on2, real_context);

    while (realCompareLessEqual(&z, &root2on2)) {
        runtime.realMultiply(&f, runtime.z47_math_wrappers_const_2(), &f, real_context);
        runtime.realSquareRoot(&z, &z, real_context);
    }

    runtime.realAdd(&z, runtime.z47_math_wrappers_const_1(), &t, real_context);
    runtime.realSubtract(&z, runtime.z47_math_wrappers_const_1(), &v, real_context);
    runtime.realDivide(&v, &t, &n, real_context);
    copyReal(&v, &n);
    runtime.realMultiply(&v, &v, &m, real_context);
    runtime.int32ToReal(3, &i);

    runtime.int32ToReal(1 - real_context.digits, &t);
    math_command_wrappers.realPower10(&t, &z, real_context);

    while (true) {
        runtime.realMultiply(&m, &n, &n, real_context);
        runtime.realDivide(&n, &i, &e, real_context);
        runtime.realAdd(&v, &e, &w, real_context);
        if (runtime.WP34S_RelativeError(&w, &v, &z, real_context)) {
            break;
        }
        copyReal(&v, &w);
        runtime.realAdd(&i, runtime.z47_math_wrappers_const_2(), &i, real_context);
    }

    runtime.realMultiply(&f, &w, res, real_context);
    if (exponent_adjust == 0) {
        return;
    }

    runtime.int32ToReal(exponent_adjust, &e);
    runtime.realMultiply(&e, runtime.z47_math_wrappers_const_ln10(), &w, real_context);
    runtime.realAdd(res, &w, res, real_context);
}

pub fn expM1Complex(
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    res_real: *runtime.real_t,
    res_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    var z2_real: runtime.real_t = undefined;
    var z2_imag: runtime.real_t = undefined;
    var e_real: runtime.real_t = undefined;
    var e_imag: runtime.real_t = undefined;

    if (runtime.realIsZero(imag)) {
        if (runtime.realIsInfinite(real) and runtime.realIsNegative(real)) {
            copyReal(res_real, runtime.z47_math_wrappers_const_minus_1());
            runtime.realSetZero(res_imag);
            return;
        }

        realExpM1(real, res_real, real_context);
        runtime.realSetZero(res_imag);
        return;
    }

    if (runtime.realIsSpecial(real) or runtime.realIsSpecial(imag)) {
        runtime.realSetNaN(res_real);
        runtime.realSetNaN(res_imag);
        return;
    }

    runtime.realMultiply(real, runtime.z47_math_wrappers_const_1on2(), &z2_real, real_context);
    runtime.realMultiply(imag, runtime.z47_math_wrappers_const_1on2(), &z2_imag, real_context);
    expComplex(&z2_real, &z2_imag, &e_real, &e_imag, real_context);
    runtime.realChangeSign(&e_real);
    runtime.realAdd(&e_real, &e_real, &e_real, real_context);
    runtime.realAdd(&e_imag, &e_imag, &e_imag, real_context);

    runtime.realChangeSign(&z2_imag);
    math_command_wrappers.sinComplex(&z2_imag, &z2_real, &z2_real, &z2_imag, real_context);
    runtime.mulComplexComplex(&z2_real, &z2_imag, &e_imag, &e_real, res_real, res_imag, real_context);
}

pub fn lnReal() callconv(.c) void {
    var x: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsZero(&x)) {
        if (!runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            return;
        }

        copyReal(&x, runtime.z47_math_wrappers_const_minus_infinity());
    } else if (runtime.realIsInfinite(&x)) {
        if (!runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            return;
        }

        if (!runtime.realIsNegative(&x)) {
            copyReal(&x, runtime.z47_math_wrappers_const_plus_infinity());
        } else if (runtime.getFlag(@intCast(runtime.FLAG_CPXRES))) {
            runtime.convertComplexToResultRegister(runtime.z47_math_wrappers_const_plus_infinity(), runtime.z47_math_wrappers_const_pi(), runtime.REGISTER_X);
            return;
        } else {
            runtime.realSetNaN(&x);
        }
    } else if (!runtime.realIsNegative(&x)) {
        lnRealValue(&x, &x, &runtime.ctxtReal39);
    } else if (runtime.getFlag(@intCast(runtime.FLAG_CPXRES))) {
        runtime.realSetPositiveSign(&x);
        lnRealValue(&x, &x, &runtime.ctxtReal39);
        copyReal(&imag_value, runtime.z47_math_wrappers_const_pi());
        runtime.convertComplexToResultRegister(&x, &imag_value, runtime.REGISTER_X);
        return;
    } else if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.realSetNaN(&x);
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        return;
    }

    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
}

pub fn lnCplx() callconv(.c) void {
    var x_real: runtime.real_t = undefined;
    var x_imag: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &x_real, &x_imag)) {
        return;
    }

    if (runtime.realIsZero(&x_real) and runtime.realIsZero(&x_imag)) {
        if (!runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            return;
        }

        copyReal(&x_real, runtime.z47_math_wrappers_const_minus_infinity());
        runtime.realSetZero(&x_imag);
    } else {
        ln_complex_owned.lnComplex(&x_real, &x_imag, &x_real, &x_imag, &runtime.ctxtReal39);
    }

    runtime.convertComplexToResultRegister(&x_real, &x_imag, runtime.REGISTER_X);
}

pub fn lnP1Complex(
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    ln_real: *runtime.real_t,
    ln_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    var magnitude: runtime.real_t = undefined;
    var dummy: runtime.real_t = undefined;
    var trailing_sum: runtime.real_t = undefined;
    var threshold = std.mem.zeroes(runtime.real_t);

    defer runtime.realAdd(real, runtime.z47_math_wrappers_const_1(), &trailing_sum, real_context);

    threshold.digits = 1;
    threshold.exponent = -6;
    threshold.lsu[0] = 1;

    rectangular_to_polar_owned.rectangularToPolarReal(real, imag, &magnitude, &dummy, real_context);
    if (realAbsLessThan(&magnitude, &threshold)) {
        var term_real: runtime.real_t = undefined;
        var term_imag: runtime.real_t = undefined;
        var sum_real: runtime.real_t = undefined;
        var sum_imag: runtime.real_t = undefined;

        copyReal(&term_real, real);
        copyReal(&term_imag, imag);
        copyReal(&sum_real, real);
        copyReal(&sum_imag, imag);

        const iterations: i32 = @divTrunc(real_context.digits, 5) | 1;
        var index: i32 = 1;
        while (index <= iterations) : (index += 1) {
            var next_real: runtime.real_t = undefined;
            var next_imag: runtime.real_t = undefined;
            var divisor: runtime.real_t = undefined;
            var contribution: runtime.real_t = undefined;

            runtime.mulComplexComplex(&term_real, &term_imag, real, imag, &next_real, &next_imag, real_context);
            copyReal(&term_real, &next_real);
            copyReal(&term_imag, &next_imag);
            runtime.int32ToReal(index + 1, &divisor);

            if ((index & 1) == 1) {
                runtime.realDivide(&term_real, &divisor, &contribution, real_context);
                runtime.realSubtract(&sum_real, &contribution, &sum_real, real_context);
                runtime.realDivide(&term_imag, &divisor, &contribution, real_context);
                runtime.realSubtract(&sum_imag, &contribution, &sum_imag, real_context);
            } else {
                runtime.realDivide(&term_real, &divisor, &contribution, real_context);
                runtime.realAdd(&sum_real, &contribution, &sum_real, real_context);
                runtime.realDivide(&term_imag, &divisor, &contribution, real_context);
                runtime.realAdd(&sum_imag, &contribution, &sum_imag, real_context);
            }
        }

        copyReal(ln_real, &sum_real);
        copyReal(ln_imag, &sum_imag);
        return;
    }

    var one_plus_real: runtime.real_t = undefined;

    runtime.realAdd(real, runtime.z47_math_wrappers_const_1(), &one_plus_real, real_context);
    if (runtime.realIsZero(&one_plus_real) and runtime.realIsZero(imag)) {
        copyReal(ln_real, runtime.z47_math_wrappers_const_minus_infinity());
        runtime.realSetZero(ln_imag);
        return;
    }

    rectangular_to_polar_owned.rectangularToPolarReal(&one_plus_real, imag, ln_real, ln_imag, real_context);
    lnRealValue(ln_real, ln_real, real_context);
}

pub fn expM1Real() callconv(.c) void {
    var x: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsInfinite(&x) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.z47_math_wrappers_report_exp_m1_real_domain_error();
        return;
    }

    realExpM1(&x, &x, &runtime.ctxtReal39);
    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
}

pub fn expM1Cplx() callconv(.c) void {
    var z_real: runtime.real_t = undefined;
    var z_imag: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &z_real, &z_imag)) {
        return;
    }

    expM1Complex(&z_real, &z_imag, &z_real, &z_imag, &runtime.ctxtReal75);
    runtime.convertComplexToResultRegister(&z_real, &z_imag, runtime.REGISTER_X);
}

pub fn lnP1Real() callconv(.c) void {
    var arg: runtime.real_t = undefined;
    var shifted: runtime.real_t = undefined;
    var result: runtime.real_t = undefined;
    var imag_part: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &arg)) {
        return;
    }

    runtime.realAdd(&arg, runtime.z47_math_wrappers_const_1(), &shifted, &runtime.ctxtReal39);
    if (runtime.realIsZero(&shifted)) {
        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            copyReal(&result, runtime.z47_math_wrappers_const_minus_infinity());
        } else {
            runtime.z47_math_wrappers_report_ln_p1_real_zero_domain_error();
            return;
        }
    } else if (runtime.realIsInfinite(&shifted)) {
        if (!runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.z47_math_wrappers_report_ln_p1_real_infinite_domain_error();
            return;
        } else if (runtime.getFlag(@intCast(runtime.FLAG_CPXRES))) {
            if (!runtime.realIsNegative(&shifted)) {
                copyReal(&result, runtime.z47_math_wrappers_const_plus_infinity());
            } else {
                runtime.convertComplexToResultRegister(
                    runtime.z47_math_wrappers_const_plus_infinity(),
                    runtime.z47_math_wrappers_const_pi(),
                    runtime.REGISTER_X,
                );
                return;
            }
        } else {
            runtime.realSetNaN(&result);
        }
    } else if (!runtime.realIsNegative(&shifted)) {
        runtime.WP34S_Ln1P(&arg, &result, &runtime.ctxtReal39);
    } else if (runtime.getFlag(@intCast(runtime.FLAG_CPXRES))) {
        lnP1Complex(&arg, runtime.z47_math_wrappers_const_0(), &result, &imag_part, &runtime.ctxtReal75);
        runtime.convertComplexToResultRegister(&result, runtime.z47_math_wrappers_const_pi(), runtime.REGISTER_X);
        return;
    } else if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.realSetNaN(&result);
    } else {
        runtime.z47_math_wrappers_report_ln_p1_real_negative_domain_error();
        return;
    }

    runtime.convertRealToResultRegister(&result, runtime.REGISTER_X, runtime.amNone);
}

pub fn lnP1Cplx() callconv(.c) void {
    var x_real: runtime.real_t = undefined;
    var x_imag: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &x_real, &x_imag)) {
        return;
    }

    if (runtime.realIsZero(&x_imag) and runtime.realCompareEqual(&x_real, runtime.z47_math_wrappers_const_minus_1())) {
        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            copyReal(&x_real, runtime.z47_math_wrappers_const_minus_infinity());
            runtime.realSetZero(&x_imag);
        } else {
            runtime.z47_math_wrappers_report_ln_p1_cplx_zero_domain_error();
            return;
        }
    } else {
        lnP1Complex(&x_real, &x_imag, &x_real, &x_imag, &runtime.ctxtReal75);
    }

    runtime.convertComplexToResultRegister(&x_real, &x_imag, runtime.REGISTER_X);
}

pub fn expReal() callconv(.c) void {
    var x: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsInfinite(&x) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.z47_math_wrappers_report_exp_real_domain_error();
        return;
    }

    realExp(&x, &x, &runtime.ctxtReal39);
    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
}

pub fn expCplx() callconv(.c) void {
    var z_real: runtime.real_t = undefined;
    var z_imag: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &z_real, &z_imag)) {
        return;
    }

    expComplex(&z_real, &z_imag, &z_real, &z_imag, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&z_real, &z_imag, runtime.REGISTER_X);
}

pub fn exp(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&expReal, &expCplx);
}

pub fn expM1(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&expM1Real, &expM1Cplx);
}

pub fn ln(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&lnReal, &lnCplx);
}

pub fn lnP1(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&lnP1Real, &lnP1Cplx);
}
