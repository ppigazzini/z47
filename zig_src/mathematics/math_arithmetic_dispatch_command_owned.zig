const runtime = @import("math_command_wrappers_runtime.zig");

const BranchFn = *const fn () callconv(.c) void;
const no_register = @as(runtime.calcRegister_t, -1);

const dyadic_integer_add: u8 = 0;
const dyadic_integer_subtract: u8 = 1;
const dyadic_integer_multiply: u8 = 2;

fn real34DataPointer(regist: runtime.calcRegister_t) *runtime.real34_t {
    return @as(*runtime.real34_t, @ptrCast(@alignCast(runtime.getRegisterDataPointer(regist).?)));
}

fn shortIntegerData(regist: runtime.calcRegister_t) *align(1) u64 {
    return @as(*align(1) u64, @ptrCast(runtime.getRegisterDataPointer(regist).?));
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

fn selectRemainingAddBranch(type_y: u32, type_x: u32) ?BranchFn {
    return switch (type_y) {
        runtime.dtLongInteger => switch (type_x) {
            runtime.dtTime => &runtime.addLonITime,
            runtime.dtDate => &runtime.addLonIDate,
            runtime.dtComplex34 => &runtime.addLonICplx,
            runtime.dtReal34Matrix => &runtime.addLonIRema,
            runtime.dtComplex34Matrix => &runtime.addLonICxma,
            else => null,
        },
        runtime.dtShortInteger => switch (type_x) {
            runtime.dtComplex34 => &runtime.addShoICplx,
            runtime.dtReal34Matrix => &runtime.addShoIRema,
            runtime.dtComplex34Matrix => &runtime.addShoICxma,
            else => null,
        },
        runtime.dtReal34 => switch (type_x) {
            runtime.dtTime => &runtime.addRealTime,
            runtime.dtDate => &runtime.addRealDate,
            runtime.dtComplex34 => &runtime.addRealCplx,
            runtime.dtReal34Matrix => &runtime.addRealRema,
            runtime.dtComplex34Matrix => &runtime.addRealCxma,
            else => null,
        },
        runtime.dtComplex34 => switch (type_x) {
            runtime.dtLongInteger => &runtime.addCplxLonI,
            runtime.dtShortInteger => &runtime.addCplxShoI,
            runtime.dtReal34 => &runtime.addCplxReal,
            runtime.dtComplex34 => &runtime.addCplxCplx,
            runtime.dtReal34Matrix => &runtime.addCplxRema,
            runtime.dtComplex34Matrix => &runtime.addCplxCxma,
            else => null,
        },
        runtime.dtTime => switch (type_x) {
            runtime.dtLongInteger => &runtime.addTimeLonI,
            runtime.dtTime => &runtime.addTimeTime,
            runtime.dtReal34 => &runtime.addTimeReal,
            else => null,
        },
        runtime.dtDate => switch (type_x) {
            runtime.dtLongInteger => &runtime.addDateLonI,
            runtime.dtReal34 => &runtime.addDateReal,
            else => null,
        },
        runtime.dtReal34Matrix => switch (type_x) {
            runtime.dtLongInteger => &runtime.addRemaLonI,
            runtime.dtShortInteger => &runtime.addRemaShoI,
            runtime.dtReal34 => &runtime.addRemaReal,
            runtime.dtComplex34 => &runtime.addRemaCplx,
            runtime.dtReal34Matrix => &runtime.addRemaRema,
            runtime.dtComplex34Matrix => &runtime.addRemaCxma,
            else => null,
        },
        runtime.dtComplex34Matrix => switch (type_x) {
            runtime.dtLongInteger => &runtime.addCxmaLonI,
            runtime.dtShortInteger => &runtime.addCxmaShoI,
            runtime.dtReal34 => &runtime.addCxmaReal,
            runtime.dtComplex34 => &runtime.addCxmaCplx,
            runtime.dtReal34Matrix => &runtime.addCxmaRema,
            runtime.dtComplex34Matrix => &runtime.addCxmaCxma,
            else => null,
        },
        else => null,
    };
}

fn selectRemainingSubtractBranch(type_y: u32, type_x: u32) ?BranchFn {
    return switch (type_y) {
        runtime.dtLongInteger => switch (type_x) {
            runtime.dtTime => &runtime.subLonITime,
            runtime.dtComplex34 => &runtime.subLonICplx,
            runtime.dtReal34Matrix => &runtime.subLonIRema,
            runtime.dtComplex34Matrix => &runtime.subLonICxma,
            else => null,
        },
        runtime.dtShortInteger => switch (type_x) {
            runtime.dtComplex34 => &runtime.subShoICplx,
            runtime.dtReal34Matrix => &runtime.subShoIRema,
            runtime.dtComplex34Matrix => &runtime.subShoICxma,
            else => null,
        },
        runtime.dtReal34 => switch (type_x) {
            runtime.dtTime => &runtime.subRealTime,
            runtime.dtComplex34 => &runtime.subRealCplx,
            runtime.dtReal34Matrix => &runtime.subRealRema,
            runtime.dtComplex34Matrix => &runtime.subRealCxma,
            else => null,
        },
        runtime.dtComplex34 => switch (type_x) {
            runtime.dtLongInteger => &runtime.subCplxLonI,
            runtime.dtShortInteger => &runtime.subCplxShoI,
            runtime.dtReal34 => &runtime.subCplxReal,
            runtime.dtComplex34 => &runtime.subCplxCplx,
            runtime.dtReal34Matrix => &runtime.subCplxRema,
            runtime.dtComplex34Matrix => &runtime.subCplxCxma,
            else => null,
        },
        runtime.dtTime => switch (type_x) {
            runtime.dtLongInteger => &runtime.subTimeLonI,
            runtime.dtTime => &runtime.subTimeTime,
            runtime.dtReal34 => &runtime.subTimeReal,
            else => null,
        },
        runtime.dtDate => switch (type_x) {
            runtime.dtLongInteger => &runtime.subDateLonI,
            runtime.dtDate => &runtime.subDateDate,
            runtime.dtReal34 => &runtime.subDateReal,
            else => null,
        },
        runtime.dtReal34Matrix => switch (type_x) {
            runtime.dtLongInteger => &runtime.subRemaLonI,
            runtime.dtShortInteger => &runtime.subRemaShoI,
            runtime.dtReal34 => &runtime.subRemaReal,
            runtime.dtComplex34 => &runtime.subRemaCplx,
            runtime.dtReal34Matrix => &runtime.subRemaRema,
            runtime.dtComplex34Matrix => &runtime.subRemaCxma,
            else => null,
        },
        runtime.dtComplex34Matrix => switch (type_x) {
            runtime.dtLongInteger => &runtime.subCxmaLonI,
            runtime.dtShortInteger => &runtime.subCxmaShoI,
            runtime.dtReal34 => &runtime.subCxmaReal,
            runtime.dtComplex34 => &runtime.subCxmaCplx,
            runtime.dtReal34Matrix => &runtime.subCxmaRema,
            runtime.dtComplex34Matrix => &runtime.subCxmaCxma,
            else => null,
        },
        else => null,
    };
}

fn selectRemainingMultiplyBranch(type_y: u32, type_x: u32) ?BranchFn {
    return switch (type_y) {
        runtime.dtLongInteger => switch (type_x) {
            runtime.dtTime => &runtime.mulLonITime,
            runtime.dtComplex34 => &runtime.mulLonICplx,
            runtime.dtReal34Matrix => &runtime.mulLonIRema,
            runtime.dtComplex34Matrix => &runtime.mulLonICxma,
            else => null,
        },
        runtime.dtShortInteger => switch (type_x) {
            runtime.dtTime => &runtime.mulShoITime,
            runtime.dtComplex34 => &runtime.mulShoICplx,
            runtime.dtReal34Matrix => &runtime.mulShoIRema,
            runtime.dtComplex34Matrix => &runtime.mulShoICxma,
            else => null,
        },
        runtime.dtReal34 => switch (type_x) {
            runtime.dtTime => &runtime.mulRealTime,
            runtime.dtComplex34 => &runtime.mulRealCplx,
            runtime.dtReal34Matrix => &runtime.mulRealRema,
            runtime.dtComplex34Matrix => &runtime.mulRealCxma,
            else => null,
        },
        runtime.dtComplex34 => switch (type_x) {
            runtime.dtLongInteger => &runtime.mulCplxLonI,
            runtime.dtShortInteger => &runtime.mulCplxShoI,
            runtime.dtReal34 => &runtime.mulCplxReal,
            runtime.dtComplex34 => &runtime.mulCplxCplx,
            runtime.dtReal34Matrix => &runtime.mulCplxRema,
            runtime.dtComplex34Matrix => &runtime.mulCplxCxma,
            else => null,
        },
        runtime.dtTime => switch (type_x) {
            runtime.dtLongInteger => &runtime.mulTimeLonI,
            runtime.dtShortInteger => &runtime.mulTimeShoI,
            runtime.dtReal34 => &runtime.mulTimeReal,
            else => null,
        },
        runtime.dtReal34Matrix => switch (type_x) {
            runtime.dtLongInteger => &runtime.mulRemaLonI,
            runtime.dtShortInteger => &runtime.mulRemaShoI,
            runtime.dtReal34 => &runtime.mulRemaReal,
            runtime.dtComplex34 => &runtime.mulRemaCplx,
            runtime.dtReal34Matrix => &runtime.mulRemaRema,
            runtime.dtComplex34Matrix => &runtime.mulRemaCxma,
            else => null,
        },
        runtime.dtComplex34Matrix => switch (type_x) {
            runtime.dtLongInteger => &runtime.mulCxmaLonI,
            runtime.dtShortInteger => &runtime.mulCxmaShoI,
            runtime.dtReal34 => &runtime.mulCxmaReal,
            runtime.dtComplex34 => &runtime.mulCxmaCplx,
            runtime.dtReal34Matrix => &runtime.mulCxmaRema,
            runtime.dtComplex34Matrix => &runtime.mulCxmaCxma,
            else => null,
        },
        else => null,
    };
}

fn selectRemainingDivideBranch(type_y: u32, type_x: u32) ?BranchFn {
    return switch (type_y) {
        runtime.dtLongInteger => switch (type_x) {
            runtime.dtTime => &runtime.divLonITime,
            runtime.dtComplex34 => &runtime.divLonICplx,
            runtime.dtReal34Matrix => &runtime.divLonIRema,
            runtime.dtComplex34Matrix => &runtime.divLonICxma,
            else => null,
        },
        runtime.dtShortInteger => switch (type_x) {
            runtime.dtTime => &runtime.divShoITime,
            runtime.dtComplex34 => &runtime.divShoICplx,
            runtime.dtReal34Matrix => &runtime.divShoIRema,
            runtime.dtComplex34Matrix => &runtime.divShoICxma,
            else => null,
        },
        runtime.dtReal34 => switch (type_x) {
            runtime.dtTime => &runtime.divRealTime,
            runtime.dtComplex34 => &runtime.divRealCplx,
            runtime.dtReal34Matrix => &runtime.divRealRema,
            runtime.dtComplex34Matrix => &runtime.divRealCxma,
            else => null,
        },
        runtime.dtComplex34 => switch (type_x) {
            runtime.dtLongInteger => &runtime.divCplxLonI,
            runtime.dtShortInteger => &runtime.divCplxShoI,
            runtime.dtReal34 => &runtime.divCplxReal,
            runtime.dtComplex34 => &runtime.divCplxCplx,
            runtime.dtReal34Matrix => &runtime.divCplxRema,
            runtime.dtComplex34Matrix => &runtime.divCplxCxma,
            else => null,
        },
        runtime.dtTime => switch (type_x) {
            runtime.dtLongInteger => &runtime.divTimeLonI,
            runtime.dtShortInteger => &runtime.divTimeShoI,
            runtime.dtReal34 => &runtime.divTimeReal,
            runtime.dtTime => &runtime.divTimeTime,
            else => null,
        },
        runtime.dtReal34Matrix => switch (type_x) {
            runtime.dtLongInteger => &runtime.divRemaLonI,
            runtime.dtShortInteger => &runtime.divRemaShoI,
            runtime.dtReal34 => &runtime.divRemaReal,
            runtime.dtComplex34 => &runtime.divRemaCplx,
            runtime.dtReal34Matrix => &runtime.divRemaRema,
            runtime.dtComplex34Matrix => &runtime.divRemaCxma,
            else => null,
        },
        runtime.dtComplex34Matrix => switch (type_x) {
            runtime.dtLongInteger => &runtime.divCxmaLonI,
            runtime.dtShortInteger => &runtime.divCxmaShoI,
            runtime.dtReal34 => &runtime.divCxmaReal,
            runtime.dtComplex34 => &runtime.divCxmaCplx,
            runtime.dtReal34Matrix => &runtime.divCxmaRema,
            runtime.dtComplex34Matrix => &runtime.divCxmaCxma,
            else => null,
        },
        else => null,
    };
}

fn tryRemainingArithmetic(select_branch: *const fn (u32, u32) ?BranchFn) bool {
    const branch = select_branch(runtime.getRegisterDataType(runtime.REGISTER_Y), runtime.getRegisterDataType(runtime.REGISTER_X)) orelse return false;

    if (!runtime.saveLastX()) {
        return true;
    }

    branch();
    runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, runtime.REGISTER_Y, no_register);
    return true;
}

