const std = @import("std");
// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/c47Extensions/graphs.c: the C47 graphing module. This
// owns the whole plot-mode command surface (fnPline/fnPcros/fnPplus/fnPbox/
// fnPcurve/fnPintg/fnPdiff/fnPrms/fnPMzoom/fnPlotZoom/fnPvect/fnPNvect/fnScale/
// fnPshade/fnComplexPlot/fnPx/fnPy/fnPlotReset/fnPlotSQ/fnListXY/fnPlotStatAdv/
// fnClGrf), the reset helpers (graphResetCommon/graph_reset), the on-screen info
// renderer graph_text (DEFINED here -> a pub export fn, NOT an extern), the
// autoscale/range helper graph_Include0, the big plot-from-memory engine
// graph_plotmem, and fnStatList. Faithful, line-by-line port.
//
// PUB EXPORT FNS (public C symbols):
//   graphResetCommon, graph_reset, fnClGrf, fnPline, fnPcros, fnPplus, fnPbox,
//   fnPcurve, fnPintg, fnPdiff, fnPrms, fnPMzoom, fnPlotZoom, fnPvect, fnPNvect,
//   fnScale, fnPshade, fnComplexPlot, fnPx, fnPy, fnPlotReset, fnPlotSQ,
//   fnListXY, fnPlotStatAdv, graph_text, graph_Include0, graph_plotmem,
//   fnStatList.
//
// PUB EXPORT VARS (file-scope C globals defined in graphs.c):
//   invalid_intg, invalid_diff, invalid_rms (bool_t), x_min, x_max, y_min, y_max
//   (f32), PLOT_ZMY (i8). The two function-local statics become module-level
//   private vars: gt_outstr (graph_text's `static char outstr[bufLen]`) and
//   gpm_prev_y_unclipped (graph_plotmem's `static int16_t prev_y_unclipped`).
//
// The file-static TO_QSPI const tables tabDeltaBig/tabDelta/tabDeltaIntBig/
// tabDeltaInt/tabDeltaRms are DEFINED here as plotdeltas (all-int8) structs in
// linksection(code_section) (pure-byte -> code_section is correct; gotcha D's
// pointer-bearing tables do not apply).
//
// PLATFORM SPLIT: fnPlotSQ's screen kick is `lcd_refresh()` on DMCP (fixed-
// address ROM trampoline LIBRARY_FN_BASE + 48, lft_ifc.h:58) vs `frontier_screen.refreshLcd(NULL)`
// on host (a real linkable symbol). clearScreen(1) in fnStatList is a host/
// firmware macro -> lcd_fill_rect(0,0,SCREEN_WIDTH,240,LCD_SET_VALUE)+frontier_status_bar.forceSBupdate();
// lcd_fill_rect is the ROM trampoline LIBRARY_FN_BASE + 60 (lft_ifc.h:61) on
// firmware and a real GTK symbol on host.
//
// BUILD-CONFIG (probed in src/c47/defines.h for the standard frontier build):
//   * SAVE_SPACE_DM42_13GRF_JM is NOT defined -> the big `#if !defined(...)`
//     body of graph_plotmem is LIVE (kept).
//   * LOW_GRAPH_ACC IS defined -> the ctxtReal34/39/51/75.digits twiddle blocks
//     in graph_plotmem are LIVE (kept).
//   * MONITOR_CLRSCR / STATDEBUG / STATDEBUG_VERBOSE are undef'd -> all those
//     printf diagnostic blocks are DEAD and omitted.
//   * EXTRA_INFO_ON_CALC_ERROR==1 only on host & not testsuite/dmcp: the
//     graph_plotmem "no summation data" extra-info sprintf+moreInfoOnError is
//     host-only (gated on extra_info && !dmcp_build), matching the sibling owners.
//   * The else-branch `#if defined(PC_BUILD) printf("Not plotted...")` debug is
//     host-only and reduced (it only prints diagnostics) -> omitted as pure debug.
//
// graphs.c is partly reachable indirectly; verification is build/link across
// every target plus the boundary gates.

const builtin = @import("builtin");
const frontier_build_options = @import("frontier_build_options");
const dmcp_build: bool = frontier_build_options.dmcp_build;
const old_hw: bool = frontier_build_options.old_hw;
const extra_info: bool = frontier_build_options.extra_info_on_calc_error;
const LIBRARY_FN_BASE: usize = if (old_hw) 0x08000201 else 0x08000301;
const code_section = if (dmcp_build and old_hw) ".qspi_data" else if (builtin.target.os.tag == .macos) "__TEXT,__text" else ".text";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const bool_t = bool;
const calcRegister_t = i16;
const videoMode_t = c_int;
const font_t = abi.Font;
const real34_t = abi.Real34;
const abi = @import("abi"); // L1 shared bindings (REPORT-23 §5)
const plot_zoom = @import("plot_zoom.zig"); // std-only plot viewport zoom
const plot_range_zero = @import("plot_range_zero.zig"); // std-only zero-axis range inclusion
const frontier_addons = @import("frontier_addons.zig"); // M-callconv: Zig-to-Zig
const frontier_char_string = @import("frontier_char_string.zig"); // M-callconv: Zig-to-Zig
const frontier_error = @import("frontier_error.zig"); // M-callconv: Zig-to-Zig
const frontier_graph_text = @import("frontier_graph_text.zig"); // M-callconv: Zig-to-Zig
const frontier_plotstat = @import("frontier_plotstat.zig"); // M-callconv: Zig-to-Zig
const frontier_radio_button_catalog = @import("frontier_radio_button_catalog.zig"); // M-callconv: Zig-to-Zig
const frontier_register_value_conversions = @import("frontier_register_value_conversions.zig"); // M-callconv: Zig-to-Zig
const frontier_screen = @import("frontier_screen.zig"); // M-callconv: Zig-to-Zig
const frontier_softmenus = @import("frontier_softmenus.zig"); // M-callconv: Zig-to-Zig
const frontier_stats = @import("frontier_stats.zig"); // M-callconv: Zig-to-Zig
const frontier_status_bar = @import("frontier_status_bar.zig"); // M-callconv: Zig-to-Zig
const realContext_t = abi.RealContext;

// GMP mpz_struct. Limb width == pointer width on every z47 target. longInteger_t
// is mpz_t == __mpz_struct[1]; an array decays to a *mpz_struct on call.
const mp_limb_t = usize;
const mpz_struct = abi.Mpz;
const longInteger_t = [1]mpz_struct;

// ---------------------------------------------------------------------------
// Constants (defines.h / typeDefinitions.h / plotstat.h / graphs.h / screen.h)
// ---------------------------------------------------------------------------
const SCREEN_WIDTH: i16 = 400;
const SCREEN_HEIGHT: i16 = 240;
const SCREEN_HEIGHT_GRAPH: i16 = SCREEN_HEIGHT; // 240
const SCREEN_WIDTH_GRAPH: i16 = SCREEN_WIDTH; // 400
const Y_POSITION_OF_REGISTER_T_LINE: i32 = 24;
const PLOT_TMP_BUF_SIZE: usize = 32;

const vmNormal: videoMode_t = 0;
const LCD_SET_VALUE: c_int = 0; // LCD_INVERT_DATA defined -> 0 on host and firmware

const force: u8 = 1;
const timed: u8 = 0;

// plot modes (plotstat.h)
const _VECT: i8 = 0;
const _SCAT: i8 = 1;

// graphs.h zoom ranges
const statZoomRangeHi: i8 = 0;
const statZoomRangeLo: i8 = -3;
const zoomRangeHi: i8 = 16;
const zoomRangeLo: i8 = -16;
const zoomOverride: i8 = 18;
const PLOTSTAT: bool = true;

// plotstat.h
const zoomfactor: f32 = 0.05;
const FLoatingMax: f32 = 1e38;
const FLoatingMin: f32 = -1e38;
const significantDigitsForScreen: i32 = 3;

// calc modes
const CM_NORMAL: u8 = 0;
const CM_PLOT_STAT: u8 = 8;
const CM_GRAPH: u8 = 15;
const CM_LISTXY: u8 = 18;

// registers / errors
const REGISTER_X: calcRegister_t = 100;
const REGISTER_Z: calcRegister_t = 102;
const REGISTER_T: calcRegister_t = 103;
const ERR_REGISTER_LINE: calcRegister_t = REGISTER_Z;
const ERROR_NO_SUMMATION_DATA: u8 = 28;
const INVALID_VARIABLE: calcRegister_t = 2199;

// reserved variables (defines.h enum)
const RESERVED_VARIABLE_UY: calcRegister_t = 2046;
const RESERVED_VARIABLE_LY: calcRegister_t = 2047;

// system flags (flags.h). Left untyped (comptime_int) so each coerces to the
// c_uint params of set/clear/flipSystemFlag AND the c_int param of getSystemFlag,
// exactly as the C int literals convert at each call site.
const FLAG_CPXPLOT = 0x804B;
const FLAG_SHOWX = 0x804C;
const FLAG_SHOWY = 0x804D;
const FLAG_PBOX = 0x804E;
const FLAG_PCROS = 0x804F;
const FLAG_PPLUS = 0x8050;
const FLAG_PLINE = 0x8051;
const FLAG_SCALE = 0x8052;
const FLAG_VECT = 0x8053;
const FLAG_NVECT = 0x8054;
const FLAG_PCURVE = 0x805A;

// menus / equations
const MNU_PLOT_STAT: i16 = 1907;
const MNU_PLOT_FUNC: i16 = 2028;
const EQ_PLOT_LU: u16 = 5;

// PLOT_NOTHING (defines.h)
const PLOT_NOTHING: u16 = 5;

// clr* (screen.h) all expand to true
const clrStatusBar: bool_t = true;
const clrRegisterLines: bool_t = true;
const clrSoftkeys: bool_t = true;
const clrTextArea: bool_t = true;
const clrGraphArea: bool_t = true;

