const runtime = @import("math_command_wrappers_runtime.zig");

const SpecialKind = enum {
    nan,
    infinite,
    special,
};

const ZeroSign = enum {
    plus,
    minus,
};

const CHECK_INTEGER: u16 = 0;
const CHECK_INTEGER_EVEN: u16 = 1;
const CHECK_INTEGER_ODD: u16 = 2;
const CHECK_INTEGER_FP: u16 = 3;
const ITM_ISREZQ: u16 = 2527;
const ITM_ISIMZQ: u16 = 2528;
const ITM_ISRENZQ: u16 = 2529;
const ITM_ISIMNZQ: u16 = 2530;

fn typeErrorX() void {
    runtime.setTemporaryInformation(false);
    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_T);
}

fn matchesRealSpecial(value: *align(1) const runtime.real34_t, comptime kind: SpecialKind) bool {
    return switch (kind) {
        .nan => runtime.real34IsNaN(value),
        .infinite => runtime.real34IsInfinite(value),
        .special => runtime.real34IsNaN(value) or runtime.real34IsInfinite(value),
    };
}

fn matchesComplexSpecial(value: *align(1) const runtime.complex34_t, comptime kind: SpecialKind) bool {
    return matchesRealSpecial(&value.real, kind) or matchesRealSpecial(&value.imag, kind);
}

fn checkMatrixElements(register_data_type: u32, comptime kind: SpecialKind) bool {
    const ptr = runtime.getRegisterDataPointer(runtime.REGISTER_X) orelse unreachable;
    const header: *align(1) runtime.matrixHeader_t = @ptrCast(ptr);
    const bytes: [*]align(1) const u8 = @ptrCast(ptr);
    const elements: usize = @as(usize, header.matrixRows) * @as(usize, header.matrixColumns);

    switch (register_data_type) {
        runtime.dtReal34Matrix => {
            const values: [*]align(1) const runtime.real34_t = @ptrCast(bytes + @sizeOf(runtime.matrixHeader_t));
            var index: usize = 0;
            while (index < elements) : (index += 1) {
                if (matchesRealSpecial(&values[index], kind)) {
                    return true;
                }
            }
        },
        runtime.dtComplex34Matrix => {
            const values: [*]align(1) const runtime.complex34_t = @ptrCast(bytes + @sizeOf(runtime.matrixHeader_t));
            var index: usize = 0;
            while (index < elements) : (index += 1) {
                if (matchesComplexSpecial(&values[index], kind)) {
                    return true;
                }
            }
        },
        else => return false,
    }

    return false;
}

fn setCheckIntegerResult(mode: u16, is_odd: bool) void {
    switch (mode) {
        CHECK_INTEGER => runtime.setTemporaryInformation(true),
        CHECK_INTEGER_EVEN => runtime.setTemporaryInformation(!is_odd),
        CHECK_INTEGER_ODD => runtime.setTemporaryInformation(is_odd),
        CHECK_INTEGER_FP => runtime.setTemporaryInformation(false),
        else => {},
    }
}

fn setCheckForZeroResult(mode: u16, real_is_zero: bool, imag_is_zero: bool) void {
    switch (mode) {
        ITM_ISREZQ => runtime.setTemporaryInformation(real_is_zero),
        ITM_ISIMZQ => runtime.setTemporaryInformation(imag_is_zero),
        ITM_ISRENZQ => runtime.setTemporaryInformation(!real_is_zero),
        ITM_ISIMNZQ => runtime.setTemporaryInformation(!imag_is_zero),
        else => {},
    }
}

fn tryCheckForZero(mode: u16) bool {
    switch (runtime.getRegisterDataType(runtime.REGISTER_X)) {
        runtime.dtLongInteger => {
            var value: runtime.longInteger_t = undefined;
            runtime.convertLongIntegerRegisterToLongInteger(runtime.REGISTER_X, &value[0]);
            defer runtime.__gmpz_clear(&value[0]);

            setCheckForZeroResult(mode, value[0]._mp_size == 0, true);
            return true;
        },
        runtime.dtShortInteger => {
            var value: u64 = 0;
            var sign: i16 = 0;
            runtime.convertShortIntegerRegisterToUInt64(runtime.REGISTER_X, &sign, &value);

            setCheckForZeroResult(mode, value == 0, true);
            return true;
        },
        runtime.dtComplex34 => {
            const value = runtime.registerComplex34Ptr(runtime.REGISTER_X);
            setCheckForZeroResult(mode, runtime.real34IsZero(&value.real), runtime.real34IsZero(&value.imag));
            return true;
        },
        runtime.dtTime, runtime.dtDate, runtime.dtReal34 => {
            setCheckForZeroResult(mode, runtime.real34IsZero(runtime.registerReal34Ptr(runtime.REGISTER_X)), true);
            return true;
        },
        else => return false,
    }
}

