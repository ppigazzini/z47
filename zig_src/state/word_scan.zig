//! Whitespace word scanners -- the pure core of calc_state_text's skip/next-word
//! navigators.
//!
//! The save/restore text parser walks NUL-terminated lines word by word: skip
//! spaces, skip a word, jump to the next word, or stop at a space/newline. These
//! are pure pointer walks with no globals (the sibling integer parsers use libc
//! and stay in the owner). Lift the scanners here for native coverage. This
//! module uses Zig many-item pointers rather than C pointers, so it stays out of
//! the idiom-ratchet cptr ceiling.

const std = @import("std");

/// Advance past leading spaces.
pub fn skipSpace(s: [*]u8) [*]u8 {
    var p = s;
    while (p[0] == ' ') p += 1;
    return p;
}

/// Advance past the current word (to the next space or terminator).
pub fn skipWord(s: [*]u8) [*]u8 {
    var p = s;
    while (p[0] != ' ' and p[0] != 0) p += 1;
    return p;
}

/// Advance to the start of the next word.
pub fn nextWord(s: [*]u8) [*]u8 {
    return skipWord(skipSpace(s));
}

/// Advance to the next space, newline, or terminator.
pub fn skipToSpaceNewline(s: [*]u8) [*]u8 {
    var p = s;
    while (p[0] != ' ' and p[0] != '\n' and p[0] != 0) p += 1;
    return p;
}

test "skipSpace skips leading spaces" {
    var buf = "   ab".*;
    try std.testing.expectEqualStrings("ab", std.mem.sliceTo(skipSpace(&buf), 0));
    var none = "ab".*;
    try std.testing.expectEqualStrings("ab", std.mem.sliceTo(skipSpace(&none), 0));
}

test "skipWord stops at the next space or terminator" {
    var buf = "ab cd".*;
    try std.testing.expectEqualStrings(" cd", std.mem.sliceTo(skipWord(&buf), 0));
    var last = "ab".*;
    try std.testing.expectEqualStrings("", std.mem.sliceTo(skipWord(&last), 0));
}

test "nextWord skips leading spaces then the current word to its trailing space" {
    // skipWord(skipSpace(s)): no leading spaces, so it skips "ab" and stops at the
    // spaces before the next word.
    var buf = "ab   cd ef".*;
    try std.testing.expectEqualStrings("   cd ef", std.mem.sliceTo(nextWord(&buf), 0));
    // With leading spaces, those are skipped first, then the word.
    var lead = "  ab cd".*;
    try std.testing.expectEqualStrings(" cd", std.mem.sliceTo(nextWord(&lead), 0));
}

test "skipToSpaceNewline stops at a newline" {
    var buf = "ab\ncd".*;
    try std.testing.expectEqualStrings("\ncd", std.mem.sliceTo(skipToSpaceNewline(&buf), 0));
}
