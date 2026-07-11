// SPDX-License-Identifier: GPL-3.0-only
const consts = abi.constants;
const const34_1e6 = consts.const34_1e6;
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

const std = @import("std");
const frontier_build_options = @import("frontier_build_options");
const extra_info: bool = frontier_build_options.extra_info_on_calc_error;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const DECNUMUNITS = 25;
const abi = @import("abi"); // L1 shared bindings (REPORT-23 §5)
const frontier = @import("frontier.zig"); // M-callconv: Zig-to-Zig
const frontier_addons = @import("frontier_addons.zig"); // M-callconv: Zig-to-Zig
const frontier_char_string = @import("frontier_char_string.zig"); // M-callconv: Zig-to-Zig
const glyph_case = @import("glyph_case.zig"); // std-only glyph codec + case map
const alpha_substring = @import("alpha_substring.zig"); // std-only ALPHAMID substring
fn substringPosition(haystack: [*c]const u8, hay_len: i16, needle: [*c]const u8, needle_len: i16) i16 {
    var i: i16 = 0;
    while (i <= hay_len - needle_len) : (i += 1) {
        var found = true;
        var j: i16 = 0;
        while (j < needle_len) : (j += 1) {
            if (haystack[@intCast(i + j)] != needle[@intCast(j)]) {
                found = false;
                break;
            }
        }
        if (found) return i;
    }
    return -1;
}
const frontier_debug = @import("frontier_debug.zig"); // M-callconv: Zig-to-Zig
const frontier_display = @import("frontier_display.zig"); // M-callconv: Zig-to-Zig
const frontier_error = @import("frontier_error.zig"); // M-callconv: Zig-to-Zig
const frontier_register_value_conversions = @import("frontier_register_value_conversions.zig"); // M-callconv: Zig-to-Zig
const frontier_store = @import("frontier_store.zig"); // M-callconv: Zig-to-Zig
const real_t = abi.Real;
const real34_t = abi.Real34;
const realContext_t = abi.RealContext;
const calcRegister_t = i16;

// GMP mpz_struct. Limb width == pointer width on every target z47 builds
// (64-bit on Linux and Win64, 32-bit on ARM32 firmware). NOT c_ulong: Win64
// is LLP64 where `unsigned long` is 32-bit yet GMP limbs are 64-bit.
const mp_limb_t = usize;
const mpz_struct = abi.Mpz;
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
const c_moreInfoOnError = @extern(*const fn (m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) callconv(.c) void, .{ .name = "moreInfoOnError" });
extern fn sprintf(buf: [*c]u8, fmt: [*:0]const u8, ...) c_int;
extern fn strlen(str: [*c]const u8) usize;
extern fn liftStack() void;
extern fn saveLastX() bool;
extern fn fnSwapX(regist: u16) void;
extern fn elementwiseRema_UInt16(f: ?*const fn (u16) callconv(.c) void, param: u16) void;
extern fn getSystemFlag(flag: c_int) bool;
extern fn reallocateRegister(regist: calcRegister_t, data_type: u32, size_blocks: u16, tag: u32) void;
extern fn WP34S_Mod(x: *const real_t, y: *align(1) const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn real34CompareAbsGreaterThan(number1: *align(1) const real34_t, number2: *align(1) const real34_t) bool;
extern fn decimal128ToNumber(src: *align(1) const real34_t, dst: *real_t) *real_t;
extern fn decNumberFromInt32(r: *real_t, v: i32) *real_t;

// Converters exported by the registerValueConversions owner.

// ---------------------------------------------------------------------------
// GMP externs (mpz_* are header macros; the linkable symbols are __gmpz_*)
// ---------------------------------------------------------------------------
extern fn __gmpz_init(p: *mpz_struct) void;
extern fn __gmpz_clear(p: *mpz_struct) void;
extern fn __gmpz_set_ui(p: *mpz_struct, v: c_ulong) void;
extern fn __gmpz_set_si(p: *mpz_struct, v: c_long) void;
extern fn __gmpz_add_ui(r: *mpz_struct, op: *const mpz_struct, c: c_ulong) void;
extern fn __gmpz_mul_ui(r: *mpz_struct, op: *const mpz_struct, c: c_ulong) void;
extern fn __gmpz_fdiv_ui(op: *const mpz_struct, c: c_ulong) c_ulong;
extern fn __gmpz_cmp_ui(op: *const mpz_struct, c: c_ulong) c_int;
extern fn __gmpz_cmp_si(op: *const mpz_struct, c: c_long) c_int;
extern fn __gmpz_get_si(op: *const mpz_struct) c_long;

// ---------------------------------------------------------------------------
// Inline wrappers (the C macros / static inlines)
// ---------------------------------------------------------------------------
inline fn moreInfoOnError(m1: [*:0]const u8, m2: ?[*:0]const u8) void {
    if (comptime extra_info) c_moreInfoOnError(m1, m2, null, null);
}
const regString = abi.registerString;
const reg34 = abi.registerReal34;
inline fn getStackTop() calcRegister_t {
    return if (getSystemFlag(FLAG_SSIZE8)) REGISTER_D else REGISTER_T;
}
inline fn stringByteLength(str: [*c]const u8) i32 {
    return @intCast(strlen(str));
}
inline fn longIntegerInit(lg: *mpz_struct) void {
    __gmpz_init(lg);
}
inline fn longIntegerFree(lg: *mpz_struct) void {
    __gmpz_clear(lg);
}
inline fn uInt32ToLongInteger(source: u32, destination: *mpz_struct) void {
    __gmpz_set_ui(destination, source);
}
inline fn int32ToLongInteger(source: i32, destination: *mpz_struct) void {
    __gmpz_set_si(destination, source);
}
inline fn longIntegerAddUInt(op: *const mpz_struct, uint: u32, result: *mpz_struct) void {
    __gmpz_add_ui(result, op, uint);
}
inline fn longIntegerMultiplyUInt(op: *const mpz_struct, uint: u32, result: *mpz_struct) void {
    __gmpz_mul_ui(result, op, uint);
}
inline fn longIntegerModuloUInt(op: *const mpz_struct, uint: u32) u32 {
    return @truncate(__gmpz_fdiv_ui(op, uint));
}
inline fn longIntegerCompareUInt(op: *const mpz_struct, uint: u32) i32 {
    return __gmpz_cmp_ui(op, uint);
}
inline fn longIntegerCompareInt(op: *const mpz_struct, sint: i32) i32 {
    return __gmpz_cmp_si(op, sint);
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
        var n: usize = 0;
        while (stringToTrim[n] != 0) : (n += 1) {}
        var i: usize = 0;
        while (i < n) : (i += 1) stringToTrim[i] = stringToTrim[i + 1];
    }
}

// ===========================================================================
// fnAlphaLeng
// ===========================================================================
pub export fn fnAlphaLeng(regist: u16) callconv(.c) void {
    var stringSize: longInteger_t = undefined;

    if (getRegisterDataType(@intCast(regist)) != dtString) {
        frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "cannot get the \x83\xb1LENG? from {s}", .{std.mem.span(frontier_debug.getRegisterDataTypeName(@intCast(regist), true, false))});
            moreInfoOnError("In function fnAlphaLeng:", errorMessage);
        }
        return;
    }

    longIntegerInit(&stringSize[0]);
    int32ToLongInteger(frontier_char_string.stringGlyphLength(regString(@intCast(regist))), &stringSize[0]);

    liftStack();

    frontier_register_value_conversions.convertLongIntegerToLongIntegerRegister(&stringSize[0], REGISTER_X);
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
        frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "cannot use \x83\xb1\xa1\x92x on {s}", .{std.mem.span(frontier_debug.getRegisterDataTypeName(@intCast(regist), true, false))});
            moreInfoOnError("In function fnAlphaToX:", errorMessage);
        }
        return;
    }

    if (stringByteLength(regString(@intCast(regist))) == 0) {
        frontier_error.displayCalcErrorMessage(ERROR_EMPTY_STRING, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "cannot use \x83\xb1\xa1\x92x on an empty string", .{});
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

    frontier_register_value_conversions.convertLongIntegerToShortIntegerRegister(&lgInt[0], 16, REGISTER_X);
    longIntegerFree(&lgInt[0]);

    if (!getSystemFlag(FLAG_ASLIFT) or regist != @as(u16, @intCast(getStackTop()))) {
        if (@as(u16, @intCast(REGISTER_X)) <= regist and regist < @as(u16, @intCast(getStackTop()))) {
            regist += 1;
        }
        const skip: u16 = if ((char1 & 0x80) != 0) 2 else 1;
        _ = frontier_char_string.xcopy(regString(@intCast(regist)), regString(@intCast(regist)) + skip, @intCast(stringByteLength(regString(@intCast(regist)) + skip) + 1));
    }
}

