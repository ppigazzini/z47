const std = @import("std");
const runtime = @import("frontier_runtime.zig");

const DSP_MAX: u16 = 19;
const FLAG_FRACT: c_uint = 0x8007;
const FLAG_PROPFR: c_uint = 0x8008;
const FLAG_TRACE: c_uint = 0x8013;
const FLAG_PRTACT: c_uint = 0xc020;
const FLAG_INTING: c_uint = 0xc025;
const FLAG_SOLVING: c_uint = 0xc026;
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

const USER_KRESET: u16 = 24;
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
const ITM_END: u16 = 1458;
const ITM_FF: u16 = 112;
const MNU_SYSFL: i16 = 1379;
const MNU_HOME: i16 = 1921;
const MNU_PFN: i16 = 1403;
const MNU_MyMenu: i16 = 1349;

const FIRST_GLOBAL_REGISTER: u16 = 0;
const LAST_GLOBAL_REGISTER: u16 = 125;
const FIRST_NAMED_VARIABLE: u16 = 256;
const FIRST_LOCAL_REGISTER: u16 = 7000;
const LAST_ITEM: u16 = 2732;

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

const TAM_BUFFER_LENGTH: usize = 32;

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

const MNU_GAP_L: i16 = 2151;
const MNU_GAP_RX: i16 = 2152;
const MNU_GAP_R: i16 = 2153;
const MNU_PLOT_SCATR: i16 = 1395;
const MNU_PLOT_ASSESS: i16 = 1396;
const MNU_HPLOT: i16 = 1402;

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
extern var tmpRow: u16;
extern var aimBuffer: [*]u8;
extern var nimBufferDisplay: [*]u8;

const ConfirmedFunction = *const fn (u16) callconv(.c) void;
extern var confirmedFunction: ?ConfirmedFunction;

const PrinterState = extern struct {
    print_on: bool,
    trace_done: bool,
    print_blank_line: u8,
    print_mode: c_int,
    printer_model: c_int,
    delay: u16,
};

extern var printerState: PrinterState;

extern fn clearSystemFlag(sf: c_uint) void;
extern fn setSystemFlag(sf: c_uint) void;
extern fn getSystemFlag(sf: c_int) bool;
extern fn flipSystemFlag(sf: c_uint) void;
extern fn setSystemFlagChanged(sf: c_int) void;
extern fn fnSetFlag(flag: u16) void;
extern fn fnClearFlag(flag: u16) void;
extern fn fnRefreshState() void;
extern fn showSoftmenu(menu: i16) void;
extern fn runFunction(func: i16) void;
extern fn resetShiftState() void;
extern fn refreshScreen(source: u16) void;
extern fn refreshLcd(surface: ?*anyopaque) void;
extern fn setLineDelay(delay: u16) void;
extern fn print_lf() void;
extern fn printLine(buff: [*:0]const u8, with_lf: c_int) void;
extern fn printJustified(buff: [*:0]const u8) void;
extern fn printTab(col: u16) void;
extern fn printProgram(list: bool, lines: u16) void;
extern fn cmdPrint(arg: u16, op: c_int) void;
extern fn printTraceMatElement(where: u16) void;
extern fn popSoftmenu() void;
extern fn setConfirmationMode(func: ConfirmedFunction) void;
extern fn fnClSigma(unused_but_mandatory_parameter: u16) void;
extern fn calcSigma(max_offset: u16) void;
extern fn fnCurveFitting(curve_fitting: u16) void;
extern fn z47_frontier_matrix_is_register_matrix_vector(regist: u16) bool;
extern fn z47_frontier_matrix_vector_polar_mode(regist: u16) u16;
extern fn z47_frontier_matrix_get_register_as_int(regist: u16, as_array_pointer: bool) i16;
extern fn z47_frontier_matrix_set_register_as_int(regist: u16, as_array_pointer: bool, to_store: i16) void;
extern fn z47_frontier_matrix_open_rows() u16;
extern fn z47_frontier_matrix_open_cols() u16;
extern fn z47_frontier_matrix_commit_open_to_register() void;
extern fn z47_frontier_matrix_calc_mode_normal_gui() void;
extern fn z47_frontier_matrix_hide_cursor() void;
extern fn z47_frontier_matrix_reload_open_matrix_from_register() void;
extern fn z47_frontier_matrix_inc_dec_i(mode: u16) void;
extern fn z47_frontier_matrix_inc_dec_j(mode: u16) void;
extern fn z47_frontier_matrix_insert_row(add: bool) void;
extern fn z47_frontier_matrix_insert_col(add: bool) void;
extern fn z47_frontier_matrix_delete_row() void;
extern fn z47_frontier_matrix_delete_col() void;
extern fn z47_frontier_matrix_finalize_open_matrix_memory() void;
extern fn leaveTamModeIfEnabled() void;
extern fn saveStatsMatrix() void;
extern fn getMatrixFromRegister(regist: u16) void;
extern fn showMatrixEditor() void;
extern fn mimEnter(commit: bool) void;
extern fn allocateLocalRegisters(number_of_registers_to_allocate: u16) void;
extern fn clearRegister(regist: i16) void;
extern fn fnExitAllMenus(unused_but_mandatory_parameter: u16) void;
extern fn fnDeleteUserMenus(confirmation: u16) void;
extern fn fnRESET_MyM(param: u16) void;
extern fn fnRESET_Mya() void;
extern fn createHOME() void;
extern fn createPFN() void;
extern fn initUserKeyArgument() void;
extern fn showHideHourGlass() void;
extern fn refreshStatusBar() void;
extern fn statGraphReset() void;
extern fn resizeProgramMemory(new_size_in_blocks: u16) void;
extern fn scanLabelsAndPrograms() void;
extern fn removeUserItemAssignments(user_item: i16, user_item_name: [*:0]const u8) void;
extern fn fnDeleteAllVariables(confirmation: u16) void;
extern fn fnClFAll(confirmation: u16) void;
extern fn z47_frontier_push_u32_to_x(value: u32) void;
extern fn z47_frontier_release_saved_statistical_sums() void;
extern fn z47_frontier_is_r47_fam() bool;
extern fn z47_frontier_keys_to_user_case() void;
extern fn z47_frontier_keys_from_user_case() void;
extern fn z47_frontier_keys_user_layout_reset_case() void;
extern fn z47_frontier_plot_set_plotstatmx_stats() void;
extern fn z47_frontier_plot_set_plotstatmx_histo() void;
extern fn z47_frontier_plot_set_statmx_histo() void;
extern fn z47_frontier_plot_has_source_data() bool;
extern fn z47_frontier_plot_clear_screen_for_graph_entry() void;
extern fn z47_frontier_program_current_program_in_ram() bool;

