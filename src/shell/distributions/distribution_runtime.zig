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

const DECNEG: u8 = 0x80;
const DECNAN: u8 = 0x20;
const DECSNAN: u8 = 0x10;
const DECINF: u8 = 0x40;
const DECSPECIAL: u8 = 0x70;

pub const calcRegister_t = i16;
pub const angularMode_t = c_int;

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
pub const DEC_ROUND_UP: c_int = 1;
pub const DEC_ROUND_HALF_UP: c_int = 2;
pub const DEC_ROUND_HALF_EVEN: c_int = 3;
pub const DEC_ROUND_HALF_DOWN: c_int = 4;
pub const DEC_ROUND_DOWN: c_int = 5;
pub const DEC_ROUND_FLOOR: c_int = 6;

// THE DISTRIBUTION GATES: one OPTION_DIST_* per distribution file. Each owner
// reads its own, as its upstream file does; frontier.zig exports an owner's
// entry points only while its gate is on, which is upstream's `#if !defined`
// stub pair.
pub const option_dist_norml: bool = frontier_build_options.option_dist_norml;
pub const option_dist_t: bool = frontier_build_options.option_dist_t;
pub const option_dist_logis: bool = frontier_build_options.option_dist_logis;
pub const option_dist_cauch: bool = frontier_build_options.option_dist_cauch;
pub const option_dist_weibl: bool = frontier_build_options.option_dist_weibl;
pub const option_dist_expon: bool = frontier_build_options.option_dist_expon;
pub const option_dist_chi2: bool = frontier_build_options.option_dist_chi2;
pub const option_dist_binom: bool = frontier_build_options.option_dist_binom;
pub const option_dist_f: bool = frontier_build_options.option_dist_f;
pub const option_dist_geom: bool = frontier_build_options.option_dist_geom;
pub const option_dist_hyper: bool = frontier_build_options.option_dist_hyper;
pub const option_dist_nbin: bool = frontier_build_options.option_dist_nbin;
pub const option_dist_poiss: bool = frontier_build_options.option_dist_poiss;
pub const option_dist_prto: bool = frontier_build_options.option_dist_prto;
pub const option_dist_gev: bool = frontier_build_options.option_dist_gev;
pub const option_dist_unfm: bool = frontier_build_options.option_dist_unfm;

// fnDistribution (wp34s.c): param names the descriptor row and which of the four
// entries it is, row * 4 + entry.
pub const DIST_P: u16 = 0;
pub const DIST_L: u16 = 1;
pub const DIST_R: u16 = 2;
pub const DIST_I: u16 = 3;
pub const DIST_EXPON: u16 = 0;
pub const DIST_CAUCHY: u16 = 1;
pub const DIST_LOGIT: u16 = 2;
pub const DIST_WEIB: u16 = 3;
pub const DIST_BINOM: u16 = 4;
pub const DIST_GEOM: u16 = 5;
pub const DIST_POISSON: u16 = 6;
pub const DIST_NEGBINOM: u16 = 7;
pub const DIST_CHI2: u16 = 8;
pub const DIST_T: u16 = 9;
pub const DIST_F: u16 = 10;

// The discrete quantile solvers' distribution selectors (defines.h).
pub const QF_NEWTON_F: u32 = 0;
pub const QF_NEWTON_POISSON: u32 = 1;
pub const QF_NEWTON_BINOMIAL: u32 = 2;
pub const QF_NEWTON_GEOMETRIC: u32 = 3;
pub const QF_NEWTON_NEGBINOM: u32 = 4;
pub const QF_NEWTON_HYPERGEOMETRIC: u32 = 5;
pub const QF_DISCRETE_CDF_POISSON: u16 = 0;
pub const QF_DISCRETE_CDF_BINOMIAL: u16 = 1;
pub const QF_DISCRETE_CDF_GEOMETRIC: u16 = 2;
pub const QF_DISCRETE_CDF_NEGBINOM: u16 = 3;
pub const QF_DISCRETE_CDF_HYPERGEOMETRIC: u16 = 4;

