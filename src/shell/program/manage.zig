// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/programming/manage.c: program-memory and label/program
// list management. This is the test-reachable core: scanLabelsAndPrograms runs at
// reset and in every program test, walking the raw program-memory bytes through
// labelList/programList. The byte-offset pointer arithmetic on currentStep,
// firstFreeProgramByte, beginOfProgramMemory, labelList[].labelPointer etc. is
// reproduced exactly.
//
// fnClPAll is NOT exported here, so it does not collide with the canonical owner:
// program_clear.zig exports `pub export fn fnClPAll` (a faithful copy of
// manage.c's fnClPAll body). The internal callers below (_clearProgram / fnClP)
// invoke that canonical fnClPAll through the `program_clear` import. This owner also provides
// z47_frontier_program_current_program_in_ram, defined below as a pub fn.
//
// manage.c carries no build-option guard, so the bodies of scanLabelsAndPrograms
// and fnPem are ported in full.
//
// The fnPem #if defined(DMCP_BUILD) "skip long processing" guard wraps the per-line
// body in an extra condition on firmware; ported via comptime dmcp_build. The
// EXTRA_INFO_ON_CALC_ERROR console hint in fnClP is gated on extra_info && !dmcp_build
// and reduced to the host moreInfoOnError call as in the sibling owners. The PC-only
// printf trace in insertStepInProgram (GTOP) is host-only. clearScreen expands to
// lcd_fill_rect(...) + frontier_status_bar.forceSBupdate(); lcd_fill_rect is a DMCP ROM
// function-table entry on firmware and a real symbol on host (idiom copied from
// the error owner). IR_PRINTING/DEBUG_PGM/MONITOR_CLRSCR are never defined here.

const std = @import("std");
const program_clear = @import("program_clear.zig");
const frontier_structured = @import("structured.zig");
const builtin = @import("builtin");
const frontier_build_options = @import("frontier_build_options");
const dmcp_build: bool = frontier_build_options.dmcp_build;
const old_hw: bool = frontier_build_options.old_hw;
// The DMCP ROM function table of the board's SDK.
const rom = @import("dmcp_rom");
const extra_info: bool = frontier_build_options.extra_info_on_calc_error;
const option_structured_pgm: bool = frontier_build_options.option_structured_pgm;
// OPTION_DRG_CFG: DRG during number entry chooses the unit of the literal, and a
// D.MS literal shows its marks as it is typed.
const option_drg_cfg: bool = frontier_build_options.option_drg_cfg;
const DRG_NIM_BIT: u3 = 5;
// structured.h defines OPTION_STRUCT_INDENT inside the OPTION_STRUCTURED_PGM guard,
// so the editor indents a structure's body exactly when the structures are compiled
// in; without it the columns are those of the build before STRUCT.
const option_struct_indent: bool = option_structured_pgm;
const PEM_STRUCT_INDENT: i32 = 2; // spaces a structure indents its body by in the editor
const PEM_MAX_STRUCT_LEVELS: i8 = 4; // levels the editor indents; deeper structures all share that column, the 400 pixel screen being the limit

const code_section = abi.codeSection(dmcp_build and old_hw);

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const bool_t = bool;
const calcRegister_t = i16;
const real34_t = abi.Real34;
const font_t = abi.Font;
const softmenu_t = abi.Softmenu;
const softmenuStack_t = abi.SoftmenuStack;
const item_t = abi.Item;
const labelList_t = abi.LabelList;
const programList_t = abi.ProgramList;
const registerHeader_t = abi.RegisterHeader;
const reservedVariableHeader_t = abi.ReservedVariableHeader;
const subroutineLevelHeader_t = abi.SubroutineLevelHeader;
const tamState_t = abi.TamState;
const abi = @import("abi"); // shared ABI bindings
const program_step_opcode = @import("program_step_opcode.zig"); // std-only program-step opcode inspection
const ks_register_remap = @import("ks_register_remap.zig"); // std-only KS-code register remap
const frontier_assign = @import("../input/assign.zig");
const frontier_addons = @import("../extensions/addons.zig");
const frontier_bufferize = @import("../display/bufferize.zig");
const frontier_calc_mode = @import("../calc_mode.zig");
const frontier_char_string = @import("../display/text/char_string.zig");
const frontier_conversion_angles = @import("../convert/conversion_angles.zig");
const frontier_date_time = @import("../convert/date_time.zig");
const frontier_decode = @import("decode.zig");
const frontier_error = @import("../error.zig");
const frontier_items = @import("../display/items/items.zig");
const frontier_lbl_gto_xeq = @import("lbl_gto_xeq.zig");
const frontier_next_step = @import("next_step.zig");
const frontier_register_value_conversions = @import("../register_value_conversions.zig");
const frontier_screen = @import("../display/screen.zig");
const frontier_screen_snap = @import("../display/screen_snap.zig");
const frontier_softmenus = @import("../display/softmenus/softmenus.zig");
const frontier_sort = @import("../display/sort.zig");
const frontier_status_bar = @import("../display/statusbar/status_bar.zig");
const realContext_t = abi.RealContext;

// ---------------------------------------------------------------------------
// Constants (probed from c47.h via a preprocessor probe)
// ---------------------------------------------------------------------------
const SOFTMENU_STACK_SIZE: usize = 8;
const AIM_BUFFER_LENGTH: i32 = 1024;
const NIM_BUFFER_LENGTH: usize = 200;

// defines.h: 16384 blocks on DM42 (DMCP without NEW_HW), 65534 everywhere else.
// 65535 is excluded throughout because it is the C47_NULL pointer value.
const RAM_SIZE_IN_BLOCKS: u32 = if (dmcp_build and old_hw) 16384 else 65534;
const BYTES_PER_BLOCK: u32 = 4;
const BPB: u5 = 2;
const C47_NULL: u16 = 65535;

const REAL34_SIZE_IN_BYTES: u32 = 16;
const COMPLEX34_SIZE_IN_BLOCKS: u32 = 8;

const FIRST_LOCAL_REGISTER: i16 = 7000;
const LAST_LOCAL_REGISTER: i16 = 7098;
const FIRST_LOCAL_REGISTER_IN_KS_CODE: i16 = 112;
const FIRST_STAT_REGISTER: i16 = 112;
const LAST_SPARE_REGISTER: i16 = 125;
const NUMBER_OF_LOCAL_REGISTERS: i16 = 99;

const LAST_LOCAL_LABEL: u8 = 123;
const FIRST_LABEL: u16 = 2200;
const LAST_LABEL: u16 = 6999;
const INVALID_VARIABLE: i16 = 2199;

const CMP_BINARY: i32 = 0;
const CMP_NAME: i32 = 3;
const NC_NORMAL: u8 = 0;
const AC_LOWER: u8 = 1;
const AC_UPPER: u8 = 0;

const NP_EMPTY: u8 = 0;
const NP_INT_10: u8 = 1;
const NP_INT_16: u8 = 2;
const NP_INT_BASE: u8 = 3;
const NP_REAL_FLOAT_PART: u8 = 4;
const NP_REAL_EXPONENT: u8 = 5;
const NP_FRACTION_DENOMINATOR: u8 = 6;
const NP_COMPLEX_INT_PART: u8 = 7;
const NP_COMPLEX_FLOAT_PART: u8 = 8;
const NP_COMPLEX_EXPONENT: u8 = 9;
const NP_HP32SII_DENOMINATOR: u8 = 10;
const NP_COMPLEX_FRACTION_DENOMINATOR: u8 = 11;
const NP_COMPLEX_HP32SII_DENOMINATOR: u8 = 12;

const PTP_STATUS: u16 = 7680;
const PTP_DISABLED: u16 = 7680;
const PTP_NONE: u16 = 0;
const PTP_NUMBER_16: u16 = 3072;
const PTP_NUMBER_8_16: u16 = 5120;
const PTP_LITERAL: u16 = 6656;
const PTP_REM: u16 = 7168;
const PTP_SKIP_BACK: u16 = 4608;

// The forms of FOR and NEXT that VALID has not passed; a new one joining the
// program unchecks the ones already there.
const ITM_FORx: u16 = 2929;
const ITM_NEXTx: u16 = 2930;
const ITM_FORYXx: u16 = 2934;
const ITM_FORTOPx: u16 = 2939;

const CAT_STATUS: u16 = 240;
const CAT_FNCT: u16 = 16;
const CNST_BEYOND_250: u8 = 250;
const SYSTEM_FLAG_NUMBER: u8 = 250;
const VALUE_0: u8 = 251;
const VALUE_1: u8 = 252;
const BINARY_SHORT_INTEGER: u8 = 1;
const BINARY_REAL34: u8 = 3;
const BINARY_COMPLEX34: u8 = 4;
const INDIRECT_REGISTER: u8 = 254;
const INDIRECT_VARIABLE: u8 = 255;

const STRING_SHORT_INTEGER: u8 = 7;
const STRING_LONG_INTEGER: u8 = 8;
const STRING_REAL34: u8 = 9;
const STRING_COMPLEX34: u8 = 10;
const STRING_TIME: u8 = 11;
const STRING_DATE: u8 = 12;
const STRING_ANGLE_RADIAN: u8 = 18;
const STRING_ANGLE_GRAD: u8 = 19;
const STRING_ANGLE_DEGREE: u8 = 20;
const STRING_ANGLE_DMS: u8 = 21;
const STRING_ANGLE_MULTPI: u8 = 22;
const STRING_LABEL_VARIABLE: u8 = 253;
const LOCAL_LABEL_VARIABLE: u8 = 249;

// namedLabels_t (typeDefinitions.h): the label-scope selector threaded through
// findNamedLabel/findNamedLabelWithDuplicate. GLOBAL_LABELS and LOCAL_LABELS
// alias the STRING_/LOCAL_LABEL_VARIABLE op-parameter sentinels so a caller can
// pass opParam directly.
pub const GLOBAL_LABELS: u8 = STRING_LABEL_VARIABLE; // 253
pub const LOCAL_LABELS: u8 = LOCAL_LABEL_VARIABLE; // 249
pub const ALL_LABELS: u8 = 0;

const TEMP_REGISTER_1: i16 = 135;
const dtReal34: u32 = 1;
const amNone: u32 = 5;

const ERROR_NONE: u8 = 0;
const ERROR_INVALID_INTEGER_INPUT: u8 = 9;
const ERROR_LABEL_NOT_FOUND: u8 = 6;
const ERROR_OUT_OF_RANGE: u8 = 8;
const ERROR_RAM_FULL: u8 = 11;
const ERROR_UNDEFINED_OPCODE: u8 = 3;
// Longest label name the calculator can produce: TAM alpha entry is force-closed beyond 6 glyphs
// (maxLen in _tamProcessInput, ui/tam.c), so a name is at most 7 glyphs of at most 2 bytes each.
// A longer name in a loaded file marks the file as corrupt. defines.h MAX_LABEL_NAME_LENGTH.
const MAX_LABEL_NAME_LENGTH: u8 = 14;
const ERR_REGISTER_LINE: i16 = 102;
const REGISTER_X: i16 = 100;
const REGISTER_T: i16 = 103;

const CONFIRMED: u16 = 9877;
const NOT_CONFIRMED: u16 = 9878;
const NOPARAM: u16 = 9876;

const TI_NO_INFO: u8 = 0;
const TI_DEL_ALL_PRGMS: u8 = 99;
const PGM_STOPPED: u8 = 0;
const PGM_RUNNING: u8 = 1;
const SCRUPD_AUTO: u8 = 0;
const SCRUPD_MANUAL_MENU: u8 = 4;
const CM_PEM: u8 = 3;
const CM_CONFIRMATION: u8 = 11;

const TM_VALUE: u16 = 10001;
const TM_CMP: u16 = 10022; // defines.h: 10022 (matches comparison items' .param=10022); was 10021 (=TM_STRING) -> interactive comparisons broke
const TM_FLAGR: u16 = 10004;
const TM_FLAGW: u16 = 10005;
const TM_LABEL: u16 = 10009;
const TM_LBLONLY: u16 = 10018;
const TM_MENU: u16 = 10017;

const Y_POSITION_OF_REGISTER_T_LINE: i32 = 24;
const SCREEN_WIDTH: u32 = 400;
const X_SHIFT_R: i32 = 361;

// FLAG_* (system flags)
const FLAG_ALPHA: c_uint = 32782;
const FLAG_NUMLOCK: c_uint = 32835;
const FLAG_USER: c_uint = 32788;
const FLAG_3DPHYS: i32 = 32869;
const FLAG_HPRP: i32 = 32811;
const FLAG_AUTOVALID: i32 = 32880;

// angular modes (currentAngularMode is a c_int enum)
const amRadian: c_int = 0;
const amGrad: c_int = 1;
const amDegree: c_int = 2;
const amDMS: c_int = 3;
const amMultPi: c_int = 4;

// ITM_* op/item codes
const ITM_GTO: u16 = 2;
const ITM_XEQ: u16 = 3;
const ITM_STO: u16 = 44;
const ITM_RCL: u16 = 51;
const ITM_YX: u16 = 60;
const ITM_SQUAREROOTX: u16 = 61;
const ITM_LOG10: u16 = 71;
const ITM_1ONX: u16 = 73;
const ITM_CHS: u16 = 97;
const ITM_CONSTpi: u16 = 109;
const ITM_DEG2: u16 = 115;
const ITM_DMS2: u16 = 116;
const ITM_GRAD2: u16 = 117;
const ITM_MULPI2: u16 = 118;
const ITM_RAD2: u16 = 119;
const ITM_LITERAL: u16 = 114;
const ITM_ENTER: u16 = 35;
const ITM_LBL: u16 = 1;
const ITM_0: i16 = 540;
const ITM_1: i16 = 541;
const ITM_9: i16 = 549;
const ITM_A: i16 = 550;
const ITM_F: u16 = 555;
const ITM_Z: u16 = 575;
const ITM_a: i16 = 576;
const ITM_PERIOD: u16 = 820;
const ITM_DOWN_ARROW: u16 = 895;
const ITM_UP_ARROW: u16 = 893;
const ITM_EXPONENT: u16 = 990;
const ITM_DMS: u16 = 1451;
const ITM_DELP: u16 = 1425;
const ITM_DELPALL: u16 = 1426;
const ITM_END: u16 = 1458;
const ITM_KEY: u16 = 1497;
const ITM_KEYG: u16 = 1498;
const ITM_KEYX: u16 = 1499;
const ITM_42KEY: u16 = 2794;
const ITM_42KEYG: u16 = 2795;
const ITM_42KEYX: u16 = 2796;
const ITM_42STRING: u16 = 2775;
const ITM_42APPEND: u16 = 2776;
const ITM_REM: u16 = 1554;
const ITM_FINISH: u16 = 1912;
const ITM_toINT: u16 = 1687;
const ITM_HMStoTM: u16 = 1688;
const ITM_USERMODE: u16 = 1729;
const ITM_CC: u16 = 1730;
const ITM_BST: u16 = 1734;
const ITM_SST: u16 = 1736;
const ITM_EXIT1: u16 = 1737;
const ITM_BACKSPACE: u16 = 1738;
const ITM_AIM: u16 = 1740;
const ITM_dotD: u16 = 1741;
const ITM_op_j_pol: u16 = 1795;
const ITM_op_j: u16 = 1830;
const ITM_toPOL2: u16 = 1849;
const ITM_toREC2: u16 = 1850;
const ITM_DRG: u16 = 1873;
const ITM_NOP: i16 = 1542;
const ITM_CLA: u16 = 1874;
const ITM_ms: u16 = 1909;
const ITM_toPOL_HP: u16 = 1981;
const ITM_SCR: u16 = 2191;
const ITM_EDIT: u16 = 2404;
const ITM_GTOP: u16 = 1482;
const ITM_STKtoV3: u16 = 2702;
const ITM_V3toSTK: u16 = 2703;
const ITM_STKtoV3_M: u16 = 2474;
const ITM_STKtoV3_P: u16 = 2488;
const ITM_V3toSTK_M: u16 = 2476;
const ITM_V3toSTK_P: u16 = 2489;

const CHR_case: u16 = 1858;
const ITM_CASEUP: u16 = 1878;
const ITM_CASEDN: u16 = 1879;
const CHR_num: u16 = 2029;
const CHR_numL: u16 = 2030;
const CHR_numU: u16 = 2031;

const VAR_ACC: u16 = 1192;
const VAR_ULIM: u16 = 1193;
const VAR_LLIM: u16 = 1194;
const VAR_UX: u16 = 1205;
const VAR_LX: u16 = 1206;
const VAR_UEST: u16 = 2545;
const VAR_LEST: u16 = 2546;
const VAR_UY: u16 = 2547;
const VAR_LY: u16 = 2548;

