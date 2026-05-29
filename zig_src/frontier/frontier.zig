const std = @import("std");
const clear_all = @import("frontier_clear_all_owned.zig");
const display_format = @import("frontier_display_format_owned.zig");
const frontend_settings = @import("frontier_frontend_settings_owned.zig");
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
        var label: [32]u8 = std.mem.zeroes([32]u8);
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

fn matrixMimRunEnterValidation() bool {
    return matrixEnsureEditorModeOrReturn();
}

fn matrixMimRunLiftFlagSnapshot() bool {
    return getSystemFlag(@as(c_int, @intCast(FLAG_ASLIFT)));
}

fn matrixMimRunHasError() bool {
    return lastErrorCode != ERROR_NONE;
}

fn matrixMimRunErrorCode() u8 {
    return lastErrorCode;
}

fn matrixMimRunWasSuccessful() bool {
    return !matrixMimRunHasError();
}

fn matrixMimRunClearErrorState() void {
    lastErrorCode = ERROR_NONE;
}

fn matrixMimRunPrepareExecution() void {
    z47_frontier_matrix_capture_selected_before();
    mimEnter(true);
    clearSystemFlag(FLAG_ASLIFT);
    matrixMimRunClearErrorState();
    z47_frontier_matrix_load_selected_into_register_x();
}

fn matrixMimRunExecute(func: i16, param: u16) void {
    z47_frontier_matrix_run_item_function(func, param);
}

fn matrixMimRunTypeNeedsConversion(register_type: u32) bool {
    return register_type == dtLongInteger or register_type == dtShortInteger;
}

fn matrixMimRunTypeIsAccepted(register_type: u32) bool {
    return register_type == dtReal34 or register_type == dtComplex34;
}

fn matrixMimRunConvertRegisterXToReal34IfNeeded(register_type: u32) void {
    if (register_type == dtLongInteger) {
        z47_frontier_matrix_convert_register_x_long_to_real34();
        return;
    }
    if (register_type == dtShortInteger) {
        z47_frontier_matrix_convert_register_x_short_to_real34();
    }
}

fn matrixMimRunNormalizeRegisterXType() void {
    const register_type = z47_frontier_matrix_register_type(@as(u16, @intCast(REGISTER_X)));
    if (matrixMimRunTypeNeedsConversion(register_type)) {
        matrixMimRunConvertRegisterXToReal34IfNeeded(register_type);
        return;
    }
    if (matrixMimRunTypeIsAccepted(register_type)) {
        return;
    }
    _ = matrixMimRunErrorCode();
    lastErrorCode = ERROR_INVALID_DATA_TYPE_FOR_OP;
}

fn matrixMimRunApplyResultIfValid() bool {
    if (!matrixMimRunWasSuccessful()) {
        return false;
    }
    return z47_frontier_matrix_apply_register_x_to_selected();
}

fn matrixMimRunRestoreLinkedXIfNeeded(converted: bool) void {
    if (matrixIndex == @as(u16, @intCast(REGISTER_X)) and !converted) {
        z47_frontier_matrix_restore_saved_selected_if_x_and_not_converted();
    }
}

fn matrixMimRunRestoreLiftFlag(lift_stack_flag: bool) void {
    if (lift_stack_flag) {
        setSystemFlag(FLAG_ASLIFT);
    }
}

fn matrixMimRunFinalizeView() void {
    z47_frontier_matrix_update_height_cache();
    refreshLcd(null);
}

const MatrixMimRunContext = struct {
    lift_stack_flag: bool,
    converted: bool,
};

fn matrixMimRunContextInit() MatrixMimRunContext {
    return .{
        .lift_stack_flag = matrixMimRunLiftFlagSnapshot(),
        .converted = false,
    };
}

fn matrixMimRunContextSetConverted(ctx: *MatrixMimRunContext, converted: bool) void {
    ctx.converted = converted;
}

fn matrixMimRunContextConverted(ctx: MatrixMimRunContext) bool {
    return ctx.converted;
}

fn matrixMimRunContextRestoreLift(ctx: MatrixMimRunContext) void {
    matrixMimRunRestoreLiftFlag(ctx.lift_stack_flag);
}

fn matrixMimRunApplyAndCapture(ctx: *MatrixMimRunContext) void {
    const converted = matrixMimRunApplyResultIfValid();
    matrixMimRunContextSetConverted(ctx, converted);
}

fn matrixMimRunRestoreLinkedState(ctx: MatrixMimRunContext) void {
    matrixMimRunRestoreLinkedXIfNeeded(matrixMimRunContextConverted(ctx));
}

fn matrixMimRunCommitView(ctx: MatrixMimRunContext) void {
    matrixMimRunRestoreLinkedState(ctx);
    matrixMimRunContextRestoreLift(ctx);
    matrixMimRunFinalizeView();
}

fn matrixMimRunExecuteAndNormalize(func: i16, param: u16) void {
    matrixMimRunExecute(func, param);
    matrixMimRunNormalizeRegisterXType();
}

fn matrixMimRunPipeline(func: i16, param: u16) void {
    var ctx = matrixMimRunContextInit();

    matrixMimRunPrepareExecution();
    matrixMimRunExecuteAndNormalize(func, param);
    matrixMimRunApplyAndCapture(&ctx);
    matrixMimRunCommitView(ctx);
}

const MatrixMimRunStage = enum {
    validate_mode,
    snapshot_selection,
    commit_pending_input,
    clear_lift_flag,
    load_selected_into_x,
    execute_item,
    normalize_x_type,
    apply_result,
    restore_linked_x,
    restore_lift_flag,
    finalize_view,
};

const MatrixMimRunExtendedContext = struct {
    func: i16,
    param: u16,
    base: MatrixMimRunContext,
};

fn matrixMimRunExtendedInit(func: i16, param: u16) MatrixMimRunExtendedContext {
    return .{
        .func = func,
        .param = param,
        .base = matrixMimRunContextInit(),
    };
}

fn matrixMimRunStageValidateMode() bool {
    return matrixMimRunEnterValidation();
}

fn matrixMimRunStageSnapshotSelection() void {
    z47_frontier_matrix_capture_selected_before();
}

