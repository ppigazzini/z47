const runtime = @import("../command_wrappers/runtime.zig");

const std_plus_minus = "\x80\xb1"; // STD_PLUS_MINUS
const std_infinity = "\xa2\x1e"; // STD_INFINITY
const std_square_root = "\xa2\x1a"; // STD_SQUARE_ROOT
const std_x_under_root = "\x83\x7f"; // STD_x_UNDER_ROOT

fn sqrtShoI() callconv(.c) void {
    var sign_value: i32 = 0;

    _ = runtime.WP34S_extract_value(runtime.registerShortIntegerPtr(runtime.REGISTER_X).*, &sign_value);
    if (sign_value != 0 and runtime.getFlag(@intCast(runtime.FLAG_CPXRES))) {
        var value: runtime.real_t = undefined;

        runtime.convertShortIntegerRegisterToReal(runtime.REGISTER_X, &value, &runtime.ctxtReal39);
        runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtComplex34, 0, runtime.amNone);
        runtime.realSetPositiveSign(&value);
        runtime.realSquareRoot(&value, &value, &runtime.ctxtReal39);
        runtime.convertComplexToResultRegister(runtime.z47_math_wrappers_const_0(), &value, runtime.REGISTER_X);
        return;
    }

    runtime.registerShortIntegerPtr(runtime.REGISTER_X).* = runtime.WP34S_intSqrt(runtime.registerShortIntegerPtr(runtime.REGISTER_X).*);
}

fn sqrtReal() callconv(.c) void {
    var value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &value)) {
        return;
    }

    if (runtime.realIsInfinite(&value) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function sqrtReal:", "cannot use " ++ std_plus_minus ++ std_infinity ++ " as X input of sqrt when flag SPCRES is not set", null, null);
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
    runtime.moreInfoOnError("In function sqrtReal:", std_square_root ++ std_x_under_root ++ " doesn't work on a negative real when flag I is not set!", null, null);
}

fn sqrtLonI() callconv(.c) void {
    var value: runtime.longInteger_t = undefined;

    // The reader initialises its value on every path, refusals included, so the
    // clear must cover the failure branch too.
    defer runtime.__gmpz_clear(&value[0]);
    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &value[0], null)) {
        return;
    }

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
    var operand: runtime.real_t = undefined;
    var nearest: runtime.real_t = undefined;
    var cube: runtime.real_t = undefined;
    var cube_root: i32 = 0;

    runtime.convertShortIntegerRegisterToReal(runtime.REGISTER_X, &value, &runtime.ctxtReal39);
    operand = value;

    if (runtime.realIsNegative(&value)) {
        runtime.realSetPositiveSign(&value);
        runtime.PowerReal(&value, runtime.z47_math_wrappers_const_1on3(), &value, &runtime.ctxtReal39);
        runtime.realChangeSign(&value);
    } else {
        runtime.PowerReal(&value, runtime.z47_math_wrappers_const_1on3(), &value, &runtime.ctxtReal39);
    }

    runtime.realToIntegralValue(&value, &nearest, runtime.DEC_ROUND_HALF_UP, &runtime.ctxtReal39); // PowerReal() lands a hair under an exact cube
    runtime.realMultiply(&nearest, &nearest, &cube, &runtime.ctxtReal39);
    runtime.realMultiply(&cube, &nearest, &cube, &runtime.ctxtReal39);
    if (runtime.realCompareEqual(&cube, &operand)) { // the operand is a cube, so its root is exact
        value = nearest;
    }

    cube_root = runtime.realToInt32C47(&value, null);
    if (cube_root >= 0) {
        runtime.registerShortIntegerPtr(runtime.REGISTER_X).* = runtime.WP34S_build_value(@intCast(cube_root), 0);
    } else {
        // Widen before negating, as the C cast does: -INT32_MIN has no i32.
        runtime.registerShortIntegerPtr(runtime.REGISTER_X).* = runtime.WP34S_build_value(@intCast(-@as(i64, cube_root)), 1);
    }
}

fn curtReal() callconv(.c) void {
    var value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &value)) {
        return;
    }

    if (runtime.realIsInfinite(&value) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError("In function curtReal:", "cannot use " ++ std_plus_minus ++ std_infinity ++ " as X input of curt when flag SPCRES is not set", null, null);
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

    // The reader initialises its value on every path, refusals included, so the
    // clear must cover the failure branch too.
    defer runtime.__gmpz_clear(&value[0]);
    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &value[0], null)) {
        return;
    }

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
        // squareRoot.c takes the matrix branch to fnMatrixSquareRoot only under
        // OPTION_EIGEN; its #else arm refuses the operand instead. The option is
        // #undef'd on DM42 packages 1, 2 and 4, where fnMatrixSquareRoot is
        // itself an empty stub.
        if (runtime.option_eigen) {
            runtime.fnMatrixSquareRoot(runtime.NOPARAM);
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        }
        return;
    }

    runtime.processIntRealComplexMonadicFunction(&sqrtReal, &sqrtCplx, &sqrtShoI, &sqrtLonI);
}

pub fn cubeRoot(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexMonadicFunction(&curtReal, &curtCplx, &curtShoI, &curtLonI);
}
