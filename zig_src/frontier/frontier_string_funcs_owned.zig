// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/stringFuncs.c: the alpha-string commands aLENG?,
// a->x, x->a, aPOS?, aRR, aRL, aSR and aSL. This is a faithful, line-by-line
// port of the C. The long-integer paths go straight to the GMP __gmpz_*
// entry points (mpz_*/longInteger* are header macros/static inlines), the
// real34 compare/convert paths reuse the registerValueConversions owner's
// exported converters, and stringByteLength is reproduced inline as
// (int32_t)strlen() exactly like charString.h.
//
// stringFuncs.c is not reachable from the testSuite; verification is by
// build/link across every target plus the boundary gates.

const frontier_build_options = @import("frontier_build_options");
const extra_info: bool = frontier_build_options.extra_info_on_calc_error;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const DECNUMUNITS = 25;
const real_t = extern struct {
    digits: i32,
    exponent: i32,
    bits: u8,
    lsu: [DECNUMUNITS]u16,
};
const real34_t = extern struct { bytes: [16]u8 };
const realContext_t = extern struct {
    digits: i32,
    emax: i32,
    emin: i32,
    round: c_int,
    traps: u32,
    status: u32,
    clamp: u8,
};
const calcRegister_t = i16;

// GMP mpz_struct. Limb width == pointer width on every target z47 builds
// (64-bit on Linux and Win64, 32-bit on ARM32 firmware). NOT c_ulong: Win64
// is LLP64 where `unsigned long` is 32-bit yet GMP limbs are 64-bit.
const mp_limb_t = usize;
const mpz_struct = extern struct {
    _mp_alloc: c_int,
    _mp_size: c_int,
    _mp_d: [*c]mp_limb_t,
};
const longInteger_t = [1]mpz_struct;

// ---------------------------------------------------------------------------
// Constants / enum values (verified against defines.h / typeDefinitions.h)
// ---------------------------------------------------------------------------
const dtLongInteger: u32 = 0;
const dtReal34: u32 = 1;
const dtString: u32 = 5;
const dtShortInteger: u32 = 8;

const amNone: u32 = 5;

const ERROR_INVALID_DATA_TYPE_FOR_OP: u8 = 24;
const ERROR_OUT_OF_RANGE: u8 = 8;
const ERROR_EMPTY_STRING: u8 = 34;

const REGISTER_X: calcRegister_t = 100;
const REGISTER_Z: calcRegister_t = 102;
const REGISTER_T: calcRegister_t = 103;
const REGISTER_D: calcRegister_t = 107;
const ERR_REGISTER_LINE: calcRegister_t = REGISTER_Z;

const FLAG_ASLIFT: c_int = 0xc023;
const FLAG_SSIZE8: c_int = 0x8018;

const DEC_ROUND_DOWN: c_int = 5;

// ---------------------------------------------------------------------------
// Constant blob (offsets from the generated constantPointers.h)
// ---------------------------------------------------------------------------
const constants = @extern([*]const u8, .{ .name = "constants" });
const OFF_const34_1e6 = 16348;

inline fn cst34(offset: u32) *align(1) const real34_t {
    return @ptrCast(constants + offset);
}

// ---------------------------------------------------------------------------
// Globals
// ---------------------------------------------------------------------------
extern var tmpString: [*c]u8;
extern var errorMessage: [*c]u8;
extern var ctxtReal34: realContext_t;
extern var ctxtReal39: realContext_t;

