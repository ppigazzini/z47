// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/mathematics/opmod.c: the modular MULMOD / EXPMOD
// commands (fnMulMod / fnExpMod / fnOpMod) and the full opModL/opModS/opModR
// data-type dispatch matrices, plus longInteger_mulmod / longInteger_expmod.
// Faithful line-by-line translation preserving the exact order of every real_t
// and mpz operation (mulmod.txt / expmod.txt / idiv.txt / idivr.txt check
// results to the last ULP). Exports the opmod.h commands with C linkage; only
// opModError stays externally visible besides the fn* commands and the two
// longInteger_* helpers. The EXTRA_INFO_ON_CALC_ERROR sprintf hints become
// fixed moreInfoOnError strings (no-op under TESTSUITE / DMCP).

const runtime = @import("../dispatch/command_wrappers_runtime.zig");

const abi = @import("abi");
const math_comparison_reals = @import("../compare/comparison_reals.zig");
const real_t = runtime.real_t;
const real34_t = runtime.real34_t;
const realContext_t = runtime.realContext_t;
const calcRegister_t = runtime.calcRegister_t;

const realMultiply = runtime.realMultiply;

const WP34S_Mod = runtime.WP34S_Mod;

const REGISTER_X = runtime.REGISTER_X;
const REGISTER_Y = runtime.REGISTER_Y;
const REGISTER_Z = runtime.REGISTER_Z;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const ERROR_INVALID_DATA_TYPE_FOR_OP = runtime.ERROR_INVALID_DATA_TYPE_FOR_OP;
const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN = runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN;
const ERROR_NONE: u8 = 0;
const amNone = runtime.amNone;
const dtReal34 = runtime.dtReal34;
const dtLongInteger = runtime.dtLongInteger;
const dtShortInteger = runtime.dtShortInteger;
const DEC_ROUND_FLOOR = runtime.DEC_ROUND_FLOOR;
const NOPARAM: u16 = 9876;

const OPMOD_MULTIPLY: u16 = 0;
const OPMOD_POWER: u16 = 1;

const displayCalcErrorMessage = runtime.displayCalcErrorMessage;
const moreInfoOnError = runtime.moreInfoOnError;

inline fn const_0() *const real_t {
    return runtime.z47_math_wrappers_const_0();
}
inline fn const_1() *const real_t {
    return runtime.z47_math_wrappers_const_1();
}

extern fn decimal128ToNumber(source: *align(1) const real34_t, destination: *real_t) *real_t;
inline fn real34ToReal(source: *align(1) const real34_t, destination: *real_t) void {
    _ = decimal128ToNumber(source, destination);
}
const registerReal34Data = abi.registerReal34;

extern var lastErrorCode: u8;
const saveLastX = runtime.saveLastX;
const adjustResult = runtime.adjustResult;
const fnDropY = runtime.fnDropY;
const getRegisterDataType = runtime.getRegisterDataType;
const reallocateRegister = runtime.reallocateRegister;
const convertRealToReal34ResultRegister = runtime.convertRealToReal34ResultRegister;
const getRegisterAngularMode = runtime.getRegisterAngularMode;

extern fn convertRealToLongInteger(real: *const real_t, lgInt: *mpz_struct, mode: c_int) void;
extern fn convertLongIntegerToReal(source: *mpz_struct, destination: *real_t, ctxt: *realContext_t) void;
extern fn convertLongIntegerRegisterToLongInteger(reg: calcRegister_t, lgInt: *mpz_struct) void;
extern fn convertShortIntegerRegisterToLongIntegerRegister(source: calcRegister_t, dest: calcRegister_t) void;
extern fn convertLongIntegerRegisterToShortIntegerRegister(source: calcRegister_t, dest: calcRegister_t) void;
extern fn convertShortIntegerRegisterToReal34Register(source: calcRegister_t, dest: calcRegister_t) void;
extern fn convertShortIntegerRegisterToUInt64(regist: calcRegister_t, sign: *i16, value: *u64) void;
extern fn convertUInt64ToShortIntegerRegister(sign: i16, value: u64, base: u32, regist: calcRegister_t) void;
// Declared against the local mpz_struct (identical ABI; just a pointer).
extern fn convertLongIntegerToLongIntegerRegister(long_integer: *const mpz_struct, regist: calcRegister_t) void;
const setRegisterTag = runtime.setRegisterTag;
const getRegisterTag = runtime.getRegisterTag;
inline fn getRegisterShortIntegerBase(reg: calcRegister_t) u32 {
    return getRegisterTag(reg);
}
inline fn setRegisterShortIntegerBase(reg: calcRegister_t, base: u32) void {
    setRegisterTag(reg, base);
}

