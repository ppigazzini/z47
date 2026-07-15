const runtime = @import("../command_wrappers/runtime.zig");
const validation_owned = @import("vector_validation.zig");

const no_register = @as(runtime.calcRegister_t, -1);

pub fn tryCrossMatrices() bool {
    const matrix_kinds = validation_owned.classifyCurrentOperands();

    if (!matrix_kinds.hasAnyMatrix()) {
        return false;
    }

    if (!matrix_kinds.areBothMatrices()) {
        return false;
    }

    if (!runtime.saveLastX()) {
        return true;
    }

    if (matrix_kinds.x_is_real_matrix and matrix_kinds.y_is_real_matrix) {
        var x_matrix: runtime.real34Matrix_t = undefined;
        var y_matrix: runtime.real34Matrix_t = undefined;
        var result: runtime.real34Matrix_t = undefined;

        runtime.linkToRealMatrixRegister(runtime.REGISTER_X, &x_matrix);
        runtime.linkToRealMatrixRegister(runtime.REGISTER_Y, &y_matrix);

        if (!validation_owned.isValidCrossRealVectors(&x_matrix, &y_matrix)) {
            runtime.displayCalcErrorMessage(runtime.ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        } else {
            runtime.crossRealVectors(&y_matrix, &x_matrix, &result);
            runtime.convertReal34MatrixToReal34MatrixRegister(&result, runtime.REGISTER_X);
            runtime.realMatrixFree(&result);
        }

        runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, no_register, no_register);
        return true;
    }

    if (matrix_kinds.x_is_real_matrix) {
        runtime.convertReal34MatrixRegisterToComplex34MatrixRegister(runtime.REGISTER_X, runtime.REGISTER_X);
    } else if (matrix_kinds.y_is_real_matrix) {
        runtime.convertReal34MatrixRegisterToComplex34MatrixRegister(runtime.REGISTER_Y, runtime.REGISTER_Y);
    }
    if (runtime.lastErrorCode != 0) { // OOM during the real->complex promote (crossCpmaRema/crossRemaCpma)
        return true;
    }

    var x_matrix: runtime.complex34Matrix_t = undefined;
    var y_matrix: runtime.complex34Matrix_t = undefined;
    var result: runtime.complex34Matrix_t = undefined;

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &x_matrix);
    runtime.linkToComplexMatrixRegister(runtime.REGISTER_Y, &y_matrix);

    if (!validation_owned.isValidCrossComplexVectors(&x_matrix, &y_matrix)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
    } else {
        runtime.crossComplexVectors(&y_matrix, &x_matrix, &result);
        runtime.convertComplex34MatrixToComplex34MatrixRegister(&result, runtime.REGISTER_X);
        runtime.complexMatrixFree(&result);
    }

    runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, no_register, no_register);
    return true;
}
