// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/mathematics/algdep.c: x->POLY (fnAlgdep) and V->SUM=0
// (fnLindep), algebraic number identification by exact-integer LLL, and the
// algdepPolynomialString() the display draws on the X line while
// TI_ALGDEP_POLY holds. Covered by algdep_cov.txt, algfunc_gen.txt,
// algfunc_cub.txt and algfunc_fp.txt.
//
// A register value is exactly N/10^k for an integer N of at most 34 digits, so
// the lattice entries and the residual check are both exact and no decNumber
// arithmetic appears below the input parse. That removes the rounding question
// entirely and keeps the shared contexts untouched.
//
// OPTION_ALGDEP is #undef'd in the block common to DM42 packages 1-4. There the
// two commands are empty stubs and the polynomial string is "", and nothing
// below is emitted: items.zig binds the two rows to itemToBeCoded and
// softmenus.zig strikes them out.
//
// The lattice arithmetic calls GMP's raw mul, add and sub, as the C does. Every
// entry is bounded by ALGDEP_SCALE and ALGDEP_MAX_DEGREE (the Gram determinants
// run to about 2*ALGDEP_SCALE digits whatever the degree) and the reduction by
// ALGDEP_GUARD, so no intermediate approaches MAX_LONG_INTEGER_SIZE_IN_BITS,
// and the checked operators' overflow refusal would be one upstream never
// raises.

const std = @import("std");
const abi = @import("abi");
const runtime = @import("command_wrappers/runtime.zig");
const math_real_predicates = @import("compare/real_predicates.zig");

const option_algdep: bool = runtime.option_algdep;

const real_t = runtime.real_t;
const real34_t = runtime.real34_t;
const real34Matrix_t = runtime.real34Matrix_t;
const mpz_struct = abi.Mpz;

const REGISTER_X = runtime.REGISTER_X;
const REGISTER_Y = runtime.REGISTER_Y;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const NIM_REGISTER_LINE = runtime.REGISTER_X; // defines.h: MUST be REGISTER_X
const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN = runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN;
const ERROR_INVALID_DATA_TYPE_FOR_OP = runtime.ERROR_INVALID_DATA_TYPE_FOR_OP;
const ERROR_OUT_OF_RANGE = runtime.ERROR_OUT_OF_RANGE;
const ERROR_RAM_FULL = runtime.ERROR_RAM_FULL;
const ERROR_NO_ROOT_FOUND: u8 = 20; // defines.h
const TI_ALGDEP_POLY: u8 = 147; // defines.h
const dtReal34 = runtime.dtReal34;
const dtReal34Matrix = runtime.dtReal34Matrix;
const amNone = runtime.amNone;

const displayCalcErrorMessage = runtime.displayCalcErrorMessage;
const moreInfoOnError = runtime.moreInfoOnError;
const extra_info_on_calc_error = runtime.extra_info_on_calc_error;
const realIsSpecial = math_real_predicates.realIsSpecial;
const exitKeyWaiting = abi.host.exitKeyWaiting;

extern fn decNumberToString(source: *const real_t, destination: [*]u8) [*]u8;
extern fn convertLongIntegerToReal34(source: *mpz_struct, destination: *real34_t) void;

// algdep.h
//
// Highest degree the lattice is allowed to reach. Bounds the GMP working set,
// which grows with the square of the degree: measured 800 bytes at degree 1 and
// 9216 at degree 10 on a refusal sweep, beside the fixed lattice frame in the
// arena. A 34 digit input cannot support a useful relation past degree 8 in any
// case.
const ALGDEP_MAX_DEGREE: i32 = 10;
// Decimal scale factor exponent: lattice column holds nint(10^ALGDEP_SCALE * x^i).
// The Gram determinants run to about 2*ALGDEP_SCALE digits regardless of degree,
// which is what keeps the working set flat.
const ALGDEP_SCALE: u32 = 30;
// Digits of margin a candidate must clear before it is reported: the confidence
// less the digits the relation itself takes to specify. Zero false positives over
// 400 pseudo random 34 digit values swept to degree 6.
const ALGDEP_MARGIN: i32 = 8;
// Ceiling on the confidence, and so on the margin. A 34 digit register value is
// a RATIONAL, so an exact integer relation among its powers always exists at some
// height; treating a zero residual as infinite confidence would report that
// relation instead of refusing. The input carries 34 digits and no verification
// can be worth more than the data behind it.
const ALGDEP_MAX_CONFIDENCE: i32 = 34;

const ALGDEP_MAX_VECTORS: usize = ALGDEP_MAX_DEGREE + 1;
const ALGDEP_MAX_COLS: usize = ALGDEP_MAX_DEGREE + 2;
const ALGDEP_POLY_LEN: usize = 96;

// LLL's potential bounds the swap count. Blowing this means an intermediate
// divided inexactly, which GMP does not flag, so the reduction would otherwise
// spin forever. A hang on a handheld is indistinguishable from a dead
// calculator: fail loudly instead.
inline fn algdepGuard(n: i32) i64 {
    return 20000 * @as(i64, n);
}

