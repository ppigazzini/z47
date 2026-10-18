const std = @import("std");
const abi = @import("abi");
const display_format = @import("shell/display/display_format.zig");
const frontend_settings = @import("shell/frontend_settings.zig");
const matrix_editor_entry = @import("shell/matrix_editor/matrix_editor_entry.zig");
const matrix_goto_grow = @import("shell/matrix_editor/matrix_goto_grow.zig");
const matrix_lifecycle = @import("shell/matrix_editor/matrix_lifecycle.zig");
const matrix_mutation = @import("shell/matrix_editor/matrix_mutation.zig");
const matrix_nav = @import("shell/matrix_editor/matrix_nav.zig");
const print_register = @import("shell/print/print_register.zig");
const cauchy = @import("shell/distributions/cauchy.zig");
const weibull = @import("shell/distributions/weibull.zig");
const logistic = @import("shell/distributions/logistic.zig");
const exponential = @import("shell/distributions/exponential.zig");
const pareto = @import("shell/distributions/pareto.zig");
const uniform = @import("shell/distributions/uniform.zig");
const gev = @import("shell/distributions/gev.zig");
const geometric = @import("shell/distributions/geometric.zig");
const poisson = @import("shell/distributions/poisson.zig");
const binomial = @import("shell/distributions/binomial.zig");
const neg_binom = @import("shell/distributions/neg_binom.zig");
const hyper = @import("shell/distributions/hyper.zig");
const chi2 = @import("shell/distributions/chi2.zig");
const normal = @import("shell/distributions/normal.zig");
const f_dist = @import("shell/distributions/f.zig");
const t_dist = @import("shell/distributions/t.zig");

// Per-package distribution strip flags, injected by the build (default: keep
// everything). They are the inverses of upstream's OPTION_DIST_B (cauchy/chi2/
// expo/logistic/t/weibull) and OPTION_DIST_D (gev/pareto/uniform), so flash-limited
// firmware packages compile those distribution owners out of the shared object.
const dr = @import("shell/distributions/distribution_runtime.zig");
const frontier_build_options = @import("frontier_build_options");
const strip_16: bool = frontier_build_options.strip_16;
const strip_17: bool = frontier_build_options.strip_17;
const strip_17b: bool = frontier_build_options.strip_17b;
const strip_17c: bool = frontier_build_options.strip_17c;
const dmcp_build: bool = frontier_build_options.dmcp_build;

extern fn printf(fmt: [*:0]const u8, ...) c_int;

comptime {
    // These owners hold the dispatch wrappers that used to live in this root. The
    // root's own bodies were what pulled them into the frontier object; with the
    // wrappers moved to them, nothing references them and Zig would not analyse
    // them at all -- their exports would vanish from the link. A root force-imports
    // its members; it does not export on their behalf.
    _ = @import("shell/clear_all.zig");
    _ = @import("shell/matrix_editor/matrix_editor_refresh.zig");
    _ = @import("shell/plot/plot_regression.zig");
    _ = @import("shell/print/print_all_regs.zig");
    _ = @import("shell/program/keys_management.zig");
    _ = @import("shell/program/program_clear.zig");
    // These owners hold the dispatch wrappers that used to live in this root.
    // The root's own bodies were what pulled them into the frontier object; with
    // the wrappers moved to them, nothing references them any more and Zig would
    // not analyse them at all -- their exports would silently vanish from the
    // link. A root force-imports its members; it does not export on their behalf.
    _ = @import("shell/free_list.zig");
    _ = @import("core/text/fonts.zig");
    _ = @import("shell/generated/frontier_martel_fonts.zig");
    _ = @import("shell/generated/frontier_printer_font8.zig");
    _ = @import("shell/convert/conversion_units.zig");
    _ = @import("shell/convert/conversion_angles.zig");
    _ = @import("shell/register_value_conversions.zig");
    _ = @import("shell/convert/date_time.zig");
    _ = @import("shell/convert/integers.zig");
    _ = @import("shell/display/sort.zig");
    _ = @import("shell/error.zig");
    _ = @import("shell/program/lbl_gto_xeq.zig");
    _ = @import("shell/display/text/string_funcs.zig");
    _ = @import("shell/recall.zig");
    _ = @import("shell/convert/fractions.zig");
    _ = @import("shell/store.zig");
    _ = @import("shell/stats.zig");
    _ = @import("shell/program/clcvar.zig");
    _ = @import("shell/program/next_step.zig");
    _ = @import("shell/program/decode.zig");
    _ = @import("shell/plot/curve_fitting.zig");
    _ = @import("shell/display/input.zig");
    _ = @import("shell/extensions/jm.zig");
    _ = @import("shell/browsers/flag_browser.zig");
    _ = @import("shell/calc_mode.zig");
    _ = @import("shell/browsers/register_browser.zig");
    _ = @import("shell/program/programmable_menu.zig");
    _ = @import("shell/browsers/font_browser.zig");
    _ = @import("shell/browsers/asn_browser.zig");
    _ = @import("shell/extensions/textfiles.zig");
    _ = @import("shell/extensions/xeqm.zig");
    _ = @import("shell/display/screen.zig");
    _ = @import("shell/display/screen_snap.zig");
    _ = @import("shell/extensions/addons.zig");
    _ = @import("shell/elec.zig");
    _ = @import("shell/display/items/items.zig");
    _ = @import("shell/display/softmenus/softmenus.zig");
    _ = @import("shell/display/display.zig");
    _ = @import("shell/c47.zig");
    _ = @import("shell/display/bufferize.zig");
    _ = @import("shell/print/print.zig");
    _ = @import("shell/config.zig");
    _ = @import("shell/plot/plotstat.zig");
    _ = @import("shell/matrix_editor/matrix_editor.zig");
    _ = @import("shell/plot/graphs.zig");
    _ = @import("shell/program/manage.zig");
    _ = @import("shell/program/structured.zig");
    _ = @import("shell/input/tam.zig");
    _ = @import("shell/input/assign.zig");
    _ = @import("shell/display/statusbar/status_bar.zig");
    _ = @import("shell/display/text/char_string.zig");
    _ = @import("shell/plot/graph_text.zig");
    _ = @import("shell/timer.zig");
    _ = @import("shell/extensions/radio_button_catalog.zig");
    _ = @import("shell/debug.zig");
}
const printer_control = @import("shell/print/printer_control.zig");
const plot_stat = @import("shell/plot/plot_stat.zig");
const print_all_items = @import("shell/print/print_all_items.zig");
const print_user = @import("shell/print/print_user.zig");
const frontier_addons = @import("shell/extensions/addons.zig");
const frontier_assign = @import("shell/input/assign.zig");
const frontier_config = @import("shell/config.zig");
const frontier_curve_fitting = @import("shell/plot/curve_fitting.zig");
const frontier_error = @import("shell/error.zig");
const frontier_graph_text = @import("shell/plot/graph_text.zig");
const frontier_items = @import("shell/display/items/items.zig");
const frontier_manage = @import("shell/program/manage.zig");
const frontier_matrix_editor = @import("shell/matrix_editor/matrix_editor.zig");
const frontier_plotstat = @import("shell/plot/plotstat.zig");
const frontier_print = @import("shell/print/print.zig");
const frontier_radio_button_catalog = @import("shell/extensions/radio_button_catalog.zig");
const frontier_screen = @import("shell/display/screen.zig");
const register_data_type = @import("shell/register_data_type.zig");
const frontier_screen_snap = @import("shell/display/screen_snap.zig");
const frontier_softmenus = @import("shell/display/softmenus/softmenus.zig");
const frontier_stats = @import("shell/stats.zig");
const frontier_status_bar = @import("shell/display/statusbar/status_bar.zig");
const frontier_tam = @import("shell/input/tam.zig");
const frontier_textfiles = @import("shell/extensions/textfiles.zig");
fn bufPrintZ(buffer: []u8, comptime format: []const u8, args: anytype) ![:0]u8 {
    return std.mem.printSentinel(buffer, format, args, 0);
}

