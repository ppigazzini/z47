const solve_build_options = @import("solve_build_options");
const abi = @import("abi");

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
// decimal128 register value; fnMvarPlot only needs its address for the quiet
// range read, so treat the 16 bytes opaquely.
pub const real34_t = extern struct { bytes: [16]u8 };
pub const FIRST_LABEL: u16 = 2200; // INVALID_VARIABLE=2199 precedes FIRST_LABEL; the //2044 C comment is stale
pub const LAST_LABEL: u16 = 6999;
pub const REGISTER_X: calcRegister_t = 100;
pub const REGISTER_Y: calcRegister_t = 101;
pub const REGISTER_Z: calcRegister_t = 102;
pub const REGISTER_T: calcRegister_t = 103;
pub const INVALID_VARIABLE: u16 = 2199;
pub const FIRST_NAMED_VARIABLE: u16 = 256;
pub const LAST_NAMED_VARIABLE: u16 = 1999;
pub const ERR_REGISTER_LINE: calcRegister_t = REGISTER_Z;
pub const NIM_REGISTER_LINE: calcRegister_t = REGISTER_X;
pub const ERROR_NONE: u8 = 0;
pub const ERROR_LABEL_NOT_FOUND: u8 = 6;
pub const ERROR_OUT_OF_RANGE: u8 = 8;
pub const ERROR_INVALID_DATA_TYPE_FOR_OP: u8 = 24;
pub const ERROR_NO_PROGRAM_SPECIFIED: u8 = 54;
pub const FLAG_ENDPMT: u32 = 0xc029;
pub const SOLVER_STATUS_USES_FORMULA: u16 = 0x0100;
pub const SOLVER_STATUS_INTERACTIVE: u16 = 0x0002;
pub const SOLVER_STATUS_EQUATION_GRAPHER: u16 = 0x2000;
pub const SOLVER_STATUS_RPN_GRAPHER: u16 = 0x4000;
pub const SCRUPD_MANUAL_MENU: u8 = 4;

pub extern var currentSolverProgram: u16;
pub extern var currentSolverStatus: u16;
pub extern var currentSolverVariable: u16;
pub extern var numberOfLabels: u16;
pub extern var screenUpdatingMode: u8;
pub extern var lastErrorCode: u8;

pub extern fn getRegisterAsReal34Quiet(reg: calcRegister_t, val: *align(1) real34_t) bool;
pub extern fn saveForUndo() void;
pub extern fn fnUndo(unused_but_mandatory_parameter: u16) void;
pub extern fn fnPlotf(unused_but_mandatory_parameter: u16) void;
pub extern fn engineNestingRefused(isPlot: bool) callconv(.c) bool;
pub const refreshScreen = abi.host.requestRefresh; // routed through the host-callback boundary
pub extern fn adjustResult(res: calcRegister_t, drop_y: bool, set_cpx_res: bool, error_reg: calcRegister_t, op1: calcRegister_t, op2: calcRegister_t) void;

pub inline fn isNamedVariable(v: u16) bool {
    return v >= FIRST_NAMED_VARIABLE and v <= LAST_NAMED_VARIABLE;
}
pub inline fn isLabelOrStackRegister(v: u16) bool {
    return (v >= FIRST_LABEL and v <= LAST_LABEL) or (v >= REGISTER_X and v <= REGISTER_T);
}

pub extern fn letteredRegisterName(regist: calcRegister_t) u8;
// namedLabels_t label-scope selector (typeDefinitions.h): GLOBAL_LABELS ==
// STRING_LABEL_VARIABLE (253), LOCAL_LABELS == LOCAL_LABEL_VARIABLE (249),
// ALL_LABELS == 0.
pub const GLOBAL_LABELS: u8 = 253;
pub extern fn findNamedLabel(label_name: [*:0]const u8, label_type: u8) calcRegister_t;
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

const label_range = @import("label_range.zig"); // std-only label/register band predicates
inline fn labelBands() label_range.Bands {
    return .{ .first_label = FIRST_LABEL, .last_label = LAST_LABEL, .reg_x = REGISTER_X, .reg_t = REGISTER_T, .invalid_variable = INVALID_VARIABLE };
}
pub inline fn isLabel(label: u16) bool {
    return label_range.isLabel(labelBands(), label);
}

pub inline fn isStackRegister(label: u16) bool {
    return label_range.isStackRegister(labelBands(), label);
}

pub inline fn isInvalidVariable(variable: u16) bool {
    return label_range.isInvalidVariable(labelBands(), variable);
}

pub inline fn labelToProgram(label: u16) u16 {
    return label_range.labelToProgram(labelBands(), label);
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

// Heap for the working reals that upstream's REAL_T_ALLOC(name, 75) block takes
// off the solver frames (solve.c's solver, graph.c's complexSolver). Bound at
// ?*abi.Real rather than an untyped C pointer because a C void* converts to any
// object pointer, which keeps the call sites cast-free; REAL_SIZE_IN_BYTES(75) is
// @sizeOf(abi.Real). Same allocator as REAL_T_ALLOC/REAL_T_FREE.
extern fn malloc(size: usize) ?*abi.Real;
extern fn free(ptr: ?*abi.Real) void;

pub inline fn mallocReal() ?*abi.Real {
    return malloc(@sizeOf(abi.Real));
}

pub inline fn freeReal(ptr: ?*abi.Real) void {
    free(ptr);
}
