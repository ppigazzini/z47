// SPDX-License-Identifier: GPL-3.0-only
const abi = @import("abi");
const consts = abi.constants;
const const34_0 = consts.const34_0;
const const34_1 = consts.const34_1;
//
// Zig owner for src/c47/mathematics/prime.c: the prime-number / integer
// factorization engine. Provides the four prime.h commands (fnIsPrime,
// fnNextPrime, fnPrimeFactors, fnEvPFacts) plus the number-theory internals
// (smallPrimeList, calculateNextPrime, SQUFOF, Pollard-rho, the Euler-phi and
// sigma helpers). It is covered by src/testSuite/tests/prime.txt so
// `zig build test` verifies the port.
//
// Faithful line-by-line translation of prime.c. C unsigned arithmetic that
// wraps is written with the wrapping operators (+% -% *%). The host-only
// progress/screen display (_showProgress and the progressHalfSecUpdate_Integer
// status drawing) has no effect on the computed stack result; the underlying
// progress/exit functions are still called (so programRunStop / flag side
// effects are preserved) but _showProgress is reduced to a no-op. The
// MONITOR_FACTORS debug blocks are #undef'd in the C and are omitted here.
// EXTRA_INFO_ON_CALC_ERROR sprintf hints become fixed moreInfoOnError strings
// (matching the sibling owners; under TESTSUITE/DMCP builds moreInfoOnError is
// a no-op).

const runtime = @import("math_command_wrappers_runtime.zig");
const math_command_wrappers = @import("math_command_wrappers.zig"); // M-callconv: Zig-to-Zig
const math_comparison_reals = @import("math_comparison_reals.zig"); // M-callconv: Zig-to-Zig
const math_matrix_lifecycle = @import("math_matrix_lifecycle.zig"); // M-callconv: Zig-to-Zig
const math_matrix_register_link = @import("math_matrix_register_link.zig"); // M-callconv: Zig-to-Zig
const math_matrix_register_memory = @import("math_matrix_register_memory.zig"); // M-callconv: Zig-to-Zig
const math_multiplication_cells = @import("math_multiplication_cells.zig"); // M-callconv: Zig-to-Zig
const math_power = @import("math_power.zig"); // M-callconv: Zig-to-Zig

const calcRegister_t = runtime.calcRegister_t;
const real_t = runtime.real_t;
const real34_t = runtime.real34_t;
const realContext_t = runtime.realContext_t;
const real34Matrix_t = runtime.real34Matrix_t;
const matrixHeader_t = runtime.matrixHeader_t;
const pcg32_random_t = runtime.pcg32_random_t;

// ---------------------------------------------------------------------------
// GMP long integer (mpz). The mpz_* names are header macros / inline wrappers;
// the linkable symbols are __gmpz_*. The limb width == pointer width on every
// z47 target (usize, NOT c_ulong which is 32-bit on Win64). The GMP "unsigned
// long int" function arguments are genuine c_ulong in the ABI.
// ---------------------------------------------------------------------------
const mp_limb_t = usize;
const mpz_struct = abi.Mpz;
const longInteger_t = [1]mpz_struct;

extern fn @"__gmpz_init"(op: *mpz_struct) void;
extern fn @"__gmpz_clear"(op: *mpz_struct) void;
extern fn @"__gmpz_set"(rop: *mpz_struct, op: *const mpz_struct) void;
extern fn @"__gmpz_set_ui"(rop: *mpz_struct, op: c_ulong) void;
extern fn @"__gmpz_set_si"(rop: *mpz_struct, op: c_long) void;
extern fn @"__gmpz_set_str"(rop: *mpz_struct, str: [*:0]const u8, base: c_int) c_int;
extern fn @"__gmpz_get_ui"(op: *const mpz_struct) c_ulong;
extern fn @"__gmpz_get_si"(op: *const mpz_struct) c_long;
extern fn @"__gmpz_cmp"(op1: *const mpz_struct, op2: *const mpz_struct) c_int;
extern fn @"__gmpz_cmp_ui"(op: *const mpz_struct, v: c_ulong) c_int;
extern fn @"__gmpz_abs"(rop: *mpz_struct, op: *const mpz_struct) void;
extern fn @"__gmpz_add_ui"(rop: *mpz_struct, op: *const mpz_struct, v: c_ulong) void;
extern fn @"__gmpz_sub_ui"(rop: *mpz_struct, op: *const mpz_struct, v: c_ulong) void;
extern fn @"__gmpz_mul_ui"(rop: *mpz_struct, op: *const mpz_struct, v: c_ulong) void;
extern fn @"__gmpz_mul_2exp"(rop: *mpz_struct, op: *const mpz_struct, v: c_ulong) void;
extern fn @"__gmpz_tdiv_q"(q: *mpz_struct, n: *const mpz_struct, d: *const mpz_struct) void;
extern fn @"__gmpz_tdiv_q_ui"(q: *mpz_struct, n: *const mpz_struct, d: c_ulong) c_ulong;
extern fn @"__gmpz_fdiv_ui"(op: *const mpz_struct, d: c_ulong) c_ulong;
extern fn @"__gmpz_mod"(r: *mpz_struct, n: *const mpz_struct, d: *const mpz_struct) void;
extern fn @"__gmpz_gcd"(rop: *mpz_struct, a: *const mpz_struct, b: *const mpz_struct) void;
extern fn @"__gmpz_gcd_ui"(rop: ?*mpz_struct, op: *const mpz_struct, v: c_ulong) c_ulong;
extern fn @"__gmpz_sqrt"(rop: *mpz_struct, op: *const mpz_struct) void;
extern fn @"__gmpz_ui_pow_ui"(rop: *mpz_struct, base: c_ulong, exp: c_ulong) void;
extern fn @"__gmpz_perfect_square_p"(op: *const mpz_struct) c_int;
extern fn @"__gmpz_probab_prime_p"(op: *const mpz_struct, reps: c_int) c_int;
extern fn @"__gmpz_divexact"(q: *mpz_struct, n: *const mpz_struct, d: *const mpz_struct) void;
extern fn @"__gmpz_divexact_ui"(q: *mpz_struct, n: *const mpz_struct, d: c_ulong) void;
extern fn @"__gmpz_divisible_ui_p"(op: *const mpz_struct, d: c_ulong) c_int;
extern fn @"__gmpz_fits_uint_p"(op: *const mpz_struct) c_int;
extern fn @"__gmpz_fits_ulong_p"(op: *const mpz_struct) c_int;
extern fn @"__gmpz_sizeinbase"(op: *const mpz_struct, base: c_int) usize;

// The overflow-guarded long-integer operators live in the integers owner. They
// take *mpz_struct (the [1]mpz_struct array decays to a pointer in C).
extern fn longIntegerAdd(opY: *mpz_struct, opX: *mpz_struct, result: *mpz_struct) void;
extern fn longIntegerSubtract(opY: *mpz_struct, opX: *mpz_struct, result: *mpz_struct) void;
extern fn longIntegerMultiply(opY: *mpz_struct, opX: *mpz_struct, result: *mpz_struct) void;
extern fn longIntegerSquare(op: *mpz_struct, result: *mpz_struct) void;