const DSP_MAX: u16 = 19;
const FLAG_FRACT: c_uint = 0x8007;
const FLAG_PROPFR: c_uint = 0x8008;
const FLAG_TRACE: c_uint = 0x8013;
const FLAG_PRTACT: c_uint = 0xc020;
const FLAG_INTING: c_uint = 0xc025;
const FLAG_SOLVING: c_uint = 0xc026;
const FLAG_ASLIFT: c_uint = 0xc023;
const FLAG_WRAPEND: c_uint = 0xc01a;
const FLAG_WRAPEDG: c_uint = 0xc03f;
const FLAG_FRCYC: c_uint = 0x8041;
const FLAG_IRFRAC: c_uint = 0x8047;
const FLAG_IRFRQ: c_uint = 0xc048;
const FLAG_PRTEN: u16 = 0x8067;
const FLAG_NORM: u16 = 0x8068;
const FLAG_SCALE: c_uint = 0x8052;
const FLAG_GROW: c_uint = 0x801d;
const FLAG_USER: u16 = 0x8014;
const FLAG_MYM_TRIPLE: u16 = 0x805f;
const FLAG_HOME_TRIPLE: u16 = 0x8060;

const SETTING_AMODE: c_int = 0x0080;
const SETTING_SINT_MODE: c_int = 0x0083;

const TI_VERSION: u8 = 10;
const TI_WHO: u8 = 11;
const TI_RESET: u8 = 8;
const TI_PRINT_COMPLETE: u8 = 136;
const TI_NO_INFO: u8 = 0;
const TI_DEL_ALL_PRGMS: u8 = 99;

const CM_NORMAL: u8 = 0;
const CM_AIM: u8 = 1;
const CM_MIM: u8 = 12;
const CM_PLOT_STAT: u8 = 8;
const CM_CONFIRMATION: u8 = 11;
const CM_GRAPH: u8 = 15;
const CM_NO_UNDO: u8 = 16;

const ERROR_NONE: u8 = 0;
const ERROR_OUT_OF_RANGE: u8 = 8;
const ERROR_OPERATION_UNDEFINED: u8 = 13;
const ERROR_INVALID_DATA_TYPE_FOR_OP: u8 = 24;
const ERROR_MATRIX_MISMATCH: u8 = 21;
const ERROR_NO_SUMMATION_DATA: u8 = 28;
const ERROR_PRINTING_DISABLED: u8 = 63;

const CONFIRMED: u16 = 9877;
const NOT_CONFIRMED: u16 = 9878;
const NOPARAM: u16 = 9876;
const INVALID_VARIABLE: u16 = 2199;

const USER_KRESET: u16 = 50;
const TO_USER: u16 = 29;
const FROM_USER: u16 = 30;
const USER_DM42: u16 = 45;
const USER_C47: u16 = 46;
const USER_ARESET: u16 = 48;
const USER_MRESET: u16 = 49;
const USER_HRESET: u16 = 58;
const USER_PRESET: u16 = 59;
const USER_R47f_g: u16 = 61;
const USER_R47bk_fg: u16 = 62;
const USER_R47fg_bk: u16 = 63;
const USER_R47fg_g: u16 = 64;
const DEC_FLAG: u16 = 1;
const ITM_RIBBON_C47: u16 = 2509;
const ITM_RIBBON_R47: u16 = 2511;
const ITM_M_GOTO_ROW: i16 = 992;
const ITM_ENTER: i16 = 35;
const ITM_CHS: i16 = 97;
const ITM_CONSTpi: i16 = 109;
const ITM_0: i16 = 540;
const ITM_1: i16 = 541;
const ITM_2: i16 = 542;
const ITM_3: i16 = 543;
const ITM_4: i16 = 544;
const ITM_5: i16 = 545;
const ITM_6: i16 = 546;
const ITM_7: i16 = 547;
const ITM_8: i16 = 548;
const ITM_9: i16 = 549;
const ITM_PERIOD: i16 = 820;
const ITM_EXPONENT: i16 = 990;
const ITM_CC: i16 = 1730;
const ITM_BACKSPACE: i16 = 1738;
const ITM_op_j_pol: i16 = 1795;
const ITM_op_j: i16 = 1830;
const ITM_END: u16 = 1458;
const ITM_FF: u16 = 112;
const MNU_SYSFL: i16 = 3128;
const MNU_HOME: i16 = 3070;
const MNU_PFN: i16 = 3095;
const MNU_MyMenu: i16 = 3090;