// showStringEnhanced flag macros (screen.h)
const NO_compress: u8 = 0;
const NO_raise: u8 = 0;
const NO_Show: u8 = 1;
const DO_Show: u8 = 0;
const NO_Bold: u8 = 0;
const DO_Bold: u8 = 1;
const NO_LF: u8 = 0; // M-callconv: showStringEnhanced lf param is u8 (was bool_t)
const DO_LF: u8 = 1;

const bufLen: usize = 40;

// ---------------------------------------------------------------------------
// Globals defined by graphs.c (extern var)
// ---------------------------------------------------------------------------
pub export var invalid_intg: bool_t = true;
pub export var invalid_diff: bool_t = true;
pub export var invalid_rms: bool_t = true;

pub export var x_min: f32 = 0;
pub export var x_max: f32 = 1;
pub export var y_min: f32 = 0;
pub export var y_max: f32 = 1;
pub export var PLOT_ZMY: i8 = 0;

// function-local statics (preserve across calls)
var gt_outstr: [bufLen]u8 = std.mem.zeroes([bufLen]u8); // graph_text's static char outstr[bufLen]
var gpm_prev_y_unclipped: i16 = 0; // graph_plotmem's static int16_t prev_y_unclipped

// ---------------------------------------------------------------------------
// Cross-owner / cross-file extern globals
// ---------------------------------------------------------------------------
// plotstat.h
extern var graph_dx: f32;
extern var graph_dy: f32;
extern var roundedTicks: bool_t;
extern var PLOT_INTG: bool_t;
extern var PLOT_DIFF: bool_t;
extern var PLOT_RMS: bool_t;
extern var PLOT_SHADE: bool_t;
extern var PLOT_AXIS: bool_t;
extern var PLOT_ZOOM: i8;
extern var drawHistogram: u8;
extern var plotmode: i8;
extern var tick_int_x: f32;
extern var tick_int_y: f32;
extern var xzero: u32;
extern var yzero: u32;

// c47.h globals
extern var calcMode: u8;
extern var previousCalcMode: u8;
extern var hourGlassIconEnabled: bool_t;
extern var currentKeyCode: u8;
extern var reDraw: bool_t;
extern var lastPlotMode: u16;
extern var ListXYposition: i16;
extern var regStatsXY: calcRegister_t;
extern var tmpString: [*c]u8;
extern var errorMessage: [*c]u8;
extern var ctxtReal34: realContext_t;
extern var ctxtReal39: realContext_t;
extern var ctxtReal51: realContext_t;
extern var ctxtReal75: realContext_t;

// `plotStatMx` is a fixed-size C array `char plotStatMx[8]`; the symbol address
// is the data, so a fixed-array extern var is correct (taking &plotStatMx/indexing
// uses the symbol address). This is NOT the `[*c]const T` array trap.
extern var plotStatMx: [8]u8;

// fonts: `extern const font_t standardFont, numericFont, tinyFont;` — these are
// real symbols; the code only takes their address.
extern const standardFont: font_t;
extern const tinyFont: font_t;

// ---------------------------------------------------------------------------
// Function externs (linkable everywhere)
// ---------------------------------------------------------------------------
extern fn clearSystemFlag(sf: c_uint) void;
extern fn setSystemFlag(sf: c_uint) void;
extern fn getSystemFlag(sf: c_int) bool_t;
extern fn flipSystemFlag(sf: c_uint) void;

extern fn fnClDrawMx(origin: u8) void;

extern fn fnEqSolvGraph(func: u16) void;

extern fn drawMxN() i32;

extern fn findNamedVariable(variableName: [*c]const u8) calcRegister_t;

// graph_text / fnStatList shared text helpers

// real34 macros: real34SetZero(d) == decQuadZero(d); real34IsZero(s) == decQuadIsZero(s)
extern fn decQuadZero(d: *real34_t) *real34_t;
extern fn decQuadIsZero(s: *align(1) const real34_t) u32;
extern fn getRegisterDataPointer(regist: calcRegister_t) *anyopaque;

// longInteger (GMP) helpers

extern fn __gmpz_get_si(op: *const mpz_struct) c_long; // longIntegerToInt32
extern fn __gmpz_clear(op: *mpz_struct) void; // longIntegerFree

// EXTRA_INFO console popup (host-only; matches the error owner).
extern fn moreInfoOnError(m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) void;

