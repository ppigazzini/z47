// SPDX-License-Identifier: GPL-3.0-only
const abi = @import("abi");
const consts = abi.constants;
//
// Zig owner for src/c47/mathematics/iteration.c: the DSE/DSL/DSZ/ISE/ISG/ISZ
// loop-counter increment/decrement-and-skip commands. UNCOVERED by the
// testSuite (no gate); faithful line-by-line translation preserving the exact
// real34_t / real_t operation order and the packed loop-counter unpack/compare/
// repack arithmetic, which is itself unverified by tests.
//
// The static getIterParam / incDecAndCompare helpers stay private; the six
// .h-declared fnIse/fnIsg/fnIsz/fnDse/fnDsl/fnDsz commands are exported with C
// linkage. The EXTRA_INFO_ON_CALC_ERROR hint becomes a fixed moreInfoOnError
// string (no-op under TESTSUITE/DMCP).
//
// =====================================================================
// Loop-counter packed format (real34 register holding "cccccc.fffii"):
//   The real34 value is  counter.fffii  where, after the integer part is
//   stripped off, the fractional digits encode  fff = target  and  ii = step:
//
//     fp     = frac(value)                 // 0.fffii...
//     target = floor(fp * 1000)            // fffii ->  fff (after re-floor)
//             then target = floor(target)  // fff   (the 3-digit limit)
//     step   = (target_before_floor - target) * 100   // .ii * 100 = ii
//             then step = floor(step), and if step == 0 -> step = 1
//
//   i.e. the fractional part is read as fff/1000 for the limit and ii/100000
//   for the step; default step is 1 when ii is absent.
//
//   The increment / decrement / skip then operates on the integer part:
//     - "skip" modes (mode & 2): set step=1, inc/dec by step, compare |x|<1.
//     - integer (LonI/ShoI) registers: incDecLonI/incDecShoI then registerCmp.
//     - real34 amNone: floor x, add +/-step, compare to target (TEMP_REGISTER_1),
//       then re-add the packed fp so the fff/ii survive into the result.
//
// mode encoding (defines.h INC_FLAG==0, DEC_FLAG==1):
//   ITER_ISE = (0<<2)|0, ITER_ISG = (0<<2)|1, ITER_ISZ = (0<<2)|2,
//   ITER_DSE = (1<<2)|0, ITER_DSL = (1<<2)|1, ITER_DSZ = (1<<2)|2.
//   incDec* take (mode >> 2) i.e. INC_FLAG/DEC_FLAG.
//
// SET_TI_TRUE_FALSE(cond): temporaryInformation = TI_FALSE + cond (TI_FALSE==12,
//   TI_TRUE==13). TEMP_REGISTER_1==135, amNone==5, DEC_ROUND_DOWN==5,
//   ERROR_INVALID_DATA_TYPE_FOR_OP==24. const34_1/100/1000 blob offsets
//   15804/16044/16124. All verified against defines.h / generated
//   constantPointers.h.
// =====================================================================

const runtime = @import("math_command_wrappers_runtime.zig");

const real34_t = runtime.real34_t;
const real_t = runtime.real_t;
const realContext_t = runtime.realContext_t;
const calcRegister_t = runtime.calcRegister_t;
const rounding_t = runtime.rounding_t;

const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const ERROR_INVALID_DATA_TYPE_FOR_OP = runtime.ERROR_INVALID_DATA_TYPE_FOR_OP;
const amNone = runtime.amNone;
const amAngleMask = runtime.amAngleMask;
const dtReal34 = runtime.dtReal34;
const dtLongInteger = runtime.dtLongInteger;
const dtShortInteger = runtime.dtShortInteger;
const dtTime = runtime.dtTime;
const DEC_ROUND_DOWN = runtime.DEC_ROUND_DOWN;

const const_3600 = runtime.z47_math_wrappers_const_3600;
const ctxtReal39 = &runtime.ctxtReal39;
const real34ToReal = runtime.real34ToReal;
const realToReal34 = runtime.realToReal34;
const realAdd = runtime.realAdd;
const realSubtract = runtime.realSubtract;

const INC_FLAG: u16 = 0;
const DEC_FLAG: u16 = 1;
const TEMP_REGISTER_1: calcRegister_t = 135;
const TI_FALSE: u8 = 12;

