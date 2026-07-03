// SPDX-License-Identifier: GPL-3.0-only
const consts = abi.constants;
const const_1 = consts.const_1;
const const_3on2 = consts.const_3on2;
const const_9999 = consts.const_9999;
const const_1on2 = consts.const_1on2;
//
// Zig owner for src/c47/fractions.c: fnDenMax and the fraction() decomposition
// engine used by the display layer. This is a faithful, line-by-line port of
// the C. Only the OPTIMAL_FRACTION_METHOD == 1 (Farey fractions) branch is
// compiled upstream — methods 0 and 2 are preprocessor-dead — so exactly that
// branch is ported. Trivial-fraction fast paths, the DENFIX and the
// factors-of-DMX paths, and the lessEqualGreater/tolerance tail reproduce the
// C's exact realContext usage (ctxtReal34/39/51) and operation order.
//
// fractions.c is not reachable from the testSuite; verification is by
// build/link across every target plus the boundary gates.

const frontier_build_options = @import("frontier_build_options");
const extra_info: bool = frontier_build_options.extra_info_on_calc_error;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const DECNUMUNITS = 25;
const abi = @import("abi"); // L1 shared bindings (REPORT-23 §5)
const real_t = abi.Real;
const real34_t = abi.Real34;
const realContext_t = abi.RealContext;
const calcRegister_t = i16;

// decNumber bits.
const DECNEG: u8 = 0x80;
const DECINF: u8 = 0x40;
const DECNAN: u8 = 0x20;
const DECSNAN: u8 = 0x10;
const DECSPECIAL: u8 = DECINF | DECNAN | DECSNAN;

// ---------------------------------------------------------------------------
// Constants / enum values (verified against defines.h)
// ---------------------------------------------------------------------------
const dtReal34: u32 = 1;

const REGISTER_X: calcRegister_t = 100;

const FLAG_PROPFR: c_int = 0x8008;
const FLAG_DENANY: c_int = 0x8009;
const FLAG_DENFIX: c_int = 0x800a;

const SETTING_DMX: c_int = 0x0081;
const SCRUPD_MANUAL_STATUSBAR: u8 = 0x01;

const MAX_DENMAX: u32 = 9999;
const MAX_INTERNAL_DENMAX: u32 = 32500;

const DEC_ROUND_DOWN: c_int = 5;

// ---------------------------------------------------------------------------
// Constant blob (offsets from the generated constantPointers.h)
// ---------------------------------------------------------------------------
const constants = @extern([*]const u8, .{ .name = "constants" });

inline fn cstR(offset: u32) *align(1) const real_t {
    return @ptrCast(constants + offset);
}

// ---------------------------------------------------------------------------
// Globals
// ---------------------------------------------------------------------------
extern var errorMessage: [*c]u8;
extern var denMax: u32;
extern var screenUpdatingMode: u8;
extern var fractionDigits: u8;
extern var ctxtReal34: realContext_t;
extern var ctxtReal39: realContext_t;
extern var ctxtReal51: realContext_t;

// ---------------------------------------------------------------------------
// Function externs
// ---------------------------------------------------------------------------
extern fn getRegisterDataType(regist: calcRegister_t) u32;
extern fn getRegisterDataPointer(regist: calcRegister_t) *anyopaque;
extern fn getRegisterDataTypeName(regist: calcRegister_t, article: bool, pad: bool) [*c]const u8;
const c_moreInfoOnError = @extern(*const fn (m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) callconv(.c) void, .{ .name = "moreInfoOnError" });
extern fn sprintf(buf: [*c]u8, fmt: [*:0]const u8, ...) c_int;
extern fn setSystemFlagChanged(sf: i32) void;
extern fn getSystemFlag(flag: c_int) bool;
extern fn realToUint32C47(r: *const real_t, err: ?*bool) u32;
extern fn fractionTolerence(tol: *real_t) void;
extern fn WP34S_int_gcd(a: u64, b: u64) u64;
extern fn realCompareLessThan(number1: *align(1) const real_t, number2: *align(1) const real_t) bool;
extern fn realCompareAbsLessThan(number1: *align(1) const real_t, number2: *align(1) const real_t) bool;
extern fn realCompareAbsGreaterThan(number1: *align(1) const real_t, number2: *align(1) const real_t) bool;
extern fn real34IsAnInteger(x: *align(1) const real34_t) bool;

