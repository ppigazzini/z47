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

const runtime = @import("../command_wrappers/runtime.zig");
const math_command_wrappers = @import("../command_wrappers.zig");
pub const math_comparison_reals = @import("../compare/comparison_reals.zig");
const math_division_cells = @import("../arithmetic/division_cells.zig");
const math_ln_complex = @import("../ln_complex.zig");
const math_lnbeta = @import("lnbeta.zig");
const math_multiplication_cells = @import("../arithmetic/multiplication_cells.zig");
const math_runtime_helpers = @import("../command_wrappers/helpers.zig");
const math_real_predicates = @import("../compare/real_predicates.zig");
const wp34s_atan = @import("../trig/wp34s_atan.zig"); // inverse-circular split
const wp34s_trig = @import("wp34s_trig.zig"); // forward-circular split
pub const real_t = runtime.real_t;
pub const realContext_t = runtime.realContext_t;
pub const cplx_t = runtime.cplx_t;
pub const angularMode_t = runtime.angularMode_t;

pub const amRadian = runtime.amRadian;
pub const amGrad = runtime.amGrad;
pub const amDegree = runtime.amDegree;
pub const amDMS = runtime.amDMS;
pub const amMultPi = runtime.amMultPi;

// ---------------------------------------------------------------------------
// real_t constant blob accessors. Use the runtime accessors where they exist
// (properly aligned *align(1) const real_t); otherwise the byte-offset blob pattern.
// ---------------------------------------------------------------------------
const cstR = consts.cstR;

