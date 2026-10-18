const abi = @import("abi");
const runtime = @import("../command_wrappers/runtime.zig");

const no_register = @as(runtime.calcRegister_t, -1);

const dyadic_integer_add: u8 = 0;
const dyadic_integer_subtract: u8 = 1;
const dyadic_integer_multiply: u8 = 2;

fn real34DataPointer(regist: runtime.calcRegister_t) *runtime.real34_t {
    return abi.registerReal34Aligned(regist);
}

fn applyDyadicRealOperation(operation: u8, lhs: *const runtime.real_t, rhs: *const runtime.real_t, result: *runtime.real_t) void {
    switch (operation) {
        dyadic_integer_add => runtime.realAdd(lhs, rhs, result, &runtime.ctxtReal39),
        dyadic_integer_subtract => runtime.realSubtract(lhs, rhs, result, &runtime.ctxtReal39),
        dyadic_integer_multiply => runtime.realMultiply(lhs, rhs, result, &runtime.ctxtReal39),
        else => unreachable,
    }
}

fn applyDyadicReal34Operation(operation: u8, lhs: *const runtime.real34_t, rhs: *const runtime.real34_t, result: *runtime.real34_t) void {
    switch (operation) {
        dyadic_integer_add => runtime.real34Add(lhs, rhs, result),
        dyadic_integer_subtract => runtime.real34Subtract(lhs, rhs, result),
        dyadic_integer_multiply => runtime.real34Multiply(lhs, rhs, result),
        else => unreachable,
    }
}

// The exact long integer and real34 combination of each operation; false where
// it does not apply and the 39-digit real path is taken.
fn applyFastLongIntegerReal34(operation: u8, integer_register: runtime.calcRegister_t, real34: *const runtime.real34_t, integer_first: bool, result: *runtime.real34_t) bool {
    return switch (operation) {
        dyadic_integer_add => runtime.addSubtractLongIntegerReal34(integer_register, real34, integer_first, false, result),
        dyadic_integer_subtract => runtime.addSubtractLongIntegerReal34(integer_register, real34, integer_first, true, result),
        dyadic_integer_multiply => runtime.multiplyLongIntegerReal34(integer_register, real34, result),
        else => unreachable,
    };
}

fn divisionDomainError(function_name: [*:0]const u8, message: [*:0]const u8) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
    runtime.moreInfoOnError(function_name, message, null, null);
}