// ===========================================================================
// fnXToAlpha
// ===========================================================================
pub export fn fnXToAlpha(regist: u16) callconv(.c) void { // new version, similar to the hp-42s ATOX function
    if (!saveLastX()) {
        return;
    }

    switch (getRegisterDataType(REGISTER_X)) {
        dtLongInteger, dtReal34, dtShortInteger => {
            _doXToAlpha(regist);
            return;
        },
        dtString => {
            _readDestinationRegister(regist);
            if (frontier_char_string.stringGlyphLength(tmpString) + frontier_char_string.stringGlyphLength(regString(REGISTER_X)) > MAX_NUMBER_OF_GLYPHS_IN_STRING) {
                frontier_error.displayCalcErrorMessage(ERROR_STRING_WOULD_BE_TOO_LONG, ERR_REGISTER_LINE, REGISTER_X);
                if (comptime extra_info) {
                    abi.fmtBufZ(errorMessage[0..512], "the resulting string would be {d} ({d} + {d}) characters long. Maximum is {d}", .{ frontier_char_string.stringGlyphLength(tmpString) + frontier_char_string.stringGlyphLength(regString(REGISTER_X)), frontier_char_string.stringGlyphLength(tmpString), frontier_char_string.stringGlyphLength(regString(REGISTER_X)), MAX_NUMBER_OF_GLYPHS_IN_STRING });
                    moreInfoOnError("In function fnXToAlpha:", errorMessage);
                }
            } else {
                var l: i32 = stringByteLength(tmpString);
                _ = frontier_char_string.xcopy(tmpString + @as(usize, @intCast(l)), regString(REGISTER_X), @intCast(stringByteLength(regString(REGISTER_X)) + 1));
                l = stringByteLength(tmpString);
                reallocateRegister(@intCast(regist), dtString, @intCast(l + 1), amNone);
                _ = frontier_char_string.xcopy(regString(@intCast(regist)), tmpString, @intCast(l + 1));
            }
            return;
        },
        dtReal34Matrix => {
            if (regist != REGISTER_X) {
                elementwiseRema_UInt16(&_doXToAlpha, regist);
            } else { // X is the destination: return in X a string of the character codes from the matrix in X
                reallocateRegister(REGISTER_L, dtString, 1, amNone);
                _ = frontier_char_string.xcopy(regString(REGISTER_L), "", 1);
                elementwiseRema_UInt16(&_doXToAlpha, @intCast(REGISTER_L));
                fnSwapX(REGISTER_L);
            }
            return;
        },
        else => {
            frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
            if (comptime extra_info) {
                abi.fmtBufZ(errorMessage[0..512], "cannot x\xa1\x92\x83\xb1 when X is {s}", .{std.mem.span(frontier_debug.getRegisterDataTypeName(REGISTER_X, true, false))});
                moreInfoOnError("In function fnXToAlpha:", errorMessage);
            }
            return;
        },
    }
}

// fnXToAlphaOld (deprecated x→α, items opcode XtoALPHA_OLD=1645) —
// master fd83b4a4 kept the old behaviour under this name (identical to the
// historical fnXToAlpha body above). The NEW master fnXToAlpha (ATOX) is a
// separate deferred port; until then opcode 2785 also runs the old logic.
pub export fn fnXToAlphaOld(unusedButMandatoryParameter: u16) callconv(.c) void { // deprecated version, backward compatibility only
    _ = unusedButMandatoryParameter;
    var lgInt: longInteger_t = undefined;
    var char1: u8 = undefined;
    var char2: u8 = undefined;

    longIntegerInit(&lgInt[0]);
    switch (getRegisterDataType(REGISTER_X)) {
        dtLongInteger => {
            // The register converter re-initializes lgInt itself (matches the C).
            frontier_register_value_conversions.convertLongIntegerRegisterToLongInteger(REGISTER_X, &lgInt[0]);
        },
        dtReal34 => {
            if (real34CompareAbsGreaterThan(reg34(REGISTER_X), const34_1e6())) {
                uInt32ToLongInteger(1000000, &lgInt[0]);
            } else {
                frontier_register_value_conversions.convertReal34ToLongInteger(reg34(REGISTER_X), &lgInt[0], DEC_ROUND_DOWN);
            }
        },
        dtShortInteger => {
            frontier_register_value_conversions.convertShortIntegerRegisterToLongInteger(REGISTER_X, &lgInt[0]);
        },
        else => {
            frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
            if (comptime extra_info) {
                abi.fmtBufZ(errorMessage[0..512], "cannot x\xa1\x92\x83\xb1 when X is {s}", .{std.mem.span(frontier_debug.getRegisterDataTypeName(REGISTER_X, true, false))});
                moreInfoOnError("In function fnXToAlpha:", errorMessage);
            }
            return;
        },
    }

    longIntegerSetPositiveSign(&lgInt[0]);
    if (longIntegerCompareUInt(&lgInt[0], 0x8000) >= 0) {
        frontier_error.displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "for x\xa1\x92\x83\xb1, X must be < 32768. Here X = {d}", .{@as(u32, @truncate(lgInt[0]._mp_d[0]))}); // OK for 32 and 64 bit limbs
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
        frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "cannot use \x83\xb1POS? on {s} (reg {d})", .{ std.mem.span(frontier_debug.getRegisterDataTypeName(@intCast(regist), true, false)), @as(c_uint, regist) });
            moreInfoOnError("In function fnAlphaPos:", errorMessage);
        }
        return;
    }

    if (getRegisterDataType(REGISTER_X) != dtString) {
        frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "cannot use \x83\xb1POS? on {s} (reg X)", .{std.mem.span(frontier_debug.getRegisterDataTypeName(@intCast(regist), true, false))});
            moreInfoOnError("In function fnAlphaPos:", errorMessage);
        }
        return;
    }

    if (frontier_char_string.stringGlyphLength(regString(@intCast(regist))) == 0 or frontier_char_string.stringGlyphLength(regString(REGISTER_X)) == 0) {
        frontier_error.displayCalcErrorMessage(ERROR_EMPTY_STRING, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "cannot use \x83\xb1POS? on or with an empty string", .{});
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

    int32ToLongInteger(substringPosition(ptrRegist, lgRegist, ptrTarget, lgTarget), &lgInt[0]);

    liftStack();
    frontier_register_value_conversions.convertLongIntegerToLongIntegerRegister(&lgInt[0], REGISTER_X);
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
        frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "cannot use \x83\xb1RR on {s}", .{std.mem.span(frontier_debug.getRegisterDataTypeName(@intCast(regist), true, false))});
            moreInfoOnError("In function fnAlphaRR:", errorMessage);
        }
        return;
    }

    const stringGlyphLen: i16 = @intCast(frontier_char_string.stringGlyphLength(regString(@intCast(regist))));
    if (stringGlyphLen == 0) {
        frontier_error.displayCalcErrorMessage(ERROR_EMPTY_STRING, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "cannot use \x83\xb1RR on an empty string", .{});
            moreInfoOnError("In function fnAlphaRR:", errorMessage);
        }
        return;
    }

    longIntegerInit(&lgInt[0]);
    switch (getRegisterDataType(REGISTER_X)) {
        dtLongInteger => {
            frontier_register_value_conversions.convertLongIntegerRegisterToLongInteger(REGISTER_X, &lgInt[0]);
        },
        dtReal34 => {
            if (stringGlyphLen == 0) {
                lgInt[0]._mp_size = 0; // lgInt = 0
            } else {
                real34ToReal(reg34(REGISTER_X), &real);
                realSetPositiveSign(&real);
                int32ToReal(stringGlyphLen, &mod);
                WP34S_Mod(&real, &mod, &real, &ctxtReal39);
                frontier_register_value_conversions.convertRealToLongInteger(&real, &lgInt[0], DEC_ROUND_DOWN);
            }
        },
        dtShortInteger => {
            frontier_register_value_conversions.convertShortIntegerRegisterToLongInteger(REGISTER_X, &lgInt[0]);
        },
        else => {
            frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
            if (comptime extra_info) {
                abi.fmtBufZ(errorMessage[0..512], "cannot \x83\xb1RR when X is {s}", .{std.mem.span(frontier_debug.getRegisterDataTypeName(REGISTER_X, true, false))});
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
            glyphPointer = frontier_char_string.stringNextGlyph(regString(@intCast(regist)), glyphPointer);
        }

        const ptr: [*c]u8 = regString(@intCast(regist)) + @as(usize, @intCast(glyphPointer));
        steps = @intCast(stringByteLength(ptr) + 1);
        _ = frontier_char_string.xcopy(tmpString, ptr, @intCast(steps));
        ptr[0] = 0;
        copyRegisterStringTo(tmpString + @as(usize, @intCast(stringByteLength(tmpString))), @intCast(regist));
        _ = frontier_char_string.xcopy(regString(@intCast(regist)), tmpString, @intCast(stringByteLength(tmpString) + 1));
    }
}

// COPY_REGISTER_STRING_TO macro from registers.h.
inline fn copyRegisterStringTo(dest: [*c]u8, regist: calcRegister_t) void {
    const regData: ?*anyopaque = getRegisterDataPointer(regist);
    if (regData != null) {
        const regStr: [*c]u8 = @as([*c]u8, @ptrCast(regData.?)) + 4; // sizeof(strLgIntHeader_t)
        _ = frontier_char_string.xcopy(dest, regStr, @intCast(stringByteLength(regStr) + 1));
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
        frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "cannot use \x83\xb1RL on {s}", .{std.mem.span(frontier_debug.getRegisterDataTypeName(@intCast(regist), true, false))});
            moreInfoOnError("In function fnAlphaRL:", errorMessage);
        }
        return;
    }

    const stringGlyphLen: i16 = @intCast(frontier_char_string.stringGlyphLength(regString(@intCast(regist))));
    if (stringGlyphLen == 0) {
        frontier_error.displayCalcErrorMessage(ERROR_EMPTY_STRING, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "cannot use \x83\xb1RL on an empty string", .{});
            moreInfoOnError("In function fnAlphaRL:", errorMessage);
        }
        return;
    }

    longIntegerInit(&lgInt[0]);
    switch (getRegisterDataType(REGISTER_X)) {
        dtLongInteger => {
            frontier_register_value_conversions.convertLongIntegerRegisterToLongInteger(REGISTER_X, &lgInt[0]);
        },
        dtReal34 => {
            if (stringGlyphLen == 0) {
                lgInt[0]._mp_size = 0; // lgInt = 0
            } else {
                real34ToReal(reg34(REGISTER_X), &real);
                realSetPositiveSign(&real);
                int32ToReal(stringGlyphLen, &mod);
                WP34S_Mod(&real, &mod, &real, &ctxtReal39);
                frontier_register_value_conversions.convertRealToLongInteger(&real, &lgInt[0], DEC_ROUND_DOWN);
            }
        },
        dtShortInteger => {
            frontier_register_value_conversions.convertShortIntegerRegisterToLongInteger(REGISTER_X, &lgInt[0]);
        },
        else => {
            frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
            if (comptime extra_info) {
                abi.fmtBufZ(errorMessage[0..512], "cannot \x83\xb1RL when X is {s}", .{std.mem.span(frontier_debug.getRegisterDataTypeName(REGISTER_X, true, false))});
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
            glyphPointer = frontier_char_string.stringNextGlyph(regString(@intCast(regist)), glyphPointer);
        }

        const ptr: [*c]u8 = regString(@intCast(regist)) + @as(usize, @intCast(glyphPointer));
        steps = @intCast(stringByteLength(ptr) + 1);
        _ = frontier_char_string.xcopy(tmpString, ptr, @intCast(steps));
        ptr[0] = 0;
        copyRegisterStringTo(tmpString + @as(usize, @intCast(stringByteLength(tmpString))), @intCast(regist));
        _ = frontier_char_string.xcopy(regString(@intCast(regist)), tmpString, @intCast(stringByteLength(tmpString) + 1));
    }
}