extern fn WP34S_mulmod(a: u64, b: u64, c: u64) u64;
extern fn WP34S_expmod(a: u64, b: u64, c: u64) u64;

// ---------------------------------------------------------------------------
// GMP long integer (mpz).
// ---------------------------------------------------------------------------
const mp_limb_t = usize;
const mpz_struct = abi.Mpz;
const longInteger_t = [1]mpz_struct;

extern fn __gmpz_init(op: *mpz_struct) void;
extern fn __gmpz_clear(op: *mpz_struct) void;
extern fn __gmpz_set(rop: *mpz_struct, op: *const mpz_struct) void;
extern fn __gmpz_set_ui(rop: *mpz_struct, op: c_ulong) void;
extern fn __gmpz_cmp_si(op: *const mpz_struct, v: c_long) c_int;
extern fn __gmpz_mul_ui(rop: *mpz_struct, op: *const mpz_struct, v: c_ulong) void;
extern fn __gmpz_tdiv_q_ui(q: *mpz_struct, n: *const mpz_struct, d: c_ulong) c_ulong;
extern fn __gmpz_mod(r: *mpz_struct, n: *const mpz_struct, d: *const mpz_struct) void;

inline fn longIntegerInit(op: *mpz_struct) void {
    __gmpz_init(op);
}
inline fn longIntegerFree(op: *mpz_struct) void {
    __gmpz_clear(op);
}
inline fn longIntegerCopy(source: *const mpz_struct, destination: *mpz_struct) void {
    __gmpz_set(destination, source);
}
inline fn uInt32ToLongInteger(source: u32, destination: *mpz_struct) void {
    __gmpz_set_ui(destination, source);
}
inline fn longIntegerSetZero(op: *mpz_struct) void {
    // Previous implementation matched C: clear + init.
    __gmpz_clear(op);
    __gmpz_init(op);
}
inline fn longIntegerIsPositive(op: *const mpz_struct) bool {
    return op._mp_size > 0;
}
inline fn longIntegerIsOdd(op: *const mpz_struct) bool {
    return op._mp_size != 0 and (op._mp_d[0] & 1) != 0;
}
inline fn longIntegerCompareInt(op: *const mpz_struct, sint: i32) i32 {
    return __gmpz_cmp_si(op, sint);
}
inline fn longIntegerMultiplyUInt(op: *const mpz_struct, u: u32, result: *mpz_struct) void {
    __gmpz_mul_ui(result, op, u);
}
inline fn longIntegerDivideUInt(op: *const mpz_struct, u: u32, result: *mpz_struct) void {
    _ = __gmpz_tdiv_q_ui(result, op, u);
}
inline fn longIntegerModulo(op1: *const mpz_struct, op2: *const mpz_struct, result: *mpz_struct) void {
    __gmpz_mod(result, op1, op2);
}

// Overflow-guarded operators (integers owner).
extern fn longIntegerAdd(opY: *mpz_struct, opX: *mpz_struct, result: *mpz_struct) void;

// ===========================================================================
// opModError / opModOutOfDomain
// ===========================================================================
pub export fn opModError(mode: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = mode;
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    moreInfoOnError("In function fnOpMod:", "cannot MOD", null, null);
}

fn opModOutOfDomain(mode: u16) linksection(runtime.code_section) void {
    _ = mode;
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    moreInfoOnError("In function fnOpMod:", "At least one of the arguments is out of the domain: Z > 0, Y > 0, X > 1", null, null);
}