fn tryRemainingDivide() bool {
    const branch = selectRemainingDivideBranch(runtime.getRegisterDataType(runtime.REGISTER_Y), runtime.getRegisterDataType(runtime.REGISTER_X)) orelse return false;

    runtime.copySourceRegisterToDestRegister(runtime.REGISTER_X, runtime.REGISTER_L);
    branch();
    runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, runtime.REGISTER_Y, no_register);
    return true;
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

        if (type_y == runtime.dtLongInteger) {
            runtime.convertLongIntegerRegisterToReal(runtime.REGISTER_Y, &y_value, &runtime.ctxtReal39);
        } else {
            runtime.convertShortIntegerRegisterToReal(runtime.REGISTER_Y, &y_value, &runtime.ctxtReal39);
        }
        runtime.real34ToReal(real34DataPointer(runtime.REGISTER_X), &x_value);
        if (x_angular_mode == runtime.amNone) {
            applyDyadicRealOperation(operation, &y_value, &x_value, &x_value);
            runtime.convertRealToReal34ResultRegister(&x_value, runtime.REGISTER_X);
        } else {
            runtime.convertAngleFromTo(&x_value, x_angular_mode, runtime.currentAngularMode, &runtime.ctxtReal39);
            applyDyadicRealOperation(operation, &y_value, &x_value, &x_value);
            runtime.convertRealToReal34ResultRegister(&x_value, runtime.REGISTER_X);
            runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.currentAngularMode);
        }
    } else {
        var y_value: runtime.real_t = undefined;
        var x_value: runtime.real_t = undefined;
        const y_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_Y);

        runtime.real34ToReal(real34DataPointer(runtime.REGISTER_Y), &y_value);
        if (type_x == runtime.dtLongInteger) {
            runtime.convertLongIntegerRegisterToReal(runtime.REGISTER_X, &x_value, &runtime.ctxtReal39);
        } else {
            runtime.convertShortIntegerRegisterToReal(runtime.REGISTER_X, &x_value, &runtime.ctxtReal39);
        }
        runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
        if (y_angular_mode == runtime.amNone) {
            applyDyadicRealOperation(operation, &y_value, &x_value, &x_value);
            runtime.convertRealToReal34ResultRegister(&x_value, runtime.REGISTER_X);
        } else {
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

    var y_value: runtime.real_t = undefined;
    if (type_y == runtime.dtLongInteger) {
        runtime.convertLongIntegerRegisterToReal(runtime.REGISTER_Y, &y_value, &runtime.ctxtReal39);
    } else {
        runtime.convertShortIntegerRegisterToReal(runtime.REGISTER_Y, &y_value, &runtime.ctxtReal39);
    }

    runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.amNone);
    if (runtime.real34IsZero(real34DataPointer(runtime.REGISTER_X))) {
        if (runtime.realIsZero(&y_value)) {
            if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
                runtime.convertRealToReal34ResultRegister(runtime.const_NaN, runtime.REGISTER_X);
            } else {
                runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
                runtime.moreInfoOnError(
                    if (type_y == runtime.dtLongInteger) "In function divLonIReal:" else "In function divShoIReal:",
                    "cannot divide 0 by 0",
                    null,
                    null,
                );
            }
        } else if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.realToReal34(
                if (runtime.realIsNegative(&y_value)) runtime.z47_math_wrappers_const_minus_infinity() else runtime.z47_math_wrappers_const_plus_infinity(),
                real34DataPointer(runtime.REGISTER_X),
            );
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            runtime.moreInfoOnError(
                if (type_y == runtime.dtLongInteger) "In function divLonIReal:" else "In function divShoIReal:",
                if (type_y == runtime.dtLongInteger) "cannot divide a long integer by 0" else "cannot divide a short integer by 0",
                null,
                null,
            );
        }
    } else {
        var x_value: runtime.real_t = undefined;

        runtime.real34ToReal(real34DataPointer(runtime.REGISTER_X), &x_value);
        runtime.realDivide(&y_value, &x_value, &x_value, &runtime.ctxtReal39);
        runtime.convertRealToReal34ResultRegister(&x_value, runtime.REGISTER_X);
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

    var x_value: runtime.real_t = undefined;
    if (type_x == runtime.dtLongInteger) {
        runtime.convertLongIntegerRegisterToReal(runtime.REGISTER_X, &x_value, &runtime.ctxtReal39);
    } else {
        runtime.convertShortIntegerRegisterToReal(runtime.REGISTER_X, &x_value, &runtime.ctxtReal39);
    }

    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
    if (runtime.realIsZero(&x_value)) {
        if (runtime.real34IsZero(real34DataPointer(runtime.REGISTER_Y))) {
            if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
                runtime.convertRealToReal34ResultRegister(runtime.const_NaN, runtime.REGISTER_X);
            } else {
                runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
                runtime.moreInfoOnError(
                    if (type_x == runtime.dtLongInteger) "In function divRealLonI:" else "In function divRealShoI:",
                    "cannot divide 0 by 0",
                    null,
                    null,
                );
            }
        } else if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.realToReal34(
                if (runtime.real34IsNegative(real34DataPointer(runtime.REGISTER_Y))) runtime.z47_math_wrappers_const_minus_infinity() else runtime.z47_math_wrappers_const_plus_infinity(),
                real34DataPointer(runtime.REGISTER_X),
            );
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            runtime.moreInfoOnError(
                if (type_x == runtime.dtLongInteger) "In function divRealLonI:" else "In function divRealShoI:",
                "cannot divide a real34 by 0",
                null,
                null,
            );
        }
    } else {
        var y_value: runtime.real_t = undefined;
        const y_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_Y);

        runtime.real34ToReal(real34DataPointer(runtime.REGISTER_Y), &y_value);
        if (y_angular_mode == runtime.amNone) {
            runtime.realDivide(&y_value, &x_value, &x_value, &runtime.ctxtReal39);
            runtime.convertRealToReal34ResultRegister(&x_value, runtime.REGISTER_X);
        } else {
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
    if (runtime.real34IsZero(real34DataPointer(runtime.REGISTER_Y)) and runtime.real34IsZero(real34DataPointer(runtime.REGISTER_X))) {
        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.convertRealToReal34ResultRegister(runtime.const_NaN, runtime.REGISTER_X);
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            runtime.moreInfoOnError("In function divRealReal:", "cannot divide 0 by 0", null, null);
        }
    } else if (runtime.real34IsZero(real34DataPointer(runtime.REGISTER_X))) {
        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.realToReal34(
                if (runtime.real34IsNegative(real34DataPointer(runtime.REGISTER_Y))) runtime.z47_math_wrappers_const_minus_infinity() else runtime.z47_math_wrappers_const_plus_infinity(),
                real34DataPointer(runtime.REGISTER_X),
            );
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            runtime.moreInfoOnError("In function divRealReal:", "cannot divide a real34 by 0", null, null);
        }
    } else {
        const y_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_Y);
        const x_angular_mode = runtime.getRegisterAngularMode(runtime.REGISTER_X);

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

