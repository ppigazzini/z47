const runtime = @import("../command_wrappers/runtime.zig");

const real_t = runtime.real_t;
const cplx_t = runtime.cplx_t;
const realContext_t = runtime.realContext_t;

fn copyReal(destination: *real_t, source: *const real_t) void {
    destination.* = source.*;
}

fn setPlusInfinity(value: *real_t) void {
    copyReal(value, runtime.z47_math_wrappers_const_plus_infinity());
}

fn setNegativeSign(value: *real_t) void {
    value.bits |= 0x80; // DECNEG
}

// Complex sinc from its power series, for |Re z| and |Im z| below 1/10.
fn sincComplexSeries(z: *const cplx_t, res: *cplx_t, real_context: *realContext_t) void {
    var z2: cplx_t = undefined;
    var term: cplx_t = undefined;
    var next: cplx_t = undefined;
    var previous: cplx_t = undefined;
    var divisor: real_t = undefined;

    runtime.mulComplexComplex(z, z, &z2, real_context);
    runtime.realSetOne(&term.Real);
    runtime.realSetZero(&term.Imag);
    runtime.realSetZero(&res.Real);
    runtime.realSetZero(&res.Imag);

    var n: i32 = 1;
    while (n < 1000) : (n += 1) {
        runtime.mulComplexComplex(&term, &z2, &next, real_context);
        runtime.realChangeSign(&next.Real);
        runtime.realChangeSign(&next.Imag);
        runtime.int32ToReal((2 * n) * (2 * n + 1), &divisor);
        runtime.realDivide(&next.Real, &divisor, &term.Real, real_context);
        runtime.realDivide(&next.Imag, &divisor, &term.Imag, real_context);
        copyReal(&previous.Real, &res.Real);
        copyReal(&previous.Imag, &res.Imag);
        runtime.realAdd(&res.Real, &term.Real, &res.Real, real_context);
        runtime.realAdd(&res.Imag, &term.Imag, &res.Imag, real_context);
        if (runtime.realCompareEqual(&res.Real, &previous.Real) and runtime.realCompareEqual(&res.Imag, &previous.Imag)) {
            break;
        }
    }

    copyReal(&previous.Real, &res.Real);
    runtime.realAdd(runtime.z47_math_wrappers_const_1(), &previous.Real, &res.Real, real_context);
    if (!runtime.realIsZero(&previous.Real) and runtime.realCompareEqual(&res.Real, runtime.z47_math_wrappers_const_1())) {
        runtime.realNextToward(&res.Real, if (runtime.realIsNegative(&previous.Real)) runtime.z47_math_wrappers_const_0() else runtime.z47_math_wrappers_const_2(), &res.Real, real_context);
    }
}

pub fn sincComplex(z: *const cplx_t, res: *cplx_t, real_context: *realContext_t) void {
    // sin(a + ib) = sin(a)*cosh(b) + i*cos(a)*sinh(b)
    // sinc (a + ib) = sin(a + ib) / (a + ib), for the allowable conditions
    var x: cplx_t = undefined;

    copyReal(&x.Real, &z.Real);
    copyReal(&x.Imag, &z.Imag);

    if (runtime.realIsZero(&x.Real) and runtime.realIsZero(&x.Imag)) {
        runtime.realSetOne(&res.Real);
        runtime.realSetZero(&res.Imag);
    } else if (runtime.realCompareAbsLessThan(&x.Real, runtime.z47_math_wrappers_const_1on10()) and runtime.realCompareAbsLessThan(&x.Imag, runtime.z47_math_wrappers_const_1on10())) {
        sincComplexSeries(&x, res, real_context);
    } else if (runtime.realIsZero(&x.Real) and !runtime.realIsSpecial(&x.Imag)) {
        runtime.WP34S_SinhCosh(&x.Imag, &res.Real, null, real_context);
        runtime.realDivide(&res.Real, &x.Imag, &res.Real, real_context);
        runtime.realSetZero(&res.Imag);
    } else {
        var sina: real_t = undefined;
        var cosa: real_t = undefined;
        var sinhb: real_t = undefined;
        var coshb: real_t = undefined;
        var sinZ: cplx_t = undefined;

        runtime.C47_WP34S_Cvt2RadSinCosTan(&z.Real, runtime.amRadian, &sina, &cosa, null, real_context);
        runtime.WP34S_SinhCosh(&z.Imag, &sinhb, &coshb, real_context);

        if (!runtime.realIsSpecial(&x.Real) and !runtime.realIsSpecial(&x.Imag) and (runtime.realIsInfinite(&sinhb) or runtime.realIsInfinite(&coshb))) {
            copyReal(&sinZ.Real, &x.Imag);
            runtime.realSetPositiveSign(&sinZ.Real);
            runtime.realMultiply(&x.Real, &sina, &res.Real, real_context);
            runtime.realFMA(&sinZ.Real, &cosa, &res.Real, &res.Real, real_context);
            runtime.realMultiply(&x.Real, &cosa, &res.Imag, real_context);
            runtime.realChangeSign(&sina);
            runtime.realFMA(&sinZ.Real, &sina, &res.Imag, &res.Imag, real_context);
            if (runtime.realIsNegative(&x.Imag)) {
                runtime.realChangeSign(&res.Imag);
            }
            if (!runtime.realIsZero(&res.Real)) {
                const negative = runtime.realIsNegative(&res.Real);
                setPlusInfinity(&res.Real);
                if (negative) {
                    setNegativeSign(&res.Real);
                }
            }
            if (!runtime.realIsZero(&res.Imag)) {
                const negative = runtime.realIsNegative(&res.Imag);
                setPlusInfinity(&res.Imag);
                if (negative) {
                    setNegativeSign(&res.Imag);
                }
            }
        } else {
            runtime.multiplyTrigByHyperbolic(&sina, &coshb, &res.Real, real_context);
            runtime.multiplyTrigByHyperbolic(&cosa, &sinhb, &res.Imag, real_context);

            copyReal(&sinZ.Real, &res.Real);
            copyReal(&sinZ.Imag, &res.Imag);
            runtime.divComplexComplex(&sinZ, &x, res, real_context);
        }
    }
}