fn tryCheckSignedZero(comptime sign: ZeroSign) bool {
    const negative = sign == .minus;
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);

    switch (register_data_type) {
        runtime.dtLongInteger => {
            var value: runtime.longInteger_t = undefined;
            runtime.convertLongIntegerRegisterToLongInteger(runtime.REGISTER_X, &value[0]);
            defer runtime.__gmpz_clear(&value[0]);

            runtime.setTemporaryInformation(!negative and value[0]._mp_size == 0);
            return true;
        },
        runtime.dtShortInteger => {
            var stored_sign: i16 = 0;
            var value: u64 = 0;
            runtime.convertShortIntegerRegisterToUInt64(runtime.REGISTER_X, &stored_sign, &value);
            runtime.setTemporaryInformation(value == 0 and stored_sign == @intFromBool(negative));
            return true;
        },
        runtime.dtComplex34 => {
            const value = runtime.registerComplex34Ptr(runtime.REGISTER_X);
            runtime.setTemporaryInformation(runtime.real34IsZero(&value.real) and runtime.real34IsZero(&value.imag) and (runtime.real34IsNegative(&value.real) == negative or runtime.real34IsNegative(&value.imag) == negative));
            return true;
        },
        runtime.dtTime, runtime.dtDate, runtime.dtReal34 => {
            runtime.setTemporaryInformation(runtime.real34IsNegative(runtime.registerReal34Ptr(runtime.REGISTER_X)) == negative and runtime.real34IsZero(runtime.registerReal34Ptr(runtime.REGISTER_X)));
            return true;
        },
        else => return false,
    }
}

// signedZeroCheck (checkValue.c): compare the SIGN bit (not zero-ness).
//   neg = true  -> x <= -0?  true for negatives and -0
//   neg = false -> x >= +0?  true for positives and +0
// The invalid-type path uses compareTypeErrorX() upstream; typeErrorX() here is
// behaviorally identical in the default build (the extra moreInfoOnError hint is
// EXTRA_INFO_ON_CALC_ERROR-gated).
fn signedZeroCheck(neg: bool) void {
    var check: bool = false;
    switch (runtime.getRegisterDataType(runtime.REGISTER_X)) {
        runtime.dtLongInteger => {
            var value: runtime.longInteger_t = undefined;
            runtime.convertLongIntegerRegisterToLongInteger(runtime.REGISTER_X, &value[0]);
            defer runtime.__gmpz_clear(&value[0]);
            check = (value[0]._mp_size < 0) == neg; // long integers have no -0: zero is +0
        },
        runtime.dtShortInteger => {
            var stored_sign: i16 = 0;
            var value: u64 = 0;
            runtime.convertShortIntegerRegisterToUInt64(runtime.REGISTER_X, &stored_sign, &value);
            check = stored_sign == @intFromBool(neg);
        },
        runtime.dtTime, runtime.dtDate, runtime.dtReal34 => {
            check = runtime.real34IsNegative(runtime.registerReal34Ptr(runtime.REGISTER_X)) == neg;
        },
        else => {
            typeErrorX();
            return;
        },
    }
    runtime.setTemporaryInformation(check);
}

pub fn checkType(type_: u16) void {
    runtime.setTemporaryInformation(runtime.getRegisterDataType(runtime.REGISTER_X) == type_);
}

pub fn checkReal() void {
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    runtime.setTemporaryInformation(register_data_type <= runtime.dtDate or register_data_type == runtime.dtShortInteger);
}

pub fn checkNumber() void {
    const is_number = switch (runtime.getRegisterDataType(runtime.REGISTER_X)) {
        runtime.dtLongInteger, runtime.dtShortInteger => true,
        runtime.dtComplex34 => blk: {
            const imag_is_number = !(runtime.real34IsNaN(runtime.registerImag34Ptr(runtime.REGISTER_X)) or runtime.real34IsInfinite(runtime.registerImag34Ptr(runtime.REGISTER_X)));
            const real_is_number = !(runtime.real34IsNaN(runtime.registerReal34Ptr(runtime.REGISTER_X)) or runtime.real34IsInfinite(runtime.registerReal34Ptr(runtime.REGISTER_X)));
            break :blk imag_is_number and real_is_number;
        },
        runtime.dtTime, runtime.dtDate, runtime.dtReal34 => !(runtime.real34IsNaN(runtime.registerReal34Ptr(runtime.REGISTER_X)) or runtime.real34IsInfinite(runtime.registerReal34Ptr(runtime.REGISTER_X))),
        else => false,
    };

    runtime.setTemporaryInformation(is_number);
}

