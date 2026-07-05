// SPDX-License-Identifier: GPL-3.0-only
const cstR = consts.cstR;
const consts = abi.constants;
const const_2 = consts.const_2;
const const_1 = consts.const_1;
//
// Zig owner for src/c47/plotstat.c: the stat-plot drawing/formatting layer.
// Faithful, line-by-line port of every PUBLIC symbol of plotstat.c plus the
// shim's z47_frontier_plot_* helpers.
//
// fnPlotStat and fnPlotRegressionLine are NOT ported here: the shim
// zig_bridge/frontier/plotstat_legacy.c #defines them away
// (z47_frontier_legacy_*), and the canonical owners live elsewhere -
// frontier.zig exports `fnPlotStat` (frontier.zig:790) and
// `fnPlotRegressionLine` (frontier.zig:960). No other code inside plotstat.c
// calls them internally (graphDrawLRline/drawline call the curve-fit helpers,
// not fnPlotStat), so they are simply omitted here.
//
// The shim's 5 helpers (z47_frontier_plot_set_plotstatmx_stats /
// _set_plotstatmx_histo / _set_statmx_histo / _has_source_data /
// _clear_screen_for_graph_entry) are declared `extern` by the consumers
// (frontier.zig, frontier_plot_stat_owned.zig) and were provided by the C shim;
// no sibling EXPORTS them, so they are reproduced here as `pub export fn`.
//
// BUILD-CONFIG (probed in src/c47/defines.h for the standard frontier build):
//   * STATDEBUG / STATDEBUG_VERBOSE: DEBUG_STAT==0 -> both undef'd -> all those
//     printf diagnostic blocks are DEAD and omitted.
//   * MONITOR_CLRSCR: #undef'd -> dead, omitted.
//   * USECURVES: #undef'd -> plotline3 collapses to plotline2(); the spline
//     helpers evalHermite/ifAnyMax are dead and omitted.
//   * SAVE_SPACE_DM42_13GRF: defined only for the old-DM42 single-file (non-QSPI)
//     C build, which the Zig owners do not model (no build option). The LIVE
//     `#if !defined(SAVE_SPACE_DM42_13GRF)` bodies are ported in full, matching
//     the sibling graphs owner.
//   * EXTRA_INFO_ON_CALC_ERROR==1 only on host & not dmcp: the moreInfoOnError
//     console hints are host-only (gated on extra_info && !dmcp_build).
//   * USEFLOATING == useFLOAT (0): both `if(USEFLOATING==useREAL4)` and
//     `if(USEFLOATING==useREAL39)` branches in drawline are comptime-false; the
//     dead convertDoubleToReal(...&XX...) calls are reproduced under comptime ifs.
//   * The else-branch `#if defined(PC_BUILD) printf("Not plotted...")` debug is
//     pure host diagnostics -> omitted.
//
// DMCP/PC split: the only direct ROM macros plotstat.c uses are lcd_fill_rect
// (clearScreenPixels, graphAxisDraw) and setBlackPixel/setWhitePixel (static
// inline in hal/lcd.h -> bitblt24). lcd_refresh appears only inside fnPlotStat
// which is provided elsewhere. All are fixed-address jump-table calls
// (LIBRARY_FN_BASE + verified offset) on firmware, real GTK symbols on host.
//
// plotstat.c is not reachable from the testSuite; verification is build/link
// across every target plus the boundary gates.

const std = @import("std");
const builtin = @import("builtin");
const frontier_build_options = @import("frontier_build_options");
const dmcp_build: bool = frontier_build_options.dmcp_build;
const old_hw: bool = frontier_build_options.old_hw;
const extra_info: bool = frontier_build_options.extra_info_on_calc_error;

const LIBRARY_FN_BASE: usize = if (old_hw) 0x08000201 else 0x08000301;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const bool_t = bool;
const calcRegister_t = i16;
const angularMode_t = c_int;
const videoMode_t = c_int;
const irfracOption_t = c_int;
const font_t = opaque {};

const DECNUMUNITS = 25;
const abi = @import("abi"); // L1 shared bindings (REPORT-23 §5)
const real_t = abi.Real;
comptime {
    if (@sizeOf(real_t) != 60) @compileError("real_t must be 60 bytes");
}
const real34_t = abi.Real34;
const realContext_t = abi.RealContext;

const matrixHeader_t = abi.MatrixHeader;
const real34Matrix_t = abi.Real34Matrix;

// item_t (typeDefinitions.h): only .itemSoftmenuName is read by RADIX34_MARK_CHAR.
const ItemFn = ?*const fn (u16) callconv(.c) void;
const item_t = abi.Item;

// ---------------------------------------------------------------------------
// Constants (defines.h / plotstat.h / display.h)
// ---------------------------------------------------------------------------
const SCREEN_WIDTH: i32 = 400;
const SCREEN_HEIGHT: i32 = 240;
const SCREEN_HEIGHT_GRAPH: i32 = SCREEN_HEIGHT; // 240
const SCREEN_WIDTH_GRAPH: i32 = SCREEN_WIDTH; // 400

const Y_POSITION_OF_REGISTER_T_LINE: i32 = 24;
const Y_POSITION_OF_REGISTER_Z_LINE: i32 = 60;

const LCD_SET_VALUE: c_int = 0;
const LCD_EMPTY_VALUE: c_int = 255;

const vmNormal: videoMode_t = 0;

const timed: u8 = 0;

const FLoatingMax: f32 = 1e38;
const FLoatingMin: f32 = -1e38;

const useFLOAT: u8 = 0;
const useREAL4: u8 = 4;
const useREAL39: u8 = 39;
const USEFLOATING: u8 = useFLOAT;

const numberIntervals: i16 = 50;
const fittedcurveboxes: c_int = 0;

const _SCAT: i8 = 1;

const PLOTSTAT: bool_t = true;

const INVALID_VARIABLE: calcRegister_t = 2199;

// curve-fit selections (defines.h)
const CF_PARABOLIC_FITTING: u16 = 64;
const CF_CAUCHY_FITTING: u16 = 128;
const CF_GAUSS_FITTING: u16 = 256;
const CF_ORTHOGONAL_FITTING: u16 = 512;

// errors
const ERROR_OVERFLOW_PLUS_INF: u8 = 4;
const ERROR_OVERFLOW_MINUS_INF: u8 = 5;
const ERROR_NO_SUMMATION_DATA: u8 = 28;
const REGISTER_X: calcRegister_t = 100;
const REGISTER_Z: calcRegister_t = 102;
const ERR_REGISTER_LINE: calcRegister_t = REGISTER_Z;

// display format
const DF_FIX: u8 = 1;
const DF_SF: u8 = 4;
const amNone: u32 = 5;
const LIMITEXP: bool_t = true;
const FRONTSPACE: bool_t = true;
const NOIRFRAC: irfracOption_t = 0;

// stringWidthC47 mode args (screen.h)
const stdNoEnlarge: c_int = 0;
const nocompress: c_int = 0;
// showStringEnhanced flags
const NO_compress: u8 = 0;
const NO_raise: u8 = 0;
const NO_Show: u8 = 1;
const NO_Bold: u8 = 0;
const NO_LF: bool_t = false;

// items
const ITM_CLSIGMA: i16 = 1429;
const ITM_SIGMAPLUS: i16 = 433;
const MNU_PLOT_SCATR: i16 = 1395;

// register data type
const dtReal34: u32 = 1; // typeDefinitions.h:200 (was 0 = dtLongInteger) // reallocateRegister(REGISTER_X, dtReal34, 0, amNone)

// temporaryInformation
const TI_SCATTER_SMI: u8 = 92;

// system flags
const FLAG_SHOWX: c_uint = 0x804C;
const FLAG_PBOX: i32 = 0x804E;
const FLAG_PCROS: i32 = 0x804F;
const FLAG_PPLUS: i32 = 0x8050;
const FLAG_PLINE: c_uint = 0x8051;
const FLAG_ENGOVR: i32 = 0x801C;
const FLAG_ASLIFT: c_uint = 0xc023;
const FLAG_NVECT: i32 = 0x8054;

// STD_* byte sequences (fonts.h).
const STD_SPACE_PUNCTUATION = "\xa0\x08";
const STD_SUB_0 = "\xa0\x80";
const STD_SUB_1 = "\xa0\x81";
const STD_SUB_2 = "\xa0\x82";
const STD_SUB_E = "\xa4\xd4";
const STD_SUP_2 = "\xa1\x62";
const STD_SUP_ASTERISK = "\xa0\x8f";
const STD_PLUS_MINUS = "\x80\xb1";
const STD_DOWN_ARROW = "\xa1\x93";
const STD_UP_ARROW = "\xa1\x91";
const STD_GAUSS_WHITE_R = "\xa4\x31";
const STD_GAUSS_WHITE_L = "\xa4\x32";
const STD_SUB_m = "\xa4\xa8";
const STD_SUB_i = "\xa4\xa4";
const STD_WCOMMA = "\xa7\x88";

const PLOT_TMP_BUF_SIZE: usize = 32;
const DISPLAY_VALUE_LEN: usize = 80;

// ---------------------------------------------------------------------------
// Constant blob (offsets from the generated constantPointers.h)
// ---------------------------------------------------------------------------

// `indexOfItems` is a C ARRAY (const item_t indexOfItems[]); bind its address
// with @extern so indexing reads element data (a [*c]const item_t extern would
// load the first 8 bytes as a pointer -> SEGV).
const indexOfItems = @extern([*c]const item_t, .{ .name = "indexOfItems" });

// ---------------------------------------------------------------------------
// File-scope globals DEFINED by plotstat.c (not exported by any sibling).
// `static real_t RR,...` are file-static -> module-level vars.
// The plotstat.h non-static globals -> pub export var.
// ---------------------------------------------------------------------------
var lr_RR: real_t = undefined;
var lr_SMI: real_t = undefined;
var lr_aa0: real_t = undefined;
var lr_aa1: real_t = undefined;
var lr_aa2: real_t = undefined;
var lr_sa0: real_t = undefined;
var lr_sa1: real_t = undefined;

pub export var graph_dx: f32 = 0;
pub export var graph_dy: f32 = 0;
pub export var roundedTicks: bool_t = false;
pub export var PLOT_INTG: bool_t = false;
pub export var PLOT_DIFF: bool_t = false;
pub export var PLOT_RMS: bool_t = false;
pub export var PLOT_SHADE: bool_t = false;
pub export var PLOT_AXIS: bool_t = false;
pub export var PLOT_ZOOM: i8 = 0;
pub export var drawHistogram: u8 = 0;

pub export var plotmode: i8 = 0;
pub export var tick_int_x: f32 = 0;
pub export var tick_int_y: f32 = 0;
pub export var xzero: u32 = 0;
pub export var yzero: u32 = 0;

// ---------------------------------------------------------------------------
// Externs - globals
// ---------------------------------------------------------------------------
extern var currentKeyCode: u8;
extern var x_min: f32;
extern var x_max: f32;
extern var y_min: f32;
extern var y_max: f32;
extern var regStatsXY: calcRegister_t;
extern var statisticalSumsPointer: ?[*]real_t;
extern var ctxtReal4: realContext_t;
extern var ctxtReal39: realContext_t;

extern var displayFormat: u8;
extern var displayFormatDigits: u8;
extern var updateDisplayValueX: bool_t;
extern var displayValueX: [DISPLAY_VALUE_LEN]u8;
extern var compressString: u8;

extern var reDraw: bool_t;
extern var plotSelection: u16;
extern var lrSelection: u16;
extern var lrChosen: u16;
extern var temporaryInformation: u8;
extern var histElementXorY: i16;
extern var loBinR: real34_t;
extern var hiBinR: real34_t;
extern var nBins: real34_t;
extern var gapItemRadix: u16;
extern var errorMessage: [*c]u8;

