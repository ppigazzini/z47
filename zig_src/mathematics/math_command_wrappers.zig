const runtime = @import("math_command_wrappers_runtime.zig");

const no_register = @as(runtime.calcRegister_t, -1);
const PowRealFn = *const fn (x: *const runtime.real_t, res: *runtime.real_t, real_context: *runtime.realContext_t) callconv(.c) void;
const long_integer_power_negative_exponent: i32 = -1;

fn copyReal(destination: *runtime.real_t, source: *const runtime.real_t) void {
    destination.* = source.*;
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

    runtime.C47_WP34S_Cvt2RadSinCosTan(real, runtime.amRadian, &sina, &cosa, null, real_context);
    runtime.WP34S_SinhCosh(imag, &sinhb, &coshb, real_context);
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

    runtime.C47_WP34S_Cvt2RadSinCosTan(real, runtime.amRadian, &sina, &cosa, null, real_context);
    runtime.WP34S_SinhCosh(imag, &sinhb, &coshb, real_context);
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
        runtime.C47_WP34S_Cvt2RadSinCosTan(&x, x_angular_mode, &x, null, null, &runtime.ctxtReal75);
    } else {
        runtime.C47_WP34S_Cvt2RadSinCosTan(&x, x_angular_mode, null, &x, null, &runtime.ctxtReal75);
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
        runtime.WP34S_SinhCosh(&x, &x, null, &runtime.ctxtReal39);
    } else {
        runtime.WP34S_SinhCosh(&x, null, &x, &runtime.ctxtReal39);
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

    runtime.WP34S_SinhCosh(&a, &sinha, &cosha, &runtime.ctxtReal39);
    runtime.C47_WP34S_Cvt2RadSinCosTan(&b, runtime.amRadian, &sinb, &cosb, null, &runtime.ctxtReal39);

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

    runtime.C47_WP34S_Cvt2RadSinCosTan(x_real, runtime.amRadian, &sina, &cosa, null, real_context);
    runtime.WP34S_SinhCosh(x_imag, &sinhb, &coshb, real_context);

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
        runtime.WP34S_Tanh(x_real, r_real, &runtime.ctxtReal39);
        runtime.realSetZero(r_imag);
    } else {
        runtime.WP34S_Tanh(x_real, r_real, &runtime.ctxtReal39);
        runtime.C47_WP34S_Cvt2RadSinCosTan(x_imag, runtime.amRadian, &sin_value, &cos_value, r_imag, &runtime.ctxtReal39);

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

pub export fn realExp(
    x: *const runtime.real_t,
    result: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    if (realExpLimitCheck(x, result, runtime.z47_math_wrappers_const_0())) {
        _ = runtime.decNumberExp(result, x, real_context);
    }
}

pub export fn expComplex(
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    res_real: *runtime.real_t,
    res_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
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
    runtime.C47_WP34S_Cvt2RadSinCosTan(imag, runtime.amRadian, &sin_value, &cos_value, null, real_context);
    runtime.realMultiply(&exp_real, &cos_value, res_real, real_context);
    runtime.realMultiply(&exp_real, &sin_value, res_imag, real_context);
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

fn tenPowLonI() callconv(.c) void {
    if (runtime.z47_math_wrappers_small_base_power_long_integer(10) == long_integer_power_negative_exponent) {
        tenPowReal();
    }
}

fn twoPowLonI() callconv(.c) void {
    if (runtime.z47_math_wrappers_small_base_power_long_integer(2) == long_integer_power_negative_exponent) {
        twoPowReal();
    }
}

fn twoPowShoI() callconv(.c) void {
    runtime.registerShortIntegerPtr(runtime.REGISTER_X).* = runtime.WP34S_int2pow(
        runtime.registerShortIntegerPtr(runtime.REGISTER_X).*,
    );
}

fn twoPowReal() callconv(.c) void {
    intPowReal(realPower2);
}

fn twoPowCplx() callconv(.c) void {
    intPowCplx(runtime.z47_math_wrappers_const_ln2());
}

fn tenPowShoI() callconv(.c) void {
    runtime.registerShortIntegerPtr(runtime.REGISTER_X).* = runtime.WP34S_int10pow(
        runtime.registerShortIntegerPtr(runtime.REGISTER_X).*,
    );
}

fn tenPowReal() callconv(.c) void {
    intPowReal(realPower10);
}

fn tenPowCplx() callconv(.c) void {
    intPowCplx(runtime.z47_math_wrappers_const_ln10());
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

fn ceilReal() callconv(.c) void {
    runtime.integerPartReal(runtime.DEC_ROUND_CEILING);
}

fn ceilCplx() callconv(.c) void {
    runtime.integerPartCplx(runtime.DEC_ROUND_CEILING);
}

fn floorReal() callconv(.c) void {
    runtime.integerPartReal(runtime.DEC_ROUND_FLOOR);
}

fn floorCplx() callconv(.c) void {
    runtime.integerPartCplx(runtime.DEC_ROUND_FLOOR);
}

fn integerPartNoOpForward() callconv(.c) void {
    runtime.integerPartNoOp();
}

fn coshReal() callconv(.c) void {
    sinhCoshReal(runtime.trigCos);
}

fn coshCplx() callconv(.c) void {
    sinhCoshCplx(runtime.trigCos);
}

fn sinReal() callconv(.c) void {
    sinCosReal(runtime.trigSin);
}

fn sinCplx() callconv(.c) void {
    sinCosCplx(runtime.trigSin);
}

fn cosReal() callconv(.c) void {
    sinCosReal(runtime.trigCos);
}

fn cosCplx() callconv(.c) void {
    sinCosCplx(runtime.trigCos);
}

fn sinhReal() callconv(.c) void {
    sinhCoshReal(runtime.trigSin);
}

fn sinhCplx() callconv(.c) void {
    sinhCoshCplx(runtime.trigSin);
}

fn tanhReal() callconv(.c) void {
    var x: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsInfinite(&x) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.z47_math_wrappers_report_tanh_real_domain_error();
        return;
    }

    runtime.WP34S_Tanh(&x, &x, &runtime.ctxtReal39);
    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
}

fn tanhCplx() callconv(.c) void {
    var x_real: runtime.real_t = undefined;
    var x_imag: runtime.real_t = undefined;
    var r_real: runtime.real_t = undefined;
    var r_imag: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &x_real, &x_imag)) {
        return;
    }

    _ = TanhComplex(&x_real, &x_imag, &r_real, &r_imag, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&r_real, &r_imag, runtime.REGISTER_X);
}

