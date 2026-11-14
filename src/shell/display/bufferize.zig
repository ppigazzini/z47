// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/bufferize.c: the NIM/AIM input-buffer state machine.
// This is the keystroke-to-buffer layer: addItemToBuffer / addItemToNimBuffer
// drive a character-by-character editor over aimBuffer (shared with NIM), the
// nim*ToDisplayBuffer family renders the in-progress entry, and closeNim/closeAim
// commit the buffer into register X (long integer, real34, short integer with a
// GMP/mpz range check, complex34, fraction, string). The alpha-cursor and
// alpha-selection helpers round it out. testSuite-reachable.
//
// Faithful, line-by-line port.
//   * TEXT_MULTILINE_EDIT and IR_PRINTING are unconditionally #defined for every
//     z47 build (defines.h, no platform guard), so those branches are always
//     reproduced; the alternative !TEXT_MULTILINE_EDIT xcopy is dead and skipped.
//   * EXTRA_INFO_ON_CALC_ERROR is 1 on the PC host and 0 on DMCP/testSuite. The
//     moreInfoOnError console hints are gated on the extra_info build option, like
//     the sibling error owner; the sprintf-into-errorMessage that precedes them is
//     gated the same way (it only feeds moreInfoOnError's split-string form).
//   * PC_BUILD-only debug printf and jm_show_calc_state blocks are host-only
//     (gated on !dmcp_build); the VERBOSE_MINIMUM one also excludes the testSuite,
//     which undefines that macro.
//   * DEBUGUNDO is never defined; those printf lines are skipped.
//   * INTEGERSHORTCUTS / isR47FAM / GROUPWIDTH_* / SEPARATOR_* / RADIX34_MARK /
//     COMPLEX_UNIT / PRODUCT_SIGN are runtime macros over globals, reproduced
//     inline. GROUPWIDTH_LEFT assignment writes back to grpGroupingLeft.
//   * indexOfItems / softmenu / dynamicSoftmenu / softmenuStack are C arrays, bound
//     by address with @extern([*c]const T, ...) (NOT a [*c] pointer extern).
//   * long-integer range check uses GMP mpz via the __gmpz_* symbols; mp_limb_t is
//     usize (== pointer width on every target), matching the sibling integer owner.
//   * No DMCP ROM calls (lcd_/sys_/key_/...) and no limb-size-dependent byte/limb
//     counts appear in this file, so there are no ROM trampolines or OS32/OS64
//     splits here.

const std = @import("std");
const matrix_lifecycle = @import("../matrix_editor/matrix_lifecycle.zig");
const builtin = @import("builtin");
const frontier_build_options = @import("frontier_build_options");
const extra_info: bool = frontier_build_options.extra_info_on_calc_error;
const dmcp_build: bool = frontier_build_options.dmcp_build;
// OPTION_IR_PRINTING guards more than printing here: the region also carries the
// lastItem writes keyboard.c reads on key release.
const ir_printing: bool = frontier_build_options.ir_printing;
// TESTSUITE_BUILD undefines VERBOSE_MINIMUM but leaves MONITOR_IRPRINT defined.
const is_testsuite_build: bool = frontier_build_options.is_testsuite_build;
// OPTION_DRG_CFG: DRG during number entry chooses the unit of the number, and a
// D.MS entry shows and closes as degrees, minutes and seconds.
const option_drg_cfg: bool = frontier_build_options.option_drg_cfg;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const bool_t = u8;
const calcRegister_t = i16;
const angularMode_t = c_int;

const DECNUMUNITS = 25;
const abi = @import("abi"); // shared ABI bindings
const gap_insert = @import("../../core/text/gap_insert.zig"); // std-only digit-group gap insertion
const frontier_matrix_editor = @import("../matrix_editor/matrix_editor.zig");
const frontier_addons = @import("../extensions/addons.zig");
const frontier_calc_mode = @import("../calc_mode.zig");
const frontier_char_string = @import("text/char_string.zig");
const frontier_conversion_angles = @import("../convert/conversion_angles.zig");
const frontier_date_time = @import("../convert/date_time.zig");
const frontier_conversion_units = @import("../convert/conversion_units.zig");
const frontier_debug = @import("../debug.zig");
const frontier_display = @import("display.zig");
const frontier_error = @import("../error.zig");
const frontier_items = @import("items/items.zig");
const frontier_manage = @import("../program/manage.zig");
const frontier_print = @import("../print/print.zig");
const frontier_radio_button_catalog = @import("../extensions/radio_button_catalog.zig");
const frontier_register_value_conversions = @import("../register_value_conversions.zig");
const frontier_screen = @import("screen.zig");
const frontier_softmenus = @import("softmenus/softmenus.zig");
const frontier_sort = @import("sort.zig");
const frontier_status_bar = @import("statusbar/status_bar.zig");
const frontier_tam = @import("../input/tam.zig");
const frontier_timer = @import("../timer.zig");
const real_t = abi.Real;
const real34_t = abi.Real34;
const realContext_t = abi.RealContext;

const item_t = abi.Item;
const softmenu_t = abi.Softmenu;
const dynamicSoftmenu_t = abi.DynamicSoftmenu;
const softmenuStack_t = abi.SoftmenuStack;
const tamState_t = abi.TamState;

const fInMim_t = abi.FInMim;
const numStr = struct { noStr: [3]u8 };

// GMP long integer (mpz). The mpz_* names are header macros; the real symbols are
// __gmpz_*. The limb width == pointer width on every z47 target, == usize.
const mp_limb_t = usize;
const mpz_struct = abi.Mpz;
// longInteger_t == mpz_t == __mpz_struct[1]; a local decays to a pointer.
const longInteger_t = [1]mpz_struct;

// ---------------------------------------------------------------------------
// Constants (probed from c47.h via /tmp probe)
// ---------------------------------------------------------------------------
const AIM_BUFFER_LENGTH = 1024;
// A string register's byte limit: 1019 bytes stored plus a terminator; the editor scrolls through displayAIMbufferoffset.
const MAX_STRING_BYTE_LENGTH = 1020;
// The equation store is 255 blocks: a uint8_t block count, terminator included.
const MAX_EQUATION_BYTE_LENGTH = 1020;
const CATALOG_MVAR = 18;
const CMP_CLEANED_STRING_ONLY = 1;
const CM_AIM = 1;
const CM_ASSIGN = 4;
const CM_EIM = 13;
const CM_MIM = 12;
const CM_NIM = 2;
const CM_NORMAL = 0;
const CM_PEM = 3;
const CST_01 = 128;
const CST_02 = 129;
const CST_03 = 130;
const CST_04 = 131;
const CST_05 = 132;
const CST_06 = 133;
const CST_07 = 134;
const CST_08 = 135;
const CST_09 = 136;
const CST_10 = 137;
const CST_11 = 138;
const CST_12 = 139;
const CST_13 = 140;
const CST_14 = 141;
const CST_15 = 142;
const CST_16 = 143;
const CST_17 = 144;
const CST_18 = 145;
const CST_19 = 146;
const CST_20 = 147;
const CST_21 = 148;
const CST_22 = 149;
const CST_23 = 150;
const CST_24 = 151;
const CST_25 = 152;
const CST_26 = 153;
const CST_27 = 154;
const CST_28 = 155;
const CST_29 = 156;
const CST_30 = 157;
const CST_31 = 158;
const CST_32 = 159;
const CST_33 = 160;
const CST_34 = 161;
const CST_35 = 162;
const CST_36 = 163;
const CST_37 = 164;
const CST_38 = 165;
const CST_39 = 166;
const CST_40 = 167;
const CST_41 = 168;
const CST_42 = 169;
const CST_43 = 170;
const CST_44 = 171;
const CST_45 = 172;
const CST_46 = 173;
const CST_47 = 174;
const CST_48 = 175;
const CST_49 = 176;
const CST_50 = 177;
const CST_51 = 178;
const CST_52 = 179;
const CST_53 = 180;
const CST_54 = 181;
const CST_55 = 182;
const CST_56 = 183;
const CST_57 = 184;
const CST_58 = 185;
const CST_59 = 186;
const CST_60 = 187;
const CST_61 = 188;
const CST_62 = 189;
const CST_63 = 190;
const CST_64 = 191;
const CST_65 = 192;
const CST_66 = 193;
const CST_67 = 194;
const CST_68 = 195;
const CST_69 = 196;
const CST_70 = 197;
const CST_71 = 198;
const CST_72 = 199;
const CST_73 = 200;
const CST_74 = 201;
const CST_75 = 202;
const CST_76 = 203;
const CST_77 = 204;
const CST_78 = 205;
const CST_79 = 206;
const CST_80 = 208;
const CST_81 = 209;
const CST_82 = 210;
const CST_83 = 211;
const CST_84 = 212;
const EIM_ENABLED = 256;
const EIM_STATUS = 256;
const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN = 1;
const ERROR_BAD_INPUT = 53;
const ERROR_INVALID_INTEGER_INPUT = 9;
const ERROR_INPUT_TOO_LONG = 10;
const ERROR_NONE = 0;
const ERROR_RAM_FULL = 11;
const ERROR_WORD_SIZE_TOO_SMALL = 14;
const ERR_REGISTER_LINE = 102;
const FIRST_CONSTANT = 128;
const FLAG_ALPHA = 32782;
const FLAG_ALPIN = 32802;
const FLAG_ASLIFT = 49187;
const FLAG_CPXRES = 32772;
const FLAG_CPXj = 32773;
const FLAG_FRACT = 32775;
const FLAG_IRFRAC = 32839;
const FLAG_IRFRQ = 49224;
const FLAG_MULTx = 32795;
const FLAG_NUMIN = 32801;
const FLAG_OVERFLOW = 32780;
const FLAG_POLAR = 32774;
const FLAG_SPCRES = 32791;
const FLAG_YMD = 49153;
const ID_43S = 0;
const ID_CPXDP = 4;
const ID_DP = 2;
const ID_LI = 7;
const ITM_0 = 540;
const ITM_1 = 541;
const ITM_10x = 67;
const ITM_1ONX = 73;
const ITM_2 = 542;
const ITM_2X = 64;
const ITM_3 = 543;
const ITM_4 = 544;
const ITM_5 = 545;
const ITM_6 = 546;
const ITM_7 = 547;
const ITM_8 = 548;
const ITM_9 = 549;
const ITM_A = 550;
const ITM_ALL = 1410;
const ITM_ALOG_SIGN = 999;
const ITM_ARG = 1706;
const ITM_B = 551;
const ITM_BACKSPACE = 1738;
const ITM_BATT = 1413;
const ITM_BESTFQ = 1435;
const ITM_BN = 1416;
const ITM_BNS = 1417;
const ITM_C = 552;
const ITM_CC = 1730;
const ITM_CEIL = 87;
const ITM_CF = 110;
const ITM_CHS = 97;
const ITM_CNST = 207;
const ITM_COMB = 49;
const ITM_COMMA = 818;
const ITM_CONJ = 1431;
const ITM_CONSTpi = 109;
const ITM_CORR = 1433;
const ITM_COS_SIGN = 2072;
const ITM_COV = 1434;
const ITM_CR = 1172;
const ITM_CUBE = 59;
const ITM_CUBEROOT = 62;
const ITM_D = 553;
const ITM_DAY = 1440;
const ITM_DECR = 91;
const ITM_DEG = 1445;
const ITM_DENMAX2 = 2551;
const ITM_DISK = 1474;
const ITM_DMS = 1451;
const ITM_DMS2 = 116;
const ITM_DOWN_ARROW = 895;
const ITM_DRG = 1873;
const ITM_DSP = 1573;
const ITM_DTtoJ = 1862;
const ITM_DtoJ = 1454;
const ITM_E = 554;
const ITM_EEXCHR = 2032;
const ITM_EE_EXP_TH = 1816;
const ITM_ENG = 1460;
const ITM_ENTER = 35;
const ITM_ERF = 1466;
const ITM_ERFC = 1467;
const ITM_EX1 = 1575;
const ITM_EXIT1 = 1737;
const ITM_EXP = 65;
const ITM_EXPONENT = 990;
const ITM_EXPT = 1470;
const ITM_Ek = 1727;
const ITM_F = 555;
const ITM_FF = 112;
const ITM_FIB = 1472;
const ITM_FIX = 1473;
const ITM_FLOOR = 88;
const ITM_FP = 94;
const ITM_GAMMAX = 1664;
const ITM_GD = 1478;
const ITM_GDM1 = 1479;
const ITM_GET_ADM = 2763;
const ITM_GET_DMX = 1558;
const ITM_GET_ISM = 1606;
const ITM_GET_NDEC = 2768;
const ITM_GET_REALDF = 2766;
const ITM_GET_RM = 2019;
const ITM_GRAD = 1480;
const ITM_HASH_JM = 1872;
const ITM_HRtoTM = 1686;
const ITM_IM = 1485;
const ITM_INC = 92;
const ITM_INDIRECTION = 539;
const ITM_INDIRECT_T = 2418;
const ITM_INDIRECT_X = 2415;
const ITM_INDIRECT_Y = 2416;
const ITM_INDIRECT_Z = 2417;
const ITM_INFINITY = 924;
const ITM_IP = 93;
const ITM_IRFRAC = 2056;
const ITM_JtoDT = 1863;
const ITM_Kk = 1726;
const ITM_LASTX = 1502;
const ITM_LEFT_ARROW = 892;
const ITM_LG_SIGN = 2069;
const ITM_LN = 69;
const ITM_LN1X = 1614;
const ITM_LNGAMMA = 1508;
const ITM_LN_SIGN = 2070;
const ITM_LOG10 = 71;
const ITM_LOG2 = 68;
const ITM_LOGICALNOT = 123;
const ITM_LocRQ = 1515;
const ITM_M1X = 1679;
const ITM_MAGNITUDE = 105;
const ITM_MANT = 1517;
const ITM_MEM = 1519;
const ITM_MINUS = 819;
const ITM_MONTH = 1521;
const ITM_MULPI = 1523;
const ITM_NEXTP = 107;
const ITM_NOP = 1542;
const ITM_NSIGMA = 435;
const ITM_NULL = 0;
const ITM_OBELUS = 857;
const ITM_OFF = 1543;
const ITM_PAIR_OF_PARENTHESES = 997;
const ITM_PERIOD = 820;
const ITM_PERM = 50;
const ITM_PLUS = 817;
const ITM_RAD = 1557;
const ITM_RAN = 1559;
const ITM_RCL = 51;
const ITM_RCLADD = 52;
const ITM_RCLDIV = 55;
const ITM_RCLMAX = 1432;
const ITM_RCLMIN = 1462;
const ITM_RCLMULT = 54;
const ITM_RCLSUB = 53;
const ITM_RDP = 1565;
const ITM_RE = 1566;
const ITM_REG_X = 527;
const ITM_REexIM = 1570;
const ITM_RIGHT_ARROW = 894;
const ITM_RMODE = 121;
const ITM_ROOT_SIGN = 1000;
const ITM_ROUND2 = 1868;
const ITM_ROUNDI2 = 1869;
const ITM_RSD = 1577;
const ITM_Rdown = 40;
const ITM_SCI = 1587;
const ITM_SDL = 423;
const ITM_SDR = 424;
const ITM_SETSIG2 = 2197;
const ITM_SF = 111;
const ITM_SHOW = 1742;
const ITM_SIGFIG = 1866;
const ITM_SIGMA1onx = 452;
const ITM_SIGMA1onx2 = 453;
const ITM_SIGMA1ony = 455;
const ITM_SIGMA1ony2 = 456;
const ITM_SIGMAln2x = 444;
const ITM_SIGMAln2y = 447;
const ITM_SIGMAlnx = 443;
const ITM_SIGMAlnxy = 442;
const ITM_SIGMAlny = 446;
const ITM_SIGMAlnyonx = 450;
const ITM_SIGMAx = 436;
const ITM_SIGMAx2 = 438;
const ITM_SIGMAx2lny = 449;
const ITM_SIGMAx2ony = 451;
const ITM_SIGMAx2y = 439;
const ITM_SIGMAx3 = 457;
const ITM_SIGMAx4 = 458;
const ITM_SIGMAxlny = 448;
const ITM_SIGMAxony = 454;
const ITM_SIGMAxy = 441;
const ITM_SIGMAy = 437;
const ITM_SIGMAy2 = 440;
const ITM_SIGMAylnx = 445;
const ITM_SIGN = 1600;
const ITM_SIN_SIGN = 2071;
const ITM_SMW = 1607;
const ITM_SQUARE = 58;
const ITM_SQUAREROOTX = 61;
const ITM_SSIZE = 1609;
const ITM_STDDEVPOP = 1674;
const ITM_STO = 44;
const ITM_STOADD = 45;
const ITM_STODIV = 48;
const ITM_STOMAX = 1430;
const ITM_STOMIN = 1545;
const ITM_STOMULT = 47;
const ITM_STOSUB = 46;
const ITM_SUB_0 = 1080;
const ITM_SUB_A = 1090;
const ITM_SUB_INFINITY = 1077;
const ITM_SUB_MINUS = 1076;
const ITM_SUB_PLUS = 1075;
const ITM_SUB_SUN = 1073;
const ITM_SUB_a = 1116;
const ITM_SUB_alpha = 1070;
const ITM_SUB_delta = 1071;
const ITM_SUB_mu = 1072;
const ITM_SUB_pi = 1142;
const ITM_SUN = 953;
const ITM_SUP_0 = 1008;
const ITM_SUP_9 = 1017;
const ITM_SUP_A = 1018;
const ITM_SUP_INFINITY = 1006;
const ITM_SUP_MINUS = 1004;
const ITM_SUP_PLUS = 1003;
const ITM_SUP_a = 1044;
const ITM_SUP_pi = 1143;
const ITM_SLASH = 821;
const ITM_SUP_SLASH = 2448;
const ITM_SUP_DOT = 2449;
const ITM_SUP_COMMA = 2450;
const ITM_SW = 1617;
const ITM_SXY = 1618;
const ITM_TAN_SIGN = 2073;
const ITM_TICKS = 1620;
const ITM_UNIT = 1867;
const ITM_UNITV = 1628;
const ITM_UP_ARROW = 893;
const ITM_VERTICAL_BAR = 998;
const ITM_WDAY = 1633;
const ITM_WM = 1635;
const ITM_WM1 = 1637;
const ITM_WP = 1636;
const ITM_XFACT = 108;
const ITM_ADD = 95;
const ITM_SUB = 96;
const ITM_MULT = 98;
const ITM_DIV = 99;
const ITM_PC = 1695;
const ITM_DELTAPC = 1666;
const ITM_XTHROOT = 63;
const ITM_XW = 1642;
const ITM_YEAR = 1647;
const ITM_YX = 60;
const ITM_Z = 575;
const ITM_a = 576;
const ITM_alpha = 628;
const ITM_arccos = 81;
const ITM_arcosh = 82;
const ITM_arcsin = 83;
const ITM_arctan = 85;
const ITM_arsinh = 84;
const ITM_artanh = 86;
const ITM_cos = 74;
const ITM_cosh = 75;
const ITM_delta = 631;
const ITM_dotD = 1741;
const ITM_ms = 1909;
const ITM_mu = 640;
const ITM_op_a = 1828;
const ITM_op_a2 = 1829;
const ITM_op_j = 1830;
const ITM_op_j_SIGN = 2165;
const ITM_op_j_pol = 1795;
const ITM_pi = 644;
const ITM_poly_SIGN = 2166;
const ITM_sin = 76;
const ITM_sincpi = 1540;
const ITM_sinh = 78;
const ITM_tan = 79;
const ITM_tanh = 80;
const ITM_toINT = 1687;
const ITM_toREAL = 1691;
const ITM_z = 601;
const ITM_zetaX = 1670;
const LAST_CONSTANT = 212;
const MAXLINES = 5;
const MNU_BASE = 3016;
const MNU_BITS = 3018;
const MNU_INTS = 3074;
const NC_NORMAL = 0;
const NC_SUBSCRIPT = 1;
const NC_SUPERSCRIPT = 2;
const NOPARAM = 9876;
const NP_COMPLEX_EXPONENT = 9;
const NP_COMPLEX_FLOAT_PART = 8;
const NP_COMPLEX_FRACTION_DENOMINATOR = 11;
const NP_COMPLEX_HP32SII_DENOMINATOR = 12;
const NP_COMPLEX_INT_PART = 7;
const NP_EMPTY = 0;
const NP_FRACTION_DENOMINATOR = 6;
const NP_HP32SII_DENOMINATOR = 10;
const NP_INT_10 = 1;
const NP_INT_16 = 2;
const NP_INT_BASE = 3;
const NP_REAL_EXPONENT = 5;
const NP_REAL_FLOAT_PART = 4;
const NUMBER_OF_DYNAMIC_SOFTMENUS = 22;
const PGM_RUNNING = 1;
const REAL34_SIZE_IN_BYTES = 16;
const REGISTER_L = 108;
const REGISTER_X = 100;
const SCREEN_WIDTH = 400;
const SCRUPD_MANUAL_SHIFT_STATUS = 8;
const SCRUPD_MANUAL_STACK = 2;
const SCRUPD_SKIP_STACK_ONE_TIME = 32;
const SIM_1COMPL = 1;
const SIM_2COMPL = 2;
const SIM_SIGNMT = 3;
const SIM_UNSIGN = 0;
const TEMP_REGISTER_1 = 135;
const TI_DATA_NEG_OVRFL = 111;
const TI_DAY_OF_WEEK = 36;
const TI_NO_INFO = 0;
const TI_SHOW_REGISTER = 14;
const TI_UNDO_DISABLED = 49;
const YY_MASK_OFF = 32768;
const amAngleMask = 15;
const amDMS = 3;
const amMultPi = 4;
const amNone = 5;
const amRadian = 0;
const bugMsgUnexpectedSValue = 4;
const bugMsgValueFor = 0;
const dtComplex34 = 2;
const dtDate = 4;
const dtLongInteger = 0;
const dtReal34 = 1;
const dtShortInteger = 8;
const dtString = 5;
const dtTime = 3;
const nocompress = 0;
const stdNoEnlarge = 0;