fn matrixMimRunStageCommitPendingInput() void {
    mimEnter(true);
}

fn matrixMimRunStageClearLiftFlagAndErrorState() void {
    clearSystemFlag(FLAG_ASLIFT);
    matrixMimRunClearErrorState();
}

fn matrixMimRunStageLoadSelectedIntoX() void {
    z47_frontier_matrix_load_selected_into_register_x();
}

fn matrixMimRunStageExecuteItem(ctx: MatrixMimRunExtendedContext) void {
    matrixMimRunExecute(ctx.func, ctx.param);
}

fn matrixMimRunStageNormalizeXType() void {
    matrixMimRunNormalizeRegisterXType();
}

fn matrixMimRunStageApplyResult(ctx: *MatrixMimRunExtendedContext) void {
    matrixMimRunApplyAndCapture(&ctx.base);
}

fn matrixMimRunStageRestoreLinkedX(ctx: MatrixMimRunExtendedContext) void {
    matrixMimRunRestoreLinkedState(ctx.base);
}

fn matrixMimRunStageRestoreLiftFlag(ctx: MatrixMimRunExtendedContext) void {
    matrixMimRunContextRestoreLift(ctx.base);
}

fn matrixMimRunStageFinalizeView() void {
    matrixMimRunFinalizeView();
}

fn matrixMimRunExecuteStage(stage: MatrixMimRunStage, ctx: *MatrixMimRunExtendedContext) bool {
    switch (stage) {
        .validate_mode => {
            if (!matrixMimRunStageValidateMode()) return false;
        },
        .snapshot_selection => matrixMimRunStageSnapshotSelection(),
        .commit_pending_input => matrixMimRunStageCommitPendingInput(),
        .clear_lift_flag => matrixMimRunStageClearLiftFlagAndErrorState(),
        .load_selected_into_x => matrixMimRunStageLoadSelectedIntoX(),
        .execute_item => matrixMimRunStageExecuteItem(ctx.*),
        .normalize_x_type => matrixMimRunStageNormalizeXType(),
        .apply_result => matrixMimRunStageApplyResult(ctx),
        .restore_linked_x => matrixMimRunStageRestoreLinkedX(ctx.*),
        .restore_lift_flag => matrixMimRunStageRestoreLiftFlag(ctx.*),
        .finalize_view => matrixMimRunStageFinalizeView(),
    }
    return true;
}

fn matrixMimRunStageSequence() [11]MatrixMimRunStage {
    return .{
        .validate_mode,
        .snapshot_selection,
        .commit_pending_input,
        .clear_lift_flag,
        .load_selected_into_x,
        .execute_item,
        .normalize_x_type,
        .apply_result,
        .restore_linked_x,
        .restore_lift_flag,
        .finalize_view,
    };
}

fn matrixMimRunPipelineExpanded(func: i16, param: u16) void {
    var ctx = matrixMimRunExtendedInit(func, param);
    const stages = matrixMimRunStageSequence();
    for (stages) |stage| {
        if (!matrixMimRunExecuteStage(stage, &ctx)) {
            return;
        }
    }
}

fn matrixMimRunUseExpandedPipeline() bool {
    return true;
}

fn matrixMimRunDispatchPipeline(func: i16, param: u16) void {
    if (matrixMimRunUseExpandedPipeline()) {
        matrixMimRunPipelineExpanded(func, param);
        return;
    }
    matrixMimRunPipeline(func, param);
}

const MatrixMimAddDecision = struct {
    handled: bool,
    stop: bool,
    enqueue_item: bool,
};

fn matrixMimAddNoopDecision() MatrixMimAddDecision {
    return .{ .handled = false, .stop = false, .enqueue_item = false };
}

fn matrixMimAddStopDecision() MatrixMimAddDecision {
    return .{ .handled = true, .stop = true, .enqueue_item = false };
}

fn matrixMimAddEnqueueDecision() MatrixMimAddDecision {
    return .{ .handled = true, .stop = false, .enqueue_item = true };
}

fn matrixMimAddShouldInitializeAim(item: i16) bool {
    return item == ITM_EXPONENT or
        item == ITM_PERIOD or
        item == ITM_0 or
        item == ITM_1 or
        item == ITM_2 or
        item == ITM_3 or
        item == ITM_4 or
        item == ITM_5 or
        item == ITM_6 or
        item == ITM_7 or
        item == ITM_8 or
        item == ITM_9;
}

fn matrixMimAddInitializeAim(item: i16) MatrixMimAddDecision {
    if (!matrixMimAddShouldInitializeAim(item)) {
        return matrixMimAddNoopDecision();
    }

    if (!z47_frontier_matrix_aim_is_empty()) {
        return matrixMimAddEnqueueDecision();
    }

    if (item == ITM_EXPONENT) {
        z47_frontier_matrix_init_aim_exponent();
        return matrixMimAddEnqueueDecision();
    }

    if (item == ITM_PERIOD) {
        z47_frontier_matrix_init_aim_period();
        return matrixMimAddEnqueueDecision();
    }

    z47_frontier_matrix_init_aim_digit();
    return matrixMimAddEnqueueDecision();
}

fn matrixMimAddHandleBackspace(item: i16) MatrixMimAddDecision {
    if (item != ITM_BACKSPACE) {
        return matrixMimAddNoopDecision();
    }

    if (z47_frontier_matrix_aim_is_empty()) {
        z47_frontier_matrix_zero_current_element();
        return matrixMimAddStopDecision();
    }

    if (z47_frontier_matrix_aim_is_single_plus_digit()) {
        z47_frontier_matrix_aim_clear_single_plus_digit();
    }
    return matrixMimAddEnqueueDecision();
}

fn matrixMimAddHandleSign(item: i16) MatrixMimAddDecision {
    if (item != ITM_CHS) {
        return matrixMimAddNoopDecision();
    }

    if (z47_frontier_matrix_aim_is_empty()) {
        z47_frontier_matrix_change_sign_current_element();
        return matrixMimAddStopDecision();
    }

    return matrixMimAddEnqueueDecision();
}