// ---------------------------------------------------------------------------
// Function externs
// ---------------------------------------------------------------------------
extern fn getRegisterDataType(regist: calcRegister_t) u32;
extern fn getRegisterDataPointer(regist: calcRegister_t) *anyopaque;
extern fn getRegisterDataTypeName(regist: calcRegister_t, article: bool, pad: bool) [*c]const u8;
extern fn displayCalcErrorMessage(error_code: u8, err_message_line: calcRegister_t, err_register_line: calcRegister_t) void;
const c_moreInfoOnError = @extern(*const fn (m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) callconv(.c) void, .{ .name = "moreInfoOnError" });
extern fn sprintf(buf: [*c]u8, fmt: [*:0]const u8, ...) c_int;
extern fn strlen(str: [*c]const u8) usize;
extern fn liftStack() void;
extern fn saveLastX() bool;
extern fn getSystemFlag(flag: c_int) bool;
extern fn reallocateRegister(regist: calcRegister_t, data_type: u32, size_blocks: u16, tag: u32) void;
extern fn xcopy(dst: *anyopaque, src: *const anyopaque, n: u32) *anyopaque;
extern fn stringGlyphLength(str: [*c]const u8) i32;
extern fn stringNextGlyph(str: [*c]const u8, pos: i16) i16;
extern fn WP34S_Mod(x: *const real_t, y: *align(1) const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn real34CompareAbsGreaterThan(number1: *align(1) const real34_t, number2: *align(1) const real34_t) bool;
extern fn decimal128ToNumber(src: *align(1) const real34_t, dst: *real_t) *real_t;
extern fn decNumberFromInt32(r: *real_t, v: i32) *real_t;

// Converters exported by the registerValueConversions owner.
extern fn convertLongIntegerToLongIntegerRegister(lgInt: *const mpz_struct, regist: calcRegister_t) void;
extern fn convertLongIntegerRegisterToLongInteger(regist: calcRegister_t, lgInt: *mpz_struct) void;
extern fn convertLongIntegerToShortIntegerRegister(lgInt: *mpz_struct, base: u32, destination: calcRegister_t) void;
extern fn convertShortIntegerRegisterToLongInteger(source: calcRegister_t, lgInt: *mpz_struct) void;
extern fn convertReal34ToLongInteger(re34: *align(1) const real34_t, lgInt: *mpz_struct, roundingMode: c_int) void;
extern fn convertRealToLongInteger(re: *const real_t, lgInt: *mpz_struct, roundingMode: c_int) void;

// ---------------------------------------------------------------------------
// GMP externs (mpz_* are header macros; the linkable symbols are __gmpz_*)
// ---------------------------------------------------------------------------
extern fn @"__gmpz_init"(p: *mpz_struct) void;
extern fn @"__gmpz_clear"(p: *mpz_struct) void;
extern fn @"__gmpz_set_ui"(p: *mpz_struct, v: c_ulong) void;
extern fn @"__gmpz_set_si"(p: *mpz_struct, v: c_long) void;
extern fn @"__gmpz_add_ui"(r: *mpz_struct, op: *const mpz_struct, c: c_ulong) void;
extern fn @"__gmpz_mul_ui"(r: *mpz_struct, op: *const mpz_struct, c: c_ulong) void;
extern fn @"__gmpz_fdiv_ui"(op: *const mpz_struct, c: c_ulong) c_ulong;
extern fn @"__gmpz_cmp_ui"(op: *const mpz_struct, c: c_ulong) c_int;
extern fn @"__gmpz_cmp_si"(op: *const mpz_struct, c: c_long) c_int;
extern fn @"__gmpz_get_si"(op: *const mpz_struct) c_long;

// ---------------------------------------------------------------------------
// Inline wrappers (the C macros / static inlines)
// ---------------------------------------------------------------------------
inline fn moreInfoOnError(m1: [*:0]const u8, m2: ?[*:0]const u8) void {
    if (comptime extra_info) c_moreInfoOnError(m1, m2, null, null);
}
inline fn regString(reg: calcRegister_t) [*c]u8 {
    // REGISTER_STRING_DATA: data pointer + sizeof(strLgIntHeader_t) == 4.
    return @as([*c]u8, @ptrCast(getRegisterDataPointer(reg))) + 4;
}
inline fn reg34(reg: calcRegister_t) *align(1) real34_t {
    return @ptrCast(getRegisterDataPointer(reg));
}
inline fn getStackTop() calcRegister_t {
    return if (getSystemFlag(FLAG_SSIZE8)) REGISTER_D else REGISTER_T;
}
inline fn stringByteLength(str: [*c]const u8) i32 {
    return @intCast(strlen(str));
}
inline fn longIntegerInit(lg: *mpz_struct) void {
    @"__gmpz_init"(lg);
}
inline fn longIntegerFree(lg: *mpz_struct) void {
    @"__gmpz_clear"(lg);
}
inline fn uInt32ToLongInteger(source: u32, destination: *mpz_struct) void {
    @"__gmpz_set_ui"(destination, source);
}
inline fn int32ToLongInteger(source: i32, destination: *mpz_struct) void {
    @"__gmpz_set_si"(destination, source);
}
inline fn longIntegerAddUInt(op: *const mpz_struct, uint: u32, result: *mpz_struct) void {
    @"__gmpz_add_ui"(result, op, uint);
}
inline fn longIntegerMultiplyUInt(op: *const mpz_struct, uint: u32, result: *mpz_struct) void {
    @"__gmpz_mul_ui"(result, op, uint);
}
inline fn longIntegerModuloUInt(op: *const mpz_struct, uint: u32) u32 {
    return @truncate(@"__gmpz_fdiv_ui"(op, uint));
}
inline fn longIntegerCompareUInt(op: *const mpz_struct, uint: u32) i32 {
    return @"__gmpz_cmp_ui"(op, uint);
}
inline fn longIntegerCompareInt(op: *const mpz_struct, sint: i32) i32 {
    return @"__gmpz_cmp_si"(op, sint);
}
inline fn longIntegerIsZero(op: *const mpz_struct) bool {
    return op._mp_size == 0;
}
inline fn longIntegerSetPositiveSign(op: *mpz_struct) void {
    op._mp_size = if (op._mp_size < 0) -op._mp_size else op._mp_size;
}
inline fn real34ToReal(src: *align(1) const real34_t, dst: *real_t) void {
    _ = decimal128ToNumber(src, dst);
}
inline fn int32ToReal(src: i32, dst: *real_t) void {
    _ = decNumberFromInt32(dst, src);
}
inline fn realSetPositiveSign(v: *real_t) void {
    v.bits &= 0x7f;
}

// ===========================================================================
// trimLeadingSpace (new in real master): drop a single leading space in place.
// Used by addition's addStri{Real,Cplx} display formatting.
pub export fn trimLeadingSpace(stringToTrim: [*c]u8) callconv(.c) void {
    if (stringToTrim[0] == ' ') {
        const len: i32 = stringByteLength(stringToTrim);
        _ = xcopy(stringToTrim, stringToTrim + 1, @intCast(len));
    }
}

// ===========================================================================
// fnAlphaLeng
// ===========================================================================
pub export fn fnAlphaLeng(regist: u16) callconv(.c) void {
    var stringSize: longInteger_t = undefined;

    if (getRegisterDataType(@intCast(regist)) != dtString) {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            _ = sprintf(errorMessage, "cannot get the \x83\xb1LENG? from %s", getRegisterDataTypeName(@intCast(regist), true, false));
            moreInfoOnError("In function fnAlphaLeng:", errorMessage);
        }
        return;
    }

    longIntegerInit(&stringSize[0]);
    int32ToLongInteger(stringGlyphLength(regString(@intCast(regist))), &stringSize[0]);

    liftStack();

    convertLongIntegerToLongIntegerRegister(&stringSize[0], REGISTER_X);
    longIntegerFree(&stringSize[0]);
}

