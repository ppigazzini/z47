// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/solver/integrate.c: numerical integration (double
// exponential, WP34s-derived). UNCOVERED by the testSuite (no direct gate;
// WP34S=7) - verified by build only. Faithful line-by-line translation
// preserving the exact order of every real_t operation.
//
// Build config (defines.h): USE_NEW_DEI_INTEGRATION_CODE == 2, so ONLY the new
// routines are live: dbl_exp_int_new, exp_sinh_opt_d, DEI_xeq_user_adr,
// DEI_xeq_user, integrate, _integratorIteration, _fnIntegrate, fnIntegrate,
// fnIntegrateYX, fnIntVar. The legacy _integrate / _integrate_mm
// (USE_NEW_DEI_INTEGRATION_CODE == 0) are DEAD and omitted.
// SPEEDUPEXPERIMENT is defined.
//
// The bridge (integrate_legacy.c, removed) renamed fnPgmInt/fnIntegrate/
// fnIntegrateYX. solve.zig's dispatcher calls z47_solver_fnIntegrate /
// z47_solver_fnIntegrateYX (exported here) but owns fnPgmInt itself (its own
// Zig impl), so z47_solver_fnPgmInt is DEAD and omitted; _fnIntegrate calls the
// real fnPgmInt (extern, owned by solve.zig). The real-name public symbols
// fnIntVar and integrate are exported here. The non-static _fnIntegrate /
// _showProgress are only referenced internally and become private (the
// host-only _showProgress drawing is a no-op, matching the sumprod precedent;
// the surrounding interrupt control flow is preserved). ENABLE_INTEGRATOR_FILE_
// OUTPUT==0 and INTEGRATION_TWO_STAGE_EXIT undefined; the sprintf/radixProcess
// display string building is reduced to a fixed literal (no effect on result).

const runtime = @import("solve_runtime.zig");

const real_t = extern struct {
    digits: i32,
    exponent: i32,
    bits: u8,
    lsu: [25]u16,
};
const real34_t = extern struct {
    bytes: [16]u8,
};
const realContext_t = extern struct {
    digits: i32,
    emax: i32,
    emin: i32,
    round: u32,
    traps: u32,
    status: u32,
    clamp: u8,
};

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
const REGISTER_T: calcRegister_t = 103;
const ERR_REGISTER_LINE: calcRegister_t = 102;
const NIM_REGISTER_LINE: calcRegister_t = REGISTER_X;

const RESERVED_VARIABLE_ACC: u16 = 2031;
const RESERVED_VARIABLE_ULIM: u16 = 2032;
const RESERVED_VARIABLE_LLIM: u16 = 2033;

const ERROR_NONE: u8 = 0;
const ERROR_LABEL_NOT_FOUND: u8 = 6;
const ERROR_OUT_OF_RANGE: u8 = 8;
const ERROR_NO_PROGRAM_SPECIFIED: u8 = 54;
const ERROR_SOLVER_ABORT: u8 = 60;

const FLAG_ASLIFT: u32 = 0xc023;
const FLAG_INTING: u32 = 0xc025;
const FLAG_SOLVING: u32 = 0xc026;

const SOLVER_STATUS_INTERACTIVE: u16 = 0x0002;
const SOLVER_STATUS_EQUATION_INTEGRATE: u16 = 0x0004;
const SOLVER_STATUS_USES_FORMULA: u16 = 0x0100;

const dtReal34: u32 = 1;
const amNone: u32 = 5;
const NOPARAM: u16 = 9876;

const TI_ACC: u8 = 53;
const TI_ULIM: u8 = 54;
const TI_LLIM: u8 = 55;
const TI_INTEGRAL: u8 = 56;

const EQUATION_PARSER_XEQ: u16 = 1;
const AIM_BUFFER_LENGTH: usize = 1024;

const force: u8 = 1;
const timed: u8 = 0;
const halfSec_clearZ: bool = true;
const halfSec_clearT: bool = true;
const halfSec_disp: bool = true;

// MNU_Sfdx / MNU_Sf_TOOL (items.h)
const MNU_Sfdx: i16 = 1381;
const MNU_Sf_TOOL: i16 = 2375;

const maxlevel: c_int = 7;

// ---------------------------------------------------------------------------
// Globals
// ---------------------------------------------------------------------------
extern var lastErrorCode: u8;
extern var temporaryInformation: u8;
extern var currentKeyCode: u8;
extern var dynamicMenuItem: i16;
extern var currentSolverNestingDepth: u16;
extern var currentSolverStatus: u16;
extern var currentSolverProgram: u16;
extern var currentSolverVariable: u16;
extern var currentFormula: u16;
extern var numberOfLabels: u16;
extern var significantDigits: u8;
extern var tmpString: [*c]u8;

extern var ctxtReal4: realContext_t;
extern var ctxtReal34: realContext_t;
extern var ctxtReal39: realContext_t;
extern var ctxtReal51: realContext_t;
extern var ctxtReal75: realContext_t;

// softmenu globals (for fnIntVar)
const dynamicSoftmenu_t = extern struct {
    menuItem: i16,
    numItems: i16,
    menuContent: [*c]u8,
};
const softmenuStack_t = extern struct {
    softmenuId: i16,
    firstItem: i16,
    userMenuId: i16,
    calcMode: u8,
};
// C arrays: bind the address, not the data-as-pointer (gotcha #1). The pointer
// form crashed fnIntegrateVar's dynamicSoftmenu[...] access like fnSolveVar.
const dynamicSoftmenu = @extern([*c]dynamicSoftmenu_t, .{ .name = "dynamicSoftmenu" });
const softmenuStack = @extern([*c]softmenuStack_t, .{ .name = "softmenuStack" });