fn matrixMimAddHandleImaginaryUnit(item: i16) MatrixMimAddDecision {
    if (!(item == ITM_op_j_pol or item == ITM_op_j or item == ITM_CC)) {
        return matrixMimAddNoopDecision();
    }

    if (z47_frontier_matrix_aim_is_empty()) {
        z47_frontier_matrix_make_j_element();
        return matrixMimAddStopDecision();
    }

    return matrixMimAddEnqueueDecision();
}

fn matrixMimAddHandlePi(item: i16) MatrixMimAddDecision {
    if (item != ITM_CONSTpi) {
        return matrixMimAddNoopDecision();
    }

    if (z47_frontier_matrix_aim_is_empty()) {
        z47_frontier_matrix_set_current_to_pi();
        return matrixMimAddStopDecision();
    }

    if (z47_frontier_matrix_can_append_pi_literal()) {
        z47_frontier_matrix_append_pi_literal_and_enter();
        return matrixMimAddStopDecision();
    }

    return matrixMimAddStopDecision();
}

fn matrixMimAddApplyDecision(item: i16, decision: MatrixMimAddDecision) bool {
    if (!decision.handled) {
        return false;
    }
    if (decision.stop) {
        return true;
    }
    if (decision.enqueue_item) {
        z47_frontier_matrix_add_item_to_nim_buffer(item);
        calcMode = CM_MIM;
    }
    return true;
}

fn matrixMimAddDispatch(item: i16) bool {
    if (matrixMimAddApplyDecision(item, matrixMimAddInitializeAim(item))) {
        return true;
    }
    if (matrixMimAddApplyDecision(item, matrixMimAddHandleBackspace(item))) {
        return true;
    }
    if (matrixMimAddApplyDecision(item, matrixMimAddHandleSign(item))) {
        return true;
    }
    if (matrixMimAddApplyDecision(item, matrixMimAddHandleImaginaryUnit(item))) {
        return true;
    }
    if (matrixMimAddApplyDecision(item, matrixMimAddHandlePi(item))) {
        return true;
    }
    return false;
}

const MatrixMimAddItemClass = enum {
    exponent,
    period,
    digit,
    backspace,
    sign,
    imaginary_unit,
    pi,
    unsupported,
};

const MatrixMimAddPlan = struct {
    class: MatrixMimAddItemClass,
    allow_when_aim_empty: bool,
    allow_when_aim_nonempty: bool,
    requests_enqueue: bool,
    requests_stop: bool,
};

fn matrixMimAddIsDigit(item: i16) bool {
    return item == ITM_0 or
        item == ITM_1 or
        item == ITM_2 or
        item == ITM_3 or
        item == ITM_4 or
        item == ITM_5 or
        item == ITM_6 or
        item == ITM_7 or
        item == ITM_8 or
        item == ITM_9;
}

fn matrixMimAddIsImaginaryUnit(item: i16) bool {
    return item == ITM_op_j_pol or item == ITM_op_j or item == ITM_CC;
}

fn matrixMimAddClassify(item: i16) MatrixMimAddItemClass {
    if (item == ITM_EXPONENT) return .exponent;
    if (item == ITM_PERIOD) return .period;
    if (matrixMimAddIsDigit(item)) return .digit;
    if (item == ITM_BACKSPACE) return .backspace;
    if (item == ITM_CHS) return .sign;
    if (matrixMimAddIsImaginaryUnit(item)) return .imaginary_unit;
    if (item == ITM_CONSTpi) return .pi;
    return .unsupported;
}

fn matrixMimAddPlanForClass(class: MatrixMimAddItemClass) MatrixMimAddPlan {
    return switch (class) {
        .exponent => .{ .class = class, .allow_when_aim_empty = true, .allow_when_aim_nonempty = true, .requests_enqueue = true, .requests_stop = false },
        .period => .{ .class = class, .allow_when_aim_empty = true, .allow_when_aim_nonempty = true, .requests_enqueue = true, .requests_stop = false },
        .digit => .{ .class = class, .allow_when_aim_empty = true, .allow_when_aim_nonempty = true, .requests_enqueue = true, .requests_stop = false },
        .backspace => .{ .class = class, .allow_when_aim_empty = true, .allow_when_aim_nonempty = true, .requests_enqueue = true, .requests_stop = false },
        .sign => .{ .class = class, .allow_when_aim_empty = true, .allow_when_aim_nonempty = true, .requests_enqueue = true, .requests_stop = false },
        .imaginary_unit => .{ .class = class, .allow_when_aim_empty = true, .allow_when_aim_nonempty = true, .requests_enqueue = true, .requests_stop = false },
        .pi => .{ .class = class, .allow_when_aim_empty = true, .allow_when_aim_nonempty = true, .requests_enqueue = false, .requests_stop = true },
        .unsupported => .{ .class = class, .allow_when_aim_empty = false, .allow_when_aim_nonempty = false, .requests_enqueue = false, .requests_stop = true },
    };
}

fn matrixMimAddPlanAllows(plan: MatrixMimAddPlan, aim_empty: bool) bool {
    if (aim_empty) {
        return plan.allow_when_aim_empty;
    }
    return plan.allow_when_aim_nonempty;
}

fn matrixMimAddPlanWantsStop(plan: MatrixMimAddPlan) bool {
    return plan.requests_stop;
}

fn matrixMimAddPlanWantsEnqueue(plan: MatrixMimAddPlan) bool {
    return plan.requests_enqueue;
}

fn matrixMimAddInitAimForClass(class: MatrixMimAddItemClass) void {
    switch (class) {
        .exponent => z47_frontier_matrix_init_aim_exponent(),
        .period => z47_frontier_matrix_init_aim_period(),
        .digit => z47_frontier_matrix_init_aim_digit(),
        else => {},
    }
}

