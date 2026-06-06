// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for the Cauchy distribution commands, porting
// `src/c47/distributions/cauchy.c`. The four fn* entry points are dispatched
// from the items.c function table; the WP34S_* helpers are cauchy-internal
// (no external references) and stay private.
//
// Frontier has no parity harness, so the decNumber/register surface is externed
// straight to the c47-core symbols present in the product, test, and firmware
// links.

const DECNUMUNITS = 25;

const DECNEG: u8 = 0x80;
const DECINF: u8 = 0x40;
const DECNAN: u8 = 0x20;
const DECSNAN: u8 = 0x10;
const DECSPECIAL: u8 = 0x70;

const calcRegister_t = i16;
const angularMode_t = c_int;
const rounding_t = c_int;

const REGISTER_X: calcRegister_t = 100;
const REGISTER_Z: calcRegister_t = 102;
const REGISTER_M: calcRegister_t = 112;
const REGISTER_S: calcRegister_t = 117;
const ERR_REGISTER_LINE: calcRegister_t = REGISTER_Z;
const amNone: angularMode_t = 5;

const FLAG_SPCRES: i32 = 0x8017;
const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN: u8 = 1;
const ERROR_INVALID_DISTRIBUTION_PARAM: u8 = 16;
const ERROR_NO_ROOT_FOUND: u8 = 20;

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

extern var ctxtReal39: realContext_t;
extern var const_NaN: *const real_t;

extern fn z47_math_wrappers_const_0() *const real_t;
extern fn z47_math_wrappers_const_1() *const real_t;
extern fn z47_math_wrappers_const_1on2() *const real_t;
extern fn z47_math_wrappers_const_pi() *const real_t;

extern fn decNumberMultiply(result: *real_t, lhs: *const real_t, rhs: *const real_t, real_context: *realContext_t) *real_t;
extern fn decNumberDivide(result: *real_t, lhs: *const real_t, rhs: *const real_t, real_context: *realContext_t) *real_t;
extern fn decNumberAdd(result: *real_t, lhs: *const real_t, rhs: *const real_t, real_context: *realContext_t) *real_t;
extern fn decNumberSubtract(result: *real_t, lhs: *const real_t, rhs: *const real_t, real_context: *realContext_t) *real_t;

extern fn realSetZero(value: *real_t) void;
extern fn realSetPlusInfinity(value: *real_t) void;
extern fn realCompareEqual(number1: *const real_t, number2: *const real_t) bool;
extern fn realCompareLessThan(number1: *const real_t, number2: *const real_t) bool;

extern fn C47_WP34S_Atan(x: *const real_t, angle: *real_t, real_context: *realContext_t) void;
extern fn C47_WP34S_SinCosTanTaylor(angle: *const real_t, swap: bool, sin_out: ?*real_t, cos_out: ?*real_t, tan_out: ?*real_t, real_context: *realContext_t) void;

extern fn saveLastX() bool;
extern fn getRegisterAsReal(reg: calcRegister_t, value: *real_t) bool;
extern fn convertRealToResultRegister(real: *const real_t, dest: calcRegister_t, angle_mode: angularMode_t) void;
extern fn adjustResult(res: calcRegister_t, drop_y: bool, set_cpx_res: bool, op1: calcRegister_t, op2: calcRegister_t, op3: calcRegister_t) void;
extern fn displayDomainErrorMessage(error_code: u8, err_message_register_line: calcRegister_t, err_register_line: calcRegister_t) void;
extern fn moreInfoOnError(msg1: [*:0]const u8, msg2: ?[*:0]const u8, msg3: ?[*:0]const u8, msg4: ?[*:0]const u8) void;
extern fn getSystemFlag(flag: i32) bool;

inline fn realMultiply(lhs: *const real_t, rhs: *const real_t, result: *real_t, real_context: *realContext_t) void {
    _ = decNumberMultiply(result, lhs, rhs, real_context);
}
inline fn realDivide(lhs: *const real_t, rhs: *const real_t, result: *real_t, real_context: *realContext_t) void {
    _ = decNumberDivide(result, lhs, rhs, real_context);
}
inline fn realAdd(lhs: *const real_t, rhs: *const real_t, result: *real_t, real_context: *realContext_t) void {
    _ = decNumberAdd(result, lhs, rhs, real_context);
}
inline fn realSubtract(lhs: *const real_t, rhs: *const real_t, result: *real_t, real_context: *realContext_t) void {
    _ = decNumberSubtract(result, lhs, rhs, real_context);
}

inline fn realIsSpecial(value: *const real_t) bool {
    return (value.bits & DECSPECIAL) != 0;
}
inline fn realIsNaN(value: *const real_t) bool {
    return (value.bits & (DECNAN | DECSNAN)) != 0;
}
inline fn realIsNegative(value: *const real_t) bool {
    return (value.bits & DECNEG) != 0;
}
inline fn realIsZero(value: *const real_t) bool {
    return value.digits == 1 and value.lsu[0] == 0 and !realIsSpecial(value);
}
inline fn realChangeSign(value: *real_t) void {
    value.bits ^= 0x80;
}
inline fn realCompareLessEqual(lhs: *const real_t, rhs: *const real_t) bool {
    return realCompareLessThan(lhs, rhs) or realCompareEqual(lhs, rhs);
}
inline fn realCompareGreaterEqual(lhs: *const real_t, rhs: *const real_t) bool {
    return !realCompareLessThan(lhs, rhs);
}

fn const0() *const real_t {
    return z47_math_wrappers_const_0();
}
fn const1() *const real_t {
    return z47_math_wrappers_const_1();
}
fn const1on2() *const real_t {
    return z47_math_wrappers_const_1on2();
}
fn const39Pi() *const real_t {
    return z47_math_wrappers_const_pi();
}

