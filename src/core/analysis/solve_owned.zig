// SPDX-License-Identifier: GPL-3.0-only
const consts = abi.constants;
//
// Zig owner for src/c47/solver/solve.c: the central generic equation solver
// (Brent + optional Newton, OPTION_TVM_FORMULAS / OPTION_TVM_NEWTON both ON).
// Transitively COVERED via tvm.txt / validate_tvm (solver() is exercised by the
// TVM application). Faithful line-by-line translation preserving the exact order
// of every real_t / real34_t operation.
//
// Exports the real-name public symbols referenced cross-file: solver (C int;
// tvm/sumprod/integrate extern it), fnSolve, fnSolveVar. fnPgmSlv is NOT defined
// here (solve.zig's dispatcher owns it; the renamed z47_solver_fnPgmSlv is dead).
// The static helpers (_executeSolver, _executeSolverReal, _linearInterpolation,
// _inverseQuadraticInterpolation, _showProgress) stay private.
//
// SOLVERDEBUG/SOLVERDEBUG2 and the PC_BUILD printf blocks are #undef'd under
// TESTSUITE_BUILD and omitted. ENABLE_SOLVER_PROGRESS _showProgress is reduced
// to a no-op (no effect on the computed result; underlying flow preserved).
// EXTRA_INFO_ON_CALC_ERROR sprintf hints are stripped under TESTSUITE/DMCP and
// omitted. ctxtSolver/ctxtSolverHi == ctxtReal39; solverTvmTol=34, solverTvmZer=35.

const runtime = @import("solve_runtime.zig");
const solve_build_options = @import("solve_build_options");
const dmcp_build: bool = solve_build_options.is_dmcp_build;
const old_hw: bool = solve_build_options.is_old_hw;

// DECNUMDIGITS=75, DECDPUN=3 => DECNUMUNITS=ceil(75/3)=25; decNumberUnit=u16.
const abi = @import("abi"); // shared ABI bindings
const equation = @import("equation.zig");
const solve = @import("solve.zig");
const tvm = @import("tvm.zig");
const real_t = abi.Real;
const real34_t = abi.Real34;
const realContext_t = abi.RealContext;

const calcRegister_t = runtime.calcRegister_t;
const bool_t = bool;

// ---------------------------------------------------------------------------
// defines.h values (verified)
// ---------------------------------------------------------------------------
const FIRST_LABEL: u16 = 2200; // INVALID_VARIABLE=2199 precedes FIRST_LABEL; the //2044 C comment is stale
const LAST_LABEL: u16 = 6999;
const INVALID_VARIABLE: u16 = 2199;
const FIRST_NAMED_VARIABLE: u16 = 256;
const LAST_NAMED_VARIABLE: u16 = 1999;

const REGISTER_X: calcRegister_t = 100;
const REGISTER_Y: calcRegister_t = 101;
const REGISTER_Z: calcRegister_t = 102;
const REGISTER_T: calcRegister_t = 103;
const REGISTER_K: calcRegister_t = 111;
const ERR_REGISTER_LINE: calcRegister_t = REGISTER_Z;
const NIM_REGISTER_LINE: calcRegister_t = REGISTER_X;

const RESERVED_VARIABLE_FV: u16 = 2034;
const RESERVED_VARIABLE_IPONA: u16 = 2035;
const RESERVED_VARIABLE_NPPER: u16 = 2036;
const RESERVED_VARIABLE_PMT: u16 = 2038;
const RESERVED_VARIABLE_PV: u16 = 2039;
const FIRST_RESERVED_VARIABLE: u16 = 2000; // = LAST_NAMED_VARIABLE(1999)+1; 2029 was RESERVED_VARIABLE_SPARE4

const ERROR_NONE: u8 = 0;
const ERROR_OVERFLOW_PLUS_INF: u8 = 4;
const ERROR_OVERFLOW_MINUS_INF: u8 = 5;
const ERROR_LABEL_NOT_FOUND: u8 = 6;
const ERROR_OUT_OF_RANGE: u8 = 8;
const ERROR_INVALID_DATA_TYPE_FOR_OP: u8 = 24;
const ERROR_NO_ROOT_FOUND: u8 = 20;
const ERROR_LARGE_DELTA_AND_OPPOSITE_SIGN: u8 = 41;
const ERROR_SOLVER_REACHED_LOCAL_EXTREMUM: u8 = 42;
const ERROR_INITIAL_GUESS_OUT_OF_DOMAIN: u8 = 43;
const ERROR_FUNCTION_VALUES_LOOK_CONSTANT: u8 = 44;
const ERROR_NO_PROGRAM_SPECIFIED: u8 = 54;
const ERROR_SOLVER_ABORT: u8 = 60;
const ERROR_RAM_FULL: u8 = 11;

// Total PLOT, INT and SOLVE engines that may run at once, in any combination, counted by
// engineNestingDepth: OLD_HW (DM42) 2, NEW_HW (DM42n/DMCP5) 3, host 4.
// OLD_HW dropped 2 -> 1 at the 6559a9c59 pin: the DM42's measured stack use
// leaves it the least room, and the same pin moved the solvers' working reals
// off the frame for the same reason.
const MAX_ENGINE_NESTING_DEPTH: u16 = if (dmcp_build and old_hw) 1 else if (dmcp_build) 3 else 4;
// Whether INT or SOLVE may run inside a plot: 0 (false) on OLD_HW, 1 (true) otherwise.
const PLOT_NESTING_ALLOWED: bool = !(dmcp_build and old_hw);
const PGM_WAITING: u8 = 2;

const FLAG_ASLIFT: u32 = 0xc023;
const FLAG_INTING: u32 = 0xc025;
const FLAG_SOLVING: u32 = 0xc026;

const dtReal34: u32 = 1;
const dtComplex34: u32 = 2;
const dtString: u32 = 5;
const amNone: u32 = 5;
const NOPARAM: u16 = 9876;

const SOLVER_STATUS_READY_TO_EXECUTE: u16 = 0x0001;
const SOLVER_STATUS_INTERACTIVE: u16 = 0x0002;
const SOLVER_STATUS_EQUATION_MODE: u16 = 0x200c;
const SOLVER_STATUS_EQUATION_1ST_DERIVATIVE: u16 = 0x0008;
const SOLVER_STATUS_EQUATION_2ND_DERIVATIVE: u16 = 0x000C;
const SOLVER_STATUS_USES_FORMULA: u16 = 0x0100;
const SOLVER_STATUS_TVM_APPLICATION: u16 = 0x1000;

const SOLVER_RESULT_NORMAL: c_int = 0;
const SOLVER_RESULT_SIGN_REVERSAL: c_int = 1;
const SOLVER_RESULT_EXTREMUM: c_int = 2;
const SOLVER_RESULT_BAD_GUESS: c_int = 3;
const SOLVER_RESULT_CONSTANT: c_int = 4;
const SOLVER_RESULT_OTHER_FAILURE: c_int = 5;
const SOLVER_RESULT_ABORTED: c_int = 6;

const TI_SOLVER_VARIABLE: u8 = 51;
const TI_SOLVER_FAILED: u8 = 52;
const TI_SOLVER_VARIABLE_RESULT: u8 = 110;

const ITM_STO: i16 = 44;
const ITM_SOLVE: i16 = 1608;

const REAL_SOLVER: u8 = 106; // status-message code passed to errorMessageOf

const SCRUPD_MANUAL_MENU: u8 = 0x04;

const force: u8 = 1;
const timed: u8 = 0;
const halfSec_clearZ: bool = true;
const halfSec_clearT: bool = true;
const halfSec_disp: bool = true;

// solverTvmTol/solverTvmZer from solve.c (#define)
const solverTvmTol: i32 = 34;
const solverTvmZer: i32 = solverTvmTol + 1;

// ---------------------------------------------------------------------------
// Globals
// ---------------------------------------------------------------------------
extern var lastErrorCode: u8;
extern var varMenu42: bool; // c47.c globals (42S MVAR alpha-register routing)
extern var alphaRegister: u16;
extern var temporaryInformation: u8;
extern var programRunStop: u8;
extern var currentKeyCode: u8;
extern var dynamicMenuItem: i16;
extern var currentSolverNestingDepth: u16;
extern var engineNestingDepth: u16;
extern var plotEngineActive: u16;
extern var engineNestingWasRefused: bool;
extern var thereIsSomethingToUndo: bool;
extern var currentSolverStatus: u16;
extern var currentSolverProgram: u16;
extern var currentSolverVariable: u16;
extern var currentMvarLabel: u16;
extern var currentFormula: u16;
extern var numberOfLabels: u16;
extern var significantDigits: u8;
extern var screenUpdatingMode: u8;
extern var entryStatus: u8;
extern var errorMessage: [*c]u8;
extern var tmpString: [*c]u8;