// libc
extern fn strcpy(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strcat(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn sprintf(buf: [*c]u8, fmt: [*:0]const u8, ...) c_int;
extern fn snprintf(buf: [*c]u8, size: usize, fmt: [*:0]const u8, ...) c_int;
extern fn pow(base: f64, exp: f64) f64;

// host-only screen refresh (referenced under !dmcp_build).

// ---------------------------------------------------------------------------
// DMCP-ROM trampolines (fixed-address on firmware; verified in lft_ifc.h).
// lcd_refresh:   LIBRARY_FN_BASE + 48 (lft_ifc.h:58) — only under dmcp_build.
// lcd_fill_rect: LIBRARY_FN_BASE + 60 (lft_ifc.h:61) — real GTK symbol on host.
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
inline fn lcd_refresh() void {
    if (comptime dmcp_build) {
        const f: *const fn () callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 48);
        f();
    }
}

// clearScreen(cnt) macro: lcd_fill_rect(0,0,SCREEN_WIDTH,240,LCD_SET_VALUE); frontier_status_bar.forceSBupdate();
inline fn clearScreen() void {
    lcd_fill_rect(0, 0, @intCast(SCREEN_WIDTH), 240, LCD_SET_VALUE);
    frontier_status_bar.forceSBupdate();
}

// real34 macro helpers
inline fn REGISTER_REAL34_DATA(a: calcRegister_t) *real34_t {
    return abi.registerReal34Aligned(a);
}
inline fn real34SetZero(d: *real34_t) void {
    _ = decQuadZero(d);
}
inline fn real34IsZero(s: *real34_t) bool {
    return decQuadIsZero(s) != 0;
}

// GRAPHMODE macro (calcMode comparison)
inline fn GRAPHMODE() bool {
    return calcMode == CM_PLOT_STAT or calcMode == CM_GRAPH;
}

// stringByteLength(str) == (int32_t)strlen(str)
inline fn stringByteLength(str: [*c]const u8) i32 {
    var i: i32 = 0;
    while (str[@intCast(i)] != 0) : (i += 1) {}
    return i;
}

// C math macros operating on f32: min/max/fabs/sqrt promote to float semantics.
inline fn fminf(a: f32, b: f32) f32 {
    return if (a < b) a else b;
}
inline fn fmaxf(a: f32, b: f32) f32 {
    return if (a > b) a else b;
}

// ===========================================================================
// graphResetCommon / graph_reset
// ===========================================================================
pub export fn graphResetCommon() callconv(.c) void {
    graph_dx = 0;
    graph_dy = 0;

    clearSystemFlag(FLAG_CPXPLOT);
    clearSystemFlag(FLAG_SHOWY);
    clearSystemFlag(FLAG_SHOWX);
    clearSystemFlag(FLAG_VECT);
    clearSystemFlag(FLAG_NVECT);
    clearSystemFlag(FLAG_SCALE);
    setSystemFlag(FLAG_PLINE);
    setSystemFlag(FLAG_PBOX);
    clearSystemFlag(FLAG_PCURVE);
    clearSystemFlag(FLAG_PCROS);
    clearSystemFlag(FLAG_PPLUS);

    real34SetZero(REGISTER_REAL34_DATA(RESERVED_VARIABLE_UY));
    real34SetZero(REGISTER_REAL34_DATA(RESERVED_VARIABLE_LY));

    PLOT_INTG = false;
    PLOT_DIFF = false;
    PLOT_RMS = false;
    PLOT_SHADE = false;
    PLOT_ZMY = 0;
    PLOT_ZOOM = 0;
    plotmode = _SCAT;
    tick_int_x = 0;
    tick_int_y = 0;
    PLOT_AXIS = false;
}

pub export fn graph_reset() callconv(.c) void {
    graphResetCommon();
}

// ===========================================================================
// fnClGrf
// ===========================================================================
pub export fn fnClGrf(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    graph_reset();
    fnClDrawMx(2);
    _ = strcpy(&plotStatMx, "DrwMX");
    frontier_radio_button_catalog.fnRefreshState();
}

// ===========================================================================
// fnPline / fnPcros / fnPplus / fnPbox / fnPcurve
// ===========================================================================
pub export fn fnPline(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    flipSystemFlag(FLAG_PLINE);
    if (!getSystemFlag(FLAG_PLINE) and !getSystemFlag(FLAG_PCROS) and !getSystemFlag(FLAG_PBOX) and !getSystemFlag(FLAG_PPLUS)) {
        setSystemFlag(FLAG_PBOX);
    }
    if (!getSystemFlag(FLAG_PLINE)) {
        clearSystemFlag(FLAG_PCURVE);
    }
    frontier_radio_button_catalog.fnRefreshState();
    fnPlotSQ(0);
}

pub export fn fnPcros(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    flipSystemFlag(FLAG_PCROS);
    if (getSystemFlag(FLAG_PCROS)) {
        clearSystemFlag(FLAG_PBOX);
        clearSystemFlag(FLAG_PPLUS);
    }
    if (!getSystemFlag(FLAG_PCROS) and !getSystemFlag(FLAG_PBOX) and !getSystemFlag(FLAG_PPLUS)) {
        setSystemFlag(FLAG_PLINE);
    }
    frontier_radio_button_catalog.fnRefreshState();
    fnPlotSQ(0);
}

pub export fn fnPplus(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    flipSystemFlag(FLAG_PPLUS);
    if (getSystemFlag(FLAG_PPLUS)) {
        clearSystemFlag(FLAG_PBOX);
        clearSystemFlag(FLAG_PCROS);
    }
    if (!getSystemFlag(FLAG_PCROS) and !getSystemFlag(FLAG_PBOX) and !getSystemFlag(FLAG_PPLUS)) {
        setSystemFlag(FLAG_PLINE);
    }
    frontier_radio_button_catalog.fnRefreshState();
    fnPlotSQ(0);
}

pub export fn fnPbox(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    flipSystemFlag(FLAG_PBOX);
    if (getSystemFlag(FLAG_PBOX)) {
        clearSystemFlag(FLAG_PCROS);
        clearSystemFlag(FLAG_PPLUS);
    }
    if (!getSystemFlag(FLAG_PCROS) and !getSystemFlag(FLAG_PBOX) and !getSystemFlag(FLAG_PPLUS)) {
        setSystemFlag(FLAG_PLINE);
    }
    frontier_radio_button_catalog.fnRefreshState();
    fnPlotSQ(0);
}

pub export fn fnPcurve(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    flipSystemFlag(FLAG_PCURVE);
    if (getSystemFlag(FLAG_PCURVE)) {
        setSystemFlag(FLAG_PLINE);
    }
    frontier_radio_button_catalog.fnRefreshState();
    fnPlotSQ(0);
}

// ===========================================================================
// fnPintg / fnPdiff / fnPrms
// ===========================================================================
pub export fn fnPintg(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    PLOT_INTG = !PLOT_INTG;
    if (!PLOT_INTG) {
        PLOT_SHADE = false;
    }
    clearSystemFlag(FLAG_VECT);
    clearSystemFlag(FLAG_NVECT);
    frontier_radio_button_catalog.fnRefreshState();
    fnPlotSQ(0);
}

pub export fn fnPdiff(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    PLOT_DIFF = !PLOT_DIFF;
    clearSystemFlag(FLAG_VECT);
    clearSystemFlag(FLAG_NVECT);
    frontier_radio_button_catalog.fnRefreshState();
    fnPlotSQ(0);
}

pub export fn fnPrms(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    PLOT_RMS = !PLOT_RMS;
    clearSystemFlag(FLAG_VECT);
    clearSystemFlag(FLAG_NVECT);
    frontier_radio_button_catalog.fnRefreshState();
    fnPlotSQ(0);
}

// ===========================================================================
// fnPMzoom (param = 2: positive; param = 1: negative)
// ===========================================================================
pub export fn fnPMzoom(param: u16) callconv(.c) void {
    switch (calcMode) {
        CM_PLOT_STAT => {
            const increment: i8 = if (param == 2) 1 else if (param == 1) -1 else 0;
            PLOT_ZOOM +%= increment;
            if (PLOT_ZOOM > statZoomRangeHi) {
                PLOT_ZOOM = statZoomRangeLo;
            } else if (PLOT_ZOOM < statZoomRangeLo) {
                PLOT_ZOOM = statZoomRangeHi;
            }
            if (PLOT_ZOOM != 0) {
                PLOT_AXIS = true;
            } else {
                PLOT_AXIS = false;
            }
        },
        CM_GRAPH => {
            PLOT_AXIS = true;
            const increment: i8 = if (param == 2) 1 else if (param == 1) -1 else 0;
            PLOT_ZMY +%= increment;
            if (PLOT_ZMY == zoomOverride - 1 or PLOT_ZMY == zoomOverride + 1) {
                PLOT_ZMY = 0;
            } else if (PLOT_ZMY > zoomOverride + 1) {
                PLOT_ZMY = zoomRangeLo;
            } else if (PLOT_ZMY < zoomRangeLo) {
                PLOT_ZMY = zoomRangeHi;
            }
            frontier_radio_button_catalog.fnRefreshState();
            fnPlotSQ(0);
        },
        else => {},
    }
}

// ===========================================================================
// fnPlotZoom
// ===========================================================================
pub export fn fnPlotZoom(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var x: longInteger_t = undefined;
    var ii: i32 = undefined;

    if (frontier_register_value_conversions.getRegisterAsLongInt(REGISTER_X, &x[0], null)) {
        ii = @truncate(__gmpz_get_si(&x[0])); // longIntegerToInt32(x, ii)
        // the ZOOM command from outside the PLOT mode only works for PLSTAT
        PLOT_ZMY = @truncate(ii);
    }
    __gmpz_clear(&x[0]); // longIntegerFree(x)
}

// ===========================================================================
// calculateZoomFactor / multiplyZoomFactors (static)
// ===========================================================================
const basefactor: f32 = 4.5;
fn calculateZoomFactor(factor: f32, aa: *f32) void {
    if (factor != 0) {
        // C: (*aa) *= pow(basefactor, -factor); pow returns double and the f32 *aa
        // promotes to double for the multiply, then narrows back on store.
        aa.* = @floatCast(@as(f64, aa.*) * pow(@as(f64, basefactor), @as(f64, -factor)));
    }
}

fn multiplyZoomFactors(plotzoomx: f32, plotzoomy: f32, histofactor: f32, x_min_: *f32, x_max_: *f32, y_min_: *f32, y_max_: *f32, dx: *f32, dy: *f32) void {
    plot_zoom.multiplyZoomFactors(plotzoomx, plotzoomy, histofactor, zoomfactor, x_min_, x_max_, y_min_, y_max_, dx, dy);
}

// ===========================================================================
// fnPvect / fnPNvect / fnScale / fnPshade
// ===========================================================================
pub export fn fnPvect(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    flipSystemFlag(FLAG_VECT);
    if (getSystemFlag(FLAG_VECT)) {
        clearSystemFlag(FLAG_NVECT);
    }
    PLOT_INTG = false;
    PLOT_DIFF = false;
    PLOT_RMS = false;
    PLOT_SHADE = false;
    frontier_radio_button_catalog.fnRefreshState();
    fnPlotSQ(0);
}

pub export fn fnPNvect(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    flipSystemFlag(FLAG_NVECT);
    if (getSystemFlag(FLAG_NVECT)) {
        clearSystemFlag(FLAG_VECT);
    }
    PLOT_INTG = false;
    PLOT_DIFF = false;
    PLOT_RMS = false;
    PLOT_SHADE = false;
    frontier_radio_button_catalog.fnRefreshState();
    fnPlotSQ(0);
}

pub export fn fnScale(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    flipSystemFlag(FLAG_SCALE);
    frontier_radio_button_catalog.fnRefreshState();
    fnPlotSQ(0);
}

pub export fn fnPshade(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    PLOT_SHADE = !PLOT_SHADE;
    if (PLOT_SHADE) {
        PLOT_INTG = true;
    }
    clearSystemFlag(FLAG_VECT);
    clearSystemFlag(FLAG_NVECT);
    frontier_radio_button_catalog.fnRefreshState();
    fnPlotSQ(0);
}

// ===========================================================================
// fnComplexPlot / fnPx / fnPy
// ===========================================================================
pub export fn fnComplexPlot(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    flipSystemFlag(FLAG_CPXPLOT);
    frontier_radio_button_catalog.fnRefreshState();
    fnEqSolvGraph(EQ_PLOT_LU);
    fnPlotSQ(0);
}

pub export fn fnPx(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    flipSystemFlag(FLAG_SHOWX);
    frontier_radio_button_catalog.fnRefreshState();
    fnPlotSQ(0);
}

pub export fn fnPy(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    flipSystemFlag(FLAG_SHOWY);
    frontier_radio_button_catalog.fnRefreshState();
    fnPlotSQ(0);
}

// ===========================================================================
// fnPlotReset
// ===========================================================================
pub export fn fnPlotReset(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    graph_reset();
    if (GRAPHMODE()) {
        frontier_radio_button_catalog.fnRefreshState();
        fnPlotSQ(0);
    }
}

// ===========================================================================
// fnPlotSQ (DMCP lcd_refresh vs host refreshLcd)
// ===========================================================================
pub export fn fnPlotSQ(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (comptime dmcp_build) {
        lcd_refresh();
    } else {
        _ = frontier_screen.refreshLcd(null);
    }

    PLOT_AXIS = true;

    if (GRAPHMODE()) {
        previousCalcMode = CM_NORMAL;
    } else {
        previousCalcMode = calcMode;
        frontier_screen.clearScreenOld(@intFromBool(clrStatusBar), @intFromBool(!clrRegisterLines), @intFromBool(!clrSoftkeys)); // Change over hourglass to the left side
    }

    calcMode = CM_GRAPH;
    hourGlassIconEnabled = true; // clear the current portion of statusbar
    frontier_status_bar.showHideHourGlass();
    frontier_status_bar.refreshStatusBar();

    if (frontier_softmenus.menu(0) != -MNU_PLOT_FUNC and plotStatMx[0] == 'D') {
        frontier_softmenus.showSoftmenu(-MNU_PLOT_FUNC);
    } else if (frontier_softmenus.menu(0) != -MNU_PLOT_STAT and plotStatMx[0] == 'S') {
        frontier_softmenus.showSoftmenu(-MNU_PLOT_STAT);
    }
}

// ===========================================================================
// fnListXY
// ===========================================================================
pub export fn fnListXY(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (if (plotStatMx[0] == 'D') (drawMxN() >= 1) else false) {
        calcMode = CM_LISTXY; // Used to view graph/listing
        ListXYposition = 0;
    }
}

// ===========================================================================
// fnPlotStatAdv
// ===========================================================================
pub export fn fnPlotStatAdv(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    lastPlotMode = PLOT_NOTHING;
    _ = strcpy(&plotStatMx, "STATS");
    setSystemFlag(FLAG_PLINE);
    PLOT_SHADE = true;
    fnPlotSQ(0);
}

// ===========================================================================
// plotarrow (static)
// ===========================================================================
fn plotarrow(xo: i16, yo: i16, xn: i16, yn: i16) void {
    var dx: f32 = undefined;
    var dy: f32 = undefined;
    const dydx: f32 = @floatFromInt(yn - yo);
    const ddx: f32 = @floatFromInt(xn - xo);
    const zz: f32 = @sqrt(dydx * dydx + ddx * ddx);
    const zzz: f32 = 3;
    dy = dydx * (zzz / zz);
    dx = ddx * (zzz / zz);
    if (!(xo == xn and yo == yn)) {
        frontier_plotstat.plotline1(xn + fToI16(-3 * dx + dy), yn + fToI16(-3 * dy - dx), xn, yn);
        frontier_plotstat.plotline1(xn + fToI16(-3 * dx - dy), yn + fToI16(-3 * dy + dx), xn, yn);
    } else {
        frontier_plotstat.placePixel(@intCast(xn), @intCast(yn));
    }
}
// C implicitly truncates the float argument to int16_t in frontier_plotstat.plotline1(int16_t,...).
inline fn fToI16(v: f32) i16 {
    return @intFromFloat(@trunc(v));
}

// ===========================================================================
// plotdeltas tables (TO_QSPI const, all int8 -> code_section)
// ===========================================================================
const plotdeltas = struct {
    valid: i8,
    xd1: i8,
    yd1: i8,
    xd2: i8,
    yd2: i8,
};

const tabDeltaBig linksection(code_section) = [_]plotdeltas{
    .{ .valid = 1, .xd1 = 0, .yd1 = -2, .xd2 = 5, .yd2 = 6 },
    .{ .valid = 1, .xd1 = 5, .yd1 = 6, .xd2 = -5, .yd2 = 6 },
    .{ .valid = 1, .xd1 = -5, .yd1 = 6, .xd2 = 0, .yd2 = -2 },
    .{ .valid = 0, .xd1 = 0, .yd1 = 0, .xd2 = 0, .yd2 = 0 },
};
fn plotdeltabig(xn: i16, yn: i16) void {
    var ii: i8 = 0;
    while (tabDeltaBig[@intCast(ii)].valid == 1) {
        const e = tabDeltaBig[@intCast(ii)];
        frontier_plotstat.plotline1(xn + @as(i16, e.xd1), yn + @as(i16, e.yd1), xn + @as(i16, e.xd2), yn + @as(i16, e.yd2));
        ii += 1;
    }
}

const tabDelta linksection(code_section) = [_]plotdeltas{
    .{ .valid = 1, .xd1 = 0, .yd1 = -2, .xd2 = 0, .yd2 = 0 },
    .{ .valid = 1, .xd1 = -1, .yd1 = -1, .xd2 = 0, .yd2 = 0 },
    .{ .valid = 1, .xd1 = -1, .yd1 = 0, .xd2 = 0, .yd2 = 0 },
    .{ .valid = 1, .xd1 = -2, .yd1 = 1, .xd2 = 0, .yd2 = 0 },
    .{ .valid = 1, .xd1 = -2, .yd1 = 2, .xd2 = 0, .yd2 = 0 },
    .{ .valid = 1, .xd1 = 1, .yd1 = -1, .xd2 = 0, .yd2 = 0 },
    .{ .valid = 1, .xd1 = 1, .yd1 = 0, .xd2 = 0, .yd2 = 0 },
    .{ .valid = 1, .xd1 = 2, .yd1 = 1, .xd2 = 0, .yd2 = 0 },
    .{ .valid = 1, .xd1 = 2, .yd1 = 2, .xd2 = 0, .yd2 = 0 },
    .{ .valid = 1, .xd1 = -1, .yd1 = 2, .xd2 = 0, .yd2 = 0 },
    .{ .valid = 1, .xd1 = 0, .yd1 = 2, .xd2 = 0, .yd2 = 0 },
    .{ .valid = 1, .xd1 = 1, .yd1 = 2, .xd2 = 0, .yd2 = 0 },
    .{ .valid = 0, .xd1 = 0, .yd1 = 0, .xd2 = 0, .yd2 = 0 },
};
fn plotdelta(xn: i16, yn: i16) void {
    var ii: i8 = 0;
    while (tabDelta[@intCast(ii)].valid == 1) {
        const e = tabDelta[@intCast(ii)];
        frontier_plotstat.placePixel(@intCast(xn + @as(i16, e.xd1)), @intCast(yn + @as(i16, e.yd1)));
        ii += 1;
    }
}

const tabDeltaIntBig linksection(code_section) = [_]plotdeltas{
    .{ .valid = 1, .xd1 = 0, .yd1 = -2, .xd2 = 3, .yd2 = -2 },
    .{ .valid = 1, .xd1 = 0, .yd1 = -1, .xd2 = 3, .yd2 = -1 },
    .{ .valid = 1, .xd1 = -3, .yd1 = 6, .xd2 = 0, .yd2 = 6 },
    .{ .valid = 1, .xd1 = -3, .yd1 = 7, .xd2 = 0, .yd2 = 7 },
    .{ .valid = 1, .xd1 = 0, .yd1 = 5, .xd2 = 0, .yd2 = -2 },
    .{ .valid = 1, .xd1 = 1, .yd1 = 5, .xd2 = 1, .yd2 = -2 },
    .{ .valid = 0, .xd1 = 0, .yd1 = 0, .xd2 = 0, .yd2 = 0 },
};
fn plotintbig(xn: i16, yn: i16) void {
    var ii: i8 = 0;
    while (tabDeltaIntBig[@intCast(ii)].valid == 1) {
        const e = tabDeltaIntBig[@intCast(ii)];
        frontier_plotstat.plotline1(xn + @as(i16, e.xd1), yn + @as(i16, e.yd1), xn + @as(i16, e.xd2), yn + @as(i16, e.yd2));
        ii += 1;
    }
}

const tabDeltaInt linksection(code_section) = [_]plotdeltas{
    .{ .valid = 1, .xd1 = 0, .yd1 = 0, .xd2 = 0, .yd2 = 0 },
    .{ .valid = 1, .xd1 = 0, .yd1 = -1, .xd2 = 0, .yd2 = 0 },
    .{ .valid = 1, .xd1 = 0, .yd1 = -2, .xd2 = 0, .yd2 = 0 },
    .{ .valid = 1, .xd1 = 0, .yd1 = 1, .xd2 = 0, .yd2 = 0 },
    .{ .valid = 1, .xd1 = 0, .yd1 = 2, .xd2 = 0, .yd2 = 0 },
    .{ .valid = 1, .xd1 = 1, .yd1 = -2, .xd2 = 0, .yd2 = 0 },
    .{ .valid = 1, .xd1 = -1, .yd1 = 2, .xd2 = 0, .yd2 = 0 },
    .{ .valid = 0, .xd1 = 0, .yd1 = 0, .xd2 = 0, .yd2 = 0 },
};
fn plotint(xn: i16, yn: i16) void {
    var ii: i8 = 0;
    while (tabDeltaInt[@intCast(ii)].valid == 1) {
        const e = tabDeltaInt[@intCast(ii)];
        frontier_plotstat.placePixel(@intCast(xn + @as(i16, e.xd1)), @intCast(yn + @as(i16, e.yd1)));
        ii += 1;
    }
}

const tabDeltaRms linksection(code_section) = [_]plotdeltas{
    .{ .valid = 1, .xd1 = 1, .yd1 = -1, .xd2 = 0, .yd2 = 0 },
    .{ .valid = 1, .xd1 = -1, .yd1 = -1, .xd2 = 0, .yd2 = 0 },
    .{ .valid = 1, .xd1 = 0, .yd1 = -1, .xd2 = 0, .yd2 = 0 },
    .{ .valid = 1, .xd1 = 1, .yd1 = 0, .xd2 = 0, .yd2 = 0 },
    .{ .valid = 1, .xd1 = -1, .yd1 = 0, .xd2 = 0, .yd2 = 0 },
    .{ .valid = 1, .xd1 = 0, .yd1 = 0, .xd2 = 0, .yd2 = 0 },
    .{ .valid = 1, .xd1 = 1, .yd1 = 1, .xd2 = 0, .yd2 = 0 },
    .{ .valid = 1, .xd1 = -1, .yd1 = 1, .xd2 = 0, .yd2 = 0 },
    .{ .valid = 1, .xd1 = 0, .yd1 = 1, .xd2 = 0, .yd2 = 0 },
    .{ .valid = 0, .xd1 = 0, .yd1 = 0, .xd2 = 0, .yd2 = 0 },
};
fn plotrms(xn: i16, yn: i16) void {
    var ii: i8 = 0;
    while (tabDeltaRms[@intCast(ii)].valid == 1) {
        const e = tabDeltaRms[@intCast(ii)];
        frontier_plotstat.placePixel(@intCast(xn + @as(i16, e.xd1)), @intCast(yn + @as(i16, e.yd1)));
        ii += 1;
    }
}

// ===========================================================================
// showGraphTickText1 (static)
// ===========================================================================
fn showGraphTickText1(tick_int_x_: f32, tick_int_y_: f32, xoff: i32, yoff1: i32, yoff2: i32, acc: u16) void {
    var buff: [32]u8 = undefined;
    var outstr: [bufLen]u8 = undefined;
    var tmpBuf: [100]u8 = undefined;
    abi.fmtBufZ(tmpString[0..2560], "  y {s}/tick  ", .{@as([*:0]const u8, frontier_plotstat.radixProcess(&buff, frontier_plotstat.formatCore(@as(f64, tick_int_y_), @intCast(acc), false, &tmpBuf, 50)))});
    frontier_char_string.convertDigits(frontier_plotstat.smallE(&buff, tmpString), &outstr);
    _ = frontier_screen.showString(&outstr, &standardFont, @intCast(xoff), @bitCast(yoff1), vmNormal, 1, 1);

    abi.fmtBufZ(tmpString[0..2560], "  x {s}/tick  ", .{@as([*:0]const u8, frontier_plotstat.radixProcess(&buff, frontier_plotstat.formatCore(@as(f64, tick_int_x_), @intCast(acc), false, &tmpBuf, 50)))});
    frontier_char_string.convertDigits(frontier_plotstat.smallE(&buff, tmpString), &outstr);
    _ = frontier_screen.showString(&outstr, &standardFont, @intCast(xoff), @bitCast(yoff2), vmNormal, 1, 1);
}

// ===========================================================================
// graph_text (DEFINED here -> pub export fn)
// ===========================================================================
pub export fn graph_text() callconv(.c) void {
    var ypos: u32 = @intCast(Y_POSITION_OF_REGISTER_T_LINE - 11 + 12 * 5 - 45);
    var ii: i16 = undefined;
    var ss: [100]u8 = undefined;
    var tt: [100]u8 = undefined;
    var tmpbuf: [PLOT_TMP_BUF_SIZE]u8 = undefined;
    var n: i32 = undefined;
    frontier_plotstat.grphNumFormatter(&ss, "(", @floatCast(x_max), 2, "");
    const ssw: u16 = @truncate(frontier_screen.showStringEnhanced(frontier_plotstat.padEquals(&tmpbuf, &ss), &standardFont, 0, 0, vmNormal, 0, 0, NO_compress, NO_raise, NO_Show, NO_Bold, NO_LF));
    frontier_plotstat.grphNumFormatter(&tt, frontier_plotstat.radixProcess(&tmpbuf, "#"), @floatCast(y_max), 2, ")");
    const ttw: u16 = @truncate(frontier_screen.showStringEnhanced(frontier_plotstat.padEquals(&tmpbuf, &tt), &standardFont, 0, 0, vmNormal, 0, 0, NO_compress, NO_raise, NO_Show, NO_Bold, NO_LF));
    ypos += 38;
    n = @bitCast(frontier_screen.showString(frontier_plotstat.padEquals(&tmpbuf, &ss), &standardFont, @bitCast(@as(i32, 160) - 3 - 2 - @as(i32, ssw) - @as(i32, ttw)), ypos, vmNormal, 0, 0));
    _ = frontier_screen.showString(frontier_plotstat.padEquals(&tmpbuf, &tt), &standardFont, @bitCast(n + 3), ypos, vmNormal, 0, 0);
    frontier_plotstat.grphNumFormatter(&ss, "(", @floatCast(x_min), 2, "");
    ypos += 19;
    n = @bitCast(frontier_screen.showString(frontier_plotstat.padEquals(&tmpbuf, &ss), &standardFont, 1, ypos, vmNormal, 0, 0));
    frontier_plotstat.grphNumFormatter(&ss, frontier_plotstat.radixProcess(&tmpbuf, "#"), @floatCast(y_min), 2, ")");
    _ = frontier_screen.showString(frontier_plotstat.padEquals(&tmpbuf, &ss), &standardFont, @bitCast(n + 3), ypos, vmNormal, 0, 0);
    ypos -%= 38;
    showGraphTickText1(tick_int_x, tick_int_y, 1, @bitCast(ypos), @bitCast(ypos -% 12), 3);
    ypos -%= 24;

    var minnx: u32 = undefined;
    var minny: u32 = undefined;
    minny = 0;
    minnx = @intCast(SCREEN_WIDTH - SCREEN_HEIGHT_GRAPH);
    tmpString[0] = 0; // If the axis is on the edge supress it, and label accordingly
    const axisdisp: u8 =
        (if (!(yzero == @as(u32, @intCast(SCREEN_HEIGHT_GRAPH - 1)) or yzero == minny)) @as(u8, 2) else 0) +
        (if (!(xzero == @as(u32, @intCast(SCREEN_WIDTH - 1)) or xzero == minnx)) @as(u8, 1) else 0);
    switch (axisdisp) {
        0 => {
            _ = strcpy(tmpString, "            ");
        },
        1 => {
            abi.fmtBufZ(tmpString[0..bufLen], "  y-axis x 0", .{});
        },
        2 => {
            abi.fmtBufZ(tmpString[0..bufLen], "  x-axis y 0", .{});
        },
        3 => {
            abi.fmtBufZ(tmpString[0..2560], "  axis 0{s}0 ", .{@as([*:0]const u8, frontier_plotstat.radixProcess(&tmpbuf, "."))});
        },
        else => {},
    }

    // Change to the small characters and fabricate a small = char.
    // (gt_outstr is graph_text's file-local `static char outstr[bufLen]`.)
    frontier_char_string.convertDigits(tmpString, &gt_outstr);

    ii = @bitCast(@as(u16, @truncate(frontier_screen.showString(&gt_outstr, &standardFont, 1, ypos, vmNormal, 1, 1))));
    if (tmpString[@intCast(stringByteLength(tmpString) - 1)] == '0') {
        const sp: i16 = 15;
        const yp: i16 = @truncate(@as(i32, @bitCast(ypos)));
        frontier_plotstat.plotline1(ii - 17, yp + 2 + sp, ii - 11, yp + 2 + sp);
        frontier_plotstat.plotline1(ii - 17, yp + 1 + sp, ii - 11, yp + 1 + sp);
        frontier_plotstat.plotline1(ii - 17, yp - 1 + sp, ii - 11, yp - 1 + sp);
        frontier_plotstat.plotline1(ii - 17, yp - 2 + sp, ii - 11, yp - 2 + sp);
    }
    ypos +%= 48 + 2 * 19;

    if (PLOT_INTG and !invalid_intg) {
        abi.fmtBufZ(tmpString[0..bufLen], "  Trapezoid integral", .{});
        _ = frontier_screen.showStringEnhanced(tmpString, &tinyFont, 1, ypos, vmNormal, 0, 0, NO_compress, NO_raise, DO_Show, DO_Bold, DO_LF);

        const yp: i16 = @truncate(@as(i32, @bitCast(ypos)));
        plotintbig(5, yp + 4 + 4 - 2 - 4);
        frontier_plotstat.plotrect(5 + 4 - 1, (yp + 4 + 4 - 2 + 2) - 1 - 4, 5 + 4 + 2, (yp + 4 + 4 - 2 + 2) + 2 - 4);
        ypos += 20;
    }

    if (PLOT_DIFF and !invalid_diff) {
        abi.fmtBufZ(tmpString[0..bufLen], "  Numerical slope", .{});
        _ = frontier_screen.showStringEnhanced(tmpString, &tinyFont, 1, ypos, vmNormal, 0, 0, NO_compress, NO_raise, DO_Show, DO_Bold, DO_LF);
        const yp: i16 = @truncate(@as(i32, @bitCast(ypos)));
        plotdeltabig(6, yp + 4 + 4 - 2 - 4);
        ypos += 20;
    }

    if (PLOT_RMS and !invalid_rms) {
        abi.fmtBufZ(tmpString[0..bufLen], "  Root Mean Square RMS", .{});
        _ = frontier_screen.showStringEnhanced(tmpString, &tinyFont, 1, ypos, vmNormal, 0, 0, NO_compress, NO_raise, DO_Show, DO_Bold, DO_LF);
        const yp: i16 = @truncate(@as(i32, @bitCast(ypos)));
        plotrms(6, yp + 4 + 4 - 2 - 3);
        frontier_plotstat.plotrect(6 - 1, (yp + 4 + 4 - 2) - 1 - 3, 6 + 2, (yp + 4 + 4 - 2) + 2 - 3);
        ypos += 20;
    }

    frontier_screen.force_refresh(timed);
}

// ===========================================================================
// graph_Include0
// ===========================================================================
pub export fn graph_Include0(mode: bool_t, statnum: u16) callconv(.c) void {
    // Check and correct if min and max is swapped
    if (x_min > 0.0 and x_min > x_max) {
        x_min = x_min - (-x_max + x_min) * 1.1;
    }
    if (x_min < 0.0 and x_min > x_max) {
        x_min = x_min + (-x_max + x_min) * 1.1;
    }

    // include the 0 axis
    if (getSystemFlag(FLAG_SHOWX)) {
        const r = plot_range_zero.includeZeroAxis(x_min, x_max);
        x_min = r.min;
        x_max = r.max;
    }
    if (getSystemFlag(FLAG_SHOWY)) {
        const r = plot_range_zero.includeZeroAxis(y_min, y_max);
        y_min = r.min;
        y_max = r.max;
    }

    // modify the draw range if the min == max
    var dx: f32 = x_max - x_min;
    var dy: f32 = y_max - y_min;
    if (dy == 0.0) {
        dy = 1.0;
        y_max = y_min + dy / 2.0;
        y_min = y_max - dy;
        dy = y_max - y_min;
    }
    if (dx == 0.0) {
        dx = 1.0;
        x_max = x_min + dx / 2.0;
        x_min = x_max - dx;
        dx = x_max - x_min;
    }

    // Calc zoom scales
    var plotzoomy: f32 = 1;
    var plotzoomx: f32 = 1;
    if (mode == PLOTSTAT) {
        // the ZOOM command from outside the PLOT mode only works for PLSTAT
        const histofactor: f32 = if (drawHistogram == 0) 1 else 1 / zoomfactor * ((@as(f32, @floatFromInt(statnum)) + 2.0) / (@as(f32, @floatFromInt(statnum)) - 1.0) - 1) / 2; // Create space on the sides of the graph for the wider histogram columns
        // C: PLOT_ZOOM * 0.75 is (int8 * double) -> double, narrowed to float at the arg.
        calculateZoomFactor(@floatCast(@as(f64, @floatFromInt(PLOT_ZOOM)) * 0.75), &plotzoomx);
        plotzoomy = if (drawHistogram == 1) 1 else plotzoomx;
        multiplyZoomFactors(plotzoomx, plotzoomy, histofactor, &x_min, &x_max, &y_min, &y_max, &dx, &dy);
        if (drawHistogram == 1) {
            y_min = 0;
        }
    } else { // mode != PLOTSTAT
        if (PLOT_ZMY != zoomOverride) {
            if (PLOT_ZMY == zoomOverride - 1 or PLOT_ZMY == zoomOverride + 1) {
                PLOT_ZMY = 0;
            } else if (PLOT_ZMY > zoomOverride + 1) {
                PLOT_ZMY = zoomRangeLo;
            } else if (PLOT_ZMY < zoomRangeLo) {
                PLOT_ZMY = zoomRangeHi;
            }
            // C: PLOT_ZMY * 0.55 is (int8 * double) -> double, narrowed to float at the arg.
            calculateZoomFactor(@floatCast(@as(f64, @floatFromInt(PLOT_ZMY)) * 0.55), &plotzoomy);
            multiplyZoomFactors(plotzoomx, plotzoomy, 1, &x_min, &x_max, &y_min, &y_max, &dx, &dy);
        } else {
            // PLOT_ZMY = 18, special case to allow Ylo Yhi
            // _LY _UY override only if ZOOM is not set, AND Yup and Ylo are not zero
            if (@abs(plotzoomx - 1) < 0.00001 and @abs(plotzoomy - 1) < 0.00001 and !(real34IsZero(REGISTER_REAL34_DATA(RESERVED_VARIABLE_LY)) and real34IsZero(REGISTER_REAL34_DATA(RESERVED_VARIABLE_UY)))) {
                y_min = @floatCast(frontier_register_value_conversions.convertRegisterToDouble(RESERVED_VARIABLE_LY));
                y_max = @floatCast(frontier_register_value_conversions.convertRegisterToDouble(RESERVED_VARIABLE_UY));
            } else {
                y_min = -10;
                y_max = 10;
            }
        }
    }

    // Cause scales to be the same
    if (getSystemFlag(FLAG_SCALE)) {
        // if y >> x, then y simply takes on the X range and can be increased using ZMY
        if (mode == PLOTSTAT) {
            x_min = fminf(x_min, y_min);
            x_max = fmaxf(x_max, y_max);
            y_min = x_min;
            y_max = x_max;
        } else { // new equal scale calculation to keep the graph centre of screen
            var dx2: f32 = @abs(x_max - x_min);
            var dy2: f32 = @abs(y_max - y_min);
            if (dx2 > 1e-10 and dy2 / dx2 > 100000) {
                y_min = x_min;
                y_max = x_max;
                dx2 = @abs(x_max - x_min);
                dy2 = @abs(y_max - y_min);
            } else {
                if (dx2 > dy2) {
                    dy2 = dx2;
                } else {
                    dx2 = dy2;
                }
            }
            x_min = (x_min + x_max) / 2 - dx2 / 2;
            x_max = x_min + dx2;
            y_min = (y_min + y_max) / 2 - dy2 / 2;
            y_max = y_min + dy2;
        }
    }
}

// ===========================================================================
// graph_plotmem
// ===========================================================================
pub export fn graph_plotmem() callconv(.c) void {
    currentKeyCode = 255;
    // SAVE_SPACE_DM42_13GRF_JM is NOT defined -> this whole body is LIVE.

    if (!reDraw) {
        frontier_screen.clearScreenGraphs(1, @intFromBool(clrTextArea), @intFromBool(!clrGraphArea));
        graph_text();
        return;
    } else {
        frontier_screen.clearScreenGraphs(2, @intFromBool(!clrTextArea), @intFromBool(clrGraphArea));
        reDraw = false; // draw now and block reDraw in the next round
    }

    // LOW_GRAPH_ACC IS defined -> change to SDIGS digit operation for graphs.
    ctxtReal34.digits = significantDigitsForScreen;
    ctxtReal39.digits = significantDigitsForScreen + 3;
    ctxtReal51.digits = significantDigitsForScreen + 3;
    ctxtReal75.digits = significantDigitsForScreen + 3;

    regStatsXY = findNamedVariable(&plotStatMx);
    var cnt: u16 = undefined;
    var ix: u16 = undefined;
    var statnum: u16 = undefined;
    var xo: i16 = undefined;
    var xn: i16 = undefined;
    var xN1: i16 = undefined;
    var yo: i16 = undefined;
    var yn: i16 = undefined;
    var yN0: i16 = 0;
    var yN1: i16 = 0;
    var x: f32 = undefined;
    var y: f32 = undefined;
    var sx: f32 = undefined;
    var sy: f32 = undefined;
    var ddx: f32 = FLoatingMax;
    var dxx: f32 = FLoatingMax;
    var dydx: f32 = FLoatingMax;
    var inty: f32 = 0;
    var inty_off: f32 = 0;
    var rmsy: f32 = 0;

    statnum = 0;

    if ((if (plotStatMx[0] == 'S') frontier_plotstat.statMxN() >= 2 else false) or (if (plotStatMx[0] == 'D') drawMxN() >= 2 else false)) {
        if (plotStatMx[0] == 'S') {
            statnum = @intCast(frontier_plotstat.statMxN());
        } else {
            statnum = @intCast(drawMxN());
        }
    }

    if (statnum >= 2) {
        // GRAPH SETUP
        roundedTicks = true;
        frontier_plotstat.graph_axis(); // Draw the axis on any uncontrolled scale to start.
        if (PLOT_AXIS) {
            graph_text();
        }

        if (getSystemFlag(FLAG_VECT) or getSystemFlag(FLAG_NVECT)) {
            plotmode = _VECT;
        } else {
            plotmode = _SCAT;
        }

        if (PLOT_INTG) {
            rmsy = @abs(frontier_plotstat.grf_y(0));
            ix = 0;
            while (ix < statnum) : (ix += 1) {
                rmsy = @sqrt((rmsy * rmsy * @as(f32, @floatFromInt(ix)) + frontier_plotstat.grf_y(@intCast(ix)) * frontier_plotstat.grf_y(@intCast(ix))) / (@as(f32, @floatFromInt(ix)) + 1.0));
            }
            inty_off = rmsy;
        }

        // AUTOSCALE
        x_min = FLoatingMax;
        x_max = FLoatingMin;
        y_min = FLoatingMax;
        y_max = FLoatingMin;

        if (plotmode != _VECT) {
            invalid_intg = false; // integral scale
            invalid_diff = false; // Differential dydx scale
            invalid_rms = false; // RMSy

            // ###### SCALING LOOP DIFF INTG RMS ######
            if (PLOT_DIFF or PLOT_INTG or PLOT_RMS) {
                inty = inty_off; // integral starting constant co-incides with graph
                if (PLOT_RMS) {
                    rmsy = @abs(frontier_plotstat.grf_y(0));
                }

                ix = 0;
                while (ix < statnum) : (ix += 1) {
                    if (ix != 0) {
                        ddx = frontier_plotstat.grf_x(@intCast(ix)) - frontier_plotstat.grf_x(@intCast(ix - 1)); // used in DIFF and INT
                        if (ddx <= 0) { // Cannot get slope or area if x is not growing positively
                            x_min = FLoatingMax;
                            x_max = FLoatingMin;
                            y_min = FLoatingMax;
                            y_max = FLoatingMin;
                            invalid_diff = true;
                            invalid_intg = true;
                            invalid_rms = true;
                            break;
                        } else {
                            if (frontier_plotstat.grf_x(@intCast(ix)) < x_min) {
                                x_min = frontier_plotstat.grf_x(@intCast(ix));
                            }
                            if (frontier_plotstat.grf_x(@intCast(ix)) > x_max) {
                                x_max = frontier_plotstat.grf_x(@intCast(ix));
                            }
                            if (PLOT_DIFF) {
                                // Differential
                                if (ddx != 0) {
                                    if (ix == 1) { // only two samples available
                                        dydx = (frontier_plotstat.grf_y(@intCast(ix)) - frontier_plotstat.grf_y(@intCast(ix - 1))) / ddx;
                                    } else if (ix >= 2) { // three samples available 0 1 2
                                        dydx = @floatCast((@as(f64, frontier_plotstat.grf_y(@intCast(ix - 2))) - 4.0 * @as(f64, frontier_plotstat.grf_y(@intCast(ix - 1))) + 3.0 * @as(f64, frontier_plotstat.grf_y(@intCast(ix)))) / 2.0 / @as(f64, ddx));
                                    }
                                } else {
                                    dydx = FLoatingMax;
                                }

                                if (dydx < y_min) {
                                    y_min = dydx;
                                }
                                if (dydx > y_max) {
                                    y_max = dydx;
                                }
                            }
                            if (PLOT_INTG) {
                                inty = inty + (frontier_plotstat.grf_y(@intCast(ix)) + frontier_plotstat.grf_y(@intCast(ix - 1))) / 2 * ddx;
                                if (inty < y_min) {
                                    y_min = inty;
                                }
                                if (inty > y_max) {
                                    y_max = inty;
                                }
                            }
                            if (PLOT_RMS) {
                                rmsy = @sqrt((rmsy * rmsy * @as(f32, @floatFromInt(ix)) + frontier_plotstat.grf_y(@intCast(ix)) * frontier_plotstat.grf_y(@intCast(ix))) / (@as(f32, @floatFromInt(ix)) + 1.0));
                                if (rmsy < y_min) {
                                    y_min = rmsy;
                                }
                                if (rmsy > y_max) {
                                    y_max = rmsy;
                                }
                            }
                        }
                    }
                    if (frontier_addons.exitKeyWaiting() != 0) {
                        return;
                    }
                }
            }
            // ###### end scaling loop ######

            // ###### SCALING LOOP ######
            var y_maxcnt: u16 = 2;
            var y_mincnt: u16 = 2;
            var a0: f32 = 0;
            var a1: f32 = 0;
            var a2: f32 = 0;
            var a3: f32 = 0;
            var a4: f32 = 0;
            var a5: f32 = 0;
            var a6: f32 = 0;
            var a7: f32 = 0;
            var a8: f32 = 0;
            var aa: f32 = 1;

            var scaleRmsy: f32 = 0;

            if (getSystemFlag(FLAG_PBOX) or getSystemFlag(FLAG_PLINE) or getSystemFlag(FLAG_PCROS) or getSystemFlag(FLAG_PPLUS) or !(PLOT_DIFF or PLOT_INTG)) {
                // pre-loop to cover trivial cases of symmetrical axis
                cnt = 0;
                while (cnt < statnum) : (cnt += 1) {
                    if (frontier_plotstat.grf_x(@intCast(cnt)) < x_min) {
                        x_min = frontier_plotstat.grf_x(@intCast(cnt));
                    }
                    if (frontier_plotstat.grf_x(@intCast(cnt)) > x_max) {
                        x_max = frontier_plotstat.grf_x(@intCast(cnt));
                    }
                    if (frontier_plotstat.grf_y(@intCast(cnt)) < y_min) {
                        y_min = frontier_plotstat.grf_y(@intCast(cnt));
                    }
                    if (frontier_plotstat.grf_y(@intCast(cnt)) > y_max) {
                        y_max = frontier_plotstat.grf_y(@intCast(cnt));
                    }
                    scaleRmsy = @sqrt((scaleRmsy * scaleRmsy * @as(f32, @floatFromInt(cnt)) + frontier_plotstat.grf_y(@intCast(cnt)) * frontier_plotstat.grf_y(@intCast(cnt))) / (@as(f32, @floatFromInt(cnt)) + 1.0));
                }

                // pre-loop to cover trivial quasi symmetrical axis
                if (y_max > 0 and y_min < 0 and (y_max > 4 * scaleRmsy)) { // force the RMS if large peaks occur
                    y_max = scaleRmsy;
                } else if (y_max > 0 and y_min < 0 and (-y_min > 4 * scaleRmsy)) {
                    y_min = -scaleRmsy;
                } else if (y_max > 0 and y_min < 0 and (y_max > -y_min) and (y_max / y_min < 1.2)) { // make x-axis sit in the middle if close enough
                    y_min = -y_max;
                } else if (y_max > 0 and y_min < 0 and (y_max < -y_min) and (y_min / y_max < 1.2)) {
                    y_max = -y_min;
                }

                {
                    cnt = 0;
                    while (cnt < statnum) : (cnt += 1) {
                        a8 = a7;
                        a7 = a6;
                        a6 = a5;
                        a5 = a4;
                        a4 = a3;
                        a3 = a2;
                        a2 = a1;
                        a1 = a0;
                        a0 = frontier_plotstat.grf_y(@intCast(cnt));
                        if (cnt < 8) {
                            aa = a0;
                        } else {
                            aa = a8 * 0.2 + a7 * 0.2 + a6 * 0.1 + a5 * 0.1 + a4 * 0.1 + a3 * 0.1 + a2 * 0.1 + a1 * 0.1;
                        }
                        if (aa < y_min) {
                            y_mincnt += 1;
                            if (@abs(aa / y_min) < 4) {
                                if (aa < y_min) {
                                    y_min = aa;
                                }
                                y_mincnt = 0;
                            } else if (y_mincnt == 3) {
                                y_min = aa;
                                y_mincnt = 0;
                            }
                        } else {
                            y_mincnt = 0;
                        }

                        if (aa > y_max) {
                            y_maxcnt += 1;
                            if (@abs(aa / y_max) < 4) {
                                if (aa > y_max) {
                                    y_max = aa;
                                }
                                y_maxcnt = 0;
                            } else if (y_maxcnt == 3) {
                                y_max = aa;
                                y_maxcnt = 0;
                            }
                        } else {
                            y_maxcnt = 0;
                        }

                        if (frontier_addons.exitKeyWaiting() != 0) {
                            return;
                        }
                    }
                }
            }
        } else { // VECTOR
            sx = 0;
            sy = 0;
            cnt = 0;
            while (cnt < statnum) : (cnt += 1) { // ### Note XXX E- will stuff up statnum!
                sx = sx + (if (!getSystemFlag(FLAG_NVECT)) frontier_plotstat.grf_x(@intCast(cnt)) else frontier_plotstat.grf_y(@intCast(cnt)));
                sy = sy + (if (!getSystemFlag(FLAG_NVECT)) frontier_plotstat.grf_y(@intCast(cnt)) else frontier_plotstat.grf_x(@intCast(cnt)));
                if (sx < x_min) {
                    x_min = sx;
                }
                if (sx > x_max) {
                    x_max = sx;
                }
                if (sy < y_min) {
                    y_min = sy;
                }
                if (sy > y_max) {
                    y_max = sy;
                }
                if (frontier_addons.exitKeyWaiting() != 0) {
                    return;
                }
            }
        }
        // ###### end scaling loop ######

        graph_Include0(!PLOTSTAT, 0);

        roundedTicks = true;
        frontier_plotstat.graph_axis();
        if (PLOT_AXIS) {
            graph_text();
        }

        if (plotmode != _VECT) {
            yn = frontier_plotstat.screen_window_y(y_min, frontier_plotstat.grf_y(0), y_max);
            xn = frontier_plotstat.screen_window_x(x_min, frontier_plotstat.grf_x(0), x_max);
            xN1 = xn;
            yN1 = yn;
        } else {
            yn = frontier_plotstat.screen_window_y(y_min, 0, y_max);
            xn = frontier_plotstat.screen_window_x(x_min, 0, x_max);
            xN1 = xn;
            yN1 = yn;
        }

        sx = 0;
        sy = 0;
        // GRAPH
        ix = 0;
        inty = inty_off; // integral starting constant co-incides with graph
        rmsy = 0;
        if (PLOT_RMS) {
            rmsy = @abs(frontier_plotstat.grf_y(0));
        }

        // ###### MAIN GRAPH LOOP ######
        const plotInCurves: bool_t = getSystemFlag(FLAG_PCURVE);

        if (plotInCurves) {
            frontier_plotstat.plotline3(0, 0, 0, 0, true, false); // reset
        }
        ix = 0;
        while (ix < statnum) : (ix += 1) {
            if (plotmode != _VECT) {
                x = 0;
                y = 0;

                if (ix != 0 and ((PLOT_DIFF and !invalid_diff) or (PLOT_INTG and !invalid_intg) or (PLOT_RMS and !invalid_rms))) {
                    ddx = frontier_plotstat.grf_x(@intCast(ix)) - frontier_plotstat.grf_x(@intCast(ix - 1));
                    if (PLOT_DIFF and ddx != 0) {
                        if (ix == 1 or (@abs(((frontier_plotstat.grf_x(@intCast(ix)) - frontier_plotstat.grf_x(@intCast(ix - 1))) / (frontier_plotstat.grf_x(@intCast(ix - 1)) - frontier_plotstat.grf_x(@intCast(ix - 2)))) - 1) > 0.0001)) { // only two samples available
                            dydx = (frontier_plotstat.grf_y(@intCast(ix)) - frontier_plotstat.grf_y(@intCast(ix - 1))) / ddx; // Differential
                            dxx = (frontier_plotstat.grf_x(@intCast(ix)) + frontier_plotstat.grf_x(@intCast(ix - 1))) / 2;
                        } else { // ix >= 2 three samples available 0 1 2
                            dydx = @floatCast((@as(f64, frontier_plotstat.grf_y(@intCast(ix - 2))) - 4.0 * @as(f64, frontier_plotstat.grf_y(@intCast(ix - 1))) + 3.0 * @as(f64, frontier_plotstat.grf_y(@intCast(ix)))) / 2.0 / @as(f64, ddx));
                            dxx = frontier_plotstat.grf_x(@intCast(ix));
                        }
                    } else {
                        dydx = FLoatingMax;
                    }

                    if (PLOT_RMS) {
                        rmsy = @sqrt((rmsy * rmsy * @as(f32, @floatFromInt(ix)) + frontier_plotstat.grf_y(@intCast(ix)) * frontier_plotstat.grf_y(@intCast(ix))) / (@as(f32, @floatFromInt(ix)) + 1.0));
                    }
                    if (PLOT_INTG) {
                        inty = inty + (frontier_plotstat.grf_y(@intCast(ix)) + frontier_plotstat.grf_y(@intCast(ix - 1))) / 2 * ddx;
                    }
                }

                x = frontier_plotstat.grf_x(@intCast(ix));
                y = frontier_plotstat.grf_y(@intCast(ix));
            } else { // _VECT
                sx = sx + (if (!getSystemFlag(FLAG_NVECT)) frontier_plotstat.grf_x(@intCast(ix)) else frontier_plotstat.grf_y(@intCast(ix)));
                sy = sy + (if (!getSystemFlag(FLAG_NVECT)) frontier_plotstat.grf_y(@intCast(ix)) else frontier_plotstat.grf_x(@intCast(ix)));
                x = sx;
                y = sy;
            }
            xo = xN1;
            yo = yN1;
            yN0 = gpm_prev_y_unclipped;

            xN1 = frontier_plotstat.screen_window_x(x_min, x, x_max);
            yN1 = frontier_plotstat.screen_window_y_nolimit(y_min, y, y_max);
            const current_y_unclipped: i16 = yN1;

            if (ix == 0) {
                xo = xN1;
                yo = yN1;
                yN0 = yN1;
                gpm_prev_y_unclipped = yN1; // Initialize for next iteration
                continue; // Skip clipping for first point
            }

            var minN_y: i16 = undefined;
            var minN_x: i16 = undefined;
            minN_y = 0;
            minN_x = SCREEN_WIDTH - SCREEN_HEIGHT_GRAPH;

            const bothOutOfScreen01: bool_t = ((yN1 >= SCREEN_HEIGHT_GRAPH) and (yN0 >= SCREEN_HEIGHT_GRAPH)) or ((yN1 < minN_y) and (yN0 < minN_y));
            const outOfScreen1: bool_t = (yN1 >= SCREEN_HEIGHT_GRAPH or yN1 < minN_y);
            const outOfScreen0: bool_t = (yN0 >= SCREEN_HEIGHT_GRAPH or yN0 < minN_y);

            if (!bothOutOfScreen01) {
                // Coming in from bottom - BOTH positive and negative slopes
                if (outOfScreen0 and !outOfScreen1 and yN0 >= SCREEN_HEIGHT_GRAPH) {
                    const dY: i16 = @intCast(@abs(@as(i32, SCREEN_HEIGHT_GRAPH) - 1 - @as(i32, yN0)));
                    if (yN1 != yN0) {
                        const dxN: f32 = @abs((@as(f32, @floatFromInt(dY)) * @as(f32, @floatFromInt(@as(i32, xN1) - @as(i32, xo)))) / @as(f32, @floatFromInt(@as(i32, yN1) - @as(i32, yN0))));
                        xo = @intCast(@as(i32, xo) + @as(i32, fToI16(dxN)));
                        yN0 = SCREEN_HEIGHT_GRAPH - 1;
                        yo = yN0;
                    }
                }
                // Coming in from top - BOTH positive and negative slopes
                else if (outOfScreen0 and !outOfScreen1 and yN0 < minN_y) {
                    const dY: i16 = @intCast(@abs(@as(i32, yN0) - @as(i32, minN_y)));
                    if (yN1 != yN0) {
                        const dxN: f32 = @abs((@as(f32, @floatFromInt(dY)) * @as(f32, @floatFromInt(@as(i32, xN1) - @as(i32, xo)))) / @as(f32, @floatFromInt(@as(i32, yN1) - @as(i32, yN0))));
                        xo = @intCast(@as(i32, xo) + @as(i32, fToI16(dxN)));
                        yN0 = minN_y;
                        yo = yN0;
                    }
                }
            }

            // exceeding the negative y-axis part or the bottom of the screen
            if ((yN1 > yN0 and xN1 > xo and yN1 >= SCREEN_HEIGHT_GRAPH and !bothOutOfScreen01 and outOfScreen1 and !outOfScreen0) or
                (yN1 < yN0 and xN1 > xo and yN0 >= SCREEN_HEIGHT_GRAPH and !bothOutOfScreen01 and !outOfScreen1 and outOfScreen0))
            {
                const dY: i16 = @intCast(@abs(@as(i32, SCREEN_HEIGHT_GRAPH) - 1 - @as(i32, yN0)));
                if (yN1 == yN0) {
                    continue; // Skip horizontal lines
                }
                const dxN: f32 = @abs((@as(f32, @floatFromInt(dY)) * @as(f32, @floatFromInt(@as(i32, xN1) - @as(i32, xo)))) / @as(f32, @floatFromInt(@as(i32, yN1) - @as(i32, yN0))));
                xN1 = @intCast(@as(i32, xo) + @as(i32, @intFromFloat(dxN + 0.5)));
                yN1 = SCREEN_HEIGHT_GRAPH - 1;
            }
            // exceeding the positive y-axis part or the top of the screen
            else if ((yN1 < yN0 and xN1 > xo and yN1 < minN_y and !bothOutOfScreen01 and outOfScreen1 and !outOfScreen0) or
                (yN1 > yN0 and xN1 > xo and yN0 < minN_y and !bothOutOfScreen01 and !outOfScreen1 and outOfScreen0))
            {
                const dY: i16 = @intCast(@abs(@as(i32, yN0) - @as(i32, minN_y)));
                if (yN1 == yN0) {
                    continue; // Skip horizontal lines
                }
                const dxN: f32 = @abs((@as(f32, @floatFromInt(dY)) * @as(f32, @floatFromInt(@as(i32, xN1) - @as(i32, xo)))) / @as(f32, @floatFromInt(@as(i32, yN1) - @as(i32, yN0))));
                xN1 = @intCast(@as(i32, xo) + @as(i32, @intFromFloat(dxN + 0.5)));
                yN1 = minN_y;
            }

            if ((xN1 < SCREEN_WIDTH_GRAPH and xN1 >= minN_x and yN1 < SCREEN_HEIGHT_GRAPH and yN1 >= minN_y)) {
                yn = yN1;
                xn = xN1;

                if (plotmode != _VECT) {
                    frontier_plotstat.plotPointGeneric(xn, yn, xo, yo, getSystemFlag(FLAG_PCROS), // cross
                        false, // fatbox
                        getSystemFlag(FLAG_PBOX), // box
                        getSystemFlag(FLAG_PPLUS), // plus
                        false // line
                    );

                    if (PLOT_DIFF and !invalid_diff and ix != 0) {
                        plotdelta(frontier_plotstat.screen_window_x(x_min, dxx, x_max), frontier_plotstat.screen_window_y(y_min, dydx, y_max));
                    }

                    if (PLOT_RMS and !invalid_rms and ix != 0) {
                        plotrms(frontier_plotstat.screen_window_x(x_min, x - ddx / 2, x_max), frontier_plotstat.screen_window_y(y_min, rmsy, y_max));
                    }

                    if (PLOT_INTG and !invalid_intg and ix != 0) {
                        const xN0: i16 = frontier_plotstat.screen_window_x(x_min, frontier_plotstat.grf_x(@intCast(ix - 1)), x_max);
                        const yNintg: i16 = frontier_plotstat.screen_window_y(y_min, inty, y_max);
                        const xAvg: i16 = @intCast((@as(i32, xN0) + @as(i32, xN1)) >> 1);

                        // Upstream master fixed the precedence to abs((int16_t)(xN1-xN0)) >= 6
                        // (absolute pixel gap), not the old (xN1-xN0) >= 6.
                        if (@abs(@as(i32, xN1) - @as(i32, xN0)) >= 6) {
                            plotint(xAvg, yNintg);
                        } else {
                            frontier_plotstat.plotrect(xAvg - 1, yNintg - 1, xAvg + 1, yNintg + 1);
                        }

                        // Upstream master fixed the precedence to abs((int16_t)(xN1-xN0)) >= 6/4
                        // (absolute pixel gap), not the old (xN1-xN0) >= 6/4.
                        if (@abs(@as(i32, xN1) - @as(i32, xN0)) >= 6) {
                            frontier_plotstat.plotline1(xN1, yNintg, xAvg + 2, yNintg);
                            frontier_plotstat.plotline1(xAvg - 2, yNintg, xN0, yNintg);
                        } else if (@abs(@as(i32, xN1) - @as(i32, xN0)) >= 4) {
                            frontier_plotstat.plotline1(xN1, yNintg, xAvg + 2, yNintg);
                            frontier_plotstat.plotline1(xAvg - 2, yNintg, xN0, yNintg);
                        }

                        if (PLOT_SHADE) {
                            const yNoff: i16 = frontier_plotstat.screen_window_y(y_min, 0, y_max);
                            frontier_plotstat.plotrect(xN0, yN0, xN1, yN1);
                            frontier_plotstat.plotrect(xN0, yNoff, xN1, yN0);
                            if (@abs(@as(i32, xN1) - @as(i32, xN0)) >= 6) {
                                frontier_plotstat.plotline1(xN0, yN0, xN1, yN1);
                            }
                        }
                    }
                } else { // _VECT
                    plotarrow(xo, yo, xn, yn);
                }

                if (getSystemFlag(FLAG_PLINE)) {
                    if (plotInCurves) {
                        frontier_plotstat.plotline3(xo, yo, xn, yn, false, false);
                    } else {
                        frontier_plotstat.plotline2(xo, yo, xn, yn);
                    }
                }
            }
            // else branch is PC_BUILD-only diagnostic printf -> omitted.

            if (frontier_addons.exitKeyWaiting() != 0) {
                return;
            }

            gpm_prev_y_unclipped = current_y_unclipped;
        }
        // ###### end main graph loop ######
        if (getSystemFlag(FLAG_PLINE) and plotInCurves) {
            frontier_plotstat.plotline3(0, 0, 0, 0, false, true); // last line segment
        }
    } else {
        frontier_error.displayCalcErrorMessage(ERROR_NO_SUMMATION_DATA, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            if (comptime !dmcp_build) {
                abi.fmtBufZ(errorMessage[0..512], "There is no statistical data available!", .{});
                moreInfoOnError("In function graph_plotmem:", errorMessage, null, null);
            }
        }
    }

    // LOW_GRAPH_ACC IS defined -> change back to normal operation for graphs.
    ctxtReal34.digits = 34;
    ctxtReal39.digits = 39;
    ctxtReal51.digits = 51;
    ctxtReal75.digits = 75;
}

// ===========================================================================
// fnStatList
// ===========================================================================
pub export fn fnStatList() callconv(.c) void {
    var tmpstr1: [100]u8 = undefined;
    var tmpstr2: [100]u8 = undefined;
    var ix: i16 = undefined;
    var ixx: i16 = undefined;
    var statnum: i16 = undefined;

    clearScreen(); // clearScreen(1) macro
    frontier_status_bar.refreshStatusBar();

    if (regStatsXY != INVALID_VARIABLE and (if (plotStatMx[0] == 'D') drawMxN() >= 1 else false)) {
        statnum = @intCast(drawMxN());
        frontier_stats.fnStatSum(0);
        abi.fmtBufZ(tmpString[0..2560], "Graph data: N = {d}", .{@as(i32, statnum)});
        frontier_graph_text.print_linestr(tmpString, true);

        if (ListXYposition > 0) {
            ListXYposition = 0;
        } else if (statnum - (minI(10, statnum) - 1) - 1 + ListXYposition < 0) {
            ListXYposition = -(statnum - (minI(10, statnum) - 1) - 1);
        }

        ix = 0;
        while (ix < minI(10, statnum)) : (ix += 1) {
            ixx = statnum - ix - 1 + ListXYposition;
            var tmpBuf: [100]u8 = undefined;

            abi.fmtBufZ(&tmpstr1, "[{d}] x{s}{s}, ", .{ @as(c_int, ixx + 1), @as([*:0]const u8, @as([*:0]const u8, "")), @as([*:0]const u8, frontier_plotstat.formatCore(@as(f64, frontier_plotstat.grf_x(@intCast(ixx))), 10, false, &tmpBuf, 150)) });
            abi.fmtBufZ(&tmpstr2, "y{s}{s}, ", .{ @as([*:0]const u8, @as([*:0]const u8, "")), @as([*:0]const u8, frontier_plotstat.formatCore(@as(f64, frontier_plotstat.grf_y(@intCast(ixx))), 10, false, &tmpBuf, 150)) });
            _ = strcat(&tmpstr1, &tmpstr2);

            frontier_graph_text.print_numberstr(&tmpstr1, false);
        }
    }
}
// min(a,b) macro for i16 operands (fnStatList).
inline fn minI(a: i16, b: i16) i16 {
    return if (a < b) a else b;
}
