// RESTORE-side parser of the calculator state file (c47.sav text format).
//
// Faithful Zig port of saveRestoreCalcState.c restoreOneSection() (lines
// ~2360-3204): reads one section from the open save file and applies it
// according to loadMode, returning true to continue (more sections) or false
// when the terminal OTHER_CONFIGURATION_STUFF section has been consumed. The
// host Zig io_flow path (calc_state_io_flow_owned.doLoad) already owns the
// open/header/policy/close orchestration and drives this in a loop.
//
// The Zig owner owns the section dispatch, the per-field control flow, and the
// loadMode gating; the file-static leaf primitives (toInt16/toUint*/next_word/
// skip_*/toInt16_next_word/strcmp2 and restoreRegister/restoreMatrixData/
// skipMatrixData) plus a few macro / static-inline reads are reached through
// direct externs to the canonical core C symbols. loadedVersion/savedCalcModel
// come from the Zig header parse (compat shim); the C static loadedVersion is
// kept in sync so the trampolined restorers see the same value.
//
// Verified by the save/load round-trip parity harness
// (`zig build saveload_roundtrip`): restore reconstructs state such that re-saving
// is byte-identical to the original save.

const std = @import("std");
const builtin = @import("builtin");
const runtime = @import("calc_state_runtime.zig");
const text = @import("calc_state_text.zig");
const progmem = @import("calc_state_progmem.zig");
const build_options = @import("calc_state_build_options");

const state_old_hw: bool = build_options.state_old_hw;
fn geometry() progmem.Geometry {
    return .{
        .ram_base = @intFromPtr(ram),
        .ram_size_in_blocks = if (state_old_hw) progmem.RAM_SIZE_IN_BLOCKS_OLD_HW else progmem.RAM_SIZE_IN_BLOCKS_NEW_HW,
        .old_hw = state_old_hw,
    };
}
const codec = @import("calc_state_register_codec.zig");

// --- Resolved constants (probed from the real headers) ---
const FIRST_LOCAL_REGISTER: i16 = 7000;
const LAST_GLOBAL_REGISTER: i16 = 136;
extern fn boundShortIntegerWordSize(word_size: u8) callconv(.c) u8;
extern fn set_def_Input_Default() callconv(.c) void;
// currentNumberOfLocalRegisters macro: currentSubroutineLevelData->numberOfLocalRegisters.
const subroutineLevelHeader_t = abi.SubroutineLevelHeader;
extern var currentSubroutineLevelData: [*c]subroutineLevelHeader_t;
inline fn currentNumberOfLocalRegisters() u8 {
    return currentSubroutineLevelData[0].numberOfLocalRegisters;
}
const FIRST_NAMED_VARIABLE: i16 = 256;
const FIRST_GLOBAL_REGISTER: i16 = 0;
const dtConfig: u32 = 9;
extern fn getRegisterDataType(regist: i16) u32;
extern var numberOfNamedVariables: u16;
const REGISTER_X: i16 = 100; // == FIRST_LETTERED_REGISTER
const ERR_REGISTER_LINE: i16 = 102; // REGISTER_Z
const ERROR_RAM_FULL: u8 = 11;
const NUMBER_OF_STATISTICAL_SUMS: i16 = 28;
extern fn displayCalcErrorMessage(error_code: u8, err_message_register_line: i16, err_register_line: i16) void;
const INVALID_VARIABLE: i16 = 2199;

// Lettered-register names for registers 100..125, in register-number order.
const registerLetters = "XYZTABCDLIJKMNPQRSEFGHOUVW";

// Map a saved register-name field to its number. "RX".."RW" (a leading 'R'
// followed by a non-digit) decode to the lettered registers 100..125; anything
// else (e.g. "R000") is read as the decimal number, so existing "Rnnn" files
// stay fully compatible. Faithful port of master stringToRegisterNumber.
fn stringToRegisterNumber(name: [*c]const u8) i16 {
    @setRuntimeSafety(true); // untrusted file input -- see calc_state.zig's panic decl
    if (name[0] == 'R' and name[1] != 0 and (name[1] < '0' or name[1] > '9')) {
        var k: usize = 0;
        while (registerLetters[k] != 0) : (k += 1) {
            if (registerLetters[k] == name[1]) {
                return REGISTER_X + @as(i16, @intCast(k));
            }
        }
    }
    return text.toInt16(name + 1);
}
const C47_NULL: u16 = 65535;
const TMP_STR_LENGTH: usize = 2560;
const AIM_BUFFER_LENGTH: usize = 1024;
const ERROR_MESSAGE_LENGTH: usize = 512;
const MAX_DENMAX: u32 = 9999;

const LM_ALL: u16 = 0;
const LM_PROGRAMS: u16 = 1;
const LM_REGISTERS: u16 = 2;
const LM_NAMED_VARIABLES: u16 = 3;
const LM_SUMS: u16 = 4;
const LM_SYSTEM_STATE: u16 = 5;
const LM_REGISTERS_PARTIAL: u16 = 6;
const ERROR_NONE: u8 = 0;

const USER_R47: u16 = 66;
const USER_C47: u16 = 46;
const USER_DM42: u16 = 45;
const USER_R47f_g: u16 = 61;
const USER_R47fg_g: u16 = 64;
const USER_R47fg_bk: u16 = 63;
const USER_R47bk_fg: u16 = 62;
const USER_V47: u16 = 40;
const USER_E47: u16 = 43;
const USER_D47: u16 = 47;
const USER_N47: u16 = 51;

// CALCMODEL == USER_R47 for the firmware this object is linked into. The R47
// firmware carries only the R47 layouts, so its kbd_std selector is a different
// one -- read the model the build stamped in, never re-derive it.
const built_for_r47: bool = build_options.calc_model_user_id == USER_R47;
const is_dmcp_build = builtin.target.os.tag == .freestanding;

const ITM_END: i32 = 1458;
const MNU_HOME: i16 = 3070;
const MNU_MyMenu: i16 = 3090;
const CMP_NAME: i32 = 3;
const CFG_DFLT: u16 = 0;

const RBX_FGLNOFF: u8 = 227;
const RBX_FGLNLIM: u8 = 229;
const RBX_FGLNFUL: u8 = 228;
const RBX_M14: u8 = 224;
const RBX_F14: u8 = 221;
const BCDu: u8 = 218;

const FLAG_MONIT: c_uint = 32832;
const FLAG_FRACT: c_uint = 32775;
const FLAG_IRFRAC: c_uint = 32839;
const FLAG_IRFRQ: c_uint = 49224;
const FLAG_SIGZEROS: c_uint = 32874; // 0x806A
const FLAG_PRMS: c_uint = 32875; // 0x806B
const FLAG_PINTG: c_uint = 32876; // 0x806C
const FLAG_PDIFF: c_uint = 32877; // 0x806D
const FLAG_PSHADE: c_uint = 32878; // 0x806E
const FLAG_SBadm: c_uint = 32879; // 0x806F
const FLAG_FGLNLIM: c_uint = 32866;
const FLAG_FGLNFUL: c_uint = 32867;
const FLAG_HOME_TRIPLE: c_uint = 32864;
const FLAG_MYM_TRIPLE: c_uint = 32863;
const FLAG_SHFT_4s: c_uint = 32865;
const FLAG_BASE_HOME: c_uint = 32862;
const FLAG_BASE_MYM: c_uint = 32860;
const FLAG_G_DOUBLETAP: c_uint = 32861;
const FLAG_BCD: c_uint = 32857;
const FLAG_TOPHEX: c_uint = 32856;
const FLAG_LARGELI: c_uint = 32838;
const FLAG_ERPN: c_uint = 32837;
const FLAG_M_ALL: c_uint = 32882;
const FLAG_CPXMULT: c_uint = 32836;
const FLAG_PFX_ALL: c_uint = 32841;

fn TO_BYTES(n: anytype) u32 {
    return @as(u32, @intCast(n)) << 2;
}
fn TO_BLOCKS(n: anytype) u32 {
    return (@as(u32, @intCast(n)) + 3) >> 2;
}

// --- Struct models (asserted against the C ABI) ---
const abi = @import("abi"); // shared ABI bindings
const calc_state = @import("calc_state.zig"); // intra-object Zig-to-Zig
const calcKey_t = abi.CalcKey;
const userMenuItem_t = abi.UserMenuItem;
const userMenu_t = abi.UserMenu;
const normKey_t = abi.NormKey;
const formulaHeader_t = abi.FormulaHeader;
const programList_t = abi.ProgramList;
const pcg32_random_t = abi.Pcg32Random;

comptime {
    std.debug.assert(@sizeOf(calcKey_t) == 18);
    std.debug.assert(@sizeOf(userMenuItem_t) == 20);
    std.debug.assert(@sizeOf(userMenu_t) == 376);
    std.debug.assert(@sizeOf(normKey_t) == 20);
    std.debug.assert(@sizeOf(formulaHeader_t) == 4);
    std.debug.assert(@sizeOf(pcg32_random_t) == 16);
}

