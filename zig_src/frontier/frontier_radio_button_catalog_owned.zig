// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/c47Extensions/radioButtonCatalog.c: the radio-button /
// check-box state catalog (indexOfRadioCbEepromItems and its companion
// fittingParams / systemFlagParams tables) plus fnCbIsSet / fnRefreshState /
// fnItemShowValue and the figlabel / stringToSub label-rendering helpers
// (add_digitglyph_to_tmp2 / use_base_glyphs). Faithful, line-by-line port.
//
// The three TO_QSPI tables hold only integer fields (no pointers), so they stay
// in code_section (the executable QSPI region on flash-limited old_hw DM42),
// like the sibling pure-byte tables. The INLINE_TEST JC_ITM_TST check-box case
// is #if defined(INLINE_TEST), never defined for any z47 build, and is omitted.
//
// radioButtonCatalog.c is not reachable from the testSuite; verification is by
// build/link across every target plus the boundary gates.

const builtin = @import("builtin");
const frontier_build_options = @import("frontier_build_options");

const code_section = if (frontier_build_options.dmcp_build and frontier_build_options.old_hw)
    ".qspi_data"
else if (builtin.target.os.tag == .macos)
    "__TEXT,__text"
else
    ".text";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const bool_t = bool;
const angularMode_t = c_int;

const radiocb_t = extern struct {
    itemNr: i16,
    param: u16,
    radioButton: u8,
};

// normKey_t (typeDefinitions.h): only Norm_Key_00.func (offset 0) is read.
const normKey_t = abi.NormKey;
const print_modes_t = c_int; // enum, 4 bytes
const printerModel_t = c_int; // enum, 4 bytes
const printerState_t = abi.PrinterState;
const ItemFn = ?*const fn (u16) callconv(.c) void;
const abi = @import("abi"); // L1 shared bindings
const item_t = abi.Item;

// ---------------------------------------------------------------------------
// Constants (verified via C probe against the sim build)
// ---------------------------------------------------------------------------
const NOVAL: i8 = -126;
const ITEM_NOT_CODED: i16 = -127;
const RB_FALSE: i8 = 0;
const RB_TRUE: i8 = 1;
const CB_FALSE: i8 = 2;
const CB_TRUE: i8 = 3;
const MB_FALSE: i8 = 4;
const MB_TRUE: i8 = 5;

const RB_AM: u8 = 128;
const RB_CM: u8 = 129;
const RB_CU: u8 = 130;
const RB_DF: u8 = 132;
const RB_DI: u8 = 133;
const RB_DO: u8 = 134;
const RB_IM: u8 = 135;
const RB_PS: u8 = 136;
const RB_SS: u8 = 137;
const RB_TF: u8 = 138;
const RB_WS: u8 = 139;
const RB_SA: u8 = 140;
const RB_ID: u8 = 141;
const CB_JC: u8 = 142;
const RB_HX: u8 = 143;
const RB_BCD: u8 = 145;
const RB_M: u8 = 146;
const RB_F: u8 = 147;
const RB_TV: u8 = 148;
const RB_IP: u8 = 150;
const RB_FP: u8 = 151;
const RB_RX: u8 = 152;
const RB_GW: u8 = 156;
const RB_KY: u8 = 157;
const RB_PRM: u8 = 158;
const RB_PRON: u8 = 159;
const RB_PM: u8 = 160;
const MB_MAC: u8 = 244;

const CM_RECTANGULAR: u16 = 238;
const CM_POLAR: u16 = 239;
const CU_I: u16 = 232;
const CU_J: u16 = 233;
const DF_MDY: u16 = 2;
const DF_DMY: u16 = 0;
const DF_YMD: u16 = 1;
const DO_SCI: u16 = 240;
const DO_ENG: u16 = 241;
const PS_DOT: u16 = 234;
const PS_CROSS: u16 = 235;
const SS_4: u16 = 236;
const SS_8: u16 = 237;
const TF_H24: u16 = 230;
const TF_H12: u16 = 231;
const FN_BEG: u16 = 242;
const FN_END: u16 = 243;
const ITM_M_GROW: u16 = 1533;
const ITM_M_WRAP: u16 = 1541;

const ITM_USER_R47: u16 = 1964; // item id (items.h) — distinct from the USER_R47 setting value (66)
const USER_R47: u16 = 66;
const USER_R47f_g: u16 = 61;
const USER_R47bk_fg: u16 = 62;
const USER_R47fg_bk: u16 = 63;
const USER_R47fg_g: u16 = 64;

const JC_LINEAR_FITTING: u16 = 199;
const JC_EXPONENTIAL_FITTING: u16 = 200;
const JC_LOGARITHMIC_FITTING: u16 = 201;
const JC_POWER_FITTING: u16 = 202;
const JC_ROOT_FITTING: u16 = 203;
const JC_HYPERBOLIC_FITTING: u16 = 204;
const JC_PARABOLIC_FITTING: u16 = 205;
const JC_CAUCHY_FITTING: u16 = 206;
const JC_GAUSS_FITTING: u16 = 207;
const JC_ORTHOGONAL_FITTING: u16 = 208;
const JC_DIFF: u16 = 192;
const JC_INTG: u16 = 191;
const JC_RMS: u16 = 193;
const JC_SHADE: u16 = 194;
const JC_UC: u16 = 198;
const JC_SS: u16 = 214;

const CF_LINEAR_FITTING: u16 = 1;
const CF_EXPONENTIAL_FITTING: u16 = 2;
const CF_LOGARITHMIC_FITTING: u16 = 4;
const CF_POWER_FITTING: u16 = 8;
const CF_ROOT_FITTING: u16 = 16;
const CF_HYPERBOLIC_FITTING: u16 = 32;
const CF_PARABOLIC_FITTING: u16 = 64;
const CF_CAUCHY_FITTING: u16 = 128;
const CF_GAUSS_FITTING: u16 = 256;
const CF_ORTHOGONAL_FITTING: u16 = 512;

const ITM_S08: u16 = 1990;
const ITM_U08: u16 = 1995;
const ITM_S16: u16 = 1991;
const ITM_U16: u16 = 1996;
const ITM_S32: u16 = 1992;
const ITM_U32: u16 = 1997;
const ITM_S64: u16 = 1993;
const ITM_U64: u16 = 1998;
const ITM_SETCHN: u16 = 1591;
const ITM_SETEUR: u16 = 1593;
const ITM_SETIND: u16 = 1594;
const ITM_SETJPN: u16 = 1595;
const ITM_SETUK: u16 = 1598;
const ITM_SETUSA: u16 = 1599;
const ITM_SETDFLT: u16 = 1596;

const SIM_UNSIGN: u8 = 0;
const SIM_2COMPL: u8 = 2;
const NC_NORMAL: u8 = 0;

