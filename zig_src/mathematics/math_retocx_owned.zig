// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/mathematics/reToCx.c: the Re->Cx command (combine regY
// and regX into the complex regY + i*regX, rectangular or polar mode), for both
// scalar real/longInteger registers and a pair of real34 matrices. Faithful
// line-by-line translation preserving the exact order of every real_t/real34
// operation (reToCx.txt). Exports fnReToCx with C linkage. The
// EXTRA_INFO_ON_CALC_ERROR sprintf hints become fixed moreInfoOnError strings
// (no-op under TESTSUITE/DMCP).

const runtime = @import("math_command_wrappers_runtime.zig");

const real_t = runtime.real_t;
const real34_t = runtime.real34_t;
const complex34_t = runtime.complex34_t;
const real34Matrix_t = runtime.real34Matrix_t;
const complex34Matrix_t = runtime.complex34Matrix_t;
const angularMode_t = runtime.angularMode_t;
const calcRegister_t = runtime.calcRegister_t;

const REGISTER_X = runtime.REGISTER_X;
const REGISTER_Y = runtime.REGISTER_Y;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const NIM_REGISTER_LINE: calcRegister_t = REGISTER_X;
const ERROR_NONE = runtime.ERROR_NONE;
const ERROR_RAM_FULL = runtime.ERROR_RAM_FULL;
const ERROR_MATRIX_MISMATCH = runtime.ERROR_MATRIX_MISMATCH;
const ERROR_INVALID_DATA_TYPE_FOR_OP = runtime.ERROR_INVALID_DATA_TYPE_FOR_OP;
const amNone = runtime.amNone;
const amRadian = runtime.amRadian;
const dtReal34 = runtime.dtReal34;
const dtLongInteger = runtime.dtLongInteger;
const dtComplex34 = runtime.dtComplex34;
const dtReal34Matrix = runtime.dtReal34Matrix;

const FLAG_CPXRES: i32 = 0x8004;
const FLAG_POLAR: i32 = 0x8006;
const FLAG_ASLIFT: i32 = 0xc023;
const NOPARAM: u16 = 9876;

const realAdd = runtime.realAdd;
const realSetPositiveSign = runtime.realSetPositiveSign;
extern fn realToReal34(source: *const real_t, destination: *align(1) real34_t) void;

// Runtime const accessors / blob offsets.
inline fn const_0() *const real_t {
    return runtime.z47_math_wrappers_const_0();
}
const constants = @extern([*]const u8, .{ .name = "constants" });
const OFF_const39_pi: u32 = 1848;
const OFF_const34_0: u32 = 15692;
inline fn const39_pi() *align(1) const real_t {
    return @ptrCast(constants + OFF_const39_pi);
}
inline fn const34_0() *align(1) const real34_t {
    return @ptrCast(constants + OFF_const34_0);
}

// real34Copy: copy the 16 raw bytes (two u64 stores in C).
inline fn real34Copy(source: *align(1) const real34_t, destination: *align(1) real34_t) void {
    const src: *align(1) const [2]u64 = @ptrCast(source);
    const dst: *align(1) [2]u64 = @ptrCast(destination);
    dst[0] = src[0];
    dst[1] = src[1];
}
// complex34Copy: copy the 32 raw bytes (four u64 stores in C).
inline fn complex34Copy(source: *align(1) const complex34_t, destination: *align(1) complex34_t) void {
    const src: *align(1) const [4]u64 = @ptrCast(source);
    const dst: *align(1) [4]u64 = @ptrCast(destination);
    dst[0] = src[0];
    dst[1] = src[1];
    dst[2] = src[2];
    dst[3] = src[3];
}
extern fn decQuadZero(destination: *align(1) real34_t) *align(1) real34_t;
inline fn real34SetZero(destination: *align(1) real34_t) void {
    _ = decQuadZero(destination);
}
extern fn real34CompareEqual(number1: *align(1) const real34_t, number2: *align(1) const real34_t) bool;

extern fn realCompareLessThan(number1: *const real_t, number2: *const real_t) bool;
extern fn convertAngleFromTo(angle: *real_t, from_angular_mode: angularMode_t, to_angular_mode: angularMode_t, real_context: *runtime.realContext_t) void;
extern fn convertAngle34FromTo(angle: *align(1) real34_t, from_mode: angularMode_t, to_mode: angularMode_t) void;

