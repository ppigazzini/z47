const atan_owned = @import("math_atan_owned.zig");
const inverse_trig_complex_command_owned = @import("math_inverse_trig_complex_command_owned.zig");
const inverse_trig_command_owned = @import("math_inverse_trig_command_owned.zig");
const real_trig_owned = @import("math_real_trig_owned.zig");
const runtime = @import("math_command_wrappers_runtime.zig");

fn copyReal(destination: *runtime.real_t, source: *const runtime.real_t) void {
    destination.* = source.*;
}

pub fn arcsinReal() callconv(.c) void {
    var x: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realCompareAbsGreaterThan(&x, runtime.z47_math_wrappers_const_1())) {
        if (runtime.getFlag(@intCast(runtime.FLAG_CPXRES))) {
            inverse_trig_complex_command_owned.arcsinCplx();
            return;
        }

        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.realSetNaN(&x);
        } else {
            runtime.z47_math_wrappers_report_arcsin_real_domain_error();
            return;
        }
    } else {
        real_trig_owned.arcsinReal(&x, &x, &runtime.ctxtReal39);
        runtime.convertAngleFromTo(&x, runtime.amRadian, runtime.currentAngularMode, &runtime.ctxtReal39);
    }

    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, @intCast(runtime.currentAngularMode));
    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.currentAngularMode);
}

pub fn arccosReal() callconv(.c) void {
    var x: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realCompareAbsGreaterThan(&x, runtime.z47_math_wrappers_const_1())) {
        if (runtime.getFlag(@intCast(runtime.FLAG_CPXRES))) {
            inverse_trig_complex_command_owned.arccosCplx();
            return;
        }

        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.realSetNaN(&x);
        } else {
            runtime.z47_math_wrappers_report_arccos_real_domain_error();
            return;
        }
    } else {
        real_trig_owned.arccosReal(&x, &x, &runtime.ctxtReal39);
        runtime.convertAngleFromTo(&x, runtime.amRadian, runtime.currentAngularMode, &runtime.ctxtReal39);
    }

    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.currentAngularMode);
}

pub fn arctanReal() callconv(.c) void {
    var x: runtime.real_t = undefined;
    var was_negative = false;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    was_negative = runtime.realIsNegative(&x);

    if (runtime.realIsInfinite(&x)) {
        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            copyReal(&x, runtime.z47_math_wrappers_const_90());
            if (was_negative) {
                runtime.realChangeSign(&x);
            }
            runtime.convertAngleFromTo(&x, runtime.amDegree, runtime.currentAngularMode, &runtime.ctxtReal39);
        } else {
            runtime.z47_math_wrappers_report_arctan_real_domain_error();
            return;
        }
    } else {
        atan_owned.arctanReal(&x, &x, &runtime.ctxtReal39);
        runtime.convertAngleFromTo(&x, runtime.amRadian, runtime.currentAngularMode, &runtime.ctxtReal39);
    }

    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.currentAngularMode);
}

pub fn arcsinhReal() callconv(.c) void {
    var x: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    _ = inverse_trig_command_owned.ArcsinhReal(&x, &x, &runtime.ctxtReal51);
    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
}

pub fn arccoshReal() callconv(.c) void {
    var x: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realCompareLessThan(&x, runtime.z47_math_wrappers_const_1())) {
        if (runtime.getFlag(@intCast(runtime.FLAG_CPXRES))) {
            inverse_trig_complex_command_owned.arccoshCplx();
            return;
        }

        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.realSetNaN(&x);
        } else {
            runtime.z47_math_wrappers_report_arccosh_real_domain_error();
            return;
        }
    } else {
        inverse_trig_command_owned.realArcosh(&x, &x, &runtime.ctxtReal75);
    }

    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
}

pub fn arctanhReal() callconv(.c) void {
    var x: runtime.real_t = undefined;
    var result: *const runtime.real_t = &x;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsZero(&x)) {
        result = runtime.z47_math_wrappers_const_0();
    } else if (runtime.realCompareEqual(&x, runtime.z47_math_wrappers_const_1())) {
        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            result = runtime.z47_math_wrappers_const_plus_infinity();
        } else {
            runtime.z47_math_wrappers_report_arctanh_real_positive_one_domain_error();
            return;
        }
    } else if (runtime.realCompareEqual(&x, runtime.z47_math_wrappers_const_minus_1())) {
        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            result = runtime.z47_math_wrappers_const_minus_infinity();
        } else {
            runtime.z47_math_wrappers_report_arctanh_real_negative_one_domain_error();
            return;
        }
    } else if (runtime.realCompareAbsGreaterThan(&x, runtime.z47_math_wrappers_const_1())) {
        if (runtime.getFlag(@intCast(runtime.FLAG_CPXRES))) {
            inverse_trig_complex_command_owned.arctanhCplx();
            return;
        }

        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.realSetNaN(&x);
        } else {
            runtime.z47_math_wrappers_report_arctanh_real_domain_error();
            return;
        }
    } else {
        real_trig_owned.arctanhReal(&x, &x, &runtime.ctxtReal39);
    }

    runtime.convertRealToResultRegister(result, runtime.REGISTER_X, runtime.amNone);
}