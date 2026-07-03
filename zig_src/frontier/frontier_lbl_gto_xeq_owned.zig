// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/programming/lblGtoXeq.c: the program-execution engine.
// fnGoto/fnGotoDot/goToGlobalStep/goToPgmStep resolve labels and navigate the
// program counter; fnExecute/fnExecutePlusSkip/fnReturn maintain the subroutine
// call stack; fnRunProgram/fnStopProgram/runProgram/execProgram drive the run
// loop; executeOneStep is the per-step opcode dispatcher; _executeOp/_putLiteral
// decode parameters and literals. Exercised by src/testSuite/tests/programs.txt
// (part of the 9530-test suite), so `zig build test` verifies correctness.
//
// Faithful, line-by-line port of the C. The IR_PRINTING and
// PC_BUILD+DEBUG_EXECUTE blocks in executeOneStep are omitted (never defined for
// any z47 build). The DMCP_BUILD key-poll block in runProgram is firmware-only
// (gated on dmcp_build); the host uses refreshLcd. EXTRA_INFO sprintf hints are
// reduced to fixed moreInfoOnError() strings as in the sibling owners; the
// tmpString sprintf bug-paths are dropped (their control flow is a no-op). This
// file is hot (executeOneStep runs per program step) so it stays in main .text.

const builtin = @import("builtin");
const frontier_build_options = @import("frontier_build_options");
const extra_info: bool = frontier_build_options.extra_info_on_calc_error;
const dmcp_build: bool = frontier_build_options.dmcp_build;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const calcRegister_t = i16;
const bool_t = u32;
const angularMode_t = c_int;
const localFlags_t = u32;

const abi = @import("abi"); // L1 shared bindings (REPORT-23 §5)
const real34_t = abi.Real34;
const complex34_t = extern struct { real: real34_t, imag: real34_t };

// GMP mpz_struct. Limb width == pointer width on every z47 target (NOT c_ulong:
// Win64 is LLP64). Matches the registerValueConversions owner.
const mp_limb_t = usize;
const mpz_struct = extern struct {
    _mp_alloc: c_int,
    _mp_size: c_int,
    _mp_d: [*c]mp_limb_t,
};
extern fn @"__gmpz_init"(p: *mpz_struct) void;
extern fn @"__gmpz_clear"(p: *mpz_struct) void;
extern fn @"__gmpz_set_str"(p: *mpz_struct, str: [*c]const u8, base: c_int) c_int;
const mpz_init = @"__gmpz_init";
const mpz_clear = @"__gmpz_clear";
const mpz_set_str = @"__gmpz_set_str";

const subroutineLevelHeader_t = abi.SubroutineLevelHeader;

const subroutineLevels_t = extern struct {
    numberOfSubroutineLevels: u16,
    ptrToSubroutineLevel0Header: u16,
};

const register_header_t = extern union {
    descriptor: u32,
};

const labelList_t = extern struct {
    program: i16,
    step: i32,
    labelPointer: [*c]u8,
    instructionPointer: [*c]u8,
};

const programList_t = extern struct {
    step: i32,
    instructionPointer: [*c]u8,
};

const item_t = abi.Item;

const softmenu_t = abi.Softmenu;

const softmenuStack_t = extern struct {
    softmenuId: i16,
    firstItem: i16,
    userMenuId: i16,
    calcMode: u8,
};

// tam: only the first field (mode) is accessed.
const tamState_t = extern struct {
    mode: u16,
};

// ---------------------------------------------------------------------------
// Constants / enum values
// ---------------------------------------------------------------------------
const C47_NULL: u16 = 65535;

const LAST_LOCAL_LABEL: u16 = 123;
const LAST_UC_LOCAL_LABEL: u16 = 111;
const FIRST_LC_LOCAL_LABEL: u16 = 112;
const REGISTER_X_IN_KS_CODE: u16 = 100;
const FIRST_LABEL: u16 = 2200;
const LAST_LABEL: u16 = 6999;

const LAST_LOCAL_FLAG: u8 = 143;
const FLAG_M: u8 = 211;
const FLAG_W: u8 = 224;

const FIRST_STAT_REGISTER_IN_KS_CODE: i16 = 211;
const LAST_SPARE_REGISTERS_IN_KS_CODE: u8 = 224;
const NUMBER_OF_LOCAL_REGISTERS: i16 = 99;
const FIRST_LOCAL_REGISTER_IN_KS_CODE: i16 = 112;
const LAST_LOCAL_REGISTER_IN_KS_CODE: i16 = 210;
const FIRST_LOCAL_REGISTER: i16 = 7000;

const SYSTEM_FLAG_NUMBER: u8 = 250;
const VALUE_0: u8 = 251;
const VALUE_1: u8 = 252;
const CNST_BEYOND_250: u8 = 250;
const STRING_LABEL_VARIABLE: u8 = 253;
const INDIRECT_REGISTER: u8 = 254;
const INDIRECT_VARIABLE: u8 = 255;
const FAILED_INDIRECTION: i16 = 9999;

const TAM_MAX_BITS: u4 = 14;
const TAM_MAX_MASK: u16 = 0x3fff;

const INVALID_VARIABLE: calcRegister_t = 2199;
const INVALID_MENU: i16 = 2791;
const TEMP_REGISTER_1: calcRegister_t = 135;
const NOPARAM: u16 = 9876;
const REGISTER_X: calcRegister_t = 100;
const REGISTER_T: calcRegister_t = 103;

const PARAM_DECLARE_LABEL: u16 = 1;
const PARAM_LABEL: u16 = 2;
const PARAM_REGISTER: u16 = 3;
const PARAM_FLAG: u16 = 4;
const PARAM_NUMBER_8: u16 = 5;
const PARAM_NUMBER_16: u16 = 6;
const PARAM_COMPARE: u16 = 7;
const PARAM_SKIP_BACK: u16 = 9;
const PARAM_NUMBER_8_16: u16 = 10;
const PARAM_SHUFFLE: u16 = 11;
const PARAM_MENU: u16 = 12;

const PTP_STATUS: u16 = 0x1e00;
const PTP_NONE: u16 = 0 << 9;
const PTP_DECLARE_LABEL: u16 = 1 << 9;
const PTP_KEYG_KEYX: u16 = 8 << 9;
const PTP_LITERAL: u16 = 13 << 9;
const PTP_REM: u16 = 14 << 9;
const PTP_DISABLED: u16 = 15 << 9;

const BINARY_SHORT_INTEGER: u8 = 1;
const BINARY_REAL34: u8 = 3;
const BINARY_COMPLEX34: u8 = 4;
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
// STRING_LABEL_VARIABLE in _putLiteral reuses the KS-code enum value 253.

const ITM_GTO: u16 = 2;
const ITM_XEQ: u16 = 3;
const ITM_RTN: u16 = 4;
const ITM_STOP: u16 = 70;
const ITM_BACK: u16 = 1412;
const ITM_CASE: u16 = 1418;
const ITM_END: u16 = 1458;
const ITM_LBLQ: u16 = 1503;
const ITM_RTNP1: u16 = 1579;
const ITM_SKIP: u16 = 1603;
const ITM_SOLVE: u16 = 1608;
const ITM_42STRING: u16 = 2775;
const ITM_42APPEND: u16 = 2776;

const SFL_TDM24: u16 = 463;
const SFL_MONIT: u16 = 2251;

const TI_FALSE: u8 = 12;
const TI_TRUE: u8 = 13;
const TI_NO_INFO: u8 = 0;
const TI_VIEW_REGISTER: u8 = 15;
const TI_SOLVER_FAILED: u8 = 52;

const amRadian: angularMode_t = 0;
const amGrad: angularMode_t = 1;
const amDegree: angularMode_t = 2;
const amDMS: angularMode_t = 3;
const amMultPi: angularMode_t = 4;
const amNone: angularMode_t = 5;