// ===========================================================================
// parseReal / toRealResult
// ===========================================================================
fn parseReal(regist: calcRegister_t, longIntVal: *mpz_struct, exponent: *i32) linksection(runtime.code_section) void {
    var r: real_t = undefined;

    real34ToReal(registerReal34Data(regist), &r);

    if (r.exponent < 0) {
        exponent.* = -r.exponent;
        r.exponent = 0;
    }
    longIntegerInit(longIntVal);
    convertRealToLongInteger(&r, longIntVal, DEC_ROUND_FLOOR);
}

fn toRealResult(longIntVal: *mpz_struct, exponent: i32) linksection(runtime.code_section) void {
    var r: real_t = undefined;

    convertLongIntegerToReal(longIntVal, &r, &runtime.ctxtReal75);
    r.exponent -= exponent;
    reallocateRegister(REGISTER_X, dtReal34, 0, @intCast(amNone));
    convertRealToReal34ResultRegister(&r, REGISTER_X);
}

// ===========================================================================
// longInteger_mulmod (adapted from WP34s integer-mode mulmod)
// ===========================================================================
pub export fn longInteger_mulmod(a: *const mpz_struct, exp_a: i32, b: *const mpz_struct, exp_b: i32, c: *const mpz_struct, exp_c: i32, res: *mpz_struct, exp_res: ?*i32) linksection(runtime.code_section) callconv(.c) void {
    var x: mpz_struct = undefined;
    var y: mpz_struct = undefined;
    var aa: mpz_struct = undefined;
    var bb: mpz_struct = undefined;
    var cc: mpz_struct = undefined;
    var i: i32 = undefined;

    if (exp_res) |er| {
        er.* = exp_a + exp_b;
    }

    longIntegerInit(&x);
    longIntegerInit(&y);
    longIntegerInit(&aa);
    longIntegerInit(&bb);
    longIntegerInit(&cc);

    longIntegerCopy(a, &aa);
    longIntegerCopy(c, &cc);
    i = 0;
    while (i < (exp_c - exp_b - exp_a)) : (i += 1) {
        longIntegerMultiplyUInt(&aa, 10, &aa);
    }
    i = 0;
    while (i < (exp_a + exp_b - exp_c)) : (i += 1) {
        longIntegerMultiplyUInt(&cc, 10, &cc);
    }

    longIntegerSetZero(&x);
    longIntegerModulo(&aa, &cc, &y);
    longIntegerCopy(b, &bb);

    while (longIntegerCompareInt(&bb, 0) > 0) {
        if (longIntegerIsOdd(&bb)) {
            longIntegerAdd(&x, &y, &x);
            longIntegerModulo(&x, &cc, &x);
        }
        longIntegerAdd(&y, &y, &y);
        longIntegerModulo(&y, &cc, &y);
        longIntegerDivideUInt(&bb, 2, &bb);
    }
    longIntegerModulo(&x, &cc, res);

    longIntegerFree(&x);
    longIntegerFree(&y);
    longIntegerFree(&aa);
    longIntegerFree(&bb);
    longIntegerFree(&cc);
}

// ===========================================================================
// longInteger_expmod
// ===========================================================================
pub export fn longInteger_expmod(a: *const mpz_struct, b: *const mpz_struct, c: *const mpz_struct, res: *mpz_struct) linksection(runtime.code_section) callconv(.c) void {
    var x: mpz_struct = undefined;
    var y: mpz_struct = undefined;
    var bb: mpz_struct = undefined;

    longIntegerInit(&x);
    longIntegerInit(&y);
    longIntegerInit(&bb);

    uInt32ToLongInteger(1, &x);
    longIntegerModulo(a, c, &y);
    longIntegerCopy(b, &bb);

    while (longIntegerCompareInt(&bb, 0) > 0) {
        if (longIntegerIsOdd(&bb)) {
            longInteger_mulmod(&x, 0, &y, 0, c, 0, &x, null);
        }
        longInteger_mulmod(&y, 0, &y, 0, c, 0, &y, null);
        longIntegerDivideUInt(&bb, 2, &bb);
    }
    longIntegerModulo(&x, c, res);

    longIntegerFree(&x);
    longIntegerFree(&y);
    longIntegerFree(&bb);
}

