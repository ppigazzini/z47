const runtime = @import("command_wrappers/runtime.zig");

fn typeErrorX() void {
    runtime.setTemporaryInformation(false);
    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE);
}

fn getConvergenceInput(
    regist: runtime.calcRegister_t,
    value: *runtime.cplx_t,
    is_complex: *bool,
) bool {
    switch (runtime.getRegisterDataType(regist)) {
        runtime.dtComplex34 => {
            is_complex.* = true;
            return runtime.getRegisterAsComplex(regist, value);
        },
        runtime.dtReal34 => {
            if (!runtime.getRegisterAsReal(regist, &value.Real)) {
                return false;
            }
            runtime.realSetZero(&value.Imag);
            return true;
        },
        runtime.dtLongInteger => {
            runtime.convertLongIntegerRegisterToReal(regist, &value.Real, &runtime.ctxtReal75);
            runtime.realSetZero(&value.Imag);
            return true;
        },
        runtime.dtShortInteger => {
            runtime.convertShortIntegerRegisterToReal(regist, &value.Real, &runtime.ctxtReal34);
            runtime.realSetZero(&value.Imag);
            return true;
        },
        else => return false,
    }
}

pub fn isConverged(mode: u16) void {
    var x: runtime.cplx_t = undefined;
    var y: runtime.cplx_t = undefined;
    var tol: runtime.real_t = undefined;
    var is_complex = false;

    runtime.convergenceTolerence(&tol);
    if (!getConvergenceInput(runtime.REGISTER_X, &x, &is_complex) or !getConvergenceInput(runtime.REGISTER_Y, &y, &is_complex)) {
        typeErrorX();
        return;
    }

    if (runtime.realIsNaN(&x.Real) or runtime.realIsNaN(&y.Real) or runtime.realIsNaN(&x.Imag) or runtime.realIsNaN(&y.Imag)) {
        runtime.setTemporaryInformation((mode & 0x4) != 0);
    } else if (runtime.realIsInfinite(&x.Real) or runtime.realIsInfinite(&y.Real) or runtime.realIsInfinite(&x.Imag) or runtime.realIsInfinite(&y.Imag)) {
        runtime.setTemporaryInformation((mode & 0x2) != 0);
    } else if ((mode & 0x1) != 0) {
        runtime.setTemporaryInformation(
            if (is_complex)
                runtime.WP34S_ComplexAbsError(&x, &y, &tol, &runtime.ctxtReal39)
            else
                runtime.WP34S_AbsoluteError(&x.Real, &y.Real, &tol, &runtime.ctxtReal39),
        );
    } else {
        runtime.setTemporaryInformation(
            if (is_complex)
                runtime.WP34S_ComplexRelativeError(&x, &y, &tol, &runtime.ctxtReal39)
            else
                runtime.WP34S_RelativeError(&x.Real, &y.Real, &tol, &runtime.ctxtReal39),
        );
    }
}
