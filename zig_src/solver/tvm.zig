// SPDX-License-Identifier: GPL-3.0-only
const consts = abi.constants;
//
// Zig owner for src/c47/solver/tvm.c: the Time-Value-of-Money engine.
// Faithful line-by-line translation preserving the exact order of every real_t
// operation (tvm.txt / validate_tvm.txt check results to the last ULP).
//
// Exports the public TVM commands with their real C names: fnTvmVar, fnEff,
// fnEffToI, fnAmortBal, fnAmortPrn, fnAmortInt, fnAmortP, fnAmortNext, plus the
// solver callback tvmEquation (called back from solve.c's generic solve_owned.solver()).
// fnTvmBeginMode / fnTvmEndMode are NOT defined here - solve.zig owns them.
// The static helpers (doubleExp, tvmRangeError, calculateEffectiveRate,
// calculatePV/FV/PMT/NPPER/PPER/CPER, solveTvmVariable51, amort*) are private.
//
// OPTION_TVM_FORMULAS / OPTION_TVM_NEWTON / OPTION_TVM_AMORT are ported
// unconditionally (the SAVE_SPACE_DM42 undefs are DEAD for the testSuite/sim/
// dmcp5 builds). EXTRA_INFO_ON_CALC_ERROR sprintf hints become fixed
// moreInfoOnError strings (no-op under TESTSUITE/DMCP).
//
// Build-target context selection mirrors the C
//   #if defined(DMCP_BUILD) && (HARDWARE_MODEL == HWM_DM42)
// which is exactly the "dmcp" old-hw firmware package; that is the same flag
// (solve_build_options.dm42_pkg_xip) used to place this owner in QSPI XIP.

const runtime = @import("solve_runtime.zig");
const solve_build_options = @import("solve_build_options");

const dmcp_dm42 = @hasDecl(solve_build_options, "dm42_pkg_xip") and solve_build_options.dm42_pkg_xip;

// DECNUMDIGITS=75, DECDPUN=3 => DECNUMUNITS=ceil(75/3)=25; decNumberUnit=u16.
const abi = @import("abi"); // L1 shared bindings (REPORT-23 §5)
const real_t = abi.Real;
const real34_t = abi.Real34;
const realContext_t = abi.RealContext;

const calcRegister_t = runtime.calcRegister_t;

// ---------------------------------------------------------------------------
// defines.h values (verified)
//   RESERVED_VARIABLE_*  (enum starting RESERVED_VARIABLE_REALDF=2029)
//   FLAG_ENDPMT=0xc029  FLAG_SOLVING=0xc026  FLAG_ASLIFT=0xc023
//   FLAG_AMORT_HP12C=0x8011  FLAG_CPXRES=0x8004
//   TI_* / ERROR_* / SOLVER_* / PGM_* / dt* / amNone / ITM_STO / NOPARAM
// ---------------------------------------------------------------------------
const RESERVED_VARIABLE_FV: u16 = 2034;
const RESERVED_VARIABLE_IPONA: u16 = 2035;
const RESERVED_VARIABLE_NPPER: u16 = 2036;
const RESERVED_VARIABLE_PPERONA: u16 = 2037;
const RESERVED_VARIABLE_PMT: u16 = 2038;
const RESERVED_VARIABLE_PV: u16 = 2039;
const RESERVED_VARIABLE_CPERONA: u16 = 2043;

const FLAG_ENDPMT: u32 = 0xc029;
const FLAG_SOLVING: u32 = 0xc026;
const FLAG_ASLIFT: u32 = 0xc023;
const FLAG_AMORT_HP12C: i32 = 0x8011;

const ERROR_NONE: u8 = 0;
const ERROR_OUT_OF_RANGE: u8 = 8;
const ERROR_NO_ROOT_FOUND: u8 = 20;
const ERROR_SOLVER_ABORT: u8 = 60;

const REGISTER_X: calcRegister_t = 100;
const REGISTER_Z: calcRegister_t = 102;
const ERR_REGISTER_LINE: calcRegister_t = REGISTER_Z;

const TI_NO_INFO: u8 = 0;
const TI_SOLVER_VARIABLE: u8 = 51;
const TI_TVM_EFF: u8 = 115;
const TI_TVM_IA: u8 = 116;
const TI_AMORT_BAL: u8 = 137;
const TI_AMORT_PRN: u8 = 138;
const TI_AMORT_INT: u8 = 139;
const TI_AMORT_P1: u8 = 140;
const TI_AMORT_P2: u8 = 141;

const SOLVER_STATUS_READY_TO_EXECUTE: u16 = 0x0001;
const SOLVER_STATUS_TVM_APPLICATION: u16 = 0x1000;
const SOLVER_RESULT_NORMAL: u16 = 0;
const SOLVER_RESULT_CONSTANT: u16 = 4;
const SOLVER_RESULT_ABORTED: u16 = 6;

const PGM_RUNNING: u8 = 1;
const PGM_PAUSED: u8 = 3;

const dtReal34: u32 = 1;
const amNone: u32 = 5;
const ITM_STO: i16 = 44;
const NOPARAM: u16 = 9876;

const DEC_ROUND_HALF_UP: u32 = 2; // 0.5 rounds up

const testing: bool = @hasDecl(solve_build_options, "is_testsuite_build") and solve_build_options.is_testsuite_build;

// ---------------------------------------------------------------------------
// Globals
// ---------------------------------------------------------------------------
extern var lastErrorCode: u8;
extern var temporaryInformation: u8;
extern var programRunStop: u8;
extern var thereIsSomethingToUndo: bool;
extern var tvmIKnown: bool;
extern var tvmIChanges: bool;
extern var currentSolverStatus: u16;
extern var currentSolverVariable: u16;
extern var amortP1: u16;
extern var amortP2: u16;

extern var ctxtReal39: realContext_t;
extern var ctxtReal51: realContext_t;
extern var ctxtReal34: realContext_t;

// ---------------------------------------------------------------------------
// Module-local 42-digit context (DMCP build only; mirrors ctxtTvm42 in tvm.c).
// ---------------------------------------------------------------------------
var ctxtTvm42: realContext_t = std.mem.zeroes(realContext_t);
const std = @import("std");
const solve_owned = @import("solve_owned.zig"); // M-callconv: Zig-to-Zig

inline fn ensureTvmContext() void {
    if (ctxtTvm42.digits == 0) {
        ctxtTvm42 = ctxtReal39;
        ctxtTvm42.digits = 42;
    }
}

// Context selection: DMCP DM42 firmware vs. everything else.
inline fn ctxtTvm() *realContext_t {
    return if (dmcp_dm42) &ctxtReal39 else &ctxtReal51;
}
inline fn ctxtTvmHi() *realContext_t {
    return if (dmcp_dm42) &ctxtTvm42 else &ctxtReal51;
}
inline fn ctxtSolverTvmHi() *realContext_t {
    return if (dmcp_dm42) &ctxtTvm42 else &ctxtReal51;
}
inline fn ctxtSolverTvmInv() *realContext_t {
    return &ctxtReal51;
}

// ---------------------------------------------------------------------------
// Constants blob accessors (offsets verified from generated constantPointers.h)
// ---------------------------------------------------------------------------
const cstR = consts.cstR;
const cst34 = consts.cst34;

inline fn const_0() *align(1) const real_t {
    return consts.c1708();
}
inline fn const__1() *align(1) const real_t {
    return consts.c4376();
}
inline fn const_1e_37() *align(1) const real_t {
    return consts.c4436();
}
inline fn const_1on10() *align(1) const real_t {
    return consts.c4520();
}
inline fn const_1on2() *align(1) const real_t {
    return consts.c4580();
}
inline fn const_1() *align(1) const real_t {
    return consts.c4856();
}
inline fn const_100() *align(1) const real_t {
    return consts.c7532();
}

inline fn const34_0() *align(1) const real34_t {
    return consts.q16200();
}
inline fn const34_1e_4() *align(1) const real34_t {
    return consts.q16264();
}
inline fn const34_1on10() *align(1) const real34_t {
    return consts.q16280();
}
inline fn const34_1on2() *align(1) const real34_t {
    return consts.q16296();
}
inline fn const34_1() *align(1) const real34_t {
    return consts.q16312();
}
inline fn const34_2() *align(1) const real34_t {
    return consts.q16328();
}
inline fn const34_3() *align(1) const real34_t {
    return consts.q16344();
}
inline fn const34_7() *align(1) const real34_t {
    return consts.q16392();
}
inline fn const34_9() *align(1) const real34_t {
    return consts.q16408();
}
inline fn const34_24() *align(1) const real34_t {
    return consts.q16472();
}