// --- libc / core helpers ---
extern fn strlen(s: [*c]const u8) usize;
extern fn strcmp(a: [*c]const u8, b: [*c]const u8) c_int;
extern fn strcpy(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn memset(dst: ?*anyopaque, val: c_int, n: usize) ?*anyopaque;
extern fn utf8ToString(utf8: [*c]const u8, str: [*c]u8) void;
extern fn utf8ToStringWithLength(utf8: [*c]const u8, str: [*c]u8, maxBytes: usize) void;
extern fn findOrAllocateNamedVariable(name: [*c]const u8) i16;
extern fn allocateLocalRegisters(num: u16) void;
extern fn initStatisticalSums() void;
extern fn reLoadStatisticalSums() void;
extern fn freeC47Blocks(p: ?*anyopaque, size_in_blocks: usize) void;
extern fn allocC47Blocks(size_in_blocks: usize) ?*anyopaque;
extern fn setUserKeyArgument(position: u16, name: [*c]const u8) void;
extern fn compareString(a: [*c]const u8, b: [*c]const u8, cmp: i32) i32;
extern fn createMenu(name: [*c]const u8) void;
extern fn resizeProgramMemory(new_size_in_blocks: u16) void;
extern fn scanLabelsAndPrograms() void;
extern fn xcopy(dst: ?*anyopaque, src: ?*const anyopaque, nbytes: u32) ?*anyopaque;
extern fn deleteEquation(equation_id: u16) void;
extern fn setEquation(equation_id: u16, str: [*c]const u8) void;
extern fn configCommon(idx: u16) void;
extern fn resetOtherConfigurationStuff(allow_user_keys: bool) void;
extern fn defaultStatusBar() void;
extern fn setSystemFlag(sf: c_uint) void;
extern fn getSystemFlag(sf: i32) bool;
extern fn clearSystemFlag(sf: c_uint) void;
extern fn forceSystemFlag(sf: c_uint, set: c_int) void;
extern fn setLongPressFg(calc_model0: c_int, menu_item: i16) void;
extern fn setLineDelay(delay: u16) void;

// --- load-parsing leaf externs (canonical core C symbols) ---
extern fn parseEquation(equation_id: u16, parse_mode: u16, buffer: [*c]u8, mvar_buffer: [*c]u8) void;
extern var updateOldConstants: bool;
const EQUATION_PARSER_MVAR: u16 = 0;
// Pre-10000021 equation-constant migration (was _updateConstantsInEquations).
fn updateConstantsInEquations() void {
    var i: u16 = 0;
    while (i < numberOfFormulae) : (i += 1) {
        if (allFormulae[i].pointerToFormulaData != C47_NULL) {
            parseEquation(i, EQUATION_PARSER_MVAR, aimBuffer, tmpString);
            if (lastErrorCode == 0) {
                _ = strcpy(tmpString, toPcmemptr(@as(u32, allFormulae[i].pointerToFormulaData)));
                updateOldConstants = true;
                parseEquation(i, EQUATION_PARSER_MVAR, aimBuffer, tmpString);
                updateOldConstants = false;
                setEquation(i, tmpString);
            } else {
                lastErrorCode = 0;
            }
        }
    }
}
extern fn checkOpCodeOfStep(step: [*c]const u8, op: u16) bool;
extern const kbd_std_C47: [37]calcKey_t;
extern const kbd_std_DM42: [37]calcKey_t;
extern const kbd_std_R47f_g: [37]calcKey_t;
extern const kbd_std_R47bk_fg: [37]calcKey_t;
extern const kbd_std_R47fg_bk: [37]calcKey_t;
extern const kbd_std_R47fg_g: [37]calcKey_t;
// assign.c:95-274 defines these four only under PC_BUILD, so kbdStdPrimary may
// only name them on the host.
extern const kbd_std_E47: [37]calcKey_t;
extern const kbd_std_D47: [37]calcKey_t;
extern const kbd_std_V47: [37]calcKey_t;
extern const kbd_std_N47: [37]calcKey_t;
fn isAtEndOfProgram(step: [*c]const u8) bool {
    return checkOpCodeOfStep(step, @intCast(ITM_END));
}
fn normKey00Key() i16 {
    return switch (@as(u16, calcModel)) {
        USER_C47, USER_DM42 => 0,
        USER_R47bk_fg => 10,
        USER_R47fg_bk => 11,
        else => -1, // USER_R47f_g and others
    };
}
// The kbd_std macro (c47.h:257-267). Three different selectors, chosen by the
// preprocessor: PC_BUILD walks every layout the simulator can be switched to;
// a CALCMODEL == USER_R47 firmware only ever reaches the four R47 layouts and
// falls back to R47f_g; every other firmware only ever reaches DM42 and C47.
fn kbdStdPrimary(idx: i16) i16 {
    const std_kbd: *const [37]calcKey_t = if (comptime !is_dmcp_build) switch (@as(u16, calcModel)) {
        USER_C47 => &kbd_std_C47,
        USER_DM42 => &kbd_std_DM42,
        USER_R47f_g => &kbd_std_R47f_g,
        USER_R47bk_fg => &kbd_std_R47bk_fg,
        USER_R47fg_bk => &kbd_std_R47fg_bk,
        USER_R47fg_g => &kbd_std_R47fg_g,
        USER_E47 => &kbd_std_E47,
        USER_D47 => &kbd_std_D47,
        USER_V47 => &kbd_std_V47,
        USER_N47 => &kbd_std_N47,
        else => &kbd_std_C47,
    } else if (comptime built_for_r47) switch (@as(u16, calcModel)) {
        USER_R47bk_fg => &kbd_std_R47bk_fg,
        USER_R47fg_bk => &kbd_std_R47fg_bk,
        USER_R47fg_g => &kbd_std_R47fg_g,
        else => &kbd_std_R47f_g,
    } else if (calcModel == USER_DM42) &kbd_std_DM42 else &kbd_std_C47;
    return std_kbd[@intCast(idx)].primary;
}

// --- core state globals ---
extern var tmpString: [*c]u8;
extern var aimBuffer: [*c]u8;
extern var errorMessage: [*c]u8;
extern var globalFlags: [8]u16;
extern var lastErrorCode: u8;
extern var statisticalSumsPointer: ?*anyopaque;
extern var systemFlags0: u64;
extern var systemFlags1: u64;
extern var kbd_usr: [37]calcKey_t;
extern var Norm_Key_00: normKey_t;
extern var userKeyLabel: [*c]u8;
extern var userKeyLabelSize: u16;
extern var userMenuItems: [18]userMenuItem_t;
extern var userAlphaItems: [18]userMenuItem_t;
extern var numberOfUserMenus: u16;
extern var userMenus: [*c]userMenu_t;
extern var beginOfProgramMemory: [*c]u8;
extern var firstFreeProgramByte: [*c]u8;
extern var freeProgramBytes: u16;
extern var currentStep: [*c]u8;
extern var firstDisplayedStep: [*c]u8;
extern var beginOfCurrentProgram: [*c]u8;
extern var endOfCurrentProgram: [*c]u8;
extern var currentProgramNumber: u16;
extern var currentLocalStepNumber: u16;
extern var firstDisplayedLocalStepNumber: u16;
extern var pemCursorIsZerothStep: bool;
extern var programList: [*c]programList_t;
extern fn findNextStep(step: [*c]u8) [*c]u8;
extern fn defineFirstDisplayedStep() void;
extern fn defineCurrentProgramFromCurrentStep() void;
extern var numberOfFormulae: u16;
extern var currentFormula: u16;
extern var allFormulae: [*c]formulaHeader_t;
extern var currentLocalFlags: ?*u32;
extern var ram: [*c]u32;
extern var pcg32_global: pcg32_random_t;
extern var calcModel: u8;
extern var hourGlassIconEnabled: bool;
extern var cancelFilename: bool;

// ---------------------------------------------------------------------------
// Menu change-over (2026-08-16). Every existing menu moved into one block, so a
// stored (negative) menu link -- in the user keyboard, in MyMenu, in MyAlpha and
// in every user menu -- still names the old number and has to be converted.
// ---------------------------------------------------------------------------
const MenuRenumber = struct { from: u16, to: u16 };

const menuRenumberTable = [_]MenuRenumber{
    .{ .from = 1207, .to = 2974 }, // MNU_BINOM              Binom:
    .{ .from = 1212, .to = 2975 }, // MNU_CAUCH              Cauch:
    .{ .from = 1217, .to = 2979 }, // MNU_EXPON              Expon:
    .{ .from = 1222, .to = 2980 }, // MNU_F                  F:
    .{ .from = 1227, .to = 2981 }, // MNU_GEOM               Geom:
    .{ .from = 1232, .to = 2983 }, // MNU_HYPER              Hyper:
    .{ .from = 1237, .to = 2977 }, // MNU_DISTR              DISTR
    .{ .from = 1242, .to = 2984 }, // MNU_LOGIS              Logis:
    .{ .from = 1247, .to = 2982 }, // MNU_GEV                GEV:
    .{ .from = 1252, .to = 2985 }, // MNU_NORML              Norml:
    .{ .from = 1257, .to = 2987 }, // MNU_POISS              Poiss:
    .{ .from = 1262, .to = 2989 }, // MNU_T                  t:
    .{ .from = 1267, .to = 2991 }, // MNU_WEIBL              Weibl:
    .{ .from = 1272, .to = 2976 }, // MNU_CHI2
    .{ .from = 1277, .to = 2988 }, // MNU_STDNORML
    .{ .from = 1286, .to = 2986 }, // MNU_PARETO             Pareto:
    .{ .from = 1313, .to = 3000 }, // MNU_ADV                ADV
    .{ .from = 1314, .to = 3013 }, // MNU_ANGLES             ANGLES
    .{ .from = 1315, .to = 3106 }, // MNU_PRINT              PRINT
    .{ .from = 1316, .to = 3033 }, // MNU_CONVA              Area:
    .{ .from = 1317, .to = 3018 }, // MNU_BITS               BITS
    .{ .from = 1318, .to = 3022 }, // MNU_CATALOG            CAT
    .{ .from = 1319, .to = 3023 }, // MNU_CHARS              CHARS
    .{ .from = 1320, .to = 3024 }, // MNU_CLK                CLK
    .{ .from = 1321, .to = 3025 }, // MNU_CLR                CLR
    .{ .from = 1322, .to = 3027 }, // MNU_CONST              CNST
    .{ .from = 1323, .to = 3046 }, // MNU_CPX                CPX
    .{ .from = 1324, .to = 3047 }, // MNU_CPXS               CPXS
    .{ .from = 1325, .to = 3048 }, // MNU_DATES              DATES
    .{ .from = 1326, .to = 3051 }, // MNU_DISP               DISP
    .{ .from = 1327, .to = 3057 }, // MNU_EQN                EQN
    .{ .from = 1328, .to = 3058 }, // MNU_EXP                EXP
    .{ .from = 1329, .to = 3036 }, // MNU_CONVE              Energy:
    .{ .from = 1330, .to = 3059 }, // MNU_FCNS               FCNS
    .{ .from = 1331, .to = 3061 }, // MNU_FIN                FIN
    .{ .from = 1332, .to = 3121 }, // MNU_SINTS              S.INTS
    .{ .from = 1333, .to = 3062 }, // MNU_FLAGS              FLAG
    .{ .from = 1335, .to = 2997 }, // MNU_1STDERIV           f'
    .{ .from = 1336, .to = 2998 }, // MNU_2NDDERIV           f_
    .{ .from = 1337, .to = 3037 }, // MNU_CONVFP             F&p:
    .{ .from = 1338, .to = 3077 }, // MNU_LINTS              L.INTS
    .{ .from = 1339, .to = 3072 }, // MNU_INFO               INFO
    .{ .from = 1340, .to = 3074 }, // MNU_INTS               INTS
    .{ .from = 1341, .to = 3075 }, // MNU_IO                 I/O
    .{ .from = 1342, .to = 3078 }, // MNU_LOOP               LOOP
    .{ .from = 1343, .to = 3080 }, // MNU_MATRS              MATRS
    .{ .from = 1344, .to = 3081 }, // MNU_MATX               MATX
    .{ .from = 1345, .to = 3083 }, // MNU_MENUS              MENUS
    .{ .from = 1346, .to = 3085 }, // MNU_MODE               MODE
    .{ .from = 1347, .to = 3120 }, // MNU_SIMQ               M_SIMQ
    .{ .from = 1348, .to = 3079 }, // MNU_M_EDIT             M_EDIT
    .{ .from = 1349, .to = 3090 }, // MNU_MyMenu             MyM
    .{ .from = 1350, .to = 3089 }, // MNU_MyAlpha
    .{ .from = 1351, .to = 3039 }, // MNU_CONVM              Mass:
    .{ .from = 1352, .to = 3093 }, // MNU_ORTHOG             Orthog
    .{ .from = 1353, .to = 3094 }, // MNU_PARTS              REAL
    .{ .from = 1354, .to = 3108 }, // MNU_PROB               PROB
    .{ .from = 1355, .to = 3110 }, // MNU_PROGS              PROGS
    .{ .from = 1356, .to = 3096 }, // MNU_PFN_1              P.FN1
    .{ .from = 1357, .to = 3097 }, // MNU_PFN_2              P.FN2
    .{ .from = 1358, .to = 3040 }, // MNU_CONVP              Power:
    .{ .from = 1359, .to = 3038 }, // MNU_CONVHUM            FFF+:
    .{ .from = 1360, .to = 3111 }, // MNU_REALS              REALS
    .{ .from = 1361, .to = 3122 }, // MNU_Solver             f Solve
    .{ .from = 1362, .to = 3124 }, // MNU_STAT               STAT
    .{ .from = 1363, .to = 3125 }, // MNU_STK                STK
    .{ .from = 1364, .to = 3126 }, // MNU_STRINGS            STRINGS
    .{ .from = 1365, .to = 3129 }, // MNU_TEST               TEST
    .{ .from = 1366, .to = 3131 }, // MNU_TIMES              TIMES
    .{ .from = 1367, .to = 3135 }, // MNU_TRI                TRIG
    .{ .from = 1368, .to = 3136 }, // MNU_TVM                TVM
    .{ .from = 1369, .to = 3137 }, // MNU_UNITCONV           CONV
    .{ .from = 1370, .to = 3139 }, // MNU_VARS               VARS
    .{ .from = 1371, .to = 3043 }, // MNU_CONVV              Volume:
    .{ .from = 1372, .to = 3142 }, // MNU_XFN                X.FN
    .{ .from = 1373, .to = 3044 }, // MNU_CONVX              Length:
    .{ .from = 1374, .to = 3007 }, // MNU_ALPHAINTL
    .{ .from = 1375, .to = 3009 }, // MNU_ALPHAMATH
    .{ .from = 1376, .to = 3006 }, // MNU_ALPHAFN
    .{ .from = 1377, .to = 3004 }, // MNU_ALPHA_OMEGA
    .{ .from = 1378, .to = 3010 }, // MNU_ALPHAMISC
    .{ .from = 1379, .to = 3128 }, // MNU_SYSFL              SYS.FL
    .{ .from = 1380, .to = 3116 }, // MNU_Sf
    .{ .from = 1381, .to = 3118 }, // MNU_Sfdx
    .{ .from = 1382, .to = 3012 }, // MNU_ANGLECONV_43S
    .{ .from = 1383, .to = 3005 }, // MNU_alpha_omega
    .{ .from = 1384, .to = 3008 }, // MNU_ALPHAintl
    .{ .from = 1385, .to = 2945 }, // MNU_TAM                Tam
    .{ .from = 1386, .to = 2947 }, // MNU_TAMCMP             TamCmp
    .{ .from = 1387, .to = 2961 }, // MNU_TAMSTO             TamSto
    .{ .from = 1388, .to = 3067 }, // MNU_Grapher            f Graph
    .{ .from = 1389, .to = 3138 }, // MNU_VAR                VAR
    .{ .from = 1390, .to = 2948 }, // MNU_TAMFLAG            TamFlag
    .{ .from = 1391, .to = 2960 }, // MNU_TAMSHUFFLE         TamShuffle
    .{ .from = 1392, .to = 3109 }, // MNU_PROG               PROG
    .{ .from = 1393, .to = 2950 }, // MNU_TAMLABEL           TamLabel
    .{ .from = 1394, .to = 3052 }, // MNU_DYNAMIC            DYNMNU
    .{ .from = 1395, .to = 3101 }, // MNU_PLOT_SCATR         SCATR
    .{ .from = 1396, .to = 3099 }, // MNU_PLOT_ASSESS        ASSESS
    .{ .from = 1397, .to = 3055 }, // MNU_ELLIPT             Ellipt
    .{ .from = 1398, .to = 3088 }, // MNU_MVAR               MVAR
    .{ .from = 1399, .to = 3056 }, // MNU_EQ_EDIT            EQ_EDIT
    .{ .from = 1400, .to = 3130 }, // MNU_TIMERF             STOPW
    .{ .from = 1401, .to = 3069 }, // MNU_HIST               HIST
    .{ .from = 1402, .to = 3071 }, // MNU_HPLOT              HPLOT
    .{ .from = 1403, .to = 3095 }, // MNU_PFN                P.FN
    .{ .from = 1448, .to = 3020 }, // MNU_BLUE_C47           BLUE47
    .{ .from = 1860, .to = 3084 }, // MNU_MISC               Misc:
    .{ .from = 1881, .to = 3019 }, // MNU_BITSET             BITSET
    .{ .from = 1883, .to = 3073 }, // MNU_INL_TST            Inl. Tst
    .{ .from = 1901, .to = 3035 }, // MNU_CONVCHEF           Chef:
    .{ .from = 1907, .to = 3102 }, // MNU_PLOT_STAT          PLSTAT
    .{ .from = 1912, .to = 2958 }, // MNU_TAMRCL             TamRcl
    .{ .from = 1913, .to = 2946 }, // MNU_TAMALPHA           TamAlpha
    .{ .from = 1920, .to = 3014 }, // MNU_ASN_N
    .{ .from = 1921, .to = 3070 }, // MNU_HOME               HOME
    .{ .from = 1922, .to = 3003 }, // MNU_ALPHA              ALPHA
    .{ .from = 1923, .to = 3016 }, // MNU_BASE               BASE
    .{ .from = 1925, .to = 3053 }, // MNU_EE                 ELEC
    .{ .from = 1927, .to = 3076 }, // MNU_KEYS               KEYS
    .{ .from = 2028, .to = 3100 }, // MNU_PLOT_FUNC          PLFUNC
    .{ .from = 2036, .to = 3134 }, // MNU_TRG_R47            TRG
    .{ .from = 2037, .to = 3104 }, // MNU_PREF               PREF
    .{ .from = 2045, .to = 3041 }, // MNU_CONVS              Speed:
    .{ .from = 2046, .to = 3034 }, // MNU_CONVANG            Angle:
    .{ .from = 2047, .to = 3042 }, // MNU_CONVTEMP           Temp:
    .{ .from = 2066, .to = 3112 }, // MNU_REG                REG
    .{ .from = 2067, .to = 3063 }, // MNU_FLG                FLG
    .{ .from = 2068, .to = 2954 }, // MNU_TAMNONREG          TamNonReg
    .{ .from = 2080, .to = 3113 }, // MNU_REGR               REGR
    .{ .from = 2081, .to = 3086 }, // MNU_MODEL              MODEL
    .{ .from = 2102, .to = 3132 }, // MNU_TRG_C47            TRG
    .{ .from = 2103, .to = 3133 }, // MNU_TRG_C47_MORE
    .{ .from = 2106, .to = 3141 }, // MNU_VECT               VECTOR
    .{ .from = 2107, .to = 3103 }, // MNU_PLOTTING           PLOT
    .{ .from = 2108, .to = 2949 }, // MNU_TAMINDIRECT        TamIndirect
    .{ .from = 2109, .to = 2955 }, // MNU_TAMNONREGMAX       TamNonRegMax
    .{ .from = 2151, .to = 3064 }, // MNU_GAP_L              IPART
    .{ .from = 2152, .to = 3066 }, // MNU_GAP_RX             RADIX
    .{ .from = 2153, .to = 3065 }, // MNU_GAP_R              FPART
    .{ .from = 2222, .to = 3045 }, // MNU_CONVYMMV           Ymmv:
    .{ .from = 2225, .to = 2963 }, // MNU_TAMVARONLY         TamVarOnly
    .{ .from = 2226, .to = 2951 }, // MNU_TAMLBLONLY         TamLblOnly
    .{ .from = 2227, .to = 3054 }, // MNU_EIMCATALOG         CAT
    .{ .from = 2228, .to = 3060 }, // MNU_FCNS_EIM           FCNS
    .{ .from = 2229, .to = 3105 }, // MNU_PREFIX             PFX
    .{ .from = 2230, .to = 3091 }, // MNU_NUMBRS             NUMBRS
    .{ .from = 2231, .to = 3026 }, // MNU_CONFIGS            CONFIGS
    .{ .from = 2232, .to = 3002 }, // MNU_ALLVARS            ALL
    .{ .from = 2234, .to = 3114 }, // MNU_RESETS             RESETS
    .{ .from = 2235, .to = 3115 }, // MNU_RIBBONS            RIBBONS
    .{ .from = 2238, .to = 2956 }, // MNU_TAMNONREGTRK       TamNonRegTrk
    .{ .from = 2243, .to = 3049 }, // MNU_DELETE             DELETE
    .{ .from = 2244, .to = 3144 }, // MNU_YESNO              YESNO
    .{ .from = 2315, .to = 3119 }, // MNU_SHOW               SHOW
    .{ .from = 2374, .to = 3068 }, // MNU_GRAPHS             Graphs
    .{ .from = 2375, .to = 3117 }, // MNU_Sf_TOOL
    .{ .from = 2376, .to = 3123 }, // MNU_Solver_TOOL        ToolS
    .{ .from = 2381, .to = 3021 }, // MNU_CASHFL             CASHFL
    .{ .from = 2382, .to = 3011 }, // MNU_AMORT              AMORT
    .{ .from = 2390, .to = 3015 }, // MNU_AUDIO              AUDIO
    .{ .from = 2403, .to = 3098 }, // MNU_PFN_3              P.FN3
    .{ .from = 2406, .to = 2953 }, // MNU_TAMMENU            TamMenu
    .{ .from = 2407, .to = 3082 }, // MNU_MENU               MENU
    .{ .from = 2414, .to = 3092 }, // MNU_NUMTHEORY          NumTh
    .{ .from = 2499, .to = 3140 }, // MNU_VECCONV
    .{ .from = 2552, .to = 3001 }, // MNU_AIMCATALOG
    .{ .from = 2596, .to = 3143 }, // MNU_XXFCNS             XFCNS
    .{ .from = 2597, .to = 3087 }, // MNU_MULTSTK            MULTSTK
    .{ .from = 2600, .to = 2990 }, // MNU_UNIFORM            Uniform:
    .{ .from = 2605, .to = 2978 }, // MNU_DISUNIFORM         DisUni:
    .{ .from = 2625, .to = 3050 }, // MNU_DEV                DEV
    .{ .from = 2638, .to = 2962 }, // MNU_TAMSTO_TVM         TamStoTvm
    .{ .from = 2639, .to = 2959 }, // MNU_TAMRCL_TVM         TamStoTvm
    .{ .from = 2681, .to = 3107 }, // MNU_PRINTER
    .{ .from = 2711, .to = 2957 }, // MNU_TAMNORM            TamNorm
    .{ .from = 2736, .to = 3017 }, // MNU_BASE2              BASE2
    .{ .from = 2738, .to = 2999 }, // MNU_42                 42
    .{ .from = 2844, .to = 3032 }, // MNU_CONV_SECTION       SecPrp:
    .{ .from = 2845, .to = 3030 }, // MNU_CONV_MATERL        MatPrp:
    .{ .from = 2846, .to = 3028 }, // MNU_CONV_F_LOAD        FLoads:
    .{ .from = 2847, .to = 3029 }, // MNU_CONV_M_LOAD        MLoads:
    .{ .from = 2848, .to = 3031 }, // MNU_CONV_P_LOAD        PLoads:
    .{ .from = 2849, .to = 3127 }, // MNU_STRUCT             Struct:
    .{ .from = 2859, .to = 2952 }, // MNU_TAMLOCALLABEL      TamLocalLabel
};

fn convertOldMenuLink(item: i16) i16 {
    if (item < 0) {
        const old: u16 = @intCast(-item);
        for (menuRenumberTable) |row| {
            if (row.from == old) return -@as(i16, @intCast(row.to));
            if (row.from > old) break; // the table is in ascending `from` order
        }
    }
    return item;
}

fn convertOldMenuItems(items: []userMenuItem_t) void {
    for (items) |*it| it.item = convertOldMenuLink(it.item);
}

fn convertOldMenuKeyboard(keys: []calcKey_t, norm_func: *i16) void {
    for (keys) |*key| {
        // keyId comes first and is a key number, never an item.
        const fields: *[8]i16 = @ptrCast(&key.primary);
        for (fields) |*field| field.* = convertOldMenuLink(field.*);
    }
    // The Norm key is written back into kbd_usr on the next TO_USER, so it converts too.
    norm_func.* = convertOldMenuLink(norm_func.*);
}

fn convertOldMenuConfigRegister(regist: i16) void {
    // STOCFG copied the whole user keyboard into the descriptor, and RCLCFG copies it back.
    if (getRegisterDataType(regist) != dtConfig) return;
    const cfg = abi.registerConfig(regist);
    convertOldMenuKeyboard(cfg.kbd_usr[0..], &cfg.Norm_Key_00.func);
}

/// Runs once after a file older than the renumbering has been read, so the menu
/// links it stored reach the menus they name.
pub export fn convertOldMenuNumbers() callconv(.c) void {
    convertOldMenuKeyboard(kbd_usr[0..], &Norm_Key_00.func);
    convertOldMenuItems(userMenuItems[0..]);
    convertOldMenuItems(userAlphaItems[0..]);
    if (userMenus != null) {
        // numberOfUserMenus comes from the file; clamp it to the space left after userMenus.
        const g = geometry();
        const menus_in_pool: u16 = @intCast((TO_BYTES(g.ram_size_in_blocks) - TO_BYTES(progmem.toC47memptr(g, @intFromPtr(userMenus)))) / @sizeOf(userMenu_t));
        const count = @min(numberOfUserMenus, menus_in_pool);
        var m: u16 = 0;
        while (m < count) : (m += 1) {
            convertOldMenuItems(userMenus[m].menuItem[0..]);
        }
    }
    var regist: i16 = FIRST_GLOBAL_REGISTER;
    while (regist <= LAST_GLOBAL_REGISTER) : (regist += 1) {
        convertOldMenuConfigRegister(regist);
    }
    var i: u16 = 0;
    while (i < currentNumberOfLocalRegisters()) : (i += 1) {
        convertOldMenuConfigRegister(FIRST_LOCAL_REGISTER + @as(i16, @intCast(i)));
    }
    i = 0;
    while (i < numberOfNamedVariables) : (i += 1) {
        convertOldMenuConfigRegister(FIRST_NAMED_VARIABLE + @as(i16, @intCast(i)));
    }
}

// --- OTHER_CONFIGURATION_STUFF scalars ---
extern var firstGregorianDay: u32;
extern var denMax: u32;
extern var lastDenominator: u32;
extern var displayFormat: u8;
extern var displayFormatDigits: u8;
extern var timeDisplayFormatDigits: u8;
extern var shortIntegerWordSize: u8;
extern var shortIntegerMode: u8;
extern var significantDigits: u8;
extern var fractionDigits: u8;
extern var currentAngularMode: c_int;
extern var gapItemLeft: u16;
extern var gapItemRight: u16;
extern var gapItemRadix: u16;
extern var lastCenturyHighUsed: u16;
extern var grpGroupingLeft: u8;
extern var grpGroupingGr1LeftOverflow: u8;
extern var grpGroupingGr1Left: u8;
extern var grpGroupingRight: u8;
extern var roundingMode: u8;
extern var displayStack: u8;
extern var exponentLimit: i16;
extern var exponentHideLimit: i16;
extern var lrSelection: u16;
extern var dispBase: u8;
extern var Input_Default: u8;
extern var displayStackSHOIDISP: u8;
extern var bcdDisplaySign: u8;
extern var DRG_Cycling: u8;
extern var DM_Cycling: u8;
extern var LongPressM: u8;
extern var LongPressF: u8;
extern var lastIntegerBase: u32;
extern var amortP1: u16;
extern var amortP2: u16;
extern var lrChosen: u16;
extern var graph_dx: f64;
extern var graph_dy: f64;
extern var roundedTicks: u8;
extern var PLOT_AXIS: u8;
extern var PLOT_ZMY: i8;
extern var firstDayOfWeek: u8;
extern var firstWeekOfYearDay: u8;

// printerState fields are enum-typed; set each through an enum-free trampoline.
extern var printerState: [16]u8; // {print_on@0:u8, printer_model@8, delay@12:u16}
fn setPrinterOn(v: u8) void {
    printerState[0] = v;
}
fn setPrinterModel(v: u8) void {
    printerState[8] = v;
}
fn setPrinterDelay(v: u16) void {
    @as(*u16, @ptrCast(@alignCast(&printerState[12]))).* = v;
}

fn cmpName(line: [*c]const u8, name: [*c]const u8) bool {
    return strcmp(line, name) == 0;
}

// Mirror of saveRestoreCalcState.c readLineSkippingComments: read a line, and
// while it is a "Cmnt" header drop the following comment-text line and read the
// next (real id/name, or another Cmnt). Lets a hand-edited register data-file
// carry comments between entries without throwing off the per-register count.
fn readLineSkippingComments(line: [*c]u8, max_len: usize) void {
    @setRuntimeSafety(true); // untrusted file input -- see calc_state.zig's panic decl
    calc_state.readLine(line, max_len);
    while (cmpName(line, "Cmnt")) {
        calc_state.readLine(line, max_len); // drop the comment text line
        calc_state.readLine(line, max_len); // next line: another Cmnt, or the real id / name
    }
}

fn b2i(x: bool) c_int {
    return @intFromBool(x);
}

// Program-memory pointer arithmetic, delegated to the geometry-parameterized,
// separately-tested progmem module (`zig build state-progmem-test`).
fn toPcmemptr(p: u32) [*c]u8 {
    @setRuntimeSafety(true); // untrusted file input -- see calc_state.zig's panic decl
    return @ptrFromInt(progmem.toPcmemptr(geometry(), @intCast(p)));
}
/// The pool pointer a saved (block, offset) pair names, or null if the pair is not
/// one the save format can have produced.
///
/// Upstream applies exactly this rule in its BACKUP owner (saveRestoreBackup.c:780)
/// and states the reason there: `saveCalc()` splits a pointer with TO_C47MEMPTR(),
/// which divides by the block size and stores the remainder as the offset, so an
/// offset is never a whole block or more, and a block index of RAM_SIZE_IN_BLOCKS
/// is the one-past-the-end position -- "every consumer here dereferences what it is
/// given". Its STATE owner reads the same two numbers, for the same globals, and
/// checks neither: `currentStep = TO_PCMEMPTR(toUint32(...))` followed by an
/// unbounded `currentStep += toUint32(...)` (saveRestoreCalcState.c:2086, 2103).
/// One operation, two owners, one of them checked -- finding 8's shape, inherited
/// from upstream rather than introduced here.
///
/// Reached by state_load_fuzz's programs_*_block_ffffffff.sav, where the port
/// trapped in the narrowing inside toPcmemptr. Trapping beats upstream's wild
/// pointer, but refusing beats both, and refusing is the rule upstream already
/// wrote down one file away. A valid save cannot be affected: its block indices are
/// inside the pool and its offsets are remainders below one block.
fn restoredPoolPointer(block: u32, offset: u32) ?[*c]u8 {
    @setRuntimeSafety(true); // untrusted file input -- see calc_state.zig's panic decl
    const geo = geometry();
    // `std.math.cast`, not `@intCast`: a block index too large to be one at all is
    // the same refusal as one outside the pool, and saying so with a checked cast
    // that RETURNS NULL keeps the whole function's answer in one shape. @intCast
    // would trap instead -- which is what this guard exists to stop -- and would
    // add a narrowing to the untrusted-file ratchet for a value the next line
    // already bounds.
    const blk = std.math.cast(u16, block) orelse return null;
    if (blk >= geo.ram_size_in_blocks or offset >= 4) {
        return null;
    }
    return @as([*c]u8, @ptrFromInt(progmem.toPcmemptr(geo, blk))) + offset;
}

fn toC47memptr(p: [*c]const u8) u16 {
    @setRuntimeSafety(true); // untrusted file input -- see calc_state.zig's panic decl
    return progmem.toC47memptr(geometry(), @intFromPtr(p));
}

pub fn restoreOneSection(load_mode: u16, s: u16, n: u16, d: u16, allow_user_keys: bool) bool {
    @setRuntimeSafety(true); // untrusted file input -- see calc_state.zig's panic decl
    const loaded_version = runtime.getLoadedVersion();
    const saved_calc_model = runtime.getSavedCalcModel();

    cancelFilename = true;
    hourGlassIconEnabled = true;
    calc_state.readLine(tmpString, TMP_STR_LENGTH);

    // A well-formed save file terminates with OTHER_CONFIGURATION_STUFF (handled
    // below, which returns false). An empty section-header line means the file
    // ended early (EOF / truncated): stop instead of spinning the doLoad section
    // loop forever. Never reached for valid files, so byte-faithful there.
    if (tmpString[0] == 0) {
        hourGlassIconEnabled = false;
        return false;
    }

    var i: i16 = 0;
    var numberOfRegs: i16 = 0;
    var str: [*c]u8 = undefined;
    var regist: i16 = 0;

    if (cmpName(tmpString, "GLOBAL_REGISTERS")) {
        calc_state.readLine(tmpString, TMP_STR_LENGTH);
        numberOfRegs = text.toInt16(tmpString);
        i = 0;
        while (i < numberOfRegs) : (i += 1) {
            readLineSkippingComments(tmpString, TMP_STR_LENGTH); // Register number, skipping any comments
            if (tmpString[0] == 0) { // the section ran out: readLine() skips blank lines, so an empty read is end of file and the count was a lie
                break;
            }
            regist = stringToRegisterNumber(tmpString); // "RX".."RW" or "Rnnn"
            calc_state.read2Lines(aimBuffer, AIM_BUFFER_LENGTH, tmpString, TMP_STR_LENGTH);
            if ((regist >= 0 and regist <= LAST_GLOBAL_REGISTER) and // reject an out-of-range register number from a malformed state file
                (load_mode == LM_ALL or
                    (load_mode == LM_REGISTERS and regist < REGISTER_X) or
                    (load_mode == LM_REGISTERS_PARTIAL and regist >= @as(i32, s) and regist < @as(i32, s) + @as(i32, n))))
            {
                // @intCast is correct here and must NOT become @truncate, even
                // though upstream saveRestoreCalcState.c:1635 narrows implicitly
                // into restoreRegister's int16_t parameter. The value provably
                // fits: the guard above bounds `regist` to [0, LAST_GLOBAL_REGISTER],
                // and `s`/`n`/`d` reach here only from fnRegCopy via getRegParam
                // (registers.c), which refuses anything with |x| >= 1000 and range-
                // checks the start against REGISTER_X / FIRST_LOCAL_REGISTER. So
                // the sum stays inside a few thousand and the cast cannot trap.
                //
                // Keeping the cast checked also pays for itself: writing @truncate
                // here discards the range LLVM was using downstream and cost 320
                // bytes of DMCP flash, measured. A narrowing that is provably in
                // range says something true about the code -- spell it @intCast.
                const target: i16 = if (load_mode == LM_REGISTERS_PARTIAL) @intCast(@as(i32, regist) - @as(i32, s) + @as(i32, d)) else regist;
                codec.restoreRegister(target, aimBuffer, tmpString, loaded_version);
                codec.restoreMatrixData(target);
            } else {
                codec.skipMatrixData(aimBuffer, tmpString);
            }
        }
    } else if (cmpName(tmpString, "GLOBAL_FLAGS")) {
        calc_state.readLine(tmpString, TMP_STR_LENGTH);
        if (load_mode == LM_ALL or load_mode == LM_SYSTEM_STATE) {
            str = tmpString;
            i = 0;
            while (i < 7) : (i += 1) {
                globalFlags[@intCast(i)] = text.toUint16(str);
                str = text.nextWord(str);
            }
            globalFlags[@intCast(i)] = text.toUint16(str);
        }
    } else if (cmpName(tmpString, "LOCAL_REGISTERS")) {
        calc_state.readLine(tmpString, TMP_STR_LENGTH);
        numberOfRegs = text.toInt16(tmpString);
        if (load_mode == LM_ALL or load_mode == LM_REGISTERS) {
            // The count is signed on the way in and unsigned on the way out, so a
            // negative line arrives as a large request and is refused by the
            // callee's "up to 99" test instead of trapping the cast.
            allocateLocalRegisters(@bitCast(numberOfRegs));
        }
        if ((load_mode != LM_ALL and load_mode != LM_REGISTERS) or lastErrorCode == ERROR_NONE) {
            i = 0;
            while (i < numberOfRegs) : (i += 1) {
                calc_state.readLine(tmpString, TMP_STR_LENGTH);
                if (tmpString[0] == 0) { // end of file: the count was a lie, see GLOBAL_REGISTERS
                    break;
                }
                regist = text.toInt16(tmpString + 2) + FIRST_LOCAL_REGISTER;
                calc_state.read2Lines(aimBuffer, AIM_BUFFER_LENGTH, tmpString, TMP_STR_LENGTH);
                if ((regist >= FIRST_LOCAL_REGISTER and regist < FIRST_LOCAL_REGISTER + @as(i16, @intCast(currentNumberOfLocalRegisters()))) and // reject an out-of-range register number from a malformed state file
                    (load_mode == LM_ALL or load_mode == LM_REGISTERS))
                {
                    codec.restoreRegister(regist, aimBuffer, tmpString, loaded_version);
                    codec.restoreMatrixData(regist);
                } else {
                    codec.skipMatrixData(aimBuffer, tmpString);
                }
            }
        }
    } else if (cmpName(tmpString, "LOCAL_FLAGS")) {
        calc_state.readLine(tmpString, TMP_STR_LENGTH);
        if (load_mode == LM_ALL or load_mode == LM_REGISTERS) {
            currentLocalFlags.?.* = text.toUint32(tmpString);
        }
    } else if (cmpName(tmpString, "NAMED_VARIABLES")) {
        calc_state.readLine(tmpString, TMP_STR_LENGTH);
        numberOfRegs = text.toInt16(tmpString);
        i = 0;
        while (i < numberOfRegs) : (i += 1) {
            calc_state.readLine(errorMessage, ERROR_MESSAGE_LENGTH);
            if (errorMessage[0] == 0) { // end of file: the count was a lie, see GLOBAL_REGISTERS
                break;
            }
            calc_state.read2Lines(aimBuffer, AIM_BUFFER_LENGTH, tmpString, TMP_STR_LENGTH);
            const is_stats_or_histo = cmpName(errorMessage, "STATS") or cmpName(errorMessage, "HISTO");
            if ((load_mode == LM_ALL or
                load_mode == LM_NAMED_VARIABLES or
                (load_mode == LM_SUMS and is_stats_or_histo)) and
                !(load_mode == LM_NAMED_VARIABLES and is_stats_or_histo))
            {
                const varName: [*c]u8 = errorMessage + strlen(errorMessage) + 1;
                utf8ToString(errorMessage, varName);
                regist = findOrAllocateNamedVariable(varName);
                if (regist != INVALID_VARIABLE) {
                    codec.restoreRegister(regist, aimBuffer, tmpString, loaded_version);
                    codec.restoreMatrixData(regist);
                } else {
                    codec.skipMatrixData(aimBuffer, tmpString);
                }
            } else {
                codec.skipMatrixData(aimBuffer, tmpString);
            }
        }
    } else if (cmpName(tmpString, "Cmnt")) {
        calc_state.readLine(tmpString, TMP_STR_LENGTH); // discard the single comment line that follows
        // falls through to the common `return true` so the load loop continues
    } else if (cmpName(tmpString, "STATISTICAL_SUMS")) {
        calc_state.readLine(tmpString, TMP_STR_LENGTH);
        numberOfRegs = text.toInt16(tmpString);
        if (numberOfRegs > 0 and (load_mode == LM_ALL or load_mode == LM_SUMS)) {
            initStatisticalSums();
            reLoadStatisticalSums();
            i = 0;
            while (i < numberOfRegs) : (i += 1) {
                calc_state.readLine(tmpString, TMP_STR_LENGTH);
                if (tmpString[0] == 0) { // end of file: the count was a lie, see GLOBAL_REGISTERS
                    break;
                }
                // statisticalSumsPointer is one pool block of NUMBER_OF_STATISTICAL_SUMS
                // reals and the save side always writes exactly that many; the count is
                // the file's. Bound the write, not the loop, which must still read a line
                // per claimed entry to stay aligned with the stream.
                if (statisticalSumsPointer != null and i < NUMBER_OF_STATISTICAL_SUMS) {
                    if (load_mode == LM_ALL or load_mode == LM_SUMS) {
                        codec.loadStatSum(tmpString, @intCast(i));
                    }
                }
            }
        }
    } else if (cmpName(tmpString, "SYSTEM_FLAGS")) {
        calc_state.readLine(tmpString, TMP_STR_LENGTH);
        if (load_mode == LM_ALL or load_mode == LM_SYSTEM_STATE) {
            systemFlags0 = calc_state.stringToUint64(tmpString);
            systemFlags1 = 0;
            if (loaded_version < 10000006) defaultStatusBar();
            if (loaded_version < 10000009) setSystemFlag(FLAG_MONIT);
        }
    } else if (cmpName(tmpString, "SYSTEM_FLAGS1")) {
        calc_state.readLine(tmpString, TMP_STR_LENGTH);
        if (load_mode == LM_ALL or load_mode == LM_SYSTEM_STATE) {
            systemFlags1 = calc_state.stringToUint64(tmpString);
            if (loaded_version < 10000006) defaultStatusBar();
            if (loaded_version < 10000009) setSystemFlag(FLAG_MONIT);
            if (loaded_version < 10000012) {
                clearSystemFlag(FLAG_IRFRAC);
                clearSystemFlag(FLAG_IRFRQ);
            }
            if (loaded_version < 10000024) setSystemFlag(FLAG_SIGZEROS); // C saveRestoreCalcState.c:1738-1740
            // The angular mode annunciator is on per default.
            if (loaded_version < 10000026) setSystemFlag(FLAG_SBadm); // C saveRestoreCalcState.c:1741-1743
            // Inclusive of this version, set the M.ALL.
            if (loaded_version < 10000027) setSystemFlag(FLAG_M_ALL);
            if (getSystemFlag(@intCast(FLAG_FRACT))) {
                setSystemFlag(FLAG_FRACT);
            } else if (getSystemFlag(@intCast(FLAG_IRFRAC))) {
                setSystemFlag(FLAG_IRFRAC);
            }
        }
    } else if (cmpName(tmpString, "KEYBOARD_ASSIGNMENTS")) {
        calc_state.readLine(tmpString, TMP_STR_LENGTH);
        numberOfRegs = text.toInt16(tmpString);
        i = 0;
        while (i < numberOfRegs) : (i += 1) {
            calc_state.readLine(tmpString, TMP_STR_LENGTH);
            if (tmpString[0] == 0) { // end of file: the count was a lie, see GLOBAL_REGISTERS
                break;
            }
            // The count is the file's, so the index is bounded here and not on the
            // loop, which must still read a line per claimed entry to stay aligned.
            if (allow_user_keys and i < @as(i16, kbd_usr.len) and (load_mode == LM_ALL or load_mode == LM_SYSTEM_STATE)) {
                const k = &kbd_usr[@intCast(i)];
                str = text.toInt16NextWord(tmpString, &k.keyId);
                str = text.toInt16NextWord(str, &k.primary);
                str = text.toInt16NextWord(str, &k.fShifted);
                str = text.toInt16NextWord(str, &k.gShifted);
                str = text.toInt16NextWord(str, &k.keyLblAim);
                str = text.toInt16NextWord(str, &k.primaryAim);
                str = text.toInt16NextWord(str, &k.fShiftedAim);
                str = text.toInt16NextWord(str, &k.gShiftedAim);
                str = text.toInt16NextWord(str, &k.primaryTam);
            }
        }
    } else if (cmpName(tmpString, "KEYBOARD_ARGUMENTS")) {
        calc_state.readLine(tmpString, TMP_STR_LENGTH);
        numberOfRegs = text.toInt16(tmpString);
        if (allow_user_keys and (load_mode == LM_ALL or load_mode == LM_SYSTEM_STATE)) {
            freeC47Blocks(userKeyLabel, TO_BLOCKS(userKeyLabelSize));
            userKeyLabelSize = 37 * 6 * 1 + 1;
            userKeyLabel = @ptrCast(allocC47Blocks(TO_BLOCKS(userKeyLabelSize)));
            if (userKeyLabel == null) { // the memset below writes through this pointer, and this section's entries then walk it
                userKeyLabelSize = 0;
                displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, REGISTER_X);
            } else {
                _ = memset(userKeyLabel, 0, TO_BYTES(TO_BLOCKS(userKeyLabelSize)));
            }
        }
        i = 0;
        while (i < numberOfRegs) : (i += 1) {
            calc_state.readLine(tmpString, TMP_STR_LENGTH);
            if (tmpString[0] == 0) { // end of file: the count was a lie, see GLOBAL_REGISTERS
                break;
            }
            if (allow_user_keys and (load_mode == LM_ALL or load_mode == LM_SYSTEM_STATE)) {
                str = tmpString;
                const key = text.toUint16(str);
                // The count is key/state slots, of which the save side writes up to
                // 37*6, so it runs far past userMenuItems; MYMENU restores that array
                // in its own section.
                if (i < @as(i16, userMenuItems.len)) {
                    userMenuItems[@intCast(i)].argumentName[0] = 0;
                }
                str = text.skipToSpaceNewline(str);
                if (str[0] == ' ') {
                    str = text.skipSpace(str);
                    // 37*6 is the ceiling userKeyLabel is allocated to above, and the one
                    // setUserKeyArgument walks to; the key comes from the file.
                    if (str[0] != '\n' and str[0] != 0 and key < 37 * 6) {
                        utf8ToStringWithLength(str, tmpString + TMP_STR_LENGTH / 2, @sizeOf(@TypeOf(userMenuItems[0].argumentName)));
                        setUserKeyArgument(key, tmpString + TMP_STR_LENGTH / 2);
                    }
                }
            }
        }
    } else if (cmpName(tmpString, "MYMENU")) {
        calc_state.readLine(tmpString, TMP_STR_LENGTH);
        numberOfRegs = text.toInt16(tmpString);
        i = 0;
        while (i < numberOfRegs) : (i += 1) {
            calc_state.readLine(tmpString, TMP_STR_LENGTH);
            if (tmpString[0] == 0) { // end of file: the count was a lie, see GLOBAL_REGISTERS
                break;
            }
            // 18 is what MYMENU can hold and what the save side writes; the count is
            // the file's. Bound the write and not the loop.
            if ((load_mode == LM_ALL or load_mode == LM_SYSTEM_STATE) and i < @as(i16, userMenuItems.len)) {
                parseMenuItem(&userMenuItems[@intCast(i)]);
            }
        }
    } else if (cmpName(tmpString, "MYALPHA")) {
        calc_state.readLine(tmpString, TMP_STR_LENGTH);
        numberOfRegs = text.toInt16(tmpString);
        i = 0;
        while (i < numberOfRegs) : (i += 1) {
            calc_state.readLine(tmpString, TMP_STR_LENGTH);
            if (tmpString[0] == 0) { // end of file: the count was a lie, see GLOBAL_REGISTERS
                break;
            }
            // Same bound as MYMENU above, on the array MYALPHA owns.
            if ((load_mode == LM_ALL or load_mode == LM_SYSTEM_STATE) and i < @as(i16, userAlphaItems.len)) {
                parseMenuItem(&userAlphaItems[@intCast(i)]);
            }
        }
    } else if (cmpName(tmpString, "USER_MENUS")) {
        calc_state.readLine(tmpString, TMP_STR_LENGTH);
        const numberOfMenus = text.toInt16(tmpString);
        var j: i32 = 0;
        while (j < numberOfMenus) : (j += 1) {
            calc_state.readLine(tmpString, TMP_STR_LENGTH);
            if (tmpString[0] == 0) { // end of file: the count was a lie, see GLOBAL_REGISTERS
                break;
            }
            var target: i16 = -1;
            if (load_mode == LM_ALL or load_mode == LM_SYSTEM_STATE) {
                utf8ToStringWithLength(tmpString, tmpString + TMP_STR_LENGTH / 2, TMP_STR_LENGTH / 2);
                i = 0;
                while (i < numberOfUserMenus) : (i += 1) {
                    if (compareString(tmpString + TMP_STR_LENGTH / 2, &userMenus[@intCast(i)].menuName[0], CMP_NAME) == 0) {
                        target = i;
                    }
                }
                if (target == -1) {
                    // createMenu() refuses a name the file made invalid, and then
                    // numberOfUserMenus - 1 is either -1, with userMenus still NULL, or an
                    // unrelated menu that would silently take this one's items. Leave
                    // target at -1 and drop the menu instead.
                    const menusBefore = numberOfUserMenus;
                    createMenu(tmpString + TMP_STR_LENGTH / 2);
                    target = if (numberOfUserMenus <= menusBefore) -1 else @intCast(@as(i32, numberOfUserMenus) - 1);
                }
            }
            calc_state.readLine(tmpString, TMP_STR_LENGTH);
            numberOfRegs = text.toInt16(tmpString);
            i = 0;
            while (i < numberOfRegs) : (i += 1) {
                calc_state.readLine(tmpString, TMP_STR_LENGTH);
                if (tmpString[0] == 0) { // end of file: the count was a lie, see GLOBAL_REGISTERS
                    break;
                }
                // A user menu holds 18 items, as MYMENU and MYALPHA do; the count and
                // the menu name are the file's. userMenus is ONE pool block holding
                // every menu, so an unbounded index writes over the menus that follow
                // this one and, past the last of them, out of the block.
                if ((load_mode == LM_ALL or load_mode == LM_SYSTEM_STATE) and target >= 0 and
                    i < @as(i16, @sizeOf(@TypeOf(userMenus[0].menuItem)) / @sizeOf(userMenuItem_t)))
                {
                    parseMenuItem(&userMenus[@intCast(target)].menuItem[@intCast(i)]);
                }
            }
        }
    } else if (cmpName(tmpString, "PROGRAMS")) {
        restoreProgramsSection(load_mode);
    } else if (cmpName(tmpString, "EQUATIONS")) {
        calc_state.readLine(tmpString, TMP_STR_LENGTH);
        const formulae = text.toUint16(tmpString);
        if (formulae > 0 and (load_mode == LM_ALL or load_mode == LM_PROGRAMS)) {
            // @bitCast, not @intCast: upstream saveRestoreCalcState.c:2216 is
            // `for(i = numberOfFormulae; i > 0; --i)` with `int16_t i` (:1602) and
            // `uint16_t numberOfFormulae`, so C narrows implicitly and the two
            // 16-bit types reinterpret rather than trap. Upstream is aware of the
            // width -- its comment at :2236 uses a wider `uint32_t f` for the
            // FORWARD loop for exactly this reason -- but left this one narrow, so
            // matching it is the parity-correct port. Latent rather than
            // reachable: a count above 32767 needs an allocation the pool refuses.
            i = @bitCast(numberOfFormulae);
            while (i > 0) : (i -= 1) {
                deleteEquation(@intCast(i - 1));
            }
            // The count is the file's, so the size of this allocation is too, and
            // allocC47Blocks() answers NULL when the pool cannot hold it -- a state
            // file claiming 65535 formulae asks for 256 KiB of a 256 KiB pool. The
            // loop below writes through that pointer, so take no equations rather
            // than write through NULL; the rest of the section still reads its lines
            // and discards them, which keeps the parser aligned with the stream.
            allFormulae = @ptrCast(@alignCast(allocC47Blocks(TO_BLOCKS(@sizeOf(formulaHeader_t)) * formulae)));
            if (allFormulae == null) {
                numberOfFormulae = 0;
                currentFormula = 0;
                displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, REGISTER_X);
            } else {
                numberOfFormulae = formulae;
                currentFormula = 0;
                // The index is wider than the count on purpose: `formulae` is a u16 and
                // this section's own `i` is an i16, so a file claiming more than 32767
                // formulae would run i past its max and the loop would never end.
                var f: u32 = 0;
                while (f < formulae) : (f += 1) {
                    allFormulae[f].pointerToFormulaData = C47_NULL;
                    allFormulae[f].sizeInBlocks = 0;
                }
            }
            var f: u32 = 0;
            while (f < formulae) : (f += 1) { // u32, as above
                calc_state.readLine(tmpString, TMP_STR_LENGTH);
                // No end-of-file break here, on purpose: the empty reads give every
                // remaining formula an empty string, which every reader of the text
                // handles; breaking would leave them at the C47_NULL set above, and not
                // every reader of that pointer tests it. allFormulae is NULL when the
                // allocation was refused, and setEquation() indexes it, so a refused
                // section costs the equations and nothing else.
                if (allFormulae != null and (load_mode == LM_ALL or load_mode == LM_PROGRAMS)) {
                    utf8ToStringWithLength(tmpString, tmpString + TMP_STR_LENGTH / 2, TMP_STR_LENGTH / 2);
                    setEquation(@intCast(f), tmpString + TMP_STR_LENGTH / 2);
                }
            }
            if (loaded_version < 10000021) {
                updateConstantsInEquations();
            }
        }
    } else if (cmpName(tmpString, "C47/R47_data_file_00")) {
        // A DATA file's version line pair. The state file carries its version in
        // the header (calc_state_header.zig); a data file carries it as a section,
        // so it arrives here instead. Without this branch the version line was
        // read as an unknown section and dropped, and every data file written by a
        // real C47 loaded as if it had no version at all.
        //
        // Same numbering and bounds as the state file: outside them the version is
        // treated as absent rather than trusted.
        calc_state.readLine(tmpString, TMP_STR_LENGTH);
        var version = text.toUint32(tmpString);
        if (version < 10000000 or version > 20000000) {
            version = 0;
        }
        runtime.setLoadedVersion(version);
    } else if (cmpName(tmpString, "OTHER_CONFIGURATION_STUFF")) {
        restoreOtherConfiguration(load_mode, allow_user_keys, loaded_version, saved_calc_model);
        hourGlassIconEnabled = false;
        return false; // terminal section
    }

    hourGlassIconEnabled = false;
    return true;
}

