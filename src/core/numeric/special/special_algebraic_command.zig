const abi = @import("abi");
const runtime = @import("../command_wrappers/runtime.zig");
const transcendental_command_owned = @import("transcendental_command.zig");
const math_wp34s = @import("wp34s.zig");

const real_t = runtime.real_t;
const cplx_t = runtime.cplx_t;
const realContext_t = runtime.realContext_t;

const std_plus_minus = "\x80\xb1"; // STD_PLUS_MINUS
const std_infinity = "\xa2\x1e"; // STD_INFINITY

fn copyReal(destination: *real_t, source: *const real_t) void {
    destination.* = source.*;
}

// realDivideBy2: a multiplication by 1/2 in place.
fn realDivideBy2(operand: *real_t, real_context: *realContext_t) void {
    runtime.realMultiply(operand, runtime.z47_math_wrappers_const_1on2(), operand, real_context);
}

pub fn sqrt1Px2Complex(
    z: *const cplx_t,
    res: *cplx_t,
    real_context: *realContext_t,
) callconv(.c) void {
    var magnitude: real_t = undefined;
    var w: cplx_t = undefined;

    if (runtime.realIsZero(&z.Imag)) {
        if (runtime.realIsInfinite(&z.Real)) {
            copyReal(&res.Real, runtime.z47_math_wrappers_const_plus_infinity());
            runtime.realSetZero(&res.Imag);
            return;
        }
        runtime.realFMA(&z.Real, &z.Real, runtime.z47_math_wrappers_const_1(), &res.Real, real_context);
        runtime.realSquareRoot(&res.Real, &res.Real, real_context);
        runtime.realSetZero(&res.Imag);
        return;
    }

    if (runtime.realIsSpecial(&z.Real) or runtime.realIsSpecial(&z.Imag)) {
        runtime.realSetNaN(&res.Real);
        runtime.realSetNaN(&res.Imag);
        return;
    }

    // sqrt(1 + a^2 - b^2 + 2 a b i)
    runtime.realFMA(&z.Imag, &z.Imag, runtime.z47_math_wrappers_const_minus_1(), &w.Real, real_context);
    runtime.realChangeSign(&w.Real);
    runtime.realFMA(&z.Real, &z.Real, &w.Real, &w.Real, real_context);
    runtime.realAdd(&z.Real, &z.Real, &w.Imag, real_context);
    runtime.realMultiply(&w.Imag, &z.Imag, &w.Imag, real_context);

    if (runtime.realIsZero(&w.Imag)) {
        runtime.sqrtComplex(&w, res, real_context);
    } else {
        runtime.complexMagnitude(&w, &magnitude, real_context);
        if (runtime.realIsNegative(&w.Real)) {
            runtime.realSubtract(&magnitude, &w.Real, &res.Imag, real_context);
            realDivideBy2(&res.Imag, real_context);
            runtime.realSquareRoot(&res.Imag, &res.Imag, real_context);
            if (runtime.realIsNegative(&w.Imag)) {
                runtime.realChangeSign(&res.Imag);
            }
            runtime.realDivide(&w.Imag, &res.Imag, &res.Real, real_context);
            realDivideBy2(&res.Real, real_context);
        } else {
            runtime.realAdd(&magnitude, &w.Real, &res.Real, real_context);
            realDivideBy2(&res.Real, real_context);
            runtime.realSquareRoot(&res.Real, &res.Real, real_context);
            runtime.realDivide(&w.Imag, &res.Real, &res.Imag, real_context);
            realDivideBy2(&res.Imag, real_context);
        }
    }
}

fn sqrt1Px2Real() callconv(.c) void {
    var magnitude: real_t = undefined;
    var x: real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsInfinite(&x) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
        if (runtime.extra_info_on_calc_error) {
            runtime.moreInfoOnError("In function sqrt1Px2Real:", "cannot use " ++ std_plus_minus ++ std_infinity ++ " as X input of exp when flag SPCRES is not set", null, null);
        }
        return;
    }

    if (runtime.realIsInfinite(&x)) {
        copyReal(&x, runtime.z47_math_wrappers_const_plus_infinity());
    } else if (runtime.realIsSpecial(&x)) {
        runtime.realSetNaN(&x);
    } else {
        copyReal(&magnitude, &x);
        runtime.realSetPositiveSign(&magnitude);
        runtime.realFMA(&x, &x, runtime.z47_math_wrappers_const_1(), &x, &runtime.ctxtReal39);
        runtime.realSquareRoot(&x, &x, &runtime.ctxtReal39);
        if (runtime.realCompareEqual(&x, &magnitude)) {
            runtime.realNextToward(&x, runtime.z47_math_wrappers_const_plus_infinity(), &x, &runtime.ctxtReal39);
        }
    }

    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
}