fn tryDyadicLongIntegerArithmetic(operation: u8) bool {
    const type_x = runtime.getRegisterDataType(runtime.REGISTER_X);
    const type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);
    const x_is_long = type_x == runtime.dtLongInteger;
    const y_is_long = type_y == runtime.dtLongInteger;
    const x_is_short = type_x == runtime.dtShortInteger;
    const y_is_short = type_y == runtime.dtShortInteger;

    if (!(x_is_long or x_is_short) or !(y_is_long or y_is_short)) {
        return false;
    }

    if (!runtime.saveLastX()) {
        return true;
    }

    if (x_is_short and y_is_short) {
        const x_value = shortIntegerData(runtime.REGISTER_X);
        const y_value = shortIntegerData(runtime.REGISTER_Y);

        runtime.setRegisterTag(runtime.REGISTER_X, runtime.getRegisterTag(runtime.REGISTER_Y));
        x_value.* = switch (operation) {
            dyadic_integer_add => runtime.WP34S_intAdd(y_value.*, x_value.*),
            dyadic_integer_subtract => runtime.WP34S_intSubtract(y_value.*, x_value.*),
            dyadic_integer_multiply => runtime.WP34S_intMultiply(y_value.*, x_value.*),
            else => unreachable,
        };

        runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, runtime.REGISTER_Y, no_register);
        return true;
    }

    var x_value: runtime.longInteger_t = undefined;
    var y_value: runtime.longInteger_t = undefined;

    if (x_is_long) {
        runtime.convertLongIntegerRegisterToLongInteger(runtime.REGISTER_X, &x_value[0]);
    } else {
        runtime.convertShortIntegerRegisterToLongInteger(runtime.REGISTER_X, &x_value[0]);
    }

    if (y_is_long) {
        runtime.convertLongIntegerRegisterToLongInteger(runtime.REGISTER_Y, &y_value[0]);
    } else {
        runtime.convertShortIntegerRegisterToLongInteger(runtime.REGISTER_Y, &y_value[0]);
    }

    defer runtime.__gmpz_clear(&x_value[0]);
    defer runtime.__gmpz_clear(&y_value[0]);

    switch (operation) {
        dyadic_integer_add => runtime.__gmpz_add(&x_value[0], &y_value[0], &x_value[0]),
        dyadic_integer_subtract => runtime.__gmpz_sub(&x_value[0], &y_value[0], &x_value[0]),
        dyadic_integer_multiply => runtime.__gmpz_mul(&x_value[0], &y_value[0], &x_value[0]),
        else => unreachable,
    }

    runtime.convertLongIntegerToLongIntegerRegister(&x_value[0], runtime.REGISTER_X);
    runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, runtime.REGISTER_Y, no_register);
    return true;
}

