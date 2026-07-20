const std = @import("std");
const keys_management = @import("program/keys_management.zig");
const matrix_lifecycle = @import("matrix_editor/matrix_lifecycle.zig");
const frontend_settings = @import("frontend_settings.zig");
const display_format = @import("display/display_format.zig");
// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/config.c: calculator configuration, the RESET machinery
// (fnReset/doFnReset/fnClrMod), profile presets (HP35/JM/RJ/C47), the flat
// Settings[] preset table walked by Sett(), region/word-size/rounding setters,
// the confirmation system, and the DMCP battery/menu glue. doFnReset and fnClrMod
// run at every calculator reset, so this owner is test-reachable: zig build test
// exercises it through the reset path.
//
// Some functions that config.c defines are owned by OTHER owners here
// (frontend_settings/clear_all/keys_management; frontier.zig delegates to them).
// They are NOT exported here; we declare them extern and call the
// canonical symbols: fnSetGapChar, fnSettingsDispFormat{GrpL,Grp1Lo,Grp1L,GrpR},
// fnMenuGap{L,RX,R}, fnIntegerMode, fnWho, fnVersion, fnSetRoundingMode,
// fnSetSignificantDigits, fnSetBaseNr, fnSetFractionDigits, fnAngularMode,
// fnFractionType, fnRange, fnHide, fnConfirmationYes, fnConfirmationNo, fnGetRange,
// fnGetHide, fnGetLastErr, fnClAll, fnKeysManagement.
//
// Three keys helper functions and three small bridge helpers
// (z47_frontier_keys_to_user_case,
// z47_frontier_keys_from_user_case, z47_frontier_keys_user_layout_reset_case,
// z47_frontier_push_u32_to_x, z47_frontier_release_saved_statistical_sums,
// z47_frontier_is_r47_fam) are defined here as pub export fn, because other
// owners (keys_management, clear_all, frontend_settings) extern them.
//
// C ARRAYS are bound by address via @extern([*c]const T, ...) — never via a
// pointer-typed extern (which would load the first element as a pointer and SEGV):
// allReservedVariables, indexOfItems, configSettings (file-local but treated as a
// const table), Settings, confirmationTI, indexOfStrings, indexOfMsgs, msg2,
// kbd_usr, and the calcModel-dependent kbd_std_* layout tables.
//
// align(4): reserved-variable register data comes from the 4-byte block allocator
// (TO_PCMEMPTR / allocC47Blocks), so real34/strLgIntHeader casts of those pointers
// use align(4) to avoid Zig's @alignCast safety panic on the 64-bit host.
//
// OS32BIT/OS64BIT: doFnReset's GRAMOD long-integer init differs by host pointer
// width; reproduced with `if (@bitSizeOf(usize) == 64)`.
//
// Firmware-only (DMCP_BUILD) code is gated on comptime dmcp_build; DMCP ROM
// functions are reached through @ptrFromInt(LIBRARY_FN_BASE + offset) trampolines
// (offsets from dep/DMCP_SDK/dmcp/lft_ifc.h). SET_ST(STAT_PGM_END) writes the
// fixed-address sdb.calc_state word (SDB_BASE). PC_BUILD-only code is host-only.
// Dead code (VERBOSE_LEVEL == -1 printf blocks, /* */-commented bodies,
// MONITOR_VOLTAGE_INTEGRATOR) is skipped. The per-package SAVE_SPACE_DM42_* guards
// are never defined for the shared frontier object, so fnSetHP35/fnSetJM/fnSetRJ
// and addTestPrograms bodies are compiled in full.

const builtin = @import("builtin");
const frontier_build_options = @import("frontier_build_options");
const dmcp_build: bool = frontier_build_options.dmcp_build;
const old_hw: bool = frontier_build_options.old_hw;
const extra_info: bool = frontier_build_options.extra_info_on_calc_error;

const code_section = if (dmcp_build and old_hw)
    ".qspi_data"
else if (builtin.target.os.tag == .macos)
    "__TEXT,__text"
else
    ".text";

const code_data_section = if (dmcp_build and old_hw)
    ".qspi_data"
else if (builtin.target.os.tag == .macos)
    "__DATA_CONST,__const"
else
    ".rodata";

// DMCP ROM trampoline base + the fixed sdb.calc_state address.
const LIBRARY_FN_BASE: usize = if (old_hw) 0x08000201 else 0x08000301;
const SDB_BASE: usize = if (old_hw) 0x10002000 else 0x20000000;
const STAT_PGM_END: u32 = 1 << 9;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const bool_t = bool;
const calcRegister_t = i16;
const angularMode_t = c_int;
const DECNUMUNITS = 25;

const real34_t = abi.Real34;
const abi = @import("abi"); // shared ABI bindings
const frontier_addons = @import("extensions/addons.zig");
const adm_encoding = @import("input/adm_encoding.zig"); // pure external-ADM angular encoding
const word_size_math = @import("word_size_math.zig"); // pure short-integer word-size resolution
const vbat_integrator = @import("vbat_integrator.zig"); // pure battery-voltage integrator
const frontier_assign = @import("input/assign.zig");
const frontier_bufferize = @import("display/bufferize.zig");
const frontier_calc_mode = @import("calc_mode.zig");
const frontier_char_string = @import("display/text/char_string.zig");
const frontier_date_time = @import("convert/date_time.zig");
const frontier_error = @import("error.zig");
const frontier_font_browser = @import("browsers/font_browser.zig");
const frontier_fractions = @import("convert/fractions.zig");
const frontier_graphs = @import("plot/graphs.zig");
const frontier_items = @import("display/items/items.zig");
const frontier_manage = @import("program/manage.zig");
const frontier_programmable_menu = @import("program/programmable_menu.zig");
const frontier_radio_button_catalog = @import("extensions/radio_button_catalog.zig");
const frontier_real_type = @import("real_type.zig");
const frontier_recall = @import("recall.zig");
const frontier_register_value_conversions = @import("register_value_conversions.zig");
const frontier_screen = @import("display/screen.zig");
const frontier_softmenus = @import("display/softmenus/softmenus.zig");
const frontier_stats = @import("stats.zig");
const frontier_status_bar = @import("display/statusbar/status_bar.zig");
const frontier_store = @import("store.zig");
const real_t = abi.Real;
const realContext_t = abi.RealContext;
const consts = abi.constants; // decNumber constant pool (const_1, ...)

const registerHeader_t = abi.RegisterHeader;
const reservedVariableHeader_t = abi.ReservedVariableHeader;
const strLgIntHeader_t = abi.StrLgIntHeader;
const freeMemoryRegion_t = abi.FreeMemoryRegion;
const matrixHeader_t = abi.MatrixHeader;
const subroutineLevelHeader_t = abi.SubroutineLevelHeader;
const subroutineLevels_t = abi.SubroutineLevels;
const calcKey_t = abi.CalcKey;
const normKey_t = abi.NormKey;
const glyph_t = abi.Glyph;
const confirmationTI_t = abi.ConfirmationTI;
const item_t = abi.Item;
const userMenuItem_t = abi.UserMenuItem;

// indexOfStrings / indexOfMsgs / msg2 are file-local const tables.
const numberstr = struct {
    itemType: u8,
    count: u16,
    itemName: [*c]const u8,
};
const nstr2 = struct {
    str2: [180]u8,
};

// ---------------------------------------------------------------------------
// Constants (probed)
// ---------------------------------------------------------------------------
const CFG_DFLT: u16 = 0;
const CFG_CHINA: u16 = 1;
const CFG_EUROPE: u16 = 2;
const CFG_INDIA: u16 = 3;
const CFG_JAPAN: u16 = 4;
const CFG_UK: u16 = 5;
const CFG_USA: u16 = 6;

const ITM_SETDFLT: u16 = 1596;
const ITM_SETCHN: u16 = 1591;
const ITM_SETEUR: u16 = 1593;
const ITM_SETIND: u16 = 1594;
const ITM_SETJPN: u16 = 1595;
const ITM_SETUK: u16 = 1598;
const ITM_SETUSA: u16 = 1599;

const FLAG_TDM24: c_uint = 32768;
const FLAG_DMY: c_uint = 49154;
const FLAG_MDY: c_uint = 49155;
const FLAG_YMD: c_uint = 49153;
const FLAG_US: c_uint = 32853;
const FLAG_FRACT: c_uint = 32775;
const FLAG_IRFRAC: c_uint = 32839;
const FLAG_INTING: c_uint = 49189;
const FLAG_SOLVING: c_uint = 49190;
const FLAG_USER: c_uint = 32788;
const FLAG_AUTOFF: c_uint = 32798;
const FLAG_RUNTIM: c_int = 49168;
const FLAG_USB: c_uint = 49192;
const FLAG_USB_R: c_int = 49192;
const FLAG_LOWBAT: c_uint = 49173;
const FLAG_BASE_HOME: c_int = 32862;

const ITM_WOY_ISO: u16 = 2501;
const ITM_WOY_US: u16 = 2502;
const ITM_WOY_ME: u16 = 2503;
const ITM_SPACE_PUNCTUATION: u16 = 873;
const ITM_PERIOD: u16 = 820;
const ITM_COMMA: u16 = 818;
const ITM_NULL: u16 = 0;
const ITM_WDOT: u16 = 2143;
const ITM_WCOMMA: u16 = 2145;
const ITM_SPACE_4_PER_EM: u16 = 870;

const TI_DISP_JULIAN_WOY: u8 = 119;
const TI_NO_INFO: u8 = 0;
const TI_RESET: u8 = 8;
const TI_BYTES: u8 = 108;
const TI_BITS: u8 = 109;
const TI_BATTV: u8 = 78;
const TI_ARE_YOU_SURE: u8 = 9;

const ID_DP: i32 = 2;
const ID_43S: i32 = 0;

const amDegree: i32 = 2;
const amRadian: i32 = 0;
const amNone: u32 = 5;

/// currentAngularMode rendered in the external ADM encoding (0 if out of range);
/// the encoding itself lives in the tested adm_encoding module.
pub fn admValue() u8 {
    return adm_encoding.admValue(@intCast(currentAngularMode));
}

const RM_HALF_EVEN: u8 = 0;
const RM_HALF_UP: u8 = 1;

// roundingModeTable[] -> enum rounding values.
const DEC_ROUND_HALF_EVEN: c_int = 3;
const DEC_ROUND_HALF_UP: c_int = 2;
const DEC_ROUND_HALF_DOWN: c_int = 4;
const DEC_ROUND_UP: c_int = 1;
const DEC_ROUND_DOWN: c_int = 5;
const DEC_ROUND_CEILING: c_int = 0;
const DEC_ROUND_FLOOR: c_int = 6;

const SETTING_SINT_WS: c_int = 130;

const SCRUPD_AUTO: u8 = 0;
const SCRUPD_MANUAL_STATUSBAR: u8 = 1;

const CM_NORMAL: u8 = 0;
const CM_NIM: u8 = 2;
const CM_ASSIGN: u8 = 4;
const CM_CONFIRMATION: u8 = 11;
const CM_MIM: u8 = 12;
const CM_TIMER: u8 = 14;

const SIM_2COMPL: u8 = 2;
const SIM_1COMPL: u8 = 1;
const SIM_UNSIGN: u8 = 0;
const SIM_SIGNMT: u8 = 3;

const NOT_CONFIRMED: u16 = 9878;
const CONFIRMED: u16 = 9877;
const NOPARAM: u16 = 9876;
const INVALID_VARIABLE: u16 = 2199;

const REGISTER_X: calcRegister_t = 100;
const FIRST_GLOBAL_REGISTER: calcRegister_t = 0;
const LAST_GLOBAL_REGISTER: calcRegister_t = 136;
const FIRST_NAMED_VARIABLE: calcRegister_t = 256;
const FIRST_RESERVED_VARIABLE: u16 = 2000;
const LAST_RESERVED_VARIABLE: u16 = 2047;

const VAR_NO_ACC: usize = 31;
const VAR_NO_PV: usize = 39;
const VAR_NO_GRAMOD: usize = 40;
const VAR_NO_UX: usize = 41;
const VAR_NO_LY: usize = 47;

const RAM_SIZE_IN_BLOCKS: u32 = 65534;
const NUMBER_OF_GLOBAL_REGISTERS: usize = 137;
const MAX_FREE_REGIONS: usize = 200;
const BYTES_PER_BLOCK: u32 = 4;
const BPB: u5 = 2;
const REAL34_SIZE_IN_BLOCKS: u32 = 4;
const NUMBER_OF_STATISTICAL_SUMS: usize = 28;
const C47_NULL: u16 = 65535;

const TMP_STR_LENGTH: usize = 2560;
const WRITE_BUFFER_LEN: usize = 4096;
const ERROR_MESSAGE_LENGTH: usize = 512;
const AIM_BUFFER_LENGTH: usize = 1024;
const NIM_BUFFER_LENGTH: usize = 200;
const TAM_BUFFER_LENGTH: usize = 56;

const dtReal34: u32 = 1;
const dtReal34Matrix: u32 = 6;

const ERROR_RAM_FULL: u8 = 11;
const DF_ALL: u8 = 0;
const DF_UN: u32 = 5;

const DEC_INIT_DECQUAD: c_int = 128;
const DEC_INIT_DECSINGLE: c_int = 32;

const SIGMA_NONE: i8 = 0;
const CF_LINEAR_FITTING: u16 = 1;
const CF_NORMAL: u8 = 1;
const PLOT_NOTHING: u16 = 5;
const BCDu: u8 = 218;
const RBX_M1234: u8 = 226;
const RBX_F124: u8 = 222;

const ITM_SQUARE: i16 = 58;
const ITM_VERS: i16 = 1631;
const REGISTER_K: u16 = 111;
const ITM_DREAL: i16 = 1899;
const ITM_op_j_pol: i16 = 1795;
const ITM_op_j: i16 = 1830;
const ITM_BOLD: i16 = 2051;
const ITM_END: u16 = 1458;
const ITM_EXIT1: u16 = 1737;
const ITM_RIBBON_C47: u16 = 2509;
const ITM_RIBBON_C47PL: u16 = 2510;
const ITM_RIBBON_R47: u16 = 2511;
const ITM_RIBBON_R47PL: u16 = 2512;
const ITM_RESET: i16 = 1568;
const ITM_DELALL: i16 = 1419;
const ITM_CLFALL: i16 = 1421;
const ITM_DELPALL: i16 = 1426;
const ITM_CLREGS: i16 = 1427;
const ITM_DELBKUP: i16 = 1780;
const ITM_CLMALL: i16 = 2239;
const ITM_CLVALL: i16 = 2240;
const ITM_DELMALL: i16 = 2241;
const ITM_DELVALL: i16 = 2242;

const MNU_EE: i16 = 1925;
const MNU_RIBBONS: i16 = 2235;
const MNU_DEV: i16 = 2625;
const MNU_YESNO: i16 = 2244;
const MNU_HOME: i16 = 1921;
const MNU_MyMenu: i16 = 1349;

const USER_C47: u8 = 46;
const USER_DM42: u8 = 45;
const USER_R47f_g: u8 = 61;
const USER_R47bk_fg: u8 = 62;
const USER_R47fg_bk: u8 = 63;
const USER_R47fg_g: u8 = 64;
const USER_E47: u8 = 43;
const USER_D47: u8 = 47;
const USER_V47: u8 = 40;
const USER_N47: u8 = 51;
const USER_KRESET: u16 = 50;
const USER_HRESET: u16 = 58;
const USER_PRESET: u16 = 59;
const USER_MRESET: u16 = 49;
const USER_ARESET: u16 = 48;
const TO_USER: u16 = 29;
const FROM_USER: u16 = 30;

const ITM_SIGMAPLUS: i16 = 433;

const PGM_STOPPED: u8 = 0;
const PGM_WAITING: u8 = 2;

const NUMBER_OF_CATALOGS: usize = 23;
const CATALOG_NONE: i16 = 0;
const SOFTMENU_STACK_SIZE: usize = 8;