// MYMENU / MYALPHA / per-user-menu item: `item` then an optional space + utf8
// argument name.
fn parseMenuItem(item: [*c]userMenuItem_t) void {
    @setRuntimeSafety(true); // untrusted file input -- see calc_state.zig's panic decl
    var str: [*c]u8 = tmpString;
    item[0].item = text.toInt16(str);
    item[0].argumentName[0] = 0;
    str = text.skipToSpaceNewline(str);
    if (str[0] == ' ') {
        str = text.skipSpace(str);
        if (str[0] != '\n' and str[0] != 0) {
            utf8ToStringWithLength(str, &item[0].argumentName[0], @sizeOf(@TypeOf(item[0].argumentName)));
        }
    }
}

fn restoreProgramsSection(load_mode: u16) void {
    @setRuntimeSafety(true); // untrusted file input -- see calc_state.zig's panic decl
    const oldSizeInBlocks: u16 = progmem.programSizeInBlocks(geometry(), @intFromPtr(beginOfProgramMemory));
    var oldFirstFreeProgramByte: [*c]u8 = firstFreeProgramByte;
    const oldFreeProgramBytes: u16 = freeProgramBytes;

    calc_state.readLine(tmpString, TMP_STR_LENGTH);
    const numberOfBlocks = text.toUint16(tmpString);
    // Program memory always holds at least the one block that carries the empty
    // .END.: that is the block config.c reserves when it forms the pool, and the
    // save side writes that 1 for an empty program area. A count of zero therefore
    // means the section is not really there -- and a section that ran out reads as
    // zero too, because an empty read converts to zero. Resizing to zero blocks
    // moves beginOfProgramMemory one past the pool, and scanLabelsAndPrograms()
    // reads it there through isAtEndOfPrograms(). Everything this branch does is
    // keyed on the load mode, so such a section is neutralised by giving the branch
    // a mode that matches neither LM_ALL nor LM_PROGRAMS. The readLine() calls still
    // run, so the parser stays aligned with the stream, and program memory keeps
    // what it already had.
    // A LM_PROGRAMS load APPENDS, so upstream saveRestoreCalcState.c:2080 resizes
    // to `oldSizeInBlocks + numberOfBlocks` through a uint16_t parameter
    // (memory.c:158): C promotes to int and truncates on the way back in. Both
    // operands can be large -- numberOfBlocks is toUint16 of a line the file
    // supplies, and oldSizeInBlocks reaches RAM_SIZE_IN_BLOCKS (65534) -- so a
    // crafted count pushes the sum past 65535 and program memory ends up sized by
    // the truncated total while the block loop below still writes numberOfBlocks
    // blocks, straight past the end of the pool. That is an out-of-bounds WRITE,
    // and state_load_fuzz reaches it: count_programs_65535.sav under LM_PROGRAMS
    // segfaulted before this guard.
    //
    // Upstream's own comment on that loop states the invariant it relies on --
    // "this loop writes into memory resizeProgramMemory() sized from the same
    // count" -- so refusing a section whose sum cannot hold restores that
    // invariant rather than inventing a new rule, in the spirit of 31fb6f755.
    // Neutralise it exactly as a zero count is neutralised above: a mode matching
    // neither LM_ALL nor LM_PROGRAMS leaves program memory untouched while the
    // readLine() calls keep the parser aligned with the stream.
    const appendedBlocks: u32 = @as(u32, oldSizeInBlocks) + numberOfBlocks;
    const programsLoadMode: u16 = if (numberOfBlocks == 0 or
        (load_mode == LM_PROGRAMS and appendedBlocks > std.math.maxInt(u16)))
        LM_SYSTEM_STATE
    else
        load_mode;
    if (programsLoadMode == LM_ALL) {
        resizeProgramMemory(numberOfBlocks);
    } else if (programsLoadMode == LM_PROGRAMS) {
        // No cast at all, where upstream needs one and the port used to @truncate:
        // the guard above refused every sum that does not fit, so this u16 addition
        // provably cannot overflow. Zig's checked add stays as the backstop if that
        // guard is ever weakened, and the narrowing simply stops existing rather
        // than being argued about.
        resizeProgramMemory(oldSizeInBlocks + numberOfBlocks);
        oldFirstFreeProgramByte = beginOfProgramMemory + TO_BYTES(oldSizeInBlocks) - oldFreeProgramBytes - 2;
    }

    calc_state.readLine(tmpString, TMP_STR_LENGTH); // currentStep block pointer
    const currentStepBlock = text.toUint32(tmpString);
    calc_state.readLine(tmpString, TMP_STR_LENGTH); // currentStep offset within block
    const currentStepOffset = text.toUint32(tmpString);
    if (programsLoadMode == LM_ALL) {
        if (restoredPoolPointer(currentStepBlock, currentStepOffset)) |p| {
            currentStep = p;
        }
    } else if (programsLoadMode == LM_PROGRAMS) {
        if (programList[@intCast(@as(i32, currentProgramNumber) - 1)].step > 0) {
            currentStep -= TO_BYTES(numberOfBlocks);
            firstDisplayedStep -= TO_BYTES(numberOfBlocks);
            beginOfCurrentProgram -= TO_BYTES(numberOfBlocks);
            endOfCurrentProgram -= TO_BYTES(numberOfBlocks);
        }
    }

    calc_state.readLine(tmpString, TMP_STR_LENGTH); // firstFreeProgramByte block pointer
    const firstFreeBlock = text.toUint32(tmpString);
    calc_state.readLine(tmpString, TMP_STR_LENGTH); // firstFreeProgramByte offset within block
    const firstFreeOffset = text.toUint32(tmpString);
    if (programsLoadMode == LM_ALL or programsLoadMode == LM_PROGRAMS) {
        if (restoredPoolPointer(firstFreeBlock, firstFreeOffset)) |p| {
            firstFreeProgramByte = p;
        }
    }

    calc_state.readLine(tmpString, TMP_STR_LENGTH); // freeProgramBytes
    if (programsLoadMode == LM_ALL or programsLoadMode == LM_PROGRAMS) {
        freeProgramBytes = text.toUint16(tmpString);
    }

    // Cross-hardware RAM-size relocation correction (sign differs OLD_HW vs
    // NEW_HW); the geometry-parameterized progmem module covers both lanes and
    // is verified by `zig build state-progmem-test`.
    {
        const reloc = progmem.relocatePrograms(.{
            .first_free_program_byte = @intFromPtr(firstFreeProgramByte),
            .free_program_bytes = freeProgramBytes,
            .begin_of_program_memory = @intFromPtr(beginOfProgramMemory),
            .number_of_blocks = numberOfBlocks,
            .current_step = @intFromPtr(currentStep),
        }, state_old_hw);
        currentStep = @ptrFromInt(reloc.current_step);
        firstFreeProgramByte = @ptrFromInt(reloc.first_free_program_byte);
    }

    if (programsLoadMode == LM_PROGRAMS) {
        freeProgramBytes += oldFreeProgramBytes;
        const at_end = (@intFromPtr(oldFirstFreeProgramByte) >= @intFromPtr(beginOfProgramMemory + 2)) and isAtEndOfProgram(oldFirstFreeProgramByte - 2);
        if (!at_end) {
            if (oldFreeProgramBytes + freeProgramBytes < 2) {
                const tmpFreeProgramBytes = freeProgramBytes;
                // Same narrowing as the LM_PROGRAMS resize above; upstream
                // saveRestoreCalcState.c:2138.
                resizeProgramMemory(@truncate(@as(u32, oldSizeInBlocks) + numberOfBlocks + 1));
                oldFirstFreeProgramByte -= 4;
                freeProgramBytes = tmpFreeProgramBytes + 4;
                if (programList[@intCast(@as(i32, currentProgramNumber) - 1)].step > 0) {
                    currentStep -= 4;
                    firstDisplayedStep -= 4;
                    beginOfCurrentProgram -= 4;
                    endOfCurrentProgram -= 4;
                }
            }
            oldFirstFreeProgramByte[0] = @intCast((@as(u32, @bitCast(ITM_END)) >> 8) | 0x80);
            oldFirstFreeProgramByte[1] = @intCast(@as(u32, @bitCast(ITM_END)) & 0xff);
            freeProgramBytes -= 2;
            oldFirstFreeProgramByte += 2;
        }
    }

    const progWords: [*c]u32 = @ptrCast(@alignCast(beginOfProgramMemory));
    // i32, where upstream's loop counter is the enclosing function's `int16_t i`
    // (saveRestoreCalcState.c:1602). numberOfBlocks is a uint16_t and program
    // memory legitimately reaches RAM_SIZE_IN_BLOCKS (65534), so an int16_t
    // counter cannot express the loop's own bound: past 32767 upstream's `i++`
    // overflows and the comparison against a uint16_t never comes true, leaving a
    // state file with a large program area spinning forever. This is not
    // malformed-input hardening -- a file a real calculator SAVED can carry such
    // a count. Widening terminates the loop after exactly numberOfBlocks
    // iterations, which is what every line of the body already assumes; for the
    // counts upstream can actually finish, the two are identical.
    var i: i32 = 0;
    while (i < numberOfBlocks) : (i += 1) {
        calc_state.readLine(tmpString, TMP_STR_LENGTH);
        if (programsLoadMode == LM_ALL) {
            progWords[@intCast(i)] = text.toUint32(tmpString);
        } else if (programsLoadMode == LM_PROGRAMS) {
            var tmpBlock: u32 = text.toUint32(tmpString);
            _ = xcopy(oldFirstFreeProgramByte + TO_BYTES(i), &tmpBlock, 4);
        }
    }

    if (programsLoadMode == LM_ALL or programsLoadMode == LM_PROGRAMS) {
        scanLabelsAndPrograms(); // selects the program around the restored step
        // The step pointer comes from the file and not the step number, so the step number is counted from the pointer
        // and the listing is set to that step.
        currentLocalStepNumber = 1;
        if (@intFromPtr(currentStep) >= @intFromPtr(beginOfCurrentProgram) and @intFromPtr(currentStep) < @intFromPtr(endOfCurrentProgram)) {
            var step: [*c]u8 = beginOfCurrentProgram;
            while (step != null and @intFromPtr(step) < @intFromPtr(currentStep)) : (step = findNextStep(step)) {
                currentLocalStepNumber += 1;
            }
        } else { // the pointer is outside this program
            currentStep = programList[0].instructionPointer;
            defineCurrentProgramFromCurrentStep();
        }
        firstDisplayedLocalStepNumber = if (currentLocalStepNumber >= 3) currentLocalStepNumber - 3 else 0;
        defineFirstDisplayedStep();
        pemCursorIsZerothStep = false; // the file does not carry it
    }
}

