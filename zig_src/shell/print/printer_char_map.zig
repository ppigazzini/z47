//! HP82240 printer character reverse lookup -- the pure core of frontier_print's
//! charMap.
//!
//! The IR printer path maps a Unicode code point back to the byte the HP82240
//! printer expects by scanning the fixed hp82240CharMap table. The control-range
//! symbols (indices 0..31) are only valid in printer-alpha mode; the high range
//! (indices 128..254) is always scanned. The scan is a pure linear search over a
//! const table with the high 0x8000 bit stripped from the query; the only global
//! it reads is lastFunc (to decide alpha mode). Lifting it here gives the lookup
//! native coverage independent of the C oracle -- the print owner is
//! testSuite-blind. This mirrors the existing findPrinterGlyph delegation to
//! printer_glyph_search: the owner passes the table pointer and the alpha-mode
//! flag in, this module owns the search.

const std = @import("std");

/// Reverse-map a Unicode code point to its HP82240 printer byte.
///
/// The high 0x8000 bit is stripped from `char_code` before comparison. When
/// `alpha_mode` is true the control range (indices 0..31) is searched first;
/// the high range (indices 128..254 inclusive) is always searched. Returns the
/// matching index, or 0 when the code point is not printable.
pub fn charMap(table: []const u16, alpha_mode: bool, char_code: u16) u8 {
    const target = char_code & ~@as(u16, 0x8000);

    if (alpha_mode) { // map control-char symbols only for pr_alpha
        var j: u32 = 0;
        while (j < 32) : (j += 1) { // characters below 0x20
            if (table[j] == target) {
                return @intCast(j);
            }
        }
    }

    var i: u32 = 128;
    while (i < 255) : (i += 1) { // characters above 0x80
        if (table[i] == target) {
            return @intCast(i);
        }
    }

    return 0;
}

// A 256-entry synthetic table with unique markers so the branch logic is
// exercised without coupling the test to the real font map's exact bytes. The
// filler 0xFFFF is never queried, so an unmatched query still returns 0.
fn testTable() [256]u16 {
    var t: [256]u16 = undefined;
    for (&t) |*e| e.* = 0xFFFF;
    t[5] = 0x0105; // control range (alpha-only)
    t[31] = 0x011F; // last control-range index
    t[100] = 0x0164; // mid range, never scanned
    t[200] = 0x01C8; // high range (always scanned)
    t[255] = 0x01FF; // just past the exclusive high-range bound
    return t;
}

test "alpha mode finds a control-range symbol; non-alpha skips it" {
    const t = testTable();
    try std.testing.expectEqual(@as(u8, 5), charMap(&t, true, 0x0105));
    try std.testing.expectEqual(@as(u8, 31), charMap(&t, true, 0x011F));
    // Control-range values are invisible without alpha mode (and are not in the
    // high range) so the lookup falls through to 0.
    try std.testing.expectEqual(@as(u8, 0), charMap(&t, false, 0x0105));
}

test "high-range symbols are found in both modes" {
    const t = testTable();
    try std.testing.expectEqual(@as(u8, 200), charMap(&t, false, 0x01C8));
    try std.testing.expectEqual(@as(u8, 200), charMap(&t, true, 0x01C8));
}

test "the 0x8000 marker bit is stripped before comparison" {
    const t = testTable();
    try std.testing.expectEqual(@as(u8, 5), charMap(&t, true, 0x8105));
    try std.testing.expectEqual(@as(u8, 200), charMap(&t, false, 0x81C8));
}

test "mid range is never scanned and index 255 is past the exclusive bound" {
    const t = testTable();
    // 32..127 is scanned by neither branch.
    try std.testing.expectEqual(@as(u8, 0), charMap(&t, true, 0x0164));
    // The high-range loop stops before index 255.
    try std.testing.expectEqual(@as(u8, 0), charMap(&t, false, 0x01FF));
}

test "an unmapped code point returns 0" {
    const t = testTable();
    try std.testing.expectEqual(@as(u8, 0), charMap(&t, true, 0x2222));
}
