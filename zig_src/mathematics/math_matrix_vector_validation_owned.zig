const runtime = @import("math_command_wrappers_runtime.zig");

pub const MatrixOperandKinds = struct {
    x_is_real_matrix: bool,
    x_is_complex_matrix: bool,
    y_is_real_matrix: bool,
    y_is_complex_matrix: bool,

    pub fn hasAnyMatrix(self: MatrixOperandKinds) bool {
        return self.x_is_real_matrix or self.x_is_complex_matrix or self.y_is_real_matrix or self.y_is_complex_matrix;
    }

    pub fn areBothMatrices(self: MatrixOperandKinds) bool {
        return (self.x_is_real_matrix or self.x_is_complex_matrix) and (self.y_is_real_matrix or self.y_is_complex_matrix);
    }
};

pub fn classifyCurrentOperands() MatrixOperandKinds {
    const type_x = runtime.getRegisterDataType(runtime.REGISTER_X);
    const type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);

    return .{
        .x_is_real_matrix = type_x == runtime.dtReal34Matrix,
        .x_is_complex_matrix = type_x == runtime.dtComplex34Matrix,
        .y_is_real_matrix = type_y == runtime.dtReal34Matrix,
        .y_is_complex_matrix = type_y == runtime.dtComplex34Matrix,
    };
}

pub fn isValidCrossRealVectors(x_matrix: *const runtime.real34Matrix_t, y_matrix: *const runtime.real34Matrix_t) bool {
    const x_size = runtime.realVectorSize(x_matrix);
    const y_size = runtime.realVectorSize(y_matrix);

    return x_size != 0 and y_size != 0 and x_size <= 3 and y_size <= 3;
}

pub fn isValidCrossComplexVectors(x_matrix: *const runtime.complex34Matrix_t, y_matrix: *const runtime.complex34Matrix_t) bool {
    const x_size = runtime.complexVectorSize(x_matrix);
    const y_size = runtime.complexVectorSize(y_matrix);

    return x_size != 0 and y_size != 0 and x_size <= 3 and y_size <= 3;
}

pub fn isValidDotRealVectors(x_matrix: *const runtime.real34Matrix_t, y_matrix: *const runtime.real34Matrix_t) bool {
    const x_size = runtime.realVectorSize(x_matrix);
    const y_size = runtime.realVectorSize(y_matrix);

    return x_size != 0 and y_size != 0 and x_size == y_size;
}

pub fn isValidDotComplexVectors(x_matrix: *const runtime.complex34Matrix_t, y_matrix: *const runtime.complex34Matrix_t) bool {
    const x_size = runtime.complexVectorSize(x_matrix);
    const y_size = runtime.complexVectorSize(y_matrix);

    return x_size != 0 and y_size != 0 and x_size == y_size;
}