fn restoreOtherConfiguration(load_mode: u16, allow_user_keys: bool, loaded_version: u32, saved_calc_model: u16) void {
    @setRuntimeSafety(true); // untrusted file input -- see calc_state.zig's panic decl
    calc_state.readLine(tmpString, TMP_STR_LENGTH); // count (unused)

    calc_state.readLine(aimBuffer, AIM_BUFFER_LENGTH); // duplicated param / END marker
    if (cmpName(aimBuffer, "END_OTHER_PARAM")) {
        return; // short-form key-only state files: no reset
    }
    resetOtherConfigurationStuff(allow_user_keys);
    calc_state.readLine(tmpString, TMP_STR_LENGTH); // duplicated 00

    var i: u32 = 0;
    while (i < 255) : (i += 1) {
        calc_state.readLine(aimBuffer, AIM_BUFFER_LENGTH); // param
        if (cmpName(aimBuffer, "END_OTHER_PARAM") or aimBuffer[0] == 0) {
            break;
        }
        calc_state.readLine(tmpString, TMP_STR_LENGTH); // value
        if (load_mode == LM_ALL or load_mode == LM_SYSTEM_STATE) {
            applyConfigField(loaded_version, allow_user_keys, saved_calc_model);
            hourGlassIconEnabled = false;
        }
    }
}