const FLAG_POLAR: i32 = 32774;
const FLAG_CPXj: i32 = 32773;
const FLAG_YMD: i32 = 49153;
const FLAG_DMY: i32 = 49154;
const FLAG_ENGOVR: i32 = 32796;
const FLAG_MULTx: i32 = 32795;
const FLAG_SSIZE8: i32 = 32792;
const FLAG_TDM24: i32 = 32768;
const FLAG_ENDPMT: i32 = 49193;
const FLAG_GROW: i32 = 32797;
const FLAG_TRACE: i32 = 32787;
const FLAG_NORM: i32 = 32872;
const FLAG_MYM_TRIPLE: u16 = 32863;
const FLAG_HOME_TRIPLE: u16 = 32864;
const FLAG_BASE_HOME: u16 = 32862;
const FLAG_BASE_MYM: u16 = 32860;
const FLAG_FGLNLIM: u16 = 32866;
const FLAG_FGLNFUL: u16 = 32867;

const MAN: i32 = 0;
const NORM: i32 = 1;
const TRACE: i32 = 2;
const STRACE: i32 = 3;

// fnItemShowValue item ids.
const ITM_DSTACK: u16 = 1450;
const ITM_TDISP: u16 = 1619;
const ITM_SHOIREP: u16 = 2006;
const ITM_FIX: u16 = 1473;
const ITM_SIGFIG: u16 = 1866;
const ITM_ENG: u16 = 1460;
const ITM_UNIT: u16 = 1867;
const ITM_SCI: u16 = 1587;
const ITM_ALL: u16 = 1410;
const ITM_MZOOMY: u16 = 2034;
const ITM_PZOOMY: u16 = 2035;
const ITM_WSIZE: u16 = 1638;
const ITM_RNG: u16 = 2549;
const ITM_BASENR: u16 = 1689;
const ITM_SETSIG2: u16 = 2197;
const ITM_SETFDIGS: u16 = 2154;
const ITM_DSPCYCLE: u16 = 1864;
const ITM_SCR: u16 = 2191;
const ITM_DSP: u16 = 1573;
const ITM_SET_ADM: u16 = 2764;
const ITM_SET_ISM: u16 = 2765;
const ITM_SET_REALDF: u16 = 2767;
const ITM_SET_DMX: u16 = 2770;
const ITM_SET_NDEC: u16 = 2769;
const ITM_HIDE: u16 = 2195;
const ITM_BESTF: u16 = 1310;
const ITM_RMODE: u16 = 121;
const ITM_HASH_JM: u16 = 1872;
const ITM_TIMER_SIGMA_L: u16 = 1783;
const ITM_TIMER_SIGMA_T: u16 = 1782;
const ITM_TIMER_R_L: u16 = 1785;
const ITM_TIMER_R_T: u16 = 1784;
const ITM_VOL: u16 = 2198;
const ITM_VOLPLUS: u16 = 2200;
const ITM_VOLMINUS: u16 = 2201;
const ITM_PRINTERDLAY: u16 = 1710;

const DF_FIX: u8 = 1;
const DF_SF: u8 = 4;
const DF_ENG: u8 = 3;
const DF_UN: u8 = 5;
const DF_SCI: u8 = 2;
const DF_ALL: u8 = 0;
const CM_PLOT_STAT: u8 = 8;

// SIGMA_N == statisticalSumsPointer.
const SUM_N: u16 = 0;

// ---------------------------------------------------------------------------
// Globals (extern var)
// ---------------------------------------------------------------------------
extern var currentAngularMode: angularMode_t;
extern var displayFormat: u8;
extern var Input_Default: u8;
extern var shortIntegerMode: u8;
extern var shortIntegerWordSize: u8;
extern var LongPressF: u8;
extern var LongPressM: u8;
extern var bcdDisplaySign: u8;
extern var lastIntegerBase: u32;
extern var gapItemRight: u16;
extern var gapItemLeft: u16;
extern var gapItemRadix: u16;
extern var calcModel: u8;
extern var lrSelection: u16;
extern var alphaCase: u8;
extern var scrLock: u8;
extern var nextChar: u8;
extern var doRefreshSoftMenu: bool_t;
extern var displayStack: u8;
extern var timeDisplayFormatDigits: u8;
extern var displayStackSHOIDISP: u8;
extern var displayFormatDigits: u8;
extern var exponentLimit: i16;
extern var dispBase: u8;
extern var significantDigits: u8;
extern var fractionDigits: u8;
extern var denMax: u32;
extern var exponentHideLimit: i16;
extern var roundingMode: u8;
extern var timerCraAndDeciseconds: u8;
extern var Norm_Key_00: normKey_t;
extern var printerState: printerState_t;
extern var statisticalSumsPointer: ?*anyopaque;
// `indexOfItems` is a C ARRAY (const item_t indexOfItems[]); bind its address
// with @extern, not a pointer-typed extern (which loads the data as an address).
const indexOfItems = @extern([*c]const item_t, .{ .name = "indexOfItems" });

extern var PLOT_INTG: bool_t;
extern var PLOT_DIFF: bool_t;
extern var PLOT_RMS: bool_t;
extern var PLOT_SHADE: bool_t;
extern var PLOT_ZOOM: i8;
extern var PLOT_ZMY: i8;

// tmp[16] is a file-scope global in radioButtonCatalog.c.
pub export var tmp: [16]u8 = undefined;

// ---------------------------------------------------------------------------
// Function externs
// ---------------------------------------------------------------------------
extern fn itemNotAvail(itemNr: i16) bool_t;
extern fn isConfigCommon(id: u16) bool_t;
extern fn getSystemFlag(flag: i32) bool_t;
extern fn clearSystemFlag(flag: c_uint) void;
extern fn realToUint32C47(r: *const anyopaque, err: ?*bool_t) u32;
extern fn getBeepVolume() u16;
extern fn compressConversionName(msg1: [*c]u8) void;
extern fn itemToBeCoded(unusedButMandatoryParameter: u16) void;
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
extern fn strlen(s: [*c]const u8) usize;
extern fn snprintf(buf: [*c]u8, n: usize, fmt: [*:0]const u8, ...) c_int;

// ---------------------------------------------------------------------------
// Inline wrappers (the C macros)
// ---------------------------------------------------------------------------
inline fn stringCopy(dest: [*c]u8, source: [*c]const u8) [*c]u8 {
    return stpcpy(dest, source);
}
inline fn stringByteLength(s: [*c]const u8) i32 {
    return @intCast(strlen(s));
}
inline fn orOrtho(a: u16) u16 {
    return if (a == 0) CF_ORTHOGONAL_FITTING else a;
}
// shortIntegerModeValue() == (mode==SIM_2COMPL?2:(mode==SIM_1COMPL?1:(mode==SIM_UNSIGN?0:-1)))
inline fn shortIntegerModeValue() i16 {
    const SIM_1COMPL: u8 = 1;
    return if (shortIntegerMode == SIM_2COMPL) 2 else if (shortIntegerMode == SIM_1COMPL) 1 else if (shortIntegerMode == SIM_UNSIGN) 0 else -1;
}

