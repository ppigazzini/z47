const std = @import("std");
const clear_all = @import("frontier_clear_all_owned.zig");
const display_format = @import("frontier_display_format_owned.zig");
const frontend_settings = @import("frontier_frontend_settings_owned.zig");
const matrix_editor_entry = @import("frontier_matrix_editor_entry_owned.zig");
const matrix_editor_refresh = @import("frontier_matrix_editor_refresh_owned.zig");
const matrix_goto_grow = @import("frontier_matrix_goto_grow_owned.zig");
const matrix_lifecycle = @import("frontier_matrix_lifecycle_owned.zig");
const matrix_mim_add = @import("frontier_matrix_mim_add_owned.zig");
const matrix_mutation = @import("frontier_matrix_mutation_owned.zig");
const matrix_nav = @import("frontier_matrix_nav_owned.zig");
const matrix_mim_run = @import("frontier_matrix_mim_run_owned.zig");
const plot_regression = @import("frontier_plot_regression_owned.zig");
const print_register = @import("frontier_print_register_owned.zig");
const program_clear = @import("frontier_program_clear_owned.zig");
const cauchy = @import("frontier_cauchy_owned.zig");
const weibull = @import("frontier_weibull_owned.zig");
const logistic = @import("frontier_logistic_owned.zig");
const exponential = @import("frontier_exponential_owned.zig");
const pareto = @import("frontier_pareto_owned.zig");
const uniform = @import("frontier_uniform_owned.zig");
const gev = @import("frontier_gev_owned.zig");
const geometric = @import("frontier_geometric_owned.zig");
const poisson = @import("frontier_poisson_owned.zig");
const binomial = @import("frontier_binomial_owned.zig");
const neg_binom = @import("frontier_neg_binom_owned.zig");
const hyper = @import("frontier_hyper_owned.zig");
const chi2 = @import("frontier_chi2_owned.zig");
const normal = @import("frontier_normal_owned.zig");
const f_dist = @import("frontier_f_owned.zig");
const t_dist = @import("frontier_t_owned.zig");

// Per-package distribution strip flags, injected by the build (default: keep
// everything). Mirror upstream's SAVE_SPACE_DM42_17B (cauchy/weibull/logistic/
// exponential) and SAVE_SPACE_DM42_17C (pareto/uniform) guards so flash-limited
// firmware packages compile those distribution owners out of the shared object.
const dr = @import("frontier_distribution_runtime.zig");
const frontier_build_options = @import("frontier_build_options");
const strip_16: bool = frontier_build_options.strip_16;
const strip_17: bool = frontier_build_options.strip_17;
const strip_17b: bool = frontier_build_options.strip_17b;
const strip_17c: bool = frontier_build_options.strip_17c;

// realType.c owner: exports low-level real<->int helpers with C linkage. It has
// no command dispatch wrappers, so force its inclusion in the frontier object.
comptime {
    _ = @import("frontier_real_type_owned.zig");
    _ = @import("frontier_free_list_owned.zig");
    _ = @import("frontier_fonts_owned.zig");
    _ = @import("frontier_martel_fonts_owned.zig");
    _ = @import("frontier_printer_font8_owned.zig");
    _ = @import("frontier_conversion_units_owned.zig");
    _ = @import("frontier_conversion_angles_owned.zig");
    _ = @import("frontier_register_value_conversions_owned.zig");
    _ = @import("frontier_date_time_owned.zig");
    _ = @import("frontier_integers_owned.zig");
    _ = @import("frontier_sort_owned.zig");
    _ = @import("frontier_error_owned.zig");
    _ = @import("frontier_lbl_gto_xeq_owned.zig");
    _ = @import("frontier_string_funcs_owned.zig");
    _ = @import("frontier_recall_owned.zig");
    _ = @import("frontier_fractions_owned.zig");
    _ = @import("frontier_store_owned.zig");
    _ = @import("frontier_stats_owned.zig");
    _ = @import("frontier_clcvar_owned.zig");
    _ = @import("frontier_next_step_owned.zig");
    _ = @import("frontier_decode_owned.zig");
    _ = @import("frontier_curve_fitting_owned.zig");
    _ = @import("frontier_input_owned.zig");
    _ = @import("frontier_jm_owned.zig");
    _ = @import("frontier_flag_browser_owned.zig");
    _ = @import("frontier_calc_mode_owned.zig");
    _ = @import("frontier_register_browser_owned.zig");
    _ = @import("frontier_programmable_menu_owned.zig");
    _ = @import("frontier_font_browser_owned.zig");
    _ = @import("frontier_asn_browser_owned.zig");
    _ = @import("frontier_textfiles_owned.zig");
    _ = @import("frontier_xeqm_owned.zig");
    _ = @import("frontier_graphs_owned.zig");
    _ = @import("frontier_manage_owned.zig");
    _ = @import("frontier_tam_owned.zig");
    _ = @import("frontier_assign_owned.zig");
    _ = @import("frontier_status_bar_owned.zig");
    _ = @import("frontier_char_string_owned.zig");
    _ = @import("frontier_graph_text_owned.zig");
    _ = @import("frontier_timer_owned.zig");
    _ = @import("frontier_radio_button_catalog_owned.zig");
    _ = @import("frontier_debug_owned.zig");
}
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
extern fn z47_frontier_matrix_softmenu_has_m_edit() bool;
extern fn z47_frontier_matrix_softmenu_top_is_m_edit() bool;
extern fn z47_frontier_matrix_show_m_edit_softmenu() void;
extern fn z47_frontier_matrix_scroll_row_get() u16;
extern fn z47_frontier_matrix_scroll_row_set(row: u16) void;
extern fn z47_frontier_matrix_render_editor_body(col_vector: bool, rows: i16, cols: i16, mat_sel_row: i16, mat_sel_col: i16) void;
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

