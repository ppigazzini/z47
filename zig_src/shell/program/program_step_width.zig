// SPDX-License-Identifier: GPL-3.0-only
//
// Pure program-step byte-width arithmetic, lifted from next_step.zig
// (src/c47/programming/nextStep.c). Upstream b18a42df7 refactored the walkers
// into a shared parameter-tail grammar: paramTailBytes/literalTailBytes report
// one step's tail as a fixed byte count, a length-prefixed form, or invalid,
// and countOpBytes/countLiteralBytes are thin wrappers over them. The grammar
// is shared with the program-file screening pass in the saveRestorePrograms
// owner (core/program/program_serialization.zig), exactly like the C. It is
// plain numeric arithmetic -- no register, dec, GTK, or global state -- so it
// lives here as a std+abi module exercised natively under `zig build
// test:unit`. The one runtime dependency (whether an opcode is an old-style
// Param16) is threaded in as a predicate callback. The owner keeps its C-ABI
// export wrappers (and the runtime-coupled findNextStep/findKey2ndParam
// walkers that call these) and delegates.
//
// testSuite-covered indirectly via programs.txt (program editing / SST-BST walks
// steps through these counters); the native tests below are the first DIRECT
// coverage of the per-opcode widths. Transcription is verbatim; the C byte
// pointer becomes a many-item pointer and the null returns become an optional.

const std = @import("std");
const abi = @import("abi");

// Constants (verified against defines.h / items.h; see audit-constant-parity).
const LAST_LOCAL_LABEL: u8 = 123;
const LAST_SPARE_REGISTERS_IN_KS_CODE: u8 = 224;
const LAST_LOCAL_FLAG: u8 = 143;
const FLAG_M: u8 = 211;
const FLAG_W: u8 = 224;
const CNST_BEYOND_250: u8 = 250;
const SYSTEM_FLAG_NUMBER: u8 = 250;
const VALUE_0: u8 = 251;
const VALUE_1: u8 = 252;
const STRING_LABEL_VARIABLE: u8 = 253;
const LOCAL_LABEL_VARIABLE: u8 = 249;
const INDIRECT_REGISTER: u8 = 254;
const INDIRECT_VARIABLE: u8 = 255;

const PARAM_DECLARE_LABEL: u16 = 1;
const PARAM_LABEL: u16 = 2;
const PARAM_REGISTER: u16 = 3;
const PARAM_FLAG: u16 = 4;
const PARAM_NUMBER_8: u16 = 5;
const PARAM_NUMBER_16: u16 = 6;
const PARAM_COMPARE: u16 = 7;
const PARAM_SKIP_BACK: u16 = 9;
const PARAM_NUMBER_8_16: u16 = 10;
const PARAM_SHUFFLE: u16 = 11;
const PARAM_MENU: u16 = 12;

const BINARY_SHORT_INTEGER: u8 = 1;
const BINARY_REAL34: u8 = 3;
const BINARY_COMPLEX34: u8 = 4;
const STRING_SHORT_INTEGER: u8 = 7;
const STRING_LONG_INTEGER: u8 = 8;
const STRING_REAL34: u8 = 9;
const STRING_COMPLEX34: u8 = 10;
const STRING_TIME: u8 = 11;
const STRING_DATE: u8 = 12;
const STRING_ANGLE_RADIAN: u8 = 18;
const STRING_ANGLE_GRAD: u8 = 19;
const STRING_ANGLE_DEGREE: u8 = 20;
const STRING_ANGLE_DMS: u8 = 21;
const STRING_ANGLE_MULTPI: u8 = 22;

const REAL34_SIZE_IN_BYTES: u32 = 16;
const REAL34_SIZE_IN_BLOCKS: u16 = 4;

// Shared parameter-tail grammar sentinels (nextStep.h).
pub const PARAM_TAIL_INVALID: i16 = -1;
pub const PARAM_TAIL_LENGTH_PREFIXED: i16 = -2;
pub const PARAM_TAIL_BASE_LENGTH_PREFIXED: i16 = -3;

inline fn toBytes(n: u16) u32 {
    return abi.block_math.toBytes(u32, n);
}

