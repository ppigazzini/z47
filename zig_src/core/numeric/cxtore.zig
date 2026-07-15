// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/mathematics/cxToRe.c: the Cx->Re command (split a complex
// value into its two real parts, real/imag in rectangular mode or
// magnitude/angle in polar mode), for both a single complex34 register and a
// complex34 matrix. Faithful line-by-line translation preserving the exact order
// of every real34 operation (cxToRe.txt). Exports fnCxToRe with C linkage. The
// EXTRA_INFO_ON_CALC_ERROR sprintf hint becomes a fixed moreInfoOnError string
// (no-op under TESTSUITE/DMCP).

const runtime = @import("command_wrappers/runtime.zig");
const math_transform_complex_helpers = @import("transform/transform_complex_helpers.zig");
const real34_t = runtime.real34_t;
const complex34Matrix_t = runtime.complex34Matrix_t;
const real34Matrix_t = runtime.real34Matrix_t;
const angularMode_t = runtime.angularMode_t;
const calcRegister_t = runtime.calcRegister_t;

const REGISTER_X = runtime.REGISTER_X;
const REGISTER_Y = runtime.REGISTER_Y;
const REGISTER_L = runtime.REGISTER_L;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const NIM_REGISTER_LINE: calcRegister_t = REGISTER_X;
const ERROR_RAM_FULL = runtime.ERROR_RAM_FULL;
const ERROR_INVALID_DATA_TYPE_FOR_OP = runtime.ERROR_INVALID_DATA_TYPE_FOR_OP;
const amNone = runtime.amNone;
const amRadian = runtime.amRadian;
const dtReal34 = runtime.dtReal34;
const dtComplex34 = runtime.dtComplex34;
const dtComplex34Matrix = runtime.dtComplex34Matrix;
const FLAG_ASLIFT: i32 = 0xc023;
const FLAG_POLAR: i32 = 0x8006;

const TI_THETA_RADIUS: u8 = 3;
const TI_RE_IM: u8 = 6;

// real34Copy(source, destination): copy the 16 raw bytes (two u64 stores in C).
inline fn real34Copy(source: *align(1) const real34_t, destination: *align(1) real34_t) void {
    const src: *align(1) const [2]u64 = @ptrCast(source);
    const dst: *align(1) [2]u64 = @ptrCast(destination);
    dst[0] = src[0];
    dst[1] = src[1];
}

extern fn convertAngle34FromTo(angle: *align(1) real34_t, from_mode: angularMode_t, to_mode: angularMode_t) void;

const displayCalcErrorMessage = runtime.displayCalcErrorMessage;
const moreInfoOnError = runtime.moreInfoOnError;

inline fn REGISTER_REAL34_DATA(reg: calcRegister_t) *align(1) real34_t {
    return runtime.registerReal34Ptr(reg);
}
inline fn REGISTER_IMAG34_DATA(reg: calcRegister_t) *align(1) real34_t {
    return runtime.registerImag34Ptr(reg);
}
inline fn VARIABLE_REAL34_DATA(elem: *align(1) runtime.complex34_t) *align(1) real34_t {
    return &elem.real;
}
inline fn VARIABLE_IMAG34_DATA(elem: *align(1) runtime.complex34_t) *align(1) real34_t {
    return &elem.imag;
}

inline fn complexMatrixElements(mat: *complex34Matrix_t) [*]align(1) runtime.complex34_t {
    if (runtime.harness_surface_is_fake) {
        return @ptrCast(&mat.matrixElements);
    } else {
        return @ptrCast(mat.matrixElements);
    }
}
inline fn realMatrixElements(mat: *real34Matrix_t) [*]align(1) real34_t {
    if (runtime.harness_surface_is_fake) {
        return @ptrCast(&mat.matrixElements);
    } else {
        return @ptrCast(mat.matrixElements);
    }
}

