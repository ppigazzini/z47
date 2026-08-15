// SPDX-License-Identifier: GPL-3.0-only
const consts = abi.constants;
//
// Zig owner for src/c47/solver/sumprod.c: the programmable Sigma / Pi
// (fnProgrammableSum / fnProgrammableSumInf / fnProgrammableProduct). This file is
// UNCOVERED by the testSuite (no test gate) - it is verified by build only. Faithful
// line-by-line translation preserving the exact order of every real_t / real34_t
// operation.
//
// The three entry points are exported as z47_solver_fnProgrammableSum,
// z47_solver_fnProgrammableSumInf and z47_solver_fnProgrammableProduct; those are
// the symbols solve.zig's dispatcher calls. The static
// _programmableSumProd / _checkArgument become private. showProgressReal is also
// defined in sumprod.c and is used by graph.c, so it is re-exported here.
//
// The progress display (showProgressReal, guarded by ENABLE_SOLVER_PROGRESS == 1)
// paints through the shared progress-panel owner; it has no effect on the
// computed stack result, and the control-flow functions around it
// (progressHalfSecUpdate_Integer, checkHalfSec) run either way so the
// programRunStop and flag side effects are preserved. The VERBOSE_COUNTER debug blocks are #undef'd in the C
// and are omitted. EXTRA_INFO_ON_CALC_ERROR sprintf hints become fixed
// moreInfoOnError strings (no-op under TESTSUITE/DMCP).

const runtime = @import("solve_runtime.zig");
const progress_panel = @import("progress_panel.zig");

// DECNUMDIGITS=75, DECDPUN=3 => DECNUMUNITS=ceil(75/3)=25; decNumberUnit=u16.
const abi = @import("abi"); // shared ABI bindings
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
extern fn __gmpz_set_ui(rop: *mpz_struct, op: c_ulong) void;
extern fn convertLongIntegerToLongIntegerRegister(longInteger: *const mpz_struct, regist: calcRegister_t) void;

