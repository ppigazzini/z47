// SPDX-License-Identifier: GPL-3.0-only
const abi = @import("abi");
const consts = abi.constants;
const const_0 = consts.const_0;
const const__1 = consts.const__1;
const const_1 = consts.const_1;
//
// Zig owner for src/c47/mathematics/rdp.c: round-to-decimal-places (RDP). Ports
// rdp.h's roundToDecimalPlace, fnRdp, rdpError, rdpTime, rdpRema, rdpCxma,
// rdpReal, rdpCplx and the Rdp[] dispatch table. Covered by xfn.txt.
//
// Faithful line-by-line translation preserving the exact order of every real_t
// operation (the testSuite checks results to the last ULP). roundToDecimalPlace
// manipulates destination->exponent in place, so the subnormal-normalisation
// loop and the integral-value rounding (roundingModeTable[roundingMode]) are
// reproduced exactly. The commented-out alternate rdpReal in the C is dropped.
// EXTRA_INFO_ON_CALC_ERROR sprintf hints become fixed moreInfoOnError strings.

const runtime = @import("math_command_wrappers_runtime.zig");

const real_t = runtime.real_t;
const real34_t = runtime.real34_t;
const realContext_t = runtime.realContext_t;
const calcRegister_t = runtime.calcRegister_t;
const angularMode_t = runtime.angularMode_t;
const rounding_t = runtime.rounding_t;

const REGISTER_X = runtime.REGISTER_X;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const ERROR_INVALID_DATA_TYPE_FOR_OP = runtime.ERROR_INVALID_DATA_TYPE_FOR_OP;
const amDMS = runtime.amDMS;
const amAngleMask = runtime.amAngleMask;
const dtLongInteger = runtime.dtLongInteger;
const dtReal34 = runtime.dtReal34;
const dtComplex34 = runtime.dtComplex34;
const dtTime = runtime.dtTime;
const dtDate = runtime.dtDate;
const dtString = runtime.dtString;
const dtReal34Matrix = runtime.dtReal34Matrix;
const dtComplex34Matrix = runtime.dtComplex34Matrix;
const dtShortInteger = runtime.dtShortInteger;
const dtConfig = runtime.dtConfig;

const FLAG_POLAR: i32 = 0x8006;

const displayCalcErrorMessage = runtime.displayCalcErrorMessage;
const moreInfoOnError = runtime.moreInfoOnError;
const saveLastX = runtime.saveLastX;
const adjustResult = runtime.adjustResult;
const getRegisterDataType = runtime.getRegisterDataType;
const getRegisterTag = runtime.getRegisterTag;
const getSystemFlag = runtime.getSystemFlag;
const getRegisterDataPointer = runtime.getRegisterDataPointer;
const realToIntegralValue = runtime.realToIntegralValue;
const realRectangularToPolar = runtime.realRectangularToPolar;
const realPolarToRectangular = runtime.realPolarToRectangular;
const convertRealToReal34ResultRegister = runtime.convertRealToReal34ResultRegister;
const convertComplexToResultRegister = runtime.convertComplexToResultRegister;
extern fn refreshRegisterLine(regist: calcRegister_t) void;
const realIsZero = runtime.realIsZero;
const realIsSpecial = runtime.realIsSpecial;
const realIsNegative = runtime.realIsNegative;
inline fn realIsPositive(source: *const real_t) bool {
    return (source.bits & 0x80) == 0x00;
}

inline fn getRegisterAngularMode(reg: calcRegister_t) u32 {
    return getRegisterTag(reg) & amAngleMask;
}

// Contexts. ctxtReal4 is the dedicated 4-digit context used by the subnormal
// loop's sign comparison; it is a distinct global from ctxtReal34/ctxtReal39.
extern var ctxtReal4: realContext_t;
const ctxtReal39 = &runtime.ctxtReal39;

