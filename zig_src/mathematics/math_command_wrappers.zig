const std = @import("std");
const runtime = @import("math_command_wrappers_runtime.zig");

const no_register = @as(runtime.calcRegister_t, -1);
const PowRealFn = *const fn (x: *const runtime.real_t, res: *runtime.real_t, real_context: *runtime.realContext_t) callconv(.c) void;
const long_integer_power_negative_exponent: i32 = -1;

const z47_math_wrappers_retained_fnBn = runtime.retained.z47_math_wrappers_retained_fnBn;
const z47_math_wrappers_retained_fnBnStar = runtime.retained.z47_math_wrappers_retained_fnBnStar;
const z47_math_wrappers_retained_fnExpt = runtime.retained.z47_math_wrappers_retained_fnExpt;
const z47_math_wrappers_retained_fnWpositive = runtime.retained.z47_math_wrappers_retained_fnWpositive;
const z47_math_wrappers_retained_fnWnegative = runtime.retained.z47_math_wrappers_retained_fnWnegative;
const z47_math_wrappers_retained_fnWinverse = runtime.retained.z47_math_wrappers_retained_fnWinverse;
const z47_math_wrappers_retained_fnGcd = runtime.retained.z47_math_wrappers_retained_fnGcd;
const z47_math_wrappers_retained_fnLcm = runtime.retained.z47_math_wrappers_retained_fnLcm;
const z47_math_wrappers_retained_fnMod = runtime.retained.z47_math_wrappers_retained_fnMod;
const z47_math_wrappers_retained_fnRmd = runtime.retained.z47_math_wrappers_retained_fnRmd;
const z47_math_wrappers_retained_fnUlp = runtime.retained.z47_math_wrappers_retained_fnUlp;
const z47_math_wrappers_retained_fnMant = runtime.retained.z47_math_wrappers_retained_fnMant;
const z47_math_wrappers_retained_fnRoundi = runtime.retained.z47_math_wrappers_retained_fnRoundi;
const z47_math_wrappers_retained_fnNeighb = runtime.retained.z47_math_wrappers_retained_fnNeighb;
const z47_math_wrappers_retained_fnIxyz = runtime.retained.z47_math_wrappers_retained_fnIxyz;
const z47_math_wrappers_retained_fnFactorial = runtime.retained.z47_math_wrappers_retained_fnFactorial;
const z47_math_wrappers_retained_fnRealPart = runtime.retained.z47_math_wrappers_retained_fnRealPart;
const z47_math_wrappers_retained_fnImaginaryPart = runtime.retained.z47_math_wrappers_retained_fnImaginaryPart;
const z47_math_wrappers_retained_fnArg = runtime.retained.z47_math_wrappers_retained_fnArg;
const z47_math_wrappers_retained_fnMagnitude = runtime.retained.z47_math_wrappers_retained_fnMagnitude;
const z47_math_wrappers_retained_fnConjugate = runtime.retained.z47_math_wrappers_retained_fnConjugate;
const z47_math_wrappers_retained_fnSwapRealImaginary = runtime.retained.z47_math_wrappers_retained_fnSwapRealImaginary;
const z47_math_wrappers_retained_fnAtan2 = runtime.retained.z47_math_wrappers_retained_fnAtan2;
const z47_math_wrappers_retained_fnPercent = runtime.retained.z47_math_wrappers_retained_fnPercent;
const z47_math_wrappers_retained_fnAdd = runtime.retained.z47_math_wrappers_retained_fnAdd;
const z47_math_wrappers_retained_fnSubtract = runtime.retained.z47_math_wrappers_retained_fnSubtract;
const z47_math_wrappers_retained_fnMultiply = runtime.retained.z47_math_wrappers_retained_fnMultiply;
const z47_math_wrappers_retained_fnDivide = runtime.retained.z47_math_wrappers_retained_fnDivide;
const z47_math_wrappers_retained_fnIDiv = runtime.retained.z47_math_wrappers_retained_fnIDiv;
const z47_math_wrappers_retained_fnIDivR = runtime.retained.z47_math_wrappers_retained_fnIDivR;
const z47_math_wrappers_retained_fnDblMultiply = runtime.retained.z47_math_wrappers_retained_fnDblMultiply;
const z47_math_wrappers_retained_fnRound = runtime.retained.z47_math_wrappers_retained_fnRound;
const z47_math_wrappers_retained_fnDecomp = runtime.retained.z47_math_wrappers_retained_fnDecomp;
const z47_math_wrappers_retained_fnCheckInteger = runtime.retained.z47_math_wrappers_retained_fnCheckInteger;
const z47_math_wrappers_retained_fnDec = runtime.retained.z47_math_wrappers_retained_fnDec;
const z47_math_wrappers_retained_fnInc = runtime.retained.z47_math_wrappers_retained_fnInc;
const z47_math_wrappers_retained_fnXLessThan = runtime.retained.z47_math_wrappers_retained_fnXLessThan;
const z47_math_wrappers_retained_fnXLessEqual = runtime.retained.z47_math_wrappers_retained_fnXLessEqual;
const z47_math_wrappers_retained_fnXGreaterThan = runtime.retained.z47_math_wrappers_retained_fnXGreaterThan;
const z47_math_wrappers_retained_fnXGreaterEqual = runtime.retained.z47_math_wrappers_retained_fnXGreaterEqual;
const z47_math_wrappers_retained_fnXEqualsTo = runtime.retained.z47_math_wrappers_retained_fnXEqualsTo;
const z47_math_wrappers_retained_fnXNotEqual = runtime.retained.z47_math_wrappers_retained_fnXNotEqual;
const z47_math_wrappers_retained_fnXAlmostEqual = runtime.retained.z47_math_wrappers_retained_fnXAlmostEqual;
const z47_math_wrappers_retained_fnIsConverged = runtime.retained.z47_math_wrappers_retained_fnIsConverged;
const z47_math_wrappers_retained_fnCheckType = runtime.retained.z47_math_wrappers_retained_fnCheckType;
const z47_math_wrappers_retained_fnCheckReal = runtime.retained.z47_math_wrappers_retained_fnCheckReal;
const z47_math_wrappers_retained_fnCheckNumber = runtime.retained.z47_math_wrappers_retained_fnCheckNumber;
const z47_math_wrappers_retained_fnCheckAngle = runtime.retained.z47_math_wrappers_retained_fnCheckAngle;
const z47_math_wrappers_retained_fnCheckMatrix = runtime.retained.z47_math_wrappers_retained_fnCheckMatrix;
const z47_math_wrappers_retained_fnGetType = runtime.retained.z47_math_wrappers_retained_fnGetType;
const z47_math_wrappers_retained_fnDblDivide = runtime.retained.z47_math_wrappers_retained_fnDblDivide;
const z47_math_wrappers_retained_fnDblDivideRemainder = runtime.retained.z47_math_wrappers_retained_fnDblDivideRemainder;
const z47_math_wrappers_retained_fnToPolar2 = runtime.retained.z47_math_wrappers_retained_fnToPolar2;
const z47_math_wrappers_retained_fnToRect2 = runtime.retained.z47_math_wrappers_retained_fnToRect2;
const z47_math_wrappers_retained_fnToRect = runtime.retained.z47_math_wrappers_retained_fnToRect;
const z47_math_wrappers_retained_fnParallel = runtime.retained.z47_math_wrappers_retained_fnParallel;
const z47_math_wrappers_retained_fnUnitVector = runtime.retained.z47_math_wrappers_retained_fnUnitVector;
const z47_math_wrappers_retained_fnSdl = runtime.retained.z47_math_wrappers_retained_fnSdl;
const z47_math_wrappers_retained_fnSdr = runtime.retained.z47_math_wrappers_retained_fnSdr;
const z47_math_wrappers_retained_fnSquareRoot = runtime.retained.z47_math_wrappers_retained_fnSquareRoot;
const z47_math_wrappers_retained_fnCubeRoot = runtime.retained.z47_math_wrappers_retained_fnCubeRoot;
const z47_math_wrappers_retained_fnPercentMRR = runtime.retained.z47_math_wrappers_retained_fnPercentMRR;
const z47_math_wrappers_retained_fnPercentPlusMG = runtime.retained.z47_math_wrappers_retained_fnPercentPlusMG;
const z47_math_wrappers_retained_fnPercentT = runtime.retained.z47_math_wrappers_retained_fnPercentT;
const z47_math_wrappers_retained_fnDeltaPercent = runtime.retained.z47_math_wrappers_retained_fnDeltaPercent;
const z47_math_wrappers_retained_fnFib = runtime.retained.z47_math_wrappers_retained_fnFib;
const z47_math_wrappers_retained_fnLINPOL = runtime.retained.z47_math_wrappers_retained_fnLINPOL;
const z47_math_wrappers_retained_fnCross = runtime.retained.z47_math_wrappers_retained_fnCross;
const z47_math_wrappers_retained_fnDot = runtime.retained.z47_math_wrappers_retained_fnDot;
const z47_math_wrappers_retained_fnLogXY = runtime.retained.z47_math_wrappers_retained_fnLogXY;

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

fn sincComplex(
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    res_real: *runtime.real_t,
    res_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    var rr: runtime.real_t = undefined;
    var ii: runtime.real_t = undefined;

    copyReal(&rr, real);
    copyReal(&ii, imag);

    if (runtime.realIsZero(&rr) and runtime.realIsZero(&ii)) {
        runtime.realSetOne(res_real);
        runtime.realSetZero(res_imag);
        return;
    }

    var sin_real: runtime.real_t = undefined;
    var sin_imag: runtime.real_t = undefined;

    sinComplex(&rr, &ii, res_real, res_imag, real_context);
    copyReal(&sin_real, res_real);
    copyReal(&sin_imag, res_imag);
    runtime.divComplexComplex(&sin_real, &sin_imag, &rr, &ii, res_real, res_imag, real_context);
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

pub export fn realExpM1(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    runtime.WP34S_ExpM1(x, res, real_context);
}

pub export fn realLog10(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    runtime.WP34S_Ln(x, res, real_context);
    runtime.realDivide(res, runtime.z47_math_wrappers_const_ln10(), res, real_context);
}

fn expM1Complex(
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
    sinComplex(&z2_imag, &z2_real, &z2_real, &z2_imag, real_context);
    runtime.mulComplexComplex(&z2_real, &z2_imag, &e_imag, &e_real, res_real, res_imag, real_context);
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
    smallBasePowerLonI(10, &tenPowReal);
}

fn smallBasePowerLonI(base_value: c_ulong, negative_exponent_callback: *const fn () callconv(.c) void) void {
    var exponent: runtime.longInteger_t = undefined;
    var base: runtime.longInteger_t = undefined;
    var power: runtime.longInteger_t = undefined;
    var exponent_sign: i32 = 0;

    runtime.__gmpz_init(&base[0]);
    runtime.__gmpz_set_ui(&base[0], base_value);
    runtime.convertLongIntegerRegisterToLongInteger(runtime.REGISTER_X, &exponent[0]);
    if (exponent[0]._mp_size < 0) {
        exponent_sign = -1;
    } else if (exponent[0]._mp_size > 0) {
        exponent_sign = 1;
    }
    defer runtime.__gmpz_clear(&base[0]);
    defer runtime.__gmpz_clear(&exponent[0]);

    longIntegerSetPositiveSign(&exponent[0]);

    if (exponent[0]._mp_size == 0) {
        runtime.__gmpz_set_ui(&base[0], 1);
        runtime.convertLongIntegerToLongIntegerRegister(&base[0], runtime.REGISTER_X);
        return;
    }

    if (exponent_sign < 0) {
        negative_exponent_callback();
        return;
    }

    runtime.__gmpz_init(&power[0]);
    defer runtime.__gmpz_clear(&power[0]);
    runtime.__gmpz_set_ui(&power[0], 1);

    while (exponent[0]._mp_size != 0 and runtime.lastErrorCode == 0) {
        if ((exponent[0]._mp_d[0] & 1) != 0) {
            runtime.__gmpz_mul(&power[0], &power[0], &base[0]);
        }

        _ = runtime.__gmpz_fdiv_q_ui(&exponent[0], &exponent[0], 2);

        if (exponent[0]._mp_size != 0) {
            runtime.__gmpz_mul(&base[0], &base[0], &base[0]);
        }
    }

    runtime.convertLongIntegerToLongIntegerRegister(&power[0], runtime.REGISTER_X);
}

fn twoPowLonI() callconv(.c) void {
    smallBasePowerLonI(2, &twoPowReal);
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

fn lnP1Complex(
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

    runtime.realRectangularToPolar(real, imag, &magnitude, &dummy, real_context);
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
            var product_real: runtime.real_t = undefined;
            var product_imag: runtime.real_t = undefined;
            var divisor: runtime.real_t = undefined;
            var contribution: runtime.real_t = undefined;

            runtime.mulComplexComplex(&term_real, &term_imag, real, imag, &product_real, &product_imag, real_context);
            runtime.realChangeSign(&product_real);
            runtime.realChangeSign(&product_imag);
            copyReal(&term_real, &product_real);
            copyReal(&term_imag, &product_imag);

            runtime.uInt32ToReal(@intCast(index + 1), &divisor);

            runtime.realDivide(&term_real, &divisor, &contribution, real_context);
            runtime.realAdd(&sum_real, &contribution, &sum_real, real_context);
            runtime.realDivide(&term_imag, &divisor, &contribution, real_context);
            runtime.realAdd(&sum_imag, &contribution, &sum_imag, real_context);
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

    runtime.realRectangularToPolar(&one_plus_real, imag, ln_real, ln_imag, real_context);
    runtime.WP34S_Ln(ln_real, ln_real, real_context);
}

fn sincReal() callconv(.c) void {
    var x: runtime.real_t = undefined;
    var sine: runtime.real_t = undefined;
    var result: *const runtime.real_t = &x;
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
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
            if (register_data_type == runtime.dtReal34) {
                const angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_X);
                if (angular_mode != runtime.amNone) {
                    runtime.convertAngleFromTo(&x, angular_mode, runtime.amRadian, &runtime.ctxtReal39);
                }
            }
            runtime.C47_WP34S_Cvt2RadSinCosTan(&x, runtime.amRadian, &sine, null, null, &runtime.ctxtReal39);
            runtime.realDivide(&sine, &x, &x, &runtime.ctxtReal75);
        }
    }

    runtime.convertRealToResultRegister(result, runtime.REGISTER_X, runtime.amNone);
}

fn sincCplx() callconv(.c) void {
    var z_real: runtime.real_t = undefined;
    var z_imag: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &z_real, &z_imag)) {
        return;
    }

    sincComplex(&z_real, &z_imag, &z_real, &z_imag, &runtime.ctxtReal75);
    runtime.convertComplexToResultRegister(&z_real, &z_imag, runtime.REGISTER_X);
}

fn sincpiReal() callconv(.c) void {
    var x: runtime.real_t = undefined;
    var sine: runtime.real_t = undefined;
    var result: *const runtime.real_t = &x;
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
            const angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_X);
            if (angular_mode != runtime.amNone) {
                runtime.convertAngleFromTo(&x, angular_mode, runtime.amRadian, &runtime.ctxtReal75);
            }
            runtime.realMultiply(&x, runtime.z47_math_wrappers_const_pi(), &x, &runtime.ctxtReal75);
            runtime.C47_WP34S_Cvt2RadSinCosTan(&x, runtime.amRadian, &sine, null, null, &runtime.ctxtReal75);
            runtime.realDivide(&sine, &x, &x, &runtime.ctxtReal75);
        }
    }

    runtime.convertRealToResultRegister(result, runtime.REGISTER_X, runtime.amNone);
}

fn sincpiComplex(
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    res_real: *runtime.real_t,
    res_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    var rr: runtime.real_t = undefined;
    var ii: runtime.real_t = undefined;
    var remainder: runtime.real_t = undefined;

    copyReal(&rr, real);
    copyReal(&ii, imag);
    runtime.WP34S_Mod(&rr, runtime.z47_math_wrappers_const_1(), &remainder, real_context);

    if (runtime.realIsZero(&rr) and runtime.realIsZero(&ii)) {
        runtime.realSetOne(res_real);
        runtime.realSetZero(res_imag);
        return;
    }

    if (runtime.realIsZero(&remainder) and runtime.realIsZero(&ii)) {
        runtime.realSetZero(res_real);
        runtime.realSetZero(res_imag);
        return;
    }

    var sina: runtime.real_t = undefined;
    var cosa: runtime.real_t = undefined;
    var sinhb: runtime.real_t = undefined;
    var coshb: runtime.real_t = undefined;
    var sin_real: runtime.real_t = undefined;
    var sin_imag: runtime.real_t = undefined;

    runtime.realMultiply(&rr, runtime.z47_math_wrappers_const_pi(), &rr, real_context);
    runtime.realMultiply(&ii, runtime.z47_math_wrappers_const_pi(), &ii, real_context);
    runtime.C47_WP34S_Cvt2RadSinCosTan(&rr, runtime.amRadian, &sina, &cosa, null, real_context);
    runtime.WP34S_SinhCosh(&ii, &sinhb, &coshb, real_context);

    runtime.realMultiply(&sina, &coshb, res_real, real_context);
    runtime.realMultiply(&cosa, &sinhb, res_imag, real_context);
    copyReal(&sin_real, res_real);
    copyReal(&sin_imag, res_imag);
    runtime.divComplexComplex(&sin_real, &sin_imag, &rr, &ii, res_real, res_imag, real_context);
}

