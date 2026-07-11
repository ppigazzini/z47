//! Glyph pixel-advance arithmetic -- the pure core of frontier_char_string's
//! calculateStringWidth.
//!
//! Each glyph contributes (doubling * (colsGlyph + colsAfterGlyph)) >> 3 pixels,
//! plus its leading gap (colsBeforeGlyph) when it is not the first glyph or when
//! leading empty rows are kept; a trailing string can then drop the final glyph's
//! colsAfterGlyph gap. `doubling` is the numeric-font stretch factor (8 = 1x).
//! This is pure integer arithmetic over the glyph's column counts -- lift it here
//! for native coverage; the string-width owner resolves each glyph and delegates.

const std = @import("std");

/// The pixel advance for one glyph. `add_before` folds in the leading gap
/// (colsBeforeGlyph), which the caller enables for every glyph past the first and
/// for the first glyph only when leading empty rows are requested.
pub fn glyphAdvance(doubling: u16, cols_glyph: u8, cols_after: u8, cols_before: u8, add_before: bool) i16 {
    var px: u32 = (@as(u32, doubling) * (@as(u32, cols_glyph) + @as(u32, cols_after))) >> 3;
    if (add_before) {
        px += (@as(u32, doubling) * @as(u32, cols_before)) >> 3;
    }
    return @intCast(px);
}

/// The trailing gap to subtract when ending empty rows are dropped: the last
/// glyph's colsAfterGlyph contribution.
pub fn trailingTrim(doubling: u16, cols_after: u8) i16 {
    return @intCast((@as(u32, doubling) * @as(u32, cols_after)) >> 3);
}

test "1x doubling advances by the column counts" {
    // doubling 8 == 1x: (8*(cols))>>3 == cols.
    try std.testing.expectEqual(@as(i16, 6), glyphAdvance(8, 5, 1, 1, false)); // 5 + 1
    try std.testing.expectEqual(@as(i16, 7), glyphAdvance(8, 5, 1, 1, true)); // + leading 1
    try std.testing.expectEqual(@as(i16, 1), trailingTrim(8, 1));
}

test "2x doubling doubles the advance" {
    // doubling 16 == 2x.
    try std.testing.expectEqual(@as(i16, 12), glyphAdvance(16, 5, 1, 3, false)); // 2*(5+1)
    try std.testing.expectEqual(@as(i16, 18), glyphAdvance(16, 5, 1, 3, true)); // + 2*3
    try std.testing.expectEqual(@as(i16, 2), trailingTrim(16, 1));
}
