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
// (`zig build saveload_parity`): restore reconstructs state such that re-saving
// is byte-identical to the original save.

const std = @import("std");
const runtime = @import("calc_state_runtime.zig");
const text = @import("calc_state_text.zig");
const progmem = @import("calc_state_progmem.zig");
const build_options = @import("calc_state_build_options");

const state_old_hw = @hasDecl(build_options, "state_old_hw") and build_options.state_old_hw;
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
// currentNumberOfLocalRegisters macro: currentSubroutineLevelData->numberOfLocalRegisters.
const subroutineLevelHeader_t = abi.SubroutineLevelHeader;
extern var currentSubroutineLevelData: [*c]subroutineLevelHeader_t;
inline fn currentNumberOfLocalRegisters() u8 {
    return currentSubroutineLevelData[0].numberOfLocalRegisters;
}
const FIRST_NAMED_VARIABLE: i16 = 256;
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

const ITM_END: i32 = 1458;
const MNU_HOME: i16 = 1921;
const MNU_MyMenu: i16 = 1349;
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
fn kbdStdPrimary(idx: i16) i16 {
    const std_kbd: *const [37]calcKey_t = switch (@as(u16, calcModel)) {
        USER_DM42 => &kbd_std_DM42,
        USER_R47f_g => &kbd_std_R47f_g,
        USER_R47bk_fg => &kbd_std_R47bk_fg,
        USER_R47fg_bk => &kbd_std_R47fg_bk,
        USER_R47fg_g => &kbd_std_R47fg_g,
        else => &kbd_std_C47,
    };
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
extern var programList: [*c]programList_t;
extern var numberOfFormulae: u16;
extern var currentFormula: u16;
extern var allFormulae: [*c]formulaHeader_t;
extern var currentLocalFlags: ?*u32;
extern var ram: [*c]u32;
extern var pcg32_global: pcg32_random_t;
extern var calcModel: u8;
extern var hourGlassIconEnabled: bool;
extern var cancelFilename: bool;

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
            allocateLocalRegisters(@intCast(numberOfRegs));
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
    const programsLoadMode: u16 = if (numberOfBlocks == 0) LM_SYSTEM_STATE else load_mode;
    if (programsLoadMode == LM_ALL) {
        resizeProgramMemory(numberOfBlocks);
    } else if (programsLoadMode == LM_PROGRAMS) {
        // @truncate, not @intCast. Upstream saveRestoreCalcState.c:2080 is
        // `resizeProgramMemory(oldSizeInBlocks + numberOfBlocks)` with both
        // operands uint16_t and the parameter uint16_t (memory.c:158), so C
        // promotes to int and the implicit conversion back to the parameter
        // TRUNCATES -- defined behaviour. numberOfBlocks is toUint16 of a line the
        // state file supplies and oldSizeInBlocks reaches RAM_SIZE_IN_BLOCKS, so
        // the sum passes 65535 on a crafted file: @intCast made that illegal
        // behaviour where upstream is defined, trapping on a safe build and, since
        // the load path raises runtime safety, on the device too.
        resizeProgramMemory(@truncate(@as(u32, oldSizeInBlocks) + numberOfBlocks));
        oldFirstFreeProgramByte = beginOfProgramMemory + TO_BYTES(oldSizeInBlocks) - oldFreeProgramBytes - 2;
    }

    calc_state.readLine(tmpString, TMP_STR_LENGTH); // currentStep block pointer
    if (programsLoadMode == LM_ALL) {
        currentStep = toPcmemptr(text.toUint32(tmpString));
    }
    calc_state.readLine(tmpString, TMP_STR_LENGTH); // currentStep offset within block
    if (programsLoadMode == LM_ALL) {
        currentStep += text.toUint32(tmpString);
    } else if (programsLoadMode == LM_PROGRAMS) {
        if (programList[@intCast(@as(i32, currentProgramNumber) - 1)].step > 0) {
            currentStep -= TO_BYTES(numberOfBlocks);
            firstDisplayedStep -= TO_BYTES(numberOfBlocks);
            beginOfCurrentProgram -= TO_BYTES(numberOfBlocks);
            endOfCurrentProgram -= TO_BYTES(numberOfBlocks);
        }
    }

    calc_state.readLine(tmpString, TMP_STR_LENGTH); // firstFreeProgramByte block pointer
    if (programsLoadMode == LM_ALL or programsLoadMode == LM_PROGRAMS) {
        firstFreeProgramByte = toPcmemptr(text.toUint32(tmpString));
    }
    calc_state.readLine(tmpString, TMP_STR_LENGTH); // firstFreeProgramByte offset within block
    if (programsLoadMode == LM_ALL or programsLoadMode == LM_PROGRAMS) {
        firstFreeProgramByte += text.toUint32(tmpString);
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
    var i: i16 = 0;
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
        scanLabelsAndPrograms();
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
