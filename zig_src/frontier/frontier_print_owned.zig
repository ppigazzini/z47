const std = @import("std");
// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/printing/print.c: the HP-82240 / Martel infrared
// printing engine (charMap / findPrinterGlyph / findMartelGlyph / printIR /
// printAdvance / printTab / printGraphic* / printGlyph* / printLine /
// printJustified* / printReg / printAlpha / print_lf / cmdPrint / setPrintMode /
// reverse / printLcd / printTrace* / printInputPrompt / printViewAview /
// nameAlias / printProgram), the always-on printer command entry points
// (fnP_PrinterOnOff / fnP_PrinterMode / fnSetPrinter / fnP_GetDelay /
// fnP_SetDelay / fnP_Advance / fnP_PrinterList / fnP_Byte / fnP_Char / fnP_Tab /
// fnP_User / fnP_LCD / fnP_Alpha / fnP_Regs / fnP_Sigma / fnP_All_Regs /
// fnP_PrintAllItems), the NamesAlias / hp82240CharMap / summationRegisterName
// data tables, and the z47_frontier_* C-helper shims that print.c's bridge
// (zig_bridge/frontier/print_legacy.c) provided. Faithful, line-by-line port.
//
// IR_PRINTING gating: print.c's infrared path is `#if defined(IR_PRINTING)`.
// IR_PRINTING is defined by default (defines.h:71) and stays defined for the
// host (PC_BUILD) and the NEW_HW dmcp5 firmware, but is `#undef`'d inside the
// old_hw DM42 package blocks (defines.h:194/214/234). So the IR path is LIVE on
// host + dmcp5 and DEAD only on old_hw firmware:
//     const ir_printing = !(dmcp_build and old_hw);
// On the dead branch print.c's `#else` stubs (in the bridge tail) are
// reproduced. The DMCP-ROM functions (printer_advance_buf / printer_busy_for /
// sys_timer_* / sys_sleep / lcd_line_addr / start_buzzer_freq / stop_buzzer /
// beep_volume_up / get_beep_volume / sys_delay) are fixed-address jump-table
// calls (LIBRARY_FN_BASE + verified offset from lft_ifc.h), only referenced
// under `if (comptime dmcp_build)`. sendByteIR / getLineDelay / setLineDelay are
// provided by the firmware/host runtime layer and are externed here.
//
// VERBOSE_LEVEL is -1 for every z47 build, so the VERBOSE_LEVEL>=1
// print_linestr diagnostic blocks are dead and omitted; INCLUDE_FONT_ESCAPE is
// not defined, so that pixel_length escape block is dead and omitted; the
// PC_BUILD printf trace diagnostics are host-only via `if (comptime !dmcp_build)`.
//
// print.c is reached from the testSuite only indirectly; verification is by
// build/link across every target plus the boundary gates.

const frontier_build_options = @import("frontier_build_options");
const dmcp_build: bool = frontier_build_options.dmcp_build;
const old_hw: bool = frontier_build_options.old_hw;
const extra_info: bool = frontier_build_options.extra_info_on_calc_error;

// IR printing is live everywhere except old_hw firmware.
const ir_printing: bool = !(dmcp_build and old_hw);

const LIBRARY_FN_BASE: usize = if (old_hw) 0x08000201 else 0x08000301;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const bool_t = bool;
const calcRegister_t = i16;
const print_modes_t = c_int;
const print_area_t = c_int;
const printArgument_t = c_int;
const real34_t = abi.Real34;
const complex34_t = extern struct { bytes: [32]u8 };
const abi = @import("abi"); // L1 shared bindings (REPORT-23 §5)
const real_t = abi.Real;
const realContext_t = abi.RealContext;
const mp_limb_t = usize;
const mpz_struct = extern struct {
    _mp_alloc: c_int,
    _mp_size: c_int,
    _mp_d: [*c]mp_limb_t,
};
const longInteger_t = [1]mpz_struct;
const font_t = opaque {};

// glyph / font structs (typeDefinitions.h)
const glyphPrinter_t = extern struct {
    charCode: u16,
    data: [5]u8,
};
const printerFont_t = extern struct {
    numberOfGlyphs: u16,
    // glyphPrinter_t glyphs[]; flexible array member - accessed via pointer math
};
const glyphMartelPrinter_t = extern struct {
    charCode: u16,
    data: [48]u8,
};
const martelFont24_t = extern struct {
    numberOfGlyphs: u16,
    // glyphMartelPrinter_t glyphs[];
};
const glyph_t = extern struct {
    charCode: u16,
    colsBeforeGlyph: u8,
    colsGlyph: u8,
    colsAfterGlyph: u8,
    rowsAboveGlyph: u8,
    rowsGlyph: u8,
    rowsBelowGlyph: u8,
    rank1: i16,
    rank2: i16,
    data: [*c]u8,
};
const nameAlias_t = extern struct {
    item: u16,
    name: [16]u8,
};
const summationRegisterName_t = extern struct {
    name: [16]u8,
};
const printerState_t = extern struct {
    print_on: bool_t,
    trace_done: bool_t,
    print_blank_line: u8,
    print_mode: print_modes_t,
    printer_model: print_modes_t,
    delay: u16,
};

// matrix structs (typeDefinitions.h). matrixHeader_t is a 4-byte bitfield
// (rows:12, cols:12, mtag:6, notUsed:2); only rows/cols are read.
const matrixHeader_t = packed struct(u32) {
    matrixRows: u12,
    matrixColumns: u12,
    mtag: u6,
    notUsed: u2,
};
const real34Matrix_t = extern struct {
    header: matrixHeader_t,
    matrixElements: [*]real34_t,
};
const complex34Matrix_t = extern struct {
    header: matrixHeader_t,
    matrixElements: [*]complex34_t,
};

// item_t (typeDefinitions.h)
const ItemFn = ?*const fn (u16) callconv(.c) void;
const item_t = extern struct {
    func: ItemFn,
    param: u16,
    itemCatalogName: [16]u8,
    itemSoftmenuName: [16]u8,
    tamMinMax: u16,
    status: u16,
};

// registerHeader_t is 4 bytes; namedVariableHeader_t / reservedVariableHeader_t.
const namedVariableHeader_t = extern struct {
    header: u32,
    variableName: [16]u8,
};
const reservedVariableHeader_t = extern struct {
    header: u32,
    reservedVariableName: [8]u8,
};

// labelList_t (typeDefinitions.h)
const labelList_t = extern struct {
    program: i16,
    step: i32,
    labelPointer: [*c]u8,
    instructionPointer: [*c]u8,
};

// userMenuItem_t / userMenu_t (typeDefinitions.h)
const userMenuItem_t = extern struct {
    item: i16,
    unused: i16,
    argumentName: [16]u8,
};
const userMenu_t = extern struct {
    menuName: [16]u8,
    menuItem: [18]userMenuItem_t,
};
// programmableMenu_t
const programmableMenu_t = extern struct {
    itemName: [18][16]u8,
    itemParam: [21]u16,
    unused: u16,
};
// subroutineLevelHeader_t (only numberOfLocalRegisters read)
const subroutineLevelHeader_t = extern struct {
    returnProgramNumber: i16,
    returnLocalStep: u16,
    numberOfLocalFlags: u8,
    numberOfLocalRegisters: u8,
    subroutineLevel: u16,
    ptrToNextLevel: u16,
    ptrToPreviousLevel: u16,
};

// ---------------------------------------------------------------------------
// Constants (verified via C probe against the sim build)
// ---------------------------------------------------------------------------
const PAPER_WIDTH: c_int = 166;
const SCREEN_WIDTH: i32 = 400;
const SCREEN_HEIGHT: i32 = 240;
const ERROR_MESSAGE_LENGTH: usize = 512;
const AIM_BUFFER_LENGTH: usize = 1024;
const NIM_BUFFER_LENGTH: usize = 200;
const NUMBER_OF_STATISTICAL_SUMS: usize = 28;
const NUMBER_OF_DISPLAY_DIGITS: i32 = 20;
const REAL34_SIZE_IN_BYTES: usize = 16;
const STR_LGINT_HEADER_SIZE: usize = 4;
const MATRIX_HEADER_SIZE: usize = 4;
const DISPLAY_WAIT_FOR_RELEASE: c_int = 1;

const FLAG_PRTACT: c_int = 0xc020;
const FLAG_PRTEN: c_uint = 0x8067;
const FLAG_NORM: c_uint = 0x8068;
const FLAG_TRACE: c_int = 0x8013;
const FLAG_SSIZE8: c_int = 0x8018;
const FLAG_2TO10: c_int = 0x803D;

const TO_CL_DROP: u8 = 6;
const JM_CLRDROP_TIMER: u32 = if (old_hw) 500 else 500; // ms; same for non-DM42 host path
const TMR_RUNNING: u8 = 2;

const KEY_EXIT: c_int = 32; // host EXIT key code (currentKeyCode == 32)

const REGISTER_X: calcRegister_t = 100;
const REGISTER_Y: calcRegister_t = 101;
const REGISTER_T: calcRegister_t = 103;
const REGISTER_D: calcRegister_t = 107;
const REGISTER_W: calcRegister_t = 125;
const REGISTER_K: calcRegister_t = 111;
const REGISTER_M: calcRegister_t = 112;
const ITM_REG_X: i32 = 527;
const ITM_REG_M: i32 = 2336;
const TEMP_REGISTER_1: calcRegister_t = 135;
const ERR_REGISTER_LINE: calcRegister_t = 102;
const NIM_REGISTER_LINE: calcRegister_t = 100;

const FIRST_LOCAL_REGISTER: u16 = 7000;
const LAST_LOCAL_REGISTER: u16 = 7098;
const FIRST_NAMED_VARIABLE: u16 = 256;
const LAST_NAMED_VARIABLE: u16 = 1999;
const FIRST_NAMED_RESERVED_VARIABLE: u16 = 2026;
const FIRST_RESERVED_VARIABLE: u16 = 2000;
const LAST_RESERVED_VARIABLE: u16 = 2047;

const FIRST_LABEL: i32 = 2200;
const LAST_LABEL: i32 = 6999;
const LAST_LOCAL_LABEL: i32 = 123;
const LAST_UC_LOCAL_LABEL: i32 = 111;
const FIRST_LC_LOCAL_LABEL: i32 = 112;

const FLAG_X: i32 = 100;
const FLAG_K: i32 = 111;
const FLAG_M: i32 = 211;
const FLAG_W: i32 = 224;
const FIRST_LOCAL_FLAG: i32 = 112;
const LAST_LOCAL_FLAG: i32 = 143;
const SFL_TDM24: i32 = 463;
const SFL_MONIT: i32 = 2251;

const ITM_LBL: i32 = 1;
const ITM_PRINTERALPHA: i16 = 2682;
const ITM_XEQ: i32 = 3;
const ITM_OPEN_MENU: i32 = 2405;
const ITM_MENU: i32 = 1520;
const ITM_PROMPT: u16 = 2020;
const ITM_INPUT: u16 = 43;
const ITM_VIEW: u16 = 101;
const ITM_PRINTERADV: i32 = 1708;
const ITM_PRINTERX: i32 = 1676;
const ITM_BACKSPACE: i32 = 1738;
const ITM_EXIT1: i32 = 1737; // items.h:1786
const MNU_DYNAMIC: i32 = 1394;

const TM_VALUE: u16 = 10001;
const TM_SHUFFLE: u16 = 10008;
const TM_LABEL: u16 = 10009;
const TM_LBLONLY: u16 = 10018;
const TM_FLAGR: u16 = 10004;
const TM_FLAGW: u16 = 10005;
const TM_CMP: u16 = 10022; // defines.h: 10022 (matches comparison items' .param=10022); was 10021 (=TM_STRING) -> interactive comparisons broke

const TAM_MAX_MASK: u16 = 0x3fff;
const PTP_STATUS: u16 = 0x1e00;
const PTP_NONE: u16 = 0;

const TI_FALSE: u8 = 12;
const TI_TRUE: u8 = 13;
const TI_PRINT_COMPLETE: u8 = 136;
const TI_SHOW_REGISTER: u8 = 14;
const TI_SHOW_REGISTER_BIG: u8 = 75;
const TI_SHOW_REGISTER_SMALL: u8 = 76;
const TI_SHOW_REGISTER_TINY: u8 = 77;
const TI_SHOWNOTHING: u8 = 93;

const CM_NORMAL: u8 = 0;
const CM_AIM: u8 = 1;
const CM_MIM: u8 = 12;
const CM_NO_UNDO: u8 = 16;
const DF_ALL: u8 = 0;

const PGM_RUNNING: u8 = 1;
const PGM_SINGLE_STEP: u8 = 6;
const PGM_WAITING: u8 = 2;

const PROFF: u16 = 0;
const PRON: u16 = 1;
const MAN: u16 = 0;
const NORM: u16 = 1;
const TRACE: u16 = 2;
const STRACE: u16 = 3;

const PRINT_BYTE: c_int = 0;
const PRINT_CHAR: c_int = 1;
const PRINT_TAB: c_int = 2;
const PRINT_ALPHA: c_int = 3;
const PRINT_ALPHA_JUST: c_int = 5;

const LINE_FULL: print_area_t = 0;
const LINE_LEFT: print_area_t = 1;
const LINE_RIGHT: print_area_t = 2;
const LINE_NOLF: print_area_t = 3;
const LINE_ASIS: print_area_t = 4;

const PMODE_DEFAULT: print_modes_t = 0;
const PMODE_GRAPHICS: print_modes_t = 1;
const PMODE_SMALLGRAPHICS: print_modes_t = 2;

const PRINTER_HP: print_modes_t = 0;
const PRINTER_MARTEL: print_modes_t = 1;

const PRN_ALL: u16 = 0;
const PRN_STK: u16 = 1;
const PRN_REGS: u16 = 2;
const PRN_GLOBALr: u16 = 3;
const PRN_LOCALr: u16 = 4;
const PRN_NAMEDr: u16 = 5;
const PRN_Xr: u16 = 6;
const PRN_XYr: u16 = 7;
const PRN_TMP: u16 = 8;

const dtLongInteger: u32 = 0;
const dtReal34: u32 = 1;
const dtComplex34: u32 = 2;
const dtTime: u32 = 3;
const dtDate: u32 = 4;
const dtString: u32 = 5;
const dtReal34Matrix: u32 = 6;
const dtComplex34Matrix: u32 = 7;
const dtShortInteger: u32 = 8;