// STD_* glyph byte sequences (fonts.h), verified via C probe.
const STD_BASE_0 = "\xa4\xea";
const STD_BASE_1 = "\xa4\x60";
const STD_SUB_A = "\xa4\xd0";
const STD_SUB_a = "\xa4\x9c";
const STD_SUB_0 = "\xa0\x80";
const STD_SUB_MINUS = "\xa0\x8b";
const STD_SUB_PLUS = "\xa0\x8a";
const STD_COMMA = "\x2c";
const STD_PERIOD = "\x2e";
const STD_UNDERSCORE = "\x5f";
const STD_OPEN_BOX = "\xa4\x23";
const STD_QUOTE = "\x27";
const STD_o_STROKE = "\x80\xf8";
const STD_INV_BRIDGE = "\xa3\xb5";
const STD_SPACE_PUNCTUATION = "\xa0\x08";
const STD_SPACE_4_PER_EM = "\xa0\x05";
const STD_SPACE_EM = "\xa0\x03";

// ---------------------------------------------------------------------------
// TO_QSPI tables (pure integer fields -> code_section). Generated byte-exact.
// ---------------------------------------------------------------------------
pub export const indexOfRadioCbEepromItems linksection(code_section) = [_]radiocb_t{
    .{ .itemNr = 1445, .param = 2, .radioButton = 128 },
    .{ .itemNr = 1451, .param = 3, .radioButton = 128 },
    .{ .itemNr = 1480, .param = 1, .radioButton = 128 },
    .{ .itemNr = 1523, .param = 4, .radioButton = 128 },
    .{ .itemNr = 1557, .param = 0, .radioButton = 128 },
    .{ .itemNr = 1453, .param = 0, .radioButton = 132 },
    .{ .itemNr = 1528, .param = 2, .radioButton = 132 },
    .{ .itemNr = 1649, .param = 1, .radioButton = 132 },
    .{ .itemNr = 1890, .param = 0, .radioButton = 141 },
    .{ .itemNr = 1889, .param = 4, .radioButton = 141 },
    .{ .itemNr = 1887, .param = 2, .radioButton = 141 },
    .{ .itemNr = 1891, .param = 7, .radioButton = 141 },
    .{ .itemNr = 1404, .param = 1, .radioButton = 135 },
    .{ .itemNr = 1406, .param = 2, .radioButton = 135 },
    .{ .itemNr = 1601, .param = 3, .radioButton = 135 },
    .{ .itemNr = 1629, .param = 0, .radioButton = 135 },
    .{ .itemNr = 1835, .param = 8, .radioButton = 139 },
    .{ .itemNr = 1836, .param = 16, .radioButton = 139 },
    .{ .itemNr = 1837, .param = 32, .radioButton = 139 },
    .{ .itemNr = 1838, .param = 64, .radioButton = 139 },
    .{ .itemNr = 1898, .param = 18124, .radioButton = 140 },
    .{ .itemNr = 1908, .param = 18115, .radioButton = 140 },
    .{ .itemNr = 1900, .param = 18116, .radioButton = 140 },
    .{ .itemNr = 1918, .param = 18277, .radioButton = 140 },
    .{ .itemNr = 1904, .param = 18113, .radioButton = 140 },
    .{ .itemNr = 1906, .param = 16817, .radioButton = 140 },
    .{ .itemNr = 1915, .param = 16384, .radioButton = 140 },
    .{ .itemNr = 1974, .param = 16492, .radioButton = 140 },
    .{ .itemNr = 1975, .param = 18257, .radioButton = 140 },
    .{ .itemNr = 1976, .param = 16423, .radioButton = 140 },
    .{ .itemNr = 1977, .param = 18179, .radioButton = 140 },
    .{ .itemNr = 1978, .param = 17789, .radioButton = 140 },
    .{ .itemNr = 1979, .param = 18006, .radioButton = 140 },
    .{ .itemNr = 2061, .param = 223, .radioButton = 147 },
    .{ .itemNr = 2062, .param = 226, .radioButton = 146 },
    .{ .itemNr = 2063, .param = 221, .radioButton = 147 },
    .{ .itemNr = 2064, .param = 224, .radioButton = 146 },
    .{ .itemNr = 2065, .param = 222, .radioButton = 147 },
    .{ .itemNr = 2060, .param = 225, .radioButton = 146 },
    .{ .itemNr = 1988, .param = 218, .radioButton = 145 },
    .{ .itemNr = 1986, .param = 219, .radioButton = 145 },
    .{ .itemNr = 1987, .param = 220, .radioButton = 145 },
    .{ .itemNr = 1533, .param = 1533, .radioButton = 156 },
    .{ .itemNr = 1541, .param = 1541, .radioButton = 156 },
    .{ .itemNr = 1299, .param = 199, .radioButton = 142 },
    .{ .itemNr = 1298, .param = 200, .radioButton = 142 },
    .{ .itemNr = 1300, .param = 201, .radioButton = 142 },
    .{ .itemNr = 1302, .param = 202, .radioButton = 142 },
    .{ .itemNr = 1307, .param = 203, .radioButton = 142 },
    .{ .itemNr = 1306, .param = 204, .radioButton = 142 },
    .{ .itemNr = 1305, .param = 205, .radioButton = 142 },
    .{ .itemNr = 1304, .param = 206, .radioButton = 142 },
    .{ .itemNr = 1303, .param = 207, .radioButton = 142 },
    .{ .itemNr = 1301, .param = 208, .radioButton = 142 },
    .{ .itemNr = 1946, .param = 239, .radioButton = 129 },
    .{ .itemNr = 1949, .param = 238, .radioButton = 129 },
    .{ .itemNr = 1936, .param = 232, .radioButton = 130 },
    .{ .itemNr = 1937, .param = 233, .radioButton = 130 },
    .{ .itemNr = 1951, .param = 241, .radioButton = 134 },
    .{ .itemNr = 1950, .param = 240, .radioButton = 134 },
    .{ .itemNr = 1944, .param = 235, .radioButton = 136 },
    .{ .itemNr = 1945, .param = 234, .radioButton = 136 },
    .{ .itemNr = 1938, .param = 236, .radioButton = 137 },
    .{ .itemNr = 1939, .param = 237, .radioButton = 137 },
    .{ .itemNr = 1942, .param = 231, .radioButton = 138 },
    .{ .itemNr = 1943, .param = 230, .radioButton = 138 },
    .{ .itemNr = 1415, .param = 242, .radioButton = 148 },
    .{ .itemNr = 1459, .param = 243, .radioButton = 148 },
    .{ .itemNr = 1959, .param = 46, .radioButton = 157 },
    .{ .itemNr = 1916, .param = 45, .radioButton = 157 },
    .{ .itemNr = 1964, .param = 66, .radioButton = 157 },
    .{ .itemNr = 2391, .param = 61, .radioButton = 142 },
    .{ .itemNr = 2392, .param = 62, .radioButton = 142 },
    .{ .itemNr = 2393, .param = 63, .radioButton = 142 },
    .{ .itemNr = 2394, .param = 64, .radioButton = 142 },
    .{ .itemNr = 2700, .param = 32869, .radioButton = 142 },
    .{ .itemNr = 2701, .param = 32870, .radioButton = 142 },
    .{ .itemNr = 1797, .param = 32861, .radioButton = 142 },
    .{ .itemNr = 1855, .param = 32865, .radioButton = 142 },
    .{ .itemNr = 1884, .param = 180, .radioButton = 142 },
    .{ .itemNr = 2024, .param = 191, .radioButton = 142 },
    .{ .itemNr = 2025, .param = 192, .radioButton = 142 },
    .{ .itemNr = 2026, .param = 193, .radioButton = 142 },
    .{ .itemNr = 2027, .param = 194, .radioButton = 142 },
    .{ .itemNr = 1856, .param = 32772, .radioButton = 142 },
    .{ .itemNr = 1940, .param = 32791, .radioButton = 142 },
    .{ .itemNr = 1857, .param = 32781, .radioButton = 142 },
    .{ .itemNr = 1917, .param = 32811, .radioButton = 142 },
    .{ .itemNr = 1924, .param = 32854, .radioButton = 142 },
    .{ .itemNr = 1895, .param = 32828, .radioButton = 142 },
    .{ .itemNr = 2052, .param = 32785, .radioButton = 142 },
    .{ .itemNr = 2053, .param = 32829, .radioButton = 142 },
    .{ .itemNr = 1876, .param = 32777, .radioButton = 142 },
    .{ .itemNr = 1877, .param = 32778, .radioButton = 142 },
    .{ .itemNr = 1888, .param = 32776, .radioButton = 142 },
    .{ .itemNr = 1744, .param = 32775, .radioButton = 142 },
    .{ .itemNr = 1948, .param = 49184, .radioButton = 142 },
    .{ .itemNr = 1853, .param = 32837, .radioButton = 142 },
    .{ .itemNr = 1851, .param = 32779, .radioButton = 142 },
    .{ .itemNr = 1852, .param = 32780, .radioButton = 142 },
    .{ .itemNr = 1896, .param = 32833, .radioButton = 142 },
    .{ .itemNr = 1865, .param = 32838, .radioButton = 142 },
    .{ .itemNr = 2056, .param = 32839, .radioButton = 142 },
    .{ .itemNr = 2384, .param = 32843, .radioButton = 142 },
    .{ .itemNr = 2014, .param = 32844, .radioButton = 142 },
    .{ .itemNr = 2015, .param = 32845, .radioButton = 142 },
    .{ .itemNr = 2011, .param = 32846, .radioButton = 142 },
    .{ .itemNr = 1980, .param = 32858, .radioButton = 142 },
    .{ .itemNr = 2010, .param = 32847, .radioButton = 142 },
    .{ .itemNr = 2162, .param = 32848, .radioButton = 142 },
    .{ .itemNr = 2009, .param = 32849, .radioButton = 142 },
    .{ .itemNr = 2007, .param = 32850, .radioButton = 142 },
    .{ .itemNr = 2012, .param = 32851, .radioButton = 142 },
    .{ .itemNr = 2013, .param = 32852, .radioButton = 142 },
    .{ .itemNr = 2029, .param = 32835, .radioButton = 142 },
    .{ .itemNr = 1729, .param = 32788, .radioButton = 142 },
    .{ .itemNr = 2039, .param = 32830, .radioButton = 142 },
    .{ .itemNr = 1899, .param = 32842, .radioButton = 142 },
    .{ .itemNr = 1798, .param = 32836, .radioButton = 142 },
    .{ .itemNr = 1858, .param = 198, .radioButton = 142 },
    .{ .itemNr = 2191, .param = 214, .radioButton = 142 },
    .{ .itemNr = 1985, .param = 32857, .radioButton = 142 },
    .{ .itemNr = 2008, .param = 32856, .radioButton = 142 },
    .{ .itemNr = 1831, .param = 2, .radioButton = 143 },
    .{ .itemNr = 1832, .param = 8, .radioButton = 143 },
    .{ .itemNr = 1833, .param = 10, .radioButton = 143 },
    .{ .itemNr = 1834, .param = 16, .radioButton = 143 },
    .{ .itemNr = 1854, .param = 32864, .radioButton = 142 },
    .{ .itemNr = 1861, .param = 32863, .radioButton = 142 },
    .{ .itemNr = 1859, .param = 32862, .radioButton = 142 },
    .{ .itemNr = 1796, .param = 32860, .radioButton = 142 },
    .{ .itemNr = 2058, .param = 32866, .radioButton = 142 },
    .{ .itemNr = 2059, .param = 32867, .radioButton = 142 },
    .{ .itemNr = 1897, .param = 32868, .radioButton = 142 },
    .{ .itemNr = 2111, .param = 849, .radioButton = 150 },
    .{ .itemNr = 2112, .param = 2143, .radioButton = 150 },
    .{ .itemNr = 2113, .param = 820, .radioButton = 150 },
    .{ .itemNr = 2114, .param = 2144, .radioButton = 150 },
    .{ .itemNr = 2115, .param = 818, .radioButton = 150 },
    .{ .itemNr = 2116, .param = 2145, .radioButton = 150 },
    .{ .itemNr = 2117, .param = 813, .radioButton = 150 },
    .{ .itemNr = 2118, .param = 2146, .radioButton = 150 },
    .{ .itemNr = 2119, .param = 873, .radioButton = 150 },
    .{ .itemNr = 2120, .param = 870, .radioButton = 150 },
    .{ .itemNr = 2121, .param = 868, .radioButton = 150 },
    .{ .itemNr = 2122, .param = 833, .radioButton = 150 },
    .{ .itemNr = 2123, .param = 0, .radioButton = 150 },
    .{ .itemNr = 2124, .param = 849, .radioButton = 151 },
    .{ .itemNr = 2125, .param = 2143, .radioButton = 151 },
    .{ .itemNr = 2126, .param = 820, .radioButton = 151 },
    .{ .itemNr = 2127, .param = 2144, .radioButton = 151 },
    .{ .itemNr = 2128, .param = 818, .radioButton = 151 },
    .{ .itemNr = 2129, .param = 2145, .radioButton = 151 },
    .{ .itemNr = 2130, .param = 813, .radioButton = 151 },
    .{ .itemNr = 2131, .param = 2146, .radioButton = 151 },
    .{ .itemNr = 2132, .param = 873, .radioButton = 151 },
    .{ .itemNr = 2133, .param = 870, .radioButton = 151 },
    .{ .itemNr = 2134, .param = 868, .radioButton = 151 },
    .{ .itemNr = 2135, .param = 833, .radioButton = 151 },
    .{ .itemNr = 2136, .param = 0, .radioButton = 151 },
    .{ .itemNr = 2137, .param = 849, .radioButton = 152 },
    .{ .itemNr = 2138, .param = 2143, .radioButton = 152 },
    .{ .itemNr = 2139, .param = 820, .radioButton = 152 },
    .{ .itemNr = 2140, .param = 2144, .radioButton = 152 },
    .{ .itemNr = 2141, .param = 818, .radioButton = 152 },
    .{ .itemNr = 2142, .param = 2145, .radioButton = 152 },
    .{ .itemNr = 1990, .param = 1990, .radioButton = 244 },
    .{ .itemNr = 1995, .param = 1995, .radioButton = 244 },
    .{ .itemNr = 1991, .param = 1991, .radioButton = 244 },
    .{ .itemNr = 1996, .param = 1996, .radioButton = 244 },
    .{ .itemNr = 1992, .param = 1992, .radioButton = 244 },
    .{ .itemNr = 1997, .param = 1997, .radioButton = 244 },
    .{ .itemNr = 1993, .param = 1993, .radioButton = 244 },
    .{ .itemNr = 1998, .param = 1998, .radioButton = 244 },
    .{ .itemNr = 1591, .param = 1591, .radioButton = 244 },
    .{ .itemNr = 1593, .param = 1593, .radioButton = 244 },
    .{ .itemNr = 1594, .param = 1594, .radioButton = 244 },
    .{ .itemNr = 1595, .param = 1595, .radioButton = 244 },
    .{ .itemNr = 1598, .param = 1598, .radioButton = 244 },
    .{ .itemNr = 1599, .param = 1599, .radioButton = 244 },
    .{ .itemNr = 1596, .param = 1596, .radioButton = 244 },
    .{ .itemNr = 2683, .param = 0, .radioButton = 158 },
    .{ .itemNr = 2684, .param = 1, .radioButton = 158 },
    .{ .itemNr = 2687, .param = 1, .radioButton = 159 },
    .{ .itemNr = 2688, .param = 0, .radioButton = 159 },
    .{ .itemNr = 2689, .param = 0, .radioButton = 160 },
    .{ .itemNr = 2690, .param = 1, .radioButton = 160 },
    .{ .itemNr = 2691, .param = 2, .radioButton = 160 },
    .{ .itemNr = 2692, .param = 3, .radioButton = 160 },
};

