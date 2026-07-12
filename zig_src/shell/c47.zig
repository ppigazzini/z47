// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/c47.c -- the GLOBALS HUB. Its first ~420 lines are the
// single definitions of the calculator's global variables/arrays that nearly
// every other owner and the remaining C shims `extern`. Byte-exactness is
// critical: a wrong type/size/order silently corrupts the calculator. Every
// global is defined here exactly ONCE with the EXACT C type, EXACT initializer
// and (for the TO_QSPI arrays) the right section. Then the public functions:
// convertKeyCode (always) and program_main (DMCP only).
//
// Struct sizes/alignments and the glyphNotFound / pcg32 init bytes were probed
// against the C build (realContext_t 28/4, subroutineLevels_t 4/2,
// subroutineLevelHeader_t 12/2, localFlags_t 4/4, font_t 8/8, glyph_t 24/8,
// printerState_t 16/4, tamState_t 26/2, normKey_t 20/2, calcKey_t 18/2,
// userMenuItem_t 20/2, programmableMenu_t 332/2, registerHeader_t 4/4,
// freeMemoryRegion_t 4/2, softmenuStack_t 8/2, pcg32_random_t 16/8,
// real_t 60/4, real34_t 16/4).

const builtin = @import("builtin");
const build_options = @import("frontier_build_options");
const dr = @import("distributions/distribution_runtime.zig");

const dmcp_build: bool = build_options.dmcp_build;
const old_hw: bool = build_options.old_hw;

// ---------------------------------------------------------------------------
// Compile-time constants (from defines.h / typeDefinitions.h, probed)
// ---------------------------------------------------------------------------
const NUMBER_OF_GLOBAL_REGISTERS = 137;
const MAX_FREE_REGIONS = 200;
const MAX_ALLOCATED_REGIONS = 5000;
const NUMBER_OF_CATALOGS = 23;
const NUMBER_OF_GLYPH_ROWS = 267; // defines.h: 267. Sizes the exported glyphRow[] global that C declares as glyphRow[NUMBER_OF_GLYPH_ROWS].
const SOFTMENU_STACK_SIZE = 8;
const DISPLAY_VALUE_LEN = 80;
const stateFileNameVarLength = 20;
const FILENAMELEN = 40;
const TIMER_APP_STOPPED: u32 = 0xFFFFFFFF;
const INVALID_VARIABLE: u16 = 2199;

const USER_R47: u8 = 66;
const USER_R47f_g: u8 = 61;
const USER_C47: u8 = 46;
// CALCMODEL is the per-build model selector (upstream's compile-time -DCALCMODEL).
// The host C47 sim + testSuite pass USER_C47 (46); the host R47 sim and the DMCP
// firmware pass USER_R47 (66). Seeding calcModel from it (below) is what makes the
// R47 sim's startup render isR47FAM()=true before c47-gtk.c re-sets calcModel.
const CALCMODEL: u8 = @import("frontier_build_options").calcmodel;

// ---------------------------------------------------------------------------
// Aggregate C-ABI type layouts, all aliased from abi (oracle-verified vs C)
// ---------------------------------------------------------------------------
const bool_t = bool; // C `bool`, 1 byte
const calcRegister_t = i16;
const angularMode_t = c_int;
const abi = @import("abi"); // shared ABI bindings
const keycode_remap = @import("input/keycode_remap.zig"); // std-only R47/WP43 key-code table
const real_t = abi.RealBlob; // decNumber, zero-init here
const real34_t = abi.Real34; // decQuad, zero-init here

const realContext_t = abi.RealContext; // size 28, align 4

const subroutineLevels_t = abi.SubroutineLevels; // size 4, align 2

// The C localFlags_t typedef is a bare uint32_t; abi centralizes it as such.
const localFlags_t = abi.LocalFlags;

const glyph_t = abi.Glyph;

const font_t = abi.Font;

const calcKey_t = abi.CalcKey; // size 18, align 2

const normKey_t = abi.NormKey;

const softmenuStack_t = abi.SoftmenuStack;

const userMenuItem_t = abi.UserMenuItem; // size 20, align 2

// programmableMenu_t (332 bytes, align 2) is centralized in abi as the typed
// layout {itemName[18][16], itemParam[21], unused}, oracle-verified == C. The
// prior opaque [332]u8 blob workaround is replaced by that exact-size type.
const ProgrammableMenuBlob = abi.ProgrammableMenu;

const tamState_t = abi.TamState;

const printerState_t = abi.PrinterState;

const registerHeader_t = abi.RegisterHeader; // size 4 align 4

const freeMemoryRegion_t = abi.FreeMemoryRegion; // size 4 align 2

const pcg32_random_t = abi.Pcg32Random; // size 16 align 8

// ---------------------------------------------------------------------------
// TO_QSPI pure-data tables -> code_section (.qspi dmcp&&old_hw / __TEXT,__text
// macos / .text else). These hold no pointers.
// ---------------------------------------------------------------------------
const code_section = dr.code_section;

pub export const baseDigits: [63]u8 linksection(code_section) =
    ("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz" ++ "\x00").*;
pub export const registerFlagLetters: [27]u8 linksection(code_section) =
    ("XYZTABCDLIJKMNPQRSEFGHOUVW" ++ "\x00").*;
pub export const KEY_X: [7]c_int linksection(code_section) =
    .{ -1, 66, 133, 200, 267, 333, 400 };

// ---------------------------------------------------------------------------
// Scalar / pointer / array global DEFINITIONS (lines ~20-373 of c47.c)
// ---------------------------------------------------------------------------
pub export var lastI: u16 = 0;
pub export var lastJ: u16 = 0;
pub export var lastFunc: i16 = 0;
pub export var lastParam: i16 = 0;
pub export var lastTemp: [16]u8 = undefined;