fn tryDyadicLongIntegerDivide(with_remainder: bool) bool {
    const type_x = runtime.getRegisterDataType(runtime.REGISTER_X);
    const type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);
    const x_is_long = type_x == runtime.dtLongInteger;
    const y_is_long = type_y == runtime.dtLongInteger;
    const x_is_short = type_x == runtime.dtShortInteger;
    const y_is_short = type_y == runtime.dtShortInteger;

    if (!(x_is_long or x_is_short) or !(y_is_long or y_is_short)) {
        return false;
    }

    if (!runtime.saveLastX()) {
        return true;
    }

    if (x_is_short and y_is_short and !with_remainder) {
        var divisor_magnitude: u64 = 0;
        var divisor_sign: i16 = 0;
        runtime.convertShortIntegerRegisterToUInt64(runtime.REGISTER_X, &divisor_sign, &divisor_magnitude);

        if (divisor_magnitude == 0) {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            runtime.moreInfoOnError(
                if (with_remainder) "In function fnIDivR:" else "In function fnIDiv:",
                "cannot divide current integer pair by 0",
                null,
                null,
            );
        } else {
            const x_raw = shortIntegerData(runtime.REGISTER_X);
            const y_raw = shortIntegerData(runtime.REGISTER_Y);

            x_raw.* = runtime.WP34S_intDivide(y_raw.*, x_raw.*);
            runtime.setRegisterTag(runtime.REGISTER_X, runtime.getRegisterShortIntegerBase(runtime.REGISTER_Y));
        }

        runtime.adjustResult(runtime.REGISTER_X, true, false, runtime.REGISTER_X, runtime.REGISTER_Y, no_register);
        return true;
    }

    var x_value: runtime.longInteger_t = undefined;
    var y_value: runtime.longInteger_t = undefined;

    if (x_is_long) {
        runtime.convertLongIntegerRegisterToLongInteger(runtime.REGISTER_X, &x_value[0]);
    } else {
        runtime.convertShortIntegerRegisterToLongInteger(runtime.REGISTER_X, &x_value[0]);
    }

    if (y_is_long) {
        runtime.convertLongIntegerRegisterToLongInteger(runtime.REGISTER_Y, &y_value[0]);
    } else {
        runtime.convertShortIntegerRegisterToLongInteger(runtime.REGISTER_Y, &y_value[0]);
    }

    defer runtime.__gmpz_clear(&x_value[0]);
    defer runtime.__gmpz_clear(&y_value[0]);

    if (x_value[0]._mp_size == 0) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError(
            if (with_remainder) "In function fnIDivR:" else "In function fnIDiv:",
            "cannot divide current integer pair by 0",
            null,
            null,
        );
    } else if (with_remainder) {
        var quotient: runtime.longInteger_t = undefined;
        var remainder: runtime.longInteger_t = undefined;

        runtime.__gmpz_init(&quotient[0]);
        runtime.__gmpz_init(&remainder[0]);
        defer runtime.__gmpz_clear(&quotient[0]);
        defer runtime.__gmpz_clear(&remainder[0]);

        runtime.__gmpz_tdiv_qr(&quotient[0], &remainder[0], &y_value[0], &x_value[0]);
        if (x_is_short and y_is_short) {
            const base_y = runtime.getRegisterShortIntegerBase(runtime.REGISTER_Y);
            runtime.convertLongIntegerToShortIntegerRegister(&quotient[0], base_y, runtime.REGISTER_X);
            runtime.convertLongIntegerToShortIntegerRegister(&remainder[0], base_y, runtime.REGISTER_Y);
        } else {
            runtime.convertLongIntegerToLongIntegerRegister(&quotient[0], runtime.REGISTER_X);
            if (y_is_short) {
                runtime.convertLongIntegerToShortIntegerRegister(&remainder[0], runtime.getRegisterShortIntegerBase(runtime.REGISTER_Y), runtime.REGISTER_Y);
            } else {
                runtime.convertLongIntegerToLongIntegerRegister(&remainder[0], runtime.REGISTER_Y);
            }
        }
    } else {
        var remainder: runtime.longInteger_t = undefined;

        runtime.__gmpz_init(&remainder[0]);
        defer runtime.__gmpz_clear(&remainder[0]);

        runtime.__gmpz_tdiv_qr(&x_value[0], &remainder[0], &y_value[0], &x_value[0]);
        runtime.convertLongIntegerToLongIntegerRegister(&x_value[0], runtime.REGISTER_X);
    }

    if (with_remainder) {
        runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, runtime.REGISTER_Y, no_register);
        runtime.adjustResult(runtime.REGISTER_Y, false, false, runtime.REGISTER_X, runtime.REGISTER_Y, no_register);
    } else {
        runtime.adjustResult(runtime.REGISTER_X, true, false, runtime.REGISTER_X, runtime.REGISTER_Y, no_register);
    }

    return true;
}