// real34ToReal with a register-resident (unaligned) real34 source.
extern fn decimal128ToNumber(source: *align(1) const real34_t, destination: *real_t) *real_t;
inline fn real34ToReal(source: *align(1) const real34_t, destination: *real_t) void {
    _ = decimal128ToNumber(source, destination);
}
// realAdd with a blob-aligned operand (const39_pi).
extern fn decNumberAdd(result: *real_t, lhs: *align(1) const real_t, rhs: *align(1) const real_t, ctxt: *runtime.realContext_t) *real_t;
inline fn realAddB(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *real_t, ctxt: *runtime.realContext_t) void {
    _ = decNumberAdd(res, op1, op2, ctxt);
}
extern fn realPolarToRectangular(magnitude: *const real_t, angle: *const real_t, real: *real_t, imag: *real_t, real_context: *runtime.realContext_t) void;
extern fn mod2Pi(x: *const real_t, result: *real_t, real_context: *runtime.realContext_t) void;
extern fn convertRealToReal34ResultRegister(real: *const real_t, dest: calcRegister_t) void;

const displayCalcErrorMessage = runtime.displayCalcErrorMessage;
const moreInfoOnError = runtime.moreInfoOnError;

inline fn REGISTER_REAL34_DATA(reg: calcRegister_t) *align(1) real34_t {
    return runtime.registerReal34Ptr(reg);
}
inline fn REGISTER_IMAG34_DATA(reg: calcRegister_t) *align(1) real34_t {
    return runtime.registerImag34Ptr(reg);
}
inline fn REGISTER_COMPLEX34_DATA(reg: calcRegister_t) *align(1) complex34_t {
    return runtime.registerComplex34Ptr(reg);
}
inline fn VARIABLE_REAL34_DATA(elem: *align(1) complex34_t) *align(1) real34_t {
    return &elem.real;
}
inline fn VARIABLE_IMAG34_DATA(elem: *align(1) complex34_t) *align(1) real34_t {
    return &elem.imag;
}
inline fn realMatrixElements(mat: *real34Matrix_t) [*]align(1) real34_t {
    if (runtime.harness_surface_is_fake) {
        return @ptrCast(&mat.matrixElements);
    } else {
        return @ptrCast(mat.matrixElements);
    }
}
inline fn complexMatrixElements(mat: *complex34Matrix_t) [*]align(1) complex34_t {
    if (runtime.harness_surface_is_fake) {
        return @ptrCast(&mat.matrixElements);
    } else {
        return @ptrCast(mat.matrixElements);
    }
}