// plotStatMx / statMx are fixed-size C char arrays (char xxx[8]); declare as
// fixed-array extern var - &plotStatMx and indexing are correct.
extern var plotStatMx: [8]u8;
extern var statMx: [8]u8;

extern const standardFont: font_t;

// SIGMA_N = statisticalSumsPointer[0]  (defines.h)
inline fn SIGMA_N() *align(1) const real_t {
    return &statisticalSumsPointer.?[0];
}

// ---------------------------------------------------------------------------
// Externs - functions (linkable everywhere)
// ---------------------------------------------------------------------------
extern fn linkToRealMatrixRegister(regist: calcRegister_t, linkedMatrix: *real34Matrix_t) void;
extern fn findNamedVariable(variableName: [*c]const u8) calcRegister_t;
extern fn isStatsMatrix(rows: *u16, mx: [*c]u8) bool_t;
extern fn checkMinimumDataPoints(n: *align(1) const real_t) bool_t;

extern fn realToFloat(vv: *const real_t, v: *f32) void;
extern fn realToInt32C47(r: *align(1) const real_t, err: ?*bool_t) i32;
extern fn convertDoubleToReal(x: f64, destination: *real_t, ctxt: *realContext_t) void;
extern fn realLog10(x: *align(1) const real_t, res: *real_t, realContext: *realContext_t) void;
extern fn realCompareAbsGreaterThan(number1: *align(1) const real_t, number2: *align(1) const real_t) bool_t;
extern fn realCompareAbsLessThan(number1: *align(1) const real_t, number2: *align(1) const real_t) bool_t;
extern fn realCompareGreaterThan(number1: *align(1) const real_t, number2: *align(1) const real_t) bool_t;

// decNumber/decQuad behind the real*/real34* macros.
// decQuadToNumber/decQuadFromNumber are `#define`s over the linkable decimal128
// functions (decQuad.h); bind the real symbols.
extern fn decimal128ToNumber(src: *align(1) const real34_t, dst: *real_t) *real_t;
extern fn decQuadIsZero(src: *align(1) const real34_t) bool_t;
extern fn decimal128FromNumber(dst: *align(1) real34_t, src: *const real_t, ctx: *realContext_t) *align(1) real34_t;
extern fn decNumberFromString(dst: *real_t, src: [*c]const u8, ctx: *realContext_t) *real_t;
extern fn decNumberMultiply(r: *real_t, a: *align(1) const real_t, b: *align(1) const real_t, ctx: *realContext_t) *real_t;

// DECNAN | DECSNAN (decNumber.h).
const DEC_NAN_BITS: u8 = 0x20 | 0x10;

inline fn real34ToReal(src: *align(1) const real34_t, dst: *real_t) void {
    _ = decimal128ToNumber(src, dst);
}
inline fn real34IsZero(src: *align(1) const real34_t) bool_t {
    return decQuadIsZero(src);
}
inline fn realToReal34(src: *const real_t, dst: *align(1) real34_t) void {
    // realToReal34 macro uses &ctxtReal34; decimal128FromNumber needs a ctxt.
    _ = decimal128FromNumber(dst, src, &ctxtReal34);
}
extern var ctxtReal34: realContext_t;
inline fn stringToReal(src: [*c]const u8, dst: *real_t, ctxt: *realContext_t) void {
    _ = decNumberFromString(dst, src, ctxt);
}
inline fn realIsNaN(src: *align(1) const real_t) bool_t {
    // decNumberIsNaN is a macro: ((dn->bits & (DECNAN|DECSNAN)) != 0).
    return (src.bits & DEC_NAN_BITS) != 0;
}
inline fn realIsNegative(src: *align(1) const real_t) bool_t {
    return (src.bits & 0x80) == 0x80;
}
inline fn realMultiply(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberMultiply(res, op1, op2, ctxt);
}

extern fn real34ToDisplayString(real34: *align(1) const real34_t, tag: u32, displayString: [*c]u8, font: *const font_t, maxWidth: i16, displayHasNDigits: i16, limitExponent: bool_t, frontSpace: bool_t, limitIrfrac: irfracOption_t) void;

// screen / drawing primitives (real linkable c47 functions)
extern fn force_refresh(mode: u8) void;
extern fn showString(str: [*c]const u8, font: *const font_t, x: u32, y: u32, videoMode: videoMode_t, showLeadingCols: bool_t, showEndingCols: bool_t) u32;
extern fn showStringEnhanced(string: [*c]const u8, font: *const font_t, x: u32, y: u32, videoMode: videoMode_t, showLeadingCols: bool_t, showEndingCols: bool_t, compress1: u8, raise1: u8, noShow1: u8, boldString1: u8, lf: bool_t) u32;
extern fn stringWidth(str: [*c]const u8, font: *const font_t, withLeadingEmptyRows: bool_t, withEndingEmptyRows: bool_t) i16;
extern fn stringWidthC47(str: [*c]const u8, mode: c_int, comp: c_int, withLeadingEmptyRows: bool_t, withEndingEmptyRows: bool_t) u32;

// stats/curvefit helpers
extern fn drawMxN() i32;
extern fn graphResetCommon() void;
extern fn graph_Include0(mode: bool_t, statnum: u16) void;
extern fn calcSigma(maxOffset: u16) void;
extern fn fnCurveFitting(curveFitting: u16) void;
extern fn processCurvefitSelection(selection: u16, RR_: *real_t, SMI_: *real_t, aa0: *real_t, aa1: *real_t, aa2: *real_t) void;
extern fn processCurvefitSA(sa0: *real_t, sa1: *real_t) void;
extern fn minLRDataPoints(selection: u16) u16;
extern fn getCurveFitModeName(selection: u16) [*c]const u8;
extern fn getCurveFitModeFormula(selection: u16) [*c]const u8;
extern fn yIsFnx(USEFLOAT: u8, selection: u16, x: f64, y: *f64, a0: f64, a1: f64, a2: f64, XX: *real_t, YY: *real_t, RR_: *real_t, SMI_: *real_t, aa0: *real_t, aa1: *real_t, aa2: *real_t) void;
extern fn lrCountOnes(curveFitting: u16) u16;
extern fn eatSpacesEnd(ss: [*c]const u8) [*c]u8;

// misc / register / mode
extern fn getSystemFlag(sf: i32) bool_t;
extern fn setSystemFlag(sf: c_uint) void;
extern fn clearSystemFlag(sf: c_uint) void;
extern fn displayCalcErrorMessage(errorCode: u8, errMessageRegisterLine: calcRegister_t, errRegisterLine: calcRegister_t) void;
const c_moreInfoOnError = @extern(*const fn (m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) callconv(.c) void, .{ .name = "moreInfoOnError" });
extern fn clearScreenOld(clearStatusBar: bool_t, clearRegisterLines: bool_t, clearSoftkeys: bool_t) void;
extern fn clearScreenGraphs(source: u8, clearTextArea: bool_t, clearGraphArea: bool_t) void;
extern fn exitKeyWaiting() bool_t;

extern fn runFunction(func: i16) void;
extern fn reallocateRegister(regist: calcRegister_t, dataType: u32, dataSizeWithoutDataLenBlocks: u16, tag: u32) void;
extern fn getRegisterDataPointer(regist: calcRegister_t) ?*anyopaque;
extern fn liftStack() void;
extern fn fnKeyExit(unused: u16) void;
extern fn fnMinExpStdDev(unused: u16) void;

// int32ToReal34 is a macro -> decQuadFromInt32; reproduce via the decQuad fn.
extern fn decQuadFromInt32(dst: *align(1) real34_t, src: i32) *align(1) real34_t;
inline fn int32ToReal34(source: i32, destination: *align(1) real34_t) void {
    _ = decQuadFromInt32(destination, source);
}
const REGISTER_REAL34_DATA = abi.registerReal34;