// decNumber / decQuad externs behind the real*/real34* macros.
extern fn decNumberAdd(r: *real_t, a: *align(1) const real_t, b: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberSubtract(r: *real_t, a: *align(1) const real_t, b: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberMultiply(r: *real_t, a: *align(1) const real_t, b: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberDivide(r: *real_t, a: *align(1) const real_t, b: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberFMA(r: *real_t, a: *align(1) const real_t, b: *align(1) const real_t, c: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberCopy(r: *real_t, src: *align(1) const real_t) *real_t;
extern fn decNumberFromUInt32(r: *real_t, v: u32) *real_t;
extern fn decNumberFromInt32(r: *real_t, v: i32) *real_t;
extern fn decimal128ToNumber(src: *align(1) const real34_t, dst: *real_t) *real_t;
extern fn decimal128FromNumber(dst: *real34_t, src: *const real_t, ctx: *realContext_t) *real34_t;
extern fn decQuadToInt32(r: *align(1) const real34_t, ctx: *realContext_t, round: c_int) i32;

// ---------------------------------------------------------------------------
// Inline wrappers (the C macros)
// ---------------------------------------------------------------------------
inline fn moreInfoOnError(m1: [*:0]const u8, m2: ?[*:0]const u8) void {
    if (comptime extra_info) c_moreInfoOnError(m1, m2, null, null);
}
inline fn reg34(reg: calcRegister_t) *align(1) real34_t {
    return @ptrCast(getRegisterDataPointer(reg));
}
inline fn realIsZero(v: *const real_t) bool {
    return v.lsu[0] == 0 and v.digits == 1 and (v.bits & DECSPECIAL) == 0;
}
inline fn realIsNegative(v: *const real_t) bool {
    return (v.bits & 0x80) == 0x80;
}
inline fn realSetPositiveSign(v: *real_t) void {
    v.bits &= 0x7f;
}
inline fn realChangeSign(v: *real_t) void {
    v.bits ^= 0x80;
}
inline fn realCopy(src: *align(1) const real_t, dst: *real_t) void {
    _ = decNumberCopy(dst, src);
}
inline fn realAdd(a: *align(1) const real_t, b: *align(1) const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberAdd(res, a, b, ctx);
}
inline fn realSubtract(a: *align(1) const real_t, b: *align(1) const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberSubtract(res, a, b, ctx);
}
inline fn realMultiply(a: *align(1) const real_t, b: *align(1) const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberMultiply(res, a, b, ctx);
}
inline fn realDivide(a: *align(1) const real_t, b: *align(1) const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberDivide(res, a, b, ctx);
}
inline fn realFMA(f1: *align(1) const real_t, f2: *align(1) const real_t, term: *align(1) const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberFMA(res, f1, f2, term, ctx);
}
inline fn uInt32ToReal(src: u32, dst: *real_t) void {
    _ = decNumberFromUInt32(dst, src);
}
inline fn int32ToReal(src: i32, dst: *real_t) void {
    _ = decNumberFromInt32(dst, src);
}
inline fn real34ToReal(src: *align(1) const real34_t, dst: *real_t) void {
    _ = decimal128ToNumber(src, dst);
}
inline fn realToReal34(src: *const real_t, dst: *real34_t) void {
    _ = decimal128FromNumber(dst, src, &ctxtReal34);
}
inline fn real34ToInt32(src: *align(1) const real34_t) i32 {
    return decQuadToInt32(src, &ctxtReal34, DEC_ROUND_DOWN);
}

// ===========================================================================
// fnDenMax
// ===========================================================================
pub export fn fnDenMax(D: u16) callconv(.c) void {
    if (denMax != D) {
        setSystemFlagChanged(SETTING_DMX);
        screenUpdatingMode &= ~SCRUPD_MANUAL_STATUSBAR;
    }
    denMax = D;
    if (denMax == 1 or denMax > MAX_DENMAX) {
        denMax = MAX_DENMAX;
        setSystemFlagChanged(SETTING_DMX);
        screenUpdatingMode &= ~SCRUPD_MANUAL_STATUSBAR;
    }
}

// ===========================================================================
// fraction
// ===========================================================================
pub export fn fraction(regist: calcRegister_t, sign: *i16, intPart: *u64, numer: *u64, denom: *u64, lessEqualGreater: *i16) callconv(.c) bool {
    // temp0 = fractional_part(absolute_value(real number))
    // temp1 = continued fraction calculation --> fractional_part(1 / temp1)  initialized with temp0
    // delta = difference between the best fraction and the real number

    const dd: u32 = denMax; // dd = global
    var denMaxLocal: u32 = undefined; // local (shadows the global in the C)
    if (dd == 0 or dd > MAX_DENMAX) {
        denMaxLocal = MAX_INTERNAL_DENMAX; // local
    } else {
        denMaxLocal = dd;
    }

    var temp0: real_t = undefined;

    if (getRegisterDataType(regist) == dtReal34) {
        real34ToReal(reg34(regist), &temp0);
    } else {
        if (comptime extra_info) {
            _ = sprintf(errorMessage, "%s cannot be shown as a fraction!", getRegisterDataTypeName(regist, true, false));
            moreInfoOnError("In function fraction:", errorMessage);
        }
        sign.* = 0;
        intPart.* = 0;
        numer.* = 0;
        denom.* = 0;
        lessEqualGreater.* = 0;

        return false;
    }

    if (realIsZero(&temp0)) {
        sign.* = 0;
        intPart.* = 0;
        numer.* = 0;
        denom.* = 1;
        lessEqualGreater.* = 0;

        return false;
    }

    if (realIsNegative(&temp0)) {
        sign.* = -1;
        realSetPositiveSign(&temp0);
    } else {
        sign.* = 1;
    }

    var posr: real_t = undefined;
    var delta: real_t = undefined;
    var temp3: real_t = undefined;
    realCopy(&temp0, &posr);
    realCopy(const_9999(), &delta); // delta is used from this initialisation with no other sets, in OPTIMAL_FRACTION_METHOD = 0
    //   it is unknown why 9999 and if this has to do with the previous DMX maximum. This may or may not have to change with the new max of 999999.
    //   it is not in use as in OPTIMAL_FRACTION_METHOD = 1, delta is re-initialized
    var ip: u32 = undefined;
    ip = realToUint32C47(&temp0, null);
    intPart.* = ip;
    uInt32ToReal(@truncate(intPart.*), &temp3);
    realSubtract(&temp0, &temp3, &temp0, &ctxtReal34);

    // ** ***************************
    // ** Check for trivial fractions
    var validResult: bool = false;
    var factorOfOneOnDenMax: real_t = undefined;
    var checkPoint: real_t = undefined;
    uInt32ToReal(denMaxLocal, &factorOfOneOnDenMax);

    // check if the fraction is lower than 0.5/DMX
    realDivide(const_1on2(), &factorOfOneOnDenMax, &checkPoint, &ctxtReal39);
    if (realCompareLessThan(&temp0, &checkPoint)) {
        numer.* = 0;
        if (getSystemFlag(FLAG_DENANY)) {
            denom.* = 1;
            validResult = true;
        } else if (getSystemFlag(FLAG_DENFIX)) {
            // *denom = denMax;
            // validResult = true;
        } else {
            denom.* = 1;
            validResult = true;
        }
    }

    if (!validResult) {
        // check if the fraction is lower than 1.5/DMX
        realDivide(const_3on2(), &factorOfOneOnDenMax, &checkPoint, &ctxtReal39);
        if (realCompareLessThan(&temp0, &checkPoint)) {
            numer.* = 1;
            if (getSystemFlag(FLAG_DENANY)) {
                // *denom = denMax;
                // validResult = true;
            } else if (getSystemFlag(FLAG_DENFIX)) {
                // *denom = denMax;
                // validResult = true;
            } else {
                denom.* = denMaxLocal;
                validResult = true;
            }
        }
    }

    if (!validResult) {
        // check if fraction is a simple integer/DMX, fast track, only integer GCD needed, not Farey fractions which run to n = DMX loops if the fraction is low
        realDivide(const_1(), &factorOfOneOnDenMax, &factorOfOneOnDenMax, &ctxtReal51);
        realDivide(&temp0, &factorOfOneOnDenMax, &factorOfOneOnDenMax, &ctxtReal51);
        var factorOfOneOnDenMax34: real34_t = undefined;
        realToReal34(&factorOfOneOnDenMax, &factorOfOneOnDenMax34);
        var tt: u32 = 0;
        if (real34IsAnInteger(&factorOfOneOnDenMax34)) {
            tt = @bitCast(real34ToInt32(&factorOfOneOnDenMax34));
            const gcd: u32 = @truncate(WP34S_int_gcd(tt, denMaxLocal));

            if (getSystemFlag(FLAG_DENANY)) {
                if (gcd != 0) {
                    numer.* = tt / gcd;
                    denom.* = denMaxLocal / gcd;
                    validResult = true;
                }
            } else if (getSystemFlag(FLAG_DENFIX)) {
                // no speed gain:        *numer = tt;
                // no speed gain:        *denom = denMax;
                // no speed gain:        validResult = true;
            } else {
                if (gcd != 0) {
                    numer.* = tt / gcd;
                    denom.* = denMaxLocal / gcd;
                    validResult = true;
                }
            }
        }
    }

    //*******************
    //* Any denominator *
    //*******************
    if (!validResult and getSystemFlag(FLAG_DENANY)) { // denominator up to denMax
        // OPTIMAL_FRACTION_METHOD == 1 (Farey fractions) — the only branch the
        // C preprocessor keeps; methods 0 and 2 are dead code upstream.
        // see: https://math.stackexchange.com/questions/2438510/can-i-find-the-closest-rational-to-any-given-real-if-i-assume-that-the-denomina
        // and https://www.johndcook.com/blog/2010/10/20/best-rational-approximation/#comment-1077474

        var a: u32 = 0;
        var b: u32 = 1;
        var c: u32 = 1;
        var d: u32 = 1;
        var oldA: u32 = 0;
        var oldB: u32 = 0;
        var oldC: u32 = 0;
        var oldD: u32 = 0;
        var exactValue: bool = false;
        var mediant: real_t = undefined;
        var temp1: real_t = undefined;

        while (b <= denMaxLocal and d <= denMaxLocal) {
            oldA = a;
            oldB = b;
            oldC = c;
            oldD = d;

            // mediant = (a+c) / (b+d)
            int32ToReal(@bitCast(a +% c), &mediant);
            int32ToReal(@bitCast(b +% d), &temp1);
            realDivide(&mediant, &temp1, &mediant, &ctxtReal34);

            realAdd(&mediant, &temp3, &temp1, &ctxtReal34);
            realSubtract(&temp1, &posr, &delta, &ctxtReal34);
            if (realIsZero(&delta)) {
                exactValue = true;
                if (b + d <= denMaxLocal) {
                    numer.* = a + c;
                    denom.* = b + d;
                } else if (d > b) {
                    numer.* = c;
                    denom.* = d;
                } else {
                    numer.* = a;
                    denom.* = b;
                }
                break;
            } else if (realIsNegative(&delta)) {
                a += c;
                b += d;
            } else {
                c += a;
                d += b;
            }
        }

        if (!exactValue) {
            // mediant = |fracPart - oldC/oldD|
            int32ToReal(@bitCast(oldC), &mediant);
            int32ToReal(@bitCast(oldD), &temp1);
            realDivide(&mediant, &temp1, &mediant, &ctxtReal34);
            realSubtract(&temp0, &mediant, &mediant, &ctxtReal34);
            realSetPositiveSign(&mediant);

            // delta = |fracPart - oldA/oldB|
            int32ToReal(@bitCast(oldA), &delta);
            int32ToReal(@bitCast(oldB), &temp1);
            realDivide(&delta, &temp1, &delta, &ctxtReal34);
            realSubtract(&temp0, &delta, &delta, &ctxtReal34);
            realSetPositiveSign(&delta);

            if (realCompareLessThan(&mediant, &delta)) {
                numer.* = oldC;
                denom.* = oldD;
            } else {
                numer.* = oldA;
                denom.* = oldB;
            }
        }
    }

    //*******************
    //* Fix denominator *
    //*******************
    else if (!validResult and getSystemFlag(FLAG_DENFIX)) { // denominator is D.MAX
        denom.* = denMaxLocal;

        uInt32ToReal(denMaxLocal, &delta);
        realFMA(&delta, &temp0, const_1on2(), &temp3, &ctxtReal34);
        ip = realToUint32C47(&temp3, null);
        numer.* = ip;
    }

    //******************************
    //* Factors of max denominator *
    //******************************
    else if (!validResult) { // denominator is a factor of D.MAX
        var bestNumer: u64 = 0;
        var bestDenom: u64 = 1;

        var temp4: real_t = undefined;

        // TODO: we can certainly do better here
        var i: u32 = 1;
        while (i <= denMaxLocal) : (i += 1) {
            if (denMaxLocal % i == 0) {
                uInt32ToReal(i, &temp4);
                realFMA(&temp4, &temp0, const_1on2(), &temp3, &ctxtReal34);
                ip = realToUint32C47(&temp3, null);
                numer.* = ip;

                uInt32ToReal(@truncate(numer.*), &temp3);
                uInt32ToReal(i, &temp4);
                realDivide(&temp3, &temp4, &temp3, &ctxtReal34);
                realSubtract(&temp3, &temp0, &temp3, &ctxtReal34);
                realSetPositiveSign(&temp3);
                realSubtract(&temp3, &delta, &temp3, &ctxtReal34);
                if (realIsNegative(&temp3)) {
                    realAdd(&temp3, &delta, &delta, &ctxtReal34);
                    bestNumer = numer.*;
                    bestDenom = i;
                }
            }
        }

        numer.* = bestNumer;
        denom.* = bestDenom;
    }

    // continue here after if..else..

    // The register value
    var r: real_t = undefined;
    real34ToReal(reg34(regist), &r);

    // The fraction value
    var f: real_t = undefined;
    var d2: real_t = undefined;
    var n: real_t = undefined;
    uInt32ToReal(@truncate(intPart.*), &f);
    uInt32ToReal(@truncate(denom.*), &d2);
    realMultiply(&f, &d2, &f, &ctxtReal39);
    uInt32ToReal(@truncate(numer.*), &n);
    realAdd(&f, &n, &f, &ctxtReal39);
    realDivide(&f, &d2, &f, &ctxtReal39);
    if (sign.* == -1) {
        realChangeSign(&f);
    }

    realSubtract(&f, &r, &f, &ctxtReal39);
    var roundingTolerance: real_t = undefined;
    fractionTolerence(&roundingTolerance); // Arrive here if a tolerance for lying is set

    if (((fractionDigits == 0 or fractionDigits == 34) and realIsZero(&f)) or
        ((fractionDigits >= 1 and fractionDigits <= 33) and realCompareAbsLessThan(&f, &roundingTolerance)))
    { // broaden the range for it to be deemed zero
        lessEqualGreater.* = 0;
    } else if (realIsNegative(&f)) {
        lessEqualGreater.* = -1;
    } else {
        lessEqualGreater.* = 1;
    }

    if (!getSystemFlag(FLAG_PROPFR)) { // d/c
        numer.* += denom.* * intPart.*;
        intPart.* = 0;
    }

    if (fractionDigits == 0 or fractionDigits == 34) { // Returns true to prepend the tags, if FDIGS=34 is normal, i.e. no lying
        return true;
    } else { // Checks if within tolerance for FDIGS<=32
        return realCompareAbsGreaterThan(&f, &roundingTolerance); // return true to prepend tags, if actual fraction is outside of tolerance
    } // return false to not prepend tags, if actual fraction is within the tolerance
}
