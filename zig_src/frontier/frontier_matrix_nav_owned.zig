const FLAG_WRAPEND: c_uint = 0xc01a;
const FLAG_WRAPEDG: c_uint = 0xc03f;
const FLAG_GROW: c_uint = 0x801d;

pub const Axis = enum {
    row,
    col,
};

pub fn incDec(axis: Axis, mode: u16) void {
    switch (axis) {
        .row => z47_frontier_matrix_inc_dec_i(mode),
        .col => z47_frontier_matrix_inc_dec_j(mode),
    }
}

pub fn wrap(rows: u16, cols: u16) bool {
    clearSystemFlag(FLAG_WRAPEDG);
    clearSystemFlag(FLAG_WRAPEND);

    if (getIRegisterAsInt(true) < 0) {
        wrapNegativeRow(rows, cols);
    } else if (getIRegisterAsInt(true) == @as(i16, @intCast(rows))) {
        wrapOverflowRow(rows, cols);
    }

    if (getJRegisterAsInt(true) < 0) {
        wrapNegativeCol(rows, cols);
    } else if (getJRegisterAsInt(true) == @as(i16, @intCast(cols))) {
        wrapOverflowCol(rows, cols);
    }

    return getIRegisterAsInt(true) == @as(i16, @intCast(rows));
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
    return getIRegisterAsInt(true) == 0 and getJRegisterAsInt(true) == 0;
}

fn atBottomRight(rows: u16, cols: u16) bool {
    return getIRegisterAsInt(true) == lastRow(rows) and getJRegisterAsInt(true) == lastCol(cols);
}

fn advanceRowWithGrow(rows: u16) void {
    const reached_last_row = getIRegisterAsInt(true) == lastRow(rows);
    const should_wrap_to_top = !getSystemFlag(@as(c_int, @intCast(FLAG_GROW))) and reached_last_row;
    if (should_wrap_to_top) {
        setIRegisterAsInt(true, 0);
    } else {
        setIRegisterAsInt(true, getIRegisterAsInt(true) + 1);
    }
}

fn decrementRowWithBottomWrap(rows: u16) void {
    if (getIRegisterAsInt(true) == 0) {
        setIRegisterAsInt(true, lastRow(rows));
    } else {
        setIRegisterAsInt(true, getIRegisterAsInt(true) - 1);
    }
}

fn incrementColWithLeftWrap(cols: u16) void {
    if (getJRegisterAsInt(true) == lastCol(cols)) {
        setJRegisterAsInt(true, 0);
    } else {
        setJRegisterAsInt(true, getJRegisterAsInt(true) + 1);
    }
}

fn decrementColWithRightWrap(cols: u16) void {
    if (getJRegisterAsInt(true) == 0) {
        setJRegisterAsInt(true, lastCol(cols));
    } else {
        setJRegisterAsInt(true, getJRegisterAsInt(true) - 1);
    }
}

fn wrapNegativeRow(rows: u16, cols: u16) void {
    setIRegisterAsInt(true, lastRow(rows));
    markWrapEdge();
    decrementColWithRightWrap(cols);
    if (atBottomRight(rows, cols)) {
        markWrapEnd();
    }
}

fn wrapOverflowRow(rows: u16, cols: u16) void {
    _ = rows;
    setIRegisterAsInt(true, 0);
    markWrapEdge();
    incrementColWithLeftWrap(cols);
    if (atTopLeft()) {
        markWrapEnd();
    }
}

fn wrapNegativeCol(rows: u16, cols: u16) void {
    setJRegisterAsInt(true, lastCol(cols));
    markWrapEdge();
    decrementRowWithBottomWrap(rows);
    if (atBottomRight(rows, cols)) {
        markWrapEnd();
    }
}

fn wrapOverflowCol(rows: u16, cols: u16) void {
    _ = cols;
    setJRegisterAsInt(true, 0);
    markWrapEdge();
    advanceRowWithGrow(rows);
    if (atTopLeft()) {
        markWrapEnd();
    }
}

extern fn clearSystemFlag(sf: c_uint) void;
extern fn setSystemFlag(sf: c_uint) void;
extern fn getSystemFlag(sf: c_int) bool;
extern fn getIRegisterAsInt(as_array_pointer: bool) i16;
extern fn getJRegisterAsInt(as_array_pointer: bool) i16;
extern fn setIRegisterAsInt(as_array_pointer: bool, to_store: i16) void;
extern fn setJRegisterAsInt(as_array_pointer: bool, to_store: i16) void;
extern fn z47_frontier_matrix_inc_dec_i(mode: u16) void;
extern fn z47_frontier_matrix_inc_dec_j(mode: u16) void;