const abi = @import("abi");
const runtime = @import("../command_wrappers/runtime.zig");

const RM_UP: u8 = 3;
const RM_DOWN: u8 = 4;
const RM_CEIL: u8 = 5;
const RM_FLOOR: u8 = 6;

inline fn realSetNegativeSign(operand: *runtime.real_t) void {
    operand.bits |= 0x80;
}

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

/// The exact square root of x rounded once by RM to 34 digits. r is the square
/// root decNumber rounds correctly at 39 digits, so the rounding by RM of r to
/// 34 digits is the answer or one of its two 34-digit neighbours. Exact squares
/// at 75 digits decide which: a 34-digit square has 68 digits, a midpoint's
/// square 70. A midpoint's square ends in 25 and has more than 34 digits, so it
/// is never x and no tie is reached. x is a positive real of 34 digits, or a
/// long integer of at most 75 digits that is not a square; r enters as the root
/// at 39 digits and leaves as the root at 34 digits.
fn sqrtRoundedOnce(x: *const runtime.real_t, r: *runtime.real_t) void {
    var c34: runtime.real34_t = undefined;
    var lo34: runtime.real34_t = undefined;
    var hi34: runtime.real34_t = undefined;
    var c: runtime.real_t = undefined;
    var lo: runtime.real_t = undefined;
    var hi: runtime.real_t = undefined;
    var sq: runtime.real_t = undefined;

    runtime.realToReal34(r, &c34); // by RM
    runtime.real34NextMinus(&c34, &lo34);
    runtime.real34NextPlus(&c34, &hi34);
    runtime.real34ToReal(&c34, &c);
    runtime.real34ToReal(&lo34, &lo);
    runtime.real34ToReal(&hi34, &hi);

    if (runtime.roundingMode == RM_DOWN or runtime.roundingMode == RM_FLOOR) { // the largest c with c^2 <= x
        runtime.realMultiply(&c, &c, &sq, &runtime.ctxtReal75);
        if (runtime.realCompareGreaterThan(&sq, x)) {
            c = lo;
        } else {
            runtime.realMultiply(&hi, &hi, &sq, &runtime.ctxtReal75);
            if (!runtime.realCompareGreaterThan(&sq, x)) {
                c = hi;
            }
        }
    } else if (runtime.roundingMode == RM_UP or runtime.roundingMode == RM_CEIL) { // the smallest c with c^2 >= x
        runtime.realMultiply(&c, &c, &sq, &runtime.ctxtReal75);
        if (runtime.realCompareLessThan(&sq, x)) {
            c = hi;
        } else {
            runtime.realMultiply(&lo, &lo, &sq, &runtime.ctxtReal75);
            if (!runtime.realCompareLessThan(&sq, x)) {
                c = lo;
            }
        }
    } else { // the neighbour nearest the root, on the side of its midpoint
        runtime.realAdd(&lo, &c, &sq, &runtime.ctxtReal75);
        runtime.realMultiply(&sq, runtime.z47_math_wrappers_const_1on2(), &sq, &runtime.ctxtReal75);
        runtime.realMultiply(&sq, &sq, &sq, &runtime.ctxtReal75);
        if (runtime.realCompareGreaterThan(&sq, x)) {
            c = lo;
        } else {
            runtime.realAdd(&c, &hi, &sq, &runtime.ctxtReal75);
            runtime.realMultiply(&sq, runtime.z47_math_wrappers_const_1on2(), &sq, &runtime.ctxtReal75);
            runtime.realMultiply(&sq, &sq, &sq, &runtime.ctxtReal75);
            if (runtime.realCompareLessThan(&sq, x)) {
                c = hi;
            }
        }
    }
    r.* = c;
}

fn sqrtReal() callconv(.c) void {
    var value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &value)) {
        return;
    }

    if (runtime.realIsInfinite(&value) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
        runtime.moreInfoOnError("In function sqrtReal:", "cannot use " ++ std_plus_minus ++ std_infinity ++ " as X input of sqrt when flag SPCRES is not set", null, null);
        return;
    }

    if (!runtime.realIsNegative(&value) or runtime.realIsZero(&value)) { // a zero of either sign is the real 0
        const x = value;
        runtime.realSquareRoot(&value, &value, &runtime.ctxtReal39);
        if (!runtime.realIsZero(&value) and !runtime.realIsSpecial(&value)) {
            sqrtRoundedOnce(&x, &value);
        }
        runtime.convertRealToResultRegister(&value, runtime.REGISTER_X, runtime.amNone);
        return;
    }

    if (runtime.getFlag(@intCast(runtime.FLAG_CPXRES))) {
        runtime.realSetPositiveSign(&value);
        runtime.realSquareRoot(&value, &value, &runtime.ctxtReal39);
        runtime.convertComplexToResultRegister(runtime.z47_math_wrappers_const_0(), &value, runtime.REGISTER_X);
        return;
    }

    runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
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
        if (runtime.__gmpz_sizeinbase(&value[0], 10) > 75) { // the root has 38 digits or more and is not an integer: 10*floor(sqrt(x)) + 5 rounds by RM to the digits sqrt(x) rounds to
            var a: runtime.real_t = undefined;

            runtime.__gmpz_mul_ui(&root[0], &root[0], 10);
            runtime.__gmpz_add_ui(&root[0], &root[0], 5);
            runtime.convertLongIntegerToReal(&root[0], &a, &runtime.ctxtReal34);
            runtime.realDivide(&a, abi.constants.const_10(), &a, &runtime.ctxtReal34);
            runtime.convertRealToResultRegister(&a, runtime.REGISTER_X, runtime.amNone);
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
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
        runtime.moreInfoOnError("In function curtReal:", "cannot use " ++ std_plus_minus ++ std_infinity ++ " as X input of curt when flag SPCRES is not set", null, null);
        return;
    }

    var a: runtime.real_t = value;

    runtime.realSetPositiveSign(&a);
    if (runtime.realIsNegative(&value)) {
        runtime.realSetPositiveSign(&value);
        runtime.PowerReal(&value, runtime.z47_math_wrappers_const_1on3(), &value, &runtime.ctxtReal39);
        runtime.realChangeSign(&value);
    } else {
        runtime.PowerReal(&value, runtime.z47_math_wrappers_const_1on3(), &value, &runtime.ctxtReal39);
    }
    if (!runtime.realIsZero(&a) and !runtime.realIsSpecial(&a)) { // a cube of a number of 34 digits gives that number
        const negative = runtime.realIsNegative(&value);
        runtime.realSetPositiveSign(&value);
        _ = runtime.realExactRoot(&a, runtime.z47_math_wrappers_const_3(), &value);
        if (negative) {
            realSetNegativeSign(&value);
        }
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
            runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE);
        }
        return;
    }

    runtime.processIntRealComplexMonadicFunction(&sqrtReal, &sqrtCplx, &sqrtShoI, &sqrtLonI);
}

pub fn cubeRoot(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexMonadicFunction(&curtReal, &curtCplx, &curtShoI, &curtLonI);
}
