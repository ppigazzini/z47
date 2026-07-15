//! Variable-name glyph decoding -- the pure core of register_metadata_variables'
//! validateName glyph helpers.
//!
//! A variable name is a run of 1- or 2-byte glyphs (the high bit of the first
//! byte marks a two-byte glyph, whose code is the low 7 bits of the first byte
//! shifted over the second). Counting the glyphs, stepping to the next glyph, and
//! decoding a glyph code are pure byte operations over the NUL-terminated name.
//! Lift them here for native coverage -- the variables owner allocates named
//! variables and is only exercised through the C oracle.

const std = @import("std");

/// The number of glyphs in the NUL-terminated name.
pub fn glyphLength(name: [*:0]const u8) usize {
    var glyph_length: usize = 0;
    var offset: usize = 0;
    while (name[offset] != 0) {
        offset += if ((name[offset] & 0x80) != 0) @as(usize, 2) else @as(usize, 1);
        glyph_length += 1;
    }
    return glyph_length;
}

/// The byte offset of the glyph after the one at `offset`.
pub fn nextGlyphOffset(name: [*:0]const u8, offset: usize) usize {
    return offset + if ((name[offset] & 0x80) != 0) @as(usize, 2) else @as(usize, 1);
}

/// The glyph code at `offset`: the plain byte, or the low 7 bits of the first
/// byte shifted over the second for a two-byte glyph.
pub fn glyphCode(name: [*:0]const u8, offset: usize) u16 {
    const first = name[offset];
    if ((first & 0x80) != 0) {
        return (@as(u16, first & 0x7f) << 8) | @as(u16, name[offset + 1]);
    }
    return @as(u16, first);
}

test "glyphLength counts one- and two-byte glyphs" {
    try std.testing.expectEqual(@as(usize, 3), glyphLength("abc"));
    try std.testing.expectEqual(@as(usize, 0), glyphLength(""));
    try std.testing.expectEqual(@as(usize, 2), glyphLength("\x81\x42c"));
}

test "nextGlyphOffset steps over the glyph width" {
    try std.testing.expectEqual(@as(usize, 1), nextGlyphOffset("abc", 0));
    try std.testing.expectEqual(@as(usize, 2), nextGlyphOffset("\x81\x42c", 0));
    try std.testing.expectEqual(@as(usize, 3), nextGlyphOffset("\x81\x42c", 2));
}

test "glyphCode decodes plain and two-byte glyphs with the 0x7f mask" {
    try std.testing.expectEqual(@as(u16, 0x41), glyphCode("A", 0));
    // 0x81 & 0x7f == 0x01, over 0x42 -> 0x0142.
    try std.testing.expectEqual(@as(u16, 0x0142), glyphCode("\x81\x42", 0));
}
