// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/c47Extensions/addons.c: the C47 "addon" extension layer.
// Faithful, line-by-line port of every public function of addons.c:
//   - fnEdit (the EDIT command: data-type-dispatch NIM editor + the CM_PEM
//     program-step editor that drives tam-state / pemAddNumber / tamProcessInput);
//   - standardScreenDump (DMCP), anyKeyWaiting / exitKeyWaiting / C47PopKeyNoBuffer
//     (platform key-buffer helpers reaching DMCP ROM trampolines on firmware);
//   - fnShoiXRepeats, fnFrom_ymd, fnFrom_ms, fnTo_ms, addzeroes, fnMultiplySI,
//     the fn_cnst_* complex/matrix constant pushers, the OPTION_VECTOR stk<->mx
//     converters (fnExchangeStkToMx / fnConvertStkToMx / fnConvertMxToStk + the
//     vecCreate[] bitfield table + processDefaultVector), fnJM_2SI,
//     exponentToUnitDisplayString, fnDisplayFormatCycle, fnAngularModeJM, DRG_cyc,
//     fnDRG, shrinkNimBuffer, fnChangeBaseJM / fnChangeBaseMNU, fnInDefault,
//     fnByteShortcutsS/U, doubleToXRegisterReal34, fnStrtoReg / fnStrtoX /
//     fnStrInputReal34 / fnStrInputLongint / fnIntInputLongint, fnRCL,
//     convert_to_double, timeToReal34, dms34ToReal34, notSexa, fnHrDeg / fnMinute /
//     fnSecond / fnTimeTo, isValidTime, fnToTime (+ toTimeParamReg), the IRFRAC
//     engine (getSmallestDenom / changeToSup/Sub/WholeString / checkForAndChange),
//     fnSafeReset, the MyMenu/MyAlpha reset machinery (assignToMyMenu_/assignToMyAlpha_,
//     ribbonMappings, fnRESET_MyM / fnRESET_Mya), mm, the radio-button/checkbox/macro
//     glyph painters (drawPixelArray + RB_/CB_/MB_ + their pixel tables), fnSetBCD,
//     fnLongPressSwitches.
//
// fnEdit is reached by the testSuite (it drives the PEM program-step editor), so
// byte-exactness of the transliteration is verified by `zig build test`.
//
// RENAMED-AWAY: fnCFGsettings is owned by frontier.zig (the retired shim renamed
// addons.c's fnCFGsettings to z47_frontier_legacy_fnCFGsettings to avoid the
// collision). Here it is an extern and not re-exported.
//
// Build matrix (defines.h):
//   * SAVE_SPACE_DM42_22_EDIT1 / SAVE_SPACE_DM42_23_EDIT2 are defined for every
//     DM42 "TWO_FILE" package (dmcp_build and old_hw, incl. the default `dmcp`
//     pkg4); off for host (sim/test) and dmcp5. They gate the reduced fnEdit body
//     plus the _getStringLabelOrVariableName / _fractionToString / _shortIntegerToString
//     / _hmsTimeToReal / _real34ToNim helpers. Gated `if (comptime !(dmcp_build and
//     old_hw))`.
//   * OPTION_VECTOR / OPTION_ELEC gate the stk<->mx converters + vecCreate[] table.
//     Both are build options; the converters need (option_vector OR option_elec).
//     fnExchangeStkToMx is OPTION_VECTOR-only.
//   * DMCP_BUILD gates standardScreenDump and the DMCP arms of the key helpers
//     (the ROM trampolines). PC_BUILD arms run on host.
//   * EXTRA_INFO_ON_CALC_ERROR moreInfoOnError hints: host only, gated on extra_info.
//   * PC_BUILD-only printf telltales are host-only (gated on !dmcp_build).
//
// Dead code skipped: the `/* */`-commented dtComplex34 fnEdit block and
// _angle34ToNim; VERBOSEKEYS_BUFFERED / VERBOSE_LEVEL diagnostics; the
// !IRFRAC_ENGINE alternate (IRFRAC_ENGINE is #defined locally) path of
// checkForAndChange.
//
// Decimal infrastructure mirrors the sibling display / bufferize owners: const_* /
// const34_* / const39_* are constantPointers.h macros over the shared `constants`
// blob, bound by byte offset; real34*/real* operations are decQuad*/decNumber*
// inline wrappers; longInteger_t is mpz via __gmpz_*. The vector / matrix accessor
// macros (REGISTER_*_DATA, getVectorRegister*Mode, isRegisterMatrix*dVector, etc.)
// are reproduced inline. The DMCP ROM screen/key calls are reached only under
// `if (comptime dmcp_build)` via LIBRARY_FN_BASE trampolines.

const std = @import("std");
const builtin = @import("builtin");
const frontier_build_options = @import("frontier_build_options");
const dmcp_build: bool = frontier_build_options.dmcp_build;
const old_hw: bool = frontier_build_options.old_hw;
const extra_info: bool = frontier_build_options.extra_info_on_calc_error;
const option_vector: bool = frontier_build_options.option_vector;
const option_elec: bool = frontier_build_options.option_elec;

// SAVE_SPACE_DM42_22_EDIT1 / SAVE_SPACE_DM42_23_EDIT2 are set for the DM42
// TWO_FILE packages (dmcp_build and old_hw); off for host and dmcp5.
const save_space_edit: bool = dmcp_build and old_hw;

// DMCP ROM trampoline base (lft_ifc.h offsets; base differs old_hw / new_hw).
const LIBRARY_FN_BASE: usize = if (old_hw) 0x08000201 else 0x08000301;

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

// ===========================================================================
// Types (matching the C build's layout, mirrored from sibling owners)
// ===========================================================================
const bool_t = u8;
const calcRegister_t = i16;
const angularMode_t = c_int;

const DECNUMUNITS = 25;
const abi = @import("abi"); // L1 shared bindings (REPORT-23 §5)
const frontier = @import("frontier.zig"); // M-callconv: Zig-to-Zig
const frontier_assign = @import("frontier_assign.zig"); // M-callconv: Zig-to-Zig
const frontier_bufferize = @import("frontier_bufferize.zig"); // M-callconv: Zig-to-Zig
const frontier_calc_mode = @import("frontier_calc_mode.zig"); // M-callconv: Zig-to-Zig
const frontier_char_string = @import("frontier_char_string.zig"); // M-callconv: Zig-to-Zig
const frontier_config = @import("frontier_config.zig"); // M-callconv: Zig-to-Zig
const frontier_conversion_angles = @import("frontier_conversion_angles.zig"); // M-callconv: Zig-to-Zig
const frontier_date_time = @import("frontier_date_time.zig"); // M-callconv: Zig-to-Zig
const frontier_debug = @import("frontier_debug.zig"); // M-callconv: Zig-to-Zig
const frontier_decode = @import("frontier_decode.zig"); // M-callconv: Zig-to-Zig
const frontier_display = @import("frontier_display.zig"); // M-callconv: Zig-to-Zig
const frontier_error = @import("frontier_error.zig"); // M-callconv: Zig-to-Zig
const frontier_fractions = @import("frontier_fractions.zig"); // M-callconv: Zig-to-Zig
const frontier_integers = @import("frontier_integers.zig"); // M-callconv: Zig-to-Zig
const frontier_items = @import("frontier_items.zig"); // M-callconv: Zig-to-Zig
const frontier_manage = @import("frontier_manage.zig"); // M-callconv: Zig-to-Zig
const frontier_next_step = @import("frontier_next_step.zig"); // M-callconv: Zig-to-Zig
const frontier_plotstat = @import("frontier_plotstat.zig"); // M-callconv: Zig-to-Zig
const frontier_radio_button_catalog = @import("frontier_radio_button_catalog.zig"); // M-callconv: Zig-to-Zig
const frontier_real_type = @import("frontier_real_type.zig"); // M-callconv: Zig-to-Zig
const frontier_recall = @import("frontier_recall.zig"); // M-callconv: Zig-to-Zig
const frontier_register_value_conversions = @import("frontier_register_value_conversions.zig"); // M-callconv: Zig-to-Zig
const frontier_screen = @import("frontier_screen.zig"); // M-callconv: Zig-to-Zig
const frontier_softmenus = @import("frontier_softmenus.zig"); // M-callconv: Zig-to-Zig
const frontier_tam = @import("frontier_tam.zig"); // M-callconv: Zig-to-Zig
const frontier_textfiles = @import("frontier_textfiles.zig"); // M-callconv: Zig-to-Zig
const real_t = abi.Real;
const real34_t = abi.Real34;
const complex34_t = abi.Complex34;
const realContext_t = abi.RealContext;

const font_t = abi.Font;

const item_t = abi.Item;

const softmenu_t = abi.Softmenu;
const softmenuStack_t = abi.SoftmenuStack;

const userMenuItem_t = abi.UserMenuItem;

// tamState_t (sizeof 26).
const tamState_t = abi.TamState;
const matrixHeader_t = abi.MatrixHeader;
const real34Matrix_t = abi.Real34Matrix;
const complex34Matrix_t = abi.Complex34Matrix;

// mpz / longInteger
const mp_limb_t = usize;
const mpz_struct = abi.Mpz;
const longInteger_t = [1]mpz_struct;

const cmplxPair = abi.CmplxPair;

// ===========================================================================
// Numeric constants (probed from the C build)
// ===========================================================================
const AIM_BUFFER_LENGTH: usize = 1024;
const NIM_BUFFER_LENGTH: usize = 200;
const TAM_BUFFER_LENGTH: usize = 32;
const ERROR_MESSAGE_LENGTH: usize = 512;
const TMP_STR_LENGTH: usize = 2560;
const NIM_BUFFER_EXTENDED_LENGTH: usize = 1400;
const REAL34_SIZE_IN_BYTES: i32 = 16;
const REAL34_SIZE_IN_BLOCKS: u32 = 4;
const SCREEN_WIDTH: i16 = 400;
const NUMBER_OF_DISPLAY_DIGITS: c_int = 20;
const MAX_DENMAX: i32 = 9999;
const MAX_INTERNAL_DENMAX: i32 = 32500;
// BYTES_PER_BLOCK = 4 -> TO_BLOCKS(n) = (n + 3) >> 2
inline fn TO_BLOCKS(n: u32) u32 {
    return (n + 3) >> 2;
}

const CM_NORMAL: u8 = 0;
const CM_AIM: u8 = 1;
const CM_NIM: u8 = 2;
const CM_PEM: u8 = 3;
const CM_MIM: u8 = 12;
const CM_REGISTER_BROWSER: u8 = 5;
const CM_ASN_BROWSER: u8 = 17;
const CM_FLAG_BROWSER: u8 = 6;
const CM_FONT_BROWSER: u8 = 7;
const CM_PLOT_STAT: u8 = 8;
const CM_LISTXY: u8 = 18;
const CM_GRAPH: u8 = 15;

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

const REGISTER_X: calcRegister_t = 100;
const REGISTER_Y: calcRegister_t = 101;
const REGISTER_Z: calcRegister_t = 102;
const REGISTER_T: calcRegister_t = 103;
const REGISTER_L: calcRegister_t = 108;
const TEMP_REGISTER_1: calcRegister_t = 135;
const NIM_REGISTER_LINE: calcRegister_t = 100;
const ERR_REGISTER_LINE: calcRegister_t = 102;
const NOPARAM: u16 = 9876;

const amRadian: angularMode_t = 0;
const amGrad: angularMode_t = 1;
const amDegree: angularMode_t = 2;
const amDMS: angularMode_t = 3;
const amMultPi: angularMode_t = 4;
const amNone: angularMode_t = 5;
const amAngleMask: u32 = 15;
const amPolar: u32 = 16;
const amPolarCYL: u32 = 64;
const amPolarSPH: u32 = 128;

const NP_INT_10: u8 = 1;
const NP_INT_16: u8 = 2;
const NP_INT_BASE: u8 = 3;
const NP_REAL_FLOAT_PART: u8 = 4;
const NP_REAL_EXPONENT: u8 = 5;
const NP_FRACTION_DENOMINATOR: u8 = 6;
const NP_COMPLEX_INT_PART: u8 = 7;
const NP_COMPLEX_FLOAT_PART: u8 = 8;
const NP_COMPLEX_EXPONENT: u8 = 9;

const SIM_UNSIGN: u8 = 0;
const SIM_1COMPL: u8 = 1;
const SIM_2COMPL: u8 = 2;
const SIM_SIGNMT: u8 = 3;

const DF_ALL: u16 = 0;
const DF_FIX: u16 = 1;
const DF_SCI: u16 = 2;
const DF_ENG: u16 = 3;
const DF_SF: u16 = 4;
const DF_UN: u16 = 5;

const TM_HMS: u16 = 7;

const BCD9c: u16 = 219;
const BCD10c: u16 = 220;
const BCDu: u16 = 218;

const RBX_F14: u16 = 221;
const RBX_F124: u16 = 222;
const RBX_F1234: u16 = 223;
const RBX_M14: u16 = 224;
const RBX_M124: u16 = 225;
const RBX_M1234: u16 = 226;

// VECT_CR_* (defines.h)
const VECT_CR_AUT: u16 = 0;
const VECT_CR_zxy: u16 = 1;
const VECT_CR_zyx: u16 = 2;
const VECT_CR_yx: u16 = 6;
const M_CR_zyx: u16 = 9;
const V_D0: u8 = 0;
const V_D1: u8 = 1;
const V_COPY: u8 = 2;
const V_NANA: u8 = 3;

// ITM / MNU
const ITM_EDIT: u16 = 2404;
const ITM_EQ_EDI: i16 = 1464;
const ITM_XEDIT: i16 = 2420;
const ITM_LITERAL: i32 = 114;
const ITM_REM: i32 = 1554;
const ITM_NULL: u16 = 0;
const ITM_0: u16 = 540;
const ITM_A: u16 = 550;
const ITM_PERIOD: u16 = 820;
const ITM_CHS: u16 = 97;
const ITM_CC: u16 = 1730;
const ITM_EXPONENT: u16 = 990;
const ITM_NOP: u16 = 1542;
const ITM_42STRING: u16 = 2775;
const ITM_alpha: u16 = 628;
const ITM_INDIRECTION: u16 = 539;
const ITM_GTO: u8 = 2;
const ITM_KEY: i16 = 1497;
const ITM_KEYG: i16 = 1498;
const ITM_KEYX: i16 = 1499;
const ITM_42KEY: i16 = 2794;
const ITM_42KEYG: i16 = 2795;
const ITM_42KEYX: i16 = 2796;
const ITM_FF: i16 = 112;
const ITM_op_j: u16 = 1830;
const ITM_op_j_pol: u16 = 1795;
const ITM_toINT: u16 = 1687;
const ITM_ms: u16 = 1909;
const ITM_dotD: u16 = 1741;
const ITM_V2toSTK: u16 = 2477;
const ITM_STKtoV2: u16 = 2475;
const ITM_stkexV2: u16 = 2495;
const ITM_stkexV3: u16 = 2496;
const ITM_MATX_A_1: u16 = 2623;
const ITM_SPACE_4_PER_EM: i16 = 870;

const MNU_EQN: i16 = 1327;
const MNU_Sfdx: i16 = 1381;
const MNU_Solver_TOOL: i16 = 2376;
const MNU_Sf_TOOL: i16 = 2375;
const MNU_GRAPHS: i16 = 2374;
const MNU_MVAR: i16 = 1398;
const MNU_ALPHA: i16 = 1922;
const MNU_TAM: i16 = 1385;
const MNU_SYSFL: i16 = 1379;
const MNU_PREFIX: i16 = 2229;
const MNU_PFN: i16 = 1403;
const MNU_HOME: i16 = 1921;

const SOLVER_STATUS_USES_FORMULA: u16 = 256;
const SOLVER_STATUS_INTERACTIVE: u16 = 2;

// literal types
const STRING_LABEL_VARIABLE: u8 = 253;
const BINARY_SHORT_INTEGER: u8 = 1;
const STRING_SHORT_INTEGER: u8 = 7;
const STRING_LONG_INTEGER: u8 = 8;
const BINARY_REAL34: u8 = 3;
const STRING_REAL34: u8 = 9;
const BINARY_COMPLEX34: u8 = 4;
const STRING_COMPLEX34: u8 = 10;
const STRING_DATE: u8 = 12;
const STRING_TIME: u8 = 11;
const STRING_ANGLE_DMS: u8 = 21;
const STRING_ANGLE_RADIAN: u8 = 18;
const STRING_ANGLE_GRAD: u8 = 19;
const STRING_ANGLE_DEGREE: u8 = 20;
const STRING_ANGLE_MULTPI: u8 = 22;
const INDIRECT_VARIABLE: u8 = 255;
const INDIRECT_REGISTER: u8 = 254;

// param modes
const PARAM_DECLARE_LABEL: u16 = 1;
const PARAM_LABEL: u16 = 2;
const PARAM_REGISTER: u16 = 3;
const PARAM_FLAG: u16 = 4;
const PARAM_NUMBER_8: u16 = 5;
const PARAM_NUMBER_16: u16 = 6;
const PARAM_COMPARE: u16 = 7;
const PARAM_KEYG_KEYX: u16 = 8;
const PARAM_SKIP_BACK: u16 = 9;
const PARAM_NUMBER_8_16: u16 = 10;
const PARAM_SHUFFLE: u16 = 11;
const PARAM_MENU: u16 = 12;
const PARAM_REM: u16 = 14;
const PTP_STATUS: u16 = 7680;

const SYSTEM_FLAG_NUMBER: u16 = 250;
const LAST_GLOBAL_FLAG: u16 = 111;
const FIRST_LOCAL_FLAG: u16 = 112;
const LAST_GLOBAL_REGISTER: u16 = 136;
const FIRST_LOCAL_REGISTER: u16 = 7000;
const LAST_SPARE_REGISTERS_IN_KS_CODE: u16 = 224;
const VALUE_0: u16 = 251;
const VALUE_1: u16 = 252;
const CNST_BEYOND_250: u16 = 250;

// flags
const FLAG_ALPHA: c_uint = 32782;
const FLAG_ASLIFT: c_uint = 49187;
const FLAG_FRACT: c_int = 32775;
const FLAG_PROPFR: c_int = 32776;
const FLAG_3DPHYS: c_uint = 32869;
const FLAG_OVERFLOW: c_uint = 32780;
const FLAG_HPBASE: c_int = 32828;
const FLAG_SSIZE8: c_int = 32792;
const FLAG_2TO10: c_int = 32829;
const FLAG_PFX_ALL: c_int = 32841;
const FLAG_G_DOUBLETAP: c_int = 32861;
const FLAG_SHFT_4s: c_int = 32865;
const FLAG_HOME_TRIPLE: c_int = 32864;
const FLAG_MYM_TRIPLE: c_int = 32863;
const FLAG_FGLNFUL: c_uint = 32867;
const FLAG_FGLNLIM: c_uint = 32866;
const FLAG_BASE_HOME: c_uint = 32862;
const FLAG_BASE_MYM: c_uint = 32860;

// errors
const ERROR_INVALID_DATA_TYPE_FOR_OP: u8 = 24;
const ERROR_NOT_ENOUGH_MEMORY_FOR_NEW_MATRIX: u8 = 39;
const ERROR_INVALID_DATA_TYPE_FOR_POLAR_RECT: u8 = 52;

// temporary information
const TI_FROM_MS_TIME: u8 = 80;
const TI_FROM_MS_DEG: u8 = 81;
const TI_NO_INFO: u8 = 0;
const TI_VECTOR: u8 = 127;
const TI_VECTORCOMP_2DPOLAR: u8 = 131;
const TI_VECTORCOMP_2DRECT: u8 = 132;
const TI_VECTORCOMP_3DSPH: u8 = 128;
const TI_VECTORCOMP_3DCYL: u8 = 129;
const TI_VECTORCOMP_3DRECT: u8 = 130;
const TI_DATA_NEG_OVRFL: u8 = 111;
const TI_DATA_LOSS: u8 = 95;

// ribbon pseudo + real
const ITM_RIBBON_ENG: i16 = 2513;
const ITM_RIBBON_ENG_C47: i16 = 32000;
const ITM_RIBBON_ENG_R47: i16 = 32001;
const ITM_RIBBON_SAV: i16 = 2508;
const ITM_RIBBON_SAV2: i16 = 2515;
const ITM_RIBBON_FIN: i16 = 2507;
const ITM_RIBBON_FIN2: i16 = 2514;
const ITM_RIBBON_CPX: i16 = 2506;
const ITM_RIBBON_C47: i16 = 2509;
const ITM_RIBBON_C47PL: i16 = 2510;
const ITM_RIBBON_R47: i16 = 2511;
const ITM_RIBBON_R47PL: i16 = 2512;
const ASSIGN_CLEAR: i16 = -32768;

// ribbon body item/menu ids
const MNU_CPX: i16 = 1323;
const MNU_MATX: i16 = 1344;
const ITM_CONSTpi: i16 = 109;
const ITM_EXP: i16 = 65;
const MNU_TRG_C47: i16 = 2102;
const MNU_TRG_R47: i16 = 2036;
const ITM_SYSTEM2: i16 = 2043;
const ITM_ACTUSB: i16 = 2044;
const ITM_SAVE: i16 = 1586;
const ITM_LOAD: i16 = 1509;
const ITM_SAVEST: i16 = 2387;
const ITM_LOADST: i16 = 2388;
const ITM_WRITEP: i16 = 1590;
const ITM_READP: i16 = 1567;
const ITM_PC: i16 = 1695;
const ITM_DELTAPC: i16 = 1666;
const ITM_YX: i16 = 60;
const ITM_SQUARE: i16 = 58;
const ITM_10x: i16 = 67;
const MNU_FIN: i16 = 1331;
const ITM_PCPMG: i16 = 1699;
const ITM_PCT: i16 = 1697;
const MNU_TVM: i16 = 1368;
const ITM_DRG: i16 = 1873;
const ITM_EE_EXP_TH: i16 = 1816;
const ITM_DSP: i16 = 1573;
const ITM_DREAL: i16 = 1899;
const ITM_Rup: i16 = 39;
const ITM_TIMER: i16 = 1622;
const MNU_LOOP: i16 = 1342;
const MNU_TEST: i16 = 1365;
const ITM_XTHROOT: i16 = 63;
const ITM_XFACT: i16 = 108;

// calcModel (isR47FAM)
const USER_C47: u8 = 46;
const USER_R47f_g: u8 = 61;
const USER_R47bk_fg: u8 = 62;
const USER_R47fg_bk: u8 = 63;
const USER_R47fg_g: u8 = 64;

// checkHP
const ID_DP: u8 = 2;

// DEC rounding modes (decContext.h enum).
const DEC_ROUND_HALF_UP: c_int = 2;
const DEC_ROUND_DOWN: c_int = 5;
const DEC_ROUND_FLOOR: c_int = 6;

const forcedLiftTheStack: bool = true;

// ===========================================================================
// STD_* byte sequences (fonts.h) used in this file
// ===========================================================================
const STD_SPACE_HAIR = "\xa0\x0a";
const STD_SPACE_4_PER_EM = "\xa0\x05";
const STD_SUP_0 = "\xa1\x60";
const STD_SUP_1 = "\xa1\x61";
const STD_SUP_MINUS = "\xa1\x6b";
const STD_SUB_10 = "\xa4\x7d";
const STD_CROSS = "\x80\xd7";
const STD_DOT = "\x80\xb7";
const STD_DEGREE = "\x80\xb0";
const STD_op_i = "\xa1\x48";
const STD_op_j = "\xa1\x49";
const STD_NOCHAR: u8 = 1;
const STD_ALMOST_EQUAL = "\xa2\x48";
const STD_MEASURED_ANGLE = "\xa2\x21";
const STD_mu = "\x83\xab";
const STD_SPACE_PUNCTUATION = "\xa0\x08";
// STD_SUP_9[1] = 0x69 ; STD_op_i[1]=0x48 ; STD_op_j[1]=0x49
const STD_SUP_9_1: u8 = 0x69;
const STD_op_i_1: u8 = 0x48;
const STD_op_j_1: u8 = 0x49;

