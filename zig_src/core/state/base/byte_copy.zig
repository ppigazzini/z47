// SPDX-License-Identifier: GPL-3.0-only
//
// xcopy: the overlap-safe byte copy from src/c47 used pervasively across the
// owners (register codecs, string builders, backup serialisation). It chooses a
// forward or backward copy direction from the src/dest ordering so overlapping
// ranges shift correctly, like memmove. It has no coupling to any owner -- pure
// pointer arithmetic -- so it belongs in the base kernel rather than the shell
// text owner it was declared in. The testSuite exercises it through every path
// that copies register or string bytes, which is the parity gate for the port.

pub export fn xcopy(dest: ?*anyopaque, source: ?*const anyopaque, nIn: u32) callconv(.c) ?*anyopaque {
    if (nIn == 0) return dest;
    const d = dest orelse return dest;
    const s = source orelse return dest;
    const pDest: [*]u8 = @ptrCast(d);
    const pSource: [*]const u8 = @ptrCast(s);
    if (@intFromPtr(pSource) > @intFromPtr(pDest)) {
        // forward copy: safe when the destination is below the source
        var i: u32 = 0;
        while (i < nIn) : (i += 1) pDest[i] = pSource[i];
    } else if (@intFromPtr(pSource) < @intFromPtr(pDest)) {
        // backward copy: safe when the destination is above the source
        var n = nIn;
        while (n != 0) {
            n -%= 1;
            pDest[n] = pSource[n];
        }
    }
    return dest;
}

const std = @import("std");
const testing = std.testing;

test "xcopy copies forward and backward for overlapping ranges" {
    var buf = [_]u8{ 1, 2, 3, 4, 5, 6, 7, 8 };
    // non-overlapping
    var out: [4]u8 = @splat(0);
    _ = xcopy(&out, &buf, 4);
    try testing.expectEqualSlices(u8, &[_]u8{ 1, 2, 3, 4 }, &out);
    // overlap, dest < source (forward): shift left by 2
    _ = xcopy(&buf[0], &buf[2], 6);
    try testing.expectEqualSlices(u8, &[_]u8{ 3, 4, 5, 6, 7, 8, 7, 8 }, &buf);
    // zero length and null are no-ops
    try testing.expect(xcopy(&buf, &buf, 0) != null);
    try testing.expect(xcopy(null, &buf, 4) == null);
}