const FIRST_GLOBAL_REGISTER: u16 = 0;
const LAST_GLOBAL_REGISTER: u16 = 136; // = TEMP_REGISTER_2_SAVED_STATS (was 125 = LAST_SPARE_REGISTER)
const FIRST_NAMED_VARIABLE: u16 = 256;
const FIRST_LOCAL_REGISTER: u16 = 7000;

const REGISTER_X: i16 = 100;
const REGISTER_Y: i16 = 101;
const REGISTER_Z: i16 = 102;
const REGISTER_T: u16 = 103;
const REGISTER_D: u16 = 107;
const REGISTER_I: u16 = 109;
const REGISTER_J: u16 = 110;
const REGISTER_W: u16 = 125;

const ERR_REGISTER_LINE: i16 = REGISTER_Z;
const NIM_REGISTER_LINE: i16 = REGISTER_X;

const FLAG_SSIZE8: c_int = 0x8018;
const SCRUPD_AUTO: u8 = 0x00;
const SCRUPD_SKIP_STACK_ONE_TIME: u8 = 0x20;
const SCRUPD_SKIP_MENU_ONE_TIME: u8 = 0x40;

const TAM_BUFFER_LENGTH: usize = 56;

const PGM_STOPPED: u8 = 0;
const PGM_RUNNING: u8 = 1;
const PGM_WAITING: u8 = 2;
const PGM_SINGLE_STEP: u8 = 6;

const PRN_ALL: u16 = 0;
const PRN_STK: u16 = 1;
const PRN_REGS: u16 = 2;
const PRN_GLOBALr: u16 = 3;
const PRN_LOCALr: u16 = 4;
const PRN_NAMEDr: u16 = 5;
const PRN_Xr: u16 = 6;
const PRN_XYr: u16 = 7;
const PRN_TMP: u16 = 8;

const PLOT_ORTHOF: u16 = 0;
const PLOT_NXT: u16 = 1;
const PLOT_REV: u16 = 2;
const PLOT_LR: u16 = 3;
const PLOT_START: u16 = 4;
const PLOT_NOTHING: u16 = 5;
const H_PLOT: u16 = 7;
const H_NORM: u16 = 8;

const CF_GAUSS_FITTING: u16 = 256;
const CF_ORTHOGONAL_FITTING: u16 = 512;

const TEMP_REGISTER_1: u16 = 135;

const LINE_FULL: c_int = 0;
const LINE_LEFT: c_int = 1;
const LINE_RIGHT: c_int = 2;

const MNU_GAP_L: i16 = 3064;
const MNU_GAP_RX: i16 = 3066;
const MNU_GAP_R: i16 = 3065;
const MNU_PLOT_SCATR: i16 = 3101;
const MNU_PLOT_ASSESS: i16 = 3099;
const MNU_HPLOT: i16 = 3071;

const PROFF: u16 = 0;
const PRON: u16 = 1;
const MAN: u16 = 0;
const NORM: u16 = 1;
const TRACE: u16 = 2;
const STRACE: u16 = 3;

const PRINT_BYTE: c_int = 0;
const PRINT_CHAR: c_int = 1;
const PRINT_TAB: c_int = 2;
const PRINT_ALPHA: c_int = 3;

const DF_DMX_MIN: i16 = 99;
const DF_HIDE_MIN: i16 = 12;

const DF_ALL: u8 = 0;
const DF_FIX: u8 = 1;
const DF_SCI: u8 = 2;
const DF_ENG: u8 = 3;
const DF_SF: u8 = 4;
const DF_UN: u8 = 5;

const dtLongInteger: u32 = 0;
const dtReal34: u32 = 1;
const dtComplex34: u32 = 2;
const dtTime: u32 = 3;
const dtDate: u32 = 4;
const dtString: u32 = 5;
const dtReal34Matrix: u32 = 6;
const dtComplex34Matrix: u32 = 7;
const dtShortInteger: u32 = 8;

extern var displayFormat: u8;
extern var displayFormatDigits: u8;
extern var timeDisplayFormatDigits: u8;
extern var calcModel: u8;
extern var DM_Cycling: u8;
extern var gapItemLeft: u16;
extern var gapItemRight: u16;
extern var gapItemRadix: u16;
extern var grpGroupingLeft: u8;
extern var grpGroupingGr1LeftOverflow: u8;
extern var grpGroupingGr1Left: u8;
extern var grpGroupingRight: u8;
extern var shortIntegerMode: u8;
extern var temporaryInformation: u8;
extern var roundingMode: u8;
extern var significantDigits: u8;
extern var dispBase: u8;
extern var fractionDigits: u8;
extern var currentAngularMode: c_int;
extern var exponentLimit: i16;
extern var exponentHideLimit: i16;
extern var calcMode: u8;
extern var previousCalcMode: u8;
extern var programRunStop: u8;
extern var lastErrorCode: u8;
extern var previousErrorCode: u8;
extern var currentKeyCode: u8;
extern var screenUpdatingMode: u8;
extern var thereIsSomethingToUndo: bool;
extern var numberOfNamedVariables: u16;
extern var statisticalSumsPointer: ?*anyopaque;
extern var hourGlassIconEnabled: bool;
extern var drawHistogram: u8;
extern var roundedTicks: bool;
extern var plotSelection: u16;
extern var lrSelection: u16;
extern var lrChosen: u16;
extern var lastPlotMode: u16;
extern var lrSelectionHistobackup: u16;
extern var lrChosenHistobackup: u16;
extern var beginOfProgramMemory: [*]u8;
extern var firstFreeProgramByte: [*]u8;
extern var freeProgramBytes: u16;
extern var currentStep: [*]u8;
extern var firstDisplayedStep: [*]u8;
extern var firstDisplayedLocalStepNumber: u16;
extern var currentLocalStepNumber: u16;
extern var beginOfCurrentProgram: [*]u8;
extern var endOfCurrentProgram: [*]u8;
extern var matrixIndex: u16;
extern var aimBuffer: [*]u8;
extern var nimBufferDisplay: [*]u8;