// ===========================================================================
// fnAlphaToX
// ===========================================================================
pub export fn fnAlphaToX(regist_arg: u16) callconv(.c) void {
    var regist: u16 = regist_arg;
    var char1: u8 = undefined;
    var char2: u8 = undefined;
    var lgInt: longInteger_t = undefined;

    if (getRegisterDataType(@intCast(regist)) != dtString) {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            _ = sprintf(errorMessage, "cannot use \x83\xb1\xa1\x92x on %s", getRegisterDataTypeName(@intCast(regist), true, false));
            moreInfoOnError("In function fnAlphaToX:", errorMessage);
        }
        return;
    }

    if (stringByteLength(regString(@intCast(regist))) == 0) {
        displayCalcErrorMessage(ERROR_EMPTY_STRING, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            _ = sprintf(errorMessage, "cannot use \x83\xb1\xa1\x92x on an empty string");
            moreInfoOnError("In function fnAlphaToX:", errorMessage);
        }
        return;
    }

    char1 = regString(@intCast(regist))[0];
    char2 = undefined;
    if ((char1 & 0x80) != 0) {
        char2 = (regString(@intCast(regist)) + 1)[0];
    }

    liftStack();

    longIntegerInit(&lgInt[0]);
    uInt32ToLongInteger(char1 & 0x7f, &lgInt[0]);
    if ((char1 & 0x80) != 0) {
        longIntegerMultiplyUInt(&lgInt[0], 256, &lgInt[0]);
        longIntegerAddUInt(&lgInt[0], char2, &lgInt[0]);
    }

    convertLongIntegerToShortIntegerRegister(&lgInt[0], 16, REGISTER_X);
    longIntegerFree(&lgInt[0]);

    if (!getSystemFlag(FLAG_ASLIFT) or regist != @as(u16, @intCast(getStackTop()))) {
        if (@as(u16, @intCast(REGISTER_X)) <= regist and regist < @as(u16, @intCast(getStackTop()))) {
            regist += 1;
        }
        const skip: u16 = if ((char1 & 0x80) != 0) 2 else 1;
        _ = xcopy(regString(@intCast(regist)), regString(@intCast(regist)) + skip, @intCast(stringByteLength(regString(@intCast(regist)) + skip) + 1));
    }
}