// MNU_* (for _closeAlphaMenus)
const MNU_CATALOG: i16 = 3022;
const MNU_MyAlpha: i16 = 3089;
const MNU_ALPHAINTL: i16 = 3007;
const MNU_ALPHAMATH: i16 = 3009;
const MNU_ALPHA_OMEGA: i16 = 3004;
const MNU_alpha_omega: i16 = 3005;
const MNU_ALPHAintl: i16 = 3008;
const MNU_DYNAMIC: u16 = 3052;
const MNU_PFN: i16 = 3095;
const MNU_ALPHA: i16 = 3003;

// videoMode_t
const vmNormal: c_int = 0;
const vmReverse: c_int = 1;

// LCD_SET_VALUE: 0 on host; firmware LCD_INVERT_DATA defined -> 0 as well.
const LCD_SET_VALUE: c_int = 0;

// STD_* byte sequences.
const STD_SPACE_4_PER_EM = "\xa0\x05";
const STD_LEFT_SINGLE_QUOTE = "\xa0\x18";
const STD_RIGHT_SINGLE_QUOTE = "\xa0\x19";
const STD_UP_ARROW = "\xa1\x91";
const STD_DOWN_ARROW = "\xa1\x93";
const STD_CURSOR = "\xa4\x27";
const STD_alpha = "\x83\xb1";
const STD_RIGHT_TACK = "\xa2\xa2";

// ---------------------------------------------------------------------------
// Globals: GENUINE C pointer/scalar variables -> extern var (declared `T *name;`
// or scalar in c47.h). Confirmed each via c47.h.
// ---------------------------------------------------------------------------
extern var ram: [*c]u32; // uint32_t *ram;
extern var beginOfProgramMemory: [*c]u8; // uint8_t *beginOfProgramMemory;
extern var firstFreeProgramByte: [*c]u8; // uint8_t *firstFreeProgramByte;
extern var freeProgramBytes: u16; // uint16_t freeProgramBytes;
extern var currentStep: [*c]u8; // uint8_t *currentStep;
extern var firstDisplayedStep: [*c]u8; // uint8_t *firstDisplayedStep;
extern var beginOfCurrentProgram: [*c]u8; // uint8_t *beginOfCurrentProgram;
extern var endOfCurrentProgram: [*c]u8; // uint8_t *endOfCurrentProgram;
// labelList/programList point into the C block allocator, which guarantees only
// 4-byte (BYTES_PER_BLOCK) alignment. On the 64-bit host the structs' [*c]u8
// fields would otherwise demand 8-byte alignment, which a pool block does not
// give (the firmware is 32-bit so pointers are 4 bytes and this is a non-issue
// there). Declare the element alignment as 4 to match the allocator
// and the C semantics (a plain void*->T* cast).
extern var labelList: [*c]align(4) labelList_t; // labelList_t *labelList;
extern var programList: [*c]align(4) programList_t; // programList_t *programList;
extern var numberOfLabels: u16;
extern var numberOfStructureLabels: u16; // uint16_t numberOfLabels;
extern var numberOfPrograms: u16; // uint16_t numberOfPrograms;
extern var currentProgramNumber: u16; // uint16_t currentProgramNumber;
extern var currentLocalStepNumber: u16; // uint16_t currentLocalStepNumber;
extern var firstDisplayedLocalStepNumber: u16; // uint16_t firstDisplayedLocalStepNumber;
extern var lastErrorCode: u8; // uint8_t lastErrorCode;
extern var calcMode: u8; // uint8_t calcMode;
extern var screenUpdatingMode: u8; // uint8_t screenUpdatingMode;
extern var temporaryInformation: u8; // uint8_t temporaryInformation;
extern var programRunStop: u8; // uint8_t programRunStop;
extern var hourGlassIconEnabled: bool_t; // bool_t hourGlassIconEnabled;
extern var programListEnd: bool_t; // bool_t programListEnd;
extern var lastProgramListEnd: bool_t; // bool_t lastProgramListEnd;
extern var pemCursorIsZerothStep: bool_t; // bool_t pemCursorIsZerothStep;
extern var aimBuffer: [*c]u8; // char *aimBuffer;
extern var tmpString: [*c]u8; // char *tmpString;
extern var errorMessage: [*c]u8; // char *errorMessage;
extern var nimBufferDisplay: [*c]u8; // char *nimBufferDisplay;
extern var softmenuStack: [SOFTMENU_STACK_SIZE]softmenuStack_t; // softmenuStack_t softmenuStack[SOFTMENU_STACK_SIZE];
extern var currentSubroutineLevelData: [*c]subroutineLevelHeader_t; // subroutineLevelHeader_t *currentSubroutineLevelData;
extern var tam: tamState_t; // tamState_t tam;
extern var dynamicMenuItem: i16; // int16_t dynamicMenuItem;
extern var lastIntegerBase: u32; // uint32_t lastIntegerBase;
extern var decodedIntegerBase: u32; // uint32_t decodedIntegerBase;
extern var nimNumberPart: u8; // uint8_t nimNumberPart;
extern var editingLiteralType: u8; // uint8_t editingLiteralType;
extern var nimPolarAngularMode: u8;
extern var drgConfig: u8;
extern var DRG_Cycling: u8;
extern var catalog: i16; // int16_t catalog;
extern var alphaCase: u8; // uint8_t alphaCase;
extern var nextChar: u8; // uint8_t nextChar;
extern var calcModel: u8; // uint8_t calcModel;
extern var shiftF: bool_t; // bool_t shiftF;
extern var shiftG: bool_t; // bool_t shiftG;
extern var T_cursorPos: i16; // int16_t T_cursorPos;
extern var displayAIMbufferoffset: i16; // int16_t displayAIMbufferoffset;
extern var tamOverPemYPos: u32; // uint32_t tamOverPemYPos;
extern var currentAngularMode: c_int; // angularMode_t currentAngularMode;
extern var ctxtReal34: realContext_t; // realContext_t ctxtReal34;
extern const standardFont: font_t; // const font_t standardFont;
extern var errorMessageRegisterLine: calcRegister_t; // calcRegister_t errorMessageRegisterLine;
extern var currentInputVariable: u16; // uint16_t currentInputVariable;

// USER_* model ids for the isR47FAM macro.
const USER_C47: u8 = 46;
const USER_R47f_g: u8 = 61;
const USER_R47bk_fg: u8 = 62;
const USER_R47fg_bk: u8 = 63;
const USER_R47fg_g: u8 = 64;
inline fn isR47FAM() bool_t {
    return calcModel == USER_R47f_g or calcModel == USER_R47bk_fg or calcModel == USER_R47fg_bk or calcModel == USER_R47fg_g;
}

// currentSubroutineLevel macro: currentSubroutineLevelData->subroutineLevel
inline fn currentSubroutineLevel() u16 {
    return currentSubroutineLevelData.*.subroutineLevel;
}
inline fn currentNumberOfLocalRegisters() u8 {
    return currentSubroutineLevelData.*.numberOfLocalRegisters;
}

// ---------------------------------------------------------------------------
// C ARRAYS -> @extern (binding the array's address, never a pointer load).
//   indexOfItems:         const item_t indexOfItems[];
//   allReservedVariables: const reservedVariableHeader_t allReservedVariables[];
//   softmenu:             const softmenu_t softmenu[];
//   baseChars/angleChars: const char baseChars[]; const char angleChars[];
// ---------------------------------------------------------------------------
const indexOfItems = @extern([*c]const item_t, .{ .name = "indexOfItems" });
const allReservedVariables = @extern([*c]const reservedVariableHeader_t, .{ .name = "allReservedVariables" });
const softmenu = @extern([*c]const softmenu_t, .{ .name = "softmenu" });
const baseChars = @extern([*c]const u8, .{ .name = "baseChars" });
const angleChars = @extern([*c]const u8, .{ .name = "angleChars" });