// PC_BUILD-only globals (host only).
comptime {
    if (!dmcp_build) {
        @export(&forceTamAlpha, .{ .name = "forceTamAlpha", .linkage = .strong });
        @export(&deadKey, .{ .name = "deadKey", .linkage = .strong });
        @export(&testDeadKeys, .{ .name = "testDeadKeys", .linkage = .strong });
        @export(&swapCtrlCode, .{ .name = "swapCtrlCode", .linkage = .strong });
    }
}
var forceTamAlpha: bool = false;
var deadKey: u32 = 0;
var testDeadKeys: bool_t = false;
var swapCtrlCode: bool_t = false;

pub export var fontForShortInteger: ?*const font_t = null;
pub export var cursorFont: ?*const font_t = null;
pub export var confirmedFunction: ?*const fn (u16) callconv(.c) void = null;

pub export var calcModel: u8 = if (CALCMODEL == USER_R47) USER_R47f_g else CALCMODEL;

// Variables stored in RAM
pub export var funcOK: bool_t = false;
pub export var keyActionProcessed: bool_t = false;
pub export var fnKeyInCatalog: bool_t = false;
pub export var hourGlassIconEnabled: bool_t = false;
pub export var watchIconEnabled: bool_t = false;
pub export var printerIconEnabled: bool_t = false;
pub export var serialIOIconEnabled: bool_t = false;
pub export var shiftF: bool_t = false;
pub export var shiftG: bool_t = false;
pub export var lastshiftF: bool_t = false;
pub export var lastshiftG: bool_t = false;
pub export var showContent: bool_t = false;
pub export var rbr1stDigit: bool_t = false;
pub export var updateDisplayValueX: bool_t = false;
pub export var thereIsSomethingToUndo: bool_t = false;
pub export var lastProgramListEnd: bool_t = false;
pub export var programListEnd: bool_t = false;
pub export var pemCursorIsZerothStep: bool_t = false;
pub export var secTick1: bool_t = false;
pub export var halfSecTick2: bool_t = false;
pub export var halfSecTick3: bool_t = false;
pub export var skippedStackLines: bool_t = false;
pub export var iterations: bool_t = false;
pub export var explicitTaylorIterVisibilitySelection: bool_t = false;

pub export var reDraw: bool_t = true;
pub export var refreshNIMdone: bool_t = false;
pub export var cleanupAfterShift: bool_t = false;
pub export var solverEstimatesUsed: bool_t = false;
pub export var updateOldConstants: bool_t = false;

pub export var ctxtReal4: realContext_t = std.mem.zeroes(realContext_t);
pub export var ctxtReal34: realContext_t = std.mem.zeroes(realContext_t);
pub export var ctxtReal39: realContext_t = std.mem.zeroes(realContext_t);
pub export var ctxtReal51: realContext_t = std.mem.zeroes(realContext_t);
pub export var ctxtReal75: realContext_t = std.mem.zeroes(realContext_t);

pub export var allSubroutineLevels: subroutineLevels_t = std.mem.zeroes(subroutineLevels_t);
pub export var currentSubroutineLevelData: ?*anyopaque = null;
pub export var statisticalSumsPointer: ?*real_t = null;
pub export var savedStatisticalSumsPointer: ?*real_t = null;
pub export var ram: ?[*]u32 = null;
pub export var currentLocalFlags: ?*localFlags_t = null;

pub export var allNamedVariables: ?*anyopaque = null;
pub export var softmenuStack: [SOFTMENU_STACK_SIZE]softmenuStack_t = std.mem.zeroes([SOFTMENU_STACK_SIZE]softmenuStack_t);
pub export var menuPageNumber: u16 = 0;
pub export var userMenuItems: [18]userMenuItem_t = std.mem.zeroes([18]userMenuItem_t);
pub export var userAlphaItems: [18]userMenuItem_t = std.mem.zeroes([18]userMenuItem_t);
pub export var userMenus: ?*anyopaque = null;
pub export var programmableMenu: ProgrammableMenuBlob = std.mem.zeroes(ProgrammableMenuBlob);
pub export var kbd_usr: [37]calcKey_t = std.mem.zeroes([37]calcKey_t);
pub export var errorMessageRegisterLine: calcRegister_t = 0;
pub export var glyphNotFound: glyph_t = .{
    .charCode = 0x0000,
    .colsBeforeGlyph = 0,
    .colsGlyph = 13,
    .colsAfterGlyph = 0,
    .rowsAboveGlyph = 0,
    .rowsGlyph = 19,
    .rowsBelowGlyph = 0,
    .rank1 = 0,
    .rank2 = 0,
    .data = null,
};

pub export var currentLocalRegisters: ?*registerHeader_t = null;

// dmcp+old_hw: globalRegister/freeMemoryRegions are static arrays here. Else
// they are NULL pointers (allocated elsewhere). allocatedMemoryRegions exists
// only on non-DMCP builds.
comptime {
    if (dmcp_build and old_hw) {
        @export(&globalRegister_arr, .{ .name = "globalRegister", .linkage = .strong });
        @export(&freeMemoryRegions_arr, .{ .name = "freeMemoryRegions", .linkage = .strong });
    } else {
        @export(&globalRegister_ptr, .{ .name = "globalRegister", .linkage = .strong });
        @export(&freeMemoryRegions_ptr, .{ .name = "freeMemoryRegions", .linkage = .strong });
    }
    if (!dmcp_build) {
        @export(&allocatedMemoryRegions, .{ .name = "allocatedMemoryRegions", .linkage = .strong });
        @export(&numberOfAllocatedMemoryRegions, .{ .name = "numberOfAllocatedMemoryRegions", .linkage = .strong });
    }
}
var globalRegister_arr: [NUMBER_OF_GLOBAL_REGISTERS]registerHeader_t = std.mem.zeroes([NUMBER_OF_GLOBAL_REGISTERS]registerHeader_t);
var freeMemoryRegions_arr: [MAX_FREE_REGIONS]freeMemoryRegion_t = std.mem.zeroes([MAX_FREE_REGIONS]freeMemoryRegion_t);
var globalRegister_ptr: ?*registerHeader_t = null;
var freeMemoryRegions_ptr: ?*freeMemoryRegion_t = null;
var allocatedMemoryRegions: [MAX_ALLOCATED_REGIONS]freeMemoryRegion_t = std.mem.zeroes([MAX_ALLOCATED_REGIONS]freeMemoryRegion_t);
var numberOfAllocatedMemoryRegions: i32 = 0;

