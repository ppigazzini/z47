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

    if (z47_frontier_matrix_is_register_matrix_vector(reg) and z47_frontier_matrix_vector_polar_mode(reg) != 0) {
        reportInvalidDataType();
        return;
    }

    leaveTamModeIfEnabled();
    saveStatsMatrix();

    if (dt != dtReal34Matrix and dt != dtComplex34Matrix) {
        reportInvalidDataType();
        return;
    }

    calcMode = CM_MIM;
    matrixIndex = reg;
    getMatrixFromRegister(reg);

    setIRegisterAsInt(true, 0);
    setJRegisterAsInt(true, 0);
    aimBuffer[0] = 0;
    nimBufferDisplay[0] = 0;

    showMatrixEditor();
    refreshScreen(MATRIX_EDITOR_REFRESH_SOURCE);
    printTraceMatElement(@as(u16, @intCast(LINE_FULL)));
}

pub fn reloadOld() void {
    if (calcMode != CM_MIM) {
        reportOperationUndefined();
        return;
    }

    aimBuffer[0] = 0;
    nimBufferDisplay[0] = 0;
    z47_frontier_matrix_hide_cursor();
    z47_frontier_matrix_reload_open_matrix_from_register();
}

fn reportInvalidDataType() void {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
}

fn reportOperationUndefined() void {
    displayCalcErrorMessage(ERROR_OPERATION_UNDEFINED, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
}

extern var calcMode: u8;
extern var matrixIndex: u16;
extern var aimBuffer: [*]u8;
extern var nimBufferDisplay: [*]u8;

extern fn z47_frontier_matrix_is_register_matrix_vector(regist: u16) bool;
extern fn z47_frontier_matrix_vector_polar_mode(regist: u16) u16;
extern fn z47_frontier_matrix_hide_cursor() void;
extern fn z47_frontier_matrix_reload_open_matrix_from_register() void;
extern fn leaveTamModeIfEnabled() void;
extern fn saveStatsMatrix() void;
extern fn getRegisterDataType(regist: i16) u32;
extern fn getMatrixFromRegister(regist: u16) void;
extern fn setIRegisterAsInt(as_array_pointer: bool, to_store: i16) void;
extern fn setJRegisterAsInt(as_array_pointer: bool, to_store: i16) void;
extern fn showMatrixEditor() void;
extern fn refreshScreen(source: u16) void;
extern fn printTraceMatElement(where: u16) void;
extern fn displayCalcErrorMessage(error_code: u16, line1: u16, line2: u16) void;