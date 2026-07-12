// SPDX-License-Identifier: GPL-3.0-only
const std = @import("std");
const abi = @import("abi");
const consts = abi.constants;
const const__1 = consts.const__1;
const const_1 = consts.const_1;
const const_2 = consts.const_2;
const const_1on2 = consts.const_1on2;
const const_10 = consts.const_10;
const const_360 = consts.const_360;
const const_400 = consts.const_400;
const const1071_pi = consts.const1071_pi;
const const2139_2pi = consts.const2139_2pi;
//
// Zig owner for src/c47/mathematics/xfn.c: the extended 1000-digit X.FN engine
// (OPTION_XFN_1000). Exports the xfn.h surface: registerFMAOutputString, fnXXfn
// and the fnXXfn_* trampolines (ToDEG/ToRAD/sin/cos/tan/pi/atan2/arc*/LN/LOG/
// EXP/10X/POWER/SQRT/1ONX/ADD/SUB/MULT/DIV/MOD/MODANG/TO/DRG/SQR/YRTX/RDP/RSD/
// CHS). The dispatcher doXfn, the FUNCTION_TABLE lookups, decomposeReal, the
// three-register FMA readers and the 1071-digit Taylor wrappers stay private.
// Covered by xfn.txt.
//
// Faithful line-by-line translation preserving the exact order of every real_t
// operation (the testSuite checks results to the last ULP). The 1071-digit
// REAL_T_PTR scratch values become 4-byte-aligned stack byte buffers cast to
// *real_t. The context digit count (maxContextDigits / maxAllowedDigits) follows
// use1071: true under TESTSUITE_BUILD and on DM42n/PC (HIMEMORY), matching the C
// `use1071 = HIMEMORY && user1071Flag`. The OPTION_XFN_1000 #else empty stubs
// (DM42 old_hw) are NOT reproduced as no-ops; the full bodies are emitted for
// every build and pushed to executable QSPI via linksection (the execute-in-place
// mechanism), so the flash-limited firmware still fits. The DEBUG_XFN console
// diagnostics and the unconditional getSingleParameter printf have no effect on
// the computed result and are dropped. EXTRA_INFO sprintf hints become fixed
// moreInfoOnError strings.

const runtime = @import("command_wrappers_runtime.zig");
const math_rdp = @import("rdp.zig");
const math_rsd = @import("rsd.zig");
const math_wp34s = @import("special/wp34s.zig");
const math_real_predicates = @import("real_predicates.zig");
const real_t = runtime.real_t;
const realContext_t = runtime.realContext_t;
const calcRegister_t = runtime.calcRegister_t;
const angularMode_t = runtime.angularMode_t;
const rounding_t = runtime.rounding_t;
const mpz_struct = runtime.mpz_struct;

const REGISTER_X = runtime.REGISTER_X;
const REGISTER_Y = runtime.REGISTER_Y;
const REGISTER_Z = runtime.REGISTER_Z;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const ERROR_INPUT_DATA_TYPE_NOT_MATCHING: u8 = 31; // defines.h 31
const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN = runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN;
const ERROR_UNDEF_SOURCE_VAR: u8 = 36; // defines.h:704 (was 6 = ERROR_LABEL_NOT_FOUND)
const ERROR_UNDEFINED_OPCODE: u8 = 3; // defines.h 3

const dtLongInteger = runtime.dtLongInteger;
const dtReal34 = runtime.dtReal34;
const amNone = runtime.amNone;
const amRadian = runtime.amRadian;
const amGrad = runtime.amGrad;
const amDegree = runtime.amDegree;
const amMultPi = runtime.amMultPi;
const amAngleMask = runtime.amAngleMask;

const FIRST_LETTERED_REGISTER: calcRegister_t = 100;
const LAST_SPARE_REGISTER: calcRegister_t = 125;
const REGISTER_A: calcRegister_t = 104;
const REGISTER_B: calcRegister_t = 105;
const REGISTER_T: calcRegister_t = 103;
const NOPARAM: u16 = 9876;
const REAL34_SIZE_IN_BYTES: u16 = 16;
const DEC_ROUND_HALF_UP: rounding_t = 2;

const FLAG_ASLIFT: i32 = 0xc023;

// ITM_*_XFN function ids (items.h).
const ITM_DEG2_XFN: c_int = 2554;
const ITM_RAD2_XFN: c_int = 2555;
const ITM_RDP_XFN: c_int = 2556;
const ITM_RSD_XFN: c_int = 2557;
const ITM_sin_XFN: c_int = 2558;
const ITM_cos_XFN: c_int = 2559;
const ITM_tan_XFN: c_int = 2560;
const ITM_pi_XFN: c_int = 2561;
const ITM_1ONX_XFN: c_int = 2562;
const ITM_atan2_XFN: c_int = 2563;
const ITM_arcsin_XFN: c_int = 2564;
const ITM_arccos_XFN: c_int = 2565;
const ITM_arctan_XFN: c_int = 2566;
const ITM_LN_XFN: c_int = 2567;
const ITM_LOG_XFN: c_int = 2568;
const ITM_EXP_XFN: c_int = 2569;
const ITM_10X_XFN: c_int = 2570;
const ITM_POWER_XFN: c_int = 2571;
const ITM_SQRT_XFN: c_int = 2572;
const ITM_ADD_XFN: c_int = 2573;
const ITM_SUB_XFN: c_int = 2574;
const ITM_MULT_XFN: c_int = 2575;
const ITM_DIV_XFN: c_int = 2576;
const ITM_MOD_XFN: c_int = 2577;
const ITM_MODANG_XFN: c_int = 2578;
const ITM_TO_XFN: c_int = 2579;
const ITM_CHS_XFN: c_int = 2580;
const ITM_DRG_XFN: c_int = 2582;
const ITM_SQR_XFN: c_int = 2583;
const ITM_XTHROOT_XFN: c_int = 2584;

const XFN_NOTFOUND: c_int = 99;
const FT_NILADIC: c_int = 100;
const FT_MONADIC: c_int = 101;
const FT_DYADIC: c_int = 102;
const FT_SINGLEX: c_int = 103;
const NOANG: c_int = 200;
const FORCEANG: c_int = 201;

// use1071 / context-digit policy.
const use1071: bool = runtime.is_testsuite_build or !runtime.wp34s_mod_small_buffers;
const maxAllowedDigits: i32 = if (use1071) 1000 else 68;
const maxContextDigits: i32 = if (use1071) 1071 else 75;