/// wp34sDistributionDomainRule_t: a distribution's own check of the registers
/// WP34S_CheckDistributionParameters read, called with registersValid false when a
/// register did not hold a real.
pub const DomainRule = *const fn (registers_valid: bool, x: *real_t, first: ?*real_t, second: ?*real_t, third: ?*real_t, parameter: u16) callconv(.c) bool;
pub const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN: u8 = 1;
pub const ERROR_INVALID_DATA_TYPE_FOR_OP: u8 = 24;
pub const ERROR_INVALID_DISTRIBUTION_PARAM: u8 = 16;
pub const ERROR_NO_ROOT_FOUND: u8 = 20;

const abi = @import("abi"); // shared ABI bindings
// Declared here rather than imported from ../real_type.zig and
// ../register_value_conversions.zig, which also declare them. Both spellings give
// the same symbol and the same link-time resolution, but an @import binds this
// file to the other file's whole import closure, and register_value_conversions
// reaches the display tree. That closure forces any module containing this file
// to be rooted at src/, which the distribution parity harness is not. Keep new C
// entry points declared here for the same reason.
extern fn realSetZero(r: *real_t) callconv(.c) void;
extern fn realSetOne(r: *real_t) callconv(.c) void;
extern fn realSetNaN(r: *real_t) callconv(.c) void;
extern fn realSetPlusInfinity(r: *real_t) callconv(.c) void;
extern fn realToIntegralValue(source: *const real_t, destination: *real_t, mode: c_int, realContext: *realContext_t) callconv(.c) void;
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
// OPTION_DIST_C cluster is kept (host, DMCP5).
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

