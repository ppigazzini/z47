// Shared text primitives for the calc-state save/restore owners: the small
// number/word parse helpers and the uint64->hex formatter that were file-static
// in saveRestoreCalcState.c (toInt16/toUint8/toUint16/toUint32, the skip_*/
// next_word navigators, toInt16_next_word, strcmp2, UI64toString). Ported here
// so the Zig save_sections / restoreOneSection owners no longer trampoline into
// C for them. Parsing uses libc strtol/strtoul and C sprintf so the conversions
// remain byte-identical to the C originals (verified by the round-trip parity
// harness). The C statics still exist for the C DMCP retained path; these are
// independent Zig copies for the host owners.

const std = @import("std");
const abi = @import("abi");
const word_scan = @import("word_scan.zig"); // std-only whitespace word scanners
extern fn strtol(nptr: [*c]const u8, endptr: ?*[*c]u8, base: c_int) c_long;
extern fn strtoul(nptr: [*c]const u8, endptr: ?*[*c]u8, base: c_int) c_ulong;
extern fn strcmp(a: [*c]const u8, b: [*c]const u8) c_int;
extern fn strlen(s: [*c]const u8) usize;
extern fn strcat(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn sprintf(str: [*c]u8, format: [*c]const u8, ...) c_int;

// (int16_t)strtol(str, NULL, 10) etc. — base-10, truncating to the target width.
pub fn toInt16(s: [*c]const u8) i16 {
    return @truncate(strtol(s, null, 10));
}
pub fn toUint8(s: [*c]const u8) u8 {
    return @truncate(strtoul(s, null, 10));
}
pub fn toUint16(s: [*c]const u8) u16 {
    return @truncate(strtoul(s, null, 10));
}
pub fn toUint32(s: [*c]const u8) u32 {
    return @truncate(strtoul(s, null, 10));
}

pub fn skipSpace(s: [*c]u8) [*c]u8 {
    return word_scan.skipSpace(s);
}
pub fn skipWord(s: [*c]u8) [*c]u8 {
    return word_scan.skipWord(s);
}
pub fn nextWord(s: [*c]u8) [*c]u8 {
    return word_scan.nextWord(s);
}
pub fn skipToSpaceNewline(s: [*c]u8) [*c]u8 {
    return word_scan.skipToSpaceNewline(s);
}
pub fn toInt16NextWord(s: [*c]u8, val: *i16) [*c]u8 {
    val.* = toInt16(s);
    return nextWord(s);
}

// Special comparison tolerating an erroneous leading-space separator in version
// 10000005-6 save files (stringByteLength is (int32_t)strlen).
pub fn strcmp2(in_str: [*c]u8, in2_str: [*c]u8) u16 {
    if (strcmp(in_str, in2_str) == 0) return 0;
    const li: i64 = @intCast(strlen(in_str));
    const l2: i64 = @intCast(strlen(in2_str));
    if (li != l2 + 1 or li > 50) return 1;
    var tmps: [60]u8 = undefined;
    tmps[0] = 32;
    tmps[1] = 0;
    _ = strcat(&tmps[0], in2_str);
    if (strcmp(in_str, &tmps[0]) == 0) return 0;
    return 1;
}

// uint64 -> "0x..." hex string (one or two 32-bit halves), via C sprintf for
// byte-identical formatting.
pub fn ui64ToString(value: u64, out: [*c]u8) void {
    const v0: u32 = @truncate(value & 0xffffffff);
    const v1: u32 = @truncate(value >> 32);
    if (v1 != 0) {
        abi.fmtCStr(out, "0x{x}{x:0>8}", .{ @as(c_uint, v1), @as(c_uint, v0) });
    } else {
        abi.fmtCStr(out, "0x{x}", .{@as(c_uint, v0)});
    }
}