/// Parameter-tail grammar shared by the in-memory step walkers and the
/// program-file screening pass in the saveRestorePrograms owner: given the
/// parameter mode, the operation (needed for PARAM_NUMBER_16 only), and the
/// first parameter byte, the tail is a fixed byte count, a length byte and
/// that many bytes, or invalid. `isOldParam16` classifies a Param16 opcode
/// (threaded from the owner's frontier_items.isFunctionOldParam16).
pub fn paramTailBytes(paramMode: u16, op: u16, opParam: u8, isOldParam16: *const fn (u16) bool) i16 {
    switch (paramMode) {
        PARAM_DECLARE_LABEL => {
            if (opParam <= LAST_LOCAL_LABEL) return 0;
            if (opParam == STRING_LABEL_VARIABLE or opParam == LOCAL_LABEL_VARIABLE) return PARAM_TAIL_LENGTH_PREFIXED;
            return PARAM_TAIL_INVALID;
        },
        PARAM_LABEL => {
            if (opParam <= LAST_LOCAL_LABEL) return 0;
            if (opParam == STRING_LABEL_VARIABLE or opParam == INDIRECT_VARIABLE or opParam == LOCAL_LABEL_VARIABLE) return PARAM_TAIL_LENGTH_PREFIXED;
            if (opParam == INDIRECT_REGISTER) return 1;
            return PARAM_TAIL_INVALID;
        },
        PARAM_REGISTER => {
            if (opParam <= LAST_SPARE_REGISTERS_IN_KS_CODE) return 0;
            if (opParam == STRING_LABEL_VARIABLE or opParam == INDIRECT_VARIABLE) return PARAM_TAIL_LENGTH_PREFIXED;
            if (opParam == INDIRECT_REGISTER) return 1;
            return PARAM_TAIL_INVALID;
        },
        PARAM_COMPARE => {
            if (opParam <= LAST_SPARE_REGISTERS_IN_KS_CODE or opParam == VALUE_0 or opParam == VALUE_1) return 0;
            if (opParam == STRING_LABEL_VARIABLE or opParam == INDIRECT_VARIABLE) return PARAM_TAIL_LENGTH_PREFIXED;
            if (opParam == INDIRECT_REGISTER) return 1;
            return PARAM_TAIL_INVALID;
        },
        PARAM_FLAG => {
            if (opParam <= LAST_LOCAL_FLAG or (FLAG_M <= opParam and opParam <= FLAG_W)) return 0;
            if (opParam == INDIRECT_REGISTER or opParam == SYSTEM_FLAG_NUMBER) return 1;
            if (opParam == INDIRECT_VARIABLE) return PARAM_TAIL_LENGTH_PREFIXED;
            return PARAM_TAIL_INVALID;
        },
        PARAM_NUMBER_8 => {
            if (opParam <= 249) return 0;
            if (opParam == INDIRECT_REGISTER) return 1;
            if (opParam == INDIRECT_VARIABLE) return PARAM_TAIL_LENGTH_PREFIXED;
            return PARAM_TAIL_INVALID;
        },
        PARAM_NUMBER_8_16 => {
            if (opParam <= 249) return 0;
            if (opParam == CNST_BEYOND_250 or opParam == INDIRECT_REGISTER) return 1;
            if (opParam == INDIRECT_VARIABLE) return PARAM_TAIL_LENGTH_PREFIXED;
            return PARAM_TAIL_INVALID;
        },
        PARAM_NUMBER_16 => {
            // original Param16 functions have no indirection support (little endian parameter)
            if (isOldParam16(op)) return 1;
            if (opParam == INDIRECT_VARIABLE) return PARAM_TAIL_LENGTH_PREFIXED;
            return 1; // new Param16 form (big endian parameter), including INDIRECT_REGISTER
        },
        PARAM_SKIP_BACK, PARAM_SHUFFLE => {
            return 0;
        },
        PARAM_MENU => {
            if (opParam == STRING_LABEL_VARIABLE or opParam == INDIRECT_VARIABLE) return PARAM_TAIL_LENGTH_PREFIXED;
            if (opParam == INDIRECT_REGISTER) return 1;
            return PARAM_TAIL_INVALID;
        },
        else => {
            return PARAM_TAIL_INVALID;
        },
    }
}

