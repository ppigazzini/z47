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
    ".qspi"
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
pub const ERROR_INVALID_DISTRIBUTION_PARAM: u8 = 16;
pub const ERROR_NO_ROOT_FOUND: u8 = 20;

pub const real_t = extern struct {
    digits: i32,
    exponent: i32,
    bits: u8,
    lsu: [DECNUMUNITS]u16,
};

pub const realContext_t = extern struct {
    digits: i32,
    emax: i32,
    emin: i32,
    round: rounding_t,
    traps: u32,
    status: u32,
    clamp: u8,
};

pub extern var ctxtReal39: realContext_t;
pub extern var ctxtReal51: realContext_t;
pub extern var ctxtReal75: realContext_t;
extern var const_NaN: *const real_t;

extern fn z47_math_wrappers_const_0() *const real_t;
extern fn z47_math_wrappers_const_1() *const real_t;
extern fn z47_math_wrappers_const_1on2() *const real_t;
extern fn z47_math_wrappers_const_pi() *const real_t;

extern fn decNumberMultiply(result: *real_t, lhs: *const real_t, rhs: *const real_t, real_context: *realContext_t) *real_t;
extern fn decNumberDivide(result: *real_t, lhs: *const real_t, rhs: *const real_t, real_context: *realContext_t) *real_t;
extern fn decNumberAdd(result: *real_t, lhs: *const real_t, rhs: *const real_t, real_context: *realContext_t) *real_t;
extern fn decNumberSubtract(result: *real_t, lhs: *const real_t, rhs: *const real_t, real_context: *realContext_t) *real_t;
extern fn decNumberMinus(result: *real_t, rhs: *const real_t, real_context: *realContext_t) *real_t;
extern fn decNumberCopy(result: *real_t, rhs: *const real_t) *real_t;
extern fn decNumberFromUInt32(result: *real_t, rhs: u32) *real_t;
extern fn decNumberSquareRoot(result: *real_t, rhs: *const real_t, real_context: *realContext_t) *real_t;
extern fn decNumberFMA(result: *real_t, factor1: *const real_t, factor2: *const real_t, term: *const real_t, real_context: *realContext_t) *real_t;
extern fn PowerReal(y: *const real_t, x: *const real_t, result: *real_t, real_context: *realContext_t) void;

extern fn realPower(base: *const real_t, exponent: *const real_t, result: *real_t, real_context: *realContext_t) void;
extern fn realExp(x: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn realSetZero(value: *real_t) void;
extern fn realSetOne(value: *real_t) void;
extern fn realSetPlusInfinity(value: *real_t) void;
extern fn realCompareEqual(number1: *const real_t, number2: *const real_t) bool;
extern fn realCompareLessThan(number1: *const real_t, number2: *const real_t) bool;
extern fn realCompareGreaterThan(number1: *const real_t, number2: *const real_t) bool;
extern fn realSetNaN(value: *real_t) void;
extern fn realIsAnInteger(value: *const real_t) bool;
extern fn realToIntegralValue(source: *const real_t, destination: *real_t, mode: c_int, real_context: *realContext_t) void;
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
pub extern fn WP34S_LnGamma(x: *const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn WP34S_qf_q_est(x: *const real_t, res: *real_t, res_y: ?*real_t, real_context: *realContext_t) void;
pub extern fn WP34S_GammaP(x: *const real_t, a: *const real_t, res: *real_t, real_context: *realContext_t, upper: bool, regularised: bool) void;
pub extern fn WP34S_Qf_Newton(r_dist: u32, target: *const real_t, estimate: *const real_t, p1: [*c]const real_t, p2: [*c]const real_t, p3: [*c]const real_t, res: *real_t, real_context: *realContext_t) void;

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
pub inline fn realIsZero(value: *const real_t) bool {
    return value.digits == 1 and value.lsu[0] == 0 and !realIsSpecial(value);
}
pub inline fn realIsInfinite(value: *const real_t) bool {
    return (value.bits & DECINF) != 0;
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
pub inline fn realCompareLessEqual(lhs: *const real_t, rhs: *const real_t) bool {
    return realCompareLessThan(lhs, rhs) or realCompareEqual(lhs, rhs);
}
pub inline fn realCompareGreaterEqual(lhs: *const real_t, rhs: *const real_t) bool {
    return !realCompareLessThan(lhs, rhs);
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

// const_4 has no c47 wrapper accessor; materialise it once from the integer 4.
var const_4_value: real_t = undefined;
var const_4_ready = false;
pub fn const4() *const real_t {
    if (!const_4_ready) {
        _ = decNumberFromUInt32(&const_4_value, 4);
        const_4_ready = true;
    }
    return &const_4_value;
}

// const_6 likewise has no c47 wrapper accessor; materialise it once from 6.
var const_6_value: real_t = undefined;
var const_6_ready = false;
pub fn const6() *const real_t {
    if (!const_6_ready) {
        _ = decNumberFromUInt32(&const_6_value, 6);
        const_6_ready = true;
    }
    return &const_6_value;
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