const FittingParam = extern struct { jcParam: u16, cfFlag: u16 };
pub export const fittingParams linksection(code_section) = [_]FittingParam{
    .{ .jcParam = JC_LINEAR_FITTING, .cfFlag = CF_LINEAR_FITTING },
    .{ .jcParam = JC_EXPONENTIAL_FITTING, .cfFlag = CF_EXPONENTIAL_FITTING },
    .{ .jcParam = JC_LOGARITHMIC_FITTING, .cfFlag = CF_LOGARITHMIC_FITTING },
    .{ .jcParam = JC_POWER_FITTING, .cfFlag = CF_POWER_FITTING },
    .{ .jcParam = JC_ROOT_FITTING, .cfFlag = CF_ROOT_FITTING },
    .{ .jcParam = JC_HYPERBOLIC_FITTING, .cfFlag = CF_HYPERBOLIC_FITTING },
    .{ .jcParam = JC_PARABOLIC_FITTING, .cfFlag = CF_PARABOLIC_FITTING },
    .{ .jcParam = JC_CAUCHY_FITTING, .cfFlag = CF_CAUCHY_FITTING },
    .{ .jcParam = JC_GAUSS_FITTING, .cfFlag = CF_GAUSS_FITTING },
};

// systemFlagParams holds raw FLAG_* values (verified via C probe).
pub export const systemFlagParams linksection(code_section) = [_]u16{
    32772, // FLAG_CPXRES
    32791, // FLAG_SPCRES
    32781, // FLAG_LEAD0
    32811, // FLAG_HPRP
    32854, // FLAG_MNUp1
    32828, // FLAG_HPBASE
    32785, // FLAG_AMORT_HP12C
    32829, // FLAG_2TO10
    32777, // FLAG_DENANY
    32778, // FLAG_DENFIX
    32776, // FLAG_PROPFR
    32775, // FLAG_FRACT
    49184, // FLAG_PRTACT
    32837, // FLAG_ERPN
    32779, // FLAG_CARRY
    32780, // FLAG_OVERFLOW
    32833, // FLAG_FRCYC
    32838, // FLAG_LARGELI
    32839, // FLAG_IRFRAC
    32843, // FLAG_CPXPLOT
    32844, // FLAG_SHOWX
    32845, // FLAG_SHOWY
    32846, // FLAG_PBOX
    32858, // FLAG_PCURVE
    32847, // FLAG_PCROS
    32848, // FLAG_PPLUS
    32849, // FLAG_PLINE
    32850, // FLAG_SCALE
    32851, // FLAG_VECT
    32852, // FLAG_NVECT
    32835, // FLAG_NUMLOCK
    32788, // FLAG_USER
    32830, // FLAG_SH_LONGPRESS
    32842, // FLAG_DREAL
    32836, // FLAG_CPXMULT
    32856, // FLAG_TOPHEX
    32857, // FLAG_BCD
    32861, // FLAG_G_DOUBLETAP
    32865, // FLAG_SHFT_4s
    32868, // FLAG_FGGR
    32869, // FLAG_3DPHYS
    32870, // FLAG_3DXYZ
    32787, // FLAG_TRACE
};