pub inline fn const_0() *align(1) const real_t {
    return consts.c1708();
}
pub inline fn const_1() *align(1) const real_t {
    return consts.c4856();
}
pub inline fn const_2() *align(1) const real_t {
    return consts.c4928();
}
inline fn const_3() *align(1) const real_t {
    return consts.c5012();
}
inline fn const__1() *align(1) const real_t {
    return consts.c4376();
}
pub inline fn const_1on2() *align(1) const real_t {
    return consts.c4580();
}
pub inline fn const_1on4() *align(1) const real_t {
    return consts.c4532();
}
pub inline fn const_1on10() *align(1) const real_t {
    return consts.c4520();
}
inline fn const_6() *align(1) const real_t {
    return consts.const_6();
}
inline fn const_3on2() *const real_t {
    return consts.const_3on2();
}
pub inline fn const_30() *const real_t {
    return consts.const_30();
}
inline fn const_29() *align(1) const real_t {
    return consts.c5180();
}
pub inline fn const_45() *align(1) const real_t {
    return consts.c7628();
}
inline fn const_47() *align(1) const real_t {
    return consts.c5236();
}
pub inline fn const_50() *align(1) const real_t {
    return consts.c7616();
}
pub inline fn const_90() *align(1) const real_t {
    return consts.c7544();
}
pub inline fn const_100() *align(1) const real_t {
    return consts.c7532();
}
pub inline fn const_180() *align(1) const real_t {
    return consts.c7460();
}
pub inline fn const_200() *align(1) const real_t {
    return consts.c7448();
}
inline fn const_205() *align(1) const real_t {
    return consts.c5344();
}
pub inline fn const_360() *align(1) const real_t {
    return consts.c5356();
}
pub inline fn const_400() *align(1) const real_t {
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
pub inline fn const39_pi() *align(1) const real_t {
    return consts.c1848();
}
inline fn const39_2pi() *align(1) const real_t {
    return consts.c1812();
}
pub inline fn const39_piOn2() *align(1) const real_t {
    return consts.c4880();
}
pub inline fn const39_piOn4() *align(1) const real_t {
    return consts.c4736();
}
pub inline fn const39_3piOn4() *align(1) const real_t {
    return consts.c4976();
}
inline fn const39_ln2() *align(1) const real_t {
    return consts.c4628();
}
inline fn const39_ln10() *align(1) const real_t {
    return consts.c4940();
}
pub inline fn const39_root2on2() *align(1) const real_t {
    return consts.c4700();
}
inline fn const39_egamma() *align(1) const real_t {
    return consts.c4592();
}
inline fn const39_eE() *align(1) const real_t {
    return consts.c176();
}
pub inline fn const39_1on3() *align(1) const real_t {
    return consts.c4544();
}
pub inline fn const_1on5() *align(1) const real_t {
    return consts.const_1on5();
}
pub inline fn const39_1on7() *align(1) const real_t {
    return consts.const39_1on7();
}
pub inline fn const39_1on9() *align(1) const real_t {
    return consts.const39_1on9();
}
pub inline fn const39_1on11() *align(1) const real_t {
    return consts.const39_1on11();
}
pub inline fn const39_1on13() *align(1) const real_t {
    return consts.const39_1on13();
}
pub inline fn const39_1on15() *align(1) const real_t {
    return consts.const39_1on15();
}
pub inline fn const39_atan1on10() *align(1) const real_t {
    return consts.const39_atan1on10();
}
pub inline fn const39_atan2on10() *align(1) const real_t {
    return consts.const39_atan2on10();
}
pub inline fn const39_atan3on10() *align(1) const real_t {
    return consts.const39_atan3on10();
}
pub inline fn const39_atan4on10() *align(1) const real_t {
    return consts.const39_atan4on10();
}
pub inline fn const39_atan5on10() *align(1) const real_t {
    return consts.const39_atan5on10();
}
pub inline fn const39_atan6on10() *align(1) const real_t {
    return consts.const39_atan6on10();
}
pub inline fn const39_atan7on10() *align(1) const real_t {
    return consts.const39_atan7on10();
}
pub inline fn const39_atan8on10() *align(1) const real_t {
    return consts.const39_atan8on10();
}
pub inline fn const39_atan9on10() *align(1) const real_t {
    return consts.const39_atan9on10();
}
pub inline fn const39_atanP08() *align(1) const real_t {
    return consts.const39_atanP08();
}
pub inline fn const39_atanP09() *align(1) const real_t {
    return consts.const39_atanP09();
}
pub inline fn const39_atanP10() *align(1) const real_t {
    return consts.const39_atanP10();
}
pub inline fn const39_atanP11() *align(1) const real_t {
    return consts.const39_atanP11();
}
pub inline fn const39_atanP12() *align(1) const real_t {
    return consts.const39_atanP12();
}
pub inline fn const75_pi() *align(1) const real_t {
    return consts.c7388();
}
pub inline fn const75_piOn2() *align(1) const real_t {
    return consts.c7472();
}
pub inline fn const75_piOn4() *align(1) const real_t {
    return consts.c7556();
}
pub inline fn const75_3piOn4() *align(1) const real_t {
    return consts.c7700();
}
pub inline fn const1071_pi() *align(1) const real_t {
    return consts.c9932();
}
pub inline fn const1071_piOn2() *align(1) const real_t {
    return consts.c9208();
}
pub inline fn const1071_piOn4() *align(1) const real_t {
    return consts.c8484();
}
pub inline fn const1071_3piOn4() *align(1) const real_t {
    return consts.c7760();
}
inline fn const75_gammaC00() *align(1) const real_t {
    return consts.const75_gammaC00();
}
inline fn const75_gammaC01(k: u32) *align(1) const real_t {
    return consts.gammaC75(k);
}
pub inline fn const_4() *align(1) const real_t {
    return consts.const_4();
}
pub inline fn const_8() *align(1) const real_t {
    return consts.const_8();
}
inline fn const_10() *align(1) const real_t {
    return consts.const_10();
}
inline fn const_1e_6() *align(1) const real_t {
    return consts.const_1e_6();
}
inline fn const_1e_34() *align(1) const real_t {
    return consts.const_1e_34();
}
inline fn const_plusInfinity() *align(1) const real_t {
    return consts.c1696();
}
inline fn const75_ln2() *align(1) const real_t {
    return consts.const75_ln2();
}
inline fn const75_ln10() *align(1) const real_t {
    return consts.const75_ln10();
}
inline fn const75_2pi() *align(1) const real_t {
    return consts.const75_2pi();
}
inline fn const39_root2() *align(1) const real_t {
    return consts.const39_root2();
}
inline fn const_1on40000() *align(1) const real_t {
    return consts.const_1on40000();
}
// RADIAN_REDUCTION_2PI: the DM42 reduces with the 2139-digit 2pi, since the
// 12321-digit one NaNs on the DM42 decNumber at the 2139 context.
pub inline fn radianReduction2Pi() *align(1) const real_t {
    return if (comptime runtime.wp34s_mod_small_buffers) consts.const2139_2pi() else consts.const12321_2pi();
}

// ---------------------------------------------------------------------------
// Globals / externs.
// ---------------------------------------------------------------------------
extern var ctxtReal39: realContext_t;
extern var ctxtReal51: realContext_t;
extern var ctxtReal75: realContext_t;
pub extern var explicitTaylorIterVisibilitySelection: bool;

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
extern fn decNumberNextToward(res: *align(1) real_t, from: *align(1) const real_t, toward: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
extern fn decNumberFMA(res: *align(1) real_t, factor1: *align(1) const real_t, factor2: *align(1) const real_t, term: *align(1) const real_t, ctxt: *realContext_t) *align(1) real_t;
extern fn decNumberFromString(res: *align(1) real_t, source: [*:0]const u8, ctxt: *realContext_t) *align(1) real_t;
extern fn decNumberFromInt32(res: *align(1) real_t, source: i32) *align(1) real_t;
extern fn decNumberFromUInt32(res: *align(1) real_t, source: u32) *align(1) real_t;

// real* setters / predicates.
pub extern fn realSetNaN(value: *align(1) real_t) void;
extern fn realSetPlusInfinity(value: *align(1) real_t) void;
extern fn realSetMinusInfinity(value: *align(1) real_t) void;

// Higher-level real ops / transcendentals from elsewhere in the tree.
pub extern fn convertAngleFromTo(angle: *align(1) real_t, from: angularMode_t, to: angularMode_t, ctxt: *realContext_t) void;

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
pub const checkHalfSec = abi.host.checkHalfSec; // routed through the host-callback boundary
pub const exitKeyWaiting = abi.host.exitKeyWaiting;
pub const progressHalfSecUpdate_Integer = abi.host.progressHalfSecUpdate_Integer; // routed through the host-callback boundary
extern fn monitorExit(loop: *i32, str: [*:0]const u8) bool;
pub extern fn displayCalcErrorMessage(error_code: u8, err_message_register_line: runtime.calcRegister_t) void;

pub const ERROR_SOLVER_ABORT: u8 = 60;
pub const REGISTER_T: runtime.calcRegister_t = 103;
pub const NIM_REGISTER_LINE: runtime.calcRegister_t = 100; // REGISTER_X
pub const halfSec_timed: u8 = 0;
pub const halfSec_force: u8 = 1;
pub const halfSec_clearZ: bool = true;
pub const halfSec_clearT: bool = true;
pub const halfSec_disp: bool = true;
pub const TaylorIterationMax: i32 = 1000;

// ---------------------------------------------------------------------------
// real_t op helpers mirroring the realType.h macro argument order. Operands are
// *align(1) const real_t so blob constants and stack scratch both work.
// ---------------------------------------------------------------------------
pub inline fn realCopy(source: *align(1) const real_t, destination: *align(1) real_t) void {
    _ = decNumberCopy(destination, source);
}
pub inline fn realCopyAbs(source: *align(1) const real_t, destination: *align(1) real_t) void {
    _ = decNumberCopyAbs(destination, source);
}
pub inline fn realPlus(operand: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberPlus(res, operand, ctxt);
}
pub inline fn realMinus(operand: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberMinus(res, operand, ctxt);
}
pub inline fn realAdd(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberAdd(res, op1, op2, ctxt);
}
pub inline fn realSubtract(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberSubtract(res, op1, op2, ctxt);
}
pub inline fn realMultiply(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberMultiply(res, op1, op2, ctxt);
}
pub inline fn realDivide(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberDivide(res, op1, op2, ctxt);
}
pub inline fn realSquareRoot(operand: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberSquareRoot(res, operand, ctxt);
}
inline fn realPower(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberPower(res, op1, op2, ctxt);
}
pub inline fn realCompare(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberCompare(res, op1, op2, ctxt);
}
inline fn realNextToward(from: *align(1) const real_t, toward: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberNextToward(res, from, toward, ctxt);
}
pub inline fn realDivideRemainder(op1: *align(1) const real_t, op2: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberRemainder(res, op1, op2, ctxt);
}
inline fn realFMA(factor1: *align(1) const real_t, factor2: *align(1) const real_t, term: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberFMA(res, factor1, factor2, term, ctxt);
}
inline fn realExp(x: *align(1) const real_t, res: *align(1) real_t, ctxt: *realContext_t) void {
    math_command_wrappers.realExp(@alignCast(x), @alignCast(res), ctxt);
}
pub inline fn stringToReal(source: [*:0]const u8, destination: *align(1) real_t, ctxt: *realContext_t) void {
    _ = decNumberFromString(destination, source, ctxt);
}
inline fn int32ToReal(source: i32, destination: *align(1) real_t) void {
    _ = decNumberFromInt32(destination, source);
}
pub inline fn uInt32ToReal(source: u32, destination: *align(1) real_t) void {
    _ = decNumberFromUInt32(destination, source);
}

pub inline fn realSetOne(r: *align(1) real_t) void {
    _ = decNumberFromInt32(r, 1);
}
pub inline fn realSetNegativeOne(r: *align(1) real_t) void {
    _ = decNumberFromInt32(r, -1);
}
pub inline fn realSetZero(r: *align(1) real_t) void {
    _ = decNumberFromInt32(r, 0);
}
pub const realIsNegative = math_real_predicates.realIsNegative;
pub const realIsPositive = math_real_predicates.realIsPositive;
pub const realIsZero = math_real_predicates.realIsZero;
const realIsSpecial = math_real_predicates.realIsSpecial;
pub inline fn realIsInfinite(source: *align(1) const real_t) bool {
    return (source.bits & 0x40) != 0;
}
pub inline fn realIsNaN(source: *align(1) const real_t) bool {
    return (source.bits & (0x20 | 0x10)) != 0;
}
pub inline fn realChangeSign(operand: *align(1) real_t) void {
    operand.bits ^= 0x80;
}
pub inline fn realSetNegativeSign(operand: *align(1) real_t) void {
    operand.bits |= 0x80;
}
pub inline fn realSetPositiveSign(operand: *align(1) real_t) void {
    operand.bits &= 0x7F;
}
pub inline fn realGetExponent(source: *align(1) const real_t) i32 {
    return source.digits + source.exponent - 1;
}

pub inline fn maxI32(a: i32, b: i32) i32 {
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
pub fn BigReal(comptime digits: u32) type {
    return struct {
        buf: [realSizeInBytes(digits)]u8 align(4) = undefined,
        pub inline fn ptr(self: *@This()) *align(1) real_t {
            return @ptrCast(&self.buf);
        }
    };
}

// The heap twin of BigReal, for the 1071-digit working reals upstream moved off
// the frame at the 6559a9c59 pin: eight of them at 724 bytes is 5792 bytes of a
// 5832-byte frame on an arm build, and that frame is the stack reason XFN 1000 is
// kept off the DM42 (defines.h). Same allocator as REAL_T_ALLOC/REAL_T_FREE.
extern fn malloc(size: usize) ?*anyopaque;
extern fn free(ptr: ?*anyopaque) void;

pub inline fn mallocBigReal(comptime digits: u32) ?*align(1) real_t {
    return @ptrCast(malloc(realSizeInBytes(digits)));
}

pub inline fn freeBigReal(ptr: ?*align(1) real_t) void {
    free(@ptrCast(ptr));
}

// ===========================================================================
// The distribution entry points: the parameter loader, the descriptor table and
// fnDistribution, then the probability helpers the kernels mark results with.
// ===========================================================================

/// wp34sDistributionDomainRule_t: a distribution's own check of the registers
/// WP34S_CheckDistributionParameters read, called with registersValid false when
/// a register did not hold a real.
pub const DomainRule = *const fn (registers_valid: bool, x: *real_t, first: ?*real_t, second: ?*real_t, third: ?*real_t, parameter: u16) callconv(.c) bool;

extern fn displayDomainErrorMessage(error_code: u8, err_message_register_line: runtime.calcRegister_t) void;

const REGISTER_M: runtime.calcRegister_t = 112;
const REGISTER_N: runtime.calcRegister_t = 113;
const REGISTER_P: runtime.calcRegister_t = 114;
const REGISTER_Q: runtime.calcRegister_t = 115;
const REGISTER_R: runtime.calcRegister_t = 116;
const REGISTER_S: runtime.calcRegister_t = 117;
const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN: u8 = 1;
const ERROR_INVALID_DISTRIBUTION_PARAM: u8 = 16;
const ERROR_NO_ROOT_FOUND: u8 = 20;

/// Loads register X and the stat registers a distribution takes its parameters
/// from, and checks them with the distribution's own domain rule. Either failure
/// leaves NaN in X when special results are on.
pub export fn WP34S_CheckDistributionParameters(x: *real_t, firstRegister: runtime.calcRegister_t, first: ?*real_t, secondRegister: runtime.calcRegister_t, second: ?*real_t, thirdRegister: runtime.calcRegister_t, third: ?*real_t, parameter: u16, domainRule: DomainRule) callconv(.c) bool {
    if (!runtime.saveLastX()) {
        return false;
    }

    const registersValid = runtime.getRegisterAsReal(runtime.REGISTER_X, x) and
        (first == null or runtime.getRegisterAsReal(firstRegister, first)) and
        (second == null or runtime.getRegisterAsReal(secondRegister, second)) and
        (third == null or runtime.getRegisterAsReal(thirdRegister, third));
    if (!registersValid) {
        _ = domainRule(false, x, first, second, third, parameter);
        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.convertRealToResultRegister(runtime.const_NaN, runtime.REGISTER_X, runtime.amNone);
        }
        return false;
    }
    if (!domainRule(true, x, first, second, third, parameter)) {
        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.convertRealToResultRegister(runtime.const_NaN, runtime.REGISTER_X, runtime.amNone);
        }
        return false;
    }
    return true;
}

// A distribution's four entry points differ in the stat registers its parameters
// live in, the domain rule, the kernel, and the context each one works at, so one
// body serves them all and the descriptor states the difference. The kernels keep
// the argument lists they already have, and arity says which member to call.
const Kernel1 = *const fn (x: *const real_t, a: *const real_t, res: *real_t, real_context: *realContext_t) callconv(.c) void;
const Kernel2 = *const fn (x: *const real_t, a: *const real_t, b: *const real_t, res: *real_t, real_context: *realContext_t) callconv(.c) void;
// distribution_t's kernel union, as two fields: the table is file-local, so no C
// code reads its layout, and an entry has no kernel when both are null.
const DistributionKernel = struct {
    one: ?Kernel1 = null,
    two: ?Kernel2 = null,
};

const DIST_CTX_39: u8 = 0;
const DIST_CTX_51: u8 = 1;
const DIST_CTX_75: u8 = 2;

// What each distribution does on top of the five lines every entry shares.
const DIST_INV_NAN_ARG: u8 = 0x01; // the inverse refuses a NaN argument as well as one outside 0 to 1
const DIST_INV_REPORT_FIRST: u8 = 0x02; // the inverse reports the domain error before the special-result branch, not instead of it
const DIST_INV_NOROOT: u8 = 0x04; // an inverse that answers NaN raises ERROR_NO_ROOT_FOUND
const DIST_INV_NOROOT_NAN: u8 = 0x08; // and puts NaN in X when special results are on
const DIST_ERR_RETURNS: u8 = 0x10; // that branch returns rather than falling through to adjustResult
const DIST_PDF_INTEGER_ONLY: u8 = 0x20; // the density is zero at a non-integer argument
const DIST_PDF_NAN_IS_ERROR: u8 = 0x40; // a density that answers NaN raises ERROR_INVALID_DISTRIBUTION_PARAM

/// distribution_t (wp34s.h). File-local: nothing outside this owner reads the table.
const Distribution = struct {
    firstRegister: u8, // the stat register the first parameter lives in
    secondRegister: u8, // and the second, 0 when the distribution takes one parameter
    arity: u8, // how many parameters the kernel takes after x
    secondFirst: u8, // the kernel wants the second parameter before the first
    flags: u8, // the DIST_ bits above
    context: [4]u8, // DIST_CTX_* per entry, in the order density, lower tail, upper tail, inverse
    domainRule: ?DomainRule,
    kernel: [4]DistributionKernel, // density, lower tail, upper tail, inverse
};

const DIST_P: u8 = 0;
const DIST_I: u8 = 3;

const DIST_EXPON = 0;
const DIST_CAUCHY = 1;
const DIST_LOGIT = 2;
const DIST_WEIB = 3;
const DIST_BINOM = 4;
const DIST_GEOM = 5;
const DIST_POISSON = 6;
const DIST_NEGBINOM = 7;
const DIST_CHI2 = 8;
const DIST_T = 9;
const DIST_F = 10;
const DIST_COUNT = 11;

// The domain rules and kernels the descriptor names, exported by the
// distribution owners from frontier.zig under the same per-file gates.
extern fn exponentialCheckDomain(registers_valid: bool, x: *real_t, first: ?*real_t, second: ?*real_t, third: ?*real_t, parameter: u16) bool;
extern fn cauchyCheckDomain(registers_valid: bool, x: *real_t, first: ?*real_t, second: ?*real_t, third: ?*real_t, parameter: u16) bool;
extern fn logisticCheckDomain(registers_valid: bool, x: *real_t, first: ?*real_t, second: ?*real_t, third: ?*real_t, parameter: u16) bool;
extern fn weibullCheckDomain(registers_valid: bool, x: *real_t, first: ?*real_t, second: ?*real_t, third: ?*real_t, parameter: u16) bool;
extern fn binomialCheckDomain(registers_valid: bool, x: *real_t, first: ?*real_t, second: ?*real_t, third: ?*real_t, parameter: u16) bool;
extern fn geometricCheckDomain(registers_valid: bool, x: *real_t, first: ?*real_t, second: ?*real_t, third: ?*real_t, parameter: u16) bool;
extern fn poissonCheckDomain(registers_valid: bool, x: *real_t, first: ?*real_t, second: ?*real_t, third: ?*real_t, parameter: u16) bool;
extern fn negativeBinomialCheckDomain(registers_valid: bool, x: *real_t, first: ?*real_t, second: ?*real_t, third: ?*real_t, parameter: u16) bool;
extern fn chi2CheckDomain(registers_valid: bool, x: *real_t, first: ?*real_t, second: ?*real_t, third: ?*real_t, parameter: u16) bool;
extern fn studentTCheckDomain(registers_valid: bool, x: *real_t, first: ?*real_t, second: ?*real_t, third: ?*real_t, parameter: u16) bool;
extern fn fCheckDomain(registers_valid: bool, x: *real_t, first: ?*real_t, second: ?*real_t, third: ?*real_t, parameter: u16) bool;

extern fn WP34S_Pdf_Expon(x: *const real_t, a: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_Cdf_Expon(x: *const real_t, a: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_Cdfu_Expon(x: *const real_t, a: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_Qf_Expon(x: *const real_t, a: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_Pdf_Cauchy(x: *const real_t, a: *const real_t, b: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_Cdf_Cauchy(x: *const real_t, a: *const real_t, b: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_Cdfu_Cauchy(x: *const real_t, a: *const real_t, b: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_Qf_Cauchy(x: *const real_t, a: *const real_t, b: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_Pdf_Logit(x: *const real_t, a: *const real_t, b: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_Cdf_Logit(x: *const real_t, a: *const real_t, b: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_Cdfu_Logit(x: *const real_t, a: *const real_t, b: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_Qf_Logit(x: *const real_t, a: *const real_t, b: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_Pdf_Weib(x: *const real_t, a: *const real_t, b: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_Cdf_Weib(x: *const real_t, a: *const real_t, b: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_Cdfu_Weib(x: *const real_t, a: *const real_t, b: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_Qf_Weib(x: *const real_t, a: *const real_t, b: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_Pdf_Binomial(x: *const real_t, a: *const real_t, b: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_Cdf_Binomial(x: *const real_t, a: *const real_t, b: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_Cdfu_Binomial(x: *const real_t, a: *const real_t, b: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_Qf_Binomial(x: *const real_t, a: *const real_t, b: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_Pdf_Geom(x: *const real_t, a: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_Cdf_Geom(x: *const real_t, a: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_Cdfu_Geom(x: *const real_t, a: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_Qf_Geom(x: *const real_t, a: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_Pdf_Poisson(x: *const real_t, a: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_Cdf_Poisson(x: *const real_t, a: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_Cdfu_Poisson(x: *const real_t, a: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_Qf_Poisson(x: *const real_t, a: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn pdf_NegBinomial(x: *const real_t, a: *const real_t, b: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn cdf_NegBinomial(x: *const real_t, a: *const real_t, b: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn cdfu_NegBinomial(x: *const real_t, a: *const real_t, b: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn qf_NegBinomial(x: *const real_t, a: *const real_t, b: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_Pdf_Chi2(x: *const real_t, a: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_Cdf_Chi2(x: *const real_t, a: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_Cdfu_Chi2(x: *const real_t, a: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_Qf_Chi2(x: *const real_t, a: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_Pdf_T(x: *const real_t, a: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_Cdf_T(x: *const real_t, a: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_Cdfu_T(x: *const real_t, a: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_Qf_T(x: *const real_t, a: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_Pdf_F(x: *const real_t, a: *const real_t, b: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_Cdf_F(x: *const real_t, a: *const real_t, b: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_Cdfu_F(x: *const real_t, a: *const real_t, b: *const real_t, res: *real_t, real_context: *realContext_t) void;
extern fn WP34S_Qf_F(x: *const real_t, a: *const real_t, b: *const real_t, res: *real_t, real_context: *realContext_t) void;

const any_distribution = runtime.option_dist_expon or runtime.option_dist_cauch or runtime.option_dist_logis or
    runtime.option_dist_weibl or runtime.option_dist_binom or runtime.option_dist_geom or runtime.option_dist_poiss or
    runtime.option_dist_nbin or runtime.option_dist_chi2 or runtime.option_dist_t or runtime.option_dist_f;

const all39 = [4]u8{ DIST_CTX_39, DIST_CTX_39, DIST_CTX_39, DIST_CTX_39 };

fn kernels1(pdf: Kernel1, cdf: Kernel1, cdfu: Kernel1, qf: Kernel1) [4]DistributionKernel {
    return .{ .{ .one = pdf }, .{ .one = cdf }, .{ .one = cdfu }, .{ .one = qf } };
}

fn kernels2(pdf: Kernel2, cdf: Kernel2, cdfu: Kernel2, qf: Kernel2) [4]DistributionKernel {
    return .{ .{ .two = pdf }, .{ .two = cdf }, .{ .two = cdfu }, .{ .two = qf } };
}

fn regU8(reg: runtime.calcRegister_t) u8 {
    return @intCast(reg);
}

// One row per distribution, in the order of the DIST_ names. A row whose option
// is off stays zero, and its null kernel is what makes the entry do nothing.
const distributions: [DIST_COUNT]Distribution linksection(runtime.code_data_section) = blk: {
    var table: [DIST_COUNT]Distribution = @splat(.{
        .firstRegister = 0,
        .secondRegister = 0,
        .arity = 0,
        .secondFirst = 0,
        .flags = 0,
        .context = @splat(0),
        .domainRule = null,
        .kernel = @splat(.{}),
    });
    if (runtime.option_dist_expon) table[DIST_EXPON] = .{
        .firstRegister = regU8(REGISTER_R),
        .secondRegister = 0,
        .arity = 1,
        .secondFirst = 0,
        .flags = DIST_INV_NOROOT | DIST_INV_NOROOT_NAN | DIST_ERR_RETURNS,
        .context = all39,
        .domainRule = &exponentialCheckDomain,
        .kernel = kernels1(&WP34S_Pdf_Expon, &WP34S_Cdf_Expon, &WP34S_Cdfu_Expon, &WP34S_Qf_Expon),
    };
    if (runtime.option_dist_cauch) table[DIST_CAUCHY] = .{
        .firstRegister = regU8(REGISTER_M),
        .secondRegister = regU8(REGISTER_S),
        .arity = 2,
        .secondFirst = 0,
        .flags = DIST_INV_NAN_ARG | DIST_INV_NOROOT | DIST_INV_NOROOT_NAN | DIST_ERR_RETURNS,
        .context = all39,
        .domainRule = &cauchyCheckDomain,
        .kernel = kernels2(&WP34S_Pdf_Cauchy, &WP34S_Cdf_Cauchy, &WP34S_Cdfu_Cauchy, &WP34S_Qf_Cauchy),
    };
    if (runtime.option_dist_logis) table[DIST_LOGIT] = .{
        .firstRegister = regU8(REGISTER_M),
        .secondRegister = regU8(REGISTER_S),
        .arity = 2,
        .secondFirst = 0,
        .flags = DIST_INV_NAN_ARG,
        .context = all39,
        .domainRule = &logisticCheckDomain,
        .kernel = kernels2(&WP34S_Pdf_Logit, &WP34S_Cdf_Logit, &WP34S_Cdfu_Logit, &WP34S_Qf_Logit),
    };
    if (runtime.option_dist_weibl) table[DIST_WEIB] = .{
        .firstRegister = regU8(REGISTER_Q),
        .secondRegister = regU8(REGISTER_S),
        .arity = 2,
        .secondFirst = 1,
        .flags = 0,
        .context = .{ DIST_CTX_51, DIST_CTX_39, DIST_CTX_39, DIST_CTX_39 },
        .domainRule = &weibullCheckDomain,
        .kernel = kernels2(&WP34S_Pdf_Weib, &WP34S_Cdf_Weib, &WP34S_Cdfu_Weib, &WP34S_Qf_Weib),
    };
    if (runtime.option_dist_binom) table[DIST_BINOM] = .{
        .firstRegister = regU8(REGISTER_P),
        .secondRegister = regU8(REGISTER_N),
        .arity = 2,
        .secondFirst = 0,
        .flags = DIST_INV_NOROOT | DIST_INV_NOROOT_NAN | DIST_ERR_RETURNS | DIST_PDF_INTEGER_ONLY | DIST_PDF_NAN_IS_ERROR,
        .context = all39,
        .domainRule = &binomialCheckDomain,
        .kernel = kernels2(&WP34S_Pdf_Binomial, &WP34S_Cdf_Binomial, &WP34S_Cdfu_Binomial, &WP34S_Qf_Binomial),
    };
    if (runtime.option_dist_geom) table[DIST_GEOM] = .{
        .firstRegister = regU8(REGISTER_P),
        .secondRegister = 0,
        .arity = 1,
        .secondFirst = 0,
        .flags = 0,
        .context = all39,
        .domainRule = &geometricCheckDomain,
        .kernel = kernels1(&WP34S_Pdf_Geom, &WP34S_Cdf_Geom, &WP34S_Cdfu_Geom, &WP34S_Qf_Geom),
    };
    if (runtime.option_dist_poiss) table[DIST_POISSON] = .{
        .firstRegister = regU8(REGISTER_R),
        .secondRegister = 0,
        .arity = 1,
        .secondFirst = 0,
        .flags = DIST_INV_NAN_ARG | DIST_INV_REPORT_FIRST | DIST_INV_NOROOT | DIST_INV_NOROOT_NAN | DIST_ERR_RETURNS,
        .context = all39,
        .domainRule = &poissonCheckDomain,
        .kernel = kernels1(&WP34S_Pdf_Poisson, &WP34S_Cdf_Poisson, &WP34S_Cdfu_Poisson, &WP34S_Qf_Poisson),
    };
    if (runtime.option_dist_nbin) table[DIST_NEGBINOM] = .{
        .firstRegister = regU8(REGISTER_P),
        .secondRegister = regU8(REGISTER_N),
        .arity = 2,
        .secondFirst = 0,
        .flags = DIST_INV_NOROOT | DIST_INV_NOROOT_NAN | DIST_ERR_RETURNS | DIST_PDF_INTEGER_ONLY | DIST_PDF_NAN_IS_ERROR,
        .context = all39,
        .domainRule = &negativeBinomialCheckDomain,
        .kernel = kernels2(&pdf_NegBinomial, &cdf_NegBinomial, &cdfu_NegBinomial, &qf_NegBinomial),
    };
    if (runtime.option_dist_chi2) table[DIST_CHI2] = .{
        .firstRegister = regU8(REGISTER_M),
        .secondRegister = 0,
        .arity = 1,
        .secondFirst = 0,
        .flags = DIST_INV_NAN_ARG | DIST_INV_REPORT_FIRST | DIST_INV_NOROOT | DIST_INV_NOROOT_NAN | DIST_ERR_RETURNS,
        .context = all39,
        .domainRule = &chi2CheckDomain,
        .kernel = kernels1(&WP34S_Pdf_Chi2, &WP34S_Cdf_Chi2, &WP34S_Cdfu_Chi2, &WP34S_Qf_Chi2),
    };
    if (runtime.option_dist_t) table[DIST_T] = .{
        .firstRegister = regU8(REGISTER_M),
        .secondRegister = 0,
        .arity = 1,
        .secondFirst = 0,
        .flags = DIST_INV_NAN_ARG | DIST_INV_REPORT_FIRST | DIST_INV_NOROOT,
        .context = all39,
        .domainRule = &studentTCheckDomain,
        .kernel = kernels1(&WP34S_Pdf_T, &WP34S_Cdf_T, &WP34S_Cdfu_T, &WP34S_Qf_T),
    };
    if (runtime.option_dist_f) table[DIST_F] = .{
        .firstRegister = regU8(REGISTER_M),
        .secondRegister = regU8(REGISTER_N),
        .arity = 2,
        .secondFirst = 0,
        .flags = DIST_INV_NAN_ARG | DIST_INV_REPORT_FIRST | DIST_INV_NOROOT | DIST_INV_NOROOT_NAN | DIST_ERR_RETURNS,
        .context = all39,
        .domainRule = &fCheckDomain,
        .kernel = kernels2(&WP34S_Pdf_F, &WP34S_Cdf_F, &WP34S_Cdfu_F, &WP34S_Qf_F),
    };
    break :blk table;
};

fn reportArgumentOutsideZeroOne() void {
    displayDomainErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
    if (comptime runtime.extra_info_on_calc_error) {
        runtime.moreInfoOnError("In function fnDistribution:", "the argument must be 0 < x < 1", null, null);
    }
}

/// Every entry point of every distribution that takes its parameters from the
/// stat registers. param names the descriptor row and which of the four entries
/// it is, and the row's flags state what that distribution does on top of the
/// five lines they all share. A build that keeps none of the eleven has an empty
/// entry.
pub export fn fnDistribution(param: u16) callconv(.c) void {
    if (comptime !any_distribution) return;
    const d = &distributions[param >> 2];
    const which: u8 = @intCast(param & 3);
    const flags = d.flags;
    var val: real_t = undefined;
    var first: real_t = undefined;
    var second: real_t = undefined;
    var ans: real_t = undefined;

    if (d.kernel[which].one == null and d.kernel[which].two == null) {
        return;
    }
    if (!WP34S_CheckDistributionParameters(&val, d.firstRegister, &first, d.secondRegister, if (d.arity > 1) &second else null, 0, null, 0, d.domainRule.?)) {
        return;
    }

    if (which == DIST_I and (((flags & DIST_INV_NAN_ARG) != 0 and realIsNaN(&val)) or
        math_comparison_reals.realCompareLessEqual(&val, const_0()) or math_comparison_reals.realCompareGreaterEqual(&val, const_1())))
    {
        if ((flags & DIST_INV_REPORT_FIRST) != 0) {
            reportArgumentOutsideZeroOne();
            if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
                runtime.convertRealToResultRegister(runtime.const_NaN, runtime.REGISTER_X, runtime.amNone);
            }
        } else if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.convertRealToResultRegister(runtime.const_NaN, runtime.REGISTER_X, runtime.amNone);
        } else {
            reportArgumentOutsideZeroOne();
        }
        return;
    }

    const realContext: *realContext_t = switch (d.context[which]) {
        DIST_CTX_75 => &ctxtReal75,
        DIST_CTX_51 => &ctxtReal51,
        else => &ctxtReal39,
    };
    if (which == DIST_P and (flags & DIST_PDF_INTEGER_ONLY) != 0 and !math_comparison_reals.realIsAnInteger(&val)) {
        realSetZero(&ans);
    } else if (d.arity > 1) {
        const secondFirst = d.secondFirst != 0;
        d.kernel[which].two.?(&val, if (secondFirst) &second else &first, if (secondFirst) &first else &second, &ans, realContext);
    } else {
        d.kernel[which].one.?(&val, &first, &ans, realContext);
    }

    if (realIsNaN(&ans) and which == DIST_I and (flags & DIST_INV_NOROOT) != 0) {
        displayDomainErrorMessage(ERROR_NO_ROOT_FOUND, runtime.ERR_REGISTER_LINE);
        if (comptime runtime.extra_info_on_calc_error) {
            runtime.moreInfoOnError("In function fnDistribution:", "the quantile did not produce a finite result", null, null);
        }
        if ((flags & DIST_INV_NOROOT_NAN) != 0 and runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.convertRealToResultRegister(runtime.const_NaN, runtime.REGISTER_X, runtime.amNone);
        }
        if ((flags & DIST_ERR_RETURNS) != 0) {
            return;
        }
    } else if (realIsNaN(&ans) and which == DIST_P and (flags & DIST_PDF_NAN_IS_ERROR) != 0) {
        displayDomainErrorMessage(ERROR_INVALID_DISTRIBUTION_PARAM, runtime.ERR_REGISTER_LINE);
        if (comptime runtime.extra_info_on_calc_error) {
            runtime.moreInfoOnError("In function fnDistribution:", "a parameter is invalid", null, null);
        }
    } else {
        runtime.convertRealToResultRegister(&ans, runtime.REGISTER_X, runtime.amNone);
    }
    runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, -1, -1);
}

/// Whether a distribution parameter is positive and finite.
pub export fn WP34S_IsPositiveFinite(value: *align(1) const real_t) callconv(.c) bool {
    return !realIsSpecial(value) and math_comparison_reals.realCompareGreaterThan(value, const_0());
}

/// The caller's context when it is wider than the fallback, else the fallback.
pub export fn WP34S_AtLeastContext(realContext: *realContext_t, fallbackContext: *realContext_t) callconv(.c) *realContext_t {
    return if (realContext.digits > fallbackContext.digits) realContext else fallbackContext;
}

/// p75 when both incomplete-beta shapes enter the concentrated range, p51 otherwise.
pub export fn WP34S_BetaCalculationContext(a: *align(1) const real_t, b: *align(1) const real_t) callconv(.c) *realContext_t {
    var threshold: real_t = undefined;

    WP34S_SetPowerOfTen(5, &threshold);
    return if (math_comparison_reals.realCompareGreaterEqual(a, &threshold) and math_comparison_reals.realCompareGreaterEqual(b, &threshold)) &ctxtReal75 else &ctxtReal51;
}

/// Sets a real value to a power of ten.
pub export fn WP34S_SetPowerOfTen(exponent: i32, res: *align(1) real_t) callconv(.c) void {
    realSetOne(res);
    res.exponent = exponent;
}

/// Retains the strict side of a finite non-endpoint probability.
pub export fn WP34S_MarkProbability(value: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    if (realIsZero(value)) {
        realNextToward(value, const_1(), value, realContext);
    } else if (math_comparison_reals.realCompareEqual(value, const_1())) {
        realNextToward(value, const_0(), value, realContext);
    }
}

/// Retains the positive side of an underflowed finite value.
pub export fn WP34S_MarkPositive(value: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    if (realIsZero(value)) {
        realNextToward(value, const_1(), value, realContext);
    }
}

/// Whether a subtraction cancelled more than `places` decimal places.
pub export fn WP34S_HasCancellation(left: *align(1) const real_t, right: *align(1) const real_t, result: *align(1) const real_t, places: i32) callconv(.c) bool {
    if (realIsZero(left) or realIsZero(right) or realIsSpecial(result)) {
        return false;
    }
    if (realIsZero(result)) {
        return true;
    }
    const inputExponent = maxI32(realGetExponent(left), realGetExponent(right));
    return inputExponent - realGetExponent(result) > places;
}

/// Forms a probability, its complement, their logarithms and their logit without
/// endpoint cancellation: the logarithm of the smaller of the two is taken
/// directly and the other through ln(1 - p).
pub export fn WP34S_DistributionProbabilityData(probability: *align(1) const real_t, complement: *align(1) real_t, logProbability: *align(1) real_t, logComplement: *align(1) real_t, logit: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    var negative: real_t = undefined;

    realSubtract(const_1(), probability, complement, realContext);
    if (math_comparison_reals.realCompareLessEqual(probability, complement)) {
        WP34S_Ln(probability, logProbability, realContext);
        realMinus(probability, &negative, realContext);
        WP34S_Ln1P(&negative, logComplement, realContext);
    } else {
        WP34S_Ln(complement, logComplement, realContext);
        realMinus(complement, &negative, realContext);
        WP34S_Ln1P(&negative, logProbability, realContext);
    }
    realSubtract(logProbability, logComplement, logit, realContext);
}

const DEC_ROUND_UP: c_int = 1; // decContext.h rounding enum order

/// Applies real39 positive-underflow rounding to an extended positive value: a
/// value below the smallest Real34 subnormal rounds to it or to zero by the
/// rounding mode.
pub export fn WP34S_AdjustPositiveUnderflow(value: *align(1) real_t) callconv(.c) void {
    var minimum: real_t = undefined;
    var halfMinimum: real_t = undefined;
    var roundUp = false;

    WP34S_SetPowerOfTen(-6176, &minimum);
    if (!realIsZero(value) and math_comparison_reals.realCompareGreaterEqual(value, &minimum)) {
        return;
    }
    realMultiply(&minimum, const_1on2(), &halfMinimum, &ctxtReal39);
    switch (runtime.roundingModeTable[runtime.roundingMode]) {
        runtime.DEC_ROUND_HALF_EVEN, runtime.DEC_ROUND_HALF_DOWN => roundUp = !realIsZero(value) and math_comparison_reals.realCompareGreaterThan(value, &halfMinimum),
        runtime.DEC_ROUND_HALF_UP => roundUp = !realIsZero(value) and math_comparison_reals.realCompareGreaterEqual(value, &halfMinimum),
        DEC_ROUND_UP, runtime.DEC_ROUND_CEILING => roundUp = true,
        else => {},
    }
    if (roundUp) {
        realCopy(&minimum, value);
    } else {
        realSetZero(value);
    }
}

/// ln(1 + x) - x without cancellation for a small argument.
pub export fn WP34S_Log1pMinus(value: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    var term: real_t = undefined;
    var sum: real_t = undefined;
    var previous: real_t = undefined;
    var numerator: real_t = undefined;
    var denominator: real_t = undefined;

    if (!math_comparison_reals.realCompareAbsLessThan(value, const_1e_6())) {
        WP34S_Ln1P(value, res, realContext);
        realSubtract(res, value, res, realContext);
        return;
    }
    realMultiply(value, value, &term, realContext);
    realMultiply(&term, const_1on2(), &term, realContext);
    realChangeSign(&term);
    realCopy(&term, &sum);
    var index: i32 = 2;
    while (index < 100) : (index += 1) {
        realCopy(&sum, &previous);
        realMultiply(&term, value, &term, realContext);
        realChangeSign(&term);
        int32ToReal(index, &numerator);
        int32ToReal(index + 1, &denominator);
        realMultiply(&term, &numerator, &term, realContext);
        realDivide(&term, &denominator, &term, realContext);
        realAdd(&sum, &term, &sum, realContext);
        if (math_comparison_reals.realCompareEqual(&sum, &previous)) {
            break;
        }
    }
    realCopy(&sum, res);
}

// REAL_SIZE_IN_BYTES(digits) at run time, for working reals sized by the caller's context.
fn realSizeInBytesRuntime(digits: u32) usize {
    return 10 + 2 * ((((digits + 2) / 6) * 6 + 3) / 3);
}

// The working reals the reduced logarithm takes off the frame, sized for the
// caller's context. In a deep call chain under the solver they go on the heap,
// not the DM42 frame.
fn HeapReals(comptime count: usize) type {
    return struct {
        block: *anyopaque,
        size: usize,

        fn init(digits: i32) ?@This() {
            const size = realSizeInBytesRuntime(@intCast(digits));
            const block = malloc(size * count) orelse return null;
            return .{ .block = block, .size = size };
        }

        fn deinit(self: @This()) void {
            free(self.block);
        }

        fn at(self: @This(), index: usize) *align(1) real_t {
            const bytes: [*]u8 = @ptrCast(self.block);
            return @ptrCast(bytes + index * self.size);
        }
    };
}

// The natural logarithm of a value near one: repeated square roots bring it
// inside [sqrt(2)/2, sqrt(2)], and the atanh series of (z-1)/(z+1) runs at the
// caller's precision. NaN when the working reals cannot be allocated.
fn wp34sLnReduced(x: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) void {
    const reals = HeapReals(7).init(realContext.digits) orelse {
        realSetNaN(res);
        return;
    };
    defer reals.deinit();
    const divisor = reals.at(0);
    const factor = reals.at(1);
    const previous = reals.at(2);
    const square = reals.at(3);
    const sum = reals.at(4);
    const term = reals.at(5);
    const z = reals.at(6);

    realCopy(x, z);
    realSetOne(factor);
    while (math_comparison_reals.realCompareLessEqual(z, const39_root2on2()) or math_comparison_reals.realCompareGreaterEqual(z, const39_root2())) {
        realSquareRoot(z, z, realContext);
        realMultiply(factor, const_2(), factor, realContext);
    }
    realSubtract(z, const_1(), term, realContext);
    realAdd(z, const_1(), sum, realContext);
    realDivide(term, sum, term, realContext);
    realMultiply(term, term, square, realContext);
    realCopy(term, sum);
    int32ToReal(3, divisor);
    var n: i32 = 0;
    while (n < 1000) : (n += 1) {
        realMultiply(term, square, term, realContext);
        realDivide(term, divisor, z, realContext);
        realCopy(sum, previous);
        realAdd(sum, z, sum, realContext);
        if (math_comparison_reals.realCompareEqual(sum, previous)) {
            break;
        }
        realAdd(divisor, const_2(), divisor, realContext);
    }
    realMultiply(sum, factor, res, realContext);
    realMultiply(res, const_2(), res, realContext);
}

/// A natural logarithm from decimal range reduction and an atanh series, at the
/// caller's (extended) precision: the mantissa in [0.1, 1) is reduced, and the
/// decimal exponent contributes that many times ln 10.
pub export fn WP34S_LnExtended(x: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    if (math_comparison_reals.realCompareGreaterEqual(x, const_1on2()) and math_comparison_reals.realCompareLessEqual(x, const_3on2())) {
        wp34sLnReduced(x, res, realContext);
        return;
    }

    const reals = HeapReals(4).init(realContext.digits) orelse {
        realSetNaN(res);
        return;
    };
    defer reals.deinit();
    const exponent = reals.at(0);
    const logarithm = reals.at(1);
    const logTen = reals.at(2);
    const mantissa = reals.at(3);

    realCopy(x, mantissa);
    const decimalExponent: i32 = mantissa.exponent + mantissa.digits;
    mantissa.exponent = -mantissa.digits;
    wp34sLnReduced(mantissa, logarithm, realContext);
    wp34sLnReduced(const_10(), logTen, realContext);
    int32ToReal(decimalExponent, exponent);
    realFMA(exponent, logTen, logarithm, res, realContext);
}

// ===========================================================================
// Forward-circular family (reduceAngleToRange + sin/cos/tan) -> math_wp34s_trig.zig.
// These wrappers keep the exact C-ABI export symbols and delegate.
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
    wp34s_trig.reduceAngleToRange(angle, angle45, angle90, angle180, angularMode, savedContextDigits, realContext);
}

pub export fn C47_WP34S_Cvt2RadSinCosTan(an: *align(1) const real_t, angularMode: angularMode_t, sinOut: ?*align(1) real_t, cosOut: ?*align(1) real_t, tanOut: ?*align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    wp34s_trig.C47_WP34S_Cvt2RadSinCosTan(an, angularMode, sinOut, cosOut, tanOut, realContext);
}

pub export fn C47_WP34S_SinCosTanTaylor(a: *align(1) const real_t, swap: bool, sinOut: ?*align(1) real_t, cosOut: ?*align(1) real_t, tanOut: ?*align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    wp34s_trig.C47_WP34S_SinCosTanTaylor(a, swap, sinOut, cosOut, tanOut, realContext);
}

// Helper: render "1E-<d>" into the provided buffer (sprintf in the C).
pub fn formatEminusD(buf: *[16]u8, d: i32) [*:0]const u8 {
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
// Inverse-circular family (atan/atan2/asin/acos) -> math_wp34s_atan.zig.
// These wrappers keep the exact C-ABI export symbols and delegate.
// ===========================================================================
pub export fn C47_WP34S_Atan(x: *align(1) const real_t, angle: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    wp34s_atan.C47_WP34S_Atan(x, angle, realContext);
}

pub export fn C47_WP34S_Atan2(y: *align(1) const real_t, x: *align(1) const real_t, atan: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    wp34s_atan.C47_WP34S_Atan2(y, x, atan, realContext);
}

pub export fn C47_WP34S_Asin(x: *align(1) const real_t, angle: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    wp34s_atan.C47_WP34S_Asin(x, angle, realContext);
}

pub export fn C47_WP34S_Acos(x: *align(1) const real_t, angle: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    wp34s_atan.C47_WP34S_Acos(x, angle, realContext);
}

// ===========================================================================
// WP34S_LanczosSum + WP34S_Calc_Gamma_LnGamma_Lanczos (static)
// ===========================================================================
/// The real Lanczos coefficient sum: C00 + sum over k of C(k+1) / (x + offset - 28 + k).
pub export fn WP34S_LanczosSum(x: *align(1) const real_t, offset: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    var denominator: real_t = undefined;
    var term: real_t = undefined;

    realSetZero(res);
    realAdd(x, offset, &denominator, realContext);
    var index: i32 = 28;
    while (index >= 0) : (index -= 1) {
        realDivide(const75_gammaC01(@intCast(index)), &denominator, &term, realContext);
        realAdd(res, &term, res, realContext);
        realSubtract(&denominator, const_1(), &denominator, realContext);
    }
    realAdd(res, const75_gammaC00(), res, realContext);
}

fn WP34S_Calc_Gamma_LnGamma_Lanczos(xin: *align(1) const real_t, res: *align(1) real_t, calculateLnGamma: bool, realContext: *realContext_t) void {
    var r: real_t = undefined;
    var s: real_t = undefined;
    var t: real_t = undefined;
    var u: real_t = undefined;
    var v: real_t = undefined;
    var x: real_t = undefined;

    const savedContextDigits = realContext.digits;
    if (realContext.digits < 75) {
        realContext.digits = 75;
    }

    realSubtract(xin, const_1(), &x, realContext);
    WP34S_LanczosSum(&x, const_29(), &s, realContext);
    WP34S_Ln(&s, &s, realContext);

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
        math_command_wrappers.realExp(&x, &x, realContext);
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
    if (math_comparison_reals.realCompareAbsLessThan(@alignCast(xin), @alignCast(const_1e_24()))) {
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
    if (math_comparison_reals.realCompareLessEqual(@alignCast(xin), @alignCast(const_0()))) {
        reflect = true;
        realSubtract(const_1(), xin, &t, realContext); // t = 1 - xin
        if (math_comparison_reals.realIsAnInteger(&t)) {
            realSetNaN(res);
            return;
        }
    } else {
        // Fast path for positive integer args that aren't too large (<= 205).
        if (math_comparison_reals.realIsAnInteger(@alignCast(xin)) and math_comparison_reals.realCompareLessEqual(@alignCast(xin), @alignCast(const_205()))) {
            realSubtract(xin, const_1(), &x, realContext); // x = xin - 1
            realSetOne(res);
            while (math_comparison_reals.realCompareGreaterEqual(&x, @alignCast(const_2()))) {
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
        // Reduce to [-0.5, 0.5] before multiplying by pi, preserving the full distance from a pole without forming an angle close to an integer multiple of pi first.
        WP34S_Mod(xin, const_2(), &t, realContext);
        if (math_comparison_reals.realCompareGreaterThan(&t, const_1on2())) {
            if (math_comparison_reals.realCompareGreaterThan(&t, const_3on2())) {
                realSubtract(&t, const_2(), &t, realContext);
            } else {
                realSubtract(const_1(), &t, &t, realContext);
            }
        } else if (realIsNegative(&t)) {
            realMinus(&t, &x, realContext);
            if (math_comparison_reals.realCompareGreaterThan(&x, const_3on2())) {
                realAdd(&t, const_2(), &t, realContext);
            } else if (math_comparison_reals.realCompareGreaterThan(&x, const_1on2())) {
                realSubtract(const__1(), &t, &t, realContext);
            }
        }
        realMultiply(&t, const75_pi(), &t, realContext); // t = xin*pi
        wp34s_trig.C47_WP34S_SinCosTanTaylor_temp75(@ptrCast(&t), false, &x, null, null, realContext); // x = sin(xin*pi)

        if (calculateLnGamma) {
            realDivide(const75_pi(), &x, &t, realContext); // t = pi / sin(pi*xin)
            WP34S_Ln(&t, &t, realContext); // t = ln(pi / sin(pi*xin))
            realSubtract(&t, res, res, realContext); // res = ln(pi / sin(pi*xin)) - lngamma(1-xin)
        } else {
            realMultiply(&x, res, &t, realContext); // t = sin(pi*xin) * gamma(1-xin)
            realDivide(const75_pi(), &t, res, realContext); // res = pi / (sin(pi*xin)*gamma(1-xin))
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

    if (math_comparison_reals.realCompareLessEqual(@alignCast(xin), @alignCast(const_0()))) {
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
    if (math_comparison_reals.realCompareGreaterThan(&v, @alignCast(const_1on2()))) {
        expon = z.exponent + z.digits;
        z.exponent = -z.digits;
    } else {
        expon = 0;
    }

    // Range reduce the value by repeated square roots.
    while (math_comparison_reals.realCompareLessEqual(&z, @alignCast(const39_root2on2()))) {
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
    math_command_wrappers.realPower10(&t, &z, realContext); // z is the max error

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
    realMultiply(&e, if (realContext.digits > 39) const75_ln10() else const39_ln10(), &w, realContext);
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
        return math_comparison_reals.realCompareLessThan(&a, @alignCast(tol));
    }

    realSubtract(x, y, &a, realContext);
    realDivide(&a, x, &a, realContext);
    realSetPositiveSign(&a);
    return math_comparison_reals.realCompareLessThan(&a, @alignCast(tol));
}

pub export fn WP34S_AbsoluteError(x: *align(1) const real_t, y: *align(1) const real_t, tol: *align(1) const real_t, realContext: *realContext_t) callconv(.c) bool {
    var a: real_t = undefined;
    realSubtract(x, y, &a, realContext);
    return math_comparison_reals.realCompareAbsLessThan(&a, @alignCast(tol));
}

pub export fn WP34S_ComplexRelativeError(x: *const cplx_t, y: *const cplx_t, tol: *align(1) const real_t, realContext: *realContext_t) callconv(.c) bool {
    var a: cplx_t = undefined;

    if (realIsZero(&x.Real) and realIsZero(&x.Imag)) {
        math_runtime_helpers.complexMagnitude(y, &a.Real, realContext);
    } else {
        realSubtract(&x.Real, &y.Real, &a.Real, realContext);
        realSubtract(&x.Imag, &y.Imag, &a.Imag, realContext);
        math_division_cells.divComplexComplex(&a, x, &a, realContext);
        math_runtime_helpers.complexMagnitude(&a, &a.Real, realContext);
    }
    return math_comparison_reals.realCompareLessThan(&a.Real, tol);
}

pub export fn WP34S_ComplexAbsError(x: *const cplx_t, y: *const cplx_t, tol: *align(1) const real_t, realContext: *realContext_t) callconv(.c) bool {
    var r: real_t = undefined;
    var a: cplx_t = undefined;

    realSubtract(&x.Real, &y.Real, &a.Real, realContext);
    realSubtract(&x.Imag, &y.Imag, &a.Imag, realContext);
    math_runtime_helpers.complexMagnitude(&a, &r, realContext);
    return math_comparison_reals.realCompareLessThan(&r, tol);
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
        if (math_comparison_reals.realCompareAbsLessThan(@alignCast(x), @alignCast(const_1on2()))) {
            WP34S_ExpM1(x, &u, realContext); // u = e^x - 1
            realMultiply(&u, const_1on2(), &t, realContext); // t = (e^x - 1) / 2

            realAdd(&u, const_1(), &u, realContext); // u = e^x
            realDivide(&t, &u, &v, realContext); // v = (e^x - 1) / 2e^x

            realAdd(&u, const_1(), &u, realContext); // u = e^x + 1
            realMultiply(&u, &v, sinh, realContext); // sinhOut = (e^x - 1)(e^x + 1) / 2e^x
        } else {
            math_command_wrappers.realExp(@alignCast(x), &u, realContext); // u = e^x
            realDivide(const_1(), &u, &v, realContext); // v = e^-x
            realSubtract(&u, &v, sinh, realContext); // sinhOut = (e^x - e^-x)
            realMultiply(sinh, const_1on2(), sinh, realContext); // sinhOut = (e^x - e^-x)/2
        }
    }
    if (coshOut) |cosh| {
        math_command_wrappers.realExp(@alignCast(x), &u, realContext); // u = e^x
        realDivide(const_1(), &u, &v, realContext); // v = e^-x
        realAdd(&u, &v, cosh, realContext); // coshOut = (e^x + e^-x)
        realMultiply(cosh, const_1on2(), cosh, realContext); // coshOut = (e^x + e^-x)/2
    }
}

pub export fn WP34S_Tanh(x: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    const negative = realIsNegative(x);

    if (realIsNaN(x)) {
        realSetNaN(res);
    } else {
        var a: real_t = undefined;
        var b: real_t = undefined;

        realCopyAbs(x, &a);
        realAdd(&a, &a, &a, realContext);
        realSetNegativeSign(&a); // a = -2|x|
        WP34S_ExpM1(&a, &b, realContext); // b = exp(-2|x|) - 1
        realChangeSign(&b); // b = 1 - exp(-2|x|)
        realSubtract(const_2(), &b, &a, realContext); // a = 1 + exp(-2|x|)
        realDivide(&b, &a, res, realContext);
        if (negative) {
            realSetNegativeSign(res);
        }
    }
}

/// x + x^3/d or x - x^3/d of an odd function for a nonzero |x| below 1E-18, kept
/// on its side of x. Where x^3/d is below the last digit of the context the sum
/// equals x; one step from x keeps it above or below |x|, so rounding it to 34
/// digits gives the exact value rounded once. The series runs on |x| and the
/// result takes the sign of x.
pub export fn WP34S_TinyOddSeries(x: *align(1) const real_t, divisor: *align(1) const real_t, above: bool, res: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    var a: real_t = undefined;
    var t: real_t = undefined;
    var s: real_t = undefined;
    const negative = realIsNegative(x);

    realCopyAbs(x, &a);
    realMultiply(&a, &a, &t, realContext);
    realMultiply(&t, &a, &t, realContext);
    realDivide(&t, divisor, &t, realContext);
    if (above) {
        realAdd(&a, &t, &s, realContext);
    } else {
        realSubtract(&a, &t, &s, realContext);
    }
    if (math_comparison_reals.realCompareEqual(&s, &a)) {
        realNextToward(&a, if (above) const_plusInfinity() else const_0(), &s, realContext);
    }
    realCopy(&s, res);
    if (negative) {
        realSetNegativeSign(res);
    }
}

// ===========================================================================
// WP34S_ArcSinh / WP34S_ArcTanh
// ===========================================================================
// -0 for a negative zero, +0 otherwise: -1 divided by +infinity keeps the sign.
fn signedZero(negative: bool, res: *align(1) real_t, realContext: *realContext_t) void {
    if (negative) {
        realDivide(const__1(), const_plusInfinity(), res, realContext);
    } else {
        realSetZero(res);
    }
}

pub export fn WP34S_ArcSinh(x: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    var a: real_t = undefined;
    var s: real_t = undefined;
    const negative = realIsNegative(x);

    if (realIsSpecial(x)) {
        realCopy(x, res);
        return;
    }
    if (realIsZero(x)) {
        signedZero(negative, res, realContext);
        return;
    }

    realCopyAbs(x, &a);
    if (realGetExponent(&a) < -18) { // arsinh x = x - x^3/6 to 72 digits, below |x| by less than half a unit at 34 digits
        WP34S_TinyOddSeries(&a, const_6(), false, res, realContext);
        if (negative) {
            realSetNegativeSign(res);
        }
        return;
    }
    realFMA(&a, &a, const_1(), &s, realContext);
    realSquareRoot(&s, &s, realContext);
    realAdd(&s, const_1(), &s, realContext);
    realDivide(&a, &s, &s, realContext);
    realAdd(&s, const_1(), &s, realContext);
    realMultiply(&a, &s, &s, realContext);
    WP34S_Ln1P(&s, res, realContext);
    if (negative) {
        realSetNegativeSign(res);
    }
}

pub export fn WP34S_ArcTanh(x: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    var y: real_t = undefined;
    var z: real_t = undefined;
    const negative = realIsNegative(x);

    if (realIsNaN(x)) {
        realSetNaN(res);
        return;
    }
    if (realIsZero(x)) {
        signedZero(negative, res, realContext);
        return;
    }

    // (ln(1+x) - ln(1-x)) / 2, each logarithm taken from ln1p.
    WP34S_Ln1P(x, &y, realContext);
    realMinus(x, &z, realContext);
    WP34S_Ln1P(&z, &z, realContext);
    realSubtract(&y, &z, &y, realContext);
    realMultiply(&y, const_1on2(), res, realContext);
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

    if (!math_command_wrappers.realExpLimitCheck(@alignCast(x), @alignCast(res), @alignCast(const__1()))) {
        return;
    }

    math_command_wrappers.realExp(@alignCast(x), &u, realContext);
    realSubtract(&u, const_1(), &v, realContext);
    if (realIsZero(&v)) { // |x| is very little
        realCopy(x, res);
    } else if (math_comparison_reals.realCompareEqual(&v, @alignCast(const__1()))) {
        realSetNegativeOne(res);
    } else if (math_comparison_reals.realCompareAbsLessThan(@alignCast(x), @alignCast(const_1on10()))) {
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
fn WP34S_CalcComplexLnGamma_Lanczos(z: *const cplx_t, res: *cplx_t, realContext: *realContext_t) void {
    var r: cplx_t = undefined;
    var s: cplx_t = undefined;
    var t: cplx_t = undefined;
    var u: cplx_t = undefined;
    var v: cplx_t = undefined;

    const savedContextDigits = realContext.digits;
    if (realContext.digits < 75) {
        realContext.digits = 75;
    }

    realSetZero(&u.Real);
    realSetZero(&u.Imag);
    realAdd(&z.Real, const_29(), &t.Real, realContext);
    realCopy(&z.Imag, &t.Imag);
    var k: i32 = 28;
    while (k >= 0) : (k -= 1) {
        // The Lanczos coefficient lives at an align(1) offset inside the const
        // blob; copy it into an aligned local instead of @alignCast-ing the
        // blob pointer, which aborts on macOS/aarch64 (strict alignment).
        var coefficient: real_t = undefined;
        realCopy(const75_gammaC01(@intCast(k)), &coefficient);
        math_division_cells.divRealComplex(&coefficient, &t, &s, realContext);
        realSubtract(&t.Real, const_1(), &t.Real, realContext);
        realAdd(&u.Real, &s.Real, &u.Real, realContext);
        realAdd(&u.Imag, &s.Imag, &u.Imag, realContext);
    }
    realAdd(&u.Real, const75_gammaC00(), &t.Real, realContext);
    realCopy(&u.Imag, &t.Imag);
    math_ln_complex.lnComplex(&t, &s, realContext); // (s1, s2)

    realAdd(&z.Real, const_gammaR(), &r.Real, realContext);
    realCopy(&z.Imag, &r.Imag);
    math_ln_complex.lnComplex(&r, &u, realContext);

    realAdd(&z.Real, const_1on2(), &t.Real, realContext);
    realCopy(&z.Imag, &t.Imag);
    math_multiplication_cells.mulComplexComplex(&t, &u, &v, realContext);

    realSubtract(&v.Real, &r.Real, &u.Real, realContext);
    realSubtract(&v.Imag, &z.Imag, &u.Imag, realContext);

    realContext.digits = savedContextDigits;

    realAdd(&u.Real, &s.Real, &res.Real, realContext);
    realAdd(&u.Imag, &s.Imag, &res.Imag, realContext);
}

// ===========================================================================
// WP34S_ComplexGammaLnGamma (static)
// ===========================================================================
fn WP34S_ComplexGammaLnGamma(z: *const cplx_t, calculateLnGamma: bool, res: *cplx_t, realContext: *realContext_t) void {
    var sinPiZ: cplx_t = undefined;
    var t: cplx_t = undefined;
    var u: cplx_t = undefined;
    var x: cplx_t = undefined;
    var reflect: bool = false;
    var negateSin: bool = false;

    // Check for special cases
    if (realIsSpecial(&z.Real) or realIsSpecial(&z.Imag)) {
        if (realIsNaN(&z.Real) or realIsNaN(&z.Imag)) {
            realSetNaN(&res.Real);
            realSetNaN(&res.Imag);
        } else {
            if (realIsInfinite(&z.Real)) {
                if (realIsInfinite(&z.Imag) or realIsNegative(&z.Real)) {
                    realSetNaN(&res.Real);
                    realSetNaN(&res.Imag);
                } else {
                    realSetPlusInfinity(&res.Real);
                    realSetZero(&res.Imag);
                }
            } else {
                realSetZero(&res.Real);
                realSetZero(&res.Imag);
            }
        }
        return;
    }

    // Correct our argument and begin the inversion if it is negative
    if (realIsNegative(&z.Real)) {
        reflect = true;
        realSubtract(const_1(), &z.Real, &t.Real, realContext);
        if (realIsZero(&z.Imag) and math_comparison_reals.realIsAnInteger(&t.Real)) {
            realSetNaN(&res.Real);
            realSetNaN(&res.Imag);
            return;
        }
        realSubtract(&t.Real, const_1(), &x.Real, realContext);
        realMinus(&z.Imag, &x.Imag, realContext);
    } else {
        realSubtract(&z.Real, const_1(), &x.Real, realContext);
        realCopy(&z.Imag, &x.Imag);
    }

    // Sum the series
    WP34S_CalcComplexLnGamma_Lanczos(&x, res, realContext);
    if (!calculateLnGamma) {
        math_command_wrappers.expComplex(res, res, realContext);
    }

    // Finally invert if we started with a negative argument
    if (reflect) {
        // Aligned copy of the const-blob pi (same reason as the Lanczos loop
        // above): divRealComplex needs a naturally-aligned pointer.
        var piReal: real_t = undefined;
        realCopy(const39_pi(), &piReal);
        // Reduce the real component before multiplying by pi and record the parity of the removed integer, which determines the sign of both sine components.
        WP34S_Mod(&z.Real, const_2(), &t.Real, realContext);
        if (math_comparison_reals.realCompareGreaterThan(&t.Real, const_1on2())) {
            if (math_comparison_reals.realCompareGreaterThan(&t.Real, const_3on2())) {
                realSubtract(&t.Real, const_2(), &t.Real, realContext);
            } else {
                realSubtract(&t.Real, const_1(), &t.Real, realContext);
                negateSin = true;
            }
        } else if (realIsNegative(&t.Real)) {
            realMinus(&t.Real, &u.Real, realContext);
            if (math_comparison_reals.realCompareGreaterThan(&u.Real, const_3on2())) {
                realAdd(&t.Real, const_2(), &t.Real, realContext);
            } else if (math_comparison_reals.realCompareGreaterThan(&u.Real, const_1on2())) {
                realAdd(&t.Real, const_1(), &t.Real, realContext);
                negateSin = true;
            }
        }
        realMultiply(&t.Real, const39_pi(), &t.Real, realContext);
        realMultiply(&z.Imag, const39_pi(), &t.Imag, realContext);
        math_command_wrappers.sinComplex(&t, &sinPiZ, realContext);
        if (negateSin) {
            realMinus(&sinPiZ.Real, &sinPiZ.Real, realContext);
            realMinus(&sinPiZ.Imag, &sinPiZ.Imag, realContext);
        }
        if (!calculateLnGamma) {
            math_multiplication_cells.mulComplexComplex(&sinPiZ, res, &u, realContext);
            math_division_cells.divRealComplex(&piReal, &u, res, realContext);
        } else {
            math_division_cells.divRealComplex(&piReal, &sinPiZ, &u, realContext);
            math_ln_complex.lnComplex(&u, &t, realContext);
            realSubtract(&t.Real, &res.Real, &res.Real, realContext);
            realSubtract(&t.Imag, &res.Imag, &res.Imag, realContext);
        }
    }
}

pub export fn WP34S_ComplexGamma(zin: *const cplx_t, res: *cplx_t, realContext: *realContext_t) callconv(.c) void {
    var z: cplx_t = undefined;

    realCopy(&zin.Real, &z.Real);
    realCopy(&zin.Imag, &z.Imag);
    WP34S_ComplexGammaLnGamma(&z, false, res, realContext);
}

pub export fn WP34S_ComplexLnGamma(zin: *const cplx_t, res: *cplx_t, realContext: *realContext_t) callconv(.c) void {
    var z: cplx_t = undefined;

    realCopy(&zin.Real, &z.Real);
    realCopy(&zin.Imag, &z.Imag);
    WP34S_ComplexGammaLnGamma(&z, true, res, realContext);
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

/// The exact truncated remainder of two finite real34 values, with 68-digit
/// modular arithmetic: the divisor's power of ten is applied by repeated squaring
/// of 10 mod |y| rather than by forming the shifted dividend.
pub export fn WP34S_Real34Remainder(x: *align(1) const real_t, y: *align(1) const real_t, res: *align(1) real_t) callconv(.c) void {
    var a_buf: BigReal(34) = .{};
    var b_buf: BigReal(34) = .{};
    var comparison_buf: BigReal(1) = .{};
    var factor_buf: BigReal(34) = .{};
    var product_buf: BigReal(68) = .{};
    var remainder_buf: BigReal(34) = .{};
    const a = a_buf.ptr();
    const b = b_buf.ptr();
    const comparison = comparison_buf.ptr();
    const factor = factor_buf.ptr();
    const product = product_buf.ptr();
    const remainder = remainder_buf.ptr();
    var c: realContext_t = ctxtReal75;

    if (realIsSpecial(x) or realIsSpecial(y) or realIsZero(y)) {
        c.digits = 39;
        realDivideRemainder(x, y, res, &c);
        return;
    }

    realCopyAbs(x, a);
    realCopyAbs(y, b);
    realCompare(a, b, comparison, &c);
    if (realIsNegative(comparison)) {
        realCopy(x, res);
        return;
    }

    c.digits = 68;
    const exponentA = a.exponent;
    const exponentB = b.exponent;
    a.exponent = 0;
    b.exponent = 0;

    if (exponentA < exponentB) {
        b.exponent = exponentB - exponentA;
        realDivideRemainder(a, b, remainder, &c);
        remainder.exponent += exponentA;
    } else {
        var shift: i32 = exponentA - exponentB;
        realDivideRemainder(a, b, remainder, &c);
        realDivideRemainder(const_10(), b, factor, &c);

        while (shift != 0) {
            if ((shift & 1) != 0) {
                realMultiply(remainder, factor, product, &c);
                realDivideRemainder(product, b, remainder, &c);
            }
            shift >>= 1;
            if (shift != 0) {
                realMultiply(factor, factor, product, &c);
                realDivideRemainder(product, b, factor, &c);
            }
        }
        remainder.exponent += exponentB;
    }

    if (realIsNegative(x)) {
        realSetNegativeSign(remainder);
    }
    realCopy(remainder, res);
}

// Both buffers come off the heap: at 2139 and 12321 digits they are far past
// what the DM42 program stack grants, and a failed allocation has to say so
// rather than compute through a buffer that is not there.
pub export fn WP34S_Mod(x: *align(1) const real_t, y: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    if (runtime.wp34s_mod_small_buffers) {
        const small = mallocBigReal(2139);
        defer freeBigReal(small);
        if (small) |buf| {
            doMod(x, y, res, realContext, 2139, buf);
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE);
            realSetNaN(res);
        }
    } else {
        const temp = mallocBigReal(12321);
        defer freeBigReal(temp);
        if (temp) |buf| {
            doMod(x, y, res, realContext, 6147, buf);
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE);
            realSetNaN(res);
        }
    }
}

// Same buffer sizes as WP34S_Mod, taken the same way. This is the one mod2Pi calls.
pub export fn WP34S_BigMod(x: *align(1) const real_t, y: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    if (runtime.wp34s_mod_small_buffers) {
        const small = mallocBigReal(2139);
        defer freeBigReal(small);
        if (small) |buf| {
            doMod(x, y, res, realContext, 2139, buf);
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE);
            realSetNaN(res);
        }
    } else {
        const temp = mallocBigReal(12321);
        defer freeBigReal(temp);
        if (temp) |buf| {
            doMod(x, y, res, realContext, 12321, buf);
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE);
            realSetNaN(res);
        }
    }
}

pub export fn mod2Pi(x: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    WP34S_BigMod(x, radianReduction2Pi(), res, realContext);
}

// ===========================================================================
// The large-shape incomplete gamma: Temme's uniform expansion, its coefficients
// in eight tables of the constant blob (const39_igammaC0_00 .. C7_12).
// ===========================================================================
const igamma_table_lengths = [8]u32{ 31, 29, 27, 25, 23, 17, 15, 13 };

fn igammaTemmePolynomial(table: u32, z: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) void {
    var coefficient: real_t = undefined;
    const count = igamma_table_lengths[table];

    realCopy(consts.igammaC39(table, count - 1), res);
    var i: i32 = @as(i32, @intCast(count)) - 2;
    while (i >= 0) : (i -= 1) {
        realCopy(consts.igammaC39(table, @intCast(i)), &coefficient);
        realFMA(res, z, &coefficient, res, realContext);
    }
}

fn igammaTemmePhi(sigma: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) void {
    var factor: real_t = undefined;
    var nReal: real_t = undefined;
    var nPlusOne: real_t = undefined;
    var previous: real_t = undefined;
    var term: real_t = undefined;

    realMultiply(sigma, sigma, &term, realContext);
    realDivide(&term, const_2(), &term, realContext);
    realCopy(&term, res);
    realMinus(sigma, &factor, realContext);
    var n: i32 = 2;
    while (n < 1000) : (n += 1) {
        realMultiply(&term, &factor, &term, realContext);
        int32ToReal(n, &nReal);
        realMultiply(&term, &nReal, &term, realContext);
        int32ToReal(n + 1, &nPlusOne);
        realDivide(&term, &nPlusOne, &term, realContext);
        realCopy(res, &previous);
        realAdd(res, &term, res, realContext);
        if (math_comparison_reals.realCompareEqual(res, &previous)) {
            break;
        }
    }
}

fn igammaTemmeTail(a: *align(1) const real_t, x: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) void {
    var correction: real_t = undefined;
    var exponential: real_t = undefined;
    var inverseA: real_t = undefined;
    var phi: real_t = undefined;
    var scale: real_t = undefined;
    var sigma: real_t = undefined;
    var workspace: [8]real_t = undefined;
    var y: real_t = undefined;
    var z: real_t = undefined;

    realSubtract(x, a, &sigma, realContext);
    realDivide(&sigma, a, &sigma, realContext);
    igammaTemmePhi(&sigma, &phi, realContext);
    realMultiply(a, &phi, &y, realContext);
    realMultiply(&phi, const_2(), &z, realContext);
    realSquareRoot(&z, &z, realContext);
    if (math_comparison_reals.realCompareLessThan(x, a)) {
        realChangeSign(&z);
    }

    for (&workspace, 0..) |*w, table| {
        igammaTemmePolynomial(@intCast(table), &z, w, realContext);
    }

    realDivide(const_1(), a, &inverseA, realContext);
    realCopy(&workspace[7], &correction);
    var i: usize = 7;
    while (i > 0) {
        i -= 1;
        realFMA(&correction, &inverseA, &workspace[i], &correction, realContext);
    }
    realMinus(&y, &exponential, realContext);
    realExp(&exponential, &exponential, realContext);
    realMultiply(&correction, &exponential, &correction, realContext);
    realMultiply(const39_2pi(), a, &scale, realContext);
    realSquareRoot(&scale, &scale, realContext);
    realDivide(&correction, &scale, &correction, realContext);
    if (math_comparison_reals.realCompareLessThan(x, a)) {
        realChangeSign(&correction);
    }

    // Q(1/2,y) is erfc(sqrt(y)); this recursive call cannot select the large-shape expansion.
    WP34S_GammaP(&y, const_1on2(), res, realContext, true, true);
    realDivide(res, const_2(), res, realContext);
    realAdd(res, &correction, res, realContext);
}

// ===========================================================================
// gser / gcheckSmall / gcf / gserUpper (static) + WP34S_GammaP
// ===========================================================================
fn gser(a: *align(1) const real_t, x: *align(1) const real_t, gln: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) void {
    var ap: real_t = undefined;
    var del: real_t = undefined;
    var sum: real_t = undefined;
    var t: real_t = undefined;
    var u: real_t = undefined;

    if (math_comparison_reals.realCompareLessEqual(@alignCast(x), @alignCast(const_0()))) {
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
        if (math_comparison_reals.realCompareEqual(&sum, &t)) {
            break;
        }
        realCopy(&t, &sum);
    }
    WP34S_Ln(x, &t, realContext);
    realMultiply(&t, a, &u, realContext);
    realSubtract(&u, x, &t, realContext);
    realSubtract(&t, gln, &u, realContext);
    math_command_wrappers.realExp(&u, &t, realContext);
    realMultiply(&sum, &t, res, realContext);
    return;
}

fn gcheckSmall(v: *align(1) real_t, realContext: *realContext_t) void {
    _ = realContext;
    if (math_comparison_reals.realCompareAbsLessThan(@alignCast(v), @alignCast(const_1e_10000()))) {
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
        if (math_comparison_reals.realCompareEqual(&u, &h)) {
            break;
        }
        realCopy(&u, &h);
    }
    WP34S_Ln(x, &t, realContext);
    realMultiply(&t, a, &u, realContext);
    realSubtract(&u, x, &t, realContext);
    realSubtract(&t, gln, &u, realContext);
    math_command_wrappers.realExp(&u, &t, realContext);
    realMultiply(&t, &h, res, realContext);
    return;
}

// The upper incomplete gamma for a small shape and argument, a <= 1 and x <= 1:
// Gamma(a) - gamma(a, x) as (Gamma(1+a)/a - x^a/a) plus the alternating series
// of the remainder, so the difference of two nearly equal values is formed from
// expm1 rather than by subtraction.
fn gserUpper(a: *align(1) const real_t, x: *align(1) const real_t, lga: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t, regularised: bool) void {
    var ap: real_t = undefined;
    var difference: real_t = undefined;
    var divisor: real_t = undefined;
    var logPower: real_t = undefined;
    var logX: real_t = undefined;
    var power: real_t = undefined;
    var previous: real_t = undefined;
    var ratio: real_t = undefined;
    var scale: real_t = undefined;
    var series: real_t = undefined;
    var term: real_t = undefined;

    WP34S_Ln(x, &logX, realContext);
    realAdd(a, const_1(), &ap, &ctxtReal75);
    if (math_comparison_reals.realCompareLessEqual(a, const_1e_37())) {
        realMinus(const39_egamma(), &ratio, realContext);
    } else {
        WP34S_LnGamma(&ap, &ratio, &ctxtReal75);
        realDivide(&ratio, a, &ratio, realContext);
    }
    realSubtract(&ratio, &logX, &difference, realContext);
    realMultiply(a, &difference, &difference, realContext);
    WP34S_ExpM1(&difference, &difference, realContext);
    realDivide(&difference, a, &difference, realContext);

    realDivide(x, &ap, &term, realContext);
    realCopy(&term, &series);
    var n: i32 = 1;
    while (n < 1000) : (n += 1) {
        realMultiply(&term, x, &term, realContext);
        realChangeSign(&term);
        realMultiply(&term, &ap, &term, realContext);
        int32ToReal(n + 1, &divisor);
        realDivide(&term, &divisor, &term, realContext);
        realAdd(&ap, const_1(), &ap, realContext);
        realDivide(&term, &ap, &term, realContext);
        realCopy(&series, &previous);
        realAdd(&series, &term, &series, realContext);
        if (math_comparison_reals.realCompareEqual(&series, &previous)) {
            break;
        }
    }
    realAdd(&difference, &series, &series, realContext);
    realMultiply(a, &logX, &logPower, realContext);
    realExp(&logPower, &power, realContext);
    realMultiply(&power, &series, res, realContext);
    if (regularised) {
        realMinus(lga, &scale, realContext);
        realExp(&scale, &scale, realContext);
        realMultiply(res, &scale, res, realContext);
    }
}

pub export fn WP34S_GammaP(x: *align(1) const real_t, a: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t, upper: bool, regularised: bool) callconv(.c) void {
    var lga: real_t = undefined;
    var sigma: real_t = undefined;
    var threshold: real_t = undefined;
    var z: real_t = undefined;

    if (realIsNegative(x) or math_comparison_reals.realCompareLessEqual(@alignCast(a), @alignCast(const_0())) or realIsNaN(x) or realIsNaN(a) or realIsInfinite(a)) {
        realSetNaN(res);
        return;
    }

    if (realIsInfinite(x)) {
        if (upper) {
            realSetZero(res);
            return;
        }

        if (regularised) {
            realSetOne(res);
            return;
        }
        WP34S_Gamma(a, res, realContext);
        return;
    }

    // A large shape near the centre, or far enough out that the series and the
    // continued fraction both fail to converge, takes Temme's expansion.
    if (math_comparison_reals.realCompareGreaterEqual(a, const_9000())) {
        realSubtract(x, a, &sigma, realContext);
        realDivide(&sigma, a, &sigma, realContext);
        realMultiply(&sigma, &sigma, &sigma, realContext);
        realDivide(const_200(), a, &threshold, realContext);
        const centralTransition = math_comparison_reals.realCompareLessThan(&sigma, &threshold);
        if (centralTransition or math_comparison_reals.realCompareLessEqual(&sigma, const_1on40000())) {
            if (!regularised) {
                realSetPlusInfinity(res);
                return;
            }
            const savedContextDigits = realContext.digits;
            if (!centralTransition and savedContextDigits < 51) {
                realContext.digits = 51;
            }
            igammaTemmeTail(a, x, res, realContext);
            realContext.digits = savedContextDigits;
            if (upper != math_comparison_reals.realCompareGreaterEqual(x, a)) {
                realSubtract(const_1(), res, res, realContext);
            }
            return;
        }
    }

    realAdd(a, const_1(), &lga, realContext);
    realCompare(x, &lga, &z, realContext);
    if (regularised) {
        WP34S_LnGamma(a, &lga, realContext);
    } else {
        realSetZero(&lga);
    }
    if (upper and !realIsZero(x) and math_comparison_reals.realCompareLessEqual(x, const_1()) and math_comparison_reals.realCompareLessEqual(a, const_1())) {
        gserUpper(a, x, &lga, res, realContext, regularised);
        return;
    }

    var use_cf: bool = false;
    if (realIsNegative(&z)) {
        // Deal with a difficult case by using the other expansion
        if (math_comparison_reals.realCompareGreaterThan(@alignCast(a), @alignCast(const_9000()))) {
            realCopy(const_995on1000(), &z);
            realMultiply(a, &z, &z, realContext);
            if (math_comparison_reals.realCompareGreaterThan(@alignCast(x), &z)) {
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
// erf x = 2x/sqrt(pi) * sum of (-x^2)^n / (n! (2n+1)), for |x| below 1/10.
fn erfSeries(x: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) void {
    var square: real_t = undefined;
    var term: real_t = undefined;
    var sum: real_t = undefined;
    var previous: real_t = undefined;
    var numerator: real_t = undefined;
    var denominator: real_t = undefined;
    var rootPi: real_t = undefined;
    const pi = if (realContext.digits > 39) const75_pi() else const39_pi();

    realMultiply(x, x, &square, realContext);
    realChangeSign(&square);
    realSetOne(&term);
    realSetOne(&sum);
    var n: i32 = 1;
    while (n < 1000) : (n += 1) {
        realMultiply(&term, &square, &term, realContext);
        int32ToReal(2 * n - 1, &numerator);
        realMultiply(&term, &numerator, &term, realContext);
        int32ToReal(n * (2 * n + 1), &denominator);
        realDivide(&term, &denominator, &term, realContext);
        realCopy(&sum, &previous);
        realAdd(&sum, &term, &sum, realContext);
        if (math_comparison_reals.realCompareEqual(&sum, &previous)) {
            break;
        }
    }
    realMultiply(x, &sum, res, realContext);
    realMultiply(res, const_2(), res, realContext);
    realSquareRoot(pi, &rootPi, realContext);
    realDivide(res, &rootPi, res, realContext);
}

// erf and erfc were embedded library functions on WP 34S
pub export fn WP34S_Erf(x: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    var p: real_t = undefined;
    var q: real_t = undefined;
    const pi = if (realContext.digits > 39) const75_pi() else const39_pi();

    if (realIsNaN(x)) {
        realCopy(x, res);
        return;
    }

    if (realIsInfinite(x)) {
        int32ToReal(if (realIsNegative(x)) -1 else 1, res);
        return;
    }

    if (realIsZero(x)) {
        signedZero(realIsNegative(x), res, realContext);
        return;
    }

    const negative = realIsNegative(x);
    if (math_comparison_reals.realCompareAbsLessThan(x, const_1on10())) {
        erfSeries(x, res, realContext);
    } else {
        realMultiply(x, x, &p, realContext);
        WP34S_GammaP(&p, const_1on2(), &p, realContext, false, false);
        realSquareRoot(pi, &q, realContext);
        realDivide(&p, &q, res, realContext);
        if (negative) {
            realChangeSign(res);
        }
    }
    // |erf x| stays below one for a finite x.
    if (math_comparison_reals.realCompareAbsEqual(res, const_1())) {
        realNextToward(res, const_0(), res, realContext);
    }
}

/// erfc x, from the upper incomplete gamma for |x| at or above 1/10 and from
/// 1 - erf x below. Gated on OPTION_DIST_NORML, part of the normal-distribution
/// build option; without it the symbol survives as an empty function.
pub export fn WP34S_Erfc(x: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    if (comptime !runtime.option_dist_norml) return;
    var p: real_t = undefined;
    var q: real_t = undefined;
    const pi = if (realContext.digits > 39) const75_pi() else const39_pi();

    if (realIsNaN(x)) {
        realCopy(x, res);
        return;
    }
    if (realIsInfinite(x)) {
        realCopy(if (realIsNegative(x)) const_2() else const_0(), res);
        return;
    }
    if (realIsZero(x)) {
        realSetOne(res);
        return;
    }

    const negative = realIsNegative(x);
    if (math_comparison_reals.realCompareAbsLessThan(x, const_1on10())) {
        WP34S_Erf(x, &p, realContext);
        realSubtract(const_1(), &p, res, realContext);
        if (math_comparison_reals.realCompareEqual(res, const_1())) {
            realNextToward(res, if (negative) const_2() else const_0(), res, realContext);
        }
        return;
    }

    realMultiply(x, x, &p, realContext);
    WP34S_GammaP(&p, const_1on2(), &p, realContext, true, false);
    realSquareRoot(pi, &q, realContext);
    realDivide(&p, &q, &p, realContext);
    if (negative) {
        realSubtract(const_2(), &p, res, realContext);
        if (math_comparison_reals.realCompareEqual(res, const_2())) {
            realNextToward(res, const_0(), res, realContext);
        }
    } else {
        realCopy(&p, res);
        if (realIsZero(res)) {
            realNextToward(res, const_1(), res, realContext);
        }
    }
}

// ===========================================================================
// betaFractionCheckScale / betaFractionStep (static) + WP34S_BetaFraction
// ===========================================================================
fn betaFractionCheckScale(value: *align(1) real_t) void {
    if (math_comparison_reals.realCompareAbsLessThan(value, const_1e_10000())) {
        const negative = realIsNegative(value);
        realCopy(const_1e_10000(), value);
        if (negative) {
            realSetNegativeSign(value);
        }
    }
}

fn betaFractionStep(coefficient: *align(1) const real_t, d: *align(1) real_t, c: *align(1) real_t, realContext: *realContext_t) void {
    var term: real_t = undefined;
    var value: real_t = undefined;

    realFMA(coefficient, d, const_1(), &value, realContext);
    betaFractionCheckScale(&value);
    realDivide(const_1(), &value, d, realContext);
    realDivide(coefficient, c, &term, realContext);
    realAdd(&term, const_1(), c, realContext);
    betaFractionCheckScale(c);
}

/// Evaluates an incomplete-beta continued fraction by the modified Lentz method;
/// true when it converges to the relative exponent within iterationMax steps.
pub export fn WP34S_BetaFraction(a: *align(1) const real_t, b: *align(1) const real_t, x: *align(1) const real_t, convergenceExponent: i32, iterationMax: i32, res: *align(1) real_t, realContext: *realContext_t) callconv(.c) bool {
    var coefficient: real_t = undefined;
    var c: real_t = undefined;
    var d: real_t = undefined;
    var ab: real_t = undefined;
    var am1: real_t = undefined;
    var ap1: real_t = undefined;
    var m: real_t = undefined;
    var twiceM: real_t = undefined;
    var old: real_t = undefined;
    var term: real_t = undefined;
    var tolerance: real_t = undefined;
    var u: real_t = undefined;
    var v: real_t = undefined;
    var w: real_t = undefined;
    var monitor: i32 = 0;

    realAdd(a, const_1(), &ap1, realContext);
    realSubtract(a, const_1(), &am1, realContext);
    realAdd(a, b, &ab, realContext);
    realSetOne(&c);
    realDivide(x, &ap1, &term, realContext);
    realFMA(&term, &ab, const__1(), &term, realContext);
    realChangeSign(&term);
    betaFractionCheckScale(&term);
    realDivide(const_1(), &term, &d, realContext);
    realCopy(&d, res);
    realSetZero(&m);
    realSetOne(&tolerance);
    tolerance.exponent = convergenceExponent;

    var index: i32 = 0;
    while (index < iterationMax) : (index += 1) {
        realCopy(res, &old);
        realAdd(&m, const_1(), &m, realContext);
        realMultiply(&m, const_2(), &twiceM, realContext);

        realSubtract(b, &m, &term, realContext);
        realMultiply(&term, &m, &u, realContext);
        realMultiply(&u, x, &term, realContext);
        realAdd(&am1, &twiceM, &u, realContext);
        realAdd(a, &twiceM, &v, realContext);
        realMultiply(&u, &v, &w, realContext);
        realDivide(&term, &w, &coefficient, realContext);
        betaFractionStep(&coefficient, &d, &c, realContext);
        realMultiply(res, &d, &term, realContext);
        realMultiply(&term, &c, res, realContext);

        realAdd(a, &m, &term, realContext);
        realAdd(&ab, &m, &u, realContext);
        realMultiply(&term, &u, &w, realContext);
        realMultiply(&w, x, &w, realContext);
        realChangeSign(&w);
        realAdd(a, &twiceM, &term, realContext);
        realAdd(&ap1, &twiceM, &u, realContext);
        realMultiply(&term, &u, &v, realContext);
        realDivide(&w, &v, &coefficient, realContext);
        betaFractionStep(&coefficient, &d, &c, realContext);
        realMultiply(&d, &c, &term, realContext);
        realMultiply(res, &term, res, realContext);

        if (math_comparison_reals.realCompareEqual(&old, res) or WP34S_RelativeError(&old, res, &tolerance, realContext)) {
            return true;
        }
        if (monitorExit(&monitor, "Iter: ")) {
            return false;
        }
    }
    return false;
}

// ===========================================================================
// check_low / ib_step / betacf (static) + WP34S_betai
// ===========================================================================
fn check_low(d: *align(1) real_t) void {
    var real_1e_32: real_t = undefined;

    realSetOne(&real_1e_32);
    real_1e_32.exponent -= 32;
    if (math_comparison_reals.realCompareAbsLessThan(@alignCast(d), &real_1e_32)) {
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
        if (math_comparison_reals.realCompareEqual(&oldr, @alignCast(r))) {
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
        math_lnbeta.LnBeta(@alignCast(a), @alignCast(b), &u, realContext);
        WP34S_Ln(x, &v, realContext); // v = ln(x)
        realMultiply(a, &v, &t, realContext);
        realSubtract(&t, &u, &v, realContext); // v = lng(...)+a.ln(x)
        realSubtract(const_1(), x, &y, realContext); // y = 1-x
        WP34S_Ln(&y, &u, realContext); // u = ln(1-x)
        realMultiply(&u, b, &t, realContext);
        realAdd(&t, &v, &u, realContext); // u = lng(...)+a.ln(x)+b.ln(1-x)
        math_command_wrappers.realExp(&u, &w, realContext);
    }

    realAdd(a, b, &v, realContext);
    realAdd(&v, const_2(), &u, realContext); // u = a+b+2
    realAdd(a, const_1(), &t, realContext); // t = a+1
    realDivide(&t, &u, &v, realContext); // u = (a+1)/(a+b+2)
    if (math_comparison_reals.realCompareLessThan(@alignCast(x), &v)) {
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

    if ((!math_comparison_reals.realIsAnInteger(@alignCast(x))) or math_comparison_reals.realCompareLessThan(@alignCast(x), @alignCast(const_0()))) {
        realSetNaN(res);
        return;
    }
    if (realIsZero(x)) { // Bn_0
        realCopy(const_1(), res);
        return;
    }
    if (!bn_star) {
        if (math_comparison_reals.realCompareEqual(@alignCast(x), @alignCast(const_1()))) { // zeta_0
            realCopy(const_1on2(), res);
            realChangeSign(res);
            return;
        } else {
            realMultiply(x, const_1on2(), &p, realContext);
            if (!math_comparison_reals.realIsAnInteger(&p)) { // Bn_odd
                realSetZero(res);
                return;
            }
        }
        realCopy(x, &p);
    } else {
        realMultiply(x, const_2(), &p, realContext);
    }

    // An index past the context's digits has no representable zeta at 1 - p.
    if (realGetExponent(&p) >= realContext.digits) {
        realSetNaN(res);
        return;
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
        if (!math_comparison_reals.realCompareGreaterThan(&reg0, @alignCast(const_0()))) {
            break;
        }
    }
    realDivide(&p, &reg5, &p, realContext);
    realSubtract(const_1(), reg1, &r, realContext);
    realMultiply(if (realContext.digits > 39) const75_ln2() else const39_ln2(), &r, &r, realContext);
    WP34S_ExpM1(&r, &q, realContext);
    realDivide(&p, &q, res, realContext);
}

pub export fn WP34S_Zeta(x: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    var p: real_t = undefined;
    var q: real_t = undefined;
    var r: real_t = undefined;
    var reg1: real_t = undefined;
    var reg7: real_t = undefined;
    const pi = if (realContext.digits > 39) const75_pi() else const39_pi();
    const twoPi = if (realContext.digits > 39) const75_2pi() else const39_2pi();

    if (realIsZero(x)) {
        realCopy(const_1on2(), res);
        realChangeSign(res);
        return;
    }
    if (math_comparison_reals.realCompareEqual(x, const_1())) {
        realSetPlusInfinity(res);
        return;
    }
    if (realIsNegative(x) and math_comparison_reals.realIsAnInteger(@alignCast(x))) { // the trivial zeros at the negative even integers
        realMultiply(x, const_1on2(), &p, realContext);
        if (math_comparison_reals.realIsAnInteger(&p)) {
            realSetZero(res);
            return;
        }
    }

    // zeta_int
    realCopy(x, &reg1);
    realCopy(x, &reg7);
    if (math_comparison_reals.realCompareGreaterThan(@alignCast(x), @alignCast(const_1on2()))) {
        zeta_calc(x, &reg1, &reg7, res, realContext);
    } else { // zeta_neg
        realSubtract(const_1(), x, &q, realContext);
        realCopy(&q, &reg1);
        zeta_calc(&q, &reg1, &reg7, &p, realContext);
        C47_WP34S_Asin(const_1(), &q, realContext);
        realMultiply(&q, &reg7, &q, realContext);
        C47_WP34S_Cvt2RadSinCosTan(&q, amRadian, &r, null, null, realContext);
        realMultiply(&p, &r, &p, realContext);
        realDivide(&p, pi, &p, realContext);
        realPower(twoPi, &reg7, &q, realContext);
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
    var e: real_t = undefined;
    var p: real_t = undefined;
    var q: real_t = undefined;
    var r: real_t = undefined;
    var reg0: real_t = undefined;
    var reg1: real_t = undefined;
    var reg2: real_t = undefined;
    var converged: bool = false;
    const tolerance = if (realContext.digits <= 39) const_1e_37() else const_1e_49();

    if (realIsNaN(x)) {
        realSetNaN(res);
        return;
    }
    if (realIsInfinite(x)) {
        if (!negativeBranch and realIsPositive(x)) {
            realSetPlusInfinity(res);
        } else {
            realSetNaN(res);
        }
        return;
    }
    if (realIsZero(x)) {
        if (negativeBranch) {
            realSetMinusInfinity(res);
        } else {
            realCopy(x, res);
        }
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
    if (math_comparison_reals.realCompareLessEqual(&reg0, &p)) {
        realExp(const_1(), &e, realContext);
        realMultiply(&reg0, &e, &q, realContext);
        realAdd(&q, const_1(), &q, realContext);
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
            realMultiply(&p, &e, &p, realContext);
            realSubtract(&p, &q, &p, realContext);
            realAdd(&p, &reg2, &p, realContext);
            realDivide(&p, &q, &p, realContext);
            realAdd(&p, &q, &p, realContext);
            if (converged) {
                break;
            }
            if (WP34S_AbsoluteError(&p, &q, tolerance, realContext)) {
                converged = true;
            }
            realSubtract(&reg1, const_1(), &reg1, realContext);
            realCopy(&p, &q);
            if (!math_comparison_reals.realCompareGreaterThan(&reg1, @alignCast(const_0()))) {
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
            if (math_comparison_reals.realCompareGreaterThan(&q, @alignCast(const_1()))) {
                WP34S_Ln(&q, &r, realContext);
                realSubtract(&q, &r, &q, realContext);
            }
        }
        // Newton-Halley iteration for W
        while (true) { // LamW0_halley
            math_command_wrappers.realExp(&q, &r, realContext);
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
            if (WP34S_RelativeError(&r, &q, tolerance, realContext)) {
                converged = true;
            }
            realSubtract(&reg1, const_1(), &reg1, realContext);
            realCopy(&r, &q);
            if (!math_comparison_reals.realCompareGreaterThan(&reg1, @alignCast(const_0()))) {
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
pub export fn WP34S_ComplexLambertW(x: *const cplx_t, res: *cplx_t, realContext: *realContext_t) callconv(.c) void {
    var d: real_t = undefined;
    var dPrev: real_t = undefined;
    var p: cplx_t = undefined;
    var q: cplx_t = undefined;
    var z: cplx_t = undefined;
    var w: cplx_t = undefined;
    var t: cplx_t = undefined;
    var delta: cplx_t = undefined;
    const piConstant = if (realContext.digits <= 39) const39_pi() else const75_pi();
    const piOn2Constant = if (realContext.digits <= 39) const39_piOn2() else const75_piOn2();
    const tolerance = const_1e_37();
    const negativeImaginarySide = realIsNegative(&x.Imag);
    var iteration: i32 = 0;
    var flat: i32 = 0;

    if (realIsNaN(&x.Real) or realIsNaN(&x.Imag) or (realIsInfinite(&x.Real) and realIsInfinite(&x.Imag))) {
        realSetNaN(&res.Real);
        realSetNaN(&res.Imag);
        return;
    }
    if (realIsInfinite(&x.Real)) {
        realSetPlusInfinity(&res.Real);
        if (realIsPositive(&x.Real)) {
            realSetZero(&res.Imag);
        } else {
            realCopy(piConstant, &res.Imag);
        }
        if (negativeImaginarySide) {
            realSetNegativeSign(&res.Imag);
        }
        return;
    }
    if (realIsInfinite(&x.Imag)) {
        realSetPlusInfinity(&res.Real);
        realCopy(piOn2Constant, &res.Imag);
        if (negativeImaginarySide) {
            realSetNegativeSign(&res.Imag);
        }
        return;
    }
    if (realIsZero(&x.Real) and realIsZero(&x.Imag)) {
        realCopy(&x.Real, &res.Real);
        realCopy(&x.Imag, &res.Imag);
        return;
    }

    realCopy(&x.Real, &z.Real);
    realCopy(&x.Imag, &z.Imag);
    realSetOne(&w.Real);
    realSetOne(&w.Imag);
    realAdd(&x.Real, const_1(), &p.Real, realContext);
    realCopy(&x.Imag, &p.Imag);
    if (realIsZero(&z.Imag) and realIsNegative(&z.Real) and math_comparison_reals.realCompareGreaterEqual(&z.Real, const__1())) {
        // Close to -1/e, the series is very slow to converge
        realSetOne(&p.Real);
        realCopy(if (negativeImaginarySide) const__1() else const_1(), &p.Imag);
    } else if (!realIsZero(&p.Real) or !realIsZero(&p.Imag)) {
        math_ln_complex.lnComplex(&p, &p, realContext);
        realCopy(&p.Real, &w.Real);
        realCopy(&p.Imag, &w.Imag);
    }
    realCopy(const_plusInfinity(), &dPrev);
    while (true) { // LamW_cloop
        if (monitorExit(&iteration, "Iter: ")) {
            break;
        }

        math_command_wrappers.expComplex(&p, &q, realContext);
        realCopy(&q.Real, &t.Real);
        realCopy(&q.Imag, &t.Imag);
        math_multiplication_cells.mulComplexComplex(&q, &w, &q, realContext);
        realAdd(&t.Real, &q.Real, &t.Real, realContext);
        realAdd(&t.Imag, &q.Imag, &t.Imag, realContext);
        realSubtract(&q.Real, &z.Real, &q.Real, realContext);
        realSubtract(&q.Imag, &z.Imag, &q.Imag, realContext);
        math_division_cells.divComplexComplex(&q, &t, &q, realContext);
        realSubtract(&w.Real, &q.Real, &w.Real, realContext);
        realSubtract(&w.Imag, &q.Imag, &w.Imag, realContext);
        if (realIsSpecial(&w.Real) or realIsSpecial(&w.Imag)) {
            // The iteration has broken down, so further evaluation cannot recover.
            realSetNaN(&w.Real);
            realSetNaN(&w.Imag);
            break;
        }
        if (WP34S_RelativeError(&w.Real, &p.Real, tolerance, realContext) and WP34S_RelativeError(&w.Imag, &p.Imag, tolerance, realContext)) {
            break;
        }
        realSubtract(&w.Real, &p.Real, &delta.Real, realContext);
        realSubtract(&w.Imag, &p.Imag, &delta.Imag, realContext);
        math_runtime_helpers.complexMagnitude(&delta, &d, realContext);
        // Near the branch point the step settles into a two-cycle at the working precision.
        if (math_comparison_reals.realCompareGreaterEqual(&d, &dPrev) and WP34S_ComplexRelativeError(&w, &p, const_1e_34(), realContext)) {
            flat += 1;
            if (flat >= 2) {
                break;
            }
        } else {
            flat = 0;
        }
        realCopy(&d, &dPrev);
        realCopy(&w.Real, &p.Real);
        realCopy(&w.Imag, &p.Imag);
    }
    if (realIsZero(&x.Imag) and negativeImaginarySide) {
        realSetNegativeSign(&w.Imag);
    }
    realCopy(&w.Real, &res.Real);
    realCopy(&w.Imag, &res.Imag);
}

// ===========================================================================
// WP34S_InverseW / WP34S_InverseComplexW
// ===========================================================================
pub export fn WP34S_InverseW(x: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    var p: real_t = undefined;

    if (realIsInfinite(x) and realIsNegative(x)) {
        realSetZero(res);
        realSetNegativeSign(res);
        return;
    }
    realExp(x, &p, realContext);
    realMultiply(&p, x, res, realContext);
}

pub export fn WP34S_InverseComplexW(x: *const cplx_t, res: *cplx_t, realContext: *realContext_t) callconv(.c) void {
    var p: cplx_t = undefined;

    if (realIsZero(&x.Imag)) {
        WP34S_InverseW(&x.Real, &res.Real, realContext);
        realSetZero(&res.Imag);
        return;
    }
    if (realIsSpecial(&x.Real) or realIsSpecial(&x.Imag)) {
        realSetNaN(&res.Real);
        realSetNaN(&res.Imag);
        return;
    }
    math_command_wrappers.expComplex(x, &p, realContext);
    math_multiplication_cells.mulComplexComplex(&p, x, res, realContext);
}

// ===========================================================================
// WP34S_OrthoPoly
// ===========================================================================
pub export fn WP34S_OrthoPoly(kind: u16, rX: *align(1) const real_t, rN: *align(1) const real_t, rParam: *align(1) const real_t, res: *align(1) real_t, realContext: *realContext_t) callconv(.c) void {
    // The whole body is inside `#if defined(OPTION_ORTHO)`, so without the
    // option the symbol survives as an empty function.
    if (comptime !runtime.option_ortho) return;
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
    if (realIsSpecial(rX) or (!math_comparison_reals.realIsAnInteger(@alignCast(rN))) or realIsNegative(rN)) {
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
            if (realIsSpecial(rParam) or math_comparison_reals.realCompareLessEqual(@alignCast(rParam), @alignCast(const__1()))) {
                realSetNaN(res);
                return;
            }
            realAdd(&b, rParam, &b, realContext);
            realAdd(rParam, const_3(), &a, realContext);
            realSubtract(&a, rX, &a, realContext);
            // L1 = 1 + alpha - x, summed from the smaller of alpha - x and 1 - x first.
            realSubtract(rParam, rX, &p, realContext);
            realSubtract(const_1(), rX, &q, realContext);
            if (math_comparison_reals.realCompareAbsLessThan(&p, &q)) {
                realAdd(&p, const_1(), &rT1, realContext);
            } else {
                realAdd(&q, rParam, &rT1, realContext);
            }
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
    while (math_comparison_reals.realCompareLessEqual(&i, @alignCast(rN))) { // ortho_loop
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