pub fn checkAngle() void {
    runtime.setTemporaryInformation(runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtReal34 and runtime.getRegisterAngularMode(runtime.REGISTER_X) != runtime.amNone);
}

pub fn checkMatrix() void {
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    runtime.setTemporaryInformation(register_data_type == runtime.dtReal34Matrix or register_data_type == runtime.dtComplex34Matrix);
}

pub fn checkMatrixSquare() void {
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);

    if (register_data_type == runtime.dtReal34Matrix or register_data_type == runtime.dtComplex34Matrix) {
        const header = runtime.registerMatrixHeaderPtr(runtime.REGISTER_X);
        runtime.setTemporaryInformation(header.matrixRows == header.matrixColumns);
        return;
    }

    typeErrorX();
}

pub fn checkRealMatrixVector(dimension: u16) void {
    if (runtime.getRegisterDataType(runtime.REGISTER_X) != runtime.dtReal34Matrix) {
        typeErrorX();
        return;
    }

    const header = runtime.registerMatrixHeaderPtr(runtime.REGISTER_X);
    runtime.setTemporaryInformation((header.matrixRows == 1 and header.matrixColumns == dimension) or (header.matrixRows == dimension and header.matrixColumns == 1));
}

pub fn checkNaN() void {
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);

    switch (register_data_type) {
        runtime.dtComplex34 => {
            runtime.setTemporaryInformation(matchesComplexSpecial(runtime.registerComplex34Ptr(runtime.REGISTER_X), .nan));
        },
        runtime.dtTime, runtime.dtDate, runtime.dtReal34 => {
            runtime.setTemporaryInformation(matchesRealSpecial(runtime.registerReal34Ptr(runtime.REGISTER_X), .nan));
        },
        runtime.dtReal34Matrix, runtime.dtComplex34Matrix => {
            runtime.setTemporaryInformation(checkMatrixElements(register_data_type, .nan));
        },
        else => typeErrorX(),
    }
}

pub fn checkInfinite() void {
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);

    switch (register_data_type) {
        runtime.dtComplex34 => {
            runtime.setTemporaryInformation(matchesComplexSpecial(runtime.registerComplex34Ptr(runtime.REGISTER_X), .infinite));
        },
        runtime.dtTime, runtime.dtDate, runtime.dtReal34 => {
            runtime.setTemporaryInformation(matchesRealSpecial(runtime.registerReal34Ptr(runtime.REGISTER_X), .infinite));
        },
        runtime.dtReal34Matrix, runtime.dtComplex34Matrix => {
            runtime.setTemporaryInformation(checkMatrixElements(register_data_type, .infinite));
        },
        else => typeErrorX(),
    }
}

pub fn checkSpecial() void {
    const register_data_type = runtime.getRegisterDataType(runtime.REGISTER_X);

    switch (register_data_type) {
        runtime.dtComplex34 => {
            runtime.setTemporaryInformation(matchesComplexSpecial(runtime.registerComplex34Ptr(runtime.REGISTER_X), .special));
        },
        runtime.dtTime, runtime.dtDate, runtime.dtReal34 => {
            runtime.setTemporaryInformation(matchesRealSpecial(runtime.registerReal34Ptr(runtime.REGISTER_X), .special));
        },
        runtime.dtReal34Matrix, runtime.dtComplex34Matrix => {
            runtime.setTemporaryInformation(checkMatrixElements(register_data_type, .special));
        },
        else => typeErrorX(),
    }
}

pub fn checkInteger(mode: u16) void {
    var value: runtime.longInteger_t = undefined;
    var fractional = false;
    const err = runtime.getRegisterAsLongIntQuiet(runtime.REGISTER_X, &value[0], &fractional);
    defer runtime.__gmpz_clear(&value[0]);

    if (err != @as(c_int, runtime.ERROR_NONE)) {
        typeErrorX();
    } else if (fractional) {
        runtime.setTemporaryInformation(mode == CHECK_INTEGER_FP);
    } else {
        runtime.fnRefreshState();
        setCheckIntegerResult(mode, value[0]._mp_size != 0 and (value[0]._mp_d[0] & 1) != 0);
    }
}

pub fn checkForZero(mode: u16) void {
    if (!tryCheckForZero(mode)) {
        typeErrorX();
    }
}

pub fn checkPlusZero() void {
    if (!tryCheckSignedZero(.plus)) {
        typeErrorX();
    }
}

pub fn checkMinusZero() void {
    if (!tryCheckSignedZero(.minus)) {
        typeErrorX();
    }
}
pub fn checkLessEqualMinusZero() void {
    signedZeroCheck(true);
}
pub fn checkGreaterEqualPlusZero() void {
    signedZeroCheck(false);
}