// ===========================================================================
// fnAlphaSR
// ===========================================================================
pub export fn fnAlphaSR(regist: u16) callconv(.c) void {
    var lgInt: longInteger_t = undefined;

    if (getRegisterDataType(@intCast(regist)) != dtString) {
        frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "cannot use \x83\xb1SR on {s}", .{std.mem.span(frontier_debug.getRegisterDataTypeName(@intCast(regist), true, false))});
            moreInfoOnError("In function fnAlphaSR:", errorMessage);
        }
        return;
    }

    const stringGlyphLen: i16 = @intCast(frontier_char_string.stringGlyphLength(regString(@intCast(regist))));
    if (stringGlyphLen == 0) {
        frontier_error.displayCalcErrorMessage(ERROR_EMPTY_STRING, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "cannot use \x83\xb1SR on an empty string", .{});
            moreInfoOnError("In function fnAlphaSR:", errorMessage);
        }
        return;
    }

    longIntegerInit(&lgInt[0]);
    switch (getRegisterDataType(REGISTER_X)) {
        dtLongInteger => {
            frontier_register_value_conversions.convertLongIntegerRegisterToLongInteger(REGISTER_X, &lgInt[0]);
        },
        dtReal34 => {
            if (real34CompareAbsGreaterThan(reg34(REGISTER_X), const34_1e6())) {
                uInt32ToLongInteger(1000000, &lgInt[0]);
            } else {
                frontier_register_value_conversions.convertReal34ToLongInteger(reg34(REGISTER_X), &lgInt[0], DEC_ROUND_DOWN);
            }
        },
        dtShortInteger => {
            frontier_register_value_conversions.convertShortIntegerRegisterToLongInteger(REGISTER_X, &lgInt[0]);
        },
        else => {
            frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
            if (comptime extra_info) {
                abi.fmtBufZ(errorMessage[0..512], "cannot \x83\xb1SR when X is {s}", .{std.mem.span(frontier_debug.getRegisterDataTypeName(REGISTER_X, true, false))});
                moreInfoOnError("In function fnAlphaSR:", errorMessage);
            }
            return;
        },
    }

    longIntegerSetPositiveSign(&lgInt[0]);
    if (longIntegerCompareInt(&lgInt[0], stringGlyphLen) >= 0) {
        int32ToLongInteger(stringGlyphLen, &lgInt[0]);
    }

    var steps: i16 = @truncate(__gmpz_get_si(&lgInt[0])); // longIntegerToInt32
    longIntegerFree(&lgInt[0]);

    if (!saveLastX()) {
        return;
    }

    if (steps > 0) {
        var glyphPointer: i16 = 0;
        steps = stringGlyphLen - steps;
        while (steps > 0) : (steps -= 1) {
            glyphPointer = frontier_char_string.stringNextGlyph(regString(@intCast(regist)), glyphPointer);
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
        frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "cannot use \x83\xb1SL on {s}", .{std.mem.span(frontier_debug.getRegisterDataTypeName(@intCast(regist), true, false))});
            moreInfoOnError("In function fnAlphaSL:", errorMessage);
        }
        return;
    }

    const ptr: [*c]u8 = regString(@intCast(regist));
    const stringGlyphLen: i16 = @intCast(frontier_char_string.stringGlyphLength(ptr));
    if (stringGlyphLen == 0) {
        frontier_error.displayCalcErrorMessage(ERROR_EMPTY_STRING, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "cannot use \x83\xb1SL on an empty string", .{});
            moreInfoOnError("In function fnAlphaSL:", errorMessage);
        }
        return;
    }

    longIntegerInit(&lgInt[0]);
    switch (getRegisterDataType(REGISTER_X)) {
        dtLongInteger => {
            frontier_register_value_conversions.convertLongIntegerRegisterToLongInteger(REGISTER_X, &lgInt[0]);
        },
        dtReal34 => {
            if (real34CompareAbsGreaterThan(reg34(REGISTER_X), const34_1e6())) {
                uInt32ToLongInteger(1000000, &lgInt[0]);
            } else {
                frontier_register_value_conversions.convertReal34ToLongInteger(reg34(REGISTER_X), &lgInt[0], DEC_ROUND_DOWN);
            }
        },
        dtShortInteger => {
            frontier_register_value_conversions.convertShortIntegerRegisterToLongInteger(REGISTER_X, &lgInt[0]);
        },
        else => {
            frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
            if (comptime extra_info) {
                abi.fmtBufZ(errorMessage[0..512], "cannot \x83\xb1SL when X is {s}", .{std.mem.span(frontier_debug.getRegisterDataTypeName(REGISTER_X, true, false))});
                moreInfoOnError("In function fnAlphaSL:", errorMessage);
            }
            return;
        },
    }

    longIntegerSetPositiveSign(&lgInt[0]);
    if (longIntegerCompareInt(&lgInt[0], stringGlyphLen) >= 0) {
        int32ToLongInteger(stringGlyphLen, &lgInt[0]);
    }

    var steps: i16 = @truncate(__gmpz_get_si(&lgInt[0])); // longIntegerToInt32
    longIntegerFree(&lgInt[0]);

    if (!saveLastX()) {
        return;
    }

    if (steps > 0) {
        var glyphPointer: i16 = 0;
        while (steps > 0) : (steps -= 1) {
            glyphPointer = frontier_char_string.stringNextGlyph(ptr, glyphPointer);
        }

        _ = frontier_char_string.xcopy(ptr, ptr + @as(usize, @intCast(glyphPointer)), @intCast(stringByteLength(ptr + @as(usize, @intCast(glyphPointer))) + 1));
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
    const stringGlyphLen = frontier_char_string.stringGlyphLength(ptr);
    if (stringGlyphLen <= 44) {
        return;
    }
    var steps: i16 = @intCast(stringGlyphLen - 44);
    var glyphPointer: i16 = 0;
    while (steps > 0) : (steps -= 1) {
        glyphPointer = frontier_char_string.stringNextGlyph(ptr, glyphPointer);
    }
    _ = frontier_char_string.xcopy(ptr, ptr + @as(usize, @intCast(glyphPointer)), @intCast(stringByteLength(ptr + @as(usize, @intCast(glyphPointer))) + 1));
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

// Raised by the 42S alpha ops when the alpha register holds no string (slot 64).
const ERROR_NO_STRING_IN_ALPHA_REGISTER: u8 = 64;

// 42ASHF: shift the alpha register left by up to 6 glyphs.
pub export fn fn42AlphaShift(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (getRegisterDataType(@intCast(alphaRegister)) != dtString) {
        frontier_error.displayCalcErrorMessage(ERROR_NO_STRING_IN_ALPHA_REGISTER, ERR_REGISTER_LINE, REGISTER_T);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "cannot use 42ASHF on {s}", .{std.mem.span(frontier_debug.getRegisterDataTypeName(@intCast(alphaRegister), true, false))});
            moreInfoOnError("In function fn42AlphaShift:", errorMessage);
        }
        return;
    }

    const ptr = regString(@intCast(alphaRegister));
    const stringGlyphLen = frontier_char_string.stringGlyphLength(ptr);
    var steps: i16 = if (stringGlyphLen < 6) @intCast(stringGlyphLen) else 6;
    var glyphPointer: i16 = 0;
    while (steps > 0) : (steps -= 1) {
        glyphPointer = frontier_char_string.stringNextGlyph(ptr, glyphPointer);
    }
    _ = frontier_char_string.xcopy(ptr, ptr + @as(usize, @intCast(glyphPointer)), @intCast(stringByteLength(ptr + @as(usize, @intCast(glyphPointer))) + 1));
}

// 42XTOA: X -> alpha register (clamped to 44 glyphs).
pub export fn fn42Xtoa(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    fnXToAlpha(alphaRegister);
    truncateAlphaRegisterTo44Char();
}

inline fn longIntegerIsNegative(lg: *const mpz_struct) bool {
    return lg._mp_size < 0;
}

