const atan2_owned = @import("atan2.zig");
const abi = @import("abi");
const build_options = @import("math_command_wrappers_build_options");
const runtime = @import("../math_command_wrappers_runtime.zig");

const no_register = @as(runtime.calcRegister_t, -1);

fn realMatrixElementCount(matrix: *const runtime.real34Matrix_t) usize {
    return @as(usize, matrix.header.matrixRows) * @as(usize, matrix.header.matrixColumns);
}

fn realMatrixElementPtr(matrix: *runtime.real34Matrix_t, index: usize) *runtime.real34_t {
    if (build_options.use_fake_wp34s_model) {
        return &matrix.matrixElements[index];
    }

    return &abi.matrixRealElems(matrix)[index];
}

fn reportZeroDomain(comptime function_name: [:0]const u8) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
    runtime.moreInfoOnError(function_name, "X = 0 and Y = 0", null, null);
}

fn hasZeroDomainError(comptime function_name: [:0]const u8, y_value: *const runtime.real_t, x_value: *const runtime.real_t) bool {
    if (!(runtime.realIsZero(y_value) and runtime.realIsZero(x_value)) or runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        return false;
    }

    reportZeroDomain(function_name);
    return true;
}

fn convertAngleAndRound(x_value: *runtime.real_t) void {
    runtime.convertAngleFromTo(x_value, runtime.amRadian, runtime.currentAngularMode, &runtime.ctxtReal39);
    runtime.roundToSignificantDigits(x_value, x_value, if (runtime.significantDigits == 0) 34 else runtime.significantDigits, &runtime.ctxtReal75);
}

fn atan2RemaRema() void {
    var y_matrix: runtime.real34Matrix_t = undefined;
    var x_matrix: runtime.real34Matrix_t = undefined;

    runtime.linkToRealMatrixRegister(runtime.REGISTER_Y, &y_matrix);
    runtime.linkToRealMatrixRegister(runtime.REGISTER_X, &x_matrix);

    if (y_matrix.header.matrixRows != x_matrix.header.matrixRows or y_matrix.header.matrixColumns != x_matrix.header.matrixColumns) {
        runtime.displayCalcErrorMessage(runtime.ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function atan2RemaRema:", "matrix size mismatch", null, null);
        return;
    }

    const count = @min(realMatrixElementCount(&x_matrix), realMatrixElementCount(&y_matrix));

    var index: usize = 0;
    while (index < count) : (index += 1) {
        var y_value: runtime.real_t = undefined;
        var x_value: runtime.real_t = undefined;

        runtime.real34ToReal(realMatrixElementPtr(&y_matrix, index), &y_value);
        runtime.real34ToReal(realMatrixElementPtr(&x_matrix, index), &x_value);
        if (hasZeroDomainError("In function atan2RemaRema:", &y_value, &x_value)) {
            return;
        }

        atan2_owned.arctan2Real(&y_value, &x_value, &x_value, &runtime.ctxtReal39);
        convertAngleAndRound(&x_value);
        runtime.realToReal34(&x_value, realMatrixElementPtr(&x_matrix, index));
    }

    if (build_options.use_fake_wp34s_model) {
        // The fake harness copies the matrix out of the register, so it must be
        // written back. The real runtime links the register data directly
        // (upstream atan2RemaRema mutates it in place); converting a linked
        // matrix back would reallocate the register and read freed memory.
        runtime.convertReal34MatrixToReal34MatrixRegister(&x_matrix, runtime.REGISTER_X);
    }
}

fn atan2RealRema() void {
    var y_scalar: runtime.real_t = undefined;
    var x_matrix: runtime.real34Matrix_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_Y, &y_scalar)) {
        return;
    }

    runtime.linkToRealMatrixRegister(runtime.REGISTER_X, &x_matrix);
    const count = realMatrixElementCount(&x_matrix);

    var index: usize = 0;
    while (index < count) : (index += 1) {
        var y_value = y_scalar;
        var x_value: runtime.real_t = undefined;

        runtime.real34ToReal(realMatrixElementPtr(&x_matrix, index), &x_value);
        if (hasZeroDomainError("In function atan2RealRema:", &y_value, &x_value)) {
            return;
        }

        atan2_owned.arctan2Real(&y_value, &x_value, &x_value, &runtime.ctxtReal39);
        convertAngleAndRound(&x_value);
        runtime.realToReal34(&x_value, realMatrixElementPtr(&x_matrix, index));
    }

    if (build_options.use_fake_wp34s_model) {
        // See atan2RemaRema: only the fake harness needs the copy-back; the
        // real runtime mutates the linked register matrix in place.
        runtime.convertReal34MatrixToReal34MatrixRegister(&x_matrix, runtime.REGISTER_X);
    }
}

fn atan2Error() void {
    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
    runtime.moreInfoOnError("In function fnAtan2:", "cannot calculate atan2 for current X and Y types", null, null);
}

fn atan2RealReal() callconv(.c) void {
    var y_value: runtime.real_t = undefined;
    var x_value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value) or !runtime.getRegisterAsReal(runtime.REGISTER_Y, &y_value)) {
        return;
    }

    if (hasZeroDomainError("In function atan2RealReal:", &y_value, &x_value)) {
        return;
    }

    atan2_owned.arctan2Real(&y_value, &x_value, &x_value, &runtime.ctxtReal39);
    runtime.convertAngleFromTo(&x_value, runtime.amRadian, runtime.currentAngularMode, &runtime.ctxtReal39);
    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, @intCast(runtime.currentAngularMode));
    runtime.convertRealToReal34ResultRegister(&x_value, runtime.REGISTER_X);
}

pub fn atan2(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    const data_type_x = runtime.getRegisterDataType(runtime.REGISTER_X);
    const data_type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);

    if (!runtime.saveLastX()) {
        return;
    }

    if ((data_type_x == runtime.dtReal34 or data_type_x == runtime.dtLongInteger) and (data_type_y == runtime.dtReal34 or data_type_y == runtime.dtLongInteger)) {
        atan2RealReal();
    } else if (data_type_x == runtime.dtReal34Matrix and data_type_y == runtime.dtReal34Matrix) {
        atan2RemaRema();
    } else if (data_type_x == runtime.dtReal34Matrix and (data_type_y == runtime.dtReal34 or data_type_y == runtime.dtLongInteger or data_type_y == runtime.dtShortInteger)) {
        atan2RealRema();
    } else if (data_type_y == runtime.dtReal34Matrix and (data_type_x == runtime.dtReal34 or data_type_x == runtime.dtLongInteger or data_type_x == runtime.dtShortInteger)) {
        runtime.elementwiseRemaReal(&atan2RealReal);
    } else {
        atan2Error();
    }

    runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, runtime.REGISTER_Y, no_register);
}