// ===========================================================================
// fnCbIsSet
// ===========================================================================
pub export fn fnCbIsSet(item: i16) callconv(.c) i8 {
    var result: i8 = NOVAL;
    const itemNr: i16 = @max(item, -%item);

    if (itemNotAvail(item)) {
        return result;
    }

    const n: usize = indexOfRadioCbEepromItems.len;
    var i: usize = 0;
    while (i < n) : (i += 1) {
        if (indexOfRadioCbEepromItems[i].itemNr == itemNr) {
            var is_cb: bool_t = false;
            var is_mb: bool_t = false;
            var rb_param: i32 = 0;
            var cb_param: bool_t = false;
            const param: u16 = indexOfRadioCbEepromItems[i].param;

            switch (indexOfRadioCbEepromItems[i].radioButton) {
                RB_AM => rb_param = currentAngularMode,
                RB_CM => {
                    if (getSystemFlag(FLAG_POLAR)) rb_param = CM_POLAR else rb_param = CM_RECTANGULAR;
                },
                RB_CU => {
                    if (getSystemFlag(FLAG_CPXj)) rb_param = CU_J else rb_param = CU_I;
                },
                RB_DF => {
                    if (getSystemFlag(FLAG_YMD)) rb_param = DF_YMD else if (getSystemFlag(FLAG_DMY)) rb_param = DF_DMY else rb_param = DF_MDY;
                },
                RB_DI => rb_param = displayFormat,
                RB_DO => {
                    if (getSystemFlag(FLAG_ENGOVR)) rb_param = DO_ENG else rb_param = DO_SCI;
                },
                RB_ID => rb_param = Input_Default,
                RB_IM => rb_param = shortIntegerMode,
                RB_PS => {
                    if (getSystemFlag(FLAG_MULTx)) rb_param = PS_CROSS else rb_param = PS_DOT;
                },
                RB_WS => rb_param = shortIntegerWordSize,
                RB_SS => {
                    if (getSystemFlag(FLAG_SSIZE8)) rb_param = SS_8 else rb_param = SS_4;
                },
                RB_TF => {
                    if (getSystemFlag(FLAG_TDM24)) rb_param = TF_H24 else rb_param = TF_H12;
                },
                RB_TV => {
                    if (getSystemFlag(FLAG_ENDPMT)) rb_param = FN_END else rb_param = FN_BEG;
                },
                RB_GW => {
                    if (getSystemFlag(FLAG_GROW)) rb_param = ITM_M_GROW else rb_param = ITM_M_WRAP;
                },
                RB_F => rb_param = LongPressF,
                RB_M => rb_param = LongPressM,
                RB_BCD => rb_param = bcdDisplaySign,
                RB_SA => rb_param = 16384 + @as(i32, Norm_Key_00.func),
                RB_HX => {
                    if (lastIntegerBase != 0) {
                        rb_param = @intCast(lastIntegerBase);
                    } else {
                        return result;
                    }
                },
                RB_FP => rb_param = gapItemRight,
                RB_IP => rb_param = gapItemLeft,
                RB_RX => rb_param = gapItemRadix,
                RB_KY => {
                    rb_param = calcModel;
                    if (itemNr == ITM_USER_R47) {
                        switch (calcModel) {
                            @as(u8, @intCast(USER_R47f_g)), @as(u8, @intCast(USER_R47bk_fg)), @as(u8, @intCast(USER_R47fg_bk)), @as(u8, @intCast(USER_R47fg_g)) => rb_param = USER_R47,
                            else => {},
                        }
                    }
                },
                MB_MAC => {
                    is_mb = true;
                    switch (param) {
                        ITM_S08 => cb_param = shortIntegerWordSize == 8 and shortIntegerMode == SIM_2COMPL,
                        ITM_U08 => cb_param = shortIntegerWordSize == 8 and shortIntegerMode == SIM_UNSIGN,
                        ITM_S16 => cb_param = shortIntegerWordSize == 16 and shortIntegerMode == SIM_2COMPL,
                        ITM_U16 => cb_param = shortIntegerWordSize == 16 and shortIntegerMode == SIM_UNSIGN,
                        ITM_S32 => cb_param = shortIntegerWordSize == 32 and shortIntegerMode == SIM_2COMPL,
                        ITM_U32 => cb_param = shortIntegerWordSize == 32 and shortIntegerMode == SIM_UNSIGN,
                        ITM_S64 => cb_param = shortIntegerWordSize == 64 and shortIntegerMode == SIM_2COMPL,
                        ITM_U64 => cb_param = shortIntegerWordSize == 64 and shortIntegerMode == SIM_UNSIGN,
                        ITM_SETCHN, ITM_SETEUR, ITM_SETIND, ITM_SETJPN, ITM_SETUK, ITM_SETUSA, ITM_SETDFLT => cb_param = isConfigCommon(param),
                        else => {},
                    }
                },
                RB_PRM => rb_param = printerState.printer_model,
                RB_PRON => rb_param = @intFromBool(printerState.print_on),
                RB_PM => rb_param = (if (getSystemFlag(FLAG_TRACE)) (if (getSystemFlag(FLAG_NORM)) STRACE else TRACE) else (if (getSystemFlag(FLAG_NORM)) NORM else MAN)),
                CB_JC => {
                    is_cb = true;

                    var param_found: bool_t = false;

                    var j: usize = 0;
                    while (j < fittingParams.len) : (j += 1) { // Check fitting parameters
                        if (param == fittingParams[j].jcParam) {
                            cb_param = ((lrSelection & fittingParams[j].cfFlag) == fittingParams[j].cfFlag);
                            param_found = true;
                            break;
                        }
                    }

                    if (!param_found) {
                        j = 0;
                        while (j < systemFlagParams.len) : (j += 1) { // Check system flag parameters
                            if (param == systemFlagParams[j]) {
                                cb_param = getSystemFlag(param);
                                param_found = true;
                                break;
                            }
                        }
                    }

                    if (!param_found) {
                        switch (param) {
                            USER_R47f_g, USER_R47bk_fg, USER_R47fg_bk, USER_R47fg_g => cb_param = calcModel == param,
                            JC_ORTHOGONAL_FITTING => cb_param = (orOrtho(lrSelection) == CF_ORTHOGONAL_FITTING),
                            JC_DIFF => cb_param = PLOT_DIFF,
                            JC_INTG => cb_param = PLOT_INTG,
                            JC_RMS => cb_param = PLOT_RMS,
                            JC_SHADE => cb_param = PLOT_SHADE,
                            JC_UC => cb_param = !(alphaCase != 0),
                            JC_SS => cb_param = scrLock != NC_NORMAL,
                            FLAG_MYM_TRIPLE, FLAG_HOME_TRIPLE => {
                                cb_param = getSystemFlag(param);
                                if (getSystemFlag(FLAG_HOME_TRIPLE) and getSystemFlag(FLAG_MYM_TRIPLE)) {
                                    clearSystemFlag(FLAG_MYM_TRIPLE);
                                }
                            },
                            FLAG_BASE_HOME, FLAG_BASE_MYM => {
                                cb_param = getSystemFlag(param);
                                if (getSystemFlag(FLAG_BASE_HOME) and getSystemFlag(FLAG_BASE_MYM)) {
                                    clearSystemFlag(FLAG_BASE_HOME);
                                }
                            },
                            FLAG_FGLNLIM, FLAG_FGLNFUL => {
                                cb_param = getSystemFlag(param);
                                if (getSystemFlag(FLAG_FGLNLIM) and getSystemFlag(FLAG_FGLNFUL)) {
                                    clearSystemFlag(FLAG_FGLNLIM);
                                }
                            },
                            // INLINE_TEST (JC_ITM_TST) is never defined for any z47 build.
                            else => {},
                        }
                    }
                },
                else => {},
            }

            if (is_mb) {
                result = if (cb_param) MB_TRUE else MB_FALSE;
            } else if (is_cb) {
                result = if (cb_param) CB_TRUE else CB_FALSE;
            } else {
                result = if (indexOfRadioCbEepromItems[i].param == rb_param) RB_TRUE else RB_FALSE;
            }
        }
    }
    return result;
}

