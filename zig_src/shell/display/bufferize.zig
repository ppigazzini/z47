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
//   * PC_BUILD-only debug printf / jm_show_calc_state / VERBOSE_MINIMUM blocks are
//     host-only (gated on !dmcp_build).
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
const builtin = @import("builtin");
const frontier_build_options = @import("frontier_build_options");
const extra_info: bool = frontier_build_options.extra_info_on_calc_error;
const dmcp_build: bool = frontier_build_options.dmcp_build;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const bool_t = u8;
const calcRegister_t = i16;
const angularMode_t = c_int;

const DECNUMUNITS = 25;
const abi = @import("abi"); // L1 shared bindings (REPORT-23 §5)
const gap_insert = @import("text/gap_insert.zig"); // std-only digit-group gap insertion
const frontier = @import("../shell.zig"); // M-callconv: Zig-to-Zig
const frontier_addons = @import("../extensions/addons.zig"); // M-callconv: Zig-to-Zig
const frontier_calc_mode = @import("../calc_mode.zig"); // M-callconv: Zig-to-Zig
const frontier_char_string = @import("text/char_string.zig"); // M-callconv: Zig-to-Zig
const frontier_conversion_angles = @import("../convert/conversion_angles.zig"); // M-callconv: Zig-to-Zig
const frontier_date_time = @import("../convert/date_time.zig"); // M-callconv: Zig-to-Zig
const frontier_debug = @import("../debug.zig"); // M-callconv: Zig-to-Zig
const frontier_display = @import("display.zig"); // M-callconv: Zig-to-Zig
const frontier_error = @import("../error.zig"); // M-callconv: Zig-to-Zig
const frontier_items = @import("items/items.zig"); // M-callconv: Zig-to-Zig
const frontier_manage = @import("../program/manage.zig"); // M-callconv: Zig-to-Zig
const frontier_print = @import("../print/print.zig"); // M-callconv: Zig-to-Zig
const frontier_radio_button_catalog = @import("../extensions/radio_button_catalog.zig"); // M-callconv: Zig-to-Zig
const frontier_register_value_conversions = @import("../register_value_conversions.zig"); // M-callconv: Zig-to-Zig
const frontier_screen = @import("screen.zig"); // M-callconv: Zig-to-Zig
const frontier_softmenus = @import("softmenus/softmenus.zig"); // M-callconv: Zig-to-Zig
const frontier_sort = @import("sort.zig"); // M-callconv: Zig-to-Zig
const frontier_status_bar = @import("statusbar/status_bar.zig"); // M-callconv: Zig-to-Zig
const frontier_tam = @import("../input/tam.zig"); // M-callconv: Zig-to-Zig
const frontier_timer = @import("../timer.zig"); // M-callconv: Zig-to-Zig
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
const ITM_ACUStoHA = 238;
const ITM_ACtoHA = 234;
const ITM_ALL = 1410;
const ITM_ALOG_SIGN = 999;
const ITM_ARG = 1706;
const ITM_ATMtoPA = 243;
const ITM_AUtoM = 244;
const ITM_B = 551;
const ITM_BACKSPACE = 1738;
const ITM_BARRELtoM3 = 364;
const ITM_BARtoPA = 246;
const ITM_BATT = 1413;
const ITM_BESTFQ = 1435;
const ITM_BN = 1416;
const ITM_BNS = 1417;
const ITM_BRDStoIN = 2181;
const ITM_BRDStoM = 2175;
const ITM_BTUtoJ = 248;
const ITM_C = 552;
const ITM_CALtoJ = 250;
const ITM_CARATtoG = 350;
const ITM_CC = 1730;
const ITM_CEIL = 87;
const ITM_CF = 110;
const ITM_CHItoM = 376;
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
const ITM_CUNtoM = 380;
const ITM_CUPCtoFZUS = 285;
const ITM_CUPCtoML = 287;
const ITM_CUPUKtoFZUK = 297;
const ITM_CUPUKtoML = 299;
const ITM_CWTtoKG = 256;
const ITM_CtoF = 220;
const ITM_D = 553;
const ITM_DAY = 1440;
const ITM_DBtoFR = 225;
const ITM_DBtoPR = 222;
const ITM_DECR = 91;
const ITM_DEG = 1445;
const ITM_DEGPStoRPM = 2089;
const ITM_DEGtoGRAD = 2098;
const ITM_DEGtoRAD = 2096;
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
const ITM_EQUAL = 825;
const ITM_ERF = 1466;
const ITM_ERFC = 1467;
const ITM_EX1 = 1575;
const ITM_EXIT1 = 1737;
const ITM_EXP = 65;
const ITM_EXPONENT = 990;
const ITM_EXPT = 1470;
const ITM_Ek = 1727;
const ITM_F = 555;
const ITM_FATHOMtoM = 358;
const ITM_FENtoM = 386;
const ITM_FF = 112;
const ITM_FIB = 1472;
const ITM_FIRtoKG = 2177;
const ITM_FIRtoLB = 2183;
const ITM_FIX = 1473;
const ITM_FLOOR = 88;
const ITM_FP = 94;
const ITM_FPFtoKPH = 2179;
const ITM_FPFtoMPH = 2185;
const ITM_FPFtoMPS = 2173;
const ITM_FPStoKMH = 2187;
const ITM_FPStoMPS = 2189;
const ITM_FRtoDB = 231;
const ITM_FT2toHA = 223;
const ITM_FT2toM2 = 226;
const ITM_FT3toGLUK = 239;
const ITM_FT3toGalUS = 271;
const ITM_FT3toL = 255;
const ITM_FTNtoS = 2171;
const ITM_FTUStoM = 260;
const ITM_FTtoM = 258;
const ITM_FURtoM = 2169;
const ITM_FZUKtoCUPUK = 301;
const ITM_FZUKtoGLUK = 233;
const ITM_FZUKtoIN3 = 265;
const ITM_FZUKtoML = 266;
const ITM_FZUKtoTBSPUK = 303;
const ITM_FZUKtoTSPUK = 305;
const ITM_FZUStoCUPC = 306;
const ITM_FZUStoGLUS = 1903;
const ITM_FZUStoIN3 = 269;
const ITM_FZUStoML = 270;
const ITM_FZUStoTBSPC = 308;
const ITM_FZUStoTSPC = 309;
const ITM_FtoC = 221;
const ITM_GAMMAX = 1664;
const ITM_GD = 1478;
const ITM_GDM1 = 1479;
const ITM_GET_ADM = 2763;
const ITM_GET_DMX = 1558;
const ITM_GET_ISM = 1606;
const ITM_GET_NDEC = 2768;
const ITM_GET_REALDF = 2766;
const ITM_GLUKtoFT3 = 241;
const ITM_GLUKtoFZUK = 232;
const ITM_GLUKtoL = 274;
const ITM_GLUStoFZUS = 1902;
const ITM_GLUStoL = 276;
const ITM_GRAD = 1480;
const ITM_GRADtoDEG = 2099;
const ITM_GRADtoRAD = 2100;
const ITM_GalUStoFT3 = 273;
const ITM_GtoCARAT = 353;
const ITM_GtoOZ = 294;
const ITM_GtoTRZ = 316;
const ITM_HASH_JM = 1872;
const ITM_HAtoAC = 236;
const ITM_HAtoACUS = 240;
const ITM_HAtoFT2 = 224;
const ITM_HAtoKM2 = 229;
const ITM_HECTAREtoM2 = 370;
const ITM_HMStoHR = 367;
const ITM_HPEtoW = 278;
const ITM_HPMtoW = 280;
const ITM_HPUKtoW = 282;
const ITM_HRtoHMS = 368;
const ITM_HRtoTM = 1686;
const ITM_IM = 1485;
const ITM_IN3toFZUK = 264;
const ITM_IN3toFZUS = 267;
const ITM_IN3toML = 237;
const ITM_INC = 92;
const ITM_INCHHGtoPA = 284;
const ITM_INCHtoCM = 2163;
const ITM_INCHtoMM = 288;
const ITM_INDIRECTION = 539;
const ITM_INDIRECT_T = 2418;
const ITM_INDIRECT_X = 2415;
const ITM_INDIRECT_Y = 2416;
const ITM_INDIRECT_Z = 2417;
const ITM_INFINITY = 924;
const ITM_INtoBRDS = 2182;
const ITM_IP = 93;
const ITM_IRFRAC = 2056;
const ITM_JINtoKG = 352;
const ITM_JtoBTU = 249;
const ITM_JtoCAL = 251;
const ITM_JtoDT = 1863;
const ITM_JtoWH = 291;
const ITM_K100KtoK100M = 2214;
const ITM_K100KtoKMK = 2208;
const ITM_K100KtoKMLE = 2207;
const ITM_K100MtoK100K = 2215;
const ITM_K100MtoMGEUK = 2219;
const ITM_K100MtoMGEUS = 2213;
const ITM_K100MtoMIK = 2220;
const ITM_KGtoCWT = 257;
const ITM_KGtoFIR = 2178;
const ITM_KGtoJIN = 355;
const ITM_KGtoLBS = 292;
const ITM_KGtoLIANG = 311;
const ITM_KGtoSCW = 296;
const ITM_KGtoST = 304;
const ITM_KGtoSTO = 300;
const ITM_KGtoTON = 310;
const ITM_KM2toHA = 230;
const ITM_KM2toMI2 = 389;
const ITM_KM2toNMI2 = 391;
const ITM_KMHtoFPS = 2188;
const ITM_KMHtoKNOT = 2085;
const ITM_KMHtoMPH = 2091;
const ITM_KMHtoMPS = 2086;
const ITM_KMKtoK100K = 2209;
const ITM_KMLEtoK100K = 2206;
const ITM_KMLtoL100 = 2205;
const ITM_KMtoMI = 329;
const ITM_KMtoNMI = 330;
const ITM_KNOTtoKMH = 2084;
const ITM_KPHtoFPF = 2180;
const ITM_Kk = 1726;
const ITM_L100toKML = 2204;
const ITM_L100toMGUK = 2216;
const ITM_L100toMGUS = 2210;
const ITM_LASTX = 1502;
const ITM_LBFFTtoNM = 252;
const ITM_LBFtoN = 320;
const ITM_LBStoKG = 293;
const ITM_LBtoFIR = 2184;
const ITM_LEFT_ARROW = 892;
const ITM_LG_SIGN = 2069;
const ITM_LIANGtoKG = 314;
const ITM_LItoM = 374;
const ITM_LN = 69;
const ITM_LN1X = 1614;
const ITM_LNGAMMA = 1508;
const ITM_LN_SIGN = 2070;
const ITM_LOG10 = 71;
const ITM_LOG2 = 68;
const ITM_LOGICALNOT = 123;
const ITM_LYtoM = 322;
const ITM_LocRQ = 1515;
const ITM_LtoFT3 = 253;
const ITM_LtoGLUK = 275;
const ITM_LtoGLUS = 277;
const ITM_LtoQT = 357;
const ITM_LtoQTUS = 261;
const ITM_M1X = 1679;
const ITM_M2toFT2 = 227;
const ITM_M2toHECTARE = 371;
const ITM_M2toMU = 373;
const ITM_M3toBARREL = 366;
const ITM_MAGNITUDE = 105;
const ITM_MANT = 1517;
const ITM_MEM = 1519;
const ITM_MGEUKtoK100M = 2218;
const ITM_MGEUStoK100M = 2212;
const ITM_MGUKtoL100 = 2217;
const ITM_MGUStoL100 = 2211;
const ITM_MI2toKM2 = 388;
const ITM_MIKtoK100M = 2221;
// Conversion items (C MimFunctionsType3Conv) merged into MimFunctionsType2 so
// unit-conversion functions are live keys in Matrix Input Mode. Values from
// src/c47/items.h, cross-checked against conversionUnits.c + the conversion owner.
const ITM_CMtoINCH = 2164;
const ITM_EVtoJ = 2464;
const ITM_JtoEV = 2465;
const ITM_BANANAtoINCH = 2466;
const ITM_INCHtoBANANA = 2467;
const ITM_BANANAtoMM = 2468;
const ITM_MMtoBANANA = 2469;
const ITM_ERGtoJ = 2658;
const ITM_JtoERG = 2659;
const ITM_FoetoJ = 2660;
const ITM_JtoFoe = 2661;
const ITM_CtoK = 2665;
const ITM_KtoC = 2666;
const ITM_RAtoK = 2667;
const ITM_KtoRA = 2668;
const ITM_RAtoF = 2669;
const ITM_FtoRA = 2670;
const ITM_EVKBtoK = 2671;
const ITM_KtoEVKB = 2672;
const ITM_FtoK = 2673;
const ITM_KtoF = 2674;
const ITM_KNOTtoMPS = 2743;
const ITM_MPStoKNOT = 2744;
const ITM_DEGPStoRADPS = 2745;
const ITM_RADPStoDEGPS = 2746;
const ITM_SLUGtoKG = 2747;
const ITM_KGtoSLUG = 2748;
const ITM_SLINCHtoKG = 2749;
const ITM_KGtoSLINCH = 2750;
const ITM_BLOBtoKG = 2751;
const ITM_KGtoBLOB = 2752;
const ITM_TONNEtoKG = 2753;
const ITM_KGtoTONNE = 2754;
const ITM_LBSFT2toPA = 2800;
const ITM_PAtoLBSFT2 = 2801;
const ITM_INLBStoNM = 2802;
const ITM_NMtoINLBS = 2803;
const ITM_LBSFTtoNPM = 2804;
const ITM_NPMtoLBSFT = 2805;
const ITM_KGFtoN = 2806;
const ITM_NtoKGF = 2807;
const ITM_MS2toFTS2 = 2808;
const ITM_FTS2toMS2 = 2809;
const ITM_MS2toINS2 = 2810;
const ITM_INS2toMS2 = 2811;
const ITM_KSItoMPA = 2812;
const ITM_MPAtoKSI = 2813;
const ITM_LBSIN3toBLOBIN3 = 2814;
const ITM_BLOBIN3toLBSIN3 = 2815;
const ITM_LBSIN3toTMM3 = 2816;
const ITM_TMM3toLBSIN3 = 2817;
const ITM_LBSIN3toKGM3 = 2818;
const ITM_KGM3toLBSIN3 = 2819;
const ITM_KGM3toBLOBIN3 = 2820;
const ITM_BLOBIN3toKGM3 = 2821;
const ITM_KGM3toTMM3 = 2822;
const ITM_TMM3toKGM3 = 2823;
const ITM_LBFTtoKGM = 2824;
const ITM_KGMtoLBFT = 2825;
const ITM_IN3toMM3 = 2826;
const ITM_MM3toIN3 = 2827;
const ITM_IN2toMM2 = 2828;
const ITM_MM2toIN2 = 2829;
const ITM_IN4toMM4 = 2830;
const ITM_MM4toIN4 = 2831;
const ITM_IN6toMM6 = 2832;
const ITM_MM6toIN6 = 2833;
const ITM_KGFPMtoNPM = 2834;
const ITM_NPMtoKGFPM = 2835;
const ITM_KGFtoLBF = 2836;
const ITM_LBFtoKGF = 2837;
const ITM_UNSLUGtoKG = 2838;
const ITM_KGtoUNSLUG = 2839;
const ITM_UNSLINCHtoKG = 2840;
const ITM_KGtoUNSLINCH = 2841;
const ITM_MILEtoM = 336;
const ITM_MINUS = 819;
const ITM_MItoKM = 328;
const ITM_MItoNMI = 2168;
const ITM_MLtoCUPC = 312;
const ITM_MLtoCUPUK = 315;
const ITM_MLtoFZUK = 268;
const ITM_MLtoFZUS = 272;
const ITM_MLtoIN3 = 235;
const ITM_MLtoPINTLQ = 317;
const ITM_MLtoPINTUK = 319;
const ITM_MLtoQT = 325;
const ITM_MLtoQTUS = 327;
const ITM_MLtoTBSPC = 335;
const ITM_MLtoTBSPUK = 338;
const ITM_MLtoTSPC = 345;
const ITM_MLtoTSPUK = 347;
const ITM_MMHGtoPA = 324;
const ITM_MMtoINCH = 289;
const ITM_MMtoPOINT = 334;
const ITM_MONTH = 1521;
const ITM_MPHtoFPF = 2186;
const ITM_MPHtoKMH = 2090;
const ITM_MPHtoMPS = 2092;
const ITM_MPStoFPF = 2174;
const ITM_MPStoFPS = 2190;
const ITM_MPStoKMH = 2087;
const ITM_MPStoMPH = 2093;
const ITM_MULPI = 1523;
const ITM_MUtoM2 = 372;
const ITM_MtoAU = 245;
const ITM_MtoBRDS = 2176;
const ITM_MtoCHI = 377;
const ITM_MtoCUN = 381;
const ITM_MtoFATHOM = 361;
const ITM_MtoFEN = 387;
const ITM_MtoFT = 259;
const ITM_MtoFTUS = 263;
const ITM_MtoFUR = 2170;
const ITM_MtoLI = 375;
const ITM_MtoLY = 323;
const ITM_MtoMILE = 339;
const ITM_MtoNMI = 363;
const ITM_MtoPC = 332;
const ITM_MtoYD = 340;
const ITM_MtoYIN = 379;
const ITM_MtoZHANG = 384;
const ITM_NEXTP = 107;
const ITM_NMI2toKM2 = 390;
const ITM_NMItoKM = 331;
const ITM_NMItoM = 360;
const ITM_NMItoMI = 2167;
const ITM_NMtoLBFFT = 254;
const ITM_NOP = 1542;
const ITM_NSIGMA = 435;
const ITM_NULL = 0;
const ITM_NtoLBF = 321;
const ITM_OBELUS = 857;
const ITM_OFF = 1543;
const ITM_OZtoG = 295;
const ITM_PAIR_OF_PARENTHESES = 997;
const ITM_PAtoATM = 242;
const ITM_PAtoBAR = 247;
const ITM_PAtoINCHHG = 286;
const ITM_PAtoMMHG = 326;
const ITM_PAtoPSI = 343;
const ITM_PAtoTOR = 344;
const ITM_PCtoM = 333;
const ITM_PERIOD = 820;
const ITM_PERM = 50;
const ITM_PINTLQtoML = 351;
const ITM_PINTUKtoML = 354;
const ITM_PLUS = 817;
const ITM_POINTtoMM = 337;
const ITM_PRtoDB = 228;
const ITM_PSItoPA = 342;
const ITM_QTUStoL = 262;
const ITM_QTUStoML = 362;
const ITM_QTtoL = 356;
const ITM_QTtoML = 359;
const ITM_RAD = 1557;
const ITM_RADPStoRPM = 2095;
const ITM_RADtoDEG = 2097;
const ITM_RADtoGRAD = 2101;
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
const ITM_RMODEQ = 2019;
const ITM_ROOT_SIGN = 1000;
const ITM_ROUND2 = 1868;
const ITM_ROUNDI2 = 1869;
const ITM_RPMtoDEGPS = 2088;
const ITM_RPMtoRADPS = 2094;
const ITM_RSD = 1577;
const ITM_Rdown = 40;
const ITM_SCI = 1587;
const ITM_SCWtoKG = 298;
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
const ITM_STOtoKG = 302;
const ITM_STtoKG = 307;
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
const ITM_SW = 1617;
const ITM_SXY = 1618;
const ITM_StoFTN = 2172;
const ITM_StoYEAR = 348;
const ITM_TAN_SIGN = 2073;
const ITM_TBSPCtoFZUS = 365;
const ITM_TBSPCtoML = 369;
const ITM_TBSPUKtoFZUK = 383;
const ITM_TBSPUKtoML = 385;
const ITM_TICKS = 1620;
const ITM_TONtoKG = 313;
const ITM_TORtoPA = 346;
const ITM_TRZtoG = 318;
const ITM_TSPCtoFZUS = 392;
const ITM_TSPCtoML = 393;
const ITM_TSPUKtoFZUK = 394;
const ITM_TSPUKtoML = 395;
const ITM_UNIT = 1867;
const ITM_UNITV = 1628;
const ITM_UP_ARROW = 893;
const ITM_VERTICAL_BAR = 998;
const ITM_WDAY = 1633;
const ITM_WHtoJ = 290;
const ITM_WM = 1635;
const ITM_WM1 = 1637;
const ITM_WP = 1636;
const ITM_WtoHPE = 279;
const ITM_WtoHPM = 281;
const ITM_WtoHPUK = 283;
const ITM_XFACT = 108;
const ITM_XTHROOT = 63;
const ITM_XW = 1642;
const ITM_YDtoM = 341;
const ITM_YEAR = 1647;
const ITM_YEARtoS = 349;
const ITM_YINtoM = 378;
const ITM_YX = 60;
const ITM_Z = 575;
const ITM_ZHANGtoM = 382;
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
const MNU_BASE = 1923;
const MNU_BITS = 1317;
const MNU_INTS = 1340;
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
// M22: named constants via the oracle-gated abi accessors (offsets verified by
// .github/project/check-constant-offsets.py) instead of raw blob @ptrCast.
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
extern var fnKeyInCatalog: bool_t;
extern var funcOK: bool_t;
extern var keyActionProcessed: bool_t;
extern var hourGlassIconEnabled: bool_t;
extern var temporaryFlagRect: bool_t;
extern var temporaryFlagPolar: bool_t;
extern var currentAngularMode: angularMode_t;
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
extern var gapItemRadix: u16;
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
extern fn fnSetFlag(flag: u16) void;
extern fn resetShiftState() void;
extern fn moreInfoOnError(m1: [*c]const u8, m2: [*c]const u8, m3: [*c]const u8, m4: [*c]const u8) void;
extern fn fnTimerStart(nr: u8, param: u16, time: u32) void;
extern fn isDyadicFunction(item: u16) bool;
extern fn stringToInt16(str: [*c]const u8) i16;
extern fn stringToInt32(str: [*c]const u8) i32;
extern fn toInt32(str: [*c]const u8) i32;
// stringCopy(dest, source) = stpcpy(dest, source) (charString.h, non-MINGW64).
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
inline fn stringCopy(dest: [*c]u8, source: [*c]const u8) [*c]u8 {
    return stpcpy(dest, source);
}
// stringToReal34(source, destination) = decQuadFromString(destination, source, &ctxtReal34).
extern fn decQuadFromString(r: *align(1) real34_t, str: [*c]const u8, ctx: *realContext_t) *align(1) real34_t;
inline fn stringToReal34(str: [*c]const u8, dst: *align(1) real34_t) void {
    _ = decQuadFromString(dst, str, &ctxtReal34);
}
extern fn getRegisterDataType(regist: calcRegister_t) u32;
extern fn getRegisterDataPointer(regist: calcRegister_t) [*c]u8;
extern fn getRegisterTag(regist: calcRegister_t) u32;
extern fn setRegisterTag(regist: calcRegister_t, tag: u32) void;
extern fn reallocateRegister(regist: calcRegister_t, dataType: u32, dataSizeWithoutDataLenBlocks: u16, tag: u32) void;
extern fn copySourceRegisterToDestRegister(rSource: calcRegister_t, rDest: calcRegister_t) void;
extern fn realPolarToRectangular(magnitude: *const real_t, theta: *const real_t, real: *real_t, imag: *real_t, realContext: *realContext_t) void;
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

