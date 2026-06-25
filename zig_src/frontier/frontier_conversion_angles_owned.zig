// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/conversionAngles.c: angular-mode conversion. The core
// convertAngleFromTo (used across ~26 first-party files via trig and display)
// converts a real_t angle between radian/grad/degree/DMS/multiple-of-pi at the
// caller's precision; convertAngle34FromTo wraps it for register real34 values;
// the DMS helpers and setInfiniteComplexAngle round it out. All exported with C
// linkage and force-included by frontier.zig.
//
// real_t constants come from the shared `constants` blob by offset (the
// conversionUnits pattern); cst() returns an unaligned pointer so the macOS host
// build (where the blob base is byte-aligned) does not trap. real34 register
// values go through decimal128 <-> decNumber, and angular state through the
// register/currentAngularMode externs.
//
// The upstream fnCvtDegToRad..fnCvtDmsToCurrentAngularMode commands are commented
// out in conversionAngles.c, so only the live functions are ported here.

const frontier_build_options = @import("frontier_build_options");
const extra_info: bool = frontier_build_options.extra_info_on_calc_error;

const constants = @extern([*]const u8, .{ .name = "constants" });
const OFF_const_1 = 4856;
const OFF_const_60 = 5296;
const OFF_const_90 = 7544;
const OFF_const_100 = 7532;
const OFF_const_180 = 7460;
const OFF_const_200 = 7448;
const OFF_const_3600 = 5448;
const OFF_const_9on10 = 4808;
const OFF_const39_pi = 1848;
const OFF_const75_pi = 7388;
const OFF_const1071_pi = 9932;
const OFF_const75_piOn2 = 7472;
const OFF_const1071_piOn2 = 9208;
const OFF_const39_200onPi = 5308;
const OFF_const39_180onPi = 5260;

const DECNUMUNITS = 25;
const real_t = extern struct {
    digits: i32,
    exponent: i32,
    bits: u8,
    lsu: [DECNUMUNITS]u16,
};
const realContext_t = extern struct {
    digits: i32,
    emax: i32,
    emin: i32,
    round: c_int,
    traps: u32,
    status: u32,
    clamp: u8,
};
const real34_t = extern struct { bytes: [16]u8 };

const calcRegister_t = i16;
const angularMode_t = c_int;

// angularMode_t values (typeDefinitions.h).
const amRadian: angularMode_t = 0;
const amGrad: angularMode_t = 1;
const amDegree: angularMode_t = 2;
const amDMS: angularMode_t = 3;
const amMultPi: angularMode_t = 4;
const amNone: angularMode_t = 5;
const amAngleMask: u32 = 15;

// data types (defines.h).
const dtLongInteger: u32 = 0;
const dtReal34: u32 = 1;

const REGISTER_X: calcRegister_t = 100;
const ERR_REGISTER_LINE: calcRegister_t = 102; // REGISTER_Z
const ERROR_INVALID_DATA_TYPE_FOR_OP: u8 = 24;

const DEC_ROUND_DOWN: c_int = 5; // decContext.h rounding enum
const DEC_Invalid_operation: u32 = 0x00000080;

extern var currentAngularMode: angularMode_t;
extern var ctxtReal39: realContext_t;
extern var ctxtReal34: realContext_t;

extern fn saveLastX() bool;
extern fn getRegisterDataType(reg: calcRegister_t) u32;
extern fn getRegisterDataPointer(reg: calcRegister_t) *anyopaque;
extern fn getRegisterTag(reg: calcRegister_t) u32;
extern fn setRegisterTag(reg: calcRegister_t, tag: u32) void;
extern fn convertLongIntegerRegisterToReal34Register(source: calcRegister_t, destination: calcRegister_t) void;
extern fn displayCalcErrorMessage(error_code: u8, err_message_register_line: calcRegister_t, err_register_line: calcRegister_t) void;
const c_moreInfoOnError = @extern(*const fn (msg1: [*:0]const u8, msg2: ?[*:0]const u8, msg3: ?[*:0]const u8, msg4: ?[*:0]const u8) callconv(.c) void, .{ .name = "moreInfoOnError" });