fn tryScalarIntRealArithmetic(operation: u8) bool {
    const type_x = runtime.getRegisterDataType(runtime.REGISTER_X);
    const type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);
    const x_is_real = type_x == runtime.dtReal34;
    const y_is_real = type_y == runtime.dtReal34;
    const x_is_int = type_x == runtime.dtLongInteger or type_x == runtime.dtShortInteger;
    const y_is_int = type_y == runtime.dtLongInteger or type_y == runtime.dtShortInteger;

    if (!((x_is_real and y_is_int) or (y_is_real and x_is_int))) {
        return false;
    }

    if (!runtime.saveLastX()) {
        return true;
    }

    if (x_is_real) {
        var y_value: runtime.real_t = undefined;
        var x_value: runtime.real_t = undefined;
        const x_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_X);

        if (x_angular_mode == runtime.amNone) {
            // The exact path first: a long integer and a finite real34 combine
            // through their scaled coefficients, a short integer through a real34.
            if (type_y == runtime.dtLongInteger) {
                if (!applyFastLongIntegerReal34(operation, runtime.REGISTER_Y, real34DataPointer(runtime.REGISTER_X), true, real34DataPointer(runtime.REGISTER_X))) {
                    runtime.convertLongIntegerRegisterToReal(runtime.REGISTER_Y, &y_value, &runtime.ctxtReal39);
                    runtime.real34ToReal(real34DataPointer(runtime.REGISTER_X), &x_value);
                    applyDyadicRealOperation(operation, &y_value, &x_value, &x_value);
                    runtime.convertRealToReal34ResultRegister(&x_value, runtime.REGISTER_X);
                }
            } else {
                runtime.convertShortIntegerRegisterToReal34Register(runtime.REGISTER_Y, runtime.REGISTER_Y);
                applyDyadicReal34Operation(operation, real34DataPointer(runtime.REGISTER_Y), real34DataPointer(runtime.REGISTER_X), real34DataPointer(runtime.REGISTER_X));
            }
        } else {
            if (type_y == runtime.dtLongInteger) {
                runtime.convertLongIntegerRegisterToReal(runtime.REGISTER_Y, &y_value, &runtime.ctxtReal39);
            } else {
                runtime.convertShortIntegerRegisterToReal(runtime.REGISTER_Y, &y_value, &runtime.ctxtReal39);
            }
            runtime.real34ToReal(real34DataPointer(runtime.REGISTER_X), &x_value);
            runtime.convertAngleFromTo(&x_value, x_angular_mode, runtime.currentAngularMode, &runtime.ctxtReal39);
            applyDyadicRealOperation(operation, &y_value, &x_value, &x_value);
            runtime.convertRealToReal34ResultRegister(&x_value, runtime.REGISTER_X);
            runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.currentAngularMode);
        }
    } else {
        var y_value: runtime.real_t = undefined;
        var x_value: runtime.real_t = undefined;
        var result: runtime.real34_t = undefined;
        const y_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_Y);

        if (y_angular_mode == runtime.amNone) {
            if (type_x == runtime.dtLongInteger) {
                if (applyFastLongIntegerReal34(operation, runtime.REGISTER_X, real34DataPointer(runtime.REGISTER_Y), false, &result)) {
                    runtime.convertReal34ToReal34Register(&result, runtime.REGISTER_X);
                } else {
                    runtime.real34ToReal(real34DataPointer(runtime.REGISTER_Y), &y_value);
                    runtime.convertLongIntegerRegisterToReal(runtime.REGISTER_X, &x_value, &runtime.ctxtReal39);
                    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
                    applyDyadicRealOperation(operation, &y_value, &x_value, &x_value);
                    runtime.convertRealToReal34ResultRegister(&x_value, runtime.REGISTER_X);
                }
            } else {
                runtime.convertShortIntegerRegisterToReal34Register(runtime.REGISTER_X, runtime.REGISTER_X);
                applyDyadicReal34Operation(operation, real34DataPointer(runtime.REGISTER_Y), real34DataPointer(runtime.REGISTER_X), real34DataPointer(runtime.REGISTER_X));
            }
        } else {
            runtime.real34ToReal(real34DataPointer(runtime.REGISTER_Y), &y_value);
            if (type_x == runtime.dtLongInteger) {
                runtime.convertLongIntegerRegisterToReal(runtime.REGISTER_X, &x_value, &runtime.ctxtReal39);
            } else {
                runtime.convertShortIntegerRegisterToReal(runtime.REGISTER_X, &x_value, &runtime.ctxtReal39);
            }
            runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
            runtime.convertAngleFromTo(&y_value, y_angular_mode, runtime.currentAngularMode, &runtime.ctxtReal39);
            applyDyadicRealOperation(operation, &y_value, &x_value, &x_value);
            runtime.convertRealToReal34ResultRegister(&x_value, runtime.REGISTER_X);
            runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.currentAngularMode);
        }
    }

    runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, runtime.REGISTER_Y, no_register);
    return true;
}

