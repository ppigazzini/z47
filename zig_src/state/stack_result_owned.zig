const runtime = @import("stack_runtime.zig");

fn adjustResultArgumentIsComplex(reg: runtime.calcRegister_t) bool {
    if (reg < 0) {
        return false;
    }

    const data_type = runtime.getRegisterDataType(reg);
    return data_type == runtime.dtComplex34 or data_type == runtime.dtComplex34Matrix;
}

pub fn toReal(unused_but_mandatory_parameter: u16) void {
    if (runtime.tryFnToRealComplexZero()) {
        return;
    }

    if (runtime.tryFnToRealLongInteger()) {
        return;
    }

    if (runtime.tryFnToRealShortInteger()) {
        return;
    }

    if (runtime.tryFnToRealTime()) {
        return;
    }

    if (runtime.tryFnToRealDate()) {
        return;
    }

    if (runtime.tryFnToRealReal34()) {
        return;
    }

    runtime.toRealRetained(unused_but_mandatory_parameter);
}

pub fn adjustResult(
    res: runtime.calcRegister_t,
    drop_y: bool,
    set_cpx_res: bool,
    op1: runtime.calcRegister_t,
    op2: runtime.calcRegister_t,
    op3: runtime.calcRegister_t,
) void {
    const one_argument_is_complex = adjustResultArgumentIsComplex(op1) or
        adjustResultArgumentIsComplex(op2) or
        adjustResultArgumentIsComplex(op3);

    if (runtime.adjustResultScalarCore(res) or runtime.adjustResultRealMatrixCore(res) or runtime.adjustResultComplexMatrixCore(res)) {
        if (runtime.lastErrorCode != runtime.ERROR_NONE) {
            return;
        }
    } else if (runtime.lastErrorCode != runtime.ERROR_NONE) {
        runtime.undoRetained();
        return;
    }

    if (set_cpx_res and one_argument_is_complex and runtime.getRegisterDataType(res) != runtime.dtString) {
        runtime.adjustResultSetCpxRes();
    }

    if (drop_y) {
        @import("stack.zig").fnDropY(0);
    }
}