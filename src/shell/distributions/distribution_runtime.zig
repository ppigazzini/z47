// SPDX-License-Identifier: GPL-3.0-only
//
// Shared decNumber/register surface for the ported statistical-distribution
// commands (cauchy, weibull, logistic, ...). Frontier has no parity harness, so
// these bind straight to the c47-core symbols present in the product, test, and
// firmware links. Each distribution owner ports its upstream
// src/c47/distributions/<name>.c using only this module.

const builtin = @import("builtin");
const frontier_build_options = @import("frontier_build_options");
// Upstream compiles the EXTRA_INFO_ON_CALC_ERROR console hints out on firmware;
// gate moreInfoOnError on the same flag so firmware sheds the calls and strings.
const extra_info_on_calc_error: bool = frontier_build_options.extra_info_on_calc_error;

// Distribution commands are user-triggered and never hot, so on the flash-limited
// old_hw DM42 their code lives in the executable QSPI region (XIP) to free the
// 704 KB main FLASH. Host and DMCP5 keep the normal code section (mach-o needs a
// SEG,sect form). Owners tag their fn declarations `linksection(dr.code_section)`.
pub const code_section = if (frontier_build_options.dmcp_build and frontier_build_options.old_hw)
    ".qspi_data"
else if (builtin.target.os.tag == .macos)
    "__TEXT,__text"
else
    ".text";

const DECNUMUNITS = 25;

const DECNEG: u8 = 0x80;
const DECNAN: u8 = 0x20;
const DECSNAN: u8 = 0x10;
const DECINF: u8 = 0x40;
const DECSPECIAL: u8 = 0x70;

pub const calcRegister_t = i16;
pub const angularMode_t = c_int;
const rounding_t = c_int;

pub const REGISTER_X: calcRegister_t = 100;
pub const REGISTER_Z: calcRegister_t = 102;
pub const REGISTER_M: calcRegister_t = 112;
pub const REGISTER_N: calcRegister_t = 113;
pub const REGISTER_P: calcRegister_t = 114;
pub const REGISTER_Q: calcRegister_t = 115;
pub const REGISTER_R: calcRegister_t = 116;
pub const REGISTER_S: calcRegister_t = 117;
pub const ERR_REGISTER_LINE: calcRegister_t = REGISTER_Z;
pub const amNone: angularMode_t = 5;

pub const FLAG_SPCRES: i32 = 0x8017;

// decContext rounding modes (dep/decNumberICU/decContext.h enum order).
pub const DEC_ROUND_CEILING: c_int = 0;
pub const DEC_ROUND_FLOOR: c_int = 6;
pub const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN: u8 = 1;
pub const ERROR_INVALID_DATA_TYPE_FOR_OP: u8 = 24;
pub const ERROR_INVALID_DISTRIBUTION_PARAM: u8 = 16;
pub const ERROR_NO_ROOT_FOUND: u8 = 20;

const abi = @import("abi"); // shared ABI bindings
const frontier_real_type = @import("../real_type.zig");
const frontier_register_value_conversions = @import("../register_value_conversions.zig");
pub const real_t = abi.Real;

pub const realContext_t = abi.RealContext;

pub extern var ctxtReal39: realContext_t;
pub extern var ctxtReal51: realContext_t;
pub extern var ctxtReal75: realContext_t;
extern var const_NaN: *const real_t;

extern fn z47_math_wrappers_const_0() *const real_t;
extern fn z47_math_wrappers_const_1() *const real_t;
extern fn z47_math_wrappers_const_1on2() *const real_t;
extern fn z47_math_wrappers_const_pi() *const real_t;
extern fn z47_math_wrappers_const_2() *const real_t;
extern fn z47_math_wrappers_const_ln2() *const real_t;
extern fn z47_math_wrappers_const_5() *const real_t;
extern fn z47_math_wrappers_const_1on3() *const real_t;
extern fn z47_math_wrappers_const_minus_infinity() *const real_t;

extern fn decNumberMultiply(result: *real_t, lhs: *const real_t, rhs: *const real_t, real_context: *realContext_t) *real_t;
extern fn decNumberDivide(result: *real_t, lhs: *const real_t, rhs: *const real_t, real_context: *realContext_t) *real_t;
extern fn decNumberAdd(result: *real_t, lhs: *const real_t, rhs: *const real_t, real_context: *realContext_t) *real_t;
extern fn decNumberSubtract(result: *real_t, lhs: *const real_t, rhs: *const real_t, real_context: *realContext_t) *real_t;
extern fn decNumberMinus(result: *real_t, rhs: *const real_t, real_context: *realContext_t) *real_t;
extern fn decNumberCopy(result: *real_t, rhs: *const real_t) *real_t;
extern fn decNumberFromUInt32(result: *real_t, rhs: u32) *real_t;
extern fn decNumberFromInt32(result: *real_t, rhs: i32) *real_t;
extern fn decNumberSquareRoot(result: *real_t, rhs: *const real_t, real_context: *realContext_t) *real_t;
extern fn decNumberCopyAbs(result: *real_t, rhs: *const real_t) *real_t;
extern fn decNumberFMA(result: *real_t, factor1: *const real_t, factor2: *const real_t, term: *const real_t, real_context: *realContext_t) *real_t;
extern fn PowerReal(y: *const real_t, x: *const real_t, result: *real_t, real_context: *realContext_t) void;

