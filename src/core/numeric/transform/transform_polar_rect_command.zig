const std = @import("std");
const rectangular_to_polar_owned = @import("rectangular_to_polar.zig");
const runtime = @import("../command_wrappers/runtime.zig");

// ERROR_MESSAGE_LENGTH is 512 (defines.h); upstream formats these hints into
// the shared errorMessage buffer of that size.
const ERROR_MESSAGE_LENGTH = 512;

// "You cannot use >R or >P with %s in X and %s in Y!", the shared refusal of
// fnToPolar2 and fnToRect2. Both name the X and Y registers, whatever pair the
// HPRP flag chose as real and imaginary.
fn reportPairTypeError(function_name: [*:0]const u8) void {
    if (!runtime.extra_info_on_calc_error) {
        return;
    }
    var buffer: [ERROR_MESSAGE_LENGTH]u8 = undefined;
    const x_name = std.mem.span(runtime.getRegisterDataTypeName(runtime.REGISTER_X, true, false));
    const y_name = std.mem.span(runtime.getRegisterDataTypeName(runtime.REGISTER_Y, true, false));
    const message = runtime.bufPrintZ(&buffer, "You cannot use >R or >P with {s} in X and {s} in Y!", .{ x_name, y_name }) catch "";
    runtime.moreInfoOnError(function_name, message, null, null);
}

// fnToRect's own refusal, which names the two registers it was about to read
// rather than X and Y. fnToPolar's twin is unreachable here: fnToPolar2's
// stricter check, inlined above it, already rejects everything it would.
fn reportToRectTypeError(radius_reg: runtime.calcRegister_t, angle_reg: runtime.calcRegister_t) void {
    if (!runtime.extra_info_on_calc_error) {
        return;
    }
    var buffer: [ERROR_MESSAGE_LENGTH]u8 = undefined;
    const radius_name = std.mem.span(runtime.getRegisterDataTypeName(radius_reg, false, false));
    const angle_name = std.mem.span(runtime.getRegisterDataTypeName(angle_reg, false, false));
    const message = runtime.bufPrintZ(&buffer, "cannot convert ({s}, {s}) to rectangular coordinates!", .{ radius_name, angle_name }) catch "";
    runtime.moreInfoOnError("In function fnToRect:", message, null, null);
}

fn loadToPolarNumericInput(reg: runtime.calcRegister_t, data_type: u32, value: *runtime.real_t) void {
    switch (data_type) {
        runtime.dtLongInteger => runtime.convertLongIntegerRegisterToReal(reg, value, &runtime.ctxtReal39),
        runtime.dtReal34 => _ = runtime.decimal128ToNumber(runtime.registerReal34Ptr(reg), value),
        else => unreachable,
    }
}