const amNone: u32 = 5;
const amRadian: u32 = 0;
const amAngleMask: u32 = 15;
const amPolar: u32 = 16;

const ERROR_OUT_OF_RANGE: u8 = 8;
const ERROR_INVALID_DATA_TYPE_FOR_OP: u8 = 24;
const ERROR_MATRIX_MISMATCH: u8 = 21;
const ERROR_NO_SUMMATION_DATA: u8 = 28;
const ERROR_PRINTING_DISABLED: u8 = 63;

const NOPARAM: u16 = 9876;
const ONELINE: bool_t = true;
const PROG: bool_t = false;
const LIST: bool_t = true;
const CMP_NAME: i32 = 3;

const DEC_ROUND_DOWN: c_int = 5;
const PRINT_GRA_LN: c_int = 1;

// STD_* byte sequences (fonts.h, verified via C probe).
const STD_MEASURED_ANGLE = "\xa2\x21";
const PRODUCT_SIGN = "\x80\xb7";
const STD_CROSS = "\x80\xd7";
const STD_DEGREE = "\x80\xb0";
const STD_SUP_MINUS = "\xa1\x6b";
const STD_SUP_0 = "\xa1\x60";
const STD_SUP_9 = "\xa1\x69";
const STD_SUP_pir = "\xac\x66";
const STD_SUP_pi = "\xac\x65";
const STD_BLACK_RIGHT_TRIANGLE = "\xa5\xb6";
const STD_LEFT_SINGLE_QUOTE = "\xa0\x18";
const STD_RIGHT_SINGLE_QUOTE = "\xa0\x19";
const STD_RIGHT_ARROW = "\xa1\x92";

// ---------------------------------------------------------------------------
// Globals (extern var) and print.c file globals
// ---------------------------------------------------------------------------
extern var printerState: printerState_t;
extern var lastFunc: i16;
extern var printerColumn: u16;
extern var printerIconEnabled: bool_t;
extern var tmpString: [*c]u8;
extern var errorMessage: [*c]u8;
extern var aimBuffer: [*c]u8;
extern var currentKeyCode: u8;
extern var calcMode: u8;
extern var programRunStop: u8;
extern var lastErrorCode: u8;
extern var temporaryInformation: u8;
extern var currentAngularMode: c_int;
extern var temporaryFlagPolar: bool_t;
extern var shortIntegerMask: u64;
extern var numberOfNamedVariables: u16;
extern var numberOfPrograms: u16;
extern var grpGroupingLeft: u8;
extern var grpGroupingRight: u8;
extern var displayFormat: u8;
extern var displayFormatDigits: u8;
extern var currentUserMenu: u16;
extern var dynamicMenuItem: i16;
extern var programListEnd: bool_t;
extern var lastProgramListEnd: bool_t;
extern var firstDisplayedLocalStepNumber: u16;
extern var currentLocalStepNumber: u16;
extern var firstDisplayedStep: [*c]u8;

extern var statisticalSumsPointer: [*c]real_t;
extern var beginOfProgramMemory: [*c]u8;
extern var currentStep: [*c]u8;
extern var allNamedVariables: [*c]namedVariableHeader_t;
extern var labelList: [*c]labelList_t;
extern var userMenus: [*c]userMenu_t;
extern var programmableMenu: programmableMenu_t;
extern var currentSubroutineLevelData: [*c]subroutineLevelHeader_t;
extern var tam: tamState_t;

extern var ctxtReal34: realContext_t;
extern var ctxtReal39: realContext_t;

// const34_0 is a pointer into the `constants` blob (constantPointers.h).
const constants = @extern([*]const u8, .{ .name = "constants" });
const OFF_const34_0: usize = 16200; // constantPointers.h:352
inline fn const34_0() *align(1) const real34_t {
    return @ptrCast(constants + OFF_const34_0);
}

extern const standardFont: font_t;

// C ARRAY symbols: bind by address with @extern (not pointer-typed extern).
const indexOfItems = @extern([*c]const item_t, .{ .name = "indexOfItems" });
const allReservedVariables = @extern([*c]const reservedVariableHeader_t, .{ .name = "allReservedVariables" });
const baseDigits = @extern([*c]const u8, .{ .name = "baseDigits" });
const shuffleReg = @extern([*c]const u8, .{ .name = "shuffleReg" });
const registerFlagLetters = @extern([*c]const u8, .{ .name = "registerFlagLetters" });
const printerFont8 = @extern(*const printerFont_t, .{ .name = "printerFont8" });
const martelFont24 = @extern(*const martelFont24_t, .{ .name = "martelFont24" });
const glyphNotFound = @extern(*glyph_t, .{ .name = "glyphNotFound" });

// tamState_t: only mode/indirect/value/value0 are read; full layout for ABI.
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

// ---------------------------------------------------------------------------
// Function externs (linkable everywhere)
// ---------------------------------------------------------------------------
extern fn boundProgramNameLength(nameStart: [*c]const u8, claimedLength: u8) u8;
extern fn getSystemFlag(sf: c_int) bool_t;
extern fn setSystemFlag(sf: c_uint) void;
extern fn clearSystemFlag(sf: c_uint) void;
extern fn setSystemFlagChanged(sf: i32) void;
extern fn fnSetFlag(flag: u16) void;
extern fn fnClearFlag(flag: u16) void;
extern fn refreshStatusBar() void;
extern fn refreshScreen(source: u16) void;
extern fn resetShiftState() void;
extern fn clearKeyBuffer() void;
extern fn C47PopKeyNoBuffer(displayWaitForRelease: bool_t) c_int;
extern fn fnTimerGetStatus(nr: u8) u8;
extern fn fnTimerStart(nr: u8, param: u16, time: u32) void;

extern fn sendByteIR(byte: u8) void;
extern fn getLineDelay() u32;
extern fn setLineDelay(delay: u16) void;

extern fn findGlyph(font: *const font_t, charCode: u16) i16;
extern fn generateNotFoundGlyph(font: i16, charCode: u16) void;
extern fn stringGlyphLength(str: [*c]const u8) i32;
extern fn stringNextGlyph(str: [*c]const u8, pos: i16) i16;
extern fn addChrBothSides(t: u8, str: [*c]u8) void;
extern fn copyRegisterToClipboardString(regist: calcRegister_t, clipboardString: [*c]u8, forPrinter: bool_t) void;

extern fn getRegisterDataType(regist: calcRegister_t) u32;
extern fn getRegisterDataPointer(regist: calcRegister_t) ?*anyopaque;
extern fn getRegisterTag(regist: calcRegister_t) u32;
extern fn getRegisterDataTypeName(regist: calcRegister_t, article: bool_t, padWithBlanks: bool_t) [*c]const u8;
extern fn letteredRegisterName(regist: calcRegister_t) u8;
extern fn convertReal34MatrixRegisterToReal34Matrix(regist: calcRegister_t, matrix: *real34Matrix_t) void;
extern fn convertComplex34MatrixRegisterToComplex34Matrix(regist: calcRegister_t, matrix: *complex34Matrix_t) void;
extern fn linkToComplexMatrixRegister(regist: calcRegister_t, linkedMatrix: *complex34Matrix_t) void;
extern fn convertRealToResultRegister(x: *const real_t, dest: calcRegister_t, angle: u32) void;
extern fn reallocateRegister(regist: calcRegister_t, dataType: u32, dataSizeWithoutDataLenBlocks: u16, tag: u32) void;
extern fn getRegParam(f: ?*bool_t, s: *u16, n: *u16, d: ?*u16) u8;
extern fn findNamedVariable(variableName: [*c]const u8) calcRegister_t;
extern fn compareString(stra: [*c]const u8, strb: [*c]const u8, comparisonType: i32) i32;
extern fn getIRegisterAsInt(asArrayPointer: bool_t) i16;
extern fn getJRegisterAsInt(asArrayPointer: bool_t) i16;

extern fn displayCalcErrorMessage(errorCode: u8, errMessageRegisterLine: calcRegister_t, errRegisterLine: calcRegister_t) void;
extern fn moreInfoOnError(m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) void;
extern fn fnStopProgram(unusedButMandatoryParameter: u16) void;
extern fn fnSNAP(unusedButMandatoryParameter: u16) void;
extern fn leaveTamModeIfEnabled() void;

extern fn create_filename(fileSuffix: [*c]const u8) void;
extern fn stackregister_csv_out(reg_b: i16, reg_e: i16, oneLine: bool_t) void;
extern fn tmpString_csv_out(nn: u8) void;

extern fn getTimeString(timeString: [*c]u8) void;
extern fn getDateString(dateString: [*c]u8) void;
extern fn defineFirstDisplayedStep() void;
extern fn findNextStep(step: [*c]u8) [*c]u8;
extern fn isAtEndOfPrograms(step: [*c]const u8) bool_t;
extern fn checkOpCodeOfStep(step: [*c]const u8, op: u16) bool_t;
// isAtEndOfProgram is a static inline in manage.h: checkOpCodeOfStep(step, ITM_END).
const ITM_END: u16 = 1458;
inline fn isAtEndOfProgram(step: [*c]const u8) bool_t {
    return checkOpCodeOfStep(step, ITM_END);
}
extern fn decodeOneStep_ALIAS(step: [*c]u8) void;
extern fn _getProgramSize() u32;

// renamed-away in the bridge; owned by other owners. Extern, NOT re-exported.
extern fn fnP_Regs(registerNo: u16) void;
extern fn fnP_PrintAllItems(unusedButMandatoryParameter: u16) void;

// real34 / decimal helpers. int32ToReal34 / real34ToString / real34IsZero are
// decQuad* macros in C; bind the underlying decQuad symbols and wrap.
extern fn real34CompareLessThan(number1: *align(1) const real34_t, number2: *align(1) const real34_t) bool_t;
extern fn real34CompareLessEqual(number1: *align(1) const real34_t, number2: *align(1) const real34_t) bool_t;
extern fn decQuadFromInt32(dq: *real34_t, v: i32) *real34_t;
extern fn decQuadToString(dq: *const real34_t, str: [*c]u8) [*c]u8;
extern fn decQuadIsZero(dq: *const real34_t) u32;
inline fn int32ToReal34(source: i32, destination: *real34_t) void {
    _ = decQuadFromInt32(destination, source);
}
inline fn real34ToString(source: *const real34_t, destination: [*c]u8) [*c]u8 {
    return decQuadToString(source, destination);
}
inline fn real34IsZero(source: *const real34_t) u32 {
    return decQuadIsZero(source);
}
extern fn real34ToDisplayString(real34: *const real34_t, tag: u32, displayString: [*c]u8, font: *const font_t, maxWidth: i16, displayHasNDigits: i16, limitExponent: bool_t, frontSpace: bool_t, limitIrfrac: c_int) void;
extern fn realRectangularToPolar(real: *const real_t, imag: *const real_t, magnitude: *real_t, theta: *real_t, realContext: *realContext_t) void;
extern fn convertAngleFromTo(angle: *real_t, fromAngularMode: u32, toAngularMode: u32, realContext: *realContext_t) void;

// decQuad / decimal128 (behind real34 macros)
extern fn decimal128ToNumber(src: *const real34_t, dst: *real_t) *real_t;
extern fn decimal128FromNumber(dst: *real34_t, src: *const real_t, ctx: *realContext_t) *real34_t;
extern fn decQuadReduce(r: *real34_t, op: *const real34_t, ctx: *realContext_t) *real34_t;
extern fn decQuadToInt32(src: *const real34_t, ctx: *realContext_t, mode: c_int) i32;

// GMP (for _getUnicodeValue)
extern fn @"__gmpz_init"(p: *mpz_struct) void;
extern fn @"__gmpz_clear"(p: *mpz_struct) void;
extern fn @"__gmpz_get_ui"(p: *const mpz_struct) c_ulong;
extern fn @"__gmpz_cmp_ui"(p: *const mpz_struct, v: c_ulong) c_int;
extern fn @"__gmpz_set_si"(p: *mpz_struct, v: c_long) void;
extern fn convertLongIntegerRegisterToLongInteger(regist: calcRegister_t, longInteger: *mpz_struct) void;
extern fn convertShortIntegerRegisterToLongInteger(source: calcRegister_t, lgInt: *mpz_struct) void;

// complex34Copy(source, dest): macro = real34Copy two halves. dest is a complex34
// register data pointer (real34_t* in our reg34 typing); copy 32 bytes.
inline fn complex34Copy(source: *const complex34_t, destination: *real34_t) void {
    const d: *complex34_t = @ptrCast(destination);
    d.* = source.*;
}