extern fn printReg(regist: u16, label: ?[*:0]const u8, eq: bool, where: c_int, pr_sigma: bool) void;
extern fn getRegParam(f: ?*bool, s: *u16, n: *u16, d: ?*u16) u8;
extern fn displayCalcErrorMessage(error_code: u8, err_message_register_line: i16, err_register_line: i16) void;
extern fn z47_frontier_print_reg_range(first_register_no: u16, last_register_no: u16) bool;
extern fn z47_frontier_current_number_of_local_registers() u16;
extern fn z47_frontier_print_exit_pressed() bool;
extern fn z47_frontier_print_sigma_line(index: u16) void;
extern fn z47_frontier_print_alpha_register(register_no: u16) void;
extern fn getRegisterDataType(regist: i16) u32;
extern fn z47_frontier_x_real_matrix_rows() u16;
extern fn z47_frontier_x_real_matrix_cols() u16;
extern fn z47_frontier_x_complex_matrix_rows() u16;
extern fn z47_frontier_x_complex_matrix_cols() u16;
extern fn z47_frontier_x_real_matrix_element_to_temp1(index: u32) void;
extern fn z47_frontier_x_complex_matrix_element_to_temp1(index: u32) void;
extern fn create_filename(file_suffix: [*:0]const u8) void;
extern fn stackregister_csv_out(reg_b: i16, reg_e: i16, one_line: bool) void;
extern fn z47_frontier_print_set_printer_sbi(status: bool) void;
extern fn z47_frontier_print_get_unicode_value(regist: i16) u16;
extern fn z47_frontier_named_variable_label(index: u16, buffer: [*]u8, buffer_size: u16) bool;
extern fn z47_frontier_user_variable_should_skip(label: [*:0]const u8) bool;
extern fn z47_frontier_find_named_variable_register(label: [*:0]const u8) u16;
extern fn z47_frontier_program_begin() [*]u8;
extern fn z47_frontier_programs_end(step: [*]u8) bool;
extern fn z47_frontier_program_next_step(step: [*]u8) [*]u8;
extern fn z47_frontier_program_global_label(step: [*]u8, label: [*]u8, label_size: u16) bool;
extern fn z47_frontier_program_step_is_end(step: [*]u8) bool;
extern fn z47_frontier_program_label_prefix() [*:0]const u8;
extern fn z47_frontier_program_label_suffix() [*:0]const u8;
extern fn z47_frontier_print_program_counter(program_number: u16, total_programs: u16) void;
extern fn z47_frontier_format_register_label(register_no: u16, label: [*]u8, label_size: u16) void;
extern fn z47_frontier_item_catalog_name(item: u16) [*:0]const u8;
extern fn z47_frontier_item_softmenu_name(item: u16) [*:0]const u8;
extern fn z47_frontier_print_backup_aim_message_area() void;
extern fn z47_frontier_print_restore_aim_message_area() void;
extern fn z47_frontier_snap_screenshot_with_message_backup() void;
extern fn z47_frontier_snap_backup_tam(dst: [*]u8) void;
extern fn z47_frontier_snap_restore_tam(src: [*]const u8) void;
extern var numberOfPrograms: u16;
extern fn tmpString_csv_out(nn: u8) void;
extern fn fnShowVersion(option: u16) void;

fn clampDisplayDigits(display_format_n: u16) u8 {
    const clamped: u16 = if (display_format_n > DSP_MAX) DSP_MAX else display_format_n;
    return @as(u8, @intCast(clamped));
}

fn displayFormatReset(display_format_n: u16) void {
    displayFormatDigits = clampDisplayDigits(display_format_n);
    clearSystemFlag(FLAG_FRACT);
    DM_Cycling = 0;
}

fn isPrintableScalarType(dt: u32) bool {
    return switch (dt) {
        dtLongInteger, dtReal34, dtShortInteger, dtString, dtDate, dtTime => true,
        else => false,
    };
}

pub export fn fnSNAP(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    resetShiftState();
    refreshScreen(80);
    z47_frontier_snap_screenshot_with_message_backup();

    var tam_backup: [TAM_BUFFER_LENGTH]u8 = undefined;
    z47_frontier_snap_backup_tam(&tam_backup);
    if (calcMode == CM_AIM) {
        fnP_Alpha(NOPARAM);
    } else {
        fnP_All_Regs(PRN_STK);
    }
    z47_frontier_snap_restore_tam(&tam_backup);

    screenUpdatingMode |= SCRUPD_SKIP_STACK_ONE_TIME | SCRUPD_SKIP_MENU_ONE_TIME;
}

pub export fn fnDisplayFormatFix(display_format_n: u16) callconv(.c) void {
    displayFormatReset(display_format_n);
    displayFormat = DF_FIX;
    fnRefreshState();
}

pub export fn fnDisplayFormatSci(display_format_n: u16) callconv(.c) void {
    displayFormatReset(display_format_n);
    displayFormat = DF_SCI;
    fnRefreshState();
}

pub export fn fnDisplayFormatEng(display_format_n: u16) callconv(.c) void {
    displayFormatReset(display_format_n);
    displayFormat = DF_ENG;
    fnRefreshState();
}

pub export fn fnDisplayFormatAll(display_format_n: u16) callconv(.c) void {
    displayFormatReset(display_format_n);
    displayFormat = DF_ALL;
    fnRefreshState();
}

pub export fn fnDisplayFormatSigFig(display_format_n: u16) callconv(.c) void {
    displayFormatReset(display_format_n);
    displayFormat = DF_SF;
    fnRefreshState();
}

pub export fn fnDisplayFormatUnit(display_format_n: u16) callconv(.c) void {
    displayFormatReset(display_format_n);
    displayFormat = DF_UN;
    fnRefreshState();
}

pub export fn fnDisplayFormatDsp(display_format_n: u16) callconv(.c) void {
    displayFormatDigits = clampDisplayDigits(display_format_n);
    clearSystemFlag(FLAG_FRACT);
    fnRefreshState();
}

pub export fn fnDisplayFormatTime(display_format_n: u16) callconv(.c) void {
    timeDisplayFormatDigits = clampDisplayDigits(display_format_n);
}

pub export fn fnDynamicMenu(unused_but_mandatory_parameter: u16) callconv(.c) void {
    runtime.z47_frontier_retained_fnDynamicMenu(unused_but_mandatory_parameter);
}

pub export fn fnNop(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
}

pub export fn fnCFGsettings(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runFunction(@as(i16, @intCast(ITM_FF)));
    showSoftmenu(-MNU_SYSFL);
}

pub export fn fnP_PrinterOnOff(op: u16) callconv(.c) void {
    if (op == PRON) {
        printerState.print_on = true;
        setSystemFlag(FLAG_PRTACT);
        fnSetFlag(FLAG_PRTEN);
    } else if (op == PROFF) {
        printerState.print_on = false;
        clearSystemFlag(FLAG_PRTACT);
        fnClearFlag(FLAG_PRTEN);
    }
}

