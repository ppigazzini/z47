// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/integers.c: the WP34S short-integer (uint64) arithmetic
// engine plus fnChangeBase and the long-integer (GMP) add/subtract/multiply/square
// overflow-guarded wrappers. The WP34S_int* routines are pure word arithmetic with
// FLAG_OVERFLOW/FLAG_CARRY side effects; they are exercised across the testSuite
// (and/or/xor, shift_rotate, idiv, gcd, lcm, mulmod, expmod and every short-integer
// arithmetic test), so `zig build test` verifies the port.
//
// Faithful line-by-line translation of integers.c. C unsigned arithmetic wraps
// (defined behavior); Zig's Debug build traps on overflow, so every wrapping C
// operation is written with the wrapping operators (+% -% *%). The host-only
// EXTRA_INFO_ON_CALC_ERROR sprintf hints are reduced to fixed strings (matching the
// sibling owners); the control flow is identical.

const frontier_build_options = @import("frontier_build_options");
const extra_info: bool = frontier_build_options.extra_info_on_calc_error;

// ---------------------------------------------------------------------------
// GMP long integer (mpz). The mpz_* names are header macros; the real symbols are
// __gmpz_*. The limb width == pointer width on every z47 target (64-bit on Linux
// and Win64, 32-bit on ARM32 firmware) — NOT c_ulong, which is 32-bit on Win64.
// ---------------------------------------------------------------------------
const mp_limb_t = usize;
const mpz_struct = extern struct {
    _mp_alloc: c_int,
    _mp_size: c_int,
    _mp_d: [*c]mp_limb_t,
};
extern fn @"__gmpz_mul"(r: *mpz_struct, a: *const mpz_struct, b: *const mpz_struct) void;
extern fn @"__gmpz_add"(r: *mpz_struct, a: *const mpz_struct, b: *const mpz_struct) void;
extern fn @"__gmpz_sub"(r: *mpz_struct, a: *const mpz_struct, b: *const mpz_struct) void;
extern fn @"__gmpz_sizeinbase"(op: *const mpz_struct, base: c_int) usize;
const mpz_mul = @"__gmpz_mul";
const mpz_add = @"__gmpz_add";
const mpz_sub = @"__gmpz_sub";

inline fn longIntegerSign(op: *const mpz_struct) i32 {
    return if (op._mp_size < 0) -1 else if (op._mp_size > 0) 1 else 0;
}
inline fn longIntegerBits(op: *const mpz_struct) u32 {
    return @intCast(@"__gmpz_sizeinbase"(op, 2));
}

const MAX_LONG_INTEGER_SIZE_IN_BITS: u32 = 3328;

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------
const SIM_UNSIGN: u8 = 0;
const SIM_1COMPL: u8 = 1;
const SIM_2COMPL: u8 = 2;
const SIM_SIGNMT: u8 = 3;

const FLAG_CARRY: u16 = 0x800b;
const FLAG_OVERFLOW: u16 = 0x800c;

const ERROR_OVERFLOW_PLUS_INF: u8 = 4;
const ERROR_OVERFLOW_MINUS_INF: u8 = 5;
const ERROR_OUT_OF_RANGE: u8 = 8;
const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN: u8 = 1;
const ERROR_BAD_TIME_OR_DATE_INPUT: u8 = 2;

const TI_DATA_NEG_OVRFL: u8 = 111;

const calcRegister_t = i16;
const REGISTER_X: calcRegister_t = 100;
const REGISTER_Z: calcRegister_t = 102;
const REGISTER_T: calcRegister_t = 103;
const ERR_REGISTER_LINE: calcRegister_t = REGISTER_Z;

// ---------------------------------------------------------------------------
// Externs: globals + runtime
// ---------------------------------------------------------------------------
extern var shortIntegerMode: u8;
extern var shortIntegerMask: u64;
extern var shortIntegerSignBit: u64;
extern var shortIntegerWordSize: u8;
extern var lastIntegerBase: u32;
extern var temporaryInformation: u8;

