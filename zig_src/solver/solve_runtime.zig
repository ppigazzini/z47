const solve_build_options = @import("solve_build_options");

// Heavy/cold solver owners (tvm, sumprod) run from executable QSPI (XIP) on the
// flash-limited DM42 old_hw firmware to keep main FLASH free; host/dmcp5/macOS
// keep the normal section (no-op there). Same mechanism as the math owners.
const dm42_pkg_xip = @hasDecl(solve_build_options, "dm42_pkg_xip") and solve_build_options.dm42_pkg_xip;
pub const code_section = if (dm42_pkg_xip)
    ".qspi_data"
else if (@import("builtin").target.os.tag == .macos)
    "__TEXT,__text"
else
    ".text";

pub const bool_t = bool;
pub const calcRegister_t = i16;
pub const FIRST_LABEL: u16 = 2200; // INVALID_VARIABLE=2199 precedes FIRST_LABEL; the //2044 C comment is stale
pub const LAST_LABEL: u16 = 6999;
pub const REGISTER_X: calcRegister_t = 100;
pub const REGISTER_Z: calcRegister_t = 102;
pub const REGISTER_T: calcRegister_t = 103;
pub const INVALID_VARIABLE: u16 = 2199;
pub const ERR_REGISTER_LINE: calcRegister_t = REGISTER_Z;
pub const ERROR_LABEL_NOT_FOUND: u8 = 6;
pub const ERROR_OUT_OF_RANGE: u8 = 8;
pub const FLAG_ENDPMT: u32 = 0xc029;
pub const SOLVER_STATUS_USES_FORMULA: u16 = 0x0100;

pub extern var currentSolverProgram: u16;
pub extern var currentSolverStatus: u16;

pub extern fn letteredRegisterName(regist: calcRegister_t) u8;
pub extern fn findNamedLabel(label_name: [*:0]const u8) calcRegister_t;
pub extern fn clearSystemFlag(flag: u32) void;
pub extern fn setSystemFlag(flag: u32) void;
pub extern fn displayCalcErrorMessage(error_code: u8, register_line: calcRegister_t, regist: calcRegister_t) void;
pub extern fn z47_solver_fnIntegrate(label_or_variable: u16) void;
pub extern fn z47_solver_fnIntegrateYX(label_or_variable: u16) void;
pub extern fn z47_solver_fnProgrammableSum(label: u16) void;
pub extern fn z47_solver_fnProgrammableProduct(label: u16) void;
pub extern fn z47_solver_fnProgrammableiSum(label: u16) void;
pub extern fn z47_solver_fnProgrammableiProduct(label: u16) void;
pub extern fn z47_solver_fn1stDeriv(label: u16) void;

pub inline fn isLabel(label: u16) bool {
    return FIRST_LABEL <= label and label <= LAST_LABEL;
}

pub inline fn isStackRegister(label: u16) bool {
    return REGISTER_X <= @as(calcRegister_t, @intCast(label)) and @as(calcRegister_t, @intCast(label)) <= REGISTER_T;
}

pub inline fn isInvalidVariable(variable: u16) bool {
    return variable == INVALID_VARIABLE;
}

pub inline fn labelToProgram(label: u16) u16 {
    return label - FIRST_LABEL;
}

pub inline fn reportLabelNotFound(buf: [*:0]const u8) void {
    _ = buf;
    displayCalcErrorMessage(ERROR_LABEL_NOT_FOUND, ERR_REGISTER_LINE, REGISTER_X);
}

pub inline fn reportOutOfRange(label: u16) void {
    _ = label;
    displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
}

pub inline fn reportLabelNotFoundPgmInt(buf: [*:0]const u8) void {
    _ = buf;
    displayCalcErrorMessage(ERROR_LABEL_NOT_FOUND, ERR_REGISTER_LINE, REGISTER_X);
}

pub inline fn reportOutOfRangePgmInt(label: u16) void {
    _ = label;
    displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
}

pub inline fn clearUsesFormulaStatus() void {
    currentSolverStatus &= ~SOLVER_STATUS_USES_FORMULA;
}

pub inline fn tvmBeginMode() void {
    clearSystemFlag(FLAG_ENDPMT);
}

pub inline fn tvmEndMode() void {
    setSystemFlag(FLAG_ENDPMT);
}
