//! Program-step opcode inspection -- the pure core of frontier_manage's
//! isAtEndOfPrograms / checkOpCodeOfStep / boundProgramNameLength.
//!
//! A program step is a 1- or 2-byte opcode in program memory; the end of all
//! programs is the sentinel byte pair 255,255. Detecting the sentinel, matching
//! an opcode against a step, and clamping a trusted name length against the
//! program region are pure byte/pointer arithmetic. The clamp in particular is a
//! safety bound: a corrupt or crafted program (a restored state file or imported
//! program) can claim a name longer than the bytes that remain, and this keeps a
//! name read inside the program region.
//!
//! Lifting these here gives them native coverage -- the manage owner is only
//! reachable through the C oracle. The owner keeps the C-ABI exports, which pass
//! the program-region end pointer in. Optional many-item pointers preserve the
//! original null handling without C pointers.

const std = @import("std");

/// Whether `step` is null or the 255,255 end-of-programs sentinel.
pub fn isAtEndOfPrograms(step: ?[*]const u8) bool {
    const s = step orelse return true;
    return s[0] == 255 and s[1] == 255;
}

/// Whether the opcode at `step` equals `op`: a single byte when `op < 128`,
/// otherwise the 7-bit high byte plus the low byte. Null never matches.
pub fn checkOpCodeOfStep(step: ?[*]const u8, op: u16) bool {
    const s = step orelse return false;
    if (op < 128) {
        return s[0] == op;
    }
    return (s[0] & 0x7f) == (op >> 8) and s[1] == (op & 0xff);
}

/// Clamp a trusted name length so a name read starting at `name_start` cannot
/// run past `region_end`. Returns 0 when the name would start at or past the
/// region end (no valid bytes remain).
pub fn boundProgramNameLength(name_start: [*]const u8, claimed_length: u8, region_end: [*]const u8) u8 {
    const start = @intFromPtr(name_start);
    const end = @intFromPtr(region_end);
    if (start >= end) {
        return 0;
    }
    const available = end - start;
    if (claimed_length > available) {
        return @intCast(available);
    }
    return claimed_length;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

test "isAtEndOfPrograms detects null and the sentinel" {
    try std.testing.expect(isAtEndOfPrograms(null));
    const sentinel = [_]u8{ 255, 255 };
    try std.testing.expect(isAtEndOfPrograms(&sentinel));
    const step = [_]u8{ 1, 2 };
    try std.testing.expect(!isAtEndOfPrograms(&step));
    // Only both bytes being 255 counts.
    const half = [_]u8{ 255, 1 };
    try std.testing.expect(!isAtEndOfPrograms(&half));
}

test "checkOpCodeOfStep matches single-byte opcodes" {
    const step = [_]u8{ 42, 0 };
    try std.testing.expect(checkOpCodeOfStep(&step, 42));
    try std.testing.expect(!checkOpCodeOfStep(&step, 43));
    try std.testing.expect(!checkOpCodeOfStep(null, 42));
}

test "checkOpCodeOfStep matches two-byte opcodes on the 7-bit high byte" {
    // op 0x0142 -> high byte 0x01 (with the 0x80 marker set in the step), low 0x42.
    const step = [_]u8{ 0x81, 0x42 };
    try std.testing.expect(checkOpCodeOfStep(&step, 0x0142));
    try std.testing.expect(!checkOpCodeOfStep(&step, 0x0143));
    try std.testing.expect(!checkOpCodeOfStep(&step, 0x0242));
}

test "boundProgramNameLength clamps to the region and floors at zero" {
    var region: [16]u8 = undefined;
    const start: [*]const u8 = &region;
    const end: [*]const u8 = region[10..].ptr; // 10 bytes available
    try std.testing.expectEqual(@as(u8, 5), boundProgramNameLength(start, 5, end));
    try std.testing.expectEqual(@as(u8, 10), boundProgramNameLength(start, 20, end));
    // Name starting at the region end has no room.
    try std.testing.expectEqual(@as(u8, 0), boundProgramNameLength(end, 5, end));
}