// libc
extern fn strlen(s: [*c]const u8) usize;
extern fn strcpy(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strcat(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn memmove(dst: ?*anyopaque, src: ?*const anyopaque, n: usize) ?*anyopaque;
extern fn memset(dst: ?*anyopaque, c: c_int, n: usize) ?*anyopaque;
extern fn xcopy(dest: ?*anyopaque, source: ?*const anyopaque, n: u32) ?*anyopaque;
extern fn sprintf(buf: [*c]u8, fmt: [*:0]const u8, ...) c_int;
extern fn snprintf(buf: [*c]u8, size: usize, fmt: [*:0]const u8, ...) c_int;
extern fn printf(fmt: [*:0]const u8, ...) c_int;
extern fn fflush(f: ?*anyopaque) c_int;

// ---------------------------------------------------------------------------
// real34 macro reproductions
// ---------------------------------------------------------------------------
inline fn reg34(reg: calcRegister_t) *real34_t {
    return @ptrCast(@alignCast(getRegisterDataPointer(reg)));
}
inline fn regBytes(reg: calcRegister_t) [*c]u8 {
    return @ptrCast(getRegisterDataPointer(reg));
}
inline fn regImag34(reg: calcRegister_t) *real34_t {
    return @ptrCast(@alignCast(regBytes(reg) + REAL34_SIZE_IN_BYTES));
}
inline fn regString(reg: calcRegister_t) [*c]u8 {
    return regBytes(reg) + STR_LGINT_HEADER_SIZE;
}
inline fn regShortInt(reg: calcRegister_t) *u64 {
    return @ptrCast(@alignCast(getRegisterDataPointer(reg)));
}
inline fn regMatrixHeader(reg: calcRegister_t) *matrixHeader_t {
    return @ptrCast(@alignCast(getRegisterDataPointer(reg)));
}
inline fn regReal34MatrixElems(reg: calcRegister_t) [*c]real34_t {
    return @ptrCast(@alignCast(regBytes(reg) + MATRIX_HEADER_SIZE));
}
inline fn varReal34(p: [*c]const complex34_t) *const real34_t {
    return @ptrCast(p);
}
inline fn varImag34(p: [*c]const complex34_t) *const real34_t {
    const b: [*c]const u8 = @ptrCast(p);
    return @ptrCast(@alignCast(b + REAL34_SIZE_IN_BYTES));
}
inline fn real34Copy(source: *const real34_t, destination: *real34_t) void {
    destination.* = source.*;
}
inline fn real34ToReal(source: *const real34_t, destination: *real_t) void {
    _ = decimal128ToNumber(source, destination);
}
inline fn realToReal34(source: *const real_t, destination: *real34_t) void {
    _ = decimal128FromNumber(destination, source, &ctxtReal34);
}
inline fn real34Reduce(operand: *const real34_t, res: *real34_t) void {
    _ = decQuadReduce(res, operand, &ctxtReal34);
}
inline fn real34ToInt32(source: *const real34_t) i32 {
    return decQuadToInt32(source, &ctxtReal34, DEC_ROUND_DOWN);
}
inline fn getComplexRegisterAngularMode(reg: calcRegister_t) u16 {
    return @intCast(getRegisterTag(reg) & amAngleMask);
}
inline fn getComplexRegisterPolarMode(reg: calcRegister_t) u16 {
    return @intCast(getRegisterTag(reg) & amPolar);
}
inline fn getRegisterAngularMode(reg: calcRegister_t) u32 {
    return getRegisterTag(reg) & amAngleMask;
}
inline fn getRegisterShortIntegerBase(reg: calcRegister_t) u32 {
    return getRegisterTag(reg);
}
inline fn longIntegerInit(op: *mpz_struct) void {
    @"__gmpz_init"(op);
}
inline fn longIntegerFree(op: *mpz_struct) void {
    @"__gmpz_clear"(op);
}
inline fn longIntegerToUInt32(op: *const mpz_struct) u32 {
    return @truncate(@"__gmpz_get_ui"(op));
}
inline fn longIntegerCompareUInt(op: *const mpz_struct, v: u32) i32 {
    return @"__gmpz_cmp_ui"(op, v);
}
inline fn stringByteLength(s: [*c]const u8) i32 {
    return @intCast(strlen(s));
}
inline fn currentNumberOfLocalRegisters() u8 {
    return currentSubroutineLevelData[0].numberOfLocalRegisters;
}
inline fn cMax(comptime T: type, a: T, b: T) T {
    return if (a > b) a else b;
}
inline fn moreInfoOnErr(where: [*:0]const u8, hint1: ?[*:0]const u8, hint2: ?[*:0]const u8, hint3: ?[*:0]const u8) void {
    if (comptime !dmcp_build) {
        moreInfoOnError(where, hint1, hint2, hint3);
    }
}

// NUMBER_OF_DISPLAY_REAL_CONTEXT_DIGITS and SHOWMODE macros.
inline fn numberOfDisplayRealContextDigits() i32 {
    if (displayFormat == DF_ALL or getSystemFlag(FLAG_2TO10)) {
        return NUMBER_OF_DISPLAY_DIGITS + 1;
    }
    return @as(i32, displayFormatDigits) + 2;
}
inline fn showMode() bool {
    return calcMode == CM_NORMAL and (temporaryInformation == TI_SHOW_REGISTER or
        temporaryInformation == TI_SHOW_REGISTER_BIG or
        temporaryInformation == TI_SHOW_REGISTER_SMALL or
        temporaryInformation == TI_SHOW_REGISTER_TINY or
        temporaryInformation == TI_SHOWNOTHING);
}

// ---------------------------------------------------------------------------
// DMCP-ROM trampolines (fixed-address on firmware; only used under dmcp_build).
// ---------------------------------------------------------------------------
inline fn lcd_line_addr(y: c_int) [*c]u8 {
    const f: *const fn (c_int) callconv(.c) [*c]u8 = @ptrFromInt(LIBRARY_FN_BASE + 40);
    return f(y);
}
inline fn printer_advance_buf(what: c_int) void {
    const f: *const fn (c_int) callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 312);
    f(what);
}
inline fn printer_busy_for(what: c_int) c_int {
    const f: *const fn (c_int) callconv(.c) c_int = @ptrFromInt(LIBRARY_FN_BASE + 316);
    return f(what);
}
inline fn sys_timer_start(timer_ix: c_int, ms_value: u32) void {
    const f: *const fn (c_int, u32) callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 504);
    f(timer_ix, ms_value);
}
inline fn sys_timer_disable(timer_ix: c_int) void {
    const f: *const fn (c_int) callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 500);
    f(timer_ix);
}
inline fn sys_sleep() void {
    const f: *const fn () callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 536);
    f();
}
inline fn start_buzzer_freq(freq: u32) void {
    const f: *const fn (u32) callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 244);
    f(freq);
}
inline fn stop_buzzer() void {
    const f: *const fn () callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 248);
    f();
}
inline fn beep_volume_up() void {
    const f: *const fn () callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 252);
    f();
}
inline fn get_beep_volume() c_int {
    const f: *const fn () callconv(.c) c_int = @ptrFromInt(LIBRARY_FN_BASE + 260);
    return f();
}
inline fn sys_delay(ms_delay: u32) void {
    const f: *const fn (u32) callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 516);
    f(ms_delay);
}
// beep(freq, len) macro (DMCP-only).
inline fn beep(frequence: u32, length: u32) void {
    while (get_beep_volume() < 11) {
        beep_volume_up();
    }
    start_buzzer_freq(frequence * 1000);
    sys_delay(length);
    stop_buzzer();
}

// key handling on DMCP uses the key_pop / key_pop_all ROM macros.
inline fn key_pop() c_int {
    if (comptime dmcp_build) {
        const f: *const fn () callconv(.c) c_int = @ptrFromInt(LIBRARY_FN_BASE + 392);
        return f();
    }
    return 0;
}
inline fn key_pop_all() void {
    if (comptime dmcp_build) {
        // key_pop_all loops key_pop until empty.
        while (key_pop() != -1) {}
    }
}

// ===========================================================================
// IR_PRINTING-gated body. Everything from charMap() to _getUnicodeValue() is
// only present when ir_printing is true; otherwise the bridge `#else` stubs
// (reproduced near the bottom) provide the public symbols.
// ===========================================================================

// Alias table for instruction names (TO_QSPI const).
const ITM_XexY: u16 = 36;
const ITM_SQUARE: u16 = 58;
const ITM_CUBE: u16 = 59;
const ITM_YX: u16 = 60;
const ITM_SQUAREROOTX: u16 = 61;
const ITM_CUBEROOT: u16 = 62;
const ITM_XTHROOT: u16 = 63;
const ITM_2X: u16 = 64;
const ITM_EXP: u16 = 65;
const ITM_10x: u16 = 67;
const ITM_Xex: u16 = 127;
const ITM_ex: u16 = 981;
const ITM_M_RR: u16 = 1539;
const ITM_REexIM: u16 = 1570;
const ITM_EX1: u16 = 1575;
const ITM_Tex: u16 = 1625;
const ITM_Yex: u16 = 1650;
const ITM_Zex: u16 = 1651;
const ITM_M1X: u16 = 1679;
const ITM_SHUFFLE: u16 = 1694;
const ITM_RS: u16 = 1725;
const ITM_SQRT1PX2: u16 = 1794;
const ITM_EE_EXP_TH: u16 = 1816;
const LAST_ITEM: u16 = 2860;

const STD_SQUARE_ROOT = "\x80\x83";
const STD_SUP_3 = "\xa1\x63";
const STD_SUP_x = "\xa1\x78";
const STD_SUP_2 = "\xa1\x62";

fn alias(comptime item: u16, comptime name: []const u8) nameAlias_t {
    var row = nameAlias_t{ .item = item, .name = std.mem.zeroes([16]u8) };
    @memcpy(row.name[0..name.len], name);
    return row;
}

const NamesAlias = [_]nameAlias_t{
    alias(ITM_XexY, "x<>y"),
    alias(ITM_SQUARE, "x^2"),
    alias(ITM_CUBE, "x^3"),
    alias(ITM_YX, "y^x"),
    alias(ITM_SQUAREROOTX, STD_SQUARE_ROOT ++ "x"),
    alias(ITM_CUBEROOT, STD_SUP_3 ++ STD_SQUARE_ROOT ++ "x"),
    alias(ITM_XTHROOT, STD_SUP_x ++ STD_SQUARE_ROOT ++ "y"),
    alias(ITM_2X, "2^x"),
    alias(ITM_EXP, "e^x"),
    alias(ITM_10x, "10^x"),
    alias(ITM_Xex, "x<>"),
    alias(ITM_ex, "<>"),
    alias(ITM_M_RR, "M.R<>R"),
    alias(ITM_REexIM, "Re<>Im"),
    alias(ITM_EX1, "e^x-1"),
    alias(ITM_Tex, "t<>"),
    alias(ITM_Yex, "y<>"),
    alias(ITM_Zex, "z<>"),
    alias(ITM_M1X, "(-1)^x"),
    alias(ITM_SHUFFLE, "<>"),
    alias(ITM_RS, "RUN"),
    alias(ITM_SQRT1PX2, STD_SQUARE_ROOT ++ "(1+x^2)"),
    alias(ITM_EE_EXP_TH, "e^ix"),
    alias(LAST_ITEM, ""),
};

// HP-82240 Roman-8 to Unicode table (TO_QSPI const uint16_t[256]).
const hp82240CharMap = [256]u16{
    0x0000, 0x0000, 0x0000, 0x0000, 0x2404, 0x0000, 0x0000, 0x0000,
    0x0000, 0x0000, 0x240A, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
    0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
    0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
    0x0020, 0x0021, 0x0022, 0x0023, 0x0024, 0x0025, 0x0026, 0x0027,
    0x0028, 0x0029, 0x002A, 0x002B, 0x002C, 0x002D, 0x002E, 0x002F,
    0x0030, 0x0031, 0x0032, 0x0033, 0x0034, 0x0035, 0x0036, 0x0037,
    0x0038, 0x0039, 0x003A, 0x003B, 0x003C, 0x003D, 0x003E, 0x003F,
    0x0040, 0x0041, 0x0042, 0x0043, 0x0044, 0x0045, 0x0046, 0x0047,
    0x0048, 0x0049, 0x004A, 0x004B, 0x004C, 0x004D, 0x004E, 0x004F,
    0x0050, 0x0051, 0x0052, 0x0053, 0x0054, 0x0055, 0x0056, 0x0057,
    0x0058, 0x0059, 0x005A, 0x005B, 0x005C, 0x005D, 0x005E, 0x005F,
    0x2019, 0x0061, 0x0062, 0x0063, 0x0064, 0x0065, 0x0066, 0x0067,
    0x0068, 0x0069, 0x006A, 0x006B, 0x006C, 0x006D, 0x006E, 0x006F,
    0x0070, 0x0071, 0x0072, 0x0073, 0x0074, 0x0075, 0x0076, 0x0077,
    0x0078, 0x0079, 0x007A, 0x007B, 0x007C, 0x007D, 0x007E, 0x0000,
    0x00A0, 0x00F7, 0x00D7, 0x221A, 0x222B, 0x2211, 0x25B6, 0x03C0,
    0x2202, 0x2264, 0x2265, 0x2260, 0x03B1, 0x2192, 0x2190, 0x03BC,
    0x240A, 0x00B0, 0x00AB, 0x00BB, 0x22A2, 0x2081, 0x2082, 0x2162,
    0x2163, 0x24A4, 0x24A5, 0x0000, 0x248A, 0x248B, 0x248C, 0x248F,
    0x2221, 0x00C0, 0x00C2, 0x00C8, 0x00CA, 0x00CB, 0x00CE, 0x00CF,
    0x00B4, 0x0060, 0x005E, 0x00A8, 0x02DC, 0x00D9, 0x00FB, 0x20A4,
    0x00AF, 0x00DD, 0x00FD, 0x00B0, 0x00C7, 0x00E7, 0x00D1, 0x00F1,
    0x00A1, 0x00BF, 0x00A4, 0x00A3, 0x00A5, 0x00A7, 0x0192, 0x00A2,
    0x00E2, 0x00EA, 0x00F4, 0x00FB, 0x00E1, 0x00E9, 0x00F3, 0x00FA,
    0x00E0, 0x00E8, 0x00F2, 0x00F9, 0x00E4, 0x00EB, 0x00F6, 0x00FC,
    0x00C5, 0x00EE, 0x00D8, 0x00C6, 0x00E5, 0x00ED, 0x00F8, 0x00E6,
    0x00C4, 0x00EC, 0x00D6, 0x00DC, 0x00C9, 0x00EF, 0x00DF, 0x00D4,
    0x00C1, 0x00C3, 0x00E3, 0x00D0, 0x00F0, 0x00CD, 0x00CC, 0x00D3,
    0x00D2, 0x00D5, 0x00F5, 0x0160, 0x0161, 0x00DA, 0x0178, 0x00FF,
    0x00DE, 0x00FE, 0x00B7, 0x00B5, 0x00B6, 0x00BE, 0x00AD, 0x00BC,
    0x00BD, 0x00AA, 0x00BA, 0x00AB, 0x25AE, 0x00BB, 0x00B1, 0x0000,
};

// ---------------------------------------------------------------------------
// IR helpers (file static & public). All compiled only when ir_printing.
// ---------------------------------------------------------------------------
fn charMap(charCode: u16) u8 {
    if (lastFunc == ITM_PRINTERALPHA) { // map control-char symbols only for pr_alpha
        var j: u32 = 0;
        while (j < 32) : (j += 1) { // characters below 0x20
            if (hp82240CharMap[j] == (charCode & ~@as(u16, 0x8000))) {
                return @intCast(j);
            }
        }
    }
    var i: u32 = 128;
    while (i < 255) : (i += 1) { // characters above 0x80
        if (hp82240CharMap[i] == (charCode & ~@as(u16, 0x8000))) {
            return @intCast(i);
        }
    }
    return 0;
}

fn findPrinterGlyph(font: *const printerFont_t, charCode: u16) i16 {
    const glyphs: [*]const glyphPrinter_t = @ptrFromInt(@intFromPtr(font) + @sizeOf(printerFont_t));
    var first: i16 = 0;
    var last: i16 = @as(i16, @bitCast(font.numberOfGlyphs)) - 1;
    var middle: i16 = @divTrunc(first + last, 2);
    while (last > first + 1) {
        if (charCode < glyphs[@intCast(middle)].charCode) {
            last = middle;
        } else {
            first = middle;
        }
        middle = @divTrunc(first + last, 2);
    }
    if (glyphs[@intCast(first)].charCode == charCode) {
        return first;
    }
    if (glyphs[@intCast(last)].charCode == charCode) {
        return last;
    }
    return @as(i16, @bitCast(font.numberOfGlyphs)) - 1;
}

