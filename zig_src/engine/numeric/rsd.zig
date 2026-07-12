// SPDX-License-Identifier: GPL-3.0-only
const abi = @import("abi");
const consts = abi.constants;
const const_0 = consts.const_0;
const const_1on10 = consts.const_1on10;
const const_1 = consts.const_1;
const const_10 = consts.const_10;
const const_60 = consts.const_60;
const const_100 = consts.const_100;
//
// Zig owner for src/c47/mathematics/rsd.c: round-to-significant-digits (RSD).
// Ports rsd.h's roundToSignificantDigits, senaryDigitToDecimal,
// decimalDigitToSenary, fnRsd, rsdError, rsdTime, rsdRema, rsdCxma, rsdReal,
// rsdCplx and the Rsd[] dispatch table. Covered by xfn.txt.
//
// Faithful line-by-line translation preserving the exact order of every real_t
// operation (the testSuite checks results to the last ULP). The
// roundToSignificantDigits subnormal-normalisation loop manipulates
// destination->exponent in place exactly as the C does, and the senary <-> decimal
// time helpers preserve their DEC_ROUND_DOWN / DEC_ROUND_UP integral rounding.
// senaryDigitToDecimal / decimalDigitToSenary are exported (rdp.c's rdpTime
// calls them). The commented-out alternate rsdReal in the C is dropped.

const runtime = @import("command_wrappers_runtime.zig");
const math_real_predicates = @import("real_predicates.zig");
const math_matrix_elementwise = @import("matrix/elementwise.zig"); // M-callconv: Zig-to-Zig

const real_t = runtime.real_t;
const real34_t = runtime.real34_t;
const realContext_t = runtime.realContext_t;
const calcRegister_t = runtime.calcRegister_t;
const rounding_t = runtime.rounding_t;

const REGISTER_X = runtime.REGISTER_X;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const ERROR_INVALID_DATA_TYPE_FOR_OP = runtime.ERROR_INVALID_DATA_TYPE_FOR_OP;
const amDMS = runtime.amDMS;
const amAngleMask = runtime.amAngleMask;

const FLAG_POLAR: i32 = 0x8006;
const DEC_ROUND_UP: rounding_t = 1;
const DEC_ROUND_DOWN: rounding_t = runtime.DEC_ROUND_DOWN;

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
const realIsPositive = math_real_predicates.realIsPositive;

inline fn getRegisterAngularMode(reg: calcRegister_t) u32 {
    return getRegisterTag(reg) & amAngleMask;
}

extern var ctxtReal4: realContext_t;

