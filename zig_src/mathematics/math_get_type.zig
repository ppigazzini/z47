const std = @import("std");
const math_type_encode = @import("math_type_encode.zig"); // std-only type-report encoders
const runtime = @import("math_command_wrappers_runtime.zig");

fn pushIntegerOut(value: u32) void {
    var long_integer: runtime.longInteger_t = undefined;

    runtime.__gmpz_init(&long_integer[0]);
    defer runtime.__gmpz_clear(&long_integer[0]);
    runtime.__gmpz_set_ui(&long_integer[0], value);

    runtime.setSystemFlag(runtime.FLAG_ASLIFT);
    runtime.liftStack();
    runtime.convertLongIntegerToLongIntegerRegister(&long_integer[0], runtime.REGISTER_X);
    runtime.setSystemFlag(runtime.FLAG_ASLIFT);
}

fn pushRealOut(value: u32) void {
    var real_output = std.mem.zeroes(runtime.real_t);
    var scale = std.mem.zeroes(runtime.real_t);

    runtime.uInt32ToReal(value, &real_output);
    runtime.uInt32ToReal(1000, &scale);
    runtime.realDivide(&real_output, &scale, &real_output, &runtime.ctxtReal39);

    runtime.setSystemFlag(runtime.FLAG_ASLIFT);
    runtime.liftStack();
    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
    runtime.convertRealToReal34ResultRegister(&real_output, runtime.REGISTER_X);
    runtime.setSystemFlag(runtime.FLAG_ASLIFT);
}

fn matrixVectorShape(header: *align(1) runtime.matrixHeader_t) u32 {
    return math_type_encode.matrixVectorShape(header.matrixRows, header.matrixColumns);
}

fn angleCode(angular_mode: u32) u32 {
    return math_type_encode.angleCode(angular_mode);
}

fn realMatrixVectorPolarCode() u32 {
    if (runtime.isRegisterMatrix2dVector(runtime.REGISTER_X)) {
        return 2;
    }

    if (!runtime.isRegisterMatrix3dVector(runtime.REGISTER_X)) {
        return 0;
    }

    return if (runtime.getVectorRegisterPolarMode(runtime.REGISTER_X) == runtime.amPolarCYL) 4 else 3;
}

pub fn getType() void {
    const data_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    const angular_mode: u32 = @intCast(runtime.getRegisterAngularMode(runtime.REGISTER_X));

    switch (data_type) {
        runtime.dtLongInteger, runtime.dtTime, runtime.dtDate, runtime.dtString, runtime.dtReal34Matrix, runtime.dtConfig => {
            if (runtime.isRegisterMatrixVector(runtime.REGISTER_X)) {
                const header = runtime.registerMatrixHeaderPtr(runtime.REGISTER_X);
                pushRealOut(data_type * 1000 + 100 * angleCode(angular_mode) + 10 * realMatrixVectorPolarCode() + matrixVectorShape(header));
            } else if (data_type == runtime.dtReal34Matrix) {
                const header = runtime.registerMatrixHeaderPtr(runtime.REGISTER_X);
                const shape = matrixVectorShape(header);

                if (shape != 0) {
                    pushRealOut(data_type * 1000 + shape);
                } else {
                    pushIntegerOut(data_type);
                }
            } else {
                pushIntegerOut(data_type);
            }
        },
        runtime.dtComplex34Matrix => {
            const header = runtime.registerMatrixHeaderPtr(runtime.REGISTER_X);
            const is_polar = runtime.getComplexRegisterPolarMode(runtime.REGISTER_X) != 0;
            const angle: u32 = if (is_polar) angleCode(angular_mode) else 0;
            const pol_rec: u32 = if (is_polar) 1 else 0;

            pushRealOut(data_type * 1000 + 100 * angle + 10 * pol_rec + matrixVectorShape(header));
        },
        runtime.dtShortInteger, runtime.dtReal34, runtime.dtComplex34 => {
            const short_bits: u32 = @intCast(angular_mode & 0x1f);
            const value: u32 = if (data_type == runtime.dtShortInteger)
                10 * (data_type * 100 + short_bits)
            else
                100 * (data_type * 10 + angleCode(angular_mode));

            pushRealOut(value);
        },
        else => {},
    }

    runtime.temporaryInformation = runtime.TI_REGTYPE;
}
