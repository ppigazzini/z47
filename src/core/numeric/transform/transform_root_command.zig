const abi = @import("abi");
const runtime = @import("../command_wrappers/runtime.zig");
const transform_complex_helpers_owned = @import("transform_complex_helpers.zig");

const real_t = runtime.real_t;
const cplx_t = runtime.cplx_t;

inline fn realSetNegativeSign(operand: *real_t) void {
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
        var value: real_t = undefined;

        runtime.convertShortIntegerRegisterToReal(runtime.REGISTER_X, &value, &runtime.ctxtReal39);
        runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtComplex34, 0, runtime.amNone);
        runtime.realSetPositiveSign(&value);
        runtime.realSquareRoot(&value, &value, &runtime.ctxtReal39);
        runtime.convertComplexPartsToResultRegister(runtime.z47_math_wrappers_const_0(), &value, runtime.REGISTER_X);
        return;
    }

    runtime.registerShortIntegerPtr(runtime.REGISTER_X).* = runtime.WP34S_intSqrt(runtime.registerShortIntegerPtr(runtime.REGISTER_X).*);
}

fn sqrtReal() callconv(.c) void {
    var a: real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &a)) {
        return;
    }

    if (runtime.realIsInfinite(&a) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
        runtime.moreInfoOnError("In function sqrtReal:", "cannot use " ++ std_plus_minus ++ std_infinity ++ " as X input of sqrt when flag SPCRES is not set", null, null);
        return;
    }

    if (runtime.realIsZero(&a)) {
        runtime.convertRealToResultRegister(&a, runtime.REGISTER_X, runtime.amNone);
    } else if (!runtime.realIsNegative(&a)) {
        var root: runtime.real34_t = undefined;

        // The root of the integer coefficient, rounded once by RM; an exact root keeps the exponent of its coefficient's root.
        if (runtime.rootRegisterToReal34(runtime.REGISTER_X, 2, true, &root)) {
            runtime.convertReal34ToReal34Register(&root, runtime.REGISTER_X);
            return;
        }
        runtime.realSquareRoot(&a, &a, &runtime.ctxtReal39);
        runtime.convertRealToResultRegister(&a, runtime.REGISTER_X, runtime.amNone);
    } else if (runtime.getFlag(@intCast(runtime.FLAG_CPXRES))) {
        runtime.realSetPositiveSign(&a);
        runtime.realSquareRoot(&a, &a, &runtime.ctxtReal39);
        runtime.convertComplexPartsToResultRegister(runtime.z47_math_wrappers_const_0(), &a, runtime.REGISTER_X);
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
        runtime.moreInfoOnError("In function sqrtReal:", std_square_root ++ std_x_under_root ++ " doesn't work on a negative real when flag I is not set!", null, null);
    }
}

// The n-th root of a long integer in X, for n = 2 (sqrt) and n = 3 (curt): an
// exact integer root stays a long integer; a negative radicand of an even order
// becomes 0 + i root when CPXRES is set and the root is exact in 34 digits; an
// inexact root is rounded once to Real34; anything else falls through to the
// real command, with its errors.
fn rootLonI(n: u32) void {
    var lg_int: runtime.longInteger_t = undefined;
    var rounded_root: runtime.real34_t = undefined;

    // The reader initialises its value on every path, refusals included, so the
    // clear must cover the failure branch too.
    defer runtime.__gmpz_clear(&lg_int[0]);
    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &lg_int[0], null)) {
        return;
    }

    const n_is_odd = (n % 2) != 0;
    if (n_is_odd or !runtime.longIntegerIsNegative(&lg_int[0])) {
        var rem: runtime.longInteger_t = undefined;
        var root: runtime.longInteger_t = undefined;

        runtime.__gmpz_init(&rem[0]);
        defer runtime.__gmpz_clear(&rem[0]);
        runtime.__gmpz_init(&root[0]);
        defer runtime.__gmpz_clear(&root[0]);

        runtime.__gmpz_rootrem(&root[0], &rem[0], &lg_int[0], n);
        if (runtime.longIntegerIsZero(&rem[0])) {
            runtime.convertLongIntegerToLongIntegerRegister(&root[0], runtime.REGISTER_X);
            return;
        }
    }
    if (n == 2 and runtime.longIntegerIsNegative(&lg_int[0]) and runtime.getFlag(@intCast(runtime.FLAG_CPXRES))) {
        var magnitude: runtime.longInteger_t = undefined;

        runtime.__gmpz_init(&magnitude[0]);
        runtime.__gmpz_abs(&magnitude[0], &lg_int[0]);
        const exact_root = runtime.rootLongIntegerToReal34(&magnitude[0], 2, &rounded_root);
        runtime.__gmpz_clear(&magnitude[0]);
        if (exact_root) {
            runtime.convertReal34ToComplex34Register(abi.constants.const34_0(), &rounded_root, runtime.REGISTER_X);
            return;
        }
    }
    if (runtime.rootLongIntegerToReal34(&lg_int[0], n, &rounded_root)) {
        runtime.convertReal34ToReal34Register(&rounded_root, runtime.REGISTER_X);
        return;
    }
    // fall through to the real calculation, with its errors
    if (n == 2) {
        sqrtReal();
    } else if (n == 3) {
        curtReal();
    }
}

