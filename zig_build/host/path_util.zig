//! Path predicates -- the pure core of the host build's platform path handling.
//!
//! Detecting a Windows-style absolute path (drive letter, colon, slash) is a
//! pure string predicate. Lift it here for native coverage -- the platform
//! module otherwise pulls in build-graph state.

const std = @import("std");

/// Whether `path` looks like a Windows absolute path: `X:/` or `X:\`.
pub fn looksLikeWindowsAbsolutePath(path: []const u8) bool {
    return path.len >= 3 and std.ascii.isAlphabetic(path[0]) and path[1] == ':' and (path[2] == '/' or path[2] == '\\');
}

test "recognizes drive-letter absolute paths" {
    try std.testing.expect(looksLikeWindowsAbsolutePath("C:/Users"));
    try std.testing.expect(looksLikeWindowsAbsolutePath("D:\\tmp"));
    try std.testing.expect(!looksLikeWindowsAbsolutePath("/usr/bin"));
    try std.testing.expect(!looksLikeWindowsAbsolutePath("C:"));
    try std.testing.expect(!looksLikeWindowsAbsolutePath("1:/x"));
    try std.testing.expect(!looksLikeWindowsAbsolutePath("relative/path"));
}