// ---------------------------------------------------------------------------
// longInteger* helper wrappers (longIntegerType.h inlines / macros).
// ---------------------------------------------------------------------------
inline fn longIntegerInit(op: *mpz_struct) void {
    @"__gmpz_init"(op);
}
inline fn longIntegerFree(op: *mpz_struct) void {
    @"__gmpz_clear"(op);
}
inline fn longIntegerCopy(source: *const mpz_struct, destination: *mpz_struct) void {
    @"__gmpz_set"(destination, source);
}
inline fn uInt32ToLongInteger(source: u32, destination: *mpz_struct) void {
    @"__gmpz_set_ui"(destination, source);
}
inline fn int32ToLongInteger(source: i32, destination: *mpz_struct) void {
    @"__gmpz_set_si"(destination, source);
}
inline fn stringToLongInteger(source: [*:0]const u8, radix: i32, destination: *mpz_struct) i32 {
    return @"__gmpz_set_str"(destination, source, radix);
}
inline fn longIntegerToUInt32(op: *const mpz_struct) u32 {
    // __gmpz_get_ui returns c_ulong (32-bit on Win64 LLP64, 64-bit elsewhere);
    // truncate the low 32 bits directly. @bitCast to a fixed-width usize would
    // size-mismatch against the 32-bit c_ulong on Win64.
    return @truncate(@"__gmpz_get_ui"(op));
}
inline fn longIntegerToInt32(op: *const mpz_struct) i32 {
    return @truncate(@"__gmpz_get_si"(op));
}
inline fn longIntegerChangeSign(op: *mpz_struct) void {
    op._mp_size = -op._mp_size;
}
inline fn longIntegerSetPositiveSign(op: *mpz_struct) void {
    op._mp_size = if (op._mp_size < 0) -op._mp_size else op._mp_size;
}
inline fn longIntegerIsZero(op: *const mpz_struct) bool {
    return op._mp_size == 0;
}
inline fn longIntegerIsPositive(op: *const mpz_struct) bool {
    return op._mp_size > 0;
}
inline fn longIntegerIsNegative(op: *const mpz_struct) bool {
    return op._mp_size < 0;
}
inline fn longIntegerIsEven(op: *const mpz_struct) bool {
    // mpz_even_p: size==0 || (low limb & 1)==0
    return op._mp_size == 0 or (op._mp_d[0] & 1) == 0;
}
inline fn longIntegerSign(op: *const mpz_struct) i32 {
    return if (op._mp_size < 0) -1 else if (op._mp_size > 0) 1 else 0;
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
inline fn longIntegerDivideUInt(op: *const mpz_struct, u: u32, result: *mpz_struct) void {
    _ = @"__gmpz_tdiv_q_ui"(result, op, u);
}
inline fn longIntegerModulo(op1: *const mpz_struct, op2: *const mpz_struct, result: *mpz_struct) void {
    @"__gmpz_mod"(result, op1, op2);
}
inline fn longIntegerModuloUInt(op: *const mpz_struct, u: u32) u32 {
    return @truncate(@"__gmpz_fdiv_ui"(op, u));
}
inline fn longIntegerSquareRoot(op: *const mpz_struct, result: *mpz_struct) void {
    @"__gmpz_sqrt"(result, op);
}
inline fn longIntegerPerfectSquare(op: *const mpz_struct) i32 {
    return @"__gmpz_perfect_square_p"(op);
}
inline fn longIntegerMultiplyUInt(op: *const mpz_struct, u: u32, result: *mpz_struct) void {
    @"__gmpz_mul_ui"(result, op, u);
}
inline fn longIntegerAddUInt(op: *const mpz_struct, u: u32, result: *mpz_struct) void {
    @"__gmpz_add_ui"(result, op, u);
}
inline fn longIntegerSubtractUInt(op: *const mpz_struct, u: u32, result: *mpz_struct) void {
    @"__gmpz_sub_ui"(result, op, u);
}
inline fn longIntegerPowerUIntUInt(base: u32, exponent: u32, result: *mpz_struct) void {
    @"__gmpz_ui_pow_ui"(result, base, exponent);
}
inline fn longIntegerGcd(op1: *const mpz_struct, op2: *const mpz_struct, result: *mpz_struct) void {
    @"__gmpz_gcd"(result, op1, op2);
}
inline fn longIntegerProbabPrime(op: *const mpz_struct) i32 {
    return @"__gmpz_probab_prime_p"(op, 25);
}
inline fn longIntegerIsPrime(op: *const mpz_struct) i32 {
    return @"__gmpz_probab_prime_p"(op, 25);
}

// longIntegerPower (power.c): result = base ^ exponent (overflow-guarded).

// The mpz_* names used directly by prime.c.
inline fn mpz_fits_uint_p(op: *const mpz_struct) bool {
    return @"__gmpz_fits_uint_p"(op) != 0;
}
inline fn mpz_fits_ulong_p(op: *const mpz_struct) bool {
    return @"__gmpz_fits_ulong_p"(op) != 0;
}
inline fn mpz_get_ui(op: *const mpz_struct) c_ulong {
    return @"__gmpz_get_ui"(op);
}
inline fn mpz_divisible_ui_p(op: *const mpz_struct, d: c_ulong) bool {
    return @"__gmpz_divisible_ui_p"(op, d) != 0;
}
inline fn mpz_divexact_ui(q: *mpz_struct, n: *const mpz_struct, d: c_ulong) void {
    @"__gmpz_divexact_ui"(q, n, d);
}
inline fn mpz_divexact(q: *mpz_struct, n: *const mpz_struct, d: *const mpz_struct) void {
    @"__gmpz_divexact"(q, n, d);
}
inline fn mpz_gcd_ui(rop: *mpz_struct, op: *const mpz_struct, d: c_ulong) void {
    _ = @"__gmpz_gcd_ui"(rop, op, d);
}
inline fn mpz_abs(rop: *mpz_struct, op: *const mpz_struct) void {
    @"__gmpz_abs"(rop, op);
}
inline fn mpz_mul_2exp(rop: *mpz_struct, op: *const mpz_struct, v: c_ulong) void {
    @"__gmpz_mul_2exp"(rop, op, v);
}
inline fn mpz_add_ui(rop: *mpz_struct, op: *const mpz_struct, v: c_ulong) void {
    @"__gmpz_add_ui"(rop, op, v);
}
inline fn mpz_init(op: *mpz_struct) void {
    @"__gmpz_init"(op);
}
inline fn mpz_clear(op: *mpz_struct) void {
    @"__gmpz_clear"(op);
}
inline fn mpz_mod(rop: *mpz_struct, n: *const mpz_struct, d: *const mpz_struct) void {
    @"__gmpz_mod"(rop, n, d);
}
inline fn mpz_sizeinbase(op: *const mpz_struct, base: c_int) usize {
    return @"__gmpz_sizeinbase"(op, base);
}

// ---------------------------------------------------------------------------
// real_t / real34_t helpers and constants
// ---------------------------------------------------------------------------
// real_t constants: use the runtime accessors (properly-aligned *const real_t).
inline fn const_0() *const real_t {
    return runtime.z47_math_wrappers_const_0();
}
inline fn const__1() *const real_t {
    return runtime.z47_math_wrappers_const_minus_1();
}
inline fn const_1() *const real_t {
    return runtime.z47_math_wrappers_const_1();
}

// real34Copy(source, destination): copy the 16 raw bytes (two u64 stores in C).
inline fn real34Copy(source: *align(1) const real34_t, destination: *align(1) real34_t) void {
    const src: *align(1) const [2]u64 = @ptrCast(source);
    const dst: *align(1) [2]u64 = @ptrCast(destination);
    dst[0] = src[0];
    dst[1] = src[1];
}
extern fn convertLongIntegerToReal34(source: *mpz_struct, destination: *align(1) real34_t) void;
extern fn decQuadFromUInt32(destination: *align(1) real34_t, source: u32) *align(1) real34_t;
inline fn uInt32ToReal34Impl(source: u32, destination: *align(1) real34_t) void {
    _ = decQuadFromUInt32(destination, source);
}
extern fn convertReal34ToLongInteger(real34: *align(1) const real34_t, lgInt: *mpz_struct, mode: c_int) void;
extern fn convertLongIntegerToReal(source: *mpz_struct, destination: *real_t, ctxt: *realContext_t) void;

// real34SetZero(destination) => decQuadZero(destination)
extern fn decQuadZero(destination: *real34_t) *real34_t; // lastAdded is naturally aligned
inline fn real34SetZero(destination: *real34_t) void {
    _ = decQuadZero(destination);
}

// roundingMode / roundingModeTable
extern var roundingMode: u8;
const roundingModeTable = @extern([*]const c_int, .{ .name = "roundingModeTable" });
inline fn currentRoundingMode() c_int {
    return roundingModeTable[roundingMode];
}

// ---------------------------------------------------------------------------
// Register / matrix access (registers.h macros)
// ---------------------------------------------------------------------------
const REGISTER_X: calcRegister_t = 100;
const REGISTER_Y: calcRegister_t = 101;
const REGISTER_Z: calcRegister_t = 102;
const REGISTER_L: calcRegister_t = 108;
const REGISTER_G: calcRegister_t = 120;
const REGISTER_H: calcRegister_t = 121;
const REGISTER_K: calcRegister_t = 111;
const TEMP_REGISTER_1: calcRegister_t = 135;
const ERR_REGISTER_LINE: calcRegister_t = REGISTER_Z;
const NIM_REGISTER_LINE: calcRegister_t = REGISTER_X;

const registerMatrixHeader = abi.registerMatrixHeader;
const registerReal34MatrixElements = abi.registerReal34MatrixElements;

// ---------------------------------------------------------------------------
// Error / data-type / stack externs
// ---------------------------------------------------------------------------
const dtReal34: u32 = 1;
const dtReal34Matrix: u32 = 6;
const dtShortInteger: u32 = 8;

const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN: u8 = 1;
const ERROR_OUT_OF_RANGE: u8 = 8;
const ERROR_RAM_FULL: u8 = 11;
const ERROR_INVALID_DATA_TYPE_FOR_OP: u8 = 24;
const ERROR_NOT_ENOUGH_MEMORY_FOR_NEW_MATRIX: u8 = 39;
const ERROR_SOLVER_ABORT: u8 = 60;

const FLAG_CPXRES: i32 = 0x8004;
const FLAG_ASLIFT: i32 = 0xc023; // defines.h:853 (was 0x8019 = FLAG_QUIET)

const NOPARAM: u16 = 9876;
const PRN_TMP: u16 = 8;
const ITM_M_DIM: u16 = 1526;
const DEC_ROUND_DOWN: c_int = 5;
const PGM_WAITING: u8 = 2;
const SCRUPD_MANUAL_STACK: u8 = 0x02;
const SCRUPD_SKIP_STACK_ONE_TIME: u8 = 0x20;
const TI_FALSE: u8 = 12;

// prime.h parameter constants
const M_SIGMA_0: u16 = 0;
const M_SIGMA_1: u16 = 1;
const M_SIGMA_k: u16 = 2;
const M_SIGMA_p1: u16 = 3;
const M_SIGMA_pk: u16 = 4;
const M_FACTORS: u16 = 5;
const M_PHI_EUL: u16 = 6;

const maximumPrime: u32 = 308;
const MAX_FACTORS: usize = 110;
const MAXIMUM_QUEUE_SIZE: usize = 100;

// Globals.
extern var temporaryInformation: u8;
extern var lastErrorCode: u8;
extern var programRunStop: u8;
extern var screenUpdatingMode: u8;
extern var iterations: bool;
extern var currentKeyCode: u8;
extern var cancelFilename: bool;
extern var cachedDisplayStack: u8;

extern fn displayCalcErrorMessage(error_code: u8, err_message_register_line: calcRegister_t, err_register_line: calcRegister_t) void;
extern fn badDomainError(reg: calcRegister_t) void;
extern fn saveLastX() bool;
extern fn saveForUndo() void;
extern fn getRegisterDataType(reg: calcRegister_t) u32;
extern fn getRegisterTag(reg: calcRegister_t) u32;
extern fn getRegisterAsLongInt(reg: calcRegister_t, val: *mpz_struct, fractional: ?*bool) bool;
extern fn getRegisterAsReal(reg: calcRegister_t, value: *real_t) bool;
extern fn convertRealToLongInteger(real: *const real_t, lgInt: *mpz_struct, mode: c_int) void;
extern fn convertLongIntegerToShortIntegerRegister(lgInt: *const mpz_struct, base: u32, regist: calcRegister_t) void;
extern fn convertLongIntegerToLongIntegerRegister(lgInt: *const mpz_struct, regist: calcRegister_t) void;
extern fn convertLongIntegerRegisterToLongInteger(reg: calcRegister_t, lgInt: *mpz_struct) void;
extern fn convertRealToResultRegister(real: *const real_t, dest: calcRegister_t, angle_mode: runtime.angularMode_t) void;
extern fn convertComplexToResultRegister(real: *const real_t, imag: *const real_t, dest: calcRegister_t) void;
extern fn realToInt32C47(source: *const real_t, err: ?*bool) i32;
extern fn fnDrop(unused_but_mandatory_parameter: u16) void;
extern fn fnSwapXY(unused_but_mandatory_parameter: u16) void;
extern fn convertReal34MatrixRegisterToReal34Matrix(reg: calcRegister_t, matrix: *real34Matrix_t) void;
extern fn convertReal34MatrixToReal34MatrixRegister(matrix: *const real34Matrix_t, reg: calcRegister_t) void;
extern fn adjustResult(res: calcRegister_t, drop_y: bool, set_cpx_res: bool, op1: calcRegister_t, op2: calcRegister_t, op3: calcRegister_t) void;
extern fn getFlag(flag: u16) bool;
extern fn setSystemFlag(sf: c_uint) void;
extern fn realSetOne(r: *real_t) void;
extern fn realSetZero(r: *real_t) void;
extern fn moreInfoOnError(m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) void;

// realIsNegative / realMultiply / real34ToReal are C macros; reproduce them.
inline fn realIsNegative(source: *const real_t) bool {
    return (source.bits & 0x80) == 0x80;
}
inline fn realMultiply(operand1: *const real_t, operand2: *const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = runtime.decNumberMultiply(res, operand1, operand2, ctxt);
}
extern fn decimal128ToNumber(source: *align(1) const real34_t, destination: *real_t) *real_t;
inline fn real34ToReal(source: *align(1) const real34_t, destination: *real_t) void {
    _ = decimal128ToNumber(source, destination);
}

// Matrix register helpers
extern fn copySourceRegisterToDestRegister(source: calcRegister_t, dest: calcRegister_t) void;

// Screen / progress (host-only; called for control-flow side effects)
extern fn updateMatrixHeightCache() void;
extern fn refreshRegisterLine(regist: calcRegister_t) void;
extern fn refreshScreen(source: u16) void;
extern fn clearScreenOld(clearStatusBar: bool, clearRegisterLines: bool, clearSoftkeys: bool) void;
extern fn force_refresh(mode: u8) void;
extern fn checkHalfSec() bool;
extern fn exitKeyWaiting() bool;
extern fn progressHalfSecUpdate_Integer(mode: u8, txt: [*:0]const u8, loop: i32, clearZ: bool, clearT: bool, disp: bool) bool;
extern fn monitorExit(loop: *i32, str: [*:0]const u8) bool;

// PCG32 RNG (exported by the random primitives owner).

// progressHalfSecUpdate_Integer mode constants (from screen.h)
const halfSec_timed: u8 = 0; // "timed"
const halfSec_force: u8 = 1; // "force"
const halfSec_clearZ: bool = true;
const halfSec_clearT: bool = true;
const halfSec_disp: bool = true;

// ---------------------------------------------------------------------------
// Static prime tables (TO_QSPI const in C -> Zig const data).
// ---------------------------------------------------------------------------
const smallPrimes = [_]u8{ 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131, 137, 139, 149, 151, 157, 163, 167, 173, 179, 181, 191, 193, 197, 199, 211, 223, 227, 229, 233, 239, 241, 251 };

const indices = [_]u8{ 1, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 121, 127, 131, 137, 139, 143, 149, 151, 157, 163, 167, 169, 173, 179, 181, 187, 191, 193, 197, 199, 209 };

const offsets = [_]u8{ 10, 2, 4, 2, 4, 6, 2, 6, 4, 2, 4, 6, 6, 2, 6, 4, 2, 6, 4, 6, 8, 4, 2, 4, 2, 4, 8, 6, 4, 6, 2, 4, 6, 2, 6, 6, 4, 2, 4, 6, 2, 6, 4, 2, 4, 2, 10, 2 };

const smallPrimes2 = [_]u8{ 6, 6, 6, 2, 6, 4, 2, 10, 14, 4, 2, 4, 14, 6, 10, 2, 4, 6, 8, 6, 6, 4, 6, 8, 4, 8, 10, 2, 10, 2, 6, 4, 6, 8, 4, 2, 4, 12, 8, 4, 8, 4, 6, 12, 2, 18, 6, 10, 6, 6, 2, 6, 10, 6, 6, 2, 6, 6, 4, 2, 12, 10, 2, 4, 6, 6, 2, 12, 4, 6, 8, 10, 8, 10, 8, 6, 6, 4, 8, 6, 4, 8, 4, 14, 10, 12, 2, 10, 2, 4, 2, 10, 14, 4, 2, 4, 14, 4, 2, 4, 20, 4, 8, 10, 8, 4, 6, 6, 14, 4, 6, 6, 8, 6, 12 };

const smallPrimeListNumber: u16 = smallPrimes.len + smallPrimes2.len;

fn smallPrimeList(index: u16) u16 {
    var tt: u16 = 251;
    if (index < smallPrimes.len) {
        return smallPrimes[index];
    } else if (index < smallPrimeListNumber) {
        const subIndex: u16 = index - @as(u16, smallPrimes.len);
        var ii: u16 = 0;
        while (ii <= subIndex and ii < smallPrimes2.len) : (ii += 1) {
            tt += smallPrimes2[ii];
        }
        return tt;
    } else {
        return 0;
    }
}

const Factors_1_SmallPrimes: bool = true;
const Factors_2_PerfectSquare: bool = true;
const Factors_3_Pollard: bool = true;

// SQUFOF multipliers
const multipliers_squfof = [_]c_int{
    1,        3,        5,        7,        11,       13,
    3 * 5,    3 * 7,    3 * 11,   3 * 13,
    5 * 7,    5 * 11,   5 * 13,
    7 * 11,   7 * 13,
    11 * 13,
    3 * 5 * 7,  3 * 5 * 11,  3 * 5 * 13,
    3 * 7 * 11, 3 * 7 * 13,  3 * 11 * 13,
    5 * 7 * 11, 5 * 7 * 13,
    3 * 5 * 7 * 11,
};

// ---------------------------------------------------------------------------
// Pollard's Rho types
// ---------------------------------------------------------------------------
const factors_status_t = enum(c_int) {
    FACTORS_SETUP = 0,
    FACTORS_ITERATE = 1,
    FACTORS_RESET = 2,
    FACTORS_DONE = 3,
    FACTORS_FAIL = 4,
};

const factors_result_t = struct {
    status: factors_status_t,
    iterations_this_call: c_int,
    total_iterations: c_int,
    attempts: c_int,
};

const pollard_t = struct {
    n: mpz_struct,
    x: mpz_struct,
    y: mpz_struct,
    c: mpz_struct,
    d: mpz_struct,
    tmp: mpz_struct,
    iteration: c_int,
    attempt: c_int,
    rng: pcg32_random_t,
};

const max_iterations: c_int = 1000000;
const max_attempts: c_int = 1000;
inline fn maxIter(self: *const pollard_t) c_int {
    return if (self.attempt <= 25) @divTrunc(max_iterations, 10) else (if (self.attempt <= 50) max_iterations else max_iterations * 4);
}

// ---------------------------------------------------------------------------
// _showProgress: host-only display, no effect on the stack result. Reduced to
// a no-op (the C clears register lines and draws strings only).
// ---------------------------------------------------------------------------
fn _showProgress(ss: *const real34_t, nextp: *mpz_struct) void {
    _ = ss;
    _ = nextp;
}

// ===========================================================================
// getIntArg
// ===========================================================================
fn getIntArg(x: *mpz_struct, regist: calcRegister_t) bool {
    var fractional: bool = undefined;

    if (!getRegisterAsLongInt(regist, x, &fractional)) {
        if (getRegisterDataType(regist) != dtReal34Matrix) {
            displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnError("In function getIntArg:", "The input value is invalid for storage into a longinteger!", null, null);
        }
        return false;
    }

    if (fractional) {
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function getIntArg:", "The input value is fractional and invalid for storage into a longinteger!", null, null);
        return false;
    }
    return true;
}

// ===========================================================================
// fnIsPrime
// ===========================================================================
pub export fn fnIsPrime(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    var tmp: mpz_struct = undefined;
    var primeCandidate: mpz_struct = undefined;

    if (!getIntArg(&primeCandidate, REGISTER_X)) {
        longIntegerFree(&primeCandidate);
        return;
    }
    defer longIntegerFree(&primeCandidate);

    longIntegerInit(&tmp);
    defer longIntegerFree(&tmp);
    longIntegerPowerUIntUInt(10, maximumPrime, &tmp);
    longIntegerSubtract(&primeCandidate, &tmp, &tmp); // (primeCandidate - 10^300) positive is too large
    if (longIntegerIsPositive(&tmp)) {
        badDomainError(REGISTER_X);
        return;
    }

    setTiTrueFalse(longIntegerIsPositive(&primeCandidate) and longIntegerIsPrime(&primeCandidate) != 0);
}

inline fn setTiTrueFalse(condition: bool) void {
    temporaryInformation = TI_FALSE + @as(u8, @intFromBool(condition));
}

// ===========================================================================
// fnNextPrime
// ===========================================================================
pub export fn fnNextPrime(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    var x: real_t = undefined;
    var tmp: mpz_struct = undefined;
    var currentNumber: mpz_struct = undefined;
    var nextPrime: mpz_struct = undefined;

    if (getRegisterDataType(REGISTER_X) == dtReal34) {
        if (!getRegisterAsReal(REGISTER_X, &x)) {
            return;
        }
        longIntegerInit(&currentNumber);
        convertRealToLongInteger(&x, &currentNumber, DEC_ROUND_DOWN);
    } else {
        if (!getIntArg(&currentNumber, REGISTER_X)) {
            longIntegerFree(&currentNumber);
            return;
        }
    }
    // currentNumber is now initialized on every path that reaches here (the
    // getIntArg failure returned above); defer replaces the goto-cleanup, freeing
    // in reverse registration order (nextPrime, tmp, currentNumber) to match the C.
    defer longIntegerFree(&currentNumber);

    longIntegerInit(&tmp);
    defer longIntegerFree(&tmp);
    longIntegerPowerUIntUInt(10, maximumPrime, &tmp);
    longIntegerSubtract(&currentNumber, &tmp, &tmp);
    if (longIntegerIsPositive(&tmp)) {
        badDomainError(REGISTER_X);
        return;
    }

    if (!saveLastX()) {
        return;
    }

    if (!longIntegerIsPositive(&currentNumber)) {
        uInt32ToLongInteger(1, &currentNumber);
    }

    longIntegerInit(&nextPrime);
    defer longIntegerFree(&nextPrime);
    calculateNextPrime(&currentNumber, &nextPrime);

    if (getRegisterDataType(REGISTER_L) == dtShortInteger) {
        convertLongIntegerToShortIntegerRegister(&nextPrime, getRegisterShortIntegerBase(REGISTER_L), REGISTER_X);
    } else {
        convertLongIntegerToLongIntegerRegister(&nextPrime, REGISTER_X);
    }
}

inline fn getRegisterShortIntegerBase(reg: calcRegister_t) u32 {
    return getRegisterTag(reg);
}

// ===========================================================================
// calculateNextPrime
// ===========================================================================
fn calculateNextPrime(currentNumber: *mpz_struct, nextPrime: *mpz_struct) void {
    var cn: u32 = undefined;
    var i: u32 = undefined;
    var x: u32 = undefined;
    var s: u32 = undefined;
    var e: u32 = undefined;
    var m: u32 = undefined;
    var o: u32 = undefined;
    var loop: i32 = 0;

    if (longIntegerCompareUInt(currentNumber, 2) < 0) {
        uInt32ToLongInteger(2, nextPrime);
        return;
    }

    // first odd larger than currentNumber
    longIntegerAddUInt(currentNumber, 1, currentNumber);
    if (longIntegerIsEven(currentNumber)) {
        longIntegerAddUInt(currentNumber, 1, currentNumber);
    }

    // check if the next odd number is a small prime
    if (longIntegerCompareUInt(currentNumber, smallPrimeList(smallPrimeListNumber - 1) + 1) < 0) {
        if (mpz_fits_ulong_p(currentNumber)) {
            cn = longIntegerToUInt32(currentNumber);
            while (true) {
                i = 0;
                while (i < smallPrimeListNumber) : (i += 1) {
                    if (smallPrimeList(@truncate(i)) == cn) {
                        uInt32ToLongInteger(cn, nextPrime);
                        return;
                    }
                }
                cn += 2;
            }
        }
    }

    // find our position in the sieve rotation via binary search
    x = longIntegerModuloUInt(currentNumber, 210);
    s = 0;
    e = 47;
    m = 24;
    while (m != e) {
        if (indices[m] < x) {
            s = m;
            m = (s + e + 1) >> 1;
        } else {
            e = m;
            m = (s + e) >> 1;
        }
    }

    // nextPrime = currentNumber + indices[m] - x;
    longIntegerAddUInt(currentNumber, indices[m] -% x, nextPrime);
    while (true) {
        o = m;
        while (o < m + 48) : (o += 1) {
            if (longIntegerIsPrime(nextPrime) != 0) {
                return;
            }
            longIntegerAddUInt(nextPrime, offsets[o % 48], nextPrime);

            if (monitorExit(&loop, "Iter: ")) {
                displayCalcErrorMessage(ERROR_SOLVER_ABORT, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
                return;
            }
        }
    }
}

// ===========================================================================
// longIntegerSumPowers (used by Euler sigma)
// ===========================================================================
fn longIntegerSumPowers(base: *mpz_struct, exponent: *mpz_struct, k: u32, result: *mpz_struct) void {
    var count: mpz_struct = undefined;
    var sum: mpz_struct = undefined;
    var pwr: mpz_struct = undefined;
    var tmp: mpz_struct = undefined;
    var tmpbase: mpz_struct = undefined;
    longIntegerInit(&count);
    longIntegerInit(&sum);
    longIntegerInit(&pwr);
    longIntegerInit(&tmp);
    longIntegerInit(&tmpbase);
    uInt32ToLongInteger(0, &sum);
    longIntegerCopy(exponent, &count);

    while (!longIntegerIsNegative(&count)) {
        if (k == 0) {
            uInt32ToLongInteger(0, &tmp);
        } else {
            longIntegerCopy(&count, &tmp);
        }
        if (k >= 2) {
            longIntegerMultiplyUInt(&tmp, k, &tmp);
        }
        longIntegerCopy(base, &tmpbase);
        math_power.longIntegerPower(&tmpbase, &tmp, &pwr);
        longIntegerCopy(&pwr, &tmp);
        longIntegerAdd(&sum, &tmp, &sum);
        longIntegerSubtractUInt(&count, 1, &count);
    }

    longIntegerCopy(&sum, result);
    longIntegerFree(&tmpbase);
    longIntegerFree(&tmp);
    longIntegerFree(&pwr);
    longIntegerFree(&sum);
    longIntegerFree(&count);
}

// ===========================================================================
// _doFnEvPFacts
// ===========================================================================
const sumTypeInteger: u8 = 0;
const sumTypeReal: u8 = 1;
const sumTypeComplex: u8 = 2;

fn _doFnEvPFacts(param: u16) void {
    var prodR: real_t = undefined;
    var prodI: real_t = undefined;
    var factorR: real_t = undefined;
    var factorI: real_t = undefined;
    var baseR: real_t = undefined;
    var expR: real_t = undefined;

    var pwr: i32 = @intCast(param);
    var x: real_t = undefined;
    var currentNumber: mpz_struct = undefined;

    if (param == M_SIGMA_k) {
        if (getRegisterDataType(REGISTER_X) == dtReal34) {
            if (!getRegisterAsReal(REGISTER_X, &x)) {
                doDomainAbort();
                return;
            }
            pwr = realToInt32C47(&x, null);
            fnDrop(NOPARAM);
        } else {
            if (!getIntArg(&currentNumber, REGISTER_X)) {
                longIntegerFree(&currentNumber);
                doDomainAbort();
                return;
            }
            pwr = longIntegerToInt32(&currentNumber);
            if (pwr > 3321 or pwr < 0) {
                longIntegerFree(&currentNumber);
                doDomainAbort();
                return;
            }
            fnDrop(NOPARAM);
            longIntegerFree(&currentNumber);
        }
    }

    if (getRegisterDataType(REGISTER_X) == dtReal34Matrix) {
        var matrix: real34Matrix_t = undefined;
        math_matrix_register_link.linkToRealMatrixRegister(REGISTER_X, &matrix);
        const rows: u16 = registerMatrixHeader(REGISTER_X).matrixRows;
        const cols: u16 = registerMatrixHeader(REGISTER_X).matrixColumns;
        if (rows == 2 and cols >= 1) {
            var prod: mpz_struct = undefined;
            var factor: mpz_struct = undefined;
            var tmp_prod: mpz_struct = undefined;
            var p_li: mpz_struct = undefined;
            var k_li: mpz_struct = undefined;
            longIntegerInit(&prod);
            longIntegerInit(&factor);
            longIntegerInit(&tmp_prod);
            // block-scoped defer: frees on the CPXRES-error return and the normal
            // fall-through, matching the C's two manual free sites. The screen
            // refreshScreen(253) is deliberately NOT deferred -- it is non-uniform
            // (the CPXRES-error path skips it). p_li/k_li stay loop-scoped.
            defer longIntegerFree(&prod);
            defer longIntegerFree(&factor);
            defer longIntegerFree(&tmp_prod);
            uInt32ToLongInteger(1, &prod);
            realSetOne(&prodR);
            var sumType: u8 = sumTypeInteger;
            const elems = matrixElementsPtr(&matrix);
            var j: u16 = 0;
            while (j < cols) : (j += 1) {
                if (math_comparison_reals.real34IsAnInteger(&elems[j]) and math_comparison_reals.real34IsAnInteger(&elems[cols + j]) and sumType == sumTypeInteger) {
                    convertReal34ToLongInteger(&elems[j], &p_li, currentRoundingMode());
                    convertReal34ToLongInteger(&elems[cols + j], &k_li, currentRoundingMode());
                    switch (param) {
                        M_FACTORS => math_power.longIntegerPower(&p_li, &k_li, &factor),
                        M_SIGMA_0, M_SIGMA_1, M_SIGMA_k => longIntegerSumPowers(&p_li, &k_li, @bitCast(pwr), &factor),
                        else => {},
                    }
                    longIntegerFree(&p_li);
                    longIntegerFree(&k_li);
                    longIntegerCopy(&prod, &tmp_prod);
                    longIntegerMultiply(&tmp_prod, &factor, &prod);
                } else {
                    if (sumType == sumTypeInteger) {
                        convertLongIntegerToReal(&prod, &prodR, &runtime.ctxtReal39);
                        sumType = sumTypeReal;
                    }
                    real34ToReal(&elems[j], &baseR);
                    real34ToReal(&elems[cols + j], &expR);
                    if (!(realIsNegative(&baseR) and !math_comparison_reals.realIsAnInteger(&expR)) and sumType == sumTypeReal) {
                        math_power.PowerReal(&baseR, &expR, &factorR, &runtime.ctxtReal39);
                        realMultiply(&prodR, &factorR, &prodR, &runtime.ctxtReal39);
                    } else if (getFlag(FLAG_CPXRES)) {
                        if (sumType == sumTypeReal) {
                            realSetZero(&prodI);
                            sumType = sumTypeComplex;
                        }
                        if (sumType == sumTypeComplex) {
                            _ = math_power.PowerComplex(&baseR, const_0(), &expR, const_0(), &factorR, &factorI, &runtime.ctxtReal39);
                            math_multiplication_cells.mulComplexComplex(&prodR, &prodI, &factorR, &factorI, &prodR, &prodI, &runtime.ctxtReal39);
                        }
                    } else {
                        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
                        moreInfoOnError("In function _doFnEvPFacts:", "cannot do complex results if CPXRES is not set", null, null);
                        return;
                    }
                }
            }

            switch (sumType) {
                sumTypeInteger => {
                    convertLongIntegerToLongIntegerRegister(&prod, REGISTER_X);
                },
                sumTypeReal => {
                    convertRealToResultRegister(&prodR, REGISTER_X, runtime.amNone);
                },
                sumTypeComplex => {
                    convertComplexToResultRegister(&prodR, &prodI, REGISTER_X);
                },
                else => {},
            }
            adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
        } else {
            displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnError("In function _doFnEvPFacts:", "Only 2xn matrix supported", null, null);
            // goto return10
            refreshScreen(253);
            return;
        }
    } else {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function _doFnEvPFacts:", "2xn matrix required.", null, null);
        // goto return10
        refreshScreen(253);
        return;
    }
    // return10:
    refreshScreen(253);
    return;
}

fn doDomainAbort() void {
    // abort: in _doFnEvPFacts
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    moreInfoOnError("In function _doFnEvPFacts:", "cannot do Euler sigma function due to parameter issue", null, null);
    refreshScreen(253);
}

inline fn matrixElementsPtr(matrix: *real34Matrix_t) [*]align(1) real34_t {
    if (runtime.harness_surface_is_fake) {
        return @ptrCast(&matrix.matrixElements);
    } else {
        return @ptrCast(matrix.matrixElements);
    }
}

// ===========================================================================
// doFnEvPFacts
// ===========================================================================
fn doFnEvPFacts(param: u16) void {
    var k: i32 = 1;

    if (param == M_SIGMA_p1 or param == M_SIGMA_pk) {
        if (param == M_SIGMA_pk) {
            var xx: mpz_struct = undefined;
            if (!getIntArg(&xx, REGISTER_X)) {
                // goto end
                longIntegerFree(&xx);
            } else {
                k = longIntegerToInt32(&xx);
                fnSwapXY(NOPARAM); // get matrix to X
                // end:
                longIntegerFree(&xx);
            }
        }

        // expect matrix in X
        var xxmat: real34Matrix_t = undefined;
        convertReal34MatrixRegisterToReal34Matrix(REGISTER_X, &xxmat);
        var y: mpz_struct = undefined;
        var x: mpz_struct = undefined;
        var z: mpz_struct = undefined;
        var tmp: mpz_struct = undefined;
        _doFnEvPFacts(M_FACTORS);
        convertLongIntegerRegisterToLongInteger(REGISTER_X, &y);
        longIntegerInit(&z);
        longIntegerInit(&tmp);
        int32ToLongInteger(k, &z);
        math_power.longIntegerPower(&y, &z, &tmp);
        longIntegerCopy(&tmp, &y); // y is the number to be subtracted
        convertReal34MatrixToReal34MatrixRegister(&xxmat, REGISTER_X);

        switch (param) {
            M_SIGMA_p1 => {
                _doFnEvPFacts(M_SIGMA_1);
            },
            M_SIGMA_pk => {
                fnSwapXY(NOPARAM); // restore matrix to y
                _doFnEvPFacts(M_SIGMA_k);
            },
            else => {},
        }
        convertLongIntegerRegisterToLongInteger(REGISTER_X, &x);
        longIntegerSubtract(&x, &y, &x);
        convertLongIntegerToLongIntegerRegister(&x, REGISTER_X);
        longIntegerFree(&tmp);
        longIntegerFree(&z);
        longIntegerFree(&y);
        longIntegerFree(&x);
        math_matrix_lifecycle.realMatrixFree(&xxmat);
    } else {
        _doFnEvPFacts(param);
    }
}

// ===========================================================================
// isRegisterMatrixFactors
// ===========================================================================
fn isRegisterMatrixFactors(reg: calcRegister_t, isNegative: *bool) bool {
    const ty = getRegisterDataType(reg);
    isNegative.* = false;

    if (ty == dtReal34Matrix) {
        const head = registerMatrixHeader(reg);
        const cols: u16 = head.matrixColumns;
        const elems = registerReal34MatrixElements(reg);
        var x: real_t = undefined;
        var mustBeOne: bool = false;

        if (head.matrixRows != 2 or cols < 1) {
            return false;
        }
        var i: u32 = 0;
        while (i < cols) : (i += 1) {
            real34ToReal(&elems[i + 0 * cols], &x);
            if (!math_comparison_reals.realIsAnInteger(&x)) {
                return false;
            }
            if (math_comparison_reals.realCompareLessEqual(&x, const_0())) {
                if (i != 0) {
                    return false;
                }
                if (!math_comparison_reals.realCompareEqual(&x, const__1())) {
                    return false;
                }
                mustBeOne = true;
            }

            real34ToReal(&elems[i + 1 * cols], &x);
            if (!math_comparison_reals.realIsAnInteger(&x)) {
                return false;
            }
            if (math_comparison_reals.realCompareLessThan(&x, const_0())) {
                return false;
            }
            if (mustBeOne) {
                if (!math_comparison_reals.realCompareEqual(&x, const_1())) {
                    return false;
                }
                isNegative.* = true;
                mustBeOne = false;
            }
        }
        return true;
    }

    return false;
}

// ===========================================================================
// ensureFactorizationMatrix
// ===========================================================================
fn ensureFactorizationMatrix(reg: calcRegister_t, allowNegative: bool, doFactorizeNow: bool, wasAlreadyMatrix: *bool) bool {
    var isNegative: bool = undefined;
    wasAlreadyMatrix.* = isRegisterMatrixFactors(reg, &isNegative);
    if (!wasAlreadyMatrix.*) {
        if (getRegisterDataType(reg) == dtReal34Matrix) {
            displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, reg);
            moreInfoOnError("In function ensureFactorizationMatrix 01:", "The input value is not a valid matrix!", null, null);
            return false;
        }
        var x: mpz_struct = undefined;
        if (!getIntArg(&x, reg)) {
            displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, reg);
            moreInfoOnError("In function ensureFactorizationMatrix 02:", "The input value is neither a longinteger nor a valid matrix!", null, null);
            longIntegerFree(&x);
            return false;
        }
        if (longIntegerIsNegative(&x)) {
            displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, reg);
            moreInfoOnError("In function ensureFactorizationMatrix 03:", "The input value is negative and therefore out of the domain!", null, null);
            longIntegerFree(&x);
            return false;
        }
        longIntegerFree(&x);
    }
    if (wasAlreadyMatrix.* and !allowNegative and isNegative) {
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, reg);
        moreInfoOnError("In function ensureFactorizationMatrix 04:", "The matrix input value is negative and therefore out of the domain!", null, null);
        return false;
    }
    // Factorize the integer if requested
    if (doFactorizeNow and !wasAlreadyMatrix.*) {
        if (reg == REGISTER_Y) {
            fnSwapXY(NOPARAM);
            _ = performPrimeFactorization(false);
            fnSwapXY(NOPARAM);
        } else {
            _ = performPrimeFactorization(false);
        }
    }
    return true;
}

