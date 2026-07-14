// SPDX-License-Identifier: GPL-3.0-only
const consts = abi.constants;
//
// Zig owner for src/c47/solver/graph.c: the function-plot engine and the
// complex solver. graph_eqn walks the x-range with adaptive step size
// (high-res tracking, jump-back fine stepping, discontinuity / vertical
// asymptote detection) and accumulates points in the DrwMX matrix;
// complexSolver is the modified-3-point-secant complex root finder behind
// cpxSlv; fnEqSolvGraph dispatches Draw / realSlv / cpxSlv from the equation
// app. Every non-static C symbol keeps its real name: drawMxN, fnClDrawMx, the
// asymptote/high-res helpers, check_osc, graph_stat, fnComplexSolver,
// fnEqSolvGraph, plus the osc/DXR/DYR/DXI/DYI globals and the three
// TO_QSPI asymptote offset tables.
//
// Faithful, line-by-line port of the C. SAVE_SPACE_DM42_13GRF is dead
// (defined only in the obsolete !TWO_FILE_PGM && !NEW_HW single-file build),
// so everything is ported unconditionally. The PC_BUILD-gated diagnostics
// that carry SIDE EFFECTS (lastErrorCode resets in initialize_function /
// execute_rpn_function) are reproduced under !is_dmcp_build; the
// PC_BUILD-active console output (VERBOSE_SOLVER_ITERDATA per-iteration
// line, the kick/yPower/revert notices, printSolverResult) is reproduced
// too, since those blocks are compiled into the current host builds. The
// ENABLE_COMPLEXSOLVER_FILE_OUTPUT blocks are compile-time dead (== 0).
// Cold code (user-invoked plots) but kept in main .text (43+ KB flash free);
// tag with linksection(runtime.code_section) only if a package overflows.

const runtime = @import("solve_runtime.zig");
const solve_build_options = @import("solve_build_options");
const is_dmcp_build = @hasDecl(solve_build_options, "is_dmcp_build") and solve_build_options.is_dmcp_build;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const abi = @import("abi"); // shared ABI bindings
const equation = @import("equation.zig");
const solve_owned = @import("solve_owned.zig");
const sumprod = @import("sumprod.zig");
const real_t = abi.Real;
const real34_t = abi.Real34;
const realContext_t = abi.RealContext;
const calcRegister_t = i16;
const matrixHeader_t = abi.MatrixHeader;
const real34Matrix_t = abi.Real34Matrix;
const font_t = opaque {};

const cplx_t = abi.Complex;

const PlotPoint = extern struct {
    x: real_t, // x-coordinate
    y: real_t, // y-coordinate
    grad: real_t, // gradient at the point
    stored: bool,
};

const AsymptoteInfo = extern struct {
    x: real_t, // x-coordinate of asymptote
    gapWidth: real_t, // width of the discontinuity gap
    maxHeight: real_t, // standard maximum height for rendering
    hasPositive: bool, // approaches +infinity
    hasNegative: bool, // approaches -infinity
};

// Direction selectors only, no math content here. Stay as small ints.
const PointOffset = extern struct {
    dx: i8, // -1, 0 or +1
    dy: i8, // -1, 0 or +1
};

comptime {
    if (@sizeOf(real_t) != 60) @compileError("real_t must be 60 bytes");
}

// ---------------------------------------------------------------------------
// Constants (verified against defines.h / items.h / graph.h / screen.h)
// ---------------------------------------------------------------------------
const NUMBERITERATIONS: c_int = 9999;

const SS1: f64 = 1.8; // grad2/grad2 threshold for 50% dx
const SS2: f64 = 2.4; // grad2/grad2 threshold for jumping back
const FINE: c_int = 9; // number of steps to jump
const JMP: f64 = 0.8; // Jump back
const dJMP: f64 = 0.2; // Fine movement in p.u. ddx
const STEP_OFFSET: f64 = 0.99999; // Stay off exact integers
const MIN_IMPROVEMENT_RATIO: f64 = 1.25; // Minimum improvement needed to justify high-res
const HIGH_RES_SAMPLE_COUNT: c_int = 3; // Number of high-res points to evaluate
const REVERT_THRESHOLD: f64 = 0.8; // When to revert to previous dx

// Working precision for all graph-walk math. 14 digits instead of 39 is a real
// speedup and pixels only need ~5. graph_eqn seeds ctxtGraphsLocal from
// ctxtReal39 at entry, then narrows it to GRAPH_WORKING_DIGITS; every real_t
// operation in graph_eqn and its helpers uses ctxtGraphs (= &ctxtGraphsLocal).
const GRAPH_WORKING_DIGITS: i32 = 14;
var ctxtGraphsLocal: realContext_t = undefined;
const ctxtGraphs = &ctxtGraphsLocal;

const MAX_ASYMPTOTES = 10;
const ASYMPTOTE_HEIGHT_RATIO: f64 = 0.8; // 80% of y-axis range
const MIN_GAP_WIDTH_RATIO: f64 = 0.001; // Minimum gap width as ratio of x-range

const REGISTER_X: calcRegister_t = 100;
const REGISTER_Y: calcRegister_t = 101;
const REGISTER_Z: calcRegister_t = 102;
const REGISTER_T: calcRegister_t = 103;
const ERR_REGISTER_LINE: calcRegister_t = REGISTER_Z;
const NIM_REGISTER_LINE: calcRegister_t = REGISTER_X;
const TEMP_REGISTER_1: calcRegister_t = 135;
const INVALID_VARIABLE: calcRegister_t = 2199;
const FIRST_NAMED_VARIABLE: calcRegister_t = 256;
const LAST_NAMED_VARIABLE: calcRegister_t = 1999;
const LAST_LABEL: i32 = 6999;
const RESERVED_VARIABLE_UX: calcRegister_t = 2041;
const RESERVED_VARIABLE_LX: calcRegister_t = 2042;
const RESERVED_VARIABLE_UEST: calcRegister_t = 2044;
const RESERVED_VARIABLE_LEST: calcRegister_t = 2045;

const ERROR_NONE: u8 = 0;
const ERROR_OUT_OF_RANGE: u8 = 8;
const ERROR_NO_ROOT_FOUND: u8 = 20;
const ERROR_NO_SUMMATION_DATA: u8 = 28;
const ERROR_NOT_ENOUGH_MEMORY_FOR_NEW_MATRIX: u8 = 39;

const dtReal34: u32 = 1;
const dtComplex34: u32 = 2;
const amNone: c_int = 5;
const amNoneU: u32 = 5;

const CM_NORMAL: u8 = 0;
const CM_PLOT_STAT: u8 = 8;
const CM_GRAPH: u8 = 15;
const CM_NO_UNDO: u8 = 16;

const PGM_RUNNING: u8 = 1;
const PGM_PAUSED: u8 = 3;

const SCRUPD_AUTO: u8 = 0x00;
const SCRUPD_SKIP_STATUSBAR_ONE_TIME: u8 = 0x10;

const TI_SOLVER_FAILED: u8 = 52;
const TI_SOLVER_VARIABLE_RESULT: u8 = 110;

const PLOT_NOTHING: u16 = 5;
const NOPARAM: u16 = 9876;

const SCREEN_WIDTH_GRAPH: f64 = 400; // SCREEN_WIDTH

const FLAG_CPXPLOT: c_int = 0x804B;
const FLAG_IMPLOT: c_int = 0x8012;
const REAL34_SIZE_IN_BLOCKS: u16 = 4;
const PGM_WAITING: u8 = 2;
const FLAG_CPXRES: c_uint = 0x8004;
const FLAG_FRACT: c_int = 0x8007;
const FLAG_FRACT_U: c_uint = 0x8007;
const FLAG_ASLIFT: c_uint = 0xc023;
const FLAG_PBOX: c_int = 0x804E;
const FLAG_PCROS: c_int = 0x804F;
const FLAG_PPLUS: c_int = 0x8050;
const FLAG_PLINE: c_int = 0x8051;
const FLAG_PLINE_U: c_uint = 0x8051;

const ITM_RAD: i16 = 1557;

const SOLVER_STATUS_READY_TO_EXECUTE: u16 = 0x0001;
const SOLVER_STATUS_RPN_GRAPHER: u16 = 0x4000;
const ERROR_SOLVER_ABORT: u8 = 60;
const SOLVER_RESULT_NORMAL: f64 = 0;
const SOLVER_RESULT_OTHER_FAILURE: f64 = 5;
const SOLVER_RESULT_CONJUGATES: f64 = 200;

const COMPLEX_SOLVER: usize = 103;
const NUMBER_OF_ERROR_CODES = 129; // defines.h: 129 (errorMessages row count)
const SIZE_OF_EACH_ERROR_MESSAGE = 48;

const EQUATION_PARSER_MVAR: u16 = 0;
const EQUATION_PARSER_XEQ: u16 = 1;
const AIM_BUFFER_LENGTH: usize = 1024;

const EQ_CPXSOLVE: u16 = 0;
const EQ_CPXSOLVE_LU: u16 = 1;
const EQ_REALSOLVE: u16 = 2;
const EQ_REALSOLVE_LU: u16 = 3;
const EQ_PLOT: u16 = 4;
const EQ_PLOT_LU: u16 = 5;

const noInitDrwMx: u16 = 0;
const initDrwMx: u16 = 1;

const DOUBLE_NOT_INIT: f64 = 3.402823466e+38; // maximum float value

const SIGMA_NONE: i8 = 0;

// screen.h
const timed: u8 = 0;
const force: u8 = 1;
const halfSec_clearZ: bool = true;
const halfSec_clearT: bool = true;
const halfSec_disp: bool = true;
const vmNormal: c_int = 0;

// decNumber bits.
const DECINF: u8 = 0x40;
const DECNAN: u8 = 0x20;
const DECSNAN: u8 = 0x10;
const DECSPECIAL: u8 = DECINF | DECNAN | DECSNAN;

// ---------------------------------------------------------------------------
// Constant blob (offsets from the generated constantPointers.h)
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Exported globals (non-static in the C)
// ---------------------------------------------------------------------------
pub export var osc: i16 = 0;
pub export var DXR: u8 = 0;
pub export var DYR: u8 = 0;
pub export var DXI: u8 = 0;
pub export var DYI: u8 = 0;

// Three possible templates for asymptotes (TO_QSPI tables in the C).
pub export const asymptote_offsets_both linksection(runtime.code_section) = [3]PointOffset{
    .{ .dx = -1, .dy = -1 }, // (x - offset, -height)
    .{ .dx = -1, .dy = 1 }, // (x - offset, +height)
    .{ .dx = 1, .dy = 1 }, // (x + offset, +height)
};
pub export const asymptote_offsets_positive linksection(runtime.code_section) = [3]PointOffset{
    .{ .dx = -1, .dy = 0 }, // (x - offset, 0)
    .{ .dx = -1, .dy = 1 }, // (x - offset, +height)
    .{ .dx = 1, .dy = 1 }, // (x + offset, +height)
};
pub export const asymptote_offsets_negative linksection(runtime.code_section) = [3]PointOffset{
    .{ .dx = -1, .dy = 0 }, // (x - offset, 0)
    .{ .dx = -1, .dy = -1 }, // (x - offset, -height)
    .{ .dx = 1, .dy = -1 }, // (x + offset, -height)
};

// Static globals.
var cpxSlvBestX: cplx_t = undefined;
var cpxSlvBestMagnitudeY: real_t = undefined;

// ---------------------------------------------------------------------------
// External globals
// ---------------------------------------------------------------------------
extern var lastErrorCode: u8;
extern var temporaryInformation: u8;
extern var calcMode: u8;
extern var programRunStop: u8;
extern var screenUpdatingMode: u8;
extern var currentKeyCode: u8;
extern var significantDigits: u8;
extern var hourGlassIconEnabled: bool;
extern var reDraw: bool;
extern var solverEstimatesUsed: bool;
extern var lastPlotMode: u16;
extern var currentSolverVariable: u16;
extern var currentSolverStatus: u16;
extern var currentFormula: u16;
extern var graphVariabl1: calcRegister_t;
extern var regStatsXY: calcRegister_t;
extern var plotStatMx: [8]u8;
extern var PLOT_SHADE: bool;
extern var PLOT_ZOOM: i8;
extern var x_min: *real_t;
extern var x_max: *real_t;
extern var y_min: *real_t;
extern var y_max: *real_t;
extern var SAVED_SIGMA_lastAddRem: i8;
extern var tmpString: [*c]u8;
extern var aimBuffer: [*c]u8;
extern var ctxtReal34: realContext_t;
extern var ctxtReal39: realContext_t;
extern var ctxtReal51: realContext_t;
extern var ctxtReal75: realContext_t;
extern const standardFont: font_t;
extern const errorMessages: [NUMBER_OF_ERROR_CODES][SIZE_OF_EACH_ERROR_MESSAGE]u8;

