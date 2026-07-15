//! System-flag classification and masking -- the pure core of flags.zig.
//!
//! Setting or clearing a system flag consults whether that flag forces a
//! screen-state refresh, extracts the 14-bit flag index, and tests the
//! write-protect bit. These are pure membership switches and bit masks over the
//! flag id. Lift them here for native coverage -- the flags owner mutates the
//! systemFlags word and is only exercised through the C oracle.

const std = @import("std");

/// Whether setting/clearing this system flag requires a screen-state refresh.
pub fn needsRefreshState(system_flag: u16) bool {
    return switch (system_flag) {
        0x8000,
        0xc001,
        0xc002,
        0xc003,
        0x8004,
        0x8017,
        0x8005,
        0x8006,
        0x800d,
        0x8009,
        0x800a,
        0x8018,
        0x801b,
        0x801c,
        0xc029,
        0x802b,
        0x8056,
        0x803c,
        0x8043,
        0x8044,
        0x8045,
        0x800b,
        0x800c,
        0x8041,
        0x8046,
        0xc00f,
        0x803d,
        0x8011,
        0x804b,
        0x804c,
        0x804d,
        0x804e,
        0x805a,
        0x804f,
        0x8050,
        0x8051,
        0x8052,
        0x8053,
        0x8054,
        0x8058,
        0x8064,
        0x8069, // FLAG_BOLD
        0x806a, // FLAG_SIGZEROS
        0x806b, // FLAG_PRMS
        0x806c, // FLAG_PINTG
        0x806d, // FLAG_PDIFF
        0x806e, // FLAG_PSHADE
        => true,
        else => false,
    };
}

/// The 14-bit flag index from a signed flag id.
pub fn maskedFlagFromSigned(sf: i32) i32 {
    return sf & 0x3fff;
}

/// The 14-bit flag index from an unsigned flag id.
pub fn maskedFlagFromUnsigned(sf: u16) i32 {
    return @as(i32, sf & 0x3fff);
}

/// Whether the write-protect bit (0x4000) is set on the flag id.
pub fn isWriteProtectedSystemFlag(flag: u16) bool {
    return (flag & 0x4000) != 0;
}

test "needsRefreshState recognizes members and rejects non-members" {
    try std.testing.expect(needsRefreshState(0x8000));
    try std.testing.expect(needsRefreshState(0x806a));
    try std.testing.expect(needsRefreshState(0xc001));
    try std.testing.expect(!needsRefreshState(0x1234));
    // A status-bar-clear flag is not a refresh flag.
    try std.testing.expect(!needsRefreshState(0x802c));
}

test "the masked flag keeps the low 14 bits" {
    try std.testing.expectEqual(@as(i32, 5), maskedFlagFromSigned(0x4005));
    try std.testing.expectEqual(@as(i32, 1), maskedFlagFromUnsigned(0xc001));
    try std.testing.expectEqual(@as(i32, 0x3fff), maskedFlagFromUnsigned(0xffff));
}

test "the write-protect bit is 0x4000" {
    try std.testing.expect(isWriteProtectedSystemFlag(0x4000));
    try std.testing.expect(isWriteProtectedSystemFlag(0xc001));
    try std.testing.expect(!isWriteProtectedSystemFlag(0x3fff));
    try std.testing.expect(!isWriteProtectedSystemFlag(0x8000));
}
