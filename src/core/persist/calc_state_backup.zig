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
const calc_state_restore = @import("calc_state_restore.zig");
const state_old_hw: bool = build_options.state_old_hw;
// OPTION_STRUCTURED_PGM: the running FOR structures are saved with the calculator,
// so a loop survives a power cycle. A build without the structures has no table.
const option_structured_pgm: bool = build_options.option_structured_pgm;
// OPTION_ATEXT_FONTS: the font ATEXT draws with is saved beside the GRMOD byte.
const option_atext_fonts: bool = build_options.option_atext_fonts;
// OPTION_DRG_CFG: the units the DRG menu chose are saved beside DRG_Cycling. A
// file without the key leaves the RESET default standing.
const option_drg_cfg: bool = build_options.option_drg_cfg;
const FOR_MAX_LOOPS: u32 = if (state_old_hw) 4 else 18;
const FOR_LOOP_TABLE_BYTES: u32 = FOR_MAX_LOOPS * 10; // sizeof(forLoop_t) is 10 on every target
// backup.cfg is the simulator's own state store: upstream wraps the whole file
// in `#if defined(PC_BUILD)`, and its two entry points are reached only from the
// GTK shell. Compiling the bodies out on firmware keeps several hundred bytes of
// field-name strings and writer code out of a flash budget that has none to give.
const is_dmcp_build = @import("builtin").target.os.tag == .freestanding;
const calc_model_user_id: u16 = build_options.calc_model_user_id;

