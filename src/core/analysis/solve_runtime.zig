const std = @import("std");
const solve_build_options = @import("solve_build_options");
const abi = @import("abi");

// Heavy/cold solver owners (tvm, sumprod) run from executable QSPI (XIP) on the
// flash-limited DM42 old_hw firmware to keep main FLASH free; host/dmcp5/macOS
// keep the normal section (no-op there). Same mechanism as the math owners.
const dm42_pkg_xip = @hasDecl(solve_build_options, "dm42_pkg_xip") and solve_build_options.dm42_pkg_xip;

/// defines.h's OPTION_INFSUMS: the infinity sum and the early stop it carries. The
/// plain programmable sum and product are outside it. Enabled by default and
/// #undef'd in the same DM42 TWO_FILE block as OPTION_XFN_1000 and OPTION_SLVP_POLY
/// (400 bytes of flash), so it is off for exactly the same builds. Absent from a
/// harness's options => on, matching the host default.
pub const option_infsums = !@hasDecl(solve_build_options, "option_infsums") or solve_build_options.option_infsums;

/// defines.h's OPTION_TVM_FORMULAS: tvm.c's analytical closed forms and the
/// fnTvmVar arm that tries them before the iterative solver. #undef'd for DM42
/// packages 2 and 4, whose FIN application is therefore solver-only.
pub const option_tvm_formulas = solve_build_options.option_tvm_formulas;

/// defines.h's OPTION_TVM_NEWTON: the Newton-Raphson method inside solve.c's
/// solver() and the derivatives tvmEquation supplies it with. #undef'd for the
/// same two packages, which makes their FIN solver brent-only.
pub const option_tvm_newton = solve_build_options.option_tvm_newton;
pub const code_section = if (dm42_pkg_xip)
    ".qspi_data"
else if (@import("builtin").target.os.tag == .macos)
    "__TEXT,__text"
else
    ".text";

pub const bool_t = bool;
pub const calcRegister_t = i16;
// decimal128 register value. The shared abi spelling, not a private 16-byte
// struct, so the progress panel can hand the register values it reads straight
// to the display entry points below.
pub const real34_t = abi.Real34;
/// The display's opaque font handle (fonts.h): owners only ever take its address.
pub const font_t = opaque {};
pub const FIRST_LABEL: u16 = 2200; // INVALID_VARIABLE=2199 precedes FIRST_LABEL; the //2044 C comment is stale
pub const LAST_LABEL: u16 = 6999;
pub const FIRST_UC_LOCAL_LABEL: u16 = 100; // A, the first upper-case local label
pub const LAST_LOCAL_LABEL: u16 = 123; // l, the last lower-case local label
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

pub extern fn getRegisterDataType(reg: calcRegister_t) u32;
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
// The operand band the interactive arm of SOLVE, the integral, PLT f and the derivatives accept: a local label A to l as
// well as a global label or a lettered register. The local-label band starts at FIRST_UC_LOCAL_LABEL and already covers
// REGISTER_X..REGISTER_T, which findProgramLabel resolves as local labels first.
pub inline fn isLocalLabelOrLabelOrStackRegister(v: u16) bool {
    return (v >= FIRST_UC_LOCAL_LABEL and v <= LAST_LOCAL_LABEL) or isLabelOrStackRegister(v);
}

pub extern fn letteredRegisterName(regist: calcRegister_t) u8;
// namedLabels_t label-scope selector (typeDefinitions.h): GLOBAL_LABELS ==
// STRING_LABEL_VARIABLE (253), LOCAL_LABELS == LOCAL_LABEL_VARIABLE (249),
// ALL_LABELS == 0.
pub const GLOBAL_LABELS: u8 = 253;
pub extern fn findNamedLabel(label_name: [*:0]const u8, label_type: u8) calcRegister_t;
// manage.c findProgramLabel: resolves a local label, an already-resolved named label or a lettered register to a label
// list index, reporting the reason itself. INVALID_VARIABLE means "already reported".
pub extern fn findProgramLabel(label: u16, caller: [*:0]const u8) calcRegister_t;
pub extern fn clearSystemFlag(flag: u32) void;
pub extern fn setSystemFlag(flag: u32) void;
pub extern fn displayCalcErrorMessage(error_code: u8, register_line: calcRegister_t, regist: calcRegister_t) void;
pub extern fn z47_solver_fnIntegrate(label_or_variable: u16) void;
pub extern fn z47_solver_fnIntegrateYX(label_or_variable: u16) void;
pub extern fn z47_solver_fnProgrammableSum(label: u16) void;
pub extern fn z47_solver_fnProgrammableProduct(label: u16) void;
pub extern fn z47_solver_fnProgrammableiSum(label: u16) void;
pub extern fn z47_solver_fnProgrammableiProduct(label: u16) void;

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

// Console diagnostics (EXTRA_INFO_ON_CALC_ERROR). The C sprintf()s each message
// into the shared errorMessage scratch and hands it to moreInfoOnError, which
// only prints it; the text is formatted into a caller-local buffer here so the
// scratch is left alone.
pub extern fn moreInfoOnError(m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) void;