// ===========================================================================
// fnEvPFacts
// ===========================================================================
pub export fn fnEvPFacts(param: u16) callconv(.c) void {
    var isValidMxX: bool = false;
    var isValidMxY: bool = false;
    var needsFactorizeX: bool = false;

    // The C `return10:` screen-cleanup ran on every exit; defer replaces the
    // goto so the early returns below are plain.
    defer {
        screenUpdatingMode &= ~SCRUPD_MANUAL_STACK;
        refreshScreen(254);
    }

    if (param != M_FACTORS) {
        if (!ensureFactorizationMatrix(REGISTER_X, false, false, &isValidMxX)) {
            return;
        }
        needsFactorizeX = !isValidMxX and (param == M_SIGMA_0 or param == M_SIGMA_1 or param == M_SIGMA_p1);
    }

    if (!saveLastX()) {
        return;
    }
    saveForUndo();

    if (needsFactorizeX) {
        if (!ensureFactorizationMatrix(REGISTER_X, false, true, &isValidMxX)) {
            return;
        }
    }

    // pre-processing
    switch (param) {
        M_SIGMA_0, M_SIGMA_1, M_SIGMA_p1 => {
            // nothing - X already ensured to be factorization matrix
        },
        M_SIGMA_k, M_SIGMA_pk => {
            if (!ensureFactorizationMatrix(REGISTER_Y, false, false, &isValidMxY)) {
                return;
            }
            if (!isValidMxY) {
                if (!ensureFactorizationMatrix(REGISTER_Y, false, true, &isValidMxY)) {
                    return;
                }
            }
        },
        M_FACTORS => {},
        M_PHI_EUL => {},
        else => {},
    }

    // processing
    switch (param) {
        M_SIGMA_0, M_SIGMA_1, M_SIGMA_k, M_SIGMA_p1, M_SIGMA_pk, M_FACTORS => {
            if (lastErrorCode == 0) {
                doFnEvPFacts(param);
            }
        },
        M_PHI_EUL => {
            fnEulPhi(NOPARAM);
        },
        else => {},
    }
}

