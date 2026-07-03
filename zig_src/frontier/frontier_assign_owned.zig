const std = @import("std");
// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/assign.c: the keyboard-layout tables (kbd_std_C47,
// kbd_std_DM42, the four R47 variants, and the host-only E47/V47/N47/D47) plus the
// ASSIGN / user-menu machinery (fnAssign, removeUserItemAssignments, fnDeleteMenu,
// fnDeleteUserMenus, fnClearUserMenus, updateAssignTamBuffer, _assignItem,
// assignToMyMenu, assignToMyAlpha, assignToUserMenu, assignToKey,
// initUserKeyArgument, setUserKeyArgument, createMenu, assignEnterAlpha,
// assignLeaveAlpha, assignGetName1, assignGetName2) and the file-static helpers
// (_typeOfFunction, _assignTamAlpha, _assignTamNum, _assignToKey). Faithful,
// line-by-line port.
//
// The kbd_std_E47/V47/N47/D47 tables are host-only (#if PC_BUILD) and exported
// only when !dmcp_build. The keyboard tables are pure int16 -> code_section. The
// EXTRA_INFO_ON_CALC_ERROR console hints are compiled out on firmware (gated on
// extra_info && !dmcp_build, like the sibling owners). The PC_BUILD abortf/printf
// diagnostics in createMenu / removeUserItemAssignments are host-only. calcModeAimGui
// / calcModeNormalGui / calcModeTamGui are no-op macros on firmware and real
// externs on host, so they are gated on !dmcp_build.
//
// assign.c is not reachable from the testSuite; verification is build/link across
// every target plus the boundary gates.

const builtin = @import("builtin");
const frontier_build_options = @import("frontier_build_options");
const dmcp_build: bool = frontier_build_options.dmcp_build;
const old_hw: bool = frontier_build_options.old_hw;
const extra_info: bool = frontier_build_options.extra_info_on_calc_error;

// Pure int16 tables: executable QSPI region on flash-limited old_hw DM42.
const code_section = if (dmcp_build and old_hw)
    ".qspi_data"
else if (builtin.target.os.tag == .macos)
    "__TEXT,__text"
else
    ".text";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const bool_t = bool;
const abi = @import("abi"); // L1 shared bindings
const calcKey_t = abi.CalcKey;
const userMenuItem_t = abi.UserMenuItem;
const userMenu_t = abi.UserMenu;
const registerHeader_t = abi.RegisterHeader;
const namedVariableHeader_t = abi.NamedVariableHeader;
const reservedVariableHeader_t = extern struct {
    header: registerHeader_t,
    reservedVariableName: [8]u8,
};
const labelList_t = extern struct {
    program: i16,
    step: i32,
    labelPointer: [*c]u8,
    instructionPointer: [*c]u8,
};
const softmenu_t = abi.Softmenu;
const item_t = abi.Item;

// ---------------------------------------------------------------------------
// Constants (defines.h / typeDefinitions.h)
// ---------------------------------------------------------------------------
const ITM_NULL: i16 = 0;
const ITM_XEQ: i16 = 3;
const ITM_RCL: i16 = 51;
const ITM_ASSIGN: i16 = 1411;
const ITM_ENTER: i16 = 35;
const ITM_EXIT1: i16 = 1737;
const ITM_USERMODE: i16 = 1729;
const ITM_UP1: i16 = 1733;
const ITM_DOWN1: i16 = 1735;
const ITM_BACKSPACE: i16 = 1738;
const ITM_PLUS: i16 = 817;
const ITM_MINUS: i16 = 819;
const ITM_CROSS: i16 = 855;
const ITM_DOT: i16 = 849;
const ITM_PROD_SIGN: i16 = 9999;
const ITM_SLASH: i16 = 821;
const ITM_ADD: i16 = 95;
const ITM_SUB: i16 = 96;
const ITM_MULT: i16 = 98;
const ITM_DIV: i16 = 99;

const ITM_A: i16 = 550;
const ITM_B: i16 = 551;
const ITM_C: i16 = 552;
const ITM_D: i16 = 553;
const ITM_E: i16 = 554;
const ITM_H: i16 = 557;
const ITM_I: i16 = 558;
const ITM_J: i16 = 559;
const ITM_K: i16 = 560;
const ITM_L: i16 = 561;
const ITM_M: i16 = 562;
const ITM_N: i16 = 563;
const ITM_O: i16 = 564;
const ITM_P: i16 = 565;
const ITM_R: i16 = 567;
const ITM_S: i16 = 568;
const ITM_T: i16 = 569;

const ITM_REG_A: i16 = 531;
const ITM_REG_B: i16 = 532;
const ITM_REG_C: i16 = 533;
const ITM_REG_D: i16 = 534;
const ITM_REG_E: i16 = 2342;
const ITM_REG_H: i16 = 2345;
const ITM_REG_I: i16 = 536;
const ITM_REG_J: i16 = 537;
const ITM_REG_K: i16 = 538;
const ITM_REG_L: i16 = 535;
const ITM_REG_M: i16 = 2336;
const ITM_REG_N: i16 = 2337;
const ITM_REG_O: i16 = 2346;
const ITM_REG_P: i16 = 2338;
const ITM_REG_R: i16 = 2340;
const ITM_REG_S: i16 = 2341;
const ITM_REG_T: i16 = 530;

const ITM_0: i16 = 540;
const ITM_9: i16 = 549;
const ITM_PERIOD: i16 = 820;

const MNU_DYNAMIC: i16 = 1394;

const ASSIGN_CLEAR: i16 = -32768;
const ASSIGN_LABELS: i16 = 12000;
const ASSIGN_RESERVED_VARIABLES: i16 = 11744;
const ASSIGN_NAMED_VARIABLES: i16 = 10000;
const ASSIGN_USER_MENU: i16 = -10000;

const CMP_NAME: i32 = 3;
const NOT_CONFIRMED: u16 = 9878;
const NOPARAM: u16 = 9876;
const INVALID_VARIABLE: i16 = 2199;
const FIRST_LABEL: i16 = 2200;
const LAST_ITEM: i32 = 2860;
const CAT_STATUS: u16 = 240;
const CAT_FNCT: u16 = 16;

const ERROR_CANNOT_DELETE_PREDEF_ITEM: u8 = 27;
const ERROR_ENTER_NEW_NAME: u8 = 26;
const ERROR_INVALID_NAME: u8 = 48;
const ERROR_CANNOT_ASSIGN_HERE: u8 = 47;
const ERR_REGISTER_LINE: i16 = 102;
const NIM_REGISTER_LINE: i16 = 100;
const REGISTER_X: i16 = 100;

const TI_NO_INFO: u8 = 0;
const TI_DEL_ALL_MENUS: u8 = 100;
const TI_CLEAR_ALL_MENUS: u8 = 97;
const SCRUPD_AUTO: u8 = 0;

const FLAG_ALPHA: c_uint = 32782;

const CM_ASSIGN: u8 = 4;
const CM_AIM: u8 = 1;
const CM_NORMAL: u8 = 0;

const BPB: u5 = 2;
const BYTES_PER_BLOCK: usize = 4;
inline fn TO_BLOCKS(n: usize) usize {
    return (n + (BYTES_PER_BLOCK - 1)) >> BPB;
}
const SIZEOF_USERMENU: usize = @sizeOf(userMenu_t);
const SIZEOF_USERMENUITEM: usize = @sizeOf(userMenuItem_t);

// ---------------------------------------------------------------------------
// Globals (extern var/const)
// ---------------------------------------------------------------------------
extern var calcMode: u8;
extern var previousCalcMode: u8;
extern var itemToBeAssigned: i16;
extern var cachedDynamicMenu: i16;
extern var aimBuffer: [*c]u8;
extern var tmpString: [*c]u8;
extern var tamBuffer: [*c]u8;
extern var errorMessage: [*c]u8;
extern var alphaCursor: i16;
extern var shiftF: bool_t;
extern var shiftG: bool_t;
extern var keyStateCode: u8;
extern var numberOfUserMenus: u16;
extern var currentUserMenu: u16;
extern var programRunStop: u8;
extern var temporaryInformation: u8;
extern var screenUpdatingMode: u8;
extern var userKeyLabel: [*c]u8;
extern var userKeyLabelSize: u16;
extern var userMenus: [*c]userMenu_t;
extern var userMenuItems: [18]userMenuItem_t;
extern var userAlphaItems: [18]userMenuItem_t;
extern var kbd_usr: [37]calcKey_t;
const softmenu = @extern([*c]const softmenu_t, .{ .name = "softmenu" });
extern var labelList: [*c]labelList_t;
const allReservedVariables = @extern([*c]const reservedVariableHeader_t, .{ .name = "allReservedVariables" });
extern var allNamedVariables: [*c]namedVariableHeader_t;
// indexOfItems is a C ARRAY (const item_t indexOfItems[]); bind its address
// with @extern, not a pointer-typed extern (which would deref the data as an
// address -> SEGV).
const indexOfItems = @extern([*c]const item_t, .{ .name = "indexOfItems" });

const PGM_RUNNING: u8 = 1;

// tam state (assign reads/writes tam.alpha).
const tamState_t = extern struct {
    mode: u16,
    function: i16,
    alpha: bool_t,
    currentOperation: i16,
    dot: bool_t,
    indirect: bool_t,
    digitsSoFar: i16,
    value0: i16,
    value: i16,
    min: i16,
    max: i16,
    key: i16,
    keyAlpha: bool_t,
    keyDot: bool_t,
    keyIndirect: bool_t,
    keyInputFinished: bool_t,
};
extern var tam: tamState_t;

// STD_* byte sequences (fonts.h).
const STD_LEFT_SINGLE_QUOTE = "\xa0\x18";
const STD_RIGHT_SINGLE_QUOTE = "\xa0\x19";
const STD_CURSOR = "\xa4\x27";
const STD_SUP_BOLD_f = "\x9d\xa0";
const STD_SUP_BOLD_g = "\x9d\x4d";

// ---------------------------------------------------------------------------
// Function externs (linkable everywhere)
// ---------------------------------------------------------------------------
extern fn isItemConversion(itemNr: i16) bool_t;
extern fn fullConvSoftMenuItemNameInclHPCONV(item: i16, outString: [*c]u8) void;
extern fn expandAbbreviations(msg1: [*c]u8) void;
extern fn compareString(stra: [*c]const u8, strb: [*c]const u8, comparisonType: i32) i32;
extern fn displayCalcErrorMessage(errorCode: u8, errMessageRegisterLine: i16, errRegisterLine: i16) void;
extern fn moreInfoOnError(m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) void;
extern fn refreshScreen(source: u16) void;
extern fn showSoftmenu(id: i16) void;
extern fn popSoftmenu() void;
extern fn removeUserMenuFromStack(userMenuId: i16) void;
extern fn createHOME() bool_t;
extern fn createPFN() bool_t;
extern fn setConfirmationMode(func: *const fn (u16) callconv(.c) void) void;
extern fn validateName(name: [*c]const u8) bool_t;
extern fn isUniqueMenuName(name: [*c]const u8) bool_t;
extern fn insertAlphaCursor(startAt: u16) void;
extern fn setSystemFlag(sf: c_uint) void;
extern fn clearSystemFlag(sf: c_uint) void;
extern fn getSystemFlag(sf: i32) bool_t;
extern fn tamEnterMode(func: i16) void;
extern fn calcModeAim(unusedButMandatoryParameter: u16) void;
extern fn leaveTamModeIfEnabled() void;
extern fn findNamedLabel(labelName: [*c]const u8) i16;
extern fn getNthString(ptr: [*c]u8, n: i16) [*c]u8;
extern fn stringToUtf8(str: [*c]const u8, utf8: [*c]u8) void;
extern fn allocC47Blocks(sizeInBlocks: usize) ?*anyopaque;
extern fn reallocC47Blocks(pcMemPtr: ?*anyopaque, oldSizeInBlocks: usize, newSizeInBlocks: usize) ?*anyopaque;
extern fn freeC47Blocks(pcMemPtr: ?*anyopaque, sizeInBlocks: usize) void;
extern fn reduceC47Blocks(pcMemPtr: ?*anyopaque, oldSizeInBlocks: usize, newSizeInBlocks: usize) void;
extern fn xcopy(dest: ?*anyopaque, source: ?*const anyopaque, n: u32) ?*anyopaque;

// host-only GUI (no-op macros on firmware).
extern fn calcModeNormalGui() void;