const ITER_ISE: u16 = (INC_FLAG << 2) | 0;
const ITER_ISG: u16 = (INC_FLAG << 2) | 1;
const ITER_ISZ: u16 = (INC_FLAG << 2) | 2;
const ITER_DSE: u16 = (DEC_FLAG << 2) | 0;
const ITER_DSL: u16 = (DEC_FLAG << 2) | 1;
const ITER_DSZ: u16 = (DEC_FLAG << 2) | 2;

const getRegisterDataType = runtime.getRegisterDataType;
const getRegisterTag = runtime.getRegisterTag;
const getRegisterDataPointer = runtime.getRegisterDataPointer;
const reallocateRegister = runtime.reallocateRegister;
const real34ToIntegralValue = runtime.real34ToIntegralValue;
const real34Subtract = runtime.real34Subtract;
const real34Add = runtime.real34Add;
const real34Multiply = runtime.real34Multiply;
// real34Copy (realType.h macro): copy the two u64 halves of the 16-byte value.
inline fn real34Copy(source: *const real34_t, destination: *real34_t) void {
    destination.bytes = source.bytes;
}
const displayCalcErrorMessage = runtime.displayCalcErrorMessage;
const moreInfoOnError = runtime.moreInfoOnError;

extern fn incDecLonI(regist: u16, flag: u8) void;
extern fn incDecReal(regist: u16, flag: u8) void;
extern fn incDecShoI(regist: u16, flag: u8) void;
extern fn registerCmp(regist1: calcRegister_t, regist2: calcRegister_t, result: *i8) bool;
extern fn real34CompareAbsLessThan(number1: *const real34_t, number2: *const real34_t) bool;
extern fn realCompareAbsLessThan(number1: *const real_t, number2: *const real_t) bool;

// real34 sign / predicate / set helpers (realType.h macros / decQuad).
extern fn decQuadZero(res: *real34_t) *real34_t;
extern fn decQuadFromInt32(res: *real34_t, value: i32) *real34_t;
extern fn decQuadIsZero(value: *const real34_t) u32;
extern fn decQuadIsNegative(value: *const real34_t) u32;
inline fn real34SetZero(destination: *real34_t) void {
    _ = decQuadZero(destination);
}
inline fn real34SetOne(destination: *real34_t) void {
    _ = decQuadFromInt32(destination, 1);
}
inline fn real34IsZero(source: *const real34_t) bool {
    return decQuadIsZero(source) != 0;
}
inline fn real34IsNegative(source: *const real34_t) bool {
    return (source.bytes[15] & 0x80) == 0x80;
}
inline fn real34SetPositiveSign(operand: *real34_t) void {
    operand.bytes[15] &= 0x7F;
}
inline fn real34SetNegativeSign(operand: *real34_t) void {
    operand.bytes[15] |= 0x80;
}

inline fn getRegisterAngularMode(reg: calcRegister_t) u32 {
    return getRegisterTag(reg) & amAngleMask;
}

const registerReal34Data = abi.registerReal34Aligned;

inline fn SET_TI_TRUE_FALSE(condition: bool) void {
    runtime.temporaryInformation = TI_FALSE + @as(u8, @intFromBool(condition));
}

// Blob constants (real34) routed through the abi typed accessors (M22).
inline fn const34_1() *const real34_t {
    return consts.q16312();
}
inline fn const34_100() *const real34_t {
    return consts.q16552();
}
inline fn const34_1000() *const real34_t {
    return consts.q16632();
}

fn getIterParam(regist: u16, fp: *real34_t, target: *real34_t, step: *real34_t) linksection(runtime.code_section) void {
    if (getRegisterDataType(@intCast(regist)) == dtReal34) {
        real34ToIntegralValue(registerReal34Data(@intCast(regist)), fp, DEC_ROUND_DOWN);
        real34Subtract(registerReal34Data(@intCast(regist)), fp, fp);
        real34SetPositiveSign(fp);
        real34Multiply(fp, const34_1000(), target);
        real34Copy(target, step);
        real34ToIntegralValue(target, target, DEC_ROUND_DOWN);
        real34Subtract(step, target, step);
        real34Multiply(step, const34_100(), step);
        real34ToIntegralValue(step, step, DEC_ROUND_DOWN);
        if (real34IsZero(step)) {
            real34SetOne(step);
        }
    } else {
        real34SetZero(fp);
        real34SetZero(target);
        real34SetOne(step);
    }
}