// STD_* / special string macro byte sequences (fonts.h).
const STD_CUBE_ROOT = "\xa2\x1b";
const STD_DOT = "\x80\xb7";
const STD_EulerE = "\xa1\x47";
const SOLVER_STATUS_READY_TO_EXECUTE: u16 = 1;
const STD_GAMMA = "\x83\x93";
const STD_MEASURED_ANGLE = "\xa2\x21";
const STD_SLASH = "\x2f";
const STD_SPACE_4_PER_EM = "\xa0\x05";
const STD_SPACE_HAIR = "\xa0\x0a";
const STD_SQUARE_ROOT = "\xa2\x1a";
const STD_SUP_0 = "\xa1\x60";
const STD_SUP_MINUS = "\xa1\x6b";
const STD_xTH_ROOT = "\xa2\x1c";
const STD_zeta = "\x83\xb6";
const STD_op_i = "\xa1\x48";
const STD_op_j = "\xa1\x49";
const STD_CROSS = "\x80\xd7";
const STD_WCOMMA = "\xa7\x88";
const STD_DEGREE = "\x80\xb0";
const STD_RIGHT_SINGLE_QUOTE = "\xa0\x19";
const STD_RIGHT_DOUBLE_QUOTE = "\xa0\x1d";
const STRING_ANGLE_DMS = 21;
const DRG_NIM_BIT = 5;

// ---------------------------------------------------------------------------
// C arrays (bind by address) and extern globals.
// ---------------------------------------------------------------------------
const indexOfItems = @extern([*c]const item_t, .{ .name = "indexOfItems" });
const softmenu = @extern([*c]const softmenu_t, .{ .name = "softmenu" });
const dynamicSoftmenu = @extern([*c]dynamicSoftmenu_t, .{ .name = "dynamicSoftmenu" });
const softmenuStack = @extern([*c]softmenuStack_t, .{ .name = "softmenuStack" });
const commonBugScreenMessages = @extern([*c]const [100]u8, .{ .name = "commonBugScreenMessages" });

extern var ctxtReal34: realContext_t;
extern var ctxtReal39: realContext_t;

// pointer-typed globals (genuine pointers, [*c]).
extern var aimBuffer: [*c]u8;
extern var nimBufferDisplay: [*c]u8;
extern var errorMessage: [*c]u8;

extern var asmBuffer: [5]u8;

// const_0 / const39_pi / const34_0 are NOT symbols: they are
// constantPointers.h macros over the shared `constants` blob, by byte offset.
// The abi accessors read them at the offsets
// .github/project/check-constant-offsets.py verifies against the oracle.
const const_0 = abi.constants.const_0();
const const39_pi = abi.constants.const39_pi();
const const34_0 = abi.constants.const34_0();

// scalar globals
// Owned global (bufferize.c defined it). Other C units reference it.
pub export var delayCloseNim: bool_t = 0;
extern var calcMode: u8;
extern var calcModel: u8;
extern var previousCalcMode: u8;
extern var programRunStop: u8;
extern var lastErrorCode: u8;
extern var screenUpdatingMode: u8;
extern var temporaryInformation: u8;
extern var nimNumberPart: u8;
extern var nimRealPart: u8;
extern var hexDigits: u8;
extern var nextChar: u8;
extern var scrLock: u8;
extern var entryStatus: u8;
extern var Input_Default: u8;
extern var shortIntegerMode: u8;
extern var shortIntegerWordSize: u8;
extern var DRG_Cycling: u8;
extern var grpGroupingLeft: u8;
extern var grpGroupingGr1Left: u8;
extern var grpGroupingGr1LeftOverflow: u8;
extern var grpGroupingRight: u8;
extern var grpGroupingHex: u8;
extern var grpGroupingBin: u8;
extern var fnKeyInCatalog: bool_t;
extern var doRefreshSoftMenu: bool_t;
extern var funcOK: bool_t;
extern var keyActionProcessed: bool_t;
extern var hourGlassIconEnabled: bool_t;
extern var temporaryFlagRect: bool_t;
extern var temporaryFlagPolar: bool_t;
extern var currentAngularMode: angularMode_t;
extern var nimPolarAngularMode: u8;
extern var drgConfig: u8;
extern var editingLiteralType: u8;
extern var catalog: i16;
extern var T_cursorPos: i16;
extern var alphaCursor: i16;
extern var displayAIMbufferoffset: i16;
extern var exponentSignLocation: i16;
extern var denominatorLocation: i16;
extern var imaginaryMantissaSignLocation: i16;
extern var imaginaryExponentSignLocation: i16;
extern var imaginaryDenominatorLocation: i16;
extern var exponentLimit: i16;
extern var lastItem: i16;
extern var lastCenturyHighUsed: u16;
extern var gapItemLeft: u16;
extern var gapItemRight: u16;
extern var currentSolverStatus: u16;
extern var lastIntegerBase: u32;
extern var lastDenominator: u32;
extern var xCursor: u32;
extern var shortIntegerMask: u64;
extern var shortIntegerSignBit: u64;
extern var tam: tamState_t;

// ---------------------------------------------------------------------------
// Function externs (cross-owner / runtime / libc / GMP / decNumber).
// ---------------------------------------------------------------------------
extern fn getSystemFlag(sf: c_int) bool_t;
extern fn setSystemFlag(sf: c_uint) void;
extern fn clearSystemFlag(sf: c_uint) void;
extern fn fnSetFlag(flag: u16) void;
extern fn resetShiftState() void;
extern fn moreInfoOnError(m1: [*c]const u8, m2: [*c]const u8, m3: [*c]const u8, m4: [*c]const u8) void;
extern fn fnTimerStart(nr: u8, param: u16, time: u32) void;
extern fn isDyadicFunction(item: u16) bool;
extern fn stringToInt16(str: [*c]const u8) i16;
extern fn stringToInt32(str: [*c]const u8) i32;
extern fn toInt32(str: [*c]const u8) i32;
// stringCopy(dest, source) = frontier_char_string.stringCopy(dest, source) (charString.h, non-MINGW64).
fn stringCopy(dest: [*c]u8, source: [*c]const u8) [*c]u8 {
    return frontier_char_string.stringCopy(dest, source);
}
// stringToReal34(source, destination) = decQuadFromString(destination, source, &ctxtReal34).
extern fn decQuadFromString(r: *real34_t, str: [*c]const u8, ctx: *realContext_t) *real34_t;
fn stringToReal34(str: [*c]const u8, dst: *real34_t) void {
    _ = decQuadFromString(dst, str, &ctxtReal34);
}
extern fn getRegisterDataType(regist: calcRegister_t) u32;
extern fn getRegisterDataPointer(regist: calcRegister_t) [*c]align(4) u8;
extern fn getRegisterTag(regist: calcRegister_t) u32;
extern fn setRegisterTag(regist: calcRegister_t, tag: u32) void;
extern fn reallocateRegister(regist: calcRegister_t, dataType: u32, dataSizeWithoutDataLenBlocks: u16, tag: u32) bool;
extern fn copySourceRegisterToDestRegister(rSource: calcRegister_t, rDest: calcRegister_t) void;
extern fn realPolarToRectangularInUnit(magnitude: *const real_t, theta: *const real_t, angularMode: angularMode_t, z: *cplx_t, realContext: *realContext_t) void;
const cplx_t = abi.Complex;
extern fn fnToPolar2(unusedButMandatoryParameter: u16) void;
extern fn fnToRect2(unusedButMandatoryParameter: u16) void;
extern fn real34CompareEqual(number1: *const real34_t, number2: *const real34_t) bool_t;
extern fn realCompareLessThan(number1: *const real_t, number2: *const real_t) bool_t;
extern fn saveForUndo() void;
extern fn undo() void;
extern fn chsShoI() void;

// IR_PRINTING (always enabled): printTrace family.

// real34 arithmetic = decQuad*/decNumber* (libdecnumber, &ctxtReal34 inline).
extern fn decQuadFromInt32(r: *real34_t, v: i32) *real34_t;
extern fn decQuadAdd(r: *real34_t, a: *const real34_t, b: *const real34_t, ctx: *realContext_t) *real34_t;
extern fn decQuadDivide(r: *real34_t, a: *const real34_t, b: *const real34_t, ctx: *realContext_t) *real34_t;
extern fn decQuadZero(r: *real34_t) *real34_t;
extern fn decimal128ToNumber(d: *const real34_t, dn: *real_t) *real_t;
extern fn decimal128FromNumber(d: *real34_t, dn: *const real_t, set: *realContext_t) *real34_t;
extern fn decNumberAdd(r: *real_t, a: *const real_t, b: *const real_t, ctx: *realContext_t) *real_t;

// GMP mpz (real symbols are __gmpz_*).
extern fn __gmpz_init(op: [*c]mpz_struct) void;
extern fn __gmpz_clear(op: [*c]mpz_struct) void;
extern fn __gmpz_set_str(rop: [*c]mpz_struct, str: [*c]const u8, base: c_int) c_int;
extern fn __gmpz_setbit(rop: [*c]mpz_struct, bit: c_ulong) void;
extern fn __gmpz_tdiv_q_ui(q: [*c]mpz_struct, n: [*c]const mpz_struct, d: c_ulong) c_ulong;
extern fn __gmpz_sub_ui(rop: [*c]mpz_struct, op1: [*c]const mpz_struct, op2: c_ulong) void;
extern fn __gmpz_add_ui(rop: [*c]mpz_struct, op1: [*c]const mpz_struct, op2: c_ulong) void;
extern fn __gmpz_cmp(op1: [*c]const mpz_struct, op2: [*c]const mpz_struct) c_int;