// ---------------------------------------------------------------------------
// Function externs
// ---------------------------------------------------------------------------
extern fn strlen(s: [*c]const u8) usize;
extern fn strcpy(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strcat(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strcmp(a: [*c]const u8, b: [*c]const u8) c_int;
extern fn atoi(s: [*c]const u8) c_int;
extern fn memset(s: ?*anyopaque, c: c_int, n: usize) ?*anyopaque;
extern fn sprintf(buf: [*c]u8, fmt: [*:0]const u8, ...) c_int;
extern fn printf(fmt: [*:0]const u8, ...) c_int;

extern fn freeC47Blocks(pcMemPtr: ?*anyopaque, sizeInBlocks: usize) void;
extern fn resizeProgramMemory(newSizeInBlocks: u16) void;

extern fn fnFlipFlag(flag: u16) void;

extern fn moreInfoOnError(m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) void;

extern fn getSystemFlag(sf: i32) bool_t;
extern fn setSystemFlag(sf: c_uint) void;
extern fn clearSystemFlag(sf: c_uint) void;
extern fn resetShiftState() void;

extern fn numlockReplacements(id: u16, item: i16, NL: bool_t, SHFT: bool_t, GSHFT: bool_t) u16;

extern fn fnT_ARROW(command: u16) void;
extern fn SetSetting(jmConfig: u16) void;

extern fn reallocateRegister(regist: calcRegister_t, dataType: u32, dataSizeWithoutDataLenBlocks: u16, tag: u32) bool;
extern fn getRegisterDataPointer(regist: calcRegister_t) *align(4) anyopaque;

// findOrAllocateNamedVariable / findNamedVariable / findMenu are not used here.

// decNumber primitives behind the stringToReal34/real34ToString/real34IsZero macros.
extern fn decQuadFromString(dst: *real34_t, src: [*c]const u8, ctx: *realContext_t) *real34_t;
extern fn decQuadToString(src: *const real34_t, dst: [*c]u8) [*c]u8;
extern fn decQuadIsZero(src: *const real34_t) u32;

// addItemToBuffer / fnT_ARROW addresses for indexOfItems[item].func comparisons.
const FnPtr = ?*const fn (u16) callconv(.c) void;
const c_addItemToBuffer = @extern(FnPtr, .{ .name = "addItemToBuffer" });
const c_fnT_ARROW = @extern(FnPtr, .{ .name = "fnT_ARROW" });

// The canonical fnClPAll symbol (provided by program_clear.zig). We reference its
// address for setConfirmationMode and call it from _clearProgram / insertStepInProgram.

// ---------------------------------------------------------------------------
// Small helpers mirroring c47.h macros / libc idioms.
// ---------------------------------------------------------------------------
inline fn stringByteLength(s: [*c]const u8) i32 {
    return @intCast(strlen(s));
}
inline fn absI(x: i32) i32 {
    return if (x < 0) -x else x;
}
inline fn maxI(a: i32, b: i32) i32 {
    return if (a > b) a else b;
}
inline fn moreInfoErr(where: [*:0]const u8, m2: [*:0]const u8, m3: ?[*:0]const u8) void {
    if (comptime extra_info) {
        if (comptime !dmcp_build) moreInfoOnError(where, m2, m3, null);
    }
}

// REGISTER_REAL34_DATA(a)
const reg34 = abi.registerReal34Aligned;
inline fn stringToReal34(src: [*c]const u8, dst: *real34_t) void {
    _ = decQuadFromString(dst, src, &ctxtReal34);
}
inline fn real34ToString(src: *const real34_t, dst: [*c]u8) void {
    _ = decQuadToString(src, dst);
}
inline fn real34IsZero(src: *const real34_t) bool {
    return decQuadIsZero(src) != 0;
}

// TO_BLOCKS / TO_BYTES
inline fn toBlocks(n: u32) u32 {
    return (n + (BYTES_PER_BLOCK - 1)) >> BPB;
}
inline fn toBytes(n: u32) u32 {
    return n << BPB;
}
// TO_C47MEMPTR(p): (p==NULL)?C47_NULL:(uint16_t)((uint32_t *)p - ram)
inline fn toC47MemPtr(p: [*c]u8) u16 {
    if (p == null) return C47_NULL;
    return @intCast((@intFromPtr(p) - @intFromPtr(ram)) / @sizeOf(u32));
}
// (uint8_t *)(ram + RAM_SIZE_IN_BLOCKS)
inline fn ramEnd() [*c]u8 {
    return std.mem.asBytes(&ram[RAM_SIZE_IN_BLOCKS]);
}

// regCtoKS (defines.h static inline)
inline fn regCtoKS(regC: i16) u8 {
    return ks_register_remap.regCtoKS(regC, .{
        .first_stat = FIRST_STAT_REGISTER,
        .last_spare = LAST_SPARE_REGISTER,
        .num_local = NUMBER_OF_LOCAL_REGISTERS,
        .first_local = FIRST_LOCAL_REGISTER,
        .last_local = LAST_LOCAL_REGISTER,
        .first_local_ks = FIRST_LOCAL_REGISTER_IN_KS_CODE,
    });
}

// clearScreen(cnt): lcd_fill_rect(0,0,SCREEN_WIDTH,240,LCD_SET_VALUE); frontier_status_bar.forceSBupdate();
const LcdFillRectFn = *const fn (x: u32, y: u32, dx: u32, dy: u32, val: c_int) callconv(.c) void;
const c_lcd_fill_rect = @extern(LcdFillRectFn, .{ .name = "lcd_fill_rect" });

inline fn lcdFillRect(x: u32, y: u32, dx: u32, dy: u32, val: c_int) void {
    if (comptime dmcp_build) {
        rom.lcd_fill_rect(x, y, dx, dy, val);
    } else {
        c_lcd_fill_rect(x, y, dx, dy, val);
    }
}
inline fn clearScreen() void {
    lcdFillRect(0, 0, SCREEN_WIDTH, 240, LCD_SET_VALUE);
    frontier_status_bar.forceSBupdate();
}

// calcMode* GUI hooks are no-op macros on firmware, real externs on host.
extern fn calcModeNormalGui() void;
extern fn calcModeAimGui() void;
inline fn calcModeNormalGuiCall() void {
    if (comptime !dmcp_build) calcModeNormalGui();
}
inline fn calcModeAimGuiCall() void {
    if (comptime !dmcp_build) calcModeAimGui();
}

// ===========================================================================
// isAtEndOfPrograms (public)
// ===========================================================================
pub export fn isAtEndOfPrograms(step: [*c]const u8) callconv(.c) bool_t {
    return program_step_opcode.isAtEndOfPrograms(step);
}

// ===========================================================================
// checkOpCodeOfStep (public)
// ===========================================================================
pub export fn checkOpCodeOfStep(step: [*c]const u8, op: u16) callconv(.c) bool_t {
    return program_step_opcode.checkOpCodeOfStep(step, op);
}

// isAtEndOfProgram (static inline in manage.h): checkOpCodeOfStep(step, ITM_END)
inline fn isAtEndOfProgram(step: [*c]const u8) bool_t {
    return checkOpCodeOfStep(step, ITM_END);
}

// ===========================================================================
// boundProgramNameLength (public) — src/c47/programming/manage.c
// ===========================================================================
// A label or variable name stored in a program step is preceded by a one-byte
// length taken from program memory on trust. A corrupt or crafted program (a
// restored state file or imported program) can claim a name longer than the
// bytes that remain. Clamp the claimed length to the span before
// firstFreeProgramByte so a name read can never run past the program region.
// When the name would start at or past firstFreeProgramByte there are no valid
// bytes left, so return 0 rather than leaving the length unbounded.
pub export fn boundProgramNameLength(nameStart: [*c]const u8, claimedLength: u8) callconv(.c) u8 {
    return program_step_opcode.boundProgramNameLength(nameStart, claimedLength, firstFreeProgramByte);
}

// ===========================================================================
// programMemoryHasOverlongLabelName (public) — src/c47/programming/manage.c
// ===========================================================================
// A label name longer than MAX_LABEL_NAME_LENGTH cannot have been produced by the calculator and can only come from a corrupt or crafted file.
// Such a name does not fit the fixed name buffers of its consumers, ASSIGN's argumentName[16] and tamBuffer[32], so the loaders use this walk to reject it.
// The walk runs from the given step to the end of program memory; a step the walker cannot decode ends it, where scanLabelsAndPrograms() truncates too.
pub export fn programMemoryHasOverlongLabelName(step_arg: [*c]u8) callconv(.c) bool_t {
    var step = step_arg;
    while (frontier_next_step.programBytesAvailable(step, 2) != 0 and !isAtEndOfPrograms(step)) {
        if (checkOpCodeOfStep(step, ITM_LBL) and
            (step[1] == STRING_LABEL_VARIABLE or step[1] == LOCAL_LABEL_VARIABLE) and
            frontier_next_step.programBytesAvailable(step, 3) != 0 and
            step[2] > MAX_LABEL_NAME_LENGTH)
        {
            return true;
        }
        step = frontier_next_step.findNextStep(step);
        if (step == null) {
            break;
        }
    }
    return false;
}

// ===========================================================================
// scanLabelsAndPrograms (public) — THE test-reached fn.
// ===========================================================================
pub export fn scanLabelsAndPrograms() callconv(.c) void {
    var stepNumber: u32 = 0;
    var nextStep: [*c]u8 = undefined;
    var step: [*c]u8 = beginOfProgramMemory;
    // Hard upper bound of the program region; a step that would advance past it
    // has a corrupt length and must not be walked, or findNextStep reads out of
    // bounds. (uint8_t *)(ram + RAM_SIZE_IN_BLOCKS).
    const programRegionEnd: [*c]u8 = ramEnd();

    freeC47Blocks(labelList, toBlocks(@sizeOf(labelList_t)) * (numberOfLabels +% numberOfStructureLabels));
    freeC47Blocks(programList, toBlocks(@sizeOf(programList_t)) * numberOfPrograms);

    numberOfLabels = 0;
    numberOfStructureLabels = 0;
    numberOfPrograms = 1;
    // numberOfLabels and numberOfPrograms are uint16_t globals the C increments
    // without a bound: a crafted program can carry more steps than they hold and
    // C wraps modulo 65536. `+%=` keeps that, where a checked add trapped on a
    // walk the state file controls -- the same reason freeProgramBytes below
    // uses @truncate/-%.
    while (!isAtEndOfPrograms(step)) { // .END.
        // The step is validated before it is counted, matching the order of the
        // filling pass below. Both passes therefore count the same steps, and the
        // structure section starts at the same index in each.
        nextStep = frontier_next_step.findNextStep(step);
        if (nextStep == null or @intFromPtr(nextStep) <= @intFromPtr(step) or @intFromPtr(nextStep) >= @intFromPtr(programRegionEnd)) {
            lastErrorCode = ERROR_UNDEFINED_OPCODE; // this step and everything after it are dropped
            break;
        }
        if (step[0] == ITM_LBL) { // LBL
            numberOfLabels +%= 1;
        } else if (comptime option_structured_pgm) {
            if (frontier_structured.structStepIsJumpTarget(step) != 0) { // a STRUCT branch end or loop top is a jump target too
                numberOfStructureLabels +%= 1;
            }
        }
        if (isAtEndOfProgram(step)) { // END
            if (!isAtEndOfPrograms(nextStep)) { // .END. following END is not the start of a new program
                numberOfPrograms +%= 1;
            }
        }
        step = nextStep;
    }

    // The STRUCT branch ends go in the same table, after every real label.
    // Appending them keeps every existing label index unchanged, which matters
    // because a key assignment holds an index and a menu entry is built from one.
    labelList = abi.allocC47BlocksAs(labelList_t, toBlocks(@sizeOf(labelList_t)) * (numberOfLabels +% numberOfStructureLabels));
    if (labelList == null) {
        // unlikely
        lastErrorCode = ERROR_RAM_FULL;
        return;
    }

    programList = abi.allocC47BlocksAs(programList_t, toBlocks(@sizeOf(programList_t)) * numberOfPrograms);
    if (programList == null) {
        // unlikely
        lastErrorCode = ERROR_RAM_FULL;
        return;
    }

    var structureLabel: u16 = numberOfLabels; // the structure section starts where the real labels end, so it fills from there

    numberOfLabels = 0;
    step = beginOfProgramMemory;
    programList[0].instructionPointer = step;
    programList[0].step = (0 + 1);
    numberOfPrograms = 1;
    stepNumber = 1;
    while (!isAtEndOfPrograms(step)) { // .END.
        nextStep = frontier_next_step.findNextStep(step);
        if (nextStep == null or @intFromPtr(nextStep) <= @intFromPtr(step) or @intFromPtr(nextStep) >= @intFromPtr(programRegionEnd)) {
            lastErrorCode = ERROR_UNDEFINED_OPCODE; // the labels and programs past it are dropped
            break;
        }
        if (checkOpCodeOfStep(step, ITM_LBL)) { // LBL
            labelList[numberOfLabels].program = @bitCast(numberOfPrograms);
            if (step[1] <= LAST_LOCAL_LABEL) { // Local label
                labelList[numberOfLabels].step = -@as(i32, @intCast(stepNumber));
                labelList[numberOfLabels].labelPointer = step + 1;
            } else if (step[1] == LOCAL_LABEL_VARIABLE) { // Local named label
                labelList[numberOfLabels].step = -@as(i32, @intCast(stepNumber));
                labelList[numberOfLabels].labelPointer = step + 2;
            } else { // Global label
                labelList[numberOfLabels].step = @intCast(stepNumber);
                labelList[numberOfLabels].labelPointer = step + 2;
            }

            labelList[numberOfLabels].instructionPointer = nextStep;
            numberOfLabels +%= 1;
        } else if (comptime option_structured_pgm) {
            // A build that cannot run the structures never looks these entries up, so
            // it does not carry them: at 24 bytes each they are what a program full of
            // structures would exhaust the table with.
            if (frontier_structured.structStepIsJumpTarget(step) != 0) { // a STRUCT jump target: labelPointer holds its number, the op code sits two bytes before it
                labelList[structureLabel].program = @bitCast(numberOfPrograms);
                labelList[structureLabel].step = -@as(i32, @intCast(stepNumber));
                labelList[structureLabel].labelPointer = step + 2;
                labelList[structureLabel].instructionPointer = nextStep;
                structureLabel +%= 1;
            }
        }

        if (isAtEndOfProgram(step)) { // END
            if (!isAtEndOfPrograms(nextStep)) { // .END. following END is not the start of a new program
                programList[numberOfPrograms].instructionPointer = step + 2;
                programList[numberOfPrograms].step = @intCast(stepNumber + 1);
                numberOfPrograms +%= 1;
            }
        }

        step = nextStep;
        stepNumber += 1;
    }

    // The following 2 lines added to address the FFFFFFFF issue in old state files
    firstFreeProgramByte = step;
    // @truncate, not @intCast, and wrapping subtraction. Upstream manage.c:210 is
    //   freeProgramBytes = (((uint8_t *)(ram + RAM_SIZE_IN_BLOCKS)) - firstFreeProgramByte) - 2;
    // which assigns a ptrdiff_t to `uint16_t freeProgramBytes`, so C narrows
    // implicitly and that is defined. The scan above walks `step` from a
    // restored program count, so a state file carrying a forged count walks it
    // to an arbitrary point in (or past) the pool: the difference then exceeds
    // u16, or goes negative in C's ptrdiff_t. Two's complement makes `-%` plus a
    // u16 @truncate bit-exact with the C for both, where the checked cast and
    // checked subtraction instead trapped -- reached by state_load_fuzz's
    // count_programs_32767.sav. Bounding the count is restoreProgramsSection's
    // job, not this line's; here parity with upstream is the contract.
    freeProgramBytes = @truncate((@intFromPtr(ramEnd()) -% @intFromPtr(firstFreeProgramByte)) -% 2);

    defineCurrentProgramFromCurrentStep();
    frontier_next_step.defineFirstDisplayedStep();
}

// ===========================================================================
// deleteStepsFromTo (public)
// ===========================================================================
pub export fn deleteStepsFromTo(from: [*c]u8, to: [*c]u8) callconv(.c) void {
    // `uint16_t opSize = to - from;` upstream: the span is a ptrdiff_t and C
    // narrows it implicitly. Deleting one step keeps it small, but _clearProgram
    // passes a whole program, and on new hardware the program region is larger
    // than a u16 can hold. @truncate keeps the C's low bits where a checked cast
    // would panic on the safety-checked build and truncate in `small` mode, so
    // the two targets would disagree. freeProgramBytes is the same u16 and wraps
    // for the same reason.
    const opSize: u16 = @truncate(@intFromPtr(to) -% @intFromPtr(from));

    // The structures left behind can be paired wrongly now, so VALID numbers them
    // again. This runs before the bytes move: afterwards the program that followed
    // has taken this address, and clearing then would strip a program the user never
    // touched.
    if (frontier_structured.structRangeHasNumbered(from, to) != 0) {
        frontier_structured.structClearProgramNumbers();
        frontier_structured.forClearChecked();
    }
    _ = frontier_char_string.xcopy(from, to, @intCast((@intFromPtr(firstFreeProgramByte) - @intFromPtr(to)) + 2));
    firstFreeProgramByte -= opSize;
    freeProgramBytes +%= opSize;
    scanLabelsAndPrograms();
}

// _removeLabelsAssignments (static)
fn _removeLabelsAssignments() void {
    var i: i16 = 0;
    var label: [256]u8 = undefined; // a global label name is a 1-byte-length string, so up to 255 bytes
    while (i < numberOfLabels) : (i += 1) {
        if ((labelList[@intCast(i)].program == currentProgramNumber) and (labelList[@intCast(i)].step > 0)) {
            const labelLength = boundProgramNameLength(labelList[@intCast(i)].labelPointer + 1, labelList[@intCast(i)].labelPointer[0]);
            _ = frontier_char_string.xcopy(&label, labelList[@intCast(i)].labelPointer + 1, labelLength);
            label[labelLength] = 0;
            frontier_assign.removeUserItemAssignments(ITM_XEQ, &label); // Remove label assignments
        }
    }
}

// fnClPAll is NOT defined here; the canonical fnClPAll is exported by
// program_clear.zig (a faithful copy of manage.c's fnClPAll body).
// The internal callers below must use that CANONICAL fnClPAll, because the
// confirmation system (config.c:1013) compares the registered confirmedFunction
// against indexOfItems[ITM_DELPALL].func, which is the canonical fnClPAll. So we
// call it through the `program_clear` import, not a local copy.

// _clearProgram (static) -> int
fn _clearProgram() c_int {
    if (beginOfCurrentProgram == beginOfProgramMemory and (@intFromPtr(endOfCurrentProgram) >= @intFromPtr(firstFreeProgramByte) or (endOfCurrentProgram[0] == 255 and endOfCurrentProgram[1] == 255))) { // There is only one program in memory
        program_clear.fnClPAll(CONFIRMED);
        return 1;
    } else {
        // Remove assignments of global labels in the program being deleted, before deleting the program
        _removeLabelsAssignments();

        const savedCurrentProgramNumber = currentProgramNumber;

        frontier_lbl_gto_xeq.goToPgmStep(currentProgramNumber, 1); // [DL] work around for crash when label deleted is not at the beginning of the program
        firstDisplayedLocalStepNumber = 0; // ditto

        deleteStepsFromTo(beginOfCurrentProgram, endOfCurrentProgram - (if (currentProgramNumber == numberOfPrograms) @as(usize, 2) else @as(usize, 0)));
        scanLabelsAndPrograms();
        // unlikely fails

        if (savedCurrentProgramNumber >= numberOfPrograms) { // The last program
            frontier_lbl_gto_xeq.goToPgmStep(numberOfPrograms, 1);
        } else { // Not the last program
            frontier_lbl_gto_xeq.goToPgmStep(savedCurrentProgramNumber, 1);
        }
        return 0;
    }
}

// ===========================================================================
// fnClP (public)
// ===========================================================================
pub export fn fnClP(label: u16) callconv(.c) void {
    const savedCurrentLocalStepNumber = currentLocalStepNumber;
    var savedCurrentProgramNumber = currentProgramNumber;

    while (currentSubroutineLevel() > 0) { // drop subroutine stack before deleting a program
        frontier_lbl_gto_xeq.fnReturn(0);
    }
    frontier_lbl_gto_xeq.fnReturn(0); // 1 more time to clean local registers

    frontier_lbl_gto_xeq.goToPgmStep(savedCurrentProgramNumber, savedCurrentLocalStepNumber);

    if (label == 0 and !tam.alpha and tam.digitsSoFar == 0) {
        const innerSaved = currentProgramNumber;
        const result = _clearProgram();
        if (result == 1 and innerSaved <= 1) {
            frontier_lbl_gto_xeq.fnGotoDot(1);
        }
    } else if (label >= FIRST_LABEL and label <= LAST_LABEL) {
        frontier_lbl_gto_xeq.fnGoto(label);
        const programNumberToDelete = currentProgramNumber;
        const result = _clearProgram();
        switch (result) {
            2 => {
                frontier_lbl_gto_xeq.goToPgmStep(savedCurrentProgramNumber, savedCurrentLocalStepNumber);
            },
            1 => {
                if (savedCurrentProgramNumber <= 1) { // RAM
                    frontier_lbl_gto_xeq.fnGotoDot(1);
                }
            },
            0 => {
                if (programNumberToDelete != savedCurrentProgramNumber) {
                    if (programNumberToDelete < savedCurrentProgramNumber) {
                        savedCurrentProgramNumber -= 1;
                    }
                    frontier_lbl_gto_xeq.goToPgmStep(savedCurrentProgramNumber, savedCurrentLocalStepNumber);
                }
            },
            else => {},
        }
    } else {
        frontier_error.displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "label {d} is not a global label", .{@as(u32, label)});
            moreInfoErr("In function fnClP:", errorMessage, null);
        }
    }
}

// ===========================================================================
// _getProgramSize (public — declared in manage.h)
// ===========================================================================
pub export fn _getProgramSize() callconv(.c) u32 {
    if (currentProgramNumber == numberOfPrograms) {
        const beginPtr: [*c]u8 = programList[currentProgramNumber - 1].instructionPointer;
        const memEnd = @intFromPtr(firstFreeProgramByte);
        var step: [*c]u8 = beginPtr;
        // A truncated or corrupt last program can lack its END/.END. sentinel; bound
        // the walk to the used program-memory region (as boundProgramNameLength does)
        // so findNextStep cannot run into garbage and leave step below beginPtr, which
        // would underflow the pointer subtraction below on malformed input.
        while (@intFromPtr(step) < memEnd and !(isAtEndOfProgram(step) or isAtEndOfPrograms(step))) { // END or .END.
            const next = frontier_next_step.findNextStep(step);
            if (@intFromPtr(next) <= @intFromPtr(step)) break; // no forward progress: corrupt opcode
            step = next;
        }
        if (@intFromPtr(step) > memEnd) step = firstFreeProgramByte;
        return @intCast((@intFromPtr(step) - @intFromPtr(beginPtr)) + 2);
    } else {
        return @intCast(@intFromPtr(programList[currentProgramNumber].instructionPointer) - @intFromPtr(programList[currentProgramNumber - 1].instructionPointer));
    }
}

// ===========================================================================
// defineCurrentProgramFromGlobalStepNumber (public)
// ===========================================================================
pub export fn defineCurrentProgramFromGlobalStepNumber(globalStepNumber: i16) callconv(.c) void {
    currentProgramNumber = 0;
    while (globalStepNumber >= programList[currentProgramNumber].step) {
        currentProgramNumber += 1;
        if (currentProgramNumber >= numberOfPrograms) {
            break;
        }
    }

    if (currentProgramNumber == 0) { // 1 based; a step number under the first program's start leaves the loop at 0
        currentProgramNumber = 1;
    }

    if (currentProgramNumber == numberOfPrograms) {
        endOfCurrentProgram = programList[currentProgramNumber - 1].instructionPointer + _getProgramSize();
    } else {
        endOfCurrentProgram = programList[currentProgramNumber].instructionPointer;
    }
    beginOfCurrentProgram = programList[currentProgramNumber - 1].instructionPointer;
}

// ===========================================================================
// defineCurrentProgramFromCurrentStep (public)
// ===========================================================================
pub export fn defineCurrentProgramFromCurrentStep() callconv(.c) void {
    if (@intFromPtr(beginOfProgramMemory) <= @intFromPtr(currentStep) and @intFromPtr(currentStep) <= @intFromPtr(firstFreeProgramByte)) {
        currentProgramNumber = 0;
        while (@intFromPtr(currentStep) >= @intFromPtr(programList[currentProgramNumber].instructionPointer)) {
            currentProgramNumber += 1;
            if (currentProgramNumber >= numberOfPrograms) {
                break;
            }
        }

        if (currentProgramNumber >= numberOfPrograms) {
            endOfCurrentProgram = programList[currentProgramNumber - 1].instructionPointer + _getProgramSize();
        } else {
            endOfCurrentProgram = programList[currentProgramNumber].instructionPointer;
        }
        beginOfCurrentProgram = programList[currentProgramNumber - 1].instructionPointer;
    }
}

// ===========================================================================
// scrollPemBackwards / scrollPemForwards (public)
// ===========================================================================
pub export fn scrollPemBackwards() callconv(.c) void {
    if (firstDisplayedLocalStepNumber > 0) {
        firstDisplayedLocalStepNumber -= 1;
    }
    frontier_next_step.defineFirstDisplayedStep();
}

pub export fn scrollPemForwards() callconv(.c) void {
    if (getNumberOfSteps() > 6) {
        if (currentLocalStepNumber > 3) {
            firstDisplayedLocalStepNumber += 1;
            firstDisplayedStep = frontier_next_step.findNextStep(firstDisplayedStep);
        } else if (currentLocalStepNumber == 3) {
            firstDisplayedLocalStepNumber = 1;
        }
    }
}

