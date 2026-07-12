//! Matrix editor I/J cursor wrap -- the pure core of frontier_matrix_editor's
//! wrapIJImpl.
//!
//! After the matrix editor moves the (I,J) cursor it wraps the row/column indices
//! at the grid edges: stepping off the top/bottom rolls the row and adjusts the
//! column (and vice-versa), the GROW flag lets the row extend past the last row,
//! and the WRAPEDG / WRAPEND conditions report an edge wrap and a full
//! wrap-around. The index arithmetic is pure over the current (i, j), the grid
//! size, and the grow flag; the owner reads/writes REGISTER_I/J and the flags.
//! Lift it here for native coverage -- the matrix editor is only reachable
//! through the C oracle.

const std = @import("std");

/// The wrapped cursor plus the edge/end conditions and whether the row now sits
/// at the (one-past-last) rows index.
pub const WrapResult = struct {
    i: i16,
    j: i16,
    wrap_edge: bool,
    wrap_end: bool,
    at_rows: bool,
};

/// Wrap the (i, j) cursor over a `rows`x`cols` grid. `grow` keeps the row from
/// rolling when it steps off the bottom (the matrix may extend).
pub fn wrapIJ(i_in: i16, j_in: i16, rows: u16, cols: u16, grow: bool) WrapResult {
    const rows_i: i16 = @bitCast(rows);
    const cols_i: i16 = @bitCast(cols);
    const last_row: i16 = @intCast(@as(c_int, rows) - 1);
    const last_col: i16 = @intCast(@as(c_int, cols) - 1);

    var i = i_in;
    var j = j_in;
    var wrap_edge = false;
    var wrap_end = false;

    if (i < 0) {
        i = last_row;
        wrap_edge = true;
        j = if (j == 0) last_col else j - 1;
        if (j == last_col and i == last_row) wrap_end = true;
    } else if (i == rows_i) {
        i = 0;
        wrap_edge = true;
        j = if (j == last_col) 0 else j + 1;
        if (j == 0 and i == 0) wrap_end = true;
    }

    if (j < 0) {
        j = last_col;
        wrap_edge = true;
        i = if (i == 0) last_row else i - 1;
        if (j == last_col and i == last_row) wrap_end = true;
    } else if (j == cols_i) {
        j = 0;
        wrap_edge = true;
        i = if ((!grow) and (i == last_row)) 0 else i + 1;
        if (i == 0 and j == 0) wrap_end = true;
    }

    return .{ .i = i, .j = j, .wrap_edge = wrap_edge, .wrap_end = wrap_end, .at_rows = (i == rows_i) };
}

test "an interior cursor does not wrap" {
    const r = wrapIJ(1, 1, 3, 3, false);
    try std.testing.expectEqual(WrapResult{ .i = 1, .j = 1, .wrap_edge = false, .wrap_end = false, .at_rows = false }, r);
}

test "stepping off the bottom rolls the row and advances the column" {
    const r = wrapIJ(3, 1, 3, 3, false);
    try std.testing.expectEqual(WrapResult{ .i = 0, .j = 2, .wrap_edge = true, .wrap_end = false, .at_rows = false }, r);
}

test "stepping off the top rolls the row back and retreats the column" {
    const r = wrapIJ(-1, 1, 3, 3, false);
    try std.testing.expectEqual(WrapResult{ .i = 2, .j = 0, .wrap_edge = true, .wrap_end = false, .at_rows = false }, r);
}

test "stepping off the right wraps the column and advances the row" {
    const r = wrapIJ(1, 3, 3, 3, false);
    try std.testing.expectEqual(WrapResult{ .i = 2, .j = 0, .wrap_edge = true, .wrap_end = false, .at_rows = false }, r);
}

test "wrapping past the last cell reports the end" {
    const r = wrapIJ(3, 2, 3, 3, false);
    try std.testing.expectEqual(WrapResult{ .i = 0, .j = 0, .wrap_edge = true, .wrap_end = true, .at_rows = false }, r);
}
