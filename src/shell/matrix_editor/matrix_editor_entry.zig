const abi = @import("abi");
const frontier_build_options = @import("frontier_build_options");
const matrix_editor_refresh = @import("matrix_editor_refresh.zig");
const frontier_error = @import("../error.zig");
const frontier_matrix_editor = @import("matrix_editor.zig");
const frontier_print = @import("../print/print.zig");
const frontier_screen = @import("../display/screen.zig");
const frontier_tam = @import("../input/tam.zig");

const extra_info: bool = frontier_build_options.extra_info_on_calc_error;
const ERROR_MESSAGE_LENGTH: usize = 512;

const NOPARAM: u16 = 9876;

const CM_MIM: u8 = 12;

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
        reportInvalidDataType(dt, "Cannot edit polar format as a matrix.");
        return;
    }

    frontier_tam.leaveTamModeIfEnabled();
    saveStatsMatrix();

    if (dt != dtReal34Matrix and dt != dtComplex34Matrix) {
        reportInvalidDataType(dt, "is not a matrix.");
        return;
    }

    calcMode = CM_MIM;
    matrixIndex = reg;
    getMatrixFromRegister(reg);

    frontier_matrix_editor.setIRegisterAsInt(true, 0);
    frontier_matrix_editor.setJRegisterAsInt(true, 0);
    aimBuffer[0] = 0;
    nimBufferDisplay[0] = 0;
    scrollRow = 0;
    scrollColumn = 0;

    matrix_editor_refresh.showMatrixEditor();
    // The refresh exists only so the trace has an up-to-date element to print;
    // fnEditMatrix wraps both in OPTION_IR_PRINTING, so on a package without the
    // IR printer neither happens.
    if (comptime frontier_print.ir_printing) {
        frontier_screen.refreshScreen(MATRIX_EDITOR_REFRESH_SOURCE);
        frontier_print.printTraceMatElement(@as(u16, @intCast(LINE_FULL)));
    }
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

/// fnEditMatrix refuses twice with the same error code but two different
/// reasons: a polar vector cannot be shown as a matrix, and a non-matrix is not
/// one. `reason` is the text that tells them apart on the console; the hint also
/// carries the data type that was refused.
fn reportInvalidDataType(data_type: u32, reason: [*:0]const u8) void {
    frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
    if (comptime extra_info) {
        abi.fmtBufZ(errorMessage[0..ERROR_MESSAGE_LENGTH], "DataType {d}", .{data_type});
        frontier_error.moreInfoOnErrorImpl("In function fnEditMatrix:", errorMessage, reason, "");
    }
}

fn reportOperationUndefined() void {
    frontier_matrix_editor.matrixModeUndefinedError("In function fnOldMatrix:");
}

extern var calcMode: u8;
extern var errorMessage: [*c]u8;
extern var matrixIndex: u16;
extern var aimBuffer: [*]u8;
extern var nimBufferDisplay: [*]u8;
extern var scrollRow: u16;
extern var scrollColumn: u16;

extern fn saveStatsMatrix() void;
extern fn getRegisterDataType(regist: i16) u32;
extern fn getMatrixFromRegister(regist: u16) void;

pub export fn fnEditMatrix(regist: u16) callconv(.c) void {
    edit(regist);
}