// 42AROT: rotate the alpha register by X glyphs; the sign of X picks the direction.
pub export fn fn42AlphaRotate(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (getRegisterDataType(@intCast(alphaRegister)) != dtString) {
        frontier_error.displayCalcErrorMessage(ERROR_NO_STRING_IN_ALPHA_REGISTER, ERR_REGISTER_LINE, REGISTER_T);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "cannot use 42AROT on {s}", .{std.mem.span(frontier_debug.getRegisterDataTypeName(@intCast(alphaRegister), true, false))});
            moreInfoOnError("In function fn42AlphaRotate:", errorMessage);
        }
        return;
    }

    var lgInt: longInteger_t = undefined;
    longIntegerInit(&lgInt[0]);
    switch (getRegisterDataType(REGISTER_X)) {
        dtLongInteger => frontier_register_value_conversions.convertLongIntegerRegisterToLongInteger(REGISTER_X, &lgInt[0]),
        dtReal34 => frontier_register_value_conversions.convertReal34ToLongInteger(reg34(REGISTER_X), &lgInt[0], DEC_ROUND_DOWN),
        dtShortInteger => frontier_register_value_conversions.convertShortIntegerRegisterToLongInteger(REGISTER_X, &lgInt[0]),
        else => {
            frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
            if (comptime extra_info) {
                abi.fmtBufZ(errorMessage[0..512], "cannot 42AROT when X is {s}", .{std.mem.span(frontier_debug.getRegisterDataTypeName(REGISTER_X, true, false))});
                moreInfoOnError("In function fn42AlphaRotate:", errorMessage);
            }
            longIntegerFree(&lgInt[0]);
            return;
        },
    }
    if (longIntegerIsNegative(&lgInt[0])) {
        fnAlphaRR(alphaRegister);
    } else {
        fnAlphaRL(alphaRegister);
    }
    longIntegerFree(&lgInt[0]);
}

// fnClearAlpha (new in real master): reset a register to an empty string.
pub export fn fnClearAlpha(regist: u16) callconv(.c) void {
    reallocateRegister(@intCast(regist), dtString, 1, amNone);
    regString(@intCast(regist))[0] = 0;
}

// 42CLA: clear the alpha register.
pub export fn fn42Cla(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    fnClearAlpha(alphaRegister);
}

// Cross-owner callees for the remaining 42S wrappers (display/print/items globals).
extern var lastFunc: i16;
const ITM_AVIEW: i16 = 2018;
const ITM_PROMPT: i16 = 2020;

// 42AVIEW: view the alpha register.
pub export fn fn42Aview(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    lastFunc = ITM_AVIEW;
    frontier_display.fnAview(alphaRegister);
}

// 42PRA: print the alpha register.
pub export fn fn42Pra(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    frontier.fnP_Alpha(alphaRegister);
}

// 42PROMPT: prompt with the alpha register.
pub export fn fn42Prompt(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    lastFunc = ITM_PROMPT;
    frontier_display.fnPrompt(alphaRegister);
}

// Cross-owner deps for fn42Alpha/fn42Append (program state, alpha source buffers, store).
extern var programRunStop: u8;
const PGM_RUNNING: u8 = 1;
extern var aimBuffer: [*c]u8;
extern var tmpStringLabelOrVariableName: [*c]u8;
extern fn copySourceRegisterToDestRegister(source_register: calcRegister_t, dest_register: calcRegister_t) void;
const LAST_TEMP_REGISTER: calcRegister_t = 136;
inline fn TO_BLOCKS(n: u32) u16 {
    return @intCast((n + 3) >> 2); // BYTES_PER_BLOCK = 4
}

// 42ALPHA: store the alpha entry/label string into the alpha register.
pub export fn fn42Alpha(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    const alphaString: [*c]u8 = if (programRunStop == PGM_RUNNING) tmpStringLabelOrVariableName else aimBuffer;
    reallocateRegister(@intCast(alphaRegister), dtString, TO_BLOCKS(@intCast(stringByteLength(alphaString) + 1)), amNone);
    _ = frontier_char_string.xcopy(regString(@intCast(alphaRegister)), alphaString, @intCast(stringByteLength(alphaString) + 1));
}

// 42APPEND: append the alpha entry string to the alpha register (clamped to 44).
pub export fn fn42Append(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    const alphaString: [*c]u8 = if (programRunStop == PGM_RUNNING) tmpStringLabelOrVariableName else aimBuffer;
    copySourceRegisterToDestRegister(REGISTER_X, LAST_TEMP_REGISTER);
    reallocateRegister(REGISTER_X, dtString, TO_BLOCKS(@intCast(stringByteLength(alphaString) + 1)), amNone);
    _ = frontier_char_string.xcopy(regString(REGISTER_X), alphaString, @intCast(stringByteLength(alphaString) + 1));
    frontier_store.fnStoreAdd(alphaRegister);
    truncateAlphaRegisterTo44Char();
    copySourceRegisterToDestRegister(LAST_TEMP_REGISTER, REGISTER_X);
}

// Deps for fnAlphaIP (the alpha integer-part helper).
const REGISTER_Y: calcRegister_t = 101;
const REGISTER_L: calcRegister_t = 108;
const SAVED_REGISTER_X: calcRegister_t = 126;
const SAVED_REGISTER_Y: calcRegister_t = 127;
const SAVED_REGISTER_L: calcRegister_t = 134;
const ERROR_NONE: u8 = 0;
const NOPARAM: u16 = 9876;
const NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS = 10;
const Fn0 = ?*const fn () callconv(.c) void;
extern var lastErrorCode: u8;
extern var grpGroupingLeft: u8;
extern const addition: [NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS]Fn0;
extern fn integerPartReal(mode: c_int) void;

// fnAlphaIP (new in real master): append the integer part of X to a register as a string.
pub export fn fnAlphaIP(regist: u16) callconv(.c) void {
    const regC: calcRegister_t = @intCast(regist);

    if (programRunStop == PGM_RUNNING) {
        copySourceRegisterToDestRegister(REGISTER_Y, SAVED_REGISTER_Y);
        copySourceRegisterToDestRegister(REGISTER_X, SAVED_REGISTER_X);
        copySourceRegisterToDestRegister(REGISTER_L, SAVED_REGISTER_L);
    }

    switch (getRegisterDataType(REGISTER_X)) {
        dtShortInteger => frontier_register_value_conversions.convertShortIntegerRegisterToLongIntegerRegister(REGISTER_X, REGISTER_X),
        dtReal34 => {
            integerPartReal(DEC_ROUND_DOWN);
            frontier_addons.fnJM_2SI(NOPARAM);
        },
        dtLongInteger => {},
        else => {
            frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
            if (comptime extra_info) {
                abi.fmtBufZ(errorMessage[0..512], "cannot \x83\xb1IP when X is {s}", .{std.mem.span(frontier_debug.getRegisterDataTypeName(REGISTER_X, true, false))});
                moreInfoOnError("In function fnAlphaIP:", errorMessage);
            }
            return;
        },
    }

    fnClearAlpha(@intCast(REGISTER_Y));

    const grpGroupingLeftOld = grpGroupingLeft;
    grpGroupingLeft = 0; // remove IP separators
    addition[@intCast(getRegisterDataType(REGISTER_X))][@intCast(getRegisterDataType(REGISTER_Y))].?();
    grpGroupingLeft = grpGroupingLeftOld; // restore IP separators

    if (lastErrorCode == ERROR_NONE) {
        if (regC != REGISTER_Y) {
            copySourceRegisterToDestRegister(regC, REGISTER_Y);
        } else {
            copySourceRegisterToDestRegister(SAVED_REGISTER_Y, REGISTER_Y);
        }
        addition[@intCast(getRegisterDataType(REGISTER_X))][@intCast(getRegisterDataType(REGISTER_Y))].?();
        copySourceRegisterToDestRegister(REGISTER_X, regC);
    }

    if (regC != REGISTER_Y or lastErrorCode != ERROR_NONE) {
        copySourceRegisterToDestRegister(SAVED_REGISTER_Y, REGISTER_Y);
    }
    copySourceRegisterToDestRegister(SAVED_REGISTER_X, REGISTER_X);
    copySourceRegisterToDestRegister(SAVED_REGISTER_L, REGISTER_L);
}

// 42AIP: append the integer part of X to the alpha register (clamped to 44).
pub export fn fn42Aip(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    fnAlphaIP(alphaRegister);
    truncateAlphaRegisterTo44Char();
}

// ===========================================================================
// HP-42S-style string case/slice/reverse/trim ops (new in real master).
// Faithful port of stringFuncs.c. stringFuncs.c is fully owned here, so the
// pre-existing static helpers _doXToAlpha and _readDestinationRegister (used
// only by fnAlphaTrim) are ported as file-local fns too.
// ===========================================================================

// defines.h string-function selectors.
const SF_TO_UPPER_CASE: bool = true;
const SF_TO_LOWER_CASE: bool = false;
const SF_LEFT: u8 = 1;
const SF_MID: u8 = 2;
const SF_RIGHT: u8 = 3;

const TMP_STR_LENGTH: i32 = 2560;
const MAX_NUMBER_OF_GLYPHS_IN_STRING: i32 = 508;
const SCREEN_WIDTH: i16 = 400;
const NUMBER_OF_DISPLAY_DIGITS: i16 = 20;
const ERROR_STRING_WOULD_BE_TOO_LONG: u8 = 33;
const ERROR_INPUT_TOO_LONG: u8 = 10;
const noBaseOverride: u8 = 0;
const amAngleMask: u32 = 15;
const amPolar: u32 = 16;
// STD_SPACE_PUNCTUATION = "\xa0\x08": a non-null char* literal. The C display
// calls pass it where bool_t frontSpace is expected, so it decays to true.
const STD_SPACE_PUNCTUATION_AS_BOOL: bool = true;

// Extra data-type enum values reached by the display dispatch.
const dtComplex34: u32 = 2;
const dtTime: u32 = 3;
const dtDate: u32 = 4;
const dtReal34Matrix: u32 = 6;
const dtComplex34Matrix: u32 = 7;

// upperLower_t: char upper[3]; char lower[3];
// upperLower_t centralized in abi (oracle-verified == C).
const upperLower_t = abi.UpperLower;

// complex34_t == two real34_t (32 bytes).
const complex34_t = abi.Complex34;