fn matrixRunMutation(kind: matrix_mutation.Kind) void {
    if (!matrixEnsureEditorModeOrReturn()) {
        return;
    }

    matrix_mutation.run(kind);
}

pub export fn wrapIJ(rows: u16, cols: u16) callconv(.c) bool {
    return matrix_nav.wrap(rows, cols);
}

pub export fn showMatrixEditor() callconv(.c) void {
    matrix_editor_refresh.run();
}

pub export fn fnEditMatrix(regist: u16) callconv(.c) void {
    matrix_editor_entry.edit(regist);
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

pub export fn mimEnter(commit: bool) callconv(.c) void {
    matrix_lifecycle.enter(commit);
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

pub export fn mimFinalize() callconv(.c) void {
    matrix_lifecycle.finalize();
}

pub export fn mimRestore() callconv(.c) void {
    matrix_lifecycle.restore();
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

// Cauchy/Weibull/Logistic/Exponential are stripped upstream under
// SAVE_SPACE_DM42_17B; Pareto/Uniform under SAVE_SPACE_DM42_17C. On packages
// that strip a cluster the Zig owner must compile to an empty stub so its code
// (and its pulled-in math helpers) does not consume flash. The comptime guard
// makes the owner call unreachable when stripped, so the owner functions are not
// codegen'd into the shared frontier object. See frontier_build_options.

pub export fn fnCauchyP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17b) cauchy.cauchyP(unused_but_mandatory_parameter);
}

pub export fn fnCauchyL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17b) cauchy.cauchyL(unused_but_mandatory_parameter);
}

pub export fn fnCauchyR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17b) cauchy.cauchyR(unused_but_mandatory_parameter);
}

pub export fn fnCauchyI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17b) cauchy.cauchyI(unused_but_mandatory_parameter);
}

pub export fn fnWeibullP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17b) weibull.weibullP(unused_but_mandatory_parameter);
}

pub export fn fnWeibullL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17b) weibull.weibullL(unused_but_mandatory_parameter);
}

pub export fn fnWeibullR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17b) weibull.weibullR(unused_but_mandatory_parameter);
}

pub export fn fnWeibullI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17b) weibull.weibullI(unused_but_mandatory_parameter);
}

pub export fn fnLogisticP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17b) logistic.logisticP(unused_but_mandatory_parameter);
}

pub export fn fnLogisticL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17b) logistic.logisticL(unused_but_mandatory_parameter);
}

pub export fn fnLogisticR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17b) logistic.logisticR(unused_but_mandatory_parameter);
}

pub export fn fnLogisticI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17b) logistic.logisticI(unused_but_mandatory_parameter);
}

pub export fn fnExponentialP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17b) exponential.exponentialP(unused_but_mandatory_parameter);
}