// real_t op helpers (realType.h macros).
extern fn decNumberCopy(res: *real_t, source: *const real_t) *real_t;
extern fn decNumberCompare(res: *real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberAdd(res: *real_t, op1: *const real_t, op2: *const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberSubtract(res: *real_t, op1: *const real_t, op2: *const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberMultiply(res: *real_t, op1: *const real_t, op2: *const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberDivide(res: *real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberRemainder(res: *real_t, op1: *const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *real_t;
inline fn realCopy(source: *const real_t, destination: *real_t) void {
    _ = decNumberCopy(destination, source);
}
inline fn realCompare(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberCompare(res, op1, op2, ctxt);
}
inline fn realAdd(op1: *const real_t, op2: *const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberAdd(res, op1, op2, ctxt);
}
inline fn realSubtract(op1: *const real_t, op2: *const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberSubtract(res, op1, op2, ctxt);
}
inline fn realMultiply(op1: *const real_t, op2: *const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberMultiply(res, op1, op2, ctxt);
}
inline fn realDivide(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberDivide(res, op1, op2, ctxt);
}
inline fn realDivideRemainder(op1: *const real_t, op2: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberRemainder(res, op1, op2, ctxt);
}

// Blob constants.

// roundingMode / roundingModeTable.
extern var roundingMode: u8;
const roundingModeTable = @extern([*]const c_int, .{ .name = "roundingModeTable" });
inline fn currentRoundingMode() rounding_t {
    return @intCast(roundingModeTable[roundingMode]);
}

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

extern var updateDisplayValueX: bool;
extern var displayValueX: [80]u8;

const REAL34_SIZE_IN_BYTES: u32 = 16;
const registerReal34Data = abi.registerReal34;
const registerImag34Data = abi.registerImag34;

// ===========================================================================
// roundToSignificantDigits
// ===========================================================================
pub export fn roundToSignificantDigits(source: *const real_t, destination: *real_t, digits: u16, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
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
    destination.exponent -= exponent + 1;
    while (true) { // in case of subnormal
        realCompare(destination, const_0(), &sign, &ctxtReal4);
        if (realIsNegative(&sign)) {
            realCompare(destination, const_1on10(), &output, realContext);
            if (realIsPositive(&output)) {
                destination.exponent += 1;
                exponent -= 1;
            } else {
                break;
            }
        } else {
            realCompare(destination, const_1on10(), &output, realContext);
            if (realIsNegative(&output)) {
                destination.exponent += 1;
                exponent -= 1;
            } else {
                break;
            }
        }
    }
    destination.exponent += digits;
    realToIntegralValue(destination, destination, currentRoundingMode(), realContext);
    destination.exponent -= digits;
    destination.exponent += exponent + 1;
}

// ===========================================================================
// rsdError
// ===========================================================================
pub export fn rsdError(unused_but_mandatory_parameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    moreInfoOnError("In function rsdError:", "cannot calculate RSD for the data type in X", null, null);
}

// Rsd[] dispatch table (NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS == 10).
const Rsd = [_]U16Fn{
    rsdError, // Long integer
    rsdReal, // Real34
    rsdCplx, // Complex34
    rsdTime, // Time
    rsdError, // Date
    rsdError, // String
    rsdRema, // Real34 mat
    rsdCxma, // Complex34 mat
    rsdError, // Short integer
    rsdError, // Config data
};

// ===========================================================================
// fnRsd
// ===========================================================================
pub export fn fnRsd(digits: u16) linksection(runtime.code_section) callconv(.c) void {
    if (!saveLastX()) {
        return;
    }

    Rsd[getRegisterDataType(REGISTER_X)].?(digits);

    adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
}

// ===========================================================================
// senaryDigitToDecimal
// ===========================================================================
pub export fn senaryDigitToDecimal(pre_grouped: bool, val: *real_t, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    var sixtieths: real_t = undefined;
    var st: real_t = undefined;
    realDivide(const_100(), const_60(), &st, realContext);

    if (pre_grouped) {
        realDivideRemainder(val, const_10(), &sixtieths, realContext);
    } else {
        realCopy(val, &sixtieths);
    }

    realToIntegralValue(&sixtieths, &sixtieths, DEC_ROUND_DOWN, realContext);
    realSubtract(val, &sixtieths, val, realContext);
    realMultiply(&sixtieths, &st, &sixtieths, realContext);
    realToIntegralValue(&sixtieths, &sixtieths, DEC_ROUND_DOWN, realContext);
    realAdd(val, &sixtieths, val, realContext);
}

// ===========================================================================
// decimalDigitToSenary
// ===========================================================================
pub export fn decimalDigitToSenary(pre_grouped: bool, val: *real_t, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    var sixtieths: real_t = undefined;
    var st: real_t = undefined;
    realDivide(const_60(), const_100(), &st, realContext);

    if (pre_grouped) {
        realDivideRemainder(val, const_10(), &sixtieths, realContext);
    } else {
        realCopy(val, &sixtieths);
    }

    realToIntegralValue(&sixtieths, &sixtieths, DEC_ROUND_DOWN, realContext);
    realSubtract(val, &sixtieths, val, realContext);
    realMultiply(&sixtieths, &st, &sixtieths, realContext);
    realToIntegralValue(&sixtieths, &sixtieths, DEC_ROUND_UP, realContext);
    realAdd(val, &sixtieths, val, realContext);
}

// ===========================================================================
// rsdTime
// ===========================================================================
pub export fn rsdTime(digits: u16) linksection(runtime.code_section) callconv(.c) void {
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
    roundToSignificantDigits(&val, &val, digits, &runtime.ctxtReal39);
    i = 0;
    while (i < 2) : (i += 1) {
        val.exponent += 1;
        decimalDigitToSenary(false, &val, &runtime.ctxtReal39);
        val.exponent += 1;
    }

    realToReal34(&val, registerReal34Data(REGISTER_X));
}

// ===========================================================================
// rsdRema / rsdCxma
// ===========================================================================
pub export fn rsdRema(digits: u16) linksection(runtime.code_section) callconv(.c) void {
    math_matrix_elementwise.elementwiseRema_UInt16(rsdReal, digits);
}

pub export fn rsdCxma(digits: u16) linksection(runtime.code_section) callconv(.c) void {
    math_matrix_elementwise.elementwiseCxma_UInt16(rsdCplx, digits);
}

// ===========================================================================
// rsdReal
// ===========================================================================
pub export fn rsdReal(digits: u16) linksection(runtime.code_section) callconv(.c) void {
    var val: real_t = undefined;

    if (getRegisterAngularMode(REGISTER_X) == amDMS) {
        real34FromDegToDms(registerReal34Data(REGISTER_X), registerReal34Data(REGISTER_X));
        checkDms34(registerReal34Data(REGISTER_X));
    }

    real34ToReal(registerReal34Data(REGISTER_X), &val);
    roundToSignificantDigits(&val, &val, digits, &runtime.ctxtReal39);
    convertRealToReal34ResultRegister(&val, REGISTER_X);

    if (getRegisterAngularMode(REGISTER_X) == amDMS) {
        real34FromDmsToDeg(registerReal34Data(REGISTER_X), registerReal34Data(REGISTER_X));
    }
}

// ===========================================================================
// rsdCplx
// ===========================================================================
pub export fn rsdCplx(digits: u16) linksection(runtime.code_section) callconv(.c) void {
    if (getSystemFlag(FLAG_POLAR)) {
        var magnitude: real_t = undefined;
        var theta: real_t = undefined;
        real34ToReal(registerReal34Data(REGISTER_X), &magnitude);
        real34ToReal(registerImag34Data(REGISTER_X), &theta);
        realRectangularToPolar(&magnitude, &theta, &magnitude, &theta, &runtime.ctxtReal39);
        roundToSignificantDigits(&magnitude, &magnitude, digits, &runtime.ctxtReal39);
        roundToSignificantDigits(&theta, &theta, digits, &runtime.ctxtReal39);
        realPolarToRectangular(&magnitude, &theta, &magnitude, &theta, &runtime.ctxtReal39);
        convertComplexToResultRegister(&magnitude, &theta, REGISTER_X);
    } else {
        var real: real_t = undefined;
        var imaginary: real_t = undefined;
        real34ToReal(registerReal34Data(REGISTER_X), &real);
        real34ToReal(registerImag34Data(REGISTER_X), &imaginary);
        roundToSignificantDigits(&real, &real, digits, &runtime.ctxtReal39);
        roundToSignificantDigits(&imaginary, &imaginary, digits, &runtime.ctxtReal39);
        convertComplexToResultRegister(&real, &imaginary, REGISTER_X);
    }
}
