const std = @import("std");
const runtime = @import("math_command_wrappers_runtime.zig");

const no_register = @as(runtime.calcRegister_t, -1);
const PowRealFn = *const fn (x: *const runtime.real_t, res: *runtime.real_t, real_context: *runtime.realContext_t) callconv(.c) void;
const long_integer_power_negative_exponent: i32 = -1;

fn copyReal(destination: *runtime.real_t, source: *const runtime.real_t) void {
    destination.* = source.*;
}

fn negateReal(destination: *runtime.real_t, source: *const runtime.real_t) void {
    copyReal(destination, source);
    runtime.realChangeSign(destination);
}

pub export fn pcg32_random_r(rng: *runtime.pcg32_random_t) callconv(.c) u32 {
    const old_state = rng.state;
    const xorshifted: u32 = @truncate(((old_state >> 18) ^ old_state) >> 27);
    const rot: u5 = @intCast((old_state >> 59) & 31);
    const inv_rot: u5 = @intCast((32 - @as(u6, rot)) & 31);

    rng.state = old_state *% 6364136223846793005 +% rng.inc;
    return (xorshifted >> rot) | (xorshifted << inv_rot);
}

pub export fn pcg32_srandom_r(rng: *runtime.pcg32_random_t, initstate: u64, initseq: u64) callconv(.c) void {
    rng.state = 0;
    rng.inc = (initseq << 1) | 1;
    _ = pcg32_random_r(rng);
    rng.state +%= initstate;
    _ = pcg32_random_r(rng);
}

pub export fn pcg32_srandom(seed: u64, seq: u64) callconv(.c) void {
    pcg32_srandom_r(&runtime.pcg32_global, seed, seq);
}

fn boundedRand(s: u32) u32 {
    var rand = pcg32_random_r(&runtime.pcg32_global);
    const initial_product = @as(u64, s) * @as(u64, rand);
    const integer_part: u32 = @intCast(initial_product >> 32);
    var fractional_part: u32 = @truncate(initial_product);

    if (fractional_part <= 1 + ~s) {
        return integer_part;
    }

    var iterations: u4 = 0;
    while (iterations < 10) : (iterations += 1) {
        rand = pcg32_random_r(&runtime.pcg32_global);
        const product = @as(u64, s) * @as(u64, rand);
        const extra_fraction: u32 = @intCast(product >> 32);

        fractional_part +%= extra_fraction;
        if (fractional_part < extra_fraction) {
            return integer_part + 1;
        }
        if (fractional_part != 0xffff_ffff) {
            return integer_part;
        }

        fractional_part = @truncate(product);
    }

    return integer_part;
}

pub export fn z47_math_wrappers_bounded_rand(s: u32) callconv(.c) u32 {
    return boundedRand(s);
}

pub export fn realRandomU01(res: *runtime.real_t) callconv(.c) void {
    var t: runtime.real_t = undefined;

    runtime.uInt32ToReal(boundedRand(100000000), res);

    runtime.uInt32ToReal(boundedRand(100000000), &t);
    res.exponent += 8;
    runtime.realAdd(res, &t, res, &runtime.ctxtReal39);

    runtime.uInt32ToReal(boundedRand(1000000000), &t);
    res.exponent += 9;
    runtime.realAdd(res, &t, res, &runtime.ctxtReal39);

    runtime.uInt32ToReal(boundedRand(1000000000), &t);
    res.exponent += 9;
    runtime.realAdd(res, &t, res, &runtime.ctxtReal39);

    res.exponent -= 34;
}

fn doRealRandomI() callconv(.c) void {
    var reg_x: runtime.real_t = undefined;
    var reg_y: runtime.real_t = undefined;
    var difference: runtime.real_t = undefined;
    var unit: runtime.real_t = undefined;
    var lower: *runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &reg_x) or !runtime.getRegisterAsReal(runtime.REGISTER_Y, &reg_y)) {
        return;
    }

    runtime.realSubtract(&reg_x, &reg_y, &difference, &runtime.ctxtReal39);
    if (runtime.realIsZero(&difference)) {
        runtime.convertRealToResultRegister(&reg_x, runtime.REGISTER_X, runtime.amNone);
        return;
    }

    if (runtime.realIsNegative(&difference)) {
        runtime.realChangeSign(&difference);
        lower = &reg_x;
    } else {
        lower = &reg_y;
    }

    realRandomU01(&unit);
    runtime.realFMA(&unit, &difference, lower, &reg_x, &runtime.ctxtReal39);
    runtime.convertRealToResultRegister(&reg_x, runtime.REGISTER_X, runtime.amNone);
}

