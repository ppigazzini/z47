const runtime = @import("../command_wrappers_runtime.zig");
const shortint_owned = @import("transform_shortint.zig");

fn sqrtShoI() callconv(.c) void {
    var sign_value: i32 = 0;

    _ = runtime.WP34S_extract_value(shortint_owned.shortIntegerData(runtime.REGISTER_X).*, &sign_value);
    if (sign_value != 0 and runtime.getFlag(@intCast(runtime.FLAG_CPXRES))) {
        var value: runtime.real_t = undefined;

        runtime.convertShortIntegerRegisterToReal(runtime.REGISTER_X, &value, &runtime.ctxtReal39);
        runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtComplex34, 0, runtime.amNone);
        runtime.realSetPositiveSign(&value);
        runtime.realSquareRoot(&value, &value, &runtime.ctxtReal39);
        runtime.convertComplexToResultRegister(runtime.z47_math_wrappers_const_0(), &value, runtime.REGISTER_X);
        return;
    }

    shortint_owned.shortIntegerData(runtime.REGISTER_X).* = runtime.WP34S_intSqrt(shortint_owned.shortIntegerData(runtime.REGISTER_X).*);
}

fn sqrtReal() callconv(.c) void {
    var value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &value)) {
        return;
    }

    if (runtime.realIsInfinite(&value) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function sqrtReal:", "cannot use infinity as X input of sqrt when flag D is not set", null, null);
        return;
    }

    if (!runtime.realIsNegative(&value)) {
        runtime.realSquareRoot(&value, &value, &runtime.ctxtReal39);
        runtime.convertRealToResultRegister(&value, runtime.REGISTER_X, runtime.amNone);
        return;
    }

    if (runtime.getFlag(@intCast(runtime.FLAG_CPXRES))) {
        runtime.realSetPositiveSign(&value);
        runtime.realSquareRoot(&value, &value, &runtime.ctxtReal39);
        runtime.convertComplexToResultRegister(runtime.z47_math_wrappers_const_0(), &value, runtime.REGISTER_X);
        return;
    }

    runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
    runtime.moreInfoOnError("In function sqrtReal:", "sqrt does not accept a negative real when flag I is not set", null, null);
}

fn sqrtLonI() callconv(.c) void {
    var value: runtime.longInteger_t = undefined;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &value[0], null)) {
        return;
    }
    defer runtime.__gmpz_clear(&value[0]);

    if (value[0]._mp_size >= 0) {
        var rem: runtime.longInteger_t = undefined;
        var root: runtime.longInteger_t = undefined;

        runtime.__gmpz_init(&rem[0]);
        defer runtime.__gmpz_clear(&rem[0]);
        runtime.__gmpz_init(&root[0]);
        defer runtime.__gmpz_clear(&root[0]);

        runtime.__gmpz_rootrem(&root[0], &rem[0], &value[0], 2);
        if (rem[0]._mp_size == 0) {
            runtime.convertLongIntegerToLongIntegerRegister(&root[0], runtime.REGISTER_X);
            return;
        }
    }

    sqrtReal();
}

fn sqrtCplx() callconv(.c) void {
    var real_value: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &real_value, &imag_value)) {
        return;
    }

    if (runtime.realIsZero(&imag_value) and runtime.realIsNegative(&real_value)) {
        runtime.realChangeSign(&real_value);
        runtime.realSquareRoot(&real_value, &imag_value, &runtime.ctxtReal39);
        runtime.realSetZero(&real_value);
    } else if (runtime.realIsZero(&imag_value)) {
        runtime.realSquareRoot(&real_value, &real_value, &runtime.ctxtReal39);
        runtime.realSetZero(&imag_value);
    } else {
        runtime.realRectangularToPolar(&real_value, &imag_value, &real_value, &imag_value, &runtime.ctxtReal39);
        runtime.realSquareRoot(&real_value, &real_value, &runtime.ctxtReal39);
        runtime.realMultiply(&imag_value, runtime.z47_math_wrappers_const_1on2(), &imag_value, &runtime.ctxtReal39);
        runtime.realPolarToRectangular(&real_value, &imag_value, &real_value, &imag_value, &runtime.ctxtReal39);
    }

    runtime.convertComplexToResultRegister(&real_value, &imag_value, runtime.REGISTER_X);
}