// ===========================================================================
// opModLonILonILonI and friends
// ===========================================================================
pub export fn opModLonILonILonI(mode: u16) linksection(runtime.code_section) callconv(.c) void {
    var x: mpz_struct = undefined;
    var y: mpz_struct = undefined;
    var z: mpz_struct = undefined;

    convertLongIntegerRegisterToLongInteger(REGISTER_X, &x);
    convertLongIntegerRegisterToLongInteger(REGISTER_Y, &y);
    convertLongIntegerRegisterToLongInteger(REGISTER_Z, &z);

    if ((longIntegerCompareInt(&x, 1) > 0) and longIntegerIsPositive(&y) and longIntegerIsPositive(&z)) {
        if (mode == OPMOD_POWER) {
            longInteger_expmod(&z, &y, &x, &x);
        } else {
            longInteger_mulmod(&z, 0, &y, 0, &x, 0, &x, null);
        }
        convertLongIntegerToLongIntegerRegister(&x, REGISTER_X);
    } else {
        opModOutOfDomain(mode);
    }

    longIntegerFree(&x);
    longIntegerFree(&y);
    longIntegerFree(&z);
}

pub export fn opModLonILonIShoI(mode: u16) linksection(runtime.code_section) callconv(.c) void {
    convertShortIntegerRegisterToLongIntegerRegister(REGISTER_X, REGISTER_X);
    opModLonILonILonI(mode);
}

pub export fn opModLonILonIReal(mode: u16) linksection(runtime.code_section) callconv(.c) void {
    var x: mpz_struct = undefined;
    var y: mpz_struct = undefined;
    var z: mpz_struct = undefined;
    var xx: real_t = undefined;
    var exp_x: i32 = 0;
    var exponent: i32 = undefined;

    parseReal(REGISTER_X, &x, &exp_x);
    convertLongIntegerRegisterToLongInteger(REGISTER_Y, &y);
    convertLongIntegerRegisterToLongInteger(REGISTER_Z, &z);
    real34ToReal(registerReal34Data(REGISTER_X), &xx);

    if ((mode == OPMOD_POWER) or (getRegisterAngularMode(REGISTER_X) != amNone)) {
        opModError(mode);
    } else if (math_comparison_reals.realCompareGreaterThan(&xx, const_1()) and longIntegerIsPositive(&y) and longIntegerIsPositive(&z)) {
        longInteger_mulmod(&z, 0, &y, 0, &x, exp_x, &x, &exponent);
        toRealResult(&x, exponent);
    } else {
        opModOutOfDomain(mode);
    }

    longIntegerFree(&x);
    longIntegerFree(&y);
    longIntegerFree(&z);
}

pub export fn opModLonIShoILonI(mode: u16) linksection(runtime.code_section) callconv(.c) void {
    convertShortIntegerRegisterToLongIntegerRegister(REGISTER_Y, REGISTER_Y);
    opModLonILonILonI(mode);
}

pub export fn opModLonIShoIShoI(mode: u16) linksection(runtime.code_section) callconv(.c) void {
    convertShortIntegerRegisterToLongIntegerRegister(REGISTER_X, REGISTER_X);
    convertShortIntegerRegisterToLongIntegerRegister(REGISTER_Y, REGISTER_Y);
    opModLonILonILonI(mode);
}

pub export fn opModLonIShoIReal(mode: u16) linksection(runtime.code_section) callconv(.c) void {
    convertShortIntegerRegisterToLongIntegerRegister(REGISTER_Y, REGISTER_Y);
    opModLonILonIReal(mode);
}

