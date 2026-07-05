// SPDX-License-Identifier: GPL-3.0-only
const consts = abi.constants;
//
// Zig owner for src/c47/ui/tam.c: the TAM (Temporary Argument Mode) state machine.
// Faithful, line-by-line port of tamOperation, _tamMaxDigits, _tamUpdateBuffer,
// _tamHandleShuffle, _tamProcessInput, tamEnterMode, leaveTamModeIfEnabled and
// tamProcessInput, plus the three TO_QSPI operation tables (StoOperations,
// RclOperations, DelitmOperations) and the function-local static registerLookup
// table.
//
// IR_PRINTING is treated as never defined for any z47 build (matching the sibling
// owners), so the printTraceErrorFunction diagnostic blocks are omitted. The
// EXTRA_INFO_ON_CALC_ERROR console hints are compiled out on firmware (gated on
// extra_info && !dmcp_build). calcModeAim/Gui, calcModeNormalGui, calcModeTamGui
// and calcModeAimGui are no-op macros on firmware and real externs on host, gated
// on !dmcp_build. The PC_BUILD-only forceTamAlpha block and the printf("tam.value")
// trace are host-only. The operation tables are pure int16 -> code_section.
//
// tam.c is not reachable from the testSuite; verification is build/link across
// every target plus the boundary gates.

const std = @import("std");
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

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const bool_t = bool;
const calcRegister_t = i16;
const abi = @import("abi"); // L1 shared bindings (REPORT-23 §5)
const real34_t = abi.Real34;
const softmenu_t = abi.Softmenu;
const softmenuStack_t = abi.SoftmenuStack;
const item_t = abi.Item;
const labelList_t = abi.LabelList;
const programList_t = abi.ProgramList;
const registerHeader_t = abi.RegisterHeader;
const reservedVariableHeader_t = abi.ReservedVariableHeader;
// subroutineLevelHeader_t: numberOfLocalRegisters is at byte offset 5.
const subroutineLevelHeader_t = abi.SubroutineLevelHeader;
const tamState_t = abi.TamState;

const SOFTMENU_STACK_SIZE: usize = 8;

// ---------------------------------------------------------------------------
// Constants (probed from c47.h)
// ---------------------------------------------------------------------------
const AIM_BUFFER_LENGTH = 1024;
const CAPS_STOetc_DEFAULT = 1;
const CAPS_TAMother_DEFAULT = 0;
const CATALOG_MVAR = 18;
const CATALOG_NONE = 0;
const CAT_FNCT = 16;
const CAT_STATUS = 240;
const CM_AIM = 1;
const CM_ASSIGN = 4;
const CM_EIM = 13;
const CM_MIM = 12;
const CM_NIM = 2;
const CM_NORMAL = 0;
const CM_PEM = 3;
const CM_TIMER = 14;
const ERROR_FUNCTION_NOT_FOUND = 7;
const ERROR_LABEL_NOT_FOUND = 6;
const ERROR_UNDEF_MENU = 59;
const ERROR_UNDEF_SOURCE_VAR = 36;
const ERR_REGISTER_LINE = 102;
const FAILED_INDIRECTION = 9999;
const FIRST_LABEL = 2200;
const FIRST_LC_LOCAL_LABEL = 112;
const FIRST_LETTERED_REGISTER = 100;
const FIRST_LOCAL_FLAG = 112;
const FIRST_LOCAL_REGISTER = 7000;
const FIRST_NAMED_RESERVED_VARIABLE = 2026;
const FIRST_RESERVED_VARIABLE = 2000;
const FIRST_UC_LOCAL_LABEL = 100;
const FLAG_ALPHA = 32782;
const FLAG_IGN1ER = 32804;
const FLAG_M = 211;
const FLAG_W = 224;
const INVALID_MENU = 2791;
const INVALID_VARIABLE = 2199;
const ITM_0 = 540;
const ITM_0P = 988;
const ITM_1P = 989;
const ITM_9 = 549;
const ITM_ADD = 95;
const ITM_ASSIGN = 1411;
const ITM_AVIEW = 2018;
const ITM_BACK = 1412;
const ITM_BACKSPACE = 1738;
const ITM_BCD = 1985;
const ITM_BST = 1734;
const ITM_CARRY = 1851;
const ITM_CB_LEADING_ZERO = 1857;
const ITM_CNORM = 2706;
const ITM_Config = 2656;
const ITM_DELITM = 1455;
const ITM_DELITM_MENU = 1572;
const ITM_DELITM_PROG = 1571;
const ITM_DELP = 1425;
const ITM_DENMAX2 = 2551;
const ITM_DIV = 99;
const ITM_END = 1458;
const ITM_ENORM = 1461;
const ITM_ENTER = 35;
const ITM_FP = 94;
const ITM_GTO = 2;
const ITM_GTOP = 1482;
const ITM_HASH_JM = 1872;
const ITM_INDEX = 1486;
const ITM_INDIRECTION = 539;
const ITM_INFINITY = 924;
const ITM_IP = 93;
const ITM_KEYX = 1499;
const ITM_42STRING = 2775; // items.h:2880
const ITM_42APPEND = 2776; // items.h:2881
const ITM_42KEYG = 2795; // items.h:2900
const ITM_42KEYX = 2796; // items.h:2901
const ITM_LBL = 1;
const ITM_LBLQ = 1503;
const ITM_MULT = 98;
const ITM_MVAR = 1524;
const ITM_M_GOTO_COLUMN = 993;
const ITM_M_GOTO_ROW = 992;
const ITM_Max = 2654;
const ITM_Min = 2655;
const ITM_NNZ = 2705;
const ITM_OVERFLOW = 1852;
const ITM_PERIOD = 820;
const ITM_PNORM = 2704;
const ITM_RCL = 51;
const ITM_RCLADD = 52;
const ITM_RCLCFG = 1561;
const ITM_RCLDIV = 55;
const ITM_RCLEL = 1562;
const ITM_RCLIJ = 1563;
const ITM_RCLMAX = 1432;
const ITM_RCLMIN = 1462;
const ITM_RCLMULT = 54;
const ITM_RCLS = 1564;
const ITM_RCLSUB = 53;
const ITM_RCLVEL = 2728;
const ITM_RCLVEL1 = 2482;
const ITM_RCLVEL2 = 2483;
const ITM_RCLVEL3 = 2484;
const ITM_REG_B = 532;
const ITM_REG_D = 534;
const ITM_REG_F = 2343;
const ITM_REG_H = 2345;
const ITM_REG_I = 536;
const ITM_REG_O = 2346;
const ITM_REG_T = 530;
const ITM_REG_X = 527;
const ITM_REG_Y = 528;
const ITM_REG_Z = 529;
const ITM_RNORM = 1574;
const ITM_SKIP = 1603;
const ITM_SOLVE = 1608;
const ITM_STO = 44;
const ITM_STOADD = 45;
const ITM_STOCFG = 1611;
const ITM_STODIV = 48;
const ITM_STOEL = 1612;
const ITM_STOIJ = 1613;
const ITM_STOMAX = 1430;
const ITM_STOMIN = 1545;
const ITM_STOMULT = 47;
const ITM_STOS = 1615;
const ITM_STOSUB = 46;
const ITM_STOVEL = 2729;
const ITM_STOVEL1 = 2485;
const ITM_STOVEL2 = 2486;
const ITM_STOVEL3 = 2487;
const ITM_SUB = 96;
const ITM_Stack = 2657;
const ITM_TOPHEX = 2008;
const ITM_USERMODE = 1729;
const ITM_VIEW = 101;
const ITM_XEQ = 3;
const ITM_XEQP1 = 2223;
const ITM_a = 576;
const ITM_alpha = 628;
const ITM_dddEL = 2652;
const ITM_dddIJ = 2653;
const ITM_dddIX = 2651;
const ITM_dddVEL = 2650;
const ITM_dddVEL1 = 2647;
const ITM_dddVEL2 = 2648;
const ITM_dddVEL3 = 2649;
const ITM_l = 587;
const ITM_toINT = 1687;
const LAST_ITEM = 2860;
const LAST_RESERVED_VARIABLE = 2047;
const MNU_AMORT = 2382;
const MNU_DYNAMIC = 1394;
const MNU_MENU = 2407;
const MNU_MENUS = 1345;
const MNU_MVAR = 1398;
const MNU_PROGS = 1355;
const MNU_TAM = 1385;
const MNU_TAMALPHA = 1913;
const MNU_TAMCMP = 1386;
const MNU_TAMFLAG = 1390;
const MNU_TAMINDIRECT = 2108;
const MNU_TAMLABEL = 1393;
const MNU_TAMLBLONLY = 2226;
const MNU_TAMMENU = 2406;
const MNU_TAMNONREG = 2068;
const MNU_TAMNONREGMAX = 2109;
const MNU_TAMNONREGTRK = 2238;
const MNU_TAMNORM = 2711;
const MNU_TAMRCL = 1912;
const MNU_TAMRCL_TVM = 2639;
const MNU_TAMSHUFFLE = 1391;
const MNU_TAMSTO = 1387;
const MNU_TAMSTO_TVM = 2638;
const MNU_TAMVARONLY = 2225;
const MNU_TVM = 1368;
const NOPARAM = 9876;
const NUMBER_OF_LOCAL_FLAGS = 32;
const PTP_DECLARE_LABEL = 512;
const PTP_SKIP_BACK = 4608;
const PTP_STATUS = 7680;
const REGISTER_A = 104;
const REGISTER_B = 105;
const REGISTER_C = 106;
const REGISTER_D = 107;
const REGISTER_E = 118;
const REGISTER_F = 119;
const REGISTER_G = 120;
const REGISTER_H = 121;
const REGISTER_I = 109;
const REGISTER_J = 110;
const REGISTER_K = 111;
const REGISTER_L = 108;
const REGISTER_M = 112;
const REGISTER_N = 113;
const REGISTER_O = 122;
const REGISTER_P = 114;
const REGISTER_Q = 115;
const REGISTER_R = 116;
const REGISTER_S = 117;
const REGISTER_T = 103;
const REGISTER_U = 123;
const REGISTER_V = 124;
const REGISTER_W = 125;
const REGISTER_X = 100;
const REGISTER_Y = 101;
const REGISTER_Z = 102;
const SCRUPD_AUTO = 0;
const SCRUPD_MANUAL_MENU = 4;
const SCRUPD_MANUAL_STACK = 2;
const SCRUPD_MANUAL_STATUSBAR = 1;
const SCRUPD_SKIP_STACK_ONE_TIME = 32;
const TAM_MAX_BITS = 14;
const TAM_MAX_MASK = 16383;
const TEMP_REGISTER_1 = 135;
const TM_CMP = 10022; // defines.h: 10022 (matches comparison items' .param=10022); was 10021 (=TM_STRING) -> interactive comparisons broke
const TM_DELITM = 10014;
const TM_FLAGR = 10004;
const TM_FLAGW = 10005;
const TM_KEY = 10012;
const TM_LABEL = 10009;
const TM_LBLONLY = 10018;
const TM_MENU = 10017;
const TM_M_DIM = 10007;
const TM_NEWMENU = 10011;
const TM_REGISTER = 10003;
const TM_SHUFFLE = 10008;
const TM_SOLVE = 10010;
const TM_STORCL = 10006;
const TM_STRING = 10021; // defines.h:1697
const TM_VALUE = 10001;
const TM_VALUE_CHB = 10002;
const TM_VALUE_MAX = 10015;
const TM_VALUE_NORM = 10020;
const TM_VALUE_TRK = 10016;
const TM_VARONLY = 10019;
const USER_C47 = 46;
const amNone = 5;
const bugMsgValueFor = 0;
const dtReal34 = 1;
const pNorm_0_NNZ = 0;
const pNorm_1_CNORM = 1;
const pNorm_2_ENORM = 2;
const pNorm_inf_RNORM = 924;