fn sincReal() callconv(.c) void {
    var x: real_t = undefined;
    var sine: real_t = undefined;
    var phase: real_t = undefined;
    var result: *const real_t = &x;
    var x_angular_mode: runtime.angularMode_t = undefined;
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);

    if (register_data_type == runtime.dtLongInteger) {
        runtime.convertLongIntegerRegisterToReal(runtime.REGISTER_X, &x, &runtime.ctxtReal75);
        if (!runtime.reduceLongIntegerRegisterAngle(runtime.REGISTER_X, runtime.amRadian, &phase, true)) {
            return;
        }
    } else {
        if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
            return;
        }
        copyReal(&phase, &x);
    }

    if (runtime.realIsInfinite(&x)) {
        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            result = runtime.z47_math_wrappers_const_0();
        } else {
            runtime.z47_math_wrappers_report_sinc_real_domain_error();
            return;
        }
    } else {
        if (runtime.realIsZero(&x)) {
            result = runtime.z47_math_wrappers_const_1();
        } else {
            x_angular_mode = runtime.amRadian;
            if (register_data_type == runtime.dtReal34) {
                x_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_X);
                if (x_angular_mode == runtime.amNone) {
                    x_angular_mode = runtime.amRadian;
                }
            }
            runtime.C47_WP34S_Cvt2RadSinCosTan(&phase, x_angular_mode, &sine, null, null, &runtime.ctxtReal39);
            if (x_angular_mode != runtime.amRadian) {
                runtime.convertAngleFromTo(&x, x_angular_mode, runtime.amRadian, &runtime.ctxtReal39);
            }
            runtime.realDivide(&sine, &x, &x, &runtime.ctxtReal39);
        }
    }

    runtime.convertRealToResultRegister(result, runtime.REGISTER_X, runtime.amNone);
}

fn sincCplx() callconv(.c) void {
    var z: cplx_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &z)) {
        return;
    }

    sincComplex(&z, &z, &runtime.ctxtReal75);

    runtime.convertComplexToResultRegister(&z, runtime.REGISTER_X);
}

pub fn sincpiComplex(z: *const cplx_t, res: *cplx_t, real_context: *realContext_t) void {
    // sin(a + ib) = sin(a)*cosh(b) + i*cos(a)*sinh(b)
    // sinc(a + ib) = sin(a + ib) / (a + ib), for the allowable conditions
    var x: cplx_t = undefined;
    const pi: *const real_t = if (real_context.digits > 39) runtime.z47_math_wrappers_const75_pi() else runtime.z47_math_wrappers_const_pi();

    copyReal(&x.Real, &z.Real);
    copyReal(&x.Imag, &z.Imag);

    if (runtime.realIsZero(&x.Real) and runtime.realIsZero(&x.Imag)) {
        runtime.realSetOne(&res.Real);
        runtime.realSetZero(&res.Imag);
    } else if (!runtime.realIsSpecial(&x.Real) and runtime.realIsAnInteger(&x.Real) and runtime.realIsZero(&x.Imag)) {
        runtime.realSetZero(&res.Real);
        runtime.realSetZero(&res.Imag);
    } else {
        runtime.realMultiply(&x.Real, pi, &x.Real, real_context);
        runtime.realMultiply(&x.Imag, pi, &x.Imag, real_context);
        sincComplex(&x, res, real_context);
    }
}

fn sincpiReal() callconv(.c) void {
    var x: real_t = undefined;
    var sine: real_t = undefined;
    var result: *const real_t = &x;
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsInfinite(&x)) {
        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            result = runtime.z47_math_wrappers_const_0();
        } else {
            runtime.z47_math_wrappers_report_sincpi_real_domain_error();
            return;
        }
    } else {
        if (runtime.realIsZero(&x)) {
            result = runtime.z47_math_wrappers_const_1();
        } else if (register_data_type != runtime.dtReal34) {
            result = runtime.z47_math_wrappers_const_0();
        } else {
            const x_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_X);
            if (x_angular_mode != runtime.amNone) {
                runtime.convertAngleFromTo(&x, x_angular_mode, runtime.amRadian, &runtime.ctxtReal75);
            }
            if (runtime.realIsAnInteger(&x)) {
                result = runtime.z47_math_wrappers_const_0();
            } else {
                // This pi converts sincpi to sinc for all input, regardless.
                runtime.realMultiply(&x, runtime.z47_math_wrappers_const75_pi(), &x, &runtime.ctxtReal75);
                runtime.C47_WP34S_Cvt2RadSinCosTan(&x, runtime.amRadian, &sine, null, null, &runtime.ctxtReal75);
                runtime.realDivide(&sine, &x, &x, &runtime.ctxtReal75);
            }
        }
    }

    runtime.convertRealToResultRegister(result, runtime.REGISTER_X, runtime.amNone);
}

fn sincpiCplx() callconv(.c) void {
    var z: cplx_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &z)) {
        return;
    }

    sincpiComplex(&z, &z, &runtime.ctxtReal75);

    runtime.convertComplexToResultRegister(&z, runtime.REGISTER_X);
}

pub fn fnSinc(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&sincReal, &sincCplx);
}

pub fn fnSincpi(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&sincpiReal, &sincpiCplx);
}
