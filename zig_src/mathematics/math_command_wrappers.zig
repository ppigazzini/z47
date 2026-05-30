const atan2_export = @import("math_atan2_export.zig");
const check_wrapper_owned = @import("math_check_wrapper_owned.zig");
const circular_trig_export = @import("math_circular_trig_export.zig");
const compare_wrapper_owned = @import("math_compare_wrapper_owned.zig");
const convergence_owned = @import("math_convergence_owned.zig");
const integer_part_owned = @import("math_integer_part_owned.zig");
const ln_complex_export = @import("math_ln_complex_export.zig");
const real_trig_export = @import("math_real_trig_export.zig");
const runtime = @import("math_command_wrappers_runtime.zig");
const increment_decrement_command_owned = @import("math_increment_decrement_command_owned.zig");
const scalar_integer_inspection_command_owned = @import("math_scalar_integer_inspection_command_owned.zig");
const trig_complex_primitives_owned = @import("math_trig_complex_primitives_owned.zig");
const transcendental_wrapper_owned = @import("math_transcendental_wrapper_owned.zig");
const logxy_wrapper_owned = @import("math_logxy_wrapper_owned.zig");
const change_sign_wrapper_owned = @import("math_change_sign_wrapper_owned.zig");
const forward_command_wrappers_owned = @import("math_forward_command_wrappers_owned.zig");
const projection_command_wrapper_owned = @import("math_projection_command_wrapper_owned.zig");
const arithmetic_command_wrapper_owned = @import("math_arithmetic_command_wrapper_owned.zig");
const special_algebraic_wrapper_owned = @import("math_special_algebraic_wrapper_owned.zig");
const inverse_trig_primitive_wrapper_owned = @import("math_inverse_trig_primitive_wrapper_owned.zig");
const tail_command_wrappers_owned = @import("math_tail_command_wrappers_owned.zig");
const random_primitive_wrapper_owned = @import("math_random_primitive_wrapper_owned.zig");

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

const PowRealFn = *const fn (x: *const runtime.real_t, res: *runtime.real_t, real_context: *runtime.realContext_t) callconv(.c) void;
pub export fn pcg32_random_r(rng: *runtime.pcg32_random_t) callconv(.c) u32 {
    return random_primitive_wrapper_owned.pcg32RandomR(rng);
}

pub export fn pcg32_srandom_r(rng: *runtime.pcg32_random_t, initstate: u64, initseq: u64) callconv(.c) void {
    random_primitive_wrapper_owned.pcg32SrandomR(rng, initstate, initseq);
}

pub export fn pcg32_srandom(seed: u64, seq: u64) callconv(.c) void {
    random_primitive_wrapper_owned.pcg32Srandom(seed, seq);
}

pub export fn z47_math_wrappers_bounded_rand(s: u32) callconv(.c) u32 {
    return random_primitive_wrapper_owned.boundedRandExport(s);
}

pub export fn realRandomU01(res: *runtime.real_t) callconv(.c) void {
    random_primitive_wrapper_owned.realRandomU01(res);
}

pub export fn sinComplex(
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    res_real: *runtime.real_t,
    res_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    trig_complex_primitives_owned.sinComplex(real, imag, res_real, res_imag, real_context);
}

pub export fn cosComplex(
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    res_real: *runtime.real_t,
    res_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    trig_complex_primitives_owned.cosComplex(real, imag, res_real, res_imag, real_context);
}

pub export fn sinCosReal(trig_type: runtime.trigType_t) callconv(.c) void {
    trig_complex_primitives_owned.sinCosReal(trig_type);
}

pub export fn sinCosCplx(trig_type: runtime.trigType_t) callconv(.c) void {
    trig_complex_primitives_owned.sinCosCplx(trig_type);
}

pub export fn sinhCoshReal(trig_type: runtime.trigType_t) callconv(.c) void {
    trig_complex_primitives_owned.sinhCoshReal(trig_type);
}

pub export fn sinhCoshCplx(trig_type: runtime.trigType_t) callconv(.c) void {
    trig_complex_primitives_owned.sinhCoshCplx(trig_type);
}

pub export fn TanComplex(
    x_real: *const runtime.real_t,
    x_imag: *const runtime.real_t,
    r_real: *runtime.real_t,
    r_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) u8 {
    return trig_complex_primitives_owned.TanComplex(x_real, x_imag, r_real, r_imag, real_context);
}

