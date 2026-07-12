// Zig port of the residual OPTION_VECTOR command surface of
// src/c47/mathematics/matrix.c: is_2D3D_Register_Ready (classifies the X/Y/Z
// stack as polar/2D-rect/spherical/cylindrical/3D-rect input) and the
// V3RectoToSph / V3RectoToCyl commands that convert a 3D rectangular vector to
// spherical / cylindrical form. is_2D3D_Register_Ready is public (other units
// call it); the V3Recto* commands are public too -> all three bridge-renamed.
const std = @import("std");
const runtime = @import("../command_wrappers_runtime.zig");
const math_matrix_vector_helpers = @import("vector_helpers.zig"); // M-callconv: Zig-to-Zig

const real_t = runtime.real_t;
const calcRegister_t = runtime.calcRegister_t;
const angularMode_t = runtime.angularMode_t;

const REGISTER_X = runtime.REGISTER_X;
const REGISTER_Y = runtime.REGISTER_Y;
const REGISTER_Z = runtime.REGISTER_Z;
const dtReal34Matrix = runtime.dtReal34Matrix;

const VECT_CR_zxy: u16 = 1;
const VECT_CR_zyx: u16 = 2;
const VECT_CR_yx: u16 = 6;
const _3DCYL: i16 = 1;
const _3DSPH: i16 = 2;
const ERROR_INVALID_DATA_TYPE_FOR_POLAR_RECT: u8 = 52;
const AMNONE: u32 = @intCast(runtime.amNone);

extern fn fnConvertStkToMx(constVector1: u16) void;

inline fn angMode(r: calcRegister_t) u32 {
    return @intCast(runtime.getRegisterAngularMode(r));
}
// registerIsNoAngle (defines.h macro): a plain real with no angle tag, or a
// long integer.
inline fn registerIsNoAngle(r: calcRegister_t) bool {
    return (runtime.getRegisterDataType(r) == runtime.dtReal34 and angMode(r) == AMNONE) or
        runtime.getRegisterDataType(r) == runtime.dtLongInteger;
}

pub export fn is_2D3D_Register_Ready(
    ang2Dx: *u32,
    ang2Dy: *u32,
    ang3Dx: *u32,
    ang3Dy: *u32,
    ang3Dz: *u32,
    validPolarInput: *bool,
    valid2DRInput: *bool,
    validSPHInput: *bool,
    validCYLInput: *bool,
    valid3DRInput: *bool,
    constVector: u16,
) callconv(.c) bool {
    ang2Dx.* = if (registerIsNoAngle(REGISTER_X) or constVector != VECT_CR_yx) AMNONE else angMode(REGISTER_X);
    ang2Dy.* = if (registerIsNoAngle(REGISTER_Y) or constVector != VECT_CR_yx) AMNONE else angMode(REGISTER_Y);
    ang3Dx.* = if (registerIsNoAngle(REGISTER_X) or (constVector != VECT_CR_zyx and constVector != VECT_CR_zxy)) AMNONE else angMode(REGISTER_X);
    ang3Dy.* = if (registerIsNoAngle(REGISTER_Y) or (constVector != VECT_CR_zyx and constVector != VECT_CR_zxy)) AMNONE else angMode(REGISTER_Y);
    ang3Dz.* = if (registerIsNoAngle(REGISTER_Z) or (constVector != VECT_CR_zyx and constVector != VECT_CR_zxy)) AMNONE else angMode(REGISTER_Z);
    validPolarInput.* = (ang2Dx.* != AMNONE and ang2Dy.* == AMNONE and constVector == VECT_CR_yx);
    valid2DRInput.* = (ang2Dx.* == AMNONE and ang2Dy.* == AMNONE and constVector == VECT_CR_yx);
    validSPHInput.* = (ang3Dx.* != AMNONE and ang3Dy.* != AMNONE and ang3Dz.* == AMNONE and (constVector == VECT_CR_zyx or constVector == VECT_CR_zxy));
    validCYLInput.* = (ang3Dx.* == AMNONE and ang3Dy.* != AMNONE and ang3Dz.* == AMNONE and (constVector == VECT_CR_zyx or constVector == VECT_CR_zxy));
    valid3DRInput.* = (ang3Dx.* == AMNONE and ang3Dy.* == AMNONE and ang3Dz.* == AMNONE);
    return (validPolarInput.* or valid2DRInput.* or validSPHInput.* or validCYLInput.* or valid3DRInput.*);
}