// ===========================================================================
// fnEulPhi
// ===========================================================================
fn fnEulPhi(unused_but_mandatory_parameter: u16) void {
    var isMxXNegative: bool = false;
    var x: mpz_struct = undefined;
    const useMatrix = isRegisterMatrixFactors(REGISTER_X, &isMxXNegative);
    var xx: real34Matrix_t = undefined;

    if (useMatrix) {
        convertReal34MatrixRegisterToReal34Matrix(REGISTER_X, &xx);
        doFnEvPFacts(M_FACTORS);
    }

    if (!getIntArg(&x, REGISTER_X)) {
        if (useMatrix) {
            convertReal34MatrixToReal34MatrixRegister(&xx, REGISTER_X);
        }
        longIntegerFree(&x);
        return;
    }
    // defer replaces the return1/return2 goto-cleanup. GMP clears are independent,
    // so LIFO vs the C's fixed order is behavior-equivalent (ASAN-gated). p_li/
    // p_li_less_1 stay manual -- they are init'd and freed inside the loop.
    defer longIntegerFree(&x);

    if (useMatrix) {
        convertReal34MatrixToReal34MatrixRegister(&xx, REGISTER_X);
    }

    var phi_x: mpz_struct = undefined;
    var p_li: mpz_struct = undefined;
    var p_li_less_1: mpz_struct = undefined;
    var phi_x_tmp: mpz_struct = undefined;
    var phi_x_tmp_b: mpz_struct = undefined;
    longIntegerInit(&phi_x);
    longIntegerInit(&phi_x_tmp);
    longIntegerInit(&phi_x_tmp_b);
    defer longIntegerFree(&phi_x);
    defer longIntegerFree(&phi_x_tmp);
    defer longIntegerFree(&phi_x_tmp_b);
    var matrix: real34Matrix_t = undefined;

    // Returns true to indicate "goto returnValue".
    const gotoReturnValue = blk: {
        // Check for the trivial case x = 0
        if (longIntegerIsZero(&x)) {
            longIntegerCopy(&x, &phi_x);
            break :blk true;
        }
        longIntegerSubtractUInt(&x, 1, &phi_x_tmp);
        // Check for the trivial case x = 1
        if (longIntegerIsZero(&phi_x_tmp)) {
            longIntegerCopy(&x, &phi_x);
            break :blk true;
        }

        if (!useMatrix) {
            fnPrimeFactors(unused_but_mandatory_parameter);
        }
        if (getRegisterDataType(REGISTER_X) == dtReal34Matrix) {
            math_matrix_register_link.linkToRealMatrixRegister(REGISTER_X, &matrix);
            const rows: u16 = registerMatrixHeader(REGISTER_X).matrixRows;
            const cols: u16 = registerMatrixHeader(REGISTER_X).matrixColumns;
            if (rows == 2 and cols >= 1) {
                const elems = matrixElementsPtr(&matrix);
                longIntegerCopy(&x, &phi_x);
                var j: u16 = 0;
                while (j < cols) : (j += 1) {
                    var p: real34_t = elems[j];
                    convertReal34ToLongInteger(&p, &p_li, currentRoundingMode());
                    longIntegerInit(&p_li_less_1);
                    longIntegerSubtractUInt(&p_li, 1, &p_li_less_1);
                    if (j == 0 and !longIntegerIsPositive(&p_li_less_1)) {
                        uInt32ToLongInteger(0, &phi_x);
                        longIntegerFree(&p_li);
                        longIntegerFree(&p_li_less_1);
                        break;
                    }
                    longIntegerCopy(&phi_x, &phi_x_tmp);
                    longIntegerDivide(&phi_x_tmp, &p_li, &phi_x_tmp_b);
                    longIntegerMultiply(&phi_x_tmp_b, &p_li_less_1, &phi_x);
                    longIntegerFree(&p_li);
                    longIntegerFree(&p_li_less_1);
                }
            } else {
                // matrix dimensions wrong
                return;
            }
        } else {
            displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnError("In function fnEulPhi:", "The intermediate prime factor matrix could not be found.", null, null);
            return;
        }
        break :blk false;
    };
    _ = gotoReturnValue;

    convertLongIntegerToLongIntegerRegister(&phi_x, REGISTER_X);
    adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
}