extern fn setSystemFlag(flag: u16) void;
extern fn clearSystemFlag(flag: u16) void;
extern fn displayCalcErrorMessage(error_code: u8, err_message_register_line: calcRegister_t, err_register_line: calcRegister_t) void;
extern fn displayBugScreen(msg: [*:0]const u8) void;
const c_moreInfoOnError = @extern(*const fn (m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) callconv(.c) void, .{ .name = "moreInfoOnError" });

// Provided by the registerValueConversions Zig owner.
extern fn getRegisterAsShortInt(reg: calcRegister_t, sign: *bool, val: *u64, overflow: ?*bool, fractional: ?*bool) bool;
extern fn convertUInt64ToShortIntegerRegister(sign: i16, value: u64, base: u32, regist: calcRegister_t) void;
// Defined in radioButtonCatalog.c.
extern fn fnRefreshState() void;

inline fn moreInfoOnError(m1: [*:0]const u8, m2: ?[*:0]const u8) void {
    if (comptime extra_info) c_moreInfoOnError(m1, m2, null, null);
}

// ===========================================================================
// fnChangeBase
// ===========================================================================
pub export fn fnChangeBase(base: u16) callconv(.c) void {
    var sign: bool = undefined;
    var val: u64 = undefined;

    if (base < 2 or base > 16) {
        displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_T);
        moreInfoOnError("In function fnChangeBase:", "The base must be from 2 to 16.");
    } else if (getRegisterAsShortInt(REGISTER_X, &sign, &val, null, null)) {
        convertUInt64ToShortIntegerRegister(@intFromBool(sign), val, base, REGISTER_X);
        lastIntegerBase = base;
        fnRefreshState();
    }
}

