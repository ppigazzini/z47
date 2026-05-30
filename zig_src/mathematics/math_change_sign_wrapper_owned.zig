const runtime = @import("math_command_wrappers_runtime.zig");

fn chsZeroCheck(value: *runtime.real_t) void {
    runtime.realChangeSign(value);
    if (runtime.realIsZero(value) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.realSetPositiveSign(value);
    }
}

pub fn chsReal() callconv(.c) void {
    var x: runtime.real_t = undefined;
    var mode = runtime.amNone;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtReal34) {
        mode = runtime.getRegisterAngularMode(runtime.REGISTER_X);
    }

    chsZeroCheck(&x);
    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, mode);
}

pub fn chsCplx() callconv(.c) void {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &a, &b)) {
        return;
    }

    chsZeroCheck(&a);
    chsZeroCheck(&b);
    runtime.convertComplexToResultRegister(&a, &b, runtime.REGISTER_X);
}

pub fn chsShoI() callconv(.c) void {
    runtime.registerShortIntegerPtr(runtime.REGISTER_X).* = runtime.WP34S_intChs(runtime.registerShortIntegerPtr(runtime.REGISTER_X).*
    );
}

pub fn chsLonI() callconv(.c) void {
    var x: runtime.longInteger_t = undefined;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &x[0], null)) {
        return;
    }
    defer runtime.__gmpz_clear(&x[0]);

    x[0]._mp_size = -x[0]._mp_size;
    runtime.convertLongIntegerToLongIntegerRegister(&x[0], runtime.REGISTER_X);
}