// ===========================================================================
// Perfect-square helpers
// ===========================================================================
extern fn sqrt(x: f64) f64;

fn is_perfect_square_uint32(n: u32, sqrt_out: ?*u32) c_int {
    const r: u32 = @intFromFloat(sqrt(@as(f64, @floatFromInt(n))));
    if (r *% r == n) {
        if (sqrt_out) |so| {
            so.* = r;
        }
        return 1;
    }
    if ((r +% 1) *% (r +% 1) == n) {
        if (sqrt_out) |so| {
            so.* = r + 1;
        }
        return 1;
    }
    return 0;
}

fn longIntegerIsPerfectSquareCheckAndDo(n: *const mpz_struct, r: *mpz_struct) c_int {
    if (mpz_fits_uint_p(n)) {
        const small: u32 = @truncate(mpz_get_ui(n));
        var sqrt_small: u32 = undefined;
        if (is_perfect_square_uint32(small, &sqrt_small) != 0) {
            uInt32ToLongInteger(sqrt_small, r);
            return 1;
        }
        return 0;
    }
    if (longIntegerPerfectSquare(n) != 0) {
        longIntegerSquareRoot(n, r);
        return 1;
    }
    return 0;
}

// ===========================================================================
// SQUFOF (Shanks square forms factorization, with parallel Pollard rho)
// ===========================================================================
var loopp: i32 = 0;