const dtLongInteger: u32 = 0;
const dtReal34: u32 = 1;
const dtComplex34: u32 = 2;
const dtDate: u32 = 4;
const dtString: u32 = 5;
const dtShortInteger: u32 = 8;

const REAL34_SIZE_IN_BYTES: u32 = 16;
const SHORT_INTEGER_SIZE_IN_BLOCKS: u16 = 2;

const ERROR_NONE: u8 = 0;
const ERROR_LABEL_NOT_FOUND: u8 = 6;
const ERROR_RAM_FULL: u8 = 11;
const ERROR_UNDEF_SOURCE_VAR: u8 = 36;
const ERROR_NON_PROGRAMMABLE_COMMAND: u8 = 50;
const ERROR_UNDEF_MENU: u8 = 59;
const ERROR_SOLVER_ABORT: u8 = 60;
const ERROR_NO_STRING_IN_ALPHA_REGISTER: u8 = 64;

const PGM_STOPPED: u8 = 0;
const PGM_RUNNING: u8 = 1;
const PGM_WAITING: u8 = 2;

const CM_PEM: u8 = 3;

const SCRUPD_AUTO: u8 = 0x00;
const SCRUPD_MANUAL_STATUSBAR: u8 = 0x01;
const SCRUPD_SKIP_STATUSBAR_ONE_TIME: u8 = 0x10;
const SCRUPD_SKIP_STACK_ONE_TIME: u8 = 0x20;

const FLAG_ASLIFT: c_uint = 0xc023;
const FLAG_INTING: c_int = 0xc025;
const FLAG_SOLVING: c_int = 0xc026;

const SOLVER_STATUS_USES_FORMULA: u16 = 0x0100;

const MNU_PROG: i16 = 1392;
const MNU_PROGS: i16 = 1355;

const REGISTER_Z: calcRegister_t = 102;
const ERR_REGISTER_LINE: calcRegister_t = REGISTER_Z;
const NIM_REGISTER_LINE: calcRegister_t = REGISTER_X;

// DMCP key-poll constants (firmware only).
const DISPLAY_WAIT_FOR_RELEASE: bool_t = 1;
const TO_KB_ACTV: u8 = 10;
const PROGRAM_KB_ACTV: u32 = 60000;

// ---------------------------------------------------------------------------
// Globals (extern var/const)
// ---------------------------------------------------------------------------
extern var ram: [*c]u32;

extern var tam: tamState_t;
extern var calcMode: u8;
extern var dynamicMenuItem: i16;
extern var numberOfLabels: u16;
extern var labelList: [*c]labelList_t;
extern var programList: [*c]programList_t;
const LAST_ITEM: u32 = 2860;
extern const indexOfItems: [LAST_ITEM + 1]item_t;
const SOFTMENU_STACK_SIZE: usize = 8;
// softmenu[] and softmenuStack[] are real C arrays: the linker symbol address is
// the array base, so declare them as array types (NOT pointers — a [*c] extern
// var would load a pointer FROM the symbol). softmenu's length is irrelevant for
// indexing; use the indexOfItems trick with a generous sentinel-free array.
extern const softmenu: [LAST_ITEM]softmenu_t;
extern var softmenuStack: [SOFTMENU_STACK_SIZE]softmenuStack_t;

extern var currentProgramNumber: u16;
extern var currentLocalStepNumber: u16;
extern var currentStep: [*c]u8;
extern var alphaRegister: u16;
extern var beginOfCurrentProgram: [*c]u8;
extern var firstDisplayedStep: [*c]u8;
extern var firstDisplayedLocalStepNumber: u16;

extern var programRunStop: u8;
extern var lastErrorCode: u8;
extern var previousErrorCode: u8;
extern var temporaryInformation: u8;
extern var screenUpdatingMode: u8;
extern var hourGlassIconEnabled: bool_t;
extern var pemCursorIsZerothStep: bool_t;
extern var entryStatus: u8;
extern var currentInputVariable: u16;
extern var currentSolverStatus: u16;

extern var allSubroutineLevels: subroutineLevels_t;
extern var currentSubroutineLevelData: ?*subroutineLevelHeader_t;
extern var currentLocalFlags: ?*localFlags_t;
extern var currentLocalRegisters: ?[*]register_header_t;

extern var tmpStringLabelOrVariableName: [*c]u8;
extern var firstFreeProgramByte: [*c]u8;
extern var errorMessage: [*c]u8;

extern var ctxtReal34: anyopaque;

// ---------------------------------------------------------------------------
// Function externs
// ---------------------------------------------------------------------------
extern fn displayCalcErrorMessage(errorCode: u8, errMessageRegisterLine: calcRegister_t, errRegisterLine: calcRegister_t) void;
const c_moreInfoOnError = @extern(*const fn (m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) callconv(.c) void, .{ .name = "moreInfoOnError" });

extern fn liftStack() void;
extern fn setSystemFlag(sf: c_uint) void;
extern fn getSystemFlag(sf: c_int) bool;
extern fn fnSkip(numberOfSteps: u16) void;
extern fn fnBack(numberOfSteps: u16) void;
extern fn fnDropY(unusedButMandatoryParameter: u16) void;
extern fn fnStore(r: u16) void;

extern fn reallyRunFunction(func: i16, param: u16) void;
extern fn runFunction(func: i16) void;
extern fn fn42Alpha(unusedButMandatoryParameter: u16) void;
extern fn fn42Append(unusedButMandatoryParameter: u16) void;

extern fn indirectAddressing(regist: calcRegister_t, parameterType: u16, minValue: i16, maxValue: i16, tryAllocate: bool_t) i16;
extern fn indirectionType(func: u16) u16;
extern fn isFunctionAllowingNewVariable(op: u16) bool_t;
extern fn isFunctionOldParam16(func: u16) bool_t;
extern fn regInRange(r: u16) bool_t;

extern fn findNamedVariable(variableName: [*c]const u8) calcRegister_t;
extern fn findNamedLabel(labelName: [*c]const u8) calcRegister_t;
extern fn findOrAllocateNamedVariable(variableName: [*c]const u8) calcRegister_t;
extern fn findMenu(buffer: [*c]u8) i16;

extern fn findNextStep(step: [*c]u8) [*c]u8;
extern fn defineCurrentStep() void;
extern fn defineCurrentProgramFromGlobalStepNumber(globalStepNumber: i16) void;
extern fn getNumberOfSteps() u16;
extern fn defineFirstDisplayedStep() void;
extern fn isAtEndOfPrograms(step: [*c]const u8) bool_t;
extern fn checkOpCodeOfStep(step: [*c]const u8, op: u16) bool_t;
extern fn insertStepInProgram(func: i16) void;

extern fn convertLongIntegerToShortIntegerRegister(lgInt: *mpz_struct, base: u32, destination: calcRegister_t) void;
extern fn convertLongIntegerToLongIntegerRegister(longInteger: *const mpz_struct, regist: calcRegister_t) void;
extern fn reallocateRegister(regist: calcRegister_t, dataType: u32, dataSizeWithoutDataLenBlocks: u16, tag: u32) void;
extern fn getRegisterDataType(regist: calcRegister_t) u32;
extern fn getRegisterDataPointer(regist: calcRegister_t) *anyopaque;
extern fn setRegisterTag(regist: calcRegister_t, tag: u32) void;

extern fn julianDayToInternalDate(source: *const real34_t, destination: *real34_t) void;
extern fn hmmssInRegisterToSeconds(regist: calcRegister_t) void;
extern fn real34FromDmsToDeg(angleDms: *const real34_t, angleDec: *real34_t) void;

