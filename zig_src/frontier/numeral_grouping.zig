//! Digit-group separator placement -- the pure core of frontier_display's
//! IS_SEPARATOR_ family.
//!
//! When formatting a number for display, frontier_display decides after which
//! digits a group separator (the thousands-style mark) belongs. That decision is
//! pure integer arithmetic over the four grouping-width settings and the digit's
//! position: the leftmost group can have its own width (GR1) with an overflow
//! allowance, and the modulo test differs for the first group versus the rest.
//! The owner reads the settings from four extern globals; the arithmetic itself
//! touches no state.
//!
//! Lifting the arithmetic here gives it native coverage independent of the C
//! oracle -- the display owner is testSuite-blind. The owner keeps its thin
//! wrapper macros (GROUPWIDTH_LEFT1 / GROUP1_OVFL / IS_SEPARATOR_) so its many
//! call sites are unchanged; each wrapper reads the four globals into a Grouping
//! and delegates the math to this module.

const std = @import("std");

/// The four digit-grouping width settings, mirroring the extern globals
/// grpGroupingLeft / grpGroupingRight / grpGroupingGr1Left /
/// grpGroupingGr1LeftOverflow.
pub const Grouping = struct {
    /// GROUPWIDTH_LEFT: group width left of the radix.
    left: u8,
    /// GROUPWIDTH_RIGHT: group width right of the radix.
    right: u8,
    /// First (leftmost) group width; 0 means fall back to `left`.
    gr1_left: u8,
    /// Overflow allowance for the first group.
    gr1_overflow: u8,
};

/// GROUPWIDTH_LEFT1: the first (leftmost) group width, falling back to the
/// normal left width when the dedicated first-group width is 0.
pub fn groupWidthLeft1(g: Grouping) u16 {
    return if (g.gr1_left == 0) @as(u16, g.left) else @as(u16, g.gr1_left);
}

/// GROUPWIDTH_(digitCount): the left width for integer-side digits
/// (digit_count >= 0), the right width for fractional-side digits.
pub fn groupWidth(g: Grouping, digit_count: i32) i32 {
    return if (digit_count >= 0) @as(i32, g.left) else @as(i32, g.right);
}

/// digitCountNEW: shift the digit count past the first group so the ordinary
/// modulo test measures against the remaining groups.
pub fn digitCountNew(g: Grouping, digit_count: i32) i32 {
    const gwl1 = @as(i32, groupWidthLeft1(g));
    return if (digit_count + 1 > gwl1) digit_count - gwl1 else digit_count;
}

/// GROUP1_OVFL: the first-group overflow allowance, non-zero only exactly at the
/// first-group boundary when an overflow width is configured and the exponent
/// lands on that boundary too.
pub fn group1Overflow(g: Grouping, digit_count: i32, exp: i32) i32 {
    const gwl1 = @as(i32, groupWidthLeft1(g));
    if (g.gr1_overflow > 0 and exp == gwl1 and digit_count + 1 == gwl1) {
        return @as(i32, g.gr1_overflow);
    }
    return 0;
}

/// IS_SEPARATOR_: whether a group separator belongs after the digit at
/// `digit_count` (negative = right of the radix). The first-group boundary is
/// always a separator; past it (or on the fractional side) the position is a
/// separator when it lands one short of a full group width.
pub fn isSeparator(g: Grouping, digit_count: i32) bool {
    const gwl1 = @as(i32, groupWidthLeft1(g));
    if (digit_count + 1 == gwl1) return true;
    if (digit_count + 1 > gwl1 or digit_count < 0) {
        const gw = groupWidth(g, digit_count);
        return modulo(digitCountNew(g, digit_count), gw) == gw - 1;
    }
    return false;
}

/// Positive remainder, matching frontier_display's modulo helper.
fn modulo(n: i32, d: i32) i32 {
    const r = @rem(n, d);
    return if (r < 0) r + d else r;
}

const uniform3 = Grouping{ .left = 3, .right = 3, .gr1_left = 0, .gr1_overflow = 0 };

test "groupWidthLeft1 falls back to the left width when gr1 is 0" {
    try std.testing.expectEqual(@as(u16, 3), groupWidthLeft1(uniform3));
    const g = Grouping{ .left = 3, .right = 3, .gr1_left = 4, .gr1_overflow = 0 };
    try std.testing.expectEqual(@as(u16, 4), groupWidthLeft1(g));
}

test "groupWidth picks left for integer digits and right for fractional" {
    const g = Grouping{ .left = 3, .right = 2, .gr1_left = 0, .gr1_overflow = 0 };
    try std.testing.expectEqual(@as(i32, 3), groupWidth(g, 0));
    try std.testing.expectEqual(@as(i32, 3), groupWidth(g, 5));
    try std.testing.expectEqual(@as(i32, 2), groupWidth(g, -1));
}

test "digitCountNew shifts only once past the first group" {
    // gwl1 == 3. Below/at the boundary the count is unchanged; above it the
    // first group's width is subtracted.
    try std.testing.expectEqual(@as(i32, 2), digitCountNew(uniform3, 2));
    try std.testing.expectEqual(@as(i32, 0), digitCountNew(uniform3, 3));
    try std.testing.expectEqual(@as(i32, 2), digitCountNew(uniform3, 5));
}

test "isSeparator on the integer side with a uniform width of 3" {
    // First-group boundary (after 3 digits) is always a separator.
    try std.testing.expect(isSeparator(uniform3, 2));
    // Next boundary six digits in.
    try std.testing.expect(isSeparator(uniform3, 5));
    // Interior positions are not separators.
    try std.testing.expect(!isSeparator(uniform3, 0));
    try std.testing.expect(!isSeparator(uniform3, 3));
    try std.testing.expect(!isSeparator(uniform3, 4));
}

test "isSeparator on the fractional side groups every third digit" {
    // Negative counts use the positive modulo, so every third fractional digit
    // (-1, -4, -7) is a separator with a width of 3.
    try std.testing.expect(isSeparator(uniform3, -1));
    try std.testing.expect(isSeparator(uniform3, -4));
    try std.testing.expect(!isSeparator(uniform3, -2));
    try std.testing.expect(!isSeparator(uniform3, -3));
}

test "isSeparator honours a distinct first-group width" {
    // gr1_left = 4: the first separator lands after 4 digits, then every 3.
    const g = Grouping{ .left = 3, .right = 3, .gr1_left = 4, .gr1_overflow = 0 };
    try std.testing.expect(isSeparator(g, 3)); // dc+1 == gwl1 == 4
    try std.testing.expect(!isSeparator(g, 2));
    // Past the first group: digitCountNew(6) = 6 - 4 = 2, modulo(2,3) == 2.
    try std.testing.expect(isSeparator(g, 6));
}

test "group1Overflow is non-zero only at the first-group boundary" {
    const g = Grouping{ .left = 3, .right = 3, .gr1_left = 3, .gr1_overflow = 2 };
    // exp and digit_count+1 both land on gwl1 == 3.
    try std.testing.expectEqual(@as(i32, 2), group1Overflow(g, 2, 3));
    // Wrong exponent, wrong position, or no overflow configured -> 0.
    try std.testing.expectEqual(@as(i32, 0), group1Overflow(g, 2, 4));
    try std.testing.expectEqual(@as(i32, 0), group1Overflow(g, 1, 3));
    try std.testing.expectEqual(@as(i32, 0), group1Overflow(uniform3, 2, 3));
}