pub export fn opModLonIRealLonI(mode: u16) linksection(runtime.code_section) callconv(.c) void {
    var x: mpz_struct = undefined;
    var y: mpz_struct = undefined;
    var z: mpz_struct = undefined;
    var exp_y: i32 = 0;
    var exponent: i32 = undefined;

    convertLongIntegerRegisterToLongInteger(REGISTER_X, &x);
    parseReal(REGISTER_Y, &y, &exp_y);
    convertLongIntegerRegisterToLongInteger(REGISTER_Z, &z);

    if ((mode == OPMOD_POWER) or (getRegisterAngularMode(REGISTER_Y) != amNone)) {
        opModError(mode);
    } else if ((longIntegerCompareInt(&x, 1) > 0) and longIntegerIsPositive(&y) and longIntegerIsPositive(&z)) {
        longInteger_mulmod(&z, 0, &y, exp_y, &x, 0, &x, &exponent);
        toRealResult(&x, exponent);
    } else {
        opModOutOfDomain(mode);
    }

    longIntegerFree(&x);
    longIntegerFree(&y);
    longIntegerFree(&z);
}

pub export fn opModLonIRealShoI(mode: u16) linksection(runtime.code_section) callconv(.c) void {
    convertShortIntegerRegisterToLongIntegerRegister(REGISTER_X, REGISTER_X);
    opModLonIRealLonI(mode);
}

pub export fn opModLonIRealReal(mode: u16) linksection(runtime.code_section) callconv(.c) void {
    var x: mpz_struct = undefined;
    var y: mpz_struct = undefined;
    var z: mpz_struct = undefined;
    var xx: real_t = undefined;
    var exp_x: i32 = 0;
    var exp_y: i32 = 0;
    var exponent: i32 = undefined;

    parseReal(REGISTER_X, &x, &exp_x);
    parseReal(REGISTER_Y, &y, &exp_y);
    convertLongIntegerRegisterToLongInteger(REGISTER_Z, &z);
    real34ToReal(registerReal34Data(REGISTER_X), &xx);

    if ((mode == OPMOD_POWER) or (getRegisterAngularMode(REGISTER_Y) != amNone) or (getRegisterAngularMode(REGISTER_X) != amNone)) {
        opModError(mode);
    } else if (math_comparison_reals.realCompareGreaterThan(&xx, const_1()) and longIntegerIsPositive(&y) and longIntegerIsPositive(&z)) {
        longInteger_mulmod(&z, 0, &y, exp_y, &x, exp_x, &x, &exponent);
        toRealResult(&x, exponent);
    } else {
        opModOutOfDomain(mode);
    }

    longIntegerFree(&x);
    longIntegerFree(&y);
    longIntegerFree(&z);
}

pub export fn opModShoILonILonI(mode: u16) linksection(runtime.code_section) callconv(.c) void {
    convertShortIntegerRegisterToLongIntegerRegister(REGISTER_Z, REGISTER_Z);
    opModLonILonILonI(mode);
}

pub export fn opModShoILonIShoI(mode: u16) linksection(runtime.code_section) callconv(.c) void {
    const base: u32 = getRegisterShortIntegerBase(REGISTER_Z);
    convertShortIntegerRegisterToLongIntegerRegister(REGISTER_X, REGISTER_X);
    convertShortIntegerRegisterToLongIntegerRegister(REGISTER_Z, REGISTER_Z);
    opModLonILonILonI(mode);
    if (mode == OPMOD_MULTIPLY) {
        convertLongIntegerRegisterToShortIntegerRegister(REGISTER_X, REGISTER_X);
        setRegisterTag(REGISTER_X, base);
    }
}

pub export fn opModShoILonIReal(mode: u16) linksection(runtime.code_section) callconv(.c) void {
    convertShortIntegerRegisterToLongIntegerRegister(REGISTER_Z, REGISTER_Z);
    opModLonILonIReal(mode);
}

pub export fn opModShoIShoILonI(mode: u16) linksection(runtime.code_section) callconv(.c) void {
    convertShortIntegerRegisterToLongIntegerRegister(REGISTER_Y, REGISTER_Y);
    convertShortIntegerRegisterToLongIntegerRegister(REGISTER_Z, REGISTER_Z);
    opModLonILonILonI(mode);
}

