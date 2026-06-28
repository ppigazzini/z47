// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/solver/isumprod.c: the integer-only programmable
// Sigma / Pi (fnProgrammableiSum / fnProgrammableiProduct). UNCOVERED by the
// testSuite (no test gate) - verified by build only. Faithful line-by-line
// translation preserving the exact order of every longInteger / real34_t op.
//
// The bridge (isumprod_legacy.c, removed) renamed fnProgrammableiSum ->
// z47_solver_fnProgrammableiSum and fnProgrammableiProduct ->
// z47_solver_fnProgrammableiProduct; those are the symbols solve.zig's
// dispatcher calls and we export them with those names. The static
// _showProgress / _programmableiSumProd / _checkRegisters / _checkiArgument
// become private. The host-only _showProgress (ENABLE_SOLVER_PROGRESS == 1)
// is reduced to a no-op (no effect on the computed result), matching the
// prime / sumprod owner precedent. The VERBOSE_COUNTER debug blocks are #undef'd
// and omitted; the EXTRA_INFO_ON_CALC_ERROR sprintf hints are stripped under
// TESTSUITE/DMCP (EXTRA_INFO_ON_CALC_ERROR == 0) so they are omitted.

const runtime = @import("solve_runtime.zig");

const real34_t = extern struct {
    bytes: [16]u8,
};

const calcRegister_t = runtime.calcRegister_t;
const bool_t = bool;

// GMP long integer (mpz). The linkable symbols are __gmpz_*.
const mp_limb_t = usize;
const mpz_struct = extern struct {
    _mp_alloc: c_int,
    _mp_size: c_int,
    _mp_d: [*c]mp_limb_t,
};
const longInteger_t = [1]mpz_struct;

extern fn @"__gmpz_init"(op: *mpz_struct) void;
extern fn @"__gmpz_clear"(op: *mpz_struct) void;
extern fn @"__gmpz_set_ui"(rop: *mpz_struct, op: c_ulong) void;
extern fn @"__gmpz_cmp"(op1: *const mpz_struct, op2: *const mpz_struct) c_int;
extern fn @"__gmpz_cmp_ui"(op1: *const mpz_struct, op2: c_ulong) c_int;
extern fn @"__gmpz_tdiv_q"(q: *mpz_struct, n: *const mpz_struct, d: *const mpz_struct) void;
extern fn @"__gmpz_fdiv_ui"(op: *const mpz_struct, d: c_ulong) c_ulong;

inline fn longIntegerInit(op: *mpz_struct) void {
    @"__gmpz_init"(op);
}
inline fn longIntegerFree(op: *mpz_struct) void {
    @"__gmpz_clear"(op);
}
inline fn uInt32ToLongInteger(source: u32, destination: *mpz_struct) void {
    @"__gmpz_set_ui"(destination, source);
}
inline fn longIntegerIsZero(op: *const mpz_struct) bool {
    return op._mp_size == 0;
}
inline fn longIntegerCompare(op1: *const mpz_struct, op2: *const mpz_struct) i32 {
    return @"__gmpz_cmp"(op1, op2);
}
inline fn longIntegerCompareUInt(op: *const mpz_struct, u: u32) i32 {
    return @"__gmpz_cmp_ui"(op, u);
}
inline fn longIntegerDivide(op1: *const mpz_struct, op2: *const mpz_struct, result: *mpz_struct) void {
    @"__gmpz_tdiv_q"(result, op1, op2);
}
inline fn longIntegerModuloUInt(op: *const mpz_struct, u: u32) u32 {
    return @truncate(@"__gmpz_fdiv_ui"(op, u));
}

// Real linkable longInteger functions (integers.c). longInteger_t decays to *mpz_struct.
extern fn longIntegerMultiply(opY: *mpz_struct, opX: *mpz_struct, result: *mpz_struct) void;
extern fn longIntegerAdd(opY: *mpz_struct, opX: *mpz_struct, result: *mpz_struct) void;
extern fn longIntegerSubtract(opY: *mpz_struct, opX: *mpz_struct, result: *mpz_struct) void;

