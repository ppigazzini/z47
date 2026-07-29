// SAVE side of the backup.cfg raw RAM dump (saveRestoreCalcState.c saveCalc,
// ~403-731). Generated faithful port: drives the ~200-field dump sequence in Zig,
// calling the Zig typed value serializer (saveStateValue, below) + the progmem
// pointer math. Verified by the parity harness Check C (Zig saveCalc -> C
// restoreCalc -> state preserved).

const abi = @import("abi");
const std = @import("std");
const progmem = @import("calc_state_progmem.zig");
const build_options = @import("calc_state_build_options");
const calc_state = @import("calc_state.zig");
const state_old_hw = @hasDecl(build_options, "state_old_hw") and build_options.state_old_hw;
const calc_model_user_id: u16 = if (@hasDecl(build_options, "calc_model_user_id")) build_options.calc_model_user_id else 46;

const FILE_OK: c_int = 1;
const ioPathBackup: c_int = 4;
const ioModeWrite: c_int = 1;
const BACKUP_VERSION: u32 = 1016; // C saveRestoreBackup.c:14 (graph range defaults float -> real)
const INVALID_VARIABLE: i16 = 2199;
const CM_CONFIRMATION: u8 = 11;
const USER_C47: u16 = 46;
const USER_DM42: u16 = 45;
const USER_R47: u16 = 66;
const USER_R47f_g: u16 = 61;
const USER_R47fg_g: u16 = 64;
const USER_R47fg_bk: u16 = 63;
const USER_R47bk_fg: u16 = 62;
const FREE_MEM_REGION_SIZE: u32 = 4;
const REGISTER_HEADER_SIZE: u32 = 4;
const NUMBER_OF_GLOBAL_REGISTERS: u32 = 137;