pub export fn TanhComplex(
    x_real: *const runtime.real_t,
    x_imag: *const runtime.real_t,
    r_real: *runtime.real_t,
    r_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) u8 {
    return trig_complex_primitives_owned.TanhComplex(x_real, x_imag, r_real, r_imag, real_context);
}

pub export fn realExpLimitCheck(
    x: *const runtime.real_t,
    result: *runtime.real_t,
    zero: *const runtime.real_t,
) callconv(.c) bool {
    return transcendental_wrapper_owned.realExpLimitCheck(x, result, zero);
}

pub export fn realExp(
    x: *const runtime.real_t,
    result: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    transcendental_wrapper_owned.realExp(x, result, real_context);
}

pub export fn expComplex(
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    res_real: *runtime.real_t,
    res_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    transcendental_wrapper_owned.expComplex(real, imag, res_real, res_imag, real_context);
}

pub export fn realExpM1(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    transcendental_wrapper_owned.realExpM1(x, res, real_context);
}

pub export fn realLog10(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    transcendental_wrapper_owned.realLog10(x, res, real_context);
}

pub export fn realPower10(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    transcendental_wrapper_owned.realPower10(x, res, real_context);
}

pub export fn realPower2(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    transcendental_wrapper_owned.realPower2(x, res, real_context);
}

pub export fn intPowReal(powf: PowRealFn) callconv(.c) void {
    transcendental_wrapper_owned.intPowReal(powf);
}

pub export fn intPowCplx(ln_base: *const runtime.real_t) callconv(.c) void {
    transcendental_wrapper_owned.intPowCplx(ln_base);
}

pub export fn logxyReal(denom: *const runtime.real_t) callconv(.c) void {
    logxy_wrapper_owned.logxyReal(denom);
}

pub export fn logxyCplx(denom: *const runtime.real_t) callconv(.c) void {
    logxy_wrapper_owned.logxyCplx(denom);
}

pub export fn logxyLonI(denom: *const runtime.real_t) callconv(.c) void {
    logxy_wrapper_owned.logxyLonI(denom);
}

pub export fn sqrt1Px2Complex(
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    res_real: *runtime.real_t,
    res_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    special_algebraic_wrapper_owned.sqrt1Px2Complex(real, imag, res_real, res_imag, real_context);
}

pub export fn eulersFormula(
    in_real: *const runtime.real_t,
    in_imag: *const runtime.real_t,
    out_real: *runtime.real_t,
    out_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    special_algebraic_wrapper_owned.eulersFormula(in_real, in_imag, out_real, out_imag, real_context);
}

pub export fn fnSqrt1Px2(unused_but_mandatory_parameter: u16) callconv(.c) void {
    special_algebraic_wrapper_owned.fnSqrt1Px2(unused_but_mandatory_parameter);
}

pub export fn fnM1Pow(unused_but_mandatory_parameter: u16) callconv(.c) void {
    special_algebraic_wrapper_owned.fnM1Pow(unused_but_mandatory_parameter);
}

pub export fn fnEulersFormula(unused_but_mandatory_parameter: u16) callconv(.c) void {
    special_algebraic_wrapper_owned.fnEulersFormula(unused_but_mandatory_parameter);
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
    return inverse_trig_primitive_wrapper_owned.ArcsinComplex(x_real, x_imag, r_real, r_imag, real_context);
}

pub export fn ArctanComplex(
    x_real: *runtime.real_t,
    x_imag: *runtime.real_t,
    r_real: *runtime.real_t,
    r_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) u8 {
    return inverse_trig_primitive_wrapper_owned.ArctanComplex(x_real, x_imag, r_real, r_imag, real_context);
}

pub export fn ArcsinhReal(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) u8 {
    return inverse_trig_primitive_wrapper_owned.ArcsinhReal(x, res, real_context);
}

pub export fn ArcsinhComplex(
    x_real: *const runtime.real_t,
    x_imag: *const runtime.real_t,
    r_real: *runtime.real_t,
    r_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) u8 {
    return inverse_trig_primitive_wrapper_owned.ArcsinhComplex(x_real, x_imag, r_real, r_imag, real_context);
}

pub export fn realArcosh(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    inverse_trig_primitive_wrapper_owned.realArcosh(x, res, real_context);
}

pub export fn chsReal() callconv(.c) void {
    change_sign_wrapper_owned.chsReal();
}