const FILE_OK: c_int = 1;
const ioPathBackup: c_int = 4;
const ioModeWrite: c_int = 1;
const ITM_NOP: u16 = 1542;
const NOPARAM: u16 = 9876;
const StrLgIntHeader = abi.StrLgIntHeader;
const REAL34_SIZE_IN_BYTES: usize = 16;
const BACKUP_VERSION: u32 = 1023; // C saveRestoreBackup.c:14 (retainedPageFirstItem[], the page each retained-page softmenu reopens on; lastCatalogPosition[] written as hexDump, every catalog; 1021 and 1022 are taken on FIN-12C, 1021 also on units/algebra)
const INVALID_VARIABLE: i16 = 2199;
const CM_CONFIRMATION: u8 = 11;
const RM_HALF_EVEN: u8 = 0;
const RM_HALF_UP: u8 = 1;
const RM_FLOOR: u8 = 6;
const DRM_DFLT: u8 = RM_HALF_UP;
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
extern fn printf(fmt: [*:0]const u8, ...) c_int;
// backupFileName: the model's own backup file.
inline fn backupFileName() [*:0]const u8 {
    return if (calc_model_user_id == USER_R47) "backupR47.cfg" else "backup.cfg";
}
extern fn ioFileWrite(buffer: ?*const anyopaque, size: u32) void;
extern fn decNumberToString(src: [*c]const u8, dst: [*c]u8) [*c]u8; // realToString
extern fn decQuadToString(src: [*c]const u8, dst: [*c]u8) [*c]u8; // real34ToString
extern fn decQuadIsInfinite(src: [*c]const u8) u32; // real34IsInfinite
extern fn decQuadZero(dst: [*c]u8) [*c]u8; // real34SetZero
// The restored I%/a is the annual rate; tvm.zig converts it into the per-period i%.
const RESERVED_VARIABLE_IPONA: i16 = 2035;
extern fn tvmSyncIp(written: i16) void;
extern fn graFontCheck() void; // screen.zig: a GRFNT code missing from the font table becomes 20
const DECINF: u8 = 0x40; // decNumberIsInfinite(dn) = (dn->bits & DECINF) != 0; bits@8
const real_t = abi.Real;
// REAL_SIZE_IN_BYTES(34) = 10 + sizeof(decNumberUnit=2) * (REAL_MAX_DIGITS(34)=39 / DECDPUN=3) = 36.
const REAL_SIZE_IN_BYTES_34: u32 = 36; // C realType.h REAL_SIZE_IN_BYTES(34)
extern fn ioFileOpen(path: c_int, mode: c_int) c_int;
extern fn ioFileClose() void;
const refreshScreen = abi.host.requestRefresh; // routed through the host-callback boundary
extern var calcModel: u8;
extern var calcMode: u8;
extern var previousCalcMode: u8;
extern var graphVariabl1: i16;
extern var freeMemoryRegions: ?[*]abi.FreeMemoryRegion; // pointer on host (NEW_HW)
extern var allocatedMemoryRegions: [4]u8; // array on host (!DMCP_BUILD) -> &[0]
extern var numberOfFreeMemoryRegions: i32;
extern var numberOfAllocatedMemoryRegions: i32;
extern var globalRegister: ?[*]abi.RegisterHeader; // pointer on host (NEW_HW)
extern var ram: [*c]u32;
extern var graMod: u8;
extern var graFont: u8;
extern var longPressFactor: i16;
extern var doublePressFactor: i16;
extern var alphaRegister: u16;
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
extern var softmenuStack: [8]abi.SoftmenuStack; // SOFTMENU_STACK_SIZE
extern var kbd_usr: [666]u8;
extern var userMenuItems: [360]u8;
extern var userAlphaItems: [360]u8;
extern var lastTemp: [16]u8;
extern var lastStateFileOpened: [32]u8;
// c47.c declares these under PC_BUILD only: the firmware has no file chooser.
// defines.h C47_PATH_MAX, at the 1024 fallback z47 binds every path copy to.
const C47_PATH_MAX = 1024;
extern var lastFolderData: [C47_PATH_MAX]u8;
extern var lastFolderState: [C47_PATH_MAX]u8;
extern var lastFolderPrograms: [C47_PATH_MAX]u8;
extern var lastI: [2]u8;
extern var lastJ: [2]u8;
extern var lastFunc: [2]u8;
extern var lastParam: [2]u8;
extern var tam: abi.TamState;
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
extern fn set_def_Input_Default() callconv(.c) void;
extern fn grpGroupingHexBinDefault() callconv(.c) void;
extern fn setRoundingMode(RM: u16) void;
extern var significantDigits: [1]u8;
extern var fractionDigits: [1]u8;
extern var shortIntegerMode: [1]u8;
extern var currentAngularMode: [4]u8;
extern var scrLock: [1]u8;
extern var roundingMode: [1]u8;
extern var displayRoundingMode: [1]u8;
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
extern var numScreensNumericFontBold: [1]u8;
extern var numLinesNumericFontBold: [1]u8;
extern var graphToRemainOnScreen: u8;
extern var programmableMenu: [332]u8;
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
extern var lastCatalogPosition: [48]u8; // int16[NUMBER_OF_CATALOGS], 24 catalogs; a hexDump writes the whole array, so the size is the C's sizeof
extern var retainedPageFirstItem: [4]u8; // int16[NUMBER_OF_RETAINED_PAGE_MENUS]
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
extern var numberOfStructureLabels: [2]u8;
extern var forLoopTable: [FOR_LOOP_TABLE_BYTES]u8;
// structured.c owns the table; a restore clears it first so a file written before
// the structures leaves no loop running.
extern fn forClearLoops() void;
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
extern var roundedTicks: [1]u8;
extern var PLOT_AXIS: [1]u8;
extern var PLOT_ZMY: [1]u8;
extern var PLOT_ZOOM: [1]u8;
extern var plotmode: [1]u8;
extern var tick_int_x: [8]u8;
extern var tick_int_y: [8]u8;
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
extern var currentDerivProgram: [2]u8;
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
extern var Norm_Key_00: abi.NormKey;
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
extern var drgConfig: u8;
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
extern var grpGroupingHex: [1]u8;
extern var grpGroupingBin: [1]u8;
extern var firstDayOfWeek: [1]u8;
extern var firstWeekOfYearDay: [1]u8;
extern var dispBase: [1]u8;
extern var printerState: abi.PrinterState;
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
    return .{ .ram_base = @intFromPtr(ram), .ram_size_in_blocks = build_options.ram_size_in_blocks, .old_hw = state_old_hw };
}
fn streq(a: [*c]const u8, b: [*c]const u8) bool {
    return strcmp(a, b) == 0;
}
fn rd(comptime T: type, buffer: [*]const u8) T {
    return std.mem.bytesToValue(T, buffer[0..@sizeOf(T)]);
}
/// Store `value` at `buffer`, whose alignment the caller does not promise.
fn wr(comptime T: type, buffer: [*]u8, value: T) void {
    @memcpy(buffer[0..@sizeOf(T)], std.mem.asBytes(&value));
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
fn sv(buffer: [*]const u8, size: u32, name: [*c]const u8, type_str: [*c]const u8) void {
    var value: [200]u8 = undefined;
    const v: [*c]u8 = &value[0];
    const buf: [*c]const u8 = buffer;
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
    if (comptime is_dmcp_build) return;
    const ok = (calc_model_user_id == USER_R47 and (calcModel == USER_R47f_g or calcModel == USER_R47fg_g or calcModel == USER_R47fg_bk or calcModel == USER_R47bk_fg)) or
        (calc_model_user_id == USER_C47 and (calcModel == USER_C47 or calcModel == USER_DM42));
    if (!ok) return;
    if (ioFileOpen(ioPathBackup, ioModeWrite) != FILE_OK) return;
    if (calcMode == CM_CONFIRMATION) {
        calcMode = previousCalcMode;
        refreshScreen(90);
    }
    var bv: u32 = BACKUP_VERSION;
    sv(std.mem.asBytes(&bv), 4, "backupVersion", "uint32");
    var rsib: u32 = geometry().ram_size_in_blocks;
    sv(std.mem.asBytes(&rsib), 4, "ramSizeInBlocks", "uint32");
    sv(std.mem.asBytes(&numberOfFreeMemoryRegions), 4, "numberOfFreeMemoryRegions", "int32");
    sv(std.mem.asBytes(&freeMemoryRegions.?[0]), FREE_MEM_REGION_SIZE * @as(u32, @bitCast(numberOfFreeMemoryRegions)), "freeMemoryRegions", "hexDump");
    sv(std.mem.asBytes(&numberOfAllocatedMemoryRegions), 4, "numberOfAllocatedMemoryRegions", "int32");
    sv(std.mem.asBytes(&allocatedMemoryRegions[0]), FREE_MEM_REGION_SIZE * @as(u32, @bitCast(numberOfAllocatedMemoryRegions)), "allocatedMemoryRegions", "hexDump");
    sv(std.mem.asBytes(&globalRegister.?[0]), REGISTER_HEADER_SIZE * NUMBER_OF_GLOBAL_REGISTERS, "globalRegister", "hexDump");
    sv(std.mem.asBytes(&calcMode), 1, "calcMode", "uint8");
    sv(std.mem.asBytes(&previousCalcMode), 1, "previousCalcMode", "uint8");
    sv(std.mem.asBytes(&graphToRemainOnScreen), 1, "graphToRemainOnScreen", "bool");
    sv(std.mem.asBytes(&calcModel), 1, "calcModel", "uint8");
    sv(std.mem.asBytes(&globalFlags[0]), 16, "globalFlags", "hexDump");
    sv(std.mem.asBytes(&errorMessage[0]), 512, "errorMessage", "hexDump");
    sv(std.mem.asBytes(&aimBuffer[0]), 1024, "aimBuffer", "hexDump");
    sv(std.mem.asBytes(&nimBufferDisplay[0]), 200, "nimBufferDisplay", "hexDump");
    sv(std.mem.asBytes(&tamBuffer[0]), 56, "tamBuffer", "hexDump");
    sv(std.mem.asBytes(&asmBuffer[0]), 5, "asmBuffer", "hexDump");
    sv(std.mem.asBytes(&oldTime[0]), 8, "oldTime", "hexDump");
    sv(std.mem.asBytes(&dateTimeString[0]), 12, "dateTimeString", "hexDump");
    sv(std.mem.asBytes(&softmenuStack), @sizeOf(@TypeOf(softmenuStack)), "softmenuStack", "hexDump");
    if (comptime option_structured_pgm) {
        sv(std.mem.asBytes(&forLoopTable[0]), FOR_LOOP_TABLE_BYTES, "forLoopTable", "hexDump");
    }
    sv(std.mem.asBytes(&kbd_usr[0]), 666, "kbd_usr", "hexDump");
    sv(std.mem.asBytes(&userMenuItems[0]), 360, "userMenuItems", "hexDump");
    sv(std.mem.asBytes(&userAlphaItems[0]), 360, "userAlphaItems", "hexDump");
    sv(std.mem.asBytes(&lastTemp[0]), 16, "lastTemp", "hexDump");
    sv(std.mem.asBytes(&lastStateFileOpened[0]), 32, "lastStateFileOpened", "hexDump");
    if (comptime !is_dmcp_build) {
        sv(std.mem.asBytes(&lastFolderData[0]), C47_PATH_MAX, "lastFolderData", "hexDump");
        sv(std.mem.asBytes(&lastFolderState[0]), C47_PATH_MAX, "lastFolderState", "hexDump");
        sv(std.mem.asBytes(&lastFolderPrograms[0]), C47_PATH_MAX, "lastFolderPrograms", "hexDump");
    }
    sv(std.mem.asBytes(&lastI[0]), 2, "lastI", "int16");
    sv(std.mem.asBytes(&lastJ[0]), 2, "lastJ", "int16");
    sv(std.mem.asBytes(&lastFunc[0]), 2, "lastFunc", "int16");
    sv(std.mem.asBytes(&lastParam[0]), 2, "lastParam", "int16");
    sv(std.mem.asBytes(&tam.mode), @sizeOf(@TypeOf(tam.mode)), "tam.mode", "uint16");
    sv(std.mem.asBytes(&tam.function), @sizeOf(@TypeOf(tam.function)), "tam.function", "int16");
    sv(std.mem.asBytes(&tam.alpha), @sizeOf(@TypeOf(tam.alpha)), "tam.alpha", "bool");
    sv(std.mem.asBytes(&tam.currentOperation), @sizeOf(@TypeOf(tam.currentOperation)), "tam.currentOperation", "int16");
    sv(std.mem.asBytes(&tam.dot), @sizeOf(@TypeOf(tam.dot)), "tam.dot", "bool");
    sv(std.mem.asBytes(&tam.indirect), @sizeOf(@TypeOf(tam.indirect)), "tam.indirect", "bool");
    sv(std.mem.asBytes(&tam.digitsSoFar), @sizeOf(@TypeOf(tam.digitsSoFar)), "tam.digitsSoFar", "int16");
    sv(std.mem.asBytes(&tam.value), @sizeOf(@TypeOf(tam.value)), "tam.value", "int16");
    sv(std.mem.asBytes(&tam.min), @sizeOf(@TypeOf(tam.min)), "tam.min", "int16");
    sv(std.mem.asBytes(&tam.max), @sizeOf(@TypeOf(tam.max)), "tam.max", "int16");
    sv(std.mem.asBytes(&rbrRegister[0]), 2, "rbrRegister", "int16");
    sv(std.mem.asBytes(&numberOfNamedVariables[0]), 2, "numberOfNamedVariables", "int16");
    sv(std.mem.asBytes(&xCursor[0]), 4, "xCursor", "uint32");
    sv(std.mem.asBytes(&yCursor[0]), 4, "yCursor", "uint32");
    sv(std.mem.asBytes(&firstGregorianDay[0]), 4, "firstGregorianDay", "uint32");
    sv(std.mem.asBytes(&denMax[0]), 4, "denMax", "uint32");
    sv(std.mem.asBytes(&lastDenominator[0]), 4, "lastDenominator", "uint32");
    sv(std.mem.asBytes(&currentRegisterBrowserScreen[0]), 2, "currentRegisterBrowserScreen", "int16");
    sv(std.mem.asBytes(&currentFntScr[0]), 1, "currentFntScr", "uint8");
    sv(std.mem.asBytes(&currentFlgScr[0]), 1, "currentFlgScr", "uint8");
    sv(std.mem.asBytes(&displayFormat[0]), 1, "displayFormat", "uint8");
    sv(std.mem.asBytes(&displayFormatDigits[0]), 1, "displayFormatDigits", "uint8");
    sv(std.mem.asBytes(&timeDisplayFormatDigits[0]), 1, "timeDisplayFormatDigits", "uint8");
    sv(std.mem.asBytes(&shortIntegerWordSize[0]), 1, "shortIntegerWordSize", "uint8");
    sv(std.mem.asBytes(&significantDigits[0]), 1, "significantDigits", "uint8");
    sv(std.mem.asBytes(&fractionDigits[0]), 1, "fractionDigits", "uint8");
    sv(std.mem.asBytes(&shortIntegerMode[0]), 1, "shortIntegerMode", "uint8");
    sv(std.mem.asBytes(&currentAngularMode[0]), 4, "currentAngularMode", "uint32");
    sv(std.mem.asBytes(&scrLock[0]), 1, "scrLock", "uint8");
    sv(std.mem.asBytes(&displayRoundingMode[0]), 1, "displayRoundingMode", "uint8");
    sv(std.mem.asBytes(&roundingMode[0]), 1, "roundingMode", "uint8");
    sv(std.mem.asBytes(&nextChar[0]), 1, "nextChar", "uint8");
    sv(std.mem.asBytes(&alphaCase[0]), 1, "alphaCase", "uint8");
    sv(std.mem.asBytes(&hourGlassIconEnabled[0]), 1, "hourGlassIconEnabled", "bool");
    sv(std.mem.asBytes(&watchIconEnabled[0]), 1, "watchIconEnabled", "bool");
    sv(std.mem.asBytes(&serialIOIconEnabled[0]), 1, "serialIOIconEnabled", "bool");
    sv(std.mem.asBytes(&printerIconEnabled[0]), 1, "printerIconEnabled", "bool");
    sv(std.mem.asBytes(&programRunStop[0]), 1, "programRunStop", "uint8");
    sv(std.mem.asBytes(&entryStatus[0]), 1, "entryStatus", "uint8");
    sv(std.mem.asBytes(&cursorEnabled[0]), 1, "cursorEnabled", "uint8");
    sv(std.mem.asBytes(&rbr1stDigit[0]), 1, "rbr1stDigit", "bool");
    sv(std.mem.asBytes(&shiftF[0]), 1, "shiftF", "bool");
    sv(std.mem.asBytes(&shiftG[0]), 1, "shiftG", "bool");
    sv(std.mem.asBytes(&rbrMode[0]), 1, "rbrMode", "uint8");
    sv(std.mem.asBytes(&showContent[0]), 1, "showContent", "bool");
    sv(std.mem.asBytes(&numScreensNumericFont[0]), 1, "numScreensNumericFont", "uint8");
    sv(std.mem.asBytes(&numScreensNumericFontBold[0]), 1, "numScreensNumericFontBold", "uint8");
    sv(std.mem.asBytes(&numLinesNumericFont[0]), 1, "numLinesNumericFont", "uint8");
    sv(std.mem.asBytes(&numLinesNumericFontBold[0]), 1, "numLinesNumericFontBold", "uint8");
    sv(std.mem.asBytes(&numScreensStandardFont[0]), 1, "numScreensStandardFont", "uint8");
    sv(std.mem.asBytes(&numLinesStandardFont[0]), 1, "numLinesStandardFont", "uint8");
    sv(std.mem.asBytes(&numScreensTinyFont[0]), 1, "numScreensTinyFont", "uint8");
    sv(std.mem.asBytes(&numLinesTinyFont[0]), 1, "numLinesTinyFont", "uint8");
    sv(std.mem.asBytes(&lastErrorCode[0]), 1, "lastErrorCode", "uint8");
    sv(std.mem.asBytes(&previousErrorCode[0]), 1, "previousErrorCode", "uint8");
    sv(std.mem.asBytes(&nimNumberPart[0]), 1, "nimNumberPart", "uint8");
    sv(std.mem.asBytes(&displayStack[0]), 1, "displayStack", "uint8");
    sv(std.mem.asBytes(&hexDigits[0]), 1, "hexDigits", "uint8");
    sv(std.mem.asBytes(&errorMessageRegisterLine[0]), 2, "errorMessageRegisterLine", "int16");
    sv(std.mem.asBytes(&shortIntegerMask[0]), 8, "shortIntegerMask", "uint64");
    sv(std.mem.asBytes(&shortIntegerSignBit[0]), 8, "shortIntegerSignBit", "uint64");
    sv(std.mem.asBytes(&temporaryInformation[0]), 1, "temporaryInformation", "uint8");
    sv(std.mem.asBytes(&funcOK[0]), 1, "funcOK", "bool");
    sv(std.mem.asBytes(&screenChange[0]), 1, "screenChange", "bool");
    sv(std.mem.asBytes(&exponentSignLocation[0]), 2, "exponentSignLocation", "int16");
    sv(std.mem.asBytes(&denominatorLocation[0]), 2, "denominatorLocation", "int16");
    sv(std.mem.asBytes(&imaginaryExponentSignLocation[0]), 2, "imaginaryExponentSignLocation", "int16");
    sv(std.mem.asBytes(&imaginaryMantissaSignLocation[0]), 2, "imaginaryMantissaSignLocation", "int16");
    sv(std.mem.asBytes(&lineTWidth[0]), 2, "lineTWidth", "int16");
    sv(std.mem.asBytes(&lastIntegerBase[0]), 4, "lastIntegerBase", "uint32");
    sv(std.mem.asBytes(&c47MemInBlocks[0]), 8, "c47MemInBlocks", "uint64");
    sv(std.mem.asBytes(&gmpMemInBytes[0]), 8, "gmpMemInBytes", "uint64");
    sv(std.mem.asBytes(&catalog[0]), 2, "catalog", "int16");
    sv(std.mem.asBytes(&lastCatalogPosition[0]), 48, "lastCatalogPosition", "hexDump");
    sv(std.mem.asBytes(&retainedPageFirstItem[0]), 4, "retainedPageFirstItem", "hexDump");
    sv(std.mem.asBytes(&displayValueX[0]), 80, "displayValueX", "hexDump");
    sv(std.mem.asBytes(&pcg32_global[0]), 16, "pcg32_global", "hexDump");
    sv(std.mem.asBytes(&exponentLimit[0]), 2, "exponentLimit", "int16");
    sv(std.mem.asBytes(&exponentHideLimit[0]), 2, "exponentHideLimit", "int16");
    sv(std.mem.asBytes(&keyActionProcessed[0]), 1, "keyActionProcessed", "bool");
    sv(std.mem.asBytes(&systemFlags0[0]), 8, "systemFlags", "uint64");
    sv(std.mem.asBytes(&systemFlags1[0]), 8, "systemFlags1", "uint64");
    sv(std.mem.asBytes(&savedSystemFlags0[0]), 8, "savedSystemFlags", "uint64");
    sv(std.mem.asBytes(&savedSystemFlags1[0]), 8, "savedSystemFlags1", "uint64");
    sv(std.mem.asBytes(&thereIsSomethingToUndo[0]), 1, "thereIsSomethingToUndo", "bool");
    sv(std.mem.asBytes(&freeProgramBytes[0]), 2, "freeProgramBytes", "uint16");
    sv(std.mem.asBytes(&firstDisplayedLocalStepNumber[0]), 2, "firstDisplayedLocalStepNumber", "uint16");
    sv(std.mem.asBytes(&numberOfLabels[0]), 2, "numberOfLabels", "uint16");
    sv(std.mem.asBytes(&numberOfStructureLabels[0]), 2, "numberOfStructureLabels", "uint16");
    sv(std.mem.asBytes(&numberOfPrograms[0]), 2, "numberOfPrograms", "uint16");
    sv(std.mem.asBytes(&currentLocalStepNumber[0]), 2, "currentLocalStepNumber", "uint16");
    sv(std.mem.asBytes(&currentProgramNumber[0]), 2, "currentProgramNumber", "uint16");
    sv(std.mem.asBytes(&lastProgramListEnd[0]), 1, "lastProgramListEnd", "bool");
    sv(std.mem.asBytes(&programListEnd[0]), 1, "programListEnd", "bool");
    sv(std.mem.asBytes(&allSubroutineLevels[0]), 4, "allSubroutineLevels", "uint32");
    sv(std.mem.asBytes(&pemCursorIsZerothStep[0]), 1, "pemCursorIsZerothStep", "bool");
    sv(std.mem.asBytes(&skippedStackLines[0]), 1, "skippedStackLines", "bool");
    sv(std.mem.asBytes(&iterations[0]), 1, "iterations", "bool");
    sv(std.mem.asBytes(&numberOfTamMenusToPop[0]), 2, "numberOfTamMenusToPop", "int16");
    sv(std.mem.asBytes(&lrSelection[0]), 2, "lrSelection", "uint16");
    sv(std.mem.asBytes(&lrSelectionUndo[0]), 2, "lrSelectionUndo", "uint16");
    sv(std.mem.asBytes(&amortP1[0]), 2, "amortP1", "uint16");
    sv(std.mem.asBytes(&amortP2[0]), 2, "amortP2", "uint16");
    sv(std.mem.asBytes(&lrChosen[0]), 2, "lrChosen", "uint16");
    sv(std.mem.asBytes(&lrChosenUndo[0]), 2, "lrChosenUndo", "uint16");
    sv(std.mem.asBytes(&lastPlotMode[0]), 2, "lastPlotMode", "uint16");
    sv(std.mem.asBytes(&plotSelection[0]), 2, "plotSelection", "uint16");
    sv(std.mem.asBytes(&roundedTicks[0]), 1, "roundedTicks", "bool");
    sv(std.mem.asBytes(&PLOT_AXIS[0]), 1, "PLOT_AXIS", "bool");
    sv(std.mem.asBytes(&PLOT_ZMY[0]), 1, "PLOT_ZMY", "int8");
    sv(std.mem.asBytes(&PLOT_ZOOM[0]), 1, "PLOT_ZOOM", "uint8");
    sv(std.mem.asBytes(&plotmode[0]), 1, "plotmode", "int8");
    sv(std.mem.asBytes(&tick_int_x[0]), 8, "tick_int_x", "double");
    sv(std.mem.asBytes(&tick_int_y[0]), 8, "tick_int_y", "double");
    sv(std.mem.asBytes(x_min), REAL_SIZE_IN_BYTES_34, "x_min", "real");
    sv(std.mem.asBytes(x_max), REAL_SIZE_IN_BYTES_34, "x_max", "real");
    sv(std.mem.asBytes(y_min), REAL_SIZE_IN_BYTES_34, "y_min", "real");
    sv(std.mem.asBytes(y_max), REAL_SIZE_IN_BYTES_34, "y_max", "real");
    sv(std.mem.asBytes(&xzero[0]), 4, "xzero", "uint32");
    sv(std.mem.asBytes(&yzero[0]), 4, "yzero", "uint32");
    sv(std.mem.asBytes(&regStatsXY[0]), 2, "regStatsXY", "int16");
    sv(std.mem.asBytes(&matrixIndex[0]), 2, "matrixIndex", "uint16");
    sv(std.mem.asBytes(&shadowI[0]), 2, "shadowI", "int16");
    sv(std.mem.asBytes(&shadowJ[0]), 2, "shadowJ", "int16");
    sv(std.mem.asBytes(&currentViewRegister[0]), 2, "currentViewRegister", "uint16");
    sv(std.mem.asBytes(&currentSolverStatus[0]), 2, "currentSolverStatus", "uint16");
    sv(std.mem.asBytes(&currentSolverProgram[0]), 2, "currentSolverProgram", "uint16");
    sv(std.mem.asBytes(&currentDerivProgram[0]), 2, "currentDerivProgram", "uint16");
    sv(std.mem.asBytes(&currentSolverVariable[0]), 2, "currentSolverVariable", "uint16");
    sv(std.mem.asBytes(&numberOfFormulae[0]), 2, "numberOfFormulae", "uint16");
    sv(std.mem.asBytes(&currentFormula[0]), 2, "currentFormula", "uint16");
    sv(std.mem.asBytes(&numberOfUserMenus[0]), 2, "numberOfUserMenus", "uint16");
    sv(std.mem.asBytes(&currentUserMenu[0]), 2, "currentUserMenu", "uint16");
    sv(std.mem.asBytes(&userKeyLabelSize[0]), 2, "userKeyLabelSize", "uint16");
    sv(std.mem.asBytes(&timerCraAndDeciseconds[0]), 1, "timerCraAndDeciseconds", "uint8");
    sv(std.mem.asBytes(&timerValue[0]), 4, "timerValue", "uint32");
    sv(std.mem.asBytes(&timerTotalTime[0]), 4, "timerTotalTime", "uint32");
    sv(std.mem.asBytes(&currentInputVariable[0]), 2, "currentInputVariable", "uint16");
    sv(std.mem.asBytes(&SAVED_SIGMA_LASTX[0]), 60, "SAVED_SIGMA_LASTX", "real");
    sv(std.mem.asBytes(&SAVED_SIGMA_LASTY[0]), 60, "SAVED_SIGMA_LASTY", "real");
    sv(std.mem.asBytes(&SAVED_SIGMA_lastAddRem[0]), 1, "SAVED_SIGMA_lastAddRem", "int8");
    sv(std.mem.asBytes(&currentMvarLabel[0]), 2, "currentMvarLabel", "uint16");
    sv(std.mem.asBytes(&plotStatMx[0]), 8, "plotStatMx", "hexDump");
    sv(std.mem.asBytes(&drawHistogram[0]), 1, "drawHistogram", "uint8");
    sv(std.mem.asBytes(&plotStatScale[0]), 1, "plotStatScale", "uint8");
    sv(std.mem.asBytes(&statMx[0]), 8, "statMx", "hexDump");
    sv(std.mem.asBytes(&lrSelectionHistobackup[0]), 2, "lrSelectionHistobackup", "uint16");
    sv(std.mem.asBytes(&lrChosenHistobackup[0]), 2, "lrChosenHistobackup", "uint16");
    sv(std.mem.asBytes(&loBinR[0]), 16, "loBinR", "real34");
    sv(std.mem.asBytes(&nBins[0]), 16, "nBins", "real34");
    sv(std.mem.asBytes(&hiBinR[0]), 16, "hiBinR", "real34");
    sv(std.mem.asBytes(&histElementXorY[0]), 2, "histElementXorY", "int16");
    sv(std.mem.asBytes(&screenUpdatingMode[0]), 1, "screenUpdatingMode", "uint8");
    sv(std.mem.asBytes(&Norm_Key_00.func), @sizeOf(@TypeOf(Norm_Key_00.func)), "Norm_Key_00.func", "int16");
    sv(std.mem.asBytes(&Norm_Key_00.funcParam), @sizeOf(@TypeOf(Norm_Key_00.funcParam)), "Norm_Key_00.funcParam", "hexDump");
    sv(std.mem.asBytes(&Norm_Key_00.used), @sizeOf(@TypeOf(Norm_Key_00.used)), "Norm_Key_00.used", "bool");
    sv(std.mem.asBytes(&Input_Default[0]), 1, "Input_Default", "uint8");
    sv(std.mem.asBytes(&T_cursorPos[0]), 2, "T_cursorPos", "int16");
    sv(std.mem.asBytes(&multiEdLines[0]), 1, "multiEdLines", "uint8");
    sv(std.mem.asBytes(&current_cursor_x[0]), 2, "current_cursor_x", "uint16");
    sv(std.mem.asBytes(&current_cursor_y[0]), 2, "current_cursor_y", "uint16");
    sv(std.mem.asBytes(&xMultiLineEdOffset[0]), 1, "xMultiLineEdOffset", "uint8");
    sv(std.mem.asBytes(&yMultiLineEdOffset[0]), 1, "yMultiLineEdOffset", "uint8");
    sv(std.mem.asBytes(&showRegis[0]), 2, "showRegis", "int16");
    sv(std.mem.asBytes(&overrideShowBottomLine[0]), 1, "overrideShowBottomLine", "uint8");
    sv(std.mem.asBytes(&displayStackSHOIDISP[0]), 1, "displayStackSHOIDISP", "uint8");
    sv(std.mem.asBytes(&ListXYposition[0]), 2, "ListXYposition", "int16");
    sv(std.mem.asBytes(&DRG_Cycling[0]), 1, "DRG_Cycling", "uint8");
    if (comptime option_drg_cfg) sv(std.mem.asBytes(&drgConfig), 1, "drgConfig", "uint8");
    sv(std.mem.asBytes(&lastFlgScr[0]), 1, "lastFlgScr", "uint8");
    sv(std.mem.asBytes(&displayAIMbufferoffset[0]), 2, "displayAIMbufferoffset", "int16");
    sv(std.mem.asBytes(&bcdDisplaySign[0]), 1, "bcdDisplaySign", "uint8");
    sv(std.mem.asBytes(&DM_Cycling[0]), 1, "DM_Cycling", "uint8");
    sv(std.mem.asBytes(&LongPressM[0]), 1, "LongPressM", "uint8");
    sv(std.mem.asBytes(&LongPressF[0]), 1, "LongPressF", "uint8");
    sv(std.mem.asBytes(&currentAsnScr[0]), 1, "currentAsnScr", "uint8");
    sv(std.mem.asBytes(&gapItemLeft[0]), 2, "gapItemLeft", "uint16");
    sv(std.mem.asBytes(&gapItemRight[0]), 2, "gapItemRight", "uint16");
    sv(std.mem.asBytes(&gapItemRadix[0]), 2, "gapItemRadix", "uint16");
    sv(std.mem.asBytes(&lastCenturyHighUsed[0]), 2, "lastCenturyHighUsed", "uint16");
    sv(std.mem.asBytes(&grpGroupingLeft[0]), 1, "grpGroupingLeft", "uint8");
    sv(std.mem.asBytes(&grpGroupingGr1LeftOverflow[0]), 1, "grpGroupingGr1LeftOverflow", "uint8");
    sv(std.mem.asBytes(&grpGroupingGr1Left[0]), 1, "grpGroupingGr1Left", "uint8");
    sv(std.mem.asBytes(&grpGroupingRight[0]), 1, "grpGroupingRight", "uint8");
    sv(std.mem.asBytes(&grpGroupingHex[0]), 1, "grpGroupingHex", "uint8");
    sv(std.mem.asBytes(&grpGroupingBin[0]), 1, "grpGroupingBin", "uint8");
    sv(std.mem.asBytes(&firstDayOfWeek[0]), 1, "firstDayOfWeek", "uint8");
    sv(std.mem.asBytes(&firstWeekOfYearDay[0]), 1, "firstWeekOfYearDay", "uint8");
    sv(std.mem.asBytes(&dispBase[0]), 1, "dispBase", "uint8");
    sv(std.mem.asBytes(&printerState.print_on), @sizeOf(@TypeOf(printerState.print_on)), "printerState.print_on", "bool");
    sv(std.mem.asBytes(&printerState.printer_model), @sizeOf(@TypeOf(printerState.printer_model)), "printerState.printer_model", "uint8");
    sv(std.mem.asBytes(&printerState.delay), @sizeOf(@TypeOf(printerState.delay)), "printerState.delay", "uint16");
    sv(std.mem.asBytes(&programmableMenu[0]), 332, "programmableMenu", "hexDump");
    {
        var cf: i8 = cursorFontId();
        sv(std.mem.asBytes(&cf), 1, "cursorFont", "int8");
    }
    graphVariabl1 = INVALID_VARIABLE;
    sv(std.mem.asBytes(&graphVariabl1), 2, "graphVariabl1", "int16");
    {
        var v: u32 = c47ptr(allNamedVariables);
        sv(std.mem.asBytes(&v), 4, "allNamedVariables", "c47Ptr");
    }
    {
        var v: u32 = c47ptr(allFormulae);
        sv(std.mem.asBytes(&v), 4, "allFormulae", "c47Ptr");
    }
    {
        var v: u32 = c47ptr(userMenus);
        sv(std.mem.asBytes(&v), 4, "userMenus", "c47Ptr");
    }
    {
        var v: u32 = c47ptr(userKeyLabel);
        sv(std.mem.asBytes(&v), 4, "userKeyLabel", "c47Ptr");
    }
    {
        var v: u32 = c47ptr(statisticalSumsPointer);
        sv(std.mem.asBytes(&v), 4, "statisticalSumsPointer", "c47Ptr");
    }
    {
        var v: u32 = c47ptr(savedStatisticalSumsPointer);
        sv(std.mem.asBytes(&v), 4, "savedStatisticalSumsPointer", "c47Ptr");
    }
    {
        var v: u32 = c47ptr(labelList);
        sv(std.mem.asBytes(&v), 4, "labelList", "c47Ptr");
    }
    {
        var v: u32 = c47ptr(programList);
        sv(std.mem.asBytes(&v), 4, "programList", "c47Ptr");
    }
    {
        var v: u32 = c47ptr(currentSubroutineLevelData);
        sv(std.mem.asBytes(&v), 4, "currentSubroutineLevelData", "c47Ptr");
    }
    {
        var v: u32 = c47ptr(currentLocalFlags);
        sv(std.mem.asBytes(&v), 4, "currentLocalFlags", "c47Ptr");
    }
    {
        var v: u32 = c47ptr(currentLocalRegisters);
        sv(std.mem.asBytes(&v), 4, "currentLocalRegisters", "c47Ptr");
    }
    {
        var v: u32 = c47ptr(beginOfProgramMemory);
        sv(std.mem.asBytes(&v), 4, "beginOfProgramMemory", "c47Ptr");
    }
    {
        var v: u32 = offWithin(beginOfProgramMemory);
        sv(std.mem.asBytes(&v), 4, "beginOfProgramMemoryOffset", "uint32");
    }
    {
        var v: u32 = c47ptr(firstFreeProgramByte);
        sv(std.mem.asBytes(&v), 4, "firstFreeProgramByte", "c47Ptr");
    }
    {
        var v: u32 = offWithin(firstFreeProgramByte);
        sv(std.mem.asBytes(&v), 4, "firstFreeProgramByteOffset", "uint32");
    }
    {
        var v: u32 = c47ptr(firstDisplayedStep);
        sv(std.mem.asBytes(&v), 4, "firstDisplayedStep", "c47Ptr");
    }
    {
        var v: u32 = offWithin(firstDisplayedStep);
        sv(std.mem.asBytes(&v), 4, "firstDisplayedStepOffset", "uint32");
    }
    {
        var v: u32 = c47ptr(currentStep);
        sv(std.mem.asBytes(&v), 4, "currentStep", "c47Ptr");
    }
    {
        var v: u32 = offWithin(currentStep);
        sv(std.mem.asBytes(&v), 4, "currentStepOffset", "uint32");
    }
    // The dump reads the whole pool, free blocks and the unwritten tail of a
    // claimed one included, which memcheck holds as no-access or undefined (see
    // free_list.zig). It is the one reader entitled to those bytes.
    std.valgrind.memcheck.makeMemDefined(poolBytes());
    sv(poolBytes().ptr, (geometry().ram_size_in_blocks) << 2, "ram", "hexDump");
    closeFreeRegions();

    sv(std.mem.asBytes(&graMod), 1, "graMod", "uint8");
    if (comptime option_atext_fonts) {
        sv(std.mem.asBytes(&graFont), 1, "graFont", "uint8");
    }
    sv(std.mem.asBytes(&longPressFactor), 2, "longPressFactor", "int16");
    sv(std.mem.asBytes(&doublePressFactor), 2, "doublePressFactor", "int16");

    sv(std.mem.asBytes(&alphaRegister), 2, "alphaRegister", "uint16");

    ioFileClose();
}

// ===================== RESTORE side =====================
// labelList/savedStatisticalSumsPointer are pointer globals not declared above.
// --- backup.cfg parser + typed value deserializer (host-only) ---
extern fn ioEof() c_int;
/// C's malloc, read as the bytes this owner asks it for: aligned for any object,
/// at least 8 on every target z47 builds.
extern fn malloc(n: usize) ?[*]align(8) u8;
extern fn free(p: ?*anyopaque) void;
extern fn strncmp(a: [*c]const u8, b: [*c]const u8, n: usize) c_int;
extern fn decNumberFromString(dst: *abi.Real, src: [*c]const u8, ctx: *RealContext) *abi.Real; // stringToReal
extern fn decQuadFromString(dst: *abi.Real34, src: [*c]const u8, ctx: *RealContext) *abi.Real34; // stringToReal34
const RealContext = abi.RealContext;
extern var ctxtReal34: RealContext;
extern var ctxtReal39: RealContext;
extern var ctxtReal51: RealContext;
extern var ctxtReal75: RealContext;
// decContext.h status bits (DECEXTFLAG): a conversion that raised any of these did
// not read the text as the number it names.
const DEC_Conversion_syntax: u32 = 0x00000001;
const DEC_Inexact: u32 = 0x00000020;
const DEC_Overflow: u32 = 0x00000200;
const DEC_Underflow: u32 = 0x00002000;
const DEC_REJECTED: u32 = DEC_Conversion_syntax | DEC_Overflow | DEC_Underflow | DEC_Inexact;

/// The whole pool as bytes, the image both directions of the backup carry.
fn poolBytes() []u8 {
    return std.mem.sliceAsBytes(ram[0..geometry().ram_size_in_blocks]);
}

/// Marks every free region no-access for memcheck, as the free list keeps it
/// (free_list.zig). Both directions of the backup handle the pool as one raw
/// image, so each hands the free regions back to memcheck after it.
fn closeFreeRegions() void {
    const regions = freeMemoryRegions orelse return;
    const pool = poolBytes();
    var i: usize = 0;
    while (i < @as(usize, @intCast(@max(numberOfFreeMemoryRegions, 0)))) : (i += 1) {
        const start = @as(usize, regions[i].blockAddress) << 2;
        std.valgrind.memcheck.makeMemNoAccess(pool[start..][0 .. @as(usize, regions[i].sizeInBlocks) << 2]);
    }
}

// The config-param list (was the file-static cfgFileParam_t paramHead chain),
// now Zig-owned. Built from the open backup.cfg, walked by restoreStateValue.
const CfgParam = extern struct { param: [*c]u8, next: ?*CfgParam };
var paramHead: ?*CfgParam = null;
var paramCurrent: ?*CfgParam = null;

/// One list node from malloc, as the C list allocates it.
fn newCfgParam() ?*CfgParam {
    const bytes = malloc(@sizeOf(CfgParam)) orelse return null;
    return std.mem.bytesAsValue(CfgParam, bytes[0..@sizeOf(CfgParam)]);
}

fn backupOpenParse() c_int {
    var oneParam: [200]u8 = undefined;
    const op: [*c]u8 = &oneParam[0];
    const ret = ioFileOpen(ioPathBackup, ioModeRead);
    if (ret != FILE_OK) return ret;
    calc_state.readLine(op, oneParam.len);
    paramHead = newCfgParam();
    paramCurrent = paramHead;
    paramCurrent.?.param = malloc(strlen(op) + 1);
    _ = strcpy(paramCurrent.?.param, op);
    paramCurrent.?.next = null;
    calc_state.readLine(op, oneParam.len);
    while (ioEof() == 0) {
        paramCurrent.?.next = newCfgParam();
        paramCurrent = paramCurrent.?.next;
        paramCurrent.?.param = malloc(strlen(op) + 1);
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
fn restoreStateValue(buffer: [*]u8, size: u32, name: [*c]const u8, type_str: [*c]const u8) void {
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
        wr(i64, buffer, calc_state.stringToInt64(vp));
    } else if (streq(type_str, "uint64")) {
        wr(u64, buffer, calc_state.stringToUint64(vp));
    } else if (streq(type_str, "int32")) {
        wr(i32, buffer, calc_state.stringToInt32(vp));
    } else if (streq(type_str, "uint32")) {
        wr(u32, buffer, calc_state.stringToUint32(vp));
    } else if (streq(type_str, "int16")) {
        wr(i16, buffer, calc_state.stringToInt16(vp));
    } else if (streq(type_str, "uint16")) {
        wr(u16, buffer, calc_state.stringToUint16(vp));
    } else if (streq(type_str, "int8")) {
        wr(i8, buffer, calc_state.stringToInt8(vp));
    } else if (streq(type_str, "uint8")) {
        wr(u8, buffer, calc_state.stringToUint8(vp));
    } else if (streq(type_str, "float")) {
        wr(f32, buffer, @floatCast(atof(vp)));
    } else if (streq(type_str, "double")) {
        wr(f64, buffer, atof(vp));
    } else if (streq(type_str, "real")) {
        // The saved infinities are spelt as the out-of-range decimals the save writes; a
        // value that does not parse cleanly leaves the default in place.
        var restored: abi.Real = undefined;
        var context: RealContext = ctxtReal39;
        const numericValue: [*c]const u8 = if (strcmp(vp, "9.9e9999999") == 0) "Infinity" else if (strcmp(vp, "-9.9e9999999") == 0) "-Infinity" else vp;
        context.status = 0;
        _ = decNumberFromString(&restored, numericValue, &context);
        if ((context.status & DEC_REJECTED) == 0) {
            wr(abi.Real, buffer, restored);
        } else {
            _ = printf("Invalid real value for parameter %s in file %s, using default\n", name, backupFileName());
        }
    } else if (streq(type_str, "real34")) {
        // stringToReal34 reads through ctxtReal34, so its status is cleared first and
        // the four shared contexts are put back whatever the conversion did to them.
        var restored: abi.Real34 = undefined;
        const savedReal34 = ctxtReal34;
        const savedReal39 = ctxtReal39;
        const savedReal51 = ctxtReal51;
        const savedReal75 = ctxtReal75;
        const numericValue: [*c]const u8 = if (strcmp(vp, "9.9e9999") == 0) "Infinity" else if (strcmp(vp, "-9.9e9999") == 0) "-Infinity" else vp;
        ctxtReal34.status = 0;
        _ = decQuadFromString(&restored, numericValue, &ctxtReal34);
        const status = ctxtReal34.status;
        ctxtReal34 = savedReal34;
        ctxtReal39 = savedReal39;
        ctxtReal51 = savedReal51;
        ctxtReal75 = savedReal75;
        if ((status & DEC_REJECTED) == 0) {
            wr(abi.Real34, buffer, restored);
        } else {
            _ = printf("Invalid real34 value for parameter %s in file %s, using default\n", name, backupFileName());
        }
    } else if (streq(type_str, "bool")) {
        wr(u8, buffer, if (calc_state.stringToInt8(vp) != 0) 1 else 0);
    } else if (streq(type_str, "c47Ptr")) {
        // WIDTH-CONTRACT: accepted -- a backup field holding a pool block index.
        // A window value gives the host the true low bits and the firmware
        // 0xFFFFFFFF, but neither is dereferenced from here: restoredPoolPointer()
        // in this same owner re-reads the pair and refuses any block index the pool
        // cannot hold, on both targets. That check is the reason this one can be
        // accepted -- and it is the check the STATE owner was missing until
        // It was ported across.
        wr(u32, buffer, @truncate(strtoul(vp, null, 0)));
    } else if (streq(type_str, "hexDump")) {
        const numberOfBytes = calc_state.stringToUint32(vp);
        var bufp: [*c]u8 = buffer;
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
// c47.c global, set by the simulator's --testPgms and --writeexportall arms.
extern var loadTestPrograms: bool;
const FLAG_FRACT: c_uint = 32775;
const FLAG_IRFRAC: c_uint = 32839;
const MNU_HOME: i16 = 3070;
const FLAG_SIGZEROS: c_uint = 32874; // 0x806A
const FLAG_SBadm: c_uint = 32879; // 0x806F
const FLAG_M_ALL: c_uint = 32882; // 0x8072
const FLAG_AUTOVALID: c_uint = 32880; // 0x8070
const FLAG_BASE_MYM: c_uint = 0x805C;
const FLAG_G_DOUBLETAP: c_uint = 0x805D;
const FLAG_BASE_HOME: c_uint = 0x805E;
const FLAG_MYM_TRIPLE: c_uint = 0x805F;
const FLAG_HOME_TRIPLE: c_uint = 0x8060;
const FLAG_SHFT_4s: c_uint = 0x8061;

fn rv(buffer: [*]u8, size: u32, name: [*c]const u8, type_str: [*c]const u8) void {
    restoreStateValue(buffer, size, name, type_str);
}
extern fn stringToDouble(str: [*c]const u8) f64; // locale-free strtod (accepts '.' or ',')
extern fn convertDoubleToReal(x: f64, destination: *real_t, ctxt: *RealContext) void;
// A pre-1016 backup stored each graph setting as a float (saveRestoreBackup.c
// migrateFloatValue). Returns that old value, or null when the file holds none,
// which leaves the default in place; a value that is not finite migrates as 0.
// The caller stores it at the new type and the next save writes that type.
fn oldFloatValue(valueName: [*c]const u8) ?f64 {
    var search: [60]u8 = undefined;
    const s: [*c]u8 = &search[0];
    _ = strcpy(s, valueName);
    _ = strcat(s, ":float:");
    paramCurrent = paramHead;
    while (paramCurrent) |pc| {
        if (strncmp(pc.param, s, strlen(s)) == 0) break;
        paramCurrent = pc.next;
    }
    const found = paramCurrent orelse return null;
    const d = stringToDouble(found.param + strlen(s));
    return if (std.math.isFinite(d)) d else 0;
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

    rv(std.mem.asBytes(&blockAddress), 4, valueName, "c47Ptr");
    if (offsetValueName) |ovn| {
        rv(std.mem.asBytes(&byteOffset), 4, ovn, "uint32");
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
fn wrU16(p: [*c]u8, value: u16) void {
    p[0] = @truncate(value);
    p[1] = @truncate(value >> 8);
}
fn programStep(idx: u16) i32 {
    const base = programList + @as(usize, idx) * 16;
    return std.mem.bytesToValue(i32, base[0..4]);
}

pub fn restoreCalc() void {
    if (comptime is_dmcp_build) return;
    doFnReset(CONFIRMED, loadAutoSav);
    if (loadTestPrograms) { // the reset above staged the test programs; reading backup.cfg over them would undo that
        refreshScreen(9100);
        return;
    }
    if (backupOpenParse() != FILE_OK) return;
    var backupVersion: u32 = 0;
    rv(std.mem.asBytes(&backupVersion), 4, "backupVersion", "uint32");
    var ramSizeInBlocks: u32 = 0;
    rv(std.mem.asBytes(&ramSizeInBlocks), 4, "ramSizeInBlocks", "uint32");
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
    rv(std.mem.asBytes(&restoredFreeRegions), 4, "numberOfFreeMemoryRegions", "int32");
    rv(std.mem.asBytes(&restoredAllocatedRegions), 4, "numberOfAllocatedMemoryRegions", "int32");
    if (!restoredRegionCountIsUsable(restoredFreeRegions, MAX_FREE_REGIONS) or
        !restoredRegionCountIsUsable(restoredAllocatedRegions, MAX_ALLOCATED_REGIONS))
    {
        backupFreeParams();
        return;
    }
    numberOfFreeMemoryRegions = restoredFreeRegions;
    numberOfAllocatedMemoryRegions = restoredAllocatedRegions;

    // The raw pool image lands over blocks memcheck may hold as no-access (see
    // free_list.zig); it is ordinary memory until the free list is read back below.
    std.valgrind.memcheck.makeMemUndefined(poolBytes());
    rv(poolBytes().ptr, (geometry().ram_size_in_blocks) << 2, "ram", "hexDump");

    graMod = 0;
    if (backupVersion >= 1020) {
        rv(std.mem.asBytes(&graMod), 1, "graMod", "uint8");
    } else {
        // Pre-1020 backups: GRAMOD as a long integer reserved variable in the ram
        // image, block 36. Take its value over, convert, then clear the slot.
        const gramodSlot = progmem.toPcmemptr(geometry(), 36);
        const oldGramod: u32 = @as(*align(4) const u32, @ptrFromInt(gramodSlot + @sizeOf(StrLgIntHeader))).*;
        graMod = if (oldGramod <= 3) @intCast(oldGramod) else 0;
        @memset(@as([*]u8, @ptrFromInt(gramodSlot))[0..REAL34_SIZE_IN_BYTES], 0);
        // Block 36 is now i%. A memset leaves bytes a decQuad does not read as zero,
        // so encode a real zero there, then derive i% from the restored I%/a.
        _ = decQuadZero(@ptrFromInt(gramodSlot));
        tvmSyncIp(RESERVED_VARIABLE_IPONA);
    }
    if (comptime option_atext_fonts) {
        graFont = 20;
        rv(std.mem.asBytes(&graFont), 1, "graFont", "uint8"); // a file without the key leaves 20, the standard font
        graFontCheck();
    }
    rv(std.mem.asBytes(&longPressFactor), 2, "longPressFactor", "int16"); // a file without the key leaves 0, factor 1
    rv(std.mem.asBytes(&doublePressFactor), 2, "doublePressFactor", "int16");
    // The size argument is what stops the reader writing off the end, so it is the room the destination
    // has, the way every other call here passes a sizeof(). These writes cannot leave their table whatever
    // count the file carries.
    rv(std.mem.asBytes(&freeMemoryRegions.?[0]), FREE_MEM_REGION_SIZE * MAX_FREE_REGIONS, "freeMemoryRegions", "hexDump");
    closeFreeRegions();
    rv(std.mem.asBytes(&allocatedMemoryRegions[0]), FREE_MEM_REGION_SIZE * MAX_ALLOCATED_REGIONS, "allocatedMemoryRegions", "hexDump");
    rv(std.mem.asBytes(&globalRegister.?[0]), REGISTER_HEADER_SIZE * NUMBER_OF_GLOBAL_REGISTERS, "globalRegister", "hexDump");
    rv(std.mem.asBytes(&calcMode), 1, "calcMode", "uint8");
    rv(std.mem.asBytes(&previousCalcMode), 1, "previousCalcMode", "uint8");
    rv(std.mem.asBytes(&graphToRemainOnScreen), 1, "graphToRemainOnScreen", "bool");
    rv(std.mem.asBytes(&calcModel), 1, "calcModel", "uint8");

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
    rv(std.mem.asBytes(&globalFlags[0]), 16, "globalFlags", "hexDump");
    rv(std.mem.asBytes(&errorMessage[0]), 512, "errorMessage", "hexDump");
    rv(std.mem.asBytes(&aimBuffer[0]), 1024, "aimBuffer", "hexDump");
    rv(std.mem.asBytes(&nimBufferDisplay[0]), 200, "nimBufferDisplay", "hexDump");
    rv(std.mem.asBytes(&tamBuffer[0]), 56, "tamBuffer", "hexDump");
    rv(std.mem.asBytes(&asmBuffer[0]), 5, "asmBuffer", "hexDump");
    rv(std.mem.asBytes(&oldTime[0]), 8, "oldTime", "hexDump");
    rv(std.mem.asBytes(&dateTimeString[0]), 12, "dateTimeString", "hexDump");
    rv(std.mem.asBytes(&softmenuStack), @sizeOf(@TypeOf(softmenuStack)), "softmenuStack", "hexDump");
    if (comptime option_structured_pgm) {
        forClearLoops(); // a file without the keyword below then leaves no loop running
        rv(std.mem.asBytes(&forLoopTable[0]), FOR_LOOP_TABLE_BYTES, "forLoopTable", "hexDump");
    }
    rv(std.mem.asBytes(&kbd_usr[0]), 666, "kbd_usr", "hexDump");
    rv(std.mem.asBytes(&userMenuItems[0]), 360, "userMenuItems", "hexDump");
    rv(std.mem.asBytes(&userAlphaItems[0]), 360, "userAlphaItems", "hexDump");
    rv(std.mem.asBytes(&lastTemp[0]), 16, "lastTemp", "hexDump");
    rv(std.mem.asBytes(&lastStateFileOpened[0]), 32, "lastStateFileOpened", "hexDump");
    if (comptime !is_dmcp_build) {
        rv(std.mem.asBytes(&lastFolderData[0]), C47_PATH_MAX, "lastFolderData", "hexDump");
        rv(std.mem.asBytes(&lastFolderState[0]), C47_PATH_MAX, "lastFolderState", "hexDump");
        rv(std.mem.asBytes(&lastFolderPrograms[0]), C47_PATH_MAX, "lastFolderPrograms", "hexDump");
    }
    rv(std.mem.asBytes(&lastI[0]), 2, "lastI", "int16");
    rv(std.mem.asBytes(&lastJ[0]), 2, "lastJ", "int16");
    rv(std.mem.asBytes(&lastFunc[0]), 2, "lastFunc", "int16");
    rv(std.mem.asBytes(&lastParam[0]), 2, "lastParam", "int16");
    rv(std.mem.asBytes(&tam.mode), @sizeOf(@TypeOf(tam.mode)), "tam.mode", "uint16");
    rv(std.mem.asBytes(&tam.function), @sizeOf(@TypeOf(tam.function)), "tam.function", "int16");
    rv(std.mem.asBytes(&tam.alpha), @sizeOf(@TypeOf(tam.alpha)), "tam.alpha", "bool");
    rv(std.mem.asBytes(&tam.currentOperation), @sizeOf(@TypeOf(tam.currentOperation)), "tam.currentOperation", "int16");
    rv(std.mem.asBytes(&tam.dot), @sizeOf(@TypeOf(tam.dot)), "tam.dot", "bool");
    rv(std.mem.asBytes(&tam.indirect), @sizeOf(@TypeOf(tam.indirect)), "tam.indirect", "bool");
    rv(std.mem.asBytes(&tam.digitsSoFar), @sizeOf(@TypeOf(tam.digitsSoFar)), "tam.digitsSoFar", "int16");
    rv(std.mem.asBytes(&tam.value), @sizeOf(@TypeOf(tam.value)), "tam.value", "int16");
    rv(std.mem.asBytes(&tam.min), @sizeOf(@TypeOf(tam.min)), "tam.min", "int16");
    rv(std.mem.asBytes(&tam.max), @sizeOf(@TypeOf(tam.max)), "tam.max", "int16");
    rv(std.mem.asBytes(&rbrRegister[0]), 2, "rbrRegister", "int16");
    rv(std.mem.asBytes(&numberOfNamedVariables[0]), 2, "numberOfNamedVariables", "int16");
    rv(std.mem.asBytes(&xCursor[0]), 4, "xCursor", "uint32");
    rv(std.mem.asBytes(&yCursor[0]), 4, "yCursor", "uint32");
    rv(std.mem.asBytes(&firstGregorianDay[0]), 4, "firstGregorianDay", "uint32");
    rv(std.mem.asBytes(&denMax[0]), 4, "denMax", "uint32");
    rv(std.mem.asBytes(&lastDenominator[0]), 4, "lastDenominator", "uint32");
    rv(std.mem.asBytes(&currentRegisterBrowserScreen[0]), 2, "currentRegisterBrowserScreen", "int16");
    rv(std.mem.asBytes(&currentFntScr[0]), 1, "currentFntScr", "uint8");
    rv(std.mem.asBytes(&currentFlgScr[0]), 1, "currentFlgScr", "uint8");
    rv(std.mem.asBytes(&displayFormat[0]), 1, "displayFormat", "uint8");
    rv(std.mem.asBytes(&displayFormatDigits[0]), 1, "displayFormatDigits", "uint8");
    rv(std.mem.asBytes(&timeDisplayFormatDigits[0]), 1, "timeDisplayFormatDigits", "uint8");
    rv(std.mem.asBytes(&shortIntegerWordSize[0]), 1, "shortIntegerWordSize", "uint8");
    shortIntegerWordSize[0] = boundShortIntegerWordSize(shortIntegerWordSize[0]);
    updateShortIntegerMasks(); // rederive shortIntegerMask and shortIntegerSignBit from the word size just restored; the file copies (older backups) are ignored
    rv(std.mem.asBytes(&significantDigits[0]), 1, "significantDigits", "uint8");
    fractionDigits[0] = 34; // the default a backup that carries no fractionDigits entry restores to
    rv(std.mem.asBytes(&fractionDigits[0]), 1, "fractionDigits", "uint8");
    rv(std.mem.asBytes(&shortIntegerMode[0]), 1, "shortIntegerMode", "uint8");
    rv(std.mem.asBytes(&currentAngularMode[0]), 4, "currentAngularMode", "uint32");
    rv(std.mem.asBytes(&scrLock[0]), 1, "scrLock", "uint8");
    scrLock[0] &= 0x03;

    displayRoundingMode[0] = DRM_DFLT;
    rv(std.mem.asBytes(&displayRoundingMode[0]), 1, "displayRoundingMode", "uint8");
    if (displayRoundingMode[0] > RM_FLOOR) {
        displayRoundingMode[0] = DRM_DFLT;
    }
    rv(std.mem.asBytes(&roundingMode[0]), 1, "roundingMode", "uint8");
    if (roundingMode[0] > RM_FLOOR) {
        roundingMode[0] = RM_HALF_EVEN;
    }
    setRoundingMode(roundingMode[0]);
    rv(std.mem.asBytes(&nextChar[0]), 1, "nextChar", "uint8");
    rv(std.mem.asBytes(&alphaCase[0]), 1, "alphaCase", "uint8");
    rv(std.mem.asBytes(&hourGlassIconEnabled[0]), 1, "hourGlassIconEnabled", "bool");
    rv(std.mem.asBytes(&watchIconEnabled[0]), 1, "watchIconEnabled", "bool");
    rv(std.mem.asBytes(&serialIOIconEnabled[0]), 1, "serialIOIconEnabled", "bool");
    rv(std.mem.asBytes(&printerIconEnabled[0]), 1, "printerIconEnabled", "bool");
    rv(std.mem.asBytes(&programRunStop[0]), 1, "programRunStop", "uint8");
    rv(std.mem.asBytes(&entryStatus[0]), 1, "entryStatus", "uint8");
    rv(std.mem.asBytes(&cursorEnabled[0]), 1, "cursorEnabled", "uint8");
    rv(std.mem.asBytes(&rbr1stDigit[0]), 1, "rbr1stDigit", "bool");
    rv(std.mem.asBytes(&shiftF[0]), 1, "shiftF", "bool");
    rv(std.mem.asBytes(&shiftG[0]), 1, "shiftG", "bool");
    rv(std.mem.asBytes(&rbrMode[0]), 1, "rbrMode", "uint8");
    rv(std.mem.asBytes(&showContent[0]), 1, "showContent", "bool");
    rv(std.mem.asBytes(&numScreensNumericFont[0]), 1, "numScreensNumericFont", "uint8");
    rv(std.mem.asBytes(&numScreensNumericFontBold[0]), 1, "numScreensNumericFontBold", "uint8");
    rv(std.mem.asBytes(&numLinesNumericFont[0]), 1, "numLinesNumericFont", "uint8");
    rv(std.mem.asBytes(&numLinesNumericFontBold[0]), 1, "numLinesNumericFontBold", "uint8");
    rv(std.mem.asBytes(&numScreensStandardFont[0]), 1, "numScreensStandardFont", "uint8");
    rv(std.mem.asBytes(&numLinesStandardFont[0]), 1, "numLinesStandardFont", "uint8");
    rv(std.mem.asBytes(&numScreensTinyFont[0]), 1, "numScreensTinyFont", "uint8");
    rv(std.mem.asBytes(&numLinesTinyFont[0]), 1, "numLinesTinyFont", "uint8");
    rv(std.mem.asBytes(&lastErrorCode[0]), 1, "lastErrorCode", "uint8");
    rv(std.mem.asBytes(&previousErrorCode[0]), 1, "previousErrorCode", "uint8");
    rv(std.mem.asBytes(&nimNumberPart[0]), 1, "nimNumberPart", "uint8");
    rv(std.mem.asBytes(&displayStack[0]), 1, "displayStack", "uint8");
    rv(std.mem.asBytes(&hexDigits[0]), 1, "hexDigits", "uint8");
    rv(std.mem.asBytes(&errorMessageRegisterLine[0]), 2, "errorMessageRegisterLine", "int16");
    // No read-back of shortIntegerMask / shortIntegerSignBit here: both were
    // rederived from the restored word size above, and the file copies are
    // deliberately ignored.
    rv(std.mem.asBytes(&temporaryInformation[0]), 1, "temporaryInformation", "uint8");
    rv(std.mem.asBytes(&funcOK[0]), 1, "funcOK", "bool");
    rv(std.mem.asBytes(&screenChange[0]), 1, "screenChange", "bool");
    rv(std.mem.asBytes(&exponentSignLocation[0]), 2, "exponentSignLocation", "int16");
    rv(std.mem.asBytes(&denominatorLocation[0]), 2, "denominatorLocation", "int16");
    rv(std.mem.asBytes(&imaginaryExponentSignLocation[0]), 2, "imaginaryExponentSignLocation", "int16");
    rv(std.mem.asBytes(&imaginaryMantissaSignLocation[0]), 2, "imaginaryMantissaSignLocation", "int16");
    rv(std.mem.asBytes(&lineTWidth[0]), 2, "lineTWidth", "int16");
    rv(std.mem.asBytes(&lastIntegerBase[0]), 4, "lastIntegerBase", "uint32");
    rv(std.mem.asBytes(&c47MemInBlocks[0]), 8, "c47MemInBlocks", "uint64");
    rv(std.mem.asBytes(&gmpMemInBytes[0]), 8, "gmpMemInBytes", "uint64");
    rv(std.mem.asBytes(&catalog[0]), 2, "catalog", "int16");
    if (backupVersion < 1012) { // the FNCS_EIM catalog was added at 1012
        rv(std.mem.asBytes(&lastCatalogPosition[0]), 48 - 4, "lastCatalogPosition", "int16");
        lastCatalogPosition[22 * 2] = 0;
        lastCatalogPosition[22 * 2 + 1] = 0;
    } else if (backupVersion < 1023) { // int16 wrote element 0 only
        rv(std.mem.asBytes(&lastCatalogPosition[0]), 48, "lastCatalogPosition", "int16");
    } else {
        rv(std.mem.asBytes(&lastCatalogPosition[0]), 48, "lastCatalogPosition", "hexDump");
    }
    rv(std.mem.asBytes(&retainedPageFirstItem[0]), 4, "retainedPageFirstItem", "hexDump");
    rv(std.mem.asBytes(&displayValueX[0]), 80, "displayValueX", "hexDump");
    rv(std.mem.asBytes(&pcg32_global[0]), 16, "pcg32_global", "hexDump");
    rv(std.mem.asBytes(&exponentLimit[0]), 2, "exponentLimit", "int16");
    rv(std.mem.asBytes(&exponentHideLimit[0]), 2, "exponentHideLimit", "int16");
    rv(std.mem.asBytes(&keyActionProcessed[0]), 1, "keyActionProcessed", "bool");
    rv(std.mem.asBytes(&systemFlags0[0]), 8, "systemFlags", "uint64");
    rv(std.mem.asBytes(&systemFlags1[0]), 8, "systemFlags1", "uint64");
    rv(std.mem.asBytes(&savedSystemFlags0[0]), 8, "savedSystemFlags", "uint64");
    rv(std.mem.asBytes(&savedSystemFlags1[0]), 8, "savedSystemFlags1", "uint64");
    rv(std.mem.asBytes(&thereIsSomethingToUndo[0]), 1, "thereIsSomethingToUndo", "bool");
    rv(std.mem.asBytes(&freeProgramBytes[0]), 2, "freeProgramBytes", "uint16");
    rv(std.mem.asBytes(&firstDisplayedLocalStepNumber[0]), 2, "firstDisplayedLocalStepNumber", "uint16");
    rv(std.mem.asBytes(&numberOfLabels[0]), 2, "numberOfLabels", "uint16");
    rv(std.mem.asBytes(&numberOfStructureLabels[0]), 2, "numberOfStructureLabels", "uint16");
    rv(std.mem.asBytes(&numberOfPrograms[0]), 2, "numberOfPrograms", "uint16");
    rv(std.mem.asBytes(&currentLocalStepNumber[0]), 2, "currentLocalStepNumber", "uint16");
    rv(std.mem.asBytes(&currentProgramNumber[0]), 2, "currentProgramNumber", "uint16");
    rv(std.mem.asBytes(&lastProgramListEnd[0]), 1, "lastProgramListEnd", "bool");
    rv(std.mem.asBytes(&programListEnd[0]), 1, "programListEnd", "bool");
    rv(std.mem.asBytes(&allSubroutineLevels[0]), 4, "allSubroutineLevels", "uint32");
    rv(std.mem.asBytes(&pemCursorIsZerothStep[0]), 1, "pemCursorIsZerothStep", "bool");
    rv(std.mem.asBytes(&skippedStackLines[0]), 1, "skippedStackLines", "bool");
    rv(std.mem.asBytes(&iterations[0]), 1, "iterations", "bool");
    rv(std.mem.asBytes(&numberOfTamMenusToPop[0]), 2, "numberOfTamMenusToPop", "int16");
    rv(std.mem.asBytes(&lrSelection[0]), 2, "lrSelection", "uint16");
    rv(std.mem.asBytes(&lrSelectionUndo[0]), 2, "lrSelectionUndo", "uint16");
    rv(std.mem.asBytes(&amortP1[0]), 2, "amortP1", "uint16");
    rv(std.mem.asBytes(&amortP2[0]), 2, "amortP2", "uint16");
    rv(std.mem.asBytes(&lrChosen[0]), 2, "lrChosen", "uint16");
    rv(std.mem.asBytes(&lrChosenUndo[0]), 2, "lrChosenUndo", "uint16");
    rv(std.mem.asBytes(&lastPlotMode[0]), 2, "lastPlotMode", "uint16");
    rv(std.mem.asBytes(&plotSelection[0]), 2, "plotSelection", "uint16");
    rv(std.mem.asBytes(&roundedTicks[0]), 1, "roundedTicks", "bool");
    rv(std.mem.asBytes(&PLOT_AXIS[0]), 1, "PLOT_AXIS", "bool");
    rv(std.mem.asBytes(&PLOT_ZMY[0]), 1, "PLOT_ZMY", "int8");
    rv(std.mem.asBytes(&PLOT_ZOOM[0]), 1, "PLOT_ZOOM", "uint8");
    rv(std.mem.asBytes(&plotmode[0]), 1, "plotmode", "int8");
    if (backupVersion >= 1016) {
        rv(std.mem.asBytes(&tick_int_x[0]), 8, "tick_int_x", "double");
        rv(std.mem.asBytes(&tick_int_y[0]), 8, "tick_int_y", "double");
        rv(std.mem.asBytes(x_min), REAL_SIZE_IN_BYTES_34, "x_min", "real");
        rv(std.mem.asBytes(x_max), REAL_SIZE_IN_BYTES_34, "x_max", "real");
        rv(std.mem.asBytes(y_min), REAL_SIZE_IN_BYTES_34, "y_min", "real");
        rv(std.mem.asBytes(y_max), REAL_SIZE_IN_BYTES_34, "y_max", "real");
    } else {
        // pre-1016 backups stored the graph settings as float: convert each once; the next save writes the new types.
        if (oldFloatValue("tick_int_x")) |d| wr(f64, &tick_int_x, d);
        if (oldFloatValue("tick_int_y")) |d| wr(f64, &tick_int_y, d);
        if (oldFloatValue("x_min")) |d| convertDoubleToReal(d, x_min, &ctxtReal39);
        if (oldFloatValue("x_max")) |d| convertDoubleToReal(d, x_max, &ctxtReal39);
        if (oldFloatValue("y_min")) |d| convertDoubleToReal(d, y_min, &ctxtReal39);
        if (oldFloatValue("y_max")) |d| convertDoubleToReal(d, y_max, &ctxtReal39);
    }
    rv(std.mem.asBytes(&xzero[0]), 4, "xzero", "uint32");
    rv(std.mem.asBytes(&yzero[0]), 4, "yzero", "uint32");
    rv(std.mem.asBytes(&regStatsXY[0]), 2, "regStatsXY", "int16");
    rv(std.mem.asBytes(&matrixIndex[0]), 2, "matrixIndex", "uint16");
    rv(std.mem.asBytes(&shadowI[0]), 2, "shadowI", "int16");
    rv(std.mem.asBytes(&shadowJ[0]), 2, "shadowJ", "int16");
    rv(std.mem.asBytes(&currentViewRegister[0]), 2, "currentViewRegister", "uint16");
    rv(std.mem.asBytes(&currentSolverStatus[0]), 2, "currentSolverStatus", "uint16");
    rv(std.mem.asBytes(&currentSolverProgram[0]), 2, "currentSolverProgram", "uint16");
    rv(std.mem.asBytes(&currentDerivProgram[0]), 2, "currentDerivProgram", "uint16");
    rv(std.mem.asBytes(&currentSolverVariable[0]), 2, "currentSolverVariable", "uint16");
    rv(std.mem.asBytes(&numberOfFormulae[0]), 2, "numberOfFormulae", "uint16");
    rv(std.mem.asBytes(&currentFormula[0]), 2, "currentFormula", "uint16");
    rv(std.mem.asBytes(&numberOfUserMenus[0]), 2, "numberOfUserMenus", "uint16");
    rv(std.mem.asBytes(&currentUserMenu[0]), 2, "currentUserMenu", "uint16");
    rv(std.mem.asBytes(&userKeyLabelSize[0]), 2, "userKeyLabelSize", "uint16");
    rv(std.mem.asBytes(&timerCraAndDeciseconds[0]), 1, "timerCraAndDeciseconds", "uint8");
    rv(std.mem.asBytes(&timerValue[0]), 4, "timerValue", "uint32");
    rv(std.mem.asBytes(&timerTotalTime[0]), 4, "timerTotalTime", "uint32");
    rv(std.mem.asBytes(&currentInputVariable[0]), 2, "currentInputVariable", "uint16");
    rv(std.mem.asBytes(&SAVED_SIGMA_LASTX[0]), 60, "SAVED_SIGMA_LASTX", "real");
    rv(std.mem.asBytes(&SAVED_SIGMA_LASTY[0]), 60, "SAVED_SIGMA_LASTY", "real");
    rv(std.mem.asBytes(&SAVED_SIGMA_lastAddRem[0]), 1, "SAVED_SIGMA_lastAddRem", "int8");
    rv(std.mem.asBytes(&currentMvarLabel[0]), 2, "currentMvarLabel", "uint16");
    rv(std.mem.asBytes(&plotStatMx[0]), 8, "plotStatMx", "hexDump");
    rv(std.mem.asBytes(&drawHistogram[0]), 1, "drawHistogram", "uint8");
    rv(std.mem.asBytes(&plotStatScale[0]), 1, "plotStatScale", "uint8");
    rv(std.mem.asBytes(&statMx[0]), 8, "statMx", "hexDump");
    rv(std.mem.asBytes(&lrSelectionHistobackup[0]), 2, "lrSelectionHistobackup", "uint16");
    rv(std.mem.asBytes(&lrChosenHistobackup[0]), 2, "lrChosenHistobackup", "uint16");
    rv(std.mem.asBytes(&loBinR[0]), 16, "loBinR", "real34");
    rv(std.mem.asBytes(&nBins[0]), 16, "nBins", "real34");
    rv(std.mem.asBytes(&hiBinR[0]), 16, "hiBinR", "real34");
    rv(std.mem.asBytes(&histElementXorY[0]), 2, "histElementXorY", "int16");
    rv(std.mem.asBytes(&screenUpdatingMode[0]), 1, "screenUpdatingMode", "uint8");
    rv(std.mem.asBytes(&Norm_Key_00.func), @sizeOf(@TypeOf(Norm_Key_00.func)), "Norm_Key_00.func", "int16");
    rv(std.mem.asBytes(&Norm_Key_00.funcParam), @sizeOf(@TypeOf(Norm_Key_00.funcParam)), "Norm_Key_00.funcParam", "hexDump");
    rv(std.mem.asBytes(&Norm_Key_00.used), @sizeOf(@TypeOf(Norm_Key_00.used)), "Norm_Key_00.used", "bool");
    rv(std.mem.asBytes(&Input_Default[0]), 1, "Input_Default", "uint8");
    set_def_Input_Default();
    rv(std.mem.asBytes(&T_cursorPos[0]), 2, "T_cursorPos", "int16");
    rv(std.mem.asBytes(&multiEdLines[0]), 1, "multiEdLines", "uint8");
    rv(std.mem.asBytes(&current_cursor_x[0]), 2, "current_cursor_x", "uint16");
    rv(std.mem.asBytes(&current_cursor_y[0]), 2, "current_cursor_y", "uint16");
    rv(std.mem.asBytes(&xMultiLineEdOffset[0]), 1, "xMultiLineEdOffset", "uint8");
    rv(std.mem.asBytes(&yMultiLineEdOffset[0]), 1, "yMultiLineEdOffset", "uint8");
    rv(std.mem.asBytes(&showRegis[0]), 2, "showRegis", "int16");
    rv(std.mem.asBytes(&overrideShowBottomLine[0]), 1, "overrideShowBottomLine", "uint8");
    rv(std.mem.asBytes(&displayStackSHOIDISP[0]), 1, "displayStackSHOIDISP", "uint8");
    rv(std.mem.asBytes(&ListXYposition[0]), 2, "ListXYposition", "int16");
    rv(std.mem.asBytes(&DRG_Cycling[0]), 1, "DRG_Cycling", "uint8");
    if (comptime option_drg_cfg) rv(std.mem.asBytes(&drgConfig), 1, "drgConfig", "uint8");
    rv(std.mem.asBytes(&lastFlgScr[0]), 1, "lastFlgScr", "uint8");
    rv(std.mem.asBytes(&displayAIMbufferoffset[0]), 2, "displayAIMbufferoffset", "int16");
    rv(std.mem.asBytes(&bcdDisplaySign[0]), 1, "bcdDisplaySign", "uint8");
    rv(std.mem.asBytes(&DM_Cycling[0]), 1, "DM_Cycling", "uint8");
    rv(std.mem.asBytes(&LongPressM[0]), 1, "LongPressM", "uint8");
    rv(std.mem.asBytes(&LongPressF[0]), 1, "LongPressF", "uint8");
    rv(std.mem.asBytes(&currentAsnScr[0]), 1, "currentAsnScr", "uint8");
    rv(std.mem.asBytes(&gapItemLeft[0]), 2, "gapItemLeft", "uint16");
    rv(std.mem.asBytes(&gapItemRight[0]), 2, "gapItemRight", "uint16");
    rv(std.mem.asBytes(&gapItemRadix[0]), 2, "gapItemRadix", "uint16");
    rv(std.mem.asBytes(&lastCenturyHighUsed[0]), 2, "lastCenturyHighUsed", "uint16");
    rv(std.mem.asBytes(&grpGroupingLeft[0]), 1, "grpGroupingLeft", "uint8");
    rv(std.mem.asBytes(&grpGroupingGr1LeftOverflow[0]), 1, "grpGroupingGr1LeftOverflow", "uint8");
    rv(std.mem.asBytes(&grpGroupingGr1Left[0]), 1, "grpGroupingGr1Left", "uint8");
    rv(std.mem.asBytes(&grpGroupingRight[0]), 1, "grpGroupingRight", "uint8");
    rv(std.mem.asBytes(&grpGroupingHex[0]), 1, "grpGroupingHex", "uint8");
    rv(std.mem.asBytes(&grpGroupingBin[0]), 1, "grpGroupingBin", "uint8");
    grpGroupingHexBinDefault();
    rv(std.mem.asBytes(&firstDayOfWeek[0]), 1, "firstDayOfWeek", "uint8");
    rv(std.mem.asBytes(&firstWeekOfYearDay[0]), 1, "firstWeekOfYearDay", "uint8");
    rv(std.mem.asBytes(&dispBase[0]), 1, "dispBase", "uint8");
    rv(std.mem.asBytes(&printerState.print_on), @sizeOf(@TypeOf(printerState.print_on)), "printerState.print_on", "bool");
    rv(std.mem.asBytes(&printerState.printer_model), @sizeOf(@TypeOf(printerState.printer_model)), "printerState.printer_model", "uint8");
    rv(std.mem.asBytes(&printerState.delay), @sizeOf(@TypeOf(printerState.delay)), "printerState.delay", "uint16");
    rv(std.mem.asBytes(&programmableMenu[0]), 332, "programmableMenu", "hexDump");
    rv(std.mem.asBytes(&alphaRegister), 2, "alphaRegister", "uint16");
    graphVariabl1 = INVALID_VARIABLE;
    rv(std.mem.asBytes(&graphVariabl1), 2, "graphVariabl1", "int16");
    if (backupVersion < 1013) {
        // Six flags that lived under their own parameter names until 1013.
        // BASE_HOME and BASE_MYM each have two old spellings; the later one wins.
        const transfers = [_]struct { name: [*c]const u8, flag: c_uint }{
            .{ .name = "jm_G_DOUBLETAP", .flag = FLAG_G_DOUBLETAP },
            .{ .name = "HOME3", .flag = FLAG_HOME_TRIPLE },
            .{ .name = "MYM3", .flag = FLAG_MYM_TRIPLE },
            .{ .name = "ShiftTimoutMode", .flag = FLAG_SHFT_4s },
            .{ .name = "BASE_HOME", .flag = FLAG_BASE_HOME },
            .{ .name = "SH_BASE_HOME", .flag = FLAG_BASE_HOME },
            .{ .name = "BASE_MYM", .flag = FLAG_BASE_MYM },
            .{ .name = "jm_BASE_SCREEN", .flag = FLAG_BASE_MYM },
        };
        // One scratch for the whole chain, as the C declares it: a name the file
        // omits leaves the previous transfer's value standing.
        var tmp1: u8 = 0;
        for (transfers) |t| {
            rv(std.mem.asBytes(&tmp1), 1, t.name, "bool");
            if (tmp1 != 0) setSystemFlag(t.flag) else clearSystemFlag(t.flag);
        }
    }
    if (backupVersion < 1014) setLongPressFg(calcModel, -MNU_HOME);
    if (backupVersion < 1015) setSystemFlag(FLAG_SIGZEROS); // SIGZEROS is on per default
    if (backupVersion < 1017) setSystemFlag(FLAG_SBadm); // the angular mode annunciator is on per default
    if (backupVersion < 1018) {
        setSystemFlag(FLAG_M_ALL); // inclusive of this version, set the M.ALL
        setSystemFlag(FLAG_AUTOVALID);
    }
    if (backupVersion < 1019) { // menu items renumbered into one block: move the stored menu links
        calc_state_restore.convertOldMenuNumbers();
        // lastFunc and its param are cleared where the menu items were replaced.
        wrU16(&lastFunc[0], ITM_NOP);
        wrU16(&lastParam[0], NOPARAM);
    }
    if (getSystemFlag(@intCast(FLAG_FRACT))) {
        setSystemFlag(FLAG_FRACT);
    } else if (getSystemFlag(@intCast(FLAG_IRFRAC))) {
        setSystemFlag(FLAG_IRFRAC);
    }
    backupFreeParams();

    // Zeros occur in older cfg files; both are 1 based, so they are repaired here rather than through a version check.
    if (rdU16(&currentLocalStepNumber[0]) == 0) {
        wrU16(&currentLocalStepNumber[0], 1);
    }
    if (rdU16(&currentProgramNumber[0]) == 0) {
        wrU16(&currentProgramNumber[0], 1);
    }

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