pub export fn fnP_PrinterMode(mode: u16) callconv(.c) void {
    if (mode == MAN) {
        fnClearFlag(FLAG_NORM);
        fnClearFlag(@as(u16, @intCast(FLAG_TRACE)));
    } else if (mode == NORM) {
        fnSetFlag(FLAG_NORM);
        fnClearFlag(@as(u16, @intCast(FLAG_TRACE)));
    } else if (mode == TRACE) {
        fnClearFlag(FLAG_NORM);
        fnSetFlag(@as(u16, @intCast(FLAG_TRACE)));
    } else if (mode == STRACE) {
        fnSetFlag(FLAG_NORM);
        fnSetFlag(@as(u16, @intCast(FLAG_TRACE)));
    }
}

pub export fn fnSetPrinter(model: u16) callconv(.c) void {
    printerState.printer_model = @as(c_int, @intCast(model));
}

pub export fn fnP_SetDelay(delay: u16) callconv(.c) void {
    printerState.delay = delay;
    setLineDelay(delay);
}

pub export fn fnP_Advance(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    z47_frontier_print_set_printer_sbi(true);
    print_lf();
    z47_frontier_print_set_printer_sbi(false);
}

pub export fn fnP_PrinterList(lines: u16) callconv(.c) void {
    printProgram(true, lines);
}

pub export fn fnP_Byte(byte: u16) callconv(.c) void {
    z47_frontier_print_set_printer_sbi(true);
    cmdPrint(byte, PRINT_BYTE);
    z47_frontier_print_set_printer_sbi(false);
}

pub export fn fnP_Char(register_no: u16) callconv(.c) void {
    z47_frontier_print_set_printer_sbi(true);
    const character = z47_frontier_print_get_unicode_value(@as(i16, @intCast(register_no)));
    cmdPrint(character, PRINT_CHAR);
    z47_frontier_print_set_printer_sbi(false);
}

pub export fn fnP_Tab(column: u16) callconv(.c) void {
    z47_frontier_print_set_printer_sbi(true);
    cmdPrint(column, PRINT_TAB);
    z47_frontier_print_set_printer_sbi(false);
}

pub export fn fnP_LCD(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    if (getSystemFlag(@as(c_int, @intCast(FLAG_PRTACT)))) {
        return;
    }
    fnSNAP(9876);
}

pub export fn fnSetGapChar(char_param: u16) callconv(.c) void {
    const group = char_param & 49152;
    const value = char_param & 16383;
    if (group == 0) {
        gapItemLeft = value;
    } else if (group == 32768) {
        gapItemRight = value;
    } else if (group == 49152) {
        gapItemRadix = value;
    }
}

pub export fn fnSettingsDispFormatGrpL(param: u16) callconv(.c) void {
    grpGroupingLeft = @as(u8, @intCast(param));
}

pub export fn fnSettingsDispFormatGrp1Lo(param: u16) callconv(.c) void {
    grpGroupingGr1LeftOverflow = @as(u8, @intCast(param));
}

pub export fn fnSettingsDispFormatGrp1L(param: u16) callconv(.c) void {
    grpGroupingGr1Left = @as(u8, @intCast(param));
}

pub export fn fnSettingsDispFormatGrpR(param: u16) callconv(.c) void {
    grpGroupingRight = @as(u8, @intCast(param));
}

pub export fn fnMenuGapL(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    showSoftmenu(-MNU_GAP_L);
}

pub export fn fnMenuGapRX(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    showSoftmenu(-MNU_GAP_RX);
}

pub export fn fnMenuGapR(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    showSoftmenu(-MNU_GAP_R);
}

pub export fn fnIntegerMode(mode: u16) callconv(.c) void {
    if (shortIntegerMode != @as(u8, @intCast(mode))) {
        setSystemFlagChanged(SETTING_SINT_MODE);
    }
    shortIntegerMode = @as(u8, @intCast(mode));
    fnRefreshState();
}

pub export fn fnWho(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    temporaryInformation = TI_WHO;
}

pub export fn fnVersion(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    temporaryInformation = TI_VERSION;
}

pub export fn fnSetRoundingMode(rm: u16) callconv(.c) void {
    roundingMode = @as(u8, @intCast(rm));
}

pub export fn fnSetSignificantDigits(s: u16) callconv(.c) void {
    significantDigits = @as(u8, @intCast(s));
    if (significantDigits == 0) {
        significantDigits = 34;
    }
}

pub export fn fnSetBaseNr(s: u16) callconv(.c) void {
    dispBase = @as(u8, @intCast(s));
    if (dispBase == 1) {
        dispBase = 0;
    }
}

pub export fn fnSetFractionDigits(s: u16) callconv(.c) void {
    fractionDigits = @as(u8, @intCast(s));
    if (fractionDigits == 0) {
        fractionDigits = 34;
    }
}

pub export fn fnAngularMode(am: u16) callconv(.c) void {
    if (currentAngularMode != @as(c_int, @intCast(am))) {
        setSystemFlagChanged(SETTING_AMODE);
    }
    currentAngularMode = @as(c_int, @intCast(am));
    fnRefreshState();
}

pub export fn fnFractionType(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    var state: u8 = 0;
    if (getSystemFlag(@as(c_int, @intCast(FLAG_IRFRAC)))) state += 8;
    if (getSystemFlag(@as(c_int, @intCast(FLAG_IRFRQ)))) state += 4;
    if (getSystemFlag(@as(c_int, @intCast(FLAG_PROPFR)))) state += 2;
    if (getSystemFlag(@as(c_int, @intCast(FLAG_FRACT)))) state += 1;

    if (getSystemFlag(@as(c_int, @intCast(FLAG_FRCYC)))) {
        state = switch (state) {
            0b0000 => 0b0001,
            0b0010 => 0b0011,
            0b0100 => 0b1100,
            0b0110 => 0b1110,
            0b0001 => 0b1110,
            0b0011 => 0b0001,
            0b1100 => 0b0011,
            0b1110 => 0b1100,
            else => 0b0011,
        };

        if ((state & 8) != 0) setSystemFlag(FLAG_IRFRAC) else clearSystemFlag(FLAG_IRFRAC);
        if ((state & 4) != 0) setSystemFlag(FLAG_IRFRQ) else clearSystemFlag(FLAG_IRFRQ);
        if ((state & 2) != 0) setSystemFlag(FLAG_PROPFR) else clearSystemFlag(FLAG_PROPFR);
        if ((state & 1) != 0) setSystemFlag(FLAG_FRACT) else clearSystemFlag(FLAG_FRACT);
    } else {
        if (getSystemFlag(@as(c_int, @intCast(FLAG_IRFRQ)))) {
            flipSystemFlag(FLAG_IRFRAC);
        } else {
            flipSystemFlag(FLAG_FRACT);
        }
    }
}

pub export fn fnRange(r: u16) callconv(.c) void {
    exponentLimit = @as(i16, @intCast(r));
    if (exponentLimit < DF_DMX_MIN) {
        exponentLimit = DF_DMX_MIN;
    }
}

pub export fn fnHide(h: u16) callconv(.c) void {
    exponentHideLimit = @as(i16, @intCast(h));
    if (exponentHideLimit > 0 and exponentHideLimit < DF_HIDE_MIN) {
        exponentHideLimit = DF_HIDE_MIN;
    }
}