// SEPARATOR_LEFT / SEPARATOR_RIGHT runtime macros (gapChar1 mapping, see display owner).
const lit_comma1 = ",\x01\x00";
const lit_dot1 = ".\x01\x00";
const lit_quote1 = "'\x01\x00";
const lit_underscore1 = "_\x01\x00";
const lit_11 = "\x01\x01\x00";
fn itemStr(gapItem: u16) [*c]const u8 {
    if (gapItem == 0) return lit_11;
    return &indexOfItems[gapItem].itemSoftmenuName;
}
fn gapChar1LR(gapItem: u16, isRight: bool) [*c]const u8 {
    const s = itemStr(gapItem);
    // C gapChar1Left guard is strict 1-byte (s[1]==0 && s[2]==0); gapChar1Right is
    // more permissive — s[1]==0 || (s[1]!=0 && s[2]==0), i.e. also a 2-byte separator.
    const match = if (isRight)
        (s[0] != 0 and (s[1] == 0 or s[2] == 0))
    else
        (s[0] != 0 and s[1] == 0 and s[2] == 0);
    if (match) {
        return switch (s[0]) {
            ',' => lit_comma1,
            '.' => lit_dot1,
            '\'' => lit_quote1,
            '_' => lit_underscore1,
            else => s,
        };
    }
    return s;
}
inline fn SEPARATOR_LEFT() [*c]const u8 {
    return gapChar1LR(gapItemLeft, false);
}
inline fn SEPARATOR_RIGHT() [*c]const u8 {
    return gapChar1LR(gapItemRight, true);
}

// ===========================================================================
// const_* / const34_* / const39_* : constantPointers.h macros over `constants`.
// ===========================================================================
// M22: blob accessors via abi (single @ptrCast site) instead of a local @extern.
const constR = abi.constants.cstRAligned;
const constR34 = abi.constants.cst34;
const const_0 = constR(1708);
const const_1 = constR(4856);
const const_1on2 = constR(4580);
const const_1on4 = constR(4532);
const const39_root3on2 = constR(4772);
const const39_rt3 = constR(5720);
const const_1e_16 = constR(4484);
const const_1e_24 = constR(4472);
const const_10p9__1 = constR(5600);
const const39_pi = constR(1848);
const const34_10 = constR34(16424);
const const34_60 = constR34(16536);
const const34_100 = constR34(16552);
const const34_3600 = constR34(16680);
const const34_0 = constR34(16200);
const const34_24 = constR34(16472);

// ===========================================================================
// C-arrays bound by address (NOT pointer-typed externs).
// ===========================================================================
const indexOfItems = @extern([*c]const item_t, .{ .name = "indexOfItems" });
const baseDigits = @extern([*c]const u8, .{ .name = "baseDigits" });
const commonBugScreenMessages = @extern([*c]const [100]u8, .{ .name = "commonBugScreenMessages" });
const softmenu = @extern([*c]const softmenu_t, .{ .name = "softmenu" });
const softmenuStack = @extern([*c]const softmenuStack_t, .{ .name = "softmenuStack" });
const userMenuItems = @extern([*c]userMenuItem_t, .{ .name = "userMenuItems" });
const userAlphaItems = @extern([*c]userMenuItem_t, .{ .name = "userAlphaItems" });

const bugMsgValueFor: usize = 0;
const bugMsgCalcModeWhileProcKey: usize = 1;

// font tables (real extern const structs, taken by &name).
extern const standardFont: font_t;
extern const numericFont: font_t;

// ===========================================================================
// Genuine pointers (stay [*c]).
// ===========================================================================
extern var aimBuffer: [*c]u8;
extern var nimBufferDisplay: [*c]u8;
extern var errorMessage: [*c]u8;
extern var tmpString: [*c]u8;
extern var tmpStringLabelOrVariableName: [*c]u8;
extern var firstFreeProgramByte: [*c]u8;
extern var currentStep: [*c]u8;
extern var cursorFont: ?*const font_t;

// ===========================================================================
// Extern globals (defined in the c47 globals hub / other owners).
// ===========================================================================
extern var calcMode: u8;
extern var calcModel: u8;
extern var tam: tamState_t;
extern var currentSolverStatus: u16;
extern var currentKeyCode: u8;
extern var displayStackSHOIDISP: u8;
extern var hexDigits: u8;
extern var nimNumberPart: u8;
extern var cursorEnabled: u8;
extern var xCursor: u32;
extern var exponentSignLocation: i16;
extern var lastIntegerBase: u32;
extern var denMax: u32;
extern var Input_Default: u8;
extern var LongPressM: u8;
extern var LongPressF: u8;
extern var editingLiteralType: u8;
extern var bcdDisplaySign: u8;
extern var DRG_Cycling: u8;
extern var DM_Cycling: u8;
extern var temporaryInformation: u8;
extern var currentAngularMode: angularMode_t;
extern var grpGroupingLeft: u8;
extern var grpGroupingRight: u8;
extern var displayFormat: u8;
extern var displayFormatDigits: u8;
extern var shortIntegerMode: u8;
extern var shortIntegerMask: u64;
extern var shortIntegerSignBit: u64;
extern var itemToBeAssigned: i16;
extern var cachedDynamicMenu: i16;
extern var numberOfTamMenusToPop: i16;
extern var alphaCursor: i16;
extern var T_cursorPos: i16;
extern var shiftF: bool_t;
extern var shiftG: bool_t;
extern var pemCursorIsZerothStep: bool_t;
extern var significantDigits: u8;
extern var displayStack: u8;
extern var exponentLimit: i16;
extern var ctxtReal39: realContext_t;
extern var gapItemLeft: u16;
extern var gapItemRight: u16;

// fnCFGsettings is owned by frontier.zig (renamed-away); declared extern, not
// re-exported.

// ===========================================================================
// Function externs (cross-owner / runtime / libc / decNumber / GMP).
// ===========================================================================
extern fn getSystemFlag(sf: c_int) bool_t;
// M-callconv: deferred — addons' stale signature (frontSpace: [*c]const u8, nim)
// differs from frontier_display's real34ToDisplayString (frontSpace: bool_t,
// limitIrfrac); a faithful @import conversion needs semantic reconciliation, so
// this one symbol stays extern to preserve exact current behavior.
extern fn real34ToDisplayString(value34: *align(1) const real34_t, angularMode: angularMode_t, displayString: [*c]u8, font: *const font_t, maxWidth: i16, displayDigits: c_int, allowLEDOff: bool_t, frontSpace: [*c]const u8, nim: bool_t) void;
extern fn setSystemFlag(sf: c_uint) void;
extern fn clearSystemFlag(sf: c_uint) void;
extern fn getRegisterDataType(regist: calcRegister_t) u32;
extern fn getRegisterDataPointer(regist: calcRegister_t) [*c]u8;
extern fn setRegisterDataPointer(regist: calcRegister_t, p: [*c]u8) void;
extern fn getRegisterTag(regist: calcRegister_t) u32;
extern fn setRegisterTag(regist: calcRegister_t, tag: u32) void;
extern fn setRegisterDataType(regist: calcRegister_t, dataType: u32, tag: u32) void;
// freeRegisterData is a macro = freeC47Blocks(ptr, getRegisterFullSizeInBlocks).
extern fn freeC47Blocks(pcMemPtr: ?*anyopaque, sizeInBlocks: usize) void;
extern fn getRegisterFullSizeInBlocks(regist: calcRegister_t) u16;
inline fn freeRegisterData(regist: calcRegister_t) void {
    freeC47Blocks(getRegisterDataPointer(regist), getRegisterFullSizeInBlocks(regist));
}
extern fn reallocateRegister(regist: calcRegister_t, dataType: u32, dataSizeInBytes: u32, tag: u32) void;
extern fn allocC47Blocks(numberOfBlocks: usize) [*c]u8;
extern fn moreInfoOnError(m1: [*c]const u8, m2: [*c]const u8, m3: [*c]const u8, m4: [*c]const u8) void;
extern fn fnDrop(unusedButMandatoryParameter: u16) void;
extern fn fnDropY(unusedButMandatoryParameter: u16) void;
extern fn liftStack() void;
extern fn saveLastX() bool_t;
extern fn copySourceRegisterToDestRegister(source: calcRegister_t, dest: calcRegister_t) void;

// edit / pem helpers
// isAtEndOfProgram is a static inline = frontier_manage.checkOpCodeOfStep(step, ITM_END).
const ITM_END: u16 = 1458;
inline fn isAtEndOfProgram(step: [*c]const u8) bool_t {
    return @intFromBool(frontier_manage.checkOpCodeOfStep(step, ITM_END));
}
// regKStoC is a static inline (registers.h).
const FIRST_STAT_REGISTER_IN_KS_CODE: u16 = 211;
const NUMBER_OF_LOCAL_REGISTERS: u16 = 99;
const FIRST_LOCAL_REGISTER_IN_KS_CODE: u16 = 112;
const LAST_LOCAL_REGISTER_IN_KS_CODE: u16 = 210;
inline fn regKStoC(regKS: u16) u16 {
    const k: i32 = @intCast(regKS);
    const a: i32 = @intFromBool(FIRST_STAT_REGISTER_IN_KS_CODE <= regKS and regKS <= LAST_SPARE_REGISTERS_IN_KS_CODE);
    const b: i32 = @intFromBool(FIRST_LOCAL_REGISTER_IN_KS_CODE <= regKS and regKS <= LAST_LOCAL_REGISTER_IN_KS_CODE);
    const r: i32 = k - a * @as(i32, NUMBER_OF_LOCAL_REGISTERS) + b * (@as(i32, FIRST_LOCAL_REGISTER) - @as(i32, FIRST_LOCAL_REGISTER_IN_KS_CODE));
    return @intCast(@as(i16, @truncate(r)));
}

// nim / aim / display string helpers

// number / register conversions
// stringToLongInteger is a static inline = mpz_set_str.
extern fn __gmpz_set_str(rop: [*c]mpz_struct, str: [*c]const u8, base: c_int) c_int;
inline fn stringToLongInteger(str: [*c]const u8, base: u32, lgInt: [*c]mpz_struct) void {
    _ = __gmpz_set_str(lgInt, str, @intCast(base));
}
// int32ToLongInteger is a static inline = mpz_set_si.
extern fn __gmpz_set_si(rop: [*c]mpz_struct, op: c_long) void;
inline fn int32ToLongInteger(value: i32, lgInt: [*c]mpz_struct) void {
    __gmpz_set_si(lgInt, value);
}
// longIntegerCompare is a static inline = mpz_cmp.
extern fn __gmpz_cmp(a: [*c]const mpz_struct, b: [*c]const mpz_struct) c_int;
inline fn longIntegerCompare(a: [*c]const mpz_struct, b: [*c]const mpz_struct) i32 {
    return __gmpz_cmp(a, b);
}
// stringToReal34 is a macro = decQuadFromString(dst, src, &ctxtReal34).
extern fn decQuadFromString(r: *align(1) real34_t, str: [*c]const u8, ctx: *realContext_t) *align(1) real34_t;
inline fn stringToReal34(str: [*c]const u8, r: *align(1) real34_t) void {
    _ = decQuadFromString(r, str, &ctxtReal34);
}
extern fn stringToInt32(str: [*c]const u8) i32;

// short integer / base
extern fn fnRoundi(unusedButMandatoryParameter: u16) void;

// arithmetic on registers (commands)
extern fn fnMultiply(unusedButMandatoryParameter: u16) void;
extern fn fnDivide(unusedButMandatoryParameter: u16) void;
extern fn adjustResult(result: calcRegister_t, dropY: bool_t, setCpxRes: bool_t, op1: calcRegister_t, op2: calcRegister_t, op3: calcRegister_t) void;
extern fn fnToReal(unusedButMandatoryParameter: u16) void;
// setRegisterAngularMode / setComplex* are setRegisterTag macros (registers.h).
inline fn setRegisterAngularMode(regist: calcRegister_t, am: u16) void {
    setRegisterTag(regist, am);
}
inline fn setComplexRegisterAngularMode(regist: calcRegister_t, am: u16) void {
    setRegisterTag(regist, (am & amAngleMask) | (getRegisterTag(regist) & amPolar));
}
inline fn setComplexRegisterPolarMode(regist: calcRegister_t, pm: u16) void {
    const base: u32 = if ((pm & amPolar) != 0) (getRegisterTag(regist) & amAngleMask) else @as(u32, @intCast(amNone));
    setRegisterTag(regist, base | (pm & amPolar));
}

// complex / matrix
extern fn fnToPolar2(unusedButMandatoryParameter: u16) void;
extern fn fnKeyCC(item: u16) void;
extern fn chsCplx() void;
extern fn conjCplx() void;
extern fn initMatrixRegister(regist: calcRegister_t, rows: u16, cols: u16, complex: bool_t) bool_t;
extern fn linkToRealMatrixRegister(regist: calcRegister_t, matrix: *real34Matrix_t) void;
extern fn linkToComplexMatrixRegister(regist: calcRegister_t, matrix: *complex34Matrix_t) void;
extern fn is_2D3D_Register_Ready(ang2Dx: *u32, ang2Dy: *u32, ang3Dx: *u32, ang3Dy: *u32, ang3Dz: *u32, validPolarInput: *bool_t, valid2DRInput: *bool_t, validSPHInput: *bool_t, validCYLInput: *bool_t, valid3DRInput: *bool_t, constVector: u16) bool_t;
extern fn convertPOLto2D(r: *real_t, th1: *real_t, am: u8, matrix: *real34Matrix_t, ctx: *realContext_t) void;
extern fn convertSPHto3D(r: *real_t, th1: *real_t, th2: *real_t, am: u8, matrix: *real34Matrix_t, ctx: *realContext_t) void;
extern fn convertCYLto3D(r: *real_t, th1: *real_t, z: *real_t, am: u8, matrix: *real34Matrix_t, ctx: *realContext_t) void;
extern fn convert3DtoCYL(matrix: *const real34Matrix_t, r: *real_t, th1: *real_t, z: *real_t, am: u8, ctx: *realContext_t) void;
extern fn convert3DtoSPH(matrix: *const real34Matrix_t, r: *real_t, th1: *real_t, th2: *real_t, am: u8, ctx: *realContext_t) void;
extern fn VtoAngleMode(angleMode: angularMode_t) bool_t;
extern fn realRectangularToPolar(real: *const real_t, imag: *const real_t, magnitude: *real_t, theta: *real_t, ctx: *realContext_t) void;

// IRFRAC helpers
extern fn irfractionTolerence(ii: i32, tol: *real_t) void;
extern fn realCompareLessThan(a: *const real_t, b: *const real_t) bool_t;
extern fn realCompareGreaterThan(a: *const real_t, b: *const real_t) bool_t;
extern fn realCompareAbsLessThan(a: *const real_t, b: *const real_t) bool_t;
extern fn realCompareAbsGreaterThan(a: *const real_t, b: *const real_t) bool_t;
// real* sign/zero/compare are decNumber macros (realType.h), reproduced inline.
extern fn decNumberCompare(res: *real_t, a: *const real_t, b: *const real_t, ctx: *realContext_t) *real_t;
inline fn realCompare(a: *const real_t, b: *const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberCompare(res, a, b, ctx);
}
inline fn realIsZero(r: *const real_t) bool_t {
    // decNumberIsZero(dn) = *(dn)->lsu==0 && ... ; reproduce via the realIsZeroB form.
    return @intFromBool(r.lsu[0] == 0 and r.digits == 1 and (r.bits & 0x70) == 0);
}
inline fn realIsSpecial(r: *const real_t) bool_t {
    return @intFromBool((r.bits & 0x70) != 0); // DECSPECIAL = 0x70
}
inline fn realIsPositive(r: *const real_t) bool_t {
    return @intFromBool((r.bits & 0x80) == 0);
}
inline fn realIsNegative(r: *const real_t) bool_t {
    return @intFromBool((r.bits & 0x80) == 0x80);
}
inline fn realSetPositiveSign(operand: *real_t) void {
    operand.bits &= 0x7F;
}
inline fn realSetNegativeSign(operand: *real_t) void {
    operand.bits |= 0x80;
}

// MyMenu helpers

// glyph painters runtime. setBlackPixel/setWhitePixel are static inline over
// bitblt24 (screen.h); placePixel is a real function. On firmware bitblt24 is a
// DMCP ROM trampoline (lft_ifc.h, LIBRARY_FN_BASE+36); on host it is linkable.
const Bitblt24Fn = *const fn (x: u32, dx: u32, y: u32, val: u32, blt_op: c_int, fill: c_int) callconv(.c) void;
const c_bitblt24 = if (!dmcp_build) @extern(Bitblt24Fn, .{ .name = "bitblt24" }) else {};
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
extern fn _Buzz(a: i32, b: i32) void;
extern fn getBeepVolume() u16;
extern fn fnSetVolume(volume: u16) void;
extern fn resetShiftState() void;
extern fn clearKeyBuffer() void;

