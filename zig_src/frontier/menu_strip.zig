//! Menu-name stripping -- the pure core of frontier_softmenus' _stripMenuName.
//!
//! A soft-menu lookup name may carry a trailing page marker: a CR glyph (two
//! bytes) followed by a single page digit and a terminator. Stripping copies the
//! name up to the CR, and, when the marker is a lone page digit, records the page
//! number (digit value) and truncates there; any other CR use yields page 0. It
//! is a pure byte scan over the two buffers -- lift it here for native coverage.
//! This module uses Zig many-item pointers rather than C pointers, so it stays
//! out of the idiom-ratchet cptr ceiling.

const std = @import("std");

/// Copy `buffer` into `name` up to a CR page marker (bytes `cr0`,`cr1`), writing
/// a terminator. Returns the page number: 1 with no marker, the trailing digit
/// (`zero`+1 .. `nine`) when the marker is a lone page digit, or 0 otherwise.
pub fn stripMenuName(name: [*]u8, buffer: [*]const u8, cr0: u8, cr1: u8, zero: u8, nine: u8) i32 {
    var i: usize = 0;
    var page: i32 = 1;
    while (buffer[i] != 0) {
        if (buffer[i] == cr0 and buffer[i + 1] == cr1) {
            if (buffer[i + 3] == 0 and buffer[i + 2] > zero and buffer[i + 2] <= nine) {
                page = @as(i32, buffer[i + 2]) - @as(i32, zero);
            } else {
                page = 0;
            }
            break;
        }
        name[i] = buffer[i];
        i += 1;
    }
    name[i] = 0;
    return page;
}

fn strip(name: []u8, buffer: [:0]const u8) struct { out: []const u8, page: i32 } {
    const page = stripMenuName(name.ptr, buffer.ptr, 0xa1, 0xb5, '0', '9');
    return .{ .out = std.mem.sliceTo(name, 0), .page = page };
}

test "a bare name copies through with page 1" {
    var out: [16]u8 = undefined;
    const r = strip(&out, "MENU");
    try std.testing.expectEqualStrings("MENU", r.out);
    try std.testing.expectEqual(@as(i32, 1), r.page);
}

test "a CR + page digit truncates and records the page" {
    var out: [16]u8 = undefined;
    const r = strip(&out, "AB\xa1\xb5" ++ "3");
    try std.testing.expectEqualStrings("AB", r.out);
    try std.testing.expectEqual(@as(i32, 3), r.page);
}

test "a CR not followed by a lone page digit yields page 0" {
    var out: [16]u8 = undefined;
    const r = strip(&out, "AB\xa1\xb5" ++ "CD");
    try std.testing.expectEqualStrings("AB", r.out);
    try std.testing.expectEqual(@as(i32, 0), r.page);
}