const ConfirmedFunction = *const fn (u16) callconv(.c) void;
extern var confirmedFunction: ?ConfirmedFunction;

const PrinterState = abi.PrinterState;

extern var printerState: PrinterState;

extern fn clearSystemFlag(sf: c_uint) void;
extern fn setSystemFlag(sf: c_uint) void;
extern fn getSystemFlag(sf: c_int) bool;
extern fn flipSystemFlag(sf: c_uint) void;
extern fn setSystemFlagChanged(sf: c_int) void;
extern fn fnSetFlag(flag: u16) void;
extern fn fnClearFlag(flag: u16) void;
extern fn resetShiftState() void;
extern fn setLineDelay(delay: u16) void;
extern fn saveStatsMatrix() void;
extern fn getMatrixFromRegister(regist: u16) void;
extern fn allocateLocalRegisters(number_of_registers_to_allocate: u16) void;
extern fn clearRegister(regist: i16) void;
extern fn resizeProgramMemory(new_size_in_blocks: u16) void;
extern fn fnDeleteAllVariables(confirmation: u16) void;
extern fn fnClFAll(confirmation: u16) void;

extern fn getRegParam(f: ?*bool, s: *u16, n: *u16, d: ?*u16) u8;
extern fn getRegisterDataType(regist: i16) u32;
extern var numberOfPrograms: u16;

fn isPrintableScalarType(dt: u32) bool {
    return register_data_type.isPrintableScalarType(dt);
}

pub export fn fnDisplayFormatTime(display_format_n: u16) callconv(.c) void {
    display_format.run(.time, display_format_n);
}

/// DYNMNU. The console trace is the function's entire effect, and it is gated on
/// the build alone -- neither VERBOSE_LEVEL nor a telltale macro -- so it is live
/// on every host lane. The firmware build has no body at all.
pub export fn fnDynamicMenu(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    if (comptime !dmcp_build) {
        _ = printf(
            "fnDynamicMenu:\n       softmenuId = %d\n  dynamicMenuItem = %d\n",
            @as(c_int, frontier_softmenus.z47_frontier_dynamic_menu_softmenu_id()),
            @as(c_int, frontier_softmenus.z47_frontier_dynamic_menu_item()),
        );
    }
}

pub export fn fnNop(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
}

// Non-INLINE_TEST compatibility stubs.
pub export fn fnSwStart(nr: u8) callconv(.c) void {
    _ = nr;
}

pub export fn fnSwStop(nr: u8) callconv(.c) void {
    _ = nr;
}

pub export fn fnSetInlineTest(drConfig: u16) callconv(.c) void {
    _ = drConfig;
}

pub export fn fnGetInlineTestBsToX(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
}

pub export fn fnSetInlineTestXToBs(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
}

pub export fn fnSysFreeMem(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
}

pub export fn fnTestBitIsSet(bit: u8) callconv(.c) bool {
    _ = bit;
    return false;
}

pub export fn fnCFGsettings(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    frontier_items.runFunction(@as(i16, @intCast(ITM_FF)));
    frontier_softmenus.showSoftmenu(-MNU_SYSFL);
}

pub export fn fnP_PrinterOnOff(op: u16) callconv(.c) void {
    printer_control.run(.on_off, op);
}

pub export fn fnP_PrinterMode(mode: u16) callconv(.c) void {
    printer_control.run(.mode, mode);
}

pub export fn fnSetPrinter(model: u16) callconv(.c) void {
    printer_control.run(.set_model, model);
}

pub export fn fnP_SetDelay(delay: u16) callconv(.c) void {
    printer_control.run(.set_delay, delay);
}

pub export fn fnP_Advance(unused_but_mandatory_parameter: u16) callconv(.c) void {
    printer_control.run(.advance, unused_but_mandatory_parameter);
}

pub export fn fnP_PrinterList(lines: u16) callconv(.c) void {
    printer_control.run(.list, lines);
}

pub export fn fnP_Byte(byte: u16) callconv(.c) void {
    printer_control.run(.byte, byte);
}

pub export fn fnP_Char(register_no: u16) callconv(.c) void {
    printer_control.run(.char, register_no);
}

pub export fn fnP_Tab(column: u16) callconv(.c) void {
    printer_control.run(.tab, column);
}

pub export fn fnP_LCD(unused_but_mandatory_parameter: u16) callconv(.c) void {
    printer_control.run(.lcd, unused_but_mandatory_parameter);
}

pub export fn fnSettingsDispFormatGrpL(param: u16) callconv(.c) void {
    frontend_settings.run(.set_group_left, param);
}

pub export fn fnSettingsDispFormatGrp1Lo(param: u16) callconv(.c) void {
    frontend_settings.run(.set_group_1lo, param);
}

pub export fn fnSettingsDispFormatGrp1L(param: u16) callconv(.c) void {
    frontend_settings.run(.set_group_1l, param);
}

pub export fn fnSettingsDispFormatGrpR(param: u16) callconv(.c) void {
    frontend_settings.run(.set_group_right, param);
}

