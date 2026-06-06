// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for the Weibull distribution commands, porting
// `src/c47/distributions/weibull.c`. The four fn* entry points are dispatched
// from the items.c function table; the WP34S_*_Weib helpers are weibull-internal
// (no external references) and stay private.
//
// Frontier has no parity harness, so the decNumber/register surface is externed
// straight to the c47-core symbols present in the product, test, and firmware
// links.

const DECNUMUNITS = 25;

const DECNEG: u8 = 0x80;
const DECNAN: u8 = 0x20;
const DECSNAN: u8 = 0x10;
const DECSPECIAL: u8 = 0x70;

const calcRegister_t = i16;
const angularMode_t = c_int;
const rounding_t = c_int;

const REGISTER_X: calcRegister_t = 100;
const REGISTER_Z: calcRegister_t = 102;
const REGISTER_Q: calcRegister_t = 115;
const REGISTER_S: calcRegister_t = 117;
const ERR_REGISTER_LINE: calcRegister_t = REGISTER_Z;
const amNone: angularMode_t = 5;

const FLAG_SPCRES: i32 = 0x8017;
const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN: u8 = 1;
const ERROR_INVALID_DISTRIBUTION_PARAM: u8 = 16;

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

extern fn decNumberMultiply(result: *real_t, lhs: *const real_t, rhs: *const real_t, real_context: *realContext_t) *real_t;
extern fn decNumberDivide(result: *real_t, lhs: *const real_t, rhs: *const real_t, real_context: *realContext_t) *real_t;
extern fn decNumberMinus(result: *real_t, rhs: *const real_t, real_context: *realContext_t) *real_t;

extern fn realPower(base: *const real_t, exponent: *const real_t, result: *real_t, real_context: *realContext_t) void;
extern fn realExp(x: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn realSetZero(value: *real_t) void;
extern fn realSetOne(value: *real_t) void;
extern fn WP34S_ExpM1(x: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_Ln1P(x: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn realCompareEqual(number1: *const real_t, number2: *const real_t) bool;
extern fn realCompareLessThan(number1: *const real_t, number2: *const real_t) bool;

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
inline fn realMinus(operand: *const real_t, result: *real_t, real_context: *realContext_t) void {
    _ = decNumberMinus(result, operand, real_context);
}

inline fn realIsSpecial(value: *const real_t) bool {
    return (value.bits & DECSPECIAL) != 0;
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

fn checkParamWeibull(x: *real_t, shape: *real_t, scale: *real_t) bool {
    if (!saveLastX()) {
        return false;
    }

    if (!getRegisterAsReal(REGISTER_X, x) or !getRegisterAsReal(REGISTER_Q, shape) or !getRegisterAsReal(REGISTER_S, scale)) {
        return fail();
    }

    if (realIsNegative(x)) {
        displayDomainErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function checkParamWeibull:", "cannot calculate for x < 0", null, null);
        return fail();
    } else if (realIsZero(shape) or realIsNegative(shape) or realIsZero(scale) or realIsNegative(scale)) {
        displayDomainErrorMessage(ERROR_INVALID_DISTRIBUTION_PARAM, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function checkParamWeibull:", "cannot calculate for b <= 0 or t <= 0", null, null);
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

pub fn weibullP(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var shape: real_t = undefined;
    var lifetime: real_t = undefined;
    var ans: real_t = undefined;

    if (checkParamWeibull(&val, &shape, &lifetime)) {
        wp34sPdfWeib(&val, &lifetime, &shape, &ans, &ctxtReal39);
        convertRealToResultRegister(&ans, REGISTER_X, amNone);
        adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
    }
}

pub fn weibullL(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var shape: real_t = undefined;
    var lifetime: real_t = undefined;
    var ans: real_t = undefined;

    if (checkParamWeibull(&val, &shape, &lifetime)) {
        wp34sCdfWeib(&val, &lifetime, &shape, &ans, &ctxtReal39);
        convertRealToResultRegister(&ans, REGISTER_X, amNone);
        adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
    }
}

pub fn weibullR(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var shape: real_t = undefined;
    var lifetime: real_t = undefined;
    var ans: real_t = undefined;

    if (checkParamWeibull(&val, &shape, &lifetime)) {
        wp34sCdfuWeib(&val, &lifetime, &shape, &ans, &ctxtReal39);
        convertRealToResultRegister(&ans, REGISTER_X, amNone);
        adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
    }
}

pub fn weibullI(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var shape: real_t = undefined;
    var lifetime: real_t = undefined;
    var ans: real_t = undefined;

    if (checkParamWeibull(&val, &shape, &lifetime)) {
        if (realCompareLessEqual(&val, const0()) or realCompareGreaterEqual(&val, const1())) {
            displayDomainErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnError("In function fnWeibullI:", "the argument must be 0 < x < 1", null, null);
            if (getSystemFlag(FLAG_SPCRES)) {
                convertRealToResultRegister(const_NaN, REGISTER_X, amNone);
            }
            return;
        }
        wp34sQfWeib(&val, &lifetime, &shape, &ans, &ctxtReal39);
        convertRealToResultRegister(&ans, REGISTER_X, amNone);
        adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
    }
}

// These functions are borrowed from the WP34S project.

fn wp34sPdfWeib(x: *const real_t, b: *const real_t, t: *const real_t, res: *real_t, real_context: *realContext_t) void {
    var p: real_t = undefined;
    var q: real_t = undefined;
    var r: real_t = undefined;

    realDivide(x, b, &p, real_context);
    if (realIsSpecial(&p) or realIsNegative(&p) or realIsZero(&p)) {
        realSetZero(res);
        return;
    }
    realPower(&p, t, &q, real_context);
    realMinus(&q, &r, real_context);
    realExp(&r, &r, real_context);
    realMultiply(&r, &q, &r, real_context);
    realDivide(&r, &p, &r, real_context);
    realMultiply(&r, t, &r, real_context);
    realDivide(&r, b, res, real_context);
}

fn wp34sCdfuWeib(x: *const real_t, b: *const real_t, t: *const real_t, res: *real_t, real_context: *realContext_t) void {
    var p: real_t = undefined;

    realDivide(x, b, &p, real_context);
    if (realIsNegative(&p) or realIsZero(&p)) {
        realSetOne(res);
        return;
    }
    if (realIsSpecial(&p)) {
        realSetZero(res);
        return;
    }
    realPower(&p, t, &p, real_context);
    realChangeSign(&p);
    realExp(&p, res, real_context);
}

fn wp34sCdfWeib(x: *const real_t, b: *const real_t, t: *const real_t, res: *real_t, real_context: *realContext_t) void {
    var p: real_t = undefined;

    realDivide(x, b, &p, real_context);
    if (realIsNegative(&p) or realIsZero(&p)) {
        realSetZero(res);
        return;
    }
    if (realIsSpecial(&p)) {
        realSetOne(res);
        return;
    }
    realPower(&p, t, &p, real_context);
    realChangeSign(&p);
    WP34S_ExpM1(&p, res, real_context);
    realChangeSign(res);
}

fn wp34sQfWeib(x: *const real_t, b: *const real_t, t: *const real_t, res: *real_t, real_context: *realContext_t) void {
    // (-ln(1-p) ^ (1/k)) * J
    var p: real_t = undefined;
    var q: real_t = undefined;

    realMinus(x, &p, real_context);
    WP34S_Ln1P(&p, &p, real_context);
    realChangeSign(&p);
    realDivide(const1(), t, &q, real_context);
    realPower(&p, &q, &p, real_context);
    realMultiply(&p, b, res, real_context);
}