fn readSeedWord(lsu_bytes: *const [50]u8, offset: usize) u64 {
    const word_bytes: *const [8]u8 = @ptrCast(&lsu_bytes[offset]);
    return std.mem.readInt(u64, word_bytes, .native);
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

fn log2LonI() callconv(.c) void {
    runtime.logxyLonI(runtime.z47_math_wrappers_const_ln2());
}

fn log2ShoI() callconv(.c) void {
    runtime.registerShortIntegerPtr(runtime.REGISTER_X).* = runtime.WP34S_intLog2(
        runtime.registerShortIntegerPtr(runtime.REGISTER_X).*,
    );
}

fn log2Real() callconv(.c) void {
    runtime.logxyReal(runtime.z47_math_wrappers_const_ln2());
}

fn log2Cplx() callconv(.c) void {
    runtime.logxyCplx(runtime.z47_math_wrappers_const_ln2());
}

pub export fn lnComplex(
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    ln_real: *runtime.real_t,
    ln_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    if (runtime.realIsZero(real) and runtime.realIsZero(imag)) {
        copyReal(ln_real, runtime.z47_math_wrappers_const_minus_infinity());
        runtime.realSetZero(ln_imag);
        return;
    }

    runtime.realRectangularToPolar(real, imag, ln_real, ln_imag, real_context);
    runtime.WP34S_Ln(ln_real, ln_real, real_context);
}

fn lnReal() callconv(.c) void {
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
        runtime.WP34S_Ln(&x, &x, &runtime.ctxtReal39);
    } else if (runtime.getFlag(@intCast(runtime.FLAG_CPXRES))) {
        runtime.realSetPositiveSign(&x);
        runtime.WP34S_Ln(&x, &x, &runtime.ctxtReal39);
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

fn lnCplx() callconv(.c) void {
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
        lnComplex(&x_real, &x_imag, &x_real, &x_imag, &runtime.ctxtReal39);
    }

    runtime.convertComplexToResultRegister(&x_real, &x_imag, runtime.REGISTER_X);
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
        runtime.WP34S_Ln(&a, &a, &runtime.ctxtReal39);
        runtime.realDivide(&a, denom, &a, &runtime.ctxtReal39);
    } else if (runtime.getFlag(@intCast(runtime.FLAG_CPXRES))) {
        runtime.realSetPositiveSign(&a);
        runtime.WP34S_Ln(&a, &a, &runtime.ctxtReal39);
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
        runtime.WP34S_Ln(&a, &a, &runtime.ctxtReal39);
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

    runtime.WP34S_Ln(&x, &x, &runtime.ctxtReal39);
    runtime.realDivide(&x, denom, &x, &runtime.ctxtReal34);
    if (!runtime.realIsAnInteger(&x)) {
        runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
    } else {
        runtime.convertRealToLongIntegerRegister(&x, runtime.REGISTER_X, runtime.DEC_ROUND_HALF_EVEN);
    }
}

fn log10LonI() callconv(.c) void {
    logxyLonI(runtime.z47_math_wrappers_const_ln10());
}

fn log10ShoI() callconv(.c) void {
    runtime.registerShortIntegerPtr(runtime.REGISTER_X).* = runtime.WP34S_intLog10(
        runtime.registerShortIntegerPtr(runtime.REGISTER_X).*,
    );
}

fn log10Real() callconv(.c) void {
    logxyReal(runtime.z47_math_wrappers_const_ln10());
}

fn log10Cplx() callconv(.c) void {
    logxyCplx(runtime.z47_math_wrappers_const_ln10());
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
    runtime.z47_math_wrappers_minus_one_power_long_integer();
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

fn doIP(x: *runtime.real_t, mode: runtime.rounding_t) void {
    if (runtime.realIsSpecial(x)) {
        if (!runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        }
    } else {
        runtime.realToIntegralValue(x, x, mode, &runtime.ctxtReal39);
    }
}

pub export fn integerPartNoOp() callconv(.c) void {}

pub export fn integerPartReal(mode: runtime.rounding_t) callconv(.c) void {
    var x: runtime.real_t = undefined;

    if (runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        doIP(&x, mode);
        runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
    }
}

pub export fn integerPartCplx(mode: runtime.rounding_t) callconv(.c) void {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;

    if (runtime.getRegisterAsComplex(runtime.REGISTER_X, &a, &b)) {
        doIP(&a, mode);
        doIP(&b, mode);
        runtime.convertComplexToResultRegister(&a, &b, runtime.REGISTER_X);
    }
}

fn integerPartNoOpForward() callconv(.c) void {
    integerPartNoOp();
}

fn ipReal() callconv(.c) void {
    integerPartReal(runtime.DEC_ROUND_DOWN);
}

fn ipCplx() callconv(.c) void {
    integerPartCplx(runtime.DEC_ROUND_DOWN);
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

pub export fn ArcsinComplex(
    x_real: *const runtime.real_t,
    x_imag: *const runtime.real_t,
    r_real: *runtime.real_t,
    r_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) u8 {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;

    copyReal(&a, x_real);
    negateReal(&b, x_imag);

    runtime.sqrt1Px2Complex(&b, &a, r_real, r_imag, real_context);
    runtime.realAdd(r_real, &b, r_real, real_context);
    runtime.realAdd(r_imag, &a, r_imag, real_context);
    runtime.lnComplex(r_real, r_imag, &a, &b, real_context);
    runtime.realChangeSign(&a);

    copyReal(r_real, &b);
    copyReal(r_imag, &a);
    return runtime.ERROR_NONE;
}

fn arcsinCplx() callconv(.c) void {
    var x_real: runtime.real_t = undefined;
    var x_imag: runtime.real_t = undefined;
    var r_real: runtime.real_t = undefined;
    var r_imag: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &x_real, &x_imag)) {
        return;
    }

    _ = ArcsinComplex(&x_real, &x_imag, &r_real, &r_imag, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&r_real, &r_imag, runtime.REGISTER_X);
}

fn arcsinReal() callconv(.c) void {
    var x: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realCompareAbsGreaterThan(&x, runtime.z47_math_wrappers_const_1())) {
        if (runtime.getFlag(@intCast(runtime.FLAG_CPXRES))) {
            arcsinCplx();
            return;
        }

        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.realSetNaN(&x);
        } else {
            runtime.z47_math_wrappers_report_arcsin_real_domain_error();
            return;
        }
    } else {
        runtime.C47_WP34S_Asin(&x, &x, &runtime.ctxtReal39);
        runtime.convertAngleFromTo(&x, runtime.amRadian, runtime.currentAngularMode, &runtime.ctxtReal39);
    }

    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, @intCast(runtime.currentAngularMode));
    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.currentAngularMode);
}

