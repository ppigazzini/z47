// SAVE-side serialization of the calculator state file (c47.sav text format).
//
// This is a faithful Zig port of saveRestoreCalcState.c doSave()'s section
// writer (the C body between opening and closing the file, lines ~1768-2032).
// The host Zig io_flow path (calc_state_io_flow_owned.doSave) already owns the
// open/close/status orchestration and calls writeSaveSections() -> this. The
// per-element value formatters (registerToSaveString / saveMatrixElements /
// UI64toString / realToString) and the few file-static / enum-typed reads stay
// in C, reached as direct externs to the canonical core symbols; this owner
// frames every section and selects the fields.
//
// Verified byte-for-byte against the current C output by the save/load parity
// harness (`zig build saveload_parity`): the golden file is the C doSave bytes.

const text = @import("calc_state_text_owned.zig");
const codec = @import("calc_state_register_codec_owned.zig");
const progmem = @import("calc_state_progmem_owned.zig");
const build_options = @import("calc_state_build_options");

const state_old_hw = @hasDecl(build_options, "state_old_hw") and build_options.state_old_hw;
fn geometry() progmem.Geometry {
    return .{
        .ram_base = @intFromPtr(ram),
        .ram_size_in_blocks = if (state_old_hw) progmem.RAM_SIZE_IN_BLOCKS_OLD_HW else progmem.RAM_SIZE_IN_BLOCKS_NEW_HW,
        .old_hw = state_old_hw,
    };
}

// --- Resolved constants (probed from the real headers) ---
const FIRST_GLOBAL_REGISTER: i16 = 0;
const LAST_GLOBAL_REGISTER: i16 = 136;
const FIRST_LOCAL_REGISTER: i16 = 7000;
const FIRST_NAMED_VARIABLE: i16 = 256;
const NUMBER_OF_STATISTICAL_SUMS: u16 = 28;
const C47_NULL: u16 = 65535;
const configFileVersion: u32 = 10000024; // C saveRestoreCalcState.c:7 (FLAG_SIGZEROS bump)

// --- Struct models (sizes/offsets asserted at comptime against the C ABI) ---
const abi = @import("abi"); // L1 shared bindings
const subroutineLevelHeader_t = abi.SubroutineLevelHeader;

const calcKey_t = abi.CalcKey;

const userMenuItem_t = abi.UserMenuItem;

const userMenu_t = abi.UserMenu;

const namedVariableHeader_t = abi.NamedVariableHeader;

const formulaHeader_t = extern struct {
    pointerToFormulaData: u16,
    sizeInBlocks: u8,
    unused: u8,
};

const normKey_t = extern struct {
    func: i16,
    funcParam: [16]u8,
    used: u8,
};

const pcg32_random_t = extern struct {
    state: u64,
    inc: u64,
};

comptime {
    const assert = @import("std").debug.assert;
    assert(@sizeOf(calcKey_t) == 18);
    assert(@sizeOf(userMenuItem_t) == 20);
    assert(@sizeOf(userMenu_t) == 376);
    assert(@sizeOf(namedVariableHeader_t) == 20);
    assert(@offsetOf(namedVariableHeader_t, "variableName") == 4);
    assert(@sizeOf(formulaHeader_t) == 4);
    assert(@sizeOf(normKey_t) == 20);
    assert(@offsetOf(normKey_t, "used") == 18);
    assert(@sizeOf(pcg32_random_t) == 16);
}