pub export fn opModShoIShoIShoI(mode: u16) linksection(runtime.code_section) callconv(.c) void {
    var x: u64 = undefined;
    var y: u64 = undefined;
    var z: u64 = undefined;
    var sx: i16 = undefined;
    var sy: i16 = undefined;
    var sz: i16 = undefined;

    convertShortIntegerRegisterToUInt64(REGISTER_X, &sx, &x);
    convertShortIntegerRegisterToUInt64(REGISTER_Y, &sy, &y);
    convertShortIntegerRegisterToUInt64(REGISTER_Z, &sz, &z);

    if ((sx == 0) and (x > 1) and (sy == 0) and (sz == 0)) {
        if (mode == OPMOD_POWER) {
            x = WP34S_expmod(z, y, x);
        } else {
            x = WP34S_mulmod(z, y, x);
        }
        convertUInt64ToShortIntegerRegister(0, x, getRegisterShortIntegerBase(REGISTER_Z), REGISTER_X);
    } else {
        opModOutOfDomain(mode);
    }
}

pub export fn opModShoIShoIReal(mode: u16) linksection(runtime.code_section) callconv(.c) void {
    convertShortIntegerRegisterToReal34Register(REGISTER_Y, REGISTER_Y);
    convertShortIntegerRegisterToReal34Register(REGISTER_Z, REGISTER_Z);
    opModRealRealReal(mode);
}

pub export fn opModShoIRealLonI(mode: u16) linksection(runtime.code_section) callconv(.c) void {
    convertShortIntegerRegisterToLongIntegerRegister(REGISTER_Z, REGISTER_Z);
    opModLonIRealLonI(mode);
}

pub export fn opModShoIRealShoI(mode: u16) linksection(runtime.code_section) callconv(.c) void {
    convertShortIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
    convertShortIntegerRegisterToReal34Register(REGISTER_Z, REGISTER_Z);
    opModRealRealReal(mode);
}

pub export fn opModShoIRealReal(mode: u16) linksection(runtime.code_section) callconv(.c) void {
    convertShortIntegerRegisterToReal34Register(REGISTER_Z, REGISTER_Z);
    opModRealRealReal(mode);
}

pub export fn opModRealLonILonI(mode: u16) linksection(runtime.code_section) callconv(.c) void {
    var x: mpz_struct = undefined;
    var y: mpz_struct = undefined;
    var z: mpz_struct = undefined;
    var exp_z: i32 = 0;
    var exponent: i32 = undefined;

    convertLongIntegerRegisterToLongInteger(REGISTER_X, &x);
    convertLongIntegerRegisterToLongInteger(REGISTER_Y, &y);
    parseReal(REGISTER_Z, &z, &exp_z);

    if ((mode == OPMOD_POWER) or (getRegisterAngularMode(REGISTER_Z) != amNone)) {
        opModError(mode);
    } else if ((longIntegerCompareInt(&x, 1) > 0) and longIntegerIsPositive(&y) and longIntegerIsPositive(&z)) {
        longInteger_mulmod(&z, exp_z, &y, 0, &x, 0, &x, &exponent);
        toRealResult(&x, exponent);
    } else {
        opModOutOfDomain(mode);
    }

    longIntegerFree(&x);
    longIntegerFree(&y);
    longIntegerFree(&z);
}

pub export fn opModRealLonIShoI(mode: u16) linksection(runtime.code_section) callconv(.c) void {
    convertShortIntegerRegisterToLongIntegerRegister(REGISTER_X, REGISTER_X);
    opModRealLonILonI(mode);
}