fn arccosCplx() callconv(.c) void {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;
    var real_value: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &a, &b)) {
        return;
    }

    negateReal(&real_value, &b);
    runtime.sqrt1Px2Complex(&real_value, &a, &imag_value, &real_value, &runtime.ctxtReal39);
    runtime.realChangeSign(&real_value);
    runtime.realAdd(&a, &real_value, &real_value, &runtime.ctxtReal39);
    runtime.realAdd(&b, &imag_value, &imag_value, &runtime.ctxtReal39);
    runtime.lnComplex(&real_value, &imag_value, &real_value, &imag_value, &runtime.ctxtReal39);

    negateReal(&a, &real_value);
    copyReal(&b, &imag_value);
    runtime.convertComplexToResultRegister(&b, &a, runtime.REGISTER_X);
}

fn arccosReal() callconv(.c) void {
    var x: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realCompareAbsGreaterThan(&x, runtime.z47_math_wrappers_const_1())) {
        if (runtime.getFlag(@intCast(runtime.FLAG_CPXRES))) {
            arccosCplx();
            return;
        }

        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.realSetNaN(&x);
        } else {
            runtime.z47_math_wrappers_report_arccos_real_domain_error();
            return;
        }
    } else {
        runtime.C47_WP34S_Acos(&x, &x, &runtime.ctxtReal39);
        runtime.convertAngleFromTo(&x, runtime.amRadian, runtime.currentAngularMode, &runtime.ctxtReal39);
    }

    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.currentAngularMode);
}