fn tryScalarRealArithmetic(operation: u8) bool {
    if (runtime.getRegisterDataType(runtime.REGISTER_X) != runtime.dtReal34 or runtime.getRegisterDataType(runtime.REGISTER_Y) != runtime.dtReal34) {
        return false;
    }

    if (!runtime.saveLastX()) {
        return true;
    }

    const y_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_Y);
    const x_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_X);
    switch (operation) {
        dyadic_integer_add, dyadic_integer_subtract => {
            if (y_angular_mode == runtime.amNone and x_angular_mode == runtime.amNone) {
                applyDyadicReal34Operation(operation, real34DataPointer(runtime.REGISTER_Y), real34DataPointer(runtime.REGISTER_X), real34DataPointer(runtime.REGISTER_X));
            } else {
                var y_value: runtime.real_t = undefined;
                var x_value: runtime.real_t = undefined;
                var resolved_y_mode = y_angular_mode;
                var resolved_x_mode = x_angular_mode;

                runtime.real34ToReal(real34DataPointer(runtime.REGISTER_Y), &y_value);
                runtime.real34ToReal(real34DataPointer(runtime.REGISTER_X), &x_value);
                if (resolved_y_mode == runtime.amNone) {
                    resolved_y_mode = runtime.currentAngularMode;
                } else if (resolved_x_mode == runtime.amNone) {
                    resolved_x_mode = runtime.currentAngularMode;
                }
                runtime.convertAngleFromTo(&y_value, resolved_y_mode, runtime.currentAngularMode, &runtime.ctxtReal39);
                runtime.convertAngleFromTo(&x_value, resolved_x_mode, runtime.currentAngularMode, &runtime.ctxtReal39);
                applyDyadicRealOperation(operation, &y_value, &x_value, &x_value);
                runtime.convertRealToReal34ResultRegister(&x_value, runtime.REGISTER_X);
                runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.currentAngularMode);
            }
        },
        dyadic_integer_multiply => {
            if (y_angular_mode == runtime.amNone and x_angular_mode == runtime.amNone) {
                runtime.real34Multiply(real34DataPointer(runtime.REGISTER_Y), real34DataPointer(runtime.REGISTER_X), real34DataPointer(runtime.REGISTER_X));
            } else if (y_angular_mode != runtime.amNone and x_angular_mode != runtime.amNone) {
                runtime.real34Multiply(real34DataPointer(runtime.REGISTER_Y), real34DataPointer(runtime.REGISTER_X), real34DataPointer(runtime.REGISTER_X));
                runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.amNone);
            } else {
                var y_value: runtime.real_t = undefined;
                var x_value: runtime.real_t = undefined;

                runtime.real34ToReal(real34DataPointer(runtime.REGISTER_Y), &y_value);
                runtime.real34ToReal(real34DataPointer(runtime.REGISTER_X), &x_value);
                runtime.realMultiply(&y_value, &x_value, &x_value, &runtime.ctxtReal39);
                runtime.convertAngleFromTo(
                    &x_value,
                    if (y_angular_mode != runtime.amNone) y_angular_mode else x_angular_mode,
                    runtime.currentAngularMode,
                    &runtime.ctxtReal39,
                );
                runtime.convertRealToReal34ResultRegister(&x_value, runtime.REGISTER_X);
                runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.currentAngularMode);
            }
        },
        else => unreachable,
    }

    runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, runtime.REGISTER_Y, no_register);
    return true;
}

fn tryScalarIntegerOverRealDivide() bool {
    const type_x = runtime.getRegisterDataType(runtime.REGISTER_X);
    const type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);
    if (type_x != runtime.dtReal34 or (type_y != runtime.dtLongInteger and type_y != runtime.dtShortInteger)) {
        return false;
    }

    runtime.copySourceRegisterToDestRegister(runtime.REGISTER_X, runtime.REGISTER_L);

    const function_name: [*:0]const u8 = if (type_y == runtime.dtLongInteger) "In function divLonIReal:" else "In function divShoIReal:";
    var y_value: runtime.real_t = undefined;
    var result: runtime.real34_t = undefined;
    if (type_y == runtime.dtLongInteger) {
        runtime.convertLongIntegerRegisterToReal(runtime.REGISTER_Y, &y_value, &runtime.ctxtReal39);
    } else {
        runtime.convertShortIntegerRegisterToReal(runtime.REGISTER_Y, &y_value, &runtime.ctxtReal39);
    }

    runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.amNone);
    if (runtime.real34IsZero(real34DataPointer(runtime.REGISTER_X))) {
        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            // The division itself yields the NaN or the signed infinity.
            var numerator: runtime.real34_t = undefined;

            runtime.realToReal34(&y_value, &numerator);
            runtime.real34Divide(&numerator, real34DataPointer(runtime.REGISTER_X), real34DataPointer(runtime.REGISTER_X));
        } else if (runtime.realIsZero(&y_value)) {
            divisionDomainError(function_name, "cannot divide 0 by 0");
        } else {
            divisionDomainError(function_name, if (type_y == runtime.dtLongInteger) "cannot divide a long integer by 0" else "cannot divide a short integer by 0");
        }
    } else if (type_y == runtime.dtLongInteger) {
        if (runtime.divideRegisterValuesToReal34(runtime.REGISTER_Y, runtime.REGISTER_X, &result)) {
            real34DataPointer(runtime.REGISTER_X).* = result;
        } else {
            var x_value: runtime.real_t = undefined;

            runtime.real34ToReal(real34DataPointer(runtime.REGISTER_X), &x_value);
            runtime.realDivide(&y_value, &x_value, &x_value, &runtime.ctxtReal39);
            runtime.convertRealToReal34ResultRegister(&x_value, runtime.REGISTER_X);
        }
    } else {
        runtime.convertShortIntegerRegisterToReal34Register(runtime.REGISTER_Y, runtime.REGISTER_Y);
        runtime.real34Divide(real34DataPointer(runtime.REGISTER_Y), real34DataPointer(runtime.REGISTER_X), real34DataPointer(runtime.REGISTER_X));
    }

    runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, runtime.REGISTER_Y, no_register);
    return true;
}