// Cross-owner runtime callees for the new ops.
extern fn fnDropY(unusedButMandatoryParameter: u16) void;
extern fn strcpy(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn memmove(dst: *anyopaque, src: *const anyopaque, n: usize) *anyopaque;

extern fn getRegisterTag(regist: calcRegister_t) u32;

// Font globals (only the address is needed).
extern const standardFont: abi.Font;
extern const numericFont: abi.Font;

// display.c converters reached by _readDestinationRegister.

const reg34c = abi.registerComplex34;
inline fn getRegisterAngularMode(reg: calcRegister_t) u32 {
    return getRegisterTag(reg) & amAngleMask;
}
inline fn getComplexRegisterAngularMode(reg: calcRegister_t) u32 {
    return getRegisterTag(reg) & amAngleMask;
}
inline fn getComplexRegisterPolarMode(reg: calcRegister_t) u32 {
    return getRegisterTag(reg) & amPolar;
}

// _getGlyphCode / _isSameGlyph / _toUpperOrLowerCase delegate to the std-only,
// tested glyph_case module; the wrappers keep the [*c] boundary and, for the
// case conversion, resolve the glyph length and pass the upperLowerTable in.
fn _getGlyphCode(ptrString: [*c]const u8) u16 {
    return glyph_case.glyphCode(ptrString);
}

fn _isSameGlyph(glyph: u16, ptrString: [*c]const u8) bool {
    return glyph_case.isSameGlyph(glyph, ptrString);
}

fn _toUpperOrLowerCase(ptrString: [*c]u8, toUpper: bool) void {
    const lgString: i16 = @intCast(frontier_char_string.stringGlyphLength(ptrString));
    glyph_case.toUpperOrLowerCase(ptrString, toUpper, lgString, &upperLowerTable);
}

pub export fn fnAlphaLower(regist: u16) callconv(.c) void {
    if (getRegisterDataType(@intCast(regist)) != dtString) {
        frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "cannot convert {s} to Lower Case", .{std.mem.span(frontier_debug.getRegisterDataTypeName(@intCast(regist), true, false))});
            moreInfoOnError("In function fnAlphaLower:", errorMessage);
        }
        return;
    }

    const ptrString: [*c]u8 = regString(@intCast(regist));
    _toUpperOrLowerCase(ptrString, SF_TO_LOWER_CASE);
}

pub export fn fnAlphaUpper(regist: u16) callconv(.c) void {
    if (getRegisterDataType(@intCast(regist)) != dtString) {
        frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "cannot convert {s} to Upper Case", .{std.mem.span(frontier_debug.getRegisterDataTypeName(@intCast(regist), true, false))});
            moreInfoOnError("In function fnAlphaUpper:", errorMessage);
        }
        return;
    }

    const ptrString: [*c]u8 = regString(@intCast(regist));
    _toUpperOrLowerCase(ptrString, SF_TO_UPPER_CASE);
}

// _alphaMid: copy len glyphs of ptrString starting at 1-based `start` into X.
fn _alphaMid(ptrString: [*c]u8, start_arg: i32, len_arg: i32) void {
    const lgString: i32 = frontier_char_string.stringGlyphLength(ptrString);
    // Extract the substring into the scratch buffer, then reallocate REGISTER_X
    // to hold it and copy it in. The clamp + glyph-walk copy is the pure core.
    _ = alpha_substring.alphaMid(tmpString, ptrString, start_arg, len_arg, lgString);
    reallocateRegister(REGISTER_X, dtString, TO_BLOCKS(@intCast(stringByteLength(tmpString) + 1)), amNone);
    _ = frontier_char_string.xcopy(regString(REGISTER_X), tmpString, @intCast(stringByteLength(tmpString) + 1));
}

fn _alphaLeftMidRight(regist: u16, sf_type: u8) void {
    var lgInt: longInteger_t = undefined;

    if (getRegisterDataType(@intCast(regist)) != dtString) {
        frontier_register_value_conversions.badTypeError(@intCast(regist));
        return;
    }

    const ptrString: [*c]u8 = regString(@intCast(regist));
    const lgString: i32 = frontier_char_string.stringGlyphLength(ptrString);

    if (!frontier_register_value_conversions.getRegisterAsLongInt(REGISTER_X, &lgInt[0], null)) {
        longIntegerFree(&lgInt[0]);
        return;
    }
    var len: i32 = @intCast(__gmpz_get_si(&lgInt[0])); // longIntegerToInt32
    if (len < 0) {
        len = 0;
    } else if (len > lgString) {
        len = lgString;
    }

    var start: i32 = 0;
    if (sf_type == SF_MID) {
        longIntegerFree(&lgInt[0]);
        if (!frontier_register_value_conversions.getRegisterAsLongInt(REGISTER_Y, &lgInt[0], null)) {
            longIntegerFree(&lgInt[0]);
            return;
        }
        start = @intCast(__gmpz_get_si(&lgInt[0])); // longIntegerToInt32
        if (start < 0) {
            start = 0;
        }
    }

    if (!saveLastX()) {
        longIntegerFree(&lgInt[0]);
        return;
    }

    switch (sf_type) {
        SF_LEFT => {
            _alphaMid(ptrString, 1, len);
        },
        SF_MID => {
            _alphaMid(ptrString, start, len);
            fnDropY(NOPARAM);
        },
        SF_RIGHT => {
            _alphaMid(ptrString, lgString - len + 1, len);
        },
        else => {},
    }
    longIntegerFree(&lgInt[0]);
}

pub export fn fnAlphaLeft(regist: u16) callconv(.c) void {
    _alphaLeftMidRight(regist, SF_LEFT);
}

pub export fn fnAlphaMid(regist: u16) callconv(.c) void {
    _alphaLeftMidRight(regist, SF_MID);
}

pub export fn fnAlphaRight(regist: u16) callconv(.c) void {
    _alphaLeftMidRight(regist, SF_RIGHT);
}

pub export fn fnAlphaRev(regist: u16) callconv(.c) void {
    if (getRegisterDataType(@intCast(regist)) != dtString) {
        frontier_register_value_conversions.badTypeError(@intCast(regist));
        return;
    }

    const ptrString: [*c]u8 = regString(@intCast(regist));
    const lgString: i32 = frontier_char_string.stringGlyphLength(ptrString);

    if (strlen(ptrString) > @as(usize, @intCast(TMP_STR_LENGTH))) {
        frontier_error.displayCalcErrorMessage(ERROR_INPUT_TOO_LONG, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "string in regist {d} is too long, size {d} bytes doesn't fit in tmpString ({d} bytes max)", .{ @as(c_int, @intCast(regist)), @as(c_uint, @truncate(strlen(ptrString))), @as(c_int, TMP_STR_LENGTH) });
            moreInfoOnError("In function fnAlphaRev:", errorMessage);
        }
        return;
    }

    var ptrTmp: [*c]u8 = tmpString;
    var pos: i16 = frontier_char_string.stringLastGlyph(ptrString);

    var i: i16 = 1;
    while (i <= lgString) : (i += 1) {
        const glyph: u16 = _getGlyphCode(ptrString + @as(usize, @intCast(pos)));
        if ((glyph & 0x8000) != 0) {
            ptrTmp[0] = @truncate(glyph >> 8);
            ptrTmp += 1;
        }
        ptrTmp[0] = @truncate(glyph & 0xff);
        ptrTmp += 1;
        pos = frontier_char_string.stringPrevGlyph(ptrString, pos);
    }
    ptrTmp[0] = 0;
    _ = strcpy(ptrString, tmpString);
    tmpString[0] = 0; // clear tmpString
}

// _readDestinationRegister: render a register to tmpString as a display string.
fn _readDestinationRegister(regist: u16) void {
    switch (getRegisterDataType(@intCast(regist))) {
        dtLongInteger => {
            frontier_display.longIntegerRegisterToDisplayString(@intCast(regist), tmpString, TMP_STR_LENGTH, SCREEN_WIDTH, 50, @intFromBool(STD_SPACE_PUNCTUATION_AS_BOOL));
        },
        dtTime => {
            frontier_display.timeToDisplayString(@intCast(regist), tmpString, 0);
        },
        dtDate => {
            frontier_display.dateToDisplayString(@intCast(regist), tmpString);
        },
        dtString => {
            _ = frontier_char_string.xcopy(tmpString, regString(@intCast(regist)), @intCast(stringByteLength(regString(@intCast(regist))) + 1));
        },
        dtReal34Matrix => {
            frontier_display.real34MatrixToDisplayString(@intCast(regist), tmpString);
        },
        dtComplex34Matrix => {
            frontier_display.complex34MatrixToDisplayString(@intCast(regist), tmpString);
        },
        dtShortInteger => {
            frontier_display.shortIntegerToDisplayString(@intCast(regist), tmpString, 0, noBaseOverride);
        },
        dtReal34 => {
            frontier_display.real34ToDisplayString(reg34(@intCast(regist)), getRegisterAngularMode(@intCast(regist)), tmpString, &standardFont, SCREEN_WIDTH, NUMBER_OF_DISPLAY_DIGITS, 0, @intFromBool(STD_SPACE_PUNCTUATION_AS_BOOL), 1);
            trimLeadingSpace(tmpString);
        },
        dtComplex34 => {
            frontier_display.complex34ToDisplayString(reg34c(@intCast(regist)), tmpString, &numericFont, SCREEN_WIDTH, NUMBER_OF_DISPLAY_DIGITS, 0, @intFromBool(STD_SPACE_PUNCTUATION_AS_BOOL), 1, @truncate(getComplexRegisterAngularMode(@intCast(regist))), @intFromBool(getComplexRegisterPolarMode(@intCast(regist)) != 0));
            trimLeadingSpace(tmpString);
        },
        else => {
            tmpString[0] = 0;
        },
    }
}