// USER_R47* for isR47FAM (USER_C47 comes from the probed const block above).
const USER_R47f_g: u8 = 61;
const USER_R47bk_fg: u8 = 62;
const USER_R47fg_bk: u8 = 63;
const USER_R47fg_g: u8 = 64;

// ---------------------------------------------------------------------------
// constants blob (const34_0 / const34_1 by byte offset)
// ---------------------------------------------------------------------------
const const34_0 = consts.q16200();
const const34_1 = consts.q16312();

// ---------------------------------------------------------------------------
// Globals (extern var/const)
// ---------------------------------------------------------------------------
extern var calcMode: u8;
extern var lastErrorCode: u8;
extern var lastIntegerBase: u32;
extern var hourGlassIconEnabled: bool_t;
extern var alphaCase: u8;
extern var alphaCursor: i16;
extern var aimBuffer: [*c]u8;
extern var tmpString: [*c]u8;
extern var tamBuffer: [*c]u8;
extern var errorMessage: [*c]u8;
extern var numberOfTamMenusToPop: i16;
extern var dynamicMenuItem: i16;
extern var catalog: i16;
extern var calcModel: u8;
extern var screenUpdatingMode: u8;
extern var currentLocalStepNumber: u16;
extern var currentProgramNumber: u16;
extern var numberOfPrograms: u16;
extern var pemCursorIsZerothStep: bool_t;
extern var programListEnd: bool_t;
extern var currentStep: [*c]u8;
extern var firstFreeProgramByte: [*c]u8;
extern var programList: [*c]programList_t;
extern var labelList: [*c]labelList_t;
const allReservedVariables = @extern([*c]const reservedVariableHeader_t, .{ .name = "allReservedVariables" });
// indexOfItems is a C ARRAY (const item_t indexOfItems[]); bind its address
// with @extern, not a pointer-typed extern (which would deref the data as an
// address -> SEGV).
const indexOfItems = @extern([*c]const item_t, .{ .name = "indexOfItems" });
const softmenu = @extern([*c]const softmenu_t, .{ .name = "softmenu" });
extern var softmenuStack: [SOFTMENU_STACK_SIZE]softmenuStack_t;
extern var currentSubroutineLevelData: [*c]subroutineLevelHeader_t;
extern var currentLocalFlags: ?*anyopaque;
extern var tam: tamState_t;

// PC_BUILD-only.
extern var forceTamAlpha: bool_t;

// STD_* byte sequences.
const STD_RIGHT_ARROW = "\xa1\x92";
const STD_LEFT_SINGLE_QUOTE = "\xa0\x18";
const STD_RIGHT_SINGLE_QUOTE = "\xa0\x19";
const STD_CURSOR = "\xa4\x27";