pub export fn ArctanComplex(
    x_real: *runtime.real_t,
    x_imag: *runtime.real_t,
    r_real: *runtime.real_t,
    r_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) u8 {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;
    var numer: runtime.real_t = undefined;
    var denom: runtime.real_t = undefined;

    copyReal(&a, x_real);
    copyReal(&b, x_imag);

    runtime.realMultiply(&a, &a, &denom, real_context);
    runtime.realFMA(&b, &b, &denom, &denom, real_context);
    runtime.realSubtract(runtime.z47_math_wrappers_const_1(), &denom, &numer, real_context);
    runtime.realChangeSign(&b);
    runtime.realFMA(&b, runtime.z47_math_wrappers_const_2(), &denom, &denom, real_context);
    runtime.realAdd(&denom, runtime.z47_math_wrappers_const_1(), &denom, real_context);
    runtime.realMultiply(&a, runtime.z47_math_wrappers_const_2(), &b, real_context);
    runtime.realChangeSign(&b);
    runtime.realDivide(&numer, &denom, &a, real_context);
    runtime.realDivide(&b, &denom, &b, real_context);
    runtime.realRectangularToPolar(&a, &b, &a, &b, real_context);
    runtime.WP34S_Ln(&a, &a, real_context);
    runtime.realMultiply(&a, runtime.z47_math_wrappers_const_1on2(), &a, real_context);
    runtime.realMultiply(&b, runtime.z47_math_wrappers_const_1on2(), &b, real_context);
    runtime.realChangeSign(&b);

    copyReal(r_real, &b);
    copyReal(r_imag, &a);
    return runtime.ERROR_NONE;
}

fn arctanReal() callconv(.c) void {
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
        runtime.C47_WP34S_Atan(&x, &x, &runtime.ctxtReal39);
        runtime.convertAngleFromTo(&x, runtime.amRadian, runtime.currentAngularMode, &runtime.ctxtReal39);
    }

    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.currentAngularMode);
}

fn arctanCplx() callconv(.c) void {
    var x_real: runtime.real_t = undefined;
    var x_imag: runtime.real_t = undefined;
    var r_real: runtime.real_t = undefined;
    var r_imag: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &x_real, &x_imag)) {
        return;
    }

    _ = ArctanComplex(&x_real, &x_imag, &r_real, &r_imag, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&r_real, &r_imag, runtime.REGISTER_X);
}

pub export fn ArcsinhReal(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) u8 {
    if (runtime.realIsInfinite(x)) {
        copyReal(res, x);
    } else {
        runtime.WP34S_ArcSinh(x, res, real_context);
    }

    return runtime.ERROR_NONE;
}

pub export fn ArcsinhComplex(
    x_real: *const runtime.real_t,
    x_imag: *const runtime.real_t,
    r_real: *runtime.real_t,
    r_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) u8 {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;

    copyReal(&a, x_real);
    copyReal(&b, x_imag);

    runtime.realMultiply(&b, &b, r_real, real_context);
    runtime.realChangeSign(r_real);
    runtime.realFMA(&a, &a, r_real, r_real, real_context);
    runtime.realMultiply(&a, &b, r_imag, real_context);
    runtime.realMultiply(r_imag, runtime.z47_math_wrappers_const_2(), r_imag, real_context);
    runtime.realAdd(r_real, runtime.z47_math_wrappers_const_1(), r_real, real_context);
    runtime.realRectangularToPolar(r_real, r_imag, r_real, r_imag, real_context);
    runtime.realSquareRoot(r_real, r_real, real_context);
    runtime.realMultiply(r_imag, runtime.z47_math_wrappers_const_1on2(), r_imag, real_context);
    runtime.realPolarToRectangular(r_real, r_imag, r_real, r_imag, real_context);
    runtime.realAdd(&a, r_real, r_real, real_context);
    runtime.realAdd(&b, r_imag, r_imag, real_context);
    runtime.realRectangularToPolar(r_real, r_imag, &a, &b, real_context);
    runtime.WP34S_Ln(&a, &a, real_context);

    copyReal(r_real, &a);
    copyReal(r_imag, &b);
    return runtime.ERROR_NONE;
}