// libc
extern fn strcpy(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strcat(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strchr(s: [*c]const u8, c: c_int) [*c]u8;
extern fn strlen(s: [*c]const u8) usize;
extern fn memmove(dst: ?*anyopaque, src: ?*const anyopaque, n: usize) ?*anyopaque;
extern fn strtof(nptr: [*c]const u8, endptr: ?*[*c]u8) f32;
extern fn srand(seed: c_uint) void;
extern fn rand() c_int;
const time_t = c_long;
extern fn time(t: ?*time_t) time_t;
extern fn fabs(x: f64) f64;
extern fn sqrtf(x: f32) f32;

inline fn stringByteLength(s: [*c]const u8) i32 {
    return @intCast(strlen(s));
}

// ---------------------------------------------------------------------------
// DMCP-ROM trampolines (fixed-address on firmware; verified in lft_ifc.h).
//   lcd_fill_rect: LIBRARY_FN_BASE + 60 (lft_ifc.h:61)
//   bitblt24:      LIBRARY_FN_BASE + 36 (lft_ifc.h:55)
// setBlackPixel/setWhitePixel are static inline in hal/lcd.h -> bitblt24.
// On host these resolve to real GTK-layer symbols.
// ---------------------------------------------------------------------------
const LcdFillRectFn = *const fn (x: u32, y: u32, dx: u32, dy: u32, val: c_int) callconv(.c) void;
const c_lcd_fill_rect = @extern(LcdFillRectFn, .{ .name = "lcd_fill_rect" });
inline fn lcd_fill_rect(x: u32, y: u32, dx: u32, dy: u32, val: c_int) void {
    if (comptime dmcp_build) {
        const f: LcdFillRectFn = @ptrFromInt(LIBRARY_FN_BASE + 60);
        f(x, y, dx, dy, val);
    } else {
        c_lcd_fill_rect(x, y, dx, dy, val);
    }
}

const Bitblt24Fn = *const fn (x: u32, dx: u32, y: u32, val: u32, blt_op: c_int, fill: c_int) callconv(.c) void;
const c_bitblt24 = @extern(Bitblt24Fn, .{ .name = "bitblt24" });
inline fn bitblt24(x: u32, dx: u32, y: u32, val: u32, blt_op: c_int, fill: c_int) void {
    if (comptime dmcp_build) {
        const f: Bitblt24Fn = @ptrFromInt(LIBRARY_FN_BASE + 36);
        f(x, dx, y, val, blt_op, fill);
    } else {
        c_bitblt24(x, dx, y, val, blt_op, fill);
    }
}
const BLT_OR: c_int = 0;
const BLT_ANDN: c_int = 1;
const BLT_NONE: c_int = 0;
inline fn setBlackPixel(x: u32, y: u32) void {
    bitblt24(x, 1, y, 1, BLT_OR, BLT_NONE);
}
inline fn setWhitePixel(x: u32, y: u32) void {
    bitblt24(x, 1, y, 1, BLT_ANDN, BLT_NONE);
}

// ---------------------------------------------------------------------------
// max/min macros (defines.h).  Operate at i32 (C int) precision then narrow.
// ---------------------------------------------------------------------------
inline fn maxI(a: i32, b: i32) i32 {
    return if (a > b) a else b;
}
inline fn minI(a: i32, b: i32) i32 {
    return if (a < b) a else b;
}
inline fn maxF(a: f32, b: f32) f32 {
    return if (a > b) a else b;
}

// ROUND_F2I(f) ((int)((f) >= 0 ? (f) + 0.5f : (f) - 0.5f))
inline fn ROUND_F2I(f: f32) i32 {
    return @intFromFloat(if (f >= 0) f + 0.5 else f - 0.5);
}

// moreInfoOnError helper (host-only console hint).
inline fn moreInfoOnError(m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) void {
    c_moreInfoOnError(m1, m2, m3, m4);
}

// RADIX34_MARK_CHAR (defines.h): map comma/wide-comma to ',', else '.'
//   Rx = (char*)indexOfItems[gapItemRadix].itemSoftmenuName
inline fn radix34MarkChar() u8 {
    const rx: [*c]const u8 = @ptrCast(&indexOfItems[gapItemRadix].itemSoftmenuName);
    if (rx[0] == ',' or (rx[0] == STD_WCOMMA[0] and rx[1] == STD_WCOMMA[1])) {
        return ',';
    }
    return '.';
}

// ===========================================================================
// statGraphReset
// ===========================================================================
pub export fn statGraphReset() callconv(.c) void {
    graphResetCommon();
    currentKeyCode = 255;
    roundedTicks = true;
    clearSystemFlag(FLAG_SHOWX);
    clearSystemFlag(FLAG_PLINE);
    y_min = 0;
    y_max = 1;
}

// ===========================================================================
// grf_x / grf_y
// ===========================================================================
pub export fn grf_x(i: c_int) callconv(.c) f32 {
    var xf: f32 = 0;
    var xr: real_t = undefined;

    const regStats: calcRegister_t = regStatsXY;
    if (regStats != INVALID_VARIABLE) {
        var stats: real34Matrix_t = undefined;
        linkToRealMatrixRegister(regStats, &stats);
        const cols: u16 = stats.header.matrixColumns;
        real34ToReal(&stats.matrixElements.?[@intCast(i * @as(c_int, cols))], &xr);
        realToFloat(&xr, &xf);
    } else {
        xf = 0;
    }
    return xf;
}

pub export fn grf_y(i: c_int) callconv(.c) f32 {
    var yf: f32 = 0;
    var yr: real_t = undefined;

    const regStats: calcRegister_t = regStatsXY;
    if (regStats != INVALID_VARIABLE) {
        var stats: real34Matrix_t = undefined;
        linkToRealMatrixRegister(regStats, &stats);
        const cols: u16 = stats.header.matrixColumns;
        real34ToReal(&stats.matrixElements.?[@intCast(i * @as(c_int, cols) + 1)], &yr);
        realToFloat(&yr, &yf);
    } else {
        yf = 0;
    }
    return yf;
}

// ===========================================================================
// screen_window_x
// ===========================================================================
pub export fn screen_window_x(x_minp: f32, x: f32, x_maxp: f32) callconv(.c) i16 {
    var temp: i16 = undefined;
    const tempr: f32 = ((x - x_minp) / (x_maxp - x_minp) * @as(f32, @floatFromInt(SCREEN_HEIGHT_GRAPH - 1)));

    if (tempr > 32766) {
        temp = 32767;
    } else if (tempr < -32766) {
        temp = -32767;
    } else {
        temp = @intCast(ROUND_F2I(tempr));
    }

    if (temp > SCREEN_HEIGHT_GRAPH - 1) {
        temp = @intCast(SCREEN_HEIGHT_GRAPH - 1);
    } else if (temp < 0) {
        temp = 0;
    }

    return @intCast(@as(i32, temp) + SCREEN_WIDTH - SCREEN_HEIGHT_GRAPH);
}

// ===========================================================================
// _screen_window_y  (#define minn 0)
// ===========================================================================
const minn: i32 = 0;
fn _screen_window_y(y_minp: f32, y: f32, y_maxp: f32, nolimit: bool_t) i16 {
    var temp: i32 = undefined;
    const tempr: f32 = ((y - y_minp) / (y_maxp - y_minp) * @as(f32, @floatFromInt(SCREEN_HEIGHT_GRAPH - 1 - minn)));

    if (tempr > 32766) {
        temp = 32767;
    } else if (tempr < -32766) {
        temp = -32767;
    } else {
        temp = @as(i32, @as(i16, @intCast(ROUND_F2I(tempr))));
    }

    if (!nolimit) {
        if (temp > SCREEN_HEIGHT_GRAPH - 1 - minn) {
            temp = SCREEN_HEIGHT_GRAPH - 1 - minn;
        } else if (temp < 0) {
            temp = 0;
        }
    }

    // PC_BUILD diagnostic printf omitted (pure host debug).

    return @intCast(SCREEN_HEIGHT_GRAPH - 1 - temp);
}

pub export fn screen_window_y_nolimit(y_minp: f32, y: f32, y_maxp: f32) callconv(.c) i16 {
    return _screen_window_y(y_minp, y, y_maxp, true); // nolimit
}

pub export fn screen_window_y(y_minp: f32, y: f32, y_maxp: f32) callconv(.c) i16 {
    return _screen_window_y(y_minp, y, y_maxp, false); // limit
}

// ===========================================================================
// placePixel / removePixel / clearScreenPixels
// ===========================================================================
pub export fn placePixel(x: u32, y: u32) callconv(.c) void {
    if (x < SCREEN_WIDTH_GRAPH and y < SCREEN_HEIGHT_GRAPH and y >= 1 + minn) {
        setBlackPixel(x, y);
    }
}

pub export fn removePixel(x: u32, y: u32) callconv(.c) void {
    if (x < SCREEN_WIDTH_GRAPH and y < SCREEN_HEIGHT_GRAPH and y >= 1 + minn) {
        setWhitePixel(x, y);
    }
}

pub export fn clearScreenPixels() callconv(.c) void {
    lcd_fill_rect(@intCast(SCREEN_WIDTH - SCREEN_HEIGHT_GRAPH), 0, @intCast(SCREEN_HEIGHT_GRAPH), @intCast(SCREEN_HEIGHT_GRAPH), LCD_SET_VALUE);
    lcd_fill_rect(0, @intCast(Y_POSITION_OF_REGISTER_T_LINE), @intCast(SCREEN_WIDTH - SCREEN_HEIGHT_GRAPH), @intCast(171 - 5 - Y_POSITION_OF_REGISTER_T_LINE + 1), LCD_SET_VALUE);
    lcd_fill_rect(19, @intCast(171 - 5), @intCast(SCREEN_WIDTH - SCREEN_HEIGHT_GRAPH - 19 + 1), 5, LCD_SET_VALUE);
}

// ===========================================================================
// plotcross / plotplus / plotbox / plotrect / plotHisto_coln / plotbox_fat
// (C uses max((int16_t)..,0): i16-narrowed operand then int max -> reproduce
// by narrowing the subtraction to i16 then promoting back to i32 for max.)
// ===========================================================================
inline fn i16w(v: i32) i16 {
    return @truncate(v);
}

pub export fn plotcross(xn: i16, yn: i16) callconv(.c) void {
    plotline1(@intCast(maxI(i16w(@as(i32, xn) - 2), 0)), @intCast(maxI(i16w(@as(i32, yn) - 2), 0)), xn + 2, yn + 2);
    plotline1(@intCast(maxI(i16w(@as(i32, xn) - 2), 0)), yn + 2, xn + 2, @intCast(maxI(i16w(@as(i32, yn) - 2), 0)));
}

pub export fn plotplus(xn: i16, yn: i16) callconv(.c) void {
    plotline1(@intCast(maxI(i16w(@as(i32, xn) - 3), 0)), yn, xn + 3, yn);
    plotline1(xn, yn + 3, xn, @intCast(maxI(i16w(@as(i32, yn) - 3), 0)));
}

pub export fn plotbox(xn: i16, yn: i16) callconv(.c) void {
    plotline1(@intCast(maxI(i16w(@as(i32, xn) - 2), 0)), @intCast(maxI(i16w(@as(i32, yn) - 2), 0)), @intCast(maxI(i16w(@as(i32, xn) - 2), 0)), @intCast(maxI(i16w(@as(i32, yn) - 1), 0)));
    placePixel(@intCast(maxI(i16w(@as(i32, xn) - 1), 0)), @intCast(maxI(i16w(@as(i32, yn) - 2), 0)));
    plotline1(@intCast(maxI(i16w(@as(i32, xn) - 2), 0)), yn + 2, @intCast(maxI(i16w(@as(i32, xn) - 2), 0)), yn + 1);
    placePixel(@intCast(maxI(i16w(@as(i32, xn) - 1), 0)), @intCast(@as(i32, yn) + 2));
    plotline1(xn + 2, @intCast(maxI(i16w(@as(i32, yn) - 2), 0)), xn + 1, @intCast(maxI(i16w(@as(i32, yn) - 2), 0)));
    placePixel(@intCast(@as(i32, xn) + 2), @intCast(maxI(i16w(@as(i32, yn) - 1), 0)));
    plotline1(xn + 2, yn + 2, xn + 2, yn + 1);
    placePixel(@intCast(@as(i32, xn) + 1), @intCast(@as(i32, yn) + 2));
}

pub export fn plotrect(a: i16, b: i16, c: i16, d: i16) callconv(.c) void {
    plotline1(a, b, c, b);
    plotline1(a, b, a, d);
    plotline1(c, d, c, b);
    plotline1(c, d, a, d);
}

// static (SAVE_SPACE_DM42_13GRF guard -> live here)
fn plotHisto_coln(x: i16, y: i16, y_minp: i16, y_wid: i16, colw: i16) void {
    plotrect(@intCast(maxI(i16w(@as(i32, x) - @as(i32, colw)), 0)), y_minp + y_wid, x + colw, y);
}

pub export fn plotbox_fat(xn: i16, yn: i16) callconv(.c) void {
    plotrect(@intCast(maxI(i16w(@as(i32, xn) - 3), 0)), @intCast(maxI(i16w(@as(i32, yn) - 3), 0)), xn + 3, yn + 3);
    plotrect(@intCast(maxI(i16w(@as(i32, xn) - 2), 0)), @intCast(maxI(i16w(@as(i32, yn) - 2), 0)), xn + 2, yn + 2);
}

// ===========================================================================
// plotline1 / plotline2
// ===========================================================================
pub export fn plotline1(xo: i16, yo: i16, xn: i16, yn: i16) callconv(.c) void {
    pixelline(xo, yo, xn, yn, true);
}

pub export fn plotline2(xo: i16, yo: i16, xn: i16, yn: i16) callconv(.c) void {
    pixelline(xo, yo, xn, yn, true);
    pixelline(@intCast(maxI(i16w(@as(i32, xo) - 1), 0)), yo, @intCast(maxI(i16w(@as(i32, xn) - 1), 0)), yn, true);
    pixelline(xo, @intCast(maxI(i16w(@as(i32, yo) - 1), 0)), xn, @intCast(maxI(i16w(@as(i32, yn) - 1), 0)), true);
}

// ===========================================================================
// plotline3 - USECURVES undefined -> just plotline2(xo,yo,xn,yn).
// ===========================================================================
pub export fn plotline3(xo: i16, yo: i16, xn: i16, yn: i16, first_time: bool_t, final_segment: bool_t) callconv(.c) void {
    _ = first_time;
    _ = final_segment;
    plotline2(xo, yo, xn, yn);
}

// ===========================================================================
// pixelline (Bresenham)
// ===========================================================================
pub export fn pixelline(xo_in: i16, yo_in: i16, xn: i16, yn: i16, vmNormalArg: bool_t) callconv(.c) void {
    var xo: i32 = xo_in;
    var yo: i32 = yo_in;
    const dx: i32 = @as(i32, @intCast(@abs(@as(i32, xn) - @as(i32, xo))));
    const sx: i32 = if (xo < xn) 1 else -1;
    const dy: i32 = -@as(i32, @intCast(@abs(@as(i32, yn) - @as(i32, yo))));
    const sy: i32 = if (yo < yn) 1 else -1;
    var err: i32 = dx + dy;
    var e2: i32 = undefined;

    while (true) {
        if (vmNormalArg) {
            placePixel(@bitCast(xo), @bitCast(yo));
        } else {
            removePixel(@bitCast(xo), @bitCast(yo));
        }
        if (xo == xn and yo == yn) {
            break;
        }
        e2 = 2 * err;
        if (e2 >= dy) {
            err += dy;
            xo += sx;
        }
        if (e2 <= dx) {
            err += dx;
            yo += sy;
        }
    }
}

// ===========================================================================
// graphAxisDraw
// ===========================================================================
pub export fn graphAxisDraw() callconv(.c) void {
    if (x_min <= FLoatingMin or x_min >= FLoatingMax or x_max <= FLoatingMin or x_max >= FLoatingMax or y_min <= FLoatingMin or y_min >= FLoatingMax or y_max <= FLoatingMin or y_max >= FLoatingMax) {
        return;
    }
    var cnt: u32 = undefined;

    clearScreenPixels();
    yzero = @intCast(screen_window_y(y_min, 0, y_max));
    xzero = @intCast(screen_window_x(x_min, 0, x_max));

    const minny: u32 = 0;
    const minnx: u32 = @intCast(SCREEN_WIDTH - SCREEN_HEIGHT_GRAPH);

    // SEPARATING LINE
    cnt = minny;
    while (cnt != SCREEN_HEIGHT_GRAPH) {
        setBlackPixel(minnx - 1, cnt);
        setBlackPixel(minnx - 2, cnt);
        cnt += 1;
    }

    var x: f32 = undefined;
    var y: f32 = undefined;

    if (PLOT_AXIS and !(yzero == SCREEN_HEIGHT_GRAPH - 1 or yzero == minny)) {
        // DRAW XAXIS
        cnt = minnx;
        while (cnt != SCREEN_WIDTH_GRAPH - 1) {
            setBlackPixel(cnt, yzero);
            cnt += 1;
        }

        force_refresh(timed);

        if (0 < x_max and 0 > x_min) {
            x = 0;
            while (x <= x_max) : (x += tick_int_x) {
                cnt = @intCast(screen_window_x(x_min, x, x_max));
                setBlackPixel(cnt, @intCast(minI(@as(i32, @intCast(yzero)) + 1, SCREEN_HEIGHT_GRAPH - 1)));
                setBlackPixel(cnt, @intCast(maxI(@as(i32, @intCast(yzero)) - 1, @intCast(minny))));
            }
            x = 0;
            while (x >= x_min) : (x += -tick_int_x) {
                cnt = @intCast(screen_window_x(x_min, x, x_max));
                setBlackPixel(cnt, @intCast(minI(@as(i32, @intCast(yzero)) + 1, SCREEN_HEIGHT_GRAPH - 1)));
                setBlackPixel(cnt, @intCast(maxI(@as(i32, @intCast(yzero)) - 1, @intCast(minny))));
            }
            x = 0;
            while (x <= x_max) : (x += tick_int_x * 5) {
                cnt = @intCast(screen_window_x(x_min, x, x_max));
                setBlackPixel(cnt, @intCast(minI(@as(i32, @intCast(yzero)) + 2, SCREEN_HEIGHT_GRAPH - 1)));
                setBlackPixel(cnt, @intCast(maxI(@as(i32, @intCast(yzero)) - 2, @intCast(minny))));
                setBlackPixel(cnt, @intCast(minI(@as(i32, @intCast(yzero)) + 3, SCREEN_HEIGHT_GRAPH - 1)));
                setBlackPixel(cnt, @intCast(maxI(@as(i32, @intCast(yzero)) - 3, @intCast(minny))));
            }
            x = 0;
            while (x >= x_min) : (x += -tick_int_x * 5) {
                cnt = @intCast(screen_window_x(x_min, x, x_max));
                setBlackPixel(cnt, @intCast(minI(@as(i32, @intCast(yzero)) + 2, SCREEN_HEIGHT_GRAPH - 1)));
                setBlackPixel(cnt, @intCast(maxI(@as(i32, @intCast(yzero)) - 2, @intCast(minny))));
                setBlackPixel(cnt, @intCast(minI(@as(i32, @intCast(yzero)) + 3, SCREEN_HEIGHT_GRAPH - 1)));
                setBlackPixel(cnt, @intCast(maxI(@as(i32, @intCast(yzero)) - 3, @intCast(minny))));
            }
        } else {
            x = x_min;
            while (x <= x_max) : (x += tick_int_x) {
                cnt = @intCast(screen_window_x(x_min, x, x_max));
                setBlackPixel(cnt, @intCast(minI(@as(i32, @intCast(yzero)) + 1, SCREEN_HEIGHT_GRAPH - 1)));
                setBlackPixel(cnt, @intCast(maxI(@as(i32, @intCast(yzero)) - 1, @intCast(minny))));
            }
            x = x_min;
            while (x <= x_max) : (x += tick_int_x * 5) {
                cnt = @intCast(screen_window_x(x_min, x, x_max));
                setBlackPixel(cnt, @intCast(minI(@as(i32, @intCast(yzero)) + 2, SCREEN_HEIGHT_GRAPH - 1)));
                setBlackPixel(cnt, @intCast(maxI(@as(i32, @intCast(yzero)) - 2, @intCast(minny))));
                setBlackPixel(cnt, @intCast(minI(@as(i32, @intCast(yzero)) + 3, SCREEN_HEIGHT_GRAPH - 1)));
                setBlackPixel(cnt, @intCast(maxI(@as(i32, @intCast(yzero)) - 3, @intCast(minny))));
            }
        }
    }

    if (PLOT_AXIS and !(xzero == SCREEN_WIDTH - 1 or xzero == minnx)) {
        // Write North arrow
        if (getSystemFlag(FLAG_NVECT)) {
            var tmpString2: [100]u8 = undefined;
            _ = showString("N", &standardFont, xzero - 4, minny + 14, vmNormal, true, true);
            _ = showString("x", &standardFont, xzero - 4, minny + 28, vmNormal, true, true);
            tmpString2[0] = @as(u8, 0x80) | @as(u8, 0x22);
            tmpString2[1] = 0x06;
            tmpString2[2] = 0;
            _ = showString(&tmpString2, &standardFont, xzero - 4, minny + 0, vmNormal, true, true);
        }

        // DRAW YAXIS
        lcd_fill_rect(xzero, minny, 1, @intCast(SCREEN_HEIGHT_GRAPH - @as(i32, @intCast(minny))), LCD_EMPTY_VALUE);

        force_refresh(timed);
        if (0 < y_max and 0 > y_min) {
            y = 0;
            while (y <= y_max) : (y += tick_int_y) {
                cnt = @intCast(screen_window_y(y_min, y, y_max));
                setBlackPixel(@intCast(maxI(@as(i32, @intCast(xzero)) - 1, 0)), cnt);
                setBlackPixel(@intCast(minI(@as(i32, @intCast(xzero)) + 1, SCREEN_WIDTH_GRAPH - 1)), cnt);
            }
            y = 0;
            while (y >= y_min) : (y += -tick_int_y) {
                cnt = @intCast(screen_window_y(y_min, y, y_max));
                setBlackPixel(@intCast(maxI(@as(i32, @intCast(xzero)) - 1, 0)), cnt);
                setBlackPixel(@intCast(minI(@as(i32, @intCast(xzero)) + 1, SCREEN_WIDTH_GRAPH - 1)), cnt);
            }
            y = 0;
            while (y <= y_max) : (y += tick_int_y * 5) {
                cnt = @intCast(screen_window_y(y_min, y, y_max));
                setBlackPixel(@intCast(maxI(@as(i32, @intCast(xzero)) - 2, 0)), cnt);
                setBlackPixel(@intCast(minI(@as(i32, @intCast(xzero)) + 2, SCREEN_WIDTH_GRAPH - 1)), cnt);
                setBlackPixel(@intCast(maxI(@as(i32, @intCast(xzero)) - 3, 0)), cnt);
                setBlackPixel(@intCast(minI(@as(i32, @intCast(xzero)) + 3, SCREEN_WIDTH_GRAPH - 1)), cnt);
            }
            y = 0;
            while (y >= y_min) : (y += -tick_int_y * 5) {
                cnt = @intCast(screen_window_y(y_min, y, y_max));
                setBlackPixel(@intCast(maxI(@as(i32, @intCast(xzero)) - 2, 0)), cnt);
                setBlackPixel(@intCast(minI(@as(i32, @intCast(xzero)) + 2, SCREEN_WIDTH_GRAPH - 1)), cnt);
                setBlackPixel(@intCast(maxI(@as(i32, @intCast(xzero)) - 3, 0)), cnt);
                setBlackPixel(@intCast(minI(@as(i32, @intCast(xzero)) + 3, SCREEN_WIDTH_GRAPH - 1)), cnt);
            }
        } else {
            y = y_min;
            while (y <= y_max) : (y += tick_int_y) {
                cnt = @intCast(screen_window_y(y_min, y, y_max));
                setBlackPixel(@intCast(maxI(@as(i32, @intCast(xzero)) - 1, 0)), cnt);
                setBlackPixel(@intCast(minI(@as(i32, @intCast(xzero)) + 1, SCREEN_WIDTH_GRAPH - 1)), cnt);
            }
            y = y_min;
            while (y <= y_max) : (y += tick_int_y * 5) {
                cnt = @intCast(screen_window_y(y_min, y, y_max));
                setBlackPixel(@intCast(maxI(@as(i32, @intCast(xzero)) - 2, 0)), cnt);
                setBlackPixel(@intCast(minI(@as(i32, @intCast(xzero)) + 2, SCREEN_WIDTH_GRAPH - 1)), cnt);
                setBlackPixel(@intCast(maxI(@as(i32, @intCast(xzero)) - 3, 0)), cnt);
                setBlackPixel(@intCast(minI(@as(i32, @intCast(xzero)) + 3, SCREEN_WIDTH_GRAPH - 1)), cnt);
            }
        }
    }
    force_refresh(timed);
}

// ===========================================================================
// auto_tick
// ===========================================================================
pub export fn auto_tick(tick_int_f_in: f32) callconv(.c) f32 {
    var tick_int_f = tick_int_f_in;
    var tmpString2: [100]u8 = undefined;

    if (!roundedTicks) {
        return tick_int_f;
    }
    abi.fmtExpC(&tmpString2, 1, @as(f64, fabs(tick_int_f)));
    var tx: [4]u8 = undefined;
    tx[0] = tmpString2[0]; // expecting "6.5e+01"
    tx[1] = tmpString2[1];
    tx[2] = tmpString2[2];
    tx[3] = 0;
    tick_int_f = strtof(&tx, null); // "6.5"
    tmpString2[0] = '1';
    tmpString2[2] = '0'; // "1.0e+01"
    const tick_int_f_mult: f32 = strtof(&tmpString2, null);

    if (tick_int_f > 0) {
        if (tick_int_f <= 1.3) {
            tick_int_f = 1.0;
        } else if (tick_int_f <= 1.7) {
            tick_int_f = 1.5;
        } else if (tick_int_f <= 3.0) {
            tick_int_f = 2.0;
        } else if (tick_int_f <= 6.5) {
            tick_int_f = 5.0;
        } else if (tick_int_f <= 9.9) {
            tick_int_f = 7.5;
        }
    } else {
        tick_int_f = 1;
    }
    tick_int_f *= tick_int_f_mult;

    return tick_int_f;
}

// ===========================================================================
// graph_axis
// ===========================================================================
pub export fn graph_axis() callconv(.c) void {
    graph_dx = 0;
    graph_dy = 0;

    if (graph_dx == 0) {
        tick_int_x = auto_tick((x_max - x_min) / 20);
    } else {
        tick_int_x = graph_dx;
    }

    if (graph_dy == 0) {
        tick_int_y = auto_tick((y_max - y_min) / 20);
    } else {
        tick_int_y = graph_dy;
    }

    graphAxisDraw();
}

// ===========================================================================
// radixProcess
// ===========================================================================
pub export fn radixProcess(output: [*c]u8, ss: [*c]const u8) callconv(.c) [*c]u8 {
    var ix: i8 = 0;
    var iy: i8 = 0;

    while (ss[@intCast(ix)] != 0) {
        if (ss[@intCast(ix)] == ',' or ss[@intCast(ix)] == '.') {
            output[@intCast(iy)] = radix34MarkChar();
            iy += 1;
        } else if (ss[@intCast(ix)] == '#') {
            output[@intCast(iy)] = ';';
            iy += 1;
        } else {
            output[@intCast(iy)] = ss[@intCast(ix)];
            iy += 1;
        }
        ix += 1;
    }
    output[@intCast(iy)] = 0;
    return output;
}

// ===========================================================================
// nanCheck
// ===========================================================================
pub export fn nanCheck(s02: [*c]u8) callconv(.c) void {
    if (stringByteLength(s02) > 2) {
        var ix: i32 = 2;
        while (s02[@intCast(ix)] != 0) : (ix += 1) {
            if (s02[@intCast(ix)] == 'n' and s02[@intCast(ix - 1)] == 'a' and s02[@intCast(ix - 2)] == 'n') {
                if (s02[0] == '(' and s02[@intCast(ix + 1)] != 0) {
                    _ = strcpy(s02, "(NaN");
                } else if (s02[0] == ';' and s02[@intCast(stringByteLength(s02) - 1)] == ')' and s02[@intCast(ix + 1)] != 0 and s02[@intCast(ix + 2)] != 0) {
                    _ = strcpy(s02, ";NaN)");
                }
            }
        }
    }
}

// ===========================================================================
// padEquals
// ===========================================================================
pub export fn padEquals(output: [*c]u8, ss: [*c]const u8) callconv(.c) [*c]u8 {
    var ix: i8 = 0;
    var iy: i8 = 0;

    while (ss[@intCast(ix)] != 0) {
        if ((ss[@intCast(ix)] & 0x80) == 0) {
            if (ss[@intCast(ix)] == '=') {
                output[@intCast(iy)] = STD_SPACE_PUNCTUATION[0];
                iy += 1;
                output[@intCast(iy)] = STD_SPACE_PUNCTUATION[1];
                iy += 1;
                output[@intCast(iy)] = '=';
                iy += 1;
                output[@intCast(iy)] = STD_SPACE_PUNCTUATION[0];
                iy += 1;
                output[@intCast(iy)] = STD_SPACE_PUNCTUATION[1];
                iy += 1;
            } else {
                output[@intCast(iy)] = ss[@intCast(ix)];
                iy += 1;
            }
        } else {
            output[@intCast(iy)] = ss[@intCast(ix)];
            iy += 1;
            if (ss[@intCast(ix + 1)] != 0) {
                ix += 1;
                output[@intCast(iy)] = ss[@intCast(ix)];
                iy += 1;
            }
        }
        ix += 1;
    }
    output[@intCast(iy)] = 0;
    return output;
}

// ===========================================================================
// smallE
// ===========================================================================
pub export fn smallE(output: [*c]u8, ss: [*c]const u8) callconv(.c) [*c]u8 {
    var ix: i8 = 0;
    var iy: i8 = 0;

    while (ss[@intCast(ix)] != 0) {
        if ((ss[@intCast(ix)] & 0x80) == 0) {
            if (ss[@intCast(ix)] == 'E') {
                output[@intCast(iy)] = STD_SUB_E[0];
                iy += 1;
                output[@intCast(iy)] = STD_SUB_E[1];
                iy += 1;
            } else {
                output[@intCast(iy)] = ss[@intCast(ix)];
                iy += 1;
            }
        } else {
            output[@intCast(iy)] = ss[@intCast(ix)];
            iy += 1;
            if (ss[@intCast(ix + 1)] != 0) {
                ix += 1;
                output[@intCast(iy)] = ss[@intCast(ix)];
                iy += 1;
            }
        }
        ix += 1;
    }
    output[@intCast(iy)] = 0;
    return output;
}

// ===========================================================================
// checkWidthWithPrefix (static)
// ===========================================================================
fn checkWidthWithPrefix(itemName: [*c]const u8, numStr: [*c]const u8, max_width: u32) c_int {
    var test_buffer: [128]u8 = undefined;
    abi.fmtBufZ(&test_buffer, "{s}{s}", .{ std.mem.span(itemName), std.mem.span(numStr) });
    // C passes `!nocompress` (LOGICAL not -> 1), not `~nocompress` (BITWISE not
    // -> -1). The bitwise value made stringWidthC47 mis-measure every graph tick/
    // coordinate number so checkWidthWithPrefix never fit -> formatDoubleWidth fell
    // through to "??" (the "left panel shows ? instead of numbers" report).
    return @intFromBool(stringWidthC47(&test_buffer, stdNoEnlarge, @intFromBool(nocompress == 0), false, false) < max_width);
}

// ===========================================================================
// cleanupTrailingZeros (static)
// ===========================================================================
fn cleanupTrailingZeros(str: [*c]u8) void {
    var e_pos: [*c]u8 = strchr(str, 'E');
    if (e_pos == null) {
        e_pos = strchr(str, 'e');
    }
    if (e_pos != null and e_pos[0] == 'e') {
        e_pos[0] = 'E';
    }
    if (e_pos != null) {
        const decimal_pos: [*c]u8 = strchr(str, '.');
        if (decimal_pos != null and @intFromPtr(decimal_pos) < @intFromPtr(e_pos)) {
            var p: [*c]u8 = e_pos - 1;
            while (@intFromPtr(p) > @intFromPtr(decimal_pos) and p[0] == '0') {
                p -= 1;
            }
            if (@intFromPtr(p) == @intFromPtr(decimal_pos)) {
                _ = memmove(decimal_pos, e_pos, strlen(e_pos) + 1);
            } else {
                _ = memmove(p + 1, e_pos, strlen(e_pos) + 1);
            }
        }
        e_pos = strchr(str, 'E');
        if (e_pos != null) {
            var exp_start: [*c]u8 = e_pos + 1;
            if (exp_start[0] == '+') {
                exp_start += 1;
            }
            if (exp_start[0] == '-') {
                exp_start += 1;
            }
            while (exp_start[0] == '0' and (exp_start + 1)[0] != 0) {
                _ = memmove(exp_start, exp_start + 1, strlen(exp_start + 1) + 1);
            }
        }
    } else {
        const decimal_pos: [*c]u8 = strchr(str, '.');
        if (decimal_pos != null) {
            const len: i32 = @intCast(strlen(str));
            var i: i32 = len - 1;
            const dpIdx: i32 = @intCast(@intFromPtr(decimal_pos) - @intFromPtr(str));
            while (i > dpIdx and str[@intCast(i)] == '0') {
                str[@intCast(i)] = 0;
                i -= 1;
            }
            if (i == dpIdx) {
                str[@intCast(i)] = 0;
            }
        }
    }
}

// ===========================================================================
// formatDoubleWidth
// ===========================================================================
pub export fn formatDoubleWidth(real34: *align(1) real34_t, digits: c_int, itemName: [*c]const u8, success: *bool_t, actual_max_width: c_int, buf: [*c]u8, digitswidthLimit: c_int) callconv(.c) [*c]u8 {
    const savedDisplayFormatDigits: u8 = displayFormatDigits;
    const saveddisplayFormat: u8 = displayFormat;
    const ovrENG: bool_t = getSystemFlag(FLAG_ENGOVR);
    clearSystemFlag(FLAG_ENGOVR);
    if (real34IsZero(real34)) {
        _ = strcpy(buf, "0");
        success.* = true;
        return buf;
    }

    var reall10: real_t = undefined;
    var real: real_t = undefined;
    real34ToReal(real34, &real);
    const isNegative: bool_t = realIsNegative(&real);
    var threshold9E99: real_t = undefined;
    var threshold1E_99: real_t = undefined;
    stringToReal("9E99", &threshold9E99, &ctxtReal39);
    stringToReal("1E-99", &threshold1E_99, &ctxtReal39);
    if (realCompareAbsGreaterThan(&real, &threshold9E99)) {
        _ = strcpy(buf, if (isNegative) STD_GAUSS_WHITE_L ++ STD_GAUSS_WHITE_L ++ STD_GAUSS_WHITE_L else STD_GAUSS_WHITE_R ++ STD_GAUSS_WHITE_R ++ STD_GAUSS_WHITE_R);
        success.* = true;
        return done(buf, savedDisplayFormatDigits, saveddisplayFormat, ovrENG);
    }
    if (realCompareAbsLessThan(&real, &threshold1E_99)) {
        _ = strcpy(buf, if (isNegative) STD_GAUSS_WHITE_L ++ STD_SUB_0 else STD_GAUSS_WHITE_R ++ STD_SUB_0);
        success.* = true;
        return done(buf, savedDisplayFormatDigits, saveddisplayFormat, ovrENG);
    }
    realLog10(&real, &reall10, &ctxtReal39);
    if (realToInt32C47(&reall10, null) < digits) {
        displayFormat = DF_SF;
        displayFormatDigits = @intCast(digits);
    } else {
        displayFormat = DF_FIX;
        displayFormatDigits = 0;
    }
    var ddd: c_int = 8;
    while (ddd >= 2) : (ddd -= 1) {
        updateDisplayValueX = true;
        displayValueX[0] = 0;
        real34ToDisplayString(real34, amNone, buf, &standardFont, if (digitswidthLimit == 0) 60 else @intCast(digitswidthLimit), @intCast(ddd), LIMITEXP, !FRONTSPACE, NOIRFRAC);
        updateDisplayValueX = false;
        _ = strcpy(buf, &displayValueX);
        cleanupTrailingZeros(buf);

        if (checkWidthWithPrefix(itemName, buf, @intCast(actual_max_width)) != 0) {
            success.* = false;
            return done(buf, savedDisplayFormatDigits, saveddisplayFormat, ovrENG);
        }
    }
    _ = strcpy(buf, "??");
    success.* = false;
    return done(buf, savedDisplayFormatDigits, saveddisplayFormat, ovrENG);
}

// `done:` label epilogue from formatDoubleWidth.
fn done(buf: [*c]u8, savedDisplayFormatDigits: u8, saveddisplayFormat: u8, ovrENG: bool_t) [*c]u8 {
    displayFormatDigits = savedDisplayFormatDigits;
    displayFormat = saveddisplayFormat;
    if (ovrENG) {
        setSystemFlag(FLAG_ENGOVR);
    } else {
        clearSystemFlag(FLAG_ENGOVR);
    }
    return buf;
}

// ===========================================================================
// formatCore
// ===========================================================================
pub export fn formatCore(value_in: f64, digits: c_int, handle_zero: bool_t, buf: [*c]u8, widthLimit: c_int) callconv(.c) [*c]u8 {
    var value = value_in;
    const sign: [*:0]const u8 = if (value < 0.0) "-" else "";
    if (value < 0.0) {
        value = -value;
    }

    if (handle_zero and value == 0.0) {
        abi.fmtCStr(buf, "{s}0.0", .{ @as([*:0]const u8, sign) });
    } else {
        var value34: real34_t = undefined;
        var valueR: real_t = undefined;
        var ok: bool_t = undefined;
        var tmpBuf: [128]u8 = undefined;
        convertDoubleToReal(value, &valueR, &ctxtReal39);
        realToReal34(&valueR, &value34);
        _ = strcpy(buf, sign);
        _ = strcat(buf, formatDoubleWidth(&value34, digits, "", &ok, if (widthLimit == 0) 50 else widthLimit, &tmpBuf, if (widthLimit == 0) 50 else widthLimit));
    }
    _ = radixProcess(buf, buf);
    return buf;
}

// ===========================================================================
// grphNumFormatter
// ===========================================================================
pub export fn grphNumFormatter(s02: [*c]u8, s01: [*c]const u8, inreal: f64, digits: i8, s05: [*c]const u8) callconv(.c) void {
    var format_buf: [64]u8 = undefined;
    _ = formatCore(inreal, digits, false, &format_buf, 70);
    abi.fmtCStr(s02, "{s}{s}{s}", .{ @as([*:0]const u8, s01), @as([*:0]const u8, @as([*c]const u8, &format_buf)), @as([*:0]const u8, s05) });
    nanCheck(s02);
}

// ===========================================================================
// statMxN
// ===========================================================================
pub export fn statMxN() callconv(.c) i32 {
    var rows: u16 = 0;

    if (plotStatMx[0] == 'D') {
        return 0; // Only allow S and H
    } else {
        const regStats: calcRegister_t = findNamedVariable(&plotStatMx);
        if (regStats == INVALID_VARIABLE) {
            return 0;
        } else {
            if (isStatsMatrix(&rows, &plotStatMx)) {
                var stats: real34Matrix_t = undefined;
                linkToRealMatrixRegister(regStats, &stats);
                return @intCast(stats.header.matrixRows);
            } else {
                return 0;
            }
        }
    }
}

// ===========================================================================
// plotPointGeneric
// ===========================================================================
pub export fn plotPointGeneric(xn: i16, yn: i16, xo: i16, yo: i16, PLOT_CROSS: bool_t, PLOT_BOXFAT: bool_t, PLOT_BOX: bool_t, PLOT_PLUS: bool_t, PLOT_LINE: bool_t) callconv(.c) void {
    if (PLOT_CROSS) {
        plotcross(xn, yn);
    } else if (PLOT_BOXFAT) {
        plotbox_fat(xn, yn);
    } else if (PLOT_BOX) {
        plotbox(xn, yn);
    } else if (PLOT_PLUS) {
        plotplus(xn, yn);
    }

    if (PLOT_LINE) {
        plotline1(xo, yo, xn, yn);
    }
}

// horOffsetR 109+5 ; autoinc 19 ; autoshift -4 ; horOffset 1
const horOffsetR: i32 = 109 + 5;
const autoinc: i32 = 19;
const autoshift: i32 = -4;
const horOffset: i32 = 1;

// ===========================================================================
// graphPlotstat
// ===========================================================================
pub export fn graphPlotstat(selection: u16) callconv(.c) void {
    currentKeyCode = 255;

    var cnt: u16 = undefined;
    var ix: u16 = undefined;
    var numberOfPlotPoints: u16 = undefined;
    var xo: i16 = undefined;
    var xn: i16 = undefined;
    var xN: i16 = undefined;
    var yo: i16 = undefined;
    var yn: i16 = undefined;
    var yN: i16 = undefined;
    var x: f32 = undefined;
    var y: f32 = undefined;

    numberOfPlotPoints = 0;
    roundedTicks = false;

    if ((plotStatMx[0] == 'S' and checkMinimumDataPoints(const_2())) or
        (plotStatMx[0] == 'D' and drawMxN() >= 2) or
        (plotStatMx[0] == 'H' and statMxN() >= 3))
    {
        switch (plotStatMx[0]) {
            'S' => numberOfPlotPoints = @intCast(realToInt32C47(SIGMA_N(), null)),
            'D' => numberOfPlotPoints = @intCast(drawMxN()),
            'H' => numberOfPlotPoints = @intCast(statMxN()),
            else => {},
        }

        if (reDraw) {
            regStatsXY = findNamedVariable(&plotStatMx);
            graph_axis();
            plotmode = _SCAT;

            reDraw = false;
            clearScreenGraphs(3, false, true); // !clrTextArea, clrGraphArea

            // AUTOSCALE
            x_min = FLoatingMax;
            x_max = FLoatingMin;
            y_min = FLoatingMax;
            y_max = FLoatingMin;

            // SCALING LOOP
            cnt = 0;
            while (cnt < numberOfPlotPoints) : (cnt += 1) {
                if (grf_x(cnt) < x_min) {
                    x_min = grf_x(cnt);
                }
                if (grf_x(cnt) > x_max) {
                    x_max = grf_x(cnt);
                }
                if (grf_y(cnt) < y_min) {
                    y_min = grf_y(cnt);
                }
                if (grf_y(cnt) > y_max) {
                    y_max = grf_y(cnt);
                }
                if (exitKeyWaiting()) {
                    return;
                }
            }

            if (x_min <= FLoatingMin or x_max <= FLoatingMin or y_min <= FLoatingMin or y_max <= FLoatingMin) {
                return scaleMinusInfinity();
            }
            if (x_min >= FLoatingMax or x_max >= FLoatingMax or y_min >= FLoatingMax or y_max >= FLoatingMax) {
                return scalePlusInfinity();
            }

            graph_Include0(PLOTSTAT, numberOfPlotPoints);

            roundedTicks = false;

            if (x_min <= FLoatingMin or x_max <= FLoatingMin or y_min <= FLoatingMin or y_max <= FLoatingMin) {
                return scaleMinusInfinity();
            }
            if (x_min >= FLoatingMax or x_max >= FLoatingMax or y_min >= FLoatingMax or y_max >= FLoatingMax) {
                return scalePlusInfinity();
            }

            graph_axis();
            yn = screen_window_y(y_min, grf_y(0), y_max);
            xn = screen_window_x(x_min, grf_x(0), x_max);
            xN = xn;
            yN = yn;

            const colw: i16 = @as(i16, @intFromFloat(
                (@as(f32, @floatFromInt(@as(i32, screen_window_x(x_min, grf_x(1), x_max)) - @as(i32, screen_window_x(x_min, grf_x(0), x_max)))) / 2.0),
            )) - 1;

            // MAIN GRAPH LOOP
            ix = 0;
            while (ix < numberOfPlotPoints) : (ix += 1) {
                x = grf_x(ix);
                y = grf_y(ix);
                xo = xN;
                yo = yN;
                xN = screen_window_x(x_min, x, x_max);
                yN = screen_window_y(y_min, y, y_max);

                const minN_y: i16 = 0;
                const minN_x: i16 = @intCast(SCREEN_WIDTH - SCREEN_HEIGHT_GRAPH);

                if (xN < SCREEN_WIDTH_GRAPH and xN >= minN_x and yN < SCREEN_HEIGHT_GRAPH and yN >= minN_y) {
                    yn = yN;
                    xn = xN;

                    if (drawHistogram != 0) {
                        plotHisto_coln(xN, yN, minN_y, @intCast(SCREEN_HEIGHT_GRAPH - @as(i32, minN_y)), colw);
                    }

                    plotPointGeneric(xn, yn, xo, yo, getSystemFlag(FLAG_PCROS), // cross
                        getSystemFlag(FLAG_PBOX), // fatbox
                        false, // box
                        getSystemFlag(FLAG_PPLUS), // plus
                        getSystemFlag(@bitCast(FLAG_PLINE)) // line
                    );
                }
                // else-branch is pure PC_BUILD diagnostics -> omitted.
                if (exitKeyWaiting()) {
                    return;
                }
            }
        } else {
            clearScreenGraphs(4, true, false); // clrTextArea, !clrGraphArea
        } // continue with text only

        if (drawHistogram == 1 and selection == 0) { // HISTO
            var lB: f32 = undefined;
            var hB: f32 = undefined;
            var nB: f32 = undefined;
            var lBr: real_t = undefined;
            var hBr: real_t = undefined;
            var nBr: real_t = undefined;
            var ss: [100]u8 = undefined;
            var tt: [100]u8 = undefined;
            var tmpbuf: [PLOT_TMP_BUF_SIZE]u8 = undefined;
            var index: i16 = -1;
            real34ToReal(&loBinR, &lBr);
            real34ToReal(&hiBinR, &hBr);
            real34ToReal(&nBins, &nBr);
            realToFloat(&lBr, &lB);
            realToFloat(&hBr, &hB);
            realToFloat(&nBr, &nB);

            _ = strcpy(&ss, "Histogram(");
            _ = strcat(&ss, if (histElementXorY == 1) "y)" else "x)");
            _ = showString(padEquals(&tmpbuf, &ss), &standardFont, @intCast(horOffset + 17), yLine(autoinc * @as(i32, index) - 7 + autoshift), vmNormal, false, false);
            index += 1;

            grphNumFormatter(&ss, "(", x_max, 2, "");
            grphNumFormatter(&tt, radixProcess(&tmpbuf, "#"), y_max, 2, ")");
            _ = strcat(&tt, padEquals(&tmpbuf, &ss));
            var n: u32 = showString(padEquals(&tmpbuf, &ss), &standardFont, @intCast(160 - 2 - 3 - 2 - @as(i32, stringWidth(&tt, &standardFont, false, false))), yLine(autoinc * @as(i32, index) + 2 - 3 + autoshift), vmNormal, false, false);
            grphNumFormatter(&ss, radixProcess(&tmpbuf, "#"), y_max, 2, ")");
            _ = showString(padEquals(&tmpbuf, &ss), &standardFont, n + 3, yLine(autoinc * @as(i32, index) - 3 + autoshift + 2), vmNormal, false, false);
            index += 1;

            grphNumFormatter(&ss, "(", x_min, 2, "");
            n = showString(padEquals(&tmpbuf, &ss), &standardFont, @intCast(horOffset), yLine(autoinc * @as(i32, index) - 6 + autoshift + 2), vmNormal, false, false);
            grphNumFormatter(&ss, radixProcess(&tmpbuf, "#"), y_min, 2, ")");
            _ = showString(padEquals(&tmpbuf, &ss), &standardFont, n + 3, yLine(autoinc * @as(i32, index) - 6 + autoshift + 2), vmNormal, false, false);
            index += 1;

            _ = strcpy(&ss, "Bin centres:");
            _ = showString(padEquals(&tmpbuf, &ss), &standardFont, @intCast(horOffset), yLine(autoinc * @as(i32, index) - 4 + autoshift), vmNormal, false, false);
            index += 1;
            grphNumFormatter(&ss, "", lB, 3, "");
            _ = showString(padEquals(&tmpbuf, &ss), &standardFont, @intCast(horOffsetR - @as(i32, stringWidth(&ss, &standardFont, false, false))), yLine(autoinc * @as(i32, index) - 4 + autoshift), vmNormal, false, false);
            _ = strcpy(&ss, STD_DOWN_ARROW ++ "BIN" ++ "=");
            _ = showString(padEquals(&tmpbuf, &ss), &standardFont, @intCast(horOffset), yLine(autoinc * @as(i32, index) - 4 + autoshift), vmNormal, false, false);
            index += 1;

            grphNumFormatter(&ss, "", hB, 3, "");
            _ = showString(padEquals(&tmpbuf, &ss), &standardFont, @intCast(horOffsetR - @as(i32, stringWidth(&ss, &standardFont, false, false))), yLine(autoinc * @as(i32, index) - 1 + autoshift), vmNormal, false, false);
            _ = strcpy(&ss, STD_UP_ARROW ++ "BIN" ++ "=");
            _ = showString(padEquals(&tmpbuf, &ss), &standardFont, @intCast(horOffset), yLine(autoinc * @as(i32, index) - 1 + autoshift), vmNormal, false, false);
            index += 1;

            grphNumFormatter(&ss, "", nB, 3, "");
            _ = showString(padEquals(&tmpbuf, &ss), &standardFont, @intCast(horOffsetR - @as(i32, stringWidth(&ss, &standardFont, false, false))), yLine(autoinc * @as(i32, index) - 1 + autoshift), vmNormal, false, false);
            _ = strcpy(&ss, "nBINS" ++ "=");
            _ = showString(padEquals(&tmpbuf, &ss), &standardFont, @intCast(horOffset), yLine(autoinc * @as(i32, index) - 1 + autoshift), vmNormal, false, false);
            index += 1;
            grphNumFormatter(&ss, "", (hB - lB) / nB, 3, "");
            _ = showString(padEquals(&tmpbuf, &ss), &standardFont, @intCast(horOffsetR - @as(i32, stringWidth(&ss, &standardFont, false, false))), yLine(autoinc * @as(i32, index) - 1 + autoshift), vmNormal, false, false);
            _ = strcpy(&ss, "Width" ++ "=");
            _ = showString(padEquals(&tmpbuf, &ss), &standardFont, @intCast(horOffset), yLine(autoinc * @as(i32, index) - 1 + autoshift), vmNormal, false, false);
            index += 1;
        }
    } else {
        displayCalcErrorMessage(ERROR_NO_SUMMATION_DATA, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            if (comptime !dmcp_build) {
                abi.fmtBufZ(errorMessage[0..512], "There is no statistical data available!", .{});
                moreInfoOnError("In function graphPlotstat:", errorMessage, null, null);
            }
        }
    }
    return;
}

inline fn yLine(off: i32) u32 {
    return @bitCast(Y_POSITION_OF_REGISTER_Z_LINE + off);
}

fn scalePlusInfinity() void {
    displayCalcErrorMessage(ERROR_OVERFLOW_PLUS_INF, ERR_REGISTER_LINE, REGISTER_X);
    if (comptime extra_info) {
        if (comptime !dmcp_build) {
            abi.fmtBufZ(errorMessage[0..512], "Plus Infinity encountered!", .{});
            moreInfoOnError("In function graphPlotstat:", errorMessage, null, null);
        }
    }
}

fn scaleMinusInfinity() void {
    displayCalcErrorMessage(ERROR_OVERFLOW_MINUS_INF, ERR_REGISTER_LINE, REGISTER_X);
    if (comptime extra_info) {
        if (comptime !dmcp_build) {
            abi.fmtBufZ(errorMessage[0..512], "Minus Infinity encountered!", .{});
            moreInfoOnError("In function graphPlotstat:", errorMessage, null, null);
        }
    }
}

// ===========================================================================
// demo_plot
// ===========================================================================
pub export fn demo_plot() callconv(.c) void {
    var ix: i8 = undefined;
    var t: time_t = undefined;

    srand(@intCast(@as(c_uint, @truncate(@as(c_ulong, @bitCast(time(&t)))))));
    runFunction(ITM_CLSIGMA);
    plotSelection = 0;
    srand(@intCast(@as(c_uint, @truncate(@as(c_ulong, @bitCast(time(null)))))));
    ix = 0;
    while (ix != 40) : (ix += 1) {
        const mv: c_int = 11000 + @rem(rand(), 110) - 55;

        setSystemFlag(FLAG_ASLIFT);
        reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
        int32ToReal34(mv + @rem(rand(), 4) - 2, REGISTER_REAL34_DATA(REGISTER_X));

        setSystemFlag(FLAG_ASLIFT);
        liftStack();
        reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
        int32ToReal34(mv + @rem(rand(), 4) - 2, REGISTER_REAL34_DATA(REGISTER_X));

        runFunction(ITM_SIGMAPLUS);
    }
}

// ===========================================================================
// graphDrawLRline
// ===========================================================================
pub export fn graphDrawLRline(selection: u16) callconv(.c) void {
    if (selection != 0) {
        processCurvefitSelection(selection, &lr_RR, &lr_SMI, &lr_aa0, &lr_aa1, &lr_aa2);
        realMultiply(&lr_RR, &lr_RR, &lr_RR, &ctxtReal39);
        if (orOrtho(selection) == CF_ORTHOGONAL_FITTING) {
            processCurvefitSA(&lr_sa0, &lr_sa1);
        }
        drawline(selection, &lr_RR, &lr_SMI, &lr_aa0, &lr_aa1, &lr_aa2, &lr_sa0, &lr_sa1);
    }
}

// orOrtho(a) ((a)==0 ? CF_ORTHOGONAL_FITTING : a)
inline fn orOrtho(a: u16) u16 {
    return if (a == 0) CF_ORTHOGONAL_FITTING else a;
}

// ===========================================================================
// drawline (static)
// ===========================================================================
fn drawline(selection: u16, RR: *real_t, SMI: *real_t, aa0: *real_t, aa1: *real_t, aa2: *real_t, sa0: *real_t, sa1: *real_t) void {
    var n: i32 = 0;
    var NN: u16 = undefined;
    var tmpbuf: [PLOT_TMP_BUF_SIZE]u8 = undefined;

    switch (plotStatMx[0]) {
        'S' => n = realToInt32C47(SIGMA_N(), null),
        'D' => n = drawMxN(),
        'H' => n = statMxN(),
        else => {},
    }

    NN = @truncate(@as(u32, @bitCast(n)));
    const isValidDraw: bool_t =
        selection != 0 and
        n >= @as(i32, @intCast(minLRDataPoints(selection))) and
        !realCompareGreaterThan(RR, const_1()) and
        !realIsNaN(RR) and
        !realIsNaN(aa0) and
        !realIsNaN(aa1) and
        (!realIsNaN(aa2) or minLRDataPoints(selection) == 2) and
        (!realIsNaN(SMI) or (orOrtho(selection) & CF_ORTHOGONAL_FITTING) == 0);

    var rr: f32 = undefined;
    var smi: f32 = undefined;
    var a0: f32 = undefined;
    var a1: f32 = undefined;
    var a2: f32 = undefined;
    var ssa0: f32 = undefined;
    var ssa1: f32 = undefined;
    var ss: [100]u8 = undefined;
    var tt: [100]u8 = undefined;

    var XX: real_t = undefined;
    var YY: real_t = undefined;
    if (selection == 0) {
        return;
    }

    realToFloat(RR, &rr);
    realToFloat(SMI, &smi);
    realToFloat(aa0, &a0);
    realToFloat(aa1, &a1);
    realToFloat(aa2, &a2);
    realToFloat(sa0, &ssa0);
    realToFloat(sa1, &ssa1);

    if (isValidDraw) {
        if (selection == 0 and a2 == 0 and a1 == 0 and a0 == 0) {
            return;
        }
        var ixd: f64 = undefined;
        var xo: i16 = 0;
        var xn: i16 = undefined;
        var xN: i16 = 0;
        var yo: i16 = 0;
        var yn: i16 = undefined;
        var yN: i16 = 0;
        var xd: f64 = x_min;
        var yd: f64 = 0.0;
        const Intervals: i16 = numberIntervals;
        var iterations: u16 = 0;
        const intervalW: f64 = @as(f64, @floatCast(x_max - x_min)) / @as(f64, @floatFromInt(Intervals));

        const minN_y: i16 = 0;
        const minN_x: i16 = @intCast(SCREEN_WIDTH - SCREEN_HEIGHT_GRAPH);

        ixd = @as(f64, @floatCast(x_min)) - intervalW;
        while (iterations < 2000 and xd < @as(f64, @floatCast(x_max)) + @as(f64, @floatCast(x_max - x_min)) * 0.5 and xN < SCREEN_WIDTH - 1) : (iterations += 1) {
            xo = xN;
            yo = yN;
            var xx: u16 = 0;
            while (xx < 14) : (xx += 1) {
                xd = ixd + intervalW / @as(f64, @floatFromInt(@as(u16, 1) << @intCast(xx)));
                if (comptime USEFLOATING == useREAL4) {
                    convertDoubleToReal(xd, &XX, &ctxtReal4);
                } else if (comptime USEFLOATING == useREAL39) {
                    convertDoubleToReal(xd, &XX, &ctxtReal39);
                }
                yIsFnx(USEFLOATING, selection, xd, &yd, a0, a1, a2, &XX, &YY, RR, SMI, aa0, aa1, aa2);
                xN = screen_window_x(x_min, @floatCast(xd), x_max);
                yN = screen_window_y(y_min, @floatCast(yd), y_max);
                if ((@abs(@as(i32, yN) - @as(i32, yo)) <= 2) or iterations == 0 or xN <= minN_x) {
                    break;
                }
            }
            ixd = xd;
            if (iterations > 0) {
                const tol: i16 = 4;
                if (xN < SCREEN_WIDTH_GRAPH and xN > minN_x and yN < SCREEN_HEIGHT_GRAPH - tol and yN > minN_y) {
                    yn = yN;
                    xn = xN;
                    if (fittedcurveboxes != 0) {
                        plotbox(xn, yn);
                    }
                    if (xo < SCREEN_WIDTH_GRAPH and xo > minN_x and yo < SCREEN_HEIGHT_GRAPH - tol and yo > minN_y) {
                        plotline2(xo, yo, xn, yn);
                    }
                }
            }
        }
    }

    var index: i16 = -1;
    if (selection != 0) {
        _ = strcpy(&ss, eatSpacesEnd(getCurveFitModeName(selection)));
        if (lrCountOnes(lrSelection) > 1 and selection == lrChosen) {
            _ = strcat(&ss, if (lrChosen == 0) "" else STD_SUP_ASTERISK);
        }
        _ = showString(&ss, &standardFont, @intCast(horOffset + 17), yLine(autoinc * @as(i32, index) - 10 + autoshift), vmNormal, false, false);
        index += 1;
        if (selection != CF_GAUSS_FITTING and selection != CF_CAUCHY_FITTING) {
            _ = strcpy(&ss, "y=");
            _ = strcat(&ss, getCurveFitModeFormula(selection));
            _ = showString(padEquals(&tmpbuf, &ss), &standardFont, @intCast(horOffset), yLine(autoinc * @as(i32, index) - 7 + autoshift), vmNormal, false, false);
            index += 1;
        } else {
            _ = strcpy(&ss, "y=");
            _ = strcat(&ss, getCurveFitModeFormula(selection));
            compressString = 1;
            _ = showString(&ss, &standardFont, @intCast(horOffset), yLine(autoinc * @as(i32, index) - 7 + autoshift), vmNormal, false, false);
            index += 1;
        }
    }

    if (isValidDraw) {
        if (softmenuMenuItem0() != -MNU_PLOT_SCATR) {
            abi.fmtBufZ(&ss, "{d}", .{ @as(c_uint, NN) });
            _ = showString(padEquals(&tmpbuf, &ss), &standardFont, @intCast(horOffsetR - @as(i32, stringWidth(&ss, &standardFont, false, false))), yLine(autoinc * @as(i32, index) - 2 + autoshift), vmNormal, false, false);
            abi.fmtBufZ(&ss, STD_SPACE_PUNCTUATION ++ STD_SPACE_PUNCTUATION ++ "n=", .{});
            _ = showString(padEquals(&tmpbuf, &ss), &standardFont, @intCast(horOffset), yLine(autoinc * @as(i32, index) - 2 + autoshift), vmNormal, false, false);
            index += 1;
        }

        if (orOrtho(selection) != CF_ORTHOGONAL_FITTING) {
            grphNumFormatter(&ss, "", a0, 3, "");
            _ = showString(padEquals(&tmpbuf, &ss), &standardFont, @intCast(horOffsetR - @as(i32, stringWidth(&ss, &standardFont, false, false))), yLine(autoinc * @as(i32, index) - 4 + autoshift), vmNormal, false, false);
            _ = strcpy(&ss, "a" ++ STD_SUB_0 ++ "=");
            _ = showString(padEquals(&tmpbuf, &ss), &standardFont, @intCast(horOffset), yLine(autoinc * @as(i32, index) - 4 + autoshift), vmNormal, false, false);
            index += 1;

            grphNumFormatter(&ss, "", a1, 3, "");
            _ = showString(padEquals(&tmpbuf, &ss), &standardFont, @intCast(horOffsetR - @as(i32, stringWidth(&ss, &standardFont, false, false))), yLine(autoinc * @as(i32, index) - 1 + autoshift), vmNormal, false, false);
            _ = strcpy(&ss, "a" ++ STD_SUB_1 ++ "=");
            _ = showString(padEquals(&tmpbuf, &ss), &standardFont, @intCast(horOffset), yLine(autoinc * @as(i32, index) - 1 + autoshift), vmNormal, false, false);
            index += 1;

            if (selection == CF_PARABOLIC_FITTING or selection == CF_GAUSS_FITTING or selection == CF_CAUCHY_FITTING) {
                grphNumFormatter(&ss, "", a2, 3, "");
                _ = showString(padEquals(&tmpbuf, &ss), &standardFont, @intCast(horOffsetR - @as(i32, stringWidth(&ss, &standardFont, false, false))), yLine(autoinc * @as(i32, index) - 1 + autoshift), vmNormal, false, false);
                _ = strcpy(&ss, "a" ++ STD_SUB_2 ++ "=");
                _ = showString(padEquals(&tmpbuf, &ss), &standardFont, @intCast(horOffset), yLine(autoinc * @as(i32, index) - 1 + autoshift), vmNormal, false, false);
                index += 1;
            }

            var tmpBuf: [100]u8 = undefined;
            _ = strcpy(&ss, formatCore(rr, 5, false, &tmpBuf, 50));
            _ = showString(padEquals(&tmpbuf, &ss), &standardFont, @intCast(horOffsetR - @as(i32, stringWidth(&ss, &standardFont, false, false))), yLine(autoinc * @as(i32, index) + 2 + autoshift), vmNormal, false, false);
            _ = strcpy(&ss, "r" ++ STD_SUP_2 ++ "=");
            _ = showString(padEquals(&tmpbuf, &ss), &standardFont, @intCast(horOffset), yLine(autoinc * @as(i32, index) + 2 + autoshift), vmNormal, false, false);
            index += 1;

            grphNumFormatter(&ss, "(", x_max, 2, "");
            const ssw: u16 = @intCast(showStringEnhanced(padEquals(&tmpbuf, &ss), &standardFont, 0, 0, vmNormal, false, false, NO_compress, NO_raise, NO_Show, NO_Bold, NO_LF));
            grphNumFormatter(&tt, radixProcess(&tmpbuf, "#"), y_max, 2, ")");
            const ttw: u16 = @intCast(showStringEnhanced(padEquals(&tmpbuf, &tt), &standardFont, 0, 0, vmNormal, false, false, NO_compress, NO_raise, NO_Show, NO_Bold, NO_LF));
            var nn: u32 = showString(padEquals(&tmpbuf, &ss), &standardFont, @intCast(160 - 3 - 2 - @as(i32, ssw) - @as(i32, ttw)), yLine(autoinc * @as(i32, index) + 2 + autoshift), vmNormal, false, false);
            _ = showString(padEquals(&tmpbuf, &tt), &standardFont, nn + 3, yLine(autoinc * @as(i32, index) + autoshift + 2), vmNormal, false, false);
            index += 1;
            grphNumFormatter(&ss, "(", x_min, 2, "");
            nn = showString(padEquals(&tmpbuf, &ss), &standardFont, @intCast(horOffset), yLine(autoinc * @as(i32, index) - 2 + autoshift + 2), vmNormal, false, false);
            grphNumFormatter(&ss, radixProcess(&tmpbuf, "#"), y_min, 2, ")");
            _ = showString(padEquals(&tmpbuf, &ss), &standardFont, nn + 3, yLine(autoinc * @as(i32, index) - 2 + autoshift + 2), vmNormal, false, false);
            index += 1;
        } else { // ORTHOF
            var tmpBuf: [100]u8 = undefined;
            _ = strcpy(&ss, formatCore(a0, 3, false, &tmpBuf, 50));
            _ = showString(padEquals(&tmpbuf, &ss), &standardFont, @intCast(horOffsetR - @as(i32, stringWidth(&ss, &standardFont, false, false))), yLine(autoinc * @as(i32, index) - 4 + autoshift), vmNormal, false, false);
            _ = strcpy(&ss, "a" ++ STD_SUB_0 ++ "=");
            _ = showString(padEquals(&tmpbuf, &ss), &standardFont, @intCast(horOffset), yLine(autoinc * @as(i32, index) - 4 + autoshift), vmNormal, false, false);
            index += 1;

            _ = strcpy(&ss, formatCore(ssa0, 3, false, &tmpBuf, 50));
            _ = showString(padEquals(&tmpbuf, &ss), &standardFont, @intCast(horOffsetR - @as(i32, stringWidth(&ss, &standardFont, false, false))), yLine(autoinc * @as(i32, index) - 4 + autoshift), vmNormal, false, false);
            _ = strcpy(&ss, "    " ++ STD_PLUS_MINUS);
            _ = showString(padEquals(&tmpbuf, &ss), &standardFont, @intCast(horOffset), yLine(autoinc * @as(i32, index) - 4 + autoshift), vmNormal, false, false);
            index += 1;

            _ = strcpy(&ss, formatCore(a1, 3, false, &tmpBuf, 50));
            _ = showString(padEquals(&tmpbuf, &ss), &standardFont, @intCast(horOffsetR - @as(i32, stringWidth(&ss, &standardFont, false, false))), yLine(autoinc * @as(i32, index) - 1 + autoshift), vmNormal, false, false);
            _ = strcpy(&ss, "a" ++ STD_SUB_1 ++ "=");
            _ = showString(padEquals(&tmpbuf, &ss), &standardFont, @intCast(horOffset), yLine(autoinc * @as(i32, index) - 1 + autoshift), vmNormal, false, false);
            index += 1;

            _ = strcpy(&ss, formatCore(ssa1, 3, false, &tmpBuf, 50));
            _ = showString(padEquals(&tmpbuf, &ss), &standardFont, @intCast(horOffsetR - @as(i32, stringWidth(&ss, &standardFont, false, false))), yLine(autoinc * @as(i32, index) - 1 + autoshift), vmNormal, false, false);
            _ = strcpy(&ss, "    " ++ STD_PLUS_MINUS);
            _ = showString(padEquals(&tmpbuf, &ss), &standardFont, @intCast(horOffset), yLine(autoinc * @as(i32, index) - 1 + autoshift), vmNormal, false, false);
            index += 1;

            if (softmenuMenuItem0() == -MNU_PLOT_SCATR) {
                if (n >= 30) {
                    grphNumFormatter(&ss, "", smi, 3, "");
                } else {
                    _ = strcpy(&ss, "  | n < 30");
                }

                _ = showString(padEquals(&tmpbuf, &ss), &standardFont, @intCast(horOffsetR - @as(i32, stringWidth(&ss, &standardFont, false, false))), yLine(autoinc * @as(i32, index) + 1 + autoshift), vmNormal, false, false);
                _ = strcpy(&ss, "s" ++ STD_SUB_m ++ STD_SUB_i ++ "=");
                _ = showString(padEquals(&tmpbuf, &ss), &standardFont, @intCast(horOffset), yLine(autoinc * @as(i32, index) + 1 + autoshift), vmNormal, false, false);
                index += 1;
            } else {
                _ = strcpy(&ss, formatCore(rr, 3, false, &tmpBuf, 50));
                _ = showString(padEquals(&tmpbuf, &ss), &standardFont, @intCast(horOffsetR - @as(i32, stringWidth(&ss, &standardFont, false, false))), yLine(autoinc * @as(i32, index) + 2 + autoshift), vmNormal, false, false);
                _ = strcpy(&ss, "r" ++ STD_SUP_2 ++ "=");
                _ = showString(padEquals(&tmpbuf, &ss), &standardFont, @intCast(horOffset), yLine(autoinc * @as(i32, index) + 2 + autoshift), vmNormal, false, false);
                index += 1;
            }
        }
    } else {
        if (n < 0) {
            _ = showString("invalid n", &standardFont, @intCast(horOffset), yLine(autoinc * @as(i32, index) - 7 + 2 + autoshift), vmNormal, false, false);
            index += 1;
        } else if (isnanF(a0) or isnanF(a1) or (isnanF(a2) and minLRDataPoints(selection) != 2)) {
            if ((selection & 448) != 0) {
                _ = showString("invalid a0,a1,a2", &standardFont, @intCast(horOffset), yLine(autoinc * @as(i32, index) - 7 + 2 + autoshift), vmNormal, false, false);
                index += 1;
            } else {
                _ = showString("invalid a0,a1", &standardFont, @intCast(horOffset), yLine(autoinc * @as(i32, index) - 7 + 2 + autoshift), vmNormal, false, false);
                index += 1;
            }
        } else if ((orOrtho(selection) & CF_ORTHOGONAL_FITTING) != 0 and isnanF(smi)) {
            _ = showString("invalid smi", &standardFont, @intCast(horOffset), yLine(autoinc * @as(i32, index) - 7 + 2 + autoshift), vmNormal, false, false);
            index += 1;
        } else if (rr > 1 or isnanF(rr)) {
            _ = showString("invalid r", &standardFont, @intCast(horOffset), yLine(autoinc * @as(i32, index) - 7 + 2 + autoshift), vmNormal, false, false);
            index += 1;
        } else if (NN < minLRDataPoints(selection)) {
            _ = showString("insufficient data", &standardFont, @intCast(horOffset), yLine(autoinc * @as(i32, index) - 7 + 2 + autoshift), vmNormal, false, false);
            index += 1;
            abi.fmtBufZ(&ss, " {d} < {d}", .{ @as(c_uint, NN), @as(c_uint, minLRDataPoints(selection)) });
            _ = showString(&ss, &standardFont, @intCast(horOffset), yLine(autoinc * @as(i32, index) - 7 + 2 + autoshift), vmNormal, false, false);
            index += 1;
        } else if (selection == 0) {
            _ = showString("No Valid L.R.", &standardFont, @intCast(horOffset), yLine(autoinc * @as(i32, index) - 7 + 2 + autoshift), vmNormal, false, false);
            index += 1;
        } else {
            _ = showString("L.R. error", &standardFont, @intCast(horOffset), yLine(autoinc * @as(i32, index) - 7 + 2 + autoshift), vmNormal, false, false);
            index += 1;
        }
    }
}

// isnan(float) faithfully (C isnan macro).
inline fn isnanF(v: f32) bool {
    return v != v;
}

// softmenu[softmenuStack[0].softmenuId].menuItem - reuse the sibling externs.
const softmenu_t = abi.Softmenu;
const softmenuStack_t = abi.SoftmenuStack;
const softmenu = @extern([*c]const softmenu_t, .{ .name = "softmenu" });
extern var softmenuStack: [8]softmenuStack_t;
inline fn softmenuMenuItem0() i16 {
    return softmenu[@intCast(softmenuStack[0].softmenuId)].menuItem;
}


// ===========================================================================
// fnPlotCloseSmi
// ===========================================================================
pub export fn fnPlotCloseSmi(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    fnKeyExit(0);
    fnMinExpStdDev(0);
    temporaryInformation = TI_SCATTER_SMI;
}

// ===========================================================================
// Shim helpers (z47_frontier_plot_*) - provided HERE (no sibling exports them).
// ===========================================================================
pub export fn z47_frontier_plot_set_plotstatmx_stats() callconv(.c) void {
    _ = strcpy(&plotStatMx, "STATS");
}

pub export fn z47_frontier_plot_set_plotstatmx_histo() callconv(.c) void {
    _ = strcpy(&plotStatMx, "HISTO");
}

pub export fn z47_frontier_plot_set_statmx_histo() callconv(.c) void {
    _ = strcpy(&statMx, "HISTO");
}

pub export fn z47_frontier_plot_has_source_data() callconv(.c) bool_t {
    return (plotStatMx[0] == 'S' and checkMinimumDataPoints(const_2())) or
        (plotStatMx[0] == 'D' and drawMxN() >= 2) or
        (plotStatMx[0] == 'H' and statMxN() >= 3);
}

pub export fn z47_frontier_plot_clear_screen_for_graph_entry() callconv(.c) void {
    if (!GRAPHMODE()) {
        clearScreenOld(true, false, false); // clrStatusBar, !clrRegisterLines, !clrSoftkeys
    }
}

// GRAPHMODE (calcMode == CM_PLOT_STAT || calcMode == CM_GRAPH)
const CM_PLOT_STAT: u8 = 8;
const CM_GRAPH: u8 = 15;
extern var calcMode: u8;
inline fn GRAPHMODE() bool {
    return calcMode == CM_PLOT_STAT or calcMode == CM_GRAPH;
}