// ===========================================================================
// fnRefreshState
// ===========================================================================
pub export fn fnRefreshState() callconv(.c) void {
    doRefreshSoftMenu = true;
}

// ===========================================================================
// fnItemShowValue
// ===========================================================================
pub export fn fnItemShowValue(item: i16) callconv(.c) i16 {
    var result: i16 = NOVAL;
    const itemNr: u16 = @intCast(@max(item, -%item));
    switch (itemNr) {
        ITM_DSTACK => result = displayStack,
        ITM_TDISP => result = timeDisplayFormatDigits,
        ITM_SHOIREP => result = displayStackSHOIDISP,
        ITM_FIX => if (displayFormat == DF_FIX) {
            result = displayFormatDigits;
        },
        ITM_SIGFIG => if (displayFormat == DF_SF) {
            result = displayFormatDigits;
        },
        ITM_ENG => if (displayFormat == DF_ENG) {
            result = displayFormatDigits;
        },
        ITM_UNIT => if (displayFormat == DF_UN) {
            result = displayFormatDigits;
        },
        ITM_SCI => if (displayFormat == DF_SCI) {
            result = displayFormatDigits;
        },
        ITM_ALL => if (displayFormat == DF_ALL) {
            result = displayFormatDigits;
        },
        ITM_MZOOMY, ITM_PZOOMY => result = if (calcMode == CM_PLOT_STAT) PLOT_ZOOM else PLOT_ZMY,
        ITM_WSIZE => result = shortIntegerWordSize,
        ITM_RNG => result = exponentLimit,
        ITM_BASENR => result = dispBase,
        ITM_SETSIG2 => result = (if (significantDigits == 0) 34 else significantDigits),
        ITM_SETFDIGS => result = (if (fractionDigits == 0) 34 else fractionDigits),
        ITM_DSPCYCLE => result = 32700 + @as(i16, displayFormat),
        ITM_SCR => result = @as(i16, scrLock & 0x03) | @as(i16, nextChar & 0x03),
        ITM_DSP => result = displayFormatDigits,
        ITM_SET_ADM => result = @intCast(currentAngularMode),
        ITM_SET_ISM => result = shortIntegerModeValue(),
        ITM_SET_REALDF => result = displayFormat,
        ITM_SET_DMX => result = @intCast(denMax),
        ITM_SET_NDEC => result = displayFormatDigits,
        ITM_HIDE => result = exponentHideLimit,
        ITM_BESTF => result = @intCast(lrSelection & 0x1FF),
        ITM_RMODE => result = roundingMode,
        ITM_HASH_JM => if (lastIntegerBase != 0) {
            result = @intCast(lastIntegerBase);
        },
        ITM_TIMER_SIGMA_L, ITM_TIMER_SIGMA_T => result = if (statisticalSumsPointer == null) 0 else @intCast(realToUint32C47(@ptrCast(statisticalSumsPointer.?), null)),
        ITM_TIMER_R_L, ITM_TIMER_R_T => result = timerCraAndDeciseconds & 0x7F,
        ITM_VOL, ITM_VOLPLUS, ITM_VOLMINUS => result = @intCast(getBeepVolume()),
        ITM_PRINTERDLAY => result = @intCast(printerState.delay),
        else => if (indexOfItems[itemNr].func == &itemToBeCoded) {
            result = ITEM_NOT_CODED;
        },
    }
    return result;
}

