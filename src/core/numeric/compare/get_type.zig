const std = @import("std");
const math_type_encode = @import("type_encode.zig"); // std-only type-report encoders
const runtime = @import("../command_wrappers/runtime.zig");
const abi = @import("abi"); // shared ABI bindings
const consts = abi.constants; // typed constant-blob accessors; q16632 is const34_1000
const real34_t = abi.Real34;

fn pushIntegerOut(value: i32) void {
    var long_integer: runtime.longInteger_t = undefined;

    runtime.__gmpz_init(&long_integer[0]);
    defer runtime.__gmpz_clear(&long_integer[0]);
    runtime.__gmpz_set_ui(&long_integer[0], @as(u32, @bitCast(value)));

    runtime.setSystemFlag(runtime.FLAG_ASLIFT);
    runtime.liftStack();
    runtime.convertLongIntegerToLongIntegerRegister(&long_integer[0], runtime.REGISTER_X);
    runtime.setSystemFlag(runtime.FLAG_ASLIFT);
}

// checkValue.c forms this value in real34 (decQuad) throughout: uInt32ToReal34,
// then real34Divide by const34_1000, then a raw real34Copy into X.
//
// The division has to stay in decQuad. Doing it in real_t under ctxtReal39 and
// converting down afterwards yields the same NUMBER with a different decimal
// COHORT -- 1 instead of 1.000 -- because decNumber's divide and the 39-to-34
// digit narrowing pick a different exponent than decQuad's divide does. On a
// calculator the cohort is the displayed trailing digits, so that is a visible
// divergence and not a rounding detail.
fn pushRealOut(value: i32) void {
    var real_output = std.mem.zeroes(real34_t);

    // The report value is built in `int` and handed to uInt32ToReal34, which
    // is the C conversion: a negative angle code arrives as its two's
    // complement, not as a refusal.
    runtime.uInt32ToReal34(@as(u32, @bitCast(value)), &real_output);
    runtime.real34Divide(&real_output, consts.q16632(), &real_output);

    runtime.setSystemFlag(runtime.FLAG_ASLIFT);
    runtime.liftStack();
    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
    // real34Copy (realType.h macro): copy the 16-byte value verbatim.
    runtime.registerReal34Ptr(runtime.REGISTER_X).bytes = real_output.bytes;
    runtime.setSystemFlag(runtime.FLAG_ASLIFT);
}

fn matrixVectorShape(header: *align(1) runtime.matrixHeader_t) i32 {
    return math_type_encode.matrixVectorShape(header.matrixRows, header.matrixColumns);
}

fn angleCode(angular_mode: i32) i32 {
    return math_type_encode.angleCode(angular_mode);
}

fn realMatrixVectorPolarCode() i32 {
    if (runtime.isRegisterMatrix2dVector(runtime.REGISTER_X)) {
        return 2;
    }

    if (!runtime.isRegisterMatrix3dVector(runtime.REGISTER_X)) {
        return 0;
    }

    return if (runtime.getVectorRegisterPolarMode(runtime.REGISTER_X) == runtime.amPolarCYL) 4 else 3;
}

pub fn getType() void {
    const data_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    // dtp and dam are plain `int` in fnGetType, and every code below is formed
    // in that width before the single conversion at the push.
    const dtp: i32 = @intCast(data_type);
    const angular_mode: i32 = @intCast(runtime.getRegisterAngularMode(runtime.REGISTER_X));

    switch (data_type) {
        runtime.dtLongInteger, runtime.dtTime, runtime.dtDate, runtime.dtString, runtime.dtReal34Matrix, runtime.dtConfig => {
            if (runtime.isRegisterMatrixVector(runtime.REGISTER_X)) {
                const header = runtime.registerMatrixHeaderPtr(runtime.REGISTER_X);
                pushRealOut(dtp * 1000 + 100 * angleCode(angular_mode) + 10 * realMatrixVectorPolarCode() + matrixVectorShape(header));
            } else if (data_type == runtime.dtReal34Matrix) {
                const header = runtime.registerMatrixHeaderPtr(runtime.REGISTER_X);
                const shape = matrixVectorShape(header);

                if (shape != 0) {
                    pushRealOut(dtp * 1000 + shape);
                } else {
                    pushIntegerOut(dtp);
                }
            } else {
                pushIntegerOut(dtp);
            }
        },
        runtime.dtComplex34Matrix => {
            const header = runtime.registerMatrixHeaderPtr(runtime.REGISTER_X);
            const is_polar = runtime.getComplexRegisterPolarMode(runtime.REGISTER_X) != 0;
            const angle: i32 = if (is_polar) angleCode(angular_mode) else 0;
            const pol_rec: i32 = if (is_polar) 1 else 0;

            pushRealOut(dtp * 1000 + 100 * angle + 10 * pol_rec + matrixVectorShape(header));
        },
        runtime.dtShortInteger, runtime.dtReal34, runtime.dtComplex34 => {
            const short_bits: i32 = angular_mode & 0x1f;
            const value: i32 = if (data_type == runtime.dtShortInteger)
                10 * (dtp * 100 + short_bits)
            else
                100 * (dtp * 10 + angleCode(angular_mode));

            pushRealOut(value);
        },
        else => {},
    }

    runtime.temporaryInformation = runtime.TI_REGTYPE;
}