// ===========================================================================
// fnXToAlpha
// ===========================================================================
pub export fn fnXToAlpha(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var lgInt: longInteger_t = undefined;
    var char1: u8 = undefined;
    var char2: u8 = undefined;

    longIntegerInit(&lgInt[0]);
    switch (getRegisterDataType(REGISTER_X)) {
        dtLongInteger => {
            // The register converter re-initializes lgInt itself (matches the C).
            convertLongIntegerRegisterToLongInteger(REGISTER_X, &lgInt[0]);
        },
        dtReal34 => {
            if (real34CompareAbsGreaterThan(reg34(REGISTER_X), cst34(OFF_const34_1e6))) {
                uInt32ToLongInteger(1000000, &lgInt[0]);
            } else {
                convertReal34ToLongInteger(reg34(REGISTER_X), &lgInt[0], DEC_ROUND_DOWN);
            }
        },
        dtShortInteger => {
            convertShortIntegerRegisterToLongInteger(REGISTER_X, &lgInt[0]);
        },
        else => {
            displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
            if (comptime extra_info) {
                _ = sprintf(errorMessage, "cannot x\xa1\x92\x83\xb1 when X is %s", getRegisterDataTypeName(REGISTER_X, true, false));
                moreInfoOnError("In function fnXToAlpha:", errorMessage);
            }
            return;
        },
    }

    longIntegerSetPositiveSign(&lgInt[0]);
    if (longIntegerCompareUInt(&lgInt[0], 0x8000) >= 0) {
        displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            _ = sprintf(errorMessage, "for x\xa1\x92\x83\xb1, X must be < 32768. Here X = %u", @as(u32, @truncate(lgInt[0]._mp_d[0]))); // OK for 32 and 64 bit limbs
            moreInfoOnError("In function fnXToAlpha:", errorMessage);
        }
        return;
    }

    liftStack();

    if (longIntegerIsZero(&lgInt[0])) {
        char1 = 0;
        char2 = 0;
    } else if (lgInt[0]._mp_d[0] < 0x0080) { // OK for 32 and 64 bit limbs
        char1 = @truncate(lgInt[0]._mp_d[0]); // OK for 32 and 64 bit limbs
        char2 = 0;
    } else {
        char1 = @truncate((lgInt[0]._mp_d[0] >> 8) | 0x80); // OK for 32 and 64 bit limbs
        char2 = @truncate(lgInt[0]._mp_d[0] & 0x00ff); // OK for 32 and 64 bit limbs
    }

    longIntegerFree(&lgInt[0]);

    reallocateRegister(REGISTER_X, dtString, 1, amNone);
    regString(REGISTER_X)[0] = char1;
    (regString(REGISTER_X) + 1)[0] = char2;
    (regString(REGISTER_X) + 2)[0] = 0;
}