extern var ctxtReal4: realContext_t;
extern var ctxtReal34: realContext_t;
extern var ctxtReal39: realContext_t;

// Context aliases (solve.c #define ctxtSolver ctxtReal39, ctxtSolverHi ctxtReal39)
inline fn ctxtSolver() *realContext_t {
    return &ctxtReal39;
}
inline fn ctxtSolverHi() *realContext_t {
    return &ctxtReal39;
}

// Upstream packed the fixed-width errorMessages[N][M] 2D array into a static pool
// reached through this accessor (error.c), so the array symbol no longer exists;
// errorMessageOf(code) returns the message pointer for one error/status code.
extern fn errorMessageOf(errorCode: u8) [*c]const u8;

// softmenu globals
const dynamicSoftmenu_t = abi.DynamicSoftmenu;
const softmenuStack_t = abi.SoftmenuStack;
// C `dynamicSoftmenu[N]` / `softmenuStack[N]` are ARRAYS: the symbol address IS
// the data. `extern var x: [*]T` loads the array's first 8 bytes AS the pointer
// -> dynamicSoftmenu[softmenuStack[0].softmenuId] dereferenced garbage
// and crashed in fnSolveVar (the grapher/solver variable path). Bind the array
// address like the frontier owners.
const dynamicSoftmenu = @extern([*c]dynamicSoftmenu_t, .{ .name = "dynamicSoftmenu" });
// softmenus.c owns the "is the top of the stack a dynamic softmenu" test; taking
// it here rather than re-deriving it keeps one owner for the rule.
extern fn currentDynamicSoftmenu() ?*dynamicSoftmenu_t;
const softmenuStack = @extern([*c]softmenuStack_t, .{ .name = "softmenuStack" });

// ---------------------------------------------------------------------------
// Constants blob accessors (offsets verified vs generated constantPointers.h)
// ---------------------------------------------------------------------------

inline fn const_NaN() *align(1) const real_t {
    return consts.c812();
}
inline fn const_minusInfinity() *align(1) const real_t {
    return consts.c1684();
}
inline fn const_plusInfinity() *align(1) const real_t {
    return consts.c1696();
}
inline fn const_1on2() *align(1) const real_t {
    return consts.c4580();
}
inline fn const_1() *align(1) const real_t {
    return consts.c4856();
}
inline fn const_2() *align(1) const real_t {
    return consts.c4928();
}
inline fn const_1e_16() *align(1) const real_t {
    return consts.c4484();
}
inline fn const_1e_32() *align(1) const real_t {
    return consts.c5708();
}
inline fn const_100() *align(1) const real_t {
    return consts.c7532();
}
inline fn const34_153() *align(1) const real34_t {
    return consts.q16568();
}