// ---------------------------------------------------------------------------
// decNumber primitives / real_t macro reproductions (realType.h)
// ---------------------------------------------------------------------------
extern fn decNumberCopy(res: *real_t, source: *align(1) const real_t) *real_t;
extern fn decNumberAdd(res: *real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberSubtract(res: *real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberMultiply(res: *real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberDivide(res: *real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberFMA(res: *real_t, f1: *align(1) const real_t, f2: *align(1) const real_t, term: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberExp(res: *real_t, rhs: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberFromInt32(res: *real_t, source: i32) *real_t;
extern fn decNumberFromUInt32(res: *real_t, source: u32) *real_t;
extern fn decNumberFromString(res: *real_t, source: [*:0]const u8, ctxt: *realContext_t) *real_t;
extern fn realToIntegralValue(source: *const real_t, destination: *real_t, mode: u32, ctxt: *realContext_t) void;

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
inline fn realChangeSign(operand: *real_t) void {
    operand.bits ^= 0x80;
}
inline fn realIsZero(source: *const real_t) bool {
    return decNumberIsZero(source);
}
inline fn realIsPositive(source: *const real_t) bool {
    return (source.bits & 0x80) == 0x00;
}
inline fn int32ToReal(source: i32, destination: *real_t) void {
    _ = decNumberFromInt32(destination, source);
}
inline fn uInt32ToReal(source: u32, destination: *real_t) void {
    _ = decNumberFromUInt32(destination, source);
}
inline fn stringToReal(source: [*:0]const u8, destination: *real_t, ctxt: *realContext_t) void {
    _ = decNumberFromString(destination, source, ctxt);
}

extern fn realSetOne(value: *real_t) void;
extern fn realSetZero(value: *real_t) void;
extern fn realSetNaN(value: *real_t) void;
extern fn realCompareEqual(number1: *align(1) const real_t, number2: *align(1) const real_t) bool;
extern fn realCompareLessThan(number1: *align(1) const real_t, number2: *align(1) const real_t) bool;
extern fn realCompareAbsLessThan(number1: *align(1) const real_t, number2: *align(1) const real_t) bool;
extern fn realExp(x: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void;
extern fn roundToSignificantDigits(source: *const real_t, destination: *real_t, digits: i32, ctxt: *realContext_t) void;
extern fn realToUint32C47(r: *const real_t, err: ?*bool) u32;

// WP34S real-op helpers (math_wp34s.zig exports).
extern fn WP34S_Ln(x: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void;
extern fn WP34S_Ln1P(x: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void;
extern fn WP34S_ExpM1(x: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void;

// ---------------------------------------------------------------------------
// real34_t macro reproductions (realType.h)
// ---------------------------------------------------------------------------
extern fn decimal128ToNumber(source: *align(1) const real34_t, destination: *real_t) *real_t;
// decQuadFromNumber is a macro for decimal128FromNumber (decQuad.h).
extern fn decimal128FromNumber(dest: *align(1) real34_t, src: *const real_t, ctxt: *realContext_t) *align(1) real34_t;
extern fn decQuadAdd(res: *align(1) real34_t, op1: *align(1) const real34_t, op2: *align(1) const real34_t, ctxt: *realContext_t) *align(1) real34_t;
extern fn decQuadSubtract(res: *align(1) real34_t, op1: *align(1) const real34_t, op2: *align(1) const real34_t, ctxt: *realContext_t) *align(1) real34_t;
extern fn decQuadMultiply(res: *align(1) real34_t, op1: *align(1) const real34_t, op2: *align(1) const real34_t, ctxt: *realContext_t) *align(1) real34_t;
extern fn decQuadDivide(res: *align(1) real34_t, op1: *align(1) const real34_t, op2: *align(1) const real34_t, ctxt: *realContext_t) *align(1) real34_t;
extern fn decQuadFromInt32(dest: *align(1) real34_t, source: i32) *align(1) real34_t;
extern fn decQuadZero(dest: *align(1) real34_t) *align(1) real34_t;
extern fn decQuadIsZero(source: *align(1) const real34_t) bool;
extern fn decQuadToUInt32(source: *align(1) const real34_t, ctxt: *realContext_t, mode: u32) u32;

const DEC_ROUND_DOWN: u32 = 5;

inline fn real34ToReal(source: *align(1) const real34_t, destination: *real_t) void {
    _ = decimal128ToNumber(source, destination);
}
inline fn realToReal34(source: *const real_t, destination: *align(1) real34_t) void {
    _ = decimal128FromNumber(destination, source, &ctxtReal34);
}
inline fn real34Copy(source: *align(1) const real34_t, destination: *align(1) real34_t) void {
    const src: *align(1) const [2]u64 = @ptrCast(source);
    const dst: *align(1) [2]u64 = @ptrCast(destination);
    dst[0] = src[0];
    dst[1] = src[1];
}
inline fn real34Multiply(op1: *align(1) const real34_t, op2: *align(1) const real34_t, res: *align(1) real34_t) void {
    _ = decQuadMultiply(res, op1, op2, &ctxtReal34);
}
inline fn real34Add(op1: *align(1) const real34_t, op2: *align(1) const real34_t, res: *align(1) real34_t) void {
    _ = decQuadAdd(res, op1, op2, &ctxtReal34);
}
inline fn real34Subtract(op1: *align(1) const real34_t, op2: *align(1) const real34_t, res: *align(1) real34_t) void {
    _ = decQuadSubtract(res, op1, op2, &ctxtReal34);
}
inline fn real34SetZero(destination: *align(1) real34_t) void {
    _ = decQuadZero(destination);
}
inline fn real34SetOne(destination: *align(1) real34_t) void {
    _ = decQuadFromInt32(destination, 1);
}
inline fn real34IsZero(source: *align(1) const real34_t) bool {
    return decQuadIsZero(source);
}
inline fn real34IsNegative(source: *align(1) const real34_t) bool {
    return (source.bytes[15] & 0x80) == 0x80;
}
inline fn real34ChangeSign(operand: *align(1) real34_t) void {
    operand.bytes[15] ^= 0x80;
}
inline fn real34ToUInt32(source: *align(1) const real34_t) u32 {
    return decQuadToUInt32(source, &ctxtReal34, DEC_ROUND_DOWN);
}

extern fn real34CompareEqual(number1: *align(1) const real34_t, number2: *align(1) const real34_t) bool;
extern fn real34CompareLessThan(number1: *align(1) const real34_t, number2: *align(1) const real34_t) bool;
extern fn real34CompareAbsLessThan(number1: *align(1) const real34_t, number2: *align(1) const real34_t) bool;

// ---------------------------------------------------------------------------
// Register / stack / flag externs
// ---------------------------------------------------------------------------
extern fn getRegisterDataPointer(reg: calcRegister_t) ?*anyopaque;
// Accepts either the i16 register id or a u16 RESERVED_VARIABLE_* tag (the C
// macro implicitly narrows the uint16_t argument to calcRegister_t).
inline fn registerReal34Ptr(reg: anytype) *align(1) real34_t {
    const r: calcRegister_t = @bitCast(@as(u16, @intCast(reg)));
    return @ptrCast(getRegisterDataPointer(r).?);
}

extern fn reallocateRegister(regist: calcRegister_t, data_type: u32, data_len: u32, tag: u32) void;
extern fn convertRealToReal34ResultRegister(real: *const real_t, dest: calcRegister_t) void;
extern fn getRegisterAsReal(reg: calcRegister_t, val: *real_t) bool;
extern fn getRegisterAsRealQuiet(reg: calcRegister_t, val: *real_t) bool;

extern fn getFlag(flag: u16) bool;
extern fn getSystemFlag(sf: i32) bool;
extern fn setSystemFlag(sf: c_uint) void;
extern fn saveForUndo() void;
extern fn liftStack() void;
extern fn fnToReal(unused: u16) void;
extern fn reallyRunFunction(func: i16, param: u16) void;
extern fn adjustResult(res: calcRegister_t, drop_y: bool, set_cpx_res: bool, op1: calcRegister_t, op2: calcRegister_t, op3: calcRegister_t) void;
extern fn displayCalcErrorMessage(error_code: u8, err_message_register_line: calcRegister_t, err_register_line: calcRegister_t) void;
extern fn displayBugScreen(msg: [*:0]const u8) void;
extern fn moreInfoOnError(m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) void;
extern fn exitKeyWaiting() bool;

// Generic solver (stays C in solve.c). Returns int; C reads it as uint16_t.

// ===========================================================================
// doubleExp: e^x and e^x-1 (WP34S_ExpM1 internal logic)
// ===========================================================================
fn doubleExp(x: *const real_t, exp: *real_t, expm1: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var v: real_t = undefined;
    var w: real_t = undefined;

    _ = decNumberExp(exp, x, realContext);

    // Code from WP34S_ExpM1 to get accurate result for e^x-1
    realSubtract(exp, const_1(), &v, realContext);
    if (realIsZero(&v)) { // |x| is very little
        realCopy(x, expm1);
    } else if (realCompareEqual(&v, const__1())) {
        realCopy(const__1(), expm1);
    } else if (realCompareAbsLessThan(x, const_1on10())) {
        realMultiply(&v, x, &w, realContext);
        WP34S_Ln(exp, &v, realContext);
        realDivide(&w, &v, expm1, realContext);
    } else {
        realCopy(&v, expm1);
    }
}

// ===========================================================================
// OPTION_TVM_FORMULAS section
// ===========================================================================
fn tvmRangeError(errorCode: c_int) linksection(runtime.code_section) c_int {
    displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
    moreInfoOnError("In function tvmRangeError:", "TVM out of range error", " Out of range error", null);
    return errorCode;
}

fn calculateEffectiveRate(iPercentPerYear: *const real_t, compoundPerYear: *const real_t, paymentPerYear: *const real_t, ip: *real_t, err: *c_int) linksection(runtime.code_section) void {
    ensureTvmContext();
    var ic: real_t = undefined;
    var temp: real_t = undefined;
    var exponent: real_t = undefined;

    if (decNumberIsZero(compoundPerYear)) {
        err.* = tvmRangeError(6);
        return;
    }
    if (decNumberIsZero(paymentPerYear)) {
        err.* = tvmRangeError(5);
        return;
    }

    realDivide(iPercentPerYear, const_100(), &ic, ctxtTvm());
    realDivide(&ic, compoundPerYear, &ic, ctxtTvm());

    realSubtract(compoundPerYear, paymentPerYear, &temp, ctxtTvm());
    if (decNumberIsZero(&temp)) {
        realCopy(&ic, ip);
        err.* = 0;
        return;
    }

    realDivide(compoundPerYear, paymentPerYear, &exponent, ctxtTvm());

    {
        var temp2: real_t = undefined;
        WP34S_Ln1P(&ic, &temp2, ctxtTvmHi());
        realMultiply(&temp2, &exponent, &temp2, ctxtTvmHi());
        WP34S_ExpM1(&temp2, ip, ctxtTvmHi());
    }

    err.* = 0;
}

fn calculatePV(fv: *const real_t, iPercentPerYear: *const real_t, npper: *const real_t, paymentPerYear: *const real_t, pmt: *const real_t, compoundPerYear: *const real_t, p: *const real_t, pv: *real_t) linksection(runtime.code_section) c_int {
    ensureTvmContext();
    var ip: real_t = undefined;
    var temp1: real_t = undefined;
    var temp2: real_t = undefined;
    var temp3: real_t = undefined;
    var negNpper: real_t = undefined;
    var powerTerm: real_t = undefined;
    var annuityFactor: real_t = undefined;
    var err: c_int = 0;

    calculateEffectiveRate(iPercentPerYear, compoundPerYear, paymentPerYear, &ip, &err);
    if (err != 0) {
        return err;
    }

    if (realCompareAbsLessThan(&ip, const_1e_37())) {
        realFMA(pmt, npper, fv, pv, ctxtTvm());
        realChangeSign(pv);
        return 0;
    }

    realCopy(npper, &negNpper);
    realChangeSign(&negNpper);
    WP34S_Ln1P(&ip, &temp2, ctxtTvm());
    realMultiply(&temp2, &negNpper, &temp2, ctxtTvm());
    doubleExp(&temp2, &powerTerm, &temp1, ctxtTvm());
    realChangeSign(&temp1);

    realDivide(&temp1, &ip, &annuityFactor, ctxtTvm());

    realFMA(&ip, p, const_1(), &temp2, ctxtTvm());

    realMultiply(&temp2, pmt, &temp1, ctxtTvm());
    realMultiply(&temp1, &annuityFactor, &temp3, ctxtTvm());

    realFMA(fv, &powerTerm, &temp3, pv, ctxtTvm());
    realChangeSign(pv);

    return 0;
}

fn calculateFV(pv: *const real_t, iPercentPerYear: *const real_t, npper: *const real_t, paymentPerYear: *const real_t, pmt: *const real_t, compoundPerYear: *const real_t, p: *const real_t, fv: *real_t) linksection(runtime.code_section) c_int {
    ensureTvmContext();
    var ip: real_t = undefined;
    var temp1: real_t = undefined;
    var temp2: real_t = undefined;
    var temp3: real_t = undefined;
    var powerTerm: real_t = undefined;
    var annuityFactor: real_t = undefined;
    var err: c_int = 0;

    calculateEffectiveRate(iPercentPerYear, compoundPerYear, paymentPerYear, &ip, &err);
    if (err != 0) {
        return err;
    }

    if (realCompareAbsLessThan(&ip, const_1e_37())) {
        realFMA(pmt, npper, pv, fv, ctxtTvm());
        realChangeSign(fv);
        return 0;
    }

    {
        var temp_ln: real_t = undefined;
        WP34S_Ln1P(&ip, &temp_ln, ctxtTvm());
        realMultiply(&temp_ln, npper, &temp_ln, ctxtTvm());
        doubleExp(&temp_ln, &powerTerm, &temp2, ctxtTvm());
    }

    realMultiply(pv, &powerTerm, &temp1, ctxtTvm());
    realChangeSign(&temp1);

    realDivide(&temp2, &ip, &annuityFactor, ctxtTvm());

    realFMA(&ip, p, const_1(), &temp3, ctxtTvm());

    realMultiply(&temp3, pmt, &temp2, ctxtTvm());
    realChangeSign(&temp1);
    realFMA(&temp2, &annuityFactor, &temp1, fv, ctxtTvm());
    realChangeSign(fv);

    return 0;
}

fn calculatePMT(pv: *const real_t, fv: *const real_t, iPercentPerYear: *const real_t, npper: *const real_t, paymentPerYear: *const real_t, compoundPerYear: *const real_t, p: *const real_t, pmt: *real_t) linksection(runtime.code_section) c_int {
    ensureTvmContext();
    var ip: real_t = undefined;
    var temp1: real_t = undefined;
    var temp2: real_t = undefined;
    var temp3: real_t = undefined;
    var negNpper: real_t = undefined;
    var powerTerm: real_t = undefined;
    var numerator: real_t = undefined;
    var denominator: real_t = undefined;
    var err: c_int = 0;

    if (decNumberIsZero(npper)) {
        return tvmRangeError(2);
    }

    calculateEffectiveRate(iPercentPerYear, compoundPerYear, paymentPerYear, &ip, &err);
    if (err != 0) {
        return err;
    }

    if (realCompareAbsLessThan(&ip, const_1e_37())) {
        realAdd(pv, fv, &temp1, ctxtTvm());
        realDivide(&temp1, npper, pmt, ctxtTvm());
        realChangeSign(pmt);
        return 0;
    }

    realCopy(npper, &negNpper);
    realChangeSign(&negNpper);
    {
        var temp_ln: real_t = undefined;
        WP34S_Ln1P(&ip, &temp_ln, ctxtTvm());
        realMultiply(&temp_ln, &negNpper, &temp_ln, ctxtTvm());
        doubleExp(&temp_ln, &powerTerm, &temp3, ctxtTvm());
        realChangeSign(&temp3);
    }

    realFMA(fv, &powerTerm, pv, &temp2, ctxtTvm());
    realMultiply(&temp2, &ip, &numerator, ctxtTvm());
    realChangeSign(&numerator);

    realFMA(&ip, p, const_1(), &temp2, ctxtTvm());
    realMultiply(&temp2, &temp3, &denominator, ctxtTvm());

    if (decNumberIsZero(&denominator)) {
        return tvmRangeError(0);
    }

    realDivide(&numerator, &denominator, pmt, ctxtTvm());

    return 0;
}

fn calculateNPPER(pv: *const real_t, fv: *const real_t, iPercentPerYear: *const real_t, paymentPerYear: *const real_t, pmt: *const real_t, compoundPerYear: *const real_t, p: *const real_t, npper: *real_t) linksection(runtime.code_section) c_int {
    ensureTvmContext();
    var ip: real_t = undefined;
    var temp1: real_t = undefined;
    var temp2: real_t = undefined;
    var a: real_t = undefined;
    var b: real_t = undefined;
    var ratio: real_t = undefined;
    var lnRatio: real_t = undefined;
    var lnBase: real_t = undefined;
    var err: c_int = 0;

    calculateEffectiveRate(iPercentPerYear, compoundPerYear, paymentPerYear, &ip, &err);
    if (err != 0) {
        return err;
    }

    if (realCompareAbsLessThan(&ip, const_1e_37())) {
        if (decNumberIsZero(pmt)) {
            return tvmRangeError(0);
        }
        realAdd(pv, fv, &temp1, ctxtTvm());
        realDivide(&temp1, pmt, npper, ctxtTvm());
        realChangeSign(npper);
        return 0;
    }

    if (decNumberIsZero(pmt)) {
        if (decNumberIsZero(pv)) {
            return tvmRangeError(7);
        }

        realDivide(fv, pv, &ratio, ctxtTvm());
        realChangeSign(&ratio);

        if (!realIsPositive(&ratio)) {
            return tvmRangeError(4);
        }

        WP34S_Ln(&ratio, &lnRatio, ctxtTvm());
        WP34S_Ln1P(&ip, &lnBase, ctxtTvm());

        if (decNumberIsZero(&lnBase)) {
            return tvmRangeError(0);
        }

        realDivide(&lnRatio, &lnBase, npper, ctxtTvm());
        return 0;
    }

    realMultiply(fv, &ip, &temp1, ctxtTvm());
    realChangeSign(&temp1);
    realFMA(&ip, p, const_1(), &temp2, ctxtTvm());
    realFMA(pmt, &temp2, &temp1, &a, ctxtTvm());

    realMultiply(pv, &ip, &temp1, ctxtTvm());
    realFMA(pmt, &temp2, &temp1, &b, ctxtTvm());

    if (decNumberIsZero(&b)) {
        return tvmRangeError(0);
    }

    realDivide(&a, &b, &ratio, ctxtTvm());

    if (!realIsPositive(&ratio)) {
        return tvmRangeError(3);
    }

    WP34S_Ln(&ratio, &lnRatio, ctxtTvm());
    WP34S_Ln1P(&ip, &lnBase, ctxtTvm());

    if (decNumberIsZero(&lnBase)) {
        return tvmRangeError(0);
    }

    realDivide(&lnRatio, &lnBase, npper, ctxtTvm());

    return 0;
}

fn calculatePPER(pv: *const real_t, fv: *const real_t, iPercentPerYear: *const real_t, npper: *const real_t, pmt: *const real_t, compoundPerYear: *const real_t, p: *const real_t, paymentPerYear: *real_t) linksection(runtime.code_section) c_int {
    _ = p;
    ensureTvmContext();
    var ic: real_t = undefined;
    var temp1: real_t = undefined;
    var temp2: real_t = undefined;
    var lnBase: real_t = undefined;
    var lnTarget: real_t = undefined;
    var ratio: real_t = undefined;
    var ip_effective: real_t = undefined;

    if (decNumberIsZero(compoundPerYear)) {
        return tvmRangeError(6);
    }

    realDivide(iPercentPerYear, const_100(), &ic, ctxtTvm());
    realDivide(&ic, compoundPerYear, &ic, ctxtTvm());

    if (decNumberIsZero(pmt)) {
        if (decNumberIsZero(pv)) {
            return tvmRangeError(7);
        }
        if (decNumberIsZero(npper)) {
            return tvmRangeError(2);
        }

        realDivide(fv, pv, &temp1, ctxtTvm());
        realChangeSign(&temp1);

        if (!realIsPositive(&temp1)) {
            return tvmRangeError(3);
        }

        realDivide(const_1(), npper, &temp2, ctxtTvm());
        {
            var temp_ln: real_t = undefined;
            WP34S_Ln(&temp1, &temp_ln, ctxtTvm());
            realMultiply(&temp_ln, &temp2, &temp_ln, ctxtTvm());
            WP34S_ExpM1(&temp_ln, &ip_effective, ctxtTvm());
        }
    } else {
        return tvmRangeError(3);
    }

    if (realCompareAbsLessThan(&ic, const_1e_37())) {
        return tvmRangeError(3);
    }

    realSubtract(&ip_effective, &ic, &temp1, ctxtTvm());
    if (realCompareAbsLessThan(&temp1, const_1e_37())) {
        realCopy(compoundPerYear, paymentPerYear);
        return 0;
    }

    realAdd(&ic, const_1(), &temp1, ctxtTvm());
    if (!realIsPositive(&temp1)) {
        return tvmRangeError(4);
    }
    WP34S_Ln1P(&ic, &lnBase, ctxtTvm());

    realAdd(&ip_effective, const_1(), &temp1, ctxtTvm());
    if (!realIsPositive(&temp1)) {
        return tvmRangeError(4);
    }
    WP34S_Ln1P(&ip_effective, &lnTarget, ctxtTvm());

    if (decNumberIsZero(&lnTarget)) {
        return tvmRangeError(0);
    }

    realDivide(&lnBase, &lnTarget, &ratio, ctxtTvm());
    realMultiply(compoundPerYear, &ratio, paymentPerYear, ctxtTvm());

    if (!realIsPositive(paymentPerYear)) {
        return tvmRangeError(3);
    }

    return 0;
}

fn calculateCPER(pv: *const real_t, fv: *const real_t, iPercentPerYear: *const real_t, npper: *const real_t, paymentPerYear: *const real_t, pmt: *const real_t, p: *const real_t, compoundPerYear: *real_t) linksection(runtime.code_section) c_int {
    _ = p;
    ensureTvmContext();
    var ip: real_t = undefined;
    var ic: real_t = undefined;
    var temp1: real_t = undefined;
    var temp2: real_t = undefined;
    var exponent: real_t = undefined;
    var test_ip: real_t = undefined;
    var error_val: real_t = undefined;
    var tolerance: real_t = undefined;
    var iterations: c_int = 0;
    const maxIterations: c_int = 100;

    if (decNumberIsZero(paymentPerYear)) {
        return tvmRangeError(5);
    }

    if (decNumberIsZero(pmt)) {
        if (decNumberIsZero(pv)) {
            return tvmRangeError(7);
        }
        if (decNumberIsZero(npper)) {
            return tvmRangeError(2);
        }

        realDivide(fv, pv, &temp1, ctxtTvm());
        realChangeSign(&temp1);

        if (!realIsPositive(&temp1)) {
            return tvmRangeError(3);
        }

        realDivide(const_1(), npper, &temp2, ctxtTvm());
        {
            var temp_ln: real_t = undefined;
            WP34S_Ln(&temp1, &temp_ln, ctxtTvm());
            realMultiply(&temp_ln, &temp2, &temp_ln, ctxtTvm());
            WP34S_ExpM1(&temp_ln, &ip, ctxtTvm());
        }
    } else {
        return tvmRangeError(9);
    }

    stringToReal("1e-36", &tolerance, ctxtTvm());

    realCopy(paymentPerYear, compoundPerYear);

    iterations = 0;
    while (iterations < maxIterations) : (iterations += 1) {
        realDivide(iPercentPerYear, const_100(), &ic, ctxtTvm());
        realDivide(&ic, compoundPerYear, &ic, ctxtTvm());

        realDivide(compoundPerYear, paymentPerYear, &exponent, ctxtTvm());

        {
            var temp_exp: real_t = undefined;
            WP34S_Ln1P(&ic, &temp_exp, ctxtTvm());
            realMultiply(&temp_exp, &exponent, &temp_exp, ctxtTvm());
            WP34S_ExpM1(&temp_exp, &test_ip, ctxtTvm());
        }

        realSubtract(&test_ip, &ip, &error_val, ctxtTvm());

        if (realCompareAbsLessThan(&error_val, &tolerance)) {
            return 0;
        }

        {
            var temp2b: real_t = undefined;
            realDivide(&error_val, &ip, &temp1, ctxtTvm());
            realChangeSign(&temp1);
            realFMA(&temp1, const_1on2(), const_1(), &temp2b, ctxtTvm());
            realMultiply(compoundPerYear, &temp2b, compoundPerYear, ctxtTvm());
        }
        if (!realIsPositive(compoundPerYear)) {
            realCopy(paymentPerYear, compoundPerYear);
        }
    }

    return tvmRangeError(3);
}

const bugScreenNotForTvmVar: [*:0]const u8 = "In function solveTvmVariable51: this variable is not intended for TVM application!";

fn solveTvmVariable51(variable: u16) linksection(runtime.code_section) c_int {
    ensureTvmContext();
    var fv: real_t = undefined;
    var iA: real_t = undefined;
    var nPer: real_t = undefined;
    var pperA: real_t = undefined;
    var cperA: real_t = undefined;
    var pmt: real_t = undefined;
    var pv: real_t = undefined;
    var p: real_t = undefined;
    var result: real_t = undefined;
    var err: c_int = 0;

    real34ToReal(registerReal34Ptr(RESERVED_VARIABLE_FV), &fv);
    real34ToReal(registerReal34Ptr(RESERVED_VARIABLE_IPONA), &iA);
    real34ToReal(registerReal34Ptr(RESERVED_VARIABLE_NPPER), &nPer);
    real34ToReal(registerReal34Ptr(RESERVED_VARIABLE_PPERONA), &pperA);
    real34ToReal(registerReal34Ptr(RESERVED_VARIABLE_CPERONA), &cperA);
    real34ToReal(registerReal34Ptr(RESERVED_VARIABLE_PMT), &pmt);
    real34ToReal(registerReal34Ptr(RESERVED_VARIABLE_PV), &pv);

    if (getSystemFlag(@bitCast(FLAG_ENDPMT))) {
        int32ToReal(0, &p);
    } else {
        int32ToReal(1, &p);
    }

    switch (variable) {
        RESERVED_VARIABLE_PV => {
            err = calculatePV(&fv, &iA, &nPer, &pperA, &pmt, &cperA, &p, &result);
            if (err == 0) {
                realToReal34(&result, registerReal34Ptr(RESERVED_VARIABLE_PV));
            }
        },
        RESERVED_VARIABLE_FV => {
            err = calculateFV(&pv, &iA, &nPer, &pperA, &pmt, &cperA, &p, &result);
            if (err == 0) {
                realToReal34(&result, registerReal34Ptr(RESERVED_VARIABLE_FV));
            }
        },
        RESERVED_VARIABLE_PMT => {
            err = calculatePMT(&pv, &fv, &iA, &nPer, &pperA, &cperA, &p, &result);
            if (err == 0) {
                realToReal34(&result, registerReal34Ptr(RESERVED_VARIABLE_PMT));
            }
        },
        RESERVED_VARIABLE_NPPER => {
            err = calculateNPPER(&pv, &fv, &iA, &pperA, &pmt, &cperA, &p, &result);
            if (err == 0) {
                realToReal34(&result, registerReal34Ptr(RESERVED_VARIABLE_NPPER));
            }
        },
        RESERVED_VARIABLE_PPERONA => {
            err = calculatePPER(&pv, &fv, &iA, &nPer, &pmt, &cperA, &p, &result);
            if (err == 0) {
                realToReal34(&result, registerReal34Ptr(RESERVED_VARIABLE_PPERONA));
            }
        },
        RESERVED_VARIABLE_CPERONA => {
            err = calculateCPER(&pv, &fv, &iA, &nPer, &pperA, &pmt, &p, &result);
            if (err == 0) {
                realToReal34(&result, registerReal34Ptr(RESERVED_VARIABLE_CPERONA));
            }
        },
        else => {
            displayBugScreen(bugScreenNotForTvmVar);
            return 8;
        },
    }

    if (err != 0) {
        moreInfoOnError("In function solveTvmVariable51:", "TVM error", " Cannot compute TVM equation with current parameters", null);
        return err;
    }

    reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
    convertRealToReal34ResultRegister(&result, REGISTER_X);
    setSystemFlag(FLAG_ASLIFT);
    return 0;
}

// ===========================================================================
// fnTvmVar
// ===========================================================================
const bugScreenNotForTvm: [*:0]const u8 = "In function fnTvmVar: this variable is not intended for TVM application!";

pub export fn fnTvmVar(variable: u16) linksection(runtime.code_section) callconv(.c) void {
    ensureTvmContext();

    switch (variable) {
        RESERVED_VARIABLE_FV, RESERVED_VARIABLE_IPONA, RESERVED_VARIABLE_NPPER, RESERVED_VARIABLE_PPERONA, RESERVED_VARIABLE_CPERONA, RESERVED_VARIABLE_PMT, RESERVED_VARIABLE_PV => {
            currentSolverStatus |= SOLVER_STATUS_TVM_APPLICATION;
            currentSolverVariable = variable;
            tvmIKnown = false;

            if ((currentSolverStatus & SOLVER_STATUS_READY_TO_EXECUTE) != 0 or programRunStop == PGM_RUNNING or programRunStop == PGM_PAUSED or testing) {
                var y: real34_t = undefined;
                var x: real34_t = undefined;
                var resZ: real34_t = undefined;
                var resY: real34_t = undefined;
                var resX: real34_t = undefined;
                real34SetZero(&resZ);
                real34SetZero(&resY);
                real34SetOne(&resX);
                saveForUndo();
                thereIsSomethingToUndo = true;
                liftStack();
                tvmIKnown = false;

                if (variable != RESERVED_VARIABLE_IPONA) {
                    const errv = solveTvmVariable51(variable);
                    if (errv == 0) {
                        temporaryInformation = TI_SOLVER_VARIABLE;
                        return;
                    } else {
                        lastErrorCode = 0;
                    }
                }

                switch (variable) {
                    RESERVED_VARIABLE_IPONA, RESERVED_VARIABLE_PPERONA, RESERVED_VARIABLE_CPERONA => {
                        tvmIChanges = true;
                    },
                    else => {
                        tvmIChanges = false;
                    },
                }

                real34Multiply(registerReal34Ptr(variable), const34_2(), &y);
                real34Multiply(registerReal34Ptr(variable), const34_1on2(), &x);

                switch (variable) {
                    RESERVED_VARIABLE_PV => {
                        if (real34CompareAbsLessThan(registerReal34Ptr(RESERVED_VARIABLE_PV), const34_1e_4())) {
                            real34Multiply(registerReal34Ptr(RESERVED_VARIABLE_FV), const34_2(), &y);
                            real34Multiply(registerReal34Ptr(RESERVED_VARIABLE_FV), const34_1on2(), &x);
                        }
                    },
                    RESERVED_VARIABLE_FV => {
                        if (real34CompareAbsLessThan(registerReal34Ptr(RESERVED_VARIABLE_FV), const34_1e_4())) {
                            real34Multiply(registerReal34Ptr(RESERVED_VARIABLE_PV), const34_2(), &y);
                            real34Multiply(registerReal34Ptr(RESERVED_VARIABLE_PV), const34_1on2(), &x);
                        }
                    },
                    RESERVED_VARIABLE_IPONA => {
                        if (real34CompareAbsLessThan(registerReal34Ptr(variable), const34_1on10())) {
                            real34Copy(const34_3(), &y);
                            real34Copy(const34_7(), &x);
                        }
                    },
                    RESERVED_VARIABLE_NPPER => {
                        if (real34CompareLessThan(registerReal34Ptr(variable), const34_1())) {
                            real34Copy(const34_2(), &y);
                            real34SetOne(&x);
                        }
                    },
                    RESERVED_VARIABLE_CPERONA, RESERVED_VARIABLE_PPERONA => {
                        if (real34CompareLessThan(registerReal34Ptr(variable), const34_3())) {
                            real34Copy(const34_24(), &y);
                            real34Copy(const34_9(), &x);
                        }
                    },
                    RESERVED_VARIABLE_PMT => {},
                    else => {},
                }

                if ((variable == RESERVED_VARIABLE_PV or variable == RESERVED_VARIABLE_FV) and
                    !real34IsZero(registerReal34Ptr(RESERVED_VARIABLE_PV)) and
                    !real34IsZero(registerReal34Ptr(RESERVED_VARIABLE_FV)) and
                    real34IsNegative(registerReal34Ptr(RESERVED_VARIABLE_PV)) == real34IsNegative(registerReal34Ptr(RESERVED_VARIABLE_FV)))
                {
                    real34ChangeSign(&y);
                    real34ChangeSign(&x);
                }

                if (real34CompareAbsLessThan(&x, const34_1e_4()) and real34CompareAbsLessThan(&y, const34_1e_4())) {
                    real34SetOne(&x);
                }

                var iter: u16 = 0;
                var xx: real34_t = undefined;
                var yy: real34_t = undefined;

                const nIter: u16 = 6;
                while (blk: {
                    const cont = iter < nIter and !real34CompareEqual(&resX, &resY);
                    iter += 1;
                    break :blk cont;
                }) {
                    real34Copy(&x, &xx);
                    real34Copy(&y, &yy);
                    const solveResult: u16 = @bitCast(@as(i16, @truncate(solve_owned.solver(@bitCast(variable), &y, &x, &resZ, &resY, &resX))));
                    if (solveResult == SOLVER_RESULT_NORMAL) {
                        reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
                        real34Copy(&resX, registerReal34Ptr(REGISTER_X));
                        temporaryInformation = TI_SOLVER_VARIABLE;
                        thereIsSomethingToUndo = false;
                        break;
                    } else if (solveResult == SOLVER_RESULT_CONSTANT) {
                        iter = nIter;
                        break;
                    } else if (solveResult == SOLVER_RESULT_ABORTED) {
                        iter = nIter;
                        if (exitKeyWaiting()) {
                            break;
                        }
                    } else {
                        if (real34IsNegative(&xx)) {
                            real34Subtract(&xx, const34_2(), &x);
                        } else {
                            real34Add(&xx, const34_1(), &x);
                        }
                        if (real34IsNegative(&yy)) {
                            real34Subtract(&yy, const34_1on2(), &y);
                        } else {
                            real34Add(&yy, const34_2(), &y);
                        }
                        real34Multiply(&x, const34_3(), &x);
                        if ((iter + 1) % 3 == 0) {
                            real34ChangeSign(&x);
                        }
                        real34Multiply(&y, const34_2(), &y);
                    }
                }

                if (iter == nIter) {
                    if (lastErrorCode != ERROR_SOLVER_ABORT) {
                        displayCalcErrorMessage(ERROR_NO_ROOT_FOUND, ERR_REGISTER_LINE, REGISTER_X);
                    }
                    moreInfoOnError("In function fnTvmVar:", "cannot compute TVM equation", "with current parameters", null);
                }

                adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
                setSystemFlag(FLAG_ASLIFT);
            } else {
                fnToReal(NOPARAM);
                if (lastErrorCode == ERROR_NONE) {
                    reallyRunFunction(ITM_STO, variable);
                    if (variable == RESERVED_VARIABLE_PPERONA) {
                        reallyRunFunction(ITM_STO, RESERVED_VARIABLE_CPERONA);
                    }
                    currentSolverStatus |= SOLVER_STATUS_READY_TO_EXECUTE;
                    temporaryInformation = TI_SOLVER_VARIABLE;
                }
                adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
                setSystemFlag(FLAG_ASLIFT);
            }
        },
        else => {
            displayBugScreen(bugScreenNotForTvm);
        },
    }
}

// ===========================================================================
// fnEff / fnEffToI
// ===========================================================================
// L2 error surface (REPORT-23 P1/P5): the finance-command cores return an
// out-of-range error instead of calling displayCalcErrorMessage inline; the L3
// shims map it via reportTvmError (all these paths share ERROR_OUT_OF_RANGE with
// static two-part messages).
const TvmError = error{ EffOutOfRange, EffToIOutOfRange, AmortBalOutOfRange, AmortPrnOutOfRange, AmortIntOutOfRange };

fn reportTvmError(e: TvmError) void {
    displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
    switch (e) {
        error.EffOutOfRange => moreInfoOnError("In function fnEff:", "cannot compute EFF%/a ", "with parameter cp/a = 0", null),
        error.EffToIOutOfRange => moreInfoOnError("In function fnEffToI:", "cannot compute I%/a ", "with parameters n = 0 & EFF/a < 0 ", null),
        error.AmortBalOutOfRange => moreInfoOnError("In function fnAmortBal:", "cannot compute BAL ", "with cp/a = 0 or P/YR = 0", null),
        error.AmortPrnOutOfRange => moreInfoOnError("In function fnAmortPrn:", "cannot compute \xCE\xA3PRN ", "with cp/a = 0 or P/YR = 0", null),
        error.AmortIntOutOfRange => moreInfoOnError("In function fnAmortInt:", "cannot compute \xCE\xA3INT ", "with cp/a = 0 or P/YR = 0", null),
    }
}

fn fnEffCore() TvmError!void {
    ensureTvmContext();
    var iA: real_t = undefined;
    var cperA: real_t = undefined;
    var tmp: real_t = undefined;

    if (getRegisterAsRealQuiet(RESERVED_VARIABLE_IPONA, &iA) and getRegisterAsRealQuiet(RESERVED_VARIABLE_CPERONA, &cperA) and !realIsZero(&cperA)) {
        saveForUndo();
        thereIsSomethingToUndo = true;
        liftStack();

        iA.exponent -= 2; // iA = iA / 100
        realDivide(&iA, &cperA, &tmp, &ctxtReal39);
        {
            var temp2: real_t = undefined;
            WP34S_Ln1P(&tmp, &temp2, ctxtTvm());
            realMultiply(&temp2, &cperA, &temp2, ctxtTvm());
            WP34S_ExpM1(&temp2, &tmp, ctxtTvm());
        }
        tmp.exponent += 2; // tmp = tmp * 100

        reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
        convertRealToReal34ResultRegister(&tmp, REGISTER_X);
        temporaryInformation = TI_TVM_EFF;
    } else {
        return error.EffOutOfRange;
    }
}

pub export fn fnEff(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    fnEffCore() catch |e| reportTvmError(e);
}

fn fnEffToICore() TvmError!void {
    ensureTvmContext();
    var iEFF: real_t = undefined;
    var tmp: real_t = undefined;
    var cperA: real_t = undefined;
    var t2: real_t = undefined;

    if (getRegisterAsRealQuiet(REGISTER_X, &iEFF) and getRegisterAsRealQuiet(RESERVED_VARIABLE_CPERONA, &cperA) and !realIsZero(&cperA) and realIsPositive(&iEFF)) {
        saveForUndo();
        thereIsSomethingToUndo = true;

        iEFF.exponent -= 2; // iEFF = iEFF / 100
        WP34S_Ln1P(&iEFF, &tmp, &ctxtReal39);

        realDivide(&tmp, &cperA, &t2, &ctxtReal39);
        WP34S_ExpM1(&t2, &tmp, &ctxtReal39);
        tmp.exponent += 2; // tmp = tmp * 100
        realMultiply(&tmp, &cperA, &tmp, &ctxtReal39);

        realToReal34(&tmp, registerReal34Ptr(RESERVED_VARIABLE_IPONA));
        reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
        convertRealToReal34ResultRegister(&tmp, REGISTER_X);

        temporaryInformation = TI_TVM_IA;
    } else {
        return error.EffToIOutOfRange;
    }
}

pub export fn fnEffToI(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    fnEffToICore() catch |e| reportTvmError(e);
}

// ===========================================================================
// tvmEquation (solver callback)
// ===========================================================================
var tvm_i: real_t = undefined; // 'static real_t i' in C

pub export fn tvmEquation(variable: calcRegister_t, ioVal: *real_t, derivative: ?*real_t) linksection(runtime.code_section) callconv(.c) void {
    const variableU: u16 = @bitCast(variable);

    // Force recalculation of i when computing derivative
    if (derivative != null and variableU == RESERVED_VARIABLE_IPONA) {
        tvmIKnown = false;
    }

    ensureTvmContext();
    var fv: real_t = undefined;
    var iA: real_t = undefined;
    var nPer: real_t = undefined;
    var pperA: real_t = undefined;
    var cperA: real_t = undefined;
    var pmt: real_t = undefined;
    var pv: real_t = undefined;
    var val: real_t = undefined;
    var r: real_t = undefined;
    var k: real_t = undefined;

    if (variableU != RESERVED_VARIABLE_FV) {
        real34ToReal(registerReal34Ptr(RESERVED_VARIABLE_FV), &fv);
    }
    if (variableU != RESERVED_VARIABLE_IPONA) {
        real34ToReal(registerReal34Ptr(RESERVED_VARIABLE_IPONA), &iA);
    }
    if (variableU != RESERVED_VARIABLE_NPPER) {
        real34ToReal(registerReal34Ptr(RESERVED_VARIABLE_NPPER), &nPer);
    }
    if (variableU != RESERVED_VARIABLE_PPERONA) {
        real34ToReal(registerReal34Ptr(RESERVED_VARIABLE_PPERONA), &pperA);
    }
    if (variableU != RESERVED_VARIABLE_CPERONA) {
        real34ToReal(registerReal34Ptr(RESERVED_VARIABLE_CPERONA), &cperA);
    }
    if (variableU != RESERVED_VARIABLE_PMT) {
        real34ToReal(registerReal34Ptr(RESERVED_VARIABLE_PMT), &pmt);
    }
    if (variableU != RESERVED_VARIABLE_PV) {
        real34ToReal(registerReal34Ptr(RESERVED_VARIABLE_PV), &pv);
    }

    switch (variableU) {
        RESERVED_VARIABLE_FV => realCopy(ioVal, &fv),
        RESERVED_VARIABLE_IPONA => realCopy(ioVal, &iA),
        RESERVED_VARIABLE_NPPER => realCopy(ioVal, &nPer),
        RESERVED_VARIABLE_PPERONA => realCopy(ioVal, &pperA),
        RESERVED_VARIABLE_CPERONA => realCopy(ioVal, &cperA),
        RESERVED_VARIABLE_PMT => realCopy(ioVal, &pmt),
        RESERVED_VARIABLE_PV => realCopy(ioVal, &pv),
        else => {},
    }

    if ((!tvmIKnown) or (tvmIChanges)) {
        realDivide(&iA, const_100(), &tvm_i, ctxtTvm());
        realDivide(&tvm_i, &pperA, &tvm_i, ctxtTvm());

        realDivide(&cperA, &pperA, &r, ctxtTvm()); // r = cperA / pperA

        if (!(realIsZero(&r) or realCompareEqual(const_1(), &r))) {
            realDivide(&tvm_i, &r, &tvm_i, ctxtTvm());
            {
                var temp: real_t = undefined;
                WP34S_Ln1P(&tvm_i, &temp, ctxtSolverTvmHi());
                realMultiply(&temp, &r, &temp, ctxtSolverTvmHi());
                WP34S_ExpM1(&temp, &tvm_i, ctxtSolverTvmHi());
            }
        }
        tvmIKnown = true;
    }

    // early return for i = 0
    if (realIsZero(&tvm_i)) {
        realFMA(&nPer, &pmt, &pv, &val, ctxtTvm());
        realSubtract(&val, &fv, &val, ctxtTvm());
        realCopy(&val, ioVal);
        if (derivative) |deriv| {
            switch (variableU) {
                RESERVED_VARIABLE_PMT => realCopy(&nPer, deriv),
                RESERVED_VARIABLE_PV => realSetOne(deriv),
                RESERVED_VARIABLE_FV => realCopy(const__1(), deriv),
                RESERVED_VARIABLE_NPPER => realCopy(&pmt, deriv),
                else => realSetNaN(deriv),
            }
        }
        return;
    }

    {
        var temp: real_t = undefined;
        var neg_nPer: real_t = undefined;
        var i1negN: real_t = undefined;
        var oneMinusI1negN: real_t = undefined;
        realCopy(&nPer, &neg_nPer);
        realChangeSign(&neg_nPer);
        WP34S_Ln1P(&tvm_i, &temp, ctxtSolverTvmHi());
        realMultiply(&temp, &neg_nPer, &temp, ctxtSolverTvmHi());

        doubleExp(&temp, &i1negN, &oneMinusI1negN, ctxtSolverTvmHi());
        realChangeSign(&oneMinusI1negN);

        if (getSystemFlag(@bitCast(FLAG_ENDPMT))) {
            realSetOne(&k);
        } else {
            realAdd(const_1(), &tvm_i, &k, ctxtTvm());
        }

        realCopy(&pv, &val);

        var term2: real_t = undefined;
        realCopy(&oneMinusI1negN, &term2);
        realDivide(&term2, &tvm_i, &term2, ctxtSolverTvmInv());
        realMultiply(&term2, &k, &term2, ctxtTvm());
        realFMA(&term2, &pmt, &val, &val, ctxtTvm());
        realFMA(&fv, &i1negN, &val, &val, ctxtTvm());
    }
    realCopy(&val, ioVal);

    // OPTION_TVM_NEWTON derivative blocks
    if (derivative) |deriv| {
        if (variableU == RESERVED_VARIABLE_IPONA) {
            var one_plus_i: real_t = undefined;
            var one_plus_i_neg_N: real_t = undefined;
            var one_plus_i_neg_N_m1: real_t = undefined;
            var term1: real_t = undefined;
            var term2: real_t = undefined;
            var factor_deriv: real_t = undefined;
            var i_squared: real_t = undefined;
            realAdd(const_1(), &tvm_i, &one_plus_i, ctxtTvm());
            var temp: real_t = undefined;
            var neg_nPer: real_t = undefined;
            var one_minus: real_t = undefined;
            realCopy(&nPer, &neg_nPer);
            realChangeSign(&neg_nPer);
            WP34S_Ln1P(&tvm_i, &temp, ctxtSolverTvmHi());
            realMultiply(&temp, &neg_nPer, &temp, ctxtSolverTvmHi());
            doubleExp(&temp, &one_plus_i_neg_N, &one_minus, ctxtSolverTvmHi());
            realChangeSign(&one_minus);
            realDivide(&one_plus_i_neg_N, &one_plus_i, &one_plus_i_neg_N_m1, ctxtTvm());
            realMultiply(&nPer, &one_plus_i_neg_N_m1, &term1, ctxtTvm());
            realDivide(&term1, &tvm_i, &term1, ctxtSolverTvmInv());
            realMultiply(&tvm_i, &tvm_i, &i_squared, ctxtSolverTvmInv());
            realDivide(&one_minus, &i_squared, &term2, ctxtSolverTvmInv());
            realSubtract(&term1, &term2, &factor_deriv, ctxtTvm());
            if (!getSystemFlag(@bitCast(FLAG_ENDPMT))) {
                realMultiply(&factor_deriv, &one_plus_i, &factor_deriv, ctxtTvm());
                var extra: real_t = undefined;
                realDivide(&one_minus, &tvm_i, &extra, ctxtSolverTvmInv());
                realAdd(&factor_deriv, &extra, &factor_deriv, ctxtTvm());
            }
            realMultiply(&pmt, &factor_deriv, deriv, ctxtTvm());
            var fv_term: real_t = undefined;
            realMultiply(&nPer, &fv, &fv_term, ctxtTvm());
            realChangeSign(&fv_term);
            realFMA(&fv_term, &one_plus_i_neg_N_m1, deriv, deriv, ctxtTvm());
            realDivide(deriv, const_100(), deriv, ctxtTvm());
            realDivide(deriv, &pperA, deriv, ctxtTvm());
        }

        if (variableU == RESERVED_VARIABLE_NPPER) {
            var one_plus_i_neg_N: real_t = undefined;
            var ln1pi: real_t = undefined;
            var pmt_term: real_t = undefined;

            var temp: real_t = undefined;
            var neg_nPer: real_t = undefined;
            realCopy(&nPer, &neg_nPer);
            realChangeSign(&neg_nPer);
            WP34S_Ln1P(&tvm_i, &ln1pi, ctxtSolverTvmHi());
            realMultiply(&ln1pi, &neg_nPer, &temp, ctxtSolverTvmHi());
            realExp(&temp, &one_plus_i_neg_N, ctxtSolverTvmHi());
            realDivide(&pmt, &tvm_i, &pmt_term, ctxtSolverTvmInv());
            realChangeSign(&fv);
            realFMA(&pmt_term, &k, &fv, &pmt_term, ctxtTvm());
            realMultiply(&one_plus_i_neg_N, &ln1pi, deriv, ctxtTvm());
            realMultiply(deriv, &pmt_term, deriv, ctxtTvm());
        }

        if (variableU == RESERVED_VARIABLE_PV) {
            realSetOne(deriv);
        }

        if (variableU == RESERVED_VARIABLE_PMT) {
            var one_minus: real_t = undefined;

            var temp: real_t = undefined;
            var neg_nPer: real_t = undefined;
            realCopy(&nPer, &neg_nPer);
            realChangeSign(&neg_nPer);
            WP34S_Ln1P(&tvm_i, &temp, ctxtSolverTvmHi());
            realMultiply(&temp, &neg_nPer, &temp, ctxtSolverTvmHi());
            WP34S_ExpM1(&temp, &one_minus, ctxtSolverTvmHi());
            realChangeSign(&one_minus);
            realDivide(&one_minus, &tvm_i, deriv, ctxtSolverTvmInv());
            realMultiply(deriv, &k, deriv, ctxtTvm());
        }

        if (variableU == RESERVED_VARIABLE_FV) {
            var temp: real_t = undefined;
            var neg_nPer: real_t = undefined;
            realCopy(&nPer, &neg_nPer);
            realChangeSign(&neg_nPer);
            WP34S_Ln1P(&tvm_i, &temp, ctxtSolverTvmHi());
            realMultiply(&temp, &neg_nPer, &temp, ctxtSolverTvmHi());
            realExp(&temp, deriv, ctxtSolverTvmHi());
        }
    }
}

// ===========================================================================
// AMORT (OPTION_TVM_AMORT)
// ===========================================================================
pub export fn fnAmortP(select: u16) linksection(runtime.code_section) callconv(.c) void {
    var r: real_t = undefined;
    if (!getRegisterAsReal(REGISTER_X, &r)) {
        return;
    }
    const tmp: u16 = @truncate(realToUint32C47(&r, null));
    if (tmp == 0) {
        return;
    }
    const npper: u32 = real34ToUInt32(registerReal34Ptr(RESERVED_VARIABLE_NPPER));
    if (select == 1) {
        amortP1 = tmp;
        if (amortP1 > npper) {
            amortP1 = @truncate(npper);
        }
        if (amortP2 < amortP1) {
            amortP2 = amortP1;
        }
        temporaryInformation = TI_AMORT_P1;
    } else if (select == 2) {
        amortP2 = tmp;
        if (amortP2 > npper) {
            amortP2 = @truncate(npper);
        }
        if (amortP1 > amortP2) {
            amortP1 = amortP2;
        }
        temporaryInformation = TI_AMORT_P2;
    }
}

pub export fn fnAmortNext(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    const delta: u16 = @intCast(@abs(@as(i32, amortP2) - @as(i32, amortP1)));
    const npper: u32 = real34ToUInt32(registerReal34Ptr(RESERVED_VARIABLE_NPPER));
    amortP1 = amortP2 +% 1;
    amortP2 = amortP1 +% delta;
    if (amortP1 > npper) {
        amortP1 = @truncate(npper);
    }
    if (amortP2 > npper) {
        amortP2 = @truncate(npper);
    }
}

fn amortPeriodicRate(iA: *const real_t, pperA: *const real_t, cperA: *const real_t, ip: *real_t) linksection(runtime.code_section) void {
    var ic: real_t = undefined;
    var diff: real_t = undefined;
    var exponent: real_t = undefined;
    var tmp: real_t = undefined;

    realDivide(iA, const_100(), &ic, ctxtTvm());
    realDivide(&ic, cperA, &ic, ctxtTvm());

    realSubtract(cperA, pperA, &diff, ctxtTvm());
    if (realIsZero(&diff)) {
        realCopy(&ic, ip);
        return;
    }

    realDivide(cperA, pperA, &exponent, ctxtTvm());
    WP34S_Ln1P(&ic, &tmp, ctxtTvmHi());
    realMultiply(&tmp, &exponent, &tmp, ctxtTvmHi());
    WP34S_ExpM1(&tmp, ip, ctxtTvmHi());
}

fn amortBalAt_HP12C(k: *const real_t, pv: *const real_t, pmt: *const real_t, i: *const real_t, begin: bool, bal: *real_t) linksection(runtime.code_section) void {
    var balance: real_t = undefined;
    var one_plus_i: real_t = undefined;
    var pmt_eff: real_t = undefined;
    var i_rounded: real_t = undefined;
    const periods: u32 = realToUint32C47(k, null);

    roundToSignificantDigits(i, &i_rounded, 10, &ctxtReal39);

    if (begin) {
        realAdd(const_1(), &i_rounded, &one_plus_i, ctxtTvm());
        realMultiply(pmt, &one_plus_i, &pmt_eff, ctxtTvm());
    } else {
        realCopy(pmt, &pmt_eff);
    }

    var pmt_scaled: real_t = undefined;
    realMultiply(&pmt_eff, const_100(), &pmt_scaled, ctxtTvm());
    realToIntegralValue(&pmt_scaled, &pmt_scaled, DEC_ROUND_HALF_UP, ctxtTvm());
    realDivide(&pmt_scaled, const_100(), &pmt_eff, ctxtTvm());

    realCopy(pv, &balance);

    var pp: u32 = 1;
    while (pp <= periods) : (pp += 1) {
        realAdd(const_1(), &i_rounded, &one_plus_i, ctxtTvm());
        realMultiply(&balance, &one_plus_i, &balance, ctxtTvm());
        realAdd(&balance, &pmt_eff, &balance, ctxtTvm());

        var bal_scaled: real_t = undefined;
        realMultiply(&balance, const_100(), &bal_scaled, ctxtTvm());
        realToIntegralValue(&bal_scaled, &bal_scaled, DEC_ROUND_HALF_UP, ctxtTvm());
        realDivide(&bal_scaled, const_100(), &balance, ctxtTvm());
    }
    realCopy(&balance, bal);
}

fn amortBalAt(k: *const real_t, pv: *const real_t, pmt: *const real_t, i: *const real_t, begin: bool, bal: *real_t) linksection(runtime.code_section) void {
    if (getSystemFlag(FLAG_AMORT_HP12C)) {
        amortBalAt_HP12C(k, pv, pmt, i, begin, bal);
        return;
    }

    var log1pi: real_t = undefined;
    var x: real_t = undefined;
    var qk: real_t = undefined;
    var qk_m1: real_t = undefined;
    var pvEff: real_t = undefined;
    var pvQk: real_t = undefined;
    var ratio: real_t = undefined;
    if (realIsZero(i)) {
        realFMA(k, pmt, pv, bal, ctxtTvm());
        return;
    }

    WP34S_Ln1P(i, &log1pi, ctxtSolverTvmHi());
    realMultiply(k, &log1pi, &x, ctxtSolverTvmHi());
    doubleExp(&x, &qk, &qk_m1, ctxtSolverTvmHi());

    if (begin) {
        var one_plus_i: real_t = undefined;
        realAdd(const_1(), i, &one_plus_i, ctxtTvm());
        realDivide(pv, &one_plus_i, &pvEff, ctxtTvm());
    } else {
        realCopy(pv, &pvEff);
    }

    realMultiply(&pvEff, &qk, &pvQk, ctxtTvm());
    realDivide(&qk_m1, i, &ratio, ctxtSolverTvmInv());
    realFMA(pmt, &ratio, &pvQk, bal, ctxtTvm());
}

fn amortCompute(sumInt: *real_t, sumPrn: *real_t, bal: *real_t) linksection(runtime.code_section) bool {
    var iA: real_t = undefined;
    var pperA: real_t = undefined;
    var cperA: real_t = undefined;
    var pmt: real_t = undefined;
    var pv: real_t = undefined;
    var i: real_t = undefined;
    var p1m1: real_t = undefined;
    var balStart: real_t = undefined;
    var count: real_t = undefined;
    var totalPmt: real_t = undefined;
    var begin: bool = undefined;
    var p1: real_t = undefined;
    var p2: real_t = undefined;
    uInt32ToReal(amortP1, &p1);
    uInt32ToReal(amortP2, &p2);

    real34ToReal(registerReal34Ptr(RESERVED_VARIABLE_IPONA), &iA);
    real34ToReal(registerReal34Ptr(RESERVED_VARIABLE_PPERONA), &pperA);
    real34ToReal(registerReal34Ptr(RESERVED_VARIABLE_CPERONA), &cperA);
    real34ToReal(registerReal34Ptr(RESERVED_VARIABLE_PMT), &pmt);
    real34ToReal(registerReal34Ptr(RESERVED_VARIABLE_PV), &pv);

    if (realIsZero(&cperA) or realIsZero(&pperA)) {
        return false;
    }

    if (getSystemFlag(FLAG_AMORT_HP12C)) {
        var pmt_scaled: real_t = undefined;
        realMultiply(&pmt, const_100(), &pmt_scaled, ctxtTvm());
        realToIntegralValue(&pmt_scaled, &pmt_scaled, DEC_ROUND_HALF_UP, ctxtTvm());
        realDivide(&pmt_scaled, const_100(), &pmt, ctxtTvm());
    }

    begin = !getSystemFlag(@bitCast(FLAG_ENDPMT));
    amortPeriodicRate(&iA, &pperA, &cperA, &i);

    realSubtract(&p1, const_1(), &p1m1, ctxtTvm());

    if (realIsZero(&p1m1)) {
        realCopy(&pv, &balStart);
    } else {
        amortBalAt(&p1m1, &pv, &pmt, &i, begin, &balStart);
    }
    amortBalAt(&p2, &pv, &pmt, &i, begin, bal);

    realSubtract(bal, &balStart, sumPrn, ctxtTvm());

    realSubtract(&p2, &p1, &count, ctxtTvm());
    realAdd(&count, const_1(), &count, ctxtTvm());
    realMultiply(&count, &pmt, &totalPmt, ctxtTvm());
    realSubtract(&totalPmt, sumPrn, sumInt, ctxtTvm());

    return true;
}

fn amortStoreResult(value: *const real_t, tiTag: u8) linksection(runtime.code_section) void {
    saveForUndo();
    thereIsSomethingToUndo = true;
    liftStack();
    reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
    convertRealToReal34ResultRegister(value, REGISTER_X);
    temporaryInformation = tiTag;
}

fn fnAmortBalCore() TvmError!void {
    ensureTvmContext();
    var sumInt: real_t = undefined;
    var sumPrn: real_t = undefined;
    var bal: real_t = undefined;

    if (!amortCompute(&sumInt, &sumPrn, &bal)) return error.AmortBalOutOfRange;
    amortStoreResult(&bal, TI_AMORT_BAL);
}

pub export fn fnAmortBal(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    fnAmortBalCore() catch |e| reportTvmError(e);
}

fn fnAmortPrnCore() TvmError!void {
    ensureTvmContext();
    var sumInt: real_t = undefined;
    var sumPrn: real_t = undefined;
    var bal: real_t = undefined;

    if (!amortCompute(&sumInt, &sumPrn, &bal)) return error.AmortPrnOutOfRange;
    amortStoreResult(&sumPrn, TI_AMORT_PRN);
}

pub export fn fnAmortPrn(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    fnAmortPrnCore() catch |e| reportTvmError(e);
}

fn fnAmortIntCore() TvmError!void {
    ensureTvmContext();
    var sumInt: real_t = undefined;
    var sumPrn: real_t = undefined;
    var bal: real_t = undefined;

    if (!amortCompute(&sumInt, &sumPrn, &bal)) return error.AmortIntOutOfRange;
    amortStoreResult(&sumInt, TI_AMORT_INT);
}

pub export fn fnAmortInt(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    fnAmortIntCore() catch |e| reportTvmError(e);
}