// ===========================================================================
// fnAlphaPos
// ===========================================================================
pub export fn fnAlphaPos(regist: u16) callconv(.c) void {
    var lgInt: longInteger_t = undefined;

    if (getRegisterDataType(@intCast(regist)) != dtString) {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            _ = sprintf(errorMessage, "cannot use \x83\xb1POS? on %s (reg %u)", getRegisterDataTypeName(@intCast(regist), true, false), @as(c_uint, regist));
            moreInfoOnError("In function fnAlphaPos:", errorMessage);
        }
        return;
    }

    if (getRegisterDataType(REGISTER_X) != dtString) {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            _ = sprintf(errorMessage, "cannot use \x83\xb1POS? on %s (reg X)", getRegisterDataTypeName(@intCast(regist), true, false));
            moreInfoOnError("In function fnAlphaPos:", errorMessage);
        }
        return;
    }

    if (stringGlyphLength(regString(@intCast(regist))) == 0 or stringGlyphLength(regString(REGISTER_X)) == 0) {
        displayCalcErrorMessage(ERROR_EMPTY_STRING, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            _ = sprintf(errorMessage, "cannot use \x83\xb1POS? on or with an empty string");
            moreInfoOnError("In function fnAlphaPos:", errorMessage);
        }
        return;
    }

    if (!saveLastX()) {
        return;
    }

    longIntegerInit(&lgInt[0]);
    const ptrTarget: [*c]u8 = regString(REGISTER_X);
    const ptrRegist: [*c]u8 = regString(@intCast(regist));
    const lgTarget: i16 = @intCast(stringByteLength(ptrTarget));
    const lgRegist: i16 = @intCast(stringByteLength(ptrRegist));

    int32ToLongInteger(-1, &lgInt[0]);
    var i: i16 = 0;
    outer: while (i <= lgRegist - lgTarget) : (i += 1) {
        var found: bool = true;
        var j: i16 = 0;
        while (j < lgTarget) : (j += 1) {
            if ((ptrRegist + @as(usize, @intCast(i + j)))[0] != (ptrTarget + @as(usize, @intCast(j)))[0]) {
                found = false;
                break;
            }
        }
        if (found) {
            int32ToLongInteger(i, &lgInt[0]);
            break :outer;
        }
    }

    liftStack();
    convertLongIntegerToLongIntegerRegister(&lgInt[0], REGISTER_X);
    longIntegerFree(&lgInt[0]);
}

// ===========================================================================
// fnAlphaRR
// ===========================================================================
pub export fn fnAlphaRR(regist: u16) callconv(.c) void {
    var lgInt: longInteger_t = undefined;
    var real: real_t = undefined;
    var mod: real_t = undefined;

    if (getRegisterDataType(@intCast(regist)) != dtString) {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            _ = sprintf(errorMessage, "cannot use \x83\xb1RR on %s", getRegisterDataTypeName(@intCast(regist), true, false));
            moreInfoOnError("In function fnAlphaRR:", errorMessage);
        }
        return;
    }

    const stringGlyphLen: i16 = @intCast(stringGlyphLength(regString(@intCast(regist))));
    if (stringGlyphLen == 0) {
        displayCalcErrorMessage(ERROR_EMPTY_STRING, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            _ = sprintf(errorMessage, "cannot use \x83\xb1RR on an empty string");
            moreInfoOnError("In function fnAlphaRR:", errorMessage);
        }
        return;
    }

    longIntegerInit(&lgInt[0]);
    switch (getRegisterDataType(REGISTER_X)) {
        dtLongInteger => {
            convertLongIntegerRegisterToLongInteger(REGISTER_X, &lgInt[0]);
        },
        dtReal34 => {
            if (stringGlyphLen == 0) {
                lgInt[0]._mp_size = 0; // lgInt = 0
            } else {
                real34ToReal(reg34(REGISTER_X), &real);
                realSetPositiveSign(&real);
                int32ToReal(stringGlyphLen, &mod);
                WP34S_Mod(&real, &mod, &real, &ctxtReal39);
                convertRealToLongInteger(&real, &lgInt[0], DEC_ROUND_DOWN);
            }
        },
        dtShortInteger => {
            convertShortIntegerRegisterToLongInteger(REGISTER_X, &lgInt[0]);
        },
        else => {
            displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
            if (comptime extra_info) {
                _ = sprintf(errorMessage, "cannot \x83\xb1RR when X is %s", getRegisterDataTypeName(REGISTER_X, true, false));
                moreInfoOnError("In function fnAlphaRR:", errorMessage);
            }
            return;
        },
    }

    longIntegerSetPositiveSign(&lgInt[0]);
    var steps: i16 = @intCast(longIntegerModuloUInt(&lgInt[0], @intCast(stringGlyphLen)));
    longIntegerFree(&lgInt[0]);

    if (!saveLastX()) {
        return;
    }

    if (steps > 0) {
        var glyphPointer: i16 = 0;
        steps = stringGlyphLen - steps;
        while (steps > 0) : (steps -= 1) {
            glyphPointer = stringNextGlyph(regString(@intCast(regist)), glyphPointer);
        }

        const ptr: [*c]u8 = regString(@intCast(regist)) + @as(usize, @intCast(glyphPointer));
        steps = @intCast(stringByteLength(ptr) + 1);
        _ = xcopy(tmpString, ptr, @intCast(steps));
        ptr[0] = 0;
        copyRegisterStringTo(tmpString + @as(usize, @intCast(stringByteLength(tmpString))), @intCast(regist));
        _ = xcopy(regString(@intCast(regist)), tmpString, @intCast(stringByteLength(tmpString) + 1));
    }
}

