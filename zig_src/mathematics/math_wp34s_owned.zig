// SPDX-License-Identifier: GPL-3.0-only
const abi = @import("abi");
const consts = abi.constants;
//
// Zig owner for src/c47/mathematics/wp34s.c: the high-precision WP34S
// transcendental engine borrowed from the WP 34S project. Faithful, line-by-
// line translation preserving the exact order of every real_t / decNumber
// operation (the trig and gamma testSuite checks results to the last ULP, so a
// reordered add / multiply or a changed context-digit count fails).
//
// Public surface (wp34s.h) is exported with C linkage so the trig / gamma
// callers and the distribution owners keep their ABI. The high-precision Taylor
// variants build a local context by copying realContext and bumping `.digits`;
// those manipulations are reproduced exactly because they control the precision
// (and therefore the result). The PC_BUILD console diagnostics (DEBUGTAYLOR,
// the EXTRA_INFO sprintf hints) have no effect on the computed result and are
// dropped; the host-only progress / exit-key control flow is preserved.
//
// real_t constants without a runtime accessor come from the shared `constants`
// blob by offset (the conversionAngles pattern); cstR() returns an unaligned
// pointer so the macOS host build (byte-aligned blob base) does not trap, and
// the real_t op helpers accept *align(1) const operands. The 1071-digit local
// REAL_T_PTR scratch values become naturally-sized, 4-byte-aligned stack byte
// buffers cast to *real_t. WP34S_Mod / WP34S_BigMod reproduce the DM42-only
// small-buffer path via the wp34s_mod_small_buffers build option.

const runtime = @import("math_command_wrappers_runtime.zig");

const real_t = runtime.real_t;
const realContext_t = runtime.realContext_t;
const angularMode_t = runtime.angularMode_t;

const amRadian = runtime.amRadian;
const amGrad = runtime.amGrad;
const amDegree = runtime.amDegree;
const amDMS = runtime.amDMS;
const amMultPi = runtime.amMultPi;

// ---------------------------------------------------------------------------
// real_t constant blob accessors. Use the runtime accessors where they exist
// (properly aligned *align(1) const real_t); otherwise the byte-offset blob pattern.
// ---------------------------------------------------------------------------
const cstR = consts.cstR;

// Offsets extracted from the generated constantPointers.h.
const OFF_const51_gammaC01: u32 = 6112;

// REAL_SIZE_IN_BYTES(51) for indexing const51_gammaC01[k].
const REAL_SIZE_51: u32 = 44;

inline fn const_0() *align(1) const real_t {
    return consts.c1708();
}
inline fn const_1() *align(1) const real_t {
    return consts.c4856();
}
inline fn const_2() *align(1) const real_t {
    return consts.c4928();
}
inline fn const_3() *align(1) const real_t {
    return consts.c5012();
}
inline fn const__1() *align(1) const real_t {
    return consts.c4376();
}
inline fn const_1on2() *align(1) const real_t {
    return consts.c4580();
}
inline fn const_1on4() *align(1) const real_t {
    return consts.c4532();
}
inline fn const_1on10() *align(1) const real_t {
    return consts.c4520();
}
inline fn const_29() *align(1) const real_t {
    return consts.c5180();
}
inline fn const_45() *align(1) const real_t {
    return consts.c7628();
}
inline fn const_47() *align(1) const real_t {
    return consts.c5236();
}
inline fn const_50() *align(1) const real_t {
    return consts.c7616();
}
inline fn const_90() *align(1) const real_t {
    return consts.c7544();
}
inline fn const_100() *align(1) const real_t {
    return consts.c7532();
}
inline fn const_180() *align(1) const real_t {
    return consts.c7460();
}
inline fn const_200() *align(1) const real_t {
    return consts.c7448();
}
inline fn const_205() *align(1) const real_t {
    return consts.c5344();
}
inline fn const_360() *align(1) const real_t {
    return consts.c5356();
}
inline fn const_400() *align(1) const real_t {
    return consts.c5368();
}
inline fn const_9000() *align(1) const real_t {
    return consts.c5460();
}
inline fn const_995on1000() *align(1) const real_t {
    return consts.c5696();
}
inline fn const_1e_10000() *align(1) const real_t {
    return consts.c5684();
}
inline fn const_1e_24() *align(1) const real_t {
    return consts.c4472();
}
inline fn const_1e_37() *align(1) const real_t {
    return consts.c4436();
}
inline fn const_1e_49() *align(1) const real_t {
    return consts.c4424();
}
inline fn const_gammaR() *align(1) const real_t {
    return consts.c5192();
}
inline fn const_NaN() *align(1) const real_t {
    return consts.c812();
}
inline fn const_minusInfinity() *align(1) const real_t {
    return consts.c1684();
}
inline fn const39_pi() *align(1) const real_t {
    return consts.c1848();
}
inline fn const39_2pi() *align(1) const real_t {
    return consts.c1812();
}
inline fn const39_piOn2() *align(1) const real_t {
    return consts.c4880();
}
inline fn const39_piOn4() *align(1) const real_t {
    return consts.c4736();
}
inline fn const39_3piOn4() *align(1) const real_t {
    return consts.c4976();
}
inline fn const39_ln2() *align(1) const real_t {
    return consts.c4628();
}
inline fn const39_ln10() *align(1) const real_t {
    return consts.c4940();
}
inline fn const39_root2on2() *align(1) const real_t {
    return consts.c4700();
}
inline fn const39_egamma() *align(1) const real_t {
    return consts.c4592();
}
inline fn const39_eE() *align(1) const real_t {
    return consts.c176();
}
inline fn const39_1on3() *align(1) const real_t {
    return consts.c4544();
}
inline fn const75_pi() *align(1) const real_t {
    return consts.c7388();
}
inline fn const75_piOn2() *align(1) const real_t {
    return consts.c7472();
}
inline fn const75_piOn4() *align(1) const real_t {
    return consts.c7556();
}
inline fn const75_3piOn4() *align(1) const real_t {
    return consts.c7700();
}
inline fn const1071_pi() *align(1) const real_t {
    return consts.c9932();
}
inline fn const1071_piOn2() *align(1) const real_t {
    return consts.c9208();
}
inline fn const1071_piOn4() *align(1) const real_t {
    return consts.c8484();
}
inline fn const1071_3piOn4() *align(1) const real_t {
    return consts.c7760();
}
inline fn const51_gammaC00() *align(1) const real_t {
    return consts.c6068();
}
inline fn const51_gammaC01(k: u32) *align(1) const real_t {
    return consts.cstR(OFF_const51_gammaC01 + k * REAL_SIZE_51);
}
inline fn const6147_2pi() *align(1) const real_t {
    return consts.c12092();
}

// ---------------------------------------------------------------------------
// Globals / externs.
// ---------------------------------------------------------------------------
extern var ctxtReal39: realContext_t;
extern var explicitTaylorIterVisibilitySelection: bool;