fn arcsinhReal() callconv(.c) void {
    var x: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    _ = ArcsinhReal(&x, &x, &runtime.ctxtReal51);
    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
}

fn arcsinhCplx() callconv(.c) void {
    var x_real: runtime.real_t = undefined;
    var x_imag: runtime.real_t = undefined;
    var r_real: runtime.real_t = undefined;
    var r_imag: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &x_real, &x_imag)) {
        return;
    }

    _ = ArcsinhComplex(&x_real, &x_imag, &r_real, &r_imag, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&r_real, &r_imag, runtime.REGISTER_X);
}

pub export fn realArcosh(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    var x_squared: runtime.real_t = undefined;

    runtime.realMultiply(x, x, &x_squared, real_context);
    runtime.realSubtract(&x_squared, runtime.z47_math_wrappers_const_1(), &x_squared, real_context);
    runtime.realSquareRoot(&x_squared, &x_squared, real_context);
    runtime.realAdd(&x_squared, x, res, real_context);
    runtime.WP34S_Ln(res, res, real_context);
}

fn arccoshCplx() callconv(.c) void {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;
    var real_value: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &a, &b)) {
        return;
    }

    runtime.realMultiply(&b, &b, &real_value, &runtime.ctxtReal39);
    runtime.realChangeSign(&real_value);
    runtime.realFMA(&a, &a, &real_value, &real_value, &runtime.ctxtReal39);
    runtime.realMultiply(&a, &b, &imag_value, &runtime.ctxtReal39);
    runtime.realMultiply(&imag_value, runtime.z47_math_wrappers_const_2(), &imag_value, &runtime.ctxtReal39);
    runtime.realSubtract(&real_value, runtime.z47_math_wrappers_const_1(), &real_value, &runtime.ctxtReal39);
    runtime.realRectangularToPolar(&real_value, &imag_value, &real_value, &imag_value, &runtime.ctxtReal39);
    runtime.realSquareRoot(&real_value, &real_value, &runtime.ctxtReal39);
    runtime.realMultiply(&imag_value, runtime.z47_math_wrappers_const_1on2(), &imag_value, &runtime.ctxtReal39);
    runtime.realPolarToRectangular(&real_value, &imag_value, &real_value, &imag_value, &runtime.ctxtReal39);
    runtime.realAdd(&a, &real_value, &real_value, &runtime.ctxtReal39);
    runtime.realAdd(&b, &imag_value, &imag_value, &runtime.ctxtReal39);
    runtime.realRectangularToPolar(&real_value, &imag_value, &a, &b, &runtime.ctxtReal39);
    runtime.WP34S_Ln(&a, &a, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&a, &b, runtime.REGISTER_X);
}

fn arccoshReal() callconv(.c) void {
    var x: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realCompareLessThan(&x, runtime.z47_math_wrappers_const_1())) {
        if (runtime.getFlag(@intCast(runtime.FLAG_CPXRES))) {
            arccoshCplx();
            return;
        }

        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.realSetNaN(&x);
        } else {
            runtime.z47_math_wrappers_report_arccosh_real_domain_error();
            return;
        }
    } else {
        realArcosh(&x, &x, &runtime.ctxtReal75);
    }

    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
}