pub export fn fnExponentialL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17b) exponential.exponentialL(unused_but_mandatory_parameter);
}

pub export fn fnExponentialR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17b) exponential.exponentialR(unused_but_mandatory_parameter);
}

pub export fn fnExponentialI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17b) exponential.exponentialI(unused_but_mandatory_parameter);
}

pub export fn fnParetoP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17c) pareto.paretoP(unused_but_mandatory_parameter);
}

pub export fn fnParetoL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17c) pareto.paretoL(unused_but_mandatory_parameter);
}

pub export fn fnParetoU(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17c) pareto.paretoU(unused_but_mandatory_parameter);
}

pub export fn fnParetoI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17c) pareto.paretoI(unused_but_mandatory_parameter);
}

pub export fn fnPareto2P(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17c) pareto.pareto2P(unused_but_mandatory_parameter);
}

pub export fn fnPareto2L(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17c) pareto.pareto2L(unused_but_mandatory_parameter);
}

pub export fn fnPareto2U(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17c) pareto.pareto2U(unused_but_mandatory_parameter);
}

pub export fn fnPareto2I(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17c) pareto.pareto2I(unused_but_mandatory_parameter);
}

pub export fn fnUniformP(discrete: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17c) uniform.uniformP(discrete);
}

pub export fn fnUniformL(discrete: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17c) uniform.uniformL(discrete);
}

pub export fn fnUniformU(discrete: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17c) uniform.uniformU(discrete);
}

pub export fn fnUniformI(discrete: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17c) uniform.uniformI(discrete);
}

pub export fn fnGEVP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17c) gev.gevP(unused_but_mandatory_parameter);
}

pub export fn fnGEVL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17c) gev.gevL(unused_but_mandatory_parameter);
}

pub export fn fnGEVR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17c) gev.gevR(unused_but_mandatory_parameter);
}

pub export fn fnGEVI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17c) gev.gevI(unused_but_mandatory_parameter);
}

pub export fn fnGeometricP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17) geometric.geometricP(unused_but_mandatory_parameter);
}

pub export fn fnGeometricL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17) geometric.geometricL(unused_but_mandatory_parameter);
}

pub export fn fnGeometricR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17) geometric.geometricR(unused_but_mandatory_parameter);
}

pub export fn fnGeometricI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17) geometric.geometricI(unused_but_mandatory_parameter);
}

// Shared discrete-quantile dispatcher (geometric.c). Exported with C linkage so
// the still-C f distribution links against it where the SAVE_SPACE_DM42_17
// cluster is kept; on DM42 (strip_17) the body is empty and the owner is elided.
pub export fn WP34S_qf_discrete_final(
    dist: u16,
    r: *const geometric.real_t,
    p: *const geometric.real_t,
    i: [*c]const geometric.real_t,
    j: [*c]const geometric.real_t,
    k: [*c]const geometric.real_t,
    res: *geometric.real_t,
    ctx: *geometric.realContext_t,
) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17) geometric.wp34sQfDiscreteFinal(dist, r, p, i, j, k, res, ctx);
}

pub export fn fnPoissonP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17) poisson.poissonP(unused_but_mandatory_parameter);
}

pub export fn fnPoissonL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17) poisson.poissonL(unused_but_mandatory_parameter);
}

pub export fn fnPoissonR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17) poisson.poissonR(unused_but_mandatory_parameter);
}

pub export fn fnPoissonI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17) poisson.poissonI(unused_but_mandatory_parameter);
}

// Poisson helpers reached by still-C cluster members where SAVE_SPACE_DM42_17 is
// kept (host, DMCP5): the geometric dispatcher (Cdf2), the f distribution (Pdf),
// and the binomial/hyper/negBinom quantiles (normal_moment_approx). Stubbed with
// the cluster on DM42.
pub export fn WP34S_Cdf_Poisson2(x: *const poisson.real_t, lambda: *const poisson.real_t, res: *poisson.real_t, ctx: *poisson.realContext_t) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17) poisson.wp34sCdfPoisson2(x, lambda, res, ctx);
}

pub export fn WP34S_Pdf_Poisson(x: *const poisson.real_t, lambda: *const poisson.real_t, res: *poisson.real_t, ctx: *poisson.realContext_t) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17) poisson.wp34sPdfPoisson(x, lambda, res, ctx);
}

