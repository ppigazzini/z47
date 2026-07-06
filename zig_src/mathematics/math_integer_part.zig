const runtime = @import("math_command_wrappers_runtime.zig");

const no_register = @as(runtime.calcRegister_t, -1);

fn doIP(x: *runtime.real_t, mode: runtime.rounding_t) void {
    if (runtime.realIsSpecial(x)) {
        if (!runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        }
    } else {
        runtime.realToIntegralValue(x, x, mode, &runtime.ctxtReal39);
    }
}

pub fn integerPartNoOp() void {}

pub fn integerPartReal(mode: runtime.rounding_t) void {
    var x: runtime.real_t = undefined;

    if (runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        doIP(&x, mode);
        runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
    }
}

pub fn integerPartCplx(mode: runtime.rounding_t) void {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;

    if (runtime.getRegisterAsComplex(runtime.REGISTER_X, &a, &b)) {
        doIP(&a, mode);
        doIP(&b, mode);
        runtime.convertComplexToResultRegister(&a, &b, runtime.REGISTER_X);
    }
}

fn integerPartNoOpForward() callconv(.c) void {
    integerPartNoOp();
}

fn ceilReal() callconv(.c) void {
    integerPartReal(runtime.DEC_ROUND_CEILING);
}

fn ceilCplx() callconv(.c) void {
    integerPartCplx(runtime.DEC_ROUND_CEILING);
}

fn floorReal() callconv(.c) void {
    integerPartReal(runtime.DEC_ROUND_FLOOR);
}

fn floorCplx() callconv(.c) void {
    integerPartCplx(runtime.DEC_ROUND_FLOOR);
}

fn ipReal() callconv(.c) void {
    integerPartReal(runtime.DEC_ROUND_DOWN);
}

fn ipCplx() callconv(.c) void {
    integerPartCplx(runtime.DEC_ROUND_DOWN);
}

fn fpRealForward() callconv(.c) void {
    var integral: runtime.real34_t = undefined;

    runtime.real34ToIntegralValue(runtime.registerReal34Ptr(runtime.REGISTER_X), &integral, runtime.DEC_ROUND_DOWN);
    runtime.real34Subtract(runtime.registerReal34Ptr(runtime.REGISTER_X), &integral, runtime.registerReal34Ptr(runtime.REGISTER_X));
}

fn fpShoIForward() callconv(.c) void {
    var result: u64 = 0;

    if (runtime.shortIntegerMode == runtime.SIM_1COMPL or runtime.shortIntegerMode == runtime.SIM_SIGNMT) {
        const value = runtime.registerShortIntegerPtr(runtime.REGISTER_X).*;
        if ((value & runtime.shortIntegerSignBit) != 0) {
            result = if (runtime.shortIntegerMode == runtime.SIM_1COMPL) runtime.shortIntegerMask else runtime.shortIntegerSignBit;
        }
    }

    runtime.registerShortIntegerPtr(runtime.REGISTER_X).* = result;
}

fn fpLonIForward() callconv(.c) void {
    runtime.z47_math_wrappers_build_sign_result(0);
}

pub fn min(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    if (!runtime.saveLastX()) {
        return;
    }

    runtime.registerMin(runtime.REGISTER_X, runtime.REGISTER_Y, runtime.REGISTER_X);
    runtime.adjustResult(runtime.REGISTER_X, true, false, runtime.REGISTER_X, no_register, no_register);
}

pub fn max(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    if (!runtime.saveLastX()) {
        return;
    }

    runtime.registerMax(runtime.REGISTER_X, runtime.REGISTER_Y, runtime.REGISTER_X);
    runtime.adjustResult(runtime.REGISTER_X, true, false, runtime.REGISTER_X, no_register, no_register);
}

pub fn ceil(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexMonadicFunction(
        &ceilReal,
        &ceilCplx,
        &integerPartNoOpForward,
        &integerPartNoOpForward,
    );
}

pub fn floor(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexMonadicFunction(
        &floorReal,
        &floorCplx,
        &integerPartNoOpForward,
        &integerPartNoOpForward,
    );
}

pub fn ip(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexMonadicFunction(
        &ipReal,
        &ipCplx,
        &integerPartNoOpForward,
        &integerPartNoOpForward,
    );
}

pub fn lint(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    var value: runtime.longInteger_t = undefined;
    const data_type = runtime.getRegisterDataType(runtime.REGISTER_X);

    if (!runtime.saveLastX()) {
        return;
    }

    if (runtime.getRegisterAsLongInt(runtime.REGISTER_X, &value[0], null)) {
        defer runtime.__gmpz_clear(&value[0]);

        runtime.convertLongIntegerToLongIntegerRegister(&value[0], runtime.REGISTER_X);
        if (data_type == runtime.dtShortInteger) {
            runtime.setLastintegerBasetoZero();
        }
    }
}

pub fn sint(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    var sign = false;
    var value: u64 = 0;
    var overflow = false;
    var fractional = false;

    if (!runtime.saveLastX()) {
        return;
    }

    if (!runtime.getRegisterAsShortInt(runtime.REGISTER_X, &sign, &value, &overflow, &fractional)) {
        return;
    }

    if (runtime.getRegisterDataType(runtime.REGISTER_X) != runtime.dtShortInteger) {
        runtime.convertUInt64ToShortIntegerRegister(@intFromBool(sign), value, 10, runtime.REGISTER_X);
    }
    runtime.forceSystemFlag(@intCast(runtime.FLAG_CARRY), @intFromBool(fractional));
    runtime.forceSystemFlag(@intCast(runtime.FLAG_OVERFLOW), @intFromBool(overflow));
}

pub fn fp(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexMonadicFunction(
        &fpRealForward,
        null,
        &fpShoIForward,
        &fpLonIForward,
    );
}
