// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/programming/structured.c: the STRUCT programming set --
// IF/ELSE/ENDIF, DO/WHILE/ENDDO, REPEAT/UNTIL, FOR/NEXT in its four opener forms,
// VALID and CLSTRUC.
//
// The set has two halves, and both are compiled. Without OPTION_STRUCTURED_PGM the
// items still exist, so a program written on one calculator loads on another, and
// every command reports that this hardware cannot run it. The predicates the
// program editor and the file writer call answer "nothing to do" instead of
// disappearing, because those callers are compiled unconditionally.
//
// Four things carry the structures, and only the first survives a power cycle:
//
//   the third byte of a numbered step   the partner number, written by VALID
//   the label list                      one entry per jump target, appended after
//                                       every real label so label indices never move
//   the walk arrays                     what VALID holds open while it reads
//   forLoopTable                        one row per FOR running anywhere; saved
//                                       with the calculator, so a loop survives
//                                       a power cycle, and forLoopStep beside it
//                                       does not, program memory having moved
//
// The arrays are sized 0 when the option is off, so a build that cannot run the
// structures carries none of their static RAM: that is what the DM42 needs, its
// .bss sitting where it does.

const std = @import("std");
const builtin = @import("builtin");
const frontier_build_options = @import("frontier_build_options");
const abi = @import("abi");

const dmcp_build: bool = frontier_build_options.dmcp_build;
const old_hw: bool = frontier_build_options.old_hw;
const extra_info: bool = frontier_build_options.extra_info_on_calc_error;
const option_structured_pgm: bool = frontier_build_options.option_structured_pgm;

const code_section = if (dmcp_build and old_hw)
    ".qspi_data"
else if (builtin.target.os.tag == .macos)
    "__TEXT,__text"
else
    ".text";

// The three program owners this file works with all call back into it, so they are
// reached by their C-ABI symbols rather than by @import: importing them would put
// this file inside the @import cycle they already sit in, and it has no reason to be
// there. program_step_opcode is a std-only leaf, so it is imported.
const program_step_opcode = @import("program_step_opcode.zig");

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const bool_t = u8; // C bool_t is one byte
const calcRegister_t = i16;
const real_t = abi.Real;
const real34_t = abi.Real34;
const realContext_t = abi.RealContext;
const mpz_struct = abi.Mpz;
const labelList_t = abi.LabelList;
const programList_t = abi.ProgramList;
const snap_t = abi.RegisterSnapshot;
const subroutineLevelHeader_t = abi.SubroutineLevelHeader;
const forLoop_t = abi.ForLoop;

// ---------------------------------------------------------------------------
// structured.h sizes
// ---------------------------------------------------------------------------
// The R47, the DM42n and the simulator hold 1008 bytes of static RAM for this;
// the DM42 set is 176 bytes, which is what its RAM has room for. Both are sized
// to 0 when the structures are not compiled in.
const STRUCT_MAX_NUMBER: u16 = if (old_hw) 10 else 255; // the highest partner number, which is what one operand byte holds
const STRUCT_MAX_NESTING: usize = if (!option_structured_pgm) 0 else if (old_hw) 10 else 63; // the deepest nesting VALID can hold open at once
const FOR_MAX_LOOPS_ON: u16 = if (old_hw) 4 else 18; // FOR structures that may run at one time, counted over every subroutine level together
const FOR_MAX_LOOPS: u16 = if (option_structured_pgm) FOR_MAX_LOOPS_ON else 0;
const FOR_LOCALS: u16 = 2; // the end value and the increment, the two values a running FOR holds for itself
// The two bits of forLoop_t.stepDescends. They share the byte the descending flag
// already had, so a row is still 10 bytes and backup.cfg keeps its layout.
const FOR_STEP_DESCENDS: u8 = 0x01; // NEXT subtracts the increment instead of adding it
const FOR_TOP_TESTED: u8 = 0x02; // the FOR compared before the first pass, so a start past the end runs no pass
const FOR_MAX_LOCALS: u16 = 99; // what allocateLocalRegisters() permits a subroutine level

// ---------------------------------------------------------------------------
// Item codes (items.h)
// ---------------------------------------------------------------------------
const ITM_LBL: u16 = 1;
const ITM_RTN: u16 = 4;
const ITM_LocR: u16 = 1514;
const ITM_POPLR: u16 = 1553;
const ITM_REM: u16 = 1554;
const ITM_RTNP1: u16 = 1579;
const ITM_IF: u16 = 2920;
const ITM_ELSE: u16 = 2921;
const ITM_ENDIF: u16 = 2922;
const ITM_DO: u16 = 2924;
const ITM_WHILE: u16 = 2925;
const ITM_ENDDO: u16 = 2926;
const ITM_FOR: u16 = 2927;
const ITM_NEXT: u16 = 2928;
const ITM_FORx: u16 = 2929;
const ITM_NEXTx: u16 = 2930;
const ITM_FORYX: u16 = 2933;
const ITM_FORYXx: u16 = 2934;
const ITM_REPEAT: u16 = 2935;
const ITM_UNTIL: u16 = 2936;
const ITM_FORTOP: u16 = 2938;
const ITM_FORTOPx: u16 = 2939;

// ---------------------------------------------------------------------------
// Constants (defines.h / typeDefinitions.h)
// ---------------------------------------------------------------------------
const NOPARAM: u16 = 9876;

const PGM_STOPPED: u8 = 0;
const PGM_RUNNING: u8 = 1;

const TI_NO_INFO: u8 = 0;
const TI_FALSE: u8 = 12;
const TI_TRUE: u8 = 13;

const ERROR_NONE: u8 = 0;
const ERROR_OVERFLOW_PLUS_INF: u8 = 4;
const ERROR_OVERFLOW_MINUS_INF: u8 = 5;
const ERROR_INVALID_DATA_TYPE_FOR_OP: u8 = 24;
const ERROR_NESTING_TOO_DEEP: u8 = 66;
const ERROR_IF_WHILE_CONDITION_MISSING: u8 = 67;
const ERROR_NOT_AVAILABLE_HERE: u8 = 68;
const ERROR_STRUCTURE_NOT_NUMBERED: u8 = 69;
const ERROR_STRUCTURE_INVALID: u8 = 70;
const ERROR_NEXT_NOT_FOUND: u8 = 71;
const ERROR_NEXT_WITHOUT_FOR: u8 = 72;
const ERROR_INVALID_COUNTER_REGISTER: u8 = 73;
const ERROR_STEP_OF_ZERO: u8 = 74;

const FLAG_SPCRES: c_int = 0x8017;
const FLAG_ASLIFT: c_int = @bitCast(@as(c_uint, 0xc023));

const REGISTER_X: calcRegister_t = 100;
const REGISTER_Y: calcRegister_t = 101;
const REGISTER_Z: calcRegister_t = 102;
const ERR_REGISTER_LINE: calcRegister_t = REGISTER_Z;
const TEMP_REGISTER_1: calcRegister_t = 135;
const FIRST_LOCAL_REGISTER: u16 = 7000;
const LAST_NAMED_VARIABLE: u16 = 1999;

const dtLongInteger: u32 = 0;
const dtReal34: u32 = 1;
const dtComplex34: u32 = 2;
const dtShortInteger: u32 = 8;

const amNone: u32 = 5;

const NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS = 10;

// ---------------------------------------------------------------------------
// Globals
// ---------------------------------------------------------------------------
extern var errorMessage: [*c]u8;
extern var lastErrorCode: u8;
extern var temporaryInformation: u8;
extern var programRunStop: u8;
extern var numberOfLabels: u16;
extern var numberOfStructureLabels: u16;
extern var labelList: [*c]labelList_t;
extern var programList: [*c]programList_t;
extern var currentStep: [*c]u8;
extern var currentLocalStepNumber: u16;
extern var currentProgramNumber: u16;
extern var firstDisplayedLocalStepNumber: u16;
extern var pemCursorIsZerothStep: bool_t;
extern var beginOfCurrentProgram: [*c]u8;
extern var endOfCurrentProgram: [*c]u8;
extern var currentSubroutineLevelData: ?*subroutineLevelHeader_t;
extern var shortIntegerMask: u64;
extern var ctxtReal39: realContext_t;

const Fn0 = ?*const fn () callconv(.c) void;
extern const addition: [NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS]Fn0;
extern const subtraction: [NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS]Fn0;

// ---------------------------------------------------------------------------
// Function externs
// ---------------------------------------------------------------------------
extern fn displayCalcErrorMessage(errorCode: u8, errMessageRegisterLine: calcRegister_t, disUsedCanBeRemoved: calcRegister_t) void;
extern fn getSystemFlag(sf: c_int) bool;
extern fn setSystemFlag(sf: c_int) void;
extern fn fnSkip(numberOfSteps: u16) void;
extern fn fnDrop(unusedButMandatoryParameter: u16) void;
extern fn fnReturn(skip: u16) void;
extern fn liftStack() void;
extern fn isRegInRange(regist: u16) bool;
extern fn getRegisterDataType(reg: calcRegister_t) u32;
extern fn getRegisterTag(reg: calcRegister_t) u32;
extern fn copySourceRegisterToDestRegister(sourceRegister: calcRegister_t, destRegister: calcRegister_t) void;
extern fn allocateLocalRegisters(numberOfRegistersToAllocate: u16) void;
extern fn reallocateRegister(reg: calcRegister_t, dataType: u32, dataSizeWithoutDataLenBlocks: u16, tag: u32) void;
extern fn registerCmp(regist1: calcRegister_t, regist2: calcRegister_t, res: *i8) bool;
extern fn saveRegisterSnapshot(reg: calcRegister_t, s: *snap_t) void;
extern fn restoreRegisterSnapshot(reg: calcRegister_t, s: *snap_t) void;
extern fn getRegisterAsAnyRealQuiet(reg: calcRegister_t, val: *real_t) bool;
extern fn getRegisterAsComplexOrAnyRealQuiet(reg: calcRegister_t, r: *real_t, i: *real_t, cmplx: ?*bool) bool;
extern fn convertUInt64ToShortIntegerRegister(sign: i16, value: u64, base: u32, regist: calcRegister_t) void;
extern fn convertLongIntegerToLongIntegerRegister(lgInt: *const mpz_struct, regist: calcRegister_t) void;
extern fn goToPgmStep(program: u16, step: u16) void;
extern fn findNextStep(step: [*c]u8) [*c]u8;
const programBytesAvailableC = @extern(*const fn ([*c]const u8, u16) callconv(.c) bool_t, .{ .name = "programBytesAvailable" });
extern fn defineCurrentStep() void;
extern fn defineFirstDisplayedStep() void;
extern fn defineCurrentProgramFromCurrentStep() void;
extern fn cleanLocalFlagsAndRegisters() void;
extern fn sprintf(buf: [*c]u8, fmt: [*:0]const u8, ...) c_int;
const c_moreInfoOnError = @extern(*const fn (m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) callconv(.c) void, .{ .name = "moreInfoOnError" });