extern fn realPower(base: *const real_t, exponent: *const real_t, result: *real_t, real_context: *realContext_t) void;
extern fn realExp(x: *const real_t, res: *real_t, real_context: *realContext_t) void;

extern fn realCompareEqual(number1: *const real_t, number2: *const real_t) bool;
extern fn realCompareLessThan(number1: *const real_t, number2: *const real_t) bool;
extern fn realCompareGreaterThan(number1: *const real_t, number2: *const real_t) bool;

extern fn realIsAnInteger(value: *const real_t) bool;

extern fn linpol(a: *const real_t, b: *const real_t, p: *const real_t, res: *real_t) void;

pub extern fn C47_WP34S_Atan(x: *const real_t, angle: *real_t, real_context: *realContext_t) void;
pub extern fn C47_WP34S_SinCosTanTaylor(angle: *const real_t, swap: bool, sin_out: ?*real_t, cos_out: ?*real_t, tan_out: ?*real_t, real_context: *realContext_t) void;
pub extern fn WP34S_ExpM1(x: *const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn WP34S_Ln1P(x: *const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn WP34S_Ln(x: *const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn WP34S_Tanh(x: *const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn WP34S_ArcTanh(x: *const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn WP34S_SinhCosh(x: *const real_t, sinh_out: ?*real_t, cosh_out: ?*real_t, real_context: *realContext_t) void;

// Other discrete CDFs reached through the shared qf_discrete_final dispatcher
// (geometric owner); these remain in C as parity oracles, present wherever the
// SAVE_SPACE_DM42_17 cluster is kept (host, DMCP5).
pub extern fn WP34S_Cdf_Poisson2(x: *const real_t, lambda: *const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn WP34S_Cdf_Binomial2(x: *const real_t, p0: *const real_t, n: *const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn cdf_NegBinomial2(x: *const real_t, p0: *const real_t, r: *const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn cdf_Hypergeometric2(x: *const real_t, p0: *const real_t, n: *const real_t, n0: *const real_t, res: *real_t, real_context: *realContext_t) void;
// Discrete PDFs + the shared discrete-quantile dispatcher reached by the f
// distribution's Newton solver (all exported by their Zig owners from frontier.zig).
pub extern fn WP34S_Pdf_Poisson(x: *const real_t, lambda: *const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn WP34S_Pdf_Binomial(x: *const real_t, p0: *const real_t, n: *const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn pdf_NegBinomial(x: *const real_t, p0: *const real_t, r: *const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn pdf_Hypergeometric(x: *const real_t, k0: *const real_t, n: *const real_t, n0: *const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn WP34S_qf_discrete_final(dist: u16, r: *const real_t, p: *const real_t, i: [*c]const real_t, j: [*c]const real_t, k: [*c]const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn LnBeta(x: *const real_t, y: *const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn WP34S_LnGamma(x: *const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn WP34S_qf_q_est(x: *const real_t, res: *real_t, res_y: ?*real_t, real_context: *realContext_t) void;
pub extern fn WP34S_GammaP(x: *const real_t, a: *const real_t, res: *real_t, real_context: *realContext_t, upper: bool, regularised: bool) void;
pub extern fn WP34S_Qf_Newton(r_dist: u32, target: *const real_t, estimate: *const real_t, p1: [*c]const real_t, p2: [*c]const real_t, p3: [*c]const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn WP34S_betai(b: *const real_t, a: *const real_t, x: *const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn logCyxReal(y: *real_t, x: *real_t, result: *real_t, real_context: *realContext_t) void;
pub extern fn checkRegisterNoFP(reg: *const real_t) bool;
pub extern fn WP34S_RelativeError(x: *const real_t, y: *const real_t, tol: *const real_t, real_context: *realContext_t) bool;
pub extern fn roundToSignificantDigits(source: *const real_t, destination: *real_t, digits: u16, real_context: *realContext_t) void;
// Provided by the poisson owner (exported from frontier.zig); reached here by the
// binomial/hyper/negBinom quantiles where the cluster is kept.
pub extern fn WP34S_normal_moment_approx(prob: *const real_t, variance: *const real_t, mean: *const real_t, res: *real_t, real_context: *realContext_t) void;

pub extern fn saveLastX() bool;
pub extern fn getRegisterAsReal(reg: calcRegister_t, value: *real_t) bool;
pub extern fn convertRealToResultRegister(real: *const real_t, dest: calcRegister_t, angle_mode: angularMode_t) void;
pub extern fn adjustResult(res: calcRegister_t, drop_y: bool, set_cpx_res: bool, op1: calcRegister_t, op2: calcRegister_t, op3: calcRegister_t) void;
pub extern fn displayDomainErrorMessage(error_code: u8, err_message_register_line: calcRegister_t, err_register_line: calcRegister_t) void;
const c_moreInfoOnError = @extern(*const fn (msg1: [*:0]const u8, msg2: ?[*:0]const u8, msg3: ?[*:0]const u8, msg4: ?[*:0]const u8) callconv(.c) void, .{ .name = "moreInfoOnError" });
pub inline fn moreInfoOnError(msg1: [*:0]const u8, msg2: ?[*:0]const u8, msg3: ?[*:0]const u8, msg4: ?[*:0]const u8) void {
    if (comptime extra_info_on_calc_error) c_moreInfoOnError(msg1, msg2, msg3, msg4);
}
pub extern fn getSystemFlag(flag: i32) bool;

pub inline fn realMultiply(lhs: *const real_t, rhs: *const real_t, result: *real_t, real_context: *realContext_t) void {
    _ = decNumberMultiply(result, lhs, rhs, real_context);
}
pub inline fn realDivide(lhs: *const real_t, rhs: *const real_t, result: *real_t, real_context: *realContext_t) void {
    _ = decNumberDivide(result, lhs, rhs, real_context);
}
pub inline fn realAdd(lhs: *const real_t, rhs: *const real_t, result: *real_t, real_context: *realContext_t) void {
    _ = decNumberAdd(result, lhs, rhs, real_context);
}
pub inline fn realSubtract(lhs: *const real_t, rhs: *const real_t, result: *real_t, real_context: *realContext_t) void {
    _ = decNumberSubtract(result, lhs, rhs, real_context);
}
pub inline fn realMinus(operand: *const real_t, result: *real_t, real_context: *realContext_t) void {
    _ = decNumberMinus(result, operand, real_context);
}
pub inline fn realCopy(source: *const real_t, destination: *real_t) void {
    _ = decNumberCopy(destination, source);
}
pub inline fn realPow(base: *const real_t, exponent: *const real_t, result: *real_t, real_context: *realContext_t) void {
    realPower(base, exponent, result, real_context);
}
pub inline fn realExponential(x: *const real_t, res: *real_t, real_context: *realContext_t) void {
    realExp(x, res, real_context);
}
pub inline fn realSquareRoot(operand: *const real_t, res: *real_t, real_context: *realContext_t) void {
    _ = decNumberSquareRoot(res, operand, real_context);
}
pub inline fn int32ToReal(source: i32, destination: *real_t) void {
    _ = decNumberFromInt32(destination, source);
}
pub inline fn realCopyAbs(source: *const real_t, destination: *real_t) void {
    _ = decNumberCopyAbs(destination, source);
}
pub inline fn realSetPositiveSign(operand: *real_t) void {
    operand.bits &= 0x7f;
}
pub inline fn realSetNegativeSign(operand: *real_t) void {
    operand.bits |= 0x80;
}
pub inline fn realExpM1(x: *const real_t, res: *real_t, real_context: *realContext_t) void {
    WP34S_ExpM1(x, res, real_context); // c47 realExpM1 forwards straight to WP34S_ExpM1
}
pub inline fn realFMA(factor1: *const real_t, factor2: *const real_t, term: *const real_t, result: *real_t, real_context: *realContext_t) void {
    _ = decNumberFMA(result, factor1, factor2, term, real_context); // result = factor1*factor2 + term
}
pub inline fn powerReal(y: *const real_t, x: *const real_t, result: *real_t, real_context: *realContext_t) void {
    PowerReal(y, x, result, real_context);
}
pub inline fn setZero(value: *real_t) void {
    frontier_real_type.realSetZero(value);
}
pub inline fn setOne(value: *real_t) void {
    frontier_real_type.realSetOne(value);
}
pub inline fn setPlusInfinity(value: *real_t) void {
    frontier_real_type.realSetPlusInfinity(value);
}
pub inline fn setNaN(value: *real_t) void {
    frontier_real_type.realSetNaN(value);
}

pub inline fn realIsSpecial(value: *const real_t) bool {
    return (value.bits & DECSPECIAL) != 0;
}
pub inline fn realIsNaN(value: *const real_t) bool {
    return (value.bits & (DECNAN | DECSNAN)) != 0;
}
pub inline fn realIsNegative(value: *const real_t) bool {
    return (value.bits & DECNEG) != 0;
}
pub inline fn realIsZero(value: *const real_t) bool {
    return value.digits == 1 and value.lsu[0] == 0 and !realIsSpecial(value);
}
pub inline fn realIsInfinite(value: *const real_t) bool {
    return (value.bits & DECINF) != 0;
}
pub inline fn realIsPositive(value: *const real_t) bool {
    return (value.bits & DECNEG) == 0; // upstream realIsPositive: sign bit clear
}
pub inline fn realChangeSign(value: *real_t) void {
    value.bits ^= 0x80;
}
pub inline fn realLessThan(lhs: *const real_t, rhs: *const real_t) bool {
    return realCompareLessThan(lhs, rhs);
}
pub inline fn realEqual(lhs: *const real_t, rhs: *const real_t) bool {
    return realCompareEqual(lhs, rhs);
}
pub inline fn realGreaterThan(lhs: *const real_t, rhs: *const real_t) bool {
    return realCompareGreaterThan(lhs, rhs);
}
pub inline fn isAnInteger(value: *const real_t) bool {
    return realIsAnInteger(value);
}
pub inline fn toIntegralValue(source: *const real_t, destination: *real_t, mode: c_int, real_context: *realContext_t) void {
    frontier_register_value_conversions.realToIntegralValue(source, destination, mode, real_context);
}
pub inline fn linearInterpolate(a: *const real_t, b: *const real_t, p: *const real_t, res: *real_t) void {
    linpol(a, b, p, res);
}
pub inline fn realCompareLessEqual(lhs: *const real_t, rhs: *const real_t) bool {
    return realCompareLessThan(lhs, rhs) or realCompareEqual(lhs, rhs);
}
pub inline fn realCompareGreaterEqual(lhs: *const real_t, rhs: *const real_t) bool {
    // Faithful to C realCompareGreaterEqual = isPositive || isZero (FALSE for NaN).
    // `!realCompareLessThan` would wrongly return true for NaN operands.
    return realCompareGreaterThan(lhs, rhs) or realCompareEqual(lhs, rhs);
}

pub fn const0() *const real_t {
    return z47_math_wrappers_const_0();
}
pub fn const1() *const real_t {
    return z47_math_wrappers_const_1();
}
pub fn const1on2() *const real_t {
    return z47_math_wrappers_const_1on2();
}
pub fn const39Pi() *const real_t {
    return z47_math_wrappers_const_pi();
}
pub fn constNaN() *const real_t {
    return const_NaN;
}

pub fn const4() *const real_t {
    return abi.constants.const_4();
}

pub fn const6() *const real_t {
    return abi.constants.const_6();
}

pub fn const2() *const real_t {
    return z47_math_wrappers_const_2();
}

pub fn const5() *const real_t {
    return z47_math_wrappers_const_5();
}

pub fn const1on10() *const real_t {
    return abi.constants.const_1on10();
}

// 2*pi at 39-digit precision; materialised once from pi.
pub fn const39_2pi() *const real_t {
    return abi.constants.const39_2pi();
}

pub fn const1on3() *const real_t {
    return z47_math_wrappers_const_1on3();
}
pub fn constMinusInfinity() *const real_t {
    return z47_math_wrappers_const_minus_infinity();
}

pub fn const3() *const real_t {
    return abi.constants.const_3();
}

pub fn const3on2() *const real_t {
    return abi.constants.const_3on2();
}

pub fn const60() *const real_t {
    return abi.constants.const_60();
}

pub fn const1e_37() *const real_t {
    return abi.constants.const_1e_37();
}

pub fn constLn2() *const real_t {
    return z47_math_wrappers_const_ln2();
}

pub fn const1on4() *const real_t {
    return abi.constants.const_1on4();
}

pub fn const8() *const real_t {
    return abi.constants.const_8();
}

pub fn const7() *const real_t {
    return abi.constants.const_7();
}

pub fn constEE() *const real_t {
    return abi.constants.const39_eE();
}

// Shared NaN-on-FLAG_SPCRES error tail used by every checkParam* helper.
pub fn specialResultNaN() void {
    if (getSystemFlag(FLAG_SPCRES)) {
        convertRealToResultRegister(const_NaN, REGISTER_X, amNone);
    }
}

// Shared "result -> X with adjustResult" tail used by every fn* entry point.
pub fn storeResult(ans: *const real_t) void {
    convertRealToResultRegister(ans, REGISTER_X, amNone);
    adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
}
