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
const z47_math_wrappers_retained_fnCheckMatrixSquare = runtime.retained.z47_math_wrappers_retained_fnCheckMatrixSquare;
const z47_math_wrappers_retained_fnCheckForZero = runtime.retained.z47_math_wrappers_retained_fnCheckForZero;
const z47_math_wrappers_retained_fnCheckIsVect2d = runtime.retained.z47_math_wrappers_retained_fnCheckIsVect2d;
const z47_math_wrappers_retained_fnCheckIsVect3d = runtime.retained.z47_math_wrappers_retained_fnCheckIsVect3d;
const z47_math_wrappers_retained_fnCheckNaN = runtime.retained.z47_math_wrappers_retained_fnCheckNaN;
const z47_math_wrappers_retained_fnCheckInfinite = runtime.retained.z47_math_wrappers_retained_fnCheckInfinite;
const z47_math_wrappers_retained_fnCheckSpecial = runtime.retained.z47_math_wrappers_retained_fnCheckSpecial;
const z47_math_wrappers_retained_fnCheckPlusZero = runtime.retained.z47_math_wrappers_retained_fnCheckPlusZero;
const z47_math_wrappers_retained_fnCheckMinusZero = runtime.retained.z47_math_wrappers_retained_fnCheckMinusZero;
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

fn roundiReal() void {
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

    const result = if (runtime.realIsNaN(&x_value))
        &x_value
    else if (runtime.realIsZero(&x_value) and runtime.getSystemFlag(runtime.FLAG_SPCRES))
        &x_value
    else if (runtime.realIsNegative(&x_value))
        runtime.z47_math_wrappers_const_180()
    else
        runtime.z47_math_wrappers_const_0();

    runtime.convertRealToResultRegister(result, runtime.REGISTER_X, runtime.amNone);
    if (!runtime.realIsNaN(result)) {
        runtime.convertAngle34FromTo(runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.amDegree, runtime.currentAngularMode);
        runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.currentAngularMode);
    }
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

    if (!runtime.saveLastX()) {
        return;
    }

    switch (register_data_type) {
        runtime.dtLongInteger => ulpLongInteger(),
        runtime.dtShortInteger => ulpShortInteger(),
        runtime.dtReal34 => ulpReal(),
        else => {
            z47_math_wrappers_retained_fnUlp(unused_but_mandatory_parameter);
            return;
        },
    }

    runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, no_register, no_register);
}

pub export fn fnMant(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    if (register_data_type != runtime.dtLongInteger and register_data_type != runtime.dtReal34) {
        z47_math_wrappers_retained_fnMant(unused_but_mandatory_parameter);
        return;
    }

    if (!runtime.saveLastX()) {
        return;
    }

    switch (register_data_type) {
        runtime.dtLongInteger => mantLonI(),
        runtime.dtReal34 => mantReal(),
        else => unreachable,
    }

    runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, no_register, no_register);
}

pub export fn fnRoundi(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    if (register_data_type != runtime.dtReal34) {
        z47_math_wrappers_retained_fnRoundi(unused_but_mandatory_parameter);
        return;
    }

    if (!runtime.saveLastX()) {
        return;
    }

    roundiReal();
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
    runtime.processIntRealComplexMonadicFunction(&factReal, &factCplx, &factShoI, &runtime.z47_math_wrappers_fact_long_integer);
}

pub export fn fnRealPart(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    if (register_data_type == runtime.dtReal34Matrix or register_data_type == runtime.dtComplex34Matrix) {
        z47_math_wrappers_retained_fnRealPart(unused_but_mandatory_parameter);
        return;
    }

    runtime.processRealComplexMonadicFunction(&realPartReal, &realPartCplx);
}

pub export fn fnImaginaryPart(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    if (register_data_type == runtime.dtReal34Matrix or register_data_type == runtime.dtComplex34Matrix) {
        z47_math_wrappers_retained_fnImaginaryPart(unused_but_mandatory_parameter);
        return;
    }

    runtime.processRealComplexMonadicFunction(&imagPartReal, &imagPartCplx);
}

pub export fn fnArg(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    if (register_data_type == runtime.dtReal34Matrix or register_data_type == runtime.dtComplex34Matrix) {
        z47_math_wrappers_retained_fnArg(unused_but_mandatory_parameter);
        return;
    }

    if (!runtime.saveLastX()) {
        return;
    }

    switch (register_data_type) {
        runtime.dtLongInteger, runtime.dtReal34, runtime.dtShortInteger => argReal(),
        runtime.dtComplex34 => argCplx(),
        else => argError(),
    }

    runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, no_register, no_register);
}

pub export fn fnMagnitude(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    if (register_data_type == runtime.dtComplex34Matrix or register_data_type == runtime.dtReal34Matrix) {
        z47_math_wrappers_retained_fnMagnitude(unused_but_mandatory_parameter);
        return;
    }

    runtime.processIntRealComplexMonadicFunction(&magnitudeReal, &magnitudeCplx, &magnitudeShoI, &magnitudeLonI);
}

pub export fn fnConjugate(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    if (register_data_type == runtime.dtComplex34Matrix or register_data_type == runtime.dtReal34Matrix) {
        z47_math_wrappers_retained_fnConjugate(unused_but_mandatory_parameter);
        return;
    }

    if (!runtime.saveLastX()) {
        return;
    }

    conjCplx();
}

pub export fn fnSwapRealImaginary(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    if (register_data_type == runtime.dtReal34Matrix or register_data_type == runtime.dtComplex34Matrix) {
        z47_math_wrappers_retained_fnSwapRealImaginary(unused_but_mandatory_parameter);
        return;
    }

    if (!runtime.saveLastX()) {
        return;
    }

    swapReImCplx();
}