// ===========================================================================
// Long integer (GMP) overflow-guarded operators
// ===========================================================================
pub export fn longIntegerMultiply(opY: *mpz_struct, opX: *mpz_struct, result: *mpz_struct) callconv(.c) void {
    if (longIntegerBits(opY) + longIntegerBits(opX) <= MAX_LONG_INTEGER_SIZE_IN_BITS) {
        mpz_mul(result, opY, opX);
    } else {
        displayCalcErrorMessage(if (longIntegerSign(opY) == longIntegerSign(opX)) ERROR_OVERFLOW_PLUS_INF else ERROR_OVERFLOW_MINUS_INF, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function longIntegerMultiply:", "the product would exceed the maximum long integer size!");
    }
}

pub export fn longIntegerSquare(op: *mpz_struct, result: *mpz_struct) callconv(.c) void {
    if (longIntegerBits(op) * 2 <= MAX_LONG_INTEGER_SIZE_IN_BITS) {
        mpz_mul(result, op, op);
    } else {
        displayCalcErrorMessage(ERROR_OVERFLOW_PLUS_INF, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function longIntegerSquare:", "the square would exceed the maximum long integer size!");
    }
}

pub export fn longIntegerAdd(opY: *mpz_struct, opX: *mpz_struct, result: *mpz_struct) callconv(.c) void {
    if (longIntegerSign(opY) != longIntegerSign(opX) or @max(longIntegerBits(opY), longIntegerBits(opX)) <= MAX_LONG_INTEGER_SIZE_IN_BITS - 1) {
        mpz_add(result, opY, opX);
    } else {
        displayCalcErrorMessage(if (longIntegerSign(opY) == 0) ERROR_OVERFLOW_PLUS_INF else ERROR_OVERFLOW_MINUS_INF, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function longIntegerAdd:", "the sum would exceed the maximum long integer size!");
    }
}

pub export fn longIntegerSubtract(opY: *mpz_struct, opX: *mpz_struct, result: *mpz_struct) callconv(.c) void {
    if (longIntegerSign(opY) == longIntegerSign(opX) or @max(longIntegerBits(opY), longIntegerBits(opX)) <= MAX_LONG_INTEGER_SIZE_IN_BITS - 1) {
        mpz_sub(result, opY, opX);
    } else {
        displayCalcErrorMessage(if (longIntegerSign(opY) == 0) ERROR_OVERFLOW_PLUS_INF else ERROR_OVERFLOW_MINUS_INF, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function longIntegerSubtract:", "the difference would exceed the maximum long integer size!");
    }
}

// ===========================================================================
// WP34S short-integer engine (borrowed from the WP34S project)
// ===========================================================================

// Helper for add/sub overflow. Only call when signs match (add) / differ (sub).
fn WP34S_calc_overflow(xv: u64, yv: u64, neg: i32) i32 {
    var u: u64 = undefined;
    var i: i32 = undefined;

    switch (shortIntegerMode) {
        SIM_UNSIGN => {
            u = (yv & (shortIntegerSignBit - 1)) +% (xv & (shortIntegerSignBit - 1));
            i = @as(i32, if ((u & shortIntegerSignBit) != 0) 1 else 0) +
                @as(i32, if ((xv & shortIntegerSignBit) != 0) 1 else 0) +
                @as(i32, if ((yv & shortIntegerSignBit) != 0) 1 else 0);
            if (i > 1) {
                // break -> set overflow
            } else return 0;
        },
        SIM_2COMPL => {
            u = xv +% yv;
            if (neg != 0 and u == shortIntegerSignBit) {
                return 0;
            }
            if ((shortIntegerSignBit & u) != 0) {
                // break
            } else if ((xv == shortIntegerSignBit and yv != 0) or (yv == shortIntegerSignBit and xv != 0)) {
                // break
            } else return 0;
        },
        SIM_SIGNMT, SIM_1COMPL => {
            if ((shortIntegerSignBit & (xv +% yv)) != 0) {
                // break
            } else return 0;
        },
        else => {
            displayBugScreen("WP34S_calc_overflow: bad shortIntegerMode");
            return 0;
        },
    }

    setSystemFlag(FLAG_OVERFLOW);
    return 1;
}

pub export fn WP34S_extract_value(val: u64, sign: *i32) callconv(.c) u64 {
    var value: u64 = val & shortIntegerMask;

    if (shortIntegerMode == SIM_UNSIGN) {
        sign.* = 0;
        return value;
    }

    if ((value & shortIntegerSignBit) != 0) {
        sign.* = 1;
        if (shortIntegerMode == SIM_2COMPL) {
            value = 0 -% value;
        } else if (shortIntegerMode == SIM_1COMPL) {
            value = ~value;
        } else { // SIM_SIGNMT
            value ^= shortIntegerSignBit;
        }
    } else {
        sign.* = 0;
    }

    return value & shortIntegerMask;
}

pub export fn WP34S_build_value(x: u64, sign: i32) callconv(.c) i64 {
    const value: u64 = x & shortIntegerMask;

    if (sign == 0 or shortIntegerMode == SIM_UNSIGN) {
        return @bitCast(value);
    }
    if (shortIntegerMode == SIM_2COMPL) {
        return @bitCast((0 -% value) & shortIntegerMask);
    }
    if (shortIntegerMode == SIM_1COMPL) {
        return @bitCast((~value) & shortIntegerMask);
    }
    return @bitCast(value | shortIntegerSignBit);
}

fn WP34S_multiply_with_overflow(multiplier: u64, multiplicand: u64, overflow: *i32) u64 {
    const product: u64 = (multiplier *% multiplicand) & shortIntegerMask;

    if (overflow.* == 0 and multiplicand != 0) {
        const tbm: u64 = if (shortIntegerMode == SIM_UNSIGN) 0 else shortIntegerSignBit;
        if ((product & tbm) != 0 or product / multiplicand != multiplier) {
            overflow.* = 1;
        }
    }
    return product;
}

pub export fn WP34S_intAdd(y: u64, x: u64) callconv(.c) u64 {
    var termXSign: i32 = undefined;
    var termYSign: i32 = undefined;
    const termX = WP34S_extract_value(x, &termXSign);
    const termY = WP34S_extract_value(y, &termYSign);
    var sum: u64 = undefined;
    var overflow: i32 = undefined;

    clearSystemFlag(FLAG_OVERFLOW);
    if (termXSign == termYSign) {
        overflow = WP34S_calc_overflow(termX, termY, termXSign);
    } else {
        overflow = 0;
    }

    if (shortIntegerMode == SIM_SIGNMT) {
        const x2: u64 = if ((x & shortIntegerSignBit) != 0) (0 -% (x ^ shortIntegerSignBit)) else x;
        const y2: u64 = if ((y & shortIntegerSignBit) != 0) (0 -% (y ^ shortIntegerSignBit)) else y;

        if (overflow != 0) {
            setSystemFlag(FLAG_CARRY);
        } else {
            clearSystemFlag(FLAG_CARRY);
        }

        sum = y2 +% x2;
        if ((sum & shortIntegerSignBit) != 0) {
            sum = (0 -% sum) | shortIntegerSignBit;
        }
    } else {
        const maskedSum: u64 = (y +% x) & shortIntegerMask;

        sum = y +% x;

        if (maskedSum < (y & shortIntegerMask)) {
            setSystemFlag(FLAG_CARRY);
            if (shortIntegerMode == SIM_1COMPL) {
                sum +%= 1;
            }
        } else {
            clearSystemFlag(FLAG_CARRY);
        }
    }
    return sum & shortIntegerMask;
}

pub export fn WP34S_intSubtract(y: u64, x: u64) callconv(.c) u64 {
    var termXSign: i32 = undefined;
    var termYSign: i32 = undefined;
    const termX = WP34S_extract_value(x, &termXSign);
    const termY = WP34S_extract_value(y, &termYSign);
    var difference: u64 = undefined;

    clearSystemFlag(FLAG_OVERFLOW);
    if (termXSign != termYSign) {
        _ = WP34S_calc_overflow(termX, termY, termYSign);
    }

    if (shortIntegerMode == SIM_SIGNMT) {
        if ((termXSign == 0 and termYSign == 0 and termX > termY) or (termXSign != 0 and termYSign != 0 and termX < termY)) {
            setSystemFlag(FLAG_CARRY);
        } else {
            clearSystemFlag(FLAG_CARRY);
        }

        const x2: u64 = if ((x & shortIntegerSignBit) != 0) (0 -% (x ^ shortIntegerSignBit)) else x;
        const y2: u64 = if ((y & shortIntegerSignBit) != 0) (0 -% (y ^ shortIntegerSignBit)) else y;

        difference = y2 -% x2;
        if ((difference & shortIntegerSignBit) != 0) {
            difference = (0 -% difference) | shortIntegerSignBit;
        }
    } else {
        difference = y -% x;

        if (y < x) {
            setSystemFlag(FLAG_CARRY);
            if (shortIntegerMode == SIM_UNSIGN) {
                setSystemFlag(FLAG_OVERFLOW);
            }
            if (shortIntegerMode == SIM_1COMPL) {
                difference -%= 1;
            }
        } else {
            clearSystemFlag(FLAG_CARRY);
        }
    }
    return difference & shortIntegerMask;
}

pub export fn WP34S_intMultiply(y: u64, x: u64) callconv(.c) u64 {
    var multiplicandSign: i32 = undefined;
    var multiplierSign: i32 = undefined;
    const multiplicand = WP34S_extract_value(x, &multiplicandSign);
    const multiplier = WP34S_extract_value(y, &multiplierSign);
    var overflow: i32 = 0;

    const product = WP34S_multiply_with_overflow(multiplier, multiplicand, &overflow);

    if (overflow != 0) {
        setSystemFlag(FLAG_OVERFLOW);
    } else {
        clearSystemFlag(FLAG_OVERFLOW);
    }

    if (shortIntegerMode == SIM_UNSIGN) {
        return product;
    }
    return @bitCast(WP34S_build_value(product & ~shortIntegerSignBit, multiplicandSign ^ multiplierSign));
}

pub export fn WP34S_intDivide(y: u64, x: u64) callconv(.c) u64 {
    var divisorSign: i32 = undefined;
    var dividendSign: i32 = undefined;
    const divisor = WP34S_extract_value(x, &divisorSign);
    const dividend = WP34S_extract_value(y, &dividendSign);

    if (divisor == 0) {
        if (dividend == 0) {
            displayCalcErrorMessage(ERROR_BAD_TIME_OR_DATE_INPUT, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnError("In function WP34S_intDivide: cannot divide 0 by 0!", null);
        } else if (dividendSign != 0) {
            displayCalcErrorMessage(ERROR_BAD_TIME_OR_DATE_INPUT, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnError("In function WP34S_intDivide: cannot divide a negative short integer by 0!", null);
        } else {
            displayCalcErrorMessage(ERROR_BAD_TIME_OR_DATE_INPUT, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnError("In function WP34S_intDivide: cannot divide a positive short integer by 0!", null);
        }
        return 0;
    }

    clearSystemFlag(FLAG_OVERFLOW);
    const quotient: u64 = (dividend / divisor) & shortIntegerMask;
    // Set carry if there is a remainder
    if (quotient *% divisor != dividend) {
        setSystemFlag(FLAG_CARRY);
    } else {
        clearSystemFlag(FLAG_CARRY);
    }

    if (shortIntegerMode != SIM_UNSIGN) {
        if ((quotient & shortIntegerSignBit) != 0) {
            setSystemFlag(FLAG_CARRY);
        }
        // Special case for 0x8000...00 / -1 in 2's complement
        if (shortIntegerMode == SIM_2COMPL and divisorSign != 0 and divisor == 1 and y == shortIntegerSignBit) {
            setSystemFlag(FLAG_OVERFLOW);
        }
    }
    return @bitCast(WP34S_build_value(quotient, divisorSign ^ dividendSign));
}

pub export fn WP34S_int_gcd(a_in: u64, b_in: u64) callconv(.c) u64 {
    var a = a_in;
    var b = b_in;
    while (b != 0) {
        const t = b;
        b = a % b;
        a = t;
    }
    return a;
}

pub export fn WP34S_intGCD(y: u64, x: u64) callconv(.c) u64 {
    var s: i32 = undefined;
    const xv = WP34S_extract_value(x, &s);
    const yv = WP34S_extract_value(y, &s);
    var gcd: u64 = undefined;

    if (xv == 0) {
        gcd = yv;
    } else if (yv == 0) {
        gcd = xv;
    } else {
        gcd = WP34S_int_gcd(xv, yv);
    }
    return @bitCast(WP34S_build_value(gcd, 0));
}

pub export fn WP34S_intLCM(y: u64, x: u64) callconv(.c) u64 {
    var s: i32 = undefined;
    const xv = WP34S_extract_value(x, &s);
    const yv = WP34S_extract_value(y, &s);

    if (xv == 0 or yv == 0) {
        return 0;
    }

    const gcd = WP34S_int_gcd(xv, yv);
    return WP34S_intMultiply((xv / gcd) & shortIntegerMask, @bitCast(WP34S_build_value(yv, 0)));
}

pub export fn WP34S_intChs(x: u64) callconv(.c) u64 {
    var signValue: i32 = undefined;
    const value = WP34S_extract_value(x, &signValue);

    if (shortIntegerMode == SIM_UNSIGN or (shortIntegerMode == SIM_2COMPL and x == shortIntegerSignBit)) {
        temporaryInformation = TI_DATA_NEG_OVRFL;
        setSystemFlag(FLAG_OVERFLOW);
        return (0 -% value) & shortIntegerMask;
    }

    clearSystemFlag(FLAG_OVERFLOW);
    return @bitCast(WP34S_build_value(value, if (signValue != 0) 0 else 1));
}

pub export fn WP34S_intSqrt(x: u64) callconv(.c) u64 {
    var signValue: i32 = undefined;
    const value = WP34S_extract_value(x, &signValue);
    var nn0: u64 = undefined;
    var nn1: u64 = undefined;

    if (signValue != 0) {
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function WP34S_intSqrt: Cannot extract the square root of a negative short integer!", null);
        return 0;
    }
    if (value == 0) {
        nn1 = 0;
    } else {
        nn0 = value / 2 + 1;
        nn1 = value / nn0 + nn0 / 2;
        while (nn1 < nn0) {
            nn0 = nn1;
            nn1 = (nn0 + value / nn0) / 2;
        }
        nn0 = nn1 *% nn1;
        if (nn0 > value) {
            nn1 -%= 1;
        }

        if (nn0 != value) {
            setSystemFlag(FLAG_CARRY);
        } else {
            clearSystemFlag(FLAG_CARRY);
        }
    }
    return @bitCast(WP34S_build_value(nn1, signValue));
}

pub export fn WP34S_intAbs(x: u64) callconv(.c) u64 {
    var signValue: i32 = undefined;
    const value = WP34S_extract_value(x, &signValue);

    clearSystemFlag(FLAG_OVERFLOW);
    if (shortIntegerMode == SIM_2COMPL and x == shortIntegerSignBit) {
        setSystemFlag(FLAG_OVERFLOW);
        return x;
    }
    return @bitCast(WP34S_build_value(value, 0));
}

pub export fn WP34S_intSign(x: u64) callconv(.c) u64 {
    var signValue: i32 = undefined;
    var value = WP34S_extract_value(x, &signValue);

    if (value == 0) {
        signValue = 0;
    } else {
        value = 1;
    }
    return @bitCast(WP34S_build_value(value, signValue));
}

fn WP34S_int_power_helper(base_in: u64, exponent_in: u64, overflow_in: i32) u64 {
    var base = base_in;
    var exponent = exponent_in;
    var overflow = overflow_in;
    var power: u64 = 1;
    var i: u32 = 0;
    var overflow_next: i32 = 0;

    while (i < shortIntegerWordSize and exponent != 0) : (i += 1) {
        if ((exponent & 1) != 0) {
            if (overflow_next != 0) {
                overflow = 1;
            }
            power = WP34S_multiply_with_overflow(power, base, &overflow);
        }
        exponent >>= 1;

        if (exponent != 0) {
            base = WP34S_multiply_with_overflow(base, base, &overflow_next);
        }
    }

    if (overflow != 0) {
        setSystemFlag(FLAG_OVERFLOW);
    } else {
        clearSystemFlag(FLAG_OVERFLOW);
    }

    return power;
}

pub export fn WP34S_intPower(b: u64, e: u64) callconv(.c) u64 {
    var exponentSign: i32 = undefined;
    var baseSign: i32 = undefined;
    const exponent = WP34S_extract_value(e, &exponentSign);
    const base = WP34S_extract_value(b, &baseSign);

    if (exponent == 0 and base == 0) {
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function WP34S_intPower: Cannot calculate 0^0!", null);
        setSystemFlag(FLAG_OVERFLOW);
        return 0;
    }
    clearSystemFlag(FLAG_CARRY);
    clearSystemFlag(FLAG_OVERFLOW);

    if (exponent == 0) {
        return 1;
    } else if (base == 0) {
        return 0;
    }

    const powerSign: i32 = if (baseSign != 0 and (exponent & 1) != 0) 1 else 0; // sign of the result
    return @bitCast(WP34S_build_value(WP34S_int_power_helper(base, exponent, 0), powerSign));
}

pub export fn WP34S_int2pow(x: u64) callconv(.c) u64 {
    var signExponent: i32 = undefined;
    const exponent = WP34S_extract_value(x, &signExponent);
    var wordSize: u32 = shortIntegerWordSize;

    clearSystemFlag(FLAG_OVERFLOW);
    if (signExponent != 0 and exponent == 1) {
        setSystemFlag(FLAG_CARRY);
    } else {
        clearSystemFlag(FLAG_CARRY);
    }

    if (signExponent != 0 and exponent != 0) {
        return 0;
    }

    if (shortIntegerMode != SIM_UNSIGN) {
        wordSize -= 1;
    }
    if (exponent >= wordSize) {
        if (exponent == wordSize) {
            setSystemFlag(FLAG_CARRY);
        } else {
            clearSystemFlag(FLAG_CARRY);
        }
        setSystemFlag(FLAG_OVERFLOW);
        return 0;
    }
    return @as(u64, 1) << @as(u6, @truncate(exponent & 0xff));
}

pub export fn WP34S_int10pow(x: u64) callconv(.c) u64 {
    var sx: i32 = undefined;
    const exponent = WP34S_extract_value(x, &sx);
    var overflow: i32 = 0;

    clearSystemFlag(FLAG_CARRY);
    if (exponent == 0) {
        clearSystemFlag(FLAG_OVERFLOW);
        return 1;
    }

    if (sx != 0) {
        setSystemFlag(FLAG_CARRY);
        return 0;
    }

    if (shortIntegerWordSize <= 3 or (shortIntegerMode != SIM_UNSIGN and shortIntegerWordSize == 4)) {
        overflow = 1;
    }
    return @bitCast(WP34S_build_value(WP34S_int_power_helper(10, x, overflow), 0));
}

pub export fn WP34S_intLog2(x: u64) callconv(.c) u64 {
    var signValue: i32 = undefined;
    var value = WP34S_extract_value(x, &signValue);
    var log2: u32 = 0;

    if (value == 0 or signValue != 0) {
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function WP34S_intLog2: argument must be > 0!", null);
        return 0;
    }

    if ((value & (value - 1)) != 0) {
        setSystemFlag(FLAG_CARRY);
    } else {
        clearSystemFlag(FLAG_CARRY);
    }

    value >>= 1;
    while (value != 0) : (value >>= 1) {
        log2 += 1;
    }

    return @bitCast(WP34S_build_value(log2, signValue));
}

pub export fn WP34S_intLog10(x: u64) callconv(.c) u64 {
    var signValue: i32 = undefined;
    var value = WP34S_extract_value(x, &signValue);
    var r: i32 = 0;
    var c: i32 = 0;

    if (value == 0 or signValue != 0) {
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function WP34S_intLog10: argument must be > 0!", null);
        return 0;
    }

    while (value >= 10) {
        r += 1;
        if (value % 10 != 0) {
            c = 1;
        }
        value /= 10;
    }

    if (c != 0 or value != 1) {
        setSystemFlag(FLAG_CARRY);
    } else {
        clearSystemFlag(FLAG_CARRY);
    }

    return @bitCast(WP34S_build_value(@intCast(r), signValue));
}

pub export fn WP34S_mulmod(a: u64, b: u64, c: u64) callconv(.c) u64 {
    const x: u128 = @as(u128, a) * @as(u128, b);
    return @intCast(x % c);
}

pub export fn WP34S_expmod(a: u64, b_in: u64, c: u64) callconv(.c) u64 {
    var b = b_in;
    var x: u64 = 1;
    var y: u64 = a;
    while (b > 0) {
        if ((b & 1) != 0) {
            x = WP34S_mulmod(x, y, c);
        }
        y = WP34S_mulmod(y, y, c);
        b /= 2;
    }
    return x % c;
}
