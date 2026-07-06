// SPDX-License-Identifier: GPL-3.0-only
const consts = abi.constants;
//
// Zig owner for src/c47/solver/sumprod.c: the programmable Sigma / Pi
// (fnProgrammableSum / fnProgrammableProduct). This file is UNCOVERED by the
// testSuite (no test gate) - it is verified by build only. Faithful line-by-line
// translation preserving the exact order of every real_t / real34_t operation.
//
// The bridge (sumprod_legacy.c, removed) renamed fnProgrammableSum ->
// z47_solver_fnProgrammableSum and fnProgrammableProduct ->
// z47_solver_fnProgrammableProduct; those are the symbols solve.zig's
// dispatcher calls. We export them with those names. The static
// _programmableSumProd / _checkArgument become private. showProgressReal is also
// defined in sumprod.c and is used by graph.c, so it is re-exported here.
//
// The host-only progress display (showProgressReal body, guarded by
// ENABLE_SOLVER_PROGRESS == 1) has no effect on the computed stack result; the
// underlying control-flow functions (progressHalfSecUpdate_Integer, checkHalfSec)
// are still called so programRunStop / flag side effects are preserved, but the
// actual screen drawing is reduced to a no-op (same precedent as the prime
// owner's _showProgress). The VERBOSE_COUNTER debug blocks are #undef'd in the C
// and are omitted. EXTRA_INFO_ON_CALC_ERROR sprintf hints become fixed
// moreInfoOnError strings (no-op under TESTSUITE/DMCP).

const runtime = @import("solve_runtime.zig");

// DECNUMDIGITS=75, DECDPUN=3 => DECNUMUNITS=ceil(75/3)=25; decNumberUnit=u16.
const abi = @import("abi"); // L1 shared bindings (REPORT-23 §5)
const real_t = abi.Real;
const real34_t = abi.Real34;
const realContext_t = abi.RealContext;

const calcRegister_t = runtime.calcRegister_t;
const bool_t = bool;

// GMP long integer (mpz). The linkable symbols are __gmpz_*.
const mp_limb_t = usize;
const mpz_struct = abi.Mpz;
const longInteger_t = [1]mpz_struct;

extern fn __gmpz_init(op: *mpz_struct) void;
extern fn __gmpz_clear(op: *mpz_struct) void;
extern fn __gmpz_fdiv_ui(op: *const mpz_struct, d: c_ulong) c_ulong;

inline fn longIntegerInit(op: *mpz_struct) void {
    __gmpz_init(op);
}
inline fn longIntegerFree(op: *mpz_struct) void {
    __gmpz_clear(op);
}
inline fn longIntegerModuloUInt(op: *const mpz_struct, u: u32) u32 {
    return @truncate(__gmpz_fdiv_ui(op, u));
}

// ---------------------------------------------------------------------------
// defines.h values (verified)
// ---------------------------------------------------------------------------
const REGISTER_X: calcRegister_t = 100;
const REGISTER_Y: calcRegister_t = 101;
const REGISTER_Z: calcRegister_t = 102;
const REGISTER_T: calcRegister_t = 103;
const ERR_REGISTER_LINE: calcRegister_t = REGISTER_Z;

const FIRST_LABEL: u16 = 2200; // INVALID_VARIABLE=2199 precedes FIRST_LABEL; the //2044 C comment is stale
const LAST_LABEL: u16 = 6999;
const INVALID_VARIABLE: u16 = 2199;

const ERROR_NONE: u8 = 0;
const ERROR_LABEL_NOT_FOUND: u8 = 6;
const ERROR_OUT_OF_RANGE: u8 = 8;
const ERROR_BAD_INPUT: u8 = 53;

const FLAG_SOLVING: u32 = 0xc026;
const FLAG_CPXRES: u16 = 0x8004;

const dtReal34: u32 = 1;
const dtComplex34: u32 = 2;
const amNone: u32 = 5;
const NOPARAM: u16 = 9876;

const DEC_ROUND_DOWN: c_int = 5; // round towards 0 (truncate)

