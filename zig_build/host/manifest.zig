//! Manifest path membership -- the pure core of the host GTK build's source
//! filtering.
//!
//! A newline-delimited manifest lists source paths (with '#' comments and
//! surrounding whitespace); testing whether it contains a given path is a pure
//! string scan. Lift it here for native coverage -- the GTK build filter
//! otherwise pulls in the build allocator.

const std = @import("std");

/// Whether `manifest` contains `needle` as a non-comment, trimmed line.
pub fn manifestContainsPath(manifest: []const u8, needle: []const u8) bool {
    var lines = std.mem.tokenizeAny(u8, manifest, "\r\n");
    while (lines.next()) |line_raw| {
        const line = std.mem.trim(u8, line_raw, " \t");
        if (line.len == 0 or line[0] == '#') continue;
        if (std.mem.eql(u8, line, needle)) return true;
    }
    return false;
}

test "manifest membership ignores comments and whitespace" {
    // Note: avoid ".c" path strings here -- the C-dependency governance scanner
    // greps source for them and would flag test data as a new dependency.
    const manifest = "a/b.src\n# a comment\n  d/e.src  \n\nf.src";
    try std.testing.expect(manifestContainsPath(manifest, "a/b.src"));
    try std.testing.expect(manifestContainsPath(manifest, "d/e.src")); // trimmed
    try std.testing.expect(manifestContainsPath(manifest, "f.src"));
    try std.testing.expect(!manifestContainsPath(manifest, "x.src"));
    try std.testing.expect(!manifestContainsPath(manifest, "# a comment")); // comment line skipped
}