pub export fn fnSettingsDispFormatGrpHex(param: u16) callconv(.c) void {
    frontend_settings.run(.set_group_hex, param);
}

pub export fn fnSettingsDispFormatGrpBin(param: u16) callconv(.c) void {
    frontend_settings.run(.set_group_bin, param);
}

pub export fn fnMenuGapL(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    frontend_settings.run(.menu_gap_l, 0);
}

pub export fn fnMenuGapRX(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    frontend_settings.run(.menu_gap_rx, 0);
}

pub export fn fnMenuGapR(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    frontend_settings.run(.menu_gap_r, 0);
}

pub export fn fnWho(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    frontend_settings.run(.who, 0);
}

pub export fn fnVersion(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    frontend_settings.run(.version, 0);
}

pub export fn fnSetRoundingMode(rm: u16) callconv(.c) void {
    frontend_settings.run(.set_rounding_mode, rm);
}

pub export fn fnSetSignificantDigits(s: u16) callconv(.c) void {
    frontend_settings.run(.set_significant_digits, s);
}

pub export fn fnSetBaseNr(s: u16) callconv(.c) void {
    frontend_settings.run(.set_base_nr, s);
}

pub export fn fnSetFractionDigits(s: u16) callconv(.c) void {
    frontend_settings.run(.set_fraction_digits, s);
}

pub export fn fnFractionType(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    frontend_settings.run(.fraction_type, 0);
}

pub export fn fnRange(r: u16) callconv(.c) void {
    frontend_settings.run(.set_range, r);
}

pub export fn fnHide(h: u16) callconv(.c) void {
    frontend_settings.run(.set_hide, h);
}

pub export fn fnConfirmationYes(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    frontend_settings.run(.confirmation_yes, 0);
}

pub export fn fnConfirmationNo(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    frontend_settings.run(.confirmation_no, 0);
}

pub export fn fnGetRange(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    frontend_settings.run(.get_range, 0);
}

pub export fn fnGetHide(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    frontend_settings.run(.get_hide, 0);
}

pub export fn fnGetLastErr(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    frontend_settings.run(.get_last_error, 0);
}

pub export fn fnP_User(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    print_user.run();
}

pub export fn fnP_Sigma(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    print_register.run(.sigma, 0);
}

pub export fn fnP_PrintAllItems(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    print_all_items.run();
}

pub export fn fnPlotStat(plot_mode: u16) callconv(.c) void {
    plot_stat.run(plot_mode);
}

// The editor-mode guard lives with the mutation, which knows which of the four
// C functions is refusing and so can name it in the console hint.
fn matrixRunMutation(kind: matrix_mutation.Kind) void {
    matrix_mutation.run(kind);
}

pub export fn wrapIJ(rows: u16, cols: u16) callconv(.c) bool {
    return matrix_nav.wrap(rows, cols);
}

pub export fn fnOldMatrix(unused_param_but_mandatory: u16) callconv(.c) void {
    _ = unused_param_but_mandatory;
    matrix_editor_entry.reloadOld();
}

pub export fn fnGoToElement(unused_param_but_mandatory: u16) callconv(.c) void {
    _ = unused_param_but_mandatory;
    matrix_goto_grow.goToElement();
}

pub export fn fnGoToRow(row: u16) callconv(.c) void {
    matrix_goto_grow.goToRow(row);
}

pub export fn fnGoToColumn(col: u16) callconv(.c) void {
    matrix_goto_grow.goToColumn(col);
}

pub export fn fnSetGrowMode(grow_flag: u16) callconv(.c) void {
    matrix_goto_grow.setGrowMode(grow_flag);
}

// No editor-mode guard: I+ and I- walk the INDEXED matrix, which is what STOSEQ,
// RCLSEQ and the I+/J+ keys need outside CM_MIM. callByIndexedMatrix does the
// refusing, on there being no indexed matrix rather than on the calculator mode.
pub export fn fnIncDecI(mode: u16) callconv(.c) void {
    matrix_nav.incDec(.row, mode);
}

pub export fn _fnInsRow(add: bool) callconv(.c) void {
    const kind: matrix_mutation.Kind = if (add) .insert_row_after else .insert_row_before;
    matrixRunMutation(kind);
}

pub export fn _fnInsCol(add: bool) callconv(.c) void {
    const kind: matrix_mutation.Kind = if (add) .insert_col_after else .insert_col_before;
    matrixRunMutation(kind);
}

pub export fn fnInsRow(unused_param_but_mandatory: u16) callconv(.c) void {
    _ = unused_param_but_mandatory;
    _fnInsRow(false);
}

pub export fn fnAddRow(unused_param_but_mandatory: u16) callconv(.c) void {
    _ = unused_param_but_mandatory;
    _fnInsRow(true);
}

pub export fn fnInsCol(unused_param_but_mandatory: u16) callconv(.c) void {
    _ = unused_param_but_mandatory;
    _fnInsCol(false);
}

pub export fn fnAddCol(unused_param_but_mandatory: u16) callconv(.c) void {
    _ = unused_param_but_mandatory;
    _fnInsCol(true);
}

pub export fn fnDelRow(unused_param_but_mandatory: u16) callconv(.c) void {
    _ = unused_param_but_mandatory;
    matrixRunMutation(.delete_row);
}

pub export fn fnDelCol(unused_param_but_mandatory: u16) callconv(.c) void {
    _ = unused_param_but_mandatory;
    matrixRunMutation(.delete_col);
}

pub export fn mimRestore() callconv(.c) void {
    matrix_lifecycle.restore();
}

// Every distribution command is exported under its upstream name and gated on
// its own OPTION_DIST_* option, which the frontier build options carry as
// dr.option_dist_*: where the option is off the command is upstream's empty stub
// and the owner, with the math it pulls in, is never codegen'd into the frontier
// object, so it costs the flash-limited images nothing. The kernels and domain
// rules upstream exports from the same files follow in the comptime block below
// under the same gates; fnDistribution in the mathematics object reaches them
// through its descriptor table.