pub export fn fnConfirmationYes(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    if (calcMode == CM_CONFIRMATION) {
        calcMode = previousCalcMode;
        popSoftmenu();
        if (confirmedFunction) |func| {
            func(CONFIRMED);
        }
    }
}

pub export fn fnConfirmationNo(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    if (calcMode == CM_CONFIRMATION) {
        calcMode = previousCalcMode;
        popSoftmenu();
    }
}

pub export fn fnGetRange(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    z47_frontier_push_u32_to_x(@as(u32, @intCast(exponentLimit)));
}

pub export fn fnGetHide(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    z47_frontier_push_u32_to_x(@as(u32, @intCast(exponentHideLimit)));
}

pub export fn fnGetLastErr(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    z47_frontier_push_u32_to_x(@as(u32, previousErrorCode));
}

pub export fn fnClAll(confirmation: u16) callconv(.c) void {
    if (confirmation == NOT_CONFIRMED) {
        setConfirmationMode(&fnClAll);
        return;
    }

    fnClPAll(CONFIRMED);
    fnClSigma(CONFIRMED);
    z47_frontier_release_saved_statistical_sums();

    allocateLocalRegisters(0);

    var regist: u16 = FIRST_GLOBAL_REGISTER;
    while (regist <= LAST_GLOBAL_REGISTER) : (regist += 1) {
        clearRegister(@as(i16, @intCast(regist)));
    }
    thereIsSomethingToUndo = false;

    fnExitAllMenus(NOPARAM);
    fnDeleteUserMenus(CONFIRMED);

    if (z47_frontier_is_r47_fam()) {
        fnRESET_MyM(ITM_RIBBON_R47);
    } else {
        fnRESET_MyM(ITM_RIBBON_C47);
    }

    fnRESET_Mya();
    createHOME();
    createPFN();

    fnKeysManagement(USER_KRESET);
    initUserKeyArgument();
    fnDeleteAllVariables(CONFIRMED);
    fnClFAll(CONFIRMED);

    temporaryInformation = TI_RESET;
    if (programRunStop == PGM_WAITING) {
        programRunStop = PGM_STOPPED;
    }
}