fn SQUFOF(result: *mpz_struct, N: *const mpz_struct, lastAdded: *const real34_t) void {
    var k: u32 = undefined;
    var BB: mpz_struct = undefined;
    var LL: mpz_struct = undefined;
    var ii: mpz_struct = undefined;
    var D: mpz_struct = undefined;
    var Po: mpz_struct = undefined;
    var P: mpz_struct = undefined;
    var Pprev: mpz_struct = undefined;
    var Q: mpz_struct = undefined;
    var Qprev: mpz_struct = undefined;
    var q: mpz_struct = undefined;
    var b: mpz_struct = undefined;
    var r: mpz_struct = undefined;
    var ss: mpz_struct = undefined;
    var temp1: mpz_struct = undefined;
    var temp2: mpz_struct = undefined;
    var temp3: mpz_struct = undefined;
    var gcd_result: mpz_struct = undefined;
    longIntegerInit(&BB);
    longIntegerInit(&LL);
    longIntegerInit(&ii);
    longIntegerInit(&D);
    longIntegerInit(&Po);
    longIntegerInit(&P);
    longIntegerInit(&Pprev);
    longIntegerInit(&Q);
    longIntegerInit(&Qprev);
    longIntegerInit(&q);
    longIntegerInit(&b);
    longIntegerInit(&r);
    longIntegerInit(&ss);
    longIntegerInit(&temp1);
    longIntegerInit(&temp2);
    longIntegerInit(&temp3);
    longIntegerInit(&gcd_result);

    // Pollard simultaneous analysis setup
    var pollardData: pollard_t = undefined;
    var instruction: factors_status_t = .FACTORS_SETUP;
    var PollardResult: factors_result_t = undefined;
    var n: mpz_struct = undefined;
    var pollardFactor: mpz_struct = undefined;
    if (Factors_3_Pollard) {
        longIntegerInit(&n);
        longIntegerInit(&pollardFactor);
        longIntegerCopy(N, &n);
        pollard_init(&pollardData);
        pollard_update_n(&pollardData, &n);
    }

    // The cleanup block (free everything) is duplicated at each exit. Use a
    // labeled block to emulate `goto cleanup`.
    cleanup: {
        // Check if N is a perfect square
        if (longIntegerIsPerfectSquareCheckAndDo(N, &ss) != 0) {
            longIntegerCopy(&ss, result);
            break :cleanup;
        }

        // Calculate s = sqrt(N)
        longIntegerSquareRoot(N, &ss);

        k = 0;
        kloop: while (k < multipliers_squfof.len) : (k += 1) {
            // D = multiplier[k] * N
            longIntegerMultiplyUInt(N, @bitCast(multipliers_squfof[k]), &D);

            // Po = Pprev = P = sqrt(D)
            longIntegerSquareRoot(&D, &Po);
            longIntegerCopy(&Po, &Pprev);
            longIntegerCopy(&Po, &P);

            // Qprev = 1
            uInt32ToLongInteger(1, &Qprev);

            // Q = D - Po*Po
            longIntegerMultiply(&Po, &Po, &temp1);
            longIntegerSubtract(&D, &temp1, &Q);
            if (longIntegerSign(&Q) == 0) {
                continue; // Q is zero; no factor found
            }

            // LL = 2 * sqrt(2*s)
            longIntegerMultiplyUInt(&ss, 2, &temp1);
            longIntegerSquareRoot(&temp1, &temp2);
            longIntegerMultiplyUInt(&temp2, 2, &LL);

            // BB = 3 * LL
            longIntegerMultiplyUInt(&LL, 3, &BB);

            // Initialize i
            uInt32ToLongInteger(2, &ii);

            while (longIntegerCompare(&ii, &BB) < 0) {
                loopp += 1;
                if (checkHalfSec()) {
                    keepFileNameAlive();
                    if (progressHalfSecUpdate_Integer(halfSec_timed, "Factors: Shanks/Pollard n =", loopp, halfSec_clearZ, halfSec_clearT, halfSec_disp)) {
                        _showProgress(lastAdded, &n);
                        force_refresh(halfSec_force);
                    }
                }
                if (exitKeyWaiting() or programRunStop == PGM_WAITING) {
                    _ = progressHalfSecUpdate_Integer(halfSec_force + 1, "Interrupted: ", loopp, halfSec_clearZ, halfSec_clearT, halfSec_disp);
                    programRunStop = PGM_WAITING;
                    break;
                }

                // Pollard simultaneous analysis - interject a few steps
                if (Factors_3_Pollard and (instruction == .FACTORS_ITERATE or instruction == .FACTORS_SETUP)) {
                    PollardResult = pollard_step(&pollardData, &pollardFactor, instruction, 10);
                    if (programRunStop == PGM_WAITING) {
                        break :kloop; // goto Broken
                    }
                    if (PollardResult.status == .FACTORS_DONE) {
                        longIntegerCopy(&pollardFactor, result);
                        break :cleanup;
                    }
                    instruction = PollardResult.status;
                }
                // Pollard end

                // b = (Po + P) / Q
                longIntegerAdd(&Po, &P, &temp1);
                longIntegerDivide(&temp1, &Q, &b);

                // P = b*Q - P
                longIntegerMultiply(&b, &Q, &temp1);
                longIntegerSubtract(&temp1, &P, &temp2);
                longIntegerCopy(&temp2, &P);
                // q = Q
                longIntegerCopy(&Q, &q);
                // Q = Qprev + b*(Pprev - P)
                longIntegerSubtract(&Pprev, &P, &temp1);
                longIntegerMultiply(&b, &temp1, &temp2);
                longIntegerAdd(&Qprev, &temp2, &Q);
                // r = sqrt(Q)
                longIntegerSquareRoot(&Q, &r);
                // Check if i is even and r*r == Q
                if (longIntegerIsEven(&ii) and longIntegerIsPerfectSquareCheckAndDo(&Q, &temp1) != 0) {
                    break;
                }

                // Qprev = q; Pprev = P
                longIntegerCopy(&q, &Qprev);
                longIntegerCopy(&P, &Pprev);

                // Increment i
                longIntegerAddUInt(&ii, 1, &ii);
            }

            if (longIntegerCompare(&ii, &BB) >= 0) {
                continue;
            }

            // b = (Po - P) / r
            longIntegerSubtract(&Po, &P, &temp1);
            longIntegerDivide(&temp1, &r, &b);

            // Pprev = P = b*r + P
            longIntegerMultiply(&b, &r, &temp1);
            longIntegerAdd(&temp1, &P, &temp2);
            longIntegerCopy(&temp2, &Pprev);
            longIntegerCopy(&temp2, &P);

            // Qprev = r
            longIntegerCopy(&r, &Qprev);

            // Q = (D - Pprev*Pprev) / Qprev
            longIntegerMultiply(&Pprev, &Pprev, &temp1);
            longIntegerSubtract(&D, &temp1, &temp2);
            longIntegerDivide(&temp2, &Qprev, &Q);

            while (true) {
                loopp += 1;
                if (checkHalfSec()) {
                    keepFileNameAlive();
                    if (progressHalfSecUpdate_Integer(halfSec_timed, "Factors: Shanks/Pollard n =", loopp, halfSec_clearZ, halfSec_clearT, halfSec_disp)) {
                        _showProgress(lastAdded, &n);
                        force_refresh(halfSec_force);
                    }
                }
                if (exitKeyWaiting() or programRunStop == PGM_WAITING) {
                    _ = progressHalfSecUpdate_Integer(halfSec_force + 1, "Interrupted: ", loopp, halfSec_clearZ, halfSec_clearT, halfSec_disp);
                    programRunStop = PGM_WAITING;
                    break;
                }
                // b = (Po + P) / Q
                longIntegerAdd(&Po, &P, &temp1);
                longIntegerDivide(&temp1, &Q, &b);

                // Pprev = P
                longIntegerCopy(&P, &Pprev);

                // P = b*Q - P
                longIntegerMultiply(&b, &Q, &temp1);
                longIntegerSubtract(&temp1, &P, &P);

                // q = Q
                longIntegerCopy(&Q, &q);

                // Q = Qprev + b*(Pprev - P)
                longIntegerSubtract(&Pprev, &P, &temp1);
                longIntegerMultiply(&b, &temp1, &temp2);
                longIntegerAdd(&Qprev, &temp2, &Q);

                // Qprev = q
                longIntegerCopy(&q, &Qprev);

                if (longIntegerCompare(&P, &Pprev) == 0) break;
            }

            // Broken: (also reached via the kloop break above)
            if (exitKeyWaiting() or programRunStop == PGM_WAITING) {
                _ = progressHalfSecUpdate_Integer(halfSec_force + 1, "Interrupted: ", loopp, halfSec_clearZ, halfSec_clearT, halfSec_disp);
                programRunStop = PGM_WAITING;
                break :kloop;
            }

            // r = gcd(N, Qprev)
            longIntegerGcd(N, &Qprev, &r);

            // Check if r != 1 and r != N
            if (longIntegerCompareUInt(&r, 1) != 0 and longIntegerCompare(&r, N) != 0) {
                longIntegerCopy(&r, result);
                break :cleanup;
            }
        }

        // No factor found
        uInt32ToLongInteger(0, result);
    }

    // cleanup:
    if (Factors_3_Pollard) {
        pollard_clear(&pollardData);
        longIntegerFree(&n);
        longIntegerFree(&pollardFactor);
    }
    longIntegerFree(&BB);
    longIntegerFree(&LL);
    longIntegerFree(&ii);
    longIntegerFree(&D);
    longIntegerFree(&Po);
    longIntegerFree(&P);
    longIntegerFree(&Pprev);
    longIntegerFree(&Q);
    longIntegerFree(&Qprev);
    longIntegerFree(&q);
    longIntegerFree(&b);
    longIntegerFree(&r);
    longIntegerFree(&ss);
    longIntegerFree(&temp1);
    longIntegerFree(&temp2);
    longIntegerFree(&temp3);
    longIntegerFree(&gcd_result);
}

// addFactorsToTSV is only true for huge inputs on real hardware; under the
// testSuite (TESTSUITE_BUILD) it is forced false (see performPrimeFactorization).
var addFactorsToTSV: bool = false;

fn keepFileNameAlive() void {
    if (addFactorsToTSV) {
        preventFilenameTimeout();
    }
}
extern fn preventFilenameTimeout() void;

// ===========================================================================
// delCol1RealMatrixX
// ===========================================================================
fn delCol1RealMatrixX() bool {
    var mat: real34Matrix_t = undefined;
    math_matrix_register_link.linkToRealMatrixRegister(REGISTER_X, &mat);
    const rows: u16 = matHeaderRows(&mat);
    const cols: u16 = matHeaderCols(&mat);
    if (matIsNull(&mat) or cols <= 1) {
        return false;
    }

    const elems = matrixElementsPtr(&mat);
    // every element in column 0 is exactly 1.0 or 0.0
    var removeFirstCol: bool = true;
    {
        var i: u16 = 0;
        while (i < rows) : (i += 1) {
            if (!math_comparison_reals.real34CompareEqual(&elems[i * cols + 0], const34_1()) and !math_comparison_reals.real34CompareEqual(&elems[i * cols + 0], const34_0())) {
                removeFirstCol = false;
                break;
            }
        }
    }
    if (!removeFirstCol) {
        return true;
    }

    var tmp: real34Matrix_t = undefined;
    if (!math_matrix_lifecycle.realMatrixInit(&tmp, rows, cols - 1)) {
        displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
        return false;
    }
    const tmpElems = matrixElementsPtr(&tmp);
    {
        var i: u16 = 0;
        while (i < rows) : (i += 1) {
            var j: u16 = 1;
            while (j < cols) : (j += 1) {
                real34Copy(&elems[i * cols + j], &tmpElems[i * (cols - 1) + (j - 1)]);
            }
        }
    }
    // Re-init the register and free old buffer
    _ = math_matrix_register_memory.initMatrixRegister(REGISTER_X, rows, cols - 1, false);

    const dest = registerReal34MatrixElements(REGISTER_X);
    const total: usize = @as(usize, rows) * (cols - 1);
    {
        var kk: usize = 0;
        while (kk < total) : (kk += 1) {
            real34Copy(&tmpElems[kk], &dest[kk]);
        }
    }
    math_matrix_lifecycle.realMatrixFree(&tmp);
    return true;
}