fn expReal() callconv(.c) void {
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

fn expCplx() callconv(.c) void {
    var z_real: runtime.real_t = undefined;
    var z_imag: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &z_real, &z_imag)) {
        return;
    }

    expComplex(&z_real, &z_imag, &z_real, &z_imag, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&z_real, &z_imag, runtime.REGISTER_X);
}

fn tanReal() callconv(.c) void {
    var sin_value: runtime.real_t = undefined;
    var cos_value: runtime.real_t = undefined;
    var tan_value: runtime.real_t = undefined;
    var x_angular_mode: runtime.angularMode_t = undefined;

    if (!runtime.getRegisterAsRealAngle(runtime.REGISTER_X, &tan_value, &x_angular_mode, runtime.ifLongIntegerDoAngleReduction)) {
        return;
    }

    if (runtime.realIsSpecial(&tan_value)) {
        runtime.realSetNaN(&tan_value);
    } else {
        runtime.C47_WP34S_Cvt2RadSinCosTan(&tan_value, x_angular_mode, &sin_value, &cos_value, &tan_value, &runtime.ctxtReal75);
        if (runtime.realIsZero(&sin_value)) {
            runtime.realSetPositiveSign(&tan_value);
        }

        if (runtime.realIsZero(&cos_value) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.z47_math_wrappers_report_tan_real_pole_error();
            return;
        }

        if (runtime.realIsZero(&cos_value)) {
            runtime.realSetNaN(&tan_value);
        }
    }

    runtime.convertRealToResultRegister(&tan_value, runtime.REGISTER_X, runtime.amNone);
}

fn tanCplx() callconv(.c) void {
    var x_real: runtime.real_t = undefined;
    var x_imag: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &x_real, &x_imag)) {
        return;
    }

    _ = TanComplex(&x_real, &x_imag, &x_real, &x_imag, &runtime.ctxtReal51);
    runtime.convertComplexToResultRegister(&x_real, &x_imag, runtime.REGISTER_X);
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
    runtime.z47_math_wrappers_change_sign_long_integer();
}

fn changeSignTime() void {
    const x = runtime.registerReal34Ptr(runtime.REGISTER_X);
    x.bytes[15] ^= runtime.DECNEG;

    if (runtime.real34IsZero(x) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        x.bytes[15] &= 0x7f;
    }
}