fn matrixMimAddHandleAimEmptyClass(class: MatrixMimAddItemClass) MatrixMimAddDecision {
    switch (class) {
        .exponent, .period, .digit => {
            matrixMimAddInitAimForClass(class);
            return matrixMimAddEnqueueDecision();
        },
        .backspace => {
            z47_frontier_matrix_zero_current_element();
            return matrixMimAddStopDecision();
        },
        .sign => {
            z47_frontier_matrix_change_sign_current_element();
            return matrixMimAddStopDecision();
        },
        .imaginary_unit => {
            z47_frontier_matrix_make_j_element();
            return matrixMimAddStopDecision();
        },
        .pi => {
            z47_frontier_matrix_set_current_to_pi();
            return matrixMimAddStopDecision();
        },
        .unsupported => return matrixMimAddStopDecision(),
    }
}

fn matrixMimAddHandleAimNonEmptyClass(class: MatrixMimAddItemClass) MatrixMimAddDecision {
    switch (class) {
        .exponent, .period, .digit => {
            return matrixMimAddEnqueueDecision();
        },
        .backspace => {
            if (z47_frontier_matrix_aim_is_single_plus_digit()) {
                z47_frontier_matrix_aim_clear_single_plus_digit();
            }
            return matrixMimAddEnqueueDecision();
        },
        .sign => return matrixMimAddEnqueueDecision(),
        .imaginary_unit => return matrixMimAddEnqueueDecision(),
        .pi => {
            if (z47_frontier_matrix_can_append_pi_literal()) {
                z47_frontier_matrix_append_pi_literal_and_enter();
            }
            return matrixMimAddStopDecision();
        },
        .unsupported => return matrixMimAddStopDecision(),
    }
}

fn matrixMimAddPlanEvaluate(item: i16, aim_empty: bool) MatrixMimAddDecision {
    const class = matrixMimAddClassify(item);
    const plan = matrixMimAddPlanForClass(class);

    if (!matrixMimAddPlanAllows(plan, aim_empty)) {
        return matrixMimAddStopDecision();
    }

    if (aim_empty) {
        return matrixMimAddHandleAimEmptyClass(class);
    }
    return matrixMimAddHandleAimNonEmptyClass(class);
}

fn matrixMimAddApplyPlanner(item: i16) bool {
    const aim_empty = z47_frontier_matrix_aim_is_empty();
    const decision = matrixMimAddPlanEvaluate(item, aim_empty);
    if (!decision.handled) {
        return false;
    }
    if (matrixMimAddPlanWantsStop(matrixMimAddPlanForClass(matrixMimAddClassify(item))) and decision.stop) {
        return true;
    }
    if (decision.enqueue_item and matrixMimAddPlanWantsEnqueue(matrixMimAddPlanForClass(matrixMimAddClassify(item)))) {
        z47_frontier_matrix_add_item_to_nim_buffer(item);
        calcMode = CM_MIM;
    }
    return true;
}

fn matrixMimAddDispatchExpanded(item: i16) bool {
    if (matrixMimAddApplyPlanner(item)) {
        return true;
    }
    return matrixMimAddDispatch(item);
}

const MatrixWrapStage = enum {
    clear_flags,
    handle_i,
    handle_j,
    complete,
};

const MatrixWrapContext = struct {
    rows: u16,
    cols: u16,
    wrapped_i: bool,
    wrapped_j: bool,
};

fn matrixWrapContextInit(rows: u16, cols: u16) MatrixWrapContext {
    return .{
        .rows = rows,
        .cols = cols,
        .wrapped_i = false,
        .wrapped_j = false,
    };
}

fn matrixWrapContextSetWrappedI(ctx: *MatrixWrapContext) void {
    ctx.wrapped_i = true;
}

fn matrixWrapContextSetWrappedJ(ctx: *MatrixWrapContext) void {
    ctx.wrapped_j = true;
}

fn matrixWrapClearFlags() void {
    clearSystemFlag(FLAG_WRAPEDG);
    clearSystemFlag(FLAG_WRAPEND);
}

fn matrixWrapHandleINegative(ctx: *MatrixWrapContext) void {
    matrixWrapNegativeI(ctx.rows, ctx.cols);
    matrixWrapContextSetWrappedI(ctx);
}

fn matrixWrapHandleIOverflow(ctx: *MatrixWrapContext) void {
    matrixWrapOverflowI(ctx.rows, ctx.cols);
    matrixWrapContextSetWrappedI(ctx);
}

fn matrixWrapHandleJNegative(ctx: *MatrixWrapContext) void {
    matrixWrapNegativeJ(ctx.rows, ctx.cols);
    matrixWrapContextSetWrappedJ(ctx);
}

fn matrixWrapHandleJOverflow(ctx: *MatrixWrapContext) void {
    matrixWrapOverflowJ(ctx.rows, ctx.cols);
    matrixWrapContextSetWrappedJ(ctx);
}

fn matrixWrapHandleIStage(ctx: *MatrixWrapContext) void {
    if (getIRegisterAsInt(true) < 0) {
        matrixWrapHandleINegative(ctx);
        return;
    }
    if (getIRegisterAsInt(true) == @as(i16, @intCast(ctx.rows))) {
        matrixWrapHandleIOverflow(ctx);
    }
}

fn matrixWrapHandleJStage(ctx: *MatrixWrapContext) void {
    if (getJRegisterAsInt(true) < 0) {
        matrixWrapHandleJNegative(ctx);
        return;
    }
    if (getJRegisterAsInt(true) == @as(i16, @intCast(ctx.cols))) {
        matrixWrapHandleJOverflow(ctx);
    }
}

fn matrixWrapStageSequence() [4]MatrixWrapStage {
    return .{ .clear_flags, .handle_i, .handle_j, .complete };
}

fn matrixWrapExecuteStage(stage: MatrixWrapStage, ctx: *MatrixWrapContext) void {
    switch (stage) {
        .clear_flags => matrixWrapClearFlags(),
        .handle_i => matrixWrapHandleIStage(ctx),
        .handle_j => matrixWrapHandleJStage(ctx),
        .complete => {},
    }
}

fn matrixWrapPipelineExpanded(rows: u16, cols: u16) bool {
    var ctx = matrixWrapContextInit(rows, cols);
    const stages = matrixWrapStageSequence();
    for (stages) |stage| {
        matrixWrapExecuteStage(stage, &ctx);
    }
    return getIRegisterAsInt(true) == @as(i16, @intCast(rows));
}