pub export fn chsCplx() callconv(.c) void {
    change_sign_wrapper_owned.chsCplx();
}

pub export fn chsShoI() callconv(.c) void {
    change_sign_wrapper_owned.chsShoI();
}

fn chsLonI() callconv(.c) void {
    change_sign_wrapper_owned.chsLonI();
}

pub export fn fnRandom(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnRandom(unused_but_mandatory_parameter);
}

pub export fn fnRandomI(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnRandomI(unused_but_mandatory_parameter);
}

pub export fn fnSeed(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnSeed(unused_but_mandatory_parameter);
}

pub export fn fnMin(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnMin(unused_but_mandatory_parameter);
}

pub export fn fnMax(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnMax(unused_but_mandatory_parameter);
}

pub export fn fnCeil(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnCeil(unused_but_mandatory_parameter);
}

pub export fn fnFloor(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnFloor(unused_but_mandatory_parameter);
}

pub export fn fnIp(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnIp(unused_but_mandatory_parameter);
}

pub export fn fnLint(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnLint(unused_but_mandatory_parameter);
}

pub export fn fnSint(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnSint(unused_but_mandatory_parameter);
}

pub export fn fnFp(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnFp(unused_but_mandatory_parameter);
}

pub export fn fnSinc(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnSinc(unused_but_mandatory_parameter);
}

pub export fn fnSincpi(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnSincpi(unused_but_mandatory_parameter);
}

pub export fn fnSin(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnSin(unused_but_mandatory_parameter);
}

pub export fn fnCos(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnCos(unused_but_mandatory_parameter);
}

pub export fn fnTan(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnTan(unused_but_mandatory_parameter);
}

pub export fn fnArcsin(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnArcsin(unused_but_mandatory_parameter);
}

pub export fn fnArccos(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnArccos(unused_but_mandatory_parameter);
}

pub export fn fnArctan(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnArctan(unused_but_mandatory_parameter);
}

pub export fn fnArcsinh(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnArcsinh(unused_but_mandatory_parameter);
}

pub export fn fnArccosh(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnArccosh(unused_but_mandatory_parameter);
}

pub export fn fnArctanh(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnArctanh(unused_but_mandatory_parameter);
}

pub export fn fnSinh(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnSinh(unused_but_mandatory_parameter);
}

pub export fn fnCosh(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnCosh(unused_but_mandatory_parameter);
}

pub export fn fnTanh(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnTanh(unused_but_mandatory_parameter);
}

pub export fn fnExp(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnExp(unused_but_mandatory_parameter);
}

pub export fn fnExpM1(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnExpM1(unused_but_mandatory_parameter);
}

pub export fn fnLn(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnLn(unused_but_mandatory_parameter);
}

pub export fn fnLnP1(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnLnP1(unused_but_mandatory_parameter);
}

pub export fn fnErf(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnErf(unused_but_mandatory_parameter);
}

pub export fn fnErfc(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnErfc(unused_but_mandatory_parameter);
}

pub export fn fn2Pow(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fn2Pow(unused_but_mandatory_parameter);
}

pub export fn fn10Pow(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fn10Pow(unused_but_mandatory_parameter);
}

pub export fn fnLog10(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnLog10(unused_but_mandatory_parameter);
}

pub export fn fnLog2(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnLog2(unused_but_mandatory_parameter);
}

pub export fn fnInvert(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnInvert(unused_but_mandatory_parameter);
}

pub export fn fnSign(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnSign(unused_but_mandatory_parameter);
}

pub export fn fnChangeSign(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnChangeSign(unused_but_mandatory_parameter);
}

pub export fn fnSquare(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnSquare(unused_but_mandatory_parameter);
}

pub export fn fnCube(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnCube(unused_but_mandatory_parameter);
}

pub export fn fnBn(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnBn(unused_but_mandatory_parameter);
}

pub export fn fnBnStar(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnBnStar(unused_but_mandatory_parameter);
}

pub export fn fnExpt(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnExpt(unused_but_mandatory_parameter);
}

pub export fn fnWpositive(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnWpositive(unused_but_mandatory_parameter);
}

pub export fn fnWnegative(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnWnegative(unused_but_mandatory_parameter);
}

pub export fn fnWinverse(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnWinverse(unused_but_mandatory_parameter);
}

pub export fn fnGcd(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnGcd(unused_but_mandatory_parameter);
}

pub export fn fnLcm(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnLcm(unused_but_mandatory_parameter);
}