fn squareLonI() callconv(.c) void {
    runtime.z47_math_wrappers_square_long_integer();
}

fn squareShoI() callconv(.c) void {
    runtime.registerShortIntegerPtr(runtime.REGISTER_X).* = runtime.WP34S_intMultiply(
        runtime.registerShortIntegerPtr(runtime.REGISTER_X).*,
        runtime.registerShortIntegerPtr(runtime.REGISTER_X).*,
    );
}

fn squareReal() callconv(.c) void {
    var x: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsInfinite(&x) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.z47_math_wrappers_report_square_real_domain_error();
        return;
    }

    runtime.realMultiply(&x, &x, &x, &runtime.ctxtReal39);
    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
}

fn squareCplx() callconv(.c) void {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &a, &b)) {
        return;
    }

    runtime.mulComplexComplex(&a, &b, &a, &b, &a, &b, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&a, &b, runtime.REGISTER_X);
}

fn cubeLonI() callconv(.c) void {
    runtime.z47_math_wrappers_cube_long_integer();
}

fn cubeShoI() callconv(.c) void {
    const square = runtime.WP34S_intMultiply(
        runtime.registerShortIntegerPtr(runtime.REGISTER_X).*,
        runtime.registerShortIntegerPtr(runtime.REGISTER_X).*,
    );
    runtime.registerShortIntegerPtr(runtime.REGISTER_X).* = runtime.WP34S_intMultiply(
        square,
        runtime.registerShortIntegerPtr(runtime.REGISTER_X).*,
    );
}

fn cubeReal() callconv(.c) void {
    var x: runtime.real_t = undefined;
    var x_squared: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsInfinite(&x) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.z47_math_wrappers_report_cube_real_domain_error();
        return;
    }

    runtime.realMultiply(&x, &x, &x_squared, &runtime.ctxtReal39);
    runtime.realMultiply(&x_squared, &x, &x, &runtime.ctxtReal39);
    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
}

fn cubeCplx() callconv(.c) void {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;
    var real_square: runtime.real_t = undefined;
    var imag_square: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &a, &b)) {
        return;
    }

    runtime.mulComplexComplex(&a, &b, &a, &b, &real_square, &imag_square, &runtime.ctxtReal39);
    runtime.mulComplexComplex(&real_square, &imag_square, &a, &b, &a, &b, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&a, &b, runtime.REGISTER_X);
}

pub export fn fnMin(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    if (!runtime.saveLastX()) {
        return;
    }

    runtime.registerMin(runtime.REGISTER_X, runtime.REGISTER_Y, runtime.REGISTER_X);
    runtime.adjustResult(runtime.REGISTER_X, true, false, runtime.REGISTER_X, no_register, no_register);
}

pub export fn fnMax(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    if (!runtime.saveLastX()) {
        return;
    }

    runtime.registerMax(runtime.REGISTER_X, runtime.REGISTER_Y, runtime.REGISTER_X);
    runtime.adjustResult(runtime.REGISTER_X, true, false, runtime.REGISTER_X, no_register, no_register);
}

pub export fn fnCeil(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexMonadicFunction(
        &ceilReal,
        &ceilCplx,
        &integerPartNoOpForward,
        &integerPartNoOpForward,
    );
}

pub export fn fnFloor(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexMonadicFunction(
        &floorReal,
        &floorCplx,
        &integerPartNoOpForward,
        &integerPartNoOpForward,
    );
}

pub export fn fnSin(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&sinReal, &sinCplx);
}

pub export fn fnCos(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&cosReal, &cosCplx);
}

pub export fn fnTan(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&tanReal, &tanCplx);
}

pub export fn fnSinh(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&sinhReal, &sinhCplx);
}

pub export fn fnCosh(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&coshReal, &coshCplx);
}

pub export fn fnTanh(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&tanhReal, &tanhCplx);
}

pub export fn fnExp(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&expReal, &expCplx);
}

pub export fn fn2Pow(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexMonadicFunction(&twoPowReal, &twoPowCplx, &twoPowShoI, &twoPowLonI);
}

pub export fn fn10Pow(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexMonadicFunction(&tenPowReal, &tenPowCplx, &tenPowShoI, &tenPowLonI);
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
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexMonadicFunction(&squareReal, &squareCplx, &squareShoI, &squareLonI);
}

pub export fn fnCube(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexMonadicFunction(&cubeReal, &cubeCplx, &cubeShoI, &cubeLonI);
}