const TI_NO_INFO: u8 = 0;
const PGM_WAITING: u8 = 2;
const PGM_STOPPED: u8 = 0;

// screen.h: timed=0, force=1, halfSec_clear*/disp=true.
const timed: u8 = 0;
const force: u8 = 1;
const halfSec_clearZ: bool = true;
const halfSec_clearT: bool = true;
const halfSec_disp: bool = true;

// ---------------------------------------------------------------------------
// Globals
// ---------------------------------------------------------------------------
extern var lastErrorCode: u8;
extern var temporaryInformation: u8;
extern var programRunStop: u8;
extern var currentKeyCode: u8;
extern var dynamicMenuItem: i16;
extern var currentSolverNestingDepth: u16;

extern var ctxtReal75: realContext_t;
extern var ctxtReal34: realContext_t;

// ---------------------------------------------------------------------------
// Constants blob accessors
// ---------------------------------------------------------------------------

inline fn const_0() *align(1) const real_t {
    return consts.c1708();
}
inline fn const_1() *align(1) const real_t {
    return consts.c4856();
}
inline fn const34_0() *align(1) const real34_t {
    return consts.q16200();
}

// ---------------------------------------------------------------------------
// decNumber primitives / real_t macros
// ---------------------------------------------------------------------------
extern fn decNumberCopy(res: *real_t, source: *align(1) const real_t) *real_t;
extern fn decNumberAdd(res: *real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberMultiply(res: *real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *real_t;

// decNumberIsZero is a decNumber.h macro (DECSPECIAL = 0x70):
//   (*lsu == 0 && digits == 1 && (bits & 0x70) == 0)
inline fn decNumberIsZero(dn: *align(1) const real_t) bool {
    return dn.lsu[0] == 0 and dn.digits == 1 and (dn.bits & 0x70) == 0;
}

inline fn realCopy(source: *align(1) const real_t, destination: *real_t) void {
    _ = decNumberCopy(destination, source);
}
inline fn realAdd(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberAdd(res, op1, op2, ctxt);
}
inline fn realMultiply(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberMultiply(res, op1, op2, ctxt);
}
inline fn realIsZero(source: *const real_t) bool {
    return decNumberIsZero(source);
}
extern fn realSetZero(value: *real_t) void;
extern fn mulComplexComplex(f1r: *const real_t, f1i: *const real_t, f2r: *const real_t, f2i: *const real_t, pr: *real_t, pi: *real_t, real_context: *realContext_t) void;

// ---------------------------------------------------------------------------
// real34_t macros
// ---------------------------------------------------------------------------
extern fn decimal128ToNumber(source: *align(1) const real34_t, destination: *real_t) *real_t;
extern fn decQuadAdd(res: *align(1) real34_t, op1: *align(1) const real34_t, op2: *align(1) const real34_t, ctxt: *realContext_t) *align(1) real34_t;
extern fn decQuadSubtract(res: *align(1) real34_t, op1: *align(1) const real34_t, op2: *align(1) const real34_t, ctxt: *realContext_t) *align(1) real34_t;
extern fn decQuadMultiply(res: *align(1) real34_t, op1: *align(1) const real34_t, op2: *align(1) const real34_t, ctxt: *realContext_t) *align(1) real34_t;
extern fn decQuadDivide(res: *align(1) real34_t, op1: *align(1) const real34_t, op2: *align(1) const real34_t, ctxt: *realContext_t) *align(1) real34_t;
extern fn decQuadCompare(res: *align(1) real34_t, op1: *align(1) const real34_t, op2: *align(1) const real34_t, ctxt: *realContext_t) *align(1) real34_t;
extern fn decQuadIsZero(source: *align(1) const real34_t) bool;
extern fn decQuadToInt32(source: *align(1) const real34_t, ctxt: *realContext_t, mode: c_int) i32;
extern fn convertReal34ToLongInteger(real34: *align(1) const real34_t, lgInt: *mpz_struct, mode: c_int) void;

inline fn real34ToReal(source: *align(1) const real34_t, destination: *real_t) void {
    _ = decimal128ToNumber(source, destination);
}
inline fn real34Copy(source: *align(1) const real34_t, destination: *align(1) real34_t) void {
    const src: *align(1) const [2]u64 = @ptrCast(source);
    const dst: *align(1) [2]u64 = @ptrCast(destination);
    dst[0] = src[0];
    dst[1] = src[1];
}
inline fn real34Add(op1: *align(1) const real34_t, op2: *align(1) const real34_t, res: *align(1) real34_t) void {
    _ = decQuadAdd(res, op1, op2, &ctxtReal34);
}
inline fn real34Subtract(op1: *align(1) const real34_t, op2: *align(1) const real34_t, res: *align(1) real34_t) void {
    _ = decQuadSubtract(res, op1, op2, &ctxtReal34);
}
inline fn real34Multiply(op1: *align(1) const real34_t, op2: *align(1) const real34_t, res: *align(1) real34_t) void {
    _ = decQuadMultiply(res, op1, op2, &ctxtReal34);
}
inline fn real34Divide(op1: *align(1) const real34_t, op2: *align(1) const real34_t, res: *align(1) real34_t) void {
    _ = decQuadDivide(res, op1, op2, &ctxtReal34);
}
inline fn real34Compare(op1: *align(1) const real34_t, op2: *align(1) const real34_t, res: *align(1) real34_t) void {
    _ = decQuadCompare(res, op1, op2, &ctxtReal34);
}
inline fn real34IsZero(source: *align(1) const real34_t) bool {
    return decQuadIsZero(source);
}
inline fn real34ToInt32(source: *align(1) const real34_t) i32 {
    return decQuadToInt32(source, &ctxtReal34, DEC_ROUND_DOWN);
}

extern fn real34CompareEqual(number1: *align(1) const real34_t, number2: *align(1) const real34_t) bool;
extern fn real34CompareGreaterThan(number1: *align(1) const real34_t, number2: *align(1) const real34_t) bool;
extern fn real34CompareLessThan(number1: *align(1) const real34_t, number2: *align(1) const real34_t) bool;
extern fn real34CompareGreaterEqual(number1: *align(1) const real34_t, number2: *align(1) const real34_t) bool;
extern fn real34CompareLessEqual(number1: *align(1) const real34_t, number2: *align(1) const real34_t) bool;

// ---------------------------------------------------------------------------
// Register / stack / program externs
// ---------------------------------------------------------------------------
const REAL34_SIZE_IN_BYTES: usize = 16;
extern fn getRegisterDataPointer(reg: calcRegister_t) ?*anyopaque;
const registerReal34Ptr = abi.registerReal34;
const registerImag34Ptr = abi.registerImag34;

extern fn getRegisterDataType(reg: calcRegister_t) u32;
extern fn reallocateRegister(regist: calcRegister_t, data_type: u32, data_len: u32, tag: u32) void;
extern fn convertRealToReal34ResultRegister(real: *const real_t, dest: calcRegister_t) void;
extern fn convertRealToImag34ResultRegister(real: *const real_t, dest: calcRegister_t) void;

extern fn getFlag(flag: u16) bool;
extern fn setSystemFlag(sf: c_uint) void;
extern fn clearSystemFlag(sf: c_uint) void;
extern fn fnToReal(unused: u16) void;
extern fn fnDrop(unused: u16) void;
extern fn fnFillStack(unused: u16) void;
extern fn execProgram(label: u16) void;
extern fn adjustResult(res: calcRegister_t, drop_y: bool, set_cpx_res: bool, op1: calcRegister_t, op2: calcRegister_t, op3: calcRegister_t) void;
extern fn displayCalcErrorMessage(error_code: u8, err_message_register_line: calcRegister_t, err_register_line: calcRegister_t) void;
extern fn moreInfoOnError(m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) void;
extern fn findNamedLabel(label_name: [*:0]const u8) calcRegister_t;
extern fn letteredRegisterName(regist: calcRegister_t) u8;

extern fn checkHalfSec() bool;
extern fn progressHalfSecUpdate_Integer(mode: u8, txt: [*:0]const u8, loop: i32, clearZ: bool, clearT: bool, disp: bool) bool;

// ===========================================================================
// showProgressReal: host-only progress display. The drawing is reduced to a
// no-op (no effect on the computed result); still exported because graph.c
// calls it. (ENABLE_SOLVER_PROGRESS == 1 body omitted.)
// ===========================================================================
pub export fn showProgressReal(a: *const real_t, ai: *real_t, cpx: bool_t) linksection(runtime.code_section) callconv(.c) void {
    _ = a;
    _ = ai;
    _ = cpx;
}

// ===========================================================================
// _programmableSumProd
// ===========================================================================
fn _programmableSumProd(label: u16, prod: bool_t) linksection(runtime.code_section) void {
    currentKeyCode = 255;
    var loop: i32 = 0;
    var finished: i16 = 0;
    var resultX: real_t = undefined;
    var resultXi: real_t = undefined;
    var resultR: real_t = undefined;
    var resultRi: real_t = undefined;
    var loopStep: real34_t = undefined;
    var loopTo: real34_t = undefined;
    var counter: real34_t = undefined;
    var compare: real34_t = undefined;
    var sign: real34_t = undefined;
    var rLoop: real34_t = undefined;
    var changedOverToComplex: bool_t = false;
    var iLoop: longInteger_t = undefined;

    fnToReal(NOPARAM);
    real34Copy(registerReal34Ptr(REGISTER_X), &loopStep);
    fnDrop(NOPARAM);
    fnToReal(NOPARAM);
    real34Copy(registerReal34Ptr(REGISTER_X), &loopTo);
    fnDrop(NOPARAM);
    fnToReal(NOPARAM);
    real34Copy(registerReal34Ptr(REGISTER_X), &counter); // Loopfrom
    realCopy(if (prod) const_1() else const_0(), &resultR); // Initialize real accumulator
    realSetZero(&resultRi); // Initialize complex accumulator

    real34Subtract(&loopTo, &counter, &rLoop); // calculate the remaining iteration counter
    if (!real34IsZero(&loopStep)) {
        real34Divide(&rLoop, &loopStep, &rLoop);
    }
    // iLoop is initialised by convertReal34ToLongInteger; do not double-init (leak).
    convertReal34ToLongInteger(&rLoop, &iLoop[0], DEC_ROUND_DOWN);
    loop = @bitCast(longIntegerModuloUInt(&iLoop[0], @bitCast(@as(i32, 0x7FFFFFFF))));
    longIntegerFree(&iLoop[0]);

    if (!real34CompareEqual(&loopTo, &counter) and
        (real34IsZero(&loopStep) or
            (real34CompareGreaterThan(&loopTo, &counter) and real34CompareLessEqual(&loopStep, const34_0())) or
            (real34CompareLessThan(&loopTo, &counter) and real34CompareGreaterEqual(&loopStep, const34_0()))))
    {
        displayCalcErrorMessage(ERROR_BAD_INPUT, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function _programmableSumProd:", "Counter will not count to destination", null, null);
    } else {
        currentSolverNestingDepth += 1;
        setSystemFlag(FLAG_SOLVING);

        while (lastErrorCode == ERROR_NONE) {
            loop -= 1;
            if (checkHalfSec()) {
                if (progressHalfSecUpdate_Integer(timed, "Loop: ", loop, halfSec_clearZ, halfSec_clearT, halfSec_disp)) {
                    showProgressReal(&resultR, &resultRi, changedOverToComplex);
                }
            }

            real34Compare(&counter, &loopTo, &compare);
            real34Compare(&loopStep, const34_0(), &sign);
            real34Multiply(&compare, &sign, &compare);
            finished = @truncate(real34ToInt32(&compare)); // 0 means equal
            if (finished > 0) {
                break;
            }

            if (getRegisterDataType(REGISTER_X) != dtReal34) {
                reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
            }
            real34Copy(&counter, registerReal34Ptr(REGISTER_X));
            fnFillStack(NOPARAM);

            dynamicMenuItem = -1;
            execProgram(label);
            if (lastErrorCode != ERROR_NONE) {
                break;
            }

            if (getFlag(FLAG_CPXRES) and (getRegisterDataType(REGISTER_X) == dtComplex34 or !realIsZero(&resultRi))) {
                changedOverToComplex = true; // Only latch over to complex operation if CPXRES is true, as well as either sum or new f(n) is complex
            }

            if (!changedOverToComplex) {
                fnToReal(NOPARAM);
                if (lastErrorCode != ERROR_NONE) {
                    break;
                }
                real34ToReal(registerReal34Ptr(REGISTER_X), &resultX); // Result accumulated
                if (prod) {
                    realMultiply(&resultR, &resultX, &resultR, &ctxtReal75);
                } else {
                    realAdd(&resultR, &resultX, &resultR, &ctxtReal75);
                }
            } else { // dtComplex34
                real34ToReal(registerReal34Ptr(REGISTER_X), &resultX); // Result accumulated
                real34ToReal(registerImag34Ptr(REGISTER_X), &resultXi); // Result accumulated
                if (prod) {
                    mulComplexComplex(&resultR, &resultRi, &resultX, &resultXi, &resultR, &resultRi, &ctxtReal75);
                } else {
                    realAdd(&resultR, &resultX, &resultR, &ctxtReal75);
                    realAdd(&resultRi, &resultXi, &resultRi, &ctxtReal75);
                }
            }

            real34Add(&counter, &loopStep, &counter);

            if (finished == 0) {
                break;
            }
        } // WHILE

        if (lastErrorCode == ERROR_NONE) {
            if (!changedOverToComplex) {
                if (getRegisterDataType(REGISTER_X) != dtReal34) {
                    reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
                }
                convertRealToReal34ResultRegister(&resultR, REGISTER_X);
            } else {
                if (getRegisterDataType(REGISTER_X) != dtComplex34) {
                    reallocateRegister(REGISTER_X, dtComplex34, 0, amNone);
                }
                convertRealToReal34ResultRegister(&resultR, REGISTER_X);
                convertRealToImag34ResultRegister(&resultRi, REGISTER_X);
            }
            adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
        } else {
            displayCalcErrorMessage(lastErrorCode, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnError("In function _programmableSumProd:", "Error or exit while calculating", null, null);
        }

        temporaryInformation = TI_NO_INFO;
        if (programRunStop == PGM_WAITING) {
            programRunStop = PGM_STOPPED;
        }
    } // MAIN IF

    currentSolverNestingDepth -= 1;
    if (currentSolverNestingDepth == 0) {
        clearSystemFlag(FLAG_SOLVING);
    }
}

// ===========================================================================
// _checkArgument
// ===========================================================================
fn _checkArgument(label_in: u16, prod: bool_t) linksection(runtime.code_section) void {
    var label = label_in;
    if (FIRST_LABEL <= label and label <= LAST_LABEL) {
        _programmableSumProd(label, prod);
    } else if (REGISTER_X <= @as(calcRegister_t, @intCast(label)) and @as(calcRegister_t, @intCast(label)) <= REGISTER_T) {
        // Interactive mode
        var buf: [2]u8 = undefined;
        buf[0] = letteredRegisterName(@intCast(label));
        buf[1] = 0;
        label = @bitCast(@as(i16, @truncate(findNamedLabel(@ptrCast(&buf[0])))));
        if (label == INVALID_VARIABLE) {
            displayCalcErrorMessage(ERROR_LABEL_NOT_FOUND, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnError("In function _checkArgument:", "string is not a named label", null, null);
        } else {
            _programmableSumProd(label, prod);
        }
    } else {
        displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function _checkArgument:", "unexpected parameter", null, null);
    }
}

pub export fn z47_solver_fnProgrammableSum(label: u16) linksection(runtime.code_section) callconv(.c) void {
    _checkArgument(label, false);
}

pub export fn z47_solver_fnProgrammableProduct(label: u16) linksection(runtime.code_section) callconv(.c) void {
    _checkArgument(label, true);
}