fn findMartelGlyph(font: *const martelFont24_t, charCode: u16) u16 {
    const glyphs: [*]const glyphMartelPrinter_t = @ptrFromInt(@intFromPtr(font) + @sizeOf(martelFont24_t));
    var first: u16 = 0;
    var last: u16 = font.numberOfGlyphs - 1;
    var middle: u16 = (first + last) / 2;
    while (last > first + 1) {
        if (charCode < glyphs[middle].charCode) {
            last = middle;
        } else {
            first = middle;
        }
        middle = (first + last) / 2;
    }
    if (glyphs[first].charCode == charCode) {
        return first;
    }
    if (glyphs[last].charCode == charCode) {
        return last;
    }
    return 255;
}

fn _exitKeyPressed() bool_t {
    if (comptime dmcp_build) {
        const key: c_int = C47PopKeyNoBuffer(!(DISPLAY_WAIT_FOR_RELEASE != 0)) + 1;
        if (key == 36 or key == 33) { // R/S or EXIT
            _ = key_pop();
            clearKeyBuffer();
            return true;
        } else {
            key_pop_all();
            clearKeyBuffer();
            return false;
        }
    } else {
        return currentKeyCode == 32; // EXIT1 / EXIT key
    }
}

fn setPrinterSBI(status: bool_t) void {
    printerIconEnabled = status;
    setSystemFlagChanged(SETTING_PRINTERICON);
    refreshStatusBar();
}
const SETTING_PRINTERICON: i32 = 134; // defines.h:935 0x86 (was 130; status bar reads 134)

const charWidths = [171]u8{
    162, 143, 210, 208, 215, 179, 100, 209, 130, 167, 178, 199,
    215, 85,  107, 123, 160, 172, 172, 88,  178, 177, 208, 208,
    166, 208, 179, 173, 209, 215, 130, 165, 170, 172, 172, 165,
    177, 172, 172, 214, 171, 117, 131, 209, 143, 215, 131, 178,
    215, 213, 143, 201, 213, 179, 172, 214, 170, 172, 215, 209,
    215, 95,  129, 129, 172, 172, 172, 172, 129, 207, 215, 136,
    172, 208, 173, 172, 172, 172, 136, 129, 172, 172, 166, 172,
    172, 112, 135, 147, 129, 171, 130, 129, 176, 131, 141, 208,
    115, 143, 82,  140, 50,  93,  129, 129, 57,  128, 165, 129,
    129, 57,  135, 137, 171, 129, 135, 93,  123, 123, 129, 129,
    87,  195, 129, 129, 129, 131, 57,  135, 141, 172, 171, 131,
    207, 165, 202, 177, 93,  167, 178, 135, 165, 124, 129, 177,
    136, 142, 143, 86,  129, 129, 129, 129, 129, 87,  165, 129,
    129, 129, 129, 129, 129, 129, 129, 129, 123, 129, 129, 129,
    129, 129, 21,
};
const charDivs = [3]u8{ 1, 6, 36 };

fn charlengths(c: u32) u32 {
    return (@as(u32, charWidths[c / 3]) / charDivs[c % 3]) % 6 + 1;
}

fn findlengths(posns: *[257]u16, smallp: c_int) void {
    const mask: c_int = if (smallp != 0) 256 else 0;
    posns[0] = 0;
    var i: c_int = 0;
    while (i < 256) : (i += 1) {
        posns[@intCast(i + 1)] = posns[@intCast(i)] + @as(u16, @intCast(charlengths(@intCast(i + mask)))) - 1;
    }
}

fn pixel_length(s_in: [*c]const u8, smallp: c_int) c_int {
    var len: c_int = 0;
    const offset: c_int = if (smallp != 0) 256 else 0;
    var s = s_in;
    while (s[0] != 0) {
        // INCLUDE_FONT_ESCAPE not defined for z47, so the escape branch is dead.
        len += @intCast(charlengths(@intCast(@as(c_int, s[0]) + offset)));
        s += 1;
    }
    return len;
}

fn prepareNewLine() void {
    if (comptime dmcp_build) {
        var i: c_int = 0;
        clearSystemFlag(FLAG_PRTACT);
        printer_advance_buf(PRINT_GRA_LN);
        while (printer_busy_for(PRINT_GRA_LN) != 0 and i < 50) {
            sys_timer_start(0, 100);
            sys_sleep();
            sys_timer_disable(0);
            i += 1;
        }
        setSystemFlag(@intCast(FLAG_PRTACT));
    }
}

fn printIR(c: u8) void {
    const mode = printerState.print_mode;
    if (c == '\n' and (mode == PMODE_GRAPHICS or mode == PMODE_SMALLGRAPHICS)) {
        sendByteIR(0x04);
    } else {
        sendByteIR(c);
    }
    if (fnTimerGetStatus(TO_CL_DROP) == TMR_RUNNING) {
        fnTimerStart(TO_CL_DROP, TO_CL_DROP, JM_CLRDROP_TIMER);
    }
}

fn printAdvance(nlMode: u8) void {
    printerColumn = 0;
    printIR(if (nlMode != 0) 0x04 else '\n');
    if (printerState.print_blank_line != 0) {
        printIR(if (nlMode != 0) 0x04 else '\n');
    }
    prepareNewLine();
}

fn advanceIfTrace() void {
    if (printerColumn != 0 and getSystemFlag(FLAG_TRACE)) {
        printAdvance(0);
    }
}

fn printTabImpl(col: u16) void {
    if (printerColumn > col) {
        printAdvance(0);
    }
    if (printerColumn < col) {
        var i: u16 = (col - printerColumn) % 7;
        if (i == 0 and printerColumn == 0 and col > 6) {
            i = 7;
        }
        printerColumn += i;
        if (i != 0) {
            sendByteIR(27);
            sendByteIR(@intCast(i));
            while (i != 0) {
                i -= 1;
                sendByteIR(0);
            }
        }
        var j: u16 = (col - printerColumn) / 7;
        while (j != 0) {
            j -= 1;
            sendByteIR(' ');
        }
        printerColumn = col;
    }
}

fn printGraphic(glen_in: u8, graphic_in: [*c]const u8) void {
    var glen = glen_in;
    var graphic = graphic_in;
    if (glen > 0) {
        sendByteIR(27);
        sendByteIR(glen);
        while (glen != 0) {
            glen -= 1;
            sendByteIR(graphic[0]);
            graphic += 1;
        }
    }
}

fn printGraphic8(glen_in: u8, graphic_in: [*c]const u8) void {
    var glen = glen_in;
    var graphic = graphic_in;
    const len: u8 = glen +% (if ((printerColumn == 0) or (printerColumn >= 160)) @as(u8, 1) else @as(u8, 2));
    if (glen > 0) {
        sendByteIR(27);
        sendByteIR(len);
        if (printerColumn != 0) {
            sendByteIR(0);
        }
        while (glen != 0) {
            glen -= 1;
            sendByteIR(graphic[0]);
            graphic += 1;
        }
        if (printerColumn < 160) {
            sendByteIR(0);
        }
        printerColumn += len;
    }
}

fn printGraphic24(glen_in: u8, graphic_in: [*c]const u8) void {
    var glen = glen_in;
    var graphic = graphic_in;
    if (glen > 0) {
        printerColumn += glen;
        sendByteIR(27);
        sendByteIR(0);
        sendByteIR(42);
        sendByteIR(33);
        sendByteIR(glen / 3);
        sendByteIR(0);
        while (glen != 0) {
            glen -= 1;
            sendByteIR(graphic[0]);
            graphic += 1;
        }
    }
}

fn printGlyph8(charCode: u16, font: *const printerFont_t) void {
    const glyphId = findPrinterGlyph(font, charCode);
    const glyphs: [*]const glyphPrinter_t = @ptrFromInt(@intFromPtr(font) + @sizeOf(printerFont_t));
    const glyph = &glyphs[@intCast(glyphId)];
    printGraphic8(5, &glyph.data);
}

fn printMartelGlyph(charCode: u16) void {
    const glyphId = findMartelGlyph(martelFont24, charCode);
    if (glyphId == 255) {
        printGlyph8(charCode, printerFont8);
    } else {
        const glyphs: [*]const glyphMartelPrinter_t = @ptrFromInt(@intFromPtr(martelFont24) + @sizeOf(martelFont24_t));
        const glyph = &glyphs[glyphId];
        printGraphic24(48, &glyph.data);
        printerColumn += 8;
    }
}

fn printGlyph24(charCode: u16, font: *const font_t) void {
    var graphic: [42]u8 = undefined;
    _ = memset(&graphic, 0, 42);
    const glyphId = findGlyph(font, charCode);

    var glyph: *glyph_t = undefined;
    if (glyphId >= 0) {
        const glyphs: [*]glyph_t = @ptrFromInt(@intFromPtr(font) + 4); // font_t header (id:i8 + numberOfGlyphs:u16 padded to 4)
        glyph = &glyphs[@intCast(glyphId)];
    } else if (glyphId == -1) {
        generateNotFoundGlyph(-1, charCode);
        glyph = glyphNotFound;
    } else if (glyphId == -2) {
        generateNotFoundGlyph(-2, charCode);
        glyph = glyphNotFound;
    } else {
        glyph = undefined; // C NULL deref would crash; preserved structurally
    }
    var data: [*c]u8 = glyph.data;

    var byte: u8 = 0;
    var row: u32 = @as(u32, glyph.rowsGlyph) + @as(u32, glyph.rowsBelowGlyph);
    while (row > glyph.rowsBelowGlyph) : (row -= 1) {
        var bit: i32 = 7;
        const row_scaled: u32 = row;
        var col: u32 = 0;
        while (col < glyph.colsGlyph) : (col += 1) {
            if (bit == 7) {
                byte = data[0];
                data += 1;
            }
            const graphic_byte: u32 = col * 3 + (24 - row_scaled) / 8;
            if (byte & 0x80 != 0) {
                graphic[graphic_byte] = graphic[graphic_byte] | (@as(u8, 1) << @intCast((row_scaled - 1) % 8));
            } else {
                graphic[graphic_byte] = graphic[graphic_byte] & ~(@as(u8, 1) << @intCast((row_scaled - 1) % 8));
            }
            byte <<= 1;
            bit -= 1;
            if (bit == -1) {
                bit = 7;
            }
        }
    }
    printGraphic24(42, &graphic);
    printerColumn += 14;
}

fn wrap(width_in: c_int) void {
    var width = width_in;
    if (@as(c_int, printerColumn) + width > PAPER_WIDTH) {
        printAdvance(0);
        if (width == 7) {
            width = 6;
        }
    }
    printerColumn += @intCast(width);
}

fn printLineImpl(buff_in: [*c]const u8, with_lf: c_int) void {
    const mode = printerState.print_mode;
    var graphic: [@intCast(PAPER_WIDTH)]u8 = undefined;
    const glen: u8 = 0;
    var w: u8 = 0;
    var buff = buff_in;

    setPrinterSBI(true);

    var c: u8 = buff[0];
    buff += 1;
    while (c != 0) : ({
        c = buff[0];
        buff += 1;
    }) {
        w = 0;
        if (mode == PMODE_DEFAULT) {
            if (c == 0o6 and buff[0] == 6) {
                continue;
            }
            if (c & 0x80 != 0) {
                const charCode: u16 = (@as(u16, c) << 8) | buff[0];
                buff += 1;
                c = charMap(charCode);
                if (c == 0) {
                    if (printerState.printer_model == PRINTER_HP) {
                        printGlyph8(charCode, printerFont8);
                    } else if (printerState.printer_model == PRINTER_MARTEL) {
                        printMartelGlyph(charCode);
                    }
                } else {
                    w = if (printerColumn == 0 or printerColumn == 160) 6 else 7;
                    wrap(w);
                    sendByteIR(c);
                }
            } else {
                w = if (printerColumn == 0 or printerColumn == 160) 6 else 7;
                printGraphic(glen, &graphic);
                wrap(w);
                sendByteIR(c);
            }
        }
    }
    printGraphic(glen, &graphic);
    if (with_lf != 0) {
        printAdvance(0);
    }

    setPrinterSBI(false);
}

fn printJustifiedImpl(buff: [*c]const u8) void {
    const pmode = printerState.print_mode;
    var len: u16 = if (pmode == PMODE_DEFAULT)
        @as(u16, @intCast(stringGlyphLength(buff))) * 7 - 1
    else
        @intCast(pixel_length(buff, @intFromBool(pmode == PMODE_SMALLGRAPHICS)));
    const paperWidth: u16 = @intCast(PAPER_WIDTH);

    if (len >= paperWidth - printerColumn) {
        len = paperWidth - printerColumn;
    }
    if (len > 0) {
        printTabImpl(paperWidth - len);
    }
    printLineImpl(buff, 1);
}

fn printJustifiedLeft(buff: [*c]const u8) void {
    const pmode = printerState.print_mode;
    var len: u16 = if (pmode == PMODE_DEFAULT)
        @as(u16, @intCast(stringGlyphLength(buff))) * 7 - 1
    else
        @intCast(pixel_length(buff, @intFromBool(pmode == PMODE_SMALLGRAPHICS)));
    const paperWidth: u16 = (@as(u16, @intCast(PAPER_WIDTH)) / 2) - 7;

    if (len >= paperWidth - printerColumn) {
        len = paperWidth - printerColumn;
    }
    if (len > 0) {
        printTabImpl(paperWidth - len);
    }
    printLineImpl(buff, 0);
}

fn _realStringToPrint(realString: [*c]u8, max_len: i16) void {
    const len: u16 = @intCast(strlen(realString));
    var k: u16 = 0;
    if (stringGlyphLength(realString) > max_len) {
        var i: u16 = 0;
        while (i < len) : (i += 1) {
            if ((realString[i] == 'e') or (realString[i] == 'E')) {
                const expLen: u16 = len - i;
                const from = realString + i;
                var pos: u16 = 1;
                var j: i32 = 0;
                while (j < @as(i32, max_len) - @as(i32, @intCast(expLen)) - 1) : (j += 1) {
                    pos = @intCast(stringNextGlyph(realString, @intCast(pos)));
                }
                const to = realString + pos;
                _ = memmove(to, from, expLen + 1);
                break;
            } else if (realString[i] & 0x80 != 0) {
                i += 1;
            }
            k += 1;
            if (k >= max_len) {
                realString[i + 1] = 0;
                break;
            }
        }
    }
}