pub export fn fnMod(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnMod(unused_but_mandatory_parameter);
}

pub export fn fnRmd(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnRmd(unused_but_mandatory_parameter);
}

pub export fn fnUlp(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnUlp(unused_but_mandatory_parameter);
}

pub export fn fnMant(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnMant(unused_but_mandatory_parameter);
}

pub export fn fnRoundi(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnRoundi(unused_but_mandatory_parameter);
}

pub export fn fnNeighb(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnNeighb(unused_but_mandatory_parameter);
}

pub export fn fnIxyz(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnIxyz(unused_but_mandatory_parameter);
}

pub export fn fnFactorial(unused_but_mandatory_parameter: u16) callconv(.c) void {
    forward_command_wrappers_owned.fnFactorial(unused_but_mandatory_parameter);
}

pub export fn fnRealPart(unused_but_mandatory_parameter: u16) callconv(.c) void {
    projection_command_wrapper_owned.fnRealPart(unused_but_mandatory_parameter);
}

pub export fn fnImaginaryPart(unused_but_mandatory_parameter: u16) callconv(.c) void {
    projection_command_wrapper_owned.fnImaginaryPart(unused_but_mandatory_parameter);
}

pub export fn fnArg(unused_but_mandatory_parameter: u16) callconv(.c) void {
    projection_command_wrapper_owned.fnArg(unused_but_mandatory_parameter);
}

pub export fn fnMagnitude(unused_but_mandatory_parameter: u16) callconv(.c) void {
    projection_command_wrapper_owned.fnMagnitude(unused_but_mandatory_parameter);
}

pub export fn fnConjugate(unused_but_mandatory_parameter: u16) callconv(.c) void {
    projection_command_wrapper_owned.fnConjugate(unused_but_mandatory_parameter);
}

pub export fn fnSwapRealImaginary(unused_but_mandatory_parameter: u16) callconv(.c) void {
    projection_command_wrapper_owned.fnSwapRealImaginary(unused_but_mandatory_parameter);
}

pub export fn fnAtan2(unused_but_mandatory_parameter: u16) callconv(.c) void {
    arithmetic_command_wrapper_owned.fnAtan2(unused_but_mandatory_parameter);
}

pub export fn fnPercent(unused_but_mandatory_parameter: u16) callconv(.c) void {
    arithmetic_command_wrapper_owned.fnPercent(unused_but_mandatory_parameter);
}

pub export fn fnAdd(unused_but_mandatory_parameter: u16) callconv(.c) void {
    arithmetic_command_wrapper_owned.fnAdd(unused_but_mandatory_parameter);
}

pub export fn fnSubtract(unused_but_mandatory_parameter: u16) callconv(.c) void {
    arithmetic_command_wrapper_owned.fnSubtract(unused_but_mandatory_parameter);
}

pub export fn fnMultiply(unused_but_mandatory_parameter: u16) callconv(.c) void {
    arithmetic_command_wrapper_owned.fnMultiply(unused_but_mandatory_parameter);
}

pub export fn fnDivide(unused_but_mandatory_parameter: u16) callconv(.c) void {
    arithmetic_command_wrapper_owned.fnDivide(unused_but_mandatory_parameter);
}

pub export fn fnIDiv(unused_but_mandatory_parameter: u16) callconv(.c) void {
    arithmetic_command_wrapper_owned.fnIDiv(unused_but_mandatory_parameter);
}

pub export fn fnIDivR(unused_but_mandatory_parameter: u16) callconv(.c) void {
    arithmetic_command_wrapper_owned.fnIDivR(unused_but_mandatory_parameter);
}

pub export fn fnDblMultiply(unused_but_mandatory_parameter: u16) callconv(.c) void {
    arithmetic_command_wrapper_owned.fnDblMultiply(unused_but_mandatory_parameter);
}

pub export fn fnRound(unused_but_mandatory_parameter: u16) callconv(.c) void {
    scalar_integer_inspection_command_owned.fnRound(unused_but_mandatory_parameter);
}

pub export fn fnCheckInteger(mode: u16) callconv(.c) void {
    check_wrapper_owned.fnCheckInteger(mode);
}

pub export fn fnDecomp(unused_but_mandatory_parameter: u16) callconv(.c) void {
    scalar_integer_inspection_command_owned.fnDecomp(unused_but_mandatory_parameter);
}