pub export fn fnAtan2(unused_but_mandatory_parameter: u16) callconv(.c) void {
    const data_type_x = runtime.getRegisterDataType(runtime.REGISTER_X);
    const data_type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);
    const x_supported = data_type_x == runtime.dtReal34 or data_type_x == runtime.dtLongInteger;
    const y_supported = data_type_y == runtime.dtReal34 or data_type_y == runtime.dtLongInteger;

    if (!x_supported or !y_supported) {
        z47_math_wrappers_retained_fnAtan2(unused_but_mandatory_parameter);
        return;
    }

    if (!runtime.saveLastX()) {
        return;
    }

    atan2RealReal();
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
    z47_math_wrappers_retained_fnDblMultiply(unused_but_mandatory_parameter);
}

pub export fn fnRound(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnRound(unused_but_mandatory_parameter);
}

pub export fn fnDecomp(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnDecomp(unused_but_mandatory_parameter);
}

pub export fn fnCheckInteger(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnCheckInteger(unused_but_mandatory_parameter);
}

pub export fn fnDec(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnDec(unused_but_mandatory_parameter);
}

pub export fn fnInc(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnInc(unused_but_mandatory_parameter);
}

pub export fn fnXLessThan(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnXLessThan(unused_but_mandatory_parameter);
}

pub export fn fnXLessEqual(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnXLessEqual(unused_but_mandatory_parameter);
}

pub export fn fnXGreaterThan(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnXGreaterThan(unused_but_mandatory_parameter);
}

pub export fn fnXGreaterEqual(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnXGreaterEqual(unused_but_mandatory_parameter);
}

pub export fn fnXEqualsTo(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnXEqualsTo(unused_but_mandatory_parameter);
}

pub export fn fnXNotEqual(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnXNotEqual(unused_but_mandatory_parameter);
}

pub export fn fnXAlmostEqual(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnXAlmostEqual(unused_but_mandatory_parameter);
}

pub export fn fnIsConverged(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnIsConverged(unused_but_mandatory_parameter);
}

pub export fn fnCheckType(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnCheckType(unused_but_mandatory_parameter);
}

pub export fn fnCheckReal(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnCheckReal(unused_but_mandatory_parameter);
}

pub export fn fnCheckNumber(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnCheckNumber(unused_but_mandatory_parameter);
}

pub export fn fnCheckAngle(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnCheckAngle(unused_but_mandatory_parameter);
}

pub export fn fnCheckMatrix(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnCheckMatrix(unused_but_mandatory_parameter);
}

pub export fn fnCheckMatrixSquare(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnCheckMatrixSquare(unused_but_mandatory_parameter);
}

pub export fn fnCheckForZero(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnCheckForZero(unused_but_mandatory_parameter);
}

pub export fn fnCheckIsVect2d(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnCheckIsVect2d(unused_but_mandatory_parameter);
}

pub export fn fnCheckIsVect3d(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnCheckIsVect3d(unused_but_mandatory_parameter);
}

pub export fn fnCheckNaN(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnCheckNaN(unused_but_mandatory_parameter);
}

pub export fn fnCheckInfinite(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnCheckInfinite(unused_but_mandatory_parameter);
}

pub export fn fnCheckSpecial(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnCheckSpecial(unused_but_mandatory_parameter);
}

pub export fn fnCheckPlusZero(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnCheckPlusZero(unused_but_mandatory_parameter);
}

pub export fn fnCheckMinusZero(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnCheckMinusZero(unused_but_mandatory_parameter);
}

pub export fn fnGetType(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnGetType(unused_but_mandatory_parameter);
}

pub export fn fnDblDivide(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnDblDivide(unused_but_mandatory_parameter);
}

pub export fn fnDblDivideRemainder(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnDblDivideRemainder(unused_but_mandatory_parameter);
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
        return false;
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

    if (tryFnToRectReal34Pair(angle_in_y)) {
        return;
    }

    z47_math_wrappers_retained_fnToRect(unused_but_mandatory_parameter);
}

pub export fn fnParallel(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnParallel(unused_but_mandatory_parameter);
}

pub export fn fnUnitVector(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnUnitVector(unused_but_mandatory_parameter);
}

pub export fn fnSdl(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnSdl(unused_but_mandatory_parameter);
}

pub export fn fnSdr(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnSdr(unused_but_mandatory_parameter);
}

pub export fn fnSquareRoot(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnSquareRoot(unused_but_mandatory_parameter);
}

pub export fn fnCubeRoot(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnCubeRoot(unused_but_mandatory_parameter);
}

pub export fn fnPercentMRR(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnPercentMRR(unused_but_mandatory_parameter);
}

pub export fn fnPercentPlusMG(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnPercentPlusMG(unused_but_mandatory_parameter);
}

pub export fn fnPercentT(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnPercentT(unused_but_mandatory_parameter);
}

pub export fn fnDeltaPercent(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnDeltaPercent(unused_but_mandatory_parameter);
}

pub export fn fnFib(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnFib(unused_but_mandatory_parameter);
}

pub export fn fnLINPOL(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnLINPOL(unused_but_mandatory_parameter);
}

pub export fn fnCross(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnCross(unused_but_mandatory_parameter);
}

pub export fn fnDot(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnDot(unused_but_mandatory_parameter);
}

pub export fn fnLogXY(unused_but_mandatory_parameter: u16) callconv(.c) void {
    z47_math_wrappers_retained_fnLogXY(unused_but_mandatory_parameter);
}