// ---------------------------------------------------------------------------
// Constants blob accessors (offsets verified vs generated constantPointers.h)
// ---------------------------------------------------------------------------
const constants = @extern([*]const u8, .{ .name = "constants" });
inline fn cstR(comptime off: u32) *align(1) const real_t {
    return @ptrCast(constants + off);
}
const OFF_const_0: u32 = 1708;
const OFF_const39_pi: u32 = 1848;
const OFF_const__1: u32 = 4376;
const OFF_const_1e_16: u32 = 4484;
const OFF_const_1on2: u32 = 4580;
const OFF_const_1: u32 = 4856;
const OFF_const39_piOn2: u32 = 4880;
const OFF_const_2: u32 = 4928;
const OFF_const39_ln10: u32 = 4940;
const OFF_const_4: u32 = 5024;
const OFF_const_7: u32 = 5096;
const OFF_const_8: u32 = 5108;
const OFF_const_10: u32 = 5132;
const OFF_const_1e_32: u32 = 5708;
const OFF_const_1e_6143: u32 = 5840;

inline fn const_0() *align(1) const real_t {
    return cstR(OFF_const_0);
}
inline fn const39_pi() *align(1) const real_t {
    return cstR(OFF_const39_pi);
}
inline fn const__1() *align(1) const real_t {
    return cstR(OFF_const__1);
}
inline fn const_1e_16() *align(1) const real_t {
    return cstR(OFF_const_1e_16);
}
inline fn const_1on2() *align(1) const real_t {
    return cstR(OFF_const_1on2);
}
inline fn const_1() *align(1) const real_t {
    return cstR(OFF_const_1);
}
inline fn const39_piOn2() *align(1) const real_t {
    return cstR(OFF_const39_piOn2);
}
inline fn const_2() *align(1) const real_t {
    return cstR(OFF_const_2);
}
inline fn const39_ln10() *align(1) const real_t {
    return cstR(OFF_const39_ln10);
}
inline fn const_4() *align(1) const real_t {
    return cstR(OFF_const_4);
}
inline fn const_7() *align(1) const real_t {
    return cstR(OFF_const_7);
}
inline fn const_8() *align(1) const real_t {
    return cstR(OFF_const_8);
}
inline fn const_10() *align(1) const real_t {
    return cstR(OFF_const_10);
}
inline fn const_1e_32() *align(1) const real_t {
    return cstR(OFF_const_1e_32);
}
inline fn const_1e_6143() *align(1) const real_t {
    return cstR(OFF_const_1e_6143);
}