// --- libc / core helpers ---
extern fn ioFileWrite(buffer: ?*const anyopaque, size: u32) void;
extern fn sprintf(str: [*c]u8, format: [*c]const u8, ...) c_int;
extern fn strlen(s: [*c]const u8) usize;
extern fn strcat(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn stringToUtf8(str: [*c]const u8, utf8: [*c]u8) void;
extern fn getNthString(ptr: [*c]u8, n: i16) [*c]u8;

// --- save-serialization leaf externs (canonical core C symbols) ---
const runtime = @import("calc_state_runtime.zig");
const MNU_HOME: i16 = 1921;
extern var printerState: [16]u8; // {print_on@0:u8, printer_model@8, delay@12:u16}
extern fn setLongPressFg(calc_model0: c_int, menu_item: i16) void;

// --- core state globals ---
extern var aimBuffer1: [400]u8;
extern var globalFlags: [8]u16;
extern var currentSubroutineLevelData: ?*subroutineLevelHeader_t;
extern var currentLocalRegisters: ?*anyopaque;
extern var currentLocalFlags: ?*u32;
extern var numberOfNamedVariables: u16;
extern var allNamedVariables: [*c]namedVariableHeader_t;
extern var statisticalSumsPointer: ?*anyopaque;
extern var systemFlags0: u64;
extern var systemFlags1: u64;
extern var userKeyLabel: [*c]u8;
extern var userMenuItems: [18]userMenuItem_t;
extern var userAlphaItems: [18]userMenuItem_t;
extern var numberOfUserMenus: u16;
extern var userMenus: [*c]userMenu_t;
extern var beginOfProgramMemory: [*c]u8;
extern var currentStep: [*c]u8;
extern var firstFreeProgramByte: [*c]u8;
extern var freeProgramBytes: u16;
extern var numberOfFormulae: u16;
extern var allFormulae: [*c]formulaHeader_t;
extern var ram: [*c]u32;
extern var kbd_usr: [37]calcKey_t;
extern var Norm_Key_00: normKey_t;
extern var pcg32_global: pcg32_random_t;

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
extern var currentAngularMode: c_int; // angularMode_t (4 bytes), saved as uint8_t
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
extern var calcModel: u8;
extern var Input_Default: u8;
extern var displayStackSHOIDISP: u8;
extern var bcdDisplaySign: u8;
extern var DRG_Cycling: u8;
extern var DM_Cycling: u8;
extern var LongPressM: u8;
extern var LongPressF: u8;
extern var lastIntegerBase: u32; // saved as uint8_t
extern var amortP1: u16;
extern var amortP2: u16;
extern var lrChosen: u16;
extern var graph_dx: f32;
extern var graph_dy: f32;
extern var roundedTicks: u8;
extern var PLOT_INTG: u8;
extern var PLOT_DIFF: u8;
extern var PLOT_RMS: u8;
extern var PLOT_SHADE: u8;
extern var PLOT_AXIS: u8;
extern var PLOT_ZMY: i8;
extern var firstDayOfWeek: u8;
extern var firstWeekOfYearDay: u8;

// Section-framing scratch buffer; mirrors doSave's local `char tmpString[3000]`
// (deliberately distinct from the global tmpString into which
// registerToSaveString writes register values).
var buf: [3000]u8 = undefined;

inline fn b() [*c]u8 {
    return &buf[0];
}

fn save(bytes: [*c]const u8) void {
    ioFileWrite(bytes, @intCast(strlen(bytes)));
}

fn cu(value: anytype) c_uint {
    return @intCast(value);
}

fn ci(value: anytype) c_int {
    return @intCast(value);
}

// Program-memory pointer arithmetic, delegated to the geometry-parameterized,
// separately-tested progmem module (`zig build state-progmem-test`).
fn toC47memptr(p: [*c]const u8) u16 {
    return progmem.toC47memptr(geometry(), @intFromPtr(p));
}
fn offsetWithinBlock(p: [*c]const u8) u32 {
    return progmem.offsetWithinBlock(geometry(), @intFromPtr(p));
}
fn toPcmemptr(p: u16) [*c]u8 {
    return @ptrFromInt(progmem.toPcmemptr(geometry(), p));
}

pub fn writeSaveSections() void {
    // SAV file version number + identifying model line.
    _ = sprintf(b(), "SAVE_FILE_REVISION\n%u\n", cu(@as(u8, 0)));
    save(b());
    _ = sprintf(b(), "C47_save_file_00\n%u\n", cu(configFileVersion));
    save(b());

    // Global registers
    _ = sprintf(b(), "GLOBAL_REGISTERS\n%u\n", cu(@as(u16, @intCast(LAST_GLOBAL_REGISTER + 1))));
    save(b());
    {
        var regist: i16 = FIRST_GLOBAL_REGISTER;
        while (regist <= LAST_GLOBAL_REGISTER) : (regist += 1) {
            codec.registerToSaveString(regist, false);
            _ = sprintf(b(), "R%03d\n%s\n%s\n", ci(regist), &aimBuffer1[0], codec.regValueBuf());
            save(b());
            codec.saveMatrixElements(regist);
        }
    }

    // Global flags
    save("GLOBAL_FLAGS\n");
    _ = sprintf(b(), "%u %u %u %u %u %u %u %u\n", cu(globalFlags[0]), cu(globalFlags[1]), cu(globalFlags[2]), cu(globalFlags[3]), cu(globalFlags[4]), cu(globalFlags[5]), cu(globalFlags[6]), cu(globalFlags[7]));
    save(b());

    // Local registers
    const localRegisterCount: u8 = currentSubroutineLevelData.?.numberOfLocalRegisters;
    _ = sprintf(b(), "LOCAL_REGISTERS\n%u\n", cu(localRegisterCount));
    save(b());
    {
        var i: u32 = 0;
        while (i < localRegisterCount) : (i += 1) {
            codec.registerToSaveString(@intCast(FIRST_LOCAL_REGISTER + @as(i32, @intCast(i))), false);
            _ = sprintf(b(), "R.%02u\n%s\n%s\n", cu(i), &aimBuffer1[0], codec.regValueBuf());
            save(b());
            codec.saveMatrixElements(@intCast(FIRST_LOCAL_REGISTER + @as(i32, @intCast(i))));
        }
    }

    // Local flags
    if (currentLocalRegisters != null) {
        _ = sprintf(b(), "LOCAL_FLAGS\n%u\n", cu(currentLocalFlags.?.*));
        save(b());
    }

    // Named variables
    _ = sprintf(b(), "NAMED_VARIABLES\n%u\n", cu(numberOfNamedVariables));
    save(b());
    {
        var i: u32 = 0;
        while (i < numberOfNamedVariables) : (i += 1) {
            codec.registerToSaveString(@intCast(FIRST_NAMED_VARIABLE + @as(i32, @intCast(i))), false);
            stringToUtf8(&allNamedVariables[i].variableName[1], b());
            const n = strlen(b());
            _ = sprintf(b() + n, "\n%s\n%s\n", &aimBuffer1[0], codec.regValueBuf());
            save(b());
            codec.saveMatrixElements(@intCast(FIRST_NAMED_VARIABLE + @as(i32, @intCast(i))));
        }
    }

    // Statistical sums
    const sumsCount: u16 = if (statisticalSumsPointer != null) NUMBER_OF_STATISTICAL_SUMS else 0;
    _ = sprintf(b(), "STATISTICAL_SUMS\n%u\n", cu(sumsCount));
    save(b());
    {
        var i: u16 = 0;
        while (i < sumsCount) : (i += 1) {
            codec.statSumToString(i);
            _ = sprintf(b(), "%s\n", codec.regValueBuf());
            save(b());
        }
    }

    // System flags
    var yy1: [35]u8 = undefined;
    var yy2: [35]u8 = undefined;
    text.ui64ToString(systemFlags0, &yy1[0]);
    _ = sprintf(b(), "SYSTEM_FLAGS\n%s\n", &yy1[0]);
    save(b());
    text.ui64ToString(systemFlags1, &yy1[0]);
    _ = sprintf(b(), "SYSTEM_FLAGS1\n%s\n", &yy1[0]);
    save(b());

    // Keyboard assignments
    save("KEYBOARD_ASSIGNMENTS\n37\n");
    {
        var i: usize = 0;
        while (i < 37) : (i += 1) {
            const k = kbd_usr[i];
            _ = sprintf(b(), "%d %d %d %d %d %d %d %d %d\n", ci(k.keyId), ci(k.primary), ci(k.fShifted), ci(k.gShifted), ci(k.keyLblAim), ci(k.primaryAim), ci(k.fShiftedAim), ci(k.gShiftedAim), ci(k.primaryTam));
            save(b());
        }
    }
    if (runtime.getLoadedVersion() < 10000023) setLongPressFg(calcModel, -MNU_HOME);

    // Keyboard arguments
    save("KEYBOARD_ARGUMENTS\n");
    {
        var num: u32 = 0;
        var i: u32 = 0;
        while (i < 37 * 6) : (i += 1) {
            if (getNthString(userKeyLabel, @intCast(i))[0] != 0) {
                num += 1;
            }
        }
        _ = sprintf(b(), "%u\n", cu(num));
        save(b());

        i = 0;
        while (i < 37 * 6) : (i += 1) {
            if (getNthString(userKeyLabel, @intCast(i))[0] != 0) {
                _ = sprintf(b(), "%u ", cu(i));
                stringToUtf8(getNthString(userKeyLabel, @intCast(i)), b() + strlen(b()));
                _ = strcat(b(), "\n");
                save(b());
            }
        }
    }

    // MyMenu
    save("MYMENU\n18\n");
    saveUserMenuBlock(&userMenuItems);

    // MyAlpha
    save("MYALPHA\n18\n");
    saveUserMenuBlock(&userAlphaItems);

    // User menus
    save("USER_MENUS\n");
    _ = sprintf(b(), "%u\n", cu(numberOfUserMenus));
    save(b());
    {
        var j: u32 = 0;
        while (j < numberOfUserMenus) : (j += 1) {
            stringToUtf8(&userMenus[j].menuName[0], b());
            _ = strcat(b(), "\n18\n");
            save(b());
            saveUserMenuBlock(&userMenus[j].menuItem);
        }
    }

    // Programs
    const currentSizeInBlocks: u16 = progmem.programSizeInBlocks(geometry(), @intFromPtr(beginOfProgramMemory));
    _ = sprintf(b(), "PROGRAMS\n%u\n", cu(currentSizeInBlocks));
    save(b());
    _ = sprintf(b(), "%u\n%u\n", cu(toC47memptr(currentStep)), cu(offsetWithinBlock(currentStep)));
    save(b());
    _ = sprintf(b(), "%u\n%u\n", cu(toC47memptr(firstFreeProgramByte)), cu(offsetWithinBlock(firstFreeProgramByte)));
    save(b());
    _ = sprintf(b(), "%u\n", cu(freeProgramBytes));
    save(b());
    {
        const progWords: [*c]u32 = @ptrCast(@alignCast(beginOfProgramMemory));
        var i: u16 = 0;
        while (i < currentSizeInBlocks) : (i += 1) {
            _ = sprintf(b(), "%u\n", cu(progWords[i]));
            save(b());
        }
    }

    // Equations
    _ = sprintf(b(), "EQUATIONS\n%u\n", cu(numberOfFormulae));
    save(b());
    {
        var i: u32 = 0;
        while (i < numberOfFormulae) : (i += 1) {
            stringToUtf8(toPcmemptr(allFormulae[i].pointerToFormulaData), b());
            _ = strcat(b(), "\n");
            save(b());
        }
    }

    // Other configuration stuff
    _ = sprintf(b(), "OTHER_CONFIGURATION_STUFF\n00\n");
    save(b());
    save(b()); // historical repeat (now a short-circuit marker on load)

    saveField("firstGregorianDay", "%u\n", .{cu(firstGregorianDay)});
    saveField("denMax", "%u\n", .{cu(denMax)});
    saveField("lastDenominator", "%u\n", .{cu(lastDenominator)});
    saveField("displayFormat", "%u\n", .{cu(displayFormat)});
    saveField("displayFormatDigits", "%u\n", .{cu(displayFormatDigits)});
    saveField("timeDisplayFormatDigits", "%u\n", .{cu(timeDisplayFormatDigits)});
    saveField("shortIntegerWordSize", "%u\n", .{cu(shortIntegerWordSize)});
    saveField("shortIntegerMode", "%u\n", .{cu(shortIntegerMode)});
    saveField("significantDigits", "%u\n", .{cu(significantDigits)});
    saveField("fractionDigits", "%u\n", .{cu(fractionDigits)});
    saveField("currentAngularMode", "%u\n", .{cu(@as(u8, @truncate(@as(u32, @bitCast(currentAngularMode)))))});
    saveField("gapItemLeft", "%u\n", .{cu(gapItemLeft)});
    saveField("gapItemRight", "%u\n", .{cu(gapItemRight)});
    saveField("gapItemRadix", "%u\n", .{cu(gapItemRadix)});
    saveField("lastCenturyHighUsed", "%u\n", .{cu(lastCenturyHighUsed)});
    saveField("grpGroupingLeft", "%u\n", .{cu(grpGroupingLeft)});
    saveField("grpGroupingGr1LeftOverflow", "%u\n", .{cu(grpGroupingGr1LeftOverflow)});
    saveField("grpGroupingGr1Left", "%u\n", .{cu(grpGroupingGr1Left)});
    saveField("grpGroupingRight", "%u\n", .{cu(grpGroupingRight)});
    saveField("roundingMode", "%u\n", .{cu(roundingMode)});
    saveField("displayStack", "%u\n", .{cu(displayStack)});

    text.ui64ToString(pcg32_global.state, &yy1[0]);
    text.ui64ToString(pcg32_global.inc, &yy2[0]);
    _ = sprintf(b(), "rngState\n%s %s\n", &yy1[0], &yy2[0]);
    save(b());

    saveField("exponentLimit", "%d\n", .{ci(exponentLimit)});
    saveField("exponentHideLimit", "%d\n", .{ci(exponentHideLimit)});
    saveField("bestF", "%u\n", .{cu(lrSelection)});
    saveField("dispBase", "%u\n", .{cu(dispBase)});
    saveField("calcModel", "%d\n", .{ci(@as(i16, calcModel))});
    saveField("Norm_Key_00.func", "%d\n", .{ci(Norm_Key_00.func)});
    {
        const paramPtr: [*c]const u8 = if (Norm_Key_00.funcParam[0] == 0) "NoNormKeyParamDef" else &Norm_Key_00.funcParam[0];
        _ = sprintf(b(), "Norm_Key_00.funcParam\n%s\n", paramPtr);
        save(b());
    }
    saveField("Norm_Key_00.used", "%u\n", .{cu(Norm_Key_00.used)});
    saveField("Input_Default", "%u\n", .{cu(Input_Default)});
    saveField("displayStackSHOIDISP", "%u\n", .{cu(displayStackSHOIDISP)});
    saveField("bcdDisplaySign", "%u\n", .{cu(bcdDisplaySign)});
    saveField("DRG_Cycling", "%u\n", .{cu(DRG_Cycling)});
    saveField("DM_Cycling", "%u\n", .{cu(DM_Cycling)});
    saveField("LongPressM", "%u\n", .{cu(LongPressM)});
    saveField("LongPressF", "%u\n", .{cu(LongPressF)});
    saveField("lastIntegerBase", "%u\n", .{cu(@as(u8, @truncate(lastIntegerBase)))});
    saveField("amortP1", "%u\n", .{cu(amortP1)});
    saveField("amortP2", "%u\n", .{cu(amortP2)});
    saveField("lrChosen", "%u\n", .{cu(lrChosen)});
    saveField("graph_dx", "%f\n", .{@as(f64, graph_dx)});
    saveField("graph_dy", "%f\n", .{@as(f64, graph_dy)});
    saveField("roundedTicks", "%u\n", .{cu(roundedTicks)});
    saveField("PLOT_INTG", "%u\n", .{cu(PLOT_INTG)});
    saveField("PLOT_DIFF", "%u\n", .{cu(PLOT_DIFF)});
    saveField("PLOT_RMS", "%u\n", .{cu(PLOT_RMS)});
    saveField("PLOT_SHADE", "%u\n", .{cu(PLOT_SHADE)});
    saveField("PLOT_AXIS", "%u\n", .{cu(PLOT_AXIS)});
    saveField("PLOT_ZMY", "%u\n", .{cu(@as(u8, @bitCast(PLOT_ZMY)))});
    saveField("firstDayOfWeek", "%u\n", .{cu(firstDayOfWeek)});
    saveField("firstWeekOfYearDay", "%u\n", .{cu(firstWeekOfYearDay)});

    {
        const pdelay = @as(*const u16, @ptrCast(@alignCast(&printerState[12]))).*;
        saveField("printerOn", "%u\n", .{cu(printerState[0])});
        saveField("printerModel", "%u\n", .{cu(printerState[8])});
        saveField("printerLineDelay", "%u\n", .{cu(pdelay)});
    }

    _ = sprintf(b(), "END_OTHER_PARAM\n");
    save(b());
}

// Emit one `name\n<value>` config line. `value_format` is the C printf format
// for the value portion (e.g. "%u\n"); args are the already-promoted variadic
// arguments matching it.
fn saveField(comptime name: []const u8, comptime value_format: []const u8, args: anytype) void {
    _ = @call(.auto, sprintf, .{ b(), name ++ "\n" ++ value_format } ++ args);
    save(b());
}

// MYMENU / MYALPHA / per-user-menu item block: 18 items, each `item` then an
// optional space + utf8 argument name, then newline.
fn saveUserMenuBlock(items: [*c]const userMenuItem_t) void {
    var i: usize = 0;
    while (i < 18) : (i += 1) {
        _ = sprintf(b(), "%d", ci(items[i].item));
        if (items[i].argumentName[0] != 0) {
            _ = strcat(b(), " ");
            stringToUtf8(&items[i].argumentName[0], b() + strlen(b()));
        }
        _ = strcat(b(), "\n");
        save(b());
    }
}

// ===========================================================================
// Data-file register export (DATA_FILE format).
//
// Faithful port of saveRestoreCalcState.c's fnSaveDataRegisters / doSaveDataFile
// and the five fnSave* item entry points. These write a register-only file (via
// ioPathRegExport) with codec.dataFileMode = true so the compact human-readable
// value forms are emitted. EXTRA_INFO_ON_CALC_ERROR is 0 in TESTSUITE_BUILD, so
// the moreInfoOnError branches are intentionally omitted (they don't compile in
// the reference build either). Round-trip verified by the save/load parity test.
// ===========================================================================

const FIRST_LETTERED_REGISTER: i16 = 100;
const LAST_SPARE_REGISTER: u16 = 125;
const REGISTER_X_REG: u16 = 100;
const REGISTER_W_REG: u16 = 125;
const ERR_REGISTER_LINE: i16 = 102; // REGISTER_Z
const REGISTER_X_LINE: i16 = 100;
const INVALID_VARIABLE: i16 = 2199;
const FLAG_SSIZE8: c_int = 0x8018;
const TI_DATA_SAVED: u16 = 143;
const ERROR_CANNOT_WRITE_FILE: u8 = 55;
const ERROR_OUT_OF_RANGE: u8 = 8;
const SCRUPD_AUTO_MODE: u8 = 0x00;
const FILE_OK_RC: c_int = 1;
const FILE_CANCEL_RC: c_int = 2;
const ioModeWrite_MODE: c_int = 1;
const ioPathRegExport_PATH: c_int = 15;
const isXFN: bool = true; // master's `#define isXFN true`

const registerLetters = "XYZTABCDLIJKMNPQRSEFGHOUVW";

extern fn ioFileOpen(path: c_int, mode: c_int) c_int;
extern fn ioFileClose() void;
extern fn refreshScreen(caller: u16) void;
extern fn showHideHourGlass() void;
extern fn displayCalcErrorMessage(error_code: u8, errMessageRegisterLine: i16, errRegisterLine: i16) void;
extern fn findNamedVariable(variableName: [*c]const u8) i16;
extern fn getSystemFlag(sf: c_int) bool;
extern var screenUpdatingMode: u8;
extern var temporaryInformation: u16;
extern var hourGlassIconEnabled: bool;

fn registerNumberToString(regist: i16, name: [*c]u8) void {
    if (regist >= FIRST_LETTERED_REGISTER and regist <= @as(i16, @intCast(LAST_SPARE_REGISTER))) {
        _ = sprintf(name, "R%c", @as(c_int, registerLetters[@intCast(regist - FIRST_LETTERED_REGISTER)]));
    } else {
        _ = sprintf(name, "R%03d", ci(regist));
    }
}

// Appends a register section to the already-open file: header, count, then one
// id/type/value (+ matrix element) block per register. registerName != null
// saves that single named variable; otherwise the range *beginR..*endR.
pub fn fnSaveDataRegisters(beginR: ?*const u16, endR: ?*const u16, registerName: [*c]const u8, isXFNRegister: bool) bool {
    if (registerName != null) {
        const regist = findNamedVariable(registerName); // read-only lookup: must not allocate
        if (regist == INVALID_VARIABLE) return false;
        _ = sprintf(b(), "NAMED_VARIABLES\n%u\n", cu(@as(u16, 1)));
        save(b());
        codec.registerToSaveString(regist, !isXFN);
        _ = sprintf(b(), "%s\n%s\n%s\n", registerName, &aimBuffer1[0], codec.regValueBuf());
        save(b());
        codec.saveMatrixElements(regist);
        return true;
    }

    if (beginR == null or endR == null or endR.?.* < beginR.?.*) return false;

    _ = sprintf(b(), "GLOBAL_REGISTERS\n%u\n", cu(@as(u16, @intCast(endR.?.* - beginR.?.* + 1))));
    save(b());
    var regName: [16]u8 = undefined;
    var regist: i16 = @intCast(beginR.?.*);
    while (regist <= @as(i16, @intCast(endR.?.*))) : (regist += 1) {
        codec.registerToSaveString(regist, isXFNRegister);
        registerNumberToString(regist, &regName[0]);
        _ = sprintf(b(), "%s\n%s\n%s\n", &regName[0], &aimBuffer1[0], codec.regValueBuf());
        save(b());
        codec.saveMatrixElements(regist); // only emits when the register really is a matrix
    }
    return true;
}

fn doSaveDataFile(beginR: ?*const u16, endR: ?*const u16, registerName: [*c]const u8, isXFNRegister: bool) void {
    const ret = ioFileOpen(ioPathRegExport_PATH, ioModeWrite_MODE);
    if (ret != FILE_OK_RC) {
        if (ret == FILE_CANCEL_RC) {
            screenUpdatingMode = SCRUPD_AUTO_MODE;
            refreshScreen(2996);
            return;
        } else {
            displayCalcErrorMessage(ERROR_CANNOT_WRITE_FILE, ERR_REGISTER_LINE, REGISTER_X_LINE);
            return;
        }
    }

    hourGlassIconEnabled = true;
    showHideHourGlass();

    codec.dataFileMode = true; // compact human-readable value forms for this file
    _ = sprintf(b(), "DATA_FILE_REVISION\n%u\n", cu(@as(u8, 0)));
    save(b());

    _ = fnSaveDataRegisters(beginR, endR, registerName, isXFNRegister);

    codec.dataFileMode = false;
    ioFileClose();
    temporaryInformation = TI_DATA_SAVED;

    screenUpdatingMode = SCRUPD_AUTO_MODE;
    refreshScreen(2997);
}

pub export fn fnSaveStackRegisters(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var beginR: u16 = REGISTER_X_REG;
    var endR: u16 = REGISTER_X_REG + @as(u16, if (getSystemFlag(FLAG_SSIZE8)) 7 else 3);
    doSaveDataFile(&beginR, &endR, null, !isXFN);
}

pub export fn fnSaveLetteredRegisters(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var beginR: u16 = REGISTER_X_REG;
    var endR: u16 = REGISTER_W_REG;
    doSaveDataFile(&beginR, &endR, null, !isXFN);
}

pub export fn fnSaveNRegisters(N: u16) callconv(.c) void {
    if (N >= 1 and N <= LAST_SPARE_REGISTER + 1) { // N registers = 0..N-1; max is all 126 (0..125, i.e. up to RW)
        var beginR: u16 = 0;
        var endR: u16 = N - 1;
        doSaveDataFile(&beginR, &endR, null, !isXFN);
    } else {
        displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X_LINE);
    }
}