fn _real34ToPrintString(real34: *real34_t, amMode: u16, realString: [*c]u8, maxWidth: i16) void {
    const grpGroupingLeftOld = grpGroupingLeft;
    const grpGroupingRightOld = grpGroupingRight;

    grpGroupingLeft = 0;
    grpGroupingRight = 0;
    real34ToDisplayString(real34, amMode, realString, &standardFont, maxWidth, 16, true, false, 1);
    grpGroupingRight = grpGroupingRightOld;
    grpGroupingLeft = grpGroupingLeftOld;
    const len: u16 = @intCast(strlen(realString));

    var j: u16 = 0;
    var i: u16 = 0;
    while (i < len) : (i += 1) {
        switch (realString[i]) {
            0x80 => {
                if (realString[i + 1] == STD_CROSS[1]) {
                    realString[j] = 'E';
                    j += 1;
                    i += 3;
                    if (realString[i + 1] == '+') {
                        i += 1;
                    }
                } else if (realString[i + 1] == STD_DEGREE[1]) {
                    realString[j] = 0x80;
                    j += 1;
                    realString[j] = 0xB0;
                    j += 1;
                    i += 1;
                } else {
                    i += 1;
                }
            },
            0xa0 => {
                if (realString[i + 1] <= 0x0f) {
                    i += 1;
                } else {
                    realString[j] = realString[i];
                    j += 1;
                    realString[j] = realString[i + 1];
                    j += 1;
                    i += 1;
                }
            },
            0xa1 => {
                if (realString[i + 1] == STD_SUP_MINUS[1]) {
                    realString[j] = '-';
                    j += 1;
                    i += 1;
                } else if ((realString[i + 1] >= STD_SUP_0[1]) and (realString[i + 1] <= STD_SUP_9[1])) {
                    realString[j] = realString[i + 1] -% 0x30;
                    j += 1;
                    i += 1;
                } else {
                    i += 1;
                }
            },
            0xac => {
                if ((realString[i + 1] == STD_SUP_pir[1]) and (printerState.printer_model == PRINTER_HP)) {
                    realString[j] = STD_SUP_pi[0];
                    j += 1;
                    realString[j] = STD_SUP_pi[1];
                    j += 1;
                    i += 1;
                } else {
                    realString[j] = realString[i];
                    j += 1;
                    realString[j] = realString[i + 1];
                    j += 1;
                    i += 1;
                }
            },
            0x81, 0x82, 0x83, 0x9d, 0x9e, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7, 0xa9, 0xab => {
                realString[j] = realString[i];
                j += 1;
                realString[j] = realString[i + 1];
                j += 1;
                i += 1;
            },
            else => {
                realString[j] = realString[i];
                j += 1;
            },
        }
    }
    realString[j] = 0;
}

fn _complex34ToPrintString(registReal34: *real34_t, registImag34: *real34_t, tagAngle_in: u16, tagPolar: u16, realString: [*c]u8) void {
    _ = realString;
    const max_len: i16 = 17;
    var real: real_t = undefined;
    var imagIc: real_t = undefined;
    var real34: real34_t = undefined;
    var imag34: real34_t = undefined;
    var tagAngle = tagAngle_in;

    if (tagPolar != 0) {
        temporaryFlagPolar = true;
        real34ToReal(registReal34, &real);
        real34ToReal(registImag34, &imagIc);

        var c: realContext_t = ctxtReal39;
        const maxExponent: i32 = cMax(i32, real.exponent + real.digits, imagIc.exponent + imagIc.digits);
        c.digits = if (showMode()) 39 else cMax(i32, 0, maxExponent) + numberOfDisplayRealContextDigits() + 2;
        realRectangularToPolar(&real, &imagIc, &real, &imagIc, &c);
        c.digits = if (showMode()) 39 else 3 + numberOfDisplayRealContextDigits();
        convertAngleFromTo(&imagIc, amRadian, tagAngle, &c);

        realToReal34(&real, &real34);
        realToReal34(&imagIc, &imag34);
    } else {
        real34Copy(registReal34, &real34);
        real34Copy(registImag34, &imag34);
    }

    // Real part
    _real34ToPrintString(&real34, @intCast(amNone), tmpString, max_len * 9);
    _realStringToPrint(tmpString, max_len);

    // Separator
    if (tagPolar != 0) {
        _ = strcat(tmpString, STD_MEASURED_ANGLE);
        tagAngle = if (tagAngle == amNone) @intCast(currentAngularMode) else tagAngle;
    } else {
        _ = strcat(tmpString, "+i");
        _ = strcat(tmpString, PRODUCT_SIGN);
        tagAngle = @intCast(amNone);
    }

    // Imaginary part
    const imaginaryPart = tmpString + strlen(tmpString);
    _real34ToPrintString(&imag34, tagAngle, imaginaryPart, max_len * 9);
    _realStringToPrint(imaginaryPart, max_len + (if (tagPolar != 0) @as(i16, 1) else 0));
}

fn printRegImpl(regist: u16, label: [*c]const u8, eq: bool_t, where: print_area_t, prSigma: bool) void {
    var max_len: i16 = if ((where == LINE_FULL) or (where == LINE_NOLF)) 17 else 11;
    if (prSigma) {
        max_len -= 1;
    }

    if (label != null) {
        printLineImpl(label, 0);
        if (eq) {
            printLineImpl("=", 0);
        }
    }

    switch (getRegisterDataType(@bitCast(regist))) {
        dtString => {
            _ = strcpy(tmpString, regString(@bitCast(regist)));
            if (where == LINE_FULL) {
                addChrBothSides(34, tmpString);
            }
        },
        dtReal34 => {
            _real34ToPrintString(reg34(@bitCast(regist)), @intCast(getRegisterAngularMode(@bitCast(regist))), tmpString, max_len * 9);
            _realStringToPrint(tmpString, max_len);
        },
        dtComplex34 => {
            const tagAngle = getComplexRegisterAngularMode(@bitCast(regist));
            const tagPolar = getComplexRegisterPolarMode(@bitCast(regist));
            const real34 = reg34(@bitCast(regist));
            const imag34 = regImag34(@bitCast(regist));
            _complex34ToPrintString(real34, imag34, tagAngle, tagPolar, tmpString);
        },
        dtReal34Matrix => {
            const matrixHeader = regMatrixHeader(@bitCast(regist));
            var real34 = regReal34MatrixElems(@bitCast(regist));
            var reduced: real34_t = undefined;
            const rows: u16 = matrixHeader.matrixRows;
            const columns: u16 = matrixHeader.matrixColumns;
            _ = sprintf(tmpString, "[ %u" ++ "x%u" ++ " Matrix ]", @as(c_uint, rows), @as(c_uint, columns));
            printJustifiedImpl(tmpString);
            var i: u16 = 1;
            while (i <= rows) : (i += 1) {
                var jj: u16 = 1;
                while (jj <= columns) : (jj += 1) {
                    _ = sprintf(tmpString, "%u" ++ ":%u" ++ "=", @as(c_uint, i), @as(c_uint, jj));
                    printLineImpl(tmpString, 0);
                    real34Reduce(real34, &reduced);
                    real34 += 1;
                    _real34ToPrintString(&reduced, @intCast(amNone), tmpString, max_len * 9);
                    _realStringToPrint(tmpString, max_len);
                    printJustifiedImpl(tmpString);
                }
            }
            return;
        },
        dtComplex34Matrix => {
            var cpxMatrix: complex34Matrix_t = undefined;
            const matrix = &cpxMatrix;
            const tagAngle = getComplexRegisterAngularMode(@bitCast(regist));
            const tagPolar = getComplexRegisterPolarMode(@bitCast(regist));
            linkToComplexMatrixRegister(@bitCast(regist), matrix);
            const rows: u16 = matrix.header.matrixRows;
            const cols: u16 = matrix.header.matrixColumns;
            _ = sprintf(tmpString, "[ %u" ++ "x%u" ++ " Cpx Matrix ]", @as(c_uint, rows), @as(c_uint, cols));
            printJustifiedImpl(tmpString);
            var i: u16 = 0;
            while (i < rows) : (i += 1) {
                var jj: u16 = 0;
                while (jj < cols) : (jj += 1) {
                    _ = sprintf(tmpString, "%u" ++ ":%u" ++ "=", @as(c_uint, i + 1), @as(c_uint, jj + 1));
                    printLineImpl(tmpString, 0);
                    const elem: [*c]const complex34_t = matrix.matrixElements + (i * cols + jj);
                    const real34 = @constCast(varReal34(elem));
                    const imag34 = @constCast(varImag34(elem));
                    _complex34ToPrintString(real34, imag34, tagAngle, tagPolar, tmpString);
                    printJustifiedImpl(tmpString);
                }
            }
            return;
        },
        dtShortInteger => {
            var shortInt: u64 = regShortInt(@bitCast(regist)).* & shortIntegerMask;
            const base: i16 = @intCast(getRegisterShortIntegerBase(@bitCast(regist)));
            var n: i16 = @as(i16, @intCast(ERROR_MESSAGE_LENGTH)) - 100;
            _ = sprintf(errorMessage + @as(usize, @intCast(n)), "#%02d", @as(c_int, base));
            n -= 1;
            if (shortInt == 0) {
                errorMessage[@intCast(n)] = '0';
                n -= 1;
            } else {
                while (shortInt != 0) {
                    errorMessage[@intCast(n)] = baseDigits[@intCast(shortInt % @as(u64, @intCast(base)))];
                    n -= 1;
                    shortInt /= @intCast(base);
                }
            }
            n += 1;
            _ = strcpy(tmpString, errorMessage + @as(usize, @intCast(n)));
        },
        else => {
            copyRegisterToClipboardString(@bitCast(regist), tmpString, true);
        },
    }

    if (label == null and (where == LINE_FULL or where == LINE_NOLF)) {
        var glen: u16 = @intCast(stringGlyphLength(tmpString));
        if ((where == LINE_NOLF) and (glen < 17)) {
            const padding: u16 = 17 - glen;
            printTabImpl(padding * 7 - 1);
        }
        if (glen > 17) {
            glen = glen % 24;
            const padding: u16 = if (glen <= 17) 17 - glen else 24 - (glen - 17);
            var i: u16 = 0;
            while (i < padding) : (i += 1) {
                _ = strcat(tmpString, " ");
            }
        }
        if (where == LINE_FULL) {
            _ = strcpy(tmpString + strlen(tmpString), "    ***");
        }
    }

    switch (where) {
        LINE_FULL, LINE_RIGHT => printJustifiedImpl(tmpString),
        LINE_LEFT => printJustifiedLeft(tmpString),
        LINE_NOLF, LINE_ASIS => printLineImpl(tmpString, 0),
        else => printJustifiedImpl(tmpString),
    }
}

fn printAlphaImpl(Alpha: [*c]const u8, arg: printArgument_t) void {
    if (!getSystemFlag(FLAG_PRTACT)) return; // RETURN_IF_PRINT_OFF
    advanceIfTrace();
    if (arg == PRINT_ALPHA_JUST) {
        printJustifiedImpl(Alpha);
    } else {
        printLineImpl(Alpha, @intFromBool(arg == PRINT_ALPHA));
    }
}

fn print_lfImpl() void {
    if (!getSystemFlag(FLAG_PRTACT)) return; // RETURN_IF_PRINT_OFF
    advanceIfTrace();
    printAdvance(0);
}