// ---------------------------------------------------------------------------
// GMP long integer (mpz). The mpz_* names are header macros / inline wrappers;
// the linkable symbols are __gmpz_*. The "unsigned long int" arguments are
// genuine c_ulong in the ABI; every value handed to one here is a u32 (an
// exponent, a base, a degree), which widens on LP64 and LLP64 alike.
// ---------------------------------------------------------------------------
extern fn __gmpz_init(op: *mpz_struct) void;
extern fn __gmpz_clear(op: *mpz_struct) void;
extern fn __gmpz_set(rop: *mpz_struct, op: *const mpz_struct) void;
extern fn __gmpz_set_ui(rop: *mpz_struct, op: c_ulong) void;
extern fn __gmpz_set_str(rop: *mpz_struct, str: [*:0]const u8, base: c_int) c_int;
extern fn __gmpz_get_str(str: [*]u8, base: c_int, op: *const mpz_struct) [*]u8;
extern fn __gmpz_add(rop: *mpz_struct, op1: *const mpz_struct, op2: *const mpz_struct) void;
extern fn __gmpz_sub(rop: *mpz_struct, op1: *const mpz_struct, op2: *const mpz_struct) void;
extern fn __gmpz_mul(rop: *mpz_struct, op1: *const mpz_struct, op2: *const mpz_struct) void;
extern fn __gmpz_mul_ui(rop: *mpz_struct, op1: *const mpz_struct, op2: c_ulong) void;
extern fn __gmpz_mul_2exp(rop: *mpz_struct, op1: *const mpz_struct, op2: c_ulong) void;
extern fn __gmpz_neg(rop: *mpz_struct, op: *const mpz_struct) void;
extern fn __gmpz_abs(rop: *mpz_struct, op: *const mpz_struct) void;
extern fn __gmpz_fdiv_q(q: *mpz_struct, n: *const mpz_struct, d: *const mpz_struct) void;
extern fn __gmpz_divexact(q: *mpz_struct, n: *const mpz_struct, d: *const mpz_struct) void;
extern fn __gmpz_swap(rop1: *mpz_struct, rop2: *mpz_struct) void;
extern fn __gmpz_cmp(op1: *const mpz_struct, op2: *const mpz_struct) c_int;
extern fn __gmpz_cmp_ui(op1: *const mpz_struct, op2: c_ulong) c_int;
extern fn __gmpz_gcd(rop: *mpz_struct, op1: *const mpz_struct, op2: *const mpz_struct) void;
extern fn __gmpz_pow_ui(rop: *mpz_struct, base: *const mpz_struct, exp: c_ulong) void;
extern fn __gmpz_ui_pow_ui(rop: *mpz_struct, base: c_ulong, exp: c_ulong) void;
extern fn __gmpz_sizeinbase(op: *const mpz_struct, base: c_int) usize;

// The three growth operations, raw as the C's are (see the header note). Each
// lives in exactly one wrapper so the raw-call gate has one site to explain.
fn mpzMul(rop: *mpz_struct, op1: *const mpz_struct, op2: *const mpz_struct) void {
    __gmpz_mul(rop, op1, op2);
}
fn mpzAdd(rop: *mpz_struct, op1: *const mpz_struct, op2: *const mpz_struct) void {
    __gmpz_add(rop, op1, op2);
}
fn mpzSub(rop: *mpz_struct, op1: *const mpz_struct, op2: *const mpz_struct) void {
    __gmpz_sub(rop, op1, op2);
}

// mpz_sgn is a gmp.h macro over _mp_size.
inline fn mpzSgn(op: *const mpz_struct) i32 {
    return if (op._mp_size < 0) -1 else if (op._mp_size > 0) 1 else 0;
}
inline fn mpzSet(rop: *mpz_struct, op: *const mpz_struct) void {
    __gmpz_set(rop, op);
}
inline fn mpzSetUi(rop: *mpz_struct, op: u32) void {
    __gmpz_set_ui(rop, op);
}
inline fn mpzMulUi(rop: *mpz_struct, op1: *const mpz_struct, op2: u32) void {
    __gmpz_mul_ui(rop, op1, op2);
}
inline fn mpzMul2exp(rop: *mpz_struct, op1: *const mpz_struct, op2: u32) void {
    __gmpz_mul_2exp(rop, op1, op2);
}
inline fn mpzNeg(rop: *mpz_struct, op: *const mpz_struct) void {
    __gmpz_neg(rop, op);
}
inline fn mpzAbs(rop: *mpz_struct, op: *const mpz_struct) void {
    __gmpz_abs(rop, op);
}
inline fn mpzFdivQ(q: *mpz_struct, n: *const mpz_struct, d: *const mpz_struct) void {
    __gmpz_fdiv_q(q, n, d);
}
inline fn mpzDivexact(q: *mpz_struct, n: *const mpz_struct, d: *const mpz_struct) void {
    __gmpz_divexact(q, n, d);
}
inline fn mpzSwap(rop1: *mpz_struct, rop2: *mpz_struct) void {
    __gmpz_swap(rop1, rop2);
}
inline fn mpzCmp(op1: *const mpz_struct, op2: *const mpz_struct) i32 {
    return __gmpz_cmp(op1, op2);
}
inline fn mpzCmpUi(op1: *const mpz_struct, op2: u32) i32 {
    return __gmpz_cmp_ui(op1, op2);
}
inline fn mpzPowUi(rop: *mpz_struct, base: *const mpz_struct, exp: u32) void {
    __gmpz_pow_ui(rop, base, exp);
}

// longIntegerType.h inlines.
inline fn longIntegerInit(op: *mpz_struct) void {
    __gmpz_init(op);
}
inline fn longIntegerFree(op: *mpz_struct) void {
    __gmpz_clear(op);
}
inline fn longIntegerChangeSign(op: *mpz_struct) void {
    op._mp_size = -op._mp_size;
}
inline fn longIntegerPowerUIntUInt(base: u32, exponent: u32, result: *mpz_struct) void {
    __gmpz_ui_pow_ui(result, base, exponent);
}
inline fn longIntegerBase10Digits(op: *const mpz_struct) i32 {
    return @intCast(__gmpz_sizeinbase(op, 10));
}
inline fn longIntegerGcd(op1: *const mpz_struct, op2: *const mpz_struct, result: *mpz_struct) void {
    __gmpz_gcd(result, op1, op2);
}
inline fn stringToLongInteger(source: [*:0]const u8, destination: *mpz_struct) void {
    _ = __gmpz_set_str(destination, source, 10);
}
inline fn longIntegerToString(source: *const mpz_struct, destination: [*]u8) void {
    _ = __gmpz_get_str(destination, 10, source);
}