inline fn matHeaderRows(mat: *real34Matrix_t) u16 {
    return mat.header.matrixRows;
}
inline fn matHeaderCols(mat: *real34Matrix_t) u16 {
    return mat.header.matrixColumns;
}
inline fn matIsNull(mat: *real34Matrix_t) bool {
    if (runtime.harness_surface_is_fake) {
        return false;
    } else {
        return mat.matrixElements == null;
    }
}

// ===========================================================================
// FactorAdder
// ===========================================================================
const FactorAdder_t = struct {
    nExpons: u16,
    expons: [MAX_FACTORS]u16,
};

fn initFactorAdder(faddr: *FactorAdder_t) void {
    faddr.nExpons = 0;
}

fn dumpExponents(regist: calcRegister_t, faddr: *FactorAdder_t, dumpForFewerThan: u16) void {
    const cols: u16 = registerMatrixHeader(regist).matrixColumns;
    const rows: u16 = registerMatrixHeader(regist).matrixRows;

    if (faddr.nExpons != cols or rows != 2 or getRegisterDataType(REGISTER_X) != dtReal34Matrix) {
        displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function dumpExponents:", "Incorrect matrix counters vs. array", null, null);
        return;
    }
    const elems = registerReal34MatrixElements(regist);
    const limit: u16 = @min(faddr.nExpons, dumpForFewerThan);
    var i: u16 = 0;
    while (i < limit) : (i += 1) {
        uInt32ToReal34Impl(faddr.expons[i], &elems[faddr.nExpons + i]);
    }
}

fn pushLongIntegerToJK(factor: *mpz_struct) void {
    copySourceRegisterToDestRegister(REGISTER_H, REGISTER_G);
    copySourceRegisterToDestRegister(REGISTER_K, REGISTER_H);
    convertLongIntegerToLongIntegerRegister(factor, REGISTER_K);
}