pub export fn fnReToCx(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var tempAngle: angularMode_t = runtime.currentAngularMode;
    const dataTypeX = runtime.getRegisterDataType(REGISTER_X);
    const dataTypeY = runtime.getRegisterDataType(REGISTER_Y);
    var xIsAReal: bool = undefined;

    if ((dataTypeX == dtReal34 or dataTypeX == dtLongInteger) and (dataTypeY == dtReal34 or dataTypeY == dtLongInteger)) {
        if (!runtime.saveLastX()) {
            return;
        }

        runtime.fnSetFlag(FLAG_CPXRES);
        runtime.fnRefreshState(); //drJM

        xIsAReal = true;
        if (runtime.getSystemFlag(FLAG_POLAR)) { // polar mode
            if (dataTypeX == dtReal34 and runtime.getRegisterAngularMode(REGISTER_X) != amNone) {
                tempAngle = runtime.getRegisterAngularMode(REGISTER_X);
                convertAngle34FromTo(REGISTER_REAL34_DATA(REGISTER_X), runtime.getRegisterAngularMode(REGISTER_X), amRadian);
                runtime.setRegisterAngularMode(REGISTER_X, amNone);
                xIsAReal = false;
            }
        }

        if (dataTypeX == dtLongInteger) {
            runtime.convertLongIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
        }

        if (dataTypeY == dtLongInteger) {
            runtime.convertLongIntegerRegisterToReal34Register(REGISTER_Y, REGISTER_Y);
        }

        var temp: complex34_t = undefined;

        real34Copy(REGISTER_REAL34_DATA(REGISTER_Y), VARIABLE_REAL34_DATA(&temp));
        real34Copy(REGISTER_REAL34_DATA(REGISTER_X), VARIABLE_IMAG34_DATA(&temp));
        runtime.reallocateRegister(REGISTER_X, dtComplex34, 0, amNone);

        if (runtime.getSystemFlag(FLAG_POLAR)) { // polar mode
            if (real34CompareEqual(VARIABLE_REAL34_DATA(&temp), const34_0())) {
                real34SetZero(REGISTER_REAL34_DATA(REGISTER_X));
                real34SetZero(REGISTER_IMAG34_DATA(REGISTER_X));
            } else {
                var magnitude: real_t = undefined;
                var theta: real_t = undefined;

                real34ToReal(VARIABLE_REAL34_DATA(&temp), &magnitude);
                real34ToReal(VARIABLE_IMAG34_DATA(&temp), &theta);
                if (xIsAReal) {
                    convertAngleFromTo(&theta, runtime.currentAngularMode, amRadian, &runtime.ctxtReal39);
                }
                if (realCompareLessThan(&magnitude, const_0())) {
                    realSetPositiveSign(&magnitude);
                    realAddB(&theta, const39_pi(), &theta, &runtime.ctxtReal39);
                    mod2Pi(&theta, &theta, &runtime.ctxtReal39);
                }
                realPolarToRectangular(&magnitude, &theta, &magnitude, &theta, &runtime.ctxtReal39); // theta in radian
                convertRealToReal34ResultRegister(&magnitude, REGISTER_X);
                realToReal34(&theta, REGISTER_IMAG34_DATA(REGISTER_X));
                runtime.setComplexRegisterAngularMode(REGISTER_X, tempAngle);
            }
        } else { // rectangular mode
            complex34Copy(&temp, REGISTER_COMPLEX34_DATA(REGISTER_X));
        }

        runtime.fnDropY(NOPARAM);
        if (runtime.lastErrorCode == ERROR_NONE) {
            runtime.setSystemFlag(FLAG_ASLIFT);
        }
    } else if (dataTypeX == dtReal34Matrix and dataTypeY == dtReal34Matrix) {
        var rMat: real34Matrix_t = undefined;
        var iMat: real34Matrix_t = undefined;
        var cMat: complex34Matrix_t = undefined;

        runtime.linkToRealMatrixRegister(REGISTER_Y, &rMat);
        runtime.convertReal34MatrixRegisterToReal34Matrix(REGISTER_X, &iMat);

        if (rMat.header.matrixRows == iMat.header.matrixRows and rMat.header.matrixColumns == iMat.header.matrixColumns) {
            if (runtime.complexMatrixInit(&cMat, rMat.header.matrixRows, rMat.header.matrixColumns)) {
                if (!runtime.saveLastX()) {
                    return;
                }
                runtime.fnSetFlag(FLAG_CPXRES);

                const rElems = realMatrixElements(&rMat);
                const iElems = realMatrixElements(&iMat);
                const cElems = complexMatrixElements(&cMat);
                var i: u16 = 0;
                while (i < @as(u32, rMat.header.matrixRows) * @as(u32, rMat.header.matrixColumns)) : (i += 1) {
                    real34Copy(&rElems[i], VARIABLE_REAL34_DATA(&cElems[i]));
                    real34Copy(&iElems[i], VARIABLE_IMAG34_DATA(&cElems[i]));

                    if (runtime.getSystemFlag(FLAG_POLAR)) { // polar mode
                        if (real34CompareEqual(VARIABLE_REAL34_DATA(&cElems[i]), const34_0())) {
                            real34SetZero(VARIABLE_IMAG34_DATA(&cElems[i]));
                        } else {
                            var magnitude: real_t = undefined;
                            var theta: real_t = undefined;

                            real34ToReal(VARIABLE_REAL34_DATA(&cElems[i]), &magnitude);
                            real34ToReal(VARIABLE_IMAG34_DATA(&cElems[i]), &theta);
                            convertAngleFromTo(&theta, runtime.currentAngularMode, amRadian, &runtime.ctxtReal39);
                            if (realCompareLessThan(&magnitude, const_0())) {
                                realSetPositiveSign(&magnitude);
                                realAddB(&theta, const39_pi(), &theta, &runtime.ctxtReal39);
                                mod2Pi(&theta, &theta, &runtime.ctxtReal39);
                            }
                            realPolarToRectangular(&magnitude, &theta, &magnitude, &theta, &runtime.ctxtReal39); // theta in radian
                            realToReal34(&magnitude, VARIABLE_REAL34_DATA(&cElems[i]));
                            realToReal34(&theta, VARIABLE_IMAG34_DATA(&cElems[i]));
                        }
                    }
                }
                runtime.convertComplex34MatrixToComplex34MatrixRegister(&cMat, REGISTER_X);
                runtime.complexMatrixFree(&cMat);
            } else {
                displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
            }
        } else {
            displayCalcErrorMessage(ERROR_MATRIX_MISMATCH, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnError("In function fnReToCx:", "cannot Re->Cx matrices of mismatched dimensions", null, null);
        }

        runtime.realMatrixFree(&iMat);
        if (runtime.lastErrorCode == ERROR_NONE) {
            runtime.fnDropY(NOPARAM);
            runtime.setSystemFlag(FLAG_ASLIFT);
        }
    } else {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X); // Invalid input data type for this operation
        moreInfoOnError("In function fnReToCx:", "You cannot use Re->Cx with these data types in X and Y!", null, null);
    }
}