/// Literal-tail grammar, same contract, for the type byte following ITM_LITERAL.
pub fn literalTailBytes(literalType: u8) i16 {
    switch (literalType) {
        BINARY_SHORT_INTEGER => return 9,
        BINARY_REAL34 => return @intCast(REAL34_SIZE_IN_BYTES),
        BINARY_COMPLEX34 => return @intCast(toBytes(REAL34_SIZE_IN_BLOCKS * 2)),
        STRING_SHORT_INTEGER => return PARAM_TAIL_BASE_LENGTH_PREFIXED, // base byte, then a length-prefixed string
        STRING_LONG_INTEGER,
        STRING_REAL34,
        STRING_LABEL_VARIABLE,
        STRING_COMPLEX34,
        STRING_DATE,
        STRING_TIME,
        STRING_ANGLE_DMS,
        STRING_ANGLE_RADIAN,
        STRING_ANGLE_GRAD,
        STRING_ANGLE_DEGREE,
        STRING_ANGLE_MULTPI,
        => return PARAM_TAIL_LENGTH_PREFIXED,
        else => return PARAM_TAIL_INVALID,
    }
}

/// Advance `step` past one op's parameter bytes for `paramMode`; null on a
/// malformed step. `isOldParam16` classifies a Param16 opcode (threaded from the
/// owner's frontier_items.isFunctionOldParam16).
pub fn countOpBytes(step_arg: [*]u8, paramMode: u16, isOldParam16: *const fn (u16) bool) ?[*]u8 {
    var step = step_arg;
    const opParam: u8 = step[0];
    step += 1;
    var op: u16 = 0;
    if (paramMode == PARAM_NUMBER_16) { // only PARAM_NUMBER_16 needs the operation, read back as before
        op = ((@as(u16, (step - 3)[0]) << 8) +% @as(u16, (step - 2)[0])) & 0x7fff;
    }
    const tail: i16 = paramTailBytes(paramMode, op, opParam, isOldParam16);
    if (tail == PARAM_TAIL_INVALID) {
        // !DMCP_BUILD printf diagnostic dropped.
        return null;
    }
    if (tail == PARAM_TAIL_LENGTH_PREFIXED) {
        return step + step[0] + 1;
    }
    return step + @as(usize, @intCast(tail));
}

/// Advance `step` past one literal's bytes for its kind byte; null on unknown.
pub fn countLiteralBytes(step_arg: [*]u8) ?[*]u8 {
    var step = step_arg;
    const tail: i16 = literalTailBytes(step[0]);
    step += 1;
    if (tail == PARAM_TAIL_INVALID) {
        // !DMCP_BUILD printf diagnostics dropped.
        return null;
    }
    if (tail == PARAM_TAIL_BASE_LENGTH_PREFIXED) {
        return step + (step + 1)[0] + 2;
    }
    if (tail == PARAM_TAIL_LENGTH_PREFIXED) {
        return step + step[0] + 1;
    }
    return step + @as(usize, @intCast(tail));
}

// ---------------------------------------------------------------------------
// Native tests -- first direct coverage of the per-opcode step widths. Each
// builds a byte buffer and asserts how far the counter advances (result - base).
// ---------------------------------------------------------------------------
const testing = std.testing;

fn neverOld(_: u16) bool {
    return false;
}
fn alwaysOld(_: u16) bool {
    return true;
}

fn advance(base: [*]u8, r: ?[*]u8) ?usize {
    return if (r) |p| (@intFromPtr(p) - @intFromPtr(base)) else null;
}

test "countLiteralBytes advances by the literal's encoded width" {
    var buf = std.mem.zeroes([32]u8);
    buf[0] = BINARY_REAL34;
    try testing.expectEqual(@as(?usize, 1 + 16), advance(&buf, countLiteralBytes(&buf))); // kind + real34
    buf[0] = BINARY_SHORT_INTEGER;
    try testing.expectEqual(@as(?usize, 1 + 9), advance(&buf, countLiteralBytes(&buf)));
    buf[0] = STRING_REAL34;
    buf[1] = 7; // length byte
    try testing.expectEqual(@as(?usize, 1 + 7 + 1), advance(&buf, countLiteralBytes(&buf)));
    buf[0] = STRING_SHORT_INTEGER;
    buf[1] = 0; // kind's own sub-byte
    buf[2] = 5; // (step+1)[0] length
    try testing.expectEqual(@as(?usize, 1 + 5 + 2), advance(&buf, countLiteralBytes(&buf)));
    buf[0] = 99; // unknown kind
    try testing.expectEqual(@as(?usize, null), advance(&buf, countLiteralBytes(&buf)));
}