// ---------------------------------------------------------------------------
// Function externs (resolve at the final link; plotstat.c is still C)
// ---------------------------------------------------------------------------
extern fn fnStore(r: u16) void;
extern fn fnRCL(inp: i16) void;
extern fn adjustResult(res: calcRegister_t, dropY: bool, setCpxRes: bool, errorReg: calcRegister_t, op1: calcRegister_t, op2: calcRegister_t) void;
extern fn findNamedVariable(variableName: [*c]const u8) calcRegister_t;
extern fn findOrAllocateNamedVariable(variableName: [*c]const u8) calcRegister_t;
extern var allNamedVariables: ?[*]abi.NamedVariableHeader; // named-variable header table (length-prefixed names)
extern var numberOfNamedVariables: u16;
extern fn getNthString(ptr: [*c]u8, n: i16) [*c]u8;
extern fn fnDeleteVariable(regist: u16) void;
extern fn isStatsMatrix(rows: *u16, mx: [*c]const u8) bool;
extern fn isStatsMatrixN(rows: *u16, regStats: calcRegister_t) bool;
extern fn linkToRealMatrixRegister(regist: calcRegister_t, linkedMatrix: *real34Matrix_t) void;
extern fn allocateNamedMatrix(name: [*c]const u8, rows: u16, cols: u16) calcRegister_t;
extern fn appendRowAtMatrixRegister(regist: calcRegister_t) bool;
extern fn realMatrixInit(matrix: *real34Matrix_t, rows: u16, cols: u16) bool;
extern fn displayCalcErrorMessage(error_code: u8, err_message_line: calcRegister_t, err_register_line: calcRegister_t) void;
extern fn moreInfoOnError(m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) void;
extern fn printf(fmt: [*:0]const u8, ...) c_int;
extern fn strcpy(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn saveForUndo() void;
extern fn fnUndo(unusedButMandatoryParameter: u16) void;
extern fn fillStackWithReal0() void;
extern fn fnClearStack(unusedButMandatoryParameter: u16) void;
extern fn liftStack() void;
extern fn getSystemFlag(sf: c_int) bool;
extern fn setSystemFlag(sf: c_uint) void;
extern fn clearSystemFlag(sf: c_uint) void;
extern fn runFunction(func: i16) void;
extern fn fnSetSignificantDigits(S: u16) void;
extern fn fnPline(unusedButMandatoryParameter: u16) void;
extern fn fnPlotSQ(unusedButMandatoryParameter: u16) void;
extern fn statMxN() i32;
extern fn fnImaginaryPart(unusedButMandatoryParameter: u16) void;
extern fn fnRealPart(unusedButMandatoryParameter: u16) void;
extern fn copySourceRegisterToDestRegister(rSource: calcRegister_t, rDest: calcRegister_t) void;
extern fn reallocateRegister(regist: calcRegister_t, dataType: u32, dataSizeWithoutDataLenBlocks: u16, tag: u32) void;
extern fn getRegisterDataType(regist: calcRegister_t) u32;
extern fn getRegisterDataPointer(regist: calcRegister_t) *anyopaque;
extern fn getRegisterAsReal(reg: calcRegister_t, val: *real_t) bool;
extern fn getRegisterAsComplex(reg: calcRegister_t, r: *real_t, c: *real_t) bool;
extern fn convertDoubleToReal34Register(x: f64, destination: calcRegister_t) void;
extern fn convertDoubleToReal34RegisterPush(x: f64, destination: calcRegister_t) void;
extern fn convertDoubleToReal(x: f64, destination: *real_t, ctxt: *realContext_t) void;
extern fn convertRegisterToDouble(regist: calcRegister_t) f64;
extern fn convertRealToResultRegister(x: *align(1) const real_t, dest: calcRegister_t, angle: c_int) void;
extern fn convertComplexToResultRegister(real: *const real_t, imag: *const real_t, dest: calcRegister_t) void;
extern fn complexMagnitude(a: *const real_t, b: *const real_t, c: *real_t, realContext: *realContext_t) void;
extern fn divComplexComplex(numerReal: *const real_t, numerImag: *const real_t, denomReal: *const real_t, denomImag: *const real_t, quotientReal: *real_t, quotientImag: *real_t, realContext: *realContext_t) void;
extern fn mulComplexComplex(factor1Real: *const real_t, factor1Imag: *const real_t, factor2Real: *align(1) const real_t, factor2Imag: *align(1) const real_t, productReal: *real_t, productImag: *real_t, realContext: *realContext_t) void;
extern fn addComplex(aReal: *const real_t, aImag: *const real_t, bReal: *align(1) const real_t, bImag: *align(1) const real_t, resReal: *real_t, resImag: *real_t, realContext: *realContext_t) void;
extern fn subComplex(aReal: *const real_t, aImag: *const real_t, bReal: *const real_t, bImag: *const real_t, resReal: *real_t, resImag: *real_t, realContext: *realContext_t) void;
extern fn realSetZero(r: *real_t) void;
extern fn realSetOne(r: *real_t) void;
extern fn realCompareEqual(a: *align(1) const real_t, b: *align(1) const real_t) bool;
extern fn realCompareLessThan(a: *align(1) const real_t, b: *align(1) const real_t) bool;
extern fn realCompareLessEqual(a: *align(1) const real_t, b: *align(1) const real_t) bool;
extern fn realCompareAbsLessThan(a: *align(1) const real_t, b: *align(1) const real_t) bool;
extern fn showHideHourGlass() void;
extern fn refreshScreen(src: u16) void;
extern fn realSetNaN(value: *real_t) void;
extern fn refreshStatusBar() void;
extern fn clearScreenOld(clearStatusBar: bool, clearRegisterLines: bool, clearSoftkeys: bool) void;
extern fn showString(str: [*c]const u8, font: *const font_t, x: u32, y: u32, video_mode: c_int, show_leading_cols: bool, show_ending_cols: bool) u32;
extern fn printStatus(row: u8, line1: [*c]const u8, forced: u8) void;
extern fn checkHalfSec() bool;
extern fn progressHalfSecUpdate_Integer(mode: u8, txt: [*c]const u8, loop: i32, clearZ: bool, clearT: bool, disp: bool) bool;
// exitKeyWaiting now routes through the host-callback boundary (abi.host),
// severing the direct engine->shell link; it reports "no abort" when headless.
const exitKeyWaiting = abi.host.exitKeyWaiting;
extern fn refreshLcd(unused: ?*anyopaque) void;

// decNumber / decQuad externs behind the real* / real34* macros.
extern fn decNumberCopy(r: *real_t, src: *align(1) const real_t) *real_t;
extern fn decNumberAdd(r: *real_t, a: *align(1) const real_t, b: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberMultiply(r: *real_t, a: *align(1) const real_t, b: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberFromString(r: *real_t, s: [*c]const u8, ctx: *realContext_t) *real_t;
extern fn decNumberToString(r: *const real_t, s: [*c]u8) [*c]u8;
extern fn decimal128ToNumber(src: *align(1) const real34_t, dst: *real_t) *real_t;
extern fn decimal128FromNumber(dst: *align(1) real34_t, src: *align(1) const real_t, ctx: *realContext_t) *align(1) real34_t;
extern fn decQuadIsInfinite(v: *align(1) const real34_t) u32;
extern fn decQuadIsNaN(v: *align(1) const real34_t) u32;
extern fn decQuadIsSignaling(v: *align(1) const real34_t) u32;
extern fn decQuadIsZero(v: *align(1) const real34_t) u32;
extern fn decQuadToString(v: *align(1) const real34_t, s: [*c]u8) [*c]u8;
extern fn decQuadToInt32(v: *align(1) const real34_t, ctx: *realContext_t, round: c_int) i32;
extern fn realToFloat(vv: *const real_t, v: *f32) void;
extern fn realToDouble(vv: *const real_t, v: *f64) void;

// Additional decNumber primitives for the real_t graph walk (M-GRAPH port).
extern fn decNumberSubtract(r: *real_t, a: *align(1) const real_t, b: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberDivide(r: *real_t, a: *align(1) const real_t, b: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberFMA(r: *real_t, f1: *align(1) const real_t, f2: *align(1) const real_t, term: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberPlus(r: *real_t, a: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberCopyAbs(r: *real_t, src: *align(1) const real_t) *real_t;
extern fn decNumberFromInt32(r: *real_t, source: i32) *real_t;
extern fn decQuadZero(v: *align(1) real34_t) *align(1) real34_t;
extern fn realCompareGreaterThan(a: *align(1) const real_t, b: *align(1) const real_t) bool;
extern fn realCompareGreaterEqual(a: *align(1) const real_t, b: *align(1) const real_t) bool;
extern fn getRegisterAsRealQuiet(reg: calcRegister_t, val: *real_t) bool;
extern fn fnSwapXY(unusedButMandatoryParameter: u16) void;

// graphAccActive: nested SOLVE reads this to pick the graph convergence
// tolerance; execute_rpn_function_graphAcc sets it around each sample eval.
extern var graphAccActive: bool;

// DMCP firmware: lcd_refresh is a ROM jump-table call (matches the lblGtoXeq
// owner trampoline; offset 48 in both lft_ifc.h files).
const dm42_pkg_xip = @hasDecl(solve_build_options, "dm42_pkg_xip") and solve_build_options.dm42_pkg_xip;
const library_fn_base: usize = if (dm42_pkg_xip) 0x08000201 else 0x08000301;
inline fn lcdRefresh() void {
    if (comptime is_dmcp_build) {
        const f: *const fn () callconv(.c) void = @ptrFromInt(library_fn_base + 48);
        f();
    } else {
        refreshLcd(null);
    }
}

// libm.
extern fn fabs(x: f64) f64;
extern fn fmax(x: f64, y: f64) f64;
extern fn fmin(x: f64, y: f64) f64;
extern fn pow(x: f64, y: f64) f64;
extern fn atan2(y: f64, x: f64) f64;
extern fn sqrt(x: f64) f64;

// ---------------------------------------------------------------------------
// Inline wrappers (the C macros)
// ---------------------------------------------------------------------------
const ctxtSolver2 = &ctxtReal39;

const reg34 = abi.registerReal34;
const regImag34 = abi.registerImag34;
inline fn realCopy(src: *align(1) const real_t, dst: *real_t) void {
    _ = decNumberCopy(dst, src);
}
inline fn realAdd(a: *align(1) const real_t, b: *align(1) const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberAdd(res, a, b, ctx);
}
inline fn realMultiply(a: *align(1) const real_t, b: *align(1) const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberMultiply(res, a, b, ctx);
}
inline fn stringToReal(src: [*c]const u8, dst: *real_t, ctx: *realContext_t) void {
    _ = decNumberFromString(dst, src, ctx);
}
inline fn real34ToReal(src: *align(1) const real34_t, dst: *real_t) void {
    _ = decimal128ToNumber(src, dst);
}
inline fn realToReal34(src: *align(1) const real_t, dst: *align(1) real34_t) void {
    _ = decimal128FromNumber(dst, src, &ctxtReal34);
}
inline fn real34IsSpecial(v: *align(1) const real34_t) bool {
    return decQuadIsNaN(v) != 0 or decQuadIsSignaling(v) != 0 or decQuadIsInfinite(v) != 0;
}
inline fn real34IsInfinite(v: *align(1) const real34_t) bool {
    return decQuadIsInfinite(v) != 0;
}
inline fn real34IsNaN(v: *align(1) const real34_t) bool {
    return decQuadIsNaN(v) != 0;
}
inline fn real34IsZero(v: *align(1) const real34_t) bool {
    return decQuadIsZero(v) != 0;
}
inline fn real34IsNegative(v: *align(1) const real34_t) bool {
    return (v.bytes[15] & 0x80) == 0x80;
}
inline fn real34ToInt32(v: *align(1) const real34_t) i32 {
    return decQuadToInt32(v, &ctxtReal34, 5); // DEC_ROUND_DOWN
}
inline fn realIsZero(v: *align(1) const real_t) bool {
    return v.lsu[0] == 0 and v.digits == 1 and (v.bits & DECSPECIAL) == 0;
}
inline fn realIsNaN(v: *const real_t) bool {
    return (v.bits & (DECNAN | DECSNAN)) != 0;
}
inline fn realIsInfinite(v: *const real_t) bool {
    return (v.bits & DECINF) != 0;
}
inline fn realGetSign(v: *const real_t) u8 {
    return v.bits & 0x80;
}
inline fn realGetExponent(v: *const real_t) i32 {
    return v.digits + v.exponent - 1;
}
inline fn realSubtract(a: *align(1) const real_t, b: *align(1) const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberSubtract(res, a, b, ctx);
}
inline fn realDivide(a: *align(1) const real_t, b: *align(1) const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberDivide(res, a, b, ctx);
}
inline fn realFMA(f1: *align(1) const real_t, f2: *align(1) const real_t, term: *align(1) const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberFMA(res, f1, f2, term, ctx);
}
inline fn realPlus(operand: *align(1) const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberPlus(res, operand, ctx);
}
inline fn realCopyAbs(source: *align(1) const real_t, destination: *real_t) void {
    _ = decNumberCopyAbs(destination, source);
}
inline fn realDivideBy2(operand: *real_t, ctx: *realContext_t) void {
    _ = decNumberMultiply(operand, operand, consts.const_1on2(), ctx);
}
inline fn int32ToReal(source: i32, destination: *real_t) void {
    _ = decNumberFromInt32(destination, source);
}
inline fn real34SetZero(destination: *align(1) real34_t) void {
    _ = decQuadZero(destination);
}
inline fn realIsSpecial(v: *align(1) const real_t) bool {
    return (v.bits & 0x70) != 0;
}
inline fn realIsNegative(v: *align(1) const real_t) bool {
    return (v.bits & 0x80) == 0x80;
}
inline fn realIsPositive(v: *align(1) const real_t) bool {
    return (v.bits & 0x80) == 0x00;
}
inline fn realToDoubleVal(r: *const real_t) f64 {
    var d: f64 = undefined;
    realToDouble(r, &d);
    return d;
}
// The C wraps realIs*/realChangeSign in noinline graphIs* shims to dodge a
// GCC bounds-check false positive on the small graph buffers; in Zig they are
// plain forwarders.
inline fn graphIsZero(x: *align(1) const real_t) bool {
    return realIsZero(x);
}
inline fn graphIsNegative(x: *align(1) const real_t) bool {
    return realIsNegative(x);
}
inline fn graphIsPositive(x: *align(1) const real_t) bool {
    return realIsPositive(x);
}
inline fn graphChangeSign(x: *real_t) void {
    x.bits ^= 0x80;
}
inline fn realChangeSign(v: *real_t) void {
    v.bits ^= 0x80;
}
// significantDigitsForEqnGraphs / significantDigitsForScreen (defines.h).
inline fn significantDigitsForEqnGraphs() i32 {
    return if (significantDigits == 0) 12 else significantDigits;
}
const significantDigitsForScreen: i32 = 3;

// ===========================================================================
// fnPlot (static)
// ===========================================================================
fn fnPlot(unusedButMandatoryParameter: u16) void {
    _ = unusedButMandatoryParameter;
    lastPlotMode = PLOT_NOTHING;
    _ = strcpy(&plotStatMx, "DrwMX");
    PLOT_SHADE = true;
    fnPlotSQ(0);
    //  C47 advanced plot ^^
}

// ===========================================================================
// initialize_function (static)
// ===========================================================================
fn initialize_function() void {
    if (graphVariabl1 > 0) {
        if (comptime !is_dmcp_build) {
            if (lastErrorCode != 0) {
                lastErrorCode = 0;
            }
        }
    } else {
        // PC_BUILD VERBOSE diagnostics only; nothing live.
    }
}

// ===========================================================================
// execute_rpn_function (static)
// ===========================================================================
fn execute_rpn_function() void {
    if (graphVariabl1 <= 0 or @as(i32, graphVariabl1) > LAST_LABEL) {
        if (comptime !is_dmcp_build) {
            _ = printf("Error: No graph variable %u\n", @as(c_uint, @bitCast(@as(c_int, graphVariabl1))));
        }
        return;
    }

    const regStats: calcRegister_t = graphVariabl1;
    if (regStats != INVALID_VARIABLE) {
        fnStore(@bitCast(regStats)); // place X register into x

        if ((currentSolverStatus & SOLVER_STATUS_RPN_GRAPHER) != 0) {
            // RPN grapher: run the program over the plot variable at this sample.
            var xReal: real_t = undefined;
            var resReal: real_t = undefined;
            real34ToReal(reg34(REGISTER_X), &xReal);
            solve_owned._executeSolverReal(@bitCast(currentSolverVariable), &xReal, &resReal, null);
            realToReal34(&resReal, reg34(REGISTER_X));
        } else {
            equation.parseEquation(currentFormula, EQUATION_PARSER_XEQ, tmpString, tmpString + AIM_BUFFER_LENGTH);
        }
        adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);

        if (lastErrorCode != 0) { // failed sample: NaN it so stale register content is not plotted
            var nanR: real_t = undefined;
            realSetNaN(&nanR);
            reallocateRegister(REGISTER_X, dtReal34, 0, @bitCast(amNone));
            realToReal34(&nanR, reg34(REGISTER_X));
            if (lastErrorCode != ERROR_SOLVER_ABORT) { // keep an abort alive to stop the plot; ordinary errors just NaN this sample
                lastErrorCode = 0;
            }
        }
        fnRCL(regStats);

        // ENABLE_COMPLEXSOLVER_FILE_OUTPUT == 2 block: compile-time dead.
    } else { // invalid plot variable: NaN REGISTER_Y so the caller does not sample stale content
        var nanR: real_t = undefined;
        realSetNaN(&nanR);
        reallocateRegister(REGISTER_Y, dtReal34, 0, @bitCast(amNone));
        realToReal34(&nanR, reg34(REGISTER_Y));
        lastErrorCode = 0;
    }
}

// ===========================================================================
// PLOTTER
// ===========================================================================
pub export fn drawMxN() callconv(.c) i32 {
    var rows: u16 = 0;
    if (plotStatMx[0] != 'D') {
        return 0;
    }
    const regStats: calcRegister_t = findNamedVariable(&plotStatMx);
    if (regStats == INVALID_VARIABLE) {
        return 0;
    }
    if (isStatsMatrix(&rows, &plotStatMx)) {
        var stats: real34Matrix_t = undefined;
        linkToRealMatrixRegister(regStats, &stats);
        return stats.header.matrixRows;
    } else {
        return 0;
    }
}

pub export fn fnClDrawMx(origin: u8) callconv(.c) void {
    _ = origin;
    PLOT_ZOOM = 0;
    const regStats: calcRegister_t = findNamedVariable("DrwMX");
    if (regStats != INVALID_VARIABLE) {
        fnDeleteVariable(@bitCast(regStats));
    }
}

fn AddtoDrawMx() void {
    var x: real_t = undefined;
    var y: real_t = undefined;
    var rows: u16 = 0;
    var cols: u16 = undefined;
    var regStats: calcRegister_t = regStatsXY;
    if (!isStatsMatrixN(&rows, regStats)) {
        regStats = allocateNamedMatrix(&plotStatMx, 1, 2); // already preps the 1x2; the old linked-copy realMatrixInit was never stored back nor freed
        regStatsXY = regStats;
    } else {
        if (appendRowAtMatrixRegister(regStats)) {} else {
            regStats = INVALID_VARIABLE;
        }
    }
    if (regStats != INVALID_VARIABLE) {
        real34ToReal(reg34(REGISTER_X), &x);
        real34ToReal(reg34(REGISTER_Y), &y);

        var stats: real34Matrix_t = undefined;
        linkToRealMatrixRegister(regStats, &stats);
        rows = stats.header.matrixRows;
        cols = stats.header.matrixColumns;
        realToReal34(&x, @ptrCast(&stats.matrixElements.?[(@as(u32, rows) - 1) * cols]));
        realToReal34(&y, @ptrCast(&stats.matrixElements.?[(@as(u32, rows) - 1) * cols + 1]));
    } else {
        displayCalcErrorMessage(ERROR_NOT_ENOUGH_MEMORY_FOR_NEW_MATRIX, ERR_REGISTER_LINE, REGISTER_X); // Invalid input data type for this operation
        moreInfoOnError("In function AddtoDrawMx:", "additional matrix line not added", null, null);
    }
}

// ===========================================================================
// real_t register / evaluation leaves (M-GRAPH port)
// ===========================================================================
fn convertRealToReal34Register(x: *align(1) const real_t, destination: calcRegister_t) void {
    reallocateRegister(destination, dtReal34, 0, @bitCast(amNone));
    realToReal34(x, reg34(destination));
}

fn convertRealToReal34RegisterPush(x: *align(1) const real_t, destination: calcRegister_t) void {
    setSystemFlag(FLAG_ASLIFT);
    liftStack();
    convertRealToReal34Register(x, destination);
    setSystemFlag(FLAG_ASLIFT);
}

// Read a register as real_t. For complex registers, return Re or Im per
// FLAG_IMPLOT. The register value is rounded into the destination at the graph
// working precision (realPlus via ctxtGraphs).
fn convertRegisterToReal(source: calcRegister_t, destination: *real_t) void {
    var tmp: real_t = undefined;
    if (getRegisterDataType(source) == dtComplex34) {
        if (getSystemFlag(FLAG_IMPLOT)) {
            real34ToReal(regImag34(source), &tmp);
        } else {
            real34ToReal(reg34(source), &tmp);
        }
        realPlus(&tmp, destination, ctxtGraphs);
        return;
    }
    if (getSystemFlag(FLAG_IMPLOT)) {
        realSetZero(destination);
        return;
    }
    if (!getRegisterAsRealQuiet(source, &tmp)) {
        realSetNaN(destination);
        return;
    }
    realPlus(&tmp, destination, ctxtGraphs);
}

// Normalised read for the jump-back analysis: out = (v - origin) / span,
// dimensionless and O(1) at any data magnitude.
fn normCoord(v: *align(1) const real_t, origin: *align(1) const real_t, span: *align(1) const real_t) f64 {
    var t: real_t = undefined;
    realSubtract(v, origin, &t, ctxtGraphs);
    realDivide(&t, span, &t, ctxtGraphs);
    return realToDoubleVal(&t);
}

// Reduce REGISTER_Y to either Re or Im (per FLAG_IMPLOT) before AddtoDrawMx.
fn reduceRegisterYToComponent() void {
    if (getRegisterDataType(REGISTER_Y) == dtComplex34) {
        fnSwapXY(NOPARAM);
        if (getSystemFlag(FLAG_IMPLOT)) {
            fnImaginaryPart(NOPARAM);
        } else {
            fnRealPart(NOPARAM);
        }
        fnSwapXY(NOPARAM);
    } else if (getSystemFlag(FLAG_IMPLOT)) {
        reallocateRegister(REGISTER_Y, dtReal34, REAL34_SIZE_IN_BLOCKS, @bitCast(amNone));
        real34SetZero(reg34(REGISTER_Y));
    }
}

// Wrapper around execute_rpn_function that narrows ctxtReal34/39/51/75 to
// graph-eqn precision (LOW_GRAPH_ACC is active) around one sample evaluation.
fn execute_rpn_function_graphAcc() void {
    const s34 = ctxtReal34.digits;
    const s39 = ctxtReal39.digits;
    const s51 = ctxtReal51.digits;
    const s75 = ctxtReal75.digits;
    const savedGraphAccActive = graphAccActive;
    graphAccActive = true; // a nested SOLVE reads this to pick the graph convergence tolerance
    const sdigs = significantDigitsForEqnGraphs();
    ctxtReal34.digits = sdigs;
    ctxtReal39.digits = sdigs + 3;
    ctxtReal51.digits = sdigs + 12;
    ctxtReal75.digits = sdigs + 18;
    execute_rpn_function();
    ctxtReal34.digits = s34;
    ctxtReal39.digits = s39;
    ctxtReal51.digits = s51;
    ctxtReal75.digits = s75;
    graphAccActive = savedGraphAccActive;
}

// Swap the range if entered reversed; widen a span too small to plot at the
// graph working precision. Uses ctxtReal39, not ctxtGraphs. (Wired in by the
// range-reconcile slice; compiled ahead of its caller.)
pub export fn graphRangeGuard(lo: *real_t, hi: *real_t) callconv(.c) void {
    var span: real_t = undefined;
    var mag: real_t = undefined;
    var tmpR: real_t = undefined;
    if (realCompareGreaterThan(lo, hi)) { // swap if entered in incorrect sequence
        realCopy(hi, &tmpR);
        realCopy(lo, hi);
        realCopy(&tmpR, lo);
    }
    realSubtract(hi, lo, &span, &ctxtReal39); // span = hi - lo, >= 0 after the swap
    realCopyAbs(lo, &mag); // mag = |lo|
    realCopyAbs(hi, &tmpR); // tmpR = |hi|
    if (realCompareGreaterThan(&tmpR, &mag)) {
        realCopy(&tmpR, &mag); // mag = max(|lo|, |hi|)
    }
    realSetOne(&tmpR);
    tmpR.exponent = 3 - GRAPH_WORKING_DIGITS; // 100x the ULP of the graph working precision
    realMultiply(&mag, &tmpR, &tmpR, &ctxtReal39); // narrowest plottable span
    if (realCompareLessEqual(&span, &tmpR)) { // span too small to plot at working precision
        if (realIsZero(&mag)) { // typically 0 - 0: change to -1 to 1
            int32ToReal(-1, lo);
            int32ToReal(1, hi);
        } else { // widen by 10% of the magnitude
            convertDoubleToReal(0.1, &tmpR, &ctxtReal39);
            realMultiply(&mag, &tmpR, &tmpR, &ctxtReal39);
            realSubtract(lo, &tmpR, lo, &ctxtReal39);
            realAdd(hi, &tmpR, hi, &ctxtReal39);
        }
    }
}

// ===========================================================================
// High-res / discontinuity helpers
// ===========================================================================
pub export fn validateDiscontinuityResolution(buffer: [*]PlotPoint, count: c_int, yBefore: *align(1) const real_t, yAfter: *align(1) const real_t, discontinuityThreshold: *align(1) const real_t) callconv(.c) bool {
    if (count < 3) {
        return false;
    }

    // Check if the fine-stepped points show smooth transition
    var maxJump: real_t = undefined;
    var totalVariation: real_t = undefined;
    var jump: real_t = undefined;
    var diff: real_t = undefined;
    realSetZero(&maxJump);
    realSetZero(&totalVariation);

    // Check continuity between consecutive fine points
    var i: c_int = 1;
    while (i < count) : (i += 1) {
        realSubtract(&buffer[@intCast(i)].y, &buffer[@intCast(i - 1)].y, &diff, ctxtGraphs);
        realCopyAbs(&diff, &jump);
        realAdd(&totalVariation, &jump, &totalVariation, ctxtGraphs);
        if (realCompareGreaterThan(&jump, &maxJump)) {
            realCopy(&jump, &maxJump);
        }
    }

    // Also check connection to endpoints
    var startJump: real_t = undefined;
    var endJump: real_t = undefined;
    realSubtract(&buffer[0].y, yBefore, &diff, ctxtGraphs);
    realCopyAbs(&diff, &startJump);
    realSubtract(yAfter, &buffer[@intCast(count - 1)].y, &diff, ctxtGraphs);
    realCopyAbs(&diff, &endJump);

    if (realCompareGreaterThan(&startJump, &maxJump)) {
        realCopy(&startJump, &maxJump);
    }
    if (realCompareGreaterThan(&endJump, &maxJump)) {
        realCopy(&endJump, &maxJump);
    }

    // If the maximum jump in fine steps is still above threshold, discontinuity persists
    const discontinuityResolved: bool = realCompareLessThan(&maxJump, discontinuityThreshold);

    // Additional check: fine points should show reasonable continuity
    var avgVariation: real_t = undefined;
    var threeAvg: real_t = undefined;
    var halfThresh: real_t = undefined;
    var countMinus1: real_t = undefined;
    int32ToReal(count - 1, &countMinus1);
    realDivide(&totalVariation, &countMinus1, &avgVariation, ctxtGraphs);
    realMultiply(consts.const_3(), &avgVariation, &threeAvg, ctxtGraphs);
    realCopy(discontinuityThreshold, &halfThresh);
    realDivideBy2(&halfThresh, ctxtGraphs);

    const below3xAvg: bool = realCompareLessThan(&maxJump, &threeAvg);
    const belowHalfThresh: bool = realCompareLessThan(&maxJump, &halfThresh);
    const smoothTransition: bool = below3xAvg or belowHalfThresh;

    return discontinuityResolved and smoothTransition;
}

pub export fn calculateNewStepSize(discontinuityDetected: c_int, grad1: *align(1) const real_t, grad2: *align(1) const real_t, grad2IncreaseDetected: bool, dx0: *align(1) const real_t, newDx: *real_t) callconv(.c) void {
    if (discontinuityDetected > 0 and discontinuityDetected <= FINE) {
        var djmpReal: real_t = undefined;
        stringToReal("0.2", &djmpReal, ctxtGraphs); // _R_STR_OF(dJMP)
        realMultiply(&djmpReal, dx0, newDx, ctxtGraphs);
        return;
    } else if (graphIsZero(grad2) or graphIsZero(grad1)) {
        realCopy(dx0, newDx);
        return;
    } else if (grad2IncreaseDetected) {
        var ratio1: real_t = undefined;
        var ratio2: real_t = undefined;
        var ss1Real: real_t = undefined;
        realDivide(grad2, grad1, &ratio1, ctxtGraphs);
        realDivide(grad1, grad2, &ratio2, ctxtGraphs);
        stringToReal("1.8", &ss1Real, ctxtGraphs); // _R_STR_OF(SS1)
        const scaleHalf: bool = realCompareGreaterThan(&ratio1, &ss1Real) or realCompareGreaterThan(&ratio2, &ss1Real);
        if (scaleHalf) {
            realMultiply(dx0, consts.const_1on2(), newDx, ctxtGraphs);
        } else {
            realCopy(dx0, newDx);
        }
        return;
    } else {
        realCopy(dx0, newDx);
        return;
    }
}

pub export fn enterHighResMode(inHighResMode: *bool, highResCount: *c_int, highResStartX: *real_t, baselineCurvatureChange: *real_t, cumulativeCurvatureChange: *real_t, x: *align(1) const real_t, curvatureChange: *align(1) const real_t) callconv(.c) void {
    inHighResMode.* = true;
    highResCount.* = 0;
    realCopy(x, highResStartX);
    realCopy(curvatureChange, baselineCurvatureChange);
    realSetZero(cumulativeCurvatureChange);
}

pub export fn commitHighResPointsInOrder(buffer: [*]PlotPoint, count: c_int) callconv(.c) void {
    var i: c_int = 0;
    while (i < count) : (i += 1) {
        if (!buffer[@intCast(i)].stored) {
            convertRealToReal34RegisterPush(&buffer[@intCast(i)].x, REGISTER_X);
            execute_rpn_function_graphAcc();
            reduceRegisterYToComponent();
            AddtoDrawMx();
            buffer[@intCast(i)].stored = true;
        }
    }
}

pub export fn abandonHighResMode(highResCount: *c_int, inHighResMode: *bool) callconv(.c) void {
    highResCount.* = 0;
    inHighResMode.* = false;
    // High-res points are simply discarded, not added to plot
}

pub export fn resetHighResTracking(highResCount: *c_int, inHighResMode: *bool, cumulativeCurvatureChange: *real_t) callconv(.c) void {
    highResCount.* = 0;
    inHighResMode.* = false;
    realSetZero(cumulativeCurvatureChange);
}

pub export fn detectTrueDiscontinuity(y0: *align(1) const real_t, y1: *align(1) const real_t, y2: *align(1) const real_t, grad0: *align(1) const real_t, grad1: *align(1) const real_t, grad2: *align(1) const real_t, yAvg: *align(1) const real_t, count: c_int) callconv(.c) bool {
    // Distinguish between genuine discontinuities and normal peaks
    if (real34IsSpecial(reg34(REGISTER_X)) or ((getRegisterDataType(REGISTER_X) == dtComplex34) and (real34IsSpecial(regImag34(REGISTER_X))))) {
        return true;
    }
    if (count < 4) {
        return false;
    }

    var absY1: real_t = undefined;
    var absY2: real_t = undefined;
    var hundredYAvg: real_t = undefined;
    var tenYAvg: real_t = undefined;
    realCopyAbs(y1, &absY1);
    realCopyAbs(y2, &absY2);
    realMultiply(consts.const_100(), yAvg, &hundredYAvg, ctxtGraphs);
    realMultiply(consts.const_10(), yAvg, &tenYAvg, ctxtGraphs);

    const absY2GtHundred: bool = realCompareGreaterThan(&absY2, &hundredYAvg);
    const absY1LtTen: bool = realCompareLessThan(&absY1, &tenYAvg);
    const extremeMagnitudeJump: bool = absY2GtHundred and absY1LtTen;

    var gradientDiscontinuity: bool = false;
    if (!graphIsZero(grad0) and !graphIsZero(grad1) and !graphIsZero(grad2)) {
        // Calculate expected gradient based on trend
        var diffG1G0: real_t = undefined;
        var expectedGrad: real_t = undefined;
        var absExpectedGrad: real_t = undefined;
        var absGrad2: real_t = undefined;
        var epsilon: real_t = undefined;
        var denom: real_t = undefined;
        var gradientRatio: real_t = undefined;
        var diffTmp: real_t = undefined;
        var absY2mY1: real_t = undefined;
        var absY1mY0: real_t = undefined;
        var twentyAbsY1mY0: real_t = undefined;
        var fiveYAvg: real_t = undefined;
        var const20: real_t = undefined;
        var const50: real_t = undefined;

        realSubtract(grad1, grad0, &diffG1G0, ctxtGraphs); // grad1 - grad0
        realAdd(grad1, &diffG1G0, &expectedGrad, ctxtGraphs); // grad1 + (grad1 - grad0)
        realCopyAbs(&expectedGrad, &absExpectedGrad);
        realCopyAbs(grad2, &absGrad2);
        stringToReal("1e-10", &epsilon, ctxtGraphs);
        realAdd(&absExpectedGrad, &epsilon, &denom, ctxtGraphs);
        realDivide(&absGrad2, &denom, &gradientRatio, ctxtGraphs);

        realSubtract(y2, y1, &diffTmp, ctxtGraphs);
        realCopyAbs(&diffTmp, &absY2mY1);
        realSubtract(y1, y0, &diffTmp, ctxtGraphs);
        realCopyAbs(&diffTmp, &absY1mY0);

        int32ToReal(20, &const20);
        int32ToReal(50, &const50);
        realMultiply(&const20, &absY1mY0, &twentyAbsY1mY0, ctxtGraphs);
        realMultiply(consts.const_5(), yAvg, &fiveYAvg, ctxtGraphs);

        const ratioGt50: bool = realCompareGreaterThan(&gradientRatio, &const50);
        const y2mY1Gt20Y1mY0: bool = realCompareGreaterThan(&absY2mY1, &twentyAbsY1mY0);
        const y2mY1Gt5YAvg: bool = realCompareGreaterThan(&absY2mY1, &fiveYAvg);

        // Only flag if gradient changes by more than 50x AND the function values suggest discontinuity
        gradientDiscontinuity = ratioGt50 and y2mY1Gt20Y1mY0 and y2mY1Gt5YAvg;
    }

    // Check for sign oscillation that indicates numerical instability not smooth peaks
    var signOscillationInstability: bool = false;
    if (count >= 6) {
        // Look for rapid alternating signs with increasing magnitude - indicates instability
        const y0Pos: bool = !graphIsNegative(y0) and !graphIsZero(y0);
        const y1Pos: bool = !graphIsNegative(y1) and !graphIsZero(y1);
        const y2Pos: bool = !graphIsNegative(y2) and !graphIsZero(y2);
        if (y0Pos != y1Pos and y1Pos != y2Pos) {
            // Alternating signs - check if magnitudes are increasing dramatically
            var mag0: real_t = undefined;
            var mag1: real_t = undefined;
            var mag2: real_t = undefined;
            var fiveMag1: real_t = undefined;
            var fiveMag0: real_t = undefined;
            var tenYAvg2: real_t = undefined;
            realCopyAbs(y0, &mag0);
            realCopyAbs(y1, &mag1);
            realCopyAbs(y2, &mag2);
            realMultiply(consts.const_5(), &mag1, &fiveMag1, ctxtGraphs);
            realMultiply(consts.const_5(), &mag0, &fiveMag0, ctxtGraphs);
            realMultiply(consts.const_10(), yAvg, &tenYAvg2, ctxtGraphs);
            const mag2Gt5Mag1: bool = realCompareGreaterThan(&mag2, &fiveMag1);
            const mag1Gt5Mag0: bool = realCompareGreaterThan(&mag1, &fiveMag0);
            const mag2Gt10YAvg: bool = realCompareGreaterThan(&mag2, &tenYAvg2);
            signOscillationInstability = mag2Gt5Mag1 and mag1Gt5Mag0 and mag2Gt10YAvg;
        }
    }

    return extremeMagnitudeJump or gradientDiscontinuity or signOscillationInstability;
}

// ===========================================================================
// Asymptote detection and rendering
// ===========================================================================
pub export fn detectAndCharacterizeAsymptote(xLeft: *align(1) const real_t, yLeft: *align(1) const real_t, xRight: *align(1) const real_t, yRight: *align(1) const real_t, xGap: *align(1) const real_t, gapWidth: *align(1) const real_t, xMin: *align(1) const real_t, xMax: *align(1) const real_t, yMin: *align(1) const real_t, yMax: *align(1) const real_t, asymptote: *AsymptoteInfo) callconv(.c) bool {
    // Check if gap is significant enough
    var xRange: real_t = undefined;
    var yRange: real_t = undefined;
    var minRatio: real_t = undefined;
    var minGap: real_t = undefined;
    realSubtract(xMax, xMin, &xRange, ctxtGraphs);
    stringToReal("0.001", &minRatio, ctxtGraphs); // _R_STR_OF(MIN_GAP_WIDTH_RATIO)
    realMultiply(&minRatio, &xRange, &minGap, ctxtGraphs);
    if (realCompareLessThan(gapWidth, &minGap)) {
        return false;
    }

    // Sample only 2 points on each side to minimize memory usage
    var leftMaxY: real_t = undefined;
    var rightMaxY: real_t = undefined;
    var leftMinY: real_t = undefined;
    var rightMinY: real_t = undefined;
    realCopy(yLeft, &leftMaxY);
    realCopy(yLeft, &leftMinY);
    realCopy(yRight, &rightMaxY);
    realCopy(yRight, &rightMinY);

    var zeroPoint7: real_t = undefined;
    var zeroPoint2: real_t = undefined;
    var iReal: real_t = undefined;
    var fineFactor: real_t = undefined;
    var leftFactor: real_t = undefined;
    var spanLeft: real_t = undefined;
    var spanRight: real_t = undefined;
    var sampleX: real_t = undefined;
    var sampleY: real_t = undefined;
    stringToReal("0.7", &zeroPoint7, ctxtGraphs);
    stringToReal("0.2", &zeroPoint2, ctxtGraphs);
    realSubtract(xGap, xLeft, &spanLeft, ctxtGraphs);
    realSubtract(xRight, xGap, &spanRight, ctxtGraphs);

    // Sample just 2 points on each side (minimal sampling)
    var i: c_int = 1;
    while (i <= 2) : (i += 1) {
        int32ToReal(i, &iReal);
        realDivide(&zeroPoint2, consts.const_2(), &fineFactor, ctxtGraphs); // 0.2 / 2
        realMultiply(&fineFactor, &iReal, &fineFactor, ctxtGraphs); // (0.2/2) * i
        realAdd(&zeroPoint7, &fineFactor, &leftFactor, ctxtGraphs); // 0.7 + ...

        // Left side samples (approaching asymptote from left)
        realMultiply(&spanLeft, &leftFactor, &sampleX, ctxtGraphs);
        realAdd(xLeft, &sampleX, &sampleX, ctxtGraphs);
        convertRealToReal34RegisterPush(&sampleX, REGISTER_X);
        execute_rpn_function_graphAcc();

        // Skip if we get invalid results
        if (real34IsInfinite(reg34(REGISTER_Y)) or real34IsNaN(reg34(REGISTER_Y))) {
            continue;
        }

        convertRegisterToReal(REGISTER_Y, &sampleY);
        if (realCompareGreaterThan(&sampleY, &leftMaxY)) {
            realCopy(&sampleY, &leftMaxY);
        }
        if (realCompareLessThan(&sampleY, &leftMinY)) {
            realCopy(&sampleY, &leftMinY);
        }

        // Right side samples (approaching asymptote from right)
        realMultiply(&spanRight, &fineFactor, &sampleX, ctxtGraphs);
        realAdd(xGap, &sampleX, &sampleX, ctxtGraphs);
        convertRealToReal34RegisterPush(&sampleX, REGISTER_X);
        execute_rpn_function_graphAcc();

        if (real34IsInfinite(reg34(REGISTER_Y)) or real34IsNaN(reg34(REGISTER_Y))) {
            continue;
        }

        convertRegisterToReal(REGISTER_Y, &sampleY);
        if (realCompareGreaterThan(&sampleY, &rightMaxY)) {
            realCopy(&sampleY, &rightMaxY);
        }
        if (realCompareLessThan(&sampleY, &rightMinY)) {
            realCopy(&sampleY, &rightMinY);
        }
    }

    // Determine if we have a vertical asymptote based on extreme values
    var extremeThreshold: real_t = undefined;
    var yMaxPlus: real_t = undefined;
    var yMinMinus: real_t = undefined;
    realSubtract(yMax, yMin, &yRange, ctxtGraphs);
    realMultiply(&yRange, consts.const_2(), &extremeThreshold, ctxtGraphs); // Values beyond 2x the plot range
    realAdd(yMax, &extremeThreshold, &yMaxPlus, ctxtGraphs);
    realSubtract(yMin, &extremeThreshold, &yMinMinus, ctxtGraphs);

    const leftGoesPositive: bool = realCompareGreaterThan(&leftMaxY, &yMaxPlus);
    const leftGoesNegative: bool = realCompareLessThan(&leftMinY, &yMinMinus);
    const rightGoesPositive: bool = realCompareGreaterThan(&rightMaxY, &yMaxPlus);
    const rightGoesNegative: bool = realCompareLessThan(&rightMinY, &yMinMinus);

    // Must have extreme behavior on at least one side
    if (!(leftGoesPositive or leftGoesNegative or rightGoesPositive or rightGoesNegative)) {
        return false;
    }

    // Fill asymptote info
    var heightRatio: real_t = undefined;
    realCopy(xGap, &asymptote.x);
    realCopy(gapWidth, &asymptote.gapWidth);
    asymptote.hasPositive = leftGoesPositive or rightGoesPositive;
    asymptote.hasNegative = leftGoesNegative or rightGoesNegative;
    stringToReal("0.8", &heightRatio, ctxtGraphs); // _R_STR_OF(ASYMPTOTE_HEIGHT_RATIO)
    realMultiply(&yRange, &heightRatio, &asymptote.maxHeight, ctxtGraphs);

    return true;
}

pub export fn renderAsymptote(asymptote: *AsymptoteInfo) callconv(.c) void {
    var xCenter: real_t = undefined;
    var offset: real_t = undefined;
    var x: real_t = undefined;
    var y: real_t = undefined;
    var c10000: real_t = undefined;
    realCopy(&asymptote.x, &xCenter);
    stringToReal("1e-3", &offset, ctxtGraphs); // Small x offset
    int32ToReal(10000, &c10000);

    var offsets: ?[*]const PointOffset = null;

    if (asymptote.hasPositive and asymptote.hasNegative) {
        offsets = &asymptote_offsets_both;
    } else if (asymptote.hasPositive) {
        offsets = &asymptote_offsets_positive;
    } else if (asymptote.hasNegative) {
        offsets = &asymptote_offsets_negative;
    }

    if (offsets) |offs| {
        var i: usize = 0;
        while (i < 3) : (i += 1) {
            // x = xCenter + dx * offset
            realCopy(&xCenter, &x);
            if (offs[i].dx > 0) {
                realAdd(&x, &offset, &x, ctxtGraphs);
            } else if (offs[i].dx < 0) {
                realSubtract(&x, &offset, &x, ctxtGraphs);
            }
            // y = (dy == 0) ? 0 : dy * asymptoteHeight
            if (offs[i].dy == 0) {
                realSetZero(&y);
            } else if (offs[i].dy > 0) {
                realCopy(&c10000, &y);
            } else {
                realCopy(&c10000, &y);
                graphChangeSign(&y);
            }
            convertRealToReal34Register(&x, REGISTER_X);
            convertRealToReal34Register(&y, REGISTER_Y);
            AddtoDrawMx();
        }
    }
}

pub export fn detectTrueDiscontinuityWithAsymptote(y0: *align(1) const real_t, y1: *align(1) const real_t, y2: *align(1) const real_t, grad0: *align(1) const real_t, grad1: *align(1) const real_t, grad2: *align(1) const real_t, yAvg: *align(1) const real_t, count: c_int, x0: *align(1) const real_t, x1: *align(1) const real_t, x2: *align(1) const real_t, xMin: *align(1) const real_t, xMax: *align(1) const real_t, yMin: *align(1) const real_t, yMax: *align(1) const real_t, asymptotes: [*c]AsymptoteInfo, asymptoteCount: *c_int) callconv(.c) bool {
    _ = x1;
    // NaN/infinite samples are domain gaps, not discontinuities
    if (realIsSpecial(y0) or realIsSpecial(y1) or realIsSpecial(y2)) {
        return false;
    }

    // If not a vertical asymptote, do discontinuity detection
    const hasDiscontinuity: bool = detectTrueDiscontinuity(y0, y1, y2, grad0, grad1, grad2, yAvg, count);

    if (hasDiscontinuity and count >= 4 and asymptoteCount.* < MAX_ASYMPTOTES) {
        // Check if this discontinuity might be an asymptote using the detailed method
        var gapWidth: real_t = undefined;
        var xGap: real_t = undefined;
        var diff: real_t = undefined;
        var sumX: real_t = undefined;
        realSubtract(x2, x0, &diff, ctxtGraphs);
        realCopyAbs(&diff, &gapWidth);
        realAdd(x0, x2, &sumX, ctxtGraphs);
        realCopy(&sumX, &xGap);
        realDivideBy2(&xGap, ctxtGraphs); // (x0 + x2) / 2

        var candidateAsymptote: AsymptoteInfo = undefined;

        if (detectAndCharacterizeAsymptote(x0, y0, x2, y2, &xGap, &gapWidth, xMin, xMax, yMin, yMax, &candidateAsymptote)) {
            // Store the asymptote
            asymptotes[@intCast(asymptoteCount.*)] = candidateAsymptote;
            asymptoteCount.* += 1;

            // Render the asymptote immediately
            renderAsymptote(&candidateAsymptote);

            // Return false to prevent normal discontinuity handling
            return false;
        }
    }

    return hasDiscontinuity;
}

// ===========================================================================
// graph_eqn (static)
// ===========================================================================
fn graph_eqn(mode: u16) void {
    var plotAborted: bool = false; // R/S/EXIT or a nested-engine abort: skip the draw and exit dead
    currentKeyCode = 255;
    calcMode = CM_GRAPH;
    saveForUndo();
    regStatsXY = findNamedVariable(&plotStatMx);

    // Configure the graph-local context: 14 working digits, full ctxtReal39 otherwise.
    ctxtGraphsLocal = ctxtReal39;
    ctxtGraphsLocal.digits = GRAPH_WORKING_DIGITS;

    var x: real_t = undefined;
    var x01: real_t = undefined;
    var y01: real_t = undefined;
    var y02: real_t = undefined;
    var y00: real_t = undefined; // Add y00 for improved discontinuity detection
    var dy: real_t = undefined;
    var dx0: real_t = undefined;
    var dx: real_t = undefined;
    var grad2: real_t = undefined;
    var grad1: real_t = undefined;
    var grad0: real_t = undefined;
    var prevDx: real_t = undefined; // Track previous step size
    var yAvg: real_t = undefined;
    var x_min_r: real_t = undefined; // real_t copy of external x_min
    var x_max_r: real_t = undefined; // real_t copy of external x_max
    var y_min_r: real_t = undefined; // real_t copy of external y_min
    var y_max_r: real_t = undefined; // real_t copy of external y_max
    var jumpBackStartX: real_t = undefined;
    var jumpBackStartY: real_t = undefined;
    var jumpBackX: real_t = undefined;
    var jumpBackDx: real_t = undefined;
    var jbY: real_t = undefined;
    var discontinuityThreshold: real_t = undefined;
    var curvatureChange: real_t = undefined;
    var newDx: real_t = undefined;
    var improvementRatio: real_t = undefined;
    var highResStartX: real_t = undefined;
    var cumulativeCurvatureChange: real_t = undefined;
    var baselineCurvatureChange: real_t = undefined;
    var savedXBeforeHighres: real_t = undefined;
    var savedDxBeforeHighres: real_t = undefined;
    var tmpA: real_t = undefined;
    var tmpB: real_t = undefined;
    var count: i16 = 0;
    var ss0: i16 = 0;
    var ss1: i16 = 0;
    var ss2: i16 = 0;
    var discontinuityDetected: u8 = 0;
    var grad2IncreaseDetected: bool = false;
    var loop: c_int = 0;
    var jumpedBack: bool = false;
    var asymptotes: [MAX_ASYMPTOTES]AsymptoteInfo = undefined;
    var asymptoteCount: c_int = 0;

    realPlus(x_min, &x_min_r, ctxtGraphs); // x_min_r = x_min rounded to the graph working digits
    realPlus(x_max, &x_max_r, ctxtGraphs);
    realPlus(y_min, &y_min_r, ctxtGraphs);
    realPlus(y_max, &y_max_r, ctxtGraphs);
    realCopy(&x_min_r, &x01);
    realSetZero(&y01);
    realSetZero(&y02);
    realSetZero(&y00);
    realSetZero(&dy);
    realSubtract(&x_max_r, &x_min_r, &tmpA, ctxtGraphs);
    int32ToReal(400, &tmpB); // SCREEN_WIDTH_GRAPH
    realDivide(&tmpA, &tmpB, &tmpA, ctxtGraphs);
    realMultiply(&tmpA, consts.const_10(), &dx0, ctxtGraphs);
    realCopy(&dx0, &dx);
    realSetOne(&grad2);
    realSetOne(&grad1);
    realSetOne(&grad0);
    realCopy(&dx0, &prevDx);
    realCopy(consts.const_1on10(), &yAvg);

    if (graphVariabl1 < FIRST_NAMED_VARIABLE or graphVariabl1 > LAST_NAMED_VARIABLE) {
        regStatsXY = INVALID_VARIABLE;
        return;
    }

    fillStackWithReal0();

    convertRealToReal34RegisterPush(&x_max_r, REGISTER_X);
    execute_rpn_function_graphAcc();
    convertRegisterToReal(REGISTER_Y, &tmpA);
    realCopyAbs(&tmpA, &tmpA);
    realFMA(consts.const_2(), &tmpA, &yAvg, &yAvg, ctxtGraphs); // yAvg += 2 * |f(x_max)|

    if (mode == initDrwMx) {
        fnClDrawMx(3);
        _ = strcpy(&plotStatMx, "DrwMX");
        asymptoteCount = 0; // Reset asymptote tracking for new plot
    }

    // Main loop, default is 40 x 6 point gaps, across the 240 wide screen
    //  If the gradient is increasing, then the dx is reduced.
    var highResBuffer: [@intCast(HIGH_RES_SAMPLE_COUNT)]PlotPoint = undefined;
    var highResCount: c_int = 0;
    var inHighResMode: bool = false;
    realSetZero(&highResStartX);
    realSetZero(&cumulativeCurvatureChange);
    realSetZero(&baselineCurvatureChange);
    realSetZero(&savedXBeforeHighres);
    realCopy(&dx0, &savedDxBeforeHighres);

    realCopy(&x_min_r, &x);
    while (true) {
        // x <= x_max ?
        if (realCompareGreaterThan(&x, &x_max_r)) break;

        // R/S/EXIT or a nested-engine abort stops the plot
        if (lastErrorCode == ERROR_SOLVER_ABORT or programRunStop == PGM_WAITING or exitKeyWaiting()) {
            lastErrorCode = ERROR_SOLVER_ABORT;
            if (programRunStop == PGM_RUNNING) {
                programRunStop = PGM_WAITING;
            }
            plotAborted = true;
            break;
        }

        jumpedBack = false;
        // x = max(x_min, min(x_max, x))
        if (realCompareGreaterThan(&x, &x_max_r)) realCopy(&x_max_r, &x);
        if (realCompareLessThan(&x, &x_min_r)) realCopy(&x_min_r, &x);

        convertRealToReal34RegisterPush(&x, REGISTER_X);
        execute_rpn_function_graphAcc();

        if (lastErrorCode == ERROR_SOLVER_ABORT or programRunStop == PGM_WAITING or exitKeyWaiting()) {
            lastErrorCode = ERROR_SOLVER_ABORT;
            if (programRunStop == PGM_RUNNING) {
                programRunStop = PGM_WAITING;
            }
            plotAborted = true;
            break;
        }

        advance: {
            // Handle complex plotting
            if (getSystemFlag(FLAG_CPXPLOT)) {
                fnRCL(REGISTER_Y);
                fnStore(@bitCast(TEMP_REGISTER_1));
                fnImaginaryPart(0);
                fnRCL(TEMP_REGISTER_1);
                fnRealPart(0);
                AddtoDrawMx();
                break :advance; // goto incrementX
            }

            reduceRegisterYToComponent();
            convertRegisterToReal(REGISTER_Y, &y02);

            // === Begin of skip and jump section
            if (count > 0) {
                realSubtract(&y02, &y01, &dy, ctxtGraphs);
                if (!realCompareEqual(&x, &x01)) {
                    realSubtract(&x, &x01, &tmpA, ctxtGraphs);
                    realDivide(&dy, &tmpA, &grad2, ctxtGraphs);
                } else {
                    realSetZero(&grad2);
                }

                // Update sign states
                ss0 = ss1;
                ss1 = ss2;
                ss2 = if (graphIsZero(&grad2)) @as(i16, 0) else if (graphIsNegative(&grad2)) @as(i16, -1) else @as(i16, 1);
                realCopy(&grad1, &grad0);
                realCopy(&grad2, &grad1);

                // Detect gradient anomalies using improved logic
                if (!graphIsZero(&grad1) and !graphIsZero(&grad2)) {
                    var absY02OverY01: real_t = undefined;
                    var absY01OverY02: real_t = undefined;
                    var absG2OverG1: real_t = undefined;
                    var absG1OverG2: real_t = undefined;
                    var absY00: real_t = undefined;
                    var absY01: real_t = undefined;
                    var absY02: real_t = undefined;
                    var twoAbsY01: real_t = undefined;
                    var absG2mG1: real_t = undefined;
                    var absG1mG0: real_t = undefined;
                    var tenAbsG1mG0: real_t = undefined;
                    var ss2_r: real_t = undefined;
                    var oneOhOne: real_t = undefined;

                    stringToReal("1.01", &oneOhOne, ctxtGraphs);
                    convertDoubleToReal(SS2, &ss2_r, ctxtGraphs);

                    realDivide(&y02, &y01, &tmpA, ctxtGraphs);
                    realCopyAbs(&tmpA, &absY02OverY01);
                    realDivide(&y01, &y02, &tmpA, ctxtGraphs);
                    realCopyAbs(&tmpA, &absY01OverY02);
                    realDivide(&grad2, &grad1, &tmpA, ctxtGraphs);
                    realCopyAbs(&tmpA, &absG2OverG1);
                    realDivide(&grad1, &grad2, &tmpA, ctxtGraphs);
                    realCopyAbs(&tmpA, &absG1OverG2);
                    realCopyAbs(&y00, &absY00);
                    realCopyAbs(&y01, &absY01);
                    realCopyAbs(&y02, &absY02);
                    realMultiply(consts.const_2(), &absY01, &twoAbsY01, ctxtGraphs);
                    realSubtract(&grad2, &grad1, &tmpA, ctxtGraphs);
                    realCopyAbs(&tmpA, &absG2mG1);
                    realSubtract(&grad1, &grad0, &tmpA, ctxtGraphs);
                    realCopyAbs(&tmpA, &absG1mG0);
                    realMultiply(consts.const_10(), &absG1mG0, &tenAbsG1mG0, ctxtGraphs);

                    const a1: bool = realCompareGreaterThan(&absY02OverY01, &oneOhOne);
                    const a2: bool = realCompareGreaterThan(&absG2OverG1, &ss2_r);
                    const yRatioCheck1: bool = a1 and a2;

                    const b1: bool = realCompareGreaterThan(&absY01OverY02, &oneOhOne);
                    const b2: bool = realCompareGreaterThan(&absG1OverG2, &ss2_r);
                    const yRatioCheck2: bool = b1 and b2;

                    // Conservative oscillation detection - only flag if truly problematic
                    const y02BigEnough: bool = realCompareGreaterThan(&absY02, &twoAbsY01);
                    const y00BigEnough: bool = realCompareGreaterThan(&absY00, &twoAbsY01);
                    const signOscillation1: bool = (ss0 == 1 and ss1 == -1 and ss2 == 1) and y02BigEnough and y00BigEnough;
                    const signOscillation2: bool = (ss0 == -1 and ss1 == 1 and ss2 == -1) and y02BigEnough and y00BigEnough;

                    // Zero crossing detection - only if accompanied by large gradient changes
                    const bigGradJump: bool = realCompareGreaterThan(&absG2mG1, &tenAbsG1mG0);
                    const y01Pos: bool = !graphIsZero(&y01) and graphIsPositive(&y01);
                    const y02Neg: bool = graphIsNegative(&y02);
                    const y01Neg: bool = graphIsNegative(&y01);
                    const y02Pos: bool = !graphIsZero(&y02) and graphIsPositive(&y02);
                    const zeroCrossing1: bool = (ss1 == 1 and ss2 == -1 and y01Pos and y02Neg) and bigGradJump;
                    const zeroCrossing2: bool = (ss1 == -1 and ss2 == 1 and y01Neg and y02Pos) and bigGradJump;

                    grad2IncreaseDetected = yRatioCheck1 or yRatioCheck2 or signOscillation1 or signOscillation2 or zeroCrossing1 or zeroCrossing2;
                } else {
                    grad2IncreaseDetected = false;
                }

                // Update running average (count == 0 path intentionally absent)
                realCopyAbs(&y02, &tmpA);
                if (realCompareGreaterThan(&tmpA, &yAvg)) {
                    int32ToReal(@as(i32, count), &tmpB);
                    realDivide(&tmpA, &tmpB, &tmpA, ctxtGraphs); // |y02|/count
                    realAdd(&yAvg, &tmpA, &yAvg, ctxtGraphs);
                }

                // Use improved discontinuity detection
                if (discontinuityDetected == 0) {
                    var x00: real_t = undefined;
                    if (count > 1) {
                        realSubtract(&x01, &dx, &x00, ctxtGraphs);
                    } else {
                        realCopy(&x_min_r, &x00);
                    }
                    const trueDiscontinuity: bool = detectTrueDiscontinuityWithAsymptote(&y00, &y01, &y02, &grad0, &grad1, &grad2, &yAvg, count, &x00, &x01, &x, &x_min_r, &x_max_r, &y_min_r, &y_max_r, &asymptotes, &asymptoteCount);
                    if (trueDiscontinuity) {
                        discontinuityDetected = @intCast(FINE);
                    }
                }

                // Jump-back logic for discontinuities and gradient increases
                if ((discontinuityDetected == FINE) or (discontinuityDetected == 0 and grad2IncreaseDetected)) {
                    // If in high-res mode, abandon it since we're jumping back anyway
                    if (inHighResMode) {
                        abandonHighResMode(&highResCount, &inHighResMode);
                    }

                    // Store the current position and original discontinuity trigger
                    realCopy(&x, &jumpBackStartX);
                    realCopy(&y02, &jumpBackStartY);
                    const wasDiscontinuity: bool = (discontinuityDetected == FINE);
                    // discontinuityThreshold = wasDiscontinuity ? |y02 - y01| * 0.1 : 0
                    if (wasDiscontinuity) {
                        realSubtract(&y02, &y01, &tmpA, ctxtGraphs);
                        realCopyAbs(&tmpA, &tmpA);
                        realMultiply(&tmpA, consts.const_1on10(), &discontinuityThreshold, ctxtGraphs);
                    } else {
                        realSetZero(&discontinuityThreshold);
                    }

                    // x -= dx * JMP
                    convertDoubleToReal(JMP, &tmpA, ctxtGraphs);
                    realMultiply(&dx, &tmpA, &tmpB, ctxtGraphs);
                    realSubtract(&x, &tmpB, &x, ctxtGraphs);
                    jumpedBack = true;
                    convertRealToReal34RegisterPush(&x, REGISTER_X);
                    execute_rpn_function_graphAcc();
                    reduceRegisterYToComponent();
                    convertRegisterToReal(REGISTER_Y, &y02);
                    // grad2 = (y02 - y01) / (x - x01)
                    realSubtract(&y02, &y01, &tmpA, ctxtGraphs);
                    realSubtract(&x, &x01, &tmpB, ctxtGraphs);
                    realDivide(&tmpA, &tmpB, &grad2, ctxtGraphs);
                    ss0 = ss1;
                    ss1 = ss2;
                    ss2 = if (graphIsZero(&grad2)) @as(i16, 0) else if (graphIsNegative(&grad2)) @as(i16, -1) else @as(i16, 1);

                    // Sample the fine-stepped points
                    var jumpBackBuffer: [@intCast(FINE)]PlotPoint = undefined;
                    var jumpBackCount: c_int = 0;
                    realCopy(&x, &jumpBackX);
                    // jumpBackDx = dJMP * dx0
                    convertDoubleToReal(dJMP, &tmpA, ctxtGraphs);
                    realMultiply(&tmpA, &dx0, &jumpBackDx, ctxtGraphs);

                    var jbStep: c_int = 0;
                    while (jbStep < FINE) : (jbStep += 1) {
                        // jumpBackX < jumpBackStartX ?
                        if (realCompareGreaterEqual(&jumpBackX, &jumpBackStartX)) break;

                        convertRealToReal34RegisterPush(&jumpBackX, REGISTER_X);
                        execute_rpn_function_graphAcc();
                        reduceRegisterYToComponent();
                        convertRegisterToReal(REGISTER_Y, &jbY);

                        jumpBackBuffer[@intCast(jumpBackCount)].stored = false;
                        realCopy(&jumpBackX, &jumpBackBuffer[@intCast(jumpBackCount)].x);
                        realCopy(&jbY, &jumpBackBuffer[@intCast(jumpBackCount)].y);
                        jumpBackCount += 1;
                        realAdd(&jumpBackX, &jumpBackDx, &jumpBackX, ctxtGraphs);
                    }

                    var shouldCommitPoints: bool = false;

                    if (wasDiscontinuity) {
                        // For discontinuity cases, validate that fine points actually resolve the discontinuity
                        const discontinuityResolved: bool = validateDiscontinuityResolution(&jumpBackBuffer, jumpBackCount, &y01, &jumpBackStartY, &discontinuityThreshold);
                        if (discontinuityResolved) {
                            shouldCommitPoints = true;
                            discontinuityDetected = 0; // Clear discontinuity flag
                        } else {
                            discontinuityDetected = 0; // Clear flag
                            shouldCommitPoints = false;
                        }
                    } else {
                        // For gradient increase cases, evaluate in normalised (double) coordinates
                        if (jumpBackCount >= 3) {
                            var spanX: real_t = undefined;
                            var spanY: real_t = undefined;
                            realSubtract(&jumpBackStartX, &x01, &spanX, ctxtGraphs); // spanX = jumpBackStartX - x01
                            realSubtract(&jumpBackStartY, &y01, &spanY, ctxtGraphs); // spanY = jumpBackStartY - y01
                            if (realIsZero(&spanY)) { // flat region
                                realCopy(&spanX, &spanY);
                            }
                            if (realIsZero(&spanX)) { // zero-width region: keep the points
                                shouldCommitPoints = true;
                            } else {
                                // Calculate curvature variation in the jump-back region
                                var maxCurvD: f64 = 0;
                                var i: c_int = 1;
                                while (i < jumpBackCount - 1) : (i += 1) {
                                    const xi: f64 = normCoord(&jumpBackBuffer[@intCast(i)].x, &x01, &spanX);
                                    const xim1: f64 = normCoord(&jumpBackBuffer[@intCast(i - 1)].x, &x01, &spanX);
                                    const xip1: f64 = normCoord(&jumpBackBuffer[@intCast(i + 1)].x, &x01, &spanX);
                                    const yi: f64 = normCoord(&jumpBackBuffer[@intCast(i)].y, &y01, &spanY);
                                    const yim1: f64 = normCoord(&jumpBackBuffer[@intCast(i - 1)].y, &y01, &spanY);
                                    const yip1: f64 = normCoord(&jumpBackBuffer[@intCast(i + 1)].y, &y01, &spanY);
                                    const g1d: f64 = (yi - yim1) / (xi - xim1);
                                    const g2d: f64 = (yip1 - yi) / (xip1 - xi);
                                    const curvChangeD: f64 = fabs(g2d - g1d);
                                    if (curvChangeD > maxCurvD) {
                                        maxCurvD = curvChangeD;
                                    }
                                }
                                // Compare with linear interpolation
                                const jumpBackStartYd: f64 = normCoord(&jumpBackStartY, &y01, &spanY);
                                const jumpBackStartXd: f64 = normCoord(&jumpBackStartX, &x01, &spanX);
                                const y01d: f64 = 0.0;
                                const x01d: f64 = 0.0;
                                const linearSlopeD: f64 = (jumpBackStartYd - y01d) / (jumpBackStartXd - x01d);
                                var interpErrD: f64 = 0;
                                var j: c_int = 0;
                                while (j < jumpBackCount) : (j += 1) {
                                    const xi: f64 = normCoord(&jumpBackBuffer[@intCast(j)].x, &x01, &spanX);
                                    const yi: f64 = normCoord(&jumpBackBuffer[@intCast(j)].y, &y01, &spanY);
                                    const expectedYd: f64 = y01d + linearSlopeD * (xi - x01d);
                                    const errD: f64 = fabs(yi - expectedYd);
                                    if (errD > interpErrD) {
                                        interpErrD = errD;
                                    }
                                }
                                // Points are useful if they show significant non-linear behavior
                                const jumpBackPointsUseful: bool = (interpErrD > 0.1 * fabs(jumpBackStartYd - y01d)) or (maxCurvD > fabs(linearSlopeD) * 0.5);
                                shouldCommitPoints = jumpBackPointsUseful;
                            }
                        }
                    }

                    if (shouldCommitPoints) { // fine points
                        var i: c_int = 0;
                        while (i < jumpBackCount) : (i += 1) {
                            convertRealToReal34RegisterPush(&jumpBackBuffer[@intCast(i)].x, REGISTER_X);
                            execute_rpn_function_graphAcc();
                            reduceRegisterYToComponent();
                            AddtoDrawMx();
                        }

                        // Also plot the original grid point (jumpBackStartX, jumpBackStartY)
                        convertRealToReal34RegisterPush(&jumpBackStartX, REGISTER_X);
                        execute_rpn_function_graphAcc();
                        reduceRegisterYToComponent();
                        AddtoDrawMx();

                        // Set position to continue from the original grid point
                        realCopy(&jumpBackStartX, &x);
                        realCopy(&jumpBackStartY, &y02);
                        realCopy(&dx0, &dx); // Reset to original step size
                        jumpedBack = false; // Clear flag since we've handled the plotting
                    } else { // not fine points
                        // Restore to the original grid point and continue normal processing
                        realCopy(&jumpBackStartX, &x);
                        realCopy(&jumpBackStartY, &y02);
                        realCopy(&dx0, &dx); // Revert to original step size
                        jumpedBack = false; // Clear flag so the original point gets plotted normally

                        // Recalculate gradient for the original point
                        realSubtract(&y02, &y01, &tmpA, ctxtGraphs);
                        realSubtract(&x, &x01, &tmpB, ctxtGraphs);
                        realDivide(&tmpA, &tmpB, &grad2, ctxtGraphs);
                        ss0 = ss1;
                        ss1 = ss2;
                        ss2 = if (graphIsZero(&grad2)) @as(i16, 0) else if (graphIsNegative(&grad2)) @as(i16, -1) else @as(i16, 1);
                    }
                }

                // Calculate curvature change for resolution assessment
                realSetZero(&curvatureChange);
                if (count > 1 and !graphIsZero(&grad0) and !graphIsZero(&grad1)) {
                    // curvatureChange = |(grad2 - grad1) - (grad1 - grad0)|
                    realSubtract(&grad2, &grad1, &tmpA, ctxtGraphs);
                    realSubtract(&grad1, &grad0, &tmpB, ctxtGraphs);
                    realSubtract(&tmpA, &tmpB, &tmpA, ctxtGraphs);
                    realCopyAbs(&tmpA, &curvatureChange);
                }

                // Determine new step size and resolution mode
                calculateNewStepSize(discontinuityDetected, &grad1, &grad2, grad2IncreaseDetected, &dx0, &newDx);

                // Check if we're entering high-resolution mode (only if not jumped back)
                // newDx < prevDx * REVERT_THRESHOLD ?
                convertDoubleToReal(REVERT_THRESHOLD, &tmpA, ctxtGraphs);
                realMultiply(&prevDx, &tmpA, &tmpB, ctxtGraphs);
                const newDxBelowThresh: bool = realCompareLessThan(&newDx, &tmpB);
                const curvNonZero: bool = !graphIsZero(&curvatureChange) and graphIsPositive(&curvatureChange);
                if (!jumpedBack and !inHighResMode and newDxBelowThresh and discontinuityDetected == 0 and curvNonZero) {
                    realCopy(&x01, &savedXBeforeHighres); // Save the last good x position
                    realCopy(&prevDx, &savedDxBeforeHighres);
                    enterHighResMode(&inHighResMode, &highResCount, &highResStartX, &baselineCurvatureChange, &cumulativeCurvatureChange, &x, &curvatureChange);
                }

                // If in high-res mode, buffer the point and assess improvement
                if (inHighResMode and !jumpedBack) {
                    realAdd(&cumulativeCurvatureChange, &curvatureChange, &cumulativeCurvatureChange, ctxtGraphs);

                    if (highResCount < HIGH_RES_SAMPLE_COUNT) { // Buffer high-res points in order
                        realCopy(&x, &highResBuffer[@intCast(highResCount)].x);
                        realCopy(&y02, &highResBuffer[@intCast(highResCount)].y);
                        realCopy(&grad2, &highResBuffer[@intCast(highResCount)].grad);
                        highResBuffer[@intCast(highResCount)].stored = false;
                        highResCount += 1;
                    } else {
                        // improvementRatio = (baseline > 0) ? cumCurv / (baseline * count_r) : 1
                        const baselinePos: bool = !graphIsZero(&baselineCurvatureChange) and graphIsPositive(&baselineCurvatureChange);
                        if (baselinePos) {
                            realMultiply(&baselineCurvatureChange, consts.const_3(), &tmpB, ctxtGraphs);
                            realDivide(&cumulativeCurvatureChange, &tmpB, &improvementRatio, ctxtGraphs);
                        } else {
                            realSetOne(&improvementRatio);
                        }

                        convertDoubleToReal(MIN_IMPROVEMENT_RATIO, &tmpA, ctxtGraphs);
                        if (realCompareGreaterEqual(&improvementRatio, &tmpA)) { // High-res beneficial, commit buffered points
                            commitHighResPointsInOrder(&highResBuffer, highResCount);
                            resetHighResTracking(&highResCount, &inHighResMode, &cumulativeCurvatureChange);
                            // Continue with current step size
                        } else { // High-res didn't help, abandon and continue from last good point with larger dx
                            abandonHighResMode(&highResCount, &inHighResMode);
                            realAdd(&savedXBeforeHighres, &savedDxBeforeHighres, &x, ctxtGraphs);
                            realCopy(&savedDxBeforeHighres, &dx);
                            break :advance; // goto incrementX
                        }
                    }
                }

                realCopy(&dx, &prevDx);
                realCopy(&newDx, &dx);
            }
            // < End of skip and jump section

            // Add point to plot (skip if in high-res buffering mode or jumped back)
            // dx >= 0 ?
            if (!jumpedBack and !graphIsNegative(&dx) and !inHighResMode) {
                AddtoDrawMx();
            }

            // Update state for next iteration
            if (count > 0) {
                realCopy(&grad2, &grad1);
            }
            realCopy(&y01, &y00); // Update y00 for improved discontinuity detection
            realCopy(&y02, &y01);
            realCopy(&x, &x01);

            if (discontinuityDetected != 0) {
                discontinuityDetected -= 1;
            }

            count += 1;
            if (count > 60) {
                break;
            }

            loop += 1;
            if (checkHalfSec()) {
                _ = progressHalfSecUpdate_Integer(timed, "Iter: ", loop, halfSec_clearZ, halfSec_clearT, halfSec_disp); // timed
            }

            if (comptime is_dmcp_build) {
                if (exitKeyWaiting()) {
                    _ = progressHalfSecUpdate_Integer(force + 1, "Interrupted Iter:", loop, halfSec_clearZ, halfSec_clearT, halfSec_disp);
                    lastErrorCode = ERROR_SOLVER_ABORT;
                    if (programRunStop == PGM_RUNNING) {
                        programRunStop = PGM_WAITING;
                    }
                    plotAborted = true;
                    break;
                }
            }
        }

        // incrementX: x += STEP_OFFSET * dx
        convertDoubleToReal(STEP_OFFSET, &tmpA, ctxtGraphs);
        realMultiply(&tmpA, &dx, &tmpB, ctxtGraphs);
        realAdd(&x, &tmpB, &x, ctxtGraphs);
    }

    if (inHighResMode and highResCount > 0) {
        abandonHighResMode(&highResCount, &inHighResMode);
    }

    if (!plotAborted) { // leave the interrupted stack intact; a completed plot clears it as before
        fillStackWithReal0();
    }

    // LOW_GRAPH_ACC: narrow to screen digits for the plot render, then restore.
    const s34 = ctxtReal34.digits;
    const s39 = ctxtReal39.digits;
    const s51 = ctxtReal51.digits;
    const s75 = ctxtReal75.digits;
    if (significantDigitsForEqnGraphs() <= 6) {
        ctxtReal34.digits = significantDigitsForScreen;
        ctxtReal39.digits = significantDigitsForScreen + 3;
    }

    const showGraph: bool = !plotAborted;
    if (showGraph) {
        if (!(calcMode == CM_PLOT_STAT or calcMode == CM_GRAPH)) { // !GRAPHMODE: change over hourglass to the left side
            clearScreenOld(true, !true, !true); // clrStatusBar, !clrRegisterLines, !clrSoftkeys
        }
        calcMode = CM_GRAPH;
        hourGlassIconEnabled = true; // clear the current portion of statusbar
        showHideHourGlass();
        refreshStatusBar();
        fnPlot(0);
    } else { // interrupted plot: stop dead on the PLT step, do not enter the graph view
        calcMode = CM_NORMAL;
        screenUpdatingMode = SCRUPD_AUTO;
        screenUpdatingMode |= SCRUPD_SKIP_STATUSBAR_ONE_TIME;
    }

    ctxtReal34.digits = s34;
    ctxtReal39.digits = s39;
    ctxtReal51.digits = s51;
    ctxtReal75.digits = s75;
}

// ===========================================================================
// graph_stat
// ===========================================================================
pub export fn graph_stat(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    saveForUndo();
    _ = strcpy(&plotStatMx, "STATS");

    if (statMxN() != 0) {
        lastPlotMode = PLOT_NOTHING;
        calcMode = CM_GRAPH;
        reDraw = true;
        PLOT_SHADE = true;

        if (!getSystemFlag(FLAG_PLINE) and !getSystemFlag(FLAG_PCROS) and !getSystemFlag(FLAG_PBOX) and !getSystemFlag(FLAG_PPLUS)) {
            fnPline(NOPARAM);
        }

        fillStackWithReal0();
        fnPlotSQ(0);
    } else {
        calcMode = CM_NORMAL;
        displayCalcErrorMessage(ERROR_NO_SUMMATION_DATA, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function graph_stat:", "There is no statistical/plot data available!", null, null);
    }
}

// ===========================================================================
// COMPLEX SOLVER helpers
// ===========================================================================
inline fn checkRealZeroTol(a: *const real_t, tol: *const real_t) bool {
    return realIsZero(a) or realCompareAbsLessThan(a, tol);
}

inline fn check2RealZeroTol(a: *const real_t, b: *const real_t, tol: *const real_t) bool {
    return checkRealZeroTol(a, tol) and checkRealZeroTol(b, tol);
}

// Now provided by registerValueConversions (shared, real master); use that one.
extern fn convertComplexRegisterToRealIfZeroImag(regist: calcRegister_t) void;

fn divFunctionComplex(a_re: *const real_t, a_im: *const real_t, b_re: *const real_t, b_im: *const real_t, res_re: *real_t, res_im: *real_t) void {
    if ((realIsZero(a_re) and realIsZero(a_im)) or realIsNaN(a_re) or realIsNaN(a_im) or realIsNaN(b_re) or realIsNaN(b_im)) {
        realSetZero(res_re);
        realSetZero(res_im);
        return;
    }
    if (realIsZero(b_re) and realIsZero(b_im)) {
        stringToReal("1E30", res_re, ctxtSolver2);
        realSetZero(res_im);
        return;
    }
    divComplexComplex(a_re, a_im, b_re, b_im, res_re, res_im, ctxtSolver2);
}

pub export fn check_osc(new: *real_t, old: *real_t, ii: *u8) callconv(.c) bool {
    if ((realGetSign(new) ^ realGetSign(old)) != 0) {
        ii.* = (ii.* << 1) + 1;
    } else {
        ii.* = ii.* << 1;
    }

    switch (ii.* & 0b00111111) {
        0b010101, 0b101010, 0b111111 => return true,
        else => {},
    }
    switch (ii.*) {
        0b01101101, 0b11011011, 0b10110110, 0b00100100, 0b01001001, 0b10010010, 0b11001100, 0b10011001, 0b00110011, 0b01100110 => return true,
        else => {},
    }
    return false;
}

// PC_BUILD console result dump (host sim and testSuite are PC_BUILD).
fn printSolverResult(iterationCounter: c_int) void {
    if (comptime !is_dmcp_build) {
        var str: [200]u8 = undefined;
        _ = decQuadToString(reg34(REGISTER_X), &str);
        _ = printf("\n\n\x1b[1m%2u: %-36s ", @as(c_uint, significantDigits), @as([*c]const u8, &str));
        _ = decQuadToString(regImag34(REGISTER_X), &str);
        if (real34IsNegative(regImag34(REGISTER_X))) {
            _ = printf("- ix%-36s", @as([*c]const u8, &str) + 1);
        } else {
            _ = printf("+ ix%-36s", @as([*c]const u8, &str));
        }
        _ = printf(" (iter:%2i code:%i)\x1b[0m\n\n", iterationCounter, real34ToInt32(reg34(REGISTER_T)));
    }
}

fn printComplexToConsole(re: *const real_t, im: *const real_t, before: [*:0]const u8, after: [*:0]const u8) void {
    if (comptime !is_dmcp_build) {
        var str: [100]u8 = undefined;
        _ = decNumberToString(re, &str);
        _ = printf("%s%43s + ", before, @as([*c]const u8, &str));
        _ = decNumberToString(im, &str);
        _ = printf("%43si %s", @as([*c]const u8, &str), after);
    }
}

inline fn copyComplex(from: *const cplx_t, to: *cplx_t) void {
    realCopy(&from.Real, &to.Real);
    realCopy(&from.Imag, &to.Imag);
}

// saves best solution to cpxSlvBestX and returns true if converging
fn execute_rpn_function_reals(from: *const cplx_t, to: *cplx_t, magnitude: *real_t) bool {
    convertComplexToResultRegister(&from.Real, &from.Imag, REGISTER_X);
    execute_rpn_function();
    _ = getRegisterAsComplex(REGISTER_Y, &to.Real, &to.Imag);
    complexMagnitude(&to.Real, &to.Imag, magnitude, ctxtSolver2);
    if (realCompareLessEqual(magnitude, &cpxSlvBestMagnitudeY)) {
        copyComplex(from, &cpxSlvBestX);
        if (realCompareLessThan(magnitude, &cpxSlvBestMagnitudeY)) {
            realCopy(magnitude, &cpxSlvBestMagnitudeY);
        }
        return true;
    }
    return false;
}

inline fn powCplxNat(base: *const cplx_t, exp: *const u8, res: *cplx_t) void {
    var tmp: cplx_t = undefined;
    copyComplex(base, &tmp);
    var i: u8 = 1;
    while (i < exp.*) : (i += 1) {
        mulComplexComplex(&tmp.Real, &tmp.Imag, &base.Real, &base.Imag, &tmp.Real, &tmp.Imag, ctxtSolver2);
    }
    copyComplex(&tmp, res);
}

// ===========================================================================
// complexSolver (static) — input parameters in REGISTER_X / REGISTER_Y
// ===========================================================================
fn complexSolver() void {
    currentKeyCode = 255;
    if (graphVariabl1 <= 0 or @as(i32, graphVariabl1) > LAST_LABEL) {
        if (comptime !is_dmcp_build) {
            _ = printf("Error: No complex solver variable %u\n", @as(c_uint, @bitCast(@as(c_int, graphVariabl1))));
        }
        return;
    }

    calcMode = CM_NO_UNDO;

    runFunction(ITM_RAD);
    setSystemFlag(FLAG_CPXRES);
    var oscillationIterationCounter: i16 = 0;
    var oscillations: i16 = 0;
    var convergent: i16 = 0;
    var iterAfterBest: i16 = 0;
    var iterationCounter: c_int = 0;
    var checkNaN: bool = false;
    var Y2IsZero: bool = false;
    var Y2IsCloseToZero: bool = false;
    const dXdYIsZero: bool = false;
    osc = 0;
    DXR = 0;
    DYR = 0;
    DXI = 0;
    DYI = 0;
    var kicker: i16 = 1;
    var yPower: u8 = 1;

    var f: real_t = undefined;
    var tol: real_t = undefined;
    var tolClose: real_t = undefined;
    var oldMagnitudeY: real_t = undefined;
    var magnitudeY: real_t = undefined;

    var X0: cplx_t = undefined;
    var X1: cplx_t = undefined;
    var X2: cplx_t = undefined;
    var X2N: cplx_t = undefined;
    var dX: cplx_t = undefined;
    var dXold: cplx_t = undefined;

    var Y0: cplx_t = undefined;
    var Y1: cplx_t = undefined;
    var Y2: cplx_t = undefined;
    var Y2N: cplx_t = undefined;
    var dY: cplx_t = undefined;
    var dYold: cplx_t = undefined;

    var temp0: cplx_t = undefined;
    var temp1: cplx_t = undefined;
    var temp2: cplx_t = undefined;
    var temp3: cplx_t = undefined;

    // Initialize
    _ = getRegisterAsComplex(REGISTER_X, &X1.Real, &X1.Imag);
    _ = getRegisterAsComplex(REGISTER_Y, &X0.Real, &X0.Imag);
    copyComplex(&X0, &cpxSlvBestX);

    realCopy(consts.c5568(), &cpxSlvBestMagnitudeY);

    // if input parameters X0 and X1 are the same, add a random number to X0
    if (realCompareEqual(&X0.Real, &X1.Real) and realCompareEqual(&X0.Imag, &X1.Imag)) {
        if (comptime !is_dmcp_build) {
            _ = printf(">>> ADD 1 to second input parameter to prevent infinite result\n");
        }
        realAdd(&X1.Real, consts.c4856(), &X1.Real, ctxtSolver2);
    }

    realSetZero(&dXold.Real);
    realSetZero(&dXold.Imag);
    copyComplex(&dXold, &dYold);
    copyComplex(&dXold, &X2N);
    copyComplex(&dXold, &dX);
    // initial value for difference comparison must be larger than tolerance
    realCopy(consts.c4520(), &dX.Real);
    copyComplex(&dX, &dY);

    realCopy(consts.c4580(), &f); // factor ()

    // set tolerance from significantDigits and use higher precision in execute_rpn_function();
    const signDig: u16 = if (significantDigits != 0) significantDigits else 34;

    realSetOne(&tol);
    tol.exponent -= if (signDig <= 4) 4 else (if (signDig > 32) 32 else @as(i32, signDig));
    realSetOne(&tolClose);
    tolClose.exponent -= if (signDig <= 4) 3 else (if (signDig > 27) 27 else @as(i32, signDig) - 1);
    fnSetSignificantDigits(34);

    _ = execute_rpn_function_reals(&X0, &Y0, &magnitudeY);
    _ = execute_rpn_function_reals(&X1, &Y1, &oldMagnitudeY);

    // check if an initial value is a solution
    if (checkRealZeroTol(&cpxSlvBestMagnitudeY, &tol)) {
        Y2IsZero = true;
    } else {
        subComplex(&Y1.Real, &Y1.Imag, &Y0.Real, &Y0.Imag, &temp1.Real, &temp1.Imag, ctxtSolver2); // dy=y1-y0
        // avoid equal Y as it causes double iterations
        if (check2RealZeroTol(&temp1.Real, &temp1.Imag, &tol)) {
            addComplex(&X0.Real, &X0.Imag, consts.c4508(), consts.c1708(), &X0.Real, &X0.Imag, ctxtSolver2);
            _ = execute_rpn_function_reals(&X0, &Y0, &magnitudeY);
            subComplex(&Y1.Real, &Y1.Imag, &Y0.Real, &Y0.Imag, &temp1.Real, &temp1.Imag, ctxtSolver2); // dy=y1-y0
        }
        subComplex(&X1.Real, &X1.Imag, &X0.Real, &X0.Imag, &temp0.Real, &temp0.Imag, ctxtSolver2); // dx=x1-x0
        divFunctionComplex(&temp0.Real, &temp0.Imag, &temp1.Real, &temp1.Imag, &temp0.Real, &temp0.Imag); // dx/dy
        mulComplexComplex(&temp0.Real, &temp0.Imag, &Y1.Real, &Y1.Imag, &temp0.Real, &temp0.Imag, ctxtSolver2); // deltaX = Y1 x dx/dy
        subComplex(&X1.Real, &X1.Imag, &temp0.Real, &temp0.Imag, &X2.Real, &X2.Imag, ctxtSolver2); // x2=x1-deltaX
        if (realIsZero(&X2.Imag)) {
            realMultiply(&X2.Real, consts.c4544(), &X2.Imag, ctxtSolver2);
        }
    }

    //###############################################################################################################
    //#################################################### Iteration start ##########################################
    while (iterationCounter < NUMBERITERATIONS and !checkNaN and !Y2IsZero and !dXdYIsZero) {
        if (lastErrorCode != 0) {
            if (comptime !is_dmcp_build) {
                _ = printf(">>> ERROR CODE INITIALLY NON-ZERO = %d <<<<<\n", @as(c_int, lastErrorCode));
            }
            break;
        }

        // Identify oscillations in real or imag: increment osc flag
        osc = @intFromBool(check_osc(&dY.Real, &dYold.Real, &DYR));
        osc = (osc << 1) + @as(i16, @intFromBool(check_osc(&dY.Imag, &dYold.Imag, &DYI)));
        osc = (osc << 1) + @as(i16, @intFromBool(check_osc(&dX.Real, &dXold.Real, &DXR)));
        osc = (osc << 1) + @as(i16, @intFromBool(check_osc(&dX.Imag, &dXold.Imag, &DXI)));

        // If osc flag is active, that is any delta polarity change, then increment oscillation count
        if (osc != 0 and (realGetExponent(&magnitudeY) - realGetExponent(&oldMagnitudeY) >= -2)) { // only increment if convergence is less than ca. 1 %, otherwise assume it is a damped oscillation
            oscillations += 1;
        } else {
            oscillations = @max(0, oscillations - 1);
        }

        // If converging, increment convergence counter
        if (realCompareLessThan(&magnitudeY, &oldMagnitudeY)) {
            convergent += 1;
        } else {
            if (Y2IsCloseToZero) {
                Y2IsZero = true; // if close to solution stop if converge strike is over
            } else {
                convergent = @max(-3, convergent - 2);
            }
        }
        realCopy(&magnitudeY, &oldMagnitudeY);

        if (!Y2IsZero) { // only do the convergence and oscillation checks if Y is not zero
            if (convergent > 6 and oscillations > 3) {
                convergent = 2;
                oscillations = 1;
            }

            if (((convergent <= -2 and kicker > @as(i16, yPower) * 3) or kicker > 8) and yPower < 5) {
                osc = 0;
                convergent = 0;
                oscillations = 0;
                kicker = 3;
                if (yPower > 1) {
                    _ = execute_rpn_function_reals(&X0, &Y0, &oldMagnitudeY);
                    _ = execute_rpn_function_reals(&X1, &Y1, &magnitudeY);
                }
                yPower += 2;
                powCplxNat(&Y0, &yPower, &Y0);
                powCplxNat(&Y1, &yPower, &Y1);
                if (comptime !is_dmcp_build) {
                    _ = printf("-------- yPower: %u, iter: %u\n", @as(c_uint, yPower), @as(c_uint, @intCast(iterationCounter)));
                }
            }
            copyComplex(&X2, &temp0);
            // If increment is oscillating it is assumed that it is unstable and needs to have a complex starting value
            if (iterationCounter == 0 or ((oscillations >= 2) and (oscillationIterationCounter > 10) // prime - 1 to not sync with oscillation
            and (convergent <= 2))) {
                oscillationIterationCounter = 0;
                oscillations = 0;
                convergent = 0;
                const kick: f64 = 0.8123 * @as(f64, @floatFromInt(kicker)) * @as(f64, @floatFromInt(kicker)) * pow(2.0, @floatFromInt(kicker));
                convertDoubleToReal(if (@rem(kicker, 2) != 0) -kick else kick, &temp1.Real, ctxtSolver2);
                convertDoubleToReal(kick, &temp1.Imag, ctxtSolver2);
                addComplex(&temp1.Real, &temp1.Imag, &X0.Real, &X0.Imag, &X2.Real, &X2.Imag, ctxtSolver2);
                if (comptime !is_dmcp_build) {
                    _ = printf("------- Kick #%d, iter:%u ", @as(c_int, kicker), @as(c_uint, @intCast(iterationCounter)));
                    printComplexToConsole(&temp1.Real, &temp1.Imag, "added: ", "\n");
                }
                kicker += 1;
            }
        }

        //@@@@@@@@@@@@@@@@@ CALCULATE NEW Y2, AND PLAUSIBILITY @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        // if same as cpxSlvBestX we probably hit the precision limit for this equation?
        subComplex(&cpxSlvBestX.Real, &cpxSlvBestX.Imag, &X2.Real, &X2.Imag, &temp1.Real, &temp1.Imag, ctxtSolver2);
        complexMagnitude(&temp1.Real, &temp1.Imag, &temp1.Real, ctxtSolver2);
        Y2IsCloseToZero = Y2IsCloseToZero or (realCompareLessThan(&cpxSlvBestMagnitudeY, consts.c4508()) and realIsZero(&temp1.Real) and realIsZero(&temp1.Imag));

        iterAfterBest = if (execute_rpn_function_reals(&X2, &Y2N, &magnitudeY)) 0 else iterAfterBest + 1;
        powCplxNat(&Y2N, &yPower, &Y2);
        if (realIsInfinite(&Y2.Real) or realIsInfinite(&Y2.Imag)) {
            // Revert kick
            if (comptime !is_dmcp_build) {
                _ = printf("----- Inf.Y iter:%u  revert kick", @as(c_uint, @intCast(iterationCounter)));
            }
            copyComplex(&temp0, &X2);
            _ = execute_rpn_function_reals(&X2, &Y2N, &magnitudeY);
            powCplxNat(&Y2N, &yPower, &Y2);
            kicker -= 2;
        }

        // check if an acceptable solution is found
        Y2IsZero = Y2IsZero or checkRealZeroTol(&magnitudeY, &tol);
        checkNaN = checkNaN or realIsNaN(&X2.Real) or realIsNaN(&X2.Imag) or
            realIsNaN(&Y2N.Real) or realIsNaN(&Y2N.Imag);
        Y2IsCloseToZero = Y2IsCloseToZero or checkRealZeroTol(&magnitudeY, &tolClose);

        // VERBOSE_SOLVER_ITERDATA (active on PC_BUILD): one line per iteration.
        if (comptime !is_dmcp_build) {
            var dbYr: f32 = undefined;
            var dbYi: f32 = undefined;
            const arrows = [8][*:0]const u8{ "→", "↗︎", "↑", "↖︎", "←", "↙︎", "↓", "↘︎" };
            realToFloat(&Y2N.Real, &dbYr);
            realToFloat(&Y2N.Imag, &dbYi);
            const angVal: f64 = 4.0 * (atan2(@as(f64, dbYi), @as(f64, dbYr))) / 3.14159265358979323846 + 8.5;
            // C casts to int (UB on NaN); guard the Debug trap, value only picks the arrow glyph.
            const angRaw: c_int = if (angVal != angVal) 0 else @intFromFloat(angVal);
            const ang: u8 = @intCast(@mod(angRaw, 8));
            const magn: f64 = sqrt(@as(f64, dbYr) * @as(f64, dbYr) + @as(f64, dbYi) * @as(f64, dbYi));
            _ = printf("#%-4u osc=%-2i conv=%-2i close=%i !best=%-2u Y=%s%5.0e ", @as(c_uint, @intCast(iterationCounter)), @as(c_int, oscillations), @as(c_int, convergent), @as(c_int, @intFromBool(Y2IsCloseToZero)), @as(c_uint, @intCast(@as(u16, @bitCast(iterAfterBest)))), arrows[ang % 8], magn);
            printComplexToConsole(&X2.Real, &X2.Imag, "X=", "\n");
        }

        //*************** DETERMINE DX and DY, to calculate the slope (or the inverse of the slope in this case) *******************
        copyComplex(&dX, &dXold); // store old DELTA values, for oscillation check
        copyComplex(&dY, &dYold); // store old DELTA values, for oscillation check

        // ---------- Modified 3 point Secant ------------
        if ((iterationCounter == 0) or (!Y2IsZero and !dXdYIsZero and !checkNaN)) {
            subComplex(&Y2.Real, &Y2.Imag, &Y1.Real, &Y1.Imag, &dY.Real, &dY.Imag, ctxtSolver2); // Y2-Y1 = dY
            subComplex(&X2.Real, &X2.Imag, &X1.Real, &X1.Imag, &dX.Real, &dX.Imag, ctxtSolver2); // X2-X1 = dX
            divFunctionComplex(&dY.Real, &dY.Imag, &dX.Real, &dX.Imag, &temp0.Real, &temp0.Imag); // dY/dX = temp0

            subComplex(&Y2.Real, &Y2.Imag, &Y0.Real, &Y0.Imag, &temp3.Real, &temp3.Imag, ctxtSolver2);

            mulComplexComplex(&temp0.Real, &temp0.Imag, &temp3.Real, &temp3.Imag, &temp3.Real, &temp3.Imag, ctxtSolver2);

            subComplex(&Y0.Real, &Y0.Imag, &Y1.Real, &Y1.Imag, &temp1.Real, &temp1.Imag, ctxtSolver2);
            subComplex(&X0.Real, &X0.Imag, &X1.Real, &X1.Imag, &temp2.Real, &temp2.Imag, ctxtSolver2);
            divFunctionComplex(&temp1.Real, &temp1.Imag, &temp2.Real, &temp2.Imag, &temp1.Real, &temp1.Imag);

            subComplex(&temp0.Real, &temp0.Imag, &temp1.Real, &temp1.Imag, &temp1.Real, &temp1.Imag, ctxtSolver2);
            mulComplexComplex(&temp1.Real, &temp1.Imag, &Y2.Real, &Y2.Imag, &temp1.Real, &temp1.Imag, ctxtSolver2);
            subComplex(&temp3.Real, &temp3.Imag, &temp1.Real, &temp1.Imag, &temp1.Real, &temp1.Imag, ctxtSolver2);

            subComplex(&Y2.Real, &Y2.Imag, &Y0.Real, &Y0.Imag, &X2N.Real, &X2N.Imag, ctxtSolver2);
            // get the 1/slope
            divFunctionComplex(&X2N.Real, &X2N.Imag, &temp1.Real, &temp1.Imag, &X2N.Real, &X2N.Imag);
            mulComplexComplex(&X2N.Real, &X2N.Imag, &Y1.Real, &Y1.Imag, &X2N.Real, &X2N.Imag, ctxtSolver2); // increment to x is: y1 . DX/DY
            // if converges slow without oscillating then accelerate.
            if (convergent > 10) {
                convertDoubleToReal(1.0 + @as(f64, @floatFromInt(convergent)) * 0.1, &f, ctxtSolver2); // factor ()
                mulComplexComplex(&X2N.Real, &X2N.Imag, &f, consts.c1708(), &X2N.Real, &X2N.Imag, ctxtSolver2); // increment to x is: y1 . DX/DY
            }

            subComplex(&X1.Real, &X1.Imag, &X2N.Real, &X2N.Imag, &X2N.Real, &X2N.Imag, ctxtSolver2); // subtract as per Newton, x1 - f/f' store temporarily to new x2n
        }

        //#############################################

        copyComplex(&Y1, &Y0); // old y1 copied to y0
        copyComplex(&X1, &X0); // old x1 copied to x0
        copyComplex(&Y2, &Y1); // old y2 copied to y1
        copyComplex(&X2, &X1); // old x2 copied to x1
        copyComplex(&X2N, &X2); // new x2

        iterationCounter += 1;
        oscillationIterationCounter += 1;

        if (checkHalfSec()) {
            if (progressHalfSecUpdate_Integer(timed, "Iter: ", iterationCounter, halfSec_clearZ, halfSec_clearT, halfSec_disp)) { // timed
                sumprod.showProgressReal(&X1.Real, &X1.Imag, !realIsZero(&X1.Imag));
            }
        }

        if (exitKeyWaiting()) {
            _ = showString("key Waiting ...", &standardFont, 20, 40, vmNormal, false, false);
            _ = progressHalfSecUpdate_Integer(force + 1, "Interrupted Iter:", iterationCounter, halfSec_clearZ, halfSec_clearT, halfSec_disp);
            calcMode = CM_NORMAL;
            screenUpdatingMode = SCRUPD_AUTO;
            screenUpdatingMode |= SCRUPD_SKIP_STATUSBAR_ONE_TIME;
            break;
        }

        // ENABLE_COMPLEXSOLVER_FILE_OUTPUT == 1 block: compile-time dead.
    } // Iteration end

    refreshScreen(200);

    checkNaN = checkNaN or
        realIsNaN(&X1.Real) or realIsNaN(&X1.Imag) or
        realIsNaN(&X2.Real) or realIsNaN(&X2.Imag);

    var conjugates: bool = false;
    // Test if zeroed complex parts is better
    copyComplex(&cpxSlvBestX, &temp0);
    if (checkRealZeroTol(&temp0.Real, &tolClose)) {
        realSetZero(&temp0.Real);
        _ = execute_rpn_function_reals(&temp0, &temp1, &magnitudeY);
    }
    copyComplex(&cpxSlvBestX, &temp0);
    if (checkRealZeroTol(&temp0.Imag, &tolClose)) {
        realSetZero(&temp0.Imag);
        _ = execute_rpn_function_reals(&temp0, &temp1, &magnitudeY);
    } else { // consider conjugates if X not close to Real
        realChangeSign(&temp0.Imag);
        _ = execute_rpn_function_reals(&temp0, &temp1, &magnitudeY);
        conjugates = checkRealZeroTol(&magnitudeY, &tolClose);
    }

    const FLAG_FRACTN: bool = getSystemFlag(FLAG_FRACT);
    clearSystemFlag(FLAG_FRACT_U);

    fnSetSignificantDigits(signDig);
    // reset stack and lift to reasonable height
    fnUndo(0);
    liftStack();
    setSystemFlag(FLAG_ASLIFT);
    liftStack();

    if (!Y2IsZero) {
        temporaryInformation = TI_SOLVER_FAILED;
        displayCalcErrorMessage(ERROR_NO_ROOT_FOUND, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
        convertDoubleToReal34Register(SOLVER_RESULT_OTHER_FAILURE, REGISTER_T);
    } else {
        temporaryInformation = TI_SOLVER_VARIABLE_RESULT;
        lastErrorCode = ERROR_NONE;
        convertDoubleToReal34Register(if (conjugates) SOLVER_RESULT_CONJUGATES else SOLVER_RESULT_NORMAL, REGISTER_T);
    }

    convertRealToResultRegister(&cpxSlvBestMagnitudeY, REGISTER_Z, amNone);
    convertComplexToResultRegister(&X1.Real, &X1.Imag, REGISTER_Y);
    convertComplexRegisterToRealIfZeroImag(REGISTER_Y);
    convertComplexToResultRegister(&cpxSlvBestX.Real, &cpxSlvBestX.Imag, REGISTER_X);
    convertComplexRegisterToRealIfZeroImag(REGISTER_X);
    copySourceRegisterToDestRegister(REGISTER_X, graphVariabl1);

    printSolverResult(iterationCounter);

    if (FLAG_FRACTN) {
        setSystemFlag(FLAG_FRACT_U);
    }

    calcMode = CM_NORMAL;
    SAVED_SIGMA_lastAddRem = SIGMA_NONE; // prevent undo of last stats add action. REMOVE when STATS are not used anymore
    return;
}

// ===========================================================================
// fnComplexSolver
// ===========================================================================
pub export fn fnComplexSolver() callconv(.c) void {
    printStatus(1, @ptrCast(&errorMessages[COMPLEX_SOLVER]), force);
    saveForUndo();
    // VERBOSE_SOLVER00/0 pre-conditioning block: never defined.
    // initialize_function();
    complexSolver();
}

// ===========================================================================
// fnEqSolvGraph
// ===========================================================================
pub export fn fnEqSolvGraph(func: u16) callconv(.c) void {
    hourGlassIconEnabled = true;
    showHideHourGlass();
    lcdRefresh();

    var x: real_t = undefined;
    var y: real_t = undefined;

    switch (func) {
        EQ_CPXSOLVE_LU, EQ_REALSOLVE_LU => {
            if (getRegisterAsReal(RESERVED_VARIABLE_LEST, &y) and getRegisterAsReal(RESERVED_VARIABLE_UEST, &x)) {
                liftStack();
                setSystemFlag(FLAG_ASLIFT);
                reallocateRegister(REGISTER_X, dtReal34, 0, amNoneU);
                liftStack();
                reallocateRegister(REGISTER_X, dtReal34, 0, amNoneU);
                realToReal34(&x, reg34(REGISTER_X));
                realToReal34(&y, reg34(REGISTER_Y));
                solverEstimatesUsed = true;
            }
        },
        EQ_CPXSOLVE, EQ_REALSOLVE => {
            if (getRegisterAsReal(REGISTER_X, &x) and getRegisterAsReal(REGISTER_Y, &y)) {
                reallocateRegister(RESERVED_VARIABLE_UEST, dtReal34, 0, amNoneU);
                reallocateRegister(RESERVED_VARIABLE_LEST, dtReal34, 0, amNoneU);
                realToReal34(&x, reg34(RESERVED_VARIABLE_UEST));
                realToReal34(&y, reg34(RESERVED_VARIABLE_LEST));
                solverEstimatesUsed = false;
            }
        },
        EQ_PLOT_LU => { // uses limits
            if (getRegisterAsReal(RESERVED_VARIABLE_LX, &y) and getRegisterAsReal(RESERVED_VARIABLE_UX, &x)) {
                liftStack();
                setSystemFlag(FLAG_ASLIFT);
                reallocateRegister(REGISTER_X, dtReal34, 0, amNoneU);
                liftStack();
                reallocateRegister(REGISTER_X, dtReal34, 0, amNoneU);
                realToReal34(&x, reg34(REGISTER_X));
                realToReal34(&y, reg34(REGISTER_Y));
            }
        },
        EQ_PLOT => { // uses X, Y
            if (getRegisterAsReal(REGISTER_X, &x) and getRegisterAsReal(REGISTER_Y, &y)) {
                reallocateRegister(RESERVED_VARIABLE_UX, dtReal34, 0, amNoneU);
                reallocateRegister(RESERVED_VARIABLE_LX, dtReal34, 0, amNoneU);
                realToReal34(&x, reg34(RESERVED_VARIABLE_UX));
                realToReal34(&y, reg34(RESERVED_VARIABLE_LX));
            }
        },
        else => {
            return;
        },
    }

    if (!(currentSolverVariable >= FIRST_NAMED_VARIABLE and currentSolverVariable <= LAST_NAMED_VARIABLE)) {
        // No plot variable assigned (e.g. a programmed Draw after X.SWAP loaded a
        // fresh formula): auto-assign the sole variable like the interactive MVAR
        // menu does; a formula with several variables still errors below.
        equation.parseEquation(currentFormula, EQUATION_PARSER_MVAR, aimBuffer, tmpString);
        if (tmpString[0] != 0 and getNthString(tmpString, 1)[0] == 0) {
            currentSolverVariable = @bitCast(findOrAllocateNamedVariable(tmpString));
        }
    }

    graphVariabl1 = @bitCast(currentSolverVariable);
    if (graphVariabl1 < 0) {
        graphVariabl1 = -graphVariabl1;
    }

    if (graphVariabl1 >= FIRST_NAMED_VARIABLE and graphVariabl1 <= LAST_NAMED_VARIABLE) {
        // VERBOSE diagnostic only.
    } else {
        displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function fnEqSolvGraph:", "unexpected parameter", null, null);
        return;
    }

    // initialize x
    currentSolverStatus &= ~SOLVER_STATUS_READY_TO_EXECUTE;

    switch (func) {
        EQ_REALSOLVE_LU, EQ_REALSOLVE => {
            if (currentSolverVariable >= FIRST_NAMED_VARIABLE) {
                solve_owned.fnSolve(currentSolverVariable);
            }
        },

        EQ_CPXSOLVE_LU, EQ_CPXSOLVE => {
            fnComplexSolver();
        },

        EQ_PLOT_LU, EQ_PLOT => {
            //      PLOT_ZMY = 0; removed default zeroing of the zoom factor in eqn
            var loX: real_t = undefined;
            var hiX: real_t = undefined;
            const rangeOK = getRegisterAsReal(REGISTER_X, &hiX) and getRegisterAsReal(REGISTER_Y, &loX);

            // fnClDrawMx deletes DrwMX, and deleting a named variable shifts every
            // higher-indexed slot down by one -- so a plot variable allocated above
            // DrwMX (e.g. a programmed `PLTf 'x'`) has its cached register go stale.
            // Snapshot the plot variable's name first, then re-resolve it by name
            // after the delete so the sampler stores into the right register.
            var plotVarName: [16]u8 = undefined;
            plotVarName[0] = 0; // empty-name sentinel; filled below when a plot variable is set
            const named_end: u16 = @as(u16, @intCast(FIRST_NAMED_VARIABLE)) + numberOfNamedVariables;
            if (currentSolverVariable >= FIRST_NAMED_VARIABLE and currentSolverVariable < named_end) {
                if (allNamedVariables) |vars| {
                    const stored = &vars[@intCast(currentSolverVariable - FIRST_NAMED_VARIABLE)].variableName;
                    const len = @min(stored[0], plotVarName.len - 1);
                    @memcpy(plotVarName[0..len], stored[1 .. 1 + len]);
                    plotVarName[len] = 0;
                }
            }

            fnClDrawMx(5);
            _ = strcpy(&plotStatMx, "DrwMX");

            if (plotVarName[0] != 0) {
                const reResolved = findNamedVariable(&plotVarName);
                if (reResolved != INVALID_VARIABLE) {
                    currentSolverVariable = @bitCast(reResolved);
                    graphVariabl1 = reResolved;
                }
            }

            if (rangeOK and realCompareGreaterThan(&hiX, &loX)) { // pre-condition the plotter: x_min = Y, x_max = X
                realCopy(&loX, x_min);
                realCopy(&hiX, x_max);
            }
            graphRangeGuard(x_min, x_max); // swap reversed limits; widen spans too small to plot at working precision

            initialize_function();
            graph_eqn(noInitDrwMx);

            if (!getSystemFlag(FLAG_PCROS) and !getSystemFlag(FLAG_PBOX) and !getSystemFlag(FLAG_PPLUS)) {
                setSystemFlag(FLAG_PLINE_U);
            }

            reDraw = true;
            screenUpdatingMode = SCRUPD_AUTO;
            screenUpdatingMode |= SCRUPD_SKIP_STATUSBAR_ONE_TIME;
            refreshScreen(239);
            if (programRunStop == PGM_RUNNING or programRunStop == PGM_PAUSED) {
                // The refresh above dropped a running program back to CM_NORMAL, so
                // a following programmed SNAP would capture the register display
                // instead of the plot. Re-arm the graph so the SNAP re-renders it.
                calcMode = CM_GRAPH;
                reDraw = true;
            }
        },
        else => {},
    }
}

// ===========================================================================
// fnPlotf
// ===========================================================================
pub export fn fnPlotf(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    fnEqSolvGraph(EQ_PLOT); // picks up X1 X2 from the stack
    if (lastErrorCode == ERROR_NONE) {
        // On a rejected range CM_NORMAL is already set; skip fnPlotSQ so it does
        // not force CM_GRAPH back and hide the error.
        fnPlotSQ(0);
    }
}