fn cmdPrintImpl(arg: u16, op: printArgument_t) void {
    var buff: [4]u8 = undefined;

    if (!getSystemFlag(FLAG_PRTACT)) {
        if (getSystemFlag(@bitCast(FLAG_PRTEN)) or ((programRunStop != PGM_RUNNING) and (programRunStop != PGM_SINGLE_STEP))) {
            displayCalcErrorMessage(ERROR_PRINTING_DISABLED, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
            if (comptime !dmcp_build) {
                _ = sprintf(errorMessage, "Printing is disabled");
                moreInfoOnError("In function cmdPrint:", errorMessage, null, null);
            }
        }
        return;
    }

    switch (op) {
        PRINT_BYTE => {
            printIR(@intCast(arg & 0xff));
            if (arg == '\n' or arg == 0x04) {
                prepareNewLine();
            }
        },
        PRINT_CHAR => {
            var line: usize = 0;
            if (arg & 0xff00 != 0) {
                buff[line] = @intCast((arg | 0x8000) >> 8);
                line += 1;
            }
            buff[line] = @intCast(arg & 0xff);
            line += 1;
            buff[line] = 0;
            printLineImpl(&buff, 0);
        },
        PRINT_TAB => {
            printTabImpl(arg);
        },
        else => {},
    }
}

fn setPrintMode(mode: u8) void {
    sendByteIR(27);
    sendByteIR(0);
    sendByteIR(33);
    sendByteIR(mode);
}

fn reverse(b_in: u8) u8 {
    var b = b_in;
    b = (b & 0xF0) >> 4 | (b & 0x0F) << 4;
    b = (b & 0xCC) >> 2 | (b & 0x33) << 2;
    b = (b & 0xAA) >> 1 | (b & 0x55) << 1;
    return b;
}

fn printLcd() void {
    var line_addr: [*c]u8 = null;
    var data: u8 = undefined;

    sendByteIR('\n');
    var x: i32 = 16;
    while (x >= 0) : (x -= 1) {
        printerColumn = 0;
        printTabImpl(30);
        sendByteIR(27);
        sendByteIR(0);
        sendByteIR(42);
        sendByteIR(33);
        sendByteIR(242);
        sendByteIR(0);
        sendByteIR(if (x == 16) 0x1f else 0xff);
        sendByteIR(0xff);
        sendByteIR(if (x == 0) 0xf1 else 0xff);
        var y: i32 = SCREEN_HEIGHT - 1;
        while (y >= 0) : (y -= 1) {
            if (comptime dmcp_build) {
                line_addr = lcd_line_addr(y);
            }
            var i: i16 = 2;
            while (i >= 0) : (i -= 1) {
                const offset: i32 = 3 * x + i;
                if ((offset > 0) and (offset < 50)) {
                    data = ((((~line_addr[@intCast(offset)]) << 4) & 0xf0) | (((~line_addr[@intCast(offset - 1)]) >> 4) & 0x0f));
                } else if (offset == 0) {
                    data = (((~line_addr[@intCast(offset)]) << 4) & 0xf0) | 0x08;
                } else {
                    data = 0x10 | (((~line_addr[@intCast(offset - 1)]) >> 4) & 0x0f);
                }
                sendByteIR(data);
            }
        }
        sendByteIR(if (x == 16) 0x1f else 0xff);
        sendByteIR(0xff);
        sendByteIR(if (x == 0) 0xf1 else 0xff);
        sendByteIR('\n');
    }
    setPrintMode(0x00);
    print_lfImpl();
}

fn _printRegRange(firstRegisterNo: u16, lastRegisterNo: u16) bool_t {
    currentKeyCode = 255;
    if (firstRegisterNo <= lastRegisterNo) {
        var regist: u16 = firstRegisterNo;
        while (regist <= lastRegisterNo) : (regist += 1) {
            fnP_Regs(regist);
            if (_exitKeyPressed()) {
                return true;
            }
        }
    } else {
        var regist: u16 = firstRegisterNo;
        while (regist >= lastRegisterNo) : (regist -= 1) {
            fnP_Regs(regist);
            if (_exitKeyPressed()) {
                return true;
            }
            if (regist == 0) break;
        }
    }
    currentKeyCode = 255;
    return false;
}

fn _getRegisterLabel(registerNo: u16, label: [*c]u8) void {
    label[0] = 0;
    if (REGISTER_X <= registerNo and registerNo <= REGISTER_W) {
        label[0] = letteredRegisterName(@bitCast(registerNo));
        label[1] = 0;
    } else if (registerNo < REGISTER_X) {
        _ = sprintf(label, "R%02d", @as(c_int, registerNo));
    } else if (FIRST_LOCAL_REGISTER <= registerNo and registerNo <= LAST_LOCAL_REGISTER) {
        _ = sprintf(label, "R.%03d", @as(c_int, registerNo) - 100);
    } else if (FIRST_NAMED_VARIABLE <= registerNo and registerNo <= LAST_NAMED_VARIABLE) {
        _ = sprintf(label, "%s", @as([*c]u8, &allNamedVariables[registerNo - FIRST_NAMED_VARIABLE].variableName) + 1);
    } else if (FIRST_NAMED_RESERVED_VARIABLE <= registerNo and registerNo <= LAST_RESERVED_VARIABLE) {
        _ = sprintf(label, "%s", @as([*c]const u8, &allReservedVariables[registerNo - FIRST_RESERVED_VARIABLE].reservedVariableName) + 1);
    }
}

fn _getUnicodeValue(regist: calcRegister_t) u16 {
    var value: i32 = 0;

    if (getRegisterDataType(regist) == dtReal34) {
        var maxValue34: real34_t = undefined;
        int32ToReal34(0x8000, &maxValue34);
        if (real34CompareLessThan(reg34(regist), const34_0()) or real34CompareLessEqual(&maxValue34, reg34(regist))) {
            displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
            if (comptime !dmcp_build) {
                _ = real34ToString(reg34(regist), errorMessage);
                _ = sprintf(tmpString, "x %d = %s:", @as(c_int, regist), errorMessage);
                moreInfoOnError("In function _getPositionFromRegister:", tmpString, "this value is negative or too big!", null);
            }
            return @bitCast(@as(i16, -1));
        }
        value = real34ToInt32(reg34(regist));
    } else if (getRegisterDataType(regist) == dtLongInteger) {
        var lgInt: longInteger_t = undefined;
        convertLongIntegerRegisterToLongInteger(regist, &lgInt[0]);
        if (longIntegerCompareUInt(&lgInt[0], 0) < 0 or longIntegerCompareUInt(&lgInt[0], 0x8000) >= 0) {
            displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
            longIntegerFree(&lgInt[0]);
            return @bitCast(@as(i16, -1));
        }
        value = @bitCast(longIntegerToUInt32(&lgInt[0]));
        longIntegerFree(&lgInt[0]);
    } else if (getRegisterDataType(regist) == dtShortInteger) {
        var lgInt: longInteger_t = undefined;
        // convertShortIntegerRegisterToLongInteger initialises lgInt; do not double-init (leak).
        convertShortIntegerRegisterToLongInteger(regist, &lgInt[0]);
        value = @bitCast(longIntegerToUInt32(&lgInt[0]));
        longIntegerFree(&lgInt[0]);
    } else {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime !dmcp_build) {
            _ = sprintf(errorMessage, "register %d is %s:", @as(c_int, regist), getRegisterDataTypeName(regist, true, false));
            moreInfoOnError("In function _getPositionFromRegister:", errorMessage, "not suited for addressing!", null);
        }
        return @bitCast(@as(i16, -1));
    }
    return @intCast(@as(u32, @bitCast(value)) & 0xffff);
}

// ---------------------------------------------------------------------------
// Public (pub export) printing functions, gated on ir_printing.
// On the dead branch the bridge's `#else` stubs are reproduced.
// ---------------------------------------------------------------------------
pub export fn printTab(col: u16) callconv(.c) void {
    if (comptime ir_printing) printTabImpl(col);
}
pub export fn printLine(buff: [*c]const u8, with_lf: c_int) callconv(.c) void {
    if (comptime ir_printing) printLineImpl(buff, with_lf);
}
pub export fn printJustified(buff: [*c]const u8) callconv(.c) void {
    if (comptime ir_printing) printJustifiedImpl(buff);
}
pub export fn printReg(regist: u16, label: [*c]const u8, eq: bool_t, where: print_area_t, prSigma: bool) callconv(.c) void {
    if (comptime ir_printing) printRegImpl(regist, label, eq, where, prSigma);
}
pub export fn printAlpha(Alpha: [*c]const u8, arg: printArgument_t) callconv(.c) void {
    if (comptime ir_printing) printAlphaImpl(Alpha, arg);
}
pub export fn print_lf() callconv(.c) void {
    if (comptime ir_printing) print_lfImpl();
}
pub export fn cmdPrint(arg: u16, op: printArgument_t) callconv(.c) void {
    if (comptime ir_printing) cmdPrintImpl(arg, op);
}

pub export fn printTraceErrorFunction(func: i16, errorString: [*c]u8) callconv(.c) void {
    if (comptime !ir_printing) return;
    if ((calcMode != CM_NORMAL) or ((tam.mode != 0) and ((func == ITM_BACKSPACE) or (func == 2017)))) {
        return;
    }
    if (getSystemFlag(FLAG_TRACE) and getSystemFlag(FLAG_PRTACT)) {
        nameAlias(@bitCast(func), tmpString);
        _ = strcat(tmpString, " ");
        _ = strcat(tmpString, errorString);
        printJustifiedImpl(tmpString);
        leaveTamModeIfEnabled();
        if (comptime !dmcp_build) {
            _ = printf("**[DL]** Trace: %s\n", tmpString);
            _ = fflush(null);
        }
    }
}

pub export fn printTraceError(errorString: [*c]u8) callconv(.c) void {
    if (comptime !ir_printing) return;
    if (getSystemFlag(FLAG_TRACE) and getSystemFlag(FLAG_PRTACT)) {
        printLineImpl(errorString, 1);
        if (comptime !dmcp_build) {
            _ = printf("**[DL]** Trace: %s\n", errorString);
            _ = fflush(null);
        }
    }
}

pub export fn printTraceX(where: u16) callconv(.c) void {
    if (comptime !ir_printing) return;
    if ((getSystemFlag(FLAG_TRACE) or getSystemFlag(@bitCast(FLAG_NORM))) and getSystemFlag(FLAG_PRTACT)) {
        if (getSystemFlag(FLAG_TRACE) and getSystemFlag(@bitCast(FLAG_NORM)) and (where == LINE_FULL)) {
            _ = _printRegRange(@bitCast(if (getSystemFlag(FLAG_SSIZE8)) REGISTER_D else REGISTER_T), @bitCast(REGISTER_X));
            print_lfImpl();
        } else {
            printRegImpl(@bitCast(REGISTER_X), null, false, @intCast(where), false);
        }
        if (comptime !dmcp_build) {
            _ = printf("**[DL]** Trace: %s\n", tmpString);
            _ = fflush(null);
        }
    }
}

pub export fn printTraceMatElement(where: u16) callconv(.c) void {
    if (comptime !ir_printing) return;
    if (getSystemFlag(FLAG_TRACE) and getSystemFlag(FLAG_PRTACT)) {
        const i: i16 = getIRegisterAsInt(true);
        const j: i16 = getJRegisterAsInt(true);
        if (getRegisterDataType(matrixIndexReg()) == dtReal34Matrix) {
            var mat: real34Matrix_t = undefined;
            const matrix = &mat;
            convertReal34MatrixRegisterToReal34Matrix(matrixIndexReg(), &mat);
            reallocateRegister(TEMP_REGISTER_1, dtReal34, 0, amNone);
            real34Copy(&matrix.matrixElements[@as(usize, @intCast(i)) * matrix.header.matrixColumns + @as(usize, @intCast(j))], reg34(TEMP_REGISTER_1));
        } else {
            var mat: complex34Matrix_t = undefined;
            const matrix = &mat;
            convertComplex34MatrixRegisterToComplex34Matrix(matrixIndexReg(), &mat);
            reallocateRegister(TEMP_REGISTER_1, dtComplex34, 0, amNone);
            complex34Copy(&matrix.matrixElements[@as(usize, @intCast(i)) * matrix.header.matrixColumns + @as(usize, @intCast(j))], reg34(TEMP_REGISTER_1));
        }
        printRegImpl(@bitCast(TEMP_REGISTER_1), null, false, @intCast(where), false);
        if (comptime !dmcp_build) {
            _ = printf("**[DL]** printTraceMatElement where %d Trace: %s\n", @as(c_int, @intCast(where)), tmpString);
            _ = fflush(null);
        }
    }
}
extern var matrixIndex: u16;
inline fn matrixIndexReg() calcRegister_t {
    return @bitCast(matrixIndex);
}

pub export fn printTraceString(string: [*c]u8, where: u16) callconv(.c) void {
    if (comptime !ir_printing) return;
    const lenInBytes: i16 = @intCast(stringByteLength(string) + 1);
    if ((getSystemFlag(FLAG_TRACE) or getSystemFlag(@bitCast(FLAG_NORM))) and getSystemFlag(FLAG_PRTACT)) {
        reallocateRegister(TEMP_REGISTER_1, dtString, toBlocks(@intCast(lenInBytes)), amNone);
        _ = xcopy(regString(TEMP_REGISTER_1), string, @intCast(lenInBytes));
        printRegImpl(@bitCast(TEMP_REGISTER_1), null, false, @intCast(where), false);
        if (comptime !dmcp_build) {
            _ = printf("**[DL]** printTraceString Trace: %s\n", tmpString);
            _ = fflush(null);
        }
    }
}
inline fn toBlocks(n: u32) u16 {
    return @intCast((n + (4 - 1)) >> 2);
}

pub export fn printTraceTI() callconv(.c) void {
    if (comptime !ir_printing) return;
    if (calcMode != CM_NORMAL) {
        return;
    }
    if (getSystemFlag(FLAG_TRACE) and getSystemFlag(FLAG_PRTACT)) {
        if ((programRunStop != PGM_RUNNING) and (programRunStop != PGM_SINGLE_STEP)) {
            tmpString[0] = 0;
            switch (temporaryInformation) {
                TI_FALSE => _ = sprintf(tmpString, "false"),
                TI_TRUE => _ = sprintf(tmpString, "true"),
                else => {},
            }
            if (tmpString[0] != 0) {
                printLineImpl(tmpString, 1);
                if (comptime !dmcp_build) {
                    _ = printf("**[DL]** Trace: %s\n", tmpString);
                    _ = fflush(null);
                }
            }
        }
    }
}

pub export fn printInputPrompt(func: u16, regist: u16) callconv(.c) void {
    if (comptime !ir_printing) return;
    if ((getSystemFlag(FLAG_TRACE) or getSystemFlag(@bitCast(FLAG_NORM))) and getSystemFlag(FLAG_PRTACT)) {
        if (getSystemFlag(@bitCast(FLAG_PRTEN)) or ((programRunStop != PGM_RUNNING) and (programRunStop != PGM_SINGLE_STEP) and (programRunStop != PGM_WAITING))) {
            if (func == ITM_PROMPT) {
                printRegImpl(regist, null, false, LINE_ASIS, false);
                print_lfImpl();
                if (comptime !dmcp_build) {
                    _ = printf("**[DL]** Trace: %s\n", tmpString);
                    _ = fflush(null);
                }
            } else {
                var label: [16]u8 = undefined;
                _getRegisterLabel(regist, &label);
                var len: usize = strlen(&label);
                label[len] = '?';
                len += 1;
                label[len] = 0;
                printRegImpl(regist, &label, false, LINE_ASIS, false);
                print_lfImpl();
                if (comptime !dmcp_build) {
                    _ = printf("**[DL]** Trace: %s\n", tmpString);
                    _ = fflush(null);
                }
                tmpString[0] = 0;
            }
        }
    }
}

pub export fn printViewAview(func: u16, regist: u16) callconv(.c) void {
    if (comptime !ir_printing) return;
    if (getSystemFlag(FLAG_PRTACT)) {
        if (getSystemFlag(@bitCast(FLAG_PRTEN)) or ((programRunStop != PGM_RUNNING) and (programRunStop != PGM_SINGLE_STEP))) {
            if (func == ITM_VIEW) {
                var label: [16]u8 = undefined;
                _getRegisterLabel(regist, &label);
                printRegImpl(regist, &label, true, LINE_ASIS, false);
                print_lfImpl();
                if (comptime !dmcp_build) {
                    _ = printf("**[DL]** Trace: %s=%s\n", &label, tmpString);
                    _ = fflush(null);
                }
            } else {
                printRegImpl(regist, null, false, LINE_ASIS, false);
                print_lfImpl();
                if (comptime !dmcp_build) {
                    _ = printf("**[DL]** Trace: %s\n", tmpString);
                    _ = fflush(null);
                }
            }
        }
    } else {
        if (getSystemFlag(@bitCast(FLAG_PRTEN)) and (programRunStop == PGM_RUNNING)) {
            fnStopProgram(NOPARAM);
        }
    }
}

