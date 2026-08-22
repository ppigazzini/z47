const matrix_lifecycle = @import("matrix_lifecycle.zig");
const frontier_matrix_editor = @import("matrix_editor.zig");
const frontier_screen = @import("../display/screen.zig");
const FLAG_ASLIFT: c_uint = 0xc023;

const ERROR_NONE: u8 = 0;
const ERROR_INVALID_DATA_TYPE_FOR_OP: u8 = 24;

const REGISTER_X: u16 = 100;

// The dyadic functions the editor stages a second operand for.
const ITM_YX: i16 = 60;
const ITM_XTHROOT: i16 = 63;
const ITM_ADD: i16 = 95;
const ITM_SUB: i16 = 96;
const ITM_MULT: i16 = 98;
const ITM_DIV: i16 = 99;
const ITM_DELTAPC: i16 = 1666;
const ITM_PC: i16 = 1695;

fn isDyadic(func: i16) bool {
    return switch (func) {
        ITM_ADD, ITM_SUB, ITM_MULT, ITM_DIV, ITM_PC, ITM_DELTAPC, ITM_YX, ITM_XTHROOT => true,
        else => false,
    };
}

const dtLongInteger: u32 = 0;
const dtReal34: u32 = 1;
const dtComplex34: u32 = 2;
const dtShortInteger: u32 = 8;

const Context = struct {
    lift_stack_flag: bool,
    converted: bool,
};

pub fn run(func: i16, param: u16) void {
    var ctx = Context{
        .lift_stack_flag = getSystemFlag(@as(c_int, @intCast(FLAG_ASLIFT))),
        .converted = false,
    };

    prepareExecution();
    const dyadic = isDyadic(func);
    stageDyadicOperand(dyadic);
    execute(func, param);
    if (dyadic) {
        frontier_matrix_editor.z47_frontier_matrix_restore_stack_above_x();
    }
    normalizeRegisterXType();
    ctx.converted = applyResultIfValid();
    restoreLinkedXIfNeeded(ctx.converted);
    restoreLiftFlag(ctx.lift_stack_flag);
    finalizeView();
}

fn prepareExecution() void {
    frontier_matrix_editor.z47_frontier_matrix_capture_selected_before();
    matrix_lifecycle.mimEnter(true);
    frontier_matrix_editor.z47_frontier_matrix_recheck_open_is_complex();
    clearSystemFlag(FLAG_ASLIFT);
    lastErrorCode = ERROR_NONE;
    frontier_matrix_editor.z47_frontier_matrix_load_selected_into_register_x();
}

// An error in the editor destroys the undo buffer, so the stack is saved before
// the operation runs and Y upwards is put back from it afterwards.
fn stageDyadicOperand(dyadic: bool) void {
    saveForUndo();
    if (dyadic) {
        frontier_matrix_editor.z47_frontier_matrix_stage_dyadic_operand_in_y();
    }
}

fn execute(func: i16, param: u16) void {
    frontier_matrix_editor.z47_frontier_matrix_run_item_function(func, param);
}

fn normalizeRegisterXType() void {
    const register_type = frontier_matrix_editor.z47_frontier_matrix_register_type(REGISTER_X);
    switch (register_type) {
        dtLongInteger => frontier_matrix_editor.z47_frontier_matrix_convert_register_x_long_to_real34(),
        dtShortInteger => frontier_matrix_editor.z47_frontier_matrix_convert_register_x_short_to_real34(),
        dtReal34, dtComplex34 => {},
        else => lastErrorCode = ERROR_INVALID_DATA_TYPE_FOR_OP,
    }
}

fn applyResultIfValid() bool {
    if (lastErrorCode != ERROR_NONE) {
        return false;
    }
    return frontier_matrix_editor.z47_frontier_matrix_apply_register_x_to_selected();
}

fn restoreLinkedXIfNeeded(converted: bool) void {
    if (matrixIndex == REGISTER_X and !converted) {
        frontier_matrix_editor.z47_frontier_matrix_restore_saved_selected_if_x_and_not_converted();
    }
}

fn restoreLiftFlag(lift_stack_flag: bool) void {
    if (lift_stack_flag) {
        setSystemFlag(FLAG_ASLIFT);
    }
}

fn finalizeView() void {
    frontier_matrix_editor.z47_frontier_matrix_update_height_cache();
    _ = frontier_screen.refreshLcd(null);
}

extern var lastErrorCode: u8;
extern var matrixIndex: u16;

extern fn getSystemFlag(sf: c_int) bool;
extern fn clearSystemFlag(sf: c_uint) void;
extern fn setSystemFlag(sf: c_uint) void;
extern fn saveForUndo() void;