pub export fn fnP_User(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    currentKeyCode = 255;

    if (!getSystemFlag(@as(c_int, @intCast(FLAG_PRTACT)))) {
        if (getSystemFlag(@as(c_int, @intCast(FLAG_PRTEN))) or ((programRunStop != PGM_RUNNING) and (programRunStop != PGM_SINGLE_STEP))) {
            displayCalcErrorMessage(ERROR_PRINTING_DISABLED, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
        }
        return;
    }

    var label: [32]u8 = [_]u8{0} ** 32;
    var user_variable_found = false;
    var idx: u16 = 0;
    while (idx < numberOfNamedVariables) : (idx += 1) {
        if (!z47_frontier_named_variable_label(idx, &label, label.len)) {
            continue;
        }

        if (z47_frontier_user_variable_should_skip(@ptrCast(&label))) {
            continue;
        }

        const variable = z47_frontier_find_named_variable_register(@ptrCast(&label));
        printReg(variable, @ptrCast(&label), true, LINE_FULL, false);
        user_variable_found = true;

        if (z47_frontier_print_exit_pressed()) {
            return;
        }
    }

    if (user_variable_found) {
        print_lf();
    }

    var step = z47_frontier_program_begin();
    var program_number: u16 = 1;
    var first_program_label = true;

    while (!z47_frontier_programs_end(step)) {
        const next_step = z47_frontier_program_next_step(step);

        if (z47_frontier_program_global_label(step, &label, label.len)) {
            printLine(z47_frontier_program_label_prefix(), 0);
            printLine(@ptrCast(&label), 0);
            printLine(z47_frontier_program_label_suffix(), if (first_program_label) 0 else 1);

            if (first_program_label) {
                z47_frontier_print_program_counter(program_number, numberOfPrograms);
                first_program_label = false;
            }
        }

        if (z47_frontier_program_step_is_end(step)) {
            printLine("END", if (first_program_label) 0 else 1);
            if (first_program_label) {
                z47_frontier_print_program_counter(program_number, numberOfPrograms);
            }
            program_number += 1;
            first_program_label = true;
        }

        step = next_step;
        if (z47_frontier_print_exit_pressed()) {
            return;
        }
    }

    printLine(".END.", 1);
}

pub export fn fnP_Alpha(register_no: u16) callconv(.c) void {
    if (getSystemFlag(@as(c_int, @intCast(FLAG_PRTACT)))) {
        z47_frontier_print_alpha_register(register_no);
        return;
    }

    if (calcMode != CM_AIM) {
        return;
    }

    z47_frontier_print_backup_aim_message_area();
    create_filename(".REGS.TSV");
    tmpString_csv_out(5);
    z47_frontier_print_restore_aim_message_area();
}

pub export fn fnP_Regs(register_no: u16) callconv(.c) void {
    if (getSystemFlag(@as(c_int, @intCast(FLAG_PRTACT)))) {
        var label: [32]u8 = [_]u8{0} ** 32;
        z47_frontier_format_register_label(register_no, &label, label.len);
        printReg(register_no, @ptrCast(&label), true, LINE_FULL, false);
        return;
    }

    if (calcMode != CM_NORMAL) {
        return;
    }

    create_filename(".REGS.TSV");
    stackregister_csv_out(@as(i16, @intCast(register_no)), @as(i16, @intCast(register_no)), false);
}

pub export fn fnP_Sigma(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    currentKeyCode = 255;

    if (statisticalSumsPointer != null) {
        if (getSystemFlag(@as(c_int, @intCast(FLAG_PRTACT)))) {
            if (!getSystemFlag(@as(c_int, @intCast(FLAG_PRTEN))) and (programRunStop == PGM_RUNNING or programRunStop == PGM_SINGLE_STEP)) {
                displayCalcErrorMessage(ERROR_PRINTING_DISABLED, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
                return;
            }

            var regist: u16 = 0;
            while (regist < 28) : (regist += 1) {
                z47_frontier_print_sigma_line(regist);
                if (z47_frontier_print_exit_pressed()) {
                    return;
                }
            }
        }
        return;
    }

    displayCalcErrorMessage(ERROR_NO_SUMMATION_DATA, ERR_REGISTER_LINE, REGISTER_X);
}

pub export fn fnP_All_Regs(option: u16) callconv(.c) void {
    if (getSystemFlag(@as(c_int, @intCast(FLAG_PRTACT)))) {
        var s: u16 = 0;
        var n: u16 = 0;

        switch (option) {
            PRN_ALL => {
                if (z47_frontier_print_reg_range(@as(u16, @intCast(REGISTER_X)), REGISTER_W)) return;
                if (z47_frontier_print_reg_range(0, 99)) return;

                const local_count = z47_frontier_current_number_of_local_registers();
                if (local_count > 0) {
                    if (z47_frontier_print_reg_range(FIRST_LOCAL_REGISTER, FIRST_LOCAL_REGISTER + local_count - 1)) return;
                }

                if (numberOfNamedVariables > 0) {
                    _ = z47_frontier_print_reg_range(FIRST_NAMED_VARIABLE, FIRST_NAMED_VARIABLE + numberOfNamedVariables - 1);
                }
            },
            PRN_REGS => {
                lastErrorCode = getRegParam(null, &s, &n, null);
                if (lastErrorCode == ERROR_NONE) {
                    _ = z47_frontier_print_reg_range(s, (s + n) - 1);
                } else {
                    displayCalcErrorMessage(lastErrorCode, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
                }
            },
            PRN_Xr => {
                printReg(@as(u16, @intCast(REGISTER_X)), null, false, LINE_FULL, false);
            },
            PRN_STK => {
                const stack_top: u16 = if (getSystemFlag(FLAG_SSIZE8)) REGISTER_D else REGISTER_T;
                _ = z47_frontier_print_reg_range(stack_top, @as(u16, @intCast(REGISTER_X)));
            },
            PRN_XYr => {
                const x_type = getRegisterDataType(REGISTER_X);
                if (isPrintableScalarType(x_type)) {
                    const y_type = getRegisterDataType(REGISTER_Y);
                    if (isPrintableScalarType(y_type)) {
                        printReg(@as(u16, @intCast(REGISTER_X)), null, false, LINE_LEFT, false);
                        printReg(@as(u16, @intCast(REGISTER_Y)), null, false, LINE_RIGHT, false);
                        return;
                    }
                    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_Y);
                    return;
                }

                if (x_type == dtReal34Matrix) {
                    const rows = z47_frontier_x_real_matrix_rows();
                    const cols = z47_frontier_x_real_matrix_cols();

                    if (cols == 2) {
                        var i: u32 = 0;
                        while (i < rows) : (i += 1) {
                            const left_index = i * 2;
                            z47_frontier_x_real_matrix_element_to_temp1(left_index);
                            printReg(TEMP_REGISTER_1, null, false, LINE_LEFT, false);

                            z47_frontier_x_real_matrix_element_to_temp1(left_index + 1);
                            printReg(TEMP_REGISTER_1, null, false, LINE_RIGHT, false);
                        }
                        return;
                    }

                    if (rows == 2) {
                        var j: u32 = 0;
                        while (j < cols) : (j += 1) {
                            z47_frontier_x_real_matrix_element_to_temp1(j);
                            printReg(TEMP_REGISTER_1, null, false, LINE_LEFT, false);

                            z47_frontier_x_real_matrix_element_to_temp1(j + cols);
                            printReg(TEMP_REGISTER_1, null, false, LINE_RIGHT, false);
                        }
                        return;
                    }

                    displayCalcErrorMessage(ERROR_MATRIX_MISMATCH, ERR_REGISTER_LINE, REGISTER_X);
                    return;
                }

                if (x_type == dtComplex34Matrix) {
                    const rows = z47_frontier_x_complex_matrix_rows();
                    const cols = z47_frontier_x_complex_matrix_cols();

                    if (cols == 2) {
                        var i: u32 = 0;
                        while (i < rows) : (i += 1) {
                            const left_index = i * 2;
                            z47_frontier_x_complex_matrix_element_to_temp1(left_index);
                            printReg(TEMP_REGISTER_1, null, false, LINE_LEFT, false);

                            z47_frontier_x_complex_matrix_element_to_temp1(left_index + 1);
                            printReg(TEMP_REGISTER_1, null, false, LINE_RIGHT, false);
                        }
                        return;
                    }

                    if (rows == 2) {
                        var j: u32 = 0;
                        while (j < cols) : (j += 1) {
                            z47_frontier_x_complex_matrix_element_to_temp1(j);
                            printReg(TEMP_REGISTER_1, null, false, LINE_LEFT, false);

                            z47_frontier_x_complex_matrix_element_to_temp1(j + cols);
                            printReg(TEMP_REGISTER_1, null, false, LINE_RIGHT, false);
                        }
                        return;
                    }

                    displayCalcErrorMessage(ERROR_MATRIX_MISMATCH, ERR_REGISTER_LINE, REGISTER_X);
                    return;
                }

                displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
            },
            else => {
                // No-op for unsupported print-to-printer options in this command.
            },
        }
        return;
    }

    if (calcMode != CM_NORMAL and calcMode != CM_NO_UNDO) {
        return;
    }

    create_filename(".REGS.TSV");

    var s: u16 = 0;
    var n: u16 = 0;
    const local_count = z47_frontier_current_number_of_local_registers();

    switch (option) {
        PRN_ALL => {
            stackregister_csv_out(@as(i16, @intCast(REGISTER_X)), @as(i16, @intCast(REGISTER_W)), false);
            stackregister_csv_out(0, 99, false);
            if (local_count > 0) {
                stackregister_csv_out(@as(i16, @intCast(FIRST_LOCAL_REGISTER)), @as(i16, @intCast(FIRST_LOCAL_REGISTER + local_count - 1)), false);
            }
            if (numberOfNamedVariables > 0) {
                stackregister_csv_out(@as(i16, @intCast(FIRST_NAMED_VARIABLE)), @as(i16, @intCast(FIRST_NAMED_VARIABLE + numberOfNamedVariables - 1)), false);
            }
        },
        PRN_REGS => {
            lastErrorCode = getRegParam(null, &s, &n, null);
            if (lastErrorCode == ERROR_NONE) {
                stackregister_csv_out(@as(i16, @intCast(s)), @as(i16, @intCast((s + n) - 1)), false);
            } else {
                displayCalcErrorMessage(lastErrorCode, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
            }
        },
        PRN_STK => {
            if (getSystemFlag(FLAG_SSIZE8)) {
                stackregister_csv_out(@as(i16, @intCast(REGISTER_X)), @as(i16, @intCast(REGISTER_D)), false);
            } else {
                stackregister_csv_out(@as(i16, @intCast(REGISTER_X)), @as(i16, @intCast(REGISTER_T)), false);
            }
        },
        PRN_GLOBALr => {
            stackregister_csv_out(0, 99, false);
        },
        PRN_LOCALr => {
            if (local_count > 0) {
                stackregister_csv_out(@as(i16, @intCast(FIRST_LOCAL_REGISTER)), @as(i16, @intCast(FIRST_LOCAL_REGISTER + local_count - 1)), false);
            }
        },
        PRN_NAMEDr => {
            if (numberOfNamedVariables > 0) {
                stackregister_csv_out(@as(i16, @intCast(FIRST_NAMED_VARIABLE)), @as(i16, @intCast(FIRST_NAMED_VARIABLE + numberOfNamedVariables - 1)), false);
            }
        },
        PRN_Xr => {
            stackregister_csv_out(@as(i16, @intCast(REGISTER_X)), @as(i16, @intCast(REGISTER_X)), false);
        },
        PRN_TMP => {
            stackregister_csv_out(@as(i16, @intCast(TEMP_REGISTER_1)), @as(i16, @intCast(TEMP_REGISTER_1)), false);
        },
        PRN_XYr => {
            stackregister_csv_out(@as(i16, @intCast(REGISTER_X)), @as(i16, @intCast(REGISTER_Y)), true);
        },
        else => {},
    }
}

pub export fn fnP_PrintAllItems(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    currentKeyCode = 255;

    if (!getSystemFlag(@as(c_int, @intCast(FLAG_PRTACT)))) {
        return;
    }

    printLine("item catname  menuname", 1);

    var line_buf: [128]u8 = undefined;
    var item: u16 = 1;
    while (item < LAST_ITEM) : (item += 1) {
        const catalog_name = z47_frontier_item_catalog_name(item);
        const softmenu_name = z47_frontier_item_softmenu_name(item);

        const left = std.fmt.bufPrintZ(&line_buf, "{d: >4} {s}", .{ item, catalog_name }) catch continue;
        printLine(left, 0);
        printTab(97);

        const right = std.fmt.bufPrintZ(&line_buf, "{s} ", .{softmenu_name}) catch continue;
        printLine(right, 1);

        if (z47_frontier_print_exit_pressed()) {
            break;
        }
    }

    temporaryInformation = TI_PRINT_COMPLETE;
}

pub export fn fnKeysManagement(choice: u16) callconv(.c) void {
    switch (choice) {
        TO_USER => {
            z47_frontier_keys_to_user_case();
        },
        FROM_USER => {
            z47_frontier_keys_from_user_case();
        },
        USER_R47f_g, USER_R47bk_fg, USER_R47fg_bk, USER_R47fg_g, USER_C47, USER_DM42 => {
            calcModel = @as(u8, @intCast(choice));
            fnClearFlag(FLAG_USER);
            fnKeysManagement(USER_KRESET);
            if (choice == USER_R47bk_fg) {
                fnClearFlag(FLAG_HOME_TRIPLE);
                fnSetFlag(FLAG_MYM_TRIPLE);
            } else {
                fnSetFlag(FLAG_HOME_TRIPLE);
                fnClearFlag(FLAG_MYM_TRIPLE);
            }
            fnShowVersion(choice);
        },
        USER_KRESET => {
            fnShowVersion(choice);
            z47_frontier_keys_user_layout_reset_case();
        },
        USER_HRESET => {
            createHOME();
            showSoftmenu(-MNU_HOME);
            fnShowVersion(choice);
        },
        USER_PRESET => {
            createPFN();
            showSoftmenu(-MNU_PFN);
            fnShowVersion(choice);
        },
        USER_MRESET => {
            fnRESET_MyM(0);
            fnShowVersion(choice);
        },
        USER_ARESET => {
            fnRESET_Mya();
            fnShowVersion(choice);
        },
        ITM_RIBBON_C47, ITM_RIBBON_R47 => {
            fnRESET_MyM(choice);
            fnShowVersion(choice);
            showSoftmenu(-MNU_MyMenu);
        },
        else => {},
    }
}

pub export fn fnPlotStat(plot_mode: u16) callconv(.c) void {
    var mode = plot_mode;

    switch (mode) {
        PLOT_ORTHOF, PLOT_START, PLOT_REV, PLOT_NXT, PLOT_LR => {
            drawHistogram = 0;
            z47_frontier_plot_set_plotstatmx_stats();
        },
        H_PLOT => {
            drawHistogram = 1;
            z47_frontier_plot_set_plotstatmx_histo();
        },
        H_NORM => {
            drawHistogram = 1;
            z47_frontier_plot_set_statmx_histo();
            calcSigma(0);
            mode = PLOT_LR;
            lastPlotMode = PLOT_START;
            lrSelectionHistobackup = lrSelection;
            lrChosenHistobackup = lrChosen;
            fnCurveFitting(CF_GAUSS_FITTING);
        },
        else => {},
    }

    if (!(calcMode == CM_PLOT_STAT or calcMode == CM_GRAPH)) {
        z47_frontier_plot_clear_screen_for_graph_entry();
    }

    hourGlassIconEnabled = true;
    showHideHourGlass();
    refreshStatusBar();

    if (z47_frontier_plot_has_source_data()) {
        clearSystemFlag(FLAG_SCALE);

        if (!(lastPlotMode == PLOT_NOTHING or lastPlotMode == PLOT_START)) {
            mode = lastPlotMode;
        }
        calcMode = CM_PLOT_STAT;
        statGraphReset();

        if (mode == PLOT_START) {
            plotSelection = 0;
            roundedTicks = false;
        } else {
            if (mode == PLOT_LR and lrSelection != 0) {
                plotSelection = lrSelection;
                roundedTicks = false;
            } else if (mode == H_PLOT or mode == H_NORM) {
                calcMode = CM_PLOT_STAT;
            }
        }

        refreshLcd(null);

        switch (mode) {
            H_PLOT, H_NORM => showSoftmenu(-MNU_HPLOT),
            PLOT_LR => {
                if (drawHistogram == 0) {
                    showSoftmenu(-MNU_PLOT_ASSESS);
                } else {
                    showSoftmenu(-MNU_HPLOT);
                }
            },
            PLOT_NXT, PLOT_REV => showSoftmenu(-MNU_PLOT_ASSESS),
            PLOT_ORTHOF, PLOT_START => {
                setSystemFlag(FLAG_SCALE);
                showSoftmenu(-MNU_PLOT_SCATR);
            },
            PLOT_NOTHING => {},
            else => {},
        }

        if ((mode != PLOT_START) and (mode != H_PLOT) and (mode != H_NORM)) {
            fnPlotRegressionLine(mode);
        } else {
            lastPlotMode = mode;
        }
        return;
    }

    calcMode = CM_NORMAL;
    displayCalcErrorMessage(ERROR_NO_SUMMATION_DATA, ERR_REGISTER_LINE, REGISTER_X);
}

pub export fn getIRegisterAsInt(as_array_pointer: bool) callconv(.c) i16 {
    return z47_frontier_matrix_get_register_as_int(REGISTER_I, as_array_pointer);
}

pub export fn getJRegisterAsInt(as_array_pointer: bool) callconv(.c) i16 {
    return z47_frontier_matrix_get_register_as_int(REGISTER_J, as_array_pointer);
}

pub export fn setIRegisterAsInt(as_array_pointer: bool, to_store: i16) callconv(.c) void {
    z47_frontier_matrix_set_register_as_int(REGISTER_I, as_array_pointer, to_store);
}

pub export fn setJRegisterAsInt(as_array_pointer: bool, to_store: i16) callconv(.c) void {
    z47_frontier_matrix_set_register_as_int(REGISTER_J, as_array_pointer, to_store);
}

fn matrixLastRow(rows: u16) i16 {
    return @as(i16, @intCast(rows - 1));
}

fn matrixLastCol(cols: u16) i16 {
    return @as(i16, @intCast(cols - 1));
}

fn matrixWrapEdgeFlag() void {
    setSystemFlag(FLAG_WRAPEDG);
}

fn matrixWrapEndFlag() void {
    setSystemFlag(FLAG_WRAPEND);
}

fn matrixAtTopLeft() bool {
    return getIRegisterAsInt(true) == 0 and getJRegisterAsInt(true) == 0;
}

fn matrixAtBottomRight(rows: u16, cols: u16) bool {
    return getIRegisterAsInt(true) == matrixLastRow(rows) and getJRegisterAsInt(true) == matrixLastCol(cols);
}

fn matrixAdvanceIByOneWithGrow(rows: u16) void {
    const reached_last_row = getIRegisterAsInt(true) == matrixLastRow(rows);
    const should_wrap_to_top = !getSystemFlag(@as(c_int, @intCast(FLAG_GROW))) and reached_last_row;
    if (should_wrap_to_top) {
        setIRegisterAsInt(true, 0);
    } else {
        setIRegisterAsInt(true, getIRegisterAsInt(true) + 1);
    }
}

fn matrixDecIWithBottomWrap(rows: u16) void {
    if (getIRegisterAsInt(true) == 0) {
        setIRegisterAsInt(true, matrixLastRow(rows));
    } else {
        setIRegisterAsInt(true, getIRegisterAsInt(true) - 1);
    }
}

fn matrixIncJWithLeftWrap(cols: u16) void {
    if (getJRegisterAsInt(true) == matrixLastCol(cols)) {
        setJRegisterAsInt(true, 0);
    } else {
        setJRegisterAsInt(true, getJRegisterAsInt(true) + 1);
    }
}

fn matrixDecJWithRightWrap(cols: u16) void {
    if (getJRegisterAsInt(true) == 0) {
        setJRegisterAsInt(true, matrixLastCol(cols));
    } else {
        setJRegisterAsInt(true, getJRegisterAsInt(true) - 1);
    }
}

fn matrixWrapNegativeI(rows: u16, cols: u16) void {
    setIRegisterAsInt(true, matrixLastRow(rows));
    matrixWrapEdgeFlag();
    matrixDecJWithRightWrap(cols);
    if (matrixAtBottomRight(rows, cols)) {
        matrixWrapEndFlag();
    }
}

fn matrixWrapOverflowI(rows: u16, cols: u16) void {
    _ = rows;
    setIRegisterAsInt(true, 0);
    matrixWrapEdgeFlag();
    matrixIncJWithLeftWrap(cols);
    if (matrixAtTopLeft()) {
        matrixWrapEndFlag();
    }
}

fn matrixWrapNegativeJ(rows: u16, cols: u16) void {
    setJRegisterAsInt(true, matrixLastCol(cols));
    matrixWrapEdgeFlag();
    matrixDecIWithBottomWrap(rows);
    if (matrixAtBottomRight(rows, cols)) {
        matrixWrapEndFlag();
    }
}

fn matrixWrapOverflowJ(rows: u16, cols: u16) void {
    _ = cols;
    setJRegisterAsInt(true, 0);
    matrixWrapEdgeFlag();
    matrixAdvanceIByOneWithGrow(rows);
    if (matrixAtTopLeft()) {
        matrixWrapEndFlag();
    }
}

fn matrixModeUndefinedError() void {
    displayCalcErrorMessage(ERROR_OPERATION_UNDEFINED, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
}

fn matrixInEditorMode() bool {
    return calcMode == CM_MIM;
}

fn matrixPrepareMutation() bool {
    if (calcMode != CM_MIM) {
        matrixModeUndefinedError();
        return false;
    }
    mimEnter(false);
    return true;
}

fn matrixFinishMutation() void {
    mimEnter(true);
}

fn matrixCommitPositionChange(row: u16, col: u16) void {
    z47_frontier_matrix_commit_open_to_register();
    setIRegisterAsInt(false, @as(i16, @intCast(row)));
    setJRegisterAsInt(false, @as(i16, @intCast(col)));
    z47_frontier_matrix_calc_mode_normal_gui();
}

pub export fn wrapIJ(rows: u16, cols: u16) callconv(.c) bool {
    clearSystemFlag(FLAG_WRAPEDG);
    clearSystemFlag(FLAG_WRAPEND);

    if (getIRegisterAsInt(true) < 0) {
        matrixWrapNegativeI(rows, cols);
    } else {
        if (getIRegisterAsInt(true) == @as(i16, @intCast(rows))) {
            matrixWrapOverflowI(rows, cols);
        }
    }

    if (getJRegisterAsInt(true) < 0) {
        matrixWrapNegativeJ(rows, cols);
    } else {
        if (getJRegisterAsInt(true) == @as(i16, @intCast(cols))) {
            matrixWrapOverflowJ(rows, cols);
        }
    }

    return getIRegisterAsInt(true) == @as(i16, @intCast(rows));
}

pub export fn fnEditMatrix(regist: u16) callconv(.c) void {
    const reg: u16 = if (regist == NOPARAM) @as(u16, @intCast(REGISTER_X)) else regist;

    if (z47_frontier_matrix_is_register_matrix_vector(reg) and z47_frontier_matrix_vector_polar_mode(reg) != 0) {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
        return;
    }

    leaveTamModeIfEnabled();
    saveStatsMatrix();

    const dt = getRegisterDataType(@as(i16, @intCast(reg)));
    if (dt == dtReal34Matrix or dt == dtComplex34Matrix) {
        calcMode = CM_MIM;
        matrixIndex = reg;
        getMatrixFromRegister(reg);

        setIRegisterAsInt(true, 0);
        setJRegisterAsInt(true, 0);
        aimBuffer[0] = 0;
        nimBufferDisplay[0] = 0;

        showMatrixEditor();
        refreshScreen(80);
        printTraceMatElement(@as(u16, @intCast(LINE_FULL)));
        return;
    }

    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
}

pub export fn fnOldMatrix(unused_param_but_mandatory: u16) callconv(.c) void {
    _ = unused_param_but_mandatory;
    if (calcMode == CM_MIM) {
        aimBuffer[0] = 0;
        nimBufferDisplay[0] = 0;
        z47_frontier_matrix_hide_cursor();
        z47_frontier_matrix_reload_open_matrix_from_register();
        return;
    }
    displayCalcErrorMessage(ERROR_OPERATION_UNDEFINED, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
}

pub export fn fnGoToElement(unused_param_but_mandatory: u16) callconv(.c) void {
    _ = unused_param_but_mandatory;
    if (calcMode == CM_MIM) {
        mimEnter(false);
        runFunction(ITM_M_GOTO_ROW);
        return;
    }
    displayCalcErrorMessage(ERROR_OPERATION_UNDEFINED, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
}

pub export fn fnGoToRow(row: u16) callconv(.c) void {
    if (calcMode == CM_MIM) {
        tmpRow = row;
        return;
    }
    displayCalcErrorMessage(ERROR_OPERATION_UNDEFINED, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
}

pub export fn fnGoToColumn(col: u16) callconv(.c) void {
    if (calcMode == CM_MIM) {
        const rows = z47_frontier_matrix_open_rows();
        const cols = z47_frontier_matrix_open_cols();

        if (tmpRow == 0 or tmpRow > rows or col == 0 or col > cols) {
            displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, @as(i16, @intCast(REGISTER_X)));
            return;
        }

        z47_frontier_matrix_commit_open_to_register();
        setIRegisterAsInt(false, @as(i16, @intCast(tmpRow)));
        setJRegisterAsInt(false, @as(i16, @intCast(col)));
        z47_frontier_matrix_calc_mode_normal_gui();
        return;
    }
    displayCalcErrorMessage(ERROR_OPERATION_UNDEFINED, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
}

pub export fn fnSetGrowMode(grow_flag: u16) callconv(.c) void {
    if (grow_flag != 0) {
        setSystemFlag(FLAG_GROW);
    } else {
        clearSystemFlag(FLAG_GROW);
    }
}

pub export fn fnIncDecI(mode: u16) callconv(.c) void {
    if (calcMode == CM_MIM) {
        z47_frontier_matrix_inc_dec_i(mode);
        return;
    }
    displayCalcErrorMessage(ERROR_OPERATION_UNDEFINED, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
}

pub export fn fnIncDecJ(mode: u16) callconv(.c) void {
    if (calcMode == CM_MIM) {
        z47_frontier_matrix_inc_dec_j(mode);
        return;
    }
    displayCalcErrorMessage(ERROR_OPERATION_UNDEFINED, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
}

pub export fn _fnInsRow(add: bool) callconv(.c) void {
    if (calcMode == CM_MIM) {
        mimEnter(false);
        z47_frontier_matrix_insert_row(add);
        mimEnter(true);
        return;
    }
    displayCalcErrorMessage(ERROR_OPERATION_UNDEFINED, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
}

pub export fn _fnInsCol(add: bool) callconv(.c) void {
    if (calcMode == CM_MIM) {
        mimEnter(false);
        z47_frontier_matrix_insert_col(add);
        mimEnter(true);
        return;
    }
    displayCalcErrorMessage(ERROR_OPERATION_UNDEFINED, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
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
    if (calcMode == CM_MIM) {
        mimEnter(false);
        z47_frontier_matrix_delete_row();
        mimEnter(true);
        return;
    }
    displayCalcErrorMessage(ERROR_OPERATION_UNDEFINED, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
}

pub export fn fnDelCol(unused_param_but_mandatory: u16) callconv(.c) void {
    _ = unused_param_but_mandatory;
    if (calcMode == CM_MIM) {
        mimEnter(false);
        z47_frontier_matrix_delete_col();
        mimEnter(true);
        return;
    }
    displayCalcErrorMessage(ERROR_OPERATION_UNDEFINED, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
}

pub export fn mimFinalize() callconv(.c) void {
    z47_frontier_matrix_finalize_open_matrix_memory();
    matrixIndex = INVALID_VARIABLE;
}

pub export fn mimRestore() callconv(.c) void {
    const idx = matrixIndex;
    mimFinalize();
    if (idx != INVALID_VARIABLE) {
        getMatrixFromRegister(idx);
        matrixIndex = idx;
    }
}

pub export fn mimAddNumber(item: i16) callconv(.c) void {
    if (calcMode == CM_MIM) {
        runtime.z47_frontier_retained_mimAddNumber(item);
        return;
    }
    displayCalcErrorMessage(ERROR_OPERATION_UNDEFINED, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
}

pub export fn mimRunFunction(func: i16, param: u16) callconv(.c) void {
    if (calcMode == CM_MIM) {
        runtime.z47_frontier_retained_mimRunFunction(func, param);
        return;
    }
    displayCalcErrorMessage(ERROR_OPERATION_UNDEFINED, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
}

pub export fn fnClPAll(confirmation: u16) callconv(.c) void {
    if (confirmation == NOT_CONFIRMED) {
        setConfirmationMode(&fnClPAll);
        return;
    }

    removeUserItemAssignments(3, "");

    const was_in_ram = z47_frontier_program_current_program_in_ram();
    resizeProgramMemory(1);

    beginOfProgramMemory[0] = @as(u8, @intCast((ITM_END >> 8) | 0x80));
    beginOfProgramMemory[1] = @as(u8, @intCast(ITM_END & 0xff));
    beginOfProgramMemory[2] = 255;
    beginOfProgramMemory[3] = 255;

    firstFreeProgramByte = beginOfProgramMemory + 2;
    freeProgramBytes = 0;
    temporaryInformation = TI_NO_INFO;
    programRunStop = PGM_STOPPED;

    if (was_in_ram) {
        currentStep = beginOfProgramMemory;
        firstDisplayedStep = beginOfProgramMemory;
        firstDisplayedLocalStepNumber = 0;
        currentLocalStepNumber = 1;
        beginOfCurrentProgram = beginOfProgramMemory;
        endOfCurrentProgram = firstFreeProgramByte;
    }

    scanLabelsAndPrograms();
    if (programRunStop != PGM_RUNNING) {
        temporaryInformation = TI_DEL_ALL_PRGMS;
    } else {
        temporaryInformation = TI_NO_INFO;
    }
    screenUpdatingMode = SCRUPD_AUTO;
}

pub export fn fnPlotRegressionLine(plot_mode: u16) callconv(.c) void {
    switch (plot_mode) {
        PLOT_ORTHOF => {
            plotSelection = CF_ORTHOGONAL_FITTING;
            lrChosen = CF_ORTHOGONAL_FITTING;
        },
        PLOT_NXT => {
            plotSelection = plotSelection << 1;
            if (plotSelection == 0) {
                plotSelection = 1;
            }

            while ((plotSelection != ((if (lrSelection == 0) @as(u16, 1023) else lrSelection) & plotSelection)) and (plotSelection < 1024)) {
                plotSelection = plotSelection << 1;
            }

            if (plotSelection >= 1024) {
                plotSelection = 0;
            }
        },
        PLOT_REV => {
            if (plotSelection == 0) {
                plotSelection = 1024;
            }
            plotSelection = plotSelection >> 1;
            if (plotSelection >= 1024) {
                plotSelection = 0;
            }

            while ((plotSelection != ((if (lrSelection == 0) @as(u16, 1023) else lrSelection) & plotSelection)) and (plotSelection < 1024) and (plotSelection > 0)) {
                plotSelection = plotSelection >> 1;
            }
        },
        PLOT_LR => {
            plotSelection = lrChosen;
            if (plotSelection == 0) {
                plotSelection = 1;
            }
            while ((plotSelection != ((if (lrSelection == 0) @as(u16, 1023) else lrSelection) & plotSelection)) and (plotSelection < 1024)) {
                plotSelection = plotSelection << 1;
            }
            if (plotSelection >= 1024) {
                plotSelection = 0;
            }
        },
        PLOT_START, PLOT_NOTHING => {},
        else => {},
    }
}