pub export fn WP34S_normal_moment_approx(prob: *const poisson.real_t, variance: *const poisson.real_t, mean: *const poisson.real_t, res: *poisson.real_t, ctx: *poisson.realContext_t) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17) poisson.wp34sNormalMomentApprox(prob, variance, mean, res, ctx);
}

pub export fn fnBinomialP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17) binomial.binomialP(unused_but_mandatory_parameter);
}

pub export fn fnBinomialL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17) binomial.binomialL(unused_but_mandatory_parameter);
}

pub export fn fnBinomialR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17) binomial.binomialR(unused_but_mandatory_parameter);
}

pub export fn fnBinomialI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17) binomial.binomialI(unused_but_mandatory_parameter);
}

// Binomial helpers reached by still-C cluster members where SAVE_SPACE_DM42_17 is
// kept: the geometric dispatcher / f-distribution Newton solver (Cdf2) and the f
// distribution (Pdf). Stubbed with the cluster on DM42.
pub export fn WP34S_Cdf_Binomial2(x: *const binomial.real_t, p0: *const binomial.real_t, n: *const binomial.real_t, res: *binomial.real_t, ctx: *binomial.realContext_t) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17) binomial.wp34sCdfBinomial2(x, p0, n, res, ctx);
}

pub export fn WP34S_Pdf_Binomial(x: *const binomial.real_t, p0: *const binomial.real_t, n: *const binomial.real_t, res: *binomial.real_t, ctx: *binomial.realContext_t) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17) binomial.wp34sPdfBinomial(x, p0, n, res, ctx);
}

pub export fn fnNegBinomialP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17) neg_binom.negBinomialP(unused_but_mandatory_parameter);
}

pub export fn fnNegBinomialL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17) neg_binom.negBinomialL(unused_but_mandatory_parameter);
}

pub export fn fnNegBinomialR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17) neg_binom.negBinomialR(unused_but_mandatory_parameter);
}

pub export fn fnNegBinomialI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17) neg_binom.negBinomialI(unused_but_mandatory_parameter);
}

// NegBinomial helpers reached by still-C cluster members where SAVE_SPACE_DM42_17
// is kept: the geometric dispatcher / f-distribution Newton solver (cdf2) and the
// f distribution (pdf). Stubbed with the cluster on DM42.
pub export fn cdf_NegBinomial2(x: *const neg_binom.real_t, p0: *const neg_binom.real_t, r: *const neg_binom.real_t, res: *neg_binom.real_t, ctx: *neg_binom.realContext_t) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17) neg_binom.cdfNegBinomial2(x, p0, r, res, ctx);
}

pub export fn pdf_NegBinomial(x: *const neg_binom.real_t, p0: *const neg_binom.real_t, r: *const neg_binom.real_t, res: *neg_binom.real_t, ctx: *neg_binom.realContext_t) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17) neg_binom.pdfNegBinomial(x, p0, r, res, ctx);
}

pub export fn fnHypergeometricP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17) hyper.hypergeometricP(unused_but_mandatory_parameter);
}

pub export fn fnHypergeometricL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17) hyper.hypergeometricL(unused_but_mandatory_parameter);
}

pub export fn fnHypergeometricR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17) hyper.hypergeometricR(unused_but_mandatory_parameter);
}

pub export fn fnHypergeometricI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17) hyper.hypergeometricI(unused_but_mandatory_parameter);
}

// Hypergeometric helpers reached by still-C cluster members where
// SAVE_SPACE_DM42_17 is kept: the geometric dispatcher / f-distribution Newton
// solver (cdf2) and the f distribution (pdf). Stubbed with the cluster on DM42.
pub export fn cdf_Hypergeometric2(x: *const hyper.real_t, k0: *const hyper.real_t, n: *const hyper.real_t, n0: *const hyper.real_t, res: *hyper.real_t, ctx: *hyper.realContext_t) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17) hyper.cdfHypergeometric2(x, k0, n, n0, res, ctx);
}

pub export fn pdf_Hypergeometric(x: *const hyper.real_t, k0: *const hyper.real_t, n: *const hyper.real_t, n0: *const hyper.real_t, res: *hyper.real_t, ctx: *hyper.realContext_t) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17) hyper.pdfHypergeometric(x, k0, n, n0, res, ctx);
}

pub export fn fnChi2P(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17b) chi2.chi2P(unused_but_mandatory_parameter);
}

