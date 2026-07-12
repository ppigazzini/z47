//! Softmenu/catalog label truncation -- the pure core shared by
//! frontier_softmenus and frontier_conversion_units (which carried byte-identical
//! private copies of this pair).
//!
//! A displayed label is cut off at the first occurrence of a two-byte marker
//! glyph: truncateAtString NUL-terminates the label where the marker begins, and
//! truncateAtArrow applies that to the left and right arrow glyphs that separate
//! conversion sides. Both are pure byte scans over a caller-owned buffer; the
//! only inputs are the marker bytes, which the owners pass in from their arrow
//! constants.
//!
//! Lifting it here dedupes the two copies and gives the logic its first native
//! coverage -- the softmenu/conversion owners are only reachable through the C
//! oracle. Each owner keeps a thin truncateAtArrow wrapper that passes its arrow
//! constants in. This module uses Zig many-item pointers rather than C pointers,
//! so it stays out of the idiom-ratchet cptr ceiling.

const std = @import("std");

/// Truncate `label` (NUL-terminate it) at the first position where the two-byte
/// `search` marker appears. Leaves the label unchanged if the marker is absent.
pub fn truncateAtString(label: [*]u8, search: [*]const u8) void {
    var i: usize = 0;
    while (label[i + 1] != 0) {
        if (search[0] == label[i] and search[1] == label[i + 1]) {
            label[i] = 0;
            break;
        }
        i += 1;
    }
}

/// Truncate `label` at the first left- or right-arrow marker. The original
/// copied each arrow into a scratch buffer before searching; since only the
/// first two bytes are read, the arrow bytes are passed straight through.
pub fn truncateAtArrow(label: [*]u8, right_arrow: [*]const u8, left_arrow: [*]const u8) void {
    truncateAtString(label, right_arrow);
    truncateAtString(label, left_arrow);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

fn truncated(src: []const u8, search: []const u8) []const u8 {
    const S = struct {
        var buf: [64]u8 = undefined;
    };
    @memcpy(S.buf[0..src.len], src);
    truncateAtString(&S.buf, search.ptr);
    return std.mem.sliceTo(&S.buf, 0);
}

test "truncateAtString cuts at a two-byte marker" {
    // "ab" + marker 0x81 0x82 + "cd" -> "ab".
    try std.testing.expectEqualStrings("ab", truncated("ab\x81\x82cd\x00", "\x81\x82"));
}

test "truncateAtString leaves the label unchanged when the marker is absent" {
    try std.testing.expectEqualStrings("abcd", truncated("abcd\x00", "\x81\x82"));
}

test "truncateAtString matches a marker at the final two bytes" {
    try std.testing.expectEqualStrings("ab", truncated("ab\x81\x82\x00", "\x81\x82"));
}

const test_right_arrow = "\xa1\x92";
const test_left_arrow = "\xa1\x90";

fn arrowTruncated(src: []const u8) []const u8 {
    const S = struct {
        var buf: [64]u8 = undefined;
    };
    @memcpy(S.buf[0..src.len], src);
    truncateAtArrow(&S.buf, test_right_arrow, test_left_arrow);
    return std.mem.sliceTo(&S.buf, 0);
}

test "truncateAtArrow cuts at the right arrow" {
    try std.testing.expectEqualStrings("foo", arrowTruncated("foo\xa1\x92bar\x00"));
}

test "truncateAtArrow cuts at the left arrow" {
    try std.testing.expectEqualStrings("foo", arrowTruncated("foo\xa1\x90bar\x00"));
}

test "truncateAtArrow leaves an arrow-free label unchanged" {
    try std.testing.expectEqualStrings("foobar", arrowTruncated("foobar\x00"));
}