// The entry points wp34s.c added for the distributions: the shared dispatcher,
// the parameter loader and the probability helpers every kernel marks its
// results with.
pub extern fn fnDistribution(param: u16) void;
pub extern fn WP34S_CheckDistributionParameters(x: *real_t, first_register: calcRegister_t, first: ?*real_t, second_register: calcRegister_t, second: ?*real_t, third_register: calcRegister_t, third: ?*real_t, parameter: u16, domain_rule: DomainRule) bool;
pub extern fn WP34S_IsPositiveFinite(value: *const real_t) bool;
pub extern fn WP34S_AtLeastContext(real_context: *realContext_t, fallback_context: *realContext_t) *realContext_t;
pub extern fn WP34S_BetaCalculationContext(a: *const real_t, b: *const real_t) *realContext_t;
pub extern fn WP34S_SetPowerOfTen(exponent: i32, res: *real_t) void;
pub extern fn WP34S_MarkProbability(value: *real_t, real_context: *realContext_t) void;
pub extern fn WP34S_MarkPositive(value: *real_t, real_context: *realContext_t) void;
pub extern fn WP34S_HasCancellation(left: *const real_t, right: *const real_t, result: *const real_t, places: i32) bool;
pub extern fn WP34S_DistributionProbabilityData(probability: *const real_t, complement: *real_t, log_probability: *real_t, log_complement: *real_t, logit: *real_t, real_context: *realContext_t) void;
pub extern fn WP34S_AdjustPositiveUnderflow(value: *real_t) void;
pub extern fn WP34S_Log1pMinus(value: *const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn WP34S_LnExtended(x: *const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn WP34S_BetaFraction(a: *const real_t, b: *const real_t, x: *const real_t, convergence_exponent: i32, iteration_max: i32, res: *real_t, real_context: *realContext_t) bool;
pub extern fn WP34S_LanczosSum(x: *const real_t, offset: *const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn WP34S_Zeta(x: *const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn WP34S_Erf(x: *const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn WP34S_Erfc(x: *const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn C47_LnBetaPositiveReal(x: *const real_t, y: *const real_t, res: *real_t) void;
// The normal owner's kernels, reached by the t, chi2, poisson, f and hyper owners
// where their gates are on; exported from frontier.zig.
pub extern fn WP34S_Pdf_Q(x: *const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn WP34S_Cdf_Q(x: *const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn WP34S_Cdfu_Q(x: *const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn WP34S_Qf_Q(x: *const real_t, res: *real_t, real_context: *realContext_t) void;
// The beta-pair routines the f owner defines and the binomial and negative
// binomial owners read.
pub extern fn distributionLogBetaPrefix(a: *const real_t, b: *const real_t, y: *const real_t, z: *const real_t, logit: *const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn distributionBetaPair(a: *const real_t, b: *const real_t, y: *const real_t, z: *const real_t, logit: *const real_t, lower: *real_t, upper: *real_t, real_context: *realContext_t) bool;
pub extern fn WP34S_Cdf_Geom(x: *const real_t, p0: *const real_t, res: *real_t, real_context: *realContext_t) void;
// comparisonReals.c's magnitude comparisons.
pub extern fn realCompareAbsLessThan(number1: *const real_t, number2: *const real_t) bool;
pub extern fn realCompareAbsGreaterThan(number1: *const real_t, number2: *const real_t) bool;
pub extern fn realCompareAbsEqual(number1: *const real_t, number2: *const real_t) bool;
extern fn decNumberNextToward(result: *real_t, from: *const real_t, toward: *const real_t, real_context: *realContext_t) *real_t;
extern fn decNumberPlus(result: *real_t, rhs: *const real_t, real_context: *realContext_t) *real_t;
// The rounding mode the hypergeometric owner's underflow adjustment follows.
pub extern var roundingMode: u8;
pub extern const roundingModeTable: [7]c_int;

pub extern fn saveLastX() bool;
pub extern fn getRegisterAsReal(reg: calcRegister_t, value: *real_t) bool;
pub extern fn convertRealToResultRegister(real: *const real_t, dest: calcRegister_t, angle_mode: angularMode_t) void;
pub extern fn adjustResult(res: calcRegister_t, drop_y: bool, set_cpx_res: bool, op1: calcRegister_t, op2: calcRegister_t, op3: calcRegister_t) void;
pub extern fn displayDomainErrorMessage(error_code: u8, err_message_register_line: calcRegister_t) void;
const c_moreInfoOnError = @extern(*const fn (msg1: [*:0]const u8, msg2: ?[*:0]const u8, msg3: ?[*:0]const u8, msg4: ?[*:0]const u8) callconv(.c) void, .{ .name = "moreInfoOnError" });
pub inline fn moreInfoOnError(msg1: [*:0]const u8, msg2: ?[*:0]const u8, msg3: ?[*:0]const u8, msg4: ?[*:0]const u8) void {
    if (comptime extra_info_on_calc_error) c_moreInfoOnError(msg1, msg2, msg3, msg4);
}

extern var errorMessage: [*c]u8;

/// Stage a diagnostic in the shared errorMessage scratch buffer and yield a
/// pointer to it, the way a `sprintf(errorMessage, text)` immediately before the
/// hint call leaves the buffer. Compiled out with the hints themselves.
pub inline fn stagedMessage(comptime text: [:0]const u8) [*:0]const u8 {
    if (comptime !extra_info_on_calc_error) return text.ptr;
    @memcpy(errorMessage[0..text.len], text);
    errorMessage[text.len] = 0;
    return errorMessage;
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
pub inline fn realNextToward(x: *const real_t, toward: *const real_t, result: *real_t, real_context: *realContext_t) void {
    _ = decNumberNextToward(result, x, toward, real_context);
}
/// realPlus: the value rounded to the context, which is how a wide working real
/// is shortened into a result.
pub inline fn realPlus(operand: *const real_t, result: *real_t, real_context: *realContext_t) void {
    _ = decNumberPlus(result, operand, real_context);
}

/// REAL_T_PTR(name, 159): the 159-digit working real the extended quantile and
/// density paths take off the frame, viewed as a real_t through `ptr`. A
/// context-sized working real (REAL_T_PTR(name, realContext->digits)) is one of
/// these too, since 159 is the widest context the distributions work at.
pub const Real159 = abi.Real159;
pub inline fn powerReal(y: *const real_t, x: *const real_t, result: *real_t, real_context: *realContext_t) void {
    PowerReal(y, x, result, real_context);
}
pub inline fn setZero(value: *real_t) void {
    realSetZero(value);
}
pub inline fn setOne(value: *real_t) void {
    realSetOne(value);
}
pub inline fn setPlusInfinity(value: *real_t) void {
    realSetPlusInfinity(value);
}
pub inline fn setNaN(value: *real_t) void {
    realSetNaN(value);
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
pub const realIsZero = abi.realIsZero;
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
    realToIntegralValue(source, destination, mode, real_context);
}
pub inline fn linearInterpolate(a: *const real_t, b: *const real_t, p: *const real_t, res: *real_t) void {
    linpol(a, b, p, res);
}
// comparisonReals.c's own functions, not re-derived from LessThan and Equal.
// Each is a sign-bit test on the result of decNumberCompare, so a NaN operand
// makes GreaterEqual and GreaterThan answer TRUE and LessEqual and LessThan
// answer FALSE -- the opposite of what rebuilding them from Equal produces.
pub extern fn realCompareLessEqual(number1: *const real_t, number2: *const real_t) bool;
pub extern fn realCompareGreaterEqual(number1: *const real_t, number2: *const real_t) bool;

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

pub fn const10() *const real_t {
    return abi.constants.const_10();
}

pub fn const100() *const real_t {
    return abi.constants.const_100();
}

pub fn const1000() *const real_t {
    return abi.constants.const_1000();
}

pub fn const10000() *const real_t {
    return abi.constants.const_10000();
}

pub fn const180() *const real_t {
    return abi.constants.const_180();
}

pub fn const205() *const real_t {
    return abi.constants.const_205();
}

pub fn const29() *const real_t {
    return abi.constants.const_29();
}

pub fn const3on4() *const real_t {
    return abi.constants.const_3on4();
}

pub fn const1e_6() *const real_t {
    return abi.constants.const_1e_6();
}

pub fn const1e_12() *const real_t {
    return abi.constants.const_1e_12();
}

pub fn const1e_10000() *const real_t {
    return abi.constants.const_1e_10000();
}

pub fn constGammaR() *const real_t {
    return abi.constants.const_gammaR();
}

pub fn constGammaRm1() *const real_t {
    return abi.constants.const_gammaRm1();
}

pub fn constMinusGammaRm1() *const real_t {
    return abi.constants.const__gammaRm1();
}

pub fn constPlusInfinity() *const real_t {
    return abi.constants.const_plusInfinity();
}

pub fn const39Root2on2() *const real_t {
    return abi.constants.const39_root2on2();
}

pub fn const75Pi() *const real_t {
    return abi.constants.const75_pi();
}

pub fn const75PiOn2() *const real_t {
    return abi.constants.const75_piOn2();
}

pub fn const75Ln2() *const real_t {
    return abi.constants.const75_ln2();
}

pub fn const75Ln10() *const real_t {
    return abi.constants.const75_ln10();
}

pub fn const75TwoPi() *const real_t {
    return abi.constants.const75_2pi();
}

pub fn const2139TwoPi() *const real_t {
    return abi.constants.const2139_2pi();
}

pub fn const1071Pi() *const real_t {
    return abi.constants.const1071_pi();
}

pub fn const51TwoLn2() *const real_t {
    return abi.constants.const51_twoLn2();
}

pub fn const51Zeta2() *const real_t {
    return abi.constants.const51_zeta2();
}

pub fn const51SevenZeta2SqOn5() *const real_t {
    return abi.constants.const51_7zeta2SqOn5();
}

pub fn const51OneOn3() *const real_t {
    return abi.constants.const51_1on3();
}

/// The pi of the context: 75 digits above a 39-digit context, 39 otherwise.
pub fn piForContext(real_context: *const realContext_t) *const real_t {
    return if (real_context.digits > 39) const75Pi() else const39Pi();
}

/// The 2 pi of the context: 2139 digits above 75, 75 above 39, 39 otherwise.
pub fn twoPiForContext(real_context: *const realContext_t) *const real_t {
    return if (real_context.digits > 75) const2139TwoPi() else if (real_context.digits > 39) const75TwoPi() else const39_2pi();
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
