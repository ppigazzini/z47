const runtime = @import("math_command_wrappers_runtime.zig");

const inc_flag: u8 = 0;
const dec_flag: u8 = 1;
const decrement_retained = runtime.retained.z47_math_wrappers_retained_fnDec;
const increment_retained = runtime.retained.z47_math_wrappers_retained_fnInc;

fn real34DataPointer(regist: runtime.calcRegister_t) *runtime.real34_t {
    return @as(*runtime.real34_t, @ptrCast(@alignCast(runtime.getRegisterDataPointer(regist).?)));
}

fn incDecError(regist: runtime.calcRegister_t) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, regist);
    runtime.moreInfoOnError("In function incDecError:", "Cannot increment/decrement, incompatible type.", null, null);
}

fn incDecLonI(regist: runtime.calcRegister_t, flag: u8) void {
    var value: runtime.longInteger_t = undefined;

    runtime.convertLongIntegerRegisterToLongInteger(regist, &value[0]);
    defer runtime.__gmpz_clear(&value[0]);

    if (flag == inc_flag) {
        runtime.__gmpz_add_ui(&value[0], &value[0], 1);
    } else {
        runtime.__gmpz_sub_ui(&value[0], &value[0], 1);
    }

    runtime.convertLongIntegerToLongIntegerRegister(&value[0], regist);
}

fn incDecReal(regist: runtime.calcRegister_t, flag: u8) void {
    var value: runtime.real_t = undefined;

    runtime.real34ToReal(real34DataPointer(regist), &value);
    if (flag == inc_flag) {
        runtime.realAdd(&value, runtime.z47_math_wrappers_const_1(), &value, &runtime.ctxtReal39);
    } else {
        runtime.realSubtract(&value, runtime.z47_math_wrappers_const_1(), &value, &runtime.ctxtReal39);
    }
    runtime.realToReal34(&value, real34DataPointer(regist));
}

fn incDecCplx(regist: runtime.calcRegister_t, flag: u8) void {
    var value: runtime.real_t = undefined;

    runtime.real34ToReal(real34DataPointer(regist), &value);
    if (flag == inc_flag) {
        runtime.realAdd(&value, runtime.z47_math_wrappers_const_1(), &value, &runtime.ctxtReal39);
    } else {
        runtime.realSubtract(&value, runtime.z47_math_wrappers_const_1(), &value, &runtime.ctxtReal39);
    }
    runtime.realToReal34(&value, real34DataPointer(regist));
}

fn incDecShoI(regist: runtime.calcRegister_t, flag: u8) void {
    var sign: i16 = 0;
    var value: u64 = 0;

    runtime.convertShortIntegerRegisterToUInt64(regist, &sign, &value);
    if (sign != 0) {
        if (flag != inc_flag) {
            value += 1;
        } else {
            value -= 1;
        }
    } else {
        if (flag == inc_flag) {
            value += 1;
        } else {
            value -= 1;
        }
    }
    runtime.convertUInt64ToShortIntegerRegister(sign, value, runtime.getRegisterTag(regist), regist);
}

fn incDecRegister(regist: runtime.calcRegister_t, flag: u8) void {
    switch (runtime.getRegisterDataType(regist)) {
        runtime.dtLongInteger => incDecLonI(regist, flag),
        runtime.dtReal34 => incDecReal(regist, flag),
        runtime.dtComplex34 => incDecCplx(regist, flag),
        runtime.dtShortInteger => incDecShoI(regist, flag),
        else => incDecError(regist),
    }
}

pub fn dec(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (unused_but_mandatory_parameter != runtime.REGISTER_X and unused_but_mandatory_parameter != runtime.REGISTER_Y and unused_but_mandatory_parameter != runtime.REGISTER_Z and unused_but_mandatory_parameter != runtime.REGISTER_T) {
        decrement_retained(unused_but_mandatory_parameter);
        return;
    }

    incDecRegister(@intCast(unused_but_mandatory_parameter), dec_flag);
}

pub fn inc(unused_but_mandatory_parameter: u16) callconv(.c) void {
    if (unused_but_mandatory_parameter != runtime.REGISTER_X and unused_but_mandatory_parameter != runtime.REGISTER_Y and unused_but_mandatory_parameter != runtime.REGISTER_Z and unused_but_mandatory_parameter != runtime.REGISTER_T) {
        increment_retained(unused_but_mandatory_parameter);
        return;
    }

    incDecRegister(@intCast(unused_but_mandatory_parameter), inc_flag);
}