fn matrixWrapUseExpandedPipeline() bool {
    return true;
}

fn matrixWrapDispatch(rows: u16, cols: u16) bool {
    if (matrixWrapUseExpandedPipeline()) {
        return matrixWrapPipelineExpanded(rows, cols);
    }

    matrixWrapClearFlags();

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

pub export fn wrapIJ(rows: u16, cols: u16) callconv(.c) bool {
    return matrixWrapDispatch(rows, cols);
}

pub export fn showMatrixEditor() callconv(.c) void {
    matrixEditorRefreshDispatcher();
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
    matrixIncDecDispatchPipeline(.row, mode);
}

pub export fn fnIncDecJ(mode: u16) callconv(.c) void {
    matrixIncDecDispatchPipeline(.col, mode);
}

const MatrixIncDecAxis = enum {
    row,
    col,
};

const MatrixIncDecStage = enum {
    validate_mode,
    apply_step,
};

const MatrixIncDecContext = struct {
    axis: MatrixIncDecAxis,
    mode: u16,
};

fn matrixIncDecContextInit(axis: MatrixIncDecAxis, mode: u16) MatrixIncDecContext {
    return .{ .axis = axis, .mode = mode };
}

fn matrixIncDecValidateMode() bool {
    if (calcMode == CM_MIM) {
        return true;
    }
    matrixModeUndefinedError();
    return false;
}

fn matrixIncDecApplyStep(ctx: MatrixIncDecContext) void {
    switch (ctx.axis) {
        .row => z47_frontier_matrix_inc_dec_i(ctx.mode),
        .col => z47_frontier_matrix_inc_dec_j(ctx.mode),
    }
}

fn matrixIncDecExecuteStage(stage: MatrixIncDecStage, ctx: MatrixIncDecContext) bool {
    switch (stage) {
        .validate_mode => return matrixIncDecValidateMode(),
        .apply_step => matrixIncDecApplyStep(ctx),
    }
    return true;
}

fn matrixIncDecStageSequence() [2]MatrixIncDecStage {
    return .{ .validate_mode, .apply_step };
}

fn matrixIncDecPipeline(axis: MatrixIncDecAxis, mode: u16) void {
    const ctx = matrixIncDecContextInit(axis, mode);
    const stages = matrixIncDecStageSequence();
    for (stages) |stage| {
        if (!matrixIncDecExecuteStage(stage, ctx)) {
            return;
        }
    }
}

fn matrixIncDecUseExpandedPipeline() bool {
    return true;
}

fn matrixIncDecDispatchPipeline(axis: MatrixIncDecAxis, mode: u16) void {
    if (matrixIncDecUseExpandedPipeline()) {
        matrixIncDecPipeline(axis, mode);
        return;
    }

    if (calcMode == CM_MIM) {
        switch (axis) {
            .row => z47_frontier_matrix_inc_dec_i(mode),
            .col => z47_frontier_matrix_inc_dec_j(mode),
        }
        return;
    }
    matrixModeUndefinedError();
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

    _ = matrixMimAddDispatchExpanded(item);
}

pub export fn mimRunFunction(func: i16, param: u16) callconv(.c) void {
    matrixMimRunDispatchPipeline(func, param);
}

pub export fn fnClPAll(confirmation: u16) callconv(.c) void {
    program_clear.run(confirmation);
}

const PlotRegressionStage = enum {
    decode_mode,
    seed_mode_defaults,
    update_selection,
    normalize_selection,
    finalize,
};

const PlotRegressionCommand = enum {
    orthof,
    next,
    prev,
    lr,
    start,
    nothing,
    unknown,
};

const PlotRegressionContext = struct {
    mode: u16,
    command: PlotRegressionCommand,
    selection: u16,
    lr_selection_mask: u16,
    chosen: u16,
};

fn plotRegressionContextInit(plot_mode: u16) PlotRegressionContext {
    return .{
        .mode = plot_mode,
        .command = .unknown,
        .selection = plotSelection,
        .lr_selection_mask = if (lrSelection == 0) @as(u16, 1023) else lrSelection,
        .chosen = lrChosen,
    };
}

fn plotRegressionDecodeMode(mode: u16) PlotRegressionCommand {
    return switch (mode) {
        PLOT_ORTHOF => .orthof,
        PLOT_NXT => .next,
        PLOT_REV => .prev,
        PLOT_LR => .lr,
        PLOT_START => .start,
        PLOT_NOTHING => .nothing,
        else => .unknown,
    };
}

fn plotRegressionStageDecodeMode(ctx: *PlotRegressionContext) void {
    ctx.command = plotRegressionDecodeMode(ctx.mode);
}

fn plotRegressionSeedDefaults(ctx: *PlotRegressionContext) void {
    _ = ctx;
}

fn plotRegressionMaskContains(mask: u16, selection: u16) bool {
    return selection == (mask & selection);
}

fn plotRegressionSelectionAllowed(ctx: PlotRegressionContext) bool {
    return plotRegressionMaskContains(ctx.lr_selection_mask, ctx.selection);
}

fn plotRegressionSelectionBelowLimit(selection: u16) bool {
    return selection < 1024;
}

fn plotRegressionSelectionAboveOrEqualLimit(selection: u16) bool {
    return selection >= 1024;
}

fn plotRegressionSelectionIsZero(selection: u16) bool {
    return selection == 0;
}

fn plotRegressionSelectionPositive(selection: u16) bool {
    return selection > 0;
}

fn plotRegressionShiftLeft(selection: u16) u16 {
    return selection << 1;
}

fn plotRegressionShiftRight(selection: u16) u16 {
    return selection >> 1;
}

fn plotRegressionSetOrthogonalSelection(ctx: *PlotRegressionContext) void {
    ctx.selection = CF_ORTHOGONAL_FITTING;
    ctx.chosen = CF_ORTHOGONAL_FITTING;
}

fn plotRegressionSeedNextSelection(ctx: *PlotRegressionContext) void {
    ctx.selection = plotRegressionShiftLeft(ctx.selection);
    if (plotRegressionSelectionIsZero(ctx.selection)) {
        ctx.selection = 1;
    }
}

fn plotRegressionNextLoopCondition(ctx: PlotRegressionContext) bool {
    return !plotRegressionSelectionAllowed(ctx) and plotRegressionSelectionBelowLimit(ctx.selection);
}

fn plotRegressionAdvanceNextSelection(ctx: *PlotRegressionContext) void {
    ctx.selection = plotRegressionShiftLeft(ctx.selection);
}

fn plotRegressionApplyNextLoop(ctx: *PlotRegressionContext) void {
    while (plotRegressionNextLoopCondition(ctx.*)) {
        plotRegressionAdvanceNextSelection(ctx);
    }
}

fn plotRegressionNormalizeNextOverflow(ctx: *PlotRegressionContext) void {
    if (plotRegressionSelectionAboveOrEqualLimit(ctx.selection)) {
        ctx.selection = 0;
    }
}

fn plotRegressionApplyNext(ctx: *PlotRegressionContext) void {
    plotRegressionSeedNextSelection(ctx);
    plotRegressionApplyNextLoop(ctx);
    plotRegressionNormalizeNextOverflow(ctx);
}

fn plotRegressionSeedPrevSelection(ctx: *PlotRegressionContext) void {
    if (plotRegressionSelectionIsZero(ctx.selection)) {
        ctx.selection = 1024;
    }
    ctx.selection = plotRegressionShiftRight(ctx.selection);
}

fn plotRegressionNormalizePrevOverflow(ctx: *PlotRegressionContext) void {
    if (plotRegressionSelectionAboveOrEqualLimit(ctx.selection)) {
        ctx.selection = 0;
    }
}

fn plotRegressionPrevLoopCondition(ctx: PlotRegressionContext) bool {
    return !plotRegressionSelectionAllowed(ctx) and plotRegressionSelectionBelowLimit(ctx.selection) and plotRegressionSelectionPositive(ctx.selection);
}

fn plotRegressionAdvancePrevSelection(ctx: *PlotRegressionContext) void {
    ctx.selection = plotRegressionShiftRight(ctx.selection);
}

fn plotRegressionApplyPrevLoop(ctx: *PlotRegressionContext) void {
    while (plotRegressionPrevLoopCondition(ctx.*)) {
        plotRegressionAdvancePrevSelection(ctx);
    }
}

fn plotRegressionApplyPrev(ctx: *PlotRegressionContext) void {
    plotRegressionSeedPrevSelection(ctx);
    plotRegressionNormalizePrevOverflow(ctx);
    plotRegressionApplyPrevLoop(ctx);
}

fn plotRegressionSeedLrSelection(ctx: *PlotRegressionContext) void {
    ctx.selection = ctx.chosen;
    if (plotRegressionSelectionIsZero(ctx.selection)) {
        ctx.selection = 1;
    }
}

fn plotRegressionLrLoopCondition(ctx: PlotRegressionContext) bool {
    return !plotRegressionSelectionAllowed(ctx) and plotRegressionSelectionBelowLimit(ctx.selection);
}

fn plotRegressionAdvanceLrSelection(ctx: *PlotRegressionContext) void {
    ctx.selection = plotRegressionShiftLeft(ctx.selection);
}

fn plotRegressionApplyLrLoop(ctx: *PlotRegressionContext) void {
    while (plotRegressionLrLoopCondition(ctx.*)) {
        plotRegressionAdvanceLrSelection(ctx);
    }
}

fn plotRegressionNormalizeLrOverflow(ctx: *PlotRegressionContext) void {
    if (plotRegressionSelectionAboveOrEqualLimit(ctx.selection)) {
        ctx.selection = 0;
    }
}

fn plotRegressionApplyLr(ctx: *PlotRegressionContext) void {
    plotRegressionSeedLrSelection(ctx);
    plotRegressionApplyLrLoop(ctx);
    plotRegressionNormalizeLrOverflow(ctx);
}

fn plotRegressionApplyStart(_: *PlotRegressionContext) void {}

fn plotRegressionApplyNothing(_: *PlotRegressionContext) void {}

fn plotRegressionApplyUnknown(_: *PlotRegressionContext) void {}

fn plotRegressionUpdateSelection(ctx: *PlotRegressionContext) void {
    switch (ctx.command) {
        .orthof => plotRegressionSetOrthogonalSelection(ctx),
        .next => plotRegressionApplyNext(ctx),
        .prev => plotRegressionApplyPrev(ctx),
        .lr => plotRegressionApplyLr(ctx),
        .start => plotRegressionApplyStart(ctx),
        .nothing => plotRegressionApplyNothing(ctx),
        .unknown => plotRegressionApplyUnknown(ctx),
    }
}

fn plotRegressionNormalizeSelection(ctx: *PlotRegressionContext) void {
    if (plotRegressionSelectionAboveOrEqualLimit(ctx.selection)) {
        ctx.selection = 0;
    }
}

fn plotRegressionFinalize(ctx: PlotRegressionContext) void {
    plotSelection = ctx.selection;
    if (ctx.command == .orthof) {
        lrChosen = ctx.chosen;
    }
}

fn plotRegressionExecuteStage(stage: PlotRegressionStage, ctx: *PlotRegressionContext) void {
    switch (stage) {
        .decode_mode => plotRegressionStageDecodeMode(ctx),
        .seed_mode_defaults => plotRegressionSeedDefaults(ctx),
        .update_selection => plotRegressionUpdateSelection(ctx),
        .normalize_selection => plotRegressionNormalizeSelection(ctx),
        .finalize => plotRegressionFinalize(ctx.*),
    }
}

fn plotRegressionStageSequence() [5]PlotRegressionStage {
    return .{
        .decode_mode,
        .seed_mode_defaults,
        .update_selection,
        .normalize_selection,
        .finalize,
    };
}

fn plotRegressionPipeline(plot_mode: u16) void {
    var ctx = plotRegressionContextInit(plot_mode);
    const stages = plotRegressionStageSequence();
    for (stages) |stage| {
        plotRegressionExecuteStage(stage, &ctx);
    }
}

const PlotRegressionPhase = enum {
    prepare,
    apply,
    finish,
};

const PlotRegressionPlan = struct {
    phases: [3]PlotRegressionPhase,
};

fn plotRegressionPlanBuild() PlotRegressionPlan {
    return .{ .phases = .{ .prepare, .apply, .finish } };
}

fn plotRegressionPrepareStages() [2]PlotRegressionStage {
    return .{ .decode_mode, .seed_mode_defaults };
}

fn plotRegressionApplyStages() [1]PlotRegressionStage {
    return .{.update_selection};
}

fn plotRegressionFinishStages() [2]PlotRegressionStage {
    return .{ .normalize_selection, .finalize };
}

fn plotRegressionRunStageList(comptime count: usize, stages: [count]PlotRegressionStage, ctx: *PlotRegressionContext) void {
    for (stages) |stage| {
        plotRegressionExecuteStage(stage, ctx);
    }
}

fn plotRegressionRunPrepare(ctx: *PlotRegressionContext) void {
    const stages = plotRegressionPrepareStages();
    plotRegressionRunStageList(stages.len, stages, ctx);
}

fn plotRegressionRunApply(ctx: *PlotRegressionContext) void {
    const stages = plotRegressionApplyStages();
    plotRegressionRunStageList(stages.len, stages, ctx);
}

fn plotRegressionRunFinish(ctx: *PlotRegressionContext) void {
    const stages = plotRegressionFinishStages();
    plotRegressionRunStageList(stages.len, stages, ctx);
}

fn plotRegressionExecutePhase(phase: PlotRegressionPhase, ctx: *PlotRegressionContext) void {
    switch (phase) {
        .prepare => plotRegressionRunPrepare(ctx),
        .apply => plotRegressionRunApply(ctx),
        .finish => plotRegressionRunFinish(ctx),
    }
}

const PlotRegressionTelemetry = struct {
    prepare_started: bool,
    prepare_completed: bool,
    apply_started: bool,
    apply_completed: bool,
    finish_started: bool,
    finish_completed: bool,
};

fn plotRegressionTelemetryInit() PlotRegressionTelemetry {
    return .{
        .prepare_started = false,
        .prepare_completed = false,
        .apply_started = false,
        .apply_completed = false,
        .finish_started = false,
        .finish_completed = false,
    };
}

fn plotRegressionTelemetryMarkPhaseStart(telemetry: *PlotRegressionTelemetry, phase: PlotRegressionPhase) void {
    switch (phase) {
        .prepare => telemetry.prepare_started = true,
        .apply => telemetry.apply_started = true,
        .finish => telemetry.finish_started = true,
    }
}

fn plotRegressionTelemetryMarkPhaseComplete(telemetry: *PlotRegressionTelemetry, phase: PlotRegressionPhase) void {
    switch (phase) {
        .prepare => telemetry.prepare_completed = true,
        .apply => telemetry.apply_completed = true,
        .finish => telemetry.finish_completed = true,
    }
}

fn plotRegressionTelemetryPhaseCanRun(telemetry: PlotRegressionTelemetry, phase: PlotRegressionPhase) bool {
    return switch (phase) {
        .prepare => true,
        .apply => telemetry.prepare_completed,
        .finish => telemetry.apply_completed,
    };
}

fn plotRegressionExecutePhaseWithTelemetry(phase: PlotRegressionPhase, ctx: *PlotRegressionContext, telemetry: *PlotRegressionTelemetry) void {
    if (!plotRegressionTelemetryPhaseCanRun(telemetry.*, phase)) {
        return;
    }

    plotRegressionTelemetryMarkPhaseStart(telemetry, phase);
    plotRegressionExecutePhaseExpanded(phase, ctx);
    plotRegressionTelemetryMarkPhaseComplete(telemetry, phase);
}

fn plotRegressionTelemetryPipeline(plot_mode: u16) void {
    var ctx = plotRegressionContextInit(plot_mode);
    var telemetry = plotRegressionTelemetryInit();
    const plan = plotRegressionPlanBuild();
    for (plan.phases) |phase| {
        plotRegressionExecutePhaseWithTelemetry(phase, &ctx, &telemetry);
    }
}

fn plotRegressionUseTelemetryPipeline() bool {
    return true;
}

fn plotRegressionPipelineExpanded(plot_mode: u16) void {
    var ctx = plotRegressionContextInit(plot_mode);
    const plan = plotRegressionPlanBuild();
    for (plan.phases) |phase| {
        plotRegressionExecutePhase(phase, &ctx);
    }
}

const PlotSelectionAudit = struct {
    mask: u16,
    selection: u16,
    within_bounds: bool,
    allowed: bool,
};

fn plotSelectionAuditInit(mask: u16, selection: u16) PlotSelectionAudit {
    return .{
        .mask = mask,
        .selection = selection,
        .within_bounds = plotRegressionSelectionBelowLimit(selection),
        .allowed = plotRegressionMaskContains(mask, selection),
    };
}

fn plotSelectionAuditRefresh(audit: *PlotSelectionAudit) void {
    audit.within_bounds = plotRegressionSelectionBelowLimit(audit.selection);
    audit.allowed = plotRegressionMaskContains(audit.mask, audit.selection);
}

fn plotSelectionAuditSetSelection(audit: *PlotSelectionAudit, selection: u16) void {
    audit.selection = selection;
    plotSelectionAuditRefresh(audit);
}

fn plotSelectionAuditShiftLeft(audit: *PlotSelectionAudit) void {
    plotSelectionAuditSetSelection(audit, plotRegressionShiftLeft(audit.selection));
}

fn plotSelectionAuditShiftRight(audit: *PlotSelectionAudit) void {
    plotSelectionAuditSetSelection(audit, plotRegressionShiftRight(audit.selection));
}

fn plotSelectionAuditNeedsForwardScan(audit: PlotSelectionAudit) bool {
    return !audit.allowed and audit.within_bounds;
}

fn plotSelectionAuditNeedsBackwardScan(audit: PlotSelectionAudit) bool {
    return !audit.allowed and audit.within_bounds and plotRegressionSelectionPositive(audit.selection);
}

fn plotSelectionAuditScanForward(audit: *PlotSelectionAudit) void {
    while (plotSelectionAuditNeedsForwardScan(audit.*)) {
        plotSelectionAuditShiftLeft(audit);
    }
}

fn plotSelectionAuditScanBackward(audit: *PlotSelectionAudit) void {
    while (plotSelectionAuditNeedsBackwardScan(audit.*)) {
        plotSelectionAuditShiftRight(audit);
    }
}

fn plotSelectionAuditClampOverflow(audit: *PlotSelectionAudit) void {
    if (plotRegressionSelectionAboveOrEqualLimit(audit.selection)) {
        plotSelectionAuditSetSelection(audit, 0);
    }
}

fn plotSelectionApplyAuditNext(ctx: *PlotRegressionContext) void {
    var audit = plotSelectionAuditInit(ctx.lr_selection_mask, ctx.selection);
    if (plotRegressionSelectionIsZero(audit.selection)) {
        plotSelectionAuditSetSelection(&audit, 1);
    }
    plotSelectionAuditShiftLeft(&audit);
    if (plotRegressionSelectionIsZero(audit.selection)) {
        plotSelectionAuditSetSelection(&audit, 1);
    }
    plotSelectionAuditScanForward(&audit);
    plotSelectionAuditClampOverflow(&audit);
    ctx.selection = audit.selection;
}

fn plotSelectionApplyAuditPrev(ctx: *PlotRegressionContext) void {
    var audit = plotSelectionAuditInit(ctx.lr_selection_mask, ctx.selection);
    if (plotRegressionSelectionIsZero(audit.selection)) {
        plotSelectionAuditSetSelection(&audit, 1024);
    }
    plotSelectionAuditShiftRight(&audit);
    plotSelectionAuditClampOverflow(&audit);
    plotSelectionAuditScanBackward(&audit);
    ctx.selection = audit.selection;
}

fn plotSelectionApplyAuditLr(ctx: *PlotRegressionContext) void {
    var audit = plotSelectionAuditInit(ctx.lr_selection_mask, ctx.chosen);
    if (plotRegressionSelectionIsZero(audit.selection)) {
        plotSelectionAuditSetSelection(&audit, 1);
    }
    plotSelectionAuditScanForward(&audit);
    plotSelectionAuditClampOverflow(&audit);
    ctx.selection = audit.selection;
}

fn plotRegressionApplySelectionViaAudit(ctx: *PlotRegressionContext) bool {
    switch (ctx.command) {
        .next => {
            plotSelectionApplyAuditNext(ctx);
            return true;
        },
        .prev => {
            plotSelectionApplyAuditPrev(ctx);
            return true;
        },
        .lr => {
            plotSelectionApplyAuditLr(ctx);
            return true;
        },
        else => return false,
    }
}

fn plotRegressionUpdateSelectionExpanded(ctx: *PlotRegressionContext) void {
    if (ctx.command == .orthof) {
        plotRegressionSetOrthogonalSelection(ctx);
        return;
    }
    if (ctx.command == .start or ctx.command == .nothing or ctx.command == .unknown) {
        return;
    }
    if (plotRegressionApplySelectionViaAudit(ctx)) {
        return;
    }
    plotRegressionUpdateSelection(ctx);
}

fn plotRegressionFinalizeExpanded(ctx: PlotRegressionContext) void {
    plotRegressionFinalize(ctx);
}

fn plotRegressionExecuteStageExpanded(stage: PlotRegressionStage, ctx: *PlotRegressionContext) void {
    switch (stage) {
        .decode_mode => plotRegressionStageDecodeMode(ctx),
        .seed_mode_defaults => plotRegressionSeedDefaults(ctx),
        .update_selection => plotRegressionUpdateSelectionExpanded(ctx),
        .normalize_selection => plotRegressionNormalizeSelection(ctx),
        .finalize => plotRegressionFinalizeExpanded(ctx.*),
    }
}

fn plotRegressionRunStageListExpanded(comptime count: usize, stages: [count]PlotRegressionStage, ctx: *PlotRegressionContext) void {
    for (stages) |stage| {
        plotRegressionExecuteStageExpanded(stage, ctx);
    }
}

fn plotRegressionRunPrepareExpanded(ctx: *PlotRegressionContext) void {
    const stages = plotRegressionPrepareStages();
    plotRegressionRunStageListExpanded(stages.len, stages, ctx);
}

fn plotRegressionRunApplyExpanded(ctx: *PlotRegressionContext) void {
    const stages = plotRegressionApplyStages();
    plotRegressionRunStageListExpanded(stages.len, stages, ctx);
}

fn plotRegressionRunFinishExpanded(ctx: *PlotRegressionContext) void {
    const stages = plotRegressionFinishStages();
    plotRegressionRunStageListExpanded(stages.len, stages, ctx);
}

fn plotRegressionExecutePhaseExpanded(phase: PlotRegressionPhase, ctx: *PlotRegressionContext) void {
    switch (phase) {
        .prepare => plotRegressionRunPrepareExpanded(ctx),
        .apply => plotRegressionRunApplyExpanded(ctx),
        .finish => plotRegressionRunFinishExpanded(ctx),
    }
}

fn plotRegressionPipelinePlanner(plot_mode: u16) void {
    var ctx = plotRegressionContextInit(plot_mode);
    const plan = plotRegressionPlanBuild();
    for (plan.phases) |phase| {
        plotRegressionExecutePhaseExpanded(phase, &ctx);
    }
}

fn plotRegressionUsePlannerPipeline() bool {
    return true;
}

fn plotRegressionUseExpandedPipeline() bool {
    return true;
}

fn plotRegressionDispatchPipeline(plot_mode: u16) void {
    if (plotRegressionUseTelemetryPipeline()) {
        plotRegressionTelemetryPipeline(plot_mode);
        return;
    }

    if (plotRegressionUsePlannerPipeline()) {
        plotRegressionPipelinePlanner(plot_mode);
        return;
    }

    if (plotRegressionUseExpandedPipeline()) {
        plotRegressionPipeline(plot_mode);
        return;
    }

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

pub export fn fnPlotRegressionLine(plot_mode: u16) callconv(.c) void {
    plotRegressionDispatchPipeline(plot_mode);
}