// libc
extern fn strlen(s: [*c]const u8) usize;
extern fn strcat(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strcpy(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strchr(s: [*c]const u8, c: c_int) [*c]u8;
extern fn strncmp(a: [*c]const u8, b: [*c]const u8, n: usize) c_int;
extern fn atoi(s: [*c]const u8) c_int;
extern fn strtoull(s: [*c]const u8, endptr: ?*[*c]u8, base: c_int) c_ulonglong;
extern fn sprintf(buf: [*c]u8, fmt: [*c]const u8, ...) c_int;
extern fn printf(fmt: [*c]const u8, ...) c_int;
extern fn fflush(stream: ?*anyopaque) c_int;

// PC_BUILD-only debug hook (referenced only under !dmcp_build).
const jm_show_calc_state = if (!dmcp_build) @extern(*const fn (comment: [*c]u8) callconv(.c) void, .{ .name = "jm_show_calc_state" }) else {};

// ---------------------------------------------------------------------------
// Inline helpers (the C macros).
// ---------------------------------------------------------------------------
fn stringByteLength(str: [*c]const u8) i32 {
    return @intCast(strlen(str));
}
fn getRegisterAngularMode(reg: calcRegister_t) angularMode_t {
    return @intCast(getRegisterTag(reg) & amAngleMask);
}
fn setRegisterAngularMode(reg: calcRegister_t, am: angularMode_t) void {
    setRegisterTag(reg, @intCast(am));
}
// Typed register views, declared once in abi.
const reg34 = abi.registerReal34;
const regImag34 = abi.registerImag34;
const regShortInteger = abi.registerShortInteger;
const regString = abi.registerString;
// TO_BLOCKS rounds its byte count up to the next 4-byte block and hands the
// uint32_t result to reallocateRegister's uint16_t block-count parameter, which
// keeps only the low 16 bits.
fn toBlocks(n: u32) u16 {
    return @truncate((n +% (BYTES_PER_BLOCK - 1)) >> BPB);
}
const BPB: u5 = 2;
const BYTES_PER_BLOCK: u32 = 1 << BPB;
const USER_C47: u8 = 46;
const USER_R47f_g: u8 = 61;
const USER_R47bk_fg: u8 = 62;
const USER_R47fg_bk: u8 = 63;
const USER_R47fg_g: u8 = 64;
const TO_ASM_ACTIVE: u8 = 9;
const NIM_REGISTER_LINE: calcRegister_t = REGISTER_X;
const YYSystem: bool_t = 1;
const LINE_NOLF: c_int = 3;
const LINE_FULL_U: u16 = 0; // LINE_FULL (printTraceMatElement takes uint16_t)
const LINE_FULL_C: c_int = 0; // LINE_FULL (printTraceX takes int)

extern fn fnConstant(constant: u16) callconv(.c) void;
fn fnConstantPtr() ?*const fn (u16) callconv(.c) void {
    return &fnConstant;
}

// RADIX34_MARK_STRING = gapChar1Radix : first two bytes of the radix separator,
// byte[1]==1 meaning a single-byte separator.
fn radix34MarkBytes() TwoBytes {
    return twoBytes(frontier_display.getGapChar1Radix());
}
fn radix34MarkByte0() u8 {
    return radix34MarkBytes().b0;
}
fn radix34MarkByte1() u8 {
    return radix34MarkBytes().b1;
}
fn separatorLeft() TwoBytes {
    return twoBytes(frontier_display.getGapChar1Left());
}
fn separatorRight() TwoBytes {
    return twoBytes(frontier_display.getGapChar1Right());
}
const ERROR_MESSAGE_LENGTH: usize = 512;

// EXTRA_INFO console-hint helpers (compiled out on firmware, like the siblings).
fn moreInfoOnErr(where: [*c]const u8, hint: [*c]const u8) void {
    if (comptime extra_info) {
        if (comptime !dmcp_build) {
            moreInfoOnError(where, hint, null, null);
        }
    }
}
fn moreInfoOnErr3(where: [*c]const u8, hint: [*c]const u8, hint2: [*c]const u8) void {
    if (comptime extra_info) {
        if (comptime !dmcp_build) {
            moreInfoOnError(where, hint, hint2, null);
        }
    }
}

// COMPLEX_UNIT / PRODUCT_SIGN runtime macros.
fn complexUnit() [*c]const u8 {
    return if (getSystemFlag(FLAG_CPXj) != 0) STD_op_j else STD_op_i;
}
fn productSign() [*c]const u8 {
    return if (getSystemFlag(FLAG_MULTx) != 0) STD_CROSS else STD_DOT;
}

// isR47FAM / INTEGERSHORTCUTS runtime macros.
fn isR47FAM() bool {
    return calcModel == USER_R47f_g or calcModel == USER_R47bk_fg or calcModel == USER_R47fg_bk or calcModel == USER_R47fg_g;
}
fn integerShortcuts() bool {
    return (calcMode == CM_NIM or calcMode == CM_PEM) and (calcModel == USER_C47 or isR47FAM());
}

// real34/real arithmetic macros over decQuad/decNumber.
fn int32ToReal34(source: i32, destination: *real34_t) void {
    _ = decQuadFromInt32(destination, source);
}
fn real34Add(op1: *const real34_t, op2: *const real34_t, res: *real34_t) void {
    _ = decQuadAdd(res, op1, op2, &ctxtReal34);
}
fn real34Divide(op1: *const real34_t, op2: *const real34_t, res: *real34_t) void {
    _ = decQuadDivide(res, op1, op2, &ctxtReal34);
}
const real34SetNegativeSign = abi.real34SetNegativeSign;
fn real34SetZero(destination: *real34_t) void {
    _ = decQuadZero(destination);
}
fn real34ToReal(source: *const real34_t, destination: *real_t) void {
    _ = decimal128ToNumber(source, destination);
}
fn realToReal34(source: *const real_t, destination: *real34_t) void {
    _ = decimal128FromNumber(destination, source, &ctxtReal34);
}
fn realAdd(op1: *const real_t, op2: *const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberAdd(res, op1, op2, ctxt);
}
fn realSetPositiveSign(operand: *real_t) void {
    operand.bits &= 0x7F;
}

// longInteger (mpz) wrappers (longIntegerType.h).
fn longIntegerInit(op: *longInteger_t) void {
    __gmpz_init(&op[0]);
}
fn longIntegerFree(op: *longInteger_t) void {
    __gmpz_clear(&op[0]);
}
fn stringToLongInteger(source: [*c]const u8, radix: i32, destination: *longInteger_t) i32 {
    return __gmpz_set_str(&destination[0], source, @intCast(radix));
}
fn longInteger2Pow(exp: u32, result: *longInteger_t) void {
    __gmpz_setbit(&result[0], exp);
}
fn longIntegerSetZero(op: *longInteger_t) void {
    __gmpz_clear(&op[0]);
    __gmpz_init(&op[0]);
}
fn longIntegerSetNegativeSign(op: *longInteger_t) void {
    op[0]._mp_size = -absI32(op[0]._mp_size);
}
fn longIntegerDivideUInt(op: *const longInteger_t, uint: u32, result: *longInteger_t) void {
    _ = __gmpz_tdiv_q_ui(&result[0], &op[0], uint);
}
fn longIntegerSubtractUInt(op: *const longInteger_t, uint: u32, result: *longInteger_t) void {
    __gmpz_sub_ui(&result[0], &op[0], uint);
}
fn longIntegerAddUInt(op: *const longInteger_t, uint: u32, result: *longInteger_t) void {
    __gmpz_add_ui(&result[0], &op[0], uint);
}
fn longIntegerCompare(op1: *const longInteger_t, op2: *const longInteger_t) i32 {
    return __gmpz_cmp(&op1[0], &op2[0]);
}
fn longIntegerIsNegative(op: *const longInteger_t) bool {
    return op[0]._mp_size < 0;
}
fn absI32(v: i32) i32 {
    return if (v < 0) -v else v;
}

// C int-promotion abs() and small helpers.
fn absInt(v: i32) i32 {
    return if (v < 0) -v else v;
}

// ---------------------------------------------------------------------------
// Data tables (TO_QSPI const) and isFunctionInMim.
// ---------------------------------------------------------------------------
const MimFunctionsType0 = [_]fInMim_t{
    .{ .itemNr = ITM_EXPONENT },
    .{ .itemNr = ITM_PERIOD },
    .{ .itemNr = ITM_0 },
    .{ .itemNr = ITM_1 },
    .{ .itemNr = ITM_2 },
    .{ .itemNr = ITM_3 },
    .{ .itemNr = ITM_4 },
    .{ .itemNr = ITM_5 },
    .{ .itemNr = ITM_6 },
    .{ .itemNr = ITM_7 },
    .{ .itemNr = ITM_8 },
    .{ .itemNr = ITM_9 },
    .{ .itemNr = ITM_CHS },
} ++ (if (option_drg_cfg) [_]fInMim_t{.{ .itemNr = ITM_DRG }} else [_]fInMim_t{}) ++ [_]fInMim_t{
    .{ .itemNr = ITM_CONSTpi },
};
const MimFunctionsType1 = [_]fInMim_t{
    .{ .itemNr = ITM_STO },
    .{ .itemNr = ITM_STOADD },
    .{ .itemNr = ITM_STOSUB },
    .{ .itemNr = ITM_STOMULT },
    .{ .itemNr = ITM_STODIV },
    .{ .itemNr = ITM_STOMAX },
    .{ .itemNr = ITM_STOMIN },
    .{ .itemNr = ITM_RCL },
    .{ .itemNr = ITM_RCLADD },
    .{ .itemNr = ITM_RCLSUB },
    .{ .itemNr = ITM_RCLMULT },
    .{ .itemNr = ITM_RCLDIV },
    .{ .itemNr = ITM_RCLMAX },
    .{ .itemNr = ITM_RCLMIN },
    .{ .itemNr = ITM_CF },
    .{ .itemNr = ITM_SF },
    .{ .itemNr = ITM_FF },
    .{ .itemNr = ITM_CNST },
    .{ .itemNr = ITM_ALL },
    .{ .itemNr = ITM_ENG },
    .{ .itemNr = ITM_FIX },
    .{ .itemNr = ITM_DSP },
    .{ .itemNr = ITM_SCI },
    .{ .itemNr = ITM_SIGFIG },
    .{ .itemNr = ITM_UNIT },
    .{ .itemNr = ITM_IRFRAC },
    .{ .itemNr = ITM_DENMAX2 },
    .{ .itemNr = ITM_SDL },
    .{ .itemNr = ITM_SDR },
    .{ .itemNr = ITM_RDP },
    .{ .itemNr = ITM_RMODE },
    .{ .itemNr = ITM_RSD },
    .{ .itemNr = ITM_DEG },
    .{ .itemNr = ITM_GRAD },
    .{ .itemNr = ITM_MULPI },
    .{ .itemNr = ITM_RAD },
};
const MimFunctionsType2 = [_]fInMim_t{
    .{ .itemNr = ITM_ADD },
    .{ .itemNr = ITM_SUB },
    .{ .itemNr = ITM_MULT },
    .{ .itemNr = ITM_DIV },
    .{ .itemNr = ITM_PC },
    .{ .itemNr = ITM_DELTAPC },
    .{ .itemNr = ITM_YX },
    .{ .itemNr = ITM_XTHROOT },
    .{ .itemNr = ITM_SQUARE },
    .{ .itemNr = ITM_CUBE },
    .{ .itemNr = ITM_SQUAREROOTX },
    .{ .itemNr = ITM_CUBEROOT },
    .{ .itemNr = ITM_2X },
    .{ .itemNr = ITM_EXP },
    .{ .itemNr = ITM_ROUND2 },
    .{ .itemNr = ITM_10x },
    .{ .itemNr = ITM_LOG2 },
    .{ .itemNr = ITM_LN },
    .{ .itemNr = ITM_LOG10 },
    .{ .itemNr = ITM_1ONX },
    .{ .itemNr = ITM_cos },
    .{ .itemNr = ITM_cosh },
    .{ .itemNr = ITM_sin },
    .{ .itemNr = ITM_sinh },
    .{ .itemNr = ITM_tan },
    .{ .itemNr = ITM_tanh },
    .{ .itemNr = ITM_arccos },
    .{ .itemNr = ITM_arcosh },
    .{ .itemNr = ITM_arcsin },
    .{ .itemNr = ITM_arsinh },
    .{ .itemNr = ITM_arctan },
    .{ .itemNr = ITM_artanh },
    .{ .itemNr = ITM_CEIL },
    .{ .itemNr = ITM_FLOOR },
    .{ .itemNr = ITM_DECR },
    .{ .itemNr = ITM_INC },
    .{ .itemNr = ITM_IP },
    .{ .itemNr = ITM_FP },
    .{ .itemNr = ITM_MAGNITUDE },
    .{ .itemNr = ITM_NEXTP },
    .{ .itemNr = ITM_XFACT },
    .{ .itemNr = ITM_LOGICALNOT },
    .{ .itemNr = CST_01 },
    .{ .itemNr = CST_02 },
    .{ .itemNr = CST_03 },
    .{ .itemNr = CST_04 },
    .{ .itemNr = CST_05 },
    .{ .itemNr = CST_06 },
    .{ .itemNr = CST_07 },
    .{ .itemNr = CST_08 },
    .{ .itemNr = CST_09 },
    .{ .itemNr = CST_10 },
    .{ .itemNr = CST_11 },
    .{ .itemNr = CST_12 },
    .{ .itemNr = CST_13 },
    .{ .itemNr = CST_14 },
    .{ .itemNr = CST_15 },
    .{ .itemNr = CST_16 },
    .{ .itemNr = CST_17 },
    .{ .itemNr = CST_18 },
    .{ .itemNr = CST_19 },
    .{ .itemNr = CST_20 },
    .{ .itemNr = CST_21 },
    .{ .itemNr = CST_22 },
    .{ .itemNr = CST_23 },
    .{ .itemNr = CST_24 },
    .{ .itemNr = CST_25 },
    .{ .itemNr = CST_26 },
    .{ .itemNr = CST_27 },
    .{ .itemNr = CST_28 },
    .{ .itemNr = CST_29 },
    .{ .itemNr = CST_30 },
    .{ .itemNr = CST_31 },
    .{ .itemNr = CST_32 },
    .{ .itemNr = CST_33 },
    .{ .itemNr = CST_34 },
    .{ .itemNr = CST_35 },
    .{ .itemNr = CST_36 },
    .{ .itemNr = CST_37 },
    .{ .itemNr = CST_38 },
    .{ .itemNr = CST_39 },
    .{ .itemNr = CST_40 },
    .{ .itemNr = CST_41 },
    .{ .itemNr = CST_42 },
    .{ .itemNr = CST_43 },
    .{ .itemNr = CST_44 },
    .{ .itemNr = CST_45 },
    .{ .itemNr = CST_46 },
    .{ .itemNr = CST_47 },
    .{ .itemNr = CST_48 },
    .{ .itemNr = CST_49 },
    .{ .itemNr = CST_50 },
    .{ .itemNr = CST_51 },
    .{ .itemNr = CST_52 },
    .{ .itemNr = CST_53 },
    .{ .itemNr = CST_54 },
    .{ .itemNr = CST_55 },
    .{ .itemNr = CST_56 },
    .{ .itemNr = CST_57 },
    .{ .itemNr = CST_58 },
    .{ .itemNr = CST_59 },
    .{ .itemNr = CST_60 },
    .{ .itemNr = CST_61 },
    .{ .itemNr = CST_62 },
    .{ .itemNr = CST_63 },
    .{ .itemNr = CST_64 },
    .{ .itemNr = CST_65 },
    .{ .itemNr = CST_66 },
    .{ .itemNr = CST_67 },
    .{ .itemNr = CST_68 },
    .{ .itemNr = CST_69 },
    .{ .itemNr = CST_70 },
    .{ .itemNr = CST_71 },
    .{ .itemNr = CST_72 },
    .{ .itemNr = CST_73 },
    .{ .itemNr = CST_74 },
    .{ .itemNr = CST_75 },
    .{ .itemNr = CST_76 },
    .{ .itemNr = CST_77 },
    .{ .itemNr = CST_78 },
    .{ .itemNr = CST_79 },
    .{ .itemNr = CST_80 },
    .{ .itemNr = CST_81 },
    .{ .itemNr = CST_82 },
    .{ .itemNr = CST_83 },
    .{ .itemNr = CST_84 },
    .{ .itemNr = ITM_NSIGMA },
    .{ .itemNr = ITM_SIGMAx },
    .{ .itemNr = ITM_SIGMAy },
    .{ .itemNr = ITM_SIGMAx2 },
    .{ .itemNr = ITM_SIGMAx2y },
    .{ .itemNr = ITM_SIGMAy2 },
    .{ .itemNr = ITM_SIGMAxy },
    .{ .itemNr = ITM_SIGMAlnxy },
    .{ .itemNr = ITM_SIGMAlnx },
    .{ .itemNr = ITM_SIGMAln2x },
    .{ .itemNr = ITM_SIGMAylnx },
    .{ .itemNr = ITM_SIGMAlny },
    .{ .itemNr = ITM_SIGMAln2y },
    .{ .itemNr = ITM_SIGMAxlny },
    .{ .itemNr = ITM_SIGMAx2lny },
    .{ .itemNr = ITM_SIGMAlnyonx },
    .{ .itemNr = ITM_SIGMAx2ony },
    .{ .itemNr = ITM_SIGMA1onx },
    .{ .itemNr = ITM_SIGMA1onx2 },
    .{ .itemNr = ITM_SIGMAxony },
    .{ .itemNr = ITM_SIGMA1ony },
    .{ .itemNr = ITM_SIGMA1ony2 },
    .{ .itemNr = ITM_SIGMAx3 },
    .{ .itemNr = ITM_SIGMAx4 },
    .{ .itemNr = ITM_BATT },
    .{ .itemNr = ITM_BN },
    .{ .itemNr = ITM_BNS },
    .{ .itemNr = ITM_CONJ },
    .{ .itemNr = ITM_CORR },
    .{ .itemNr = ITM_COV },
    .{ .itemNr = ITM_BESTFQ },
    .{ .itemNr = ITM_DAY },
    .{ .itemNr = ITM_DtoJ },
    .{ .itemNr = ITM_DTtoJ },
    .{ .itemNr = ITM_ERF },
    .{ .itemNr = ITM_ERFC },
    .{ .itemNr = ITM_EXPT },
    .{ .itemNr = ITM_FIB },
    .{ .itemNr = ITM_DISK },
    .{ .itemNr = ITM_GD },
    .{ .itemNr = ITM_GDM1 },
    .{ .itemNr = ITM_IM },
    .{ .itemNr = ITM_JtoDT },
    .{ .itemNr = ITM_LASTX },
    .{ .itemNr = ITM_LNGAMMA },
    .{ .itemNr = ITM_LocRQ },
    .{ .itemNr = ITM_MANT },
    .{ .itemNr = ITM_MEM },
    .{ .itemNr = ITM_MONTH },
    .{ .itemNr = ITM_sincpi },
    .{ .itemNr = ITM_RAN },
    .{ .itemNr = ITM_RE },
    .{ .itemNr = ITM_REexIM },
    .{ .itemNr = ITM_GET_RM },
    .{ .itemNr = ITM_EX1 },
    .{ .itemNr = ITM_ROUNDI2 },
    .{ .itemNr = ITM_SETSIG2 },
    .{ .itemNr = ITM_SIGN },
    .{ .itemNr = ITM_GET_ADM },
    .{ .itemNr = ITM_GET_ISM },
    .{ .itemNr = ITM_GET_REALDF },
    .{ .itemNr = ITM_GET_NDEC },
    .{ .itemNr = ITM_GET_DMX },
    .{ .itemNr = ITM_SMW },
    .{ .itemNr = ITM_SSIZE },
    .{ .itemNr = ITM_LN1X },
    .{ .itemNr = ITM_SW },
    .{ .itemNr = ITM_SXY },
    .{ .itemNr = ITM_TICKS },
    .{ .itemNr = ITM_UNITV },
    .{ .itemNr = ITM_WDAY },
    .{ .itemNr = ITM_WM },
    .{ .itemNr = ITM_WP },
    .{ .itemNr = ITM_WM1 },
    .{ .itemNr = ITM_XW },
    .{ .itemNr = ITM_YEAR },
    .{ .itemNr = ITM_GAMMAX },
    .{ .itemNr = ITM_zetaX },
    .{ .itemNr = ITM_STDDEVPOP },
    .{ .itemNr = ITM_M1X },
    .{ .itemNr = ITM_HRtoTM },
    .{ .itemNr = ITM_toREAL },
    .{ .itemNr = ITM_Kk },
    .{ .itemNr = ITM_Ek },
    .{ .itemNr = ITM_ARG },
    .{ .itemNr = ITM_op_a },
    .{ .itemNr = ITM_op_a2 },
    .{ .itemNr = ITM_EE_EXP_TH },
};

const NumMsg = [_]numStr{
    .{ .noStr = "^0".* ++ [_]u8{0} }, .{ .noStr = "^1".* ++ [_]u8{0} }, .{ .noStr = "^2".* ++ [_]u8{0} }, .{ .noStr = "^3".* ++ [_]u8{0} }, .{ .noStr = "^4".* ++ [_]u8{0} },
    .{ .noStr = "^5".* ++ [_]u8{0} }, .{ .noStr = "^6".* ++ [_]u8{0} }, .{ .noStr = "^7".* ++ [_]u8{0} }, .{ .noStr = "^8".* ++ [_]u8{0} }, .{ .noStr = "^9".* ++ [_]u8{0} },
};

const bugScreenNoParam = "In function addItemToBuffer:item should not be NOPARAM=7654!";

// fType 3 is the conversion table, which conversionUnits.c holds.
fn isFunctionInMim(com: i16, fType: u8) bool {
    const table: []const fInMim_t = switch (fType) {
        0 => &MimFunctionsType0,
        1 => &MimFunctionsType1,
        2 => &MimFunctionsType2,
        else => &frontier_conversion_units.MimFunctionsType3Conv,
    };
    for (table) |entry| {
        if (com == @as(i16, @bitCast(entry.itemNr))) {
            return true;
        }
    }
    return false;
}

// ---------------------------------------------------------------------------
// fnAim
// ---------------------------------------------------------------------------
pub export fn fnAim(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (calcMode != CM_AIM and calcMode != CM_EIM and (calcMode != CM_PEM or tam.mode != 0 or getSystemFlag(FLAG_ALPHA) == 0)) {
        resetShiftState();
        displayAIMbufferoffset = 0;
        T_cursorPos = 0;
        aimBuffer[0] = 0;
    }
    frontier_screen.setLastintegerBasetoZero();
    frontier_calc_mode.calcModeAim(NOPARAM);
    if (programRunStop != PGM_RUNNING) {
        entryStatus |= 0x01;
        setSystemFlag(FLAG_ALPIN);
    }
}

// ---------------------------------------------------------------------------
// convertItemToSubOrSup
// ---------------------------------------------------------------------------
pub export fn convertItemToSubOrSup(item: u16, subOrSup: i16) callconv(.c) u16 {
    const it: i16 = @bitCast(item);
    if (subOrSup == NC_SUBSCRIPT) {
        nextChar = NC_NORMAL;
        if (item >= ITM_0 and item <= ITM_9) return @bitCast(it + ITM_SUB_0 - ITM_0) else if (item >= ITM_a and item <= ITM_z) return @bitCast(it + ITM_SUB_a - ITM_a) else if (item >= ITM_A and item <= ITM_Z) return @bitCast(it + ITM_SUB_A - ITM_A) else {
            return switch (item) {
                ITM_alpha => ITM_SUB_alpha,
                ITM_delta => ITM_SUB_delta,
                ITM_mu => ITM_SUB_mu,
                ITM_pi => ITM_SUB_pi,
                ITM_SUN => ITM_SUB_SUN,
                ITM_INFINITY => ITM_SUB_INFINITY,
                ITM_PLUS => ITM_SUB_PLUS,
                ITM_MINUS => ITM_SUB_MINUS,
                else => item,
            };
        }
    } else if (subOrSup == NC_SUPERSCRIPT) {
        nextChar = NC_NORMAL;
        if (item >= ITM_0 and item <= ITM_9) return @bitCast(it + ITM_SUP_0 - ITM_0) else if (item >= ITM_a and item <= ITM_z) return @bitCast(it + ITM_SUP_a - ITM_a) else if (item >= ITM_A and item <= ITM_Z) return @bitCast(it + ITM_SUP_A - ITM_A) else {
            return switch (item) {
                ITM_INFINITY => ITM_SUP_INFINITY,
                ITM_PLUS => ITM_SUP_PLUS,
                ITM_MINUS => ITM_SUP_MINUS,
                ITM_pi => ITM_SUP_pi,
                ITM_SLASH => ITM_SUP_SLASH,
                ITM_PERIOD => ITM_SUP_DOT,
                ITM_COMMA => ITM_SUP_COMMA,
                else => item,
            };
        }
    }
    return item;
}

// ---------------------------------------------------------------------------
// findFirstItem
// ---------------------------------------------------------------------------
pub export fn findFirstItem(twoLetters: [*c]const u8) callconv(.c) i32 {
    const menuId: i16 = softmenuStack[0].softmenuId;

    if (menuId < NUMBER_OF_DYNAMIC_SOFTMENUS) { // Dynamic softmenu
        var firstString: [*c]u8 = undefined;
        var middleString: [*c]u8 = undefined;
        var first: i16 = 0;
        var middle: i16 = undefined;
        var last: i16 = undefined;

        firstString = dynamicSoftmenu[@intCast(menuId)].menuContent;
        last = dynamicSoftmenu[@intCast(menuId)].numItems - 1;

        middle = first + @divTrunc(last - first, 2);
        middleString = frontier_softmenus.getNthString(dynamicSoftmenu[@intCast(menuId)].menuContent, middle);

        while (first + 1 < last) {
            if (frontier_sort.compareString(twoLetters, middleString, CMP_CLEANED_STRING_ONLY) <= 0) {
                last = middle;
            } else {
                first = middle;
                firstString = middleString;
            }
            middle = first + @divTrunc(last - first, 2);
            middleString = frontier_softmenus.getNthString(dynamicSoftmenu[@intCast(menuId)].menuContent, middle);
        }

        if (frontier_sort.compareString(twoLetters, firstString, CMP_CLEANED_STRING_ONLY) <= 0) {
            return first;
        } else {
            return last;
        }
    } else { // Static softmenu
        var first: [*c]const i16 = softmenu[@intCast(menuId)].softkeyItem;
        var last: [*c]const i16 = first + @as(usize, @intCast(softmenu[@intCast(menuId)].numItems - 1));
        while (last[0] == ITM_NULL) {
            last -= 1;
        }
        var middle: [*c]const i16 = first + ((last - first) / 2);
        while ((last - first) > 1) {
            if (frontier_sort.compareString(twoLetters, &indexOfItems[@intCast(absInt(middle[0]))].itemCatalogName, CMP_CLEANED_STRING_ONLY) <= 0) {
                last = middle;
            } else {
                first = middle;
            }
            middle = first + ((last - first) / 2);
        }
        if (frontier_sort.compareString(twoLetters, &indexOfItems[@intCast(absInt(first[0]))].itemCatalogName, CMP_CLEANED_STRING_ONLY) <= 0) {
            return @intCast(first - softmenu[@intCast(menuId)].softkeyItem);
        } else {
            return @intCast(last - softmenu[@intCast(menuId)].softkeyItem);
        }
    }
}

// ---------------------------------------------------------------------------
// resetAlphaSelectionBuffer
// ---------------------------------------------------------------------------
pub export fn resetAlphaSelectionBuffer() callconv(.c) void {
    asmBuffer[0] = 0;
    fnKeyInCatalog = 0;
    frontier_timer.fnTimerStop(TO_ASM_ACTIVE);
    frontier_status_bar.kill_ASB_icon();
}

// ---------------------------------------------------------------------------
// validShortIntegerInX
// ---------------------------------------------------------------------------
pub export fn validShortIntegerInX() callconv(.c) bool_t {
    const lg: u16 = @intCast(strlen(aimBuffer));
    var posHash: u16 = lg;
    var i: u16 = undefined;
    if (nimNumberPart == NP_INT_BASE) {
        return 1;
    } else {
        // C computes the bound as int, so a buffer of 0 or 1 characters gives a
        // bound below the start index and the loop does not run.
        const upper: u16 = if (lg >= 2) lg - 1 else 0;
        i = 1;
        while (i < upper) : (i += 1) { // do not check the # on the very begin or very end
            if (aimBuffer[i] == '#') {
                posHash = i;
            }
        }
    }
    i = 0;
    while (i < posHash) : (i += 1) {
        const c = aimBuffer[i];
        if (c == 'e' or c == 'i' or c == ',' or c == '.') {
            return 0;
        }
    }
    var base: u8 = 0;
    // Same promotion: `aimBuffer[lg - 2]` with lg < 2 indexes before the buffer
    // in the C. A buffer that short cannot carry the base suffix these two tests
    // look for, so the length is required up front instead.
    if (lg >= 2 and aimBuffer[lg - 2] == '#' and (aimBuffer[lg - 1] >= '0' and aimBuffer[lg - 1] <= '9')) {
        base = aimBuffer[lg - 1];
    }
    if (lg >= 3 and aimBuffer[lg - 3] == '#' and (aimBuffer[lg - 2] >= '0' and aimBuffer[lg - 2] <= '1') and (aimBuffer[lg - 1] >= '0' and aimBuffer[lg - 1] <= '9')) {
        base = aimBuffer[lg - 2] *% 10 +% aimBuffer[lg - 1];
    }
    if (base < 2 or base > 16) {
        return 0;
    }
    var start: u16 = 0;
    if (aimBuffer[0] == '-' or aimBuffer[0] == '+' or aimBuffer[0] == ' ') {
        start += 1;
    }
    i = start;
    while (i < posHash) : (i += 1) {
        if (!(aimBuffer[i] >= '0' and aimBuffer[i] <= '9') and !(aimBuffer[i] >= 'A' and aimBuffer[i] <= 'F')) {
            return 0;
        }
    }
    return if (posHash > 0) 1 else 0;
}

// ---------------------------------------------------------------------------
// checkShortIntegerDigits
// ---------------------------------------------------------------------------
// Every digit of the short integer typed as digits#base is below the base; when
// one is not, the error is displayed and the answer is false.
pub export fn checkShortIntegerDigits(buffer: [*c]u8) callconv(.c) bool {
    const numBuffer: [*c]u8 = if (buffer[0] == '+') buffer + 1 else buffer;
    var posHash: i16 = 0;
    while (numBuffer[@intCast(posHash)] != '#') : (posHash += 1) {}
    const base: u8 = @truncate(@as(c_uint, @bitCast(atoi(numBuffer + @as(usize, @intCast(posHash)) + 1))));
    var i: i16 = if (numBuffer[0] == '-') 1 else 0;
    while (i < posHash) : (i += 1) {
        const c: i32 = numBuffer[@intCast(i)];
        const digit: i32 = if (c > '9') c - 'A' + 10 else c - '0';
        if (digit >= base) {
            frontier_error.displayCalcErrorMessage(ERROR_INVALID_INTEGER_INPUT, ERR_REGISTER_LINE);
            if (comptime extra_info) {
                abi.fmtBufZ(errorMessage[0..ERROR_MESSAGE_LENGTH], "digit {c} is not allowed in base {d}!", .{ numBuffer[@intCast(i)], base });
                moreInfoOnError("In function checkShortIntegerDigits:", errorMessage, null, null);
            }
            return false;
        }
    }
    return true;
}

// ---------------------------------------------------------------------------
// The number being entered: its parts, its unit and its value
// ---------------------------------------------------------------------------
// The complex number being entered is polar: i∠ was pressed, or POLAR is set and
// i was not.
pub export fn nimPolarEntry() callconv(.c) bool {
    return (getSystemFlag(FLAG_POLAR) != 0 and temporaryFlagRect == 0) or temporaryFlagPolar != 0;
}

// The imaginary part or the angle of a complex number is being entered.
pub export fn nimComplexPart() callconv(.c) bool {
    return switch (nimNumberPart) {
        NP_COMPLEX_INT_PART, NP_COMPLEX_FLOAT_PART, NP_COMPLEX_EXPONENT, NP_COMPLEX_FRACTION_DENOMINATOR, NP_COMPLEX_HP32SII_DENOMINATOR => true,
        else => false,
    };
}

fn nimPartIsFraction(part: u8) bool {
    return part == NP_FRACTION_DENOMINATOR or part == NP_HP32SII_DENOMINATOR or part == NP_COMPLEX_FRACTION_DENOMINATOR or part == NP_COMPLEX_HP32SII_DENOMINATOR;
}

// π right after i is the imaginary part: its digits end the number, which the
// caller closes.
pub export fn nimPiAfterI() callconv(.c) bool {
    if (nimNumberPart == NP_COMPLEX_INT_PART and aimBuffer[strlen(aimBuffer) - 1] == 'i') {
        _ = strcat(aimBuffer, "3.141592653589793238462643383279503");
        return true;
    }
    return false;
}

// A real number or a fraction is being entered.
pub export fn nimRealOrFractionPart() callconv(.c) bool {
    return switch (nimNumberPart) {
        NP_INT_10, NP_REAL_FLOAT_PART, NP_REAL_EXPONENT, NP_FRACTION_DENOMINATOR, NP_HP32SII_DENOMINATOR => true,
        else => false,
    };
}

// NIMDRG is set and the number being entered closes as a real or a complex
// number, which takes the unit DRG chooses. A real number takes it through the
// tag of the real liftStack made X for the entry.
pub export fn nimDrgChoosesUnit() callconv(.c) bool {
    if ((drgConfig & (1 << DRG_NIM_BIT)) == 0) {
        return false;
    }
    if (nimComplexPart()) {
        return true;
    }
    return nimRealOrFractionPart() and calcMode == CM_NIM and lastIntegerBase == 0 and Input_Default != ID_CPXDP;
}

// The number being entered has the unit D.MS, so the digits after the radix mark
// are minutes and seconds.
fn nimDmsDigits() bool {
    if (nimComplexPart()) {
        return nimPolarAngularMode == amDMS;
    }
    if (calcMode == CM_PEM) {
        return editingLiteralType == STRING_ANGLE_DMS;
    }
    return calcMode == CM_NIM and getRegisterAngularMode(REGISTER_X) == amDMS;
}

// The digits of a D.MS number with an exponent, without its radix mark, into
// digits; integerDigits receives how many of them stand before the radix mark.
// Returns how many are degrees once the exponent moves the radix mark, which can
// fall below 0 or above their count. The C narrows that int sum to int16_t.
fn nimDmsExponentDigits(number_in: [*c]const u8, digits: [*c]u8, integerDigits: *i16) i16 {
    var number = number_in;
    var count: i16 = 0;
    integerDigits.* = -1;
    while (number[0] != 'e' and number[0] != 0) : (number += 1) {
        if (number[0] == '.') {
            integerDigits.* = count;
        } else {
            digits[@intCast(count)] = number[0];
            count += 1;
        }
    }
    digits[@intCast(count)] = 0;
    if (integerDigits.* < 0) {
        integerDigits.* = count;
    }
    const shift: c_int = if (number[0] == 'e') atoi(number + 1) else 0;
    return @truncate(@as(c_int, integerDigits.*) + shift);
}

// The count-th D.MS digit after the degree mark, then the minute mark after the
// second digit and, with radixMark, the radix mark after the fourth.
fn nimDmsDigit(text_in: [*c]u8, digit: u8, count: i16, radixMark: bool) [*c]u8 {
    var text = text_in;
    text[0] = digit;
    text += 1;
    if (count == 2) {
        text = stringCopy(text, STD_RIGHT_SINGLE_QUOTE);
    } else if (count == 4 and radixMark) {
        text[0] = radix34MarkByte0();
        text += 1;
        if (radix34MarkByte1() != 1) { // a radix mark of two bytes
            text[0] = radix34MarkByte1();
            text += 1;
        }
    }
    return text;
}

// nimDmsMark's buffer for an entry with an exponent: the degree mark, up to 34
// digits and three marks.
var nimDmsTail: [64]u8 = undefined;

// The marks after the cursor in a D.MS entry: all three with no radix mark,
// minutes and seconds until two digits follow it, then seconds. With an exponent
// the digits it moves past the radix mark are shown as the minutes and seconds
// they become.
pub export fn nimDmsMark() callconv(.c) [*c]const u8 {
    const marks: [*c]const u8 = STD_DEGREE ++ STD_RIGHT_SINGLE_QUOTE ++ STD_RIGHT_DOUBLE_QUOTE;
    if (nimNumberPart == NP_INT_10 or nimNumberPart == NP_COMPLEX_INT_PART) {
        return marks;
    }
    if (nimNumberPart == NP_REAL_EXPONENT or nimNumberPart == NP_COMPLEX_EXPONENT) {
        var digits: [48]u8 = undefined;
        var integerDigits: i16 = undefined;
        const number: [*c]const u8 = if (nimComplexPart()) aimBuffer + @as(usize, @intCast(imaginaryMantissaSignLocation + 2)) else aimBuffer + 1;
        const degrees = nimDmsExponentDigits(number, &digits, &integerDigits);
        const count: i16 = @intCast(strlen(&digits));
        var shown: i16 = 0;
        var t: [*c]u8 = stringCopy(&nimDmsTail, STD_DEGREE);
        // The zeros the exponent puts in front fill the minutes and seconds only.
        var i: i16 = degrees;
        while (i < count and (shown < 4 or i >= 0)) : ({
            i += 1;
            shown += 1;
        }) {
            // The radix mark only when a digit follows it.
            t = nimDmsDigit(t, if (i < 0) '0' else digits[@intCast(i)], shown + 1, i + 1 < count and i + 1 >= 0);
        }
        if (shown == 1 or shown == 3) { // a lone digit is the tens of the minutes or of the seconds
            t[0] = '0';
            t += 1;
        }
        if (shown < 2) {
            t = stringCopy(t, STD_RIGHT_SINGLE_QUOTE);
        }
        _ = strcpy(t, STD_RIGHT_DOUBLE_QUOTE);
        return &nimDmsTail;
    }
    if (nimNumberPart == NP_REAL_FLOAT_PART or nimNumberPart == NP_COMPLEX_FLOAT_PART or nimPartIsFraction(nimNumberPart)) {
        // 5/3 has no gap, so its bar is the degree mark.
        const barIsMark = nimNumberPart == NP_HP32SII_DENOMINATOR or nimNumberPart == NP_COMPLEX_HP32SII_DENOMINATOR;
        var digits: i16 = 0;
        var c: [*c]const u8 = aimBuffer + strlen(aimBuffer) - 1;
        while (c[0] != '.' and c[0] != ' ' and (c[0] != '/' or !barIsMark)) : (c -= 1) {
            if (c[0] != '/') {
                digits += 1;
            }
        }
        if (digits < 2) { // fewer than two digits after the degree mark
            return marks + 2;
        }
    }
    return marks + 4;
}

// The buffer of a new number: 1. before an exponent, 0 before a radix mark, and
// nothing before a digit.
pub export fn nimStartNumber(item: i16) callconv(.c) void {
    switch (item) {
        ITM_EXPONENT => {
            aimBuffer[0] = '+';
            aimBuffer[1] = '1';
            aimBuffer[2] = '.';
            aimBuffer[3] = 0;
            nimNumberPart = NP_REAL_FLOAT_PART;
        },
        ITM_PERIOD => {
            aimBuffer[0] = '+';
            aimBuffer[1] = '0';
            aimBuffer[2] = 0;
            nimNumberPart = NP_INT_10;
        },
        ITM_0, ITM_1, ITM_2, ITM_3, ITM_4, ITM_5, ITM_6, ITM_7, ITM_8, ITM_9, ITM_A, ITM_B, ITM_C, ITM_D, ITM_E, ITM_F => {
            aimBuffer[0] = '+';
            aimBuffer[1] = 0;
            nimNumberPart = NP_EMPTY;
        },
        else => {},
    }
}

// The text after the cursor: the base of an integer, or the denominator a
// fraction takes when none is typed.
pub export fn nimHint(hint: [*c]u8) callconv(.c) void {
    hint[0] = 0;
    if (lastIntegerBase != 0) {
        hint[0] = '#';
        if (lastIntegerBase > 9) {
            hint[1] = '1';
            hint[2] = @intCast('0' + (lastIntegerBase - 10));
            hint[3] = 0;
        } else {
            hint[1] = @intCast('0' + lastIntegerBase);
            hint[2] = 0;
        }
    } else if (aimBuffer[0] != 0 and aimBuffer[strlen(aimBuffer) - 1] == '/' and !(option_drg_cfg and nimDmsDigits())) { // a bar in a D.MS entry makes no fraction
        frontier_display.subNumberToDisplayString(@bitCast(lastDenominator), hint, null);
    }
}

// ---------------------------------------------------------------------------
// closeAim
// ---------------------------------------------------------------------------
pub export fn closeAim() callconv(.c) void {
    frontier_calc_mode.calcModeNormal();
    frontier_softmenus.popSoftmenu();

    if (aimBuffer[0] == 0) {
        undo();
    } else {
        const len: i16 = @intCast(stringByteLength(aimBuffer) + 1);
        _ = reallocateRegister(REGISTER_X, dtString, toBlocks(@intCast(len)), amNone);
        _ = frontier_char_string.xcopy(regString(REGISTER_X), aimBuffer, @intCast(len));
        aimBuffer[0] = 0;
        setSystemFlag(FLAG_ASLIFT);
    }
}

// ---------------------------------------------------------------------------
// insertAlphaCharacter
// ---------------------------------------------------------------------------
pub export fn insertAlphaCharacter(item: u16, currentCursor: *i16) callconv(.c) void {
    // USE_ITALIC_CONSTANT is not defined -> the ITM_ALOG_SYMBOL branch is dead.
    const addChar: [*c]const u8 = if (item == ITM_PAIR_OF_PARENTHESES) "()" else if (item == ITM_VERTICAL_BAR) "||" else if (item == ITM_ROOT_SIGN) STD_SQUARE_ROOT ++ "()" else &indexOfItems[item].itemSoftmenuName;
    var aimCursorPos: [*c]u8 = aimBuffer;
    var aimBottomPos: [*c]u8 = aimBuffer + @as(usize, @intCast(stringByteLength(aimBuffer)));
    const itemLen: u32 = @intCast(stringByteLength(addChar));
    var i: i32 = 0;
    while (i < currentCursor.*) : (i += 1) {
        aimCursorPos += if ((aimCursorPos[0] & 0x80) != 0) @as(usize, 2) else 1;
    }
    while (@intFromPtr(aimBottomPos) >= @intFromPtr(aimCursorPos)) : (aimBottomPos -= 1) {
        (aimBottomPos + itemLen)[0] = aimBottomPos[0];
    }
    _ = frontier_char_string.xcopy(aimCursorPos, addChar, itemLen);
    switch (item) {
        ITM_ROOT_SIGN => {
            currentCursor.* += 2;
        },
        ITM_PAIR_OF_PARENTHESES, ITM_VERTICAL_BAR => {
            currentCursor.* += 1;
        },
        else => {
            currentCursor.* += @intCast(frontier_char_string.stringGlyphLength(&indexOfItems[item].itemSoftmenuName));
        },
    }
}

// ---------------------------------------------------------------------------
// deleteAlphaCharacter
// ---------------------------------------------------------------------------
pub export fn deleteAlphaCharacter(currentCursor: *i16) callconv(.c) void {
    var dstPos: [*c]u8 = aimBuffer;
    var srcPos: [*c]u8 = undefined;
    const lstPos: [*c]u8 = aimBuffer + @as(usize, @intCast(frontier_char_string.stringNextGlyph(aimBuffer, frontier_char_string.stringLastGlyph(aimBuffer))));
    currentCursor.* -= 1;
    var i: i16 = 0;
    while (i < currentCursor.*) : (i += 1) {
        dstPos += if ((dstPos[0] & 0x80) != 0) @as(usize, 2) else 1;
    }
    srcPos = dstPos + (if ((dstPos[0] & 0x80) != 0) @as(usize, 2) else 1);
    while (@intFromPtr(srcPos) <= @intFromPtr(lstPos)) {
        dstPos[0] = srcPos[0];
        dstPos += 1;
        srcPos += 1;
    }
}

// ---------------------------------------------------------------------------
// fnAlphaCursorLeft / Right / Home / End
// ---------------------------------------------------------------------------
pub export fn fnAlphaCursorLeft(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (alphaCursor > 0) {
        alphaCursor -= 1;
    }
}

pub export fn fnAlphaCursorRight(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    const glyphLen: u16 = @truncate(@as(u32, @bitCast(frontier_char_string.stringGlyphLength(aimBuffer))));
    if (@as(i32, alphaCursor) < @as(i32, glyphLen)) {
        alphaCursor += 1;
    }
}

pub export fn fnAlphaCursorHome(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    alphaCursor = 0;
}

pub export fn fnAlphaCursorEnd(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    alphaCursor = @bitCast(@as(u16, @truncate(@as(u32, @bitCast(frontier_char_string.stringGlyphLength(aimBuffer))))));
}

// ---------------------------------------------------------------------------
// insertGapIP / insertGapFP (file-static)
//   GROUPLEFT_DISABLED  = (GROUPWIDTH_LEFT == 0 || gapItemLeft == 0)
//   GROUPRIGHT_DISABLED = (GROUPWIDTH_RIGHT == 0 || gapItemRight == 0)
//   GROUPWIDTH_LEFT  = grpGroupingLeft ; GROUPWIDTH_RIGHT = grpGroupingRight
//   SEPARATOR_LEFT[1] / SEPARATOR_RIGHT[1] reproduced via separatorByte1Left/Right.
// ---------------------------------------------------------------------------
fn separatorLeftByte1() u8 {
    return separatorLeft().b1;
}
fn separatorRightByte1() u8 {
    return separatorRight().b1;
}
const TwoBytes = struct { b0: u8, b1: u8 };
// The first two bytes of a separator string from getGapChar1Left/Right/Radix
// (byte[1] == 1 means "single-byte separator").
fn twoBytes(s: [*c]const u8) TwoBytes {
    return .{ .b0 = s[0], .b1 = s[1] };
}

fn insertGapIP(displayBuffer: [*c]u8, numDigits: i16, nth: i16) i16 {
    const gw: i16 = grpGroupingLeft;
    const disabled = gw == 0 or gapItemLeft == 0;
    return gap_insert.insertGapIP(displayBuffer, numDigits, nth, gw, disabled, separatorLeftByte1() == 1);
}

fn insertGapFP(displayBuffer: [*c]u8, numDigits: i16, nth: i16) i16 {
    const gw: i16 = grpGroupingRight;
    const disabled = gw == 0 or gapItemRight == 0;
    return gap_insert.insertGapFP(displayBuffer, numDigits, nth, gw, disabled, separatorRightByte1() == 1);
}

// ---------------------------------------------------------------------------
// nimBufferToDisplayBuffer
// ---------------------------------------------------------------------------
pub export fn nimBufferToDisplayBuffer(buffer_in: [*c]const u8, displayBuffer_in: [*c]u8) callconv(.c) void {
    var buffer = buffer_in;
    var displayBuffer = displayBuffer_in;
    var numDigits: i16 = undefined;
    var source: i16 = undefined;
    var dest: i16 = undefined;

    if (buffer[0] == '-') {
        displayBuffer[0] = '-';
        displayBuffer += 1;
    }
    buffer += 1;

    // A D.MS mantissa with an exponent shows the degrees the exponent leaves, and
    // nimDmsMark the minutes and seconds: up to 34 digits, the radix mark and the
    // 'e' that ends them.
    var degrees: [52]u8 = undefined;
    if (option_drg_cfg and (nimNumberPart == NP_REAL_EXPONENT or nimNumberPart == NP_COMPLEX_EXPONENT) and nimDmsDigits()) {
        var digits: [48]u8 = undefined;
        var integerDigits: i16 = undefined;
        const whole = nimDmsExponentDigits(buffer, &digits, &integerDigits);
        const count: i16 = @intCast(strlen(&digits));
        if (whole < count) {
            var d: usize = 0;
            if (whole <= 0) {
                degrees[d] = '0';
                d += 1;
            } else if (whole <= integerDigits) {
                // The digits after the degrees become zeros, so the mantissa times
                // the power of ten is the degrees.
                const w: usize = @intCast(whole);
                const n: usize = @intCast(integerDigits);
                @memcpy(degrees[0..w], digits[0..w]);
                @memset(degrees[w..n], '0');
                d = n;
            } else {
                const w: usize = @intCast(whole);
                const n: usize = @intCast(integerDigits);
                @memcpy(degrees[0..n], digits[0..n]);
                degrees[n] = '.';
                @memcpy(degrees[n + 1 .. w + 1], digits[n..w]);
                d = w + 1;
            }
            degrees[d] = 'e';
            degrees[d + 1] = 0;
            buffer = &degrees;
        }
    }

    const GROUPWIDTH_LEFTM: u8 = grpGroupingLeft;
    switch (nimNumberPart) {
        NP_INT_10, NP_INT_BASE => {
            switch (lastIntegerBase) {
                0 => grpGroupingLeft = GROUPWIDTH_LEFTM,
                2 => grpGroupingLeft = grpGroupingBin,
                3 => grpGroupingLeft = 3,
                4 => grpGroupingLeft = 2,
                5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 => grpGroupingLeft = 3,
                16 => grpGroupingLeft = grpGroupingHex,
                else => {},
            }
        },
        NP_INT_16 => {
            grpGroupingLeft = grpGroupingHex;
        },
        else => {},
    }

    numDigits = 0;
    while (buffer[@intCast(numDigits)] != 0 and buffer[@intCast(numDigits)] != 'e' and buffer[@intCast(numDigits)] != '.' and buffer[@intCast(numDigits)] != ' ' and buffer[@intCast(numDigits)] != '/' and buffer[@intCast(numDigits)] != '#' and buffer[@intCast(numDigits)] != '+' and buffer[@intCast(numDigits)] != '-') : (numDigits += 1) {}

    source = 0;
    dest = 0;
    while (source < numDigits) : (source += 1) {
        displayBuffer[@intCast(dest)] = buffer[@intCast(source)];
        dest += 1;
        dest += insertGapIP(displayBuffer + @as(usize, @intCast(dest)), numDigits, source);
    }

    grpGroupingLeft = GROUPWIDTH_LEFTM;
    displayBuffer[@intCast(dest)] = 0;

    // D.MS digits show their marks as typed and no gaps; in a fraction the gap, or
    // a bar with no gap before it, is the degree mark.
    const dms = option_drg_cfg and (nimNumberPart == NP_REAL_FLOAT_PART or nimNumberPart == NP_COMPLEX_FLOAT_PART or nimPartIsFraction(nimNumberPart)) and nimDmsDigits();
    var dmsDigits: i16 = 0;
    if (nimNumberPart == NP_REAL_FLOAT_PART or nimNumberPart == NP_REAL_EXPONENT or nimNumberPart == NP_COMPLEX_FLOAT_PART or nimNumberPart == NP_COMPLEX_EXPONENT or dms) {
        if (dms) {
            _ = strcpy(displayBuffer + @as(usize, @intCast(dest)), STD_DEGREE);
            dest += 2;
        } else {
            displayBuffer[@intCast(dest)] = '.';
            dest += 1;
        }

        buffer += @as(usize, @intCast(source)) + 1;

        numDigits = 0;
        while (buffer[@intCast(numDigits)] != 0 and buffer[@intCast(numDigits)] != 'e' and buffer[@intCast(numDigits)] != '+' and buffer[@intCast(numDigits)] != '-') : (numDigits += 1) {}

        source = 0;
        while (source < numDigits) : (source += 1) {
            if (dms) {
                if (buffer[@intCast(source)] != '/') { // a later bar is no D.MS digit
                    dmsDigits += 1;
                    dest = @intCast(nimDmsDigit(displayBuffer + @as(usize, @intCast(dest)), buffer[@intCast(source)], dmsDigits, true) - displayBuffer);
                }
                continue;
            }
            displayBuffer[@intCast(dest)] = buffer[@intCast(source)];
            dest += 1;
            dest += insertGapFP(displayBuffer + @as(usize, @intCast(dest)), numDigits, source);
        }

        displayBuffer[@intCast(dest)] = 0;
    } else if (nimNumberPart == NP_INT_BASE) {
        _ = strcpy(displayBuffer + @as(usize, @intCast(dest)), buffer + @as(usize, @intCast(numDigits)));
    }
}

// ---------------------------------------------------------------------------
// nimFractionToDisplayBuffer
// ---------------------------------------------------------------------------
pub export fn nimFractionToDisplayBuffer(buffer: [*c]const u8, displayBuffer: [*c]u8) callconv(.c) void {
    var index: i16 = undefined;

    // A D.MS entry shows the fraction as its digits; another unit shows the
    // fraction again.
    if (option_drg_cfg and nimDmsDigits()) {
        nimBufferToDisplayBuffer(buffer, displayBuffer);
        return;
    }

    if (nimNumberPart == NP_FRACTION_DENOMINATOR or nimNumberPart == NP_COMPLEX_FRACTION_DENOMINATOR) {
        nimBufferToDisplayBuffer(buffer, displayBuffer);
        _ = strcat(displayBuffer, STD_SPACE_4_PER_EM);
        index = 2;
        while (buffer[@intCast(index)] != ' ') : (index += 1) {}
    } else {
        if (buffer[0] == '-') {
            _ = strcat(displayBuffer, "-");
        }
        index = 0;
    }

    frontier_display.supNumberToDisplayString(toInt32(buffer + @as(usize, @intCast(index)) + 1), displayBuffer + @as(usize, @intCast(stringByteLength(displayBuffer))), null, 1);

    _ = strcat(displayBuffer, "/");

    while (buffer[@intCast(index)] != '/') : (index += 1) {}
    index += 1;
    if (buffer[@intCast(index)] == '+') { // There is an imaginary part
        frontier_display.subNumberToDisplayString(@bitCast(lastDenominator), displayBuffer + @as(usize, @intCast(stringByteLength(displayBuffer))), null);
    } else if (buffer[@intCast(index)] != 0) {
        const denominator: i32 = toInt32(buffer + @as(usize, @intCast(index)));
        frontier_display.subNumberToDisplayString(denominator, displayBuffer + @as(usize, @intCast(stringByteLength(displayBuffer))), null);
        while (buffer[@intCast(index)] >= '0' and buffer[@intCast(index)] <= '9') : (index += 1) {}
        if (buffer[@intCast(index)] == '+') {
            lastDenominator = @bitCast(denominator);
        }
    }
}

// ---------------------------------------------------------------------------
// nimRealToDisplayBuffer
// ---------------------------------------------------------------------------
pub export fn nimRealToDisplayBuffer(buffer: [*c]const u8, exponentLocation: i16, displayBuffer: [*c]u8) callconv(.c) void {
    nimBufferToDisplayBuffer(buffer, displayBuffer);

    if (nimNumberPart == NP_REAL_EXPONENT or nimNumberPart == NP_COMPLEX_EXPONENT) {
        frontier_display.exponentToDisplayString(stringToInt32(buffer + @as(usize, @intCast(exponentLocation))), displayBuffer + @as(usize, @intCast(stringByteLength(displayBuffer))), null, 1);
        if (buffer[@intCast(exponentLocation + 1)] == 0 and buffer[@intCast(exponentLocation)] == '-') {
            _ = strcat(displayBuffer, STD_SUP_MINUS);
        } else if (buffer[@intCast(exponentLocation + 1)] == '0' and buffer[@intCast(exponentLocation)] == '+') {
            _ = strcat(displayBuffer, STD_SUP_0);
        }
    }
}

// ---------------------------------------------------------------------------
// nimFractionToReal34
// ---------------------------------------------------------------------------
pub export fn nimFractionToReal34(source: [*c]u8, dest: *real34_t) callconv(.c) void {
    var i: i16 = undefined;
    var posSpace: i16 = undefined;
    var posSlash: i16 = undefined;
    var lg: i16 = undefined;
    var numer: i32 = undefined;
    var denom: i32 = undefined;
    var temp: real34_t = undefined;

    setSystemFlag(if (getSystemFlag(FLAG_IRFRQ) != 0) FLAG_IRFRAC else FLAG_FRACT);

    lg = @intCast(strlen(source));

    posSpace = 0;
    i = 2;
    while (i < lg) : (i += 1) {
        if (source[@intCast(i)] == ' ') {
            posSpace = i;
            break;
        }
    }

    i = 1;
    while (i < posSpace) : (i += 1) {
        if (source[@intCast(i)] < '0' or source[@intCast(i)] > '9') { // This should never happen
            frontier_error.displayCalcErrorMessage(ERROR_BAD_INPUT, ERR_REGISTER_LINE);
            moreInfoOnErr("In function nimFractionToReal34:", "there is a non numeric character in the integer part of the fraction!");
            return;
        }
    }

    posSlash = 0;
    i = posSpace + 2;
    while (i < lg) : (i += 1) {
        if (source[@intCast(i)] == '/') {
            posSlash = i;
            break;
        }
    }

    i = posSpace + 1;
    while (i < posSlash) : (i += 1) {
        if (source[@intCast(i)] < '0' or source[@intCast(i)] > '9') { // This should never happen
            frontier_error.displayCalcErrorMessage(ERROR_BAD_INPUT, ERR_REGISTER_LINE);
            moreInfoOnErr("In function nimFractionToReal34:", "there is a non numeric character in the numerator part of the fraction!");
            return;
        }
    }

    if (source[@intCast(posSlash + 1)] != 0) {
        i = posSlash + 1;
        while (i < lg) : (i += 1) {
            if (source[@intCast(i)] < '0' or source[@intCast(i)] > '9') {
                frontier_error.displayCalcErrorMessage(ERROR_BAD_INPUT, ERR_REGISTER_LINE);
                moreInfoOnErr("In function nimFractionToReal34:", "there is a non numeric character in the denominator part of the fraction!");
                return;
            }
        }
    }

    if (posSpace != 0) {
        source[@intCast(posSpace)] = 0;
    }
    source[@intCast(posSlash)] = 0;
    numer = toInt32(source + @as(usize, @intCast(posSpace)) + 1);
    if (source[@intCast(posSlash + 1)] == 0) {
        denom = @bitCast(lastDenominator);
    } else {
        denom = toInt32(source + @as(usize, @intCast(posSlash)) + 1);
        if (denom != 0) {
            lastDenominator = @bitCast(denom);
        }
    }

    if (denom == 0 and getSystemFlag(FLAG_SPCRES) == 0) {
        frontier_error.displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE);
        moreInfoOnErr3("In function nimFractionToReal34:", "the denominator of the fraction should not be 0!", "Unless D flag (Danger) is set.");
        return;
    }

    int32ToReal34(numer, dest);
    int32ToReal34(denom, &temp);
    real34Divide(dest, &temp, dest);
    if (posSpace != 0) {
        stringToReal34(source + 1, &temp);
        real34Add(dest, &temp, dest);
    }
    if (source[0] == '-') {
        real34SetNegativeSign(dest);
    }
}

// The real number, or a part of the complex number, being entered is a fraction.
pub export fn nimFractionEntered() callconv(.c) bool {
    return nimPartIsFraction(nimNumberPart) or (nimComplexPart() and nimPartIsFraction(nimRealPart));
}

// ---------------------------------------------------------------------------
// closeNimWithFraction
// ---------------------------------------------------------------------------
pub export fn closeNimWithFraction(dest: *real34_t) callconv(.c) void {
    nimFractionToReal34(aimBuffer, dest);
}

// The real number or the fraction being entered.
pub export fn nimRealValue(dest: *real34_t) callconv(.c) void {
    if (nimNumberPart == NP_FRACTION_DENOMINATOR or nimNumberPart == NP_HP32SII_DENOMINATOR) {
        closeNimWithFraction(dest);
    } else {
        stringToReal34(aimBuffer, dest);
    }
}

// The complex number being entered; a polar entry is converted from its angle in
// the unit DRG chose for it, or in ADM.
pub export fn nimComplexValue(dest_r: *real34_t, dest_i: *real34_t) callconv(.c) void {
    aimBuffer[@intCast(imaginaryMantissaSignLocation + 1)] = aimBuffer[@intCast(imaginaryMantissaSignLocation)];
    aimBuffer[@intCast(imaginaryMantissaSignLocation)] = 0;

    if (nimRealPart == NP_FRACTION_DENOMINATOR or nimRealPart == NP_HP32SII_DENOMINATOR) {
        nimFractionToReal34(aimBuffer, dest_r);
    } else {
        stringToReal34(aimBuffer, dest_r);
    }

    if (nimNumberPart == NP_COMPLEX_FRACTION_DENOMINATOR or nimNumberPart == NP_COMPLEX_HP32SII_DENOMINATOR) {
        nimFractionToReal34(aimBuffer + @as(usize, @intCast(imaginaryMantissaSignLocation)) + 1, dest_i);
    } else {
        stringToReal34(aimBuffer + @as(usize, @intCast(imaginaryMantissaSignLocation)) + 1, dest_i);
    }

    if (nimPolarEntry()) {
        if (real34CompareEqual(dest_r, const34_0) != 0) {
            real34SetZero(dest_r);
            real34SetZero(dest_i);
        } else {
            var z: cplx_t = undefined;
            if (option_drg_cfg and nimPolarAngularMode == amDMS) { // the angle digits are degrees, minutes and seconds
                frontier_conversion_angles.real34FromDmsToDeg(dest_i, dest_i);
            }
            real34ToReal(dest_r, z.mag());
            real34ToReal(dest_i, z.arg());
            const unit: angularMode_t = if (option_drg_cfg and nimPolarAngularMode != amNone) nimPolarAngularMode else currentAngularMode;
            realPolarToRectangularInUnit(z.mag(), z.arg(), unit, &z, &ctxtReal39);
            realToReal34(&z.Real, dest_r);
            realToReal34(&z.Imag, dest_i);
        }
    }
}

// ---------------------------------------------------------------------------
// closeNimWithComplex
// ---------------------------------------------------------------------------
pub export fn closeNimWithComplex(dest_r: *real34_t, dest_i: *real34_t) callconv(.c) void {
    nimComplexValue(dest_r, dest_i);

    if (nimPolarEntry()) {
        fnToPolar2(0);
        if (option_drg_cfg and nimPolarAngularMode != amNone and calcMode != CM_MIM) { // X shows its angle in the unit DRG chose
            setRegisterTag(REGISTER_X, abi.register_tag.complexWithAngularMode(getRegisterTag(REGISTER_X), nimPolarAngularMode));
        }
    } else {
        fnToRect2(0);
    }
    temporaryFlagRect = 0;
    temporaryFlagPolar = 0;
    if (comptime option_drg_cfg) {
        frontier_addons.drgAutoAdm(nimPolarAngularMode);
        nimPolarAngularMode = amNone;
    }
    fnSetFlag(FLAG_CPXRES);
}

// The value NIM gives a fraction or a complex number being entered, for a
// program literal: NaN where the denominator is refused. im is read only for a
// complex number. Program entry leaves the fraction display as it was, although
// entering a fraction sets it.
pub export fn nimLiteralValue(re: *real34_t, im: ?*real34_t) callconv(.c) void {
    const fract = getSystemFlag(FLAG_FRACT) != 0;
    const irFrac = getSystemFlag(FLAG_IRFRAC) != 0;
    realToReal34(abi.constants.const_NaN(), re);
    if (nimComplexPart()) {
        realToReal34(abi.constants.const_NaN(), im.?);
        nimComplexValue(re, im.?);
    } else {
        closeNimWithFraction(re);
    }
    if (!fract) {
        clearSystemFlag(FLAG_FRACT);
    }
    if (!irFrac) {
        clearSystemFlag(FLAG_IRFRAC);
    }
}

// Before a close: an exponent without digits is left out, an empty imaginary
// part becomes 1 and an empty angle 0. A D.MS fraction closes as its digits, and
// a D.MS number with an exponent is written without it when at most 34 digits
// result.
pub export fn nimCompleteNumber() callconv(.c) void {
    if (option_drg_cfg and nimPartIsFraction(nimNumberPart) and nimDmsDigits()) {
        // The gap, or a bar with no gap before it, is the radix mark, and a later
        // bar is skipped.
        const complexPart = nimComplexPart();
        var digits: [*c]u8 = if (complexPart) aimBuffer + @as(usize, @intCast(imaginaryMantissaSignLocation + 2)) else aimBuffer + 1;
        var mark = false;
        var source: [*c]const u8 = digits;
        while (source[0] != 0) : (source += 1) {
            if (source[0] != ' ' and source[0] != '/') {
                digits[0] = source[0];
                digits += 1;
            } else if (!mark) {
                digits[0] = '.';
                digits += 1;
                mark = true;
            }
        }
        digits[0] = 0;
        nimNumberPart = if (complexPart) NP_COMPLEX_FLOAT_PART else NP_REAL_FLOAT_PART;
    }
    var lastChar: i16 = @intCast(strlen(aimBuffer) - 1);
    if ((nimNumberPart == NP_COMPLEX_EXPONENT or nimNumberPart == NP_REAL_EXPONENT) and (aimBuffer[@intCast(lastChar)] == '+' or aimBuffer[@intCast(lastChar)] == '-') and aimBuffer[@intCast(lastChar - 1)] == 'e') {
        lastChar -= 1;
        aimBuffer[@intCast(lastChar)] = 0;
        lastChar -= 1;
    } else if (nimNumberPart == NP_REAL_EXPONENT and aimBuffer[@intCast(lastChar)] == 'e') {
        aimBuffer[@intCast(lastChar)] = 0;
        lastChar -= 1;
    }
    if (option_drg_cfg and (nimNumberPart == NP_REAL_EXPONENT or nimNumberPart == NP_COMPLEX_EXPONENT) and nimDmsDigits()) {
        // The exponent moves the radix mark of the D.MS digits.
        const complexPart = nimComplexPart();
        const number: [*c]u8 = if (complexPart) aimBuffer + @as(usize, @intCast(imaginaryMantissaSignLocation + 2)) else aimBuffer + 1;
        var digits: [48]u8 = undefined;
        var integerDigits: i16 = undefined;
        const whole = nimDmsExponentDigits(number, &digits, &integerDigits);
        const count: i16 = @intCast(strlen(&digits));
        if (@max(whole, 1) + (if (whole < count) count - whole else 0) <= 34) {
            var write = number;
            if (whole <= 0) {
                write[0] = '0';
                write += 1;
            }
            var i: i16 = 0;
            while (i < whole) : (i += 1) {
                write[0] = if (i < count) digits[@intCast(i)] else '0';
                write += 1;
            }
            write[0] = '.';
            write += 1;
            i = whole;
            while (i < count) : (i += 1) {
                write[0] = if (i < 0) '0' else digits[@intCast(i)];
                write += 1;
            }
            write[0] = 0;
            while (number[0] == '0' and number[1] != '.') { // the zeros in front of the degrees
                _ = frontier_char_string.xcopy(number, number + 1, @intCast(strlen(number)));
            }
            nimNumberPart = if (complexPart) NP_COMPLEX_FLOAT_PART else NP_REAL_FLOAT_PART;
            lastChar = @intCast(strlen(aimBuffer) - 1);
        }
    }
    const is_i: bool = nimNumberPart == NP_COMPLEX_INT_PART and aimBuffer[@intCast(lastChar)] == 'i';
    const is_theta: bool = nimNumberPart == NP_COMPLEX_INT_PART and (@as(i32, aimBuffer[@intCast(lastChar - 1)]) * 256 + @as(i32, aimBuffer[@intCast(lastChar)]) * 256) == 0xa221;
    if ((is_i or is_theta) and !nimPolarEntry()) { // i: nothing typed after it, so the imaginary part is 1
        lastChar += 1;
        aimBuffer[@intCast(lastChar)] = '1';
        aimBuffer[@intCast(lastChar + 1)] = 0;
    } else if ((is_i or is_theta) and nimPolarEntry()) { // i∠: nothing typed after it, so the angle is 0
        lastChar += 1;
        aimBuffer[@intCast(lastChar)] = '0';
        aimBuffer[@intCast(lastChar + 1)] = 0;
    }
}

// The short integer typed as digits#base, into regist. False with the error
// displayed when the digits, the base or the word size refuse it.
pub export fn nimShortInteger(buffer: [*c]u8, regist: calcRegister_t) callconv(.c) bool {
    var minVal: longInteger_t = undefined;
    var value: longInteger_t = undefined;
    var maxVal: longInteger_t = undefined;

    const lg: i16 = @intCast(strlen(buffer));
    var posHash: i16 = 0;
    var ii: i16 = 1;
    while (ii < lg) : (ii += 1) {
        if (buffer[@intCast(ii)] == '#') {
            posHash = ii;
            break;
        }
    }

    ii = posHash + 1;
    while (ii < lg) : (ii += 1) {
        if (buffer[@intCast(ii)] < '0' or buffer[@intCast(ii)] > '9') {
            // This should never happen
            frontier_error.displayCalcErrorMessage(ERROR_INVALID_INTEGER_INPUT, ERR_REGISTER_LINE);
            moreInfoOnErr("In function closeNIM:", "there is a non numeric character in the base of the integer!");
            return false;
        }
    }

    const base: i32 = stringToInt32(buffer + @as(usize, @intCast(posHash)) + 1);
    if (base < 2 or base > 16) {
        frontier_error.displayCalcErrorMessage(ERROR_INVALID_INTEGER_INPUT, ERR_REGISTER_LINE);
        moreInfoOnErr("In function closeNIM:", "the base of the integer must be from 2 to 16!");
        return false;
    }

    if (!checkShortIntegerDigits(buffer)) {
        undo();
        return false;
    }

    longIntegerInit(&value);
    buffer[@intCast(posHash)] = 0;
    _ = stringToLongInteger(buffer + @as(usize, if (buffer[0] == '+') 1 else 0), base, &value);

    // maxVal = 2^shortIntegerWordSize
    longIntegerInit(&maxVal);
    if (shortIntegerWordSize >= 1 and shortIntegerWordSize <= 64) {
        longInteger2Pow(shortIntegerWordSize, &maxVal);
    } else {
        _ = sprintf(errorMessage, &commonBugScreenMessages[bugMsgValueFor], "closeNIM", "shortIntegerWordSize", @as(c_int, shortIntegerWordSize));
        frontier_error.displayBugScreen(errorMessage);
        longIntegerFree(&maxVal);
        longIntegerFree(&value);
        return false;
    }

    // minVal = -maxVal/2
    longIntegerInit(&minVal);
    longIntegerSetZero(&minVal); // Mandatory! Else SEGV at next instruction
    longIntegerDivideUInt(&maxVal, 2, &minVal); // minVal = maxVal / 2
    longIntegerSetNegativeSign(&minVal); // minVal = -minVal

    if ((base != 2) and (base != 4) and (base != 8) and (base != 16) and (shortIntegerMode != SIM_UNSIGN)) {
        longIntegerDivideUInt(&maxVal, 2, &maxVal); // maxVal /= 2
    }

    longIntegerSubtractUInt(&maxVal, 1, &maxVal); // maxVal--

    if (shortIntegerMode == SIM_UNSIGN) {
        longIntegerSetZero(&minVal); // minVal = 0
    }

    if (shortIntegerMode == SIM_1COMPL or shortIntegerMode == SIM_SIGNMT) {
        longIntegerAddUInt(&minVal, 1, &minVal); // minVal++
    }

    if (longIntegerCompare(&value, &minVal) < 0 or longIntegerCompare(&value, &maxVal) > 0) {
        frontier_error.displayCalcErrorMessage(ERROR_WORD_SIZE_TOO_SMALL, ERR_REGISTER_LINE);
        if (comptime extra_info) {
            if (comptime !dmcp_build) {
                var strMin: [22]u8 = undefined;
                var strMax: [22]u8 = undefined;
                frontier_display.longIntegerToAllocatedString(&minVal[0], &strMin, @intCast(strMin.len));
                frontier_display.longIntegerToAllocatedString(&maxVal[0], &strMax, @intCast(strMax.len));
                abi.fmtBufZ(errorMessage[0..512], "For word size of {d} bit{s} and integer mode {s},", .{ @as(i32, shortIntegerWordSize), std.mem.span(if (shortIntegerWordSize > 1) @as([*c]const u8, "s") else @as([*c]const u8, "")), std.mem.span(frontier_debug.getShortIntegerModeName(shortIntegerMode)) });
                abi.fmtCStr(errorMessage + ERROR_MESSAGE_LENGTH / 2, "the entered number must be from {s} to {s}!", .{ std.mem.sliceTo(&strMin, 0), std.mem.sliceTo(&strMax, 0) });
                moreInfoOnError("In function closeNIM:", errorMessage, errorMessage + ERROR_MESSAGE_LENGTH / 2, null);
            }
        }
        longIntegerFree(&maxVal);
        longIntegerFree(&minVal);
        longIntegerFree(&value);
        return false;
    }

    _ = reallocateRegister(regist, dtShortInteger, 0, @intCast(base));

    var strValue: [22]u8 = undefined;
    frontier_display.longIntegerToAllocatedString(&value[0], &strValue, @intCast(strValue.len));

    // WIDTH-CONTRACT: no-width-question -- `long long` is 64-bit on every target
    // z47 builds for, and the string is one this function just formatted rather
    // than file input.
    var val: u64 = strtoull(@as([*c]const u8, &strValue) + @as(usize, if (longIntegerIsNegative(&value)) 1 else 0), null, 10);

    if (shortIntegerMode == SIM_UNSIGN) {} else if (shortIntegerMode == SIM_2COMPL) {
        if (longIntegerIsNegative(&value)) {
            val = (~val +% 1) & shortIntegerMask;
        }
    } else if (shortIntegerMode == SIM_1COMPL) {
        if (longIntegerIsNegative(&value)) {
            val = ~val & shortIntegerMask;
        }
    } else if (shortIntegerMode == SIM_SIGNMT) {
        if (longIntegerIsNegative(&value)) {
            val = (val & shortIntegerMask) | shortIntegerSignBit;
        }
    } else {
        _ = sprintf(errorMessage, &commonBugScreenMessages[bugMsgValueFor], "closeNIM", "shortIntegerMode", @as(c_int, shortIntegerMode));
        frontier_error.displayBugScreen(errorMessage);
        regShortInteger(regist).* = 0;
    }

    regShortInteger(regist).* = val;

    longIntegerFree(&maxVal);
    longIntegerFree(&minVal);
    longIntegerFree(&value);
    return true;
}

// ---------------------------------------------------------------------------
// closeNim
// ---------------------------------------------------------------------------
pub export fn closeNim() callconv(.c) void {
    setSystemFlag(FLAG_ASLIFT);
    screenUpdatingMode &= ~@as(u8, SCRUPD_MANUAL_STACK | SCRUPD_SKIP_STACK_ONE_TIME);

    if (nimNumberPart == NP_INT_10) { // JM Input default type
        switch (Input_Default) {
            ID_43S, ID_LI => {}, // Do nothing, default LI/DP
            ID_DP, ID_CPXDP => {
                if (lastIntegerBase == 0) {
                    nimNumberPart = NP_REAL_FLOAT_PART;
                }
            },
            else => {},
        }
    }
    if ((nimNumberPart == NP_INT_10 or nimNumberPart == NP_INT_16) and lastIntegerBase != 0) {
        _ = strcat(aimBuffer, "#0");
        var basePos: i16 = @intCast(strlen(aimBuffer) - 1);
        if (lastIntegerBase <= 9) {
            aimBuffer[@intCast(basePos)] +%= @intCast(lastIntegerBase);
        } else {
            aimBuffer[@intCast(basePos)] = '1';
            basePos += 1;
            aimBuffer[@intCast(basePos)] = '0';
            aimBuffer[@intCast(basePos + 1)] = 0;
            aimBuffer[@intCast(basePos)] +%= @intCast(lastIntegerBase - 10);
        }
        nimNumberPart = NP_INT_BASE;
    } else {
        frontier_screen.setLastintegerBasetoZero();
    }

    if (calcMode == CM_PEM) {
        frontier_manage.pemCloseNumberInput();
        return;
    }

    // The unit DRG gave the number, made ADM by A.AUTO once the close succeeds.
    const drgUnit: angularMode_t = if (option_drg_cfg and calcMode == CM_NIM) getRegisterAngularMode(REGISTER_X) else amNone;
    var delayedShortIntegerCHS: bool = false;
    if (aimBuffer[0] == '-' and validShortIntegerInX() != 0) {
        aimBuffer[0] = ' ';
        delayedShortIntegerCHS = true;
    }

    var lastChar: i16 = @intCast(strlen(aimBuffer) - 1);

    closeNim_exit: {
        if (nimNumberPart != NP_INT_16) { // We need a # and a base
            if (nimNumberPart != NP_INT_BASE or aimBuffer[@intCast(lastChar)] != '#') { // We need a base
                nimCompleteNumber();
                lastChar = @intCast(strlen(aimBuffer) - 1);

                if ((aimBuffer[0] != '-' or aimBuffer[1] != 0) and (aimBuffer[@intCast(lastChar)] != '-')) {
                    frontier_calc_mode.calcModeNormal();

                    if (nimNumberPart == NP_INT_10) {
                        var lgInt: longInteger_t = undefined;
                        const xangularMode: angularMode_t = if ((getRegisterDataType(REGISTER_X) == dtReal34) == (dtReal34 != 0)) getRegisterAngularMode(REGISTER_X) else amNone;

                        if (xangularMode < amNone) { // editing with angular mode -> convert to real, preserve angular mode
                            _ = reallocateRegister(REGISTER_X, dtReal34, 0, @intCast(getRegisterAngularMode(REGISTER_X)));
                            stringToReal34(aimBuffer, reg34(REGISTER_X));
                            if (xangularMode == amDMS) {
                                frontier_conversion_angles.real34FromDmsToDeg(reg34(REGISTER_X), reg34(REGISTER_X));
                            }
                        } else {
                            longIntegerInit(&lgInt);
                            _ = stringToLongInteger(aimBuffer + @as(usize, if (aimBuffer[0] == '+') 1 else 0), 10, &lgInt);
                            frontier_register_value_conversions.convertLongIntegerToLongIntegerRegister(&lgInt[0], REGISTER_X);
                            longIntegerFree(&lgInt);
                        }
                    } else if (nimNumberPart == NP_INT_BASE) {
                        if (!nimShortInteger(aimBuffer, REGISTER_X)) {
                            break :closeNim_exit;
                        }
                        lastIntegerBase = getRegisterTag(REGISTER_X);
                        frontier_radio_button_catalog.fnRefreshState();
                        aimBuffer[0] = 0; // Clear the NIM input buffer once written successfully.
                    } else if (nimNumberPart == NP_REAL_FLOAT_PART or nimNumberPart == NP_REAL_EXPONENT) {
                        const dataType: u16 = @intCast(getRegisterDataType(REGISTER_X));
                        if (dataType == dtTime) {
                            _ = reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
                            stringToReal34(aimBuffer, reg34(REGISTER_X));

                            if (calcMode != CM_NIM and lastErrorCode == 0) {
                                if (getRegisterDataType(REGISTER_X) == dtLongInteger) {
                                    frontier_register_value_conversions.convertLongIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
                                }
                                frontier_date_time.hmmssInRegisterToSeconds(REGISTER_X);
                                if (lastErrorCode == 0) {
                                    setSystemFlag(FLAG_ASLIFT);
                                } else {
                                    undo();
                                }
                            }
                        } else if (dataType == dtDate) {
                            _ = reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
                            stringToReal34(aimBuffer, reg34(REGISTER_X));

                            if (calcMode != CM_NIM and lastErrorCode == 0) {
                                frontier_register_value_conversions.convertReal34RegisterToDateRegister(REGISTER_X, REGISTER_X, YYSystem != 0);
                                frontier_date_time.checkDateRange(reg34(REGISTER_X));
                                temporaryInformation = TI_DAY_OF_WEEK;

                                if (lastErrorCode == 0) {
                                    setSystemFlag(FLAG_ASLIFT);
                                } else {
                                    undo();
                                }
                            }
                        } else {
                            if (lastIntegerBase == 0 and Input_Default == ID_CPXDP) {
                                _ = reallocateRegister(REGISTER_X, dtComplex34, 0, amNone);
                                stringToReal34(aimBuffer, reg34(REGISTER_X));
                                stringToReal34("0", regImag34(REGISTER_X));
                            } else {
                                const xangularMode: angularMode_t = if ((getRegisterDataType(REGISTER_X) == dtReal34) == (dtReal34 != 0)) getRegisterAngularMode(REGISTER_X) else amNone;

                                _ = reallocateRegister(REGISTER_X, dtReal34, 0, @intCast(xangularMode));
                                stringToReal34(aimBuffer, reg34(REGISTER_X));
                                if (xangularMode == amDMS) {
                                    frontier_conversion_angles.real34FromDmsToDeg(reg34(REGISTER_X), reg34(REGISTER_X));
                                }
                            }
                        }
                    } else if (nimNumberPart == NP_FRACTION_DENOMINATOR or nimNumberPart == NP_HP32SII_DENOMINATOR) {
                        _ = reallocateRegister(REGISTER_X, dtReal34, 0, @intCast(getRegisterAngularMode(REGISTER_X)));
                        closeNimWithFraction(reg34(REGISTER_X));
                    } else if (nimNumberPart == NP_COMPLEX_INT_PART or nimNumberPart == NP_COMPLEX_FLOAT_PART or nimNumberPart == NP_COMPLEX_EXPONENT or nimNumberPart == NP_COMPLEX_FRACTION_DENOMINATOR or nimNumberPart == NP_COMPLEX_HP32SII_DENOMINATOR) {
                        _ = reallocateRegister(REGISTER_X, dtComplex34, 0, amNone);
                        closeNimWithComplex(reg34(REGISTER_X), regImag34(REGISTER_X));
                    } else {
                        _ = sprintf(errorMessage, &commonBugScreenMessages[bugMsgUnexpectedSValue], "closeNIM", @as(c_uint, nimNumberPart), "nimNumberPart");
                        frontier_error.displayBugScreen(errorMessage);
                    }
                }
            }
        }
        if (delayedShortIntegerCHS) {
            chsShoI();
        }

        if (comptime ir_printing) {
            if ((lastItem != ITM_ms) and (lastItem != ITM_dotD) and (lastItem != ITM_DRG)) { // avoid double tracing for functions changing X after closeNim
                // PC_BUILD && MONITOR_IRPRINT: both are defined for the simulator
                // and for the testSuite.
                if (comptime !dmcp_build) {
                    _ = printf("**[DL]** closeNim printTraceX lastItem %d\n", @as(c_int, lastItem));
                    _ = fflush(null);
                }
                frontier_print.printTraceX(LINE_NOLF);
            }
            lastItem = 0;
        }
    } // closeNim_exit

    if (calcMode != CM_NIM) { // a refused close keeps NIM open
        nimNumberPart = NP_EMPTY; // Ensure insertStepInProgram sees the correct value.
        if (option_drg_cfg and lastErrorCode == 0) {
            frontier_addons.drgAutoAdm(@intCast(drgUnit));
        }
    }
}

// ---------------------------------------------------------------------------
// addItemToBuffer
// ---------------------------------------------------------------------------
pub export fn addItemToBuffer(item_in: u16) callconv(.c) void {
    var item = item_in;
    if (comptime !dmcp_build) {
        var tmp: [200]u8 = undefined;
        abi.fmtBufZ(&tmp, "bufferize.c:addItemToBuffer item={d} tam.mode={d}\n", .{ @as(c_int, @bitCast(@as(u32, item))), @as(c_int, tam.mode) });
        jm_show_calc_state(&tmp);
    }

    if (item == NOPARAM) {
        frontier_error.displayBugScreen(bugScreenNoParam);
    } else {
        screenUpdatingMode &= ~@as(u8, SCRUPD_MANUAL_STACK | SCRUPD_MANUAL_SHIFT_STATUS);
        currentSolverStatus &= ~@as(u16, SOLVER_STATUS_READY_TO_EXECUTE);
        if (calcMode == CM_NORMAL and fnKeyInCatalog != 0 and (frontier_softmenus.isAlphabeticSoftmenu() != 0 or frontier_softmenus.isJMAlphaOnlySoftmenu() != 0) and tam.mode == 0) {
            fnAim(NOPARAM);
        } else if ((fnKeyInCatalog != 0 or catalog == 0 or catalog == CATALOG_MVAR) and (((calcMode == CM_AIM or calcMode == CM_EIM) and tam.mode == 0) or tam.alpha)) {
            item = convertItemToSubOrSup(item, nextChar);
            if (tam.alpha) {
                insertAlphaCharacter(item, &alphaCursor);
            } else if (stringByteLength(aimBuffer) + (if (item == ITM_poly_SIGN) @as(i32, 24) else stringByteLength(&indexOfItems[item].itemSoftmenuName)) >= (if (calcMode == CM_EIM) @as(i32, MAX_EQUATION_BYTE_LENGTH) else AIM_BUFFER_LENGTH)) {
                // full: the equation store is 255 blocks, alpha is the buffer; refuse the character so the text survives and ENTER still stores it
                frontier_error.displayCalcErrorMessage(ERROR_INPUT_TOO_LONG, ERR_REGISTER_LINE);
            } else if (calcMode == CM_EIM) {
                const addChar0: [*c]const u8 = if (item == ITM_EEXCHR) "E" else if (item == ITM_PAIR_OF_PARENTHESES) "()" else if (item == ITM_VERTICAL_BAR) "||" else if (item == ITM_MAGNITUDE) "||" else if (item == ITM_ROOT_SIGN) STD_SQUARE_ROOT ++ "()" else if (item == ITM_SQUAREROOTX) STD_SQUARE_ROOT ++ "()" else if (item == ITM_CUBEROOT) STD_CUBE_ROOT ++ "()" else if (item == ITM_XTHROOT) STD_xTH_ROOT ++ "(:)" else if (item == ITM_EXP) STD_EulerE ++ "^()" else if (item == ITM_ALOG_SIGN) STD_EulerE ++ "^()" else if (item == ITM_LG_SIGN) "LOG()" else if (item == ITM_LN_SIGN) "LN()" else if (item == ITM_LOG2) "LB()" else if (item == ITM_SIN_SIGN) "SIN()" else if (item == ITM_COS_SIGN) "COS()" else if (item == ITM_TAN_SIGN) "TAN()" else if (item == ITM_OBELUS) STD_SLASH else if (item == ITM_poly_SIGN) "a4" ++ STD_DOT ++ "x^4+a3" ++ STD_DOT ++ "x^3+a2" ++ STD_DOT ++ "x^2+a1" ++ STD_DOT ++ "x+a0" else if (item == ITM_op_j_SIGN) complexUnit() else if (item == ITM_zetaX) STD_zeta ++ "()" else if (item == ITM_GAMMAX) STD_GAMMA ++ "()" else if (item == ITM_XFACT) "!" else if (item == ITM_M1X) "(-1)^()" else if (item == ITM_COMB) "COMB(:)" else if (item == ITM_PERM) "PERM(:)" else if (item >= FIRST_CONSTANT and item <= LAST_CONSTANT) @as([*c]const u8, &indexOfItems[item].itemCatalogName) else if (item >= ITM_SUP_0 and item <= ITM_SUP_9) @as([*c]const u8, &NumMsg[item - ITM_SUP_0].noStr) else "";

                var addChar: [100]u8 = undefined;
                var jj: i16 = 0;
                addChar[0] = 0;
                if (addChar0[0] == 0) {
                    // "=" is not filtered out here: an equation can be typed with
                    // both sides, and Draw plots the left one.
                    _ = stringCopy(&addChar, &indexOfItems[item].itemSoftmenuName);
                    if ((indexOfItems[item].itemSoftmenuName[0] != 0) and (indexOfItems[item].status & EIM_STATUS) == EIM_ENABLED) {
                        if (isDyadicFunction(item)) {
                            _ = stringCopy(@as([*c]u8, &addChar) + @as(usize, @intCast(stringByteLength(&addChar))), "(:)");
                            jj = 2;
                        } else {
                            _ = stringCopy(@as([*c]u8, &addChar) + @as(usize, @intCast(stringByteLength(&addChar))), "()");
                            jj = 1;
                        }
                    }
                } else {
                    _ = stringCopy(&addChar, addChar0);
                    if (addChar0[0] == '^') {
                        if (scrLock == NC_SUPERSCRIPT) {
                            scrLock = NC_NORMAL;
                            frontier_radio_button_catalog.fnRefreshState();
                        }
                    }
                }

                var aimCursorPos: [*c]u8 = aimBuffer;
                var aimBottomPos: [*c]u8 = aimBuffer + @as(usize, @intCast(stringByteLength(aimBuffer)));
                const itemLen: u32 = @intCast(stringByteLength(&addChar));
                var i: u32 = 0;
                while (i < xCursor) : (i += 1) {
                    aimCursorPos += if ((aimCursorPos[0] & 0x80) != 0) @as(usize, 2) else 1;
                }
                while (@intFromPtr(aimBottomPos) >= @intFromPtr(aimCursorPos)) : (aimBottomPos -= 1) {
                    (aimBottomPos + itemLen)[0] = aimBottomPos[0];
                }
                _ = frontier_char_string.xcopy(aimCursorPos, &addChar, itemLen);
                if (jj != 0) {
                    xCursor +%= @bitCast(@as(i32, frontier_char_string.stringGlyphLength(&addChar) - jj));
                } else {
                    switch (item) {
                        ITM_poly_SIGN => {
                            xCursor +%= 0;
                        },
                        ITM_M1X => {
                            xCursor +%= 6;
                        },
                        ITM_COMB, ITM_PERM => {
                            xCursor +%= 5;
                        },
                        ITM_LG_SIGN, ITM_SIN_SIGN, ITM_COS_SIGN, ITM_TAN_SIGN => {
                            xCursor +%= 4;
                        },
                        ITM_ALOG_SIGN, ITM_LOG2, ITM_EXP, ITM_LN_SIGN => {
                            xCursor +%= 3;
                        },
                        ITM_ROOT_SIGN, ITM_SQUAREROOTX, ITM_CUBEROOT, ITM_XTHROOT, ITM_GAMMAX, ITM_zetaX => {
                            xCursor +%= 2;
                        },
                        ITM_PAIR_OF_PARENTHESES, ITM_VERTICAL_BAR, ITM_MAGNITUDE => {
                            xCursor +%= 1;
                        },
                        ITM_XFACT => {},
                        else => {
                            xCursor +%= @intCast(frontier_char_string.stringGlyphLength(&addChar));
                        },
                    }
                }
            } else if (stringByteLength(aimBuffer) + stringByteLength(&indexOfItems[item].itemSoftmenuName) <= MAX_STRING_BYTE_LENGTH - 1) { // the 1019-byte string limit; the editor scrolls through displayAIMbufferoffset
                // TEXT_MULTILINE_EDIT (always defined): insert mid-string.
                var ix: u16 = 0;
                var in: u16 = 0;
                while (ix < @as(u16, @bitCast(T_cursorPos)) and in < @as(u16, @bitCast(T_cursorPos))) {
                    in = @bitCast(frontier_char_string.stringNextGlyphNoEndCheck_JM(aimBuffer, @bitCast(in)));
                    ix += 1;
                }
                T_cursorPos = @bitCast(in);
                const nq: u16 = @intCast(stringByteLength(&indexOfItems[item].itemSoftmenuName));
                const nr: u16 = @intCast(stringByteLength(aimBuffer + in));
                _ = frontier_char_string.xcopy(aimBuffer + in + nq, aimBuffer + in, nr + 1); // shift the tail, its terminator included
                _ = frontier_char_string.xcopy(aimBuffer + in, &indexOfItems[item].itemSoftmenuName, nq);

                T_cursorPos = frontier_char_string.stringNextGlyph(aimBuffer, T_cursorPos);
                switch (item) {
                    ITM_LG_SIGN, ITM_SIN_SIGN, ITM_COS_SIGN, ITM_TAN_SIGN, ITM_ROOT_SIGN => {
                        T_cursorPos += 2;
                    },
                    ITM_LN_SIGN => {
                        T_cursorPos += 1;
                    },
                    ITM_PAIR_OF_PARENTHESES => {
                        T_cursorPos += 1;
                    },
                    else => {},
                }

                frontier_screen.incOffset();
            } else {
                frontier_error.displayCalcErrorMessage(ERROR_INPUT_TOO_LONG, ERR_REGISTER_LINE); // the text fills the editable width: refuse with feedback rather than dropping the key silently
            }
        }

        // Scroll_Asm: SCROLL_ASM is not defined -> Scroll_Asm == 1.
        const Scroll_Asm: i32 = 1;

        if (catalog != 0 and catalog != CATALOG_MVAR and fnKeyInCatalog == 0) {
            if (item == ITM_BACKSPACE) {
                frontier_calc_mode.calcModeNormal();
                return;
            } else if (frontier_char_string.stringGlyphLength(&indexOfItems[item].itemSoftmenuName) == 1 and frontier_char_string.stringGlyphLength(&asmBuffer) <= Scroll_Asm and item != ITM_CR and item != ITM_ROOT_SIGN and frontier_softmenus.currentSoftmenuScrolls() != 0) {
                _ = stringCopy(@as([*c]u8, &asmBuffer) + @as(usize, @intCast(stringByteLength(&asmBuffer))), &indexOfItems[item].itemSoftmenuName);

                softmenuStack[0].firstItem = @intCast(findFirstItem(&asmBuffer));
                doRefreshSoftMenu = 1; // the search moved the menu to another page, and btnReleased leaves it protected
                frontier_softmenus.setCatalogLastPos();
                fnTimerStart(TO_ASM_ACTIVE, TO_ASM_ACTIVE, 3000);
                frontier_status_bar.light_ASB_icon();
            }
            if (calcMode == CM_PEM) {
                hourGlassIconEnabled = 0;
            }
        } else if (tam.mode != 0) {
            if ((item == ITM_INDIRECT_X) or (item == ITM_INDIRECT_Y) or (item == ITM_INDIRECT_Z) or (item == ITM_INDIRECT_T)) {
                frontier_tam.tamProcessInput(ITM_INDIRECTION);
                frontier_tam.tamProcessInput(item - (ITM_INDIRECT_X - ITM_REG_X));
            } else {
                frontier_tam.tamProcessInput(item);
            }
        } else if (calcMode == CM_NIM) {
            addItemToNimBuffer(@bitCast(item));
        } else if (calcMode == CM_MIM) {
            if (temporaryInformation == TI_SHOW_REGISTER) {
                temporaryInformation = TI_NO_INFO;
            }

            if (item == ITM_RIGHT_ARROW) {
                matrix_lifecycle.mimEnter(true);
                frontier_matrix_editor.setJRegisterAsInt(true, frontier_matrix_editor.getJRegisterAsInt(true) + 1);
                frontier_screen.refreshScreen(51);
                frontier_print.printTrace(@bitCast(item), @bitCast(item));
                frontier_print.printTraceMatElement(LINE_FULL_U);
            } else if (item == ITM_LEFT_ARROW) {
                matrix_lifecycle.mimEnter(true);
                frontier_matrix_editor.setJRegisterAsInt(true, frontier_matrix_editor.getJRegisterAsInt(true) - 1);
                frontier_screen.refreshScreen(52);
                frontier_print.printTrace(@bitCast(item), @bitCast(item));
                frontier_print.printTraceMatElement(LINE_FULL_U);
            } else if (item == ITM_UP_ARROW) {
                matrix_lifecycle.mimEnter(true);
                frontier_matrix_editor.setIRegisterAsInt(true, frontier_matrix_editor.getIRegisterAsInt(true) - 1);
                frontier_screen.refreshScreen(53);
                frontier_print.printTrace(@bitCast(item), @bitCast(item));
                frontier_print.printTraceMatElement(LINE_FULL_U);
            } else if (item == ITM_DOWN_ARROW) {
                matrix_lifecycle.mimEnter(true);
                frontier_matrix_editor.setIRegisterAsInt(true, frontier_matrix_editor.getIRegisterAsInt(true) + 1);
                frontier_screen.refreshScreen(54);
                frontier_print.printTrace(@bitCast(item), @bitCast(item));
                frontier_print.printTraceMatElement(LINE_FULL_U);
            }

            if (@as(i16, @bitCast(item)) < 0) {
                frontier_softmenus.showSoftmenu(@bitCast(item));
                frontier_screen.refreshScreen(55);
                return;
            }

            switch (item) {
                ITM_SHOW => {
                    matrix_lifecycle.mimEnter(true);
                    temporaryInformation = TI_SHOW_REGISTER;
                },
                ITM_OFF => {
                    frontier_items.runFunction(ITM_OFF);
                },
                else => {
                    if (isFunctionInMim(@bitCast(item), 0)) {
                        frontier_matrix_editor.mimAddNumber(@bitCast(item));
                    } else if (isFunctionInMim(@bitCast(item), 1)) {
                        lastErrorCode = ERROR_NONE;
                        matrix_lifecycle.mimEnter(true);
                        frontier_items.runFunction(@bitCast(item));
                    } else if (isFunctionInMim(@bitCast(item), 2) or isFunctionInMim(@bitCast(item), 3)) {
                        frontier_matrix_editor.mimRunFunction(@bitCast(item), indexOfItems[item].param);
                    }
                },
            }
        } else if (calcMode != CM_AIM and calcMode != CM_EIM and calcMode != CM_ASSIGN and (item >= ITM_A and item <= ITM_F)) {
            addItemToNimBuffer(@bitCast(item));
        } else if (calcMode != CM_AIM and calcMode != CM_EIM) {
            funcOK = 0;
            return;
        }

        funcOK = 1;
    }
}

// C `goto addItemToNimBuffer_exit` jumps to the label at the START of the
// ITM_EXIT1 case body. It is reached only from the integer base-entry shortcuts
// (item is a base digit/key, never ITM_EXIT1), so the item==ITM_EXIT1-guarded
// saveForUndo paths are skipped. This runs the same close/commit the label runs;
// returns true if the caller must return immediately (NIM closed and left
// CM_NIM), false to fall through to the shared post-switch display processing
// (the `break :sw` path, same as ITM_PERIOD). The caller must not skip the
// closeNim() this performs: it is what commits a base-entry shortcut
// (B/D/H/I/OCT, base-digit completion) to X.
fn nimExitCloseFromGoto() bool {
    screenUpdatingMode &= ~@as(u8, SCRUPD_SKIP_STACK_ONE_TIME);
    closeNim();
    if (lastErrorCode != 0) {
        return true; // closeNim rejected buffer; skip display rebuild (caller must return)
    }
    if (calcMode != CM_NIM and lastErrorCode == 0) {
        frontier_print.printTrace(ITM_ENTER, NOPARAM);
        setSystemFlag(FLAG_ASLIFT);
        return true;
    }
    return false;
}

// ---------------------------------------------------------------------------
// addItemToNimBuffer
// ---------------------------------------------------------------------------
pub export fn addItemToNimBuffer(item: i16) callconv(.c) void {
    var lastChar: i16 = undefined;
    var index: i16 = undefined;
    var savedNimNumberPart: u8 = undefined;
    var done: bool = undefined;
    var strBase: [*c]u8 = undefined;

    if ((calcMode == CM_NIM or calcMode == CM_NORMAL) and Input_Default == ID_LI and item == ITM_PERIOD) {
        return;
    }

    if (comptime ir_printing) {
        if (calcMode == CM_NIM) {
            lastItem = item;
        }
    }

    if (item >= ITM_A and item <= ITM_F and lastIntegerBase == 0) {
        lastIntegerBase = 16;
    }

    screenUpdatingMode &= ~@as(u8, SCRUPD_MANUAL_STACK | SCRUPD_MANUAL_SHIFT_STATUS);
    currentSolverStatus &= ~@as(u16, SOLVER_STATUS_READY_TO_EXECUTE);

    if (calcMode == CM_NORMAL) {
        switch (item) {
            ITM_EXPONENT, ITM_PERIOD => {
                frontier_calc_mode.calcModeNim(NOPARAM);
                nimStartNumber(item);
                frontier_screen.setLastintegerBasetoZero();
            },
            ITM_0, ITM_1, ITM_2, ITM_3, ITM_4, ITM_5, ITM_6, ITM_7, ITM_8, ITM_9, ITM_A, ITM_B, ITM_C, ITM_D, ITM_E, ITM_F => {
                frontier_calc_mode.calcModeNim(NOPARAM);
                nimStartNumber(item);
            },
            else => {
                abi.fmtBufZ(errorMessage[0..512], "In function addItemToNimBuffer:{d} is an unexpected item value when initializing NIM!", .{@as(i32, item)});
                frontier_error.displayBugScreen(errorMessage);
                return;
            },
        }

        if (programRunStop != PGM_RUNNING) {
            entryStatus |= 0x01;
            setSystemFlag(FLAG_NUMIN);
        }
    } else if (calcMode == CM_NIM) {
        screenUpdatingMode |= SCRUPD_SKIP_STACK_ONE_TIME;
    }

    done = false;

    {
        sw: switch (item) {
            ITM_0, ITM_1, ITM_2, ITM_3, ITM_4, ITM_5, ITM_6, ITM_7, ITM_8, ITM_9 => {
                done = true;

                switch (nimNumberPart) {
                    NP_INT_10 => {
                        if (item == ITM_0) {
                            _ = strcat(aimBuffer, "0");
                        } else {
                            if (aimBuffer[1] == '0') {}
                            _ = strcat(aimBuffer, &indexOfItems[@intCast(item)].itemSoftmenuName);
                        }
                    },
                    NP_REAL_EXPONENT => {
                        if (item == ITM_0) {
                            if (aimBuffer[@intCast(exponentSignLocation + 1)] == '0') {
                                aimBuffer[strlen(aimBuffer) - 1] = 0;
                            }
                            if (aimBuffer[@intCast(exponentSignLocation + 1)] != 0 or aimBuffer[@intCast(exponentSignLocation)] == '+') {
                                _ = strcat(aimBuffer, "0");
                            }
                            if (stringToInt16(aimBuffer + @as(usize, @intCast(exponentSignLocation))) > exponentLimit or stringToInt16(aimBuffer + @as(usize, @intCast(exponentSignLocation))) < -exponentLimit) {
                                aimBuffer[strlen(aimBuffer) - 1] = 0;
                            }
                        } else {
                            if (aimBuffer[@intCast(exponentSignLocation + 1)] == '0') {
                                aimBuffer[strlen(aimBuffer) - 1] = 0;
                            }
                            _ = strcat(aimBuffer, &indexOfItems[@intCast(item)].itemSoftmenuName);
                            if (stringToInt16(aimBuffer + @as(usize, @intCast(exponentSignLocation))) > exponentLimit or stringToInt16(aimBuffer + @as(usize, @intCast(exponentSignLocation))) < -exponentLimit) {
                                aimBuffer[strlen(aimBuffer) - 1] = 0;
                            }
                        }
                    },
                    NP_HP32SII_DENOMINATOR, NP_FRACTION_DENOMINATOR => {
                        if (item == ITM_0) {
                            _ = strcat(aimBuffer, "0");
                            if (aimBuffer[@intCast(denominatorLocation)] == '0') {
                                aimBuffer[@intCast(denominatorLocation)] = 0;
                            }
                            if (toInt32(aimBuffer + @as(usize, @intCast(denominatorLocation))) < 0 or toInt32(aimBuffer + @as(usize, @intCast(denominatorLocation))) > 999999999) {
                                aimBuffer[strlen(aimBuffer) - 1] = 0;
                            }
                        } else {
                            _ = strcat(aimBuffer, &indexOfItems[@intCast(item)].itemSoftmenuName);
                            if (toInt32(aimBuffer + @as(usize, @intCast(denominatorLocation))) < 0 or toInt32(aimBuffer + @as(usize, @intCast(denominatorLocation))) > 999999999) {
                                aimBuffer[strlen(aimBuffer) - 1] = 0;
                            }
                        }
                    },
                    NP_COMPLEX_INT_PART => {
                        if (item == ITM_0) {
                            if (aimBuffer[@intCast(imaginaryMantissaSignLocation + 2)] != '0') {
                                _ = strcat(aimBuffer, "0");
                            }
                        } else {
                            if (aimBuffer[@intCast(imaginaryMantissaSignLocation + 2)] == '0') {
                                aimBuffer[@intCast(imaginaryMantissaSignLocation + 2)] = 0;
                            }
                            _ = strcat(aimBuffer, &indexOfItems[@intCast(item)].itemSoftmenuName);
                        }
                    },
                    NP_COMPLEX_EXPONENT => {
                        if (item == ITM_0) {
                            if (aimBuffer[@intCast(imaginaryExponentSignLocation + 1)] == '0') {
                                aimBuffer[strlen(aimBuffer) - 1] = 0;
                            }
                            if (aimBuffer[@intCast(imaginaryExponentSignLocation + 1)] != 0 or aimBuffer[@intCast(imaginaryExponentSignLocation)] == '+') {
                                _ = strcat(aimBuffer, "0");
                            }
                            if (stringToInt16(aimBuffer + @as(usize, @intCast(imaginaryExponentSignLocation))) > exponentLimit or stringToInt16(aimBuffer + @as(usize, @intCast(imaginaryExponentSignLocation))) < -exponentLimit) {
                                aimBuffer[strlen(aimBuffer) - 1] = 0;
                            }
                        } else {
                            if (aimBuffer[@intCast(imaginaryExponentSignLocation + 1)] == '0') {
                                aimBuffer[strlen(aimBuffer) - 1] = 0;
                            }
                            _ = strcat(aimBuffer, &indexOfItems[@intCast(item)].itemSoftmenuName);
                            if (stringToInt16(aimBuffer + @as(usize, @intCast(imaginaryExponentSignLocation))) > exponentLimit or stringToInt16(aimBuffer + @as(usize, @intCast(imaginaryExponentSignLocation))) < -exponentLimit) {
                                aimBuffer[strlen(aimBuffer) - 1] = 0;
                            }
                        }
                    },
                    NP_COMPLEX_HP32SII_DENOMINATOR, NP_COMPLEX_FRACTION_DENOMINATOR => {
                        if (item == ITM_0) {
                            _ = strcat(aimBuffer, "0");
                            if (aimBuffer[@intCast(imaginaryDenominatorLocation)] == '0') {
                                aimBuffer[@intCast(imaginaryDenominatorLocation)] = 0;
                            }
                            if (toInt32(aimBuffer + @as(usize, @intCast(imaginaryDenominatorLocation))) < 0 or toInt32(aimBuffer + @as(usize, @intCast(imaginaryDenominatorLocation))) > 999999999) {
                                aimBuffer[strlen(aimBuffer) - 1] = 0;
                            }
                        } else {
                            _ = strcat(aimBuffer, &indexOfItems[@intCast(item)].itemSoftmenuName);
                            if (toInt32(aimBuffer + @as(usize, @intCast(imaginaryDenominatorLocation))) < 0 or toInt32(aimBuffer + @as(usize, @intCast(imaginaryDenominatorLocation))) > 999999999) {
                                aimBuffer[strlen(aimBuffer) - 1] = 0;
                            }
                        }
                    },
                    NP_INT_BASE => {
                        _ = strcat(aimBuffer, &indexOfItems[@intCast(item)].itemSoftmenuName);
                        strBase = strchr(aimBuffer, '#') + 1;
                        if (atoi(strBase) > 16) {
                            strBase[1] = 0;
                        } else if (atoi(strBase) >= 2) {
                            {
                                done = true;
                                if (nimExitCloseFromGoto()) return;
                                break :sw;
                            }
                        }
                    },
                    else => {
                        if (nimNumberPart == NP_EMPTY) {
                            nimNumberPart = NP_INT_10;
                        }
                        _ = strcat(aimBuffer, &indexOfItems[@intCast(item)].itemSoftmenuName);
                    },
                }
            },

            ITM_A, ITM_B, ITM_C, ITM_D, ITM_E, ITM_F => {
                done = true;
                if (nimNumberPart == NP_EMPTY or nimNumberPart == NP_INT_10 or nimNumberPart == NP_INT_16) {
                    if (aimBuffer[1] == '0') {}
                    _ = strcat(aimBuffer, &indexOfItems[@intCast(item)].itemSoftmenuName);
                    hexDigits += 1;
                    nimNumberPart = NP_INT_16;
                    if (lastIntegerBase <= 10) {
                        lastIntegerBase = 16;
                    }
                }
            },

            ITM_PERIOD => {
                done = true;
                if (aimBuffer[strlen(aimBuffer) - 1] == 'i') {
                    _ = strcat(aimBuffer, "0");
                }
                frontier_screen.setLastintegerBasetoZero();
                switch (nimNumberPart) {
                    NP_INT_10 => {
                        _ = strcat(aimBuffer, ".");
                        nimNumberPart = NP_REAL_FLOAT_PART;
                    },
                    NP_REAL_FLOAT_PART => {
                        if (option_drg_cfg and nimDmsDigits()) { // a D.MS number takes one radix mark and no fraction
                            break :sw;
                        }
                        var HP32SII: bool = false;
                        if (aimBuffer[strlen(aimBuffer) - 1] == '.') {
                            HP32SII = true;
                        }
                        const numeratorLocation: i16 = if (HP32SII) 1 else @intCast(strchr(aimBuffer, '.') - aimBuffer + 1);
                        const numerator: i32 = toInt32(aimBuffer + @as(usize, @intCast(numeratorLocation)));
                        if (numerator < 0 or numerator > 999999999) {
                            break :sw;
                        }
                        if (HP32SII) {
                            aimBuffer[strlen(aimBuffer) - 1] = 0;
                        } else {
                            aimBuffer[@intCast(numeratorLocation - 1)] = ' ';
                        }
                        _ = strcat(aimBuffer, "/");
                        denominatorLocation = @intCast(strlen(aimBuffer));
                        nimNumberPart = if (HP32SII) NP_HP32SII_DENOMINATOR else NP_FRACTION_DENOMINATOR;
                    },
                    NP_COMPLEX_INT_PART => {
                        _ = strcat(aimBuffer, ".");
                        nimNumberPart = NP_COMPLEX_FLOAT_PART;
                    },
                    NP_COMPLEX_FLOAT_PART => {
                        if (option_drg_cfg and nimDmsDigits()) { // a D.MS angle takes one radix mark and no fraction
                            break :sw;
                        }
                        var HP32SII: bool = false;
                        if (aimBuffer[strlen(aimBuffer) - 1] == '.') {
                            HP32SII = true;
                        }
                        const numeratorLocation: i16 = if (HP32SII) imaginaryMantissaSignLocation + 2 else @intCast(strchr(aimBuffer + @as(usize, @intCast(imaginaryMantissaSignLocation)) + 2, '.') - aimBuffer + 1);
                        const numerator: i32 = toInt32(aimBuffer + @as(usize, @intCast(numeratorLocation)));
                        if (numerator < 0 or numerator > 999999999) {
                            break :sw;
                        }
                        if (HP32SII) {
                            aimBuffer[strlen(aimBuffer) - 1] = 0;
                        } else {
                            aimBuffer[@intCast(numeratorLocation - 1)] = ' ';
                        }
                        _ = strcat(aimBuffer, "/");
                        imaginaryDenominatorLocation = @intCast(strlen(aimBuffer));
                        nimNumberPart = if (HP32SII) NP_COMPLEX_HP32SII_DENOMINATOR else NP_COMPLEX_FRACTION_DENOMINATOR;
                    },
                    else => {},
                }
            },

            ITM_EXPONENT => {
                if (integerShortcuts() and nimNumberPart == NP_INT_BASE and aimBuffer[strlen(aimBuffer) - 1] == '#') {
                    _ = strcat(aimBuffer, "8");
                    {
                        done = true;
                        if (nimExitCloseFromGoto()) return;
                        break :sw;
                    }
                }
                done = true;
                if (aimBuffer[strlen(aimBuffer) - 1] == 'i') {
                    _ = strcat(aimBuffer, "1");
                }
                frontier_screen.setLastintegerBasetoZero();
                switch (nimNumberPart) {
                    NP_INT_10 => {
                        _ = strcat(aimBuffer, "."); // fallthrough
                        _ = strcat(aimBuffer, "e+");
                        exponentSignLocation = @intCast(strlen(aimBuffer) - 1);
                        nimNumberPart = NP_REAL_EXPONENT;
                    },
                    NP_REAL_FLOAT_PART => {
                        _ = strcat(aimBuffer, "e+");
                        exponentSignLocation = @intCast(strlen(aimBuffer) - 1);
                        nimNumberPart = NP_REAL_EXPONENT;
                    },
                    NP_COMPLEX_INT_PART => {
                        _ = strcat(aimBuffer, "."); // fallthrough
                        _ = strcat(aimBuffer, "e+");
                        imaginaryExponentSignLocation = @intCast(strlen(aimBuffer) - 1);
                        nimNumberPart = NP_COMPLEX_EXPONENT;
                    },
                    NP_COMPLEX_FLOAT_PART => {
                        _ = strcat(aimBuffer, "e+");
                        imaginaryExponentSignLocation = @intCast(strlen(aimBuffer) - 1);
                        nimNumberPart = NP_COMPLEX_EXPONENT;
                    },
                    else => {},
                }
            },

            ITM_HASH_JM, ITM_toINT => { // #
                done = true;
                frontier_screen.setLastintegerBasetoZero();
                if (nimNumberPart == NP_INT_10 or nimNumberPart == NP_INT_16) {
                    _ = strcat(aimBuffer, "#");
                    nimNumberPart = NP_INT_BASE;
                } else if (nimNumberPart == NP_INT_BASE) { // a second # clears the base typed after the first
                    while (strlen(aimBuffer) != 0 and aimBuffer[strlen(aimBuffer) - 1] != '#') {
                        aimBuffer[strlen(aimBuffer) - 1] = 0;
                    }
                }
            },

            ITM_CHS => { // +/-
                done = true;
                switch (nimNumberPart) {
                    NP_INT_10, NP_INT_16, NP_INT_BASE, NP_REAL_FLOAT_PART, NP_HP32SII_DENOMINATOR, NP_FRACTION_DENOMINATOR => {
                        if (aimBuffer[0] == '+') {
                            aimBuffer[0] = '-';
                        } else {
                            aimBuffer[0] = '+';
                        }
                    },
                    NP_REAL_EXPONENT => {
                        if (aimBuffer[@intCast(exponentSignLocation)] == '+') {
                            aimBuffer[@intCast(exponentSignLocation)] = '-';
                            if (aimBuffer[@intCast(exponentSignLocation + 1)] == '0') {
                                aimBuffer[strlen(aimBuffer) - 1] = 0;
                            }
                        } else {
                            aimBuffer[@intCast(exponentSignLocation)] = '+';
                        }
                    },
                    NP_COMPLEX_INT_PART, NP_COMPLEX_FLOAT_PART, NP_COMPLEX_HP32SII_DENOMINATOR, NP_COMPLEX_FRACTION_DENOMINATOR => {
                        if (aimBuffer[@intCast(imaginaryMantissaSignLocation)] == '+') {
                            aimBuffer[@intCast(imaginaryMantissaSignLocation)] = '-';
                        } else {
                            aimBuffer[@intCast(imaginaryMantissaSignLocation)] = '+';
                        }
                    },
                    NP_COMPLEX_EXPONENT => {
                        if (aimBuffer[@intCast(imaginaryExponentSignLocation)] == '+') {
                            aimBuffer[@intCast(imaginaryExponentSignLocation)] = '-';
                            if (aimBuffer[@intCast(imaginaryExponentSignLocation + 1)] == '0') {
                                aimBuffer[strlen(aimBuffer) - 1] = 0;
                            }
                        } else {
                            aimBuffer[@intCast(imaginaryExponentSignLocation)] = '+';
                        }
                    },
                    else => {},
                }
            },

            ITM_op_j_pol, ITM_op_j, ITM_CC => {
                if (item == ITM_op_j or item == ITM_op_j_pol) {
                    resetShiftState();
                    // The key sets the form, as fnKeyCC does before ITM_CC.
                    temporaryFlagRect = @intFromBool(item == ITM_op_j);
                    temporaryFlagPolar = @intFromBool(item == ITM_op_j_pol);
                }
                lastChar = @intCast(strlen(aimBuffer) - 1);
                done = true;
                frontier_screen.setLastintegerBasetoZero();
                switch (nimNumberPart) {
                    NP_REAL_EXPONENT => {
                        if ((aimBuffer[@intCast(lastChar)] == '+' or aimBuffer[@intCast(lastChar)] == '-') and aimBuffer[@intCast(lastChar - 1)] == 'e') {
                            aimBuffer[@intCast(lastChar - 1)] = 0;
                        } else if (aimBuffer[@intCast(lastChar)] == 'e') {
                            aimBuffer[@intCast(lastChar)] = 0;
                        } else {
                            imaginaryMantissaSignLocation = @intCast(strlen(aimBuffer));
                            _ = strcat(aimBuffer, "+i");
                            nimRealPart = nimNumberPart;
                            nimNumberPart = NP_COMPLEX_INT_PART;
                        }
                    },
                    NP_INT_10 => {
                        _ = strcat(aimBuffer, "."); // fallthrough
                        imaginaryMantissaSignLocation = @intCast(strlen(aimBuffer));
                        _ = strcat(aimBuffer, "+i");
                        nimRealPart = nimNumberPart;
                        nimNumberPart = NP_COMPLEX_INT_PART;
                    },
                    NP_REAL_FLOAT_PART, NP_FRACTION_DENOMINATOR, NP_HP32SII_DENOMINATOR => {
                        imaginaryMantissaSignLocation = @intCast(strlen(aimBuffer));
                        _ = strcat(aimBuffer, "+i");
                        nimRealPart = nimNumberPart;
                        nimNumberPart = NP_COMPLEX_INT_PART;
                    },
                    else => {},
                }
                // i or i∠ sets the unit of the angle: ADM for a polar entry when
                // NIMDRG is set, none otherwise, and never the unit DRG gave the real part.
                if (option_drg_cfg and nimComplexPart()) {
                    nimPolarAngularMode = amNone;
                    if (nimDrgChoosesUnit() and nimPolarEntry()) {
                        nimPolarAngularMode = @intCast(currentAngularMode);
                    }
                    if (calcMode == CM_NIM) {
                        setRegisterAngularMode(REGISTER_X, amNone);
                    }
                }
            },

            ITM_CONSTpi => {
                if (nimPiAfterI()) {
                    done = true;
                    frontier_items.reallyRunFunction(ITM_EXIT1, NOPARAM);
                    frontier_screen.setLastintegerBasetoZero();
                    return; // NIM is closed and the value is on the stack, skip the buffer-to-display conversion
                }
            },

            ITM_BACKSPACE => {
                lastChar = @intCast(strlen(aimBuffer) - 1);
                done = true;
                switch (nimNumberPart) {
                    NP_INT_10 => {},
                    NP_INT_16 => {
                        if (aimBuffer[@intCast(lastChar)] >= 'A') {
                            hexDigits -= 1;
                        }
                        if (hexDigits == 0) {
                            nimNumberPart = NP_INT_10;
                        }
                    },
                    NP_INT_BASE => {
                        if (aimBuffer[@intCast(lastChar)] == '#') {
                            if (hexDigits > 0) {
                                nimNumberPart = NP_INT_16;
                            } else {
                                nimNumberPart = NP_INT_10;
                            }
                        }
                    },
                    NP_REAL_FLOAT_PART => {
                        if (aimBuffer[@intCast(lastChar)] == '.') {
                            nimNumberPart = NP_INT_10;
                        }
                    },
                    NP_REAL_EXPONENT => {
                        if (aimBuffer[@intCast(lastChar)] == '+' or aimBuffer[@intCast(lastChar)] == '-') {
                            aimBuffer[@intCast(lastChar)] = 0;
                            lastChar -= 1;
                        }
                        if (aimBuffer[@intCast(lastChar)] == 'e') {
                            nimNumberPart = NP_INT_10;
                            var ii: i16 = 1;
                            while (ii < lastChar) : (ii += 1) {
                                if (aimBuffer[@intCast(ii)] == '.') {
                                    nimNumberPart = NP_REAL_FLOAT_PART;
                                    break;
                                }
                            }
                        }
                    },
                    NP_HP32SII_DENOMINATOR => {
                        if (aimBuffer[@intCast(lastChar)] == '/') {
                            nimNumberPart = NP_REAL_FLOAT_PART;
                            aimBuffer[@intCast(lastChar)] = '.';
                            lastChar += 1;
                        }
                    },
                    NP_FRACTION_DENOMINATOR => {
                        if (aimBuffer[@intCast(lastChar)] == '/') {
                            nimNumberPart = NP_REAL_FLOAT_PART;
                            var ii: i16 = 1;
                            while (ii < lastChar) : (ii += 1) {
                                if (aimBuffer[@intCast(ii)] == ' ') {
                                    aimBuffer[@intCast(ii)] = '.';
                                    break;
                                }
                            }
                        }
                    },
                    NP_COMPLEX_INT_PART => {
                        if (aimBuffer[@intCast(lastChar)] == 'i') {
                            nimNumberPart = nimRealPart;
                            lastChar -= 1;
                            if (nimNumberPart == NP_INT_10 and aimBuffer[@intCast(lastChar - 1)] == '.') {
                                lastChar -= 1;
                            }
                        }
                    },
                    NP_COMPLEX_FLOAT_PART => {
                        if (aimBuffer[@intCast(lastChar)] == '.') {
                            nimNumberPart = NP_COMPLEX_INT_PART;
                        }
                    },
                    NP_COMPLEX_EXPONENT => {
                        if (aimBuffer[@intCast(lastChar)] == '+' or aimBuffer[@intCast(lastChar)] == '-') {
                            aimBuffer[@intCast(lastChar)] = 0;
                            lastChar -= 1;
                        }
                        if (aimBuffer[@intCast(lastChar)] == 'e') {
                            nimNumberPart = NP_COMPLEX_INT_PART;
                            var ii: i16 = imaginaryMantissaSignLocation + 2;
                            while (ii < lastChar) : (ii += 1) {
                                if (aimBuffer[@intCast(ii)] == '.') {
                                    nimNumberPart = NP_COMPLEX_FLOAT_PART;
                                    break;
                                }
                            }
                        }
                    },
                    NP_COMPLEX_HP32SII_DENOMINATOR => {
                        if (aimBuffer[@intCast(lastChar)] == '/') {
                            nimNumberPart = NP_COMPLEX_FLOAT_PART;
                            aimBuffer[@intCast(lastChar)] = '.';
                            lastChar += 1;
                        }
                    },
                    NP_COMPLEX_FRACTION_DENOMINATOR => {
                        if (aimBuffer[@intCast(lastChar)] == '/') {
                            nimNumberPart = NP_COMPLEX_FLOAT_PART;
                            var ii: i16 = imaginaryMantissaSignLocation + 2;
                            while (ii < lastChar) : (ii += 1) {
                                if (aimBuffer[@intCast(ii)] == ' ') {
                                    aimBuffer[@intCast(ii)] = '.';
                                    break;
                                }
                            }
                        }
                    },
                    else => {},
                }

                aimBuffer[@intCast(lastChar)] = 0;
                lastChar -= 1;

                if ((calcMode != CM_MIM) and (lastChar == -1 or (lastChar == 0 and aimBuffer[0] == '+'))) {
                    screenUpdatingMode &= ~@as(u8, SCRUPD_SKIP_STACK_ONE_TIME);
                    frontier_calc_mode.calcModeNormal();
                    undo();
                }
            },

            ITM_EXIT1 => {
                done = true;
                screenUpdatingMode &= ~@as(u8, SCRUPD_SKIP_STACK_ONE_TIME);
                closeNim();
                if (lastErrorCode != 0) {
                    return; // closeNim rejected buffer; skip display rebuild
                }
                if (calcMode != CM_NIM and lastErrorCode == 0) {
                    // IR_PRINTING: Close NIM ended with entering the value on the stack
                    frontier_print.printTrace(ITM_ENTER, NOPARAM);
                    setSystemFlag(FLAG_ASLIFT);
                    if (item == ITM_EXIT1) {
                        saveForUndo();
                        if (lastErrorCode == ERROR_RAM_FULL) {
                            lastErrorCode = 0;
                            temporaryInformation = TI_UNDO_DISABLED;
                            moreInfoOnErr("In function addItemToNimBuffer:", "there is not enough memory to save for undo!");
                        }
                    }
                    return;
                }
                if (item == ITM_EXIT1) {
                    saveForUndo();
                    if (lastErrorCode == ERROR_RAM_FULL) {
                        lastErrorCode = 0;
                        temporaryInformation = TI_UNDO_DISABLED;
                        moreInfoOnErr("In function addItemToNimBuffer:", "there is not enough memory to save for undo!");
                    }
                }
            },

            ITM_1ONX, ITM_SQUAREROOTX => { // C47: B / R47:
                if ((!isR47FAM() and item == ITM_SQUAREROOTX) or (isR47FAM() and item == ITM_1ONX)) {
                    keyActionProcessed = 0;
                } else if (integerShortcuts() and nimNumberPart == NP_INT_BASE and aimBuffer[strlen(aimBuffer) - 1] == '#') {
                    _ = strcat(aimBuffer, "2");
                    {
                        done = true;
                        if (nimExitCloseFromGoto()) return;
                        break :sw;
                    }
                } else {
                    keyActionProcessed = 0;
                }
            },

            ITM_ENTER, ITM_LOG10, ITM_YX => { // D: decimal base
                if ((!isR47FAM() and item == ITM_YX) or (isR47FAM() and item == ITM_LOG10)) {
                    keyActionProcessed = 0;
                } else if (integerShortcuts() and nimNumberPart == NP_INT_BASE and aimBuffer[strlen(aimBuffer) - 1] == '#') {
                    _ = strcat(aimBuffer, "10");
                    {
                        done = true;
                        if (nimExitCloseFromGoto()) return;
                        break :sw;
                    }
                } else {
                    keyActionProcessed = 0;
                }
            },

            ITM_RCL => { // H for hexadecimal base
                if (integerShortcuts() and nimNumberPart == NP_INT_BASE and aimBuffer[strlen(aimBuffer) - 1] == '#') {
                    _ = strcat(aimBuffer, "16");
                    {
                        done = true;
                        if (nimExitCloseFromGoto()) return;
                        break :sw;
                    }
                } else {
                    keyActionProcessed = 0;
                }
            },

            ITM_Rdown => { // I for longinteger
                if (integerShortcuts() and nimNumberPart == NP_INT_BASE and aimBuffer[strlen(aimBuffer) - 1] == '#') {
                    aimBuffer[strlen(aimBuffer) - 1] = 0;
                    nimNumberPart = NP_INT_10;
                    {
                        done = true;
                        if (nimExitCloseFromGoto()) return;
                        break :sw;
                    }
                } else {
                    keyActionProcessed = 0;
                }
            },

            ITM_DMS => {
                if (nimNumberPart == NP_INT_10 or nimNumberPart == NP_REAL_FLOAT_PART) {
                    done = true;
                    frontier_screen.setLastintegerBasetoZero();
                    screenUpdatingMode &= ~@as(u8, SCRUPD_SKIP_STACK_ONE_TIME);
                    closeNim();
                    if (calcMode != CM_NIM and lastErrorCode == 0) {
                        if (getRegisterDataType(REGISTER_X) == dtLongInteger) {
                            frontier_register_value_conversions.convertLongIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
                        }
                        frontier_conversion_angles.real34FromDmsToDeg(reg34(REGISTER_X), reg34(REGISTER_X));
                        setRegisterAngularMode(REGISTER_X, amDMS);
                        setSystemFlag(FLAG_ASLIFT);
                        // IR_PRINTING
                        frontier_print.printTraceX(LINE_NOLF);
                        frontier_print.printTrace(ITM_ENTER, NOPARAM);
                        return;
                    }
                }
            },

            ITM_dotD => {
                var xangularMode: angularMode_t = if ((getRegisterDataType(REGISTER_X) == dtReal34) == (dtReal34 != 0)) getRegisterAngularMode(REGISTER_X) else amNone;
                if (xangularMode < amNone) { // If editing with angular mode, then cancel angular mode
                    xangularMode = amNone;
                } else if (nimNumberPart == NP_REAL_FLOAT_PART) {
                    done = true;
                    screenUpdatingMode &= ~@as(u8, SCRUPD_SKIP_STACK_ONE_TIME);

                    const tmplen: i16 = @intCast(stringByteLength(aimBuffer));
                    if ((lastCenturyHighUsed & YY_MASK_OFF) == 0 and getSystemFlag(FLAG_YMD) == 0 and ((tmplen == 8 and (frontier_char_string.isValidNumber(aimBuffer, "sdd.dddd"))) or (tmplen == 7 and (frontier_char_string.isValidNumber(aimBuffer, "sd.dddd"))))) {
                        aimBuffer[@intCast(tmplen)] = aimBuffer[@intCast(tmplen - 2)];
                        aimBuffer[@intCast(tmplen + 1)] = aimBuffer[@intCast(tmplen - 1)];
                        aimBuffer[@intCast(tmplen - 2)] = '0';
                        aimBuffer[@intCast(tmplen - 1)] = '0';
                        aimBuffer[@intCast(tmplen + 2)] = 0;
                    }

                    closeNim();
                    if (calcMode != CM_NIM and lastErrorCode == 0 and getRegisterDataType(REGISTER_X) != dtDate) {
                        frontier_register_value_conversions.convertReal34RegisterToDateRegister(REGISTER_X, REGISTER_X, YYSystem != 0);
                        frontier_date_time.checkDateRange(reg34(REGISTER_X));
                        temporaryInformation = TI_DAY_OF_WEEK;
                        if (lastErrorCode == 0) {
                            setSystemFlag(FLAG_ASLIFT);
                            // IR_PRINTING
                            frontier_print.printTraceX(LINE_NOLF);
                            frontier_print.printTrace(ITM_ENTER, NOPARAM);
                        } else {
                            undo();
                        }
                        return;
                    }
                } else if (nimNumberPart == NP_INT_10 and lastIntegerBase == 0) {
                    nimNumberPart = NP_REAL_FLOAT_PART;
                    closeNim();
                    return;
                } else if (nimNumberPart == NP_REAL_EXPONENT) {
                    closeNim();
                    return;
                }
            },

            ITM_ms => {
                if (nimNumberPart == NP_INT_10 or nimNumberPart == NP_REAL_FLOAT_PART or nimNumberPart == NP_REAL_EXPONENT) {
                    done = true;
                    frontier_screen.setLastintegerBasetoZero();
                    screenUpdatingMode &= ~@as(u8, SCRUPD_SKIP_STACK_ONE_TIME);
                    closeNim();
                    if (calcMode != CM_NIM and lastErrorCode == 0 and getRegisterDataType(REGISTER_X) != dtTime) {
                        if (getRegisterDataType(REGISTER_X) == dtLongInteger) {
                            frontier_register_value_conversions.convertLongIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
                        }
                        frontier_date_time.hmmssInRegisterToSeconds(REGISTER_X);
                        if (lastErrorCode == 0) {
                            setSystemFlag(FLAG_ASLIFT);
                            frontier_print.printTraceX(LINE_NOLF);
                            frontier_print.printTrace(ITM_ENTER, NOPARAM);
                        } else {
                            undo();
                        }
                        return;
                    }
                }
            },

            ITM_DMS2 => {
                if (nimNumberPart == NP_INT_10 or nimNumberPart == NP_REAL_FLOAT_PART or nimNumberPart == NP_REAL_EXPONENT) {
                    done = true;
                    closeNim();
                    if (calcMode != CM_NIM and lastErrorCode == 0) {
                        // it cannot be an angle at this point: a closed input is only a real or a long integer
                        frontier_addons.fnAngularModeJM(amDMS);
                        // IR_PRINTING
                        frontier_print.printTrace(ITM_DMS2, NOPARAM);
                        frontier_print.printTraceX(LINE_FULL_C);
                        return;
                    }
                }
            },

            ITM_DRG => {
                DRG_Cycling = 0;
                if (option_drg_cfg and nimDrgChoosesUnit()) {
                    done = true;
                    if (nimComplexPart()) { // no unit is a rectangular entry, a unit is a polar entry with its angle in that unit
                        var unit: u16 = nimPolarAngularMode;
                        frontier_addons.DRG_cycNim(&unit);
                        nimPolarAngularMode = @intCast(unit);
                        temporaryFlagRect = @intFromBool(unit == amNone);
                        temporaryFlagPolar = @intFromBool(unit != amNone);
                    } else { // the tag of X is the unit closeNim gives the number
                        var unit: u16 = @intCast(getRegisterAngularMode(REGISTER_X));
                        frontier_addons.DRG_cycNim(&unit);
                        setRegisterAngularMode(REGISTER_X, unit);
                    }
                    break :sw;
                }
                if (nimNumberPart == NP_INT_10 or nimNumberPart == NP_REAL_FLOAT_PART or nimNumberPart == NP_REAL_EXPONENT) {
                    done = true;
                    closeNim();
                    if (calcMode != CM_NIM and lastErrorCode == 0) {
                        copySourceRegisterToDestRegister(REGISTER_X, TEMP_REGISTER_1);
                        if (getRegisterDataType(REGISTER_X) == dtLongInteger) {
                            frontier_register_value_conversions.convertLongIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
                        }
                        if (getRegisterDataType(REGISTER_X) == dtReal34 and getRegisterAngularMode(REGISTER_X) == amNone) {
                            if (currentAngularMode == amDMS) {
                                frontier_conversion_angles.fnCvtFromCurrentAngularMode(amDMS);
                            } else if (currentAngularMode == amMultPi) {
                                frontier_conversion_angles.fnCvtFromCurrentAngularMode(amMultPi);
                            } else {
                                setRegisterAngularMode(REGISTER_X, currentAngularMode);
                            }
                        }
                        if (lastErrorCode == 0) {
                            setSystemFlag(FLAG_ASLIFT);
                            frontier_print.printTraceX(LINE_NOLF);
                            frontier_print.printTrace(ITM_ENTER, NOPARAM);
                        } else {
                            undo();
                        }
                        copySourceRegisterToDestRegister(TEMP_REGISTER_1, REGISTER_L);
                        return;
                    }
                }
            },

            ITM_NOP => {
                if (option_drg_cfg and calcMode == CM_PEM) { // the display follows a literal type DRG changed
                    done = true;
                }
            },

            else => {
                keyActionProcessed = 0;
            },
        }

        if (done) {
            // Convert nimBuffer to display string
            _ = strcpy(nimBufferDisplay, STD_SPACE_HAIR);

            switch (nimNumberPart) {
                NP_INT_10, NP_INT_16, NP_INT_BASE => {
                    nimBufferToDisplayBuffer(aimBuffer, nimBufferDisplay + 2);
                },
                NP_REAL_FLOAT_PART => {
                    nimBufferToDisplayBuffer(aimBuffer, nimBufferDisplay + 2);
                },
                NP_REAL_EXPONENT => {
                    nimRealToDisplayBuffer(aimBuffer, exponentSignLocation, nimBufferDisplay + 2);
                },
                NP_HP32SII_DENOMINATOR, NP_FRACTION_DENOMINATOR => {
                    nimFractionToDisplayBuffer(aimBuffer, nimBufferDisplay + 2);
                },
                NP_COMPLEX_INT_PART, NP_COMPLEX_FLOAT_PART, NP_COMPLEX_EXPONENT, NP_COMPLEX_HP32SII_DENOMINATOR, NP_COMPLEX_FRACTION_DENOMINATOR => {
                    // Real part
                    savedNimNumberPart = nimNumberPart;
                    nimNumberPart = nimRealPart;

                    if (nimNumberPart == NP_FRACTION_DENOMINATOR or nimNumberPart == NP_HP32SII_DENOMINATOR) {
                        nimFractionToDisplayBuffer(aimBuffer, nimBufferDisplay + 2);
                    } else {
                        nimRealToDisplayBuffer(aimBuffer, exponentSignLocation, nimBufferDisplay + 2);
                    }

                    nimNumberPart = savedNimNumberPart;
                    // Complex "separator"
                    if (nimPolarEntry()) { // polar mode
                        _ = strcat(nimBufferDisplay, STD_SPACE_4_PER_EM ++ STD_MEASURED_ANGLE ++ STD_SPACE_4_PER_EM);
                        if (aimBuffer[@intCast(imaginaryMantissaSignLocation)] == '-') {
                            _ = strcat(nimBufferDisplay, "-");
                        }
                    } else { // rectangular mode
                        if (strncmp(nimBufferDisplay + @as(usize, @intCast(stringByteLength(nimBufferDisplay) - 2)), STD_SPACE_HAIR, 2) != 0) {
                            _ = strcat(nimBufferDisplay, STD_SPACE_HAIR);
                        }
                        if (aimBuffer[@intCast(imaginaryMantissaSignLocation)] == '-') {
                            _ = strcat(nimBufferDisplay, "-");
                        } else {
                            _ = strcat(nimBufferDisplay, "+");
                        }
                        _ = strcat(nimBufferDisplay, complexUnit());
                        _ = strcat(nimBufferDisplay, productSign());
                    }

                    // Imaginary part
                    if (aimBuffer[@intCast(imaginaryMantissaSignLocation + 2)] != 0) {
                        if (nimNumberPart == NP_COMPLEX_FRACTION_DENOMINATOR or nimNumberPart == NP_COMPLEX_HP32SII_DENOMINATOR) {
                            nimFractionToDisplayBuffer(aimBuffer + @as(usize, @intCast(imaginaryMantissaSignLocation)) + 1, nimBufferDisplay + @as(usize, @intCast(stringByteLength(nimBufferDisplay))));
                        } else {
                            nimRealToDisplayBuffer(aimBuffer + @as(usize, @intCast(imaginaryMantissaSignLocation)) + 1, imaginaryExponentSignLocation - imaginaryMantissaSignLocation - 1, nimBufferDisplay + @as(usize, @intCast(stringByteLength(nimBufferDisplay))));
                        }
                    }
                },
                else => {
                    abi.fmtBufZ(errorMessage[0..512], "In function addItemToNimBuffer: {d} is an unexpected nimNumberPart value while converting buffer to display!", .{@as(i32, nimNumberPart)});
                    frontier_error.displayBugScreen(errorMessage);
                },
            }
            const _len: u16 = @intCast(stringByteLength(nimBufferDisplay));
            if (radix34MarkByte0() != '.') {
                index = @intCast(_len - 1);
                while (index > 0) : (index -= 1) {
                    if (nimBufferDisplay[@intCast(index)] == '.') {
                        nimBufferDisplay[@intCast(index)] = radix34MarkByte0();
                        if (radix34MarkByte1() != 1) {
                            var index2: u16 = _len;
                            while (index2 >= @as(u16, @intCast(index))) : (index2 -%= 1) {
                                nimBufferDisplay[index2 + 1] = nimBufferDisplay[index2];
                            }
                            nimBufferDisplay[@intCast(index + 1)] = radix34MarkByte1();
                        }
                    }
                }
            }
            index = @intCast(stringByteLength(nimBufferDisplay) - 1);
            while (index > 0) : (index -= 1) {
                if (nimBufferDisplay[@intCast(index)] == @as(u8, 0xab)) {
                    const sep = separatorLeft();
                    nimBufferDisplay[@intCast(index)] = sep.b0;
                    if (nimBufferDisplay[@intCast(index + 1)] == 1) {
                        nimBufferDisplay[@intCast(index + 1)] = sep.b1;
                    }
                }
                if (nimBufferDisplay[@intCast(index)] == @as(u8, 0xbb)) {
                    const sep = separatorRight();
                    nimBufferDisplay[@intCast(index)] = sep.b0;
                    if (nimBufferDisplay[@intCast(index + 1)] == 1) {
                        nimBufferDisplay[@intCast(index + 1)] = sep.b1;
                    }
                }
            }
        } else if (item != ITM_NOP) {
            // PC_BUILD && VERBOSE_MINIMUM: defined for the simulator, undefined for
            // the testSuite.
            if (comptime !dmcp_build and !is_testsuite_build) {
                _ = printf("addItemToNimBuffer: delayCloseNim=%u\n", @as(c_uint, delayCloseNim));
                _ = fflush(null);
            }
            if (delayCloseNim == 0) {
                switch (item) {
                    ITM_HASH_JM, ITM_toINT, -MNU_BASE, -MNU_INTS, -MNU_BITS => {},
                    else => {
                        screenUpdatingMode &= ~@as(u8, SCRUPD_SKIP_STACK_ONE_TIME);
                        closeNim();
                        if (calcMode == CM_NIM and item > 0) {
                            // Close refused, NIM stays open: a function does
                            // nothing more, a menu still opens.
                            keyActionProcessed = 1;
                        }
                    },
                }
            }
            if (calcMode != CM_NIM) {
                if (item == ITM_CONSTpi or (item >= 0 and indexOfItems[@intCast(item)].func == fnConstantPtr())) {
                    setSystemFlag(FLAG_ASLIFT);
                    frontier_screen.setLastintegerBasetoZero();
                }
                if (lastErrorCode == 0) {
                    frontier_screen.showFunctionName(item, 1000, null);
                }
            }
        }
    } // addItemToNimBuffer_exit
}