pub export fn opModRealLonIReal(mode: u16) linksection(runtime.code_section) callconv(.c) void {
    var x: mpz_struct = undefined;
    var y: mpz_struct = undefined;
    var z: mpz_struct = undefined;
    var xx: real_t = undefined;
    var exp_x: i32 = 0;
    var exp_z: i32 = 0;
    var exponent: i32 = undefined;

    parseReal(REGISTER_X, &x, &exp_x);
    convertLongIntegerRegisterToLongInteger(REGISTER_Y, &y);
    parseReal(REGISTER_Z, &z, &exp_z);
    real34ToReal(registerReal34Data(REGISTER_X), &xx);

    if ((mode == OPMOD_POWER) or (getRegisterAngularMode(REGISTER_Z) != amNone) or (getRegisterAngularMode(REGISTER_X) != amNone)) {
        opModError(mode);
    } else if (math_comparison_reals.realCompareGreaterThan(&xx, const_1()) and longIntegerIsPositive(&y) and longIntegerIsPositive(&z)) {
        longInteger_mulmod(&z, exp_z, &y, 0, &x, exp_x, &x, &exponent);
        toRealResult(&x, exponent);
    } else {
        opModOutOfDomain(mode);
    }

    longIntegerFree(&x);
    longIntegerFree(&y);
    longIntegerFree(&z);
}

pub export fn opModRealShoILonI(mode: u16) linksection(runtime.code_section) callconv(.c) void {
    convertShortIntegerRegisterToLongIntegerRegister(REGISTER_Y, REGISTER_Y);
    opModRealLonILonI(mode);
}

pub export fn opModRealShoIShoI(mode: u16) linksection(runtime.code_section) callconv(.c) void {
    convertShortIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
    convertShortIntegerRegisterToReal34Register(REGISTER_Y, REGISTER_Y);
    opModRealRealReal(mode);
}

pub export fn opModRealShoIReal(mode: u16) linksection(runtime.code_section) callconv(.c) void {
    convertShortIntegerRegisterToReal34Register(REGISTER_Y, REGISTER_Y);
    opModRealRealReal(mode);
}

pub export fn opModRealRealLonI(mode: u16) linksection(runtime.code_section) callconv(.c) void {
    var x: mpz_struct = undefined;
    var y: mpz_struct = undefined;
    var z: mpz_struct = undefined;
    var exp_y: i32 = 0;
    var exp_z: i32 = 0;
    var exponent: i32 = undefined;

    convertLongIntegerRegisterToLongInteger(REGISTER_X, &x);
    parseReal(REGISTER_Y, &y, &exp_y);
    parseReal(REGISTER_Z, &z, &exp_z);

    if ((mode == OPMOD_POWER) or (getRegisterAngularMode(REGISTER_Z) != amNone) or (getRegisterAngularMode(REGISTER_Y) != amNone)) {
        opModError(mode);
    } else if ((longIntegerCompareInt(&x, 1) > 0) and longIntegerIsPositive(&y) and longIntegerIsPositive(&z)) {
        longInteger_mulmod(&z, exp_z, &y, exp_y, &x, 0, &x, &exponent);
        toRealResult(&x, exponent);
    } else {
        opModOutOfDomain(mode);
    }

    longIntegerFree(&x);
    longIntegerFree(&y);
    longIntegerFree(&z);
}

pub export fn opModRealRealShoI(mode: u16) linksection(runtime.code_section) callconv(.c) void {
    convertShortIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
    opModRealRealReal(mode);
}

pub export fn opModRealRealReal(mode: u16) linksection(runtime.code_section) callconv(.c) void {
    var x: real_t = undefined;
    var y: real_t = undefined;
    var z: real_t = undefined;
    real34ToReal(registerReal34Data(REGISTER_X), &x);
    real34ToReal(registerReal34Data(REGISTER_Y), &y);
    real34ToReal(registerReal34Data(REGISTER_Z), &z);
    if ((mode == OPMOD_POWER) or (getRegisterAngularMode(REGISTER_Z) != amNone) or (getRegisterAngularMode(REGISTER_Y) != amNone) or (getRegisterAngularMode(REGISTER_X) != amNone)) {
        opModError(mode);
    } else if (math_comparison_reals.realCompareGreaterThan(&x, const_1()) and math_comparison_reals.realCompareGreaterThan(&y, const_0()) and math_comparison_reals.realCompareGreaterThan(&z, const_0())) {
        realMultiply(&z, &y, &z, &runtime.ctxtReal75);
        WP34S_Mod(&z, &x, &x, &runtime.ctxtReal75);
        convertRealToReal34ResultRegister(&x, REGISTER_X);
    } else {
        opModOutOfDomain(mode);
    }
}

