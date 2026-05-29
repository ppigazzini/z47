const runtime = @import("math_command_wrappers_runtime.zig");

const SpecialKind = enum {
    nan,
    infinite,
    special,
};

fn typeErrorX() void {
    runtime.setTemporaryInformation(false);
    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_T);
}

fn matchesRealSpecial(value: *align(1) const runtime.real34_t, comptime kind: SpecialKind) bool {
    return switch (kind) {
        .nan => runtime.real34IsNaN(value),
        .infinite => runtime.real34IsInfinite(value),
        .special => runtime.real34IsNaN(value) or runtime.real34IsInfinite(value),
    };
}

fn matchesComplexSpecial(value: *align(1) const runtime.complex34_t, comptime kind: SpecialKind) bool {
    return matchesRealSpecial(&value.real, kind) or matchesRealSpecial(&value.imag, kind);
}

fn checkMatrixElements(register_data_type: u32, comptime kind: SpecialKind) bool {
    const ptr = runtime.getRegisterDataPointer(runtime.REGISTER_X) orelse unreachable;
    const header: *align(1) runtime.matrixHeader_t = @ptrCast(ptr);
    const bytes: [*]align(1) const u8 = @ptrCast(ptr);
    const elements: usize = @as(usize, header.matrixRows) * @as(usize, header.matrixColumns);

    switch (register_data_type) {
        runtime.dtReal34Matrix => {
            const values: [*]align(1) const runtime.real34_t = @ptrCast(bytes + @sizeOf(runtime.matrixHeader_t));
            var index: usize = 0;
            while (index < elements) : (index += 1) {
                if (matchesRealSpecial(&values[index], kind)) {
                    return true;
                }
            }
        },
        runtime.dtComplex34Matrix => {
            const values: [*]align(1) const runtime.complex34_t = @ptrCast(bytes + @sizeOf(runtime.matrixHeader_t));
            var index: usize = 0;
            while (index < elements) : (index += 1) {
                if (matchesComplexSpecial(&values[index], kind)) {
                    return true;
                }
            }
        },
        else => return false,
    }

    return false;
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

pub fn checkNaN() void {
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);

    switch (register_data_type) {
        runtime.dtComplex34 => {
            runtime.setTemporaryInformation(matchesComplexSpecial(runtime.registerComplex34Ptr(runtime.REGISTER_X), .nan));
        },
        runtime.dtTime, runtime.dtDate, runtime.dtReal34 => {
            runtime.setTemporaryInformation(matchesRealSpecial(runtime.registerReal34Ptr(runtime.REGISTER_X), .nan));
        },
        runtime.dtReal34Matrix, runtime.dtComplex34Matrix => {
            runtime.setTemporaryInformation(checkMatrixElements(register_data_type, .nan));
        },
        else => typeErrorX(),
    }
}

pub fn checkInfinite() void {
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);

    switch (register_data_type) {
        runtime.dtComplex34 => {
            runtime.setTemporaryInformation(matchesComplexSpecial(runtime.registerComplex34Ptr(runtime.REGISTER_X), .infinite));
        },
        runtime.dtTime, runtime.dtDate, runtime.dtReal34 => {
            runtime.setTemporaryInformation(matchesRealSpecial(runtime.registerReal34Ptr(runtime.REGISTER_X), .infinite));
        },
        runtime.dtReal34Matrix, runtime.dtComplex34Matrix => {
            runtime.setTemporaryInformation(checkMatrixElements(register_data_type, .infinite));
        },
        else => typeErrorX(),
    }
}

pub fn checkSpecial() void {
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);

    switch (register_data_type) {
        runtime.dtComplex34 => {
            runtime.setTemporaryInformation(matchesComplexSpecial(runtime.registerComplex34Ptr(runtime.REGISTER_X), .special));
        },
        runtime.dtTime, runtime.dtDate, runtime.dtReal34 => {
            runtime.setTemporaryInformation(matchesRealSpecial(runtime.registerReal34Ptr(runtime.REGISTER_X), .special));
        },
        runtime.dtReal34Matrix, runtime.dtComplex34Matrix => {
            runtime.setTemporaryInformation(checkMatrixElements(register_data_type, .special));
        },
        else => typeErrorX(),
    }
}