pub export fn fnCxToRe(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    const dataTypeX = runtime.getRegisterDataType(REGISTER_X);
    var tempAngle: angularMode_t = runtime.currentAngularMode;

    if (dataTypeX == dtComplex34) {
        if (!runtime.saveLastX()) {
            return;
        }
        runtime.reallocateRegister(REGISTER_X, dtReal34, 0, amNone);

        runtime.setSystemFlag(FLAG_ASLIFT);
        if (runtime.getComplexRegisterPolarMode(REGISTER_L) != 0) { // polar mode
            if (runtime.getComplexRegisterAngularMode(REGISTER_L) != amNone) {
                tempAngle = runtime.getComplexRegisterAngularMode(REGISTER_L);
            }
            runtime.liftStack();
            runtime.reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
            math_transform_complex_helpers.real34RectangularToPolar(REGISTER_REAL34_DATA(REGISTER_L), REGISTER_IMAG34_DATA(REGISTER_L), REGISTER_REAL34_DATA(REGISTER_Y), REGISTER_REAL34_DATA(REGISTER_X)); // X in radians
            convertAngle34FromTo(REGISTER_REAL34_DATA(REGISTER_X), amRadian, tempAngle);
            runtime.setRegisterAngularMode(REGISTER_X, tempAngle);
            runtime.temporaryInformation = TI_THETA_RADIUS;
        } else { // rectangular mode
            real34Copy(REGISTER_REAL34_DATA(REGISTER_L), REGISTER_REAL34_DATA(REGISTER_X));
            runtime.liftStack();
            runtime.reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
            real34Copy(REGISTER_IMAG34_DATA(REGISTER_L), REGISTER_REAL34_DATA(REGISTER_X));
            runtime.temporaryInformation = TI_RE_IM;
        }
    } else if (dataTypeX == dtComplex34Matrix) {
        var cMat: complex34Matrix_t = undefined;
        var rMat: real34Matrix_t = undefined;
        var iMat: real34Matrix_t = undefined;

        if (!runtime.saveLastX()) {
            return;
        }

        runtime.linkToComplexMatrixRegister(REGISTER_X, &cMat);
        if (runtime.realMatrixInit(&rMat, cMat.header.matrixRows, cMat.header.matrixColumns)) {
            if (runtime.realMatrixInit(&iMat, cMat.header.matrixRows, cMat.header.matrixColumns)) {
                const cElems = complexMatrixElements(&cMat);
                const rElems = realMatrixElements(&rMat);
                const iElems = realMatrixElements(&iMat);
                var i: u16 = 0;
                while (i < @as(u32, cMat.header.matrixRows) * @as(u32, cMat.header.matrixColumns)) : (i += 1) {
                    if (runtime.getSystemFlag(FLAG_POLAR)) { // polar mode
                        math_transform_complex_helpers.real34RectangularToPolar(VARIABLE_REAL34_DATA(&cElems[i]), VARIABLE_IMAG34_DATA(&cElems[i]), &rElems[i], &iElems[i]);
                        convertAngle34FromTo(&iElems[i], amRadian, runtime.currentAngularMode);
                    } else { // rectangular mode
                        real34Copy(VARIABLE_REAL34_DATA(&cElems[i]), &rElems[i]);
                        real34Copy(VARIABLE_IMAG34_DATA(&cElems[i]), &iElems[i]);
                    }
                }

                runtime.setSystemFlag(FLAG_ASLIFT);
                runtime.liftStack();
                runtime.convertReal34MatrixToReal34MatrixRegister(&rMat, REGISTER_Y);
                runtime.convertReal34MatrixToReal34MatrixRegister(&iMat, REGISTER_X);
                runtime.realMatrixFree(&iMat);
            } else {
                displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
            }
            runtime.realMatrixFree(&rMat);
        } else {
            displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
        }
    } else {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X); // Invalid input data type for this operation
        moreInfoOnError("In function fnCxToRe:", "You cannot use Cx->Re with this data type in X!", null, null);
    }
}