// ---------------------------------------------------------------------------
// Function externs (linkable everywhere)
// ---------------------------------------------------------------------------
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
extern fn strcpy(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strlen(s: [*c]const u8) usize;
extern fn strchr(s: [*c]const u8, c: c_int) [*c]u8;
extern fn sprintf(buf: [*c]u8, fmt: [*:0]const u8, ...) c_int;
extern fn printf(fmt: [*:0]const u8, ...) c_int;

extern fn compareString(stra: [*c]const u8, strb: [*c]const u8, comparisonType: i32) i32;
extern fn stringGlyphLength(str: [*c]const u8) i32;
extern fn xcopy(dest: ?*anyopaque, source: ?*const anyopaque, n: u32) ?*anyopaque;
extern fn displayCalcErrorMessage(errorCode: u8, errMessageRegisterLine: i16, errRegisterLine: i16) void;
extern fn displayBugScreen(msg: [*c]const u8) void;
extern fn moreInfoOnError(m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) void;
extern fn showSoftmenu(id: i16) void;
extern fn popSoftmenu() void;
extern fn setSystemFlag(sf: c_uint) void;
extern fn clearSystemFlag(sf: c_uint) void;
extern fn getSystemFlag(sf: i32) bool_t;
extern fn currentMenu() i16;
extern fn menu(n: u8) i16;
extern fn insertAlphaCursor(startAt: u16) void;
extern fn deleteAlphaCharacter(currentCursor: *i16) void;
extern fn addItemToNimBuffer(item: i16) void;
extern fn closeNim() void;
extern fn pemCloseAlphaInput() void;
extern fn pemCloseNumberInput() void;
extern fn refreshRegisterLine(regist: calcRegister_t) void;
extern fn scanLabelsAndPrograms() void;
extern fn insertStepInProgram(func: i16) void;
extern fn findPreviousStep(step: [*c]u8) [*c]u8;
extern fn scrollPemBackwards() void;
extern fn scrollPemForwards() void;
extern fn resetShiftState() void;
extern fn saveForUndo() void;
extern fn getNumberOfSteps() u16;
extern fn addStepInProgram(func: i16) void;
extern fn reallyRunFunction(func: i16, param: u16) void;
extern fn runFunction(func: i16) void;
extern fn mimRunFunction(func: i16, param: u16) void;
extern fn indirectAddressing(regist: calcRegister_t, parameterType: u16, minValue: i16, maxValue: i16, tryAllocate: bool_t) i16;
extern fn indirectionType(func: u16) u16;
extern fn isFunctionAllowingNewVariable(op: u16) bool_t;
extern fn isFunctionOldParam16(func: u16) bool_t;
extern fn findNamedLabelWithDuplicate(labelName: [*c]const u8, dupNum: i16) i16;
extern fn findNamedVariable(variableName: [*c]const u8) i16;
extern fn findOrAllocateNamedVariable(variableName: [*c]const u8) i16;
extern fn findMenu(buffer: [*c]u8) i16;
extern fn dynmenuGetLabelWithDup(menuitem: i16, dupNum: *i16) [*c]u8;
extern fn fnGoto(label: u16) void;
extern fn goToPgmStep(program: u16, step: u16) void;
extern fn goToGlobalStep(step: i32) void;
extern fn clearTamBuffer() void;
extern fn reallocateRegister(regist: calcRegister_t, dataType: u32, dataSizeWithoutDataLenBlocks: u16, tag: u32) void;
extern fn getRegisterDataPointer(regist: calcRegister_t) *anyopaque;
extern fn assignLeaveAlpha() void;
extern fn assignGetName1() void;
extern fn assignGetName2() void;
extern fn calcModeAim(unusedButMandatoryParameter: u16) void;
extern fn fnJM_2SI(unusedButMandatoryParameter: u16) void;
extern fn fnLint(unusedButMandatoryParameter: u16) void;
extern fn fnFp(unusedButMandatoryParameter: u16) void;
extern fn fnIp(unusedButMandatoryParameter: u16) void;
extern fn fnToReal(unusedButMandatoryParameter: u16) void;

// host-only GUI (no-op macros on firmware).
extern fn calcModeNormalGui() void;
extern fn calcModeTamGui() void;
extern fn calcModeAimGui() void;

// stringCopy = stpcpy (non-MINGW64).
inline fn stringCopy(dest: [*c]u8, source: [*c]const u8) [*c]u8 {
    return stpcpy(dest, source);
}
inline fn stringByteLength(s: [*c]const u8) i32 {
    return @intCast(strlen(s));
}
inline fn maxI(a: i32, b: i32) i32 {
    return if (a > b) a else b;
}
// real34Copy(src,dst): two 8-byte copies.
inline fn real34Copy(src: *align(1) const real34_t, dst: *real34_t) void {
    dst.* = src.*;
}
const reg34 = abi.registerReal34;
// REGISTER_STRING_DATA(a): char* at getRegisterDataPointer(a)+sizeof(strLgIntHeader_t) (=4).
const regStringData = abi.registerString;
inline fn currentNumberOfLocalRegisters() u8 {
    return currentSubroutineLevelData.*.numberOfLocalRegisters;
}
inline fn isR47FAM() bool {
    return calcModel == USER_R47f_g or calcModel == USER_R47bk_fg or calcModel == USER_R47fg_bk or calcModel == USER_R47fg_g;
}
inline fn moreInfoErr(where: [*:0]const u8, m2: [*:0]const u8, m3: ?[*:0]const u8) void {
    if (comptime extra_info) {
        if (comptime !dmcp_build) moreInfoOnError(where, m2, m3, null);
    }
}

// ---------------------------------------------------------------------------
// Operation tables (TO_QSPI const int16_t[][2]).
// ---------------------------------------------------------------------------
const StoOperations linksection(code_section) = [_][2]i16{
    .{ ITM_ADD, ITM_STOADD },
    .{ ITM_SUB, ITM_STOSUB },
    .{ ITM_MULT, ITM_STOMULT },
    .{ ITM_DIV, ITM_STODIV },
    .{ ITM_Max, ITM_STOMAX },
    .{ ITM_Min, ITM_STOMIN },
    .{ ITM_Config, ITM_STOCFG },
    .{ ITM_Stack, ITM_STOS },
    .{ ITM_dddEL, ITM_STOEL },
    .{ ITM_dddIJ, ITM_STOIJ },
    .{ ITM_dddVEL, ITM_STOVEL },
    .{ ITM_dddVEL1, ITM_STOVEL1 },
    .{ ITM_dddVEL2, ITM_STOVEL2 },
    .{ ITM_dddVEL3, ITM_STOVEL3 },
    .{ ITM_dddIX, ITM_INDEX },
};
const RclOperations linksection(code_section) = [_][2]i16{
    .{ ITM_ADD, ITM_RCLADD },
    .{ ITM_SUB, ITM_RCLSUB },
    .{ ITM_MULT, ITM_RCLMULT },
    .{ ITM_DIV, ITM_RCLDIV },
    .{ ITM_Max, ITM_RCLMAX },
    .{ ITM_Min, ITM_RCLMIN },
    .{ ITM_Config, ITM_RCLCFG },
    .{ ITM_Stack, ITM_RCLS },
    .{ ITM_dddEL, ITM_RCLEL },
    .{ ITM_dddIJ, ITM_RCLIJ },
    .{ ITM_dddVEL1, ITM_RCLVEL1 },
    .{ ITM_dddVEL2, ITM_RCLVEL2 },
    .{ ITM_dddVEL3, ITM_RCLVEL3 },
    .{ ITM_dddVEL, ITM_RCLVEL },
};
const DelitmOperations linksection(code_section) = [_][2]i16{
    .{ MNU_PROGS, ITM_DELITM_PROG },
    .{ MNU_MENUS, ITM_DELITM_MENU },
};

// ===========================================================================
// tamOperation
// ===========================================================================
pub export fn tamOperation() callconv(.c) i16 {
    switch (tam.function) {
        ITM_STO => {
            var i: usize = 0;
            while (i < StoOperations.len) : (i += 1) {
                if (tam.currentOperation == StoOperations[i][0]) {
                    return StoOperations[i][1];
                }
            }
            return ITM_STO;
        },
        ITM_RCL => {
            var i: usize = 0;
            while (i < RclOperations.len) : (i += 1) {
                if (tam.currentOperation == RclOperations[i][0]) {
                    return RclOperations[i][1];
                }
            }
            return ITM_RCL;
        },
        ITM_DELITM => {
            const m: i16 = -softmenu[@intCast(softmenuStack[0].softmenuId)].menuItem;
            var i: usize = 0;
            while (i < DelitmOperations.len) : (i += 1) {
                if (m == DelitmOperations[i][0]) {
                    return DelitmOperations[i][1];
                }
            }
            return ITM_DELITM;
        },
        else => {
            return tam.function;
        },
    }
}

// ===========================================================================
// _tamMaxDigits (static)
// ===========================================================================
fn _tamMaxDigits(max: i16) u8 {
    if (tam.function == ITM_GTOP) {
        return if (max < 1000) 3 else if (max < 10000) 4 else 5;
    } else {
        return if (max < 10) 1 else if (max < 100) 2 else if (max < 1000) 3 else if (max < 10000) 4 else 5;
    }
}

// ===========================================================================
// _tamUpdateBuffer (static)
// ===========================================================================
fn _tamUpdateBuffer() void {
    var regists: [5]u8 = undefined;
    var tbPtr: [*c]u8 = tamBuffer;
    if (tam.mode == 0) {
        return;
    }

    if (tam.mode == TM_KEY) {
        if (tam.function == ITM_42KEYG or tam.function == ITM_42KEYX) {
            tbPtr = stringCopy(tbPtr, " 42KEY ");
        } else {
            tbPtr = stringCopy(tbPtr, "KEY ");
        }
        if (tam.keyInputFinished) {
            if (tam.keyIndirect) {
                tbPtr = stringCopy(tbPtr, STD_RIGHT_ARROW);
            }
            if (tam.keyDot) {
                tbPtr = stringCopy(tbPtr, ".");
            }
            if (tam.keyAlpha) {
                tbPtr = stringCopy(tbPtr, STD_LEFT_SINGLE_QUOTE);
                tbPtr = stringCopy(tbPtr, aimBuffer + AIM_BUFFER_LENGTH / 2);
                tbPtr = stringCopy(tbPtr, STD_RIGHT_SINGLE_QUOTE);
            } else {
                var v: i16 = tam.key;
                var i: i32 = 1;
                while (i >= 0) : (i -= 1) {
                    tbPtr[@intCast(i)] = @intCast('0' + @rem(v, 10));
                    v = @divTrunc(v, 10);
                }
                tbPtr += 2;
            }
            if (tam.function == ITM_KEYX or tam.function == ITM_42KEYX) {
                tbPtr = stringCopy(tbPtr, " XEQ ");
            } else {
                tbPtr = stringCopy(tbPtr, " GTO ");
            }
        }
    } else {
        tbPtr = stringCopy(tbPtr, &indexOfItems[@intCast(tamOperation())].itemCatalogName);
        tbPtr = stringCopy(tbPtr, " ");
    }

    if (tam.mode == TM_SHUFFLE) {
        regists[4] = 0;
        var i: u4 = 0;
        while (i < 4) : (i += 1) {
            if ((tam.value >> @intCast(i * 2 + 8)) & 1 != 0) {
                const regNum: u8 = @intCast((tam.value >> @intCast(i * 2)) & 3);
                regists[i] = if (regNum == 3) 't' else 'x' + regNum;
            } else {
                regists[i] = '_';
            }
        }
        tbPtr = stringCopy(tbPtr, &regists);
    } else {
        if (tam.indirect) {
            tbPtr = stringCopy(tbPtr, STD_RIGHT_ARROW);
        }
        if (tam.dot) {
            tbPtr = stringCopy(tbPtr, ".");
        }
        if (tam.alpha) {
            tbPtr = stringCopy(tbPtr, STD_LEFT_SINGLE_QUOTE);
            if (aimBuffer[0] == 0) {
                tbPtr[0] = STD_CURSOR[0];
                tbPtr += 1;
                tbPtr[0] = STD_CURSOR[1];
                tbPtr += 1;
                tbPtr[0] = 0;
            } else {
                insertAlphaCursor(0);
                tbPtr = stringCopy(tbPtr, tmpString);
                tbPtr = stringCopy(tbPtr, STD_RIGHT_SINGLE_QUOTE);
            }
        } else {
            const max: i16 = if (tam.indirect)
                (if (tam.dot) (if (calcMode == CM_PEM) @as(i16, 98) else @as(i16, @intCast(currentNumberOfLocalRegisters())) - 1) else @as(i16, 99))
            else
                (if (tam.dot) (if (calcMode == CM_PEM) @as(i16, 98) else (if (tam.mode == TM_FLAGR or tam.mode == TM_FLAGW) NUMBER_OF_LOCAL_FLAGS - 1 else @as(i16, @intCast(currentNumberOfLocalRegisters())) - 1)) else tam.max);
            const maxDigits: u8 = _tamMaxDigits(max);
            const underscores: u8 = maxDigits -% @as(u8, @intCast(tam.digitsSoFar));
            var v: i16 = tam.value;
            var i: i32 = @as(i32, tam.digitsSoFar) - 1;
            while (i >= 0) : (i -= 1) {
                tbPtr[@intCast(i)] = @intCast('0' + @rem(v, 10));
                v = @divTrunc(v, 10);
            }
            tbPtr += @intCast(tam.digitsSoFar);
            var k: u8 = 0;
            while (k < underscores) : (k += 1) {
                tbPtr[0] = '_';
                tbPtr += 1;
            }
        }
    }

    tbPtr[0] = 0;
}

// ===========================================================================
// _tamHandleShuffle (static)
// ===========================================================================
fn _tamHandleShuffle(item: u16) void {
    switch (item) {
        @as(u16, ITM_REG_X), @as(u16, ITM_REG_Y), @as(u16, ITM_REG_Z), @as(u16, ITM_REG_T) => {
            var i: u4 = 0;
            while (i < 4) : (i += 1) {
                if (!(((tam.value >> @intCast(2 * @as(u5, i) + 8)) & 1) != 0)) {
                    const mask: u16 = @as(u16, 3) << @intCast(2 * @as(u5, i));
                    tam.value |= @as(i16, @bitCast(@as(u16, 1) << @intCast(2 * @as(u5, i) + 8)));
                    tam.value = @bitCast((@as(u16, @bitCast(tam.value)) & ~mask) | ((@as(u16, @bitCast(@as(i16, @bitCast(item)) -% ITM_REG_X)) << @intCast(2 * @as(u5, i))) & mask));
                    if (i == 3) {
                        if (calcMode == CM_PEM) {
                            addStepInProgram(tamOperation());
                        } else {
                            reallyRunFunction(tamOperation(), @bitCast(tam.value));
                        }
                        leaveTamModeIfEnabled();
                    }
                    break;
                }
            }
        },
        @as(u16, ITM_BACKSPACE) => {
            var i: i32 = 3;
            while (i >= 0) : (i -= 1) {
                if ((tam.value >> @intCast(2 * i + 8)) & 1 != 0) {
                    tam.value &= ~(@as(i16, @bitCast(@as(u16, 1) << @intCast(2 * i + 8))));
                    break;
                } else if (i == 0) {
                    leaveTamModeIfEnabled();
                    scrollPemBackwards();
                    break;
                }
            }
        },
        else => {},
    }
}

// registerLookup (function-static in C; module-level TO_QSPI here).
// Indexed by (param - FIRST_LETTERED_REGISTER); {char, ALPHA_LABEL(1)/LOCAL_LABEL(0)}.
const LOCAL_LABEL: i16 = 0;
const ALPHA_LABEL: i16 = 1;
const registerLookup linksection(code_section) = [_][2]i16{
    .{ 88, 1 },
    .{ 89, 1 },
    .{ 90, 1 },
    .{ 84, 1 },
    .{ 65, 0 },
    .{ 66, 0 },
    .{ 67, 0 },
    .{ 68, 0 },
    .{ 76, 0 },
    .{ 73, 0 },
    .{ 74, 0 },
    .{ 75, 0 },
    .{ 77, 1 },
    .{ 78, 1 },
    .{ 80, 1 },
    .{ 81, 1 },
    .{ 82, 1 },
    .{ 83, 1 },
    .{ 69, 0 },
    .{ 70, 0 },
    .{ 71, 0 },
    .{ 72, 0 },
    .{ 79, 1 },
    .{ 85, 1 },
    .{ 86, 1 },
    .{ 87, 1 },
};

// ===========================================================================
// _tamProcessInput (static)
// ===========================================================================
fn _tamProcessInput(item: u16) void {
    var min: i16 = undefined;
    var max: i16 = undefined;
    var min2: i16 = undefined;
    var max2: i16 = undefined;
    var dupNum: i16 = undefined;
    var forceTry: bool_t = false;
    var tryOoR: bool_t = false;
    const valueParameter: bool_t = (tam.function == ITM_GTOP or isFunctionOldParam16(@bitCast(tam.function)) or tam.function == ITM_SKIP or tam.function == ITM_BACK);
    var forcedVar: [*c]u8 = null;

    // Shuffle is handled completely differently to everything else
    if (tam.mode == TM_SHUFFLE) {
        _tamHandleShuffle(item);
        return;
    }

    min = if (tam.dot) 0 else tam.min;
    max = if (tam.dot) (if (tam.mode == TM_FLAGR or tam.mode == TM_FLAGW) NUMBER_OF_LOCAL_FLAGS - 1 else (if (calcMode == CM_PEM) @as(i16, 98) else @as(i16, @intCast(currentNumberOfLocalRegisters())) - 1)) else tam.max;
    min2 = if (tam.indirect) 0 else min;
    max2 = if (tam.indirect) (if (tam.dot) (if (calcMode == CM_PEM) @as(i16, 98) else @as(i16, @intCast(currentNumberOfLocalRegisters())) - 1) else @as(i16, 99)) else max;
    dupNum = 0;
    const itm: i16 = @bitCast(item);

    if ((item == ITM_ENTER and !(tam.function == ITM_toINT or tam.function == ITM_HASH_JM)) or (tam.alpha and stringGlyphLength(aimBuffer) > (if (tam.mode == TM_MENU) @as(i32, 8) else if (tam.mode == TM_STRING) (if (tam.function == ITM_42STRING) @as(i32, 14) else @as(i32, 13)) else @as(i32, 6)))) {
        forceTry = true;
        if (tam.alpha and calcMode == CM_ASSIGN) {
            assignLeaveAlpha();
            if (itemToBeAssigned == 0) {
                assignGetName1();
            } else {
                assignGetName2();
            }
            return;
        }
    } else if (tam.mode == TM_VALUE and currentMenu() == -MNU_TAMNORM and (item == ITM_NNZ or item == ITM_CNORM or item == ITM_RNORM or item == ITM_ENORM or item == ITM_INFINITY)) {
        switch (item) {
            ITM_NNZ => {
                tam.value = pNorm_0_NNZ;
                forceTry = true;
            },
            ITM_CNORM => {
                tam.value = pNorm_1_CNORM;
                forceTry = true;
            },
            ITM_ENORM => {
                tam.value = pNorm_2_ENORM;
                forceTry = true;
            },
            ITM_RNORM => {
                tam.value = pNorm_inf_RNORM;
                forceTry = true;
            },
            ITM_INFINITY => {
                tam.value = pNorm_inf_RNORM;
                forceTry = true;
            },
            else => {},
        }
    } else if (item == ITM_BACKSPACE) {
        if (tam.alpha) {
            if (stringByteLength(aimBuffer) != 0) {
                if (alphaCursor > 0) {
                    deleteAlphaCharacter(&alphaCursor);
                }
            } else if (tam.mode == TM_NEWMENU) {
                leaveTamModeIfEnabled();
                runFunction(ITM_ASSIGN);
            } else {
                tam.alpha = false;
                clearSystemFlag(FLAG_ALPHA);
                popSoftmenu();
                numberOfTamMenusToPop -= 1;
                if (menu(0) == -MNU_TAMALPHA) {
                    popSoftmenu();
                    numberOfTamMenusToPop -= 1;
                }
                if (calcMode == CM_ASSIGN) {
                    leaveTamModeIfEnabled();
                    if (comptime !dmcp_build) calcModeNormalGui();
                } else if (tam.mode == TM_STRING) {
                    leaveTamModeIfEnabled();
                    scrollPemBackwards();
                } else {
                    if (comptime !dmcp_build) calcModeTamGui();
                }
            }
        } else if (tam.digitsSoFar > 0) {
            if (tam.function == ITM_GTOP and tam.digitsSoFar == 3) {
                tam.max = @intCast(maxI(getNumberOfSteps(), 99));
                max2 = tam.max;
            }
            tam.digitsSoFar -= 1;
            if (tam.digitsSoFar != 0) {
                tam.value = @divTrunc(tam.value, 10);
            } else {
                tam.value = 0;
            }
        } else if (tam.function == ITM_GTOP) {
            tam.function = ITM_GTO;
            tam.min = @bitCast(indexOfItems[@intCast(ITM_GTO)].tamMinMax >> TAM_MAX_BITS);
            tam.max = @bitCast(indexOfItems[@intCast(ITM_GTO)].tamMinMax & TAM_MAX_MASK);
        } else if (tam.dot) {
            tam.dot = false;
        } else if (tam.indirect) {
            tam.indirect = false;
            popSoftmenu();
            if (tam.mode == TM_VALUE or tam.mode == TM_VALUE_CHB) {
                if (tam.function == ITM_DENMAX2) {
                    showSoftmenu(-MNU_TAMNONREGMAX);
                } else if (tam.function == ITM_PNORM) {
                    showSoftmenu(-MNU_TAMNORM);
                } else {
                    showSoftmenu(-MNU_TAMNONREG);
                }
            } else if (tam.mode == TM_REGISTER or tam.mode == TM_M_DIM) {
                showSoftmenu(-MNU_TAM);
            } else if (tam.mode == TM_VARONLY) {
                showSoftmenu(-MNU_TAMVARONLY);
            } else if (tam.mode == TM_FLAGR or tam.mode == TM_FLAGW) {
                showSoftmenu(-MNU_TAMFLAG);
            } else if (tam.mode == TM_STORCL) {
                showSoftmenu(if (item == ITM_STO) (if (currentMenu() == -MNU_TVM) -MNU_TAMSTO_TVM else -MNU_TAMSTO) else (if (currentMenu() == -MNU_TVM or currentMenu() == -MNU_AMORT) -MNU_TAMRCL_TVM else -MNU_TAMRCL));
            } else if (tam.mode == TM_LABEL or (tam.mode == TM_KEY and tam.keyInputFinished)) {
                showSoftmenu(-MNU_TAMLABEL);
            } else if (tam.mode == TM_LBLONLY or (tam.mode == TM_KEY and tam.keyInputFinished)) {
                showSoftmenu(-MNU_TAMLBLONLY);
            } else if (tam.mode == TM_SOLVE) {
                if (tam.function == ITM_SOLVE and calcMode == CM_PEM) {
                    showSoftmenu(-MNU_TAMVARONLY);
                } else {
                    showSoftmenu(-MNU_TAMLBLONLY);
                }
            } else if (tam.mode == TM_MENU) {
                showSoftmenu(-MNU_TAMMENU);
            } else if (tam.mode == TM_CMP) {
                showSoftmenu(-MNU_TAMCMP);
            }
            numberOfTamMenusToPop -= 1;
        } else if (tam.currentOperation != tam.function) {
            tam.currentOperation = tam.function;
        } else if (tam.mode == TM_KEY and tam.keyInputFinished) {
            tam.value = @divTrunc(tam.key, 10);
            tam.alpha = tam.keyAlpha;
            tam.dot = tam.keyDot;
            tam.indirect = tam.keyIndirect;
            tam.keyInputFinished = false;
            _ = xcopy(aimBuffer, aimBuffer + AIM_BUFFER_LENGTH / 2, 16);
            aimBuffer[0] = 0;
            tam.key = 0;
            tam.keyAlpha = false;
            tam.keyDot = false;
            tam.keyIndirect = false;
            tam.max = 21;
            tam.min = 1;
            tam.digitsSoFar = 1;
            popSoftmenu();
            showSoftmenu(-MNU_TAM);
            numberOfTamMenusToPop -= 1;
            if (tam.alpha) {
                setSystemFlag(FLAG_ALPHA);
                calcModeAim(NOPARAM);
            }
            if (comptime !dmcp_build) calcModeTamGui();
        } else {
            leaveTamModeIfEnabled();
            scrollPemBackwards();
            if (calcMode == CM_ASSIGN) {
                calcMode = CM_NORMAL;
            }
        }
        return;
    } else if (item == MNU_DYNAMIC) {
        forcedVar = dynmenuGetLabelWithDup(dynamicMenuItem, &dupNum);
        if (forcedVar[0] == 0) {
            forcedVar = null;
        }
        forceTry = true;
    } else if (tam.alpha) {
        return;
    } else if (!(tam.function == ITM_toINT or tam.function == ITM_HASH_JM) and item == ITM_alpha) {
        var allowAlphaMode: bool_t = false;
        var beginWithLowercase: bool_t = false;
        allowAlphaMode = allowAlphaMode or (tam.digitsSoFar == 0 and !tam.dot and !valueParameter and (tam.mode == TM_STORCL or tam.mode == TM_M_DIM or tam.mode == TM_REGISTER or tam.mode == TM_VARONLY or tam.mode == TM_CMP or tam.function == ITM_MVAR));
        allowAlphaMode = allowAlphaMode or (tam.digitsSoFar == 0 and !tam.dot and tam.indirect);
        allowAlphaMode = allowAlphaMode or (tam.digitsSoFar == 0 and !tam.dot and tam.mode == TM_SOLVE and calcMode == CM_PEM);
        beginWithLowercase = allowAlphaMode;
        allowAlphaMode = allowAlphaMode or (tam.digitsSoFar == 0 and !tam.dot and (tam.mode == TM_LABEL or tam.mode == TM_LBLONLY or tam.mode == TM_SOLVE or tam.mode == TM_MENU));
        allowAlphaMode = allowAlphaMode or (tam.digitsSoFar == 0 and !tam.dot and tam.keyInputFinished and tam.mode == TM_KEY);
        allowAlphaMode = allowAlphaMode or (tam.digitsSoFar == 0 and (tam.function == ITM_LBL or tam.function == ITM_GTOP));
        if (allowAlphaMode) {
            tam.alpha = true;
            setSystemFlag(FLAG_ALPHA);
            aimBuffer[0] = 0;
            alphaCursor = 0;
            calcModeAim(NOPARAM);
            if (beginWithLowercase) {
                alphaCase = CAPS_STOetc_DEFAULT;
            } else {
                alphaCase = CAPS_TAMother_DEFAULT;
            }
            switch (softmenu[@intCast(softmenuStack[0].softmenuId)].menuItem) {
                -MNU_TAMCMP, -MNU_TAMLABEL, -MNU_TAMLBLONLY, -MNU_TAM, -MNU_TAMVARONLY, -MNU_TAMSTO, -MNU_TAMRCL, -MNU_TAMSTO_TVM, -MNU_TAMRCL_TVM, -MNU_TAMMENU, -MNU_TAMINDIRECT => {
                    showSoftmenu(-MNU_TAMALPHA);
                    screenUpdatingMode = SCRUPD_AUTO;
                },
                else => {},
            }
        }
        return;
    } else if (tam.digitsSoFar == 0 and !tam.indirect and tam.mode == TM_FLAGW and (item == ITM_BCD or item == ITM_TOPHEX or item == ITM_CB_LEADING_ZERO or item == ITM_OVERFLOW or item == ITM_CARRY)) {
        if (tam.mode != 0) {
            leaveTamModeIfEnabled();
        }
        hourGlassIconEnabled = false;
        return;
    } else if (item == ITM_Max or item == ITM_Min or
        item == ITM_ADD or item == ITM_SUB or item == ITM_MULT or item == ITM_DIV or
        item == ITM_Config or item == ITM_Stack or item == ITM_dddEL or item == ITM_dddIJ or
        item == ITM_dddVEL or item == ITM_dddIX or (itm >= ITM_dddVEL1 and itm <= ITM_dddVEL3))
    {
        if (tam.digitsSoFar == 0 and !tam.indirect) {
            if (tam.function == ITM_GTO) {
                if (item == ITM_Max) {
                    if (currentLocalStepNumber == 1) {
                        if (currentProgramNumber == 1) {
                            leaveTamModeIfEnabled();
                            return;
                        } else {
                            tam.value = @intCast(programList[currentProgramNumber - 2].step);
                        }
                    } else {
                        tam.value = @intCast(programList[currentProgramNumber - 1].step);
                    }
                    reallyRunFunction(ITM_GTOP, @bitCast(tam.value));
                    pemCursorIsZerothStep = true;
                    leaveTamModeIfEnabled();
                    hourGlassIconEnabled = false;
                    return;
                }
                if (item == ITM_Min) {
                    if (currentProgramNumber == numberOfPrograms) {
                        tam.value = @intCast(programList[currentProgramNumber - 1].step);
                        reallyRunFunction(ITM_GTOP, @bitCast(tam.value));
                        reallyRunFunction(ITM_BST, NOPARAM);
                    } else {
                        tam.value = @intCast(programList[currentProgramNumber].step);
                        reallyRunFunction(ITM_GTOP, @bitCast(tam.value));
                        pemCursorIsZerothStep = true;
                    }
                    leaveTamModeIfEnabled();
                    hourGlassIconEnabled = false;
                    return;
                }
            } else if (tam.mode == TM_STORCL and tam.currentOperation != ITM_Config and tam.currentOperation != ITM_Stack) {
                if (itm == tam.currentOperation) {
                    tam.currentOperation = tam.function;
                } else if ((itm >= ITM_STOVEL1 and itm <= ITM_STOVEL3) or (itm >= ITM_RCLVEL1 and itm <= ITM_RCLVEL3)) {
                    tam.currentOperation = itm;
                    switch (calcMode) {
                        CM_MIM => {},
                        CM_PEM => {
                            addStepInProgram(itm);
                        },
                        else => {
                            runFunction(itm);
                        },
                    }
                    leaveTamModeIfEnabled();
                    hourGlassIconEnabled = false;
                    return;
                } else if (item == ITM_dddVEL or (itm >= ITM_dddVEL1 and itm <= ITM_dddVEL3) or item == ITM_dddIX) {
                    tam.currentOperation = itm;
                    if (calcMode != CM_MIM) {
                        leaveTamModeIfEnabled();
                        runFunction(tamOperation());
                    }
                    return;
                } else {
                    tam.currentOperation = itm;
                    if (item == ITM_dddEL or item == ITM_dddIJ) {
                        switch (calcMode) {
                            CM_MIM => {
                                mimRunFunction(tamOperation(), NOPARAM);
                            },
                            CM_PEM => {
                                addStepInProgram(tamOperation());
                            },
                            else => {
                                reallyRunFunction(tamOperation(), NOPARAM);
                            },
                        }
                        leaveTamModeIfEnabled();
                        hourGlassIconEnabled = false;
                        return;
                    }
                }
            }
        }
        return;
    } else if ((tam.function == ITM_toINT or tam.function == ITM_HASH_JM) and item == ITM_REG_I) {
        if (calcMode == CM_PEM) {
            addStepInProgram(ITM_IP);
        } else {
            saveForUndo();
            fnJM_2SI(NOPARAM);
            fnLint(NOPARAM);
        }
        leaveTamModeIfEnabled();
        return;
    } else if ((tam.function == ITM_toINT or tam.function == ITM_HASH_JM) and ((item == ITM_alpha and calcModel == USER_C47) or (item == ITM_REG_F and isR47FAM()))) {
        if (calcMode == CM_PEM) {
            addStepInProgram(ITM_FP);
        } else {
            saveForUndo();
            fnFp(NOPARAM);
            fnToReal(NOPARAM);
        }
        leaveTamModeIfEnabled();
        return;
    } else if ((tam.function == ITM_toINT or tam.function == ITM_HASH_JM) and (item == ITM_REG_D or item == ITM_ENTER)) {
        tam.value = 10;
        forceTry = true;
    } else if ((tam.function == ITM_toINT or tam.function == ITM_HASH_JM) and item == ITM_REG_B) {
        tam.value = 2;
        forceTry = true;
    } else if ((tam.function == ITM_toINT or tam.function == ITM_HASH_JM) and item == ITM_REG_H) {
        tam.value = 16;
        forceTry = true;
    } else if ((tam.function == ITM_toINT or tam.function == ITM_HASH_JM) and item == ITM_REG_O) {
        tam.value = 8;
        forceTry = true;
    } else if ((tam.function == ITM_toINT or tam.function == ITM_HASH_JM) and item == ITM_REG_I) {
        tam.value = 8;
        forceTry = true;
    } else if ((tam.mode == TM_LABEL or tam.mode == TM_LBLONLY or tam.mode == TM_SOLVE or (tam.mode == TM_KEY and tam.keyInputFinished)) and !tam.indirect and ITM_a <= itm and itm <= ITM_l) {
        tam.value = FIRST_LC_LOCAL_LABEL + itm - ITM_a;
        forceTry = true;
        tryOoR = true;
    } else if (((REGISTER_X <= indexOfItems[item].param and indexOfItems[item].param <= REGISTER_W) or
        (FIRST_NAMED_RESERVED_VARIABLE <= indexOfItems[item].param and indexOfItems[item].param <= LAST_RESERVED_VARIABLE)) and
        !tam.dot)
    {
        if (tam.digitsSoFar == 0 and !isFunctionOldParam16(@bitCast(tam.function)) and (tam.indirect or (tam.mode != TM_VALUE and tam.mode != TM_VALUE_CHB))) {
            if ((tam.mode == TM_LABEL or tam.mode == TM_LBLONLY or tam.mode == TM_SOLVE or (tam.mode == TM_KEY and tam.keyInputFinished)) and !tam.indirect) {
                const param: i32 = @intCast(indexOfItems[item].param);
                if (registerLookup[@intCast(param - FIRST_LETTERED_REGISTER)][1] == ALPHA_LABEL) {
                    tam.alpha = true;
                    aimBuffer[0] = @intCast(registerLookup[@intCast(param - FIRST_LETTERED_REGISTER)][0]);
                    aimBuffer[1] = 0;
                    forceTry = true;
                } else {
                    tam.value = FIRST_UC_LOCAL_LABEL - 'A' + registerLookup[@intCast(param - FIRST_LETTERED_REGISTER)][0];
                    forceTry = true;
                    tryOoR = true;
                }
            } else {
                if (calcMode == CM_PEM and indexOfItems[item].param >= FIRST_RESERVED_VARIABLE and indexOfItems[item].param <= LAST_RESERVED_VARIABLE) {
                    tam.alpha = true;
                    _ = strcpy(aimBuffer, @ptrCast(&allReservedVariables[@intCast(@as(i32, @intCast(indexOfItems[item].param)) - FIRST_RESERVED_VARIABLE)].reservedVariableName[1]));
                    forceTry = true;
                } else {
                    tam.value = @intCast(indexOfItems[item].param);
                    tam.value += 99 * @as(i16, @intFromBool(!tam.dot and (tam.mode == TM_FLAGR or tam.mode == TM_FLAGW) and FLAG_M - 99 <= tam.value and tam.value <= FLAG_W - 99));
                    if (comptime !dmcp_build) {
                        _ = printf("tam.value: %d\n", @as(c_int, tam.value));
                    }
                    forceTry = true;
                    tryOoR = true;
                }
            }
        }
    } else if (item == ITM_0P or item == ITM_1P) {
        reallocateRegister(TEMP_REGISTER_1, dtReal34, 0, amNone);
        real34Copy(if (item == ITM_1P) const34_1 else const34_0, reg34(TEMP_REGISTER_1));
        if (tam.digitsSoFar == 0 and !isFunctionOldParam16(@bitCast(tam.function)) and tam.mode != TM_VALUE and tam.mode != TM_VALUE_CHB) {
            tam.value = TEMP_REGISTER_1;
            forceTry = true;
            tryOoR = true;
        }
    } else if (ITM_0 <= itm and itm <= ITM_9) {
        const digit: i16 = itm - ITM_0;
        var maxDigits: u8 = _tamMaxDigits(max2);
        if (tam.function == ITM_GTOP and tam.digitsSoFar == 2) {
            tam.max = @intCast(getNumberOfSteps());
            max2 = tam.max;
            maxDigits = _tamMaxDigits(max2);
        }
        if (!tam.alpha and (tam.value * 10 + digit) <= max2 and tam.digitsSoFar < maxDigits) {
            if (tam.digitsSoFar != maxDigits - 1 or (tam.value * 10 + digit) >= min2) {
                tam.value = tam.value * 10 + digit;
                tam.digitsSoFar += 1;
                if (tam.digitsSoFar == maxDigits) {
                    forceTry = true;
                }
            }
        } else if (tam.function == ITM_GTOP) {
            tam.max = @intCast(maxI(getNumberOfSteps(), 99));
            max2 = tam.max;
            maxDigits = _tamMaxDigits(max2);
        }
    } else if (item == ITM_PERIOD) {
        if (tam.function == ITM_LBL) {
            return;
        } else if (tam.function == ITM_GTOP) {
            aimBuffer[0] = 0;
            tam.value = @intCast(programList[numberOfPrograms - 1].step);
            pemCursorIsZerothStep = true;
            reallyRunFunction(ITM_GTOP, @bitCast(tam.value));
            if ((currentStep[0] != 0xff) or (currentStep[1] != 0xff)) {
                currentStep = firstFreeProgramByte;
                insertStepInProgram(ITM_END);
                scanLabelsAndPrograms();
                tam.value = @intCast(programList[numberOfPrograms - 1].step);
                reallyRunFunction(ITM_GTOP, @bitCast(tam.value));
            }
            leaveTamModeIfEnabled();
            hourGlassIconEnabled = false;
            return;
        } else if (!tam.alpha and tam.digitsSoFar == 0 and !tam.dot and !valueParameter) {
            if (tam.function == ITM_GTO or tam.function == ITM_XEQ) {
                tam.function = ITM_GTOP;
                tam.min = 0;
                tam.max = @intCast(maxI(getNumberOfSteps(), 99));
            } else if (tam.indirect and (currentNumberOfLocalRegisters() != 0 or calcMode == CM_PEM)) {
                tam.dot = true;
            } else if (tam.mode != TM_VALUE and tam.mode != TM_VALUE_CHB and tam.mode != TM_LABEL and tam.mode != TM_LBLONLY and tam.mode != TM_MENU) {
                if (calcMode == CM_PEM or ((tam.mode == TM_FLAGR or tam.mode == TM_FLAGW) and currentLocalFlags != null) or ((tam.mode != TM_FLAGR and tam.mode != TM_FLAGW) and currentNumberOfLocalRegisters() != 0)) {
                    tam.dot = true;
                }
            }
        }
        return;
    } else if (item == ITM_INDIRECTION) {
        if (!tam.alpha and tam.digitsSoFar == 0 and !tam.dot and !valueParameter and (indexOfItems[@intCast(tam.function)].status & PTP_STATUS) != PTP_SKIP_BACK and (indexOfItems[@intCast(tam.function)].status & PTP_STATUS) != PTP_DECLARE_LABEL) {
            if (!tam.indirect) {
                popSoftmenu();
                showSoftmenu(-MNU_TAMINDIRECT);
                numberOfTamMenusToPop -= 1;
            }
            tam.indirect = true;
        }
        return;
    } else if (indexOfItems[item].func == fnGetSystemFlag_ptr() and (tam.mode == TM_FLAGR or tam.mode == TM_FLAGW)) {
        tam.value = @intCast(indexOfItems[item].param);
        tryOoR = true;
        forceTry = true;
    } else if (tam.mode == TM_MENU and softmenu[@intCast(softmenuStack[0].softmenuId)].menuItem == -MNU_MENU) {
        tam.value = itm;
    } else {
        return;
    }

    // Fall-through evaluation.
    if (tam.mode == TM_KEY and !tam.keyInputFinished) {
        if (tam.alpha or forcedVar != null or ((tryOoR or (min2 <= tam.value and tam.value <= max2)) and (forceTry or tam.value * 10 > max2))) {
            tam.key = tam.value;
            tam.keyAlpha = tam.alpha;
            tam.keyDot = tam.dot;
            tam.keyIndirect = tam.indirect;
            tam.keyInputFinished = true;
            _ = xcopy(aimBuffer + AIM_BUFFER_LENGTH / 2, aimBuffer, 16);
            aimBuffer[0] = 0;
            tam.value = 0;
            tam.alpha = false;
            tam.dot = false;
            tam.indirect = false;
            tam.max = 99;
            tam.min = 0;
            tam.digitsSoFar = 0;
            popSoftmenu();
            showSoftmenu(-MNU_TAMLABEL);
            numberOfTamMenusToPop -= 1;
            clearSystemFlag(FLAG_ALPHA);
            if (comptime !dmcp_build) calcModeTamGui();
        } else if (tam.digitsSoFar == 2 and tam.value == 0) {
            tam.digitsSoFar = 1;
        }
    } else if (!tam.alpha and forcedVar == null) {
        if (forceTry and tam.mode == TM_VALUE and currentMenu() == -MNU_TAMNORM and (item == ITM_RNORM or item == ITM_INFINITY)) {
            max2 = pNorm_inf_RNORM + 1;
        }

        if ((tryOoR or (min2 <= tam.value and tam.value <= max2)) and (forceTry or tam.value * 10 > max2) and ((tam.mode != TM_MENU) or tam.indirect)) {
            var value: i16 = tam.value;
            const tryAllocate: bool_t = isFunctionAllowingNewVariable(@bitCast(tam.function));
            var run: bool_t = true;
            if (tam.dot) {
                value += if (tam.mode == TM_FLAGR or tam.mode == TM_FLAGW) FIRST_LOCAL_FLAG else FIRST_LOCAL_REGISTER;
            }
            if (tam.indirect and calcMode != CM_PEM) {
                tam.value0 = value;
                value = indirectAddressing(value, indirectionType(@bitCast(tam.function)), min, max, tryAllocate);
                run = (lastErrorCode == 0);
            }
            if (tam.function == ITM_GTOP) {
                if (tam.digitsSoFar < 3) {
                    pemCursorIsZerothStep = false;
                    fnGoto(@bitCast(value));
                } else {
                    pemCursorIsZerothStep = (value == 0);
                    if (value == 0) {
                        value = 1;
                    }
                    goToPgmStep(currentProgramNumber, @bitCast(value));
                }
            } else if (run) {
                switch (calcMode) {
                    CM_MIM => {
                        mimRunFunction(tamOperation(), @bitCast(value));
                    },
                    CM_PEM => {
                        addStepInProgram(tamOperation());
                    },
                    else => {
                        if (tam.mode == TM_MENU) {
                            leaveTamModeIfEnabled();
                        }
                        reallyRunFunction(tamOperation(), @bitCast(value));
                    },
                }
            }
            if (tamOperation() == ITM_M_GOTO_ROW) {
                leaveTamModeIfEnabled();
                tamEnterMode(ITM_M_GOTO_COLUMN);
            } else {
                leaveTamModeIfEnabled();
            }
        } else if (tam.mode == TM_MENU and softmenu[@intCast(softmenuStack[0].softmenuId)].menuItem == -MNU_MENU) {
            const value: i16 = tam.value;
            if (calcMode == CM_PEM) {
                addStepInProgram(tamOperation());
                leaveTamModeIfEnabled();
            } else {
                leaveTamModeIfEnabled();
                reallyRunFunction(tamOperation(), @bitCast(value));
            }
        }
    } else {
        var buffer: [*c]u8 = if (forcedVar != null) forcedVar else aimBuffer;
        const tryAllocate: bool_t = isFunctionAllowingNewVariable(@bitCast(tam.function));
        var value: i16 = undefined;
        var value2: i16 = undefined;
        if (tam.mode == TM_NEWMENU or tam.mode == TM_STRING) {
            value = 1;
        } else if (tam.mode == TM_LABEL or tam.mode == TM_LBLONLY or tam.mode == TM_SOLVE or (tam.mode == TM_KEY and tam.keyInputFinished) or (tam.mode == TM_DELITM and softmenu[@intCast(softmenuStack[0].softmenuId)].menuItem == -MNU_PROGS)) {
            if (!tam.indirect) {
                value = findNamedLabelWithDuplicate(buffer, dupNum);
            } else {
                value = findNamedVariable(buffer);
                tam.value0 = value;
                if (calcMode != CM_PEM) {
                    if (value != INVALID_VARIABLE) {
                        value2 = indirectAddressing(value, indirectionType(@bitCast(tam.function)), min, max, tryAllocate);
                        buffer = regStringData(value);
                        dynamicMenuItem = -1;
                        value = if (value2 != FAILED_INDIRECTION) value2 else INVALID_VARIABLE;
                    } else {
                        displayCalcErrorMessage(ERROR_UNDEF_SOURCE_VAR, ERR_REGISTER_LINE, REGISTER_X);
                        if (comptime extra_info) {
                            abi.fmtBufZ(errorMessage[0..512], "string '{s}' is not a named variable", .{std.mem.span(buffer)});
                            moreInfoErr("In function _tamProcessInput:", errorMessage, null);
                        }
                    }
                }
            }
            if (value == INVALID_VARIABLE and ((tam.function == ITM_XEQ) or (tam.function == ITM_XEQP1))) {
                if (!tam.indirect) {
                    var i: i32 = 0;
                    while (i < LAST_ITEM) : (i += 1) {
                        if ((indexOfItems[@intCast(i)].status & CAT_STATUS) == CAT_FNCT and compareString(buffer, &indexOfItems[@intCast(i)].itemCatalogName, CMP_NAME) == 0) {
                            leaveTamModeIfEnabled();
                            if (calcMode == CM_PEM) {
                                aimBuffer[0] = 0;
                                if (!programListEnd) {
                                    scrollPemBackwards();
                                }
                            }
                            runFunction(@intCast(i));
                            return;
                        }
                    }
                }
                if (calcMode != CM_PEM) {
                    leaveTamModeIfEnabled();
                    if (!tam.indirect) {
                        displayCalcErrorMessage(ERROR_FUNCTION_NOT_FOUND, ERR_REGISTER_LINE, REGISTER_X);
                        if (comptime extra_info) {
                            abi.fmtBufZ(errorMessage[0..512], "string '{s}' is neither a named label nor a function name", .{std.mem.span(buffer)});
                            moreInfoErr("In function _tamProcessInput:", errorMessage, null);
                        }
                    }
                    return;
                }
            } else if (value == INVALID_VARIABLE and tam.function != ITM_LBL and tam.function != ITM_LBLQ and (calcMode != CM_PEM or tam.mode != TM_SOLVE)) {
                if (calcMode != CM_PEM and getSystemFlag(FLAG_IGN1ER)) {
                    clearSystemFlag(FLAG_IGN1ER);
                    if (comptime extra_info) {
                        abi.fmtBufZ(errorMessage[0..512], "string '{s}' is not a named label", .{std.mem.span(buffer)});
                        moreInfoErr("In function _tamProcessInput:", errorMessage, "ignored since IGN1ER was set");
                    }
                } else if (calcMode != CM_PEM or tam.function != ITM_GTO) {
                    displayCalcErrorMessage(ERROR_LABEL_NOT_FOUND, ERR_REGISTER_LINE, REGISTER_X);
                    if (comptime extra_info) {
                        abi.fmtBufZ(errorMessage[0..512], "string '{s}' is not a named label", .{std.mem.span(buffer)});
                        moreInfoErr("In function _tamProcessInput:", errorMessage, null);
                    }
                }
            } else if (calcMode != CM_PEM) {
                reallyRunFunction(tamOperation(), @bitCast(value));
                leaveTamModeIfEnabled();
                return;
            }
        } else if (tam.mode == TM_DELITM and softmenu[@intCast(softmenuStack[0].softmenuId)].menuItem == -MNU_MENUS) {
            value = tam.value;
        } else if (tryAllocate and !tam.indirect) {
            value = findOrAllocateNamedVariable(buffer);
        } else if ((tam.mode == TM_MENU) and !tam.indirect) {
            value = findMenu(buffer);
            tam.value = value;
            if (value == INVALID_MENU and calcMode != CM_PEM) {
                if (getSystemFlag(FLAG_IGN1ER)) {
                    clearSystemFlag(FLAG_IGN1ER);
                    if (comptime extra_info) {
                        abi.fmtBufZ(errorMessage[0..512], "string '{s}' is not a menu name", .{std.mem.span(buffer)});
                        moreInfoErr("In function _tamProcessInput:", errorMessage, "ignored since IGN1ER system flag was set");
                    }
                } else {
                    displayCalcErrorMessage(ERROR_UNDEF_MENU, ERR_REGISTER_LINE, REGISTER_X);
                    if (comptime extra_info) {
                        abi.fmtBufZ(errorMessage[0..512], "string '{s}' is not a menu name", .{std.mem.span(buffer)});
                        moreInfoErr("In function _tamProcessInput:", errorMessage, null);
                    }
                }
            }
        } else {
            value = findNamedVariable(buffer);
            if (value == INVALID_VARIABLE and calcMode != CM_PEM) {
                if (getSystemFlag(FLAG_IGN1ER)) {
                    clearSystemFlag(FLAG_IGN1ER);
                    if (comptime extra_info) {
                        abi.fmtBufZ(errorMessage[0..512], "string '{s}' is not a named variable", .{std.mem.span(buffer)});
                        moreInfoErr("In function _tamProcessInput:", errorMessage, "ignored since IGN1ER system flag was set");
                    }
                } else {
                    displayCalcErrorMessage(ERROR_UNDEF_SOURCE_VAR, ERR_REGISTER_LINE, REGISTER_X);
                    if (comptime extra_info) {
                        abi.fmtBufZ(errorMessage[0..512], "string '{s}' is not a named variable", .{std.mem.span(buffer)});
                        moreInfoErr("In function _tamProcessInput:", errorMessage, null);
                    }
                }
            }
        }
        if (calcMode == CM_PEM and tam.function != ITM_DELP and lastErrorCode == 0) {
            addStepInProgram(tamOperation());
        }
        if (tam.mode != TM_NEWMENU and tam.mode != TM_STRING) {
            aimBuffer[0] = 0;
        }
        if (tam.indirect and value != INVALID_VARIABLE and calcMode != CM_PEM) {
            tam.value0 = value;
            value = indirectAddressing(value, indirectionType(@bitCast(tam.function)), min, max, tryAllocate);
            if (lastErrorCode != 0) {
                value = INVALID_VARIABLE;
            }
        }
        if (value != INVALID_VARIABLE or tamOperation() == ITM_LBLQ) {
            if (calcMode == CM_MIM) {
                mimRunFunction(tamOperation(), @bitCast(value));
            } else if (tam.function == ITM_GTOP) {
                goToGlobalStep(labelList[@intCast(value - FIRST_LABEL)].step);
            } else if (tam.function == ITM_DELP) {
                reallyRunFunction(ITM_DELP, @bitCast(value));
            } else if (calcMode == CM_PEM) {
                // already done
            } else if (tam.mode == TM_MENU) {
                if (value != INVALID_MENU) {
                    leaveTamModeIfEnabled();
                    reallyRunFunction(tamOperation(), @bitCast(value));
                }
            } else {
                reallyRunFunction(tamOperation(), @bitCast(value));
            }
        }
        if (tamOperation() == ITM_M_GOTO_ROW) {
            leaveTamModeIfEnabled();
            tamEnterMode(ITM_M_GOTO_COLUMN);
        } else {
            leaveTamModeIfEnabled();
        }
    }
}

// indexOfItems[item].func == fnGetSystemFlag : compare against the C symbol's address.
const FnPtr = ?*const fn (u16) callconv(.c) void;
const c_fnGetSystemFlag = @extern(FnPtr, .{ .name = "fnGetSystemFlag" });
inline fn fnGetSystemFlag_ptr() FnPtr {
    return c_fnGetSystemFlag;
}

extern var itemToBeAssigned: i16;
const CMP_NAME: i32 = 3;


// ===========================================================================
// tamEnterMode
// ===========================================================================
pub export fn tamEnterMode(funcIn: i16) callconv(.c) void {
    var func = funcIn;
    tam.mode = @bitCast(if (func == ITM_ASSIGN) TM_LABEL else if (func == ITM_USERMODE) TM_NEWMENU else indexOfItems[@intCast(func)].param);
    func = if (func == ITM_USERMODE) ITM_ASSIGN else func;
    tam.function = func;
    tam.min = @bitCast(indexOfItems[@intCast(func)].tamMinMax >> TAM_MAX_BITS);
    tam.max = @bitCast(indexOfItems[@intCast(func)].tamMinMax & TAM_MAX_MASK);

    screenUpdatingMode = SCRUPD_AUTO;

    if (tam.max == 16383) {
        tam.max = 32766;
    }

    if (calcMode == CM_NIM) {
        if (func == ITM_toINT or func == ITM_HASH_JM) {
            lastIntegerBase = 0;
            screenUpdatingMode &= ~@as(u8, SCRUPD_MANUAL_STATUSBAR);
            resetShiftState();
            leaveTamModeIfEnabled();
            while (stringByteLength(aimBuffer) > 1 and strchr(aimBuffer, '#') != null and aimBuffer[strlen(aimBuffer) - 1] != '#') {
                addItemToNimBuffer(ITM_BACKSPACE);
            }
            addItemToNimBuffer(func);
            refreshRegisterLine(REGISTER_X);
            return;
        } else {
            closeNim();
        }
    } else if (calcMode == CM_PEM and aimBuffer[0] != 0) {
        if (getSystemFlag(FLAG_ALPHA)) {
            pemCloseAlphaInput();
        } else {
            pemCloseNumberInput();
        }
        aimBuffer[0] = 0;
        currentLocalStepNumber -= 1;
        currentStep = findPreviousStep(currentStep);
    } else if (calcMode == CM_PEM) {
        scrollPemForwards();
    }

    if (func == ITM_ASSIGN) {
        aimBuffer[0] = 0;
    }

    tam.alpha = (func == ITM_ASSIGN);
    alphaCursor = 0;
    tam.currentOperation = tam.function;
    tam.digitsSoFar = 0;
    tam.dot = false;
    tam.indirect = false;
    tam.value = 0;

    tam.key = 0;
    tam.keyAlpha = false;
    tam.keyDot = false;
    tam.keyIndirect = false;
    tam.keyInputFinished = false;

    switch (@as(i16, @bitCast(tam.mode))) {
        TM_VALUE_NORM => {
            if ((func != ITM_VIEW and func != ITM_AVIEW) or catalog == 0 or catalog != CATALOG_MVAR) {
                showSoftmenu(-MNU_TAMNORM);
            }
            tam.mode = TM_VALUE;
        },
        TM_VALUE_MAX => {
            if ((func != ITM_VIEW and func != ITM_AVIEW) or catalog == 0 or catalog != CATALOG_MVAR) {
                showSoftmenu(-MNU_TAMNONREGMAX);
            }
            tam.mode = TM_VALUE;
        },
        TM_VALUE_TRK => {
            if ((func != ITM_VIEW and func != ITM_AVIEW) or catalog == 0 or catalog != CATALOG_MVAR) {
                showSoftmenu(-MNU_TAMNONREGTRK);
            }
            tam.mode = TM_VALUE;
        },
        TM_VALUE, TM_VALUE_CHB => {
            if ((func != ITM_VIEW and func != ITM_AVIEW) or catalog == 0 or catalog != CATALOG_MVAR) {
                showSoftmenu(-MNU_TAMNONREG);
            }
        },
        TM_REGISTER, TM_M_DIM, TM_KEY => {
            if ((func != ITM_VIEW and func != ITM_AVIEW) or catalog == 0 or catalog != CATALOG_MVAR) {
                showSoftmenu(-MNU_TAM);
            }
        },
        TM_VARONLY => {
            showSoftmenu(-MNU_TAMVARONLY);
        },
        TM_CMP => {
            showSoftmenu(-MNU_TAMCMP);
        },
        TM_FLAGR, TM_FLAGW => {
            showSoftmenu(-MNU_TAMFLAG);
        },
        TM_STORCL => {
            if (catalog == 0 or catalog != CATALOG_MVAR) {
                showSoftmenu(if (func == ITM_STO) (if (currentMenu() == -MNU_TVM) -MNU_TAMSTO_TVM else -MNU_TAMSTO) else (if (currentMenu() == -MNU_TVM or currentMenu() == -MNU_AMORT) -MNU_TAMRCL_TVM else -MNU_TAMRCL));
            }
        },
        TM_SHUFFLE => {
            showSoftmenu(-MNU_TAMSHUFFLE);
        },
        TM_LABEL => {
            if (func == ITM_ASSIGN) {
                showSoftmenu(-MNU_TAMALPHA);
            } else {
                showSoftmenu(-MNU_TAMLABEL);
            }
        },
        TM_LBLONLY => {
            showSoftmenu(-MNU_TAMLBLONLY);
        },
        TM_MENU => {
            showSoftmenu(-MNU_TAMMENU);
        },
        TM_SOLVE => {
            if (func == ITM_SOLVE and calcMode == CM_PEM) {
                showSoftmenu(-MNU_TAMVARONLY);
            } else {
                showSoftmenu(-MNU_TAMLBLONLY);
            }
        },
        TM_NEWMENU => {
            showSoftmenu(-MNU_TAMALPHA);
            screenUpdatingMode &= ~@as(u8, SCRUPD_MANUAL_MENU);
        },
        TM_DELITM => {
            showSoftmenu(-ITM_DELITM);
        },
        TM_STRING => {
            tam.alpha = true;
            setSystemFlag(FLAG_ALPHA);
            aimBuffer[0] = 0;
            alphaCursor = 0;
            calcModeAim(NOPARAM);
            showSoftmenu(-MNU_TAMALPHA);
            screenUpdatingMode &= ~@as(u8, SCRUPD_MANUAL_MENU);
        },
        else => {
            abi.fmtBufZ(errorMessage[0..512], "In function {s}:{d} is an unexpected value for {s}!", .{ "tamEnterMode", @as(c_int, @intCast(tam.mode)), "tam.mode" });
            displayBugScreen(errorMessage);
            return;
        },
    }

    numberOfTamMenusToPop = 1;

    _tamUpdateBuffer();

    clearSystemFlag(FLAG_ALPHA);

    if (comptime !dmcp_build) {
        if (forceTamAlpha) {
            forceTamAlpha = false;
            tamProcessInput(ITM_alpha);
        }
    }

    if (tam.mode == TM_NEWMENU or tam.mode == TM_STRING) {
        setSystemFlag(FLAG_ALPHA);
        aimBuffer[0] = 0;
        calcModeAim(NOPARAM);
    } else {
        if (comptime !dmcp_build) {
            calcModeTamGui();
        }
    }
}
extern const commonBugScreenMessages: [10][100]u8;

// ===========================================================================
// leaveTamModeIfEnabled
// ===========================================================================
pub export fn leaveTamModeIfEnabled() callconv(.c) void {
    if (tam.mode == 0) {
        return;
    }
    if (screenUpdatingMode & (SCRUPD_MANUAL_STACK | SCRUPD_SKIP_STACK_ONE_TIME) != 0) {
        clearTamBuffer();
    }

    if (((tam.mode == TM_STORCL) or (tam.function == ITM_VIEW) or (tam.function == ITM_AVIEW)) and (currentMenu() == -MNU_MVAR)) {
        numberOfTamMenusToPop = 0;
    } else {
        catalog = CATALOG_NONE;
    }

    tam.alpha = false;
    tam.mode = 0;
    clearSystemFlag(FLAG_ALPHA);

    if (numberOfTamMenusToPop > 0) {
        while (numberOfTamMenusToPop > 0) {
            numberOfTamMenusToPop -= 1;
            popSoftmenu();
        }
    }

    if (comptime !dmcp_build) {
        switch (calcMode) {
            CM_NORMAL, CM_PEM, CM_MIM, CM_TIMER, CM_ASSIGN => {
                calcModeNormalGui();
            },
            CM_AIM, CM_EIM => {
                calcModeAimGui();
            },
            else => {},
        }
    }

    if (calcMode == CM_PEM) {
        hourGlassIconEnabled = false;
    }
}

// ===========================================================================
// tamProcessInput
// ===========================================================================
pub export fn tamProcessInput(item: u16) callconv(.c) void {
    _tamProcessInput(item);
    _tamUpdateBuffer();
}