pub fn fnAdd(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (tryDyadicLongIntegerArithmetic(dyadic_integer_add)) {
        return;
    }

    if (tryScalarIntRealArithmetic(dyadic_integer_add) or tryScalarRealArithmetic(dyadic_integer_add)) {
        return;
    }

    if (tryRemainingArithmetic(&selectRemainingAddBranch)) {
        return;
    }

    runtime.retained.z47_math_wrappers_retained_fnAdd(unused_but_mandatory_parameter);
}

pub fn fnSubtract(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (tryDyadicLongIntegerArithmetic(dyadic_integer_subtract)) {
        return;
    }

    if (tryScalarIntRealArithmetic(dyadic_integer_subtract) or tryScalarRealArithmetic(dyadic_integer_subtract)) {
        return;
    }

    if (tryRemainingArithmetic(&selectRemainingSubtractBranch)) {
        return;
    }

    runtime.retained.z47_math_wrappers_retained_fnSubtract(unused_but_mandatory_parameter);
}

pub fn fnMultiply(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (tryDyadicLongIntegerArithmetic(dyadic_integer_multiply)) {
        return;
    }

    if (tryScalarIntRealArithmetic(dyadic_integer_multiply) or tryScalarRealArithmetic(dyadic_integer_multiply)) {
        return;
    }

    if (tryRemainingArithmetic(&selectRemainingMultiplyBranch)) {
        return;
    }

    runtime.retained.z47_math_wrappers_retained_fnMultiply(unused_but_mandatory_parameter);
}

pub fn fnDivide(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (tryScalarIntegerOverRealDivide()) {
        return;
    }

    if (tryScalarRealOverIntegerDivide()) {
        return;
    }

    if (tryScalarRealOverRealDivide()) {
        return;
    }

    if (tryRemainingDivide()) {
        return;
    }

    runtime.retained.z47_math_wrappers_retained_fnDivide(unused_but_mandatory_parameter);
}

pub fn fnIDiv(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (tryDyadicLongIntegerDivide(false)) {
        return;
    }

    runtime.retained.z47_math_wrappers_retained_fnIDiv(unused_but_mandatory_parameter);
}

pub fn fnIDivR(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (tryDyadicLongIntegerDivide(true)) {
        return;
    }

    runtime.retained.z47_math_wrappers_retained_fnIDivR(unused_but_mandatory_parameter);
}