// COPY_REGISTER_STRING_TO macro from registers.h.
inline fn copyRegisterStringTo(dest: [*c]u8, regist: calcRegister_t) void {
    const regData: ?*anyopaque = getRegisterDataPointer(regist);
    if (regData != null) {
        const regStr: [*c]u8 = @as([*c]u8, @ptrCast(regData.?)) + 4; // sizeof(strLgIntHeader_t)
        _ = xcopy(dest, regStr, @intCast(stringByteLength(regStr) + 1));
    }
}

// ===========================================================================
// fnAlphaRL
// ===========================================================================
pub export fn fnAlphaRL(regist: u16) callconv(.c) void {
    var lgInt: longInteger_t = undefined;
    var real: real_t = undefined;
    var mod: real_t = undefined;

    if (getRegisterDataType(@intCast(regist)) != dtString) {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            _ = sprintf(errorMessage, "cannot use \x83\xb1RL on %s", getRegisterDataTypeName(@intCast(regist), true, false));
            moreInfoOnError("In function fnAlphaRL:", errorMessage);
        }
        return;
    }

    const stringGlyphLen: i16 = @intCast(stringGlyphLength(regString(@intCast(regist))));
    if (stringGlyphLen == 0) {
        displayCalcErrorMessage(ERROR_EMPTY_STRING, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            _ = sprintf(errorMessage, "cannot use \x83\xb1RL on an empty string");
            moreInfoOnError("In function fnAlphaRL:", errorMessage);
        }
        return;
    }

    longIntegerInit(&lgInt[0]);
    switch (getRegisterDataType(REGISTER_X)) {
        dtLongInteger => {
            convertLongIntegerRegisterToLongInteger(REGISTER_X, &lgInt[0]);
        },
        dtReal34 => {
            if (stringGlyphLen == 0) {
                lgInt[0]._mp_size = 0; // lgInt = 0
            } else {
                real34ToReal(reg34(REGISTER_X), &real);
                realSetPositiveSign(&real);
                int32ToReal(stringGlyphLen, &mod);
                WP34S_Mod(&real, &mod, &real, &ctxtReal39);
                convertRealToLongInteger(&real, &lgInt[0], DEC_ROUND_DOWN);
            }
        },
        dtShortInteger => {
            convertShortIntegerRegisterToLongInteger(REGISTER_X, &lgInt[0]);
        },
        else => {
            displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
            if (comptime extra_info) {
                _ = sprintf(errorMessage, "cannot \x83\xb1RL when X is %s", getRegisterDataTypeName(REGISTER_X, true, false));
                moreInfoOnError("In function fnAlphaRL:", errorMessage);
            }
            return;
        },
    }

    longIntegerSetPositiveSign(&lgInt[0]);
    var steps: i16 = @intCast(longIntegerModuloUInt(&lgInt[0], @intCast(stringGlyphLen)));
    longIntegerFree(&lgInt[0]);

    if (!saveLastX()) {
        return;
    }

    if (steps > 0) {
        var glyphPointer: i16 = 0;
        while (steps > 0) : (steps -= 1) {
            glyphPointer = stringNextGlyph(regString(@intCast(regist)), glyphPointer);
        }

        const ptr: [*c]u8 = regString(@intCast(regist)) + @as(usize, @intCast(glyphPointer));
        steps = @intCast(stringByteLength(ptr) + 1);
        _ = xcopy(tmpString, ptr, @intCast(steps));
        ptr[0] = 0;
        copyRegisterStringTo(tmpString + @as(usize, @intCast(stringByteLength(tmpString))), @intCast(regist));
        _ = xcopy(regString(@intCast(regist)), tmpString, @intCast(stringByteLength(tmpString) + 1));
    }
}