// isStack3DReadyConvertIfNot (file-local) -- confirm the stack holds a 3D polar
// vector; convert a 3D-rectangular stack to angle-tagged form for the target.
fn isStack3DReadyConvertIfNot(mode: i16, constVector: u16) bool {
    var ang2Dx: u32 = undefined;
    var ang2Dy: u32 = undefined;
    var ang3Dx: u32 = undefined;
    var ang3Dy: u32 = undefined;
    var ang3Dz: u32 = undefined;
    var validPolarInput: bool = undefined;
    var valid2DRInput: bool = undefined;
    var validSPHInput: bool = undefined;
    var validCYLInput: bool = undefined;
    var valid3DRInput: bool = undefined;
    _ = is_2D3D_Register_Ready(&ang2Dx, &ang2Dy, &ang3Dx, &ang3Dy, &ang3Dz, &validPolarInput, &valid2DRInput, &validSPHInput, &validCYLInput, &valid3DRInput, constVector);
    const is_3D_Register_Ready = validSPHInput or validCYLInput or valid3DRInput;

    if (!is_3D_Register_Ready) {
        runtime.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_POLAR_RECT, runtime.ERR_REGISTER_LINE, REGISTER_X);
        if (runtime.extra_info_on_calc_error) runtime.moreInfoOnError("In function isStack3DReadyConvertIfNot:", "No valid coordinates for 3D Spherical/Cylindrical", null, null);
        return false;
    }

    var xx: real_t = undefined;
    if (!(runtime.getRegisterAsReal(REGISTER_X, &xx) and runtime.getRegisterAsReal(REGISTER_Y, &xx) and runtime.getRegisterAsReal(REGISTER_Z, &xx))) {
        return false;
    }

    if ((validCYLInput and mode == _3DCYL) or (validSPHInput and mode == _3DSPH)) {
        return true;
    }

    if (valid3DRInput and (mode == _3DCYL or mode == _3DSPH)) {
        if (runtime.getRegisterDataType(REGISTER_Y) == runtime.dtShortInteger) {
            runtime.convertShortIntegerRegisterToReal34Register(REGISTER_Y, REGISTER_Y);
        }
        if (runtime.getRegisterDataType(REGISTER_Y) == runtime.dtLongInteger) {
            runtime.convertLongIntegerRegisterToReal34Register(REGISTER_Y, REGISTER_Y);
        }
        runtime.setRegisterAngularMode(REGISTER_Y, runtime.currentAngularMode);

        if (mode == _3DSPH) {
            if (runtime.getRegisterDataType(REGISTER_X) == runtime.dtShortInteger) {
                runtime.convertShortIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
            }
            if (runtime.getRegisterDataType(REGISTER_X) == runtime.dtLongInteger) {
                runtime.convertLongIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
            }
            runtime.setRegisterAngularMode(REGISTER_X, runtime.currentAngularMode);
        }
        return true;
    }
    return false;
}

pub export fn V3RectoToSph(am: u16) callconv(.c) void {
    if (runtime.getRegisterDataType(REGISTER_X) != dtReal34Matrix and isStack3DReadyConvertIfNot(_3DSPH, VECT_CR_zyx)) {
        fnConvertStkToMx(VECT_CR_zyx);
    } else {
        const angleMode: angularMode_t = if (am == 255) runtime.currentAngularMode else @intCast(am);
        if (runtime.getRegisterDataType(REGISTER_X) == dtReal34Matrix) {
            if (runtime.isRegisterMatrix3dVector(REGISTER_X)) {
                runtime.setVectorRegisterPolarMode(REGISTER_X, runtime.amPolarSPH);
                runtime.setVectorRegisterAngularMode(REGISTER_X, angleMode);
                runtime.temporaryInformation = runtime.TI_VECTOR;
            } else {
                math_matrix_vector_helpers.V3err(1);
            }
        } else {
            math_matrix_vector_helpers.V3err(2);
        }
    }
}

pub export fn V3RectoToCyl(am: u16) callconv(.c) void {
    if (runtime.getRegisterDataType(REGISTER_X) != dtReal34Matrix and isStack3DReadyConvertIfNot(_3DCYL, VECT_CR_zyx)) {
        fnConvertStkToMx(VECT_CR_zyx);
    } else {
        const angleMode: angularMode_t = if (am == 255) runtime.currentAngularMode else @intCast(am);
        if (runtime.getRegisterDataType(REGISTER_X) == dtReal34Matrix) {
            if (runtime.isRegisterMatrix3dVector(REGISTER_X)) {
                runtime.setVectorRegisterPolarMode(REGISTER_X, runtime.amPolarCYL);
                runtime.setVectorRegisterAngularMode(REGISTER_X, angleMode);
                runtime.temporaryInformation = runtime.TI_VECTOR;
            } else {
                math_matrix_vector_helpers.V3err(3);
            }
        } else {
            math_matrix_vector_helpers.V3err(4);
        }
    }
}