fn sincpiCplx() callconv(.c) void {
    var z_real: runtime.real_t = undefined;
    var z_imag: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &z_real, &z_imag)) {
        return;
    }

    sincpiComplex(&z_real, &z_imag, &z_real, &z_imag, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&z_real, &z_imag, runtime.REGISTER_X);
}

fn expM1Real() callconv(.c) void {
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

fn expM1Cplx() callconv(.c) void {
    var z_real: runtime.real_t = undefined;
    var z_imag: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &z_real, &z_imag)) {
        return;
    }

    expM1Complex(&z_real, &z_imag, &z_real, &z_imag, &runtime.ctxtReal75);
    runtime.convertComplexToResultRegister(&z_real, &z_imag, runtime.REGISTER_X);
}

fn lnP1Real() callconv(.c) void {
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
    } else {
        if (!runtime.realIsNegative(&shifted)) {
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
    }

    runtime.convertRealToResultRegister(&result, runtime.REGISTER_X, runtime.amNone);
}

fn lnP1Cplx() callconv(.c) void {
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

fn realPartCplx() callconv(.c) void {
    var real_value: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &real_value, &imag_value)) {
        return;
    }

    runtime.convertRealToResultRegister(&real_value, runtime.REGISTER_X, runtime.amNone);
}

fn realPartCxma() void {
    var complex_matrix: runtime.complex34Matrix_t = undefined;
    var real_matrix: runtime.real34Matrix_t = undefined;

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &complex_matrix);
    if (!runtime.realMatrixInit(&real_matrix, complex_matrix.header.matrixRows, complex_matrix.header.matrixColumns)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        return;
    }
    defer runtime.realMatrixFree(&real_matrix);

    const count = @min(
        @as(usize, complex_matrix.header.matrixRows) * @as(usize, complex_matrix.header.matrixColumns),
        real_matrix.matrixElements.len,
    );

    var index: usize = 0;
    while (index < count) : (index += 1) {
        real_matrix.matrixElements[index] = complex_matrix.matrixElements[index].real;
    }

    runtime.convertReal34MatrixToReal34MatrixRegister(&real_matrix, runtime.REGISTER_X);
}

fn realPartReal() callconv(.c) void {
    var value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &value)) {
        return;
    }

    runtime.convertRealToResultRegister(&value, runtime.REGISTER_X, runtime.amNone);
}

fn imagPartCplx() callconv(.c) void {
    var real_value: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &real_value, &imag_value)) {
        return;
    }

    runtime.convertRealToResultRegister(&imag_value, runtime.REGISTER_X, runtime.amNone);
}

fn imagPartCxma() void {
    var complex_matrix: runtime.complex34Matrix_t = undefined;
    var real_matrix: runtime.real34Matrix_t = undefined;

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &complex_matrix);
    if (!runtime.realMatrixInit(&real_matrix, complex_matrix.header.matrixRows, complex_matrix.header.matrixColumns)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        return;
    }
    defer runtime.realMatrixFree(&real_matrix);

    const count = @min(
        @as(usize, complex_matrix.header.matrixRows) * @as(usize, complex_matrix.header.matrixColumns),
        real_matrix.matrixElements.len,
    );

    var index: usize = 0;
    while (index < count) : (index += 1) {
        real_matrix.matrixElements[index] = complex_matrix.matrixElements[index].imag;
    }

    runtime.convertReal34MatrixToReal34MatrixRegister(&real_matrix, runtime.REGISTER_X);
}

fn imagPartReal() callconv(.c) void {
    runtime.convertRealToResultRegister(runtime.z47_math_wrappers_const_0(), runtime.REGISTER_X, runtime.amNone);
}

fn magnitudeLonI() callconv(.c) void {
    runtime.setRegisterLongIntegerSign(runtime.REGISTER_X, runtime.LI_POSITIVE);
}

fn magnitudeShoI() callconv(.c) void {
    runtime.registerShortIntegerPtr(runtime.REGISTER_X).* = runtime.WP34S_intAbs(runtime.registerShortIntegerPtr(runtime.REGISTER_X).*);
}

fn magnitudeReal() callconv(.c) void {
    runtime.real34SetPositiveSign(runtime.registerReal34Ptr(runtime.REGISTER_X));
    runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.amNone);
}

fn complexMagnitude2(real: *const runtime.real_t, imag: *const runtime.real_t, magnitude: *runtime.real_t, real_context: *runtime.realContext_t) void {
    var product: runtime.real_t = undefined;

    runtime.realMultiply(real, real, &product, real_context);
    runtime.realFMA(imag, imag, &product, magnitude, real_context);
}

fn complexMagnitude(real: *const runtime.real_t, imag: *const runtime.real_t, magnitude: *runtime.real_t, real_context: *runtime.realContext_t) void {
    var squared: runtime.real_t = undefined;

    complexMagnitude2(real, imag, &squared, real_context);
    runtime.realSquareRoot(&squared, magnitude, real_context);
}

fn magnitudeCxma() void {
    var complex_matrix: runtime.complex34Matrix_t = undefined;
    var real_matrix: runtime.real34Matrix_t = undefined;
    var dummy = std.mem.zeroes(runtime.real34_t);

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &complex_matrix);
    if (!runtime.realMatrixInit(&real_matrix, complex_matrix.header.matrixRows, complex_matrix.header.matrixColumns)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        return;
    }
    defer runtime.realMatrixFree(&real_matrix);

    const count = @min(
        @as(usize, complex_matrix.header.matrixRows) * @as(usize, complex_matrix.header.matrixColumns),
        real_matrix.matrixElements.len,
    );

    var index: usize = 0;
    while (index < count) : (index += 1) {
        runtime.real34RectangularToPolar(
            &complex_matrix.matrixElements[index].real,
            &complex_matrix.matrixElements[index].imag,
            &real_matrix.matrixElements[index],
            &dummy,
        );
    }

    runtime.convertReal34MatrixToReal34MatrixRegister(&real_matrix, runtime.REGISTER_X);
}

fn magnitudeCplx() callconv(.c) void {
    var real_value: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;
    var magnitude: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &real_value, &imag_value)) {
        return;
    }

    complexMagnitude(&real_value, &imag_value, &magnitude, &runtime.ctxtReal39);
    runtime.convertRealToResultRegister(&magnitude, runtime.REGISTER_X, runtime.amNone);
}

fn changeReal34Sign(value: *runtime.real34_t) void {
    value.bytes[15] ^= 0x80;
}

fn conjRema() void {
    var complex_matrix: runtime.complex34Matrix_t = undefined;

    runtime.convertReal34MatrixRegisterToComplex34Matrix(runtime.REGISTER_X, &complex_matrix);
    if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        const count = @min(
            @as(usize, complex_matrix.header.matrixRows) * @as(usize, complex_matrix.header.matrixColumns),
            complex_matrix.matrixElements.len,
        );

        var index: usize = 0;
        while (index < count) : (index += 1) {
            changeReal34Sign(&complex_matrix.matrixElements[index].imag);
        }
    }

    runtime.convertComplex34MatrixToComplex34MatrixRegister(&complex_matrix, runtime.REGISTER_X);
}

fn conjCxma() void {
    var complex_matrix: runtime.complex34Matrix_t = undefined;

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &complex_matrix);
    const count = @min(
        @as(usize, complex_matrix.header.matrixRows) * @as(usize, complex_matrix.header.matrixColumns),
        complex_matrix.matrixElements.len,
    );

    var index: usize = 0;
    while (index < count) : (index += 1) {
        changeReal34Sign(&complex_matrix.matrixElements[index].imag);
        if (runtime.real34IsZero(&complex_matrix.matrixElements[index].imag) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.real34SetPositiveSign(&complex_matrix.matrixElements[index].imag);
        }
    }

    runtime.convertComplex34MatrixToComplex34MatrixRegister(&complex_matrix, runtime.REGISTER_X);
}

fn conjCplx() callconv(.c) void {
    var real_value: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &real_value, &imag_value)) {
        return;
    }

    runtime.realChangeSign(&imag_value);
    if (runtime.realIsZero(&imag_value) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.realSetPositiveSign(&imag_value);
    }

    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtComplex34, 0, runtime.amNone);
    runtime.convertComplexToResultRegister(&real_value, &imag_value, runtime.REGISTER_X);
}

fn swapReImCplx() callconv(.c) void {
    var real_value: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &real_value, &imag_value)) {
        return;
    }

    runtime.convertComplexToResultRegister(&imag_value, &real_value, runtime.REGISTER_X);
}

fn swapReImRema() void {
    var complex_matrix: runtime.complex34Matrix_t = undefined;
    var real_matrix: runtime.real34Matrix_t = undefined;

    runtime.linkToRealMatrixRegister(runtime.REGISTER_X, &real_matrix);
    runtime.convertReal34MatrixToComplex34Matrix(&real_matrix, &complex_matrix);

    const count = @min(
        @as(usize, complex_matrix.header.matrixRows) * @as(usize, complex_matrix.header.matrixColumns),
        complex_matrix.matrixElements.len,
    );

    var index: usize = 0;
    while (index < count) : (index += 1) {
        complex_matrix.matrixElements[index].imag = complex_matrix.matrixElements[index].real;
        complex_matrix.matrixElements[index].real = std.mem.zeroes(runtime.real34_t);
    }

    runtime.convertComplex34MatrixToComplex34MatrixRegister(&complex_matrix, runtime.REGISTER_X);
    runtime.complexMatrixFree(&complex_matrix);
}

fn swapReImCxma() void {
    var complex_matrix: runtime.complex34Matrix_t = undefined;

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &complex_matrix);
    const count = @min(
        @as(usize, complex_matrix.header.matrixRows) * @as(usize, complex_matrix.header.matrixColumns),
        complex_matrix.matrixElements.len,
    );

    var index: usize = 0;
    while (index < count) : (index += 1) {
        const real_value = complex_matrix.matrixElements[index].real;
        complex_matrix.matrixElements[index].real = complex_matrix.matrixElements[index].imag;
        complex_matrix.matrixElements[index].imag = real_value;
    }

    runtime.convertComplex34MatrixToComplex34MatrixRegister(&complex_matrix, runtime.REGISTER_X);
}

fn atan2RemaReal() void {
    var y_matrix: runtime.real34Matrix_t = undefined;
    var x_scalar: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_scalar)) {
        return;
    }

    runtime.linkToRealMatrixRegister(runtime.REGISTER_Y, &y_matrix);
    const count = @min(
        @as(usize, y_matrix.header.matrixRows) * @as(usize, y_matrix.header.matrixColumns),
        y_matrix.matrixElements.len,
    );

    var index: usize = 0;
    while (index < count) : (index += 1) {
        var y_value: runtime.real_t = undefined;
        var x_value = x_scalar;

        runtime.real34ToReal(&y_matrix.matrixElements[index], &y_value);
        if (runtime.realIsZero(&y_value) and runtime.realIsZero(&x_value) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            runtime.moreInfoOnError("In function atan2RemaReal:", "X = 0 and Y = 0", null, null);
            return;
        }

        runtime.C47_WP34S_Atan2(&y_value, &x_value, &x_value, &runtime.ctxtReal39);
        runtime.convertAngleFromTo(&x_value, runtime.amRadian, runtime.currentAngularMode, &runtime.ctxtReal39);
        runtime.roundToSignificantDigits(&x_value, &x_value, if (runtime.significantDigits == 0) 34 else runtime.significantDigits, &runtime.ctxtReal75);
        runtime.realToReal34(&x_value, &y_matrix.matrixElements[index]);
    }

    runtime.convertReal34MatrixToReal34MatrixRegister(&y_matrix, runtime.REGISTER_X);
}

fn atan2RemaRema() void {
    var y_matrix: runtime.real34Matrix_t = undefined;
    var x_matrix: runtime.real34Matrix_t = undefined;

    runtime.linkToRealMatrixRegister(runtime.REGISTER_Y, &y_matrix);
    runtime.linkToRealMatrixRegister(runtime.REGISTER_X, &x_matrix);

    if (y_matrix.header.matrixRows != x_matrix.header.matrixRows or y_matrix.header.matrixColumns != x_matrix.header.matrixColumns) {
        runtime.displayCalcErrorMessage(runtime.ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function atan2RemaRema:", "matrix size mismatch", null, null);
        return;
    }

    const count = @min(
        @as(usize, x_matrix.header.matrixRows) * @as(usize, x_matrix.header.matrixColumns),
        @min(x_matrix.matrixElements.len, y_matrix.matrixElements.len),
    );

    var index: usize = 0;
    while (index < count) : (index += 1) {
        var y_value: runtime.real_t = undefined;
        var x_value: runtime.real_t = undefined;

        runtime.real34ToReal(&y_matrix.matrixElements[index], &y_value);
        runtime.real34ToReal(&x_matrix.matrixElements[index], &x_value);
        if (runtime.realIsZero(&y_value) and runtime.realIsZero(&x_value) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            runtime.moreInfoOnError("In function atan2RemaRema:", "X = 0 and Y = 0", null, null);
            return;
        }

        runtime.C47_WP34S_Atan2(&y_value, &x_value, &x_value, &runtime.ctxtReal39);
        runtime.convertAngleFromTo(&x_value, runtime.amRadian, runtime.currentAngularMode, &runtime.ctxtReal39);
        runtime.roundToSignificantDigits(&x_value, &x_value, if (runtime.significantDigits == 0) 34 else runtime.significantDigits, &runtime.ctxtReal75);
        runtime.realToReal34(&x_value, &x_matrix.matrixElements[index]);
    }

    runtime.convertReal34MatrixToReal34MatrixRegister(&x_matrix, runtime.REGISTER_X);
}

fn atan2RealRema() void {
    var y_scalar: runtime.real_t = undefined;
    var x_matrix: runtime.real34Matrix_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_Y, &y_scalar)) {
        return;
    }

    runtime.linkToRealMatrixRegister(runtime.REGISTER_X, &x_matrix);
    const count = @min(
        @as(usize, x_matrix.header.matrixRows) * @as(usize, x_matrix.header.matrixColumns),
        x_matrix.matrixElements.len,
    );

    var index: usize = 0;
    while (index < count) : (index += 1) {
        var y_value = y_scalar;
        var x_value: runtime.real_t = undefined;

        runtime.real34ToReal(&x_matrix.matrixElements[index], &x_value);
        if (runtime.realIsZero(&y_value) and runtime.realIsZero(&x_value) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            runtime.moreInfoOnError("In function atan2RealRema:", "X = 0 and Y = 0", null, null);
            return;
        }

        runtime.C47_WP34S_Atan2(&y_value, &x_value, &x_value, &runtime.ctxtReal39);
        runtime.convertAngleFromTo(&x_value, runtime.amRadian, runtime.currentAngularMode, &runtime.ctxtReal39);
        runtime.roundToSignificantDigits(&x_value, &x_value, if (runtime.significantDigits == 0) 34 else runtime.significantDigits, &runtime.ctxtReal75);
        runtime.realToReal34(&x_value, &x_matrix.matrixElements[index]);
    }

    runtime.convertReal34MatrixToReal34MatrixRegister(&x_matrix, runtime.REGISTER_X);
}

fn atan2Error() void {
    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
    runtime.moreInfoOnError("In function fnAtan2:", "cannot calculate atan2 for current X and Y types", null, null);
}

fn atan2RealReal() callconv(.c) void {
    var y_value: runtime.real_t = undefined;
    var x_value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value) or !runtime.getRegisterAsReal(runtime.REGISTER_Y, &y_value)) {
        return;
    }

    if (runtime.realIsZero(&y_value) and runtime.realIsZero(&x_value) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function atan2RealReal:", "X = 0 and Y = 0", null, null);
        return;
    }

    runtime.C47_WP34S_Atan2(&y_value, &x_value, &x_value, &runtime.ctxtReal39);
    runtime.convertAngleFromTo(&x_value, runtime.amRadian, runtime.currentAngularMode, &runtime.ctxtReal39);
    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, @intCast(runtime.currentAngularMode));
    runtime.convertRealToReal34ResultRegister(&x_value, runtime.REGISTER_X);
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

fn doIP(x: *runtime.real_t, mode: runtime.rounding_t) void {
    if (runtime.realIsSpecial(x)) {
        if (!runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        }
    } else {
        runtime.realToIntegralValue(x, x, mode, &runtime.ctxtReal39);
    }
}

fn argReal() callconv(.c) void {
    var x_value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value)) {
        return;
    }

    const result = realArgValue(&x_value);

    runtime.convertRealToResultRegister(result, runtime.REGISTER_X, runtime.amNone);
    if (!runtime.realIsNaN(result)) {
        runtime.convertAngle34FromTo(runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.amDegree, runtime.currentAngularMode);
        runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.currentAngularMode);
    }
}

fn realArgValue(x_value: *const runtime.real_t) *const runtime.real_t {
    return if (runtime.realIsNaN(x_value))
        x_value
    else if (runtime.realIsZero(x_value) and runtime.getSystemFlag(runtime.FLAG_SPCRES))
        x_value
    else if (runtime.realIsNegative(x_value))
        runtime.z47_math_wrappers_const_180()
    else
        runtime.z47_math_wrappers_const_0();
}