fn tryToPolar2Real34Pair() bool {
    if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtComplex34 or runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtComplex34Matrix) {
        runtime.setComplexRegisterPolarMode(runtime.REGISTER_X, runtime.amPolar);
        if (runtime.getComplexRegisterAngularMode(runtime.REGISTER_X) == runtime.amNone) {
            runtime.setComplexRegisterAngularMode(runtime.REGISTER_X, runtime.currentAngularMode);
        }
        return true;
    }

    // toPolar.c wraps the whole real-matrix vector branch in
    // `#if defined(OPTION_VECTOR)`. defines.h #undef's OPTION_VECTOR in the block
    // common to packages 1-4, so no DM42 package carries the branch: there a
    // real-matrix X falls straight through to the operand type check below.
    if (runtime.option_vector and runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtReal34Matrix) {
        if (runtime.isRegisterMatrix3dVector(runtime.REGISTER_X)) {
            const polar_mode = runtime.getVectorRegisterPolarMode(runtime.REGISTER_X);
            runtime.setVectorRegisterPolarMode(
                runtime.REGISTER_X,
                if (polar_mode == 0)
                    runtime.amPolarSPH
                else if (polar_mode == runtime.amPolarSPH)
                    runtime.amPolarCYL
                else if (polar_mode == runtime.amPolarCYL)
                    runtime.amPolarSPH
                else
                    0,
            );
            runtime.setVectorRegisterAngularMode(runtime.REGISTER_X, runtime.currentAngularMode);
            runtime.temporaryInformation = runtime.TI_VECTOR;
            return true;
        }

        if (runtime.isRegisterMatrix2dVector(runtime.REGISTER_X)) {
            runtime.setVectorRegisterPolarMode(runtime.REGISTER_X, runtime.amPolar);
            runtime.setVectorRegisterAngularMode(runtime.REGISTER_X, runtime.currentAngularMode);
            runtime.temporaryInformation = runtime.TI_VECTOR;
            return true;
        }
    }

    // The registers are chosen first and the types read from the chosen ones, so
    // each operand is decoded with its own type. Reading the types from X and Y
    // and then swapping only the registers crosses them whenever HPRP is clear.
    const hp_rp = runtime.getSystemFlag(runtime.FLAG_HPRP);
    const real_reg = if (hp_rp) runtime.REGISTER_X else runtime.REGISTER_Y;
    const imag_reg = if (hp_rp) runtime.REGISTER_Y else runtime.REGISTER_X;

    const data_type_x = runtime.getRegisterDataType(real_reg);
    const data_atag_x = runtime.getRegisterAngularMode(real_reg);
    const data_type_y = runtime.getRegisterDataType(imag_reg);
    const data_atag_y = runtime.getRegisterAngularMode(imag_reg);

    const x_valid = data_type_x == runtime.dtLongInteger or (data_type_x == runtime.dtReal34 and data_atag_x == runtime.amNone);
    const y_valid = data_type_y == runtime.dtLongInteger or (data_type_y == runtime.dtReal34 and data_atag_y == runtime.amNone);

    if (!x_valid or !y_valid) {
        runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        reportPairTypeError("In function fnToPolar2:");
        return true;
    }

    if (!runtime.saveLastX()) {
        return true;
    }

    var real_value: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;

    loadToPolarNumericInput(real_reg, data_type_x, &real_value);
    loadToPolarNumericInput(imag_reg, data_type_y, &imag_value);

    rectangular_to_polar_owned.rectangularToPolarReal(&real_value, &imag_value, &real_value, &imag_value, &runtime.ctxtReal39);
    runtime.convertAngleFromTo(&imag_value, runtime.amRadian, runtime.currentAngularMode, &runtime.ctxtReal39);

    runtime.reallocateRegister(real_reg, runtime.dtReal34, 0, runtime.amNone);
    runtime.reallocateRegister(imag_reg, runtime.dtReal34, 0, @intCast(runtime.currentAngularMode));
    runtime.convertRealToReal34ResultRegister(&real_value, real_reg);
    runtime.convertRealToReal34ResultRegister(&imag_value, imag_reg);
    runtime.temporaryInformation = if (runtime.getSystemFlag(runtime.FLAG_HPRP))
        runtime.TI_RADIUS_THETA
    else
        runtime.TI_RADIUS_THETA_SWAPPED;
    return true;
}