fn tryScalarRealOverIntegerDivide() bool {
    const type_x = runtime.getRegisterDataType(runtime.REGISTER_X);
    const type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);
    if ((type_x != runtime.dtLongInteger and type_x != runtime.dtShortInteger) or type_y != runtime.dtReal34) {
        return false;
    }

    runtime.copySourceRegisterToDestRegister(runtime.REGISTER_X, runtime.REGISTER_L);

    const function_name: [*:0]const u8 = if (type_x == runtime.dtLongInteger) "In function divRealLonI:" else "In function divRealShoI:";
    var x_value: runtime.real_t = undefined;
    var result: runtime.real34_t = undefined;
    var short_integer_value: u64 = 0;
    var short_integer_sign: i16 = 0;
    var negative_zero = false;
    if (type_x == runtime.dtLongInteger) {
        runtime.convertLongIntegerRegisterToReal(runtime.REGISTER_X, &x_value, &runtime.ctxtReal39);
    } else {
        // A negative zero short integer (sign-magnitude or one's complement)
        // keeps its sign on the infinite quotient.
        runtime.convertShortIntegerRegisterToUInt64(runtime.REGISTER_X, &short_integer_sign, &short_integer_value);
        negative_zero = short_integer_sign != 0 and short_integer_value == 0;
        runtime.convertShortIntegerRegisterToReal(runtime.REGISTER_X, &x_value, &runtime.ctxtReal39);
    }

    const x_is_zero = if (type_x == runtime.dtLongInteger) runtime.realIsZero(&x_value) else short_integer_value == 0;
    if (x_is_zero) {
        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            var denominator: runtime.real34_t = undefined;

            runtime.realToReal34(&x_value, &denominator);
            runtime.real34SetPositiveSign(&denominator);
            runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
            runtime.real34Divide(real34DataPointer(runtime.REGISTER_Y), &denominator, real34DataPointer(runtime.REGISTER_X));
            if (negative_zero and !runtime.real34IsNaN(real34DataPointer(runtime.REGISTER_X))) {
                real34DataPointer(runtime.REGISTER_X).bytes[15] ^= runtime.DECNEG;
            }
        } else {
            runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
            if (runtime.real34IsZero(real34DataPointer(runtime.REGISTER_Y))) {
                divisionDomainError(function_name, "cannot divide 0 by 0");
            } else {
                divisionDomainError(function_name, "cannot divide a real34 by 0");
            }
        }
    } else {
        var y_value: runtime.real_t = undefined;
        const y_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_Y);

        if (y_angular_mode == runtime.amNone) {
            if (type_x == runtime.dtLongInteger) {
                if (runtime.divideRegisterValuesToReal34(runtime.REGISTER_Y, runtime.REGISTER_X, &result)) {
                    runtime.convertReal34ToReal34Register(&result, runtime.REGISTER_X);
                } else {
                    runtime.real34ToReal(real34DataPointer(runtime.REGISTER_Y), &y_value);
                    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
                    runtime.realDivide(&y_value, &x_value, &x_value, &runtime.ctxtReal39);
                    runtime.convertRealToReal34ResultRegister(&x_value, runtime.REGISTER_X);
                }
            } else {
                runtime.convertShortIntegerRegisterToReal34Register(runtime.REGISTER_X, runtime.REGISTER_X);
                runtime.real34Divide(real34DataPointer(runtime.REGISTER_Y), real34DataPointer(runtime.REGISTER_X), real34DataPointer(runtime.REGISTER_X));
            }
        } else {
            runtime.real34ToReal(real34DataPointer(runtime.REGISTER_Y), &y_value);
            runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
            runtime.convertAngleFromTo(&y_value, y_angular_mode, runtime.currentAngularMode, &runtime.ctxtReal39);
            runtime.realDivide(&y_value, &x_value, &x_value, &runtime.ctxtReal39);
            runtime.convertRealToReal34ResultRegister(&x_value, runtime.REGISTER_X);
            runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.currentAngularMode);
        }
    }

    runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, runtime.REGISTER_Y, no_register);
    return true;
}