const doNotLoadAutoSav: bool_t = false;
const loadAutoSav: bool_t = true;

const TIMER_APP_STOPPED: u32 = 0xffffffff;

// rounding-mode table (config.c roundingModeTable[7]). Exported: math owners
// (round/rdp/rsd/prime/addition/subtraction) reference it by name.
pub export const roundingModeTable linksection(code_data_section) = [7]c_int{
    DEC_ROUND_HALF_EVEN, DEC_ROUND_HALF_UP, DEC_ROUND_HALF_DOWN,
    DEC_ROUND_UP,        DEC_ROUND_DOWN,    DEC_ROUND_CEILING,
    DEC_ROUND_FLOOR,
};

// configSettings preset row (bit-fields collapsed into plain fields; only the
// values are read, not the storage layout, so a plain struct is faithful).
const ConfigSetting = struct {
    tdm24: u32,
    dmy: u32,
    mdy: u32,
    ymd: u32,
    gregorianDay: u32,
    gapl: u32,
    gprl: u32,
    gpr1x: u32,
    gpr1: u32,
    gprr: u32,
    gapr: u32,
    gaprx: u32,
    us: u32,
    woy: u32,
};

const _gapl: u32 = ITM_SPACE_PUNCTUATION;
const _gprl: u32 = 3;
const _gpr1x: u32 = 0;
const _gpr1: u32 = 0;
const _gprr: u32 = 3;
const _gapr: u32 = ITM_SPACE_PUNCTUATION;
const _gaprx: u32 = ITM_PERIOD;

const configSettings = [7]ConfigSetting{
    .{ .tdm24 = 1, .dmy = 0, .mdy = 0, .ymd = 1, .gregorianDay = 2361222, .gapl = _gapl, .gprl = _gprl, .gpr1x = _gpr1x, .gpr1 = _gpr1, .gprr = _gprr, .gapr = _gapr, .gaprx = _gaprx, .us = 0, .woy = ITM_WOY_ISO },
    .{ .tdm24 = 1, .dmy = 0, .mdy = 0, .ymd = 1, .gregorianDay = 2433191, .gapl = ITM_COMMA, .gprl = 4, .gpr1x = 0, .gpr1 = 0, .gprr = 4, .gapr = ITM_COMMA, .gaprx = ITM_PERIOD, .us = 0, .woy = ITM_WOY_ISO },
    .{ .tdm24 = 1, .dmy = 1, .mdy = 0, .ymd = 0, .gregorianDay = 2299161, .gapl = ITM_SPACE_PUNCTUATION, .gprl = 3, .gpr1x = 0, .gpr1 = 0, .gprr = 3, .gapr = ITM_SPACE_PUNCTUATION, .gaprx = ITM_COMMA, .us = 0, .woy = ITM_WOY_ISO },
    .{ .tdm24 = 1, .dmy = 1, .mdy = 0, .ymd = 0, .gregorianDay = 2361222, .gapl = ITM_COMMA, .gprl = 2, .gpr1x = 0, .gpr1 = 3, .gprr = 2, .gapr = ITM_COMMA, .gaprx = ITM_PERIOD, .us = 0, .woy = ITM_WOY_US },
    .{ .tdm24 = 1, .dmy = 0, .mdy = 0, .ymd = 1, .gregorianDay = 2405160, .gapl = ITM_SPACE_PUNCTUATION, .gprl = 3, .gpr1x = 0, .gpr1 = 0, .gprr = 3, .gapr = ITM_SPACE_PUNCTUATION, .gaprx = ITM_PERIOD, .us = 0, .woy = ITM_WOY_US },
    .{ .tdm24 = 0, .dmy = 1, .mdy = 0, .ymd = 0, .gregorianDay = 2361222, .gapl = ITM_SPACE_PUNCTUATION, .gprl = 3, .gpr1x = 0, .gpr1 = 0, .gprr = 3, .gapr = ITM_SPACE_PUNCTUATION, .gaprx = ITM_PERIOD, .us = 0, .woy = ITM_WOY_ISO },
    .{ .tdm24 = 0, .dmy = 0, .mdy = 1, .ymd = 0, .gregorianDay = 2361222, .gapl = ITM_COMMA, .gprl = 3, .gpr1x = 9, .gpr1 = 0, .gprr = 3, .gapr = ITM_NULL, .gaprx = ITM_PERIOD, .us = 1, .woy = ITM_WOY_US },
};

// ---------------------------------------------------------------------------
// Settings[] flat preset table (config.c). Indexed [row*9 + col]; col 0 is the
// opcode, col 1 the flag set/clear value, cols 2..8 are the per-profile values.
// Generated faithfully from the C preprocessor; xxx == -10001.
// ---------------------------------------------------------------------------
const Settings = [_]i32{
    101,  -10001, -10001, 2,      0,      0,      0,      -10001, -10001,
    102,  -10001, -10001, 9,      3,      -10001, -10001, -10001, -10001,
    103,  -10001, -10001, -10001, -10001, -10001, 3,      -10001, -10001,
    104,  -10001, -10001, -10001, -10001, 3,      -10001, -10001, -10001,
    107,  -10001, 6145,   99,     6145,   6145,   6145,   -10001, -10001,
    108,  -10001, 0,      16,     0,      0,      34,     -10001, -10001,
    123,  -10001, 0,      16,     31,     0,      34,     -10001, -10001,
    118,  -10001, 0,      0,      31,     30,     0,      -10001, -10001,
    109,  -10001, 4,      1,      4,      4,      4,      -10001, -10001,
    110,  -10001, 4,      1,      4,      4,      4,      -10001, -10001,
    111,  -10001, 2,      0,      2,      0,      2,      -10001, -10001,
    112,  -10001, 3,      3,      3,      3,      3,      -10001, -10001,
    113,  -10001, 3,      3,      3,      3,      3,      -10001, -10001,
    114,  -10001, 0,      0,      0,      0,      0,      -10001, -10001,
    115,  -10001, 0,      0,      0,      1,      0,      -10001, -10001,
    3,    0,      32839,  -10001, -10001, -10001, -10001, -10001, -10001,
    3,    1,      -10001, -10001, 32839,  32839,  -10001, -10001, -10001,
    3,    0,      49224,  -10001, -10001, -10001, -10001, -10001, -10001,
    3,    1,      -10001, -10001, 49224,  49224,  -10001, -10001, -10001,
    3,    0,      -10001, 32837,  -10001, -10001, -10001, -10001, -10001,
    3,    1,      32837,  -10001, 32837,  32837,  32837,  -10001, -10001,
    3,    0,      32836,  -10001, -10001, -10001, -10001, -10001, -10001,
    3,    1,      32838,  -10001, -10001, -10001, -10001, -10001, -10001,
    3,    0,      32841,  -10001, -10001, -10001, -10001, -10001, -10001,
    3,    0,      32842,  -10001, -10001, -10001, -10001, -10001, -10001,
    3,    1,      -10001, -10001, 32842,  32842,  -10001, -10001, -10001,
    120,  -10001, 64,     -10001, 120,    999,    64,     -10001, -10001,
    121,  -10001, 0,      -10001, -10001, -10001, -10001, -10001, 0,
    122,  -10001, 0,      -10001, -10001, -10001, -10001, -10001, 0,
    2042, -10001, -10,    -10001, -10001, -10001, -10001, -10001, 0,
    2041, -10001, 10,     -10001, -10001, -10001, -10001, -10001, 0,
    2047, -10001, 0,      -10001, -10001, -10001, -10001, -10001, 0,
    2046, -10001, 0,      -10001, -10001, -10001, -10001, -10001, 0,
    2034, -10001, 0,      -10001, -10001, -10001, -10001, -10001, 0,
    2035, -10001, 0,      -10001, -10001, -10001, -10001, -10001, 0,
    2036, -10001, 0,      -10001, -10001, -10001, -10001, -10001, 0,
    2038, -10001, 0,      -10001, -10001, -10001, -10001, -10001, 0,
    2039, -10001, 0,      -10001, -10001, -10001, -10001, -10001, 0,
    2037, -10001, 12,     -10001, -10001, -10001, -10001, -10001, 12,
    2043, -10001, 12,     -10001, -10001, -10001, -10001, -10001, 12,
    3,    1,      49193,  -10001, -10001, -10001, -10001, -10001, 49193,
    124,  -10001, 1,      -10001, -10001, -10001, -10001, -10001, 1,
    125,  -10001, 12,     -10001, -10001, -10001, -10001, -10001, 12,
    // FLAG_SIGZEROS (32874) / FLAG_BOLD (32873) preset rows (config.c) — these
    // 4 rows were dropped in the port, so no profile configured BOLD/SIGZEROS.
    3,    1,      32874,  32874,  -10001, 32874,  32874,  -10001, -10001,
    3,    0,      -10001, -10001, 32874,  -10001, -10001, -10001, -10001,
    3,    0,      32873,  32873,  -10001, 32873,  32873,  -10001, -10001,
    3,    1,      -10001, -10001, 32873,  -10001, -10001, -10001, -10001,
    3,    1,      32832,  -10001, -10001, -10001, -10001, -10001, -10001,
    3,    1,      32834,  -10001, -10001, -10001, -10001, -10001, -10001,
    3,    0,      -10001, -10001, 32834,  32834,  -10001, -10001, -10001,
    3,    0,      32859,  -10001, 32859,  32859,  -10001, -10001, -10001,
    3,    1,      32830,  -10001, 32830,  32830,  -10001, -10001, -10001,
    3,    0,      -10001, -10001, 32788,  32788,  -10001, -10001, -10001,
    3,    1,      32812,  -10001, -10001, -10001, -10001, 32812,  -10001,
    3,    0,      32813,  -10001, 32813,  -10001, -10001, 32813,  -10001,
    3,    0,      32814,  -10001, -10001, -10001, -10001, 32814,  -10001,
    3,    1,      -10001, -10001, -10001, 32814,  -10001, -10001, -10001,
    3,    1,      32815,  -10001, -10001, -10001, -10001, 32815,  -10001,
    3,    0,      32816,  -10001, -10001, -10001, -10001, 32816,  -10001,
    3,    1,      32817,  -10001, -10001, -10001, -10001, 32817,  -10001,
    3,    1,      32818,  -10001, -10001, -10001, -10001, 32818,  -10001,
    3,    0,      -10001, -10001, -10001, 32818,  -10001, -10001, -10001,
    3,    0,      32819,  -10001, -10001, -10001, -10001, 32819,  -10001,
    3,    1,      -10001, -10001, -10001, 32819,  -10001, -10001, -10001,
    3,    1,      32820,  -10001, -10001, -10001, -10001, 32820,  -10001,
    3,    1,      32821,  -10001, -10001, -10001, -10001, 32821,  -10001,
    3,    0,      32822,  -10001, -10001, -10001, -10001, 32822,  -10001,
    3,    1,      32823,  -10001, -10001, -10001, -10001, 32823,  -10001,
    3,    0,      -10001, -10001, -10001, 32823,  -10001, -10001, -10001,
    3,    1,      32824,  -10001, -10001, -10001, -10001, 32824,  -10001,
    3,    1,      32825,  -10001, -10001, -10001, -10001, 32825,  -10001,
    3,    0,      32826,  -10001, -10001, -10001, -10001, 32826,  -10001,
    3,    1,      -10001, -10001, 32826,  32826,  -10001, -10001, -10001,
    3,    0,      32827,  -10001, -10001, -10001, -10001, 32827,  -10001,
    3,    1,      32795,  -10001, -10001, -10001, -10001, -10001, -10001,
    3,    0,      -10001, -10001, 32795,  -10001, -10001, -10001, -10001,
    3,    1,      32798,  -10001, -10001, -10001, -10001, -10001, -10001,
    3,    1,      49193,  -10001, -10001, -10001, -10001, -10001, -10001,
    3,    1,      32811,  -10001, -10001, -10001, -10001, -10001, -10001,
    3,    0,      -10001, -10001, 32811,  32811,  -10001, -10001, -10001,
    3,    1,      32854,  -10001, -10001, -10001, -10001, -10001, -10001,
    3,    0,      -10001, -10001, 32854,  32854,  -10001, -10001, -10001,
    3,    1,      32828,  -10001, 32828,  -10001, -10001, -10001, -10001,
    3,    0,      -10001, -10001, -10001, 32828,  -10001, -10001, -10001,
    3,    0,      32829,  -10001, 32829,  32829,  -10001, -10001, -10001,
    3,    0,      32785,  -10001, 32785,  32785,  -10001, -10001, -10001,
    3,    0,      -10001, -10001, 32774,  -10001, -10001, -10001, -10001,
    3,    0,      -10001, -10001, -10001, -10001, 32773,  -10001, -10001,
    3,    1,      -10001, -10001, 32773,  -10001, -10001, -10001, -10001,
    3,    1,      32772,  -10001, 32772,  32772,  32772,  -10001, -10001,
    3,    0,      -10001, 32772,  -10001, -10001, -10001, -10001, -10001,
    3,    1,      32791,  -10001, 32791,  32791,  32791,  -10001, -10001,
    3,    0,      -10001, 32791,  -10001, -10001, -10001, -10001, -10001,
    3,    1,      32792,  -10001, 32792,  32792,  32792,  -10001, -10001,
    3,    0,      -10001, 32792,  -10001, -10001, -10001, -10001, -10001,
    3,    0,      49187,  -10001, -10001, -10001, -10001, -10001, -10001,
    3,    1,      -10001, -10001, 32796,  -10001, -10001, -10001, -10001,
    3,    1,      32856,  -10001, 32856,  32856,  32856,  -10001, -10001,
    3,    0,      32778,  -10001, 32778,  -10001, -10001, -10001, -10001,
    3,    0,      32775,  -10001, 32775,  -10001, -10001, -10001, -10001,
    3,    1,      32776,  -10001, -10001, -10001, -10001, -10001, -10001,
    3,    0,      -10001, -10001, 32776,  32776,  -10001, -10001, -10001,
    3,    0,      32777,  -10001, -10001, -10001, -10001, -10001, -10001,
    3,    1,      -10001, -10001, 32777,  32777,  -10001, -10001, -10001,
    3,    0,      32810,  -10001, 32810,  -10001, -10001, -10001, -10001,
    3,    0,      32833,  -10001, -10001, -10001, -10001, -10001, -10001,
    3,    1,      32861,  -10001, -10001, -10001, -10001, -10001, -10001,
    3,    1,      32864,  -10001, -10001, -10001, -10001, -10001, -10001,
    3,    0,      32863,  -10001, -10001, -10001, -10001, -10001, -10001,
    3,    0,      32865,  -10001, -10001, -10001, -10001, -10001, -10001,
    3,    1,      32860,  -10001, 32860,  32860,  32860,  -10001, -10001,
    3,    0,      -10001, 32860,  -10001, -10001, -10001, -10001, -10001,
    3,    0,      32862,  32862,  32862,  32862,  32862,  -10001, -10001,
    3,    1,      32867,  -10001, 32867,  32867,  32867,  -10001, -10001,
    3,    0,      -10001, 32867,  -10001, -10001, -10001, -10001, -10001,
    3,    0,      -10001, 32866,  -10001, -10001, -10001, -10001, -10001,
    3,    0,      32868,  -10001, -10001, 32868,  32868,  -10001, -10001,
    3,    1,      -10001, -10001, 32868,  -10001, -10001, -10001, -10001,
    3,    0,      32869,  -10001, -10001, 32869,  32869,  -10001, -10001,
    3,    0,      32870,  -10001, -10001, 32870,  32870,  -10001, -10001,
    4,    -10001, 873,    0,      873,    870,    873,    -10001, -10001,
    4,    -10001, 33641,  32768,  33641,  33638,  33641,  -10001, -10001,
    4,    -10001, 49972,  51295,  51295,  51297,  49972,  -10001, -10001,
    0,    0,      0,      0,      0,      0,      0,      0,      0,
};

const _numberOfGrps: usize = 7;