// calcMode is read in fnItemShowValue's PLOT_ZOOM case.
extern var calcMode: u8;

// ===========================================================================
// add_digitglyph_to_tmp2
// ===========================================================================
pub export fn add_digitglyph_to_tmp2(tmp2: [*c]u8, xx: i16) callconv(.c) void {
    tmp2[0] = 0;

    _ = stringCopy(tmp2, STD_BASE_0); // can also be STD_SUB_0 for a slightly raised look
    if (1 <= xx and xx <= 16) {
        _ = stringCopy(tmp2, STD_BASE_1); // can also be STD_SUB_1 for a slightly raised look
        tmp2[1] +%= @intCast(xx - 1);
    }
}

// ===========================================================================
// use_base_glyphs
// ===========================================================================
pub export fn use_base_glyphs(tmp1: [*c]u8, xx: i16) callconv(.c) void {
    var tmp2: [16]u8 = undefined;
    tmp1[0] = 0;

    if (xx <= 16) {
        add_digitglyph_to_tmp2(&tmp2, xx);
        _ = stringCopy(tmp1, &tmp2);
    } else if (xx <= 99) {
        add_digitglyph_to_tmp2(&tmp2, @divTrunc(xx, 10));
        _ = stringCopy(tmp1, &tmp2);
        add_digitglyph_to_tmp2(&tmp2, @rem(xx, 10));
        _ = stringCopy(tmp1 + @as(usize, @intCast(stringByteLength(tmp1))), &tmp2);
    } else if (xx <= 999) {
        add_digitglyph_to_tmp2(&tmp2, @divTrunc(xx, 100));
        _ = stringCopy(tmp1, &tmp2);
        add_digitglyph_to_tmp2(&tmp2, @divTrunc(@rem(xx, 100), 10));
        _ = stringCopy(tmp1 + @as(usize, @intCast(stringByteLength(tmp1))), &tmp2);
        add_digitglyph_to_tmp2(&tmp2, @rem(@rem(xx, 100), 10));
        _ = stringCopy(tmp1 + @as(usize, @intCast(stringByteLength(tmp1))), &tmp2);
    } else if (xx <= 9999) {
        add_digitglyph_to_tmp2(&tmp2, @divTrunc(xx, 1000));
        _ = stringCopy(tmp1, &tmp2);
        add_digitglyph_to_tmp2(&tmp2, @divTrunc(@rem(xx, 1000), 100));
        _ = stringCopy(tmp1 + @as(usize, @intCast(stringByteLength(tmp1))), &tmp2);
        add_digitglyph_to_tmp2(&tmp2, @divTrunc(@rem(@rem(xx, 1000), 100), 10));
        _ = stringCopy(tmp1 + @as(usize, @intCast(stringByteLength(tmp1))), &tmp2);
        add_digitglyph_to_tmp2(&tmp2, @rem(@rem(@rem(xx, 1000), 100), 10));
        _ = stringCopy(tmp1 + @as(usize, @intCast(stringByteLength(tmp1))), &tmp2);
    } else {
        _ = snprintf(tmp1, 12, "%d", @as(c_int, xx));
    }
}

