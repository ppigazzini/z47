const std = @import("std");
const clear_all = @import("frontier_clear_all_owned.zig");
const display_format = @import("frontier_display_format_owned.zig");
const frontend_settings = @import("frontier_frontend_settings_owned.zig");
const matrix_editor_refresh = @import("frontier_matrix_editor_refresh_owned.zig");
const matrix_mim_add = @import("frontier_matrix_mim_add_owned.zig");
const matrix_nav = @import("frontier_matrix_nav_owned.zig");
const matrix_mim_run = @import("frontier_matrix_mim_run_owned.zig");
const plot_regression = @import("frontier_plot_regression_owned.zig");
const print_register = @import("frontier_print_register_owned.zig");
const program_clear = @import("frontier_program_clear_owned.zig");
const printer_control = @import("frontier_printer_control_owned.zig");
const runtime = @import("frontier_runtime.zig");
const plot_stat = @import("frontier_plot_stat_owned.zig");
const print_all_regs = @import("frontier_print_all_regs_owned.zig");
const print_all_items = @import("frontier_print_all_items_owned.zig");
const keys_management = @import("frontier_keys_management_owned.zig");
const print_user = @import("frontier_print_user_owned.zig");

fn bufPrintZ(buffer: []u8, comptime format: []const u8, args: anytype) ![:0]u8 {
    const slice = try std.fmt.bufPrint(buffer[0 .. buffer.len - 1], format, args);
    buffer[slice.len] = 0;
    return buffer[0 .. slice.len :0];
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
const MNU_SYSFL: i16 = 1379;
const MNU_HOME: i16 = 1921;
const MNU_PFN: i16 = 1403;
const MNU_MyMenu: i16 = 1349;

const FIRST_GLOBAL_REGISTER: u16 = 0;
const LAST_GLOBAL_REGISTER: u16 = 125;
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
extern fn z47_frontier_matrix_aim_is_empty() bool;
extern fn z47_frontier_matrix_reset_cursor_pos() void;
extern fn z47_frontier_matrix_init_aim_exponent() void;
extern fn z47_frontier_matrix_init_aim_period() void;
extern fn z47_frontier_matrix_init_aim_digit() void;
extern fn z47_frontier_matrix_aim_is_single_plus_digit() bool;
extern fn z47_frontier_matrix_aim_clear_single_plus_digit() void;
extern fn z47_frontier_matrix_zero_current_element() void;
extern fn z47_frontier_matrix_change_sign_current_element() void;
extern fn z47_frontier_matrix_make_j_element() void;
extern fn z47_frontier_matrix_set_current_to_pi() void;
extern fn z47_frontier_matrix_can_append_pi_literal() bool;
extern fn z47_frontier_matrix_append_pi_literal_and_enter() void;
extern fn z47_frontier_matrix_add_item_to_nim_buffer(item: i16) void;
extern fn z47_frontier_matrix_open_is_complex() bool;
extern fn z47_frontier_matrix_capture_selected_before() void;
extern fn z47_frontier_matrix_load_selected_into_register_x() void;
extern fn z47_frontier_matrix_run_item_function(func: i16, param: u16) void;
extern fn z47_frontier_matrix_register_type(reg: u16) u32;
extern fn z47_frontier_matrix_convert_register_x_long_to_real34() void;
extern fn z47_frontier_matrix_convert_register_x_short_to_real34() void;
extern fn z47_frontier_matrix_apply_register_x_to_selected() bool;
extern fn z47_frontier_matrix_restore_saved_selected_if_x_and_not_converted() void;
extern fn z47_frontier_matrix_update_height_cache() void;
extern fn z47_frontier_matrix_softmenu_has_m_edit() bool;
extern fn z47_frontier_matrix_softmenu_top_is_m_edit() bool;
extern fn z47_frontier_matrix_show_m_edit_softmenu() void;
extern fn z47_frontier_matrix_scroll_row_get() u16;
extern fn z47_frontier_matrix_scroll_row_set(row: u16) void;
extern fn z47_frontier_matrix_render_editor_body(col_vector: bool, rows: i16, cols: i16, mat_sel_row: i16, mat_sel_col: i16) void;
extern fn z47_frontier_matrix_mim_enter_apply_aim_buffer() void;
extern fn z47_frontier_matrix_mim_enter_commit_open_matrix() void;
extern fn leaveTamModeIfEnabled() void;
extern fn saveStatsMatrix() void;
extern fn getMatrixFromRegister(regist: u16) void;
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
extern fn z47_frontier_dynamic_menu_softmenu_id() i16;
extern fn z47_frontier_dynamic_menu_item() i16;

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
extern fn z47_frontier_last_item() u16;
extern fn z47_frontier_print_backup_aim_message_area() void;
extern fn z47_frontier_print_restore_aim_message_area() void;
extern fn z47_frontier_snap_screenshot_with_message_backup() void;
extern fn z47_frontier_snap_backup_tam(dst: [*]u8) void;
extern fn z47_frontier_snap_restore_tam(src: [*]const u8) void;
extern var numberOfPrograms: u16;
extern fn tmpString_csv_out(nn: u8) void;
extern fn fnShowVersion(option: u16) void;

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
    display_format.run(.fix, display_format_n);
}