// Settings[] opcodes
const op_InputDefaultDataType: i32 = 101;
const op_SigFigNumberOfDigits: i32 = 102;
const op_AllNumberOfDigits: i32 = 103;
const op_FixNumberOfDigits: i32 = 104;
const op_RNG: i32 = 107;
const op_SDIGS: i32 = 108;
const op_DSTACK: i32 = 109;
const op_CACHEDDSTACK: i32 = 110;
const op_ADM: i32 = 111;
const op_IPGRP: i32 = 112;
const op_FPGRP: i32 = 113;
const op_IPGRP1: i32 = 114;
const op_IPGRP1x: i32 = 115;
const op_HIDE: i32 = 118;
const op_DenMaX: i32 = 120;
const op_TVMIKnown: i32 = 121;
const op_TVMIChanges: i32 = 122;
const op_FDIGS: i32 = 123;
const op_AMORTP1: i32 = 124;
const op_AMORTP2: i32 = 125;

const RESERVED_VARIABLE_LX: i32 = 2042;
const RESERVED_VARIABLE_UX: i32 = 2041;
const RESERVED_VARIABLE_LY: i32 = 2047;
const RESERVED_VARIABLE_UY: i32 = 2046;
const RESERVED_VARIABLE_FV: i32 = 2034;
const RESERVED_VARIABLE_IPONA: i32 = 2035;
const RESERVED_VARIABLE_NPPER: i32 = 2036;
const RESERVED_VARIABLE_PMT: i32 = 2038;
const RESERVED_VARIABLE_PV: i32 = 2039;
const RESERVED_VARIABLE_PPERONA: i32 = 2037;
const RESERVED_VARIABLE_CPERONA: i32 = 2043;

// Sett() profile selectors
const _Reset: i16 = 1;
const _HP35: i16 = 2;
const _JM: i16 = 3;
const _RJ: i16 = 4;
const _C47: i16 = 5;
const _DefltSB: i16 = 6;
const _TVM: i16 = 7;

// ---------------------------------------------------------------------------
// Globals: genuine C pointer/scalar variables -> extern var.
// ---------------------------------------------------------------------------
extern var ram: [*c]u32;
extern var loadTestData: bool_t; // c47.c global; default false, set only by the host test-data option
extern var tmpString: [*c]u8;
extern var errorMessage: [*c]u8;
extern var aimBuffer: [*c]u8;
extern var nimBufferDisplay: [*c]u8;
extern var tamBuffer: [*c]u8;
extern var tmpStringLabelOrVariableName: [*c]u8;
extern var beginOfProgramMemory: [*c]u8;
extern var currentStep: [*c]u8;
extern var firstFreeProgramByte: [*c]u8;
extern var firstDisplayedStep: [*c]u8;
extern var labelList: [*c]abi.LabelList;
extern var programList: [*c]abi.ProgramList;
extern var allNamedVariables: [*c]abi.NamedVariableHeader;
extern var currentSubroutineLevelData: [*c]subroutineLevelHeader_t;
extern var currentLocalFlags: [*c]abi.LocalFlags;
extern var currentLocalRegisters: [*c]abi.RegisterHeader;
extern var userKeyLabel: [*c]u8;
extern var savedStatisticalSumsPointer: ?*anyopaque;
extern var statisticalSumsPointer: [*c]abi.Real;
extern var userMenus: [*c]abi.UserMenu;
extern var allFormulae: [*c]abi.FormulaHeader;

// globalRegister/freeMemoryRegions are STATIC ARRAYS only on DMCP+OLD_HW; on the
// host and new_hw firmware they are malloc'd POINTERS (c47.h:#if DMCP_BUILD &&
// OLD_HW). This must match frontier_free_list.zig's free_regions_is_array.
const globalRegister_is_array = dmcp_build and old_hw;
const globalRegister_array = if (globalRegister_is_array)
    @extern([*c]registerHeader_t, .{ .name = "globalRegister" })
else {};
const freeMemoryRegions_array = if (globalRegister_is_array)
    @extern([*c]freeMemoryRegion_t, .{ .name = "freeMemoryRegions" })
else {};
// Pointer form (host + new_hw firmware): freeMemoryRegions is a freeMemoryRegion_t*.
const globalRegister_ptr = if (!globalRegister_is_array)
    @extern(*?*anyopaque, .{ .name = "globalRegister" })
else {};
const freeMemoryRegions_ptr = if (!globalRegister_is_array)
    @extern(*?*anyopaque, .{ .name = "freeMemoryRegions" })
else {};

// C ARRAYS bound by address.
const allReservedVariables = @extern([*c]const reservedVariableHeader_t, .{ .name = "allReservedVariables" });
const indexOfItems = @extern([*c]const item_t, .{ .name = "indexOfItems" });
const kbd_usr = @extern([*c]calcKey_t, .{ .name = "kbd_usr" });

// calcModel-dependent layout tables (kbd_std macro) — bound by address.
const kbd_std_C47 = @extern([*c]const calcKey_t, .{ .name = "kbd_std_C47" });
const kbd_std_DM42 = @extern([*c]const calcKey_t, .{ .name = "kbd_std_DM42" });
const kbd_std_R47f_g = @extern([*c]const calcKey_t, .{ .name = "kbd_std_R47f_g" });
const kbd_std_R47bk_fg = @extern([*c]const calcKey_t, .{ .name = "kbd_std_R47bk_fg" });
const kbd_std_R47fg_bk = @extern([*c]const calcKey_t, .{ .name = "kbd_std_R47fg_bk" });
const kbd_std_R47fg_g = @extern([*c]const calcKey_t, .{ .name = "kbd_std_R47fg_g" });
// PC_BUILD-only extra layouts referenced by the kbd_std macro on host.
const kbd_std_E47 = if (!dmcp_build) @extern([*c]const calcKey_t, .{ .name = "kbd_std_E47" }) else {};
const kbd_std_D47 = if (!dmcp_build) @extern([*c]const calcKey_t, .{ .name = "kbd_std_D47" }) else {};
const kbd_std_V47 = if (!dmcp_build) @extern([*c]const calcKey_t, .{ .name = "kbd_std_V47" }) else {};
const kbd_std_N47 = if (!dmcp_build) @extern([*c]const calcKey_t, .{ .name = "kbd_std_N47" }) else {};

// kbd_std_C47[37] size for the frontier_char_string.xcopy(kbd_usr, kbd_std, sizeof(kbd_std_C47)) calls.
const SIZEOF_KBD_STD: u32 = 37 * @sizeOf(calcKey_t);

extern var Norm_Key_00: normKey_t;
extern var glyphNotFound: glyph_t;
extern var softmenuStack: [SOFTMENU_STACK_SIZE]abi.SoftmenuStack;
extern var globalFlags: [8]u16;
extern var systemFlags0: u64;
extern var systemFlags1: u64;
extern var lastCatalogPosition: [NUMBER_OF_CATALOGS]i16;
extern var userMenuItems: [18]userMenuItem_t;
extern var userAlphaItems: [18]userMenuItem_t;
extern var lastStateFileOpened: [stateFileNameVarLength + 12]u8;
const stateFileNameVarLength: usize = 20;
extern var lastTemp: [16]u8;
extern var statMx: [8]u8;
extern var plotStatMx: [8]u8;
extern var ctxtReal34: realContext_t;
extern var ctxtReal4: realContext_t;
extern var ctxtReal39: realContext_t;
extern var ctxtReal51: realContext_t;
extern var ctxtReal75: realContext_t;
extern var allSubroutineLevels: subroutineLevels_t;

const ConfirmedFn = *const fn (u16) callconv(.c) void;
extern var confirmedFunction: ?ConfirmedFn;

// Scalars
extern var firstGregorianDay: u32;
extern var firstDayOfWeek: u8;
extern var firstWeekOfYearDay: u8;
extern var gapItemLeft: u16;
extern var gapItemRight: u16;
extern var gapItemRadix: u16;
extern var grpGroupingLeft: u8;
extern var grpGroupingGr1LeftOverflow: u8;
extern var grpGroupingGr1Left: u8;
extern var grpGroupingRight: u8;
extern var displayFormat: u8;
extern var displayFormatDigits: u8;
extern var timeDisplayFormatDigits: u8;
extern var shortIntegerMode: u8;
extern var shortIntegerWordSize: u8;
extern var shortIntegerMask: u64;
extern var shortIntegerSignBit: u64;
extern var roundingMode: u8;
extern var significantDigits: u8;
extern var fractionDigits: u8;
extern var dispBase: u8;
extern var denMax: u32;
extern var currentAngularMode: c_int;
extern var displayStack: u8;
extern var cachedDisplayStack: u8;
extern var exponentLimit: i16;
extern var exponentHideLimit: i16;
extern var lastCenturyHighUsed: u16;
extern var lrSelection: u16;
extern var lrSelectionUndo: u16;
extern var lrChosen: u16;
extern var lrChosenUndo: u16;
extern var lrChosenHistobackup: u16;
extern var lrSelectionHistobackup: u16;
extern var IrFractionsCurrentStatus: u8;
extern var Input_Default: u8;
extern var displayStackSHOIDISP: u8;
extern var bcdDisplaySign: u8;
extern var DRG_Cycling: u8;
extern var DM_Cycling: u8;
extern var LongPressM: u8;
extern var LongPressF: u8;
extern var lastIntegerBase: u32;
extern var decodedIntegerBase: u32;
extern var timeLastOp: u32;
extern var timeLastOp0: u32;
extern var timeLastOp1: u32;
extern var lastI: u16;
extern var lastFunc: i16;
extern var lastParam: i16;
extern var blockMonitoring: bool_t;
extern var cancelFilename: bool_t;
extern var firstDisplayedLocalStepNumber: u16;
extern var currentLocalStepNumber: u16;
extern var freeProgramBytes: u16;
extern var numberOfNamedVariables: u16;
extern var numberOfFreeMemoryRegions: i32;
extern var matrixIndex: u16;
extern var statisticalSumsUpdate: bool_t;
extern var lastPlotMode: u16;
extern var plotSelection: u16;
extern var drawHistogram: u8;
extern var SAVED_SIGMA_LASTX: real_t;
extern var SAVED_SIGMA_LASTY: real_t;
extern var SAVED_SIGMA_lastAddRem: i8;
extern var regStatsXY: calcRegister_t;
extern var loBinR: real34_t;
extern var nBins: real34_t;
extern var hiBinR: real34_t;
extern var histElementXorY: i16;
// Graph range limits: real_t (decNumber) POINTERs (real_t *const in upstream).
// The symbol holds a pointer to a backing real_t; deref/pass the pointer directly.
extern var x_min: *real_t;
extern var x_max: *real_t;
extern var y_min: *real_t;
extern var y_max: *real_t;
extern var watchIconEnabled: bool_t;
extern var serialIOIconEnabled: bool_t;
extern var printerIconEnabled: bool_t;
extern var thereIsSomethingToUndo: bool_t;
extern var pemCursorIsZerothStep: bool_t;
extern var fnKeyInCatalog: bool_t;
extern var hourGlassIconEnabled: bool_t;
extern var shiftF: bool_t;
extern var shiftG: bool_t;
extern var lastshiftF: bool_t;
extern var lastshiftG: bool_t;
extern var secTick1: bool_t;
extern var halfSecTick2: bool_t;
extern var halfSecTick3: bool_t;
extern var skippedStackLines: bool_t;
extern var iterations: bool_t;
extern var explicitTaylorIterVisibilitySelection: bool_t;
extern var updateOldConstants: bool_t;
extern var programRunStop: u8;
extern var currentAsnScr: u8;
extern var currentFlgScr: u8;
extern var lastFlgScr: u8;
extern var currentRegisterBrowserScreen: i16;
extern var menuPageNumber: u16;
extern var lastErrorCode: u8;
extern var previousErrorCode: u8;
extern var catalog: i16;
extern var lastDenominator: u32;
extern var temporaryInformation: u8;
extern var currentInputVariable: u16;
extern var currentMvarLabel: u16;
extern var lastKeyCode: u8;
extern var entryStatus: u8;
extern var lastUserMode: bool_t;
extern var lastItem: i16;
extern var numberOfUserMenus: u16;
extern var currentUserMenu: u16;
extern var showRegis: u16;
extern var overrideShowBottomLine: u8;
extern var ListXYposition: i16;
extern var displayAIMbufferoffset: i16;
extern var T_cursorPos: i16;
extern var yMultiLineEdOffset: u8;
extern var xMultiLineEdOffset: u8;
extern var current_cursor_x: u16;
extern var current_cursor_y: u16;
extern var lastT_cursorPos: i16;
extern var numberOfFormulae: u16;
extern var currentFormula: u16;
extern var currentSolverStatus: u16;
extern var currentSolverProgram: u16;
extern var currentSolverVariable: u16;
extern var currentSolverNestingDepth: u16;
extern var graphVariabl1: calcRegister_t;
extern var timerCraAndDeciseconds: u8;
extern var timerValue: u32;
extern var timerStartTime: u32;
extern var timerTotalTime: u32;
extern var calcMode: u8;
extern var screenUpdatingMode: u8;
extern var doRefreshSoftMenu: bool_t;
extern var cachedDynamicMenu: i16;
extern var calcModel: u8;
extern var itemToBeAssigned: i16;
extern var previousCalcMode: u8;
extern var cursorEnabled: bool_t;
extern var numberOfLabels: u16;
extern var numberOfPrograms: u16;

