//! Numeral -> display-string formatter -- the pure core of frontier_decode's
//! _decodeNumeral.
//!
//! _decodeNumeral rewrites a raw numeral ASCII string ("-1234.56e-7" form) into
//! the calculator's display string: it substitutes the radix mark, inserts the
//! left/right group separators at the configured group widths, and renders the
//! exponent as subscript-10 plus superscript-glyph digits. The byte-shuffling
//! loop is pure over its inputs; every setting it consults (the radix mark, the
//! two gap-character strings, the two group widths, the disabled flags, and the
//! product sign) is resolved from globals by the owner and handed in as a
//! Format. The const glyph tables (subscript-10, superscript-minus, superscript
//! digits) are passed in the same way, so this module touches no state and no C.
//!
//! Lifting the transform here gives the number formatter its first native
//! coverage -- the decode owner is only reachable through the C oracle. The
//! owner keeps the thin _decodeNumeral shim that reads the globals into a Format
//! and delegates. This module uses Zig many-item pointers rather than C
//! pointers by construction, so it stays out of the idiom-ratchet cptr ceiling.

const std = @import("std");

/// Fully-resolved display formatting, mirroring what _decodeNumeral read from
/// globals: the radix mark character, the group-separator enable flags and
/// widths, the two resolved gap-character strings (a byte of 1 in the second
/// position means "single-character separator, no trailing byte"), the product
/// sign, and the glyph tables for the exponent.
pub const Format = struct {
    /// radix34MarkChar(): the decimal mark to emit in place of the source '.'.
    radix_mark: u8,
    /// groupLeftDisabled(): suppress integer-side group separators.
    group_left_disabled: bool,
    /// groupRightDisabled(): suppress fractional-side group separators.
    group_right_disabled: bool,
    /// grpGroupingLeft: integer-side group width.
    group_width_left: u8,
    /// grpGroupingRight: fractional-side group width.
    group_width_right: u8,
    /// gapChar1Left(): integer-side separator bytes.
    gap_left: [*]const u8,
    /// gapChar1Right(): fractional-side separator bytes.
    gap_right: [*]const u8,
    /// productSign(): the two exponent product-sign bytes.
    product_sign: [*]const u8,
    /// STD_SUB_10: the two subscript-10 bytes.
    sub_10: [*]const u8,
    /// STD_SUP_MINUS: the two superscript-minus bytes.
    sup_minus: [*]const u8,
    /// supDigit: 10 superscript digit glyphs, two bytes each (index d*2, d*2+1).
    sup_digit: [*]const u8,
};

/// The advanced target and source pointers after a decode, matching
/// _decodeNumeral's updatedTgtPtr / updatedSrcPtr out-parameters.
pub const NumeralWrite = struct {
    tgt: [*]u8,
    src: [*]const u8,
};

fn absI(n: i32) i32 {
    return if (n < 0) -n else n;
}

