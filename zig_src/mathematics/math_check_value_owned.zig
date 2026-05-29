const runtime = @import("math_command_wrappers_runtime.zig");

fn typeErrorX() void {
    runtime.setTemporaryInformation(false);
    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_T);
}

pub fn checkType(type_: u16) void {
    runtime.setTemporaryInformation(runtime.getRegisterDataType(runtime.REGISTER_X) == type_);
}

pub fn checkReal() void {
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    runtime.setTemporaryInformation(register_data_type <= runtime.dtDate or register_data_type == runtime.dtShortInteger);
}

pub fn checkNumber() void {
    const is_number = switch (runtime.getRegisterDataType(runtime.REGISTER_X)) {
        runtime.dtLongInteger, runtime.dtShortInteger => true,
        runtime.dtComplex34 => blk: {
            const imag_is_number = !(runtime.real34IsNaN(runtime.registerImag34Ptr(runtime.REGISTER_X)) or runtime.real34IsInfinite(runtime.registerImag34Ptr(runtime.REGISTER_X)));
            const real_is_number = !(runtime.real34IsNaN(runtime.registerReal34Ptr(runtime.REGISTER_X)) or runtime.real34IsInfinite(runtime.registerReal34Ptr(runtime.REGISTER_X)));
            break :blk imag_is_number and real_is_number;
        },
        runtime.dtTime, runtime.dtDate, runtime.dtReal34 => !(runtime.real34IsNaN(runtime.registerReal34Ptr(runtime.REGISTER_X)) or runtime.real34IsInfinite(runtime.registerReal34Ptr(runtime.REGISTER_X))),
        else => false,
    };

    runtime.setTemporaryInformation(is_number);
}

pub fn checkAngle() void {
    runtime.setTemporaryInformation(runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtReal34 and runtime.getRegisterAngularMode(runtime.REGISTER_X) != runtime.amNone);
}

pub fn checkMatrix() void {
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    runtime.setTemporaryInformation(register_data_type == runtime.dtReal34Matrix or register_data_type == runtime.dtComplex34Matrix);
}

pub fn checkMatrixSquare() void {
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);

    if (register_data_type == runtime.dtReal34Matrix or register_data_type == runtime.dtComplex34Matrix) {
        const header = runtime.registerMatrixHeaderPtr(runtime.REGISTER_X);
        runtime.setTemporaryInformation(header.matrixRows == header.matrixColumns);
        return;
    }

    typeErrorX();
}