pub export fn fnChi2L(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17b) chi2.chi2L(unused_but_mandatory_parameter);
}

pub export fn fnChi2R(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17b) chi2.chi2R(unused_but_mandatory_parameter);
}

pub export fn fnChi2I(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17b) chi2.chi2I(unused_but_mandatory_parameter);
}

// checkRegisterNoFP is defined in upstream chi2.c (17B cluster) and used by the
// binomial/hyper/negBinom/f members; export it so they link where the cluster is
// kept. On packages with 17B stripped it is the upstream stub (returns false).
pub export fn checkRegisterNoFP(reg: *const chi2.real_t) linksection(dr.code_section) callconv(.c) bool {
    if (comptime !strip_17b) return chi2.checkRegisterNoFP(reg);
    return false;
}

pub export fn fnStdNormalP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    if (comptime !strip_16) normal.normalP(.std_normal);
}
pub export fn fnStdNormalL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    if (comptime !strip_16) normal.normalL(.std_normal);
}
pub export fn fnStdNormalR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    if (comptime !strip_16) normal.normalR(.std_normal);
}
pub export fn fnStdNormalI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    if (comptime !strip_16) normal.normalI(.std_normal);
}
pub export fn fnNormalP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    if (comptime !strip_16) normal.normalP(.param_normal);
}
pub export fn fnNormalL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    if (comptime !strip_16) normal.normalL(.param_normal);
}
pub export fn fnNormalR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    if (comptime !strip_16) normal.normalR(.param_normal);
}
pub export fn fnNormalI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    if (comptime !strip_16) normal.normalI(.param_normal);
}
pub export fn fnLogNormalP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    if (comptime !strip_16) normal.normalP(.log_normal);
}
pub export fn fnLogNormalL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    if (comptime !strip_16) normal.normalL(.log_normal);
}
pub export fn fnLogNormalR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    if (comptime !strip_16) normal.normalR(.log_normal);
}
pub export fn fnLogNormalI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    if (comptime !strip_16) normal.normalI(.log_normal);
}

// WP34S_qf_q_est (defined in upstream normal.c) and WP34S_Cdf_Q are reached by the
// other (17/17B) distribution members where their clusters are kept; export them.
// On DM42 (cluster 16 stripped) they are the upstream stubs.
pub export fn WP34S_qf_q_est(x: *const normal.real_t, res: *normal.real_t, res_y: [*c]normal.real_t, ctx: *normal.realContext_t) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_16) normal.wp34sQfQEst(x, res, res_y, ctx);
}

pub export fn WP34S_Cdf_Q(x: *const normal.real_t, res: *normal.real_t, ctx: *normal.realContext_t) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_16) normal.wp34sCdfQ(x, res, ctx);
}

pub export fn fnF_P(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17) f_dist.fP(unused_but_mandatory_parameter);
}

pub export fn fnF_L(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17) f_dist.fL(unused_but_mandatory_parameter);
}

pub export fn fnF_R(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17) f_dist.fR(unused_but_mandatory_parameter);
}

pub export fn fnF_I(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17) f_dist.fI(unused_but_mandatory_parameter);
}

// The shared Newton-step solver (f.c) reached by the poisson/binomial/negBinom/
// hyper quantiles where the cluster is kept; stubbed with the cluster on DM42.
pub export fn WP34S_Qf_Newton(
    r_dist: u32,
    target: *const f_dist.real_t,
    estimate: *const f_dist.real_t,
    p1: [*c]const f_dist.real_t,
    p2: [*c]const f_dist.real_t,
    p3: [*c]const f_dist.real_t,
    res: *f_dist.real_t,
    ctx: *f_dist.realContext_t,
) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17) f_dist.wp34sQfNewton(r_dist, target, estimate, p1, p2, p3, res, ctx);
}

pub export fn fnT_P(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17b) t_dist.tP(unused_but_mandatory_parameter);
}

pub export fn fnT_L(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17b) t_dist.tL(unused_but_mandatory_parameter);
}

pub export fn fnT_R(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17b) t_dist.tR(unused_but_mandatory_parameter);
}

pub export fn fnT_I(unused_but_mandatory_parameter: u16) linksection(dr.code_section) callconv(.c) void {
    if (comptime !strip_17b) t_dist.tI(unused_but_mandatory_parameter);
}