// ---------------------------------------------------------------------------
// decNumber primitives / real_t macro reproductions
// ---------------------------------------------------------------------------
extern fn decNumberCopy(res: *real_t, source: *align(1) const real_t) *real_t;
extern fn decNumberAdd(res: *real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberSubtract(res: *real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberMultiply(res: *real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberDivide(res: *real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberFMA(res: *real_t, f1: *align(1) const real_t, f2: *align(1) const real_t, term: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberFromString(res: *real_t, source: [*:0]const u8, ctxt: *realContext_t) *real_t;

// decNumberIsZero macro (DECSPECIAL = 0x70)
inline fn decNumberIsZero(dn: *align(1) const real_t) bool {
    return dn.lsu[0] == 0 and dn.digits == 1 and (dn.bits & 0x70) == 0;
}

inline fn realCopy(source: *align(1) const real_t, destination: *real_t) void {
    _ = decNumberCopy(destination, source);
}
inline fn realAdd(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberAdd(res, op1, op2, ctxt);
}
inline fn realSubtract(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberSubtract(res, op1, op2, ctxt);
}
inline fn realMultiply(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberMultiply(res, op1, op2, ctxt);
}
inline fn realDivide(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberDivide(res, op1, op2, ctxt);
}
inline fn realFMA(f1: *align(1) const real_t, f2: *align(1) const real_t, term: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberFMA(res, f1, f2, term, ctxt);
}
inline fn stringToReal(source: [*:0]const u8, destination: *real_t, ctxt: *realContext_t) void {
    _ = decNumberFromString(destination, source, ctxt);
}
inline fn realChangeSign(operand: *real_t) void {
    operand.bits ^= 0x80;
}
inline fn realSetNegativeSign(operand: *real_t) void {
    operand.bits |= 0x80;
}
inline fn realSetPositiveSign(operand: *real_t) void {
    operand.bits &= 0x7F;
}
inline fn realIsZero(source: *align(1) const real_t) bool {
    return decNumberIsZero(source);
}
inline fn realIsNegative(source: *align(1) const real_t) bool {
    return (source.bits & 0x80) == 0x80;
}
inline fn realIsSpecial(source: *align(1) const real_t) bool {
    return (source.bits & 0x70) != 0;
}
inline fn realIsInfinite(source: *align(1) const real_t) bool {
    return (source.bits & 0x40) != 0;
}

extern fn realSetOne(value: *real_t) void;
extern fn realSetZero(value: *real_t) void;
extern fn realSetNaN(value: *real_t) void;
extern fn realCompareEqual(number1: *align(1) const real_t, number2: *align(1) const real_t) bool;
extern fn realCompareLessThan(number1: *align(1) const real_t, number2: *align(1) const real_t) bool;
extern fn realCompareAbsLessThan(number1: *align(1) const real_t, number2: *align(1) const real_t) bool;
extern fn realGetExponentComp(val: *const real_t) i32;
extern fn convergenceTolerence(tol: *real_t) void;
extern fn WP34S_RelativeError(x: *align(1) const real_t, y: *align(1) const real_t, tol: *align(1) const real_t, ctxt: *realContext_t) bool;

// ---------------------------------------------------------------------------
// real34_t macro reproductions
// ---------------------------------------------------------------------------
extern fn decimal128ToNumber(source: *align(1) const real34_t, destination: *real_t) *real_t;
extern fn decimal128FromNumber(dest: *align(1) real34_t, src: *align(1) const real_t, ctxt: *realContext_t) *align(1) real34_t;
extern fn decQuadSubtract(res: *align(1) real34_t, op1: *align(1) const real34_t, op2: *align(1) const real34_t, ctxt: *realContext_t) *align(1) real34_t;
extern fn decQuadMultiply(res: *align(1) real34_t, op1: *align(1) const real34_t, op2: *align(1) const real34_t, ctxt: *realContext_t) *align(1) real34_t;
extern fn decQuadFromInt32(dest: *align(1) real34_t, source: i32) *align(1) real34_t;
extern fn decQuadZero(dest: *align(1) real34_t) *align(1) real34_t;
extern fn decQuadIsZero(source: *align(1) const real34_t) bool;
extern fn decQuadIsInfinite(source: *align(1) const real34_t) bool;
extern fn decQuadMinus(res: *align(1) real34_t, operand: *align(1) const real34_t, ctxt: *realContext_t) *align(1) real34_t;
extern fn decQuadNextPlus(res: *align(1) real34_t, operand: *align(1) const real34_t, ctxt: *realContext_t) *align(1) real34_t;
extern fn decQuadNextMinus(res: *align(1) real34_t, operand: *align(1) const real34_t, ctxt: *realContext_t) *align(1) real34_t;

inline fn real34ToReal(source: *align(1) const real34_t, destination: *real_t) void {
    _ = decimal128ToNumber(source, destination);
}
inline fn realToReal34(source: *align(1) const real_t, destination: *align(1) real34_t) void {
    _ = decimal128FromNumber(destination, source, &ctxtReal34);
}
inline fn real34Copy(source: *align(1) const real34_t, destination: *align(1) real34_t) void {
    const src: *align(1) const [2]u64 = @ptrCast(source);
    const dst: *align(1) [2]u64 = @ptrCast(destination);
    dst[0] = src[0];
    dst[1] = src[1];
}
inline fn real34Subtract(op1: *align(1) const real34_t, op2: *align(1) const real34_t, res: *align(1) real34_t) void {
    _ = decQuadSubtract(res, op1, op2, &ctxtReal34);
}
inline fn real34Multiply(op1: *align(1) const real34_t, op2: *align(1) const real34_t, res: *align(1) real34_t) void {
    _ = decQuadMultiply(res, op1, op2, &ctxtReal34);
}
inline fn real34SetZero(destination: *align(1) real34_t) void {
    _ = decQuadZero(destination);
}
inline fn real34IsZero(source: *align(1) const real34_t) bool {
    return decQuadIsZero(source);
}
inline fn real34IsInfinite(source: *align(1) const real34_t) bool {
    return decQuadIsInfinite(source);
}
inline fn real34ChangeSign(operand: *align(1) real34_t) void {
    operand.bytes[15] ^= 0x80;
}
inline fn real34Minus(operand: *align(1) const real34_t, res: *align(1) real34_t) void {
    _ = decQuadMinus(res, operand, &ctxtReal34);
}
inline fn real34NextPlus(operand: *align(1) const real34_t, res: *align(1) real34_t) void {
    _ = decQuadNextPlus(res, operand, &ctxtReal34);
}
inline fn real34NextMinus(operand: *align(1) const real34_t, res: *align(1) real34_t) void {
    _ = decQuadNextMinus(res, operand, &ctxtReal34);
}
inline fn int32ToReal34(source: i32, destination: *align(1) real34_t) void {
    _ = decQuadFromInt32(destination, source);
}

inline fn real34IsPositive(source: *align(1) const real34_t) bool {
    return (source.bytes[15] & 0x80) == 0x00;
}
extern fn real34CompareEqual(number1: *align(1) const real34_t, number2: *align(1) const real34_t) bool;

// ---------------------------------------------------------------------------
// Register / stack / program externs
// ---------------------------------------------------------------------------
extern fn getRegisterDataPointer(reg: calcRegister_t) ?*anyopaque;
const registerReal34Ptr = abi.registerReal34;
const registerImag34Ptr = abi.registerImag34;
const registerStringPtr = abi.registerString;
const STR_LGINT_HEADER_SIZE: usize = 4; // sizeof(strLgIntHeader_t)

extern fn getRegisterDataType(reg: calcRegister_t) u32;
extern fn reallocateRegister(regist: calcRegister_t, data_type: u32, data_len: u32, tag: u32) void;
extern fn clearRegister(regist: calcRegister_t) void;
extern fn convertRealToReal34ResultRegister(real: *const real_t, dest: calcRegister_t) void;
extern fn copySourceRegisterToDestRegister(rSource: calcRegister_t, rDest: calcRegister_t) void;
extern fn getRegisterAsReal34Quiet(reg: calcRegister_t, val: *align(1) real34_t) bool;

extern fn getSystemFlag(sf: i32) bool;
extern fn setSystemFlag(sf: c_uint) void;
extern fn clearSystemFlag(sf: c_uint) void;
extern fn saveForUndo() void;
extern fn liftStack() void;
extern fn fnToReal(unused: u16) void;
extern fn fnDrop(unused: u16) void;
extern fn fnFillStack(unused: u16) void;
extern fn fnUndo(unused: u16) void;
extern fn execProgram(label: u16) void;
extern fn reallyRunFunction(func: i16, param: u16) void;
extern fn runProgram(singleStep: bool, menuLabel: u16) void;
extern fn runFunction(item: i16) void;
extern fn adjustResult(res: calcRegister_t, drop_y: bool, set_cpx_res: bool, op1: calcRegister_t, op2: calcRegister_t, op3: calcRegister_t) void;
extern fn displayCalcErrorMessage(error_code: u8, err_message_register_line: calcRegister_t, err_register_line: calcRegister_t) void;
extern fn findNamedLabel(label_name: [*:0]const u8, label_type: u8) calcRegister_t;
extern fn findOrAllocateNamedVariable(variableName: [*:0]const u8) calcRegister_t;
extern fn letteredRegisterName(regist: calcRegister_t) u8;
const refreshScreen = abi.host.requestRefresh; // routed through the host-callback boundary
extern fn showSoftmenu(id: i16) void;
extern fn printStatus(row: u8, line1: [*c]const u8, forced: u8) void;
extern fn getNthString(ptr: [*c]u8, n: i16) [*c]u8;
// exitKeyWaiting now routes through the host-callback boundary (abi.host),
// severing the direct engine->shell link; it reports "no abort" when headless.
const exitKeyWaiting = abi.host.exitKeyWaiting;
const checkHalfSec = abi.host.checkHalfSec; // routed through the host-callback boundary
const progressHalfSecUpdate_Integer = abi.host.progressHalfSecUpdate_Integer; // routed through the host-callback boundary

// libc helpers
extern fn strlen(s: [*c]const u8) usize;
extern fn xcopy(dest: ?*anyopaque, source: ?*const anyopaque, n: u32) ?*anyopaque;
inline fn stringByteLength(s: [*c]const u8) i32 {
    return @intCast(strlen(s));
}
inline fn TO_BLOCKS(n: u32) u16 {
    return @intCast((n + 3) >> 2); // BYTES_PER_BLOCK=4, BPB=2
}

// tvm.c callback (defined in tvm.zig)

// ===========================================================================
// fnSolve
// ===========================================================================
// fnPgmSlv is owned by solve.zig (the dispatcher). We extern it here.

pub export fn fnSolve(labelOrVariable: u16) linksection(runtime.code_section) callconv(.c) void {
    if ((FIRST_LABEL <= labelOrVariable and labelOrVariable <= LAST_LABEL) or (REGISTER_X <= @as(calcRegister_t, @intCast(labelOrVariable)) and @as(calcRegister_t, @intCast(labelOrVariable)) <= REGISTER_T)) {
        // Interactive mode
        solve.fnPgmSlv(labelOrVariable);
        if (lastErrorCode == ERROR_NONE) {
            currentSolverStatus = SOLVER_STATUS_INTERACTIVE;
        }
        adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
    } else if ((currentSolverStatus & SOLVER_STATUS_USES_FORMULA) == 0 and (FIRST_NAMED_VARIABLE <= labelOrVariable and labelOrVariable <= LAST_NAMED_VARIABLE) and currentSolverProgram >= numberOfLabels) {
        displayCalcErrorMessage(ERROR_NO_PROGRAM_SPECIFIED, ERR_REGISTER_LINE, REGISTER_X);
        adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
    } else if (FIRST_NAMED_VARIABLE <= labelOrVariable and labelOrVariable <= LAST_NAMED_VARIABLE) {
        // Execute
        var z: real34_t = undefined;
        var y: real34_t = undefined;
        var x: real34_t = undefined;
        var tmp: real_t = undefined;
        var resultCode: c_int = 0;

        if (engineNestingRefused(false)) {
            return;
        }
        if (getRegisterAsReal34Quiet(REGISTER_Y, &y) and getRegisterAsReal34Quiet(REGISTER_X, &x)) {
            fnDrop(NOPARAM);
            fnDrop(NOPARAM);
            saveForUndo(); // repeat after dropping the input parameters
            currentSolverVariable = labelOrVariable;
            screenUpdatingMode &= ~SCRUPD_MANUAL_MENU;
            refreshScreen(0);
            resultCode = solver(@bitCast(labelOrVariable), &y, &x, &z, &y, &x);

            fnUndo(0);
            liftStack();
            setSystemFlag(FLAG_ASLIFT);
            liftStack();
            setSystemFlag(FLAG_ASLIFT);
            liftStack();
            setSystemFlag(FLAG_ASLIFT);
            liftStack();
            real34ToReal(&z, &tmp);
            convertRealToReal34ResultRegister(&tmp, REGISTER_Z);
            real34ToReal(&y, &tmp);
            convertRealToReal34ResultRegister(&tmp, REGISTER_Y);
            real34ToReal(&x, &tmp);
            convertRealToReal34ResultRegister(&tmp, REGISTER_X);
            int32ToReal34(resultCode, registerReal34Ptr(REGISTER_T));
            switch (resultCode) {
                SOLVER_RESULT_NORMAL => {
                    copySourceRegisterToDestRegister(REGISTER_X, @bitCast(labelOrVariable));
                    temporaryInformation = TI_SOLVER_VARIABLE_RESULT;
                    lastErrorCode = ERROR_NONE;
                },
                SOLVER_RESULT_SIGN_REVERSAL => {
                    temporaryInformation = TI_SOLVER_FAILED;
                    displayCalcErrorMessage(ERROR_LARGE_DELTA_AND_OPPOSITE_SIGN, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
                },
                SOLVER_RESULT_EXTREMUM => {
                    temporaryInformation = TI_SOLVER_FAILED;
                    displayCalcErrorMessage(ERROR_SOLVER_REACHED_LOCAL_EXTREMUM, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
                },
                SOLVER_RESULT_BAD_GUESS => {
                    temporaryInformation = TI_SOLVER_FAILED;
                    displayCalcErrorMessage(ERROR_INITIAL_GUESS_OUT_OF_DOMAIN, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
                },
                SOLVER_RESULT_CONSTANT => {
                    temporaryInformation = TI_SOLVER_FAILED;
                    displayCalcErrorMessage(ERROR_FUNCTION_VALUES_LOOK_CONSTANT, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
                },
                SOLVER_RESULT_OTHER_FAILURE => {
                    temporaryInformation = TI_SOLVER_FAILED;
                    displayCalcErrorMessage(ERROR_NO_ROOT_FOUND, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
                },
                SOLVER_RESULT_ABORTED => {
                    temporaryInformation = TI_SOLVER_FAILED;
                    displayCalcErrorMessage(ERROR_SOLVER_ABORT, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
                },
                else => {},
            }
            adjustResult(REGISTER_X, false, false, REGISTER_X, REGISTER_Y, -1);
        } else {
            displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
            adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
        }
    } else {
        displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
        adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
    }
}

// ===========================================================================
// fnSolveVar
// ===========================================================================
pub export fn fnSolveVar(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    printStatus(1, errorMessageOf(REAL_SOLVER), force);
    // The menu content is only there to read while the top of the softmenu stack
    // IS a dynamic softmenu; on a static one the id ranks in softmenu[] instead and
    // addresses past dynamicSoftmenu[].
    const dynamic = currentDynamicSoftmenu() orelse return;
    if (dynamicMenuItem < 0 or dynamicMenuItem >= dynamic.numItems) {
        return;
    }
    const variable_str: [*c]u8 = getNthString(dynamic.menuContent, dynamicMenuItem);
    const regist: u16 = @bitCast(@as(i16, @truncate(findOrAllocateNamedVariable(@ptrCast(variable_str)))));
    const nameLength: u16 = @intCast(stringByteLength(variable_str) + 1);
    if (currentMvarLabel != INVALID_VARIABLE) {
        if ((currentSolverStatus & SOLVER_STATUS_INTERACTIVE) != 0) { // MNU_MVAR was displayed by the Solver
            reallyRunFunction(ITM_STO, regist);
        } else { // MNU_MVAR was displayed by VARMNU
            if ((entryStatus & 0x01) != 0) { // MVAR menu key pressed after a user entry: save the value in the variable
                entryStatus &= 0xfe;
                currentSolverVariable = regist;
                reallyRunFunction(ITM_STO, regist);
                temporaryInformation = TI_SOLVER_VARIABLE;
            } else { // store the variable name in the alpha register (42S) or K, and continue program execution
                const alpha_register: calcRegister_t = if (varMenu42) @intCast(alphaRegister) else REGISTER_K;
                reallocateRegister(alpha_register, dtString, TO_BLOCKS(nameLength), amNone);
                _ = xcopy(registerStringPtr(alpha_register), variable_str, nameLength);
                dynamicMenuItem = -1;
                runProgram(false, INVALID_VARIABLE);
            }
        }
    } else if ((currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_1ST_DERIVATIVE or (currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_2ND_DERIVATIVE) {
        currentSolverVariable = regist;
        reallyRunFunction(ITM_STO, regist);
        temporaryInformation = TI_SOLVER_VARIABLE;
    } else if ((currentSolverStatus & SOLVER_STATUS_READY_TO_EXECUTE) != 0) {
        reallyRunFunction(ITM_SOLVE, regist);
    } else {
        currentSolverVariable = regist;
        reallyRunFunction(ITM_STO, regist);
        currentSolverStatus |= SOLVER_STATUS_READY_TO_EXECUTE;
        temporaryInformation = TI_SOLVER_VARIABLE;
    }
}

// ===========================================================================
// _executeSolver
// ===========================================================================
fn _executeSolver(variable: calcRegister_t, val: *align(1) const real34_t, res: *align(1) real34_t) linksection(runtime.code_section) void {
    reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
    real34Copy(val, registerReal34Ptr(REGISTER_X));
    if ((currentSolverStatus & SOLVER_STATUS_TVM_APPLICATION) != 0) {
        copySourceRegisterToDestRegister(REGISTER_X, variable);
    } else {
        reallyRunFunction(ITM_STO, @bitCast(variable));
        fnFillStack(NOPARAM);
    }
    if (lastErrorCode == ERROR_SOLVER_ABORT) {
        realToReal34(const_NaN(), res);
        return;
    }
    if ((currentSolverStatus & SOLVER_STATUS_USES_FORMULA) != 0) {
        equation.parseEquation(currentFormula, 1, tmpString, tmpString + 1024);
    } else {
        // also stack the variable + control flags so a nested SOLVE cannot leak
        // into the outer point (enables PLOT(SOLVE), SOLVE(SOLVE)). Saving only
        // the program left the outer engine reading whichever variable and
        // status the inner one finished with, so every later sample of the
        // outer sweep evaluated against the wrong target.
        const savedCurrentSolverProgram: u16 = currentSolverProgram;
        const savedCurrentSolverVariable: u16 = currentSolverVariable;
        const savedCurrentSolverStatus: u16 = currentSolverStatus;
        dynamicMenuItem = -1;
        execProgram(currentSolverProgram + FIRST_LABEL);
        currentSolverProgram = savedCurrentSolverProgram;
        currentSolverVariable = savedCurrentSolverVariable;
        currentSolverStatus = savedCurrentSolverStatus;
    }
    if (lastErrorCode == ERROR_OVERFLOW_PLUS_INF) {
        realToReal34(const_plusInfinity(), res);
        lastErrorCode = ERROR_NONE;
    } else if (lastErrorCode == ERROR_OVERFLOW_MINUS_INF) {
        realToReal34(const_minusInfinity(), res);
        lastErrorCode = ERROR_NONE;
    } else if (lastErrorCode != ERROR_NONE) {
        realToReal34(const_NaN(), res);
    } else if (getRegisterAsReal34Quiet(REGISTER_X, res)) {
        // ;
    } else if (getRegisterDataType(REGISTER_X) == dtComplex34 and real34IsZero(registerReal34Ptr(REGISTER_X))) {
        real34Copy(registerImag34Ptr(REGISTER_X), res);
        real34ChangeSign(res);
    } else {
        realToReal34(const_NaN(), res);
    }
}

pub fn _executeSolverReal(variable: calcRegister_t, val: *const real_t, res: *real_t, deriv: ?*real_t) linksection(runtime.code_section) void {
    if ((currentSolverStatus & SOLVER_STATUS_TVM_APPLICATION) != 0) {
        // pass real_t value via ioVal, result comes back in same variable as real_t
        realCopy(val, res);
        tvm.tvmEquation(variable, res, deriv);
    } else {
        var val34: real34_t = undefined;
        var res34: real34_t = undefined;
        realToReal34(val, &val34);
        _executeSolver(variable, &val34, &res34);
        real34ToReal(&res34, res);
    }
}

fn _linearInterpolation(a: *const real_t, b: *const real_t, fa: *const real_t, fb: *const real_t, res: ?*real_t, slope: ?*real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var amb: real_t = undefined;
    var famfb: real_t = undefined;
    realSubtract(a, b, &amb, realContext);
    realSubtract(fa, fb, &famfb, realContext);
    if (slope) |s| {
        realDivide(&famfb, &amb, s, realContext);
    }
    if (res) |r| {
        realDivide(&amb, &famfb, &amb, realContext);
        realMultiply(&amb, fb, &amb, realContext);
        realSubtract(b, &amb, r, realContext);
    }
}

fn _inverseQuadraticInterpolation(a: *const real_t, b: *const real_t, c: *const real_t, fa: *const real_t, fb: *const real_t, fc: *const real_t, res: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var val: real_t = undefined;
    var num: real_t = undefined;
    var den: real_t = undefined;
    var tmp: real_t = undefined;

    realMultiply(fb, fc, &num, realContext);
    realMultiply(&num, a, &num, realContext);
    realSubtract(fa, fb, &den, realContext);
    realSubtract(fa, fc, &tmp, realContext);
    realMultiply(&den, &tmp, &den, realContext);
    realDivide(&num, &den, &val, realContext);

    realMultiply(fa, fc, &num, realContext);
    realMultiply(&num, b, &num, realContext);
    realSubtract(fb, fa, &den, realContext);
    realSubtract(fb, fc, &tmp, realContext);
    realMultiply(&den, &tmp, &den, realContext);
    realDivide(const_1(), &den, &den, realContext);
    realFMA(&num, &den, &val, &val, realContext);

    realMultiply(fa, fb, &num, realContext);
    realMultiply(&num, c, &num, realContext);
    realSubtract(fc, fa, &den, realContext);
    realSubtract(fc, fb, &tmp, realContext);
    realMultiply(&den, &tmp, &den, realContext);
    realDivide(const_1(), &den, &den, realContext);
    realFMA(&num, &den, &val, res, realContext);
}

fn _showProgress(a: *align(1) const real34_t, b: *align(1) const real34_t, fa: *align(1) const real34_t, fb: *align(1) const real34_t) linksection(runtime.code_section) void {
    _ = a;
    _ = b;
    _ = fa;
    _ = fb;
}

// ===========================================================================
// engineNestingRefused
// ===========================================================================
// True when a further PLOT, INT or SOLVE may not start. INT and SOLVE nest to
// MAX_ENGINE_NESTING_DEPTH. PLOT runs only as the outermost engine, because the
// draw matrix DrwMX, its register regStatsXY and the screen are single, and
// where PLOT_NESTING_ALLOWED is false nothing at all runs inside a plot. Each
// engine calls this at its entry, ahead of that engine's own saveForUndo.
pub export fn engineNestingRefused(isPlot: bool) linksection(runtime.code_section) callconv(.c) bool {
    if (if (isPlot)
        engineNestingDepth == 0
    else
        engineNestingDepth < MAX_ENGINE_NESTING_DEPTH and (PLOT_NESTING_ALLOWED or plotEngineActive == 0))
    {
        engineNestingWasRefused = false;
        return false;
    }
    programRunStop = PGM_WAITING;
    thereIsSomethingToUndo = false;
    engineNestingWasRefused = true;
    return true;
}

// ===========================================================================
// solver (the central Brent+Newton root finder)
// ===========================================================================
const SOLVER_METHOD_BRENT: u8 = 0;
const SOLVER_METHOD_NEWTON: u8 = 1;

pub export fn solver(variable: calcRegister_t, y: *align(1) const real34_t, x: *align(1) const real34_t, resZ: *align(1) real34_t, resY: *align(1) real34_t, resX: *align(1) real34_t) linksection(runtime.code_section) callconv(.c) c_int {
    currentKeyCode = 255;

    // The working reals come from the heap, not the frame: thirty-seven decNumbers
    // at 60 bytes, and the frame stands for the whole solve while every evaluation of
    // the user program or formula runs below it. Upstream measured the DM42 frame
    // falling from 1952 bytes to 552. The reals that were declared inside the
    // iteration loop are taken here as well, so the loop allocates nothing; each is
    // still written before it is read on every pass. `defer` frees them on every
    // exit, which is what upstream's `goto freeWork` does for each of its returns.
    const newton_x_p = runtime.mallocReal();
    const prev_fx_p = runtime.mallocReal();
    const prev_x_p = runtime.mallocReal();
    const brent_best_x_p = runtime.mallocReal();
    const brent_best_fx_p = runtime.mallocReal();
    const aa_p = runtime.mallocReal();
    const bb_p = runtime.mallocReal();
    const bb1_p = runtime.mallocReal();
    const bb2_p = runtime.mallocReal();
    const faa_p = runtime.mallocReal();
    const fbb_p = runtime.mallocReal();
    const fbb1_p = runtime.mallocReal();
    const mm_p = runtime.mallocReal();
    const ss_p = runtime.mallocReal();
    const secantSlopeA_p = runtime.mallocReal();
    const secantSlopeB_p = runtime.mallocReal();
    const delta_p = runtime.mallocReal();
    const deltaB_p = runtime.mallocReal();
    const smb_p = runtime.mallocReal();
    const tol_p = runtime.mallocReal();
    const fbp1_p = runtime.mallocReal();
    const tmp_p = runtime.mallocReal();
    const tolAlmostZero_p = runtime.mallocReal();
    const minBracketSpacing_p = runtime.mallocReal();
    const prevResX_p = runtime.mallocReal();
    const antiLevel_p = runtime.mallocReal();
    const bracketWidth_p = runtime.mallocReal();
    const relativeWidth_p = runtime.mallocReal();
    const fullBracket_p = runtime.mallocReal();
    const newton_trial_p = runtime.mallocReal();
    const newton_fx_p = runtime.mallocReal();
    const newton_deriv_p = runtime.mallocReal();
    const newton_step_p = runtime.mallocReal();
    const tol_converged_p = runtime.mallocReal();
    const tol1_p = runtime.mallocReal();
    const resXr_p = runtime.mallocReal();
    const resZr_p = runtime.mallocReal();
    defer {
        runtime.freeReal(newton_x_p);
        runtime.freeReal(prev_fx_p);
        runtime.freeReal(prev_x_p);
        runtime.freeReal(brent_best_x_p);
        runtime.freeReal(brent_best_fx_p);
        runtime.freeReal(aa_p);
        runtime.freeReal(bb_p);
        runtime.freeReal(bb1_p);
        runtime.freeReal(bb2_p);
        runtime.freeReal(faa_p);
        runtime.freeReal(fbb_p);
        runtime.freeReal(fbb1_p);
        runtime.freeReal(mm_p);
        runtime.freeReal(ss_p);
        runtime.freeReal(secantSlopeA_p);
        runtime.freeReal(secantSlopeB_p);
        runtime.freeReal(delta_p);
        runtime.freeReal(deltaB_p);
        runtime.freeReal(smb_p);
        runtime.freeReal(tol_p);
        runtime.freeReal(fbp1_p);
        runtime.freeReal(tmp_p);
        runtime.freeReal(tolAlmostZero_p);
        runtime.freeReal(minBracketSpacing_p);
        runtime.freeReal(prevResX_p);
        runtime.freeReal(antiLevel_p);
        runtime.freeReal(bracketWidth_p);
        runtime.freeReal(relativeWidth_p);
        runtime.freeReal(fullBracket_p);
        runtime.freeReal(newton_trial_p);
        runtime.freeReal(newton_fx_p);
        runtime.freeReal(newton_deriv_p);
        runtime.freeReal(newton_step_p);
        runtime.freeReal(tol_converged_p);
        runtime.freeReal(tol1_p);
        runtime.freeReal(resXr_p);
        runtime.freeReal(resZr_p);
    }
    if (newton_x_p == null or prev_fx_p == null or prev_x_p == null or brent_best_x_p == null or brent_best_fx_p == null or aa_p == null or bb_p == null or bb1_p == null or bb2_p == null or faa_p == null or fbb_p == null or fbb1_p == null or mm_p == null or ss_p == null or secantSlopeA_p == null or secantSlopeB_p == null or delta_p == null or deltaB_p == null or smb_p == null or tol_p == null or fbp1_p == null or tmp_p == null or tolAlmostZero_p == null or minBracketSpacing_p == null or prevResX_p == null or antiLevel_p == null or bracketWidth_p == null or relativeWidth_p == null or fullBracket_p == null or newton_trial_p == null or newton_fx_p == null or newton_deriv_p == null or newton_step_p == null or tol_converged_p == null or tol1_p == null or resXr_p == null or resZr_p == null) {
        displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, REGISTER_X);
        return SOLVER_RESULT_OTHER_FAILURE;
    }
    const newton_x = newton_x_p.?;
    const prev_fx = prev_fx_p.?;
    const prev_x = prev_x_p.?;
    const brent_best_x = brent_best_x_p.?;
    const brent_best_fx = brent_best_fx_p.?;
    const aa = aa_p.?;
    const bb = bb_p.?;
    const bb1 = bb1_p.?;
    const bb2 = bb2_p.?;
    const faa = faa_p.?;
    const fbb = fbb_p.?;
    const fbb1 = fbb1_p.?;
    const mm = mm_p.?;
    const ss = ss_p.?;
    const secantSlopeA = secantSlopeA_p.?;
    const secantSlopeB = secantSlopeB_p.?;
    const delta = delta_p.?;
    const deltaB = deltaB_p.?;
    const smb = smb_p.?;
    const tol = tol_p.?;
    const fbp1 = fbp1_p.?;
    const tmp = tmp_p.?;
    const tolAlmostZero = tolAlmostZero_p.?;
    const minBracketSpacing = minBracketSpacing_p.?;
    const prevResX = prevResX_p.?;
    const antiLevel = antiLevel_p.?;
    const bracketWidth = bracketWidth_p.?;
    const relativeWidth = relativeWidth_p.?;
    const fullBracket = fullBracket_p.?;
    const newton_trial = newton_trial_p.?;
    const newton_fx = newton_fx_p.?;
    const newton_deriv = newton_deriv_p.?;
    const newton_step = newton_step_p.?;
    const tol_converged = tol_converged_p.?;
    const tol1 = tol1_p.?;
    const resXr = resXr_p.?;
    const resZr = resZr_p.?;

    var currentMethod: u8 = SOLVER_METHOD_BRENT;
    // OPTION_TVM_NEWTON state
    var newton_polish_mode: bool_t = false;
    var newton_polish_count: c_int = 0;
    var first_newton_iter: bool_t = true;
    var stall_count: c_int = 0;
    var newton_iter_count: c_int = 0;
    var newtonDisabled: bool_t = false;
    realSetNaN(brent_best_x);
    realSetNaN(brent_best_fx);
    var newtonInitialized: bool_t = false;

    var antiLevel34: real34_t = undefined;
    var bp1: *real_t = mm;
    var extendRange: bool_t = false;
    var originallyLevel: bool_t = false;
    var extremum: bool_t = false;
    var result: c_int = SOLVER_RESULT_NORMAL;
    const was_inting: bool_t = getSystemFlag(@bitCast(FLAG_INTING));
    var loop: c_int = 0;
    var getOutOfLevel: i16 = 17;
    var fbIsAlmostZero: bool_t = false;
    realSetNaN(prevResX);

    if ((currentSolverStatus & SOLVER_STATUS_TVM_APPLICATION) != 0) {
        realSetOne(tol);
        tol.exponent -= if (significantDigits == 0 or significantDigits == 34) solverTvmTol else significantDigits;

        realSetOne(tolAlmostZero);
        tolAlmostZero.exponent -= if (significantDigits == 0 or significantDigits == 34) solverTvmZer else (@as(i32, significantDigits) + 1);

        realSetOne(minBracketSpacing);
        minBracketSpacing.exponent -= if (significantDigits == 0 or significantDigits == 34) solverTvmTol else significantDigits;
    } else {
        convergenceTolerence(tol);
        stringToReal("1e-34", tolAlmostZero, ctxtSolver());
        realCopy(const_1e_32(), minBracketSpacing);
    }

    if (engineNestingRefused(false)) { // ahead of the flags and both depth counters
        return SOLVER_RESULT_ABORTED;
    }
    engineNestingDepth += 1;
    currentSolverNestingDepth += 1;
    setSystemFlag(FLAG_SOLVING);
    clearSystemFlag(FLAG_INTING);

    realSetZero(delta);

    real34ToReal(y, aa);
    real34ToReal(y, bb1);
    real34ToReal(x, bb);
    realSetNaN(bb2);

    // determine the tolerance (ULP) with which levelness will be detected
    real34NextPlus(x, &antiLevel34);
    if (real34IsInfinite(&antiLevel34)) {
        real34NextMinus(x, &antiLevel34);
        real34Subtract(x, &antiLevel34, &antiLevel34);
    } else {
        real34Subtract(x, &antiLevel34, &antiLevel34);
    }

    // The C uses `retryLevel:` as a goto target reached from two sites. The
    // region from the nudge down to the fbb==fbb1 check forms a loop: nudge,
    // setup+eval, and loop back when fbb==fbb1 && getOutOfLevel>=0. The first
    // entry runs the nudge only if bb==aa.
    var doNudge: bool_t = realCompareEqual(bb, aa);
    retry: while (true) {
        if (doNudge) {
            getOutOfLevel -= 1;
            if (getOutOfLevel >= 0) {
                real34Multiply(&antiLevel34, const34_153(), &antiLevel34); // increase it for the next round
                real34Minus(&antiLevel34, &antiLevel34); // flip sign
                real34ToReal(&antiLevel34, antiLevel);
                if (real34IsPositive(&antiLevel34)) {
                    realAdd(bb, antiLevel, bb, ctxtSolver()); // Add to the right hand starting value
                } else {
                    realAdd(aa, antiLevel, aa, ctxtSolver()); // Add to the left hand starting value
                    realAdd(bb1, antiLevel, bb1, ctxtSolver());
                }
            }
        }

        realSubtract(bb, aa, ss, ctxtSolver());
        if (realCompareAbsLessThan(ss, minBracketSpacing)) {
            realCopy(minBracketSpacing, ss);
            if (realCompareLessThan(bb, aa)) {
                realSetNegativeSign(ss);
            }
            realSubtract(aa, ss, aa, ctxtSolver());
            realAdd(bb, ss, bb, ctxtSolver());
        }

        _executeSolverReal(variable, bb1, fbb1, null);
        if (lastErrorCode != ERROR_NONE) {
            result = SOLVER_RESULT_BAD_GUESS;
        }
        realCopy(fbb1, faa);

        // calculation
        _executeSolverReal(variable, bb, fbb, null);

        if (lastErrorCode != ERROR_NONE) {
            result = SOLVER_RESULT_BAD_GUESS;
        }

        if (realIsSpecial(fbb) or realIsSpecial(fbb1)) {
            result = SOLVER_RESULT_BAD_GUESS;
        } else if (realIsNegative(fbb) == realIsNegative(fbb1)) {
            extendRange = true;
        }

        if (realCompareEqual(fbb, fbb1)) {
            if (getOutOfLevel >= 0) {
                doNudge = true;
                continue :retry;
            } else {
                originallyLevel = true;
            }
        }
        break :retry;
    }

    if (realCompareAbsLessThan(faa, fbb)) {
        realCopy(bb, tmp);
        realCopy(aa, bb);
        realCopy(tmp, aa);
        realCopy(tmp, bb1);
        realCopy(fbb, tmp);
        realCopy(faa, fbb);
        realCopy(tmp, faa);
        realCopy(tmp, fbb1);
    }

    if (realIsZero(faa) or realIsZero(fbb)) { // already is a root?
        engineNestingDepth -= 1;
        currentSolverNestingDepth -= 1;
        if (currentSolverNestingDepth == 0) {
            clearSystemFlag(FLAG_SOLVING);
        } else if (was_inting) {
            clearSystemFlag(FLAG_SOLVING);
            setSystemFlag(FLAG_INTING);
        }
        real34SetZero(resZ);
        real34SetZero(resY);
        realToReal34(if (realIsZero(faa)) aa else bb, resX);

        reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
        real34Copy(resX, registerReal34Ptr(REGISTER_X));
        copySourceRegisterToDestRegister(REGISTER_X, variable);

        return SOLVER_RESULT_NORMAL;
    }

    // result of the iteration is delivered via labeled blocks that emulate the
    // C `goto solver_polish_exit` / `goto solver_final_print` targets.
    polish_exit: {
        final_print: {
            // =========== ITERATION START =============
            while (true) {
                loop += 1;
                if (checkHalfSec()) {
                    var ssbuf: [10]u8 = undefined;
                    ssbuf[0..6].* = "Iter: ".*;
                    ssbuf[4] = if (currentMethod == SOLVER_METHOD_BRENT) ':' else '=';
                    if (progressHalfSecUpdate_Integer(timed, @ptrCast(&ssbuf[0]), loop, halfSec_clearZ, halfSec_clearT, halfSec_disp)) {
                        var a34: real34_t = undefined;
                        var b34: real34_t = undefined;
                        var fa34: real34_t = undefined;
                        var fb34: real34_t = undefined;
                        realToReal34(aa, &a34);
                        realToReal34(bb, &b34);
                        realToReal34(faa, &fa34);
                        realToReal34(fbb, &fb34);
                        _showProgress(&a34, &b34, &fa34, &fb34);
                    }
                }

                if (exitKeyWaiting()) {
                    _ = progressHalfSecUpdate_Integer(force + 1, "Interrupted Iter:", loop, halfSec_clearZ, halfSec_clearT, halfSec_disp);
                    programRunStop = 2; // PGM_WAITING
                    displayCalcErrorMessage(ERROR_SOLVER_ABORT, REGISTER_T, NIM_REGISTER_LINE);
                    break;
                }

                // pre-calculation
                if (realIsSpecial(bb2)) {
                    realSubtract(bb, bb1, deltaB, ctxtSolverHi());
                } else {
                    realSubtract(bb1, bb2, deltaB, ctxtSolverHi());
                }
                realSetPositiveSign(deltaB);

                _linearInterpolation(aa, bb, faa, fbb, null, secantSlopeA, ctxtSolverHi());

                // interpolation
                if (!(realCompareEqual(faa, fbb) or realCompareEqual(faa, fbb1) or realCompareEqual(fbb, fbb1))) { // inverse quadratic
                    _linearInterpolation(bb, bb1, fbb, fbb1, null, secantSlopeB, ctxtSolverHi());
                    _inverseQuadraticInterpolation(aa, bb, bb1, faa, fbb, fbb1, ss, ctxtSolverHi());
                } else { // linear interpolation
                    _linearInterpolation(bb, bb1, fbb, fbb1, ss, secantSlopeB, ctxtSolverHi());
                }

                realSubtract(ss, bb, smb, ctxtSolverHi());
                realMultiply(smb, const_2(), smb, ctxtSolverHi());
                realSetPositiveSign(smb);

                realSubtract(bb, bb1, bracketWidth, ctxtSolver());
                realSetPositiveSign(bracketWidth);

                if (currentMethod != SOLVER_METHOD_NEWTON or !newtonInitialized) {
                    // bisection
                    realAdd(aa, bb, mm, ctxtSolver());
                    realMultiply(mm, const_1on2(), mm, ctxtSolver());
                }

                // OPTION_TVM_NEWTON: method selection
                if ((currentSolverStatus & SOLVER_STATUS_TVM_APPLICATION) != 0 and
                    (variable == @as(calcRegister_t, @bitCast(RESERVED_VARIABLE_IPONA)) or
                        variable == @as(calcRegister_t, @bitCast(RESERVED_VARIABLE_NPPER)) or
                        variable == @as(calcRegister_t, @bitCast(RESERVED_VARIABLE_PV)) or
                        variable == @as(calcRegister_t, @bitCast(RESERVED_VARIABLE_PMT)) or
                        variable == @as(calcRegister_t, @bitCast(RESERVED_VARIABLE_FV))) and
                    currentMethod != SOLVER_METHOD_NEWTON and loop >= 5)
                {
                    realSubtract(bb, aa, fullBracket, ctxtSolver());
                    realSetPositiveSign(fullBracket);
                    realDivide(fullBracket, bb, relativeWidth, ctxtSolver());
                    realSetPositiveSign(relativeWidth);

                    var handoff: bool_t = false;
                    if (realGetExponentComp(bb) >= -25) {
                        if (realGetExponentComp(relativeWidth) <= -2) {
                            handoff = true;
                        } else if (realGetExponentComp(relativeWidth) <= 1 and realGetExponentComp(fbb) <= -10) {
                            handoff = true;
                        }
                    } else {
                        if (realGetExponentComp(bracketWidth) <= -35) {
                            handoff = true;
                        }
                    }

                    if (handoff and !newtonDisabled) {
                        currentMethod = SOLVER_METHOD_NEWTON;
                        realCopy(bb, newton_x);
                        newtonInitialized = true;
                    }
                }

                // next point - select based on current method
                if (currentMethod == SOLVER_METHOD_NEWTON and newtonInitialized) {
                    // Newton step: x_new = x - f(x)/f'(x)
                    realCopy(newton_x, newton_trial);
                    _executeSolverReal(variable, newton_trial, newton_fx, newton_deriv);

                    if (realIsZero(newton_deriv) or realIsSpecial(newton_fx)) {
                        currentMethod = SOLVER_METHOD_BRENT;
                        newtonInitialized = false;
                        bp1 = mm;
                    } else {
                        realDivide(newton_fx, newton_deriv, newton_step, ctxtSolver());
                        realSubtract(newton_x, newton_step, newton_x, ctxtSolver());
                        newton_iter_count += 1;
                        if (newton_iter_count > 12) {
                            realToReal34(newton_fx, resZ);
                            realToReal34(newton_x, resY);
                            realToReal34(newton_x, resX);
                            reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
                            real34Copy(resX, registerReal34Ptr(REGISTER_X));
                            copySourceRegisterToDestRegister(REGISTER_X, variable);
                            engineNestingDepth -= 1;
                            currentSolverNestingDepth -= 1;
                            if (currentSolverNestingDepth == 0) {
                                clearSystemFlag(FLAG_SOLVING);
                            }
                            first_newton_iter = true;
                            return SOLVER_RESULT_NORMAL;
                        }

                        realCopy(newton_x, newton_trial);
                        _executeSolverReal(variable, newton_trial, newton_fx, null);
                        bp1 = newton_x;
                    }
                } else {
                    if (extendRange) {
                        realSubtract(bb, aa, tmp, ctxtSolver());
                        realMultiply(tmp, const_2(), tmp, ctxtSolver());
                        realAdd(bb, tmp, ss, ctxtSolver()); // Use ss instead of b
                        bp1 = ss;
                    } else if (realCompareEqual(bb, ss)) {
                        bp1 = mm;
                    } else if (realCompareLessThan(delta, deltaB) and realCompareLessThan(smb, deltaB)) {
                        bp1 = ss;
                    } else {
                        bp1 = mm;
                    }
                }

                // calculation
                _executeSolverReal(variable, bp1, fbp1, null);

                // OPTION_TVM_NEWTON: convergence / divergence
                if (currentMethod == SOLVER_METHOD_NEWTON and newtonInitialized) {
                    if (newton_polish_mode) {
                        newton_polish_count += 1;
                        if (newton_polish_count > 2) {
                            newton_polish_mode = false;
                            if (realCompareAbsLessThan(fbp1, fbb)) {
                                realToReal34(fbp1, resZ);
                                realToReal34(newton_x, resY);
                                realToReal34(newton_x, resX);
                                reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
                                real34Copy(resX, registerReal34Ptr(REGISTER_X));
                                copySourceRegisterToDestRegister(REGISTER_X, variable);
                                engineNestingDepth -= 1;
                                currentSolverNestingDepth -= 1;
                                if (currentSolverNestingDepth == 0) {
                                    clearSystemFlag(FLAG_SOLVING);
                                }
                                return SOLVER_RESULT_NORMAL;
                            } else {
                                realToReal34(brent_best_fx, resZ);
                                realToReal34(brent_best_x, resY);
                                realToReal34(brent_best_x, resX);
                                reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
                                real34Copy(resX, registerReal34Ptr(REGISTER_X));
                                copySourceRegisterToDestRegister(REGISTER_X, variable);
                                engineNestingDepth -= 1;
                                currentSolverNestingDepth -= 1;
                                if (currentSolverNestingDepth == 0) {
                                    clearSystemFlag(FLAG_SOLVING);
                                }
                                return SOLVER_RESULT_NORMAL;
                            }
                        }
                    }

                    // Is Newton diverging
                    if (!first_newton_iter and realCompareAbsLessThan(prev_fx, fbp1)) {
                        currentMethod = SOLVER_METHOD_BRENT;
                        newtonInitialized = false;
                        newtonDisabled = true;
                        newton_iter_count = 0;
                        first_newton_iter = true;
                        stall_count = 0;
                    } else if (!first_newton_iter and realCompareEqual(newton_x, prev_x)) {
                        realSetOne(tol_converged);
                        tol_converged.exponent = -37;

                        if (realCompareAbsLessThan(fbp1, tol_converged)) {
                            realToReal34(fbp1, resZ);
                            realToReal34(newton_x, resY);
                            realToReal34(newton_x, resX);
                            reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
                            real34Copy(resX, registerReal34Ptr(REGISTER_X));
                            copySourceRegisterToDestRegister(REGISTER_X, variable);
                            engineNestingDepth -= 1;
                            currentSolverNestingDepth -= 1;
                            if (currentSolverNestingDepth == 0) {
                                clearSystemFlag(FLAG_SOLVING);
                            }
                            first_newton_iter = true;
                            stall_count = 0;
                            return SOLVER_RESULT_NORMAL;
                        } else {
                            stall_count += 1;
                            if (stall_count >= 3) {
                                currentMethod = SOLVER_METHOD_BRENT;
                                newtonInitialized = false;
                                first_newton_iter = true;
                                stall_count = 0;
                            }
                        }
                    } else {
                        realCopy(fbp1, prev_fx);
                        realCopy(newton_x, prev_x);
                        stall_count = 0;
                        if (!first_newton_iter and realCompareAbsLessThan(fbp1, tolAlmostZero)) {
                            realToReal34(fbp1, resZ);
                            realToReal34(newton_x, resY);
                            realToReal34(newton_x, resX);
                            reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
                            real34Copy(resX, registerReal34Ptr(REGISTER_X));
                            copySourceRegisterToDestRegister(REGISTER_X, variable);
                            engineNestingDepth -= 1;
                            currentSolverNestingDepth -= 1;
                            if (currentSolverNestingDepth == 0) {
                                clearSystemFlag(FLAG_SOLVING);
                            }
                            first_newton_iter = true; // Reset for next solve
                            return SOLVER_RESULT_NORMAL;
                        }
                        first_newton_iter = false; // Mark that Newton has now run
                    }
                }

                // Calculate convergence flags (needed for exit conditions)
                const bb_bb1_converged: bool_t = WP34S_RelativeError(bb, bb1, tol, ctxtSolver());
                const b1_b2_Equal: bool_t = realCompareEqual(bb1, bb2);
                const b_b1_Equal: bool_t = realCompareEqual(bb, bb1);

                // Bracket update - only for Brent method
                if (currentMethod != SOLVER_METHOD_NEWTON or !newtonInitialized) {
                    if (extendRange and (realIsNegative(secantSlopeA) != realIsNegative(secantSlopeB)) and !realIsZero(secantSlopeA) and !realIsZero(secantSlopeB)) {
                        extendRange = false;
                        extremum = (realIsNegative(fbb) == realIsNegative(fbp1));
                    }

                    if (!realIsSpecial(bp1) and !realIsSpecial(fbp1)) {
                        if (extendRange) {
                            if ((realIsNegative(fbb) != realIsNegative(fbp1)) or (realIsNegative(fbb) != realIsNegative(faa))) {
                                extendRange = false;
                                originallyLevel = false;
                            }
                            if ((realIsNegative(faa) == realIsNegative(fbp1)) and realCompareAbsLessThan(fbb, fbp1)) {
                                extendRange = false;
                                originallyLevel = false;
                                extremum = true;
                            }
                        } else if (realIsNegative(faa) == realIsNegative(fbp1)) {
                            realCopy(bb, aa);
                            realCopy(fbb, faa);
                        } else {
                            extendRange = false;
                            extremum = false;
                            if (!realCompareEqual(fbb, faa)) {
                                originallyLevel = false;
                            }
                        }

                        if (realCompareAbsLessThan(faa, fbp1)) {
                            realCopy(bp1, tmp);
                            realCopy(aa, bp1);
                            realCopy(tmp, aa);
                            realCopy(fbp1, tmp);
                            realCopy(faa, fbp1);
                            realCopy(tmp, faa);
                            realCopy(aa, bb);
                            realCopy(faa, fbb);
                        }

                        if (bp1 == ss) {
                            realSetNaN(bb2);
                        } else {
                            realCopy(bb1, bb2);
                        }
                        realCopy(bb, bb1);
                        realCopy(fbb, fbb1);
                        realCopy(bp1, bb);
                        realCopy(fbp1, fbb);
                    } else if (originallyLevel and (realIsInfinite(bb) or realIsInfinite(aa))) {
                        result = SOLVER_RESULT_CONSTANT;
                    } else if (extendRange) {
                        extendRange = false;
                        originallyLevel = false;
                        extremum = true;
                    } else if (realIsNegative(faa) != realIsNegative(fbb)) {
                        result = SOLVER_RESULT_SIGN_REVERSAL;
                    } else {
                        result = SOLVER_RESULT_EXTREMUM;
                    }

                    // Stricter residual tolerance near zero
                    if (realCompareAbsLessThan(bb, const_1e_16())) {
                        stringToReal("1e-120", tol1, ctxtSolver());
                        fbIsAlmostZero = realCompareAbsLessThan(fbb, tol1);
                    } else {
                        fbIsAlmostZero = realCompareAbsLessThan(fbb, tolAlmostZero);
                    }

                    if (result != SOLVER_RESULT_NORMAL) {
                        break;
                    }
                }

                // End conditions
                if ((!realIsSpecial(bb2) and b1_b2_Equal) and
                    ((extendRange or bb_bb1_converged) or extremum))
                {
                    break;
                }
                if (!originallyLevel and ((!extendRange and bb_bb1_converged) or b_b1_Equal or fbIsAlmostZero)) {
                    if (currentMethod == SOLVER_METHOD_BRENT and
                        (currentSolverStatus & SOLVER_STATUS_TVM_APPLICATION) != 0 and
                        (variable == @as(calcRegister_t, @bitCast(RESERVED_VARIABLE_IPONA)) or
                            variable == @as(calcRegister_t, @bitCast(RESERVED_VARIABLE_NPPER)) or
                            variable == @as(calcRegister_t, @bitCast(RESERVED_VARIABLE_PV)) or
                            variable == @as(calcRegister_t, @bitCast(RESERVED_VARIABLE_PMT)) or
                            variable == @as(calcRegister_t, @bitCast(RESERVED_VARIABLE_FV))))
                    {
                        currentMethod = SOLVER_METHOD_NEWTON;
                        realCopy(bb, newton_x);
                        newtonInitialized = true;
                        newton_polish_mode = true;
                        newton_polish_count = 0;
                        realCopy(bb, brent_best_x);
                        realCopy(fbb, brent_best_fx);
                        // Don't break - do Newton polish
                    } else if (newton_polish_mode and newton_polish_count > 0) {
                        newton_polish_mode = false;
                        newton_polish_count = 0;
                        if (realCompareAbsLessThan(fbp1, brent_best_fx)) {
                            realToReal34(fbp1, resZ);
                            realToReal34(newton_x, resY);
                            realToReal34(newton_x, resX);
                        } else {
                            realToReal34(brent_best_fx, resZ);
                            realToReal34(brent_best_x, resY);
                            realToReal34(brent_best_x, resX);
                        }
                        break :final_print; // goto solver_polish_exit
                    } else {
                        break;
                    }
                }
                if (loop > (if ((currentSolverStatus & SOLVER_STATUS_TVM_APPLICATION) != 0) @as(c_int, 2000) else @as(c_int, 10000))) {
                    result = SOLVER_RESULT_OTHER_FAILURE;
                    break;
                }
            }
            //==== ITER END ====

            _executeSolverReal(variable, bb, tmp, null);
            realToReal34(tmp, resZ);
            realToReal34(bb1, resY);
            realToReal34(bb, resX);
            reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
            real34Copy(resX, registerReal34Ptr(REGISTER_X));
            copySourceRegisterToDestRegister(REGISTER_X, variable);
            break :polish_exit; // goto solver_final_print
        }
        // solver_polish_exit:
        reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
        real34Copy(resX, registerReal34Ptr(REGISTER_X));
        copySourceRegisterToDestRegister(REGISTER_X, variable);
    }

    // solver_final_print:
    if ((extendRange and !originallyLevel) or extremum) {
        result = SOLVER_RESULT_EXTREMUM;
    }

    engineNestingDepth -= 1; // after the extremum check above, which re-runs the user program
    currentSolverNestingDepth -= 1;
    if (currentSolverNestingDepth == 0) {
        clearSystemFlag(FLAG_SOLVING);
    } else if (was_inting) {
        clearSystemFlag(FLAG_SOLVING);
        setSystemFlag(FLAG_INTING);
    }

    if (fbIsAlmostZero) {
        result = SOLVER_RESULT_NORMAL;
    }

    if (result == SOLVER_RESULT_EXTREMUM) { // Check if the result is really an extremum
        const retainSolvingFlag: bool_t = getSystemFlag(@bitCast(FLAG_SOLVING));
        setSystemFlag(FLAG_SOLVING);
        realCopy(minBracketSpacing, tmp);
        while (true) {
            real34ToReal(resX, resXr);
            real34ToReal(resZ, resZr);
            realAdd(resXr, tmp, aa, ctxtSolver());
            realSubtract(resXr, tmp, bb, ctxtSolver());
            _executeSolverReal(variable, aa, faa, null);
            _executeSolverReal(variable, bb, fbb, null);
            realSubtract(faa, resZr, faa, ctxtSolver());
            realSubtract(fbb, resZr, fbb, ctxtSolver());
            if (realIsSpecial(faa) or realIsSpecial(fbb)) {
                result = SOLVER_RESULT_OTHER_FAILURE;
                break;
            } else if ((currentSolverStatus & SOLVER_STATUS_TVM_APPLICATION) != 0 and (realIsSpecial(aa) or realIsSpecial(bb))) {
                result = SOLVER_RESULT_CONSTANT;
                break;
            } else if (realIsZero(faa) or realIsZero(fbb)) {
                realMultiply(tmp, const_100(), tmp, ctxtSolver());
            } else if (realIsNegative(faa) == realIsNegative(fbb)) { // true extremum
                break;
            } else { // not an extremum
                result = SOLVER_RESULT_OTHER_FAILURE;
                break;
            }
        }
        if (!retainSolvingFlag) {
            clearSystemFlag(FLAG_SOLVING);
        }
    }

    if (result == SOLVER_RESULT_NORMAL and real34IsInfinite(registerReal34Ptr(variable)) and extendRange and real34IsZero(resZ)) {
        result = SOLVER_RESULT_CONSTANT;
    }

    if (lastErrorCode == ERROR_SOLVER_ABORT) {
        result = SOLVER_RESULT_ABORTED;
    }

    return result;
}