fn curtShoI() callconv(.c) void {
    var value: runtime.real_t = undefined;
    var cube_root: i32 = 0;

    runtime.convertShortIntegerRegisterToReal(runtime.REGISTER_X, &value, &runtime.ctxtReal39);

    if (runtime.realIsNegative(&value)) {
        runtime.realSetPositiveSign(&value);
        runtime.PowerReal(&value, runtime.z47_math_wrappers_const_1on3(), &value, &runtime.ctxtReal39);
        runtime.realChangeSign(&value);
    } else {
        runtime.PowerReal(&value, runtime.z47_math_wrappers_const_1on3(), &value, &runtime.ctxtReal39);
    }

    cube_root = runtime.realToInt32C47(&value, null);
    if (cube_root >= 0) {
        shortint_owned.shortIntegerData(runtime.REGISTER_X).* = runtime.WP34S_build_value(@intCast(cube_root), 0);
    } else {
        shortint_owned.shortIntegerData(runtime.REGISTER_X).* = runtime.WP34S_build_value(@intCast(-cube_root), 1);
    }
}

fn curtReal() callconv(.c) void {
    var value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &value)) {
        return;
    }

    if (runtime.realIsInfinite(&value) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function curtReal:", "cannot use infinity as X input of curt when flag D is not set", null, null);
        return;
    }

    if (runtime.realIsNegative(&value)) {
        runtime.realSetPositiveSign(&value);
        runtime.PowerReal(&value, runtime.z47_math_wrappers_const_1on3(), &value, &runtime.ctxtReal39);
        runtime.realChangeSign(&value);
    } else {
        runtime.PowerReal(&value, runtime.z47_math_wrappers_const_1on3(), &value, &runtime.ctxtReal39);
    }

    runtime.convertRealToResultRegister(&value, runtime.REGISTER_X, runtime.amNone);
}

fn curtLonI() callconv(.c) void {
    var value: runtime.longInteger_t = undefined;
    var rem: runtime.longInteger_t = undefined;
    var root: runtime.longInteger_t = undefined;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &value[0], null)) {
        return;
    }
    defer runtime.__gmpz_clear(&value[0]);

    runtime.__gmpz_init(&rem[0]);
    defer runtime.__gmpz_clear(&rem[0]);
    runtime.__gmpz_init(&root[0]);
    defer runtime.__gmpz_clear(&root[0]);

    runtime.__gmpz_rootrem(&root[0], &rem[0], &value[0], 3);
    if (rem[0]._mp_size == 0) {
        runtime.convertLongIntegerToLongIntegerRegister(&root[0], runtime.REGISTER_X);
        return;
    }

    curtReal();
}

fn curtCplx() callconv(.c) void {
    var real_value: runtime.real_t = undefined;
    var imag_value: runtime.real_t = undefined;
    var magnitude: runtime.real_t = undefined;
    var angle: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &real_value, &imag_value)) {
        return;
    }

    magnitude = real_value;
    angle = imag_value;

    if (runtime.realIsZero(&angle)) {
        if (runtime.realIsNegative(&magnitude)) {
            runtime.realSetPositiveSign(&magnitude);
            runtime.PowerReal(&magnitude, runtime.z47_math_wrappers_const_1on3(), &real_value, &runtime.ctxtReal39);
            runtime.realChangeSign(&real_value);
        } else {
            runtime.PowerReal(&magnitude, runtime.z47_math_wrappers_const_1on3(), &real_value, &runtime.ctxtReal39);
        }
        runtime.realSetZero(&imag_value);
    } else {
        runtime.realRectangularToPolar(&magnitude, &angle, &magnitude, &angle, &runtime.ctxtReal39);
        runtime.PowerReal(&magnitude, runtime.z47_math_wrappers_const_1on3(), &magnitude, &runtime.ctxtReal39);
        runtime.realMultiply(&angle, runtime.z47_math_wrappers_const_1on3(), &angle, &runtime.ctxtReal39);
        runtime.realPolarToRectangular(&magnitude, &angle, &real_value, &imag_value, &runtime.ctxtReal39);
    }

    runtime.convertComplexToResultRegister(&real_value, &imag_value, runtime.REGISTER_X);
}

pub fn squareRoot(unused_but_mandatory_parameter: u16) void {
    const register_type = runtime.getRegisterDataType(runtime.REGISTER_X);

    _ = unused_but_mandatory_parameter;

    if (register_type == runtime.dtReal34Matrix or register_type == runtime.dtComplex34Matrix) {
        runtime.fnMatrixSquareRoot(runtime.NOPARAM);
        return;
    }

    runtime.processIntRealComplexMonadicFunction(&sqrtReal, &sqrtCplx, &sqrtShoI, &sqrtLonI);
}

pub fn cubeRoot(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexMonadicFunction(&curtReal, &curtCplx, &curtShoI, &curtLonI);
}
