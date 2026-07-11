//! 24-dot glyph rotation -- the pure core of frontier_print's printGlyph24.
//!
//! The 24-dot printer wants a glyph rotated 90 degrees: the source is a row-major,
//! MSB-first bitmap (each row byte-aligned, restarting a fresh source byte), and
//! the target is a 42-byte column buffer where column `col` occupies bytes
//! col*3..col*3+2 and source row `row` maps to bit (row-1)%8 of byte
//! (24-row)/8. It is pure bit shuffling over the source bytes -- lift it here for
//! native coverage; the print owner resolves the glyph and emits the buffer. This
//! module uses Zig many-item pointers rather than C pointers, staying out of the
//! idiom-ratchet ceiling.

const std = @import("std");

/// Rotate a glyph bitmap into the 42-byte 24-dot column buffer `graphic`. `data`
/// is the source bitmap (row-major, MSB first, each row starting a fresh byte);
/// only rows `rows_below+1 .. rows_below+rows_glyph` and columns 0..cols_glyph
/// are emitted.
pub fn rotateGlyph24(graphic: *[42]u8, data_in: [*]const u8, rows_glyph: u8, rows_below: u8, cols_glyph: u8) void {
    @memset(graphic, 0);
    var data = data_in;
    var byte: u8 = 0;
    var row: u32 = @as(u32, rows_glyph) + @as(u32, rows_below);
    while (row > rows_below) : (row -= 1) {
        var bit: i32 = 7;
        var col: u32 = 0;
        while (col < cols_glyph) : (col += 1) {
            if (bit == 7) {
                byte = data[0];
                data += 1;
            }
            const graphic_byte: u32 = col * 3 + (24 - row) / 8;
            if (byte & 0x80 != 0) {
                graphic[graphic_byte] |= @as(u8, 1) << @intCast((row - 1) % 8);
            } else {
                graphic[graphic_byte] &= ~(@as(u8, 1) << @intCast((row - 1) % 8));
            }
            byte <<= 1;
            bit -= 1;
            if (bit == -1) {
                bit = 7;
            }
        }
    }
}

test "a single top-left pixel maps to its rotated bit" {
    // 1x1 glyph, no rows below, one set pixel (MSB of the single source byte).
    var g: [42]u8 = undefined;
    rotateGlyph24(&g, &[_]u8{0x80}, 1, 0, 1);
    // row=1, col=0 -> byte (24-1)/8 = 2, bit (1-1)%8 = 0.
    try std.testing.expectEqual(@as(u8, 1), g[2]);
    var zeros = true;
    for (g, 0..) |v, i| if (i != 2 and v != 0) {
        zeros = false;
    };
    try std.testing.expect(zeros);
}

test "a two-row column places bits in the same graphic byte" {
    // cols=1, rows=2, rows_below=0. Source: row-major, each row a fresh byte.
    // rows iterate 2 then 1. row=2: byte 0x80 -> graphic[(24-2)/8=2] bit (2-1)%8=1.
    // row=1: next byte 0x80 -> graphic[(24-1)/8=2] bit 0. So g[2] = 0b11 = 3.
    var g: [42]u8 = undefined;
    rotateGlyph24(&g, &[_]u8{ 0x80, 0x80 }, 2, 0, 1);
    try std.testing.expectEqual(@as(u8, 0b11), g[2]);
}

test "a cleared source pixel leaves its bit zero" {
    var g: [42]u8 = undefined;
    rotateGlyph24(&g, &[_]u8{0x00}, 1, 0, 1);
    try std.testing.expectEqual(@as(u8, 0), g[2]);
}
