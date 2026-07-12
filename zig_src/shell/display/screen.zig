const std = @import("std");
// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/screen.c: the master LCD renderer. Faithful, byte-for-byte
// port of every public function: the glyph/string rendering core
// (showGlyphCode/showGlyph/showString*/stringWidthC47/stringAfterPixelsC47/
// showStringEdC47), the register-line refresh machinery (the big
// _refreshRegisterLine branch tree, refreshRegisterLine, displayNim,
// displayBaseMode, the temporary-information prefix builders), the screen-clear /
// refresh orchestration (clearScreenOld/clearScreenGraphs/_selectiveClearScreen/
// _refreshNormalScreen/_refreshPemScreen/refreshScreen), the shift/FN long-press
// handlers, the SHOW renderer (showDisp/showDispSmall/showBottomLine), the
// pixel/graph primitives (fnPixel/fnPoint/fnAGraph/fnClLcd), fnSNAP/fnScreenDump,
// and the alpha-cursor inserter.
//
// Build matrix (computed locally; no new build options):
//   * option_tvm_amort = !(dmcp_build and old_hw): the OPTION_TVM_AMORT amort-TI
//     branches. ON for sim/dmcp5 + new_hw pkgs, OFF only for old_hw DMCP.
//   * LONGPRESS_CFG is ON for every target (always live).
//   * STACK_X_STR_MED_FONT is #undef everywhere; only STACK_X_STR_LRG_FONT +
//     STACK_STR_MED_FONT live. TEXT_MULTILINE_EDIT is ON everywhere.
//   * option_vector gates the OPTION_VECTOR vector-component TI helpers (tiVector,
//     the e0/e1/e2 element-name helpers). ON for host/dmcp5, OFF for dmcp pkg1/2/4.
//   * extra_info / ir_printing as the siblings.
//   * Dead/omitted: DISCRIMINANT, GENERATE_CATALOGS, REAL34_WIDTH_TEST==0,
//     VERBOSE_SCREEN/MONITOR_*/ANALYSE_REFRESH/FN_TIME_DEBUG1/DEBUG_SHOWNAME
//     (DEBUGSFN=false)/INLINE_TEST. The #if PC_BUILD clipboard/cairo helpers and
//     the GTK refreshLcd are host-only (comptime !dmcp_build); drawScreen / the
//     copy*ToClipboard / get_binary_bits / refreshLcd are PC-only exports.
//
// DMCP-ROM trampolines (only under dmcp_build; base 0x08000201 old_hw /
// 0x08000301 new_hw, from dep/DMCP_SDK/dmcp/lft_ifc.h):
//   lcd_fill_rect      +60  (lft_ifc.h:61)
//   lcd_refresh        +48  (lft_ifc.h:58)
//   lcd_refresh_lines  +56  (lft_ifc.h:60)
//   lcd_refresh_dma    +644 (lft_ifc.h:207)
//   LCD_write_line     +32  (lft_ifc.h:54)
//   bitblt24           +36  (lft_ifc.h:55)  [via setBlackPixel/setWhitePixel/flipPixel]
// lcd_buffer is a C47-side uint8_t* global (not ROM). placePixel is first-party.
//
// fnSNAP IS owned here; the z47_frontier_snap_* backup helpers it calls are owned
// by screen_snap.zig. No other screen.c symbol is owned elsewhere.
//
// The decNumber/real34 wrapper block mirrors the sibling display/bufferize owners
// exactly (const* macros over `constants`, decQuad*/decNumber* inline wrappers,
// __gmpz_* for longInteger). C int-promotion in the u16 pixel math is reproduced
// with i32 @divTrunc/@rem and u16 +%= wraps. Register real34/complex34 data is
// accessed via *align(1) off the 4-byte block allocator.

const frontier_build_options = @import("frontier_build_options");
const dmcp_build: bool = frontier_build_options.dmcp_build;
const old_hw: bool = frontier_build_options.old_hw;
const extra_info: bool = frontier_build_options.extra_info_on_calc_error;
const ir_printing: bool = frontier_build_options.ir_printing;
const option_vector: bool = frontier_build_options.option_vector;
// OPTION_TVM_AMORT: defines.h #undefs it only for the old_hw single-file pkgs.
const option_tvm_amort: bool = !(dmcp_build and old_hw);

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const bool_t = u8;
const calcRegister_t = i16;
const angularMode_t = c_int;
const videoMode_t = c_int;
const irfracOption_t = c_int;

const DECNUMUNITS = 25;
const abi = @import("abi"); // shared ABI bindings
const frontier = @import("../shell.zig");
const frontier_addons = @import("../extensions/addons.zig");
const frontier_asn_browser = @import("../browsers/asn_browser.zig");
const frontier_assign = @import("../input/assign.zig");
const frontier_bufferize = @import("bufferize.zig");
const frontier_calc_mode = @import("../calc_mode.zig");
const frontier_char_string = @import("text/char_string.zig");
const frontier_config = @import("../config.zig");
const frontier_conversion_units = @import("../convert/conversion_units.zig");
const frontier_curve_fitting = @import("../plot/curve_fitting.zig");
const frontier_date_time = @import("../convert/date_time.zig");
const frontier_debug = @import("../debug.zig");
const frontier_display = @import("display.zig");
const frontier_error = @import("../error.zig");
const frontier_flag_browser = @import("../browsers/flag_browser.zig");
const frontier_font_browser = @import("../browsers/font_browser.zig");
const frontier_fonts = @import("fonts/fonts.zig");
const frontier_graphs = @import("../plot/graphs.zig");
const frontier_items = @import("items/items.zig");
const frontier_lbl_gto_xeq = @import("../program/lbl_gto_xeq.zig");
const frontier_manage = @import("../program/manage.zig");
const frontier_matrix_editor = @import("../matrix_editor/matrix_editor.zig");
const frontier_next_step = @import("../program/next_step.zig");
const frontier_plotstat = @import("../plot/plotstat.zig");
const frontier_radio_button_catalog = @import("../extensions/radio_button_catalog.zig");
const frontier_real_type = @import("../real_type.zig");
const frontier_register_browser = @import("../browsers/register_browser.zig");
const frontier_register_value_conversions = @import("../register_value_conversions.zig");
const frontier_softmenus = @import("softmenus/softmenus.zig");
const frontier_sort = @import("sort.zig");
const frontier_status_bar = @import("statusbar/status_bar.zig");
const frontier_tam = @import("../input/tam.zig");
const frontier_timer = @import("../timer.zig");
const real_t = abi.Real;
const real34_t = abi.Real34;
const complex34_t = abi.Complex34;
const realContext_t = abi.RealContext;

// glyph_t: 24 bytes. byte fields at 2..7, data ptr at 16.
const glyph_t = abi.Glyph;
// font_t is the abi single-source (same layout --
// numberOfGlyphs@2, glyphs@8; .id is never read here so the i8-vs-u16 owner
// difference is inert). glyphsPtr() lives on abi.Font.
const font_t = abi.Font;

const item_t = abi.Item;

const matrixHeader_t = abi.MatrixHeader;
const real34Matrix_t = abi.Real34Matrix;
const complex34Matrix_t = abi.Complex34Matrix;
const any34Matrix_t = abi.Any34Matrix;

// mpz / longInteger
const mp_limb_t = usize;
const mpz_struct = abi.Mpz;
const longInteger_t = [1]mpz_struct;

// calcKey_t: int16 fields. We only touch primary/gShifted.
const calcKey_t = abi.CalcKey;

// softmenu_t {i16 menuItem, i16 numItems, ptr softkeyItem}
const softmenu_t = abi.Softmenu;
// softmenuStack_t {i16 softmenuId, i16 firstItem, i16 userMenuId, u8 calcMode}
const softmenuStack_t = abi.SoftmenuStack;
// confirmationTI_t {i16 item, char[30] string}
const confirmationTI_t = abi.ConfirmationTI;
// reservedVariableDescStr_t { char Desc[28] }
// reservedVariableDescStr_t centralized in abi (oracle-verified == C).
const reservedVariableDescStr_t = abi.ReservedVariableDescStr;
// registerHeader_t: union with bitfields; pointerToRegisterData = low 16 bits.
const registerHeader_t = abi.RegisterHeader;
const namedVariableHeader_t = abi.NamedVariableHeader;
const reservedVariableHeader_t = abi.ReservedVariableHeader;

// ---------------------------------------------------------------------------
// Numeric constants (probed from defines.h / typeDefinitions.h)
// ---------------------------------------------------------------------------
const SCREEN_WIDTH: i16 = 400;
const SCREEN_HEIGHT: i16 = 240;
const REGISTER_LINE_HEIGHT: i16 = 36;
const Y_POSITION_OF_REGISTER_X_LINE: i16 = 132;
const Y_POSITION_OF_REGISTER_Y_LINE: i16 = 96;
const Y_POSITION_OF_REGISTER_Z_LINE: i16 = 60;
const Y_POSITION_OF_REGISTER_T_LINE: i16 = 24;
const Y_POSITION_OF_NIM_LINE: i16 = 132;
const Y_POSITION_OF_TAM_LINE: i16 = 24;
const Y_POSITION_OF_ERR_LINE: i16 = 60;
const Y_POSITION_OF_TRUE_FALSE_LINE: i16 = 60;
const STANDARD_FONT_HEIGHT: i16 = 22;
const SOFTMENU_HEIGHT: u8 = 23;
const LCD_LINE_BUF_SIZE: usize = 54;
const LCD_SET_VALUE: c_int = 0;
const LCD_EMPTY_VALUE: c_int = 255;
const TEMPORARY_INFO_OFFSET: i16 = 6;
const MATRIX_LINE_WIDTH: i16 = 380;
const MATRIX_MAX_COLUMNS: usize = 11;
const MATRIX_MAX_ROWS: usize = 5;
const SHOWLineSize: i16 = 120;
const TMP_STR_LENGTH: usize = 2560;
const ERROR_MESSAGE_LENGTH: usize = 512;
const TAM_BUFFER_LENGTH: usize = 32;
const AIM_BUFFER_LENGTH: usize = 1024;
const NIM_BUFFER_LENGTH: usize = 200;
const SHOWLineMax: i16 = @intCast(TMP_STR_LENGTH / @as(usize, @intCast(SHOWLineSize)));

const vmNormal: videoMode_t = 0;

const stdNoEnlarge: c_int = 0;
const stdEnlarge: c_int = 1;
const stdnumEnlarge: c_int = 2;
const numSmall: c_int = 3;
const numHalf: c_int = 4;
const combinationFontsDefault: u8 = 2;
const DOUBLING_A: u16 = 15; // REPLACEFONT defined; C: DOUBLING = (checkHP ? DOUBLING_A : 6)
const DOUBLINGBASEX: u16 = 8;
const REDUCT_A: c_int = 3;
const REDUCT_B: c_int = 4;
const REDUCT_OFF: c_int = 3;

const NO_LF: bool_t = 0;
const DO_LF: bool_t = 1;
const NO_compress: c_int = 0;
const DO_compress: c_int = 1;
const NO_raise: u8 = 0;
const DO_Show: u8 = 0;
const NO_Bold: u8 = 0;
const nocompress: c_int = 0;
const toRemoveTrailingRadix: bool_t = 1;

const force: u8 = 1;
const timed: u8 = 0;
const SCRUPD_AUTO: u8 = 0;
const SCRUPD_MANUAL_STATUSBAR: u8 = 1;
const SCRUPD_MANUAL_STACK: u8 = 2;
const SCRUPD_MANUAL_MENU: u8 = 4;
const SCRUPD_MANUAL_SHIFT_STATUS: u8 = 8;
const SCRUPD_SKIP_STATUSBAR_ONE_TIME: u8 = 16;
const SCRUPD_SKIP_STACK_ONE_TIME: u8 = 32;
const SCRUPD_SKIP_MENU_ONE_TIME: u8 = 64;
const SCREEN_REFRESH_PERIOD: i16 = if (dmcp_build) 160 else 100; // defines.h: 160 DMCP / 100 host
const FAST_SCREEN_REFRESH_PERIOD: i16 = 100;

// Registers
const REGISTER_X: calcRegister_t = 100;
const REGISTER_Y: calcRegister_t = 101;
const REGISTER_Z: calcRegister_t = 102;
const REGISTER_T: calcRegister_t = 103;
const REGISTER_M: calcRegister_t = 112;
const REGISTER_N: calcRegister_t = 113;
const REGISTER_P: calcRegister_t = 114;
const REGISTER_Q: calcRegister_t = 115;
const REGISTER_R: calcRegister_t = 116;
const REGISTER_S: calcRegister_t = 117;
const REGISTER_I: calcRegister_t = 109;
const REGISTER_J: calcRegister_t = 110;
const REGISTER_K: calcRegister_t = 111;
const FIRST_LETTERED_REGISTER: calcRegister_t = 100;
const LAST_SPARE_REGISTER: calcRegister_t = 125;
const FIRST_LOCAL_REGISTER: calcRegister_t = 7000;
const LAST_LOCAL_REGISTER: calcRegister_t = 7098;
const FIRST_NAMED_VARIABLE: calcRegister_t = 256;
const LAST_NAMED_VARIABLE: calcRegister_t = 1999;
const FIRST_RESERVED_VARIABLE: calcRegister_t = 2000;
const LAST_RESERVED_VARIABLE: calcRegister_t = 2047;
const TEMP_REGISTER_1: calcRegister_t = 135;
const INVALID_VARIABLE = 2199; // untyped: coerces in i16/u16 comparisons
const RESERVED_VARIABLE_UEST: calcRegister_t = 2044;
const RESERVED_VARIABLE_LEST: calcRegister_t = 2045;
const RESERVED_VARIABLE_GRAMOD: calcRegister_t = 2040;
const NIM_REGISTER_LINE: calcRegister_t = 100;
const AIM_REGISTER_LINE: calcRegister_t = 100;
const TRUE_FALSE_REGISTER_LINE: calcRegister_t = 102;
const ERR_REGISTER_LINE: calcRegister_t = 102;
const C47_NULL: u32 = 65535; // 0xFFFF null-block sentinel (was 0; block 0 is valid)

const NUMBER_OF_DISPLAY_DIGITS: i16 = 20;
const LIMITEXP: bool_t = 1;
const FRONTSPACE: bool_t = 1;
const NOIRFRAC: irfracOption_t = 0;
const LIMITIRFRAC: irfracOption_t = 1;
const FULLIRFRAC: irfracOption_t = 3;
const NOPARAM: u16 = 9876;
const noBaseOverride: u8 = 0;

// calcModes
const CM_NORMAL: u8 = 0;
const CM_AIM: u8 = 1;
const CM_NIM: u8 = 2;
const CM_PEM: u8 = 3;
const CM_ASSIGN: u8 = 4;
const CM_REGISTER_BROWSER: u8 = 5;
const CM_FLAG_BROWSER: u8 = 6;
const CM_FONT_BROWSER: u8 = 7;
const CM_PLOT_STAT: u8 = 8;
const CM_ERROR_MESSAGE: u8 = 9;
const CM_BUG_ON_SCREEN: u8 = 10;
const CM_CONFIRMATION: u8 = 11;
const CM_MIM: u8 = 12;
const CM_EIM: u8 = 13;
const CM_TIMER: u8 = 14;
const CM_GRAPH: u8 = 15;
const CM_ASN_BROWSER: u8 = 17;
const CM_LISTXY: u8 = 18;

// data types
const dtLongInteger: u32 = 0;
const dtReal34: u32 = 1;
const dtComplex34: u32 = 2;
const dtTime: u32 = 3;
const dtDate: u32 = 4;
const dtString: u32 = 5;
const dtReal34Matrix: u32 = 6;
const dtComplex34Matrix: u32 = 7;
const dtShortInteger: u32 = 8;
const dtConfig: u32 = 9;

// angular modes
const amRadian: angularMode_t = 0;
const amGrad: angularMode_t = 1;
const amDegree: angularMode_t = 2;
const amDMS: angularMode_t = 3;
const amMultPi: angularMode_t = 4;
const amNone: angularMode_t = 5;
const amSecond: angularMode_t = 6;
const amAngleMask: u32 = 0x0F;
const amPolar: u32 = 16;
const amPolarCYL: u32 = 64;
const amPolarSPH: u32 = 128;

// program run state
const PGM_STOPPED: u8 = 0;
const PGM_RUNNING: u8 = 1;
const PGM_WAITING: u8 = 2;
const PGM_PAUSED: u8 = 3;
const PGM_SINGLE_STEP: u8 = 6;

const SIM_UNSIGN: u8 = 0;

// display formats
const DF_ALL: u8 = 0;
const DF_SCI: u8 = 2;
const DF_UN: u8 = 5;

// items
const ITM_NOP: i16 = 1542;
const ITM_RCL: i16 = 51;
const ITM_XEQ: i16 = 3;
const ITM_GTO: i16 = 2;
const ITM_AVIEW: i16 = 2018;
const ITM_PROMPT: i16 = 2020;
const ITM_BACKSPACE: i16 = 1738;
const ITM_T_LEFT_ARROW: i16 = 1952;
const ITM_T_RIGHT_ARROW: i16 = 1953;
const ITM_NULL: i16 = 0;
const ITM_SNAP: i16 = 1405;
const ITM_ms: i16 = 1909;
const ITM_CC: i16 = 1730;
const ITM_op_j: i16 = 1830;
const ITM_op_j_pol: i16 = 1795;
const ITM_dotD: i16 = 1741;
const ITM_HASH_JM: i16 = 1872;
const ITM_toINT: i16 = 1687;
const ITM_CLRMOD: i16 = 2005;
const LAST_ITEM: i16 = 2870;
const MNU_DYNAMIC: i16 = 1394;
const FIRST_CONSTANT: i16 = 128;
const LAST_CONSTANT: i16 = 212;
const VAR_UEST: i16 = 2545;
const VAR_LEST: i16 = 2546;

// menus
const MNU_Solver_TOOL: i16 = 2376;
const MNU_PARETO: i16 = 1286;
const MNU_GEV: i16 = 1247;
const MNU_BINOM: i16 = 1207;
const MNU_CAUCH: i16 = 1212;
const MNU_WEIBL: i16 = 1267;
const MNU_CHI2: i16 = 1272;
const MNU_T: i16 = 1262;
const MNU_EXPON: i16 = 1217;
const MNU_POISS: i16 = 1257;
const MNU_F: i16 = 1222;
const MNU_GEOM: i16 = 1227;
const MNU_HYPER: i16 = 1232;
const MNU_LOGIS: i16 = 1242;
const MNU_NORML: i16 = 1252;
const MNU_UNIFORM: i16 = 2600;
const MNU_DISUNIFORM: i16 = 2605;
const MNU_SHOW: i16 = 2315;
const MNU_MVAR: i16 = 1398;
const MNU_EQ_EDIT: i16 = 1399;
const MNU_Sf: i16 = 1380;
const MNU_Solver: i16 = 1361;
const MNU_PLOT_FUNC: i16 = 2028;
const MNU_HPLOT: i16 = 1402;
const MNU_PLOT_ASSESS: i16 = 1396;
const MNU_PLOT_SCATR: i16 = 1395;
const MNU_ALPHA: i16 = 1922;
const MNU_HOME: i16 = 1921;
const MNU_TAMALPHA: i16 = 1913;
const MNU_MyAlpha: i16 = 1350;
const MNU_AIMCATALOG: i16 = 2552;
const MNU_MyMenu: i16 = 1349;
const MNU_XXFCNS: i16 = 2596;
const MNU_BASE: i16 = 1923; // -MNU_BASE used in BASEMODEACTIVE

const PROBMENUSTART1: i16 = 1207;
const PROBMENUEND1: i16 = 1296;
const PROBMENUSTART2: i16 = 2600;
const PROBMENUEND2: i16 = 2619;

const SOFTMENU_STACK_SIZE: usize = 8;
const SOLVER_STATUS_INTERACTIVE: u16 = 2;
const SOLVER_STATUS_USES_FORMULA: u16 = 256;
const SOLVER_STATUS_EQUATION_MODE: u16 = 8204;
const SOLVER_STATUS_EQUATION_INTEGRATE: u16 = 4;

// radio-button longpress modes
const RBX_F1234: u16 = 223;
const RBX_F124: u16 = 222;
const RBX_F14: u16 = 221;
const RBX_M124: u16 = 225;

// calc models
const USER_R47: u8 = 66;
const USER_C47: u8 = 46;
const USER_DM42: u8 = 45;
const USER_R47bk_fg: u8 = 62;
const USER_R47fg_bk: u8 = 63;
const USER_R47fg_g: u8 = 64;

// FN state machine
const ST_1_PRESS1: u8 = 1;
const ST_3_PRESS2: u8 = 3;
const TMR_COMPLETED: u8 = 3;

// timers
const TO_FG_LONG: u8 = 0;
const TO_CL_LONG: u8 = 1;
const TO_FG_TIMR: u8 = 2;
const TO_FN_LONG: u8 = 3;
const TO_ASM_ACTIVE: u8 = 9;
const TO_3S_CTFF: u8 = 5;
const TO_KB_ACTV: u8 = 10;
const TO_TIMER_APP: u8 = 8;
const TIMER_APP_PERIOD: u32 = 100;
const TO_KB_ACTV_MEDIUM: u32 = 6000;
const TIME_FN_1234_F_TO_G: u32 = 560;
const TIME_FN_124_F_TO_NOP: u32 = 560;
const TIME_FN_1234_G_TO_NOP: u32 = 504;
const JM_TO_FG_LONG: u32 = 580;
const JM_TO_CL_LONG: u32 = 800;

// flags (defines.h)
const FLAG_FGLNFUL: c_int = 0x8063;
const FLAG_FGLNLIM: c_int = 0x8062;
const FLAG_FGGR: c_int = 0x8064;
const FLAG_ALPHA: c_int = 0x800e;
const FLAG_USER: c_int = 0x8014;
const FLAG_MONIT: c_int = 0x8040;
const FLAG_FRACT: c_int = 0x8007;
const FLAG_DREAL: c_int = 0x804a;
const FLAG_2TO10: c_int = 0x803d;
const FLAG_LARGELI: c_int = 0x8046;
const FLAG_BCD: c_int = 0x8059;
const FLAG_SSIZE8: c_int = 0x8018;
const FLAG_USB: c_int = 0xc028;
const FLAG_3DXYZ: c_int = 0x8066;
const FLAG_3DPHYS: c_int = 0x8065;
const FLAG_DMY: c_int = 0xc002;
const FLAG_MDY: c_int = 0xc003;
const FLAG_BOLD: c_int = 0x8069;
const FLAG_BASE_MYM: c_int = 0x805c;
const FLAG_BASE_HOME: c_int = 0x805e;
const FLAG_CPXj: c_int = 0x8005;
const FLAG_MULTx: c_int = 0x801b;
const FLAG_SBshfR: c_int = 0x803b;
const FLAG_SBdate: c_int = 0x802c;
const FLAG_SBtime: c_int = 0x802d;
const FLAG_SBwoy: c_int = 0x8057;

// errors
const ERROR_NONE: u8 = 0;
const ERROR_OUT_OF_RANGE: u8 = 8;
const ERROR_INVALID_DATA_TYPE_FOR_OP: u8 = 24;
const ERROR_UNDEF_SOURCE_VAR: u8 = 36;
const ERROR_LABEL_NOT_FOUND: u8 = 6;
const ERROR_RESERVED_VARIABLE_NAME: u8 = 61;
const ERROR_INVALID_TYPE_XFN: u8 = 62;
const ERROR_TI_UNDO_FAILED: usize = 128; // defines.h 128; matches errorMessages[128] after the table was un-truncated

const PRN_STK: u16 = 1;
const clrStatusBar: bool_t = 1;
const clrRegisterLines: bool_t = 1;
const clrSoftkeys: bool_t = 1;
const toDisplayVectorMatrix: bool_t = 1;
const CMP_BINARY: i32 = 0;

// errorMessages[] string-table indices used by screen.c (these are #define'd
// indices into the errorMessages array; reproduce by their numeric values).
const TI_All_data_prgms_cleared: usize = 118;
const TI_All_user_prgms_deleted: usize = 121;
const TI_All_user_flags_cleared: usize = 117;
const TI_All_user_menus_cleared: usize = 119;
const TI_All_user_vars_cleared: usize = 120;
const TI_All_user_menus_deleted: usize = 122;
const TI_All_user_vars_deleted: usize = 123;
const TI_Not_on_simulator: usize = 126; // defines.h 126 (errorMessages index)
const TI_Only_on_simulator: usize = 127; // defines.h 127 (errorMessages index)
const TI_Backup_restored: usize = 107;
const TI_State_file_restored: usize = 108;
const TI_Saved_programs_and_equations: usize = 109;
const TI_appended: usize = 110;
const TI_Saved_global_and_local_registers: usize = 111;
const TI_w_local_flags_restored: usize = 112;
const TI_Saved_system_settings_restored: usize = 113;
const TI_Saved_statistic_data_restored: usize = 114;
const TI_Saved_user_variables_restored: usize = 115;
const TI_Program_file_loaded: usize = 116;

// CF_ fitting selection codes (curveFitting.h)
const CF_ORTHOGONAL_FITTING: u16 = 512;
const CF_CAUCHY_FITTING: u16 = 128;
const CF_GAUSS_FITTING: u16 = 256;
const CF_PARABOLIC_FITTING: u16 = 64;
const ID_DP: u8 = 2;

// ---------------------------------------------------------------------------
// temporaryInformation_t enum values (probed)
// ---------------------------------------------------------------------------
const TI_NO_INFO: u8 = 0;
const TI_RADIUS_THETA: u8 = 1;
const TI_RADIUS_THETA_SWAPPED: u8 = 2;
const TI_THETA_RADIUS: u8 = 3;
const TI_X_Y: u8 = 4;
const TI_X_Y_SWAPPED: u8 = 5;
const TI_RE_IM: u8 = 6;
const TI_STATISTIC_SUMS: u8 = 7;
const TI_RESET: u8 = 8;
const TI_ARE_YOU_SURE: u8 = 9;
const TI_VERSION: u8 = 10;
const TI_WHO: u8 = 11;
const TI_FALSE: u8 = 12;
const TI_TRUE: u8 = 13;
const TI_SHOW_REGISTER: u8 = 14;
const TI_VIEW_REGISTER: u8 = 15;
const TI_SUMX_SUMY: u8 = 16;
const TI_MEANX_MEANY: u8 = 17;
const TI_MEANX: u8 = 18;
const TI_GEOMMEANX_GEOMMEANY: u8 = 19;
const TI_WEIGHTEDMEANX: u8 = 20;
const TI_HARMMEANX_HARMMEANY: u8 = 21;
const TI_RMSMEANX_RMSMEANY: u8 = 22;
const TI_WEIGHTEDSAMPLSTDDEV: u8 = 23;
const TI_WEIGHTEDPOPLSTDDEV: u8 = 24;
const TI_WEIGHTEDSTDERR: u8 = 25;
const TI_SAMPLSTDDEV: u8 = 26;
const TI_POPLSTDDEV: u8 = 27;
const TI_STDERR: u8 = 28;
const TI_GEOMSAMPLSTDDEV: u8 = 29;
const TI_GEOMPOPLSTDDEV: u8 = 30;
const TI_GEOMSTDERR: u8 = 31;
const TI_SAVED: u8 = 32;
const TI_BACKUP_RESTORED: u8 = 33;
const TI_XMIN_YMIN: u8 = 34;
const TI_XMAX_YMAX: u8 = 35;
const TI_DAY_OF_WEEK: u8 = 36;
const TI_CORR: u8 = 39;
const TI_SMI: u8 = 40;
const TI_LR: u8 = 41;
const TI_CALCX: u8 = 42;
const TI_CALCY: u8 = 43;
const TI_CALCX2: u8 = 44;
const TI_STATISTIC_LR: u8 = 45;
const TI_STATISTIC_HISTO: u8 = 46;
const TI_SA: u8 = 47;
const TI_INACCURATE: u8 = 48;
const TI_UNDO_DISABLED: u8 = 49;
const TI_SOLVER_VARIABLE: u8 = 51;
const TI_ACC: u8 = 53;
const TI_ULIM: u8 = 54;
const TI_LLIM: u8 = 55;
const TI_INTEGRAL: u8 = 56;
const TI_1ST_DERIVATIVE: u8 = 57;
const TI_2ND_DERIVATIVE: u8 = 58;
const TI_KEYS: u8 = 59;
const TI_MEDIANX_MEDIANY: u8 = 60;
const TI_Q1X_Q1Y: u8 = 61;
const TI_Q3X_Q3Y: u8 = 62;
const TI_MADX_MADY: u8 = 63;
const TI_IQRX_IQRY: u8 = 64;
const TI_RANGEX_RANGEY: u8 = 65;
const TI_PCTILEX_PCTILEY: u8 = 66;
const TI_CONV_MENU_STR: u8 = 67;
const TI_PERC: u8 = 68;
const TI_PERCD: u8 = 69;
const TI_PERCD2: u8 = 70;
const TI_STATEFILE_RESTORED: u8 = 71;
const TI_ABC: u8 = 72;
const TI_ABBCCA: u8 = 73;
const TI_012: u8 = 74;
const TI_SHOW_REGISTER_BIG: u8 = 75;
const TI_SHOW_REGISTER_SMALL: u8 = 76;
const TI_SHOW_REGISTER_TINY: u8 = 77;
const TI_BATTV: u8 = 78;
const TI_FROM_DMS: u8 = 79;
const TI_FROM_MS_TIME: u8 = 80;
const TI_FROM_MS_DEG: u8 = 81;
const TI_FROM_HMS: u8 = 82;
const TI_DISP_JULIAN: u8 = 83;
const TI_FROM_DATEX: u8 = 84;
const TI_LAST_CONST_CATNAME: u8 = 85;
const TI_PROGRAM_LOADED: u8 = 86;
const TI_PROGRAMS_RESTORED: u8 = 87;
const TI_REGISTERS_RESTORED: u8 = 88;
const TI_SETTINGS_RESTORED: u8 = 89;
const TI_SUMS_RESTORED: u8 = 90;
const TI_VARIABLES_RESTORED: u8 = 91;
const TI_SCATTER_SMI: u8 = 92;
const TI_SHOWNOTHING: u8 = 93;
const TI_COPY_FROM_SHOW: u8 = 94;
const TI_DATA_LOSS: u8 = 95;
const TI_CLEAR_ALL_FLAGS: u8 = 96;
const TI_CLEAR_ALL_MENUS: u8 = 97;
const TI_CLEAR_ALL_VARIABLES: u8 = 98;
const TI_DEL_ALL_PRGMS: u8 = 99;
const TI_DEL_ALL_MENUS: u8 = 100;
const TI_DEL_ALL_VARIABLES: u8 = 101;
const TI_ROOTS2: u8 = 102;
const TI_ROOTS3: u8 = 103;
const TI_IJ: u8 = 104;
const TI_I: u8 = 105;
const TI_J: u8 = 106;
const TI_MIJ: u8 = 107;
const TI_BYTES: u8 = 108;
const TI_BITS: u8 = 109;
const TI_SOLVER_VARIABLE_RESULT: u8 = 110;
const TI_DATA_NEG_OVRFL: u8 = 111;
const TI_LASTSTATEFILE: u8 = 112;
const TI_FUNCTION: u8 = 113;
const TI_STORCL: u8 = 114;
const TI_TVM_EFF: u8 = 115;
const TI_TVM_IA: u8 = 116;
const TI_NOT_AVAILABLE: u8 = 117;
const TI_DISP_WOY: u8 = 118;
const TI_DISP_JULIAN_WOY: u8 = 119;
const TI_WOY: u8 = 120;
const TI_WOY_RULE: u8 = 121;
const TI_MIJEQ: u8 = 122;
const TI_REGTYPE: u8 = 123;
const TI_LR_A0: u8 = 124;
const TI_LR_A1: u8 = 125;
const TI_LR_A2: u8 = 126;
const TI_VECTOR: u8 = 127;
const TI_VECTORCOMP_3DSPH: u8 = 128;
const TI_VECTORCOMP_3DCYL: u8 = 129;
const TI_VECTORCOMP_3DRECT: u8 = 130;
const TI_VECTORCOMP_2DPOLAR: u8 = 131;
const TI_VECTORCOMP_2DRECT: u8 = 132;
const TI_ELLIPSE_K: u8 = 133;
const TI_ELLIPSE_M: u8 = 134;
const TI_ELLIPSE_Theta: u8 = 135;
const TI_PRINT_COMPLETE: u8 = 136;
const TI_AMORT_BAL: u8 = 137;
const TI_AMORT_PRN: u8 = 138;
const TI_AMORT_INT: u8 = 139;
const TI_AMORT_P1: u8 = 140;
const TI_AMORT_P2: u8 = 141;
const TI_INTEGRAL_unused = {};

// ---------------------------------------------------------------------------
// STD_* byte sequences (fonts.h) -- probed
// ---------------------------------------------------------------------------
const STD_CR = "\xa1\xb5";
const STD_SPACE = "\x20";
const STD_SPACE_4_PER_EM = "\xa0\x05";
const STD_SPACE_3_PER_EM = "\xa0\x04";
const STD_SPACE_FIGURE = "\xa0\x07";
const STD_SPACE_6_PER_EM = "\xa0\x06";
const STD_SPACE_HAIR = "\xa0\x0a";
const STD_SUB_0 = "\xa0\x80";
const STD_SUB_1 = "\xa0\x81";
const STD_SUB_2 = "\xa0\x82";
const STD_SUB_3 = "\xa0\x83";
const STD_SUB_r = "\xa4\xad";
const STD_SUB_c = "\xa4\x9e";
const STD_SUB_x = "\xa4\xb3";
const STD_SUB_y = "\xa4\xb4";
const STD_SUB_z = "\xa4\xb5";
const STD_SUB_i = "\xa4\xa4";
const STD_SUB_j = "\xa4\xa5";
const STD_SUB_k = "\xa4\xa6";
const STD_SUB_m = "\xa4\xa8";
const STD_SUB_a = "\xa4\x9c";
const STD_SUB_n = "\xa4\xa9";
const STD_SUB_w = "\xa4\xb2";
const STD_SUB_p = "\xa4\xab";
const STD_SUB_e = "\xa4\xa0";
const STD_SUB_v = "\xa4\xb1";
const STD_SUB_G = "\xa4\xd6";
const STD_SUB_H = "\xa4\xd7";
const STD_SUB_R = "\xa4\xe1";
const STD_SUB_M = "\xa4\xdc";
const STD_SUB_S = "\xa4\xe2";
const STD_SUB_P = "\xa4\xdf";
const STD_SUP_0 = "\xa1\x60";
const STD_SUP_MINUS = "\xa1\x6b";
const STD_SUP_1 = "\xa1\x61";
const STD_SUP_2 = "\xa1\x62";
const STD_SUP_pir = "\xac\x66";
const STD_SUP_BOLD_r = "\x82\xb3";
const STD_SUP_BOLD_g = "\x9d\x4d";
const STD_SUP_ASTERISK = "\xa0\x8f";
const STD_DEGREE = "\x80\xb0";
const STD_pi = "\x83\xc0";
const STD_theta_m = "\x83\xb8";
const STD_phi_m = "\x83\xd5";
const STD_rho = "\x83\xc1";
const STD_mu = "\x83\xbc";
const STD_MU = "\x83\x9c";
const STD_sigma = "\x83\xc3";
const STD_SIGMA = "\x83\xa3";
const STD_alpha = "\x83\xb1";
const STD_xi = "\x83\xbe";
const STD_nu = "\x83\xbd";
const STD_lambda = "\x83\xbb";
const STD_gamma = "\x83\xb3";
const STD_epsilon = "\x83\xb5";
const STD_DELTA = "\x83\x94";
const STD_x_BAR = "\x83\x78";
const STD_y_BAR = "\x82\x33";
const STD_x_CIRC = "\x83\x79";
const STD_y_CIRC = "\x81\x77";
const STD_UP_ARROW = "\xa1\x91";
const STD_DOWN_ARROW = "\xa1\x93";
const STD_INTEGRAL = "\xa2\x2b";
const STD_ALMOST_EQUAL = "\xa2\x48";
const STD_SQUARE_ROOT = "\xa2\x1a";
const STD_INTEGER_Z = "\xa1\x24";
const STD_INTEGER_Z_SMALL = "\xa1\x25";
const STD_ELLIPSIS = "\xa0\x26";
const STD_CURSOR = "\xa4\x27";
const STD_LEFT_SINGLE_QUOTE = "\xa0\x18";
const STD_RIGHT_SINGLE_QUOTE = "\xa0\x19";
const STD_CROSS = "\x80\xd7";
const STD_DOT = "\x80\xb7";
const STD_op_i = "\xa1\x48";
const STD_op_j = "\xa1\x49";
const STD_a_RING = "\x80\xe5";
const STD_f = "\x66";
const STD_g = "\x67";
const STD_MODE_F = "\x9e\x9d";
const STD_MODE_G = "\x9e\x9f";
const STD_p = "\x70";
const STD_n = "\x6e";
const STD_k = "\x6b";
const STD_N = "\x4e";
const STD_K = "\x4b";
const STD_a = "\x61";
const STD_b = "\x62";
const STD_d = "\x64";
const STD_s = "\x73";
const STD_x = "\x78";
const STD_NOCHAR: u8 = 1;

// ---------------------------------------------------------------------------
// const34_* : constantPointers.h macros over the `constants` blob.
// ---------------------------------------------------------------------------
const constR = abi.constants.cstRAligned;
const constR34 = abi.constants.cst34;
const const_1000 = constR(5456);
// const34_0 / const34_1e6 : real34 constants. (offsets via constantPointers.h)
const const34_0 = constR34(16276);
const const34_1e6 = constR34(16932);

// ---------------------------------------------------------------------------
// font tables (real extern const structs, taken by &name).
// ---------------------------------------------------------------------------
extern const standardFont: font_t;
extern const numericFont: font_t;
extern const numericFontBold: font_t; // FLAG_BOLD bold numeric font (rasterFontsData)
extern const tinyFont: font_t;
const glyphNotFound = @extern(*const glyph_t, .{ .name = "glyphNotFound" });

// C arrays bound by address.
const indexOfItems = @extern([*c]const item_t, .{ .name = "indexOfItems" });
const softmenu = @extern([*c]const softmenu_t, .{ .name = "softmenu" });
const softmenuStack = @extern([*c]softmenuStack_t, .{ .name = "softmenuStack" });
const allReservedVariables = @extern([*c]const reservedVariableHeader_t, .{ .name = "allReservedVariables" });
// `namedVariableHeader_t *allNamedVariables` is a POINTER global (dynamically
// alloc'd array), not an array symbol: the `extern var` form loads the pointer
// VALUE; @extern([*c]...) would load &allNamedVariables. Matches the
// 13 sibling owners that bind it as `extern var`.
extern var allNamedVariables: [*c]const namedVariableHeader_t;
// C: `const int KEY_X[7] = {-1, 66, ...}` -- signed 4-byte ints (KEY_X[0] is
// -1). It must be c_int: a u16 view both mis-sizes the elements and turns -1
// into 65535 (KEY_X[0]+1 then overflows u16).
const KEY_X = @extern([*c]const c_int, .{ .name = "KEY_X" });
const confirmationTI = @extern([*c]const confirmationTI_t, .{ .name = "confirmationTI" });
const varDescr = @extern([*c]const reservedVariableDescStr_t, .{ .name = "varDescr" });
const registerFlagLetters = @extern([*c]const u8, .{ .name = "registerFlagLetters" });
// errorMessages is a 2D char array [NUMBER_OF_ERROR_CODES][SIZE_OF_EACH_ERROR_MESSAGE]
// (48-byte rows); errorMessages[i] is the row address (a char*), NOT a pointer to
// deref. Bind as rows and pass &errorMessages[i].
const SIZE_OF_EACH_ERROR_MESSAGE: usize = 48;
const errorMessages = @extern([*c]const [SIZE_OF_EACH_ERROR_MESSAGE]u8, .{ .name = "errorMessages" });
const commonBugScreenMessages = @extern([*c]const [100]u8, .{ .name = "commonBugScreenMessages" });

// A NUL-terminated view of an errorMessages row for std.fmt {s}. The row
// pointer inherits `allowzero` from the [*c] blob base, which {s} rejects; one
// localized cast here yields the plain [:0]const u8 the formatter wants.
inline fn errMsgRow(idx: anytype) [:0]const u8 {
    return std.mem.sliceTo(@as([*:0]const u8, @ptrCast(&errorMessages[idx])), 0);
}
const baseDigits = @extern([*c]const u8, .{ .name = "baseDigits" });
const kbd_usr = @extern([*c]const calcKey_t, .{ .name = "kbd_usr" });
// lcd_buffer is a C47-side `uint8_t *lcd_buffer` POINTER global (NOT ROM): the
// symbol's storage holds the pointer to the malloc'd framebuffer. Binding it
// `@extern([*c]u8)` yields &lcd_buffer (a .data address), so indexing it ran off
// the data segment -> SIGSEGV on the R47 f/g underline path (same class as
// screenData). Bind the pointer's storage and deref.
const lcd_bufferPtr = @extern(*[*c]u8, .{ .name = "lcd_buffer" });
inline fn lcd_buffer() [*c]u8 {
    return lcd_bufferPtr.*;
}

const bugMsgValueReturnedByFindGlyph: usize = 3; // typeDefinitions.h:315 — index into commonBugScreenMessages[] (was 0 = wrong message)

// ---------------------------------------------------------------------------
// File-local TO_QSPI const strings (upstream screen.c statics; not referenced by
// other C units, so kept private here -- pure bytes).
// ---------------------------------------------------------------------------
const spc = STD_SPACE;
const spc1 = STD_SPACE ++ STD_SPACE_3_PER_EM;
const whoStr1: [*:0]const u8 = "C47 & R47 Development since 2019" ++ spc ++ "by" ++ spc1 ++
    "\n" ++
    "Ben" ++ spc ++ "GB," ++ spc1 ++
    "D" ++ spc ++ "A" ++ spc ++ "CA," ++ spc1 ++
    "Dani" ++ spc ++ "CH," ++ spc1 ++
    "Didier" ++ spc ++ "FR," ++ spc1 ++
    "\n" ++
    "H" ++ STD_a_RING ++ "kon" ++ spc ++ "NO," ++ spc1 ++
    "Jaco" ++ spc ++ "ZA," ++ spc1 ++
    "Martin" ++ spc ++ "FR," ++ spc1 ++
    "Mihail" ++ spc ++ "JP," ++ spc1 ++
    "\n" ++
    "Pauli" ++ spc ++ "AU," ++ spc1 ++
    "RJvM" ++ spc ++ "NL," ++ spc1 ++
    "Walter" ++ spc ++ "DE.";

// MODELTEXT: CALCMODEL==USER_R47 ? "R47" : "C47". All z47 targets are C47 builds.
const MODELTEXT = "C47";
const disclaimerStr: [*:0]const u8 = "  " ++ MODELTEXT ++ " firmware is free, open source and \n  neither provided nor supported by \n  SwissMicros. Press a key to continue.";

// versionStr / versionStr2 embed VERSION_STRING (generated VCS id) and __DATE__,
// which cannot be reproduced byte-faithfully in pure Zig; the residual C helper
// (zig_bridge/frontier/screen_snap_helpers.c) defines them. They are C arrays, so
// bind to the byte address.
const versionStr = @extern([*c]const u8, .{ .name = "versionStr" });
const versionStr2 = @extern([*c]const u8, .{ .name = "versionStr2" });

// nameOfWday_en[8] : nstr { char itemName[30]; }. File-local in screen.c.
const nstr = struct { itemName: [30]u8 };
fn wday(comptime s: []const u8) nstr {
    var r = nstr{ .itemName = std.mem.zeroes([30]u8) };
    @memcpy(r.itemName[0..s.len], s);
    return r;
}
const nameOfWday_en: [8]nstr = .{
    wday("invalid day of week"),
    wday("Monday"),
    wday("Tuesday"),
    wday("Wednesday"),
    wday("Thursday"),
    wday("Friday"),
    wday("Saturday"),
    wday("Sunday"),
};

// ---------------------------------------------------------------------------
// tamState_t (only .mode / .alpha touched).
// ---------------------------------------------------------------------------
const tamState_t = abi.TamState;
// Owned module-scope globals (screen.c defines these). External linkage.
// ---------------------------------------------------------------------------
pub export var blockMonitoring: bool_t = 0; // = false
pub export var cursorBlinkCounter: i8 = 0;
pub export var yUnderlined: u16 = 3;
pub export var combinationFonts: u8 = combinationFontsDefault;
pub export var miniC: u8 = 0;
pub export var maxiC: u8 = 0;
pub export var noShow: bool_t = 0; // = false
pub export var displaymode: u8 = stdNoEnlarge;
pub export var boldString: u8 = 0;
pub export var compressString: u8 = 0;
pub export var raiseString: u8 = 0;
pub export var refreshScreenCounter: i16 = 0;

// ---------------------------------------------------------------------------
// Extern globals (defined in the c47 globals hub / sibling owners).
// ---------------------------------------------------------------------------
extern var lastIntegerBase: u32;
extern var screenUpdatingMode: u8;
extern var refreshNIMdone: bool_t;
extern var calcMode: u8;
extern var temporaryInformation: u8;
extern var lastErrorCode: u8;
extern var displayStack: u8;
extern var dispBase: u8;
extern var currentInputVariable: u16;
extern var currentViewRegister: u16;
extern var showRegis: u16;
extern var overrideShowBottomLine: u8;
extern var programRunStop: u8;
extern var displayFormat: u8;
extern var displayFormatDigits: u8;
extern var shortIntegerWordSize: u8;
extern var shortIntegerMode: u8;
extern var cursorEnabled: bool_t;
extern var cursorFont: ?*const font_t;
extern var fontForShortInteger: ?*const font_t;
extern var xCursor: u32;
extern var yCursor: u32;
extern var matrixIndex: u16;
extern var errorMessageRegisterLine: calcRegister_t;
extern var displayAIMbufferoffset: i16;
extern var multiEdLines: u8;
extern var T_cursorPos: i16;
extern var xMultiLineEdOffset: u8;
extern var yMultiLineEdOffset: u8;
extern var last_CM: u8;
extern var currentSolverVariable: u16;
extern var currentSolverStatus: u16;
extern var currentMvarLabel: u16;
extern var solverEstimatesUsed: bool_t;
extern var lrChosen: u16;
extern var lrSelection: u16;
extern var shiftF: bool_t;
extern var shiftG: bool_t;
extern var FN_state: u8;
extern var FN_key_pressed: i16;
extern var FN_timeouts_in_progress: bool_t;
extern var FN_timed_out_to_RELEASE_EXEC: bool_t;
extern var FN_timed_out_to_NOP_or_Executed: bool_t;
extern var FN_handle_timed_out_to_EXEC: bool_t;
extern var LongPressF: u8;
extern var LongPressM: u8;
extern var Shft_LongPress_f_g: bool_t;
extern var Shft_timeouts: bool_t;
extern var itemToBeAssigned: i16;
extern var previousCalcMode: u8;
extern var keyActionProcessed: bool_t;
extern var keyStateCode: u8;
extern var currentKeyCode: u8;
extern var JM_auto_longpress_enabled: i16;
extern var longpressDelayedkey2: i16;
extern var longpressDelayedkey3: i16;
extern var delayCloseNim: bool_t;
extern var catalog: i16;
extern var dynamicMenuItem: i16;
extern var doRefreshSoftMenu: bool_t;
extern var hourGlassIconEnabled: bool_t;
extern var reDraw: bool_t;
extern var plotSelection: u16;
extern var lastDenominator: u32;
extern var lastI: u16;
extern var lastJ: u16;
extern var firstDayOfWeek: u8;
extern var firstWeekOfYearDay: u8;
extern var firstGregorianDay: u32;
extern var skippedStackLines: bool_t;
extern var secTick1: bool_t;
extern var halfSecTick2: bool_t;
extern var halfSecTick3: bool_t;
extern var displayStackSHOIDISP: u8;
extern var BASE_OVERRIDEONCE: bool_t;
extern var systemFlags0: u64;
extern var ctxtReal34: realContext_t;
extern var ctxtReal39: realContext_t;
extern var tam: tamState_t;
extern var statisticalSumsPointer: [*c]real_t;
extern var openMatrixMIMPointer: any34Matrix_t;
// owned by c47.zig
extern var showFunctionNameArg: [*c]u8;
extern var showFunctionNameItem: i16;
extern var showFunctionNameCounter: i16;
extern var lineTWidth: i16;
extern var cachedDisplayStack: u8;
// genuine char* buffers
extern var tmpString: [*c]u8;
extern var errorMessage: [*c]u8;
extern var aimBuffer: [*c]u8;
extern var tamBuffer: [*c]u8;
extern var nimBufferDisplay: [*c]u8;
extern var userKeyLabel: [*c]u8;
extern var current_cursor_x: u16;
extern var current_cursor_y: u16;
extern var alphaCursor: i16;

const SIGMA_N = struct {
    inline fn ptr() *const real_t {
        return @ptrCast(statisticalSumsPointer);
    }
};

// ---------------------------------------------------------------------------
// min/max/mod (C macros). C int-promotes; we operate in i32 then narrow.
// ---------------------------------------------------------------------------
inline fn minI(a: i32, b: i32) i32 {
    return if (a < b) a else b;
}
inline fn maxI(a: i32, b: i32) i32 {
    return if (a > b) a else b;
}
inline fn absI(a: i32) i32 {
    return if (a < 0) -a else a;
}
// mod(n,d) = (((n%d)+d)%d)
inline fn mod(n: i32, d: i32) i32 {
    return @rem(@rem(n, d) + d, d);
}

// ---------------------------------------------------------------------------
// DMCP-ROM trampolines (only under dmcp_build; from lft_ifc.h).
// ---------------------------------------------------------------------------
const LIBRARY_FN_BASE: usize = if (old_hw) 0x08000201 else 0x08000301;

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

const LcdRefreshFn = *const fn () callconv(.c) void;
const c_lcd_refresh = @extern(LcdRefreshFn, .{ .name = "lcd_refresh" });
inline fn lcd_refresh() void {
    if (comptime dmcp_build) {
        const f: LcdRefreshFn = @ptrFromInt(LIBRARY_FN_BASE + 48);
        f();
    } else {
        c_lcd_refresh();
    }
}

const LcdRefreshLinesFn = *const fn (ln: c_int, cnt: c_int) callconv(.c) void;
const c_lcd_refresh_lines = @extern(LcdRefreshLinesFn, .{ .name = "lcd_refresh_lines" });
inline fn lcd_refresh_lines(ln: c_int, cnt: c_int) void {
    if (comptime dmcp_build) {
        const f: LcdRefreshLinesFn = @ptrFromInt(LIBRARY_FN_BASE + 56);
        f(ln, cnt);
    } else {
        c_lcd_refresh_lines(ln, cnt);
    }
}

const LcdRefreshDmaFn = *const fn () callconv(.c) void;
const c_lcd_refresh_dma = @extern(LcdRefreshDmaFn, .{ .name = "lcd_refresh_dma" });
inline fn lcd_refresh_dma() void {
    if (comptime dmcp_build) {
        const f: LcdRefreshDmaFn = @ptrFromInt(LIBRARY_FN_BASE + 644);
        f();
    } else {
        c_lcd_refresh_dma();
    }
}

const LcdWriteLineFn = *const fn (buf: [*c]u8) callconv(.c) void;
const c_LCD_write_line = @extern(LcdWriteLineFn, .{ .name = "LCD_write_line" });
inline fn LCD_write_line(buf: [*c]u8) void {
    if (comptime dmcp_build) {
        const f: LcdWriteLineFn = @ptrFromInt(LIBRARY_FN_BASE + 32);
        f(buf);
    } else {
        c_LCD_write_line(buf);
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
// lcd_buffer_pixel_on tests one pixel of the 1bpp frame buffer. Only the PC and
// testSuite screen dumps read it back, so it is bound on non-firmware builds
// only; the C prototype returns bool_t, which is a one-byte 0/1 here.
const LcdBufferPixelOnFn = *const fn (x: u32, y: u32) callconv(.c) u8;
const c_lcd_buffer_pixel_on = if (!dmcp_build) @extern(LcdBufferPixelOnFn, .{ .name = "lcd_buffer_pixel_on" }) else {};

// lcd.h static inlines over bitblt24: BLT_OR=0, BLT_ANDN=1, BLT_XOR=2, BLT_NONE=0.
const BLT_OR: c_int = 0;
const BLT_ANDN: c_int = 1;
const BLT_XOR: c_int = 2;
const BLT_NONE: c_int = 0;
inline fn setBlackPixel(x: u32, y: u32) void {
    bitblt24(x, 1, y, 1, BLT_OR, BLT_NONE);
}
inline fn setWhitePixel(x: u32, y: u32) void {
    bitblt24(x, 1, y, 1, BLT_ANDN, BLT_NONE);
}
inline fn flipPixel(x: u32, y: u32) void {
    bitblt24(x, 1, y, 1, BLT_XOR, BLT_NONE);
}
// non-inline callconv(.c) shims for the showGlyphCode pencil function pointer.
fn pencilBlack(x: u32, y: u32) callconv(.c) void {
    setBlackPixel(x, y);
}
fn pencilWhite(x: u32, y: u32) callconv(.c) void {
    setWhitePixel(x, y);
}

// ---------------------------------------------------------------------------
// First-party / runtime / libc externs.
// ---------------------------------------------------------------------------
extern fn getSystemFlag(sf: c_int) bool_t;
extern fn setSystemFlag(sf: c_uint) void;
extern fn clearSystemFlag(sf: c_uint) void;
extern fn getRegisterDataType(regist: calcRegister_t) u32;
extern fn getRegisterDataPointer(regist: calcRegister_t) [*c]u8;
extern fn getRegisterTag(regist: calcRegister_t) u32;
extern fn copySourceRegisterToDestRegister(source: calcRegister_t, dest: calcRegister_t) void;
extern var calcModel: u8;
extern var lastKeyItemDetermined: i16;
// addItemToBuffer pointer for comparison against indexOfItems[].func.
const addItemToBufferPtr = @extern(*const fn (u16) callconv(.c) void, .{ .name = "addItemToBuffer" });
// calcModeAimGui: no-op macro on DMCP; real GTK symbol on host sim.
const calcModeAimGuiExtern = if (!dmcp_build) @extern(*const fn () callconv(.c) void, .{ .name = "calcModeAimGui" }) else {};
inline fn calcModeAimGui() void {
    if (comptime !dmcp_build) {
        calcModeAimGuiExtern();
    }
}
const keypress_long_f: i16 = 0; // #define keypress_long_f false
extern fn fnDisplayStack(numberOfStackLines: u16) void;
extern fn linkToRealMatrixRegister(regist: calcRegister_t, matrix: *real34Matrix_t) void;
extern fn linkToComplexMatrixRegister(regist: calcRegister_t, matrix: *complex34Matrix_t) void;
extern fn real34CompareLessThan(a: *align(1) const real34_t, b: *align(1) const real34_t) bool_t;
extern fn real34CompareLessEqual(a: *align(1) const real34_t, b: *align(1) const real34_t) bool_t;
extern fn real34CompareAbsLessThan(a: *align(1) const real34_t, b: *align(1) const real34_t) bool_t;
extern fn real34IsAnInteger(x: *align(1) const real34_t) bool_t;
extern fn realIsAnInteger(r: *const real_t) bool_t;
extern fn findNamedVariable(name: [*c]const u8) calcRegister_t;
extern fn processKeyAction(item: i16) void;
extern fn fnKeyBackspace(p: u16) void;
extern fn fnInc(regist: calcRegister_t) void;
extern fn openHOMEorMyM(keypress: i16) void;
extern fn resetShiftState() void;
extern fn showShiftState() void;
extern fn nameFunction(keyOffset: i16, sf: bool_t, sg: bool_t) i16;
extern fn moreInfoOnError(m1: [*c]const u8, m2: [*c]const u8, m3: [*c]const u8, m4: [*c]const u8) void;
extern fn refresh_gui() void;
extern fn dmcpResetAutoOff() void;
extern fn checkBattery() void;
extern fn fnTimerStart(nr: u8, param: u16, time: u32) void;
// On DMCP_BUILD these are static-inline wrappers in lcd.h over lcd_forced_refresh
// (LIBRARY_FN_BASE+52, lft_ifc.h:59) / lcd_refresh_lines (+56); on host they are
// real first-party symbols.
const c__lcdRefresh = if (!dmcp_build) @extern(*const fn () callconv(.c) void, .{ .name = "_lcdRefresh" }) else {};
const c__lcdSBRefresh = if (!dmcp_build) @extern(*const fn () callconv(.c) void, .{ .name = "_lcdSBRefresh" }) else {};
const c__lcdBandRefresh = if (!dmcp_build) @extern(*const fn (y: u32, dy: u32) callconv(.c) void, .{ .name = "_lcdBandRefresh" }) else {};
inline fn _lcdRefresh() void {
    if (comptime dmcp_build) {
        const f: *const fn () callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 52); // lcd_forced_refresh
        f();
    } else {
        c__lcdRefresh();
    }
}
inline fn _lcdSBRefresh() void {
    if (comptime dmcp_build) {
        lcd_refresh_lines(0, 20);
    } else {
        c__lcdSBRefresh();
    }
}
inline fn _lcdBandRefresh(yStart: u32, height: u32) void {
    if (comptime dmcp_build) {
        lcd_refresh_lines(@bitCast(yStart), @bitCast(height));
    } else {
        c__lcdBandRefresh(yStart, height);
    }
}
extern fn keyBuffer_pop() void;
extern fn emptyKeyBuffer() bool_t;
// key_empty: DMCP ROM (LIBRARY_FN_BASE+380, lft_ifc.h:141); only called under
// dmcp_build (the battery-power skip path).
inline fn key_empty() c_int {
    const f: *const fn () callconv(.c) c_int = @ptrFromInt(LIBRARY_FN_BASE + 380);
    return f();
}

// GraphInfo box / menu layout constants (defines.h status-bar geometry).
const LeftGraphInfoX: u32 = 0;
const topLeftGraphInfoY: u32 = 20;
const widthGraphInfoBox: u32 = 158;
const heightGraphInfoBox: u32 = 151;
const topLeftMenuInclBorderY: u32 = 171;
const widthGraphInclBorder: u32 = 242;
const menuHeightInclBorder: u32 = 69;

// libc
extern fn strlen(s: [*c]const u8) usize;
extern fn strcat(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strcpy(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strchr(s: [*c]const u8, c: c_int) [*c]u8;
extern fn strstr(h: [*c]const u8, n: [*c]const u8) [*c]u8;
extern fn memcpy(d: ?*anyopaque, s: ?*const anyopaque, n: usize) ?*anyopaque;
extern fn memmove(d: ?*anyopaque, s: ?*const anyopaque, n: usize) ?*anyopaque;
extern fn pow(x: f64, y: f64) f64;
extern fn log10(x: f64) f64;

// GTK event-loop pumping (host only; referenced under !dmcp_build).
const gtk_events_pending = if (!dmcp_build) @extern(*const fn () callconv(.c) c_int, .{ .name = "gtk_events_pending" }) else {};
const gtk_main_iteration = if (!dmcp_build) @extern(*const fn () callconv(.c) c_int, .{ .name = "gtk_main_iteration" }) else {};

// stdio for fnScreenDump (host only).
const FILE = opaque {};
const time_t = c_long;
const tm = opaque {};
const c_time = @extern(*const fn (t: ?*time_t) callconv(.c) time_t, .{ .name = "time" });
extern fn localtime(t: *const time_t) *tm;
extern fn strftime(s: [*c]u8, max: usize, fmt: [*c]const u8, tmp: *const tm) usize;
extern fn fopen(name: [*c]const u8, mode: [*c]const u8) ?*FILE;
extern fn strncpy(dst: [*c]u8, src: [*c]const u8, n: usize) [*c]u8;
// Optional SNAP filename override: the graph coverage suite writes the next
// capture's path here; fnScreenDump consumes it once and clears it.
extern var _ioFileNameOverride: [1024]u8;
extern fn fwrite(ptr: ?*const anyopaque, size: usize, nmemb: usize, stream: ?*FILE) usize;
extern fn fclose(stream: ?*FILE) c_int;

// real34 = decQuad helpers (libdecnumber).
extern fn decQuadReduce(r: *align(1) real34_t, a: *align(1) const real34_t, ctx: *realContext_t) *align(1) real34_t;
extern fn decQuadToString(d: *align(1) const real34_t, str: [*c]u8) [*c]u8;
extern fn decQuadIsZero(d: *align(1) const real34_t) u32;
extern fn decimal128ToNumber(d: *const real34_t, dn: *real_t) *real_t;
extern fn decimal128FromNumber(d: *real34_t, dn: *const real_t, set: *realContext_t) *real34_t;
extern fn decNumberMultiply(res: *real_t, a: *const real_t, b: *const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberAdd(res: *real_t, a: *const real_t, b: *const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberToString(r: *const real_t, str: [*c]u8) [*c]u8;

// GMP
extern fn __gmpz_init(op: [*c]mpz_struct) void;
extern fn __gmpz_clear(op: [*c]mpz_struct) void;

// ---------------------------------------------------------------------------
// realType.h / longIntegerType.h inline wrappers.
// ---------------------------------------------------------------------------
inline fn real34Reduce(operand: *align(1) const real34_t, res: *align(1) real34_t) void {
    _ = decQuadReduce(res, operand, &ctxtReal34);
}
inline fn real34ToString(source_: *align(1) const real34_t, destination: [*c]u8) void {
    _ = decQuadToString(source_, destination);
}
inline fn real34IsZero(source_: *align(1) const real34_t) bool {
    return decQuadIsZero(source_) != 0;
}
inline fn real34IsNegative(source_: *align(1) const real34_t) bool {
    return (source_.bytes[15] & 0x80) == 0x80;
}
inline fn real34SetPositiveSign(operand: *align(1) real34_t) void {
    operand.bytes[15] &= 0x7F;
}
inline fn realToReal34(source_: *const real_t, destination: *align(1) real34_t) void {
    _ = decimal128FromNumber(@ptrCast(destination), source_, &ctxtReal34);
}
inline fn realMultiply(a: *const real_t, b: *const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberMultiply(res, a, b, ctx);
}
inline fn realAdd(a: *const real_t, b: *const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberAdd(res, a, b, ctx);
}
inline fn realToString(r: *const real_t, str: [*c]u8) void {
    _ = decNumberToString(r, str);
}
inline fn longIntegerInit(op: *longInteger_t) void {
    __gmpz_init(&op[0]);
}
inline fn longIntegerFree(op: *longInteger_t) void {
    __gmpz_clear(&op[0]);
}

inline fn stringByteLength(str: [*c]const u8) i32 {
    return @intCast(strlen(str));
}

// macro reproductions (defines.h / registers.h / realType.h / longIntegerType.h)
fn stpcpy(dst: [*c]u8, src: [*c]const u8) [*c]u8 {
    var d = dst;
    var s = src;
    while (s[0] != 0) {
        d[0] = s[0];
        d += 1;
        s += 1;
    }
    d[0] = 0;
    return d;
}
extern fn decQuadFromInt32(r: *align(1) real34_t, v: i32) *align(1) real34_t;
extern fn decQuadFromUInt32(r: *align(1) real34_t, v: u32) *align(1) real34_t;
extern fn decQuadToInt32(d: *align(1) const real34_t, ctx: *realContext_t, round: c_int) i32;
extern fn __gmpz_get_ui(op: [*c]const mpz_struct) c_ulong;
extern fn __gmpz_get_si(op: [*c]const mpz_struct) c_long;
extern fn __gmpz_cmp_ui(op: [*c]const mpz_struct, v: c_ulong) c_int;
const DEC_ROUND_DOWN: c_int = 5;

inline fn stringCopy(dest: [*c]u8, source: [*c]const u8) [*c]u8 {
    return stpcpy(dest, source);
}
inline fn getRegisterShortIntegerBase(reg: calcRegister_t) u32 {
    return getRegisterTag(reg);
}
inline fn int32ToReal34(source_: i32, destination: *align(1) real34_t) void {
    _ = decQuadFromInt32(destination, source_);
}
inline fn uInt32ToReal34(source_: u32, destination: *align(1) real34_t) void {
    _ = decQuadFromUInt32(destination, source_);
}
inline fn real34ToInt32(source_: *align(1) const real34_t) i32 {
    return decQuadToInt32(source_, &ctxtReal34, DEC_ROUND_DOWN);
}
// decNumberIsSpecial(dn) = (dn->bits & DECSPECIAL) != 0; DECSPECIAL = 0x70.
inline fn realIsSpecial(source_: *const real_t) bool_t {
    return @intFromBool((source_.bits & 0x70) != 0);
}
inline fn longIntegerToInt32(op: *longInteger_t, dst: *i32) void {
    dst.* = @intCast(__gmpz_get_si(&op[0]));
}
inline fn longIntegerToUInt32(op: *longInteger_t, dst: *u32) void {
    dst.* = @intCast(__gmpz_get_ui(&op[0]));
}
inline fn longIntegerCompareUInt(op: [*c]const mpz_struct, v: u32) i32 {
    return __gmpz_cmp_ui(op, v);
}
// isR47FAM (defines.h)
const USER_R47f_g: u8 = 61;
inline fn isR47FAM() bool {
    return calcModel == USER_R47f_g or calcModel == USER_R47bk_fg or calcModel == USER_R47fg_bk or calcModel == USER_R47fg_g;
}
inline fn isArrowUp(code: u8) bool_t {
    return @intFromBool((isR47FAM() and code == 22) or (!isR47FAM() and code == 17));
}
inline fn isArrowDown(code: u8) bool_t {
    return @intFromBool((isR47FAM() and code == 27) or (!isR47FAM() and code == 22));
}
inline fn isShift(code: u8) bool_t {
    return @intFromBool((isR47FAM() and code == 10) or (isR47FAM() and code == 11) or (!isR47FAM() and code == 27));
}
inline fn orOrtho(a: u16) u16 {
    return if (a == 0) CF_ORTHOGONAL_FITTING else a;
}
inline fn isMatrix3dVector(rows: u16, cols: u16) bool {
    return (rows == 1 and cols == 3) or (rows == 3 and cols == 1);
}
inline fn isMatrix2dVector(rows: u16, cols: u16) bool {
    return (rows == 1 and cols == 2) or (rows == 2 and cols == 1);
}
const regMatrixHeaderPtr = abi.registerMatrixHeader;
inline fn isRegisterMatrix3dVector(reg: calcRegister_t) bool_t {
    if (getRegisterDataType(reg) != dtReal34Matrix) return 0;
    const h = regMatrixHeaderPtr(reg);
    return @intFromBool(isMatrix3dVector(h.matrixRows, h.matrixColumns));
}
inline fn isRegisterMatrix2dVector(reg: calcRegister_t) bool_t {
    if (getRegisterDataType(reg) != dtReal34Matrix) return 0;
    const h = regMatrixHeaderPtr(reg);
    return @intFromBool(isMatrix2dVector(h.matrixRows, h.matrixColumns));
}
inline fn isRegisterMatrixVector(reg: calcRegister_t) bool_t {
    return @intFromBool(isRegisterMatrix3dVector(reg) != 0 or isRegisterMatrix2dVector(reg) != 0);
}
inline fn getVectorRegisterPolarMode(reg: calcRegister_t) u32 {
    if ((getRegisterDataType(reg) == dtReal34Matrix) and ((getRegisterTag(reg) & amAngleMask) != amNone)) {
        if (isRegisterMatrix3dVector(reg) != 0) {
            return if ((getRegisterTag(reg) & amPolar) == amPolar) amPolarSPH else amPolarCYL;
        } else if (isRegisterMatrix2dVector(reg) != 0) {
            return getRegisterTag(reg) & amPolar;
        } else {
            return 0;
        }
    }
    return 0;
}

// register-data accessors (REGISTER_*_DATA macros).
const REGISTER_REAL34_DATA = abi.registerReal34;
const REGISTER_COMPLEX34_DATA = abi.registerComplex34;
const SIZEOF_STR_LG_INT_HEADER: usize = 4;
const REGISTER_STRING_DATA = abi.registerString;
inline fn getRegisterAngularMode(reg: calcRegister_t) angularMode_t {
    return @intCast(getRegisterTag(reg) & amAngleMask);
}
inline fn getComplexRegisterAngularMode(reg: calcRegister_t) angularMode_t {
    return @intCast(getRegisterTag(reg) & amAngleMask);
}
inline fn getComplexRegisterPolarMode(reg: calcRegister_t) u32 {
    return getRegisterTag(reg) & amPolar;
}
// COPY_REGISTER_STRING_TO(dest, regist) = frontier_char_string.xcopy(dest, REGISTER_STRING_DATA(regist), len+1)
inline fn COPY_REGISTER_STRING_TO(dest: [*c]u8, regist: calcRegister_t) void {
    const src = REGISTER_STRING_DATA(regist);
    _ = frontier_char_string.xcopy(dest, src, @intCast(strlen(src) + 1));
}

// ---------------------------------------------------------------------------
// runtime macros over globals.
// ---------------------------------------------------------------------------
extern var significantDigits: u8;
extern var exponentLimit: i16;
extern var Input_Default: u8;
inline fn checkHP() bool {
    return significantDigits <= 16 and displayStack == 1 and exponentLimit == 99 and Input_Default == ID_DP and (calcMode == CM_NORMAL or calcMode == CM_NIM);
}
inline fn HPFONT() bool {
    return checkHP() and HPFONT1;
}
// HPFONT1 is true on host and the relevant builds; the #if guard reduces to
// HPFONT1==true everywhere HPFONT is reached on z47 targets.
const HPFONT1 = true;
inline fn checkHPoffset() i32 {
    return if (checkHP() and temporaryInformation == TI_NO_INFO) 50 else 0;
}
inline fn runningOnSimOrUSB() bool {
    if (comptime dmcp_build) {
        return getSystemFlag(FLAG_USB) != 0;
    } else {
        return true;
    }
}
inline fn GRAPHMODE() bool {
    return calcMode == CM_PLOT_STAT or calcMode == CM_GRAPH;
}
inline fn SHOWMODE() bool {
    return calcMode == CM_NORMAL and (temporaryInformation == TI_SHOW_REGISTER or temporaryInformation == TI_SHOW_REGISTER_BIG or temporaryInformation == TI_SHOW_REGISTER_SMALL or temporaryInformation == TI_SHOW_REGISTER_TINY or temporaryInformation == TI_SHOWNOTHING);
}
inline fn PROBMENU() bool {
    return showingProbMenu() != 0;
}
inline fn menuItemOfTop() i16 {
    return softmenu[@intCast(softmenuStack[0].softmenuId)].menuItem;
}
inline fn BASEMODEACTIVE() bool {
    return !PROBMENU() and (lastIntegerBase != 0 or menuItemOfTop() == -MNU_BASE or dispBase > 0);
}
inline fn XXFNMODEACTIVE() bool {
    return !SHOWMODE() and !GRAPHMODE() and menuItemOfTop() == -MNU_XXFCNS and calcMode != CM_NIM and
        ((getRegisterDataType(REGISTER_X) == dtReal34 or getRegisterDataType(REGISTER_X) == dtLongInteger) or
            (getRegisterDataType(REGISTER_T) == dtReal34 or getRegisterDataType(REGISTER_T) == dtLongInteger));
}
inline fn DBASEMODE() bool {
    return !SHOWMODE() and !GRAPHMODE() and !PROBMENU() and !XXFNMODEACTIVE() and dispBase >= 2;
}
inline fn BASEMODEREGISTERX() bool {
    return BASEMODEACTIVE() and displayStackSHOIDISP != 0 and
        ((calcMode == CM_NORMAL and getRegisterDataType(REGISTER_X) == dtShortInteger) or
            (calcMode == CM_NIM and getRegisterDataType(REGISTER_Y) == dtShortInteger) or
            (calcMode == CM_NORMAL and getRegisterDataType(REGISTER_X) == dtLongInteger));
}
inline fn isXFNregisterValid3r(r: calcRegister_t) bool {
    const ok = (getRegisterDataType(r) == dtReal34 or getRegisterDataType(r) == dtLongInteger) and
        (getRegisterDataType(r + 1) == dtReal34 or getRegisterDataType(r + 1) == dtLongInteger) and
        (getRegisterDataType(r + 2) == dtReal34 or getRegisterDataType(r + 2) == dtLongInteger);
    // !inputAngleError3r(r): !registerIsNoAngle(r+1) || !registerIsNoAngle(r+2)
    const angleErr = !registerIsNoAngle(r + 1) or !registerIsNoAngle(r + 2);
    return ok and !angleErr;
}
inline fn registerIsNoAngle(r: calcRegister_t) bool {
    return (getRegisterDataType(r) == dtReal34 and getRegisterAngularMode(r) == amNone) or getRegisterDataType(r) == dtLongInteger;
}
// X_SHIFT / Y_SHIFT
// X_SHIFT_L=0, X_SHIFT_R = X_PRINTER-1 = 361 (status-bar layout constant).
const X_SHIFT_R: i32 = 361;
inline fn X_SHIFT() i32 {
    return if (getSystemFlag(FLAG_SBshfR) != 0) X_SHIFT_R else 0;
}
inline fn Y_SHIFT() i32 {
    const sbarShift = getSystemFlag(FLAG_SBshfR) != 0;
    const sbarupdDate = getSystemFlag(FLAG_SBdate) != 0;
    const sbarupdTime = getSystemFlag(FLAG_SBtime) != 0;
    const sbarupdWoY = getSystemFlag(FLAG_SBwoy) != 0;
    // (((!Date || !(Time||WoY)) && !SBAR_SHIFT) ? 0 : (SBAR_SHIFT ? 0 : Y_SHIFT_LO))
    if ((!sbarupdDate or !(sbarupdTime or sbarupdWoY)) and !sbarShift) {
        return 0;
    }
    return if (sbarShift) 0 else Y_POSITION_OF_REGISTER_T_LINE;
}
// PRODUCT_SIGN / COMPLEX_UNIT
inline fn PRODUCT_SIGN() [*c]const u8 {
    return if (getSystemFlag(FLAG_MULTx) != 0) STD_CROSS else STD_DOT;
}
inline fn COMPLEX_UNIT() [*c]const u8 {
    return if (getSystemFlag(FLAG_CPXj) != 0) STD_op_j else STD_op_i;
}

// funcNameOffset_x / isShiftOffset / funcNameOffset_str (FIXED_FN_NAME_SHIFT def)
const shiftOffset: i32 = 17;
inline fn funcNameOffset_x() i32 {
    return shiftOffset;
}
inline fn isShiftOffset() bool {
    return funcNameOffset_x() == shiftOffset and !SHOWMODE();
}
inline fn funcNameOffset_str() [*c]const u8 {
    return if (isShiftOffset()) "  " else "";
}

// letteredRegisterName uses registerFlagLetters[regist - FIRST_LETTERED_REGISTER]
inline fn letteredRegisterName(regist: calcRegister_t) u8 {
    return registerFlagLetters[@intCast(regist - FIRST_LETTERED_REGISTER)];
}

// ===========================================================================
// Functions (source order)
// ===========================================================================

pub export fn setLastintegerBasetoZero() callconv(.c) void {
    if (lastIntegerBase != 0) {
        lastIntegerBase = 0;
        screenUpdatingMode = SCRUPD_AUTO;
        screenUpdatingMode |= SCRUPD_SKIP_STATUSBAR_ONE_TIME;
        refreshNIMdone = 0;
        refreshScreen(56);
    }
    frontier_radio_button_catalog.fnRefreshState();
}

pub export fn execTimerApp(timerType: u16) callconv(.c) void {
    _ = timerType;
    fnTimerStart(TO_TIMER_APP, TO_TIMER_APP, TIMER_APP_PERIOD);
    frontier_timer.fnUpdateTimerApp();
}

pub export fn refreshFn(timerType: u16) callconv(.c) void {
    if (timerType == TO_FG_LONG) {
        Shft_handler();
    }
    if (timerType == TO_CL_LONG) {
        LongpressKey_handler();
    }
    if (timerType == TO_FG_TIMR) {
        Shft_stop();
    }
    if (timerType == TO_FN_LONG) {
        FN_handler();
    }
    if (timerType == TO_ASM_ACTIVE) {
        if (catalog != 0) {
            frontier_bufferize.resetAlphaSelectionBuffer();
        }
    }
}

pub export fn toggle6UnderLines(y: i16) callconv(.c) void {
    if (frontier_softmenus.maxfgLines(y) != 0 or getSystemFlag(FLAG_FGLNFUL) != 0) {
        underline_softkey(0b111111, @intCast(y));
    } else {
        underline_softkey(0, 3);
    }
}

pub export fn show_f_jm() callconv(.c) void {
    if (FN_timeouts_in_progress == 0 and calcMode != CM_ASN_BROWSER) {
        toggle6UnderLines(1);
    }
}

pub export fn show_g_jm() callconv(.c) void {
    if (FN_timeouts_in_progress == 0 and calcMode != CM_ASN_BROWSER) {
        toggle6UnderLines(2);
    }
}

pub export fn clear_fg_jm() callconv(.c) void {
    if (FN_timeouts_in_progress == 0) {
        underline_softkey(0, 3);
    }
}

inline fn getLine_buffer_bit(x: i32) u16 {
    // C: `uint16_t getLine_buffer_bit(int x){ return 415-x; }` -- the signed
    // result is implicitly truncated to uint16_t (it wraps when x > 415, which
    // happens on the R47 f/g underline path). @intCast would panic; reproduce
    // the C modulo-2^16 truncation.
    return @truncate(@as(u32, @bitCast(415 - x)));
}

pub export fn underline_softkey(xSoftkeyMask_in: u16, ySoftkey: u16) callconv(.c) void {
    var xSoftkeyMask = xSoftkeyMask_in;
    if (calcMode == CM_REGISTER_BROWSER or calcMode == CM_FLAG_BROWSER or calcMode == CM_FONT_BROWSER or (getSystemFlag(FLAG_FGLNFUL) == 0 and getSystemFlag(FLAG_FGLNLIM) == 0)) {
        return;
    }
    xSoftkeyMask &= (if (GRAPHMODE()) @as(u16, 0b000011) else @as(u16, 0b111111));
    const greyType: bool_t = getSystemFlag(FLAG_FGGR);
    var maxLine: u8 = undefined;
    const lineCount: u8 = if (greyType != 0) SOFTMENU_HEIGHT - 3 else 3;
    if (yUnderlined <= 2) {
        maxLine = @intCast(239 - @as(i32, SOFTMENU_HEIGHT) * @as(i32, @intCast(yUnderlined)));
        lcd_refresh_lines(@as(c_int, maxLine) - @as(c_int, lineCount), lineCount);
    }
    yUnderlined = ySoftkey;
    if (ySoftkey > 2) {
        return;
    }
    var temp_line: [LCD_LINE_BUF_SIZE]u8 = undefined;
    var tempByte: u8 = undefined;
    var xBg: [6]u8 = undefined;
    var xIndex: u8 = undefined;
    var line: u8 = undefined;
    var j: u16 = undefined;
    var buff_bit: u16 = undefined;
    const colIncrease: u16 = if (greyType != 0) 5 else 2;
    maxLine = @intCast(238 - @as(i32, SOFTMENU_HEIGHT) * @as(i32, @intCast(ySoftkey)));
    // Get current background from corner pixels
    xIndex = 0;
    while (xIndex < 6) : (xIndex += 1) {
        buff_bit = getLine_buffer_bit(@as(i32, KEY_X[xIndex]) + 1);
        xBg[xIndex] = (lcd_buffer()[52 * (@as(usize, maxLine) + 1) + buff_bit / 8] >> @intCast(mod(buff_bit, 8))) & 1;
    }
    // Draw shade pattern without changing lcd_buffer
    line = maxLine - lineCount + 1;
    while (line <= maxLine) : (line += 1) {
        @memcpy(temp_line[0..LCD_LINE_BUF_SIZE], (lcd_buffer() + 52 * @as(usize, line))[0..LCD_LINE_BUF_SIZE]);
        xIndex = 0;
        while (xIndex < 6) : (xIndex += 1) {
            if ((xSoftkeyMask >> @intCast(xIndex)) & 1 != 0) {
                j = @intCast(KEY_X[xIndex] + 1);
                j +%= @intCast(if (greyType != 0) mod(2 * @as(i32, line) - @as(i32, j), 5) else mod(@as(i32, j) + @as(i32, line), 2));
                while (@as(i32, j) < KEY_X[xIndex + 1]) : (j +%= colIncrease) {
                    buff_bit = getLine_buffer_bit(j);
                    tempByte = temp_line[buff_bit / 8];
                    if (xBg[xIndex] != 0) {
                        tempByte = tempByte & ~(@as(u8, 1) << @intCast(mod(buff_bit, 8)));
                    } else {
                        tempByte = tempByte | (@as(u8, 1) << @intCast(mod(buff_bit, 8)));
                    }
                    temp_line[buff_bit / 8] = tempByte;
                }
            }
        }
        temp_line[0] = 0;
        LCD_write_line(&temp_line);
    }
}

pub export fn FN_handler_StepToF(time: u32) callconv(.c) void {
    shiftF = 1;
    shiftG = 0;
    showShiftState();
    if (calcMode != CM_PEM) {
        refreshRegisterLineRestoreT();
    }
    var varCatalogItem: [*c]const u8 = "SF:F";
    const Dyn = nameFunction(FN_key_pressed - 37, shiftF, shiftG);
    if (dynamicMenuItem > -1) { // !DEBUGSFN (DEBUGSFN=false)
        varCatalogItem = frontier_softmenus.dynmenuGetLabel(dynamicMenuItem);
    }
    showFunctionName(Dyn, 0, varCatalogItem);
    FN_timed_out_to_RELEASE_EXEC = 1;
    underline_softkey(@as(u16, 1) << @intCast(FN_key_pressed - 38), 1);
    fnTimerStart(TO_FN_LONG, TO_FN_LONG, time);
}

pub export fn FN_handler_StepToG(time: u32) callconv(.c) void {
    shiftF = 0;
    shiftG = 1;
    showShiftState();
    if (calcMode != CM_PEM) {
        refreshRegisterLineRestoreT();
    }
    var varCatalogItem: [*c]const u8 = "SF:G";
    const Dyn = nameFunction(FN_key_pressed - 37, shiftF, shiftG);
    if (dynamicMenuItem > -1) {
        varCatalogItem = frontier_softmenus.dynmenuGetLabel(dynamicMenuItem);
    }
    showFunctionName(Dyn, 0, varCatalogItem);
    FN_timed_out_to_RELEASE_EXEC = 1;
    underline_softkey(@as(u16, 1) << @intCast(FN_key_pressed - 38), 2);
    fnTimerStart(TO_FN_LONG, TO_FN_LONG, time);
}

pub export fn FN_handler_StepToNOP() callconv(.c) void {
    if (calcMode != CM_PEM) {
        refreshRegisterLineRestoreT();
    }
    showFunctionName(ITM_NOP, 0, "SF:N");
    FN_timed_out_to_NOP_or_Executed = 1;
    underline_softkey(@as(u16, 1) << @intCast(FN_key_pressed - 38), 3);
    FN_timeouts_in_progress = 0;
    frontier_timer.fnTimerStop(TO_FN_LONG);
}

// IS_BASEBLANK_(menuId) (defines.h:2341): menuId==0 && !FLAG_BASE_MYM && !FLAG_BASE_HOME.
// (NOT softmenu[id].menuItem==-MNU_BASE — that is the BASEMODEACTIVE idiom; an earlier
// port misread the macro, mis-gating FN_handler's longpress shift cycle.)
inline fn IS_BASEBLANK_(menuId: i16) bool {
    return menuId == 0 and getSystemFlag(FLAG_BASE_MYM) == 0 and getSystemFlag(FLAG_BASE_HOME) == 0;
}

pub export fn FN_handler() callconv(.c) void {
    if ((FN_state == ST_1_PRESS1 or FN_state == ST_3_PRESS2) and FN_timeouts_in_progress != 0 and (FN_key_pressed != 0) and !IS_BASEBLANK_(softmenuStack[0].softmenuId)) {
        if (frontier_timer.fnTimerGetStatus(TO_FN_LONG) == TMR_COMPLETED) {
            FN_handle_timed_out_to_EXEC = 0;
            if (shiftF == 0 and shiftG == 0) {
                if (LongPressF == RBX_F1234) {
                    FN_handler_StepToF(TIME_FN_1234_F_TO_G);
                } else if (LongPressF == RBX_F124) {
                    FN_handler_StepToF(TIME_FN_124_F_TO_NOP);
                } else if (LongPressF == RBX_F14) {
                    FN_handler_StepToNOP();
                }
            } else if (shiftF != 0 and shiftG == 0) {
                if (LongPressF == RBX_F1234) {
                    FN_handler_StepToG(TIME_FN_1234_G_TO_NOP);
                } else if (LongPressF == RBX_F124) {
                    FN_handler_StepToNOP();
                }
            } else if ((shiftF == 0 and shiftG != 0) or (shiftF != 0 and shiftG != 0)) {
                FN_handler_StepToNOP();
            }
        }
    }
}

// LONGPRESS_CFG: always live.
fn _assignLongPressKey(keyCode: c_int) void {
    var kc: [4]u8 = .{ 0, 0, 0, 0 };
    kc[0] = @intCast(@divTrunc(keyCode, 10) + '0');
    kc[1] = @intCast(@rem(keyCode, 10) + '0');
    kc[2] = 0;
    shiftF = 0;
    shiftG = 1;
    frontier_assign.assignToKey(&kc);
    itemToBeAssigned = 0;
    frontier_tam.leaveTamModeIfEnabled();
    keyActionProcessed = 1;
    calcMode = previousCalcMode;
    shiftF = 0;
    shiftG = 0;
}

pub export fn _executeItem(item: i16, keyCode: c_int) callconv(.c) void {
    var funcParam: [*c]const u8 = "";

    keyStateCode = @intCast((if (getSystemFlag(FLAG_ALPHA) != 0) @as(c_int, 3) else 0) + 2);
    funcParam = frontier_softmenus.getNthString(userKeyLabel, @intCast(keyCode * 6 + @as(c_int, keyStateCode)));
    if (item == ITM_RCL and getSystemFlag(FLAG_USER) != 0 and funcParam[0] != 0) {
        const variable = findNamedVariable(funcParam);
        if (variable != INVALID_VARIABLE) {
            if (calcMode == CM_PEM) {
                frontier_manage.insertUserItemInProgram(item, @constCast(funcParam));
            } else {
                frontier_items.reallyRunFunction(item, @intCast(variable));
            }
        } else {
            frontier_error.displayCalcErrorMessage(ERROR_UNDEF_SOURCE_VAR, ERR_REGISTER_LINE, REGISTER_X);
            if (comptime extra_info) {
                abi.fmtBufZ(errorMessage[0..512], "string '{s}' is not a named variable", .{std.mem.span(funcParam)});
                moreInfoOnError("In function _executeItem:", errorMessage, null, null);
            }
        }
    } else if (item == ITM_XEQ and getSystemFlag(FLAG_USER) != 0 and funcParam[0] != 0) {
        const label = frontier_manage.findNamedLabel(funcParam, frontier_manage.GLOBAL_LABELS);
        if (label != INVALID_VARIABLE) {
            if (calcMode == CM_PEM) {
                frontier_manage.insertUserItemInProgram(item, @constCast(funcParam));
            } else {
                frontier_items.reallyRunFunction(item, @intCast(label));
            }
        } else {
            frontier_error.displayCalcErrorMessage(ERROR_LABEL_NOT_FOUND, ERR_REGISTER_LINE, REGISTER_X);
            if (comptime extra_info) {
                abi.fmtBufZ(errorMessage[0..512], "string '{s}' is not a named label", .{std.mem.span(funcParam)});
                moreInfoOnError("In function _executeItem:", errorMessage, null, null);
            }
        }
    } else {
        frontier_items.runFunction(item);
    }
}

fn clearShiftTemporaryIndications(condition: bool_t) void {
    if (isShift(currentKeyCode) != 0 and (temporaryInformation != TI_NO_INFO) and condition != 0) {
        temporaryInformation = TI_NO_INFO;
        screenUpdatingMode &= ~(SCRUPD_MANUAL_STACK | SCRUPD_MANUAL_STATUSBAR);
        refreshScreen(1311);
    }
}

pub export fn Shft_handler() callconv(.c) void {
    if (Shft_LongPress_f_g != 0) {
        if (frontier_timer.fnTimerGetStatus(TO_FG_LONG) == TMR_COMPLETED) {
            Shft_LongPress_f_g = 0;
            frontier_timer.fnTimerStop(TO_3S_CTFF);
            frontier_timer.fnTimerStop(TO_FG_LONG);
            // LONGPRESS_CFG
            {
                if ((shiftF != 0 or shiftG != 0) and (calcMode != CM_EIM) and (calcMode != CM_MIM)) {
                    const keyCode: c_int = if (shiftF != 0) 10 else 11;
                    const key = &kbd_usr[@intCast(keyCode)];
                    const item: i16 = key.gShifted;
                    if ((calcMode == CM_ASSIGN) and (itemToBeAssigned != 0)) {
                        if (previousCalcMode != CM_AIM) {
                            _assignLongPressKey(keyCode);
                        }
                        shiftF = 0;
                        shiftG = 0;
                    } else if (tam.alpha or tam.mode == 0) {
                        if (calcMode == CM_NIM and item != ITM_ms and item != ITM_CC and item != ITM_op_j and item != ITM_op_j_pol and item != ITM_dotD and item != ITM_HASH_JM and item != ITM_toINT and item != ITM_BACKSPACE and indexOfItems[@intCast(item)].func != addItemToBufferPtr) {
                            delayCloseNim = 0;
                            frontier_bufferize.closeNim();
                            screenUpdatingMode &= ~SCRUPD_MANUAL_MENU;
                        }
                        // USER mode
                        if (getSystemFlag(FLAG_USER) != 0 and (calcMode != CM_AIM) and (calcMode != CM_EIM) and getSystemFlag(FLAG_ALPHA) == 0 and (item > 0)) {
                            if ((calcMode == CM_NIM or (calcMode == CM_PEM and aimBuffer[0] != 0 and getSystemFlag(FLAG_ALPHA) == 0)) and (item == ITM_HASH_JM or item == ITM_toINT)) {
                                clearShiftTemporaryIndications(@intFromBool(shiftG != 0 or shiftF != 0));
                                processKeyAction(item);
                            } else if (calcMode != CM_PEM and indexOfItems[@intCast(item)].func == addItemToBufferPtr) {
                                clearShiftTemporaryIndications(@intFromBool(shiftG != 0 or shiftF != 0));
                                frontier_bufferize.addItemToNimBuffer(item);
                            } else {
                                clearShiftTemporaryIndications(@intFromBool((item != ITM_SNAP) and (shiftG != 0 or shiftF != 0)));
                                _executeItem(item, keyCode);
                            }
                        } else { // non-USER mode
                            clearShiftTemporaryIndications(@intFromBool(shiftG != 0 or shiftF != 0));
                            var funcParam: [*c]const u8 = "";
                            keyStateCode = @intCast((if (getSystemFlag(FLAG_ALPHA) != 0) @as(c_int, 3) else 0) + 2);
                            funcParam = frontier_softmenus.getNthString(userKeyLabel, @intCast(keyCode * 6 + @as(c_int, keyStateCode)));
                            _ = frontier_softmenus.setCurrentUserMenu(item, @constCast(funcParam));
                            if (shiftF != 0) {
                                if (getSystemFlag(FLAG_ALPHA) != 0 and ((frontier_softmenus.currentMenu() == -MNU_MyAlpha) or (frontier_softmenus.currentMenu() == -MNU_AIMCATALOG) or frontier_softmenus.isAlphabeticSoftmenu() != 0)) {
                                    frontier_softmenus.popSoftmenu();
                                }
                                if (tam.alpha) {
                                    frontier_softmenus.showSoftmenu(-MNU_TAMALPHA);
                                } else if ((calcMode == CM_AIM) or getSystemFlag(FLAG_ALPHA) != 0 or ((calcMode == CM_ASSIGN) and (previousCalcMode == CM_AIM))) {
                                    frontier_softmenus.showSoftmenu(-MNU_ALPHA);
                                } else if (getSystemFlag(FLAG_USER) != 0 and (key.gShifted != ITM_NULL)) {
                                    frontier_softmenus.showSoftmenu(key.gShifted);
                                } else {
                                    frontier_softmenus.showSoftmenu(-MNU_HOME);
                                }
                                frontier_softmenus.showSoftmenuCurrentPart();
                            } else {
                                var baseOverrideOnce: bool_t = 1;
                                BASE_OVERRIDEONCE = baseOverrideOnce;
                                if ((calcMode == CM_AIM) or getSystemFlag(FLAG_ALPHA) != 0 or ((calcMode == CM_ASSIGN) and (previousCalcMode == CM_AIM)) or tam.alpha) {
                                    frontier_softmenus.showSoftmenu(-MNU_MyAlpha);
                                } else if (getSystemFlag(FLAG_USER) != 0 and (key.gShifted != ITM_NULL)) {
                                    frontier_softmenus.showSoftmenu(key.gShifted);
                                } else if (getSystemFlag(FLAG_BASE_MYM) != 0 or getSystemFlag(FLAG_BASE_HOME) != 0) {
                                    frontier_softmenus.showSoftmenu(-MNU_MyMenu);
                                } else {
                                    baseOverrideOnce = 0;
                                    BASE_OVERRIDEONCE = baseOverrideOnce;
                                    frontier_softmenus.fnExitAllMenus(0);
                                }
                                BASE_OVERRIDEONCE = baseOverrideOnce;
                                frontier_softmenus.showSoftmenuCurrentPart();
                                BASE_OVERRIDEONCE = baseOverrideOnce;
                            }
                        }
                    } else if (tam.mode != 0 and indexOfItems[@intCast(item)].func == addItemToBufferPtr) {
                        frontier_bufferize.addItemToBuffer(@intCast(item));
                    }
                    shiftF = 0;
                    shiftG = 0;
                    screenUpdatingMode = SCRUPD_AUTO;
                    refreshScreen(23);
                }
            }
            shiftF = 0;
            shiftG = 0;
            showShiftState();
            if ((calcMode == CM_AIM) or (calcMode == CM_EIM)) {
                calcModeAimGui();
            }
        }
    } else if (Shft_timeouts != 0) { // fg longpress
        clearShiftTemporaryIndications(shiftG);
        if (frontier_timer.fnTimerGetStatus(TO_FG_LONG) == TMR_COMPLETED) {
            frontier_timer.fnTimerStop(TO_3S_CTFF);
            if (shiftF == 0 and shiftG == 0) {
                shiftF = 1;
                fnTimerStart(TO_FG_LONG, TO_FG_LONG, JM_TO_FG_LONG);
                showShiftState();
            } else if (shiftF != 0 and shiftG == 0) {
                shiftG = 1;
                shiftF = 0;
                fnTimerStart(TO_FG_LONG, TO_FG_LONG, JM_TO_FG_LONG);
                showShiftState();
            } else if ((shiftF == 0 and shiftG != 0) or (shiftF != 0 and shiftG != 0)) {
                Shft_timeouts = 0;
                resetShiftState();
                if ((calcMode == CM_ASSIGN) and (itemToBeAssigned != 0)) {
                    // LONGPRESS_CFG
                    const keyCode: c_int = if (calcModel == USER_R47bk_fg) 11 else if (calcModel == USER_R47fg_bk or calcModel == USER_R47fg_g) 10 else if (calcModel == USER_C47 or calcModel == USER_DM42) 27 else 9999;
                    if (previousCalcMode != CM_AIM) {
                        _assignLongPressKey(keyCode);
                    }
                    shiftF = 0;
                    shiftG = 0;
                    screenUpdatingMode = SCRUPD_AUTO;
                    refreshScreen(23);
                } else {
                    openHOMEorMyM(keypress_long_f);
                }
            }
        }
    }
}

pub export fn LongpressKey_handler() callconv(.c) void {
    if (frontier_timer.fnTimerGetStatus(TO_CL_LONG) == TMR_COMPLETED) {
        if (JM_auto_longpress_enabled != 0) {
            var funcParam: [*c]const u8 = undefined;
            const keyStateCodeLocal: c_int = (if (getSystemFlag(FLAG_ALPHA) != 0) @as(c_int, 3) else 0) + (if (LongPressM == RBX_M124) @as(c_int, 1) else if (longpressDelayedkey3 != 0) @as(c_int, 1) else 2);
            funcParam = frontier_softmenus.getNthString(userKeyLabel, @intCast(@as(c_int, currentKeyCode) * 6 + keyStateCodeLocal));

            if (calcMode == CM_NORMAL and programRunStop == PGM_STOPPED and (isArrowUp(currentKeyCode) != 0)) {
                aimBuffer[0] = 0;
                frontier_next_step.fnSkip(0);
                refreshRegisterLine(REGISTER_T);
                if (JM_auto_longpress_enabled == ITM_NOP) {
                    FN_timeouts_in_progress = 0;
                    frontier_timer.fnTimerStop(TO_FN_LONG);
                    return;
                }
            } else if (calcMode == CM_NORMAL and programRunStop == PGM_SINGLE_STEP and (isArrowDown(currentKeyCode) != 0)) {
                programRunStop = PGM_STOPPED;
                refreshRegisterLine(REGISTER_T);
                if (JM_auto_longpress_enabled == ITM_NOP) {
                    FN_timeouts_in_progress = 0;
                    frontier_timer.fnTimerStop(TO_FN_LONG);
                    return;
                }
            } else if (calcMode == CM_NORMAL and (programRunStop == PGM_STOPPED or programRunStop == PGM_SINGLE_STEP) and currentKeyCode == 35) {
                refreshRegisterLine(REGISTER_T);
                lastKeyItemDetermined = 0;
                if (JM_auto_longpress_enabled == ITM_NOP) {
                    FN_timeouts_in_progress = 0;
                    frontier_timer.fnTimerStop(TO_FN_LONG);
                    return;
                }
            }

            if ((calcMode == CM_AIM or calcMode == CM_EIM or tam.alpha) and !((currentKeyCode == 16 or currentKeyCode == 12)) and JM_auto_longpress_enabled != ITM_CLRMOD and JM_auto_longpress_enabled > 0) {
                if (JM_auto_longpress_enabled == ITM_NOP) {
                    return;
                }
                if (isArrowUp(currentKeyCode) != 0 or isArrowDown(currentKeyCode) != 0) {
                    return;
                }
                fnKeyBackspace(NOPARAM);
                frontier_bufferize.addItemToBuffer(@intCast(JM_auto_longpress_enabled));
                FN_timeouts_in_progress = 0;
                frontier_timer.fnTimerStop(TO_FN_LONG);
                if (calcMode == CM_AIM) {
                    refreshRegisterLine(AIM_REGISTER_LINE);
                } else if (calcMode == CM_EIM or tam.alpha) {
                    screenUpdatingMode &= ~(SCRUPD_MANUAL_MENU | SCRUPD_SKIP_MENU_ONE_TIME);
                    refreshScreen(1312);
                }
                return;
            } else if ((funcParam[0] != 0) and ((JM_auto_longpress_enabled == -MNU_DYNAMIC) or (JM_auto_longpress_enabled == ITM_XEQ) or (JM_auto_longpress_enabled == ITM_RCL))) {
                showFunctionName(JM_auto_longpress_enabled, @intCast(JM_TO_CL_LONG + 50), funcParam);
            } else if (funcParam[0] == 0 and (JM_auto_longpress_enabled == ITM_XEQ or JM_auto_longpress_enabled == ITM_GTO)) {
                showFunctionName(JM_auto_longpress_enabled, @intCast(JM_TO_CL_LONG + 50), funcParam);
            } else {
                showFunctionName(JM_auto_longpress_enabled, @intCast(JM_TO_CL_LONG + 50), "SF:LL");
            }
            JM_auto_longpress_enabled = 0;

            if (longpressDelayedkey2 != 0) {
                JM_auto_longpress_enabled = longpressDelayedkey2;
                longpressDelayedkey2 = 0;
            } else if (longpressDelayedkey3 != 0) {
                JM_auto_longpress_enabled = longpressDelayedkey3;
                longpressDelayedkey3 = 0;
            } else {
                JM_auto_longpress_enabled = ITM_NOP;
            }
            if (JM_auto_longpress_enabled != 0) {
                fnTimerStart(TO_CL_LONG, TO_CL_LONG, JM_TO_CL_LONG);
            }
        }
    }
}

pub export fn Shft_stop() callconv(.c) void {
    Shft_timeouts = 0;
    resetShiftState();
}

pub export fn str2dec(ch: [*c]u8) callconv(.c) u16 {
    return @as(u16, ch[1]) + (@as(u16, ch[0]) << 8);
}

pub export fn showGlyphCode(charCode_in: u16, font_in: *const font_t, x_in: u32, y_in: u32, videoMode: videoMode_t, showLeadingCols: bool_t, showEndingCols: bool_t, noPreClear: bool_t) callconv(.c) u32 {
    var charCode = charCode_in;
    var font = font_in;
    const x = x_in;
    var y = y_in;
    var col: u32 = undefined;
    var row: u32 = undefined;
    var xGlyph: u32 = undefined;
    var endingCols: u32 = undefined;
    var glyphId: i32 = undefined;
    var byte: i8 = undefined;
    var data: [*c]const i8 = undefined;
    var glyph: ?*const glyph_t = undefined;

    if (charCode == STD_NOCHAR) {
        return x;
    }

    var enlarge: bool_t = 0;
    if (combinationFonts == stdnumEnlarge or combinationFonts == numHalf) {
        if (maxiC == 1 and font == &numericFont) {
            glyphId = frontier_fonts.findGlyph(font, charCode);
            if (glyphId < 0) {
                enlarge = 1;
                font = &standardFont;
            }
        }
    } else if (combinationFonts == 1) {
        if (maxiC == 1 and font == &standardFont) {
            enlarge = 1;
        }
    }

    // !GENERATE_CATALOGS
    if (checkHP() and font == &numericFont and HPFONT()) {
        frontier_char_string.charCodeHPReplacement(&charCode);
    }

    glyph = null;
    // FLAG_BOLD: probe the separate bold numeric font first (numeric font only).
    // A miss returns -1 so it never aliases glyph 0, and font stays == numericFont
    // so the numDouble/HP identity logic below is unaffected. (C screen.c:1164)
    if (getSystemFlag(FLAG_BOLD) != 0 and font == &numericFont) {
        const boldId = frontier_fonts.findGlyphExact(&numericFontBold, charCode);
        if (boldId >= 0) {
            glyph = &numericFontBold.glyphsPtr()[@intCast(boldId)];
        }
    }

    if (glyph == null) {
        glyphId = frontier_fonts.findGlyph(font, charCode);
        if (glyphId >= 0) {
            glyph = &font.glyphsPtr()[@intCast(glyphId)];
        } else if (glyphId == -1) {
            frontier_fonts.generateNotFoundGlyph(-1, charCode);
            glyph = glyphNotFound;
        } else if (glyphId == -2) {
            frontier_fonts.generateNotFoundGlyph(-2, charCode);
            glyph = glyphNotFound;
        } else {
            glyph = null;
        }
    }

    if (glyph == null) {
        abi.fmtBufZ(errorMessage[0..512], "In function {s}: {d} is an unexpected value returned by findGlyph!", .{ "showGlyphCode", glyphId });
        frontier_error.displayBugScreen(errorMessage);
        return 0;
    }
    const g = glyph.?;

    const yy: i32 = @bitCast(y); // negative-as-unsigned back to signed
    data = @ptrCast(g.data);
    const y0: u32 = y;
    xGlyph = if (showLeadingCols != 0) g.colsBeforeGlyph else 0;
    endingCols = if (showEndingCols != 0) g.colsAfterGlyph else 0;

    const numDouble: bool = font == &numericFont and checkHP() and temporaryInformation == TI_NO_INFO;
    // C: DOUBLING = (checkHP ? DOUBLING_A : 6). numDouble already implies checkHP(),
    // so this resolves to DOUBLING_A(15) here — matching the width owner (char_string),
    // which was using 15 while rendering used 6 (glyphs rendered at ~0.75x vs ~1.875x).
    const doubling: u16 = if (numDouble) (if (checkHP()) DOUBLING_A else 6) else DOUBLINGBASEX;

    const rep_enlarge: bool = numDouble or (enlarge != 0 and combinationFonts != 0);
    const yNewMaxDx: u32 = @intCast((if (rep_enlarge) @as(i32, 2) else 1) * ((@as(i32, @intCast(@as(u32, g.rowsAboveGlyph) + g.rowsGlyph + g.rowsBelowGlyph)) >> @intCast(miniC)) - (if (rep_enlarge) @as(i32, 4) else 0)));
    if (noShow == 0 and noPreClear == 0) {
        lcd_fill_rect(x, @intCast(maxI(0, yy)), @as(u32, @intCast(@as(i32, @intCast(@as(u32, @intCast(doubling)) * ((xGlyph + g.colsGlyph + endingCols) >> @intCast(miniC)))) >> 3)), @intCast(maxI(0, @as(i32, @intCast(yNewMaxDx)) + (if (yy < 0) yy else 0))), if (videoMode == vmNormal) LCD_SET_VALUE else LCD_EMPTY_VALUE);
    }
    if (displaymode == numHalf) {
        y +%= @bitCast(@divTrunc(@as(i32, g.rowsAboveGlyph) * REDUCT_A, REDUCT_B) * (if (rep_enlarge) @as(i32, 2) else 1));
    } else {
        y +%= @as(u32, g.rowsAboveGlyph) * (if (rep_enlarge) @as(u32, 2) else 1);
    }

    // Choose pencil
    const PencilFn = *const fn (u32, u32) callconv(.c) void;
    const setPixel: PencilFn = if (videoMode == vmNormal) &pencilBlack else &pencilWhite;
    // Drawing the glyph
    row = 0;
    while (row < g.rowsGlyph) : ({
        row += 1;
        y +%= 1;
    }) {
        if (displaymode == numHalf) {
            if (@rem(REDUCT_A * @as(i32, @intCast(row)) + REDUCT_OFF, REDUCT_B) == 0) {
                y -%= 1;
            }
        }
        col = 0;
        while (col < g.colsGlyph) : (col += 1) {
            if (col % 8 == 0) {
                byte = data[0];
                data += 1;
                if (miniC != 0) {
                    byte = @bitCast(@as(u8, @bitCast(byte)) | (@as(u8, @bitCast(byte)) << 1));
                }
            }

            if (byte & @as(i8, @bitCast(@as(u8, 0x80))) != 0 and noShow == 0) {
                const x1: u32 = x +% (((@as(u32, @intCast(doubling)) *% (xGlyph +% col)) >> @intCast(miniC)) >> 3);
                var x2: u32 = x1;
                // min(u32 yNewMaxDx, (y-y0)>>miniC) -> (int32_t) -> yy + it -> max(0,.) -> min(SCREEN_HEIGHT-1,.)
                const rowOff: u32 = (y -% y0) >> @intCast(miniC);
                const yMin1: u32 = @min(yNewMaxDx, rowOff);
                const yMin2: u32 = @min(yNewMaxDx, rowOff +% 1);
                const y1: u32 = @intCast(minI(SCREEN_HEIGHT - 1, maxI(0, yy +% @as(i32, @bitCast(yMin1)))));
                const y2: u32 = @intCast(minI(SCREEN_HEIGHT - 1, maxI(0, yy +% @as(i32, @bitCast(yMin2)))));
                if (x2 > 0) {
                    x2 -= 1;
                }
                setPixel(x1, y1);
                if (boldString == 1) {
                    setPixel(x1 +% 1, y1);
                }
                if (numDouble) {
                    setPixel(x2, y1);
                }
                if (rep_enlarge) {
                    setPixel(x1, y2);
                    if (numDouble) {
                        setPixel(x2, y2);
                    }
                }
            }

            byte = @bitCast(@as(u8, @bitCast(byte)) << 1);
        }
        if (rep_enlarge and row != 3 and row != 6 and row != 9 and row != 12) {
            y +%= 1;
        }
    }
    return x +% boldString +% (((@as(u32, @intCast(doubling)) *% (xGlyph +% g.colsGlyph +% endingCols)) >> @intCast(miniC)) >> 3);
}

pub export fn showGlyph(ch: [*c]const u8, font: *const font_t, x: u32, y: u32, videoMode: videoMode_t, showLeadingCols: bool_t, showEndingCols: bool_t, noPreClear: bool_t) callconv(.c) u32 {
    return showGlyphCode(frontier_char_string.charCodeFromString(ch, null), font, x, y, videoMode, showLeadingCols, showEndingCols, noPreClear);
}

noinline fn getGlyphBounds(ch: [*c]const u8, offset: ?*u16, font: *const font_t, col: *u32, row: *u32) void {
    const glyphId = frontier_fonts.findGlyph(font, frontier_char_string.charCodeFromString(ch, offset));
    if (glyphId < 0) {
        abi.fmtBufZ(errorMessage[0..512], "In function {s}: {d} is an unexpected value returned by findGlyph!", .{ "getGlyphBounds", glyphId });
        frontier_error.displayBugScreen(errorMessage);
        return;
    }
    const glyph = &font.glyphsPtr()[@intCast(glyphId)];
    col.* = @as(u32, glyph.colsBeforeGlyph) + glyph.colsGlyph + glyph.colsAfterGlyph;
    row.* = @as(u32, glyph.rowsAboveGlyph) + glyph.rowsGlyph + glyph.rowsBelowGlyph;
}

pub export fn getStringBounds(string: [*c]const u8, font: *const font_t, col: *u32, row: *u32) callconv(.c) void {
    getStringBoundsImpl(string, font, col, row);
}
noinline fn getStringBoundsImpl(string: [*c]const u8, font: *const font_t, col: *u32, row: *u32) void {
    var ch: u16 = 0;
    var lcol: u32 = 0;
    var lrow: u32 = 0;
    col.* = 0;
    row.* = 0;

    while (string[ch] != 0) {
        getGlyphBounds(string, &ch, font, &lcol, &lrow);
        col.* += lcol;
        if (lrow > row.*) {
            row.* = lrow;
        }
    }
}

noinline fn _doShowString(string: [*c]const u8, font: *const font_t, x_in: u32, y_in: u32, resStr: ?*[*c]u8, width: u32, videoMode: videoMode_t, showLeadingCols: bool_t, showEndingCols: bool_t, LF: bool_t) u32 {
    var x = x_in;
    var y = y_in;
    var ch: u16 = undefined;
    var slc: bool_t = undefined;
    var sec: bool_t = undefined;
    var prevX: u32 = x;
    const orgX: u32 = x;

    const lg: u16 = @intCast(stringByteLength(string));

    ch = 0;
    while (string[ch] != 0) {
        if (lg == 1 or (lg == 2 and (string[0] & 0x80) != 0)) {
            slc = showLeadingCols;
            sec = showEndingCols;
        } else if (ch == 0) {
            slc = showLeadingCols;
            sec = 1;
        } else if (ch == lg - 1 or (ch == lg - 2 and (string[ch] & 0x80) != 0)) {
            slc = 1;
            sec = showEndingCols;
        } else {
            slc = 1;
            sec = 1;
        }

        if (LF != 0 and x > SCREEN_WIDTH - 20 and noShow == 0) {
            noShow = 1;
            var tmp: u16 = ch;
            if (x +% showGlyphCode(frontier_char_string.charCodeFromString(string, &tmp), font, 0, 0, videoMode, slc, sec, 0) -% compressString > SCREEN_WIDTH) {
                x = orgX;
                prevX = x;
                y +%= if (font == &tinyFont) @as(u32, 8) else 20;
            }
            noShow = 0;
        }

        x = showGlyphCode(frontier_char_string.charCodeFromString(string, &ch), font, x, y -% raiseString, videoMode, slc, sec, 0) -% compressString;
        if (resStr) |rs| { // for stringAfterPixelsC47
            if (x > width) {
                if (showEndingCols == 0) {
                    const tmpX: u32 = x;
                    ch = @intCast(rs.* - string);
                    x = showGlyphCode(frontier_char_string.charCodeFromString(string, &ch), font, prevX, y -% raiseString, videoMode, 1, 0, 0) -% compressString;
                    if (x <= width) {
                        rs.* = @constCast(string + ch);
                    }
                    x = tmpX;
                }
                break;
            } else {
                rs.* = @constCast(string + ch);
                prevX = x;
            }
        }
        var tmp2: u16 = ch;
        while (LF != 0 and (frontier_char_string.charCodeFromString(string, &tmp2) == 0x0A)) {
            _ = frontier_char_string.charCodeFromString(string, &ch);
            x = orgX;
            prevX = x;
            y +%= if (font == &tinyFont) @as(u32, 8) else 20;
        }
    }
    compressString = 0;
    raiseString = 0;
    return x;
}

pub export fn showStringEnhanced(string: [*c]const u8, font: *const font_t, x: u32, y: u32, videoMode: videoMode_t, showLeadingCols: bool_t, showEndingCols: bool_t, compress1: u8, raise1: u8, noShow1: u8, boldString1: u8, lf: bool_t) callconv(.c) u32 {
    boldString = boldString1;
    compressString = compress1;
    raiseString = raise1;
    noShow = noShow1;
    const tmp = _doShowString(string, font, x, y, null, 0, videoMode, showLeadingCols, showEndingCols, lf);
    boldString = 0;
    compressString = 0;
    raiseString = 0;
    noShow = 0;
    return tmp;
}

pub export fn showString(string: [*c]const u8, font: *const font_t, x: u32, y: u32, videoMode: videoMode_t, showLeadingCols: bool_t, showEndingCols: bool_t) callconv(.c) u32 {
    return showStringImpl(string, font, x, y, videoMode, showLeadingCols, showEndingCols);
}
noinline fn showStringImpl(string: [*c]const u8, font: *const font_t, x: u32, y: u32, videoMode: videoMode_t, showLeadingCols: bool_t, showEndingCols: bool_t) u32 {
    return _doShowString(string, font, x, y, null, 0, videoMode, showLeadingCols, showEndingCols, NO_LF);
}

fn _stringAfterPixels(string: [*c]const u8, font: *const font_t, width: u32, showLeadingCols: bool_t, showEndingCols: bool_t) [*c]u8 {
    var resStr: [*c]u8 = @constCast(string);
    _ = _doShowString(string, font, 0, 0, &resStr, width, vmNormal, showLeadingCols, showEndingCols, NO_LF);
    return resStr;
}

fn _showStringWithLimit(string: [*c]const u8, font: *const font_t, limitWidth: u32, showLeadingCols: bool_t, showEndingCols: bool_t) u32 {
    var resStr: [*c]u8 = @constCast(string);
    return _doShowString(string, font, 0, 0, &resStr, limitWidth, vmNormal, showLeadingCols, showEndingCols, NO_LF);
}

fn _setStringMode(modeVal: c_int, comp: c_int, fontPtr: *?*const font_t) void {
    compressString = @truncate(@as(u32, @bitCast(comp)));
    displaymode = @truncate(@as(u32, @bitCast(modeVal)));
    switch (modeVal) {
        stdNoEnlarge => {
            miniC = 0;
            maxiC = 0;
            combinationFonts = combinationFontsDefault;
            fontPtr.* = &standardFont;
        },
        stdEnlarge => {
            miniC = 0;
            maxiC = 1;
            combinationFonts = @intCast(stdEnlarge);
            fontPtr.* = &standardFont;
        },
        stdnumEnlarge => {
            miniC = 0;
            maxiC = 1;
            combinationFonts = @intCast(stdnumEnlarge);
            fontPtr.* = &numericFont;
        },
        numSmall => {
            miniC = 1;
            maxiC = 0;
            combinationFonts = combinationFontsDefault;
            fontPtr.* = &numericFont;
        },
        numHalf => {
            miniC = 0;
            maxiC = 1;
            combinationFonts = @intCast(numHalf);
            fontPtr.* = &numericFont;
        },
        else => {
            fontPtr.* = null;
        },
    }
}

fn _resetStringMode() void {
    miniC = 0;
    maxiC = 0;
    compressString = 0;
    noShow = 0;
    displaymode = stdNoEnlarge;
}

pub export fn showStringC47(string: [*c]const u8, mode_in: c_int, comp: c_int, x_in: u32, y: u32, videoMode: videoMode_t, showLeadingCols: bool_t, showEndingCols: bool_t) callconv(.c) u32 {
    var mode = mode_in;
    var x = x_in;
    const combinationFontsM: c_int = combinationFonts;
    if (combinationFontsDefault == 0) {
        mode = stdNoEnlarge;
    }

    var font: ?*const font_t = undefined;
    _setStringMode(mode, comp, &font);
    if (font) |f| {
        x = showString(string, f, x, y, videoMode, showLeadingCols, showEndingCols);
    } else {
        x = 0;
    }

    combinationFonts = @intCast(combinationFontsM);
    _resetStringMode();
    return x;
}

pub export fn stringAfterPixelsC47(string: [*c]const u8, mode_in: c_int, comp: c_int, width: u32, withLeadingEmptyRows: bool_t, withEndingEmptyRows: bool_t) callconv(.c) [*c]u8 {
    var mode = mode_in;
    const combinationFontsM: c_int = combinationFonts;
    var resStr: [*c]u8 = @constCast(string);
    if (combinationFontsDefault == 0) {
        mode = stdNoEnlarge;
    }

    var font: ?*const font_t = undefined;
    noShow = 1;
    _setStringMode(mode, comp, &font);
    if (font) |f| {
        resStr = _stringAfterPixels(string, f, width, withLeadingEmptyRows, withEndingEmptyRows);
    } else {
        resStr = @constCast(string);
    }

    combinationFonts = @intCast(combinationFontsM);
    _resetStringMode();
    return resStr;
}

pub export fn stringWidthWithLimitC47(string: [*c]const u8, mode_in: c_int, comp: c_int, limitWidth: u32, withLeadingEmptyRows: bool_t, withEndingEmptyRows: bool_t) callconv(.c) u32 {
    var mode = mode_in;
    const combinationFontsM: c_int = combinationFonts;
    var x: u32 = 0;
    if (combinationFontsDefault == 0) {
        mode = stdNoEnlarge;
    }

    var font: ?*const font_t = undefined;
    noShow = 1;
    _setStringMode(mode, comp, &font);
    if (font) |f| {
        x = _showStringWithLimit(string, f, limitWidth, withLeadingEmptyRows, withEndingEmptyRows);
    } else {
        x = 0;
    }

    combinationFonts = @intCast(combinationFontsM);
    _resetStringMode();
    return x;
}

pub export fn stringWidthC47(str: [*c]const u8, mode: c_int, comp: c_int, withLeadingEmptyRows: bool_t, withEndingEmptyRows: bool_t) callconv(.c) u32 {
    noShow = 1;
    return showStringC47(str, mode, comp, 0, 0, vmNormal, withLeadingEmptyRows, withEndingEmptyRows);
}

pub export fn drawSinglePixelFullWidthLine(y: c_int) callconv(.c) void {
    lcd_fill_rect(0, @intCast(y), SCREEN_WIDTH, 1, LCD_EMPTY_VALUE);
}

pub export fn showBottomLine() callconv(.c) void {
    var yoff: i32 = 0;
    if (!((temporaryInformation == TI_SHOW_REGISTER_SMALL and tmpString[5 * @as(usize, @intCast(SHOWLineSize))] != 0) or
        (temporaryInformation == TI_SHOW_REGISTER_TINY and tmpString[14 * @as(usize, @intCast(SHOWLineSize))] != 0)) or (overrideShowBottomLine > 0))
    {
        if (overrideShowBottomLine > 0) {
            yoff = @intFromFloat(@as(f32, SCREEN_HEIGHT) - @as(f32, REGISTER_LINE_HEIGHT) * @as(f32, @floatFromInt(overrideShowBottomLine)) / 10.0);
        } else {
            yoff = SCREEN_HEIGHT - REGISTER_LINE_HEIGHT * 2;
        }

        const offs: i32 = if (temporaryInformation == TI_SHOW_REGISTER_BIG) -2 else 0;

        drawSinglePixelFullWidthLine(yoff + offs);

        overrideShowBottomLine = 0;
    }
}

const line_small: i32 = 21;
const line_tiny: i32 = 10;

pub export fn showDispSmall(offset: u16, _h1: u8) callconv(.c) void {
    const line_hMultiLineEdOffset: u32 = @intCast(Y_POSITION_OF_REGISTER_T_LINE);
    if (tmpString[offset] != 0) {
        const w = frontier_char_string.stringWidth(tmpString + offset, if (temporaryInformation == TI_SHOW_REGISTER_SMALL) &standardFont else &tinyFont, true, true);
        _ = showString(tmpString + offset, if (temporaryInformation == TI_SHOW_REGISTER_SMALL) &standardFont else &tinyFont, @intCast(@as(i32, SCREEN_WIDTH) - w), @intCast(@as(i32, @intCast(line_hMultiLineEdOffset)) + (if (temporaryInformation == TI_SHOW_REGISTER_SMALL) line_small else line_tiny) * @as(i32, _h1)), vmNormal, 1, 1);
    }
}

const line_h1: i32 = 37;

pub export fn showDisp(offset: u16, _h1: u8) callconv(.c) void {
    const line_hMultiLineEdOffset: i32 = Y_POSITION_OF_REGISTER_T_LINE - 3;

    var w = stringWidthWithLimitC47(tmpString + offset, stdnumEnlarge, nocompress, SCREEN_WIDTH, 1, 1);
    if (w < SCREEN_WIDTH) {
        _ = showStringC47(tmpString + offset, stdnumEnlarge, nocompress, @as(u32, SCREEN_WIDTH) - w, @intCast(line_hMultiLineEdOffset + line_h1 * @as(i32, _h1)), vmNormal, 1, 1);
        return;
    }
    w = stringWidthWithLimitC47(tmpString + offset, stdEnlarge, nocompress, SCREEN_WIDTH, 1, 1);
    if (w < SCREEN_WIDTH) {
        _ = showStringC47(tmpString + offset, stdEnlarge, nocompress, @as(u32, SCREEN_WIDTH) - w, @intCast(line_hMultiLineEdOffset + line_h1 * @as(i32, _h1)), vmNormal, 1, 1);
        return;
    }
    w = stringWidthWithLimitC47(tmpString + offset, stdNoEnlarge, nocompress, SCREEN_WIDTH, 1, 1);
    if (w < SCREEN_WIDTH) {
        _ = showStringC47(tmpString + offset, stdNoEnlarge, nocompress, @as(u32, SCREEN_WIDTH) - w, @intCast(line_hMultiLineEdOffset + line_h1 * @as(i32, _h1)), vmNormal, 1, 1);
        return;
    }
    w = stringWidthWithLimitC47(tmpString + offset, numSmall, nocompress, SCREEN_WIDTH, 1, 1);
    if (w < SCREEN_WIDTH) {
        _ = showStringC47(tmpString + offset, numSmall, nocompress, @as(u32, SCREEN_WIDTH) - w, @intCast(line_hMultiLineEdOffset + line_h1 * @as(i32, _h1)), vmNormal, 1, 1);
        return;
    }
    w = stringWidthWithLimitC47(tmpString + offset, numSmall, DO_compress, SCREEN_WIDTH, 1, 1);
    if (w < SCREEN_WIDTH) {
        _ = showStringC47(tmpString + offset, numSmall, DO_compress, @as(u32, SCREEN_WIDTH) - w, @intCast(line_hMultiLineEdOffset + line_h1 * @as(i32, _h1)), vmNormal, 1, 1);
        return;
    }
    const w2 = frontier_char_string.stringWidth(tmpString + offset + 2, &standardFont, true, true);
    if (w2 < SCREEN_WIDTH) {
        _ = showString(tmpString + offset + 2, &standardFont, @intCast(@as(i32, SCREEN_WIDTH) - w2), @intCast(line_hMultiLineEdOffset + line_h1 * @as(i32, _h1)), vmNormal, 1, 1);
        return;
    }
}

// TEXT_MULTILINE_EDIT is ON for all targets.
pub export fn showStringEdC47(lastline_in: u32, offset: i16, edcursor: i16, string: [*c]const u8, x_in: u32, y_in: u32, videoMode: videoMode_t, showLeadingCols: bool_t, showEndingCols: bool_t, noshow1: bool_t) callconv(.c) u32 {
    var lastline = lastline_in;
    var x = x_in;
    var y = y_in;
    var ch: u16 = undefined;
    var charCode: u16 = undefined;
    var glyphId: i16 = undefined;
    var slc: bool_t = undefined;
    var sec: bool_t = undefined;
    var numPixels: u32 = undefined;
    var tmpxy: u32 = undefined;
    var glyph: ?*const glyph_t = undefined;
    var yincr: u8 = undefined;
    var font: *const font_t = undefined;

    if (combinationFonts == 2) {
        font = &numericFont;
    } else {
        font = &standardFont;
    }

    const lg: u16 = @intCast(stringByteLength(string + @as(usize, @intCast(offset))));

    yincr = 35;
    xMultiLineEdOffset = 0;
    if (frontier_char_string.stringWidth(string + @as(usize, @intCast(offset)), &numericFont, showLeadingCols != 0, showEndingCols != 0) > SCREEN_WIDTH - 50) {
        multiEdLines = 3;
        yMultiLineEdOffset = 1;
        screenUpdatingMode &= ~SCRUPD_MANUAL_STACK;
        last_CM = calcMode;
    } else {
        multiEdLines = 2;
        yMultiLineEdOffset = 3;
        screenUpdatingMode &= ~SCRUPD_MANUAL_STACK;
        last_CM = calcMode;
    }

    if (checkHP()) {
        multiEdLines = 1;
        yMultiLineEdOffset = 1;
        screenUpdatingMode &= ~SCRUPD_MANUAL_STACK;
        last_CM = calcMode;
        yincr = 1;
    }

    const orglastlines: u32 = lastline;

    if (lastline > yMultiLineEdOffset) {
        x = xMultiLineEdOffset;
        y = @intCast((@as(i32, yincr) - 1) + @as(i32, yMultiLineEdOffset) * (@as(i32, yincr) - 1));
    }

    ch = @intCast(offset);
    while (string[ch] != 0) {
        if (lg == 1 or (lg == 2 and (string[@as(usize, @intCast(offset))] & 0x80) != 0)) {
            slc = showLeadingCols;
            sec = showEndingCols;
        } else if (ch == 0) {
            slc = showLeadingCols;
            sec = 1;
        } else if (ch == lg - 1 or (ch == lg - 2 and (string[ch] & 0x80) != 0)) {
            slc = 1;
            sec = showEndingCols;
        } else {
            slc = 1;
            sec = 1;
        }

        if (ch == edcursor) {
            current_cursor_x = @truncate(x);
            current_cursor_y = @truncate(y);
            tmpxy = y -% 1;
            while (tmpxy < y + (@as(u32, yincr) + 1)) {
                if (noshow1 == 0) {
                    setBlackPixel(x, tmpxy);
                }
                if (noshow1 == 0) {
                    setBlackPixel(x + 1, tmpxy);
                }
                tmpxy += 1;
            }
            x += 2;
        }

        charCode = string[ch];
        ch += 1;
        if (charCode & 0x80 != 0) {
            charCode = (charCode << 8) | string[ch];
            ch += 1;
        }
        glyph = null;
        glyphId = frontier_fonts.findGlyph(font, charCode);
        if (glyphId >= 0) {
            glyph = &font.glyphsPtr()[@intCast(glyphId)];
        } else if (glyphId == -1) {
            frontier_fonts.generateNotFoundGlyph(-1, charCode);
            glyph = glyphNotFound;
        } else if (glyphId == -2) {
            frontier_fonts.generateNotFoundGlyph(-2, charCode);
            glyph = glyphNotFound;
        } else {
            glyph = null;
        }

        const g = glyph.?;
        numPixels = 0;
        numPixels += @as(u32, g.colsGlyph) + g.colsAfterGlyph + g.colsBeforeGlyph;
        if (string[ch] == 0) {
            numPixels += 8;
        }
        const ALLOW_PIXELS_FOR_CURSOR: u32 = 12;
        if (x + numPixels > SCREEN_WIDTH - 1 - ALLOW_PIXELS_FOR_CURSOR and lastline == orglastlines) {
            x = xMultiLineEdOffset;
            y += yincr;
            lastline -= 1;
        } else if (x + numPixels > SCREEN_WIDTH - 1 - ALLOW_PIXELS_FOR_CURSOR and lastline > 1) {
            x = 1;
            y += yincr;
            lastline -= 1;
        } else if (x + numPixels > SCREEN_WIDTH - 1 - ALLOW_PIXELS_FOR_CURSOR and lastline <= 1) {
            xCursor = x;
            yCursor = y;
            return x;
        }

        maxiC = 1;
        if (y != @as(u32, @bitCast(@as(i32, -100)))) {
            x = showGlyphCode(charCode, font, x, y -% raiseString, videoMode, slc, sec, 0) -% compressString;
        }
        maxiC = 0;
    }

    xCursor = x;
    yCursor = y;
    compressString = 0;
    raiseString = 0;
    return xCursor;
}

pub export fn findOffset() callconv(.c) void {
    var strWidth: i32 = @intCast(stringWidthC47(aimBuffer, combinationFonts, nocompress, 1, 1));
    strWidth -= @as(i32, SCREEN_WIDTH) * @as(i32, multiEdLines) - 45;
    if (strWidth < 0) {
        strWidth = 0;
    }
    const offset = stringAfterPixelsC47(aimBuffer, combinationFonts, nocompress, @intCast(strWidth), 1, 1);
    displayAIMbufferoffset = @intCast(offset - aimBuffer);
    incOffset();
}

pub export fn incOffset() callconv(.c) void {
    if (@as(i32, @intCast(stringWidthC47(aimBuffer + @as(usize, @intCast(displayAIMbufferoffset)), combinationFonts, nocompress, 1, 1))) -
        @as(i32, @intCast(stringWidthC47(aimBuffer + @as(usize, @intCast(T_cursorPos)), combinationFonts, nocompress, 1, 1))) >
        @as(i32, SCREEN_WIDTH) * @as(i32, multiEdLines) - 45)
    {
        displayAIMbufferoffset = frontier_char_string.stringNextGlyph(aimBuffer, displayAIMbufferoffset);
    }
}

const blockForcedRefreshes = false;

fn _force_refresh(modeArg: u8) bool_t {
    var now: u16 = 0;
    var itIsTime: bool_t = 0;
    if (modeArg != force or blockForcedRefreshes) {
        now = @truncate(frontier_timer.getUptimeMs() >> 4);
        itIsTime = @intFromBool(((now >> 6) & 0x0001) == @as(u16, @intFromBool(secTick1 != 0)));
        if (itIsTime != 0) {
            secTick1 = @intFromBool(secTick1 == 0);
        }
    }

    if (((modeArg == force and !blockForcedRefreshes) or itIsTime != 0) and getSystemFlag(FLAG_MONIT) != 0) {
        return 1;
    }
    return 0;
}

pub export fn force_refresh(modeArg: u8) callconv(.c) void {
    if (_force_refresh(modeArg) != 0) {
        _lcdRefresh();
    }
}

pub export fn force_SBrefresh(modeArg: u8) callconv(.c) void {
    if (_force_refresh(modeArg) != 0) {
        _lcdSBRefresh();
    }
}

fn force_Registerrefresh(regist: calcRegister_t, clearTop: bool, clearBottom: bool) void {
    if (REGISTER_X <= regist and regist <= REGISTER_T) {
        var yStart: u32 = @intCast(@as(i32, Y_POSITION_OF_REGISTER_X_LINE) - @as(i32, REGISTER_LINE_HEIGHT) * @as(i32, regist - REGISTER_X));
        var height: u32 = 32;

        if (clearTop) {
            yStart -%= 4;
            height += 4;
        }
        if (clearBottom) {
            height += 4;
            if (regist == REGISTER_X) {
                height += 3;
            }
        }
        _lcdBandRefresh(yStart, height);
    }
}

fn _printHalfSecUpdate_Integer(modeArg: u8, txt: [*c]u8, loop: i32, clearZ: bool_t, clearT: bool_t, disp: bool_t) bool_t {
    var tmps: [100]u8 = undefined;
    var ret_value: bool_t = 0;

    if ((modeArg != timed and !blockForcedRefreshes) or (((@as(u16, @truncate(frontier_timer.getUptimeMs())) >> 10) & 0x0001) == @as(u16, @intFromBool(halfSecTick3 != 0)))) {
        halfSecTick3 = @intFromBool(halfSecTick3 == 0);
        ret_value = 1;
        if (comptime dmcp_build) {
            dmcpResetAutoOff();
        }

        if (clearT != 0 and blockMonitoring == 0) {
            clearRegisterLine(REGISTER_T, true, true);
        }
        if (clearZ != 0 and blockMonitoring == 0 and modeArg > force) {
            clearRegisterLine(REGISTER_Z, true, true);
        }

        fnTimerStart(TO_KB_ACTV, TO_KB_ACTV, TO_KB_ACTV_MEDIUM);
        if (disp != 0 and blockMonitoring == 0) {
            abi.fmtBufZ(&tmps, "{s} {d}  ", .{ std.mem.span(txt), loop });
            _ = showString(&tmps, &standardFont, 20, @intCast(@as(i32, Y_POSITION_OF_REGISTER_T_LINE) + @as(i32, modeArg) * 20), vmNormal, 0, 0);
        }

        _lcdRefresh();
    }
    return ret_value;
}

pub export fn progressHalfSecUpdate_Integer(modeArg: u8, txt: [*c]u8, loop: i32, clearZ: bool_t, clearT: bool_t, disp: bool_t) callconv(.c) bool_t {
    if (getSystemFlag(FLAG_MONIT) == 0) {
        return 0;
    }
    return _printHalfSecUpdate_Integer(modeArg, txt, loop, clearZ, clearT, disp);
}

pub export fn checkHalfSec() callconv(.c) bool_t {
    if (comptime !dmcp_build) {
        while (gtk_events_pending() != 0) {
            _ = gtk_main_iteration();
        }
    }
    if (getSystemFlag(FLAG_MONIT) == 0) {
        return 0;
    }
    if (((@as(u16, @truncate(frontier_timer.getUptimeMs())) >> 10) & 0x0001) == @as(u16, @intFromBool(halfSecTick2 != 0))) {
        halfSecTick2 = @intFromBool(halfSecTick2 == 0);
        if (comptime dmcp_build) {
            dmcpResetAutoOff();
        }
        return 1;
    }
    return 0;
}

// halfSec_* monitoring defaults are #define ... true macros in defines.h.
const halfSec_clearZ: bool_t = 1;
const halfSec_clearT: bool_t = 1;
const halfSec_disp: bool_t = 1;

pub export fn monitorExit(loop: *i32, str: [*c]u8) callconv(.c) bool_t {
    loop.* += 1;
    if (checkHalfSec() != 0) {
        if (progressHalfSecUpdate_Integer(timed, str, loop.*, halfSec_clearZ, halfSec_clearT, halfSec_disp) != 0) {}
    }
    if (frontier_addons.exitKeyWaiting() != 0) {
        _ = progressHalfSecUpdate_Integer(force + 1, @constCast("Interrupted: "), loop.*, halfSec_clearZ, halfSec_clearT, halfSec_disp);
        return 1;
    }
    return 0;
}

pub export fn hideCursor() callconv(.c) void {
    if (cursorEnabled != 0) {
        if (cursorFont == &standardFont) {
            lcd_fill_rect(xCursor, yCursor + 10, 6, 6, LCD_SET_VALUE);
        } else {
            if (checkHP()) {
                var ccol: u32 = undefined;
                var crow: u32 = undefined;
                getGlyphBounds(STD_CURSOR, null, cursorFont.?, &ccol, &crow);
                lcd_fill_rect(xCursor, @intCast(@as(i32, @bitCast(yCursor)) - checkHPoffset()), ccol, crow, LCD_SET_VALUE);
            } else {
                lcd_fill_rect(xCursor, yCursor + 15, 13, 13, LCD_SET_VALUE);
            }
        }
    }
}

fn stats_param_display(name: [*c]const u8, reg: calcRegister_t, prefix: [*c]u8, tmpStringArg: [*c]u8, rowReg: calcRegister_t) void {
    var prefixWidth: i16 = undefined;
    var regS: [16]u8 = undefined;
    var p: [*c]const u8 = undefined;
    var t: real_t = undefined;
    var u: real34_t = undefined;
    var angleMode: u32 = undefined;

    if (name == null or !(rowReg == REGISTER_Y or rowReg == REGISTER_Z or rowReg == REGISTER_T)) {
        return;
    }
    clearRegisterLine(rowReg, true, true);

    if (reg == RESERVED_VARIABLE_UEST) {
        abi.fmtCStr(prefix, "Upper =", .{});
        _ = strcpy(&regS, name);
    } else if (reg == RESERVED_VARIABLE_LEST) {
        abi.fmtCStr(prefix, "Lower =", .{});
        _ = strcpy(&regS, name);
    } else {
        _ = strcpy(&regS, "Reg_");
        regS[3] = letteredRegisterName(reg);
        abi.fmtCStr(prefix, "= {s} =", .{@as([*:0]const u8, name)});
    }
    _ = showString(&regS, &standardFont, 19, @intCast(@as(i32, Y_POSITION_OF_REGISTER_X_LINE) - @as(i32, REGISTER_LINE_HEIGHT) * @as(i32, rowReg - REGISTER_X) + 6), vmNormal, 1, 1);
    prefixWidth = @intCast(showString(prefix, &standardFont, 19 + (17 + 28), @intCast(@as(i32, Y_POSITION_OF_REGISTER_X_LINE) - @as(i32, REGISTER_LINE_HEIGHT) * @as(i32, rowReg - REGISTER_X) + 6), vmNormal, 1, 1));

    if (frontier_register_value_conversions.getRegisterAsRealQuiet(reg, &t)) {
        angleMode = if (getRegisterDataType(reg) == dtReal34) @intCast(getRegisterAngularMode(reg)) else amNone;
        realToReal34(&t, &u);
        frontier_display.real34ToDisplayString(&u, angleMode, tmpStringArg, &numericFont, @intCast(@as(i32, SCREEN_WIDTH) - prefixWidth), NUMBER_OF_DISPLAY_DIGITS, LIMITEXP, FRONTSPACE, NOIRFRAC);
        p = tmpStringArg;
    } else {
        p = "invalid";
    }

    _ = showString(p, &numericFont, @intCast(@as(i32, SCREEN_WIDTH) - frontier_char_string.stringWidth(p, &numericFont, false, true)), @intCast(@as(i32, Y_POSITION_OF_REGISTER_X_LINE) - @as(i32, REGISTER_LINE_HEIGHT) * @as(i32, rowReg - REGISTER_X)), vmNormal, 0, 1);
}

const PRIORITY_itemCatalogName: bool_t = 1;
const PRIORITY_itemSoftmenuName: bool_t = 0;
pub export fn pickValidItemFromItems(item: i16, priority: bool_t) callconv(.c) [*c]const u8 {
    var takeCat: bool_t = 0;
    const idx: usize = @intCast(absI(item));
    if (priority == PRIORITY_itemCatalogName) {
        if (indexOfItems[idx].itemCatalogName[0] != 0) {
            takeCat = 1;
        }
    } else {
        if (indexOfItems[idx].itemSoftmenuName[0] == 0) {
            takeCat = 1;
        }
    }
    if (takeCat != 0) {
        return &indexOfItems[idx].itemCatalogName;
    } else {
        return &indexOfItems[idx].itemSoftmenuName;
    }
}

pub export fn showingProbMenu() callconv(.c) bool_t {
    const cur: c_int = -softmenu[@intCast(softmenuStack[0].softmenuId)].menuItem;
    return @intFromBool((cur >= PROBMENUSTART1 and cur <= PROBMENUEND1) or
        (cur >= PROBMENUSTART2 and cur <= PROBMENUEND2));
}

// DEBUG_SHOWNAME undef -> the #else branch of showFunctionName.
pub export fn showFunctionName(itm: i16, delayInMs: i16, arg: [*c]const u8) callconv(.c) void {
    const item: i16 = itm;
    var functionName: [64]u8 = undefined;
    var padding: [25]u8 = undefined;
    functionName[0] = 0;
    showFunctionNameArg = null;

    if ((item == ITM_XEQ) or (item == ITM_RCL)) {
        if (arg != null) {
            _ = stringCopy(&functionName, arg);
        }
        showFunctionNameArg = @constCast(arg);
        if (functionName[0] == 0) {
            _ = stringCopy(&functionName, &indexOfItems[@intCast(absI(item))].itemCatalogName);
        }
    } else if (item == -MNU_DYNAMIC) {
        if (arg != null) {
            _ = stringCopy(&functionName, arg);
        }
        showFunctionNameArg = @constCast(arg);
    } else if (item >= FIRST_CONSTANT and item <= LAST_CONSTANT) {
        _ = stringCopy(&functionName, pickValidItemFromItems(item, PRIORITY_itemSoftmenuName));
    } else if (frontier_conversion_units.isItemConversion(item)) {
        frontier_conversion_units.executionConversionPartner(item, null, &functionName);
        frontier_char_string.expandAbbreviations(&functionName);
    } else if (item < LAST_ITEM and item != MNU_DYNAMIC) {
        _ = stringCopy(&functionName, pickValidItemFromItems(item, PRIORITY_itemCatalogName));
    } else if (dynamicMenuItem > -1) {
        _ = stringCopy(&functionName, frontier_softmenus.dynmenuGetLabel(dynamicMenuItem));
    }

    showFunctionNameItem = item;
    showFunctionNameCounter = delayInMs;

    if (tam.alpha and ((item == ITM_BACKSPACE) or (item == ITM_T_LEFT_ARROW) or (item == ITM_T_RIGHT_ARROW))) {
        return;
    }

    if (functionName[0] != 0) {
        const overLapPossible: bool = (calcMode == CM_PEM);
        padding[0] = 0;
        if (overLapPossible) {
            _ = stringCopy(&padding, " ");
        }
        const typWidth: i32 = 120;
        _ = stringCopy(padding[@intCast(stringByteLength(&padding))..].ptr, &functionName);
        _ = stringCopy(padding[@intCast(stringByteLength(&padding))..].ptr, "       ");
        if (calcMode == CM_ASSIGN or ((PROBMENU() or XXFNMODEACTIVE() or @as(i32, frontier_char_string.stringWidth(&padding, &standardFont, true, true)) + 1 + @as(i32, lineTWidth) > SCREEN_WIDTH) and calcMode != CM_PEM)) {
            clearRegisterLine(REGISTER_T, true, false);
        }
        clearShiftState();
        const xx = showString(&padding, &standardFont, @intCast(funcNameOffset_x()), @intCast(@as(i32, Y_POSITION_OF_REGISTER_T_LINE) + 6), vmNormal, 1, 1);
        if (overLapPossible) {
            frontier_plotstat.plotrect(@intCast(funcNameOffset_x()), Y_POSITION_OF_REGISTER_T_LINE + 6, @intCast(maxI(@as(i32, @intCast(xx)), funcNameOffset_x() + typWidth)), Y_POSITION_OF_REGISTER_T_LINE + 6 + STANDARD_FONT_HEIGHT - 1);
            if (@as(i32, @intCast(xx)) < funcNameOffset_x() + typWidth) {
                lcd_fill_rect(xx, Y_POSITION_OF_REGISTER_T_LINE + 6 + 1, @intCast(funcNameOffset_x() + typWidth - @as(i32, @intCast(xx))), STANDARD_FONT_HEIGHT - 2, LCD_SET_VALUE);
            }
        }
    }
    if (temporaryInformation != TI_NO_INFO) {
        temporaryInformation = TI_NO_INFO;
        lastErrorCode = 0;
        screenUpdatingMode &= ~SCRUPD_MANUAL_STACK;
    }
}

pub export fn hideFunctionName() callconv(.c) void {
    if (tmpString[0] != 0 or calcMode != CM_AIM) {
        if (calcMode != CM_PEM) {
            if (!tam.alpha or (showFunctionNameItem != ITM_BACKSPACE and
                showFunctionNameItem != ITM_T_LEFT_ARROW and
                showFunctionNameItem != ITM_T_RIGHT_ARROW and
                showFunctionNameItem != ITM_NULL))
            {
                refreshRegisterLineRestoreT();
                force_Registerrefresh(REGISTER_T, true, true);
            }
        } else {
            _refreshPemScreen();
        }
    }
    showFunctionNameItem = 0;
    showFunctionNameCounter = 0;
}

pub export fn clearRect(g_line_x: u32, g_line_y: u32) callconv(.c) void {
    var fcol: u32 = undefined;
    var frow: u32 = undefined;
    getGlyphBounds(" ", null, &standardFont, &fcol, &frow);
    lcd_fill_rect(g_line_x, g_line_y, @as(u32, SCREEN_WIDTH) - g_line_x - 1, frow, LCD_SET_VALUE);
}

pub export fn clearRegisterLine(regist: calcRegister_t, clearTop: bool, clearBottom: bool) callconv(.c) void {
    if (REGISTER_X <= regist and regist <= REGISTER_T) {
        var yStart: u32 = @intCast(@as(i32, Y_POSITION_OF_REGISTER_X_LINE) - @as(i32, REGISTER_LINE_HEIGHT) * @as(i32, regist - REGISTER_X));
        var height: u32 = 32;

        if (clearTop) {
            yStart -%= 4;
            height += 4;
        }
        if (clearBottom) {
            height += 4;
            if (regist == REGISTER_X) {
                height += 3;
            }
        }
        lcd_fill_rect(0, yStart, SCREEN_WIDTH, height, LCD_SET_VALUE);
    }
}

fn do_viewRegName(regist: calcRegister_t, prefix: [*c]u8, prefixWidth: *i16, endChar: [*c]const u8) void {
    if (frontier_items.lastFuncNo() == ITM_AVIEW or frontier_items.lastFuncNo() == ITM_PROMPT) {
        if (isShiftOffset()) {
            _ = strcpy(prefix, "  ");
            prefixWidth.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        } else {
            prefix[0] = 0;
            prefixWidth.* = 1;
        }
        return;
    }

    if (regist < REGISTER_X) {
        abi.fmtCStr(prefix, "{s}R{d:0>2}" ++ STD_SPACE_4_PER_EM ++ "{s}" ++ STD_SPACE_4_PER_EM, .{ @as([*:0]const u8, funcNameOffset_str()), @as(c_uint, @intCast(regist)), @as([*:0]const u8, endChar) });
    } else if (regist <= LAST_SPARE_REGISTER) {
        abi.fmtCStr(prefix, "{s}{c}" ++ STD_SPACE_4_PER_EM ++ "{s}" ++ STD_SPACE_4_PER_EM, .{ @as([*:0]const u8, funcNameOffset_str()), @as(u8, @intCast(@as(c_int, letteredRegisterName(regist)))), @as([*:0]const u8, endChar) });
    } else if (regist >= FIRST_LOCAL_REGISTER and regist <= LAST_LOCAL_REGISTER) {
        abi.fmtCStr(prefix, "{s}R.{d:0>2}" ++ STD_SPACE_4_PER_EM ++ "{s}" ++ STD_SPACE_4_PER_EM, .{ @as([*:0]const u8, funcNameOffset_str()), @as(c_uint, @intCast(regist - FIRST_LOCAL_REGISTER)), @as([*:0]const u8, endChar) });
    } else if (FIRST_NAMED_VARIABLE <= regist and regist <= LAST_NAMED_VARIABLE) {
        if (isShiftOffset()) {
            _ = strcpy(prefix, "  ");
        }
        const off1: usize = if (isShiftOffset()) 2 else 0;
        _ = strcpy(prefix + off1, STD_LEFT_SINGLE_QUOTE);
        const nv = &allNamedVariables[@intCast(regist - FIRST_NAMED_VARIABLE)];
        const off2: usize = if (isShiftOffset()) 4 else 2;
        _ = memcpy(prefix + off2, &nv.variableName[1], nv.variableName[0]);
        abi.fmtCStr(prefix + off2 + nv.variableName[0], STD_RIGHT_SINGLE_QUOTE ++ STD_SPACE_4_PER_EM ++ "{s}" ++ STD_SPACE_4_PER_EM, .{@as([*:0]const u8, endChar)});
    } else if (FIRST_RESERVED_VARIABLE <= regist and regist <= LAST_RESERVED_VARIABLE) {
        if (isShiftOffset()) {
            _ = strcpy(prefix, "  ");
        }
        const off1: usize = if (isShiftOffset()) 2 else 0;
        _ = strcpy(prefix + off1, STD_LEFT_SINGLE_QUOTE);
        const rv = &allReservedVariables[@intCast(regist - FIRST_RESERVED_VARIABLE)];
        const off2: usize = if (isShiftOffset()) 4 else 2;
        _ = memcpy(prefix + off2, &rv.reservedVariableName[1], rv.reservedVariableName[0]);
        abi.fmtCStr(prefix + off2 + rv.reservedVariableName[0], STD_RIGHT_SINGLE_QUOTE ++ STD_SPACE_4_PER_EM ++ "{s}" ++ STD_SPACE_4_PER_EM, .{@as([*:0]const u8, endChar)});
    } else {
        abi.fmtCStr(prefix, "?" ++ STD_SPACE_4_PER_EM ++ "{s}" ++ STD_SPACE_4_PER_EM, .{@as([*:0]const u8, endChar)});
    }
    prefixWidth.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
}

fn viewRegName(prefix: [*c]u8, prefixWidth: *i16) void {
    do_viewRegName(@intCast(currentViewRegister), prefix, prefixWidth, "=");
}

pub export fn viewRegName2(prefix: [*c]u8, prefixWidth: *i16) callconv(.c) void {
    do_viewRegName(@intCast(showRegis), prefix, prefixWidth, ":");
}

fn nameRegis(regist: calcRegister_t, prefix: [*c]u8) void {
    var prefixWidth: i16 = undefined;
    do_viewRegName(regist, prefix, &prefixWidth, "");
}

fn viewStoRcl(prefix: [*c]u8, prefixWidth: *i16) void {
    do_viewRegName(frontier_items.lastSTORCL(), prefix, prefixWidth, ":");
    if (prefix[0] == '?') {
        prefix[0] = 0;
        // upstream `prefixWidth = 0` reassigns the LOCAL pointer (dead store), not
        // *prefixWidth -- reproduced faithfully as a no-op.
    }
}

pub export fn createSubstrings(number: u8) callconv(.c) void {
    if (!(frontier_items.lastFuncNo() == ITM_AVIEW or frontier_items.lastFuncNo() == ITM_PROMPT)) {
        return;
    }
    var nn: u16 = 0;
    var counter: u16 = 0;
    const mm: u16 = @intCast(stringByteLength(tmpString));
    while (nn <= mm) {
        if (tmpString[nn] == STD_CR[0] and tmpString[nn + 1] == STD_CR[1]) {
            tmpString[nn] = 32;
            nn += 1;
            tmpString[nn] = 0;
            counter += 1;
            if (counter == number) {
                break;
            }
        } else if (tmpString[nn] & 0x80 != 0) {
            nn += 1;
        }
        nn += 1;
    }
    tmpString[nn] = 0;
    while (counter < number and number <= 4) {
        nn += 1;
        tmpString[nn] = 0;
        counter += 1;
    }
}

fn userTI(viewRegister: i16, refreshRegist: i16, prefix: [*c]u8, prefixWidth: *i16) void {
    if (!(frontier_items.lastFuncNo() == ITM_AVIEW or frontier_items.lastFuncNo() == ITM_PROMPT)) {
        return;
    }
    if (temporaryInformation == TI_VIEW_REGISTER and getRegisterDataType(viewRegister) == dtString) {
        COPY_REGISTER_STRING_TO(tmpString, viewRegister);
        createSubstrings(4);
        if (refreshRegist == REGISTER_T) {
            const string1: [*c]u8 = frontier_softmenus.getNthString(tmpString, 0);
            const off1: usize = if (isShiftOffset()) 2 else 0;
            _ = frontier_char_string.xcopy(tmpString + off1, string1, @intCast(stringByteLength(string1) + 1));
            if (isShiftOffset()) {
                tmpString[0] = 32;
                tmpString[1] = 32;
            }
        } else if (refreshRegist == REGISTER_X) {
            const string1: [*c]u8 = frontier_softmenus.getNthString(tmpString, 1);
            _ = frontier_char_string.xcopy(prefix, string1, @intCast(stringByteLength(string1) + 1));
            prefixWidth.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        } else if (refreshRegist == REGISTER_Y) {
            const string1: [*c]u8 = frontier_softmenus.getNthString(tmpString, 2);
            _ = frontier_char_string.xcopy(prefix, string1, @intCast(stringByteLength(string1) + 1));
            prefixWidth.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        } else if (refreshRegist == REGISTER_Z) {
            const string1: [*c]u8 = frontier_softmenus.getNthString(tmpString, 3);
            _ = frontier_char_string.xcopy(prefix, string1, @intCast(stringByteLength(string1) + 1));
            prefixWidth.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    }
}

fn elecTI(regist: i16, prefix: [*c]u8, prefixWidth: *i16) void {
    if (temporaryInformation == TI_ABC) {
        if (regist == REGISTER_X) {
            _ = strcpy(prefix, "c" ++ STD_SPACE_FIGURE ++ ":");
            prefixWidth.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        } else if (regist == REGISTER_Y) {
            _ = strcpy(prefix, "b" ++ STD_SPACE_FIGURE ++ ":");
            prefixWidth.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        } else if (regist == REGISTER_Z) {
            _ = strcpy(prefix, "a" ++ STD_SPACE_FIGURE ++ ":");
            prefixWidth.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_ABBCCA) {
        if (regist == REGISTER_X) {
            _ = strcpy(prefix, "bc" ++ STD_SPACE_FIGURE ++ ":");
            prefixWidth.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        } else if (regist == REGISTER_Y) {
            _ = strcpy(prefix, "ab" ++ STD_SPACE_FIGURE ++ ":");
            prefixWidth.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        } else if (regist == REGISTER_Z) {
            _ = strcpy(prefix, "ca" ++ STD_SPACE_FIGURE ++ ":");
            prefixWidth.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_012) {
        if (regist == REGISTER_X) {
            _ = strcpy(prefix, "sym2" ++ STD_SPACE_FIGURE ++ ":");
            prefixWidth.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        } else if (regist == REGISTER_Y) {
            _ = strcpy(prefix, "sym1" ++ STD_SPACE_FIGURE ++ ":");
            prefixWidth.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        } else if (regist == REGISTER_Z) {
            _ = strcpy(prefix, "sym0" ++ STD_SPACE_FIGURE ++ ":");
            prefixWidth.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    }
}

fn inputRegName(prefix: [*c]u8, prefixWidth: *i16) void {
    const civ: u16 = currentInputVariable & 0x3fff;
    if (civ < REGISTER_X) {
        abi.fmtCStr(prefix, " R{d:0>2}?", .{@as(c_uint, civ)});
    } else if (civ <= LAST_SPARE_REGISTER) {
        abi.fmtCStr(prefix, " {c}?", .{@as(u8, @intCast(@as(c_int, letteredRegisterName(@intCast(civ)))))});
    } else if ((civ >= FIRST_LOCAL_REGISTER) and civ <= LAST_LOCAL_REGISTER) {
        abi.fmtCStr(prefix, " R.{d:0>2}?", .{@as(c_uint, civ - FIRST_LOCAL_REGISTER)});
    } else if (FIRST_NAMED_VARIABLE <= civ and civ <= LAST_NAMED_VARIABLE) {
        const nv = &allNamedVariables[@intCast(civ - FIRST_NAMED_VARIABLE)];
        _ = memcpy(prefix, &nv.variableName[1], nv.variableName[0]);
        _ = strcpy(prefix + nv.variableName[0], "?");
    } else if (FIRST_RESERVED_VARIABLE <= civ and civ <= LAST_RESERVED_VARIABLE) {
        const rv = &allReservedVariables[@intCast(civ - FIRST_RESERVED_VARIABLE)];
        _ = memcpy(prefix, &rv.reservedVariableName[1], rv.reservedVariableName[0]);
        _ = strcpy(prefix + rv.reservedVariableName[0], "?");
    } else {
        abi.fmtCStr(prefix, "??", .{});
    }
    prefixWidth.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
}

fn _fnShowRecallTI(prefix: [*c]u8, prefixWidth: *i16) void {
    abi.fmtCStr(prefix, "SHOW RCL", .{});
    viewRegName2(prefix + "SHOW RCL".len, prefixWidth);
    prefixWidth.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
    temporaryInformation = TI_NO_INFO;
    screenUpdatingMode |= SCRUPD_SKIP_STACK_ONE_TIME;
}

pub export fn updateMatrixHeightCache() callconv(.c) void {
    var prefixWidth: i16 = 0;
    var prefix: [200]u8 = undefined;

    cachedDisplayStack = 4;

    if (getRegisterDataType(REGISTER_X) == dtReal34Matrix or (calcMode == CM_MIM and getRegisterDataType(@intCast(matrixIndex)) == dtReal34Matrix)) {
        var matrix: real34Matrix_t = undefined;

        if (temporaryInformation == TI_VIEW_REGISTER) {
            viewRegName(&prefix, &prefixWidth);
        }
        if (temporaryInformation == TI_NO_INFO and currentInputVariable != INVALID_VARIABLE) {
            inputRegName(&prefix, &prefixWidth);
        }
        if (calcMode == CM_MIM) {
            matrix = openMatrixMIMPointer.realMatrix;
        } else {
            linkToRealMatrixRegister(REGISTER_X, &matrix);
        }
        const rows: u16 = matrix.header.matrixRows;
        const cols: u16 = matrix.header.matrixColumns;
        var smallFont: bool_t = @intFromBool(rows >= 5);
        var dummyVal: [MATRIX_MAX_COLUMNS * (MATRIX_MAX_ROWS + 1) + 1]i16 = std.mem.zeroes([MATRIX_MAX_COLUMNS * (MATRIX_MAX_ROWS + 1) + 1]i16);

        var allElementsInColAreIntegers: [MATRIX_MAX_COLUMNS]bool_t = std.mem.zeroes([MATRIX_MAX_COLUMNS]bool_t);
        {
            var j: usize = 0;
            while (j < @min(cols, MATRIX_MAX_COLUMNS)) : (j += 1) {
                allElementsInColAreIntegers[j] = 1;
                var i: usize = 0;
                while (i < rows) : (i += 1) {
                    if (real34IsAnInteger(&matrix.matrixElements.?[i * cols + j]) == 0) {
                        allElementsInColAreIntegers[j] = 0;
                        break;
                    }
                }
            }
        }

        const mtxWidth = frontier_matrix_editor.getRealMatrixColumnWidths(&matrix, prefixWidth, &numericFont, &dummyVal, dummyVal[MATRIX_MAX_COLUMNS..].ptr, &dummyVal[(MATRIX_MAX_ROWS + 1) * MATRIX_MAX_COLUMNS], if (cols > MATRIX_MAX_COLUMNS) MATRIX_MAX_COLUMNS else cols, @ptrCast(&allElementsInColAreIntegers));
        if (absI(mtxWidth) > MATRIX_LINE_WIDTH) {
            smallFont = 1;
        }
        if (rows == 2 and cols > 1 and smallFont == 0) {
            cachedDisplayStack = 3;
        }
        if (rows == 3 and cols > 1) {
            cachedDisplayStack = if (smallFont != 0) 3 else 2;
        }
        if (rows == 4 and cols > 1) {
            cachedDisplayStack = if (smallFont != 0) 2 else 1;
        }
        if (rows >= 5 and cols > 1) {
            cachedDisplayStack = 2;
        }
        if (calcMode == CM_MIM) {
            cachedDisplayStack -%= 2;
        }
        if (cachedDisplayStack > 4) {
            cachedDisplayStack = 0;
        }
    } else if (getRegisterDataType(REGISTER_X) == dtComplex34Matrix or (calcMode == CM_MIM and getRegisterDataType(@intCast(matrixIndex)) == dtComplex34Matrix)) {
        var matrix: complex34Matrix_t = undefined;
        if (temporaryInformation == TI_VIEW_REGISTER) {
            viewRegName(&prefix, &prefixWidth);
        }
        if (temporaryInformation == TI_NO_INFO and currentInputVariable != INVALID_VARIABLE) {
            inputRegName(&prefix, &prefixWidth);
        }
        if (calcMode == CM_MIM) {
            matrix = openMatrixMIMPointer.complexMatrix;
        } else {
            linkToComplexMatrixRegister(REGISTER_X, &matrix);
        }
        const rows: u16 = matrix.header.matrixRows;
        const cols: u16 = matrix.header.matrixColumns;
        var smallFont: bool_t = @intFromBool(rows >= 5);
        var dummyVal: [MATRIX_MAX_COLUMNS * (MATRIX_MAX_ROWS * 2 + 3) + 1]i16 = std.mem.zeroes([MATRIX_MAX_COLUMNS * (MATRIX_MAX_ROWS * 2 + 3) + 1]i16);
        const mtxWidth = frontier_matrix_editor.getComplexMatrixColumnWidths(&matrix, prefixWidth, &numericFont, &dummyVal, dummyVal[MATRIX_MAX_COLUMNS..].ptr, dummyVal[MATRIX_MAX_COLUMNS * 2 ..].ptr, dummyVal[MATRIX_MAX_COLUMNS * 3 ..].ptr, dummyVal[MATRIX_MAX_COLUMNS * (MATRIX_MAX_ROWS + 3) ..].ptr, &dummyVal[MATRIX_MAX_COLUMNS * (MATRIX_MAX_ROWS * 2 + 3)], if (cols > MATRIX_MAX_COLUMNS) MATRIX_MAX_COLUMNS else cols, getComplexRegisterAngularMode(REGISTER_X), (getComplexRegisterPolarMode(REGISTER_X) == amPolar));
        if (mtxWidth > MATRIX_LINE_WIDTH) {
            smallFont = 1;
        }
        if (rows == 2 and cols > 1 and smallFont == 0) {
            cachedDisplayStack = 3;
        }
        if (rows == 3 and cols > 1) {
            cachedDisplayStack = if (smallFont != 0) 3 else 2;
        }
        if (rows == 4 and cols > 1) {
            cachedDisplayStack = if (smallFont != 0) 2 else 1;
        }
        if (rows >= 5 and cols > 1) {
            cachedDisplayStack = 2;
        }
        if (calcMode == CM_MIM) {
            cachedDisplayStack -%= 2;
        }
        if (cachedDisplayStack > 4) {
            cachedDisplayStack = 0;
        }
    }

    if (calcMode == CM_MIM and matrixIndex == REGISTER_X) {
        cachedDisplayStack += 1;
    }
}

pub export fn displayTemporaryInformationOnX(prefix: [*c]u8) callconv(.c) void {
    var w: i16 = undefined;
    var prefixWidth: i16 = undefined;
    var savedTempInformation: u8 = undefined;

    prefixWidth = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
    savedTempInformation = temporaryInformation;
    temporaryInformation = TI_NO_INFO;
    refreshRegisterLine(REGISTER_T);
    refreshRegisterLine(REGISTER_Z);
    refreshRegisterLine(REGISTER_Y);
    refreshRegisterLine(REGISTER_X);
    temporaryInformation = savedTempInformation;

    if (getRegisterDataType(REGISTER_X) == dtReal34) {
        clearRegisterLine(REGISTER_X, true, true);
        if (getSystemFlag(FLAG_FRACT) != 0) {
            frontier_display.fractionToDisplayString(REGISTER_X, tmpString);
        } else {
            frontier_display.real34ToDisplayString(REGISTER_REAL34_DATA(REGISTER_X), @intCast(getRegisterAngularMode(REGISTER_X)), tmpString, &numericFont, @intCast(@as(i32, SCREEN_WIDTH) - prefixWidth), NUMBER_OF_DISPLAY_DIGITS, LIMITEXP, FRONTSPACE, LIMITIRFRAC);
        }
        w = frontier_char_string.stringWidth(tmpString, &numericFont, false, true);
        _ = showString(prefix, &standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE + 6, vmNormal, 1, 1);
        _ = showString(tmpString, &numericFont, @intCast(@as(i32, SCREEN_WIDTH) - w), Y_POSITION_OF_REGISTER_X_LINE, vmNormal, 0, 1);
    } else if (getRegisterDataType(REGISTER_X) == dtComplex34) {
        clearRegisterLine(REGISTER_X, true, true);
        frontier_display.complex34ToDisplayString(REGISTER_COMPLEX34_DATA(REGISTER_X), tmpString, &numericFont, @intCast(@as(i32, SCREEN_WIDTH) - prefixWidth), NUMBER_OF_DISPLAY_DIGITS, LIMITEXP, FRONTSPACE, LIMITIRFRAC, @intCast(getComplexRegisterAngularMode(REGISTER_X)), @intFromBool(getComplexRegisterPolarMode(REGISTER_X) == amPolar));
        w = frontier_char_string.stringWidth(tmpString, &numericFont, false, true);
        _ = showString(prefix, &standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE + 6, vmNormal, 1, 1);
        _ = showString(tmpString, &numericFont, @intCast(@as(i32, SCREEN_WIDTH) - w), Y_POSITION_OF_REGISTER_X_LINE, vmNormal, 0, 1);
    } else if (getRegisterDataType(REGISTER_X) == dtLongInteger) {
        clearRegisterLine(REGISTER_X, true, true);
        frontier_display.longIntegerRegisterToDisplayString(REGISTER_X, tmpString, TMP_STR_LENGTH, @intCast(@as(i32, SCREEN_WIDTH) - prefixWidth), 50, 1);
        w = frontier_char_string.stringWidth(tmpString, &numericFont, false, true);
        _ = showString(prefix, &standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE + 6, vmNormal, 1, 1);
        if (w <= SCREEN_WIDTH - prefixWidth) {
            _ = showString(tmpString, &numericFont, @intCast(@as(i32, SCREEN_WIDTH) - w), Y_POSITION_OF_REGISTER_X_LINE, vmNormal, 0, 1);
        } else {
            w = frontier_char_string.stringWidth(tmpString, &standardFont, false, true);
            if (w > SCREEN_WIDTH - prefixWidth) {
                _ = strcpy(tmpString, "Long integer representation too wide!");
            }
            w = frontier_char_string.stringWidth(tmpString, &standardFont, false, true);
            _ = showString(tmpString, &standardFont, @intCast(@as(i32, SCREEN_WIDTH) - w), Y_POSITION_OF_REGISTER_X_LINE + 6, vmNormal, 0, 1);
        }
    } else {
        _ = showString(prefix, &standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE + 6, vmNormal, 1, 1);
    }
}

pub export fn _displayIJ(regist: calcRegister_t, prefix: [*c]u8, prefixWidth: *i16) callconv(.c) void {
    if (lastErrorCode != 0) {
        return;
    }
    var iir: real_t = undefined;
    var jjr: real_t = undefined;

    var iii: i32 = undefined;
    var jji: i32 = undefined;
    var bb: bool_t = undefined;
    iii = lastI;
    jji = lastJ;
    if (iii == 0xFFFF or jji == 0xFFFF) {
        bb = @intFromBool(frontier_register_value_conversions.getRegisterAsRealQuiet(REGISTER_I, &iir) and frontier_register_value_conversions.getRegisterAsRealQuiet(REGISTER_J, &jjr));
        iii = @bitCast(frontier_real_type.realToUint32C47(&iir, null));
        jji = @bitCast(frontier_real_type.realToUint32C47(&jjr, null));
    } else {
        bb = 1;
    }

    if (bb != 0) {
        if (0 <= iii and iii < 200 and 0 <= jji and jji < 200) {
            prefix[0] = 0;
            prefixWidth.* = 0;
            var tmp: [16]u8 = undefined;
            nameRegis(@intCast(matrixIndex), &tmp);
            if (regist == REGISTER_X and temporaryInformation == TI_MIJEQ) {
                abi.fmtCStr(prefix, STD_MU ++ "[I" ++ STD_SUB_r ++ STD_SPACE_4_PER_EM ++ "J" ++ STD_SUB_c ++ "]={s}[{d}" ++ STD_SPACE_3_PER_EM ++ "{d}]{s}", .{ std.mem.sliceTo(&tmp, 0), @as(c_uint, @intCast(@as(u8, @truncate(@as(u32, @bitCast(iii)))))), @as(c_uint, @intCast(@as(u8, @truncate(@as(u32, @bitCast(jji)))))), @as([*:0]const u8, if (temporaryInformation == TI_MIJEQ) @as([*c]const u8, "=") else @as([*c]const u8, "")) });
            } else if (regist == REGISTER_X and temporaryInformation == TI_MIJ) {
                abi.fmtCStr(prefix, STD_MU ++ "[I" ++ STD_SUB_r ++ STD_SPACE_4_PER_EM ++ "J" ++ STD_SUB_c ++ "]={s}[{d}" ++ STD_SPACE_3_PER_EM ++ "{d}]", .{ std.mem.sliceTo(&tmp, 0), @as(c_uint, @intCast(@as(u8, @truncate(@as(u32, @bitCast(iii)))))), @as(c_uint, @intCast(@as(u8, @truncate(@as(u32, @bitCast(jji)))))) });
            } else if (regist == REGISTER_X and ((iii != 0 and temporaryInformation == TI_I) or (jji != 0 and temporaryInformation == TI_J))) {
                abi.fmtCStr(prefix, "{s}[I" ++ STD_SUB_r ++ "={d}" ++ STD_SPACE_4_PER_EM ++ "J" ++ STD_SUB_c ++ "={d}]{s}", .{ std.mem.sliceTo(&tmp, 0), @as(c_uint, @intCast(@as(u8, @truncate(@as(u32, @bitCast(iii)))))), @as(c_uint, @intCast(@as(u8, @truncate(@as(u32, @bitCast(jji)))))), @as([*:0]const u8, if (temporaryInformation == TI_I) @as([*c]const u8, ": I" ++ STD_SUB_r ++ "=") else @as([*c]const u8, ": J" ++ STD_SUB_c ++ "=")) });
            } else if (iii != 0 and jji != 0) {
                if (regist == REGISTER_Y) {
                    abi.fmtCStr(prefix, STD_MU ++ STD_SPACE_4_PER_EM ++ "{s}:I" ++ STD_SUB_r ++ "=", .{std.mem.sliceTo(&tmp, 0)});
                } else if (regist == REGISTER_X) {
                    abi.fmtCStr(prefix, STD_MU ++ STD_SPACE_4_PER_EM ++ "{s}:J" ++ STD_SUB_c ++ "=", .{std.mem.sliceTo(&tmp, 0)});
                }
            }
            prefixWidth.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    }
}

// OPTION_VECTOR vector-component TI (gated).
const compact: bool_t = 1;
inline fn e0() [*c]const u8 {
    return if (getSystemFlag(FLAG_3DXYZ) != 0) "x" else "i";
}
inline fn e1() [*c]const u8 {
    return if (getSystemFlag(FLAG_3DXYZ) != 0) "y" else "j";
}
inline fn e2() [*c]const u8 {
    return if (getSystemFlag(FLAG_3DXYZ) != 0) "z" else "k";
}
inline fn _e0() [*c]const u8 {
    return if (getSystemFlag(FLAG_3DXYZ) != 0) STD_SUB_x else STD_SUB_i;
}
inline fn _e1() [*c]const u8 {
    return if (getSystemFlag(FLAG_3DXYZ) != 0) STD_SUB_y else STD_SUB_j;
}
inline fn _e2() [*c]const u8 {
    return if (getSystemFlag(FLAG_3DXYZ) != 0) STD_SUB_z else STD_SUB_k;
}
const interspace = STD_SPACE_HAIR;

pub export fn tiVector(regist: calcRegister_t, prefix: [*c]u8, prefixWidth: *i16, shrt: bool_t) callconv(.c) void {
    if (comptime !option_vector) return;
    prefix[0] = 0;
    prefixWidth.* = 0;
    if (temporaryInformation == TI_VECTORCOMP_3DSPH and getRegisterDataType(regist) == dtReal34 and regist >= REGISTER_X and regist <= REGISTER_Z) {
        if (getSystemFlag(FLAG_3DPHYS) != 0) {
            switch (regist) {
                REGISTER_Z => abi.fmtCStr(prefix, "[{s}  ] =", .{STD_rho}),
                REGISTER_Y => abi.fmtCStr(prefix, "[ {s}{s} ] =", .{ STD_phi_m, @as([*:0]const u8, _e2()) }),
                REGISTER_X => abi.fmtCStr(prefix, "[  {s}{s}{s}] =", .{ STD_theta_m, @as([*:0]const u8, _e0()), @as([*:0]const u8, _e1()) }),
                else => {},
            }
        } else {
            switch (regist) {
                REGISTER_Z => abi.fmtCStr(prefix, "[{s}  ] =", .{STD_rho}),
                REGISTER_Y => abi.fmtCStr(prefix, "[ {s}{s}{s} ] =", .{ STD_theta_m, @as([*:0]const u8, _e0()), @as([*:0]const u8, _e1()) }),
                REGISTER_X => abi.fmtCStr(prefix, "[  {s}{s}] =", .{ STD_phi_m, @as([*:0]const u8, _e2()) }),
                else => {},
            }
        }
    } else if (temporaryInformation == TI_VECTORCOMP_3DCYL and getRegisterDataType(regist) == dtReal34 and regist >= REGISTER_X and regist <= REGISTER_Z) {
        switch (regist) {
            REGISTER_Z => abi.fmtCStr(prefix, "[r  ] =", .{}),
            REGISTER_Y => abi.fmtCStr(prefix, "[ {s}{s}{s} ] =", .{ STD_theta_m, @as([*:0]const u8, _e0()), @as([*:0]const u8, _e1()) }),
            REGISTER_X => abi.fmtCStr(prefix, "[  {s}] =", .{@as([*:0]const u8, e2())}),
            else => {},
        }
    } else if (temporaryInformation == TI_VECTORCOMP_3DRECT and getRegisterDataType(regist) == dtReal34 and regist >= REGISTER_X and regist <= REGISTER_Z) {
        switch (regist) {
            REGISTER_Z => abi.fmtCStr(prefix, "[{s}  ] =", .{@as([*:0]const u8, e0())}),
            REGISTER_Y => abi.fmtCStr(prefix, "[ {s} ] =", .{@as([*:0]const u8, e1())}),
            REGISTER_X => abi.fmtCStr(prefix, "[  {s}] =", .{@as([*:0]const u8, e2())}),
            else => {},
        }
    } else if (temporaryInformation == TI_VECTORCOMP_2DPOLAR and getRegisterDataType(regist) == dtReal34 and regist >= REGISTER_X and regist <= REGISTER_Y) {
        switch (regist) {
            REGISTER_Y => abi.fmtCStr(prefix, "[r ] =", .{}),
            REGISTER_X => abi.fmtCStr(prefix, "[ {s}{s}{s}] =", .{ STD_theta_m, @as([*:0]const u8, _e0()), @as([*:0]const u8, _e1()) }),
            else => {},
        }
    } else if (temporaryInformation == TI_VECTORCOMP_2DRECT and getRegisterDataType(regist) == dtReal34 and regist >= REGISTER_X and regist <= REGISTER_Y) {
        switch (regist) {
            REGISTER_Y => abi.fmtCStr(prefix, "[{s} ] =", .{@as([*:0]const u8, e0())}),
            REGISTER_X => abi.fmtCStr(prefix, "[ {s}] =", .{@as([*:0]const u8, e1())}),
            else => {},
        }
    } else if (isRegisterMatrix3dVector(regist) != 0) {
        if (getVectorRegisterPolarMode(regist) == amPolarSPH) {
            if (getSystemFlag(FLAG_3DPHYS) != 0) {
                if (shrt != 0) {
                    abi.fmtCStr(prefix, "{s}{s}{s}", .{ STD_rho, STD_phi_m, STD_theta_m });
                } else {
                    abi.fmtCStr(prefix, "[{s}{s}{s}{s}{s}{s}{s}{s}]" ++ STD_SUB_P, .{ STD_rho, interspace, STD_phi_m, @as([*:0]const u8, _e2()), interspace, STD_theta_m, @as([*:0]const u8, _e0()), @as([*:0]const u8, _e1()) });
                }
            } else {
                if (shrt != 0) {
                    abi.fmtCStr(prefix, "{s}{s}{s}", .{ STD_rho, STD_theta_m, STD_phi_m });
                } else {
                    abi.fmtCStr(prefix, "[{s}{s}{s}{s}{s}{s}{s}{s}]" ++ STD_SUB_M, .{ STD_rho, interspace, STD_theta_m, @as([*:0]const u8, _e0()), @as([*:0]const u8, _e1()), interspace, STD_phi_m, @as([*:0]const u8, _e2()) });
                }
            }
        } else if (getVectorRegisterPolarMode(regist) == amPolarCYL) {
            if (shrt != 0) {
                abi.fmtCStr(prefix, "{s}{s}{s}", .{ "r", STD_theta_m, @as([*:0]const u8, e2()) });
            } else {
                abi.fmtCStr(prefix, "[{s}{s}{s}{s}{s}{s}{s}]", .{ "r", interspace, STD_theta_m, @as([*:0]const u8, _e0()), @as([*:0]const u8, _e1()), interspace, @as([*:0]const u8, e2()) });
            }
        } else {
            if (shrt != 0) {
                abi.fmtCStr(prefix, "{s}{s}{s}", .{ @as([*:0]const u8, e0()), @as([*:0]const u8, e1()), @as([*:0]const u8, e2()) });
            } else {
                abi.fmtCStr(prefix, "[{s}{s}{s}{s}{s}]", .{ @as([*:0]const u8, e0()), interspace, @as([*:0]const u8, e1()), interspace, @as([*:0]const u8, e2()) });
            }
        }
    } else if (isRegisterMatrix2dVector(regist) != 0) {
        if (getVectorRegisterPolarMode(regist) != amPolar) {
            if (shrt != 0) {
                abi.fmtCStr(prefix, "{s}{s}", .{ @as([*:0]const u8, e0()), @as([*:0]const u8, e1()) });
            } else {
                abi.fmtCStr(prefix, "[{s}{s}{s}]", .{ @as([*:0]const u8, e0()), interspace, @as([*:0]const u8, e1()) });
            }
        } else {
            if (shrt != 0) {
                abi.fmtCStr(prefix, "{s}{s}", .{ "r", STD_theta_m });
            } else {
                abi.fmtCStr(prefix, "[{s}{s}{s}{s}{s}]", .{ "r", interspace, STD_theta_m, @as([*:0]const u8, _e0()), @as([*:0]const u8, _e1()) });
            }
        }
    } else {
        return;
    }

    prefixWidth.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
}

fn __displaySolver(regist: calcRegister_t, prefix: [*c]u8, prefixWidth: *i16, no: i16) void {
    _ = regist;
    var noo: [32]u8 = undefined;
    var t: real_t = undefined;
    // C `uint16_t variableNo = currentSolverVariable - FIRST_RESERVED_VARIABLE;`
    // wraps mod 2^16 when currentSolverVariable < FIRST_RESERVED_VARIABLE (the
    // value is only used under the `>=` guard below). Zig `-` would panic on the
    // underflow; reproduce the C truncation.
    const variableNo: u16 = @truncate(@as(u32, @bitCast(@as(i32, currentSolverVariable) - @as(i32, FIRST_RESERVED_VARIABLE))));
    switch (no) {
        2 => {
            _ = strcpy(&noo, STD_SUB_p ++ STD_SUB_r ++ STD_SUB_e ++ STD_SUB_v ++ " =");
        },
        1 => {
            _ = strcpy(&noo, " =");
            if (frontier_register_value_conversions.getRegisterAsRealQuiet(REGISTER_T, &t)) {
                if (realIsSpecial(&t) == 0 and realIsAnInteger(&t) != 0 and frontier_real_type.realToInt32C47(&t, null) == 200) {
                    _ = strcat(&noo, " (conjugates)");
                }
            }
        },
        else => {
            _ = strcpy(&noo, " =");
        },
    }
    if (currentSolverVariable >= FIRST_RESERVED_VARIABLE) {
        const rv = &allReservedVariables[variableNo];
        _ = memcpy(prefix, &rv.reservedVariableName[1], rv.reservedVariableName[0]);
        _ = strcpy(prefix + rv.reservedVariableName[0], &noo);
        _ = strcat(prefix + rv.reservedVariableName[0], &varDescr[variableNo].Desc[0]);
    } else {
        const nv = &allNamedVariables[@intCast(currentSolverVariable - FIRST_NAMED_VARIABLE)];
        _ = memcpy(prefix, &nv.variableName[1], nv.variableName[0]);
        _ = strcpy(prefix + nv.variableName[0], &noo);
    }
    prefixWidth.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
}

pub export fn _displaySolverOutput(regist: calcRegister_t, prefix: [*c]u8, prefixWidth: *i16) callconv(.c) void {
    if (regist == REGISTER_X or regist == REGISTER_Y) {
        __displaySolver(regist, prefix, prefixWidth, regist - REGISTER_X + 1);
    } else if (regist == REGISTER_Z) {
        _ = strcpy(prefix, "Accuracy " ++ STD_ALMOST_EQUAL);
        prefixWidth.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
    }
    if (regist == REGISTER_T) {
        if (funcNameOffset_x() == shiftOffset) {
            _ = strcpy(prefix, "  ");
        } else {
            prefix[0] = 0;
        }
        _ = strcat(prefix, "Result Code =");
        prefixWidth.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
    }
}

pub export fn _displaySolverInput(regist: calcRegister_t, prefix: [*c]u8, prefixWidth: *i16) callconv(.c) void {
    if (regist == REGISTER_X) {
        __displaySolver(regist, prefix, prefixWidth, -1);
    }
}

const noLine: bool_t = 0;
fn _displaySigmaPlus(regist: calcRegister_t, prefix: [*c]u8, prefixWidth: *i16, doLine: bool_t) void {
    const w: i32 = frontier_real_type.realToInt32C47(SIGMA_N.ptr(), null);
    if (regist == REGISTER_X) {
        abi.fmtCStr(prefix, "{d:0>3} data point", .{@as(u32, @intCast(@as(c_int, w)))});
        if (w > 1) {
            _ = stringCopy(prefix + @as(usize, @intCast(stringByteLength(prefix))), "s");
        }
        prefixWidth.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        if (doLine != 0) {
            drawSinglePixelFullWidthLine(Y_POSITION_OF_REGISTER_Y_LINE - 2);
        }
    }
}

// _displayRegType static tables.
const dRT_typeName = [_][*:0]const u8{ "LongInteger", "Real", "Complex", "Time", "Date", "String", "RealMatrix", "ComplexMatrix", "ShortInteger", "Config" };
const dRT_angleSuffix = [_][*:0]const u8{ ", MUL" ++ STD_pi, ", DMS", ", Degree", ", Grad", ", Radian" };
const dRT_vecDim = [_][*:0]const u8{ "", "", "2D", "3D", "3D", "" };
const dRT_coordMode = [_][*:0]const u8{ "RECT", "POLAR", "RECT", "RECT", "SPH", "CYL" };

pub export fn _displayRegType(regist: calcRegister_t, prefix: [*c]u8, prefixWidth: *i16) callconv(.c) void {
    if (regist == REGISTER_X) {
        var t: real_t = undefined;
        _ = frontier_register_value_conversions.getRegisterAsRealQuiet(REGISTER_X, &t);
        const typeIdx: i32 = frontier_real_type.realToInt32C47(&t, null);
        realMultiply(&t, const_1000, &t, &ctxtReal39);
        const subCode: i32 = frontier_real_type.realToInt32C47(&t, null) - 1000 * typeIdx;
        const angSub: i32 = @divTrunc(subCode, 100);
        const polRec: i32 = @rem(@divTrunc(subCode, 10), 10);
        const vecType: i32 = @rem(subCode, 10);
        var typeStr: [40]u8 = undefined;
        _ = strcpy(&typeStr, if (typeIdx >= 0 and typeIdx <= 9) dRT_typeName[@intCast(typeIdx)] else "?");
        if (typeIdx == 8) {
            var baseSuffix: [24]u8 = undefined;
            abi.fmtBufZ(&baseSuffix, ", base {d}", .{@as(i32, angSub * 10 + polRec)});
            _ = strcat(&typeStr, &baseSuffix);
        } else if (typeIdx == 6) {
            if (polRec == 0 and vecType > 0) {
                _ = strcat(&typeStr, if (vecType == 2) @as([*c]const u8, ", col vector") else ", row vector");
            } else if (polRec == 0 and vecType == 0) {
                // no suffix
            } else if (polRec >= 2 and polRec <= 4) {
                const modeIdx: usize = @intCast(if (polRec == 4) @as(i32, 5) else if (polRec == 3) (if (angSub == 0) @as(i32, 3) else 4) else (if (angSub == 0) @as(i32, 2) else 1));
                _ = strcat(&typeStr, ", ");
                _ = strcat(&typeStr, dRT_vecDim[@intCast(polRec)]);
                _ = strcat(&typeStr, " ");
                _ = strcat(&typeStr, dRT_coordMode[modeIdx]);
                if (angSub >= 1 and angSub <= 5) {
                    _ = strcat(&typeStr, dRT_angleSuffix[@intCast(angSub - 1)]);
                }
                if (vecType == 2) {
                    _ = strcat(&typeStr, ", col");
                }
            }
        } else if (typeIdx == 7) {
            _ = strcat(&typeStr, ", ");
            _ = strcat(&typeStr, if (polRec == 0) dRT_coordMode[0] else dRT_coordMode[1]);
            if (angSub >= 1 and angSub <= 5) {
                _ = strcat(&typeStr, dRT_angleSuffix[@intCast(angSub - 1)]);
            }
            if (vecType == 1) {
                _ = strcat(&typeStr, ", row");
            } else if (vecType == 2) {
                _ = strcat(&typeStr, ", col");
            }
        } else if (typeIdx == 2) {
            _ = strcat(&typeStr, ", ");
            _ = strcat(&typeStr, if (angSub == 0) dRT_coordMode[0] else dRT_coordMode[1]);
            if (angSub >= 1 and angSub <= 5) {
                _ = strcat(&typeStr, dRT_angleSuffix[@intCast(angSub - 1)]);
            }
        } else {
            if (angSub >= 1 and angSub <= 5) {
                _ = strcat(&typeStr, dRT_angleSuffix[@intCast(angSub - 1)]);
            }
        }
        abi.fmtCStr(prefix, "{s}", .{std.mem.sliceTo(&typeStr, 0)});
        prefixWidth.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
    }
}

const clearOffset: i32 = -2;
fn displayTrueFalse(regist: calcRegister_t) bool_t {
    _ = regist;
    var sss: [10]u8 = undefined;
    if (temporaryInformation == TI_FALSE) {
        if (clearOffset != 0) {
            abi.fmtBufZ(&sss, "     ", .{});
            _ = showString(&sss, &standardFont, 1, @intCast(@as(i32, Y_POSITION_OF_TRUE_FALSE_LINE) + 6 + clearOffset), vmNormal, 1, 1);
        }
        abi.fmtBufZ(&sss, "false", .{});
        _ = showString(&sss, &standardFont, 1, Y_POSITION_OF_TRUE_FALSE_LINE + 6, vmNormal, 1, 1);
        return 1;
    } else if (temporaryInformation == TI_TRUE) {
        if (clearOffset != 0) {
            abi.fmtBufZ(&sss, "    ", .{});
            _ = showString(&sss, &standardFont, 1, @intCast(@as(i32, Y_POSITION_OF_TRUE_FALSE_LINE) + 6 + clearOffset), vmNormal, 1, 1);
        }
        abi.fmtBufZ(&sss, "true", .{});
        _ = showString(&sss, &standardFont, 1, Y_POSITION_OF_TRUE_FALSE_LINE + 6, vmNormal, 1, 1);
        return 1;
    }
    return 0;
}

const BASEMODE_OFFSET_X: i32 = 2;
const BASEMODE_OFFSET_Y: i32 = 2;
pub export fn displayBaseMode(regist: calcRegister_t) callconv(.c) void {
    const Register_X: calcRegister_t = if (calcMode == CM_NIM) REGISTER_Y else REGISTER_X;

    if (BASEMODEREGISTERX() and regist == REGISTER_X and lastErrorCode == 0) {
        if (getRegisterDataType(REGISTER_X) == dtShortInteger) {
            // Reg Pos Y
            if (displayStack == 1 and calcMode != CM_NIM) {
                frontier_display.shortIntegerToDisplayString(Register_X, tmpString, 1, if (dispBase == 0) 10 else 16);
                if (lastErrorCode == 0 and frontier_char_string.stringWidth(tmpString, fontForShortInteger.?, false, true) + frontier_char_string.stringWidth("  X: ", &standardFont, false, true) <= SCREEN_WIDTH) {
                    _ = showString("  X: ", &standardFont, 0, @intCast(@as(i32, Y_POSITION_OF_REGISTER_X_LINE) - @as(i32, REGISTER_LINE_HEIGHT) * @as(i32, REGISTER_Y - REGISTER_X) + (if (fontForShortInteger == &standardFont) @as(i32, 6) else 0)), vmNormal, 0, 1);
                }
                _ = showString(tmpString, fontForShortInteger.?, @intCast(@as(i32, SCREEN_WIDTH) - frontier_char_string.stringWidth(tmpString, fontForShortInteger.?, false, true)), @intCast(@as(i32, Y_POSITION_OF_REGISTER_X_LINE) - @as(i32, REGISTER_LINE_HEIGHT) * @as(i32, REGISTER_Y - REGISTER_X) + (if (fontForShortInteger == &standardFont) @as(i32, 6) else 0)), vmNormal, 0, 1);
            }
            // reg pos Z
            if ((displayStack == 1 and calcMode != CM_NIM) or displayStack == 2) {
                frontier_display.shortIntegerToDisplayString(Register_X, tmpString, 1, if (displayStack == 1) 2 else (if (dispBase == 0) @as(u8, 10) else 16));
                if (lastErrorCode == 0 and frontier_char_string.stringWidth(tmpString, fontForShortInteger.?, false, true) + frontier_char_string.stringWidth("  X: ", &standardFont, false, true) <= SCREEN_WIDTH) {
                    _ = showString("  X: ", &standardFont, 0, @intCast(@as(i32, Y_POSITION_OF_REGISTER_X_LINE) - @as(i32, REGISTER_LINE_HEIGHT) * @as(i32, REGISTER_Z - REGISTER_X) + (if (fontForShortInteger == &standardFont) @as(i32, 6) else 0)), vmNormal, 0, 1);
                }
                _ = showString(tmpString, fontForShortInteger.?, @intCast(@as(i32, SCREEN_WIDTH) - frontier_char_string.stringWidth(tmpString, fontForShortInteger.?, false, true)), @intCast(@as(i32, Y_POSITION_OF_REGISTER_X_LINE) - @as(i32, REGISTER_LINE_HEIGHT) * @as(i32, REGISTER_Z - REGISTER_X) + (if (fontForShortInteger == &standardFont) @as(i32, 6) else 0)), vmNormal, 0, 1);
            }
            // reg pos T
            if ((displayStack == 1 and calcMode != CM_NIM) or displayStack == 2 or displayStack == 3) {
                frontier_display.shortIntegerToDisplayString(Register_X, tmpString, 1, if (dispBase == 0) (if (getSystemFlag(FLAG_BCD) == 0) @as(u8, 16) else 1) else dispBase);
                if (lastErrorCode == 0 and frontier_char_string.stringWidth(tmpString, fontForShortInteger.?, false, true) + frontier_char_string.stringWidth("  X: ", &standardFont, false, true) <= SCREEN_WIDTH) {
                    _ = showString("  X: ", &standardFont, @intCast(0 + BASEMODE_OFFSET_X), @intCast(@as(i32, Y_POSITION_OF_REGISTER_X_LINE) - @as(i32, REGISTER_LINE_HEIGHT) * @as(i32, REGISTER_T - REGISTER_X) + (if (fontForShortInteger == &standardFont) @as(i32, 6) else 0) + BASEMODE_OFFSET_Y), vmNormal, 0, 1);
                }
                _ = showString(tmpString, fontForShortInteger.?, @intCast(@as(i32, SCREEN_WIDTH) - frontier_char_string.stringWidth(tmpString, fontForShortInteger.?, false, true)), @intCast(@as(i32, Y_POSITION_OF_REGISTER_X_LINE) - @as(i32, REGISTER_LINE_HEIGHT) * @as(i32, REGISTER_T - REGISTER_X) + (if (fontForShortInteger == &standardFont) @as(i32, 6) else 0)), vmNormal, 0, 1);
            }
        } else if (getRegisterDataType(REGISTER_X) == dtLongInteger and solverEstimatesUsed == 0) {
            // longinteger in pos T
            if ((displayStack == 1 and calcMode != CM_NIM) or displayStack == 2 or displayStack == 3) {
                frontier_display.longIntegerToHexDisplayString(REGISTER_X, tmpString, 1, if (dispBase == 0) (if (getSystemFlag(FLAG_BCD) == 0) @as(u32, 16) else 1) else dispBase, @intCast(@as(i32, SCREEN_WIDTH) - (if (isShiftOffset()) @as(i32, 10) else 0)));
                const printFirstCol: bool_t = @intFromBool(fontForShortInteger == &tinyFont);
                const printWillFit: bool_t = @intFromBool(frontier_char_string.stringWidth(tmpString, fontForShortInteger.?, printFirstCol != 0, true) + frontier_char_string.stringWidth("  X:" ++ STD_INTEGER_Z ++ ": ", &standardFont, false, true) <= SCREEN_WIDTH - (if (isShiftOffset()) @as(i32, 10) else 0));
                const xoff: u32 = if (printWillFit != 0) @intCast(@as(i32, SCREEN_WIDTH) - (if (isShiftOffset()) @as(i32, 10) else 0) - frontier_char_string.stringWidth(tmpString, fontForShortInteger.?, printFirstCol != 0, true) - 3) else (if (isShiftOffset()) @as(u32, 10) else 0);
                if (lastErrorCode == 0 and printWillFit != 0) {
                    _ = showString("  X:" ++ STD_INTEGER_Z ++ ": ", &standardFont, @intCast(0 + BASEMODE_OFFSET_X), @intCast(@as(i32, Y_POSITION_OF_REGISTER_X_LINE) - @as(i32, REGISTER_LINE_HEIGHT) * @as(i32, REGISTER_T - REGISTER_X) + (if (fontForShortInteger == &standardFont) @as(i32, 6) else 0) + BASEMODE_OFFSET_Y), vmNormal, 0, 1);
                }
                _ = showStringEnhanced(tmpString, fontForShortInteger.?, xoff, @intCast(@as(i32, Y_POSITION_OF_REGISTER_X_LINE) - @as(i32, REGISTER_LINE_HEIGHT) * @as(i32, REGISTER_T - REGISTER_X) + (if (fontForShortInteger == &standardFont) @as(i32, 6) else 0)), vmNormal, printFirstCol, 1, NO_compress, NO_raise, DO_Show, NO_Bold, DO_LF);
            }
        }

        if (displayStack == 3) {
            drawSinglePixelFullWidthLine(Y_POSITION_OF_REGISTER_Z_LINE - 2);
        } else if (displayStack == 2) {
            drawSinglePixelFullWidthLine(Y_POSITION_OF_REGISTER_Y_LINE - 2);
        } else if (displayStack == 1) {
            drawSinglePixelFullWidthLine(Y_POSITION_OF_REGISTER_X_LINE - 2);
        }
    }
}

pub export fn registerFMA(regist: calcRegister_t, tmp1: *real_t, tmp2: *real_t, tmp3: *real34_t, angle: *angularMode_t, c: *realContext_t) callconv(.c) bool_t {
    if (getRegisterDataType(regist) == dtShortInteger or getRegisterDataType(regist + 1) == dtShortInteger or getRegisterDataType(regist + 2) == dtShortInteger) {
        return 0;
    }
    if (!frontier_register_value_conversions.getRegisterAsRealQuiet(regist, tmp1)) {
        return 0;
    }
    if (getRegisterDataType(regist) == dtReal34) {
        angle.* = getRegisterAngularMode(regist);
    } else {
        angle.* = amNone;
    }
    if (!frontier_register_value_conversions.getRegisterAsRealQuiet(regist + 1, tmp2)) {
        return 0;
    }
    realMultiply(tmp1, tmp2, tmp1, c);
    if (!frontier_register_value_conversions.getRegisterAsRealQuiet(regist + 2, tmp2)) {
        return 0;
    }
    realAdd(tmp1, tmp2, tmp1, c);
    realToReal34(tmp1, @ptrCast(tmp3));
    return 1;
}

const LRWidth: i16 = 140;
fn displayLRtemporaryInformation(prefix1: [*c]const u8, prefix2: [*c]const u8, prefix: [*c]u8, label: [*c]const u8, prefixPre: bool_t, prefixPost: bool_t, prefixWidth: *i16) void {
    _ = strcpy(prefix, prefix1);
    _ = strcat(prefix, frontier_debug.getCurveFitModeFormula(lrChosen));
    _ = strcat(prefix, prefix2);
    while (frontier_char_string.stringWidth(prefix, &standardFont, prefixPre != 0, prefixPost != 0) + 1 < LRWidth) {
        _ = strcat(prefix, STD_SPACE_6_PER_EM);
    }
    _ = strcat(prefix, label);
    _ = strcat(prefix, STD_SPACE_4_PER_EM ++ "=" ++ STD_SPACE_HAIR);
    prefixWidth.* = frontier_char_string.stringWidth(prefix, &standardFont, prefixPre != 0, prefixPost != 0) + 1;
}

const RESTORE_T: bool_t = 1;

fn _refreshRegisterLine(regist_in: calcRegister_t, restoreRegisterT: bool_t) void {
    var regist = regist_in;
    var w: i32 = 0;
    var wLastBaseNumeric: i16 = undefined;
    var wLastBaseStandard: i16 = undefined;
    var prefixWidth: i16 = 0;
    var lineWidth: i16 = 0;
    const prefixPre: bool_t = 1;
    const prefixPost: bool_t = 1;
    const origDisplayStack: u8 = displayStack;
    var distModeActive: bool_t = 0;

    var prefix: [200]u8 = undefined;
    var lastBase: [20]u8 = undefined;

    if (comptime dmcp_build) {
        keyBuffer_pop();
        if (!(skippedStackLines != 0) and (calcMode == CM_NORMAL or calcMode == CM_MIM) and
            !(regist == REGISTER_X) and
            !runningOnSimOrUSB() and
            !(emptyKeyBuffer() != 0) and
            key_empty() == 1)
        {
            skippedStackLines = 1;
            return;
        }
    }

    if (BASEMODEREGISTERX() and !SHOWMODE() and displayStack != 4 - displayStackSHOIDISP) {
        if (getRegisterDataType(REGISTER_X) == dtShortInteger) {
            fnDisplayStack(4 - displayStackSHOIDISP);
        } else {
            fnDisplayStack(3);
        }
    } else {
        if (XXFNMODEACTIVE()) {
            fnDisplayStack(3);
        }
    }

    if ((temporaryInformation == TI_SHOW_REGISTER or SHOWMODE()) and regist == REGISTER_X) {
        drawSinglePixelFullWidthLine(Y_POSITION_OF_REGISTER_T_LINE - 4);
    }

    if ((calcMode != CM_BUG_ON_SCREEN) and !GRAPHMODE() and (calcMode != CM_LISTXY)) {
        if (temporaryInformation != TI_SHOW_REGISTER_BIG) {
            clearRegisterLine(regist, true, regist != REGISTER_Y);
        }

        if (getRegisterDataType(REGISTER_X) == dtReal34Matrix or (calcMode == CM_MIM and getRegisterDataType(@intCast(matrixIndex)) == dtReal34Matrix)) {
            displayStack = cachedDisplayStack;
        } else if (getRegisterDataType(REGISTER_X) == dtComplex34Matrix or (calcMode == CM_MIM and getRegisterDataType(@intCast(matrixIndex)) == dtComplex34Matrix)) {
            displayStack = cachedDisplayStack;
        }

        if (temporaryInformation == TI_STATISTIC_LR and (getRegisterDataType(REGISTER_X) != dtReal34)) {
            if (regist == REGISTER_X) {
                if (orOrtho(lrSelection) == CF_ORTHOGONAL_FITTING) {
                    abi.fmtBufZ(tmpString[0..2560], "L.R. selected to OrthoF", .{});
                } else {
                    abi.fmtBufZ(tmpString[0..2560], "L.R. selected to {d:0>3}.", .{@as(u32, lrSelection & 0x01FF)});
                }
                if (comptime extra_info) {
                    abi.fmtBufZ(errorMessage[0..512], "BestF is set, but will not work until REAL data points are used.", .{});
                    moreInfoOnError("In function _refreshRegisterLine:", errorMessage, &errorMessages[ERROR_INVALID_DATA_TYPE_FOR_OP], null);
                }
                w = frontier_char_string.stringWidth(tmpString, &standardFont, true, true);
                _ = showString(tmpString, &standardFont, @intCast(@as(i32, SCREEN_WIDTH) - w), Y_POSITION_OF_REGISTER_X_LINE + 6, vmNormal, 1, 1);
            }
        } else if (temporaryInformation == TI_BATTV and regist == REGISTER_X) {
            abi.fmtBufZ(&prefix, "V" ++ STD_SPACE_FIGURE ++ "=", .{});
            displayTemporaryInformationOnX(&prefix);
        } else if (temporaryInformation == TI_BYTES and regist == REGISTER_X) {
            abi.fmtBufZ(&prefix, "Bytes" ++ STD_SPACE_FIGURE ++ "=", .{});
            displayTemporaryInformationOnX(&prefix);
        } else if (temporaryInformation == TI_BITS and regist == REGISTER_X) {
            abi.fmtBufZ(&prefix, "Bits" ++ STD_SPACE_FIGURE ++ "=", .{});
            displayTemporaryInformationOnX(&prefix);
        } else if (temporaryInformation == TI_ARE_YOU_SURE and regist == REGISTER_X) {
            const id = frontier_config.getConfirmationTiId();
            _ = showString(&confirmationTI[id].string, &standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE + 6, vmNormal, 1, 1);
        } else if (temporaryInformation == TI_WHO) {
            if (regist == REGISTER_Z or regist == REGISTER_Y or regist == REGISTER_X) {
                _ = showStringEnhanced(whoStr1, &standardFont, 1, @intCast(@as(i32, Y_POSITION_OF_REGISTER_X_LINE) - @as(i32, REGISTER_LINE_HEIGHT) * 2 + 6), vmNormal, 1, 1, NO_compress, NO_raise, DO_Show, NO_Bold, DO_LF);
            }
        } else if (temporaryInformation == TI_VERSION and regist == REGISTER_X) {
            clearRegisterLine(REGISTER_T, true, true);
            clearRegisterLine(REGISTER_Z, true, true);
            clearRegisterLine(REGISTER_Y, true, true);
            clearRegisterLine(REGISTER_X, true, true);
            _ = showStringEnhanced(versionStr2, &standardFont, 1, Y_POSITION_OF_REGISTER_T_LINE + 6, vmNormal, 1, 1, NO_compress, NO_raise, DO_Show, NO_Bold, DO_LF);
            _ = showStringEnhanced(versionStr, &standardFont, 1, Y_POSITION_OF_REGISTER_Z_LINE + 6, vmNormal, 1, 1, NO_compress, NO_raise, DO_Show, NO_Bold, DO_LF);
            _ = showStringEnhanced(disclaimerStr, &standardFont, 1, Y_POSITION_OF_REGISTER_Y_LINE + 6, vmNormal, 1, 1, NO_compress, NO_raise, DO_Show, NO_Bold, DO_LF);
        } else if (temporaryInformation == TI_DISP_JULIAN) {
            var j: real34_t = undefined;
            var tmpStr2: [20]u8 = undefined;
            uInt32ToReal34(firstGregorianDay, &j);
            frontier_date_time.julianDayToInternalDate(&j, REGISTER_REAL34_DATA(TEMP_REGISTER_1));
            frontier_display.dateToDisplayString(TEMP_REGISTER_1, &tmpStr2);
            abi.fmtBufZ(tmpString[0..2560], "First Gregorian day set: {s}", .{std.mem.sliceTo(&tmpStr2, 0)});
            _ = showString(tmpString, &standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE + TEMPORARY_INFO_OFFSET + 6, vmNormal, 1, 1);
        } else if (temporaryInformation == TI_DISP_WOY) {
            abi.fmtBufZ(tmpString[0..2560], "Week of Year rule set: {s}.{s}", .{ std.mem.sliceTo(&nameOfWday_en[firstDayOfWeek].itemName, 0), std.mem.sliceTo(&nameOfWday_en[firstWeekOfYearDay].itemName, 0) });
            _ = showString(tmpString, &standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE + TEMPORARY_INFO_OFFSET + 6, vmNormal, 1, 1);
        } else if (temporaryInformation == TI_DISP_JULIAN_WOY) {
            var j: real34_t = undefined;
            var tmpStr2: [20]u8 = undefined;
            uInt32ToReal34(firstGregorianDay, &j);
            frontier_date_time.julianDayToInternalDate(&j, REGISTER_REAL34_DATA(TEMP_REGISTER_1));
            frontier_display.dateToDisplayString(TEMP_REGISTER_1, &tmpStr2);
            abi.fmtBufZ(tmpString[0..2560], "First Gregorian day set: {s}", .{std.mem.sliceTo(&tmpStr2, 0)});
            _ = showString(tmpString, &standardFont, 1, Y_POSITION_OF_REGISTER_Y_LINE + TEMPORARY_INFO_OFFSET + 6, vmNormal, 1, 1);
            abi.fmtBufZ(tmpString[0..2560], "Week of Year rule set: {s}.{s}", .{ std.mem.sliceTo(&nameOfWday_en[firstDayOfWeek].itemName, 0), std.mem.sliceTo(&nameOfWday_en[firstWeekOfYearDay].itemName, 0) });
            _ = showString(tmpString, &standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE + TEMPORARY_INFO_OFFSET + 6, vmNormal, 1, 1);
        } else if (temporaryInformation == TI_WOY and regist == REGISTER_X) {
            abi.fmtBufZ(&prefix, "Week of Year" ++ STD_SPACE_FIGURE ++ "=", .{});
            displayTemporaryInformationOnX(&prefix);
        } else if (temporaryInformation == TI_WOY_RULE and regist == REGISTER_X) {
            abi.fmtBufZ(&prefix, "{s}.{s}", .{ std.mem.sliceTo(&nameOfWday_en[firstDayOfWeek].itemName, 0), std.mem.sliceTo(&nameOfWday_en[firstWeekOfYearDay].itemName, 0) });
            displayTemporaryInformationOnX(&prefix);
        } else if (temporaryInformation == TI_KEYS and regist == REGISTER_X) {
            _ = showString(errorMessage, &standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE + 6, vmNormal, 1, 1);
        } else if (regist == TRUE_FALSE_REGISTER_LINE and displayTrueFalse(regist) != 0) {
            // handled
        } else if (temporaryInformation == TI_RESET and regist == REGISTER_X) {
            abi.fmtBufZ(tmpString[0..2560], "{s}", .{errMsgRow(TI_All_data_prgms_cleared)});
            w = frontier_char_string.stringWidth(tmpString, &standardFont, true, true);
            _ = showString(tmpString, &standardFont, @intCast(@as(i32, SCREEN_WIDTH) - w), Y_POSITION_OF_REGISTER_X_LINE + 6, vmNormal, 1, 1);
        } else if (temporaryInformation == TI_SAVED and regist == REGISTER_X) {
            abi.fmtBufZ(&prefix, "Saved", .{});
            displayTemporaryInformationOnX(&prefix);
        } else if (ir_printing and temporaryInformation == TI_PRINT_COMPLETE and regist == REGISTER_X) {
            abi.fmtBufZ(&prefix, "Print completed", .{});
            displayTemporaryInformationOnX(&prefix);
        } else if (temporaryInformation == TI_DEL_ALL_PRGMS and regist == REGISTER_X) {
            abi.fmtBufZ(tmpString[0..2560], "{s}", .{errMsgRow(TI_All_user_prgms_deleted)});
            w = frontier_char_string.stringWidth(tmpString, &standardFont, true, true);
            _ = showString(tmpString, &standardFont, @intCast(@as(i32, SCREEN_WIDTH) - w), Y_POSITION_OF_REGISTER_X_LINE + 6, vmNormal, 1, 1);
        } else if (temporaryInformation == TI_CLEAR_ALL_FLAGS and regist == REGISTER_X) {
            abi.fmtBufZ(tmpString[0..2560], "{s}", .{errMsgRow(TI_All_user_flags_cleared)});
            w = frontier_char_string.stringWidth(tmpString, &standardFont, true, true);
            _ = showString(tmpString, &standardFont, @intCast(@as(i32, SCREEN_WIDTH) - w), Y_POSITION_OF_REGISTER_X_LINE + 6, vmNormal, 1, 1);
        } else if (temporaryInformation == TI_CLEAR_ALL_MENUS and regist == REGISTER_X) {
            abi.fmtBufZ(tmpString[0..2560], "{s}", .{errMsgRow(TI_All_user_menus_cleared)});
            w = frontier_char_string.stringWidth(tmpString, &standardFont, true, true);
            _ = showString(tmpString, &standardFont, @intCast(@as(i32, SCREEN_WIDTH) - w), Y_POSITION_OF_REGISTER_X_LINE + 6, vmNormal, 1, 1);
        } else if (temporaryInformation == TI_CLEAR_ALL_VARIABLES and regist == REGISTER_X) {
            abi.fmtBufZ(tmpString[0..2560], "{s}", .{errMsgRow(TI_All_user_vars_cleared)});
            w = frontier_char_string.stringWidth(tmpString, &standardFont, true, true);
            _ = showString(tmpString, &standardFont, @intCast(@as(i32, SCREEN_WIDTH) - w), Y_POSITION_OF_REGISTER_X_LINE + 6, vmNormal, 1, 1);
        } else if (temporaryInformation == TI_DEL_ALL_MENUS and regist == REGISTER_X) {
            abi.fmtBufZ(tmpString[0..2560], "{s}", .{errMsgRow(TI_All_user_menus_deleted)});
            w = frontier_char_string.stringWidth(tmpString, &standardFont, true, true);
            _ = showString(tmpString, &standardFont, @intCast(@as(i32, SCREEN_WIDTH) - w), Y_POSITION_OF_REGISTER_X_LINE + 6, vmNormal, 1, 1);
        } else if (temporaryInformation == TI_DEL_ALL_VARIABLES and regist == REGISTER_X) {
            abi.fmtBufZ(tmpString[0..2560], "{s}", .{errMsgRow(TI_All_user_vars_deleted)});
            w = frontier_char_string.stringWidth(tmpString, &standardFont, true, true);
            _ = showString(tmpString, &standardFont, @intCast(@as(i32, SCREEN_WIDTH) - w), Y_POSITION_OF_REGISTER_X_LINE + 6, vmNormal, 1, 1);
        } else if (!dmcp_build and temporaryInformation == TI_NOT_AVAILABLE and regist == REGISTER_X) {
            abi.fmtBufZ(&prefix, "{s}", .{errMsgRow(TI_Not_on_simulator)});
            displayTemporaryInformationOnX(&prefix);
        } else if (dmcp_build and temporaryInformation == TI_NOT_AVAILABLE and regist == REGISTER_X) {
            abi.fmtBufZ(&prefix, "{s}", .{errMsgRow(TI_Only_on_simulator)});
            displayTemporaryInformationOnX(&prefix);
        } else if (temporaryInformation == TI_BACKUP_RESTORED and regist == REGISTER_X) {
            clearRegisterLine(REGISTER_X, true, true);
            clearRegisterLine(REGISTER_Y, true, true);
            clearRegisterLine(REGISTER_Z, true, true);
            clearRegisterLine(REGISTER_T, true, true);
            _ = showString(&errorMessages[TI_Backup_restored], &standardFont, 1, Y_POSITION_OF_REGISTER_Z_LINE + 6, vmNormal, 1, 1);
            _ = showStringEnhanced(versionStr, &standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE + 6, vmNormal, 1, 1, NO_compress, NO_raise, DO_Show, NO_Bold, DO_LF);
            _ = showStringEnhanced(versionStr2, &standardFont, 1, Y_POSITION_OF_REGISTER_Y_LINE + 6, vmNormal, 1, 1, NO_compress, NO_raise, DO_Show, NO_Bold, DO_LF);
        } else if (temporaryInformation == TI_STATEFILE_RESTORED and regist == REGISTER_X) {
            abi.fmtBufZ(&prefix, "{s}", .{errMsgRow(TI_State_file_restored)});
            displayTemporaryInformationOnX(&prefix);
        } else if (temporaryInformation == TI_PROGRAMS_RESTORED and regist == REGISTER_X) {
            abi.fmtBufZ(&prefix, "                                ", .{});
            displayTemporaryInformationOnX(&prefix);
            abi.fmtBufZ(&prefix, "{s}", .{errMsgRow(TI_Saved_programs_and_equations)});
            _ = showString(&prefix, &standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE - 3, vmNormal, 1, 1);
            abi.fmtBufZ(&prefix, "{s}", .{errMsgRow(TI_appended)});
            _ = showString(&prefix, &standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE + 17, vmNormal, 1, 1);
        } else if (temporaryInformation == TI_REGISTERS_RESTORED and regist == REGISTER_X) {
            abi.fmtBufZ(&prefix, "                                  ", .{});
            displayTemporaryInformationOnX(&prefix);
            abi.fmtBufZ(&prefix, "{s}", .{errMsgRow(TI_Saved_global_and_local_registers)});
            _ = showString(&prefix, &standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE - 3, vmNormal, 1, 1);
            abi.fmtBufZ(&prefix, "{s}", .{errMsgRow(TI_w_local_flags_restored)});
            _ = showString(&prefix, &standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE + 17, vmNormal, 1, 1);
        } else if (temporaryInformation == TI_SETTINGS_RESTORED and regist == REGISTER_X) {
            abi.fmtBufZ(&prefix, "{s}", .{errMsgRow(TI_Saved_system_settings_restored)});
            displayTemporaryInformationOnX(&prefix);
        } else if (temporaryInformation == TI_SUMS_RESTORED and regist == REGISTER_X) {
            abi.fmtBufZ(&prefix, "{s}", .{errMsgRow(TI_Saved_statistic_data_restored)});
            displayTemporaryInformationOnX(&prefix);
        } else if (temporaryInformation == TI_VARIABLES_RESTORED and regist == REGISTER_X) {
            abi.fmtBufZ(&prefix, "{s}", .{errMsgRow(TI_Saved_user_variables_restored)});
            displayTemporaryInformationOnX(&prefix);
        } else if (temporaryInformation == TI_PROGRAM_LOADED and regist == REGISTER_X) {
            abi.fmtBufZ(&prefix, "{s}", .{errMsgRow(TI_Program_file_loaded)});
            displayTemporaryInformationOnX(&prefix);
        } else if (temporaryInformation == TI_UNDO_DISABLED and regist == REGISTER_X) {
            _ = showString(&errorMessages[ERROR_TI_UNDO_FAILED], &standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE + 6, vmNormal, 1, 1);
        }
        // NEW SHOW
        else if (temporaryInformation == TI_SHOW_REGISTER_SMALL or temporaryInformation == TI_SHOW_REGISTER) {
            switch (regist) {
                REGISTER_X => {
                    clearScreenOld(@intFromBool(false), clrRegisterLines, clrSoftkeys);
                    var nn: i16 = 0;
                    while (nn <= 9) {
                        showDispSmall(@intCast(nn * SHOWLineSize), @intCast(nn));
                        nn += 1;
                    }
                    showBottomLine();
                },
                else => {},
            }
        } else if (temporaryInformation == TI_SHOW_REGISTER_TINY) {
            switch (regist) {
                REGISTER_X => {
                    clearScreenOld(@intFromBool(false), clrRegisterLines, clrSoftkeys);
                    var nn: i16 = 0;
                    while (nn <= @divTrunc(SCREEN_HEIGHT, line_tiny) and nn < SHOWLineMax) {
                        showDispSmall(@intCast(nn * SHOWLineSize), @intCast(nn));
                        nn += 1;
                    }
                    showBottomLine();
                },
                else => {},
            }
        } else if (temporaryInformation == TI_SHOW_REGISTER_BIG) {
            if (regist == REGISTER_T) {
                var nn: i16 = 0;
                while (nn <= 5) {
                    showDisp(@intCast(nn * SHOWLineSize), @intCast(nn));
                    nn += 1;
                }
                showBottomLine();
            }
        }
        // The main "register fits" branch
        else if ((regist < REGISTER_X + @as(calcRegister_t, @intCast(minI(displayStack, origDisplayStack)))) or
            (lastErrorCode != 0 and regist == errorMessageRegisterLine) or
            (temporaryInformation == TI_VIEW_REGISTER and regist == REGISTER_T))
        {
            refreshRegisterMainBranch(&regist, restoreRegisterT, origDisplayStack, &prefix, &lastBase, &prefixWidth, &lineWidth, &w, &wLastBaseNumeric, &wLastBaseStandard, prefixPre, prefixPost, &distModeActive);
        }

        if (regist == REGISTER_T) {
            lineTWidth = lineWidth;
        }
    }

    if (getRegisterDataType(REGISTER_X) == dtReal34Matrix or getRegisterDataType(REGISTER_X) == dtComplex34Matrix or calcMode == CM_MIM or distModeActive != 0 or BASEMODEACTIVE() or XXFNMODEACTIVE()) {
        displayStack = origDisplayStack;
    }
}

// The main "register fits on its line" branch of _refreshRegisterLine.
fn refreshRegisterMainBranch(regist_p: *calcRegister_t, restoreRegisterT: bool_t, origDisplayStack: u8, prefix: [*c]u8, lastBase: [*c]u8, prefixWidth_p: *i16, lineWidth_p: *i16, w_p: *i32, wLastBaseNumeric_p: *i16, wLastBaseStandard_p: *i16, prefixPre: bool_t, prefixPost: bool_t, distModeActive_p: *bool_t) void {
    var regist = regist_p.*;
    prefixWidth_p.* = 0;
    const baseY: i16 = @intCast(@as(i32, Y_POSITION_OF_REGISTER_X_LINE) - @as(i32, REGISTER_LINE_HEIGHT) * @as(i32, regist - REGISTER_X + (if (restoreRegisterT == RESTORE_T) @as(calcRegister_t, 0) else (if (temporaryInformation == TI_VIEW_REGISTER and regist == REGISTER_T) @as(calcRegister_t, 0) else (if (getRegisterDataType(REGISTER_X) == dtReal34Matrix or getRegisterDataType(REGISTER_X) == dtComplex34Matrix) @as(calcRegister_t, @intCast(4 - @as(i32, displayStack))) else 0)))));
    const origRegist: calcRegister_t = regist;
    if (temporaryInformation == TI_VIEW_REGISTER and regist == REGISTER_T) {
        if (FIRST_RESERVED_VARIABLE <= currentViewRegister and currentViewRegister < LAST_RESERVED_VARIABLE and allReservedVariables[@intCast(@as(calcRegister_t, @intCast(currentViewRegister)) - FIRST_RESERVED_VARIABLE)].header.bits.pointerToRegisterData == C47_NULL) {
            copySourceRegisterToDestRegister(@intCast(currentViewRegister), TEMP_REGISTER_1);
            regist = TEMP_REGISTER_1;
        } else {
            regist = @intCast(currentViewRegister);
        }
    }

    if (regist == REGISTER_X and currentInputVariable != INVALID_VARIABLE) {
        inputRegName(prefix, prefixWidth_p);
    }

    // STATISTICAL DISTR & SOLVER
    if (regist == REGISTER_X and lastErrorCode == 0 and calcMode != CM_PEM and
        ((PROBMENU()) or
            (frontier_softmenus.currentMenu() == -MNU_Solver_TOOL and solverEstimatesUsed != 0 and temporaryInformation != TI_SOLVER_VARIABLE_RESULT)))
    {
        var r_i: [*c]const u8 = null;
        var r_j: [*c]const u8 = null;
        var r_k: [*c]const u8 = null;
        var register_i: calcRegister_t = REGISTER_X;
        var register_j: calcRegister_t = REGISTER_X;
        var register_k: calcRegister_t = REGISTER_X;

        switch (frontier_softmenus.currentMenu()) {
            -MNU_Solver_TOOL => {
                r_i = &indexOfItems[VAR_UEST].itemCatalogName;
                register_i = RESERVED_VARIABLE_UEST;
                r_j = &indexOfItems[VAR_LEST].itemCatalogName;
                register_j = RESERVED_VARIABLE_LEST;
            },
            -MNU_PARETO => {
                r_i = STD_mu;
                register_i = REGISTER_M;
                r_j = STD_sigma;
                register_j = REGISTER_S;
                r_k = STD_alpha;
                register_k = REGISTER_Q;
            },
            -MNU_GEV => {
                r_i = STD_mu;
                register_i = REGISTER_M;
                r_j = STD_sigma;
                register_j = REGISTER_S;
                r_k = STD_xi;
                register_k = REGISTER_Q;
            },
            -MNU_BINOM => {
                r_i = STD_p;
                register_i = REGISTER_P;
                r_j = STD_n;
                register_j = REGISTER_N;
            },
            -MNU_CAUCH => {
                r_i = STD_x ++ STD_SUB_0;
                register_i = REGISTER_M;
                r_j = STD_gamma;
                register_j = REGISTER_S;
            },
            -MNU_WEIBL => {
                r_i = STD_k;
                register_i = REGISTER_Q;
                r_j = STD_lambda;
                register_j = REGISTER_S;
            },
            -MNU_CHI2, -MNU_T => {
                r_i = STD_nu;
                register_i = REGISTER_M;
            },
            -MNU_EXPON, -MNU_POISS => {
                r_i = STD_lambda;
                register_i = REGISTER_R;
            },
            -MNU_F => {
                r_i = STD_d ++ STD_SUB_1;
                register_i = REGISTER_M;
                r_j = STD_d ++ STD_SUB_2;
                register_j = REGISTER_N;
            },
            -MNU_GEOM => {
                r_i = STD_p;
                register_i = REGISTER_P;
            },
            -MNU_HYPER => {
                r_i = STD_N;
                register_i = REGISTER_M;
                r_j = STD_n;
                register_j = REGISTER_N;
                r_k = STD_K;
                register_k = REGISTER_Q;
            },
            -MNU_LOGIS => {
                r_j = STD_s;
                register_j = REGISTER_S;
                r_i = STD_mu;
                register_i = REGISTER_M;
            },
            -MNU_NORML => {
                r_j = STD_sigma;
                register_j = REGISTER_S;
                r_i = STD_mu;
                register_i = REGISTER_M;
            },
            -MNU_UNIFORM, -MNU_DISUNIFORM => {
                r_i = STD_a;
                register_i = REGISTER_M;
                r_j = STD_b;
                register_j = REGISTER_N;
            },
            else => {},
        }

        if (r_i != null or r_j != null or r_k != null) {
            stats_param_display(r_i, register_i, prefix, tmpString, REGISTER_T);
            stats_param_display(r_j, register_j, prefix, tmpString, REGISTER_Z);
            stats_param_display(r_k, register_k, prefix, tmpString, REGISTER_Y);

            prefix[0] = 0;
            tmpString[0] = 0;
            var ii: u8 = 255;
            if (r_i != null) {
                ii = Y_POSITION_OF_REGISTER_Z_LINE;
                fnDisplayStack(3);
                distModeActive_p.* = 1;
            }
            if (r_j != null) {
                ii = Y_POSITION_OF_REGISTER_Y_LINE;
                fnDisplayStack(2);
                distModeActive_p.* = 1;
            }
            if (r_k != null) {
                ii = Y_POSITION_OF_REGISTER_X_LINE;
                fnDisplayStack(1);
                distModeActive_p.* = 1;
            }
            if (distModeActive_p.* != 0) {
                drawSinglePixelFullWidthLine(@as(i32, ii) - 2);
                if (displayStack != origDisplayStack) {
                    // refreshScreen(81); // (commented out upstream)
                }
            }
        }
    }

    // XXFN DISPLAY
    if (regist == REGISTER_X and XXFNMODEACTIVE()) {
        const tmpY: i32 = @as(i32, Y_POSITION_OF_REGISTER_X_LINE) - @as(i32, REGISTER_LINE_HEIGHT) * @as(i32, REGISTER_T - REGISTER_X);

        var angle: angularMode_t = undefined;
        var tmp1: real_t = undefined;
        var tmp2: real_t = undefined;
        var tmp3: real34_t = undefined;
        const FMA_X: i32 = 19 - 3;
        const FMA_T: i32 = -1 - 3;
        const savedDisplayFormat: u8 = displayFormat;
        const savedDisplayFormatDigits: u8 = displayFormatDigits;
        displayFormat = DF_ALL;
        displayFormatDigits = 19;

        {
            abi.fmtBufZ(tmpString[0..2560], "X{s}Y+Z=", .{std.mem.span(PRODUCT_SIGN())});
            const xx = showString(tmpString, &standardFont, @intCast(if (isShiftOffset()) @as(i32, 20) else 0), @intCast(tmpY + FMA_X), vmNormal, 0, 1);
            if (isXFNregisterValid3r(REGISTER_X + (if (calcMode == CM_NIM) @as(calcRegister_t, 1) else 0)) and registerFMA(REGISTER_X + (if (calcMode == CM_NIM) @as(calcRegister_t, 1) else 0), &tmp1, &tmp2, &tmp3, &angle, &ctxtReal39) != 0) {
                tmpString[0] = 0;
                frontier_display.real34ToDisplayString(&tmp3, @intCast(angle), tmpString, &standardFont, @intCast(@as(i32, SCREEN_WIDTH) - (if (isShiftOffset()) @as(i32, 20) else 0) - @as(i32, @intCast(xx))), 34, LIMITEXP, FRONTSPACE, NOIRFRAC);
            } else {
                abi.fmtBufZ(tmpString[0..2560], "{s} ", .{errMsgRow(ERROR_INVALID_TYPE_XFN)});
            }
            _ = showString(tmpString, &standardFont, @intCast(@as(i32, SCREEN_WIDTH) - frontier_char_string.stringWidth(tmpString, &standardFont, false, true)), @intCast(tmpY + FMA_X), vmNormal, 0, 1);
        }
        if (getSystemFlag(FLAG_SSIZE8) != 0) {
            abi.fmtBufZ(tmpString[0..2560], "T{s}A+B=", .{std.mem.span(PRODUCT_SIGN())});
            const xx = showString(tmpString, &standardFont, @intCast(if (isShiftOffset()) @as(i32, 20) else 0), @intCast(tmpY + FMA_T), vmNormal, 0, 1);
            if (isXFNregisterValid3r(REGISTER_T + (if (calcMode == CM_NIM) @as(calcRegister_t, 1) else 0)) and registerFMA(REGISTER_T + (if (calcMode == CM_NIM) @as(calcRegister_t, 1) else 0), &tmp1, &tmp2, &tmp3, &angle, &ctxtReal39) != 0) {
                tmpString[0] = 0;
                frontier_display.real34ToDisplayString(&tmp3, @intCast(angle), tmpString, &standardFont, @intCast(@as(i32, SCREEN_WIDTH) - (if (isShiftOffset()) @as(i32, 20) else 0) - @as(i32, @intCast(xx))), 34, LIMITEXP, FRONTSPACE, NOIRFRAC);
            } else {
                abi.fmtBufZ(tmpString[0..2560], "{s} ", .{errMsgRow(ERROR_INVALID_TYPE_XFN)});
            }
            _ = showString(tmpString, &standardFont, @intCast(@as(i32, SCREEN_WIDTH) - frontier_char_string.stringWidth(tmpString, &standardFont, false, true)), @intCast(tmpY + FMA_T), vmNormal, 0, 1);
        }
        displayFormat = savedDisplayFormat;
        displayFormatDigits = savedDisplayFormatDigits;
        drawSinglePixelFullWidthLine(Y_POSITION_OF_REGISTER_Z_LINE - 2);
        fnDisplayStack(3);
    }

    refreshRegisterDataDispatch(&regist, origRegist, restoreRegisterT, baseY, prefix, lastBase, prefixWidth_p, lineWidth_p, w_p, wLastBaseNumeric_p, wLastBaseStandard_p, prefixPre, prefixPost);

    if (temporaryInformation == TI_VIEW_REGISTER and origRegist == REGISTER_X) {
        regist = REGISTER_X;
    }
    regist_p.* = regist;
}

const const34_1e6_unused = {};

fn refreshRegisterDataDispatch(regist_p: *calcRegister_t, origRegist: calcRegister_t, restoreRegisterT: bool_t, baseY: i16, prefix: [*c]u8, lastBase: [*c]u8, prefixWidth_p: *i16, lineWidth_p: *i16, w_p: *i32, wLastBaseNumeric_p: *i16, wLastBaseStandard_p: *i16, prefixPre: bool_t, prefixPost: bool_t) void {
    _ = restoreRegisterT;
    const regist = regist_p.*;
    const hp = checkHPoffset();

    if (lastErrorCode != 0 and regist == errorMessageRegisterLine) {
        if (frontier_char_string.stringWidth(&errorMessages[lastErrorCode], &standardFont, true, true) <= SCREEN_WIDTH - 1) {
            if (lastErrorCode == ERROR_RESERVED_VARIABLE_NAME) {
                abi.fmtBufZ(tmpString[0..2560], "{s}: {s}", .{ errMsgRow(lastErrorCode), std.mem.span(@as([*:0]const u8, errorMessage)) });
                _ = showString(tmpString, &standardFont, 1, @intCast(@as(i32, Y_POSITION_OF_REGISTER_X_LINE) - @as(i32, REGISTER_LINE_HEIGHT) * @as(i32, regist - REGISTER_X) + 6), vmNormal, 1, 1);
            } else {
                _ = showString(&errorMessages[lastErrorCode], &standardFont, 1, @intCast(@as(i32, Y_POSITION_OF_REGISTER_X_LINE) - @as(i32, REGISTER_LINE_HEIGHT) * @as(i32, regist - REGISTER_X) + 6), vmNormal, 1, 1);
            }
        } else {
            if (comptime extra_info) {
                abi.fmtBufZ(errorMessage[0..512], "Error message {d} is too wide!", .{@as(u32, lastErrorCode)});
                moreInfoOnError("In function _refreshRegisterLine:", errorMessage, &errorMessages[lastErrorCode], null);
            }
            abi.fmtBufZ(tmpString[0..2560], "Error message {d} is too wide!", .{@as(u32, lastErrorCode)});
            w_p.* = frontier_char_string.stringWidth(tmpString, &standardFont, true, true);
            _ = showString(tmpString, &standardFont, @intCast(@as(i32, SCREEN_WIDTH) - w_p.*), @intCast(@as(i32, Y_POSITION_OF_REGISTER_X_LINE) - @as(i32, REGISTER_LINE_HEIGHT) * @as(i32, regist - REGISTER_X) + 6), vmNormal, 1, 1);
        }
    } else if (regist == NIM_REGISTER_LINE and calcMode == CM_NIM) {
        if (lastIntegerBase != 0) {
            lastBase[0] = '#';
            if (lastIntegerBase > 9) {
                lastBase[1] = '1';
                lastBase[2] = @intCast('0' + (lastIntegerBase - 10));
                lastBase[3] = 0;
            } else {
                lastBase[1] = @intCast('0' + lastIntegerBase);
                lastBase[2] = 0;
            }
            wLastBaseNumeric_p.* = frontier_char_string.stringWidth(lastBase, &numericFont, true, true);
            wLastBaseStandard_p.* = frontier_char_string.stringWidth(lastBase, &standardFont, true, true);
        } else if (aimBuffer[0] != 0 and aimBuffer[strlen(aimBuffer) - 1] == '/') {
            var lb: [*c]u8 = lastBase;

            var iDigit: u32 = @intFromFloat(pow(10, @floor(log10(@as(f64, @floatFromInt(lastDenominator)))) + 1));
            var iDigit1: u32 = undefined;
            while (iDigit >= 10) {
                iDigit1 = iDigit / 10;
                if (lastDenominator >= iDigit1) {
                    lb[0] = STD_SUB_0[0];
                    lb += 1;
                    lb[0] = @intCast(STD_SUB_0[1] + (lastDenominator % iDigit) / iDigit1);
                    lb += 1;
                }
                iDigit = iDigit1;
            }

            lb[0] = 0;
            lb += 1;
            wLastBaseNumeric_p.* = frontier_char_string.stringWidth(lb, &numericFont, true, true);
            wLastBaseStandard_p.* = frontier_char_string.stringWidth(lb, &standardFont, true, true);
        } else {
            wLastBaseNumeric_p.* = 0;
            wLastBaseStandard_p.* = 0;
        }

        displayBaseMode(regist);
        displayNim(nimBufferDisplay, lastBase, wLastBaseNumeric_p.*, wLastBaseStandard_p.*);
    } else if (regist == AIM_REGISTER_LINE and calcMode == CM_AIM and tam.mode == 0) {
        // TEXT_MULTILINE_EDIT
        const tmplen: i16 = @intCast(stringByteLength(aimBuffer));
        if (T_cursorPos > tmplen) {
            T_cursorPos = tmplen;
        }
        if (T_cursorPos < 0) {
            T_cursorPos = tmplen;
        }
        _ = showStringEdC47(multiEdLines, displayAIMbufferoffset, T_cursorPos, aimBuffer, 1, @intCast(@as(i32, Y_POSITION_OF_NIM_LINE) - 3 - hp), vmNormal, 1, 1, 0);

        if (T_cursorPos == tmplen) {
            cursorEnabled = 1;
        } else {
            cursorEnabled = 0;
        }
        if (combinationFonts == 2) {
            cursorFont = &numericFont;
        } else {
            cursorFont = &standardFont;
        }
    }
    // Main type dtReal34 FLAG_FRACT
    else if (getSystemFlag(FLAG_FRACT) != 0 and (getRegisterDataType(regist) == dtReal34 and (real34CompareAbsLessThan(REGISTER_REAL34_DATA(regist), const34_1e6) != 0 or real34IsZero(REGISTER_REAL34_DATA(regist))))) {
        if (temporaryInformation == TI_VIEW_REGISTER and origRegist == REGISTER_T) {
            viewRegName(prefix, prefixWidth_p);
        } else if (temporaryInformation == TI_VIEW_REGISTER) {
            userTI(@intCast(currentViewRegister), regist, prefix, prefixWidth_p);
        }

        frontier_display.fractionToDisplayString(regist, tmpString);

        w_p.* = frontier_char_string.stringWidth(tmpString, &numericFont, false, true);
        lineWidth_p.* = @intCast(w_p.*);

        if (prefixWidth_p.* > 0) {
            if (temporaryInformation == TI_INTEGRAL and regist == REGISTER_X) {
                _ = showString(prefix, &numericFont, 1, @intCast(@as(i32, baseY) - hp), vmNormal, prefixPre, prefixPost);
            } else {
                _ = showString(prefix, &standardFont, 1, @intCast(@as(i32, baseY) - hp + TEMPORARY_INFO_OFFSET), vmNormal, prefixPre, prefixPost);
            }
        }

        if (w_p.* <= SCREEN_WIDTH) {
            _ = showString(tmpString, &numericFont, @intCast(@as(i32, SCREEN_WIDTH) - w_p.*), @intCast(@as(i32, baseY) - hp), vmNormal, 0, 1);
        } else {
            w_p.* = frontier_char_string.stringWidth(tmpString, &standardFont, false, true);
            lineWidth_p.* = @intCast(w_p.*);
            if (w_p.* > SCREEN_WIDTH) {
                if (comptime extra_info) {
                    moreInfoOnError("In function _refreshRegisterLine:", "Fraction representation too wide!", tmpString, null);
                }
                _ = strcpy(tmpString, "Fraction representation too wide!");
                w_p.* = frontier_char_string.stringWidth(tmpString, &standardFont, false, true);
                lineWidth_p.* = @intCast(w_p.*);
            }
            _ = showString(tmpString, &standardFont, @intCast(@as(i32, SCREEN_WIDTH) - w_p.*), @bitCast(@as(i32, baseY)), vmNormal, 0, 1);
        }
    }
    // Main type dtReal34
    else if (getRegisterDataType(regist) == dtReal34) {
        refreshReal34(regist, origRegist, baseY, prefix, prefixWidth_p, lineWidth_p, w_p, prefixPre, prefixPost, hp);
    }
    // Main type dtComplex34
    else if (getRegisterDataType(regist) == dtComplex34) {
        refreshComplex34(regist, origRegist, baseY, prefix, prefixWidth_p, lineWidth_p, w_p, prefixPre, prefixPost, hp);
    }
    // Main type dtString
    else if (getRegisterDataType(regist) == dtString) {
        refreshString(regist, origRegist, baseY, prefix, prefixWidth_p, lineWidth_p, w_p, prefixPre, prefixPost, hp);
    }
    // Main type dtShortInteger
    else if (getRegisterDataType(regist) == dtShortInteger) {
        refreshShortInteger(regist, origRegist, baseY, prefix, prefixWidth_p, w_p, prefixPre, prefixPost, hp);
    }
    // Main type dtLongInteger
    else if (getRegisterDataType(regist) == dtLongInteger) {
        refreshLongInteger(regist, origRegist, baseY, prefix, prefixWidth_p, lineWidth_p, w_p, prefixPre, prefixPost, hp);
    }
    // Main type dtTime
    else if (getRegisterDataType(regist) == dtTime) {
        if (temporaryInformation == TI_COPY_FROM_SHOW and regist == REGISTER_X) {
            _fnShowRecallTI(prefix, prefixWidth_p);
        } else if (temporaryInformation == TI_VIEW_REGISTER and origRegist == REGISTER_T) {
            viewRegName(prefix, prefixWidth_p);
        } else if (temporaryInformation == TI_VIEW_REGISTER) {
            userTI(@intCast(currentViewRegister), regist, prefix, prefixWidth_p);
        }
        frontier_display.timeToDisplayString(regist, tmpString, 0);
        w_p.* = frontier_char_string.stringWidth(tmpString, &numericFont, false, true);
        if (prefixWidth_p.* > 0) {
            _ = showString(prefix, &standardFont, 1, @intCast(@as(i32, baseY) + TEMPORARY_INFO_OFFSET), vmNormal, prefixPre, prefixPost);
        }
        _ = showString(tmpString, &numericFont, @intCast(if (temporaryInformation == TI_VIEW_REGISTER and origRegist == REGISTER_T) @as(i32, prefixWidth_p.*) else @as(i32, SCREEN_WIDTH) - w_p.*), @intCast(@as(i32, baseY) - hp), vmNormal, 0, 1);
    }
    // Main type dtDate
    else if (getRegisterDataType(regist) == dtDate) {
        if (temporaryInformation == TI_COPY_FROM_SHOW and regist == REGISTER_X) {
            _fnShowRecallTI(prefix, prefixWidth_p);
        } else if (temporaryInformation != TI_VIEW_REGISTER) {
            if (regist >= REGISTER_X and regist <= REGISTER_T) {
                if (!(temporaryInformation == TI_NO_INFO and currentInputVariable != INVALID_VARIABLE) or regist != REGISTER_X) {
                    prefix[0] = 0;
                }
                if (isShiftOffset() and regist == REGISTER_T) {
                    _ = strcpy(prefix, "  ");
                }
                _ = strcat(prefix, &nameOfWday_en[@intCast(frontier_date_time.getJulianDayOfWeek(regist))].itemName);
                prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
            }
        } else if (temporaryInformation == TI_VIEW_REGISTER and origRegist == REGISTER_T) {
            viewRegName(prefix, prefixWidth_p);
            _ = strcat(prefix, &nameOfWday_en[@intCast(frontier_date_time.getJulianDayOfWeek(regist))].itemName);
            _ = strcat(prefix, " ");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        } else if (temporaryInformation == TI_VIEW_REGISTER) {
            userTI(@intCast(currentViewRegister), regist, prefix, prefixWidth_p);
        }

        frontier_display.dateToDisplayString(regist, tmpString);
        w_p.* = frontier_char_string.stringWidth(tmpString, &numericFont, false, true);
        if (prefixWidth_p.* > 0) {
            _ = showString(prefix, &standardFont, 1, @intCast(@as(i32, baseY) + TEMPORARY_INFO_OFFSET), vmNormal, prefixPre, prefixPost);
        }
        _ = showString(tmpString, &numericFont, @intCast(if (temporaryInformation == TI_VIEW_REGISTER and origRegist == REGISTER_T) @as(i32, prefixWidth_p.*) else @as(i32, SCREEN_WIDTH) - w_p.*), @intCast(@as(i32, baseY) - hp), vmNormal, 0, 1);
    }
    // Main type dtConfig
    else if (getRegisterDataType(regist) == dtConfig) {
        if (temporaryInformation == TI_COPY_FROM_SHOW and regist == REGISTER_X) {
            _fnShowRecallTI(prefix, prefixWidth_p);
        }
        if (temporaryInformation == TI_VIEW_REGISTER and origRegist == REGISTER_T) {
            viewRegName(prefix, prefixWidth_p);
        } else if (temporaryInformation == TI_VIEW_REGISTER) {
            userTI(@intCast(currentViewRegister), regist, prefix, prefixWidth_p);
        }
        _ = frontier_char_string.xcopy(tmpString, "Configuration data", 19);
        w_p.* = frontier_char_string.stringWidth(tmpString, &numericFont, false, true);
        lineWidth_p.* = @intCast(w_p.*);
        if (prefixWidth_p.* > 0) {
            _ = showString(prefix, &standardFont, 1, @intCast(@as(i32, baseY) + TEMPORARY_INFO_OFFSET), vmNormal, prefixPre, prefixPost);
        }
        _ = showString(tmpString, &numericFont, @intCast(if (temporaryInformation == TI_VIEW_REGISTER and origRegist == REGISTER_T) @as(i32, prefixWidth_p.*) else @as(i32, SCREEN_WIDTH) - w_p.*), @intCast(@as(i32, baseY) - hp), vmNormal, 0, 1);
    }
    // Main type dtReal34Matrix
    else if (getRegisterDataType(regist) == dtReal34Matrix) {
        refreshRealMatrix(regist, origRegist, baseY, prefix, prefixWidth_p, lineWidth_p, w_p, prefixPre, prefixPost);
    }
    // Main type dtComplex34Matrix
    else if (getRegisterDataType(regist) == dtComplex34Matrix) {
        refreshComplexMatrix(regist, origRegist, baseY, prefix, prefixWidth_p, lineWidth_p, w_p, prefixPre, prefixPost);
    } else {
        abi.fmtBufZ(tmpString[0..2560], "Displaying {s}: to be coded!", .{std.mem.span(frontier_debug.getRegisterDataTypeName(regist, true, false))});
        _ = showString(tmpString, &standardFont, @intCast(@as(i32, SCREEN_WIDTH) - frontier_char_string.stringWidth(tmpString, &standardFont, false, true)), @intCast(@as(i32, baseY) + 6), vmNormal, 0, 1);
    }
}

// dtReal34 prefix builder + render.
const compact_real = {};
fn refreshReal34(regist: calcRegister_t, origRegist: calcRegister_t, baseY: i16, prefix: [*c]u8, prefixWidth_p: *i16, lineWidth_p: *i16, w_p: *i32, prefixPre: bool_t, prefixPost: bool_t, hp: i32) void {
    if (temporaryInformation == TI_COPY_FROM_SHOW and regist == REGISTER_X) {
        _fnShowRecallTI(prefix, prefixWidth_p);
    } else if (temporaryInformation == TI_THETA_RADIUS) {
        if (regist == REGISTER_Y) {
            _ = strcpy(prefix, "r =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        } else if (regist == REGISTER_X) {
            _ = strcpy(prefix, STD_theta_m ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_RADIUS_THETA) {
        if (regist == REGISTER_X) {
            _ = strcpy(prefix, "r =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        } else if (regist == REGISTER_Y) {
            _ = strcpy(prefix, STD_theta_m ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_RADIUS_THETA_SWAPPED) {
        if (regist == REGISTER_Y) {
            _ = strcpy(prefix, "r =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        } else if (regist == REGISTER_X) {
            _ = strcpy(prefix, STD_theta_m ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_PERC) {
        if (regist == REGISTER_X) {
            _ = strcpy(prefix, " % :");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_PERCD) {
        if (regist == REGISTER_X) {
            _ = strcpy(prefix, STD_DELTA ++ "% :");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_PERCD2) {
        if (regist == REGISTER_Y) {
            _ = strcpy(prefix, " % :");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
        if (regist == REGISTER_X) {
            _ = strcpy(prefix, STD_DELTA ++ "% :");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_X_Y) {
        if (regist == REGISTER_X) {
            _ = strcpy(prefix, "x : Re =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        } else if (regist == REGISTER_Y) {
            _ = strcpy(prefix, "y : Im =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_X_Y_SWAPPED) {
        if (regist == REGISTER_Y) {
            _ = strcpy(prefix, "x : Re =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        } else if (regist == REGISTER_X) {
            _ = strcpy(prefix, "y : Im =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_RE_IM) {
        if (regist == REGISTER_X) {
            _ = strcpy(prefix, "Im" ++ STD_SPACE_FIGURE ++ "=");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        } else if (regist == REGISTER_Y) {
            _ = strcpy(prefix, "Re" ++ STD_SPACE_FIGURE ++ "=");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_SUMX_SUMY) {
        if (regist == REGISTER_X) {
            _ = strcpy(prefix, STD_SIGMA ++ "x =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        } else if (regist == REGISTER_Y) {
            _ = strcpy(prefix, STD_SIGMA ++ "y =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_XMIN_YMIN) {
        if (regist == REGISTER_X) {
            _ = strcpy(prefix, "x" ++ STD_SUB_m ++ STD_SUB_i ++ STD_SUB_n ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        } else if (regist == REGISTER_Y) {
            _ = strcpy(prefix, "y" ++ STD_SUB_m ++ STD_SUB_i ++ STD_SUB_n ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_XMAX_YMAX) {
        if (regist == REGISTER_X) {
            _ = strcpy(prefix, "x" ++ STD_SUB_m ++ STD_SUB_a ++ STD_SUB_x ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        } else if (regist == REGISTER_Y) {
            _ = strcpy(prefix, "y" ++ STD_SUB_m ++ STD_SUB_a ++ STD_SUB_x ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_SA) {
        if (regist == REGISTER_X) {
            _ = strcpy(prefix, "s(a" ++ STD_SUB_0 ++ ") =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        } else if (regist == REGISTER_Y) {
            _ = strcpy(prefix, "s(a" ++ STD_SUB_1 ++ ") =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_MEANX_MEANY or temporaryInformation == TI_MEANX) {
        if (regist == REGISTER_X) {
            _ = strcpy(prefix, STD_x_BAR ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        } else if (regist == REGISTER_Y and temporaryInformation != TI_MEANX) {
            _ = strcpy(prefix, STD_y_BAR ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_PCTILEX_PCTILEY) {
        if (regist == REGISTER_X) {
            _ = strcpy(prefix, "pctile" ++ STD_SUB_x ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        } else if (regist == REGISTER_Y) {
            _ = strcpy(prefix, "pctile" ++ STD_SUB_y ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_MEDIANX_MEDIANY) {
        if (regist == REGISTER_X) {
            _ = strcpy(prefix, "md" ++ STD_SUB_x ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        } else if (regist == REGISTER_Y) {
            _ = strcpy(prefix, "md" ++ STD_SUB_y ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_Q1X_Q1Y) {
        if (regist == REGISTER_X) {
            _ = strcpy(prefix, "Q" ++ STD_SUB_1 ++ STD_SPACE_3_PER_EM ++ STD_SUB_x ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        } else if (regist == REGISTER_Y) {
            _ = strcpy(prefix, "Q" ++ STD_SUB_1 ++ STD_SPACE_3_PER_EM ++ STD_SUB_y ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_Q3X_Q3Y) {
        if (regist == REGISTER_X) {
            _ = strcpy(prefix, "Q" ++ STD_SUB_3 ++ STD_SPACE_3_PER_EM ++ STD_SUB_x ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        } else if (regist == REGISTER_Y) {
            _ = strcpy(prefix, "Q" ++ STD_SUB_3 ++ STD_SPACE_3_PER_EM ++ STD_SUB_y ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_MADX_MADY) {
        if (regist == REGISTER_X) {
            _ = strcpy(prefix, "mad" ++ STD_SUB_x ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        } else if (regist == REGISTER_Y) {
            _ = strcpy(prefix, "mad" ++ STD_SUB_y ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_IQRX_IQRY) {
        if (regist == REGISTER_X) {
            _ = strcpy(prefix, "iqr" ++ STD_SUB_x ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        } else if (regist == REGISTER_Y) {
            _ = strcpy(prefix, "iqr" ++ STD_SUB_y ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_RANGEX_RANGEY) {
        if (regist == REGISTER_X) {
            _ = strcpy(prefix, "rg" ++ STD_SUB_x ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        } else if (regist == REGISTER_Y) {
            _ = strcpy(prefix, "rg" ++ STD_SUB_y ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_SAMPLSTDDEV) {
        if (regist == REGISTER_X) {
            _ = strcpy(prefix, "s" ++ STD_SUB_x ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        } else if (regist == REGISTER_Y) {
            _ = strcpy(prefix, "s" ++ STD_SUB_y ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_POPLSTDDEV) {
        if (regist == REGISTER_X) {
            _ = strcpy(prefix, STD_sigma ++ STD_SUB_x ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        } else if (regist == REGISTER_Y) {
            _ = strcpy(prefix, STD_sigma ++ STD_SUB_y ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_STDERR) {
        if (regist == REGISTER_X) {
            _ = strcpy(prefix, "s" ++ STD_SUB_m ++ STD_SUB_x ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        } else if (regist == REGISTER_Y) {
            _ = strcpy(prefix, "s" ++ STD_SUB_m ++ STD_SUB_y ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_GEOMMEANX_GEOMMEANY) {
        if (regist == REGISTER_X) {
            _ = strcpy(prefix, STD_x_BAR ++ STD_SUB_G ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        } else if (regist == REGISTER_Y) {
            _ = strcpy(prefix, STD_y_BAR ++ STD_SUB_G ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_GEOMSAMPLSTDDEV) {
        if (regist == REGISTER_X) {
            _ = strcpy(prefix, STD_epsilon ++ STD_SUB_x ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        } else if (regist == REGISTER_Y) {
            _ = strcpy(prefix, STD_epsilon ++ STD_SUB_y ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_GEOMPOPLSTDDEV) {
        if (regist == REGISTER_X) {
            _ = strcpy(prefix, STD_epsilon ++ STD_SUB_p ++ STD_SUB_x ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        } else if (regist == REGISTER_Y) {
            _ = strcpy(prefix, STD_epsilon ++ STD_SUB_p ++ STD_SUB_y ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_GEOMSTDERR) {
        if (regist == REGISTER_X) {
            _ = strcpy(prefix, STD_epsilon ++ STD_SUB_m ++ STD_SUB_x ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        } else if (regist == REGISTER_Y) {
            _ = strcpy(prefix, STD_epsilon ++ STD_SUB_m ++ STD_SUB_y ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_WEIGHTEDMEANX) {
        if (regist == REGISTER_X) {
            _ = strcpy(prefix, STD_x_BAR ++ STD_SUB_w ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_WEIGHTEDSAMPLSTDDEV) {
        if (regist == REGISTER_X) {
            _ = strcpy(prefix, "s" ++ STD_SUB_w ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_WEIGHTEDPOPLSTDDEV) {
        if (regist == REGISTER_X) {
            _ = strcpy(prefix, STD_sigma ++ STD_SUB_w ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_WEIGHTEDSTDERR) {
        if (regist == REGISTER_X) {
            _ = strcpy(prefix, "s" ++ STD_SUB_m ++ STD_SUB_w ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_STATISTIC_HISTO) {
        if (regist == REGISTER_X) {
            _ = strcpy(prefix, STD_UP_ARROW ++ "BIN" ++ STD_SPACE_FIGURE ++ ":");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        } else if (regist == REGISTER_Y) {
            _ = strcpy(prefix, STD_DOWN_ARROW ++ "BIN" ++ STD_SPACE_FIGURE ++ ":");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        } else if (regist == REGISTER_Z) {
            _ = strcpy(prefix, "nBINS" ++ STD_SPACE_FIGURE ++ ":");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_ROOTS3) {
        if (regist == REGISTER_X or regist == REGISTER_Y or regist == REGISTER_Z) {
            _ = strcpy(prefix, "Root" ++ STD_SPACE_FIGURE ++ ":");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_ROOTS2) {
        if (regist == REGISTER_X or regist == REGISTER_Y) {
            _ = strcpy(prefix, "Root" ++ STD_SPACE_FIGURE ++ ":");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_LR_A0) {
        if (regist == REGISTER_X) {
            displayLRtemporaryInformation("y" ++ STD_SPACE_4_PER_EM ++ "=" ++ STD_SPACE_4_PER_EM, ":" ++ STD_SPACE_4_PER_EM, prefix, "a" ++ STD_SUB_0, prefixPre, prefixPost, prefixWidth_p);
        }
    } else if (temporaryInformation == TI_LR_A1) {
        if (regist == REGISTER_X) {
            displayLRtemporaryInformation("y" ++ STD_SPACE_4_PER_EM ++ "=" ++ STD_SPACE_4_PER_EM, ":" ++ STD_SPACE_4_PER_EM, prefix, "a" ++ STD_SUB_1, prefixPre, prefixPost, prefixWidth_p);
        }
    } else if (temporaryInformation == TI_LR_A2) {
        if (regist == REGISTER_X) {
            displayLRtemporaryInformation("y" ++ STD_SPACE_4_PER_EM ++ "=" ++ STD_SPACE_4_PER_EM, ":" ++ STD_SPACE_4_PER_EM, prefix, "a" ++ STD_SUB_2, prefixPre, prefixPost, prefixWidth_p);
        }
    }
    // L.R. Display
    else if (temporaryInformation == TI_LR and lrChosen != 0) {
        const lprefixPre: bool_t = 0;
        const lprefixPost: bool_t = 0;
        if (lrChosen == CF_CAUCHY_FITTING or lrChosen == CF_GAUSS_FITTING or lrChosen == CF_PARABOLIC_FITTING) {
            if (regist == REGISTER_X) {
                displayLRtemporaryInformation("", "", prefix, "a" ++ STD_SUB_0, lprefixPre, lprefixPost, prefixWidth_p);
            } else if (regist == REGISTER_Y) {
                _ = strcpy(prefix, "y" ++ STD_SPACE_4_PER_EM ++ "=" ++ STD_SPACE_4_PER_EM);
                while (frontier_char_string.stringWidth(prefix, &standardFont, lprefixPre != 0, lprefixPost != 0) + 1 < LRWidth) {
                    _ = strcat(prefix, STD_SPACE_6_PER_EM);
                }
                _ = strcat(prefix, "a" ++ STD_SUB_1 ++ STD_SPACE_4_PER_EM ++ "=" ++ STD_SPACE_HAIR);
                prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, lprefixPre != 0, lprefixPost != 0) + 1;
            } else if (regist == REGISTER_Z) {
                _ = strcpy(prefix, frontier_debug.eatSpacesEnd(frontier_debug.getCurveFitModeName(lrChosen)));
                if (frontier_curve_fitting.lrCountOnes(lrSelection) > 1) {
                    _ = strcat(prefix, if (lrChosen == 0) @as([*c]const u8, "") else STD_SUP_ASTERISK);
                }
                while (frontier_char_string.stringWidth(prefix, &standardFont, lprefixPre != 0, lprefixPost != 0) + 1 < LRWidth) {
                    _ = strcat(prefix, STD_SPACE_6_PER_EM);
                }
                _ = strcat(prefix, "a" ++ STD_SUB_2 ++ STD_SPACE_4_PER_EM ++ "=" ++ STD_SPACE_HAIR);
                prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, lprefixPre != 0, lprefixPost != 0) + 1;
            }
        } else {
            if (regist == REGISTER_X) {
                displayLRtemporaryInformation("y" ++ STD_SPACE_4_PER_EM ++ "=" ++ STD_SPACE_4_PER_EM, "", prefix, "a" ++ STD_SUB_0, lprefixPre, lprefixPost, prefixWidth_p);
            } else if (regist == REGISTER_Y) {
                _ = strcpy(prefix, frontier_debug.eatSpacesEnd(frontier_debug.getCurveFitModeName(lrChosen)));
                if (frontier_curve_fitting.lrCountOnes(lrSelection) > 1) {
                    _ = strcat(prefix, if (lrChosen == 0) @as([*c]const u8, "") else STD_SUP_ASTERISK);
                }
                while (frontier_char_string.stringWidth(prefix, &standardFont, lprefixPre != 0, lprefixPost != 0) + 1 < LRWidth) {
                    _ = strcat(prefix, STD_SPACE_6_PER_EM);
                }
                _ = strcat(prefix, "a" ++ STD_SUB_1 ++ STD_SPACE_4_PER_EM ++ "=" ++ STD_SPACE_HAIR);
                prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, lprefixPre != 0, lprefixPost != 0) + 1;
            }
        }
    } else if (temporaryInformation == TI_CALCY) {
        if (regist == REGISTER_X) {
            prefix[0] = 0;
            if (lrChosen != 0) {
                _ = strcpy(prefix, frontier_debug.eatSpacesEnd(frontier_debug.getCurveFitModeName(lrChosen)));
                if (frontier_curve_fitting.lrCountOnes(lrSelection) > 1) {
                    _ = strcat(prefix, STD_SUP_ASTERISK);
                }
                _ = strcat(prefix, STD_SPACE_FIGURE);
            }
            _ = strcat(prefix, STD_y_CIRC ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, false, false) + 1;
        }
    } else if (temporaryInformation == TI_CALCX) {
        if (regist == REGISTER_X) {
            prefix[0] = 0;
            if (lrChosen != 0) {
                _ = strcpy(prefix, frontier_debug.eatSpacesEnd(frontier_debug.getCurveFitModeName(lrChosen)));
                if (frontier_curve_fitting.lrCountOnes(lrSelection) > 1) {
                    _ = strcat(prefix, STD_SUP_ASTERISK);
                }
                _ = strcat(prefix, STD_SPACE_FIGURE);
            }
            _ = strcat(prefix, STD_x_CIRC ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, false, false) + 1;
        }
    } else if (temporaryInformation == TI_CALCX2) {
        if (regist == REGISTER_X) {
            prefix[0] = 0;
            if (lrChosen != 0) {
                _ = strcpy(prefix, frontier_debug.eatSpacesEnd(frontier_debug.getCurveFitModeName(lrChosen)));
                if (frontier_curve_fitting.lrCountOnes(lrSelection) > 1) {
                    _ = strcat(prefix, STD_SUP_ASTERISK);
                }
                _ = strcat(prefix, STD_SPACE_FIGURE);
            }
            _ = strcat(prefix, STD_x_CIRC ++ STD_SUB_1 ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, false, false) + 1;
        } else {
            if (regist == REGISTER_Y) {
                prefix[0] = 0;
                if (lrChosen != 0) {
                    _ = strcpy(prefix, frontier_debug.eatSpacesEnd(frontier_debug.getCurveFitModeName(lrChosen)));
                    if (frontier_curve_fitting.lrCountOnes(lrSelection) > 1) {
                        _ = strcat(prefix, STD_SUP_ASTERISK);
                    }
                    _ = strcat(prefix, STD_SPACE_FIGURE);
                }
                _ = strcat(prefix, STD_x_CIRC ++ STD_SUB_2 ++ " =");
                prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, false, false) + 1;
            }
        }
    } else if (temporaryInformation == TI_CORR) {
        if (regist == REGISTER_X) {
            prefix[0] = 0;
            if (lrChosen != 0) {
                _ = strcpy(prefix, frontier_debug.eatSpacesEnd(frontier_debug.getCurveFitModeName(lrChosen)));
                if (frontier_curve_fitting.lrCountOnes(lrSelection) > 1) {
                    _ = strcat(prefix, STD_SUP_ASTERISK);
                }
                _ = strcat(prefix, STD_SPACE_FIGURE);
            }
            _ = strcat(prefix, "r =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, false, false) + 1;
        }
    } else if (temporaryInformation == TI_SMI) {
        if (regist == REGISTER_X) {
            _ = strcpy(prefix, "s" ++ STD_SUB_m ++ STD_SUB_i ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, false, false) + 1;
        }
    } else if (temporaryInformation == TI_HARMMEANX_HARMMEANY) {
        if (regist == REGISTER_X) {
            _ = strcpy(prefix, STD_x_BAR ++ STD_SUB_H ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        } else if (regist == REGISTER_Y) {
            _ = strcpy(prefix, STD_y_BAR ++ STD_SUB_H ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_RMSMEANX_RMSMEANY) {
        if (regist == REGISTER_X) {
            _ = strcpy(prefix, STD_x_BAR ++ STD_SUB_R ++ STD_SUB_M ++ STD_SUB_S ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        } else if (regist == REGISTER_Y) {
            _ = strcpy(prefix, STD_y_BAR ++ STD_SUB_R ++ STD_SUB_M ++ STD_SUB_S ++ " =");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_STATISTIC_SUMS) {
        _displaySigmaPlus(regist, prefix, prefixWidth_p, @intFromBool(noLine == 0));
    } else if (temporaryInformation == TI_STATISTIC_LR) {
        if (regist == REGISTER_X) {
            if (orOrtho(lrSelection) == CF_ORTHOGONAL_FITTING) {
                abi.fmtCStr(prefix, "L.R. selected to OrthoF", .{});
            } else {
                abi.fmtCStr(prefix, "L.R. selected to {d:0>3}", .{@as(c_uint, lrSelection & 0x01FF)});
            }
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_SOLVER_VARIABLE_RESULT) {
        _displaySolverOutput(regist, prefix, prefixWidth_p);
    } else if (temporaryInformation == TI_SOLVER_VARIABLE) {
        _displaySolverInput(regist, prefix, prefixWidth_p);
    } else if (temporaryInformation == TI_ELLIPSE_K) {
        if (regist == REGISTER_X) {
            abi.fmtCStr(prefix, "eccentricity e=k=" ++ STD_SQUARE_ROOT ++ "m" ++ STD_SPACE_FIGURE ++ ":", .{});
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_ELLIPSE_M) {
        if (regist == REGISTER_X) {
            abi.fmtCStr(prefix, "modulus m=k" ++ STD_SUP_2 ++ STD_SPACE_FIGURE ++ ":", .{});
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_ELLIPSE_Theta) {
        if (regist == REGISTER_X) {
            abi.fmtCStr(prefix, "eccentricity angle " ++ STD_theta_m ++ STD_SPACE_FIGURE ++ ":", .{});
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_ACC) {
        if (regist == REGISTER_X) {
            abi.fmtCStr(prefix, "ACC" ++ STD_SPACE_FIGURE ++ ":", .{});
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_ULIM) {
        if (regist == REGISTER_X) {
            abi.fmtCStr(prefix, STD_UP_ARROW ++ " Upper limit" ++ STD_SPACE_FIGURE ++ ":", .{});
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_LLIM) {
        if (regist == REGISTER_X) {
            abi.fmtCStr(prefix, STD_DOWN_ARROW ++ " Lower limit" ++ STD_SPACE_FIGURE ++ ":", .{});
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_INTEGRAL) {
        if (regist == REGISTER_X) {
            abi.fmtCStr(prefix, STD_INTEGRAL ++ STD_ALMOST_EQUAL, .{});
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &numericFont, true, true) + 1;
        } else if (regist == REGISTER_Y) {
            _ = strcpy(prefix, "Accuracy " ++ STD_ALMOST_EQUAL);
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_FUNCTION) {
        if (regist == REGISTER_X) {
            abi.fmtCStr(prefix, "f =", .{});
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_1ST_DERIVATIVE) {
        if (regist == REGISTER_X) {
            abi.fmtCStr(prefix, "{s}f'" ++ STD_ALMOST_EQUAL, .{@as([*:0]const u8, errorMessage)});
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_2ND_DERIVATIVE) {
        if (regist == REGISTER_X) {
            abi.fmtCStr(prefix, "{s}f\"" ++ STD_ALMOST_EQUAL, .{@as([*:0]const u8, errorMessage)});
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_VIEW_REGISTER and origRegist == REGISTER_T) {
        viewRegName(prefix, prefixWidth_p);
    } else if (temporaryInformation == TI_VIEW_REGISTER) {
        userTI(@intCast(currentViewRegister), regist, prefix, prefixWidth_p);
    } else if (temporaryInformation == TI_CONV_MENU_STR and regist == REGISTER_X) {
        _ = strcpy(prefix, " ");
        _ = strcat(prefix, errorMessage);
        _ = strcat(prefix, ":");
        prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
    } else if (temporaryInformation == TI_ABC or temporaryInformation == TI_ABBCCA or temporaryInformation == TI_012) {
        elecTI(regist, prefix, prefixWidth_p);
    } else if (temporaryInformation == TI_FROM_DMS) {
        if (regist == REGISTER_X) {
            _ = strcpy(prefix, "decimal" ++ STD_DEGREE ++ ":");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_FROM_HMS) {
        if (regist == REGISTER_X) {
            _ = strcpy(prefix, "decimal h:");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_FROM_MS_TIME) {
        if (regist == REGISTER_X) {
            _ = strcpy(prefix, "hh.mmss:");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_FROM_MS_DEG) {
        if (regist == REGISTER_X) {
            _ = strcpy(prefix, "dd.mmss:");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (option_tvm_amort and temporaryInformation == TI_AMORT_BAL and regist == REGISTER_X) {
        _ = strcpy(prefix, "Balance remaining =");
        prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
    } else if (option_tvm_amort and temporaryInformation == TI_AMORT_PRN and regist == REGISTER_X) {
        abi.fmtCStr(prefix, "{s}", .{STD_SIGMA});
        _ = strcat(prefix, " of principal to P2 =");
        prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
    } else if (option_tvm_amort and temporaryInformation == TI_AMORT_INT and regist == REGISTER_X) {
        abi.fmtCStr(prefix, "{s}", .{STD_SIGMA});
        _ = strcat(prefix, " of interest to P2 =");
        prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
    } else if (option_tvm_amort and temporaryInformation == TI_AMORT_P1 and regist == REGISTER_X) {
        _ = strcpy(prefix, "From period P1:");
        prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
    } else if (option_tvm_amort and temporaryInformation == TI_AMORT_P2 and regist == REGISTER_X) {
        _ = strcpy(prefix, "To period P2:");
        prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
    } else if (temporaryInformation == TI_TVM_EFF and regist == REGISTER_X) {
        _ = strcpy(prefix, "EFF%/a = EFF%YR = EAR =");
        prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
    } else if (temporaryInformation == TI_TVM_IA and regist == REGISTER_X) {
        _ = strcpy(prefix, "I%/a = I%YR = NAR =");
        prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
    } else if (temporaryInformation == TI_FROM_DATEX) {
        if (regist == REGISTER_X) {
            if (getSystemFlag(FLAG_DMY) != 0) {
                _ = strcpy(prefix, "dd.mmyyyy:");
            } else if (getSystemFlag(FLAG_MDY) != 0) {
                _ = strcpy(prefix, "mm.ddyyyy:");
            } else {
                _ = strcpy(prefix, "yyyy.mmdd:");
            }
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_LAST_CONST_CATNAME or temporaryInformation == TI_SCATTER_SMI) {
        if (regist == REGISTER_X) {
            _ = strcpy(prefix, frontier_items.lastFuncSoftmenuName());
            if (prefix[0] != 0) {
                _ = strcat(prefix, " ");
                if (frontier_sort.compareString(frontier_items.lastFuncSoftmenuName(), frontier_items.lastFuncCatalogName(), CMP_BINARY) != 0) {
                    var prefix_: [16]u8 = undefined;
                    prefix_[0] = 0;
                    _ = strcat(&prefix_, frontier_items.lastFuncCatalogName());
                    if (prefix_[0] != 0) {
                        _ = strcat(prefix, &prefix_);
                    }
                }
                if (prefix[0] != 0) {
                    _ = strcat(prefix, " = ");
                }
                prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
            }
        }
    } else if ((regist == REGISTER_X and (temporaryInformation == TI_MIJ or temporaryInformation == TI_MIJEQ)) or ((regist == REGISTER_X or regist == REGISTER_Y) and temporaryInformation == TI_IJ) or (regist == REGISTER_X and (temporaryInformation == TI_I or temporaryInformation == TI_J))) {
        _displayIJ(regist, prefix, prefixWidth_p);
    } else if (temporaryInformation == TI_STORCL and regist == REGISTER_X) {
        viewStoRcl(prefix, prefixWidth_p);
    } else if (temporaryInformation == TI_REGTYPE) {
        _displayRegType(regist, prefix, prefixWidth_p);
    } else if (option_vector and temporaryInformation >= TI_VECTORCOMP_3DSPH and temporaryInformation <= TI_VECTORCOMP_2DRECT) {
        tiVector(regist, prefix, prefixWidth_p, @intFromBool(temporaryInformation != TI_VECTOR));
    }

    if (prefixWidth_p.* > 0 and temporaryInformation != TI_VIEW_REGISTER) {
        if (regist == REGISTER_X) {
            _ = showString(prefix, &standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE + TEMPORARY_INFO_OFFSET, vmNormal, 1, 1);
        } else if (regist == REGISTER_Y) {
            _ = showString(prefix, &standardFont, 1, Y_POSITION_OF_REGISTER_Y_LINE + TEMPORARY_INFO_OFFSET, vmNormal, 1, 1);
        } else if (regist == REGISTER_Z) {
            _ = showString(prefix, &standardFont, 1, Y_POSITION_OF_REGISTER_Z_LINE + TEMPORARY_INFO_OFFSET, vmNormal, 1, 1);
        }
    }

    frontier_display.real34ToDisplayString(REGISTER_REAL34_DATA(regist), @intCast(getRegisterAngularMode(regist)), tmpString, &numericFont, @intCast(@as(i32, SCREEN_WIDTH) - prefixWidth_p.*), NUMBER_OF_DISPLAY_DIGITS, LIMITEXP, FRONTSPACE, FULLIRFRAC);

    w_p.* = frontier_char_string.stringWidth(tmpString, &numericFont, false, true);
    lineWidth_p.* = @intCast(w_p.*);
    if (prefixWidth_p.* > 0) {
        if (temporaryInformation == TI_INTEGRAL and regist == REGISTER_X) {
            _ = showString(prefix, &numericFont, 1, @intCast(@as(i32, baseY) - hp), vmNormal, prefixPre, prefixPost);
        } else {
            _ = showString(prefix, &standardFont, 1, @intCast(@as(i32, baseY) - hp + TEMPORARY_INFO_OFFSET), vmNormal, prefixPre, prefixPost);
        }
    }
    _ = showString(tmpString, &numericFont, @intCast(if (temporaryInformation == TI_VIEW_REGISTER and origRegist == REGISTER_T) @as(i32, prefixWidth_p.*) else @as(i32, SCREEN_WIDTH) - w_p.*), @intCast(@as(i32, baseY) - hp), vmNormal, 0, 1);
}

fn refreshComplex34(regist: calcRegister_t, origRegist: calcRegister_t, baseY: i16, prefix: [*c]u8, prefixWidth_p: *i16, lineWidth_p: *i16, w_p: *i32, prefixPre: bool_t, prefixPost: bool_t, hp: i32) void {
    if (temporaryInformation == TI_COPY_FROM_SHOW and regist == REGISTER_X) {
        _fnShowRecallTI(prefix, prefixWidth_p);
    } else if (temporaryInformation == TI_SOLVER_VARIABLE_RESULT) {
        _displaySolverOutput(regist, prefix, prefixWidth_p);
    } else if (temporaryInformation == TI_SOLVER_VARIABLE) {
        _displaySolverInput(regist, prefix, prefixWidth_p);
    } else if (temporaryInformation == TI_VIEW_REGISTER and origRegist == REGISTER_T) {
        viewRegName(prefix, prefixWidth_p);
    } else if (temporaryInformation == TI_VIEW_REGISTER) {
        userTI(@intCast(currentViewRegister), regist, prefix, prefixWidth_p);
    } else if (temporaryInformation == TI_ABC or temporaryInformation == TI_ABBCCA or temporaryInformation == TI_012) {
        elecTI(regist, prefix, prefixWidth_p);
    } else if (temporaryInformation == TI_ROOTS3) {
        if (regist == REGISTER_X or regist == REGISTER_Y or regist == REGISTER_Z) {
            _ = strcpy(prefix, "Root" ++ STD_SPACE_FIGURE ++ ":");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_ROOTS2) {
        if (regist == REGISTER_X or regist == REGISTER_Y) {
            _ = strcpy(prefix, "Root" ++ STD_SPACE_FIGURE ++ ":");
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if ((regist == REGISTER_X and (temporaryInformation == TI_MIJ or temporaryInformation == TI_MIJEQ)) or ((regist == REGISTER_X or regist == REGISTER_Y) and temporaryInformation == TI_IJ) or (regist == REGISTER_X and (temporaryInformation == TI_I or temporaryInformation == TI_J))) {
        _displayIJ(regist, prefix, prefixWidth_p);
    } else if (temporaryInformation == TI_STORCL and regist == REGISTER_X) {
        viewStoRcl(prefix, prefixWidth_p);
    }

    if (prefixWidth_p.* > 0) {
        if (regist == REGISTER_X) {
            _ = showString(prefix, &standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE + TEMPORARY_INFO_OFFSET, vmNormal, 1, 1);
        } else if (regist == REGISTER_Y) {
            _ = showString(prefix, &standardFont, 1, Y_POSITION_OF_REGISTER_Y_LINE + TEMPORARY_INFO_OFFSET, vmNormal, 1, 1);
        } else if (regist == REGISTER_Z) {
            _ = showString(prefix, &standardFont, 1, Y_POSITION_OF_REGISTER_Z_LINE + TEMPORARY_INFO_OFFSET, vmNormal, 1, 1);
        }
    }
    frontier_display.complex34ToDisplayString(REGISTER_COMPLEX34_DATA(regist), tmpString, &numericFont, @intCast(@as(i32, SCREEN_WIDTH) - prefixWidth_p.*), NUMBER_OF_DISPLAY_DIGITS, LIMITEXP, FRONTSPACE, FULLIRFRAC, @intCast(getComplexRegisterAngularMode(regist)), @intFromBool(getComplexRegisterPolarMode(regist) == amPolar));

    w_p.* = frontier_char_string.stringWidth(tmpString, &numericFont, false, true);
    lineWidth_p.* = @intCast(w_p.*);
    if (prefixWidth_p.* > 0) {
        _ = showString(prefix, &standardFont, 1, @intCast(@as(i32, baseY) + TEMPORARY_INFO_OFFSET), vmNormal, prefixPre, prefixPost);
    }
    _ = showString(tmpString, &numericFont, @intCast(if (temporaryInformation == TI_VIEW_REGISTER and origRegist == REGISTER_T) @as(i32, prefixWidth_p.*) else @as(i32, SCREEN_WIDTH) - w_p.*), @intCast(@as(i32, baseY) - hp), vmNormal, 0, 1);
}

fn refreshString(regist: calcRegister_t, origRegist: calcRegister_t, baseY: i16, prefix: [*c]u8, prefixWidth_p: *i16, lineWidth_p: *i16, w_p: *i32, prefixPre: bool_t, prefixPost: bool_t, hp: i32) void {
    if (temporaryInformation == TI_COPY_FROM_SHOW and regist == REGISTER_X) {
        _fnShowRecallTI(prefix, prefixWidth_p);
    } else if (temporaryInformation == TI_VIEW_REGISTER and origRegist == REGISTER_T) {
        viewRegName(prefix, prefixWidth_p);
    } else if (temporaryInformation == TI_VIEW_REGISTER) {
        userTI(@intCast(currentViewRegister), regist, prefix, prefixWidth_p);
    } else if (temporaryInformation == TI_STORCL and regist == REGISTER_X) {
        viewStoRcl(prefix, prefixWidth_p);
    } else if (temporaryInformation == TI_LASTSTATEFILE) {
        clearRegisterLine(REGISTER_Y, true, false);
        _ = strcpy(prefix, "Last full state file loaded:");
        _ = showString(prefix, &standardFont, 1, Y_POSITION_OF_REGISTER_Y_LINE, vmNormal, prefixPre, prefixPost);
        prefix[0] = 0;
        prefixWidth_p.* = 0;
    } else if (isShiftOffset() and regist == REGISTER_T) {
        _ = strcpy(prefix, "  ");
        prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
    }

    if (prefixWidth_p.* > 0) {
        _ = showString(prefix, &standardFont, 1, @intCast(@as(i32, baseY) + TEMPORARY_INFO_OFFSET), vmNormal, prefixPre, prefixPost);
    }

    // STACK_X_STR_LRG_FONT (live); STACK_X_STR_MED_FONT undef; STACK_STR_MED_FONT (live).
    var w: i16 = @intCast(stringWidthWithLimitC47(REGISTER_STRING_DATA(regist), stdnumEnlarge, nocompress, SCREEN_WIDTH, 0, 1));
    if (temporaryInformation != TI_VIEW_REGISTER and regist == REGISTER_X and w < SCREEN_WIDTH) {
        lineWidth_p.* = w;
        _ = showStringC47(REGISTER_STRING_DATA(regist), stdnumEnlarge, nocompress, @intCast(@as(i32, SCREEN_WIDTH) - w), @intCast(@as(i32, Y_POSITION_OF_REGISTER_X_LINE) + 6 - hp), vmNormal, 0, 1);
    } else if (regist >= REGISTER_Y and regist <= REGISTER_T and blk: {
        w = @intCast(stringWidthWithLimitC47(REGISTER_STRING_DATA(regist), numHalf, nocompress, @intCast(@as(i32, SCREEN_WIDTH) - prefixWidth_p.*), 0, 1));
        break :blk w < SCREEN_WIDTH - prefixWidth_p.*;
    }) {
        lineWidth_p.* = w;
        _ = showStringC47(REGISTER_STRING_DATA(regist), numHalf, nocompress, @intCast(@as(i32, SCREEN_WIDTH) - w), @intCast(@as(i32, baseY) + 6 - hp), vmNormal, 0, 1);
    } else {
        w = frontier_char_string.stringWidth(REGISTER_STRING_DATA(regist), &standardFont, false, true);
        if (w >= SCREEN_WIDTH - prefixWidth_p.*) {
            var tmpStrW: [*c]u8 = undefined;
            if (regist == REGISTER_X or (temporaryInformation == TI_VIEW_REGISTER and origRegist == REGISTER_T)) {
                COPY_REGISTER_STRING_TO(tmpString, regist);
                if (temporaryInformation == TI_VIEW_REGISTER and origRegist == REGISTER_T) {
                    createSubstrings(1);
                }
                tmpStrW = frontier_char_string.stringAfterPixels(tmpString, &standardFont, @intCast(@as(i32, SCREEN_WIDTH) - prefixWidth_p.* - 1), false, true);
                tmpStrW[0] = 0;
                w = frontier_char_string.stringWidth(tmpString, &standardFont, false, true);
                if (temporaryInformation == TI_VIEW_REGISTER and origRegist == REGISTER_T) {
                    _ = showString(tmpString, &standardFont, @intCast(prefixWidth_p.*), Y_POSITION_OF_REGISTER_T_LINE - 3, vmNormal, 0, 1);
                } else {
                    _ = showString(tmpString, &standardFont, @intCast(@as(i32, SCREEN_WIDTH) - w), @intCast(@as(i32, Y_POSITION_OF_REGISTER_X_LINE) - 3 - hp), vmNormal, 0, 1);
                }
                w = @intCast(stringByteLength(tmpString));
                COPY_REGISTER_STRING_TO(tmpString, regist);
                if (temporaryInformation == TI_VIEW_REGISTER and origRegist == REGISTER_T) {
                    createSubstrings(1);
                }
                _ = frontier_char_string.xcopy(tmpString, tmpString + @as(usize, @intCast(w)), @intCast(stringByteLength(tmpString + @as(usize, @intCast(w))) + 1));
                w = frontier_char_string.stringWidth(tmpString, &standardFont, false, true);
                if (w >= SCREEN_WIDTH - prefixWidth_p.*) {
                    tmpStrW = frontier_char_string.stringAfterPixels(tmpString, &standardFont, @intCast(@as(i32, SCREEN_WIDTH) - prefixWidth_p.* - 14 - 1), false, true);
                    _ = frontier_char_string.xcopy(tmpStrW, STD_ELLIPSIS, 3);
                    w = frontier_char_string.stringWidth(tmpString, &standardFont, false, true);
                }
                if (temporaryInformation == TI_VIEW_REGISTER and origRegist == REGISTER_T) {
                    _ = showString(tmpString, &standardFont, @intCast(prefixWidth_p.*), Y_POSITION_OF_REGISTER_T_LINE + 18, vmNormal, 0, 1);
                } else {
                    _ = showString(tmpString, &standardFont, @intCast(@as(i32, SCREEN_WIDTH) - w), @intCast(@as(i32, Y_POSITION_OF_REGISTER_X_LINE) + 18 - hp), vmNormal, 0, 1);
                }
            } else {
                COPY_REGISTER_STRING_TO(tmpString, regist);
                tmpStrW = frontier_char_string.stringAfterPixels(tmpString, &standardFont, @intCast(@as(i32, SCREEN_WIDTH) - prefixWidth_p.* - 14 - 1), false, true);
                _ = frontier_char_string.xcopy(tmpStrW, STD_ELLIPSIS, 3);
                w = frontier_char_string.stringWidth(tmpString, &standardFont, false, true);
                lineWidth_p.* = w;
                _ = showString(tmpString, &standardFont, @intCast(@as(i32, SCREEN_WIDTH) - w), @intCast(@as(i32, baseY) + 6 - hp), vmNormal, 0, 1);
            }
        } else {
            lineWidth_p.* = w;
            COPY_REGISTER_STRING_TO(tmpString, regist);
            if (temporaryInformation == TI_VIEW_REGISTER and origRegist == REGISTER_T) {
                createSubstrings(1);
            }
            if (temporaryInformation == TI_VIEW_REGISTER and origRegist == REGISTER_T) {
                _ = showString(tmpString, &standardFont, @intCast(prefixWidth_p.*), @intCast(@as(i32, baseY) + TEMPORARY_INFO_OFFSET), vmNormal, 0, 1);
            } else {
                _ = showString(tmpString, &standardFont, @intCast(@as(i32, SCREEN_WIDTH) - w), @intCast(@as(i32, baseY) + 6 - hp), vmNormal, 0, 1);
            }
        }
    }
    _ = w_p;
}

fn refreshShortInteger(regist: calcRegister_t, origRegist: calcRegister_t, baseY: i16, prefix: [*c]u8, prefixWidth_p: *i16, w_p: *i32, prefixPre: bool_t, prefixPost: bool_t, hp: i32) void {
    _ = w_p;
    {
        frontier_display.shortIntegerToDisplayString(regist, tmpString, 1, noBaseOverride);
        _ = showString(tmpString, fontForShortInteger.?, @intCast(@as(i32, SCREEN_WIDTH) - frontier_char_string.stringWidth(tmpString, fontForShortInteger.?, false, true)), @intCast(@as(i32, baseY) + (if (fontForShortInteger == &standardFont) @as(i32, 6) else 0) - (if (fontForShortInteger == &numericFont) hp else 0)), vmNormal, 0, 1);

        if (regist == REGISTER_X) {
            displayBaseMode(regist);
            _ = displayTrueFalse(regist);
        }
        if (temporaryInformation == TI_VIEW_REGISTER and origRegist == REGISTER_T) {
            lcd_fill_rect(0, Y_POSITION_OF_REGISTER_T_LINE, 50, REGISTER_LINE_HEIGHT, LCD_SET_VALUE);
        }
    }

    if (!(temporaryInformation == TI_NO_INFO and currentInputVariable != INVALID_VARIABLE)) {
        prefix[0] = 0;
    }
    tmpString[0] = 0;
    if (regist == REGISTER_X and (temporaryInformation == TI_DATA_LOSS or temporaryInformation == TI_DATA_NEG_OVRFL)) {
        frontier_display.shortIntegerToDisplayString(regist, tmpString, 1, noBaseOverride);
        if (temporaryInformation == TI_DATA_LOSS) {
            abi.fmtCStr(prefix, "Ovrfl>{d}bits:", .{@as(c_uint, shortIntegerWordSize)});
        } else if (temporaryInformation == TI_DATA_NEG_OVRFL) {
            abi.fmtCStr(prefix, "Ovrfl<0:", .{});
        }
        prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        if (prefixWidth_p.* + frontier_char_string.stringWidth(tmpString, fontForShortInteger.?, true, true) + 1 > SCREEN_WIDTH) {
            abi.fmtCStr(prefix, "OF", .{});
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (temporaryInformation == TI_VIEW_REGISTER and origRegist == REGISTER_T) {
        viewRegName(prefix, prefixWidth_p);
    } else if (temporaryInformation == TI_VIEW_REGISTER) {
        userTI(@intCast(currentViewRegister), regist, prefix, prefixWidth_p);
    } else if (temporaryInformation == TI_COPY_FROM_SHOW and regist == REGISTER_X) {
        _fnShowRecallTI(prefix, prefixWidth_p);
    } else if (temporaryInformation == TI_STATISTIC_SUMS) {
        _displaySigmaPlus(regist, prefix, prefixWidth_p, @intFromBool(noLine == 0));
    } else if (temporaryInformation == TI_STORCL and regist == REGISTER_X) {
        viewStoRcl(prefix, prefixWidth_p);
    }
    if (prefixWidth_p.* > 0) {
        if (regist == REGISTER_X) {
            _ = showString(prefix, &standardFont, 1, @intCast(@as(i32, baseY) + TEMPORARY_INFO_OFFSET), vmNormal, prefixPre, prefixPost);
        }
        if (tmpString[0] != 0) {
            frontier_display.shortIntegerToDisplayString(regist, tmpString, 1, noBaseOverride);
        }
        _ = showString(tmpString, fontForShortInteger.?, @intCast(@as(i32, SCREEN_WIDTH) - frontier_char_string.stringWidth(tmpString, fontForShortInteger.?, false, true)), @intCast(@as(i32, baseY) + (if (fontForShortInteger == &standardFont) @as(i32, 6) else 0) - (if (fontForShortInteger == &numericFont) hp else 0)), vmNormal, 0, 1);
    }
}

fn refreshLongInteger(regist: calcRegister_t, origRegist: calcRegister_t, baseY: i16, prefix: [*c]u8, prefixWidth_p: *i16, lineWidth_p: *i16, w_p: *i32, prefixPre: bool_t, prefixPost: bool_t, hp: i32) void {
    if (!(temporaryInformation == TI_NO_INFO and currentInputVariable != INVALID_VARIABLE)) {
        prefix[0] = 0;
    }

    if (DBASEMODE()) {
        displayBaseMode(regist);
    }

    if (temporaryInformation == TI_COPY_FROM_SHOW and regist == REGISTER_X) {
        _fnShowRecallTI(prefix, prefixWidth_p);
    } else if (temporaryInformation == TI_SOLVER_VARIABLE) {
        _displaySolverInput(regist, prefix, prefixWidth_p);
    } else if ((regist == REGISTER_X and (temporaryInformation == TI_MIJ or temporaryInformation == TI_MIJEQ)) or ((regist == REGISTER_X or regist == REGISTER_Y) and temporaryInformation == TI_IJ) or (regist == REGISTER_X and (temporaryInformation == TI_I or temporaryInformation == TI_J))) {
        _displayIJ(regist, prefix, prefixWidth_p);
    } else if (temporaryInformation == TI_STORCL and regist == REGISTER_X) {
        viewStoRcl(prefix, prefixWidth_p);
    } else if (temporaryInformation == TI_REGTYPE) {
        _displayRegType(regist, prefix, prefixWidth_p);
    } else if (temporaryInformation == TI_ABC or temporaryInformation == TI_ABBCCA or temporaryInformation == TI_012) {
        elecTI(regist, prefix, prefixWidth_p);
    } else if (temporaryInformation == TI_STATISTIC_SUMS) {
        _displaySigmaPlus(regist, prefix, prefixWidth_p, @intFromBool(noLine == 0));
    } else if (temporaryInformation == TI_VIEW_REGISTER and origRegist == REGISTER_T) {
        viewRegName(prefix, prefixWidth_p);
    } else if (temporaryInformation == TI_VIEW_REGISTER) {
        userTI(@intCast(currentViewRegister), regist, prefix, prefixWidth_p);
    } else if (temporaryInformation == TI_DAY_OF_WEEK) {
        if (regist == REGISTER_X) {
            var day: i32 = undefined;
            var li: longInteger_t = undefined;
            _ = frontier_register_value_conversions.getRegisterAsLongInt(REGISTER_X, &li[0], null);
            longIntegerToInt32(&li, &day);
            longIntegerFree(&li);
            if (day < 1 or day > 7) {
                day = 0;
            }
            _ = strcpy(prefix, "[ISO day] ");
            _ = strcat(prefix, &nameOfWday_en[@intCast(day)].itemName);
            prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
        }
    } else if (option_tvm_amort and temporaryInformation == TI_AMORT_P1 and regist == REGISTER_X) {
        _ = strcpy(prefix, "From period P1:");
        prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
    } else if (option_tvm_amort and temporaryInformation == TI_AMORT_P2 and regist == REGISTER_X) {
        _ = strcpy(prefix, "To period P2:");
        prefixWidth_p.* = frontier_char_string.stringWidth(prefix, &standardFont, true, true) + 1;
    }

    // shift longinteger prefix on by two spaces if interfering with the shift indicator
    if (regist == REGISTER_T and isShiftOffset()) {
        const len: i32 = @intCast(strlen(prefix));
        if (len + 2 < 200) {
            if (prefix[0] == 0) {
                _ = strcpy(prefix, "  ");
                prefixWidth_p.* += 20;
            } else {
                var i: i32 = len;
                while (i >= 0) : (i -= 1) {
                    prefix[@intCast(i + 2)] = prefix[@intCast(i)];
                }
                prefix[0] = ' ';
                prefix[1] = ' ';
                prefixWidth_p.* += 20;
            }
        }
    }

    if (getSystemFlag(FLAG_DREAL) != 0) {
        _ = strcpy(tmpString, STD_INTEGER_Z_SMALL ++ ": ");
        w_p.* = frontier_char_string.stringWidth(tmpString, if (getSystemFlag(FLAG_LARGELI) != 0) &numericFont else &standardFont, false, true);
        const tlen: i16 = @intCast(stringByteLength(tmpString));
        frontier_display.longIntegerRegisterToRealDisplayString(regist, tmpString + @as(usize, @intCast(tlen)), @as(i32, TMP_STR_LENGTH) - tlen, @intCast(@as(i32, SCREEN_WIDTH) - prefixWidth_p.* - w_p.*), 0, toRemoveTrailingRadix);
        tmpString[TMP_STR_LENGTH - 1] = tmpString[@intCast(tlen)];
    } else if (getSystemFlag(FLAG_2TO10) != 0 and displayFormat == DF_UN) {
        _ = strcpy(tmpString, STD_INTEGER_Z_SMALL ++ ": ");
        w_p.* = frontier_char_string.stringWidth(tmpString, &standardFont, false, true);
        const tlen: i16 = @intCast(stringByteLength(tmpString));
        frontier_display.longIntegerRegisterToRealDisplayString(regist, tmpString + @as(usize, @intCast(tlen)), @as(i32, TMP_STR_LENGTH) - tlen, @intCast(@as(i32, SCREEN_WIDTH) - prefixWidth_p.* - w_p.*), 1024, @intFromBool(toRemoveTrailingRadix == 0));
        tmpString[TMP_STR_LENGTH - 1] = tmpString[@intCast(tlen)];
    } else {
        frontier_display.longIntegerRegisterToDisplayString(regist, tmpString, TMP_STR_LENGTH, @intCast(@as(i32, SCREEN_WIDTH) - prefixWidth_p.*), 50, getSystemFlag(FLAG_LARGELI));
        tmpString[TMP_STR_LENGTH - 1] = tmpString[0];
        {
            var pos: u16 = undefined;
            if (frontier_char_string.findTwoChars(tmpString, PRODUCT_SIGN()[0], PRODUCT_SIGN()[1], &pos)) {
                _ = strcpy(tmpString, STD_INTEGER_Z_SMALL ++ ": ");
                w_p.* = frontier_char_string.stringWidth(tmpString, if (getSystemFlag(FLAG_LARGELI) != 0) &numericFont else &standardFont, false, true);
                const tlen: i16 = @intCast(stringByteLength(tmpString));
                const savedDisplayFormat: u8 = displayFormat;
                const savedDisplayFormatDigits: u8 = displayFormatDigits;
                displayFormatDigits = 20;
                displayFormat = DF_SCI;
                frontier_display.longIntegerRegisterToRealDisplayString(regist, tmpString + @as(usize, @intCast(tlen)), @as(i32, TMP_STR_LENGTH) - tlen, @intCast(@as(i32, SCREEN_WIDTH) - prefixWidth_p.* - w_p.*), 0, toRemoveTrailingRadix);
                displayFormat = savedDisplayFormat;
                displayFormatDigits = savedDisplayFormatDigits;
                tmpString[TMP_STR_LENGTH - 1] = tmpString[@intCast(tlen)];
            }
        }
    }

    w_p.* = frontier_char_string.stringWidth(tmpString, &numericFont, false, true);
    lineWidth_p.* = @intCast(w_p.*);
    if (prefixWidth_p.* > 0) {
        _ = showString(prefix, &standardFont, 1, @intCast(@as(i32, baseY) + TEMPORARY_INFO_OFFSET), vmNormal, prefixPre, prefixPost);
    }
    if (w_p.* <= SCREEN_WIDTH) {
        _ = showString(tmpString, &numericFont, @intCast(if (temporaryInformation == TI_VIEW_REGISTER and origRegist == REGISTER_T) @as(i32, prefixWidth_p.*) else @as(i32, SCREEN_WIDTH) - w_p.*), @intCast(@as(i32, baseY) - hp), vmNormal, 0, 1);
    } else {
        w_p.* = frontier_char_string.stringWidth(tmpString, &standardFont, false, true);
        if (w_p.* > SCREEN_WIDTH) {
            if (comptime extra_info) {
                moreInfoOnError("In function _refreshRegisterLine:", "Long integer representation too wide!", tmpString, null);
            }
            _ = strcpy(tmpString, "Long integer representation too wide!");
        }
        w_p.* = frontier_char_string.stringWidth(tmpString, &standardFont, false, true);
        lineWidth_p.* = @intCast(w_p.*);
        _ = showString(tmpString, &standardFont, @intCast(if (temporaryInformation == TI_VIEW_REGISTER and origRegist == REGISTER_T) @as(i32, prefixWidth_p.*) else @as(i32, SCREEN_WIDTH) - w_p.*), @intCast(@as(i32, baseY) + 6), vmNormal, 0, 1);
    }
}

fn refreshRealMatrix(regist: calcRegister_t, origRegist: calcRegister_t, baseY: i16, prefix: [*c]u8, prefixWidth_p: *i16, lineWidth_p: *i16, w_p: *i32, prefixPre: bool_t, prefixPost: bool_t) void {
    const displayVector: bool = (origRegist == REGISTER_X and calcMode != CM_MIM) and temporaryInformation != TI_VIEW_REGISTER and lastErrorCode == 0 and temporaryInformation != TI_MIJ and temporaryInformation != TI_IJ and temporaryInformation != TI_I and temporaryInformation != TI_J and temporaryInformation != TI_STORCL and temporaryInformation != TI_TRUE and temporaryInformation != TI_FALSE;
    if ((origRegist == REGISTER_X and calcMode != CM_MIM) or (temporaryInformation == TI_VIEW_REGISTER and origRegist == REGISTER_T) or displayVector) {
        var matrix: real34Matrix_t = undefined;
        prefixWidth_p.* = 0;
        prefix[0] = 0;
        linkToRealMatrixRegister(regist, &matrix);
        if (temporaryInformation == TI_VIEW_REGISTER and origRegist == REGISTER_T) {
            viewRegName(prefix, prefixWidth_p);
        } else if ((regist == REGISTER_X and (temporaryInformation == TI_MIJ or temporaryInformation == TI_MIJEQ)) or ((regist == REGISTER_X or regist == REGISTER_Y) and temporaryInformation == TI_IJ) or (regist == REGISTER_X and (temporaryInformation == TI_I or temporaryInformation == TI_J))) {
            _displayIJ(regist, prefix, prefixWidth_p);
        } else if (temporaryInformation == TI_STORCL and regist == REGISTER_X) {
            viewStoRcl(prefix, prefixWidth_p);
        } else if (temporaryInformation == TI_VIEW_REGISTER and regist == REGISTER_X) {
            userTI(@intCast(currentViewRegister), regist, prefix, prefixWidth_p);
        } else if (temporaryInformation == TI_STATISTIC_SUMS) {
            _displaySigmaPlus(regist, prefix, prefixWidth_p, noLine);
        } else if (temporaryInformation == TI_NO_INFO and currentInputVariable != INVALID_VARIABLE) {
            inputRegName(prefix, prefixWidth_p);
        } else if (option_vector and displayVector and isRegisterMatrixVector(regist) != 0) {
            tiVector(regist, prefix, prefixWidth_p, @intFromBool(temporaryInformation != TI_VECTOR));
        }

        frontier_matrix_editor.showRealMatrix(&matrix, prefixWidth_p.*, toDisplayVectorMatrix != 0, (!(temporaryInformation == TI_VIEW_REGISTER and origRegist == REGISTER_T)));
        if (lastErrorCode != 0) {
            refreshRegisterLine(errorMessageRegisterLine);
        }
        if (temporaryInformation == TI_TRUE or temporaryInformation == TI_FALSE) {
            refreshRegisterLine(TRUE_FALSE_REGISTER_LINE);
        }
        if (prefixWidth_p.* > 0) {
            _ = showString(prefix, &standardFont, 1, @intCast(@as(i32, baseY) + TEMPORARY_INFO_OFFSET), vmNormal, prefixPre, prefixPost);
        }
    } else {
        if (temporaryInformation == TI_VIEW_REGISTER) {
            userTI(@intCast(currentViewRegister), regist, prefix, prefixWidth_p);
        }
        if (prefixWidth_p.* > 0) {
            _ = showString(prefix, &standardFont, 1, @intCast(@as(i32, baseY) + TEMPORARY_INFO_OFFSET), vmNormal, prefixPre, prefixPost);
        }

        var preserveErrorMessage: [ERROR_MESSAGE_LENGTH]u8 = undefined;
        _ = frontier_char_string.xcopy(&preserveErrorMessage, errorMessage, ERROR_MESSAGE_LENGTH);
        if ((regist == REGISTER_Z or regist == REGISTER_T) and !runningOnSimOrUSB()) {
            frontier_display.real34MatrixToDisplayString(regist, tmpString);
        } else if (frontier_display.vectorToDisplayString(regist, tmpString) == 0) {
            frontier_display.real34MatrixToDisplayString(regist, tmpString);
        }
        _ = frontier_char_string.xcopy(errorMessage, &preserveErrorMessage, ERROR_MESSAGE_LENGTH);

        w_p.* = frontier_char_string.stringWidth(tmpString, &numericFont, false, true);
        lineWidth_p.* = @intCast(w_p.*);
        if (w_p.* > SCREEN_WIDTH - 1) {
            w_p.* = frontier_char_string.stringWidth(tmpString, &standardFont, false, true);
            _ = showString(tmpString, &standardFont, @intCast(@as(i32, SCREEN_WIDTH) - w_p.* - 0 + 2), @bitCast(@as(i32, baseY)), vmNormal, 0, 1);
        } else {
            _ = showString(tmpString, &numericFont, @intCast(@as(i32, SCREEN_WIDTH) - w_p.* - 1), @bitCast(@as(i32, baseY)), vmNormal, 0, 1);
        }
    }

    if (temporaryInformation == TI_INACCURATE and regist == REGISTER_X) {
        _ = showString("This result may be inaccurate", &standardFont, 1, Y_POSITION_OF_ERR_LINE, vmNormal, 1, 1);
    }
}

fn refreshComplexMatrix(regist: calcRegister_t, origRegist: calcRegister_t, baseY: i16, prefix: [*c]u8, prefixWidth_p: *i16, lineWidth_p: *i16, w_p: *i32, prefixPre: bool_t, prefixPost: bool_t) void {
    if ((origRegist == REGISTER_X and calcMode != CM_MIM) or (temporaryInformation == TI_VIEW_REGISTER and origRegist == REGISTER_T)) {
        var matrix: complex34Matrix_t = undefined;
        prefixWidth_p.* = 0;
        prefix[0] = 0;
        linkToComplexMatrixRegister(regist, &matrix);
        if (temporaryInformation == TI_VIEW_REGISTER and origRegist == REGISTER_T) {
            viewRegName(prefix, prefixWidth_p);
        } else if ((regist == REGISTER_X and (temporaryInformation == TI_MIJ or temporaryInformation == TI_MIJEQ)) or ((regist == REGISTER_X or regist == REGISTER_Y) and temporaryInformation == TI_IJ) or (regist == REGISTER_X and (temporaryInformation == TI_I or temporaryInformation == TI_J))) {
            _displayIJ(regist, prefix, prefixWidth_p);
        } else if (temporaryInformation == TI_STORCL and regist == REGISTER_X) {
            viewStoRcl(prefix, prefixWidth_p);
        } else if (temporaryInformation == TI_VIEW_REGISTER and regist == REGISTER_X) {
            userTI(@intCast(currentViewRegister), regist, prefix, prefixWidth_p);
        } else if (temporaryInformation == TI_NO_INFO and currentInputVariable != INVALID_VARIABLE) {
            inputRegName(prefix, prefixWidth_p);
        }

        frontier_matrix_editor.showComplexMatrix(&matrix, prefixWidth_p.*, getComplexRegisterAngularMode(regist), (getComplexRegisterPolarMode(regist) == amPolar), (!(temporaryInformation == TI_VIEW_REGISTER and origRegist == REGISTER_T)));
        if (lastErrorCode != 0) {
            refreshRegisterLine(errorMessageRegisterLine);
        }
        if (temporaryInformation == TI_TRUE or temporaryInformation == TI_FALSE) {
            refreshRegisterLine(TRUE_FALSE_REGISTER_LINE);
        }
        if (prefixWidth_p.* > 0) {
            _ = showString(prefix, &standardFont, 1, @intCast(@as(i32, baseY) + TEMPORARY_INFO_OFFSET), vmNormal, prefixPre, prefixPost);
        }
    } else {
        if (temporaryInformation == TI_VIEW_REGISTER) {
            userTI(@intCast(currentViewRegister), regist, prefix, prefixWidth_p);
        }
        if (prefixWidth_p.* > 0) {
            _ = showString(prefix, &standardFont, 1, @intCast(@as(i32, baseY) + TEMPORARY_INFO_OFFSET), vmNormal, prefixPre, prefixPost);
        }
        frontier_display.complex34MatrixToDisplayString(regist, tmpString);
        w_p.* = frontier_char_string.stringWidth(tmpString, &numericFont, false, true);
        lineWidth_p.* = @intCast(w_p.*);
        _ = showString(tmpString, &numericFont, @intCast(@as(i32, SCREEN_WIDTH) - w_p.* - 2), @bitCast(@as(i32, baseY)), vmNormal, 0, 1);
    }

    if (temporaryInformation == TI_INACCURATE and regist == REGISTER_X) {
        _ = showString("This result may be inaccurate", &standardFont, 1, Y_POSITION_OF_ERR_LINE, vmNormal, 1, 1);
    }
}

pub export fn refreshRegisterLine(regist: calcRegister_t) callconv(.c) void {
    _refreshRegisterLine(regist, ~RESTORE_T & 1);
}

fn refreshRegisterLineRestoreT() void {
    _refreshRegisterLine(REGISTER_T, RESTORE_T);
}

fn _showAngularModeGlyph(angularMode: angularMode_t, font: *const font_t, x: u32, y: u32) void {
    switch (angularMode) {
        amMultPi => {
            _ = showString(STD_SUP_pir, font, x, y, vmNormal, 1, 1);
        },
        amRadian => {
            _ = showString(STD_SUP_BOLD_r, font, x, y, vmNormal, 1, 1);
        },
        amGrad => {
            _ = showString(STD_SUP_BOLD_g, font, x, y, vmNormal, 1, 1);
        },
        amDegree => {
            _ = showString(STD_DEGREE, font, x, y, vmNormal, 1, 1);
        },
        amSecond => {
            _ = showString("s", font, x, y, vmNormal, 1, 1);
        },
        else => {},
    }
}

pub export fn displayNim(nim: [*c]const u8, lastBase: [*c]const u8, wLastBaseNumeric: i16, wLastBaseStandard: i16) callconv(.c) void {
    var w: i16 = undefined;
    const xangularMode: angularMode_t = getRegisterAngularMode(REGISTER_X);
    const hp = checkHPoffset();
    if (frontier_char_string.stringWidth(nim, &numericFont, true, true) + wLastBaseNumeric <= SCREEN_WIDTH - 16) {
        xCursor = showString(nim, &numericFont, 0, @intCast(@as(i32, Y_POSITION_OF_NIM_LINE) - hp), vmNormal, 1, 1);
        yCursor = Y_POSITION_OF_NIM_LINE;
        cursorFont = &numericFont;

        if (lastIntegerBase != 0 or (aimBuffer[0] != 0 and aimBuffer[strlen(aimBuffer) - 1] == '/')) {
            _ = showString(lastBase, &numericFont, xCursor + 16, @intCast(@as(i32, Y_POSITION_OF_NIM_LINE) - hp), vmNormal, 1, 1);
        } else if ((getRegisterDataType(REGISTER_X) == dtReal34) and (xangularMode < amNone)) {
            _showAngularModeGlyph(xangularMode, &numericFont, xCursor + 16, @intCast(@as(i32, Y_POSITION_OF_NIM_LINE) - hp));
        }
    } else if (frontier_char_string.stringWidth(nim, &standardFont, true, true) + wLastBaseStandard <= SCREEN_WIDTH - 8) {
        xCursor = showString(nim, &standardFont, 0, Y_POSITION_OF_NIM_LINE + 6, vmNormal, 1, 1);
        yCursor = Y_POSITION_OF_NIM_LINE + 6;
        cursorFont = &standardFont;

        if (lastIntegerBase != 0 or (aimBuffer[0] != 0 and aimBuffer[strlen(aimBuffer) - 1] == '/')) {
            _ = showString(lastBase, &standardFont, xCursor + 8, Y_POSITION_OF_NIM_LINE + 6, vmNormal, 1, 1);
        } else if ((getRegisterDataType(REGISTER_X) == dtReal34) and (xangularMode < amNone)) {
            _showAngularModeGlyph(xangularMode, &standardFont, xCursor + 8, Y_POSITION_OF_NIM_LINE + 6);
        }
    } else {
        var nimw: [*c]u8 = undefined;
        w = @intCast(stringByteLength(nim) + 1);
        _ = frontier_char_string.xcopy(tmpString, nim, @intCast(w));
        _ = frontier_char_string.xcopy(tmpString + 1500, nim, @intCast(w));
        nimw = frontier_char_string.stringAfterPixels(tmpString, &standardFont, SCREEN_WIDTH - 1, true, true);
        w = @intCast(nimw - tmpString);
        nimw[0] = 0;

        if (frontier_char_string.stringWidth(tmpString + 1500 + @as(usize, @intCast(w)), &standardFont, true, true) + wLastBaseStandard > SCREEN_WIDTH - 8) {
            frontier_bufferize.addItemToNimBuffer(ITM_BACKSPACE);
        } else {
            _ = showString(tmpString, &standardFont, 0, Y_POSITION_OF_NIM_LINE - 3, vmNormal, 1, 1);

            xCursor = showString(tmpString + 1500 + @as(usize, @intCast(w)), &standardFont, 0, Y_POSITION_OF_NIM_LINE + 18, vmNormal, 1, 1);
            yCursor = Y_POSITION_OF_NIM_LINE + 18;
            cursorFont = &standardFont;

            if (lastIntegerBase != 0 or (aimBuffer[0] != 0 and aimBuffer[strlen(aimBuffer) - 1] == '/')) {
                _ = showString(lastBase, &standardFont, xCursor + 8, Y_POSITION_OF_NIM_LINE + 18, vmNormal, 1, 1);
            } else if ((getRegisterDataType(REGISTER_X) == dtReal34) and (xangularMode < amNone)) {
                _showAngularModeGlyph(xangularMode, &standardFont, xCursor + 8, Y_POSITION_OF_NIM_LINE + 18);
            }
        }
    }
}

extern var tamOverPemYPos: u32;

pub export fn clearTamBuffer() callconv(.c) void {
    if (temporaryInformation == TI_SHOWNOTHING) {
        return;
    }
    if (shiftF != 0 or shiftG != 0) {
        lcd_fill_rect(@intCast(funcNameOffset_x()), Y_POSITION_OF_TAM_LINE, @intCast(@as(i32, SCREEN_WIDTH) - funcNameOffset_x()), 32, LCD_SET_VALUE);
    } else {
        lcd_fill_rect(0, Y_POSITION_OF_TAM_LINE, SCREEN_WIDTH, 32, LCD_SET_VALUE);
    }
}

// useSmallShifts / displayF / displayG runtime macros.
inline fn useSmallShifts() bool {
    return isShiftOffset() and calcMode == CM_NORMAL and
        (((!BASEMODEACTIVE() or displayStackSHOIDISP == 0) and getRegisterDataType(REGISTER_T) == dtShortInteger and getRegisterShortIntegerBase(REGISTER_T) < 4) or
            ((dispBase > 0) and (getRegisterDataType(REGISTER_X) == dtShortInteger or getRegisterDataType(REGISTER_X) == dtLongInteger)));
}
inline fn displayF() [*c]const u8 {
    return if (useSmallShifts()) STD_f else STD_MODE_F;
}
inline fn displayG() [*c]const u8 {
    return if (useSmallShifts()) STD_g else STD_MODE_G;
}

pub export fn clearShiftState() callconv(.c) void {
    var fcol: u32 = undefined;
    var frow: u32 = undefined;
    var gcol: u32 = undefined;
    var grow: u32 = undefined;
    getGlyphBounds(displayF(), null, &standardFont, &fcol, &frow);
    getGlyphBounds(displayG(), null, &standardFont, &gcol, &grow);
    lcd_fill_rect(@intCast(X_SHIFT()), @intCast(Y_SHIFT()), if (fcol > gcol) fcol else gcol, if (frow > grow) frow else grow, LCD_SET_VALUE);
}

pub export fn showShiftStateF() callconv(.c) void {
    _ = showGlyph(displayF(), &standardFont, @intCast(X_SHIFT()), @intCast(Y_SHIFT()), vmNormal, 1, 1, 0);
}

pub export fn showShiftStateG() callconv(.c) void {
    _ = showGlyph(displayG(), &standardFont, @intCast(X_SHIFT()), @intCast(Y_SHIFT()), vmNormal, 1, 1, 0);
}

pub export fn displayShiftAndTamBuffer() callconv(.c) void {
    if (calcMode == CM_ASSIGN) {
        frontier_assign.updateAssignTamBuffer();
    }

    if (calcMode != CM_ASSIGN or itemToBeAssigned == 0 or tam.alpha) {
        if (shiftF != 0) {
            showShiftStateF();
        } else if (shiftG != 0) {
            showShiftStateG();
        }
    }

    if (tam.mode != 0 or calcMode == CM_ASSIGN) {
        if (calcMode == CM_PEM) {
            lcd_fill_rect(45 + 20, tamOverPemYPos, 168, 20, LCD_SET_VALUE);
            _ = showString(tamBuffer, &standardFont, 75 + 20, tamOverPemYPos, vmNormal, 0, 0);
        } else {
            clearTamBuffer();
            _ = showString(tamBuffer, &standardFont, @intCast(funcNameOffset_x()), Y_POSITION_OF_TAM_LINE + 6, vmNormal, 1, 1);
        }
    }
}

pub export fn closeShowMenu() callconv(.c) void {
    if (frontier_softmenus.currentMenu() == -MNU_SHOW) {
        frontier_softmenus.popSoftmenu();
    }
    showRegis = 9999;
    calcMode = CM_NORMAL;
    screenUpdatingMode = SCRUPD_AUTO;
    temporaryInformation = TI_NO_INFO;
    refreshScreen(137);
}

pub export fn reallyClearStatusBar(info: u8) callconv(.c) void {
    _ = info;
    lcd_fill_rect(0, 0, @intCast(if (GRAPHMODE()) @divTrunc(@as(i32, SCREEN_WIDTH), 3) else SCREEN_WIDTH), Y_POSITION_OF_REGISTER_T_LINE, LCD_SET_VALUE);
    force_SBrefresh(force);
    frontier_status_bar.forceSBupdate();
    frontier_status_bar.refreshStatusBar();
}

fn _selectiveClearScreen() void {
    if (screenUpdatingMode == SCRUPD_AUTO) {
        clearScreen(6);
        frontier_status_bar.refreshStatusBar();
        refreshNIMdone = 0;
    } else {
        if ((screenUpdatingMode & (SCRUPD_MANUAL_STATUSBAR | SCRUPD_SKIP_STATUSBAR_ONE_TIME)) == 0) {
            clearScreenStatusBar(7);
        } else if ((screenUpdatingMode & SCRUPD_MANUAL_STATUSBAR) == 0) {
            frontier_status_bar.refreshStatusBar();
        }

        if ((screenUpdatingMode & (SCRUPD_MANUAL_STACK | SCRUPD_SKIP_STACK_ONE_TIME)) == 0) {
            lcd_fill_rect(LeftGraphInfoX, topLeftGraphInfoY, widthGraphInfoBox, heightGraphInfoBox, LCD_SET_VALUE);
            refreshNIMdone = 0;
            if (!GRAPHMODE()) {
                lcd_fill_rect(widthGraphInfoBox, topLeftGraphInfoY, widthGraphInclBorder, heightGraphInfoBox, LCD_SET_VALUE);
            }
        }

        if ((screenUpdatingMode & (SCRUPD_MANUAL_MENU | SCRUPD_SKIP_MENU_ONE_TIME)) == 0) {
            lcd_fill_rect(LeftGraphInfoX, topLeftMenuInclBorderY, widthGraphInfoBox, menuHeightInclBorder, LCD_SET_VALUE);
            if (!GRAPHMODE() or frontier_softmenus.menu(0) == -MNU_PLOT_FUNC) {
                lcd_fill_rect(LeftGraphInfoX, topLeftMenuInclBorderY - 3, 20, 6, LCD_SET_VALUE);
            }
            if (!GRAPHMODE()) {
                lcd_fill_rect(widthGraphInfoBox, topLeftMenuInclBorderY, widthGraphInclBorder, menuHeightInclBorder, LCD_SET_VALUE);
            }
        }
    }
}

// clearScreen / clearScreenStatusBar runtime macros (screen.h).
inline fn clearScreen(cnt: u16) void {
    _ = cnt;
    lcd_fill_rect(0, 0, SCREEN_WIDTH, 240, LCD_SET_VALUE);
    frontier_status_bar.forceSBupdate();
}
inline fn clearScreenStatusBar(cnt: u16) void {
    _ = cnt;
    lcd_fill_rect(0, 0, if (calcMode == CM_GRAPH) widthGraphInfoBox else @as(u32, @intCast(SCREEN_WIDTH)), 20, LCD_SET_VALUE);
    frontier_status_bar.forceSBupdate();
}

pub export fn clearScreenOld(clearStatusBar: bool_t, clearRegisterLines_arg: bool_t, clearSoftkeys: bool_t) callconv(.c) void {
    const origScreenUpdatingMode: u8 = screenUpdatingMode;
    screenUpdatingMode = SCRUPD_AUTO;
    if (clearStatusBar != 0) {
        screenUpdatingMode &= ~SCRUPD_MANUAL_STATUSBAR;
        screenUpdatingMode |= SCRUPD_MANUAL_STACK;
        screenUpdatingMode |= SCRUPD_MANUAL_MENU;
        _selectiveClearScreen();
    }
    if (clearRegisterLines_arg != 0) {
        screenUpdatingMode |= SCRUPD_MANUAL_STATUSBAR;
        screenUpdatingMode &= ~SCRUPD_MANUAL_STACK;
        screenUpdatingMode |= SCRUPD_MANUAL_MENU;
        _selectiveClearScreen();
    }
    if (clearSoftkeys != 0) {
        screenUpdatingMode |= SCRUPD_MANUAL_STATUSBAR;
        screenUpdatingMode |= SCRUPD_MANUAL_STACK;
        screenUpdatingMode &= ~SCRUPD_MANUAL_MENU;
        _selectiveClearScreen();
    }
    screenUpdatingMode = origScreenUpdatingMode;
}

pub export fn clearScreenGraphs(source: u8, clearTextArea: bool_t, clearGraphArea: bool_t) callconv(.c) void {
    _ = source;
    const origCalcMode: u8 = calcMode;
    if (clearTextArea != 0) {
        calcMode = CM_GRAPH;
    }
    if (clearGraphArea != 0) {
        reDraw = 1;
        calcMode = CM_NORMAL;
    }
    clearScreenOld(clrStatusBar, clrRegisterLines, clrSoftkeys);
    screenUpdatingMode |= SCRUPD_MANUAL_MENU;
    screenUpdatingMode |= SCRUPD_MANUAL_STACK;
    screenUpdatingMode |= SCRUPD_MANUAL_STATUSBAR;
    calcMode = origCalcMode;
}

fn _refreshPemScreen() void {
    skippedStackLines = 0;
    if (comptime dmcp_build) {
        keyBuffer_pop();
        if (!runningOnSimOrUSB() and !(emptyKeyBuffer() != 0) and key_empty() == 1) {
            skippedStackLines = 1;
            return;
        }
    }

    if (comptime dmcp_build) {
        if (!runningOnSimOrUSB()) {
            if (doRefreshSoftMenu != 0 or (screenUpdatingMode & (SCRUPD_MANUAL_MENU | SCRUPD_SKIP_MENU_ONE_TIME)) == 0) {
                clearScreenOld(@intFromBool(false), @intFromBool(false), clrSoftkeys);
                frontier_softmenus.showSoftmenuCurrentPart();
            }
            clearScreenOld(@intFromBool(false), clrRegisterLines, @intFromBool(false));
            frontier_manage.fnPem(NOPARAM);
            displayShiftAndTamBuffer();
            if ((screenUpdatingMode & SCRUPD_MANUAL_STATUSBAR) == 0) {
                clearScreenOld(clrStatusBar, @intFromBool(false), @intFromBool(false));
                frontier_status_bar.refreshStatusBar();
            }
        } else {
            clearScreen(7);
            frontier_softmenus.showSoftmenuCurrentPart();
            frontier_manage.fnPem(NOPARAM);
            displayShiftAndTamBuffer();
            frontier_status_bar.refreshStatusBar();
        }
    } else {
        // PC_BUILD with TEST_BATTERY_POWERED_SIMULATION
        if (doRefreshSoftMenu != 0 or (screenUpdatingMode & (SCRUPD_MANUAL_MENU | SCRUPD_SKIP_MENU_ONE_TIME)) == 0) {
            clearScreenOld(@intFromBool(false), @intFromBool(false), clrSoftkeys);
            frontier_softmenus.showSoftmenuCurrentPart();
        }
        clearScreenOld(@intFromBool(false), clrRegisterLines, @intFromBool(false));
        frontier_manage.fnPem(NOPARAM);
        displayShiftAndTamBuffer();
        if ((screenUpdatingMode & SCRUPD_MANUAL_STATUSBAR) == 0) {
            clearScreenOld(clrStatusBar, @intFromBool(false), @intFromBool(false));
            frontier_status_bar.refreshStatusBar();
        }
    }
    doRefreshSoftMenu = 0;
    force_refresh(force);
}

fn _refreshNormalScreen() void {
    if (calcMode != CM_NIM) {
        refreshNIMdone = 0;
    }

    if (calcMode == CM_NORMAL and screenUpdatingMode != SCRUPD_AUTO and temporaryInformation == TI_SHOWNOTHING) {
        // goto RETURN_NORMAL
        screenUpdatingMode |= SCRUPD_MANUAL_STATUSBAR | SCRUPD_MANUAL_STACK | SCRUPD_MANUAL_MENU;
        return;
    }

    if (BASEMODEREGISTERX()) {
        screenUpdatingMode &= ~SCRUPD_MANUAL_MENU;
        screenUpdatingMode &= ~(SCRUPD_MANUAL_STACK | SCRUPD_SKIP_STACK_ONE_TIME);
        if (calcMode == CM_NIM) {
            refreshNIMdone = 0;
        }
    }

    if (BASEMODEACTIVE()) {
        frontier_status_bar.showFracMode();
    }
    if (calcMode == CM_CONFIRMATION) {
        screenUpdatingMode = SCRUPD_AUTO;
        screenUpdatingMode |= SCRUPD_SKIP_STATUSBAR_ONE_TIME;
    } else if (calcMode == CM_MIM) {
        screenUpdatingMode = if (aimBuffer[0] == 0) SCRUPD_AUTO else (SCRUPD_MANUAL_STACK | SCRUPD_MANUAL_SHIFT_STATUS);
        screenUpdatingMode |= SCRUPD_SKIP_STATUSBAR_ONE_TIME;
    } else if (calcMode == CM_TIMER) {
        screenUpdatingMode = SCRUPD_AUTO;
    } else if (calcMode == CM_EIM) {
        screenUpdatingMode &= ~SCRUPD_MANUAL_MENU;
        screenUpdatingMode |= SCRUPD_MANUAL_STACK;
    } else if (SHOWMODE()) {
        screenUpdatingMode &= ~(SCRUPD_MANUAL_STACK | SCRUPD_MANUAL_MENU);
    } else if (calcMode == CM_PEM) {
        screenUpdatingMode |= SCRUPD_MANUAL_STATUSBAR;
    } else if ((calcMode == CM_NORMAL) and ((getRegisterDataType(REGISTER_X) == dtReal34Matrix) or getRegisterDataType(REGISTER_X) == dtComplex34Matrix)) {
        screenUpdatingMode &= ~(SCRUPD_MANUAL_STACK | SCRUPD_SKIP_STACK_ONE_TIME);
    }

    _selectiveClearScreen();

    if ((calcMode != CM_NIM or (skippedStackLines != 0 and calcMode == CM_NIM)) and (screenUpdatingMode & (SCRUPD_MANUAL_STACK | SCRUPD_SKIP_STACK_ONE_TIME)) == 0) {
        if (calcMode != CM_AIM) {
            if (calcMode != CM_TIMER and !tam.alpha and temporaryInformation != TI_VIEW_REGISTER) {
                refreshRegisterLine(REGISTER_T);
            }
            refreshRegisterLine(REGISTER_Z);
            refreshRegisterLine(REGISTER_Y);
            refreshRegisterLine(REGISTER_X);
            if (temporaryInformation == TI_VIEW_REGISTER) {
                clearRegisterLine(REGISTER_T, true, true);
                refreshRegisterLine(REGISTER_T);
            }
            if (SHOWMODE()) {
                screenUpdatingMode |= SCRUPD_MANUAL_MENU;
            }
        } else {
            if (yMultiLineEdOffset == 3) {
                refreshRegisterLine(REGISTER_T);
                refreshRegisterLine(REGISTER_Z);
                refreshRegisterLine(REGISTER_Y);
            }
            refreshRegisterLine(REGISTER_X);
        }
    } else if (calcMode == CM_NIM) {
        if (refreshNIMdone == 0) {
            refreshRegisterLine(REGISTER_T);
            refreshRegisterLine(REGISTER_Z);
            refreshRegisterLine(REGISTER_Y);
            refreshNIMdone = 1;
        }
        refreshRegisterLine(NIM_REGISTER_LINE);
    }

    if (calcMode == CM_ASN_BROWSER) {
        frontier_asn_browser.fnAsnViewer(NOPARAM);
        frontier_calc_mode.calcModeNormal();
        calcMode = CM_ASN_BROWSER;
    }

    if (calcMode == CM_MIM) {
        frontier.showMatrixEditor();
    }
    if (calcMode == CM_TIMER) {
        frontier_timer.fnShowTimerApp();
    }

    if ((currentSolverStatus & SOLVER_STATUS_INTERACTIVE) != 0) {
        var mvarMenu: bool_t = 0;
        var i: usize = 0;
        while (i < SOFTMENU_STACK_SIZE) : (i += 1) {
            if (frontier_softmenus.menu(@intCast(i)) == -MNU_MVAR) {
                mvarMenu = 1;
                break;
            }
        }
        if (mvarMenu == 0) {
            if ((currentSolverStatus & SOLVER_STATUS_USES_FORMULA) != 0) {
                if ((currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_INTEGRATE) {
                    frontier_softmenus.showSoftmenu(-MNU_Sf);
                } else {
                    frontier_softmenus.showSoftmenu(-MNU_Solver);
                }
            } else {
                currentMvarLabel = INVALID_VARIABLE;
                frontier_softmenus.showSoftmenu(-MNU_MVAR);
            }
        }
    }
    if (calcMode == CM_EIM) {
        var mvarMenu: bool_t = 0;
        var i: usize = 0;
        while (i < SOFTMENU_STACK_SIZE) : (i += 1) {
            if (frontier_softmenus.menu(@intCast(i)) == -MNU_EQ_EDIT) {
                mvarMenu = 1;
                break;
            }
        }
        if (mvarMenu == 0) {
            frontier_softmenus.showSoftmenu(-MNU_EQ_EDIT);
        }
    }

    if ((screenUpdatingMode & SCRUPD_MANUAL_SHIFT_STATUS) == 0) {
        if ((screenUpdatingMode & (SCRUPD_MANUAL_STACK | SCRUPD_SKIP_STACK_ONE_TIME)) != 0) {
            clearShiftState();
        }
        displayShiftAndTamBuffer();
    }
    if ((screenUpdatingMode & (SCRUPD_MANUAL_MENU | SCRUPD_SKIP_MENU_ONE_TIME)) == 0) {
        frontier_softmenus.showSoftmenuCurrentPart();
        if (comptime dmcp_build) {
            lcd_refresh_dma();
        }
    }
    if (programRunStop == PGM_STOPPED or programRunStop == PGM_WAITING) {
        hourGlassIconEnabled = 0;
    }

    frontier_status_bar.refreshStatusBar();

    // RETURN_NORMAL:
    screenUpdatingMode |= SCRUPD_MANUAL_STATUSBAR | SCRUPD_MANUAL_STACK | SCRUPD_MANUAL_MENU;
}

pub export fn refreshScreen(source: u16) callconv(.c) void {
    _ = source;
    if (calcMode != CM_AIM and calcMode != CM_NIM and calcMode != CM_PLOT_STAT and calcMode != CM_GRAPH and calcMode != CM_LISTXY and last_CM != 240) {
        last_CM = 254;
    } else {
        if (last_CM == 240) {
            last_CM = calcMode;
        }
    }

    switch (frontier_softmenus.currentMenu()) {
        -MNU_PARETO, -MNU_UNIFORM, -MNU_DISUNIFORM, -MNU_GEV, -MNU_BINOM, -MNU_CAUCH, -MNU_WEIBL, -MNU_CHI2, -MNU_T, -MNU_EXPON, -MNU_POISS, -MNU_F, -MNU_GEOM, -MNU_HYPER, -MNU_LOGIS, -MNU_NORML => {
            screenUpdatingMode = SCRUPD_AUTO;
            screenUpdatingMode |= SCRUPD_SKIP_STATUSBAR_ONE_TIME;
        },
        else => {},
    }

    switch (calcMode) {
        CM_FLAG_BROWSER => {
            last_CM = calcMode;
            clearScreen(9);
            frontier_flag_browser.flagBrowser(NOPARAM);
            frontier_status_bar.refreshStatusBar();
            force_refresh(force);
        },
        CM_FONT_BROWSER => {
            last_CM = calcMode;
            clearScreen(10);
            frontier_font_browser.fontBrowser(NOPARAM);
            frontier_status_bar.refreshStatusBar();
            force_refresh(force);
        },
        CM_REGISTER_BROWSER => {
            last_CM = calcMode;
            clearScreen(11);
            frontier_register_browser.registerBrowser(NOPARAM);
            frontier_status_bar.refreshStatusBar();
            force_refresh(force);
        },
        CM_PEM => {
            screenUpdatingMode &= ~SCRUPD_MANUAL_MENU;
            _refreshPemScreen();
        },
        CM_CONFIRMATION => {
            if (previousCalcMode == CM_PEM) {
                _refreshPemScreen();
            } else {
                _refreshNormalScreen();
            }
        },
        CM_ASN_BROWSER, CM_NORMAL, CM_AIM, CM_NIM, CM_MIM, CM_EIM, CM_ASSIGN, CM_ERROR_MESSAGE, CM_TIMER => {
            if ((doRefreshSoftMenu != 0 and !SHOWMODE()) or calcMode == CM_ASSIGN) {
                screenUpdatingMode &= ~SCRUPD_MANUAL_MENU;
            } else if (calcMode == CM_MIM) {
                screenUpdatingMode = if (aimBuffer[0] == 0) SCRUPD_AUTO else (SCRUPD_MANUAL_STACK | SCRUPD_MANUAL_SHIFT_STATUS);
                screenUpdatingMode |= SCRUPD_SKIP_STATUSBAR_ONE_TIME;
            } else if (calcMode == CM_TIMER) {
                screenUpdatingMode = SCRUPD_MANUAL_STACK | SCRUPD_MANUAL_SHIFT_STATUS;
            }
            _refreshNormalScreen();
        },
        CM_LISTXY => {
            doRefreshSoftMenu = 0;
            displayShiftAndTamBuffer();
            frontier_status_bar.refreshStatusBar();
            frontier_graphs.fnStatList();
            hourGlassIconEnabled = 0;
            frontier_status_bar.refreshStatusBar();
            force_refresh(force);
        },
        CM_GRAPH => {
            doRefreshSoftMenu = 0;
            frontier_graphs.graph_plotmem();
            displayShiftAndTamBuffer();
            frontier_softmenus.showSoftmenuCurrentPart();
            if (programRunStop == PGM_RUNNING or programRunStop == PGM_PAUSED) {
                // Programmed graph: paint the current menu (above) and drop to
                // CM_NORMAL so a following programmed SNAP captures the same view
                // the interactive UI shows.
                calcMode = CM_NORMAL;
            }
            hourGlassIconEnabled = 1;
            frontier_status_bar.refreshStatusBar();
            hourGlassIconEnabled = 0;
            frontier_status_bar.showHideHourGlass();
            frontier_status_bar.refreshStatusBar();
            force_refresh(force);
        },
        CM_PLOT_STAT => {
            doRefreshSoftMenu = 0;
            frontier_plotstat.graphPlotstat(plotSelection);
            displayShiftAndTamBuffer();
            frontier_softmenus.showSoftmenuCurrentPart();
            hourGlassIconEnabled = 1;
            frontier_status_bar.refreshStatusBar();
            frontier_plotstat.graphDrawLRline(plotSelection);
            if (lastErrorCode != ERROR_NONE) {
                if (frontier_softmenus.currentMenu() == -MNU_HPLOT or frontier_softmenus.currentMenu() == -MNU_PLOT_ASSESS or frontier_softmenus.currentMenu() == -MNU_HPLOT or frontier_softmenus.currentMenu() == -MNU_PLOT_SCATR) {
                    frontier_softmenus.popSoftmenu();
                    calcMode = CM_NORMAL;
                    refreshScreen(84);
                }
            }
            hourGlassIconEnabled = 0;
            frontier_status_bar.showHideHourGlass();
            frontier_status_bar.refreshStatusBar();
            force_refresh(force);
        },
        else => {},
    }

    doRefreshSoftMenu = 0;
    if (comptime !dmcp_build) {
        _ = refreshLcd(null);
    }
}

// refreshLcd: host = GTK timer cb (gboolean(*)(gpointer)); dmcp = void(void).
// Both are exported (called by refreshScreen and the main loop / GTK).
const cursorCycle: i8 = 3;
extern fn showDateTimeExtern() bool_t; // (showDateTime already externed above)

pub export fn refreshLcd(unusedData: ?*anyopaque) callconv(.c) c_int {
    if (comptime !dmcp_build) {
        _ = unusedData;
        const S = struct {
            var cursorBlink: bool_t = 1;
        };
        if (cursorEnabled != 0) {
            cursorBlinkCounter += 1;
            if (cursorBlinkCounter > cursorCycle) {
                cursorBlinkCounter = 0;
                if (S.cursorBlink != 0 and !checkHP()) {
                    _ = showGlyph(STD_CURSOR, cursorFont.?, xCursor, @intCast(@as(i32, @bitCast(yCursor)) - checkHPoffset()), vmNormal, 1, 0, 0);
                } else {
                    hideCursor();
                }
                S.cursorBlink = @intFromBool(S.cursorBlink == 0);
            }
        }

        if (showFunctionNameCounter > 0) {
            showFunctionNameCounter -= SCREEN_REFRESH_PERIOD;
            if (showFunctionNameCounter <= 0) {
                hideFunctionName();
                tmpString[0] = 0;
                showFunctionName(ITM_NOP, 0, "SF:R");
            }
        }

        _ = frontier_status_bar.showDateTime();
        lcd_refresh();
        refresh_gui();
        return 1; // TRUE
    } else {
        _ = unusedData;
        const S = struct {
            var cursorBlink: bool_t = 1;
        };
        if (cursorEnabled != 0) {
            cursorBlinkCounter += 1;
            if (cursorBlinkCounter > cursorCycle) {
                cursorBlinkCounter = 0;
                if (S.cursorBlink != 0 and !checkHP()) {
                    _ = showGlyph(STD_CURSOR, cursorFont.?, xCursor, @intCast(@as(i32, @bitCast(yCursor)) - checkHPoffset()), vmNormal, 1, 0, 0);
                } else {
                    hideCursor();
                }
            }
        }

        if (showFunctionNameCounter > 0) {
            showFunctionNameCounter -= FAST_SCREEN_REFRESH_PERIOD;
            if (showFunctionNameCounter <= 0) {
                hideFunctionName();
                tmpString[0] = 0;
                showFunctionName(ITM_NOP, 0, "SF:R");
            }
        }

        if (frontier_status_bar.showDateTime()) {
            dmcpResetAutoOff();
            frontier_timer.fnPollTimerApp();
        }
        checkBattery();
        return 0;
    }
}

// fnScreenDump: host writes a BMP file (PC_BUILD only); dmcp body is empty.
pub export fn fnScreenDump(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (comptime !dmcp_build) {
        var bmpFileName: [22]u8 = undefined;
        var rawTime: time_t = undefined;
        _ = c_time(&rawTime);
        const timeInfo = localtime(&rawTime);
        if (_ioFileNameOverride[0] != 0) {
            // The graph coverage suite set this before a programmed SNAP so the
            // capture lands in c47plotTest<N>.bmp; consume it once, then clear.
            _ = strncpy(&bmpFileName, &_ioFileNameOverride, bmpFileName.len - 1);
            bmpFileName[bmpFileName.len - 1] = 0;
            _ioFileNameOverride[0] = 0;
        } else {
            _ = strftime(&bmpFileName, 22, "%Y%m%d-%H%M%S00.bmp", timeInfo);
        }
        const bmp = fopen(&bmpFileName, "wb");

        _ = fwrite("BM", 1, 2, bmp);

        var uint32: u32 = (@as(u32, @intCast(SCREEN_WIDTH)) / 8 * @as(u32, @intCast(SCREEN_HEIGHT))) + 610;
        _ = fwrite(&uint32, 1, 4, bmp);
        uint32 = 0;
        _ = fwrite(&uint32, 1, 4, bmp);
        uint32 = 0x00000082;
        _ = fwrite(&uint32, 1, 4, bmp);
        uint32 = 0x0000006c;
        _ = fwrite(&uint32, 1, 4, bmp);
        uint32 = @intCast(SCREEN_WIDTH);
        _ = fwrite(&uint32, 1, 4, bmp);
        uint32 = @intCast(SCREEN_HEIGHT);
        _ = fwrite(&uint32, 1, 4, bmp);
        var uint16: u16 = 0x0001;
        _ = fwrite(&uint16, 1, 2, bmp);
        uint16 = 0x0001;
        _ = fwrite(&uint16, 1, 2, bmp);
        uint32 = 0;
        _ = fwrite(&uint32, 1, 4, bmp);
        uint32 = 0x000030c0;
        _ = fwrite(&uint32, 1, 4, bmp);
        // Horizontal and vertical print resolution: 2835 pixels/m (72 dpi), so
        // sim and hardware screen dumps produce byte-identical BMPs.
        uint32 = 0x00000b13;
        _ = fwrite(&uint32, 1, 4, bmp);
        uint32 = 0x00000b13;
        _ = fwrite(&uint32, 1, 4, bmp);
        uint32 = 0x00000002;
        _ = fwrite(&uint32, 1, 4, bmp);
        uint32 = 0x00000002;
        _ = fwrite(&uint32, 1, 4, bmp);
        uint32 = 0x73524742;
        _ = fwrite(&uint32, 1, 4, bmp);
        uint32 = 0;
        _ = fwrite(&uint32, 1, 4, bmp);
        _ = fwrite(&uint32, 1, 4, bmp);
        _ = fwrite(&uint32, 1, 4, bmp);
        _ = fwrite(&uint32, 1, 4, bmp);
        _ = fwrite(&uint32, 1, 4, bmp);
        _ = fwrite(&uint32, 1, 4, bmp);
        _ = fwrite(&uint32, 1, 4, bmp);
        _ = fwrite(&uint32, 1, 4, bmp);
        _ = fwrite(&uint32, 1, 4, bmp);
        _ = fwrite(&uint32, 1, 4, bmp);
        _ = fwrite(&uint32, 1, 4, bmp);
        _ = fwrite(&uint32, 1, 4, bmp);
        uint32 = 0x00000002;
        _ = fwrite(&uint32, 1, 4, bmp);
        uint32 = 0;
        _ = fwrite(&uint32, 1, 4, bmp);
        _ = fwrite(&uint32, 1, 4, bmp);
        _ = fwrite(&uint32, 1, 4, bmp);
        uint32 = 0x00dff5cc;
        _ = fwrite(&uint32, 1, 4, bmp);
        uint32 = 0;
        _ = fwrite(&uint32, 1, 4, bmp);

        uint16 = 0;
        uint32 = 0;
        var uint8: u8 = undefined;
        var y: i32 = SCREEN_HEIGHT - 1;
        while (y >= 0) : (y -= 1) {
            var x: i32 = 0;
            while (x < SCREEN_WIDTH) : (x += 1) {
                uint8 = @bitCast(@as(u8, @bitCast(uint8)) << 1);
                if (c_lcd_buffer_pixel_on(@intCast(x), @intCast(y)) != 0) {
                    uint8 |= 1;
                }
                if (@rem(x, 8) == 7) {
                    _ = fwrite(&uint8, 1, 1, bmp);
                    uint8 = 0;
                }
            }
            _ = fwrite(&uint16, 1, 2, bmp);
        }

        _ = fclose(bmp);
        screenUpdatingMode |= SCRUPD_SKIP_STACK_ONE_TIME | SCRUPD_SKIP_MENU_ONE_TIME;
    }
}

fn _getPositionFromRegister(regist: calcRegister_t, maxValuePlusOne: i16) i32 {
    var value: i32 = undefined;

    if (getRegisterDataType(regist) == dtReal34) {
        var maxValue34: real34_t = undefined;
        int32ToReal34(maxValuePlusOne, &maxValue34);
        if (real34CompareLessThan(REGISTER_REAL34_DATA(regist), const34_0) != 0 or real34CompareLessEqual(&maxValue34, REGISTER_REAL34_DATA(regist)) != 0) {
            frontier_error.displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
            if (comptime extra_info) {
                real34ToString(REGISTER_REAL34_DATA(regist), errorMessage);
                abi.fmtBufZ(tmpString[0..2560], "x {d} = {s}:", .{ @as(i32, regist), std.mem.span(@as([*:0]const u8, errorMessage)) });
                moreInfoOnError("In function _getPositionFromRegister:", tmpString, "this value is negative or too big!", null);
            }
            return -1;
        }
        value = real34ToInt32(REGISTER_REAL34_DATA(regist));
    } else if (getRegisterDataType(regist) == dtLongInteger) {
        var lgInt: longInteger_t = undefined;
        frontier_register_value_conversions.convertLongIntegerRegisterToLongInteger(regist, &lgInt[0]);
        if (longIntegerCompareUInt(&lgInt[0], 0) < 0 or longIntegerCompareUInt(&lgInt[0], @intCast(maxValuePlusOne)) >= 0) {
            frontier_error.displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
            if (comptime extra_info) {
                frontier_display.longIntegerToAllocatedString(&lgInt[0], errorMessage, ERROR_MESSAGE_LENGTH);
                abi.fmtBufZ(tmpString[0..2560], "register {d} = {s}:", .{ @as(i32, regist), std.mem.span(@as([*:0]const u8, errorMessage)) });
                moreInfoOnError("In function _getPositionFromRegister:", tmpString, "this value is negative or too big!", null);
            }
            longIntegerFree(&lgInt);
            return -1;
        }
        var uv: u32 = undefined;
        longIntegerToUInt32(&lgInt, &uv);
        value = @bitCast(uv);
        longIntegerFree(&lgInt);
    } else {
        frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "register {d} is {s}:", .{ @as(i32, regist), std.mem.span(frontier_debug.getRegisterDataTypeName(regist, true, false)) });
            moreInfoOnError("In function _getPositionFromRegister:", errorMessage, "not suited for addressing!", null);
        }
        return -1;
    }

    return value;
}

fn getPixelPos(x: *i32, y: *i32) void {
    x.* = _getPositionFromRegister(REGISTER_X, SCREEN_WIDTH);
    y.* = _getPositionFromRegister(REGISTER_Y, SCREEN_HEIGHT);
}

pub export fn fnClLcd(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var x: i32 = undefined;
    var y: i32 = undefined;
    getPixelPos(&x, &y);
    if (lastErrorCode == ERROR_NONE) {
        screenUpdatingMode |= SCRUPD_MANUAL_STATUSBAR | SCRUPD_MANUAL_STACK | SCRUPD_MANUAL_MENU | SCRUPD_MANUAL_SHIFT_STATUS;
        lcd_fill_rect(@intCast(x), 0, @intCast(@as(i32, SCREEN_WIDTH) - x), @intCast(@as(i32, SCREEN_HEIGHT) - y), LCD_SET_VALUE);
    }
}

pub export fn fnPixel(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var x: i32 = undefined;
    var y: i32 = undefined;
    getPixelPos(&x, &y);
    if (lastErrorCode == ERROR_NONE) {
        screenUpdatingMode |= SCRUPD_MANUAL_STACK | SCRUPD_MANUAL_MENU | SCRUPD_MANUAL_SHIFT_STATUS;
        if ((@as(i32, SCREEN_HEIGHT) - y - 1) <= Y_POSITION_OF_REGISTER_T_LINE) {
            screenUpdatingMode |= SCRUPD_MANUAL_STATUSBAR;
        }
        setBlackPixel(@intCast(x), @intCast(@as(i32, SCREEN_HEIGHT) - y - 1));
    }
}

pub export fn fnPoint(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var x: i32 = undefined;
    var y: i32 = undefined;
    getPixelPos(&x, &y);
    if (lastErrorCode == ERROR_NONE) {
        screenUpdatingMode |= SCRUPD_MANUAL_STACK | SCRUPD_MANUAL_MENU | SCRUPD_MANUAL_SHIFT_STATUS;
        if ((@as(i32, SCREEN_HEIGHT) - y - 2) <= Y_POSITION_OF_REGISTER_T_LINE) {
            screenUpdatingMode |= SCRUPD_MANUAL_STATUSBAR;
        }
        lcd_fill_rect(@intCast(x - 1), @intCast(@as(i32, SCREEN_HEIGHT) - y - 2), 3, 3, LCD_EMPTY_VALUE);
    }
}

pub export fn fnAGraph(regist: u16) callconv(.c) void {
    var x: i32 = undefined;
    var y: i32 = undefined;
    var gramod: u32 = undefined;
    var liGramod: longInteger_t = undefined;
    getPixelPos(&x, &y);
    frontier_register_value_conversions.convertLongIntegerRegisterToLongInteger(RESERVED_VARIABLE_GRAMOD, &liGramod[0]);
    longIntegerToUInt32(&liGramod, &gramod);
    longIntegerFree(&liGramod);
    if (lastErrorCode == ERROR_NONE) {
        if (getRegisterDataType(@intCast(regist)) == dtShortInteger) {
            var val: u64 = undefined;
            var sign: i16 = undefined;
            const savedShortIntegerMode: u8 = shortIntegerMode;

            screenUpdatingMode |= SCRUPD_MANUAL_STACK | SCRUPD_MANUAL_MENU | SCRUPD_MANUAL_SHIFT_STATUS;
            if ((@as(i32, SCREEN_HEIGHT) - y - 1 - @as(i32, shortIntegerWordSize)) <= Y_POSITION_OF_REGISTER_T_LINE) {
                screenUpdatingMode |= SCRUPD_MANUAL_STATUSBAR;
            }
            shortIntegerMode = SIM_UNSIGN;
            frontier_register_value_conversions.convertShortIntegerRegisterToUInt64(@intCast(regist), &sign, &val);
            shortIntegerMode = savedShortIntegerMode;
            var i: u32 = 0;
            while (i < shortIntegerWordSize) : (i += 1) {
                switch (gramod) {
                    1 => {
                        if (val & 1 == 0) setWhitePixel(@intCast(x), @intCast(@as(i32, SCREEN_HEIGHT) - y - 1 - @as(i32, @intCast(i))));
                        if (val & 1 != 0) setBlackPixel(@intCast(x), @intCast(@as(i32, SCREEN_HEIGHT) - y - 1 - @as(i32, @intCast(i))));
                    },
                    0 => {
                        if (val & 1 != 0) setBlackPixel(@intCast(x), @intCast(@as(i32, SCREEN_HEIGHT) - y - 1 - @as(i32, @intCast(i))));
                    },
                    2 => {
                        if (val & 1 != 0) setWhitePixel(@intCast(x), @intCast(@as(i32, SCREEN_HEIGHT) - y - 1 - @as(i32, @intCast(i))));
                    },
                    3 => {
                        if (val & 1 != 0) flipPixel(@intCast(x), @intCast(@as(i32, SCREEN_HEIGHT) - y - 1 - @as(i32, @intCast(i))));
                    },
                    else => {},
                }
                val >>= 1;
            }

            fnInc(REGISTER_X);
        } else {
            frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
            if (comptime extra_info) {
                abi.fmtBufZ(errorMessage[0..512], "register {d} is {s}:", .{ @as(i32, @as(i16, @intCast(regist))), std.mem.span(frontier_debug.getRegisterDataTypeName(@intCast(regist), true, false)) });
                moreInfoOnError("In function fnAGraph:", errorMessage, "not suited for addressing!", null);
            }
        }
    }
}

pub export fn insertAlphaCursor(startAt: u16) callconv(.c) void {
    var bufPtr: [*c]u8 = tmpString + startAt;
    var strPtr: [*c]const u8 = aimBuffer;
    var strLength: u16 = 0;

    bufPtr[0] = 0;

    if (alphaCursor == 0) {
        bufPtr[0] = STD_CURSOR[0];
        bufPtr[1] = STD_CURSOR[1];
        bufPtr[2] = 0;
        bufPtr += 2;
    }

    while (strPtr[0] != 0) {
        strLength += 1;
        bufPtr[0] = strPtr[0];

        if (strPtr[0] & 0x80 != 0) {
            bufPtr[1] = strPtr[1];
            bufPtr[2] = 0;
            bufPtr += 2;
        } else {
            bufPtr[1] = 0;
            bufPtr += 1;
        }

        if (strLength == alphaCursor) {
            bufPtr[0] = STD_CURSOR[0];
            bufPtr[1] = STD_CURSOR[1];
            bufPtr[2] = 0;
            bufPtr += 2;
        }

        strPtr += if (strPtr[0] & 0x80 != 0) @as(usize, 2) else 1;
    }
}

// ===========================================================================
// fnClDisplay (42S CLD) — clear the temporary display info. Master fd83b4a4.
// ===========================================================================
pub export fn fnClDisplay(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    temporaryInformation = TI_NO_INFO;
    if (programRunStop == PGM_RUNNING) {
        screenUpdatingMode &= ~(SCRUPD_MANUAL_STATUSBAR | SCRUPD_SKIP_STATUSBAR_ONE_TIME);
        refreshScreen(151);
    }
}