test "countOpBytes advances by the parameter width per mode" {
    var buf = std.mem.zeroes([32]u8);
    // PARAM_LABEL: a local label (<=123) consumes just the 1 opParam byte.
    buf[0] = 5;
    try testing.expectEqual(@as(?usize, 1), advance(&buf, countOpBytes(&buf, PARAM_LABEL, neverOld)));
    // ...a string-label-variable consumes 1 + length + 1.
    buf[0] = STRING_LABEL_VARIABLE;
    buf[1] = 4;
    try testing.expectEqual(@as(?usize, 1 + 4 + 1), advance(&buf, countOpBytes(&buf, PARAM_LABEL, neverOld)));
    // ...an indirect register consumes 1 + 1.
    buf[0] = INDIRECT_REGISTER;
    try testing.expectEqual(@as(?usize, 2), advance(&buf, countOpBytes(&buf, PARAM_LABEL, neverOld)));
    // ...a bad opParam yields null.
    buf[0] = 200;
    try testing.expectEqual(@as(?usize, null), advance(&buf, countOpBytes(&buf, PARAM_LABEL, neverOld)));
    // PARAM_NUMBER_8_16: value >=250 (CNST_BEYOND_250) consumes 1 + 1.
    buf[0] = CNST_BEYOND_250;
    try testing.expectEqual(@as(?usize, 2), advance(&buf, countOpBytes(&buf, PARAM_NUMBER_8_16, neverOld)));
    // PARAM_NUMBER_16: old-style (predicate true) consumes opParam + 1 = 2. The
    // step is assumed 3 bytes into the opcode, so pass a pointer with room behind.
    var big = [_]u8{ 0, 0, 0, 7, 200, 0, 0, 0 };
    try testing.expectEqual(@as(?usize, 2), advance(big[3..].ptr, countOpBytes(big[3..].ptr, PARAM_NUMBER_16, alwaysOld)));
    // new-style (predicate false), indirect variable -> opParam + length + 1.
    var big2 = [_]u8{ 0, 0, 0, INDIRECT_VARIABLE, 3, 0, 0, 0 };
    try testing.expectEqual(@as(?usize, 1 + 3 + 1), advance(big2[3..].ptr, countOpBytes(big2[3..].ptr, PARAM_NUMBER_16, neverOld)));
}

test "paramTailBytes exposes the shared grammar the screening pass consumes" {
    // Fixed tails.
    try testing.expectEqual(@as(i16, 0), paramTailBytes(PARAM_DECLARE_LABEL, 0, 5, neverOld));
    try testing.expectEqual(@as(i16, 1), paramTailBytes(PARAM_REGISTER, 0, INDIRECT_REGISTER, neverOld));
    // Length-prefixed tails.
    try testing.expectEqual(PARAM_TAIL_LENGTH_PREFIXED, paramTailBytes(PARAM_DECLARE_LABEL, 0, STRING_LABEL_VARIABLE, neverOld));
    try testing.expectEqual(PARAM_TAIL_LENGTH_PREFIXED, paramTailBytes(PARAM_DECLARE_LABEL, 0, LOCAL_LABEL_VARIABLE, neverOld));
    // Invalid parameter.
    try testing.expectEqual(PARAM_TAIL_INVALID, paramTailBytes(PARAM_MENU, 0, 7, neverOld));
    try testing.expectEqual(PARAM_TAIL_INVALID, paramTailBytes(999, 0, 0, neverOld));
    // PARAM_NUMBER_16 consults the op through the predicate.
    try testing.expectEqual(@as(i16, 1), paramTailBytes(PARAM_NUMBER_16, 42, 0, alwaysOld));
    try testing.expectEqual(PARAM_TAIL_LENGTH_PREFIXED, paramTailBytes(PARAM_NUMBER_16, 42, INDIRECT_VARIABLE, neverOld));
    // Literal grammar: base + length-prefixed string, plain length-prefixed, invalid.
    try testing.expectEqual(PARAM_TAIL_BASE_LENGTH_PREFIXED, literalTailBytes(STRING_SHORT_INTEGER));
    try testing.expectEqual(PARAM_TAIL_LENGTH_PREFIXED, literalTailBytes(STRING_LABEL_VARIABLE));
    try testing.expectEqual(@as(i16, 9), literalTailBytes(BINARY_SHORT_INTEGER));
    try testing.expectEqual(PARAM_TAIL_INVALID, literalTailBytes(99));
}