fn distributionCommand(comptime enabled: bool, comptime body: fn (u16) void, parameter: u16) linksection(dr.code_section) void {
    if (comptime enabled) {
        body(parameter);
    }
}

pub export fn fnCauchyP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_cauch, cauchy.cauchyP, unused_but_mandatory_parameter);
}

pub export fn fnCauchyL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_cauch, cauchy.cauchyL, unused_but_mandatory_parameter);
}

pub export fn fnCauchyR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_cauch, cauchy.cauchyR, unused_but_mandatory_parameter);
}

pub export fn fnCauchyI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_cauch, cauchy.cauchyI, unused_but_mandatory_parameter);
}

pub export fn fnWeibullP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_weibl, weibull.weibullP, unused_but_mandatory_parameter);
}

pub export fn fnWeibullL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_weibl, weibull.weibullL, unused_but_mandatory_parameter);
}

pub export fn fnWeibullR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_weibl, weibull.weibullR, unused_but_mandatory_parameter);
}

pub export fn fnWeibullI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_weibl, weibull.weibullI, unused_but_mandatory_parameter);
}

pub export fn fnLogisticP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_logis, logistic.logisticP, unused_but_mandatory_parameter);
}

pub export fn fnLogisticL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_logis, logistic.logisticL, unused_but_mandatory_parameter);
}

pub export fn fnLogisticR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_logis, logistic.logisticR, unused_but_mandatory_parameter);
}

pub export fn fnLogisticI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_logis, logistic.logisticI, unused_but_mandatory_parameter);
}

pub export fn fnExponentialP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_expon, exponential.exponentialP, unused_but_mandatory_parameter);
}

pub export fn fnExponentialL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_expon, exponential.exponentialL, unused_but_mandatory_parameter);
}

pub export fn fnExponentialR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_expon, exponential.exponentialR, unused_but_mandatory_parameter);
}

pub export fn fnExponentialI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_expon, exponential.exponentialI, unused_but_mandatory_parameter);
}

pub export fn fnParetoP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_prto, pareto.paretoP, unused_but_mandatory_parameter);
}

pub export fn fnParetoL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_prto, pareto.paretoL, unused_but_mandatory_parameter);
}

pub export fn fnParetoU(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_prto, pareto.paretoU, unused_but_mandatory_parameter);
}

pub export fn fnParetoI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_prto, pareto.paretoI, unused_but_mandatory_parameter);
}

pub export fn fnPareto2P(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_prto, pareto.pareto2P, unused_but_mandatory_parameter);
}

pub export fn fnPareto2L(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_prto, pareto.pareto2L, unused_but_mandatory_parameter);
}

pub export fn fnPareto2U(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_prto, pareto.pareto2U, unused_but_mandatory_parameter);
}

pub export fn fnPareto2I(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_prto, pareto.pareto2I, unused_but_mandatory_parameter);
}

pub export fn fnUniformP(discrete: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_unfm, uniform.uniformP, discrete);
}

pub export fn fnUniformL(discrete: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_unfm, uniform.uniformL, discrete);
}

pub export fn fnUniformU(discrete: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_unfm, uniform.uniformU, discrete);
}

pub export fn fnUniformI(discrete: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_unfm, uniform.uniformI, discrete);
}

pub export fn fnGEVP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_gev, gev.gevP, unused_but_mandatory_parameter);
}

pub export fn fnGEVL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_gev, gev.gevL, unused_but_mandatory_parameter);
}

pub export fn fnGEVR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_gev, gev.gevR, unused_but_mandatory_parameter);
}

pub export fn fnGEVI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_gev, gev.gevI, unused_but_mandatory_parameter);
}

pub export fn fnGeometricP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_geom, geometric.geometricP, unused_but_mandatory_parameter);
}

pub export fn fnGeometricL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_geom, geometric.geometricL, unused_but_mandatory_parameter);
}

pub export fn fnGeometricR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_geom, geometric.geometricR, unused_but_mandatory_parameter);
}

pub export fn fnGeometricI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_geom, geometric.geometricI, unused_but_mandatory_parameter);
}

pub export fn fnPoissonP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_poiss, poisson.poissonP, unused_but_mandatory_parameter);
}

pub export fn fnPoissonL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_poiss, poisson.poissonL, unused_but_mandatory_parameter);
}

pub export fn fnPoissonR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_poiss, poisson.poissonR, unused_but_mandatory_parameter);
}

pub export fn fnPoissonI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_poiss, poisson.poissonI, unused_but_mandatory_parameter);
}

pub export fn fnBinomialP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_binom, binomial.binomialP, unused_but_mandatory_parameter);
}

pub export fn fnBinomialL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_binom, binomial.binomialL, unused_but_mandatory_parameter);
}

pub export fn fnBinomialR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_binom, binomial.binomialR, unused_but_mandatory_parameter);
}

pub export fn fnBinomialI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_binom, binomial.binomialI, unused_but_mandatory_parameter);
}

pub export fn fnNegBinomialP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_nbin, neg_binom.negBinomialP, unused_but_mandatory_parameter);
}

pub export fn fnNegBinomialL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_nbin, neg_binom.negBinomialL, unused_but_mandatory_parameter);
}

pub export fn fnNegBinomialR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_nbin, neg_binom.negBinomialR, unused_but_mandatory_parameter);
}

pub export fn fnNegBinomialI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_nbin, neg_binom.negBinomialI, unused_but_mandatory_parameter);
}

pub export fn fnHypergeometricP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_hyper, hyper.hypergeometricP, unused_but_mandatory_parameter);
}

pub export fn fnHypergeometricL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_hyper, hyper.hypergeometricL, unused_but_mandatory_parameter);
}