// real_t op helpers (realType.h macros).
extern fn decNumberCopy(res: *real_t, source: *const real_t) *real_t;
extern fn decNumberCompare(res: *real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *real_t;
inline fn realCopy(source: *const real_t, destination: *real_t) void {
    _ = decNumberCopy(destination, source);
}
inline fn realCompare(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberCompare(res, op1, op2, ctxt);
}

// Blob constants.

// roundingMode / roundingModeTable.
extern var roundingMode: u8;
const roundingModeTable = @extern([*]const c_int, .{ .name = "roundingModeTable" });
inline fn currentRoundingMode() rounding_t {
    return @intCast(roundingModeTable[roundingMode]);
}

// rsd.c (sibling owner) provides these for the time path.
extern fn senaryDigitToDecimal(pre_grouped: bool, val: *real_t, realContext: *realContext_t) void;
extern fn decimalDigitToSenary(pre_grouped: bool, val: *real_t, realContext: *realContext_t) void;

// Register data / real34 conversion.
extern fn decimal128ToNumber(source: *align(1) const real34_t, destination: *real_t) *real_t;
inline fn real34ToReal(source: *align(1) const real34_t, destination: *real_t) void {
    _ = decimal128ToNumber(source, destination);
}
extern fn decimal128FromNumber(destination: *align(1) real34_t, source: *const real_t, ctxt: *realContext_t) *align(1) real34_t;
inline fn realToReal34(source: *const real_t, destination: *align(1) real34_t) void {
    _ = decimal128FromNumber(destination, source, &runtime.ctxtReal34);
}

extern fn real34FromDegToDms(angleDec: *align(1) const real34_t, angleDms: *align(1) real34_t) void;
extern fn real34FromDmsToDeg(angleDms: *align(1) const real34_t, angleDec: *align(1) real34_t) void;
extern fn checkDms34(angle34Dms: *align(1) real34_t) void;

const U16Fn = ?*const fn (u16) callconv(.c) void;
extern fn elementwiseRema_UInt16(f: U16Fn, param: u16) void;
extern fn elementwiseCxma_UInt16(f: U16Fn, param: u16) void;

extern var updateDisplayValueX: bool;
extern var displayValueX: [80]u8;

const REAL34_SIZE_IN_BYTES: u32 = 16;
inline fn registerReal34Data(reg: calcRegister_t) *align(1) real34_t {
    return @ptrCast(getRegisterDataPointer(reg).?);
}
inline fn registerImag34Data(reg: calcRegister_t) *align(1) real34_t {
    const base: [*]u8 = @ptrCast(getRegisterDataPointer(reg).?);
    return @ptrCast(base + REAL34_SIZE_IN_BYTES);
}

// ===========================================================================
// roundToDecimalPlace
// ===========================================================================
pub export fn roundToDecimalPlace(source: *const real_t, destination: *real_t, digits: u16, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    var sign: real_t = undefined;
    var output: real_t = undefined;
    var exponent: i32 = undefined;

    if (realIsZero(source) or realIsSpecial(source)) {
        if (@intFromPtr(source) != @intFromPtr(destination)) {
            realCopy(source, destination);
        }
        return;
    }

    if (@intFromPtr(source) != @intFromPtr(destination)) {
        realCopy(source, destination);
    }

    exponent = destination.digits + destination.exponent - 1;
    destination.exponent -= exponent;

    while (true) { // in case of subnormal
        realCompare(destination, const_0(), &sign, &ctxtReal4);
        if (realIsNegative(&sign)) {
            realCompare(destination, const__1(), &output, realContext);
            if (realIsPositive(&output)) {
                destination.exponent += 1;
                exponent -= 1;
            } else {
                break;
            }
        } else {
            realCompare(destination, const_1(), &output, realContext);
            if (realIsNegative(&output)) {
                destination.exponent += 1;
                exponent -= 1;
            } else {
                break;
            }
        }
    }

    destination.exponent += exponent;
    destination.exponent += digits;
    realToIntegralValue(destination, destination, currentRoundingMode(), realContext);
    destination.exponent -= digits;
}

// ===========================================================================
// rdpError
// ===========================================================================
pub export fn rdpError(unused_but_mandatory_parameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    moreInfoOnError("In function rdpError:", "cannot calculate RDP for the data type in X", null, null);
}

// Rdp[] dispatch table (NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS == 10).
const Rdp = [_]U16Fn{
    rdpError, // Long integer
    rdpReal, // Real34
    rdpCplx, // Complex34
    rdpTime, // Time
    rdpError, // Date
    rdpError, // String
    rdpRema, // Real34 mat
    rdpCxma, // Complex34 mat
    rdpError, // Short integer
    rdpError, // Config data
};

// ===========================================================================
// fnRdp
// ===========================================================================
pub export fn fnRdp(digits: u16) linksection(runtime.code_section) callconv(.c) void {
    if (!saveLastX()) {
        return;
    }

    Rdp[getRegisterDataType(REGISTER_X)].?(digits);

    adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
}

// ===========================================================================
// rdpTime
// ===========================================================================
pub export fn rdpTime(digits: u16) linksection(runtime.code_section) callconv(.c) void {
    var val: real_t = undefined;
    var i: i32 = undefined;

    updateDisplayValueX = true;
    displayValueX[0] = 0;
    refreshRegisterLine(REGISTER_X);
    updateDisplayValueX = false;

    real34ToReal(registerReal34Data(REGISTER_X), &val);

    i = 0;
    while (i < 2) : (i += 1) {
        val.exponent -= 1;
        senaryDigitToDecimal(false, &val, &runtime.ctxtReal39);
        val.exponent -= 1;
    }
    roundToDecimalPlace(&val, &val, digits, &runtime.ctxtReal39);
    i = 0;
    while (i < 2) : (i += 1) {
        val.exponent += 1;
        decimalDigitToSenary(false, &val, &runtime.ctxtReal39);
        val.exponent += 1;
    }

    realToReal34(&val, registerReal34Data(REGISTER_X));
}

// ===========================================================================
// rdpRema / rdpCxma
// ===========================================================================
pub export fn rdpRema(digits: u16) linksection(runtime.code_section) callconv(.c) void {
    elementwiseRema_UInt16(rdpReal, digits);
}

pub export fn rdpCxma(digits: u16) linksection(runtime.code_section) callconv(.c) void {
    elementwiseCxma_UInt16(rdpCplx, digits);
}

// ===========================================================================
// rdpReal
// ===========================================================================
pub export fn rdpReal(digits: u16) linksection(runtime.code_section) callconv(.c) void {
    var val: real_t = undefined;

    if (getRegisterAngularMode(REGISTER_X) == amDMS) {
        real34FromDegToDms(registerReal34Data(REGISTER_X), registerReal34Data(REGISTER_X));
        checkDms34(registerReal34Data(REGISTER_X));
    }

    real34ToReal(registerReal34Data(REGISTER_X), &val);
    roundToDecimalPlace(&val, &val, digits, &runtime.ctxtReal39);
    convertRealToReal34ResultRegister(&val, REGISTER_X);

    if (getRegisterAngularMode(REGISTER_X) == amDMS) {
        real34FromDmsToDeg(registerReal34Data(REGISTER_X), registerReal34Data(REGISTER_X));
    }
}

// ===========================================================================
// rdpCplx
// ===========================================================================
pub export fn rdpCplx(digits: u16) linksection(runtime.code_section) callconv(.c) void {
    if (getSystemFlag(FLAG_POLAR)) {
        var magnitude: real_t = undefined;
        var theta: real_t = undefined;
        real34ToReal(registerReal34Data(REGISTER_X), &magnitude);
        real34ToReal(registerImag34Data(REGISTER_X), &theta);
        realRectangularToPolar(&magnitude, &theta, &magnitude, &theta, &runtime.ctxtReal39);
        roundToDecimalPlace(&magnitude, &magnitude, digits, &runtime.ctxtReal39);
        roundToDecimalPlace(&theta, &theta, digits, &runtime.ctxtReal39);
        realPolarToRectangular(&magnitude, &theta, &magnitude, &theta, &runtime.ctxtReal39);
        convertComplexToResultRegister(&magnitude, &theta, REGISTER_X);
    } else {
        var real: real_t = undefined;
        var imaginary: real_t = undefined;
        real34ToReal(registerReal34Data(REGISTER_X), &real);
        real34ToReal(registerImag34Data(REGISTER_X), &imaginary);
        roundToDecimalPlace(&real, &real, digits, &runtime.ctxtReal39);
        roundToDecimalPlace(&imaginary, &imaginary, digits, &runtime.ctxtReal39);
        convertComplexToResultRegister(&real, &imaginary, REGISTER_X);
    }
}

comptime {
    _ = dtLongInteger;
    _ = dtReal34;
    _ = dtComplex34;
    _ = dtTime;
    _ = dtDate;
    _ = dtString;
    _ = dtReal34Matrix;
    _ = dtComplex34Matrix;
    _ = dtShortInteger;
    _ = dtConfig;
    _ = ctxtReal39;
}