// realType.h's int32ToReal34, through a local so the register slot's block
// alignment is never a question.
inline fn int32ToReal34(source: i32, destination: *align(1) real34_t) void {
    var value: real34_t = undefined;
    _ = runtime.decQuadFromInt32(&value, source);
    destination.* = value;
}

inline fn ix(value: anytype) usize {
    return @intCast(value);
}

// ---------------------------------------------------------------------------
// The lattice
// ---------------------------------------------------------------------------
const Lattice = extern struct {
    b: [ALGDEP_MAX_VECTORS][ALGDEP_MAX_COLS]mpz_struct,
    d: [ALGDEP_MAX_VECTORS + 1]mpz_struct,
    lam: [ALGDEP_MAX_VECTORS + 1][ALGDEP_MAX_VECTORS + 1]mpz_struct,
    t0: mpz_struct,
    t1: mpz_struct,
    t2: mpz_struct,
    t3: mpz_struct,
    dotProd: mpz_struct,
    dotAcc: mpz_struct,
    coeff: [ALGDEP_MAX_VECTORS]mpz_struct,
    powN: [ALGDEP_MAX_VECTORS]mpz_struct, // N^i, or the scaled vector entries under LINDEP
    p10: [ALGDEP_MAX_VECTORS]mpz_struct, // 10^(kdec*(degree-i)), or the per-entry denominators under LINDEP
    n: i16,
    m: i16,
};

// Every member up to n/m is a longInteger_t laid out contiguously, so one flat
// pass initialises and clears them all.
const ALGDEP_MPZ_COUNT: usize = @offsetOf(Lattice, "n") / @sizeOf(mpz_struct);

var algdepPoly: [ALGDEP_POLY_LEN]u8 = @splat(0);

// The recovered relation rendered as x^3 - x - 1, for the temporary information
// line. Empty until a search succeeds.
pub export fn algdepPolynomialString() linksection(runtime.code_section) callconv(.c) [*:0]const u8 {
    if (comptime !option_algdep) {
        return "";
    }
    return @ptrCast(&algdepPoly);
}

// ------------------------------------------------------------ lattice lifetime

// TO_BLOCKS (defines.h): BYTES_PER_BLOCK is 4.
inline fn toBlocks(bytes: usize) usize {
    return (bytes + 3) >> 2;
}

// The arena hands out 4-byte blocks and the frame is the C's sizeof, exactly, on
// the 32-bit firmware where an mpz wants no more. A 64-bit host's mpz carries a
// pointer and wants 8, so one extra block pays for aligning the frame inside its
// allocation there.
const lattice_blocks: usize = toBlocks(@sizeOf(Lattice)) + (if (@alignOf(Lattice) > 4) @as(usize, 1) else 0);

const LatticeFrame = struct {
    raw: *anyopaque,
    lattice: *Lattice,
};

fn latticeAlloc() ?LatticeFrame {
    const raw = runtime.allocC47Blocks(lattice_blocks) orelse {
        displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE);
        return null;
    };
    const lattice: *Lattice = @ptrFromInt(std.mem.alignForward(usize, @intFromPtr(raw), @alignOf(Lattice)));
    const members: [*]mpz_struct = @ptrCast(lattice);
    for (members[0..ALGDEP_MPZ_COUNT]) |*member| {
        longIntegerInit(member);
    }
    return .{ .raw = raw, .lattice = lattice };
}

// Every mpz_init above needs its mpz_clear on every exit path: the test suite
// fails the run on a GMP leak through gmpMemInBytes.
fn latticeFree(frame: LatticeFrame) void {
    const members: [*]mpz_struct = @ptrCast(frame.lattice);
    for (members[0..ALGDEP_MPZ_COUNT]) |*member| {
        longIntegerFree(member);
    }
    runtime.freeC47Blocks(frame.raw, lattice_blocks);
}

// ------------------------------------------------ integral LLL, Cohen 2.6.7

// Uses its own product and accumulator. The Gram-Schmidt block passes t0 as the
// destination, so aliasing the scratch here makes divexact divide inexactly and
// the reduction never terminates.
fn latticeDot(L: *Lattice, r: *mpz_struct, i: i32, j: i32) void {
    mpzSetUi(&L.dotAcc, 0);
    var t: i32 = 0;
    while (t < L.m) : (t += 1) {
        mpzMul(&L.dotProd, &L.b[ix(i - 1)][ix(t)], &L.b[ix(j - 1)][ix(t)]);
        mpzAdd(&L.dotAcc, &L.dotAcc, &L.dotProd);
    }
    mpzSet(r, &L.dotAcc);
}