const displayCalcErrorMessage = runtime.displayCalcErrorMessage;
const moreInfoOnError = runtime.moreInfoOnError;
const saveLastX = runtime.saveLastX;
const adjustResult = runtime.adjustResult;
const reallocateRegister = runtime.reallocateRegister;
const liftStack = runtime.liftStack;
const setSystemFlag = runtime.setSystemFlag;
const getRegisterDataType = runtime.getRegisterDataType;
const getRegisterTag = runtime.getRegisterTag;
const getRegisterDataPointer = runtime.getRegisterDataPointer;
const convertRealToResultRegister = runtime.convertRealToResultRegister;
const convertRealToReal34ResultRegister = runtime.convertRealToReal34ResultRegister;
const convertLongIntegerToLongIntegerRegister = runtime.convertLongIntegerToLongIntegerRegister;
const fnDrop = runtime.fnDrop;
// align(1) variants (the 1071-digit stack scratch is 4-byte aligned, so this is
// safe; the runtime declarations require natural alignment).
extern fn convertAngleFromTo(angle: *align(1) real_t, from: angularMode_t, to: angularMode_t, ctxt: *realContext_t) void;
extern fn fnDropT(unusedButMandatoryParameter: u16) void;

extern var currentAngularMode: angularMode_t;
extern var lastErrorCode: u8;
extern var explicitTaylorIterVisibilitySelection: bool;
extern var tmpString: [*]u8;

inline fn getRegisterAngularMode(reg: calcRegister_t) angularMode_t {
    return @intCast(getRegisterTag(reg) & amAngleMask);
}

// registerIsNoAngle(r): (Real34 && am==amNone) || LongInteger
inline fn registerIsNoAngle(r: calcRegister_t) bool {
    return (getRegisterDataType(r) == dtReal34 and getRegisterAngularMode(r) == amNone) or getRegisterDataType(r) == dtLongInteger;
}
// inputAngleMode3r(r)
inline fn inputAngleMode3r(r: calcRegister_t) angularMode_t {
    if (registerIsNoAngle(r + 1) and registerIsNoAngle(r + 2)) {
        return if (!registerIsNoAngle(r)) getRegisterAngularMode(r) else amNone;
    }
    return amNone;
}
// inputIsNoAngle3r(r)
inline fn inputIsNoAngle3r(r: calcRegister_t) bool {
    return registerIsNoAngle(r) or !registerIsNoAngle(r + 1) or !registerIsNoAngle(r + 2);
}
// inputAngleError3r(r)
inline fn inputAngleError3r(r: calcRegister_t) bool {
    return !registerIsNoAngle(r + 1) or !registerIsNoAngle(r + 2);
}
// isXFNregisterValid3r(r)
inline fn isXFNregisterValid3r(r: calcRegister_t) bool {
    return (getRegisterDataType(r) == dtReal34 or getRegisterDataType(r) == dtLongInteger) and
        (getRegisterDataType(r + 1) == dtReal34 or getRegisterDataType(r + 1) == dtLongInteger) and
        (getRegisterDataType(r + 2) == dtReal34 or getRegisterDataType(r + 2) == dtLongInteger) and
        !inputAngleError3r(r);
}