pub export var pcg32_global: pcg32_random_t = .{ .state = 0x853c49e6748fea9b, .inc = 0xda3e39cb94b95bdb };
pub export var labelList: ?*anyopaque = null;
pub export var programList: ?*anyopaque = null;
pub export var currentAngularMode: angularMode_t = 0;
pub export var allFormulae: ?*anyopaque = null;

pub export var beginOfCurrentProgram: ?[*]u8 = null;
pub export var endOfCurrentProgram: ?[*]u8 = null;
pub export var firstDisplayedStep: ?[*]u8 = null;
pub export var currentStep: ?[*]u8 = null;

pub export var tmpString: ?[*]u8 = null;
pub export var tmpStringLabelOrVariableName: ?[*]u8 = null;
pub export var errorMessage: ?[*]u8 = null;
pub export var aimBuffer: ?[*]u8 = null;
pub export var nimBufferDisplay: ?[*]u8 = null;
pub export var tamBuffer: ?[*]u8 = null;
pub export var userKeyLabel: ?[*]u8 = null;
pub export var asmBuffer: [5]u8 = undefined;
pub export var oldTime: [8]u8 = undefined;
pub export var dateTimeString: [12]u8 = undefined;
pub export var displayValueX: [DISPLAY_VALUE_LEN]u8 = undefined;
pub export var gapItemLeft: u16 = 0;
pub export var gapItemRight: u16 = 0;
pub export var gapItemRadix: u16 = 0;
pub export var lastCenturyHighUsed: u16 = 0;

pub export var lcd_buffer: ?[*]u8 = null;
pub export var numScreensStandardFont: u8 = 0;
pub export var numScreensNumericFont: u8 = 0;
pub export var numScreensTinyFont: u8 = 0;
pub export var currentAsnScr: u8 = 0;
pub export var currentFntScr: u8 = 0;
pub export var currentFlgScr: u8 = 0;
pub export var lastFlgScr: u8 = 0;
pub export var displayFormat: u8 = 0;
pub export var displayFormatDigits: u8 = 0;
pub export var timeDisplayFormatDigits: u8 = 0;
pub export var shortIntegerWordSize: u8 = 0;
pub export var significantDigits: u8 = 0;
pub export var dispBase: u8 = 0;
pub export var fractionDigits: u8 = 0;
pub export var shortIntegerMode: u8 = 0;
pub export var previousCalcMode: u8 = 0;
pub export var grpGroupingLeft: u8 = 0;
pub export var grpGroupingGr1LeftOverflow: u8 = 0;
pub export var grpGroupingGr1Left: u8 = 0;
pub export var grpGroupingRight: u8 = 0;
pub export var roundingMode: u8 = 0;
pub export var calcMode: u8 = 0;
pub export var nextChar: u8 = 0;
pub export var displayStack: u8 = 0;
pub export var cachedDisplayStack: u8 = 0;
pub export var alphaCase: u8 = 0;
pub export var numLinesNumericFont: u8 = 0;
pub export var numLinesStandardFont: u8 = 0;
pub export var numLinesTinyFont: u8 = 0;
// New upstream (real master) globals: headless/--dumpMenus + test-load flags,
// bold numeric-font metrics, the alpha register and the 42S var-menu flag.
pub export var headlessMode: bool_t = false;
pub export var loadTestPrograms: bool_t = false;
pub export var loadTestData: bool_t = false;
pub export var numScreensNumericFontBold: u8 = 0;
pub export var numLinesNumericFontBold: u8 = 0;
pub export var alphaRegister: u16 = 0;
pub export var varMenu42: bool_t = false;
pub export var cursorEnabled: u8 = 0;
pub export var nimNumberPart: u8 = 0;
pub export var nimRealPart: u8 = 0;
pub export var hexDigits: u8 = 0;
pub export var lastErrorCode: u8 = 0;
pub export var previousErrorCode: u8 = 0;
pub export var temporaryInformation: u8 = 0;
pub export var rbrMode: u8 = 0;
pub export var timerCraAndDeciseconds: u8 = 128;
pub export var programRunStop: u8 = 0;
pub export var currentKeyCode: u8 = 0;
pub export var lastKeyCode: u8 = 0;
pub export var keyStateCode: u8 = 0;
pub export var entryStatus: u8 = 0;
pub export var screenUpdatingMode: u8 = 0;
pub export var beginOfProgramMemory: ?[*]u8 = null;
pub export var firstFreeProgramByte: ?[*]u8 = null;
pub export var statisticalSumsUpdate: bool_t = false;

pub export var tam: tamState_t = std.mem.zeroes(tamState_t);
pub export var currentRegisterBrowserScreen: i16 = 0;
pub export var lineTWidth: i16 = 0;
pub export var rbrRegister: i16 = 0;
pub export var catalog: i16 = 0;
pub export var lastCatalogPosition: [NUMBER_OF_CATALOGS]i16 = std.mem.zeroes([NUMBER_OF_CATALOGS]i16);
pub export var lastKeyItemDetermined: i16 = 0;
pub export var lastUserMode: bool_t = false;
pub export var lastItem: i16 = 0;
pub export var showFunctionNameItem: i16 = 0;
pub export var showFunctionNameArg: ?[*]u8 = null;

