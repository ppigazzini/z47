// SPDX-License-Identifier: GPL-3.0-only
//! Pure two-byte-glyph -> replacement-string table lookup lifted out of
//! frontier_char_string.zig (getText / getTextRTF in src/c47/charString.c). The
//! owner keeps its two translation tables (indexOfStringsASCII with 148 entries,
//! indexOfStringsRTF with 2), which stay in their firmware code-data section;
//! the scan-and-append logic that both getText and getTextRTF duplicated moves
//! here and is parameterised by whichever table the caller passes.
//!
//! The table is taken as `anytype` -- any slice whose entries expose `.item_in`
//! (a byte pointer indexable at [0]/[1]) and `.item_out` (a NUL-terminated byte
//! pointer) -- so the module needs neither the owner's entry type nor a C
//! pointer spelling, and imports only std. These feed clipboard/file text
//! export (stringToASCII / stringToRTF), which the testSuite does not drive, so
//! the native tests below are the lookup's first automated coverage.

const std = @import("std");

/// Clear `out`, then scan `table` for the two-byte glyph (a1, a2); on the first
/// matching entry append its `item_out` to `out` and stop. Returns true when a
/// mapping was found (and `out` now holds it), false when none matched (and
/// `out` is left empty). Mirrors getText / getTextRTF byte-for-byte.
pub fn lookupGlyphText(a1: u8, a2: u8, out: [*]u8, table: anytype) bool {
    out[0] = 0;
    for (table) |entry| {
        if (a1 == entry.item_in[0] and a2 == entry.item_in[1]) {
            appendCStr(out, entry.item_out);
            break;
        }
    }
    return out[0] != 0;
}

/// Append the NUL-terminated `src` onto the NUL-terminated `dest` in place.
/// `src` is `anytype` so the module stays free of any C-pointer spelling.
fn appendCStr(dest: [*]u8, src: anytype) void {
    var d: usize = 0;
    while (dest[d] != 0) d += 1;
    var s: usize = 0;
    while (src[s] != 0) : (s += 1) {
        dest[d] = src[s];
        d += 1;
    }
    dest[d] = 0;
}

const testing = std.testing;

const TestEntry = struct {
    item_in: [:0]const u8,
    item_out: [:0]const u8,
};

const test_table = [_]TestEntry{
    .{ .item_in = "\xa1\x02", .item_out = "deg" },
    .{ .item_in = "\xb3\x04", .item_out = "<>" },
};

test "lookupGlyphText appends the mapped string on a match" {
    var out: [16]u8 = undefined;
    try testing.expect(lookupGlyphText(0xa1, 0x02, &out, &test_table));
    try testing.expectEqualStrings("deg", std.mem.sliceTo(&out, 0));
}

test "lookupGlyphText matches a later entry too" {
    var out: [16]u8 = undefined;
    try testing.expect(lookupGlyphText(0xb3, 0x04, &out, &test_table));
    try testing.expectEqualStrings("<>", std.mem.sliceTo(&out, 0));
}

test "lookupGlyphText returns false and empties out when nothing matches" {
    var out: [16]u8 = undefined;
    out[0] = 'X';
    out[1] = 'Y';
    out[2] = 0;
    try testing.expect(!lookupGlyphText(0x00, 0x00, &out, &test_table));
    try testing.expectEqual(@as(u8, 0), out[0]);
}

test "lookupGlyphText needs BOTH bytes to match, not just the lead" {
    var out: [16]u8 = undefined;
    // lead byte 0xa1 matches entry 0, but the second byte differs.
    try testing.expect(!lookupGlyphText(0xa1, 0x99, &out, &test_table));
    try testing.expectEqual(@as(u8, 0), out[0]);
}