// ---------------------------------------------------------------------------
// Dispatch matrices opModL / opModS / opModR.
// Indexed [getRegisterDataType(REGISTER_X)][getRegisterDataType(REGISTER_Y)].
// NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS == 10.
// ---------------------------------------------------------------------------
const OpModFn = *const fn (u16) callconv(.c) void;
const NDT: usize = 10;

const opModL = [NDT][NDT]OpModFn{
    .{ opModLonILonILonI, opModLonIRealLonI, opModError, opModError, opModError, opModError, opModError, opModError, opModLonIShoILonI, opModError },
    .{ opModLonILonIReal, opModLonIRealReal, opModError, opModError, opModError, opModError, opModError, opModError, opModLonIShoIReal, opModError },
    .{ opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError },
    .{ opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError },
    .{ opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError },
    .{ opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError },
    .{ opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError },
    .{ opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError },
    .{ opModLonILonIShoI, opModLonIRealShoI, opModError, opModError, opModError, opModError, opModError, opModError, opModLonIShoIShoI, opModError },
    .{ opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError },
};

const opModS = [NDT][NDT]OpModFn{
    .{ opModShoILonILonI, opModShoIRealLonI, opModError, opModError, opModError, opModError, opModError, opModError, opModShoIShoILonI, opModError },
    .{ opModShoILonIReal, opModShoIRealReal, opModError, opModError, opModError, opModError, opModError, opModError, opModShoIShoIReal, opModError },
    .{ opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError },
    .{ opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError },
    .{ opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError },
    .{ opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError },
    .{ opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError },
    .{ opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError },
    .{ opModShoILonIShoI, opModShoIRealShoI, opModError, opModError, opModError, opModError, opModError, opModError, opModShoIShoIShoI, opModError },
    .{ opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError },
};

const opModR = [NDT][NDT]OpModFn{
    .{ opModRealLonILonI, opModRealRealLonI, opModError, opModError, opModError, opModError, opModError, opModError, opModRealShoILonI, opModError },
    .{ opModRealLonIReal, opModRealRealReal, opModError, opModError, opModError, opModError, opModError, opModError, opModRealShoIReal, opModError },
    .{ opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError },
    .{ opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError },
    .{ opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError },
    .{ opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError },
    .{ opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError },
    .{ opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError },
    .{ opModRealLonIShoI, opModRealRealShoI, opModError, opModError, opModError, opModError, opModError, opModError, opModRealShoIShoI, opModError },
    .{ opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError, opModError },
};

// ===========================================================================
// fnMulMod / fnExpMod / fnOpMod
// ===========================================================================
pub export fn fnMulMod(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    fnOpMod(OPMOD_MULTIPLY);
}

pub export fn fnExpMod(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    fnOpMod(OPMOD_POWER);
}

pub export fn fnOpMod(mode: u16) linksection(runtime.code_section) callconv(.c) void {
    if (!saveLastX()) {
        return;
    }

    switch (getRegisterDataType(REGISTER_Z)) {
        dtLongInteger => {
            opModL[getRegisterDataType(REGISTER_X)][getRegisterDataType(REGISTER_Y)](mode);
        },
        dtShortInteger => {
            opModS[getRegisterDataType(REGISTER_X)][getRegisterDataType(REGISTER_Y)](mode);
        },
        dtReal34 => {
            opModR[getRegisterDataType(REGISTER_X)][getRegisterDataType(REGISTER_Y)](mode);
        },
        else => {
            opModError(mode);
        },
    }
    adjustResult(REGISTER_X, true, false, REGISTER_X, REGISTER_Y, REGISTER_Z);
    if (lastErrorCode == ERROR_NONE) {
        fnDropY(NOPARAM);
    }
}
