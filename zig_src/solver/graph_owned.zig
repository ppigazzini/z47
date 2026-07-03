// SPDX-License-Identifier: GPL-3.0-only
const consts = abi.constants;
//
// Zig owner for src/c47/solver/graph.c: the function-plot engine and the
// complex solver. graph_eqn walks the x-range with adaptive step size
// (high-res tracking, jump-back fine stepping, discontinuity / vertical
// asymptote detection) and accumulates points in the DrwMX matrix;
// complexSolver is the modified-3-point-secant complex root finder behind
// cpxSlv; fnEqSolvGraph dispatches Draw / realSlv / cpxSlv from the equation
// app. The shim (graph_legacy.c, removed) had NO renames, so every
// non-static C symbol keeps its real name: drawMxN, fnClDrawMx, the
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
const abi = @import("abi"); // L1 shared bindings (REPORT-23 §5)
const real_t = abi.Real;
const real34_t = abi.Real34;
const realContext_t = abi.RealContext;
const calcRegister_t = i16;
const matrixHeader_t = packed struct(u32) {
    matrixRows: u12,
    matrixColumns: u12,
    mtag: u6,
    notUsed: u2,
};
const real34Matrix_t = extern struct { header: matrixHeader_t, matrixElements: ?[*]real34_t };
const font_t = opaque {};

const cplx_t = abi.Complex;

const PlotPoint = extern struct {
    x: f64,
    y: f64,
    grad: f64,
    stored: bool,
};

const AsymptoteInfo = extern struct {
    x: f64, // x-coordinate of asymptote
    gapWidth: f64, // width of the discontinuity gap
    hasPositive: bool, // approaches +infinity
    hasNegative: bool, // approaches -infinity
    maxHeight: f64, // standard maximum height for rendering
};