/// Rewrite the NUL-terminated numeral at `src_start_ptr` into the display buffer
/// at `start_ptr`, writing a trailing NUL, and return the advanced pointers.
///
/// Byte-for-byte equivalent to _decodeNumeral: the destination buffer must have
/// room for the expanded string (the caller guarantees this, exactly as the C
/// path does -- there is no length here, matching the original raw-pointer
/// contract).
pub fn decodeNumeral(
    start_ptr: [*]u8,
    src_start_ptr: [*]const u8,
    is_long_int: bool,
    fmt: Format,
) NumeralWrite {
    var digit: i32 = 0;
    var strPtr: [*]u8 = start_ptr;
    var srcStr: [*]const u8 = src_start_ptr;

    if (srcStr[0] == '-') {
        srcStr += 1;
    }
    digit = 0;
    while ((srcStr[0] >= '0' and srcStr[0] <= '9') or (srcStr[0] >= 'A' and srcStr[0] <= 'F')) {
        digit += 1;
        srcStr += 1;
    }
    srcStr = src_start_ptr;

    if (srcStr[0] == '-') {
        strPtr[0] = srcStr[0];
        strPtr += 1;
        srcStr += 1;
    }
    while ((srcStr[0] >= '0' and srcStr[0] <= '9') or (srcStr[0] >= 'A' and srcStr[0] <= 'F') or srcStr[0] == '.' or srcStr[0] == ',') {
        if (digit == 0) {
            strPtr[0] = fmt.radix_mark;
            strPtr += 1;
            srcStr += 1;
        } else {
            if (!fmt.group_right_disabled and digit < -1 and @rem(absI(digit), @as(i32, fmt.group_width_right)) == 1) {
                const g = fmt.gap_right;
                strPtr[0] = g[0];
                strPtr += 1;
                if (g[1] != 1) {
                    strPtr[0] = g[1];
                    strPtr += 1;
                }
            }
            strPtr[0] = srcStr[0];
            strPtr += 1;
            srcStr += 1;
            if (!fmt.group_left_disabled and digit > 1 and @rem(digit, @as(i32, fmt.group_width_left)) == 1) {
                const g = fmt.gap_left;
                strPtr[0] = g[0];
                strPtr += 1;
                if (g[1] != 1) {
                    strPtr[0] = g[1];
                    strPtr += 1;
                }
            }
        }
        digit -= 1;
    }
    if (digit == 0 and !is_long_int) {
        strPtr[0] = fmt.radix_mark;
        strPtr += 1;
    }

    if (srcStr[0] == 'e') {
        srcStr += 1;
        strPtr[0] = fmt.product_sign[0];
        strPtr += 1;
        strPtr[0] = fmt.product_sign[1];
        strPtr += 1;
        strPtr[0] = fmt.sub_10[0];
        strPtr += 1;
        strPtr[0] = fmt.sub_10[1];
        strPtr += 1;
        if (srcStr[0] == '-') {
            strPtr[0] = fmt.sup_minus[0];
            strPtr += 1;
            strPtr[0] = fmt.sup_minus[1];
            strPtr += 1;
            srcStr += 1;
        } else if (srcStr[0] == '+') {
            srcStr += 1;
        }
        while (srcStr[0] >= '0' and srcStr[0] <= '9') {
            strPtr[0] = fmt.sup_digit[0 + @as(usize, srcStr[0] - '0') * 2];
            strPtr += 1;
            strPtr[0] = fmt.sup_digit[1 + @as(usize, srcStr[0] - '0') * 2];
            strPtr += 1;
            srcStr += 1;
        }
    } else if (srcStr[0] == '#') { // input not yet closed
        strPtr[0] = srcStr[0];
        strPtr += 1;
        srcStr += 1;
        while (srcStr[0] >= '0' and srcStr[0] <= '9') {
            strPtr[0] = srcStr[0];
            strPtr += 1;
            srcStr += 1;
        }
    }

    strPtr[0] = 0;
    return .{ .tgt = strPtr, .src = srcStr };
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

// A standard grouping Format: '.' radix, width-3 groups both sides, single-char
// ',' separators (second byte 1 => not emitted), and index-valued glyph tables
// so exponent output is easy to assert.
const sup_digit_table = blk: {
    var t: [24]u8 = undefined;
    for (&t, 0..) |*e, i| e.* = @intCast(i);
    break :blk t;
};
const std_fmt = Format{
    .radix_mark = '.',
    .group_left_disabled = false,
    .group_right_disabled = false,
    .group_width_left = 3,
    .group_width_right = 3,
    .gap_left = ",\x01",
    .gap_right = ",\x01",
    .product_sign = "\x80\xb7",
    .sub_10 = "\xa4\x7d",
    .sup_minus = "\xa1\x6b",
    .sup_digit = &sup_digit_table,
};

fn run(src: [:0]const u8, is_long_int: bool, fmt: Format) []const u8 {
    const S = struct {
        var buf: [128]u8 = undefined;
    };
    const w = decodeNumeral(&S.buf, src.ptr, is_long_int, fmt);
    const len = @intFromPtr(w.tgt) - @intFromPtr(&S.buf);
    return S.buf[0..len];
}

test "integer input groups the left side every three digits" {
    // is_long_int suppresses the trailing radix mark, so this is a clean group.
    try std.testing.expectEqualStrings("1,234", run("1234", true, std_fmt));
    try std.testing.expectEqualStrings("1,234,567", run("1234567", true, std_fmt));
}

test "the source radix is replaced by the configured radix mark" {
    var fmt = std_fmt;
    fmt.radix_mark = ':';
    try std.testing.expectEqualStrings("1:5", run("1.5", false, fmt));
}

test "the fractional side groups every three digits with the separator ahead of the digit" {
    try std.testing.expectEqualStrings("0.123,456", run("0.123456", false, std_fmt));
}

test "disabled grouping emits no separators" {
    var fmt = std_fmt;
    fmt.group_left_disabled = true;
    try std.testing.expectEqualStrings("1234", run("1234", true, fmt));
}

test "exponent renders product-sign, subscript-10, superscript-minus and digits" {
    const out = run("1.5e-3", false, std_fmt);
    // "1.5" then the two product-sign bytes, the two subscript-10 bytes, the two
    // superscript-minus bytes, then digit 3 -> sup_digit[6], sup_digit[7].
    const expected = [_]u8{ '1', '.', '5', 0x80, 0xb7, 0xa4, 0x7d, 0xa1, 0x6b, 6, 7 };
    try std.testing.expectEqualSlices(u8, &expected, out);
}

test "a positive exponent omits the superscript-minus" {
    const out = run("2e5", true, std_fmt);
    // no fractional radix (is_long_int), exponent 5 -> sup_digit[10], sup_digit[11].
    const expected = [_]u8{ '2', 0x80, 0xb7, 0xa4, 0x7d, 10, 11 };
    try std.testing.expectEqualSlices(u8, &expected, out);
}

test "the unclosed-input '#' branch copies the base digits verbatim" {
    try std.testing.expectEqualStrings("5#12", run("5#12", true, std_fmt));
}

test "a leading minus sign is preserved" {
    try std.testing.expectEqualStrings("-1,234", run("-1234", true, std_fmt));
}

test "a two-byte gap separator emits both bytes" {
    var fmt = std_fmt;
    fmt.gap_left = "\xa7\x88"; // second byte != 1, so both are emitted
    try std.testing.expectEqualStrings("1\xa7\x88234", run("1234", true, fmt));
}