// ===========================================================================
// pemLeftOffset (public)
// X_SHIFT == X_SHIFT_R  -> (getSystemFlag(FLAG_SBshfR)?X_SHIFT_R:X_SHIFT_L)==X_SHIFT_R
// i.e. getSystemFlag(FLAG_SBshfR) is true. Whether the shift indicator sits on the
// T line at all is the screen owner's shiftOnTline.
// ===========================================================================
const FLAG_SBshfR: i32 = 0x803B;
inline fn xShiftIsRight() bool_t {
    return getSystemFlag(FLAG_SBshfR);
}
pub export fn pemLeftOffset(y: i32) callconv(.c) i32 {
    if (y > Y_POSITION_OF_REGISTER_T_LINE or xShiftIsRight() or frontier_screen.shiftOnTline == 0) {
        return frontier_screen.noShiftOffset;
    } else {
        return frontier_screen.shiftOffset; // Offset to allow for f/g
    }
}

// The reverse-video row number is padded on its left up to the line's indent, so the
// highlight reaches the edge the text starts from.
inline fn padSelectedRowNumber(y: i32) void {
    lcdFillRect(@intCast(pemLeftOffset(y) - frontier_screen.noShiftOffset), @intCast(y), @intCast(frontier_screen.noShiftOffset), 20, 1);
}

// _isAngleType (static)
fn _isAngleType(literalType: u8) bool_t {
    return switch (literalType) {
        STRING_ANGLE_RADIAN, STRING_ANGLE_GRAD, STRING_ANGLE_DEGREE, STRING_ANGLE_MULTPI => true,
        else => false,
    };
}

// ===========================================================================
// fnPem (public) — PEM display. Not test-reachable; ported faithfully.
// ===========================================================================
pub export fn fnPem(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;

    var currentStepNumber: u32 = undefined;
    var firstDisplayedStepNumber: u32 = undefined;
    var line: u16 = undefined;
    var firstLine: u16 = undefined;
    var stepsThatWouldBeDisplayed: u16 = 7;
    var step: [*c]u8 = undefined;
    var nextStep: [*c]u8 = undefined;
    var lblOrEnd: bool_t = undefined;
    // Only the build without OPTION_STRUCT_INDENT lays the columns out from these
    // two; with the indent on, every step but the first label and the ENDs hangs at
    // one indent whatever it is.
    var lblOrEndOrXeq: bool_t = undefined;
    var gto: bool_t = undefined;
    const inTamMode: bool_t = (tam.mode != 0) and programList[currentProgramNumber - 1].step > 0;
    const numberOfSteps: u16 = getNumberOfSteps();
    var linesOfCurrentStep: u16 = 1;
    lastIntegerBase = 0;

    if ((calcMode != CM_PEM) and (calcMode != CM_CONFIRMATION)) {
        calcMode = CM_PEM;
        frontier_softmenus.showSoftmenu(-MNU_PFN);
        screenUpdatingMode &= ~@as(u8, SCRUPD_MANUAL_MENU);
        hourGlassIconEnabled = false;
        aimBuffer[0] = 0;
        setCurrentInputVariableInvalid(); // currentInputVariable = INVALID_VARIABLE
        frontier_screen.refreshScreen(227);
        return;
    }

    if (currentLocalStepNumber < firstDisplayedLocalStepNumber) {
        firstDisplayedLocalStepNumber = currentLocalStepNumber;
        frontier_next_step.defineFirstDisplayedStep();
    }

    if (currentLocalStepNumber == 0) {
        currentLocalStepNumber = 1;
        pemCursorIsZerothStep = true;
    } else if (currentLocalStepNumber > 1) {
        pemCursorIsZerothStep = false;
    }

    const progStepAbs: i32 = absI(programList[currentProgramNumber - 1].step);
    currentStepNumber = @intCast(@as(i32, @intCast(currentLocalStepNumber)) + progStepAbs - 1);
    firstDisplayedStepNumber = @intCast(@as(i32, @intCast(firstDisplayedLocalStepNumber)) + progStepAbs - 1);
    step = firstDisplayedStep;
    programListEnd = false;
    lastProgramListEnd = false;

    if (firstDisplayedLocalStepNumber == 0) {
        const vm: c_int = if ((pemCursorIsZerothStep and tam.mode == 0 and aimBuffer[0] == 0)) vmReverse else vmNormal;
        _ = frontier_screen.showString("0000:" ++ STD_SPACE_4_PER_EM, &standardFont, @intCast(pemLeftOffset(Y_POSITION_OF_REGISTER_T_LINE)), @intCast(Y_POSITION_OF_REGISTER_T_LINE), vm, 0, 1);
        if (vm == vmReverse) {
            padSelectedRowNumber(Y_POSITION_OF_REGISTER_T_LINE);
        }
        abi.fmtBufZ(tmpString[0..2560], "{{Prgm #{d}/{d}: {d} bytes / {d} step{s}}}", .{ @as(u32, currentProgramNumber), @as(u32, numberOfPrograms), @as(u32, _getProgramSize()), @as(u32, numberOfSteps), if (numberOfSteps == 1) @as([*:0]const u8, "") else @as([*:0]const u8, "s") });
        _ = frontier_screen.showString(tmpString, &standardFont, @intCast(pemLeftOffset(Y_POSITION_OF_REGISTER_T_LINE) + 41), @intCast(Y_POSITION_OF_REGISTER_T_LINE), vmNormal, 0, 0);
        firstLine = 1;
    } else {
        firstLine = 0;
    }

    var lineOffset: i32 = 0;
    var lineOffsetTam: i32 = 0;
    var pemIndent: i32 = 0;
    // The editor draws the columns the exported listing writes, one indent being
    // PEM_STRUCT_INDENT spaces and a space ten pixels. The window can open inside a
    // structure, so the levels above it are counted before the first line is laid
    // out. The count runs to any depth; only the drawn column is clamped.
    var structLevel: i8 = 0;
    var drawLevel: i8 = 0;
    if (comptime option_struct_indent) {
        var scanStep: [*c]u8 = programList[currentProgramNumber - 1].instructionPointer;
        while (scanStep != null and @intFromPtr(scanStep) < @intFromPtr(firstDisplayedStep)) : (scanStep = frontier_next_step.findNextStep(scanStep)) {
            if (frontier_structured.structStepClosesIndent(scanStep) != 0 and structLevel > 0) {
                structLevel -= 1;
            }
            if (frontier_structured.structStepOpensIndent(scanStep) != 0) {
                structLevel += 1;
            }
        }
    }

    line = firstLine;
    while (line < 7) : (line += 1) {
        nextStep = frontier_next_step.findNextStep(step);
        abi.fmtBufZ(tmpString[0..2560], "{d:0>4}:" ++ STD_SPACE_4_PER_EM, .{@as(u32, @intCast(@as(c_int, @intCast(@as(i32, firstDisplayedLocalStepNumber) + @as(i32, line) - lineOffset + lineOffsetTam))))});
        if (@as(i32, @intCast(firstDisplayedStepNumber)) + @as(i32, line) - lineOffset == @as(i32, @intCast(currentStepNumber))) {
            tamOverPemYPos = @intCast(Y_POSITION_OF_REGISTER_T_LINE + 21 * @as(i32, line));
            const vm: c_int = if ((pemCursorIsZerothStep and tam.mode == 0 and aimBuffer[0] == 0) or (tam.mode != 0 and (programList[currentProgramNumber - 1].step > 0))) vmNormal else vmReverse;
            _ = frontier_screen.showString(tmpString, &standardFont, @intCast(pemLeftOffset(@intCast(tamOverPemYPos))), tamOverPemYPos, vm, @intFromBool(false), @intFromBool(true));
            if (vm == vmReverse) {
                padSelectedRowNumber(@intCast(tamOverPemYPos));
            }
            currentStep = step;
        } else {
            _ = frontier_screen.showString(tmpString, &standardFont, @intCast(pemLeftOffset(Y_POSITION_OF_REGISTER_T_LINE + 21 * @as(i32, line))), @intCast(Y_POSITION_OF_REGISTER_T_LINE + 21 * @as(i32, line)), vmNormal, 0, 1);
        }

        // Automatically, when on battery (low processor) skip long processing register printing.
        // On firmware this wraps the per-line body in an extra condition.
        const doBody: bool_t = if (comptime dmcp_build)
            (!(!runningOnSimOrUSB() and !emptyKeyBuffer() and keyEmpty() == 1) or (@as(i32, @intCast(firstDisplayedStepNumber)) + @as(i32, line) - lineOffset == @as(i32, @intCast(currentStepNumber))))
        else
            true;

        if (doBody) {
            if (comptime option_struct_indent) {
                // The left margin holds the first label of the program, END and .END.,
                // and nothing else. Every other step hangs one indent in, later labels
                // with them.
                lblOrEnd = (checkOpCodeOfStep(step, ITM_LBL) and @as(i32, firstDisplayedLocalStepNumber) + @as(i32, line) - lineOffset + lineOffsetTam == 1) or
                    isAtEndOfProgram(step) or isAtEndOfPrograms(step);
            } else {
                lblOrEndOrXeq = checkOpCodeOfStep(step, ITM_LBL) or isAtEndOfProgram(step) or isAtEndOfPrograms(step) or checkOpCodeOfStep(step, ITM_XEQ);
                lblOrEnd = checkOpCodeOfStep(step, ITM_LBL) or isAtEndOfProgram(step) or isAtEndOfPrograms(step);
                gto = checkOpCodeOfStep(step, ITM_GTO);
            }
            if (comptime option_struct_indent) {
                if (frontier_structured.structStepClosesIndent(step) != 0 and structLevel > 0) {
                    structLevel -= 1; // the body ends here, so the closer prints on the column its opener printed on
                }
                // ELSE and WHILE come back one indent to their opener's column, which is
                // the outdent the exported listing takes from its name table. The outdent
                // comes off the level, not off the column, so a clamped ELSE lands on its
                // opener's column instead of one left of it.
                drawLevel = structLevel - @as(i8, if (frontier_structured.structStepOnOpenerColumn(step) != 0 and structLevel > 0) 1 else 0);
                // PEM_MAX_STRUCT_LEVELS is what the 400 pixel screen has room for, so
                // anything deeper draws in that column rather than running the step off
                // the right edge.
                pemIndent = 10 * PEM_STRUCT_INDENT * @as(i32, if (drawLevel > PEM_MAX_STRUCT_LEVELS) PEM_MAX_STRUCT_LEVELS else drawLevel);
            }
            if (programList[currentProgramNumber - 1].step > 0) {
                if ((!pemCursorIsZerothStep and @as(i32, @intCast(firstDisplayedStepNumber)) + @as(i32, line) - lineOffset == @as(i32, @intCast(currentStepNumber)) + 1) or (line == 1 and tam.mode != 0 and pemCursorIsZerothStep)) {
                    tamOverPemYPos = @intCast(Y_POSITION_OF_REGISTER_T_LINE + 21 * @as(i32, line));
                    if (tam.mode != 0) {
                        line += 1;
                        lineOffset += 1;
                        lineOffsetTam += 1;
                        _ = frontier_screen.showString(tmpString, &standardFont, @intCast(pemLeftOffset(@intCast(tamOverPemYPos))), tamOverPemYPos, vmReverse, @intFromBool(false), @intFromBool(true));
                        if (line >= 7) {
                            break;
                        }
                        abi.fmtBufZ(tmpString[0..2560], "{d:0>4}:" ++ STD_SPACE_4_PER_EM, .{@as(u32, @intCast(@as(c_int, @intCast(@as(i32, firstDisplayedLocalStepNumber) + @as(i32, line) - lineOffset + lineOffsetTam))))});
                        _ = frontier_screen.showString(tmpString, &standardFont, @intCast(pemLeftOffset(Y_POSITION_OF_REGISTER_T_LINE + 21 * @as(i32, line))), @intCast(Y_POSITION_OF_REGISTER_T_LINE + 21 * @as(i32, line)), vmNormal, 0, 1);
                    }
                } else if (@as(i32, @intCast(firstDisplayedStepNumber)) + @as(i32, line) - lineOffset == @as(i32, @intCast(currentStepNumber)) and lblOrEnd and (step[0] != ITM_LBL)) {
                    if (tam.mode != 0) {
                        line += 1;
                        lineOffset += 1;
                        lineOffsetTam += 1;
                        _ = frontier_screen.showString(tmpString, &standardFont, @intCast(pemLeftOffset(@intCast(tamOverPemYPos))), tamOverPemYPos, vmReverse, @intFromBool(false), @intFromBool(true));
                        if (line >= 7) {
                            break;
                        }
                        abi.fmtBufZ(tmpString[0..2560], "{d:0>4}:" ++ STD_SPACE_4_PER_EM, .{@as(u32, @intCast(@as(c_int, @intCast(@as(i32, firstDisplayedLocalStepNumber) + @as(i32, line) - lineOffset + lineOffsetTam))))});
                        _ = frontier_screen.showString(tmpString, &standardFont, @intCast(pemLeftOffset(Y_POSITION_OF_REGISTER_T_LINE + 21 * @as(i32, line))), @intCast(Y_POSITION_OF_REGISTER_T_LINE + 21 * @as(i32, line)), vmNormal, 0, 1);
                    }
                }
            }
            frontier_decode.decodeOneStep(step);
            if (@as(i32, @intCast(firstDisplayedStepNumber)) + @as(i32, line) - lineOffset == @as(i32, @intCast(currentStepNumber)) and tam.mode == 0) {
                if (getSystemFlag(FLAG_ALPHA)) {
                    const tmpChar = tmpString[4];
                    tmpString[4] = 0;
                    const isRem = strcmp(tmpString, "REM ") == 0;
                    const is42 = strcmp(tmpString, "42" ++ STD_alpha) == 0 or strcmp(tmpString, "42" ++ STD_RIGHT_TACK) == 0;
                    tmpString[4] = tmpChar;
                    const tmpChar7 = tmpString[7];
                    tmpString[7] = 0;
                    const isFinish = strcmp(tmpString, "FINISH ") == 0; // FINISH with its space is seven bytes, so the four-byte compare above cannot see it
                    tmpString[7] = tmpChar7;
                    const cursorInString: i16 = if (isRem) T_cursorPos + 4 else if (isFinish) T_cursorPos + 7 else if (is42) T_cursorPos + 5 else T_cursorPos;
                    _ = frontier_char_string.xcopy(tmpString + 2 + @as(usize, @intCast(cursorInString)) + 2, tmpString + 2 + @as(usize, @intCast(cursorInString)), @intCast(stringByteLength(tmpString + 2 + @as(usize, @intCast(cursorInString))) + 1));
                    tmpString[2 + @as(usize, @intCast(cursorInString))] = STD_CURSOR[0];
                    tmpString[2 + @as(usize, @intCast(cursorInString)) + 1] = STD_CURSOR[1];
                } else if (aimBuffer[0] != 0) {
                    // The number is shown as in NIM while it is entered, with its
                    // base, denominator or unit after the cursor.
                    var hint: [20]u8 = undefined;
                    lastIntegerBase = decodedIntegerBase;
                    var tstr: [*c]u8 = frontier_char_string.stringCopy(tmpString, nimBufferDisplay + 2);
                    tstr[0] = STD_CURSOR[0];
                    tstr += 1;
                    tstr[0] = STD_CURSOR[1];
                    tstr += 1;
                    frontier_bufferize.nimHint(&hint);
                    tstr = frontier_char_string.stringCopy(tstr, &hint);
                    if (comptime option_drg_cfg) {
                        const unit: u8 = if (frontier_bufferize.nimComplexPart())
                            nimPolarAngularMode
                        else if (editingLiteralType >= STRING_ANGLE_RADIAN and editingLiteralType <= STRING_ANGLE_MULTPI)
                            editingLiteralType - STRING_ANGLE_RADIAN
                        else
                            amNone;
                        if (unit == amDMS) {
                            tstr = frontier_char_string.stringCopy(tstr, frontier_bufferize.nimDmsMark());
                        } else if (unit < amNone) {
                            tstr[0] = angleChars[@as(usize, unit) * 2];
                            tstr += 1;
                            tstr[0] = angleChars[@as(usize, unit) * 2 + 1];
                            tstr += 1;
                        }
                    } else if (_isAngleType(editingLiteralType)) {
                        tstr[0] = angleChars[@as(usize, @intCast((editingLiteralType - STRING_ANGLE_RADIAN))) * 2];
                        tstr += 1;
                        tstr[0] = angleChars[@as(usize, @intCast((editingLiteralType - STRING_ANGLE_RADIAN))) * 2 + 1];
                        tstr += 1;
                    }
                    tstr[0] = 0;
                    tstr += 1;
                }
            }
            // Split long lines
            var numberOfExtraLines: c_int = 0;
            var offset: i32 = 0;
            var endStr: [*c]const u8 = undefined;
            while (offset <= 1500) {
                // the step is drawn pemIndent further right, so that much less of it fits the line
                endStr = frontier_char_string.stringAfterPixels(tmpString + @as(usize, @intCast(offset)), &standardFont, @intCast(337 - pemIndent), false, false);
                if (endStr[0] == 0) break;
                const lineByteLength: i32 = @intCast(@intFromPtr(endStr) - @intFromPtr(tmpString + @as(usize, @intCast(offset))));
                numberOfExtraLines += 1;
                _ = frontier_char_string.xcopy(tmpString + @as(usize, @intCast(offset + 300)), tmpString + @as(usize, @intCast(offset + lineByteLength)), @intCast(stringByteLength(endStr) + 1));
                tmpString[@as(usize, @intCast(offset + lineByteLength))] = 0;
                offset += 300;
            }
            stepsThatWouldBeDisplayed -%= @intCast(numberOfExtraLines);
            if (@as(i32, @intCast(firstDisplayedStepNumber)) + @as(i32, line) - lineOffset == @as(i32, @intCast(currentStepNumber))) {
                linesOfCurrentStep += @intCast(numberOfExtraLines);
            }

            if (comptime option_struct_indent) {
                _ = frontier_screen.showString(tmpString, &standardFont, @intCast(pemLeftOffset(Y_POSITION_OF_REGISTER_T_LINE + 21 * @as(i32, line)) + (if (lblOrEnd) @as(i32, 41) else 41 + 10 * PEM_STRUCT_INDENT) + pemIndent), @intCast(Y_POSITION_OF_REGISTER_T_LINE + 21 * @as(i32, line)), vmNormal, 0, 0);
            } else {
                _ = frontier_screen.showString(tmpString, &standardFont, @intCast(pemLeftOffset(Y_POSITION_OF_REGISTER_T_LINE + 21 * @as(i32, line)) + (if (lblOrEndOrXeq) @as(i32, 41) else if (gto) @as(i32, 81) else @as(i32, 61))), @intCast(Y_POSITION_OF_REGISTER_T_LINE + 21 * @as(i32, line)), vmNormal, 0, 0);
            }
            offset = 300;
            while (numberOfExtraLines != 0 and line <= 5) {
                line += 1;
                _ = frontier_screen.showString(tmpString + @as(usize, @intCast(offset)), &standardFont, @intCast(pemLeftOffset(Y_POSITION_OF_REGISTER_T_LINE + 21 * @as(i32, line)) + 61 + pemIndent), @intCast(Y_POSITION_OF_REGISTER_T_LINE + 21 * @as(i32, line)), vmNormal, 0, 0);
                numberOfExtraLines -= 1;
                offset += 300;
                lineOffset += 1;
            }
            if (comptime option_struct_indent) {
                if (frontier_structured.structStepOpensIndent(step) != 0) {
                    structLevel += 1; // the body steps below stand one level further in
                }
            }
            if (isAtEndOfProgram(step)) {
                programListEnd = true;
                if (nextStep[0] == 255 and nextStep[1] == 255) {
                    lastProgramListEnd = true;
                }
                break;
            }
            if ((step[0] == 255) and (step[1] == 255)) {
                programListEnd = true;
                lastProgramListEnd = true;
                break;
            }
            step = nextStep;
        }
    }

    if (lastErrorCode != ERROR_NONE) {
        frontier_screen.refreshRegisterLine(errorMessageRegisterLine);
    }

    if (aimBuffer[0] != 0 and linesOfCurrentStep > 4) { // Limited to 4 lines so as not to cause crash or freeze
        if (getSystemFlag(FLAG_ALPHA)) {
            pemAlpha(ITM_BACKSPACE);
        } else {
            pemAddNumber(ITM_BACKSPACE, true);
        }

        clearScreen();
        frontier_softmenus.showSoftmenuCurrentPart();
        fnPem(NOPARAM);
    }
    if ((@as(i32, currentLocalStepNumber) + (if (inTamMode) (if (currentLocalStepNumber < numberOfSteps) @as(i32, 2) else @as(i32, 1)) else @as(i32, 0))) >= (@as(i32, firstDisplayedLocalStepNumber) + @as(i32, stepsThatWouldBeDisplayed))) {
        firstDisplayedLocalStepNumber = @intCast(@as(i32, currentLocalStepNumber) - @as(i32, stepsThatWouldBeDisplayed) + 1 + (if (inTamMode) (if (currentLocalStepNumber < numberOfSteps) @as(i32, 2) else @as(i32, 1)) else @as(i32, 0)));
        if (inTamMode and (firstDisplayedLocalStepNumber > 1) and (@as(i32, currentLocalStepNumber) + 1 >= (@as(i32, firstDisplayedLocalStepNumber) + @as(i32, stepsThatWouldBeDisplayed)))) {
            firstDisplayedLocalStepNumber += 1;
        }

        frontier_next_step.defineFirstDisplayedStep();
        clearScreen();
        frontier_softmenus.showSoftmenuCurrentPart();
        fnPem(NOPARAM);
    }
}

