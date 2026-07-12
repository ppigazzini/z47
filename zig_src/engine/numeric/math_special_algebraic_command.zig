const runtime = @import("math_command_wrappers_runtime.zig");
const transcendental_command_owned = @import("math_transcendental_command.zig");

fn copyReal(destination: *runtime.real_t, source: *const runtime.real_t) void {
    destination.* = source.*;
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
            runtime.realChangeSign(&a);
            runtime.realSquareRoot(&a, res_imag, real_context);
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

pub fn sqrt1Px2Complex(
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

pub fn eulersFormula(
    in_real: *const runtime.real_t,
    in_imag: *const runtime.real_t,
    out_real: *runtime.real_t,
    out_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    var z_real: runtime.real_t = undefined;
    var z_imag: runtime.real_t = undefined;

    runtime.mulComplexi(in_real, in_imag, &z_real, &z_imag);
    transcendental_command_owned.expComplex(&z_real, &z_imag, out_real, out_imag, real_context);
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

pub fn fnSqrt1Px2(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processRealComplexMonadicFunction(&sqrt1Px2Real, &sqrt1Px2Cplx);
}

pub fn fnM1Pow(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processIntRealComplexMonadicFunction(&m1PowReal, &m1PowCplx, &m1PowShoI, &m1PowLonI);
}

pub fn fnEulersFormula(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processRealComplexMonadicFunction(&eulersFormulaReal, &eulersFormulaCplx);
}