fn argError() void {
    _ = runtime.getRegisterAsReal(runtime.REGISTER_X, null);
}

fn argCplx() callconv(.c) void {
    var real_value: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &real_value, &imag_value)) {
        return;
    }

    runtime.realRectangularToPolar(&real_value, &imag_value, &real_value, &imag_value, &runtime.ctxtReal39);
    runtime.convertAngleFromTo(&imag_value, runtime.amRadian, runtime.currentAngularMode, &runtime.ctxtReal39);

    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, @intCast(runtime.currentAngularMode));
    runtime.convertRealToReal34ResultRegister(&imag_value, runtime.REGISTER_X);
}

fn argRema() void {
    var matrix: runtime.real34Matrix_t = undefined;

    runtime.convertReal34MatrixRegisterToReal34Matrix(runtime.REGISTER_X, &matrix);
    defer runtime.realMatrixFree(&matrix);

    const count = @min(
        @as(usize, matrix.header.matrixRows) * @as(usize, matrix.header.matrixColumns),
        matrix.matrixElements.len,
    );

    var index: usize = 0;
    while (index < count) : (index += 1) {
        var real_value: runtime.real_t = undefined;

        runtime.real34ToReal(&matrix.matrixElements[index], &real_value);
        real_value = realArgValue(&real_value).*;
        runtime.convertAngleFromTo(&real_value, runtime.amDegree, runtime.currentAngularMode, &runtime.ctxtReal39);
        runtime.realToReal34(&real_value, &matrix.matrixElements[index]);
    }

    runtime.convertReal34MatrixToReal34MatrixRegister(&matrix, runtime.REGISTER_X);
}

fn argCxma() void {
    var complex_matrix: runtime.complex34Matrix_t = undefined;
    var real_matrix: runtime.real34Matrix_t = undefined;
    var dummy = std.mem.zeroes(runtime.real34_t);

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &complex_matrix);
    if (!runtime.realMatrixInit(&real_matrix, complex_matrix.header.matrixRows, complex_matrix.header.matrixColumns)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        return;
    }
    defer runtime.realMatrixFree(&real_matrix);

    const count = @min(
        @as(usize, complex_matrix.header.matrixRows) * @as(usize, complex_matrix.header.matrixColumns),
        real_matrix.matrixElements.len,
    );

    var index: usize = 0;
    while (index < count) : (index += 1) {
        runtime.real34RectangularToPolar(
            &complex_matrix.matrixElements[index].real,
            &complex_matrix.matrixElements[index].imag,
            &dummy,
            &real_matrix.matrixElements[index],
        );
        runtime.convertAngle34FromTo(&real_matrix.matrixElements[index], runtime.amRadian, runtime.currentAngularMode);
    }

    runtime.convertReal34MatrixToReal34MatrixRegister(&real_matrix, runtime.REGISTER_X);
}

fn wInvReal() callconv(.c) void {
    var x_value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value)) {
        return;
    }

    runtime.WP34S_InverseW(&x_value, &x_value, &runtime.ctxtReal39);
    runtime.convertRealToResultRegister(&x_value, runtime.REGISTER_X, runtime.amNone);
}

fn wInvCplx() callconv(.c) void {
    var real_value: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;
    var result_real: runtime.real_t = undefined;
    var result_imag: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &real_value, &imag_value)) {
        return;
    }

    runtime.WP34S_InverseComplexW(&real_value, &imag_value, &result_real, &result_imag, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&result_real, &result_imag, runtime.REGISTER_X);
}

fn minusOneOverE() runtime.real_t {
    var value = runtime.z47_math_wrappers_const_1oneE().*;
    runtime.realChangeSign(&value);
    return value;
}

fn wPosReal() callconv(.c) void {
    var x_value: runtime.real_t = undefined;
    var result: runtime.real_t = undefined;
    var result_imag: runtime.real_t = undefined;
    const limit = minusOneOverE();

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value)) {
        return;
    }

    if (realCompareGreaterEqual(&x_value, &limit)) {
        runtime.WP34S_LambertW(&x_value, &result, false, &runtime.ctxtReal39);
        runtime.convertRealToResultRegister(&result, runtime.REGISTER_X, runtime.amNone);
    } else if (runtime.getSystemFlag(runtime.FLAG_CPXRES)) {
        runtime.WP34S_ComplexLambertW(&x_value, runtime.z47_math_wrappers_const_0(), &result, &result_imag, &runtime.ctxtReal39);
        runtime.convertComplexToResultRegister(&result, &result_imag, runtime.REGISTER_X);
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function wPosReal:", "X < -e^(-1)", "and CPXRES is not set!", null);
    }
}

fn wPosCplx() callconv(.c) void {
    var real_value: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;
    var result_real: runtime.real_t = undefined;
    var result_imag: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &real_value, &imag_value)) {
        return;
    }

    runtime.WP34S_ComplexLambertW(&real_value, &imag_value, &result_real, &result_imag, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&result_real, &result_imag, runtime.REGISTER_X);
}

fn wNegReal() callconv(.c) void {
    var x_value: runtime.real_t = undefined;
    var result: runtime.real_t = undefined;
    const limit = minusOneOverE();

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value)) {
        return;
    }

    if (realCompareGreaterEqual(&x_value, &limit) and realCompareLessEqual(&x_value, runtime.z47_math_wrappers_const_0())) {
        runtime.WP34S_LambertW(&x_value, &result, true, &runtime.ctxtReal39);
        runtime.convertRealToResultRegister(&result, runtime.REGISTER_X, runtime.amNone);
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function wNegReal:", "X < -e^(-1) || 0 < X", null, null);
    }
}

fn wNegCplx() callconv(.c) void {
    var real_value: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;
    var result: runtime.real_t = undefined;
    const limit = minusOneOverE();

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &real_value, &imag_value)) {
        return;
    }

    if (runtime.realIsZero(&imag_value)) {
        if (realCompareGreaterEqual(&real_value, &limit) and realCompareLessEqual(&real_value, runtime.z47_math_wrappers_const_0())) {
            runtime.WP34S_LambertW(&real_value, &result, true, &runtime.ctxtReal39);
            runtime.convertComplexToResultRegister(&result, runtime.z47_math_wrappers_const_0(), runtime.REGISTER_X);
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            runtime.moreInfoOnError("In function wNegCplx:", "X < -e^(-1) || 0 < X", null, null);
        }
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function wNegCplx:", "Cannot calculate Wm for complex number with non-zero imaginary part", null, null);
    }
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

    runtime.WP34S_Mod(&y_value, &x_value, &result, &runtime.ctxtReal39);
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

    runtime.WP34S_Mod(&y_value, &x_value, &result, &runtime.ctxtReal39);
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

fn fpRealForward() callconv(.c) void {
    var integral: runtime.real34_t = undefined;

    runtime.real34ToIntegralValue(runtime.registerReal34Ptr(runtime.REGISTER_X), &integral, runtime.DEC_ROUND_DOWN);
    runtime.real34Subtract(runtime.registerReal34Ptr(runtime.REGISTER_X), &integral, runtime.registerReal34Ptr(runtime.REGISTER_X));
}

fn fpShoIForward() callconv(.c) void {
    var result: u64 = 0;

    if (runtime.shortIntegerMode == runtime.SIM_1COMPL or runtime.shortIntegerMode == runtime.SIM_SIGNMT) {
        const value = runtime.registerShortIntegerPtr(runtime.REGISTER_X).*;
        if ((value & runtime.shortIntegerSignBit) != 0) {
            result = if (runtime.shortIntegerMode == runtime.SIM_1COMPL) runtime.shortIntegerMask else runtime.shortIntegerSignBit;
        }
    }

    runtime.registerShortIntegerPtr(runtime.REGISTER_X).* = result;
}

fn fpLonIForward() callconv(.c) void {
    runtime.z47_math_wrappers_build_sign_result(0);
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

fn squareLonI() callconv(.c) void {
    var x: runtime.longInteger_t = undefined;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &x[0], null)) {
        return;
    }
    defer runtime.__gmpz_clear(&x[0]);

    runtime.__gmpz_mul(&x[0], &x[0], &x[0]);
    runtime.convertLongIntegerToLongIntegerRegister(&x[0], runtime.REGISTER_X);
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
    var x: runtime.longInteger_t = undefined;
    var cube: runtime.longInteger_t = undefined;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &x[0], null)) {
        return;
    }
    defer runtime.__gmpz_clear(&x[0]);

    runtime.__gmpz_init(&cube[0]);
    defer runtime.__gmpz_clear(&cube[0]);

    runtime.__gmpz_mul(&cube[0], &x[0], &x[0]);
    runtime.__gmpz_mul(&cube[0], &cube[0], &x[0]);
    runtime.convertLongIntegerToLongIntegerRegister(&cube[0], runtime.REGISTER_X);
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

fn doIntRandomI() callconv(.c) void {
    const range_limit: u32 = 0xFFFFFFFE;

    var x: runtime.longInteger_t = undefined;
    var y: runtime.longInteger_t = undefined;
    var frac_x = false;
    var frac_y = false;

    runtime.saveForUndo();
    runtime.thereIsSomethingToUndo = true;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &x[0], &frac_x)) {
        return;
    }
    defer runtime.__gmpz_clear(&x[0]);
    if (frac_x) {
        return;
    }

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_Y, &y[0], &frac_y)) {
        return;
    }
    defer runtime.__gmpz_clear(&y[0]);
    if (frac_y) {
        return;
    }

    const cmp = runtime.__gmpz_cmp(&x[0], &y[0]);
    if (cmp == 0) {
        runtime.convertLongIntegerToLongIntegerRegister(&x[0], runtime.REGISTER_X);
        runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, no_register, no_register);
        return;
    }

    const min_value = if (cmp < 0) &x[0] else &y[0];
    const max_value = if (cmp < 0) &y[0] else &x[0];

    var range: runtime.longInteger_t = undefined;
    runtime.__gmpz_init(&range[0]);
    defer runtime.__gmpz_clear(&range[0]);
    runtime.__gmpz_sub(&range[0], max_value, min_value);

    if (runtime.__gmpz_cmp_ui(&range[0], range_limit) >= 0) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function doIntRandomI:", "cannot RANI# with |X - Y| >= 2^32", null, null);
        runtime.fnUndo(0);
        return;
    }

    var max_rand: u32 = @intCast(runtime.__gmpz_get_ui(&range[0]));
    max_rand = boundedRand(max_rand + 1);

    var result: runtime.longInteger_t = undefined;
    runtime.__gmpz_init(&result[0]);
    defer runtime.__gmpz_clear(&result[0]);
    runtime.__gmpz_add_ui(&result[0], min_value, max_rand);

    runtime.convertLongIntegerToLongIntegerRegister(&result[0], runtime.REGISTER_X);
    runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, no_register, no_register);
}

pub export fn fnRandomI(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexDyadicFunction(&doRealRandomI, null, null, &doIntRandomI);
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

    var value: runtime.longInteger_t = undefined;
    const data_type = runtime.getRegisterDataType(runtime.REGISTER_X);

    if (!runtime.saveLastX()) {
        return;
    }

    if (runtime.getRegisterAsLongInt(runtime.REGISTER_X, &value[0], null)) {
        defer runtime.__gmpz_clear(&value[0]);

        runtime.convertLongIntegerToLongIntegerRegister(&value[0], runtime.REGISTER_X);
        if (data_type == runtime.dtShortInteger) {
            runtime.setLastintegerBasetoZero();
        }
    }
}

pub export fn fnSint(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    var sign: bool = false;
    var value: u64 = 0;
    var overflow: bool = false;
    var fractional: bool = false;

    if (!runtime.saveLastX()) {
        return;
    }

    if (!runtime.getRegisterAsShortInt(runtime.REGISTER_X, &sign, &value, &overflow, &fractional)) {
        return;
    }

    if (runtime.getRegisterDataType(runtime.REGISTER_X) != runtime.dtShortInteger) {
        runtime.convertUInt64ToShortIntegerRegister(@intFromBool(sign), value, 10, runtime.REGISTER_X);
    }
    runtime.forceSystemFlag(@intCast(runtime.FLAG_CARRY), @intFromBool(fractional));
    runtime.forceSystemFlag(@intCast(runtime.FLAG_OVERFLOW), @intFromBool(overflow));
}

pub export fn fnFp(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexMonadicFunction(
        &fpRealForward,
        null,
        &fpShoIForward,
        &fpLonIForward,
    );
}

pub export fn fnSinc(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&sincReal, &sincCplx);
}

pub export fn fnSincpi(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&sincpiReal, &sincpiCplx);
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

pub export fn fnExpM1(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&expM1Real, &expM1Cplx);
}

pub export fn fnLn(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&lnReal, &lnCplx);
}

pub export fn fnLnP1(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&lnP1Real, &lnP1Cplx);
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
    _ = unused_but_mandatory_parameter;
    runtime.processRealComplexMonadicFunction(&wPosReal, &wPosCplx);
}

pub export fn fnWnegative(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processRealComplexMonadicFunction(&wNegReal, &wNegCplx);
}

pub export fn fnWinverse(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processRealComplexMonadicFunction(&wInvReal, &wInvCplx);
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

fn setPowerOfTwo(result: *runtime.mpz_struct, exponent: u32) void {
    runtime.__gmpz_set_ui(result, 1);
    runtime.__gmpz_mul_2exp(result, result, @as(c_ulong, @intCast(exponent)));
}

fn initShortIntegerRegisterAsLongInteger(reg: runtime.calcRegister_t, value: *runtime.longInteger_t) void {
    var sign: i16 = 0;
    var raw_value: u64 = 0;

    runtime.convertShortIntegerRegisterToUInt64(reg, &sign, &raw_value);
    runtime.__gmpz_init(&value[0]);
    runtime.__gmpz_set_ui(&value[0], @as(c_ulong, @intCast(raw_value >> 32)));
    runtime.__gmpz_mul_2exp(&value[0], &value[0], 32);
    runtime.__gmpz_add_ui(&value[0], &value[0], @as(c_ulong, @intCast(@as(u32, @truncate(raw_value)))));

    if (sign != 0) {
        longIntegerSetNegativeSign(&value[0]);
    }
}

fn reportDblMultiplyTypeError(reg: runtime.calcRegister_t) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_T);
    _ = runtime.getRegisterDataType(reg);
    runtime.moreInfoOnError("In function fnDblMultiply:", "the input type is not allowed for DBLx!", null, null);
}

fn requireDblMultiplyShortInteger(reg: runtime.calcRegister_t) bool {
    if (runtime.getRegisterDataType(reg) == runtime.dtShortInteger) {
        return true;
    }

    reportDblMultiplyTypeError(reg);
    return false;
}

fn dblMultiply() void {
    if (!requireDblMultiplyShortInteger(runtime.REGISTER_X) or
        !requireDblMultiplyShortInteger(runtime.REGISTER_Y))
    {
        return;
    }

    if (!runtime.saveLastX()) {
        return;
    }

    const sim = runtime.shortIntegerMode;
    defer runtime.shortIntegerMode = sim;
    const word_size: u32 = runtime.shortIntegerWordSize;
    const base = runtime.getRegisterTag(runtime.REGISTER_Y);
    var signs_differ = false;

    if (sim == runtime.SIM_1COMPL or sim == runtime.SIM_SIGNMT) {
        const y_negative = (runtime.registerShortIntegerPtr(runtime.REGISTER_Y).* & runtime.shortIntegerSignBit) != 0;
        const x_negative = (runtime.registerShortIntegerPtr(runtime.REGISTER_X).* & runtime.shortIntegerSignBit) != 0;
        signs_differ = y_negative != x_negative;
    }

    var scale: runtime.longInteger_t = undefined;
    runtime.__gmpz_init(&scale[0]);
    defer runtime.__gmpz_clear(&scale[0]);
    setPowerOfTwo(&scale[0], word_size);

    var y_value: runtime.longInteger_t = undefined;
    initShortIntegerRegisterAsLongInteger(runtime.REGISTER_Y, &y_value);
    defer runtime.__gmpz_clear(&y_value[0]);

    var x_value: runtime.longInteger_t = undefined;
    initShortIntegerRegisterAsLongInteger(runtime.REGISTER_X, &x_value);
    defer runtime.__gmpz_clear(&x_value[0]);

    var product: runtime.longInteger_t = undefined;
    runtime.__gmpz_init(&product[0]);
    defer runtime.__gmpz_clear(&product[0]);
    runtime.__gmpz_mul(&product[0], &y_value[0], &x_value[0]);

    if (sim == runtime.SIM_1COMPL) {
        if (signs_differ) {
            runtime.__gmpz_sub_ui(&product[0], &product[0], 1);
        }
        runtime.shortIntegerMode = runtime.SIM_2COMPL;
    } else if (sim == runtime.SIM_SIGNMT) {
        longIntegerSetPositiveSign(&product[0]);
        runtime.shortIntegerMode = runtime.SIM_UNSIGN;
    }

    runtime.__gmpz_tdiv_qr(&x_value[0], &y_value[0], &product[0], &scale[0]);

    if (sim == runtime.SIM_SIGNMT) {
        runtime.shortIntegerMode = runtime.SIM_SIGNMT;
        if (signs_differ) {
            longIntegerSetNegativeSign(&x_value[0]);
        }
    }

    runtime.convertLongIntegerToShortIntegerRegister(&y_value[0], base, runtime.REGISTER_Y);
    runtime.convertLongIntegerToShortIntegerRegister(&x_value[0], base, runtime.REGISTER_X);
    runtime.clearSystemFlag(runtime.FLAG_OVERFLOW);
}