fn latticeReduceStep(L: *Lattice, k: i32, l: i32) void {
    mpzAbs(&L.t0, &L.lam[ix(k)][ix(l)]);
    mpzMul2exp(&L.t0, &L.t0, 1);
    if (mpzCmp(&L.t0, &L.d[ix(l)]) <= 0) {
        return;
    }

    mpzMul2exp(&L.t1, &L.lam[ix(k)][ix(l)], 1); // q = nint(lam[k][l] / d[l]), by floor((2*lam + d) / (2*d))
    mpzAdd(&L.t1, &L.t1, &L.d[ix(l)]);
    mpzMul2exp(&L.t2, &L.d[ix(l)], 1);
    mpzFdivQ(&L.t1, &L.t1, &L.t2);

    var t: i32 = 0;
    while (t < L.m) : (t += 1) {
        mpzMul(&L.t0, &L.t1, &L.b[ix(l - 1)][ix(t)]);
        mpzSub(&L.b[ix(k - 1)][ix(t)], &L.b[ix(k - 1)][ix(t)], &L.t0);
    }
    mpzMul(&L.t0, &L.t1, &L.d[ix(l)]);
    mpzSub(&L.lam[ix(k)][ix(l)], &L.lam[ix(k)][ix(l)], &L.t0);
    var i: i32 = 1;
    while (i <= l - 1) : (i += 1) {
        mpzMul(&L.t0, &L.t1, &L.lam[ix(l)][ix(i)]);
        mpzSub(&L.lam[ix(k)][ix(i)], &L.lam[ix(k)][ix(i)], &L.t0);
    }
}

fn latticeSwap(L: *Lattice, k: i32, kmax: i32) void {
    var t: i32 = 0;
    while (t < L.m) : (t += 1) {
        mpzSwap(&L.b[ix(k - 1)][ix(t)], &L.b[ix(k - 2)][ix(t)]);
    }
    var j: i32 = 1;
    while (j <= k - 2) : (j += 1) {
        mpzSwap(&L.lam[ix(k)][ix(j)], &L.lam[ix(k - 1)][ix(j)]);
    }

    mpzMul(&L.t0, &L.d[ix(k - 2)], &L.d[ix(k)]); // t0 = (d[k-2]*d[k] + lam^2) / d[k-1], the new d[k-1]
    mpzMul(&L.t1, &L.lam[ix(k)][ix(k - 1)], &L.lam[ix(k)][ix(k - 1)]);
    mpzAdd(&L.t0, &L.t0, &L.t1);
    mpzDivexact(&L.t0, &L.t0, &L.d[ix(k - 1)]);

    var i: i32 = k + 1;
    while (i <= kmax) : (i += 1) {
        mpzSet(&L.t1, &L.lam[ix(i)][ix(k)]);
        mpzMul(&L.t2, &L.d[ix(k)], &L.lam[ix(i)][ix(k - 1)]);
        mpzMul(&L.t3, &L.lam[ix(k)][ix(k - 1)], &L.t1);
        mpzSub(&L.t2, &L.t2, &L.t3);
        mpzDivexact(&L.lam[ix(i)][ix(k)], &L.t2, &L.d[ix(k - 1)]);
        mpzMul(&L.t2, &L.t0, &L.t1);
        mpzMul(&L.t3, &L.lam[ix(k)][ix(k - 1)], &L.lam[ix(i)][ix(k)]); // deliberately the new lam[i][k]
        mpzAdd(&L.t2, &L.t2, &L.t3);
        mpzDivexact(&L.lam[ix(i)][ix(k - 1)], &L.t2, &L.d[ix(k)]);
    }
    mpzSet(&L.d[ix(k - 1)], &L.t0);
}

// Returns false on dependent input or on a guard trip; d[k] == 0 cannot arise
// from the fnAlgdep lattice, whose identity block makes the rows independent.
fn latticeReduce(L: *Lattice) bool {
    const n: i32 = L.n;
    var k: i32 = 2;
    var kmax: i32 = 1;
    var guard: i64 = 0;

    mpzSetUi(&L.d[0], 1);
    latticeDot(L, &L.d[1], 1, 1);
    if (mpzSgn(&L.d[1]) == 0) {
        return false;
    }

    while (k <= n) {
        if (k > kmax) {
            kmax = k;
            var j: i32 = 1;
            while (j <= k) : (j += 1) {
                latticeDot(L, &L.t0, k, j);
                var i: i32 = 1;
                while (i <= j - 1) : (i += 1) {
                    mpzMul(&L.t1, &L.d[ix(i)], &L.t0);
                    mpzMul(&L.t2, &L.lam[ix(k)][ix(i)], &L.lam[ix(j)][ix(i)]);
                    mpzSub(&L.t1, &L.t1, &L.t2);
                    mpzDivexact(&L.t0, &L.t1, &L.d[ix(i - 1)]);
                }
                if (j < k) {
                    mpzSet(&L.lam[ix(k)][ix(j)], &L.t0);
                } else {
                    mpzSet(&L.d[ix(k)], &L.t0);
                }
            }
            if (mpzSgn(&L.d[ix(k)]) == 0) {
                return false;
            }
        }

        while (true) {
            guard += 1;
            if (guard > algdepGuard(n)) { // counted here and not in the outer loop: consecutive swaps cycle in this loop alone, so a
                return false; // corrupted lattice would spin here without the outer loop ever seeing it
            }
            latticeReduceStep(L, k, k - 1);
            mpzMul(&L.t0, &L.d[ix(k)], &L.d[ix(k - 2)]); // swap when 4*d[k]*d[k-2] < 3*d[k-1]^2 - 4*lam[k][k-1]^2
            mpzMul2exp(&L.t0, &L.t0, 2);
            mpzMul(&L.t1, &L.d[ix(k - 1)], &L.d[ix(k - 1)]);
            mpzMulUi(&L.t1, &L.t1, 3);
            mpzMul(&L.t2, &L.lam[ix(k)][ix(k - 1)], &L.lam[ix(k)][ix(k - 1)]);
            mpzMul2exp(&L.t2, &L.t2, 2);
            mpzSub(&L.t1, &L.t1, &L.t2);
            if (mpzCmp(&L.t0, &L.t1) < 0) {
                latticeSwap(L, k, kmax);
                k = if (k - 1 > 2) k - 1 else 2;
            } else {
                var l: i32 = k - 2;
                while (l >= 1) : (l -= 1) {
                    latticeReduceStep(L, k, l);
                }
                k += 1;
                break;
            }
        }
    }
    return true;
}

