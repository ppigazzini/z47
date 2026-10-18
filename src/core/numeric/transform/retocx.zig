// SPDX-License-Identifier: GPL-3.0-only
const std = @import("std");
const abi = @import("abi");
const consts = abi.constants;
//
// Zig owner for src/c47/mathematics/reToCx.c: the Re->Cx command (combine regY
// and regX into the complex regY + i*regX, rectangular or polar mode), for both
// scalar real/longInteger registers and a pair of real34 matrices. Faithful
// line-by-line translation preserving the exact order of every real_t/real34
// operation (reToCx.txt). Exports fnReToCx with C linkage. The
// EXTRA_INFO_ON_CALC_ERROR sprintf hints become fixed moreInfoOnError strings
// (no-op under TESTSUITE/DMCP).

const runtime = @import("../command_wrappers/runtime.zig");
const math_comparison_reals = @import("../compare/comparison_reals.zig");
const math_runtime_helpers = @import("../command_wrappers/helpers.zig");
const math_transform_complex_helpers = @import("transform_complex_helpers.zig");
const real_t = runtime.real_t;
const cplx_t = runtime.cplx_t;
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
const dtReal34 = runtime.dtReal34;
const dtLongInteger = runtime.dtLongInteger;
const dtComplex34 = runtime.dtComplex34;
const dtReal34Matrix = runtime.dtReal34Matrix;

const FLAG_CPXRES: i32 = 0x8004;
const FLAG_POLAR: i32 = 0x8006;
const FLAG_ASLIFT: i32 = 0xc023;
const NOPARAM: u16 = 9876;

inline fn const34_0() *align(1) const real34_t {
    return consts.q16200();
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

// real34ToReal with a register-resident (unaligned) real34 source.
extern fn decimal128ToNumber(source: *align(1) const real34_t, destination: *real_t) *real_t;
inline fn real34ToReal(source: *align(1) const real34_t, destination: *real_t) void {
    _ = decimal128ToNumber(source, destination);
}
extern fn convertRealToReal34ResultRegister(real: *const real_t, dest: calcRegister_t) void;

const displayCalcErrorMessage = runtime.displayCalcErrorMessage;
const moreInfoOnError = runtime.moreInfoOnError;

const std_cross = "\x80\xd7"; // STD_CROSS

// ERROR_MESSAGE_LENGTH is 512 (defines.h); upstream formats these hints into
// the shared errorMessage buffer of that size.
const ERROR_MESSAGE_LENGTH = 512;

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
    var reducedLongAngle: real_t = undefined;
    var longAngleWasReduced = false;

    if ((dataTypeX == dtReal34 or dataTypeX == dtLongInteger) and (dataTypeY == dtReal34 or dataTypeY == dtLongInteger)) {
        if (runtime.getSystemFlag(FLAG_POLAR)) { // polar mode
            if (dataTypeX == dtReal34 and runtime.getRegisterAngularMode(REGISTER_X) != amNone) {
                tempAngle = runtime.getRegisterAngularMode(REGISTER_X);
            } else if (dataTypeX == dtLongInteger) {
                // a long integer angle is reduced by the turn of the current unit before the stack moves
                if (!runtime.getRegisterAsRealAngle(REGISTER_X, &reducedLongAngle, &tempAngle, true) or runtime.lastErrorCode != ERROR_NONE) {
                    return;
                }
                longAngleWasReduced = true;
            }
        }

        if (!runtime.saveLastX()) {
            return;
        }

        runtime.fnSetFlag(FLAG_CPXRES);
        runtime.fnRefreshState(); //drJM

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
            if (math_comparison_reals.real34CompareEqual(VARIABLE_REAL34_DATA(&temp), const34_0())) {
                real34SetZero(REGISTER_REAL34_DATA(REGISTER_X));
                real34SetZero(REGISTER_IMAG34_DATA(REGISTER_X));
            } else {
                var z: cplx_t = undefined;

                real34ToReal(VARIABLE_REAL34_DATA(&temp), z.mag());
                if (longAngleWasReduced) {
                    z.arg().* = reducedLongAngle;
                } else {
                    real34ToReal(VARIABLE_IMAG34_DATA(&temp), z.arg());
                }
                math_transform_complex_helpers.realPolarToRectangularInUnit(z.constMag(), z.constArg(), tempAngle, &z, &runtime.ctxtReal39);
                convertRealToReal34ResultRegister(&z.Real, REGISTER_X);
                runtime.convertRealToImag34ResultRegister(&z.Imag, REGISTER_X);
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
        if (runtime.lastErrorCode != 0) {
            return;
        }

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
                        if (math_comparison_reals.real34CompareEqual(VARIABLE_REAL34_DATA(&cElems[i]), const34_0())) {
                            real34SetZero(VARIABLE_REAL34_DATA(&cElems[i]));
                            real34SetZero(VARIABLE_IMAG34_DATA(&cElems[i]));
                        } else {
                            var z: cplx_t = undefined;

                            real34ToReal(VARIABLE_REAL34_DATA(&cElems[i]), z.mag());
                            real34ToReal(VARIABLE_IMAG34_DATA(&cElems[i]), z.arg());
                            math_transform_complex_helpers.realPolarToRectangularInUnit(z.constMag(), z.constArg(), runtime.currentAngularMode, &z, &runtime.ctxtReal39);
                            math_runtime_helpers.realToReal34(&z.Real, VARIABLE_REAL34_DATA(&cElems[i]));
                            math_runtime_helpers.realToReal34(&z.Imag, VARIABLE_IMAG34_DATA(&cElems[i]));
                        }
                    }
                }
                runtime.convertComplex34MatrixToComplex34MatrixRegister(&cMat, REGISTER_X);
                runtime.complexMatrixFree(&cMat);
            } else {
                displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE);
            }
        } else {
            displayCalcErrorMessage(ERROR_MATRIX_MISMATCH, ERR_REGISTER_LINE);
            if (runtime.extra_info_on_calc_error) {
                var buffer: [ERROR_MESSAGE_LENGTH]u8 = undefined;
                const message = runtime.bufPrintZ(&buffer, "cannot Re->Cx {d}" ++ std_cross ++ "{d}-matrix and {d}" ++ std_cross ++ "{d} -matrix", .{
                    rMat.header.matrixRows,
                    rMat.header.matrixColumns,
                    iMat.header.matrixRows,
                    iMat.header.matrixColumns,
                }) catch "";
                moreInfoOnError("In function fnReToCx:", message, null, null);
            }
        }

        runtime.realMatrixFree(&iMat);
        if (runtime.lastErrorCode == ERROR_NONE) {
            runtime.fnDropY(NOPARAM);
            runtime.setSystemFlag(FLAG_ASLIFT);
        }
    } else {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE); // Invalid input data type for this operation
        if (runtime.extra_info_on_calc_error) {
            var buffer: [ERROR_MESSAGE_LENGTH]u8 = undefined;
            const x_name = std.mem.span(runtime.getRegisterDataTypeName(REGISTER_X, true, false));
            const y_name = std.mem.span(runtime.getRegisterDataTypeName(REGISTER_Y, true, false));
            const message = runtime.bufPrintZ(&buffer, "You cannot use Re->Cx with {s} in X and {s} in Y!", .{ x_name, y_name }) catch "";
            moreInfoOnError("In function fnReToCx:", message, null, null);
        }
    }
}