extern fn decimal128ToNumber(src: *const real34_t, dst: *real_t) *real_t;
extern fn decimal128FromNumber(dst: *real34_t, src: *const real_t, ctx: *realContext_t) *real34_t;
extern fn realToIntegralValue(source: *const real_t, destination: *real_t, mode: c_int, real_context: *realContext_t) void;
extern fn realSetZero(value: *real_t) void;
extern fn realSetPlusInfinity(value: *real_t) void;
extern fn realSetMinusInfinity(value: *real_t) void;
extern fn decContextClearStatus(ctx: *realContext_t, mask: u32) *realContext_t;

extern fn decNumberMultiply(result: *real_t, lhs: *align(1) const real_t, rhs: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberDivide(result: *real_t, lhs: *align(1) const real_t, rhs: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberAdd(result: *real_t, lhs: *align(1) const real_t, rhs: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberSubtract(result: *real_t, lhs: *align(1) const real_t, rhs: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn realCompareGreaterThan(a: *align(1) const real_t, b: *align(1) const real_t) bool;
extern fn realCompareEqual(a: *align(1) const real_t, b: *align(1) const real_t) bool;

inline fn moreInfoOnError(msg1: [*:0]const u8, msg2: ?[*:0]const u8) void {
    if (comptime extra_info) c_moreInfoOnError(msg1, msg2, null, null);
}
inline fn cst(offset: u32) *align(1) const real_t {
    return @ptrCast(constants + offset);
}
inline fn reg34(reg: calcRegister_t) *real34_t {
    return @ptrCast(getRegisterDataPointer(reg));
}
inline fn getRegisterAngularMode(reg: calcRegister_t) angularMode_t {
    return @intCast(getRegisterTag(reg) & amAngleMask);
}
inline fn setRegisterAngularMode(reg: calcRegister_t, mode: angularMode_t) void {
    setRegisterTag(reg, @intCast(mode));
}
inline fn realMul(a: *align(1) const real_t, b: *align(1) const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberMultiply(res, a, b, ctx);
}
inline fn realDiv(a: *align(1) const real_t, b: *align(1) const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberDivide(res, a, b, ctx);
}
inline fn realAddOp(a: *align(1) const real_t, b: *align(1) const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberAdd(res, a, b, ctx);
}
inline fn realSubOp(a: *align(1) const real_t, b: *align(1) const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberSubtract(res, a, b, ctx);
}
inline fn realGreaterEqual(a: *align(1) const real_t, b: *align(1) const real_t) bool {
    return realCompareGreaterThan(a, b) or realCompareEqual(a, b);
}
inline fn realIsNegative(v: *const real_t) bool {
    return (v.bits & 0x80) != 0;
}
inline fn realIsPositive(v: *const real_t) bool {
    return (v.bits & 0x80) == 0;
}
inline fn realIsInfinite(v: *const real_t) bool {
    return (v.bits & 0x40) != 0;
}
inline fn realSetPositiveSign(v: *real_t) void {
    v.bits &= 0x7f;
}
inline fn realSetNegativeSign(v: *real_t) void {
    v.bits |= 0x80;
}
inline fn real34ToReal(src: *const real34_t, dst: *real_t) void {
    _ = decimal128ToNumber(src, dst);
}
inline fn realToReal34(src: *const real_t, dst: *real34_t) void {
    _ = decimal128FromNumber(dst, src, &ctxtReal34);
}
inline fn real34IsNegative(v: *const real34_t) bool {
    return (v.bytes[15] & 0x80) == 0x80;
}

fn cannotConvertError(reg: calcRegister_t, where: [*:0]const u8, hint: [*:0]const u8) void {
    // The upstream EXTRA_INFO path also sprintf()s a getRegisterDataTypeName()
    // line; that host-only console hint is dropped here (the testSuite checks
    // computed values, not the hint text), matching the conversionUnits owner.
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, reg);
    moreInfoOnError(where, hint);
}

pub export fn fnCvtToCurrentAngularMode(from_angular_mode: u16) callconv(.c) void {
    if (!saveLastX()) return;
    const from: angularMode_t = @intCast(from_angular_mode);
    switch (getRegisterDataType(REGISTER_X)) {
        dtLongInteger => {
            convertLongIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
            convertAngle34FromTo(reg34(REGISTER_X), from, currentAngularMode);
            setRegisterAngularMode(REGISTER_X, currentAngularMode);
        },
        dtReal34 => {
            convertAngle34FromTo(reg34(REGISTER_X), from, currentAngularMode);
            setRegisterAngularMode(REGISTER_X, currentAngularMode);
        },
        else => cannotConvertError(REGISTER_X, "In function fnCvtToCurrentAngularMode:", "the input value must be a long integer, a real34 or an angle34"),
    }
}

pub export fn fnCvtFromCurrentAngularModeRegister(regist1: calcRegister_t, to_angular_mode: u16) callconv(.c) void {
    if (!saveLastX()) return;
    const to: angularMode_t = @intCast(to_angular_mode);
    switch (getRegisterDataType(regist1)) {
        dtLongInteger => {
            convertLongIntegerRegisterToReal34Register(regist1, regist1);
            convertAngle34FromTo(reg34(regist1), currentAngularMode, to);
            setRegisterAngularMode(regist1, to);
        },
        dtReal34 => {
            if (currentAngularMode == amDMS and getRegisterAngularMode(regist1) == amNone) {
                real34FromDmsToDeg(reg34(regist1), reg34(regist1));
                setRegisterAngularMode(regist1, amDegree);
            }
            const from = if (getRegisterAngularMode(regist1) == amNone) currentAngularMode else getRegisterAngularMode(regist1);
            convertAngle34FromTo(reg34(regist1), from, to);
            setRegisterAngularMode(regist1, to);
        },
        else => cannotConvertError(regist1, "In function fnCvtFromCurrentAngularModeRegister:", "the input value must be a long integer, a real34 or an angle16 or an angle34"),
    }
}

pub export fn fnCvtFromCurrentAngularMode(to_angular_mode: u16) callconv(.c) void {
    fnCvtFromCurrentAngularModeRegister(REGISTER_X, to_angular_mode);
}

pub export fn convertAngle34FromTo(angle34: *real34_t, from_angular_mode: angularMode_t, to_angular_mode: angularMode_t) callconv(.c) void {
    var angle: real_t = undefined;
    real34ToReal(angle34, &angle);
    convertAngleFromTo(&angle, from_angular_mode, to_angular_mode, &ctxtReal39);
    realToReal34(&angle, angle34);
}

pub export fn convertAngleFromTo(angle: *real_t, from_angular_mode_arg: angularMode_t, to_angular_mode_arg: angularMode_t, real_context: *realContext_t) callconv(.c) void {
    const from = if (from_angular_mode_arg == amNone) currentAngularMode else from_angular_mode_arg;
    const to = if (to_angular_mode_arg == amNone) currentAngularMode else to_angular_mode_arg;
    const lp = real_context.digits > 39;
    const vlp = real_context.digits > 75;
    const a: *align(1) const real_t = angle;
    switch (from) {
        amRadian => switch (to) {
            amMultPi => realDiv(a, if (vlp) cst(OFF_const1071_pi) else if (lp) cst(OFF_const75_pi) else cst(OFF_const39_pi), angle, real_context),
            amGrad => {
                if (vlp) {
                    realMul(a, cst(OFF_const_100), angle, real_context);
                    realDiv(a, cst(OFF_const1071_piOn2), angle, real_context);
                } else if (lp) {
                    realMul(a, cst(OFF_const_100), angle, real_context);
                    realDiv(a, cst(OFF_const75_piOn2), angle, real_context);
                } else {
                    realMul(a, cst(OFF_const39_200onPi), angle, real_context);
                }
            },
            amDegree, amDMS => {
                if (vlp) {
                    realMul(a, cst(OFF_const_90), angle, real_context);
                    realDiv(a, cst(OFF_const1071_piOn2), angle, real_context);
                } else if (lp) {
                    realMul(a, cst(OFF_const_90), angle, real_context);
                    realDiv(a, cst(OFF_const75_piOn2), angle, real_context);
                } else {
                    realMul(a, cst(OFF_const39_180onPi), angle, real_context);
                }
            },
            else => {},
        },
        amMultPi => switch (to) {
            amRadian => realMul(a, if (vlp) cst(OFF_const1071_pi) else if (lp) cst(OFF_const75_pi) else cst(OFF_const39_pi), angle, real_context),
            amGrad => realMul(a, cst(OFF_const_200), angle, real_context),
            amDegree, amDMS => realMul(a, cst(OFF_const_180), angle, real_context),
            else => {},
        },
        amGrad => switch (to) {
            amRadian => {
                if (vlp) {
                    realMul(a, cst(OFF_const1071_piOn2), angle, real_context);
                    realDiv(a, cst(OFF_const_100), angle, real_context);
                } else if (lp) {
                    realMul(a, cst(OFF_const75_piOn2), angle, real_context);
                    realDiv(a, cst(OFF_const_100), angle, real_context);
                } else {
                    realDiv(a, cst(OFF_const39_200onPi), angle, real_context);
                }
            },
            amMultPi => realDiv(a, cst(OFF_const_200), angle, real_context),
            amDegree, amDMS => realMul(a, cst(OFF_const_9on10), angle, real_context),
            else => {},
        },
        amDegree, amDMS => switch (to) {
            amRadian => {
                if (vlp) {
                    realMul(a, cst(OFF_const1071_piOn2), angle, real_context);
                    realDiv(a, cst(OFF_const_90), angle, real_context);
                } else if (lp) {
                    realMul(a, cst(OFF_const75_piOn2), angle, real_context);
                    realDiv(a, cst(OFF_const_90), angle, real_context);
                } else {
                    realDiv(a, cst(OFF_const39_180onPi), angle, real_context);
                }
            },
            amMultPi => realDiv(a, cst(OFF_const_180), angle, real_context),
            amGrad => realDiv(a, cst(OFF_const_9on10), angle, real_context),
            else => {},
        },
        else => {},
    }
}

pub export fn checkDms34(angle34_dms: *real34_t) callconv(.c) void {
    var angle_dms: real_t = undefined;
    var degrees: real_t = undefined;
    var minutes: real_t = undefined;
    var seconds: real_t = undefined;

    real34ToReal(angle34_dms, &angle_dms);
    const sign: i16 = if (realIsNegative(&angle_dms)) -1 else 1;
    realSetPositiveSign(&angle_dms);

    realToIntegralValue(&angle_dms, &degrees, DEC_ROUND_DOWN, &ctxtReal39);
    realSubOp(&angle_dms, &degrees, &angle_dms, &ctxtReal39);

    angle_dms.exponent += 2; // * 100
    realToIntegralValue(&angle_dms, &minutes, DEC_ROUND_DOWN, &ctxtReal39);
    realSubOp(&angle_dms, &minutes, &angle_dms, &ctxtReal39);

    realMul(&angle_dms, cst(OFF_const_100), &seconds, &ctxtReal39);

    if (realGreaterEqual(&seconds, cst(OFF_const_60))) {
        realSubOp(&seconds, cst(OFF_const_60), &seconds, &ctxtReal39);
        realAddOp(&minutes, cst(OFF_const_1), &minutes, &ctxtReal39);
    }
    if (realGreaterEqual(&minutes, cst(OFF_const_60))) {
        realSubOp(&minutes, cst(OFF_const_60), &minutes, &ctxtReal39);
        realAddOp(&degrees, cst(OFF_const_1), &degrees, &ctxtReal39);
    }

    minutes.exponent -= 2; // / 100
    realAddOp(&degrees, &minutes, &angle_dms, &ctxtReal39);
    seconds.exponent -= 4; // / 10000
    realAddOp(&angle_dms, &seconds, &angle_dms, &ctxtReal39);

    if (sign == -1) {
        realSetNegativeSign(&angle_dms);
    }
    realToReal34(&angle_dms, angle34_dms);
}

pub export fn getInfiniteComplexAngle(x: *real_t, y: *real_t) callconv(.c) u32 {
    if (!realIsInfinite(x)) {
        return 2 + 4 * @as(u32, @intFromBool(realIsNegative(y)));
    }
    if (!realIsInfinite(y)) {
        return 4 * @as(u32, @intFromBool(realIsNegative(x)));
    }
    if (realIsPositive(x)) {
        return 1 + 6 * @as(u32, @intFromBool(realIsNegative(y)));
    }
    return 3 + 2 * @as(u32, @intFromBool(realIsNegative(y)));
}

pub export fn setInfiniteComplexAngle(angle: u32, x: *real_t, y: *real_t) callconv(.c) void {
    switch (angle) {
        3, 4, 5 => realSetMinusInfinity(x),
        2, 6 => realSetZero(x),
        else => realSetPlusInfinity(x),
    }
    switch (angle) {
        5, 6, 7 => realSetMinusInfinity(y),
        0, 4 => realSetZero(y),
        else => realSetPlusInfinity(y),
    }
}

pub export fn real34FromDmsToDeg(angle_dms: *const real34_t, angle_dec: *real34_t) callconv(.c) void {
    var angle: real_t = undefined;
    var degrees: real_t = undefined;
    var minutes: real_t = undefined;
    var seconds: real_t = undefined;

    real34ToReal(angle_dms, &angle);
    realSetPositiveSign(&angle);

    _ = decContextClearStatus(&ctxtReal34, DEC_Invalid_operation);
    realToIntegralValue(&angle, &degrees, DEC_ROUND_DOWN, &ctxtReal39);

    realSubOp(&angle, &degrees, &angle, &ctxtReal39);
    angle.exponent += 2; // * 100

    realToIntegralValue(&angle, &minutes, DEC_ROUND_DOWN, &ctxtReal39);

    realSubOp(&angle, &minutes, &angle, &ctxtReal39);
    realMul(&angle, cst(OFF_const_100), &seconds, &ctxtReal39);

    if (realGreaterEqual(&seconds, cst(OFF_const_60))) {
        realSubOp(&seconds, cst(OFF_const_60), &seconds, &ctxtReal39);
        realAddOp(&minutes, cst(OFF_const_1), &minutes, &ctxtReal39);
    }
    if (realGreaterEqual(&minutes, cst(OFF_const_60))) {
        realSubOp(&minutes, cst(OFF_const_60), &minutes, &ctxtReal39);
        realAddOp(&degrees, cst(OFF_const_1), &degrees, &ctxtReal39);
    }

    realDiv(&minutes, cst(OFF_const_60), &minutes, &ctxtReal39);
    realDiv(&seconds, cst(OFF_const_3600), &seconds, &ctxtReal39);

    realAddOp(&degrees, &minutes, &angle, &ctxtReal39);
    realAddOp(&angle, &seconds, &angle, &ctxtReal39);

    if (real34IsNegative(angle_dms)) {
        realSetNegativeSign(&angle);
    }
    realToReal34(&angle, angle_dec);
}

pub export fn real34FromDegToDms(angle_dec: *const real34_t, angle_dms: *real34_t) callconv(.c) void {
    var angle: real_t = undefined;
    var degrees: real_t = undefined;
    var minutes: real_t = undefined;
    var seconds: real_t = undefined;

    real34ToReal(angle_dec, &angle);
    realSetPositiveSign(&angle);

    realToIntegralValue(&angle, &degrees, DEC_ROUND_DOWN, &ctxtReal39);

    realSubOp(&angle, &degrees, &angle, &ctxtReal39);
    realMul(&angle, cst(OFF_const_60), &angle, &ctxtReal39);

    realToIntegralValue(&angle, &minutes, DEC_ROUND_DOWN, &ctxtReal39);

    realSubOp(&angle, &minutes, &angle, &ctxtReal39);
    realMul(&angle, cst(OFF_const_60), &seconds, &ctxtReal39);

    minutes.exponent -= 2; // / 100
    seconds.exponent -= 4; // / 10000

    realAddOp(&degrees, &minutes, &angle, &ctxtReal39);
    realAddOp(&angle, &seconds, &angle, &ctxtReal39);

    if (real34IsNegative(angle_dec)) {
        realSetNegativeSign(&angle);
    }
    realToReal34(&angle, angle_dms);
    checkDms34(angle_dms);
}