const PointOffset = extern struct {
    dx: f64,
    dy: f64,
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

const SCRUPD_AUTO: u8 = 0x00;
const SCRUPD_SKIP_STATUSBAR_ONE_TIME: u8 = 0x10;

const TI_SOLVER_FAILED: u8 = 52;
const TI_SOLVER_VARIABLE_RESULT: u8 = 110;

const PLOT_NOTHING: u16 = 5;
const NOPARAM: u16 = 9876;

const SCREEN_WIDTH_GRAPH: f64 = 400; // SCREEN_WIDTH

const FLAG_CPXPLOT: c_int = 0x804B;
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
const SOLVER_RESULT_NORMAL: f64 = 0;
const SOLVER_RESULT_OTHER_FAILURE: f64 = 5;
const SOLVER_RESULT_CONJUGATES: f64 = 200;

const COMPLEX_SOLVER: usize = 103;
const NUMBER_OF_ERROR_CODES = 129; // defines.h: 129 (errorMessages row count)
const SIZE_OF_EACH_ERROR_MESSAGE = 48;

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
    .{ .dx = -1.0, .dy = -1.0 }, // (x - offset, -height)
    .{ .dx = -1.0, .dy = 1.0 }, // (x - offset, +height)
    .{ .dx = 1.0, .dy = 1.0 }, // (x + offset, +height)
};
pub export const asymptote_offsets_positive linksection(runtime.code_section) = [3]PointOffset{
    .{ .dx = -1.0, .dy = 0.0 }, // (x - offset, 0)
    .{ .dx = -1.0, .dy = 1.0 }, // (x - offset, +height)
    .{ .dx = 1.0, .dy = 1.0 }, // (x + offset, +height)
};
pub export const asymptote_offsets_negative linksection(runtime.code_section) = [3]PointOffset{
    .{ .dx = -1.0, .dy = 0.0 }, // (x - offset, 0)
    .{ .dx = -1.0, .dy = -1.0 }, // (x - offset, -height)
    .{ .dx = 1.0, .dy = -1.0 }, // (x + offset, -height)
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
extern var x_min: f32;
extern var x_max: f32;
extern var y_min: f32;
extern var y_max: f32;
extern var SAVED_SIGMA_lastAddRem: i8;
extern var tmpString: [*c]u8;
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
extern fn parseEquation(equationId: u16, parseMode: u16, buffer: [*c]u8, mvarBuffer: [*c]u8) void;
extern fn adjustResult(res: calcRegister_t, dropY: bool, setCpxRes: bool, errorReg: calcRegister_t, op1: calcRegister_t, op2: calcRegister_t) void;
extern fn findNamedVariable(variableName: [*c]const u8) calcRegister_t;
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
extern fn fnSolve(labelOrVariable: u16) void;
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
extern fn refreshStatusBar() void;
extern fn clearScreenOld(clearStatusBar: bool, clearRegisterLines: bool, clearSoftkeys: bool) void;
extern fn showString(str: [*c]const u8, font: *const font_t, x: u32, y: u32, video_mode: c_int, show_leading_cols: bool, show_ending_cols: bool) u32;
extern fn printStatus(row: u8, line1: [*c]const u8, forced: u8) void;
extern fn checkHalfSec() bool;
extern fn progressHalfSecUpdate_Integer(mode: u8, txt: [*c]const u8, loop: i32, clearZ: bool, clearT: bool, disp: bool) bool;
extern fn showProgressReal(a: *const real_t, ai: *real_t, cpx: bool) void;
extern fn exitKeyWaiting() bool;
extern fn refreshLcd(unused: ?*anyopaque) void;

// decNumber / decQuad externs behind the real* / real34* macros.
extern fn decNumberCopy(r: *real_t, src: *align(1) const real_t) *real_t;
extern fn decNumberAdd(r: *real_t, a: *align(1) const real_t, b: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberMultiply(r: *real_t, a: *align(1) const real_t, b: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberFromString(r: *real_t, s: [*c]const u8, ctx: *realContext_t) *real_t;
extern fn decNumberToString(r: *const real_t, s: [*c]u8) [*c]u8;
extern fn decimal128ToNumber(src: *align(1) const real34_t, dst: *real_t) *real_t;
extern fn decimal128FromNumber(dst: *align(1) real34_t, src: *const real_t, ctx: *realContext_t) *align(1) real34_t;
extern fn decQuadIsInfinite(v: *align(1) const real34_t) u32;
extern fn decQuadIsNaN(v: *align(1) const real34_t) u32;
extern fn decQuadIsSignaling(v: *align(1) const real34_t) u32;
extern fn decQuadIsZero(v: *align(1) const real34_t) u32;
extern fn decQuadToString(v: *align(1) const real34_t, s: [*c]u8) [*c]u8;
extern fn decQuadToInt32(v: *align(1) const real34_t, ctx: *realContext_t, round: c_int) i32;
extern fn realToFloat(vv: *const real_t, v: *f32) void;

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

inline fn reg34(reg: calcRegister_t) *align(1) real34_t {
    return @ptrCast(getRegisterDataPointer(reg));
}
inline fn regImag34(reg: calcRegister_t) *align(1) real34_t {
    const bytes: [*]u8 = @ptrCast(getRegisterDataPointer(reg));
    return @ptrCast(bytes + 16);
}
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
inline fn realToReal34(src: *const real_t, dst: *align(1) real34_t) void {
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
inline fn realIsZero(v: *const real_t) bool {
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

        parseEquation(currentFormula, EQUATION_PARSER_XEQ, tmpString, tmpString + AIM_BUFFER_LENGTH);
        adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);

        if (comptime !is_dmcp_build) {
            if (lastErrorCode != 0) {
                lastErrorCode = 0;
            }
        }
        fnRCL(regStats);

        // ENABLE_COMPLEXSOLVER_FILE_OUTPUT == 2 block: compile-time dead.
    } else {
        if (comptime !is_dmcp_build) {
            lastErrorCode = 0;
        }
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
// High-res / discontinuity helpers
// ===========================================================================
pub export fn validateDiscontinuityResolution(buffer: [*c]PlotPoint, count: c_int, yBefore: f64, yAfter: f64, discontinuityThreshold: f64) callconv(.c) bool {
    if (count < 3) {
        return false;
    }

    // Check if the fine-stepped points show smooth transition
    var maxJump: f64 = 0;
    var totalVariation: f64 = 0;

    // Check continuity between consecutive fine points
    var i: c_int = 1;
    while (i < count) : (i += 1) {
        const jump: f64 = fabs(buffer[@intCast(i)].y - buffer[@intCast(i - 1)].y);
        totalVariation += jump;
        if (jump > maxJump) {
            maxJump = jump;
        }
    }

    // Also check connection to endpoints
    const startJump: f64 = fabs(buffer[0].y - yBefore);
    const endJump: f64 = fabs(yAfter - buffer[@intCast(count - 1)].y);

    if (startJump > maxJump) {
        maxJump = startJump;
    }
    if (endJump > maxJump) {
        maxJump = endJump;
    }

    // If the maximum jump in fine steps is still above threshold, discontinuity persists
    const discontinuityResolved: bool = (maxJump < discontinuityThreshold);

    // Additional check: fine points should show reasonable continuity
    const avgVariation: f64 = totalVariation / @as(f64, @floatFromInt(count - 1));
    const smoothTransition: bool = (maxJump < 3.0 * avgVariation) or (maxJump < discontinuityThreshold * 0.5);

    return discontinuityResolved and smoothTransition;
}

pub export fn calculateNewStepSize(discontinuityDetected: c_int, grad1: f64, grad2: f64, grad2IncreaseDetected: bool, dx0: f64) callconv(.c) f64 {
    if (discontinuityDetected > 0 and discontinuityDetected <= FINE) {
        const newDx: f64 = dJMP * dx0;
        return newDx;
    } else if (grad2 == 0 or grad1 == 0) {
        return dx0;
    } else if (grad2IncreaseDetected) {
        const ratio1: f64 = grad2 / grad1;
        const ratio2: f64 = grad1 / grad2;
        const newDx: f64 = dx0 * (if (ratio1 > SS1 or ratio2 > SS1) @as(f64, 0.5) else @as(f64, 1.0));
        return newDx;
    } else {
        return dx0;
    }
}

pub export fn enterHighResMode(inHighResMode: *bool, highResCount: *c_int, highResStartX: *f64, baselineCurvatureChange: *f64, cumulativeCurvatureChange: *f64, x: f64, curvatureChange: f64) callconv(.c) void {
    inHighResMode.* = true;
    highResCount.* = 0;
    highResStartX.* = x;
    baselineCurvatureChange.* = curvatureChange;
    cumulativeCurvatureChange.* = 0;
}

pub export fn commitHighResPointsInOrder(buffer: [*c]PlotPoint, count: c_int) callconv(.c) void {
    var i: c_int = 0;
    while (i < count) : (i += 1) {
        if (!buffer[@intCast(i)].stored) {
            convertDoubleToReal34RegisterPush(buffer[@intCast(i)].x, REGISTER_X);
            execute_rpn_function();
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

pub export fn resetHighResTracking(highResCount: *c_int, inHighResMode: *bool, cumulativeCurvatureChange: *f64) callconv(.c) void {
    highResCount.* = 0;
    inHighResMode.* = false;
    cumulativeCurvatureChange.* = 0;
}

pub export fn detectTrueDiscontinuity(y0: f64, y1: f64, y2: f64, grad0: f64, grad1: f64, grad2: f64, yAvg: f64, count: c_int) callconv(.c) bool {
    // Distinguish between genuine discontinuities and normal peaks
    if (real34IsSpecial(reg34(REGISTER_X)) or ((getRegisterDataType(REGISTER_X) == dtComplex34) and (real34IsSpecial(regImag34(REGISTER_X))))) {
        return true;
    }
    if (count < 4) {
        return false;
    }

    const extremeMagnitudeJump: bool = (fabs(y2) > 100 * yAvg) and (fabs(y1) < 10 * yAvg);
    var gradientDiscontinuity: bool = false;
    if (grad0 != 0 and grad1 != 0 and grad2 != 0) {
        // Calculate expected gradient based on trend
        const expectedGrad: f64 = grad1 + (grad1 - grad0); // Linear extrapolation
        const gradientRatio: f64 = fabs(grad2) / (fabs(expectedGrad) + 1e-10);

        // Only flag if gradient changes by more than 50x AND the function values suggest discontinuity
        gradientDiscontinuity = (gradientRatio > 50) and (fabs(y2 - y1) > 20 * fabs(y1 - y0)) and (fabs(y2 - y1) > 5 * yAvg);
    }

    // Check for sign oscillation that indicates numerical instability not smooth peaks
    var signOscillationInstability: bool = false;
    if (count >= 6) {
        // Look for rapid alternating signs with increasing magnitude - indicates instability
        const y0Pos: bool = (y0 > 0);
        const y1Pos: bool = (y1 > 0);
        const y2Pos: bool = (y2 > 0);
        if (y0Pos != y1Pos and y1Pos != y2Pos) {
            // Alternating signs - check if magnitudes are increasing dramatically
            const mag0: f64 = fabs(y0);
            const mag1: f64 = fabs(y1);
            const mag2: f64 = fabs(y2);
            signOscillationInstability = (mag2 > 5 * mag1) and (mag1 > 5 * mag0) and (mag2 > 10 * yAvg);
        }
    }

    return extremeMagnitudeJump or gradientDiscontinuity or signOscillationInstability;
}

// ===========================================================================
// Asymptote detection and rendering
// ===========================================================================
pub export fn detectAndCharacterizeAsymptote(xLeft: f64, yLeft: f64, xRight: f64, yRight: f64, xGap: f64, gapWidth: f64, asymptote: *AsymptoteInfo) callconv(.c) bool {
    // Check if gap is significant enough
    const xRange: f64 = @as(f64, x_max) - x_min;
    if (gapWidth < MIN_GAP_WIDTH_RATIO * xRange) {
        return false;
    }

    // Sample only 2 points on each side to minimize memory usage
    var leftMaxY: f64 = yLeft;
    var rightMaxY: f64 = yRight;
    var leftMinY: f64 = yLeft;
    var rightMinY: f64 = yRight;

    // Sample just 2 points on each side (minimal sampling)
    var i: c_int = 1;
    while (i <= 2) : (i += 1) {
        // Left side samples (approaching asymptote from left)
        var sampleX: f64 = xLeft + (xGap - xLeft) * (0.7 + 0.2 * @as(f64, @floatFromInt(i)) / 2);
        convertDoubleToReal34RegisterPush(sampleX, REGISTER_X);
        execute_rpn_function();

        // Skip if we get invalid results
        if (real34IsInfinite(reg34(REGISTER_Y)) or real34IsNaN(reg34(REGISTER_Y))) {
            continue;
        }

        var sampleY: f64 = convertRegisterToDouble(REGISTER_Y);
        if (sampleY > leftMaxY) {
            leftMaxY = sampleY;
        }
        if (sampleY < leftMinY) {
            leftMinY = sampleY;
        }

        // Right side samples (approaching asymptote from right)
        sampleX = xGap + (xRight - xGap) * (0.2 * @as(f64, @floatFromInt(i)) / 2);
        convertDoubleToReal34RegisterPush(sampleX, REGISTER_X);
        execute_rpn_function();

        if (real34IsInfinite(reg34(REGISTER_Y)) or real34IsNaN(reg34(REGISTER_Y))) {
            continue;
        }

        sampleY = convertRegisterToDouble(REGISTER_Y);
        if (sampleY > rightMaxY) {
            rightMaxY = sampleY;
        }
        if (sampleY < rightMinY) {
            rightMinY = sampleY;
        }
    }

    // Determine if we have a vertical asymptote based on extreme values
    const yRange: f64 = @as(f64, y_max) - y_min;
    const extremeThreshold: f64 = yRange * 2.0; // Values beyond 2x the plot range

    const leftGoesPositive: bool = (leftMaxY > y_max + extremeThreshold);
    const leftGoesNegative: bool = (leftMinY < y_min - extremeThreshold);
    const rightGoesPositive: bool = (rightMaxY > y_max + extremeThreshold);
    const rightGoesNegative: bool = (rightMinY < y_min - extremeThreshold);

    // Must have extreme behavior on at least one side
    if (!(leftGoesPositive or leftGoesNegative or rightGoesPositive or rightGoesNegative)) {
        return false;
    }

    // Fill asymptote info
    asymptote.x = xGap;
    asymptote.gapWidth = gapWidth;
    asymptote.hasPositive = leftGoesPositive or rightGoesPositive;
    asymptote.hasNegative = leftGoesNegative or rightGoesNegative;
    asymptote.maxHeight = yRange * ASYMPTOTE_HEIGHT_RATIO;

    return true;
}

pub export fn renderAsymptote(asymptote: *AsymptoteInfo) callconv(.c) void {
    const x_center: f64 = asymptote.x;
    const offset: f64 = 1e-3; // Small x offset
    const asymptoteHeight: f64 = 10000.0;

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
            const x: f64 = x_center + offs[i].dx * offset;
            const y: f64 = offs[i].dy * (if (offs[i].dy == 0.0) @as(f64, 0.0) else asymptoteHeight);
            convertDoubleToReal34Register(x, REGISTER_X);
            convertDoubleToReal34Register(y, REGISTER_Y);
            AddtoDrawMx();
        }
    }
}

pub export fn detectTrueDiscontinuityWithAsymptote(y0: f64, y1: f64, y2: f64, grad0: f64, grad1: f64, grad2: f64, yAvg: f64, count: c_int, x0: f64, x1: f64, x2: f64, asymptotes: [*c]AsymptoteInfo, asymptoteCount: *c_int) callconv(.c) bool {
    _ = x1;
    // If not a vertical asymptote, do discontinuity detection
    const hasDiscontinuity: bool = detectTrueDiscontinuity(y0, y1, y2, grad0, grad1, grad2, yAvg, count);

    if (hasDiscontinuity and count >= 4 and asymptoteCount.* < MAX_ASYMPTOTES) {
        // Check if this discontinuity might be an asymptote using the detailed method
        const gapWidth: f64 = fabs(x2 - x0);
        const xGap: f64 = (x0 + x2) / 2.0;

        var candidateAsymptote: AsymptoteInfo = undefined;

        if (detectAndCharacterizeAsymptote(x0, y0, x2, y2, xGap, gapWidth, &candidateAsymptote)) {
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
    currentKeyCode = 255;
    calcMode = CM_GRAPH;
    saveForUndo();
    regStatsXY = findNamedVariable(&plotStatMx);
    var x: f64 = undefined;
    var x01: f64 = x_min;
    var y01: f64 = 0;
    var y02: f64 = 0;
    var y00: f64 = 0; // Add y00 for improved discontinuity detection
    var dy: f64 = undefined;
    const dx0: f64 = (@as(f64, x_max) - x_min) / SCREEN_WIDTH_GRAPH * 10;
    var dx: f64 = dx0;
    var grad2: f64 = 1;
    var grad1: f64 = 1;
    var grad0: f64 = 1;
    var prevDx: f64 = dx0; // Track previous step size
    var count: i16 = 0;
    var ss0: i16 = 0;
    var ss1: i16 = 0;
    var ss2: i16 = 0;
    var discontinuityDetected: u8 = 0;
    var grad2IncreaseDetected: bool = false;
    var yAvg: f64 = 0.1;
    var loop: c_int = 0;
    var jumpedBack: bool = false;
    var asymptotes: [MAX_ASYMPTOTES]AsymptoteInfo = undefined;
    var asymptoteCount: c_int = 0;

    if (graphVariabl1 < FIRST_NAMED_VARIABLE or graphVariabl1 > LAST_NAMED_VARIABLE) {
        regStatsXY = INVALID_VARIABLE;
        return;
    }

    // LOW_GRAPH_ACC is defined: change to SDIGS digit operation for graphs.
    if (significantDigitsForEqnGraphs() <= 6) {
        ctxtReal34.digits = significantDigitsForEqnGraphs();
        ctxtReal39.digits = significantDigitsForEqnGraphs() + 3;
        ctxtReal51.digits = significantDigitsForEqnGraphs() + 6;
        ctxtReal75.digits = significantDigitsForEqnGraphs() + 9;
    }

    fillStackWithReal0();

    convertDoubleToReal34RegisterPush(x_max, REGISTER_X);
    execute_rpn_function();
    yAvg += 2 * fabs(convertRegisterToDouble(REGISTER_Y));

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
    var highResStartX: f64 = 0;
    var cumulativeCurvatureChange: f64 = 0;
    var baselineCurvatureChange: f64 = 0;
    var savedXBeforeHighres: f64 = 0;
    var savedDxBeforeHighres: f64 = dx0;

    x = x_min;
    while (x <= x_max) : (x += STEP_OFFSET * dx) {
        jumpedBack = false;
        x = fmax(x_min, fmin(x_max, x));

        convertDoubleToReal34RegisterPush(x, REGISTER_X);
        execute_rpn_function();

        // Handle complex plotting
        if (getSystemFlag(FLAG_CPXPLOT)) {
            fnRCL(REGISTER_Y);
            fnStore(@bitCast(TEMP_REGISTER_1));
            fnImaginaryPart(0);
            fnRCL(TEMP_REGISTER_1);
            fnRealPart(0);
            AddtoDrawMx();
            continue;
        }

        y02 = convertRegisterToDouble(REGISTER_Y);

        // Calculate gradient and detect anomalies
        if (count > 0) {
            dy = y02 - y01;
            grad2 = if (x != x01) dy / (x - x01) else 0.0;

            // Update sign states
            ss0 = ss1;
            ss1 = ss2;
            ss2 = if (grad2 == 0) 0 else if (grad2 > 0) 1 else -1;
            grad0 = grad1;
            grad1 = grad2;

            // Detect gradient anomalies using improved logic
            if (grad1 != 0 and grad2 != 0) {
                const yRatioCheck1: bool = (fabs(y02 / y01) > 1.01 and fabs(grad2 / grad1) > SS2);
                const yRatioCheck2: bool = (fabs(y01 / y02) > 1.01 and fabs(grad1 / grad2) > SS2);

                // Conservative oscillation detection - only flag if it's truly problematic
                const signOscillation1: bool = (ss0 == 1 and ss1 == -1 and ss2 == 1) and (fabs(y02) > 2 * fabs(y01)) and (fabs(y00) > 2 * fabs(y01));
                const signOscillation2: bool = (ss0 == -1 and ss1 == 1 and ss2 == -1) and (fabs(y02) > 2 * fabs(y01)) and (fabs(y00) > 2 * fabs(y01));

                // Zero crossing detection - only if accompanied by large gradient changes
                const zeroCrossing1: bool = (ss1 == 1 and ss2 == -1 and y01 > 0 and y02 < 0) and (fabs(grad2 - grad1) > 10 * fabs(grad1 - grad0));
                const zeroCrossing2: bool = (ss1 == -1 and ss2 == 1 and y01 < 0 and y02 > 0) and (fabs(grad2 - grad1) > 10 * fabs(grad1 - grad0));

                grad2IncreaseDetected = yRatioCheck1 or yRatioCheck2 or signOscillation1 or signOscillation2 or zeroCrossing1 or zeroCrossing2;
            } else {
                grad2IncreaseDetected = false;
            }

            // Update running average
            if (count == 0) {
                yAvg += 2 * fabs(y02);
            } else if (fabs(y02) > yAvg) {
                yAvg += fabs(y02) / @as(f64, @floatFromInt(count));
            }

            // Use improved discontinuity detection
            if (discontinuityDetected == 0) {
                const x00: f64 = if (count > 1) x01 - dx else x_min;
                const trueDiscontinuity: bool = detectTrueDiscontinuityWithAsymptote(y00, y01, y02, grad0, grad1, grad2, yAvg, count, x00, x01, x, &asymptotes, &asymptoteCount);
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
                const jumpBackStartX: f64 = x;
                const jumpBackStartY: f64 = y02;
                const wasDiscontinuity: bool = (discontinuityDetected == FINE);
                const discontinuityThreshold: f64 = if (wasDiscontinuity) fabs(y02 - y01) * 0.1 else 0; // 10% of original jump

                x -= dx * JMP;
                jumpedBack = true;
                convertDoubleToReal34RegisterPush(x, REGISTER_X);
                execute_rpn_function();
                y02 = convertRegisterToDouble(REGISTER_Y);
                grad2 = (y02 - y01) / (x - x01);
                ss0 = ss1;
                ss1 = ss2;
                ss2 = if (grad2 == 0) 0 else if (grad2 > 0) 1 else -1;

                // Sample the fine-stepped points
                var jumpBackBuffer: [@intCast(FINE)]PlotPoint = undefined;
                var jumpBackCount: c_int = 0;
                var jumpBackX: f64 = x;
                const jumpBackDx: f64 = dJMP * dx0;

                var jbStep: c_int = 0;
                while (jbStep < FINE and jumpBackX < jumpBackStartX) : (jbStep += 1) {
                    convertDoubleToReal34RegisterPush(jumpBackX, REGISTER_X);
                    execute_rpn_function();
                    const jbY: f64 = convertRegisterToDouble(REGISTER_Y);

                    jumpBackBuffer[@intCast(jumpBackCount)].x = jumpBackX;
                    jumpBackBuffer[@intCast(jumpBackCount)].y = jbY;
                    jumpBackBuffer[@intCast(jumpBackCount)].stored = false;
                    jumpBackCount += 1;
                    jumpBackX += jumpBackDx;
                }

                var shouldCommitPoints: bool = false;

                if (wasDiscontinuity) {
                    // For discontinuity cases, validate that fine points actually resolve the discontinuity
                    const discontinuityResolved: bool = validateDiscontinuityResolution(&jumpBackBuffer, jumpBackCount, y01, jumpBackStartY, discontinuityThreshold);

                    if (discontinuityResolved) {
                        shouldCommitPoints = true;
                        discontinuityDetected = 0; // Clear discontinuity flag
                    } else {
                        discontinuityDetected = 0; // Clear flag
                        shouldCommitPoints = false;
                        // Don't skip the original grid point - restore to original position and let the
                        // normal flow handle plotting the original grid point
                    }
                } else {
                    // For gradient increase cases, evaluate if points add significant detail
                    if (jumpBackCount >= 3) {
                        // Calculate curvature variation in the jump-back region
                        var maxCurvatureChange: f64 = 0;
                        var i: c_int = 1;
                        while (i < jumpBackCount - 1) : (i += 1) {
                            const g1: f64 = (jumpBackBuffer[@intCast(i)].y - jumpBackBuffer[@intCast(i - 1)].y) / (jumpBackBuffer[@intCast(i)].x - jumpBackBuffer[@intCast(i - 1)].x);
                            const g2: f64 = (jumpBackBuffer[@intCast(i + 1)].y - jumpBackBuffer[@intCast(i)].y) / (jumpBackBuffer[@intCast(i + 1)].x - jumpBackBuffer[@intCast(i)].x);
                            const curvChange: f64 = fabs(g2 - g1);
                            if (curvChange > maxCurvatureChange) {
                                maxCurvatureChange = curvChange;
                            }
                        }
                        // Compare with linear interpolation
                        const linearSlope: f64 = (jumpBackStartY - y01) / (jumpBackStartX - x01);
                        var interpolationError: f64 = 0;
                        var j: c_int = 0;
                        while (j < jumpBackCount) : (j += 1) {
                            const expectedY: f64 = y01 + linearSlope * (jumpBackBuffer[@intCast(j)].x - x01);
                            const err: f64 = fabs(jumpBackBuffer[@intCast(j)].y - expectedY);
                            if (err > interpolationError) {
                                interpolationError = err;
                            }
                        }
                        // Points are useful if they show significant non-linear behavior
                        const jumpBackPointsUseful: bool = (interpolationError > 0.1 * fabs(jumpBackStartY - y01)) or (maxCurvatureChange > fabs(linearSlope) * 0.5);

                        shouldCommitPoints = jumpBackPointsUseful;
                    }
                }

                if (shouldCommitPoints) { // fine points
                    var i: c_int = 0;
                    while (i < jumpBackCount) : (i += 1) {
                        convertDoubleToReal34RegisterPush(jumpBackBuffer[@intCast(i)].x, REGISTER_X);
                        execute_rpn_function();
                        AddtoDrawMx();
                    }

                    // Also plot the original grid point (jumpBackStartX, jumpBackStartY)
                    convertDoubleToReal34RegisterPush(jumpBackStartX, REGISTER_X);
                    execute_rpn_function();
                    AddtoDrawMx();

                    // Set position to continue from the original grid point
                    x = jumpBackStartX;
                    y02 = jumpBackStartY;
                    dx = dx0; // Reset to original step size
                    jumpedBack = false; // Clear flag since we've handled the plotting
                } else { // not fine points
                    // Restore to the original grid point and continue normal processing, ensures
                    // original grid point gets plotted in the normal flow
                    x = jumpBackStartX;
                    y02 = jumpBackStartY;
                    dx = dx0; // Revert to original step size
                    jumpedBack = false; // Clear flag so the original point gets plotted normally

                    // Recalculate gradient for the original point
                    grad2 = (y02 - y01) / (x - x01);
                    ss0 = ss1;
                    ss1 = ss2;
                    ss2 = if (grad2 == 0) 0 else if (grad2 > 0) 1 else -1;
                }
            }

            // Calculate curvature change for resolution assessment
            var curvatureChange: f64 = 0;
            if (count > 1 and grad0 != 0 and grad1 != 0) {
                curvatureChange = fabs((grad2 - grad1) - (grad1 - grad0));
            }

            // Determine new step size and resolution mode
            const newDx: f64 = calculateNewStepSize(discontinuityDetected, grad1, grad2, grad2IncreaseDetected, dx0);

            // Check if we're entering high-resolution mode (only if not jumped back) and only trigger
            // high-res for genuine curvature issues, not discontinuity-related step reductions
            if (!jumpedBack and !inHighResMode and newDx < prevDx * REVERT_THRESHOLD and discontinuityDetected == 0 and curvatureChange > 0) {
                savedXBeforeHighres = x01; // Save the last good x position
                savedDxBeforeHighres = prevDx;

                enterHighResMode(&inHighResMode, &highResCount, &highResStartX, &baselineCurvatureChange, &cumulativeCurvatureChange, x, curvatureChange);
            }

            // If in high-res mode, buffer the point and assess improvement
            if (inHighResMode and !jumpedBack) {
                cumulativeCurvatureChange += curvatureChange;

                if (highResCount < HIGH_RES_SAMPLE_COUNT) { // Buffer high-res points in order
                    highResBuffer[@intCast(highResCount)].x = x;
                    highResBuffer[@intCast(highResCount)].y = y02;
                    highResBuffer[@intCast(highResCount)].grad = grad2;
                    highResBuffer[@intCast(highResCount)].stored = false;
                    highResCount += 1;
                } else {
                    // Evaluate if high-res provided sufficient improvement
                    const improvementRatio: f64 = if (baselineCurvatureChange > 0) cumulativeCurvatureChange / (baselineCurvatureChange * @as(f64, @floatFromInt(HIGH_RES_SAMPLE_COUNT))) else 1.0;

                    if (improvementRatio >= MIN_IMPROVEMENT_RATIO) { // High-res was beneficial, commit buffered points in sequence
                        commitHighResPointsInOrder(&highResBuffer, highResCount);
                        resetHighResTracking(&highResCount, &inHighResMode, &cumulativeCurvatureChange);
                        // Continue with current step size
                    } else { // High-res didn't help, abandon and continue from last good point with larger dx
                        abandonHighResMode(&highResCount, &inHighResMode);
                        x = savedXBeforeHighres + savedDxBeforeHighres;
                        dx = savedDxBeforeHighres;
                        // Don't set jumpedBack since we want to continue forward, just with larger steps
                        continue; // Skip to next iteration with the adjusted x
                    }
                }
            }

            prevDx = dx;
            dx = newDx;
        }

        // Add point to plot (skip if in high-res buffering mode or jumped back)
        if (!jumpedBack and dx >= 0 and !inHighResMode) {
            AddtoDrawMx();
        }

        // Update state for next iteration
        if (count > 0) {
            grad1 = grad2;
        }
        y00 = y01; // Update y00 for improved discontinuity detection
        y01 = y02;
        x01 = x;

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
                fnClearStack(0);
                calcMode = CM_NORMAL;
                screenUpdatingMode = SCRUPD_AUTO;
                screenUpdatingMode |= SCRUPD_SKIP_STATUSBAR_ONE_TIME;
                break;
            }
        }
    }

    if (inHighResMode and highResCount > 0) {
        abandonHighResMode(&highResCount, &inHighResMode);
    }

    // LOW_GRAPH_ACC: change back to normal operation for fresh stack.
    ctxtReal34.digits = 34;
    ctxtReal39.digits = 39;

    fillStackWithReal0();

    // LOW_GRAPH_ACC: change to SDIGS digit operation for screen graphs.
    if (significantDigitsForEqnGraphs() <= 6) {
        ctxtReal34.digits = significantDigitsForScreen;
        ctxtReal39.digits = significantDigitsForScreen + 3;
    }

    if (!(calcMode == CM_PLOT_STAT or calcMode == CM_GRAPH)) { // !GRAPHMODE: change over hourglass to the left side
        clearScreenOld(true, !true, !true); // clrStatusBar, !clrRegisterLines, !clrSoftkeys
    }
    calcMode = CM_GRAPH;
    hourGlassIconEnabled = true; // clear the current portion of statusbar
    showHideHourGlass();
    refreshStatusBar();
    fnPlot(0);
    // LOW_GRAPH_ACC: change to normal operation for graphs.
    ctxtReal34.digits = 34;
    ctxtReal39.digits = 39;
    ctxtReal51.digits = 51;
    ctxtReal75.digits = 75;
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
                showProgressReal(&X1.Real, &X1.Imag, !realIsZero(&X1.Imag));
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
                fnSolve(currentSolverVariable);
            }
        },

        EQ_CPXSOLVE_LU, EQ_CPXSOLVE => {
            fnComplexSolver();
        },

        EQ_PLOT_LU, EQ_PLOT => {
            //      PLOT_ZMY = 0; removed default zeroing of the zoom factor in eqn
            const higherXStartValue: f64 = convertRegisterToDouble(REGISTER_X);
            const lowerXStartValue: f64 = convertRegisterToDouble(REGISTER_Y);

            fnClDrawMx(5);
            _ = strcpy(&plotStatMx, "DrwMX");

            if (higherXStartValue > lowerXStartValue + 0.0001 and higherXStartValue != DOUBLE_NOT_INIT and lowerXStartValue != DOUBLE_NOT_INIT) { // pre-condition the plotter
                x_min = @floatCast(lowerXStartValue);
                x_max = @floatCast(higherXStartValue);
            }
            if (x_min > x_max) { // swap if entered in incorrect sequence
                const kk: f32 = x_max;
                x_max = x_min;
                x_min = kk;
            }
            var x_d: f32 = @floatCast(fabs(@as(f64, x_max - x_min)));
            if (x_d < 0.0001) { // too close together for float type
                x_d = 0.0001 * 10;
                if (fabs(@as(f64, x_min)) < 0.0001 or fabs(@as(f64, x_max)) < 0.0001) { // abort old values typically 0 - 0 and change to -1 to 1
                    x_d = 10;
                }
                x_min = @floatCast(@as(f64, x_min) - 0.1 * @as(f64, x_d));
                x_max = @floatCast(@as(f64, x_max) + 0.1 * @as(f64, x_d));
            }

            initialize_function();
            graph_eqn(noInitDrwMx);

            if (!getSystemFlag(FLAG_PCROS) and !getSystemFlag(FLAG_PBOX) and !getSystemFlag(FLAG_PPLUS)) {
                setSystemFlag(FLAG_PLINE_U);
            }

            reDraw = true;
            screenUpdatingMode = SCRUPD_AUTO;
            screenUpdatingMode |= SCRUPD_SKIP_STATUSBAR_ONE_TIME;
            refreshScreen(239);
        },
        else => {},
    }
}