// ===========================================================================
// stringToSub (file-scope static buf[64])
// ===========================================================================
var stringToSub_buf: [64]u8 = undefined;
pub export fn stringToSub(showTextIn: [*c]const u8) callconv(.c) [*c]u8 {
    var showText = showTextIn;
    stringToSub_buf[0] = 0;
    while (showText[0] != 0 and stringByteLength(&stringToSub_buf) + 2 < @as(i32, @intCast(stringToSub_buf.len))) {
        if (showText[0] >= 'A' and showText[0] <= 'Z') {
            _ = stringCopy(&stringToSub_buf[@intCast(stringByteLength(&stringToSub_buf))], STD_SUB_A);
            stringToSub_buf[@intCast(stringByteLength(&stringToSub_buf) - 1)] +%= showText[0] - 'A';
        } else if (showText[0] >= 'a' and showText[0] <= 'z') {
            _ = stringCopy(&stringToSub_buf[@intCast(stringByteLength(&stringToSub_buf))], STD_SUB_a);
            stringToSub_buf[@intCast(stringByteLength(&stringToSub_buf) - 1)] +%= showText[0] - 'a';
        } else if (showText[0] >= '0' and showText[0] <= '9') {
            _ = stringCopy(&stringToSub_buf[@intCast(stringByteLength(&stringToSub_buf))], STD_SUB_0);
            stringToSub_buf[@intCast(stringByteLength(&stringToSub_buf) - 1)] +%= showText[0] - '0';
        } else {
            var tt: [2]u8 = undefined;
            tt[0] = showText[0];
            tt[1] = 0;
            _ = stringCopy(&stringToSub_buf[@intCast(stringByteLength(&stringToSub_buf))], &tt);
        }
        showText += 1;
    }
    return &stringToSub_buf;
}

// ===========================================================================
// figlabel (uses the module-level tmp[16])
// ===========================================================================
pub export fn figlabel(label: [*c]const u8, showText: [*c]const u8, showValueIn: i16) callconv(.c) [*c]u8 {
    var showValue = showValueIn;
    var tmp1: [16]u8 = undefined;
    tmp[0] = 0;

    if (stringByteLength(label) <= 15) {
        _ = stringCopy(&tmp, label);
    }

    if (showValue != NOVAL and showValue != ITEM_NOT_CODED and showValue < 0) {
        _ = stringCopy(&tmp[@intCast(stringByteLength(&tmp))], STD_SUB_MINUS);
    }

    if (showValue != NOVAL and showValue != ITEM_NOT_CODED and stringByteLength(label) <= 8) {
        showValue = @max(showValue, -%showValue);
        use_base_glyphs(&tmp1, showValue);
        _ = stringCopy(&tmp[@intCast(stringByteLength(&tmp))], &tmp1);
    }

    if (showText[0] != 0 and stringByteLength(&tmp) + stringByteLength(showText) + 1 <= 15) {
        var ii: u16 = 0;
        while (showText[ii] != 0) {
            switch (showText[ii]) {
                '+' => _ = stringCopy(&tmp[@intCast(stringByteLength(&tmp))], STD_SUB_PLUS),
                ',' => _ = stringCopy(&tmp[@intCast(stringByteLength(&tmp))], STD_COMMA),
                '-' => _ = stringCopy(&tmp[@intCast(stringByteLength(&tmp))], STD_SUB_MINUS),
                '.' => _ = stringCopy(&tmp[@intCast(stringByteLength(&tmp))], STD_PERIOD),
                '_' => _ = stringCopy(&tmp[@intCast(stringByteLength(&tmp))], STD_UNDERSCORE),
                ' ' => _ = stringCopy(&tmp[@intCast(stringByteLength(&tmp))], STD_OPEN_BOX),
                '\'' => _ = stringCopy(&tmp[@intCast(stringByteLength(&tmp))], STD_QUOTE),
                else => {
                    const tmpi: u16 = (@as(u16, @as(u8, @bitCast(showText[ii])) & 0x00FF) << 8) + @as(u16, @as(u8, @bitCast(showText[ii + 1])));
                    if (0x0101 == tmpi) {
                        _ = stringCopy(&tmp[@intCast(stringByteLength(&tmp))], STD_o_STROKE);
                        ii += 1;
                    } else if ((showText[ii] & 0x80) != 0 and (showText[ii + 1] != 0)) {
                        var tt: [3]u8 = undefined;
                        tt[0] = 0;
                        tt[1] = 0;
                        tt[2] = 0;

                        if ((@as(u16, STD_SPACE_PUNCTUATION[0] & 0x00FF) << 8) + (STD_SPACE_PUNCTUATION[1] & 0x00FF) == tmpi) {
                            _ = stringCopy(&tmp[@intCast(stringByteLength(&tmp))], STD_OPEN_BOX);
                            ii += 1;
                        } else if ((@as(u16, STD_SPACE_4_PER_EM[0] & 0x00FF) << 8) + (STD_SPACE_4_PER_EM[1] & 0x00FF) == tmpi) {
                            _ = stringCopy(&tmp[@intCast(stringByteLength(&tmp))], STD_INV_BRIDGE);
                            ii += 1;
                        } else if ((@as(u16, STD_SPACE_EM[0] & 0x00FF) << 8) + (STD_SPACE_EM[1] & 0x00FF) == tmpi) {
                            _ = stringCopy(&tmp[@intCast(stringByteLength(&tmp))], STD_OPEN_BOX ++ STD_OPEN_BOX);
                            ii += 1;
                        } else { // double byte
                            tt[0] = showText[ii];
                            ii += 1;
                            tt[1] = showText[ii];
                            _ = stringCopy(&tmp[@intCast(stringByteLength(&tmp))], &tt);
                        }
                    } else { // single byte
                        var tt: [2]u8 = undefined;
                        tt[0] = showText[ii];
                        tt[1] = 0;
                        _ = stringCopy(&tmp[@intCast(stringByteLength(&tmp))], stringToSub(&tt));
                    }
                },
            }
            ii += 1;
        }
    }
    compressConversionName(&tmp);
    return &tmp;
}