fn reportDblDivideTypeError(reg: runtime.calcRegister_t) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_T);
    _ = runtime.getRegisterDataType(reg);
    runtime.moreInfoOnError("In function dblDivide:", "the input type is not allowed for DBL divide!", null, null);
}

fn reportDblDivideZeroDivisor() void {
    runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_T);
    runtime.moreInfoOnError("In function dblDivide:", "cannot divide a short integer by 0", null, null);
}

fn reportDblDivideOverflow() void {
    runtime.displayCalcErrorMessage(runtime.ERROR_OUT_OF_RANGE, runtime.ERR_REGISTER_LINE, runtime.REGISTER_T);
    runtime.moreInfoOnError("In function dblDivide:", "quotient overflow", null, null);
}

fn requireDblDivideShortInteger(reg: runtime.calcRegister_t) bool {
    if (runtime.getRegisterDataType(reg) == runtime.dtShortInteger) {
        return true;
    }

    reportDblDivideTypeError(reg);
    return false;
}

fn dblDivide(remainder_mode: bool) void {
    if (!requireDblDivideShortInteger(runtime.REGISTER_X) or
        !requireDblDivideShortInteger(runtime.REGISTER_Y) or
        !requireDblDivideShortInteger(runtime.REGISTER_Z))
    {
        return;
    }

    const sim = runtime.shortIntegerMode;
    const word_size: u32 = runtime.shortIntegerWordSize;

    var divisor: runtime.longInteger_t = undefined;
    initShortIntegerRegisterAsLongInteger(runtime.REGISTER_X, &divisor);
    defer runtime.__gmpz_clear(&divisor[0]);

    if (divisor[0]._mp_size == 0) {
        reportDblDivideZeroDivisor();
        return;
    }

    var scale: runtime.longInteger_t = undefined;
    runtime.__gmpz_init(&scale[0]);
    defer runtime.__gmpz_clear(&scale[0]);
    setPowerOfTwo(&scale[0], word_size);

    var dividend_hi: runtime.longInteger_t = undefined;
    var dividend_lo: runtime.longInteger_t = undefined;
    runtime.shortIntegerMode = runtime.SIM_UNSIGN;
    defer runtime.shortIntegerMode = sim;
    initShortIntegerRegisterAsLongInteger(runtime.REGISTER_Z, &dividend_lo);
    defer runtime.__gmpz_clear(&dividend_lo[0]);
    initShortIntegerRegisterAsLongInteger(runtime.REGISTER_Y, &dividend_hi);
    defer runtime.__gmpz_clear(&dividend_hi[0]);

    const base = runtime.getRegisterTag(runtime.REGISTER_Y);

    var dividend: runtime.longInteger_t = undefined;
    runtime.__gmpz_init(&dividend[0]);
    defer runtime.__gmpz_clear(&dividend[0]);
    runtime.__gmpz_mul(&dividend[0], &dividend_hi[0], &scale[0]);
    runtime.__gmpz_add(&dividend[0], &dividend[0], &dividend_lo[0]);

    if (sim != runtime.SIM_UNSIGN) {
        setPowerOfTwo(&scale[0], word_size * 2 - 1);
        if (runtime.__gmpz_cmp(&dividend[0], &scale[0]) >= 0) {
            if (sim == runtime.SIM_SIGNMT) {
                runtime.__gmpz_sub(&dividend[0], &dividend[0], &scale[0]);
                longIntegerSetNegativeSign(&dividend[0]);
            } else {
                setPowerOfTwo(&scale[0], word_size * 2);
                if (sim == runtime.SIM_1COMPL) {
                    runtime.__gmpz_sub_ui(&scale[0], &scale[0], 1);
                }
                runtime.__gmpz_sub(&dividend[0], &scale[0], &dividend[0]);
                longIntegerSetNegativeSign(&dividend[0]);
            }
        }
        setPowerOfTwo(&scale[0], word_size - 1);
    }

    runtime.__gmpz_tdiv_qr(&dividend_lo[0], &dividend_hi[0], &dividend[0], &divisor[0]);

    if (remainder_mode) {
        if (!runtime.saveLastX()) {
            return;
        }
        runtime.convertLongIntegerToShortIntegerRegister(&dividend_hi[0], base, runtime.REGISTER_X);
    } else {
        longIntegerSetPositiveSign(&scale[0]);
        if (runtime.__gmpz_cmp(&dividend_lo[0], &scale[0]) >= 0) {
            reportDblDivideOverflow();
            return;
        }

        if (sim != runtime.SIM_UNSIGN) {
            longIntegerSetNegativeSign(&scale[0]);
            const quotient_cmp = runtime.__gmpz_cmp(&dividend_lo[0], &scale[0]);
            if (quotient_cmp < 0 or (sim != runtime.SIM_2COMPL and quotient_cmp == 0)) {
                reportDblDivideOverflow();
                return;
            }
        }

        if (!runtime.saveLastX()) {
            return;
        }

        runtime.convertLongIntegerToShortIntegerRegister(&dividend_lo[0], base, runtime.REGISTER_X);

        if (dividend_hi[0]._mp_size == 0) {
            runtime.clearSystemFlag(runtime.FLAG_CARRY);
        } else {
            runtime.setSystemFlag(runtime.FLAG_CARRY);
        }

        runtime.clearSystemFlag(runtime.FLAG_OVERFLOW);
    }

    runtime.fnDropY(0);
    if (runtime.lastErrorCode == runtime.ERROR_NONE) {
        runtime.fnDropY(0);
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

    if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtComplex34Matrix) {
        if (!runtime.saveLastX()) {
            return;
        }

        realPartCxma();
        return;
    }

    runtime.processRealComplexMonadicFunction(&realPartReal, &realPartCplx);
}

pub export fn fnImaginaryPart(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtComplex34Matrix) {
        if (!runtime.saveLastX()) {
            return;
        }

        imagPartCxma();
        return;
    }

    runtime.processRealComplexMonadicFunction(&imagPartReal, &imagPartCplx);
}

pub export fn fnArg(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);

    _ = unused_but_mandatory_parameter;

    if (!runtime.saveLastX()) {
        return;
    }

    switch (register_data_type) {
        runtime.dtLongInteger, runtime.dtReal34, runtime.dtShortInteger => argReal(),
        runtime.dtComplex34 => argCplx(),
        runtime.dtReal34Matrix => argRema(),
        runtime.dtComplex34Matrix => argCxma(),
        else => argError(),
    }

    runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, no_register, no_register);
}

pub export fn fnMagnitude(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtComplex34Matrix) {
        if (!runtime.saveLastX()) {
            return;
        }

        magnitudeCxma();
        return;
    }

    runtime.processIntRealComplexMonadicFunction(&magnitudeReal, &magnitudeCplx, &magnitudeShoI, &magnitudeLonI);
}

pub export fn fnConjugate(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);

    _ = unused_but_mandatory_parameter;

    if (!runtime.saveLastX()) {
        return;
    }

    if (register_data_type == runtime.dtComplex34Matrix) {
        conjCxma();
        return;
    }

    if (register_data_type == runtime.dtReal34Matrix) {
        conjRema();
        return;
    }

    conjCplx();
}

pub export fn fnSwapRealImaginary(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);

    _ = unused_but_mandatory_parameter;

    if (!runtime.saveLastX()) {
        return;
    }

    if (register_data_type == runtime.dtReal34Matrix) {
        swapReImRema();
        return;
    }

    if (register_data_type == runtime.dtComplex34Matrix) {
        swapReImCxma();
        return;
    }

    swapReImCplx();
}

pub export fn fnAtan2(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const data_type_x = runtime.getRegisterDataType(runtime.REGISTER_X);
    const data_type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);

    _ = unused_but_mandatory_parameter;

    if (!runtime.saveLastX()) {
        return;
    }

    if ((data_type_x == runtime.dtReal34 or data_type_x == runtime.dtLongInteger) and (data_type_y == runtime.dtReal34 or data_type_y == runtime.dtLongInteger)) {
        atan2RealReal();
    } else if (data_type_x == runtime.dtReal34Matrix and data_type_y == runtime.dtReal34Matrix) {
        atan2RemaRema();
    } else if (data_type_x == runtime.dtReal34Matrix and (data_type_y == runtime.dtReal34 or data_type_y == runtime.dtLongInteger or data_type_y == runtime.dtShortInteger)) {
        atan2RealRema();
    } else if (data_type_y == runtime.dtReal34Matrix and (data_type_x == runtime.dtReal34 or data_type_x == runtime.dtLongInteger or data_type_x == runtime.dtShortInteger)) {
        runtime.elementwiseRemaReal(&atan2RealReal);
    } else {
        atan2Error();
    }

    runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, runtime.REGISTER_Y, no_register);
}

pub export fn fnPercent(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    var register_x = std.mem.zeroes(runtime.real_t);
    var register_y = std.mem.zeroes(runtime.real_t);
    var result = std.mem.zeroes(runtime.real_t);

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &register_x) or !runtime.getRegisterAsReal(runtime.REGISTER_Y, &register_y)) {
        return;
    }

    if (!runtime.saveLastX()) {
        return;
    }

    runtime.realMultiply(&register_x, &register_y, &result, &runtime.ctxtReal34);
    result.exponent -= 2;

    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
    runtime.convertRealToReal34ResultRegister(&result, runtime.REGISTER_X);
    runtime.adjustResult(runtime.REGISTER_X, false, true, runtime.REGISTER_X, no_register, no_register);
}

pub export fn fnAdd(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnAdd(unused_but_mandatory_parameter);
}

pub export fn fnSubtract(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnSubtract(unused_but_mandatory_parameter);
}

pub export fn fnMultiply(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnMultiply(unused_but_mandatory_parameter);
}

pub export fn fnDivide(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnDivide(unused_but_mandatory_parameter);
}

pub export fn fnIDiv(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnIDiv(unused_but_mandatory_parameter);
}

pub export fn fnIDivR(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnIDivR(unused_but_mandatory_parameter);
}

pub export fn fnDblMultiply(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    dblMultiply();
}

