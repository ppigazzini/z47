const runtime = @import("math_command_wrappers_runtime.zig");
const legacy = runtime.legacy;

const Operation = enum {
    inc,
    dec,
};

fn isOwnedStackRegister(regist: u16) bool {
    return switch (regist) {
        runtime.REGISTER_X,
        runtime.REGISTER_Y,
        runtime.REGISTER_Z,
        runtime.REGISTER_T,
        => true,
        else => false,
    };
}

fn real34DataPointer(regist: runtime.calcRegister_t) *runtime.real34_t {
    return @as(*runtime.real34_t, @ptrCast(@alignCast(runtime.getRegisterDataPointer(regist).?)));
}

fn incDecError(regist: runtime.calcRegister_t) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, regist);
    runtime.moreInfoOnError("In function incDecError:", "Cannot increment/decrement, incompatible type.", null, null);
}

fn incDecLonI(regist: runtime.calcRegister_t, operation: Operation) void {
    var value: runtime.longInteger_t = undefined;

    runtime.convertLongIntegerRegisterToLongInteger(regist, &value[0]);
    defer runtime.__gmpz_clear(&value[0]);

    if (operation == .inc) {
        runtime.__gmpz_add_ui(&value[0], &value[0], 1);
    } else {
        runtime.__gmpz_sub_ui(&value[0], &value[0], 1);
    }

    runtime.convertLongIntegerToLongIntegerRegister(&value[0], regist);
}

fn incDecReal(regist: runtime.calcRegister_t, operation: Operation) void {
    var value: runtime.real_t = undefined;

    runtime.real34ToReal(real34DataPointer(regist), &value);
    if (operation == .inc) {
        runtime.realAdd(&value, runtime.z47_math_wrappers_const_1(), &value, &runtime.ctxtReal39);
    } else {
        runtime.realSubtract(&value, runtime.z47_math_wrappers_const_1(), &value, &runtime.ctxtReal39);
    }
    runtime.realToReal34(&value, real34DataPointer(regist));
}

fn incDecCplx(regist: runtime.calcRegister_t, operation: Operation) void {
    var value: runtime.real_t = undefined;

    runtime.real34ToReal(real34DataPointer(regist), &value);
    if (operation == .inc) {
        runtime.realAdd(&value, runtime.z47_math_wrappers_const_1(), &value, &runtime.ctxtReal39);
    } else {
        runtime.realSubtract(&value, runtime.z47_math_wrappers_const_1(), &value, &runtime.ctxtReal39);
    }
    runtime.realToReal34(&value, real34DataPointer(regist));
}

fn incDecTime(regist: runtime.calcRegister_t, operation: Operation) void {
    var value: runtime.real_t = undefined;

    // "count hours", value in seconds; step by 1 h = 3600 s to match DSZ/ISZ.
    runtime.real34ToReal(real34DataPointer(regist), &value);
    if (operation == .inc) {
        runtime.realAdd(&value, runtime.z47_math_wrappers_const_3600(), &value, &runtime.ctxtReal39);
    } else {
        runtime.realSubtract(&value, runtime.z47_math_wrappers_const_3600(), &value, &runtime.ctxtReal39);
    }
    runtime.realToReal34(&value, real34DataPointer(regist));
}

fn incDecShoI(regist: runtime.calcRegister_t, operation: Operation) void {
    var sign: i16 = 0;
    var value: u64 = 0;

    runtime.convertShortIntegerRegisterToUInt64(regist, &sign, &value);
    if (sign != 0) {
        if (operation == .dec) {
            value += 1;
        } else {
            value -= 1;
        }
    } else {
        if (operation == .inc) {
            value += 1;
        } else {
            value -= 1;
        }
    }
    runtime.convertUInt64ToShortIntegerRegister(sign, value, runtime.getRegisterTag(regist), regist);
}

fn incDecRegister(regist: runtime.calcRegister_t, operation: Operation) void {
    switch (runtime.getRegisterDataType(regist)) {
        runtime.dtLongInteger => incDecLonI(regist, operation),
        runtime.dtReal34 => incDecReal(regist, operation),
        runtime.dtComplex34 => incDecCplx(regist, operation),
        runtime.dtTime => incDecTime(regist, operation),
        runtime.dtShortInteger => incDecShoI(regist, operation),
        else => incDecError(regist),
    }
}

pub fn dec(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (!isOwnedStackRegister(unused_but_mandatory_parameter)) {
        legacy.fnDec(unused_but_mandatory_parameter);
        return;
    }

    incDecRegister(@intCast(unused_but_mandatory_parameter), .dec);
}

pub fn inc(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (!isOwnedStackRegister(unused_but_mandatory_parameter)) {
        legacy.fnInc(unused_but_mandatory_parameter);
        return;
    }

    incDecRegister(@intCast(unused_but_mandatory_parameter), .inc);
}