pub export fn fnHypergeometricR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_hyper, hyper.hypergeometricR, unused_but_mandatory_parameter);
}

pub export fn fnHypergeometricI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_hyper, hyper.hypergeometricI, unused_but_mandatory_parameter);
}

pub export fn fnChi2P(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_chi2, chi2.chi2P, unused_but_mandatory_parameter);
}

pub export fn fnChi2L(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_chi2, chi2.chi2L, unused_but_mandatory_parameter);
}

pub export fn fnChi2R(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_chi2, chi2.chi2R, unused_but_mandatory_parameter);
}

pub export fn fnChi2I(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_chi2, chi2.chi2I, unused_but_mandatory_parameter);
}

fn normalCommand(comptime body: fn (normal.NormalType) void, comptime normal_type: normal.NormalType) linksection(dr.code_section) void {
    if (comptime dr.option_dist_norml) {
        body(normal_type);
    }
}

pub export fn fnStdNormalP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    normalCommand(normal.normalP, .std_normal);
}

pub export fn fnStdNormalL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    normalCommand(normal.normalL, .std_normal);
}

pub export fn fnStdNormalR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    normalCommand(normal.normalR, .std_normal);
}

pub export fn fnStdNormalI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    normalCommand(normal.normalI, .std_normal);
}

pub export fn fnNormalP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    normalCommand(normal.normalP, .param_normal);
}

pub export fn fnNormalL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    normalCommand(normal.normalL, .param_normal);
}

pub export fn fnNormalR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    normalCommand(normal.normalR, .param_normal);
}

pub export fn fnNormalI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    normalCommand(normal.normalI, .param_normal);
}

pub export fn fnLogNormalP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    normalCommand(normal.normalP, .log_normal);
}

pub export fn fnLogNormalL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    normalCommand(normal.normalL, .log_normal);
}

pub export fn fnLogNormalR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    normalCommand(normal.normalR, .log_normal);
}

pub export fn fnLogNormalI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    normalCommand(normal.normalI, .log_normal);
}

pub export fn fnF_P(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_f, f_dist.fP, unused_but_mandatory_parameter);
}

pub export fn fnF_L(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_f, f_dist.fL, unused_but_mandatory_parameter);
}

pub export fn fnF_R(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_f, f_dist.fR, unused_but_mandatory_parameter);
}

pub export fn fnF_I(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_f, f_dist.fI, unused_but_mandatory_parameter);
}

pub export fn fnT_P(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_t, t_dist.tP, unused_but_mandatory_parameter);
}

pub export fn fnT_L(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_t, t_dist.tL, unused_but_mandatory_parameter);
}

pub export fn fnT_R(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_t, t_dist.tR, unused_but_mandatory_parameter);
}

pub export fn fnT_I(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    distributionCommand(dr.option_dist_t, t_dist.tI, unused_but_mandatory_parameter);
}