fn incDecAndCompare(regist: u16, mode: u16) linksection(runtime.code_section) void {
    var fp: real34_t = undefined;
    var step: real34_t = undefined;
    var compared: i8 = undefined;

    reallocateRegister(TEMP_REGISTER_1, dtReal34, 0, @intCast(amNone));
    getIterParam(regist, &fp, registerReal34Data(TEMP_REGISTER_1), &step);
    switch (getRegisterDataType(@intCast(regist))) {
        dtLongInteger => {
            incDecLonI(regist, @intCast(mode >> 2));
            _ = registerCmp(@intCast(regist), TEMP_REGISTER_1, &compared);
        },
        dtShortInteger => {
            incDecShoI(regist, @intCast(mode >> 2));
            _ = registerCmp(@intCast(regist), TEMP_REGISTER_1, &compared);
        },
        dtReal34 => {
            if ((mode & 2) == 2) {
                real34SetOne(&step);
                incDecReal(regist, @intCast(mode >> 2));
                compared = if (real34CompareAbsLessThan(registerReal34Data(@intCast(regist)), const34_1())) 0 else 1;
            } else if (getRegisterAngularMode(@intCast(regist)) == amNone) {
                real34ToIntegralValue(registerReal34Data(@intCast(regist)), registerReal34Data(@intCast(regist)), DEC_ROUND_DOWN);
                if ((mode >> 2) == DEC_FLAG) {
                    real34SetNegativeSign(&step);
                }
                real34Add(registerReal34Data(@intCast(regist)), &step, registerReal34Data(@intCast(regist)));
                _ = registerCmp(@intCast(regist), TEMP_REGISTER_1, &compared);
                if (real34IsNegative(registerReal34Data(@intCast(regist)))) {
                    real34SetNegativeSign(&fp);
                }
                real34Add(registerReal34Data(@intCast(regist)), &fp, registerReal34Data(@intCast(regist)));
            } else {
                // fallthrough to default: goto invalidType
                return invalidType(regist);
            }
        },
        dtTime => {
            if ((mode & 2) == 2) { // DSZ / ISZ : count by whole hours
                var v: real_t = undefined;
                real34ToReal(registerReal34Data(@intCast(regist)), &v); // seconds
                if ((mode >> 2) == DEC_FLAG) {
                    realSubtract(&v, const_3600(), &v, ctxtReal39);
                } else {
                    realAdd(&v, const_3600(), &v, ctxtReal39);
                } // step = 1 hour = 3600 s
                realToReal34(&v, registerReal34Data(@intCast(regist)));
                compared = if (realCompareAbsLessThan(&v, const_3600())) 0 else 1; // |time| < 1h -> treat as zero
            } else {
                // ISG/DSE/ISE/DSL counter format has no meaning for Time
                return invalidType(regist);
            }
        },
        else => {
            // goto invalidType
            return invalidType(regist);
        },
    }
    if (compared > 0) {
        SET_TI_TRUE_FALSE(!((mode & 6) == (INC_FLAG << 2)));
    } else if (compared < 0) {
        SET_TI_TRUE_FALSE(!((mode & 6) == (DEC_FLAG << 2)));
    } else { // compared == 0
        SET_TI_TRUE_FALSE((mode & 1) != 0);
    }
    return;
}

fn invalidType(regist: u16) linksection(runtime.code_section) void {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, @intCast(regist));
    moreInfoOnError("In function incDecAndCompare:", "incompatible type for iterator.", null, null);
}

pub export fn fnIse(regist: u16) linksection(runtime.code_section) callconv(.c) void {
    incDecAndCompare(regist, ITER_ISE);
}

pub export fn fnIsg(regist: u16) linksection(runtime.code_section) callconv(.c) void {
    incDecAndCompare(regist, ITER_ISG);
}

pub export fn fnIsz(regist: u16) linksection(runtime.code_section) callconv(.c) void {
    incDecAndCompare(regist, ITER_ISZ);
}

pub export fn fnDse(regist: u16) linksection(runtime.code_section) callconv(.c) void {
    incDecAndCompare(regist, ITER_DSE);
}

pub export fn fnDsl(regist: u16) linksection(runtime.code_section) callconv(.c) void {
    incDecAndCompare(regist, ITER_DSL);
}

pub export fn fnDsz(regist: u16) linksection(runtime.code_section) callconv(.c) void {
    incDecAndCompare(regist, ITER_DSZ);
}