inline fn setCurrentInputVariableInvalid() void {
    currentInputVariable = @intCast(INVALID_VARIABLE);
}

// DMCP-only helpers for the fnPem battery skip guard.
extern fn emptyKeyBuffer() bool_t;
inline fn keyEmpty() c_int {
    if (comptime dmcp_build) {
        return rom.key_empty();
    } else {
        return 1;
    }
}
const FLAG_USB: i32 = 0xc028; // runningOnSimOrUSB = getSystemFlag(FLAG_USB) on firmware; true on host
inline fn runningOnSimOrUSB() bool_t {
    if (comptime dmcp_build) {
        return getSystemFlag(FLAG_USB);
    } else {
        return true;
    }
}

// _insertInProgram (static)
fn _insertInProgram(dat_in: [*c]const u8, size: u16) void {
    var dat = dat_in;
    const _dynamicMenuItem = dynamicMenuItem;
    var globalStepNumber: u16 = undefined;
    // Read before the copy loop below moves dat. The top bit of the first byte is
    // what says the op takes two bytes: a one byte op followed by its operand byte
    // is two bytes long as well, and reading that pair as one op turns x= ? A into IF.
    const insertedOp: u16 = if ((dat[0] & 0x80) != 0 and size >= 2) @as(u16, dat[1]) + (@as(u16, dat[0] & 0x7f) << 8) else dat[0];

    if (freeProgramBytes < size) {
        const oldBeginOfProgramMemory = beginOfProgramMemory;
        const programSizeInBlocks: u32 = RAM_SIZE_IN_BLOCKS - toC47MemPtr(beginOfProgramMemory);
        const newProgramSizeInBlocks: u32 = toBlocks(toBytes(programSizeInBlocks) - freeProgramBytes + size);
        freeProgramBytes += @intCast(toBytes(newProgramSizeInBlocks - programSizeInBlocks));
        resizeProgramMemory(@intCast(newProgramSizeInBlocks));
        currentStep = currentStep - @intFromPtr(oldBeginOfProgramMemory) + @intFromPtr(beginOfProgramMemory);
        firstDisplayedStep = firstDisplayedStep - @intFromPtr(oldBeginOfProgramMemory) + @intFromPtr(beginOfProgramMemory);
        beginOfCurrentProgram = beginOfCurrentProgram - @intFromPtr(oldBeginOfProgramMemory) + @intFromPtr(beginOfProgramMemory);
        endOfCurrentProgram = endOfCurrentProgram - @intFromPtr(oldBeginOfProgramMemory) + @intFromPtr(beginOfProgramMemory);
    }

    {
        var pos: [*c]u8 = firstFreeProgramByte + 1 + size;
        while (@intFromPtr(pos) > @intFromPtr(currentStep)) : (pos -= 1) {
            pos[0] = (pos - size)[0];
        }
    }

    var tmpB: u16 = 0; // convert codes for v3>xyz and xyz>v3 respecting 3D_PHYS
    if (size == 2 and (insertedOp == ITM_STKtoV3 or insertedOp == ITM_V3toSTK)) { // the size keeps the two bytes written here and the caller's size in step
        switch (insertedOp) {
            ITM_STKtoV3 => tmpB = if (getSystemFlag(FLAG_3DPHYS) == false) ITM_STKtoV3_M else ITM_STKtoV3_P,
            ITM_V3toSTK => tmpB = if (getSystemFlag(FLAG_3DPHYS) == false) ITM_V3toSTK_M else ITM_V3toSTK_P,
            else => {},
        }
        currentStep[0] = @intCast((tmpB >> 8) | 0x80);
        currentStep += 1;
        currentStep[0] = @intCast(tmpB & 0x00FF);
        currentStep += 1;
    } else if (size == 2 and (insertedOp == ITM_toPOL2 or insertedOp == ITM_toREC2)) { // convert >RECT and >POLAR to the relevant ones, respecting RP_HP
        tmpB = ITM_toPOL_HP + (insertedOp - ITM_toPOL2) + (if (getSystemFlag(FLAG_HPRP)) @as(u16, 0) else @as(u16, 2));
        currentStep[0] = @intCast((tmpB >> 8) | 0x80);
        currentStep += 1;
        currentStep[0] = @intCast(tmpB & 0x00FF);
        currentStep += 1;
    } else {
        var i: u16 = 0;
        while (i < size) : (i += 1) {
            currentStep[0] = dat[0];
            currentStep += 1;
            dat += 1;
        }
    }

    firstFreeProgramByte += size;
    freeProgramBytes -= size;
    currentLocalStepNumber += 1;
    endOfCurrentProgram += size;
    globalStepNumber = @intCast(@as(i32, currentLocalStepNumber) + programList[currentProgramNumber - 1].step - 1);
    scanLabelsAndPrograms();
    if (frontier_structured.structOpHasNumber(insertedOp) != 0) { // a numbered step joining the program repairs nothing, so VALID numbers them all again
        frontier_structured.structClearProgramNumbers();
    }
    if (insertedOp == ITM_FORx or insertedOp == ITM_NEXTx or insertedOp == ITM_FORYXx or insertedOp == ITM_FORTOPx) { // a FOR or a NEXT joining the program unchecks the ones already there
        frontier_structured.forClearChecked();
    }
    dynamicMenuItem = -1;
    frontier_lbl_gto_xeq.goToGlobalStep(globalStepNumber);
    dynamicMenuItem = _dynamicMenuItem;
}

// _closeAlphaMenus (static)
fn _closeAlphaMenus() void {
    var i: usize = 0;
    while (i < SOFTMENU_STACK_SIZE) : (i += 1) {
        switch (-softmenu[@intCast(softmenuStack[0].softmenuId)].menuItem) {
            MNU_ALPHAINTL, MNU_ALPHAintl, MNU_ALPHAMATH, MNU_ALPHA_OMEGA, MNU_alpha_omega, MNU_ALPHA => {
                frontier_softmenus.popSoftmenu();
            },
            MNU_MyAlpha => {
                switch (-softmenu[@intCast(softmenuStack[1].softmenuId)].menuItem) {
                    MNU_ALPHAINTL, MNU_ALPHAintl, MNU_ALPHAMATH, MNU_ALPHA_OMEGA, MNU_alpha_omega, MNU_ALPHA => {
                        frontier_softmenus.popSoftmenu();
                    },
                    else => {
                        softmenuStack[0].softmenuId = 0; // MyMenu
                        return;
                    },
                }
                // C falls through to default (return) after the MNU_MyAlpha case.
                return;
            },
            else => {
                return;
            },
        }
    }
    // Just in case softmenuStack was filled with AIM-related menus
    var j: usize = 0;
    while (j < SOFTMENU_STACK_SIZE) : (j += 1) {
        softmenuStack[j].softmenuId = 0; // MyMenu
    }
}

// The length and the text of a literal after its header in tmpString, inserted
// as one step. The C narrows the length into the step's length byte.
fn _pemInsertText(tmpPtr_in: [*c]u8, text: [*c]const u8) void {
    var tmpPtr = tmpPtr_in;
    const length: u32 = @intCast(stringByteLength(text));
    tmpPtr[0] = @truncate(length);
    tmpPtr += 1;
    _ = frontier_char_string.xcopy(tmpPtr, text, @intCast(length));
    _insertInProgram(tmpString, @intCast(length + @as(u32, @intCast(@intFromPtr(tmpPtr) - @intFromPtr(tmpString)))));
}

// ===========================================================================
// pemAlpha (public)
// ===========================================================================
pub export fn pemAlpha(item_in: i16) callconv(.c) void {
    var item = item_in;
    var editCommand: bool_t = false;
    if (item == ITM_EDIT) {
        var aimFunc: i16 = currentStep[0];

        if (aimFunc & 0x80 != 0) {
            aimFunc &= 0x7f;
            aimFunc <<= 8;
            aimFunc |= currentStep[1];
        }

        tam.function = aimFunc;
        frontier_decode.decodeOneStep(currentStep);
        const ll = stringByteLength(tmpString);
        if (aimFunc == ITM_LITERAL) { // literal
            _ = frontier_char_string.xcopy(aimBuffer, tmpString + 2, @intCast(ll)); // purposely overshoot aimbuffer
            aimBuffer[@intCast(ll - 2 - 2)] = 0;
            T_cursorPos = frontier_char_string.stringLastGlyph(aimBuffer) + 1;
            deleteStepsFromTo(currentStep, frontier_next_step.findNextStep(currentStep));
            editCommand = true;
            item = 0;
        } else if (aimFunc == ITM_REM or aimFunc == ITM_FINISH) { // REM or FINISH
            const pfx = stringByteLength(&indexOfItems[@intCast(aimFunc)].itemCatalogName) + 3; // the name, the space and the two-byte opening quote before the text
            _ = frontier_char_string.xcopy(aimBuffer, tmpString + @as(usize, @intCast(pfx)), @intCast(ll));
            aimBuffer[@intCast(ll - 2 - pfx)] = 0;
            T_cursorPos = frontier_char_string.stringLastGlyph(aimBuffer) + 1;
            deleteStepsFromTo(currentStep, frontier_next_step.findNextStep(currentStep));
            tam.function = aimFunc;
            editCommand = true;
            item = aimFunc;
        } else {
            aimBuffer[0] = 0;
            return;
        }
    }

    if (!getSystemFlag(FLAG_ALPHA)) {
        resetShiftState();
        displayAIMbufferoffset = 0;
        if (!editCommand) {
            T_cursorPos = 0;
            aimBuffer[0] = 0;
        }

        frontier_softmenus.showSoftmenu(-MNU_ALPHA);
        setSystemFlag(FLAG_ALPHA);
        if (comptime !dmcp_build) calcModeAimGui();

        if (tam.function < 128) { // literal
            tmpString[0] = @intCast(tam.function);
            tmpString[1] = STRING_LABEL_VARIABLE;
            tmpString[2] = 0;
            _insertInProgram(tmpString, 3);
        } else { // rem or 42str
            tmpString[0] = @intCast((@as(u16, @bitCast(tam.function)) >> 8) | 0x80);
            tmpString[1] = @intCast(@as(u16, @bitCast(tam.function)) & 0xff);
            tmpString[2] = STRING_LABEL_VARIABLE;
            tmpString[3] = 0;
            _insertInProgram(tmpString, 4);
        }
        currentLocalStepNumber -= 1;
        currentStep = frontier_next_step.findPreviousStep(currentStep);
    }
    if (indexOfItems[@intCast(item)].func == c_addItemToBuffer) {
        const len = stringByteLength(aimBuffer);
        item = @bitCast(numlockReplacements(0, item, getSystemFlag(FLAG_NUMLOCK), shiftF, shiftG));
        if (alphaCase == AC_LOWER) {
            if (ITM_A <= item and item <= ITM_Z) {
                item += (ITM_a - ITM_A);
            }
        }

        if ((nextChar == NC_NORMAL) or ((item != ITM_DOWN_ARROW) and (item != ITM_UP_ARROW))) {
            item = @bitCast(frontier_bufferize.convertItemToSubOrSup(@bitCast(item), nextChar));
            const inputCharLength = stringByteLength(&indexOfItems[@intCast(item)].itemSoftmenuName);
            if (len < (256 - inputCharLength) and frontier_char_string.stringGlyphLength(aimBuffer) < 196) {
                _ = frontier_char_string.xcopy(aimBuffer + @as(usize, @intCast(T_cursorPos)) + @as(usize, @intCast(inputCharLength)), aimBuffer + @as(usize, @intCast(T_cursorPos)), @intCast(stringByteLength(aimBuffer + @as(usize, @intCast(T_cursorPos))) + 1));
                _ = frontier_char_string.xcopy(aimBuffer + @as(usize, @intCast(T_cursorPos)), &indexOfItems[@intCast(item)].itemSoftmenuName, @intCast(inputCharLength));
                T_cursorPos += @intCast(inputCharLength);
            }
        }
    } else if (item == ITM_BACKSPACE) {
        if (aimBuffer[0] == 0) {
            deleteStepsFromTo(currentStep, frontier_next_step.findNextStep(currentStep));
            clearSystemFlag(FLAG_ALPHA);
            calcModeNormalGuiCall();
            _closeAlphaMenus();
            return;
        } else if (T_cursorPos == 0) {
            return;
        } else {
            const cursorByte = aimBuffer[@intCast(T_cursorPos)];
            aimBuffer[@intCast(T_cursorPos)] = 0;
            const lastGlyphPos = frontier_char_string.stringLastGlyph(aimBuffer);
            aimBuffer[@intCast(T_cursorPos)] = cursorByte;
            _ = frontier_char_string.xcopy(aimBuffer + @as(usize, @intCast(lastGlyphPos)), aimBuffer + @as(usize, @intCast(T_cursorPos)), @intCast(stringByteLength(aimBuffer + @as(usize, @intCast(T_cursorPos))) + 1));
            T_cursorPos = lastGlyphPos;
        }
    } else if (item == ITM_ENTER) {
        pemCloseAlphaInput();
        frontier_next_step.defineFirstDisplayedStep();
        _closeAlphaMenus();
        return;
    } else if (item == ITM_USERMODE) {
        fnFlipFlag(FLAG_USER);
        return;
    } else if (item == ITM_CLA) { // JM addon
        aimBuffer[0] = 0;
        T_cursorPos = 0;
        nextChar = NC_NORMAL;
    } else if (item == CHR_numL and !getSystemFlag(FLAG_NUMLOCK)) { // JM addon
        alphaCase = AC_UPPER;
        SetSetting(indexOfItems[@intCast(CHR_num)].param);
        return;
    } else if (item == CHR_numU and getSystemFlag(FLAG_NUMLOCK)) { // JM addon
        alphaCase = AC_UPPER;
        SetSetting(indexOfItems[@intCast(CHR_num)].param);
        return;
    } else if (item == ITM_CASEUP and alphaCase != AC_UPPER) { // JM addon
        nextChar = NC_NORMAL;
        SetSetting(indexOfItems[@intCast(CHR_case)].param);
        return;
    } else if (item == ITM_CASEDN and alphaCase != AC_LOWER) { // JM addon
        nextChar = NC_NORMAL;
        SetSetting(indexOfItems[@intCast(CHR_case)].param);
        return;
    } else if (item == CHR_num) { // JM addon
        alphaCase = AC_UPPER;
        SetSetting(indexOfItems[@intCast(item)].param);
        return;
    } else if (item == CHR_case) { // JM addon
        nextChar = NC_NORMAL;
        clearSystemFlag(FLAG_NUMLOCK);
        SetSetting(indexOfItems[@intCast(item)].param);
        return;
    } else if (item == ITM_SCR) { // JM addon
        SetSetting(indexOfItems[@intCast(item)].param);
        return;
    } else if (indexOfItems[@intCast(item)].func == c_fnT_ARROW) { // JM addon
        fnT_ARROW(indexOfItems[@intCast(item)].param);
        return;
    }

    var aimFunc2: i16 = currentStep[0];
    if (aimFunc2 & 0x80 != 0) {
        aimFunc2 &= 0x7f;
        aimFunc2 <<= 8;
        aimFunc2 |= currentStep[1];
    }

    deleteStepsFromTo(currentStep, frontier_next_step.findNextStep(currentStep));
    if (aimFunc2 < 128) { // literal
        tmpString[0] = @intCast(aimFunc2);
        tmpString[1] = STRING_LABEL_VARIABLE;
        _pemInsertText(tmpString + 2, aimBuffer);
    } else { // rem or 42str
        tmpString[0] = @intCast((@as(u16, @bitCast(aimFunc2)) >> 8) | 0x80);
        tmpString[1] = @intCast(@as(u16, @bitCast(aimFunc2)) & 0xff);
        tmpString[2] = STRING_LABEL_VARIABLE;
        _pemInsertText(tmpString + 3, aimBuffer);
    }
    currentLocalStepNumber -= 1;
    currentStep = frontier_next_step.findPreviousStep(currentStep);
    if (!programListEnd) {
        scrollPemBackwards();
    }
}