pub export fn printTrace(func: i16, param_in: u16) callconv(.c) void {
    if (comptime !ir_printing) return;
    var traceBuffer: [32]u8 = undefined;
    var param = param_in;

    printerState.trace_done = true;
    if (((calcMode != CM_NORMAL) and (calcMode != CM_MIM)) or ((tam.mode != 0) and ((func == ITM_BACKSPACE) or (func == 2017)))) {
        return;
    }

    if ((getSystemFlag(FLAG_TRACE) or getSystemFlag(@bitCast(FLAG_NORM))) and getSystemFlag(FLAG_PRTACT)) {
        if ((programRunStop != PGM_RUNNING) and (programRunStop != PGM_SINGLE_STEP)) {
            if (func < 0) {
                if (func == -@as(i16, @intCast(MNU_DYNAMIC))) {
                    printJustifiedImpl(&userMenus[currentUserMenu].menuName);
                    if (comptime !dmcp_build) {
                        _ = printf("**[DL]** Trace: %s\n", &userMenus[currentUserMenu].menuName);
                        _ = fflush(null);
                    }
                } else {
                    printJustifiedImpl(&indexOfItems[@intCast(-func)].itemSoftmenuName);
                    if (comptime !dmcp_build) {
                        _ = printf("**[DL]** Trace: %s\n", &indexOfItems[@intCast(-func)].itemSoftmenuName);
                        _ = fflush(null);
                    }
                }
            } else if ((func != ITM_PRINTERADV) and (func != ITM_PRINTERX)) {
                var buffer: [16]u8 = undefined;
                _ = xcopy(&buffer, tmpString, 16);
                nameAlias(@bitCast(func), tmpString);
                if ((indexOfItems[@intCast(func)].func != addItemToBufferFn) and (indexOfItems[@intCast(func)].param != NOPARAM) and ((indexOfItems[@intCast(func)].status & PTP_STATUS) != PTP_NONE)) {
                    traceBuffer[0] = 0;
                    if (tam.indirect) {
                        _ = strcat(tmpString, " " ++ STD_RIGHT_ARROW);
                        param = @bitCast(tam.value0);
                    }
                    if ((tam.mode == TM_VALUE) and !tam.indirect) {
                        const tamMax: u16 = indexOfItems[@intCast(func)].tamMinMax & TAM_MAX_MASK;
                        if (tamMax <= 9) {
                            _ = sprintf(&traceBuffer, " %u", @as(c_uint, param));
                        } else if (tamMax <= 99) {
                            _ = sprintf(&traceBuffer, " %02u", @as(c_uint, param));
                        } else if (tamMax <= 999) {
                            _ = sprintf(&traceBuffer, " %03u", @as(c_uint, param));
                        } else {
                            _ = sprintf(&traceBuffer, " %04u", @as(c_uint, param));
                        }
                    } else if ((func == ITM_OPEN_MENU) and !tam.indirect) {
                        if (param == MNU_DYNAMIC) {
                            _ = sprintf(&traceBuffer, " " ++ STD_LEFT_SINGLE_QUOTE ++ "%s" ++ STD_RIGHT_SINGLE_QUOTE, &buffer);
                        } else {
                            _ = sprintf(&traceBuffer, " " ++ STD_LEFT_SINGLE_QUOTE ++ "%s" ++ STD_RIGHT_SINGLE_QUOTE, &indexOfItems[@intCast(tam.value)].itemCatalogName);
                        }
                    } else if (tam.mode == TM_SHUFFLE) {
                        _ = sprintf(&traceBuffer, " %c%c%c%c", @as(c_int, shuffleReg[param & 0x03]), @as(c_int, shuffleReg[(param & 0x0c) >> 2]), @as(c_int, shuffleReg[(param & 0x30) >> 4]), @as(c_int, shuffleReg[(param & 0xc0) >> 6]));
                    } else if ((param >= FIRST_NAMED_VARIABLE) and (param <= LAST_NAMED_VARIABLE)) {
                        if (!tam.indirect) {
                            _ = strcat(tmpString, " ");
                        }
                        _ = strcat(tmpString, STD_LEFT_SINGLE_QUOTE);
                        _ = strcat(tmpString, @as([*c]u8, &allNamedVariables[param - FIRST_NAMED_VARIABLE].variableName) + 1);
                        _ = strcat(tmpString, STD_RIGHT_SINGLE_QUOTE);
                    } else if ((param >= FIRST_NAMED_RESERVED_VARIABLE) and (param <= LAST_RESERVED_VARIABLE)) {
                        if (!tam.indirect) {
                            _ = strcat(tmpString, " ");
                        }
                        _ = strcat(tmpString, STD_LEFT_SINGLE_QUOTE);
                        _ = strcat(tmpString, @as([*c]const u8, &allReservedVariables[param - FIRST_RESERVED_VARIABLE].reservedVariableName) + 1);
                        _ = strcat(tmpString, STD_RIGHT_SINGLE_QUOTE);
                    } else if ((tam.mode == TM_LABEL or tam.mode == TM_LBLONLY or func == ITM_XEQ) and !tam.indirect) {
                        if (param < 99) {
                            _ = sprintf(&traceBuffer, " %02u", @as(c_uint, param));
                        } else if (param <= LAST_UC_LOCAL_LABEL) {
                            _ = sprintf(&traceBuffer, " %c", @as(c_int, 'A') + (@as(c_int, param) - 100));
                        } else if (param <= LAST_LOCAL_LABEL) {
                            _ = sprintf(&traceBuffer, " %c", @as(c_int, 'a') + (@as(c_int, param) - FIRST_LC_LOCAL_LABEL));
                        } else if ((param >= FIRST_LABEL) and (param <= LAST_LABEL)) {
                            _ = strcat(tmpString, " " ++ STD_LEFT_SINGLE_QUOTE);
                            const strLength: u16 = @intCast(stringByteLength(tmpString));
                            const lp = labelList[@as(usize, param) - @as(usize, @intCast(FIRST_LABEL))].labelPointer;
                            const lblNameLen = boundProgramNameLength(lp + 1, lp[0]);
                            _ = xcopy(tmpString + strLength, lp + 1, lblNameLen);
                            tmpString[strLength + lblNameLen] = 0;
                            _ = strcat(tmpString, STD_RIGHT_SINGLE_QUOTE);
                        }
                    } else if ((tam.mode == TM_FLAGR or tam.mode == TM_FLAGW) and !tam.indirect) {
                        if (param < FLAG_X) {
                            _ = sprintf(&traceBuffer, " %02u", @as(c_uint, param));
                        } else if (FLAG_X <= param and param <= FLAG_K) {
                            _ = sprintf(&traceBuffer, " %c", @as(c_int, registerFlagLetters[@as(usize, param) - @as(usize, @intCast(FLAG_X))]));
                        } else if (param <= LAST_LOCAL_FLAG) {
                            _ = sprintf(&traceBuffer, " .%02d", @as(c_int, param) - FIRST_LOCAL_FLAG);
                        } else if (param < FLAG_M) {
                            _ = sprintf(&traceBuffer, " %02u", @as(c_uint, param));
                        } else if (param <= FLAG_W) {
                            _ = sprintf(&traceBuffer, " %c", @as(c_int, registerFlagLetters[@as(usize, @intCast(@as(c_int, param) - FLAG_M + (FLAG_K - FLAG_X + 1)))]));
                        } else if (param & 0x8000 != 0) {
                            param &= 0x3fff;
                            if (param < 64) {
                                _ = sprintf(&traceBuffer, " " ++ STD_LEFT_SINGLE_QUOTE ++ "%s" ++ STD_RIGHT_SINGLE_QUOTE, &indexOfItems[@as(usize, @intCast(@as(c_int, param) + SFL_TDM24))].itemSoftmenuName);
                            } else {
                                _ = sprintf(&traceBuffer, " " ++ STD_LEFT_SINGLE_QUOTE ++ "%s" ++ STD_RIGHT_SINGLE_QUOTE, &indexOfItems[@as(usize, @intCast(@as(c_int, param) + SFL_MONIT - 64))].itemSoftmenuName);
                            }
                        }
                    } else if ((tam.mode == TM_CMP) and (param == TEMP_REGISTER_1) and !tam.indirect) {
                        _ = sprintf(&traceBuffer, if (real34IsZero(reg34(TEMP_REGISTER_1)) != 0) " 0." else " 1.");
                    } else {
                        if (param < 99) {
                            if (!tam.indirect) {
                                _ = strcat(tmpString, " ");
                            }
                            _ = sprintf(&traceBuffer, "%02u", @as(c_uint, param));
                        } else if (param <= REGISTER_K) {
                            if (!tam.indirect) {
                                _ = strcat(tmpString, " ");
                            }
                            _ = sprintf(&traceBuffer, "%s", &indexOfItems[@as(usize, @intCast(ITM_REG_X + @as(c_int, param) - REGISTER_X))].itemSoftmenuName);
                        } else if (param <= REGISTER_W) {
                            if (!tam.indirect) {
                                _ = strcat(tmpString, " ");
                            }
                            _ = sprintf(&traceBuffer, "%s", &indexOfItems[@as(usize, @intCast(ITM_REG_M + @as(c_int, param) - REGISTER_M))].itemSoftmenuName);
                        } else if ((param >= FIRST_LOCAL_REGISTER) and (param <= LAST_LOCAL_REGISTER)) {
                            if (!tam.indirect) {
                                _ = strcat(tmpString, " ");
                            }
                            _ = sprintf(&traceBuffer, ".%02d", @as(c_int, param) - @as(c_int, @intCast(FIRST_LOCAL_REGISTER)));
                        }
                    }
                    _ = strcat(tmpString, &traceBuffer);
                } else if ((func == ITM_MENU) and (dynamicMenuItem >= 0)) {
                    _ = xcopy(tmpString, &programmableMenu.itemName[@intCast(dynamicMenuItem)], 16);
                }
                const width: u16 = @as(u16, @intCast(stringGlyphLength(tmpString))) * 7 - 1;
                if (@as(c_int, printerColumn) + width > PAPER_WIDTH) {
                    printAdvance(0);
                }
                printJustifiedImpl(tmpString);
                if (comptime !dmcp_build) {
                    _ = printf("**[DL]** Trace: %s\n", tmpString);
                    _ = fflush(null);
                }
            }
        } else if (getSystemFlag(FLAG_TRACE)) {
            decodeOneStep_ALIAS(currentStep);
            if (func == ITM_LBL) {
                printAdvance(0);
                _ = sprintf(&traceBuffer, " %02d", @as(c_int, @intCast(currentLocalStepNumber)));
                _ = strcat(&traceBuffer, STD_BLACK_RIGHT_TRIANGLE);
                _ = strcat(&traceBuffer, tmpString);
                printJustifiedImpl(&traceBuffer);
                if (comptime !dmcp_build) {
                    _ = printf("**[DL]** Trace: %s\n", &traceBuffer);
                    _ = fflush(null);
                }
            } else if (func >= 0) {
                printJustifiedImpl(tmpString);
                if (comptime !dmcp_build) {
                    _ = printf("**[DL]** Trace: %s\n", tmpString);
                    _ = fflush(null);
                }
            }
        }
    }
}
extern fn addItemToBuffer(item: u16) callconv(.c) void;
const addItemToBufferFn: ItemFn = &addItemToBuffer;

pub export fn nameAlias(op: u16, nameOp: [*c]u8) callconv(.c) void {
    if (comptime !ir_printing) return;
    var i: u16 = 0;
    while (NamesAlias[i].item != LAST_ITEM) {
        if (NamesAlias[i].item == op) {
            _ = strcpy(nameOp, &NamesAlias[i].name);
            return;
        }
        i += 1;
    }
    _ = strcpy(nameOp, &indexOfItems[op].itemCatalogName);
}