// ------------------------------------------------------------------ input parse

// x = n / 10^k exactly, k >= 0. decNumberToString emits plain decimal or an E
// form; both are handled here rather than assuming the plain one.
fn realToScaledInteger(x: *const real_t, n: *mpz_struct, k: *i32) bool {
    var str: [128]u8 = undefined;
    var digits: [128]u8 = undefined;
    var di: usize = 0;
    var frac: i32 = 0;
    var expo: i32 = 0;
    var expSign: i32 = 1;
    var neg = false;
    var seenDot = false;
    var seenExp = false;

    _ = decNumberToString(x, &str);

    var p: usize = 0;
    if (str[p] == '-') {
        neg = true;
        p += 1;
    } else if (str[p] == '+') {
        p += 1;
    }

    while (str[p] != 0) : (p += 1) {
        const c = str[p];
        if (c == '.') {
            seenDot = true;
            continue;
        }
        if (c == 'E' or c == 'e') {
            seenExp = true;
            p += 1;
            if (str[p] == '-') {
                expSign = -1;
                p += 1;
            } else if (str[p] == '+') {
                p += 1;
            }
            while (str[p] >= '0' and str[p] <= '9') : (p += 1) {
                expo = expo * 10 + @as(i32, str[p] - '0');
            }
            break;
        }
        if (c < '0' or c > '9') {
            return false; // NaN, Infinity, or anything else that is not a finite number
        }
        if (di < digits.len - 1) {
            digits[di] = c;
            di += 1;
        }
        if (seenDot) {
            frac += 1;
        }
    }
    digits[di] = 0;
    if (di == 0) {
        return false;
    }
    if (seenExp) {
        expo *= expSign;
    }

    stringToLongInteger(@ptrCast(&digits), n);
    if (neg) {
        longIntegerChangeSign(n);
    }

    k.* = frac - expo;
    if (k.* < 0) {
        var scale: mpz_struct = undefined;
        longIntegerInit(&scale);
        longIntegerPowerUIntUInt(10, @intCast(-k.*), &scale);
        mpzMul(n, n, &scale);
        longIntegerFree(&scale);
        k.* = 0;
    }
    return true;
}

// ------------------------------------------------------------------- the search

const Outcome = struct {
    found: bool,
    degree: i32,
    margin: i32,
};

// Scores one reduced row against the acceptance rule, common to both commands:
// the i-th value is powN[i]*p10[i], which fnAlgdep fills with N^i and
// 10^(kdec*(degree-i)) and fnLindep fills with the entry and its denominator.
// Sharing it is not only smaller, it is what stops the two paths drifting apart:
// the residual-is-zero case was fixed once in each of them before this existed.
// Reuses t0..t3 and dotProd, which are free once the reduction has finished.
fn scoreCandidate(L: *Lattice, cand: i32, count: i32, marginOut: *i32) bool {
    const residual = &L.t0;
    const typical = &L.t1;
    const height = &L.t2;
    const term = &L.t3;
    const abscoef = &L.dotProd;
    var allZero = true;

    mpzSetUi(residual, 0);
    mpzSetUi(typical, 0);
    mpzSetUi(height, 0);

    var i: i32 = 0;
    while (i < count) : (i += 1) {
        const row = &L.b[ix(cand)][ix(i)];
        if (mpzSgn(row) != 0) {
            allZero = false;
        }
        mpzMul(term, &L.powN[ix(i)], &L.p10[ix(i)]); // the i-th value, scaled to the common denominator

        mpzMul(abscoef, row, term);
        mpzAdd(residual, residual, abscoef); // exact: the relation evaluated at the input, times that denominator

        mpzAbs(abscoef, row);
        mpzAbs(term, term);
        mpzMul(term, term, abscoef);
        mpzAdd(typical, typical, term); // the size a random combination of this height would reach

        mpzAbs(abscoef, row);
        if (mpzCmp(abscoef, height) > 0) {
            mpzSet(height, abscoef);
        }
    }
    if (allZero or mpzSgn(typical) == 0) {
        return false;
    }

    var confidence: i32 = if (mpzSgn(residual) == 0)
        ALGDEP_MAX_CONFIDENCE
    else
        longIntegerBase10Digits(typical) - longIntegerBase10Digits(residual);
    if (confidence > ALGDEP_MAX_CONFIDENCE) {
        confidence = ALGDEP_MAX_CONFIDENCE;
    }

    marginOut.* = confidence - count * longIntegerBase10Digits(height);
    return marginOut.* >= ALGDEP_MARGIN;
}