// _doXToAlpha: append the alpha char encoded by X's numeric value to `regist`.
fn _doXToAlpha(regist: u16) callconv(.c) void {
    var lgInt: longInteger_t = undefined;
    var char1: u8 = undefined;
    var char2: u8 = undefined;

    longIntegerInit(&lgInt[0]);
    switch (getRegisterDataType(REGISTER_X)) {
        dtLongInteger => {
            longIntegerFree(&lgInt[0]);
            frontier_register_value_conversions.convertLongIntegerRegisterToLongInteger(REGISTER_X, &lgInt[0]);
        },
        dtReal34 => {
            if (real34CompareAbsGreaterThan(reg34(REGISTER_X), const34_1e6())) {
                uInt32ToLongInteger(1000000, &lgInt[0]);
            } else {
                longIntegerFree(&lgInt[0]);
                frontier_register_value_conversions.convertReal34ToLongInteger(reg34(REGISTER_X), &lgInt[0], DEC_ROUND_DOWN);
            }
        },
        dtShortInteger => {
            longIntegerFree(&lgInt[0]);
            frontier_register_value_conversions.convertShortIntegerRegisterToLongInteger(REGISTER_X, &lgInt[0]);
        },
        dtReal34Matrix => {
            longIntegerFree(&lgInt[0]);
            frontier_register_value_conversions.convertShortIntegerRegisterToLongInteger(REGISTER_X, &lgInt[0]);
        },
        else => {
            frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
            if (comptime extra_info) {
                abi.fmtBufZ(errorMessage[0..512], "cannot x\xa1\x92\x83\xb1 when X is {s}", .{std.mem.span(frontier_debug.getRegisterDataTypeName(REGISTER_X, true, false))});
                moreInfoOnError("In function _doXToAlpha:", errorMessage);
            }
            longIntegerFree(&lgInt[0]);
            return;
        },
    }

    longIntegerSetPositiveSign(&lgInt[0]);
    if (longIntegerCompareUInt(&lgInt[0], 0x8000) >= 0) {
        frontier_error.displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "for x\xa1\x92\x83\xb1, X must be < 32768. Here X = {d}", .{@as(u32, @truncate(lgInt[0]._mp_d[0]))}); // OK for 32 and 64 bit limbs
            moreInfoOnError("In function _doXToAlpha:", errorMessage);
        }
        longIntegerFree(&lgInt[0]);
        return;
    }

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

    if (regist != @as(u16, @intCast(REGISTER_X))) {
        _readDestinationRegister(regist);
    } else {
        tmpString[0] = 0; // If destination register is X just return the alpha character from the character code
    }

    if (frontier_char_string.stringGlyphLength(tmpString) >= MAX_NUMBER_OF_GLYPHS_IN_STRING) {
        frontier_error.displayCalcErrorMessage(ERROR_STRING_WOULD_BE_TOO_LONG, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "the resulting string would be {d} characters long. Maximum is {d}", .{ frontier_char_string.stringGlyphLength(tmpString) + 1, MAX_NUMBER_OF_GLYPHS_IN_STRING });
            moreInfoOnError("In function _doXToAlpha:", errorMessage);
        }
    } else {
        var l: i32 = stringByteLength(tmpString);
        tmpString[@intCast(l)] = char1;
        tmpString[@intCast(l + 1)] = char2;
        if (char2 != 0) {
            tmpString[@intCast(l + 2)] = 0;
            l += 1;
        }
        l += 1;

        reallocateRegister(@intCast(regist), dtString, @intCast(l + 1), amNone);
        _ = frontier_char_string.xcopy(regString(@intCast(regist)), tmpString, @intCast(l + 1));
    }
}

pub export fn fnAlphaTrim(regist: u16) callconv(.c) void {
    if (getRegisterDataType(@intCast(regist)) != dtString) {
        frontier_register_value_conversions.badTypeError(@intCast(regist));
        return;
    }

    switch (getRegisterDataType(REGISTER_X)) {
        dtLongInteger, dtReal34, dtShortInteger => {
            _doXToAlpha(@intCast(REGISTER_X)); // convert X to a single character
        },
        dtString => {},
        else => {
            frontier_register_value_conversions.badTypeError(REGISTER_X);
            return;
        },
    }
    var ptrString: [*c]u8 = regString(REGISTER_X);
    var lgString: i32 = frontier_char_string.stringGlyphLength(ptrString);
    if (lgString != 1) {
        frontier_error.displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "for \x83\xb1TRIM, X must be a single character. Here X = {s}", .{std.mem.span(ptrString)});
            moreInfoOnError("In function fnAlphaTrim:", errorMessage);
        }
        copySourceRegisterToDestRegister(SAVED_REGISTER_X, REGISTER_X); // Restore register X
        copySourceRegisterToDestRegister(REGISTER_L, SAVED_REGISTER_L); // Save register L
        return;
    }

    const glyph: u16 = _getGlyphCode(ptrString);
    ptrString = regString(@intCast(regist));
    lgString = frontier_char_string.stringGlyphLength(ptrString);

    // Trim character at the beginning of the string
    var pos: i16 = 0;
    while (_isSameGlyph(glyph, ptrString + @as(usize, @intCast(pos)))) {
        pos = frontier_char_string.stringNextGlyph(ptrString, pos);
    }
    _ = memmove(ptrString, ptrString + @as(usize, @intCast(pos)), strlen(ptrString + @as(usize, @intCast(pos))) + 1);

    // Trim character at the end of the string
    pos = frontier_char_string.stringLastGlyph(ptrString);
    while (_isSameGlyph(glyph, ptrString + @as(usize, @intCast(pos)))) {
        ptrString[@intCast(pos)] = 0;
        pos = frontier_char_string.stringLastGlyph(ptrString);
    }

    copySourceRegisterToDestRegister(SAVED_REGISTER_X, REGISTER_X); // Restore register X
    copySourceRegisterToDestRegister(REGISTER_L, SAVED_REGISTER_L); // Save register L
}