pub export fn fnRound(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    if (register_data_type != runtime.dtLongInteger and register_data_type != runtime.dtShortInteger) {
        z47_math_wrappers_retained_fnRound(unused_but_mandatory_parameter);
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
    const message = std.fmt.bufPrintZ(&message_buffer, "cannot calculate Decomp for {s}", .{type_name}) catch "cannot calculate Decomp";

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

const CHECK_INTEGER: u16 = 0;
const CHECK_INTEGER_EVEN: u16 = 1;
const CHECK_INTEGER_ODD: u16 = 2;
const CHECK_INTEGER_FP: u16 = 3;
const ITM_ISREZQ: u16 = 2527;
const ITM_ISIMZQ: u16 = 2528;
const ITM_ISRENZQ: u16 = 2529;
const ITM_ISIMNZQ: u16 = 2530;

fn setCheckIntegerResult(mode: u16, is_odd: bool) void {
    switch (mode) {
        CHECK_INTEGER => runtime.setTemporaryInformation(true),
        CHECK_INTEGER_EVEN => runtime.setTemporaryInformation(!is_odd),
        CHECK_INTEGER_ODD => runtime.setTemporaryInformation(is_odd),
        CHECK_INTEGER_FP => runtime.setTemporaryInformation(false),
        else => {},
    }
}

pub export fn fnCheckInteger(mode: u16) callconv(.c) void {
    var value: runtime.longInteger_t = undefined;
    var fractional = false;
    const err = runtime.getRegisterAsLongIntQuiet(runtime.REGISTER_X, &value[0], &fractional);
    defer runtime.__gmpz_clear(&value[0]);

    if (err != @as(c_int, runtime.ERROR_NONE)) {
        compareTypeErrorX();
    } else if (fractional) {
        runtime.setTemporaryInformation(mode == CHECK_INTEGER_FP);
    } else {
        runtime.fnRefreshState();
        setCheckIntegerResult(mode, value[0]._mp_size != 0 and (value[0]._mp_d[0] & 1) != 0);
    }
}

pub export fn fnDec(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (unused_but_mandatory_parameter != runtime.REGISTER_X and unused_but_mandatory_parameter != runtime.REGISTER_Y and unused_but_mandatory_parameter != runtime.REGISTER_Z and unused_but_mandatory_parameter != runtime.REGISTER_T) {
        z47_math_wrappers_retained_fnDec(unused_but_mandatory_parameter);
        return;
    }

    incDecRegister(@intCast(unused_but_mandatory_parameter), dec_flag);
}

pub export fn fnInc(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (unused_but_mandatory_parameter != runtime.REGISTER_X and unused_but_mandatory_parameter != runtime.REGISTER_Y and unused_but_mandatory_parameter != runtime.REGISTER_Z and unused_but_mandatory_parameter != runtime.REGISTER_T) {
        z47_math_wrappers_retained_fnInc(unused_but_mandatory_parameter);
        return;
    }

    incDecRegister(@intCast(unused_but_mandatory_parameter), inc_flag);
}

pub export fn fnXLessThan(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const regist: runtime.calcRegister_t = @intCast(unused_but_mandatory_parameter);

    if (!isOwnedCompareRegister(regist)) {
        z47_math_wrappers_retained_fnXLessThan(unused_but_mandatory_parameter);
        return;
    }

    compareScalarRegister(regist, compare_mode_less_than);
}

pub export fn fnXLessEqual(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const regist: runtime.calcRegister_t = @intCast(unused_but_mandatory_parameter);

    if (!isOwnedCompareRegister(regist)) {
        z47_math_wrappers_retained_fnXLessEqual(unused_but_mandatory_parameter);
        return;
    }

    compareScalarRegister(regist, compare_mode_less_equal);
}

pub export fn fnXGreaterThan(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const regist: runtime.calcRegister_t = @intCast(unused_but_mandatory_parameter);

    if (!isOwnedCompareRegister(regist)) {
        z47_math_wrappers_retained_fnXGreaterThan(unused_but_mandatory_parameter);
        return;
    }

    compareScalarRegister(regist, compare_mode_greater_than);
}

pub export fn fnXGreaterEqual(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const regist: runtime.calcRegister_t = @intCast(unused_but_mandatory_parameter);

    if (!isOwnedCompareRegister(regist)) {
        z47_math_wrappers_retained_fnXGreaterEqual(unused_but_mandatory_parameter);
        return;
    }

    compareScalarRegister(regist, compare_mode_greater_equal);
}

pub export fn fnXEqualsTo(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const regist: runtime.calcRegister_t = @intCast(unused_but_mandatory_parameter);

    if (!isOwnedCompareRegister(regist)) {
        z47_math_wrappers_retained_fnXEqualsTo(unused_but_mandatory_parameter);
        return;
    }

    compareScalarRegister(regist, compare_mode_equal);
}

pub export fn fnXNotEqual(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const regist: runtime.calcRegister_t = @intCast(unused_but_mandatory_parameter);

    if (!isOwnedCompareRegister(regist)) {
        z47_math_wrappers_retained_fnXNotEqual(unused_but_mandatory_parameter);
        return;
    }

    compareScalarRegister(regist, compare_mode_not_equal);
}

pub export fn fnXAlmostEqual(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const regist: runtime.calcRegister_t = @intCast(unused_but_mandatory_parameter);
    const x_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    const regist_type = runtime.getRegisterDataType(regist);

    if (!isOwnedCompareRegister(regist) or !isOwnedAlmostEqualIntegerType(x_type) or !isOwnedAlmostEqualIntegerType(regist_type)) {
        z47_math_wrappers_retained_fnXAlmostEqual(unused_but_mandatory_parameter);
        return;
    }

    compareScalarRegister(regist, compare_mode_equal);
}

fn getConvergenceInput(
    regist: runtime.calcRegister_t,
    real: *runtime.real_t,
    imag: *runtime.real_t,
    is_complex: *bool,
) bool {
    switch (runtime.getRegisterDataType(regist)) {
        runtime.dtComplex34 => {
            is_complex.* = true;
            return runtime.getRegisterAsComplex(regist, real, imag);
        },
        runtime.dtReal34 => {
            if (!runtime.getRegisterAsReal(regist, real)) {
                return false;
            }
            runtime.realSetZero(imag);
            return true;
        },
        runtime.dtLongInteger => {
            runtime.convertLongIntegerRegisterToReal(regist, real, &runtime.ctxtReal39);
            runtime.realSetZero(imag);
            return true;
        },
        runtime.dtShortInteger => {
            runtime.convertShortIntegerRegisterToReal(regist, real, &runtime.ctxtReal39);
            runtime.realSetZero(imag);
            return true;
        },
        else => return false,
    }
}

const compare_mode_less_than: u8 = 0x1;
const compare_mode_equal: u8 = 0x2;
const compare_mode_less_equal: u8 = 0x3;
const compare_mode_greater_than: u8 = 0x4;
const compare_mode_not_equal: u8 = 0x5;
const compare_mode_greater_equal: u8 = 0x6;

fn isOwnedCompareRegister(regist: runtime.calcRegister_t) bool {
    return regist == runtime.REGISTER_X or regist == runtime.REGISTER_Y or regist == runtime.REGISTER_Z or regist == runtime.REGISTER_T;
}

fn isOwnedCompareType(data_type: u32) bool {
    return data_type == runtime.dtLongInteger or data_type == runtime.dtShortInteger or data_type == runtime.dtReal34 or data_type == runtime.dtComplex34;
}

fn isOwnedAlmostEqualIntegerType(data_type: u32) bool {
    return data_type == runtime.dtLongInteger or data_type == runtime.dtShortInteger;
}

fn compareTypeError(regist: runtime.calcRegister_t) void {
    var message_buffer: [128]u8 = undefined;
    const type_name = std.mem.span(runtime.getRegisterDataTypeName(regist, true, false));
    const message = std.fmt.bufPrintZ(&message_buffer, "cannot convert Register {} from {s}", .{ regist, type_name }) catch "cannot convert Register";

    runtime.setTemporaryInformation(false);
    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_T);
    runtime.moreInfoOnError("In function badTypeError:", message, null, null);
}

fn compareResultToTemporaryInformation(result: i32, mode: u8) void {
    if (result < 0) {
        runtime.setTemporaryInformation((mode & compare_mode_less_than) != 0);
    } else if (result > 0) {
        runtime.setTemporaryInformation((mode & compare_mode_greater_than) != 0);
    } else {
        runtime.setTemporaryInformation((mode & compare_mode_equal) != 0);
    }
}

fn compareRealsToTemporaryInformation(left: *runtime.real_t, right: *runtime.real_t, mode: u8) void {
    if (runtime.realIsNaN(left) or runtime.realIsNaN(right)) {
        runtime.setTemporaryInformation(false);
        return;
    }

    const result: i32 = if (runtime.realCompareEqual(left, right))
        0
    else if (runtime.realCompareLessThan(left, right))
        -1
    else
        1;

    compareResultToTemporaryInformation(result, mode);
}

fn compareComplexToTemporaryInformation(
    left_real: *runtime.real_t,
    left_imag: *runtime.real_t,
    right_real: *runtime.real_t,
    right_imag: *runtime.real_t,
    mode: u8,
    regist: runtime.calcRegister_t,
) void {
    if (mode != compare_mode_equal and mode != compare_mode_not_equal) {
        compareTypeError(regist);
        return;
    }

    compareRealsToTemporaryInformation(left_real, right_real, mode);
    if (runtime.temporaryInformation != runtime.TI_FALSE) {
        compareRealsToTemporaryInformation(left_imag, right_imag, mode);
    }
}

fn getCompareInput(
    regist: runtime.calcRegister_t,
    real: *runtime.real_t,
    imag: *runtime.real_t,
    is_complex: *bool,
) bool {
    switch (runtime.getRegisterDataType(regist)) {
        runtime.dtComplex34 => {
            is_complex.* = true;
            return runtime.getRegisterAsComplex(regist, real, imag);
        },
        runtime.dtReal34 => {
            if (!runtime.getRegisterAsReal(regist, real)) {
                return false;
            }
            runtime.realSetZero(imag);
            return true;
        },
        runtime.dtLongInteger => {
            runtime.convertLongIntegerRegisterToReal(regist, real, &runtime.ctxtReal39);
            runtime.realSetZero(imag);
            return true;
        },
        runtime.dtShortInteger => {
            runtime.convertShortIntegerRegisterToReal(regist, real, &runtime.ctxtReal39);
            runtime.realSetZero(imag);
            return true;
        },
        else => return false,
    }
}

fn compareScalarRegister(regist: runtime.calcRegister_t, mode: u8) void {
    const x_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    const regist_type = runtime.getRegisterDataType(regist);
    var x_real: runtime.real_t = undefined;
    var x_imag: runtime.real_t = undefined;
    var regist_real: runtime.real_t = undefined;
    var regist_imag: runtime.real_t = undefined;
    var is_complex = false;

    if (!isOwnedCompareType(x_type) or !isOwnedCompareType(regist_type)) {
        compareTypeError(regist);
        return;
    }

    if (!getCompareInput(runtime.REGISTER_X, &x_real, &x_imag, &is_complex) or !getCompareInput(regist, &regist_real, &regist_imag, &is_complex)) {
        compareTypeError(regist);
        return;
    }

    if (is_complex) {
        compareComplexToTemporaryInformation(&x_real, &x_imag, &regist_real, &regist_imag, mode, regist);
    } else {
        compareRealsToTemporaryInformation(&x_real, &regist_real, mode);
    }
}

pub export fn fnIsConverged(unused_but_mandatory_parameter: u16) callconv(.c) void {
    var x_real: runtime.real_t = undefined;
    var x_imag: runtime.real_t = undefined;
    var y_real: runtime.real_t = undefined;
    var y_imag: runtime.real_t = undefined;
    var tol: runtime.real_t = undefined;
    var is_complex = false;

    runtime.convergenceTolerence(&tol);
    if (!getConvergenceInput(runtime.REGISTER_X, &x_real, &x_imag, &is_complex) or !getConvergenceInput(runtime.REGISTER_Y, &y_real, &y_imag, &is_complex)) {
        compareTypeErrorX();
        return;
    }

    if (runtime.realIsNaN(&x_real) or runtime.realIsNaN(&y_real) or runtime.realIsNaN(&x_imag) or runtime.realIsNaN(&y_imag)) {
        runtime.setTemporaryInformation((unused_but_mandatory_parameter & 0x4) != 0);
    } else if (runtime.realIsInfinite(&x_real) or runtime.realIsInfinite(&y_real) or runtime.realIsInfinite(&x_imag) or runtime.realIsInfinite(&y_imag)) {
        runtime.setTemporaryInformation((unused_but_mandatory_parameter & 0x2) != 0);
    } else if ((unused_but_mandatory_parameter & 0x1) != 0) {
        runtime.setTemporaryInformation(
            if (is_complex)
                runtime.WP34S_ComplexAbsError(&x_real, &x_imag, &y_real, &y_imag, &tol, &runtime.ctxtReal39)
            else
                runtime.WP34S_AbsoluteError(&x_real, &y_real, &tol, &runtime.ctxtReal39),
        );
    } else {
        runtime.setTemporaryInformation(
            if (is_complex)
                runtime.WP34S_ComplexRelativeError(&x_real, &x_imag, &y_real, &y_imag, &tol, &runtime.ctxtReal39)
            else
                runtime.WP34S_RelativeError(&x_real, &y_real, &tol, &runtime.ctxtReal39),
        );
    }
}

pub export fn fnCheckType(type_: u16) callconv(.c) void {
    runtime.setTemporaryInformation(runtime.getRegisterDataType(runtime.REGISTER_X) == type_);
}

pub export fn fnCheckReal(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    runtime.setTemporaryInformation(register_data_type <= runtime.dtDate or register_data_type == runtime.dtShortInteger);
}

pub export fn fnCheckNumber(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    const is_number = switch (runtime.getRegisterDataType(runtime.REGISTER_X)) {
        runtime.dtLongInteger, runtime.dtShortInteger => true,
        runtime.dtComplex34 => blk: {
            const imag_is_number = !(runtime.real34IsNaN(runtime.registerImag34Ptr(runtime.REGISTER_X)) or runtime.real34IsInfinite(runtime.registerImag34Ptr(runtime.REGISTER_X)));
            const real_is_number = !(runtime.real34IsNaN(runtime.registerReal34Ptr(runtime.REGISTER_X)) or runtime.real34IsInfinite(runtime.registerReal34Ptr(runtime.REGISTER_X)));
            break :blk imag_is_number and real_is_number;
        },
        runtime.dtTime, runtime.dtDate, runtime.dtReal34 => !(runtime.real34IsNaN(runtime.registerReal34Ptr(runtime.REGISTER_X)) or runtime.real34IsInfinite(runtime.registerReal34Ptr(runtime.REGISTER_X))),
        else => false,
    };

    runtime.setTemporaryInformation(is_number);
}

pub export fn fnCheckAngle(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.setTemporaryInformation(runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtReal34 and runtime.getRegisterAngularMode(runtime.REGISTER_X) != runtime.amNone);
}

pub export fn fnCheckMatrix(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    runtime.setTemporaryInformation(register_data_type == runtime.dtReal34Matrix or register_data_type == runtime.dtComplex34Matrix);
}

fn compareTypeErrorX() void {
    runtime.setTemporaryInformation(false);
    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_T);
}

pub export fn fnCheckMatrixSquare(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);

    if (register_data_type == runtime.dtReal34Matrix or register_data_type == runtime.dtComplex34Matrix) {
        const header = runtime.registerMatrixHeaderPtr(runtime.REGISTER_X);
        runtime.setTemporaryInformation(header.matrixRows == header.matrixColumns);
        return;
    }

    compareTypeErrorX();
}

fn setCheckForZeroResult(mode: u16, real_is_zero: bool, imag_is_zero: bool) void {
    switch (mode) {
        ITM_ISREZQ => runtime.setTemporaryInformation(real_is_zero),
        ITM_ISIMZQ => runtime.setTemporaryInformation(imag_is_zero),
        ITM_ISRENZQ => runtime.setTemporaryInformation(!real_is_zero),
        ITM_ISIMNZQ => runtime.setTemporaryInformation(!imag_is_zero),
        else => {},
    }
}

fn tryCheckForZero(mode: u16) bool {
    switch (runtime.getRegisterDataType(runtime.REGISTER_X)) {
        runtime.dtLongInteger => {
            var value: runtime.longInteger_t = undefined;
            runtime.convertLongIntegerRegisterToLongInteger(runtime.REGISTER_X, &value[0]);
            defer runtime.__gmpz_clear(&value[0]);

            setCheckForZeroResult(mode, value[0]._mp_size == 0, true);
            return true;
        },
        runtime.dtShortInteger => {
            var value: u64 = 0;
            runtime.convertShortIntegerRegisterToUInt64(runtime.REGISTER_X, null, &value);

            setCheckForZeroResult(mode, value == 0, true);
            return true;
        },
        runtime.dtComplex34 => {
            const value = runtime.registerComplex34Ptr(runtime.REGISTER_X);
            setCheckForZeroResult(mode, runtime.real34IsZero(&value.real), runtime.real34IsZero(&value.imag));
            return true;
        },
        runtime.dtTime, runtime.dtDate, runtime.dtReal34 => {
            setCheckForZeroResult(mode, runtime.real34IsZero(runtime.registerReal34Ptr(runtime.REGISTER_X)), true);
            return true;
        },
        else => return false,
    }
}

pub export fn fnCheckForZero(mode: u16) callconv(.c) void {
    if (!tryCheckForZero(mode)) {
        compareTypeErrorX();
    }
}

fn tryCheckRealMatrixVector(dimension: u16) bool {
    if (runtime.getRegisterDataType(runtime.REGISTER_X) != runtime.dtReal34Matrix) {
        return false;
    }

    const header = runtime.registerMatrixHeaderPtr(runtime.REGISTER_X);
    runtime.setTemporaryInformation((header.matrixRows == 1 and header.matrixColumns == dimension) or (header.matrixRows == dimension and header.matrixColumns == 1));
    return true;
}

pub export fn fnCheckIsVect2d(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    if (!tryCheckRealMatrixVector(2)) {
        compareTypeErrorX();
    }
}

pub export fn fnCheckIsVect3d(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    if (!tryCheckRealMatrixVector(3)) {
        compareTypeErrorX();
    }
}

fn checkNaNMatrixElements(register_data_type: u32) bool {
    const ptr = runtime.getRegisterDataPointer(runtime.REGISTER_X) orelse unreachable;
    const header: *align(1) runtime.matrixHeader_t = @ptrCast(ptr);
    const bytes: [*]align(1) u8 = @ptrCast(ptr);
    const elements: usize = @as(usize, header.matrixRows) * @as(usize, header.matrixColumns);

    switch (register_data_type) {
        runtime.dtReal34Matrix => {
            const values: [*]align(1) runtime.real34_t = @ptrCast(bytes + @sizeOf(runtime.matrixHeader_t));
            var index: usize = 0;
            while (index < elements) : (index += 1) {
                if (runtime.real34IsNaN(&values[index])) {
                    return true;
                }
            }
        },
        runtime.dtComplex34Matrix => {
            const values: [*]align(1) runtime.complex34_t = @ptrCast(bytes + @sizeOf(runtime.matrixHeader_t));
            var index: usize = 0;
            while (index < elements) : (index += 1) {
                if (runtime.real34IsNaN(&values[index].real) or runtime.real34IsNaN(&values[index].imag)) {
                    return true;
                }
            }
        },
        else => return false,
    }

    return false;
}

fn checkInfiniteMatrixElements(register_data_type: u32) bool {
    const ptr = runtime.getRegisterDataPointer(runtime.REGISTER_X) orelse unreachable;
    const header: *align(1) runtime.matrixHeader_t = @ptrCast(ptr);
    const bytes: [*]align(1) u8 = @ptrCast(ptr);
    const elements: usize = @as(usize, header.matrixRows) * @as(usize, header.matrixColumns);

    switch (register_data_type) {
        runtime.dtReal34Matrix => {
            const values: [*]align(1) runtime.real34_t = @ptrCast(bytes + @sizeOf(runtime.matrixHeader_t));
            var index: usize = 0;
            while (index < elements) : (index += 1) {
                if (runtime.real34IsInfinite(&values[index])) {
                    return true;
                }
            }
        },
        runtime.dtComplex34Matrix => {
            const values: [*]align(1) runtime.complex34_t = @ptrCast(bytes + @sizeOf(runtime.matrixHeader_t));
            var index: usize = 0;
            while (index < elements) : (index += 1) {
                if (runtime.real34IsInfinite(&values[index].real) or runtime.real34IsInfinite(&values[index].imag)) {
                    return true;
                }
            }
        },
        else => return false,
    }

    return false;
}

fn checkSpecialMatrixElements(register_data_type: u32) bool {
    const ptr = runtime.getRegisterDataPointer(runtime.REGISTER_X) orelse unreachable;
    const header: *align(1) runtime.matrixHeader_t = @ptrCast(ptr);
    const bytes: [*]align(1) u8 = @ptrCast(ptr);
    const elements: usize = @as(usize, header.matrixRows) * @as(usize, header.matrixColumns);

    switch (register_data_type) {
        runtime.dtReal34Matrix => {
            const values: [*]align(1) runtime.real34_t = @ptrCast(bytes + @sizeOf(runtime.matrixHeader_t));
            var index: usize = 0;
            while (index < elements) : (index += 1) {
                if (runtime.real34IsNaN(&values[index]) or runtime.real34IsInfinite(&values[index])) {
                    return true;
                }
            }
        },
        runtime.dtComplex34Matrix => {
            const values: [*]align(1) runtime.complex34_t = @ptrCast(bytes + @sizeOf(runtime.matrixHeader_t));
            var index: usize = 0;
            while (index < elements) : (index += 1) {
                if (runtime.real34IsNaN(&values[index].real) or runtime.real34IsInfinite(&values[index].real) or runtime.real34IsNaN(&values[index].imag) or runtime.real34IsInfinite(&values[index].imag)) {
                    return true;
                }
            }
        },
        else => return false,
    }

    return false;
}

pub export fn fnCheckNaN(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);

    switch (register_data_type) {
        runtime.dtComplex34 => {
            runtime.setTemporaryInformation(runtime.real34IsNaN(runtime.registerImag34Ptr(runtime.REGISTER_X)) or runtime.real34IsNaN(runtime.registerReal34Ptr(runtime.REGISTER_X)));
        },
        runtime.dtTime, runtime.dtDate, runtime.dtReal34 => {
            runtime.setTemporaryInformation(runtime.real34IsNaN(runtime.registerReal34Ptr(runtime.REGISTER_X)));
        },
        runtime.dtReal34Matrix, runtime.dtComplex34Matrix => {
            runtime.setTemporaryInformation(checkNaNMatrixElements(register_data_type));
        },
        else => {
            _ = unused_but_mandatory_parameter;
            compareTypeErrorX();
        },
    }
}

pub export fn fnCheckInfinite(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);

    switch (register_data_type) {
        runtime.dtComplex34 => {
            runtime.setTemporaryInformation(runtime.real34IsInfinite(runtime.registerImag34Ptr(runtime.REGISTER_X)) or runtime.real34IsInfinite(runtime.registerReal34Ptr(runtime.REGISTER_X)));
        },
        runtime.dtTime, runtime.dtDate, runtime.dtReal34 => {
            runtime.setTemporaryInformation(runtime.real34IsInfinite(runtime.registerReal34Ptr(runtime.REGISTER_X)));
        },
        runtime.dtReal34Matrix, runtime.dtComplex34Matrix => {
            runtime.setTemporaryInformation(checkInfiniteMatrixElements(register_data_type));
        },
        else => {
            _ = unused_but_mandatory_parameter;
            compareTypeErrorX();
        },
    }
}