fn tryToRect2Real34Pair() bool {
    if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtComplex34 or runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtComplex34Matrix) {
        runtime.setComplexRegisterPolarMode(runtime.REGISTER_X, runtime.amNone);
        runtime.setComplexRegisterAngularMode(runtime.REGISTER_X, runtime.amNone);
        return true;
    }

    // toRect.c wraps the whole real-matrix vector branch in
    // `#if defined(OPTION_VECTOR)`, undefined on every DM42 package, where a
    // real-matrix X therefore reaches the operand type check below instead.
    if (runtime.option_vector and runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtReal34Matrix and runtime.isRegisterMatrixVector(runtime.REGISTER_X)) {
        runtime.setVectorRegisterPolarMode(runtime.REGISTER_X, 0);
        runtime.setVectorRegisterAngularMode(runtime.REGISTER_X, runtime.amNone);
        runtime.temporaryInformation = runtime.TI_VECTOR;
        return true;
    }

    const data_type_x = runtime.getRegisterDataType(runtime.REGISTER_X);
    const data_atag_x = runtime.getRegisterAngularMode(runtime.REGISTER_X);
    const data_type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);
    const data_atag_y = runtime.getRegisterAngularMode(runtime.REGISTER_Y);
    const x_is_angle = data_type_x == runtime.dtReal34 and data_atag_x != runtime.amNone;
    const y_is_angle = data_type_y == runtime.dtReal34 and data_atag_y != runtime.amNone;
    const x_is_radius = data_type_x == runtime.dtLongInteger or (data_type_x == runtime.dtReal34 and data_atag_x == runtime.amNone);
    const y_is_radius = data_type_y == runtime.dtLongInteger or (data_type_y == runtime.dtReal34 and data_atag_y == runtime.amNone);

    var angle_in_y: i8 = 1;
    if (!runtime.getSystemFlag(runtime.FLAG_HPRP)) {
        angle_in_y = -angle_in_y;
        if (x_is_angle and y_is_radius) {
            // Keep the current register order.
        } else if (y_is_angle and x_is_radius) {
            angle_in_y = -angle_in_y;
        }
    } else {
        if (x_is_angle and y_is_radius) {
            angle_in_y = -angle_in_y;
        } else if (y_is_angle and x_is_radius) {
            // Keep the current register order.
        }
    }

    const x_valid = data_type_x == runtime.dtLongInteger or data_type_x == runtime.dtReal34;
    const y_valid = data_type_y == runtime.dtLongInteger or data_type_y == runtime.dtReal34;

    if (!x_valid or !y_valid) {
        runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        reportPairTypeError("In function fnToRect2:");
        return true;
    }

    var radius_reg = if (angle_in_y == 1) runtime.REGISTER_X else runtime.REGISTER_Y;
    var angle_reg = if (angle_in_y == 1) runtime.REGISTER_Y else runtime.REGISTER_X;
    const radius_type = runtime.getRegisterDataType(radius_reg);
    const angle_type = runtime.getRegisterDataType(angle_reg);
    const radius_valid = radius_type == runtime.dtLongInteger or radius_type == runtime.dtReal34;
    const angle_valid = angle_type == runtime.dtLongInteger or angle_type == runtime.dtReal34;

    if (!radius_valid or !angle_valid) {
        runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, radius_reg);
        reportToRectTypeError(radius_reg, angle_reg);
        return true;
    }

    var angle_mode = runtime.getRegisterAngularMode(angle_reg);
    if (!runtime.saveLastX()) {
        return true;
    }

    var radius_value: runtime.real_t = undefined;
    var angle_value: runtime.real_t = undefined;

    loadToPolarNumericInput(radius_reg, radius_type, &radius_value);
    loadToPolarNumericInput(angle_reg, angle_type, &angle_value);

    // A long integer register's tag holds its SIGN, not an angular mode --
    // LI_NEGATIVE is 1 and LI_POSITIVE is 2, which collide with amGrad and
    // amDegree. toRect.c reads currentAngularMode for a long-integer angle and the
    // register's own tag only for a real34, so the sign is never mistaken for a
    // mode. tryToRectReal34Pair below already does this; this one did not.
    if (angle_type == runtime.dtLongInteger) {
        angle_mode = runtime.currentAngularMode;
    } else if (angle_mode == runtime.amNone) {
        angle_mode = runtime.currentAngularMode;
    }

    runtime.convertAngleFromTo(&angle_value, angle_mode, runtime.amRadian, &runtime.ctxtReal39);
    runtime.realPolarToRectangular(&radius_value, &angle_value, &radius_value, &angle_value, &runtime.ctxtReal39);

    if (runtime.getSystemFlag(runtime.FLAG_HPRP)) {
        radius_reg = runtime.REGISTER_X;
        angle_reg = runtime.REGISTER_Y;
    } else {
        radius_reg = runtime.REGISTER_Y;
        angle_reg = runtime.REGISTER_X;
    }

    runtime.reallocateRegister(radius_reg, runtime.dtReal34, 0, runtime.amNone);
    runtime.reallocateRegister(angle_reg, runtime.dtReal34, 0, runtime.amNone);
    runtime.convertRealToReal34ResultRegister(&radius_value, radius_reg);
    runtime.convertRealToReal34ResultRegister(&angle_value, angle_reg);
    runtime.temporaryInformation = if (runtime.getSystemFlag(runtime.FLAG_HPRP))
        runtime.TI_X_Y
    else
        runtime.TI_X_Y_SWAPPED;
    return true;
}