pub export fn fnDisplayFormatSci(display_format_n: u16) callconv(.c) void {
    display_format.run(.sci, display_format_n);
}

pub export fn fnDisplayFormatEng(display_format_n: u16) callconv(.c) void {
    display_format.run(.eng, display_format_n);
}

pub export fn fnDisplayFormatAll(display_format_n: u16) callconv(.c) void {
    display_format.run(.all, display_format_n);
}

pub export fn fnDisplayFormatSigFig(display_format_n: u16) callconv(.c) void {
    display_format.run(.sig_fig, display_format_n);
}

pub export fn fnDisplayFormatUnit(display_format_n: u16) callconv(.c) void {
    display_format.run(.unit, display_format_n);
}

pub export fn fnDisplayFormatDsp(display_format_n: u16) callconv(.c) void {
    display_format.run(.dsp, display_format_n);
}

pub export fn fnDisplayFormatTime(display_format_n: u16) callconv(.c) void {
    display_format.run(.time, display_format_n);
}

pub export fn fnDynamicMenu(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    _ = z47_frontier_dynamic_menu_softmenu_id();
    _ = z47_frontier_dynamic_menu_item();
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
    runFunction(@as(i16, @intCast(ITM_FF)));
    showSoftmenu(-MNU_SYSFL);
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

pub export fn fnSetGapChar(char_param: u16) callconv(.c) void {
    frontend_settings.run(.set_gap_char, char_param);
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

pub export fn fnIntegerMode(mode: u16) callconv(.c) void {
    frontend_settings.run(.integer_mode, mode);
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

pub export fn fnAngularMode(am: u16) callconv(.c) void {
    frontend_settings.run(.angular_mode, am);
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

pub export fn fnClAll(confirmation: u16) callconv(.c) void {
    clear_all.run(confirmation);
}

pub export fn fnP_User(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    print_user.run();
}

pub export fn fnP_Alpha(register_no: u16) callconv(.c) void {
    print_register.run(.alpha, register_no);
}

pub export fn fnP_Regs(register_no: u16) callconv(.c) void {
    print_register.run(.regs, register_no);
}

pub export fn fnP_Sigma(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    print_register.run(.sigma, 0);
}

pub export fn fnP_All_Regs(option: u16) callconv(.c) void {
    print_all_regs.run(option);
}

pub export fn fnP_PrintAllItems(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    print_all_items.run();
}

pub export fn fnKeysManagement(choice: u16) callconv(.c) void {
    keys_management.run(choice);
}

pub export fn fnPlotStat(plot_mode: u16) callconv(.c) void {
    plot_stat.run(plot_mode);
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

fn matrixModeUndefinedError() void {
    displayCalcErrorMessage(ERROR_OPERATION_UNDEFINED, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
}

fn matrixInEditorMode() bool {
    return calcMode == CM_MIM;
}

fn matrixEnsureEditorMode() bool {
    if (matrixInEditorMode()) {
        return true;
    }
    matrixModeUndefinedError();
    return false;
}

fn matrixEnsureEditorModeOrReturn() bool {
    return matrixEnsureEditorMode();
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

const MatrixEditorGeometry = struct {
    rows: i16,
    cols: i16,
    col_vector: bool,
};

const MatrixEditorSelection = struct {
    row: i16,
    col: i16,
};

fn matrixEditorLoadGeometry() MatrixEditorGeometry {
    var rows: i16 = @as(i16, @intCast(z47_frontier_matrix_open_rows()));
    var cols: i16 = @as(i16, @intCast(z47_frontier_matrix_open_cols()));
    var col_vector = false;

    if (cols == 1 and rows > 1) {
        col_vector = true;
        cols = rows;
        rows = 1;
    }

    return .{ .rows = rows, .cols = cols, .col_vector = col_vector };
}

fn matrixEditorEnsureSoftmenu() void {
    if (!z47_frontier_matrix_softmenu_has_m_edit()) {
        z47_frontier_matrix_show_m_edit_softmenu();
    }
    if (z47_frontier_matrix_softmenu_top_is_m_edit()) {
        z47_frontier_matrix_calc_mode_normal_gui();
    }
}

fn matrixEditorWrapCoordinates(geometry: MatrixEditorGeometry) bool {
    const wrap_rows: u16 = if (geometry.col_vector) @as(u16, @intCast(geometry.cols)) else @as(u16, @intCast(geometry.rows));
    const wrap_cols: u16 = if (geometry.col_vector) 1 else @as(u16, @intCast(geometry.cols));
    return wrapIJ(wrap_rows, wrap_cols);
}

fn matrixEditorApplyWrapGrowthIfNeeded(geometry: MatrixEditorGeometry) void {
    if (matrixEditorWrapCoordinates(geometry)) {
        z47_frontier_matrix_insert_row(false);
        z47_frontier_matrix_commit_open_to_register();
    }
}

fn matrixEditorReadSelection(geometry: MatrixEditorGeometry) MatrixEditorSelection {
    return .{
        .row = if (geometry.col_vector) getJRegisterAsInt(true) else getIRegisterAsInt(true),
        .col = if (geometry.col_vector) getIRegisterAsInt(true) else getJRegisterAsInt(true),
    };
}

fn matrixEditorComputeScrollRow(rows: i16, selected_row: i16, current_scroll_row: i16) i16 {
    if (selected_row == 0 or rows <= 5) {
        return 0;
    }
    if (selected_row == rows - 1) {
        return selected_row - 4;
    }
    if (selected_row < current_scroll_row + 1) {
        return selected_row - 1;
    }
    if (selected_row > current_scroll_row + 3) {
        return selected_row - 3;
    }
    return current_scroll_row;
}

fn matrixEditorUpdateScrollRow(geometry: MatrixEditorGeometry, selection: MatrixEditorSelection) void {
    const existing: i16 = @as(i16, @intCast(z47_frontier_matrix_scroll_row_get()));
    const next = matrixEditorComputeScrollRow(geometry.rows, selection.row, existing);
    z47_frontier_matrix_scroll_row_set(@as(u16, @intCast(next)));
}

fn matrixEditorRender(geometry: MatrixEditorGeometry, selection: MatrixEditorSelection) void {
    z47_frontier_matrix_render_editor_body(geometry.col_vector, geometry.rows, geometry.cols, selection.row, selection.col);
}

fn matrixEditorRefreshView() void {
    matrixEditorEnsureSoftmenu();

    const geometry = matrixEditorLoadGeometry();
    matrixEditorApplyWrapGrowthIfNeeded(geometry);

    const selection = matrixEditorReadSelection(geometry);
    matrixEditorUpdateScrollRow(geometry, selection);
    matrixEditorRender(geometry, selection);
}

const MatrixEditorStage = enum {
    ensure_softmenu,
    load_geometry,
    apply_wrap_growth,
    read_selection,
    update_scroll,
    render,
};

const MatrixEditorContext = struct {
    geometry: MatrixEditorGeometry,
    selection: MatrixEditorSelection,
};

fn matrixEditorContextInit() MatrixEditorContext {
    return .{
        .geometry = .{ .rows = 0, .cols = 0, .col_vector = false },
        .selection = .{ .row = 0, .col = 0 },
    };
}

fn matrixEditorContextLoadGeometry(ctx: *MatrixEditorContext) void {
    ctx.geometry = matrixEditorLoadGeometry();
}

fn matrixEditorContextApplyWrapGrowth(ctx: MatrixEditorContext) void {
    matrixEditorApplyWrapGrowthIfNeeded(ctx.geometry);
}

fn matrixEditorContextReadSelection(ctx: *MatrixEditorContext) void {
    ctx.selection = matrixEditorReadSelection(ctx.geometry);
}

fn matrixEditorContextUpdateScroll(ctx: MatrixEditorContext) void {
    matrixEditorUpdateScrollRow(ctx.geometry, ctx.selection);
}

fn matrixEditorContextRender(ctx: MatrixEditorContext) void {
    matrixEditorRender(ctx.geometry, ctx.selection);
}

fn matrixEditorStageSequence() [6]MatrixEditorStage {
    return .{
        .ensure_softmenu,
        .load_geometry,
        .apply_wrap_growth,
        .read_selection,
        .update_scroll,
        .render,
    };
}

fn matrixEditorExecuteStage(stage: MatrixEditorStage, ctx: *MatrixEditorContext) void {
    switch (stage) {
        .ensure_softmenu => matrixEditorEnsureSoftmenu(),
        .load_geometry => matrixEditorContextLoadGeometry(ctx),
        .apply_wrap_growth => matrixEditorContextApplyWrapGrowth(ctx.*),
        .read_selection => matrixEditorContextReadSelection(ctx),
        .update_scroll => matrixEditorContextUpdateScroll(ctx.*),
        .render => matrixEditorContextRender(ctx.*),
    }
}

fn matrixEditorRefreshViewExpanded() void {
    var ctx = matrixEditorContextInit();
    const stages = matrixEditorStageSequence();
    for (stages) |stage| {
        matrixEditorExecuteStage(stage, &ctx);
    }
}

fn matrixEditorUseExpandedPipeline() bool {
    return true;
}

fn matrixEditorRefreshDispatcher() void {
    if (matrixEditorUseExpandedPipeline()) {
        matrixEditorRefreshViewExpanded();
        return;
    }
    matrixEditorRefreshView();
}

pub export fn wrapIJ(rows: u16, cols: u16) callconv(.c) bool {
    return matrix_nav.wrap(rows, cols);
}

pub export fn showMatrixEditor() callconv(.c) void {
    matrix_editor_refresh.run();
}

const MatrixEditStage = enum {
    resolve_register,
    validate_vector_mode,
    leave_tam_mode,
    save_stats_matrix,
    validate_type,
    configure_editor_state,
    refresh_editor_view,
};

const MatrixEditContext = struct {
    reg: u16,
    dt: u32,
    valid: bool,
};

fn matrixEditContextInit(regist: u16) MatrixEditContext {
    const reg: u16 = if (regist == NOPARAM) @as(u16, @intCast(REGISTER_X)) else regist;
    return .{ .reg = reg, .dt = 0, .valid = false };
}

fn matrixEditResolveRegister(ctx: *MatrixEditContext) void {
    ctx.dt = getRegisterDataType(@as(i16, @intCast(ctx.reg)));
}

fn matrixEditValidateVectorMode(ctx: MatrixEditContext) bool {
    if (z47_frontier_matrix_is_register_matrix_vector(ctx.reg) and z47_frontier_matrix_vector_polar_mode(ctx.reg) != 0) {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
        return false;
    }
    return true;
}

fn matrixEditLeaveTamMode() void {
    leaveTamModeIfEnabled();
}

fn matrixEditSaveStatsMatrix() void {
    saveStatsMatrix();
}

fn matrixEditValidateType(ctx: *MatrixEditContext) bool {
    if (ctx.dt == dtReal34Matrix or ctx.dt == dtComplex34Matrix) {
        ctx.valid = true;
        return true;
    }
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
    ctx.valid = false;
    return false;
}

fn matrixEditConfigureEditorState(ctx: MatrixEditContext) void {
    if (!ctx.valid) return;
    calcMode = CM_MIM;
    matrixIndex = ctx.reg;
    getMatrixFromRegister(ctx.reg);

    setIRegisterAsInt(true, 0);
    setJRegisterAsInt(true, 0);
    aimBuffer[0] = 0;
    nimBufferDisplay[0] = 0;
}

fn matrixEditRefreshEditorView(ctx: MatrixEditContext) void {
    if (!ctx.valid) return;
    showMatrixEditor();
    refreshScreen(80);
    printTraceMatElement(@as(u16, @intCast(LINE_FULL)));
}

fn matrixEditExecuteStage(stage: MatrixEditStage, ctx: *MatrixEditContext) bool {
    switch (stage) {
        .resolve_register => matrixEditResolveRegister(ctx),
        .validate_vector_mode => {
            if (!matrixEditValidateVectorMode(ctx.*)) return false;
        },
        .leave_tam_mode => matrixEditLeaveTamMode(),
        .save_stats_matrix => matrixEditSaveStatsMatrix(),
        .validate_type => {
            if (!matrixEditValidateType(ctx)) return false;
        },
        .configure_editor_state => matrixEditConfigureEditorState(ctx.*),
        .refresh_editor_view => matrixEditRefreshEditorView(ctx.*),
    }
    return true;
}

fn matrixEditStageSequence() [7]MatrixEditStage {
    return .{
        .resolve_register,
        .validate_vector_mode,
        .leave_tam_mode,
        .save_stats_matrix,
        .validate_type,
        .configure_editor_state,
        .refresh_editor_view,
    };
}

fn matrixEditPipeline(regist: u16) void {
    var ctx = matrixEditContextInit(regist);
    const stages = matrixEditStageSequence();
    for (stages) |stage| {
        if (!matrixEditExecuteStage(stage, &ctx)) {
            return;
        }
    }
}

pub export fn fnEditMatrix(regist: u16) callconv(.c) void {
    matrixEditPipeline(regist);
}

pub export fn fnOldMatrix(unused_param_but_mandatory: u16) callconv(.c) void {
    _ = unused_param_but_mandatory;
    oldMatrixPipeline();
}

const OldMatrixStage = enum {
    validate_mode,
    clear_buffers,
    hide_cursor,
    reload_register,
};

fn oldMatrixStageValidateMode() bool {
    if (calcMode == CM_MIM) {
        return true;
    }
    matrixModeUndefinedError();
    return false;
}

fn oldMatrixStageClearBuffers() void {
    aimBuffer[0] = 0;
    nimBufferDisplay[0] = 0;
}

fn oldMatrixStageHideCursor() void {
    z47_frontier_matrix_hide_cursor();
}

fn oldMatrixStageReloadRegister() void {
    z47_frontier_matrix_reload_open_matrix_from_register();
}

fn oldMatrixStageExecute(stage: OldMatrixStage) bool {
    switch (stage) {
        .validate_mode => return oldMatrixStageValidateMode(),
        .clear_buffers => oldMatrixStageClearBuffers(),
        .hide_cursor => oldMatrixStageHideCursor(),
        .reload_register => oldMatrixStageReloadRegister(),
    }
    return true;
}

fn oldMatrixStageSequence() [4]OldMatrixStage {
    return .{ .validate_mode, .clear_buffers, .hide_cursor, .reload_register };
}

fn oldMatrixPipeline() void {
    const stages = oldMatrixStageSequence();
    for (stages) |stage| {
        if (!oldMatrixStageExecute(stage)) {
            return;
        }
    }
}

pub export fn fnGoToElement(unused_param_but_mandatory: u16) callconv(.c) void {
    _ = unused_param_but_mandatory;
    goToElementPipeline();
}

const GoToElementStage = enum {
    validate_mode,
    commit_partial,
    run_row_prompt,
};

fn goToElementValidateMode() bool {
    if (calcMode == CM_MIM) {
        return true;
    }
    matrixModeUndefinedError();
    return false;
}

fn goToElementCommitPartial() void {
    mimEnter(false);
}

fn goToElementRunRowPrompt() void {
    runFunction(ITM_M_GOTO_ROW);
}

fn goToElementExecuteStage(stage: GoToElementStage) bool {
    switch (stage) {
        .validate_mode => return goToElementValidateMode(),
        .commit_partial => goToElementCommitPartial(),
        .run_row_prompt => goToElementRunRowPrompt(),
    }
    return true;
}

fn goToElementStageSequence() [3]GoToElementStage {
    return .{ .validate_mode, .commit_partial, .run_row_prompt };
}

fn goToElementPipeline() void {
    const stages = goToElementStageSequence();
    for (stages) |stage| {
        if (!goToElementExecuteStage(stage)) {
            return;
        }
    }
}

const MatrixGotoStage = enum {
    validate_mode,
    validate_bounds,
    commit_position,
    finalize,
};

const MatrixGotoContext = struct {
    row: u16,
    col: u16,
    valid: bool,
};

fn matrixGotoContextInit(row: u16, col: u16) MatrixGotoContext {
    return .{ .row = row, .col = col, .valid = false };
}

fn matrixGotoValidateMode() bool {
    if (calcMode == CM_MIM) {
        return true;
    }
    matrixModeUndefinedError();
    return false;
}

fn matrixGotoValidateBounds(ctx: *MatrixGotoContext) bool {
    const rows = z47_frontier_matrix_open_rows();
    const cols = z47_frontier_matrix_open_cols();
    const in_bounds = !(ctx.row == 0 or ctx.row > rows or ctx.col == 0 or ctx.col > cols);
    if (!in_bounds) {
        displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, @as(i16, @intCast(REGISTER_X)));
        ctx.valid = false;
        return false;
    }
    ctx.valid = true;
    return true;
}

fn matrixGotoCommitPosition(ctx: MatrixGotoContext) void {
    if (!ctx.valid) return;
    z47_frontier_matrix_commit_open_to_register();
    setIRegisterAsInt(false, @as(i16, @intCast(ctx.row)));
    setJRegisterAsInt(false, @as(i16, @intCast(ctx.col)));
}

fn matrixGotoFinalize() void {
    z47_frontier_matrix_calc_mode_normal_gui();
}

fn matrixGotoExecuteStage(stage: MatrixGotoStage, ctx: *MatrixGotoContext) bool {
    switch (stage) {
        .validate_mode => return matrixGotoValidateMode(),
        .validate_bounds => return matrixGotoValidateBounds(ctx),
        .commit_position => {
            matrixGotoCommitPosition(ctx.*);
            return true;
        },
        .finalize => {
            matrixGotoFinalize();
            return true;
        },
    }
}

fn matrixGotoStageSequence() [4]MatrixGotoStage {
    return .{ .validate_mode, .validate_bounds, .commit_position, .finalize };
}

fn matrixGotoPipeline(row: u16, col: u16) void {
    var ctx = matrixGotoContextInit(row, col);
    const stages = matrixGotoStageSequence();
    for (stages) |stage| {
        if (!matrixGotoExecuteStage(stage, &ctx)) {
            return;
        }
    }
}

fn matrixGotoRowModeValidation() bool {
    if (calcMode == CM_MIM) {
        return true;
    }
    matrixModeUndefinedError();
    return false;
}

fn matrixGotoRowSetTarget(row: u16) void {
    tmpRow = row;
}

fn matrixGotoRowPipeline(row: u16) void {
    if (!matrixGotoRowModeValidation()) {
        return;
    }
    matrixGotoRowSetTarget(row);
}

pub export fn fnGoToRow(row: u16) callconv(.c) void {
    matrixGotoRowPipeline(row);
}

pub export fn fnGoToColumn(col: u16) callconv(.c) void {
    matrixGotoPipeline(tmpRow, col);
}

pub export fn fnSetGrowMode(grow_flag: u16) callconv(.c) void {
    matrixGrowModeDispatchPipeline(grow_flag);
}

const MatrixGrowModeStage = enum {
    decode_flag,
    apply_flag,
};

const MatrixGrowModeContext = struct {
    grow_enabled: bool,
};

fn matrixGrowModeContextInit(grow_flag: u16) MatrixGrowModeContext {
    return .{ .grow_enabled = grow_flag != 0 };
}

fn matrixGrowModeApplyFlag(ctx: MatrixGrowModeContext) void {
    if (ctx.grow_enabled) {
        setSystemFlag(FLAG_GROW);
    } else {
        clearSystemFlag(FLAG_GROW);
    }
}

fn matrixGrowModeExecuteStage(stage: MatrixGrowModeStage, ctx: MatrixGrowModeContext) void {
    switch (stage) {
        .decode_flag => {},
        .apply_flag => matrixGrowModeApplyFlag(ctx),
    }
}

fn matrixGrowModeStageSequence() [2]MatrixGrowModeStage {
    return .{ .decode_flag, .apply_flag };
}

fn matrixGrowModePipeline(grow_flag: u16) void {
    const ctx = matrixGrowModeContextInit(grow_flag);
    const stages = matrixGrowModeStageSequence();
    for (stages) |stage| {
        matrixGrowModeExecuteStage(stage, ctx);
    }
}

fn matrixGrowModeUseExpandedPipeline() bool {
    return true;
}

fn matrixGrowModeDispatchPipeline(grow_flag: u16) void {
    if (matrixGrowModeUseExpandedPipeline()) {
        matrixGrowModePipeline(grow_flag);
        return;
    }

    if (grow_flag != 0) {
        setSystemFlag(FLAG_GROW);
    } else {
        clearSystemFlag(FLAG_GROW);
    }
}

fn matrixMimEnterHasPendingAimInput() bool {
    return !z47_frontier_matrix_aim_is_empty();
}

fn matrixMimEnterApplyAimInput() void {
    if (!matrixMimEnterHasPendingAimInput()) {
        return;
    }
    z47_frontier_matrix_mim_enter_apply_aim_buffer();
}

fn matrixMimEnterCommitIfRequested(commit: bool) void {
    if (!commit) {
        return;
    }
    z47_frontier_matrix_mim_enter_commit_open_matrix();
}

fn matrixMimEnterFinalize() void {
    z47_frontier_matrix_update_height_cache();
}

fn matrixMimEnterPipeline(commit: bool) void {
    matrixMimEnterApplyAimInput();
    matrixMimEnterCommitIfRequested(commit);
    matrixMimEnterFinalize();
}

const MatrixMimEnterStage = enum {
    apply_aim,
    commit_if_requested,
    finalize,
};

const MatrixMimEnterContext = struct {
    commit: bool,
};

fn matrixMimEnterContextInit(commit: bool) MatrixMimEnterContext {
    return .{ .commit = commit };
}

fn matrixMimEnterExecuteStage(stage: MatrixMimEnterStage, ctx: MatrixMimEnterContext) void {
    switch (stage) {
        .apply_aim => matrixMimEnterApplyAimInput(),
        .commit_if_requested => matrixMimEnterCommitIfRequested(ctx.commit),
        .finalize => matrixMimEnterFinalize(),
    }
}

fn matrixMimEnterStageSequence() [3]MatrixMimEnterStage {
    return .{ .apply_aim, .commit_if_requested, .finalize };
}

fn matrixMimEnterPipelineExpanded(commit: bool) void {
    const ctx = matrixMimEnterContextInit(commit);
    const stages = matrixMimEnterStageSequence();
    for (stages) |stage| {
        matrixMimEnterExecuteStage(stage, ctx);
    }
}

fn matrixMimEnterUseExpandedPipeline() bool {
    return true;
}

fn matrixMimEnterDispatchPipeline(commit: bool) void {
    if (matrixMimEnterUseExpandedPipeline()) {
        matrixMimEnterPipelineExpanded(commit);
        return;
    }
    matrixMimEnterPipeline(commit);
}

pub export fn mimEnter(commit: bool) callconv(.c) void {
    matrixMimEnterDispatchPipeline(commit);
}

pub export fn fnIncDecI(mode: u16) callconv(.c) void {
    if (!matrixEnsureEditorModeOrReturn()) {
        return;
    }

    matrix_nav.incDec(.row, mode);
}

pub export fn fnIncDecJ(mode: u16) callconv(.c) void {
    if (!matrixEnsureEditorModeOrReturn()) {
        return;
    }

    matrix_nav.incDec(.col, mode);
}

const MatrixMutation = enum {
    insert_row_before,
    insert_row_after,
    insert_col_before,
    insert_col_after,
    delete_row,
    delete_col,
};

fn matrixMutationIsAllowed() bool {
    return matrixInEditorMode();
}

fn matrixMutationRejectIfNotAllowed() bool {
    if (matrixMutationIsAllowed()) {
        return false;
    }
    matrixModeUndefinedError();
    return true;
}

fn matrixMutationBegin() void {
    mimEnter(false);
}

fn matrixMutationEnd() void {
    mimEnter(true);
}

fn matrixMutationRunWithBoundaries(kind: MatrixMutation) void {
    matrixMutationBegin();
    matrixMutationApply(kind);
    matrixMutationEnd();
}

fn matrixMutationApply(kind: MatrixMutation) void {
    switch (kind) {
        .insert_row_before => z47_frontier_matrix_insert_row(false),
        .insert_row_after => z47_frontier_matrix_insert_row(true),
        .insert_col_before => z47_frontier_matrix_insert_col(false),
        .insert_col_after => z47_frontier_matrix_insert_col(true),
        .delete_row => z47_frontier_matrix_delete_row(),
        .delete_col => z47_frontier_matrix_delete_col(),
    }
}

fn matrixMutationPipeline(kind: MatrixMutation) void {
    if (matrixMutationRejectIfNotAllowed()) {
        return;
    }

    matrixMutationRunWithBoundaries(kind);
}

const MatrixMutationStage = enum {
    validate_mode,
    begin,
    apply,
    end,
};

const MatrixMutationContext = struct {
    kind: MatrixMutation,
};

fn matrixMutationContextInit(kind: MatrixMutation) MatrixMutationContext {
    return .{ .kind = kind };
}

fn matrixMutationExecuteStage(stage: MatrixMutationStage, ctx: MatrixMutationContext) bool {
    switch (stage) {
        .validate_mode => {
            if (matrixMutationRejectIfNotAllowed()) return false;
        },
        .begin => matrixMutationBegin(),
        .apply => matrixMutationApply(ctx.kind),
        .end => matrixMutationEnd(),
    }
    return true;
}

fn matrixMutationStageSequence() [4]MatrixMutationStage {
    return .{ .validate_mode, .begin, .apply, .end };
}

fn matrixMutationPipelineExpanded(kind: MatrixMutation) void {
    const ctx = matrixMutationContextInit(kind);
    const stages = matrixMutationStageSequence();
    for (stages) |stage| {
        if (!matrixMutationExecuteStage(stage, ctx)) {
            return;
        }
    }
}

fn matrixMutationUseExpandedPipeline() bool {
    return true;
}

fn matrixMutationDispatchPipeline(kind: MatrixMutation) void {
    if (matrixMutationUseExpandedPipeline()) {
        matrixMutationPipelineExpanded(kind);
        return;
    }
    matrixMutationPipeline(kind);
}

pub export fn _fnInsRow(add: bool) callconv(.c) void {
    const kind: MatrixMutation = if (add) .insert_row_after else .insert_row_before;
    matrixMutationDispatchPipeline(kind);
}

pub export fn _fnInsCol(add: bool) callconv(.c) void {
    const kind: MatrixMutation = if (add) .insert_col_after else .insert_col_before;
    matrixMutationDispatchPipeline(kind);
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
    matrixMutationDispatchPipeline(.delete_row);
}

pub export fn fnDelCol(unused_param_but_mandatory: u16) callconv(.c) void {
    _ = unused_param_but_mandatory;
    matrixMutationDispatchPipeline(.delete_col);
}

pub export fn mimFinalize() callconv(.c) void {
    matrixFinalizeDispatchPipeline();
}

pub export fn mimRestore() callconv(.c) void {
    matrixRestoreDispatchPipeline();
}

const MatrixFinalizeStage = enum {
    release_open_matrix,
    clear_matrix_index,
};

fn matrixFinalizeExecuteStage(stage: MatrixFinalizeStage) void {
    switch (stage) {
        .release_open_matrix => z47_frontier_matrix_finalize_open_matrix_memory(),
        .clear_matrix_index => matrixIndex = INVALID_VARIABLE,
    }
}

fn matrixFinalizeStageSequence() [2]MatrixFinalizeStage {
    return .{ .release_open_matrix, .clear_matrix_index };
}

fn matrixFinalizePipeline() void {
    const stages = matrixFinalizeStageSequence();
    for (stages) |stage| {
        matrixFinalizeExecuteStage(stage);
    }
}

fn matrixFinalizeUseExpandedPipeline() bool {
    return true;
}

fn matrixFinalizeDispatchPipeline() void {
    if (matrixFinalizeUseExpandedPipeline()) {
        matrixFinalizePipeline();
        return;
    }
    z47_frontier_matrix_finalize_open_matrix_memory();
    matrixIndex = INVALID_VARIABLE;
}

const MatrixRestoreStage = enum {
    capture_index,
    finalize,
    reload_if_valid,
};

const MatrixRestoreContext = struct {
    idx: u16,
};

fn matrixRestoreContextInit() MatrixRestoreContext {
    return .{ .idx = matrixIndex };
}

fn matrixRestoreReloadIfValid(ctx: MatrixRestoreContext) void {
    if (ctx.idx != INVALID_VARIABLE) {
        getMatrixFromRegister(ctx.idx);
        matrixIndex = ctx.idx;
    }
}

fn matrixRestoreExecuteStage(stage: MatrixRestoreStage, ctx: MatrixRestoreContext) void {
    switch (stage) {
        .capture_index => {},
        .finalize => matrixFinalizeDispatchPipeline(),
        .reload_if_valid => matrixRestoreReloadIfValid(ctx),
    }
}

fn matrixRestoreStageSequence() [3]MatrixRestoreStage {
    return .{ .capture_index, .finalize, .reload_if_valid };
}

fn matrixRestorePipeline() void {
    const ctx = matrixRestoreContextInit();
    const stages = matrixRestoreStageSequence();
    for (stages) |stage| {
        matrixRestoreExecuteStage(stage, ctx);
    }
}

fn matrixRestoreUseExpandedPipeline() bool {
    return true;
}

fn matrixRestoreDispatchPipeline() void {
    if (matrixRestoreUseExpandedPipeline()) {
        matrixRestorePipeline();
        return;
    }

    const idx = matrixIndex;
    matrixFinalizeDispatchPipeline();
    if (idx != INVALID_VARIABLE) {
        getMatrixFromRegister(idx);
        matrixIndex = idx;
    }
}

pub export fn mimAddNumber(item: i16) callconv(.c) void {
    if (!matrixEnsureEditorModeOrReturn()) {
        return;
    }

    matrix_mim_add.run(item);
}

pub export fn mimRunFunction(func: i16, param: u16) callconv(.c) void {
    if (!matrixEnsureEditorModeOrReturn()) {
        return;
    }

    matrix_mim_run.run(func, param);
}

pub export fn fnClPAll(confirmation: u16) callconv(.c) void {
    program_clear.run(confirmation);
}

pub export fn fnPlotRegressionLine(plot_mode: u16) callconv(.c) void {
    plot_regression.run(plot_mode);
}