fn sqrt1Px2Cplx() callconv(.c) void {
    var z: cplx_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &z)) {
        return;
    }

    sqrt1Px2Complex(&z, &z, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&z, runtime.REGISTER_X);
}

fn m1PowLonI() callconv(.c) void {
    var result: runtime.longInteger_t = undefined;
    var exponent: runtime.longInteger_t = undefined;

    runtime.__gmpz_init(&result[0]);
    defer runtime.__gmpz_clear(&result[0]);
    runtime.__gmpz_set_ui(&result[0], 1);

    runtime.convertLongIntegerRegisterToLongInteger(runtime.REGISTER_X, &exponent[0]);
    defer runtime.__gmpz_clear(&exponent[0]);

    if (runtime.longIntegerIsOdd(&exponent[0])) {
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

// (-1)^x on an exact axis: the sector is 2x reduced to 0..3 and picks which
// axis carries the magnitude.
fn setM1PowAxis(magnitude: *const real_t, sector: *real_t, res: *cplx_t) void {
    if (runtime.realIsNegative(sector) and !runtime.realIsZero(sector)) {
        runtime.realAdd(sector, abi.constants.const_4(), sector, &runtime.ctxtReal39);
    }
    const sector_index = runtime.realToInt32C47(sector, null);

    runtime.realSetZero(&res.Real);
    runtime.realSetZero(&res.Imag);
    switch (sector_index) {
        0 => copyReal(&res.Real, magnitude),
        1 => copyReal(&res.Imag, magnitude),
        2 => {
            copyReal(&res.Real, magnitude);
            runtime.realChangeSign(&res.Real);
        },
        3 => {
            copyReal(&res.Imag, magnitude);
            runtime.realChangeSign(&res.Imag);
        },
        else => {
            runtime.realSetNaN(&res.Real);
            runtime.realSetNaN(&res.Imag);
        },
    }
}

fn m1PowReal() callconv(.c) void {
    var z: cplx_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &z.Real)) {
        return;
    }

    if (runtime.realIsInfinite(&z.Real) or runtime.realIsNaN(&z.Real)) {
        runtime.convertRealToResultRegister(abi.constants.const_NaN(), runtime.REGISTER_X, runtime.amNone);
        return;
    }

    runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.amNone);

    runtime.WP34S_Mod(&z.Real, runtime.z47_math_wrappers_const_2(), &z.Real, &runtime.ctxtReal39);
    if (runtime.realIsZero(&z.Real)) {
        runtime.convertRealToResultRegister(runtime.z47_math_wrappers_const_1(), runtime.REGISTER_X, runtime.amNone);
    } else if (runtime.realCompareAbsEqual(&z.Real, runtime.z47_math_wrappers_const_1())) {
        runtime.convertRealToResultRegister(runtime.z47_math_wrappers_const_minus_1(), runtime.REGISTER_X, runtime.amNone);
    } else { // Complex result
        runtime.fnSetFlag(runtime.FLAG_CPXRES);
        runtime.fnRefreshState();

        // Euler's formula takes its angle in radians; the display mode goes back
        // afterwards, so the result carries the POLAR tag the user chose.
        const saved_angular_mode = runtime.currentAngularMode;
        runtime.currentAngularMode = runtime.amRadian;

        runtime.realMultiply(&z.Real, runtime.z47_math_wrappers_const_2(), &z.Imag, &runtime.ctxtReal39);
        if (runtime.realIsAnInteger(&z.Imag)) {
            setM1PowAxis(runtime.z47_math_wrappers_const_1(), &z.Imag, &z);
        } else {
            runtime.realMultiply(&z.Real, runtime.z47_math_wrappers_const_pi(), &z.Real, &runtime.ctxtReal39);
            runtime.realSetZero(&z.Imag);
            eulersFormula(&z, &z, &runtime.ctxtReal39);
        }

        runtime.convertComplexToResultRegister(&z, runtime.REGISTER_X);
        runtime.currentAngularMode = saved_angular_mode;
        return;
    }
}

