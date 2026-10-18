const abi = @import("abi");
const runtime = @import("../command_wrappers/runtime.zig");

fn signReal() callconv(.c) void {
    const x = runtime.registerReal34Ptr(runtime.REGISTER_X);

    if (runtime.real34IsNaN(x)) {
        runtime.z47_math_wrappers_report_sign_real_nan_error();
        return;
    }

    runtime.z47_math_wrappers_build_sign_result(
        if (runtime.real34IsZero(x))
            0
        else if (runtime.real34IsNegative(x))
            -1
        else
            1,
    );
}

fn signCplx() callconv(.c) void {
    runtime.unitVectorCplx();
}

fn signShoI() callconv(.c) void {
    var sign_value: i32 = 0;
    const value = runtime.WP34S_extract_value(runtime.registerShortIntegerPtr(runtime.REGISTER_X).*, &sign_value);

    runtime.z47_math_wrappers_build_sign_result(
        if (value == 0)
            0
        else
            2 * -sign_value + 1,
    );
}

fn signLonI() callconv(.c) void {
    const sign_result: i32 = switch (runtime.getRegisterLongIntegerSign(runtime.REGISTER_X)) {
        runtime.LI_ZERO => 0,
        runtime.LI_NEGATIVE => -1,
        runtime.LI_POSITIVE => 1,
        else => unreachable,
    };

    runtime.z47_math_wrappers_build_sign_result(sign_result);
}

// real34ChangeSign is a decQuad macro over the sign bit.
inline fn real34ChangeSign(value: *align(1) runtime.real34_t) void {
    value.bytes[15] ^= runtime.DECNEG;
}

fn chsZeroCheck(a: *align(1) runtime.real34_t) void {
    real34ChangeSign(a);
    if (runtime.real34IsZero(a) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.real34SetPositiveSign(a);
    }
}

pub fn chsReal() callconv(.c) void {
    chsZeroCheck(runtime.registerReal34Ptr(runtime.REGISTER_X));
}

pub fn chsCplx() callconv(.c) void {
    chsZeroCheck(runtime.registerReal34Ptr(runtime.REGISTER_X));
    chsZeroCheck(runtime.registerImag34Ptr(runtime.REGISTER_X));
    runtime.setRegisterTag(runtime.REGISTER_X, @intCast(runtime.amNone));
}

fn chsRema() void {
    var matrix: runtime.real34Matrix_t = undefined;

    runtime.linkToRealMatrixRegister(runtime.REGISTER_X, &matrix);
    const elements = abi.matrixRealElems(&matrix);
    const count: u16 = @truncate(@as(u32, matrix.header.matrixRows) * @as(u32, matrix.header.matrixColumns));
    var i: u16 = 0;
    while (i < count) : (i += 1) {
        chsZeroCheck(&elements[i]);
    }
    runtime.setRegisterTag(runtime.REGISTER_X, @intCast(runtime.amNone));
}

fn chsCxma() void {
    var matrix: runtime.complex34Matrix_t = undefined;

    runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &matrix);
    const elements = abi.matrixComplexElems(&matrix);
    const count: u16 = @truncate(@as(u32, matrix.header.matrixRows) * @as(u32, matrix.header.matrixColumns));
    var i: u16 = 0;
    while (i < count) : (i += 1) {
        chsZeroCheck(&elements[i].real);
        chsZeroCheck(&elements[i].imag);
    }
    runtime.setRegisterTag(runtime.REGISTER_X, @intCast(runtime.amNone));
}

pub fn chsShoI() callconv(.c) void {
    runtime.registerShortIntegerPtr(runtime.REGISTER_X).* = runtime.WP34S_intChs(runtime.registerShortIntegerPtr(runtime.REGISTER_X).*);
}

pub fn chsLonI() callconv(.c) void {
    var x: runtime.longInteger_t = undefined;

    // getRegisterAsLongInt initialises its output on every path, refusals
    // included, so the clear has to be registered before the refusal check.
    defer runtime.__gmpz_clear(&x[0]);
    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &x[0], null)) {
        return;
    }

    x[0]._mp_size = -x[0]._mp_size;
    runtime.convertLongIntegerToLongIntegerRegister(&x[0], runtime.REGISTER_X);
}

pub fn sign(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processIntRealComplexMonadicFunction(&signReal, &signCplx, &signShoI, &signLonI);
}

pub fn changeSign(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtTime) {
        chsZeroCheck(runtime.registerReal34Ptr(runtime.REGISTER_X));
        return;
    }
    if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtReal34Matrix) {
        chsRema();
        runtime.adjustResult(runtime.REGISTER_X, false, true, runtime.REGISTER_X, -1, -1);
        return;
    }
    if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtComplex34Matrix) {
        chsCxma();
        runtime.adjustResult(runtime.REGISTER_X, false, true, runtime.REGISTER_X, -1, -1);
        return;
    }

    runtime.processIntRealComplexMonadicFunction(&chsReal, &chsCplx, &chsShoI, &chsLonI);
}