pub export fn fnDec(unused_but_mandatory_parameter: u16) callconv(.c) void {
    increment_decrement_command_owned.dec(unused_but_mandatory_parameter);
}

pub export fn fnInc(unused_but_mandatory_parameter: u16) callconv(.c) void {
    increment_decrement_command_owned.inc(unused_but_mandatory_parameter);
}

pub export fn fnXLessThan(unused_but_mandatory_parameter: u16) callconv(.c) void {
    compare_wrapper_owned.fnXLessThan(unused_but_mandatory_parameter);
}

pub export fn fnXLessEqual(unused_but_mandatory_parameter: u16) callconv(.c) void {
    compare_wrapper_owned.fnXLessEqual(unused_but_mandatory_parameter);
}

pub export fn fnXGreaterThan(unused_but_mandatory_parameter: u16) callconv(.c) void {
    compare_wrapper_owned.fnXGreaterThan(unused_but_mandatory_parameter);
}

pub export fn fnXGreaterEqual(unused_but_mandatory_parameter: u16) callconv(.c) void {
    compare_wrapper_owned.fnXGreaterEqual(unused_but_mandatory_parameter);
}

pub export fn fnXEqualsTo(unused_but_mandatory_parameter: u16) callconv(.c) void {
    compare_wrapper_owned.fnXEqualsTo(unused_but_mandatory_parameter);
}

pub export fn fnXNotEqual(unused_but_mandatory_parameter: u16) callconv(.c) void {
    compare_wrapper_owned.fnXNotEqual(unused_but_mandatory_parameter);
}

pub export fn fnXAlmostEqual(unused_but_mandatory_parameter: u16) callconv(.c) void {
    compare_wrapper_owned.fnXAlmostEqual(unused_but_mandatory_parameter);
}

pub export fn fnIsConverged(unused_but_mandatory_parameter: u16) callconv(.c) void {
    convergence_owned.isConverged(unused_but_mandatory_parameter);
}

pub export fn fnCheckType(type_: u16) callconv(.c) void {
    check_wrapper_owned.fnCheckType(type_);
}

pub export fn fnCheckReal(unused_but_mandatory_parameter: u16) callconv(.c) void {
    check_wrapper_owned.fnCheckReal(unused_but_mandatory_parameter);
}

pub export fn fnCheckNumber(unused_but_mandatory_parameter: u16) callconv(.c) void {
    check_wrapper_owned.fnCheckNumber(unused_but_mandatory_parameter);
}

pub export fn fnCheckAngle(unused_but_mandatory_parameter: u16) callconv(.c) void {
    check_wrapper_owned.fnCheckAngle(unused_but_mandatory_parameter);
}

pub export fn fnCheckMatrix(unused_but_mandatory_parameter: u16) callconv(.c) void {
    check_wrapper_owned.fnCheckMatrix(unused_but_mandatory_parameter);
}

pub export fn fnCheckMatrixSquare(unused_but_mandatory_parameter: u16) callconv(.c) void {
    check_wrapper_owned.fnCheckMatrixSquare(unused_but_mandatory_parameter);
}

pub export fn fnCheckForZero(mode: u16) callconv(.c) void {
    check_wrapper_owned.fnCheckForZero(mode);
}

pub export fn fnCheckIsVect2d(unused_but_mandatory_parameter: u16) callconv(.c) void {
    check_wrapper_owned.fnCheckIsVect2d(unused_but_mandatory_parameter);
}

pub export fn fnCheckIsVect3d(unused_but_mandatory_parameter: u16) callconv(.c) void {
    check_wrapper_owned.fnCheckIsVect3d(unused_but_mandatory_parameter);
}

pub export fn fnCheckNaN(unused_but_mandatory_parameter: u16) callconv(.c) void {
    check_wrapper_owned.fnCheckNaN(unused_but_mandatory_parameter);
}

pub export fn fnCheckInfinite(unused_but_mandatory_parameter: u16) callconv(.c) void {
    check_wrapper_owned.fnCheckInfinite(unused_but_mandatory_parameter);
}

pub export fn fnCheckSpecial(unused_but_mandatory_parameter: u16) callconv(.c) void {
    check_wrapper_owned.fnCheckSpecial(unused_but_mandatory_parameter);
}

pub export fn fnCheckPlusZero(unused_but_mandatory_parameter: u16) callconv(.c) void {
    check_wrapper_owned.fnCheckPlusZero(unused_but_mandatory_parameter);
}