// decNumber primitives (the realType.h macros expand to these).
extern fn decNumberCopy(res: *align(1) real_t, source: *align(1) const real_t) *align(1) real_t;
extern fn decNumberCopyAbs(res: *align(1) real_t, source: *align(1) const real_t) *align(1) real_t;
extern fn decNumberPlus(res: *align(1) real_t, operand: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
extern fn decNumberMinus(res: *align(1) real_t, operand: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
extern fn decNumberAdd(res: *align(1) real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
extern fn decNumberSubtract(res: *align(1) real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
extern fn decNumberMultiply(res: *align(1) real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
extern fn decNumberDivide(res: *align(1) real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
extern fn decNumberSquareRoot(res: *align(1) real_t, rhs: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
extern fn decNumberPower(res: *align(1) real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
extern fn decNumberCompare(res: *align(1) real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
extern fn decNumberRemainder(res: *align(1) real_t, op1: *align(1) const real_t, op2: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
extern fn decNumberFromString(res: *align(1) real_t, source: [*:0]const u8, ctxt: *realContext_t) *align(1) real_t;
extern fn decNumberFromInt32(res: *align(1) real_t, source: i32) *align(1) real_t;
extern fn decNumberFromUInt32(res: *align(1) real_t, source: u32) *align(1) real_t;

// real* setters / predicates.
extern fn realSetNaN(value: *align(1) real_t) void;
extern fn realSetPlusInfinity(value: *align(1) real_t) void;
extern fn realSetMinusInfinity(value: *align(1) real_t) void;
extern fn realIsAnInteger(x: *align(1) const real_t) bool;
extern fn realCompareEqual(n1: *align(1) const real_t, n2: *align(1) const real_t) bool;
extern fn realCompareGreaterEqual(n1: *align(1) const real_t, n2: *align(1) const real_t) bool;
extern fn realCompareGreaterThan(n1: *align(1) const real_t, n2: *align(1) const real_t) bool;
extern fn realCompareLessEqual(n1: *align(1) const real_t, n2: *align(1) const real_t) bool;
extern fn realCompareLessThan(n1: *align(1) const real_t, n2: *align(1) const real_t) bool;
extern fn realCompareAbsLessThan(n1: *align(1) const real_t, n2: *align(1) const real_t) bool;
extern fn realCompareAbsGreaterThan(n1: *align(1) const real_t, n2: *align(1) const real_t) bool;

// Higher-level real ops / transcendentals from elsewhere in the tree.
extern fn realPower10(x: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void;
extern fn realExp(rhs: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void;
extern fn realExpLimitCheck(x: *align(1) const real_t, res: *align(1) real_t, zero: *align(1) const real_t) bool;
extern fn convertAngleFromTo(angle: *align(1) real_t, from: angularMode_t, to: angularMode_t, ctxt: *realContext_t) void;

// Complex helpers used by the complex-gamma / lambert / error paths.
extern fn mulComplexComplex(f1r: *align(1) const real_t, f1i: *align(1) const real_t, f2r: *align(1) const real_t, f2i: *align(1) const real_t, pr: *align(1) real_t, pi: *align(1) real_t, ctxt: *realContext_t) void;
extern fn divComplexComplex(nr: *align(1) const real_t, ni: *align(1) const real_t, dr: *align(1) const real_t, di: *align(1) const real_t, qr: *align(1) real_t, qi: *align(1) real_t, ctxt: *realContext_t) void;
extern fn divRealComplex(numer: *align(1) const real_t, dr: *align(1) const real_t, di: *align(1) const real_t, qr: *align(1) real_t, qi: *align(1) real_t, ctxt: *realContext_t) void;
extern fn lnComplex(re: *align(1) const real_t, im: *align(1) const real_t, lr: *align(1) real_t, li: *align(1) real_t, ctxt: *realContext_t) void;
extern fn sinComplex(re: *align(1) const real_t, im: *align(1) const real_t, rr: *align(1) real_t, ri: *align(1) real_t, ctxt: *realContext_t) void;
extern fn expComplex(re: *align(1) const real_t, im: *align(1) const real_t, rr: *align(1) real_t, ri: *align(1) real_t, ctxt: *realContext_t) void;
extern fn complexMagnitude(a: *align(1) const real_t, b: *align(1) const real_t, c: *align(1) real_t, ctxt: *realContext_t) void;
extern fn LnBeta(x: *align(1) const real_t, y: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void;
extern fn WP34S_Cdf_Q(x: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void;

// Orthogonal polynomial kind constants (defines.h:2043 — order matters; the C
// caller in ortho_polynom.c passes these exact values to switch on).
const ORTHOPOLY_HERMITE_H: u16 = 0;
const ORTHOPOLY_HERMITE_HE: u16 = 1;
const ORTHOPOLY_LAGUERRE_L: u16 = 2;
const ORTHOPOLY_LAGUERRE_L_ALPHA: u16 = 3;
const ORTHOPOLY_LEGENDRE_P: u16 = 4;
const ORTHOPOLY_CHEBYSHEV_T: u16 = 5;
const ORTHOPOLY_CHEBYSHEV_U: u16 = 6;

// Host-only progress / abort control flow (preserved for side effects).
extern fn checkHalfSec() bool;
extern fn exitKeyWaiting() bool;
extern fn progressHalfSecUpdate_Integer(mode: u8, txt: [*:0]const u8, loop: i32, clearZ: bool, clearT: bool, disp: bool) bool;
extern fn monitorExit(loop: *i32, str: [*:0]const u8) bool;
extern fn displayCalcErrorMessage(error_code: u8, err_message_register_line: runtime.calcRegister_t, err_register_line: runtime.calcRegister_t) void;

const ERROR_SOLVER_ABORT: u8 = 60;
const REGISTER_T: runtime.calcRegister_t = 103;
const NIM_REGISTER_LINE: runtime.calcRegister_t = 100; // REGISTER_X
const halfSec_timed: u8 = 0;
const halfSec_force: u8 = 1;
const halfSec_clearZ: bool = true;
const halfSec_clearT: bool = true;
const halfSec_disp: bool = true;
const TaylorIterationMax: i32 = 1000;

// ---------------------------------------------------------------------------
// real_t op helpers mirroring the realType.h macro argument order. Operands are
// *align(1) const real_t so blob constants and stack scratch both work.
// ---------------------------------------------------------------------------
inline fn realCopy(source: *align(1) const real_t, destination: *align(1) real_t) void {
    _ = decNumberCopy(destination, source);
}
inline fn realCopyAbs(source: *align(1) const real_t, destination: *align(1) real_t) void {
    _ = decNumberCopyAbs(destination, source);
}
inline fn realPlus(operand: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberPlus(res, operand, ctxt);
}
inline fn realMinus(operand: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberMinus(res, operand, ctxt);
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
inline fn realSquareRoot(operand: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberSquareRoot(res, operand, ctxt);
}
inline fn realPower(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberPower(res, op1, op2, ctxt);
}
inline fn realCompare(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberCompare(res, op1, op2, ctxt);
}
inline fn realDivideRemainder(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberRemainder(res, op1, op2, ctxt);
}
inline fn stringToReal(source: [*:0]const u8, destination: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberFromString(destination, source, ctxt);
}
inline fn int32ToReal(source: i32, destination: *align(1) real_t) void {
    _ = decNumberFromInt32(destination, source);
}
inline fn uInt32ToReal(source: u32, destination: *align(1) real_t) void {
    _ = decNumberFromUInt32(destination, source);
}

inline fn realSetOne(r: *align(1) real_t) void {
    _ = decNumberFromInt32(r, 1);
}
inline fn realSetZero(r: *align(1) real_t) void {
    _ = decNumberFromInt32(r, 0);
}
inline fn realIsNegative(source: *align(1) const real_t) bool {
    return (source.bits & 0x80) == 0x80;
}
inline fn realIsPositive(source: *align(1) const real_t) bool {
    return (source.bits & 0x80) == 0x00;
}
inline fn realIsZero(source: *align(1) const real_t) bool {
    return source.digits == 1 and source.lsu[0] == 0 and !realIsSpecial(source);
}
inline fn realIsSpecial(source: *align(1) const real_t) bool {
    return (source.bits & 0x70) != 0;
}
inline fn realIsInfinite(source: *align(1) const real_t) bool {
    return (source.bits & 0x40) != 0;
}
inline fn realIsNaN(source: *align(1) const real_t) bool {
    return (source.bits & (0x20 | 0x10)) != 0;
}
inline fn realChangeSign(operand: *align(1) real_t) void {
    operand.bits ^= 0x80;
}
inline fn realSetNegativeSign(operand: *align(1) real_t) void {
    operand.bits |= 0x80;
}
inline fn realSetPositiveSign(operand: *align(1) real_t) void {
    operand.bits &= 0x7F;
}
inline fn realGetExponent(source: *align(1) const real_t) i32 {
    return source.digits + source.exponent - 1;
}

inline fn maxI32(a: i32, b: i32) i32 {
    return if (a > b) a else b;
}

// ---------------------------------------------------------------------------
// REAL_T_PTR(name, digits): a stack scratch real_t with `digits` capacity. The
// underlying buffer is REAL_SIZE_IN_BYTES(digits) = 10 + 2*(REAL_MAX_DIGITS/3),
// 4-byte aligned, cast to *real_t.
// ---------------------------------------------------------------------------
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

// ===========================================================================
// reduceAngleToRange
// ===========================================================================
pub export fn reduceAngleToRange(
    angle: *align(1) real_t,
    angle45: *(*align(1) const real_t),
    angle90: *(*align(1) const real_t),
    angle180: *(*align(1) const real_t),
    angularMode: *angularMode_t,
    savedContextDigits: i32,
    realContext: *realContext_t,
) callconv(.c) void {
    switch (angularMode.*) {
        amRadian => {
            if (savedContextDigits >= 1071) {
                angle45.* = const1071_piOn4();
                angle90.* = const1071_piOn2();
                angle180.* = const1071_pi();
            } else {
                angle45.* = const75_piOn4();
                angle90.* = const75_piOn2();
                angle180.* = const75_pi();
            }
            mod2Pi(angle, angle, realContext); // mod(angle, 2pi) --> angle
        },
        amMultPi => {
            angle45.* = const_1on4();
            angle90.* = const_1on2();
            angle180.* = const_1();
            WP34S_Mod(angle, const_2(), angle, realContext); // mod(angle, 2) --> angle
        },
        amGrad => {
            angle45.* = const_50();
            angle90.* = const_100();
            angle180.* = const_200();
            WP34S_Mod(angle, const_400(), angle, realContext); // mod(angle, 400g) --> angle
        },
        amDegree, amDMS => {
            angle45.* = const_45();
            angle90.* = const_90();
            angle180.* = const_180();
            WP34S_Mod(angle, const_360(), angle, realContext); // mod(angle, 360) --> angle
            angularMode.* = amDegree;
        },
        else => {},
    }
}

// ===========================================================================
// doWP34S_SinCosTanTaylor (static)
// ===========================================================================
fn doWP34S_SinCosTanTaylor(
    angle: *align(1) real_t,
    sinNeg: *bool,
    cosNeg: *bool,
    swap: *bool,
    sinOut: ?*align(1) real_t,
    cosOut: ?*align(1) real_t,
    tanOut: ?*align(1) real_t,
    angularMode_arg: angularMode_t,
    savedContextDigits: i32,
    realContext: *realContext_t,
) void {
    var angularMode = angularMode_arg;
    var angle45: *align(1) const real_t = const_0();
    var angle90: *align(1) const real_t = const_0();
    var angle180: *align(1) const real_t = const_0();

    // sin(-x) = -sin(x), cos(-x) = cos(x)
    if (realIsNegative(angle)) {
        sinNeg.* = true;
        realSetPositiveSign(angle);
    }

    reduceAngleToRange(@ptrCast(angle), &angle45, &angle90, &angle180, &angularMode, savedContextDigits, realContext);

    // sin(180+x) = -sin(x), cos(180+x) = -cos(x)
    if (realCompareGreaterEqual(angle, angle180)) { // angle >= 180
        realSubtract(angle, angle180, angle, realContext); // angle - 180 --> angle
        sinNeg.* = !(sinNeg.*);
        cosNeg.* = !(cosNeg.*);
    }

    // sin(90+x) = cos(x), cos(90+x) = -sin(x)
    if (realCompareGreaterEqual(angle, angle90)) { // angle >= 90
        realSubtract(angle, angle90, angle, realContext); // angle - 90 --> angle
        swap.* = true;
        cosNeg.* = !(cosNeg.*);
    }

    // sin(90-x) = cos(x), cos(90-x) = sin(x)
    if (realCompareEqual(angle, angle45)) { // angle == 45
        if (sinOut) |s| {
            realCopy(const39_root2on2(), s);
        }
        if (cosOut) |c| {
            realCopy(const39_root2on2(), c);
        }
        if (tanOut) |t| {
            realSetOne(t);
        }
    } else { // angle < 90
        if (realCompareGreaterThan(angle, angle45)) { // angle > 45
            realSubtract(angle90, angle, angle, realContext); // 90 - angle --> angle
            swap.* = !(swap.*);
        }
        convertAngleFromTo(angle, angularMode, amRadian, realContext);
        if (savedContextDigits >= 1071) {
            C47_WP34S_SinCosTanTaylor_temp1071(angle, swap.*, if (swap.*) cosOut else sinOut, if (swap.*) sinOut else cosOut, tanOut, realContext);
        } else {
            C47_WP34S_SinCosTanTaylor_temp75(angle, swap.*, if (swap.*) cosOut else sinOut, if (swap.*) sinOut else cosOut, tanOut, realContext);
        }
    }

    realContext.digits = savedContextDigits;

    if (sinOut) |s| {
        if (sinNeg.*) {
            realSetNegativeSign(s);
            if (tanOut) |t| {
                realSetNegativeSign(t);
            }
        }
        if (realIsZero(s)) {
            realSetPositiveSign(s);
            if (tanOut) |t| {
                realSetPositiveSign(t);
            }
        }
        realPlus(s, s, realContext);
    }

    if (cosOut) |c| {
        if (cosNeg.*) {
            realSetNegativeSign(c);
            if (tanOut) |t| {
                realChangeSign(t);
            }
        }
        if (realIsZero(c)) {
            realSetPositiveSign(c);
        }
        realPlus(c, c, realContext);
    }

    if (tanOut != null and cosOut != null and realIsZero(cosOut.?)) {
        realSetPositiveSign(tanOut.?);
        realPlus(tanOut.?, tanOut.?, realContext);
    }
}

// ===========================================================================
// C47_WP34S_Cvt2RadSinCosTan_75temp (static)
// ===========================================================================
fn C47_WP34S_Cvt2RadSinCosTan_75temp(an: *align(1) const real_t, angularMode: angularMode_t, sinOut: ?*align(1) real_t, cosOut: ?*align(1) real_t, tanOut: ?*align(1) real_t, realContext: *realContext_t) void {
    var sinNeg: bool = false;
    var cosNeg: bool = false;
    var swap: bool = false;
    var angle: real_t = undefined;

    if (realIsNaN(an)) {
        if (sinOut) |s| realSetNaN(s);
        if (cosOut) |c| realSetNaN(c);
        if (tanOut) |t| realSetNaN(t);
        return;
    }

    realCopy(an, &angle);

    const savedContextDigits = realContext.digits;

    if (realContext.digits > 51) {
        realContext.digits = 75;
    } else {
        realContext.digits = 51;
    }

    doWP34S_SinCosTanTaylor(&angle, &sinNeg, &cosNeg, &swap, sinOut, cosOut, tanOut, angularMode, savedContextDigits, realContext);
}

// ===========================================================================
// doTaylorIterations (static)
// ===========================================================================
fn doTaylorIterations(
    a: *align(1) const real_t,
    angle: *align(1) real_t,
    a2: *align(1) real_t,
    t: *align(1) real_t,
    j: *align(1) real_t,
    z: *align(1) real_t,
    sin: *align(1) real_t,
    cos: *align(1) real_t,
    sinOut: ?*align(1) real_t,
    cosOut: ?*align(1) real_t,
    epsilonOrCompare: *align(1) real_t,
    doEpsilon: bool,
    epsilonDigits: i32,
    realContext: *realContext_t,
) void {
    var tmpEpsilon: [16]u8 = undefined;
    var endSin: bool = (sinOut == null);
    var endCos: bool = (cosOut == null);

    if (doEpsilon) {
        stringToReal(formatEminusD(&tmpEpsilon, epsilonDigits), epsilonOrCompare, realContext);
    }
    realCopy(a, angle);
    realMultiply(angle, angle, a2, realContext);
    realSetOne(j);
    realSetOne(t);
    realSetOne(sin);
    realSetOne(cos);

    var i: i32 = 1;
    while (!(endSin and endCos) and i < TaylorIterationMax) : (i += 1) {
        realAdd(j, const_1(), j, realContext);
        realDivide(a2, j, z, realContext);
        realMultiply(t, z, t, realContext);
        realChangeSign(t);
        var tExp = realGetExponent(t);

        if (!endCos) {
            realCopy(cos, z);
            realAdd(cos, t, cos, realContext);
            if (doEpsilon) {
                realCopyAbs(t, z);
            } else {
                realCompare(cos, z, epsilonOrCompare, realContext);
            }
            endCos = (!doEpsilon and realIsZero(epsilonOrCompare)) or (doEpsilon and realCompareLessThan(z, epsilonOrCompare));
        }

        realAdd(j, const_1(), j, realContext);
        realDivide(t, j, t, realContext);
        tExp = maxI32(tExp, realGetExponent(t));

        if (!endSin) {
            realCopy(sin, z);
            realAdd(sin, t, sin, realContext);
            if (doEpsilon) {
                realCopyAbs(t, z);
            } else {
                realCompare(sin, z, epsilonOrCompare, realContext);
            }
            endSin = (!doEpsilon and realIsZero(epsilonOrCompare)) or (doEpsilon and realCompareLessThan(z, epsilonOrCompare));
        }

        if (explicitTaylorIterVisibilitySelection and checkHalfSec()) {
            _ = progressHalfSecUpdate_Integer(halfSec_timed, "Taylor Iter", epsilonDigits, halfSec_clearZ, halfSec_clearT, halfSec_disp);
        }
        if (exitKeyWaiting()) {
            _ = progressHalfSecUpdate_Integer(halfSec_force + 1, "Interrupted Iter:", i, halfSec_clearZ, halfSec_clearT, halfSec_disp);
            displayCalcErrorMessage(ERROR_SOLVER_ABORT, REGISTER_T, NIM_REGISTER_LINE);
            break;
        }
    }

    if (realIsZero(cos)) {
        realSetPositiveSign(cos);
    }
    if (realIsZero(sin)) {
        realSetPositiveSign(sin);
    }
    realMultiply(sin, angle, sin, realContext);
    explicitTaylorIterVisibilitySelection = false;
}

// Helper: render "1E-<d>" into the provided buffer (sprintf in the C).
fn formatEminusD(buf: *[16]u8, d: i32) [*:0]const u8 {
    var tmp: [16]u8 = undefined;
    var n: usize = 0;
    var v: u32 = @intCast(d);
    if (v == 0) {
        tmp[0] = '0';
        n = 1;
    } else {
        while (v != 0) : (v /= 10) {
            tmp[n] = '0' + @as(u8, @intCast(v % 10));
            n += 1;
        }
    }
    var idx: usize = 0;
    buf[idx] = '1';
    idx += 1;
    buf[idx] = 'E';
    idx += 1;
    buf[idx] = '-';
    idx += 1;
    var k: usize = n;
    while (k > 0) {
        k -= 1;
        buf[idx] = tmp[k];
        idx += 1;
    }
    buf[idx] = 0;
    return @ptrCast(buf);
}

// ===========================================================================
// C47_WP34S_SinCosTanTaylor_temp75
// ===========================================================================
pub export fn C47_WP34S_SinCosTanTaylor_temp75(a: *align(1) const real_t, swap: bool, sinOut: ?*align(1) real_t, cosOut: ?*align(1) real_t, tanOut: ?*align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    var doEpsilon: bool = false;
    var epsilonDigits: i32 = undefined;
    var angle: real_t = undefined;
    var a2: real_t = undefined;
    var t: real_t = undefined;
    var j: real_t = undefined;
    var z: real_t = undefined;
    var sin: real_t = undefined;
    var cos: real_t = undefined;
    var epsilonOrCompare: real_t = undefined;

    const savedContextDigits = realContext.digits;

    if (realContext.digits > 51) {
        realContext.digits = 75;
        epsilonDigits = 72;
        doEpsilon = true;
    } else {
        realContext.digits = 51;
        epsilonDigits = 39;
        doEpsilon = false;
    }

    doTaylorIterations(a, &angle, &a2, &t, &j, &z, &sin, &cos, sinOut, cosOut, &epsilonOrCompare, doEpsilon, epsilonDigits, realContext);

    realContext.digits = savedContextDigits;

    if (sinOut) |s| {
        realPlus(&sin, s, realContext);
    }

    if (cosOut) |c| {
        realPlus(&cos, c, realContext);
    }

    if (tanOut) |tn| {
        if (sinOut == null or cosOut == null) {
            realSetNaN(tn);
        } else {
            if (swap) {
                realDivide(&cos, &sin, tn, realContext);
            } else {
                realDivide(&sin, &cos, tn, realContext);
            }
        }
    }
}

// ===========================================================================
// C47_WP34S_Cvt2RadSinCosTan_1071temp (static)
// ===========================================================================
fn C47_WP34S_Cvt2RadSinCosTan_1071temp(an: *align(1) const real_t, angularMode: angularMode_t, sinOut: ?*align(1) real_t, cosOut: ?*align(1) real_t, tanOut: ?*align(1) real_t, realContext: *realContext_t) void {
    var sinNeg: bool = false;
    var cosNeg: bool = false;
    var swap: bool = false;
    var angle_buf: BigReal(1071) = .{};
    const angle = angle_buf.ptr();

    if (realIsNaN(an)) {
        if (sinOut) |s| realSetNaN(s);
        if (cosOut) |c| realSetNaN(c);
        if (tanOut) |t| realSetNaN(t);
        return;
    }

    realCopy(an, angle);

    const savedContextDigits = realContext.digits;

    doWP34S_SinCosTanTaylor(angle, &sinNeg, &cosNeg, &swap, sinOut, cosOut, tanOut, angularMode, savedContextDigits, realContext);
}

// ===========================================================================
// C47_WP34S_Cvt2RadSinCosTan
// ===========================================================================
pub export fn C47_WP34S_Cvt2RadSinCosTan(an: *align(1) const real_t, angularMode: angularMode_t, sinOut: ?*align(1) real_t, cosOut: ?*align(1) real_t, tanOut: ?*align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    if (realContext.digits >= 1071) {
        C47_WP34S_Cvt2RadSinCosTan_1071temp(an, angularMode, sinOut, cosOut, tanOut, realContext);
    } else {
        C47_WP34S_Cvt2RadSinCosTan_75temp(an, angularMode, sinOut, cosOut, tanOut, realContext);
    }
}

// ===========================================================================
// C47_WP34S_SinCosTanTaylor_temp1071
// ===========================================================================
pub export fn C47_WP34S_SinCosTanTaylor_temp1071(a: *align(1) const real_t, swap: bool, sinOut: ?*align(1) real_t, cosOut: ?*align(1) real_t, tanOut: ?*align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    var angle_buf: BigReal(1071) = .{};
    var a2_buf: BigReal(1071) = .{};
    var t_buf: BigReal(1071) = .{};
    var j_buf: BigReal(1071) = .{};
    var z_buf: BigReal(1071) = .{};
    var sin_buf: BigReal(1071) = .{};
    var cos_buf: BigReal(1071) = .{};
    var epsilon_buf: BigReal(1071) = .{};

    const angle = angle_buf.ptr();
    const a2 = a2_buf.ptr();
    const t = t_buf.ptr();
    const j = j_buf.ptr();
    const z = z_buf.ptr();
    const sin = sin_buf.ptr();
    const cos = cos_buf.ptr();
    const epsilonOrCompare = epsilon_buf.ptr();

    doTaylorIterations(a, angle, a2, t, j, z, sin, cos, sinOut, cosOut, epsilonOrCompare, true, 1040, realContext);

    if (sinOut) |s| {
        realPlus(sin, s, realContext);
    }
    if (cosOut) |c| {
        realPlus(cos, c, realContext);
    }
    if (tanOut) |tn| {
        if (sinOut == null or cosOut == null) {
            realSetNaN(tn);
        } else {
            if (swap) {
                realDivide(cos, sin, tn, realContext);
            } else {
                realDivide(sin, cos, tn, realContext);
            }
        }
    }
}

// ===========================================================================
// C47_WP34S_SinCosTanTaylor (dispatcher) - not in wp34s.h but defined in C
// ===========================================================================
pub export fn C47_WP34S_SinCosTanTaylor(a: *align(1) const real_t, swap: bool, sinOut: ?*align(1) real_t, cosOut: ?*align(1) real_t, tanOut: ?*align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    if (realContext.digits >= 1071) {
        C47_WP34S_SinCosTanTaylor_temp1071(a, swap, sinOut, cosOut, tanOut, realContext);
    } else {
        C47_WP34S_SinCosTanTaylor_temp75(a, swap, sinOut, cosOut, tanOut, realContext);
    }
}

// ===========================================================================
// doAtan (static)
// ===========================================================================
fn doAtan(
    a: *align(1) real_t,
    angle: *align(1) real_t,
    a2: *align(1) real_t,
    t: *align(1) real_t,
    j: *align(1) real_t,
    z: *align(1) real_t,
    x: *align(1) const real_t,
    b: *align(1) real_t,
    epsilon: *align(1) real_t,
    last: *align(1) real_t,
    doEpsilon: bool,
    epsilonDigits: i32,
    doubles: *i32,
    invert: *c_int,
    neg: *c_int,
    realContext: *realContext_t,
) bool {
    var conditionToKeepIterating: bool = false;
    var tmpEpsilon: [16]u8 = undefined;
    if (doEpsilon) {
        stringToReal(formatEminusD(&tmpEpsilon, epsilonDigits), epsilon, realContext);
    }

    neg.* = @intFromBool(realIsNegative(x));

    if (realIsNaN(x)) {
        realSetNaN(angle);
        return false;
    }

    realCopy(x, a);

    // arrange for a >= 0
    if (neg.* != 0) {
        realChangeSign(a);
    }

    // reduce range to 0 <= a < 1, using atan(x) = pi/2 - atan(1/x)
    invert.* = @intFromBool(realCompareGreaterThan(a, const_1()));
    if (invert.* != 0) {
        realDivide(const_1(), a, a, realContext);
    }

    // Range reduce using tan(x/2) = tan(x)/(1+sqrt(1+tan(x)^2))
    {
        var n: i32 = 0;
        while (n < TaylorIterationMax) : (n += 1) {
            if (!doEpsilon and realCompareLessEqual(a, const_1on10())) {
                break;
            } else if (doEpsilon and realCompareLessEqual(a, const_1on10())) {
                break;
            }

            doubles.* += 1;
            // a = a/(1+sqrt(1+a^2)) -- at most 3 iterations.
            realMultiply(a, a, b, realContext);
            realAdd(b, const_1(), b, realContext);
            realSquareRoot(b, b, realContext);
            realAdd(b, const_1(), b, realContext);
            realDivide(a, b, a, realContext);
        }
    }

    // Now Taylor series: atan(x) = x(1-x^2/3+x^4/5-...)
    uInt32ToReal(3, angle);
    uInt32ToReal(5, j);
    realMultiply(a, a, a2, realContext); // a^2
    realCopy(a2, t);
    realDivide(t, angle, angle, realContext); // s = 1-t/3
    realSubtract(const_1(), angle, angle, realContext);

    var i: i32 = 0;
    while (true) {
        realCopy(angle, last);

        realMultiply(t, a2, t, realContext);
        realDivide(t, j, z, realContext);
        realAdd(angle, z, angle, realContext);

        realAdd(j, const_2(), j, realContext);

        realMultiply(t, a2, t, realContext);
        realDivide(t, j, z, realContext);
        realSubtract(angle, z, angle, realContext);

        realAdd(j, const_2(), j, realContext);

        if (doEpsilon) {
            realSubtract(angle, last, b, realContext);
            realCopyAbs(b, b);
            realSubtract(b, epsilon, b, realContext);
            conditionToKeepIterating = realIsPositive(b);
        } else {
            realSubtract(angle, last, b, realContext);
            realPlus(b, b, realContext);
            conditionToKeepIterating = !realIsZero(b);
        }

        if (explicitTaylorIterVisibilitySelection and checkHalfSec()) {
            _ = progressHalfSecUpdate_Integer(halfSec_timed, "Taylor Iter", epsilonDigits, halfSec_clearZ, halfSec_clearT, halfSec_disp);
        }
        if (exitKeyWaiting()) {
            _ = progressHalfSecUpdate_Integer(halfSec_force + 1, "Interrupted Iter:", i, halfSec_clearZ, halfSec_clearT, halfSec_disp);
            displayCalcErrorMessage(ERROR_SOLVER_ABORT, REGISTER_T, NIM_REGISTER_LINE);
            break;
        }

        i += 1;

        if (!(conditionToKeepIterating and i < TaylorIterationMax)) {
            break;
        }
    }

    realMultiply(angle, a, angle, realContext);

    while (doubles.* != 0) {
        realAdd(angle, angle, angle, realContext);
        doubles.* -= 1;
    }
    if (invert.* != 0) {
        realSubtract(if (realContext.digits > 51) const1071_piOn2() else const39_piOn2(), angle, angle, realContext);
    }
    if (neg.* != 0) {
        realChangeSign(angle);
    }
    return true;
}

// ===========================================================================
// WP34S_Atan_75temp (static)
// ===========================================================================
fn WP34S_Atan_75temp(x: *align(1) const real_t, angle: *align(1) real_t, realContext: *realContext_t) void {
    var doEpsilon: bool = false;
    var a: real_t = undefined;
    var b: real_t = undefined;
    var a2: real_t = undefined;
    var t: real_t = undefined;
    var j: real_t = undefined;
    var z: real_t = undefined;
    var last: real_t = undefined;
    var epsilon: real_t = undefined;
    var doubles: i32 = 0;
    var invert: c_int = undefined;
    var neg: c_int = undefined;
    const savedContextDigits = realContext.digits;
    var epsilonDigits: i32 = undefined;

    if (realContext.digits > 39) {
        realContext.digits = 75;
        epsilonDigits = 72;
        doEpsilon = true;
    } else {
        realContext.digits = 39;
        epsilonDigits = 39;
        doEpsilon = false;
    }

    if (!doAtan(&a, angle, &a2, &t, &j, &z, x, &b, &epsilon, &last, doEpsilon, epsilonDigits, &doubles, &invert, &neg, realContext)) {
        realContext.digits = savedContextDigits;
        return; // NaN
    }
    realContext.digits = savedContextDigits;
}

// ===========================================================================
// C47do_WP34S_Atan_1071temp (static)
// ===========================================================================
fn C47do_WP34S_Atan_1071temp(x: *align(1) const real_t, angle: *align(1) real_t, realContext: *realContext_t) void {
    var a_buf: BigReal(1071) = .{};
    var b_buf: BigReal(1071) = .{};
    var a2_buf: BigReal(1071) = .{};
    var t_buf: BigReal(1071) = .{};
    var j_buf: BigReal(1071) = .{};
    var z_buf: BigReal(1071) = .{};
    var last_buf: BigReal(1071) = .{};
    var epsilon_buf: BigReal(1071) = .{};
    var doubles: i32 = 0;
    var invert: c_int = undefined;
    var neg: c_int = undefined;
    if (!doAtan(a_buf.ptr(), angle, a2_buf.ptr(), t_buf.ptr(), j_buf.ptr(), z_buf.ptr(), x, b_buf.ptr(), epsilon_buf.ptr(), last_buf.ptr(), true, 1040, &doubles, &invert, &neg, realContext)) {
        return; // NaN
    }
}

// ===========================================================================
// C47_WP34S_Atan
// ===========================================================================
pub export fn C47_WP34S_Atan(x: *align(1) const real_t, angle: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    if (realContext.digits >= 1071) {
        C47do_WP34S_Atan_1071temp(x, angle, realContext);
    } else {
        WP34S_Atan_75temp(x, angle, realContext);
    }
}

// pi-family selectors used by doAtan2 (the _pi/_piOn2/... macros).
inline fn pi_d(d: i32) *align(1) const real_t {
    return if (d > 51) (if (d > 75) const1071_pi() else const75_pi()) else const39_pi();
}
inline fn piOn2_d(d: i32) *align(1) const real_t {
    return if (d > 51) (if (d > 75) const1071_piOn2() else const75_piOn2()) else const39_piOn2();
}
inline fn piOn4_d(d: i32) *align(1) const real_t {
    return if (d > 51) (if (d > 75) const1071_piOn4() else const75_piOn4()) else const39_piOn4();
}
inline fn threePiOn4_d(d: i32) *align(1) const real_t {
    return if (d > 51) (if (d > 75) const1071_3piOn4() else const75_3piOn4()) else const39_3piOn4();
}

// ===========================================================================
// doAtan2 (static)
// ===========================================================================
fn doAtan2(y: *align(1) const real_t, x: *align(1) const real_t, atan: *align(1) real_t, r: *align(1) real_t, t: *align(1) real_t, realContext: *realContext_t) bool {
    const xNeg = realIsNegative(x);
    const yNeg = realIsNegative(y);

    if (realIsNaN(x) or realIsNaN(y)) {
        realSetNaN(atan);
        return false;
    }

    if (realCompareEqual(y, const_0())) {
        if (yNeg) {
            if (realCompareEqual(x, const_0())) {
                if (xNeg) {
                    realMinus(pi_d(realContext.digits), atan, realContext);
                } else {
                    realCopy(y, atan);
                }
            } else if (xNeg) {
                realMinus(pi_d(realContext.digits), atan, realContext);
            } else {
                realCopy(y, atan);
            }
        } else {
            if (realCompareEqual(x, const_0())) {
                if (xNeg) {
                    realCopy(pi_d(realContext.digits), atan);
                } else {
                    realSetZero(atan);
                }
            } else if (xNeg) {
                realCopy(pi_d(realContext.digits), atan);
            } else {
                realSetZero(atan);
            }
        }
        return true;
    }

    if (realCompareEqual(x, const_0())) {
        realCopy(piOn2_d(realContext.digits), atan);
        if (yNeg) {
            realSetNegativeSign(atan);
        }
        return true;
    }

    if (realIsInfinite(x)) {
        if (xNeg) {
            if (realIsInfinite(y)) {
                realCopy(threePiOn4_d(realContext.digits), atan);
                if (yNeg) {
                    realSetNegativeSign(atan);
                }
            } else {
                realCopy(pi_d(realContext.digits), atan);
                if (yNeg) {
                    realSetNegativeSign(atan);
                }
            }
        } else {
            if (realIsInfinite(y)) {
                realCopy(piOn4_d(realContext.digits), atan);
                if (yNeg) {
                    realSetNegativeSign(atan);
                }
            } else {
                realSetZero(atan);
                if (yNeg) {
                    realSetNegativeSign(atan);
                }
            }
        }
        return true;
    }

    if (realIsInfinite(y)) {
        realCopy(piOn2_d(realContext.digits), atan);
        if (yNeg) {
            realSetNegativeSign(atan);
        }
        return true;
    }

    realDivide(y, x, t, realContext);
    C47_WP34S_Atan(@ptrCast(t), @ptrCast(r), realContext);
    if (xNeg) {
        realCopy(pi_d(realContext.digits), t);
        if (yNeg) {
            realSetNegativeSign(t);
        }
    } else {
        realSetZero(t);
    }

    realAdd(r, t, atan, realContext);
    if (realCompareEqual(atan, const_0()) and yNeg) {
        realSetNegativeSign(atan);
    }
    return true;
}

// ===========================================================================
// WP34S_Atan2_75temp / 1071temp (static) + dispatcher
// ===========================================================================
fn WP34S_Atan2_75temp(y: *align(1) const real_t, x: *align(1) const real_t, atan: *align(1) real_t, realContext: *realContext_t) void {
    var r: real_t = undefined;
    var t: real_t = undefined;
    if (!doAtan2(y, x, atan, &r, &t, realContext)) {
        return; // NaN
    }
}

fn C47do_WP34S_Atan2_1071temp(y: *align(1) const real_t, x: *align(1) const real_t, atan: *align(1) real_t, realContext: *realContext_t) void {
    var r_buf: BigReal(1071) = .{};
    var t_buf: BigReal(1071) = .{};
    if (!doAtan2(y, x, atan, r_buf.ptr(), t_buf.ptr(), realContext)) {
        return; // NaN
    }
}

pub export fn C47_WP34S_Atan2(y: *align(1) const real_t, x: *align(1) const real_t, atan: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    if (realContext.digits >= 1071) {
        C47do_WP34S_Atan2_1071temp(y, x, atan, realContext);
    } else {
        WP34S_Atan2_75temp(y, x, atan, realContext);
    }
}

// ===========================================================================
// doAsin (static) + dispatchers
// ===========================================================================
fn doAsin(x: *align(1) const real_t, angle: *align(1) real_t, abx: *align(1) real_t, z: *align(1) real_t, realContext: *realContext_t) bool {
    if (realIsNaN(x)) {
        realSetNaN(angle);
        return false;
    }
    realCopyAbs(x, abx);
    if (realCompareGreaterThan(abx, const_1())) {
        realSetNaN(angle);
        return false;
    }
    // angle = 2*atan(x/(1+sqrt(1-x*x)))
    realMultiply(x, x, z, realContext);
    realSubtract(const_1(), z, z, realContext);
    realSquareRoot(z, z, realContext);
    realAdd(z, const_1(), z, realContext);
    realDivide(x, z, z, realContext);
    C47_WP34S_Atan(@ptrCast(z), @ptrCast(abx), realContext);
    realAdd(abx, abx, angle, realContext);
    return true;
}

fn WP34S_Asin_75temp(x: *align(1) const real_t, angle: *align(1) real_t, realContext: *realContext_t) void {
    var abx: real_t = undefined;
    var z: real_t = undefined;
    if (!doAsin(x, angle, &abx, &z, realContext)) {
        return; // NaN
    }
}

fn C47do_WP34S_Asin_1071temp(x: *align(1) const real_t, angle: *align(1) real_t, realContext: *realContext_t) void {
    var abx_buf: BigReal(1071) = .{};
    var z_buf: BigReal(1071) = .{};
    if (!doAsin(x, angle, abx_buf.ptr(), z_buf.ptr(), realContext)) {
        return; // NaN
    }
}

pub export fn C47_WP34S_Asin(x: *align(1) const real_t, angle: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    if (realContext.digits >= 1071) {
        C47do_WP34S_Asin_1071temp(x, angle, realContext);
    } else {
        WP34S_Asin_75temp(x, angle, realContext);
    }
}

// ===========================================================================
// doAcos (static) + dispatchers
// ===========================================================================
fn doAcos(x: *align(1) const real_t, angle: *align(1) real_t, abx: *align(1) real_t, z: *align(1) real_t, realContext: *realContext_t) bool {
    if (realIsNaN(x)) {
        realSetNaN(angle);
        return false;
    }
    realCopyAbs(x, abx);
    if (realCompareGreaterThan(abx, const_1())) {
        realSetNaN(angle);
        return false;
    }
    // angle = 2*atan((1-x)/sqrt(1-x*x))
    if (realCompareEqual(x, const_1())) {
        realSetZero(angle);
    } else {
        realMultiply(x, x, z, realContext);
        realSubtract(const_1(), z, z, realContext);
        realSquareRoot(z, z, realContext);
        realSubtract(const_1(), x, abx, realContext);
        realDivide(abx, z, z, realContext);
        C47_WP34S_Atan(@ptrCast(z), @ptrCast(abx), realContext);
        realAdd(abx, abx, angle, realContext);
    }
    return true;
}

fn WP34S_Acos_75temp(x: *align(1) const real_t, angle: *align(1) real_t, realContext: *realContext_t) void {
    var abx: real_t = undefined;
    var z: real_t = undefined;
    if (!doAcos(x, angle, &abx, &z, realContext)) {
        return; // NaN
    }
}

fn C47do_WP34S_Acos_1071temp(x: *align(1) const real_t, angle: *align(1) real_t, realContext: *realContext_t) void {
    var abx_buf: BigReal(1071) = .{};
    var z_buf: BigReal(1071) = .{};
    if (!doAcos(x, angle, abx_buf.ptr(), z_buf.ptr(), realContext)) {
        return; // NaN
    }
}

pub export fn C47_WP34S_Acos(x: *align(1) const real_t, angle: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    if (realContext.digits >= 1071) {
        C47do_WP34S_Acos_1071temp(x, angle, realContext);
    } else {
        WP34S_Acos_75temp(x, angle, realContext);
    }
}

// ===========================================================================
// WP34S_Calc_Gamma_LnGamma_Lanczos (static)
// ===========================================================================
fn WP34S_Calc_Gamma_LnGamma_Lanczos(xin: *align(1) const real_t, res: *align(1) real_t, calculateLnGamma: bool, realContext: *realContext_t) void {
    var r: real_t = undefined;
    var s: real_t = undefined;
    var t: real_t = undefined;
    var u: real_t = undefined;
    var v: real_t = undefined;
    var x: real_t = undefined;

    const savedContextDigits = realContext.digits;
    if (realContext.digits < 51) {
        realContext.digits = 51;
    }

    realSubtract(xin, const_1(), &x, realContext);
    realSetZero(&s);
    realAdd(&x, const_29(), &t, realContext);
    var k: i32 = 28;
    while (k >= 0) : (k -= 1) {
        realDivide(const51_gammaC01(@intCast(k)), &t, &u, realContext);
        realSubtract(&t, const_1(), &t, realContext);
        realAdd(&s, &u, &s, realContext);
    }

    realAdd(&s, const51_gammaC00(), &t, realContext);
    WP34S_Ln(&t, &s, realContext);

    //  r = z + g + 0.5;
    realAdd(&x, const_gammaR(), &r, realContext); // const_gammaR is g + 0.5

    //  r = log(R[0][0]) + (z+0.5) * log(r) - r;
    WP34S_Ln(&r, &u, realContext);
    realAdd(&x, const_1on2(), &t, realContext);
    realMultiply(&u, &t, &v, realContext);

    realSubtract(&v, &r, &u, realContext);

    if (calculateLnGamma) {
        realAdd(&u, &s, &x, realContext);
    } else {
        realAdd(&u, &s, &x, realContext);
        realExp(&x, &x, realContext);
    }

    realContext.digits = savedContextDigits;

    realPlus(&x, res, realContext);
}

// ===========================================================================
// WP34S_Gamma_LnGamma (static)
// ===========================================================================
fn WP34S_Gamma_LnGamma(xin: *align(1) const real_t, calculateLnGamma: bool, res: *align(1) real_t, realContext: *realContext_t) void {
    var x: real_t = undefined;
    var t: real_t = undefined;
    var reflect: bool = false;

    // Check for special cases
    if (realIsSpecial(xin)) {
        if (realIsInfinite(xin) and realIsPositive(xin)) {
            realSetPlusInfinity(res);
            return;
        }

        realSetNaN(res);
        return;
    }

    // Handle x approximately zero case
    if (realCompareAbsLessThan(xin, const_1e_24())) {
        if (realIsZero(xin)) {
            realSetNaN(res);
            return;
        }
        realDivide(const_1(), xin, &x, realContext);
        realSubtract(&x, const39_egamma(), res, realContext);
        if (calculateLnGamma) {
            WP34S_Ln(res, res, realContext);
        }
        return;
    }

    // Correct our argument and begin the inversion if it is negative
    if (realCompareLessEqual(xin, const_0())) {
        reflect = true;
        realSubtract(const_1(), xin, &t, realContext); // t = 1 - xin
        if (realIsAnInteger(&t)) {
            realSetNaN(res);
            return;
        }
    } else {
        // Fast path for positive integer args that aren't too large (<= 205).
        if (realIsAnInteger(xin) and realCompareLessEqual(xin, const_205())) {
            realSubtract(xin, const_1(), &x, realContext); // x = xin - 1
            realSetOne(res);
            while (realCompareGreaterEqual(&x, const_2())) {
                realMultiply(res, &x, res, realContext);
                realSubtract(&x, const_1(), &x, realContext);
            }
            if (calculateLnGamma) {
                WP34S_Ln(res, res, realContext);
            }
            return;
        }
        realCopy(xin, &t); // t = xin
    }

    WP34S_Calc_Gamma_LnGamma_Lanczos(&t, res, calculateLnGamma, realContext);

    if (reflect) {
        // figure out xin * PI mod 2PI
        WP34S_Mod(xin, const_2(), &t, realContext);
        realMultiply(&t, const39_pi(), &t, realContext); // t = xin*pi
        C47_WP34S_SinCosTanTaylor_temp75(@ptrCast(&t), false, &x, null, null, realContext); // x = sin(xin*pi)

        if (calculateLnGamma) {
            realDivide(const39_pi(), &x, &t, realContext); // t = pi / sin(pi*xin)
            WP34S_Ln(&t, &t, realContext); // t = ln(pi / sin(pi*xin))
            realSubtract(&t, res, res, realContext); // res = ln(pi / sin(pi*xin)) - lngamma(1-xin)
        } else {
            realMultiply(&x, res, &t, realContext); // t = sin(pi*xin) * gamma(1-xin)
            realDivide(const39_pi(), &t, res, realContext); // res = pi / (sin(pi*xin)*gamma(1-xin))
        }
    }
}

// ===========================================================================
// WP34S_Factorial / WP34S_Gamma / WP34S_LnGamma
// ===========================================================================
pub export fn WP34S_Factorial(xin: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    var x: real_t = undefined;
    realAdd(xin, const_1(), &x, realContext);
    WP34S_Gamma_LnGamma(&x, false, res, realContext);
}

pub export fn WP34S_Gamma(xin: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    var x: real_t = undefined;
    realCopy(xin, &x);
    WP34S_Gamma_LnGamma(&x, false, res, realContext);
}

pub export fn WP34S_LnGamma(xin: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    var x: real_t = undefined;
    realCopy(xin, &x);
    WP34S_Gamma_LnGamma(&x, true, res, realContext);
}

// ===========================================================================
// WP34S_Ln
// ===========================================================================
pub export fn WP34S_Ln(xin: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    var z: real_t = undefined;
    var t: real_t = undefined;
    var f: real_t = undefined;
    var n: real_t = undefined;
    var m: real_t = undefined;
    var i: real_t = undefined;
    var v: real_t = undefined;
    var w: real_t = undefined;
    var e: real_t = undefined;
    var expon: i32 = undefined;

    if (realIsSpecial(xin)) {
        if (realIsNaN(xin) or realIsNegative(xin)) {
            realSetNaN(res);
            return;
        }

        realSetPlusInfinity(res);
        return;
    }

    if (realCompareLessEqual(xin, const_0())) {
        if (realIsNegative(xin)) {
            realSetNaN(res);
            return;
        }

        realSetMinusInfinity(res);
        return;
    }

    realCopy(xin, &z);
    realCopy(const_2(), &f);
    realSubtract(xin, const_1(), &t, realContext);
    realCopy(&t, &v);
    realSetPositiveSign(&v);
    if (realCompareGreaterThan(&v, const_1on2())) {
        expon = z.exponent + z.digits;
        z.exponent = -z.digits;
    } else {
        expon = 0;
    }

    // Range reduce the value by repeated square roots.
    while (realCompareLessEqual(&z, const39_root2on2())) {
        realMultiply(&f, const_2(), &f, realContext);
        realSquareRoot(&z, &z, realContext);
    }

    realAdd(&z, const_1(), &t, realContext);
    realSubtract(&z, const_1(), &v, realContext);
    realDivide(&v, &t, &n, realContext);
    realCopy(&n, &v);
    realMultiply(&v, &v, &m, realContext);
    realCopy(const_3(), &i);

    int32ToReal(1 - realContext.digits, &t); // t is the exponent
    realPower10(&t, &z, realContext); // z is the max error

    while (true) {
        realMultiply(&m, &n, &n, realContext);
        realDivide(&n, &i, &e, realContext);
        realAdd(&v, &e, &w, realContext);
        if (WP34S_RelativeError(&w, &v, &z, realContext)) {
            break;
        }
        realCopy(&w, &v);
        realAdd(&i, const_2(), &i, realContext);
    }

    realMultiply(&f, &w, res, realContext);
    if (expon == 0) {
        return;
    }

    int32ToReal(expon, &e);
    realMultiply(&e, const39_ln10(), &w, realContext);
    realAdd(res, &w, res, realContext);
}

// ===========================================================================
// WP34S_Log / WP34S_Log10 / WP34S_Logxy
// ===========================================================================
pub export fn WP34S_Log(xin: *align(1) const real_t, base: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    var y: real_t = undefined;

    if (realIsSpecial(xin)) {
        if (realIsNaN(xin) or realIsNegative(xin)) {
            realSetNaN(res);
            return;
        }

        realSetPlusInfinity(res);
        return;
    }

    WP34S_Ln(xin, &y, realContext);

    realDivide(&y, base, res, realContext);
}

pub export fn WP34S_Log10(xin: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    WP34S_Log(xin, const39_ln10(), res, realContext);
}

pub export fn WP34S_Logxy(yin: *align(1) const real_t, xin: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    var lx: real_t = undefined;

    WP34S_Ln(xin, &lx, realContext);
    WP34S_Log(yin, &lx, res, realContext);
}

// ===========================================================================
// WP34S_RelativeError / WP34S_AbsoluteError
// ===========================================================================
pub export fn WP34S_RelativeError(x: *align(1) const real_t, y: *align(1) const real_t, tol: *align(1) const real_t, realContext: *realContext_t) callconv(.c) bool {
    var a: real_t = undefined;

    if (realIsZero(x)) {
        realCopyAbs(y, &a);
        return realCompareLessThan(&a, tol);
    }

    realSubtract(x, y, &a, realContext);
    realDivide(&a, x, &a, realContext);
    realSetPositiveSign(&a);
    return realCompareLessThan(&a, tol);
}

pub export fn WP34S_AbsoluteError(x: *align(1) const real_t, y: *align(1) const real_t, tol: *align(1) const real_t, realContext: *realContext_t) callconv(.c) bool {
    var a: real_t = undefined;
    realSubtract(x, y, &a, realContext);
    return realCompareAbsLessThan(&a, tol);
}

pub export fn WP34S_ComplexRelativeError(xReal: *align(1) const real_t, xImag: *align(1) const real_t, yReal: *align(1) const real_t, yImag: *align(1) const real_t, tol: *align(1) const real_t, realContext: *realContext_t) callconv(.c) bool {
    var a: real_t = undefined;
    var b: real_t = undefined;

    if (realIsZero(xReal) and realIsZero(xImag)) {
        complexMagnitude(yReal, yImag, &a, realContext);
    } else {
        realSubtract(xReal, yReal, &a, realContext);
        realSubtract(xImag, yImag, &b, realContext);
        divComplexComplex(&a, &b, xReal, xImag, &a, &b, realContext);
        complexMagnitude(&a, &b, &a, realContext);
    }
    return realCompareLessThan(&a, tol);
}

pub export fn WP34S_ComplexAbsError(xReal: *align(1) const real_t, xImag: *align(1) const real_t, yReal: *align(1) const real_t, yImag: *align(1) const real_t, tol: *align(1) const real_t, realContext: *realContext_t) callconv(.c) bool {
    var a: real_t = undefined;
    var b: real_t = undefined;
    var r: real_t = undefined;

    realSubtract(xReal, yReal, &a, realContext);
    realSubtract(xImag, yImag, &b, realContext);
    complexMagnitude(&a, &b, &r, realContext);
    return realCompareLessThan(&r, tol);
}

// ===========================================================================
// WP34S_SinhCosh / WP34S_Tanh
// ===========================================================================
pub export fn WP34S_SinhCosh(x: *align(1) const real_t, sinhOut: ?*align(1) real_t, coshOut: ?*align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    var t: real_t = undefined;
    var u: real_t = undefined;
    var v: real_t = undefined;

    if (realIsNaN(x)) {
        if (sinhOut) |s| realSetNaN(s);
        if (coshOut) |c| realSetNaN(c);
        return;
    }

    if (sinhOut) |sinh| {
        if (realCompareAbsLessThan(x, const_1on2())) {
            WP34S_ExpM1(x, &u, realContext); // u = e^x - 1
            realMultiply(&u, const_1on2(), &t, realContext); // t = (e^x - 1) / 2

            realAdd(&u, const_1(), &u, realContext); // u = e^x
            realDivide(&t, &u, &v, realContext); // v = (e^x - 1) / 2e^x

            realAdd(&u, const_1(), &u, realContext); // u = e^x + 1
            realMultiply(&u, &v, sinh, realContext); // sinhOut = (e^x - 1)(e^x + 1) / 2e^x
        } else {
            realExp(x, &u, realContext); // u = e^x
            realDivide(const_1(), &u, &v, realContext); // v = e^-x
            realSubtract(&u, &v, sinh, realContext); // sinhOut = (e^x - e^-x)
            realMultiply(sinh, const_1on2(), sinh, realContext); // sinhOut = (e^x - e^-x)/2
        }
    }
    if (coshOut) |cosh| {
        realExp(x, &u, realContext); // u = e^x
        realDivide(const_1(), &u, &v, realContext); // v = e^-x
        realAdd(&u, &v, cosh, realContext); // coshOut = (e^x + e^-x)
        realMultiply(cosh, const_1on2(), cosh, realContext); // coshOut = (e^x + e^-x)/2
    }
}

pub export fn WP34S_Tanh(x: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    if (realIsNaN(x)) {
        realSetNaN(res);
    } else if (realCompareAbsGreaterThan(x, const_47())) { // equals 1 to 39 digits
        realCopy(if (realIsPositive(x)) const_1() else const__1(), res);
    } else {
        var a: real_t = undefined;
        var b: real_t = undefined;

        realAdd(x, x, &a, realContext); // a = 2x
        WP34S_ExpM1(&a, &b, realContext); // b = exp(2x) - 1
        realAdd(&b, const_2(), &a, realContext); // a = exp(2x) + 1
        realDivide(&b, &a, res, realContext); // res = (exp(2x) - 1) / (exp(2x) + 1)
    }
}

// ===========================================================================
// WP34S_ArcSinh / WP34S_ArcTanh
// ===========================================================================
pub export fn WP34S_ArcSinh(x: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    var a: real_t = undefined;

    realMultiply(x, x, &a, realContext); // a = x^2
    realAdd(&a, const_1(), &a, realContext); // a = x^2 + 1
    realSquareRoot(&a, &a, realContext); // a = sqrt(x^2+1)
    realAdd(&a, const_1(), &a, realContext); // a = sqrt(x^2+1)+1
    realDivide(x, &a, &a, realContext); // a = x / (sqrt(x^2+1)+1)
    realAdd(&a, const_1(), &a, realContext); // a = x / (sqrt(x^2+1)+1) + 1
    realMultiply(x, &a, &a, realContext); // y = x * (...)
    WP34S_Ln1P(&a, res, realContext);
}

pub export fn WP34S_ArcTanh(x: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    var y: real_t = undefined;
    var z: real_t = undefined;

    if (realIsNaN(x)) {
        realSetNaN(res);
    }

    // Not the obvious formula but more stable...
    realSubtract(const_1(), x, &z, realContext); // z = 1-x
    realDivide(x, &z, &y, realContext); // y = x / (1-x)
    realMultiply(&y, const_2(), &z, realContext); // z = 2x / (1-x)
    WP34S_Ln1P(&z, &y, realContext); // y = ln(1 + 2x / (1-x))
    realMultiply(&y, const_1on2(), res, realContext); // res = ln(...) / 2
}

// ===========================================================================
// WP34S_Ln1P / WP34S_ExpM1
// ===========================================================================
pub export fn WP34S_Ln1P(x: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    var u: real_t = undefined;
    var v: real_t = undefined;
    var w: real_t = undefined;

    if (realIsSpecial(x) or realIsZero(x)) {
        realCopy(x, res);
    } else {
        realAdd(x, const_1(), &u, realContext); // u = x+1
        realSubtract(&u, const_1(), &v, realContext); // v = x
        if (realIsZero(&v)) {
            realCopy(x, res);
        } else {
            realDivide(x, &v, &w, realContext);
            WP34S_Ln(&u, &v, realContext);
            realMultiply(&v, &w, res, realContext);
        }
    }
}

pub export fn WP34S_ExpM1(x: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    var u: real_t = undefined;
    var v: real_t = undefined;
    var w: real_t = undefined;

    if (!realExpLimitCheck(x, res, const__1())) {
        return;
    }

    realExp(x, &u, realContext);
    realSubtract(&u, const_1(), &v, realContext);
    if (realIsZero(&v)) { // |x| is very little
        realCopy(x, res);
    } else if (realCompareEqual(&v, const__1())) {
        realCopy(const__1(), res);
    } else if (realCompareAbsLessThan(x, const_1on10())) {
        realMultiply(&v, x, &w, realContext);
        WP34S_Ln(&u, &v, realContext);
        realDivide(&w, &v, res, realContext);
    } else {
        realCopy(&v, res);
    }
}

// ===========================================================================
// WP34S_CalcComplexLnGamma_Lanczos (static)
// ===========================================================================
fn WP34S_CalcComplexLnGamma_Lanczos(zReal: *align(1) const real_t, zImag: *align(1) const real_t, resReal: *align(1) real_t, resImag: *align(1) real_t, realContext: *realContext_t) void {
    var rReal: real_t = undefined;
    var sReal: real_t = undefined;
    var tReal: real_t = undefined;
    var uReal: real_t = undefined;
    var vReal: real_t = undefined;
    var rImag: real_t = undefined;
    var sImag: real_t = undefined;
    var tImag: real_t = undefined;
    var uImag: real_t = undefined;
    var vImag: real_t = undefined;

    const savedContextDigits = realContext.digits;
    if (realContext.digits < 51) {
        realContext.digits = 51;
    }

    realSetZero(&uReal);
    realSetZero(&uImag);
    realAdd(zReal, const_29(), &tReal, realContext);
    realCopy(zImag, &tImag);
    var k: i32 = 28;
    while (k >= 0) : (k -= 1) {
        divRealComplex(const51_gammaC01(@intCast(k)), &tReal, &tImag, &sReal, &sImag, realContext);
        realSubtract(&tReal, const_1(), &tReal, realContext);
        realAdd(&uReal, &sReal, &uReal, realContext);
        realAdd(&uImag, &sImag, &uImag, realContext);
    }
    realAdd(&uReal, const51_gammaC00(), &tReal, realContext);
    realCopy(&uImag, &tImag);
    lnComplex(&tReal, &tImag, &sReal, &sImag, realContext); // (s1, s2)

    realAdd(zReal, const_gammaR(), &rReal, realContext);
    realCopy(zImag, &rImag);
    lnComplex(&rReal, &rImag, &uReal, &uImag, realContext);

    realAdd(zReal, const_1on2(), &tReal, realContext);
    realCopy(zImag, &tImag);
    mulComplexComplex(&tReal, &tImag, &uReal, &uImag, &vReal, &vImag, realContext);

    realSubtract(&vReal, &rReal, &uReal, realContext);
    realSubtract(&vImag, zImag, &uImag, realContext);

    realContext.digits = savedContextDigits;

    realAdd(&uReal, &sReal, resReal, realContext);
    realAdd(&uImag, &sImag, resImag, realContext);
}

// ===========================================================================
// WP34S_ComplexGammaLnGamma (static)
// ===========================================================================
fn WP34S_ComplexGammaLnGamma(zReal: *align(1) const real_t, zImag: *align(1) const real_t, calculateLnGamma: bool, resReal: *align(1) real_t, resImag: *align(1) real_t, realContext: *realContext_t) void {
    var sinPiZReal: real_t = undefined;
    var tReal: real_t = undefined;
    var uReal: real_t = undefined;
    var xReal: real_t = undefined;
    var sinPiZImag: real_t = undefined;
    var tImag: real_t = undefined;
    var uImag: real_t = undefined;
    var xImag: real_t = undefined;
    var reflect: bool = false;

    // Check for special cases
    if (realIsSpecial(zReal) or realIsSpecial(zImag)) {
        if (realIsNaN(zReal) or realIsNaN(zImag)) {
            realSetNaN(resReal);
            realSetNaN(resImag);
        } else {
            if (realIsInfinite(zReal)) {
                if (realIsInfinite(zImag) or realIsNegative(zReal)) {
                    realSetNaN(resReal);
                    realSetNaN(resImag);
                } else {
                    realSetPlusInfinity(resReal);
                    realSetZero(resImag);
                }
            } else {
                realSetZero(resReal);
                realSetZero(resImag);
            }
        }
        return;
    }

    // Correct our argument and begin the inversion if it is negative
    if (realIsNegative(zReal)) {
        reflect = true;
        realSubtract(const_1(), zReal, &tReal, realContext);
        if (realIsZero(zImag) and realIsAnInteger(&tReal)) {
            realSetNaN(resReal);
            realSetNaN(resImag);
            return;
        }
        realSubtract(&tReal, const_1(), &xReal, realContext);
        realMinus(zImag, &xImag, realContext);
    } else {
        realSubtract(zReal, const_1(), &xReal, realContext);
        realCopy(zImag, &xImag);
    }

    // Sum the series
    WP34S_CalcComplexLnGamma_Lanczos(&xReal, &xImag, resReal, resImag, realContext);
    if (!calculateLnGamma) {
        expComplex(resReal, resImag, resReal, resImag, realContext);
    }

    // Finally invert if we started with a negative argument
    if (reflect) {
        realMultiply(zReal, const39_pi(), &tReal, realContext);
        realMultiply(zImag, const39_pi(), &tImag, realContext);
        sinComplex(&tReal, &tImag, &sinPiZReal, &sinPiZImag, realContext);
        if (!calculateLnGamma) {
            mulComplexComplex(&sinPiZReal, &sinPiZImag, resReal, resImag, &uReal, &uImag, realContext);
            divRealComplex(const39_pi(), &uReal, &uImag, resReal, resImag, realContext);
        } else {
            divRealComplex(const39_pi(), &sinPiZReal, &sinPiZImag, &uReal, &uImag, realContext);
            lnComplex(&uReal, &uImag, &tReal, &tImag, realContext);
            realSubtract(&tReal, resReal, resReal, realContext);
            realSubtract(&tImag, resImag, resImag, realContext);
        }
    }
}

pub export fn WP34S_ComplexGamma(zinReal: *align(1) const real_t, zinImag: *align(1) const real_t, resReal: *align(1) real_t, resImag: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    var zReal: real_t = undefined;
    var zImag: real_t = undefined;

    realCopy(zinReal, &zReal);
    realCopy(zinImag, &zImag);
    WP34S_ComplexGammaLnGamma(&zReal, &zImag, false, resReal, resImag, realContext);
}

pub export fn WP34S_ComplexLnGamma(zinReal: *align(1) const real_t, zinImag: *align(1) const real_t, resReal: *align(1) real_t, resImag: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    var zReal: real_t = undefined;
    var zImag: real_t = undefined;

    realCopy(zinReal, &zReal);
    realCopy(zinImag, &zImag);
    WP34S_ComplexGammaLnGamma(&zReal, &zImag, true, resReal, resImag, realContext);
}

// ===========================================================================
// doMod (static) + WP34S_Mod / WP34S_BigMod / mod2Pi
// ===========================================================================
fn doMod(x: *align(1) const real_t, y: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t, digits: u32, out: *align(1) real_t) void {
    var c: realContext_t = realContext.*;

    c.digits = @intCast(digits);
    realDivideRemainder(x, y, out, &c);
    realPlus(out, res, realContext);
}

pub export fn WP34S_Mod(x: *align(1) const real_t, y: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    if (runtime.wp34s_mod_small_buffers) {
        var small_buf: BigReal(2139) = .{};
        doMod(x, y, res, realContext, 2139, small_buf.ptr());
    } else {
        var temp_buf: BigReal(12321) = .{};
        doMod(x, y, res, realContext, 6147, temp_buf.ptr());
    }
}

pub export fn WP34S_BigMod(x: *align(1) const real_t, y: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    if (runtime.wp34s_mod_small_buffers) {
        var small_buf: BigReal(2139) = .{};
        doMod(x, y, res, realContext, 2139, small_buf.ptr());
    } else {
        var temp_buf: BigReal(12321) = .{};
        doMod(x, y, res, realContext, 12321, temp_buf.ptr());
    }
}

pub export fn mod2Pi(x: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    WP34S_BigMod(x, const6147_2pi(), res, realContext);
}

// ===========================================================================
// gser / gcheckSmall / gcf (static) + WP34S_GammaP
// ===========================================================================
fn gser(a: *align(1) const real_t, x: *align(1) const real_t, gln: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) void {
    var ap: real_t = undefined;
    var del: real_t = undefined;
    var sum: real_t = undefined;
    var t: real_t = undefined;
    var u: real_t = undefined;

    if (realCompareLessEqual(x, const_0())) {
        realSetZero(res);
        return;
    }
    realCopy(a, &ap);
    realDivide(const_1(), a, &sum, realContext);
    realCopy(&sum, &del);
    var i: i32 = 0;
    while (i < 1000) : (i += 1) {
        realAdd(&ap, const_1(), &ap, realContext);
        realDivide(x, &ap, &t, realContext);
        realMultiply(&del, &t, &del, realContext);
        realAdd(&sum, &del, &t, realContext);
        if (realCompareEqual(&sum, &t)) {
            break;
        }
        realCopy(&t, &sum);
    }
    WP34S_Ln(x, &t, realContext);
    realMultiply(&t, a, &u, realContext);
    realSubtract(&u, x, &t, realContext);
    realSubtract(&t, gln, &u, realContext);
    realExp(&u, &t, realContext);
    realMultiply(&sum, &t, res, realContext);
    return;
}

fn gcheckSmall(v: *align(1) real_t, realContext: *realContext_t) void {
    _ = realContext;
    if (realCompareAbsLessThan(v, const_1e_10000())) {
        realCopy(const_1e_10000(), v);
    }
}

fn gcf(a: *align(1) const real_t, x: *align(1) const real_t, gln: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) void {
    var an: real_t = undefined;
    var b: real_t = undefined;
    var c: real_t = undefined;
    var d: real_t = undefined;
    var h: real_t = undefined;
    var t: real_t = undefined;
    var u: real_t = undefined;
    var v: real_t = undefined;
    var i: real_t = undefined;

    realAdd(x, const_1(), &t, realContext);
    realSubtract(&t, a, &b, realContext); // b = (x+1) - a
    gcheckSmall(&b, realContext);
    realSetPlusInfinity(&c);
    realDivide(const_1(), &b, &d, realContext);
    realCopy(&d, &h);
    realSetZero(&i);
    var n: i32 = 0;
    while (n < 1000) : (n += 1) {
        realAdd(&i, const_1(), &i, realContext);
        realSubtract(a, &i, &t, realContext); // t = a-i
        realMultiply(&i, &t, &an, realContext); // an = -i (i-a)
        realAdd(&b, const_2(), &b, realContext);
        realMultiply(&an, &d, &t, realContext);
        realAdd(&t, &b, &v, realContext);
        gcheckSmall(&v, realContext);
        realDivide(const_1(), &v, &d, realContext);
        realDivide(&an, &c, &t, realContext);
        realAdd(&b, &t, &c, realContext);
        gcheckSmall(&c, realContext);
        realMultiply(&d, &c, &t, realContext);
        realMultiply(&h, &t, &u, realContext);
        if (realCompareEqual(&u, &h)) {
            break;
        }
        realCopy(&u, &h);
    }
    WP34S_Ln(x, &t, realContext);
    realMultiply(&t, a, &u, realContext);
    realSubtract(&u, x, &t, realContext);
    realSubtract(&t, gln, &u, realContext);
    realExp(&u, &t, realContext);
    realMultiply(&t, &h, res, realContext);
    return;
}

pub export fn WP34S_GammaP(x: *align(1) const real_t, a: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t, upper: bool, regularised: bool) callconv(.c) void {
    var z: real_t = undefined;
    var lga: real_t = undefined;

    if (realIsNegative(x) or realCompareLessEqual(a, const_0()) or realIsNaN(x) or realIsNaN(a) or realIsInfinite(a)) {
        realSetNaN(res);
        return;
    }

    if (realIsInfinite(x)) {
        if (upper) {
            if (regularised) {
                realSetOne(res);
                return;
            }

            WP34S_Gamma(a, res, realContext);
            return;
        }

        realSetZero(res);
        return;
    }

    realAdd(a, const_1(), &lga, realContext);
    realCompare(x, &lga, &z, realContext);
    if (regularised) {
        WP34S_LnGamma(a, &lga, realContext);
    } else {
        realSetZero(&lga);
    }

    var use_cf: bool = false;
    if (realIsNegative(&z)) {
        // Deal with a difficult case by using the other expansion
        if (realCompareGreaterThan(a, const_9000())) {
            realCopy(const_995on1000(), &z);
            realMultiply(a, &z, &z, realContext);
            if (realCompareGreaterThan(x, &z)) {
                use_cf = true;
            }
        }

        if (!use_cf) {
            gser(a, x, &lga, res, realContext);
            if (upper) {
                // goto invert
                doGammaPInvert(a, res, regularised, realContext);
                return;
            }
            return;
        }
    }

    // use_cf:
    gcf(a, x, &lga, res, realContext);
    if (!upper) {
        // goto invert
        doGammaPInvert(a, res, regularised, realContext);
        return;
    }
    return;
}

fn doGammaPInvert(a: *align(1) const real_t, res: *align(1) real_t, regularised: bool, realContext: *realContext_t) void {
    var z: real_t = undefined;
    if (regularised) {
        realSubtract(const_1(), res, res, realContext);
        return;
    }
    WP34S_Gamma(a, &z, realContext);
    realSubtract(&z, res, res, realContext);
    return;
}

// ===========================================================================
// WP34S_Erf / WP34S_Erfc
// ===========================================================================
pub export fn WP34S_Erf(x: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    var p: real_t = undefined;
    var q: real_t = undefined;

    if (realIsInfinite(x)) {
        int32ToReal(if (realIsNegative(x)) -1 else 1, res);
        return;
    }

    realMultiply(x, x, &p, realContext);
    WP34S_GammaP(&p, const_1on2(), &p, realContext, false, false);
    realSquareRoot(const39_pi(), &q, realContext);
    realDivide(&p, &q, &p, realContext);
    if (realIsNegative(x)) {
        realChangeSign(&p);
    }
    realCopy(&p, res);
    return;
}

pub export fn WP34S_Erfc(x: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    var p: real_t = undefined;

    realSquareRoot(const_2(), &p, realContext);
    realMultiply(x, &p, &p, realContext);
    realChangeSign(&p);
    WP34S_Cdf_Q(&p, &p, realContext);
    realMultiply(&p, const_2(), res, realContext);
}

// ===========================================================================
// check_low / ib_step / betacf (static) + WP34S_betai
// ===========================================================================
fn check_low(d: *align(1) real_t) void {
    var real_1e_32: real_t = undefined;

    realSetOne(&real_1e_32);
    real_1e_32.exponent -= 32;
    if (realCompareAbsLessThan(d, &real_1e_32)) {
        realCopy(d, &real_1e_32);
    }
}

fn ib_step(aa: *align(1) const real_t, d: *align(1) real_t, c: *align(1) real_t, realContext: *realContext_t) void {
    var t: real_t = undefined;
    var u: real_t = undefined;

    realMultiply(aa, d, &t, realContext);
    realAdd(&t, const_1(), &u, realContext); // d = 1+aa*d
    check_low(&u);
    realDivide(const_1(), &u, d, realContext);
    realDivide(aa, c, &t, realContext);
    realAdd(&t, const_1(), c, realContext); // c = 1+aa/c
    check_low(c);
}

fn betacf(a: *align(1) const real_t, b: *align(1) const real_t, x: *align(1) const real_t, r: *align(1) real_t, realContext: *realContext_t) void {
    var aa: real_t = undefined;
    var c: real_t = undefined;
    var d: real_t = undefined;
    var apb: real_t = undefined;
    var am1: real_t = undefined;
    var ap1: real_t = undefined;
    var m: real_t = undefined;
    var m2: real_t = undefined;
    var oldr: real_t = undefined;
    var t: real_t = undefined;
    var u: real_t = undefined;
    var v: real_t = undefined;
    var w: real_t = undefined;
    var loop: i32 = 0;

    realAdd(a, const_1(), &ap1, realContext); // ap1 = 1+a
    realSubtract(a, const_1(), &am1, realContext); // am1 = a-1
    realAdd(a, b, &apb, realContext); // apb = a+b
    realSetOne(&c); // c = 1
    realDivide(x, &ap1, &t, realContext);
    realMultiply(&t, &apb, &u, realContext);
    realSubtract(const_1(), &u, &t, realContext); // t = 1-apb*x/ap1
    check_low(&t);
    realDivide(const_1(), &t, &d, realContext); // d = 1/t
    realCopy(&d, r); // res = d
    realSetZero(&m);
    var i: i32 = 0;
    while (i < 500) : (i += 1) {
        realCopy(r, &oldr);
        realAdd(&m, const_1(), &m, realContext); // m = i+1
        realMultiply(&m, const_2(), &m2, realContext);
        realSubtract(b, &m, &t, realContext);
        realMultiply(&t, &m, &u, realContext);
        realMultiply(&u, x, &t, realContext); // t = m*(b-m)*x
        realAdd(&am1, &m2, &u, realContext);
        realAdd(a, &m2, &v, realContext);
        realMultiply(&u, &v, &w, realContext); // w = (am1+m2)*(a+m2)
        realDivide(&t, &w, &aa, realContext); // aa = t/w
        ib_step(&aa, &d, &c, realContext);
        realMultiply(r, &d, &t, realContext);
        realMultiply(&t, &c, r, realContext); // r = r*d*c
        realAdd(a, &m, &t, realContext);
        realAdd(&apb, &m, &u, realContext);
        realMultiply(&t, &u, &w, realContext);
        realMultiply(&w, x, &t, realContext);
        realMinus(&t, &w, realContext); // w = -(a+m)*(apb+m)*x
        realAdd(a, &m2, &t, realContext);
        realAdd(&ap1, &m2, &u, realContext);
        realMultiply(&t, &u, &v, realContext); // v = (a+m2)*(ap1+m2)
        realDivide(&w, &v, &aa, realContext); // aa = w/v
        ib_step(&aa, &d, &c, realContext);
        realMultiply(&d, &c, &v, realContext);
        realMultiply(r, &v, r, realContext); // r *= d*c
        if (realCompareEqual(&oldr, r)) {
            break;
        }
        if (monitorExit(&loop, "Iter: ")) {
            break;
        }
    }
}

pub export fn WP34S_betai(b: *align(1) const real_t, a: *align(1) const real_t, x: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    var t: real_t = undefined;
    var u: real_t = undefined;
    var v: real_t = undefined;
    var w: real_t = undefined;
    var y: real_t = undefined;
    var limit: i32 = 0;

    realCompare(const_1(), x, &t, realContext);
    if (realIsNegative(x) or realIsNegative(&t)) {
        realSetNaN(res);
        return;
    }

    if (realIsZero(x) or realIsZero(&t)) {
        limit = 1;
    } else {
        LnBeta(a, b, &u, realContext);
        WP34S_Ln(x, &v, realContext); // v = ln(x)
        realMultiply(a, &v, &t, realContext);
        realSubtract(&t, &u, &v, realContext); // v = lng(...)+a.ln(x)
        realSubtract(const_1(), x, &y, realContext); // y = 1-x
        WP34S_Ln(&y, &u, realContext); // u = ln(1-x)
        realMultiply(&u, b, &t, realContext);
        realAdd(&t, &v, &u, realContext); // u = lng(...)+a.ln(x)+b.ln(1-x)
        realExp(&u, &w, realContext);
    }

    realAdd(a, b, &v, realContext);
    realAdd(&v, const_2(), &u, realContext); // u = a+b+2
    realAdd(a, const_1(), &t, realContext); // t = a+1
    realDivide(&t, &u, &v, realContext); // u = (a+1)/(a+b+2)
    if (realCompareLessThan(x, &v)) {
        if (limit != 0) {
            realSetZero(res);
        } else {
            betacf(a, b, x, &t, realContext);
            realDivide(&t, a, &u, realContext);
            realMultiply(&w, &u, res, realContext);
        }
    } else {
        if (limit != 0) {
            realSetOne(res);
        } else {
            betacf(b, a, &y, &t, realContext);
            realDivide(&t, b, &u, realContext);
            realMultiply(&w, &u, &t, realContext);
            realSubtract(const_1(), &t, res, realContext);
        }
    }
}

// ===========================================================================
// WP34S_Bernoulli
// ===========================================================================
pub export fn WP34S_Bernoulli(x: *align(1) const real_t, res: *align(1) real_t, bn_star: bool, realContext: *realContext_t) callconv(.c) void {
    var p: real_t = undefined;

    if ((!realIsAnInteger(x)) or realCompareLessThan(x, const_0())) {
        realSetNaN(res);
        return;
    }
    if (realIsZero(x)) { // Bn_0
        realCopy(if (bn_star) const_NaN() else const_1(), res);
        return;
    }
    if (!bn_star) {
        if (realCompareEqual(x, const_1())) { // zeta_0
            realCopy(const_1on2(), res);
            realChangeSign(res);
            return;
        } else {
            realMultiply(x, const_1on2(), &p, realContext);
            if (!realIsAnInteger(&p)) { // Bn_odd
                realSetZero(res);
                return;
            }
        }
        realCopy(x, &p);
    } else {
        realMultiply(x, const_2(), &p, realContext);
    }

    // bernoulli
    realSubtract(&p, const_1(), &p, realContext);
    realChangeSign(&p);
    WP34S_Zeta(&p, &p, realContext);
    realMultiply(&p, x, &p, realContext);
    realChangeSign(&p);

    if (bn_star) {
        realMultiply(&p, const_2(), &p, realContext);
        realSetPositiveSign(&p);
    }
    realCopy(&p, res);
}

// ===========================================================================
// zeta_calc (static) + WP34S_Zeta
// ===========================================================================
fn zeta_calc(x: *align(1) const real_t, reg1: *align(1) const real_t, reg7: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) void {
    _ = x;
    _ = reg7;
    var p: real_t = undefined;
    var q: real_t = undefined;
    var r: real_t = undefined;
    var s: real_t = undefined;
    var reg0: real_t = undefined;
    var reg3: real_t = undefined;
    var reg4: real_t = undefined;
    var reg5: real_t = undefined;
    var reg6: real_t = undefined;
    var loop: i32 = 0;

    int32ToReal(60, &reg0);
    int32ToReal(60, &reg3);
    int32ToReal(1, &reg4);
    int32ToReal(1, &reg5);
    int32ToReal(-1, &reg6);
    realSetZero(&p);
    while (true) { // zeta_loop
        realMinus(reg1, &q, realContext);
        realPower(&reg0, &q, &q, realContext);
        realMultiply(&reg5, &q, &q, realContext);
        realChangeSign(&reg6);
        realMultiply(&q, &reg6, &q, realContext);
        realAdd(&p, &q, &p, realContext);
        realMultiply(&reg0, const_2(), &q, realContext);
        realMultiply(&q, &reg0, &q, realContext);
        realSubtract(&q, &reg0, &q, realContext);
        realMultiply(&q, &reg4, &q, realContext);
        realMultiply(&reg3, &reg3, &r, realContext);
        realSubtract(&reg0, const_1(), &s, realContext);
        realMultiply(&s, &s, &s, realContext);
        realSubtract(&r, &s, &r, realContext);
        realMultiply(&r, const_2(), &r, realContext);
        realDivide(&q, &r, &q, realContext);
        realCopy(&q, &reg4);
        realAdd(&q, &reg5, &reg5, realContext);
        realSubtract(&reg0, const_1(), &reg0, realContext);
        if (monitorExit(&loop, "Iter: ")) {
            break;
        }
        if (!realCompareGreaterThan(&reg0, const_0())) {
            break;
        }
    }
    realDivide(&p, &reg5, &p, realContext);
    realSubtract(const_1(), reg1, &r, realContext);
    realMultiply(const39_ln2(), &r, &r, realContext);
    WP34S_ExpM1(&r, &q, realContext);
    realDivide(&p, &q, res, realContext);
}

pub export fn WP34S_Zeta(x: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    var p: real_t = undefined;
    var q: real_t = undefined;
    var r: real_t = undefined;
    var reg1: real_t = undefined;
    var reg7: real_t = undefined;

    if (realIsZero(x)) {
        realCopy(const_1on2(), res);
        realChangeSign(res);
        return;
    }

    // zeta_int
    realCopy(x, &reg1);
    realCopy(x, &reg7);
    if (realCompareGreaterThan(x, const_1on2())) {
        zeta_calc(x, &reg1, &reg7, res, realContext);
    } else { // zeta_neg
        realSubtract(const_1(), x, &q, realContext);
        realCopy(&q, &reg1);
        zeta_calc(&q, &reg1, &reg7, &p, realContext);
        C47_WP34S_Asin(const_1(), &q, realContext);
        realMultiply(&q, &reg7, &q, realContext);
        C47_WP34S_Cvt2RadSinCosTan(&q, amRadian, &r, null, null, realContext);
        realMultiply(&p, &r, &p, realContext);
        realDivide(&p, const39_pi(), &p, realContext);
        realPower(const39_2pi(), &reg7, &q, realContext);
        realMultiply(&p, &q, &p, realContext);
        realCopy(&reg1, &q);
        WP34S_Gamma(&q, &r, realContext);
        realMultiply(&r, &p, res, realContext);
    }
}

// ===========================================================================
// WP34S_LambertW
// ===========================================================================
pub export fn WP34S_LambertW(x: *align(1) const real_t, res: *align(1) real_t, negativeBranch: bool, realContext: *realContext_t) callconv(.c) void {
    var p: real_t = undefined;
    var q: real_t = undefined;
    var r: real_t = undefined;
    var reg0: real_t = undefined;
    var reg1: real_t = undefined;
    var reg2: real_t = undefined;
    var converged: bool = false;

    if (realIsSpecial(x)) {
        realSetNaN(res);
        return;
    }
    if (realIsZero(x)) {
        realCopy(if (negativeBranch) const_minusInfinity() else const_0(), res);
        return;
    }
    if (negativeBranch and realIsPositive(x)) {
        realSetNaN(res);
        return;
    }

    // LamW0_common
    realCopy(x, &reg0);
    int32ToReal(7, &reg1);
    int32ToReal(if (negativeBranch) 25 else 35, &p);
    p.exponent -= 2;
    realChangeSign(&p);
    if (realCompareLessEqual(&reg0, &p)) {
        realDivide(const_1(), const39_eE(), &q, realContext);
        realAdd(&reg0, &q, &q, realContext);
        realMultiply(&q, const39_eE(), &q, realContext);
        realCopy(&q, &reg2);
        realMultiply(&q, const_2(), &q, realContext);
        realSquareRoot(&q, &r, realContext);
        if (negativeBranch) {
            realChangeSign(&r);
        }
        realMultiply(&q, const39_1on3(), &q, realContext);
        realSubtract(&r, &q, &q, realContext);

        // Newton iteration for W+1
        while (true) { // LamW0_wp1_newton
            realMinus(&q, &p, realContext);
            WP34S_ExpM1(&p, &p, realContext);
            realMultiply(&p, &reg0, &p, realContext);
            realMultiply(&p, const39_eE(), &p, realContext);
            realSubtract(&p, &q, &p, realContext);
            realAdd(&p, &reg2, &p, realContext);
            realDivide(&p, &q, &p, realContext);
            realAdd(&p, &q, &p, realContext);
            if (converged) {
                break;
            }
            if (WP34S_AbsoluteError(&p, &q, if (realContext == &ctxtReal39) const_1e_37() else const_1e_49(), realContext)) {
                converged = true;
            }
            realSubtract(&reg1, const_1(), &reg1, realContext);
            realCopy(&p, &q);
            if (!realCompareGreaterThan(&reg1, const_0())) {
                break;
            }
        }
        // LamW0_converged
        realSubtract(&p, const_1(), res, realContext);
    } else { // LamW0_normal
        if (negativeBranch) { // LamW0_smallx
            realMinus(&reg0, &q, realContext);
            WP34S_Ln(&q, &q, realContext);
            realMinus(&q, &r, realContext);
            WP34S_Ln(&r, &r, realContext);
            realSubtract(&q, &r, &q, realContext);
        } else {
            WP34S_Ln1P(&reg0, &q, realContext);
            if (realCompareGreaterThan(&q, const_1())) {
                WP34S_Ln(&q, &r, realContext);
                realSubtract(&q, &r, &q, realContext);
            }
        }
        // Newton-Halley iteration for W
        while (true) { // LamW0_halley
            realExp(&q, &r, realContext);
            realDivide(&reg0, &r, &r, realContext);
            realSubtract(&q, &r, &r, realContext);
            realAdd(&q, const_1(), &p, realContext);
            realDivide(&r, &p, &r, realContext);
            realDivide(const_1(), &p, &p, realContext);
            realAdd(&p, const_1(), &p, realContext);
            realMultiply(&p, &r, &p, realContext);
            realMultiply(&p, const_1on2(), &p, realContext);
            realChangeSign(&p);
            realAdd(&p, const_1(), &p, realContext);
            realDivide(&r, &p, &r, realContext);
            realSubtract(&q, &r, &r, realContext);
            // R Q Q
            if (converged) {
                break;
            }
            if (WP34S_RelativeError(&r, &q, if (realContext == &ctxtReal39) const_1e_37() else const_1e_49(), realContext)) {
                converged = true;
            }
            realSubtract(&reg1, const_1(), &reg1, realContext);
            realCopy(&r, &q);
            if (!realCompareGreaterThan(&reg1, const_0())) {
                break;
            }
        }
        // LamW0_finish
        realCopy(&r, res);
    }
}

// ===========================================================================
// WP34S_ComplexLambertW
// ===========================================================================
pub export fn WP34S_ComplexLambertW(xReal: *align(1) const real_t, xImag: *align(1) const real_t, resReal: *align(1) real_t, resImag: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    var pr: real_t = undefined;
    var pi: real_t = undefined;
    var qr: real_t = undefined;
    var qi: real_t = undefined;
    var zr: real_t = undefined;
    var zi: real_t = undefined;
    var wr: real_t = undefined;
    var wi: real_t = undefined;
    var tr: real_t = undefined;
    var ti: real_t = undefined;

    realCopy(xReal, &zr);
    realCopy(xImag, &zi);
    realSetOne(&wr);
    realSetOne(&wi);
    realAdd(xReal, const_1(), &pr, realContext);
    realCopy(xImag, &pi);
    if (realIsZero(&zi) and realIsNegative(&zr) and realCompareGreaterEqual(&zr, const__1())) {
        // Close to -1/e, the series is very slow to converge
        realSetOne(&pr);
        realCopy(if (realIsNegative(&pi)) const__1() else const_1(), &pi);
    } else if (!realIsZero(&pr) or !realIsZero(&pi)) {
        lnComplex(&pr, &pi, &pr, &pi, realContext);
        realCopy(&pr, &wr);
        realCopy(&pi, &wi);
    }
    while (true) { // LamW_cloop
        expComplex(&pr, &pi, &qr, &qi, realContext);
        realCopy(&qr, &tr);
        realCopy(&qi, &ti);
        mulComplexComplex(&qr, &qi, &wr, &wi, &qr, &qi, realContext);
        realAdd(&tr, &qr, &tr, realContext);
        realAdd(&ti, &qi, &ti, realContext);
        realSubtract(&qr, &zr, &qr, realContext);
        realSubtract(&qi, &zi, &qi, realContext);
        divComplexComplex(&qr, &qi, &tr, &ti, &qr, &qi, realContext);
        realSubtract(&wr, &qr, &wr, realContext);
        realSubtract(&wi, &qi, &wi, realContext);
        if (WP34S_ComplexAbsError(&wr, &wi, &pr, &pi, const_1e_37(), realContext)) {
            break;
        }
        realCopy(&wr, &pr);
        realCopy(&wi, &pi);
    }
    realCopy(&wr, resReal);
    realCopy(&wi, resImag);
}

// ===========================================================================
// WP34S_InverseW / WP34S_InverseComplexW
// ===========================================================================
pub export fn WP34S_InverseW(x: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    var p: real_t = undefined;

    realExp(x, &p, realContext);
    realMultiply(&p, x, res, realContext);
}

pub export fn WP34S_InverseComplexW(xReal: *align(1) const real_t, xImag: *align(1) const real_t, resReal: *align(1) real_t, resImag: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    var p: real_t = undefined;
    var q: real_t = undefined;

    expComplex(xReal, xImag, &p, &q, realContext);
    mulComplexComplex(&p, &q, xReal, xImag, resReal, resImag, realContext);
}

// ===========================================================================
// WP34S_OrthoPoly
// ===========================================================================
pub export fn WP34S_OrthoPoly(kind: u16, rX: *align(1) const real_t, rN: *align(1) const real_t, rParam: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    var a: real_t = undefined;
    var b: real_t = undefined;
    var c: real_t = undefined;
    var d: real_t = undefined;
    var i: real_t = undefined;
    var rT0: real_t = undefined;
    var rT1: real_t = undefined;
    var incB: real_t = undefined;
    var p: real_t = undefined;
    var q: real_t = undefined;
    var incA: bool = false;
    var incC: bool = false;

    // ortho_default
    if (realIsSpecial(rX) or (!realIsAnInteger(rN)) or realIsNegative(rN)) {
        realSetNaN(res);
        return;
    }
    if (realIsZero(rN)) {
        realSetOne(res);
        return;
    }
    realSetOne(&rT0);
    // Now initialise everything else
    realCopy(const_2(), &i);
    realCopy(const_2(), &d);
    realSetOne(&c);
    realSetOne(&b);
    realCopy(rX, &rT1);
    realMultiply(rX, const_2(), &a, realContext);

    // We must initialise this too
    realSetZero(&incB);

    var goto_allinc: bool = false;
    switch (kind) {
        ORTHOPOLY_LEGENDRE_P => {
            realAdd(&a, rX, &a, realContext);
            realMultiply(rX, const_2(), &d, realContext);
            goto_allinc = true;
        },
        ORTHOPOLY_CHEBYSHEV_T => {},
        ORTHOPOLY_CHEBYSHEV_U => {
            realAdd(&rT1, rX, &rT1, realContext);
        },
        ORTHOPOLY_LAGUERRE_L, ORTHOPOLY_LAGUERRE_L_ALPHA => {
            // laguerre_common
            if (realIsSpecial(rParam) or realCompareLessEqual(rParam, const__1())) {
                realSetNaN(res);
                return;
            }
            realAdd(&b, rParam, &b, realContext);
            realAdd(rParam, const_3(), &a, realContext);
            realSubtract(&a, rX, &a, realContext);
            realAdd(rParam, const_1(), &rT1, realContext);
            realSubtract(&rT1, rX, &rT1, realContext);
            goto_allinc = true;
        },
        ORTHOPOLY_HERMITE_HE => {
            realCopy(rX, &a);
            realSetOne(&incB);
        },
        ORTHOPOLY_HERMITE_H => {
            realAdd(&rT1, rX, &rT1, realContext);
            realCopy(const_2(), &b);
            realCopy(const_2(), &incB);
        },
        else => {},
    }

    if (goto_allinc) {
        // ortho_allinc
        incA = true;
        realSetOne(&incB);
        incC = true;
    }

    // ortho_common
    while (realCompareLessEqual(&i, rN)) { // ortho_loop
        realMultiply(&rT1, &a, &p, realContext);
        realMultiply(&rT0, &b, &q, realContext);
        realCopy(&rT1, &rT0);
        realSubtract(&p, &q, &rT1, realContext);

        if (incC) {
            realAdd(&c, const_1(), &c, realContext);
            realDivide(&rT1, &c, &rT1, realContext);
        } // ortho_noC
        if (incA) {
            realAdd(&a, &d, &a, realContext);
        } // ortho_noA
        realAdd(&b, &incB, &b, realContext);
        realAdd(&i, const_1(), &i, realContext);
    }
    realCopy(&rT1, res);
}