// The domain rules and kernels each distribution file exports: the descriptor
// table in wp34s.c names them, the discrete quantiles call across files for the
// Poisson, binomial, negative binomial and hypergeometric CDFs, the Student t
// and chi-square take the standard normal, and the binomial family takes the F's
// beta machinery and the geometric's integer finisher. Each symbol exists only
// while its own option is on, exactly as upstream compiles it.
comptime {
    if (dr.option_dist_expon) {
        @export(&exponential.checkDomain, .{ .name = "exponentialCheckDomain" });
        @export(&exponential.wp34sPdfExpon, .{ .name = "WP34S_Pdf_Expon" });
        @export(&exponential.wp34sCdfuExpon, .{ .name = "WP34S_Cdfu_Expon" });
        @export(&exponential.wp34sCdfExpon, .{ .name = "WP34S_Cdf_Expon" });
        @export(&exponential.wp34sQfExpon, .{ .name = "WP34S_Qf_Expon" });
    }
    if (dr.option_dist_cauch) {
        @export(&cauchy.checkDomain, .{ .name = "cauchyCheckDomain" });
        @export(&cauchy.wp34sPdfCauchy, .{ .name = "WP34S_Pdf_Cauchy" });
        @export(&cauchy.wp34sCdfuCauchy, .{ .name = "WP34S_Cdfu_Cauchy" });
        @export(&cauchy.wp34sCdfCauchy, .{ .name = "WP34S_Cdf_Cauchy" });
        @export(&cauchy.wp34sQfCauchy, .{ .name = "WP34S_Qf_Cauchy" });
        @export(&cauchy.wp34sCdfCauchyCommon, .{ .name = "WP34S_cdf_cauchy_common" });
        @export(&cauchy.wp34sCdfCauchyXform, .{ .name = "WP34S_cdf_cauchy_xform" });
    }
    if (dr.option_dist_logis) {
        @export(&logistic.checkDomain, .{ .name = "logisticCheckDomain" });
        @export(&logistic.wp34sPdfLogit, .{ .name = "WP34S_Pdf_Logit" });
        @export(&logistic.wp34sCdfuLogit, .{ .name = "WP34S_Cdfu_Logit" });
        @export(&logistic.wp34sCdfLogit, .{ .name = "WP34S_Cdf_Logit" });
        @export(&logistic.wp34sQfLogit, .{ .name = "WP34S_Qf_Logit" });
    }
    if (dr.option_dist_weibl) {
        @export(&weibull.checkDomain, .{ .name = "weibullCheckDomain" });
        @export(&weibull.wp34sPdfWeib, .{ .name = "WP34S_Pdf_Weib" });
        @export(&weibull.wp34sCdfuWeib, .{ .name = "WP34S_Cdfu_Weib" });
        @export(&weibull.wp34sCdfWeib, .{ .name = "WP34S_Cdf_Weib" });
        @export(&weibull.wp34sQfWeib, .{ .name = "WP34S_Qf_Weib" });
    }
    if (dr.option_dist_binom) {
        @export(&binomial.checkDomain, .{ .name = "binomialCheckDomain" });
        @export(&binomial.wp34sPdfBinomial, .{ .name = "WP34S_Pdf_Binomial" });
        @export(&binomial.wp34sCdfuBinomial, .{ .name = "WP34S_Cdfu_Binomial" });
        @export(&binomial.wp34sCdfBinomial, .{ .name = "WP34S_Cdf_Binomial" });
        @export(&binomial.wp34sCdfBinomial2, .{ .name = "WP34S_Cdf_Binomial2" });
        @export(&binomial.wp34sQfBinomial, .{ .name = "WP34S_Qf_Binomial" });
    }
    if (dr.option_dist_geom) {
        @export(&geometric.checkDomain, .{ .name = "geometricCheckDomain" });
        @export(&geometric.wp34sPdfGeom, .{ .name = "WP34S_Pdf_Geom" });
        @export(&geometric.wp34sCdfuGeom, .{ .name = "WP34S_Cdfu_Geom" });
        @export(&geometric.wp34sCdfGeom, .{ .name = "WP34S_Cdf_Geom" });
        @export(&geometric.wp34sQfGeom, .{ .name = "WP34S_Qf_Geom" });
        @export(&geometric.wp34sQfDiscreteFinal, .{ .name = "WP34S_qf_discrete_final" });
    }
    if (dr.option_dist_poiss) {
        @export(&poisson.checkDomain, .{ .name = "poissonCheckDomain" });
        @export(&poisson.wp34sNormalMomentApprox, .{ .name = "WP34S_normal_moment_approx" });
        @export(&poisson.wp34sPdfPoisson, .{ .name = "WP34S_Pdf_Poisson" });
        @export(&poisson.wp34sCdfuPoisson, .{ .name = "WP34S_Cdfu_Poisson" });
        @export(&poisson.wp34sCdfPoisson, .{ .name = "WP34S_Cdf_Poisson" });
        @export(&poisson.wp34sCdfPoisson2, .{ .name = "WP34S_Cdf_Poisson2" });
        @export(&poisson.wp34sQfPoisson, .{ .name = "WP34S_Qf_Poisson" });
    }
    if (dr.option_dist_nbin) {
        @export(&neg_binom.checkDomain, .{ .name = "negativeBinomialCheckDomain" });
        @export(&neg_binom.pdfNegBinomial, .{ .name = "pdf_NegBinomial" });
        @export(&neg_binom.cdfuNegBinomial, .{ .name = "cdfu_NegBinomial" });
        @export(&neg_binom.cdfNegBinomial, .{ .name = "cdf_NegBinomial" });
        @export(&neg_binom.cdfNegBinomial2, .{ .name = "cdf_NegBinomial2" });
        @export(&neg_binom.qfNegBinomial, .{ .name = "qf_NegBinomial" });
    }
    if (dr.option_dist_hyper) {
        @export(&hyper.pdfHypergeometric, .{ .name = "pdf_Hypergeometric" });
        @export(&hyper.cdfuHypergeometric, .{ .name = "cdfu_Hypergeometric" });
        @export(&hyper.cdfHypergeometric, .{ .name = "cdf_Hypergeometric" });
        @export(&hyper.cdfHypergeometric2, .{ .name = "cdf_Hypergeometric2" });
        @export(&hyper.qfHypergeometric, .{ .name = "qf_Hypergeometric" });
    }
    if (dr.option_dist_chi2) {
        @export(&chi2.checkRegisterNoFP, .{ .name = "checkRegisterNoFP" });
        @export(&chi2.checkDomain, .{ .name = "chi2CheckDomain" });
        @export(&chi2.wp34sPdfChi2, .{ .name = "WP34S_Pdf_Chi2" });
        @export(&chi2.wp34sCdfuChi2, .{ .name = "WP34S_Cdfu_Chi2" });
        @export(&chi2.wp34sCdfChi2, .{ .name = "WP34S_Cdf_Chi2" });
        @export(&chi2.wp34sQfChi2, .{ .name = "WP34S_Qf_Chi2" });
    }
    if (dr.option_dist_norml) {
        @export(&normal.wp34sPdfQ, .{ .name = "WP34S_Pdf_Q" });
        @export(&normal.wp34sCdfuQ, .{ .name = "WP34S_Cdfu_Q" });
        @export(&normal.wp34sCdfQ, .{ .name = "WP34S_Cdf_Q" });
        @export(&normal.wp34sQfQEst, .{ .name = "WP34S_qf_q_est" });
        @export(&normal.wp34sQfQ, .{ .name = "WP34S_Qf_Q" });
    }
    if (dr.option_dist_f) {
        @export(&f_dist.checkDomain, .{ .name = "fCheckDomain" });
        @export(&f_dist.distributionLogBetaPrefix, .{ .name = "distributionLogBetaPrefix" });
        @export(&f_dist.distributionBetaPair, .{ .name = "distributionBetaPair" });
        @export(&f_dist.wp34sPdfF, .{ .name = "WP34S_Pdf_F" });
        @export(&f_dist.wp34sCdfuF, .{ .name = "WP34S_Cdfu_F" });
        @export(&f_dist.wp34sCdfF, .{ .name = "WP34S_Cdf_F" });
        @export(&f_dist.wp34sQfF, .{ .name = "WP34S_Qf_F" });
        @export(&f_dist.wp34sQfNewton, .{ .name = "WP34S_Qf_Newton" });
    }
    if (dr.option_dist_t) {
        @export(&t_dist.checkDomain, .{ .name = "studentTCheckDomain" });
        @export(&t_dist.wp34sPdfT, .{ .name = "WP34S_Pdf_T" });
        @export(&t_dist.wp34sCdfuT, .{ .name = "WP34S_Cdfu_T" });
        @export(&t_dist.wp34sCdfT, .{ .name = "WP34S_Cdf_T" });
        @export(&t_dist.wp34sQfT, .{ .name = "WP34S_Qf_T" });
    }
}