pub export fn fnCheckSpecial(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);

    switch (register_data_type) {
        runtime.dtComplex34 => {
            const imag_special = runtime.real34IsNaN(runtime.registerImag34Ptr(runtime.REGISTER_X)) or runtime.real34IsInfinite(runtime.registerImag34Ptr(runtime.REGISTER_X));
            const real_special = runtime.real34IsNaN(runtime.registerReal34Ptr(runtime.REGISTER_X)) or runtime.real34IsInfinite(runtime.registerReal34Ptr(runtime.REGISTER_X));
            runtime.setTemporaryInformation(imag_special or real_special);
        },
        runtime.dtTime, runtime.dtDate, runtime.dtReal34 => {
            runtime.setTemporaryInformation(runtime.real34IsNaN(runtime.registerReal34Ptr(runtime.REGISTER_X)) or runtime.real34IsInfinite(runtime.registerReal34Ptr(runtime.REGISTER_X)));
        },
        runtime.dtReal34Matrix, runtime.dtComplex34Matrix => {
            runtime.setTemporaryInformation(checkSpecialMatrixElements(register_data_type));
        },
        else => {
            _ = unused_but_mandatory_parameter;
            compareTypeErrorX();
        },
    }
}

fn tryCheckZeroScalar(neg: bool) bool {
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);

    switch (register_data_type) {
        runtime.dtLongInteger => {
            var value: runtime.longInteger_t = undefined;
            runtime.convertLongIntegerRegisterToLongInteger(runtime.REGISTER_X, &value[0]);
            defer runtime.__gmpz_clear(&value[0]);
            runtime.setTemporaryInformation(!neg and value[0]._mp_size == 0);
            return true;
        },
        runtime.dtShortInteger => {
            var sign: i16 = 0;
            var value: u64 = 0;
            runtime.convertShortIntegerRegisterToUInt64(runtime.REGISTER_X, &sign, &value);
            runtime.setTemporaryInformation(value == 0 and sign == @intFromBool(neg));
            return true;
        },
        runtime.dtComplex34 => {
            const value = runtime.registerComplex34Ptr(runtime.REGISTER_X);
            runtime.setTemporaryInformation(runtime.real34IsZero(&value.real) and runtime.real34IsZero(&value.imag) and (runtime.real34IsNegative(&value.real) == neg or runtime.real34IsNegative(&value.imag) == neg));
            return true;
        },
        runtime.dtTime, runtime.dtDate, runtime.dtReal34 => {
            runtime.setTemporaryInformation(runtime.real34IsNegative(runtime.registerReal34Ptr(runtime.REGISTER_X)) == neg and runtime.real34IsZero(runtime.registerReal34Ptr(runtime.REGISTER_X)));
            return true;
        },
        else => return false,
    }
}

pub export fn fnCheckPlusZero(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    if (!tryCheckZeroScalar(false)) {
        compareTypeErrorX();
    }
}

pub export fn fnCheckMinusZero(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    if (!tryCheckZeroScalar(true)) {
        compareTypeErrorX();
    }
}

fn pushGetTypeIntegerOut(value: u32) void {
    var long_integer: runtime.longInteger_t = undefined;

    runtime.__gmpz_init(&long_integer[0]);
    defer runtime.__gmpz_clear(&long_integer[0]);
    runtime.__gmpz_set_ui(&long_integer[0], value);

    runtime.setSystemFlag(runtime.FLAG_ASLIFT);
    runtime.liftStack();
    runtime.convertLongIntegerToLongIntegerRegister(&long_integer[0], runtime.REGISTER_X);
    runtime.setSystemFlag(runtime.FLAG_ASLIFT);
}

fn pushGetTypeRealOut(value: u32) void {
    var real_output = std.mem.zeroes(runtime.real_t);
    var scale = std.mem.zeroes(runtime.real_t);

    runtime.uInt32ToReal(value, &real_output);
    runtime.uInt32ToReal(1000, &scale);
    runtime.realDivide(&real_output, &scale, &real_output, &runtime.ctxtReal39);

    runtime.setSystemFlag(runtime.FLAG_ASLIFT);
    runtime.liftStack();
    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
    runtime.convertRealToReal34ResultRegister(&real_output, runtime.REGISTER_X);
    runtime.setSystemFlag(runtime.FLAG_ASLIFT);
}

pub export fn fnGetType(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const data_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    const angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_X);

    _ = unused_but_mandatory_parameter;

    switch (data_type) {
        runtime.dtLongInteger, runtime.dtTime, runtime.dtDate, runtime.dtString, runtime.dtReal34Matrix, runtime.dtConfig => {
            if (runtime.isRegisterMatrixVector(runtime.REGISTER_X)) {
                const header = runtime.registerMatrixHeaderPtr(runtime.REGISTER_X);
                const angle_bits: u32 = @intCast(runtime.getRegisterAngularMode(runtime.REGISTER_X) & 0x07);
                const angle: u32 = 5 - angle_bits;
                const vector_shape: u32 = if (header.matrixRows > 1 and header.matrixColumns == 1)
                    2
                else if (header.matrixRows == 1 and header.matrixColumns > 1)
                    1
                else
                    0;
                const pol_rec: u32 = if (runtime.isRegisterMatrix2dVector(runtime.REGISTER_X))
                    2
                else if (runtime.isRegisterMatrix3dVector(runtime.REGISTER_X))
                    if (runtime.getVectorRegisterPolarMode(runtime.REGISTER_X) == runtime.amPolarCYL) 4 else 3
                else
                    0;

                pushGetTypeRealOut(data_type * 1000 + 100 * angle + 10 * pol_rec + vector_shape);
            } else if (data_type == runtime.dtReal34Matrix) {
                const header = runtime.registerMatrixHeaderPtr(runtime.REGISTER_X);
                const is_col = header.matrixRows > 1 and header.matrixColumns == 1;
                const is_row = header.matrixRows == 1 and header.matrixColumns > 1;

                if (is_col or is_row) {
                    const suffix: u32 = if (is_col) 2 else 1;
                    pushGetTypeRealOut(data_type * 1000 + suffix);
                } else {
                    pushGetTypeIntegerOut(data_type);
                }
            } else {
                pushGetTypeIntegerOut(data_type);
            }
        },
        runtime.dtComplex34Matrix => {
            const header = runtime.registerMatrixHeaderPtr(runtime.REGISTER_X);
            const is_polar = runtime.getComplexRegisterPolarMode(runtime.REGISTER_X) != 0;
            const angle_bits: u32 = @intCast(angular_mode & 0x07);
            const angle: u32 = if (is_polar) 5 - angle_bits else 0;
            const vector_shape: u32 = if (header.matrixRows > 1 and header.matrixColumns == 1)
                2
            else if (header.matrixRows == 1 and header.matrixColumns > 1)
                1
            else
                0;
            const pol_rec: u32 = if (is_polar) 1 else 0;

            pushGetTypeRealOut(data_type * 1000 + 100 * angle + 10 * pol_rec + vector_shape);
        },
        runtime.dtShortInteger, runtime.dtReal34, runtime.dtComplex34 => {
            const short_bits: u32 = @intCast(angular_mode & 0x1f);
            const angle_bits: u32 = @intCast(angular_mode & 0x07);
            const value: u32 = if (data_type == runtime.dtShortInteger)
                10 * (data_type * 100 + short_bits)
            else
                100 * (data_type * 10 + 5 - angle_bits);

            pushGetTypeRealOut(value);
        },
        else => {},
    }

    runtime.temporaryInformation = runtime.TI_REGTYPE;
}

pub export fn fnDblDivide(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    dblDivide(false);
}

pub export fn fnDblDivideRemainder(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    dblDivide(true);
}

fn loadToPolarNumericInput(reg: runtime.calcRegister_t, data_type: u32, value: *runtime.real_t) void {
    switch (data_type) {
        runtime.dtLongInteger => runtime.convertLongIntegerRegisterToReal(reg, value, &runtime.ctxtReal39),
        runtime.dtReal34 => _ = runtime.decimal128ToNumber(runtime.registerReal34Ptr(reg), value),
        else => unreachable,
    }
}

fn tryFnToPolar2Real34Pair() bool {
    if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtComplex34 or runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtComplex34Matrix) {
        runtime.setComplexRegisterPolarMode(runtime.REGISTER_X, runtime.amPolar);
        if (runtime.getComplexRegisterAngularMode(runtime.REGISTER_X) == runtime.amNone) {
            runtime.setComplexRegisterAngularMode(runtime.REGISTER_X, runtime.currentAngularMode);
        }
        return true;
    }

    if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtReal34Matrix) {
        if (runtime.isRegisterMatrix3dVector(runtime.REGISTER_X)) {
            const polar_mode = runtime.getVectorRegisterPolarMode(runtime.REGISTER_X);
            runtime.setVectorRegisterPolarMode(
                runtime.REGISTER_X,
                if (polar_mode == runtime.amNone)
                    runtime.amPolarSPH
                else if (polar_mode == runtime.amPolarSPH)
                    runtime.amPolarCYL
                else if (polar_mode == runtime.amPolarCYL)
                    runtime.amPolarSPH
                else
                    runtime.amNone,
            );
            runtime.setVectorRegisterAngularMode(runtime.REGISTER_X, runtime.currentAngularMode);
            return true;
        }

        if (runtime.isRegisterMatrix2dVector(runtime.REGISTER_X)) {
            runtime.setVectorRegisterPolarMode(runtime.REGISTER_X, runtime.amPolar);
            runtime.setVectorRegisterAngularMode(runtime.REGISTER_X, runtime.currentAngularMode);
            return true;
        }
    }

    const data_type_x = runtime.getRegisterDataType(runtime.REGISTER_X);
    const data_atag_x = runtime.getRegisterAngularMode(runtime.REGISTER_X);
    const data_type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);
    const data_atag_y = runtime.getRegisterAngularMode(runtime.REGISTER_Y);

    const x_valid = data_type_x == runtime.dtLongInteger or (data_type_x == runtime.dtReal34 and data_atag_x == runtime.amNone);
    const y_valid = data_type_y == runtime.dtLongInteger or (data_type_y == runtime.dtReal34 and data_atag_y == runtime.amNone);

    if (!x_valid or !y_valid) {
        runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        return true;
    }

    const hp_rp = runtime.getSystemFlag(runtime.FLAG_HPRP);
    const real_reg = if (hp_rp) runtime.REGISTER_X else runtime.REGISTER_Y;
    const imag_reg = if (hp_rp) runtime.REGISTER_Y else runtime.REGISTER_X;

    if (!runtime.saveLastX()) {
        return true;
    }

    var real_value: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;

    loadToPolarNumericInput(real_reg, data_type_x, &real_value);
    loadToPolarNumericInput(imag_reg, data_type_y, &imag_value);

    runtime.realRectangularToPolar(&real_value, &imag_value, &real_value, &imag_value, &runtime.ctxtReal39);
    runtime.convertAngleFromTo(&imag_value, runtime.amRadian, runtime.currentAngularMode, &runtime.ctxtReal39);

    runtime.reallocateRegister(real_reg, runtime.dtReal34, 0, runtime.amNone);
    runtime.reallocateRegister(imag_reg, runtime.dtReal34, 0, @intCast(runtime.currentAngularMode));
    runtime.convertRealToReal34ResultRegister(&real_value, real_reg);
    runtime.convertRealToReal34ResultRegister(&imag_value, imag_reg);
    _ = runtime.getSystemFlag(runtime.FLAG_HPRP);
    return true;
}

fn tryFnToRect2Real34Pair() bool {
    if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtComplex34 or runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtComplex34Matrix) {
        runtime.setComplexRegisterPolarMode(runtime.REGISTER_X, runtime.amNone);
        runtime.setComplexRegisterAngularMode(runtime.REGISTER_X, runtime.amNone);
        return true;
    }

    if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtReal34Matrix and runtime.isRegisterMatrixVector(runtime.REGISTER_X)) {
        runtime.setVectorRegisterPolarMode(runtime.REGISTER_X, runtime.amNone);
        runtime.setVectorRegisterAngularMode(runtime.REGISTER_X, runtime.amNone);
        runtime.temporaryInformation = runtime.TI_VECTOR;
        return true;
    }

    const data_type_x = runtime.getRegisterDataType(runtime.REGISTER_X);
    const data_atag_x = runtime.getRegisterAngularMode(runtime.REGISTER_X);
    const data_type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);
    const data_atag_y = runtime.getRegisterAngularMode(runtime.REGISTER_Y);

    var angle_in_y: i8 = 1;
    if (!runtime.getSystemFlag(runtime.FLAG_HPRP)) {
        angle_in_y = -angle_in_y;
        if (data_type_x == runtime.dtReal34 and data_atag_x != runtime.amNone and data_type_y == runtime.dtReal34 and data_atag_y == runtime.amNone) {
            // Keep the current register order.
        } else if (data_type_y == runtime.dtReal34 and data_atag_y != runtime.amNone and data_type_x == runtime.dtReal34 and data_atag_x == runtime.amNone) {
            angle_in_y = -angle_in_y;
        }
    } else {
        if (data_type_x == runtime.dtReal34 and data_atag_x != runtime.amNone and data_type_y == runtime.dtReal34 and data_atag_y == runtime.amNone) {
            angle_in_y = -angle_in_y;
        } else if (data_type_y == runtime.dtReal34 and data_atag_y != runtime.amNone and data_type_x == runtime.dtReal34 and data_atag_x == runtime.amNone) {
            // Keep the current register order.
        }
    }

    const x_valid = data_type_x == runtime.dtLongInteger or data_type_x == runtime.dtReal34;
    const y_valid = data_type_y == runtime.dtLongInteger or data_type_y == runtime.dtReal34;

    if (!x_valid or !y_valid) {
        runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        return true;
    }

    var radius_reg = if (angle_in_y == 1) runtime.REGISTER_X else runtime.REGISTER_Y;
    var angle_reg = if (angle_in_y == 1) runtime.REGISTER_Y else runtime.REGISTER_X;
    const radius_type = runtime.getRegisterDataType(radius_reg);
    const angle_type = runtime.getRegisterDataType(angle_reg);
    const radius_valid = radius_type == runtime.dtLongInteger or radius_type == runtime.dtReal34;
    const angle_valid = angle_type == runtime.dtLongInteger or angle_type == runtime.dtReal34;

    if (!radius_valid or !angle_valid) {
        runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, radius_reg);
        return true;
    }

    var angle_mode = runtime.getRegisterAngularMode(angle_reg);
    if (!runtime.saveLastX()) {
        return true;
    }

    var radius_value: runtime.real_t = undefined;
    var angle_value: runtime.real_t = undefined;

    loadToPolarNumericInput(radius_reg, radius_type, &radius_value);
    loadToPolarNumericInput(angle_reg, angle_type, &angle_value);

    if (angle_type == runtime.dtReal34 and angle_mode == runtime.amNone) {
        angle_mode = runtime.currentAngularMode;
    }

    runtime.convertAngleFromTo(&angle_value, angle_mode, runtime.amRadian, &runtime.ctxtReal39);
    runtime.realPolarToRectangular(&radius_value, &angle_value, &radius_value, &angle_value, &runtime.ctxtReal39);

    if (runtime.getSystemFlag(runtime.FLAG_HPRP)) {
        radius_reg = runtime.REGISTER_X;
        angle_reg = runtime.REGISTER_Y;
    } else {
        radius_reg = runtime.REGISTER_Y;
        angle_reg = runtime.REGISTER_X;
    }

    runtime.reallocateRegister(radius_reg, runtime.dtReal34, 0, runtime.amNone);
    runtime.reallocateRegister(angle_reg, runtime.dtReal34, 0, runtime.amNone);
    runtime.convertRealToReal34ResultRegister(&radius_value, radius_reg);
    runtime.convertRealToReal34ResultRegister(&angle_value, angle_reg);
    _ = runtime.getSystemFlag(runtime.FLAG_HPRP);
    return true;
}

fn tryFnToRectReal34Pair(angle_in_y: i8) bool {
    var radius_reg = if (angle_in_y == 1) runtime.REGISTER_X else runtime.REGISTER_Y;
    var angle_reg = if (angle_in_y == 1) runtime.REGISTER_Y else runtime.REGISTER_X;
    const radius_type = runtime.getRegisterDataType(radius_reg);
    const angle_type = runtime.getRegisterDataType(angle_reg);
    const radius_valid = radius_type == runtime.dtLongInteger or radius_type == runtime.dtReal34;
    const angle_valid = angle_type == runtime.dtLongInteger or angle_type == runtime.dtReal34;

    if (!radius_valid or !angle_valid) {
        runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, radius_reg);
        runtime.moreInfoOnError("In function fnToRect:", "cannot convert current X/Y pair to rectangular coordinates", null, null);
        return true;
    }

    var angle_mode = runtime.getRegisterAngularMode(angle_reg);
    if (!runtime.saveLastX()) {
        return true;
    }

    var radius_value: runtime.real_t = undefined;
    var angle_value: runtime.real_t = undefined;

    loadToPolarNumericInput(radius_reg, radius_type, &radius_value);
    loadToPolarNumericInput(angle_reg, angle_type, &angle_value);

    if (angle_type == runtime.dtLongInteger) {
        angle_mode = runtime.currentAngularMode;
    } else if (angle_mode == runtime.amNone) {
        angle_mode = runtime.currentAngularMode;
    }

    runtime.convertAngleFromTo(&angle_value, angle_mode, runtime.amRadian, &runtime.ctxtReal39);
    runtime.realPolarToRectangular(&radius_value, &angle_value, &radius_value, &angle_value, &runtime.ctxtReal39);

    if (runtime.getSystemFlag(runtime.FLAG_HPRP)) {
        radius_reg = runtime.REGISTER_X;
        angle_reg = runtime.REGISTER_Y;
    } else {
        radius_reg = runtime.REGISTER_Y;
        angle_reg = runtime.REGISTER_X;
    }

    runtime.reallocateRegister(radius_reg, runtime.dtReal34, 0, runtime.amNone);
    runtime.reallocateRegister(angle_reg, runtime.dtReal34, 0, runtime.amNone);
    runtime.convertRealToReal34ResultRegister(&radius_value, radius_reg);
    runtime.convertRealToReal34ResultRegister(&angle_value, angle_reg);
    _ = runtime.getSystemFlag(runtime.FLAG_HPRP);
    return true;
}