fn checkParamCauchy(x: *real_t, i: *real_t, j: *real_t) bool {
    if (!saveLastX()) {
        return false;
    }

    if (!getRegisterAsReal(REGISTER_X, x) or !getRegisterAsReal(REGISTER_M, i) or !getRegisterAsReal(REGISTER_S, j)) {
        return fail();
    }

    if (realIsZero(j) or realIsNegative(j)) {
        displayDomainErrorMessage(ERROR_INVALID_DISTRIBUTION_PARAM, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function checkParamCauchy:", "cannot calculate for gamma <= 0", null, null);
        return fail();
    }
    return true;
}

fn fail() bool {
    if (getSystemFlag(FLAG_SPCRES)) {
        convertRealToResultRegister(const_NaN, REGISTER_X, amNone);
    }
    return false;
}

pub fn cauchyP(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var x0: real_t = undefined;
    var gamma: real_t = undefined;

    if (checkParamCauchy(&val, &x0, &gamma)) {
        wp34sPdfCauchy(&val, &x0, &gamma, &ans, &ctxtReal39);
        convertRealToResultRegister(&ans, REGISTER_X, amNone);
        adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
    }
}

pub fn cauchyL(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var x0: real_t = undefined;
    var gamma: real_t = undefined;

    if (checkParamCauchy(&val, &x0, &gamma)) {
        wp34sCdfCauchy(&val, &x0, &gamma, &ans, &ctxtReal39);
        convertRealToResultRegister(&ans, REGISTER_X, amNone);
        adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
    }
}

pub fn cauchyR(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var x0: real_t = undefined;
    var gamma: real_t = undefined;

    if (checkParamCauchy(&val, &x0, &gamma)) {
        wp34sCdfuCauchy(&val, &x0, &gamma, &ans, &ctxtReal39);
        convertRealToResultRegister(&ans, REGISTER_X, amNone);
        adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
    }
}

pub fn cauchyI(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var x0: real_t = undefined;
    var gamma: real_t = undefined;

    if (checkParamCauchy(&val, &x0, &gamma)) {
        if (realCompareLessEqual(&val, const0()) or realCompareGreaterEqual(&val, const1())) {
            displayDomainErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnError("In function fnCauchyI:", "the argument must be 0 < x < 1", null, null);
            if (getSystemFlag(FLAG_SPCRES)) {
                convertRealToResultRegister(const_NaN, REGISTER_X, amNone);
            }
            return;
        }
        wp34sQfCauchy(&val, &x0, &gamma, &ans, &ctxtReal39);
        if (realIsNaN(&ans)) {
            displayDomainErrorMessage(ERROR_NO_ROOT_FOUND, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnError("In function fnCauchyI:", "WP34S_Qf_Chi2 did not converge", null, null);
            if (getSystemFlag(FLAG_SPCRES)) {
                convertRealToResultRegister(const_NaN, REGISTER_X, amNone);
            }
            return;
        }
        convertRealToResultRegister(&ans, REGISTER_X, amNone);
        adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
    }
}

// These functions are borrowed from the WP34S project.

fn wp34sPdfCauchy(x: *const real_t, x0: *const real_t, gamma: *const real_t, res: *real_t, real_context: *realContext_t) void {
    wp34sCdfCauchyXform(x, x0, gamma, res, real_context);
    if (realIsSpecial(res)) {
        realSetZero(res); // Can only be infinite which has zero probability.
        return;
    }
    realMultiply(res, res, res, real_context);
    realAdd(res, const1(), res, real_context);
    realMultiply(res, gamma, res, real_context);
    realMultiply(res, const39Pi(), res, real_context);
    realDivide(const1(), res, res, real_context);
}

fn wp34sCdfuCauchy(x: *const real_t, x0: *const real_t, gamma: *const real_t, res: *real_t, real_context: *realContext_t) void {
    wp34sCdfCauchyCommon(x, x0, gamma, true, res, real_context);
}

fn wp34sCdfCauchy(x: *const real_t, x0: *const real_t, gamma: *const real_t, res: *real_t, real_context: *realContext_t) void {
    wp34sCdfCauchyCommon(x, x0, gamma, false, res, real_context);
}

fn wp34sCdfCauchyCommon(x: *const real_t, x0: *const real_t, gamma: *const real_t, complementary: bool, res: *real_t, real_context: *realContext_t) void {
    var p: real_t = undefined;

    wp34sCdfCauchyXform(x, x0, gamma, &p, real_context);
    if (realIsSpecial(&p)) {
        realSetPlusInfinity(res);
        return;
    }
    C47_WP34S_Atan(&p, &p, real_context);
    realDivide(&p, const39Pi(), &p, real_context);
    if (complementary) {
        realChangeSign(&p);
    }
    realAdd(&p, const1on2(), res, real_context);
}

fn wp34sCdfCauchyXform(x: *const real_t, x0: *const real_t, gamma: *const real_t, res: *real_t, real_context: *realContext_t) void {
    realSubtract(x, x0, res, real_context);
    realDivide(res, gamma, res, real_context);
}

fn wp34sQfCauchy(x: *const real_t, x0: *const real_t, gamma: *const real_t, res: *real_t, real_context: *realContext_t) void {
    var p: real_t = undefined;
    var s: real_t = undefined;
    var c: real_t = undefined;

    realSubtract(x, const1on2(), &p, real_context);
    realMultiply(&p, const39Pi(), &p, real_context);
    C47_WP34S_SinCosTanTaylor(&p, false, &s, &c, &p, real_context);
    realMultiply(&p, gamma, &p, real_context);
    realAdd(&p, x0, res, real_context);
}