inline fn longIntegerInit(op: *mpz_struct) void {
    __gmpz_init(op);
}
inline fn uInt32ToLongInteger(source: u32, destination: *mpz_struct) void {
    __gmpz_set_ui(destination, source);
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
const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN: u8 = 1;
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
extern var significantDigits: u8;

extern var ctxtReal75: realContext_t;
extern var ctxtReal34: realContext_t;
extern fn decimal128FromNumber(dest: *align(1) real34_t, src: *align(1) const real_t, ctxt: *realContext_t) *align(1) real34_t;

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
const const_10 = consts.const_10;

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
extern fn decNumberDivide(res: *real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *real_t;
// realType.h macros, not functions.
inline fn realSetPositiveSign(value: *real_t) void {
    value.bits &= 0x7F;
}
inline fn realDivide(dividend: *align(1) const real_t, divisor: *align(1) const real_t, quotient: *real_t, real_context: *realContext_t) void {
    _ = decNumberDivide(quotient, dividend, divisor, real_context);
}
extern fn realPower(base: *align(1) const real_t, exponent: *align(1) const real_t, result: *real_t, real_context: *realContext_t) void;
extern fn int32ToReal(source: i32, destination: *real_t) void;
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
extern fn reallocateRegister(regist: calcRegister_t, data_type: u32, data_len: u16, tag: u32) void;
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
const GLOBAL_LABELS: u8 = 253; // namedLabels_t: STRING_LABEL_VARIABLE
extern fn findNamedLabel(label_name: [*:0]const u8, label_type: u8) calcRegister_t;
extern fn letteredRegisterName(regist: calcRegister_t) u8;

const checkHalfSec = abi.host.checkHalfSec; // routed through the host-callback boundary
const progressHalfSecUpdate_Integer = abi.host.progressHalfSecUpdate_Integer; // routed through the host-callback boundary

// ===========================================================================
// showProgressReal: the running sum or product, real or complex. Exported
// because the grapher calls it too.
// ===========================================================================
pub export fn showProgressReal(a: *const real_t, ai: *real_t, cpx: bool_t) linksection(runtime.code_section) callconv(.c) void {
    var a34: real34_t = undefined;
    var ai34: real34_t = undefined;
    _ = decimal128FromNumber(&a34, a, &ctxtReal34);
    if (cpx) {
        _ = decimal128FromNumber(&ai34, ai, &ctxtReal34);
    }
    progress_panel.showRealPartial(&a34, &ai34, cpx);
}

// ===========================================================================
// Early abort, reached through the infinity sum only: the passes still to come
// cannot reach the last digit of the answer, so the run stops. Real sums only.
// ===========================================================================
const EARLY_ABORT_WATCH_FROM: u32 = 10; // first iteration whose term is judged; anything before it is ignored
const EARLY_ABORT_NOT_BEFORE: u32 = 50; // earliest iteration a run may stop on
// The test needs a magnitude, so a complex run counts to the end. Kept as a named
// constant because the complex accumulation branch below is written to it.
const EARLY_ABORT_IN_COMPLEX: bool = false;

// What _checkArgument and _programmableSumProd do with each term.
const SUMMING: bool_t = false;
const MULTIPLYING: bool_t = true;
// No early-stop state, so every iteration the caller asked for.
const RUNALL: ?*EarlyAbort = null;

/// Only the infinity sum carries this, on its own frame.
const EarlyAbort = struct {
    previousTerm: real_t,
    term: real_t,
    remaining: real_t,
    allowance: real_t,
    scale: real_t,
    haveTerm: bool_t,
    falling: bool_t,
    pass: u32,
};

// ===========================================================================
// _programmableSumProd
// ===========================================================================
fn _programmableSumProd(label: u16, prod: bool_t, early: ?*EarlyAbort) linksection(runtime.code_section) void {
    currentKeyCode = 255;
    const inf = runtime.option_infsums and early != null;
    // Read once: the term program itself can set CPXRES.
    const cpxAllowed = getFlag(FLAG_CPXRES);
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

        if (inf) {
            const e = early.?;
            realSetZero(&e.previousTerm);
            e.haveTerm = false;
            e.falling = true;
            e.pass = 0;
            int32ToReal(if (significantDigits == 0) 34 else significantDigits, &e.scale);
            realPower(const_10(), &e.scale, &e.scale, &ctxtReal75); // 10^SDIGS, fixed for the run
        }

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

            if (getRegisterDataType(REGISTER_X) == dtComplex34 or !realIsZero(&resultRi)) {
                if (cpxAllowed) {
                    changedOverToComplex = true; // Only latch over to complex operation if CPXRES is true, as well as either sum or new f(n) is complex
                } else {
                    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
                    moreInfoOnError("In function _programmableSumProd:", "f(n) returned a complex value while flag I is not set!", null, null);
                    break;
                }
            }

            if (inf) { // counted for the complex branch too, and saturates
                const e = early.?;
                if (e.pass < 0xFFFFFFFF) {
                    e.pass += 1;
                }
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
                    if (inf) {
                        const e = early.?;
                        realCopy(&resultX, &e.term); // the term itself, which outlives a saturated total
                        realSetPositiveSign(&e.term);
                        if (!realIsZero(&e.term)) { // a term of zero says nothing about the terms after it
                            if (e.haveTerm and e.pass >= EARLY_ABORT_WATCH_FROM and
                                runtime.realCompareGreaterThan(&e.term, &e.previousTerm))
                            {
                                e.falling = false; // one rise after the watch point disqualifies the run
                            }
                            if (e.falling and e.pass >= EARLY_ABORT_NOT_BEFORE) {
                                real34Subtract(&loopTo, &counter, &rLoop); // iterations still to come, no integer count
                                if (!real34IsZero(&loopStep)) {
                                    real34Divide(&rLoop, &loopStep, &rLoop);
                                }
                                real34ToReal(&rLoop, &e.remaining);
                                realSetPositiveSign(&e.remaining);
                                realDivide(&resultR, &e.scale, &e.allowance, &ctxtReal75); // one last digit of the answer
                                realSetPositiveSign(&e.allowance);
                                realDivide(&e.allowance, &e.term, &e.allowance, &ctxtReal75); // iterations it is worth
                                if (runtime.realCompareLessThan(&e.remaining, &e.allowance)) {
                                    break;
                                }
                            }
                            realCopy(&e.term, &e.previousTerm);
                            e.haveTerm = true;
                        }
                    }
                }
            } else { // dtComplex34, and EARLY_ABORT_IN_COMPLEX is false, so this branch always runs the full count
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
            if (inf) { // iterations actually run, so a short run is visible
                var iPass: longInteger_t = undefined;
                longIntegerInit(&iPass[0]);
                uInt32ToLongInteger(early.?.pass, &iPass[0]);
                convertLongIntegerToLongIntegerRegister(&iPass[0], REGISTER_Y);
                longIntegerFree(&iPass[0]);
            }
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

        currentSolverNestingDepth -= 1;
        if (currentSolverNestingDepth == 0) {
            clearSystemFlag(FLAG_SOLVING);
        }
    } // MAIN IF
}

// ===========================================================================
// _checkArgument
// ===========================================================================
fn _checkArgument(label_in: u16, prod: bool_t, early: ?*EarlyAbort) linksection(runtime.code_section) void {
    const label: u16 = @bitCast(runtime.findProgramLabel(label_in, "In function _checkArgument:"));
    if (label != INVALID_VARIABLE) {
        _programmableSumProd(label, prod, early);
    }
}

pub export fn z47_solver_fnProgrammableSum(label: u16) linksection(runtime.code_section) callconv(.c) void {
    _checkArgument(label, SUMMING, RUNALL);
}

/// Reached from solve.zig's dispatcher through the module graph, not an exported
/// symbol: both files land in the same object.
pub fn programmableSumInf(label: u16) linksection(runtime.code_section) void {
    if (comptime runtime.option_infsums) {
        var earlyAbort: EarlyAbort = undefined; // this frame carries the early stop state
        _checkArgument(label, SUMMING, &earlyAbort);
    }
}

pub export fn z47_solver_fnProgrammableProduct(label: u16) linksection(runtime.code_section) callconv(.c) void {
    _checkArgument(label, MULTIPLYING, RUNALL);
}
