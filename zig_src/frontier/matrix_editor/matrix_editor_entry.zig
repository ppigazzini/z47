const frontier = @import("../frontier.zig"); // M-callconv: Zig-to-Zig
const frontier_error = @import("../frontier_error.zig"); // M-callconv: Zig-to-Zig
const frontier_matrix_editor = @import("matrix_editor.zig"); // M-callconv: Zig-to-Zig
const frontier_print = @import("../print/print.zig"); // M-callconv: Zig-to-Zig
const frontier_screen = @import("../frontier_screen.zig"); // M-callconv: Zig-to-Zig
const frontier_tam = @import("../frontier_tam.zig"); // M-callconv: Zig-to-Zig
const NOPARAM: u16 = 9876;

const CM_MIM: u8 = 12;

const ERROR_OPERATION_UNDEFINED: u8 = 13;
const ERROR_INVALID_DATA_TYPE_FOR_OP: u8 = 24;

const REGISTER_X: i16 = 100;
const REGISTER_Z: i16 = 102;

const ERR_REGISTER_LINE: i16 = REGISTER_Z;
const NIM_REGISTER_LINE: i16 = REGISTER_X;

const MATRIX_EDITOR_REFRESH_SOURCE: u16 = 80;
const LINE_FULL: c_int = 0;

const dtReal34Matrix: u32 = 6;
const dtComplex34Matrix: u32 = 7;

pub fn edit(regist: u16) void {
    const reg: u16 = if (regist == NOPARAM) @as(u16, @intCast(REGISTER_X)) else regist;
    const dt = getRegisterDataType(@as(i16, @intCast(reg)));

    if (frontier_matrix_editor.z47_frontier_matrix_is_register_matrix_vector(reg) and frontier_matrix_editor.z47_frontier_matrix_vector_polar_mode(reg) != 0) {
        reportInvalidDataType();
        return;
    }

    frontier_tam.leaveTamModeIfEnabled();
    saveStatsMatrix();

    if (dt != dtReal34Matrix and dt != dtComplex34Matrix) {
        reportInvalidDataType();
        return;
    }

    calcMode = CM_MIM;
    matrixIndex = reg;
    getMatrixFromRegister(reg);

    frontier.setIRegisterAsInt(true, 0);
    frontier.setJRegisterAsInt(true, 0);
    aimBuffer[0] = 0;
    nimBufferDisplay[0] = 0;
    scrollRow = 0;
    scrollColumn = 0;

    frontier.showMatrixEditor();
    frontier_screen.refreshScreen(MATRIX_EDITOR_REFRESH_SOURCE);
    frontier_print.printTraceMatElement(@as(u16, @intCast(LINE_FULL)));
}

pub fn reloadOld() void {
    if (calcMode != CM_MIM) {
        reportOperationUndefined();
        return;
    }

    aimBuffer[0] = 0;
    nimBufferDisplay[0] = 0;
    frontier_matrix_editor.z47_frontier_matrix_hide_cursor();
    frontier_matrix_editor.z47_frontier_matrix_reload_open_matrix_from_register();
}

fn reportInvalidDataType() void {
    frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
}

fn reportOperationUndefined() void {
    frontier_error.displayCalcErrorMessage(ERROR_OPERATION_UNDEFINED, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
}

extern var calcMode: u8;
extern var matrixIndex: u16;
extern var aimBuffer: [*]u8;
extern var nimBufferDisplay: [*]u8;
extern var scrollRow: u16;
extern var scrollColumn: u16;

extern fn saveStatsMatrix() void;
extern fn getRegisterDataType(regist: i16) u32;
extern fn getMatrixFromRegister(regist: u16) void;