// decNumber / GMP primitives behind the realType.h and longIntegerType.h macros.
extern fn decNumberCompare(res: *real_t, lhs: *const real_t, rhs: *const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberAdd(res: *real_t, lhs: *const real_t, rhs: *const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberSubtract(res: *real_t, lhs: *const real_t, rhs: *const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberMultiply(res: *real_t, lhs: *const real_t, rhs: *const real_t, ctx: *realContext_t) *real_t;
extern fn decQuadIsInfinite(src: *align(1) const real34_t) u32;
extern fn decQuadFromInt32(res: *align(1) real34_t, value: i32) *align(1) real34_t;
extern fn __gmpz_init(op: *mpz_struct) void;
extern fn __gmpz_clear(op: *mpz_struct) void;
extern fn __gmpz_set_si(rop: *mpz_struct, op: c_long) void;

// ---------------------------------------------------------------------------
// Macro wrappers (realType.h, real34 helpers, registers.h)
// ---------------------------------------------------------------------------
const DECNEG: u8 = 0x80;
const DECSPECIAL: u8 = 0x70;

// const34_0 / const34_1 come out of the constant blob, as every other owner reads
// them: they are offsets into the shared table, not link-time symbols.
const consts = abi.constants;
const const34_0 = consts.const34_0;
const const34_1 = consts.const34_1;

const reg34 = abi.registerReal34Aligned;
const regImag34 = abi.registerImag34Aligned;
const regShortInt = abi.registerShortInteger;

inline fn realIsZero(x: *const real_t) bool {
    return x.lsu[0] == 0 and x.digits == 1 and (x.bits & DECSPECIAL) == 0;
}
inline fn realIsPositive(x: *const real_t) bool {
    return (x.bits & DECNEG) == 0 and !realIsZero(x);
}
inline fn realAdd(a: *const real_t, b: *const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberAdd(res, a, b, ctx);
}
inline fn realSubtract(a: *const real_t, b: *const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberSubtract(res, a, b, ctx);
}
inline fn realMultiply(a: *const real_t, b: *const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberMultiply(res, a, b, ctx);
}
inline fn realCompare(a: *const real_t, b: *const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberCompare(res, a, b, ctx);
}
inline fn real34Copy(src: *align(1) const real34_t, dst: *align(1) real34_t) void {
    dst.* = src.*;
}
inline fn real34IsInfinite(src: *align(1) const real34_t) bool {
    return decQuadIsInfinite(src) != 0;
}
// realType.h reads the sign bit of the encoding directly, so a negative zero is
// not positive and an infinity answers by its sign alone.
inline fn real34IsPositive(src: *align(1) const real34_t) bool {
    return (src.bytes[15] & 0x80) == 0x00;
}
inline fn int32ToReal34(src: i32, dst: *align(1) real34_t) void {
    _ = decQuadFromInt32(dst, src);
}
inline fn longIntegerInit(op: *mpz_struct) void {
    __gmpz_init(op);
}
inline fn longIntegerFree(op: *mpz_struct) void {
    __gmpz_clear(op);
}
inline fn int32ToLongInteger(src: i32, dst: *mpz_struct) void {
    __gmpz_set_si(dst, src);
}
inline fn getRegisterShortIntegerBase(reg: calcRegister_t) u32 {
    return getRegisterTag(reg);
}
inline fn currentNumberOfLocalRegisters() u16 {
    return currentSubroutineLevelData.?.numberOfLocalRegisters;
}
inline fn currentSubroutineLevel() u16 {
    return currentSubroutineLevelData.?.subroutineLevel;
}
inline fn moreInfoOnError(m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) void {
    if (comptime extra_info) c_moreInfoOnError(m1, m2, m3, m4);
}
inline fn programBytesAvailable(address: [*c]const u8, numberOfBytes: u16) bool {
    return programBytesAvailableC(address, numberOfBytes) != 0;
}
inline fn isAtEndOfPrograms(step: [*c]const u8) bool {
    return program_step_opcode.isAtEndOfPrograms(step);
}
inline fn isAtEndOfProgram(step: [*c]const u8) bool {
    return program_step_opcode.checkOpCodeOfStep(step, 1458); // ITM_END
}

// ===========================================================================
// The half compiled in every build
// ===========================================================================

// The op code of a step, 0 when the step cannot be read. Bounds checked: the step
// after a test is not reached yet, so the second byte of a two-byte op code can lie
// past the end of program memory.
fn structOpOfStep(step: [*c]u8) u16 {
    if (step == null or !programBytesAvailable(step, 1)) {
        return 0;
    }
    var stepOp: u16 = step[0];
    if ((stepOp & 0x80) != 0) {
        if (!programBytesAvailable(step, 2)) {
            return 0;
        }
        stepOp = ((stepOp & 0x7f) << 8) | step[1];
    }
    return stepOp;
}

// True for the STRUCT commands that carry a partner number. Their number reads as
// subscript digits joined to the name.
pub export fn structOpHasNumber(op: u16) callconv(.c) bool_t {
    return @intFromBool(op == ITM_IF or op == ITM_ELSE or op == ITM_ENDIF or op == ITM_DO or op == ITM_WHILE or op == ITM_ENDDO or
        op == ITM_REPEAT or op == ITM_UNTIL);
}

// True when the step reads a test answer, that is IF, WHILE or UNTIL. SST on the
// test runs both the test and IF..., so BST steps back two steps.
pub export fn structStepIsIfOrWhile(step: [*c]u8) callconv(.c) bool_t {
    const op = structOpOfStep(step);

    return @intFromBool(op == ITM_IF or op == ITM_WHILE or op == ITM_UNTIL);
}

// True for the STRUCT structure tokens. A test indents the step after it, and these
// take their own column instead.
pub export fn structDisplayOutdent(step: [*c]u8) callconv(.c) bool_t {
    const op = structPlainOp(structOpOfStep(step));

    return @intFromBool(structOpHasNumber(op) != 0 or op == ITM_FOR or op == ITM_NEXT);
}

// True for the step that opens a structure. A listing stands its body two columns in
// from here.
pub export fn structStepOpensIndent(step: [*c]u8) callconv(.c) bool_t {
    const op = structPlainOp(structOpOfStep(step));

    return @intFromBool(op == ITM_IF or op == ITM_DO or op == ITM_FOR or op == ITM_REPEAT);
}

// True for the step that closes a structure. It stands on the column its opener
// stands on, so the count falls before it is written.
pub export fn structStepClosesIndent(step: [*c]u8) callconv(.c) bool_t {
    const op = structPlainOp(structOpOfStep(step));

    return @intFromBool(op == ITM_ENDIF or op == ITM_ENDDO or op == ITM_NEXT or op == ITM_UNTIL);
}

// True for the step that stands on its opener's column without closing it, so the
// body below it stays indented. The exported listing takes this from the name table.
pub export fn structStepOnOpenerColumn(step: [*c]u8) callconv(.c) bool_t {
    const op = structPlainOp(structOpOfStep(step));

    return @intFromBool(op == ITM_ELSE or op == ITM_WHILE);
}

// True for the STRUCT steps a jump lands on: both branch ends of IF, both ends of
// the loop since ENDDO goes back to its DO, and FOR and NEXT in every form. The
// label scan records each one, so a STRUCT jump is the lookup a GTO to a local label
// makes.
pub export fn structStepIsJumpTarget(step: [*c]u8) callconv(.c) bool_t {
    const op = structPlainOp(structOpOfStep(step));

    return @intFromBool(op == ITM_ELSE or op == ITM_ENDIF or op == ITM_DO or op == ITM_ENDDO or op == ITM_FOR or op == ITM_NEXT or
        op == ITM_REPEAT or op == ITM_UNTIL);
}

// The plain form of a step VALID has marked as not checked, and the plain FOR of a
// FORyx. The forms differ only in the op code, so everything that reads a program
// asks this and sees the structure, while the run and the file writer test for the
// marked form and refuse it. FORyx differs from FOR only in where its step comes
// from, and once it is running it is a FOR, so every walk of a program treats the two
// alike and only the item table tells them apart.
pub export fn structPlainOp(op: u16) callconv(.c) u16 {
    if (op == ITM_FORx or op == ITM_FORYX or op == ITM_FORYXx or op == ITM_FORTOP or op == ITM_FORTOPx) {
        return ITM_FOR;
    }
    if (op == ITM_NEXTx) {
        return ITM_NEXT;
    }
    return op;
}

// The op code of the step after 'step' when that step is a complete IF or WHILE, 0
// otherwise. The run loop then runs the test and that step as one action instead of
// taking the legacy skip. Compiled in every build: without the option a false test
// would skip the IF and run the branch it did not select. All three bytes must be
// present, since the caller reads the number as the third one and a program damaged
// there would read past the end.
pub export fn structFusedOp(step: [*c]u8) callconv(.c) u16 {
    const next = findNextStep(step);
    const op = structOpOfStep(next);

    if ((op == ITM_IF or op == ITM_WHILE or op == ITM_UNTIL) and programBytesAvailable(next, 3)) {
        return op;
    }
    return 0;
}

// True when the step after 'step' must run whatever the test answered. The legacy
// rule skips the step after a false test, and skipping a structure token breaks the
// structure silently: a skipped ENDDO ends the loop after one pass, a skipped ELSE
// runs the branch it should have skipped.
pub export fn structNoLegacySkip(step: [*c]u8) callconv(.c) bool_t {
    return @intFromBool(structFusedOp(step) != 0 or structStepIsJumpTarget(findNextStep(step)) != 0);
}

// The items exist in every build so programs stay portable. Without the option the
// commands only report that they cannot run on this hardware. IF and WHILE arrive
// with the test answer still pending, and that display would cover the message, so it
// is cleared first.
fn structNotHere() void {
    temporaryInformation = TI_NO_INFO;
    displayCalcErrorMessage(ERROR_NOT_AVAILABLE_HERE, ERR_REGISTER_LINE, REGISTER_X);
}

// ===========================================================================
// The half that runs the structures
// ===========================================================================
// Every entry point below is compiled in both builds. Without the option the body
// is the refusal above, or "nothing to do" for the predicates the program editor
// and the file writer call whatever the build.

// True when the step holds exactly this operation.
fn structStepIs(step: [*c]u8, op: u16) bool {
    return structOpOfStep(step) == op;
}

// The structures VALID has open at the step it is reading: what opened each one,
// whether its WHILE has been seen, the step number it opened at, the partner number
// it was given, whether a routine boundary crossed it, and, for a FOR, the step
// itself. An unclosed structure reports the step number.
var structOpenedBy: [STRUCT_MAX_NESTING]u16 = @splat(0);
var structOpenSawWhile: [STRUCT_MAX_NESTING]bool = @splat(false);
var structOpenStepNumber: [STRUCT_MAX_NESTING]u16 = @splat(0);
var structOpenNumber: [STRUCT_MAX_NESTING]u16 = @splat(0);
var structOpenCrossed: [STRUCT_MAX_NESTING]bool = @splat(false);
var structOpenForStep: [STRUCT_MAX_NESTING][*c]u8 = @splat(null);

// The running FOR structures. A row is filled as a loop opens and its step set back
// to 0 as it closes. The row is what a NEXT trusts: it reads the two local registers
// only because a row says a loop of its counter runs at its level, and a program
// cannot write a row. The table is saved with the calculator, so a loop survives a
// power cycle.
var forLoopTable: [FOR_MAX_LOOPS]forLoop_t = @splat(.{
    .counterRegister = 0,
    .localStepNumber = 0,
    .localRegisterBase = 0,
    .programNumber = 0,
    .stepDescends = 0,
    .subroutineLevel = 0,
});

// Where each running FOR stands in memory. Not part of the saved state: program
// memory moves, so this is set as a loop opens and tested before it is used.
var forLoopStep: [FOR_MAX_LOOPS][*c]u8 = @splat(null);

comptime {
    // Only a build that runs the structures has a table for backup.cfg to carry, and
    // only that build's saveRestoreBackup owner names it.
    if (option_structured_pgm) @export(&forLoopTable, .{ .name = "forLoopTable" });
}

// True when the two steps carry the same counter. Both are a FOR or a NEXT, so the
// operand runs from the third byte to the end of the step. The bytes are compared as
// they stand: the written form is what pairs them, and an indirect operand is not
// resolved.
fn forStepsSameCounter(forStep: [*c]u8, nextStep: [*c]u8) bool {
    const forEnd = findNextStep(forStep);
    const nextEnd = findNextStep(nextStep);

    if (forEnd == null or nextEnd == null or (forEnd - forStep) != (nextEnd - nextStep)) {
        return false;
    }
    const stepLength: u16 = @intCast(forEnd - forStep);
    var byte: u16 = 2;
    while (byte < stepLength) : (byte += 1) {
        if (forStep[byte] != nextStep[byte]) {
            return false;
        }
    }
    return true;
}

// A partner number runs from 1 to STRUCT_MAX_NUMBER, which is the whole range one
// operand byte holds. 0 is what an unnumbered step carries.
fn structNumberIsValid(structureNumber: u16) bool {
    return structureNumber != 0 and structureNumber <= STRUCT_MAX_NUMBER;
}

// Running an unnumbered step stops the program.
fn structNumberMissing(structureNumber: u16) bool {
    if (structNumberIsValid(structureNumber)) {
        return false;
    }
    temporaryInformation = TI_NO_INFO;
    displayCalcErrorMessage(ERROR_STRUCTURE_NOT_NUMBERED, ERR_REGISTER_LINE, REGISTER_X);
    return true;
}

// The local step number a label-list entry stands at, in the arithmetic the C does:
// the entry's step is stored negated, and the program's own first step is taken off
// it. Both narrow to uint16_t, as the C locals do.
inline fn structLabelLocalStep(label: u16, programStep: u16) u16 {
    return @truncate(@as(u32, @bitCast((0 -% labelList[label].step) -% @as(i32, programStep) +% 1)));
}

// The nearest recorded structure step of this number, below the step in hand when
// 'below' is set and above it otherwise. Only the op codes named count, and
// 'secondOp' is 0 when one op ends the search. scanLabelsAndPrograms() holds them all
// in the label list, after the real labels, in program and step order, so the walk
// stops once it is past its target and program memory is never scanned. Nearest, and
// never wrapping, lets one number serve structures that follow one another rather
// than nest.
fn structFindPartner(structureNumber: u16, firstOp: u16, secondOp: u16, below: bool) u16 {
    const lastLabel = numberOfLabels + numberOfStructureLabels;
    const programStep: u16 = @truncate(@as(u32, @bitCast(programList[currentProgramNumber - 1].step)));
    var bestLabel = lastLabel;

    var label = numberOfLabels;
    while (label < lastLabel) : (label += 1) {
        if (labelList[label].program > currentProgramNumber) {
            break;
        }
        if (labelList[label].program != currentProgramNumber) {
            continue;
        }
        const localStep = structLabelLocalStep(label, programStep);
        if (if (below) (localStep <= currentLocalStepNumber) else (localStep >= currentLocalStepNumber)) {
            if (!below) {
                break; // the entries ascend, so everything from here on is below the step in hand
            }
            continue;
        }
        if (labelList[label].labelPointer[0] != structureNumber) {
            continue;
        }
        if (!structStepIs(labelList[label].labelPointer - 2, firstOp) and
            !(secondOp != 0 and structStepIs(labelList[label].labelPointer - 2, secondOp)))
        {
            continue;
        }
        if (below) {
            return label; // the first one below is the nearest
        }
        bestLabel = label; // above, the last one seen is the nearest
    }
    return bestLabel;
}

// Go to the step after the partner found. The label list holds that step, so the jump
// is the lookup a GTO to a local label makes.
fn structJumpToLabel(label: u16) bool {
    if (label >= numberOfLabels + numberOfStructureLabels) {
        return false;
    }
    // the step after the one found
    currentLocalStepNumber = @truncate(@as(u32, @bitCast((0 -% labelList[label].step) -% programList[currentProgramNumber - 1].step +% 2)));
    currentStep = labelList[label].instructionPointer;
    return true;
}

fn structJumpToPartner(structureNumber: u16, firstOp: u16, secondOp: u16, below: bool) bool {
    return structJumpToLabel(structFindPartner(structureNumber, firstOp, secondOp, below));
}

pub export fn fnIf(structureNumber: u16) callconv(.c) void {
    if (comptime !option_structured_pgm) return structNotHere();
    if (programRunStop != PGM_RUNNING) {
        return;
    }
    if (structNumberMissing(structureNumber)) {
        return;
    }
    if (temporaryInformation != TI_TRUE and temporaryInformation != TI_FALSE) {
        displayCalcErrorMessage(ERROR_IF_WHILE_CONDITION_MISSING, ERR_REGISTER_LINE, REGISTER_X);
        return;
    }
    if (temporaryInformation == TI_TRUE) {
        temporaryInformation = TI_NO_INFO;
        fnSkip(0);
        return;
    }
    temporaryInformation = TI_NO_INFO;
    // A false IF ends its branch at either token, whichever comes first.
    if (!structJumpToPartner(structureNumber, ITM_ENDIF, ITM_ELSE, true)) {
        displayCalcErrorMessage(ERROR_STRUCTURE_INVALID, ERR_REGISTER_LINE, REGISTER_X); // Redundant message, cannot happen with validated program
    }
}

// Closes the true branch by jumping past its own ENDIF. An ELSE no IF opened is
// reached and jumps the same way. Only ENDIF ends the search: a second ELSE of the
// same structure belongs to the branch being skipped.
pub export fn fnElse(structureNumber: u16) callconv(.c) void {
    if (comptime !option_structured_pgm) return structNotHere();
    if (programRunStop != PGM_RUNNING) {
        return;
    }
    if (structNumberMissing(structureNumber)) {
        return;
    }
    if (!structJumpToPartner(structureNumber, ITM_ENDIF, 0, true)) {
        displayCalcErrorMessage(ERROR_STRUCTURE_INVALID, ERR_REGISTER_LINE, REGISTER_X); // Redundant message, cannot happen with validated program
    }
}

// Nothing to do. Both branches end here and the step after it is the one to run.
pub export fn fnEndif(structureNumber: u16) callconv(.c) void {
    if (comptime !option_structured_pgm) return structNotHere();
    if (programRunStop != PGM_RUNNING) {
        return;
    }
    if (structNumberMissing(structureNumber)) {
        return;
    }
    fnSkip(0);
}

// Nothing to do. The test follows it, and the ENDDO comes back to the step after this
// one.
pub export fn fnDo(structureNumber: u16) callconv(.c) void {
    if (comptime !option_structured_pgm) return structNotHere();
    if (programRunStop != PGM_RUNNING) {
        return;
    }
    if (structNumberMissing(structureNumber)) {
        return;
    }
    fnSkip(0);
}

// The test answer decides the loop: true runs the body, false leaves the structure by
// jumping past its own ENDDO.
pub export fn fnWhile(structureNumber: u16) callconv(.c) void {
    if (comptime !option_structured_pgm) return structNotHere();
    if (programRunStop != PGM_RUNNING) {
        return;
    }
    if (structNumberMissing(structureNumber)) {
        return;
    }
    if (temporaryInformation != TI_TRUE and temporaryInformation != TI_FALSE) {
        displayCalcErrorMessage(ERROR_IF_WHILE_CONDITION_MISSING, ERR_REGISTER_LINE, REGISTER_X);
        return;
    }
    if (temporaryInformation == TI_TRUE) {
        temporaryInformation = TI_NO_INFO;
        fnSkip(0);
        return;
    }
    temporaryInformation = TI_NO_INFO;
    if (!structJumpToPartner(structureNumber, ITM_ENDDO, 0, true)) {
        displayCalcErrorMessage(ERROR_STRUCTURE_INVALID, ERR_REGISTER_LINE, REGISTER_X); // Redundant message, cannot happen with validated program
    }
}

// Goes back to its own DO, landing on the step after it, which is the test. An ENDDO
// that no DO opened has nowhere to go and says so.
pub export fn fnEnddo(structureNumber: u16) callconv(.c) void {
    if (comptime !option_structured_pgm) return structNotHere();
    if (programRunStop != PGM_RUNNING) {
        return;
    }
    if (structNumberMissing(structureNumber)) {
        return;
    }
    // The nearest DO above is the loop this closes, unless an ENDDO of the same number
    // lies between the two: that one closed it, so nothing is open here and the jump
    // would re-enter a finished loop.
    const doLabel = structFindPartner(structureNumber, ITM_DO, 0, false);
    const enddoLabel = structFindPartner(structureNumber, ITM_ENDDO, 0, false);

    if (doLabel < numberOfLabels + numberOfStructureLabels and
        (enddoLabel >= numberOfLabels + numberOfStructureLabels or labelList[enddoLabel].step > labelList[doLabel].step))
    {
        _ = structJumpToLabel(doLabel);
        return;
    }
    displayCalcErrorMessage(ERROR_STRUCTURE_INVALID, ERR_REGISTER_LINE, REGISTER_X); // Redundant message, cannot happen with validated program
}

// Nothing to do. The body follows, and the UNTIL comes back to the step after this
// one.
pub export fn fnRepeat(structureNumber: u16) callconv(.c) void {
    if (comptime !option_structured_pgm) return structNotHere();
    if (programRunStop != PGM_RUNNING) {
        return;
    }
    if (structNumberMissing(structureNumber)) {
        return;
    }
    fnSkip(0);
}

// The test is at the end, not the top, so the body has already run: true ends the
// loop, false goes back to the step after its own REPEAT. A stray UNTIL says so.
pub export fn fnUntil(structureNumber: u16) callconv(.c) void {
    if (comptime !option_structured_pgm) return structNotHere();
    if (programRunStop != PGM_RUNNING) {
        return;
    }
    if (structNumberMissing(structureNumber)) {
        return;
    }
    if (temporaryInformation != TI_TRUE and temporaryInformation != TI_FALSE) {
        displayCalcErrorMessage(ERROR_IF_WHILE_CONDITION_MISSING, ERR_REGISTER_LINE, REGISTER_X);
        return;
    }
    if (temporaryInformation == TI_TRUE) {
        temporaryInformation = TI_NO_INFO;
        fnSkip(0);
        return;
    }
    temporaryInformation = TI_NO_INFO;
    // The nearest REPEAT above is the one this closes, unless an UNTIL of the same
    // number lies between them: that one closed it and this jump would re-enter it.
    const repeatLabel = structFindPartner(structureNumber, ITM_REPEAT, 0, false);
    const untilLabel = structFindPartner(structureNumber, ITM_UNTIL, 0, false);

    if (repeatLabel < numberOfLabels + numberOfStructureLabels and
        (untilLabel >= numberOfLabels + numberOfStructureLabels or labelList[untilLabel].step > labelList[repeatLabel].step))
    {
        _ = structJumpToLabel(repeatLabel);
        return;
    }
    displayCalcErrorMessage(ERROR_STRUCTURE_INVALID, ERR_REGISTER_LINE, REGISTER_X); // Redundant message, cannot happen with validated program
}

// True when the pointer the FOR left still reaches that FOR. Program memory moves
// when a step is inserted or deleted, so it is trusted only while it lies inside the
// open program and still reads as a FOR. A NEXT that cannot trust it counts steps
// from the top of the program instead, as every jump did before.
fn forLoopStepPointerLive(row: u16) bool {
    const step = forLoopStep[row];

    return step != null and @intFromPtr(step) >= @intFromPtr(beginOfCurrentProgram) and
        @intFromPtr(step) < @intFromPtr(endOfCurrentProgram) and structPlainOp(structOpOfStep(step)) == ITM_FOR;
}

// True when the two registers the row names are still there. LocR and PopLR set the
// count outright, so either can delete them under a running loop, and the row alone
// would then send the NEXT to whatever took their place.
fn forLoopRegistersLive(row: u16) bool {
    return forLoopTable[row].localRegisterBase + FOR_LOCALS <= FIRST_LOCAL_REGISTER + currentNumberOfLocalRegisters();
}

// No FOR structure runs after a state file is loaded. The state file does not carry
// them.
pub export fn forClearLoops() callconv(.c) void {
    if (comptime !option_structured_pgm) return; // no FOR runs on this hardware
    var row: u16 = 0;
    while (row < FOR_MAX_LOOPS) : (row += 1) {
        forLoopTable[row].localStepNumber = 0;
        forLoopStep[row] = null;
    }
}

// forLoopRegistersLive compares the row's first register number against the last
// local register the level now running owns. A row of this level failing that test has
// lost the two registers its NEXT reads, so its localStepNumber is set to 0 and
// another loop may take the row.
fn forDropDeadLoops() void {
    var row: u16 = 0;
    while (row < FOR_MAX_LOOPS) : (row += 1) {
        if (forLoopTable[row].localStepNumber != 0 and (forLoopTable[row].subroutineLevel > currentSubroutineLevel() or
            (forLoopTable[row].subroutineLevel == currentSubroutineLevel() and
                (forLoopTable[row].programNumber != currentProgramNumber or !forLoopRegistersLive(row)))))
        {
            forLoopTable[row].localStepNumber = 0;
        }
    }
}

// Deleting a named variable compacts the table and moves every variable above it down
// one, so a running loop counting in one of those follows its counter. A loop counting
// in the variable deleted has lost what it counts in, and the number it holds now
// names whatever moves into that slot, so the loop ends here. The delete is the only
// place that is known without the name: a NEXT reading a register number alone cannot
// tell a variable from the one that replaced it.
pub export fn forAdjustCountersAfterVariableDelete(deletedVariable: u16) callconv(.c) void {
    if (comptime !option_structured_pgm) return; // no VALID to write the numbers, so nothing pairs and nothing runs
    var row: u16 = 0;
    while (row < FOR_MAX_LOOPS) : (row += 1) {
        if (forLoopTable[row].localStepNumber != 0 and forLoopTable[row].counterRegister == deletedVariable) {
            forLoopTable[row].localStepNumber = 0;
        } else if (forLoopTable[row].localStepNumber != 0 and forLoopTable[row].counterRegister > deletedVariable and
            forLoopTable[row].counterRegister <= LAST_NAMED_VARIABLE)
        {
            forLoopTable[row].counterRegister -= 1;
        }
    }
}

// The running loop counting in this register at this level, or FOR_MAX_LOOPS when
// there is none.
fn forLoopOfCounter(counter: u16) u16 {
    var row: u16 = 0;
    while (row < FOR_MAX_LOOPS) : (row += 1) {
        if (forLoopTable[row].localStepNumber != 0 and forLoopTable[row].subroutineLevel == currentSubroutineLevel() and
            forLoopTable[row].counterRegister == counter)
        {
            return row;
        }
    }
    return FOR_MAX_LOOPS;
}

// Prevent having the same variable in a second simultaneous FOR loop. A local register
// belongs to the subroutine level that declared it, so a loop of another level counting
// in one of the same number counts in a different register; every other register is one
// register whatever the level. A routine called from a body is a level down, which is
// why the level alone will not do.
fn forCounterAlreadyCounted(counter: u16) bool {
    var row: u16 = 0;
    while (row < FOR_MAX_LOOPS) : (row += 1) {
        if (forLoopTable[row].localStepNumber != 0 and forLoopTable[row].counterRegister == counter and
            (forLoopTable[row].subroutineLevel == currentSubroutineLevel() or counter < FIRST_LOCAL_REGISTER))
        {
            return true;
        }
    }
    return false;
}

// The running loop that opened at this step and level: this FOR reached a second time
// with its loop still open. BST then SST does that, and so does a GTO onto it. The loop
// carries on rather than taking a second pair of registers.
fn forLoopOfStep() u16 {
    var row: u16 = 0;
    while (row < FOR_MAX_LOOPS) : (row += 1) {
        if (forLoopTable[row].localStepNumber == currentLocalStepNumber and forLoopTable[row].subroutineLevel == currentSubroutineLevel()) {
            return row;
        }
    }
    return FOR_MAX_LOOPS;
}

// A free row, or FOR_MAX_LOOPS when every row is running.
fn forFreeLoopRow() u16 {
    var row: u16 = 0;
    while (row < FOR_MAX_LOOPS) : (row += 1) {
        if (forLoopTable[row].localStepNumber == 0) {
            return row;
        }
    }
    return FOR_MAX_LOOPS;
}

// True when a loop of this level opened at a later step than the row given, so it is
// inside that one and still running. Loops nest in the text, so the innermost is always
// the latest step and owns the pair at the top of the level. Closing an outer loop
// first is a crossed structure.
fn forInnerLoopStillOpen(row: u16) bool {
    var other: u16 = 0;
    while (other < FOR_MAX_LOOPS) : (other += 1) {
        if (forLoopTable[other].localStepNumber != 0 and forLoopTable[other].subroutineLevel == currentSubroutineLevel() and
            forLoopTable[other].localStepNumber > forLoopTable[row].localStepNumber)
        {
            return true;
        }
    }
    return false;
}

// True when a NEXT closes the FOR now running, somewhere below it in the same program.
// RTN does not end the search: an RTN inside the body is the early exit the
// specification allows, and stopping there would refuse a loop that is written
// correctly.
fn forNextOfThisFor(stepsAhead: ?*u16) [*c]u8 {
    var step = findNextStep(currentStep);
    var depth: u16 = 0;
    var ahead: u16 = 1;

    while (step != null and !isAtEndOfProgram(step) and !isAtEndOfPrograms(step)) {
        if (structPlainOp(structOpOfStep(step)) == ITM_FOR) {
            depth += 1;
        } else if (structPlainOp(structOpOfStep(step)) == ITM_NEXT) {
            if (depth == 0) {
                if (stepsAhead) |out| {
                    out.* = ahead;
                }
                return step;
            }
            depth -= 1;
        }
        step = findNextStep(step);
        ahead += 1;
    }
    return null;
}

fn forHasNext() bool {
    return forNextOfThisFor(null) != null;
}

// True when the two registers hold the same value. Long and short integers compare
// exactly. A complex value is compared part by part, the ordinary compare having no
// meaning for it.
fn forValuesEqual(first: calcRegister_t, second: calcRegister_t) bool {
    var cmp: i8 = 0;

    if (getRegisterDataType(first) == dtComplex34 or getRegisterDataType(second) == dtComplex34) {
        var firstRe: real_t = undefined;
        var firstIm: real_t = undefined;
        var secondRe: real_t = undefined;
        var secondIm: real_t = undefined;
        var cmplx: bool = false;

        if (!getRegisterAsComplexOrAnyRealQuiet(first, &firstRe, &firstIm, &cmplx) or
            !getRegisterAsComplexOrAnyRealQuiet(second, &secondRe, &secondIm, &cmplx))
        {
            return false;
        }
        realSubtract(&firstRe, &secondRe, &firstRe, &ctxtReal39);
        realSubtract(&firstIm, &secondIm, &firstIm, &ctxtReal39);
        return realIsZero(&firstRe) and realIsZero(&firstIm);
    }
    return registerCmp(first, second, &cmp) and cmp == 0;
}

// True for a value a FOR can count with: a long or short integer, a real or a complex
// number. Anything else, a string or a matrix among them, can be neither stepped nor
// compared, and a loop given one would run its body once and say nothing.
fn forValueCanCount(regist: calcRegister_t) bool {
    return getRegisterDataType(regist) == dtLongInteger or getRegisterDataType(regist) == dtShortInteger or
        getRegisterDataType(regist) == dtReal34 or getRegisterDataType(regist) == dtComplex34;
}

// True when adding the step to the value leaves it where it was, so no number of
// passes reaches the end. A step of zero is the plain case; a step too small for the
// value's digits, and a value so large that the step rounds away, are the same fault
// and take the same message. The sum is worked in the stack the way NEXT works it, so
// the two agree digit for digit. X and Y are put back from a snapshot in memory:
// saving them into the two saved stack registers allocates, and an allocation while a
// loop is open takes the storage of the loop's own two local registers.
fn forStepCannotMove(value: calcRegister_t, stepReg: calcRegister_t) bool {
    var snapX: snap_t = .{};
    var snapY: snap_t = .{};

    saveRegisterSnapshot(REGISTER_X, &snapX);
    saveRegisterSnapshot(REGISTER_Y, &snapY);
    copySourceRegisterToDestRegister(value, TEMP_REGISTER_1);
    copySourceRegisterToDestRegister(stepReg, REGISTER_X);
    copySourceRegisterToDestRegister(TEMP_REGISTER_1, REGISTER_Y);
    addition[getRegisterDataType(REGISTER_X)][getRegisterDataType(REGISTER_Y)].?();
    const same = (lastErrorCode == ERROR_NONE) and forValuesEqual(REGISTER_X, TEMP_REGISTER_1);
    restoreRegisterSnapshot(REGISTER_X, &snapX);
    restoreRegisterSnapshot(REGISTER_Y, &snapY);
    return same;
}

// True when the counter has passed the end value, which ends the loop. A real or
// integer counter compares against the end directly, upwards for a positive step and
// downwards for a negative one or a descending row, in an arithmetic that keeps a long
// integer exact. A complex value in any of the three compares two lengths from the
// origin instead, the counter's against the end value's, squared so no root is needed
// and no answer changes.
fn forCounterPastEnd(counter: calcRegister_t, endReg: calcRegister_t, stepReg: calcRegister_t, descends: bool) bool {
    var cmp: i8 = 0;

    if (getRegisterDataType(counter) == dtComplex34 or getRegisterDataType(endReg) == dtComplex34 or
        getRegisterDataType(stepReg) == dtComplex34)
    {
        var counterRe: real_t = undefined;
        var counterIm: real_t = undefined;
        var endRe: real_t = undefined;
        var endIm: real_t = undefined;
        var reach: real_t = undefined;
        var target: real_t = undefined;
        var term: real_t = undefined;
        var cmplx: bool = false;

        if (!getRegisterAsComplexOrAnyRealQuiet(counter, &counterRe, &counterIm, &cmplx) or
            !getRegisterAsComplexOrAnyRealQuiet(endReg, &endRe, &endIm, &cmplx))
        {
            return true; // a value the arithmetic cannot read ends the loop instead of running for ever
        }
        realMultiply(&counterRe, &counterRe, &reach, &ctxtReal39);
        realMultiply(&counterIm, &counterIm, &term, &ctxtReal39);
        realAdd(&reach, &term, &reach, &ctxtReal39);
        realMultiply(&endRe, &endRe, &target, &ctxtReal39);
        realMultiply(&endIm, &endIm, &term, &ctxtReal39);
        realAdd(&target, &term, &target, &ctxtReal39);
        realCompare(&reach, &target, &term, &ctxtReal39);
        return !realIsZero(&term) and realIsPositive(&term);
    }

    var step39: real_t = undefined;

    if (!registerCmp(counter, endReg, &cmp) or !getRegisterAsAnyRealQuiet(stepReg, &step39)) {
        return true;
    }
    return if (descends or !realIsPositive(&step39)) (cmp < 0) else (cmp > 0);
}

// True when the step carried the counter the wrong way. A short integer does that when
// the addition passes the word size and wraps: the counter reappears at the far end and
// can never reach its end value. The loop ends there, holding the last value that did
// not wrap.
fn forStepWentBackwards(sum: calcRegister_t, counter: calcRegister_t, stepReg: calcRegister_t, descends: bool) bool {
    var cmp: i8 = 0;
    var step39: real_t = undefined;

    if (getRegisterDataType(counter) == dtComplex34 or getRegisterDataType(sum) == dtComplex34) {
        return false; // a complex counter has no direction, and its own length test ends the loop
    }
    if (!registerCmp(sum, counter, &cmp) or !getRegisterAsAnyRealQuiet(stepReg, &step39)) {
        return false;
    }
    return if (descends or !realIsPositive(&step39)) (cmp > 0) else (cmp < 0);
}

// The out of range refusal adjustResult makes for every other addition. adjustResult
// itself cannot be called here: it drops the stack and undoes the whole step, where the
// caller borrows X and Y and puts them back.
fn forRefuseInfinite(regist: calcRegister_t, value: *align(1) const real34_t) void {
    if (real34IsInfinite(value)) {
        displayCalcErrorMessage(if (real34IsPositive(value)) ERROR_OVERFLOW_PLUS_INF else ERROR_OVERFLOW_MINUS_INF, ERR_REGISTER_LINE, regist);
    }
}

// One step of the counter, and whether that step passed the end. The arithmetic runs in
// the stack the way an arithmetic store does, borrowing the same two saved registers,
// so a NEXT costs what a STO+ costs and leaves X and Y as it found them. A descending
// row subtracts the increment where the others add it.
fn forStepAndTest(counter: calcRegister_t, endReg: calcRegister_t, stepReg: calcRegister_t, descends: bool, keepLastStep: bool) bool {
    var snapX: snap_t = .{};
    var snapY: snap_t = .{};

    saveRegisterSnapshot(REGISTER_X, &snapX);
    saveRegisterSnapshot(REGISTER_Y, &snapY);
    copySourceRegisterToDestRegister(counter, TEMP_REGISTER_1);
    copySourceRegisterToDestRegister(stepReg, REGISTER_X);
    copySourceRegisterToDestRegister(TEMP_REGISTER_1, REGISTER_Y);
    if (getRegisterDataType(REGISTER_Y) == dtShortInteger) {
        regShortInt(REGISTER_Y).* &= shortIntegerMask;
    }
    if (descends) {
        subtraction[getRegisterDataType(REGISTER_X)][getRegisterDataType(REGISTER_Y)].?();
    } else {
        addition[getRegisterDataType(REGISTER_X)][getRegisterDataType(REGISTER_Y)].?();
    }
    if (!getSystemFlag(FLAG_SPCRES) and lastErrorCode == ERROR_NONE) { // out of range, which every other addition refuses under this flag
        if (getRegisterDataType(REGISTER_X) == dtReal34) {
            forRefuseInfinite(REGISTER_X, reg34(REGISTER_X));
        } else if (getRegisterDataType(REGISTER_X) == dtComplex34) {
            forRefuseInfinite(REGISTER_X, reg34(REGISTER_X));
            forRefuseInfinite(REGISTER_X, regImag34(REGISTER_X));
        }
    }
    if (lastErrorCode == ERROR_NONE and forValuesEqual(REGISTER_X, TEMP_REGISTER_1)) { // the counter has grown until the step rounds away, so the end is now
        displayCalcErrorMessage(ERROR_STEP_OF_ZERO, ERR_REGISTER_LINE, REGISTER_X); // unreachable whatever the FOR was given
    }
    const unusable = (lastErrorCode != ERROR_NONE) or forStepWentBackwards(REGISTER_X, TEMP_REGISTER_1, stepReg, descends);
    const past = unusable or forCounterPastEnd(REGISTER_X, endReg, stepReg, descends);
    // A bottom tested row keeps the value its last pass ran with, a top tested row the
    // step that failed, one past the end, its comparison belonging at the FOR. An
    // unusable step is written for neither: X then contains a wrapped or errored value
    // the loop never produced.
    const writeBack = !past or (keepLastStep and !unusable);
    if (writeBack) {
        copySourceRegisterToDestRegister(REGISTER_X, TEMP_REGISTER_1);
    }
    restoreRegisterSnapshot(REGISTER_X, &snapX);
    restoreRegisterSnapshot(REGISTER_Y, &snapY);
    if (writeBack) {
        copySourceRegisterToDestRegister(TEMP_REGISTER_1, counter);
    }
    return past;
}

// FOR opens a counted structure. The start comes from Z, the end from Y and the step
// from X, the layout Sigma-n uses, and all three leave the stack. The start goes to the
// counter; the end and the step go to two local registers of the structure's own, above
// whatever the routine declared. The body always runs once, because the comparison is at
// the NEXT.
pub export fn fnFor(regist: u16) callconv(.c) void {
    if (comptime !option_structured_pgm) return structNotHere();
    if (programRunStop != PGM_RUNNING) {
        return;
    }
    forDropDeadLoops();
    var row = forLoopOfStep();
    const base = currentNumberOfLocalRegisters();

    if (row < FOR_MAX_LOOPS and forLoopRegistersLive(row)) {
        return; // this FOR is running already, reached again by BST or by a GTO, so its loop carries on untouched and the stack is left alone
    }
    if (!isRegInRange(regist)) { // the quiet range test, so the counter's own message is the one that shows
        displayCalcErrorMessage(ERROR_INVALID_COUNTER_REGISTER, ERR_REGISTER_LINE, REGISTER_X);
        return;
    }
    if (!forValueCanCount(REGISTER_Z) or !forValueCanCount(REGISTER_Y) or !forValueCanCount(REGISTER_X)) {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        return;
    }
    if (forStepCannotMove(REGISTER_Z, REGISTER_X)) { // the start plus the step, against the start
        displayCalcErrorMessage(ERROR_STEP_OF_ZERO, ERR_REGISTER_LINE, REGISTER_X);
        return;
    }
    if (!forHasNext()) {
        displayCalcErrorMessage(ERROR_NEXT_NOT_FOUND, ERR_REGISTER_LINE, REGISTER_X);
        return;
    }
    if (row < FOR_MAX_LOOPS) { // the row outlived its registers, which a run that ended inside the loop does, so it is free again
        forLoopTable[row].localStepNumber = 0;
    }
    if (forCounterAlreadyCounted(regist)) { // a running loop already counts in it, so neither could ever end
        displayCalcErrorMessage(ERROR_INVALID_COUNTER_REGISTER, ERR_REGISTER_LINE, REGISTER_X);
        return;
    }
    row = forFreeLoopRow();
    if (row >= FOR_MAX_LOOPS or base + FOR_LOCALS > FOR_MAX_LOCALS) {
        displayCalcErrorMessage(ERROR_NESTING_TOO_DEEP, ERR_REGISTER_LINE, REGISTER_X);
        return;
    }
    allocateLocalRegisters(base + FOR_LOCALS);
    if (lastErrorCode != ERROR_NONE) {
        return;
    }
    forLoopTable[row].counterRegister = regist;
    forLoopTable[row].localRegisterBase = FIRST_LOCAL_REGISTER + base; // where its two registers are, not merely that they are on top
    forLoopTable[row].subroutineLevel = @truncate(currentSubroutineLevel());
    forLoopTable[row].programNumber = currentProgramNumber;
    forLoopTable[row].stepDescends = 0; // both bits clear: FOR adds the step it was handed, whichever way it points, and compares at its NEXT
    forLoopStep[row] = currentStep; // where the FOR stands, so a pass returns to it without counting steps from the top of the program
    forLoopTable[row].localStepNumber = currentLocalStepNumber; // last, since it is what marks the row taken

    copySourceRegisterToDestRegister(REGISTER_Y, @intCast(FIRST_LOCAL_REGISTER + base));
    copySourceRegisterToDestRegister(REGISTER_X, @intCast(FIRST_LOCAL_REGISTER + base + 1));
    fnDrop(NOPARAM);
    fnDrop(NOPARAM);
    copySourceRegisterToDestRegister(REGISTER_X, TEMP_REGISTER_1); // the start goes aside for the last drop and fills the counter after it: a counter in a stack register
    fnDrop(NOPARAM); // would otherwise be written and then moved over by that drop
    copySourceRegisterToDestRegister(TEMP_REGISTER_1, @bitCast(regist));
}

// FORyx opens the same structure as FOR from the start in Y and the end in X. The step
// is a 1 in the start's type, so the counter holds one type throughout. An end below the
// start marks the row descending and NEXT subtracts that 1, so nothing negative is built
// and unsigned counts down. A complex value has no direction and counts up. The lift
// leaves the three values FOR reads.
pub export fn fnForYx(regist: u16) callconv(.c) void {
    if (comptime !option_structured_pgm) return structNotHere();
    if (programRunStop != PGM_RUNNING) {
        return;
    }
    forDropDeadLoops();
    const running = forLoopOfStep();

    if (running < FOR_MAX_LOOPS and forLoopRegistersLive(running)) {
        return; // this FOR is running already, reached again by BST or by a GTO, so the test below it decides the pass and the stack is left alone
    }
    if (!forValueCanCount(REGISTER_Y) or !forValueCanCount(REGISTER_X)) {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        return;
    }
    const startType = getRegisterDataType(REGISTER_Y);
    const startBase = getRegisterShortIntegerBase(REGISTER_Y);
    var cmp: i8 = 0;
    var down = false;

    if (startType != dtComplex34 and getRegisterDataType(REGISTER_X) != dtComplex34) {
        down = registerCmp(REGISTER_Y, REGISTER_X, &cmp) and cmp > 0; // the start stands above the end, so the count runs down to it
    }
    setSystemFlag(FLAG_ASLIFT); // the end value has to reach Y whatever the step before this one left behind, so the lift is not the conditional one
    liftStack();
    switch (startType) {
        dtShortInteger => {
            convertUInt64ToShortIntegerRegister(0, 1, startBase, REGISTER_X);
        },
        dtLongInteger => {
            var stepValue: mpz_struct = undefined;

            longIntegerInit(&stepValue);
            int32ToLongInteger(1, &stepValue);
            convertLongIntegerToLongIntegerRegister(&stepValue, REGISTER_X);
            longIntegerFree(&stepValue);
        },
        dtComplex34 => {
            reallocateRegister(REGISTER_X, dtComplex34, 0, amNone);
            real34Copy(const34_1(), reg34(REGISTER_X));
            real34Copy(const34_0(), regImag34(REGISTER_X));
        },
        else => { // liftStack() has made X a real34 already, so only the value is left to write
            int32ToReal34(1, reg34(REGISTER_X));
        },
    }
    fnFor(regist);
    if (down and lastErrorCode == ERROR_NONE) { // the row at this step and level, which FOR has just filled or found already running
        const row = forLoopOfStep();

        if (row < FOR_MAX_LOOPS) {
            forLoopTable[row].stepDescends |= FOR_STEP_DESCENDS;
        }
    }
}

// FORTOP opens the same structure as FOR from the same three values, and the one
// difference is where the first comparison happens. FOR compares at its NEXT, so a body
// always runs once. FORTOP compares the start against the end before any pass, which is
// where the HP-71B and ANSI BASIC put it, so a start already past the end runs no pass at
// all and the run carries on below the NEXT. Every later pass is decided at the NEXT
// exactly as before, so the two forms differ in that first comparison and in nothing
// else. The row is marked FOR_TOP_TESTED, which its NEXT uses to decide what the counter
// keeps on the way out: a top tested loop leaves it one step past the end.
pub export fn fnForTop(regist: u16) callconv(.c) void {
    if (comptime !option_structured_pgm) return structNotHere();
    if (programRunStop != PGM_RUNNING) {
        return;
    }
    forDropDeadLoops();
    const entered = forLoopOfStep();
    const reEntered = entered < FOR_MAX_LOOPS and forLoopRegistersLive(entered); // BST or a GTO back to this step, so the loop is running and nothing is compared

    fnFor(regist);
    if (lastErrorCode != ERROR_NONE) {
        return;
    }
    const row = forLoopOfStep();

    if (row >= FOR_MAX_LOOPS) {
        return;
    }
    forLoopTable[row].stepDescends |= FOR_TOP_TESTED;

    const base = forLoopTable[row].localRegisterBase;

    if (!reEntered and forCounterPastEnd(@bitCast(regist), @bitCast(base), @bitCast(base +% 1), (forLoopTable[row].stepDescends & FOR_STEP_DESCENDS) != 0)) {
        var ahead: u16 = 0;
        const nextStep = forNextOfThisFor(&ahead);

        if (nextStep == null) { // fnFor refuses a FOR with no NEXT below it, so this cannot be reached from a program that got this far
            displayCalcErrorMessage(ERROR_NEXT_NOT_FOUND, ERR_REGISTER_LINE, REGISTER_X);
            return;
        }
        forLoopTable[row].localStepNumber = 0; // the row goes, no pass having been run
        allocateLocalRegisters(forLoopTable[row].localRegisterBase - FIRST_LOCAL_REGISTER); // and the two registers with it
        currentLocalStepNumber +%= ahead + 1;
        currentStep = findNextStep(nextStep);
        return;
    }
    currentLocalStepNumber +%= 1; // this step places its own pointer, as NEXT does, so the body is entered from here
    currentStep = findNextStep(currentStep);
}

// NEXT steps the counter and decides the pass. A row for a running loop of its counter at
// its own subroutine level is what says the two local registers at the top of the level
// are its own: a stray NEXT, a body reached by a GTO, and a jump over the FOR all arrive
// with no such row. Past the end the registers and the row go and the run carries on
// below, otherwise it returns to the step after the FOR, which the row names.
pub export fn fnNext(regist: u16) callconv(.c) void {
    if (comptime !option_structured_pgm) return structNotHere();
    if (programRunStop != PGM_RUNNING) {
        return;
    }
    if (!isRegInRange(regist)) {
        displayCalcErrorMessage(ERROR_INVALID_COUNTER_REGISTER, ERR_REGISTER_LINE, REGISTER_X);
        return;
    }
    forDropDeadLoops();
    const row = forLoopOfCounter(regist);

    // A loop of this level that opened at a later step is inside this one and still
    // running, so this NEXT closes out of order. Registers that are no longer there are a
    // LocR or a PopLR that deleted them under the loop, and reading whatever took their
    // place would answer wrongly and say nothing.
    if (row >= FOR_MAX_LOOPS or forInnerLoopStillOpen(row) or !forLoopRegistersLive(row)) {
        displayCalcErrorMessage(ERROR_NEXT_WITHOUT_FOR, ERR_REGISTER_LINE, REGISTER_X);
        return;
    }
    const base = forLoopTable[row].localRegisterBase;
    const counterReg: calcRegister_t = @bitCast(regist);
    const endReg: calcRegister_t = @bitCast(base);
    const stepReg: calcRegister_t = @bitCast(base +% 1);

    // The body may write the counter and the loop's own two registers as freely as any
    // other, so all three are tested here, where they are read. A type that cannot be
    // counted would otherwise end the loop without a word.
    if (!forValueCanCount(counterReg) or !forValueCanCount(endReg) or !forValueCanCount(stepReg)) {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            _ = sprintf(errorMessage, "%s of this FOR", if (!forValueCanCount(counterReg))
                @as([*:0]const u8, "the counter")
            else if (!forValueCanCount(endReg))
                @as([*:0]const u8, "the end value")
            else
                @as([*:0]const u8, "the step"));
            moreInfoOnError("In function fnNext:", errorMessage, "holds a type the loop cannot count with", null);
        }
        return;
    }

    const past = forStepAndTest(counterReg, endReg, stepReg, (forLoopTable[row].stepDescends & FOR_STEP_DESCENDS) != 0, (forLoopTable[row].stepDescends & FOR_TOP_TESTED) != 0);

    if (lastErrorCode != ERROR_NONE) {
        return;
    }
    if (!past) {
        if (forLoopStepPointerLive(row)) {
            currentLocalStepNumber = forLoopTable[row].localStepNumber +% 1; // the step after the FOR, from the row, so no search is made on a pass
            currentStep = findNextStep(forLoopStep[row]);
            return;
        }
        // No address to return to: a restore does not carry one, and an edit invalidates
        // the one there was. The step number finds the FOR again and a fresh address is
        // taken, so only the first pass after that pays for the search. A step number that
        // no longer holds a FOR is an edit that moved it, and the loop cannot go on.
        currentLocalStepNumber = forLoopTable[row].localStepNumber;
        defineCurrentStep();
        if (structPlainOp(structOpOfStep(currentStep)) != ITM_FOR) {
            displayCalcErrorMessage(ERROR_NEXT_WITHOUT_FOR, ERR_REGISTER_LINE, REGISTER_X);
            return;
        }
        forLoopStep[row] = currentStep;
        currentStep = findNextStep(currentStep);
        currentLocalStepNumber +%= 1;
        return;
    }
    forLoopTable[row].localStepNumber = 0;
    allocateLocalRegisters(forLoopTable[row].localRegisterBase - FIRST_LOCAL_REGISTER); // back to what the level held before this FOR grew it
    fnSkip(0);
}

// True when the byte range holds a STRUCT step that pairs: a numbered step, or a FOR or a
// NEXT. The editor asks before it inserts or deletes a range.
pub export fn structRangeHasNumbered(from: [*c]u8, to: [*c]u8) callconv(.c) bool_t {
    if (comptime !option_structured_pgm) return 0; // there is no VALID, so a program is never refused for carrying 0 and an edit has nothing to clear
    var step = from;

    while (step != null and @intFromPtr(step) < @intFromPtr(to)) {
        const op = structPlainOp(structOpOfStep(step));

        if (structOpHasNumber(op) != 0 or op == ITM_FOR or op == ITM_NEXT) { // a FOR or a NEXT leaving the program unpairs the rest as surely as a numbered step
            return 1;
        }
        step = findNextStep(step);
    }
    return 0;
}

// Set every partner number of the open program back to 0. An edit that adds or removes a
// numbered step can leave the rest paired wrongly, and the numbers are what the run and
// the file writer check, so they go and VALID puts them back.
pub export fn structClearProgramNumbers() callconv(.c) void {
    if (comptime !option_structured_pgm) return;
    var step = beginOfCurrentProgram;

    while (step != null and @intFromPtr(step) < @intFromPtr(endOfCurrentProgram) and !isAtEndOfProgram(step) and !isAtEndOfPrograms(step)) {
        const nextStep = findNextStep(step);

        if (structOpHasNumber(structOpOfStep(step)) != 0 and nextStep != null and (nextStep - step) >= 3) {
            step[2] = 0;
        }
        step = nextStep;
    }
}

// The marked form of a FOR or a NEXT. Only VALID writes it and only VALID takes it off.
// Reaching one in a run means VALID has not passed the structure since it was last
// edited, so the run stops with the message the numbered structures give for the same
// thing.
pub export fn fnForNotChecked(regist: u16) callconv(.c) void {
    _ = regist;
    if (comptime !option_structured_pgm) return structNotHere();
    temporaryInformation = TI_NO_INFO;
    displayCalcErrorMessage(ERROR_STRUCTURE_NOT_NUMBERED, ERR_REGISTER_LINE, REGISTER_X);
}

// The not checked form of a FOR or a NEXT. A new step enters the program in that form.
// Everything else is itself.
pub export fn structNotCheckedOp(op: u16) callconv(.c) u16 {
    if (comptime !option_structured_pgm) return op; // there is no VALID, so a step keyed in enters as itself
    if (op == ITM_FOR) {
        return ITM_FORx;
    }
    if (op == ITM_FORYX) {
        return ITM_FORYXx;
    }
    if (op == ITM_FORTOP) {
        return ITM_FORTOPx;
    }
    if (op == ITM_NEXT) {
        return ITM_NEXTx;
    }
    return op;
}

// Write the marked form of a FOR or a NEXT over the step given. Both forms are two op
// code bytes and carry the same counter, so only the second byte changes and no step
// moves.
fn structMarkNotChecked(step: [*c]u8) void {
    const op = structOpOfStep(step);

    if (op == ITM_FOR) {
        step[1] = ITM_FORx & 0xff;
    } else if (op == ITM_FORYX) {
        step[1] = ITM_FORYXx & 0xff;
    } else if (op == ITM_FORTOP) {
        step[1] = ITM_FORTOPx & 0xff;
    } else if (op == ITM_NEXT) {
        step[1] = ITM_NEXTx & 0xff;
    }
}

// Rewrite every FOR and NEXT of the open program from one form to the other. The two
// forms differ only in the second op code byte, so no step moves and the operand is
// untouched.
fn forRewriteMarks(fromFor: u16, toFor: u16, fromNext: u16, toNext: u16) void {
    var step = beginOfCurrentProgram;

    while (step != null and @intFromPtr(step) < @intFromPtr(endOfCurrentProgram) and !isAtEndOfProgram(step) and !isAtEndOfPrograms(step)) {
        const op = structOpOfStep(step);

        if (op == fromFor) {
            step[1] = @truncate(toFor);
        } else if (op == fromNext) {
            step[1] = @truncate(toNext);
        }
        step = findNextStep(step);
    }
}

// Take the mark off every FOR and NEXT of the open program. VALID does this only when the
// walk found no fault in them.
fn structClearMarks() void {
    forRewriteMarks(ITM_FORx, ITM_FOR, ITM_NEXTx, ITM_NEXT);
    forRewriteMarks(ITM_FORYXx, ITM_FORYX, ITM_NEXTx, ITM_NEXT); // the second walk finds only the FORyx steps, the NEXT of the first walk being plain already
    forRewriteMarks(ITM_FORTOPx, ITM_FORTOP, ITM_NEXTx, ITM_NEXT); // and the third only the FORTOP steps, for the same reason
}

// Forget that VALID has checked the FOR structures of the open program: every FOR and
// NEXT goes back to the not checked form. An edit that adds or removes a FOR or a NEXT
// calls this, as it calls the number clearing above, and for the same reason: what is
// left may pair wrongly.
pub export fn forClearChecked() callconv(.c) void {
    if (comptime !option_structured_pgm) return;
    forRewriteMarks(ITM_FOR, ITM_FORx, ITM_NEXT, ITM_NEXTx);
    forRewriteMarks(ITM_FORYX, ITM_FORYXx, ITM_NEXT, ITM_NEXTx); // the second walk finds only the FORyx steps, the NEXT of the first walk being marked already
    forRewriteMarks(ITM_FORTOP, ITM_FORTOPx, ITM_NEXT, ITM_NEXTx); // and the third only the FORTOP steps, for the same reason
}

// True when a structure step of the selected program carries no valid partner number, or
// is a FOR or a NEXT that VALID has not passed. Such a program can be neither stored nor
// run, so the file writer asks before it opens the file. The caller has already selected
// the program.
pub export fn structProgramHasUnnumbered() callconv(.c) bool_t {
    if (comptime !option_structured_pgm) return 0;
    var step = beginOfCurrentProgram;

    while (step != null and @intFromPtr(step) < @intFromPtr(endOfCurrentProgram) and !isAtEndOfProgram(step) and !isAtEndOfPrograms(step)) {
        const nextStep = findNextStep(step);

        const op = structOpOfStep(step);

        if (op == ITM_FORx or op == ITM_NEXTx or op == ITM_FORYXx or op == ITM_FORTOPx) { // VALID has not passed this structure, so the program can be neither stored nor run
            return 1;
        }
        if (structOpHasNumber(op) != 0 and nextStep != null and (nextStep - step) >= 3 and !structNumberIsValid(step[2])) {
            return 1;
        }
        step = nextStep;
    }
    return 0;
}

// A paused run owns the program pointer: it is where R/S resumes. VALID reads the program
// and must leave that alone, so it only moves the editor when no run is waiting.
fn structMayMoveThePointer() bool {
    return programRunStop == PGM_STOPPED;
}

// Put the editor on this step, the same way goToGlobalStep() does, so the listing scrolls
// to it and the cursor lands on it rather than on the header.
fn structGoToLocalStep(localStepNumber: u16) void {
    currentLocalStepNumber = localStepNumber;
    defineCurrentStep();
    firstDisplayedLocalStepNumber = if (localStepNumber >= 3) localStepNumber - 3 else 0; // 0 is what keeps the program header line on screen, as GTO does
    defineFirstDisplayedStep();
    pemCursorIsZerothStep = 0;
}

// The commands that leave a test answer for the step after them, which is what an IF or a
// WHILE reads. They are every item a program can hold whose function leaves
// temporaryInformation at TI_TRUE or TI_FALSE. A new test command has to be added here as
// well.
const structTest linksection(code_section) = [_]i16{
    5,    6,    7,    8,    9,    10,
    11,   12,   13,   14,   15,   16,
    17,   18,   19,   2850, 2851, 20,
    21,   396,  397,  398,  399,  400,
    401,  405,  406,  22,   23,   24,
    25,   2398, 2400, 28,   30,   32,
    33,   2399, 29,   26,   31,   27,
    2524, 2525, 113,  2715, 2531, 2532,
    2527, 2528, 2529, 2530, 2396, 2397,
    2401, 1504, 2526, 1503, 34,   57,
    77,   56,
};

// True when the item leaves a test answer.
fn structOpIsTest(op: u16) bool {
    for (structTest) |item| {
        if (op == @as(u16, @bitCast(item))) {
            return true;
        }
    }
    return false;
}

// Put the editor on the step VALID is reporting and raise the message, so the program
// opens where the fault is with that step in view.
fn structReportFault(localStepNumber: u16, err: u8) void {
    if (structMayMoveThePointer()) {
        structGoToLocalStep(localStepNumber);
    }
    temporaryInformation = TI_NO_INFO; // a pending test display would otherwise cover the message
    displayCalcErrorMessage(err, ERR_REGISTER_LINE, REGISTER_X);
}

inline fn faultDetail(localStepNumber: u16, detail: [*:0]const u8) void {
    if (comptime extra_info) {
        _ = sprintf(errorMessage, "step %u:", @as(c_uint, localStepNumber));
        moreInfoOnError("In function structWalkProgram:", errorMessage, detail, null);
    }
}

// One walk of the open program, from its first step to its END. It checks the structures
// and, on the second call, numbers them: every structure gets its own number, in the order
// the openers appear, IF and DO in two series of their own. A fault stops the walk with
// the editor on the offending step, and nothing is numbered, because the checking call
// always runs first. A stopAt walks to that step instead of to the END, which is where a
// keyed END would put one.
fn structWalkProgram(numbering: bool, stopAt: [*c]const u8) bool {
    var step = beginOfCurrentProgram;
    var localStepNumber: u16 = 1;
    var depth: u16 = 0;
    var forDepth: u16 = 0;
    var previousOp: u16 = 0;
    var previousStepOp: u16 = 0;
    var ifNext: u16 = 0;
    var doNext: u16 = 0;
    var repeatNext: u16 = 0;
    var forSeen = false; // a FOR has taken local registers of its own in this routine, so no LocR may set the count after it
    var firstForStep: [*c]u8 = null; // that first FOR, which is what a LocR after it would rob

    while (step != null and (stopAt == null or @intFromPtr(step) < @intFromPtr(stopAt)) and
        @intFromPtr(step) < @intFromPtr(endOfCurrentProgram) and !isAtEndOfProgram(step) and !isAtEndOfPrograms(step))
    {
        const op = structPlainOp(structOpOfStep(step)); // a step VALID marked last time is checked again as the structure it is
        const nextStep = findNextStep(step);

        // A label after a return starts the next routine, with any number of REMs between
        // the two. A structure still open there would close in a routine of its own, which
        // no jump could pair with its opener, so it is flagged as crossed and refused when
        // its closer is reached.
        // The counters run on: they never issue a number twice, so a routine's numbers are
        // its own without a step at the boundary.
        if (op == ITM_LBL and (previousOp == ITM_RTN or previousOp == ITM_RTNP1)) {
            forSeen = false; // the next routine declares its own local registers from the start
            var open: u16 = 0;
            while (open < depth) : (open += 1) {
                structOpenCrossed[open] = true;
            }
        }

        // The step before an IF, a WHILE or an UNTIL has to leave a test answer. Nothing
        // stands between the two, so this reads the step itself and not the last step that
        // was not a REM.
        if ((op == ITM_IF or op == ITM_WHILE or op == ITM_UNTIL) and !structOpIsTest(previousStepOp)) {
            structClearProgramNumbers(); // the step keyed above the test is neither numbered nor a FOR, so nothing else takes the numbers off
            structReportFault(localStepNumber, ERROR_IF_WHILE_CONDITION_MISSING);
            faultDetail(localStepNumber, "the step above this IF, WHILE or UNTIL is not a test");
            return false;
        }

        // A FOR takes two local registers at the top of its level and a NEXT reads them
        // back. LocR and PopLR set the count outright, so either of them after the first FOR
        // of the routine would take that pair away. The routine declares what it needs
        // before its first FOR, and the count is left alone after.
        if (op == ITM_FOR) {
            if (!forSeen) {
                firstForStep = step;
            }
            forSeen = true;
        } else if (forSeen and (op == ITM_LocR or op == ITM_POPLR)) {
            structMarkNotChecked(firstForStep); // the LocR is the offending step, but the FOR whose registers it would take is what must not run
            structReportFault(localStepNumber, ERROR_STRUCTURE_INVALID);
            faultDetail(localStepNumber, "this LocR or PopLR comes below a FOR of the same routine, and a jump can put the run back inside that loop");
            return false;
        }

        // FOR and NEXT go on the same stack as IF and DO, so a structure crossing another is
        // caught wherever the crossing happens. They take no number: the counter pairs them,
        // and the counter written on the NEXT has to be the one written on the FOR it closes.
        if (op == ITM_FOR) {
            if (depth >= STRUCT_MAX_NESTING or forDepth >= FOR_MAX_LOOPS) { // more FOR structures inside one another than the table has rows could never all run
                structReportFault(localStepNumber, ERROR_NESTING_TOO_DEEP);
                faultDetail(localStepNumber, if (depth >= STRUCT_MAX_NESTING)
                    @as([*:0]const u8, "this FOR passes STRUCT_MAX_NESTING structures open at once")
                else
                    @as([*:0]const u8, "this FOR passes FOR_MAX_LOOPS FOR structures inside one another"));
                return false;
            }
            forDepth += 1;
            structOpenedBy[depth] = op;
            structOpenSawWhile[depth] = false;
            structOpenStepNumber[depth] = localStepNumber;
            structOpenCrossed[depth] = false;
            structOpenForStep[depth] = step;
            depth += 1;
        } else if (op == ITM_NEXT) {
            if (depth == 0 or structOpenedBy[depth - 1] != ITM_FOR) {
                structMarkNotChecked(step);
                structReportFault(localStepNumber, if (depth == 0) ERROR_NEXT_WITHOUT_FOR else ERROR_STRUCTURE_INVALID);
                faultDetail(localStepNumber, "this NEXT has no open FOR to close, and what is open here was opened by something else");
                return false;
            }
            if (!forStepsSameCounter(structOpenForStep[depth - 1], step)) {
                // a FOR and NEXT are paired by their common counter register. This NEXT's
                // counter is different from the open FOR, so it closes nothing and the FOR has
                // no NEXT.
                structMarkNotChecked(structOpenForStep[depth - 1]);
                structReportFault(structOpenStepNumber[depth - 1], ERROR_NEXT_NOT_FOUND);
                faultDetail(structOpenStepNumber[depth - 1], "the NEXT below this FOR counts in a different register, so this FOR has no matching NEXT");
                return false;
            }
            // the crossing test further down only reads steps with a partner number, and a FOR
            // and a NEXT have none, so this pair is tested here
            if (structOpenCrossed[depth - 1]) {
                // Marked before the report: a boundary between a FOR and its NEXT is neither a
                // numbered step nor a FOR, so nothing else takes the pair out of the passed form.
                structMarkNotChecked(structOpenForStep[depth - 1]);
                structMarkNotChecked(step);
                structReportFault(localStepNumber, ERROR_STRUCTURE_INVALID); // the NEXT is the offending step: the FOR above the boundary is written correctly
                faultDetail(localStepNumber, "the FOR this NEXT closes is in another routine, so nothing can pair them at run time");
                return false;
            }
            forDepth -= 1;
            depth -= 1;
        } else if (op == ITM_IF or op == ITM_DO or op == ITM_REPEAT) {
            if (depth >= STRUCT_MAX_NESTING) {
                structReportFault(localStepNumber, ERROR_NESTING_TOO_DEEP);
                faultDetail(localStepNumber, "this opener passes STRUCT_MAX_NESTING structures open at once");
                return false;
            }
            if ((if (op == ITM_IF) ifNext else if (op == ITM_DO) doNext else repeatNext) >= STRUCT_MAX_NUMBER) {
                structReportFault(localStepNumber, ERROR_STRUCTURE_INVALID);
                faultDetail(localStepNumber, "the partner numbers of this opener's family are used up at STRUCT_MAX_NUMBER");
                return false;
            }
            structOpenedBy[depth] = op;
            structOpenSawWhile[depth] = false;
            structOpenStepNumber[depth] = localStepNumber;
            structOpenCrossed[depth] = false;
            // every structure takes a number of its own, never one already used
            structOpenNumber[depth] = if (op == ITM_IF) blk: {
                ifNext += 1;
                break :blk ifNext;
            } else if (op == ITM_DO) blk: {
                doNext += 1;
                break :blk doNext;
            } else blk: {
                repeatNext += 1;
                break :blk repeatNext;
            };
            depth += 1;
        } else if (structOpHasNumber(op) != 0) {
            const opener: u16 = if (op == ITM_ELSE or op == ITM_ENDIF) ITM_IF else if (op == ITM_UNTIL) ITM_REPEAT else ITM_DO;

            if (depth == 0) {
                structReportFault(localStepNumber, ERROR_STRUCTURE_INVALID);
                faultDetail(localStepNumber, "this closer has no structure open above it");
                return false;
            }
            if (structOpenedBy[depth - 1] != opener) {
                structReportFault(localStepNumber, ERROR_STRUCTURE_INVALID);
                faultDetail(localStepNumber, "this closer does not match the structure it would close");
                return false;
            }
            if (op == ITM_WHILE) {
                structOpenSawWhile[depth - 1] = true;
            }
            if (op == ITM_ENDDO and !structOpenSawWhile[depth - 1]) { // a loop with no test never ends, so it is a fault and not a run to be started
                structReportFault(structOpenStepNumber[depth - 1], ERROR_STRUCTURE_INVALID);
                faultDetail(structOpenStepNumber[depth - 1], "this DO has no WHILE, so its loop could never end");
                return false;
            }
        }
        // A closer takes the number its opener was given. A routine boundary between the two
        // leaves nothing that can pair them at run time, so the structure is refused and the
        // editor lands on the step below the boundary, which is the one written wrongly.
        if (structOpHasNumber(op) != 0 and depth > 0) {
            const level = depth - 1;

            if (structOpenCrossed[level] and op != ITM_IF and op != ITM_DO and op != ITM_REPEAT) {
                structClearProgramNumbers(); // numbers left in place would leave the program storable, exportable and runnable
                structReportFault(localStepNumber, ERROR_STRUCTURE_INVALID); // this step is the offending one: the opener above the boundary is written correctly
                faultDetail(localStepNumber, "the structure this step belongs to was opened in another routine");
                return false;
            }
            // The number is the step's third byte. A step damaged shorter than that is left
            // alone: writing it would land on the step after, or on the END.
            if (numbering and nextStep != null and (nextStep - step) >= 3) {
                step[2] = @truncate(structOpenNumber[level]);
            }
        }
        if (op == ITM_ENDIF or op == ITM_ENDDO or op == ITM_UNTIL) {
            depth -= 1;
        }
        previousStepOp = op;
        if (op != ITM_REM) { // a REM is transparent to the routine boundary, and to nothing else
            previousOp = op;
        }
        step = nextStep;
        localStepNumber +%= 1;
    }

    if (depth > 0) {
        // The innermost one still open. A FOR reaching the END with no NEXT is that message
        // rather than the general one, and the cursor lands on the FOR.
        if (structOpenedBy[depth - 1] == ITM_FOR) {
            structMarkNotChecked(structOpenForStep[depth - 1]);
        }
        structReportFault(structOpenStepNumber[depth - 1], if (structOpenedBy[depth - 1] == ITM_FOR) ERROR_NEXT_NOT_FOUND else ERROR_STRUCTURE_INVALID);
        faultDetail(structOpenStepNumber[depth - 1], "this structure reaches the END of the program still open");
        return false;
    }
    if (numbering) { // the checking call passed, so nothing here is marked any more
        structClearMarks();
    }
    return true;
}

// Numbers the structures of the open program and reports the first fault. It is not
// programmable: it edits the program.
pub export fn fnValid(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (comptime !option_structured_pgm) return structNotHere();
    defineCurrentProgramFromCurrentStep();
    if (!structWalkProgram(false, null)) {
        return;
    }
    const editedStep = currentLocalStepNumber; // VALID numbers the program and leaves the editor exactly as it found it,
    const editedFirst = firstDisplayedLocalStepNumber; // the step under the cursor and the step at the top of the window both
    const editedZeroth = pemCursorIsZerothStep;

    _ = structWalkProgram(true, null); // the checking call above passed, so this one cannot fault
    if (structMayMoveThePointer()) {
        currentLocalStepNumber = editedStep;
        defineCurrentStep();
        firstDisplayedLocalStepNumber = editedFirst;
        defineFirstDisplayedStep();
        pemCursorIsZerothStep = editedZeroth;
    }
    temporaryInformation = TI_NO_INFO;
}

// True when the steps above the cursor check out as a program by themselves. An END keyed
// there splits the program in two and the editor follows the second half, so AVALID
// reaches that one on the way out; the first half is left behind and nothing else would
// ever check it.
pub export fn structEndSplitsWell() callconv(.c) bool_t {
    if (comptime !option_structured_pgm) return 1; // nothing checks a split without VALID, so nothing holds the END back
    defineCurrentProgramFromCurrentStep();
    return @intFromBool(structWalkProgram(false, currentStep));
}

// CLSTRUC leaves every structure that is open and every subroutine that has not returned,
// stops the run, and puts the step pointer at the top of the program. Nothing of the run
// is left: no loop holds a row or a pair of local registers, no level holds its locals,
// and the ! icon goes with the paused state. The partner numbers of that program go back
// to 0 and its FOR and NEXT steps back to the marked form, so VALID allocates the numbers
// again before the program can be stored or run.
pub export fn fnClearStructures(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (comptime !option_structured_pgm) return structNotHere();
    const theProgram = currentProgramNumber;

    forClearLoops();
    while (currentSubroutineLevel() > 0) { // the same unwind fnClP makes before it deletes a program, and for the same reason
        fnReturn(0);
    }
    cleanLocalFlagsAndRegisters(); // the level the run started in gives up its locals, all fnReturn does at level 0 beyond a step position goToPgmStep sets below
    programRunStop = PGM_STOPPED; // a paused or running program is stopped, and the ! icon goes with PGM_WAITING
    goToPgmStep(theProgram, 1);
    pemCursorIsZerothStep = 1; // the editor draws step 0000 from this, so the listing opens at the top by either route
    defineCurrentProgramFromCurrentStep(); // the two calls below read the open program, which the step above has just settled
    structClearProgramNumbers();
    forClearChecked();
    temporaryInformation = TI_NO_INFO;
}