// upper<->lower case map (TO_QSPI const upperLowerTable[] in C).
const upperLowerTable = [_]upperLower_t{
    .{ .upper = [3]u8{ 0x41, 0x00, 0x00 }, .lower = [3]u8{ 0x61, 0x00, 0x00 } },
    .{ .upper = [3]u8{ 0x42, 0x00, 0x00 }, .lower = [3]u8{ 0x62, 0x00, 0x00 } },
    .{ .upper = [3]u8{ 0x43, 0x00, 0x00 }, .lower = [3]u8{ 0x63, 0x00, 0x00 } },
    .{ .upper = [3]u8{ 0x44, 0x00, 0x00 }, .lower = [3]u8{ 0x64, 0x00, 0x00 } },
    .{ .upper = [3]u8{ 0x45, 0x00, 0x00 }, .lower = [3]u8{ 0x65, 0x00, 0x00 } },
    .{ .upper = [3]u8{ 0x46, 0x00, 0x00 }, .lower = [3]u8{ 0x66, 0x00, 0x00 } },
    .{ .upper = [3]u8{ 0x47, 0x00, 0x00 }, .lower = [3]u8{ 0x67, 0x00, 0x00 } },
    .{ .upper = [3]u8{ 0x48, 0x00, 0x00 }, .lower = [3]u8{ 0x68, 0x00, 0x00 } },
    .{ .upper = [3]u8{ 0x49, 0x00, 0x00 }, .lower = [3]u8{ 0x69, 0x00, 0x00 } },
    .{ .upper = [3]u8{ 0x4a, 0x00, 0x00 }, .lower = [3]u8{ 0x6a, 0x00, 0x00 } },
    .{ .upper = [3]u8{ 0x4b, 0x00, 0x00 }, .lower = [3]u8{ 0x6b, 0x00, 0x00 } },
    .{ .upper = [3]u8{ 0x4c, 0x00, 0x00 }, .lower = [3]u8{ 0x6c, 0x00, 0x00 } },
    .{ .upper = [3]u8{ 0x4d, 0x00, 0x00 }, .lower = [3]u8{ 0x6d, 0x00, 0x00 } },
    .{ .upper = [3]u8{ 0x4e, 0x00, 0x00 }, .lower = [3]u8{ 0x6e, 0x00, 0x00 } },
    .{ .upper = [3]u8{ 0x4f, 0x00, 0x00 }, .lower = [3]u8{ 0x6f, 0x00, 0x00 } },
    .{ .upper = [3]u8{ 0x50, 0x00, 0x00 }, .lower = [3]u8{ 0x70, 0x00, 0x00 } },
    .{ .upper = [3]u8{ 0x51, 0x00, 0x00 }, .lower = [3]u8{ 0x71, 0x00, 0x00 } },
    .{ .upper = [3]u8{ 0x52, 0x00, 0x00 }, .lower = [3]u8{ 0x72, 0x00, 0x00 } },
    .{ .upper = [3]u8{ 0x53, 0x00, 0x00 }, .lower = [3]u8{ 0x73, 0x00, 0x00 } },
    .{ .upper = [3]u8{ 0x54, 0x00, 0x00 }, .lower = [3]u8{ 0x74, 0x00, 0x00 } },
    .{ .upper = [3]u8{ 0x55, 0x00, 0x00 }, .lower = [3]u8{ 0x75, 0x00, 0x00 } },
    .{ .upper = [3]u8{ 0x56, 0x00, 0x00 }, .lower = [3]u8{ 0x76, 0x00, 0x00 } },
    .{ .upper = [3]u8{ 0x57, 0x00, 0x00 }, .lower = [3]u8{ 0x77, 0x00, 0x00 } },
    .{ .upper = [3]u8{ 0x58, 0x00, 0x00 }, .lower = [3]u8{ 0x78, 0x00, 0x00 } },
    .{ .upper = [3]u8{ 0x59, 0x00, 0x00 }, .lower = [3]u8{ 0x79, 0x00, 0x00 } },
    .{ .upper = [3]u8{ 0x5a, 0x00, 0x00 }, .lower = [3]u8{ 0x7a, 0x00, 0x00 } },
    .{ .upper = [3]u8{ 0x83, 0x91, 0x00 }, .lower = [3]u8{ 0x83, 0xb1, 0x00 } },
    .{ .upper = [3]u8{ 0x83, 0x92, 0x00 }, .lower = [3]u8{ 0x83, 0xb2, 0x00 } },
    .{ .upper = [3]u8{ 0x83, 0x93, 0x00 }, .lower = [3]u8{ 0x83, 0xb3, 0x00 } },
    .{ .upper = [3]u8{ 0x83, 0x94, 0x00 }, .lower = [3]u8{ 0x83, 0xb4, 0x00 } },
    .{ .upper = [3]u8{ 0x83, 0x95, 0x00 }, .lower = [3]u8{ 0x83, 0xb5, 0x00 } },
    .{ .upper = [3]u8{ 0x83, 0x96, 0x00 }, .lower = [3]u8{ 0x83, 0xb6, 0x00 } },
    .{ .upper = [3]u8{ 0x83, 0x97, 0x00 }, .lower = [3]u8{ 0x83, 0xb7, 0x00 } },
    .{ .upper = [3]u8{ 0x83, 0x98, 0x00 }, .lower = [3]u8{ 0x83, 0xb8, 0x00 } },
    .{ .upper = [3]u8{ 0x83, 0x99, 0x00 }, .lower = [3]u8{ 0x83, 0xb9, 0x00 } },
    .{ .upper = [3]u8{ 0x83, 0x9a, 0x00 }, .lower = [3]u8{ 0x83, 0xba, 0x00 } },
    .{ .upper = [3]u8{ 0x83, 0x9b, 0x00 }, .lower = [3]u8{ 0x83, 0xbb, 0x00 } },
    .{ .upper = [3]u8{ 0x83, 0x9c, 0x00 }, .lower = [3]u8{ 0x83, 0xbc, 0x00 } },
    .{ .upper = [3]u8{ 0x83, 0x9d, 0x00 }, .lower = [3]u8{ 0x83, 0xbd, 0x00 } },
    .{ .upper = [3]u8{ 0x83, 0x9e, 0x00 }, .lower = [3]u8{ 0x83, 0xbe, 0x00 } },
    .{ .upper = [3]u8{ 0x83, 0x9f, 0x00 }, .lower = [3]u8{ 0x83, 0xbf, 0x00 } },
    .{ .upper = [3]u8{ 0x83, 0xa0, 0x00 }, .lower = [3]u8{ 0x83, 0xc0, 0x00 } },
    .{ .upper = [3]u8{ 0x83, 0xa1, 0x00 }, .lower = [3]u8{ 0x83, 0xc1, 0x00 } },
    .{ .upper = [3]u8{ 0x83, 0xa3, 0x00 }, .lower = [3]u8{ 0x83, 0xc3, 0x00 } },
    .{ .upper = [3]u8{ 0x83, 0xa4, 0x00 }, .lower = [3]u8{ 0x83, 0xc4, 0x00 } },
    .{ .upper = [3]u8{ 0x83, 0xa5, 0x00 }, .lower = [3]u8{ 0x83, 0xc5, 0x00 } },
    .{ .upper = [3]u8{ 0x83, 0xa6, 0x00 }, .lower = [3]u8{ 0x83, 0xc6, 0x00 } },
    .{ .upper = [3]u8{ 0x83, 0xa7, 0x00 }, .lower = [3]u8{ 0x83, 0xc7, 0x00 } },
    .{ .upper = [3]u8{ 0x83, 0xa8, 0x00 }, .lower = [3]u8{ 0x83, 0xc8, 0x00 } },
    .{ .upper = [3]u8{ 0x83, 0xa9, 0x00 }, .lower = [3]u8{ 0x83, 0xc9, 0x00 } },
    .{ .upper = [3]u8{ 0x83, 0xaa, 0x00 }, .lower = [3]u8{ 0x83, 0xca, 0x00 } },
    .{ .upper = [3]u8{ 0x83, 0xab, 0x00 }, .lower = [3]u8{ 0x83, 0xcb, 0x00 } },
    .{ .upper = [3]u8{ 0x80, 0xc0, 0x00 }, .lower = [3]u8{ 0x80, 0xe0, 0x00 } },
    .{ .upper = [3]u8{ 0x80, 0xc1, 0x00 }, .lower = [3]u8{ 0x80, 0xe1, 0x00 } },
    .{ .upper = [3]u8{ 0x80, 0xc2, 0x00 }, .lower = [3]u8{ 0x80, 0xe2, 0x00 } },
    .{ .upper = [3]u8{ 0x80, 0xc3, 0x00 }, .lower = [3]u8{ 0x80, 0xe3, 0x00 } },
    .{ .upper = [3]u8{ 0x80, 0xc4, 0x00 }, .lower = [3]u8{ 0x80, 0xe4, 0x00 } },
    .{ .upper = [3]u8{ 0x80, 0xc5, 0x00 }, .lower = [3]u8{ 0x80, 0xe5, 0x00 } },
    .{ .upper = [3]u8{ 0x80, 0xc6, 0x00 }, .lower = [3]u8{ 0x80, 0xe6, 0x00 } },
    .{ .upper = [3]u8{ 0x80, 0xc7, 0x00 }, .lower = [3]u8{ 0x80, 0xe7, 0x00 } },
    .{ .upper = [3]u8{ 0x80, 0xc8, 0x00 }, .lower = [3]u8{ 0x80, 0xe8, 0x00 } },
    .{ .upper = [3]u8{ 0x80, 0xc9, 0x00 }, .lower = [3]u8{ 0x80, 0xe9, 0x00 } },
    .{ .upper = [3]u8{ 0x80, 0xca, 0x00 }, .lower = [3]u8{ 0x80, 0xea, 0x00 } },
    .{ .upper = [3]u8{ 0x80, 0xcb, 0x00 }, .lower = [3]u8{ 0x80, 0xeb, 0x00 } },
    .{ .upper = [3]u8{ 0x80, 0xcc, 0x00 }, .lower = [3]u8{ 0x80, 0xec, 0x00 } },
    .{ .upper = [3]u8{ 0x80, 0xcd, 0x00 }, .lower = [3]u8{ 0x80, 0xed, 0x00 } },
    .{ .upper = [3]u8{ 0x80, 0xce, 0x00 }, .lower = [3]u8{ 0x80, 0xee, 0x00 } },
    .{ .upper = [3]u8{ 0x80, 0xcf, 0x00 }, .lower = [3]u8{ 0x80, 0xef, 0x00 } },
    .{ .upper = [3]u8{ 0x80, 0xd0, 0x00 }, .lower = [3]u8{ 0x80, 0xf0, 0x00 } },
    .{ .upper = [3]u8{ 0x80, 0xd1, 0x00 }, .lower = [3]u8{ 0x80, 0xf1, 0x00 } },
    .{ .upper = [3]u8{ 0x80, 0xd2, 0x00 }, .lower = [3]u8{ 0x80, 0xf2, 0x00 } },
    .{ .upper = [3]u8{ 0x80, 0xd3, 0x00 }, .lower = [3]u8{ 0x80, 0xf3, 0x00 } },
    .{ .upper = [3]u8{ 0x80, 0xd4, 0x00 }, .lower = [3]u8{ 0x80, 0xf4, 0x00 } },
    .{ .upper = [3]u8{ 0x80, 0xd5, 0x00 }, .lower = [3]u8{ 0x80, 0xf5, 0x00 } },
    .{ .upper = [3]u8{ 0x80, 0xd6, 0x00 }, .lower = [3]u8{ 0x80, 0xf6, 0x00 } },
    .{ .upper = [3]u8{ 0x80, 0xd7, 0x00 }, .lower = [3]u8{ 0x80, 0xf7, 0x00 } },
    .{ .upper = [3]u8{ 0x80, 0xd8, 0x00 }, .lower = [3]u8{ 0x80, 0xf8, 0x00 } },
    .{ .upper = [3]u8{ 0x80, 0xd9, 0x00 }, .lower = [3]u8{ 0x80, 0xf9, 0x00 } },
    .{ .upper = [3]u8{ 0x80, 0xda, 0x00 }, .lower = [3]u8{ 0x80, 0xfa, 0x00 } },
    .{ .upper = [3]u8{ 0x80, 0xdb, 0x00 }, .lower = [3]u8{ 0x80, 0xfb, 0x00 } },
    .{ .upper = [3]u8{ 0x80, 0xdc, 0x00 }, .lower = [3]u8{ 0x80, 0xfc, 0x00 } },
    .{ .upper = [3]u8{ 0x80, 0xdd, 0x00 }, .lower = [3]u8{ 0x80, 0xfd, 0x00 } },
    .{ .upper = [3]u8{ 0x81, 0x78, 0x00 }, .lower = [3]u8{ 0x80, 0xff, 0x00 } },
    .{ .upper = [3]u8{ 0x81, 0x7f, 0x00 }, .lower = [3]u8{ 0x81, 0x01, 0x00 } },
    .{ .upper = [3]u8{ 0x81, 0x02, 0x00 }, .lower = [3]u8{ 0x81, 0x03, 0x00 } },
    .{ .upper = [3]u8{ 0x81, 0x04, 0x00 }, .lower = [3]u8{ 0x81, 0x05, 0x00 } },
    .{ .upper = [3]u8{ 0x81, 0x06, 0x00 }, .lower = [3]u8{ 0x81, 0x07, 0x00 } },
    .{ .upper = [3]u8{ 0x81, 0x0c, 0x00 }, .lower = [3]u8{ 0x81, 0x0d, 0x00 } },
    .{ .upper = [3]u8{ 0x81, 0x10, 0x00 }, .lower = [3]u8{ 0x81, 0x11, 0x00 } },
    .{ .upper = [3]u8{ 0x81, 0x12, 0x00 }, .lower = [3]u8{ 0x81, 0x13, 0x00 } },
    .{ .upper = [3]u8{ 0x81, 0x14, 0x00 }, .lower = [3]u8{ 0x81, 0x15, 0x00 } },
    .{ .upper = [3]u8{ 0x81, 0x16, 0x00 }, .lower = [3]u8{ 0x81, 0x17, 0x00 } },
    .{ .upper = [3]u8{ 0x81, 0x18, 0x00 }, .lower = [3]u8{ 0x81, 0x19, 0x00 } },
    .{ .upper = [3]u8{ 0x81, 0x1a, 0x00 }, .lower = [3]u8{ 0x81, 0x1b, 0x00 } },
    .{ .upper = [3]u8{ 0x81, 0x1e, 0x00 }, .lower = [3]u8{ 0x81, 0x1f, 0x00 } },
    .{ .upper = [3]u8{ 0x81, 0x2a, 0x00 }, .lower = [3]u8{ 0x81, 0x2b, 0x00 } },
    .{ .upper = [3]u8{ 0x81, 0x2c, 0x00 }, .lower = [3]u8{ 0x81, 0x2d, 0x00 } },
    .{ .upper = [3]u8{ 0x81, 0x2e, 0x00 }, .lower = [3]u8{ 0x81, 0x2f, 0x00 } },
    .{ .upper = [3]u8{ 0x81, 0x39, 0x00 }, .lower = [3]u8{ 0x81, 0x3a, 0x00 } },
    .{ .upper = [3]u8{ 0x81, 0x3d, 0x00 }, .lower = [3]u8{ 0x81, 0x3e, 0x00 } },
    .{ .upper = [3]u8{ 0x81, 0x41, 0x00 }, .lower = [3]u8{ 0x81, 0x42, 0x00 } },
    .{ .upper = [3]u8{ 0x81, 0x43, 0x00 }, .lower = [3]u8{ 0x81, 0x44, 0x00 } },
    .{ .upper = [3]u8{ 0x81, 0x47, 0x00 }, .lower = [3]u8{ 0x81, 0x48, 0x00 } },
    .{ .upper = [3]u8{ 0x81, 0x4c, 0x00 }, .lower = [3]u8{ 0x81, 0x4d, 0x00 } },
    .{ .upper = [3]u8{ 0x81, 0x4e, 0x00 }, .lower = [3]u8{ 0x81, 0x4f, 0x00 } },
    .{ .upper = [3]u8{ 0x81, 0x52, 0x00 }, .lower = [3]u8{ 0x81, 0x53, 0x00 } },
    .{ .upper = [3]u8{ 0x81, 0x54, 0x00 }, .lower = [3]u8{ 0x81, 0x55, 0x00 } },
    .{ .upper = [3]u8{ 0x81, 0x58, 0x00 }, .lower = [3]u8{ 0x81, 0x59, 0x00 } },
    .{ .upper = [3]u8{ 0x81, 0x5a, 0x00 }, .lower = [3]u8{ 0x81, 0x5b, 0x00 } },
    .{ .upper = [3]u8{ 0x81, 0x5e, 0x00 }, .lower = [3]u8{ 0x81, 0x5f, 0x00 } },
    .{ .upper = [3]u8{ 0x81, 0x60, 0x00 }, .lower = [3]u8{ 0x81, 0x61, 0x00 } },
    .{ .upper = [3]u8{ 0x81, 0x62, 0x00 }, .lower = [3]u8{ 0x81, 0x63, 0x00 } },
    .{ .upper = [3]u8{ 0x81, 0x64, 0x00 }, .lower = [3]u8{ 0x81, 0x65, 0x00 } },
    .{ .upper = [3]u8{ 0x81, 0x68, 0x00 }, .lower = [3]u8{ 0x81, 0x69, 0x00 } },
    .{ .upper = [3]u8{ 0x81, 0x6a, 0x00 }, .lower = [3]u8{ 0x81, 0x6b, 0x00 } },
    .{ .upper = [3]u8{ 0x81, 0x6c, 0x00 }, .lower = [3]u8{ 0x81, 0x6d, 0x00 } },
    .{ .upper = [3]u8{ 0x81, 0x6e, 0x00 }, .lower = [3]u8{ 0x81, 0x6f, 0x00 } },
    .{ .upper = [3]u8{ 0x81, 0x72, 0x00 }, .lower = [3]u8{ 0x81, 0x73, 0x00 } },
    .{ .upper = [3]u8{ 0x81, 0x74, 0x00 }, .lower = [3]u8{ 0x81, 0x75, 0x00 } },
    .{ .upper = [3]u8{ 0x81, 0x76, 0x00 }, .lower = [3]u8{ 0x81, 0x77, 0x00 } },
    .{ .upper = [3]u8{ 0x81, 0x79, 0x00 }, .lower = [3]u8{ 0x81, 0x7a, 0x00 } },
    .{ .upper = [3]u8{ 0x81, 0x7b, 0x00 }, .lower = [3]u8{ 0x81, 0x7c, 0x00 } },
    .{ .upper = [3]u8{ 0x81, 0x7d, 0x00 }, .lower = [3]u8{ 0x81, 0x7e, 0x00 } },
    .{ .upper = [3]u8{ 0x83, 0xd8, 0x00 }, .lower = [3]u8{ 0x83, 0xd9, 0x00 } },
    .{ .upper = [3]u8{ 0x83, 0xdc, 0x00 }, .lower = [3]u8{ 0x83, 0xdd, 0x00 } },
    .{ .upper = [3]u8{ 0x83, 0xe0, 0x00 }, .lower = [3]u8{ 0x83, 0xe1, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xb6, 0x00 }, .lower = [3]u8{ 0xa4, 0x82, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xb7, 0x00 }, .lower = [3]u8{ 0xa4, 0x83, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xb8, 0x00 }, .lower = [3]u8{ 0xa4, 0x84, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xb9, 0x00 }, .lower = [3]u8{ 0xa4, 0x85, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xba, 0x00 }, .lower = [3]u8{ 0xa4, 0x86, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xbb, 0x00 }, .lower = [3]u8{ 0xa4, 0x87, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xbc, 0x00 }, .lower = [3]u8{ 0xa4, 0x88, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xbd, 0x00 }, .lower = [3]u8{ 0xa4, 0x89, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xbe, 0x00 }, .lower = [3]u8{ 0xa4, 0x8a, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xbf, 0x00 }, .lower = [3]u8{ 0xa4, 0x8b, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xc0, 0x00 }, .lower = [3]u8{ 0xa4, 0x8c, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xc1, 0x00 }, .lower = [3]u8{ 0xa4, 0x8d, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xc2, 0x00 }, .lower = [3]u8{ 0xa4, 0x8e, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xc3, 0x00 }, .lower = [3]u8{ 0xa4, 0x8f, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xc4, 0x00 }, .lower = [3]u8{ 0xa4, 0x90, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xc5, 0x00 }, .lower = [3]u8{ 0xa4, 0x91, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xc6, 0x00 }, .lower = [3]u8{ 0xa4, 0x92, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xc7, 0x00 }, .lower = [3]u8{ 0xa4, 0x93, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xc8, 0x00 }, .lower = [3]u8{ 0xa4, 0x94, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xc9, 0x00 }, .lower = [3]u8{ 0xa4, 0x95, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xca, 0x00 }, .lower = [3]u8{ 0xa4, 0x96, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xcb, 0x00 }, .lower = [3]u8{ 0xa4, 0x97, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xcc, 0x00 }, .lower = [3]u8{ 0xa4, 0x98, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xcd, 0x00 }, .lower = [3]u8{ 0xa4, 0x99, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xce, 0x00 }, .lower = [3]u8{ 0xa4, 0x9a, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xcf, 0x00 }, .lower = [3]u8{ 0xa4, 0x9b, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xd0, 0x00 }, .lower = [3]u8{ 0xa4, 0x9c, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xd1, 0x00 }, .lower = [3]u8{ 0xa4, 0x9d, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xd2, 0x00 }, .lower = [3]u8{ 0xa4, 0x9e, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xd3, 0x00 }, .lower = [3]u8{ 0xa4, 0x9f, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xd4, 0x00 }, .lower = [3]u8{ 0xa4, 0xa0, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xd5, 0x00 }, .lower = [3]u8{ 0xa4, 0xa1, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xd6, 0x00 }, .lower = [3]u8{ 0xa4, 0xa2, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xd7, 0x00 }, .lower = [3]u8{ 0xa4, 0xa3, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xd8, 0x00 }, .lower = [3]u8{ 0xa4, 0xa4, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xd9, 0x00 }, .lower = [3]u8{ 0xa4, 0xa5, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xda, 0x00 }, .lower = [3]u8{ 0xa4, 0xa6, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xdb, 0x00 }, .lower = [3]u8{ 0xa4, 0xa7, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xdc, 0x00 }, .lower = [3]u8{ 0xa4, 0xa8, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xdd, 0x00 }, .lower = [3]u8{ 0xa4, 0xa9, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xde, 0x00 }, .lower = [3]u8{ 0xa4, 0xaa, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xdf, 0x00 }, .lower = [3]u8{ 0xa4, 0xab, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xe0, 0x00 }, .lower = [3]u8{ 0xa4, 0xac, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xe1, 0x00 }, .lower = [3]u8{ 0xa4, 0xad, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xe2, 0x00 }, .lower = [3]u8{ 0xa4, 0xae, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xe3, 0x00 }, .lower = [3]u8{ 0xa4, 0xaf, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xe4, 0x00 }, .lower = [3]u8{ 0xa4, 0xb0, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xe5, 0x00 }, .lower = [3]u8{ 0xa4, 0xb1, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xe6, 0x00 }, .lower = [3]u8{ 0xa4, 0xb2, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xe7, 0x00 }, .lower = [3]u8{ 0xa4, 0xb3, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xe8, 0x00 }, .lower = [3]u8{ 0xa4, 0xb4, 0x00 } },
    .{ .upper = [3]u8{ 0xa4, 0xe9, 0x00 }, .lower = [3]u8{ 0xa4, 0xb5, 0x00 } },
    .{ .upper = [3]u8{ 0x00, 0x00, 0x00 }, .lower = [3]u8{ 0x00, 0x00, 0x00 } },
};