fn arctanhCplx() callconv(.c) void {
    var numer_real: runtime.real_t = undefined;
    var denom_real: runtime.real_t = undefined;
    var numer_imag: runtime.real_t = undefined;
    var denom_imag: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &denom_imag, &numer_imag)) {
        return;
    }

    runtime.realAdd(&denom_imag, runtime.z47_math_wrappers_const_1(), &numer_real, &runtime.ctxtReal39);
    runtime.realSubtract(runtime.z47_math_wrappers_const_1(), &denom_imag, &denom_real, &runtime.ctxtReal39);
    negateReal(&denom_imag, &numer_imag);
    runtime.divComplexComplex(&numer_real, &numer_imag, &denom_real, &denom_imag, &numer_real, &numer_imag, &runtime.ctxtReal39);
    runtime.lnComplex(&numer_real, &numer_imag, &numer_real, &numer_imag, &runtime.ctxtReal39);
    runtime.realMultiply(&numer_real, runtime.z47_math_wrappers_const_1on2(), &numer_real, &runtime.ctxtReal39);
    runtime.realMultiply(&numer_imag, runtime.z47_math_wrappers_const_1on2(), &numer_imag, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&numer_real, &numer_imag, runtime.REGISTER_X);
}

fn arctanhReal() callconv(.c) void {
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
            arctanhCplx();
            return;
        }

        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.realSetNaN(&x);
        } else {
            runtime.z47_math_wrappers_report_arctanh_real_domain_error();
            return;
        }
    } else {
        runtime.WP34S_ArcTanh(&x, &x, &runtime.ctxtReal39);
    }

    runtime.convertRealToResultRegister(result, runtime.REGISTER_X, runtime.amNone);
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
    _ = unused_but_mandatory_parameter;

    var value: runtime.real_t = undefined;

    realRandomU01(&value);
    runtime.liftStack();
    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
    runtime.convertRealToReal34ResultRegister(&value, runtime.REGISTER_X);
    runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, no_register, no_register);
}

pub export fn fnRandomI(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexDyadicFunction(&doRealRandomI, null, null, &runtime.z47_math_wrappers_do_int_random_i);
}

pub export fn fnSeed(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    var register_x = std.mem.zeroes(runtime.real_t);

    if (!runtime.saveLastX()) {
        return;
    }

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &register_x)) {
        return;
    }

    runtime.fnDrop(0);

    const lsu_bytes: *const [50]u8 = @ptrCast(&register_x.lsu);
    var seed = readSeedWord(lsu_bytes, 0);
    var sequence = readSeedWord(lsu_bytes, @sizeOf(u64));

    if (seed == 0 and sequence == 0) {
        runtime.z47_math_wrappers_seed_defaults(&seed, &sequence);
    }

    pcg32_srandom(seed, sequence);
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

pub export fn fnIp(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexMonadicFunction(
        &ipReal,
        &ipCplx,
        &integerPartNoOpForward,
        &integerPartNoOpForward,
    );
}

pub export fn fnLint(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    if (!runtime.saveLastX()) {
        return;
    }

    runtime.z47_math_wrappers_integer_part_long_integer();
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

pub export fn fnArcsin(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&arcsinReal, &arcsinCplx);
}

pub export fn fnArccos(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&arccosReal, &arccosCplx);
}

pub export fn fnArctan(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&arctanReal, &arctanCplx);
}

pub export fn fnArcsinh(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&arcsinhReal, &arcsinhCplx);
}

pub export fn fnArccosh(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&arccoshReal, &arccoshCplx);
}

pub export fn fnArctanh(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&arctanhReal, &arctanhCplx);
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

pub export fn fnLn(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&lnReal, &lnCplx);
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
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexMonadicFunction(&twoPowReal, &twoPowCplx, &twoPowShoI, &twoPowLonI);
}

pub export fn fn10Pow(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexMonadicFunction(&tenPowReal, &tenPowCplx, &tenPowShoI, &tenPowLonI);
}

pub export fn fnLog10(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexMonadicFunction(&log10Real, &log10Cplx, &log10ShoI, &log10LonI);
}

pub export fn fnLog2(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexMonadicFunction(&log2Real, &log2Cplx, &log2ShoI, &log2LonI);
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
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexMonadicFunction(&squareReal, &squareCplx, &squareShoI, &squareLonI);
}

pub export fn fnCube(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexMonadicFunction(&cubeReal, &cubeCplx, &cubeShoI, &cubeLonI);
}