extern fn refreshScreen(source: u16) void;
extern fn refreshLcd(surface: ?*anyopaque) void;
extern fn leaveTamModeIfEnabled() void;
extern fn showHideHourGlass() void;

extern fn xcopy(dest: *anyopaque, source: *const anyopaque, n: u32) *anyopaque;
extern fn strlen(s: [*c]const u8) usize;
extern fn dynmenuGetLabel(menuitem: i16) [*c]u8;
extern fn dynmenuGetLabelWithDup(menuitem: i16, dupNum: *i16) [*c]u8;

// decQuad helpers (the real34 macros / literal helpers).
extern fn decQuadFromInt32(r: *real34_t, v: i32) *real34_t;
extern fn decQuadZero(r: *real34_t) *real34_t;
extern fn decQuadFromString(r: *real34_t, s: [*c]const u8, ctx: *anyopaque) *real34_t;

// C47 functions (always linkable, both host and firmware).
extern fn C47PopKeyNoBuffer(displayWaitForRelease: bool_t) c_int;
extern fn fnTimerStart(nr: u8, param: u16, time: u32) void;
extern fn setLastKeyCode(key: c_int) void;

// DMCP SDK functions. On firmware these live in the calculator ROM and are
// reached through the fixed library-function jump table (LIBRARY_FN_BASE +
// offset), matching the sibling owners (error.c's lcd_fill_rect, dateTime's
// rtc_read) and the firmware_io_runtime offsets. On the host they are real
// linkable symbols (gtk_lcd_runtime). They are only called inside dmcp_build
// comptime blocks (lcd_refresh has a host call too, so keep the host extern).
const old_hw: bool = frontier_build_options.old_hw;
const library_fn_base: usize = if (old_hw) 0x08000201 else 0x08000301;
const lcd_refresh_offset: usize = 48;
const wait_for_key_release_offset: usize = 420;
const key_pop_offset: usize = 392;

const VoidFn = *const fn () callconv(.c) void;
const WaitForKeyReleaseFn = *const fn (tout: c_int) callconv(.c) void;
const KeyPopFn = *const fn () callconv(.c) c_int;

extern fn lcd_refresh() void; // host symbol; firmware path uses the trampoline.
inline fn lcdRefresh() void {
    if (comptime dmcp_build) {
        const f: VoidFn = @ptrFromInt(library_fn_base + lcd_refresh_offset);
        f();
    } else {
        lcd_refresh();
    }
}
inline fn waitForKeyRelease(tout: c_int) void {
    const f: WaitForKeyReleaseFn = @ptrFromInt(library_fn_base + wait_for_key_release_offset);
    f(tout);
}
inline fn keyPop() c_int {
    const f: KeyPopFn = @ptrFromInt(library_fn_base + key_pop_offset);
    return f();
}

// ---------------------------------------------------------------------------
// Inline wrappers (the C macros / static inlines)
// ---------------------------------------------------------------------------
inline fn moreInfoOnError(where: [*:0]const u8, hint: [*:0]const u8) void {
    if (comptime extra_info) c_moreInfoOnError(where, hint, null, null);
}

inline fn real34SetOne(destination: *real34_t) void {
    _ = decQuadFromInt32(destination, 1);
}
inline fn real34SetZero(destination: *real34_t) void {
    _ = decQuadZero(destination);
}
inline fn stringToReal34(source: [*c]const u8, destination: *real34_t) void {
    _ = decQuadFromString(destination, source, &ctxtReal34);
}
inline fn setRegisterAngularMode(reg: calcRegister_t, am: angularMode_t) void {
    setRegisterTag(reg, @bitCast(am));
}
inline fn stringByteLength(str: [*c]const u8) i32 {
    return @intCast(strlen(str));
}
inline fn reg34(reg: calcRegister_t) *align(1) real34_t {
    return @ptrCast(getRegisterDataPointer(reg));
}
inline fn regImag34(reg: calcRegister_t) *align(1) real34_t {
    const bytes: [*]align(1) u8 = @ptrCast(getRegisterDataPointer(reg));
    return @ptrCast(bytes + REAL34_SIZE_IN_BYTES);
}
inline fn regStringData(reg: calcRegister_t) [*]u8 {
    const bytes: [*]u8 = @ptrCast(getRegisterDataPointer(reg));
    return bytes + 4; // sizeof(strLgIntHeader_t)
}

inline fn toBlocks(n: u32) u16 {
    return @intCast((n + 3) >> 2);
}
inline fn toBytes(n: u16) u32 {
    return @as(u32, n) << 2;
}

// TO_PCMEMPTR / TO_C47MEMPTR (ram is uint32_t*; offset in u32 words).
inline fn toPcMemPtr(p: u16) ?*anyopaque {
    if (p == C47_NULL) return null;
    return @ptrCast(&ram[p]);
}
inline fn toC47MemPtr(p: ?*const anyopaque) u16 {
    const ptr = p orelse return C47_NULL;
    return @intCast((@intFromPtr(ptr) - @intFromPtr(ram)) / @sizeOf(u32));
}

// current* accessors (defines.h macros over currentSubroutineLevelData).
inline fn cur() *subroutineLevelHeader_t {
    return currentSubroutineLevelData.?;
}

inline fn localFlagsAfterHeader(level: *subroutineLevelHeader_t) *localFlags_t {
    const bytes: [*]align(1) u8 = @ptrCast(level);
    const aligned: [*]align(@alignOf(localFlags_t)) u8 = @alignCast(bytes + @sizeOf(subroutineLevelHeader_t));
    return @ptrCast(aligned);
}
inline fn localRegistersAfterFlags(flags: *localFlags_t) [*]register_header_t {
    const bytes: [*]align(1) u8 = @ptrCast(flags);
    const aligned: [*]align(@alignOf(register_header_t)) u8 = @alignCast(bytes + @sizeOf(localFlags_t));
    return @ptrCast(aligned);
}

// allocC47Blocks / freeC47Blocks / reduceC47Blocks / allocateLocalRegisters.
extern fn allocC47Blocks(size_in_blocks: usize) ?*anyopaque;
extern fn freeC47Blocks(pc_mem_ptr: ?*anyopaque, size_in_blocks: usize) void;
extern fn reduceC47Blocks(pc_mem_ptr: ?*anyopaque, old_size_in_blocks: usize, new_size_in_blocks: usize) void;
extern fn allocateLocalRegisters(number_of_registers_to_allocate: u16) void;

// regKStoC (static inline in defines.h).
inline fn regKStoC(regKS: u8) i16 {
    const k: i16 = @intCast(regKS);
    const stat: i16 = if (FIRST_STAT_REGISTER_IN_KS_CODE <= k and regKS <= LAST_SPARE_REGISTERS_IN_KS_CODE) NUMBER_OF_LOCAL_REGISTERS else 0;
    const local: i16 = if (FIRST_LOCAL_REGISTER_IN_KS_CODE <= k and k <= LAST_LOCAL_REGISTER_IN_KS_CODE) (FIRST_LOCAL_REGISTER - FIRST_LOCAL_REGISTER_IN_KS_CODE) else 0;
    return k - stat + local;
}

inline fn isAtEndOfProgram(step: [*c]const u8) bool_t {
    return checkOpCodeOfStep(step, ITM_END);
}

inline fn absI32(x: i32) i32 {
    return if (x < 0) -x else x;
}