// ===========================================================================
// fnAlphaSR
// ===========================================================================
pub export fn fnAlphaSR(regist: u16) callconv(.c) void {
    var lgInt: longInteger_t = undefined;

    if (getRegisterDataType(@intCast(regist)) != dtString) {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            _ = sprintf(errorMessage, "cannot use \x83\xb1SR on %s", getRegisterDataTypeName(@intCast(regist), true, false));
            moreInfoOnError("In function fnAlphaSR:", errorMessage);
        }
        return;
    }

    const stringGlyphLen: i16 = @intCast(stringGlyphLength(regString(@intCast(regist))));
    if (stringGlyphLen == 0) {
        displayCalcErrorMessage(ERROR_EMPTY_STRING, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            _ = sprintf(errorMessage, "cannot use \x83\xb1SR on an empty string");
            moreInfoOnError("In function fnAlphaSR:", errorMessage);
        }
        return;
    }

    longIntegerInit(&lgInt[0]);
    switch (getRegisterDataType(REGISTER_X)) {
        dtLongInteger => {
            convertLongIntegerRegisterToLongInteger(REGISTER_X, &lgInt[0]);
        },
        dtReal34 => {
            if (real34CompareAbsGreaterThan(reg34(REGISTER_X), cst34(OFF_const34_1e6))) {
                uInt32ToLongInteger(1000000, &lgInt[0]);
            } else {
                convertReal34ToLongInteger(reg34(REGISTER_X), &lgInt[0], DEC_ROUND_DOWN);
            }
        },
        dtShortInteger => {
            convertShortIntegerRegisterToLongInteger(REGISTER_X, &lgInt[0]);
        },
        else => {
            displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
            if (comptime extra_info) {
                _ = sprintf(errorMessage, "cannot \x83\xb1SR when X is %s", getRegisterDataTypeName(REGISTER_X, true, false));
                moreInfoOnError("In function fnAlphaSR:", errorMessage);
            }
            return;
        },
    }

    longIntegerSetPositiveSign(&lgInt[0]);
    if (longIntegerCompareInt(&lgInt[0], stringGlyphLen) >= 0) {
        int32ToLongInteger(stringGlyphLen, &lgInt[0]);
    }

    var steps: i16 = @truncate(@"__gmpz_get_si"(&lgInt[0])); // longIntegerToInt32
    longIntegerFree(&lgInt[0]);

    if (!saveLastX()) {
        return;
    }

    if (steps > 0) {
        var glyphPointer: i16 = 0;
        steps = stringGlyphLen - steps;
        while (steps > 0) : (steps -= 1) {
            glyphPointer = stringNextGlyph(regString(@intCast(regist)), glyphPointer);
        }

        (regString(@intCast(regist)) + @as(usize, @intCast(glyphPointer)))[0] = 0;
    }
}