// ===========================================================================
// pemCloseAlphaInput (public)
// ===========================================================================
pub export fn pemCloseAlphaInput() callconv(.c) void {
    aimBuffer[0] = 0;
    clearSystemFlag(FLAG_ALPHA);
    calcModeNormalGuiCall();
    currentLocalStepNumber += 1;
    currentStep = frontier_next_step.findNextStep(currentStep);
    // C: if((getNumberOfSteps() - currentLocalStepNumber) > 4) — the display window
    // only advances when there are >4 steps below the cursor. The subtraction is
    // signed int in C (uint16 promote), so an underflow goes negative, not wrapping.
    if ((@as(i32, getNumberOfSteps()) - @as(i32, currentLocalStepNumber)) > 4) {
        firstDisplayedLocalStepNumber += 1;
        firstDisplayedStep = frontier_next_step.findNextStep(firstDisplayedStep);
    }
    _closeAlphaMenus();
}

// ===========================================================================
// pemAlphaEdit (public)
// ===========================================================================
pub export fn pemAlphaEdit(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (getSystemFlag(FLAG_ALPHA) or calcMode != CM_PEM or tam.mode != 0) {
        hourGlassIconEnabled = false;
        return;
    }
    var func: i16 = currentStep[0];
    if (func & 0x80 != 0) {
        func &= 0x7f;
        func <<= 8;
        func |= currentStep[1];
    }
    if ((func == ITM_LITERAL or func == ITM_REM or func == ITM_FINISH)) {
        pemAlpha(ITM_EDIT);
    }
    hourGlassIconEnabled = false;
}

// ===========================================================================
// pemAddNumber (public)
// ===========================================================================
pub export fn pemAddNumber(item: i16, doInsertInProgram: bool) callconv(.c) void {
    if (aimBuffer[0] == 0) {
        lastIntegerBase = 0;
        editingLiteralType = 0;
        tmpString[0] = @intCast(ITM_LITERAL);
        tmpString[1] = STRING_LONG_INTEGER;
        tmpString[2] = 0;
        _insertInProgram(tmpString, 3);
        _ = memset(nimBufferDisplay, 0, NIM_BUFFER_LENGTH);
        currentLocalStepNumber -= 1;
        currentStep = frontier_next_step.findPreviousStep(currentStep);
        frontier_bufferize.nimStartNumber(item);
    }

    if (item == ITM_BACKSPACE and ((aimBuffer[0] == '+' and aimBuffer[1] != 0 and aimBuffer[2] == 0) or aimBuffer[1] == 0)) {
        aimBuffer[0] = 0;
    } else {
        frontier_bufferize.addItemToNimBuffer(item);
        if (stringByteLength(aimBuffer) > 255) {
            frontier_bufferize.addItemToNimBuffer(ITM_BACKSPACE);
        }
    }
    clearSystemFlag(FLAG_ALPHA);

    if (aimBuffer[0] != '!') {
        if (doInsertInProgram) {
            deleteStepsFromTo(currentStep, frontier_next_step.findNextStep(currentStep));
        }
        if (aimBuffer[0] != 0) {
            var tmpPtr: [*c]u8 = tmpString;
            const numBuffer: [*c]u8 = if (aimBuffer[0] == '+') aimBuffer + 1 else aimBuffer;
            tmpPtr[0] = @intCast(ITM_LITERAL);
            tmpPtr += 1;
            switch (nimNumberPart) {
                NP_INT_10, NP_INT_16 => {
                    if (lastIntegerBase != 0) {
                        tmpPtr[0] = STRING_SHORT_INTEGER;
                        tmpPtr += 1;
                        tmpPtr[0] = @intCast(lastIntegerBase);
                        tmpPtr += 1;
                    } else {
                        tmpPtr[0] = STRING_LONG_INTEGER;
                        tmpPtr += 1;
                    }
                },
                NP_REAL_FLOAT_PART, NP_REAL_EXPONENT, NP_HP32SII_DENOMINATOR, NP_FRACTION_DENOMINATOR => {
                    tmpPtr[0] = STRING_REAL34;
                    tmpPtr += 1;
                },
                NP_COMPLEX_INT_PART, NP_COMPLEX_FLOAT_PART, NP_COMPLEX_EXPONENT => {
                    tmpPtr[0] = STRING_COMPLEX34;
                    tmpPtr += 1;
                },
                else => {
                    tmpPtr[0] = STRING_LONG_INTEGER;
                    tmpPtr += 1;
                },
            }
            if (_isAngleType(editingLiteralType)) {
                (tmpPtr - 1)[0] = editingLiteralType; // [DL] force literal type when editing angles
            }
            if (doInsertInProgram) {
                _pemInsertText(tmpPtr, numBuffer);
                currentLocalStepNumber -= 1;
                currentStep = frontier_next_step.findPreviousStep(currentStep);
                if (!programListEnd) {
                    scrollPemBackwards();
                }
            }
        }
        calcMode = CM_PEM;
    } else {
        aimBuffer[0] = 0;
        nimNumberPart = NP_EMPTY;
    }
}

// ===========================================================================
// pemCloseNumberInput (public)
// ===========================================================================
pub export fn pemCloseNumberInput() callconv(.c) void {
    frontier_bufferize.nimCompleteNumber();
    if (editingLiteralType > 0) { // For EDIT: close with right data/angle type
        switch (editingLiteralType) {
            STRING_DATE => _pemCloseDateInput(),
            STRING_TIME => _pemCloseTimeInput(),
            STRING_ANGLE_RADIAN, STRING_ANGLE_GRAD, STRING_ANGLE_DEGREE, STRING_ANGLE_DMS, STRING_ANGLE_MULTPI => _pemCloseAngleInput(editingLiteralType),
            else => {},
        }
        return;
    }

    if (aimBuffer[0] != 0) {
        const numBuffer: [*c]u8 = if (aimBuffer[0] == '+') aimBuffer + 1 else aimBuffer;
        var tmpPtr: [*c]u8 = tmpString;
        var inputLength: u32 = @intCast(stringByteLength(numBuffer));
        var doneWithBinaryLiteral: bool_t = false;

        if ((lastIntegerBase != 0) and (nimNumberPart == NP_INT_10 or nimNumberPart == NP_INT_16)) {
            const hashPos = strlen(aimBuffer);
            abi.fmtBufZ(aimBuffer[hashPos..AIM_BUFFER_LENGTH], "#{d}", .{@as(u32, @intCast(lastIntegerBase))});
            if (!frontier_bufferize.checkShortIntegerDigits(aimBuffer)) {
                aimBuffer[hashPos] = 0;
                return;
            }
            nimNumberPart = NP_INT_BASE;
        } else if (nimNumberPart == NP_INT_BASE) {
            if (!frontier_bufferize.checkShortIntegerDigits(aimBuffer)) {
                return;
            }
        } else if (nimNumberPart == NP_INT_16) {
            frontier_error.displayCalcErrorMessage(ERROR_INVALID_INTEGER_INPUT, ERR_REGISTER_LINE);
            if (comptime extra_info) {
                moreInfoErr("In function pemCloseNumberInput:", "An hexdigit is not allowed in a long integer!", null);
            }
            return;
        }

        deleteStepsFromTo(currentStep, frontier_next_step.findNextStep(currentStep));
        tmpPtr[0] = @intCast(ITM_LITERAL);
        tmpPtr += 1;
        switch (nimNumberPart) {
            NP_INT_BASE => {
                var basePtr: [*c]u8 = numBuffer;
                while (basePtr[0] != '#') {
                    basePtr += 1;
                }
                basePtr[0] = 0;
                basePtr += 1;
                inputLength = @intCast(stringByteLength(numBuffer)); // numBuffer truncated
                if (inputLength >= @sizeOf(u64) and numBuffer[0] != '-') {
                    const base: u8 = @intCast(atoi(basePtr));
                    var val: u64 = 0;
                    tmpPtr[0] = BINARY_SHORT_INTEGER;
                    tmpPtr += 1;
                    tmpPtr[0] = @intCast(atoi(basePtr));
                    tmpPtr += 1;
                    var i: u32 = 0;
                    while (i < inputLength) : (i += 1) {
                        const c = numBuffer[i];
                        if ('0' <= c and c <= '9') {
                            val *%= base;
                            val +%= (c - '0');
                        } else if ('A' <= c and c <= 'F') {
                            val *%= base;
                            val +%= (c - 'A' + 10);
                        } else if ('a' <= c and c <= 'f') {
                            val *%= base;
                            val +%= (c - 'a' + 10);
                        }
                    }
                    const valBytes: [*]const u8 = std.mem.asBytes(&val);
                    var j: u32 = 0;
                    while (j < @sizeOf(u64)) : (j += 1) {
                        tmpPtr[0] = valBytes[j];
                        tmpPtr += 1;
                    }
                    _insertInProgram(tmpString, @intCast(@intFromPtr(tmpPtr) - @intFromPtr(tmpString)));
                    doneWithBinaryLiteral = true;
                } else {
                    tmpPtr[0] = STRING_SHORT_INTEGER;
                    tmpPtr += 1;
                    tmpPtr[0] = @intCast(atoi(basePtr));
                    tmpPtr += 1;
                }
            },
            NP_REAL_FLOAT_PART, NP_REAL_EXPONENT, NP_HP32SII_DENOMINATOR, NP_FRACTION_DENOMINATOR => {
                // A program literal takes no fraction, so a fraction is written as its value.
                const fraction = frontier_bufferize.nimFractionEntered();
                if (inputLength >= REAL34_SIZE_IN_BYTES or fraction) {
                    var val: real34_t = undefined;
                    tmpPtr[0] = BINARY_REAL34;
                    tmpPtr += 1;
                    if (fraction) {
                        frontier_bufferize.nimLiteralValue(&val, null);
                    } else {
                        stringToReal34(numBuffer, &val);
                    }
                    const valBytes: [*]const u8 = std.mem.asBytes(&val);
                    var i: u32 = 0;
                    while (i < REAL34_SIZE_IN_BYTES) : (i += 1) {
                        tmpPtr[0] = valBytes[i];
                        tmpPtr += 1;
                    }
                    _insertInProgram(tmpString, @intCast(@intFromPtr(tmpPtr) - @intFromPtr(tmpString)));
                    doneWithBinaryLiteral = true;
                } else {
                    tmpPtr[0] = STRING_REAL34;
                    tmpPtr += 1;
                }
            },
            NP_COMPLEX_INT_PART, NP_COMPLEX_FLOAT_PART, NP_COMPLEX_EXPONENT, NP_COMPLEX_FRACTION_DENOMINATOR, NP_COMPLEX_HP32SII_DENOMINATOR => {
                // A program literal takes no fraction and no polar form, so these
                // are written as their value.
                const polar = frontier_bufferize.nimPolarEntry();
                const fraction = frontier_bufferize.nimFractionEntered();
                if (inputLength >= toBytes(COMPLEX34_SIZE_IN_BLOCKS) or fraction or polar) {
                    var re: real34_t = undefined;
                    var im: real34_t = undefined;
                    if (fraction or polar) {
                        frontier_bufferize.nimLiteralValue(&re, &im);
                    } else {
                        var imag: [*c]u8 = numBuffer;
                        while (imag[0] != 'i' and imag[0] != 0) {
                            imag += 1;
                        }
                        if (imag[0] == 'i') {
                            if (@intFromPtr(imag) > @intFromPtr(numBuffer) and (imag - 1)[0] == '-') {
                                imag[0] = '-';
                                (imag - 1)[0] = 0;
                            } else if (@intFromPtr(imag) > @intFromPtr(numBuffer) and (imag - 1)[0] == '+') {
                                imag[0] = 0;
                                (imag - 1)[0] = 0;
                                imag += 1;
                            } else {
                                imag[0] = 0;
                            }
                        }
                        stringToReal34(numBuffer, &re);
                        stringToReal34(imag, &im);
                    }

                    tmpPtr[0] = BINARY_COMPLEX34;
                    tmpPtr += 1;
                    const reBytes: [*]const u8 = std.mem.asBytes(&re);
                    var i: u32 = 0;
                    while (i < REAL34_SIZE_IN_BYTES) : (i += 1) {
                        tmpPtr[0] = reBytes[i];
                        tmpPtr += 1;
                    }
                    const imBytes: [*]const u8 = std.mem.asBytes(&im);
                    var k: u32 = 0;
                    while (k < REAL34_SIZE_IN_BYTES) : (k += 1) {
                        tmpPtr[0] = imBytes[k];
                        tmpPtr += 1;
                    }
                    _insertInProgram(tmpString, @intCast(@intFromPtr(tmpPtr) - @intFromPtr(tmpString)));
                    doneWithBinaryLiteral = true;
                } else {
                    tmpPtr[0] = STRING_COMPLEX34;
                    tmpPtr += 1;
                }
            },
            else => {
                tmpPtr[0] = STRING_LONG_INTEGER;
                tmpPtr += 1;
            },
        }
        if (!doneWithBinaryLiteral) {
            _pemInsertText(tmpPtr, numBuffer);
            pemCursorIsZerothStep = false;
        }
    } else {
        deleteStepsFromTo(currentStep, frontier_next_step.findNextStep(currentStep));
    }

    aimBuffer[0] = '!';
    nimNumberPart = NP_EMPTY;
    lastIntegerBase = 0;
}