pub export fn fnCheckMinusZero(unused_but_mandatory_parameter: u16) callconv(.c) void {
    check_wrapper_owned.fnCheckMinusZero(unused_but_mandatory_parameter);
}

pub export fn fnGetType(unused_but_mandatory_parameter: u16) callconv(.c) void {
    check_wrapper_owned.fnGetType(unused_but_mandatory_parameter);
}

pub export fn fnDblDivide(unused_but_mandatory_parameter: u16) callconv(.c) void {
    arithmetic_command_wrapper_owned.fnDblDivide(unused_but_mandatory_parameter);
}

pub export fn fnDblDivideRemainder(unused_but_mandatory_parameter: u16) callconv(.c) void {
    arithmetic_command_wrapper_owned.fnDblDivideRemainder(unused_but_mandatory_parameter);
}

pub export fn fnToPolar2(unused_but_mandatory_parameter: u16) callconv(.c) void {
    tail_command_wrappers_owned.fnToPolar2(unused_but_mandatory_parameter);
}

pub export fn fnToRect2(unused_but_mandatory_parameter: u16) callconv(.c) void {
    tail_command_wrappers_owned.fnToRect2(unused_but_mandatory_parameter);
}

pub export fn fnToRect(unused_but_mandatory_parameter: u16) callconv(.c) void {
    tail_command_wrappers_owned.fnToRect(unused_but_mandatory_parameter);
}

pub export fn fnParallel(unused_but_mandatory_parameter: u16) callconv(.c) void {
    tail_command_wrappers_owned.fnParallel(unused_but_mandatory_parameter);
}

pub export fn fnUnitVector(unused_but_mandatory_parameter: u16) callconv(.c) void {
    tail_command_wrappers_owned.fnUnitVector(unused_but_mandatory_parameter);
}

pub export fn fnSdl(unused_but_mandatory_parameter: u16) callconv(.c) void {
    tail_command_wrappers_owned.fnSdl(unused_but_mandatory_parameter);
}

pub export fn fnSdr(unused_but_mandatory_parameter: u16) callconv(.c) void {
    tail_command_wrappers_owned.fnSdr(unused_but_mandatory_parameter);
}

pub export fn fnSquareRoot(unused_but_mandatory_parameter: u16) callconv(.c) void {
    tail_command_wrappers_owned.fnSquareRoot(unused_but_mandatory_parameter);
}

pub export fn fnCubeRoot(unused_but_mandatory_parameter: u16) callconv(.c) void {
    tail_command_wrappers_owned.fnCubeRoot(unused_but_mandatory_parameter);
}

pub export fn fnPercentMRR(unused_but_mandatory_parameter: u16) callconv(.c) void {
    tail_command_wrappers_owned.fnPercentMRR(unused_but_mandatory_parameter);
}

pub export fn fnPercentPlusMG(unused_but_mandatory_parameter: u16) callconv(.c) void {
    tail_command_wrappers_owned.fnPercentPlusMG(unused_but_mandatory_parameter);
}

pub export fn fnPercentT(unused_but_mandatory_parameter: u16) callconv(.c) void {
    tail_command_wrappers_owned.fnPercentT(unused_but_mandatory_parameter);
}

pub export fn fnDeltaPercent(unused_but_mandatory_parameter: u16) callconv(.c) void {
    tail_command_wrappers_owned.fnDeltaPercent(unused_but_mandatory_parameter);
}

pub export fn fnFib(unused_but_mandatory_parameter: u16) callconv(.c) void {
    tail_command_wrappers_owned.fnFib(unused_but_mandatory_parameter);
}

pub export fn fnLINPOL(unused_but_mandatory_parameter: u16) callconv(.c) void {
    tail_command_wrappers_owned.fnLINPOL(unused_but_mandatory_parameter);
}

pub export fn fnCross(unused_but_mandatory_parameter: u16) callconv(.c) void {
    tail_command_wrappers_owned.fnCross(unused_but_mandatory_parameter);
}
pub export fn fnDot(unused_but_mandatory_parameter: u16) callconv(.c) void {
    tail_command_wrappers_owned.fnDot(unused_but_mandatory_parameter);
}

pub export fn fnLogXY(unused_but_mandatory_parameter: u16) callconv(.c) void {
    tail_command_wrappers_owned.fnLogXY(unused_but_mandatory_parameter);
}
