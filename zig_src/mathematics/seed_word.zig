//! RNG seed-word read -- the pure core of math_random_seed's readSeedWord.
//!
//! Seeding the RNG reads a native-endian u64 out of an 8-byte window of the
//! decimal significand's byte buffer. The read is a pure byte decode. Lift it
//! here for native coverage -- the seed owner otherwise touches decimal values
//! and globals.

const std = @import("std");

/// Read a native-endian u64 from the 8 bytes at `offset` in `lsu_bytes`.
pub fn readSeedWord(lsu_bytes: *const [50]u8, offset: usize) u64 {
    const word_bytes: *const [8]u8 = @ptrCast(&lsu_bytes[offset]);
    return std.mem.readInt(u64, word_bytes, .native);
}

test "reads the native-endian u64 at the offset" {
    var buf: [50]u8 = undefined;
    @memset(&buf, 0);
    std.mem.writeInt(u64, buf[0..8], 0x0123456789abcdef, .native);
    std.mem.writeInt(u64, buf[8..16], 0xfeedface_cafebabe, .native);
    try std.testing.expectEqual(@as(u64, 0x0123456789abcdef), readSeedWord(&buf, 0));
    try std.testing.expectEqual(@as(u64, 0xfeedface_cafebabe), readSeedWord(&buf, 8));
}