// _pemCloseTimeInput (static)
fn _pemCloseTimeInput() void {
    switch (nimNumberPart) {
        NP_INT_10, NP_REAL_FLOAT_PART => {
            deleteStepsFromTo(currentStep, frontier_next_step.findNextStep(currentStep));
            if (aimBuffer[0] != 0) {
                const numBuffer: [*c]u8 = if (aimBuffer[0] == '+') aimBuffer + 1 else aimBuffer;
                var tmpPtr: [*c]u8 = tmpString;
                tmpPtr[0] = @intCast(ITM_LITERAL);
                tmpPtr += 1;
                tmpPtr[0] = STRING_TIME;
                tmpPtr += 1;
                _pemInsertText(tmpPtr, numBuffer);
            }
            aimBuffer[0] = '!';
        },
        else => {},
    }
}

// _pemCloseDateInput (static)
fn _pemCloseDateInput() void {
    if (nimNumberPart == NP_REAL_FLOAT_PART) {
        deleteStepsFromTo(currentStep, frontier_next_step.findNextStep(currentStep));
        if (aimBuffer[0] != 0) {
            const numBuffer: [*c]u8 = if (aimBuffer[0] == '+') aimBuffer + 1 else aimBuffer;
            var tmpPtr: [*c]u8 = tmpString;
            tmpPtr[0] = @intCast(ITM_LITERAL);
            tmpPtr += 1;
            tmpPtr[0] = STRING_DATE;
            tmpPtr += 1;

            _ = reallocateRegister(TEMP_REGISTER_1, dtReal34, 0, amNone);
            stringToReal34(numBuffer, reg34(TEMP_REGISTER_1));
            frontier_register_value_conversions.convertReal34RegisterToDateRegister(TEMP_REGISTER_1, TEMP_REGISTER_1, false);
            frontier_date_time.internalDateToJulianDay(reg34(TEMP_REGISTER_1), reg34(TEMP_REGISTER_1));

            if (lastErrorCode == 0) {
                real34ToString(reg34(TEMP_REGISTER_1), numBuffer); // the Julian day number, written over the typed date
                _pemInsertText(tmpPtr, numBuffer);
            }
        }
        aimBuffer[0] = '!';
    }
}

// _pemCloseAngleInput (static): the number closes as an angle literal of that type.
fn _pemCloseAngleInput(literalType: u8) void {
    frontier_bufferize.nimCompleteNumber();
    switch (nimNumberPart) {
        NP_FRACTION_DENOMINATOR, NP_HP32SII_DENOMINATOR, NP_INT_10, NP_REAL_FLOAT_PART, NP_REAL_EXPONENT => {
            if (nimNumberPart == NP_FRACTION_DENOMINATOR or nimNumberPart == NP_HP32SII_DENOMINATOR) {
                // An angle literal is text, so a fraction is written as the text of its value.
                var value: real34_t = undefined;
                frontier_bufferize.nimLiteralValue(&value, null);
                if (literalType == STRING_ANGLE_DMS) {
                    frontier_conversion_angles.real34FromDegToDms(&value, &value);
                }
                real34ToString(&value, aimBuffer);
                var exponent: usize = 0;
                while (aimBuffer[exponent] != 0 and aimBuffer[exponent] != 'E') : (exponent += 1) {}
                if (aimBuffer[exponent] == 'E') {
                    aimBuffer[exponent] = 'e'; // a literal takes its exponent in lower case
                }
            }
            deleteStepsFromTo(currentStep, frontier_next_step.findNextStep(currentStep));
            if (aimBuffer[0] != 0) {
                const numBuffer: [*c]u8 = if (aimBuffer[0] == '+') aimBuffer + 1 else aimBuffer;
                var tmpPtr: [*c]u8 = tmpString;
                tmpPtr[0] = @intCast(ITM_LITERAL);
                tmpPtr += 1;
                tmpPtr[0] = literalType;
                tmpPtr += 1;
                _pemInsertText(tmpPtr, numBuffer);
            }
            editingLiteralType = 0;
            aimBuffer[0] = '!';
        },
        else => {},
    }
}

// The literal type an angle key gives the number being entered, 0 for any other key.
fn _angleLiteralType(func: i16) u8 {
    return switch (func) {
        ITM_DEG2 => STRING_ANGLE_DEGREE,
        ITM_DMS2 => STRING_ANGLE_DMS,
        ITM_GRAD2 => STRING_ANGLE_GRAD,
        ITM_MULPI2 => STRING_ANGLE_MULTPI,
        ITM_RAD2 => STRING_ANGLE_RADIAN,
        else => 0,
    };
}

// ===========================================================================
// insertStepInProgram (public)
// ===========================================================================
pub export fn insertStepInProgram(newFunc: i16) callconv(.c) void {
    // A FOR or a NEXT enters in the form VALID has not passed, as a new partner
    // number enters as 00. VALID has to run before the program will.
    const func: i16 = @bitCast(frontier_structured.structNotCheckedOp(@bitCast(newFunc)));
    const opBytes: u32 = if (func >= 128) 2 else 1;

    if (func == ITM_END) {
        if (comptime option_structured_pgm) {
            // The split leaves the steps above the END behind, out of the editor's
            // reach and out of AVALID's on the way out. AVALID checks them here
            // instead, and holds the END back on a fault, as it holds the editor on
            // one.
            if (getSystemFlag(FLAG_AUTOVALID) and frontier_structured.structEndSplitsWell() == 0) {
                return;
            }
        }
        firstDisplayedLocalStepNumber = 0;
    }

    if (func == ITM_AIM or (tam.mode == 0 and getSystemFlag(FLAG_ALPHA))) {
        if (aimBuffer[0] != 0 and !getSystemFlag(FLAG_ALPHA)) {
            pemCloseNumberInput();
            aimBuffer[0] = 0;
        }
        tam.function = @intCast(ITM_LITERAL);
        pemAlpha(func);
        pemCursorIsZerothStep = false;
        return;
    } else if (func == ITM_REM or func == ITM_FINISH) {
        if (aimBuffer[0] != 0 and !getSystemFlag(FLAG_ALPHA)) {
            pemCloseNumberInput();
            aimBuffer[0] = 0;
        }
        if (catalog != 0) { // exit catalog and Asm Mode
            frontier_calc_mode.leaveAsmMode();
            frontier_softmenus.popSoftmenu();
            if (frontier_softmenus.currentMenu() == -MNU_CATALOG) { // drop the CAT menu too
                frontier_softmenus.popSoftmenu();
            }
        }
        tam.function = func;
        pemAlpha(func);
        pemCursorIsZerothStep = false;
        return;
    } else if (@as(u16, @bitCast(func)) == ITM_42STRING or @as(u16, @bitCast(func)) == ITM_42APPEND) {
        tmpString[0] = @intCast((@as(u16, @bitCast(func)) >> 8) | 0x80);
        tmpString[1] = @truncate(@as(u16, @bitCast(func)) & 0xff);
        tmpString[2] = @intCast(STRING_LABEL_VARIABLE);
        _pemInsertText(tmpString + 3, aimBuffer);
        aimBuffer[0] = 0;
        return;
    }

    const ufunc: u16 = @bitCast(func);
    if (indexOfItems[@intCast(func)].func == c_addItemToBuffer or
        (tam.mode == 0 and aimBuffer[0] != 0 and (ufunc == ITM_CHS or ufunc == ITM_CC or ufunc == ITM_op_j or ufunc == ITM_op_j_pol or ufunc == ITM_toINT or
            (nimNumberPart == NP_INT_BASE and ((isR47FAM() and (ufunc == ITM_SQUAREROOTX or ufunc == ITM_YX)) or
                (!isR47FAM() and (ufunc == ITM_1ONX or ufunc == ITM_LOG10)) or
                ufunc == ITM_RCL or ufunc == ITM_EXPONENT or ufunc == ITM_ENTER)))))
    {
        pemAddNumber(func, true);
        return;
    } else if (nimNumberPart == NP_INT_BASE) {
        return;
    } else if (ufunc == ITM_CONSTpi and aimBuffer[0] != 0 and !getSystemFlag(FLAG_ALPHA) and frontier_bufferize.nimPiAfterI()) {
        pemCloseNumberInput();
        aimBuffer[0] = 0;
        return;
    } else if (_angleLiteralType(func) != 0 and aimBuffer[0] != 0 and !getSystemFlag(FLAG_ALPHA) and (nimNumberPart == NP_INT_10 or nimNumberPart == NP_REAL_FLOAT_PART)) {
        _pemCloseAngleInput(_angleLiteralType(func));
        aimBuffer[0] = 0;
        return;
    } else if ((ufunc == ITM_dotD) and editingLiteralType != 0 and aimBuffer[0] != 0 and !getSystemFlag(FLAG_ALPHA)) {
        editingLiteralType = 0;
        pemCloseNumberInput();
        aimBuffer[0] = '!';
    } else if (option_drg_cfg and (ufunc == ITM_DRG) and aimBuffer[0] != 0 and !getSystemFlag(FLAG_ALPHA) and (drgConfig & (1 << DRG_NIM_BIT)) != 0 and (frontier_bufferize.nimComplexPart() or frontier_bufferize.nimRealOrFractionPart())) {
        if (frontier_bufferize.nimComplexPart()) {
            pemAddNumber(ITM_DRG, true); // the angle takes the unit DRG chooses, as in NIM, and the input stays open
            return;
        }
        var unit: u16 = editingLiteralType -% STRING_ANGLE_RADIAN; // STRING_ANGLE_* follow angularMode_t
        if (unit > amMultPi) {
            unit = amNone;
        }
        frontier_addons.DRG_cycNim(&unit);
        DRG_Cycling = 0;
        editingLiteralType = if (unit == amNone) 0 else STRING_ANGLE_RADIAN + @as(u8, @intCast(unit));
        pemAddNumber(ITM_NOP, true); // the step becomes a literal of that unit, and the input stays open
        return;
    } else if ((ufunc == ITM_DRG) and aimBuffer[0] != 0 and !getSystemFlag(FLAG_ALPHA) and (nimNumberPart == NP_INT_10 or nimNumberPart == NP_REAL_FLOAT_PART)) {
        if (currentAngularMode > amMultPi) {
            return;
        }
        _pemCloseAngleInput(STRING_ANGLE_RADIAN + @as(u8, @intCast(currentAngularMode))); // STRING_ANGLE_* follow angularMode_t
        aimBuffer[0] = 0;
        return;
    }

    if (tam.mode == 0 and !tam.alpha and aimBuffer[0] != 0 and ufunc != ITM_HMStoTM and ufunc != ITM_EXIT1) {
        if ((ufunc == ITM_dotD) or ((editingLiteralType == STRING_DATE) and (ufunc != ITM_ms))) {
            _pemCloseDateInput();
            if (aimBuffer[0] == '!') {
                aimBuffer[0] = 0;
                return;
            }
        } else if ((ufunc == ITM_ms) or (editingLiteralType == STRING_TIME)) {
            _pemCloseTimeInput();
            if (aimBuffer[0] == '!') {
                aimBuffer[0] = 0;
                return;
            }
        } else {
            pemCloseNumberInput(); // for EDIT this closes with the right angle type
            if (lastErrorCode == ERROR_NONE) {
                aimBuffer[0] = 0;
            }
            if (ufunc == ITM_ENTER) { // just close number editing, don't insert ENTER
                return;
            }
        }
    }

    var buffer: [16]u8 = undefined;
    _ = frontier_char_string.xcopy(&buffer, tmpString, 16); // Save tmpString content for dynamic menus

    if (func < 128) {
        tmpString[0] = @intCast(func);
    } else {
        tmpString[0] = @intCast((ufunc >> 8) | 0x80);
        tmpString[1] = @intCast(ufunc & 0xff);
    }

    switch (indexOfItems[@intCast(func)].status & PTP_STATUS) {
        PTP_DISABLED => {
            switch (ufunc) {
                ITM_KEYG, ITM_KEYX, ITM_42KEYG, ITM_42KEYX => {
                    var opLen: usize = undefined;
                    const keyFunc: u16 = if ((ufunc == ITM_42KEYG) or (ufunc == ITM_42KEYX)) ITM_42KEY else ITM_KEY;
                    tmpString[0] = @intCast((keyFunc >> 8) | 0x80);
                    tmpString[1] = @intCast(keyFunc & 0xff);
                    if (tam.keyAlpha) {
                        const nameLength: u16 = @intCast(stringByteLength(aimBuffer + @as(usize, @intCast(@divTrunc(AIM_BUFFER_LENGTH, 2)))));
                        tmpString[2] = INDIRECT_VARIABLE;
                        tmpString[3] = @intCast(nameLength);
                        _ = frontier_char_string.xcopy(tmpString + 4, aimBuffer + @as(usize, @intCast(@divTrunc(AIM_BUFFER_LENGTH, 2))), nameLength);
                        opLen = nameLength + 4;
                    } else if (tam.keyIndirect) {
                        tmpString[2] = INDIRECT_REGISTER;
                        tmpString[3] = @intCast(tam.key);
                        opLen = 4;
                    } else {
                        tmpString[2] = @intCast(tam.key);
                        opLen = 3;
                    }

                    tmpString[opLen + 0] = @intCast(if ((ufunc == ITM_KEYX) or (ufunc == ITM_42KEYX)) ITM_XEQ else ITM_GTO);
                    if (tam.alpha) {
                        const nameLength: u16 = @intCast(stringByteLength(aimBuffer));
                        tmpString[opLen + 1] = if (tam.indirect) INDIRECT_VARIABLE else if (tam.colon) LOCAL_LABEL_VARIABLE else STRING_LABEL_VARIABLE;
                        tmpString[opLen + 2] = @intCast(nameLength);
                        _ = frontier_char_string.xcopy(tmpString + opLen + 3, aimBuffer, nameLength);
                        _insertInProgram(tmpString, @intCast(nameLength + opLen + 3));
                    } else if (tam.indirect) {
                        tmpString[opLen + 1] = INDIRECT_REGISTER;
                        tmpString[opLen + 2] = @intCast(tam.value);
                        _insertInProgram(tmpString, @intCast(opLen + 3));
                    } else {
                        tmpString[opLen + 1] = @intCast(tam.value);
                        _insertInProgram(tmpString, @intCast(opLen + 2));
                    }
                },
                ITM_GTOP => {
                    if (comptime !dmcp_build) {
                        frontier_char_string.stringToUtf8(&indexOfItems[@intCast(func)].itemCatalogName, tmpString);
                        _ = printf("insertStepInProgram: %s\n", tmpString);
                    }
                },
                ITM_DELPALL => {
                    program_clear.fnClPAll(NOT_CONFIRMED);
                },
                ITM_BST => {
                    frontier_next_step.fnBst(NOPARAM);
                },
                ITM_SST => {
                    frontier_next_step.fnSst(NOPARAM);
                },
                VAR_ACC => {
                    tmpString[0] = @intCast(ITM_STO);
                    tmpString[1] = STRING_LABEL_VARIABLE;
                    tmpString[2] = 3;
                    tmpString[3] = 'A';
                    tmpString[4] = 'C';
                    tmpString[5] = 'C';
                    _insertInProgram(tmpString, 6);
                },
                VAR_UEST, VAR_LEST => {
                    tmpString[0] = @intCast(ITM_STO);
                    tmpString[1] = STRING_LABEL_VARIABLE;
                    tmpString[2] = 5;
                    if (ufunc == VAR_UEST) {
                        tmpString[3] = STD_UP_ARROW[0];
                        tmpString[4] = STD_UP_ARROW[1];
                    } else {
                        tmpString[3] = STD_DOWN_ARROW[0];
                        tmpString[4] = STD_DOWN_ARROW[1];
                    }
                    tmpString[5] = 'E';
                    tmpString[6] = 's';
                    tmpString[7] = 't';
                    _insertInProgram(tmpString, 8);
                },
                VAR_ULIM, VAR_LLIM => {
                    tmpString[0] = @intCast(ITM_STO);
                    tmpString[1] = STRING_LABEL_VARIABLE;
                    tmpString[2] = 5;
                    if (ufunc == VAR_ULIM) {
                        tmpString[3] = STD_UP_ARROW[0];
                        tmpString[4] = STD_UP_ARROW[1];
                    } else {
                        tmpString[3] = STD_DOWN_ARROW[0];
                        tmpString[4] = STD_DOWN_ARROW[1];
                    }
                    tmpString[5] = 'L';
                    tmpString[6] = 'i';
                    tmpString[7] = 'm';
                    _insertInProgram(tmpString, 8);
                },
                VAR_UY, VAR_LY, VAR_UX, VAR_LX => {
                    tmpString[0] = @intCast(ITM_STO);
                    tmpString[1] = STRING_LABEL_VARIABLE;
                    tmpString[2] = 3;
                    if (ufunc == VAR_UX or ufunc == VAR_UY) {
                        tmpString[3] = STD_UP_ARROW[0];
                        tmpString[4] = STD_UP_ARROW[1];
                    } else {
                        tmpString[3] = STD_DOWN_ARROW[0];
                        tmpString[4] = STD_DOWN_ARROW[1];
                    }
                    if (ufunc == VAR_UX or ufunc == VAR_LX) {
                        tmpString[5] = 'X';
                    } else {
                        tmpString[5] = 'Y';
                    }
                    _insertInProgram(tmpString, 6);
                },
                ITM_USERMODE => {
                    fnFlipFlag(FLAG_USER);
                },
                else => {},
            }
        },
        PTP_NONE => {
            if (ufunc == ITM_HMStoTM and aimBuffer[0] != 0 and !getSystemFlag(FLAG_ALPHA)) {
                _pemCloseTimeInput();
                if (aimBuffer[0] != '!') {
                    pemCloseNumberInput();
                    aimBuffer[0] = 0;
                    tmpString[0] = @intCast((ufunc >> 8) | 0x80);
                    tmpString[1] = @intCast(ufunc & 0xff);
                    _insertInProgram(tmpString, 2);
                }
                aimBuffer[0] = 0;
            } else {
                _insertInProgram(tmpString, @intCast(1 + @as(u16, @intFromBool(func >= 128))));
            }
        },
        PTP_NUMBER_16 => {
            if (frontier_items.isFunctionOldParam16(ufunc) != 0) { // little-endian param
                tmpString[2] = @intCast(@as(u16, @bitCast(tam.value)) & 0xff);
                tmpString[3] = @intCast(@as(u16, @bitCast(tam.value)) >> 8);
                _insertInProgram(tmpString, 4);
            } else { // big-endian param with indirection support
                if (tam.alpha and tam.indirect) {
                    const nameLength: u16 = @intCast(stringByteLength(aimBuffer));
                    tmpString[opBytes] = INDIRECT_VARIABLE;
                    tmpString[opBytes + 1] = @intCast(nameLength);
                    _ = frontier_char_string.xcopy(tmpString + opBytes + 2, aimBuffer, nameLength);
                    _insertInProgram(tmpString, @intCast(nameLength + opBytes + 2));
                } else if (tam.indirect) {
                    tmpString[opBytes] = INDIRECT_REGISTER;
                    // FIRST_LOCAL_REGISTER is 7000, so `.05` gives 7005: the C
                    // adds in `int` and stores into a char, keeping the low byte
                    // (0x5D). Widen before the add and truncate after it, or the
                    // narrowing traps on every keyed-in indirect local register.
                    tmpString[opBytes + 1] = @truncate(@as(u32, @bitCast(@as(i32, tam.value) + (if (tam.dot) @as(i32, FIRST_LOCAL_REGISTER) else 0))));
                    _insertInProgram(tmpString, @intCast(opBytes + 2));
                } else {
                    tmpString[2] = @intCast(@as(u16, @bitCast(tam.value)) >> 8);
                    tmpString[3] = @intCast(@as(u16, @bitCast(tam.value)) & 0xff);
                    _insertInProgram(tmpString, 4);
                }
            }
        },
        PTP_LITERAL, PTP_REM => {
            // nothing to do here
        },
        PTP_SKIP_BACK => {
            // A new partner number enters as 00 and nothing prompts for one: VALID
            // puts the numbers in. SKIP and BACK still take the value typed.
            tmpString[opBytes] = if (frontier_structured.structOpHasNumber(@bitCast(func)) != 0) 0 else @intCast(if (tam.dot) tam.value + FIRST_LOCAL_REGISTER_IN_KS_CODE else tam.value);
            _insertInProgram(tmpString, @intCast(opBytes + 1));
        },
        else => {
            const opBytes2: u32 = 1 + @as(u32, @intFromBool(func >= 128));

            if (tam.mode == TM_VALUE and ((indexOfItems[@intCast(func)].status & PTP_STATUS) == PTP_NUMBER_8_16) and tam.value > 250) {
                tmpString[opBytes2] = CNST_BEYOND_250;
                tmpString[opBytes2 + 1] = @intCast(tam.value - 250);
                _insertInProgram(tmpString, @intCast(opBytes2 + 2));
            } else if (tam.mode == TM_CMP and tam.value == TEMP_REGISTER_1) {
                tmpString[opBytes2] = if (real34IsZero(reg34(TEMP_REGISTER_1))) VALUE_0 else VALUE_1;
                _insertInProgram(tmpString, @intCast(opBytes2 + 1));
            } else if ((tam.mode == TM_FLAGR or tam.mode == TM_FLAGW) and tam.alpha and !tam.indirect) {
                tmpString[opBytes2] = SYSTEM_FLAG_NUMBER;
                tmpString[opBytes2 + 1] = @intCast(tam.value);
                _insertInProgram(tmpString, @intCast(opBytes2 + 2));
            } else if ((tam.mode == TM_MENU) and !tam.alpha and !tam.indirect) {
                var nameLength: u16 = undefined;
                tmpString[opBytes2] = STRING_LABEL_VARIABLE;
                if (tam.value == MNU_DYNAMIC) {
                    nameLength = @intCast(stringByteLength(&buffer));
                    tmpString[opBytes2 + 1] = @intCast(nameLength);
                    _ = frontier_char_string.xcopy(tmpString + opBytes2 + 2, &buffer, nameLength);
                    _insertInProgram(tmpString, @intCast(nameLength + opBytes2 + 2));
                } else {
                    nameLength = @intCast(stringByteLength(&indexOfItems[@intCast(tam.value)].itemCatalogName));
                    tmpString[opBytes2 + 1] = @intCast(nameLength);
                    _ = frontier_char_string.xcopy(tmpString + opBytes2 + 2, &indexOfItems[@intCast(tam.value)].itemCatalogName, nameLength);
                    _insertInProgram(tmpString, @intCast(nameLength + opBytes2 + 2));
                }
            } else if (tam.alpha) {
                const nameLength: u16 = @intCast(stringByteLength(aimBuffer));
                tmpString[opBytes2] = if (tam.indirect) INDIRECT_VARIABLE else if (tam.colon) LOCAL_LABEL_VARIABLE else STRING_LABEL_VARIABLE;
                tmpString[opBytes2 + 1] = @intCast(nameLength);
                _ = frontier_char_string.xcopy(tmpString + opBytes2 + 2, aimBuffer, nameLength);
                _insertInProgram(tmpString, @intCast(nameLength + opBytes2 + 2));
            } else if (tam.indirect) {
                tmpString[opBytes2] = INDIRECT_REGISTER;
                tmpString[opBytes2 + 1] = if (tam.dot) @intCast(tam.value + FIRST_LOCAL_REGISTER_IN_KS_CODE) else regCtoKS(tam.value);
                _insertInProgram(tmpString, @intCast(opBytes2 + 2));
            } else {
                tmpString[opBytes2] = if (tam.dot) @as(u8, @intCast(tam.value + FIRST_LOCAL_REGISTER_IN_KS_CODE)) else (if (tam.mode == TM_LABEL or tam.mode == TM_LBLONLY) @as(u8, @intCast(tam.value)) else regCtoKS(tam.value));
                _insertInProgram(tmpString, @intCast(opBytes2 + 1));
            }
        },
    }

    if (func != ITM_EDIT) {
        aimBuffer[0] = 0;
    }
}

