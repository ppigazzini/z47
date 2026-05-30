const FLAG_GROW: c_uint = 0x801d;

const CM_MIM: u8 = 12;

const ERROR_OPERATION_UNDEFINED: u8 = 13;
const ERROR_OUT_OF_RANGE: u8 = 8;

const ITM_M_GOTO_ROW: i16 = 992;

const REGISTER_X: i16 = 100;
const REGISTER_Z: i16 = 102;

const ERR_REGISTER_LINE: i16 = REGISTER_Z;

pub fn goToElement() void {
    if (!ensureEditorMode()) {
        return;
    }

    mimEnter(false);
    runFunction(ITM_M_GOTO_ROW);
}

pub fn goToRow(row: u16) void {
    if (!ensureEditorMode()) {
        return;
    }

    tmpRow = row;
}

pub fn goToColumn(col: u16) void {
    if (!ensureEditorMode()) {
        return;
    }

    const row = tmpRow;
    if (!validateBounds(row, col)) {
        return;
    }

    z47_frontier_matrix_commit_open_to_register();
    setIRegisterAsInt(false, @as(i16, @intCast(row)));
    setJRegisterAsInt(false, @as(i16, @intCast(col)));
    z47_frontier_matrix_calc_mode_normal_gui();
}

pub fn setGrowMode(grow_flag: u16) void {
    if (grow_flag != 0) {
        setSystemFlag(FLAG_GROW);
    } else {
        clearSystemFlag(FLAG_GROW);
    }
}

fn ensureEditorMode() bool {
    if (calcMode == CM_MIM) {
        return true;
    }

    displayCalcErrorMessage(ERROR_OPERATION_UNDEFINED, ERR_REGISTER_LINE, REGISTER_X);
    return false;
}

fn validateBounds(row: u16, col: u16) bool {
    const rows = z47_frontier_matrix_open_rows();
    const cols = z47_frontier_matrix_open_cols();

    if (row == 0 or row > rows or col == 0 or col > cols) {
        displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
        return false;
    }

    return true;
}

extern var calcMode: u8;
extern var tmpRow: u16;

extern fn clearSystemFlag(sf: c_uint) void;
extern fn setSystemFlag(sf: c_uint) void;
extern fn z47_frontier_matrix_open_rows() u16;
extern fn z47_frontier_matrix_open_cols() u16;
extern fn z47_frontier_matrix_commit_open_to_register() void;
extern fn z47_frontier_matrix_calc_mode_normal_gui() void;
extern fn mimEnter(commit: bool) void;
extern fn runFunction(func: i16) void;
extern fn setIRegisterAsInt(as_array_pointer: bool, to_store: i16) void;
extern fn setJRegisterAsInt(as_array_pointer: bool, to_store: i16) void;
extern fn displayCalcErrorMessage(error_code: u8, err_message_register_line: i16, err_register_line: i16) void;