// PC_BUILD-only debug hook (referenced only under !dmcp_build).
const jm_show_calc_state = if (!dmcp_build) @extern(*const fn (comment: [*c]u8) callconv(.c) void, .{ .name = "jm_show_calc_state" }) else {};

// ---------------------------------------------------------------------------
// Inline helpers (the C macros).
// ---------------------------------------------------------------------------
inline fn stringByteLength(str: [*c]const u8) i32 {
    return @intCast(strlen(str));
}
inline fn getRegisterAngularMode(reg: calcRegister_t) angularMode_t {
    return @intCast(getRegisterTag(reg) & amAngleMask);
}
inline fn setRegisterAngularMode(reg: calcRegister_t, am: angularMode_t) void {
    setRegisterTag(reg, @intCast(am));
}
// M22: typed register views centralized in abi (single @ptrCast per shape).
const reg34 = abi.registerReal34;
const regImag34 = abi.registerImag34;
const regShortInteger = abi.registerShortInteger;
const regString = abi.registerString;
inline fn toBlocks(n: u32) u16 {
    return @intCast((n + (BYTES_PER_BLOCK - 1)) >> BPB);
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
inline fn fnConstantPtr() ?*const fn (u16) callconv(.c) void {
    return &fnConstant;
}

// RADIX34_MARK_STRING = gapChar1Radix : first two bytes of the radix separator,
// byte[1]==1 meaning a single-byte separator.
fn radix34MarkBytes() TwoBytes {
    const s: [*c]const u8 = &indexOfItems[gapItemRadix].itemSoftmenuName;
    if (s[0] != 0 and (s[1] == 0 or (s[1] != 0 and s[2] == 0))) {
        switch (s[0]) {
            ',' => return .{ .b0 = ',', .b1 = 1 },
            '.' => return .{ .b0 = '.', .b1 = 1 },
            else => return .{ .b0 = s[0], .b1 = s[1] },
        }
    }
    return .{ .b0 = s[0], .b1 = s[1] };
}
inline fn radix34MarkByte0() u8 {
    return radix34MarkBytes().b0;
}
inline fn radix34MarkByte1() u8 {
    return radix34MarkBytes().b1;
}
inline fn separatorLeft() TwoBytes {
    return gapChar1Bytes(gapItemLeft);
}
inline fn separatorRight() TwoBytes {
    return gapChar1Bytes(gapItemRight);
}
const ERROR_MESSAGE_LENGTH: usize = 512;

// EXTRA_INFO console-hint helpers (compiled out on firmware, like the siblings).
inline fn moreInfoOnErr(where: [*c]const u8, hint: [*c]const u8) void {
    if (comptime extra_info) {
        if (comptime !dmcp_build) {
            moreInfoOnError(where, hint, null, null);
        }
    }
}
inline fn moreInfoOnErr3(where: [*c]const u8, hint: [*c]const u8, hint2: [*c]const u8) void {
    if (comptime extra_info) {
        if (comptime !dmcp_build) {
            moreInfoOnError(where, hint, hint2, null);
        }
    }
}

// COMPLEX_UNIT / PRODUCT_SIGN runtime macros.
inline fn complexUnit() [*c]const u8 {
    return if (getSystemFlag(FLAG_CPXj) != 0) STD_op_j else STD_op_i;
}
inline fn productSign() [*c]const u8 {
    return if (getSystemFlag(FLAG_MULTx) != 0) STD_CROSS else STD_DOT;
}

// isR47FAM / INTEGERSHORTCUTS runtime macros.
inline fn isR47FAM() bool {
    return calcModel == USER_R47f_g or calcModel == USER_R47bk_fg or calcModel == USER_R47fg_bk or calcModel == USER_R47fg_g;
}
inline fn integerShortcuts() bool {
    return (calcMode == CM_NIM or calcMode == CM_PEM) and (calcModel == USER_C47 or isR47FAM());
}

// real34/real arithmetic macros over decQuad/decNumber.
inline fn int32ToReal34(source: i32, destination: *real34_t) void {
    _ = decQuadFromInt32(destination, source);
}
inline fn real34Add(op1: *const real34_t, op2: *const real34_t, res: *real34_t) void {
    _ = decQuadAdd(res, op1, op2, &ctxtReal34);
}
inline fn real34Divide(op1: *const real34_t, op2: *const real34_t, res: *real34_t) void {
    _ = decQuadDivide(res, op1, op2, &ctxtReal34);
}
inline fn real34SetNegativeSign(operand: *real34_t) void {
    operand.bytes[15] |= 0x80;
}
inline fn real34SetZero(destination: *real34_t) void {
    _ = decQuadZero(destination);
}
inline fn real34ToReal(source: *const real34_t, destination: *real_t) void {
    _ = decimal128ToNumber(source, destination);
}
inline fn realToReal34(source: *const real_t, destination: *real34_t) void {
    _ = decimal128FromNumber(destination, source, &ctxtReal34);
}
inline fn realAdd(op1: *const real_t, op2: *const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberAdd(res, op1, op2, ctxt);
}
inline fn realSetPositiveSign(operand: *real_t) void {
    operand.bits &= 0x7F;
}

// longInteger (mpz) wrappers (longIntegerType.h).
inline fn longIntegerInit(op: *longInteger_t) void {
    __gmpz_init(&op[0]);
}
inline fn longIntegerFree(op: *longInteger_t) void {
    __gmpz_clear(&op[0]);
}
inline fn stringToLongInteger(source: [*c]const u8, radix: i32, destination: *longInteger_t) i32 {
    return __gmpz_set_str(&destination[0], source, @intCast(radix));
}
inline fn longInteger2Pow(exp: u32, result: *longInteger_t) void {
    __gmpz_setbit(&result[0], exp);
}
inline fn longIntegerSetZero(op: *longInteger_t) void {
    __gmpz_clear(&op[0]);
    __gmpz_init(&op[0]);
}
inline fn longIntegerSetNegativeSign(op: *longInteger_t) void {
    op[0]._mp_size = -absI32(op[0]._mp_size);
}
inline fn longIntegerDivideUInt(op: *const longInteger_t, uint: u32, result: *longInteger_t) void {
    _ = __gmpz_tdiv_q_ui(&result[0], &op[0], uint);
}
inline fn longIntegerSubtractUInt(op: *const longInteger_t, uint: u32, result: *longInteger_t) void {
    __gmpz_sub_ui(&result[0], &op[0], uint);
}
inline fn longIntegerAddUInt(op: *const longInteger_t, uint: u32, result: *longInteger_t) void {
    __gmpz_add_ui(&result[0], &op[0], uint);
}
inline fn longIntegerCompare(op1: *const longInteger_t, op2: *const longInteger_t) i32 {
    return __gmpz_cmp(&op1[0], &op2[0]);
}
inline fn longIntegerIsNegative(op: *const longInteger_t) bool {
    return op[0]._mp_size < 0;
}
inline fn absI32(v: i32) i32 {
    return if (v < 0) -v else v;
}

// C int-promotion abs() and small helpers.
inline fn absInt(v: i32) i32 {
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
    .{ .itemNr = ITM_CtoF },
    .{ .itemNr = ITM_FtoC },
    .{ .itemNr = ITM_DBtoPR },
    .{ .itemNr = ITM_FT2toHA },
    .{ .itemNr = ITM_HAtoFT2 },
    .{ .itemNr = ITM_DBtoFR },
    .{ .itemNr = ITM_FT2toM2 },
    .{ .itemNr = ITM_M2toFT2 },
    .{ .itemNr = ITM_PRtoDB },
    .{ .itemNr = ITM_HAtoKM2 },
    .{ .itemNr = ITM_KM2toHA },
    .{ .itemNr = ITM_FRtoDB },
    .{ .itemNr = ITM_GLUKtoFZUK },
    .{ .itemNr = ITM_FZUKtoGLUK },
    .{ .itemNr = ITM_ACtoHA },
    .{ .itemNr = ITM_MLtoIN3 },
    .{ .itemNr = ITM_HAtoAC },
    .{ .itemNr = ITM_IN3toML },
    .{ .itemNr = ITM_ACUStoHA },
    .{ .itemNr = ITM_FT3toGLUK },
    .{ .itemNr = ITM_HAtoACUS },
    .{ .itemNr = ITM_GLUKtoFT3 },
    .{ .itemNr = ITM_PAtoATM },
    .{ .itemNr = ITM_ATMtoPA },
    .{ .itemNr = ITM_AUtoM },
    .{ .itemNr = ITM_MtoAU },
    .{ .itemNr = ITM_BARtoPA },
    .{ .itemNr = ITM_PAtoBAR },
    .{ .itemNr = ITM_BTUtoJ },
    .{ .itemNr = ITM_JtoBTU },
    .{ .itemNr = ITM_CALtoJ },
    .{ .itemNr = ITM_JtoCAL },
    .{ .itemNr = ITM_LBFFTtoNM },
    .{ .itemNr = ITM_LtoFT3 },
    .{ .itemNr = ITM_NMtoLBFFT },
    .{ .itemNr = ITM_FT3toL },
    .{ .itemNr = ITM_CWTtoKG },
    .{ .itemNr = ITM_KGtoCWT },
    .{ .itemNr = ITM_FTtoM },
    .{ .itemNr = ITM_MtoFT },
    .{ .itemNr = ITM_FTUStoM },
    .{ .itemNr = ITM_LtoQTUS },
    .{ .itemNr = ITM_QTUStoL },
    .{ .itemNr = ITM_MtoFTUS },
    .{ .itemNr = ITM_IN3toFZUK },
    .{ .itemNr = ITM_FZUKtoIN3 },
    .{ .itemNr = ITM_FZUKtoML },
    .{ .itemNr = ITM_IN3toFZUS },
    .{ .itemNr = ITM_MLtoFZUK },
    .{ .itemNr = ITM_FZUStoIN3 },
    .{ .itemNr = ITM_FZUStoML },
    .{ .itemNr = ITM_FT3toGalUS },
    .{ .itemNr = ITM_MLtoFZUS },
    .{ .itemNr = ITM_GalUStoFT3 },
    .{ .itemNr = ITM_GLUKtoL },
    .{ .itemNr = ITM_LtoGLUK },
    .{ .itemNr = ITM_GLUStoL },
    .{ .itemNr = ITM_LtoGLUS },
    .{ .itemNr = ITM_HPEtoW },
    .{ .itemNr = ITM_WtoHPE },
    .{ .itemNr = ITM_HPMtoW },
    .{ .itemNr = ITM_WtoHPM },
    .{ .itemNr = ITM_HPUKtoW },
    .{ .itemNr = ITM_WtoHPUK },
    .{ .itemNr = ITM_INCHHGtoPA },
    .{ .itemNr = ITM_CUPCtoFZUS },
    .{ .itemNr = ITM_PAtoINCHHG },
    .{ .itemNr = ITM_CUPCtoML },
    .{ .itemNr = ITM_INCHtoMM },
    .{ .itemNr = ITM_MMtoINCH },
    .{ .itemNr = ITM_WHtoJ },
    .{ .itemNr = ITM_JtoWH },
    .{ .itemNr = ITM_KGtoLBS },
    .{ .itemNr = ITM_LBStoKG },
    .{ .itemNr = ITM_GtoOZ },
    .{ .itemNr = ITM_OZtoG },
    .{ .itemNr = ITM_KGtoSCW },
    .{ .itemNr = ITM_CUPUKtoFZUK },
    .{ .itemNr = ITM_SCWtoKG },
    .{ .itemNr = ITM_CUPUKtoML },
    .{ .itemNr = ITM_KGtoSTO },
    .{ .itemNr = ITM_FZUKtoCUPUK },
    .{ .itemNr = ITM_STOtoKG },
    .{ .itemNr = ITM_FZUKtoTBSPUK },
    .{ .itemNr = ITM_KGtoST },
    .{ .itemNr = ITM_FZUKtoTSPUK },
    .{ .itemNr = ITM_FZUStoCUPC },
    .{ .itemNr = ITM_STtoKG },
    .{ .itemNr = ITM_FZUStoTBSPC },
    .{ .itemNr = ITM_FZUStoTSPC },
    .{ .itemNr = ITM_KGtoTON },
    .{ .itemNr = ITM_KGtoLIANG },
    .{ .itemNr = ITM_MLtoCUPC },
    .{ .itemNr = ITM_TONtoKG },
    .{ .itemNr = ITM_LIANGtoKG },
    .{ .itemNr = ITM_MLtoCUPUK },
    .{ .itemNr = ITM_GtoTRZ },
    .{ .itemNr = ITM_MLtoPINTLQ },
    .{ .itemNr = ITM_TRZtoG },
    .{ .itemNr = ITM_MLtoPINTUK },
    .{ .itemNr = ITM_LBFtoN },
    .{ .itemNr = ITM_NtoLBF },
    .{ .itemNr = ITM_LYtoM },
    .{ .itemNr = ITM_MtoLY },
    .{ .itemNr = ITM_MMHGtoPA },
    .{ .itemNr = ITM_MLtoQT },
    .{ .itemNr = ITM_PAtoMMHG },
    .{ .itemNr = ITM_MLtoQTUS },
    .{ .itemNr = ITM_MItoKM },
    .{ .itemNr = ITM_KMtoMI },
    .{ .itemNr = ITM_KMtoNMI },
    .{ .itemNr = ITM_NMItoKM },
    .{ .itemNr = ITM_MtoPC },
    .{ .itemNr = ITM_PCtoM },
    .{ .itemNr = ITM_MMtoPOINT },
    .{ .itemNr = ITM_MLtoTBSPC },
    .{ .itemNr = ITM_MILEtoM },
    .{ .itemNr = ITM_POINTtoMM },
    .{ .itemNr = ITM_MLtoTBSPUK },
    .{ .itemNr = ITM_MtoMILE },
    .{ .itemNr = ITM_MtoYD },
    .{ .itemNr = ITM_YDtoM },
    .{ .itemNr = ITM_PSItoPA },
    .{ .itemNr = ITM_PAtoPSI },
    .{ .itemNr = ITM_PAtoTOR },
    .{ .itemNr = ITM_MLtoTSPC },
    .{ .itemNr = ITM_TORtoPA },
    .{ .itemNr = ITM_MLtoTSPUK },
    .{ .itemNr = ITM_StoYEAR },
    .{ .itemNr = ITM_YEARtoS },
    .{ .itemNr = ITM_CARATtoG },
    .{ .itemNr = ITM_PINTLQtoML },
    .{ .itemNr = ITM_JINtoKG },
    .{ .itemNr = ITM_GtoCARAT },
    .{ .itemNr = ITM_PINTUKtoML },
    .{ .itemNr = ITM_KGtoJIN },
    .{ .itemNr = ITM_QTtoL },
    .{ .itemNr = ITM_LtoQT },
    .{ .itemNr = ITM_FATHOMtoM },
    .{ .itemNr = ITM_QTtoML },
    .{ .itemNr = ITM_NMItoM },
    .{ .itemNr = ITM_MtoFATHOM },
    .{ .itemNr = ITM_QTUStoML },
    .{ .itemNr = ITM_MtoNMI },
    .{ .itemNr = ITM_BARRELtoM3 },
    .{ .itemNr = ITM_TBSPCtoFZUS },
    .{ .itemNr = ITM_M3toBARREL },
    .{ .itemNr = ITM_HMStoHR },
    .{ .itemNr = ITM_HRtoHMS },
    .{ .itemNr = ITM_TBSPCtoML },
    .{ .itemNr = ITM_HECTAREtoM2 },
    .{ .itemNr = ITM_M2toHECTARE },
    .{ .itemNr = ITM_MUtoM2 },
    .{ .itemNr = ITM_M2toMU },
    .{ .itemNr = ITM_LItoM },
    .{ .itemNr = ITM_MtoLI },
    .{ .itemNr = ITM_CHItoM },
    .{ .itemNr = ITM_MtoCHI },
    .{ .itemNr = ITM_YINtoM },
    .{ .itemNr = ITM_MtoYIN },
    .{ .itemNr = ITM_CUNtoM },
    .{ .itemNr = ITM_MtoCUN },
    .{ .itemNr = ITM_ZHANGtoM },
    .{ .itemNr = ITM_TBSPUKtoFZUK },
    .{ .itemNr = ITM_MtoZHANG },
    .{ .itemNr = ITM_TBSPUKtoML },
    .{ .itemNr = ITM_FENtoM },
    .{ .itemNr = ITM_MtoFEN },
    .{ .itemNr = ITM_MI2toKM2 },
    .{ .itemNr = ITM_KM2toMI2 },
    .{ .itemNr = ITM_NMI2toKM2 },
    .{ .itemNr = ITM_KM2toNMI2 },
    .{ .itemNr = ITM_TSPCtoFZUS },
    .{ .itemNr = ITM_TSPCtoML },
    .{ .itemNr = ITM_TSPUKtoFZUK },
    .{ .itemNr = ITM_TSPUKtoML },
    .{ .itemNr = ITM_GLUStoFZUS },
    .{ .itemNr = ITM_FZUStoGLUS },
    .{ .itemNr = ITM_KNOTtoKMH },
    .{ .itemNr = ITM_KMHtoKNOT },
    .{ .itemNr = ITM_KMHtoMPS },
    .{ .itemNr = ITM_MPStoKMH },
    .{ .itemNr = ITM_RPMtoDEGPS },
    .{ .itemNr = ITM_DEGPStoRPM },
    .{ .itemNr = ITM_MPHtoKMH },
    .{ .itemNr = ITM_KMHtoMPH },
    .{ .itemNr = ITM_MPHtoMPS },
    .{ .itemNr = ITM_MPStoMPH },
    .{ .itemNr = ITM_RPMtoRADPS },
    .{ .itemNr = ITM_RADPStoRPM },
    .{ .itemNr = ITM_DEGtoRAD },
    .{ .itemNr = ITM_RADtoDEG },
    .{ .itemNr = ITM_DEGtoGRAD },
    .{ .itemNr = ITM_GRADtoDEG },
    .{ .itemNr = ITM_GRADtoRAD },
    .{ .itemNr = ITM_RADtoGRAD },
    .{ .itemNr = ITM_INCHtoCM },
    .{ .itemNr = ITM_CMtoINCH },
    .{ .itemNr = ITM_NMItoMI },
    .{ .itemNr = ITM_MItoNMI },
    .{ .itemNr = ITM_FURtoM },
    .{ .itemNr = ITM_MtoFUR },
    .{ .itemNr = ITM_FTNtoS },
    .{ .itemNr = ITM_StoFTN },
    .{ .itemNr = ITM_FPFtoMPS },
    .{ .itemNr = ITM_MPStoFPF },
    .{ .itemNr = ITM_BRDStoM },
    .{ .itemNr = ITM_MtoBRDS },
    .{ .itemNr = ITM_FIRtoKG },
    .{ .itemNr = ITM_KGtoFIR },
    .{ .itemNr = ITM_FPFtoKPH },
    .{ .itemNr = ITM_KPHtoFPF },
    .{ .itemNr = ITM_BRDStoIN },
    .{ .itemNr = ITM_INtoBRDS },
    .{ .itemNr = ITM_FIRtoLB },
    .{ .itemNr = ITM_LBtoFIR },
    .{ .itemNr = ITM_FPFtoMPH },
    .{ .itemNr = ITM_MPHtoFPF },
    .{ .itemNr = ITM_FPStoKMH },
    .{ .itemNr = ITM_KMHtoFPS },
    .{ .itemNr = ITM_FPStoMPS },
    .{ .itemNr = ITM_MPStoFPS },
    .{ .itemNr = ITM_L100toKML },
    .{ .itemNr = ITM_KMLtoL100 },
    .{ .itemNr = ITM_KMLEtoK100K },
    .{ .itemNr = ITM_K100KtoKMLE },
    .{ .itemNr = ITM_K100KtoKMK },
    .{ .itemNr = ITM_KMKtoK100K },
    .{ .itemNr = ITM_L100toMGUS },
    .{ .itemNr = ITM_MGUStoL100 },
    .{ .itemNr = ITM_MGEUStoK100M },
    .{ .itemNr = ITM_K100MtoMGEUS },
    .{ .itemNr = ITM_K100KtoK100M },
    .{ .itemNr = ITM_K100MtoK100K },
    .{ .itemNr = ITM_L100toMGUK },
    .{ .itemNr = ITM_MGUKtoL100 },
    .{ .itemNr = ITM_MGEUKtoK100M },
    .{ .itemNr = ITM_K100MtoMGEUK },
    .{ .itemNr = ITM_K100MtoMIK },
    .{ .itemNr = ITM_MIKtoK100M },
    .{ .itemNr = ITM_EVtoJ },
    .{ .itemNr = ITM_JtoEV },
    .{ .itemNr = ITM_BANANAtoINCH },
    .{ .itemNr = ITM_INCHtoBANANA },
    .{ .itemNr = ITM_BANANAtoMM },
    .{ .itemNr = ITM_MMtoBANANA },
    .{ .itemNr = ITM_ERGtoJ },
    .{ .itemNr = ITM_JtoERG },
    .{ .itemNr = ITM_FoetoJ },
    .{ .itemNr = ITM_JtoFoe },
    .{ .itemNr = ITM_CtoK },
    .{ .itemNr = ITM_KtoC },
    .{ .itemNr = ITM_RAtoK },
    .{ .itemNr = ITM_KtoRA },
    .{ .itemNr = ITM_RAtoF },
    .{ .itemNr = ITM_FtoRA },
    .{ .itemNr = ITM_EVKBtoK },
    .{ .itemNr = ITM_KtoEVKB },
    .{ .itemNr = ITM_FtoK },
    .{ .itemNr = ITM_KtoF },
    .{ .itemNr = ITM_KNOTtoMPS },
    .{ .itemNr = ITM_MPStoKNOT },
    .{ .itemNr = ITM_DEGPStoRADPS },
    .{ .itemNr = ITM_RADPStoDEGPS },
    .{ .itemNr = ITM_SLUGtoKG },
    .{ .itemNr = ITM_KGtoSLUG },
    .{ .itemNr = ITM_SLINCHtoKG },
    .{ .itemNr = ITM_KGtoSLINCH },
    .{ .itemNr = ITM_BLOBtoKG },
    .{ .itemNr = ITM_KGtoBLOB },
    .{ .itemNr = ITM_TONNEtoKG },
    .{ .itemNr = ITM_KGtoTONNE },
    .{ .itemNr = ITM_LBSFT2toPA },
    .{ .itemNr = ITM_PAtoLBSFT2 },
    .{ .itemNr = ITM_INLBStoNM },
    .{ .itemNr = ITM_NMtoINLBS },
    .{ .itemNr = ITM_LBSFTtoNPM },
    .{ .itemNr = ITM_NPMtoLBSFT },
    .{ .itemNr = ITM_KGFtoN },
    .{ .itemNr = ITM_NtoKGF },
    .{ .itemNr = ITM_MS2toFTS2 },
    .{ .itemNr = ITM_FTS2toMS2 },
    .{ .itemNr = ITM_MS2toINS2 },
    .{ .itemNr = ITM_INS2toMS2 },
    .{ .itemNr = ITM_KSItoMPA },
    .{ .itemNr = ITM_MPAtoKSI },
    .{ .itemNr = ITM_LBSIN3toBLOBIN3 },
    .{ .itemNr = ITM_BLOBIN3toLBSIN3 },
    .{ .itemNr = ITM_LBSIN3toTMM3 },
    .{ .itemNr = ITM_TMM3toLBSIN3 },
    .{ .itemNr = ITM_LBSIN3toKGM3 },
    .{ .itemNr = ITM_KGM3toLBSIN3 },
    .{ .itemNr = ITM_KGM3toBLOBIN3 },
    .{ .itemNr = ITM_BLOBIN3toKGM3 },
    .{ .itemNr = ITM_KGM3toTMM3 },
    .{ .itemNr = ITM_TMM3toKGM3 },
    .{ .itemNr = ITM_LBFTtoKGM },
    .{ .itemNr = ITM_KGMtoLBFT },
    .{ .itemNr = ITM_IN3toMM3 },
    .{ .itemNr = ITM_MM3toIN3 },
    .{ .itemNr = ITM_IN2toMM2 },
    .{ .itemNr = ITM_MM2toIN2 },
    .{ .itemNr = ITM_IN4toMM4 },
    .{ .itemNr = ITM_MM4toIN4 },
    .{ .itemNr = ITM_IN6toMM6 },
    .{ .itemNr = ITM_MM6toIN6 },
    .{ .itemNr = ITM_KGFPMtoNPM },
    .{ .itemNr = ITM_NPMtoKGFPM },
    .{ .itemNr = ITM_KGFtoLBF },
    .{ .itemNr = ITM_LBFtoKGF },
    .{ .itemNr = ITM_UNSLUGtoKG },
    .{ .itemNr = ITM_KGtoUNSLUG },
    .{ .itemNr = ITM_KGtoUNSLINCH },
    .{ .itemNr = ITM_UNSLINCHtoKG },
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
    .{ .itemNr = ITM_RMODEQ },
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

fn isFunctionInMim(com: i16, fType: u8) bool {
    const table: []const fInMim_t = if (fType == 0) &MimFunctionsType0 else if (fType == 1) &MimFunctionsType1 else &MimFunctionsType2;
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
        i = 1;
        while (i < lg - 1) : (i += 1) { // do not check the # on the very begin or very end
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
    if (aimBuffer[lg - 2] == '#' and (aimBuffer[lg - 1] >= '0' and aimBuffer[lg - 1] <= '9')) {
        base = aimBuffer[lg - 1];
    }
    if (aimBuffer[lg - 3] == '#' and (aimBuffer[lg - 2] >= '0' and aimBuffer[lg - 2] <= '1') and (aimBuffer[lg - 1] >= '0' and aimBuffer[lg - 1] <= '9')) {
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
// closeAim
// ---------------------------------------------------------------------------
pub export fn closeAim() callconv(.c) void {
    frontier_calc_mode.calcModeNormal();
    frontier_softmenus.popSoftmenu();

    if (aimBuffer[0] == 0) {
        undo();
    } else {
        const len: i16 = @intCast(stringByteLength(aimBuffer) + 1);
        reallocateRegister(REGISTER_X, dtString, toBlocks(@intCast(len)), amNone);
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
inline fn separatorLeftByte1() u8 {
    return gapChar1Bytes(gapItemLeft).b1;
}
inline fn separatorRightByte1() u8 {
    return gapChar1Bytes(gapItemRight).b1;
}
const TwoBytes = struct { b0: u8, b1: u8 };
// Reproduces Lt/Rt -> gapChar1Left/Right: returns the first two bytes of the
// separator string (byte[1] == 1 means "single-byte separator").
fn gapChar1Bytes(gapItem: u16) TwoBytes {
    var s: [*c]const u8 = undefined;
    if (gapItem == 0) {
        s = "\x01\x01\x00";
    } else {
        s = &indexOfItems[gapItem].itemSoftmenuName;
    }
    if (s[0] != 0 and s[1] == 0 and s[2] == 0) {
        switch (s[0]) {
            ',' => return .{ .b0 = ',', .b1 = 1 },
            '.' => return .{ .b0 = '.', .b1 = 1 },
            '\'' => return .{ .b0 = '\'', .b1 = 1 },
            '_' => return .{ .b0 = '_', .b1 = 1 },
            else => return .{ .b0 = s[0], .b1 = s[1] },
        }
    }
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

    const GROUPWIDTH_LEFTM: u8 = grpGroupingLeft;
    switch (nimNumberPart) {
        NP_INT_10, NP_INT_BASE => {
            switch (lastIntegerBase) {
                0 => grpGroupingLeft = GROUPWIDTH_LEFTM,
                2 => grpGroupingLeft = 4,
                3 => grpGroupingLeft = 3,
                4 => grpGroupingLeft = 2,
                5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 => grpGroupingLeft = 3,
                16 => grpGroupingLeft = 2,
                else => {},
            }
        },
        NP_INT_16 => {
            grpGroupingLeft = 2;
        },
        else => {},
    }

    numDigits = 0;
    while (buffer[@intCast(numDigits)] != 0 and buffer[@intCast(numDigits)] != 'e' and buffer[@intCast(numDigits)] != '.' and buffer[@intCast(numDigits)] != ' ' and buffer[@intCast(numDigits)] != '#' and buffer[@intCast(numDigits)] != '+' and buffer[@intCast(numDigits)] != '-') : (numDigits += 1) {}

    source = 0;
    dest = 0;
    while (source < numDigits) : (source += 1) {
        displayBuffer[@intCast(dest)] = buffer[@intCast(source)];
        dest += 1;
        dest += insertGapIP(displayBuffer + @as(usize, @intCast(dest)), numDigits, source);
    }

    grpGroupingLeft = GROUPWIDTH_LEFTM;
    displayBuffer[@intCast(dest)] = 0;

    if (nimNumberPart == NP_REAL_FLOAT_PART or nimNumberPart == NP_REAL_EXPONENT or nimNumberPart == NP_COMPLEX_FLOAT_PART or nimNumberPart == NP_COMPLEX_EXPONENT) {
        displayBuffer[@intCast(dest)] = '.';
        dest += 1;

        buffer += @as(usize, @intCast(source)) + 1;

        numDigits = 0;
        while (buffer[@intCast(numDigits)] != 0 and buffer[@intCast(numDigits)] != 'e' and buffer[@intCast(numDigits)] != '+' and buffer[@intCast(numDigits)] != '-') : (numDigits += 1) {}

        source = 0;
        while (source < numDigits) : (source += 1) {
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
    var integer: i32 = undefined;
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
            frontier_error.displayCalcErrorMessage(ERROR_BAD_INPUT, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
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
            frontier_error.displayCalcErrorMessage(ERROR_BAD_INPUT, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
            moreInfoOnErr("In function nimFractionToReal34:", "there is a non numeric character in the numerator part of the fraction!");
            return;
        }
    }

    if (source[@intCast(posSlash + 1)] != 0) {
        i = posSlash + 1;
        while (i < lg) : (i += 1) {
            if (source[@intCast(i)] < '0' or source[@intCast(i)] > '9') {
                frontier_error.displayCalcErrorMessage(ERROR_BAD_INPUT, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
                moreInfoOnErr("In function nimFractionToReal34:", "there is a non numeric character in the denominator part of the fraction!");
                return;
            }
        }
    }

    if (posSpace != 0) {
        source[@intCast(posSpace)] = 0;
        integer = toInt32(source + 1);
    } else {
        integer = 0;
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
        frontier_error.displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
        moreInfoOnErr3("In function nimFractionToReal34:", "the denominator of the fraction should not be 0!", "Unless D flag (Danger) is set.");
        return;
    }

    int32ToReal34(numer, dest);
    int32ToReal34(denom, &temp);
    real34Divide(dest, &temp, dest);
    int32ToReal34(integer, &temp);
    real34Add(dest, &temp, dest);
    if (source[0] == '-') {
        real34SetNegativeSign(dest);
    }
}

// ---------------------------------------------------------------------------
// closeNimWithFraction
// ---------------------------------------------------------------------------
pub export fn closeNimWithFraction(dest: *real34_t) callconv(.c) void {
    nimFractionToReal34(aimBuffer, dest);
}

// ---------------------------------------------------------------------------
// closeNimWithComplex
// ---------------------------------------------------------------------------
pub export fn closeNimWithComplex(dest_r: *real34_t, dest_i: *real34_t) callconv(.c) void {
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

    if ((getSystemFlag(FLAG_POLAR) != 0 and temporaryFlagRect == 0) or temporaryFlagPolar != 0) { // polar mode
        if (real34CompareEqual(dest_r, const34_0) != 0) {
            real34SetZero(dest_i);
        } else {
            var magnitude: real_t = undefined;
            var theta: real_t = undefined;
            real34ToReal(dest_r, &magnitude);
            real34ToReal(dest_i, &theta);
            frontier_conversion_angles.convertAngleFromTo(&theta, currentAngularMode, amRadian, &ctxtReal39);
            if (realCompareLessThan(&magnitude, const_0) != 0) {
                realSetPositiveSign(&magnitude);
                realAdd(&theta, const39_pi, &theta, &ctxtReal39);
            }
            realPolarToRectangular(&magnitude, &theta, &magnitude, &theta, &ctxtReal39); // theta in radian
            realToReal34(&magnitude, dest_r);
            realToReal34(&theta, dest_i);
        }
        fnToPolar2(0);
    } else if ((getSystemFlag(FLAG_POLAR) == 0 and temporaryFlagPolar == 0) or temporaryFlagRect != 0) { // rect mode
        fnToRect2(0);
    }
    temporaryFlagRect = 0;
    temporaryFlagPolar = 0;
    fnSetFlag(FLAG_CPXRES);
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

    var delayedShortIntegerCHS: bool = false;
    if (aimBuffer[0] == '-' and validShortIntegerInX() != 0) {
        aimBuffer[0] = ' ';
        delayedShortIntegerCHS = true;
    }

    var lastChar: i16 = @intCast(strlen(aimBuffer) - 1);

    closeNim_exit: {
        if (nimNumberPart != NP_INT_16) { // We need a # and a base
            if (nimNumberPart != NP_INT_BASE or aimBuffer[@intCast(lastChar)] != '#') { // We need a base
                if ((nimNumberPart == NP_COMPLEX_EXPONENT or nimNumberPart == NP_REAL_EXPONENT) and (aimBuffer[@intCast(lastChar)] == '+' or aimBuffer[@intCast(lastChar)] == '-') and aimBuffer[@intCast(lastChar - 1)] == 'e') {
                    lastChar -= 1;
                    aimBuffer[@intCast(lastChar)] = 0;
                    lastChar -= 1;
                } else if (nimNumberPart == NP_REAL_EXPONENT and aimBuffer[@intCast(lastChar)] == 'e') {
                    aimBuffer[@intCast(lastChar)] = 0;
                    lastChar -= 1;
                }
                const is_i: bool = nimNumberPart == NP_COMPLEX_INT_PART and aimBuffer[@intCast(lastChar)] == 'i';
                const is_theta: bool = nimNumberPart == NP_COMPLEX_INT_PART and (@as(i32, aimBuffer[@intCast(lastChar - 1)]) * 256 + @as(i32, aimBuffer[@intCast(lastChar)]) * 256) == 0xa221;
                if ((is_i or is_theta) and getSystemFlag(FLAG_POLAR) == 0) { // complex i
                    lastChar += 1;
                    aimBuffer[@intCast(lastChar)] = '1';
                    aimBuffer[@intCast(lastChar + 1)] = 0;
                } else if ((is_i or is_theta) and getSystemFlag(FLAG_POLAR) != 0) { // complex measured angle
                    lastChar += 1;
                    aimBuffer[@intCast(lastChar)] = '0';
                    aimBuffer[@intCast(lastChar + 1)] = 0;
                }

                if ((aimBuffer[0] != '-' or aimBuffer[1] != 0) and (aimBuffer[@intCast(lastChar)] != '-')) {
                    frontier_calc_mode.calcModeNormal();

                    if (nimNumberPart == NP_INT_10) {
                        var lgInt: longInteger_t = undefined;
                        const xangularMode: angularMode_t = if ((getRegisterDataType(REGISTER_X) == dtReal34) == (dtReal34 != 0)) getRegisterAngularMode(REGISTER_X) else amNone;

                        if (xangularMode < amNone) { // editing with angular mode -> convert to real, preserve angular mode
                            reallocateRegister(REGISTER_X, dtReal34, 0, @intCast(getRegisterAngularMode(REGISTER_X)));
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
                        // Any change here must be reported in strToShortInteger in testSuite.c.
                        var minVal: longInteger_t = undefined;
                        var value: longInteger_t = undefined;
                        var maxVal: longInteger_t = undefined;
                        var posHash: i16 = undefined;
                        var ii: i16 = undefined;
                        var lg: i16 = undefined;
                        var base: i32 = undefined;

                        lg = @intCast(strlen(aimBuffer));
                        posHash = 0;
                        ii = 1;
                        while (ii < lg) : (ii += 1) {
                            if (aimBuffer[@intCast(ii)] == '#') {
                                posHash = ii;
                                break;
                            }
                        }

                        ii = posHash + 1;
                        while (ii < lg) : (ii += 1) {
                            if (aimBuffer[@intCast(ii)] < '0' or aimBuffer[@intCast(ii)] > '9') {
                                frontier_error.displayCalcErrorMessage(ERROR_INVALID_INTEGER_INPUT, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
                                moreInfoOnErr("In function closeNIM:", "there is a non numeric character in the base of the integer!");
                                break :closeNim_exit;
                            }
                        }

                        base = stringToInt32(aimBuffer + @as(usize, @intCast(posHash)) + 1);
                        if (base < 2 or base > 16) {
                            frontier_error.displayCalcErrorMessage(ERROR_INVALID_INTEGER_INPUT, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
                            moreInfoOnErr("In function closeNIM:", "the base of the integer must be from 2 to 16!");
                            break :closeNim_exit;
                        }

                        ii = if (aimBuffer[0] == '-') 1 else 0;
                        while (ii < posHash) : (ii += 1) {
                            const digitVal: i32 = if (aimBuffer[@intCast(ii)] > '9') @as(i32, aimBuffer[@intCast(ii)]) - 'A' + 10 else @as(i32, aimBuffer[@intCast(ii)]) - '0';
                            if (digitVal >= base) {
                                frontier_error.displayCalcErrorMessage(ERROR_INVALID_INTEGER_INPUT, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
                                if (comptime extra_info) {
                                    if (comptime !dmcp_build) {
                                        abi.fmtBufZ(errorMessage[0..512], "digit {c} is not allowed in base {d}!", .{ aimBuffer[@intCast(ii)], @as(i32, base) });
                                        moreInfoOnError("In function closeNIM:", errorMessage, null, null);
                                    }
                                }
                                undo();
                                break :closeNim_exit;
                            }
                        }

                        longIntegerInit(&value);
                        aimBuffer[@intCast(posHash)] = 0;
                        _ = stringToLongInteger(aimBuffer + @as(usize, if (aimBuffer[0] == '+') 1 else 0), base, &value);

                        // maxVal = 2^shortIntegerWordSize
                        longIntegerInit(&maxVal);
                        if (shortIntegerWordSize >= 1 and shortIntegerWordSize <= 64) {
                            longInteger2Pow(shortIntegerWordSize, &maxVal);
                        } else {
                            _ = sprintf(errorMessage, @ptrCast(&commonBugScreenMessages[bugMsgValueFor]), "closeNIM", "shortIntegerWordSize", @as(c_int, shortIntegerWordSize));
                            frontier_error.displayBugScreen(errorMessage);
                            longIntegerFree(&maxVal);
                            longIntegerFree(&value);
                            break :closeNim_exit;
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
                            frontier_error.displayCalcErrorMessage(ERROR_WORD_SIZE_TOO_SMALL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
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
                            break :closeNim_exit;
                        }

                        reallocateRegister(REGISTER_X, dtShortInteger, 0, @intCast(base));

                        var strValue: [22]u8 = undefined;
                        frontier_display.longIntegerToAllocatedString(&value[0], &strValue, @intCast(strValue.len));

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
                            _ = sprintf(errorMessage, @ptrCast(&commonBugScreenMessages[bugMsgValueFor]), "closeNIM", "shortIntegerMode", @as(c_int, shortIntegerMode));
                            frontier_error.displayBugScreen(errorMessage);
                            regShortInteger(REGISTER_X).* = 0;
                        }

                        regShortInteger(REGISTER_X).* = val;
                        lastIntegerBase = @intCast(base);
                        frontier_radio_button_catalog.fnRefreshState();
                        aimBuffer[0] = 0; // Clear the NIM input buffer once written successfully.

                        longIntegerFree(&maxVal);
                        longIntegerFree(&minVal);
                        longIntegerFree(&value);
                    } else if (nimNumberPart == NP_REAL_FLOAT_PART or nimNumberPart == NP_REAL_EXPONENT) {
                        const dataType: u16 = @intCast(getRegisterDataType(REGISTER_X));
                        if (dataType == dtTime) {
                            reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
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
                            reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
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
                                reallocateRegister(REGISTER_X, dtComplex34, 0, amNone);
                                stringToReal34(aimBuffer, reg34(REGISTER_X));
                                stringToReal34("0", regImag34(REGISTER_X));
                            } else {
                                const xangularMode: angularMode_t = if ((getRegisterDataType(REGISTER_X) == dtReal34) == (dtReal34 != 0)) getRegisterAngularMode(REGISTER_X) else amNone;

                                reallocateRegister(REGISTER_X, dtReal34, 0, @intCast(xangularMode));
                                stringToReal34(aimBuffer, reg34(REGISTER_X));
                                if (xangularMode == amDMS) {
                                    frontier_conversion_angles.real34FromDmsToDeg(reg34(REGISTER_X), reg34(REGISTER_X));
                                }
                            }
                        }
                    } else if (nimNumberPart == NP_FRACTION_DENOMINATOR or nimNumberPart == NP_HP32SII_DENOMINATOR) {
                        reallocateRegister(REGISTER_X, dtReal34, 0, @intCast(getRegisterAngularMode(REGISTER_X)));
                        closeNimWithFraction(reg34(REGISTER_X));
                    } else if (nimNumberPart == NP_COMPLEX_INT_PART or nimNumberPart == NP_COMPLEX_FLOAT_PART or nimNumberPart == NP_COMPLEX_EXPONENT or nimNumberPart == NP_COMPLEX_FRACTION_DENOMINATOR or nimNumberPart == NP_COMPLEX_HP32SII_DENOMINATOR) {
                        reallocateRegister(REGISTER_X, dtComplex34, 0, amNone);
                        closeNimWithComplex(reg34(REGISTER_X), regImag34(REGISTER_X));
                    } else {
                        abi.fmtBufZ(errorMessage[0..512], "In function {s}: {d} is an unexpected {s} value!", .{ "closeNIM", @as(c_int, nimNumberPart), "nimNumberPart" });
                        frontier_error.displayBugScreen(errorMessage);
                    }
                }
            }
        }
        if (delayedShortIntegerCHS) {
            chsShoI();
        }

        // IR_PRINTING (always enabled).
        if ((lastItem != ITM_ms) and (lastItem != ITM_dotD) and (lastItem != ITM_DRG)) {
            frontier_print.printTraceX(LINE_NOLF);
        }
        lastItem = 0;
    } // closeNim_exit

    nimNumberPart = NP_EMPTY; // Ensure insertStepInProgram sees the correct value.
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
            } else if (stringByteLength(aimBuffer) + (if (item == ITM_poly_SIGN) @as(i32, 24) else stringByteLength(&indexOfItems[item].itemSoftmenuName)) >= AIM_BUFFER_LENGTH) {
                abi.fmtBufZ(errorMessage[0..512], "In function addItemToBuffer:the AIM input buffer is full! {d} bytes for now", .{@as(i32, AIM_BUFFER_LENGTH)});
                frontier_error.displayBugScreen(errorMessage);
            } else if (calcMode == CM_EIM) {
                const addChar0: [*c]const u8 = if (item == ITM_EEXCHR) "E" else if (item == ITM_PAIR_OF_PARENTHESES) "()" else if (item == ITM_VERTICAL_BAR) "||" else if (item == ITM_MAGNITUDE) "||" else if (item == ITM_ROOT_SIGN) STD_SQUARE_ROOT ++ "()" else if (item == ITM_SQUAREROOTX) STD_SQUARE_ROOT ++ "()" else if (item == ITM_CUBEROOT) STD_CUBE_ROOT ++ "()" else if (item == ITM_XTHROOT) STD_xTH_ROOT ++ "(:)" else if (item == ITM_EXP) STD_EulerE ++ "^()" else if (item == ITM_ALOG_SIGN) STD_EulerE ++ "^()" else if (item == ITM_LG_SIGN) "LOG()" else if (item == ITM_LN_SIGN) "LN()" else if (item == ITM_LOG2) "LB()" else if (item == ITM_SIN_SIGN) "SIN()" else if (item == ITM_COS_SIGN) "COS()" else if (item == ITM_TAN_SIGN) "TAN()" else if (item == ITM_OBELUS) STD_SLASH else if (item == ITM_poly_SIGN) "a4" ++ STD_DOT ++ "x^4+a3" ++ STD_DOT ++ "x^3+a2" ++ STD_DOT ++ "x^2+a1" ++ STD_DOT ++ "x+a0" else if (item == ITM_op_j_SIGN) complexUnit() else if (item == ITM_zetaX) STD_zeta ++ "()" else if (item == ITM_GAMMAX) STD_GAMMA ++ "()" else if (item == ITM_XFACT) "!" else if (item == ITM_M1X) "(-1)^()" else if (item == ITM_COMB) "COMB(:)" else if (item == ITM_PERM) "PERM(:)" else if (item >= FIRST_CONSTANT and item <= LAST_CONSTANT) @as([*c]const u8, &indexOfItems[item].itemCatalogName) else if (item >= ITM_SUP_0 and item <= ITM_SUP_9) @as([*c]const u8, &NumMsg[item - ITM_SUP_0].noStr) else "";

                var addChar: [100]u8 = undefined;
                var jj: i16 = 0;
                addChar[0] = 0;
                if (addChar0[0] == 0) {
                    if (item != ITM_EQUAL) { // block the entry of "="
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
            } else if (stringByteLength(aimBuffer) <= AIM_BUFFER_LENGTH - 1 and frontier_screen.stringWidthWithLimitC47(aimBuffer, stdNoEnlarge, nocompress, SCREEN_WIDTH * MAXLINES - 16, 1, 1) < SCREEN_WIDTH * MAXLINES - 16) {
                // TEXT_MULTILINE_EDIT (always defined): insert mid-string.
                var ix: u16 = 0;
                var in: u16 = 0;
                while (ix < @as(u16, @bitCast(T_cursorPos)) and in < @as(u16, @bitCast(T_cursorPos))) {
                    in = @bitCast(frontier_char_string.stringNextGlyphNoEndCheck_JM(aimBuffer, @bitCast(in)));
                    ix += 1;
                }
                T_cursorPos = @bitCast(in);
                var ixaa: [AIM_BUFFER_LENGTH]u8 = undefined;
                _ = frontier_char_string.xcopy(&ixaa, aimBuffer, in);
                ixaa[in] = 0;

                const nq: u16 = @intCast(stringByteLength(&indexOfItems[item].itemSoftmenuName));
                _ = frontier_char_string.xcopy(@as([*c]u8, &ixaa) + in, &indexOfItems[item].itemSoftmenuName, nq + 1);
                ixaa[in + nq] = 0;

                const nr: u16 = @intCast(stringByteLength(aimBuffer + in));
                _ = frontier_char_string.xcopy(@as([*c]u8, &ixaa) + in + nq, aimBuffer + in, nr + 1);
                ixaa[in + nq + nr] = 0;

                _ = frontier_char_string.xcopy(aimBuffer, &ixaa, @intCast(stringByteLength(&ixaa) + 1));

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
                frontier.mimEnter(true);
                frontier.setJRegisterAsInt(true, frontier.getJRegisterAsInt(true) + 1);
                frontier_screen.refreshScreen(51);
                frontier_print.printTrace(@bitCast(item), @bitCast(item));
                frontier_print.printTraceMatElement(LINE_FULL_U);
            } else if (item == ITM_LEFT_ARROW) {
                frontier.mimEnter(true);
                frontier.setJRegisterAsInt(true, frontier.getJRegisterAsInt(true) - 1);
                frontier_screen.refreshScreen(52);
                frontier_print.printTrace(@bitCast(item), @bitCast(item));
                frontier_print.printTraceMatElement(LINE_FULL_U);
            } else if (item == ITM_UP_ARROW) {
                frontier.mimEnter(true);
                frontier.setIRegisterAsInt(true, frontier.getIRegisterAsInt(true) - 1);
                frontier_screen.refreshScreen(53);
                frontier_print.printTrace(@bitCast(item), @bitCast(item));
                frontier_print.printTraceMatElement(LINE_FULL_U);
            } else if (item == ITM_DOWN_ARROW) {
                frontier.mimEnter(true);
                frontier.setIRegisterAsInt(true, frontier.getIRegisterAsInt(true) + 1);
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
                    frontier.mimEnter(true);
                    temporaryInformation = TI_SHOW_REGISTER;
                },
                ITM_OFF => {
                    frontier_items.runFunction(ITM_OFF);
                },
                else => {
                    if (isFunctionInMim(@bitCast(item), 0)) {
                        frontier.mimAddNumber(@bitCast(item));
                    } else if (isFunctionInMim(@bitCast(item), 1)) {
                        lastErrorCode = ERROR_NONE;
                        frontier.mimEnter(true);
                        frontier_items.runFunction(@bitCast(item));
                    } else if (isFunctionInMim(@bitCast(item), 2)) {
                        frontier.mimRunFunction(@bitCast(item), indexOfItems[item].param);
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
// (the `break :sw` path, same as ITM_PERIOD). The earlier port mistranslated the
// goto as `break :addItemToNimBuffer_exit`, which exited the function and skipped
// closeNim() — so base-entry shortcuts (B/D/H/I/OCT, base-digit completion) never
// committed the number to X.
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

    // IR_PRINTING (always defined).
    if (calcMode == CM_NIM) {
        lastItem = item;
    }

    if (item >= ITM_A and item <= ITM_F and lastIntegerBase == 0) {
        lastIntegerBase = 16;
    }

    screenUpdatingMode &= ~@as(u8, SCRUPD_MANUAL_STACK | SCRUPD_MANUAL_SHIFT_STATUS);
    currentSolverStatus &= ~@as(u16, SOLVER_STATUS_READY_TO_EXECUTE);

    if (calcMode == CM_NORMAL) {
        switch (item) {
            ITM_EXPONENT => {
                frontier_calc_mode.calcModeNim(NOPARAM);
                aimBuffer[0] = '+';
                aimBuffer[1] = '1';
                aimBuffer[2] = '.';
                aimBuffer[3] = 0;
                nimNumberPart = NP_REAL_FLOAT_PART;
                frontier_screen.setLastintegerBasetoZero();
            },
            ITM_PERIOD => {
                frontier_calc_mode.calcModeNim(NOPARAM);
                aimBuffer[0] = '+';
                aimBuffer[1] = '0';
                aimBuffer[2] = 0;
                nimNumberPart = NP_INT_10;
                frontier_screen.setLastintegerBasetoZero();
            },
            ITM_0, ITM_1, ITM_2, ITM_3, ITM_4, ITM_5, ITM_6, ITM_7, ITM_8, ITM_9, ITM_A, ITM_B, ITM_C, ITM_D, ITM_E, ITM_F => {
                frontier_calc_mode.calcModeNim(NOPARAM);
                aimBuffer[0] = '+';
                aimBuffer[1] = 0;
                nimNumberPart = NP_EMPTY;
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
            },

            ITM_CONSTpi => {
                if (nimNumberPart == NP_COMPLEX_INT_PART and aimBuffer[strlen(aimBuffer) - 1] == 'i') {
                    done = true;
                    _ = strcat(aimBuffer, "3.141592653589793238462643383279503");
                    frontier_items.reallyRunFunction(ITM_EXIT1, NOPARAM);
                    frontier_screen.setLastintegerBasetoZero();
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
                } else {
                    done = true;
                    closeNim();
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
                    frontier_addons.fnAngularModeJM(amDMS);
                    // IR_PRINTING
                    frontier_print.printTrace(ITM_DMS2, NOPARAM);
                    frontier_print.printTraceX(LINE_FULL_C);
                }
            },

            ITM_DRG => {
                DRG_Cycling = 0;
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

            ITM_NOP => {},

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
                    if ((getSystemFlag(FLAG_POLAR) != 0 and temporaryFlagRect == 0) or temporaryFlagPolar != 0) { // polar mode
                        _ = strcat(nimBufferDisplay, STD_SPACE_4_PER_EM ++ STD_MEASURED_ANGLE ++ STD_SPACE_4_PER_EM);
                        if (aimBuffer[@intCast(imaginaryMantissaSignLocation)] == '-') {
                            _ = strcat(nimBufferDisplay, "-");
                        }
                    } else if ((getSystemFlag(FLAG_POLAR) == 0 and temporaryFlagPolar == 0) or temporaryFlagRect != 0) { // rectangular mode
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
            if (comptime !dmcp_build) {
                // PC_BUILD && VERBOSE_MINIMUM block: VERBOSE_MINIMUM not defined -> skip.
            }
            if (delayCloseNim == 0) {
                switch (item) {
                    ITM_HASH_JM, ITM_toINT, -MNU_BASE, -MNU_INTS, -MNU_BITS => {},
                    else => {
                        screenUpdatingMode &= ~@as(u8, SCRUPD_SKIP_STACK_ONE_TIME);
                        closeNim();
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