// The display surface the solver, the integrator and the sum/product engines
// paint their live value panel with (progress_panel.zig). displayFormatDigits is
// saved and restored around each panel, so the panel's own 34-digit reading does
// not outlive it.
pub extern var displayFormat: u8;
pub extern var displayFormatDigits: u8;
pub extern var tmpString: [*c]u8;
pub extern const standardFont: font_t;
pub extern fn clearRegisterLine(regist: calcRegister_t, clear_top: bool, clear_bottom: bool) void;
pub extern fn showString(str: [*c]const u8, font: *const font_t, x: u32, y: u32, video_mode: c_int, show_leading_cols: bool, show_ending_cols: bool) u32;
pub extern fn real34ToDisplayString(real34: *align(1) const real34_t, tag: u32, display_string: [*c]u8, font: *const font_t, max_width: i16, display_has_n_digits: i16, limit_exponent: bool, front_space: bool, limit_irfrac: c_int) void;
pub extern fn longIntegerRegisterToDisplayString(regist: calcRegister_t, display_string: [*c]u8, str_lg: i32, max_width: i16, max_exp: i16, allow_large_li: bool) void;
pub extern fn convertLongIntegerToLongIntegerRegister(op: *const abi.Mpz, destination: calcRegister_t) void;
pub extern fn force_refresh(mode: u8) void;
pub extern fn getSystemFlag(sf: c_int) bool;
pub extern fn strcat(dest: [*c]u8, src: [*c]const u8) [*c]u8;
pub extern fn real34CompareGreaterThan(x: *align(1) const real34_t, y: *align(1) const real34_t) bool;
pub extern fn real34CompareGreaterEqual(x: *align(1) const real34_t, y: *align(1) const real34_t) bool;
// decQuad predicates return decNumber's 0/nonzero, not a bool.
pub extern fn decQuadIsNaN(v: *align(1) const real34_t) u32;
pub extern fn decQuadIsSignaling(v: *align(1) const real34_t) u32;
pub extern fn decQuadIsInfinite(v: *align(1) const real34_t) u32;
pub extern fn decQuadIsZero(v: *align(1) const real34_t) u32;

pub fn bufPrintZ(buffer: []u8, comptime format: []const u8, args: anytype) ![:0]u8 {
    const slice = try std.fmt.bufPrint(buffer[0 .. buffer.len - 1], format, args);
    buffer[slice.len] = 0;
    return buffer[0..slice.len :0];
}

pub fn infoNotANamedLabel(fnName: [*:0]const u8, buf: [*:0]const u8) void {
    var buffer: [80]u8 = undefined;
    const message = bufPrintZ(&buffer, "string '{s}' is not a named label", .{buf}) catch "string is not a named label";
    moreInfoOnError(fnName, message, null, null);
}

pub fn infoUnexpectedParameter(fnName: [*:0]const u8, label: u16) void {
    var buffer: [40]u8 = undefined;
    const message = bufPrintZ(&buffer, "unexpected parameter {d}", .{label}) catch "unexpected parameter";
    moreInfoOnError(fnName, message, null, null);
}

pub fn infoLabelNotFound(fnName: [*:0]const u8, labelOrVariable: u16) void {
    var buffer: [40]u8 = undefined;
    const message = bufPrintZ(&buffer, "label {d} not found", .{labelOrVariable}) catch "label not found";
    moreInfoOnError(fnName, message, null, null);
}

/// The four-argument form: the trailing "" is an empty string, not NULL, so
/// moreInfoOnError takes its four-part branch.
pub fn infoNotARealNumber(fnName: [*:0]const u8, dataType: u32) void {
    var buffer: [40]u8 = undefined;
    const message = bufPrintZ(&buffer, "DataType {d}", .{dataType}) catch "DataType";
    moreInfoOnError(fnName, message, "is not a real number.", "");
}

pub inline fn reportLabelNotFound(buf: [*:0]const u8) void {
    displayCalcErrorMessage(ERROR_LABEL_NOT_FOUND, ERR_REGISTER_LINE, REGISTER_X);
    infoNotANamedLabel("In function fnPgmSlv:", buf);
}

pub inline fn reportOutOfRange(label: u16) void {
    displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
    infoUnexpectedParameter("In function fnPgmSlv:", label);
}

pub inline fn reportLabelNotFoundPgmInt(buf: [*:0]const u8) void {
    displayCalcErrorMessage(ERROR_LABEL_NOT_FOUND, ERR_REGISTER_LINE, REGISTER_X);
    infoNotANamedLabel("In function fnPgmInt:", buf);
}

pub inline fn reportOutOfRangePgmInt(label: u16) void {
    displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
    infoUnexpectedParameter("In function fnPgmInt:", label);
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

// comparisonReals.c's real_t orderings, declared once for the whole solver object.
// Five owners in it each carried their own copy of these two, which is five chances
// for the signatures to drift apart against one C definition.
pub extern fn realCompareLessThan(number1: *align(1) const abi.Real, number2: *align(1) const abi.Real) bool;
pub extern fn realCompareGreaterThan(number1: *align(1) const abi.Real, number2: *align(1) const abi.Real) bool;