// libc
extern fn strlen(s: [*c]const u8) usize;
extern fn strcat(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strcpy(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strncmp(a: [*c]const u8, b: [*c]const u8, n: usize) c_int;
extern fn memset(s: ?*anyopaque, c: c_int, n: usize) ?*anyopaque;
extern fn strtof(s: [*c]const u8, end: ?*[*c]u8) f32;
extern fn abs(v: c_int) c_int;

// ===========================================================================
// real34 / real arithmetic = decQuad/decNumber (libdecnumber).
// ===========================================================================
extern fn decimal128ToNumber(d: *const real34_t, dn: *real_t) *real_t;
extern fn decimal128FromNumber(d: *real34_t, dn: *const real_t, set: *realContext_t) *real34_t;
extern fn decQuadCopy(r: *align(1) real34_t, a: *align(1) const real34_t) *align(1) real34_t;
extern fn decQuadZero(r: *align(1) real34_t) *align(1) real34_t;
extern fn decQuadIsZero(d: *align(1) const real34_t) u32;
extern fn decQuadToString(d: *align(1) const real34_t, str: [*c]u8) [*c]u8;
extern fn decQuadAdd(r: *align(1) real34_t, a: *align(1) const real34_t, b: *align(1) const real34_t, ctx: *realContext_t) *align(1) real34_t;
extern fn decQuadSubtract(r: *align(1) real34_t, a: *align(1) const real34_t, b: *align(1) const real34_t, ctx: *realContext_t) *align(1) real34_t;
extern fn decQuadMultiply(r: *align(1) real34_t, a: *align(1) const real34_t, b: *align(1) const real34_t, ctx: *realContext_t) *align(1) real34_t;
extern fn decQuadDivide(r: *align(1) real34_t, a: *align(1) const real34_t, b: *align(1) const real34_t, ctx: *realContext_t) *align(1) real34_t;
extern fn decQuadRemainder(r: *align(1) real34_t, a: *align(1) const real34_t, b: *align(1) const real34_t, ctx: *realContext_t) *align(1) real34_t;
extern fn decQuadToIntegralValue(r: *align(1) real34_t, a: *align(1) const real34_t, ctx: *realContext_t, round: c_int) *align(1) real34_t;
extern fn decQuadCompare(r: *align(1) real34_t, a: *align(1) const real34_t, b: *align(1) const real34_t, ctx: *realContext_t) *align(1) real34_t;
extern var ctxtReal34: realContext_t;

// real (decNumber) helpers / macros
extern fn decNumberFromString(r: *real_t, str: [*c]const u8, ctx: *realContext_t) *real_t;
extern fn decNumberToString(r: *const real_t, str: [*c]u8) [*c]u8;
extern fn decNumberDivide(res: *real_t, a: *const real_t, b: *const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberMultiply(res: *real_t, a: *const real_t, b: *const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberAdd(res: *real_t, a: *const real_t, b: *const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberSubtract(res: *real_t, a: *const real_t, b: *const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberFromInt32(r: *real_t, v: i32) *real_t;
extern fn decNumberCopy(dst: *real_t, src: *const real_t) *real_t;

inline fn stringToReal(str: [*c]const u8, r: *real_t, ctx: *realContext_t) void {
    _ = decNumberFromString(r, str, ctx);
}
inline fn realToString(r: *const real_t, str: [*c]u8) void {
    _ = decNumberToString(r, str);
}
inline fn realDivide(a: *const real_t, b: *const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberDivide(res, a, b, ctx);
}
inline fn realMultiply(a: *const real_t, b: *const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberMultiply(res, a, b, ctx);
}
inline fn realAdd(a: *const real_t, b: *const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberAdd(res, a, b, ctx);
}
inline fn realSubtract(a: *const real_t, b: *const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberSubtract(res, a, b, ctx);
}
inline fn int32ToReal(v: i32, r: *real_t) void {
    _ = decNumberFromInt32(r, v);
}
inline fn realCopy(source_: *const real_t, destination: *real_t) void {
    destination.* = source_.*;
}
inline fn realCopyAbs(source_: *const real_t, destination: *real_t) void {
    destination.* = source_.*;
    destination.bits &= 0x7F;
}

// real34 wrappers (realType.h macros)
inline fn real34ToReal(source_: *align(1) const real34_t, destination: *real_t) void {
    _ = decimal128ToNumber(@ptrCast(source_), destination);
}
inline fn realToReal34(source_: *const real_t, destination: *align(1) real34_t) void {
    _ = decimal128FromNumber(@ptrCast(destination), source_, &ctxtReal34);
}
inline fn real34Copy(source_: *align(1) const real34_t, destination: *align(1) real34_t) void {
    _ = decQuadCopy(destination, source_);
}
inline fn real34SetZero(destination: *align(1) real34_t) void {
    _ = decQuadZero(destination);
}
inline fn real34IsZero(source_: *align(1) const real34_t) bool {
    return decQuadIsZero(source_) != 0;
}
inline fn real34ToString(source_: *align(1) const real34_t, destination: [*c]u8) void {
    _ = decQuadToString(source_, destination);
}
inline fn real34IsNegative(source_: *align(1) const real34_t) bool {
    return (source_.bytes[15] & 0x80) == 0x80;
}
inline fn real34IsPositive(source_: *align(1) const real34_t) bool {
    return (source_.bytes[15] & 0x80) == 0;
}
inline fn real34SetPositiveSign(operand: *align(1) real34_t) void {
    operand.bytes[15] &= 0x7F;
}
inline fn real34ChangeSign(operand: *align(1) real34_t) void {
    operand.bytes[15] ^= 0x80;
}
inline fn real34Add(a: *align(1) const real34_t, b: *align(1) const real34_t, res: *align(1) real34_t) void {
    _ = decQuadAdd(res, a, b, &ctxtReal34);
}
inline fn real34Subtract(a: *align(1) const real34_t, b: *align(1) const real34_t, res: *align(1) real34_t) void {
    _ = decQuadSubtract(res, a, b, &ctxtReal34);
}
inline fn real34Multiply(a: *align(1) const real34_t, b: *align(1) const real34_t, res: *align(1) real34_t) void {
    _ = decQuadMultiply(res, a, b, &ctxtReal34);
}
inline fn real34Divide(a: *align(1) const real34_t, b: *align(1) const real34_t, res: *align(1) real34_t) void {
    _ = decQuadDivide(res, a, b, &ctxtReal34);
}
inline fn real34DivideRemainder(a: *align(1) const real34_t, b: *align(1) const real34_t, res: *align(1) real34_t) void {
    _ = decQuadRemainder(res, a, b, &ctxtReal34);
}
inline fn real34ToIntegralValue(a: *align(1) const real34_t, res: *align(1) real34_t, round: c_int) void {
    _ = decQuadToIntegralValue(res, a, &ctxtReal34, round);
}
inline fn int32ToReal34(v: i32, res: *align(1) real34_t) void {
    var tmp: real_t = undefined;
    int32ToReal(v, &tmp);
    realToReal34(&tmp, res);
}
// real34CompareLessThan / GreaterEqual / AbsLessThan are real functions (NOT
// macros) -- use them so uninitialized/special-value semantics match C exactly.
extern fn real34CompareLessThan(a: *align(1) const real34_t, b: *align(1) const real34_t) bool_t;
extern fn real34CompareGreaterEqual(a: *align(1) const real34_t, b: *align(1) const real34_t) bool_t;
extern fn real34CompareAbsLessThan(a: *align(1) const real34_t, b: *align(1) const real34_t) bool_t;

// longInteger wrappers
inline fn longIntegerInit(op: *longInteger_t) void {
    __gmpz_init(&op[0]);
}
inline fn longIntegerFree(op: *longInteger_t) void {
    __gmpz_clear(&op[0]);
}
inline fn longIntegerIsNegative(op: *const longInteger_t) bool {
    return op[0]._mp_size < 0;
}
inline fn longIntegerIsPositiveOrZero(op: *const longInteger_t) bool {
    return op[0]._mp_size >= 0;
}
extern fn __gmpz_init(op: [*c]mpz_struct) void;
extern fn __gmpz_clear(op: [*c]mpz_struct) void;

// ===========================================================================
// runtime macros over globals
// ===========================================================================
inline fn checkHP() bool {
    return significantDigits <= 16 and displayStack == 1 and exponentLimit == 99 and Input_Default == ID_DP and (calcMode == CM_NORMAL or calcMode == CM_NIM);
}
inline fn isR47FAM() bool {
    return calcModel == USER_R47f_g or calcModel == USER_R47bk_fg or calcModel == USER_R47fg_bk or calcModel == USER_R47fg_g;
}
inline fn registerIsNoAngle(r: calcRegister_t) bool {
    return (getRegisterDataType(r) == dtReal34 and getRegisterAngularMode(r) == amNone) or getRegisterDataType(r) == dtLongInteger;
}
inline fn registerIsAngle(r: calcRegister_t) bool {
    return getRegisterDataType(r) == dtReal34 and !registerIsNoAngle(r);
}
inline fn getRegisterAngularMode(reg: calcRegister_t) angularMode_t {
    return @intCast(getRegisterTag(reg) & amAngleMask);
}
inline fn getComplexRegisterAngularMode(reg: calcRegister_t) u16 {
    return @intCast(getRegisterTag(reg) & amAngleMask);
}
inline fn getComplexRegisterPolarMode(reg: calcRegister_t) u16 {
    return @intCast(getRegisterTag(reg) & amPolar);
}
// extra-info hint (host only, gated like siblings).
inline fn moreInfoOnErr(where: [*c]const u8, hint: [*c]const u8) void {
    if (comptime extra_info) {
        if (comptime !dmcp_build) {
            moreInfoOnError(where, hint, null, null);
        }
    }
}
inline fn stringByteLength(str: [*c]const u8) i32 {
    return @intCast(strlen(str));
}
inline fn maxI(a: i32, b: i32) i32 {
    return if (a > b) a else b;
}

// register data accessors (REGISTER_*_DATA macros)
const reg34 = abi.registerReal34;
const regImag34 = abi.registerImag34;
const SIZEOF_STR_LG_INT_HEADER: usize = 4;
const regString = abi.registerString;
const regShortInteger = abi.registerShortInteger;
const regMatrixHeader = abi.registerMatrixHeader;
// VARIABLE_REAL34_DATA(a)=((real34_t*)(a)); VARIABLE_IMAG34_DATA(a)=((real34_t*)(a)+1)
// matrixElements[i] : index a [*c]complex34_t element and return its real/imag halves.
inline fn varReal34(elems: [*c]complex34_t, i: usize) *align(1) real34_t {
    const p: [*]align(1) real34_t = @ptrCast(&elems[i]);
    return &p[0];
}
inline fn varImag34(elems: [*c]complex34_t, i: usize) *align(1) real34_t {
    const p: [*]align(1) real34_t = @ptrCast(&elems[i]);
    return &p[1];
}
// real matrix element accessor (matrixElements is [*c]real34_t = allowzero).
inline fn mxRe34(elems: [*c]real34_t, i: usize) *align(1) real34_t {
    const p: [*]align(1) real34_t = @ptrCast(elems);
    return &p[i];
}

// vector register macros
inline fn isMatrix2dVector(rows: u16, cols: u16) bool {
    return (rows == 1 and cols == 2) or (rows == 2 and cols == 1);
}
inline fn isMatrix3dVector(rows: u16, cols: u16) bool {
    return (rows == 1 and cols == 3) or (rows == 3 and cols == 1);
}
inline fn isRegisterMatrix2dVector(reg: calcRegister_t) bool {
    if (getRegisterDataType(reg) != dtReal34Matrix) return false;
    const h = regMatrixHeader(reg);
    return isMatrix2dVector(h.matrixRows, h.matrixColumns);
}
inline fn isRegisterMatrix3dVector(reg: calcRegister_t) bool {
    if (getRegisterDataType(reg) != dtReal34Matrix) return false;
    const h = regMatrixHeader(reg);
    return isMatrix3dVector(h.matrixRows, h.matrixColumns);
}
inline fn getVectorRegisterAngularMode(reg: calcRegister_t) u32 {
    return if (getRegisterDataType(reg) == dtReal34Matrix) (getRegisterTag(reg) & amAngleMask) & amAngleMask else @as(u32, @intCast(amNone));
}
inline fn setVectorRegisterAngularMode(reg: calcRegister_t, am: u32) void {
    setRegisterTag(reg, (am & amAngleMask) | (getRegisterTag(reg) & amPolar));
}
inline fn getVectorRegisterPolarMode(reg: calcRegister_t) u32 {
    if (getRegisterDataType(reg) == dtReal34Matrix and (getRegisterTag(reg) & amAngleMask) != @as(u32, @intCast(amNone))) {
        if (isRegisterMatrix3dVector(reg)) {
            return if ((getRegisterTag(reg) & amPolar) == amPolar) amPolarSPH else amPolarCYL;
        } else if (isRegisterMatrix2dVector(reg)) {
            return getRegisterTag(reg) & amPolar;
        } else {
            return 0;
        }
    }
    return 0;
}
inline fn setVectorRegisterPolarMode(reg: calcRegister_t, pm: u32) void {
    const tag = getRegisterTag(reg);
    var newTag: u32 = undefined;
    if (pm == 0) {
        newTag = (tag & ~(amAngleMask | amPolar)) + @as(u32, @intCast(amNone));
    } else {
        const orPart: u32 = if (pm == amPolarSPH or pm == amPolar) amPolar else 0;
        const left = (tag & (amAngleMask | amPolar)) | orPart;
        const andMask: u32 = if (pm == amPolarCYL) ((~amPolar) & (amAngleMask | amPolar)) else 255;
        newTag = left & andMask;
    }
    setRegisterTag(reg, newTag);
}

// ===========================================================================
// SAVE_SPACE-gated helpers (file-static in C).
// ===========================================================================

// !SAVE_SPACE_DM42_23_EDIT2
// Upstream shares the bounded decoder in decode.c (getStringLabelOrVariableName);
// this local copy carries the same clamp so a corrupt step's length byte cannot
// read past the program region.
fn _getStringLabelOrVariableName(stringAddress: [*c]u8) void {
    const p = stringAddress + 1;
    var stringLength: u8 = stringAddress[0];
    if (@intFromPtr(p) >= @intFromPtr(firstFreeProgramByte)) {
        stringLength = 0;
    } else if (stringLength > @intFromPtr(firstFreeProgramByte) - @intFromPtr(p)) {
        stringLength = @intCast(@intFromPtr(firstFreeProgramByte) - @intFromPtr(p));
    }
    _ = frontier_char_string.xcopy(tmpStringLabelOrVariableName, p, stringLength);
    tmpStringLabelOrVariableName[stringLength] = 0;
}

// !SAVE_SPACE_DM42_22_EDIT1
pub export fn _fractionToString(regist: calcRegister_t, displayString: [*c]u8, lessEqualGreater: *i16) callconv(.c) void {
    var sign: i16 = undefined;
    var intPart: u64 = undefined;
    var numer: u64 = undefined;
    var denom: u64 = undefined;

    _ = frontier_fractions.fraction(regist, &sign, &intPart, &numer, &denom, lessEqualGreater);

    if (getSystemFlag(FLAG_PROPFR) != 0) { // a b/c
        abi.fmtCStr(displayString, "{s}{d} {d}/{d}", .{ @as([*:0]const u8, if (sign == -1) @as([*c]const u8, "-") else @as([*c]const u8, "+")), @as(u32, @truncate(intPart)), @as(u32, @truncate(numer)), @as(u32, @truncate(denom)) });
    } else { // FT_IMPROPER d/
        abi.fmtCStr(displayString, "{s}0 {d}/{d}", .{ @as([*:0]const u8, if (sign == -1) @as([*c]const u8, "-") else @as([*c]const u8, "+")), @as(u32, @truncate(numer)), @as(u32, @truncate(denom)) });
    }
}

pub export fn _shortIntegerToString(regist: calcRegister_t, displayString: [*c]u8) callconv(.c) void {
    var i: i16 = undefined;
    var j: i16 = undefined;
    var k: i16 = undefined;
    var unit: i16 = undefined;
    var base: i16 = undefined;
    var number: u64 = undefined;
    var sign: u64 = undefined;

    base = @intCast(getRegisterTag(regist));
    number = regShortInteger(regist).*;

    if (base <= 1 or base >= 17) {
        abi.fmtBufZ(errorMessage[0..512], "In function {s}:{d} is an unexpected value for {s}!", .{ "_shortIntegerToString", @as(c_int, base), "base" });
        frontier_error.displayBugScreen(errorMessage);
        base = 10;
    }

    if (shortIntegerMode == SIM_UNSIGN or base == 2 or base == 4 or base == 8 or base == 16) {
        sign = 0;
    } else {
        sign = number & shortIntegerSignBit;
    }

    if (sign != 0) {
        if (shortIntegerMode == SIM_2COMPL) {
            number |= ~shortIntegerMask;
            number = ~number +% 1;
        } else if (shortIntegerMode == SIM_1COMPL) {
            number = ~number;
        } else if (shortIntegerMode == SIM_SIGNMT) {
            number &= ~shortIntegerSignBit;
        } else {
            abi.fmtBufZ(errorMessage[0..512], "In function {s}:{d} is an unexpected value for {s}!", .{ "_shortIntegerToString", @as(c_int, shortIntegerMode), "shortIntegerMode" });
            frontier_error.displayBugScreen(errorMessage);
        }
        number &= shortIntegerMask;
    }

    i = @intCast(ERROR_MESSAGE_LENGTH / 2);

    if (number == 0) {
        displayString[@intCast(i)] = '0';
        i += 1;
    }

    while (number != 0) {
        unit = @intCast(@rem(number, @as(u64, @intCast(base))));
        number /= @as(u64, @intCast(base));
        displayString[@intCast(i)] = baseDigits[@intCast(unit)];
        i += 1;
    }

    if (sign != 0) {
        displayString[@intCast(i)] = '-';
        i += 1;
    } else {
        displayString[@intCast(i)] = '+';
        i += 1;
    }

    k = i - 1;
    j = 0;
    while (k >= @as(i16, @intCast(ERROR_MESSAGE_LENGTH / 2))) : ({
        k -= 1;
        j += 1;
    }) {
        if (displayString[@intCast(k)] == ' ') {
            displayString[@intCast(j)] = STD_SPACE_PUNCTUATION[0];
            j += 1;
            displayString[@intCast(j)] = STD_SPACE_PUNCTUATION[1];
        } else {
            displayString[@intCast(j)] = displayString[@intCast(k)];
        }
    }
    displayString[@intCast(j)] = 0;
    return;
}

// !SAVE_SPACE_DM42_22_EDIT1
fn _hmsTimeToReal() void {
    var i: i16 = 0;
    var j: i16 = 0;
    var decimalflag: bool = false;

    frontier_display.timeToDisplayString(REGISTER_X, tmpString, 1);

    while (tmpString[@intCast(i)] != 0) {
        switch (tmpString[@intCast(i)]) {
            '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '-' => {
                tmpString[@intCast(j)] = tmpString[@intCast(i)];
                j += 1;
            },
            ':' => {
                if (!decimalflag) {
                    decimalflag = true;
                    tmpString[@intCast(j)] = '.';
                    j += 1;
                }
            },
            else => {},
        }
        i += 1;
    }
    tmpString[@intCast(j)] = 0;

    if (tmpString[0] != 0) {
        reallocateRegister(REGISTER_X, dtReal34, @intCast(REAL34_SIZE_IN_BYTES), amNone);
        stringToReal34(tmpString, reg34(REGISTER_X));
    }
}

// !SAVE_SPACE_DM42_22_EDIT1
fn _real34ToNim(real34: *align(1) const real34_t, nimInput: [*c]u8, nimDisplay: [*c]u8) void {
    var i: u16 = undefined;
    const grpGroupingLeftOld = grpGroupingLeft;
    const grpGroupingRightOld = grpGroupingRight;

    grpGroupingLeft = 0;
    grpGroupingRight = 0;
    real34ToDisplayString(real34, amNone, tmpString, &standardFont, SCREEN_WIDTH, NUMBER_OF_DISPLAY_DIGITS, 1, STD_SPACE_PUNCTUATION, 1);
    grpGroupingRight = grpGroupingRightOld;
    grpGroupingLeft = grpGroupingLeftOld;

    var noDisplayExponent: bool = true;
    i = 0;
    while (i < strlen(tmpString)) : (i += 1) {
        if ((tmpString[i] == STD_SUB_10[0]) and (tmpString[i + 1] == STD_SUB_10[1])) {
            noDisplayExponent = false;
        }
    }
    grpGroupingLeft = 0;
    grpGroupingRight = 0;
    real34ToString(real34, nimDisplay);
    grpGroupingRight = grpGroupingRightOld;
    grpGroupingLeft = grpGroupingLeftOld;
    var dotFound: bool = false;
    if (noDisplayExponent) {
        i = 0;
        while (i < strlen(nimDisplay)) : (i += 1) {
            if ((nimDisplay[i] == 'e') or (nimDisplay[i] == 'E')) {
                _ = strcpy(nimDisplay, tmpString + @as(usize, if (tmpString[0] == '-') 0 else 1));
                break;
            }
            if (nimDisplay[i] == '.') {
                dotFound = true;
            }
        }
        if (dotFound) {
            i = @intCast(strlen(nimDisplay) - 1);
            while (i > 0) : (i -%= 1) {
                if (nimDisplay[i] == '0') {
                    nimDisplay[i] = 0; // remove trailing zeros
                } else {
                    break;
                }
            }
        }
    }
    if (real34IsPositive(real34)) {
        nimInput[0] = '+';
        _ = strcpy(nimInput + 1, nimDisplay);
    } else {
        _ = strcpy(nimInput, nimDisplay);
    }
    var exponentFound: bool = false;
    dotFound = false;
    i = 0;
    while (i < strlen(nimInput)) : (i += 1) {
        if (nimInput[i] == 'E') {
            nimInput[i] = 'e';
            dotFound = true;
            exponentFound = true;
            exponentSignLocation = @intCast(i + 1);
            nimNumberPart = NP_REAL_EXPONENT;
        }
        if (nimInput[i] == '.') {
            dotFound = true;
            nimNumberPart = NP_REAL_FLOAT_PART;
        }
    }
    if (!dotFound) {
        nimInput[i] = '.';
        nimNumberPart = NP_REAL_FLOAT_PART;
    }
    _ = strcpy(nimDisplay, STD_SPACE_HAIR);
    frontier_bufferize.nimBufferToDisplayBuffer(nimInput, nimDisplay + 2);
    i = @intCast(stringByteLength(nimDisplay) - 1);
    while (i > 0) : (i -%= 1) {
        if (nimDisplay[i] == 0xab) { // token
            nimDisplay[i] = SEPARATOR_LEFT()[0];
            if (nimDisplay[i + 1] == 1) {
                nimDisplay[i + 1] = SEPARATOR_LEFT()[1];
            }
        }
        if (nimDisplay[i] == 0xbb) { // token
            nimDisplay[i] = SEPARATOR_RIGHT()[0];
            if (nimDisplay[i + 1] == 1) {
                nimDisplay[i + 1] = SEPARATOR_RIGHT()[1];
            }
        }
    }
    if (exponentFound) {
        frontier_display.exponentToDisplayString(stringToInt32(nimInput + @as(usize, @intCast(exponentSignLocation))), nimDisplay + @as(usize, @intCast(stringByteLength(nimDisplay))), null, 1);
        if (nimInput[@as(usize, @intCast(exponentSignLocation)) + 1] == 0 and nimInput[@intCast(exponentSignLocation)] == '-') {
            _ = strcat(nimDisplay, STD_SUP_MINUS);
        } else if (nimInput[@as(usize, @intCast(exponentSignLocation)) + 1] == '0' and nimInput[@intCast(exponentSignLocation)] == '+') {
            _ = strcat(nimDisplay, STD_SUP_0);
        }
    }
}

// ===========================================================================
// fnEdit : the EDIT command.
// ===========================================================================
pub export fn fnEdit(unusedParamButMandatory: u16) callconv(.c) void {
    _ = unusedParamButMandatory;
    var index: i16 = 0;
    var grpGroupingLeftOld: u8 = 0;
    var grpGroupingRightOld: u8 = 0;
    var varOrLblName: [32]u8 = undefined; // C: char varOrLblName[32]; a name's byte length (opParam2) can exceed 7 with multi-byte glyphs

    if (tam.mode != 0) {
        frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnErr("In function fnEdit:", "Calculator mode or type not supported for EDIT command");
        return;
    }
    switch (calcMode) {
        CM_NORMAL => {
            if (frontier_softmenus.currentMenu() == -MNU_EQN or frontier_softmenus.currentMenu() == -MNU_Sfdx or frontier_softmenus.currentMenu() == -MNU_Solver_TOOL or frontier_softmenus.currentMenu() == -MNU_Sf_TOOL or frontier_softmenus.currentMenu() == -MNU_GRAPHS or
                (frontier_softmenus.currentMenu() == -MNU_MVAR and (currentSolverStatus & SOLVER_STATUS_USES_FORMULA) != 0 and (currentSolverStatus & SOLVER_STATUS_INTERACTIVE) != 0))
            {
                frontier_softmenus.showSoftmenu(-MNU_EQN);
                frontier_items.runFunction(ITM_EQ_EDI);
            } else {
                editNormalDispatch(&index, &grpGroupingLeftOld, &grpGroupingRightOld);
            }
        },
        CM_AIM => {
            frontier_items.runFunction(ITM_XEDIT);
        },
        CM_PEM => {
            editPem(&index, &grpGroupingLeftOld, &grpGroupingRightOld, &varOrLblName);
        },
        else => {
            frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnErr("In function fnEdit:", "Calculator mode or type not supported for EDIT command");
        },
    }
}

fn editErr() void {
    frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    moreInfoOnErr("In function fnEdit:", "Calculator mode or type not supported for EDIT command");
}

// CM_NORMAL data-type dispatch arm of fnEdit.
fn editNormalDispatch(index: *i16, grpGroupingLeftOld: *u8, grpGroupingRightOld: *u8) void {
    const dt = getRegisterDataType(REGISTER_X);
    if (comptime !save_space_edit) {
        switch (dt) {
            dtLongInteger => {
                editLongInteger();
                return;
            },
            dtReal34 => {
                editReal34(index, grpGroupingLeftOld, grpGroupingRightOld);
                return;
            },
            dtTime => {
                _hmsTimeToReal();
                setRegisterDataType(REGISTER_X, dtTime, amNone);
                editReal34(index, grpGroupingLeftOld, grpGroupingRightOld);
                return;
            },
            dtDate => {
                frontier_register_value_conversions.convertDateRegisterToReal34Register(REGISTER_X, REGISTER_X);
                setRegisterDataType(REGISTER_X, dtDate, amNone);
                editReal34(index, grpGroupingLeftOld, grpGroupingRightOld);
                return;
            },
            else => {},
        }
    }
    switch (dt) {
        dtString => {
            setSystemFlag(FLAG_ASLIFT);
            if (stringByteLength(regString(REGISTER_X)) < @as(i32, @intCast(AIM_BUFFER_LENGTH))) {
                _ = strcpy(aimBuffer, regString(REGISTER_X));
                T_cursorPos = @intCast(stringByteLength(aimBuffer));
                fnDrop(NOPARAM);
                shiftF = 0;
                shiftG = 0;
                frontier_calc_mode.calcModeAim(NOPARAM);
                frontier_softmenus.showSoftmenu(-MNU_ALPHA);
            }
        },
        dtReal34Matrix, dtComplex34Matrix => {
            frontier.fnEditMatrix(NOPARAM);
        },
        else => {
            if (comptime !save_space_edit) {
                if (dt == dtShortInteger) {
                    editShortInteger(grpGroupingLeftOld, grpGroupingRightOld);
                    return;
                }
            }
            editErr();
        },
    }
}

fn editLongInteger() void {
    @memset(nimBufferDisplay[0..NIM_BUFFER_EXTENDED_LENGTH], 0);
    var lgInt: longInteger_t = undefined;
    frontier_register_value_conversions.convertLongIntegerRegisterToLongInteger(REGISTER_X, &lgInt[0]);
    frontier_display.longIntegerToAllocatedString(&lgInt[0], nimBufferDisplay, NIM_BUFFER_EXTENDED_LENGTH);
    if (longIntegerIsPositiveOrZero(&lgInt)) {
        aimBuffer[0] = '+';
        _ = strcpy(aimBuffer + 1, nimBufferDisplay);
    } else {
        _ = strcpy(aimBuffer, nimBufferDisplay);
    }
    longIntegerFree(&lgInt);
    if (grpGroupingLeft > 0) {
        var len: i16 = @intCast(strlen(nimBufferDisplay));
        var i: i16 = len - @as(i16, @intCast(grpGroupingLeft));
        while (i > 0) : (i -= @intCast(grpGroupingLeft)) {
            if (i != 1 or nimBufferDisplay[0] != '-') {
                if (gapItemLeft != ITM_NULL) { // insert gapCharLeft
                    const lenGapItem: u8 = @intCast(strlen(&indexOfItems[gapItemLeft].itemSoftmenuName));
                    _ = frontier_char_string.xcopy(nimBufferDisplay + @as(usize, @intCast(i)) + lenGapItem, nimBufferDisplay + @as(usize, @intCast(i)), @intCast(len - i + 1));
                    _ = frontier_char_string.xcopy(nimBufferDisplay + @as(usize, @intCast(i)), &indexOfItems[gapItemLeft].itemSoftmenuName, lenGapItem);
                    len += @intCast(lenGapItem);
                }
            }
        }
    }

    if (frontier_char_string.stringWidth(nimBufferDisplay, &standardFont, true, true) < (SCREEN_WIDTH * 2) - 8) {
        calcMode = CM_NIM;
        clearSystemFlag(FLAG_ALPHA);
        freeRegisterData(REGISTER_X);
        setRegisterDataPointer(REGISTER_X, allocC47Blocks(REAL34_SIZE_IN_BLOCKS));
        setRegisterDataType(REGISTER_X, dtReal34, amNone);
        real34SetZero(reg34(REGISTER_X));
        hexDigits = 0;
        nimNumberPart = NP_INT_10;
        if (!checkHP()) {
            frontier_screen.clearRegisterLine(NIM_REGISTER_LINE, true, true);
        }
        xCursor = 1;
        cursorEnabled = 1;
        cursorFont = &numericFont;
    } else {
        @memset(nimBufferDisplay[0..NIM_BUFFER_EXTENDED_LENGTH], 0);
        aimBuffer[0] = 0;
        nimBufferDisplay[0] = 0;
    }
}

fn editReal34(index: *i16, grpGroupingLeftOld: *u8, grpGroupingRightOld: *u8) void {
    grpGroupingLeftOld.* = grpGroupingLeft;
    grpGroupingRightOld.* = grpGroupingRight;
    const xangularMode = getRegisterAngularMode(REGISTER_X);

    @memset(aimBuffer[0..AIM_BUFFER_LENGTH], 0);
    @memset(nimBufferDisplay[0..NIM_BUFFER_LENGTH], 0);

    if (xangularMode == amDMS) {
        frontier_conversion_angles.real34FromDegToDms(reg34(REGISTER_X), reg34(REGISTER_X));
    }

    var lessEqualGreater: i16 = 0;
    if (getSystemFlag(FLAG_FRACT) != 0) {
        grpGroupingLeft = 0;
        grpGroupingRight = 0;
        _fractionToString(REGISTER_X, aimBuffer, &lessEqualGreater);
        grpGroupingRight = grpGroupingRightOld.*;
        grpGroupingLeft = grpGroupingLeftOld.*;

        if (lessEqualGreater == 0) { // display fraction
            nimNumberPart = NP_FRACTION_DENOMINATOR;
            _ = strcpy(nimBufferDisplay, STD_SPACE_HAIR);
            frontier_bufferize.nimBufferToDisplayBuffer(aimBuffer, nimBufferDisplay + 2);
            _ = strcat(nimBufferDisplay, STD_SPACE_4_PER_EM);
            index.* = 2;
            while (aimBuffer[@intCast(index.*)] != ' ') : (index.* += 1) {}
            frontier_display.supNumberToDisplayString(stringToInt32(aimBuffer + @as(usize, @intCast(index.* + 1))), nimBufferDisplay + @as(usize, @intCast(stringByteLength(nimBufferDisplay))), null, 1);

            _ = strcat(nimBufferDisplay, "/");

            while (aimBuffer[@intCast(index.*)] != '/') : (index.* += 1) {}
            index.* += 1;
            if (aimBuffer[@intCast(index.*)] != 0) {
                frontier_display.subNumberToDisplayString(stringToInt32(aimBuffer + @as(usize, @intCast(index.*))), nimBufferDisplay + @as(usize, @intCast(stringByteLength(nimBufferDisplay))), null);
            }
        } else { // display real34
            _real34ToNim(reg34(REGISTER_X), aimBuffer, nimBufferDisplay);
        }
    } else { // display real34
        _real34ToNim(reg34(REGISTER_X), aimBuffer, nimBufferDisplay);
    }

    calcMode = CM_NIM;
    clearSystemFlag(FLAG_ALPHA);
    const dataType = getRegisterDataType(REGISTER_X);
    freeRegisterData(REGISTER_X);
    setRegisterDataPointer(REGISTER_X, allocC47Blocks(REAL34_SIZE_IN_BLOCKS));
    if ((dataType == dtTime) or (dataType == dtDate)) {
        setRegisterDataType(REGISTER_X, dataType, @intCast(xangularMode));
    } else {
        setRegisterDataType(REGISTER_X, dtReal34, @intCast(xangularMode));
    }
    real34SetZero(reg34(REGISTER_X));
    hexDigits = 0;
    if (!checkHP()) {
        frontier_screen.clearRegisterLine(NIM_REGISTER_LINE, true, true);
    }
    xCursor = 1;
    cursorEnabled = 1;
    cursorFont = &numericFont;
}

fn editShortInteger(grpGroupingLeftOld: *u8, grpGroupingRightOld: *u8) void {
    var i: u16 = undefined;
    grpGroupingLeftOld.* = grpGroupingLeft;
    grpGroupingRightOld.* = grpGroupingRight;

    @memset(aimBuffer[0..AIM_BUFFER_LENGTH], 0);
    @memset(nimBufferDisplay[0..NIM_BUFFER_LENGTH], 0);

    lastIntegerBase = getRegisterTag(REGISTER_X);
    nimNumberPart = if (lastIntegerBase <= 10) NP_INT_10 else NP_INT_16;

    grpGroupingLeft = 0;
    grpGroupingRight = 0;
    _shortIntegerToString(REGISTER_X, aimBuffer);
    grpGroupingRight = grpGroupingRightOld.*;
    grpGroupingLeft = grpGroupingLeftOld.*;

    hexDigits = 0;
    i = 0;
    while (i < strlen(aimBuffer)) : (i += 1) {
        if ((aimBuffer[i] >= 'A') and (aimBuffer[i] <= 'F')) {
            hexDigits += 1;
        }
    }

    _ = strcpy(nimBufferDisplay, STD_SPACE_HAIR);
    frontier_bufferize.nimBufferToDisplayBuffer(aimBuffer, nimBufferDisplay + 2);
    i = @intCast(stringByteLength(nimBufferDisplay) - 1);
    while (i > 0) : (i -%= 1) {
        if (nimBufferDisplay[i] == 0xab) { // token
            nimBufferDisplay[i] = SEPARATOR_LEFT()[0];
            if (nimBufferDisplay[i + 1] == 1) {
                nimBufferDisplay[i + 1] = SEPARATOR_LEFT()[1];
            }
        }
    }

    calcMode = CM_NIM;
    clearSystemFlag(FLAG_ALPHA);
    freeRegisterData(REGISTER_X);
    setRegisterDataPointer(REGISTER_X, allocC47Blocks(REAL34_SIZE_IN_BLOCKS));
    setRegisterDataType(REGISTER_X, dtReal34, amNone);
    if (!checkHP()) {
        frontier_screen.clearRegisterLine(NIM_REGISTER_LINE, true, true);
    }
    xCursor = 1;
    cursorEnabled = 1;
    cursorFont = &numericFont;
}

// CM_PEM arm of fnEdit (the program-step editor).
fn editPem(index: *i16, grpGroupingLeftOld: *u8, grpGroupingRightOld: *u8, varOrLblName: *[32]u8) void {
    if ((pemCursorIsZerothStep != 0) or isAtEndOfProgram(currentStep) != 0 or frontier_manage.isAtEndOfPrograms(currentStep)) {
        return; // Don't try to edit step 000 or END or .END.
    }
    var i: i16 = 0;
    var func: i16 = currentStep[@intCast(i)];
    i += 1;
    if ((func & 0x80) != 0) {
        func &= 0x7f;
        func <<= 8;
        func |= currentStep[@intCast(i)];
        i += 1;
    }
    const opParam: u8 = currentStep[@intCast(i)];
    i += 1;
    var opParam2: u8 = 0;
    var opParam3: u8 = 0;
    if (comptime !save_space_edit) {
        opParam2 = currentStep[@intCast(i)];
        i += 1;
        opParam3 = currentStep[@intCast(i)];
    }

    if ((func == ITM_LITERAL or func == ITM_REM)) {
        @memset(aimBuffer[0..AIM_BUFFER_LENGTH], 0);

        if (opParam == STRING_LABEL_VARIABLE) {
            frontier_manage.pemAlphaEdit(NOPARAM);
        } else if (comptime !save_space_edit) {
            if ((opParam == BINARY_SHORT_INTEGER) or (opParam == STRING_SHORT_INTEGER) or (opParam == STRING_LONG_INTEGER) or
                (opParam == BINARY_REAL34) or (opParam == STRING_REAL34) or
                (opParam == BINARY_COMPLEX34) or (opParam == STRING_COMPLEX34) or
                (opParam == STRING_DATE) or (opParam == STRING_TIME) or (opParam == STRING_ANGLE_DMS) or
                (opParam == STRING_ANGLE_RADIAN) or (opParam == STRING_ANGLE_GRAD) or
                (opParam == STRING_ANGLE_DEGREE) or (opParam == STRING_ANGLE_MULTPI))
            {
                editPemLiteral(opParam, opParam2, grpGroupingLeftOld, grpGroupingRightOld);
            }
        }
    } else if (comptime !save_space_edit) {
        editPemNonLiteral(func, opParam, opParam2, opParam3, &i, index, varOrLblName);
    }
}

fn editPemLiteral(opParam_in: u8, opParam2: u8, grpGroupingLeftOld: *u8, grpGroupingRightOld: *u8) void {
    const opParam = opParam_in;
    const tempBuffer: [*c]u8 = errorMessage + 3000;
    var chsNeeded: bool = false;
    const isDate: bool = (opParam == STRING_DATE);

    if ((opParam == STRING_REAL34) or (opParam == STRING_COMPLEX34)) {
        _getStringLabelOrVariableName(&currentStep[2]);
        _ = strcpy(tempBuffer, tmpStringLabelOrVariableName);
    } else {
        grpGroupingLeftOld.* = grpGroupingLeft;
        grpGroupingRightOld.* = grpGroupingRight;
        grpGroupingRight = 0;
        grpGroupingLeft = 0;
        frontier_decode.decodeOneStep(currentStep);
        grpGroupingRight = grpGroupingRightOld.*;
        grpGroupingLeft = grpGroupingLeftOld.*;
        _ = strcpy(tempBuffer, tmpString);
    }
    lastIntegerBase = if (opParam == BINARY_SHORT_INTEGER) opParam2 else if (opParam == STRING_SHORT_INTEGER) opParam2 else 0;
    frontier_manage.deleteStepsFromTo(currentStep, frontier_next_step.findNextStep(currentStep));

    var i: u16 = 0;
    const iMax: u16 = @intCast(strlen(tempBuffer));
    var decimalflag: bool = false;
    while (i < iMax) : (i += 1) {
        switch (tempBuffer[i]) {
            '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' => {
                frontier_manage.pemAddNumber(@as(i16, ITM_0) + @as(i16, tempBuffer[i]) - '0', false);
            },
            'A', 'B', 'C', 'D', 'E', 'F' => {
                frontier_manage.pemAddNumber(@as(i16, ITM_A) + @as(i16, tempBuffer[i]) - 'A', false);
            },
            '.' => {
                if (!decimalflag) {
                    decimalflag = true;
                    frontier_manage.pemAddNumber(ITM_PERIOD, false);
                }
            },
            ':' => {
                if (!decimalflag) {
                    decimalflag = true;
                    frontier_manage.pemAddNumber(ITM_PERIOD, false);
                }
            },
            '+' => {
                if (chsNeeded) {
                    frontier_manage.pemAddNumber(ITM_CHS, false);
                }
                chsNeeded = false;
                if (opParam == BINARY_COMPLEX34) {
                    frontier_manage.pemAddNumber(ITM_CC, false);
                    decimalflag = false;
                }
            },
            '-' => {
                if (isDate) {
                    if (!decimalflag) {
                        decimalflag = true;
                        frontier_manage.pemAddNumber(ITM_PERIOD, false);
                    }
                } else {
                    if (chsNeeded) {
                        frontier_manage.pemAddNumber(ITM_CHS, false);
                    }
                    chsNeeded = true;
                    if (opParam == BINARY_COMPLEX34) {
                        frontier_manage.pemAddNumber(ITM_CC, false);
                        decimalflag = false;
                    }
                }
            },
            '/' => {
                if (isDate) {
                    if (!decimalflag) {
                        decimalflag = true;
                        frontier_manage.pemAddNumber(ITM_PERIOD, false);
                    }
                }
            },
            'e' => {
                if (chsNeeded) {
                    frontier_manage.pemAddNumber(ITM_CHS, false);
                }
                chsNeeded = false;
                frontier_manage.pemAddNumber(ITM_EXPONENT, false);
            },
            'i' => {
                frontier_manage.pemAddNumber(ITM_CC, false);
                decimalflag = false;
            },
            0x80 => {
                i += 1;
                if ((tempBuffer[i] == STD_CROSS[1]) and (nimNumberPart != NP_COMPLEX_INT_PART)) {
                    i += 2; // Skip next character (STD_BASE_10)
                    if (chsNeeded) {
                        frontier_manage.pemAddNumber(ITM_CHS, false);
                    }
                    chsNeeded = false;
                    frontier_manage.pemAddNumber(ITM_EXPONENT, false);
                } else if ((tempBuffer[i] == STD_DEGREE[1]) and (opParam == STRING_ANGLE_DMS)) {
                    frontier_manage.pemAddNumber(ITM_PERIOD, false);
                }
            },
            0xa1 => {
                i += 1;
                if ((tempBuffer[i] >= STD_SUP_0[1]) and (tempBuffer[i] <= STD_SUP_9_1)) {
                    frontier_manage.pemAddNumber(@as(i16, ITM_0) + @as(i16, tempBuffer[i]) - STD_SUP_0[1], false);
                } else if (tempBuffer[i] == STD_SUP_MINUS[1]) {
                    chsNeeded = true;
                } else if (((tempBuffer[i] == STD_op_i_1) or (tempBuffer[i] == STD_op_j_1)) and (nimNumberPart != NP_COMPLEX_INT_PART)) {
                    frontier_manage.pemAddNumber(ITM_CC, false);
                    decimalflag = false;
                }
            },
            0x81, 0x82, 0x83, 0x9d, 0x9e, 0xa0, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7, 0xa9, 0xab, 0xac => {
                i += 1; // Ignore non supported unicode characters, including base subscripts
            },
            else => {},
        }
        lastIntegerBase = if (opParam == BINARY_SHORT_INTEGER) opParam2 else if (opParam == STRING_SHORT_INTEGER) opParam2 else 0;
    }
    if (chsNeeded) {
        frontier_manage.pemAddNumber(ITM_CHS, false);
    }
    switch (opParam) {
        STRING_DATE, STRING_TIME, STRING_ANGLE_RADIAN, STRING_ANGLE_GRAD, STRING_ANGLE_DEGREE, STRING_ANGLE_DMS, STRING_ANGLE_MULTPI => {
            editingLiteralType = opParam;
        },
        else => {
            editingLiteralType = 0;
        },
    }
    frontier_manage.pemAddNumber(ITM_NOP, true); // to insert the resulting number in program
}

fn editPemNonLiteral(func_in: i16, opParam_in: u8, opParam2_in: u8, opParam3: u8, ip: *i16, index: *i16, varOrLblName: *[32]u8) void {
    var func = func_in;
    var opParam = opParam_in;
    var opParam2 = opParam2_in;
    var i = ip.*;
    var regNumber: u16 = undefined;
    const paramMode: u16 = (indexOfItems[@intCast(func)].status & PTP_STATUS) >> 9;
    if ((opParam == STRING_LABEL_VARIABLE) or (opParam == INDIRECT_VARIABLE)) {
        index.* = 0;
        while (index.* < opParam2) : (index.* += 1) {
            varOrLblName[@intCast(index.*)] = currentStep[@intCast(i)];
            i += 1;
        }
        varOrLblName[@intCast(index.*)] = 0;
    }
    switch (paramMode) {
        PARAM_DECLARE_LABEL, PARAM_LABEL, PARAM_REGISTER, PARAM_FLAG, PARAM_NUMBER_8, PARAM_NUMBER_16, PARAM_COMPARE, PARAM_SKIP_BACK, PARAM_NUMBER_8_16, PARAM_SHUFFLE, PARAM_MENU => {
            frontier_manage.deleteStepsFromTo(currentStep, frontier_next_step.findNextStep(currentStep));
            if (pemCursorIsZerothStep == 0) {
                frontier_next_step.fnBst(NOPARAM);
            }
            frontier_tam.tamEnterMode(func);

            var maxDigits: u8 = if (tam.max < 10) 1 else if (tam.max < 100) 2 else if (tam.max < 1000) 3 else if (tam.max < 10000) 4 else 5;

            if ((opParam == INDIRECT_REGISTER) and (frontier_items.isFunctionOldParam16(@intCast(func)) == 0)) {
                tam.indirect = true;
                tam.max = 99;
                maxDigits = 2;
                opParam = opParam2;
                opParam2 = opParam3;
                frontier_softmenus.popSoftmenu();
                frontier_softmenus.showSoftmenu(-MNU_TAM);
                numberOfTamMenusToPop -= 1;
            } else if ((opParam == INDIRECT_VARIABLE) and (frontier_items.isFunctionOldParam16(@intCast(func)) == 0)) {
                tam.indirect = true;
                opParam = STRING_LABEL_VARIABLE;
                frontier_softmenus.popSoftmenu();
                frontier_softmenus.showSoftmenu(-MNU_TAM);
                numberOfTamMenusToPop -= 1;
            }

            regNumber = opParam;
            if ((paramMode == PARAM_REGISTER) or (paramMode == PARAM_COMPARE) or tam.indirect) {
                if (opParam <= LAST_SPARE_REGISTERS_IN_KS_CODE) {
                    regNumber = regKStoC(opParam);
                }
            }

            if ((paramMode == PARAM_FLAG) and opParam == SYSTEM_FLAG_NUMBER) {
                tam.digitsSoFar = 0;
                tam.value = 0;
            } else if (opParam == STRING_LABEL_VARIABLE) {
                tam.digitsSoFar = 0;
                tam.value = 0;
            } else if ((paramMode == PARAM_COMPARE) and ((opParam == VALUE_0) or (opParam == VALUE_1))) {
                tam.digitsSoFar = 0;
                tam.value = 0;
            } else if ((paramMode == PARAM_FLAG) and opParam > LAST_GLOBAL_FLAG) {
                tam.dot = true;
                tam.digitsSoFar = @as(i16, maxDigits) - 1;
                tam.value = @intCast((opParam - FIRST_LOCAL_FLAG) / 10);
            } else if (((paramMode == PARAM_REGISTER) or (paramMode == PARAM_COMPARE) or tam.indirect) and (regNumber > LAST_GLOBAL_REGISTER)) {
                tam.dot = true;
                tam.digitsSoFar = @as(i16, maxDigits) - 1;
                tam.value = @intCast((regNumber - FIRST_LOCAL_REGISTER) / 10);
            } else if (((paramMode == PARAM_REGISTER) or (paramMode == PARAM_FLAG) or (paramMode == PARAM_COMPARE) or tam.indirect) and opParam >= REGISTER_X) {
                tam.digitsSoFar = 0;
                tam.value = 0;
            } else if (((paramMode == PARAM_DECLARE_LABEL) or (paramMode == PARAM_LABEL)) and opParam >= 100) {
                tam.digitsSoFar = 0;
                tam.value = 0;
            } else if ((paramMode == PARAM_NUMBER_16) and !tam.indirect) {
                tam.digitsSoFar = @as(i16, maxDigits) - 1;
                if (frontier_items.isFunctionOldParam16(@intCast(func)) != 0) {
                    tam.value = @intCast(((@as(u16, opParam2) << 8) + opParam) / 10);
                } else {
                    tam.value = @intCast(((@as(u16, opParam) << 8) + opParam2) / 10);
                }
            } else if (paramMode == PARAM_SHUFFLE) {
                tam.digitsSoFar = 3;
                tam.value = @as(i16, opParam & 0x3F) + 0x1500;
            } else if ((paramMode == PARAM_NUMBER_8_16) and opParam == CNST_BEYOND_250) {
                tam.digitsSoFar = @as(i16, maxDigits) - 1;
                tam.value = @intCast((opParam2 / 10) + 25);
            } else {
                tam.digitsSoFar = @as(i16, maxDigits) - 1;
                tam.value = @intCast(opParam / 10);
            }
            frontier_tam.tamProcessInput(@intCast(func));
            if (opParam == STRING_LABEL_VARIABLE) {
                frontier_tam.tamProcessInput(ITM_alpha);
                if (frontier_char_string.stringGlyphLength(varOrLblName) == 7) {
                    varOrLblName[@intCast(frontier_char_string.stringLastGlyph(varOrLblName))] = 0; // Ensure name is 6 characters maximum
                }
                _ = strcpy(aimBuffer, varOrLblName);
                alphaCursor = @intCast(frontier_char_string.stringGlyphLength(varOrLblName));
                frontier_tam.tamProcessInput(ITM_NOP);
            }
        },
        PARAM_KEYG_KEYX => {
            if (func == ITM_KEY) {
                func = if (opParam2 == ITM_GTO) ITM_KEYG else ITM_KEYX;
            } else { // ITM_42KEY
                func = if (opParam2 == ITM_GTO) ITM_42KEYG else ITM_42KEYX;
            }
            frontier_manage.deleteStepsFromTo(currentStep, frontier_next_step.findNextStep(currentStep));
            if (pemCursorIsZerothStep == 0) {
                frontier_next_step.fnBst(NOPARAM);
            }
            frontier_items.runFunction(func);
            frontier_tam.tamProcessInput(@intCast(@as(i16, ITM_0) + @divTrunc(@as(i16, opParam), 10)));
            frontier_tam.tamProcessInput(@intCast(@as(i16, ITM_0) + @as(i16, opParam % 10)));
            if ((opParam3 == INDIRECT_REGISTER) or (opParam3 == INDIRECT_VARIABLE)) {
                frontier_tam.tamProcessInput(ITM_INDIRECTION);
            }
        },
        PARAM_REM => {
            _ = memset(aimBuffer, 0, AIM_BUFFER_LENGTH);
            frontier_manage.deleteStepsFromTo(currentStep, frontier_next_step.findNextStep(currentStep));
            if (pemCursorIsZerothStep == 0) {
                frontier_next_step.fnBst(NOPARAM);
            }
            frontier_tam.tamEnterMode(func);
            if (frontier_char_string.stringGlyphLength(varOrLblName) == (if (@as(u16, @bitCast(func)) == ITM_42STRING) @as(i32, 15) else @as(i32, 14))) {
                varOrLblName[@intCast(frontier_char_string.stringLastGlyph(varOrLblName))] = 0; // Ensure name is 14 (42STRING) or 13 (42APPEND) characters maximum
            }
            _ = strcpy(aimBuffer, varOrLblName);
            alphaCursor = @intCast(frontier_char_string.stringGlyphLength(varOrLblName));
            frontier_tam.tamProcessInput(ITM_NOP); // to insert the resulting string in program
        },
        else => {},
    }
}

// ===========================================================================
// DMCP ROM trampolines (lft_ifc.h offsets; reached only under dmcp_build).
// ===========================================================================
const LcdFillRectFn = *const fn (u32, u32, u32, u32, c_int) callconv(.c) void;
const CreateScreenshotFn = *const fn (c_int) callconv(.c) c_int;
const KeyEmptyFn = *const fn () callconv(.c) c_int;
const KeyTailFn = *const fn () callconv(.c) c_int;
const KeyPopFn = *const fn () callconv(.c) c_int;
const KeyPopAllFn = *const fn () callconv(.c) void;
const WaitForKeyReleaseFn = *const fn (c_int) callconv(.c) c_int;

const c_lcd_fill_rect = @extern(LcdFillRectFn, .{ .name = "lcd_fill_rect" });
inline fn lcd_fill_rect(x: u32, y: u32, dx: u32, dy: u32, val: c_int) void {
    // On firmware this is a ROM trampoline; on host the linkable symbol exists
    // (see frontier_status_bar_owned), so the CB background-clear works on PC too.
    if (comptime dmcp_build) {
        const f: LcdFillRectFn = @ptrFromInt(LIBRARY_FN_BASE + 60);
        f(x, y, dx, dy, val);
    } else {
        c_lcd_fill_rect(x, y, dx, dy, val);
    }
}
inline fn create_screenshot(a: c_int) c_int {
    const f: CreateScreenshotFn = @ptrFromInt(LIBRARY_FN_BASE + 376);
    return f(a);
}
inline fn key_empty() c_int {
    const f: KeyEmptyFn = @ptrFromInt(LIBRARY_FN_BASE + 380);
    return f();
}
inline fn key_tail() c_int {
    const f: KeyTailFn = @ptrFromInt(LIBRARY_FN_BASE + 388);
    return f();
}
inline fn key_pop() c_int {
    const f: KeyPopFn = @ptrFromInt(LIBRARY_FN_BASE + 392);
    return f();
}
inline fn key_pop_all() void {
    const f: KeyPopAllFn = @ptrFromInt(LIBRARY_FN_BASE + 400);
    f();
}
inline fn wait_for_key_release(a: c_int) c_int {
    const f: WaitForKeyReleaseFn = @ptrFromInt(LIBRARY_FN_BASE + 420);
    return f(a);
}

const force: u8 = 1;
const DISPLAY_WAIT_FOR_RELEASE: bool_t = 1;

// ===========================================================================
// standardScreenDump (DMCP_BUILD) + key buffer helpers.
// ===========================================================================
fn standardScreenDump() void {
    resetShiftState();
    var vol: i32 = 0;
    vol = getBeepVolume();
    fnSetVolume(11);
    _Buzz(100, 5);
    _ = frontier_char_string.xcopy(tmpString, errorMessage, @intCast(ERROR_MESSAGE_LENGTH + AIM_BUFFER_LENGTH + NIM_BUFFER_LENGTH + TAM_BUFFER_LENGTH));
    _ = create_screenshot(0);
    _ = frontier_char_string.xcopy(errorMessage, tmpString, @intCast(ERROR_MESSAGE_LENGTH + AIM_BUFFER_LENGTH + NIM_BUFFER_LENGTH + TAM_BUFFER_LENGTH));
    _Buzz(100, 5);
    fnSetVolume(@intCast(vol));
}

comptime {
    if (dmcp_build) {
        @export(&standardScreenDumpExport, .{ .name = "standardScreenDump" });
    }
}
fn standardScreenDumpExport() callconv(.c) void {
    standardScreenDump();
}

pub export fn anyKeyWaiting() callconv(.c) bool_t {
    if (comptime dmcp_build) {
        return @intFromBool(key_empty() == 0 or key_tail() != -1);
    } else {
        return @intFromBool(currentKeyCode == 32);
    }
}

pub export fn exitKeyWaiting() callconv(.c) bool_t {
    if (comptime dmcp_build) {
        const checkKey: bool_t = @intFromBool(C47PopKeyNoBuffer(DISPLAY_WAIT_FOR_RELEASE) == 32);
        if (checkKey == 0) {
            key_pop_all();
            clearKeyBuffer();
        }
        return checkKey;
    } else {
        return @intFromBool(currentKeyCode == 32);
    }
}

pub export fn C47PopKeyNoBuffer(displayWaitForRelease: bool_t) callconv(.c) c_int {
    var tmpf: c_int = -1;
    if (comptime dmcp_build) {
        if (anyKeyWaiting() == 0) {
            return -1;
        }
        if (displayWaitForRelease != 0) {
            frontier_screen.force_refresh(force);
        }
        _ = wait_for_key_release(0);
        var signalToDoScreenDump: bool = false;
        var signalToDoEXIT: bool = false;
        var signalToDoRS: bool = false;
        var tmpz: c_int = -1;
        while (anyKeyWaiting() != 0) {
            tmpz = key_pop();
            if (tmpz > 0) {
                tmpf = tmpz;
            }
            if (tmpz == 44) {
                signalToDoScreenDump = true;
            }
            if (tmpz == 33) {
                signalToDoEXIT = true;
            }
            if (tmpz == 36) {
                signalToDoRS = true;
            }
        }

        if (signalToDoScreenDump) {
            standardScreenDump();
            tmpf = 0;
        }
        if (signalToDoRS) {
            tmpf = 36;
        }
        if (signalToDoEXIT) {
            tmpf = 33;
        }
        return tmpf - 1; // EXIT = 33-1
    } else {
        tmpf = currentKeyCode;
        currentKeyCode = 255;
        return tmpf; // EXIT = 32
    }
}

pub export fn fnShoiXRepeats(numberOfRepeats: u16) callconv(.c) void {
    displayStackSHOIDISP = @intCast(numberOfRepeats);
    frontier_radio_button_catalog.fnRefreshState();
}

pub export fn fnFrom_ymd(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (getRegisterDataType(REGISTER_X) == dtDate) {
        fnToReal(NOPARAM);
    }
}

pub export fn fnFrom_ms(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    fnFrom_msRegisterImpl(REGISTER_X);
}

// Register-parametrized form of fnFrom_ms; used by the data-file serializer to
// convert a dtTime register to its HHMMSS-coded real (master fnFrom_msRegister).
pub export fn fnFrom_msRegister(regist: i16) callconv(.c) void {
    fnFrom_msRegisterImpl(regist);
}

fn fnFrom_msRegisterImpl(regist: i16) void {
    var tmpString100: [100]u8 = undefined;
    var tmpString100_OUT: [100]u8 = undefined;
    tmpString100[0] = 0;
    tmpString100_OUT[0] = 0;

    if (getRegisterDataType(regist) == dtTime) {
        temporaryInformation = TI_FROM_MS_TIME;
    } else if (getRegisterDataType(regist) == dtReal34 and getRegisterAngularMode(regist) != amNone) {
        if (getRegisterAngularMode(regist) != amDMS) {
            fnAngularModeJM(amDMS);
        }
        temporaryInformation = TI_FROM_MS_DEG;
    } else {
        temporaryInformation = TI_NO_INFO;
    }

    if (temporaryInformation != TI_NO_INFO) {
        if (temporaryInformation == TI_FROM_MS_TIME) {
            frontier_display.timeToDisplayString(regist, &tmpString100, 1);
        }
        if (temporaryInformation == TI_FROM_MS_DEG) {
            // !LIMITEXP=0, FRONTSPACE=1, NOIRFRAC=0
            real34ToDisplayString(reg34(regist), getRegisterAngularMode(regist), &tmpString100, &standardFont, SCREEN_WIDTH, NUMBER_OF_DISPLAY_DIGITS, 0, 1, 0);
            var tmp_i: i16 = 0;
            while (tmpString100[@intCast(tmp_i)] != 0 and tmpString100[@intCast(tmp_i + 1)] != 0) : (tmp_i += 1) {
                if (tmpString100[@intCast(tmp_i)] == 128 and tmpString100[@intCast(tmp_i + 1)] == 176) {
                    tmpString100[@intCast(tmp_i)] = ' ';
                    tmpString100[@intCast(tmp_i + 1)] = 'o';
                }
                if (tmpString100[@intCast(tmp_i)] == 'o' and tmpString100[@intCast(tmp_i + 1)] == ' ') {
                    tmpString100[@intCast(tmp_i + 1)] = '0';
                }
                if (tmpString100[@intCast(tmp_i)] == ':' and tmpString100[@intCast(tmp_i + 1)] == ' ') {
                    tmpString100[@intCast(tmp_i + 1)] = '0';
                }
                if (tmpString100[@intCast(tmp_i)] == '\'' and tmpString100[@intCast(tmp_i + 1)] == ' ') {
                    tmpString100[@intCast(tmp_i + 1)] = '0';
                }
            }
        }

        var tmp_j: i16 = 0;
        var tmp_i: i16 = 0;
        var decimalflag: bool = false;
        while (tmpString100[@intCast(tmp_i)] != 0) {
            switch (tmpString100[@intCast(tmp_i)]) {
                '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '-' => {
                    tmpString100_OUT[@intCast(tmp_j)] = tmpString100[@intCast(tmp_i)];
                    tmp_j += 1;
                    tmpString100_OUT[@intCast(tmp_j)] = 0;
                },
                'o', ':', '.', ',' => {
                    if (!decimalflag) {
                        decimalflag = true;
                        tmpString100_OUT[@intCast(tmp_j)] = '.';
                        tmp_j += 1;
                        tmpString100_OUT[@intCast(tmp_j)] = 0;
                    }
                },
                else => {},
            }
            tmp_i += 1;
        }

        if (tmpString100_OUT[0] != 0) {
            reallocateRegister(regist, dtReal34, 0, amNone);
            stringToReal34(&tmpString100_OUT, reg34(regist));
        }
    }
}

pub export fn fnTo_ms(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    switch (calcMode) {
        CM_NIM => {
            frontier_bufferize.addItemToNimBuffer(ITM_ms);
        },
        CM_NORMAL => {
            copySourceRegisterToDestRegister(REGISTER_L, TEMP_REGISTER_1);

            switch (getRegisterDataType(REGISTER_X)) {
                dtShortInteger => {
                    frontier_register_value_conversions.convertShortIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
                },
                dtLongInteger => {
                    frontier_register_value_conversions.convertLongIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
                },
                else => {},
            }

            if (getRegisterDataType(REGISTER_X) == dtReal34) {
                if (getRegisterAngularMode(REGISTER_X) == amDMS) {
                    if (calcMode == CM_NORMAL) {
                        fnToReal(0);
                    } else if (calcMode == CM_NIM) {
                        frontier_bufferize.addItemToNimBuffer(ITM_dotD);
                    }
                    frontier_date_time.fnHRtoTM(0);
                } else if (getRegisterAngularMode(REGISTER_X) == amDegree) {
                    fnAngularModeJM(amDMS);
                } else if (getRegisterAngularMode(REGISTER_X) == amNone) {
                    frontier_date_time.fnHRtoTM(0);
                } else {
                    frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
                    moreInfoOnErr("In function fnTo_ms:", "cannot calculate specific type/tag");
                }
            } else if (getRegisterDataType(REGISTER_X) == dtTime) {
                frontier_date_time.fnToHr(0);
                setRegisterAngularMode(REGISTER_X, amDegree);
                frontier_conversion_angles.fnCvtFromCurrentAngularMode(amDMS);
            }

            copySourceRegisterToDestRegister(TEMP_REGISTER_1, REGISTER_L);
        },
        CM_REGISTER_BROWSER, CM_ASN_BROWSER, CM_FLAG_BROWSER, CM_FONT_BROWSER, CM_PLOT_STAT, CM_LISTXY, CM_GRAPH => {},
        else => {
            abi.fmtBufZ(errorMessage[0..512], "In function {s}: unexpected calcMode value ({d}) while processing key {s}!", .{ "fnTo_ms", @as(c_int, calcMode), ".ms" });
            frontier_error.displayBugScreen(errorMessage);
        },
    }
}

pub export fn addzeroes(st: [*c]u8, ix: u8) callconv(.c) void {
    var iy: u8 = undefined;
    _ = strcpy(st, "1");
    iy = 0;
    while (iy < ix) : (iy += 1) {
        _ = strcat(st, "0");
    }
}

pub export fn fnMultiplySI(multiplier: u16) callconv(.c) void {
    copySourceRegisterToDestRegister(REGISTER_L, TEMP_REGISTER_1);
    var mult: [64]u8 = undefined;
    var divi: [64]u8 = undefined;
    mult[0] = 0;
    divi[0] = 0;

    var base: u16 = 10;

    if (multiplier > 100 and multiplier <= 100 + 18) {
        addzeroes(&mult, @intCast(multiplier - 100));
        base = 10;
    } else if (multiplier < 100 and multiplier >= 100 - 18) {
        addzeroes(&divi, @intCast(100 - multiplier));
        base = 10;
    } else if (multiplier == 100) {
        _ = strcpy(&mult, "1");
        base = 10;
    } else if (multiplier > 200 and multiplier <= 200 + 50) {
        addzeroes(&mult, @intCast(multiplier - 200));
        base = 2;
    } else if (multiplier == 200) {
        _ = strcpy(&mult, "1");
        base = 2;
    }

    setSystemFlag(FLAG_ASLIFT);
    liftStack();
    var lgInt: longInteger_t = undefined;
    longIntegerInit(&lgInt);

    if (mult[0] != 0) {
        stringToLongInteger(&mult[@as(usize, if (mult[0] == '+') 1 else 0)], base, &lgInt[0]);
        frontier_register_value_conversions.convertLongIntegerToLongIntegerRegister(&lgInt[0], REGISTER_X);
        longIntegerFree(&lgInt);
        fnMultiply(0);
    } else if (divi[0] != 0) {
        stringToLongInteger(&divi[@as(usize, if (divi[0] == '+') 1 else 0)], base, &lgInt[0]);
        frontier_register_value_conversions.convertLongIntegerToLongIntegerRegister(&lgInt[0], REGISTER_X);
        longIntegerFree(&lgInt);
        fnDivide(0);
    }

    adjustResult(REGISTER_X, 0, 0, REGISTER_X, REGISTER_Y, -1);
    copySourceRegisterToDestRegister(TEMP_REGISTER_1, REGISTER_L);
}

fn cpxToStk(real1: *const real_t, real2: *const real_t, sl: bool) void {
    if (sl == forcedLiftTheStack) {
        setSystemFlag(FLAG_ASLIFT);
    }
    liftStack();
    frontier_register_value_conversions.convertComplexToResultRegister(real1, real2, REGISTER_X);
}

pub export fn fn_cnst_op_j(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (calcMode == CM_NIM or calcMode == CM_MIM) {
        fnKeyCC(ITM_op_j);
    } else {
        cpxToStk(const_0, const_1, !forcedLiftTheStack);
    }
}

pub export fn fn_cnst_op_j_pol(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (calcMode == CM_NIM or calcMode == CM_MIM) {
        fnKeyCC(ITM_op_j_pol);
    } else {
        cpxToStk(const_0, const_1, !forcedLiftTheStack);
        fnToPolar2(0);
    }
}

pub export fn fn_cnst_op_aa(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    cpxToStk(const_1on2, const39_root3on2, !forcedLiftTheStack);
    chsCplx();
}

pub export fn fn_cnst_op_a(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    fn_cnst_op_aa(0);
    conjCplx();
}

pub export fn fn_cnst_0_cpx(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    cpxToStk(const_0, const_0, !forcedLiftTheStack);
}

pub export fn fn_cnst_1_cpx(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    cpxToStk(const_1, const_0, !forcedLiftTheStack);
}

pub export fn fn_cnst_op_A(option: u16) callconv(.c) void {
    var matrixC: complex34Matrix_t = undefined;
    const inverted: bool = option == ITM_MATX_A_1;

    if (saveLastX() == 0) {
        return;
    }

    setSystemFlag(FLAG_ASLIFT);
    liftStack();
    frontier_register_value_conversions.convertRealToResultRegister(const_0, REGISTER_X, amNone);

    if (initMatrixRegister(REGISTER_X, 3, 3, 1) != 0) {} else {
        frontier_error.displayCalcErrorMessage(ERROR_NOT_ENOUGH_MEMORY_FOR_NEW_MATRIX, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnErr("In function fn_cnst_op_A:", "Not enough memory for a 1\xc3\x97" ++ "1 matrix");
        return;
    }
    adjustResult(REGISTER_X, 0, 0, REGISTER_X, -1, -1);

    linkToComplexMatrixRegister(REGISTER_X, &matrixC);

    var const__rt3on2: real_t = undefined;
    var const_rt3on2: real_t = undefined;
    var const__1on2: real_t = undefined;
    realMultiply(const39_rt3, const_1on2, &const_rt3on2, &ctxtReal39);
    realMultiply(const39_rt3, const_1on2, &const__rt3on2, &ctxtReal39);
    realSetNegativeSign(&const__rt3on2);
    realCopy(const_1on2, &const__1on2);
    realSetNegativeSign(&const__1on2);

    const me = matrixC.matrixElements;
    realToReal34(&const__1on2, varReal34(me, 4));
    realToReal34(if (!inverted) &const_rt3on2 else &const__rt3on2, varImag34(me, 4));
    realToReal34(&const__1on2, varReal34(me, 5));
    realToReal34(if (!inverted) &const__rt3on2 else &const_rt3on2, varImag34(me, 5));
    realToReal34(&const__1on2, varReal34(me, 7));
    realToReal34(if (!inverted) &const__rt3on2 else &const_rt3on2, varImag34(me, 7));
    realToReal34(&const__1on2, varReal34(me, 8));
    realToReal34(if (!inverted) &const_rt3on2 else &const__rt3on2, varImag34(me, 8));

    var i: usize = 0;
    while (i < 3) : (i += 1) {
        realToReal34(const_1, varReal34(me, i));
        real34SetZero(varImag34(me, i));
        if (i != 0) {
            realToReal34(const_1, varReal34(me, i * 3));
            real34SetZero(varImag34(me, i * 3));
        }
    }
    adjustResult(REGISTER_X, 0, 1, REGISTER_X, -1, -1);
}

// ===========================================================================
// OPTION_VECTOR / OPTION_ELEC : stk <-> mx converters.
// ===========================================================================
const vector_or_elec = option_vector or option_elec;

// vecCreate[]: TO_QSPI static const bitfield table {rows:2,cols:2,x:2,y:2,z:2,
// xdef:2,ydef:2,zdef:2}, stride 4 bytes. Probed packed-u16 values per index.
const vecCreate_t = struct {
    bits: u16,
    _pad: u16 = 0,
    inline fn rows(self: vecCreate_t) u8 {
        return @intCast(self.bits & 0x3);
    }
    inline fn cols(self: vecCreate_t) u8 {
        return @intCast((self.bits >> 2) & 0x3);
    }
    inline fn x(self: vecCreate_t) u8 {
        return @intCast((self.bits >> 4) & 0x3);
    }
    inline fn y(self: vecCreate_t) u8 {
        return @intCast((self.bits >> 6) & 0x3);
    }
    inline fn z(self: vecCreate_t) u8 {
        return @intCast((self.bits >> 8) & 0x3);
    }
    inline fn xdef(self: vecCreate_t) u8 {
        return @intCast((self.bits >> 10) & 0x3);
    }
    inline fn ydef(self: vecCreate_t) u8 {
        return @intCast((self.bits >> 12) & 0x3);
    }
    inline fn zdef(self: vecCreate_t) u8 {
        return @intCast((self.bits >> 14) & 0x3);
    }
};
// index: AUT=0,zxy=1,zyx=2,100=3,010=4,001=5,yx=6,10=7,01=8 (probed)
const vecCreate linksection(code_section) = [9]vecCreate_t{
    .{ .bits = 0x0000 }, // [0] AUT (unused slot)
    .{ .bits = 0xaa4d }, // [1] zxy
    .{ .bits = 0xaa4d }, // [2] zyx
    .{ .bits = 0x424d }, // [3] 100
    .{ .bits = 0x124d }, // [4] 010
    .{ .bits = 0x064d }, // [5] 001
    .{ .bits = 0xeb49 }, // [6] yx
    .{ .bits = 0xd349 }, // [7] 10
    .{ .bits = 0xc749 }, // [8] 01
};

fn processDefaultVector(regist: calcRegister_t, p: u8, d: u8, xarr: [*]cmplxPair, complexCoefs: *bool_t) bool_t {
    if (d == V_COPY) {
        if (!frontier_register_value_conversions.getRegisterAsComplexOrReal(regist, &xarr[p].r, &xarr[p].i, @ptrCast(complexCoefs))) {
            return 0;
        }
    } else if (d <= V_D1) {
        realCopy(if (d == V_D1) const_1 else const_0, &xarr[p].r);
    }
    return 1;
}

pub export fn fnExchangeStkToMx(opType: u16) callconv(.c) void {
    _ = &opType; // referenced unconditionally so the !option_vector build has no unused param
    if (comptime option_vector) {
        switch (opType) {
            ITM_stkexV2 => {
                if (isRegisterMatrix2dVector(REGISTER_X)) {
                    fnConvertMxToStk(indexOfItems[ITM_V2toSTK].param);
                } else if ((getRegisterDataType(REGISTER_X) == dtReal34 or getRegisterDataType(REGISTER_X) == dtLongInteger) and (getRegisterDataType(REGISTER_Y) == dtReal34 or getRegisterDataType(REGISTER_Y) == dtLongInteger)) {
                    fnConvertStkToMx(indexOfItems[ITM_STKtoV2].param);
                } else {
                    if (comptime !dmcp_build) {
                        frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
                        invalidDataTypeHint("In function fnExchangeStkToMx:");
                    }
                }
            },
            ITM_stkexV3 => {
                if (isRegisterMatrix3dVector(REGISTER_X)) {
                    fnConvertMxToStk(VECT_CR_AUT);
                } else if ((getRegisterDataType(REGISTER_X) == dtReal34 or getRegisterDataType(REGISTER_X) == dtLongInteger) and
                    (getRegisterDataType(REGISTER_Y) == dtReal34 or getRegisterDataType(REGISTER_Y) == dtLongInteger) and
                    (getRegisterDataType(REGISTER_Z) == dtReal34 or getRegisterDataType(REGISTER_Z) == dtLongInteger))
                {
                    fnConvertStkToMx(VECT_CR_AUT);
                } else {
                    if (comptime !dmcp_build) {
                        frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
                        invalidDataTypeHint("In function fnExchangeStkToMx:");
                    }
                }
            },
            else => {},
        }
    }
}

// EXTRA_INFO invalid-data-type hint (uses getRegisterDataTypeName).
inline fn invalidDataTypeHint(where: [*c]const u8) void {
    if (comptime extra_info) {
        if (comptime !dmcp_build) {
            abi.fmtBufZ(errorMessage[0..512], "invalid data type {s} and {s}", .{ std.mem.span(frontier_debug.getRegisterDataTypeName(REGISTER_Y, true, false)), std.mem.span(frontier_debug.getRegisterDataTypeName(REGISTER_X, true, false)) });
            moreInfoOnError(where, errorMessage, null, null);
        }
    }
}

pub export fn fnConvertStkToMx(constVector1: u16) callconv(.c) void {
    if (comptime !vector_or_elec) {
        return;
    }
    var complexCoefs: bool_t = 0;
    var x: [3]cmplxPair = undefined;
    var matrix: real34Matrix_t = undefined;
    var matrixC: complex34Matrix_t = undefined;
    var elements: u16 = undefined;

    if (constVector1 == VECT_CR_zyx) {
        clearSystemFlag(FLAG_3DPHYS);
    } else if (constVector1 == VECT_CR_zxy) {
        setSystemFlag(FLAG_3DPHYS);
    }

    var constVector: u16 = constVector1;
    if (constVector == VECT_CR_AUT) {
        constVector = VECT_CR_zyx;
        if (getSystemFlag(FLAG_3DPHYS) != 0 and registerIsAngle(REGISTER_X) and registerIsAngle(REGISTER_Y)) {
            constVector = VECT_CR_zxy;
        }
    }

    if (constVector1 == M_CR_zyx) {
        constVector = VECT_CR_zyx;
    }

    const vc = vecCreate[constVector];
    elements = @as(u16, vc.rows()) * @as(u16, vc.cols());

    if (processDefaultVector(REGISTER_X, vc.x(), vc.xdef(), &x, &complexCoefs) == 0) return;
    if (processDefaultVector(REGISTER_Y, vc.y(), vc.ydef(), &x, &complexCoefs) == 0) return;
    if (@max(vc.z(), vc.zdef()) != V_NANA and
        processDefaultVector(REGISTER_Z, vc.z(), vc.zdef(), &x, &complexCoefs) == 0) return;

    if (saveLastX() == 0) {
        return;
    }

    var ang2Dx: u32 = undefined;
    var ang2Dy: u32 = undefined;
    var ang3Dx: u32 = undefined;
    var ang3Dy: u32 = undefined;
    var ang3Dz: u32 = undefined;
    var validPolarInput: bool_t = undefined;
    var valid2DRInput: bool_t = undefined;
    var validSPHInput: bool_t = undefined;
    var validCYLInput: bool_t = undefined;
    var valid3DRInput: bool_t = undefined;

    if (is_2D3D_Register_Ready(&ang2Dx, &ang2Dy, &ang3Dx, &ang3Dy, &ang3Dz, &validPolarInput, &valid2DRInput, &validSPHInput, &validCYLInput, &valid3DRInput, constVector) == 0) {
        frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_POLAR_RECT, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnErr("In function fnConvertStkToMx:", "No valid coordinates for 2D/3D Rect/Polar/Spherical/Cylindrical");
        return;
    } else {
        if (constVector1 == M_CR_zyx and valid3DRInput == 0) {
            frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnErr("In function fnConvertStkToMx:", "No angles allowed for ELEC M");
            return;
        }
    }

    if (validPolarInput != 0) {
        frontier_conversion_angles.convertAngleFromTo(&x[0].r, @intCast(ang2Dx), amRadian, &ctxtReal39);
        if (realCompareLessThan(&x[1].r, const_0) != 0) {
            realSetPositiveSign(&x[1].r);
            realAdd(&x[0].r, const39_pi, &x[0].r, &ctxtReal39);
        }
    }

    if (validSPHInput != 0) {
        frontier_conversion_angles.convertAngleFromTo(&x[vc.x()].r, @intCast(ang3Dx), amRadian, &ctxtReal39);
        frontier_conversion_angles.convertAngleFromTo(&x[vc.y()].r, @intCast(ang3Dy), amRadian, &ctxtReal39);
    } else if (validCYLInput != 0) {
        frontier_conversion_angles.convertAngleFromTo(&x[vc.y()].r, @intCast(ang3Dy), amRadian, &ctxtReal39);
    }

    if (vc.xdef() <= V_D1 or vc.ydef() <= V_D1 or vc.zdef() <= V_D1) {
        setSystemFlag(FLAG_ASLIFT);
        liftStack();
    } else {
        fnDrop(NOPARAM);
        if (elements > 2) {
            fnDrop(NOPARAM);
        }
    }

    if (getRegisterDataType(REGISTER_X) != dtReal34Matrix and getRegisterDataType(REGISTER_X) != dtComplex34Matrix) {
        if (initMatrixRegister(REGISTER_X, vc.rows(), vc.cols(), complexCoefs) != 0) {} else {
            frontier_error.displayCalcErrorMessage(ERROR_NOT_ENOUGH_MEMORY_FOR_NEW_MATRIX, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnErr("In function fnConvertStkToMx:", "Not enough memory for a 1\xc3\x97" ++ "1 matrix");
            return;
        }
        adjustResult(REGISTER_X, 0, 0, REGISTER_X, -1, -1);
    }

    var matrixRegisterLoaded: bool = false;
    if (complexCoefs != 0) {
        linkToComplexMatrixRegister(REGISTER_X, &matrixC);
    } else {
        linkToRealMatrixRegister(REGISTER_X, &matrix);

        if (ang2Dx != amNone and ang2Dy == amNone and constVector == VECT_CR_yx) {
            convertPOLto2D(&x[1].r, &x[0].r, amRadian, &matrix, &ctxtReal39);
            matrixRegisterLoaded = true;
        } else if (ang3Dx != amNone and ang3Dy != amNone and (constVector == VECT_CR_zyx or constVector == VECT_CR_zxy)) {
            if (constVector == VECT_CR_zxy) {
                convertSPHto3D(&x[2].r, &x[0].r, &x[1].r, amRadian, &matrix, &ctxtReal39);
            } else {
                convertSPHto3D(&x[2].r, &x[1].r, &x[0].r, amRadian, &matrix, &ctxtReal39);
            }
            matrixRegisterLoaded = true;
        } else if (ang3Dx == amNone and ang3Dy != amNone and constVector == VECT_CR_zyx) {
            convertCYLto3D(&x[2].r, &x[1].r, &x[0].r, amRadian, &matrix, &ctxtReal39);
            matrixRegisterLoaded = true;
        }
    }

    if (!matrixRegisterLoaded) {
        var i: usize = 0;
        while (i < elements) : (i += 1) {
            if (complexCoefs != 0) {
                realToReal34(&x[elements - 1 - i].r, varReal34(matrixC.matrixElements, i));
                realToReal34(&x[elements - 1 - i].i, varImag34(matrixC.matrixElements, i));
            } else {
                realToReal34(&x[elements - 1 - i].r, mxRe34(matrix.matrixElements, i));
            }
        }
    }

    adjustResult(REGISTER_X, 0, 1, REGISTER_X, -1, -1);

    if (validPolarInput != 0) {
        setVectorRegisterAngularMode(REGISTER_X, ang2Dx);
        setVectorRegisterPolarMode(REGISTER_X, amPolar);
        temporaryInformation = TI_VECTOR;
    } else if (validSPHInput != 0) {
        setVectorRegisterAngularMode(REGISTER_X, ang3Dx);
        setVectorRegisterPolarMode(REGISTER_X, amPolarSPH);
        temporaryInformation = TI_VECTOR;
    } else if (validCYLInput != 0) {
        setVectorRegisterAngularMode(REGISTER_X, ang3Dy);
        setVectorRegisterPolarMode(REGISTER_X, amPolarCYL);
        temporaryInformation = TI_VECTOR;
    }
}

pub export fn fnConvertMxToStk(param1: u16) callconv(.c) void {
    if (comptime !vector_or_elec) {
        return;
    }
    var matrix: real34Matrix_t = undefined;
    var matrixC: complex34Matrix_t = undefined;
    var Xrows: u16 = undefined;
    var Xcols: u16 = undefined;

    if (!(getRegisterDataType(REGISTER_X) == dtReal34Matrix or getRegisterDataType(REGISTER_X) == dtComplex34Matrix)) {
        if (comptime !dmcp_build) {
            frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
            invalidDataTypeHint("In function fnConvertMxToStk:");
        }
        return;
    }

    // default is rectangular
    var ang2Dx: i32 = amNone;
    var ang3Dx: i32 = amNone;
    var ang3Dy: i32 = amNone;

    if (isRegisterMatrix2dVector(REGISTER_X) and (getVectorRegisterPolarMode(REGISTER_X) == amPolar)) {
        ang2Dx = @intCast(getRegisterTag(REGISTER_X) & amAngleMask);
    } else if (isRegisterMatrix3dVector(REGISTER_X) and (getVectorRegisterPolarMode(REGISTER_X) == amPolarSPH)) {
        ang3Dx = @intCast(getRegisterTag(REGISTER_X) & amAngleMask);
        ang3Dy = ang3Dx;
    } else if (isRegisterMatrix3dVector(REGISTER_X) and (getVectorRegisterPolarMode(REGISTER_X) == amPolarCYL)) {
        ang3Dy = @intCast(getRegisterTag(REGISTER_X) & amAngleMask);
    }

    copySourceRegisterToDestRegister(REGISTER_X, TEMP_REGISTER_1);
    if (getRegisterDataType(TEMP_REGISTER_1) == dtComplex34Matrix) {
        linkToComplexMatrixRegister(TEMP_REGISTER_1, &matrixC);
        Xrows = matrixC.header.matrixRows;
        Xcols = matrixC.header.matrixColumns;
    } else {
        linkToRealMatrixRegister(TEMP_REGISTER_1, &matrix);
        Xrows = matrix.header.matrixRows;
        Xcols = matrix.header.matrixColumns;
    }

    if (param1 == VECT_CR_zyx) {
        clearSystemFlag(FLAG_3DPHYS);
    } else if (param1 == VECT_CR_zxy) {
        setSystemFlag(FLAG_3DPHYS);
    }

    var param: u16 = param1;
    if (param == VECT_CR_AUT) {
        param = VECT_CR_zyx;
        if (getSystemFlag(FLAG_3DPHYS) != 0 and isRegisterMatrix3dVector(REGISTER_X) and (getVectorRegisterPolarMode(REGISTER_X) == amPolarSPH)) {
            param = VECT_CR_zxy;
        }
    }

    var constVector: u16 = param & 0x0F;
    if (constVector == M_CR_zyx) {
        constVector = VECT_CR_zyx;
    }
    {
        const vc = vecCreate[constVector];
        if (!((Xrows == vc.rows() and Xcols == vc.cols()) or (Xrows == vc.cols() and Xcols == vc.rows()))) {
            constVector = (param & 0xF0) >> 4;
            const vc2 = vecCreate[constVector];
            if (constVector == 0 or !((Xrows == vc2.rows() and Xcols == vc2.cols()) or (Xrows == vc2.cols() and Xcols == vc2.rows()))) {
                return;
            }
        }
    }

    const elements: u16 = Xrows * Xcols;

    if (saveLastX() == 0) {
        return;
    }

    if (getRegisterDataType(TEMP_REGISTER_1) == dtReal34Matrix) {
        frontier_register_value_conversions.convertRealToResultRegister(const_0, REGISTER_X, amNone);
        setSystemFlag(FLAG_ASLIFT);
        liftStack();
        frontier_register_value_conversions.convertRealToResultRegister(const_0, REGISTER_X, amNone);
    } else {
        frontier_register_value_conversions.convertComplexToResultRegisterRPangle(const_0, const_0, REGISTER_X, amNone, 0);
        setSystemFlag(FLAG_ASLIFT);
        liftStack();
        frontier_register_value_conversions.convertComplexToResultRegisterRPangle(const_0, const_0, REGISTER_X, amNone, 0);
    }
    if (elements > 2) {
        if (getRegisterDataType(TEMP_REGISTER_1) == dtReal34Matrix) {
            setSystemFlag(FLAG_ASLIFT);
            liftStack();
            frontier_register_value_conversions.convertRealToResultRegister(const_0, REGISTER_X, amNone);
        } else {
            setSystemFlag(FLAG_ASLIFT);
            liftStack();
            frontier_register_value_conversions.convertComplexToResultRegisterRPangle(const_0, const_0, REGISTER_X, amNone, 0);
        }
    }

    if (constVector == VECT_CR_yx and ang2Dx != amNone) {
        var theta: real_t = undefined;
        var magnitude: real_t = undefined;
        real34ToReal(mxRe34(matrix.matrixElements, 0), &magnitude);
        real34ToReal(mxRe34(matrix.matrixElements, 1), &theta);
        realRectangularToPolar(&magnitude, &theta, &magnitude, &theta, &ctxtReal39);
        frontier_conversion_angles.convertAngleFromTo(&theta, amRadian, ang2Dx, &ctxtReal39);
        realToReal34(&magnitude, mxRe34(matrix.matrixElements, 0));
        realToReal34(&theta, mxRe34(matrix.matrixElements, 1));
    } else if ((constVector == VECT_CR_zyx or constVector == VECT_CR_zxy) and (ang3Dy != amNone and ang3Dx == amNone)) { // CYL
        var theta: real_t = undefined;
        var magnitude: real_t = undefined;
        var zz: real_t = undefined;
        convert3DtoCYL(&matrix, &magnitude, &theta, &zz, @intCast(ang3Dy), &ctxtReal39);
        realToReal34(&magnitude, mxRe34(matrix.matrixElements, 0));
        realToReal34(&theta, mxRe34(matrix.matrixElements, 1));
        realToReal34(&zz, mxRe34(matrix.matrixElements, 2));
    } else if ((constVector == VECT_CR_zyx or constVector == VECT_CR_zxy) and (ang3Dy != amNone and ang3Dx != amNone)) { // SPH
        var theta: real_t = undefined;
        var theta2: real_t = undefined;
        var magnitude: real_t = undefined;
        convert3DtoSPH(&matrix, &magnitude, &theta, &theta2, @intCast(ang3Dx), &ctxtReal39);
        realToReal34(&magnitude, mxRe34(matrix.matrixElements, 0));
        if (constVector == VECT_CR_zxy) {
            realToReal34(&theta, mxRe34(matrix.matrixElements, 2));
            realToReal34(&theta2, mxRe34(matrix.matrixElements, 1));
        } else {
            realToReal34(&theta2, mxRe34(matrix.matrixElements, 2));
            realToReal34(&theta, mxRe34(matrix.matrixElements, 1));
        }
    }

    {
        const vc = vecCreate[constVector];
        var i: usize = 0;
        while (i < elements) : (i += 1) {
            const target: u16 = @intCast(elements - 1 - i);
            const rg: calcRegister_t = if (vc.x() == target) REGISTER_X else if (vc.y() == target) REGISTER_Y else if (vc.z() == target) REGISTER_Z else 0;
            if (getRegisterDataType(TEMP_REGISTER_1) == dtComplex34Matrix) {
                real34Copy(varReal34(matrixC.matrixElements, i), reg34(rg));
                real34Copy(varImag34(matrixC.matrixElements, i), regImag34(rg));
                setRegisterAngularMode(rg, getComplexRegisterAngularMode(TEMP_REGISTER_1) | @as(u16, @intCast(getComplexRegisterPolarMode(TEMP_REGISTER_1))));
            } else {
                real34Copy(mxRe34(matrix.matrixElements, i), reg34(rg));
            }
            adjustResult(rg, 0, 0, rg, -1, -1);
        }
    }

    if (constVector == VECT_CR_yx and ang2Dx != amNone) { // POL
        setRegisterAngularMode(REGISTER_X, @intCast(ang2Dx));
        temporaryInformation = TI_VECTORCOMP_2DPOLAR;
    } else if (constVector == VECT_CR_yx and ang2Dx == amNone) { // RECT
        temporaryInformation = TI_VECTORCOMP_2DRECT;
    } else if ((constVector == VECT_CR_zyx or constVector == VECT_CR_zxy) and ang3Dy != amNone and ang3Dx != amNone) { // SPH
        setRegisterAngularMode(REGISTER_X, @intCast(ang3Dx));
        setRegisterAngularMode(REGISTER_Y, @intCast(ang3Dy));
        temporaryInformation = TI_VECTORCOMP_3DSPH;
    } else if ((constVector == VECT_CR_zyx or constVector == VECT_CR_zxy) and ang3Dy != amNone and ang3Dx == amNone) { // CYL
        setRegisterAngularMode(REGISTER_Y, @intCast(ang3Dy));
        temporaryInformation = TI_VECTORCOMP_3DCYL;
    } else if ((constVector == VECT_CR_zyx or constVector == VECT_CR_zxy) and ang3Dy == amNone and ang3Dx == amNone) { // RECT
        setRegisterAngularMode(REGISTER_Y, @intCast(ang3Dy));
        temporaryInformation = TI_VECTORCOMP_3DRECT;
    }
}

// ===========================================================================
// fnJM_2SI : rounding / SI <-> longint conversions.
// ===========================================================================

pub export fn fnJM_2SI(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (calcMode == CM_NIM) {
        if (((nimNumberPart == NP_INT_BASE and aimBuffer[strlen(aimBuffer) - 1] == '#') or (nimNumberPart == NP_INT_10 and lastIntegerBase > 0))) {
            return;
        }
    }
    var tmp1: longInteger_t = undefined;
    var tmp3: longInteger_t = undefined;
    switch (getRegisterDataType(REGISTER_X)) {
        dtLongInteger => {
            frontier_register_value_conversions.convertLongIntegerRegisterToLongInteger(REGISTER_X, &tmp3[0]);
            if (shortIntegerMode == SIM_UNSIGN and longIntegerIsNegative(&tmp3)) {
                temporaryInformation = TI_DATA_NEG_OVRFL;
            }
            frontier_register_value_conversions.convertLongIntegerRegisterToShortIntegerRegister(REGISTER_X, REGISTER_X); // default to 10
            if (lastIntegerBase >= 2 and lastIntegerBase <= 16 and lastIntegerBase != 10) {
                frontier_integers.fnChangeBase(@intCast(lastIntegerBase));
            }
            frontier_register_value_conversions.convertShortIntegerRegisterToLongInteger(REGISTER_X, &tmp1[0]);

            if (longIntegerCompare(&tmp1[0], &tmp3[0]) != 0) {
                if (temporaryInformation != TI_DATA_NEG_OVRFL) {
                    temporaryInformation = TI_DATA_LOSS;
                }
                setSystemFlag(FLAG_OVERFLOW);
            }
            longIntegerFree(&tmp1);
            longIntegerFree(&tmp3);
        },
        dtReal34 => {
            fnRoundi(0);
        },
        dtShortInteger => {
            frontier_register_value_conversions.convertShortIntegerRegisterToLongIntegerRegister(REGISTER_X, REGISTER_X);
            lastIntegerBase = 0;
            frontier_radio_button_catalog.fnRefreshState();
        },
        else => {},
    }
}

// ===========================================================================
// exponentToUnitDisplayString : JM UNIT
// ===========================================================================
const SIprefixes linksection(code_section) = "q  r  y  z  a  f  p  n  u  m     k  M  G  T  P  E  Z  Y  R  Q  ".*;
const ITSIprefixes linksection(code_section) = "K  M  G  T  P  E  Z  ".*;

pub export fn exponentToUnitDisplayString(exponent: i32, flag2To10: bool_t, displayString_in: [*c]u8, displayValueString: [*c]u8, nimMode: bool_t) callconv(.c) void {
    var displayString = displayString_in;
    displayString[0] = ' ';
    displayString[1] = 0;
    displayString[2] = 0;
    displayString[3] = 0;

    if (flag2To10 == 0 and getSystemFlag(FLAG_2TO10) == 0) {
        if ((-15 <= exponent and exponent <= 15) or (-30 <= exponent and exponent <= 30 and getSystemFlag(FLAG_PFX_ALL) != 0)) {
            displayString[1] = SIprefixes[@intCast(exponent + 30)];
            if (displayString[1] == 'u') {
                displayString[1] = STD_mu[0];
                displayString[2] = STD_mu[1];
            }
        }
    } else if (flag2To10 != 0) {
        if ((3 <= exponent and exponent <= 15) or (3 <= exponent and exponent <= 21 and getSystemFlag(FLAG_PFX_ALL) != 0)) {
            displayString[1] = ITSIprefixes[@intCast(exponent - 3)];
            displayString[2] = 'i';
        }
    }

    if (displayString[1] == 0) {
        _ = strcpy(displayString, productSign());
        displayString += 2;
        _ = strcpy(displayString, STD_SUB_10);
        displayString += 2;
        displayString[0] = 0;
        if (nimMode != 0) {
            if (exponent != 0) {
                frontier_display.supNumberToDisplayString(exponent, displayString, displayValueString, 0);
            }
        } else {
            frontier_display.supNumberToDisplayString(exponent, displayString, displayValueString, 0);
        }
    }
}

// PRODUCT_SIGN runtime macro
extern var systemFlags0: u64;
inline fn productSign() [*c]const u8 {
    return if (getSystemFlag(FLAG_MULTx) != 0) STD_CROSS else STD_DOT;
}
const FLAG_MULTx: c_int = 32795; // 0x801b

// ===========================================================================
// fnDisplayFormatCycle
// ===========================================================================

pub export fn fnDisplayFormatCycle(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (DM_Cycling == 0 and softmenu[@intCast(softmenuStack[0].softmenuId)].menuItem == -MNU_PREFIX) {
        frontier.fnDisplayFormatUnit(@as(u16, displayFormatDigits));
    } else if (displayFormat == DF_UN) {
        frontier.fnDisplayFormatSigFig(@as(u16, displayFormatDigits));
    } else if (displayFormat == DF_SF) {
        frontier.fnDisplayFormatAll(@as(u16, displayFormatDigits));
    } else if (displayFormat == DF_ALL) {
        frontier.fnDisplayFormatFix(@as(u16, displayFormatDigits));
    } else if (displayFormat == DF_FIX) {
        frontier.fnDisplayFormatSci(@as(u16, displayFormatDigits));
    } else if (displayFormat == DF_SCI) {
        frontier.fnDisplayFormatEng(@as(u16, displayFormatDigits));
    } else if (displayFormat == DF_ENG) {
        frontier.fnDisplayFormatUnit(@as(u16, displayFormatDigits));
    }
    DM_Cycling = 1;
}

pub export fn fnAngularModeJM(AMODE: u16) callconv(.c) void {
    copySourceRegisterToDestRegister(REGISTER_X, TEMP_REGISTER_1);
    if (AMODE == TM_HMS) {
        if (getRegisterDataType(REGISTER_X) == dtTime) {
            copySourceRegisterToDestRegister(TEMP_REGISTER_1, REGISTER_L);
            return;
        }
        if (getRegisterDataType(REGISTER_X) == dtReal34 and getRegisterAngularMode(REGISTER_X) != amNone) {
            frontier_conversion_angles.fnCvtFromCurrentAngularMode(amDegree);
        }

        if (calcMode == CM_NORMAL) {
            fnToReal(0);
        } else if (calcMode == CM_NIM) {
            frontier_bufferize.addItemToNimBuffer(ITM_dotD);
        }

        frontier_date_time.fnHRtoTM(0); // covers longint & real
    } else {
        if (getRegisterDataType(REGISTER_X) == dtTime) {
            frontier_date_time.fnToHr(0); // covers time
            setRegisterAngularMode(REGISTER_X, amDegree);
            frontier_conversion_angles.fnCvtFromCurrentAngularMode(AMODE);
        }

        if (getRegisterDataType(REGISTER_X) == dtComplex34 or getRegisterDataType(REGISTER_X) == dtComplex34Matrix) {
            setComplexRegisterAngularMode(REGISTER_X, AMODE);
            setComplexRegisterPolarMode(REGISTER_X, amPolar);
        } else if (getRegisterDataType(REGISTER_X) == dtReal34Matrix) {
            _ = VtoAngleMode(@intCast(AMODE));
        } else {
            if ((getRegisterDataType(REGISTER_X) != dtReal34) or ((getRegisterDataType(REGISTER_X) == dtReal34) and getRegisterAngularMode(REGISTER_X) == amNone)) {
                if (calcMode == CM_NORMAL) {
                    fnToReal(0);
                } else if (calcMode == CM_NIM) {
                    frontier_bufferize.addItemToNimBuffer(ITM_dotD);
                }

                const currentAngularModeOld = currentAngularMode;
                currentAngularMode = @intCast(AMODE);
                frontier_conversion_angles.fnCvtFromCurrentAngularMode(@intCast(currentAngularMode));
                currentAngularMode = currentAngularModeOld;
            } else { // convert existing tagged angle
                frontier_conversion_angles.fnCvtFromCurrentAngularMode(AMODE);
            }
        }
    }

    copySourceRegisterToDestRegister(TEMP_REGISTER_1, REGISTER_L);
}

pub export fn DRG_cyc(dest: *u16) callconv(.c) void {
    DRG_Cycling = 1;
    switch (dest.*) {
        amNone => dest.* = @intCast(currentAngularMode),
        amRadian => dest.* = amGrad,
        amGrad => dest.* = amDegree,
        amDegree => dest.* = amRadian,
        amDMS => dest.* = amDegree,
        amMultPi => dest.* = amRadian,
        else => {},
    }
}

pub export fn fnDRG(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    switch (getRegisterDataType(REGISTER_X)) {
        dtTime, dtDate, dtString, dtConfig => {
            return;
        },
        else => {},
    }

    copySourceRegisterToDestRegister(REGISTER_X, TEMP_REGISTER_1);
    var dest: u16 = 9999;

    if (getRegisterDataType(REGISTER_X) == dtComplex34 or getRegisterDataType(REGISTER_X) == dtComplex34Matrix) {
        setComplexRegisterPolarMode(REGISTER_X, amPolar);
        dest = getComplexRegisterAngularMode(REGISTER_X);
        DRG_cyc(&dest);
        setComplexRegisterAngularMode(REGISTER_X, dest);
    } else if (getRegisterDataType(REGISTER_X) == dtShortInteger) {
        frontier_register_value_conversions.convertShortIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
        setRegisterAngularMode(REGISTER_X, amNone);
    } else if (getRegisterDataType(REGISTER_X) == dtLongInteger) {
        frontier_register_value_conversions.convertLongIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
        setRegisterAngularMode(REGISTER_X, amNone);
    }

    if (getRegisterDataType(REGISTER_X) == dtReal34) {
        dest = @intCast(getRegisterAngularMode(REGISTER_X));

        if (dest != amNone and dest != currentAngularMode and DRG_Cycling != 1) {
            frontier_conversion_angles.fnCvtToCurrentAngularMode(dest);
            copySourceRegisterToDestRegister(TEMP_REGISTER_1, REGISTER_L);
            return;
        }

        DRG_cyc(&dest);
        frontier_conversion_angles.fnCvtFromCurrentAngularMode(dest);
    } else if (getRegisterDataType(REGISTER_X) == dtReal34Matrix) {
        dest = @intCast(getVectorRegisterAngularMode(REGISTER_X));
        DRG_cyc(&dest);
        _ = VtoAngleMode(@intCast(dest));
    }

    copySourceRegisterToDestRegister(TEMP_REGISTER_1, REGISTER_L);
}

pub export fn shrinkNimBuffer() callconv(.c) void {
    var hexD: i16 = 0;
    var reached_end: bool = false;
    const lastChar: i16 = @truncate(@as(i32, @intCast(strlen(aimBuffer))) - 1);
    if (lastChar >= 1) {
        var ix: usize = 0;
        while (aimBuffer[ix] != 0) : (ix += 1) {
            if (aimBuffer[ix] >= 'A') {
                hexD += 1;
            }
            if (aimBuffer[ix] == '#' or aimBuffer[ix] == '.' or reached_end) {
                aimBuffer[ix] = 0;
                reached_end = true;
            }
        }
        if (hexD > 0) {
            nimNumberPart = NP_INT_16;
        } else {
            nimNumberPart = NP_INT_10;
        }
    }
}

pub export fn fnChangeBaseJM(BASE: u16) callconv(.c) void {
    shrinkNimBuffer();
    frontier_integers.fnChangeBase(BASE);

    if (getSystemFlag(FLAG_HPBASE) != 0) {
        var regist: u16 = REGISTER_X + 1;
        const limit: u16 = @as(u16, @intCast(REGISTER_X)) + (if (getSystemFlag(FLAG_SSIZE8) != 0) @as(u16, 8) else 4);
        while (regist < limit) : (regist += 1) {
            if (getRegisterDataType(@intCast(regist)) == dtShortInteger) {
                if (2 <= BASE and BASE <= 16) {
                    setRegisterTag(@intCast(regist), BASE);
                }
                frontier_radio_button_catalog.fnRefreshState();
            }
        }
    }

    frontier_bufferize.nimBufferToDisplayBuffer(aimBuffer, nimBufferDisplay + 2);
}

pub export fn fnChangeBaseMNU(BASE: u16) callconv(.c) void {
    if (calcMode == CM_AIM) {
        frontier_bufferize.addItemToBuffer(ITM_toINT);
        return;
    }

    shrinkNimBuffer();

    if (lastIntegerBase == 0 and calcMode == CM_NORMAL and BASE > 1 and BASE <= 16) {
        fnChangeBaseJM(BASE);
        return;
    }

    if (calcMode == CM_NORMAL and BASE == NOPARAM) {
        frontier_items.runFunction(ITM_toINT);
        return;
    }

    if (BASE > 1 and BASE <= 16) {
        fnChangeBaseJM(BASE);
        frontier_bufferize.nimBufferToDisplayBuffer(aimBuffer, nimBufferDisplay + 2);
        return;
    }

    if (aimBuffer[0] == 0 and calcMode == CM_NORMAL and BASE == NOPARAM) {
        frontier_items.runFunction(ITM_toINT);
        frontier_bufferize.nimBufferToDisplayBuffer(aimBuffer, nimBufferDisplay + 2);
        return;
    }

    if (aimBuffer[0] != 0 and calcMode == CM_NIM) {
        frontier_bufferize.addItemToNimBuffer(ITM_toINT);
        frontier_bufferize.nimBufferToDisplayBuffer(aimBuffer, nimBufferDisplay + 2);
        return;
    }
}

pub export fn fnInDefault(inputDefault: u16) callconv(.c) void {
    Input_Default = @intCast(inputDefault);
    lastIntegerBase = 0;
    frontier_radio_button_catalog.fnRefreshState();
}

pub export fn fnByteShortcutsS(size: u16) callconv(.c) void {
    frontier_config.fnSetWordSize(size);
    frontier.fnIntegerMode(SIM_2COMPL);
}

pub export fn fnByteShortcutsU(size: u16) callconv(.c) void {
    frontier_config.fnSetWordSize(size);
    frontier.fnIntegerMode(SIM_UNSIGN);
}

pub export fn doubleToXRegisterReal34(x: f64) callconv(.c) void {
    setSystemFlag(FLAG_ASLIFT);
    liftStack();
    reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
    abi.fmtExpC(tmpString, 16, x);
    stringToReal34(tmpString, reg34(REGISTER_X));
    setSystemFlag(FLAG_ASLIFT);
}

pub export fn fnStrtoReg(buffer: [*c]const u8, regist: calcRegister_t) callconv(.c) void {
    const mem: i16 = @intCast(stringByteLength(buffer) + 1);
    reallocateRegister(regist, dtString, TO_BLOCKS(@intCast(mem)), amNone);
    _ = frontier_char_string.xcopy(regString(regist), buffer, @intCast(mem));
}

pub export fn fnStrtoX(buffer: [*c]const u8) callconv(.c) void {
    setSystemFlag(FLAG_ASLIFT);
    liftStack();
    fnStrtoReg(buffer, REGISTER_X);
    setSystemFlag(FLAG_ASLIFT);
}

pub export fn fnStrInputReal34(inp1: [*c]const u8) callconv(.c) void {
    tmpString[0] = 0;
    _ = strcat(tmpString, inp1);
    setSystemFlag(FLAG_ASLIFT);
    liftStack();
    reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
    stringToReal34(tmpString, reg34(REGISTER_X));
    setSystemFlag(FLAG_ASLIFT);
}

pub export fn fnStrInputLongint(inp1: [*c]const u8) callconv(.c) void {
    tmpString[0] = 0;
    _ = strcat(tmpString, inp1);
    setSystemFlag(FLAG_ASLIFT);
    liftStack();

    var lgInt: longInteger_t = undefined;
    longIntegerInit(&lgInt);
    stringToLongInteger(tmpString + @as(usize, if (tmpString[0] == '+') 1 else 0), 10, &lgInt[0]);
    frontier_register_value_conversions.convertLongIntegerToLongIntegerRegister(&lgInt[0], REGISTER_X);
    longIntegerFree(&lgInt);
    setSystemFlag(FLAG_ASLIFT);
}

pub export fn fnIntInputLongint(inp1: i32) callconv(.c) void {
    liftStack();

    var lgInt: longInteger_t = undefined;
    longIntegerInit(&lgInt);
    int32ToLongInteger(inp1, &lgInt[0]);
    frontier_register_value_conversions.convertLongIntegerToLongIntegerRegister(&lgInt[0], REGISTER_X);
    longIntegerFree(&lgInt);
    setSystemFlag(FLAG_ASLIFT);
}

pub export fn fnRCL(inp: i16) callconv(.c) void {
    setSystemFlag(FLAG_ASLIFT);
    if (inp == TEMP_REGISTER_1) {
        liftStack();
        copySourceRegisterToDestRegister(inp, REGISTER_X);
    } else {
        frontier_recall.fnRecall(@intCast(inp));
    }
}

pub export fn convert_to_double(regist: calcRegister_t) callconv(.c) f64 {
    var y: f64 = undefined;
    var tmpy: real_t = undefined;
    switch (getRegisterDataType(regist)) {
        dtLongInteger => {
            frontier_register_value_conversions.convertLongIntegerRegisterToReal(regist, &tmpy, &ctxtReal39);
        },
        dtReal34 => {
            real34ToReal(reg34(regist), &tmpy);
        },
        else => {
            return 0;
        },
    }
    realToString(&tmpy, tmpString);
    y = @floatCast(strtof(tmpString, null));
    return y;
}

// ===========================================================================
// time / DMS / sexagesimal conversions
// ===========================================================================
pub export fn timeToReal34(hms: u16) callconv(.c) void {
    const regist: calcRegister_t = REGISTER_X;
    var real34: real34_t = undefined;
    var value34: real34_t = undefined;
    var h34: real34_t = undefined;
    var m34: real34_t = undefined;
    var s34: real34_t = undefined;
    var sign: i32 = undefined;
    var digits: u32 = undefined;
    var tDigits: u32 = 0;
    var bDigits: u32 = undefined;
    var isValid12hTime: bool = false;

    real34Copy(reg34(regist), &real34);
    sign = @intFromBool(real34IsNegative(&real34));

    // Pre-rounding: scale by the input's integer-digit magnitude, round to an
    // integral value, then scale back — to strip floating-point noise before the
    // H/M/S split. C compares the input value `real34` (addons.c:2531); an
    // earlier port misread it as a different (zeroed) variable, which forced
    // bDigits to 0 and always scaled by 10^16, changing the rounding for any
    // value >= 10. Compare `real34`, matching current C.
    int32ToReal34(10, &value34);
    bDigits = 0;
    while (bDigits < (if (isValid12hTime) @as(u32, 14) else 16)) : (bDigits += 1) {
        if (real34CompareAbsLessThan(&real34, &value34) != 0) {
            break;
        }
        real34Multiply(&value34, const34_10, &value34);
    }
    tDigits = if (isValid12hTime) 14 else 16;
    isValid12hTime = false;

    digits = bDigits;
    while (digits < tDigits) : (digits += 1) {
        real34Multiply(&real34, &value34, &real34);
    }
    real34ToIntegralValue(&real34, &real34, DEC_ROUND_HALF_UP);
    digits = bDigits;
    while (digits < tDigits) : (digits += 1) {
        real34Divide(&real34, &value34, &real34);
    }
    tDigits = 0;
    real34SetPositiveSign(&real34);

    if (hms == 3) {
        //total seconds
        reallocateRegister(regist, dtReal34, 0, amNone);
        real34Copy(&real34, reg34(regist));
        if (sign != 0) {
            real34ChangeSign(reg34(regist));
        }
        return;
    }

    // Seconds
    real34Copy(&real34, &s34);
    // Minutes
    real34Divide(&s34, const34_60, &m34);
    real34ToIntegralValue(&m34, &m34, DEC_ROUND_DOWN);
    real34DivideRemainder(&s34, const34_60, &s34);
    // Hours
    real34Divide(&m34, const34_60, &h34);
    real34ToIntegralValue(&h34, &h34, DEC_ROUND_DOWN);
    real34DivideRemainder(&m34, const34_60, &m34);

    var ptr: ?*align(1) real34_t = null;
    switch (hms) {
        0 => ptr = &h34,
        1 => ptr = &m34,
        2 => ptr = &s34,
        else => ptr = null,
    }

    reallocateRegister(regist, dtReal34, 0, amNone);
    if (ptr) |p| {
        real34Copy(p, reg34(regist));
        if (sign != 0) {
            real34ChangeSign(reg34(regist));
        }
    }
}

pub export fn dms34ToReal34(dms: u16) callconv(.c) void {
    var angle34: real34_t = undefined;
    const regist: calcRegister_t = REGISTER_X;
    var d34: real34_t = undefined;
    var m34: real34_t = undefined;
    var s34: real34_t = undefined;
    var fs34: real34_t = undefined;
    real34Copy(reg34(regist), &angle34);

    var m: u32 = undefined;
    var s: u32 = undefined;
    var fs: u32 = undefined;
    var sign: i16 = undefined;

    var temp: real_t = undefined;
    var degrees: real_t = undefined;
    var minutes: real_t = undefined;
    var seconds: real_t = undefined;

    real34ToReal(&angle34, &temp);

    sign = 1 - 2 * @as(i16, @intFromBool(realIsNegative(&temp) != 0));
    realSetPositiveSign(&temp);

    // Get the degrees
    frontier_register_value_conversions.realToIntegralValue(&temp, &degrees, DEC_ROUND_DOWN, &ctxtReal39);

    // Get the minutes
    realSubtract(&temp, &degrees, &temp, &ctxtReal39);
    temp.exponent += 2; // temp = temp * 100
    frontier_register_value_conversions.realToIntegralValue(&temp, &minutes, DEC_ROUND_DOWN, &ctxtReal39);

    // Get the seconds
    realSubtract(&temp, &minutes, &temp, &ctxtReal39);
    temp.exponent += 2;
    frontier_register_value_conversions.realToIntegralValue(&temp, &seconds, DEC_ROUND_DOWN, &ctxtReal39);

    // Get the fractional seconds
    realSubtract(&temp, &seconds, &temp, &ctxtReal39);
    temp.exponent += 2;

    fs = frontier_real_type.realToUint32C47(&temp, null);
    s = frontier_real_type.realToUint32C47(&seconds, null);
    m = frontier_real_type.realToUint32C47(&minutes, null);

    if (fs >= 100) {
        fs -= 100;
        s += 1;
    }

    if (s >= 60) {
        s -= 60;
        m += 1;
    }

    if (m >= 60) {
        m -= 60;
        realAdd(&degrees, const_1, &degrees, &ctxtReal39);
    }

    var ptr: ?*align(1) real34_t = null;
    switch (dms) {
        0 => { // d
            realToReal34(&degrees, &d34);
            ptr = &d34;
        },
        1 => { // m
            int32ToReal34(@intCast(m), &m34);
            ptr = &m34;
        },
        2 => { // s
            int32ToReal34(@intCast(fs), &fs34);
            real34Divide(&fs34, const34_100, &fs34);

            int32ToReal34(@intCast(s), &s34);
            real34Add(&s34, &fs34, &s34);

            ptr = &s34;
        },
        else => ptr = null,
    }

    if (sign == -1) {
        real34ChangeSign(ptr.?);
    }
    reallocateRegister(regist, dtReal34, 0, amNone);
    real34Copy(ptr.?, reg34(regist));
}

pub export fn notSexa() callconv(.c) void {
    copySourceRegisterToDestRegister(REGISTER_L, REGISTER_X);
    frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    if (comptime extra_info) {
        if (comptime !dmcp_build) {
            abi.fmtBufZ(errorMessage[0..512], "data type {s} cannot be converted!", .{std.mem.span(frontier_debug.getRegisterDataTypeName(REGISTER_X, false, false))});
            moreInfoOnError("In function notSexa:", errorMessage, null, null);
        }
    }
}

pub export fn fnHrDeg(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (saveLastX() == 0) {
        return;
    }
    if (getRegisterAngularMode(REGISTER_X) == amDMS and getRegisterDataType(REGISTER_X) == dtReal34) {
        dms34ToReal34(0);
    } else if (getRegisterDataType(REGISTER_X) == dtTime) {
        timeToReal34(0);
    } else {
        notSexa();
    }
}

pub export fn fnMinute(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (saveLastX() == 0) {
        return;
    }
    if (getRegisterAngularMode(REGISTER_X) == amDMS and getRegisterDataType(REGISTER_X) == dtReal34) {
        dms34ToReal34(1);
    } else if (getRegisterDataType(REGISTER_X) == dtTime) {
        timeToReal34(1);
    } else {
        notSexa();
    }
}

pub export fn fnSecond(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (saveLastX() == 0) {
        return;
    }
    if (getRegisterAngularMode(REGISTER_X) == amDMS and getRegisterDataType(REGISTER_X) == dtReal34) {
        dms34ToReal34(2);
    } else if (getRegisterDataType(REGISTER_X) == dtTime) {
        timeToReal34(2);
    } else {
        notSexa();
    }
}

pub export fn fnTimeTo(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (saveLastX() == 0) {
        return;
    }

    if (getRegisterAngularMode(REGISTER_X) == amDMS and getRegisterDataType(REGISTER_X) == dtReal34) {
        dms34ToReal34(0);
        liftStack();
        copySourceRegisterToDestRegister(REGISTER_L, REGISTER_X);
        dms34ToReal34(1);
        liftStack();
        copySourceRegisterToDestRegister(REGISTER_L, REGISTER_X);
        dms34ToReal34(2);
    } else if (getRegisterDataType(REGISTER_X) == dtTime) {
        timeToReal34(0);
        liftStack();
        copySourceRegisterToDestRegister(REGISTER_L, REGISTER_X);
        timeToReal34(1);
        liftStack();
        copySourceRegisterToDestRegister(REGISTER_L, REGISTER_X);
        timeToReal34(2);
    } else {
        notSexa();
        return;
    }
}

pub export fn isValidTime(hour: *align(1) const real34_t, minute: *align(1) const real34_t, second: *align(1) const real34_t) callconv(.c) bool_t {
    var val: real34_t = undefined;

    // second
    real34ToIntegralValue(second, &val, DEC_ROUND_FLOOR);
    real34Subtract(second, &val, &val);
    if (!real34IsZero(&val)) return 0;
    if (real34CompareLessThan(second, const34_0) != 0) return 0;
    if (real34CompareGreaterEqual(second, const34_60) != 0) return 0;

    // minute
    real34ToIntegralValue(minute, &val, DEC_ROUND_FLOOR);
    real34Subtract(minute, &val, &val);
    if (!real34IsZero(&val)) return 0;
    if (real34CompareLessThan(minute, const34_0) != 0) return 0;
    if (real34CompareGreaterEqual(minute, const34_60) != 0) return 0;

    // hour
    real34ToIntegralValue(hour, &val, DEC_ROUND_FLOOR);
    real34Subtract(hour, &val, &val);
    if (!real34IsZero(&val)) return 0;
    if (real34CompareLessThan(hour, const34_0) != 0) return 0;
    if (real34CompareGreaterEqual(hour, const34_24) != 0) return 0;

    return 1;
}

pub export const toTimeParamReg linksection(code_section) = [3]calcRegister_t{ REGISTER_Z, REGISTER_Y, REGISTER_X };

pub export fn fnToTime(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var hr: real34_t = undefined;
    var m: real34_t = undefined;
    var s: real34_t = undefined;
    var part: [3]*align(1) real34_t = undefined;
    var i: usize = undefined;

    if (saveLastX() == 0) {
        return;
    }

    part[0] = &hr;
    part[1] = &m;
    part[2] = &s;

    i = 0;
    while (i < 3) : (i += 1) {
        switch (getRegisterDataType(toTimeParamReg[i])) {
            dtLongInteger => {
                frontier_register_value_conversions.convertLongIntegerRegisterToReal34(toTimeParamReg[i], part[i]);
            },
            dtReal34 => {
                if (getRegisterAngularMode(toTimeParamReg[i]) != 0) {
                    real34ToIntegralValue(reg34(toTimeParamReg[i]), part[i], DEC_ROUND_DOWN);
                } else {
                    frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
                    if (comptime extra_info) {
                        if (comptime !dmcp_build) {
                            abi.fmtBufZ(errorMessage[0..512], "data type {s} cannot be converted to a time!", .{std.mem.span(frontier_debug.getRegisterDataTypeName(toTimeParamReg[i], false, false))});
                            moreInfoOnError("In function fnToTime:", errorMessage, null, null);
                        }
                    }
                    return;
                }
            },
            else => {
                frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
                if (comptime extra_info) {
                    if (comptime !dmcp_build) {
                        abi.fmtBufZ(errorMessage[0..512], "data type {s} cannot be converted to a time!", .{std.mem.span(frontier_debug.getRegisterDataTypeName(toTimeParamReg[i], false, false))});
                        moreInfoOnError("In function fnToTime:", errorMessage, null, null);
                    }
                }
                return;
            },
        }
    }

    fnDropY(NOPARAM);
    fnDropY(NOPARAM);

    real34Multiply(const34_3600, &hr, &hr); // hr is now seconds
    real34Multiply(const34_60, &m, &m); // m is now seconds
    real34Add(&hr, &m, &hr);
    real34Add(&hr, &s, &hr);

    reallocateRegister(REGISTER_X, dtTime, 0, amNone);
    real34Copy(&hr, reg34(REGISTER_X));
}

// ===========================================================================
// IRFRAC engine
// ===========================================================================
const K_ctxtReal_denominator_finder: i32 = 26;
const K_ctxtReal_integer_conversion_find_lowest_err_fraction: i32 = 12;
const K_ctxtReal_irrational_detection: i32 = 26;
const K_ctxtReal_find_multiple_of_irr: i32 = 26;

pub export fn getSmallestDenom(val: *const real_t) callconv(.c) i32 {
    var ctxtReal_denom_finder: realContext_t = ctxtReal39;
    ctxtReal_denom_finder.digits = K_ctxtReal_denominator_finder;
    var xx: real_t = undefined;
    var temp: real_t = undefined;
    realCopy(val, &xx);

    var m: [2][2]i32 = undefined;
    m[0][0] = 1;

    var maxden: i32 = undefined;
    var ai: i32 = undefined;
    var dd: i32 = undefined;
    if (denMax == 0 or denMax > MAX_DENMAX) {
        maxden = MAX_INTERNAL_DENMAX;
    } else {
        maxden = @intCast(denMax);
    }
    int32ToReal(maxden, &temp);
    realDivide(const_1on4, &temp, &temp, &ctxtReal_denom_finder);
    if (realCompareLessThan(&xx, &temp) != 0) {
        dd = 1;
        return finishDenom(&m, dd);
    }

    // initialize matrix
    m[0][0] = 1;
    m[1][1] = 1;
    m[0][1] = 0;
    m[1][0] = 0;

    // loop finding terms until denom gets too big
    while (true) {
        ai = frontier_real_type.realToInt32C47(&xx, null);
        if (!(m[1][0] * ai + m[1][1] <= maxden)) break;
        var t: i32 = undefined;
        t = m[0][0] * ai + m[0][1];
        m[0][1] = m[0][0];
        m[0][0] = t;
        t = m[1][0] * ai + m[1][1];
        m[1][1] = m[1][0];
        m[1][0] = t;

        int32ToReal(ai, &temp);
        realSubtract(&xx, &temp, &xx, &ctxtReal_denom_finder);
        if (realIsZero(&xx) != 0 or realCompareAbsLessThan(&xx, const_1e_24) != 0) {
            break; // AF: division by zero
        }
        realDivide(const_1, &xx, &xx, &ctxtReal_denom_finder);
        if (realCompareGreaterThan(&xx, const_10p9__1) != 0) {
            realCopy(const_10p9__1, &xx);
        }
        if (realIsSpecial(&xx) != 0) {
            dd = 1;
            return finishDenom(&m, dd);
        }
    }

    // Pick the correct num/denom from the matrix
    var ctxtReal_int_conv: realContext_t = ctxtReal39;
    ctxtReal_int_conv.digits = K_ctxtReal_integer_conversion_find_lowest_err_fraction;
    var num1: real_t = undefined;
    var den1: real_t = undefined;
    var num2: real_t = undefined;
    var den2: real_t = undefined;
    var frac1: real_t = undefined;
    var frac2: real_t = undefined;
    var err1: real_t = undefined;
    var err2: real_t = undefined;
    int32ToReal(m[0][0], &num1);
    int32ToReal(m[1][0], &den1);
    int32ToReal(m[0][1], &num2);
    int32ToReal(m[1][1], &den2);

    realDivide(&num1, &den1, &frac1, &ctxtReal_int_conv);
    realDivide(&num2, &den2, &frac2, &ctxtReal_int_conv);
    realSubtract(val, &frac1, &err1, &ctxtReal_int_conv);
    realCopyAbs(&err1, &err1);
    realSubtract(val, &frac2, &err2, &ctxtReal_int_conv);
    realCopyAbs(&err2, &err2);
    var cmpResult: real_t = undefined;
    realCompare(&err2, &err1, &cmpResult, &ctxtReal_int_conv);
    if (realIsNegative(&cmpResult) != 0) {
        m[0][0] = m[0][1];
        m[1][0] = m[1][1];
    }
    dd = m[1][0];
    if (dd == 0) {
        dd = 1;
    }
    return dd;
}
// nothingTodo: label -> just returns dd (m unused after).
fn finishDenom(m: *[2][2]i32, dd: i32) i32 {
    _ = m;
    return dd;
}

pub export fn changeToSup(numer: u64, str: [*c]u8) callconv(.c) void {
    var endingZero: i16 = 0;
    str[0] = 0;
    frontier_display._numerator(numer, str, &endingZero);
}

pub export fn changeToSub(denom: u64, str: [*c]u8) callconv(.c) void {
    var endingZero: i16 = 1;
    str[0] = '/';
    str[1] = 0;
    frontier_display._denominator(denom, str, &endingZero);
}

pub export fn changeToWholeString(intt: i32, str: [*c]u8, str1: [*c]const u8) callconv(.c) void {
    str[0] = 0;
    var lgInt: longInteger_t = undefined;
    longIntegerInit(&lgInt);
    int32ToLongInteger(intt, &lgInt[0]);
    frontier_display.longIntegerToDisplayString(&lgInt[0], str, 30, SCREEN_WIDTH, 20, 1);
    _ = strcat(str, str1);
    longIntegerFree(&lgInt);
}

pub export fn checkForAndChange(displayString: [*c]u8, valueReal: *const real_t, valueRealAbs: *const real_t, constant: *const real_t, findingIrrationalTolerance: *const real_t, constantStr: [*c]const u8, frontSpace: bool_t, complexMixedNumbers: bool_t) callconv(.c) bool_t {
    const DISALLOW_MIXED_NUMBER_CONSTANTS = true;
    const DISALLOW_MIXED_NUMBER_COMPLEX = false;
    var ctxtReal_irrational_detection: realContext_t = ctxtReal39;
    ctxtReal_irrational_detection.digits = K_ctxtReal_irrational_detection;
    var ctxtReal_find_multiple_of_irr: realContext_t = ctxtReal39;
    ctxtReal_find_multiple_of_irr.digits = K_ctxtReal_find_multiple_of_irr;

    var cStr: [16]u8 = undefined;
    const useMixedNumbers: bool = getSystemFlag(FLAG_PROPFR) != 0 and (if (DISALLOW_MIXED_NUMBER_COMPLEX) (complexMixedNumbers == 0) else true);
    var smallestDenomR: real_t = undefined;
    var newConstant: real_t = undefined;
    var multipleOfNewConstant: real_t = undefined;
    var multipleOfNewConstant_ip: real_t = undefined;
    var multipleOfNewConstant_fp: real_t = undefined;
    var multConstant: real_t = undefined;

    var denomStr: [20]u8 = undefined;
    var wholePart: [30]u8 = undefined;
    var resultingIntStr: [100]u8 = undefined;
    var tmpstr: [50]u8 = undefined;
    tmpstr[0] = 0;
    denomStr[0] = 0;
    wholePart[0] = 0;
    resultingIntStr[0] = 0;
    var multipleOfNewConstantInteger: i32 = 0;
    var sign: [2]u8 = undefined;

    if (realIsPositive(valueReal) != 0) {
        _ = strcpy(&sign, "+");
    } else {
        _ = strcpy(&sign, "-");
    }

    // Returning: Real is too small
    if (realCompareLessThan(valueRealAbs, const_1e_16) != 0) {
        return 0;
    }
    // Returning: Multiple of constant is too large
    realDivide(valueRealAbs, constant, &multConstant, &ctxtReal_irrational_detection);
    if (realCompareGreaterThan(&multConstant, const_10p9__1) != 0) {
        return 0;
    }

    // IRFRAC_ENGINE: special denominator search engine
    const smallestDenom: i32 = getSmallestDenom(&multConstant);

    // Create a new constant comprising the constant divided by the whole denominator
    int32ToReal(smallestDenom, &smallestDenomR);
    realDivide(constant, &smallestDenomR, &newConstant, &ctxtReal39);

    // See if there is a whole multiple of the new constant
    realDivide(valueRealAbs, &newConstant, &multipleOfNewConstant, &ctxtReal_find_multiple_of_irr);
    frontier_register_value_conversions.realToIntegralValue(&multipleOfNewConstant, &multipleOfNewConstant_ip, DEC_ROUND_HALF_UP, &ctxtReal_find_multiple_of_irr);
    realSubtract(&multipleOfNewConstant, &multipleOfNewConstant_ip, &multipleOfNewConstant_fp, &ctxtReal_find_multiple_of_irr);
    multipleOfNewConstantInteger = abs(frontier_real_type.realToInt32C47(&multipleOfNewConstant_ip, null));

    // See if the ip is out of range
    if (realCompareAbsGreaterThan(&multipleOfNewConstant_ip, const_10p9__1) != 0) {
        return 0;
    }

    var findingIrrationalTolerance1: real_t = undefined;
    realMultiply(findingIrrationalTolerance, &smallestDenomR, &findingIrrationalTolerance1, &ctxtReal_irrational_detection);

    if ((DISALLOW_MIXED_NUMBER_CONSTANTS and constantStr[0] != 0 and multipleOfNewConstantInteger > smallestDenom) and useMixedNumbers and smallestDenom != 1) {
        cStr[0] = 0;
    } else {
        _ = strcpy(&cStr, constantStr);
    }

    if (multipleOfNewConstantInteger >= 1 and realCompareAbsLessThan(&multipleOfNewConstant_fp, &findingIrrationalTolerance1) != 0) {
        if (multipleOfNewConstantInteger > smallestDenom and smallestDenom > 1 and multipleOfNewConstantInteger != 0 and useMixedNumbers and smallestDenom != 1) {
            const wholeInteger: i32 = @divTrunc(multipleOfNewConstantInteger, smallestDenom);
            multipleOfNewConstantInteger = multipleOfNewConstantInteger - (wholeInteger * smallestDenom);

            var useMixedNumbersSep: [3]u8 = undefined;
            if (cStr[0] == 0) { // no constant
                useMixedNumbersSep[0] = STD_SPACE_4_PER_EM[0];
                useMixedNumbersSep[1] = STD_SPACE_4_PER_EM[1];
                useMixedNumbersSep[2] = 0;
                changeToWholeString(wholeInteger, &wholePart, &useMixedNumbersSep);
                _ = strcat(&wholePart, &useMixedNumbersSep); // "1 "
            } else { // constant with numbers
                useMixedNumbersSep[0] = sign[0];
                useMixedNumbersSep[1] = sign[1];
                useMixedNumbersSep[2] = 0;
                if (wholeInteger == 1) {
                    abi.fmtBufZ(&wholePart, "{s}{s}", .{ std.mem.sliceTo(&cStr, 0), std.mem.sliceTo(&useMixedNumbersSep, 0) }); // "e+"
                } else {
                    changeToWholeString(wholeInteger, &wholePart, productSign());
                    _ = strcat(&wholePart, &cStr);
                    _ = strcat(&wholePart, &useMixedNumbersSep); // "2xe+"
                }
            }
        }

        if (cStr[0] == 0) { // no constant
            if (smallestDenom > 1) {
                changeToSup(@intCast(multipleOfNewConstantInteger), &tmpstr); // numerator
            } else {
                return 0;
            }
            abi.fmtBufZ(&resultingIntStr, "{s}{s}", .{ std.mem.sliceTo(&wholePart, 0), std.mem.sliceTo(&tmpstr, 0) }); // "1 1"
        } else { // constant
            if (multipleOfNewConstantInteger == 1) {
                abi.fmtBufZ(&resultingIntStr, "{s}", .{std.mem.sliceTo(&wholePart, 0)}); // "e+" or "2xe+"
            } else {
                abi.fmtBufZ(&tmpstr, "{d}{s}", .{ multipleOfNewConstantInteger, @as([*:0]const u8, productSign()) });
                abi.fmtBufZ(&resultingIntStr, "{s}{s}", .{ std.mem.sliceTo(&wholePart, 0), std.mem.sliceTo(&tmpstr, 0) }); // "e+1" or "2xe+1"
            }
        }
    } else {
        if (smallestDenom == 1) {
            return 0; // unlikely
        } else {
            changeToSup(@intCast(multipleOfNewConstantInteger), &resultingIntStr);
        }
    }

    if (smallestDenom > 1) {
        changeToSub(@intCast(smallestDenom), &denomStr); // "/12"
    }

    if ((resultingIntStr[@intCast(stringByteLength(&resultingIntStr) - 1)] == ' ' or resultingIntStr[@intCast(maxI(0, stringByteLength(&resultingIntStr) - 1))] == 0) and denomStr[0] == '/' and cStr[0] == 0) {
        abi.fmtBufZ(&tmpstr, STD_SUP_1 ++ "{s}", .{std.mem.sliceTo(denomStr[0..], 0)});
        _ = strcpy(&denomStr, &tmpstr);
    }

    var roundingTolerance1: real_t = undefined;
    irfractionTolerence(smallestDenom * 6 + 1, &roundingTolerance1);

    displayString[0] = 0;
    if (realCompareAbsGreaterThan(&multipleOfNewConstant_fp, &findingIrrationalTolerance1) == 0) { // irrational tolerance found
        if (realCompareAbsLessThan(&multipleOfNewConstant_fp, &roundingTolerance1) == 0) {
            _ = strcat(displayString, STD_ALMOST_EQUAL);
        }

        if (sign[0] == '+') {
            if (frontSpace != 0) {
                _ = strcat(displayString, STD_SPACE_4_PER_EM);
                if (resultingIntStr[0] != 0) {
                    _ = strcat(displayString, &resultingIntStr);
                }
                _ = strcat(displayString, &cStr);
                _ = strcat(displayString, &denomStr); // " 2xe+" "e" "/3"
            } else {
                if (resultingIntStr[0] != 0) {
                    _ = strcat(displayString, &resultingIntStr);
                }
                _ = strcat(displayString, &cStr);
                _ = strcat(displayString, &denomStr); // "2xe+" "e" "/3"
            }
        } else { // "-"
            _ = strcat(displayString, STD_SPACE_4_PER_EM ++ "-");
            if (resultingIntStr[0] != 0) {
                _ = strcat(displayString, &resultingIntStr);
            }
            _ = strcat(displayString, &cStr);
            _ = strcat(displayString, &denomStr); // "-2xe+" "e" "/3"
        }

        if (cStr[0] == 0 and constantStr[0] != 0) { // "-2/3" "e"
            _ = strcat(displayString, STD_SPACE_4_PER_EM);
            _ = strcat(displayString, productSign());
            _ = strcat(displayString, STD_SPACE_4_PER_EM);
            _ = strcat(displayString, constantStr);
        }

        return 1; // successful IRFRAC conversion, displaying as fraction
    } else {
        return 0; // unsuccessful IRFRAC conversion, displaying as decimal
    }
}

// ===========================================================================
// fnSafeReset
// ===========================================================================
pub export fn fnSafeReset(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (getSystemFlag(FLAG_G_DOUBLETAP) == 0 and getSystemFlag(FLAG_SHFT_4s) == 0 and getSystemFlag(FLAG_HOME_TRIPLE) == 0 and getSystemFlag(FLAG_MYM_TRIPLE) == 0) {
        setSystemFlag(FLAG_FGLNFUL);
        clearSystemFlag(FLAG_FGLNLIM);
        setSystemFlag(FLAG_G_DOUBLETAP);
        setSystemFlag(FLAG_SHFT_4s);
        setSystemFlag(FLAG_HOME_TRIPLE);
        clearSystemFlag(FLAG_MYM_TRIPLE);
        clearSystemFlag(FLAG_BASE_HOME);
        setSystemFlag(FLAG_BASE_MYM);
    } else {
        clearSystemFlag(FLAG_FGLNFUL);
        clearSystemFlag(FLAG_FGLNLIM);
        clearSystemFlag(FLAG_G_DOUBLETAP);
        clearSystemFlag(FLAG_SHFT_4s);
        clearSystemFlag(FLAG_HOME_TRIPLE);
        clearSystemFlag(FLAG_MYM_TRIPLE);
        clearSystemFlag(FLAG_BASE_HOME);
        setSystemFlag(FLAG_BASE_MYM);
    }
}

// ===========================================================================
// MyMenu / MyAlpha
// ===========================================================================
fn assignToMyMenu_(position: u16) void {
    if (position < 18) {
        frontier_assign._assignItem(@ptrCast(&userMenuItems[position]));
    }
    cachedDynamicMenu = 0;
}

fn assignToMyAlpha_(position: u16) void {
    if (position < 18) {
        frontier_assign._assignItem(@ptrCast(&userAlphaItems[position]));
    }
    cachedDynamicMenu = 0;
}

// ribbonMappings: TO_QSPI static const int16_t[][7] -> pure-int table, code_section.
const ribbonMappings linksection(code_section) = [_][7]i16{
    .{ ITM_RIBBON_ENG_C47, -MNU_CPX, -MNU_MATX, ITM_CONSTpi, ITM_op_j, ITM_EXP, -MNU_TRG_C47 },
    .{ ITM_RIBBON_ENG_R47, ITM_op_j, -MNU_CPX, ITM_CONSTpi, -MNU_MATX, -MNU_TRG_R47, ITM_EXP },

    .{ ITM_RIBBON_SAV, ITM_SYSTEM2, ITM_ACTUSB, ITM_SAVE, ITM_LOAD, ITM_SAVEST, ITM_LOADST },
    .{ ITM_RIBBON_SAV2, ITM_SYSTEM2, ITM_ACTUSB, ITM_WRITEP, ITM_READP, ITM_SAVEST, ITM_LOADST },
    .{ ITM_RIBBON_FIN, ITM_PC, ITM_DELTAPC, ITM_YX, ITM_SQUARE, ITM_10x, -MNU_FIN },
    .{ ITM_RIBBON_FIN2, ITM_PCPMG, ITM_PCT, ITM_PC, ITM_DELTAPC, -MNU_TVM, -MNU_FIN },
    .{ ITM_RIBBON_CPX, ITM_DRG, ITM_CC, ITM_EE_EXP_TH, ITM_EXP, ITM_op_j_pol, ITM_op_j },
    .{ ITM_RIBBON_C47, ITM_DRG, ITM_YX, ITM_SQUARE, ITM_10x, ITM_EXP, ITM_op_j_pol },
    .{ ITM_RIBBON_C47PL, ITM_DRG, ITM_DSP, ITM_DREAL, ITM_FF, ITM_Rup, ITM_XFACT },
    .{ ITM_RIBBON_R47, ITM_op_j, ITM_op_j_pol, ITM_XFACT, ITM_XTHROOT, ITM_10x, ITM_EXP },
    .{ ITM_RIBBON_R47PL, ITM_TIMER, ITM_DSP, ITM_DREAL, ITM_FF, -MNU_LOOP, -MNU_TEST },
};

pub export fn fnRESET_MyM(param: u16) callconv(.c) void {
    clearSystemFlag(FLAG_BASE_MYM);

    var searchParam: i16 = @bitCast(param);
    if (param == ITM_RIBBON_ENG) {
        searchParam = if (isR47FAM()) ITM_RIBBON_ENG_R47 else ITM_RIBBON_ENG_C47;
    }

    var i: u16 = undefined;
    var fn_: i8 = 1;
    while (fn_ <= 6) : (fn_ += 1) {
        i = 0;
        while (i < ribbonMappings.len) : (i += 1) {
            if (ribbonMappings[i][0] == searchParam) {
                if (fn_ >= 1 and fn_ <= 6) {
                    itemToBeAssigned = ribbonMappings[i][@intCast(fn_)];
                } else {
                    itemToBeAssigned = ASSIGN_CLEAR;
                }
                break;
            }
        }
        if (i >= ribbonMappings.len) {
            itemToBeAssigned = ASSIGN_CLEAR;
        }

        if (itemToBeAssigned == -MNU_PFN) {
            _ = strcpy(aimBuffer, "P.FN");
            frontier_assign.assignGetName1();
        } else if (itemToBeAssigned == -MNU_HOME) {
            _ = strcpy(aimBuffer, "HOME");
            frontier_assign.assignGetName1();
        }

        assignToMyMenu_(@intCast(fn_ - 1));
        if (param == 0) {
            itemToBeAssigned = ASSIGN_CLEAR;
            assignToMyMenu_(@intCast(6 + fn_ - 1));
            itemToBeAssigned = ASSIGN_CLEAR;
            assignToMyMenu_(@intCast(12 + fn_ - 1));
        }
    }
    setSystemFlag(FLAG_BASE_MYM);
    frontier_screen.refreshScreen(42);
}

pub export fn fnRESET_Mya() callconv(.c) void {
    var fn_: i8 = 1;
    while (fn_ <= 6) : (fn_ += 1) {
        itemToBeAssigned = ASSIGN_CLEAR;
        assignToMyAlpha_(@intCast(fn_ - 1));
        itemToBeAssigned = ASSIGN_CLEAR;
        assignToMyAlpha_(@intCast(6 + fn_ - 1));
        itemToBeAssigned = ASSIGN_CLEAR;
        assignToMyAlpha_(@intCast(12 + fn_ - 1));
    }
    frontier_screen.refreshScreen(43);
}

// ===========================================================================
// Softmenus
// ===========================================================================
pub export fn mm(id: i16) callconv(.c) i16 {
    var m: i16 = 0;
    if (id != 0) {
        while (softmenu[@intCast(m)].menuItem != 0) {
            if (softmenu[@intCast(m)].menuItem == id) {
                break;
            }
            m += 1;
        }
    }
    return m;
}

// ===========================================================================
// EXTRA DRAWINGS FOR RADIO_BUTTON / CHECK_BOX / MB_MACRO
// ===========================================================================
inline fn drawPixelArray(xx: u32, yy: u32, coords: [*]const [2]u8, count: u8, white: bool) void {
    var i: u8 = 0;
    while (i < count) : (i += 1) {
        if (white) {
            setWhitePixel(xx + coords[i][0], yy + coords[i][1]);
        } else {
            setBlackPixel(xx + coords[i][0], yy + coords[i][1]);
        }
    }
}

const rbCheckedBlack linksection(code_section) = [_][2]u8{
    .{ 1, 3 }, .{ 1, 4 }, .{ 1, 5 }, .{ 1, 6 }, .{ 1, 7 },
    .{ 2, 2 }, .{ 2, 3 }, .{ 2, 4 }, .{ 2, 5 }, .{ 2, 6 },
    .{ 2, 7 }, .{ 2, 8 }, .{ 3, 1 }, .{ 3, 2 }, .{ 3, 3 },
    .{ 3, 7 }, .{ 3, 8 }, .{ 3, 9 }, .{ 4, 1 }, .{ 4, 2 },
    .{ 4, 4 }, .{ 4, 5 }, .{ 4, 6 }, .{ 4, 8 }, .{ 4, 9 },
    .{ 5, 1 }, .{ 5, 2 }, .{ 5, 4 }, .{ 5, 5 }, .{ 5, 6 },
    .{ 5, 8 }, .{ 5, 9 }, .{ 6, 1 }, .{ 6, 2 }, .{ 6, 4 },
    .{ 6, 5 }, .{ 6, 6 }, .{ 6, 8 }, .{ 6, 9 }, .{ 7, 1 },
    .{ 7, 2 }, .{ 7, 3 }, .{ 7, 7 }, .{ 7, 8 }, .{ 7, 9 },
    .{ 8, 2 }, .{ 8, 3 }, .{ 8, 4 }, .{ 8, 5 }, .{ 8, 6 },
    .{ 8, 7 }, .{ 8, 8 }, .{ 9, 3 }, .{ 9, 4 }, .{ 9, 5 },
    .{ 9, 6 }, .{ 9, 7 },
};
const rbCheckedWhite linksection(code_section) = [_][2]u8{
    .{ 0, 2 },  .{ 0, 3 },  .{ 0, 4 },  .{ 0, 5 }, .{ 0, 6 },  .{ 0, 7 },  .{ 0, 8 },
    .{ 1, 1 },  .{ 1, 8 },  .{ 1, 9 },  .{ 2, 0 }, .{ 2, 1 },  .{ 2, 9 },  .{ 2, 10 },
    .{ 3, 0 },  .{ 3, 4 },  .{ 3, 5 },  .{ 3, 6 }, .{ 3, 10 }, .{ 4, 0 },  .{ 4, 3 },
    .{ 4, 7 },  .{ 4, 10 }, .{ 5, 0 },  .{ 5, 3 }, .{ 5, 7 },  .{ 5, 10 }, .{ 6, 0 },
    .{ 6, 3 },  .{ 6, 7 },  .{ 6, 10 }, .{ 7, 0 }, .{ 7, 4 },  .{ 7, 5 },  .{ 7, 6 },
    .{ 7, 10 }, .{ 8, 0 },  .{ 8, 1 },  .{ 8, 9 }, .{ 8, 10 }, .{ 9, 1 },  .{ 9, 8 },
    .{ 9, 9 },
};

pub export fn RB_CHECKED(xx: u32, yy: u32) callconv(.c) void {
    drawPixelArray(xx, yy, &rbCheckedBlack, rbCheckedBlack.len, false);
    drawPixelArray(xx, yy, &rbCheckedWhite, rbCheckedWhite.len, true);
}

const rbUncheckedBlack linksection(code_section) = [_][2]u8{
    .{ 1, 3 }, .{ 1, 4 }, .{ 1, 5 }, .{ 1, 6 }, .{ 1, 7 },
    .{ 2, 2 }, .{ 2, 3 }, .{ 2, 7 }, .{ 2, 8 }, .{ 3, 1 },
    .{ 3, 2 }, .{ 3, 8 }, .{ 3, 9 }, .{ 4, 1 }, .{ 4, 9 },
    .{ 5, 1 }, .{ 5, 9 }, .{ 6, 1 }, .{ 6, 9 }, .{ 7, 1 },
    .{ 7, 2 }, .{ 7, 8 }, .{ 7, 9 }, .{ 8, 2 }, .{ 8, 3 },
    .{ 8, 7 }, .{ 8, 8 }, .{ 9, 3 }, .{ 9, 4 }, .{ 9, 5 },
    .{ 9, 6 }, .{ 9, 7 },
};
const rbUncheckedWhite linksection(code_section) = [_][2]u8{
    .{ 0, 2 },  .{ 0, 3 },  .{ 0, 4 },  .{ 0, 5 },  .{ 0, 6 }, .{ 0, 7 },  .{ 0, 8 },
    .{ 1, 1 },  .{ 1, 8 },  .{ 1, 9 },  .{ 2, 0 },  .{ 2, 1 }, .{ 2, 9 },  .{ 2, 10 },
    .{ 3, 0 },  .{ 3, 10 }, .{ 4, 0 },  .{ 4, 10 }, .{ 5, 0 }, .{ 5, 10 }, .{ 6, 0 },
    .{ 6, 10 }, .{ 7, 0 },  .{ 7, 10 }, .{ 8, 0 },  .{ 8, 1 }, .{ 8, 9 },  .{ 8, 10 },
    .{ 9, 1 },  .{ 9, 8 },  .{ 9, 9 },
};

pub export fn RB_UNCHECKED(xx: u32, yy: u32) callconv(.c) void {
    drawPixelArray(xx, yy, &rbUncheckedBlack, rbUncheckedBlack.len, false);
    drawPixelArray(xx, yy, &rbUncheckedWhite, rbUncheckedWhite.len, true);
}

const cbCheckedBlack linksection(code_section) = [_][2]u8{
    .{ 1, 1 }, .{ 1, 2 }, .{ 1, 3 }, .{ 1, 4 }, .{ 1, 5 }, .{ 1, 6 }, .{ 1, 7 }, .{ 1, 8 }, .{ 1, 9 },
    .{ 2, 1 }, .{ 2, 2 }, .{ 2, 3 }, .{ 2, 4 }, .{ 2, 5 }, .{ 2, 6 }, .{ 2, 7 }, .{ 2, 8 }, .{ 2, 9 },
    .{ 3, 1 }, .{ 3, 2 }, .{ 3, 8 }, .{ 3, 9 }, .{ 4, 1 }, .{ 4, 2 }, .{ 4, 4 }, .{ 4, 5 }, .{ 4, 6 },
    .{ 4, 8 }, .{ 4, 9 }, .{ 5, 1 }, .{ 5, 2 }, .{ 5, 4 }, .{ 5, 5 }, .{ 5, 6 }, .{ 5, 8 }, .{ 5, 9 },
    .{ 6, 1 }, .{ 6, 2 }, .{ 6, 4 }, .{ 6, 5 }, .{ 6, 6 }, .{ 6, 8 }, .{ 6, 9 }, .{ 7, 1 }, .{ 7, 2 },
    .{ 7, 8 }, .{ 7, 9 }, .{ 8, 1 }, .{ 8, 2 }, .{ 8, 3 }, .{ 8, 4 }, .{ 8, 5 }, .{ 8, 6 }, .{ 8, 7 },
    .{ 8, 8 }, .{ 8, 9 }, .{ 9, 1 }, .{ 9, 2 }, .{ 9, 3 }, .{ 9, 4 }, .{ 9, 5 }, .{ 9, 6 }, .{ 9, 7 },
    .{ 9, 8 }, .{ 9, 9 },
};
const cbCheckedWhite linksection(code_section) = [_][2]u8{
    .{ 0, 0 },  .{ 0, 1 },  .{ 0, 2 }, .{ 0, 3 },  .{ 0, 4 }, .{ 0, 5 }, .{ 0, 6 }, .{ 0, 7 },  .{ 0, 8 }, .{ 0, 9 },  .{ 0, 10 },
    .{ 1, 0 },  .{ 1, 10 }, .{ 2, 0 }, .{ 2, 10 }, .{ 3, 0 }, .{ 3, 3 }, .{ 3, 4 }, .{ 3, 5 },  .{ 3, 6 }, .{ 3, 7 },  .{ 3, 10 },
    .{ 4, 0 },  .{ 4, 3 },  .{ 4, 7 }, .{ 4, 10 }, .{ 5, 0 }, .{ 5, 3 }, .{ 5, 7 }, .{ 5, 10 }, .{ 6, 0 }, .{ 6, 3 },  .{ 6, 7 },
    .{ 6, 10 }, .{ 7, 0 },  .{ 7, 3 }, .{ 7, 4 },  .{ 7, 5 }, .{ 7, 6 }, .{ 7, 7 }, .{ 7, 10 }, .{ 8, 0 }, .{ 8, 10 }, .{ 9, 0 },
    .{ 9, 10 },
};

pub export fn CB_CHECKED(xx: u32, yy: u32) callconv(.c) void {
    lcd_fill_rect(xx, yy - 1, 10, 11, 0); // Clear background area (C: unconditional)
    drawPixelArray(xx, yy, &cbCheckedBlack, cbCheckedBlack.len, false);
    drawPixelArray(xx, yy, &cbCheckedWhite, cbCheckedWhite.len, true);
}

const cbUncheckedBlack linksection(code_section) = [_][2]u8{
    .{ 1, 1 }, .{ 1, 2 }, .{ 1, 3 }, .{ 1, 4 }, .{ 1, 5 }, .{ 1, 6 }, .{ 1, 7 }, .{ 1, 8 }, .{ 1, 9 },
    .{ 2, 1 }, .{ 2, 9 }, .{ 3, 1 }, .{ 3, 9 }, .{ 4, 1 }, .{ 4, 9 }, .{ 5, 1 }, .{ 5, 9 }, .{ 6, 1 },
    .{ 6, 9 }, .{ 7, 1 }, .{ 7, 9 }, .{ 8, 1 }, .{ 8, 9 }, .{ 9, 1 }, .{ 9, 2 }, .{ 9, 3 }, .{ 9, 4 },
    .{ 9, 5 }, .{ 9, 6 }, .{ 9, 7 }, .{ 9, 8 }, .{ 9, 9 },
};
const cbUncheckedWhite linksection(code_section) = [_][2]u8{
    .{ 0, 0 },  .{ 0, 1 },  .{ 0, 2 },  .{ 0, 3 },  .{ 0, 4 },  .{ 0, 5 },  .{ 0, 6 },  .{ 0, 7 },  .{ 0, 8 }, .{ 0, 9 },  .{ 0, 10 },
    .{ 1, 0 },  .{ 1, 10 }, .{ 2, 0 },  .{ 2, 10 }, .{ 3, 0 },  .{ 3, 10 }, .{ 4, 0 },  .{ 4, 10 }, .{ 5, 0 }, .{ 5, 10 }, .{ 6, 0 },
    .{ 6, 10 }, .{ 7, 0 },  .{ 7, 10 }, .{ 8, 0 },  .{ 8, 10 }, .{ 9, 0 },  .{ 9, 10 },
};

pub export fn CB_UNCHECKED(xx: u32, yy: u32) callconv(.c) void {
    lcd_fill_rect(xx, yy - 1, 10, 11, 0); // Clear background area (C: unconditional)
    drawPixelArray(xx, yy, &cbUncheckedBlack, cbUncheckedBlack.len, false);
    drawPixelArray(xx, yy, &cbUncheckedWhite, cbUncheckedWhite.len, true);
}

const mbDiamond linksection(code_section) = [_][2]u8{
    .{ 5, 0 },
    .{ 4, 1 },
    .{ 6, 1 },
    .{ 3, 2 },
    .{ 7, 2 },
    .{ 2, 3 },
    .{ 8, 3 },
    .{ 1, 4 },
    .{ 9, 4 },
    .{ 0, 5 },
    .{ 10, 5 },
    .{ 1, 6 },
    .{ 9, 6 },
    .{ 2, 7 },
    .{ 8, 7 },
    .{ 3, 8 },
    .{ 7, 8 },
    .{ 4, 9 },
    .{ 6, 9 },
    .{ 5, 10 },
};
const mb_offs: u32 = 1;

pub export fn MB_MACRO(xx: u32, yy: u32) callconv(.c) void {
    var i: u8 = 0;
    while (i < mbDiamond.len) : (i += 1) {
        frontier_plotstat.placePixel(xx + mbDiamond[i][0] - mb_offs, yy + mbDiamond[i][1]);
        // DOUBLE: duplicate row above for thickness
        frontier_plotstat.placePixel(xx + mbDiamond[i][0] - mb_offs, yy + mbDiamond[i][1] -% 1);
    }
}

const mbDiamondFill linksection(code_section) = [_][2]u8{
    .{ 5, 3 },
    .{ 4, 4 },
    .{ 5, 4 },
    .{ 6, 4 },
    .{ 3, 5 },
    .{ 4, 5 },
    .{ 5, 5 },
    .{ 6, 5 },
    .{ 7, 5 },
    .{ 3, 6 },
    .{ 4, 6 },
    .{ 5, 6 },
    .{ 6, 6 },
    .{ 7, 6 },
    .{ 4, 7 },
    .{ 5, 7 },
    .{ 6, 7 },
    .{ 5, 8 },
};

pub export fn MB_MACRO_CHECKED(xx: u32, yy: u32) callconv(.c) void {
    MB_MACRO(xx, yy);
    var i: u8 = 0;
    while (i < mbDiamondFill.len) : (i += 1) {
        frontier_plotstat.placePixel(xx + mbDiamondFill[i][0] - mb_offs, yy + mbDiamondFill[i][1] -% 1);
    }
}

// ===========================================================================
// fnSetBCD / fnLongPressSwitches
// ===========================================================================
pub export fn fnSetBCD(bcd: u16) callconv(.c) void {
    switch (bcd) {
        BCD9c, BCD10c, BCDu => {
            bcdDisplaySign = @intCast(bcd);
        },
        else => {},
    }
}

pub export fn fnLongPressSwitches(option: u16) callconv(.c) void {
    switch (option) {
        RBX_F14, RBX_F124, RBX_F1234 => {
            LongPressF = @intCast(option);
        },
        RBX_M14, RBX_M124, RBX_M1234 => {
            LongPressM = @intCast(option);
        },
        else => {
            LongPressM = RBX_M1234;
            LongPressF = RBX_F124;
        },
    }
}