// Builds the lattice for one degree, reduces it, and tests every reduced row. A
// candidate is reported only when the residual beats a random integer
// combination of the same height by ALGDEP_MARGIN digits more than the relation
// costs to write down.
fn trySingleDegree(L: *Lattice, bigN: *const mpz_struct, kdec: i32, degree: i32, out: *Outcome) void {
    var scale: mpz_struct = undefined;
    var den: mpz_struct = undefined;
    var num: mpz_struct = undefined;
    var quo: mpz_struct = undefined;
    var term: mpz_struct = undefined;

    L.n = @intCast(degree + 1);
    L.m = @intCast(degree + 2);

    longIntegerInit(&scale);
    longIntegerInit(&den);
    longIntegerInit(&num);
    longIntegerInit(&quo);
    longIntegerInit(&term);
    defer {
        longIntegerFree(&scale);
        longIntegerFree(&den);
        longIntegerFree(&num);
        longIntegerFree(&quo);
        longIntegerFree(&term);
    }

    longIntegerPowerUIntUInt(10, ALGDEP_SCALE, &scale);
    var i: i32 = 0;
    while (i <= degree) : (i += 1) { // N^i and 10^(kdec*(degree-i)) depend only on i, so they are built once here and read back in the
        mpzPowUi(&L.powN[ix(i)], bigN, @intCast(i)); // candidate loop below. Recomputing them per candidate cost (degree+1) squared big-integer
        longIntegerPowerUIntUInt(10, @intCast(kdec * (degree - i)), &L.p10[ix(i)]); // exponentiations instead of (degree+1).
    }
    i = 0;
    while (i <= degree) : (i += 1) {
        var j: i32 = 0;
        while (j <= degree) : (j += 1) {
            mpzSetUi(&L.b[ix(i)][ix(j)], if (i == j) 1 else 0);
        }
        longIntegerPowerUIntUInt(10, @intCast(kdec * i), &den);
        mpzMul(&num, &scale, &L.powN[ix(i)]);
        mpzMul2exp(&quo, &num, 1); // nint(num/den)
        mpzAdd(&quo, &quo, &den);
        mpzMul2exp(&term, &den, 1);
        mpzFdivQ(&quo, &quo, &term);
        mpzSet(&L.b[ix(i)][ix(degree + 1)], &quo);
    }

    if (!latticeReduce(L)) {
        return;
    }

    var cand: i32 = 0;
    while (cand <= degree) : (cand += 1) {
        var margin: i32 = 0;
        if (!scoreCandidate(L, cand, degree + 1, &margin)) {
            continue;
        }
        mpzSetUi(&term, 0); // primitive part, then a positive leading coefficient
        i = 0;
        while (i <= degree) : (i += 1) {
            longIntegerGcd(&term, &L.b[ix(cand)][ix(i)], &term);
        }
        i = 0;
        while (i <= degree) : (i += 1) {
            if (mpzSgn(&term) != 0) {
                mpzDivexact(&L.coeff[ix(i)], &L.b[ix(cand)][ix(i)], &term);
            } else {
                mpzSet(&L.coeff[ix(i)], &L.b[ix(cand)][ix(i)]);
            }
        }
        if (mpzSgn(&L.coeff[ix(degree)]) < 0) {
            i = 0;
            while (i <= degree) : (i += 1) {
                mpzNeg(&L.coeff[ix(i)], &L.coeff[ix(i)]);
            }
        }
        out.found = true;
        out.degree = degree;
        out.margin = margin;
        break;
    }
}

// Sweeps upward so the first hit is the minimal polynomial and not a multiple of it.
fn algdepSearch(L: *Lattice, x: *const real_t, maxDegree: i32, out: *Outcome) bool {
    var bigN: mpz_struct = undefined;
    var kdec: i32 = 0;

    out.found = false;
    longIntegerInit(&bigN);
    defer longIntegerFree(&bigN);
    if (!realToScaledInteger(x, &bigN, &kdec)) {
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE);
        if (comptime extra_info_on_calc_error) {
            moreInfoOnError("In function algdepSearch:", "the value in X is not finite.", null, null);
        }
        return false;
    }

    if (mpzSgn(&bigN) == 0) { // zero is the root of x. Its row scores typical == 0, which scoreCandidate cannot tell from an
        mpzSetUi(&L.coeff[0], 0); // empty candidate, so it is answered here instead of being lost in the sweep.
        mpzSetUi(&L.coeff[1], 1);
        out.found = true;
        out.degree = 1;
        out.margin = ALGDEP_MAX_CONFIDENCE;
        return true;
    }

    // A relation of degree d and height H costs (d+1)log10(H) + d*log10|x| digits to specify, and only 34 are available. The magnitude term alone can exceed the
    // budget: for x = 1e400 no degree is possible at all. Testing it here refuses in constant time instead of reducing a lattice to reach the same answer, and it
    // keeps 10^(kdec*i) bounded, which matters because GMP aborts rather than failing when an allocation cannot be met.
    var magnitude: i32 = longIntegerBase10Digits(&bigN) - kdec;
    if (magnitude < 0) {
        magnitude = -magnitude;
    }

    var degree: i32 = 1;
    while (degree <= maxDegree and !out.found) : (degree += 1) {
        if (magnitude > 0 and degree * magnitude > ALGDEP_MAX_CONFIDENCE - ALGDEP_MARGIN) {
            break; // every higher degree is worse, so the sweep is finished
        }
        trySingleDegree(L, &bigN, kdec, degree, out);
        if (exitKeyWaiting()) {
            break;
        }
    }
    return out.found;
}

// ----------------------------------------------------------- polynomial string

