const runtime = @import("command_wrappers_runtime.zig");

fn typeErrorX() void {
    runtime.setTemporaryInformation(false);
    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_T);
}

fn getConvergenceInput(
    regist: runtime.calcRegister_t,
    real: *runtime.real_t,
    imag: *runtime.real_t,
    is_complex: *bool,
) bool {
    switch (runtime.getRegisterDataType(regist)) {
        runtime.dtComplex34 => {
            is_complex.* = true;
            return runtime.getRegisterAsComplex(regist, real, imag);
        },
        runtime.dtReal34 => {
            if (!runtime.getRegisterAsReal(regist, real)) {
                return false;
            }
            runtime.realSetZero(imag);
            return true;
        },
        runtime.dtLongInteger => {
            runtime.convertLongIntegerRegisterToReal(regist, real, &runtime.ctxtReal75);
            runtime.realSetZero(imag);
            return true;
        },
        runtime.dtShortInteger => {
            runtime.convertShortIntegerRegisterToReal(regist, real, &runtime.ctxtReal34);
            runtime.realSetZero(imag);
            return true;
        },
        else => return false,
    }
}

pub fn isConverged(mode: u16) void {
    var x_real: runtime.real_t = undefined;
    var x_imag: runtime.real_t = undefined;
    var y_real: runtime.real_t = undefined;
    var y_imag: runtime.real_t = undefined;
    var tol: runtime.real_t = undefined;
    var is_complex = false;

    runtime.convergenceTolerence(&tol);
    if (!getConvergenceInput(runtime.REGISTER_X, &x_real, &x_imag, &is_complex) or !getConvergenceInput(runtime.REGISTER_Y, &y_real, &y_imag, &is_complex)) {
        typeErrorX();
        return;
    }

    if (runtime.realIsNaN(&x_real) or runtime.realIsNaN(&y_real) or runtime.realIsNaN(&x_imag) or runtime.realIsNaN(&y_imag)) {
        runtime.setTemporaryInformation((mode & 0x4) != 0);
    } else if (runtime.realIsInfinite(&x_real) or runtime.realIsInfinite(&y_real) or runtime.realIsInfinite(&x_imag) or runtime.realIsInfinite(&y_imag)) {
        runtime.setTemporaryInformation((mode & 0x2) != 0);
    } else if ((mode & 0x1) != 0) {
        runtime.setTemporaryInformation(
            if (is_complex)
                runtime.WP34S_ComplexAbsError(&x_real, &x_imag, &y_real, &y_imag, &tol, &runtime.ctxtReal39)
            else
                runtime.WP34S_AbsoluteError(&x_real, &y_real, &tol, &runtime.ctxtReal39),
        );
    } else {
        runtime.setTemporaryInformation(
            if (is_complex)
                runtime.WP34S_ComplexRelativeError(&x_real, &x_imag, &y_real, &y_imag, &tol, &runtime.ctxtReal39)
            else
                runtime.WP34S_RelativeError(&x_real, &y_real, &tol, &runtime.ctxtReal39),
        );
    }
}