fn addFactor(factor: *mpz_struct, regist: calcRegister_t, lastAdded: *real34_t, faddr: *FactorAdder_t) bool {
    if (addFactorsToTSV) {
        convertLongIntegerToLongIntegerRegister(factor, TEMP_REGISTER_1);
        fnP_All_Regs(PRN_TMP);
    }

    pushLongIntegerToJK(factor);

    if (getRegisterDataType(regist) != dtReal34Matrix) {
        if (math_matrix_register_memory.initMatrixRegister(regist, 2, 1, false)) {
            setSystemFlag(@intCast(FLAG_ASLIFT));
        } else {
            if (lastErrorCode != 0) {
                return addFactorReturnFalse();
            }
            displayCalcErrorMessage(ERROR_NOT_ENOUGH_MEMORY_FOR_NEW_MATRIX, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnError("In function addFactor 001:", "Not enough memory for a new matrix", null, null);
            return addFactorReturnFalse();
        }
        adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
    }

    const rows: u16 = registerMatrixHeader(regist).matrixRows;
    if (rows > 2) {
        displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function addFactor:", "Incorrect matrix dimensions", null, null);
        return addFactorReturnFalse();
    }

    if (faddr.nExpons == 0) {
        faddr.nExpons = 1; // has to be 1 now, as we have this factor
        faddr.expons[faddr.nExpons - 1] = 1;
    }
    var wkgCols: u16 = faddr.nExpons;
    if (!math_matrix_register_memory.redimMatrixRegister(regist, rows, wkgCols, ITM_M_DIM)) {
        if (lastErrorCode != 0) {
            return addFactorReturnFalse();
        }
        displayCalcErrorMessage(ERROR_NOT_ENOUGH_MEMORY_FOR_NEW_MATRIX, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function addFactor 002:", "Not enough memory for a matrix", null, null);
        return addFactorReturnFalse();
    }

    var counter: i32 = faddr.nExpons;
    var n: u16 = rows *% @as(u16, @intCast(counter));
    var c: u16 = n / 2;
    var factorR: real34_t = undefined;
    convertLongIntegerToReal34(factor, &factorR);
    const elems = registerReal34MatrixElements(regist);
    // search for existing factors
    while (counter >= 0 and !math_comparison_reals.real34CompareEqual(&factorR, &elems[@intCast(counter)])) {
        counter -= 1;
    }

    // increment exponent if found
    if (longIntegerSign(factor) != 0 and counter >= 0 and !math_comparison_reals.real34CompareAbsEqual(&elems[@intCast(counter)], const34_1())) {
        faddr.expons[@intCast(counter)] += 1;
    } else {
        const incNExpons: bool = if (math_comparison_reals.real34CompareAbsEqual(&factorR, const34_1())) false else true;
        if (!incNExpons) {
            c = 0;
        }
        real34Copy(&factorR, &elems[c]);
        real34Copy(&factorR, lastAdded);
        if (incNExpons) {
            if (faddr.nExpons < MAX_FACTORS) {
                faddr.nExpons += 1;
            } else {
                displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
                moreInfoOnError("In function addFactor 003:", "Maximum number of factors exceeded", null, null);
                return addFactorReturnFalse();
            }

            wkgCols += 1;
            faddr.expons[faddr.nExpons - 1] = 1;
            if (!math_matrix_register_memory.redimMatrixRegister(regist, rows, wkgCols, ITM_M_DIM)) {
                if (lastErrorCode != 0) {
                    return addFactorReturnFalse();
                }
                displayCalcErrorMessage(ERROR_NOT_ENOUGH_MEMORY_FOR_NEW_MATRIX, ERR_REGISTER_LINE, REGISTER_X);
                moreInfoOnError("In function addFactor 004", "Not enough memory for a matrix", null, null);
                return addFactorReturnFalse();
            }
        }
        n = rows *% faddr.nExpons;
        c = n / 2;
    }
    dumpExponents(REGISTER_X, faddr, 13);
    updateMatrixHeightCache();
    refreshRegisterLine(REGISTER_X);

    return true;
}

fn addFactorReturnFalse() bool {
    // returnFalse:
    updateMatrixHeightCache();
    screenUpdatingMode &= ~(SCRUPD_MANUAL_STACK | SCRUPD_SKIP_STACK_ONE_TIME);
    refreshScreen(301);
    return false;
}

extern fn fnP_All_Regs(option: u16) void;

fn printTitles(input: *mpz_struct) void {
    if (addFactorsToTSV) {
        // Host-only TSV file output; never runs under the testSuite. The
        // create_filename/fnStrtoReg/fnP_All_Regs path is omitted; only reachable
        // when addFactorsToTSV is true, which is forced false in TESTSUITE_BUILD.
        convertLongIntegerToLongIntegerRegister(input, TEMP_REGISTER_1);
        fnP_All_Regs(PRN_TMP);
    }
}

// Early multiplier check using 32-bit perfect square test
const multipliers_square = [_]u32{ 1, 3, 5, 7, 11, 15, 21, 33, 35, 55, 65, 77, 91, 105 };

// ===========================================================================
// performPrimeFactorization
// ===========================================================================
fn performPrimeFactorization(doSaveLastX: bool) bool {
    iterations = true;
    loopp = 0;
    currentKeyCode = 255;
    var lastAdded: real34_t = undefined;

    var currentNumber: mpz_struct = undefined;
    var tmp: mpz_struct = undefined;
    var temp1: mpz_struct = undefined;

    longIntegerInit(&tmp);
    longIntegerInit(&temp1);

    // abort: block. Everything that frees and returns false jumps here.
    abort: {
        if (!getIntArg(&currentNumber, REGISTER_X)) {
            break :abort;
        }

        if (longIntegerIsZero(&currentNumber)) {
            badDomainError(REGISTER_X);
            break :abort;
        }

        const sign: i32 = @intFromBool(longIntegerIsNegative(&currentNumber));
        if (sign != 0) {
            longIntegerSetPositiveSign(&currentNumber);
        }

        longIntegerPowerUIntUInt(10, maximumPrime, &tmp);
        longIntegerSubtract(&currentNumber, &tmp, &tmp);
        if (longIntegerIsPositive(&tmp)) {
            badDomainError(REGISTER_X);
            break :abort;
        }

        if (doSaveLastX and !saveLastX()) {
            break :abort;
        }

        real34SetZero(&lastAdded);
        var faddr: FactorAdder_t = undefined;
        initFactorAdder(&faddr);

        // determine if the TSV file is to be written
        var lgInt: mpz_struct = undefined;
        longIntegerInit(&lgInt);
        _ = stringToLongInteger("9999999999999999999999999999999999", 10, &lgInt);
        if (!runtime.is_testsuite_build) {
            addFactorsToTSV = longIntegerCompare(&currentNumber, &lgInt) > 0;
        }
        longIntegerFree(&lgInt);
        printTitles(&currentNumber);

        // capture the sign in the output matrix
        int32ToLongInteger(if (sign != 0) -1 else 1, &tmp);
        if (!addFactor(&tmp, REGISTER_X, &lastAdded, &faddr)) {
            break :abort;
        }

        var queue: [MAXIMUM_QUEUE_SIZE]mpz_struct = undefined;
        var queue_start: i32 = 0;
        var queue_end: i32 = 0;

        var temp: mpz_struct = undefined;
        var factor: mpz_struct = undefined;
        var quotient: mpz_struct = undefined;
        var tempPrePrimeRun: mpz_struct = undefined;
        longIntegerInit(&temp);
        longIntegerInit(&factor);
        longIntegerInit(&quotient);
        longIntegerInit(&tempPrePrimeRun);
        for (&queue) |*qi| {
            longIntegerInit(qi);
        }

        clearScreenOld(false, true, true); // !clrStatusBar, clrRegisterLines, clrSoftkeys
        force_refresh(halfSec_force);

        // cleanup: block (frees the second-part variables and queue)
        cleanup: {
            if (Factors_1_SmallPrimes) {
                var i: u16 = 0;
                while (i < smallPrimeListNumber) : (i += 1) {
                    const smallP: u16 = smallPrimeList(i);
                    while (mpz_divisible_ui_p(&currentNumber, smallP)) {
                        loopp += 1;
                        if (checkHalfSec()) {
                            keepFileNameAlive();
                            if (progressHalfSecUpdate_Integer(halfSec_timed, "Factors: Small prime trial: p =", @intCast(smallP), halfSec_clearZ, halfSec_clearT, halfSec_disp)) {
                                _showProgress(&lastAdded, &currentNumber);
                                dumpExponents(REGISTER_X, &faddr, 13);
                                force_refresh(halfSec_force);
                            }
                        }
                        if (exitKeyWaiting() or programRunStop == PGM_WAITING) {
                            _ = progressHalfSecUpdate_Integer(halfSec_force + 1, "Interrupted: ", loopp, halfSec_clearZ, halfSec_clearT, halfSec_disp);
                            programRunStop = PGM_WAITING;
                            break;
                        }
                        mpz_divexact_ui(&currentNumber, &currentNumber, smallP);
                        uInt32ToLongInteger(smallP, &tempPrePrimeRun);
                        if (!addFactor(&tempPrePrimeRun, REGISTER_X, &lastAdded, &faddr)) {
                            break :cleanup;
                        }
                    }
                }
            }

            if (Factors_2_PerfectSquare) {
                var i: u16 = 0;
                while (i < multipliers_square.len) : (i += 1) {
                    loopp += 1;
                    if (checkHalfSec()) {
                        keepFileNameAlive();
                        if (progressHalfSecUpdate_Integer(halfSec_timed, "Factors: Perfect Sq trial: p =", @intCast(multipliers_square[i]), halfSec_clearZ, halfSec_clearT, halfSec_disp)) {
                            _showProgress(&lastAdded, &currentNumber);
                            dumpExponents(REGISTER_X, &faddr, 13);
                            force_refresh(halfSec_force);
                        }
                    }
                    if (exitKeyWaiting() or programRunStop == PGM_WAITING) {
                        _ = progressHalfSecUpdate_Integer(halfSec_force + 1, "Interrupted: ", loopp, halfSec_clearZ, halfSec_clearT, halfSec_disp);
                        programRunStop = PGM_WAITING;
                        break;
                    }
                    if (mpz_fits_uint_p(&currentNumber)) {
                        const kk: u32 = multipliers_square[i];
                        const n32: u32 = longIntegerToUInt32(&currentNumber);
                        const kn: u64 = @as(u64, kk) * @as(u64, n32);
                        var root: u32 = undefined;
                        if (is_perfect_square_uint32(@truncate(kn), &root) != 0) {
                            // Skip trivial perfect square 1 * 1 = 1
                            if (!(kk == 1 and root == 1)) {
                                var gcd: mpz_struct = undefined;
                                longIntegerInit(&gcd);
                                mpz_gcd_ui(&gcd, &currentNumber, root);
                                if (longIntegerCompareUInt(&gcd, 1) > 0) {
                                    if (!addFactor(&gcd, REGISTER_X, &lastAdded, &faddr)) {
                                        longIntegerFree(&gcd);
                                        break :cleanup;
                                    }
                                    mpz_divexact(&currentNumber, &currentNumber, &gcd);
                                    longIntegerFree(&gcd);
                                    break;
                                }
                                longIntegerFree(&gcd);
                            }
                        }
                    }
                }
            }

            // SQUFOF SHANKS & POLLARD RHO FACTORISATION START
            longIntegerCopy(&currentNumber, &queue[@intCast(queue_end)]);
            queue_end = @intCast(@mod(queue_end + 1, @as(i32, MAXIMUM_QUEUE_SIZE)));

            var current: mpz_struct = undefined;
            longIntegerInit(&current);
            // doneWhile: block frees `current`.
            doneWhile: {
                while (queue_start != queue_end) {
                    longIntegerCopy(&queue[@intCast(queue_start)], &current);
                    queue_start = @intCast(@mod(queue_start + 1, @as(i32, MAXIMUM_QUEUE_SIZE)));

                    loopp += 1;
                    if (checkHalfSec()) {
                        keepFileNameAlive();
                        if (progressHalfSecUpdate_Integer(halfSec_timed, "Factors: Shanks/Pollard: n =", loopp, halfSec_clearZ, halfSec_clearT, halfSec_disp)) {
                            _showProgress(&lastAdded, &current);
                            dumpExponents(REGISTER_X, &faddr, 13);
                            force_refresh(halfSec_force);
                        }
                    }
                    if (exitKeyWaiting() or programRunStop == PGM_WAITING) {
                        _ = progressHalfSecUpdate_Integer(halfSec_force + 1, "Interrupted: ", loopp, halfSec_clearZ, halfSec_clearT, halfSec_disp);
                        programRunStop = PGM_WAITING;
                        break;
                    }

                    // Skip if current is 1
                    if (longIntegerCompareUInt(&current, 1) == 0) {
                        continue;
                    }

                    // Check if current is prime
                    if (longIntegerProbabPrime(&current) != 0) {
                        if (!addFactor(&current, REGISTER_X, &lastAdded, &faddr)) {
                            break :doneWhile;
                        }
                        continue;
                    }

                    // Attempt to find a factor using SQUFOF
                    SQUFOF(&factor, &current, &lastAdded);
                    if (longIntegerCompareUInt(&factor, 0) == 0 or longIntegerCompare(&factor, &current) == 0) {
                        // SQUFOF failed; treat current as prime
                        if (!addFactor(&current, REGISTER_X, &lastAdded, &faddr)) {
                            break :doneWhile;
                        }
                        continue;
                    }

                    // Divide current by the found factor
                    mpz_divexact(&quotient, &current, &factor);

                    // Enqueue the factor and quotient for further factorization
                    const next_end: i32 = @intCast(@mod(queue_end + 1, @as(i32, MAXIMUM_QUEUE_SIZE)));
                    const next_next_end: i32 = @intCast(@mod(next_end + 1, @as(i32, MAXIMUM_QUEUE_SIZE)));
                    if (next_next_end != queue_start) {
                        longIntegerCopy(&factor, &queue[@intCast(queue_end)]);
                        queue_end = next_end;
                        longIntegerCopy(&quotient, &queue[@intCast(queue_end)]);
                        queue_end = next_next_end;
                    } else {
                        if (lastErrorCode != 0) {
                            break;
                        }
                        displayCalcErrorMessage(ERROR_NOT_ENOUGH_MEMORY_FOR_NEW_MATRIX, ERR_REGISTER_LINE, REGISTER_X);
                        moreInfoOnError("In function performPrimeFactorization:  Queue overflow:", "Not enough memory for a matrix", null, null);
                        break;
                    }
                }
            }
            // doneWhile:
            longIntegerFree(&current);
        }

        // cleanup:
        longIntegerFree(&temp);
        longIntegerFree(&factor);
        longIntegerFree(&quotient);
        longIntegerFree(&tempPrePrimeRun);
        for (&queue) |*qi| {
            longIntegerFree(qi);
        }

        dumpExponents(REGISTER_X, &faddr, 65535);
        _ = delCol1RealMatrixX();
    }

    // abort:
    uInt32ToLongInteger(1, &tmp);
    convertLongIntegerToLongIntegerRegister(&tmp, TEMP_REGISTER_1);
    longIntegerFree(&tmp);
    longIntegerFree(&temp1);
    longIntegerFree(&currentNumber);
    cancelFilename = true;
    iterations = false;
    return false;
}

// ===========================================================================
// fnPrimeFactors
// ===========================================================================
pub export fn fnPrimeFactors(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    _ = performPrimeFactorization(true);
}

// ===========================================================================
// Pollard's Rho
// ===========================================================================
fn f(result: *mpz_struct, x: *mpz_struct, c: *mpz_struct, n: *const mpz_struct) void {
    longIntegerSquare(x, result); // x^2
    longIntegerAdd(result, c, result); // + c
    longIntegerModulo(result, n, result); // mod n
}

fn pollard_init(self: *pollard_t) void {
    longIntegerInit(&self.n);
    longIntegerInit(&self.x);
    longIntegerInit(&self.y);
    longIntegerInit(&self.c);
    longIntegerInit(&self.d);
    longIntegerInit(&self.tmp);
    self.iteration = 0;
    self.attempt = 0;

    // Deterministically seed the RNG for repeatability.
    self.rng.state = 0x853c49e6748fea9b;
    self.rng.inc = 0xda3e39cb94b95bdb;
}

fn mpz_urandomm_pcg32(rop: *mpz_struct, rng: *pcg32_random_t, n: *const mpz_struct) void {
    const n_bits: usize = mpz_sizeinbase(n, 2);
    var temp: mpz_struct = undefined;
    mpz_init(&temp);
    var bits_generated: usize = 0;
    while (bits_generated < n_bits + 32) {
        const random_val: u32 = math_command_wrappers.pcg32_random_r(rng);
        mpz_mul_2exp(&temp, &temp, 32);
        mpz_add_ui(&temp, &temp, random_val);
        bits_generated += 32;
    }
    mpz_mod(rop, &temp, n);
    mpz_clear(&temp);
}

fn pollard_clear(self: *pollard_t) void {
    longIntegerFree(&self.n);
    longIntegerFree(&self.x);
    longIntegerFree(&self.y);
    longIntegerFree(&self.c);
    longIntegerFree(&self.d);
    longIntegerFree(&self.tmp);
}

fn pollard_update_n(self: *pollard_t, new_n: *const mpz_struct) void {
    longIntegerCopy(new_n, &self.n);
    self.attempt = 0;
    self.iteration = 0;

    uInt32ToLongInteger(1, &self.c); // Start with f(x) = x^2 + 1
    mpz_urandomm_pcg32(&self.x, &self.rng, &self.n);
    longIntegerCopy(&self.x, &self.y);
    uInt32ToLongInteger(1, &self.d);
}

fn pollard_step(self: *pollard_t, factor: *mpz_struct, instruction: factors_status_t, steps: c_int) factors_result_t {
    var result: factors_result_t = undefined;
    result.status = .FACTORS_ITERATE;
    result.iterations_this_call = 0;
    result.total_iterations = self.iteration;
    result.attempts = self.attempt;
    // First-time or forced re-setup
    if (instruction == .FACTORS_RESET or (instruction == .FACTORS_SETUP and self.iteration >= maxIter(self))) {
        const cur_attempt = self.attempt;
        self.attempt += 1;
        if (cur_attempt >= max_attempts) {
            result.status = .FACTORS_FAIL;
            return result;
        }

        // Try different polynomial function based on attempt number
        if (@mod(self.attempt, 3) == 0) {
            uInt32ToLongInteger(1, &self.c); // f(x) = x^2 + 1
        } else if (@mod(self.attempt, 3) == 1) {
            uInt32ToLongInteger(2, &self.c); // f(x) = x^2 + 2
        } else {
            mpz_urandomm_pcg32(&self.c, &self.rng, &self.n); // Random c
        }
        mpz_urandomm_pcg32(&self.x, &self.rng, &self.n);
        longIntegerCopy(&self.x, &self.y);
        uInt32ToLongInteger(1, &self.d);
        self.iteration = 0;
        result.status = .FACTORS_ITERATE;
        return result;
    }
    // Perform up to `steps` iterations
    if (instruction == .FACTORS_ITERATE) {
        var i: c_int = 0;
        while (i < steps) : (i += 1) {
            self.iteration += 1;
            if (self.iteration >= maxIter(self)) {
                result.status = .FACTORS_SETUP; // Too long without result — reseed
                break;
            }
            // Floyd's cycle detection: tortoise and hare
            f(&self.x, &self.x, &self.c, &self.n); // tortoise: 1 step
            f(&self.y, &self.y, &self.c, &self.n); // hare: 2 steps
            f(&self.y, &self.y, &self.c, &self.n);
            longIntegerSubtract(&self.x, &self.y, &self.tmp);
            mpz_abs(&self.tmp, &self.tmp);
            longIntegerGcd(&self.tmp, &self.n, &self.d);
            // Factor found!
            if (longIntegerCompareUInt(&self.d, 1) > 0 and longIntegerCompare(&self.d, &self.n) < 0) {
                longIntegerCopy(&self.d, factor);
                result.status = .FACTORS_DONE;
                break;
            }
            // Fail — retry from new seed
            if (longIntegerCompare(&self.d, &self.n) == 0) {
                result.status = .FACTORS_SETUP;
                break;
            }
            result.iterations_this_call += 1;
        }
    }
    result.total_iterations = self.iteration;
    result.attempts = self.attempt;
    return result;
}