// ---------------------------------------------------------------------------
// decNumber primitives / real_t macro reproductions. The ones used inline as
// expression arguments (realDivide/realMultiply/realAdd/realSubtract/
// realCopyAbs) return the destination pointer (decNumber* convention).
// ---------------------------------------------------------------------------
extern fn decNumberCopy(res: *real_t, source: *align(1) const real_t) *real_t;
extern fn decNumberCopyAbs(res: *real_t, source: *const real_t) *real_t;
extern fn decNumberAdd(res: *real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberSubtract(res: *real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberMultiply(res: *real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberDivide(res: *real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberFMA(res: *real_t, f1: *align(1) const real_t, f2: *align(1) const real_t, term: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberMinus(res: *real_t, operand: *align(1) const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberFromInt32(res: *real_t, source: i32) *real_t;
extern fn decNumberFromUInt32(res: *real_t, source: u32) *real_t;
extern fn decNumberNextToward(res: *real_t, from: *align(1) const real_t, toward: *align(1) const real_t, ctxt: *realContext_t) *real_t;

inline fn realCopy(source: *align(1) const real_t, destination: *real_t) void {
    _ = decNumberCopy(destination, source);
}
inline fn realCopyAbs(source: *const real_t, destination: *real_t) *real_t {
    return decNumberCopyAbs(destination, source);
}
inline fn realAdd(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) *real_t {
    return decNumberAdd(res, op1, op2, ctxt);
}
inline fn realSubtract(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) *real_t {
    return decNumberSubtract(res, op1, op2, ctxt);
}
inline fn realMultiply(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) *real_t {
    return decNumberMultiply(res, op1, op2, ctxt);
}
inline fn realDivide(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) *real_t {
    return decNumberDivide(res, op1, op2, ctxt);
}
inline fn realFMA(f1: *align(1) const real_t, f2: *align(1) const real_t, term: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberFMA(res, f1, f2, term, ctxt);
}
inline fn realMinus(operand: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberMinus(res, operand, ctxt);
}
inline fn int32ToReal(source: i32, destination: *real_t) void {
    _ = decNumberFromInt32(destination, source);
}
inline fn uInt32ToReal(source: u32, destination: *real_t) void {
    _ = decNumberFromUInt32(destination, source);
}
inline fn realNextToward(from: *align(1) const real_t, toward: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberNextToward(res, from, toward, ctxt);
}
inline fn realChangeSign(operand: *real_t) void {
    operand.bits ^= 0x80;
}
inline fn realSetPositiveSign(operand: *real_t) void {
    operand.bits &= 0x7F;
}
inline fn realGetSign(source: *const real_t) u8 {
    return source.bits & 0x80;
}
inline fn realIsZero(source: *align(1) const real_t) bool {
    return source.lsu[0] == 0 and source.digits == 1 and (source.bits & 0x70) == 0;
}
inline fn realIsSpecial(source: *align(1) const real_t) bool {
    return (source.bits & 0x70) != 0;
}
inline fn realIsInfinite(source: *align(1) const real_t) bool {
    return (source.bits & 0x40) != 0;
}
inline fn realIsNaN(source: *align(1) const real_t) bool {
    return (source.bits & 0x30) != 0;
}

extern fn realSetZero(value: *real_t) void;
extern fn realSetOne(value: *real_t) void;
extern fn realSetNaN(value: *real_t) void;
extern fn realSetMinusInfinity(value: *real_t) void;
extern fn realCompareEqual(number1: *align(1) const real_t, number2: *align(1) const real_t) bool;
extern fn realCompareLessThan(number1: *align(1) const real_t, number2: *align(1) const real_t) bool;
extern fn realCompareGreaterThan(number1: *align(1) const real_t, number2: *align(1) const real_t) bool;
extern fn realCompareGreaterEqual(number1: *align(1) const real_t, number2: *align(1) const real_t) bool;
extern fn realCompareLessEqual(number1: *align(1) const real_t, number2: *align(1) const real_t) bool;
extern fn realCompareAbsLessThan(number1: *align(1) const real_t, number2: *align(1) const real_t) bool;
extern fn realCompareAbsGreaterEqual(number1: *align(1) const real_t, number2: *align(1) const real_t) bool;
extern fn realExp(rhs: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void;
extern fn realSquareRoot(operand: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void;
extern fn realToInt32C47(r: *const real_t, err: ?*bool) i32;
extern fn WP34S_Ln(x: *align(1) const real_t, res: *real_t, ctxt: *realContext_t) void;
extern fn WP34S_SinhCosh(x: *align(1) const real_t, sinOut: ?*real_t, cosOut: ?*real_t, ctxt: *realContext_t) void;

// ---------------------------------------------------------------------------
// real34_t macros
// ---------------------------------------------------------------------------
extern fn decimal128ToNumber(source: *align(1) const real34_t, destination: *real_t) *real_t;
extern fn decimal128FromNumber(dest: *align(1) real34_t, src: *align(1) const real_t, ctxt: *realContext_t) *align(1) real34_t;
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
extern fn real34CompareEqual(number1: *align(1) const real34_t, number2: *align(1) const real34_t) bool;

// ---------------------------------------------------------------------------
// Register / stack / program externs
// ---------------------------------------------------------------------------
extern fn getRegisterDataPointer(reg: calcRegister_t) ?*anyopaque;
inline fn registerReal34Ptr(reg: calcRegister_t) *align(1) real34_t {
    return @ptrCast(getRegisterDataPointer(reg).?);
}
extern fn getRegisterDataType(reg: calcRegister_t) u32;
extern fn getRegisterAsReal(reg: calcRegister_t, val: *real_t) bool;
extern fn reallocateRegister(regist: calcRegister_t, data_type: u32, data_len: u32, tag: u32) void;
extern fn convertRealToReal34ResultRegister(real: *const real_t, dest: calcRegister_t) void;

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
extern fn parseEquation(equationId: u16, parseMode: u16, buffer: [*c]u8, mvarBuffer: [*c]u8) void;
extern fn displayCalcErrorMessage(error_code: u8, err_message_register_line: calcRegister_t, err_register_line: calcRegister_t) void;
extern fn findNamedLabel(label_name: [*:0]const u8) calcRegister_t;
extern fn findOrAllocateNamedVariable(variableName: [*:0]const u8) calcRegister_t;
extern fn letteredRegisterName(regist: calcRegister_t) u8;
extern fn getNthString(ptr: [*c]u8, n: i16) [*c]u8;
extern fn showSoftmenu(id: i16) void;
extern fn exitKeyWaiting() bool;
extern fn checkHalfSec() bool;
extern fn progressHalfSecUpdate_Integer(mode: u8, txt: [*:0]const u8, loop: i32, clearZ: bool, clearT: bool, disp: bool) bool;

// fnPgmInt is owned by solve.zig (its own Zig impl); call the real symbol.
extern fn fnPgmInt(label: u16) void;

// ===========================================================================
// _fnIntegrate
// ===========================================================================
fn _fnIntegrate(labelOrVariable: u16, XY: bool_t) linksection(runtime.code_section) void {
    if ((FIRST_LABEL <= labelOrVariable and labelOrVariable <= LAST_LABEL) or (REGISTER_X <= @as(calcRegister_t, @intCast(labelOrVariable)) and @as(calcRegister_t, @intCast(labelOrVariable)) <= REGISTER_T)) {
        // Interactive mode
        fnPgmInt(labelOrVariable);
        if (lastErrorCode == ERROR_NONE) {
            currentSolverStatus = SOLVER_STATUS_INTERACTIVE | SOLVER_STATUS_EQUATION_INTEGRATE;
        }
    } else if (!XY and (labelOrVariable == RESERVED_VARIABLE_ACC or labelOrVariable == RESERVED_VARIABLE_ULIM or labelOrVariable == RESERVED_VARIABLE_LLIM)) {
        fnToReal(NOPARAM);
        if (lastErrorCode == ERROR_NONE) {
            real34Copy(registerReal34Ptr(REGISTER_X), registerReal34Ptr(@bitCast(labelOrVariable)));
            switch (labelOrVariable) {
                RESERVED_VARIABLE_ACC => {
                    temporaryInformation = TI_ACC;
                },
                RESERVED_VARIABLE_ULIM => {
                    temporaryInformation = TI_ULIM;
                },
                RESERVED_VARIABLE_LLIM => {
                    temporaryInformation = TI_LLIM;
                },
                else => {},
            }
        }
    } else if ((currentSolverStatus & SOLVER_STATUS_USES_FORMULA) == 0 and (FIRST_NAMED_VARIABLE <= labelOrVariable and labelOrVariable <= LAST_NAMED_VARIABLE) and currentSolverProgram >= numberOfLabels) {
        displayCalcErrorMessage(ERROR_NO_PROGRAM_SPECIFIED, ERR_REGISTER_LINE, REGISTER_X);
        // adjustResult is omitted (the C calls it; mirrors via convertRealToReal34? No - the C calls adjustResult here)
        adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
    } else if (FIRST_NAMED_VARIABLE <= labelOrVariable and labelOrVariable <= LAST_NAMED_VARIABLE) {
        var acc: real_t = undefined;
        var ulim: real_t = undefined;
        var llim: real_t = undefined;
        var res: real_t = undefined;
        var smallerEpsilon: bool_t = false;
        real34ToReal(registerReal34Ptr(@bitCast(RESERVED_VARIABLE_ACC)), &acc);
        real34ToReal(registerReal34Ptr(@bitCast(RESERVED_VARIABLE_ULIM)), &ulim);
        real34ToReal(registerReal34Ptr(@bitCast(RESERVED_VARIABLE_LLIM)), &llim);
        smallerEpsilon = realCompareAbsLessThan(&acc, const_1e_16()) and (realCompareAbsLessThan(&ulim, const_1e_32()) or realCompareAbsLessThan(&llim, const_1e_32()));
        // USE_MICHALSKI_MOSIG_TANH_SINH == 1
        smallerEpsilon = smallerEpsilon and (realIsSpecial(&ulim) or realIsSpecial(&llim)); // smallerEpsilon not needed
        if (realIsZero(&acc)) { // it may freeze if ACC=0
            realCopy(const_1e_32(), &acc); // used to be const_1e_6143
        }
        if (real34CompareEqual(registerReal34Ptr(@bitCast(RESERVED_VARIABLE_ULIM)), registerReal34Ptr(@bitCast(RESERVED_VARIABLE_LLIM)))) {
            realSetZero(&res);
            realSetZero(&acc);
        } else {
            const regist: calcRegister_t = @bitCast(labelOrVariable); // at this point, it is a register variable
            saveForUndo();

            // SPEEDUPEXPERIMENT
            var digits: real_t = undefined;
            const significantDigitsMem: u8 = significantDigits;
            var digitsN: i32 = 0;
            WP34S_Ln(&acc, &digits, &ctxtReal39);
            _ = realDivide(&digits, const39_ln10(), &digits, &ctxtReal39);
            digitsN = max_i32(min_i32(-realToInt32C47(&digits, null), 34 - 3), 1);

            if (digitsN == 6) {
                significantDigits = @intCast(digitsN + 3);
                ctxtReal4.digits = 7;
                ctxtReal34.digits = digitsN + 3;
                ctxtReal39.digits = digitsN + 5;
                ctxtReal51.digits = digitsN + 7;
                ctxtReal75.digits = digitsN + 13;
                integrate(regist, &llim, &ulim, &acc, &res, &ctxtReal4);
                significantDigits = significantDigitsMem;
                ctxtReal4.digits = 6;
                ctxtReal34.digits = 34;
                ctxtReal39.digits = 39;
                ctxtReal51.digits = 51;
                ctxtReal75.digits = 75;
            } else if (digitsN <= 10) {
                significantDigits = @intCast(digitsN + 3);
                ctxtReal4.digits = digitsN + 3;
                ctxtReal34.digits = digitsN + 3;
                ctxtReal39.digits = digitsN + 5;
                ctxtReal51.digits = digitsN + 7;
                ctxtReal75.digits = digitsN + 13;
                integrate(regist, &llim, &ulim, &acc, &res, &ctxtReal39);
                significantDigits = significantDigitsMem;
                ctxtReal4.digits = 6;
                ctxtReal34.digits = 34;
                ctxtReal39.digits = 39;
                ctxtReal51.digits = 51;
                ctxtReal75.digits = 75;
            } else {
                integrate(regist, &llim, &ulim, &acc, &res, if (smallerEpsilon) &ctxtReal75 else &ctxtReal39);
            }
        }

        // done:
        fnUndo(0);
        liftStack();
        setSystemFlag(FLAG_ASLIFT);
        liftStack();

        convertRealToReal34ResultRegister(&res, REGISTER_X);
        convertRealToReal34ResultRegister(&acc, REGISTER_Y);
        if (lastErrorCode != ERROR_SOLVER_ABORT) {
            temporaryInformation = TI_INTEGRAL;
        }
        adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
    } else {
        displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
    }
}

extern fn adjustResult(res: calcRegister_t, drop_y: bool, set_cpx_res: bool, op1: calcRegister_t, op2: calcRegister_t, op3: calcRegister_t) void;

inline fn max_i32(a: i32, b: i32) i32 {
    return if (a > b) a else b;
}
inline fn min_i32(a: i32, b: i32) i32 {
    return if (a < b) a else b;
}

pub export fn z47_solver_fnIntegrate(labelOrVariable: u16) linksection(runtime.code_section) callconv(.c) void {
    _fnIntegrate(labelOrVariable, false);
}

pub export fn z47_solver_fnIntegrateYX(labelOrVariable: u16) linksection(runtime.code_section) callconv(.c) void {
    var x: real_t = undefined;
    var y: real_t = undefined;
    if (getRegisterAsReal(REGISTER_X, &x) and getRegisterAsReal(REGISTER_Y, &y)) {
        realToReal34(&x, registerReal34Ptr(@bitCast(RESERVED_VARIABLE_ULIM)));
        realToReal34(&y, registerReal34Ptr(@bitCast(RESERVED_VARIABLE_LLIM)));
        fnDrop(NOPARAM);
        fnDrop(NOPARAM);
    }
    _fnIntegrate(labelOrVariable, true);
}

pub export fn fnIntVar(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    const variable_str: [*c]u8 = getNthString(dynamicSoftmenu[@intCast(softmenuStack[0].softmenuId)].menuContent, dynamicMenuItem);
    const regist: u16 = @bitCast(@as(i16, @truncate(findOrAllocateNamedVariable(@ptrCast(variable_str)))));
    const doubleVarPress: bool_t = regist == currentSolverVariable;
    currentSolverVariable = regist;
    if (doubleVarPress and (currentSolverStatus & 0x0001) != 0) { // SOLVER_STATUS_READY_TO_EXECUTE
        if ((currentSolverStatus & SOLVER_STATUS_INTERACTIVE) != 0 and (currentSolverStatus & SOLVER_STATUS_USES_FORMULA) == 0) {
            showSoftmenu(-MNU_Sfdx); // in case of RPN formula
        } else {
            showSoftmenu(-MNU_Sf_TOOL); // in case of EQN
        }
    } else {
        reallyRunFunction(44, regist); // ITM_STO
        currentSolverStatus |= 0x0001; // SOLVER_STATUS_READY_TO_EXECUTE
        temporaryInformation = 51; // TI_SOLVER_VARIABLE
    }
}

// ===========================================================================
// _integratorIteration  (ENABLE_INTEGRATOR_FILE_OUTPUT == 0)
// ===========================================================================
fn _integratorIteration() linksection(runtime.code_section) void {
    if (lastErrorCode == ERROR_SOLVER_ABORT) {
        return;
    }
    if ((currentSolverStatus & SOLVER_STATUS_USES_FORMULA) != 0) {
        parseEquation(currentFormula, EQUATION_PARSER_XEQ, tmpString, tmpString + AIM_BUFFER_LENGTH);
    } else {
        // mirror of the solver's guard (Mihail, 9bb487e44 "Fix integral nested in
        // SOLVE"); a nested program may repoint currentSolverProgram. Enables
        // INT(INT).
        const savedCurrentSolverProgram: u16 = currentSolverProgram;
        dynamicMenuItem = -1;
        execProgram(currentSolverProgram + FIRST_LABEL);
        currentSolverProgram = savedCurrentSolverProgram;
    }
}

// ===========================================================================
// DEI_xeq_user  (ported from WP34s)
// ===========================================================================
fn DEI_xeq_user(regist: calcRegister_t, x: *align(1) const real_t, res: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    _ = realContext;
    if (lastErrorCode == ERROR_SOLVER_ABORT) { // Aborted?
        realSetZero(res);
    } else if (!realIsSpecial(x)) { // abscissa is good?
        reallocateRegister(regist, dtReal34, 0, amNone);
        realToReal34(x, registerReal34Ptr(regist));
        fnFillStack(NOPARAM);
        _integratorIteration();
        real34ToReal(registerReal34Ptr(REGISTER_X), res);
        if (realIsSpecial(res)) { // do not stop in error (if flag D was set)
            realSetZero(res);
        }
    } else { // DEI_bad_absc
        realSetZero(res);
    }
}

// ===========================================================================
// _showProgress: host-only progress display, reduced to a no-op (no effect on
// the computed result). ENABLE_SOLVER_PROGRESS == 1 body omitted.
// ===========================================================================
fn _showProgress(ss: *align(1) const real_t, bma2: *align(1) const real_t, h: *align(1) const real_t, a: *align(1) const real_t, b: *align(1) const real_t, fact: *align(1) const real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    _ = ss;
    _ = bma2;
    _ = h;
    _ = a;
    _ = b;
    _ = fact;
    _ = realContext;
}

// ===========================================================================
// DEI_xeq_user_adr  (helper for exp_sinh_opt_d)
// ===========================================================================
fn DEI_xeq_user_adr(regist: calcRegister_t, a: *align(1) const real_t, d: *align(1) const real_t, r: *align(1) const real_t, fl: *real_t, fr: *real_t, h: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var s1: real_t = undefined;
    _ = realDivide(d, r, &s1, realContext); // s1 = d/r
    _ = realAdd(a, &s1, &s1, realContext); // s1 = a+d/r
    DEI_xeq_user(regist, &s1, fl, realContext); // fl = f(a+d/r)

    _ = realMultiply(d, r, &s1, realContext); // s1 = d*r
    _ = realAdd(a, &s1, &s1, realContext); // s1 = a+d*r
    DEI_xeq_user(regist, &s1, fr, realContext); // fr = f(a+d*r)
    _ = realMultiply(fr, r, fr, realContext);
    _ = realMultiply(fr, r, fr, realContext); // fr = r*r*f(a+d*r)

    _ = realSubtract(fl, fr, h, realContext); // h = fl - fr
}

inline fn IS_INFINITE(x: *const real_t) bool {
    return realIsInfinite(x) or realIsNaN(x);
}
inline fn IS_FINITE(x: *const real_t) bool {
    return !(realIsInfinite(x) or realIsNaN(x));
}

// ===========================================================================
// exp_sinh_opt_d  (USE_NEW_DEI_INTEGRATION_CODE == 2)
// ===========================================================================
fn exp_sinh_opt_d(regist: calcRegister_t, a: *align(1) const real_t, eps: *align(1) const real_t, d: *real_t, realContext: *realContext_t) linksection(runtime.code_section) *real_t {
    _ = eps;
    var fl: real_t = undefined;
    var fr: real_t = undefined;
    var h2: real_t = undefined;
    var r: real_t = undefined;
    var h: real_t = undefined;
    var lfl: real_t = undefined;
    var lfr: real_t = undefined;
    var lr: real_t = undefined;
    var s: real_t = undefined;

    DEI_xeq_user_adr(regist, a, d, const_2(), &fl, &fr, &h2, realContext);

    if (IS_INFINITE(&h2) or (realIsZero(&fl) and realIsZero(&fr))) {
        return d;
    }
    // function undefined or zero - don't bother.

    var i: u16 = 1;
    var j: u16 = 32; // j=32 is optimal to find r

    realSetZero(&s);
    realCopy(const_2(), &lr);
    while (true) { // find max j such that fl and fr are both finite
        j /= 2;
        uInt32ToReal(@as(u32, 1) << @intCast(i + j), &r);
        DEI_xeq_user_adr(regist, a, d, &r, &fl, &fr, &h, realContext);
        if (!(j > 1 and IS_INFINITE(&h))) break;
    }

    if (j > 1 and IS_FINITE(&h) and (realGetSign(&h) != realGetSign(&h2))) {
        realCopy(&fl, &lfl);
        realCopy(&fr, &lfr);

        while (true) { // bisect in 4 iterations
            j /= 2;
            uInt32ToReal(@as(u32, 1) << @intCast(i + j), &r);
            DEI_xeq_user_adr(regist, a, d, &r, &fl, &fr, &h, realContext);
            if (IS_FINITE(&h)) {
                var s1b: real_t = undefined;
                _ = realCopyAbs(&h, &s1b);
                _ = realAdd(&s, &s1b, &s, realContext); // sum |h| to remove noisy cases
                if (realGetSign(&h) == realGetSign(&h2)) {
                    i += j; // search right half
                } else { // search left half
                    realCopy(&fl, &lfl);
                    realCopy(&fr, &lfr);
                    realCopy(&r, &lr);
                }
            }
            if (!(j > 1)) break;
        }

        if (realCompareGreaterThan(&s, const_1e_32())) { // if sum of |h| > small ...
            _ = realSubtract(&lfl, &lfr, &h, realContext);
            realCopy(&lr, &r);
            if (!realIsZero(&h)) { // if last diff != 0, back up r by one step
                _ = realMultiply(&r, const_1on2(), &r, realContext);
            }
            realSetPositiveSign(&lfl);
            realSetPositiveSign(&lfr);
            if (realCompareLessThan(&lfl, &lfr)) {
                _ = realDivide(d, &r, d, realContext); // move d closer to the finite endpoint
            } else {
                _ = realMultiply(d, &r, d, realContext); // move d closer to the infinite endpoint
            }
        }
    }

    return d;
}

// ===========================================================================
// dbl_exp_int_new  (USE_NEW_DEI_INTEGRATION_CODE > 0)
// ===========================================================================
fn dbl_exp_int_new(regist: calcRegister_t, a: *align(1) const real_t, b: *align(1) const real_t, errorp: *real_t, result: *real_t, sign_in: c_int, realContext: *realContext_t) linksection(runtime.code_section) void {
    const interruptedLoop: i16 = 0;
    currentKeyCode = 255;
    var exitSignalled: bool_t = false;

    var c: real_t = undefined;
    var d: real_t = undefined;
    var s: real_t = undefined;
    var v: real_t = undefined;
    var h: real_t = undefined;
    var y: real_t = undefined;
    var eps: real_t = undefined;
    var s1: real_t = undefined;
    var s2: real_t = undefined;
    var s3: real_t = undefined;

    var sign: c_int = sign_in;
    var k: c_int = 0;
    var mode: c_int = 0; // Tanh-Sinh = 0, Exp-Sinh = 1, Sinh-Sinh = 2

    var loop: c_int = 0;

    realCopy(errorp, &eps);

    realSetZero(&c);
    realSetOne(&d);
    realCopy(const_2(), &h);

    if (realIsNaN(a) or realIsNaN(b)) { // check for invalid limits
        realSetNaN(result);
        realSetNaN(errorp);
        return;
    }

    if (realCompareEqual(a, b)) { // check for equal limits
        realSetZero(result);
        realSetZero(errorp);
        return;
    }

    realSetZero(errorp); // initial error is zero
    realSetZero(result); // initial result is zero

    if ((!realIsInfinite(a)) and (!realIsInfinite(b))) {
        _ = realAdd(a, b, &c, realContext);
        _ = realMultiply(&c, const_1on2(), &c, realContext);

        _ = realSubtract(b, a, &d, realContext);
        _ = realMultiply(&d, const_1on2(), &d, realContext);

        realCopy(&c, &v);
    } else if (!realIsInfinite(a)) { // int from a to infinity
        mode = 1; // Exp-Sinh
        realCopy(a, &c); // c = a
        // USE_NEW_DEI_INTEGRATION_CODE == 2: optimise d
        realCopy(exp_sinh_opt_d(regist, a, &eps, &d, realContext), &d);
        _ = realAdd(a, &d, &v, realContext); // v = a + d
    } else if (!realIsInfinite(b)) { // int from -infinity to b
        mode = 1; // Exp-Sinh
        realCopy(b, &c); // c = b
        sign = -sign;

        realMinus(&d, &d, realContext); // d = -1
        // USE_NEW_DEI_INTEGRATION_CODE == 2: optimise d
        realCopy(exp_sinh_opt_d(regist, b, &eps, &d, realContext), &d);
        _ = realAdd(b, &d, &v, realContext); // v = b + d
    } else {
        mode = 2; // Sinh-Sinh
        realSetZero(&v);
    }

    DEI_xeq_user(regist, &v, &s, realContext);

    // Now a, b, c, d, v, and mode have the correct values.
    while (true) {
        var p: real_t = undefined;
        var q: real_t = undefined;
        var fp: real_t = undefined;
        var fm: real_t = undefined;
        var t: real_t = undefined;
        var eh: real_t = undefined;
        realSetZero(&p);
        realSetZero(&fp);
        realSetZero(&fm);

        _ = realMultiply(&h, const_1on2(), &h, realContext);
        realExp(&h, &eh, realContext);
        realCopy(&eh, &t);

        if (k > 0) {
            _ = realMultiply(&eh, &eh, &eh, realContext);
        }

        if (mode == 0) { // Tanh-Sinh
            while (true) {
                var u: real_t = undefined;
                var r: real_t = undefined;
                var w: real_t = undefined;
                var xx: real_t = undefined;

                exitSignalled = exitSignalled or exitKeyWaiting();
                loop += 1;
                if (checkHalfSec()) {
                    if (progressHalfSecUpdate_Integer(timed, "Level: ", loop, !(interruptedLoop != 0), !(interruptedLoop != 0), !(interruptedLoop != 0))) {
                        _showProgress(result, const_1(), const_1(), errorp, const_0(), const_1(), realContext);
                        if (interruptedLoop == 0 and exitSignalled) { // First EXIT press
                            // INTEGRATION_TWO_STAGE_EXIT undefined:
                            displayCalcErrorMessage(ERROR_SOLVER_ABORT, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
                            return;
                        }
                    }
                }

                _ = realDivide(const_1(), &t, &s1, realContext); // s1 stores 1/t
                _ = realSubtract(&s1, &t, &u, realContext);
                realExp(&u, &u, realContext); // u = exp(1/t-t)

                _ = realAdd(&u, const_1(), &r, realContext);
                _ = realDivide(&u, &r, &r, realContext);
                _ = realMultiply(&r, const_2(), &r, realContext); // r = 2*u/(1+u);

                _ = realAdd(&t, &s1, &s2, realContext);
                _ = realMultiply(&r, &s2, &w, realContext);
                _ = realAdd(&u, const_1(), &s2, realContext);
                _ = realDivide(&w, &s2, &w, realContext); // w = (t+1/t)*r/(1+u);

                _ = realMultiply(&d, &r, &xx, realContext); // x = d*r;

                _ = realAdd(a, &xx, &s1, realContext);
                if (realCompareGreaterThan(&s1, a)) { // if too close to a then reuse previous fp
                    DEI_xeq_user(regist, &s1, &y, realContext);
                    if (!realIsInfinite(&y)) {
                        realCopy(&y, &fp);
                    }
                }

                _ = realSubtract(b, &xx, &s1, realContext);
                if (realCompareLessThan(&s1, b)) {
                    DEI_xeq_user(regist, &s1, &y, realContext);
                    if (!realIsInfinite(&y)) {
                        realCopy(&y, &fm);
                    }
                }

                _ = realAdd(&fp, &fm, &s1, realContext);
                _ = realMultiply(&s1, &w, &q, realContext); // q = w*(fp+fm)
                _ = realAdd(&p, &q, &p, realContext); // p += q
                _ = realMultiply(&t, &eh, &t, realContext); // t *= eh

                _ = realMultiply(&eps, realCopyAbs(&p, &s1), &s2, realContext); // s2 = eps*abs(p)
                if (!realCompareGreaterThan(realCopyAbs(&q, &s1), &s2)) break; // while abs(q) > eps*abs(p)
            }
        } else {
            _ = realMultiply(&t, const_1on2(), &t, realContext);
            while (true) {
                var r: real_t = undefined;
                var w: real_t = undefined;
                var xx: real_t = undefined;

                exitSignalled = exitSignalled or exitKeyWaiting();
                loop += 1;
                if (checkHalfSec()) {
                    if (progressHalfSecUpdate_Integer(timed, "Level: ", loop, !(interruptedLoop != 0), !(interruptedLoop != 0), !(interruptedLoop != 0))) {
                        _showProgress(result, const_1(), const_1(), errorp, const_0(), const_1(), realContext);
                        if (interruptedLoop == 0 and exitSignalled) { // First EXIT press
                            displayCalcErrorMessage(ERROR_SOLVER_ABORT, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
                            return;
                        }
                    }
                }

                _ = realMultiply(&t, const_4(), &s1, realContext); // s1 = 4t
                _ = realDivide(const_1(), &s1, &s1, realContext); // s1 = 0.25/t
                _ = realSubtract(&t, &s1, &s1, realContext); // s1 = t - 0.25/t
                realExp(&s1, &r, realContext); // r = exp(t-0.25/t)

                realCopy(&r, &w);

                realSetZero(&q);

                if (mode == 1) { // Exp-Sinh
                    _ = realAdd(&c, realDivide(&d, &r, &s1, realContext), &xx, realContext); // x = c+d/r;
                    if (realCompareEqual(&xx, &c)) {
                        break;
                    }
                    DEI_xeq_user(regist, &xx, &y, realContext);
                    if (!realIsInfinite(&y)) {
                        _ = realAdd(&q, realDivide(&y, &w, &s1, realContext), &q, realContext);
                    }
                } else { // Sinh-Sinh
                    _ = realSubtract(&r, realDivide(const_1(), &r, &s2, realContext), &s1, realContext);
                    _ = realMultiply(&s1, const_1on2(), &r, realContext); // r = (r-1/r)/2

                    _ = realAdd(&w, realDivide(const_1(), &w, &s2, realContext), &s1, realContext);
                    _ = realMultiply(&s1, const_1on2(), &w, realContext); // w = (w+1/w)/2

                    _ = realSubtract(&c, realMultiply(&d, &r, &s1, realContext), &xx, realContext); // x = c-d*r;
                    DEI_xeq_user(regist, &xx, &y, realContext);
                    if (!realIsInfinite(&y)) {
                        _ = realAdd(&q, realMultiply(&y, &w, &s1, realContext), &q, realContext);
                    }
                }

                _ = realAdd(&c, realMultiply(&d, &r, &s1, realContext), &xx, realContext); // x = c+d*r;
                DEI_xeq_user(regist, &xx, &y, realContext);

                if (!realIsInfinite(&y)) {
                    _ = realAdd(&q, realMultiply(&y, &w, &s1, realContext), &q, realContext);
                }

                _ = realDivide(const_1(), realMultiply(&t, const_4(), &s2, realContext), &s1, realContext); // s1 = 1/(4t)
                _ = realMultiply(&q, realAdd(&t, &s1, &s2, realContext), &q, realContext); // q = q * (t + 1/4t)
                _ = realAdd(&p, &q, &p, realContext); // p += q;
                _ = realMultiply(&t, &eh, &t, realContext); // t *= eh;
                _ = realMultiply(&eps, realCopyAbs(&p, &s1), &s2, realContext); // s2 = eps*abs(p)
                if (!realCompareGreaterThan(realCopyAbs(&q, &s1), &s2)) break; // while abs(q) > eps*abs(p)
            }
        }

        _ = realSubtract(&s, &p, &v, realContext); // v = s - p
        _ = realAdd(&s, &p, &s, realContext); // s+=p

        _ = realCopyAbs(&s, &s1); // s1 = abs(s)
        _ = realCopyAbs(&v, &s2); // s2 = abs(v)
        k += 1;
        // estimate of the integral here = sign*s*h*d.
        _ = realMultiply(&d, realMultiply(&s, &h, &s3, realContext), result, realContext);
        if (sign == -1) {
            realMinus(result, result, realContext); // result = sign*s*h*d
        }
        _ = realDivide(&s2, realAdd(&s1, &s2, &s3, realContext), errorp, realContext); // error = abs(v)/(abs(s)+abs(v))
        if (realIsNaN(errorp)) {
            realSetOne(errorp); // only happens when v, s both zero
        }
        if (!(realCompareGreaterThan(&s2, realMultiply(const_10(), realMultiply(&eps, &s1, &s3, realContext), &s3, realContext)) and k <= maxlevel)) break; // while abs(v) > 10*eps*abs(s)
    }
    return;
}

// ===========================================================================
// integrate
// ===========================================================================
pub export fn integrate(regist: calcRegister_t, a: *align(1) const real_t, b: *align(1) const real_t, acc: *real_t, res: *real_t, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) void {
    const was_solving: bool_t = getSystemFlag(@bitCast(FLAG_SOLVING));
    currentSolverNestingDepth += 1;
    setSystemFlag(FLAG_INTING);
    clearSystemFlag(FLAG_SOLVING);
    // USE_NEW_DEI_INTEGRATION_CODE > 0
    if (realCompareLessThan(a, b)) {
        dbl_exp_int_new(regist, a, b, acc, res, 1, realContext);
    } else { // a, b might be NaN or both equal; handled in function.
        dbl_exp_int_new(regist, b, a, acc, res, -1, realContext);
    }
    currentSolverNestingDepth -= 1;
    if (currentSolverNestingDepth == 0) {
        clearSystemFlag(FLAG_INTING);
    } else if (was_solving) {
        clearSystemFlag(FLAG_INTING);
        setSystemFlag(FLAG_SOLVING);
    }
}
