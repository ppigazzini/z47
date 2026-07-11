//! Short-integer word-size resolution -- the pure core of fnSetWordSize.
//!
//! frontier_config.zig's fnSetWordSize takes a requested word size and derives
//! the normalized size, the value mask, the sign bit, and the "setting changed"
//! and "word size reduced" predicates that gate its side effects (the
//! SETTING_SINT_WS flag change, the status-bar refresh, and the reduce-time
//! register-masking loop). That derivation is pure integer arithmetic over the
//! request and the current size; only the global writes and the register walk
//! are side effects.
//!
//! This module owns the arithmetic so it has native coverage independent of the
//! C oracle -- the config owner is testSuite-blind. The owner keeps the thin
//! shim that reads shortIntegerWordSize in, applies the result to the globals,
//! and runs the reduce loop.

const std = @import("std");

/// Resolved word-size state derived from a request and the current size.
pub const WordSizeResult = struct {
    /// The request changed the low 8 bits of the stored size; the owner raises
    /// SETTING_SINT_WS and clears the manual status-bar bit when true.
    changed: bool,
    /// Normalized word size (a request of 0 means the full 64-bit width).
    word_size: u8,
    /// Value mask for the resolved size: all ones at 64, else (1 << ws) - 1.
    mask: u64,
    /// Sign bit for the resolved size: 1 << (ws - 1).
    sign_bit: u64,
    /// The resolved size is strictly smaller than the current one; the owner
    /// masks live short-integer registers down to the new width when true.
    reduce: bool,
};

/// Resolve a requested short-integer word size against the current size.
///
/// Mirrors fnSetWordSize's arithmetic exactly: the "changed" test compares the
/// current size against the low 8 bits of the RAW request (before the 0 -> 64
/// normalization), then the request is normalized, and reduce/mask/sign_bit are
/// derived from the normalized value.
pub fn resolveWordSize(requested: u16, current_word_size: u8) WordSizeResult {
    const changed = current_word_size != @as(u8, @truncate(requested));

    const normalized: u16 = if (requested == 0) 64 else requested;
    const reduce = normalized < current_word_size;
    const word_size: u8 = @truncate(normalized);

    const mask: u64 = if (word_size == 64)
        @bitCast(@as(i64, -1))
    else
        (@as(u64, 1) << @intCast(word_size)) - 1;

    const sign_bit: u64 = @as(u64, 1) << @intCast(word_size - 1);

    return .{
        .changed = changed,
        .word_size = word_size,
        .mask = mask,
        .sign_bit = sign_bit,
        .reduce = reduce,
    };
}

test "request of 0 selects the full 64-bit width with an all-ones mask" {
    const r = resolveWordSize(0, 16);
    try std.testing.expectEqual(@as(u8, 64), r.word_size);
    try std.testing.expectEqual(@as(u64, 0xFFFF_FFFF_FFFF_FFFF), r.mask);
    try std.testing.expectEqual(@as(u64, 1) << 63, r.sign_bit);
    // 64 < 16 is false, so growing from 16 to 64 is not a reduce.
    try std.testing.expect(!r.reduce);
    // low 8 bits of the raw request (0) differ from current 16.
    try std.testing.expect(r.changed);
}

test "mask and sign bit for a representative small width" {
    const r = resolveWordSize(8, 8);
    try std.testing.expectEqual(@as(u8, 8), r.word_size);
    try std.testing.expectEqual(@as(u64, 0xFF), r.mask);
    try std.testing.expectEqual(@as(u64, 0x80), r.sign_bit);
}

test "shrinking the width reports reduce; growing does not" {
    try std.testing.expect(resolveWordSize(8, 32).reduce);
    try std.testing.expect(!resolveWordSize(32, 8).reduce);
    // equal width is not a reduce.
    try std.testing.expect(!resolveWordSize(16, 16).reduce);
}

test "changed compares the raw low 8 bits, not the normalized width" {
    // Same width requested as current -> unchanged.
    try std.testing.expect(!resolveWordSize(16, 16).changed);
    // A request of 0 normalizes to 64 but its raw low byte is 0, so when the
    // current size is already 0 the setting is reported unchanged even though
    // the resolved width becomes 64.
    try std.testing.expect(!resolveWordSize(0, 0).changed);
}

test "mask covers the full width sweep 1..64" {
    var ws: u16 = 1;
    while (ws <= 64) : (ws += 1) {
        const r = resolveWordSize(ws, 0);
        const expected: u64 = if (ws == 64)
            0xFFFF_FFFF_FFFF_FFFF
        else
            (@as(u64, 1) << @intCast(ws)) - 1;
        try std.testing.expectEqual(expected, r.mask);
        try std.testing.expectEqual(@as(u64, 1) << @intCast(ws - 1), r.sign_bit);
    }
}