// ---------------------------------------------------------------------------
// libc / runtime function externs
// ---------------------------------------------------------------------------
extern fn memset(s: ?*anyopaque, c: c_int, n: usize) ?*anyopaque;
extern fn malloc(n: usize) ?*anyopaque;
extern fn strcpy(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strcat(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn sprintf(buf: [*c]u8, fmt: [*:0]const u8, ...) c_int;
extern fn printf(fmt: [*:0]const u8, ...) c_int;

// decNumber primitives behind int32ToReal / realToReal34 / real34SetZero / realSetZero.
extern fn decNumberFromInt32(result: *real_t, rhs: i32) *real_t;
// realCopy(src,dst) macro -> decNumberCopy(dst, src) (used by doFnReset range init).
extern fn decNumberCopy(res: *real_t, src: *align(1) const real_t) *real_t;
// realToReal34/decQuadFromNumber are macros over decimal128FromNumber.
extern fn decimal128FromNumber(dst: *real34_t, src: *align(1) const real_t, ctx: *realContext_t) *real34_t;
extern fn decQuadZero(dst: *real34_t) *real34_t;

extern fn decContextDefault(ctx: *realContext_t, kind: c_int) *realContext_t;

// PRNG seed (pcg32_srandom(uint64_t, uint64_t)).
extern fn pcg32_srandom(initstate: u64, initseq: u64) void;

// flags
extern fn getSystemFlag(sf: i32) bool_t;
extern fn forceSystemFlag(sf: c_uint, set: c_int) void;
extern fn setSystemFlag(sf: c_uint) void;
extern fn clearSystemFlag(sf: c_uint) void;
extern fn fnSetFlag(flag: u16) void;
extern fn fnClearFlag(flag: u16) void;
extern fn setSystemFlagChanged(sf: i32) void;

// register / long-integer helpers

extern fn reallocateRegister(regist: calcRegister_t, dataType: u32, dataSizeWithoutDataLenBlocks: u16, tag: u32) void;
extern fn getRegisterDataPointer(regist: calcRegister_t) *anyopaque;
extern fn getRegisterDataType(regist: calcRegister_t) u32;
extern fn setRegisterDataType(regist: calcRegister_t, dataType: u16, tag: u32) void;
extern fn setRegisterDataPointer(regist: calcRegister_t, memPtr: *const anyopaque) void;
extern fn clearRegister(regist: calcRegister_t) void;
extern fn allocateNamedVariable(variableName: [*c]const u8, dataType: u32, fullDataSizeInBlocks: u16) void;
extern fn allocateLocalRegisters(numberOfRegistersToAllocate: u16) void;
extern fn allocC47Blocks(sizeInBlocks: usize) ?*anyopaque;
extern fn freeC47Blocks(pcMemPtr: ?*anyopaque, sizeInBlocks: usize) void;
extern fn resizeProgramMemory(newSizeInBlocks: u16) void;

// GMP mpz_struct (limb width == pointer width on every z47 target).
const mpz_struct = abi.Mpz;
extern fn __gmpz_init(p: *mpz_struct) void;
extern fn __gmpz_clear(p: *mpz_struct) void;
extern fn __gmpz_set_ui(p: *mpz_struct, v: c_ulong) void;
extern fn __gmpz_get_ui(p: *const mpz_struct) c_ulong;
extern fn __gmpz_get_si(p: *const mpz_struct) c_long;
const mpz_init = __gmpz_init;
const mpz_clear = __gmpz_clear;
const mpz_set_ui = __gmpz_set_ui;
const mpz_get_ui = __gmpz_get_ui;
const mpz_get_si = __gmpz_get_si;

// other engine functions

extern fn showShiftState() void;
extern fn refreshModeGui() void;

extern fn fnKeyExit(unusedButMandatoryParameter: u16) void;
extern fn fnKeyBackspace(unusedButMandatoryParameter: u16) void;
extern fn fnDisplayStack(numberOfStackLines: u16) void;
extern fn fnClearStack(unusedButMandatoryParameter: u16) void;
extern fn fnPi(unusedButMandatoryParameter: u16) void;
extern fn fnDrop(unusedButMandatoryParameter: u16) void;
extern fn fnSquare(unusedButMandatoryParameter: u16) void;

extern fn resetKeytimers() void;

extern var alphaRegister: u16;
extern var varMenu42: bool;
extern fn liftStack() void;
extern fn getFreeRamMemory() u32;

// Cross-owner canonical symbols (owned by
// frontend_settings / clear_all / keys_management) -> extern, called by name.

// Engine functions config.c calls (owned elsewhere, not by this file).

extern fn SetSetting(jmConfig: u16) void;

// ---------------------------------------------------------------------------
// Inline helpers mirroring c47.h macros.
// ---------------------------------------------------------------------------
inline fn toBlocks(n: u32) u32 {
    return abi.block_math.toBlocks(u32, n);
}
inline fn toBytes(n: u32) u32 {
    return abi.block_math.toBytes(u32, n);
}
// TO_PCMEMPTR(p): (p==C47_NULL)?NULL:ram+p  (p is a 16-bit block index)
inline fn toPcMemPtr(p: u32) ?*anyopaque {
    if (p == C47_NULL) return null;
    return @ptrCast(ram + p);
}
// TO_C47MEMPTR(p): (p==NULL)?C47_NULL:(uint16_t)((uint32_t*)p - ram)
inline fn toC47MemPtr(p: ?*anyopaque) u16 {
    if (p == null) return C47_NULL;
    const pu: [*c]u32 = @ptrCast(@alignCast(p));
    return @intCast((@intFromPtr(pu) - @intFromPtr(ram)) / @sizeOf(u32));
}
// int32ToReal(s,d) / realToReal34(s,d) / real34SetZero(d)
inline fn int32ToReal(source: i32, destination: *real_t) void {
    _ = decNumberFromInt32(destination, source);
}
inline fn realCopy(source: *align(1) const real_t, destination: *real_t) void {
    _ = decNumberCopy(destination, source);
}
inline fn realToReal34(source: *const real_t, destination: *real34_t) void {
    _ = decimal128FromNumber(destination, @ptrCast(source), &ctxtReal34);
}
inline fn real34SetZero(destination: *real34_t) void {
    _ = decQuadZero(destination);
}
// REGISTER_REAL34_DATA(a)
const reg34 = abi.registerReal34Aligned;
// reserved-variable register data pointer (4-byte block aligned).
inline fn reservedReal34(varNo: usize) *align(4) real34_t {
    const blk = allReservedVariables[varNo].header.descriptor & 0xFFFF;
    return @ptrCast(@alignCast(toPcMemPtr(blk).?));
}
inline fn reservedStrLgHdr(varNo: usize) [*c]align(4) strLgIntHeader_t {
    const blk = allReservedVariables[varNo].header.descriptor & 0xFFFF;
    return @ptrCast(@alignCast(toPcMemPtr(blk).?));
}
// getStackTop(): FLAG_SSIZE8 ? REGISTER_D : REGISTER_T
const FLAG_SSIZE8: i32 = 32792;
const REGISTER_D: calcRegister_t = 107;
const REGISTER_T: calcRegister_t = 103;
inline fn getStackTop() calcRegister_t {
    return if (getSystemFlag(FLAG_SSIZE8)) REGISTER_D else REGISTER_T;
}
// shortIntegerModeValue()
inline fn shortIntegerModeValue() i32 {
    return if (shortIntegerMode == SIM_2COMPL) 2 else if (shortIntegerMode == SIM_1COMPL) 1 else if (shortIntegerMode == SIM_UNSIGN) 0 else -1;
}
// isR47FAM macro
inline fn isR47FAM() bool_t {
    return calcModel == USER_R47f_g or calcModel == USER_R47bk_fg or calcModel == USER_R47fg_bk or calcModel == USER_R47fg_g;
}
// checkHP macro: significantDigits<=16 && displayStack==1 && exponentLimit==99 &&
//   Input_Default==ID_DP && (calcMode==CM_NORMAL || calcMode==CM_NIM)
const ID_DP_u8: u8 = 2;
inline fn checkHP() bool_t {
    return significantDigits <= 16 and displayStack == 1 and exponentLimit == 99 and Input_Default == ID_DP_u8 and (calcMode == CM_NORMAL or calcMode == CM_NIM);
}

// kbd_std macro: select the layout table by calcModel.
inline fn kbdStd() [*c]const calcKey_t {
    if (comptime !dmcp_build) {
        return if (calcModel == USER_C47) kbd_std_C47 else if (calcModel == USER_DM42) kbd_std_DM42 else if (calcModel == USER_R47f_g) kbd_std_R47f_g else if (calcModel == USER_R47bk_fg) kbd_std_R47bk_fg else if (calcModel == USER_R47fg_bk) kbd_std_R47fg_bk else if (calcModel == USER_R47fg_g) kbd_std_R47fg_g else if (calcModel == USER_E47) kbd_std_E47 else if (calcModel == USER_D47) kbd_std_D47 else if (calcModel == USER_V47) kbd_std_V47 else if (calcModel == USER_N47) kbd_std_N47 else if (calcModel == USER_DM42) kbd_std_DM42 else kbd_std_C47;
    } else {
        return if (calcModel == USER_C47) kbd_std_C47 else if (calcModel == USER_DM42) kbd_std_DM42 else if (calcModel == USER_R47f_g) kbd_std_R47f_g else if (calcModel == USER_R47bk_fg) kbd_std_R47bk_fg else if (calcModel == USER_R47fg_bk) kbd_std_R47fg_bk else if (calcModel == USER_R47fg_g) kbd_std_R47fg_g else kbd_std_C47;
    }
}
// Norm_Key_00_key macro
inline fn normKey00Key() i32 {
    return if (calcModel == USER_C47) 0 else if (calcModel == USER_DM42) 0 else if (calcModel == USER_R47f_g) -1 else if (calcModel == USER_R47bk_fg) 10 else if (calcModel == USER_R47fg_bk) 11 else -1;
}
// Norm_Key_00_item_in_layout macro
inline fn normKey00ItemInLayout() i16 {
    return if (calcModel == USER_C47) ITM_SIGMAPLUS else if (calcModel == USER_DM42) ITM_SIGMAPLUS else if (calcModel == USER_R47f_g) -1 else if (calcModel == USER_R47bk_fg) @as(i16, @intCast(ITM_NULL)) else if (calcModel == USER_R47fg_bk) @as(i16, @intCast(ITM_NULL)) else -1;
}

// SET_ST(STAT_PGM_END): set the bit in the fixed-address sdb.calc_state word.
inline fn setStatPgmEnd() void {
    const calc_state: *volatile u32 = @ptrFromInt(SDB_BASE);
    calc_state.* |= STAT_PGM_END;
}

// ===========================================================================
// Preserved bridge helpers (other owners extern these).
// ===========================================================================
pub fn z47_frontier_push_u32_to_x(value: u32) void {
    var tmp: mpz_struct = undefined;
    liftStack();
    mpz_init(&tmp);
    mpz_set_ui(&tmp, value);
    frontier_register_value_conversions.convertLongIntegerToLongIntegerRegister(&tmp, REGISTER_X);
    mpz_clear(&tmp);
}

pub fn z47_frontier_release_saved_statistical_sums() void {
    if (savedStatisticalSumsPointer != null) {
        freeC47Blocks(savedStatisticalSumsPointer, NUMBER_OF_STATISTICAL_SUMS * realSizeInBlocks75);
    }
}
// REAL_SIZE_IN_BLOCKS(75) == 15
const realSizeInBlocks75: usize = 15;

pub fn z47_frontier_is_r47_fam() bool_t {
    return isR47FAM();
}

pub fn z47_frontier_keys_to_user_case() void {
    if (normKey00Key() != -1) {
        const k: usize = @intCast(normKey00Key());
        kbd_usr[k].primary = Norm_Key_00.func;
        frontier_assign.setUserKeyArgument(@intCast(@as(i32, @intCast(k)) * 6), &Norm_Key_00.funcParam);
        frontier_radio_button_catalog.fnRefreshState();
        fnSetFlag(FLAG_USER_u16);
    } else {
        Norm_Key_00.used = false;
        frontier_error.displayCalcErrorMessage(ERROR_CANNOT_ASSIGN_HERE, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
    }
}
const FLAG_USER_u16: u16 = 32788;
const ERROR_CANNOT_ASSIGN_HERE: u8 = 47;
const ERR_REGISTER_LINE: i16 = 102;
const NIM_REGISTER_LINE: i16 = 100;
const MNU_DYNAMIC: i16 = 1394;
const ITM_XEQ: i16 = 3;
const ITM_RCL: i16 = 51;

pub fn z47_frontier_keys_from_user_case() void {
    if (normKey00Key() != -1) {
        const k: usize = @intCast(normKey00Key());
        Norm_Key_00.func = kbd_usr[k].primary;
        Norm_Key_00.funcParam[0] = 0;
        Norm_Key_00.used = Norm_Key_00.func != kbdStd()[k].primary;
        const funcParam = frontier_softmenus.getNthString(userKeyLabel, @intCast(@as(i32, @intCast(k)) * 6));
        if ((funcParam[0] != 0) and ((Norm_Key_00.func == -MNU_DYNAMIC) or (Norm_Key_00.func == ITM_XEQ) or (Norm_Key_00.func == ITM_RCL))) {
            _ = strcpy(&Norm_Key_00.funcParam, frontier_softmenus.getNthString(userKeyLabel, @intCast(@as(i32, @intCast(k)) * 6)));
        }
        frontier_radio_button_catalog.fnRefreshState();
        fnClearFlag(FLAG_USER_u16);
    } else {
        Norm_Key_00.used = false;
        frontier_error.displayCalcErrorMessage(ERROR_CANNOT_ASSIGN_HERE, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
    }
}

pub fn z47_frontier_keys_user_layout_reset_case() void {
    _ = frontier_char_string.xcopy(kbd_usr, kbdStd(), SIZEOF_KBD_STD);
    Norm_Key_00.func = normKey00ItemInLayout();
    Norm_Key_00.funcParam[0] = 0;
    Norm_Key_00.used = false;
    frontier_radio_button_catalog.fnRefreshState();
    fnClearFlag(FLAG_USER_u16);
}

// ===========================================================================
// isConfigCommon (public)
// ===========================================================================
pub export fn isConfigCommon(id: u16) callconv(.c) bool_t {
    var idx: usize = 99;
    switch (id) {
        ITM_SETDFLT => idx = CFG_DFLT,
        ITM_SETCHN => idx = CFG_CHINA,
        ITM_SETEUR => idx = CFG_EUROPE,
        ITM_SETIND => idx = CFG_INDIA,
        ITM_SETJPN => idx = CFG_JAPAN,
        ITM_SETUK => idx = CFG_UK,
        ITM_SETUSA => idx = CFG_USA,
        else => {},
    }
    const cs = &configSettings[idx];
    const cmp1 = @as(i32, @intFromBool(getSystemFlag(FLAG_TDM24_i))) == @as(i32, @intCast(cs.tdm24));
    const cmp2 = @as(i32, @intFromBool(getSystemFlag(FLAG_DMY_i))) == @as(i32, @intCast(cs.dmy));
    const cmp3 = @as(i32, @intFromBool(getSystemFlag(FLAG_MDY_i))) == @as(i32, @intCast(cs.mdy));
    const cmp4 = @as(i32, @intFromBool(getSystemFlag(FLAG_YMD_i))) == @as(i32, @intCast(cs.ymd));
    const cmp5 = @as(i32, @intCast(firstGregorianDay)) == @as(i32, @intCast(cs.gregorianDay));
    const cmp6a = (@as(i32, @intCast(cs.woy)) == ITM_WOY_ISO and @as(i32, @intCast(firstDayOfWeek)) == 1 and @as(i32, @intCast(firstWeekOfYearDay)) == 4);
    const cmp6b = (@as(i32, @intCast(cs.woy)) == ITM_WOY_US and @as(i32, @intCast(firstDayOfWeek)) == 7 and @as(i32, @intCast(firstWeekOfYearDay)) == 6);
    const cmp6c = (@as(i32, @intCast(cs.woy)) == ITM_WOY_ME and @as(i32, @intCast(firstDayOfWeek)) == 6 and @as(i32, @intCast(firstWeekOfYearDay)) == 5);
    const cmp6 = (cmp6a or cmp6b or cmp6c);
    const cmp7 = (0x3FFF & @as(u32, gapItemLeft)) == (0x3FFF & @as(u32, @intCast(@as(i32, @intCast(cs.gapl)))));
    const cmp8 = @as(i32, @intCast(grpGroupingLeft)) == @as(i32, @intCast(cs.gprl));
    const cmp9 = @as(i32, @intCast(grpGroupingGr1LeftOverflow)) == @as(i32, @intCast(cs.gpr1x));
    const cmp10 = @as(i32, @intCast(grpGroupingGr1Left)) == @as(i32, @intCast(cs.gpr1));
    const cmp11 = @as(i32, @intCast(grpGroupingRight)) == @as(i32, @intCast(cs.gprr));
    const cmp12 = (0x3FFF & @as(u32, gapItemRight)) == (0x3FFF & cs.gapr);
    const cmp13 = (0x3FFF & @as(u32, gapItemRadix)) == (0x3FFF & cs.gaprx);
    const cmp14 = @as(i32, @intFromBool(getSystemFlag(FLAG_US_i))) == @as(i32, @intCast(cs.us));

    return cmp1 and (cmp2 or cmp3 or cmp4) and cmp5 and cmp6 and cmp7 and cmp8 and cmp9 and cmp10 and cmp11 and cmp12 and cmp13 and cmp14;
}
const FLAG_TDM24_i: i32 = 32768;
const FLAG_DMY_i: i32 = 49154;
const FLAG_MDY_i: i32 = 49155;
const FLAG_YMD_i: i32 = 49153;
const FLAG_US_i: i32 = 32853;

// ===========================================================================
// configCommon (public)
// ===========================================================================
pub export fn configCommon(idx: u16) callconv(.c) void {
    if (checkHP()) {
        fnSetC47(0);
    }

    const cs = &configSettings[idx];
    forceSystemFlag(FLAG_TDM24, @intCast(cs.tdm24));
    forceSystemFlag(FLAG_DMY, @intCast(cs.dmy));
    forceSystemFlag(FLAG_MDY, @intCast(cs.mdy));
    forceSystemFlag(FLAG_YMD, @intCast(cs.ymd));
    firstGregorianDay = cs.gregorianDay;
    frontier_date_time.fnSetWeekOfYearRule(@intCast(cs.woy));
    temporaryInformation = TI_DISP_JULIAN_WOY;

    frontend_settings.fnSetGapChar(@intCast(0 + cs.gapl));
    grpGroupingLeft = @intCast(cs.gprl);
    grpGroupingGr1LeftOverflow = @intCast(cs.gpr1x);
    grpGroupingGr1Left = @intCast(cs.gpr1);
    grpGroupingRight = @intCast(cs.gprr);
    frontend_settings.fnSetGapChar(@intCast(32768 + cs.gapr));
    frontend_settings.fnSetGapChar(@intCast(49152 + cs.gaprx));
    forceSystemFlag(FLAG_US, @intCast(cs.us));
}

extern var tvmIKnown: bool_t;
extern var tvmIChanges: bool_t;
extern var amortP1: u16;
extern var amortP2: u16;

// ===========================================================================
// Sett (file-local) — walk the flat Settings[] preset table for profile `grp`.
// ===========================================================================
fn Sett(grp: i16) void {
    var realt: real_t = undefined;
    const stride: usize = _numberOfGrps + 2;
    const grpU: usize = @intCast(grp);

    var ptr: i32 = -1;
    while (true) {
        ptr += 1;
        const base: usize = @as(usize, @intCast(ptr)) * stride;
        if (Settings[base + 0] == 0) break;

        if (Settings[base + 1 + grpU] != xxx) {
            const opcode = Settings[base + 0];
            const value = Settings[base + 1 + grpU];
            switch (opcode) {
                op_InputDefaultDataType => frontier_addons.fnInDefault(@intCast(value)),
                op_SigFigNumberOfDigits => display_format.fnDisplayFormatSigFig(@intCast(value)),
                op_AllNumberOfDigits => display_format.fnDisplayFormatAll(@intCast(value)),
                op_FixNumberOfDigits => display_format.fnDisplayFormatFix(@intCast(value)),
                op_RNG => exponentLimit = @intCast(value),
                op_SDIGS => significantDigits = @intCast(value),
                op_FDIGS => fractionDigits = @intCast(value),
                op_HIDE => exponentHideLimit = @intCast(value),
                op_DSTACK => displayStack = @intCast(value),
                op_CACHEDDSTACK => cachedDisplayStack = @intCast(value),
                op_ADM => currentAngularMode = @intCast(value),
                op_IPGRP => grpGroupingLeft = @intCast(value),
                op_FPGRP => grpGroupingRight = @intCast(value),
                op_IPGRP1 => grpGroupingGr1Left = @intCast(value),
                op_IPGRP1x => grpGroupingGr1LeftOverflow = @intCast(value),
                op_DenMaX => denMax = @intCast(value),
                op_TVMIKnown => tvmIKnown = (value == 1),
                op_TVMIChanges => tvmIChanges = (value == 1),
                op_AMORTP1 => amortP1 = @intCast(value),
                op_AMORTP2 => amortP2 = @intCast(value),

                RESERVED_VARIABLE_LX,
                RESERVED_VARIABLE_UX,
                RESERVED_VARIABLE_LY,
                RESERVED_VARIABLE_UY,
                RESERVED_VARIABLE_FV,
                RESERVED_VARIABLE_IPONA,
                RESERVED_VARIABLE_NPPER,
                RESERVED_VARIABLE_PMT,
                RESERVED_VARIABLE_PV,
                RESERVED_VARIABLE_PPERONA,
                RESERVED_VARIABLE_CPERONA,
                => {
                    int32ToReal(value, &realt);
                    reallocateRegister(@intCast(opcode), dtReal34, 0, amNone);
                    realToReal34(&realt, reg34(@intCast(opcode)));
                },

                2 => SetSetting(@intCast(value)),
                3 => forceSystemFlag(@intCast(@as(u32, @bitCast(value))), Settings[base + 1]),
                4 => frontend_settings.fnSetGapChar(@intCast(@as(u32, @bitCast(value)) & 0xFFFF)),
                else => {},
            }
        }
    }
}
const xxx: i32 = -10001;

// ===========================================================================
// Profile presets. SAVE_SPACE_DM42_* never defined here, so bodies are full.
// ===========================================================================
pub export fn fnSetHP35(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    frontier_date_time.getDateString(&lastStateFileOpened);
    _ = strcat(&lastStateFileOpened, ": HP35 defaults");
    fnKeyExit(0);
    fnClrMod(0);
    frontier_store.fnStoreConfig(35);

    fnClearStack(0);
    fnPi(0);

    Sett(_HP35);

    temporaryInformation = TI_NO_INFO;
    frontier_radio_button_catalog.fnRefreshState();
    screenUpdatingMode = SCRUPD_AUTO;
    frontier_screen.refreshScreen(160);
}

pub export fn fnSetJM(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    fnDrop(NOPARAM);
    resetOtherConfigurationStuff(true);
    frontier_date_time.getDateString(&lastStateFileOpened);
    _ = strcat(&lastStateFileOpened, ": Jaco defaults");

    Sett(_JM);

    roundingMode = RM_HALF_UP;
    if (!isR47FAM()) {
        keys_management.fnKeysManagement(ITM_RIBBON_C47PL);
    } else {
        keys_management.fnKeysManagement(ITM_RIBBON_R47PL);
    }

    itemToBeAssigned = ITM_op_j;
    frontier_assign.assignToMyMenu(10);
    itemToBeAssigned = ITM_op_j_pol;
    frontier_assign.assignToMyMenu(11);
    itemToBeAssigned = -MNU_RIBBONS;
    frontier_assign.assignToMyMenu(9);
    itemToBeAssigned = ITM_BOLD;
    frontier_assign.assignToMyMenu(8);
    itemToBeAssigned = -MNU_DEV;
    frontier_assign.assignToMyMenu(7);
    itemToBeAssigned = -MNU_EE;
    frontier_assign.assignToMyMenu(6);

    cachedDynamicMenu = 0;

    temporaryInformation = TI_NO_INFO;
    frontier_radio_button_catalog.fnRefreshState();
    screenUpdatingMode = SCRUPD_AUTO;
    frontier_screen.refreshScreen(161);
}

pub export fn fnSetRJ(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    resetOtherConfigurationStuff(true);
    frontier_date_time.getDateString(&lastStateFileOpened);
    _ = strcat(&lastStateFileOpened, ": RJvM defaults");

    Sett(_RJ);

    fnKeyExit(0);
    fnDrop(NOPARAM);
    fnSquare(0);
    frontier_radio_button_catalog.fnRefreshState();
    screenUpdatingMode = SCRUPD_AUTO;
    frontier_screen.refreshScreen(165);
}

// _fnSetC47 (file-local)
fn _fnSetC47(unusedButMandatoryParameter: u16) void {
    _ = unusedButMandatoryParameter;
    fnKeyExit(0);
    frontier_bufferize.addItemToBuffer(ITM_EXIT1);
    frontier_date_time.getDateString(&lastStateFileOpened);
    _ = strcat(&lastStateFileOpened, ": C47 defaults");

    Sett(_C47);

    temporaryInformation = TI_NO_INFO;
    frontier_radio_button_catalog.fnRefreshState();

    fnDrop(NOPARAM);
    fnDrop(NOPARAM);
    frontier_items.runFunction(ITM_SQUARE);
    screenUpdatingMode = SCRUPD_AUTO;
    frontier_screen.refreshScreen(162);
}

pub export fn fnSetC47(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    fnKeyExit(0);
    frontier_bufferize.addItemToBuffer(ITM_EXIT1);
    fnClrMod(0);
    _fnSetC47(0);
    frontier_recall.fnRecallConfig(35);
    lastErrorCode = 0;
    frontier_radio_button_catalog.fnRefreshState();
    screenUpdatingMode = SCRUPD_AUTO;
    frontier_screen.refreshScreen(167);
}

// ===========================================================================
// fnClrMod (public) — clear input buffers / exit modes.
// ===========================================================================
pub export fn fnClrMod(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    resetKeytimers();
    clearSystemFlag(FLAG_FRACT);
    clearSystemFlag(FLAG_IRFRAC);
    clearSystemFlag(FLAG_INTING);
    clearSystemFlag(FLAG_SOLVING);
    programRunStop = PGM_STOPPED;

    if (calcMode == CM_NIM) {
        _ = strcpy(aimBuffer, "+");
        fnKeyBackspace(0);
    }
    if (calcMode == CM_ASSIGN) {
        fnKeyExit(0);
    }
    fnKeyExit(0);
    fnKeyExit(0);
    frontier_softmenus.popSoftmenu();
    lastIntegerBase = 0;
    decodedIntegerBase = 0;
    editingLiteralType = 0;
    temporaryInformation = TI_NO_INFO;
    lastErrorCode = 0;
    currentInputVariable = INVALID_VARIABLE;
    dispBase = 0;
    frontier_softmenus.fnExitAllMenus(0);
    if (!checkHP()) {
        fnDisplayStack(4);
    } else {
        _fnSetC47(0);
        frontier_recall.fnRecallConfig(35);
        lastErrorCode = 0;
    }
    frontier_calc_mode.calcModeNormal();
    hourGlassIconEnabled = false;
    screenUpdatingMode = SCRUPD_AUTO;
    shiftF = false;
    shiftG = false;
    lastshiftF = false;
    lastshiftG = false;
    showShiftState();
    refreshModeGui();
    screenUpdatingMode &= ~SCRUPD_MANUAL_STATUSBAR;
    frontier_status_bar.refreshStatusBar();
    screenUpdatingMode = SCRUPD_AUTO;
    frontier_status_bar.forceSBupdate();
    frontier_screen.refreshScreen(166);
}
extern var editingLiteralType: u8;

// ===========================================================================
// Simple memory/word-size/rounding functions (this owner owns these).
// ===========================================================================
pub export fn fnFreeMemory(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    z47_frontier_push_u32_to_x(getFreeRamMemory());
    temporaryInformation = TI_BYTES;
}

pub export fn fnGetRoundingMode(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    frontier_addons.fnIntInputLongint(@intCast(roundingMode));
}

pub export fn fnGetWordSize(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    z47_frontier_push_u32_to_x(@intCast(shortIntegerWordSize));
    temporaryInformation = TI_BITS;
}

pub export fn fnSetWordSize(WS_in: u16) callconv(.c) void {
    const resolved = word_size_math.resolveWordSize(WS_in, shortIntegerWordSize);

    if (resolved.changed) {
        setSystemFlagChanged(SETTING_SINT_WS);
        screenUpdatingMode &= ~SCRUPD_MANUAL_STATUSBAR;
    }

    shortIntegerWordSize = resolved.word_size;
    shortIntegerMask = resolved.mask;
    shortIntegerSignBit = resolved.sign_bit;

    if (resolved.reduce) {
        var regist: calcRegister_t = REGISTER_X;
        const top = getStackTop();
        while (regist <= top) : (regist += 1) {
            if (getRegisterDataType(regist) == dtShortInteger) {
                // Register data is only 4-byte (block) aligned on the 64-bit host.
                const p: *align(4) u64 = @ptrCast(@alignCast(getRegisterDataPointer(regist)));
                p.* &= shortIntegerMask;
            }
        }
        if (getRegisterDataType(REGISTER_L) == dtShortInteger) {
            const p: *align(4) u64 = @ptrCast(@alignCast(getRegisterDataPointer(REGISTER_L)));
            p.* &= shortIntegerMask;
        }
    }

    frontier_radio_button_catalog.fnRefreshState();
}
const dtShortInteger: u32 = 8;
const REGISTER_L: calcRegister_t = 108;

pub export fn fnFreeFlashMemory(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    z47_frontier_push_u32_to_x(getFreeFlash());
}

pub export fn fnBatteryVoltage(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var value: real_t = undefined;

    liftStack();

    if (comptime !dmcp_build) {
        int32ToReal(3100, &value);
    } else {
        const tmpVbat = romGetVbat();
        int32ToReal(if (tmpVbat < vbatVIntegrated) tmpVbat else vbatVIntegrated, &value);
    }

    temporaryInformation = TI_BATTV;
    value.exponent -= 3; // value = value / 1000
    frontier_register_value_conversions.convertRealToResultRegister(&value, REGISTER_X, amNone);
}

pub export fn getFreeFlash() callconv(.c) u32 {
    return 123456789;
}

pub export fn fnGetSignificantDigits(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    frontier_addons.fnIntInputLongint(@intCast(if (significantDigits == 0) @as(i32, 34) else @as(i32, @intCast(significantDigits))));
}

pub export fn fnGetFractionDigits(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    frontier_addons.fnIntInputLongint(@intCast(if (fractionDigits == 0) @as(i32, 34) else @as(i32, @intCast(fractionDigits))));
}

pub export fn fnRoundingMode(RM: u16) callconv(.c) void {
    if (RM < roundingModeTable.len) {
        roundingMode = @intCast(RM);
        ctxtReal34.round = roundingModeTable[RM];
    } else {
        abi.fmtBufZ(errorMessage[0..512], "Value {d} for RM is out of range. ", .{@as(u32, RM)});
        _ = strcat(errorMessage, "Must be from 0 to 6");
        frontier_error.displayBugScreen(errorMessage);
    }
}

pub export fn fnGetADM(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    frontier_addons.fnIntInputLongint(@intCast(admValue()));
}

pub export fn fnSetADM(regist: u16) callconv(.c) void {
    var lgInt: mpz_struct = undefined;
    mpz_init(&lgInt);
    if (!frontier_register_value_conversions.getRegisterAsLongInt(@intCast(regist), &lgInt, null)) {
        mpz_clear(&lgInt);
        return;
    }
    const value: u32 = @intCast(mpz_get_ui(&lgInt) & 0xFFFFFFFF);
    if (adm_encoding.angularModeFromAdm(value)) |angularMode| {
        frontend_settings.fnAngularMode(angularMode);
    }
    mpz_clear(&lgInt);
}

pub export fn fnGetIntegerSignMode(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    frontier_addons.fnIntInputLongint(shortIntegerModeValue());
}

pub export fn fnSetISM(regist: u16) callconv(.c) void {
    var lgInt: mpz_struct = undefined;
    mpz_init(&lgInt);
    if (!frontier_register_value_conversions.getRegisterAsLongInt(@intCast(regist), &lgInt, null)) {
        mpz_clear(&lgInt);
        return;
    }
    const value: i32 = @intCast(mpz_get_si(&lgInt));
    switch (value) {
        2 => shortIntegerMode = SIM_2COMPL,
        1 => shortIntegerMode = SIM_1COMPL,
        0 => shortIntegerMode = SIM_UNSIGN,
        else => shortIntegerMode = SIM_SIGNMT,
    }
    mpz_clear(&lgInt);
}

pub export fn fnGetDMX(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    frontier_addons.fnIntInputLongint(@intCast(@as(i32, @bitCast(denMax))));
}

pub export fn fnSetDMX(regist: u16) callconv(.c) void {
    var lgInt: mpz_struct = undefined;
    mpz_init(&lgInt);
    if (!frontier_register_value_conversions.getRegisterAsLongInt(@intCast(regist), &lgInt, null)) {
        mpz_clear(&lgInt);
        return;
    }
    const value: u32 = @intCast(mpz_get_ui(&lgInt) & 0xFFFFFFFF);
    frontier_fractions.fnDenMax(@intCast(value & 0xFFFF));
    mpz_clear(&lgInt);
}

pub export fn fnGetREALDF(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    frontier_addons.fnIntInputLongint(@intCast(displayFormat));
}

pub export fn fnSetREALDF(regist: u16) callconv(.c) void {
    var lgInt: mpz_struct = undefined;
    mpz_init(&lgInt);
    if (!frontier_register_value_conversions.getRegisterAsLongInt(@intCast(regist), &lgInt, null)) {
        mpz_clear(&lgInt);
        return;
    }
    const value: u32 = @intCast(mpz_get_ui(&lgInt) & 0xFFFFFFFF);
    if (value <= DF_UN) {
        displayFormat = @intCast(value);
    }
    mpz_clear(&lgInt);
}

pub export fn fnGetNDEC(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    frontier_addons.fnIntInputLongint(@intCast(displayFormatDigits));
}

pub export fn fnSetNDEC(regist: u16) callconv(.c) void {
    var lgInt: mpz_struct = undefined;
    mpz_init(&lgInt);
    if (!frontier_register_value_conversions.getRegisterAsLongInt(@intCast(regist), &lgInt, null)) {
        mpz_clear(&lgInt);
        return;
    }
    const value: u32 = @intCast(mpz_get_ui(&lgInt) & 0xFFFFFFFF);
    display_format.fnDisplayFormatDsp(@intCast(value & 0xFFFF));
    mpz_clear(&lgInt);
}

// ===========================================================================
// Confirmation messages table + helpers.
// ===========================================================================
// Exported: screen.c (the engine) reads confirmationTI[] for the confirmation
// message lookup.
pub export const confirmationTI linksection(code_data_section) = [11]confirmationTI_t{
    .{ .item = ITM_DELALL, .string = strBuf("Delete all?") },
    .{ .item = ITM_CLFALL, .string = strBuf("Clear all flags?") },
    .{ .item = ITM_DELPALL, .string = strBuf("Delete all programs?") },
    .{ .item = ITM_CLREGS, .string = strBuf("Clear registers?") },
    .{ .item = ITM_RESET, .string = strBuf("Reset?") },
    .{ .item = ITM_DELBKUP, .string = strBuf("Delete both backup files?") },
    .{ .item = ITM_CLMALL, .string = strBuf("Clear all user menus?") },
    .{ .item = ITM_CLVALL, .string = strBuf("Clear all user variables?") },
    .{ .item = ITM_DELMALL, .string = strBuf("Delete all user menus?") },
    .{ .item = ITM_DELVALL, .string = strBuf("Delete all user variables?") },
    .{ .item = 0, .string = strBuf("Are you sure?") },
};

fn strBuf(comptime s: []const u8) [30]u8 {
    var b: [30]u8 = std.mem.zeroes([30]u8);
    @memcpy(b[0..s.len], s);
    return b;
}

const LAST_ITEM: u16 = 2870;

pub export fn getConfirmationTiId() callconv(.c) u16 {
    var id: u16 = 0;
    var item: u16 = 0;
    while (id < LAST_ITEM) : (id += 1) {
        if (indexOfItems[id].func == confirmedFunction) {
            item = id;
            break;
        }
    }
    id = 0;
    while (confirmationTI[id].item != 0) {
        if (confirmationTI[id].item == @as(i16, @bitCast(item))) {
            break;
        }
        id += 1;
    }
    return id;
}

pub export fn setConfirmationMode(func: ConfirmedFn) callconv(.c) void {
    previousCalcMode = calcMode;
    cursorEnabled = false;
    calcMode = CM_CONFIRMATION;
    clearSystemFlag(FLAG_ALPHA);
    confirmedFunction = func;
    temporaryInformation = TI_ARE_YOU_SURE;
    frontier_softmenus.showSoftmenu(-MNU_YESNO);
}
const FLAG_ALPHA: c_uint = 32782;

// ===========================================================================
// initSimEqMatABX (public)
// ===========================================================================
pub export fn initSimEqMatABX() callconv(.c) void {
    var matrixHeader: *matrixHeader_t = undefined;

    allocateNamedVariable("Mat_A", dtReal34Matrix, @intCast(REAL34_SIZE_IN_BLOCKS + toBlocks(@intCast(@sizeOf(matrixHeader_t)))));
    matrixHeader = abi.registerMatrixHeaderAligned(FIRST_NAMED_VARIABLE);
    setMatrixDims(matrixHeader, 1, 1);
    real34SetZero(matrixElementsAfterHeader(matrixHeader));

    allocateNamedVariable("Mat_B", dtReal34Matrix, @intCast(REAL34_SIZE_IN_BLOCKS + toBlocks(@intCast(@sizeOf(matrixHeader_t)))));
    matrixHeader = abi.registerMatrixHeaderAligned(FIRST_NAMED_VARIABLE + 1);
    setMatrixDims(matrixHeader, 1, 1);
    real34SetZero(matrixElementsAfterHeader(matrixHeader));

    allocateNamedVariable("Mat_X", dtReal34Matrix, @intCast(REAL34_SIZE_IN_BLOCKS + toBlocks(@intCast(@sizeOf(matrixHeader_t)))));
    matrixHeader = abi.registerMatrixHeaderAligned(FIRST_NAMED_VARIABLE + 2);
    setMatrixDims(matrixHeader, 1, 1);
    real34SetZero(matrixElementsAfterHeader(matrixHeader));
}
// matrixHeader bit-fields: matrixRows:12, matrixColumns:12, mtag:6, notUsed:2.
inline fn setMatrixDims(h: *matrixHeader_t, rows: u32, cols: u32) void {
    h.matrixRows = @truncate(rows);
    h.matrixColumns = @truncate(cols);
}
// REAL34_MATRIX_ELEMENTS_AFTER_MATRIX_HEADER(ptr): (real34_t*)((matrixHeader_t*)ptr + 1)
inline fn matrixElementsAfterHeader(h: *matrixHeader_t) *real34_t {
    const p: [*]matrixHeader_t = @ptrCast(h);
    return @ptrCast(@alignCast(p + 1));
}

// ===========================================================================
// Test data tables (file-local), used by doFnReset to populate registers and
// by searchMsg/fnShowVersion for KEYS version messages.
// ===========================================================================
const STD_CROSS = "\x80\xd7";
const STD_f = "\x66";
const STD_g = "\x67";
const STD_fg = "\xa9\xf1";
const STD_BOX = "\xa5\xa2";
const STD_alpha = "\x83\xb1";

const indexOfStrings = [_]numberstr{
    .{ .itemType = 0, .count = 10, .itemName = "Reg 11, 12 & 13 have: The 3 cubes = 3." },
    .{ .itemType = 1, .count = 11, .itemName = "569936821221962380720" },
    .{ .itemType = 1, .count = 12, .itemName = "-569936821113563493509" },
    .{ .itemType = 1, .count = 13, .itemName = "-472715493453327032" },
    .{ .itemType = 0, .count = 14, .itemName = "Reg 15, 16 & 17 have: The 3 cubes = 42." },
    .{ .itemType = 1, .count = 15, .itemName = "-80538738812075974" },
    .{ .itemType = 1, .count = 16, .itemName = "80435758145817515" },
    .{ .itemType = 1, .count = 17, .itemName = "12602123297335631" },
    .{ .itemType = 0, .count = 18, .itemName = "37 digits of pi, Reg19 / Reg20." },
    .{ .itemType = 1, .count = 19, .itemName = "2646693125139304345" },
    .{ .itemType = 1, .count = 20, .itemName = "842468587426513207" },
    .{ .itemType = 0, .count = 21, .itemName = "Primes: Carol" },
    .{ .itemType = 1, .count = 22, .itemName = "18014398241046527" },
    .{ .itemType = 0, .count = 23, .itemName = "Primes: Kynea" },
    .{ .itemType = 1, .count = 24, .itemName = "18446744082299486207" },
    .{ .itemType = 0, .count = 25, .itemName = "Primes: repunit" },
    .{ .itemType = 1, .count = 26, .itemName = "7369130657357778596659" },
    .{ .itemType = 0, .count = 27, .itemName = "Primes: Woodal" },
    .{ .itemType = 1, .count = 28, .itemName = "195845982777569926302400511" },
    .{ .itemType = 0, .count = 29, .itemName = "Primes: Woodal" },
    .{ .itemType = 1, .count = 30, .itemName = "4776913109852041418248056622882488319" },
    .{ .itemType = 0, .count = 31, .itemName = "Primes: Woodal" },
    .{ .itemType = 1, .count = 32, .itemName = "225251798594466661409915431774713195745814267044878909733007331390393510002687" },
    .{ .itemType = 0, .count = 33, .itemName = "pi.(10^100) (101 digits) longinteger" },
    .{ .itemType = 1, .count = 34, .itemName = "31415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170680" },
    .{ .itemType = 0, .count = 36, .itemName = "100 primes' product 2x3x...x541" },
    .{ .itemType = 1, .count = 37, .itemName = "4711930799906184953162487834760260422020574773409675520188634839616415335845034221205289256705544681972439104097777157991804380284218315038719444943990492579030720635990538452312528339864352999310398481791730017201031090" },
    .{ .itemType = 0, .count = 38, .itemName = "Heart:16" ++ STD_CROSS ++ "(sin(t)^3)+i" ++ STD_CROSS ++ "(13" ++ STD_CROSS ++ "cos(t)-5" ++ STD_CROSS ++ "cos(2" ++ STD_CROSS ++ "t)-2" ++ STD_CROSS ++ "cos(3" ++ STD_CROSS ++ "t)-cos(4" ++ STD_CROSS ++ "t))" },
};

const USER_C47_msg: u16 = 46;
const USER_R47f_g_msg: u16 = 61;
const USER_R47bk_fg_msg: u16 = 62;
const USER_R47fg_bk_msg: u16 = 63;
const USER_R47fg_g_msg: u16 = 64;
const USER_DM42_msg: u16 = 45;
const USER_HRESET_msg: u16 = 58;
const USER_PRESET_msg: u16 = 59;
const USER_KRESET_msg: u16 = 50;
const USER_MRESET_msg: u16 = 49;
const USER_ARESET_msg: u16 = 48;
const ITM_RIBBON_ENG_msg: u16 = 2513;
const ITM_RIBBON_FIN_msg: u16 = 2507;
const ITM_RIBBON_FIN2_msg: u16 = 2514;
const ITM_RIBBON_CPX_msg: u16 = 2506;
const ITM_RIBBON_SAV_msg: u16 = 2508;
const ITM_RIBBON_SAV2_msg: u16 = 2515;
const ITM_RIBBON_C47_msg: u16 = 2509;
const ITM_RIBBON_C47PL_msg: u16 = 2510;
const ITM_RIBBON_R47_msg: u16 = 2511;
const ITM_RIBBON_R47PL_msg: u16 = 2512;

const indexOfMsgs = [_]numberstr{
    .{ .itemType = 0, .count = USER_C47_msg, .itemName = "C47: Classic single shift (DM42/DM42n base)" },
    .{ .itemType = 0, .count = USER_R47f_g_msg, .itemName = "R47v0 L.Shift is " ++ STD_f ++ ", R.Shift is " ++ STD_g },
    .{ .itemType = 0, .count = USER_R47bk_fg_msg, .itemName = "R47v3 L.Shift is " ++ STD_BOX ++ ", R.Shift is " ++ STD_fg },
    .{ .itemType = 0, .count = USER_R47fg_bk_msg, .itemName = "R47v1 L.Shift is " ++ STD_fg ++ ", R.Shift is " ++ STD_BOX },
    .{ .itemType = 0, .count = USER_R47fg_g_msg, .itemName = "R47v2 L.Shift is " ++ STD_fg ++ ", R.Shift is " ++ STD_g },
    .{ .itemType = 0, .count = USER_DM42_msg, .itemName = "DM42: Final Compatibility layout" },
    .{ .itemType = 0, .count = USER_HRESET_msg, .itemName = "HOME menu reset to default" },
    .{ .itemType = 0, .count = USER_PRESET_msg, .itemName = "P.FN menu reset to default" },
    .{ .itemType = 0, .count = USER_KRESET_msg, .itemName = "Key assignments cleaned" },
    .{ .itemType = 0, .count = USER_MRESET_msg, .itemName = "MyMenu menu cleaned" },
    .{ .itemType = 0, .count = USER_ARESET_msg, .itemName = "My" ++ STD_alpha ++ " menu cleaned" },
    .{ .itemType = 0, .count = ITM_RIBBON_ENG_msg, .itemName = "MyMenu primary F-key engineering ribbon" },
    .{ .itemType = 0, .count = ITM_RIBBON_FIN_msg, .itemName = "MyMenu primary F-key financial ribbon" },
    .{ .itemType = 0, .count = ITM_RIBBON_FIN2_msg, .itemName = "MyMenu primary F-key financial ribbon 2" },
    .{ .itemType = 0, .count = ITM_RIBBON_CPX_msg, .itemName = "MyMenu primary F-key complex ribbon" },
    .{ .itemType = 0, .count = ITM_RIBBON_SAV_msg, .itemName = "MyMenu primary F-key save/load ribbon" },
    .{ .itemType = 0, .count = ITM_RIBBON_SAV2_msg, .itemName = "MyMenu primary F-key save/load ribbon 2" },
    .{ .itemType = 0, .count = ITM_RIBBON_C47_msg, .itemName = "MyMenu primary C47 F-key ribbon" },
    .{ .itemType = 0, .count = ITM_RIBBON_C47PL_msg, .itemName = "MyMenu primary C47 Plus F-key ribbon" },
    .{ .itemType = 0, .count = ITM_RIBBON_R47_msg, .itemName = "MyMenu primary R47 F-key ribbon" },
    .{ .itemType = 0, .count = ITM_RIBBON_R47PL_msg, .itemName = "MyMenu primary R47 Plus F-key ribbon" },
    .{ .itemType = 0, .count = 100, .itemName = "Error List" },
};

pub export fn searchMsg(idStr: u16) callconv(.c) u16 {
    const n: usize = indexOfMsgs.len;
    var i: usize = 0;
    while (i < n) : (i += 1) {
        if (indexOfMsgs[i].count == idStr) {
            break;
        }
    }
    return @intCast(i);
}

const TI_KEYS: u8 = 59;
const SCRUPD_MANUAL_STACK: u8 = 2;
const SCRUPD_SKIP_STACK_ONE_TIME: u8 = 32;

pub export fn fnShowVersion(option: u16) callconv(.c) void {
    _ = strcpy(errorMessage, indexOfMsgs[searchMsg(option)].itemName);
    temporaryInformation = TI_KEYS;
    screenUpdatingMode &= ~(SCRUPD_MANUAL_STACK | SCRUPD_SKIP_STACK_ONE_TIME);
}

pub export fn fnResetTVM(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    Sett(_TVM);
}

pub export fn defaultStatusBar() callconv(.c) void {
    Sett(_DefltSB);
}

pub export fn restoreStats() callconv(.c) void {
    if (lrChosen != 65535) {
        lrChosen = lrChosenHistobackup;
    }
    if (lrSelection != 65535) {
        lrSelection = lrSelectionHistobackup;
    }
    _ = strcpy(&statMx, "STATS");
    lrSelectionHistobackup = 65535;
    lrChosenHistobackup = 65535;
    frontier_stats.calcSigma(0);
}

// ===========================================================================
// resetOtherConfigurationStuff (public)
// ===========================================================================
const SIM_2COMPL_v: u8 = 2;
const ID_43S_u8: u8 = 0;
pub export fn resetOtherConfigurationStuff(allowUserKeys: bool_t) callconv(.c) void {
    cancelFilename = true;
    lastStateFileOpened[0] = 0;

    firstGregorianDay = 2361222;
    displayFormat = DF_ALL;
    displayFormatDigits = 3;
    timeDisplayFormatDigits = 0;

    shortIntegerMode = SIM_2COMPL_v;
    fnSetWordSize(64);
    roundingMode = RM_HALF_EVEN;
    pcg32_srandom(0x1963073019931121, 0x1995062319981019);
    exponentHideLimit = 0;
    lastCenturyHighUsed = 0;
    lrSelection = CF_LINEAR_FITTING;
    lrSelectionUndo = lrSelection;

    IrFractionsCurrentStatus = CF_NORMAL;
    if (allowUserKeys) {
        Norm_Key_00.func = normKey00ItemInLayout();
        Norm_Key_00.funcParam[0] = 0;
        Norm_Key_00.used = false;
    }
    Input_Default = ID_43S_u8;
    displayStackSHOIDISP = 2;
    bcdDisplaySign = BCDu;
    DRG_Cycling = 0;
    DM_Cycling = 0;
    LongPressM = RBX_M1234;
    LongPressF = RBX_F124;
    lastIntegerBase = 0;
    decodedIntegerBase = 0;
    timeLastOp = 0;
    timeLastOp0 = 0;
    timeLastOp1 = 0;
    dispBase = 0;

    lastI = 0;
    lastI = 0;
    lastFunc = 0;
    lastParam = 0;
    lastTemp[0] = 0;

    blockMonitoring = false;
}

// ===========================================================================
// setLongPressFg (public)
// ===========================================================================
pub export fn setLongPressFg(calcModel0: c_int, menuItem: i16) callconv(.c) void {
    var keyCode: i16 = 9999;
    switch (calcModel0) {
        USER_R47f_g => keyCode = 9999,
        USER_R47bk_fg => keyCode = 11,
        USER_R47fg_bk => keyCode = 10,
        USER_R47fg_g => keyCode = 10,
        USER_C47 => keyCode = 27,
        USER_DM42 => keyCode = 27,
        else => {},
    }
    if (keyCode != 9999) {
        const key_assign_test = &kbd_usr[@intCast(keyCode)];
        key_assign_test.fShifted = menuItem;
    }
}

// ===========================================================================
// msg2 / glyphNotFound bitmap (file-local).
// ===========================================================================
const msg2 = [_]nstr2{
    .{ .str2 = blk: {
        var b: [180]u8 = std.mem.zeroes([180]u8);
        const lit = "\xff\xf8\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\xff\xf8";
        @memcpy(b[0..lit.len], lit);
        break :blk b;
    } },
};

// ===========================================================================
// addTestPrograms (file-local). SAVE_SPACE_DM42_14 never defined here.
// ===========================================================================
fn addTestPrograms() void {
    const numberOfBytesForTheTestPrograms: u32 = toBytes(toBlocks(24000)); // upstream 90b263136: 22000 -> 24000
    var numberOfBytesUsed: u32 = 0;

    resizeProgramMemory(@intCast(toBlocks(numberOfBytesForTheTestPrograms)));
    firstDisplayedStep = beginOfProgramMemory;
    currentStep = beginOfProgramMemory;
    currentLocalStepNumber = 1;
    firstDisplayedLocalStepNumber = 0;

    if (comptime dmcp_build) {
        const sdb_ppgm_fp: *?*anyopaque = @ptrFromInt(SDB_BASE + SDB_PPGM_FP_OFF);
        if (romFOpen(sdb_ppgm_fp.*, "testPgms.bin", FA_READ) != FR_OK) {
            beginOfProgramMemory[0] = 255;
            beginOfProgramMemory[1] = 255;
            firstFreeProgramByte = beginOfProgramMemory;
            freeProgramBytes = @intCast(numberOfBytesForTheTestPrograms - 2);
        } else {
            var bytesRead: c_uint = 0;
            _ = romFRead(sdb_ppgm_fp.*, &numberOfBytesUsed, @sizeOf(@TypeOf(numberOfBytesUsed)), &bytesRead);
            _ = romFRead(sdb_ppgm_fp.*, beginOfProgramMemory, numberOfBytesUsed, &bytesRead);
            _ = romFClose(sdb_ppgm_fp.*);

            firstFreeProgramByte = beginOfProgramMemory + (numberOfBytesUsed - 2);
            freeProgramBytes = @intCast(numberOfBytesForTheTestPrograms - numberOfBytesUsed);
        }
        frontier_manage.scanLabelsAndPrograms();
    } else {
        const testPgmsOpt = fopen("res/testPgms/testPgms.bin", "rb");
        if (testPgmsOpt == null) {
            _ = printf("Cannot open file res/testPgms/testPgms.bin\n");
            beginOfProgramMemory[0] = 255;
            beginOfProgramMemory[1] = 255;
            firstFreeProgramByte = beginOfProgramMemory;
            freeProgramBytes = @intCast(numberOfBytesForTheTestPrograms - 2);
        } else {
            const testPgms = testPgmsOpt.?;
            _ = fread(&numberOfBytesUsed, 1, @sizeOf(@TypeOf(numberOfBytesUsed)), testPgms);
            _ = printf("%u bytes\n", numberOfBytesUsed);
            if (numberOfBytesUsed > numberOfBytesForTheTestPrograms) {
                _ = printf("Increase allocated memory for programs! File config.c 1st line of function addTestPrograms\n");
                _ = fclose(testPgms);
                exit(0);
            }
            _ = fread(beginOfProgramMemory, 1, numberOfBytesUsed, testPgms);
            _ = fclose(testPgms);

            firstFreeProgramByte = beginOfProgramMemory + (numberOfBytesUsed - 2);
            freeProgramBytes = @intCast(numberOfBytesForTheTestPrograms - numberOfBytesUsed);
        }

        _ = printf("freeProgramBytes = %u\n", @as(c_uint, freeProgramBytes));

        frontier_manage.scanLabelsAndPrograms();
        leavePem();
        _ = printf("freeProgramBytes = %u\n", @as(c_uint, freeProgramBytes));
    }
}
const FA_READ: c_int = 0x01;
const FR_OK: c_int = 0;
// sdb layout: volatile uint32_t calc_state; FIL *ppgm_fp; ... -> ppgm_fp at +4.
const SDB_PPGM_FP_OFF: usize = 4;
extern fn fopen(path: [*:0]const u8, mode: [*:0]const u8) ?*anyopaque;
extern fn fread(ptr: *anyopaque, size: usize, nmemb: usize, stream: *anyopaque) usize;
extern fn fclose(stream: *anyopaque) c_int;
extern fn exit(code: c_int) noreturn;
extern fn leavePem() void;

// ===========================================================================
// fnReset / doFnReset (public) — test-reachable reset machinery.
// ===========================================================================
pub export fn fnReset(confirmation: u16) callconv(.c) void {
    doFnReset(confirmation, doNotLoadAutoSav);
}

pub export fn doFnReset(confirmation: u16, autoSav: bool_t) callconv(.c) void {
    if (confirmation == NOT_CONFIRMED) {
        setConfirmationMode(&fnReset);
    } else {
        var memPtr: ?*anyopaque = undefined;

        if (ram == null) {
            ram = @ptrCast(@alignCast(malloc(toBytes(RAM_SIZE_IN_BLOCKS))));
        }
        _ = memset(ram, 0, toBytes(RAM_SIZE_IN_BLOCKS));

        // #if !defined(DMCP_BUILD) || !defined(OLD_HW): malloc the pointer-form
        // globalRegister/freeMemoryRegions (host + new_hw firmware).
        if (comptime !globalRegister_is_array) {
            if (globalRegister_ptr.* == null) {
                globalRegister_ptr.* = malloc(@sizeOf(registerHeader_t) * NUMBER_OF_GLOBAL_REGISTERS);
                freeMemoryRegions_ptr.* = malloc(@sizeOf(freeMemoryRegion_t) * MAX_FREE_REGIONS);
            }
        }

        const lastResIdx = LAST_RESERVED_VARIABLE - FIRST_RESERVED_VARIABLE;
        const lastResBlk = (allReservedVariables[lastResIdx].header.descriptor & 0xFFFF) + REAL34_SIZE_IN_BLOCKS;
        const region0Addr = toC47MemPtr(@ptrCast(ram + lastResBlk));
        freeRegion0().blockAddress = region0Addr;
        freeRegion0().sizeInBlocks = @intCast(RAM_SIZE_IN_BLOCKS - region0Addr - 1);

        numberOfFreeMemoryRegions = 1;

        if (comptime !dmcp_build) {
            numberOfAllocatedMemoryRegions = 0;
        }

        if (tmpString == null) {
            if (comptime dmcp_build) {
                tmpString = romAuxBufPtr();
                errorMessage = @ptrCast(romWriteBufPtr());
            } else {
                tmpString = @ptrCast(malloc(TMP_STR_LENGTH));
                errorMessage = @ptrCast(malloc(WRITE_BUFFER_LEN));
            }

            aimBuffer = errorMessage + ERROR_MESSAGE_LENGTH;
            nimBufferDisplay = aimBuffer + AIM_BUFFER_LENGTH;
            tamBuffer = nimBufferDisplay + NIM_BUFFER_LENGTH;
            tmpStringLabelOrVariableName = tmpString + 1000;
        }
        _ = memset(tmpString, 0, TMP_STR_LENGTH);
        _ = memset(errorMessage, 0, ERROR_MESSAGE_LENGTH);
        _ = memset(aimBuffer, 0, AIM_BUFFER_LENGTH);
        _ = memset(nimBufferDisplay, 0, NIM_BUFFER_LENGTH);
        _ = memset(tamBuffer, 0, TAM_BUFFER_LENGTH);

        beginOfProgramMemory = @ptrCast(ram + (RAM_SIZE_IN_BLOCKS - 1));
        currentStep = beginOfProgramMemory;
        firstFreeProgramByte = beginOfProgramMemory + 2;
        firstDisplayedStep = beginOfProgramMemory;
        firstDisplayedLocalStepNumber = 0;
        labelList = null;
        programList = null;
        beginOfProgramMemory[0] = @intCast((ITM_END >> 8) | 0x80);
        beginOfProgramMemory[1] = @intCast(ITM_END & 0xff);
        beginOfProgramMemory[2] = 255;
        beginOfProgramMemory[3] = 255;
        freeProgramBytes = 0;

        frontier_manage.scanLabelsAndPrograms();

        if (glyphNotFound.data == null) {
            glyphNotFound.data = @ptrCast(malloc(38));
        }
        _ = frontier_char_string.xcopy(glyphNotFound.data, &msg2[0].str2, 38);

        _ = frontier_char_string.xcopy(kbd_usr, kbdStd(), SIZEOF_KBD_STD);

        // 9 real34 reserved variables: ACC..PV
        {
            var i: usize = VAR_NO_ACC;
            while (i <= VAR_NO_PV) : (i += 1) {
                real34SetZero(reservedReal34(i));
            }
        }

        // 1 long integer reserved variable: GRAMOD
        {
            const hdr = reservedStrLgHdr(VAR_NO_GRAMOD);
            if (@bitSizeOf(usize) == 64) {
                hdr[0].dataMaxLengthInBlocks = @intCast(toBlocks(8));
                const p: *align(4) i64 = @ptrCast(@alignCast(hdr + 1));
                p.* = 0;
            } else {
                hdr[0].dataMaxLengthInBlocks = @intCast(toBlocks(4));
                const p: *align(4) i32 = @ptrCast(@alignCast(hdr + 1));
                p.* = 0;
            }
        }

        // 7 real34 reserved variables: UX..LY
        {
            var i: usize = VAR_NO_UX;
            while (i <= VAR_NO_LY) : (i += 1) {
                real34SetZero(reservedReal34(i));
            }
        }

        // #if DMCP_BUILD && OLD_HW: globalRegister is the static array; memset the
        // whole array (sizeof(globalRegister)).
        if (comptime globalRegister_is_array) {
            _ = memset(globalRegister_array, 0, @sizeOf(registerHeader_t) * NUMBER_OF_GLOBAL_REGISTERS);
        }
        {
            var regist: calcRegister_t = FIRST_GLOBAL_REGISTER;
            while (regist <= LAST_GLOBAL_REGISTER) : (regist += 1) {
                setRegisterDataType(regist, dtReal34, amNone);
                memPtr = allocC47Blocks(REAL34_SIZE_IN_BLOCKS);
                setRegisterDataPointer(regist, memPtr.?);
                real34SetZero(@ptrCast(@alignCast(memPtr.?)));
            }
        }

        _ = memset(&globalFlags, 0, @sizeOf(@TypeOf(globalFlags)));

        allSubroutineLevels.numberOfSubroutineLevels = 1;
        currentSubroutineLevelData = @ptrCast(@alignCast(allocC47Blocks(3)));
        allSubroutineLevels.ptrToSubroutineLevel0Header = toC47MemPtr(@ptrCast(currentSubroutineLevelData));
        currentSubroutineLevelData.*.returnProgramNumber = 0;
        currentSubroutineLevelData.*.returnLocalStep = 0;
        currentSubroutineLevelData.*.numberOfLocalRegisters = 0;
        currentSubroutineLevelData.*.numberOfLocalFlags = 0;
        currentSubroutineLevelData.*.subroutineLevel = 0;
        currentSubroutineLevelData.*.ptrToNextLevel = C47_NULL;
        currentSubroutineLevelData.*.ptrToPreviousLevel = C47_NULL;
        currentLocalFlags = null;
        currentLocalRegisters = null;

        numberOfNamedVariables = 0;
        allNamedVariables = null;

        initSimEqMatABX();

        matrixIndex = INVALID_VARIABLE;

        _ = decContextDefault(&ctxtReal34, DEC_INIT_DECQUAD);

        _ = decContextDefault(&ctxtReal4, DEC_INIT_DECSINGLE);
        ctxtReal4.digits = 6;
        ctxtReal4.traps = 0;

        _ = decContextDefault(&ctxtReal39, DEC_INIT_DECQUAD);
        ctxtReal39.digits = 39;
        ctxtReal39.emax = 999999;
        ctxtReal39.emin = -999999;
        ctxtReal39.traps = 0;

        _ = decContextDefault(&ctxtReal51, DEC_INIT_DECQUAD);
        ctxtReal51.digits = 51;
        ctxtReal51.emax = 999999;
        ctxtReal51.emin = -999999;
        ctxtReal51.traps = 0;

        _ = decContextDefault(&ctxtReal75, DEC_INIT_DECQUAD);
        ctxtReal75.digits = 75;
        ctxtReal75.emax = 999999;
        ctxtReal75.emin = -999999;
        ctxtReal75.traps = 0;

        resetOtherConfigurationStuff(true);

        statisticalSumsPointer = null;
        savedStatisticalSumsPointer = null;
        statisticalSumsUpdate = true;
        lrChosen = 0;
        lrChosenUndo = 0;
        lastPlotMode = PLOT_NOTHING;
        plotSelection = 0;
        drawHistogram = 0;
        frontier_real_type.realSetZero(&SAVED_SIGMA_LASTX);
        frontier_real_type.realSetZero(&SAVED_SIGMA_LASTY);
        SAVED_SIGMA_lastAddRem = SIGMA_NONE;

        plotStatMx[0] = 0;
        regStatsXY = INVALID_VARIABLE;
        real34SetZero(&loBinR);
        real34SetZero(&nBins);
        real34SetZero(&hiBinR);
        histElementXorY = -1;

        // x_min/x_max/y_min/y_max are real_t *const; write through the pointers
        // exactly as config.c does (int32ToReal / realSetZero / realCopy(const_1)).
        int32ToReal(-10, x_min);
        int32ToReal(10, x_max);
        frontier_real_type.realSetZero(y_min);
        realCopy(consts.const_1(), y_max);

        systemFlags0 = 0;
        systemFlags1 = 0;
        clearScreen(202);

        Sett(_Reset);

        configCommon(CFG_DFLT);

        hourGlassIconEnabled = false;
        watchIconEnabled = false;
        serialIOIconEnabled = false;
        printerIconEnabled = false;
        thereIsSomethingToUndo = false;
        pemCursorIsZerothStep = true;
        tam_alpha_set(false);
        fnKeyInCatalog = false;
        shiftF = false;
        shiftG = false;
        lastshiftF = false;
        lastshiftG = false;
        secTick1 = false;
        halfSecTick2 = false;
        halfSecTick3 = false;
        skippedStackLines = false;
        iterations = false;
        explicitTaylorIterVisibilitySelection = false;
        updateOldConstants = false;
        programRunStop = PGM_STOPPED;

        ctxtReal34.round = DEC_ROUND_HALF_EVEN;

        frontier_font_browser.initFontBrowser();
        currentAsnScr = 1;
        currentFlgScr = NO_SCREEN;
        lastFlgScr = NO_SCREEN;
        currentRegisterBrowserScreen = 9999;

        _ = memset(&softmenuStack, 0, @sizeOf(@TypeOf(softmenuStack)));
        menuPageNumber = 1;

        aimBuffer[0] = 0;
        lastErrorCode = 0;
        previousErrorCode = 0;

        frontier_bufferize.resetAlphaSelectionBuffer();

        if (calcMode == CM_MIM) {
            matrix_lifecycle.mimFinalize();
        }

        clearScreen(10);
        frontier_calc_mode.calcModeNormal();

        if (comptime !dmcp_build) {
            forceTamAlpha = false;
            deadKey = 0;
        }

        tam_mode_set(0);
        catalog = CATALOG_NONE;
        _ = memset(&lastCatalogPosition, 0, NUMBER_OF_CATALOGS * @sizeOf(i16));
        lastDenominator = 4;
        temporaryInformation = TI_RESET;

        currentInputVariable = INVALID_VARIABLE;
        currentMvarLabel = INVALID_VARIABLE;
        lastKeyCode = 0;
        entryStatus = 0;
        lastUserMode = false;
        lastItem = 0;

        _ = memset(&userMenuItems, 0, @sizeOf(userMenuItem_t) * 18);
        _ = memset(&userAlphaItems, 0, @sizeOf(userMenuItem_t) * 18);
        userMenus = null;
        numberOfUserMenus = 0;
        currentUserMenu = 0;

        frontier_assign.initUserKeyArgument();

        frontier_programmable_menu.fnClearMenu(NOPARAM);

        frontier_calc_mode.calcModeNormal();
        if (getSystemFlag(FLAG_BASE_HOME)) {
            frontier_softmenus.showSoftmenu(-MNU_HOME);
        }

        showRegis = 9999;
        overrideShowBottomLine = 0;

        frontier_graphs.graph_reset();

        ListXYposition = 0;

        fnClrMod(0);

        displayAIMbufferoffset = 0;
        T_cursorPos = 0;
        yMultiLineEdOffset = 0;
        xMultiLineEdOffset = 0;
        current_cursor_x = 0;
        current_cursor_y = 0;
        lastT_cursorPos = 0;

        keys_management.fnKeysManagement(USER_PRESET);
        keys_management.fnKeysManagement(USER_HRESET);
        keys_management.fnKeysManagement(USER_ARESET);
        keys_management.fnKeysManagement(USER_MRESET);

        if (isR47FAM()) {
            keys_management.fnKeysManagement(ITM_RIBBON_R47);
        } else {
            keys_management.fnKeysManagement(ITM_RIBBON_C47);
        }

        frontier_softmenus.showSoftmenu(-MNU_MyMenu);
        keys_management.fnKeysManagement(USER_KRESET);
        temporaryInformation = TI_NO_INFO;
        screenUpdatingMode = SCRUPD_AUTO;
        frontier_screen.refreshScreen(163);

        // !SAVE_SPACE_DM42_14 (never defined here)
        addTestPrograms();

        allFormulae = null;
        numberOfFormulae = 0;
        currentFormula = 0;

        currentSolverStatus = 0;
        currentSolverProgram = 0xffff;
        currentSolverVariable = INVALID_VARIABLE;
        currentSolverNestingDepth = 0;

        graphVariabl1 = 0;

        timerCraAndDeciseconds = 0x80;
        timerValue = 0;
        timerStartTime = TIMER_APP_STOPPED;
        timerTotalTime = 0;

        if (comptime dmcp_build) {
            checkBatteryFw();
        }

        // C guards this with if(loadTestData) — populating registers with test
        // data (cubes/pi digits/primes) only when the host test-data option is on.
        // The port ran it unconditionally, corrupting registers on every reset.
        if (loadTestData) {
            const n: usize = indexOfStrings.len;
            var i: usize = 0;
            while (i < n) : (i += 1) {
                if (indexOfStrings[i].itemType == 0) {
                    frontier_addons.fnStrtoX(indexOfStrings[i].itemName);
                } else if (indexOfStrings[i].itemType == 1) {
                    frontier_addons.fnStrInputLongint(@constCast(indexOfStrings[i].itemName));
                }
                frontier_store.fnStore(indexOfStrings[i].count);
                fnDrop(NOPARAM);
            }
        }

        // IR_PRINTING printer state init
        printerState_print_on(false);
        printerState_print_blank_line(0);
        printerState_print_mode(PMODE_DEFAULT);
        printerState_printer_model(PRINTER_HP);
        printerState_delay(getLineDelay());

        frontier_items.runFunction(ITM_VERS);

        // Initialize default alpha register (C: alphaRegister = REGISTER_K; varMenu42 = false;)
        alphaRegister = REGISTER_K;
        varMenu42 = false;

        if (comptime dmcp_build) {
            if (autoSav == loadAutoSav) {
                fnLoadAuto();
            }
        }

        frontier_softmenus.showSoftmenuCurrentPart();
        doRefreshSoftMenu = true;
        screenUpdatingMode = SCRUPD_AUTO;
        frontier_screen.refreshScreen(164);

        fnClearFlag(FLAG_USER_u16);
        frontier_radio_button_catalog.fnRefreshState();
    }
}

// ---------------------------------------------------------------------------
// doFnReset support: externs, helpers, ROM trampolines.
// ---------------------------------------------------------------------------
const NO_SCREEN: u8 = 0;
const PMODE_DEFAULT: c_int = 0;
const PRINTER_HP: c_int = 0;

extern var numberOfAllocatedMemoryRegions: i32;
extern var forceTamAlpha: bool_t;
extern var deadKey: u32;

const tamState_t = abi.TamState;
extern var tam: tamState_t;
inline fn tam_alpha_set(v: bool_t) void {
    tam.alpha = v;
}
inline fn tam_mode_set(v: u16) void {
    tam.mode = v;
}

const printerState_t = abi.PrinterState;
extern var printerState: printerState_t;
inline fn printerState_print_on(v: bool_t) void {
    printerState.print_on = v;
}
inline fn printerState_print_blank_line(v: u8) void {
    printerState.print_blank_line = v;
}
inline fn printerState_print_mode(v: c_int) void {
    printerState.print_mode = v;
}
inline fn printerState_printer_model(v: c_int) void {
    printerState.printer_model = v;
}
inline fn printerState_delay(v: u32) void {
    printerState.delay = @truncate(v);
}

// freeMemoryRegions[0] — array on host/new_hw, pointer-target on old_hw.
inline fn freeRegion0() *freeMemoryRegion_t {
    if (comptime globalRegister_is_array) {
        const p: [*]freeMemoryRegion_t = @ptrCast(freeMemoryRegions_array);
        return &p[0];
    } else {
        const p: [*]freeMemoryRegion_t = @ptrCast(@alignCast(freeMemoryRegions_ptr.*));
        return &p[0];
    }
}

// clearScreen(cnt): lcd_fill_rect(0,0,SCREEN_WIDTH,240,LCD_SET_VALUE); frontier_status_bar.forceSBupdate();
const SCREEN_WIDTH: u32 = 400;
const LCD_SET_VALUE: c_int = 0;
const LcdFillRectFn = *const fn (x: u32, y: u32, dx: u32, dy: u32, val: c_int) callconv(.c) void;
const c_lcd_fill_rect = if (!dmcp_build) @extern(LcdFillRectFn, .{ .name = "lcd_fill_rect" }) else {};
inline fn lcdFillRect(x: u32, y: u32, dx: u32, dy: u32, val: c_int) void {
    if (comptime dmcp_build) {
        const f: LcdFillRectFn = @ptrFromInt(LIBRARY_FN_BASE + 60);
        f(x, y, dx, dy, val);
    } else {
        c_lcd_fill_rect(x, y, dx, dy, val);
    }
}
inline fn clearScreen(cnt: u16) void {
    _ = cnt;
    lcdFillRect(0, 0, SCREEN_WIDTH, 240, LCD_SET_VALUE);
    frontier_status_bar.forceSBupdate();
}

// IR_PRINTING getLineDelay() — firmware HAL fn (host-side too, real symbol).
extern fn getLineDelay() u32;

// host: fnLoadAuto only referenced under dmcp_build. checkBattery firmware-only.
extern fn fnLoadAuto() void;

// DMCP ROM trampolines (firmware only).
const GetVbatFn = *const fn () callconv(.c) c_int;
const UsbPoweredFn = *const fn () callconv(.c) c_int;
const KeyEmptyFn = *const fn () callconv(.c) c_int;
const ResetAutoOffFn = *const fn () callconv(.c) void;
const RunMenuItemSysFn = *const fn (line_id: u8) callconv(.c) c_int;
const AuxBufPtrFn = *const fn () callconv(.c) [*c]u8;
const WriteBufPtrFn = *const fn () callconv(.c) ?*anyopaque;
const FOpenFn = *const fn (fp: ?*anyopaque, path: [*:0]const u8, mode: c_int) callconv(.c) c_int;
const FCloseFn = *const fn (fp: ?*anyopaque) callconv(.c) c_int;
const FReadFn = *const fn (fp: ?*anyopaque, buff: ?*anyopaque, btr: c_uint, br: *c_uint) callconv(.c) c_int;

inline fn romGetVbat() c_int {
    const f: GetVbatFn = @ptrFromInt(LIBRARY_FN_BASE + 240);
    return f();
}
inline fn romUsbPowered() c_int {
    const f: UsbPoweredFn = @ptrFromInt(LIBRARY_FN_BASE + 288);
    return f();
}
inline fn romKeyEmpty() c_int {
    const f: KeyEmptyFn = @ptrFromInt(LIBRARY_FN_BASE + 380);
    return f();
}
inline fn romResetAutoOff() void {
    const f: ResetAutoOffFn = @ptrFromInt(LIBRARY_FN_BASE + 440);
    f();
}
inline fn romRunMenuItemSys(line_id: u8) c_int {
    const f: RunMenuItemSysFn = @ptrFromInt(LIBRARY_FN_BASE + 728);
    return f(line_id);
}
inline fn romAuxBufPtr() [*c]u8 {
    const f: AuxBufPtrFn = @ptrFromInt(LIBRARY_FN_BASE + 292);
    return f();
}
inline fn romWriteBufPtr() ?*anyopaque {
    const f: WriteBufPtrFn = @ptrFromInt(LIBRARY_FN_BASE + 296);
    return f();
}
inline fn romFOpen(fp: ?*anyopaque, path: [*:0]const u8, mode: c_int) c_int {
    const f: FOpenFn = @ptrFromInt(LIBRARY_FN_BASE + 564);
    return f(fp, path, mode);
}
inline fn romFClose(fp: ?*anyopaque) c_int {
    const f: FCloseFn = @ptrFromInt(LIBRARY_FN_BASE + 568);
    return f(fp);
}
inline fn romFRead(fp: ?*anyopaque, buff: ?*anyopaque, btr: c_uint, br: *c_uint) c_int {
    const f: FReadFn = @ptrFromInt(LIBRARY_FN_BASE + 572);
    return f(fp, buff, btr, br);
}

// vbatVIntegrated / nextTimerRefresh / backToDMCP (firmware globals).
extern var vbatVIntegrated: c_int;
extern var nextTimerRefresh: u32;
extern var backToDMCP: bool_t;
extern fn emptyKeyBuffer() bool_t;
extern fn showHideUsbLowBattery() void;

const MONITOR_VOLTAGE_INTEGRATOR = false;

// ===========================================================================
// DMCP-only functions (firmware). Not exported on host (the C functions only
// exist under DMCP_BUILD). Each is a no-op-bodied placeholder under !dmcp_build
// so the symbols are not emitted on host.
// ===========================================================================
const FLAG_RUNTIM_i: i32 = 49168;
const FLAG_USB_i: i32 = 49192;
const FLAG_LOWBAT_c: c_uint = 49173;
const FLAG_USB_c: c_uint = 49192;
const PGM_RUNNING_v: u8 = 1;

comptime {
    if (dmcp_build) {
        @export(&dmcpResetAutoOff_impl, .{ .name = "dmcpResetAutoOff" });
        @export(&updateVbatIntegrated_impl, .{ .name = "updateVbatIntegrated" });
        @export(&checkBattery_impl, .{ .name = "checkBattery" });
    }
}

var loopVar: i16 = 0;
var loop2Var: i16 = 0;

fn dmcpResetAutoOff_impl(unused: u16) callconv(.c) void {
    _ = unused;
    if (romKeyEmpty() == 0 or !emptyKeyBuffer() or ((calcMode == CM_TIMER) and timerStartTime != TIMER_APP_STOPPED) or !getSystemFlag(FLAG_AUTOFF_i) or getSystemFlag(FLAG_RUNTIM_i) or programRunStop == PGM_RUNNING_v or (nextTimerRefresh != 0)) {
        romResetAutoOff();
    }
}
const FLAG_AUTOFF_i: i32 = 32798;

fn updateVbatIntegrated_impl(minutePulse: bool_t) callconv(.c) c_int {
    if (getSystemFlag(FLAG_USB_i)) {
        return 3100;
    }
    const tmpVbat = romGetVbat();
    const r = vbat_integrator.integrate(vbatVIntegrated, tmpVbat, minutePulse);
    vbatVIntegrated = r.integrated;
    if (r.reset_loop) {
        loopVar = 0;
    }
    return tmpVbat;
}

fn checkBattery_impl() callconv(.c) void {
    if (romUsbPowered() == 1) {
        if (!getSystemFlag(FLAG_USB_i)) {
            setSystemFlag(FLAG_USB_c);
            clearSystemFlag(FLAG_LOWBAT_c);
            showHideUsbLowBattery();
        }
    } else {
        if (getSystemFlag(FLAG_USB_i)) {
            clearSystemFlag(FLAG_USB_c);
            showHideUsbLowBattery();
        }

        const tmpVbat = updateVbatIntegrated_impl(false);

        if (tmpVbat < 2100 or vbatVIntegrated < 2100) {
            if (!getSystemFlag(FLAG_LOWBAT_i)) {
                setSystemFlag(FLAG_LOWBAT_c);
                showHideUsbLowBattery();
            }
            setStatPgmEnd();
        } else if (tmpVbat < 2500 or vbatVIntegrated < 2500) {
            if (!getSystemFlag(FLAG_LOWBAT_i)) {
                setSystemFlag(FLAG_LOWBAT_c);
                showHideUsbLowBattery();
            }
        } else {
            if (getSystemFlag(FLAG_LOWBAT_i)) {
                clearSystemFlag(FLAG_LOWBAT_c);
                showHideUsbLowBattery();
            }
        }
    }
}
const FLAG_LOWBAT_i: i32 = 49173;

// firmware-internal call from doFnReset.
inline fn checkBatteryFw() void {
    if (comptime dmcp_build) checkBattery_impl();
}

// ===========================================================================
// backToSystem / runDMCPmenu / activateUSBdisk (public)
// ===========================================================================
pub export fn backToSystem(confirmation: u16) callconv(.c) void {
    if (confirmation == NOT_CONFIRMED) {
        setConfirmationMode(&backToSystem);
    } else {
        cancelFilename = true;
        if (comptime !dmcp_build) {
            frontier_calc_mode.fnOff(NOPARAM);
        }
        if (comptime dmcp_build) {
            backToDMCP = true;
        }
    }
}

pub export fn runDMCPmenu(confirmation: u16) callconv(.c) void {
    // Whole body is DMCP_BUILD-only; on host it is an empty function.
    if (comptime dmcp_build) {
        if (confirmation == NOT_CONFIRMED) {
            setConfirmationMode(&runDMCPmenu);
        } else {
            cancelFilename = true;
            _ = romRunMenuItemSys(MI_DMCP_MENU);
            clearScreen(200);
        }
    }
}
const MI_DMCP_MENU: u8 = 216;

pub export fn activateUSBdisk(confirmation: u16) callconv(.c) void {
    if (comptime dmcp_build) {
        if (confirmation == NOT_CONFIRMED) {
            setConfirmationMode(&activateUSBdisk);
        } else {
            cancelFilename = true;
            _ = romRunMenuItemSys(MI_MSC);
            clearScreen(201);
        }
    }
}
const MI_MSC: u8 = 196;
