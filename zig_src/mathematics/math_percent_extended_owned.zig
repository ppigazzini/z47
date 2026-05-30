const std = @import("std");
const runtime = @import("math_command_wrappers_runtime.zig");

const no_register = @as(runtime.calcRegister_t, -1);

pub fn percentMRR(unused_but_mandatory_parameter: u16) void {
    var x_value: runtime.real_t = undefined;
    var y_value: runtime.real_t = undefined;
    var z_value: runtime.real_t = undefined;
    var result: runtime.real_t = undefined;

    _ = unused_but_mandatory_parameter;

    if (!runtime.saveLastX()) {
        return;
    }

    if (runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value) and runtime.getRegisterAsReal(runtime.REGISTER_Y, &y_value) and runtime.getRegisterAsReal(runtime.REGISTER_Z, &z_value)) {
        if (runtime.realIsZero(&x_value) and runtime.realIsZero(&y_value)) {
            if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
                runtime.realSetNaN(&result);
            } else {
                runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            }
        } else if (runtime.realIsZero(&y_value)) {
            if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
                result = runtime.z47_math_wrappers_const_plus_infinity().*;
                if (runtime.realIsNegative(&x_value)) {
                    result.bits |= 0x80;
                }
            } else {
                runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            }
        } else {
            runtime.realDivide(&x_value, &y_value, &result, &runtime.ctxtReal75);
            runtime.realDivide(runtime.z47_math_wrappers_const_1(), &z_value, &z_value, &runtime.ctxtReal75);
            runtime.realPower(&result, &z_value, &result, &runtime.ctxtReal75);
            runtime.realSubtract(&result, runtime.z47_math_wrappers_const_1(), &result, &runtime.ctxtReal75);
            result.exponent += 2;
        }

        if (runtime.lastErrorCode == 0) {
            runtime.convertRealToResultRegister(&result, runtime.REGISTER_X, runtime.amNone);
            runtime.temporaryInformation = runtime.TI_PERC;
        }
    }

    runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, no_register, no_register);
    if (runtime.lastErrorCode == 0) {
        runtime.fnDropY(0);
    }
}

pub fn percentPlusMG(unused_but_mandatory_parameter: u16) void {
    var x_value: runtime.real_t = undefined;
    var y_value: runtime.real_t = undefined;
    var result: runtime.real_t = undefined;

    _ = unused_but_mandatory_parameter;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value) or !runtime.getRegisterAsReal(runtime.REGISTER_Y, &y_value)) {
        return;
    }

    if (!runtime.saveLastX()) {
        return;
    }

    if (runtime.realCompareEqual(&x_value, runtime.z47_math_wrappers_const_100()) and runtime.realIsZero(&y_value)) {
        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.realSetNaN(&result);
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            return;
        }
    } else if (runtime.realCompareEqual(&x_value, runtime.z47_math_wrappers_const_100())) {
        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            result = runtime.z47_math_wrappers_const_plus_infinity().*;
            if (runtime.realIsNegative(&y_value)) {
                result.bits |= 0x80;
            }
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            return;
        }
    } else {
        runtime.realDivide(&x_value, runtime.z47_math_wrappers_const_100(), &result, &runtime.ctxtReal34);
        runtime.realSubtract(runtime.z47_math_wrappers_const_1(), &result, &result, &runtime.ctxtReal34);
        runtime.realDivide(&y_value, &result, &result, &runtime.ctxtReal34);
    }

    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
    runtime.convertRealToReal34ResultRegister(&result, runtime.REGISTER_X);
    runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.amNone);
    runtime.adjustResult(runtime.REGISTER_X, false, true, runtime.REGISTER_X, no_register, no_register);
}

pub fn percentT(unused_but_mandatory_parameter: u16) void {
    var x_value: runtime.real_t = undefined;
    var y_value: runtime.real_t = undefined;
    var result: runtime.real_t = undefined;
    var write_result = false;

    _ = unused_but_mandatory_parameter;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value) or !runtime.getRegisterAsReal(runtime.REGISTER_Y, &y_value)) {
        return;
    }

    if (!runtime.saveLastX()) {
        return;
    }

    if (runtime.realIsZero(&x_value) and runtime.realIsZero(&y_value)) {
        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.realSetNaN(&result);
            write_result = true;
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        }
    } else if (runtime.realIsZero(&y_value)) {
        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            result = runtime.z47_math_wrappers_const_plus_infinity().*;
            if (runtime.realIsNegative(&x_value)) {
                result.bits |= 0x80;
            }
            write_result = true;
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        }
    } else {
        x_value.exponent += 2;
        runtime.realDivide(&x_value, &y_value, &result, &runtime.ctxtReal39);
        write_result = true;
    }

    if (write_result) {
        runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
        runtime.convertRealToReal34ResultRegister(&result, runtime.REGISTER_X);
    }

    runtime.adjustResult(runtime.REGISTER_X, false, true, runtime.REGISTER_X, no_register, no_register);
    runtime.temporaryInformation = runtime.TI_PERC;
}

pub fn deltaPercent(unused_but_mandatory_parameter: u16) void {
    var x_value: runtime.real_t = undefined;
    var y_value: runtime.real_t = undefined;
    var result = std.mem.zeroes(runtime.real_t);

    _ = unused_but_mandatory_parameter;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value) or !runtime.getRegisterAsReal(runtime.REGISTER_Y, &y_value)) {
        return;
    }

    if (!runtime.saveLastX()) {
        return;
    }

    if (runtime.realIsZero(&x_value) and runtime.realCompareEqual(&x_value, &y_value)) {
        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.realSetNaN(&result);
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        }
    } else if (runtime.realIsZero(&y_value)) {
        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            result = runtime.z47_math_wrappers_const_plus_infinity().*;
            if (runtime.realIsZero(&x_value)) {
                result.bits |= 0x80;
            }
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        }
    } else {
        runtime.realSubtract(&x_value, &y_value, &result, &runtime.ctxtReal39);
        runtime.realDivide(&result, &y_value, &result, &runtime.ctxtReal39);
        result.exponent += 2;
    }

    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
    runtime.convertRealToReal34ResultRegister(&result, runtime.REGISTER_X);
    runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.amNone);
    runtime.adjustResult(runtime.REGISTER_X, false, true, runtime.REGISTER_X, no_register, no_register);
    runtime.temporaryInformation = runtime.TI_PERCD;
}