pub export var displayStackSHOIDISP: u8 = 0;
pub export var scrLock: u8 = 0;
pub export var doRefreshSoftMenu: bool_t = false;
pub export var IrFractionsCurrentStatus: u8 = 0;
pub export var tvmIKnown: bool_t = false;
pub export var tvmIChanges: bool_t = false;

pub export var Norm_Key_00: normKey_t = std.mem.zeroes(normKey_t);
pub export var Input_Default: u8 = 0;
pub export var DRG_Cycling: u8 = 0;
pub export var DM_Cycling: u8 = 0;
// INLINE_TEST never defined: testEnabled / testBitset skipped.
pub export var longpressDelayedkey2: i16 = 0;
pub export var longpressDelayedkey3: i16 = 0;
pub export var T_cursorPos: i16 = 0;
pub export var multiEdLines: u8 = 0;
pub export var yMultiLineEdOffset: u8 = 0;
pub export var xMultiLineEdOffset: u8 = 0;
pub export var current_cursor_x: u16 = 0;
pub export var current_cursor_y: u16 = 0;
pub export var alphaCursor: i16 = 0;
pub export var lastT_cursorPos: i16 = 0;
pub export var displayAIMbufferoffset: i16 = 0;
pub export var showRegis: u16 = 0;
pub export var overrideShowBottomLine: u8 = 0;
pub export var ListXYposition: i16 = 0;
pub export var JM_auto_doublepress_autodrop_enabled: i16 = 0;
pub export var JM_auto_longpress_enabled: i16 = 0;
pub export var JM_SHIFT_HOME_TIMER1: u8 = 0;
pub export var ULFL: bool_t = false;
pub export var ULGL: bool_t = false;
pub export var FN_key_pressed: i16 = 0;
pub export var FN_key_pressed_last: i16 = 0;
pub export var FN_timeouts_in_progress: bool_t = false;
pub export var Shft_timeouts: bool_t = false;
pub export var Shft_LongPress_f_g: bool_t = false;
pub export var FN_timed_out_to_NOP_or_Executed: bool_t = false;
pub export var FN_timed_out_to_RELEASE_EXEC: bool_t = false;
pub export var FN_handle_timed_out_to_EXEC: bool_t = false;
pub export var fnAsnDisplayUSER: bool_t = true;

pub export var bcdDisplaySign: u8 = 0;
pub export var LongPressM: u8 = 0;
pub export var LongPressF: u8 = 0;
pub export var last_CM: u8 = 255;
pub export var FN_state: u8 = 0;
pub export var editingLiteralType: u8 = 0;

pub export var exponentSignLocation: i16 = 0;
pub export var denominatorLocation: i16 = 0;
pub export var imaginaryExponentSignLocation: i16 = 0;
pub export var imaginaryMantissaSignLocation: i16 = 0;
pub export var imaginaryDenominatorLocation: i16 = 0;
pub export var exponentLimit: i16 = 0;
pub export var exponentHideLimit: i16 = 0;
pub export var showFunctionNameCounter: i16 = 0;
pub export var dynamicMenuItem: i16 = 0;
pub export var menu_RAM: ?[*]i16 = null;
pub export var numberOfTamMenusToPop: i16 = 0;
pub export var itemToBeAssigned: i16 = 0;
pub export var cachedDynamicMenu: i16 = 0;

pub export var globalFlags: [8]u16 = std.mem.zeroes([8]u16);
pub export var freeProgramBytes: u16 = 0;
pub export var glyphRow: [NUMBER_OF_GLYPH_ROWS]u16 = std.mem.zeroes([NUMBER_OF_GLYPH_ROWS]u16);
pub export var firstDisplayedLocalStepNumber: u16 = 0;
pub export var numberOfLabels: u16 = 0;
pub export var numberOfPrograms: u16 = 0;
pub export var numberOfNamedVariables: u16 = 0;
pub export var currentLocalStepNumber: u16 = 0;
pub export var currentProgramNumber: u16 = 0;
pub export var lrSelection: u16 = 0;
pub export var lrSelectionUndo: u16 = 0;
pub export var lrChosen: u16 = 0;
pub export var lrChosenUndo: u16 = 0;
pub export var lastPlotMode: u16 = 0;
pub export var plotSelection: u16 = 0;
pub export var currentViewRegister: u16 = 0;
pub export var currentSolverStatus: u16 = 0;
pub export var currentSolverProgram: u16 = 0;
pub export var currentSolverVariable: u16 = 0;
pub export var currentSolverNestingDepth: u16 = 0;
pub export var numberOfFormulae: u16 = 0;
pub export var currentFormula: u16 = 0;
pub export var numberOfUserMenus: u16 = 0;
pub export var currentUserMenu: u16 = 0;
pub export var userKeyLabelSize: u16 = 0;
pub export var currentInputVariable: u16 = INVALID_VARIABLE;
pub export var currentMvarLabel: u16 = INVALID_VARIABLE;
// REAL34_WIDTH_TEST == 0: largeur skipped.

pub export var numberOfFreeMemoryRegions: i32 = 0;

pub export var lgCatalogSelection: i32 = 0;
pub export var graphVariabl1: calcRegister_t = 0;