// Renders the recovered relation as x^3 - x - 1 rather than a column of numbers.
// Superscript digits and the minus sign are existing two byte glyphs.
fn buildPolynomialString(L: *Lattice, degree: i32) void {
    var number: [64]u8 = undefined;
    var at: usize = 0;
    var first = true;

    algdepPoly[0] = 0;
    var i: i32 = degree;
    while (i >= 0) : (i -= 1) {
        const coeff = &L.coeff[ix(i)];
        if (mpzSgn(coeff) == 0) {
            continue;
        }
        const negative = mpzSgn(coeff) < 0;

        if (first) {
            if (negative) {
                algdepPoly[at] = '-';
                at += 1;
            }
        } else {
            const sign: *const [3]u8 = if (negative) " - " else " + ";
            @memcpy(algdepPoly[at .. at + 3], sign);
            at += 3;
        }

        mpzAbs(&L.t0, coeff);
        if (mpzCmpUi(&L.t0, 1) != 0 or i == 0) { // a unit coefficient is written only when it is the constant term
            longIntegerToString(&L.t0, &number);
            const len = std.mem.indexOfScalar(u8, &number, 0) orelse number.len;
            if (at + len >= ALGDEP_POLY_LEN - 8) {
                at = 0;
                break;
            }
            @memcpy(algdepPoly[at .. at + len], number[0..len]);
            at += len;
        }
        if (i >= 1) {
            if (at + 2 >= ALGDEP_POLY_LEN - 8) {
                at = 0;
                break;
            }
            algdepPoly[at] = 'x';
            at += 1;
        }
        if (i >= 2) { // exponent 1 is implied, so it is never printed
            var sup: [8]u8 = undefined;
            var si: usize = 0;
            const e: usize = ix(i);
            if (e >= 10) {
                sup[si] = 0xa1;
                sup[si + 1] = @intCast(0x60 + e / 10);
                si += 2;
            }
            sup[si] = 0xa1;
            sup[si + 1] = @intCast(0x60 + e % 10);
            si += 2;
            if (at + si >= ALGDEP_POLY_LEN - 2) {
                at = 0;
                break;
            }
            @memcpy(algdepPoly[at .. at + si], sup[0..si]);
            at += si;
        }
        first = false;
    }
    algdepPoly[at] = 0;
}

// ----------------------------------------------------------------- the commands

fn reportNoRelation(function: [*:0]const u8, what: [*:0]const u8) void {
    displayCalcErrorMessage(ERROR_NO_ROOT_FOUND, ERR_REGISTER_LINE);
    if (comptime extra_info_on_calc_error) {
        moreInfoOnError(function, what, "to the precision the input carries.", null);
    }
}

// The result writes deliberately skip adjustResult: its SDIGS rounding would turn
// an exact seven digit coefficient into noise at SDIGS 6, with no error and no
// warning. Nothing else in it applies here either: the result is real, and every
// error path returns before a result is written. The search itself never reads
// significantDigits, so no context needs forcing. algdep_cov.txt pins the
// exactness at SD=6.
pub export fn fnAlgdep(maxDegree: u16) linksection(runtime.code_section) callconv(.c) void {
    if (comptime !option_algdep) {
        return;
    }
    var x: real_t = undefined;
    var out: Outcome = .{ .found = false, .degree = 0, .margin = 0 };

    if (maxDegree < 1 or maxDegree > ALGDEP_MAX_DEGREE) {
        displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE);
        return;
    }
    if (!runtime.getRegisterAsReal(REGISTER_X, &x)) {
        return;
    }
    if (realIsSpecial(&x)) {
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE);
        return;
    }
    if (!runtime.saveLastX()) { // the input is consumed, so LASTx carries it, as fnSlvq's does; a refusal is an error, and runFunction's undo()
        // restores LASTx with the rest of the stack, so on that path LASTx keeps what it had
        return;
    }
    const frame = latticeAlloc() orelse return;
    const L = frame.lattice;

    const found = algdepSearch(L, &x, @intCast(maxDegree), &out);

    if (!found) {
        latticeFree(frame);
        reportNoRelation("In function fnAlgdep:", "no integer polynomial of the requested degree has this value as a root,");
        return;
    }

    buildPolynomialString(L, out.degree);

    // Highest degree first, the coefficient-vector convention SLVP, SLVQ and SLVC read: SLVC consumes X as it stands,
    // and for a quadratic v3->zyx lands a, b, c in Z, Y, X, which is the stack order SLVQ reads.
    var matrix: real34Matrix_t = undefined;
    runtime.liftStack();
    if (runtime.initMatrixRegister(REGISTER_X, 1, @intCast(out.degree + 1), false)) {
        runtime.linkToRealMatrixRegister(REGISTER_X, &matrix);
        const elems = abi.matrixRealElems(matrix);
        var i: i32 = 0;
        while (i <= out.degree) : (i += 1) {
            convertLongIntegerToReal34(&L.coeff[ix(out.degree - i)], &elems[ix(i)]);
        }
        runtime.temporaryInformation = TI_ALGDEP_POLY; // only when the matrix write succeeded, so a RAM full error keeps its message line
    }
    runtime.reallocateRegister(REGISTER_Y, dtReal34, 0, amNone);
    int32ToReal34(out.margin, runtime.registerReal34Ptr(REGISTER_Y));

    latticeFree(frame);
}