pub export fn fnToPolar2(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (tryFnToPolar2Real34Pair()) {
        return;
    }

    z47_math_wrappers_retained_fnToPolar2(unused_but_mandatory_parameter);
}

pub export fn fnToRect2(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (tryFnToRect2Real34Pair()) {
        return;
    }

    z47_math_wrappers_retained_fnToRect2(unused_but_mandatory_parameter);
}

pub export fn fnToRect(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const angle_in_y: i8 = @bitCast(@as(u8, @truncate(unused_but_mandatory_parameter)));

    _ = tryFnToRectReal34Pair(angle_in_y);
}

fn doParallelReal() callconv(.c) void {
    var y_value: runtime.real_t = undefined;
    var x_value: runtime.real_t = undefined;
    var product: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value) or !runtime.getRegisterAsReal(runtime.REGISTER_Y, &y_value)) {
        return;
    }

    if (!runtime.realIsZero(&x_value)) {
        runtime.realMultiply(&y_value, &x_value, &product, &runtime.ctxtReal75);
        runtime.realAdd(&y_value, &x_value, &y_value, &runtime.ctxtReal75);
        runtime.realDivide(&product, &y_value, &x_value, &runtime.ctxtReal75);
    }

    runtime.convertRealToResultRegister(&x_value, runtime.REGISTER_X, runtime.amNone);
}

fn doParallelComplex() callconv(.c) void {
    var y_real: runtime.real_t = undefined;
    var x_real: runtime.real_t = undefined;
    var product_real: runtime.real_t = undefined;
    var sum_real: runtime.real_t = undefined;
    var y_imag: runtime.real_t = undefined;
    var x_imag: runtime.real_t = undefined;
    var product_imag: runtime.real_t = undefined;
    var sum_imag: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &x_real, &x_imag) or !runtime.getRegisterAsComplex(runtime.REGISTER_Y, &y_real, &y_imag)) {
        return;
    }

    if (!runtime.realIsZero(&x_real) or !runtime.realIsZero(&x_imag)) {
        runtime.mulComplexComplex(&y_real, &y_imag, &x_real, &x_imag, &product_real, &product_imag, &runtime.ctxtReal75);
        runtime.realAdd(&y_real, &x_real, &sum_real, &runtime.ctxtReal75);
        runtime.realAdd(&y_imag, &x_imag, &sum_imag, &runtime.ctxtReal75);
        runtime.divComplexComplex(&product_real, &product_imag, &sum_real, &sum_imag, &x_real, &x_imag, &runtime.ctxtReal75);
    }

    runtime.convertComplexToResultRegister(&x_real, &x_imag, runtime.REGISTER_X);
}

pub export fn fnParallel(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexDyadicFunction(&doParallelReal, &doParallelComplex);
}

fn shiftDigitsError(function_name: [:0]const u8, operation_name: []const u8) void {
    var message_buffer: [96]u8 = undefined;
    const type_name = std.mem.span(runtime.getRegisterDataTypeName(runtime.REGISTER_X, true, false));
    const message = std.fmt.bufPrintZ(&message_buffer, "cannot {s} {s}", .{ operation_name, type_name }) catch "cannot shift digits";

    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
    runtime.moreInfoOnError(function_name, message, null, null);
}

fn unitVectorError() void {
    var message_buffer: [128]u8 = undefined;
    const type_name = std.mem.span(runtime.getRegisterDataTypeName(runtime.REGISTER_X, true, false));
    const message = std.fmt.bufPrintZ(&message_buffer, "cannot calculate the unit vector of {s}", .{type_name}) catch "cannot calculate the unit vector";

    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
    runtime.moreInfoOnError("In function fnUnitVector:", message, null, null);
}

fn unitVectorComplex() void {
    var real_value: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;
    var norm: runtime.real_t = undefined;

    runtime.real34ToReal(runtime.registerReal34Ptr(runtime.REGISTER_X), &real_value);
    runtime.real34ToReal(runtime.registerImag34Ptr(runtime.REGISTER_X), &imag_value);

    runtime.realMultiply(&real_value, &real_value, &norm, &runtime.ctxtReal39);
    runtime.realFMA(&imag_value, &imag_value, &norm, &norm, &runtime.ctxtReal39);
    runtime.realSquareRoot(&norm, &norm, &runtime.ctxtReal39);
    runtime.realDivide(&real_value, &norm, &real_value, &runtime.ctxtReal39);
    runtime.realDivide(&imag_value, &norm, &imag_value, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&real_value, &imag_value, runtime.REGISTER_X);
}

fn unitVectorRema() void {
    var matrix: runtime.real34Matrix_t = undefined;
    var element: runtime.real_t = undefined;
    var sum: runtime.real_t = undefined;

    runtime.linkToRealMatrixRegister(runtime.REGISTER_X, &matrix);
    runtime.realSetZero(&sum);

    const count = @min(@as(usize, matrix.header.matrixRows) * @as(usize, matrix.header.matrixColumns), matrix.matrixElements.len);

    for (0..count) |index| {
        runtime.real34ToReal(&matrix.matrixElements[index], &element);
        runtime.realMultiply(&element, &element, &element, &runtime.ctxtReal39);
        runtime.realAdd(&sum, &element, &sum, &runtime.ctxtReal39);
    }

    runtime.realSquareRoot(&sum, &sum, &runtime.ctxtReal39);

    for (0..count) |index| {
        runtime.real34ToReal(&matrix.matrixElements[index], &element);
        runtime.realDivide(&element, &sum, &element, &runtime.ctxtReal39);
        runtime.realToReal34(&element, &matrix.matrixElements[index]);
    }

    runtime.convertReal34MatrixToReal34MatrixRegister(&matrix, runtime.REGISTER_X);
}

fn unitVectorCxma() void {
    var matrix: runtime.complex34Matrix_t = undefined;
    var real_value: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;
    var sum: runtime.real_t = undefined;

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &matrix);
    runtime.realSetZero(&sum);

    const count = @min(@as(usize, matrix.header.matrixRows) * @as(usize, matrix.header.matrixColumns), matrix.matrixElements.len);

    for (0..count) |index| {
        runtime.real34ToReal(&matrix.matrixElements[index].real, &real_value);
        runtime.realMultiply(&real_value, &real_value, &real_value, &runtime.ctxtReal39);
        runtime.realAdd(&sum, &real_value, &sum, &runtime.ctxtReal39);
        runtime.real34ToReal(&matrix.matrixElements[index].imag, &imag_value);
        runtime.realMultiply(&imag_value, &imag_value, &imag_value, &runtime.ctxtReal39);
        runtime.realAdd(&sum, &imag_value, &sum, &runtime.ctxtReal39);
    }

    runtime.realSquareRoot(&sum, &sum, &runtime.ctxtReal39);

    for (0..count) |index| {
        runtime.real34ToReal(&matrix.matrixElements[index].real, &real_value);
        runtime.real34ToReal(&matrix.matrixElements[index].imag, &imag_value);
        runtime.divComplexComplex(&real_value, &imag_value, &sum, runtime.z47_math_wrappers_const_0(), &real_value, &imag_value, &runtime.ctxtReal39);
        runtime.realToReal34(&real_value, &matrix.matrixElements[index].real);
        runtime.realToReal34(&imag_value, &matrix.matrixElements[index].imag);
    }

    runtime.convertComplex34MatrixToComplex34MatrixRegister(&matrix, runtime.REGISTER_X);
}

pub export fn fnUnitVector(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    if (!runtime.saveLastX()) {
        return;
    }

    switch (runtime.getRegisterDataType(runtime.REGISTER_X)) {
        runtime.dtComplex34 => unitVectorComplex(),
        runtime.dtReal34Matrix => unitVectorRema(),
        runtime.dtComplex34Matrix => unitVectorCxma(),
        else => unitVectorError(),
    }

    runtime.adjustResult(runtime.REGISTER_X, false, true, runtime.REGISTER_X, no_register, no_register);
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

fn sqrtShoI() callconv(.c) void {
    var sign_value: i32 = 0;

    _ = runtime.WP34S_extract_value(@as(*u64, @ptrCast(@alignCast(runtime.getRegisterDataPointer(runtime.REGISTER_X).?))).*, &sign_value);
    if (sign_value != 0 and runtime.getFlag(@intCast(runtime.FLAG_CPXRES))) {
        var value: runtime.real_t = undefined;

        runtime.convertShortIntegerRegisterToReal(runtime.REGISTER_X, &value, &runtime.ctxtReal39);
        runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtComplex34, 0, runtime.amNone);
        runtime.realSetPositiveSign(&value);
        runtime.realSquareRoot(&value, &value, &runtime.ctxtReal39);
        runtime.convertComplexToResultRegister(runtime.z47_math_wrappers_const_0(), &value, runtime.REGISTER_X);
        return;
    }

    @as(*u64, @ptrCast(@alignCast(runtime.getRegisterDataPointer(runtime.REGISTER_X).?))).* = runtime.WP34S_intSqrt(@as(*u64, @ptrCast(@alignCast(runtime.getRegisterDataPointer(runtime.REGISTER_X).?))).*);
}

fn sqrtReal() callconv(.c) void {
    var value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &value)) {
        return;
    }

    if (runtime.realIsInfinite(&value) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function sqrtReal:", "cannot use infinity as X input of sqrt when flag D is not set", null, null);
        return;
    }

    if (!runtime.realIsNegative(&value)) {
        runtime.realSquareRoot(&value, &value, &runtime.ctxtReal39);
        runtime.convertRealToResultRegister(&value, runtime.REGISTER_X, runtime.amNone);
        return;
    }

    if (runtime.getFlag(@intCast(runtime.FLAG_CPXRES))) {
        runtime.realSetPositiveSign(&value);
        runtime.realSquareRoot(&value, &value, &runtime.ctxtReal39);
        runtime.convertComplexToResultRegister(runtime.z47_math_wrappers_const_0(), &value, runtime.REGISTER_X);
        return;
    }

    runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
    runtime.moreInfoOnError("In function sqrtReal:", "sqrt does not accept a negative real when flag I is not set", null, null);
}

fn sqrtLonI() callconv(.c) void {
    var value: runtime.longInteger_t = undefined;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &value[0], null)) {
        return;
    }
    defer runtime.__gmpz_clear(&value[0]);

    if (value[0]._mp_size >= 0) {
        var rem: runtime.longInteger_t = undefined;
        var root: runtime.longInteger_t = undefined;

        runtime.__gmpz_init(&rem[0]);
        defer runtime.__gmpz_clear(&rem[0]);
        runtime.__gmpz_init(&root[0]);
        defer runtime.__gmpz_clear(&root[0]);

        runtime.__gmpz_rootrem(&root[0], &rem[0], &value[0], 2);
        if (rem[0]._mp_size == 0) {
            runtime.convertLongIntegerToLongIntegerRegister(&root[0], runtime.REGISTER_X);
            return;
        }
    }

    sqrtReal();
}

fn sqrtCplx() callconv(.c) void {
    var real_value: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &real_value, &imag_value)) {
        return;
    }

    if (runtime.realIsZero(&imag_value) and runtime.realIsNegative(&real_value)) {
        runtime.realChangeSign(&real_value);
        runtime.realSquareRoot(&real_value, &imag_value, &runtime.ctxtReal39);
        runtime.realSetZero(&real_value);
    } else if (runtime.realIsZero(&imag_value)) {
        runtime.realSquareRoot(&real_value, &real_value, &runtime.ctxtReal39);
        runtime.realSetZero(&imag_value);
    } else {
        runtime.realRectangularToPolar(&real_value, &imag_value, &real_value, &imag_value, &runtime.ctxtReal39);
        runtime.realSquareRoot(&real_value, &real_value, &runtime.ctxtReal39);
        runtime.realMultiply(&imag_value, runtime.z47_math_wrappers_const_1on2(), &imag_value, &runtime.ctxtReal39);
        runtime.realPolarToRectangular(&real_value, &imag_value, &real_value, &imag_value, &runtime.ctxtReal39);
    }

    runtime.convertComplexToResultRegister(&real_value, &imag_value, runtime.REGISTER_X);
}

fn curtShoI() callconv(.c) void {
    var value: runtime.real_t = undefined;
    var cube_root: i32 = 0;

    runtime.convertShortIntegerRegisterToReal(runtime.REGISTER_X, &value, &runtime.ctxtReal39);

    if (runtime.realIsNegative(&value)) {
        runtime.realSetPositiveSign(&value);
        runtime.PowerReal(&value, runtime.z47_math_wrappers_const_1on3(), &value, &runtime.ctxtReal39);
        runtime.realChangeSign(&value);
    } else {
        runtime.PowerReal(&value, runtime.z47_math_wrappers_const_1on3(), &value, &runtime.ctxtReal39);
    }

    cube_root = runtime.realToInt32C47(&value, null);
    if (cube_root >= 0) {
        @as(*u64, @ptrCast(@alignCast(runtime.getRegisterDataPointer(runtime.REGISTER_X).?))).* = runtime.WP34S_build_value(@intCast(cube_root), 0);
    } else {
        @as(*u64, @ptrCast(@alignCast(runtime.getRegisterDataPointer(runtime.REGISTER_X).?))).* = runtime.WP34S_build_value(@intCast(-cube_root), 1);
    }
}

fn curtReal() callconv(.c) void {
    var value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &value)) {
        return;
    }

    if (runtime.realIsInfinite(&value) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function curtReal:", "cannot use infinity as X input of curt when flag D is not set", null, null);
        return;
    }

    if (runtime.realIsNegative(&value)) {
        runtime.realSetPositiveSign(&value);
        runtime.PowerReal(&value, runtime.z47_math_wrappers_const_1on3(), &value, &runtime.ctxtReal39);
        runtime.realChangeSign(&value);
    } else {
        runtime.PowerReal(&value, runtime.z47_math_wrappers_const_1on3(), &value, &runtime.ctxtReal39);
    }

    runtime.convertRealToResultRegister(&value, runtime.REGISTER_X, runtime.amNone);
}

fn curtLonI() callconv(.c) void {
    var value: runtime.longInteger_t = undefined;
    var rem: runtime.longInteger_t = undefined;
    var root: runtime.longInteger_t = undefined;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &value[0], null)) {
        return;
    }
    defer runtime.__gmpz_clear(&value[0]);

    runtime.__gmpz_init(&rem[0]);
    defer runtime.__gmpz_clear(&rem[0]);
    runtime.__gmpz_init(&root[0]);
    defer runtime.__gmpz_clear(&root[0]);

    runtime.__gmpz_rootrem(&root[0], &rem[0], &value[0], 3);
    if (rem[0]._mp_size == 0) {
        runtime.convertLongIntegerToLongIntegerRegister(&root[0], runtime.REGISTER_X);
        return;
    }

    curtReal();
}

fn curtCplx() callconv(.c) void {
    var real_value: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;
    var magnitude: runtime.real_t = undefined;
    var angle: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &real_value, &imag_value)) {
        return;
    }

    magnitude = real_value;
    angle = imag_value;

    if (runtime.realIsZero(&angle)) {
        if (runtime.realIsNegative(&magnitude)) {
            runtime.realSetPositiveSign(&magnitude);
            runtime.PowerReal(&magnitude, runtime.z47_math_wrappers_const_1on3(), &real_value, &runtime.ctxtReal39);
            runtime.realChangeSign(&real_value);
        } else {
            runtime.PowerReal(&magnitude, runtime.z47_math_wrappers_const_1on3(), &real_value, &runtime.ctxtReal39);
        }
        runtime.realSetZero(&imag_value);
    } else {
        runtime.realRectangularToPolar(&magnitude, &angle, &magnitude, &angle, &runtime.ctxtReal39);
        runtime.PowerReal(&magnitude, runtime.z47_math_wrappers_const_1on3(), &magnitude, &runtime.ctxtReal39);
        runtime.realMultiply(&angle, runtime.z47_math_wrappers_const_1on3(), &angle, &runtime.ctxtReal39);
        runtime.realPolarToRectangular(&magnitude, &angle, &real_value, &imag_value, &runtime.ctxtReal39);
    }

    runtime.convertComplexToResultRegister(&real_value, &imag_value, runtime.REGISTER_X);
}