fn m1PowCplx() callconv(.c) void {
    var sector: real_t = undefined;
    var magnitude: real_t = undefined;
    var z: cplx_t = undefined;

    runtime.fnSetFlag(runtime.FLAG_CPXRES);
    runtime.fnRefreshState();
    runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.amNone);

    runtime.real34ToReal(runtime.registerReal34Ptr(runtime.REGISTER_X), &z.Real);
    runtime.WP34S_Mod(&z.Real, runtime.z47_math_wrappers_const_2(), &z.Real, &runtime.ctxtReal39);

    runtime.real34ToReal(runtime.registerImag34Ptr(runtime.REGISTER_X), &z.Imag);
    if (runtime.realIsZero(&z.Imag)) {
        if (runtime.realIsZero(&z.Real)) {
            runtime.convertComplexPartsToResultRegister(runtime.z47_math_wrappers_const_1(), runtime.z47_math_wrappers_const_0(), runtime.REGISTER_X);
            return;
        } else if (runtime.realCompareAbsEqual(&z.Real, runtime.z47_math_wrappers_const_1())) {
            runtime.convertComplexPartsToResultRegister(runtime.z47_math_wrappers_const_minus_1(), runtime.z47_math_wrappers_const_0(), runtime.REGISTER_X);
            return;
        }
    }

    if (!runtime.realIsNaN(&z.Real) and !runtime.realIsNaN(&z.Imag)) {
        runtime.realMultiply(&z.Real, runtime.z47_math_wrappers_const_2(), &sector, &runtime.ctxtReal39);
        if (runtime.realIsAnInteger(&sector)) {
            runtime.realMultiply(&z.Imag, runtime.z47_math_wrappers_const75_pi(), &magnitude, &runtime.ctxtReal51);
            runtime.realChangeSign(&magnitude);
            transcendental_command_owned.realExp(&magnitude, &magnitude, &runtime.ctxtReal51);
            setM1PowAxis(&magnitude, &sector, &z);
            runtime.convertComplexToResultRegister(&z, runtime.REGISTER_X);
            return;
        }
    }

    const saved_angular_mode = runtime.currentAngularMode;
    runtime.currentAngularMode = runtime.amRadian;

    runtime.mulComplexReal(&z, runtime.z47_math_wrappers_const75_pi(), &z, &runtime.ctxtReal51);
    eulersFormula(&z, &z, &runtime.ctxtReal51);

    runtime.convertComplexToResultRegister(&z, runtime.REGISTER_X);
    runtime.currentAngularMode = saved_angular_mode;
}

pub fn eulersFormula(
    in: *const cplx_t,
    out: *cplx_t,
    ctxt: *realContext_t,
) callconv(.c) void {
    var z: cplx_t = undefined;

    if (runtime.realIsZero(&in.Imag)) {
        copyReal(&z.Real, &in.Real);
        math_wp34s.C47_WP34S_Cvt2RadSinCosTan(&z.Real, runtime.amRadian, &out.Imag, &out.Real, null, ctxt);
        return;
    }

    runtime.mulComplexi(in, &z);
    transcendental_command_owned.expComplex(&z, out, ctxt);
}

fn eulersFormulaCplx() callconv(.c) void {
    var z: cplx_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &z)) {
        return;
    }

    if ((runtime.realIsInfinite(&z.Real) or runtime.realIsInfinite(&z.Imag)) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.z47_math_wrappers_report_eulers_formula_complex_domain_error();
        return;
    }

    if (runtime.realIsInfinite(&z.Real)) {
        runtime.convertComplexPartsToResultRegister(abi.constants.const_NaN(), abi.constants.const_NaN(), runtime.REGISTER_X);
    } else {
        if (runtime.realIsZero(&z.Imag)) {
            eulersFormula(&z, &z, &runtime.ctxtReal34);
        } else {
            eulersFormula(&z, &z, &runtime.ctxtReal39);
        }
        runtime.convertComplexToResultRegister(&z, runtime.REGISTER_X);
    }

    runtime.fnSetFlag(runtime.FLAG_CPXRES);
    runtime.fnRefreshState();
}

fn eulersFormulaReal() callconv(.c) void {
    var angle: real_t = undefined;
    var c: cplx_t = undefined;
    var x_angular_mode: runtime.angularMode_t = runtime.amNone;
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);

    if (register_data_type == runtime.dtLongInteger) {
        if (!runtime.reduceLongIntegerRegisterAngle(runtime.REGISTER_X, runtime.amRadian, &c.Real, true)) {
            return;
        }
    } else if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &c.Real)) {
        return;
    }

    if (runtime.realIsInfinite(&c.Real) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.z47_math_wrappers_report_eulers_formula_real_domain_error();
        return;
    }

    if (register_data_type == runtime.dtReal34) {
        x_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_X);
        if (x_angular_mode != runtime.amNone) {
            copyReal(&angle, &c.Real);
            math_wp34s.C47_WP34S_Cvt2RadSinCosTan(&angle, x_angular_mode, &c.Imag, &c.Real, null, &runtime.ctxtReal34);
        }
    }

    if (register_data_type != runtime.dtReal34 or x_angular_mode == runtime.amNone) {
        runtime.realSetZero(&c.Imag);
        eulersFormula(&c, &c, &runtime.ctxtReal34);
    }

    runtime.convertComplexToResultRegister(&c, runtime.REGISTER_X);
    runtime.fnSetFlag(runtime.FLAG_CPXRES);
    runtime.fnRefreshState();
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