pub export var firstGregorianDay: u32 = 0;
pub export var denMax: u32 = 0;
pub export var lastDenominator: u32 = 4;
pub export var lastIntegerBase: u32 = 0;
pub export var decodedIntegerBase: u32 = 0;
pub export var xCursor: u32 = 0;
pub export var yCursor: u32 = 0;
pub export var tamOverPemYPos: u32 = 0;
pub export var timerValue: u32 = 0;
pub export var timerStartTime: u32 = TIMER_APP_STOPPED;
pub export var timerTotalTime: u32 = 0;
pub export var pointerOfFlashPgmLibrary: u32 = 0;
pub export var sizeOfFlashPgmLibrary: u32 = 0;

pub export var shortIntegerMask: u64 = 0;
pub export var shortIntegerSignBit: u64 = 0;
pub export var systemFlags0: u64 = 0;
pub export var systemFlags1: u64 = 0;
pub export var savedSystemFlags0: u64 = 0;
pub export var savedSystemFlags1: u64 = 0;

pub export var gmpMemInBytes: usize = 0;
pub export var c47MemInBlocks: usize = 0;

pub export var SAVED_SIGMA_LASTX: real_t = std.mem.zeroes(real_t);
pub export var SAVED_SIGMA_LASTY: real_t = std.mem.zeroes(real_t);
pub export var SAVED_SIGMA_lastAddRem: i8 = 0;

pub export var amortP1: u16 = 0;
pub export var amortP2: u16 = 0;

pub export var lrSelectionHistobackup: u16 = 0;
pub export var lrChosenHistobackup: u16 = 0;
pub export var histElementXorY: i16 = 0;
pub export var loBinR: real34_t = std.mem.zeroes(real34_t);
pub export var nBins: real34_t = std.mem.zeroes(real34_t);
pub export var hiBinR: real34_t = std.mem.zeroes(real34_t);
pub export var statMx: [8]u8 = std.mem.zeroes([8]u8);
pub export var plotStatMx: [8]u8 = std.mem.zeroes([8]u8);
pub export var regStatsXY: calcRegister_t = 0;

pub export var temporaryFlagRect: bool_t = false;
pub export var temporaryFlagPolar: bool_t = false;
pub export var vbatVIntegrated: c_int = 3000;
pub export var timeLastOp: u32 = 0;
pub export var timeLastOp0: u32 = 0;
pub export var timeLastOp1: u32 = 0;
pub export var lastStateFileOpened: [stateFileNameVarLength + 12]u8 = std.mem.zeroes([stateFileNameVarLength + 12]u8);
pub export var fileNameSelected: [stateFileNameVarLength]u8 = std.mem.zeroes([stateFileNameVarLength]u8);

pub export var filename_csv: [FILENAMELEN]u8 = std.mem.zeroes([FILENAMELEN]u8);
pub export var mem__32: u32 = 0;
pub export var cancelFilename: bool_t = false;

pub export var firstDayOfWeek: u8 = 1;
pub export var firstWeekOfYearDay: u8 = 4;

pub export var printerState: printerState_t = std.mem.zeroes(printerState_t);
pub export var printerColumn: u16 = 0;

const std = @import("std");