fn fibonacciReal(n: *const runtime.real_t, res: *runtime.real_t, real_context: *runtime.realContext_t) void {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;

    runtime.realPower(runtime.z47_math_wrappers_const_phi(), n, &a, real_context);
    runtime.realDivide(runtime.z47_math_wrappers_const_1(), &a, &b, real_context);
    runtime.realMultiply(runtime.z47_math_wrappers_const_pi(), n, res, real_context);
    runtime.C47_WP34S_Cvt2RadSinCosTan(res, runtime.amRadian, null, res, null, real_context);
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

fn linpolReadCoeff(regist: runtime.calcRegister_t, data_type: u32, real_part: *runtime.real_t, imag_part: *runtime.real_t, real_coefs: *bool) bool {
    switch (data_type) {
        runtime.dtLongInteger => {
            runtime.convertLongIntegerRegisterToReal(regist, real_part, &runtime.ctxtReal75);
            return true;
        },
        runtime.dtShortInteger => {
            runtime.convertShortIntegerRegisterToReal(regist, real_part, &runtime.ctxtReal39);
            return true;
        },
        runtime.dtReal34 => {
            if (runtime.getRegisterAngularMode(regist) != runtime.amNone) {
                return false;
            }
            runtime.real34ToReal(real34DataPointer(regist), real_part);
            return true;
        },
        runtime.dtComplex34 => {
            runtime.real34ToReal(real34DataPointer(regist), real_part);
            runtime.real34ToReal(imag34DataPointer(regist), imag_part);
            real_coefs.* = false;
            return true;
        },
        else => return false,
    }
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
    const register_type = runtime.getRegisterDataType(runtime.REGISTER_X);

    _ = unused_but_mandatory_parameter;

    if (register_type == runtime.dtReal34Matrix or register_type == runtime.dtComplex34Matrix) {
        z47_math_wrappers_retained_fnSquareRoot(0);
        return;
    }

    runtime.processIntRealComplexMonadicFunction(&sqrtReal, &sqrtCplx, &sqrtShoI, &sqrtLonI);
}

pub export fn fnCubeRoot(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexMonadicFunction(&curtReal, &curtCplx, &curtShoI, &curtLonI);
}

pub export fn fnPercentMRR(unused_but_mandatory_parameter: u16) callconv(.c) void {
    var x_value: runtime.real_t = undefined;
    var y_value: runtime.real_t = undefined;
    var z_value: runtime.real_t = undefined;
    var result: runtime.real_t = undefined;

    _ = unused_but_mandatory_parameter;

    if (!runtime.saveLastX()) {
        return;
    }

    if (runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value) and runtime.getRegisterAsReal(runtime.REGISTER_Y, &y_value) and runtime.getRegisterAsReal(runtime.REGISTER_Z, &z_value)) {
        if (runtime.realIsZero(&x_value) and runtime.realIsZero(&y_value)) {
            if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
                runtime.realSetNaN(&result);
            } else {
                runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            }
        } else if (runtime.realIsZero(&y_value)) {
            if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
                result = runtime.z47_math_wrappers_const_plus_infinity().*;
                if (runtime.realIsNegative(&x_value)) {
                    result.bits |= 0x80;
                }
            } else {
                runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            }
        } else {
            runtime.realDivide(&x_value, &y_value, &result, &runtime.ctxtReal75);
            runtime.realDivide(runtime.z47_math_wrappers_const_1(), &z_value, &z_value, &runtime.ctxtReal75);
            runtime.realPower(&result, &z_value, &result, &runtime.ctxtReal75);
            runtime.realSubtract(&result, runtime.z47_math_wrappers_const_1(), &result, &runtime.ctxtReal75);
            result.exponent += 2;
        }

        if (runtime.lastErrorCode == 0) {
            runtime.convertRealToResultRegister(&result, runtime.REGISTER_X, runtime.amNone);
            runtime.temporaryInformation = runtime.TI_PERC;
        }
    }

    runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, no_register, no_register);
    if (runtime.lastErrorCode == 0) {
        runtime.fnDropY(0);
    }
}

pub export fn fnPercentPlusMG(unused_but_mandatory_parameter: u16) callconv(.c) void {
    var x_value: runtime.real_t = undefined;
    var y_value: runtime.real_t = undefined;
    var result: runtime.real_t = undefined;

    _ = unused_but_mandatory_parameter;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value) or !runtime.getRegisterAsReal(runtime.REGISTER_Y, &y_value)) {
        return;
    }

    if (!runtime.saveLastX()) {
        return;
    }

    if (runtime.realCompareEqual(&x_value, runtime.z47_math_wrappers_const_100()) and runtime.realIsZero(&y_value)) {
        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.realSetNaN(&result);
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            return;
        }
    } else if (runtime.realCompareEqual(&x_value, runtime.z47_math_wrappers_const_100())) {
        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            result = runtime.z47_math_wrappers_const_plus_infinity().*;
            if (runtime.realIsNegative(&y_value)) {
                result.bits |= 0x80;
            }
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            return;
        }
    } else {
        runtime.realDivide(&x_value, runtime.z47_math_wrappers_const_100(), &result, &runtime.ctxtReal34);
        runtime.realSubtract(runtime.z47_math_wrappers_const_1(), &result, &result, &runtime.ctxtReal34);
        runtime.realDivide(&y_value, &result, &result, &runtime.ctxtReal34);
    }

    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
    runtime.convertRealToReal34ResultRegister(&result, runtime.REGISTER_X);
    runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.amNone);
    runtime.adjustResult(runtime.REGISTER_X, false, true, runtime.REGISTER_X, no_register, no_register);
}

pub export fn fnPercentT(unused_but_mandatory_parameter: u16) callconv(.c) void {
    var x_value: runtime.real_t = undefined;
    var y_value: runtime.real_t = undefined;
    var result: runtime.real_t = undefined;
    var write_result = false;

    _ = unused_but_mandatory_parameter;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value) or !runtime.getRegisterAsReal(runtime.REGISTER_Y, &y_value)) {
        return;
    }

    if (!runtime.saveLastX()) {
        return;
    }

    if (runtime.realIsZero(&x_value) and runtime.realIsZero(&y_value)) {
        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.realSetNaN(&result);
            write_result = true;
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        }
    } else if (runtime.realIsZero(&y_value)) {
        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            result = runtime.z47_math_wrappers_const_plus_infinity().*;
            if (runtime.realIsNegative(&x_value)) {
                result.bits |= 0x80;
            }
            write_result = true;
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        }
    } else {
        x_value.exponent += 2;
        runtime.realDivide(&x_value, &y_value, &result, &runtime.ctxtReal39);
        write_result = true;
    }

    if (write_result) {
        runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
        runtime.convertRealToReal34ResultRegister(&result, runtime.REGISTER_X);
    }

    runtime.adjustResult(runtime.REGISTER_X, false, true, runtime.REGISTER_X, no_register, no_register);
    runtime.temporaryInformation = runtime.TI_PERC;
}

pub export fn fnDeltaPercent(unused_but_mandatory_parameter: u16) callconv(.c) void {
    var x_value: runtime.real_t = undefined;
    var y_value: runtime.real_t = undefined;
    var result = std.mem.zeroes(runtime.real_t);

    _ = unused_but_mandatory_parameter;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value) or !runtime.getRegisterAsReal(runtime.REGISTER_Y, &y_value)) {
        return;
    }

    if (!runtime.saveLastX()) {
        return;
    }

    if (runtime.realIsZero(&x_value) and runtime.realCompareEqual(&x_value, &y_value)) {
        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.realSetNaN(&result);
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        }
    } else if (runtime.realIsZero(&y_value)) {
        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            result = runtime.z47_math_wrappers_const_plus_infinity().*;
            if (runtime.realIsZero(&x_value)) {
                result.bits |= 0x80;
            }
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        }
    } else {
        runtime.realSubtract(&x_value, &y_value, &result, &runtime.ctxtReal39);
        runtime.realDivide(&result, &y_value, &result, &runtime.ctxtReal39);
        result.exponent += 2;
    }

    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
    runtime.convertRealToReal34ResultRegister(&result, runtime.REGISTER_X);
    runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.amNone);
    runtime.adjustResult(runtime.REGISTER_X, false, true, runtime.REGISTER_X, no_register, no_register);
    runtime.temporaryInformation = runtime.TI_PERCD;
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
    const type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);
    const type_z = runtime.getRegisterDataType(runtime.REGISTER_Z);
    const is_y_angle = type_y == runtime.dtReal34 and runtime.getRegisterAngularMode(runtime.REGISTER_Y) != runtime.amNone;
    const is_z_angle = type_z == runtime.dtReal34 and runtime.getRegisterAngularMode(runtime.REGISTER_Z) != runtime.amNone;

    _ = unused_but_mandatory_parameter;
    runtime.realSetZero(&a_imag);
    runtime.realSetZero(&b_imag);

    if (!linpolReadP(&p) or
        !(type_y == runtime.dtLongInteger or type_y == runtime.dtShortInteger or type_y == runtime.dtReal34 or type_y == runtime.dtComplex34) or
        !(type_z == runtime.dtLongInteger or type_z == runtime.dtShortInteger or type_z == runtime.dtReal34 or type_z == runtime.dtComplex34) or
        is_y_angle or is_z_angle)
    {
        z47_math_wrappers_retained_fnLINPOL(0);
        return;
    }

    if (!linpolReadCoeff(runtime.REGISTER_Y, type_y, &b_real, &b_imag, &real_coefs) or !linpolReadCoeff(runtime.REGISTER_Z, type_z, &a_real, &a_imag, &real_coefs)) {
        z47_math_wrappers_retained_fnLINPOL(0);
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
        runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
        runtime.convertRealToReal34ResultRegister(&result_real, runtime.REGISTER_X);
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

pub export fn fnCross(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const type_x = runtime.getRegisterDataType(runtime.REGISTER_X);
    const type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);

    _ = unused_but_mandatory_parameter;

    if (type_x == runtime.dtReal34Matrix or type_x == runtime.dtComplex34Matrix or type_y == runtime.dtReal34Matrix or type_y == runtime.dtComplex34Matrix) {
        z47_math_wrappers_retained_fnCross(0);
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

pub export fn fnDot(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const type_x = runtime.getRegisterDataType(runtime.REGISTER_X);
    const type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);

    _ = unused_but_mandatory_parameter;

    if (type_x == runtime.dtReal34Matrix or type_x == runtime.dtComplex34Matrix or type_y == runtime.dtReal34Matrix or type_y == runtime.dtComplex34Matrix) {
        z47_math_wrappers_retained_fnDot(0);
        return;
    }

    runtime.processRealComplexDyadicFunction(&doDotReal, &doDotCplx);
}

fn logXYComplex(
    x_real: *const runtime.real_t,
    x_imag: *const runtime.real_t,
    y_real: *const runtime.real_t,
    y_imag: *const runtime.real_t,
    result_real: *runtime.real_t,
    result_imag: *runtime.real_t,
) void {
    var ln_x_real: runtime.real_t = undefined;
    var ln_x_imag: runtime.real_t = undefined;

    runtime.lnComplex(y_real, y_imag, result_real, result_imag, &runtime.ctxtReal39);
    runtime.lnComplex(x_real, x_imag, &ln_x_real, &ln_x_imag, &runtime.ctxtReal39);
    runtime.divComplexComplex(result_real, result_imag, &ln_x_real, &ln_x_imag, result_real, result_imag, &runtime.ctxtReal39);
}

fn logXYArgsHandled(x_real: *const runtime.real_t, x_imag: ?*const runtime.real_t, y_real: *const runtime.real_t, y_imag: ?*const runtime.real_t) bool {
    const x_zero = runtime.realIsZero(x_real) and (x_imag == null or runtime.realIsZero(x_imag.?));
    const y_zero = runtime.realIsZero(y_real) and (y_imag == null or runtime.realIsZero(y_imag.?));

    if (x_zero and y_zero) {
        if (runtime.getFlag(@intCast(runtime.FLAG_SPCRES))) {
            runtime.convertRealToResultRegister(runtime.z47_math_wrappers_const_plus_infinity(), runtime.REGISTER_X, runtime.amNone);
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_OVERFLOW_PLUS_INF, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            runtime.moreInfoOnError("checkArgs", "cannot calculate LogXY with x=0 and y=0", null, null);
        }
        return true;
    }

    if (!x_zero and y_zero) {
        if (runtime.getFlag(@intCast(runtime.FLAG_SPCRES))) {
            runtime.convertRealToResultRegister(runtime.z47_math_wrappers_const_minus_infinity(), runtime.REGISTER_X, runtime.amNone);
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_OVERFLOW_MINUS_INF, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            runtime.moreInfoOnError("checkArgs", "cannot calculate LogXY with x=0 and y!=0", null, null);
        }
        return true;
    }

    if (x_zero and !y_zero) {
        if (runtime.getFlag(@intCast(runtime.FLAG_SPCRES))) {
            runtime.convertRealToResultRegister(runtime.const_NaN, runtime.REGISTER_X, runtime.amNone);
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        }
        return true;
    }

    return false;
}

fn logxyRealCore(x_real: *const runtime.real_t, y_real: *const runtime.real_t, real_context: *runtime.realContext_t) void {
    var result_real: runtime.real_t = undefined;
    var result_imag: runtime.real_t = undefined;

    if (logXYArgsHandled(x_real, null, y_real, null)) {
        return;
    }

    if (runtime.realIsNegative(x_real) or runtime.realIsNegative(y_real)) {
        logXYComplex(x_real, runtime.z47_math_wrappers_const_0(), y_real, runtime.z47_math_wrappers_const_0(), &result_real, &result_imag);

        if (!runtime.realIsZero(&result_imag)) {
            if (runtime.getFlag(@intCast(runtime.FLAG_CPXRES))) {
                runtime.convertComplexToResultRegister(&result_real, &result_imag, runtime.REGISTER_X);
                return;
            }

            if (runtime.getFlag(@intCast(runtime.FLAG_SPCRES))) {
                runtime.realSetNaN(&result_real);
            } else {
                runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
                runtime.moreInfoOnError("logxy", "cannot calculate LogXY with x<0 or y<0 when flag I is not set", null, null);
                return;
            }
        }
    } else {
        runtime.WP34S_Logxy(y_real, x_real, &result_real, real_context);
    }

    runtime.convertRealToResultRegister(&result_real, runtime.REGISTER_X, runtime.amNone);
}

fn logXYLongInt() callconv(.c) void {
    var x_value: runtime.real_t = undefined;
    var y_value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value) or !runtime.getRegisterAsReal(runtime.REGISTER_Y, &y_value)) {
        return;
    }

    logxyRealCore(&x_value, &y_value, &runtime.ctxtReal39);

    if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtReal34 and runtime.real34IsAnInteger(runtime.registerReal34Ptr(runtime.REGISTER_X))) {
        runtime.convertReal34ToLongIntegerRegister(runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.REGISTER_X, runtime.DEC_ROUND_DOWN);
    }
}

fn logXYShortInt() callconv(.c) void {
    var x_value: runtime.real_t = undefined;
    var y_value: runtime.real_t = undefined;
    const base = runtime.getRegisterShortIntegerBase(runtime.REGISTER_Y);

    if (!runtime.getRegisterAsReal(runtime.REGISTER_Y, &y_value) or !runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value)) {
        return;
    }

    logxyRealCore(&x_value, &y_value, &runtime.ctxtReal39);

    if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtReal34) {
        if (runtime.real34IsNaN(runtime.registerReal34Ptr(runtime.REGISTER_X)) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            runtime.moreInfoOnError("logxy", "cannot calculate LogXY with x=0", null, null);
            return;
        }

        if (runtime.real34IsAnInteger(runtime.registerReal34Ptr(runtime.REGISTER_X))) {
            runtime.clearSystemFlag(runtime.FLAG_CARRY);
        } else {
            runtime.setSystemFlag(runtime.FLAG_CARRY);
        }

        runtime.fnChangeBase(@intCast(base));
    }
}

fn logXYReal() callconv(.c) void {
    var x_value: runtime.real_t = undefined;
    var y_value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_Y, &y_value) or !runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value)) {
        return;
    }

    logxyRealCore(&x_value, &y_value, &runtime.ctxtReal39);
}

fn logXYCplx() callconv(.c) void {
    var x_real: runtime.real_t = undefined;
    var x_imag: runtime.real_t = undefined;
    var y_real: runtime.real_t = undefined;
    var y_imag: runtime.real_t = undefined;
    var result_real: runtime.real_t = undefined;
    var result_imag: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_Y, &y_real, &y_imag) or !runtime.getRegisterAsComplex(runtime.REGISTER_X, &x_real, &x_imag)) {
        return;
    }

    if (logXYArgsHandled(&x_real, &x_imag, &y_real, &y_imag)) {
        return;
    }

    logXYComplex(&x_real, &x_imag, &y_real, &y_imag, &result_real, &result_imag);
    runtime.convertComplexToResultRegister(&result_real, &result_imag, runtime.REGISTER_X);
}

pub export fn fnLogXY(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexDyadicFunction(&logXYReal, &logXYCplx, &logXYShortInt, &logXYLongInt);
}