// ===========================================================================
// fnGoto
// ===========================================================================
pub export fn fnGoto(label: u16) callconv(.c) void {
    if (tam.mode != 0 or calcMode != CM_PEM) {
        if (dynamicMenuItem >= 0) {
            goToGlobalStep(label);
            return;
        }

        // Local Label 00 to 99 and A to l
        if (label <= LAST_LOCAL_LABEL) {
            // Search for local label
            var lbl: u16 = 0;
            while (lbl < numberOfLabels) : (lbl += 1) {
                if (labelList[lbl].program == @as(i16, @bitCast(currentProgramNumber)) and labelList[lbl].step < 0 and labelList[lbl].labelPointer[0] == label) {
                    if (programRunStop == PGM_RUNNING) {
                        currentLocalStepNumber = @intCast((-labelList[lbl].step) - programList[currentProgramNumber - 1].step + 1);
                        currentStep = labelList[lbl].labelPointer - 1;
                    } else {
                        goToGlobalStep(@intCast(-labelList[lbl].step));
                    }
                    return;
                }
            }

            displayCalcErrorMessage(ERROR_LABEL_NOT_FOUND, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnError("In function fnGoto:", "there is no local label in current program");
        } else if (label >= FIRST_LABEL and label <= LAST_LABEL) { // Global named label
            if ((label - FIRST_LABEL) < numberOfLabels) {
                goToGlobalStep(@intCast(labelList[label - FIRST_LABEL].step));
                return;
            } else {
                displayCalcErrorMessage(ERROR_LABEL_NOT_FOUND, ERR_REGISTER_LINE, REGISTER_X);
                moreInfoOnError("In function fnGoto:", "label ID out of range");
            }
        } else {
            displayCalcErrorMessage(ERROR_LABEL_NOT_FOUND, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnError("In function fnGoto:", "invalid parameter");
        }
    } else {
        insertStepInProgram(@intCast(ITM_GTO));
    }
}

// ===========================================================================
// goToGlobalStep
// ===========================================================================
pub export fn goToGlobalStep(step_arg: i32) callconv(.c) void {
    var step = step_arg;

    if (dynamicMenuItem >= 0) {
        var dupNum: i16 = 0;
        const labelName: [*c]u8 = dynmenuGetLabelWithDup(dynamicMenuItem, &dupNum);

        if (labelName[0] == 0) {
            return;
        }
        if ((softmenu[@intCast(softmenuStack[0].softmenuId)].menuItem != -MNU_PROG) and (softmenu[@intCast(softmenuStack[0].softmenuId)].menuItem != -MNU_PROGS)) { // Don't apply the dupNum logic in configurable menus
            dupNum = 0;
        }

        const len: i16 = @intCast(stringByteLength(labelName));
        var lbl: u16 = 0;
        while (lbl < numberOfLabels) : (lbl += 1) {
            const lblPtr: [*c]u8 = labelList[lbl].labelPointer;
            if (labelList[lbl].step > 0 and lblPtr[0] == @as(u8, @intCast(len))) { // It's a global label and the length is OK
                var c: i16 = 0;
                while (c < len) : (c += 1) {
                    if (labelName[@intCast(c)] != lblPtr[@intCast(c + 1)]) {
                        break;
                    }
                }
                if (c == len) {
                    if (dupNum <= 0) {
                        step = labelList[lbl].step;
                        break;
                    } else {
                        dupNum -= 1;
                    }
                }
            }
        }
    }

    defineCurrentProgramFromGlobalStepNumber(@intCast(step));
    currentLocalStepNumber = @intCast(absI32(step) - absI32(programList[currentProgramNumber - 1].step) + 1);

    var stepPointer: [*c]u8 = beginOfCurrentProgram;
    step = 1;
    while (true) {
        if (step == currentLocalStepNumber) {
            currentStep = stepPointer;
            break;
        }

        stepPointer = findNextStep(stepPointer);
        step += 1;
    }

    if (currentLocalStepNumber >= 3) {
        firstDisplayedLocalStepNumber = currentLocalStepNumber - 3;
        const numberOfSteps: u16 = getNumberOfSteps();
        if (firstDisplayedLocalStepNumber + 6 > numberOfSteps) {
            var i: i32 = 3 + @as(i32, currentLocalStepNumber) - @as(i32, numberOfSteps);
            while (i > 0) : (i -= 1) {
                if (firstDisplayedLocalStepNumber > 0) {
                    firstDisplayedLocalStepNumber -= 1;
                }
            }
        }
        defineFirstDisplayedStep();
    } else {
        firstDisplayedLocalStepNumber = 0;
        firstDisplayedStep = beginOfCurrentProgram;
    }
}

// ===========================================================================
// goToPgmStep
// ===========================================================================
pub export fn goToPgmStep(program: u16, step: u16) callconv(.c) void {
    const globalStepNumber: i32 = programList[program - 1].step;
    goToGlobalStep(globalStepNumber + step - 1);
}

// ===========================================================================
// fnGotoDot
// ===========================================================================
pub export fn fnGotoDot(globalStepNumber: u16) callconv(.c) void {
    goToGlobalStep(@as(i16, @bitCast(globalStepNumber)));
}

// ===========================================================================
// fnExecute
// ===========================================================================
pub export fn fnExecute(label: u16) callconv(.c) void {
    if (programRunStop == PGM_RUNNING) {
        const oldCurrentSubroutineLevelData = currentSubroutineLevelData;
        allSubroutineLevels.numberOfSubroutineLevels += 1;
        currentSubroutineLevelData = @ptrCast(@alignCast(allocC47Blocks(3)));
        if (currentSubroutineLevelData != null) {
            oldCurrentSubroutineLevelData.?.ptrToNextLevel = toC47MemPtr(currentSubroutineLevelData);
            cur().returnProgramNumber = @bitCast(currentProgramNumber);
            cur().returnLocalStep = currentLocalStepNumber;
            cur().numberOfLocalRegisters = 0; // No local register
            cur().numberOfLocalFlags = 0; // No local flags
            cur().subroutineLevel = allSubroutineLevels.numberOfSubroutineLevels - 1;
            cur().ptrToNextLevel = C47_NULL;
            cur().ptrToPreviousLevel = toC47MemPtr(oldCurrentSubroutineLevelData);
            currentLocalFlags = null;
            currentLocalRegisters = null;

            fnGoto(label);
            dynamicMenuItem = -1;
            if (lastErrorCode != ERROR_NONE) {
                fnReturn(0);
                fnBack(1);
            }
        } else {
            // OUT OF MEMORY
            currentSubroutineLevelData = oldCurrentSubroutineLevelData;
            displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
        }
    } else {
        fnGoto(label);
        dynamicMenuItem = -1;
        if (lastErrorCode == ERROR_NONE) {
            if (tam.mode != 0) {
                leaveTamModeIfEnabled();
                refreshScreen(2);
            }
            runProgram(0, INVALID_VARIABLE);
        }
    }
}

pub export fn fnExecutePlusSkip(label: u16) callconv(.c) void {
    fnExecute(label);
    if ((programRunStop == PGM_RUNNING) and (lastErrorCode == ERROR_NONE)) {
        cur().returnLocalStep += 1;
    }
}

// ===========================================================================
// fnReturn
// ===========================================================================
pub export fn fnReturn(skip: u16) callconv(.c) void {
    var oldCurrentSubroutineLevelData = currentSubroutineLevelData;
    var sizeToBeFreedInBlocks: u16 = undefined;

    // Cancel INPUT
    if (currentInputVariable != INVALID_VARIABLE) {
        currentInputVariable = INVALID_VARIABLE;
        screenUpdatingMode = SCRUPD_AUTO; // &= ~SCRUPD_MANUAL_STATUSBAR;
        refreshScreen(3);
        if (comptime dmcp_build) {
            lcdRefresh();
        } else {
            refreshLcd(null);
        }
    }

    // A subroutine is running
    if (cur().subroutineLevel > 0) {
        if (programRunStop == PGM_RUNNING) {
            currentProgramNumber = @bitCast(cur().returnProgramNumber);
            currentLocalStepNumber = cur().returnLocalStep + 1;
            defineCurrentStep();
        } else {
            const returnGlobalStepNumber: u16 = @intCast(@as(i32, cur().returnLocalStep) + programList[@as(u16, @bitCast(cur().returnProgramNumber)) - 1].step); // the next step
            goToGlobalStep(returnGlobalStepNumber);
        }

        if (skip > 0 and isAtEndOfProgram(currentStep) == 0 and isAtEndOfPrograms(currentStep) == 0) {
            currentLocalStepNumber += 1;
            currentStep = findNextStep(currentStep);
        }
        if (cur().numberOfLocalRegisters > 0) {
            allocateLocalRegisters(0);
            oldCurrentSubroutineLevelData = currentSubroutineLevelData;
        }
        sizeToBeFreedInBlocks = toBlocks(@as(u32, @sizeOf(subroutineLevelHeader_t)) + @as(u32, @sizeOf(localFlags_t)) * @intFromBool(cur().numberOfLocalFlags > 0));
        currentSubroutineLevelData = @ptrCast(@alignCast(toPcMemPtr(cur().ptrToPreviousLevel)));
        freeC47Blocks(oldCurrentSubroutineLevelData, sizeToBeFreedInBlocks);
        cur().ptrToNextLevel = C47_NULL;
        allSubroutineLevels.numberOfSubroutineLevels -= 1;

        currentLocalFlags = if (cur().numberOfLocalFlags == 0) null else localFlagsAfterHeader(cur());
        currentLocalRegisters = if (cur().numberOfLocalRegisters == 0 or cur().numberOfLocalFlags == 0) null else localRegistersAfterFlags(currentLocalFlags.?);
    }

    // Not in a subroutine
    else {
        goToPgmStep(currentProgramNumber, 1);
        if (cur().numberOfLocalRegisters > 0) {
            allocateLocalRegisters(0);
        }
        if (cur().numberOfLocalFlags > 0) {
            reduceC47Blocks(
                cur(),
                toBlocks(@as(u32, @sizeOf(subroutineLevelHeader_t)) + @as(u32, @sizeOf(localFlags_t))),
                toBlocks(@as(u32, @sizeOf(subroutineLevelHeader_t))),
            );
            cur().numberOfLocalFlags = 0;
        }
        currentLocalFlags = null;
        currentLocalRegisters = null;
        pemCursorIsZerothStep = 1;
    }
}

// ===========================================================================
// fnRunProgram / fnStopProgram
// ===========================================================================
pub export fn fnRunProgram(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (currentInputVariable != INVALID_VARIABLE) {
        if (currentInputVariable & 0x8000 != 0) {
            fnDropY(NOPARAM);
        }
        fnStore(currentInputVariable & 0x3fff);
        currentInputVariable = INVALID_VARIABLE;
    }
    dynamicMenuItem = -1;
    runProgram(0, INVALID_VARIABLE);
}

pub export fn fnStopProgram(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    programRunStop = PGM_WAITING;
    screenUpdatingMode &= ~SCRUPD_MANUAL_STATUSBAR;
    //  refreshStatusBar();
}

// ===========================================================================
// Static helpers
// ===========================================================================
// Upstream shares the bounded decoder in decode.c (getStringLabelOrVariableName);
// this local copy carries the same clamp so a corrupt step's length byte cannot
// read past the program region.
fn _getStringLabelOrVariableName(stringAddress: [*c]u8) void {
    var stringLength: u8 = stringAddress[0];
    const nameStart: [*c]u8 = stringAddress + 1;
    if (@intFromPtr(nameStart) >= @intFromPtr(firstFreeProgramByte)) {
        stringLength = 0;
    } else if (stringLength > @intFromPtr(firstFreeProgramByte) - @intFromPtr(nameStart)) {
        stringLength = @intCast(@intFromPtr(firstFreeProgramByte) - @intFromPtr(nameStart));
    }
    _ = xcopy(@ptrCast(tmpStringLabelOrVariableName), @ptrCast(nameStart), stringLength);
    tmpStringLabelOrVariableName[stringLength] = 0;
}

fn _executeWithIndirectRegister(paramAddress: [*c]u8, op: u16) void {
    const opParam: u8 = paramAddress[0];
    const tryAllocate: bool_t = isFunctionAllowingNewVariable(op);
    if (opParam <= LAST_SPARE_REGISTERS_IN_KS_CODE) { // Local register from .00 to .98
        const realParam: i16 = indirectAddressing(regKStoC(opParam), indirectionType(op), @intCast(indexOfItems[op].tamMinMax >> TAM_MAX_BITS), @intCast(indexOfItems[op].tamMinMax & TAM_MAX_MASK), tryAllocate);
        if (realParam != FAILED_INDIRECTION) {
            reallyRunFunction(@bitCast(op), @bitCast(realParam));
        }
    } else {
        // sprintf(tmpString, ...): bug-path, dropped.
    }
}

fn _executeWithIndirectVariable(stringAddress: [*c]u8, op: u16) void {
    const tryAllocate: bool_t = isFunctionAllowingNewVariable(op);
    _getStringLabelOrVariableName(stringAddress);
    const regist: calcRegister_t = findNamedVariable(tmpStringLabelOrVariableName);
    if (regist != INVALID_VARIABLE) {
        const realParam: i16 = indirectAddressing(regist, indirectionType(op), @intCast(indexOfItems[op].tamMinMax >> TAM_MAX_BITS), @intCast(indexOfItems[op].tamMinMax & TAM_MAX_MASK), tryAllocate);
        if (realParam != FAILED_INDIRECTION) {
            reallyRunFunction(@bitCast(op), @bitCast(realParam));
        }
    } else {
        displayCalcErrorMessage(ERROR_UNDEF_SOURCE_VAR, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function _executeWithIndirectVariable:", "string is not a named variable");
    }
}

fn _executeOp(paramAddress_arg: [*c]u8, op: u16, paramMode: u16) void {
    var paramAddress = paramAddress_arg;
    const opParam: u8 = paramAddress[0];
    paramAddress += 1;
    const tryAllocate: bool_t = isFunctionAllowingNewVariable(op);

    switch (paramMode) {
        PARAM_DECLARE_LABEL => {
            // nothing to do
        },

        PARAM_LABEL => {
            if (opParam <= LAST_LOCAL_LABEL) { // Local label from 00 to 99 or from A to l
                reallyRunFunction(@bitCast(op), opParam);
            } else if (opParam == STRING_LABEL_VARIABLE) {
                _getStringLabelOrVariableName(paramAddress);
                const label: calcRegister_t = findNamedLabel(tmpStringLabelOrVariableName);
                if (label != INVALID_VARIABLE or op == ITM_LBLQ) {
                    reallyRunFunction(@bitCast(op), @bitCast(label));
                } else {
                    displayCalcErrorMessage(ERROR_LABEL_NOT_FOUND, ERR_REGISTER_LINE, REGISTER_X);
                    moreInfoOnError("In function _executeOp:", "string is not a named label");
                }
            } else if (opParam == INDIRECT_REGISTER) {
                _executeWithIndirectRegister(paramAddress, op);
            } else if (opParam == INDIRECT_VARIABLE) {
                _executeWithIndirectVariable(paramAddress, op);
            } else {
                // sprintf(tmpString, ...): bug-path, dropped.
            }
        },

        PARAM_FLAG => {
            if (opParam <= LAST_LOCAL_FLAG) { // Global flag 00..99, Lettered X..K, or Local .00..31
                reallyRunFunction(@bitCast(op), opParam);
            } else if (FLAG_M <= opParam and opParam < FLAG_W) { // Lettered flag from M to W
                reallyRunFunction(@bitCast(op), opParam);
            } else if (opParam == SYSTEM_FLAG_NUMBER) {
                if (paramAddress[0] < 64) { // first 64 system flags
                    reallyRunFunction(@bitCast(op), indexOfItems[@as(usize, paramAddress[0]) + SFL_TDM24].param);
                } else { // other system flags
                    reallyRunFunction(@bitCast(op), indexOfItems[@as(usize, paramAddress[0] & 0x3f) + SFL_MONIT].param);
                }
            } else if (opParam == INDIRECT_REGISTER) {
                _executeWithIndirectRegister(paramAddress, op);
            } else if (opParam == INDIRECT_VARIABLE) {
                _executeWithIndirectVariable(paramAddress, op);
            } else {
                // bug-path, dropped.
            }
        },

        PARAM_NUMBER_8 => {
            if (opParam <= (indexOfItems[op].tamMinMax & TAM_MAX_MASK)) { // Value from 0 to 99
                reallyRunFunction(@bitCast(op), opParam);
            } else if (opParam == INDIRECT_REGISTER) {
                _executeWithIndirectRegister(paramAddress, op);
            } else if (opParam == INDIRECT_VARIABLE) {
                _executeWithIndirectVariable(paramAddress, op);
            } else {
                // bug-path, dropped.
            }
        },

        PARAM_NUMBER_8_16 => {
            if (opParam <= 249) { // Value from 0 to 249
                reallyRunFunction(@bitCast(op), opParam);
            } else if (opParam == CNST_BEYOND_250) { // Value from 250 to 499
                reallyRunFunction(@bitCast(op), 250 + @as(u16, paramAddress[0]));
            } else if (opParam == INDIRECT_REGISTER) {
                _executeWithIndirectRegister(paramAddress, op);
            } else if (opParam == INDIRECT_VARIABLE) {
                _executeWithIndirectVariable(paramAddress, op);
            } else {
                // bug-path, dropped.
            }
        },

        PARAM_NUMBER_16 => {
            if (isFunctionOldParam16(op) != 0) { // original Param16 without indirection (little endian parameter)
                reallyRunFunction(@bitCast(op), @as(u16, opParam) +% 256 *% @as(u16, paramAddress[0]));
            } else { // new Param16 with indirection (big endian parameter)
                if (opParam == INDIRECT_REGISTER) {
                    _executeWithIndirectRegister(paramAddress, op);
                } else if (opParam == INDIRECT_VARIABLE) {
                    _executeWithIndirectVariable(paramAddress, op);
                } else {
                    reallyRunFunction(@bitCast(op), (@as(u16, opParam) *% 256) +% @as(u16, paramAddress[0]));
                }
            }
        },

        PARAM_REGISTER, PARAM_COMPARE => {
            if (opParam <= LAST_SPARE_REGISTERS_IN_KS_CODE) { // Global 00..99, Lettered X..K, or Local .00..98
                if (regInRange(@bitCast(regKStoC(opParam))) != 0) {
                    reallyRunFunction(@bitCast(op), @bitCast(regKStoC(opParam)));
                }
            } else if (opParam == STRING_LABEL_VARIABLE) {
                _getStringLabelOrVariableName(paramAddress);
                const regist: calcRegister_t = findNamedVariable(tmpStringLabelOrVariableName);
                if (tryAllocate != 0) {
                    reallyRunFunction(@bitCast(op), @bitCast(findOrAllocateNamedVariable(tmpStringLabelOrVariableName)));
                } else if (regist != INVALID_VARIABLE) {
                    reallyRunFunction(@bitCast(op), @bitCast(regist));
                } else {
                    displayCalcErrorMessage(ERROR_UNDEF_SOURCE_VAR, ERR_REGISTER_LINE, REGISTER_X);
                    moreInfoOnError("In function _executeOp:", "string is not a named variable");
                }
            } else if (paramMode == PARAM_COMPARE and opParam == VALUE_0) {
                reallocateRegister(TEMP_REGISTER_1, dtReal34, 0, @bitCast(amNone));
                real34SetZero(reg34(TEMP_REGISTER_1));
                reallyRunFunction(@bitCast(op), TEMP_REGISTER_1);
            } else if (paramMode == PARAM_COMPARE and opParam == VALUE_1) {
                reallocateRegister(TEMP_REGISTER_1, dtReal34, 0, @bitCast(amNone));
                real34SetOne(reg34(TEMP_REGISTER_1));
                reallyRunFunction(@bitCast(op), TEMP_REGISTER_1);
            } else if (opParam == INDIRECT_REGISTER) {
                _executeWithIndirectRegister(paramAddress, op);
            } else if (opParam == INDIRECT_VARIABLE) {
                _executeWithIndirectVariable(paramAddress, op);
            } else {
                // bug-path, dropped.
            }
        },

        PARAM_MENU => {
            if (opParam == STRING_LABEL_VARIABLE) {
                _getStringLabelOrVariableName(paramAddress);
                const menu_id: i16 = findMenu(tmpStringLabelOrVariableName);
                if (tryAllocate != 0) {
                    reallyRunFunction(@bitCast(op), @bitCast(findOrAllocateNamedVariable(tmpStringLabelOrVariableName)));
                } else if (menu_id != INVALID_MENU) {
                    reallyRunFunction(@bitCast(op), @bitCast(menu_id));
                } else {
                    displayCalcErrorMessage(ERROR_UNDEF_MENU, ERR_REGISTER_LINE, REGISTER_X);
                    moreInfoOnError("In function _executeOp:", "string is not a menu name");
                }
            } else if (opParam == INDIRECT_REGISTER) {
                _executeWithIndirectRegister(paramAddress, op);
            } else if (opParam == INDIRECT_VARIABLE) {
                _executeWithIndirectVariable(paramAddress, op);
            } else {
                // bug-path, dropped.
            }
        },

        PARAM_SKIP_BACK, PARAM_SHUFFLE => {
            reallyRunFunction(@bitCast(op), opParam);
        },

        else => {
            // sprintf(tmpString, "paramMode %u is not valid"): bug-path, dropped.
        },
    }
}

fn _putLiteral(literalAddress_arg: [*c]u8) void {
    var literalAddress = literalAddress_arg;
    const kind: u8 = literalAddress[0];
    literalAddress += 1;
    switch (kind) {
        BINARY_SHORT_INTEGER => {
            liftStack();
            setSystemFlag(FLAG_ASLIFT);
            reallocateRegister(REGISTER_X, dtShortInteger, 0, literalAddress[0]);
            literalAddress += 1;
            _ = xcopy(getRegisterDataPointer(REGISTER_X), @ptrCast(literalAddress), toBytes(SHORT_INTEGER_SIZE_IN_BLOCKS));
        },

        BINARY_REAL34 => {
            var realLiteral: real34_t = undefined;
            _ = xcopy(@ptrCast(&realLiteral), @ptrCast(literalAddress), REAL34_SIZE_IN_BYTES);
            liftStack();
            setSystemFlag(FLAG_ASLIFT);
            reallocateRegister(REGISTER_X, dtReal34, 0, @bitCast(amNone));
            real34Copy(&realLiteral, reg34(REGISTER_X));
        },

        BINARY_COMPLEX34 => {
            var complexLiteral: complex34_t = undefined;
            liftStack();
            setSystemFlag(FLAG_ASLIFT);
            reallocateRegister(REGISTER_X, dtComplex34, 0, @bitCast(amNone));
            _ = xcopy(@ptrCast(&complexLiteral.real), @ptrCast(literalAddress), REAL34_SIZE_IN_BYTES);
            _ = xcopy(@ptrCast(&complexLiteral.imag), @ptrCast(literalAddress + REAL34_SIZE_IN_BYTES), REAL34_SIZE_IN_BYTES);
            complex34Copy(&complexLiteral, regComplex34(REGISTER_X));
        },

        STRING_SHORT_INTEGER => {
            const base: u8 = literalAddress[0];
            var val: mpz_struct = undefined;
            mpz_init(&val);

            _getStringLabelOrVariableName(literalAddress + 1);
            _ = stringToLongInteger(tmpStringLabelOrVariableName, base, &val);
            liftStack();
            setSystemFlag(FLAG_ASLIFT);
            convertLongIntegerToShortIntegerRegister(&val, literalAddress[0], REGISTER_X);

            mpz_clear(&val);
        },

        STRING_LONG_INTEGER => {
            var val: mpz_struct = undefined;
            mpz_init(&val);

            _getStringLabelOrVariableName(literalAddress);
            _ = stringToLongInteger(tmpStringLabelOrVariableName, 10, &val);
            liftStack();
            setSystemFlag(FLAG_ASLIFT);
            convertLongIntegerToLongIntegerRegister(&val, REGISTER_X);

            mpz_clear(&val);
        },

        STRING_REAL34 => {
            _getStringLabelOrVariableName(literalAddress);
            liftStack();
            setSystemFlag(FLAG_ASLIFT);
            reallocateRegister(REGISTER_X, dtReal34, 0, @bitCast(amNone));
            stringToReal34(tmpStringLabelOrVariableName, reg34(REGISTER_X));
        },

        STRING_ANGLE_RADIAN, STRING_ANGLE_GRAD, STRING_ANGLE_DEGREE, STRING_ANGLE_MULTPI => {
            _getStringLabelOrVariableName(literalAddress);
            liftStack();
            setSystemFlag(FLAG_ASLIFT);
            reallocateRegister(REGISTER_X, dtReal34, 0, @bitCast(amNone));
            stringToReal34(tmpStringLabelOrVariableName, reg34(REGISTER_X));
            const tmpAngle: angularMode_t = switch ((literalAddress - 1)[0]) {
                STRING_ANGLE_RADIAN => amRadian,
                STRING_ANGLE_GRAD => amGrad,
                STRING_ANGLE_DEGREE => amDegree,
                STRING_ANGLE_MULTPI => amMultPi,
                else => amNone,
            };
            setRegisterAngularMode(REGISTER_X, tmpAngle);
        },

        STRING_COMPLEX34 => {
            var imag: [*c]u8 = tmpStringLabelOrVariableName;
            _getStringLabelOrVariableName(literalAddress);
            while (imag[0] != 'i' and imag[0] != 0) {
                imag += 1;
            }
            if (imag[0] == 'i') {
                if (@intFromPtr(imag) > @intFromPtr(tmpStringLabelOrVariableName) and (imag - 1)[0] == '-') {
                    imag[0] = '-';
                    (imag - 1)[0] = 0;
                } else if (@intFromPtr(imag) > @intFromPtr(tmpStringLabelOrVariableName) and (imag - 1)[0] == '+') {
                    imag[0] = 0;
                    (imag - 1)[0] = 0;
                    imag += 1;
                } else {
                    imag[0] = 0;
                }
            }
            liftStack();
            setSystemFlag(FLAG_ASLIFT);
            reallocateRegister(REGISTER_X, dtComplex34, 0, @bitCast(amNone));
            stringToReal34(tmpStringLabelOrVariableName, reg34(REGISTER_X));
            stringToReal34(imag, regImag34(REGISTER_X));
        },

        STRING_LABEL_VARIABLE => {
            _getStringLabelOrVariableName(literalAddress);
            liftStack();
            setSystemFlag(FLAG_ASLIFT);
            reallocateRegister(REGISTER_X, dtString, toBlocks(@as(u32, @intCast(stringByteLength(tmpStringLabelOrVariableName) + 1))), @bitCast(amNone));
            _ = xcopy(@ptrCast(regStringData(REGISTER_X)), @ptrCast(tmpStringLabelOrVariableName), @intCast(stringByteLength(tmpStringLabelOrVariableName) + 1));
        },

        STRING_DATE => {
            _getStringLabelOrVariableName(literalAddress);
            liftStack();
            setSystemFlag(FLAG_ASLIFT);
            reallocateRegister(REGISTER_X, dtDate, 0, @bitCast(amNone));
            stringToReal34(tmpStringLabelOrVariableName, reg34(REGISTER_X));
            julianDayToInternalDate(@ptrCast(reg34(REGISTER_X)), @ptrCast(reg34(REGISTER_X)));
        },

        STRING_TIME => {
            _getStringLabelOrVariableName(literalAddress);
            liftStack();
            setSystemFlag(FLAG_ASLIFT);
            reallocateRegister(REGISTER_X, dtReal34, 0, @bitCast(amNone));
            stringToReal34(tmpStringLabelOrVariableName, reg34(REGISTER_X));
            hmmssInRegisterToSeconds(REGISTER_X);
        },

        STRING_ANGLE_DMS => {
            _getStringLabelOrVariableName(literalAddress);
            liftStack();
            setSystemFlag(FLAG_ASLIFT);
            reallocateRegister(REGISTER_X, dtReal34, 0, @bitCast(amDMS));
            stringToReal34(tmpStringLabelOrVariableName, reg34(REGISTER_X));
            real34FromDmsToDeg(@ptrCast(reg34(REGISTER_X)), @ptrCast(reg34(REGISTER_X)));
        },

        else => {
            // !DMCP_BUILD printf bug message: omitted (host-only diagnostic, no
            // control-flow effect).
        },
    }
}

inline fn real34Copy(src: *const real34_t, dst: *align(1) real34_t) void {
    dst.* = src.*;
}
inline fn complex34Copy(src: *const complex34_t, dst: *align(1) complex34_t) void {
    dst.* = src.*;
}
inline fn regComplex34(reg: calcRegister_t) *align(1) complex34_t {
    return @ptrCast(getRegisterDataPointer(reg));
}
inline fn stringToLongInteger(source: [*c]const u8, radix: i32, destination: *mpz_struct) i32 {
    return mpz_set_str(destination, source, radix);
}

// ===========================================================================
// executeOneStep
// ===========================================================================
pub export fn executeOneStep(step_arg: [*c]u8) callconv(.c) i16 {
    var step = step_arg;
    var op: u16 = undefined;

    op = step[0];
    step += 1;
    if (op & 0x80 != 0) {
        op &= 0x7f;
        op <<= 8;
        op |= step[0];
        step += 1;
    }

    // IR_PRINTING and PC_BUILD+DEBUG_EXECUTE blocks omitted (never defined).

    switch (op) {
        ITM_GTO, ITM_XEQ, ITM_BACK, ITM_CASE, ITM_SKIP => {
            const previousErrorCodeMeM: u8 = previousErrorCode;
            _executeOp(step, op, (indexOfItems[op].status & PTP_STATUS) >> 9);
            previousErrorCode = previousErrorCodeMeM;
            return -1;
        },

        ITM_RTN, ITM_END, ITM_RTNP1 => {
            runFunction(@bitCast(op));
            return 0;
        },

        0x7fff => { // .END.
            screenUpdatingMode = SCRUPD_AUTO;
            fnReturn(0);
            return 0;
        },

        ITM_SOLVE => {
            currentSolverStatus &= ~SOLVER_STATUS_USES_FORMULA;
            _executeOp(step, op, PARAM_REGISTER);
            if (temporaryInformation == TI_SOLVER_FAILED) {
                lastErrorCode = ERROR_NONE;
                return 2;
            } else {
                return 1;
            }
        },

        else => {
            switch (indexOfItems[op].status & PTP_STATUS) {
                PTP_NONE => {
                    runFunction(@bitCast(op));
                },

                PTP_DECLARE_LABEL => {
                    return 1;
                },

                PTP_DISABLED => {
                    displayCalcErrorMessage(ERROR_NON_PROGRAMMABLE_COMMAND, ERR_REGISTER_LINE, REGISTER_X);
                    moreInfoOnError("In function executeOneStep:", "non-programmable function appeared in the program!");
                    return 0;
                },

                PTP_LITERAL => {
                    _putLiteral(step);
                    return 1;
                },

                PTP_REM => {
                    if (op == ITM_42STRING) {
                        const marker = step[0];
                        step += 1;
                        if (marker == STRING_LABEL_VARIABLE) {
                            _getStringLabelOrVariableName(step);
                            fn42Alpha(NOPARAM);
                        }
                    } else if (op == ITM_42APPEND) {
                        const marker = step[0];
                        step += 1;
                        if (marker == STRING_LABEL_VARIABLE) {
                            if (getRegisterDataType(@bitCast(alphaRegister)) != dtString) {
                                displayCalcErrorMessage(ERROR_NO_STRING_IN_ALPHA_REGISTER, ERR_REGISTER_LINE, REGISTER_T);
                                moreInfoOnError("In function executeOneStep:", "cannot use 42append: alpha register is not a string");
                                return 0;
                            }
                            _getStringLabelOrVariableName(step);
                            fn42Append(NOPARAM);
                        }
                    } else {
                        // REM: just ignore it
                    }
                    return 1;
                },

                PTP_KEYG_KEYX => {
                    _executeOp(step, op, PARAM_NUMBER_8);
                },

                else => {
                    _executeOp(step, op, (indexOfItems[op].status & PTP_STATUS) >> 9);
                },
            }
            // IR_PRINTING trace block omitted.
            return if (temporaryInformation == TI_FALSE) 2 else 1;
        },
    }
}

// ===========================================================================
// runProgram
// ===========================================================================
pub export fn runProgram(singleStep: bool_t, menuLabel: u16) callconv(.c) void {
    const nestedEngine: bool_t = @intFromBool(programRunStop == PGM_RUNNING);
    const startingSubLevel: u16 = if (nestedEngine != 0 and menuLabel == INVALID_VARIABLE) cur().subroutineLevel else 0;
    lastErrorCode = ERROR_NONE;
    hourGlassIconEnabled = 1;
    programRunStop = PGM_RUNNING;
    if (!getSystemFlag(FLAG_INTING) and !getSystemFlag(FLAG_SOLVING)) {
        showHideHourGlass();
        screenUpdatingMode = SCRUPD_AUTO;
        screenUpdatingMode |= SCRUPD_SKIP_STATUSBAR_ONE_TIME;
    }

    if (menuLabel != INVALID_VARIABLE) {
        fnBack(1);
        if (menuLabel & 0x8000 != 0) {
            fnExecute(menuLabel & 0x7fff);
        } else {
            fnGoto(menuLabel & 0x7fff);
        }
    }

    while (true) {
        var stepsToBeAdvanced: i16 = undefined;
        const subLevel: u16 = cur().subroutineLevel;
        var opCode: u16 = currentStep[0];
        currentInputVariable = INVALID_VARIABLE; // INPUT is already executed
        if (opCode & 0x80 != 0) {
            opCode = (@as(u16, opCode & 0x7F) << 8) | currentStep[1];
        }
        if (temporaryInformation == TI_TRUE or temporaryInformation == TI_FALSE or temporaryInformation == TI_SOLVER_FAILED or (opCode != ITM_RTN and opCode != ITM_STOP and opCode != ITM_END and opCode != 0x7fff)) {
            temporaryInformation = TI_NO_INFO;
        }
        stepsToBeAdvanced = executeOneStep(currentStep);
        if (lastErrorCode == ERROR_NONE) {
            switch (stepsToBeAdvanced) {
                -1 => { // Already the pointer is set
                },

                0 => { // End of the routine
                    if (subLevel == startingSubLevel) {
                        break;
                    }
                },

                else => { // Find the next step
                    fnSkip(@as(u16, @bitCast(stepsToBeAdvanced)) -% 1);
                },
            }
        } else {
            break;
        }
        if (comptime dmcp_build) {
            if (nestedEngine == 0) {
                const key: c_int = C47PopKeyNoBuffer(DISPLAY_WAIT_FOR_RELEASE) + 1;
                if (key == 36 or key == 33) { // JM R/S or EXIT
                    programRunStop = PGM_WAITING;
                    screenUpdatingMode = SCRUPD_AUTO;
                    if (getSystemFlag(FLAG_INTING) or getSystemFlag(FLAG_SOLVING)) {
                        displayCalcErrorMessage(ERROR_SOLVER_ABORT, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
                    }
                    refreshScreen(1);
                    lcdRefresh();
                    fnTimerStart(TO_KB_ACTV, TO_KB_ACTV, PROGRAM_KB_ACTV);
                    waitForKeyRelease(0);
                    _ = keyPop();
                    break;
                } else if (key > 0) {
                    setLastKeyCode(key);
                }
            }
        }
        if (programRunStop != PGM_RUNNING) {
            break;
        }
        if (singleStep != 0) {
            break;
        }
        screenUpdatingMode = SCRUPD_AUTO;
        screenUpdatingMode |= SCRUPD_SKIP_STATUSBAR_ONE_TIME;
    }

    // stopProgram:
    if (programRunStop == PGM_RUNNING and nestedEngine == 0) {
        programRunStop = PGM_STOPPED;
    }
    if (programRunStop != PGM_RUNNING) {
        entryStatus &= 0xfe;
    }
    if (!getSystemFlag(FLAG_INTING) and !getSystemFlag(FLAG_SOLVING)) {
        showHideHourGlass();
        if (temporaryInformation == TI_VIEW_REGISTER) {
            screenUpdatingMode |= SCRUPD_SKIP_STACK_ONE_TIME;
        }
        if (screenUpdatingMode == SCRUPD_AUTO and singleStep == 0) {
            refreshScreen(4);
        }
    }
    return;
}

// ===========================================================================
// execProgram
// ===========================================================================
pub export fn execProgram(label: u16) callconv(.c) void {
    const origLocalStepNumber: u16 = currentLocalStepNumber;
    const origStep: [*c]u8 = currentStep;
    fnExecute(label);
    if (programRunStop == PGM_RUNNING and (getSystemFlag(FLAG_INTING) or getSystemFlag(FLAG_SOLVING))) {
        runProgram(0, INVALID_VARIABLE);
        currentLocalStepNumber = origLocalStepNumber;
        currentStep = origStep;
    }
}

// ===========================================================================
// fnCheckLabel
// ===========================================================================
pub export fn fnCheckLabel(label_arg: u16) callconv(.c) void {
    var label = label_arg;
    if (dynamicMenuItem >= 0) {
        label = @bitCast(findNamedLabel(dynmenuGetLabel(dynamicMenuItem)));
    }

    // Local Label 00 to 99 and A to l
    if (label <= LAST_LOCAL_LABEL) {
        // Search for local label
        var lbl: u16 = 0;
        while (lbl < numberOfLabels) : (lbl += 1) {
            if (labelList[lbl].program == @as(i16, @bitCast(currentProgramNumber)) and labelList[lbl].step < 0 and labelList[lbl].labelPointer[0] == label) {
                temporaryInformation = TI_TRUE;
                return;
            }
        }
        temporaryInformation = TI_FALSE;
    } else if (label >= FIRST_LABEL and label <= LAST_LABEL) { // Global named label
        if ((label - FIRST_LABEL) < numberOfLabels) {
            temporaryInformation = TI_TRUE;
            return;
        }
        temporaryInformation = TI_FALSE;
    } else {
        temporaryInformation = TI_FALSE;
    }
}

// ===========================================================================
// fnIsTopRoutine
// ===========================================================================
pub export fn fnIsTopRoutine(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    // A subroutine is running
    if (cur().subroutineLevel > 0) {
        temporaryInformation = TI_FALSE;
    }
    // Not in a subroutine
    else {
        temporaryInformation = TI_TRUE;
    }
}