// Integer relation over a supplied vector: same kernel, but the lattice column
// carries the vector entries rather than the powers of one value. The result is
// a row, as fnAlgdep's is, whichever way the input vector lay.
pub export fn fnLindep(unused_but_mandatory_parameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    if (comptime !option_algdep) {
        return;
    }
    var matrix: real34Matrix_t = undefined;

    if (runtime.getRegisterDataType(REGISTER_X) != dtReal34Matrix) {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE);
        return;
    }
    runtime.linkToRealMatrixRegister(REGISTER_X, &matrix);
    const elems = abi.matrixRealElems(matrix);

    const count: u16 = if (matrix.header.matrixRows == 1)
        matrix.header.matrixColumns
    else if (matrix.header.matrixColumns == 1)
        matrix.header.matrixRows
    else
        0;
    if (count < 2 or count > ALGDEP_MAX_VECTORS) {
        displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE);
        if (comptime extra_info_on_calc_error) {
            moreInfoOnError("In function fnLindep:", "expects a row or column vector of 2 to 11 elements.", null, null);
        }
        return;
    }
    // The entries are validated before LASTx is written, so a vector carrying a NaN or an infinity refuses with the same domain error and the same untouched
    // stack as fnAlgdep refuses a special scalar. maxK is the common denominator the residual is measured over; the lattice column does not use it.
    var entryN: mpz_struct = undefined;
    longIntegerInit(&entryN);
    var finite = true;
    var maxK: i32 = 0;
    var maxMag: i32 = -0x7FFFFFFF;
    var minMag: i32 = 0x7FFFFFFF;
    var i: u16 = 0;
    while (i < count and finite) : (i += 1) {
        var v: real_t = undefined;
        var k: i32 = undefined;
        runtime.real34ToReal(&elems[i], &v);
        if (realIsSpecial(&v) or !realToScaledInteger(&v, &entryN, &k)) {
            finite = false;
        } else {
            if (k > maxK) {
                maxK = k;
            }
            const mag: i32 = longIntegerBase10Digits(&entryN) - k; // log10 of the entry, not its count of decimal places: 1 and 1.414... are both magnitude 1
            if (mag > maxMag) {
                maxMag = mag;
            }
            if (mag < minMag) {
                minMag = mag;
            }
        }
    }
    longIntegerFree(&entryN);
    if (!finite) {
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE);
        if (comptime extra_info_on_calc_error) {
            moreInfoOnError("In function fnLindep:", "every entry of the vector must be finite.", null, null);
        }
        return;
    }
    if (!runtime.saveLastX()) { // the vector in X is consumed, so LASTx carries it, as fnAlgdep's does; a refusal undoes it the same way
        return;
    }
    // Entries spread over more decades than the digit budget cannot share a relation of any usable height, so this refuses the impossible case and bounds the
    // powers of ten the construction would otherwise follow. It is the fnLindep twin of the magnitude test in algdepSearch; placed here it also spares the
    // lattice allocation.
    if (maxMag - minMag > ALGDEP_MAX_CONFIDENCE - ALGDEP_MARGIN) {
        reportNoRelation("In function fnLindep:", "no integer relation stands out among entries this far apart in magnitude,");
        return;
    }
    const frame = latticeAlloc() orelse return;
    const L = frame.lattice;

    var scale: mpz_struct = undefined;
    var den: mpz_struct = undefined;
    var num: mpz_struct = undefined;
    var quo: mpz_struct = undefined;
    var term: mpz_struct = undefined;
    longIntegerInit(&scale);
    longIntegerInit(&den);
    longIntegerInit(&num);
    longIntegerInit(&quo);
    longIntegerInit(&term);
    longIntegerPowerUIntUInt(10, ALGDEP_SCALE, &scale);

    L.n = @intCast(count);
    L.m = @intCast(count + 1);
    i = 0;
    while (i < count) : (i += 1) {
        var v: real_t = undefined;
        var k: i32 = 0;
        runtime.real34ToReal(&elems[i], &v);
        _ = realToScaledInteger(&v, &L.powN[i], &k); // cannot fail, the entries were validated above; parsed into powN once, the candidate loop reads it back
        longIntegerPowerUIntUInt(10, @intCast(maxK - k), &L.p10[i]);
        var j: u16 = 0;
        while (j < count) : (j += 1) {
            mpzSetUi(&L.b[i][j], if (i == j) 1 else 0);
        }
        longIntegerPowerUIntUInt(10, @intCast(k), &den); // nint(10^S * v_i), exactly as trySingleDegree builds its column: scaling the column any harder
        mpzMul(&num, &scale, &L.powN[i]); // than the identity block stops LLL feeling the cost of a large coefficient, and it then finds
        mpzMul2exp(&quo, &num, 1); // the exact relation that always exists among truncated decimals
        mpzAdd(&quo, &quo, &den);
        mpzMul2exp(&term, &den, 1);
        mpzFdivQ(&quo, &quo, &term);
        mpzSet(&L.b[i][count], &quo);
    }

    var found = false;
    var margin: i32 = 0;
    if (latticeReduce(L)) {
        var cand: u16 = 0;
        while (cand < count and !found) : (cand += 1) {
            if (!scoreCandidate(L, cand, count, &margin)) {
                continue;
            }
            i = 0;
            while (i < count) : (i += 1) {
                mpzSet(&L.coeff[i], &L.b[cand][i]);
            }
            i = 0;
            while (i < count) : (i += 1) { // first non-zero coefficient positive, so the reported relation is deterministic
                if (mpzSgn(&L.coeff[i]) != 0) {
                    if (mpzSgn(&L.coeff[i]) < 0) {
                        var j: u16 = 0;
                        while (j < count) : (j += 1) {
                            mpzNeg(&L.coeff[j], &L.coeff[j]);
                        }
                    }
                    break;
                }
            }
            found = true;
        }
    }

    longIntegerFree(&scale);
    longIntegerFree(&den);
    longIntegerFree(&num);
    longIntegerFree(&quo);
    longIntegerFree(&term);

    if (!found) {
        latticeFree(frame);
        reportNoRelation("In function fnLindep:", "no integer relation stands out among the vector entries,");
        return;
    }

    var result: real34Matrix_t = undefined;
    runtime.liftStack();
    if (runtime.initMatrixRegister(REGISTER_X, 1, count, false)) {
        runtime.linkToRealMatrixRegister(REGISTER_X, &result);
        const resultElems = abi.matrixRealElems(result);
        i = 0;
        while (i < count) : (i += 1) {
            convertLongIntegerToReal34(&L.coeff[i], &resultElems[i]);
        }
    }
    runtime.reallocateRegister(REGISTER_Y, dtReal34, 0, amNone);
    int32ToReal34(margin, runtime.registerReal34Ptr(REGISTER_Y));
    latticeFree(frame);
}