// ---------------------------------------------------------------------------
// defines.h values (verified)
//   REGISTER_X=100 Y=101 Z=102 T=103; ERR_REGISTER_LINE=REGISTER_Z
//   FIRST_LABEL=2044 LAST_LABEL=6999 INVALID_VARIABLE=2199
//   ERROR_NONE=0 ERROR_LABEL_NOT_FOUND=6 ERROR_OUT_OF_RANGE=8
//   ERROR_INVALID_DATA_TYPE_FOR_OP=24 ERROR_BAD_INPUT=53
//   FLAG_SOLVING=0xc026; dtLongInteger=0; amNone=5; NOPARAM=9876
//   TI_NO_INFO=0; PGM_WAITING=2 PGM_STOPPED=0
//   screen.h: timed=0 force=1 halfSec_clear*/disp=true
// ---------------------------------------------------------------------------
const REGISTER_X: calcRegister_t = 100;
const REGISTER_Y: calcRegister_t = 101;
const REGISTER_Z: calcRegister_t = 102;
const REGISTER_T: calcRegister_t = 103;
const ERR_REGISTER_LINE: calcRegister_t = REGISTER_Z;

const FIRST_LABEL: u16 = 2044;
const LAST_LABEL: u16 = 6999;
const INVALID_VARIABLE: u16 = 2199;

const ERROR_NONE: u8 = 0;
const ERROR_LABEL_NOT_FOUND: u8 = 6;
const ERROR_OUT_OF_RANGE: u8 = 8;
const ERROR_INVALID_DATA_TYPE_FOR_OP: u8 = 24;
const ERROR_BAD_INPUT: u8 = 53;

const FLAG_SOLVING: u32 = 0xc026;

const dtLongInteger: u32 = 0;
const amNone: u32 = 5;
const NOPARAM: u16 = 9876;

const TI_NO_INFO: u8 = 0;
const PGM_WAITING: u8 = 2;
const PGM_STOPPED: u8 = 0;

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

// ---------------------------------------------------------------------------
// Register / stack / program externs
// ---------------------------------------------------------------------------
extern fn getRegisterDataType(reg: calcRegister_t) u32;
extern fn convertLongIntegerRegisterToLongInteger(regist: calcRegister_t, longInteger: *mpz_struct) void;
extern fn convertLongIntegerToLongIntegerRegister(longInteger: *const mpz_struct, regist: calcRegister_t) void;

extern fn setSystemFlag(sf: c_uint) void;
extern fn clearSystemFlag(sf: c_uint) void;
extern fn fnFillStack(unused: u16) void;
extern fn execProgram(label: u16) void;
extern fn displayCalcErrorMessage(error_code: u8, err_message_register_line: calcRegister_t, err_register_line: calcRegister_t) void;
extern fn findNamedLabel(label_name: [*:0]const u8) calcRegister_t;
extern fn letteredRegisterName(regist: calcRegister_t) u8;

extern fn checkHalfSec() bool;
extern fn progressHalfSecUpdate_Integer(mode: u8, txt: [*:0]const u8, loop: i32, clearZ: bool, clearT: bool, disp: bool) bool;

// ===========================================================================
// _showProgress: host-only progress display reduced to a no-op (no effect on
// the computed result). ENABLE_SOLVER_PROGRESS == 1 body omitted.
// ===========================================================================
fn _showProgress(a: *const mpz_struct) linksection(runtime.code_section) void {
    _ = a;
}