fn tryScalarRealOverRealDivide() bool {
    if (runtime.getRegisterDataType(runtime.REGISTER_X) != runtime.dtReal34 or runtime.getRegisterDataType(runtime.REGISTER_Y) != runtime.dtReal34) {
        return false;
    }

    runtime.copySourceRegisterToDestRegister(runtime.REGISTER_X, runtime.REGISTER_L);

    const y_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_Y);
    const x_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_X);

    if (runtime.real34IsZero(real34DataPointer(runtime.REGISTER_X))) {
        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.real34Divide(real34DataPointer(runtime.REGISTER_Y), real34DataPointer(runtime.REGISTER_X), real34DataPointer(runtime.REGISTER_X));
            runtime.setRegisterAngularMode(runtime.REGISTER_X, if (y_angular_mode != runtime.amNone and x_angular_mode == runtime.amNone) runtime.currentAngularMode else runtime.amNone);
        } else if (runtime.real34IsZero(real34DataPointer(runtime.REGISTER_Y))) {
            divisionDomainError("In function divRealReal:", "cannot divide 0 by 0");
        } else {
            divisionDomainError("In function divRealReal:", "cannot divide a real34 by 0");
        }
    } else {
        if (y_angular_mode == runtime.amNone) {
            runtime.real34Divide(real34DataPointer(runtime.REGISTER_Y), real34DataPointer(runtime.REGISTER_X), real34DataPointer(runtime.REGISTER_X));
            runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.amNone);
        } else {
            var y_value: runtime.real_t = undefined;
            var x_value: runtime.real_t = undefined;

            runtime.real34ToReal(real34DataPointer(runtime.REGISTER_Y), &y_value);
            runtime.real34ToReal(real34DataPointer(runtime.REGISTER_X), &x_value);
            if (x_angular_mode != runtime.amNone) {
                runtime.convertAngleFromTo(&x_value, x_angular_mode, y_angular_mode, &runtime.ctxtReal39);
                runtime.realDivide(&y_value, &x_value, &x_value, &runtime.ctxtReal39);
                runtime.convertRealToReal34ResultRegister(&x_value, runtime.REGISTER_X);
                runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.amNone);
            } else {
                runtime.realDivide(&y_value, &x_value, &x_value, &runtime.ctxtReal39);
                runtime.convertAngleFromTo(&x_value, y_angular_mode, runtime.currentAngularMode, &runtime.ctxtReal39);
                runtime.convertRealToReal34ResultRegister(&x_value, runtime.REGISTER_X);
                runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.currentAngularMode);
            }
        }
    }

    runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, runtime.REGISTER_Y, no_register);
    return true;
}

pub fn tryScalarAdd() bool {
    return tryScalarIntRealArithmetic(dyadic_integer_add) or tryScalarRealArithmetic(dyadic_integer_add);
}

pub fn tryScalarSubtract() bool {
    return tryScalarIntRealArithmetic(dyadic_integer_subtract) or tryScalarRealArithmetic(dyadic_integer_subtract);
}

pub fn tryScalarMultiply() bool {
    return tryScalarIntRealArithmetic(dyadic_integer_multiply) or tryScalarRealArithmetic(dyadic_integer_multiply);
}

pub fn tryScalarDivide() bool {
    return tryScalarIntegerOverRealDivide() or tryScalarRealOverIntegerDivide() or tryScalarRealOverRealDivide();
}