// ===========================================================================
// DMCP-only block (lines 376-1258 of c47.c are under `#if defined(DMCP_BUILD)`)
// ---------------------------------------------------------------------------
// convertKeyCode and program_main, plus the DMCP-only globals backToDMCP /
// nextTimerRefresh / nextScreenRefresh / wp43KbdLayout, exist only on firmware.
//
// The frontier Zig object is built ONCE and shared by the C47 and R47 firmware
// links, so the upstream `#if CALCMODEL == USER_R47` compile-time selection in
// convertKeyCode is reproduced as a RUNTIME branch on the calcModel global --
// matching the established pattern in the other ported owners (kbdStd, isR47FAM)
// and giving each firmware variant its correct mapping. calcModel boots to
// USER_C47 here and is overwritten at state load (saveRestoreCalcState.c).
const dmcp = struct {
    const USER_R47f_g_v: u8 = 61;
    const USER_R47bk_fg_v: u8 = 62;
    const USER_R47fg_bk_v: u8 = 63;
    const USER_R47fg_g_v: u8 = 64;

    fn isR47FAM() bool {
        return calcModel == USER_R47f_g_v or calcModel == USER_R47bk_fg_v or
            calcModel == USER_R47fg_bk_v or calcModel == USER_R47fg_g_v;
    }

    // DMCP-only globals.
    var backToDMCP: bool_t = false;
    var nextTimerRefresh: u32 = 0;
    var nextScreenRefresh: u32 = 0;
    var wp43KbdLayout: bool_t = false;

    // ---- DMCP SDK constants ----
    const LIBRARY_FN_BASE: usize = if (old_hw) 0x08000201 else 0x08000301;
    const SDB_ADDR: usize = if (old_hw) 0x10002000 else 0x20000000;
    // calc_state is the volatile u32 at offset 0 of sys_sdb_t.
    const calc_state_ptr: *volatile u32 = @ptrFromInt(SDB_ADDR);

    fn bit(comptime n: u5) u32 {
        return @as(u32, 1) << n;
    }
    const STAT_RUNNING = bit(1);
    const STAT_SUSPENDED = bit(2);
    const STAT_OFF = bit(4);
    const STAT_PGM_END = bit(9);
    const STAT_CLK_WKUP_ENABLE = bit(10);
    const STAT_CLK_WKUP_FLAG = bit(12);
    const STAT_POWER_CHANGE = bit(15);

    inline fn ST(x: u32) u32 {
        return calc_state_ptr.* & x;
    }
    inline fn SET_ST(x: u32) void {
        calc_state_ptr.* |= x;
    }
    inline fn CLR_ST(x: u32) void {
        calc_state_ptr.* &= ~x;
    }

    const SCREEN_REFRESH_PERIOD: u32 = if (dmcp_build) 160 else 100; // defines.h: 160 DMCP / 100 host
    const TIMER_IDX_REFRESH_SLEEP: c_int = 0;
    const TMR_RUNNING: u8 = 2;
    const PGM_RUNNING_v: u8 = 1;
    const SCRUPD_AUTO_v: u8 = 0x00;
    const FLAG_AUTXEQ: c_int = 0x801f;
    const ITM_RS: i16 = 1725;
    const SCREENDUMP_v: i16 = 9875;
    const CONFIRMED_v: u16 = 9877;
    const NOPARAM_v: u16 = 9876;
    const loadAutoSav: bool_t = true;

    // Timer slot ids (defines.h).
    const TO_FG_LONG: u8 = 0;
    const TO_CL_LONG: u8 = 1;
    const TO_FG_TIMR: u8 = 2;
    const TO_FN_LONG: u8 = 3;
    const TO_FN_EXEC: u8 = 4;
    const TO_3S_CTFF: u8 = 5;
    const TO_CL_DROP: u8 = 6;
    const TO_AUTO_REPEAT: u8 = 7;
    const TO_TIMER_APP: u8 = 8;
    const TO_ASM_ACTIVE: u8 = 9;
    const TO_KB_ACTV: u8 = 10;
    const TO_KB_ACTV_MEDIUM: u32 = 6000;
    const TO_KB_ACTV_CURSOR: u32 = 480;
    const TO_KB_ACTV_SHORT: u32 = 40;

    const BUFFER_SUCCESS: u8 = 1;

    // ---- ROM (LIBRARY_FN_BASE) trampolines ----
    fn rom(comptime T: type, comptime off: usize) T {
        return @ptrFromInt(LIBRARY_FN_BASE + off);
    }
    // offsets from dep/DMCP_SDK/dmcp/lft_ifc.h
    const lcd_line_addr = rom(*const fn (c_int) callconv(.c) [*c]u8, 40);
    const lcd_clear_buf = rom(*const fn () callconv(.c) void, 44);
    const lcd_refresh = rom(*const fn () callconv(.c) void, 48);
    const lcd_forced_refresh = rom(*const fn () callconv(.c) void, 52);
    const LCD_power_on = rom(*const fn () callconv(.c) void, 24);
    const LCD_power_off = rom(*const fn (c_int) callconv(.c) void, 28);
    const lcd_set_buf_cleared = rom(*const fn (c_int) callconv(.c) void, 84);
    const lcd_get_buf_cleared = rom(*const fn () callconv(.c) c_int, 88);
    const key_empty = rom(*const fn () callconv(.c) c_int, 380);
    const wait_for_key_release = rom(*const fn (c_int) callconv(.c) c_int, 420);
    const rtc_wakeup_delay = rom(*const fn () callconv(.c) void, 228);
    const sys_timer_disable = rom(*const fn (c_int) callconv(.c) void, 500);
    const sys_timer_start = rom(*const fn (c_int, u32) callconv(.c) void, 504);
    const sys_current_ms = rom(*const fn () callconv(.c) u32, 524);
    const sys_sleep = rom(*const fn () callconv(.c) void, 536);
    const draw_power_off_image = rom(*const fn (c_int) callconv(.c) void, 556);
    const lcd_refresh_dma = rom(*const fn () callconv(.c) void, 644);
    const lcd_refresh_wait = rom(*const fn () callconv(.c) void, 648);

    // ---- Runtime C symbols (resolved at firmware link) ----
    extern fn doFnReset(confirmation: u16, autoSav: bool_t) void;
    extern fn refreshScreen(source: u16) void;
    extern fn refreshLcd() void;
    extern fn refreshTimer() void;
    extern fn fnTimerReset() void;
    extern fn fnTimerConfig(nr: u8, func: *const fn (u16) callconv(.c) void, param: u16) void;
    extern fn fnTimerStart(nr: u8, param: u16, time: u32) void;
    extern fn fnTimerStop(nr: u8) void;
    extern fn fnTimerGetStatus(nr: u8) u8;
    extern fn fnTimerDummy1(param: u16) void;
    extern fn fnTimerEndOfActivity(param: u16) void;
    extern fn refreshFn(timerType: u16) void;
    extern fn execFnTimeout(key: u16) void;
    extern fn shiftCutoff(unusedButMandatoryParameter: u16) void;
    extern fn execAutoRepeat(key: u16) void;
    extern fn execTimerApp(timerType: u16) void;
    extern fn btnFnPressed(data: ?*anyopaque) void;
    extern fn btnFnReleased(data: ?*anyopaque) void;
    extern fn btnPressed(data: ?*anyopaque) void;
    extern fn btnReleased(data: ?*anyopaque) void;
    extern fn resetShiftState() void;
    extern fn resetKeytimers() void;
    extern fn dmcpResetAutoOff() void;
    extern fn runFunction(func: i16) void;
    extern fn standardScreenDump() void;
    extern fn fnSaveAuto(unusedButMandatoryParameter: u16) void;
    extern fn updateVbatIntegrated(minutePulse: bool_t) c_int;
    extern fn showHideUsbLowBattery() void;
    extern fn getSystemFlag(sf: i32) bool_t;
    extern fn clearSystemFlag(sf: c_uint) void;
    extern fn keyBuffer_pop() void;
    extern fn emptyKeyBuffer() bool_t;
    extern fn outKeyBuffer(pByte: *u8) u8;
    extern fn allocGmp(sizeInBytes: usize) ?*anyopaque;
    extern fn reallocGmp(p: ?*anyopaque, oldSize: usize, newSize: usize) ?*anyopaque;
    extern fn freeGmp(p: ?*anyopaque, sizeInBytes: usize) void;
    // gmp.h: `mp_set_memory_functions` is a macro for `__gmp_set_memory_functions`.
    extern fn __gmp_set_memory_functions(
        alloc_fn: *const fn (usize) callconv(.c) ?*anyopaque,
        realloc_fn: *const fn (?*anyopaque, usize, usize) callconv(.c) ?*anyopaque,
        free_fn: *const fn (?*anyopaque, usize) callconv(.c) void,
    ) void;
    const mp_set_memory_functions = __gmp_set_memory_functions;
    extern fn sprintf(buf: [*]u8, fmt: [*:0]const u8, ...) c_int;

    inline fn min(a: u32, b: u32) u32 {
        return if (a < b) a else b;
    }

    pub fn convertKeyCode(key_in: c_int) callconv(.c) c_int {
        return keycode_remap.remapKey(key_in, isR47FAM(), wp43KbdLayout);
    }

    pub fn program_main() callconv(.c) void {
        var key: c_int = 0;
        var charKey: [3]u8 = undefined;

        c47MemInBlocks = 0;
        gmpMemInBytes = 0;
        mp_set_memory_functions(allocGmp, reallocGmp, freeGmp);

        // initialize lcd_buffer mainly used in hal/lcd.c
        lcd_buffer = lcd_line_addr(0) - 2;
        lcd_clear_buf();
        doFnReset(CONFIRMED_v, loadAutoSav);
        refreshScreen(71);

        backToDMCP = false;

        lcd_forced_refresh();
        nextScreenRefresh = sys_current_ms() + SCREEN_REFRESH_PERIOD;

        fnTimerReset();
        fnTimerConfig(TO_FG_LONG, refreshFn, TO_FG_LONG);
        fnTimerConfig(TO_CL_LONG, refreshFn, TO_CL_LONG);
        fnTimerConfig(TO_FG_TIMR, refreshFn, TO_FG_TIMR);
        fnTimerConfig(TO_FN_LONG, refreshFn, TO_FN_LONG);
        fnTimerConfig(TO_FN_EXEC, execFnTimeout, 0);
        fnTimerConfig(TO_3S_CTFF, shiftCutoff, TO_3S_CTFF);
        fnTimerConfig(TO_CL_DROP, fnTimerDummy1, TO_CL_DROP);
        fnTimerConfig(TO_AUTO_REPEAT, execAutoRepeat, 0);
        fnTimerConfig(TO_TIMER_APP, execTimerApp, 0);
        fnTimerConfig(TO_ASM_ACTIVE, refreshFn, TO_ASM_ACTIVE);
        fnTimerConfig(TO_KB_ACTV, fnTimerEndOfActivity, TO_KB_ACTV);
        nextTimerRefresh = SCREEN_REFRESH_PERIOD;

        SET_ST(STAT_CLK_WKUP_ENABLE); // Enable wakeup each minute (for clock update)

        //** ** ** MAIN LOOP START ** ** **
        while (backToDMCP == false) {
            if (ST(STAT_PGM_END) != 0 and ST(STAT_SUSPENDED) != 0) { // Already off and suspended
                CLR_ST(STAT_RUNNING);
                sys_sleep();
            } else if (ST(STAT_PGM_END) == 0 and key_empty() != 0 and emptyKeyBuffer()) { // Just wait if no keys available.
                CLR_ST(STAT_RUNNING);

                if (nextTimerRefresh == 0) { // no timeout available
                    sys_sleep();
                } else { // timeout available
                    var timeoutTime: u32 = sys_current_ms();
                    if (nextTimerRefresh > timeoutTime) {
                        timeoutTime = nextTimerRefresh - timeoutTime;
                    } else {
                        timeoutTime = 1;
                    }

                    if (fnTimerGetStatus(TO_KB_ACTV) == TMR_RUNNING) {
                        timeoutTime = min(timeoutTime, 40);
                    }
                    if (fnTimerGetStatus(TO_FN_EXEC) == TMR_RUNNING) {
                        timeoutTime = min(timeoutTime, 15);
                    }
                    if (fnTimerGetStatus(TO_CL_DROP) == TMR_RUNNING or fnTimerGetStatus(TO_FN_LONG) == TMR_RUNNING or fnTimerGetStatus(TO_CL_LONG) == TMR_RUNNING) {
                        timeoutTime = min(timeoutTime, 10);
                    }

                    var sleepTime: u32 = SCREEN_REFRESH_PERIOD;
                    sleepTime = min(sleepTime, timeoutTime);
                    sys_timer_start(TIMER_IDX_REFRESH_SLEEP, @max(sleepTime, 1)); // wake up for screen refresh

                    sys_sleep();
                    sys_timer_disable(TIMER_IDX_REFRESH_SLEEP);
                }
            }

            // =======================
            // Externally forced LCD repaint
            if (ST(STAT_CLK_WKUP_FLAG) != 0) {
                if (ST(STAT_OFF) == 0 and (nextTimerRefresh == 0)) {
                    _ = updateVbatIntegrated(true);
                    refreshLcd();
                    lcd_refresh_wait();
                }
                CLR_ST(STAT_CLK_WKUP_FLAG);
                continue;
            }
            if (ST(STAT_POWER_CHANGE) != 0) {
                showHideUsbLowBattery();
                refreshLcd();
                lcd_refresh_wait();
                if (ST(STAT_OFF) == 0 and (fnTimerGetStatus(TO_KB_ACTV) != TMR_RUNNING)) {
                    fnTimerStart(TO_KB_ACTV, TO_KB_ACTV, 40);
                }
                CLR_ST(STAT_POWER_CHANGE);
                continue;
            }

            // Wakeup in off state or going to sleep
            if (ST(STAT_PGM_END) != 0 or ST(STAT_SUSPENDED) != 0) {
                if (ST(STAT_SUSPENDED) == 0) {
                    // Going to off mode
                    lcd_set_buf_cleared(0); // Mark no buffer change region
                    draw_power_off_image(1);

                    LCD_power_off(0);
                    SET_ST(STAT_SUSPENDED);
                    SET_ST(STAT_OFF);
                }
                // Already in OFF -> just continue to sleep above
                continue;
            }

            // Well, we are woken-up
            SET_ST(STAT_RUNNING);

            // Clear suspended state, because now we are definitely reached the active state
            CLR_ST(STAT_SUSPENDED);

            // Get up from OFF state
            if (ST(STAT_OFF) != 0) {
                LCD_power_on();
                rtc_wakeup_delay(); // Ensure that RTC readings after power off will be OK

                CLR_ST(STAT_OFF);

                if (lcd_get_buf_cleared() == 0) {
                    lcd_forced_refresh(); // Just redraw from LCD buffer
                }

                if (getSystemFlag(FLAG_AUTXEQ)) { // Run the program if AUTXEQ is set
                    clearSystemFlag(@intCast(FLAG_AUTXEQ));
                    if (programRunStop != PGM_RUNNING_v) {
                        screenUpdatingMode = SCRUPD_AUTO_v;
                        runFunction(ITM_RS);
                    }
                    refreshScreen(72);
                }
            }

            dmcpResetAutoOff();

            var outKey: u8 = undefined;
            keyBuffer_pop();

            if (outKeyBuffer(&outKey) == BUFFER_SUCCESS) {
                key = outKey;
            } else {
                key = -1;
            }

            if (key == 44) { // DISP for special SCREEN DUMP key code.
                standardScreenDump();
                _ = wait_for_key_release(0);
                charKey[0] = 0;
                charKey[1] = 0;
                resetShiftState();
                resetKeytimers();
                CLR_ST(bit(3)); // STAT_KEYUP_WAIT
                dmcpResetAutoOff();
                key = -1;

                keyBuffer_pop();
                var outKey2: u8 = undefined;
                while (!emptyKeyBuffer()) {
                    _ = outKeyBuffer(&outKey2);
                }
                lastItem = SCREENDUMP_v;
            }

            if (38 <= key and key <= 43) { // Function key
                abi.fmtBufZ(&charKey, "{c}", .{@as(u8, @intCast(key + 11))});
                btnFnPressed(&charKey);
            } else if (1 <= key and key <= 37) { // Not a function key
                abi.fmtBufZ(&charKey, "{d:0>2}", .{@as(u32, @intCast(key - 1))});
                btnPressed(&charKey);
            } else if (key == 0 and charKey[1] == 0) {
                btnFnReleased(&charKey);
            } else if (key == 0) {
                btnReleased(&charKey);
                // Faithful to upstream: compares the RUNTIME calcModel to the
                // raw USER_C47 / USER_R47 enumerators (c47.c lines 1191-1193).
                if (calcMode == CM_PEM_v and shiftF != false and ((calcModel == USER_C47_v and ((charKey[0] == '1' and charKey[1] == '7') or (charKey[0] == '2' and charKey[1] == '2'))) or (calcModel == USER_R47_v and ((charKey[0] == '2' and charKey[1] == '2') or (charKey[0] == '2' and charKey[1] == '7'))))) {
                    shiftF = false;
                    refreshScreen(74);
                }
            }

            if (key >= 0) {
                lcd_refresh_dma();
                if (key > 0) {
                    fnTimerStart(TO_KB_ACTV, TO_KB_ACTV, TO_KB_ACTV_MEDIUM); // Key pressed
                } else if (cursorEnabled == 1) {
                    fnTimerStart(TO_KB_ACTV, TO_KB_ACTV, TO_KB_ACTV_CURSOR);
                } else {
                    fnTimerStart(TO_KB_ACTV, TO_KB_ACTV, if (skippedStackLines != false) TO_KB_ACTV_MEDIUM / 5 else TO_KB_ACTV_SHORT); // Key released
                }
            }

            var now: u32 = sys_current_ms();

            if (nextTimerRefresh != 0 and nextTimerRefresh <= now) {
                refreshTimer(); // Executes pending timer jobs
            }
            now = sys_current_ms();
            if (nextScreenRefresh <= now) {
                nextScreenRefresh += SCREEN_REFRESH_PERIOD;
                if (nextScreenRefresh < now) {
                    nextScreenRefresh = now + SCREEN_REFRESH_PERIOD; // we were out longer than expected; just skip ahead.
                }
                if ((calcMode != CM_TIMER_v) or (fnTimerGetStatus(TO_TIMER_APP) != TMR_RUNNING)) {
                    refreshLcd();
                    if (key >= 0) {
                        lcd_refresh();
                    } else {
                        lcd_refresh_wait();
                    }
                }
            }
        }
        fnSaveAuto(NOPARAM_v);
    }

    const CM_PEM_v: u8 = 3;
    const CM_TIMER_v: u8 = 14;
    const USER_C47_v: u8 = 46;
    const USER_R47_v: u8 = 66;
};

comptime {
    if (dmcp_build) {
        @export(&dmcp.convertKeyCode, .{ .name = "convertKeyCode", .linkage = .strong });
        @export(&dmcp.program_main, .{ .name = "program_main", .linkage = .strong });
        @export(&dmcp.backToDMCP, .{ .name = "backToDMCP", .linkage = .strong });
        @export(&dmcp.nextTimerRefresh, .{ .name = "nextTimerRefresh", .linkage = .strong });
        @export(&dmcp.nextScreenRefresh, .{ .name = "nextScreenRefresh", .linkage = .strong });
        @export(&dmcp.wp43KbdLayout, .{ .name = "wp43KbdLayout", .linkage = .strong });
    }
}
