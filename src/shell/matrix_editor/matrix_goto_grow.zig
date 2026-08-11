const abi = @import("abi");
const frontier_build_options = @import("frontier_build_options");
const matrix_lifecycle = @import("matrix_lifecycle.zig");
const frontier_error = @import("../error.zig");
const frontier_items = @import("../display/items/items.zig");
const frontier_matrix_editor = @import("matrix_editor.zig");

const extra_info: bool = frontier_build_options.extra_info_on_calc_error;
const ERROR_MESSAGE_LENGTH: usize = 512;

const FLAG_GROW: c_uint = 0x801d;

const ERROR_OUT_OF_RANGE: u8 = 8;

const ITM_M_GOTO_ROW: i16 = 992;

const REGISTER_X: i16 = 100;
const REGISTER_Z: i16 = 102;

const ERR_REGISTER_LINE: i16 = REGISTER_Z;

pub fn goToElement() void {
    if (!ensureEditorMode("In function fnGoToElement:")) {
        return;
    }

    matrix_lifecycle.mimEnter(false);
    frontier_items.runFunction(ITM_M_GOTO_ROW);
}

pub fn goToRow(row: u16) void {
    if (!ensureEditorMode("In function fnGoToRow:")) {
        return;
    }

    tmpRow = row;
}

pub fn goToColumn(col: u16) void {
    if (!ensureEditorMode("In function fnGoToColumn:")) {
        return;
    }

    const row = tmpRow;
    // C fnGoToColumn calls calcModeNormalGui() after BOTH the out-of-range
    // error branch and the success branch (it dismisses the GOTO input overlay
    // either way); only the register commit is gated on the bounds check.
    if (validateBounds(row, col)) {
        frontier_matrix_editor.z47_frontier_matrix_commit_open_to_register();
        frontier_matrix_editor.setIRegisterAsInt(false, @as(i16, @intCast(row)));
        frontier_matrix_editor.setJRegisterAsInt(false, @as(i16, @intCast(col)));
    }
    frontier_matrix_editor.z47_frontier_matrix_calc_mode_normal_gui();
}

pub fn setGrowMode(grow_flag: u16) void {
    if (grow_flag != 0) {
        setSystemFlag(FLAG_GROW);
    } else {
        clearSystemFlag(FLAG_GROW);
    }
}

// Each of the three GOTO entry points names itself in the console hint it prints
// when it refuses outside CM_MIM.
fn ensureEditorMode(where: [*:0]const u8) bool {
    return frontier_matrix_editor.matrixEnsureEditorMode(where);
}

fn validateBounds(row: u16, col: u16) bool {
    const rows = frontier_matrix_editor.z47_frontier_matrix_open_rows();
    const cols = frontier_matrix_editor.z47_frontier_matrix_open_cols();

    if (row == 0 or row > rows or col == 0 or col > cols) {
        frontier_error.displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            // The hint prints the pair that was rejected, so the user can see
            // which of the two coordinates was out of range.
            abi.fmtBufZ(errorMessage[0..ERROR_MESSAGE_LENGTH], "({d}, {d}) out of range", .{ row, col });
            frontier_error.moreInfoOnErrorImpl("In function fnGoToColumn:", errorMessage, null, null);
        }
        return false;
    }

    return true;
}

extern var errorMessage: [*c]u8;
extern var tmpRow: u16;

extern fn clearSystemFlag(sf: c_uint) void;
extern fn setSystemFlag(sf: c_uint) void;