fn matchU8(name: [*c]const u8, ptr: anytype) bool {
    if (cmpName(aimBuffer, name)) {
        ptr.* = text.toUint8(tmpString);
        return true;
    }
    return false;
}

fn applyConfigField(loaded_version: u32, allow_user_keys: bool, saved_calc_model: u16) void {
    @setRuntimeSafety(true); // untrusted file input -- see calc_state.zig's panic decl
    const ab = aimBuffer;
    if (cmpName(ab, "firstGregorianDay")) {
        firstGregorianDay = text.toUint32(tmpString);
    } else if (cmpName(ab, "denMax")) {
        denMax = text.toUint32(tmpString);
        if (denMax == 1 or denMax > MAX_DENMAX) denMax = MAX_DENMAX;
    } else if (cmpName(ab, "lastDenominator")) {
        lastDenominator = text.toUint32(tmpString);
        if (lastDenominator < 1 or lastDenominator > MAX_DENMAX) lastDenominator = 4;
    } else if (matchU8("displayFormat", &displayFormat)) {} else if (matchU8("displayFormatDigits", &displayFormatDigits)) {} else if (matchU8("timeDisplayFormatDigits", &timeDisplayFormatDigits)) {} else if (cmpName(ab, "shortIntegerWordSize")) {
        shortIntegerWordSize = boundShortIntegerWordSize(text.toUint8(tmpString));
    } else if (matchU8("shortIntegerMode", &shortIntegerMode)) {} else if (matchU8("significantDigits", &significantDigits)) {} else if (matchU8("fractionDigits", &fractionDigits)) {} else if (cmpName(ab, "currentAngularMode")) {
        currentAngularMode = text.toUint8(tmpString);
    } else if (cmpName(ab, "groupingGap")) {
        configCommon(CFG_DFLT);
        grpGroupingLeft = text.toUint8(tmpString);
        grpGroupingRight = grpGroupingLeft;
    } else if (text.strcmp2(ab, @constCast("gapItemLeft")) == 0) {
        gapItemLeft = text.toUint16(tmpString);
    } else if (text.strcmp2(ab, @constCast("gapItemRight")) == 0) {
        gapItemRight = text.toUint16(tmpString);
    } else if (text.strcmp2(ab, @constCast("gapItemRadix")) == 0) {
        gapItemRadix = text.toUint16(tmpString);
    } else if (text.strcmp2(ab, @constCast("lastCenturyHighUsed")) == 0) {
        lastCenturyHighUsed = text.toUint16(tmpString);
    } else if (text.strcmp2(ab, @constCast("grpGroupingLeft")) == 0) {
        grpGroupingLeft = text.toUint8(tmpString);
    } else if (text.strcmp2(ab, @constCast("grpGroupingGr1LeftOverflow")) == 0) {
        grpGroupingGr1LeftOverflow = text.toUint8(tmpString);
    } else if (text.strcmp2(ab, @constCast("grpGroupingGr1Left")) == 0) {
        grpGroupingGr1Left = text.toUint8(tmpString);
    } else if (text.strcmp2(ab, @constCast("grpGroupingRight")) == 0) {
        grpGroupingRight = text.toUint8(tmpString);
    } else if (matchU8("roundingMode", &roundingMode)) {} else if (matchU8("displayStack", &displayStack)) {} else if (cmpName(ab, "rngState")) {
        pcg32_global.state = calc_state.stringToUint64(tmpString);
        const w = text.nextWord(tmpString);
        pcg32_global.inc = calc_state.stringToUint64(w);
    } else if (cmpName(ab, "exponentLimit")) {
        exponentLimit = text.toInt16(tmpString);
    } else if (cmpName(ab, "exponentHideLimit")) {
        exponentHideLimit = text.toInt16(tmpString);
    } else if (cmpName(ab, "notBestF")) {
        lrSelection = text.toUint16(tmpString);
    } else if (cmpName(ab, "bestF")) {
        lrSelection = text.toUint16(tmpString);
    } else if (cmpName(ab, "fgLN") or cmpName(ab, "jm_FG_LINE")) {
        const fgLN = calc_state.convert001090400T001090500(text.toUint8(tmpString), RBX_FGLNOFF);
        if (fgLN == RBX_FGLNOFF) {
            clearSystemFlag(FLAG_FGLNLIM);
            clearSystemFlag(FLAG_FGLNFUL);
        } else if (fgLN == RBX_FGLNLIM) {
            setSystemFlag(FLAG_FGLNLIM);
            clearSystemFlag(FLAG_FGLNFUL);
        } else if (fgLN == RBX_FGLNFUL) {
            clearSystemFlag(FLAG_FGLNLIM);
            setSystemFlag(FLAG_FGLNFUL);
        }
    } else if (cmpName(ab, "HOME3")) {
        if (loaded_version < 10000022) {
            forceSystemFlag(FLAG_HOME_TRIPLE, @intFromBool(text.toUint8(tmpString) != 0));
            setLongPressFg(calcModel, -MNU_HOME);
        }
    } else if (cmpName(ab, "MYM3")) {
        if (loaded_version < 10000022) {
            forceSystemFlag(FLAG_MYM_TRIPLE, @intFromBool(text.toUint8(tmpString) != 0));
            setLongPressFg(calcModel, -MNU_MyMenu);
        }
    } else if (cmpName(ab, "dispBase")) {
        dispBase = text.toUint8(tmpString);
    } else if (cmpName(ab, "ShiftTimoutMode")) {
        if (loaded_version < 10000022) forceSystemFlag(FLAG_SHFT_4s, @intFromBool(text.toUint8(tmpString) != 0));
    } else if (cmpName(ab, "SH_BASE_HOME")) {
        if (loaded_version < 10000022) forceSystemFlag(FLAG_BASE_HOME, @intFromBool(text.toUint8(tmpString) != 0));
    } else if (cmpName(ab, "BASE_HOME")) {
        if (loaded_version < 10000022) forceSystemFlag(FLAG_BASE_HOME, @intFromBool(text.toUint8(tmpString) != 0));
    } else if (allow_user_keys and cmpName(ab, "Norm_Key_00_VAR")) {
        if (normKey00Key() != -1) {
            Norm_Key_00.func = @bitCast(text.toUint16(tmpString));
            Norm_Key_00.used = Norm_Key_00.func != kbdStdPrimary(normKey00Key());
        } else {
            Norm_Key_00.used = false;
        }
    } else if (allow_user_keys and cmpName(ab, "Norm_Key_00.func")) {
        Norm_Key_00.func = @bitCast(text.toUint16(tmpString));
    } else if (cmpName(ab, "Norm_Key_00.funcParam")) {
        if (cmpName(tmpString, "Norm_Key_00.used")) {
            if (allow_user_keys) {
                Norm_Key_00.funcParam[0] = 0;
                Norm_Key_00.used = false;
            }
            calc_state.readLine(tmpString, TMP_STR_LENGTH);
        } else if (allow_user_keys and cmpName(tmpString, "NoNormKeyParamDef")) {
            Norm_Key_00.funcParam[0] = 0;
        } else if (allow_user_keys) {
            // A name the field cannot hold comes only from a corrupt file, so leave it
            // empty rather than let strcpy run past the field.
            Norm_Key_00.funcParam[0] = 0;
            if (strlen(tmpString) < @sizeOf(@TypeOf(Norm_Key_00.funcParam))) {
                _ = strcpy(&Norm_Key_00.funcParam[0], tmpString);
            }
        }
    } else if (allow_user_keys and cmpName(ab, "Norm_Key_00.used")) {
        Norm_Key_00.used = text.toUint8(tmpString) != 0;
    } else if (allow_user_keys and cmpName(ab, "calcModel")) {
        const calcModelRead = text.toUint16(tmpString);
        if (saved_calc_model == USER_R47 and (calcModelRead == USER_R47f_g or calcModelRead == USER_R47fg_g or calcModelRead == USER_R47fg_bk or calcModelRead == USER_R47bk_fg)) {
            calcModel = @intCast(calcModelRead);
        } else if (saved_calc_model == USER_C47 and (calcModelRead == USER_C47 or calcModelRead == USER_DM42)) {
            calcModel = @intCast(calcModelRead);
        }
    } else if (cmpName(ab, "Input_Default")) {
        Input_Default = text.toUint8(tmpString);
        set_def_Input_Default();
    } else if (cmpName(ab, "jm_BASE_SCREEN")) {
        if (loaded_version < 10000022) forceSystemFlag(FLAG_BASE_MYM, @intFromBool(text.toUint8(tmpString) != 0));
    } else if (cmpName(ab, "BASE_MYM")) {
        if (loaded_version < 10000022) forceSystemFlag(FLAG_BASE_MYM, @intFromBool(text.toUint8(tmpString) != 0));
    } else if (cmpName(ab, "jm_G_DOUBLETAP")) {
        if (loaded_version < 10000022) forceSystemFlag(FLAG_G_DOUBLETAP, @intFromBool(text.toUint8(tmpString) != 0));
    } else if (cmpName(ab, "displayStackSHOIDISP")) {
        displayStackSHOIDISP = text.toUint8(tmpString);
    } else if (cmpName(ab, "bcdDisplay")) {
        if (loaded_version < 10000020) forceSystemFlag(FLAG_BCD, @intFromBool(text.toUint8(tmpString) != 0));
    } else if (cmpName(ab, "topHex")) {
        if (loaded_version < 10000019) forceSystemFlag(FLAG_TOPHEX, @intFromBool(text.toUint8(tmpString) != 0));
    } else if (cmpName(ab, "bcdDisplaySign")) {
        bcdDisplaySign = calc_state.convert001090400T001090500(text.toUint8(tmpString), BCDu);
    } else if (matchU8("DRG_Cycling", &DRG_Cycling)) {} else if (matchU8("DM_Cycling", &DM_Cycling)) {} else if (cmpName(ab, "LongPressM")) {
        LongPressM = calc_state.convert001090400T001090500(text.toUint8(tmpString), RBX_M14);
    } else if (cmpName(ab, "LongPressF")) {
        LongPressF = calc_state.convert001090400T001090500(text.toUint8(tmpString), RBX_F14);
    } else if (cmpName(ab, "lastIntegerBase")) {
        lastIntegerBase = text.toUint8(tmpString);
    } else if (cmpName(ab, "amortP1")) {
        amortP1 = text.toUint16(tmpString);
    } else if (cmpName(ab, "amortP2")) {
        amortP2 = text.toUint16(tmpString);
    } else if (cmpName(ab, "lrChosen")) {
        lrChosen = text.toUint16(tmpString);
    } else if (cmpName(ab, "graph_dx")) {
        graph_dx = calc_state.stringToFloat(tmpString);
    } else if (cmpName(ab, "graph_dy")) {
        graph_dy = calc_state.stringToFloat(tmpString);
    } else if (cmpName(ab, "roundedTicks")) {
        roundedTicks = @intFromBool(text.toUint8(tmpString) != 0);
    } else if (cmpName(ab, "PLOT_INTG")) {
        if (loaded_version < 10000025) forceSystemFlag(FLAG_PINTG, @intFromBool(text.toUint8(tmpString) != 0));
    } else if (cmpName(ab, "PLOT_DIFF")) {
        if (loaded_version < 10000025) forceSystemFlag(FLAG_PDIFF, @intFromBool(text.toUint8(tmpString) != 0));
    } else if (cmpName(ab, "PLOT_RMS")) {
        if (loaded_version < 10000025) forceSystemFlag(FLAG_PRMS, @intFromBool(text.toUint8(tmpString) != 0));
    } else if (cmpName(ab, "PLOT_SHADE")) {
        if (loaded_version < 10000025) forceSystemFlag(FLAG_PSHADE, @intFromBool(text.toUint8(tmpString) != 0));
    } else if (cmpName(ab, "PLOT_AXIS")) {
        PLOT_AXIS = @intFromBool(text.toUint8(tmpString) != 0);
    } else if (cmpName(ab, "PLOT_ZMY")) {
        PLOT_ZMY = @bitCast(text.toUint8(tmpString));
    } else if (matchU8("firstDayOfWeek", &firstDayOfWeek)) {} else if (matchU8("firstWeekOfYearDay", &firstWeekOfYearDay)) {} else if (cmpName(ab, "printerOn")) {
        setPrinterOn(text.toUint8(tmpString));
    } else if (cmpName(ab, "printerModel")) {
        setPrinterModel(text.toUint8(tmpString));
    } else if (cmpName(ab, "printerLineDelay")) {
        const delay = text.toUint16(tmpString);
        setPrinterDelay(delay);
        setLineDelay(delay);
    } else if (cmpName(ab, "jm_LARGELI")) {
        if (loaded_version < 10000012) forceSystemFlag(FLAG_LARGELI, @intFromBool(text.toUint8(tmpString) != 0));
    } else if (cmpName(ab, "constantFractions")) {
        if (loaded_version < 10000012) forceSystemFlag(FLAG_IRFRQ, @intFromBool(text.toUint8(tmpString) != 0));
    } else if (cmpName(ab, "constantFractionsOn")) {
        if (loaded_version < 10000012) forceSystemFlag(FLAG_IRFRAC, @intFromBool(text.toUint8(tmpString) != 0));
    } else if (cmpName(ab, "eRPN")) {
        if (loaded_version < 10000012) forceSystemFlag(FLAG_ERPN, @intFromBool(text.toUint8(tmpString) != 0));
    } else if (cmpName(ab, "CPXMult")) {
        if (loaded_version < 10000012) forceSystemFlag(FLAG_CPXMULT, @intFromBool(text.toUint8(tmpString) != 0));
    } else if (cmpName(ab, "SI_All")) {
        if (loaded_version < 10000012) forceSystemFlag(FLAG_PFX_ALL, @intFromBool(text.toUint8(tmpString) != 0));
    }
}