fn sqrtLonI() callconv(.c) void {
    rootLonI(2);
}

fn sqrtCplx() callconv(.c) void {
    var a: cplx_t = undefined;

    if (runtime.getRegisterAsComplex(runtime.REGISTER_X, &a)) {
        transform_complex_helpers_owned.sqrtComplex(&a, &a, &runtime.ctxtReal39);
        runtime.convertComplexToResultRegister(&a, runtime.REGISTER_X);
    }
}

fn curtShoI() callconv(.c) void {
    var value: real_t = undefined;
    var operand: real_t = undefined;
    var nearest: real_t = undefined;
    var cube: real_t = undefined;
    var cube_root: i32 = 0;

    runtime.convertShortIntegerRegisterToReal(runtime.REGISTER_X, &value, &runtime.ctxtReal39);
    operand = value;

    if (runtime.realIsNegative(&value)) {
        runtime.realSetPositiveSign(&value);
        runtime.PowerReal(&value, runtime.z47_math_wrappers_const_1on3(), &value, &runtime.ctxtReal39);
        realSetNegativeSign(&value);
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
    var x: real_t = undefined;
    var operand: real_t = undefined;
    var root: runtime.real34_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }
    operand = x;

    if (runtime.realIsInfinite(&x) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
        runtime.moreInfoOnError("In function curtReal:", "cannot use " ++ std_plus_minus ++ std_infinity ++ " as X input of curt when flag SPCRES is not set", null, null);
        return;
    }

    if (runtime.realIsZero(&x)) {
        runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
        return;
    }
    if (runtime.rootRegisterToReal34(runtime.REGISTER_X, 3, true, &root)) { // the cube root of the integer coefficient, rounded once by RM
        runtime.real34ToReal(&root, &x);
    } else if (!runtime.realIsNegative(&x)) {
        runtime.PowerReal(&x, runtime.z47_math_wrappers_const_1on3(), &x, &runtime.ctxtReal39);
    } else {
        runtime.realSetPositiveSign(&x);
        runtime.PowerReal(&x, runtime.z47_math_wrappers_const_1on3(), &x, &runtime.ctxtReal39);
        realSetNegativeSign(&x);
    }
    transform_complex_helpers_owned.correctExactReal34Cube(&operand, &x);
    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
}

fn curtLonI() callconv(.c) void {
    rootLonI(3);
}

fn curtCplx() callconv(.c) void {
    var a: cplx_t = undefined;

    if (runtime.getRegisterAsComplex(runtime.REGISTER_X, &a)) {
        const operand_real = a.Real;
        const operand_imaginary_zero = runtime.realIsZero(&a.Imag);
        transform_complex_helpers_owned.curtComplex(&a, &a, &runtime.ctxtReal39);
        if (operand_imaginary_zero) {
            transform_complex_helpers_owned.correctExactReal34Cube(&operand_real, &a.Real);
        }
        runtime.convertComplexToResultRegister(&a, runtime.REGISTER_X);
    }
}

pub fn squareRoot(unused_but_mandatory_parameter: u16) void {
    const register_type = runtime.getRegisterDataType(runtime.REGISTER_X);

    _ = unused_but_mandatory_parameter;

    if (register_type == runtime.dtReal34Matrix or register_type == runtime.dtComplex34Matrix) {
        // squareRoot.c takes the matrix branch to fnMatrixSquareRoot only under
        // OPTION_EIGEN; its #else arm refuses the operand instead. On a DM42
        // package without the option fnMatrixSquareRoot is itself an empty stub.
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