// ===========================================================================
// _programmableiSumProd
// ===========================================================================
fn _programmableiSumProd(label: u16, prod: bool_t) linksection(runtime.code_section) void {
    currentKeyCode = 255;
    var loop: i32 = 0;
    var finished: i16 = 0;
    var resultLi: longInteger_t = undefined;
    var xLi: longInteger_t = undefined;
    var loopStep: longInteger_t = undefined;
    var loopTo: longInteger_t = undefined;
    var iCounter: longInteger_t = undefined;
    var iLoop: longInteger_t = undefined;
    // loopTo/loopStep/iCounter are initialised by the converters below; do not
    // double-init (the first allocation would leak). iLoop/resultLi need init.
    longIntegerInit(&iLoop[0]);
    longIntegerInit(&resultLi[0]);
    convertLongIntegerRegisterToLongInteger(REGISTER_Y, &loopTo[0]);
    convertLongIntegerRegisterToLongInteger(REGISTER_X, &loopStep[0]);
    convertLongIntegerRegisterToLongInteger(REGISTER_Z, &iCounter[0]); // Loopfrom counter initial value = From
    uInt32ToLongInteger(if (prod) @as(u32, 1) else @as(u32, 0), &resultLi[0]); // Initialize long integer accumulator

    longIntegerSubtract(&loopTo[0], &iCounter[0], &iLoop[0]); // calculate the remaining iteration counter
    if (!longIntegerIsZero(&loopStep[0])) {
        longIntegerDivide(&iLoop[0], &loopStep[0], &iLoop[0]);
    }
    loop = @bitCast(longIntegerModuloUInt(&iLoop[0], @bitCast(@as(i32, 0x7FFFFFFF))));

    if (longIntegerCompare(&loopTo[0], &iCounter[0]) != 0 and
        (longIntegerIsZero(&loopStep[0]) or
            (longIntegerCompare(&loopTo[0], &iCounter[0]) > 0 and longIntegerCompareUInt(&loopStep[0], 0) <= 0) or
            (longIntegerCompare(&loopTo[0], &iCounter[0]) < 0 and longIntegerCompareUInt(&loopStep[0], 0) >= 0)))
    {
        displayCalcErrorMessage(ERROR_BAD_INPUT, ERR_REGISTER_LINE, REGISTER_X);
    } else {
        currentSolverNestingDepth += 1;
        setSystemFlag(FLAG_SOLVING);

        while (lastErrorCode == ERROR_NONE) {
            loop -= 1;
            if (checkHalfSec()) {
                if (progressHalfSecUpdate_Integer(timed, "Loop: ", loop, halfSec_clearZ, halfSec_clearT, halfSec_disp)) {
                    _showProgress(&resultLi[0]);
                }
            }

            finished = @truncate(longIntegerCompare(&iCounter[0], &loopTo[0])); // 0 mean equal
            finished = finished * @as(i16, @truncate(longIntegerCompareUInt(&loopStep[0], 0)));
            if (finished > 0) {
                break;
            }

            convertLongIntegerToLongIntegerRegister(&iCounter[0], REGISTER_X);
            fnFillStack(NOPARAM);

            dynamicMenuItem = -1;
            execProgram(label);
            if (lastErrorCode != ERROR_NONE) {
                break;
            }

            if (getRegisterDataType(REGISTER_X) != dtLongInteger) {
                lastErrorCode = ERROR_INVALID_DATA_TYPE_FOR_OP;
                break;
            }

            convertLongIntegerRegisterToLongInteger(REGISTER_X, &xLi[0]); // Result accumulated
            if (prod) {
                longIntegerMultiply(&resultLi[0], &xLi[0], &resultLi[0]);
            } else {
                longIntegerAdd(&resultLi[0], &xLi[0], &resultLi[0]);
            }
            longIntegerFree(&xLi[0]);

            longIntegerAdd(&iCounter[0], &loopStep[0], &iCounter[0]);

            if (finished == 0) {
                break;
            }
        } // WHILE

        if (lastErrorCode == ERROR_NONE) {
            convertLongIntegerToLongIntegerRegister(&resultLi[0], REGISTER_X);
        } else {
            displayCalcErrorMessage(lastErrorCode, ERR_REGISTER_LINE, REGISTER_X);
        }

        longIntegerFree(&resultLi[0]);
        longIntegerFree(&iLoop[0]);
        longIntegerFree(&iCounter[0]);
        longIntegerFree(&loopTo[0]);
        longIntegerFree(&loopStep[0]);

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
// _checkRegisters
// ===========================================================================
fn _checkRegisters() linksection(runtime.code_section) bool_t {
    if (getRegisterDataType(REGISTER_X) != dtLongInteger) {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        return true;
    } else if (getRegisterDataType(REGISTER_Y) != dtLongInteger) {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_Y);
        return true;
    } else if (getRegisterDataType(REGISTER_Z) != dtLongInteger) {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_Z);
        return true;
    }
    return false;
}

// ===========================================================================
// _checkiArgument
// ===========================================================================
fn _checkiArgument(label_in: u16, prod: bool_t) linksection(runtime.code_section) void {
    var label = label_in;
    if (FIRST_LABEL <= label and label <= LAST_LABEL) {
        if (!_checkRegisters()) {
            _programmableiSumProd(label, prod);
        }
    } else if (REGISTER_X <= @as(calcRegister_t, @intCast(label)) and @as(calcRegister_t, @intCast(label)) <= REGISTER_T) {
        // Interactive mode
        var buf: [2]u8 = undefined;
        buf[0] = letteredRegisterName(@intCast(label));
        buf[1] = 0;
        label = @bitCast(@as(i16, @truncate(findNamedLabel(@ptrCast(&buf[0])))));
        if (label == INVALID_VARIABLE) {
            displayCalcErrorMessage(ERROR_LABEL_NOT_FOUND, ERR_REGISTER_LINE, REGISTER_X);
        } else {
            if (!_checkRegisters()) {
                _programmableiSumProd(label, prod);
            }
        }
    } else {
        displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
    }
}

pub export fn z47_solver_fnProgrammableiSum(label: u16) linksection(runtime.code_section) callconv(.c) void {
    _checkiArgument(label, false);
}

pub export fn z47_solver_fnProgrammableiProduct(label: u16) linksection(runtime.code_section) callconv(.c) void {
    _checkiArgument(label, true);
}
