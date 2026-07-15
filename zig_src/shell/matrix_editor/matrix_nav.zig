const frontier = @import("../../frontier.zig");
const frontier_matrix_editor = @import("matrix_editor.zig");
const FLAG_WRAPEND: c_uint = 0xc01a;
const FLAG_WRAPEDG: c_uint = 0xc03f;
const FLAG_GROW: c_uint = 0x801d;

pub const Axis = enum {
    row,
    col,
};

pub fn incDec(axis: Axis, mode: u16) void {
    switch (axis) {
        .row => frontier_matrix_editor.z47_frontier_matrix_inc_dec_i(mode),
        .col => frontier_matrix_editor.z47_frontier_matrix_inc_dec_j(mode),
    }
}

pub fn wrap(rows: u16, cols: u16) bool {
    clearSystemFlag(FLAG_WRAPEDG);
    clearSystemFlag(FLAG_WRAPEND);

    if (frontier.getIRegisterAsInt(true) < 0) {
        wrapNegativeRow(rows, cols);
    } else if (frontier.getIRegisterAsInt(true) == @as(i16, @intCast(rows))) {
        wrapOverflowRow(rows, cols);
    }

    if (frontier.getJRegisterAsInt(true) < 0) {
        wrapNegativeCol(rows, cols);
    } else if (frontier.getJRegisterAsInt(true) == @as(i16, @intCast(cols))) {
        wrapOverflowCol(rows, cols);
    }

    return frontier.getIRegisterAsInt(true) == @as(i16, @intCast(rows));
}

fn lastRow(rows: u16) i16 {
    return @as(i16, @intCast(rows - 1));
}

fn lastCol(cols: u16) i16 {
    return @as(i16, @intCast(cols - 1));
}

fn markWrapEdge() void {
    setSystemFlag(FLAG_WRAPEDG);
}

fn markWrapEnd() void {
    setSystemFlag(FLAG_WRAPEND);
}

fn atTopLeft() bool {
    return frontier.getIRegisterAsInt(true) == 0 and frontier.getJRegisterAsInt(true) == 0;
}

fn atBottomRight(rows: u16, cols: u16) bool {
    return frontier.getIRegisterAsInt(true) == lastRow(rows) and frontier.getJRegisterAsInt(true) == lastCol(cols);
}

fn advanceRowWithGrow(rows: u16) void {
    const reached_last_row = frontier.getIRegisterAsInt(true) == lastRow(rows);
    const should_wrap_to_top = !getSystemFlag(@as(c_int, @intCast(FLAG_GROW))) and reached_last_row;
    if (should_wrap_to_top) {
        frontier.setIRegisterAsInt(true, 0);
    } else {
        frontier.setIRegisterAsInt(true, frontier.getIRegisterAsInt(true) + 1);
    }
}

fn decrementRowWithBottomWrap(rows: u16) void {
    if (frontier.getIRegisterAsInt(true) == 0) {
        frontier.setIRegisterAsInt(true, lastRow(rows));
    } else {
        frontier.setIRegisterAsInt(true, frontier.getIRegisterAsInt(true) - 1);
    }
}

fn incrementColWithLeftWrap(cols: u16) void {
    if (frontier.getJRegisterAsInt(true) == lastCol(cols)) {
        frontier.setJRegisterAsInt(true, 0);
    } else {
        frontier.setJRegisterAsInt(true, frontier.getJRegisterAsInt(true) + 1);
    }
}

fn decrementColWithRightWrap(cols: u16) void {
    if (frontier.getJRegisterAsInt(true) == 0) {
        frontier.setJRegisterAsInt(true, lastCol(cols));
    } else {
        frontier.setJRegisterAsInt(true, frontier.getJRegisterAsInt(true) - 1);
    }
}

fn wrapNegativeRow(rows: u16, cols: u16) void {
    frontier.setIRegisterAsInt(true, lastRow(rows));
    markWrapEdge();
    decrementColWithRightWrap(cols);
    if (atBottomRight(rows, cols)) {
        markWrapEnd();
    }
}

fn wrapOverflowRow(rows: u16, cols: u16) void {
    _ = rows;
    frontier.setIRegisterAsInt(true, 0);
    markWrapEdge();
    incrementColWithLeftWrap(cols);
    if (atTopLeft()) {
        markWrapEnd();
    }
}

fn wrapNegativeCol(rows: u16, cols: u16) void {
    frontier.setJRegisterAsInt(true, lastCol(cols));
    markWrapEdge();
    decrementRowWithBottomWrap(rows);
    if (atBottomRight(rows, cols)) {
        markWrapEnd();
    }
}

fn wrapOverflowCol(rows: u16, cols: u16) void {
    _ = cols;
    frontier.setJRegisterAsInt(true, 0);
    markWrapEdge();
    advanceRowWithGrow(rows);
    if (atTopLeft()) {
        markWrapEnd();
    }
}

extern fn clearSystemFlag(sf: c_uint) void;
extern fn setSystemFlag(sf: c_uint) void;
extern fn getSystemFlag(sf: c_int) bool;