pub export fn fnSaveRegister(regist: u16) callconv(.c) void {
    if (@as(i32, regist) >= @as(i32, FIRST_NAMED_VARIABLE) and
        @as(i32, regist) < @as(i32, FIRST_NAMED_VARIABLE) + @as(i32, numberOfNamedVariables))
    {
        var varName: [16]u8 = undefined;
        const idx: usize = @as(usize, regist) - @as(usize, @intCast(FIRST_NAMED_VARIABLE));
        stringToUtf8(&allNamedVariables[idx].variableName[1], &varName[0]); // named variable: save by name
        doSaveDataFile(null, null, &varName[0], !isXFN);
    } else if (regist <= LAST_SPARE_REGISTER) {
        var beginR: u16 = regist;
        var endR: u16 = regist;
        doSaveDataFile(&beginR, &endR, null, !isXFN); // numbered or lettered register: save by number (through RW = LAST_SPARE_REGISTER)
    } else {
        displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X_LINE);
    }
}

pub export fn fnSaveXFNRegister(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    const regist: u16 = REGISTER_X_REG;
    if (regist < LAST_SPARE_REGISTER - 2) {
        var beginR: u16 = regist;
        var endR: u16 = regist;
        doSaveDataFile(&beginR, &endR, null, isXFN);
    } else {
        displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X_LINE);
    }
}