// ===========================================================================
// fnAlphaSL
// ===========================================================================
pub export fn fnAlphaSL(regist: u16) callconv(.c) void {
    var lgInt: longInteger_t = undefined;

    if (getRegisterDataType(@intCast(regist)) != dtString) {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            _ = sprintf(errorMessage, "cannot use \x83\xb1SL on %s", getRegisterDataTypeName(@intCast(regist), true, false));
            moreInfoOnError("In function fnAlphaSL:", errorMessage);
        }
        return;
    }

    const ptr: [*c]u8 = regString(@intCast(regist));
    const stringGlyphLen: i16 = @intCast(stringGlyphLength(ptr));
    if (stringGlyphLen == 0) {
        displayCalcErrorMessage(ERROR_EMPTY_STRING, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            _ = sprintf(errorMessage, "cannot use \x83\xb1SL on an empty string");
            moreInfoOnError("In function fnAlphaSL:", errorMessage);
        }
        return;
    }

    longIntegerInit(&lgInt[0]);
    switch (getRegisterDataType(REGISTER_X)) {
        dtLongInteger => {
            convertLongIntegerRegisterToLongInteger(REGISTER_X, &lgInt[0]);
        },
        dtReal34 => {
            if (real34CompareAbsGreaterThan(reg34(REGISTER_X), cst34(OFF_const34_1e6))) {
                uInt32ToLongInteger(1000000, &lgInt[0]);
            } else {
                convertReal34ToLongInteger(reg34(REGISTER_X), &lgInt[0], DEC_ROUND_DOWN);
            }
        },
        dtShortInteger => {
            convertShortIntegerRegisterToLongInteger(REGISTER_X, &lgInt[0]);
        },
        else => {
            displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
            if (comptime extra_info) {
                _ = sprintf(errorMessage, "cannot \x83\xb1SL when X is %s", getRegisterDataTypeName(REGISTER_X, true, false));
                moreInfoOnError("In function fnAlphaSL:", errorMessage);
            }
            return;
        },
    }

    longIntegerSetPositiveSign(&lgInt[0]);
    if (longIntegerCompareInt(&lgInt[0], stringGlyphLen) >= 0) {
        int32ToLongInteger(stringGlyphLen, &lgInt[0]);
    }

    var steps: i16 = @truncate(@"__gmpz_get_si"(&lgInt[0])); // longIntegerToInt32
    longIntegerFree(&lgInt[0]);

    if (!saveLastX()) {
        return;
    }

    if (steps > 0) {
        var glyphPointer: i16 = 0;
        while (steps > 0) : (steps -= 1) {
            glyphPointer = stringNextGlyph(ptr, glyphPointer);
        }

        _ = xcopy(ptr, ptr + @as(usize, @intCast(glyphPointer)), @intCast(stringByteLength(ptr + @as(usize, @intCast(glyphPointer))) + 1));
    }
}

// ===========================================================================
// HP-42S alpha-register operations (real master). These run against the
// dedicated alphaRegister (c47.c global) and, for now, are additive exports
// that the pinned testSuite never reaches (no items.c dispatch yet).
// ===========================================================================
extern var alphaRegister: u16;

// Truncate the alpha register's string to the 42S 44-glyph maximum.
pub export fn truncateAlphaRegisterTo44Char() callconv(.c) void {
    const ptr = regString(@intCast(alphaRegister));
    const stringGlyphLen = stringGlyphLength(ptr);
    if (stringGlyphLen <= 44) {
        return;
    }
    var steps: i16 = @intCast(stringGlyphLen - 44);
    var glyphPointer: i16 = 0;
    while (steps > 0) : (steps -= 1) {
        glyphPointer = stringNextGlyph(ptr, glyphPointer);
    }
    _ = xcopy(ptr, ptr + @as(usize, @intCast(glyphPointer)), @intCast(stringByteLength(ptr + @as(usize, @intCast(glyphPointer))) + 1));
}

// 42S thin wrappers over the existing 47-native alpha operations.
pub export fn fn42Aleng(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    fnAlphaLeng(alphaRegister);
}

pub export fn fn42Atox(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    fnAlphaToX(alphaRegister);
}

pub export fn fn42Posa(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    fnAlphaPos(alphaRegister);
}