const Font = opaque {};
extern const tinyFont: Font;
extern const standardFont: Font;
extern const numericFont: Font;
extern var cursorFont: ?*const Font;
fn cursorFontId() i8 {
    if (cursorFont == &tinyFont) return 1;
    if (cursorFont == &standardFont) return 2;
    if (cursorFont == &numericFont) return 3;
    return -1;
}
extern fn strcpy(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strcat(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strlen(s: [*c]const u8) usize;
extern fn strcmp(a: [*c]const u8, b: [*c]const u8) c_int;
extern fn strchr(s: [*c]const u8, c: c_int) [*c]u8;
extern fn ioFileWrite(buffer: ?*const anyopaque, size: u32) void;
extern fn decNumberToString(src: [*c]const u8, dst: [*c]u8) [*c]u8; // realToString
extern fn decQuadToString(src: [*c]const u8, dst: [*c]u8) [*c]u8; // real34ToString
extern fn decQuadIsInfinite(src: [*c]const u8) u32; // real34IsInfinite
const DECINF: u8 = 0x40; // decNumberIsInfinite(dn) = (dn->bits & DECINF) != 0; bits@8
const real_t = opaque {}; // decNumber; range globals hold a *real_t (see graphs.zig)
// REAL_SIZE_IN_BYTES(34) = 10 + sizeof(decNumberUnit=2) * (REAL_MAX_DIGITS(34)=39 / DECDPUN=3) = 36.
const REAL_SIZE_IN_BYTES_34: u32 = 36; // C realType.h REAL_SIZE_IN_BYTES(34)
extern fn ioFileOpen(path: c_int, mode: c_int) c_int;
extern fn ioFileClose() void;
const refreshScreen = abi.host.requestRefresh; // routed through the host-callback boundary
extern var calcModel: u8;
extern var calcMode: u8;
extern var previousCalcMode: u8;
extern var graphVariabl1: i16;
extern var freeMemoryRegions: ?*anyopaque; // pointer on host (NEW_HW)
extern var allocatedMemoryRegions: [4]u8; // array on host (!DMCP_BUILD) -> &[0]
extern var numberOfFreeMemoryRegions: i32;
extern var numberOfAllocatedMemoryRegions: i32;
extern var globalRegister: ?*anyopaque; // pointer on host (NEW_HW)
extern var ram: [*c]u32;
extern var globalFlags: [16]u8;
// These four are `char *` POINTERS in c47.h (errorMessage/aimBuffer/nimBufferDisplay/
// tamBuffer), not arrays. They must be declared as pointers so that `&X[0]` in the
// sv()/rv() calls resolves to the pointer VALUE (the heap buffer C dumps/restores),
// exactly as C passes the bare pointer. Declaring them as `[N]u8` arrays made `&X[0]`
// the address of the pointer slot itself, so a 512-byte errorMessage restore wrote
// across adjacent globals (incl. labelList) and crashed startup. asmBuffer stays an
// array because c47.h declares `char asmBuffer[5]`.
extern var errorMessage: [*c]u8;
extern var aimBuffer: [*c]u8;
extern var nimBufferDisplay: [*c]u8;
extern var tamBuffer: [*c]u8;
extern var asmBuffer: [5]u8;
extern var oldTime: [8]u8;
extern var dateTimeString: [12]u8;
extern var softmenuStack: [64]u8;
extern var kbd_usr: [666]u8;
extern var userMenuItems: [360]u8;
extern var userAlphaItems: [360]u8;
extern var lastTemp: [16]u8;
extern var lastStateFileOpened: [32]u8;
extern var lastI: [2]u8;
extern var lastJ: [2]u8;
extern var lastFunc: [2]u8;
extern var lastParam: [2]u8;
extern var tam: [64]u8;
extern var rbrRegister: [2]u8;
extern var numberOfNamedVariables: [2]u8;
extern var xCursor: [4]u8;
extern var yCursor: [4]u8;
extern var firstGregorianDay: [4]u8;
extern var denMax: [4]u8;
extern var lastDenominator: [4]u8;
extern var currentRegisterBrowserScreen: [2]u8;
extern var currentFntScr: [1]u8;
extern var currentFlgScr: [1]u8;
extern var displayFormat: [1]u8;
extern var displayFormatDigits: [1]u8;
extern var timeDisplayFormatDigits: [1]u8;
extern var shortIntegerWordSize: [1]u8;
extern fn boundShortIntegerWordSize(word_size: u8) callconv(.c) u8;
extern fn updateShortIntegerMasks() callconv(.c) void;
extern var significantDigits: [1]u8;
extern var fractionDigits: [1]u8;
extern var shortIntegerMode: [1]u8;
extern var currentAngularMode: [4]u8;
extern var scrLock: [1]u8;
extern var roundingMode: [1]u8;
extern var nextChar: [1]u8;
extern var alphaCase: [1]u8;
extern var hourGlassIconEnabled: [1]u8;
extern var watchIconEnabled: [1]u8;
extern var serialIOIconEnabled: [1]u8;
extern var printerIconEnabled: [1]u8;
extern var programRunStop: [1]u8;
extern var entryStatus: [1]u8;
extern var cursorEnabled: [1]u8;
extern var rbr1stDigit: [1]u8;
extern var shiftF: [1]u8;
extern var shiftG: [1]u8;
extern var rbrMode: [1]u8;
extern var showContent: [1]u8;
extern var numScreensNumericFont: [1]u8;
extern var numLinesNumericFont: [1]u8;
extern var numScreensStandardFont: [1]u8;
extern var numLinesStandardFont: [1]u8;
extern var numScreensTinyFont: [1]u8;
extern var numLinesTinyFont: [1]u8;
extern var lastErrorCode: [1]u8;
extern var previousErrorCode: [1]u8;
extern var nimNumberPart: [1]u8;
extern var displayStack: [1]u8;
extern var hexDigits: [1]u8;
extern var errorMessageRegisterLine: [2]u8;
extern var shortIntegerMask: [8]u8;
extern var shortIntegerSignBit: [8]u8;
extern var temporaryInformation: [1]u8;
extern var funcOK: [1]u8;
extern var screenChange: [1]u8;
extern var exponentSignLocation: [2]u8;
extern var denominatorLocation: [2]u8;
extern var imaginaryExponentSignLocation: [2]u8;
extern var imaginaryMantissaSignLocation: [2]u8;
extern var lineTWidth: [2]u8;
extern var lastIntegerBase: [4]u8;
extern var c47MemInBlocks: [8]u8;
extern var gmpMemInBytes: [8]u8;
extern var catalog: [2]u8;
extern var lastCatalogPosition: [46]u8;
extern var displayValueX: [80]u8;
extern var pcg32_global: [16]u8;
extern var exponentLimit: [2]u8;
extern var exponentHideLimit: [2]u8;
extern var keyActionProcessed: [1]u8;
extern var systemFlags0: [8]u8;
extern var systemFlags1: [8]u8;
extern var savedSystemFlags0: [8]u8;
extern var savedSystemFlags1: [8]u8;
extern var thereIsSomethingToUndo: [1]u8;
extern var freeProgramBytes: [2]u8;
extern var firstDisplayedLocalStepNumber: [2]u8;
extern var numberOfLabels: [2]u8;
extern var numberOfPrograms: [2]u8;
extern var currentLocalStepNumber: [2]u8;
extern var currentProgramNumber: [2]u8;
extern var lastProgramListEnd: [1]u8;
extern var programListEnd: [1]u8;
extern var allSubroutineLevels: [4]u8;
extern var pemCursorIsZerothStep: [1]u8;
extern var skippedStackLines: [1]u8;
extern var iterations: [1]u8;
extern var numberOfTamMenusToPop: [2]u8;
extern var lrSelection: [2]u8;
extern var lrSelectionUndo: [2]u8;
extern var amortP1: [2]u8;
extern var amortP2: [2]u8;
extern var lrChosen: [2]u8;
extern var lrChosenUndo: [2]u8;
extern var lastPlotMode: [2]u8;
extern var plotSelection: [2]u8;
extern var graph_dx: [4]u8;
extern var graph_dy: [4]u8;
extern var roundedTicks: [1]u8;
extern var PLOT_AXIS: [1]u8;
extern var PLOT_ZMY: [1]u8;
extern var PLOT_ZOOM: [1]u8;
extern var plotmode: [1]u8;
extern var tick_int_x: [4]u8;
extern var tick_int_y: [4]u8;
// Graph range globals are now pointers to a real_t (34-digit decNumber) buffer,
// matching c43's REAL_T_PTR(x_min, 34) in graphs.c. Use the pointer directly (no &).
extern var x_min: *real_t;
extern var x_max: *real_t;
extern var y_min: *real_t;
extern var y_max: *real_t;
extern var xzero: [4]u8;
extern var yzero: [4]u8;
extern var regStatsXY: [2]u8;
extern var matrixIndex: [2]u8;
extern var shadowI: [2]u8;
extern var shadowJ: [2]u8;
extern var currentViewRegister: [2]u8;
extern var currentSolverStatus: [2]u8;
extern var currentSolverProgram: [2]u8;
extern var currentSolverVariable: [2]u8;
extern var numberOfFormulae: [2]u8;
extern var currentFormula: [2]u8;
extern var numberOfUserMenus: [2]u8;
extern var currentUserMenu: [2]u8;
extern var userKeyLabelSize: [2]u8;
extern var timerCraAndDeciseconds: [1]u8;
extern var timerValue: [4]u8;
extern var timerTotalTime: [4]u8;
extern var currentInputVariable: [2]u8;
extern var SAVED_SIGMA_LASTX: [60]u8;
extern var SAVED_SIGMA_LASTY: [60]u8;
extern var SAVED_SIGMA_lastAddRem: [1]u8;
extern var currentMvarLabel: [2]u8;
extern var plotStatMx: [8]u8;
extern var drawHistogram: [1]u8;
extern var plotStatScale: [1]u8;
extern var statMx: [8]u8;
extern var lrSelectionHistobackup: [2]u8;
extern var lrChosenHistobackup: [2]u8;
extern var loBinR: [16]u8;
extern var nBins: [16]u8;
extern var hiBinR: [16]u8;
extern var histElementXorY: [2]u8;
extern var screenUpdatingMode: [1]u8;
extern var Norm_Key_00: [64]u8;
extern var Input_Default: [1]u8;
extern var T_cursorPos: [2]u8;
extern var multiEdLines: [1]u8;
extern var current_cursor_x: [2]u8;
extern var current_cursor_y: [2]u8;
extern var xMultiLineEdOffset: [1]u8;
extern var yMultiLineEdOffset: [1]u8;
extern var showRegis: [2]u8;
extern var overrideShowBottomLine: [1]u8;
extern var displayStackSHOIDISP: [1]u8;
extern var ListXYposition: [2]u8;
extern var DRG_Cycling: [1]u8;
extern var lastFlgScr: [1]u8;
extern var displayAIMbufferoffset: [2]u8;
extern var bcdDisplaySign: [1]u8;
extern var DM_Cycling: [1]u8;
extern var LongPressM: [1]u8;
extern var LongPressF: [1]u8;
extern var currentAsnScr: [1]u8;
extern var gapItemLeft: [2]u8;
extern var gapItemRight: [2]u8;
extern var gapItemRadix: [2]u8;
extern var lastCenturyHighUsed: [2]u8;
extern var grpGroupingLeft: [1]u8;
extern var grpGroupingGr1LeftOverflow: [1]u8;
extern var grpGroupingGr1Left: [1]u8;
extern var grpGroupingRight: [1]u8;
extern var firstDayOfWeek: [1]u8;
extern var firstWeekOfYearDay: [1]u8;
extern var dispBase: [1]u8;
extern var printerState: [64]u8;
extern var allNamedVariables: [*c]u8;
extern var allFormulae: [*c]u8;
extern var userMenus: [*c]u8;
extern var userKeyLabel: [*c]u8;
extern var statisticalSumsPointer: [*c]u8;
extern var savedStatisticalSumsPointer: [*c]u8;
extern var labelList: [*c]u8;
extern var programList: [*c]u8;
extern var currentSubroutineLevelData: [*c]u8;
extern var currentLocalFlags: [*c]u8;
extern var currentLocalRegisters: [*c]u8;
extern var beginOfProgramMemory: [*c]u8;
extern var firstFreeProgramByte: [*c]u8;
extern var firstDisplayedStep: [*c]u8;
extern var currentStep: [*c]u8;

fn geometry() progmem.Geometry {
    return .{ .ram_base = @intFromPtr(ram), .ram_size_in_blocks = if (state_old_hw) progmem.RAM_SIZE_IN_BLOCKS_OLD_HW else progmem.RAM_SIZE_IN_BLOCKS_NEW_HW, .old_hw = state_old_hw };
}
fn streq(a: [*c]const u8, b: [*c]const u8) bool {
    return strcmp(a, b) == 0;
}
fn rd(comptime T: type, buffer: ?*const anyopaque) T {
    return @as(*const T, @ptrCast(@alignCast(buffer))).*;
}
fn save(bytes: [*c]const u8) void {
    ioFileWrite(bytes, @intCast(strlen(bytes)));
}
// Replace ',' with '.' after the second ':' (locale-independent floats).
fn changeCommaToPeriod(str: [*c]u8) void {
    var s = strchr(str, ':') + 1;
    s = strchr(s, ':') + 1;
    while (s[0] != 0) : (s += 1) {
        if (s[0] == ',') s[0] = '.';
    }
}

// Typed value serializer (saveRestoreCalcState.c saveStateValue, host-only).
fn sv(buffer: ?*const anyopaque, size: u32, name: [*c]const u8, type_str: [*c]const u8) void {
    var value: [200]u8 = undefined;
    const v: [*c]u8 = &value[0];
    const buf: [*c]const u8 = @ptrCast(buffer);
    if (streq(type_str, "int64")) {
        // C uses PRIi64/PRIu64: the full 64-bit value on every platform. Casting
        // to c_long/c_ulong truncates (and @intCast-panics on overflow) on Windows
        // LLP64 where long is 32-bit, so pass the native i64/u64 straight through.
        abi.fmtCStr(v, "{s}:{s}:{d}\n", .{ @as([*:0]const u8, name), @as([*:0]const u8, type_str), rd(i64, buffer) });
        save(v);
    } else if (streq(type_str, "uint64")) {
        abi.fmtCStr(v, "{s}:{s}:{d}\n", .{ @as([*:0]const u8, name), @as([*:0]const u8, type_str), rd(u64, buffer) });
        save(v);
    } else if (streq(type_str, "int32")) {
        abi.fmtCStr(v, "{s}:{s}:{d}\n", .{ @as([*:0]const u8, name), @as([*:0]const u8, type_str), @as(c_int, rd(i32, buffer)) });
        save(v);
    } else if (streq(type_str, "uint32")) {
        abi.fmtCStr(v, "{s}:{s}:{d}\n", .{ @as([*:0]const u8, name), @as([*:0]const u8, type_str), @as(c_uint, rd(u32, buffer)) });
        save(v);
    } else if (streq(type_str, "int16")) {
        abi.fmtCStr(v, "{s}:{s}:{d}\n", .{ @as([*:0]const u8, name), @as([*:0]const u8, type_str), @as(c_int, rd(i16, buffer)) });
        save(v);
    } else if (streq(type_str, "uint16")) {
        abi.fmtCStr(v, "{s}:{s}:{d}\n", .{ @as([*:0]const u8, name), @as([*:0]const u8, type_str), @as(c_uint, rd(u16, buffer)) });
        save(v);
    } else if (streq(type_str, "int8")) {
        abi.fmtCStr(v, "{s}:{s}:{d}\n", .{ @as([*:0]const u8, name), @as([*:0]const u8, type_str), @as(c_int, rd(i8, buffer)) });
        save(v);
    } else if (streq(type_str, "uint8")) {
        abi.fmtCStr(v, "{s}:{s}:{d}\n", .{ @as([*:0]const u8, name), @as([*:0]const u8, type_str), @as(c_uint, rd(u8, buffer)) });
        save(v);
    } else if (streq(type_str, "float")) {
        var fb: [64]u8 = undefined;
        abi.fmtCStr(v, "{s}:{s}:{s}\n", .{ @as([*:0]const u8, name), @as([*:0]const u8, type_str), abi.fmtExpBuf(&fb, 20, @as(f64, rd(f32, buffer))) });
        changeCommaToPeriod(v);
        save(v);
    } else if (streq(type_str, "double")) {
        var fb: [64]u8 = undefined;
        abi.fmtCStr(v, "{s}:{s}:{s}\n", .{ @as([*:0]const u8, name), @as([*:0]const u8, type_str), abi.fmtExpBuf(&fb, 20, rd(f64, buffer)) });
        changeCommaToPeriod(v);
        save(v);
    } else if (streq(type_str, "real")) {
        abi.fmtCStr(v, "{s}:{s}:", .{ @as([*:0]const u8, name), @as([*:0]const u8, type_str) });
        if (buf[8] & DECINF != 0) {
            _ = strcpy(v + strlen(v), if (buf[8] & 0x80 != 0) "-9.9e9999999" else "9.9e9999999");
        } else {
            _ = decNumberToString(buf, v + strlen(v));
        }
        _ = strcat(v, "\n");
        changeCommaToPeriod(v);
        save(v);
    } else if (streq(type_str, "real34")) {
        abi.fmtCStr(v, "{s}:{s}:", .{ @as([*:0]const u8, name), @as([*:0]const u8, type_str) });
        if (decQuadIsInfinite(buf) != 0) {
            _ = strcpy(v + strlen(v), if (buf[15] & 0x80 != 0) "-9.9e9999" else "9.9e9999");
        } else {
            _ = decQuadToString(buf, v + strlen(v));
        }
        _ = strcat(v, "\n");
        changeCommaToPeriod(v);
        save(v);
    } else if (streq(type_str, "bool")) {
        abi.fmtCStr(v, "{s}:{s}:{d}\n", .{ @as([*:0]const u8, name), @as([*:0]const u8, type_str), @as(c_uint, rd(u8, buffer)) });
        save(v);
    } else if (streq(type_str, "c47Ptr")) {
        const p = rd(u32, buffer);
        abi.fmtCStr(v, "{s}:{s}:{d} (0x{x:0>5})\n", .{ @as([*:0]const u8, name), @as([*:0]const u8, type_str), @as(c_uint, p), @as(c_uint, 4 * p) });
        save(v);
    } else if (streq(type_str, "hexDump")) {
        abi.fmtCStr(v, "{s}:{s}:{d}\n", .{ @as([*:0]const u8, name), @as([*:0]const u8, type_str), @as(c_uint, size) });
        save(v);
        var addr: u32 = 0;
        while (addr < size) : (addr += 32) {
            abi.fmtCStr(v, "{x:0>5}  ", .{@as(c_uint, addr)});
            var b: u32 = 0;
            while (b < 32) : (b += 1) {
                if (addr + b < size) {
                    abi.fmtCStr(v + 7 + 3 * b, "{x:0>2} ", .{@as(c_uint, buf[addr + b])});
                } else {
                    _ = strcpy(v + 7 + 3 * b, "   ");
                }
            }
            _ = strcpy(v + 103, " '");
            b = 0;
            while (b < 32) : (b += 1) {
                if (addr + b < size) {
                    const ch = buf[addr + b];
                    abi.fmtCStr(v + 105 + b, "{c}", .{@as(u8, @intCast(@as(c_int, if (ch >= ' ' and ch != 0x7f) ch else ' ')))});
                } else {
                    _ = strcpy(v + 105 + b, " ");
                }
            }
            _ = strcpy(v + 137, "'\n");
            save(v);
        }
    }
}
fn c47ptr(p: [*c]const u8) u32 {
    return progmem.toC47memptr(geometry(), @intFromPtr(p));
}
fn offWithin(p: [*c]const u8) u32 {
    return progmem.offsetWithinBlock(geometry(), @intFromPtr(p));
}

pub fn saveCalc() void {
    const ok = (calc_model_user_id == USER_R47 and (calcModel == USER_R47f_g or calcModel == USER_R47fg_g or calcModel == USER_R47fg_bk or calcModel == USER_R47bk_fg)) or
        (calc_model_user_id == USER_C47 and (calcModel == USER_C47 or calcModel == USER_DM42));
    if (!ok) return;
    if (ioFileOpen(ioPathBackup, ioModeWrite) != FILE_OK) return;
    if (calcMode == CM_CONFIRMATION) {
        calcMode = previousCalcMode;
        refreshScreen(90);
    }
    var bv: u32 = BACKUP_VERSION;
    sv(&bv, 4, "backupVersion", "uint32");
    var rsib: u32 = geometry().ram_size_in_blocks;
    sv(&rsib, 4, "ramSizeInBlocks", "uint32");
    sv(&numberOfFreeMemoryRegions, 4, "numberOfFreeMemoryRegions", "int32");
    sv(freeMemoryRegions, FREE_MEM_REGION_SIZE * @as(u32, @bitCast(numberOfFreeMemoryRegions)), "freeMemoryRegions", "hexDump");
    sv(&numberOfAllocatedMemoryRegions, 4, "numberOfAllocatedMemoryRegions", "int32");
    sv(&allocatedMemoryRegions[0], FREE_MEM_REGION_SIZE * @as(u32, @bitCast(numberOfAllocatedMemoryRegions)), "allocatedMemoryRegions", "hexDump");
    sv(globalRegister, REGISTER_HEADER_SIZE * NUMBER_OF_GLOBAL_REGISTERS, "globalRegister", "hexDump");
    sv(&calcMode, 1, "calcMode", "uint8");
    sv(&previousCalcMode, 1, "previousCalcMode", "uint8");
    sv(&calcModel, 1, "calcModel", "uint8");
    sv(&globalFlags[0], 16, "globalFlags", "hexDump");
    sv(&errorMessage[0], 512, "errorMessage", "hexDump");
    sv(&aimBuffer[0], 1024, "aimBuffer", "hexDump");
    sv(&nimBufferDisplay[0], 200, "nimBufferDisplay", "hexDump");
    sv(&tamBuffer[0], 56, "tamBuffer", "hexDump");
    sv(&asmBuffer[0], 5, "asmBuffer", "hexDump");
    sv(&oldTime[0], 8, "oldTime", "hexDump");
    sv(&dateTimeString[0], 12, "dateTimeString", "hexDump");
    sv(&softmenuStack[0], 64, "softmenuStack", "hexDump");
    sv(&kbd_usr[0], 666, "kbd_usr", "hexDump");
    sv(&userMenuItems[0], 360, "userMenuItems", "hexDump");
    sv(&userAlphaItems[0], 360, "userAlphaItems", "hexDump");
    sv(&lastTemp[0], 16, "lastTemp", "hexDump");
    sv(&lastStateFileOpened[0], 32, "lastStateFileOpened", "hexDump");
    sv(&lastI[0], 2, "lastI", "int16");
    sv(&lastJ[0], 2, "lastJ", "int16");
    sv(&lastFunc[0], 2, "lastFunc", "int16");
    sv(&lastParam[0], 2, "lastParam", "int16");
    sv(&tam[0], 2, "tam.mode", "uint16");
    sv(&tam[2], 2, "tam.function", "int16");
    sv(&tam[4], 1, "tam.alpha", "bool");
    sv(&tam[6], 2, "tam.currentOperation", "int16");
    sv(&tam[8], 1, "tam.dot", "bool");
    sv(&tam[9], 1, "tam.indirect", "bool");
    sv(&tam[10], 2, "tam.digitsSoFar", "int16");
    sv(&tam[14], 2, "tam.value", "int16");
    sv(&tam[16], 2, "tam.min", "int16");
    sv(&tam[18], 2, "tam.max", "int16");
    sv(&rbrRegister[0], 2, "rbrRegister", "int16");
    sv(&numberOfNamedVariables[0], 2, "numberOfNamedVariables", "int16");
    sv(&xCursor[0], 4, "xCursor", "uint32");
    sv(&yCursor[0], 4, "yCursor", "uint32");
    sv(&firstGregorianDay[0], 4, "firstGregorianDay", "uint32");
    sv(&denMax[0], 4, "denMax", "uint32");
    sv(&lastDenominator[0], 4, "lastDenominator", "uint32");
    sv(&currentRegisterBrowserScreen[0], 2, "currentRegisterBrowserScreen", "int16");
    sv(&currentFntScr[0], 1, "currentFntScr", "uint8");
    sv(&currentFlgScr[0], 1, "currentFlgScr", "uint8");
    sv(&displayFormat[0], 1, "displayFormat", "uint8");
    sv(&displayFormatDigits[0], 1, "displayFormatDigits", "uint8");
    sv(&timeDisplayFormatDigits[0], 1, "timeDisplayFormatDigits", "uint8");
    sv(&shortIntegerWordSize[0], 1, "shortIntegerWordSize", "uint8");
    sv(&significantDigits[0], 1, "significantDigits", "uint8");
    sv(&fractionDigits[0], 1, "fractionDigits", "uint8");
    sv(&shortIntegerMode[0], 1, "shortIntegerMode", "uint8");
    sv(&currentAngularMode[0], 4, "currentAngularMode", "uint32");
    sv(&scrLock[0], 1, "scrLock", "uint8");
    sv(&roundingMode[0], 1, "roundingMode", "uint8");
    sv(&nextChar[0], 1, "nextChar", "uint8");
    sv(&alphaCase[0], 1, "alphaCase", "uint8");
    sv(&hourGlassIconEnabled[0], 1, "hourGlassIconEnabled", "bool");
    sv(&watchIconEnabled[0], 1, "watchIconEnabled", "bool");
    sv(&serialIOIconEnabled[0], 1, "serialIOIconEnabled", "bool");
    sv(&printerIconEnabled[0], 1, "printerIconEnabled", "bool");
    sv(&programRunStop[0], 1, "programRunStop", "uint8");
    sv(&entryStatus[0], 1, "entryStatus", "uint8");
    sv(&cursorEnabled[0], 1, "cursorEnabled", "uint8");
    sv(&rbr1stDigit[0], 1, "rbr1stDigit", "bool");
    sv(&shiftF[0], 1, "shiftF", "bool");
    sv(&shiftG[0], 1, "shiftG", "bool");
    sv(&rbrMode[0], 1, "rbrMode", "uint8");
    sv(&showContent[0], 1, "showContent", "bool");
    sv(&numScreensNumericFont[0], 1, "numScreensNumericFont", "uint8");
    sv(&numLinesNumericFont[0], 1, "numLinesNumericFont", "uint8");
    sv(&numScreensStandardFont[0], 1, "numScreensStandardFont", "uint8");
    sv(&numLinesStandardFont[0], 1, "numLinesStandardFont", "uint8");
    sv(&numScreensTinyFont[0], 1, "numScreensTinyFont", "uint8");
    sv(&numLinesTinyFont[0], 1, "numLinesTinyFont", "uint8");
    sv(&lastErrorCode[0], 1, "lastErrorCode", "uint8");
    sv(&previousErrorCode[0], 1, "previousErrorCode", "uint8");
    sv(&nimNumberPart[0], 1, "nimNumberPart", "uint8");
    sv(&displayStack[0], 1, "displayStack", "uint8");
    sv(&hexDigits[0], 1, "hexDigits", "uint8");
    sv(&errorMessageRegisterLine[0], 2, "errorMessageRegisterLine", "int16");
    sv(&shortIntegerMask[0], 8, "shortIntegerMask", "uint64");
    sv(&shortIntegerSignBit[0], 8, "shortIntegerSignBit", "uint64");
    sv(&temporaryInformation[0], 1, "temporaryInformation", "uint8");
    sv(&funcOK[0], 1, "funcOK", "bool");
    sv(&screenChange[0], 1, "screenChange", "bool");
    sv(&exponentSignLocation[0], 2, "exponentSignLocation", "int16");
    sv(&denominatorLocation[0], 2, "denominatorLocation", "int16");
    sv(&imaginaryExponentSignLocation[0], 2, "imaginaryExponentSignLocation", "int16");
    sv(&imaginaryMantissaSignLocation[0], 2, "imaginaryMantissaSignLocation", "int16");
    sv(&lineTWidth[0], 2, "lineTWidth", "int16");
    sv(&lastIntegerBase[0], 4, "lastIntegerBase", "uint32");
    sv(&c47MemInBlocks[0], 8, "c47MemInBlocks", "uint64");
    sv(&gmpMemInBytes[0], 8, "gmpMemInBytes", "uint64");
    sv(&catalog[0], 2, "catalog", "int16");
    sv(&lastCatalogPosition[0], 46, "lastCatalogPosition", "int16");
    sv(&displayValueX[0], 80, "displayValueX", "hexDump");
    sv(&pcg32_global[0], 16, "pcg32_global", "hexDump");
    sv(&exponentLimit[0], 2, "exponentLimit", "int16");
    sv(&exponentHideLimit[0], 2, "exponentHideLimit", "int16");
    sv(&keyActionProcessed[0], 1, "keyActionProcessed", "bool");
    sv(&systemFlags0[0], 8, "systemFlags", "uint64");
    sv(&systemFlags1[0], 8, "systemFlags1", "uint64");
    sv(&savedSystemFlags0[0], 8, "savedSystemFlags", "uint64");
    sv(&savedSystemFlags1[0], 8, "savedSystemFlags1", "uint64");
    sv(&thereIsSomethingToUndo[0], 1, "thereIsSomethingToUndo", "bool");
    sv(&freeProgramBytes[0], 2, "freeProgramBytes", "uint16");
    sv(&firstDisplayedLocalStepNumber[0], 2, "firstDisplayedLocalStepNumber", "uint16");
    sv(&numberOfLabels[0], 2, "numberOfLabels", "uint16");
    sv(&numberOfPrograms[0], 2, "numberOfPrograms", "uint16");
    sv(&currentLocalStepNumber[0], 2, "currentLocalStepNumber", "uint16");
    sv(&currentProgramNumber[0], 2, "currentProgramNumber", "uint16");
    sv(&lastProgramListEnd[0], 1, "lastProgramListEnd", "bool");
    sv(&programListEnd[0], 1, "programListEnd", "bool");
    sv(&allSubroutineLevels[0], 4, "allSubroutineLevels", "uint32");
    sv(&pemCursorIsZerothStep[0], 1, "pemCursorIsZerothStep", "bool");
    sv(&skippedStackLines[0], 1, "skippedStackLines", "bool");
    sv(&iterations[0], 1, "iterations", "bool");
    sv(&numberOfTamMenusToPop[0], 2, "numberOfTamMenusToPop", "int16");
    sv(&lrSelection[0], 2, "lrSelection", "uint16");
    sv(&lrSelectionUndo[0], 2, "lrSelectionUndo", "uint16");
    sv(&amortP1[0], 2, "amortP1", "uint16");
    sv(&amortP2[0], 2, "amortP2", "uint16");
    sv(&lrChosen[0], 2, "lrChosen", "uint16");
    sv(&lrChosenUndo[0], 2, "lrChosenUndo", "uint16");
    sv(&lastPlotMode[0], 2, "lastPlotMode", "uint16");
    sv(&plotSelection[0], 2, "plotSelection", "uint16");
    sv(&graph_dx[0], 4, "graph_dx", "float");
    sv(&graph_dy[0], 4, "graph_dy", "float");
    sv(&roundedTicks[0], 1, "roundedTicks", "bool");
    sv(&PLOT_AXIS[0], 1, "PLOT_AXIS", "bool");
    sv(&PLOT_ZMY[0], 1, "PLOT_ZMY", "int8");
    sv(&PLOT_ZOOM[0], 1, "PLOT_ZOOM", "uint8");
    sv(&plotmode[0], 1, "plotmode", "int8");
    sv(&tick_int_x[0], 4, "tick_int_x", "float");
    sv(&tick_int_y[0], 4, "tick_int_y", "float");
    sv(x_min, REAL_SIZE_IN_BYTES_34, "x_min", "real");
    sv(x_max, REAL_SIZE_IN_BYTES_34, "x_max", "real");
    sv(y_min, REAL_SIZE_IN_BYTES_34, "y_min", "real");
    sv(y_max, REAL_SIZE_IN_BYTES_34, "y_max", "real");
    sv(&xzero[0], 4, "xzero", "uint32");
    sv(&yzero[0], 4, "yzero", "uint32");
    sv(&regStatsXY[0], 2, "regStatsXY", "int16");
    sv(&matrixIndex[0], 2, "matrixIndex", "uint16");
    sv(&shadowI[0], 2, "shadowI", "int16");
    sv(&shadowJ[0], 2, "shadowJ", "int16");
    sv(&currentViewRegister[0], 2, "currentViewRegister", "uint16");
    sv(&currentSolverStatus[0], 2, "currentSolverStatus", "uint16");
    sv(&currentSolverProgram[0], 2, "currentSolverProgram", "uint16");
    sv(&currentSolverVariable[0], 2, "currentSolverVariable", "uint16");
    sv(&numberOfFormulae[0], 2, "numberOfFormulae", "uint16");
    sv(&currentFormula[0], 2, "currentFormula", "uint16");
    sv(&numberOfUserMenus[0], 2, "numberOfUserMenus", "uint16");
    sv(&currentUserMenu[0], 2, "currentUserMenu", "uint16");
    sv(&userKeyLabelSize[0], 2, "userKeyLabelSize", "uint16");
    sv(&timerCraAndDeciseconds[0], 1, "timerCraAndDeciseconds", "uint8");
    sv(&timerValue[0], 4, "timerValue", "uint32");
    sv(&timerTotalTime[0], 4, "timerTotalTime", "uint32");
    sv(&currentInputVariable[0], 2, "currentInputVariable", "uint16");
    sv(&SAVED_SIGMA_LASTX[0], 60, "SAVED_SIGMA_LASTX", "real");
    sv(&SAVED_SIGMA_LASTY[0], 60, "SAVED_SIGMA_LASTY", "real");
    sv(&SAVED_SIGMA_lastAddRem[0], 1, "SAVED_SIGMA_lastAddRem", "int8");
    sv(&currentMvarLabel[0], 2, "currentMvarLabel", "uint16");
    sv(&plotStatMx[0], 8, "plotStatMx", "hexDump");
    sv(&drawHistogram[0], 1, "drawHistogram", "uint8");
    sv(&plotStatScale[0], 1, "plotStatScale", "uint8");
    sv(&statMx[0], 8, "statMx", "hexDump");
    sv(&lrSelectionHistobackup[0], 2, "lrSelectionHistobackup", "uint16");
    sv(&lrChosenHistobackup[0], 2, "lrChosenHistobackup", "uint16");
    sv(&loBinR[0], 16, "loBinR", "real34");
    sv(&nBins[0], 16, "nBins", "real34");
    sv(&hiBinR[0], 16, "hiBinR", "real34");
    sv(&histElementXorY[0], 2, "histElementXorY", "int16");
    sv(&screenUpdatingMode[0], 1, "screenUpdatingMode", "uint8");
    sv(&Norm_Key_00[0], 2, "Norm_Key_00.func", "int16");
    sv(&Norm_Key_00[2], 16, "Norm_Key_00.funcParam", "hexDump");
    sv(&Norm_Key_00[18], 1, "Norm_Key_00.used", "bool");
    sv(&Input_Default[0], 1, "Input_Default", "uint8");
    sv(&T_cursorPos[0], 2, "T_cursorPos", "int16");
    sv(&multiEdLines[0], 1, "multiEdLines", "uint8");
    sv(&current_cursor_x[0], 2, "current_cursor_x", "uint16");
    sv(&current_cursor_y[0], 2, "current_cursor_y", "uint16");
    sv(&xMultiLineEdOffset[0], 1, "xMultiLineEdOffset", "uint8");
    sv(&yMultiLineEdOffset[0], 1, "yMultiLineEdOffset", "uint8");
    sv(&showRegis[0], 2, "showRegis", "int16");
    sv(&overrideShowBottomLine[0], 1, "overrideShowBottomLine", "uint8");
    sv(&displayStackSHOIDISP[0], 1, "displayStackSHOIDISP", "uint8");
    sv(&ListXYposition[0], 2, "ListXYposition", "int16");
    sv(&DRG_Cycling[0], 1, "DRG_Cycling", "uint8");
    sv(&lastFlgScr[0], 1, "lastFlgScr", "uint8");
    sv(&displayAIMbufferoffset[0], 2, "displayAIMbufferoffset", "int16");
    sv(&bcdDisplaySign[0], 1, "bcdDisplaySign", "uint8");
    sv(&DM_Cycling[0], 1, "DM_Cycling", "uint8");
    sv(&LongPressM[0], 1, "LongPressM", "uint8");
    sv(&LongPressF[0], 1, "LongPressF", "uint8");
    sv(&currentAsnScr[0], 1, "currentAsnScr", "uint8");
    sv(&gapItemLeft[0], 2, "gapItemLeft", "uint16");
    sv(&gapItemRight[0], 2, "gapItemRight", "uint16");
    sv(&gapItemRadix[0], 2, "gapItemRadix", "uint16");
    sv(&lastCenturyHighUsed[0], 2, "lastCenturyHighUsed", "uint16");
    sv(&grpGroupingLeft[0], 1, "grpGroupingLeft", "uint8");
    sv(&grpGroupingGr1LeftOverflow[0], 1, "grpGroupingGr1LeftOverflow", "uint8");
    sv(&grpGroupingGr1Left[0], 1, "grpGroupingGr1Left", "uint8");
    sv(&grpGroupingRight[0], 1, "grpGroupingRight", "uint8");
    sv(&firstDayOfWeek[0], 1, "firstDayOfWeek", "uint8");
    sv(&firstWeekOfYearDay[0], 1, "firstWeekOfYearDay", "uint8");
    sv(&dispBase[0], 1, "dispBase", "uint8");
    sv(&printerState[0], 1, "printerState.print_on", "bool");
    sv(&printerState[8], 4, "printerState.printer_model", "uint8");
    sv(&printerState[12], 2, "printerState.delay", "uint16");
    {
        var cf: i8 = cursorFontId();
        sv(&cf, 1, "cursorFont", "int8");
    }
    graphVariabl1 = INVALID_VARIABLE;
    sv(&graphVariabl1, 2, "graphVariabl1", "int16");
    {
        var v: u32 = c47ptr(allNamedVariables);
        sv(&v, 4, "allNamedVariables", "c47Ptr");
    }
    {
        var v: u32 = c47ptr(allFormulae);
        sv(&v, 4, "allFormulae", "c47Ptr");
    }
    {
        var v: u32 = c47ptr(userMenus);
        sv(&v, 4, "userMenus", "c47Ptr");
    }
    {
        var v: u32 = c47ptr(userKeyLabel);
        sv(&v, 4, "userKeyLabel", "c47Ptr");
    }
    {
        var v: u32 = c47ptr(statisticalSumsPointer);
        sv(&v, 4, "statisticalSumsPointer", "c47Ptr");
    }
    {
        var v: u32 = c47ptr(savedStatisticalSumsPointer);
        sv(&v, 4, "savedStatisticalSumsPointer", "c47Ptr");
    }
    {
        var v: u32 = c47ptr(labelList);
        sv(&v, 4, "labelList", "c47Ptr");
    }
    {
        var v: u32 = c47ptr(programList);
        sv(&v, 4, "programList", "c47Ptr");
    }
    {
        var v: u32 = c47ptr(currentSubroutineLevelData);
        sv(&v, 4, "currentSubroutineLevelData", "c47Ptr");
    }
    {
        var v: u32 = c47ptr(currentLocalFlags);
        sv(&v, 4, "currentLocalFlags", "c47Ptr");
    }
    {
        var v: u32 = c47ptr(currentLocalRegisters);
        sv(&v, 4, "currentLocalRegisters", "c47Ptr");
    }
    {
        var v: u32 = c47ptr(beginOfProgramMemory);
        sv(&v, 4, "beginOfProgramMemory", "c47Ptr");
    }
    {
        var v: u32 = offWithin(beginOfProgramMemory);
        sv(&v, 4, "beginOfProgramMemoryOffset", "uint32");
    }
    {
        var v: u32 = c47ptr(firstFreeProgramByte);
        sv(&v, 4, "firstFreeProgramByte", "c47Ptr");
    }
    {
        var v: u32 = offWithin(firstFreeProgramByte);
        sv(&v, 4, "firstFreeProgramByteOffset", "uint32");
    }
    {
        var v: u32 = c47ptr(firstDisplayedStep);
        sv(&v, 4, "firstDisplayedStep", "c47Ptr");
    }
    {
        var v: u32 = offWithin(firstDisplayedStep);
        sv(&v, 4, "firstDisplayedStepOffset", "uint32");
    }
    {
        var v: u32 = c47ptr(currentStep);
        sv(&v, 4, "currentStep", "c47Ptr");
    }
    {
        var v: u32 = offWithin(currentStep);
        sv(&v, 4, "currentStepOffset", "uint32");
    }
    sv(@ptrCast(ram), (geometry().ram_size_in_blocks) << 2, "ram", "hexDump");
    ioFileClose();
}

// ===================== RESTORE side =====================
// labelList/savedStatisticalSumsPointer are pointer globals not declared above.
// --- backup.cfg parser + typed value deserializer (host-only) ---
extern fn ioEof() c_int;
extern fn malloc(n: usize) ?*anyopaque;
extern fn free(p: ?*anyopaque) void;
extern fn strncmp(a: [*c]const u8, b: [*c]const u8, n: usize) c_int;
extern fn decNumberFromString(dst: [*c]u8, src: [*c]const u8, ctx: *OpaqueCtx) [*c]u8; // stringToReal
extern fn decQuadFromString(dst: [*c]u8, src: [*c]const u8, ctx: *OpaqueCtx) [*c]u8; // stringToReal34
const OpaqueCtx = opaque {};
extern var ctxtReal34: OpaqueCtx;
extern var ctxtReal39: OpaqueCtx;

// The config-param list (was the file-static cfgFileParam_t paramHead chain),
// now Zig-owned. Built from the open backup.cfg, walked by restoreStateValue.
const CfgParam = extern struct { param: [*c]u8, next: ?*CfgParam };
var paramHead: ?*CfgParam = null;
var paramCurrent: ?*CfgParam = null;

fn backupOpenParse() c_int {
    var oneParam: [200]u8 = undefined;
    const op: [*c]u8 = &oneParam[0];
    const ret = ioFileOpen(ioPathBackup, ioModeRead);
    if (ret != FILE_OK) return ret;
    calc_state.readLine(op, oneParam.len);
    paramHead = @ptrCast(@alignCast(malloc(@sizeOf(CfgParam))));
    paramCurrent = paramHead;
    paramCurrent.?.param = @ptrCast(malloc(strlen(op) + 1));
    _ = strcpy(paramCurrent.?.param, op);
    paramCurrent.?.next = null;
    calc_state.readLine(op, oneParam.len);
    while (ioEof() == 0) {
        paramCurrent.?.next = @ptrCast(@alignCast(malloc(@sizeOf(CfgParam))));
        paramCurrent = paramCurrent.?.next;
        paramCurrent.?.param = @ptrCast(malloc(strlen(op) + 1));
        _ = strcpy(paramCurrent.?.param, op);
        paramCurrent.?.next = null;
        calc_state.readLine(op, oneParam.len);
    }
    ioFileClose();
    return FILE_OK;
}
fn backupFreeParams() void {
    paramCurrent = paramHead;
    while (paramHead) |h| {
        paramHead = h.next;
        free(h.param);
        free(h);
        paramCurrent = paramHead;
    }
}
fn hexNibble(c: u8) u8 {
    return c - (if (c <= '9') @as(u8, '0') else 'a' - 10);
}
// Typed value deserializer (saveRestoreCalcState.c restoreStateValue).
fn restoreStateValue(buffer: ?*anyopaque, size: u32, name: [*c]const u8, type_str: [*c]const u8) void {
    _ = size;
    var value: [200]u8 = undefined;
    const v: [*c]u8 = &value[0];
    _ = strcpy(v, name);
    _ = strcat(v, ":");
    paramCurrent = paramHead;
    while (paramCurrent) |pc| {
        if (strncmp(pc.param, v, strlen(v)) == 0) break;
        paramCurrent = pc.next;
    }
    if (paramCurrent == null) return; // default value kept
    const param = paramCurrent.?.param;
    const typePtr = strchr(param, ':');
    if (typePtr == null) return;
    const tp = typePtr + 1;
    const valuePtr = strchr(tp, ':');
    if (valuePtr == null) return;
    const vp = valuePtr + 1;
    // extract the type from the line and verify it matches.
    var i: usize = 0;
    var p = tp;
    while (p[0] != ':') : (p += 1) {
        value[i] = p[0];
        i += 1;
    }
    value[i] = 0;
    if (strcmp(type_str, v) != 0) return;

    if (streq(type_str, "int64")) {
        @as(*i64, @ptrCast(@alignCast(buffer))).* = calc_state.stringToInt64(vp);
    } else if (streq(type_str, "uint64")) {
        @as(*u64, @ptrCast(@alignCast(buffer))).* = calc_state.stringToUint64(vp);
    } else if (streq(type_str, "int32")) {
        @as(*i32, @ptrCast(@alignCast(buffer))).* = calc_state.stringToInt32(vp);
    } else if (streq(type_str, "uint32")) {
        @as(*u32, @ptrCast(@alignCast(buffer))).* = calc_state.stringToUint32(vp);
    } else if (streq(type_str, "int16")) {
        @as(*i16, @ptrCast(@alignCast(buffer))).* = calc_state.stringToInt16(vp);
    } else if (streq(type_str, "uint16")) {
        @as(*u16, @ptrCast(@alignCast(buffer))).* = calc_state.stringToUint16(vp);
    } else if (streq(type_str, "int8")) {
        @as(*i8, @ptrCast(buffer)).* = calc_state.stringToInt8(vp);
    } else if (streq(type_str, "uint8")) {
        @as(*u8, @ptrCast(buffer)).* = calc_state.stringToUint8(vp);
    } else if (streq(type_str, "float")) {
        @as(*f32, @ptrCast(@alignCast(buffer))).* = @floatCast(atof(vp));
    } else if (streq(type_str, "double")) {
        @as(*f64, @ptrCast(@alignCast(buffer))).* = atof(vp);
    } else if (streq(type_str, "real")) {
        _ = decNumberFromString(@ptrCast(buffer), vp, &ctxtReal39);
    } else if (streq(type_str, "real34")) {
        _ = decQuadFromString(@ptrCast(buffer), vp, &ctxtReal34);
    } else if (streq(type_str, "bool")) {
        @as(*u8, @ptrCast(buffer)).* = if (calc_state.stringToInt8(vp) != 0) 1 else 0;
    } else if (streq(type_str, "c47Ptr")) {
        @as(*u32, @ptrCast(@alignCast(buffer))).* = @truncate(strtoul(vp, null, 0));
    } else if (streq(type_str, "hexDump")) {
        const numberOfBytes = calc_state.stringToUint32(vp);
        var bufp: [*c]u8 = @ptrCast(buffer);
        // The two hex digits of byte b sit at offset 7 + 3*b of a dump line saveStateValue() wrote. A line in
        // the file need not be that long, so index it against its own length. Offsets rather than pointers: a
        // line shorter than 7 has no such position to point at, one-past-the-end or otherwise.
        var dumpLine: [*c]const u8 = null;
        var dumpLineLength: usize = 0;
        var digit: usize = 0;
        var count: u32 = 0;
        while (count < numberOfBytes) : ({
            count += 1;
            bufp += 1;
        }) {
            if (count % 32 == 0) {
                paramCurrent = paramCurrent.?.next;
                const pc = paramCurrent orelse break;
                dumpLine = pc.param;
                dumpLineLength = strlen(pc.param);
                digit = 7;
            }
            if (digit + 1 >= dumpLineLength) { // the line ends before the digit pair this byte needs: stop, as for a parameter list that runs out above
                break;
            }
            const hi = hexNibble(dumpLine[digit]);
            const lo = hexNibble(dumpLine[digit + 1]);
            digit += 3;
            bufp[0] = (hi << 4) | lo;
        }
    }
}
extern fn atof(s: [*c]const u8) f64;
extern fn strtoul(s: [*c]const u8, endptr: ?*[*c]u8, base: c_int) c_ulong; // c47Ptr: "%u (0x..)" -> stop at space
extern fn doFnReset(confirmation: u16, auto_sav: bool) void;
extern fn invalidateNamedVariableCache() callconv(.c) void;
extern fn scanLabelsAndPrograms() void;
extern fn defineCurrentProgramFromGlobalStepNumber(global_step: i16) void;
extern fn defineCurrentStep() void;
extern fn defineFirstDisplayedStep() void;
extern fn defineCurrentProgramFromCurrentStep() void;
extern fn getSystemFlag(sf: i32) bool;
extern fn setSystemFlag(sf: c_uint) void;
extern fn clearSystemFlag(sf: c_uint) void;
extern fn setLongPressFg(calc_model0: c_int, menu_item: i16) void;
const ioModeRead: c_int = 0;
const CONFIRMED: u16 = 9877;
const loadAutoSav: bool = true;
const FLAG_FRACT: c_uint = 32775;
const FLAG_IRFRAC: c_uint = 32839;
const MNU_HOME: i16 = 1921;
const FLAG_SIGZEROS: c_uint = 32874; // 0x806A

fn rv(buffer: ?*anyopaque, size: u32, name: [*c]const u8, type_str: [*c]const u8) void {
    restoreStateValue(buffer, size, name, type_str);
}
extern fn stringToDouble(str: [*c]const u8) f64; // locale-free strtod (accepts '.' or ',')
extern fn convertDoubleToReal(x: f64, destination: *real_t, ctxt: *OpaqueCtx) void;
// One-time migration of a pre-1016 float parameter into its new real (or double)
// variable (saveRestoreBackup.c migrateFloatValue). Not an error: the old value is
// converted and the next save writes the new type. Leaves the default in place when
// no old float value is present.
fn migrateFloatValue(buffer: ?*anyopaque, valueName: [*c]const u8, newType: [*c]const u8) void {
    var search: [60]u8 = undefined;
    const s: [*c]u8 = &search[0];
    _ = strcpy(s, valueName);
    _ = strcat(s, ":float:");
    paramCurrent = paramHead;
    while (paramCurrent) |pc| {
        if (strncmp(pc.param, s, strlen(s)) == 0) break;
        paramCurrent = pc.next;
    }
    if (paramCurrent == null) return; // old float value absent: keep the default
    var d = stringToDouble(paramCurrent.?.param + strlen(s));
    if (!std.math.isFinite(d)) d = 0; // unusable old value: store the default 0
    if (streq(newType, "real")) {
        convertDoubleToReal(d, @ptrCast(buffer), &ctxtReal39);
    } else {
        @as(*f64, @ptrCast(@alignCast(buffer))).* = d;
    }
}
fn toPcmem(blk: u32) [*c]u8 {
    return @ptrFromInt(progmem.toPcmemptr(geometry(), @intCast(blk)));
}
const C47_NULL: u32 = 65535;
const MAX_FREE_REGIONS: u32 = if (state_old_hw) 50 else 200;
const MAX_ALLOCATED_REGIONS: u32 = 5000;

// A memory region count read from backup.cfg is how many entries of freeMemoryRegions or
// allocatedMemoryRegions freeList.c walks, so a count outside 0..ceiling cannot describe the file's own
// tables. Report it and let the caller refuse the file, as it already does for a wrong RAM size. This is a
// coherence check, not the bound on the restore: those writes are bounded by the destination.
fn restoredRegionCountIsUsable(count: i32, ceiling: u32) bool {
    return count >= 0 and @as(u32, @intCast(count)) <= ceiling;
}

// Restore one c47Ptr - a block index into ram - together with the byte offset saveCalc() stored beside it
// where the field has one, and build the pointer from the two integers. TO_PCMEMPTR() has no range of its
// own, so the range test here is what stops a block index the file chose forming a pointer outside the
// pool, before scanLabelsAndPrograms() or the register walk is handed it.
//
// `current` seeds both numbers, so a field whose parameter the file omits keeps its own value.
// restoreStateValue() writes nothing when it finds no match, so one scratch variable shared across the
// fields would hand an omitted field whichever pointer was restored before it.
//
// Out of range clears poolPointersInRange, which makes the caller refuse the file, and returns null rather
// than a pointer the caller might still use. C47_NULL is the file's own null and stays legal.
fn restoredPoolPointer(current: [*c]u8, valueName: [*c]const u8, offsetValueName: ?[*c]const u8, poolPointersInRange: *bool) [*c]u8 {
    const geo = geometry();
    var blockAddress: u32 = progmem.toC47memptr(geo, @intFromPtr(current));
    var byteOffset: u32 = if (current == null) 0 else progmem.offsetWithinBlock(geo, @intFromPtr(current));

    rv(&blockAddress, 4, valueName, "c47Ptr");
    if (offsetValueName) |ovn| {
        rv(&byteOffset, 4, ovn, "uint32");
    }

    if (blockAddress == C47_NULL and byteOffset == 0) {
        return null;
    }
    // Bound each number against what the format lets the writer produce, not against the pool as a whole:
    // saveCalc() splits a pointer with TO_C47MEMPTR(), which divides by the block size, and stores the
    // remainder as the offset, so an offset is never one block or more. The result is required to be
    // strictly inside the pool: a block index of ram_size_in_blocks is the one-past-the-end position.
    if (blockAddress >= geo.ram_size_in_blocks or byteOffset >= 4) {
        poolPointersInRange.* = false;
        return null;
    }
    return @ptrFromInt(progmem.toPcmemptr(geo, @intCast(blockAddress)) + byteOffset);
}
fn rdU16(p: [*c]const u8) u16 {
    return @as(u16, p[0]) | (@as(u16, p[1]) << 8);
}
fn programStep(idx: u16) i32 {
    const base = programList + @as(usize, idx) * 16;
    return @as(*const i32, @ptrCast(@alignCast(base))).*;
}

pub fn restoreCalc() void {
    doFnReset(CONFIRMED, loadAutoSav);
    if (backupOpenParse() != FILE_OK) return;
    var backupVersion: u32 = 0;
    rv(&backupVersion, 4, "backupVersion", "uint32");
    var ramSizeInBlocks: u32 = 0;
    rv(&ramSizeInBlocks, 4, "ramSizeInBlocks", "uint32");
    if (ramSizeInBlocks != geometry().ram_size_in_blocks) {
        backupFreeParams();
        return;
    }
    if (backupVersion == 0 or backupVersion < 1011) {
        backupFreeParams();
        return;
    }
    // Both region counts are read into locals and checked before anything is committed, and ahead of the
    // ram restore, so a file refused here leaves the calculator doFnReset() built at entry rather than one
    // with half a pool in it. A parameter the file omits leaves its local at the live value, as for any
    // other field.
    var restoredFreeRegions: i32 = numberOfFreeMemoryRegions;
    var restoredAllocatedRegions: i32 = numberOfAllocatedMemoryRegions;
    rv(&restoredFreeRegions, 4, "numberOfFreeMemoryRegions", "int32");
    rv(&restoredAllocatedRegions, 4, "numberOfAllocatedMemoryRegions", "int32");
    if (!restoredRegionCountIsUsable(restoredFreeRegions, MAX_FREE_REGIONS) or
        !restoredRegionCountIsUsable(restoredAllocatedRegions, MAX_ALLOCATED_REGIONS))
    {
        backupFreeParams();
        return;
    }
    numberOfFreeMemoryRegions = restoredFreeRegions;
    numberOfAllocatedMemoryRegions = restoredAllocatedRegions;

    rv(@ptrCast(ram), (geometry().ram_size_in_blocks) << 2, "ram", "hexDump");
    // The size argument is what stops the reader writing off the end, so it is the room the destination
    // has, the way every other call here passes a sizeof(). These writes cannot leave their table whatever
    // count the file carries.
    rv(freeMemoryRegions, FREE_MEM_REGION_SIZE * MAX_FREE_REGIONS, "freeMemoryRegions", "hexDump");
    rv(&allocatedMemoryRegions[0], FREE_MEM_REGION_SIZE * MAX_ALLOCATED_REGIONS, "allocatedMemoryRegions", "hexDump");
    rv(globalRegister, REGISTER_HEADER_SIZE * NUMBER_OF_GLOBAL_REGISTERS, "globalRegister", "hexDump");
    rv(&calcMode, 1, "calcMode", "uint8");
    rv(&previousCalcMode, 1, "previousCalcMode", "uint8");
    rv(&calcModel, 1, "calcModel", "uint8");

    var poolPointersInRange = true;
    allNamedVariables = restoredPoolPointer(allNamedVariables, "allNamedVariables", null, &poolPointersInRange);
    invalidateNamedVariableCache(); // the whole table arrives from the backup image: nothing findNamedVariable() remembers describes it any more
    allFormulae = restoredPoolPointer(allFormulae, "allFormulae", null, &poolPointersInRange);
    userMenus = restoredPoolPointer(userMenus, "userMenus", null, &poolPointersInRange);
    userKeyLabel = restoredPoolPointer(userKeyLabel, "userKeyLabel", null, &poolPointersInRange);
    statisticalSumsPointer = restoredPoolPointer(statisticalSumsPointer, "statisticalSumsPointer", null, &poolPointersInRange);
    savedStatisticalSumsPointer = restoredPoolPointer(savedStatisticalSumsPointer, "savedStatisticalSumsPointer", null, &poolPointersInRange);
    labelList = restoredPoolPointer(labelList, "labelList", null, &poolPointersInRange);
    programList = restoredPoolPointer(programList, "programList", null, &poolPointersInRange);
    currentSubroutineLevelData = restoredPoolPointer(currentSubroutineLevelData, "currentSubroutineLevelData", null, &poolPointersInRange);
    currentLocalFlags = restoredPoolPointer(currentLocalFlags, "currentLocalFlags", null, &poolPointersInRange);
    currentLocalRegisters = restoredPoolPointer(currentLocalRegisters, "currentLocalRegisters", null, &poolPointersInRange);

    beginOfProgramMemory = restoredPoolPointer(beginOfProgramMemory, "beginOfProgramMemory", "beginOfProgramMemoryOffset", &poolPointersInRange);
    firstFreeProgramByte = restoredPoolPointer(firstFreeProgramByte, "firstFreeProgramByte", "firstFreeProgramByteOffset", &poolPointersInRange);
    firstDisplayedStep = restoredPoolPointer(firstDisplayedStep, "firstDisplayedStep", "firstDisplayedStepOffset", &poolPointersInRange);
    currentStep = restoredPoolPointer(currentStep, "currentStep", "currentStepOffset", &poolPointersInRange);

    // Every field above is restored before this is tested, so one file reports every pointer it got wrong
    // rather than only the first. A file that describes pointers into some other pool is refused: nothing
    // here can repair it, and the next thing to run is scanLabelsAndPrograms() walking program memory
    // through exactly these pointers.
    //
    // Unlike the region-count check above, this one cannot simply return: by here ram holds the file's
    // bytes, the region counts are the file's, every pointer that passed has been assigned, and the one
    // that failed holds the null restoredPoolPointer() returns. So perform the reset this path implies.
    if (!poolPointersInRange) {
        backupFreeParams();
        doFnReset(CONFIRMED, loadAutoSav);
        return;
    }
    rv(&globalFlags[0], 16, "globalFlags", "hexDump");
    rv(&errorMessage[0], 512, "errorMessage", "hexDump");
    rv(&aimBuffer[0], 1024, "aimBuffer", "hexDump");
    rv(&nimBufferDisplay[0], 200, "nimBufferDisplay", "hexDump");
    rv(&tamBuffer[0], 56, "tamBuffer", "hexDump");
    rv(&asmBuffer[0], 5, "asmBuffer", "hexDump");
    rv(&oldTime[0], 8, "oldTime", "hexDump");
    rv(&dateTimeString[0], 12, "dateTimeString", "hexDump");
    rv(&softmenuStack[0], 64, "softmenuStack", "hexDump");
    rv(&kbd_usr[0], 666, "kbd_usr", "hexDump");
    rv(&userMenuItems[0], 360, "userMenuItems", "hexDump");
    rv(&userAlphaItems[0], 360, "userAlphaItems", "hexDump");
    rv(&lastTemp[0], 16, "lastTemp", "hexDump");
    rv(&lastStateFileOpened[0], 32, "lastStateFileOpened", "hexDump");
    rv(&lastI[0], 2, "lastI", "int16");
    rv(&lastJ[0], 2, "lastJ", "int16");
    rv(&lastFunc[0], 2, "lastFunc", "int16");
    rv(&lastParam[0], 2, "lastParam", "int16");
    rv(&tam[0], 2, "tam.mode", "uint16");
    rv(&tam[2], 2, "tam.function", "int16");
    rv(&tam[4], 1, "tam.alpha", "bool");
    rv(&tam[6], 2, "tam.currentOperation", "int16");
    rv(&tam[8], 1, "tam.dot", "bool");
    rv(&tam[9], 1, "tam.indirect", "bool");
    rv(&tam[10], 2, "tam.digitsSoFar", "int16");
    rv(&tam[14], 2, "tam.value", "int16");
    rv(&tam[16], 2, "tam.min", "int16");
    rv(&tam[18], 2, "tam.max", "int16");
    rv(&rbrRegister[0], 2, "rbrRegister", "int16");
    rv(&numberOfNamedVariables[0], 2, "numberOfNamedVariables", "int16");
    rv(&xCursor[0], 4, "xCursor", "uint32");
    rv(&yCursor[0], 4, "yCursor", "uint32");
    rv(&firstGregorianDay[0], 4, "firstGregorianDay", "uint32");
    rv(&denMax[0], 4, "denMax", "uint32");
    rv(&lastDenominator[0], 4, "lastDenominator", "uint32");
    rv(&currentRegisterBrowserScreen[0], 2, "currentRegisterBrowserScreen", "int16");
    rv(&currentFntScr[0], 1, "currentFntScr", "uint8");
    rv(&currentFlgScr[0], 1, "currentFlgScr", "uint8");
    rv(&displayFormat[0], 1, "displayFormat", "uint8");
    rv(&displayFormatDigits[0], 1, "displayFormatDigits", "uint8");
    rv(&timeDisplayFormatDigits[0], 1, "timeDisplayFormatDigits", "uint8");
    rv(&shortIntegerWordSize[0], 1, "shortIntegerWordSize", "uint8");
    shortIntegerWordSize[0] = boundShortIntegerWordSize(shortIntegerWordSize[0]);
    updateShortIntegerMasks(); // rederive shortIntegerMask and shortIntegerSignBit from the word size just restored; the file copies (older backups) are ignored
    rv(&significantDigits[0], 1, "significantDigits", "uint8");
    rv(&fractionDigits[0], 1, "fractionDigits", "uint8");
    rv(&shortIntegerMode[0], 1, "shortIntegerMode", "uint8");
    rv(&currentAngularMode[0], 4, "currentAngularMode", "uint32");
    rv(&scrLock[0], 1, "scrLock", "uint8");
    rv(&roundingMode[0], 1, "roundingMode", "uint8");
    rv(&nextChar[0], 1, "nextChar", "uint8");
    rv(&alphaCase[0], 1, "alphaCase", "uint8");
    rv(&hourGlassIconEnabled[0], 1, "hourGlassIconEnabled", "bool");
    rv(&watchIconEnabled[0], 1, "watchIconEnabled", "bool");
    rv(&serialIOIconEnabled[0], 1, "serialIOIconEnabled", "bool");
    rv(&printerIconEnabled[0], 1, "printerIconEnabled", "bool");
    rv(&programRunStop[0], 1, "programRunStop", "uint8");
    rv(&entryStatus[0], 1, "entryStatus", "uint8");
    rv(&cursorEnabled[0], 1, "cursorEnabled", "uint8");
    rv(&rbr1stDigit[0], 1, "rbr1stDigit", "bool");
    rv(&shiftF[0], 1, "shiftF", "bool");
    rv(&shiftG[0], 1, "shiftG", "bool");
    rv(&rbrMode[0], 1, "rbrMode", "uint8");
    rv(&showContent[0], 1, "showContent", "bool");
    rv(&numScreensNumericFont[0], 1, "numScreensNumericFont", "uint8");
    rv(&numLinesNumericFont[0], 1, "numLinesNumericFont", "uint8");
    rv(&numScreensStandardFont[0], 1, "numScreensStandardFont", "uint8");
    rv(&numLinesStandardFont[0], 1, "numLinesStandardFont", "uint8");
    rv(&numScreensTinyFont[0], 1, "numScreensTinyFont", "uint8");
    rv(&numLinesTinyFont[0], 1, "numLinesTinyFont", "uint8");
    rv(&lastErrorCode[0], 1, "lastErrorCode", "uint8");
    rv(&previousErrorCode[0], 1, "previousErrorCode", "uint8");
    rv(&nimNumberPart[0], 1, "nimNumberPart", "uint8");
    rv(&displayStack[0], 1, "displayStack", "uint8");
    rv(&hexDigits[0], 1, "hexDigits", "uint8");
    rv(&errorMessageRegisterLine[0], 2, "errorMessageRegisterLine", "int16");
    rv(&shortIntegerMask[0], 8, "shortIntegerMask", "uint64");
    rv(&shortIntegerSignBit[0], 8, "shortIntegerSignBit", "uint64");
    rv(&temporaryInformation[0], 1, "temporaryInformation", "uint8");
    rv(&funcOK[0], 1, "funcOK", "bool");
    rv(&screenChange[0], 1, "screenChange", "bool");
    rv(&exponentSignLocation[0], 2, "exponentSignLocation", "int16");
    rv(&denominatorLocation[0], 2, "denominatorLocation", "int16");
    rv(&imaginaryExponentSignLocation[0], 2, "imaginaryExponentSignLocation", "int16");
    rv(&imaginaryMantissaSignLocation[0], 2, "imaginaryMantissaSignLocation", "int16");
    rv(&lineTWidth[0], 2, "lineTWidth", "int16");
    rv(&lastIntegerBase[0], 4, "lastIntegerBase", "uint32");
    rv(&c47MemInBlocks[0], 8, "c47MemInBlocks", "uint64");
    rv(&gmpMemInBytes[0], 8, "gmpMemInBytes", "uint64");
    rv(&catalog[0], 2, "catalog", "int16");
    rv(&lastCatalogPosition[0], 46, "lastCatalogPosition", "int16");
    rv(&displayValueX[0], 80, "displayValueX", "hexDump");
    rv(&pcg32_global[0], 16, "pcg32_global", "hexDump");
    rv(&exponentLimit[0], 2, "exponentLimit", "int16");
    rv(&exponentHideLimit[0], 2, "exponentHideLimit", "int16");
    rv(&keyActionProcessed[0], 1, "keyActionProcessed", "bool");
    rv(&systemFlags0[0], 8, "systemFlags", "uint64");
    rv(&systemFlags1[0], 8, "systemFlags1", "uint64");
    rv(&savedSystemFlags0[0], 8, "savedSystemFlags", "uint64");
    rv(&savedSystemFlags1[0], 8, "savedSystemFlags1", "uint64");
    rv(&thereIsSomethingToUndo[0], 1, "thereIsSomethingToUndo", "bool");
    rv(&freeProgramBytes[0], 2, "freeProgramBytes", "uint16");
    rv(&firstDisplayedLocalStepNumber[0], 2, "firstDisplayedLocalStepNumber", "uint16");
    rv(&numberOfLabels[0], 2, "numberOfLabels", "uint16");
    rv(&numberOfPrograms[0], 2, "numberOfPrograms", "uint16");
    rv(&currentLocalStepNumber[0], 2, "currentLocalStepNumber", "uint16");
    rv(&currentProgramNumber[0], 2, "currentProgramNumber", "uint16");
    rv(&lastProgramListEnd[0], 1, "lastProgramListEnd", "bool");
    rv(&programListEnd[0], 1, "programListEnd", "bool");
    rv(&allSubroutineLevels[0], 4, "allSubroutineLevels", "uint32");
    rv(&pemCursorIsZerothStep[0], 1, "pemCursorIsZerothStep", "bool");
    rv(&skippedStackLines[0], 1, "skippedStackLines", "bool");
    rv(&iterations[0], 1, "iterations", "bool");
    rv(&numberOfTamMenusToPop[0], 2, "numberOfTamMenusToPop", "int16");
    rv(&lrSelection[0], 2, "lrSelection", "uint16");
    rv(&lrSelectionUndo[0], 2, "lrSelectionUndo", "uint16");
    rv(&amortP1[0], 2, "amortP1", "uint16");
    rv(&amortP2[0], 2, "amortP2", "uint16");
    rv(&lrChosen[0], 2, "lrChosen", "uint16");
    rv(&lrChosenUndo[0], 2, "lrChosenUndo", "uint16");
    rv(&lastPlotMode[0], 2, "lastPlotMode", "uint16");
    rv(&plotSelection[0], 2, "plotSelection", "uint16");
    rv(&graph_dx[0], 4, "graph_dx", "float");
    rv(&graph_dy[0], 4, "graph_dy", "float");
    rv(&roundedTicks[0], 1, "roundedTicks", "bool");
    rv(&PLOT_AXIS[0], 1, "PLOT_AXIS", "bool");
    rv(&PLOT_ZMY[0], 1, "PLOT_ZMY", "int8");
    rv(&PLOT_ZOOM[0], 1, "PLOT_ZOOM", "uint8");
    rv(&plotmode[0], 1, "plotmode", "int8");
    rv(&tick_int_x[0], 4, "tick_int_x", "float");
    rv(&tick_int_y[0], 4, "tick_int_y", "float");
    if (backupVersion >= 1016) {
        rv(x_min, REAL_SIZE_IN_BYTES_34, "x_min", "real");
        rv(x_max, REAL_SIZE_IN_BYTES_34, "x_max", "real");
        rv(y_min, REAL_SIZE_IN_BYTES_34, "y_min", "real");
        rv(y_max, REAL_SIZE_IN_BYTES_34, "y_max", "real");
    } else {
        // pre-1016 backups stored the ranges as float: convert each once; the next save writes "real".
        migrateFloatValue(x_min, "x_min", "real");
        migrateFloatValue(x_max, "x_max", "real");
        migrateFloatValue(y_min, "y_min", "real");
        migrateFloatValue(y_max, "y_max", "real");
    }
    rv(&xzero[0], 4, "xzero", "uint32");
    rv(&yzero[0], 4, "yzero", "uint32");
    rv(&regStatsXY[0], 2, "regStatsXY", "int16");
    rv(&matrixIndex[0], 2, "matrixIndex", "uint16");
    rv(&shadowI[0], 2, "shadowI", "int16");
    rv(&shadowJ[0], 2, "shadowJ", "int16");
    rv(&currentViewRegister[0], 2, "currentViewRegister", "uint16");
    rv(&currentSolverStatus[0], 2, "currentSolverStatus", "uint16");
    rv(&currentSolverProgram[0], 2, "currentSolverProgram", "uint16");
    rv(&currentSolverVariable[0], 2, "currentSolverVariable", "uint16");
    rv(&numberOfFormulae[0], 2, "numberOfFormulae", "uint16");
    rv(&currentFormula[0], 2, "currentFormula", "uint16");
    rv(&numberOfUserMenus[0], 2, "numberOfUserMenus", "uint16");
    rv(&currentUserMenu[0], 2, "currentUserMenu", "uint16");
    rv(&userKeyLabelSize[0], 2, "userKeyLabelSize", "uint16");
    rv(&timerCraAndDeciseconds[0], 1, "timerCraAndDeciseconds", "uint8");
    rv(&timerValue[0], 4, "timerValue", "uint32");
    rv(&timerTotalTime[0], 4, "timerTotalTime", "uint32");
    rv(&currentInputVariable[0], 2, "currentInputVariable", "uint16");
    rv(&SAVED_SIGMA_LASTX[0], 60, "SAVED_SIGMA_LASTX", "real");
    rv(&SAVED_SIGMA_LASTY[0], 60, "SAVED_SIGMA_LASTY", "real");
    rv(&SAVED_SIGMA_lastAddRem[0], 1, "SAVED_SIGMA_lastAddRem", "int8");
    rv(&currentMvarLabel[0], 2, "currentMvarLabel", "uint16");
    rv(&plotStatMx[0], 8, "plotStatMx", "hexDump");
    rv(&drawHistogram[0], 1, "drawHistogram", "uint8");
    rv(&plotStatScale[0], 1, "plotStatScale", "uint8");
    rv(&statMx[0], 8, "statMx", "hexDump");
    rv(&lrSelectionHistobackup[0], 2, "lrSelectionHistobackup", "uint16");
    rv(&lrChosenHistobackup[0], 2, "lrChosenHistobackup", "uint16");
    rv(&loBinR[0], 16, "loBinR", "real34");
    rv(&nBins[0], 16, "nBins", "real34");
    rv(&hiBinR[0], 16, "hiBinR", "real34");
    rv(&histElementXorY[0], 2, "histElementXorY", "int16");
    rv(&screenUpdatingMode[0], 1, "screenUpdatingMode", "uint8");
    rv(&Norm_Key_00[0], 2, "Norm_Key_00.func", "int16");
    rv(&Norm_Key_00[2], 16, "Norm_Key_00.funcParam", "hexDump");
    rv(&Norm_Key_00[18], 1, "Norm_Key_00.used", "bool");
    rv(&Input_Default[0], 1, "Input_Default", "uint8");
    rv(&T_cursorPos[0], 2, "T_cursorPos", "int16");
    rv(&multiEdLines[0], 1, "multiEdLines", "uint8");
    rv(&current_cursor_x[0], 2, "current_cursor_x", "uint16");
    rv(&current_cursor_y[0], 2, "current_cursor_y", "uint16");
    rv(&xMultiLineEdOffset[0], 1, "xMultiLineEdOffset", "uint8");
    rv(&yMultiLineEdOffset[0], 1, "yMultiLineEdOffset", "uint8");
    rv(&showRegis[0], 2, "showRegis", "int16");
    rv(&overrideShowBottomLine[0], 1, "overrideShowBottomLine", "uint8");
    rv(&displayStackSHOIDISP[0], 1, "displayStackSHOIDISP", "uint8");
    rv(&ListXYposition[0], 2, "ListXYposition", "int16");
    rv(&DRG_Cycling[0], 1, "DRG_Cycling", "uint8");
    rv(&lastFlgScr[0], 1, "lastFlgScr", "uint8");
    rv(&displayAIMbufferoffset[0], 2, "displayAIMbufferoffset", "int16");
    rv(&bcdDisplaySign[0], 1, "bcdDisplaySign", "uint8");
    rv(&DM_Cycling[0], 1, "DM_Cycling", "uint8");
    rv(&LongPressM[0], 1, "LongPressM", "uint8");
    rv(&LongPressF[0], 1, "LongPressF", "uint8");
    rv(&currentAsnScr[0], 1, "currentAsnScr", "uint8");
    rv(&gapItemLeft[0], 2, "gapItemLeft", "uint16");
    rv(&gapItemRight[0], 2, "gapItemRight", "uint16");
    rv(&gapItemRadix[0], 2, "gapItemRadix", "uint16");
    rv(&lastCenturyHighUsed[0], 2, "lastCenturyHighUsed", "uint16");
    rv(&grpGroupingLeft[0], 1, "grpGroupingLeft", "uint8");
    rv(&grpGroupingGr1LeftOverflow[0], 1, "grpGroupingGr1LeftOverflow", "uint8");
    rv(&grpGroupingGr1Left[0], 1, "grpGroupingGr1Left", "uint8");
    rv(&grpGroupingRight[0], 1, "grpGroupingRight", "uint8");
    rv(&firstDayOfWeek[0], 1, "firstDayOfWeek", "uint8");
    rv(&firstWeekOfYearDay[0], 1, "firstWeekOfYearDay", "uint8");
    rv(&dispBase[0], 1, "dispBase", "uint8");
    rv(&printerState[0], 1, "printerState.print_on", "bool");
    rv(&printerState[8], 4, "printerState.printer_model", "uint8");
    rv(&printerState[12], 2, "printerState.delay", "uint16");
    graphVariabl1 = INVALID_VARIABLE;
    rv(&graphVariabl1, 2, "graphVariabl1", "int16");
    if (backupVersion < 1014) setLongPressFg(calcModel, -MNU_HOME);
    if (backupVersion < 1015) setSystemFlag(FLAG_SIGZEROS); // C saveRestoreBackup.c:1153-1155
    if (getSystemFlag(@intCast(FLAG_FRACT))) {
        setSystemFlag(FLAG_FRACT);
    } else if (getSystemFlag(@intCast(FLAG_IRFRAC))) {
        setSystemFlag(FLAG_IRFRAC);
    }
    backupFreeParams();
    scanLabelsAndPrograms();
    {
        const cpn = rdU16(&currentProgramNumber[0]);
        const cls = rdU16(&currentLocalStepNumber[0]);
        const step = programStep(cpn - 1);
        const gsn = @as(i32, cls) + (if (step < 0) -step else step) - 1;
        defineCurrentProgramFromGlobalStepNumber(@intCast(gsn));
    }
    defineCurrentStep();
    defineFirstDisplayedStep();
    defineCurrentProgramFromCurrentStep();
}