// isFunctionOldParam16: cross-owner extern (real function).

// ===========================================================================
// insertUserItemInProgram (public)
// ===========================================================================
pub export fn insertUserItemInProgram(func: i16, funcParam: [*c]const u8) callconv(.c) void {
    var opBytes: usize = 0;
    const nameLength: u16 = @intCast(stringByteLength(funcParam));

    if ((!pemCursorIsZerothStep) and ((aimBuffer[0] == 0 and !getSystemFlag(FLAG_ALPHA)) or tam.mode != 0) and !isAtEndOfProgram(currentStep) and !isAtEndOfPrograms(currentStep)) {
        currentStep = frontier_next_step.findNextStep(currentStep);
        currentLocalStepNumber += 1;
    }
    if (func < 128) {
        tmpString[opBytes] = @intCast(func);
        opBytes += 1;
    } else {
        tmpString[opBytes] = @intCast((@as(u16, @bitCast(func)) >> 8) | 0x80);
        opBytes += 1;
        tmpString[opBytes] = @intCast(@as(u16, @bitCast(func)) & 0x7f);
        opBytes += 1;
    }

    tmpString[opBytes] = STRING_LABEL_VARIABLE;
    tmpString[opBytes + 1] = @intCast(nameLength);
    _ = frontier_char_string.xcopy(tmpString + opBytes + 2, funcParam, nameLength);
    _insertInProgram(tmpString, @intCast(nameLength + opBytes + 2));

    currentStep = frontier_next_step.findPreviousStep(currentStep);
    if (currentLocalStepNumber > 1) {
        currentLocalStepNumber -= 1;
    }
    pemCursorIsZerothStep = false;
    if (!programListEnd) {
        scrollPemBackwards();
    }
}

// ===========================================================================
// addStepInProgram (public)
// ===========================================================================
pub export fn addStepInProgram(func: i16) callconv(.c) void {
    const cursorWasZerothStep = pemCursorIsZerothStep;
    if ((!pemCursorIsZerothStep) and ((aimBuffer[0] == 0 and !getSystemFlag(FLAG_ALPHA)) or tam.mode != 0) and !isAtEndOfProgram(currentStep) and !isAtEndOfPrograms(currentStep)) {
        currentStep = frontier_next_step.findNextStep(currentStep);
        currentLocalStepNumber += 1;
    }
    insertStepInProgram(func);
    if ((aimBuffer[0] == 0 and !getSystemFlag(FLAG_ALPHA)) or tam.mode != 0) {
        currentStep = frontier_next_step.findPreviousStep(currentStep);
        if (currentLocalStepNumber > 1) {
            currentLocalStepNumber -= 1;
        }
        pemCursorIsZerothStep = false;
        if ((indexOfItems[@intCast(func)].status & PTP_STATUS) == PTP_DISABLED) {
            switch (@as(u16, @bitCast(func))) {
                VAR_ACC, VAR_ULIM, VAR_LLIM, VAR_UX, VAR_LX, VAR_UEST, VAR_LEST, VAR_UY, VAR_LY, ITM_DELP, ITM_DELPALL, ITM_GTOP, ITM_KEYG, ITM_KEYX, ITM_42KEYG, ITM_42KEYX, ITM_BST, ITM_SST => {},
                else => {
                    pemCursorIsZerothStep = cursorWasZerothStep; // no step went in, so the cursor stays where it was
                    return;
                },
            }
        }
        if (!programListEnd) {
            scrollPemBackwards();
        }
    }
}

// ===========================================================================
// findNamedLabel (public)
// ===========================================================================
pub export fn findNamedLabel(labelName: [*c]const u8, labelType: u8) callconv(.c) calcRegister_t {
    return findNamedLabelWithDuplicate(labelName, 0, labelType);
}

// ===========================================================================
// findProgramLabel (public)
// ===========================================================================
// The label-list index of the program a command names, for every command that keeps a program rather than jumping to it:
// PGMSLV, PGMINT, PGMPLT, PGMDRV, VARMNU, the sums and products, and the interactive arm of SOLVE, the integral, PLT f and
// the derivatives. A local label 00 to 99 or A to l is searched in the running program the way GTO and XEQ search it, a
// named label arrives already resolved, and a lettered register names a global label. INVALID_VARIABLE comes back with the
// reason already reported, so every caller stores only on a good answer and none of them repeats the three cases. `caller`
// is the "In function x:" text.
pub export fn findProgramLabel(label: u16, caller: [*:0]const u8) callconv(.c) calcRegister_t {
    if (label <= LAST_LOCAL_LABEL) { // Local label from 00 to 99 or from A to l
        var lbl: u16 = 0;
        while (lbl < numberOfLabels) : (lbl += 1) {
            if (labelList[lbl].program > currentProgramNumber) { // After the current program
                break;
            }
            if (labelList[lbl].program == currentProgramNumber and labelList[lbl].step < 0 and
                labelList[lbl].labelPointer[0] == label and (labelList[lbl].labelPointer - 1)[0] == ITM_LBL)
            {
                return @intCast(@as(i32, lbl) + FIRST_LABEL);
            }
        }
        frontier_error.displayCalcErrorMessage(ERROR_LABEL_NOT_FOUND, ERR_REGISTER_LINE);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "there is no local label {d:0>2} in current program", .{@as(u32, label)});
            moreInfoErr(caller, errorMessage, null);
        }
        return INVALID_VARIABLE;
    }
    if (FIRST_LABEL <= label and label <= LAST_LABEL) {
        return @intCast(label);
    }
    if (REGISTER_X <= @as(i32, label) and @as(i32, label) <= REGISTER_T) { // Interactive mode
        var buf: [2]u8 = .{ frontier_screen_snap.letteredRegisterName(@intCast(label)), 0 };
        const found = findNamedLabel(&buf, GLOBAL_LABELS);
        if (found == INVALID_VARIABLE) {
            frontier_error.displayCalcErrorMessage(ERROR_LABEL_NOT_FOUND, ERR_REGISTER_LINE);
            if (comptime extra_info) {
                abi.fmtBufZ(errorMessage[0..512], "string '{s}' is not a named label", .{buf[0..1]});
                moreInfoErr(caller, errorMessage, null);
            }
        }
        return found;
    }
    frontier_error.displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE);
    if (comptime extra_info) {
        abi.fmtBufZ(errorMessage[0..512], "unexpected parameter {d}", .{@as(u32, label)});
        moreInfoErr(caller, errorMessage, null);
    }
    return INVALID_VARIABLE;
}

// ===========================================================================
// findNamedLabelWithDuplicate (public)
// ===========================================================================
pub export fn findNamedLabelWithDuplicate(labelName: [*c]const u8, dupNumIn: i16, labelType: u8) callconv(.c) calcRegister_t {
    var dupNum = dupNumIn;
    if ((labelType == ALL_LABELS) or (labelType == LOCAL_LABELS)) { // Start searching for local named labels
        var labelFound: bool = false;
        var firstLabel: u16 = 0;
        var nextLabel: u16 = 0;
        var lbl: u16 = 0;

        while (lbl < numberOfLabels) : (lbl += 1) {
            if (labelList[lbl].program > currentProgramNumber) { // After the current program
                break;
            }
            if (labelList[lbl].program == currentProgramNumber) { // Within the current progrm
                if (labelList[lbl].step < 0 and (labelList[lbl].labelPointer - 1)[0] == LOCAL_LABEL_VARIABLE) { // Is a named local label
                    const lblNameLen = boundProgramNameLength(labelList[lbl].labelPointer + 1, labelList[lbl].labelPointer[0]);
                    _ = frontier_char_string.xcopy(tmpString, labelList[lbl].labelPointer + 1, lblNameLen);
                    tmpString[lblNameLen] = 0;
                    if (frontier_sort.compareString(tmpString, labelName, CMP_BINARY) == 0) { // Label name match
                        if (!labelFound) { // First label occurence in the current program
                            firstLabel = lbl;
                            labelFound = true;
                        }
                        const labelLocalStepNumber: i32 = (-labelList[lbl].step) - programList[currentProgramNumber - 1].step + 1;
                        if (labelLocalStepNumber > @as(i32, currentLocalStepNumber)) {
                            nextLabel = lbl; // First label occurence after the current program step
                            break;
                        }
                    }
                }
            }
        }
        // return local label found, if any
        if (labelFound) { // If a local label found in the program
            lbl = if (nextLabel != 0) nextLabel else firstLabel; // First found label label after current program step or the first found label in the program
            return @intCast(@as(i32, lbl) + FIRST_LABEL);
        }
    }
    if ((labelType == ALL_LABELS) or (labelType == GLOBAL_LABELS)) { // then search global labels
        var lbl: u16 = 0;
        while (lbl < numberOfLabels) : (lbl += 1) {
            if (labelList[lbl].step > 0) {
                const lblNameLen = boundProgramNameLength(labelList[lbl].labelPointer + 1, labelList[lbl].labelPointer[0]);
                _ = frontier_char_string.xcopy(tmpString, labelList[lbl].labelPointer + 1, lblNameLen);
                tmpString[lblNameLen] = 0;
                if (frontier_sort.compareString(tmpString, labelName, CMP_BINARY) == 0) {
                    if (dupNum <= 0) {
                        return @intCast(@as(i32, lbl) + FIRST_LABEL);
                    } else {
                        dupNum -= 1;
                    }
                }
            }
        }
    }
    return INVALID_VARIABLE;
}

// ===========================================================================
// getNumberOfSteps (public)
// ===========================================================================
pub export fn getNumberOfSteps() callconv(.c) u16 {
    if (currentProgramNumber == numberOfPrograms) {
        var numberOfSteps: u16 = 1;
        var step: [*c]u8 = programList[currentProgramNumber - 1].instructionPointer;
        while (!(isAtEndOfProgram(step) or isAtEndOfPrograms(step))) { // END or .END.
            numberOfSteps += 1;
            step = frontier_next_step.findNextStep(step);
        }
        return numberOfSteps;
    } else {
        return @intCast(absI(programList[currentProgramNumber].step - programList[currentProgramNumber - 1].step));
    }
}

// ===========================================================================
// z47_frontier_program_current_program_in_ram — helper used by program_clear.zig.
// ===========================================================================
pub fn z47_frontier_program_current_program_in_ram() bool {
    return programList[currentProgramNumber - 1].step > 0;
}