// real_t op helpers (operands *align(1) const).
extern fn decNumberCopy(res: *align(1) real_t, source: *align(1) const real_t) *align(1) real_t;
extern fn decNumberPlus(res: *align(1) real_t, operand: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
extern fn decNumberAdd(res: *align(1) real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
extern fn decNumberSubtract(res: *align(1) real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
extern fn decNumberMultiply(res: *align(1) real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
extern fn decNumberDivide(res: *align(1) real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
extern fn decNumberPower(res: *align(1) real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
extern fn decNumberExp(res: *align(1) real_t, rhs: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
extern fn decNumberLn(res: *align(1) real_t, rhs: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
extern fn decNumberToIntegralExact(res: *align(1) real_t, rhs: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
extern fn decNumberFromString(res: *align(1) real_t, source: [*:0]const u8, ctxt: *realContext_t) *align(1) real_t;
extern fn decNumberToString(source: *align(1) const real_t, destination: [*]u8) [*]u8;
extern fn realSetNaN(value: *align(1) real_t) void;
extern fn decNumberReduce(res: *align(1) real_t, source: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
extern fn sprintf(str: [*]u8, format: [*:0]const u8, ...) c_int;

// realIsNaN / realIsInfinite / realIsZero (decNumber.h bit-test macros, inlined).
const DEC_INF: u8 = 0x40;
const DEC_NAN_BITS: u8 = 0x20 | 0x10; // DECNAN | DECSNAN
inline fn realIsInfinite(s: *align(1) const real_t) bool {
    return (s.bits & DEC_INF) != 0;
}
inline fn realIsNaN(s: *align(1) const real_t) bool {
    return (s.bits & DEC_NAN_BITS) != 0;
}
const realIsZero = math_real_predicates.realIsZero;

inline fn realCopy(source: *align(1) const real_t, destination: *align(1) real_t) void {
    _ = decNumberCopy(destination, source);
}
inline fn realPlus(operand: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberPlus(res, operand, ctxt);
}
inline fn realAdd(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberAdd(res, op1, op2, ctxt);
}
inline fn realSubtract(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberSubtract(res, op1, op2, ctxt);
}
inline fn realMultiply(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberMultiply(res, op1, op2, ctxt);
}
inline fn realDivide(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberDivide(res, op1, op2, ctxt);
}
inline fn realPower(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberPower(res, op1, op2, ctxt);
}
inline fn realSetZero(r: *align(1) real_t) void {
    r.bits = 0;
    r.exponent = 0;
    r.digits = 1;
    r.lsu[0] = 0;
}
inline fn realToString(source: *align(1) const real_t, destination: [*]u8) void {
    _ = decNumberToString(source, destination);
}
inline fn stringToReal(source: [*:0]const u8, destination: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberFromString(destination, source, ctxt);
}
const realIsSpecial = math_real_predicates.realIsSpecial;
inline fn realGetExponent(source: *align(1) const real_t) i32 {
    return source.digits + source.exponent - 1;
}
inline fn realGetDigits(x: *align(1) const real_t) i32 {
    return x.digits;
}

extern fn realToSci(num: *align(1) const real_t, dispString: [*]u8) void;

// WP34S / Taylor engine (operands *align(1)).

// roundToDecimalPlace / roundToSignificantDigits live in the rdp/rsd owners.

// Register / longInteger access.
extern fn getRegisterAsReal(reg: calcRegister_t, value: *align(1) real_t) bool;
extern fn getRegisterAsLongInt(reg: calcRegister_t, val: *mpz_struct, fractional: ?*bool) bool;
extern fn convertLongIntegerToReal(source: *mpz_struct, destination: *align(1) real_t, ctxt: *realContext_t) void;

// longInteger helpers.
extern fn __gmpz_init(op: *mpz_struct) void;
extern fn __gmpz_clear(op: *mpz_struct) void;
extern fn __gmpz_set_ui(rop: *mpz_struct, op: c_ulong) void;
extern fn __gmpz_set_str(rop: *mpz_struct, str: [*:0]const u8, base: c_int) c_int;
extern fn __gmpz_get_str(str: ?[*]u8, base: c_int, op: *const mpz_struct) [*]u8;
inline fn longIntegerInit(op: *mpz_struct) void {
    __gmpz_init(op);
}
inline fn longIntegerFree(op: *mpz_struct) void {
    __gmpz_clear(op);
}
inline fn uInt32ToLongInteger(source: u32, destination: *mpz_struct) void {
    __gmpz_set_ui(destination, source);
}
inline fn stringToLongInteger(source: [*:0]const u8, radix: c_int, destination: *mpz_struct) c_int {
    return __gmpz_set_str(destination, source, radix);
}
inline fn longIntegerToString(source: *const mpz_struct, radix: c_int, destination: [*]u8) void {
    _ = __gmpz_get_str(destination, radix, source);
}
const longIntegerIsZero = math_real_predicates.longIntegerIsZero;

// libc string ops.
extern fn strlen(s: [*:0]const u8) usize;
extern fn strcpy(dst: [*]u8, src: [*:0]const u8) [*]u8;

inline fn setSystemFlagAslift() void {
    setSystemFlag(FLAG_ASLIFT);
}

// Blob constants.

// modulus(a)
inline fn modulus(a: angularMode_t) *align(1) const real_t {
    return if (a == amRadian) const2139_2pi() else if (a == amDegree) const_360() else if (a == amGrad) const_400() else if (a == amMultPi) const_2() else const_1();
}

// REAL_T_PTR(name, 1071).
inline fn realMaxDigits(comptime digits: u32) u32 {
    return ((digits + 2) / 6) * 6 + 3;
}
inline fn realSizeInBytes(comptime digits: u32) u32 {
    return 10 + 2 * (realMaxDigits(digits) / 3);
}
fn BigReal(comptime digits: u32) type {
    return struct {
        buf: [realSizeInBytes(digits)]u8 align(4) = undefined,
        inline fn ptr(self: *@This()) *align(1) real_t {
            return @ptrCast(&self.buf);
        }
    };
}

// ---------------------------------------------------------------------------
// 1071-digit Taylor wrappers (set the explicit-iteration visibility flag).
// ---------------------------------------------------------------------------
fn C47Cvt2RadSinCosTan1071(an: *align(1) real_t, angularMode: angularMode_t, sinOut: ?*align(1) real_t, cosOut: ?*align(1) real_t, tanOut: ?*align(1) real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    explicitTaylorIterVisibilitySelection = true;
    math_wp34s.C47_WP34S_Cvt2RadSinCosTan(an, angularMode, sinOut, cosOut, tanOut, realContext);
}
fn C47_WP34S_Asin1071(x: *align(1) const real_t, angle: *align(1) real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    explicitTaylorIterVisibilitySelection = true;
    math_wp34s.C47_WP34S_Asin(x, angle, realContext);
}
fn C47_WP34S_Acos1071(x: *align(1) const real_t, angle: *align(1) real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    explicitTaylorIterVisibilitySelection = true;
    math_wp34s.C47_WP34S_Acos(x, angle, realContext);
}
fn C47_WP34S_Atan1071(x: *align(1) const real_t, angle: *align(1) real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    explicitTaylorIterVisibilitySelection = true;
    math_wp34s.C47_WP34S_Atan(x, angle, realContext);
}
fn C47_WP34S_Atan2_1071(y: *align(1) const real_t, x: *align(1) const real_t, atan: *align(1) real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    explicitTaylorIterVisibilitySelection = true;
    math_wp34s.C47_WP34S_Atan2(y, x, atan, realContext);
}

// ===========================================================================
// decomposeReal
// ===========================================================================
fn decomposeReal(x: *align(1) const real_t, integerPart: *mpz_struct, fractionalPart: *align(1) real_t, c: *realContext_t) linksection(runtime.code_section) void {
    // pre-check on original x
    var digits: i32 = realGetDigits(x);
    digits = if (digits < c.digits) digits else c.digits;
    if (digits <= 34) {
        // returnUnity
        uInt32ToLongInteger(1, integerPart);
        realCopy(x, fractionalPart);
        return;
    }

    // normalize using realPlus() and re-check if it fits
    var mantissa_b = BigReal(1071){};
    const mantissa = mantissa_b.ptr();
    realPlus(x, mantissa, c);
    var actualDigits: i32 = realGetDigits(mantissa);
    if (actualDigits <= 34) {
        uInt32ToLongInteger(1, integerPart);
        realCopy(x, fractionalPart);
        return;
    }

    // adjust mantissa to form integer 'mantissa'
    const actualExponent: i32 = realGetExponent(mantissa);
    if (actualDigits > maxAllowedDigits) {
        actualDigits = maxAllowedDigits;
    }
    const scaleAmount: i32 = actualDigits - 1 - actualExponent;
    mantissa.exponent += scaleAmount;
    var cc: realContext_t = c.*;
    cc.round = DEC_ROUND_HALF_UP;
    _ = decNumberToIntegralExact(mantissa, mantissa, &cc);
    mantissa.bits &= 0x7F; // realSetPositiveSign
    realToString(mantissa, tmpString);

    const len: i32 = @intCast(strlen(@ptrCast(tmpString)));
    var i: i32 = len - 1;
    while (i >= 0 and tmpString[@intCast(i)] == '0') : (i -= 1) {
        if (i == actualExponent and i <= 34) {
            break;
        }
        tmpString[@intCast(i)] = 0;
    }
    if (strlen(@ptrCast(tmpString)) == 0) {
        _ = strcpy(tmpString, "0");
    }

    _ = stringToLongInteger(@ptrCast(tmpString), 10, integerPart);
    if (longIntegerIsZero(integerPart)) {
        uInt32ToLongInteger(1, integerPart);
        realCopy(x, fractionalPart);
        return;
    }
    var integerAsReal_b = BigReal(1071){};
    const integerAsReal = integerAsReal_b.ptr();
    convertLongIntegerToReal(integerPart, integerAsReal, c);
    realDivide(x, integerAsReal, fractionalPart, c);
    return;
}

// ===========================================================================
// FUNCTION_TABLE lookups
// ===========================================================================
const FunctionLookup = struct {
    function_id: c_int,
    function_type: c_int,
    function_angle: c_int,
};

const FUNCTION_TABLE = [_]FunctionLookup{
    .{ .function_id = ITM_pi_XFN, .function_type = FT_NILADIC, .function_angle = NOANG },
    .{ .function_id = ITM_TO_XFN, .function_type = FT_SINGLEX, .function_angle = NOANG },
    .{ .function_id = ITM_DEG2_XFN, .function_type = FT_MONADIC, .function_angle = NOANG },
    .{ .function_id = ITM_RAD2_XFN, .function_type = FT_MONADIC, .function_angle = NOANG },
    .{ .function_id = ITM_sin_XFN, .function_type = FT_MONADIC, .function_angle = FORCEANG },
    .{ .function_id = ITM_cos_XFN, .function_type = FT_MONADIC, .function_angle = FORCEANG },
    .{ .function_id = ITM_tan_XFN, .function_type = FT_MONADIC, .function_angle = FORCEANG },
    .{ .function_id = ITM_arcsin_XFN, .function_type = FT_MONADIC, .function_angle = NOANG },
    .{ .function_id = ITM_arccos_XFN, .function_type = FT_MONADIC, .function_angle = NOANG },
    .{ .function_id = ITM_arctan_XFN, .function_type = FT_MONADIC, .function_angle = NOANG },
    .{ .function_id = ITM_LN_XFN, .function_type = FT_MONADIC, .function_angle = NOANG },
    .{ .function_id = ITM_LOG_XFN, .function_type = FT_MONADIC, .function_angle = NOANG },
    .{ .function_id = ITM_EXP_XFN, .function_type = FT_MONADIC, .function_angle = NOANG },
    .{ .function_id = ITM_10X_XFN, .function_type = FT_MONADIC, .function_angle = NOANG },
    .{ .function_id = ITM_SQRT_XFN, .function_type = FT_MONADIC, .function_angle = NOANG },
    .{ .function_id = ITM_MODANG_XFN, .function_type = FT_MONADIC, .function_angle = FORCEANG },
    .{ .function_id = ITM_1ONX_XFN, .function_type = FT_MONADIC, .function_angle = NOANG },
    .{ .function_id = ITM_DRG_XFN, .function_type = FT_MONADIC, .function_angle = NOANG },
    .{ .function_id = ITM_SQR_XFN, .function_type = FT_MONADIC, .function_angle = NOANG },
    .{ .function_id = ITM_RDP_XFN, .function_type = FT_MONADIC, .function_angle = NOANG },
    .{ .function_id = ITM_RSD_XFN, .function_type = FT_MONADIC, .function_angle = NOANG },
    .{ .function_id = ITM_CHS_XFN, .function_type = FT_MONADIC, .function_angle = NOANG },
    .{ .function_id = ITM_atan2_XFN, .function_type = FT_DYADIC, .function_angle = NOANG },
    .{ .function_id = ITM_ADD_XFN, .function_type = FT_DYADIC, .function_angle = NOANG },
    .{ .function_id = ITM_SUB_XFN, .function_type = FT_DYADIC, .function_angle = NOANG },
    .{ .function_id = ITM_POWER_XFN, .function_type = FT_DYADIC, .function_angle = NOANG },
    .{ .function_id = ITM_XTHROOT_XFN, .function_type = FT_DYADIC, .function_angle = NOANG },
    .{ .function_id = ITM_MULT_XFN, .function_type = FT_DYADIC, .function_angle = NOANG },
    .{ .function_id = ITM_DIV_XFN, .function_type = FT_DYADIC, .function_angle = NOANG },
    .{ .function_id = ITM_MOD_XFN, .function_type = FT_DYADIC, .function_angle = NOANG },
    .{ .function_id = 0, .function_type = 0, .function_angle = 0 },
};

fn lookupFunction(function_id: c_int) linksection(runtime.code_section) ?*const FunctionLookup {
    var idx: usize = 0;
    while (FUNCTION_TABLE[idx].function_id != 0) : (idx += 1) {
        if (FUNCTION_TABLE[idx].function_id == function_id) {
            return &FUNCTION_TABLE[idx];
        }
    }
    return null;
}

fn lookupFunctionId(function_id: c_int) linksection(runtime.code_section) c_int {
    const entry = lookupFunction(function_id);
    return if (entry) |e| e.function_type else XFN_NOTFOUND;
}

fn lookupFunctionAngle(function_id: c_int) linksection(runtime.code_section) c_int {
    const entry = lookupFunction(function_id);
    return if (entry) |e| e.function_angle else XFN_NOTFOUND;
}

// ===========================================================================
// getLongintegerRegisterAsReal1071
// ===========================================================================
fn getLongintegerRegisterAsReal1071(registerNo: calcRegister_t, result: *align(1) real_t, c: *realContext_t) linksection(runtime.code_section) bool {
    if (getRegisterDataType(registerNo) == dtLongInteger) {
        var lint: mpz_struct = undefined;
        longIntegerInit(&lint);
        var frac: bool = false;
        if (getRegisterAsLongInt(registerNo, &lint, &frac)) {
            longIntegerToString(&lint, 10, tmpString);
            longIntegerFree(&lint);
            stringToReal(@ptrCast(tmpString), result, c);
            return true;
        }
        longIntegerFree(&lint);
    } else if (getRegisterDataType(registerNo) == dtReal34) {
        if (getRegisterAsReal(registerNo, result)) {
            return true;
        }
    }
    displayCalcErrorMessage(ERROR_INPUT_DATA_TYPE_NOT_MATCHING, ERR_REGISTER_LINE, REGISTER_X);
    moreInfoOnError("In function fnXfn:getLongintegerRegisterAsReal1071:", "Invalid input register", null, null);
    return false;
}

// ===========================================================================
// getAngleModeForRegister3r / getAngleModeForArithmetic3r
// ===========================================================================
pub export fn getAngleModeForRegister3r(registerNo: calcRegister_t, angleMode: *angularMode_t) linksection(runtime.code_section) callconv(.c) bool {
    if (isXFNregisterValid3r(registerNo)) {
        if (getRegisterDataType(registerNo) == dtLongInteger) {
            angleMode.* = amNone;
            return false;
        }
        if (!inputAngleError3r(registerNo)) {
            angleMode.* = if (inputAngleMode3r(registerNo) == amNone) currentAngularMode else inputAngleMode3r(registerNo);
            return true;
        }
    } else {
        displayCalcErrorMessage(ERROR_INPUT_DATA_TYPE_NOT_MATCHING, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function fnXfn:getAngleModeForRegister3r:", "Invalid input angle register", null, null);
    }
    return false;
}

fn getAngleModeForArithmetic3r(registerNo: calcRegister_t, angleMode: *angularMode_t) linksection(runtime.code_section) bool {
    if (isXFNregisterValid3r(registerNo)) {
        if (getRegisterDataType(registerNo) == dtLongInteger) {
            angleMode.* = amNone;
            return false;
        }
        if (!inputAngleError3r(registerNo)) {
            angleMode.* = inputAngleMode3r(registerNo);
            return true;
        }
    } else {
        displayCalcErrorMessage(ERROR_INPUT_DATA_TYPE_NOT_MATCHING, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function fnXfn:getAngleModeForArithmetic3r:", "Invalid input angle register", null, null);
    }
    return false;
}

fn validateExponent(x: *align(1) const real_t) linksection(runtime.code_section) bool {
    if (realGetExponent(x) > maxAllowedDigits) {
        return false;
    }
    return true;
}

// ===========================================================================
// readThreeRegisters
// ===========================================================================
fn readThreeRegisters(registerNo: calcRegister_t, result: *align(1) real_t, temporary: *align(1) real_t, c: *realContext_t) linksection(runtime.code_section) bool {
    if (!getLongintegerRegisterAsReal1071(registerNo + 0, temporary, c)) {
        return false;
    }
    if (!getLongintegerRegisterAsReal1071(registerNo + 1, result, c)) {
        return false;
    }
    realMultiply(result, temporary, result, c);

    if (!getLongintegerRegisterAsReal1071(registerNo + 2, temporary, c)) {
        return false;
    }
    realAdd(result, temporary, result, c);
    realSetZero(temporary);
    return true;
}

// ===========================================================================
// getCombinedParameter
// ===========================================================================
fn getCombinedParameter(param: c_int, registerNo: calcRegister_t, combined: *align(1) real_t, temporary: *align(1) real_t, angleMode: *angularMode_t, c: *realContext_t) linksection(runtime.code_section) bool {
    _ = param;
    if (!getAngleModeForRegister3r(registerNo, angleMode) and getRegisterDataType(registerNo) != dtLongInteger) {
        displayCalcErrorMessage(ERROR_INPUT_DATA_TYPE_NOT_MATCHING, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function fnXfn:getCombinedParameter:", "Invalid input registers: getAngleModeForRegister3r ", null, null);
        return false;
    }
    if (!readThreeRegisters(registerNo, combined, temporary, c)) {
        displayCalcErrorMessage(ERROR_INPUT_DATA_TYPE_NOT_MATCHING, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function fnXfn:getCombinedParameter:", "Invalid input registers: readThreeRegisters", null, null);
        return false;
    }
    if (!validateExponent(combined)) {
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function fnXfn:getCombinedParameter:", "Total exceeds the maximum exponent", null, null);
        return false;
    }
    return true;
}

// ===========================================================================
// getSingleParameter
// ===========================================================================
fn getSingleParameter(registerNo: calcRegister_t, combined: *align(1) real_t, angleMode: *angularMode_t, c: *realContext_t) linksection(runtime.code_section) bool {
    angleMode.* = if (registerIsNoAngle(registerNo)) amNone else getRegisterAngularMode(registerNo);

    if (!getLongintegerRegisterAsReal1071(registerNo, combined, c)) {
        displayCalcErrorMessage(ERROR_INPUT_DATA_TYPE_NOT_MATCHING, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function fnXfn:getSingleParameter:", "Invalid input registers: getLongintegerRegisterAsReal1071", null, null);
        return false;
    }
    if (!validateExponent(combined)) {
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function fnXfn:getSingleParameter:", "Total VAR exceeds the maximum exponent", null, null);
        return false;
    }
    return true;
}

// ===========================================================================
// registerFMAOutputString
// ===========================================================================
pub export fn registerFMAOutputString(regist: calcRegister_t, prefix: [*:0]const u8, displayString: [*]u8) linksection(runtime.code_section) callconv(.c) bool {
    var angle: angularMode_t = undefined;
    var tmp1_b = BigReal(1071){};
    var tmp2_b = BigReal(1071){};
    const tmp1 = tmp1_b.ptr();
    const tmp2 = tmp2_b.ptr();
    var c: realContext_t = runtime.ctxtReal75;
    c.digits = 1000;
    c.round = DEC_ROUND_HALF_UP;
    if (getCombinedParameter(1, regist, tmp1, tmp2, &angle, &c)) {
        _ = strcpy(displayString, prefix);
        realToSci(tmp1, displayString + strlen(@ptrCast(displayString)));
        return true;
    }
    return false;
}

// registerFMAOutputPlainString: like registerFMAOutputString but emits the value
// in a plain mantissa+"E±exp" form (trailing zeros dropped) for data-file export.
// Faithful port of saveRestoreCalcState.c's helper of the same name.
pub export fn registerFMAOutputPlainString(regist: calcRegister_t, prefix: [*:0]const u8, displayString: [*]u8) linksection(runtime.code_section) callconv(.c) bool {
    var angle: angularMode_t = undefined;
    var tmp1_b = BigReal(1071){};
    var tmp2_b = BigReal(1071){};
    const tmp1 = tmp1_b.ptr();
    const tmp2 = tmp2_b.ptr();
    var c: realContext_t = runtime.ctxtReal75;
    c.digits = 1034;
    c.round = DEC_ROUND_HALF_UP;
    if (getCombinedParameter(1, regist, tmp1, tmp2, &angle, &c)) {
        _ = strcpy(displayString, prefix);
        if (realIsNaN(tmp1) or realIsInfinite(tmp1) or realIsZero(tmp1)) {
            // zero / infinity / NaN have no coefficient/exponent split: print untouched
            realToString(tmp1, displayString + strlen(@ptrCast(displayString)));
        } else {
            _ = decNumberReduce(tmp1, tmp1, &c); // drop trailing zeros: significant digits only
            const sciExp: i32 = tmp1.exponent + tmp1.digits - 1; // power of the leading digit
            tmp1.exponent = 1 - tmp1.digits; // one digit . rest, so decNumber prints it plainly
            realToString(tmp1, displayString + strlen(@ptrCast(displayString)));
            abi.fmtCStr(@ptrCast(displayString + strlen(@ptrCast(displayString))), "E{s}{d}", .{ if (sciExp >= 0) @as([*:0]const u8, "+") else @as([*:0]const u8, "-"), @abs(@as(i64, sciExp)) });
        }
        return true;
    }
    return false;
}

// ===========================================================================
// fnDrop3
// ===========================================================================
fn fnDrop3() linksection(runtime.code_section) void {
    fnDrop(NOPARAM);
    fnDrop(NOPARAM);
    fnDrop(NOPARAM);
    reallocateRegister(REGISTER_T, dtReal34, REAL34_SIZE_IN_BYTES, amNone);
    real34SetZero(registerReal34Data(REGISTER_T));
    reallocateRegister(REGISTER_A, dtReal34, REAL34_SIZE_IN_BYTES, amNone);
    real34SetZero(registerReal34Data(REGISTER_A));
    reallocateRegister(REGISTER_B, dtReal34, REAL34_SIZE_IN_BYTES, amNone);
    real34SetZero(registerReal34Data(REGISTER_B));
}

const real34_t = runtime.real34_t;
extern fn decQuadZero(destination: *align(1) real34_t) *align(1) real34_t;
inline fn real34SetZero(destination: *align(1) real34_t) void {
    _ = decQuadZero(destination);
}
const registerReal34Data = abi.registerReal34;

// ===========================================================================
// fnXXfn
// ===========================================================================
pub export fn fnXXfn(function: u16) linksection(runtime.code_section) callconv(.c) void {
    var ErrorLocation: c_int = 0;
    const functionType = lookupFunctionId(function);
    const functionAngle = lookupFunctionAngle(function);
    if (functionType == XFN_NOTFOUND) {
        ErrorLocation = 11;
    }
    doXfn(REGISTER_X, function, functionType, functionAngle, 0, ErrorLocation);
}

// ===========================================================================
// fnXfnIndirect (static)
// ===========================================================================
fn fnXfnIndirect(registerNo: calcRegister_t, function: u16, functionParam: u16) linksection(runtime.code_section) void {
    var ErrorLocation: c_int = 0;
    const functionType = lookupFunctionId(function);
    const functionAngle = lookupFunctionAngle(function);
    if (functionType == XFN_NOTFOUND) {
        ErrorLocation = 14;
    }
    if ((functionType == FT_NILADIC) or (functionType == FT_SINGLEX) or
        (functionType == FT_MONADIC and (registerNo <= FIRST_LETTERED_REGISTER - 3 or (registerNo >= FIRST_LETTERED_REGISTER and registerNo <= (LAST_SPARE_REGISTER + 1) - 3))) or
        (functionType == FT_DYADIC and (registerNo <= FIRST_LETTERED_REGISTER - 6 or (registerNo >= FIRST_LETTERED_REGISTER and registerNo <= (LAST_SPARE_REGISTER + 1) - 6))))
    {
        doXfn(registerNo, function, functionType, functionAngle, functionParam, ErrorLocation);
        return;
    }
    displayCalcErrorMessage(ERROR_UNDEF_SOURCE_VAR, ERR_REGISTER_LINE, REGISTER_X);
    moreInfoOnError("In function fnXfnIndirect:", "Specified register numbers out of range", null, null);
}

// ===========================================================================
// fnXXfn_* trampolines
// ===========================================================================
pub export fn fnXXfn_ToDEG(registerNo: u16) linksection(runtime.code_section) callconv(.c) void {
    fnXfnIndirect(@intCast(registerNo), @intCast(ITM_DEG2_XFN), 0);
}
pub export fn fnXXfn_ToRAD(registerNo: u16) linksection(runtime.code_section) callconv(.c) void {
    fnXfnIndirect(@intCast(registerNo), @intCast(ITM_RAD2_XFN), 0);
}
pub export fn fnXXfn_sin(registerNo: u16) linksection(runtime.code_section) callconv(.c) void {
    fnXfnIndirect(@intCast(registerNo), @intCast(ITM_sin_XFN), 0);
}
pub export fn fnXXfn_cos(registerNo: u16) linksection(runtime.code_section) callconv(.c) void {
    fnXfnIndirect(@intCast(registerNo), @intCast(ITM_cos_XFN), 0);
}
pub export fn fnXXfn_tan(registerNo: u16) linksection(runtime.code_section) callconv(.c) void {
    fnXfnIndirect(@intCast(registerNo), @intCast(ITM_tan_XFN), 0);
}
pub export fn fnXXfn_pi(registerNo: u16) linksection(runtime.code_section) callconv(.c) void {
    fnXfnIndirect(@intCast(registerNo), @intCast(ITM_pi_XFN), 0);
}
pub export fn fnXXfn_atan2(registerNo: u16) linksection(runtime.code_section) callconv(.c) void {
    fnXfnIndirect(@intCast(registerNo), @intCast(ITM_atan2_XFN), 0);
}
pub export fn fnXXfn_arcsin(registerNo: u16) linksection(runtime.code_section) callconv(.c) void {
    fnXfnIndirect(@intCast(registerNo), @intCast(ITM_arcsin_XFN), 0);
}
pub export fn fnXXfn_arccos(registerNo: u16) linksection(runtime.code_section) callconv(.c) void {
    fnXfnIndirect(@intCast(registerNo), @intCast(ITM_arccos_XFN), 0);
}
pub export fn fnXXfn_arctan(registerNo: u16) linksection(runtime.code_section) callconv(.c) void {
    fnXfnIndirect(@intCast(registerNo), @intCast(ITM_arctan_XFN), 0);
}
pub export fn fnXXfn_LN(registerNo: u16) linksection(runtime.code_section) callconv(.c) void {
    fnXfnIndirect(@intCast(registerNo), @intCast(ITM_LN_XFN), 0);
}
pub export fn fnXXfn_LOG(registerNo: u16) linksection(runtime.code_section) callconv(.c) void {
    fnXfnIndirect(@intCast(registerNo), @intCast(ITM_LOG_XFN), 0);
}
pub export fn fnXXfn_EXP(registerNo: u16) linksection(runtime.code_section) callconv(.c) void {
    fnXfnIndirect(@intCast(registerNo), @intCast(ITM_EXP_XFN), 0);
}
pub export fn fnXXfn_10X(registerNo: u16) linksection(runtime.code_section) callconv(.c) void {
    fnXfnIndirect(@intCast(registerNo), @intCast(ITM_10X_XFN), 0);
}
pub export fn fnXXfn_POWER(registerNo: u16) linksection(runtime.code_section) callconv(.c) void {
    fnXfnIndirect(@intCast(registerNo), @intCast(ITM_POWER_XFN), 0);
}
pub export fn fnXXfn_SQRT(registerNo: u16) linksection(runtime.code_section) callconv(.c) void {
    fnXfnIndirect(@intCast(registerNo), @intCast(ITM_SQRT_XFN), 0);
}
pub export fn fnXXfn_1ONX(registerNo: u16) linksection(runtime.code_section) callconv(.c) void {
    fnXfnIndirect(@intCast(registerNo), @intCast(ITM_1ONX_XFN), 0);
}
pub export fn fnXXfn_ADD(registerNo: u16) linksection(runtime.code_section) callconv(.c) void {
    fnXfnIndirect(@intCast(registerNo), @intCast(ITM_ADD_XFN), 0);
}
pub export fn fnXXfn_SUB(registerNo: u16) linksection(runtime.code_section) callconv(.c) void {
    fnXfnIndirect(@intCast(registerNo), @intCast(ITM_SUB_XFN), 0);
}
pub export fn fnXXfn_MULT(registerNo: u16) linksection(runtime.code_section) callconv(.c) void {
    fnXfnIndirect(@intCast(registerNo), @intCast(ITM_MULT_XFN), 0);
}
pub export fn fnXXfn_DIV(registerNo: u16) linksection(runtime.code_section) callconv(.c) void {
    fnXfnIndirect(@intCast(registerNo), @intCast(ITM_DIV_XFN), 0);
}
pub export fn fnXXfn_MOD(registerNo: u16) linksection(runtime.code_section) callconv(.c) void {
    fnXfnIndirect(@intCast(registerNo), @intCast(ITM_MOD_XFN), 0);
}
pub export fn fnXXfn_MODANG(registerNo: u16) linksection(runtime.code_section) callconv(.c) void {
    fnXfnIndirect(@intCast(registerNo), @intCast(ITM_MODANG_XFN), 0);
}
pub export fn fnXXfn_TO(registerNo: u16) linksection(runtime.code_section) callconv(.c) void {
    fnXfnIndirect(@intCast(registerNo), @intCast(ITM_TO_XFN), 0);
}
pub export fn fnXXfn_DRG(registerNo: u16) linksection(runtime.code_section) callconv(.c) void {
    fnXfnIndirect(@intCast(registerNo), @intCast(ITM_DRG_XFN), 0);
}
pub export fn fnXXfn_SQR(registerNo: u16) linksection(runtime.code_section) callconv(.c) void {
    fnXfnIndirect(@intCast(registerNo), @intCast(ITM_SQR_XFN), 0);
}
pub export fn fnXXfn_YRTX(registerNo: u16) linksection(runtime.code_section) callconv(.c) void {
    fnXfnIndirect(@intCast(registerNo), @intCast(ITM_XTHROOT_XFN), 0);
}
pub export fn fnXXfn_RDP(digits: u16) linksection(runtime.code_section) callconv(.c) void {
    fnXfnIndirect(REGISTER_X, @intCast(ITM_RDP_XFN), digits);
}
pub export fn fnXXfn_RSD(digits: u16) linksection(runtime.code_section) callconv(.c) void {
    fnXfnIndirect(REGISTER_X, @intCast(ITM_RSD_XFN), digits);
}
pub export fn fnXXfn_CHS(registerNo: u16) linksection(runtime.code_section) callconv(.c) void {
    fnXfnIndirect(@intCast(registerNo), @intCast(ITM_CHS_XFN), 0);
}

// ===========================================================================
// doXfn (static dispatcher)
// ===========================================================================
fn doXfn(registerNo: calcRegister_t, function: c_int, functionType: c_int, functionAngle: c_int, functionParam: u16, ErrorLocation: c_int) linksection(runtime.code_section) void {
    if (ErrorLocation != 0 or function == XFN_NOTFOUND or functionType == XFN_NOTFOUND) {
        // goto noFunction
        noFunction();
        return;
    }

    if (!saveLastX()) {
        return;
    }

    var paramX_b = BigReal(1071){};
    var paramY_b = BigReal(1071){};
    var paramTemp_b = BigReal(1071){};
    const paramX = paramX_b.ptr();
    const paramY = paramY_b.ptr();
    const paramTemp = paramTemp_b.ptr();
    realSetZero(paramX);
    var tmpR: real_t = undefined;

    var c: realContext_t = runtime.ctxtReal75;
    c.digits = maxContextDigits;

    var angleMode: angularMode_t = currentAngularMode;
    var tmpAngle: angularMode_t = undefined;

    if (functionType == FT_NILADIC) {
        // no input needed, continue
    } else if (functionType == FT_SINGLEX) {
        if (!getSingleParameter(registerNo, paramX, &angleMode, &c)) {
            return;
        }
    } else if (functionType == FT_MONADIC or functionType == FT_DYADIC) {
        if (!getCombinedParameter(1, registerNo, paramX, paramTemp, &angleMode, &c)) {
            return;
        }
        if (functionType == FT_DYADIC) {
            if (!getCombinedParameter(2, registerNo + 3, paramY, paramTemp, &tmpAngle, &c)) {
                return;
            }
        }
        if (functionAngle == FORCEANG and angleMode == amNone) {
            angleMode = currentAngularMode;
        }
    } else {
        noFunction();
        return;
    }

    if (realIsSpecial(paramX)) {
        realSetNaN(paramX);
    } else {
        switch (function) {
            // NILADIC
            ITM_pi_XFN => {
                realCopy(const1071_pi(), paramX);
            },
            // MONADIC
            ITM_RAD2_XFN => {
                if (inputIsNoAngle3r(registerNo)) {
                    angleMode = amRadian;
                } else {
                    if (!inputAngleError3r(registerNo) and angleMode != amRadian) {
                        realDivide(paramX, modulus(angleMode), paramX, &c);
                        realMultiply(paramX, modulus(amRadian), paramX, &c);
                    }
                    angleMode = amRadian;
                }
            },
            ITM_DEG2_XFN => {
                if (inputIsNoAngle3r(registerNo)) {
                    angleMode = amDegree;
                } else {
                    if (!inputAngleError3r(registerNo) and angleMode != amDegree) {
                        realDivide(paramX, modulus(angleMode), paramX, &c);
                        realMultiply(paramX, modulus(amDegree), paramX, &c);
                    }
                    angleMode = amDegree;
                }
            },
            ITM_DRG_XFN => {
                const nextAngleMode: angularMode_t = if (angleMode == amDegree) amRadian else if (angleMode == amRadian) amGrad else if (angleMode == amGrad) amMultPi else if (angleMode == amMultPi) amDegree else amDegree;
                if (inputIsNoAngle3r(registerNo)) {
                    angleMode = currentAngularMode;
                } else {
                    if (!inputAngleError3r(registerNo) and angleMode != nextAngleMode) {
                        realDivide(paramX, modulus(angleMode), paramX, &c);
                        realMultiply(paramX, modulus(nextAngleMode), paramX, &c);
                    }
                    angleMode = nextAngleMode;
                }
            },
            ITM_sin_XFN, ITM_cos_XFN, ITM_tan_XFN => {
                var aa_b = BigReal(1071){};
                var bb_b = BigReal(1071){};
                const aa = aa_b.ptr();
                const bb = bb_b.ptr();
                realSetZero(aa);
                realSetZero(bb);
                if (function == ITM_sin_XFN) {
                    C47Cvt2RadSinCosTan1071(paramX, angleMode, paramX, null, null, &c);
                } else if (function == ITM_cos_XFN) {
                    C47Cvt2RadSinCosTan1071(paramX, angleMode, null, paramX, null, &c);
                } else if (function == ITM_tan_XFN) {
                    C47Cvt2RadSinCosTan1071(paramX, angleMode, aa, bb, paramX, &c);
                }
            },
            ITM_arcsin_XFN => {
                C47_WP34S_Asin1071(paramX, paramX, &c);
                convertAngleFromTo(paramX, amRadian, currentAngularMode, &c);
            },
            ITM_arccos_XFN => {
                C47_WP34S_Acos1071(paramX, paramX, &c);
                convertAngleFromTo(paramX, amRadian, currentAngularMode, &c);
            },
            ITM_arctan_XFN => {
                C47_WP34S_Atan1071(paramX, paramX, &c);
                convertAngleFromTo(paramX, amRadian, currentAngularMode, &c);
            },
            ITM_LN_XFN => {
                _ = decNumberLn(paramX, paramX, &c);
            },
            ITM_LOG_XFN => {
                _ = decNumberLn(paramX, paramX, &c);
                _ = decNumberLn(paramTemp, const_10(), &c);
                realDivide(paramX, paramTemp, paramX, &c);
            },
            ITM_EXP_XFN => {
                _ = decNumberExp(paramX, paramX, &c);
            },
            ITM_10X_XFN => {
                realPower(const_10(), paramX, paramX, &c);
            },
            ITM_SQRT_XFN => {
                realPower(paramX, const_1on2(), paramX, &c);
            },
            ITM_SQR_XFN => {
                realPower(paramX, const_2(), paramX, &c);
            },
            ITM_1ONX_XFN => {
                realDivide(const_1(), paramX, paramX, &c);
            },
            ITM_MODANG_XFN => {
                if (angleMode == amRadian) {
                    math_wp34s.mod2Pi(paramX, paramX, &c);
                } else {
                    math_wp34s.WP34S_Mod(paramX, modulus(angleMode), paramX, &c);
                }
            },
            ITM_RDP_XFN => {
                math_rdp.roundToDecimalPlace(@alignCast(paramX), @alignCast(paramX), functionParam, &c);
            },
            ITM_RSD_XFN => {
                math_rsd.roundToSignificantDigits(@alignCast(paramX), @alignCast(paramX), functionParam, &c);
            },
            ITM_CHS_XFN => {
                realMultiply(const__1(), paramX, paramX, &c);
            },
            // SINGLE REG
            ITM_TO_XFN => {
                // paramX input ->> output
            },
            // DYADIC
            ITM_ADD_XFN => {
                realAdd(paramY, paramX, paramX, &c);
            },
            ITM_SUB_XFN => {
                realSubtract(paramY, paramX, paramX, &c);
            },
            ITM_POWER_XFN => {
                realPower(paramY, paramX, paramX, &c);
            },
            ITM_XTHROOT_XFN => {
                realDivide(const_1(), paramX, paramX, &c);
                realPower(paramY, paramX, paramX, &c);
            },
            ITM_MULT_XFN => {
                realMultiply(paramY, paramX, paramX, &c);
            },
            ITM_DIV_XFN => {
                realDivide(paramY, paramX, paramX, &c);
            },
            ITM_MOD_XFN => {
                math_wp34s.WP34S_BigMod(paramY, paramX, paramX, &c);
            },
            ITM_atan2_XFN => {
                C47_WP34S_Atan2_1071(paramY, paramX, paramX, &c);
                convertAngleFromTo(paramX, amRadian, currentAngularMode, &c);
            },
            else => {
                noFunction();
                return;
            },
        }
    }

    // Clip to 1034 digits
    var cc: realContext_t = runtime.ctxtReal75;
    cc.digits = maxAllowedDigits + 34;
    cc.round = DEC_ROUND_HALF_UP;
    realPlus(paramX, paramX, &cc);

    // Step 00: Handle the angle
    switch (function) {
        ITM_arcsin_XFN, ITM_arccos_XFN, ITM_arctan_XFN, ITM_atan2_XFN => {
            angleMode = currentAngularMode;
        },
        ITM_RAD2_XFN, ITM_DEG2_XFN, ITM_DRG_XFN => {
            // leave angleMode, it is set in the function
        },
        ITM_ADD_XFN, ITM_SUB_XFN, ITM_MULT_XFN => {
            if (!getAngleModeForArithmetic3r(registerNo + 3, &angleMode)) {
                if (!getAngleModeForArithmetic3r(registerNo, &angleMode)) {
                    angleMode = amNone;
                }
            }
        },
        ITM_TO_XFN => {
            angleMode = amNone;
        },
        else => {
            angleMode = amNone;
        },
    }

    // Step 0: Prep the stack
    if ((functionType == FT_MONADIC or functionType == FT_DYADIC) and registerNo == REGISTER_X and lastErrorCode == 0) {
        fnDrop3();
    } else if (functionType == FT_SINGLEX) {
        fnDrop(NOPARAM);
    }

    // Step 1: Send a 0 addition term to the stack output
    setSystemFlagAslift();
    liftStack();
    reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
    realSetZero(&tmpR);
    convertRealToReal34ResultRegister(&tmpR, REGISTER_X);
    adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);

    // Step 2: Send integer part to stack output
    setSystemFlagAslift();
    liftStack();
    var integerOutput: mpz_struct = undefined;
    longIntegerInit(&integerOutput);
    decomposeReal(paramX, &integerOutput, paramY, &c);
    convertLongIntegerToLongIntegerRegister(&integerOutput, REGISTER_X);
    longIntegerFree(&integerOutput);

    // Step 3: Send real multiplier to the stack output
    setSystemFlagAslift();
    liftStack();
    realPlus(paramY, &tmpR, &runtime.ctxtReal75);
    convertRealToResultRegister(&tmpR, REGISTER_X, angleMode);
    adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);

    // Step 4: update difference term; re-using paramY
    if (functionType == FT_NILADIC or functionType == FT_MONADIC or functionType == FT_DYADIC) {
        if (!getCombinedParameter(1, REGISTER_X, paramY, paramTemp, &tmpAngle, &c)) {
            return;
        }
        realSubtract(paramX, paramY, paramY, &c);
        realPlus(paramY, &tmpR, &runtime.ctxtReal75);
        convertRealToResultRegister(&tmpR, REGISTER_Z, amNone);
    }

    // Step 6: drop T, A, B for a successful dyadic function (C xfn.c:794-799)
    if (lastErrorCode == 0 and functionType == FT_DYADIC) {
        fnDropT(NOPARAM);
        fnDropT(NOPARAM);
        fnDropT(NOPARAM);
    }

    return;
}

fn noFunction() linksection(runtime.code_section) void {
    displayCalcErrorMessage(ERROR_UNDEFINED_OPCODE, ERR_REGISTER_LINE, REGISTER_X);
    moreInfoOnError("In function doXfn:", "Incorrect function code", null, null);
}