// libc.
extern fn strcpy(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strcat(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strlen(s: [*c]const u8) usize;
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
extern fn memset(s: ?*anyopaque, c: c_int, n: usize) ?*anyopaque;
extern fn sprintf(buf: [*c]u8, fmt: [*:0]const u8, ...) c_int;
extern fn printf(fmt: [*:0]const u8, ...) c_int;
extern fn abort() noreturn;
extern fn fprintf(stream: ?*anyopaque, fmt: [*:0]const u8, ...) c_int;

// stringCopy is `#define stringCopy(d,s) stpcpy(d,s)` (non-MINGW64 builds).
inline fn stringCopy(dest: [*c]u8, source: [*c]const u8) [*c]u8 {
    return stpcpy(dest, source);
}
inline fn stringByteLength(s: [*c]const u8) i32 {
    return @intCast(strlen(s));
}
inline fn moreInfoOnErr2(where: [*:0]const u8, m2: [*:0]const u8) void {
    if (comptime extra_info) {
        if (comptime !dmcp_build) moreInfoOnError(where, m2, null, null);
    }
}
inline fn moreInfoOnErr3(where: [*:0]const u8, m2: [*:0]const u8, m3: ?[*:0]const u8) void {
    if (comptime extra_info) {
        if (comptime !dmcp_build) moreInfoOnError(where, m2, m3, null);
    }
}
inline fn moreInfoOnErr4(where: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) void {
    if (comptime extra_info) {
        if (comptime !dmcp_build) moreInfoOnError(where, m2, m3, m4);
    }
}


// ===========================================================================
// Keyboard layout tables (TO_QSPI const calcKey_t[37]).
// C47 / DM42 / R47* are unconditional; E47/V47/N47/D47 are host-only (#if PC_BUILD).
// ===========================================================================
pub export const kbd_std_C47 linksection(code_section) = [37]calcKey_t{
    .{ .keyId=21, .primary=433, .fShifted=1871, .gShifted=1422, .keyLblAim=0, .primaryAim=550, .fShiftedAim=576, .gShiftedAim=620, .primaryTam=531 },
    .{ .keyId=22, .primary=73, .fShifted=60, .gShifted=1872, .keyLblAim=809, .primaryAim=551, .fShiftedAim=577, .gShiftedAim=832, .primaryTam=532 },
    .{ .keyId=23, .primary=61, .fShifted=58, .gShifted=1909, .keyLblAim=1000, .primaryAim=552, .fShiftedAim=578, .gShiftedAim=1000, .primaryTam=533 },
    .{ .keyId=24, .primary=71, .fShifted=67, .gShifted=1741, .keyLblAim=0, .primaryAim=553, .fShiftedAim=579, .gShiftedAim=2069, .primaryTam=534 },
    .{ .keyId=25, .primary=69, .fShifted=65, .gShifted=1, .keyLblAim=0, .primaryAim=554, .fShiftedAim=580, .gShiftedAim=2070, .primaryTam=2342 },
    .{ .keyId=26, .primary=3, .fShifted=1740, .gShifted=2, .keyLblAim=0, .primaryAim=555, .fShiftedAim=581, .gShiftedAim=628, .primaryTam=628 },
    .{ .keyId=31, .primary=44, .fShifted=105, .gShifted=1706, .keyLblAim=0, .primaryAim=556, .fShiftedAim=582, .gShiftedAim=998, .primaryTam=2344 },
    .{ .keyId=32, .primary=51, .fShifted=1695, .gShifted=1666, .keyLblAim=0, .primaryAim=557, .fShiftedAim=583, .gShiftedAim=605, .primaryTam=2345 },
    .{ .keyId=33, .primary=40, .fShifted=109, .gShifted=63, .keyLblAim=0, .primaryAim=558, .fShiftedAim=584, .gShiftedAim=644, .primaryTam=536 },
    .{ .keyId=34, .primary=76, .fShifted=83, .gShifted=1830, .keyLblAim=0, .primaryAim=559, .fShiftedAim=585, .gShiftedAim=2071, .primaryTam=537 },
    .{ .keyId=35, .primary=74, .fShifted=81, .gShifted=1850, .keyLblAim=0, .primaryAim=560, .fShiftedAim=586, .gShiftedAim=2072, .primaryTam=538 },
    .{ .keyId=36, .primary=79, .fShifted=85, .gShifted=1849, .keyLblAim=0, .primaryAim=561, .fShiftedAim=587, .gShiftedAim=2073, .primaryTam=535 },
    .{ .keyId=41, .primary=35, .fShifted=1848, .gShifted=-1323, .keyLblAim=35, .primaryAim=35, .fShiftedAim=2420, .gShiftedAim=1172, .primaryTam=35 },
    .{ .keyId=42, .primary=36, .fShifted=1502, .gShifted=-1363, .keyLblAim=981, .primaryAim=562, .fShiftedAim=588, .gShiftedAim=981, .primaryTam=2336 },
    .{ .keyId=43, .primary=97, .fShifted=-1346, .gShifted=-2102, .keyLblAim=847, .primaryAim=563, .fShiftedAim=589, .gShiftedAim=847, .primaryTam=2337 },
    .{ .keyId=44, .primary=990, .fShifted=-1326, .gShifted=-1328, .keyLblAim=0, .primaryAim=564, .fShiftedAim=590, .gShiftedAim=2032, .primaryTam=2346 },
    .{ .keyId=45, .primary=1738, .fShifted=1723, .gShifted=-1321, .keyLblAim=1738, .primaryAim=1738, .fShiftedAim=1874, .gShiftedAim=1874, .primaryTam=1738 },
    .{ .keyId=51, .primary=1733, .fShifted=1734, .gShifted=1560, .keyLblAim=1733, .primaryAim=1733, .fShiftedAim=1878, .gShiftedAim=893, .primaryTam=1733 },
    .{ .keyId=52, .primary=547, .fShifted=-1327, .gShifted=-1921, .keyLblAim=547, .primaryAim=565, .fShiftedAim=591, .gShiftedAim=547, .primaryTam=547 },
    .{ .keyId=53, .primary=548, .fShifted=-1313, .gShifted=-1331, .keyLblAim=548, .primaryAim=566, .fShiftedAim=592, .gShiftedAim=548, .primaryTam=548 },
    .{ .keyId=54, .primary=549, .fShifted=-1344, .gShifted=-1372, .keyLblAim=549, .primaryAim=567, .fShiftedAim=593, .gShiftedAim=549, .primaryTam=549 },
    .{ .keyId=55, .primary=99, .fShifted=-1362, .gShifted=-2107, .keyLblAim=857, .primaryAim=568, .fShiftedAim=594, .gShiftedAim=857, .primaryTam=99 },
    .{ .keyId=61, .primary=1735, .fShifted=1736, .gShifted=1935, .keyLblAim=1735, .primaryAim=1735, .fShiftedAim=1879, .gShiftedAim=895, .primaryTam=1735 },
    .{ .keyId=62, .primary=544, .fShifted=-1923, .gShifted=-1317, .keyLblAim=544, .primaryAim=569, .fShiftedAim=595, .gShiftedAim=544, .primaryTam=544 },
    .{ .keyId=63, .primary=545, .fShifted=-1369, .gShifted=-1320, .keyLblAim=545, .primaryAim=570, .fShiftedAim=596, .gShiftedAim=545, .primaryTam=545 },
    .{ .keyId=64, .primary=546, .fShifted=-1333, .gShifted=-1353, .keyLblAim=546, .primaryAim=571, .fShiftedAim=597, .gShiftedAim=546, .primaryTam=546 },
    .{ .keyId=65, .primary=98, .fShifted=-1354, .gShifted=-1340, .keyLblAim=855, .primaryAim=572, .fShiftedAim=598, .gShiftedAim=855, .primaryTam=98 },
    .{ .keyId=71, .primary=1893, .fShifted=0, .gShifted=0, .keyLblAim=1893, .primaryAim=0, .fShiftedAim=0, .gShiftedAim=0, .primaryTam=1893 },
    .{ .keyId=72, .primary=541, .fShifted=1411, .gShifted=-1927, .keyLblAim=541, .primaryAim=573, .fShiftedAim=599, .gShiftedAim=541, .primaryTam=541 },
    .{ .keyId=73, .primary=542, .fShifted=1729, .gShifted=-1376, .keyLblAim=542, .primaryAim=574, .fShiftedAim=600, .gShiftedAim=542, .primaryTam=542 },
    .{ .keyId=74, .primary=543, .fShifted=-1403, .gShifted=-1342, .keyLblAim=543, .primaryAim=575, .fShiftedAim=601, .gShiftedAim=543, .primaryTam=543 },
    .{ .keyId=75, .primary=96, .fShifted=-1315, .gShifted=-1341, .keyLblAim=819, .primaryAim=833, .fShiftedAim=1155, .gShiftedAim=819, .primaryTam=96 },
    .{ .keyId=81, .primary=1737, .fShifted=1543, .gShifted=1405, .keyLblAim=1737, .primaryAim=1737, .fShiftedAim=1543, .gShiftedAim=1405, .primaryTam=1737 },
    .{ .keyId=82, .primary=540, .fShifted=101, .gShifted=1622, .keyLblAim=540, .primaryAim=822, .fShiftedAim=823, .gShiftedAim=540, .primaryTam=540 },
    .{ .keyId=83, .primary=820, .fShifted=1742, .gShifted=-1339, .keyLblAim=820, .primaryAim=818, .fShiftedAim=809, .gShiftedAim=820, .primaryTam=820 },
    .{ .keyId=84, .primary=1725, .fShifted=1724, .gShifted=-1365, .keyLblAim=0, .primaryAim=827, .fShiftedAim=807, .gShiftedAim=821, .primaryTam=1725 },
    .{ .keyId=85, .primary=95, .fShifted=-1318, .gShifted=-1322, .keyLblAim=817, .primaryAim=806, .fShiftedAim=-2552, .gShiftedAim=817, .primaryTam=95 },
};

const kbd_std_E47_data linksection(code_section) = [37]calcKey_t{
    .{ .keyId=21, .primary=44, .fShifted=1871, .gShifted=1422, .keyLblAim=0, .primaryAim=550, .fShiftedAim=576, .gShiftedAim=0, .primaryTam=531 },
    .{ .keyId=22, .primary=51, .fShifted=63, .gShifted=1872, .keyLblAim=809, .primaryAim=551, .fShiftedAim=577, .gShiftedAim=0, .primaryTam=532 },
    .{ .keyId=23, .primary=73, .fShifted=60, .gShifted=1909, .keyLblAim=0, .primaryAim=552, .fShiftedAim=578, .gShiftedAim=0, .primaryTam=533 },
    .{ .keyId=24, .primary=61, .fShifted=58, .gShifted=1741, .keyLblAim=1000, .primaryAim=553, .fShiftedAim=579, .gShiftedAim=1000, .primaryTam=534 },
    .{ .keyId=25, .primary=71, .fShifted=67, .gShifted=1850, .keyLblAim=0, .primaryAim=554, .fShiftedAim=580, .gShiftedAim=2069, .primaryTam=0 },
    .{ .keyId=26, .primary=69, .fShifted=65, .gShifted=1849, .keyLblAim=0, .primaryAim=555, .fShiftedAim=581, .gShiftedAim=2070, .primaryTam=0 },
    .{ .keyId=31, .primary=1731, .fShifted=0, .gShifted=0, .keyLblAim=1731, .primaryAim=0, .fShiftedAim=0, .gShiftedAim=0, .primaryTam=1731 },
    .{ .keyId=32, .primary=1732, .fShifted=0, .gShifted=0, .keyLblAim=1732, .primaryAim=0, .fShiftedAim=0, .gShiftedAim=0, .primaryTam=1732 },
    .{ .keyId=33, .primary=40, .fShifted=39, .gShifted=109, .keyLblAim=0, .primaryAim=556, .fShiftedAim=582, .gShiftedAim=644, .primaryTam=0 },
    .{ .keyId=34, .primary=76, .fShifted=83, .gShifted=1830, .keyLblAim=0, .primaryAim=557, .fShiftedAim=583, .gShiftedAim=2071, .primaryTam=0 },
    .{ .keyId=35, .primary=74, .fShifted=81, .gShifted=105, .keyLblAim=0, .primaryAim=558, .fShiftedAim=584, .gShiftedAim=2072, .primaryTam=536 },
    .{ .keyId=36, .primary=79, .fShifted=85, .gShifted=1706, .keyLblAim=0, .primaryAim=559, .fShiftedAim=585, .gShiftedAim=2073, .primaryTam=537 },
    .{ .keyId=41, .primary=35, .fShifted=1848, .gShifted=-1323, .keyLblAim=35, .primaryAim=35, .fShiftedAim=2420, .gShiftedAim=1172, .primaryTam=35 },
    .{ .keyId=42, .primary=36, .fShifted=1502, .gShifted=-1363, .keyLblAim=981, .primaryAim=560, .fShiftedAim=586, .gShiftedAim=981, .primaryTam=538 },
    .{ .keyId=43, .primary=97, .fShifted=1873, .gShifted=-2102, .keyLblAim=847, .primaryAim=561, .fShiftedAim=587, .gShiftedAim=847, .primaryTam=535 },
    .{ .keyId=44, .primary=990, .fShifted=-1328, .gShifted=-1326, .keyLblAim=0, .primaryAim=562, .fShiftedAim=588, .gShiftedAim=2032, .primaryTam=0 },
    .{ .keyId=45, .primary=1738, .fShifted=1723, .gShifted=-1321, .keyLblAim=1738, .primaryAim=1738, .fShiftedAim=1874, .gShiftedAim=1874, .primaryTam=1738 },
    .{ .keyId=51, .primary=3, .fShifted=1740, .gShifted=1729, .keyLblAim=0, .primaryAim=0, .fShiftedAim=0, .gShiftedAim=628, .primaryTam=628 },
    .{ .keyId=52, .primary=547, .fShifted=2, .gShifted=-1921, .keyLblAim=547, .primaryAim=563, .fShiftedAim=589, .gShiftedAim=547, .primaryTam=547 },
    .{ .keyId=53, .primary=548, .fShifted=-1327, .gShifted=-1313, .keyLblAim=548, .primaryAim=564, .fShiftedAim=590, .gShiftedAim=548, .primaryTam=548 },
    .{ .keyId=54, .primary=549, .fShifted=-1344, .gShifted=-1372, .keyLblAim=549, .primaryAim=565, .fShiftedAim=591, .gShiftedAim=549, .primaryTam=549 },
    .{ .keyId=55, .primary=99, .fShifted=-1362, .gShifted=-2107, .keyLblAim=857, .primaryAim=566, .fShiftedAim=592, .gShiftedAim=857, .primaryTam=99 },
    .{ .keyId=61, .primary=1733, .fShifted=1734, .gShifted=1560, .keyLblAim=1733, .primaryAim=1733, .fShiftedAim=1878, .gShiftedAim=893, .primaryTam=1733 },
    .{ .keyId=62, .primary=544, .fShifted=-1923, .gShifted=-1317, .keyLblAim=544, .primaryAim=567, .fShiftedAim=593, .gShiftedAim=544, .primaryTam=544 },
    .{ .keyId=63, .primary=545, .fShifted=-1369, .gShifted=-1320, .keyLblAim=545, .primaryAim=568, .fShiftedAim=594, .gShiftedAim=545, .primaryTam=545 },
    .{ .keyId=64, .primary=546, .fShifted=-1333, .gShifted=-1353, .keyLblAim=546, .primaryAim=569, .fShiftedAim=595, .gShiftedAim=546, .primaryTam=546 },
    .{ .keyId=65, .primary=98, .fShifted=-1354, .gShifted=-1340, .keyLblAim=855, .primaryAim=570, .fShiftedAim=596, .gShiftedAim=855, .primaryTam=98 },
    .{ .keyId=71, .primary=1735, .fShifted=1736, .gShifted=1935, .keyLblAim=1735, .primaryAim=1735, .fShiftedAim=1879, .gShiftedAim=895, .primaryTam=1735 },
    .{ .keyId=72, .primary=541, .fShifted=1411, .gShifted=-1927, .keyLblAim=541, .primaryAim=571, .fShiftedAim=597, .gShiftedAim=541, .primaryTam=541 },
    .{ .keyId=73, .primary=542, .fShifted=-2037, .gShifted=-1376, .keyLblAim=542, .primaryAim=572, .fShiftedAim=598, .gShiftedAim=542, .primaryTam=542 },
    .{ .keyId=74, .primary=543, .fShifted=-1403, .gShifted=-1342, .keyLblAim=543, .primaryAim=573, .fShiftedAim=599, .gShiftedAim=543, .primaryTam=543 },
    .{ .keyId=75, .primary=96, .fShifted=-1331, .gShifted=-1341, .keyLblAim=819, .primaryAim=574, .fShiftedAim=600, .gShiftedAim=819, .primaryTam=96 },
    .{ .keyId=81, .primary=1737, .fShifted=1543, .gShifted=1405, .keyLblAim=1737, .primaryAim=1737, .fShiftedAim=1543, .gShiftedAim=1405, .primaryTam=1737 },
    .{ .keyId=82, .primary=540, .fShifted=101, .gShifted=1622, .keyLblAim=540, .primaryAim=575, .fShiftedAim=601, .gShiftedAim=540, .primaryTam=540 },
    .{ .keyId=83, .primary=820, .fShifted=1742, .gShifted=-1339, .keyLblAim=820, .primaryAim=818, .fShiftedAim=820, .gShiftedAim=820, .primaryTam=820 },
    .{ .keyId=84, .primary=1725, .fShifted=1724, .gShifted=-1365, .keyLblAim=0, .primaryAim=827, .fShiftedAim=821, .gShiftedAim=821, .primaryTam=1725 },
    .{ .keyId=85, .primary=95, .fShifted=-1318, .gShifted=-1322, .keyLblAim=817, .primaryAim=806, .fShiftedAim=817, .gShiftedAim=817, .primaryTam=95 },
};

const kbd_std_V47_data linksection(code_section) = [37]calcKey_t{
    .{ .keyId=21, .primary=73, .fShifted=60, .gShifted=1422, .keyLblAim=0, .primaryAim=550, .fShiftedAim=576, .gShiftedAim=832, .primaryTam=531 },
    .{ .keyId=22, .primary=61, .fShifted=58, .gShifted=1872, .keyLblAim=1000, .primaryAim=551, .fShiftedAim=577, .gShiftedAim=1000, .primaryTam=532 },
    .{ .keyId=23, .primary=71, .fShifted=67, .gShifted=1909, .keyLblAim=0, .primaryAim=552, .fShiftedAim=578, .gShiftedAim=2069, .primaryTam=533 },
    .{ .keyId=24, .primary=69, .fShifted=65, .gShifted=1741, .keyLblAim=0, .primaryAim=553, .fShiftedAim=579, .gShiftedAim=2070, .primaryTam=534 },
    .{ .keyId=25, .primary=1731, .fShifted=0, .gShifted=0, .keyLblAim=1731, .primaryAim=0, .fShiftedAim=0, .gShiftedAim=0, .primaryTam=1731 },
    .{ .keyId=26, .primary=1732, .fShifted=0, .gShifted=0, .keyLblAim=1732, .primaryAim=0, .fShiftedAim=0, .gShiftedAim=0, .primaryTam=1732 },
    .{ .keyId=31, .primary=44, .fShifted=105, .gShifted=1706, .keyLblAim=0, .primaryAim=554, .fShiftedAim=580, .gShiftedAim=998, .primaryTam=0 },
    .{ .keyId=32, .primary=51, .fShifted=1695, .gShifted=1666, .keyLblAim=0, .primaryAim=555, .fShiftedAim=581, .gShiftedAim=605, .primaryTam=1834 },
    .{ .keyId=33, .primary=40, .fShifted=109, .gShifted=63, .keyLblAim=0, .primaryAim=556, .fShiftedAim=582, .gShiftedAim=644, .primaryTam=0 },
    .{ .keyId=34, .primary=76, .fShifted=83, .gShifted=1830, .keyLblAim=0, .primaryAim=557, .fShiftedAim=583, .gShiftedAim=2071, .primaryTam=0 },
    .{ .keyId=35, .primary=74, .fShifted=81, .gShifted=1, .keyLblAim=0, .primaryAim=558, .fShiftedAim=584, .gShiftedAim=2072, .primaryTam=536 },
    .{ .keyId=36, .primary=79, .fShifted=85, .gShifted=2, .keyLblAim=0, .primaryAim=559, .fShiftedAim=585, .gShiftedAim=2073, .primaryTam=537 },
    .{ .keyId=41, .primary=35, .fShifted=1848, .gShifted=-1323, .keyLblAim=35, .primaryAim=35, .fShiftedAim=2420, .gShiftedAim=1172, .primaryTam=35 },
    .{ .keyId=42, .primary=36, .fShifted=1502, .gShifted=-1363, .keyLblAim=981, .primaryAim=560, .fShiftedAim=586, .gShiftedAim=981, .primaryTam=538 },
    .{ .keyId=43, .primary=97, .fShifted=-1346, .gShifted=-2102, .keyLblAim=847, .primaryAim=561, .fShiftedAim=587, .gShiftedAim=847, .primaryTam=535 },
    .{ .keyId=44, .primary=990, .fShifted=-1326, .gShifted=-1328, .keyLblAim=0, .primaryAim=562, .fShiftedAim=588, .gShiftedAim=2032, .primaryTam=0 },
    .{ .keyId=45, .primary=1738, .fShifted=1723, .gShifted=-1321, .keyLblAim=1738, .primaryAim=1738, .fShiftedAim=1874, .gShiftedAim=1874, .primaryTam=1738 },
    .{ .keyId=51, .primary=96, .fShifted=-1362, .gShifted=-2107, .keyLblAim=819, .primaryAim=563, .fShiftedAim=589, .gShiftedAim=819, .primaryTam=96 },
    .{ .keyId=52, .primary=547, .fShifted=-1327, .gShifted=-1921, .keyLblAim=547, .primaryAim=564, .fShiftedAim=590, .gShiftedAim=547, .primaryTam=547 },
    .{ .keyId=53, .primary=548, .fShifted=-1313, .gShifted=-1331, .keyLblAim=548, .primaryAim=565, .fShiftedAim=591, .gShiftedAim=548, .primaryTam=548 },
    .{ .keyId=54, .primary=549, .fShifted=-1344, .gShifted=-1372, .keyLblAim=549, .primaryAim=566, .fShiftedAim=592, .gShiftedAim=549, .primaryTam=549 },
    .{ .keyId=55, .primary=3, .fShifted=1740, .gShifted=1729, .keyLblAim=0, .primaryAim=567, .fShiftedAim=593, .gShiftedAim=628, .primaryTam=628 },
    .{ .keyId=61, .primary=95, .fShifted=-1354, .gShifted=-1340, .keyLblAim=817, .primaryAim=568, .fShiftedAim=594, .gShiftedAim=817, .primaryTam=95 },
    .{ .keyId=62, .primary=544, .fShifted=-1923, .gShifted=-1317, .keyLblAim=544, .primaryAim=569, .fShiftedAim=595, .gShiftedAim=544, .primaryTam=544 },
    .{ .keyId=63, .primary=545, .fShifted=-1369, .gShifted=-1320, .keyLblAim=545, .primaryAim=570, .fShiftedAim=596, .gShiftedAim=545, .primaryTam=545 },
    .{ .keyId=64, .primary=546, .fShifted=-1333, .gShifted=-1353, .keyLblAim=546, .primaryAim=571, .fShiftedAim=597, .gShiftedAim=546, .primaryTam=546 },
    .{ .keyId=65, .primary=1733, .fShifted=1734, .gShifted=1560, .keyLblAim=1733, .primaryAim=1733, .fShiftedAim=1878, .gShiftedAim=893, .primaryTam=1733 },
    .{ .keyId=71, .primary=98, .fShifted=-1315, .gShifted=-1341, .keyLblAim=855, .primaryAim=572, .fShiftedAim=598, .gShiftedAim=855, .primaryTam=98 },
    .{ .keyId=72, .primary=541, .fShifted=1411, .gShifted=-1927, .keyLblAim=541, .primaryAim=573, .fShiftedAim=599, .gShiftedAim=541, .primaryTam=541 },
    .{ .keyId=73, .primary=542, .fShifted=1729, .gShifted=-1376, .keyLblAim=542, .primaryAim=574, .fShiftedAim=600, .gShiftedAim=542, .primaryTam=542 },
    .{ .keyId=74, .primary=543, .fShifted=-1403, .gShifted=-1342, .keyLblAim=543, .primaryAim=575, .fShiftedAim=601, .gShiftedAim=543, .primaryTam=543 },
    .{ .keyId=75, .primary=1735, .fShifted=1736, .gShifted=1935, .keyLblAim=1735, .primaryAim=1735, .fShiftedAim=1879, .gShiftedAim=895, .primaryTam=1735 },
    .{ .keyId=81, .primary=99, .fShifted=-1318, .gShifted=-1322, .keyLblAim=857, .primaryAim=806, .fShiftedAim=857, .gShiftedAim=857, .primaryTam=99 },
    .{ .keyId=82, .primary=540, .fShifted=101, .gShifted=1622, .keyLblAim=540, .primaryAim=822, .fShiftedAim=823, .gShiftedAim=540, .primaryTam=540 },
    .{ .keyId=83, .primary=820, .fShifted=1742, .gShifted=-1339, .keyLblAim=820, .primaryAim=818, .fShiftedAim=820, .gShiftedAim=820, .primaryTam=820 },
    .{ .keyId=84, .primary=1725, .fShifted=1724, .gShifted=-1365, .keyLblAim=0, .primaryAim=827, .fShiftedAim=821, .gShiftedAim=821, .primaryTam=1725 },
    .{ .keyId=85, .primary=1737, .fShifted=1543, .gShifted=1405, .keyLblAim=1737, .primaryAim=1737, .fShiftedAim=1543, .gShiftedAim=1405, .primaryTam=1737 },
};

const kbd_std_N47_data linksection(code_section) = [37]calcKey_t{
    .{ .keyId=21, .primary=76, .fShifted=83, .gShifted=1422, .keyLblAim=0, .primaryAim=550, .fShiftedAim=576, .gShiftedAim=2071, .primaryTam=531 },
    .{ .keyId=22, .primary=74, .fShifted=81, .gShifted=1872, .keyLblAim=809, .primaryAim=551, .fShiftedAim=577, .gShiftedAim=2072, .primaryTam=532 },
    .{ .keyId=23, .primary=79, .fShifted=85, .gShifted=1909, .keyLblAim=0, .primaryAim=552, .fShiftedAim=578, .gShiftedAim=2073, .primaryTam=533 },
    .{ .keyId=24, .primary=73, .fShifted=60, .gShifted=1741, .keyLblAim=0, .primaryAim=553, .fShiftedAim=579, .gShiftedAim=832, .primaryTam=534 },
    .{ .keyId=25, .primary=61, .fShifted=58, .gShifted=1871, .keyLblAim=1000, .primaryAim=554, .fShiftedAim=580, .gShiftedAim=1000, .primaryTam=0 },
    .{ .keyId=26, .primary=1733, .fShifted=1734, .gShifted=1560, .keyLblAim=1733, .primaryAim=1733, .fShiftedAim=1878, .gShiftedAim=893, .primaryTam=1733 },
    .{ .keyId=31, .primary=44, .fShifted=109, .gShifted=1695, .keyLblAim=0, .primaryAim=555, .fShiftedAim=581, .gShiftedAim=644, .primaryTam=0 },
    .{ .keyId=32, .primary=51, .fShifted=105, .gShifted=1706, .keyLblAim=0, .primaryAim=556, .fShiftedAim=582, .gShiftedAim=998, .primaryTam=1834 },
    .{ .keyId=33, .primary=40, .fShifted=63, .gShifted=39, .keyLblAim=0, .primaryAim=557, .fShiftedAim=583, .gShiftedAim=0, .primaryTam=0 },
    .{ .keyId=34, .primary=71, .fShifted=67, .gShifted=1850, .keyLblAim=0, .primaryAim=558, .fShiftedAim=584, .gShiftedAim=2070, .primaryTam=536 },
    .{ .keyId=35, .primary=69, .fShifted=65, .gShifted=1849, .keyLblAim=0, .primaryAim=559, .fShiftedAim=585, .gShiftedAim=0, .primaryTam=537 },
    .{ .keyId=36, .primary=1735, .fShifted=1736, .gShifted=1935, .keyLblAim=1735, .primaryAim=1735, .fShiftedAim=1879, .gShiftedAim=895, .primaryTam=1735 },
    .{ .keyId=41, .primary=35, .fShifted=1848, .gShifted=-1323, .keyLblAim=35, .primaryAim=35, .fShiftedAim=2420, .gShiftedAim=1172, .primaryTam=35 },
    .{ .keyId=42, .primary=36, .fShifted=1502, .gShifted=-1363, .keyLblAim=981, .primaryAim=560, .fShiftedAim=586, .gShiftedAim=981, .primaryTam=538 },
    .{ .keyId=43, .primary=97, .fShifted=1873, .gShifted=-2102, .keyLblAim=847, .primaryAim=561, .fShiftedAim=587, .gShiftedAim=847, .primaryTam=535 },
    .{ .keyId=44, .primary=990, .fShifted=-1328, .gShifted=-1326, .keyLblAim=0, .primaryAim=562, .fShiftedAim=588, .gShiftedAim=2032, .primaryTam=1832 },
    .{ .keyId=45, .primary=1738, .fShifted=1723, .gShifted=-1321, .keyLblAim=1738, .primaryAim=1738, .fShiftedAim=1874, .gShiftedAim=1874, .primaryTam=1738 },
    .{ .keyId=51, .primary=3, .fShifted=1740, .gShifted=1729, .keyLblAim=0, .primaryAim=563, .fShiftedAim=589, .gShiftedAim=628, .primaryTam=628 },
    .{ .keyId=52, .primary=547, .fShifted=2, .gShifted=-1921, .keyLblAim=547, .primaryAim=564, .fShiftedAim=590, .gShiftedAim=547, .primaryTam=547 },
    .{ .keyId=53, .primary=548, .fShifted=-1327, .gShifted=-1313, .keyLblAim=548, .primaryAim=565, .fShiftedAim=591, .gShiftedAim=548, .primaryTam=548 },
    .{ .keyId=54, .primary=549, .fShifted=-1344, .gShifted=-1372, .keyLblAim=549, .primaryAim=566, .fShiftedAim=592, .gShiftedAim=549, .primaryTam=549 },
    .{ .keyId=55, .primary=99, .fShifted=-1362, .gShifted=-2107, .keyLblAim=857, .primaryAim=567, .fShiftedAim=593, .gShiftedAim=857, .primaryTam=99 },
    .{ .keyId=61, .primary=1731, .fShifted=0, .gShifted=0, .keyLblAim=1731, .primaryAim=0, .fShiftedAim=0, .gShiftedAim=0, .primaryTam=1731 },
    .{ .keyId=62, .primary=544, .fShifted=-1923, .gShifted=-1317, .keyLblAim=544, .primaryAim=568, .fShiftedAim=594, .gShiftedAim=544, .primaryTam=544 },
    .{ .keyId=63, .primary=545, .fShifted=-1369, .gShifted=-1320, .keyLblAim=545, .primaryAim=569, .fShiftedAim=595, .gShiftedAim=545, .primaryTam=545 },
    .{ .keyId=64, .primary=546, .fShifted=-1333, .gShifted=-1353, .keyLblAim=546, .primaryAim=570, .fShiftedAim=596, .gShiftedAim=546, .primaryTam=546 },
    .{ .keyId=65, .primary=98, .fShifted=-1354, .gShifted=-1340, .keyLblAim=855, .primaryAim=571, .fShiftedAim=597, .gShiftedAim=855, .primaryTam=98 },
    .{ .keyId=71, .primary=1732, .fShifted=0, .gShifted=0, .keyLblAim=1732, .primaryAim=0, .fShiftedAim=0, .gShiftedAim=0, .primaryTam=1732 },
    .{ .keyId=72, .primary=541, .fShifted=1411, .gShifted=-1927, .keyLblAim=541, .primaryAim=572, .fShiftedAim=598, .gShiftedAim=541, .primaryTam=541 },
    .{ .keyId=73, .primary=542, .fShifted=-2037, .gShifted=-1376, .keyLblAim=542, .primaryAim=573, .fShiftedAim=599, .gShiftedAim=542, .primaryTam=542 },
    .{ .keyId=74, .primary=543, .fShifted=-1403, .gShifted=-1342, .keyLblAim=543, .primaryAim=574, .fShiftedAim=600, .gShiftedAim=543, .primaryTam=543 },
    .{ .keyId=75, .primary=96, .fShifted=-1331, .gShifted=-1341, .keyLblAim=819, .primaryAim=0, .fShiftedAim=819, .gShiftedAim=819, .primaryTam=96 },
    .{ .keyId=81, .primary=1737, .fShifted=1543, .gShifted=1405, .keyLblAim=1737, .primaryAim=1737, .fShiftedAim=1543, .gShiftedAim=1405, .primaryTam=1737 },
    .{ .keyId=82, .primary=540, .fShifted=101, .gShifted=1622, .keyLblAim=540, .primaryAim=575, .fShiftedAim=601, .gShiftedAim=540, .primaryTam=540 },
    .{ .keyId=83, .primary=820, .fShifted=1742, .gShifted=-1339, .keyLblAim=820, .primaryAim=818, .fShiftedAim=820, .gShiftedAim=820, .primaryTam=820 },
    .{ .keyId=84, .primary=1725, .fShifted=1724, .gShifted=-1365, .keyLblAim=0, .primaryAim=827, .fShiftedAim=821, .gShiftedAim=821, .primaryTam=1725 },
    .{ .keyId=85, .primary=95, .fShifted=-1318, .gShifted=-1322, .keyLblAim=817, .primaryAim=806, .fShiftedAim=817, .gShiftedAim=817, .primaryTam=95 },
};

const kbd_std_D47_data linksection(code_section) = [37]calcKey_t{
    .{ .keyId=21, .primary=69, .fShifted=65, .gShifted=1422, .keyLblAim=0, .primaryAim=550, .fShiftedAim=576, .gShiftedAim=2070, .primaryTam=531 },
    .{ .keyId=22, .primary=71, .fShifted=67, .gShifted=1872, .keyLblAim=809, .primaryAim=551, .fShiftedAim=577, .gShiftedAim=2069, .primaryTam=532 },
    .{ .keyId=23, .primary=61, .fShifted=58, .gShifted=1909, .keyLblAim=1000, .primaryAim=552, .fShiftedAim=578, .gShiftedAim=1000, .primaryTam=533 },
    .{ .keyId=24, .primary=76, .fShifted=83, .gShifted=1741, .keyLblAim=0, .primaryAim=553, .fShiftedAim=579, .gShiftedAim=2071, .primaryTam=534 },
    .{ .keyId=25, .primary=74, .fShifted=81, .gShifted=1850, .keyLblAim=0, .primaryAim=554, .fShiftedAim=580, .gShiftedAim=2072, .primaryTam=0 },
    .{ .keyId=26, .primary=79, .fShifted=85, .gShifted=1849, .keyLblAim=0, .primaryAim=555, .fShiftedAim=581, .gShiftedAim=2073, .primaryTam=0 },
    .{ .keyId=31, .primary=44, .fShifted=1871, .gShifted=1695, .keyLblAim=0, .primaryAim=556, .fShiftedAim=582, .gShiftedAim=0, .primaryTam=0 },
    .{ .keyId=32, .primary=51, .fShifted=105, .gShifted=1706, .keyLblAim=0, .primaryAim=557, .fShiftedAim=583, .gShiftedAim=998, .primaryTam=1834 },
    .{ .keyId=33, .primary=40, .fShifted=63, .gShifted=39, .keyLblAim=0, .primaryAim=558, .fShiftedAim=584, .gShiftedAim=0, .primaryTam=536 },
    .{ .keyId=34, .primary=73, .fShifted=60, .gShifted=109, .keyLblAim=0, .primaryAim=559, .fShiftedAim=585, .gShiftedAim=832, .primaryTam=537 },
    .{ .keyId=35, .primary=1731, .fShifted=0, .gShifted=0, .keyLblAim=1731, .primaryAim=0, .fShiftedAim=0, .gShiftedAim=0, .primaryTam=1731 },
    .{ .keyId=36, .primary=1732, .fShifted=0, .gShifted=0, .keyLblAim=1732, .primaryAim=0, .fShiftedAim=0, .gShiftedAim=0, .primaryTam=1732 },
    .{ .keyId=41, .primary=35, .fShifted=1848, .gShifted=-1323, .keyLblAim=35, .primaryAim=35, .fShiftedAim=2420, .gShiftedAim=1172, .primaryTam=35 },
    .{ .keyId=42, .primary=36, .fShifted=1502, .gShifted=-1363, .keyLblAim=981, .primaryAim=560, .fShiftedAim=586, .gShiftedAim=981, .primaryTam=538 },
    .{ .keyId=43, .primary=97, .fShifted=1873, .gShifted=-2036, .keyLblAim=847, .primaryAim=561, .fShiftedAim=587, .gShiftedAim=847, .primaryTam=535 },
    .{ .keyId=44, .primary=990, .fShifted=-1328, .gShifted=-1326, .keyLblAim=0, .primaryAim=562, .fShiftedAim=588, .gShiftedAim=2032, .primaryTam=0 },
    .{ .keyId=45, .primary=1738, .fShifted=1723, .gShifted=-1321, .keyLblAim=1738, .primaryAim=1738, .fShiftedAim=1874, .gShiftedAim=1874, .primaryTam=1738 },
    .{ .keyId=51, .primary=3, .fShifted=1740, .gShifted=1729, .keyLblAim=0, .primaryAim=0, .fShiftedAim=0, .gShiftedAim=628, .primaryTam=628 },
    .{ .keyId=52, .primary=547, .fShifted=2, .gShifted=-1921, .keyLblAim=547, .primaryAim=563, .fShiftedAim=589, .gShiftedAim=547, .primaryTam=547 },
    .{ .keyId=53, .primary=548, .fShifted=-1327, .gShifted=-1313, .keyLblAim=548, .primaryAim=564, .fShiftedAim=590, .gShiftedAim=548, .primaryTam=548 },
    .{ .keyId=54, .primary=549, .fShifted=-1344, .gShifted=-1372, .keyLblAim=549, .primaryAim=565, .fShiftedAim=591, .gShiftedAim=549, .primaryTam=549 },
    .{ .keyId=55, .primary=99, .fShifted=-1362, .gShifted=-2107, .keyLblAim=857, .primaryAim=566, .fShiftedAim=592, .gShiftedAim=857, .primaryTam=99 },
    .{ .keyId=61, .primary=1733, .fShifted=1734, .gShifted=1560, .keyLblAim=1733, .primaryAim=1733, .fShiftedAim=1878, .gShiftedAim=893, .primaryTam=1733 },
    .{ .keyId=62, .primary=544, .fShifted=-1923, .gShifted=-1317, .keyLblAim=544, .primaryAim=567, .fShiftedAim=593, .gShiftedAim=544, .primaryTam=544 },
    .{ .keyId=63, .primary=545, .fShifted=-1369, .gShifted=-1320, .keyLblAim=545, .primaryAim=568, .fShiftedAim=594, .gShiftedAim=545, .primaryTam=545 },
    .{ .keyId=64, .primary=546, .fShifted=-1333, .gShifted=-1353, .keyLblAim=546, .primaryAim=569, .fShiftedAim=595, .gShiftedAim=546, .primaryTam=546 },
    .{ .keyId=65, .primary=98, .fShifted=-1354, .gShifted=-1340, .keyLblAim=855, .primaryAim=570, .fShiftedAim=596, .gShiftedAim=855, .primaryTam=98 },
    .{ .keyId=71, .primary=1735, .fShifted=1736, .gShifted=1935, .keyLblAim=1735, .primaryAim=1735, .fShiftedAim=1879, .gShiftedAim=895, .primaryTam=1735 },
    .{ .keyId=72, .primary=541, .fShifted=1411, .gShifted=-1927, .keyLblAim=541, .primaryAim=571, .fShiftedAim=597, .gShiftedAim=541, .primaryTam=541 },
    .{ .keyId=73, .primary=542, .fShifted=-2037, .gShifted=-1376, .keyLblAim=542, .primaryAim=572, .fShiftedAim=598, .gShiftedAim=542, .primaryTam=542 },
    .{ .keyId=74, .primary=543, .fShifted=-1403, .gShifted=-1342, .keyLblAim=543, .primaryAim=573, .fShiftedAim=599, .gShiftedAim=543, .primaryTam=543 },
    .{ .keyId=75, .primary=96, .fShifted=-1331, .gShifted=-1341, .keyLblAim=819, .primaryAim=574, .fShiftedAim=600, .gShiftedAim=819, .primaryTam=96 },
    .{ .keyId=81, .primary=1737, .fShifted=1543, .gShifted=1405, .keyLblAim=1737, .primaryAim=1737, .fShiftedAim=1543, .gShiftedAim=1405, .primaryTam=1737 },
    .{ .keyId=82, .primary=540, .fShifted=101, .gShifted=1622, .keyLblAim=540, .primaryAim=575, .fShiftedAim=601, .gShiftedAim=540, .primaryTam=540 },
    .{ .keyId=83, .primary=820, .fShifted=1742, .gShifted=-1339, .keyLblAim=820, .primaryAim=818, .fShiftedAim=820, .gShiftedAim=820, .primaryTam=820 },
    .{ .keyId=84, .primary=1725, .fShifted=1724, .gShifted=-1365, .keyLblAim=0, .primaryAim=827, .fShiftedAim=821, .gShiftedAim=821, .primaryTam=1725 },
    .{ .keyId=85, .primary=95, .fShifted=-1318, .gShifted=-1322, .keyLblAim=817, .primaryAim=806, .fShiftedAim=817, .gShiftedAim=817, .primaryTam=95 },
};

pub export const kbd_std_DM42 linksection(code_section) = [37]calcKey_t{
    .{ .keyId=21, .primary=433, .fShifted=434, .gShifted=1422, .keyLblAim=0, .primaryAim=550, .fShiftedAim=576, .gShiftedAim=620, .primaryTam=531 },
    .{ .keyId=22, .primary=73, .fShifted=60, .gShifted=1872, .keyLblAim=809, .primaryAim=551, .fShiftedAim=577, .gShiftedAim=832, .primaryTam=532 },
    .{ .keyId=23, .primary=61, .fShifted=58, .gShifted=1909, .keyLblAim=1000, .primaryAim=552, .fShiftedAim=578, .gShiftedAim=1000, .primaryTam=533 },
    .{ .keyId=24, .primary=71, .fShifted=67, .gShifted=1741, .keyLblAim=0, .primaryAim=553, .fShiftedAim=579, .gShiftedAim=2069, .primaryTam=534 },
    .{ .keyId=25, .primary=69, .fShifted=65, .gShifted=1, .keyLblAim=0, .primaryAim=554, .fShiftedAim=580, .gShiftedAim=2070, .primaryTam=0 },
    .{ .keyId=26, .primary=3, .fShifted=2, .gShifted=4, .keyLblAim=0, .primaryAim=555, .fShiftedAim=581, .gShiftedAim=628, .primaryTam=628 },
    .{ .keyId=31, .primary=44, .fShifted=1848, .gShifted=1706, .keyLblAim=0, .primaryAim=556, .fShiftedAim=582, .gShiftedAim=998, .primaryTam=0 },
    .{ .keyId=32, .primary=51, .fShifted=1695, .gShifted=1666, .keyLblAim=0, .primaryAim=557, .fShiftedAim=583, .gShiftedAim=605, .primaryTam=1834 },
    .{ .keyId=33, .primary=40, .fShifted=109, .gShifted=63, .keyLblAim=0, .primaryAim=558, .fShiftedAim=584, .gShiftedAim=644, .primaryTam=536 },
    .{ .keyId=34, .primary=76, .fShifted=83, .gShifted=1830, .keyLblAim=0, .primaryAim=559, .fShiftedAim=585, .gShiftedAim=2071, .primaryTam=537 },
    .{ .keyId=35, .primary=74, .fShifted=81, .gShifted=1850, .keyLblAim=0, .primaryAim=560, .fShiftedAim=586, .gShiftedAim=2072, .primaryTam=538 },
    .{ .keyId=36, .primary=79, .fShifted=85, .gShifted=1849, .keyLblAim=0, .primaryAim=561, .fShiftedAim=587, .gShiftedAim=2073, .primaryTam=535 },
    .{ .keyId=41, .primary=35, .fShifted=1740, .gShifted=-1323, .keyLblAim=35, .primaryAim=35, .fShiftedAim=2420, .gShiftedAim=1172, .primaryTam=35 },
    .{ .keyId=42, .primary=36, .fShifted=1502, .gShifted=-1363, .keyLblAim=981, .primaryAim=562, .fShiftedAim=588, .gShiftedAim=981, .primaryTam=0 },
    .{ .keyId=43, .primary=97, .fShifted=-1346, .gShifted=-2102, .keyLblAim=847, .primaryAim=563, .fShiftedAim=589, .gShiftedAim=847, .primaryTam=0 },
    .{ .keyId=44, .primary=990, .fShifted=-1326, .gShifted=-1328, .keyLblAim=0, .primaryAim=564, .fShiftedAim=590, .gShiftedAim=2032, .primaryTam=1832 },
    .{ .keyId=45, .primary=1738, .fShifted=-1321, .gShifted=1723, .keyLblAim=1738, .primaryAim=1738, .fShiftedAim=1874, .gShiftedAim=1874, .primaryTam=1738 },
    .{ .keyId=51, .primary=1733, .fShifted=1734, .gShifted=1560, .keyLblAim=1733, .primaryAim=1733, .fShiftedAim=1878, .gShiftedAim=893, .primaryTam=1733 },
    .{ .keyId=52, .primary=547, .fShifted=-1327, .gShifted=-1921, .keyLblAim=547, .primaryAim=565, .fShiftedAim=591, .gShiftedAim=547, .primaryTam=547 },
    .{ .keyId=53, .primary=548, .fShifted=-1313, .gShifted=-1331, .keyLblAim=548, .primaryAim=566, .fShiftedAim=592, .gShiftedAim=548, .primaryTam=548 },
    .{ .keyId=54, .primary=549, .fShifted=-1344, .gShifted=-1372, .keyLblAim=549, .primaryAim=567, .fShiftedAim=593, .gShiftedAim=549, .primaryTam=549 },
    .{ .keyId=55, .primary=99, .fShifted=-1362, .gShifted=-2107, .keyLblAim=857, .primaryAim=568, .fShiftedAim=594, .gShiftedAim=857, .primaryTam=99 },
    .{ .keyId=61, .primary=1735, .fShifted=1736, .gShifted=1935, .keyLblAim=1735, .primaryAim=1735, .fShiftedAim=1879, .gShiftedAim=895, .primaryTam=1735 },
    .{ .keyId=62, .primary=544, .fShifted=-1923, .gShifted=-1317, .keyLblAim=544, .primaryAim=569, .fShiftedAim=595, .gShiftedAim=544, .primaryTam=544 },
    .{ .keyId=63, .primary=545, .fShifted=-1369, .gShifted=-1320, .keyLblAim=545, .primaryAim=570, .fShiftedAim=596, .gShiftedAim=545, .primaryTam=545 },
    .{ .keyId=64, .primary=546, .fShifted=-1333, .gShifted=-1353, .keyLblAim=546, .primaryAim=571, .fShiftedAim=597, .gShiftedAim=546, .primaryTam=546 },
    .{ .keyId=65, .primary=98, .fShifted=-1354, .gShifted=-1340, .keyLblAim=855, .primaryAim=572, .fShiftedAim=598, .gShiftedAim=855, .primaryTam=98 },
    .{ .keyId=71, .primary=1893, .fShifted=0, .gShifted=0, .keyLblAim=1893, .primaryAim=0, .fShiftedAim=0, .gShiftedAim=0, .primaryTam=1893 },
    .{ .keyId=72, .primary=541, .fShifted=1411, .gShifted=-1927, .keyLblAim=541, .primaryAim=573, .fShiftedAim=599, .gShiftedAim=541, .primaryTam=541 },
    .{ .keyId=73, .primary=542, .fShifted=1729, .gShifted=-1376, .keyLblAim=542, .primaryAim=574, .fShiftedAim=600, .gShiftedAim=542, .primaryTam=542 },
    .{ .keyId=74, .primary=543, .fShifted=-1403, .gShifted=-1342, .keyLblAim=543, .primaryAim=575, .fShiftedAim=601, .gShiftedAim=543, .primaryTam=543 },
    .{ .keyId=75, .primary=96, .fShifted=-1315, .gShifted=-1341, .keyLblAim=819, .primaryAim=833, .fShiftedAim=819, .gShiftedAim=819, .primaryTam=96 },
    .{ .keyId=81, .primary=1737, .fShifted=1543, .gShifted=1405, .keyLblAim=1737, .primaryAim=1737, .fShiftedAim=1543, .gShiftedAim=1405, .primaryTam=1737 },
    .{ .keyId=82, .primary=540, .fShifted=-1448, .gShifted=1622, .keyLblAim=540, .primaryAim=822, .fShiftedAim=823, .gShiftedAim=540, .primaryTam=540 },
    .{ .keyId=83, .primary=820, .fShifted=1742, .gShifted=-1339, .keyLblAim=820, .primaryAim=818, .fShiftedAim=809, .gShiftedAim=820, .primaryTam=820 },
    .{ .keyId=84, .primary=1725, .fShifted=1724, .gShifted=-1365, .keyLblAim=0, .primaryAim=827, .fShiftedAim=807, .gShiftedAim=821, .primaryTam=1725 },
    .{ .keyId=85, .primary=95, .fShifted=-1318, .gShifted=-1322, .keyLblAim=817, .primaryAim=806, .fShiftedAim=-2552, .gShiftedAim=817, .primaryTam=95 },
};

pub export const kbd_std_R47f_g linksection(code_section) = [37]calcKey_t{
    .{ .keyId=21, .primary=58, .fShifted=1830, .gShifted=1850, .keyLblAim=0, .primaryAim=550, .fShiftedAim=576, .gShiftedAim=1159, .primaryTam=531 },
    .{ .keyId=22, .primary=61, .fShifted=1795, .gShifted=1849, .keyLblAim=1000, .primaryAim=551, .fShiftedAim=577, .gShiftedAim=1000, .primaryTam=532 },
    .{ .keyId=23, .primary=73, .fShifted=108, .gShifted=1909, .keyLblAim=0, .primaryAim=552, .fShiftedAim=578, .gShiftedAim=807, .primaryTam=533 },
    .{ .keyId=24, .primary=60, .fShifted=63, .gShifted=1741, .keyLblAim=0, .primaryAim=553, .fShiftedAim=579, .gShiftedAim=832, .primaryTam=534 },
    .{ .keyId=25, .primary=71, .fShifted=67, .gShifted=1871, .keyLblAim=0, .primaryAim=554, .fShiftedAim=580, .gShiftedAim=1155, .primaryTam=2342 },
    .{ .keyId=26, .primary=69, .fShifted=65, .gShifted=1872, .keyLblAim=809, .primaryAim=555, .fShiftedAim=581, .gShiftedAim=809, .primaryTam=2343 },
    .{ .keyId=31, .primary=44, .fShifted=105, .gShifted=1706, .keyLblAim=0, .primaryAim=556, .fShiftedAim=582, .gShiftedAim=998, .primaryTam=2344 },
    .{ .keyId=32, .primary=51, .fShifted=1695, .gShifted=1666, .keyLblAim=0, .primaryAim=557, .fShiftedAim=583, .gShiftedAim=605, .primaryTam=2345 },
    .{ .keyId=33, .primary=40, .fShifted=109, .gShifted=39, .keyLblAim=0, .primaryAim=558, .fShiftedAim=584, .gShiftedAim=644, .primaryTam=536 },
    .{ .keyId=34, .primary=1873, .fShifted=1729, .gShifted=1411, .keyLblAim=0, .primaryAim=559, .fShiftedAim=585, .gShiftedAim=1160, .primaryTam=537 },
    .{ .keyId=35, .primary=1731, .fShifted=0, .gShifted=0, .keyLblAim=1731, .primaryAim=0, .fShiftedAim=0, .gShiftedAim=0, .primaryTam=1731 },
    .{ .keyId=36, .primary=1732, .fShifted=0, .gShifted=0, .keyLblAim=1732, .primaryAim=0, .fShiftedAim=0, .gShiftedAim=0, .primaryTam=1732 },
    .{ .keyId=41, .primary=35, .fShifted=1848, .gShifted=-1323, .keyLblAim=35, .primaryAim=35, .fShiftedAim=2420, .gShiftedAim=1172, .primaryTam=35 },
    .{ .keyId=42, .primary=36, .fShifted=1502, .gShifted=-1363, .keyLblAim=981, .primaryAim=560, .fShiftedAim=586, .gShiftedAim=981, .primaryTam=538 },
    .{ .keyId=43, .primary=97, .fShifted=-1326, .gShifted=-2036, .keyLblAim=847, .primaryAim=561, .fShiftedAim=587, .gShiftedAim=847, .primaryTam=535 },
    .{ .keyId=44, .primary=990, .fShifted=-2229, .gShifted=-1328, .keyLblAim=0, .primaryAim=562, .fShiftedAim=588, .gShiftedAim=2032, .primaryTam=2336 },
    .{ .keyId=45, .primary=1738, .fShifted=1723, .gShifted=-1321, .keyLblAim=1738, .primaryAim=1738, .fShiftedAim=1874, .gShiftedAim=1874, .primaryTam=1738 },
    .{ .keyId=51, .primary=3, .fShifted=1740, .gShifted=2, .keyLblAim=0, .primaryAim=833, .fShiftedAim=628, .gShiftedAim=653, .primaryTam=628 },
    .{ .keyId=52, .primary=547, .fShifted=76, .gShifted=83, .keyLblAim=547, .primaryAim=563, .fShiftedAim=589, .gShiftedAim=547, .primaryTam=547 },
    .{ .keyId=53, .primary=548, .fShifted=74, .gShifted=81, .keyLblAim=548, .primaryAim=564, .fShiftedAim=590, .gShiftedAim=548, .primaryTam=548 },
    .{ .keyId=54, .primary=549, .fShifted=79, .gShifted=85, .keyLblAim=549, .primaryAim=565, .fShiftedAim=591, .gShiftedAim=549, .primaryTam=549 },
    .{ .keyId=55, .primary=99, .fShifted=-1362, .gShifted=-2107, .keyLblAim=857, .primaryAim=566, .fShiftedAim=592, .gShiftedAim=857, .primaryTam=99 },
    .{ .keyId=61, .primary=1733, .fShifted=1734, .gShifted=1560, .keyLblAim=1733, .primaryAim=1733, .fShiftedAim=1878, .gShiftedAim=893, .primaryTam=1733 },
    .{ .keyId=62, .primary=544, .fShifted=-1923, .gShifted=-1317, .keyLblAim=544, .primaryAim=567, .fShiftedAim=593, .gShiftedAim=544, .primaryTam=544 },
    .{ .keyId=63, .primary=545, .fShifted=-1340, .gShifted=-1353, .keyLblAim=545, .primaryAim=568, .fShiftedAim=594, .gShiftedAim=545, .primaryTam=545 },
    .{ .keyId=64, .primary=546, .fShifted=-1344, .gShifted=-1372, .keyLblAim=546, .primaryAim=569, .fShiftedAim=595, .gShiftedAim=546, .primaryTam=546 },
    .{ .keyId=65, .primary=98, .fShifted=-1327, .gShifted=-1313, .keyLblAim=855, .primaryAim=570, .fShiftedAim=596, .gShiftedAim=855, .primaryTam=98 },
    .{ .keyId=71, .primary=1735, .fShifted=1736, .gShifted=1935, .keyLblAim=1735, .primaryAim=1735, .fShiftedAim=1879, .gShiftedAim=895, .primaryTam=1735 },
    .{ .keyId=72, .primary=541, .fShifted=-2037, .gShifted=-1927, .keyLblAim=541, .primaryAim=571, .fShiftedAim=597, .gShiftedAim=541, .primaryTam=541 },
    .{ .keyId=73, .primary=542, .fShifted=-1369, .gShifted=-1320, .keyLblAim=542, .primaryAim=572, .fShiftedAim=598, .gShiftedAim=542, .primaryTam=542 },
    .{ .keyId=74, .primary=543, .fShifted=-1333, .gShifted=-1376, .keyLblAim=543, .primaryAim=573, .fShiftedAim=599, .gShiftedAim=543, .primaryTam=543 },
    .{ .keyId=75, .primary=96, .fShifted=-1354, .gShifted=-1331, .keyLblAim=819, .primaryAim=574, .fShiftedAim=600, .gShiftedAim=819, .primaryTam=96 },
    .{ .keyId=81, .primary=1737, .fShifted=1543, .gShifted=-1339, .keyLblAim=1737, .primaryAim=1737, .fShiftedAim=1543, .gShiftedAim=1405, .primaryTam=1737 },
    .{ .keyId=82, .primary=540, .fShifted=101, .gShifted=-1341, .keyLblAim=540, .primaryAim=575, .fShiftedAim=601, .gShiftedAim=540, .primaryTam=540 },
    .{ .keyId=83, .primary=820, .fShifted=1742, .gShifted=1422, .keyLblAim=820, .primaryAim=818, .fShiftedAim=823, .gShiftedAim=820, .primaryTam=820 },
    .{ .keyId=84, .primary=1725, .fShifted=1724, .gShifted=-1403, .keyLblAim=0, .primaryAim=827, .fShiftedAim=822, .gShiftedAim=821, .primaryTam=1725 },
    .{ .keyId=85, .primary=95, .fShifted=-1318, .gShifted=-1322, .keyLblAim=817, .primaryAim=806, .fShiftedAim=-2552, .gShiftedAim=817, .primaryTam=95 },
};

pub export const kbd_std_R47bk_fg linksection(code_section) = [37]calcKey_t{
    .{ .keyId=21, .primary=58, .fShifted=1830, .gShifted=1850, .keyLblAim=0, .primaryAim=550, .fShiftedAim=576, .gShiftedAim=1159, .primaryTam=531 },
    .{ .keyId=22, .primary=61, .fShifted=1795, .gShifted=1849, .keyLblAim=1000, .primaryAim=551, .fShiftedAim=577, .gShiftedAim=1000, .primaryTam=532 },
    .{ .keyId=23, .primary=73, .fShifted=108, .gShifted=1909, .keyLblAim=0, .primaryAim=552, .fShiftedAim=578, .gShiftedAim=807, .primaryTam=533 },
    .{ .keyId=24, .primary=60, .fShifted=63, .gShifted=1741, .keyLblAim=0, .primaryAim=553, .fShiftedAim=579, .gShiftedAim=832, .primaryTam=534 },
    .{ .keyId=25, .primary=71, .fShifted=67, .gShifted=1871, .keyLblAim=0, .primaryAim=554, .fShiftedAim=580, .gShiftedAim=1155, .primaryTam=2342 },
    .{ .keyId=26, .primary=69, .fShifted=65, .gShifted=1872, .keyLblAim=809, .primaryAim=555, .fShiftedAim=581, .gShiftedAim=809, .primaryTam=2343 },
    .{ .keyId=31, .primary=44, .fShifted=105, .gShifted=1706, .keyLblAim=0, .primaryAim=556, .fShiftedAim=582, .gShiftedAim=998, .primaryTam=2344 },
    .{ .keyId=32, .primary=51, .fShifted=1695, .gShifted=1666, .keyLblAim=0, .primaryAim=557, .fShiftedAim=583, .gShiftedAim=605, .primaryTam=2345 },
    .{ .keyId=33, .primary=40, .fShifted=109, .gShifted=39, .keyLblAim=0, .primaryAim=558, .fShiftedAim=584, .gShiftedAim=644, .primaryTam=536 },
    .{ .keyId=34, .primary=1873, .fShifted=1729, .gShifted=1411, .keyLblAim=0, .primaryAim=559, .fShiftedAim=585, .gShiftedAim=1160, .primaryTam=537 },
    .{ .keyId=35, .primary=0, .fShifted=0, .gShifted=0, .keyLblAim=0, .primaryAim=0, .fShiftedAim=0, .gShiftedAim=0, .primaryTam=0 },
    .{ .keyId=36, .primary=1893, .fShifted=0, .gShifted=0, .keyLblAim=1893, .primaryAim=0, .fShiftedAim=0, .gShiftedAim=0, .primaryTam=1893 },
    .{ .keyId=41, .primary=35, .fShifted=1848, .gShifted=-1323, .keyLblAim=35, .primaryAim=35, .fShiftedAim=2420, .gShiftedAim=1172, .primaryTam=35 },
    .{ .keyId=42, .primary=36, .fShifted=1502, .gShifted=-1363, .keyLblAim=981, .primaryAim=560, .fShiftedAim=586, .gShiftedAim=981, .primaryTam=538 },
    .{ .keyId=43, .primary=97, .fShifted=-1326, .gShifted=-2036, .keyLblAim=847, .primaryAim=561, .fShiftedAim=587, .gShiftedAim=847, .primaryTam=535 },
    .{ .keyId=44, .primary=990, .fShifted=-2229, .gShifted=-1328, .keyLblAim=0, .primaryAim=562, .fShiftedAim=588, .gShiftedAim=2032, .primaryTam=2336 },
    .{ .keyId=45, .primary=1738, .fShifted=1723, .gShifted=-1321, .keyLblAim=1738, .primaryAim=1738, .fShiftedAim=1874, .gShiftedAim=1874, .primaryTam=1738 },
    .{ .keyId=51, .primary=3, .fShifted=1740, .gShifted=2, .keyLblAim=0, .primaryAim=833, .fShiftedAim=628, .gShiftedAim=653, .primaryTam=628 },
    .{ .keyId=52, .primary=547, .fShifted=76, .gShifted=83, .keyLblAim=547, .primaryAim=563, .fShiftedAim=589, .gShiftedAim=547, .primaryTam=547 },
    .{ .keyId=53, .primary=548, .fShifted=74, .gShifted=81, .keyLblAim=548, .primaryAim=564, .fShiftedAim=590, .gShiftedAim=548, .primaryTam=548 },
    .{ .keyId=54, .primary=549, .fShifted=79, .gShifted=85, .keyLblAim=549, .primaryAim=565, .fShiftedAim=591, .gShiftedAim=549, .primaryTam=549 },
    .{ .keyId=55, .primary=99, .fShifted=-1362, .gShifted=-2107, .keyLblAim=857, .primaryAim=566, .fShiftedAim=592, .gShiftedAim=857, .primaryTam=99 },
    .{ .keyId=61, .primary=1733, .fShifted=1734, .gShifted=1560, .keyLblAim=1733, .primaryAim=1733, .fShiftedAim=1878, .gShiftedAim=893, .primaryTam=1733 },
    .{ .keyId=62, .primary=544, .fShifted=-1923, .gShifted=-1317, .keyLblAim=544, .primaryAim=567, .fShiftedAim=593, .gShiftedAim=544, .primaryTam=544 },
    .{ .keyId=63, .primary=545, .fShifted=-1340, .gShifted=-1353, .keyLblAim=545, .primaryAim=568, .fShiftedAim=594, .gShiftedAim=545, .primaryTam=545 },
    .{ .keyId=64, .primary=546, .fShifted=-1344, .gShifted=-1372, .keyLblAim=546, .primaryAim=569, .fShiftedAim=595, .gShiftedAim=546, .primaryTam=546 },
    .{ .keyId=65, .primary=98, .fShifted=-1327, .gShifted=-1313, .keyLblAim=855, .primaryAim=570, .fShiftedAim=596, .gShiftedAim=855, .primaryTam=98 },
    .{ .keyId=71, .primary=1735, .fShifted=1736, .gShifted=1935, .keyLblAim=1735, .primaryAim=1735, .fShiftedAim=1879, .gShiftedAim=895, .primaryTam=1735 },
    .{ .keyId=72, .primary=541, .fShifted=-2037, .gShifted=-1927, .keyLblAim=541, .primaryAim=571, .fShiftedAim=597, .gShiftedAim=541, .primaryTam=541 },
    .{ .keyId=73, .primary=542, .fShifted=-1369, .gShifted=-1320, .keyLblAim=542, .primaryAim=572, .fShiftedAim=598, .gShiftedAim=542, .primaryTam=542 },
    .{ .keyId=74, .primary=543, .fShifted=-1333, .gShifted=-1376, .keyLblAim=543, .primaryAim=573, .fShiftedAim=599, .gShiftedAim=543, .primaryTam=543 },
    .{ .keyId=75, .primary=96, .fShifted=-1354, .gShifted=-1331, .keyLblAim=819, .primaryAim=574, .fShiftedAim=600, .gShiftedAim=819, .primaryTam=96 },
    .{ .keyId=81, .primary=1737, .fShifted=1543, .gShifted=-1339, .keyLblAim=1737, .primaryAim=1737, .fShiftedAim=1543, .gShiftedAim=1405, .primaryTam=1737 },
    .{ .keyId=82, .primary=540, .fShifted=101, .gShifted=-1341, .keyLblAim=540, .primaryAim=575, .fShiftedAim=601, .gShiftedAim=540, .primaryTam=540 },
    .{ .keyId=83, .primary=820, .fShifted=1742, .gShifted=1422, .keyLblAim=820, .primaryAim=818, .fShiftedAim=823, .gShiftedAim=820, .primaryTam=820 },
    .{ .keyId=84, .primary=1725, .fShifted=1724, .gShifted=-1403, .keyLblAim=0, .primaryAim=827, .fShiftedAim=822, .gShiftedAim=821, .primaryTam=1725 },
    .{ .keyId=85, .primary=95, .fShifted=-1318, .gShifted=-1322, .keyLblAim=817, .primaryAim=806, .fShiftedAim=-2552, .gShiftedAim=817, .primaryTam=95 },
};

pub export const kbd_std_R47fg_bk linksection(code_section) = [37]calcKey_t{
    .{ .keyId=21, .primary=58, .fShifted=1830, .gShifted=1850, .keyLblAim=0, .primaryAim=550, .fShiftedAim=576, .gShiftedAim=1159, .primaryTam=531 },
    .{ .keyId=22, .primary=61, .fShifted=1795, .gShifted=1849, .keyLblAim=1000, .primaryAim=551, .fShiftedAim=577, .gShiftedAim=1000, .primaryTam=532 },
    .{ .keyId=23, .primary=73, .fShifted=108, .gShifted=1909, .keyLblAim=0, .primaryAim=552, .fShiftedAim=578, .gShiftedAim=807, .primaryTam=533 },
    .{ .keyId=24, .primary=60, .fShifted=63, .gShifted=1741, .keyLblAim=0, .primaryAim=553, .fShiftedAim=579, .gShiftedAim=832, .primaryTam=534 },
    .{ .keyId=25, .primary=71, .fShifted=67, .gShifted=1871, .keyLblAim=0, .primaryAim=554, .fShiftedAim=580, .gShiftedAim=1155, .primaryTam=2342 },
    .{ .keyId=26, .primary=69, .fShifted=65, .gShifted=1872, .keyLblAim=809, .primaryAim=555, .fShiftedAim=581, .gShiftedAim=809, .primaryTam=2343 },
    .{ .keyId=31, .primary=44, .fShifted=105, .gShifted=1706, .keyLblAim=0, .primaryAim=556, .fShiftedAim=582, .gShiftedAim=998, .primaryTam=2344 },
    .{ .keyId=32, .primary=51, .fShifted=1695, .gShifted=1666, .keyLblAim=0, .primaryAim=557, .fShiftedAim=583, .gShiftedAim=605, .primaryTam=2345 },
    .{ .keyId=33, .primary=40, .fShifted=109, .gShifted=39, .keyLblAim=0, .primaryAim=558, .fShiftedAim=584, .gShiftedAim=644, .primaryTam=536 },
    .{ .keyId=34, .primary=1873, .fShifted=1729, .gShifted=1411, .keyLblAim=0, .primaryAim=559, .fShiftedAim=585, .gShiftedAim=1160, .primaryTam=537 },
    .{ .keyId=35, .primary=1893, .fShifted=0, .gShifted=0, .keyLblAim=1893, .primaryAim=0, .fShiftedAim=0, .gShiftedAim=0, .primaryTam=1893 },
    .{ .keyId=36, .primary=0, .fShifted=0, .gShifted=0, .keyLblAim=0, .primaryAim=0, .fShiftedAim=0, .gShiftedAim=0, .primaryTam=0 },
    .{ .keyId=41, .primary=35, .fShifted=1848, .gShifted=-1323, .keyLblAim=35, .primaryAim=35, .fShiftedAim=2420, .gShiftedAim=1172, .primaryTam=35 },
    .{ .keyId=42, .primary=36, .fShifted=1502, .gShifted=-1363, .keyLblAim=981, .primaryAim=560, .fShiftedAim=586, .gShiftedAim=981, .primaryTam=538 },
    .{ .keyId=43, .primary=97, .fShifted=-1326, .gShifted=-2036, .keyLblAim=847, .primaryAim=561, .fShiftedAim=587, .gShiftedAim=847, .primaryTam=535 },
    .{ .keyId=44, .primary=990, .fShifted=-2229, .gShifted=-1328, .keyLblAim=0, .primaryAim=562, .fShiftedAim=588, .gShiftedAim=2032, .primaryTam=2336 },
    .{ .keyId=45, .primary=1738, .fShifted=1723, .gShifted=-1321, .keyLblAim=1738, .primaryAim=1738, .fShiftedAim=1874, .gShiftedAim=1874, .primaryTam=1738 },
    .{ .keyId=51, .primary=3, .fShifted=1740, .gShifted=2, .keyLblAim=0, .primaryAim=833, .fShiftedAim=628, .gShiftedAim=653, .primaryTam=628 },
    .{ .keyId=52, .primary=547, .fShifted=76, .gShifted=83, .keyLblAim=547, .primaryAim=563, .fShiftedAim=589, .gShiftedAim=547, .primaryTam=547 },
    .{ .keyId=53, .primary=548, .fShifted=74, .gShifted=81, .keyLblAim=548, .primaryAim=564, .fShiftedAim=590, .gShiftedAim=548, .primaryTam=548 },
    .{ .keyId=54, .primary=549, .fShifted=79, .gShifted=85, .keyLblAim=549, .primaryAim=565, .fShiftedAim=591, .gShiftedAim=549, .primaryTam=549 },
    .{ .keyId=55, .primary=99, .fShifted=-1362, .gShifted=-2107, .keyLblAim=857, .primaryAim=566, .fShiftedAim=592, .gShiftedAim=857, .primaryTam=99 },
    .{ .keyId=61, .primary=1733, .fShifted=1734, .gShifted=1560, .keyLblAim=1733, .primaryAim=1733, .fShiftedAim=1878, .gShiftedAim=893, .primaryTam=1733 },
    .{ .keyId=62, .primary=544, .fShifted=-1923, .gShifted=-1317, .keyLblAim=544, .primaryAim=567, .fShiftedAim=593, .gShiftedAim=544, .primaryTam=544 },
    .{ .keyId=63, .primary=545, .fShifted=-1340, .gShifted=-1353, .keyLblAim=545, .primaryAim=568, .fShiftedAim=594, .gShiftedAim=545, .primaryTam=545 },
    .{ .keyId=64, .primary=546, .fShifted=-1344, .gShifted=-1372, .keyLblAim=546, .primaryAim=569, .fShiftedAim=595, .gShiftedAim=546, .primaryTam=546 },
    .{ .keyId=65, .primary=98, .fShifted=-1327, .gShifted=-1313, .keyLblAim=855, .primaryAim=570, .fShiftedAim=596, .gShiftedAim=855, .primaryTam=98 },
    .{ .keyId=71, .primary=1735, .fShifted=1736, .gShifted=1935, .keyLblAim=1735, .primaryAim=1735, .fShiftedAim=1879, .gShiftedAim=895, .primaryTam=1735 },
    .{ .keyId=72, .primary=541, .fShifted=-2037, .gShifted=-1927, .keyLblAim=541, .primaryAim=571, .fShiftedAim=597, .gShiftedAim=541, .primaryTam=541 },
    .{ .keyId=73, .primary=542, .fShifted=-1369, .gShifted=-1320, .keyLblAim=542, .primaryAim=572, .fShiftedAim=598, .gShiftedAim=542, .primaryTam=542 },
    .{ .keyId=74, .primary=543, .fShifted=-1333, .gShifted=-1376, .keyLblAim=543, .primaryAim=573, .fShiftedAim=599, .gShiftedAim=543, .primaryTam=543 },
    .{ .keyId=75, .primary=96, .fShifted=-1354, .gShifted=-1331, .keyLblAim=819, .primaryAim=574, .fShiftedAim=600, .gShiftedAim=819, .primaryTam=96 },
    .{ .keyId=81, .primary=1737, .fShifted=1543, .gShifted=-1339, .keyLblAim=1737, .primaryAim=1737, .fShiftedAim=1543, .gShiftedAim=1405, .primaryTam=1737 },
    .{ .keyId=82, .primary=540, .fShifted=101, .gShifted=-1341, .keyLblAim=540, .primaryAim=575, .fShiftedAim=601, .gShiftedAim=540, .primaryTam=540 },
    .{ .keyId=83, .primary=820, .fShifted=1742, .gShifted=1422, .keyLblAim=820, .primaryAim=818, .fShiftedAim=823, .gShiftedAim=820, .primaryTam=820 },
    .{ .keyId=84, .primary=1725, .fShifted=1724, .gShifted=-1403, .keyLblAim=0, .primaryAim=827, .fShiftedAim=822, .gShiftedAim=821, .primaryTam=1725 },
    .{ .keyId=85, .primary=95, .fShifted=-1318, .gShifted=-1322, .keyLblAim=817, .primaryAim=806, .fShiftedAim=-2552, .gShiftedAim=817, .primaryTam=95 },
};

pub export const kbd_std_R47fg_g linksection(code_section) = [37]calcKey_t{
    .{ .keyId=21, .primary=58, .fShifted=1830, .gShifted=1850, .keyLblAim=0, .primaryAim=550, .fShiftedAim=576, .gShiftedAim=1159, .primaryTam=531 },
    .{ .keyId=22, .primary=61, .fShifted=1795, .gShifted=1849, .keyLblAim=1000, .primaryAim=551, .fShiftedAim=577, .gShiftedAim=1000, .primaryTam=532 },
    .{ .keyId=23, .primary=73, .fShifted=108, .gShifted=1909, .keyLblAim=0, .primaryAim=552, .fShiftedAim=578, .gShiftedAim=807, .primaryTam=533 },
    .{ .keyId=24, .primary=60, .fShifted=63, .gShifted=1741, .keyLblAim=0, .primaryAim=553, .fShiftedAim=579, .gShiftedAim=832, .primaryTam=534 },
    .{ .keyId=25, .primary=71, .fShifted=67, .gShifted=1871, .keyLblAim=0, .primaryAim=554, .fShiftedAim=580, .gShiftedAim=1155, .primaryTam=2342 },
    .{ .keyId=26, .primary=69, .fShifted=65, .gShifted=1872, .keyLblAim=809, .primaryAim=555, .fShiftedAim=581, .gShiftedAim=809, .primaryTam=2343 },
    .{ .keyId=31, .primary=44, .fShifted=105, .gShifted=1706, .keyLblAim=0, .primaryAim=556, .fShiftedAim=582, .gShiftedAim=998, .primaryTam=2344 },
    .{ .keyId=32, .primary=51, .fShifted=1695, .gShifted=1666, .keyLblAim=0, .primaryAim=557, .fShiftedAim=583, .gShiftedAim=605, .primaryTam=2345 },
    .{ .keyId=33, .primary=40, .fShifted=109, .gShifted=39, .keyLblAim=0, .primaryAim=558, .fShiftedAim=584, .gShiftedAim=644, .primaryTam=536 },
    .{ .keyId=34, .primary=1873, .fShifted=1729, .gShifted=1411, .keyLblAim=0, .primaryAim=559, .fShiftedAim=585, .gShiftedAim=1160, .primaryTam=537 },
    .{ .keyId=35, .primary=1893, .fShifted=0, .gShifted=0, .keyLblAim=1893, .primaryAim=0, .fShiftedAim=0, .gShiftedAim=0, .primaryTam=1893 },
    .{ .keyId=36, .primary=1732, .fShifted=0, .gShifted=0, .keyLblAim=1732, .primaryAim=0, .fShiftedAim=0, .gShiftedAim=0, .primaryTam=1732 },
    .{ .keyId=41, .primary=35, .fShifted=1848, .gShifted=-1323, .keyLblAim=35, .primaryAim=35, .fShiftedAim=2420, .gShiftedAim=1172, .primaryTam=35 },
    .{ .keyId=42, .primary=36, .fShifted=1502, .gShifted=-1363, .keyLblAim=981, .primaryAim=560, .fShiftedAim=586, .gShiftedAim=981, .primaryTam=538 },
    .{ .keyId=43, .primary=97, .fShifted=-1326, .gShifted=-2036, .keyLblAim=847, .primaryAim=561, .fShiftedAim=587, .gShiftedAim=847, .primaryTam=535 },
    .{ .keyId=44, .primary=990, .fShifted=-2229, .gShifted=-1328, .keyLblAim=0, .primaryAim=562, .fShiftedAim=588, .gShiftedAim=2032, .primaryTam=2336 },
    .{ .keyId=45, .primary=1738, .fShifted=1723, .gShifted=-1321, .keyLblAim=1738, .primaryAim=1738, .fShiftedAim=1874, .gShiftedAim=1874, .primaryTam=1738 },
    .{ .keyId=51, .primary=3, .fShifted=1740, .gShifted=2, .keyLblAim=0, .primaryAim=833, .fShiftedAim=628, .gShiftedAim=653, .primaryTam=628 },
    .{ .keyId=52, .primary=547, .fShifted=76, .gShifted=83, .keyLblAim=547, .primaryAim=563, .fShiftedAim=589, .gShiftedAim=547, .primaryTam=547 },
    .{ .keyId=53, .primary=548, .fShifted=74, .gShifted=81, .keyLblAim=548, .primaryAim=564, .fShiftedAim=590, .gShiftedAim=548, .primaryTam=548 },
    .{ .keyId=54, .primary=549, .fShifted=79, .gShifted=85, .keyLblAim=549, .primaryAim=565, .fShiftedAim=591, .gShiftedAim=549, .primaryTam=549 },
    .{ .keyId=55, .primary=99, .fShifted=-1362, .gShifted=-2107, .keyLblAim=857, .primaryAim=566, .fShiftedAim=592, .gShiftedAim=857, .primaryTam=99 },
    .{ .keyId=61, .primary=1733, .fShifted=1734, .gShifted=1560, .keyLblAim=1733, .primaryAim=1733, .fShiftedAim=1878, .gShiftedAim=893, .primaryTam=1733 },
    .{ .keyId=62, .primary=544, .fShifted=-1923, .gShifted=-1317, .keyLblAim=544, .primaryAim=567, .fShiftedAim=593, .gShiftedAim=544, .primaryTam=544 },
    .{ .keyId=63, .primary=545, .fShifted=-1340, .gShifted=-1353, .keyLblAim=545, .primaryAim=568, .fShiftedAim=594, .gShiftedAim=545, .primaryTam=545 },
    .{ .keyId=64, .primary=546, .fShifted=-1344, .gShifted=-1372, .keyLblAim=546, .primaryAim=569, .fShiftedAim=595, .gShiftedAim=546, .primaryTam=546 },
    .{ .keyId=65, .primary=98, .fShifted=-1327, .gShifted=-1313, .keyLblAim=855, .primaryAim=570, .fShiftedAim=596, .gShiftedAim=855, .primaryTam=98 },
    .{ .keyId=71, .primary=1735, .fShifted=1736, .gShifted=1935, .keyLblAim=1735, .primaryAim=1735, .fShiftedAim=1879, .gShiftedAim=895, .primaryTam=1735 },
    .{ .keyId=72, .primary=541, .fShifted=-2037, .gShifted=-1927, .keyLblAim=541, .primaryAim=571, .fShiftedAim=597, .gShiftedAim=541, .primaryTam=541 },
    .{ .keyId=73, .primary=542, .fShifted=-1369, .gShifted=-1320, .keyLblAim=542, .primaryAim=572, .fShiftedAim=598, .gShiftedAim=542, .primaryTam=542 },
    .{ .keyId=74, .primary=543, .fShifted=-1333, .gShifted=-1376, .keyLblAim=543, .primaryAim=573, .fShiftedAim=599, .gShiftedAim=543, .primaryTam=543 },
    .{ .keyId=75, .primary=96, .fShifted=-1354, .gShifted=-1331, .keyLblAim=819, .primaryAim=574, .fShiftedAim=600, .gShiftedAim=819, .primaryTam=96 },
    .{ .keyId=81, .primary=1737, .fShifted=1543, .gShifted=-1339, .keyLblAim=1737, .primaryAim=1737, .fShiftedAim=1543, .gShiftedAim=1405, .primaryTam=1737 },
    .{ .keyId=82, .primary=540, .fShifted=101, .gShifted=-1341, .keyLblAim=540, .primaryAim=575, .fShiftedAim=601, .gShiftedAim=540, .primaryTam=540 },
    .{ .keyId=83, .primary=820, .fShifted=1742, .gShifted=1422, .keyLblAim=820, .primaryAim=818, .fShiftedAim=823, .gShiftedAim=820, .primaryTam=820 },
    .{ .keyId=84, .primary=1725, .fShifted=1724, .gShifted=-1403, .keyLblAim=0, .primaryAim=827, .fShiftedAim=822, .gShiftedAim=821, .primaryTam=1725 },
    .{ .keyId=85, .primary=95, .fShifted=-1318, .gShifted=-1322, .keyLblAim=817, .primaryAim=806, .fShiftedAim=-2552, .gShiftedAim=817, .primaryTam=95 },
};

comptime {
    if (!dmcp_build) {
        @export(&kbd_std_E47_data, .{ .name = "kbd_std_E47", .linkage = .strong });
        @export(&kbd_std_V47_data, .{ .name = "kbd_std_V47", .linkage = .strong });
        @export(&kbd_std_N47_data, .{ .name = "kbd_std_N47", .linkage = .strong });
        @export(&kbd_std_D47_data, .{ .name = "kbd_std_D47", .linkage = .strong });
    }
}
// ===========================================================================
// fnAssign
// ===========================================================================
pub export fn fnAssign(mode: u16) callconv(.c) void {
    if (mode != 0) {
        createMenu(aimBuffer);
        aimBuffer[0] = 0;
    } else {
        previousCalcMode = calcMode;
        calcMode = CM_ASSIGN;
        itemToBeAssigned = 0;
        updateAssignTamBuffer();
    }
}

// ===========================================================================
// removeUserItemAssignments
// ===========================================================================
pub export fn removeUserItemAssignments(userItem: i16, userItemName: [*c]u8) callconv(.c) void {
    var deleteAllItems: bool_t = false;

    itemToBeAssigned = ITM_NULL;
    if (userItemName[0] == 0) {
        deleteAllItems = true;
    }

    // Predefined configurable menus
    {
        var i: usize = 0;
        while (i < 18) : (i += 1) {
            if ((userMenuItems[i].item == userItem) and (userMenuItems[i].argumentName[0] != 0) and
                (deleteAllItems or compareString(&userMenuItems[i].argumentName, userItemName, CMP_NAME) == 0))
            {
                assignToMyMenu(@intCast(i));
            }
            if ((userAlphaItems[i].item == userItem) and (userAlphaItems[i].argumentName[0] != 0) and
                (deleteAllItems or (compareString(&userAlphaItems[i].argumentName, userItemName, CMP_NAME) == 0)))
            {
                assignToMyAlpha(@intCast(i));
            }
        }
    }
    // User-defined menus
    {
        var i: usize = 0;
        while (i < numberOfUserMenus) : (i += 1) {
            var j: usize = 0;
            while (j < 18) : (j += 1) {
                if ((userMenus[i].menuItem[j].item == userItem) and (userMenus[i].menuItem[j].argumentName[0] != 0) and
                    (deleteAllItems or (compareString(&userMenus[i].menuItem[j].argumentName, userItemName, CMP_NAME) == 0)))
                {
                    _assignItem(@ptrCast(&userMenus[i].menuItem[j]));
                }
            }
        }
    }
    // Keys
    var key: [*c]calcKey_t = undefined;
    var lbl: [22]u8 = undefined;
    const f: bool_t = shiftF;
    const g: bool_t = shiftG;
    var kc: [4]u8 = std.mem.zeroes([4]u8);
    {
        var i: usize = 0;
        while (i < 37) : (i += 1) {
            key = &kbd_usr[i];
            kc[0] = @intCast((i / 10) + '0');
            kc[1] = @intCast((i % 10) + '0');
            kc[2] = 0;
            if (key.*.primary == userItem) {
                stringToUtf8(getNthString(userKeyLabel, @intCast(i * 6)), &lbl);
                if ((lbl[0] != 0) and (deleteAllItems or (compareString(&lbl, userItemName, CMP_NAME) == 0))) {
                    shiftF = false;
                    shiftG = false;
                    assignToKey(&kc);
                }
            }
            if (key.*.fShifted == userItem) {
                stringToUtf8(getNthString(userKeyLabel, @intCast(i * 6 + 1)), &lbl);
                if ((lbl[0] != 0) and (deleteAllItems or (compareString(&lbl, userItemName, CMP_NAME) == 0))) {
                    shiftF = true;
                    shiftG = false;
                    assignToKey(&kc);
                }
            }
            if (key.*.gShifted == userItem) {
                stringToUtf8(getNthString(userKeyLabel, @intCast(i * 6 + 2)), &lbl);
                if ((lbl[0] != 0) and (deleteAllItems or (compareString(&lbl, userItemName, CMP_NAME) == 0))) {
                    shiftF = false;
                    shiftG = true;
                    assignToKey(&kc);
                }
            }
        }
    }
    shiftF = f;
    shiftG = g;
}

// ===========================================================================
// fnDeleteMenu
// ===========================================================================
pub export fn fnDeleteMenu(id: u16) callconv(.c) void {
    if (id >= numberOfUserMenus) {
        displayCalcErrorMessage(ERROR_CANNOT_DELETE_PREDEF_ITEM, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
        return;
    } else {
        removeUserItemAssignments(-MNU_DYNAMIC, &userMenus[id].menuName);
        removeUserMenuFromStack(@intCast(id));
        if (numberOfUserMenus == 1) {
            freeC47Blocks(userMenus, TO_BLOCKS(SIZEOF_USERMENU));
            userMenus = null;
            numberOfUserMenus = 0;
        } else if (numberOfUserMenus > 1) {
            if (id < numberOfUserMenus - 1) {
                _ = xcopy(userMenus + id, userMenus + id + 1, @intCast(SIZEOF_USERMENU * (numberOfUserMenus - id - 1)));
            }
            reduceC47Blocks(userMenus, TO_BLOCKS(SIZEOF_USERMENU) * numberOfUserMenus, TO_BLOCKS(SIZEOF_USERMENU) * (numberOfUserMenus - 1));
            numberOfUserMenus -= 1;
        }
    }
    if (currentUserMenu > id) {
        currentUserMenu -= 1;
    } else if (currentUserMenu == id) {
        showSoftmenu(-MNU_DYNAMIC);
        popSoftmenu();
    }
}

// ===========================================================================
// fnDeleteUserMenus
// ===========================================================================
pub export fn fnDeleteUserMenus(confirmation: u16) callconv(.c) void {
    if ((confirmation == NOT_CONFIRMED) and (programRunStop != PGM_RUNNING)) {
        setConfirmationMode(&fnDeleteUserMenus);
    } else {
        removeUserItemAssignments(-MNU_DYNAMIC, @constCast(""));
        removeUserMenuFromStack(@intCast(numberOfUserMenus));
        freeC47Blocks(userMenus, TO_BLOCKS(SIZEOF_USERMENU) * numberOfUserMenus);
        userMenus = null;
        numberOfUserMenus = 0;
        _ = createHOME();
        _ = createPFN();
        if (programRunStop != PGM_RUNNING) {
            temporaryInformation = TI_DEL_ALL_MENUS;
        } else {
            temporaryInformation = TI_NO_INFO;
        }
        screenUpdatingMode = SCRUPD_AUTO;
    }
}

// ===========================================================================
// fnClearUserMenus
// ===========================================================================
pub export fn fnClearUserMenus(confirmation: u16) callconv(.c) void {
    if ((confirmation == NOT_CONFIRMED) and (programRunStop != PGM_RUNNING)) {
        setConfirmationMode(&fnClearUserMenus);
    } else {
        var i: usize = 0;
        while (i < numberOfUserMenus) : (i += 1) {
            _ = memset(&userMenus[i].menuItem, 0, 18 * SIZEOF_USERMENUITEM);
        }
        _ = createHOME();
        _ = createPFN();
        if (programRunStop != PGM_RUNNING) {
            temporaryInformation = TI_CLEAR_ALL_MENUS;
        } else {
            temporaryInformation = TI_NO_INFO;
        }
        screenUpdatingMode = SCRUPD_AUTO;
    }
}

// ===========================================================================
// updateAssignTamBuffer
// ===========================================================================
pub export fn updateAssignTamBuffer() callconv(.c) void {
    var tbPtr: [*c]u8 = tamBuffer;
    tbPtr = stringCopy(tbPtr, "ASSIGN ");

    if (itemToBeAssigned == 0) {
        if (tam.alpha) {
            tbPtr = stringCopy(tbPtr, STD_LEFT_SINGLE_QUOTE);
            if (aimBuffer[0] == 0) {
                tbPtr = stringCopy(tbPtr, STD_CURSOR);
            } else {
                _ = stringCopy(tmpString, aimBuffer);
                insertAlphaCursor(0);
                tbPtr = stringCopy(tbPtr, tmpString);
                tbPtr = stringCopy(tbPtr, STD_RIGHT_SINGLE_QUOTE);
            }
        } else {
            tbPtr = stringCopy(tbPtr, "_");
        }
    } else if (itemToBeAssigned == ASSIGN_CLEAR) {
        tbPtr = stringCopy(tbPtr, "NULL");
    } else if (itemToBeAssigned >= ASSIGN_LABELS) {
        var lblPtr: [*c]u8 = labelList[@intCast(itemToBeAssigned - ASSIGN_LABELS)].labelPointer;
        const count: u32 = lblPtr[0];
        lblPtr += 1;
        var i: u32 = 0;
        while (i < count) : (i += 1) {
            tbPtr[0] = lblPtr[0];
            tbPtr += 1;
            lblPtr += 1;
        }
    } else if (itemToBeAssigned >= ASSIGN_RESERVED_VARIABLES) {
        tbPtr = stringCopy(tbPtr, @ptrCast(&allReservedVariables[@intCast(itemToBeAssigned - ASSIGN_RESERVED_VARIABLES)].reservedVariableName[1]));
    } else if (itemToBeAssigned >= ASSIGN_NAMED_VARIABLES) {
        tbPtr = stringCopy(tbPtr, @ptrCast(&allNamedVariables[@intCast(itemToBeAssigned - ASSIGN_NAMED_VARIABLES)].variableName[1]));
    } else if (itemToBeAssigned <= ASSIGN_USER_MENU) {
        tbPtr = stringCopy(tbPtr, &userMenus[@intCast(-(itemToBeAssigned - ASSIGN_USER_MENU))].menuName);
    } else if (isItemConversion(itemToBeAssigned)) {
        var tb: [64]u8 = undefined;
        fullConvSoftMenuItemNameInclHPCONV(itemToBeAssigned, &tb);
        expandAbbreviations(&tb);
        tbPtr = stringCopy(tbPtr, &tb);
    } else if (itemToBeAssigned < 0) {
        tbPtr = stringCopy(tbPtr, &indexOfItems[@intCast(-itemToBeAssigned)].itemCatalogName);
    } else if (indexOfItems[@intCast(itemToBeAssigned)].itemCatalogName[0] == 0) {
        tbPtr = stringCopy(tbPtr, &indexOfItems[@intCast(itemToBeAssigned)].itemSoftmenuName);
    } else {
        tbPtr = stringCopy(tbPtr, &indexOfItems[@intCast(itemToBeAssigned)].itemCatalogName);
    }

    tbPtr = stringCopy(tbPtr, " ");
    if (itemToBeAssigned != 0 and tam.alpha) {
        tbPtr = stringCopy(tbPtr, STD_LEFT_SINGLE_QUOTE);
        if (aimBuffer[0] == 0) {
            tbPtr = stringCopy(tbPtr, STD_CURSOR);
        } else {
            _ = stringCopy(tmpString, aimBuffer);
            insertAlphaCursor(0);
            tbPtr = stringCopy(tbPtr, tmpString);
            tbPtr = stringCopy(tbPtr, STD_RIGHT_SINGLE_QUOTE);
        }
    } else if (itemToBeAssigned != 0 and shiftF) {
        tbPtr = stringCopy(tbPtr, STD_SUP_BOLD_f ++ STD_CURSOR);
    } else if (itemToBeAssigned != 0 and shiftG) {
        tbPtr = stringCopy(tbPtr, STD_SUP_BOLD_g ++ STD_CURSOR);
    } else {
        tbPtr = stringCopy(tbPtr, "_");
    }
}

// ===========================================================================
// _assignItem
// ===========================================================================
pub export fn _assignItem(menuItem: *userMenuItem_t) callconv(.c) void {
    var lblPtr: [*c]const u8 = null;
    var l: u32 = 0;
    if (itemToBeAssigned == ASSIGN_CLEAR) {
        menuItem.item = ITM_NULL;
        menuItem.argumentName[0] = 0;
    } else if (itemToBeAssigned >= ASSIGN_LABELS) {
        lblPtr = labelList[@intCast(itemToBeAssigned - ASSIGN_LABELS)].labelPointer;
        menuItem.item = ITM_XEQ;
    } else if (itemToBeAssigned >= ASSIGN_RESERVED_VARIABLES) {
        lblPtr = &allReservedVariables[@intCast(itemToBeAssigned - ASSIGN_RESERVED_VARIABLES)].reservedVariableName;
        menuItem.item = ITM_RCL;
    } else if (itemToBeAssigned >= ASSIGN_NAMED_VARIABLES) {
        lblPtr = &allNamedVariables[@intCast(itemToBeAssigned - ASSIGN_NAMED_VARIABLES)].variableName;
        menuItem.item = ITM_RCL;
    } else if (itemToBeAssigned <= ASSIGN_USER_MENU) {
        lblPtr = @ptrCast(&userMenus[@intCast(-(itemToBeAssigned - ASSIGN_USER_MENU))].menuName);
        menuItem.item = -MNU_DYNAMIC;
        _ = xcopy(&menuItem.argumentName, lblPtr, @intCast(stringByteLength(lblPtr) + 1));
        lblPtr = null;
    } else {
        menuItem.item = itemToBeAssigned;
        menuItem.argumentName[0] = 0;
    }
    if (lblPtr != null) {
        l = lblPtr[0];
        lblPtr += 1;
        _ = xcopy(&menuItem.argumentName, lblPtr, l);
        menuItem.argumentName[l] = 0;
    }
}

// ===========================================================================
// assignToMyMenu
// ===========================================================================
pub export fn assignToMyMenu(position: u16) callconv(.c) void {
    if (position < 18) {
        _assignItem(&userMenuItems[position]);
    }
    cachedDynamicMenu = 0;
    refreshScreen(20);
}

// ===========================================================================
// assignToMyAlpha
// ===========================================================================
pub export fn assignToMyAlpha(position: u16) callconv(.c) void {
    if (position < 18) {
        _assignItem(&userAlphaItems[position]);
    }
    cachedDynamicMenu = 0;
    refreshScreen(21);
}

// ===========================================================================
// assignToUserMenu
// ===========================================================================
pub export fn assignToUserMenu(position: u16) callconv(.c) void {
    if (position < 18) {
        _assignItem(@ptrCast(&userMenus[currentUserMenu].menuItem[position]));
    }
    cachedDynamicMenu = 0;
    refreshScreen(22);
}

// ===========================================================================
// _typeOfFunction (static)
// ===========================================================================
fn _typeOfFunction(func: i16) c_int {
    switch (func) {
        ITM_NULL => return 0,
        ITM_EXIT1, ITM_ENTER, ITM_UP1, ITM_DOWN1, ITM_BACKSPACE => return 1,
        ITM_0, 541, 542, 543, 544, 545, 546, 547, 548, ITM_9, ITM_PERIOD, ITM_ADD, ITM_SUB, ITM_MULT, ITM_DIV => return 2,
        ITM_A, ITM_B, ITM_C, ITM_D, ITM_E, ITM_H, ITM_I, ITM_J, ITM_K, ITM_L, ITM_O => return 3,
        else => return 4,
    }
}

// ===========================================================================
// _assignTamAlpha (static)
// ===========================================================================
fn _assignTamAlpha(key: *calcKey_t, item: u16) bool_t {
    switch (item) {
        @as(u16, @bitCast(ITM_A)) => {
            key.primaryTam = ITM_REG_A;
            return true;
        },
        @as(u16, @bitCast(ITM_B)) => {
            key.primaryTam = ITM_REG_B;
            return true;
        },
        @as(u16, @bitCast(ITM_C)) => {
            key.primaryTam = ITM_REG_C;
            return true;
        },
        @as(u16, @bitCast(ITM_D)) => {
            key.primaryTam = ITM_REG_D;
            return true;
        },
        @as(u16, @bitCast(ITM_E)) => {
            key.primaryTam = ITM_REG_E;
            return true;
        },
        @as(u16, @bitCast(ITM_H)) => {
            key.primaryTam = ITM_REG_H;
            return true;
        },
        @as(u16, @bitCast(ITM_I)) => {
            key.primaryTam = ITM_REG_I;
            return true;
        },
        @as(u16, @bitCast(ITM_J)) => {
            key.primaryTam = ITM_REG_J;
            return true;
        },
        @as(u16, @bitCast(ITM_K)) => {
            key.primaryTam = ITM_REG_K;
            return true;
        },
        @as(u16, @bitCast(ITM_L)) => {
            key.primaryTam = ITM_REG_L;
            return true;
        },
        @as(u16, @bitCast(ITM_O)) => {
            key.primaryTam = ITM_REG_O;
            return true;
        },
        @as(u16, @bitCast(ITM_M)) => {
            key.primaryTam = ITM_REG_M;
            return true;
        },
        @as(u16, @bitCast(ITM_N)) => {
            key.primaryTam = ITM_REG_N;
            return true;
        },
        @as(u16, @bitCast(ITM_P)) => {
            key.primaryTam = ITM_REG_P;
            return true;
        },
        @as(u16, @bitCast(ITM_R)) => {
            key.primaryTam = ITM_REG_R;
            return true;
        },
        @as(u16, @bitCast(ITM_S)) => {
            key.primaryTam = ITM_REG_S;
            return true;
        },
        @as(u16, @bitCast(ITM_T)) => {
            key.primaryTam = ITM_REG_T;
            return true;
        },
        else => return false,
    }
}

// ===========================================================================
// _assignTamNum (static)
// ===========================================================================
fn _assignTamNum(key: *calcKey_t, item: u16) bool_t {
    if (_typeOfFunction(@bitCast(item)) == 2) {
        key.primaryTam = @bitCast(item);
        return true;
    } else {
        return false;
    }
}

// ===========================================================================
// assignToKey
// ===========================================================================
pub export fn assignToKey(data: [*c]const u8) callconv(.c) void {
    const keyCode: i32 = (@as(i32, data[0]) - '0') * 10 + @as(i32, data[1]) - '0';
    const key: *calcKey_t = &kbd_usr[@intCast(keyCode)];
    var tmpMenuItem: userMenuItem_t = undefined;
    keyStateCode = @intCast((if (previousCalcMode == CM_AIM) @as(u8, 3) else @as(u8, 0)) + (if (shiftG) @as(u8, 2) else if (shiftF) @as(u8, 1) else @as(u8, 0)));
    const stdKey: *const calcKey_t = &kbdStd()[@intCast(keyCode)];

    _assignItem(&tmpMenuItem);
    switch (_typeOfFunction(tmpMenuItem.item)) {
        0 => {
            switch (keyStateCode) {
                5 => key.gShiftedAim = stdKey.gShiftedAim,
                4 => key.fShiftedAim = stdKey.fShiftedAim,
                3 => {
                    key.primaryAim = stdKey.primaryAim;
                    key.primaryTam = stdKey.primaryTam;
                },
                2 => key.gShifted = stdKey.gShifted,
                1 => key.fShifted = stdKey.fShifted,
                0 => {
                    key.primary = stdKey.primary;
                    key.primaryTam = stdKey.primaryTam;
                    _ = _assignTamAlpha(key, @bitCast(key.primaryAim));
                },
                else => {},
            }
        },
        1 => {
            switch (keyStateCode) {
                5, 2 => {
                    key.gShifted = tmpMenuItem.item;
                    key.gShiftedAim = key.gShifted;
                },
                4, 1 => {
                    key.fShifted = tmpMenuItem.item;
                    key.fShiftedAim = key.fShifted;
                },
                3, 0 => {
                    key.primaryTam = tmpMenuItem.item;
                    key.primary = key.primaryTam;
                    key.primaryAim = key.primary;
                },
                else => {},
            }
        },
        2 => {
            switch (keyStateCode) {
                5 => key.gShiftedAim = tmpMenuItem.item,
                4 => {
                    key.fShiftedAim = tmpMenuItem.item;
                    switch (tmpMenuItem.item) {
                        ITM_PLUS => key.primary = ITM_ADD,
                        ITM_MINUS => key.primary = ITM_SUB,
                        ITM_CROSS, ITM_DOT, ITM_PROD_SIGN => key.primary = ITM_MULT,
                        ITM_SLASH => key.primary = ITM_DIV,
                        else => key.primary = tmpMenuItem.item,
                    }
                    _ = _assignTamNum(key, @bitCast(key.primary));
                },
                3 => key.primaryAim = tmpMenuItem.item,
                2 => key.gShifted = tmpMenuItem.item,
                1 => key.fShifted = tmpMenuItem.item,
                0 => {
                    key.primaryTam = tmpMenuItem.item;
                    key.primary = key.primaryTam;
                    switch (tmpMenuItem.item) {
                        ITM_ADD => key.fShiftedAim = ITM_PLUS,
                        ITM_SUB => key.fShiftedAim = ITM_MINUS,
                        ITM_MULT => key.fShiftedAim = ITM_PROD_SIGN,
                        ITM_DIV => key.fShiftedAim = ITM_SLASH,
                        else => key.fShiftedAim = tmpMenuItem.item,
                    }
                },
                else => {},
            }
        },
        3 => {
            switch (keyStateCode) {
                5 => key.gShiftedAim = tmpMenuItem.item,
                4 => key.fShiftedAim = tmpMenuItem.item,
                3 => {
                    key.primaryAim = tmpMenuItem.item;
                    _ = _assignTamAlpha(key, @bitCast(tmpMenuItem.item));
                },
                2 => key.gShifted = tmpMenuItem.item,
                1 => key.fShifted = tmpMenuItem.item,
                0 => {
                    key.primary = tmpMenuItem.item;
                    if (!_assignTamAlpha(key, @bitCast(key.primaryAim))) {
                        key.primaryTam = ITM_NULL;
                    }
                },
                else => {},
            }
        },
        else => {
            switch (keyStateCode) {
                5 => key.gShiftedAim = tmpMenuItem.item,
                4 => key.fShiftedAim = tmpMenuItem.item,
                3 => {
                    key.primaryAim = tmpMenuItem.item;
                    if (!_assignTamAlpha(key, @bitCast(key.primaryAim)) and !_assignTamNum(key, @bitCast(key.primary))) {
                        key.primaryTam = ITM_NULL;
                    }
                },
                2 => key.gShifted = tmpMenuItem.item,
                1 => key.fShifted = tmpMenuItem.item,
                0 => {
                    key.primary = tmpMenuItem.item;
                    if (!_assignTamNum(key, @bitCast(key.primary)) and !_assignTamAlpha(key, @bitCast(key.primaryAim))) {
                        key.primaryTam = ITM_NULL;
                    }
                },
                else => {},
            }
        },
    }

    if (keyCode == 5) {
        key.primaryTam = stdKey.primaryTam;
    }

    setUserKeyArgument(@intCast(keyCode * 6 + keyStateCode), &tmpMenuItem.argumentName);
}

// kbd_std is a #define selecting the active layout by calcModel. The PC_BUILD
// macro adds the E47/D47/V47/N47 layouts; the firmware macro stops at the R47
// variants. Reproduce both, gated on dmcp_build.
const USER_DM42: u8 = 45;
const USER_E47: u8 = 43;
const USER_D47: u8 = 47;
const USER_V47: u8 = 40;
const USER_N47: u8 = 51;
const USER_R47f_g: u8 = 61;
const USER_R47bk_fg: u8 = 62;
const USER_R47fg_bk: u8 = 63;
const USER_R47fg_g: u8 = 64;
inline fn kbdStd() *const [37]calcKey_t {
    if (calcModel == USER_C47_v) return &kbd_std_C47;
    if (calcModel == USER_DM42) return &kbd_std_DM42;
    if (calcModel == USER_R47f_g) return &kbd_std_R47f_g;
    if (calcModel == USER_R47bk_fg) return &kbd_std_R47bk_fg;
    if (calcModel == USER_R47fg_bk) return &kbd_std_R47fg_bk;
    if (calcModel == USER_R47fg_g) return &kbd_std_R47fg_g;
    if (comptime !dmcp_build) {
        if (calcModel == USER_E47) return &kbd_std_E47_data;
        if (calcModel == USER_D47) return &kbd_std_D47_data;
        if (calcModel == USER_V47) return &kbd_std_V47_data;
        if (calcModel == USER_N47) return &kbd_std_N47_data;
        if (calcModel == USER_DM42) return &kbd_std_DM42;
    }
    return &kbd_std_C47;
}
const USER_C47_v: u8 = 46;
extern var calcModel: u8;

// ===========================================================================
// initUserKeyArgument
// ===========================================================================
pub export fn initUserKeyArgument() callconv(.c) void {
    userKeyLabelSize = 37 * 6 * 1 + 1;
    userKeyLabel = @ptrCast(allocC47Blocks(TO_BLOCKS(userKeyLabelSize)));
    _ = memset(userKeyLabel, 0, TO_BYTES(TO_BLOCKS(userKeyLabelSize)));
}
inline fn TO_BYTES(n: usize) usize {
    return n << BPB;
}

// ===========================================================================
// setUserKeyArgument
// ===========================================================================
pub export fn setUserKeyArgument(position: u16, name: [*c]const u8) callconv(.c) void {
    const userKeyLabelPtr1: [*c]u8 = getNthString(userKeyLabel, @intCast(position));
    const userKeyLabelPtr2: [*c]u8 = getNthString(userKeyLabel, @intCast(position + 1));
    const userKeyLabelPtr3: [*c]u8 = getNthString(userKeyLabel, 37 * 6);
    const newUserKeyLabelSize: u16 = userKeyLabelSize -% @as(u16, @intCast(stringByteLength(userKeyLabelPtr1))) +% @as(u16, @intCast(stringByteLength(name)));
    const newUserKeyLabel: [*c]u8 = @ptrCast(allocC47Blocks(TO_BLOCKS(newUserKeyLabelSize)));
    var newUserKeyLabelPtr: [*c]u8 = newUserKeyLabel;

    _ = xcopy(newUserKeyLabelPtr, userKeyLabel, @intCast(@as(c_int, @intCast(@intFromPtr(userKeyLabelPtr1) - @intFromPtr(userKeyLabel)))));
    newUserKeyLabelPtr += @intFromPtr(userKeyLabelPtr1) - @intFromPtr(userKeyLabel);
    _ = xcopy(newUserKeyLabelPtr, name, @intCast(stringByteLength(name)));
    newUserKeyLabelPtr += @as(usize, @intCast(stringByteLength(name)));
    newUserKeyLabelPtr[0] = 0;
    newUserKeyLabelPtr += 1;
    _ = xcopy(newUserKeyLabelPtr, userKeyLabelPtr2, @intCast(@as(c_int, @intCast(@intFromPtr(userKeyLabelPtr3) - @intFromPtr(userKeyLabelPtr2)))));
    newUserKeyLabelPtr += @intFromPtr(userKeyLabelPtr3) - @intFromPtr(userKeyLabelPtr2);
    newUserKeyLabelPtr[0] = 0;
    newUserKeyLabelPtr += 1;

    freeC47Blocks(userKeyLabel, TO_BLOCKS(userKeyLabelSize));
    userKeyLabel = newUserKeyLabel;
    userKeyLabelSize = newUserKeyLabelSize;
}

// ===========================================================================
// createMenu
// ===========================================================================
pub export fn createMenu(name: [*c]const u8) callconv(.c) void {
    if (validateName(name)) {
        if (isUniqueMenuName(name)) {
            if (numberOfUserMenus == 0) {
                userMenus = @ptrCast(@alignCast(allocC47Blocks(TO_BLOCKS(SIZEOF_USERMENU))));
            } else {
                userMenus = @ptrCast(@alignCast(reallocC47Blocks(userMenus, TO_BLOCKS(SIZEOF_USERMENU) * numberOfUserMenus, TO_BLOCKS(SIZEOF_USERMENU) * (numberOfUserMenus + 1))));
            }
            _ = memset(userMenus + numberOfUserMenus, 0, SIZEOF_USERMENU);
            if (comptime !dmcp_build) {
                if (name == null) {
                    abortfHost("The parameter name is NULL!\n");
                }
                if (stringByteLength(name) + 1 > @as(i32, @intCast(@sizeOf(@TypeOf(userMenus[0].menuName))))) {
                    var tmp: [1000]u8 = undefined;
                    _ = sprintf(&tmp, "The string \"name\" <%s> is too long (%d+1 bytes) to be copied to userMenus[numberOfUserMenus].menuName (%d bytes)\n", name, stringByteLength(name), @as(i32, @intCast(@sizeOf(@TypeOf(userMenus[0].menuName)))));
                    abortfHost(&tmp);
                }
            }
            _ = xcopy(&userMenus[numberOfUserMenus].menuName, name, @intCast(stringByteLength(name) + 1));
            numberOfUserMenus += 1;
        } else {
            displayCalcErrorMessage(ERROR_ENTER_NEW_NAME, ERR_REGISTER_LINE, REGISTER_X);
            if (comptime extra_info) {
                _ = sprintf(errorMessage, "the name %s", name);
                if (comptime !dmcp_build) moreInfoOnError("In function createMenu:", errorMessage, "is already in use!", null);
            }
        }
    } else {
        displayCalcErrorMessage(ERROR_INVALID_NAME, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            if (comptime !dmcp_build) moreInfoOnError("In function createMenu:", "the menu", name, "does not follow the naming convention");
        }
    }
}

// abortf host macro: fprintf(stderr,...);perror(a);fflush(stderr);abort().
// Reduced to perror+abort: perror already writes the message to stderr, and
// this avoids referencing the `stderr` symbol directly, which is not portable
// (it is __stderrp on macOS and not a plain symbol in Windows ucrt). The
// color/location decoration is cosmetic.
extern fn perror(s: [*c]const u8) void;
fn abortfHost(a: [*c]const u8) noreturn {
    perror(a);
    abort();
}

// ===========================================================================
// assignEnterAlpha
// ===========================================================================
pub export fn assignEnterAlpha() callconv(.c) void {
    tam.alpha = true;
    setSystemFlag(FLAG_ALPHA);
    aimBuffer[0] = 0;
    tamEnterMode(ITM_ASSIGN);
    calcModeAim(NOPARAM);
}

// ===========================================================================
// assignLeaveAlpha
// ===========================================================================
pub export fn assignLeaveAlpha() callconv(.c) void {
    tam.alpha = false;
    clearSystemFlag(FLAG_ALPHA);
    leaveTamModeIfEnabled();
    alphaCursor = 0;
    if (comptime !dmcp_build) {
        calcModeNormalGui();
    }
}

// ===========================================================================
// assignGetName1
// ===========================================================================
pub export fn assignGetName1() callconv(.c) void {
    if (compareString(aimBuffer, "ENTER", CMP_NAME) == 0) {
        itemToBeAssigned = ITM_ENTER;
    } else if (compareString(aimBuffer, "EXIT", CMP_NAME) == 0) {
        itemToBeAssigned = ITM_EXIT1;
    } else if (compareString(aimBuffer, "USER", CMP_NAME) == 0) {
        itemToBeAssigned = ITM_USERMODE;
    } else if (compareString(aimBuffer, "UP", CMP_NAME) == 0) {
        itemToBeAssigned = ITM_UP1;
    } else if (compareString(aimBuffer, "DOWN", CMP_NAME) == 0) {
        itemToBeAssigned = ITM_DOWN1;
    } else if (compareString(aimBuffer, "BKSPC", CMP_NAME) == 0) {
        itemToBeAssigned = ITM_BACKSPACE;
    } else if (aimBuffer[0] == 0) {
        itemToBeAssigned = ITM_NULL;
    } else {
        itemToBeAssigned = ASSIGN_CLEAR;

        // user-defined menus
        var i: i32 = 0;
        while (i < numberOfUserMenus) : (i += 1) {
            if (compareString(aimBuffer, &userMenus[@intCast(i)].menuName, CMP_NAME) == 0) {
                itemToBeAssigned = ASSIGN_USER_MENU - @as(i16, @intCast(i));
                break;
            }
        }

        // preset menus
        if (itemToBeAssigned == ASSIGN_CLEAR) {
            var k: usize = 0;
            while (softmenu[k].menuItem != 0) : (k += 1) {
                if (compareString(aimBuffer, &indexOfItems[@intCast(-softmenu[k].menuItem)].itemCatalogName, CMP_NAME) == 0) {
                    itemToBeAssigned = softmenu[k].menuItem;
                    break;
                }
            }
        }

        // programs
        if (itemToBeAssigned == ASSIGN_CLEAR) {
            itemToBeAssigned = findNamedLabel(aimBuffer);
            if (itemToBeAssigned == INVALID_VARIABLE) {
                itemToBeAssigned = ASSIGN_CLEAR;
            } else {
                itemToBeAssigned = itemToBeAssigned - FIRST_LABEL + ASSIGN_LABELS;
            }
        }

        // functions
        if (itemToBeAssigned == ASSIGN_CLEAR) {
            var j: i32 = 0;
            while (j < LAST_ITEM) : (j += 1) {
                if ((indexOfItems[@intCast(j)].status & CAT_STATUS) == CAT_FNCT and compareString(aimBuffer, &indexOfItems[@intCast(j)].itemCatalogName, CMP_NAME) == 0) {
                    itemToBeAssigned = @intCast(j);
                    break;
                }
            }
        }
    }
}

// ===========================================================================
// _assignToKey (static)
// ===========================================================================
fn _assignToKey(keyFunc: i16) bool_t {
    keyStateCode = if (previousCalcMode == CM_AIM) 3 else 0;

    var i: i32 = 0;
    while (i < 3) : (i += 1) {
        var j: i32 = 0;
        while (j < 37) : (j += 1) {
            const key: *const calcKey_t = if (getSystemFlag(FLAG_USER)) &kbd_usr[@intCast(j)] else &kbdStd()[@intCast(j)];
            var kf: i16 = 0;
            switch (@as(i32, keyStateCode) + i) {
                5 => kf = key.gShiftedAim,
                4 => kf = key.fShiftedAim,
                3 => kf = key.primaryAim,
                2 => kf = key.gShifted,
                1 => kf = key.fShifted,
                0 => kf = key.primary,
                else => {},
            }
            if (keyFunc == kf and (!getSystemFlag(FLAG_USER) or getNthString(userKeyLabel, @intCast(j * 6 + @as(i32, keyStateCode) + i))[0] == 0)) {
                var kc: [4]u8 = std.mem.zeroes([4]u8);
                kc[0] = @intCast(@divTrunc(j, 10) + '0');
                kc[1] = @intCast(@rem(j, 10) + '0');
                kc[2] = 0;
                shiftF = (i == 1);
                shiftG = (i == 2);
                assignToKey(&kc);
                return true;
            }
        }
    }
    return false;
}
const FLAG_USER: i32 = 32788;

// ===========================================================================
// assignGetName2
// ===========================================================================
pub export fn assignGetName2() callconv(.c) void {
    var result: bool_t = false;
    if (compareString(aimBuffer, "ENTER", CMP_NAME) == 0) {
        result = _assignToKey(ITM_ENTER);
    } else if (compareString(aimBuffer, "EXIT", CMP_NAME) == 0) {
        result = _assignToKey(ITM_EXIT1);
    } else if (compareString(aimBuffer, "USER", CMP_NAME) == 0) {
        result = _assignToKey(ITM_USERMODE);
    } else if (compareString(aimBuffer, "UP", CMP_NAME) == 0) {
        result = _assignToKey(ITM_UP1);
    } else if (compareString(aimBuffer, "DOWN", CMP_NAME) == 0) {
        result = _assignToKey(ITM_DOWN1);
    } else if (compareString(aimBuffer, "BKSPC", CMP_NAME) == 0) {
        result = _assignToKey(ITM_BACKSPACE);
    }
    calcMode = previousCalcMode;
    shiftF = false;
    shiftG = false;
    refreshScreen(23);

    if (!result) {
        displayCalcErrorMessage(ERROR_CANNOT_ASSIGN_HERE, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
        if (comptime extra_info) {
            if (comptime !dmcp_build) moreInfoOnError("In function assignGetName2:", aimBuffer, "is invalid name.", null);
        }
    }
}