fn tryToRectReal34Pair(angle_in_y: i8) bool {
    var radius_reg = if (angle_in_y == 1) runtime.REGISTER_X else runtime.REGISTER_Y;
    var angle_reg = if (angle_in_y == 1) runtime.REGISTER_Y else runtime.REGISTER_X;
    const radius_type = runtime.getRegisterDataType(radius_reg);
    const angle_type = runtime.getRegisterDataType(angle_reg);
    const radius_valid = radius_type == runtime.dtLongInteger or radius_type == runtime.dtReal34;
    const angle_valid = angle_type == runtime.dtLongInteger or angle_type == runtime.dtReal34;

    if (!radius_valid or !angle_valid) {
        runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, radius_reg);
        reportToRectTypeError(radius_reg, angle_reg);
        return true;
    }

    var angle_mode = runtime.getRegisterAngularMode(angle_reg);
    if (!runtime.saveLastX()) {
        return true;
    }

    var radius_value: runtime.real_t = undefined;
    var angle_value: runtime.real_t = undefined;

    loadToPolarNumericInput(radius_reg, radius_type, &radius_value);
    loadToPolarNumericInput(angle_reg, angle_type, &angle_value);

    if (angle_type == runtime.dtLongInteger) {
        angle_mode = runtime.currentAngularMode;
    } else if (angle_mode == runtime.amNone) {
        angle_mode = runtime.currentAngularMode;
    }

    runtime.convertAngleFromTo(&angle_value, angle_mode, runtime.amRadian, &runtime.ctxtReal39);
    runtime.realPolarToRectangular(&radius_value, &angle_value, &radius_value, &angle_value, &runtime.ctxtReal39);

    if (runtime.getSystemFlag(runtime.FLAG_HPRP)) {
        radius_reg = runtime.REGISTER_X;
        angle_reg = runtime.REGISTER_Y;
    } else {
        radius_reg = runtime.REGISTER_Y;
        angle_reg = runtime.REGISTER_X;
    }

    runtime.reallocateRegister(radius_reg, runtime.dtReal34, 0, runtime.amNone);
    runtime.reallocateRegister(angle_reg, runtime.dtReal34, 0, runtime.amNone);
    runtime.convertRealToReal34ResultRegister(&radius_value, radius_reg);
    runtime.convertRealToReal34ResultRegister(&angle_value, angle_reg);
    runtime.temporaryInformation = if (runtime.getSystemFlag(runtime.FLAG_HPRP))
        runtime.TI_X_Y
    else
        runtime.TI_X_Y_SWAPPED;
    return true;
}

pub fn toPolar2(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    _ = tryToPolar2Real34Pair();
}

pub fn toRect2(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    _ = tryToRect2Real34Pair();
}

pub fn toRect(unused_but_mandatory_parameter: u16) void {
    const angle_in_y: i8 = @bitCast(@as(u8, @truncate(unused_but_mandatory_parameter)));

    _ = tryToRectReal34Pair(angle_in_y);
}