pub export fn printProgram(list: bool_t, lines: u16) callconv(.c) void {
    if (comptime !ir_printing) return;
    currentKeyCode = 255;
    var step: [*c]u8 = undefined;
    currentKeyCode = 255;
    if (!getSystemFlag(FLAG_PRTACT)) return; // RETURN_IF_PRINT_OFF
    advanceIfTrace();

    firstDisplayedLocalStepNumber = 0;
    if (!list) {
        defineFirstDisplayedStep();
        step = firstDisplayedStep;
    } else {
        step = currentStep;
    }
    programListEnd = false;
    lastProgramListEnd = false;

    print_lfImpl();

    var firstLine: u16 = undefined;
    var lastLine: u16 = undefined;

    if (!list) {
        if (getSystemFlag(FLAG_TRACE)) {
            printLineImpl(" ", 0);
        }
        getTimeString(tmpString);
        printLineImpl(tmpString, 0);
        printLineImpl(" ", 0);
        getDateString(tmpString);
        printLineImpl(tmpString, 1);
        print_lfImpl();

        if (firstDisplayedLocalStepNumber == 0) {
            if (getSystemFlag(FLAG_TRACE)) {
                printLineImpl(" ", 0);
            }
            _ = sprintf(tmpString, "00 { %u-Byte Prgm }", @as(c_uint, _getProgramSize()));
            printLineImpl(tmpString, 1);
            firstLine = 1;
        } else {
            firstLine = 0;
        }
        lastLine = 9999;
    } else {
        firstLine = currentLocalStepNumber;
        lastLine = firstLine + lines - 1;
    }

    const lineOffset: i32 = 0;
    const lineOffsetTam: i32 = 0;

    var isLabel: bool_t = undefined;
    var startOfLine: bool_t = true;

    var line: u16 = firstLine;
    while (line <= lastLine) : (line += 1) {
        const nextStep = findNextStep(step);
        isLabel = (step[0] == ITM_LBL);

        if (getSystemFlag(FLAG_TRACE)) {
            if (isLabel) {
                if ((line != 1) and !startOfLine) {
                    printAdvance(0);
                }
                printAdvance(0);
                _ = sprintf(tmpString, " %02d", @as(c_int, @intCast(@as(i32, firstDisplayedLocalStepNumber) + @as(i32, line) - lineOffset + lineOffsetTam)));
                _ = strcat(tmpString, STD_BLACK_RIGHT_TRIANGLE);
                printLineImpl(tmpString, 0);
            } else if (!startOfLine) {
                if (@as(c_int, printerColumn) + 14 <= PAPER_WIDTH) {
                    printLineImpl("  ", 0);
                } else {
                    printAdvance(0);
                }
            }
        } else {
            _ = sprintf(tmpString, "%02d", @as(c_int, @intCast(@as(i32, firstDisplayedLocalStepNumber) + @as(i32, line) - lineOffset + lineOffsetTam)));
            _ = strcat(tmpString, if (isLabel) STD_BLACK_RIGHT_TRIANGLE else " ");
            printLineImpl(tmpString, 0);
        }

        decodeOneStep_ALIAS(step);

        if (getSystemFlag(FLAG_TRACE)) {
            if (@as(c_int, printerColumn) + stringGlyphLength(tmpString) * 7 > PAPER_WIDTH + 2) {
                printAdvance(0);
            }
            printLineImpl(tmpString, @intFromBool(isLabel));
            startOfLine = isLabel;
        } else {
            printLineImpl(tmpString, 1);
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
        if (_exitKeyPressed()) {
            break;
        }
    }
    if (getSystemFlag(FLAG_TRACE)) {
        printAdvance(0);
    }
}

// ===========================================================================
// PRINTER FUNCTIONS.
//
// The command entry points fnP_PrinterOnOff / fnP_PrinterMode / fnSetPrinter /
// fnP_SetDelay / fnP_Advance / fnP_PrinterList / fnP_Byte / fnP_Char / fnP_Tab /
// fnP_LCD / fnP_User / fnP_Alpha / fnP_Sigma / fnP_All_Regs (and fnP_Regs /
// fnP_PrintAllItems) are owned by frontier.zig and the printer_control /
// print_register / print_all_regs / print_user / print_all_items owners, which
// already replicate those bodies. They are NOT exported here; this owner only
// provides the underlying printing engine and the helper shims those owners call.
// fnP_GetDelay was provided only by print.c, so it is kept here.
// ===========================================================================
pub export fn fnP_GetDelay(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (comptime ir_printing) {
        var delay: longInteger_t = undefined;
        liftStack();
        longIntegerInit(&delay[0]);
        @"__gmpz_set_si"(&delay[0], @intCast(getLineDelay()));
        convertLongIntegerToLongIntegerRegister(&delay[0], REGISTER_X);
        longIntegerFree(&delay[0]);
    }
}
extern fn liftStack() void;
extern fn convertLongIntegerToLongIntegerRegister(lgInt: *const mpz_struct, regist: calcRegister_t) void;

// fnP_Regs is owned elsewhere (renamed away in the bridge), so we do NOT define
// it here; it is externed above and used by _printRegRange.

const summationRegisterName = blk: {
    const SS = struct {
        fn row(comptime s: []const u8) summationRegisterName_t {
            var r = summationRegisterName_t{ .name = std.mem.zeroes([16]u8) };
            @memcpy(r.name[0..s.len], s);
            return r;
        }
    };
    // STD_SIGMA, STD_SUP_2/3/4, STD_DOT byte sequences (fonts.h).
    const SIG = "\x80\x85";
    const S2 = "\xa1\x62";
    const S3 = "\xa1\x63";
    const S4 = "\xa1\x64";
    const DOT = "\xa0\x09";
    break :blk [NUMBER_OF_STATISTICAL_SUMS]summationRegisterName_t{
        SS.row("n"),
        SS.row(SIG ++ "X"),
        SS.row(SIG ++ "Y"),
        SS.row(SIG ++ "X" ++ S2),
        SS.row(SIG ++ "X" ++ S2 ++ "Y"),
        SS.row(SIG ++ "Y" ++ S2),
        SS.row(SIG ++ "XY"),
        SS.row(SIG ++ "lnXlnY"),
        SS.row(SIG ++ "lnX"),
        SS.row(SIG ++ "ln" ++ S2 ++ "X"),
        SS.row(SIG ++ "Y" ++ DOT ++ "lnX"),
        SS.row(SIG ++ "lnY"),
        SS.row(SIG ++ "ln" ++ S2 ++ "Y"),
        SS.row(SIG ++ "X" ++ DOT ++ "lnY"),
        SS.row(SIG ++ "X" ++ S2 ++ "lnY"),
        SS.row(SIG ++ "lnY/X"),
        SS.row(SIG ++ "X" ++ S2 ++ "/Y"),
        SS.row(SIG ++ "1/X"),
        SS.row(SIG ++ "1/X" ++ S2),
        SS.row(SIG ++ "X/Y"),
        SS.row(SIG ++ "1/Y"),
        SS.row(SIG ++ "1/Y" ++ S2),
        SS.row(SIG ++ "X" ++ S3),
        SS.row(SIG ++ "X" ++ S4),
        SS.row(SIG ++ "Xmin"),
        SS.row(SIG ++ "Xmax"),
        SS.row(SIG ++ "Ymin"),
        SS.row(SIG ++ "Ymax"),
    };
};

// summationRegisterName is a TO_QSPI const array defined by print.c; export it.
comptime {
    @export(&summationRegisterName, .{ .name = "summationRegisterName", .linkage = .strong });
}

// fnP_PrintAllItems is owned elsewhere (renamed away in the bridge); extern only.

// ===========================================================================
// z47_frontier_* C-helper shims (were in the bridge tail). Always-on, both
// branches. On the IR-dead branch they reproduce the bridge's `#else` stubs.
// ===========================================================================
pub export fn z47_frontier_print_reg_range(first_register_no: u16, last_register_no: u16) callconv(.c) bool_t {
    if (comptime ir_printing) {
        return _printRegRange(first_register_no, last_register_no);
    }
    return false;
}

pub export fn z47_frontier_print_exit_pressed() callconv(.c) bool_t {
    if (comptime ir_printing) {
        return _exitKeyPressed();
    }
    return false;
}

pub export fn z47_frontier_current_number_of_local_registers() callconv(.c) u16 {
    return currentNumberOfLocalRegisters();
}

pub export fn z47_frontier_sigma_name(index: u16) callconv(.c) [*c]const u8 {
    return &summationRegisterName[index].name;
}

pub export fn z47_frontier_print_sigma_line(index: u16) callconv(.c) void {
    if (comptime ir_printing) {
        convertRealToResultRegister(statisticalSumsPointer + index, TEMP_REGISTER_1, amNone);
        printRegImpl(@bitCast(TEMP_REGISTER_1), &summationRegisterName[index].name, true, LINE_FULL, true);
    }
}

pub export fn z47_frontier_print_alpha_register(register_no: u16) callconv(.c) void {
    if (comptime ir_printing) {
        if (getRegisterDataType(@bitCast(register_no)) == dtString) {
            printAlphaImpl(regString(@bitCast(register_no)), PRINT_ALPHA);
        }
    }
}

pub export fn z47_frontier_print_set_printer_sbi(status: bool_t) callconv(.c) void {
    if (comptime ir_printing) {
        setPrinterSBI(status);
    }
}

pub export fn z47_frontier_print_get_unicode_value(regist: calcRegister_t) callconv(.c) u16 {
    if (comptime ir_printing) {
        return _getUnicodeValue(regist);
    }
    return 0;
}

pub export fn z47_frontier_x_real_matrix_rows() callconv(.c) u16 {
    var x: real34Matrix_t = undefined;
    convertReal34MatrixRegisterToReal34Matrix(REGISTER_X, &x);
    return x.header.matrixRows;
}

pub export fn z47_frontier_x_real_matrix_cols() callconv(.c) u16 {
    var x: real34Matrix_t = undefined;
    convertReal34MatrixRegisterToReal34Matrix(REGISTER_X, &x);
    return x.header.matrixColumns;
}

pub export fn z47_frontier_x_complex_matrix_rows() callconv(.c) u16 {
    var x: complex34Matrix_t = undefined;
    convertComplex34MatrixRegisterToComplex34Matrix(REGISTER_X, &x);
    return x.header.matrixRows;
}

pub export fn z47_frontier_x_complex_matrix_cols() callconv(.c) u16 {
    var x: complex34Matrix_t = undefined;
    convertComplex34MatrixRegisterToComplex34Matrix(REGISTER_X, &x);
    return x.header.matrixColumns;
}

pub export fn z47_frontier_x_real_matrix_element_to_temp1(index: u32) callconv(.c) void {
    var x: real34Matrix_t = undefined;
    convertReal34MatrixRegisterToReal34Matrix(REGISTER_X, &x);
    reallocateRegister(TEMP_REGISTER_1, dtReal34, @intCast(REAL34_SIZE_IN_BYTES), amNone);
    real34Copy(&x.matrixElements[index], reg34(TEMP_REGISTER_1));
}

pub export fn z47_frontier_x_complex_matrix_element_to_temp1(index: u32) callconv(.c) void {
    var x: complex34Matrix_t = undefined;
    convertComplex34MatrixRegisterToComplex34Matrix(REGISTER_X, &x);
    reallocateRegister(TEMP_REGISTER_1, dtComplex34, 0, amNone);
    complex34Copy(&x.matrixElements[index], reg34(TEMP_REGISTER_1));
}

pub export fn z47_frontier_named_variable_label(index: u16, buffer: [*c]u8, buffer_size: u16) callconv(.c) bool_t {
    if (index >= numberOfNamedVariables or buffer == null or buffer_size == 0) {
        return false;
    }
    var length: u16 = allNamedVariables[index].variableName[0];
    if (length >= buffer_size) {
        length = buffer_size - 1;
    }
    _ = xcopy(buffer, @as([*c]u8, &allNamedVariables[index].variableName) + 1, length);
    buffer[length] = 0;
    return true;
}

pub export fn z47_frontier_user_variable_should_skip(label: [*c]const u8) callconv(.c) bool_t {
    if (label == null) {
        return true;
    }
    return compareString(label, "STATS", CMP_NAME) == 0 or
        compareString(label, "HISTO", CMP_NAME) == 0 or
        compareString(label, "Mat_A", CMP_NAME) == 0 or
        compareString(label, "Mat_B", CMP_NAME) == 0 or
        compareString(label, "Mat_X", CMP_NAME) == 0;
}

pub export fn z47_frontier_find_named_variable_register(label: [*c]const u8) callconv(.c) calcRegister_t {
    return findNamedVariable(label);
}

pub export fn z47_frontier_program_begin() callconv(.c) [*c]u8 {
    return beginOfProgramMemory;
}

pub export fn z47_frontier_programs_end(step: [*c]u8) callconv(.c) bool_t {
    return isAtEndOfPrograms(step);
}

pub export fn z47_frontier_program_next_step(step: [*c]u8) callconv(.c) [*c]u8 {
    return findNextStep(step);
}

pub export fn z47_frontier_program_global_label(step: [*c]u8, label: [*c]u8, label_size: u16) callconv(.c) bool_t {
    if (step == null or label == null or label_size == 0) {
        return false;
    }
    if (!checkOpCodeOfStep(step, ITM_LBL)) {
        return false;
    }
    if (step[1] <= LAST_LOCAL_LABEL) {
        return false;
    }
    // Clamp to the program-memory end (upstream boundProgramNameLength) so a
    // corrupt step cannot read past program memory, then to the caller buffer.
    var length: u16 = boundProgramNameLength(step + 3, step[2]);
    if (length >= label_size) {
        length = label_size - 1;
    }
    _ = xcopy(label, step + 3, length);
    label[length] = 0;
    return true;
}

pub export fn z47_frontier_program_step_is_end(step: [*c]u8) callconv(.c) bool_t {
    return isAtEndOfProgram(step);
}

pub export fn z47_frontier_program_label_prefix() callconv(.c) [*c]const u8 {
    return "LBL " ++ STD_LEFT_SINGLE_QUOTE;
}

pub export fn z47_frontier_program_label_suffix() callconv(.c) [*c]const u8 {
    return STD_RIGHT_SINGLE_QUOTE;
}

pub export fn z47_frontier_print_program_counter(program_number: u16, total_programs: u16) callconv(.c) void {
    if (comptime ir_printing) {
        _ = sprintf(tmpString, "Prgm #%u/%u", @as(c_uint, program_number), @as(c_uint, total_programs));
        printJustifiedImpl(tmpString);
    }
}

pub export fn z47_frontier_format_register_label(register_no: u16, label: [*c]u8, label_size: u16) callconv(.c) void {
    if (label == null or label_size == 0) {
        return;
    }
    label[0] = 0;
    if (REGISTER_X <= register_no and register_no <= REGISTER_W) {
        label[0] = letteredRegisterName(@bitCast(register_no));
        label[1] = 0;
    } else if (register_no < REGISTER_X) {
        _ = snprintf(label, label_size, "R%02u", @as(c_uint, register_no));
    } else if (FIRST_LOCAL_REGISTER <= register_no and register_no <= LAST_LOCAL_REGISTER) {
        _ = snprintf(label, label_size, "R.%03u", @as(c_uint, register_no) - 100);
    } else if (FIRST_NAMED_VARIABLE <= register_no and register_no <= LAST_NAMED_VARIABLE) {
        _ = snprintf(label, label_size, "%s", @as([*c]u8, &allNamedVariables[register_no - FIRST_NAMED_VARIABLE].variableName) + 1);
    } else if (FIRST_NAMED_RESERVED_VARIABLE <= register_no and register_no <= LAST_RESERVED_VARIABLE) {
        _ = snprintf(label, label_size, "%s", @as([*c]const u8, &allReservedVariables[register_no - FIRST_RESERVED_VARIABLE].reservedVariableName) + 1);
    }
}

pub export fn z47_frontier_item_catalog_name(item: u16) callconv(.c) [*c]const u8 {
    return &indexOfItems[item].itemCatalogName;
}

pub export fn z47_frontier_item_softmenu_name(item: u16) callconv(.c) [*c]const u8 {
    return &indexOfItems[item].itemSoftmenuName;
}

pub export fn z47_frontier_last_item() callconv(.c) u16 {
    return LAST_ITEM;
}

pub export fn z47_frontier_print_backup_aim_message_area() callconv(.c) void {
    _ = xcopy(tmpString, aimBuffer, @intCast(ERROR_MESSAGE_LENGTH + AIM_BUFFER_LENGTH + NIM_BUFFER_LENGTH));
}

pub export fn z47_frontier_print_restore_aim_message_area() callconv(.c) void {
    _ = xcopy(aimBuffer, tmpString, @intCast(ERROR_MESSAGE_LENGTH + AIM_BUFFER_LENGTH + NIM_BUFFER_LENGTH));
}

// Reference otherwise-unused public symbols so they are emitted even when the
// optimizer cannot see a call (matches print.c keeping them link-live).
comptime {
    _ = &reverse;
    _ = &printLcd;
    _ = &setPrintMode;
    _ = &findlengths;
    _ = &printGlyph24;
    _ = &fnP_GetDelay;
    _ = &printTraceErrorFunction;
    _ = &printTraceError;
    _ = &printTraceX;
    _ = &printTraceString;
    _ = &printTraceTI;
    _ = &printInputPrompt;
    _ = &printViewAview;
    _ = &printTrace;
}
