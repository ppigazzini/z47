// SPDX-License-Identifier: GPL-3.0-only
//
// Dedicated fake runtime for the statistical-distribution parity harness.
// It provides the register/UI/const surface the ported distribution owners
// bind to (via frontier_distribution_runtime), backed by the REAL decNumber
// library (linked from dep/decNumberICU). This gives true high-precision
// arithmetic so data-dependent branches resolve exactly as in production, and
// the harness can compare a Zig owner's result against independent golden
// values.

const std = @import("std");
const owners = @import("dist_owners");

const DECNUMUNITS = 25;

pub const real_t = extern struct {
    digits: i32,
    exponent: i32,
    bits: u8,
    lsu: [DECNUMUNITS]u16,
};

pub const realContext_t = extern struct {
    digits: i32,
    emax: i32,
    emin: i32,
    round: c_int,
    traps: u32,
    status: u32,
    clamp: u8,
};

const DEC_INIT_BASE: i32 = 0;

extern fn decContextDefault(context: *realContext_t, kind: i32) *realContext_t;
extern fn decNumberMultiply(res: *real_t, a: *const real_t, b: *const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberDivide(res: *real_t, a: *const real_t, b: *const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberAdd(res: *real_t, a: *const real_t, b: *const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberSubtract(res: *real_t, a: *const real_t, b: *const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberMinus(res: *real_t, a: *const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberExp(res: *real_t, a: *const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberLn(res: *real_t, a: *const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberPower(res: *real_t, a: *const real_t, b: *const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberCopy(res: *real_t, a: *const real_t) *real_t;
extern fn decNumberCompare(res: *real_t, a: *const real_t, b: *const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberToIntegralValue(res: *real_t, a: *const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberZero(res: *real_t) *real_t;
extern fn decNumberFromUInt32(res: *real_t, value: u32) *real_t;
extern fn decNumberFromString(res: *real_t, str: [*:0]const u8, ctx: *realContext_t) *real_t;
extern fn decNumberAbs(res: *real_t, a: *const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberToString(a: *const real_t, str: [*]u8) [*]u8;
extern fn decNumberNextToward(res: *real_t, a: *const real_t, toward: *const real_t, ctx: *realContext_t) *real_t;

// ---- Exported product-symbol surface (resolved by the distribution owners) ----

pub export var ctxtReal39: realContext_t = undefined;
pub export var ctxtReal51: realContext_t = undefined;
pub export var ctxtReal75: realContext_t = undefined;

var nan_storage: real_t = undefined;
var inf_storage: real_t = undefined;
var const0_storage: real_t = undefined;
var const1_storage: real_t = undefined;
var const2_storage: real_t = undefined;
var const1on2_storage: real_t = undefined;
var tol_storage: real_t = undefined;
var const_nan_ptr: *const real_t = undefined;
pub export var const_NaN: *const real_t = undefined;

var registers: [256]real_t = undefined;
var last_error: u8 = 0;
var spcres_flag: bool = false;

pub export fn z47_distribution_parity_init() callconv(.c) void {
    _ = decContextDefault(&ctxtReal39, DEC_INIT_BASE);
    ctxtReal39.digits = 39;
    // decNumber transcendental ops (exp/ln/power) require emax/emin within
    // DEC_MAX_MATH (999999); larger limits make them return NaN.
    ctxtReal39.emax = 999999;
    ctxtReal39.emin = -999999;
    ctxtReal39.traps = 0; // c47 runs trap-free; never abort on status flags
    ctxtReal39.status = 0;
    // The wider working contexts the owners pick for cancellation-prone paths,
    // set up the way config.c sets them: the 39-digit limits at more digits.
    ctxtReal51 = ctxtReal39;
    ctxtReal51.digits = 51;
    ctxtReal75 = ctxtReal39;
    ctxtReal75.digits = 75;
    _ = decNumberFromString(&nan_storage, "NaN", &ctxtReal39);
    _ = decNumberFromString(&inf_storage, "Infinity", &ctxtReal39);
    _ = decNumberZero(&const0_storage);
    _ = decNumberFromUInt32(&const1_storage, 1);
    _ = decNumberFromUInt32(&const2_storage, 2);
    _ = decNumberFromString(&const1on2_storage, "0.5", &ctxtReal39);
    _ = decNumberFromString(&tol_storage, "1E-30", &ctxtReal39);
    const_nan_ptr = &nan_storage;
    const_NaN = &nan_storage;
    for (&registers) |*r| _ = decNumberZero(r);
    last_error = 0;
    spcres_flag = false;
}

pub export fn z47_distribution_parity_reset() callconv(.c) void {
    for (&registers) |*r| _ = decNumberZero(r);
    last_error = 0;
}

pub export fn z47_distribution_parity_set_register(reg: i16, str: [*:0]const u8) callconv(.c) void {
    _ = decNumberFromString(&registers[@intCast(reg)], str, &ctxtReal39);
}

pub export fn z47_distribution_parity_get_register(reg: i16, out: *real_t) callconv(.c) void {
    _ = decNumberCopy(out, &registers[@intCast(reg)]);
}

pub export fn z47_distribution_parity_last_error() callconv(.c) u8 {
    return last_error;
}

pub export fn z47_distribution_parity_print(reg: i16) callconv(.c) void {
    var buf: [128]u8 = undefined;
    _ = decNumberToString(&registers[@intCast(reg)], &buf);
    std.debug.print("  REG[{d}] = {s}\n", .{ reg, std.mem.sliceTo(&buf, 0) });
}

// True when register `reg` matches `golden_str` to within 1e-30 relative error
// (absolute error when golden is zero) -- i.e. >= ~30 correct significant digits.
pub export fn z47_distribution_parity_matches(reg: i16, golden_str: [*:0]const u8) callconv(.c) bool {
    const actual = &registers[@intCast(reg)];
    var golden: real_t = undefined;
    _ = decNumberFromString(&golden, golden_str, &ctxtReal39);
    var diff: real_t = undefined;
    _ = decNumberSubtract(&diff, actual, &golden, &ctxtReal39);
    const golden_zero = golden.digits == 1 and golden.lsu[0] == 0 and (golden.bits & 0x70) == 0;
    var metric: real_t = undefined;
    if (golden_zero) {
        _ = decNumberCopy(&metric, &diff);
    } else {
        _ = decNumberDivide(&metric, &diff, &golden, &ctxtReal39);
    }
    metric.bits &= 0x7f; // |metric|: clear the sign bit (non-special values)
    return realCompareLessThan(&metric, &tol_storage);
}

pub export fn z47_distribution_parity_set_spcres(value: bool) callconv(.c) void {
    spcres_flag = value;
}

// frontier_distribution_runtime extern surface:

pub export fn xcopy(dest: ?*anyopaque, source: ?*const anyopaque, n: u32) callconv(.c) ?*anyopaque {
    if (dest) |d| {
        if (source) |s| {
            const db: [*]u8 = @ptrCast(d);
            const sb: [*]const u8 = @ptrCast(s);
            var i: u32 = 0;
            while (i < n) : (i += 1) db[i] = sb[i];
        }
    }
    return dest;
}

pub export fn getRegisterAsReal(reg: i16, value: *real_t) callconv(.c) bool {
    _ = decNumberCopy(value, &registers[@intCast(reg)]);
    return true;
}
pub export fn convertRealToResultRegister(value: *const real_t, dest: i16, angle_mode: c_int) callconv(.c) void {
    _ = angle_mode;
    _ = decNumberCopy(&registers[@intCast(dest)], value);
}
pub export fn saveLastX() callconv(.c) bool {
    return true;
}
pub export fn adjustResult(res: i16, drop_y: bool, set_cpx_res: bool, op1: i16, op2: i16, op3: i16) callconv(.c) void {
    _ = .{ res, drop_y, set_cpx_res, op1, op2, op3 };
}
pub export fn displayDomainErrorMessage(error_code: u8, a: i16) callconv(.c) void {
    _ = a;
    last_error = error_code;
}
pub export fn moreInfoOnError(m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) callconv(.c) void {
    _ = .{ m1, m2, m3, m4 };
}
pub export fn getSystemFlag(flag: i32) callconv(.c) bool {
    _ = flag;
    return spcres_flag;
}

pub export fn realExp(x: *const real_t, res: *real_t, ctx: *realContext_t) callconv(.c) void {
    var tmp: real_t = undefined;
    _ = decNumberExp(&tmp, x, ctx);
    _ = decNumberCopy(res, &tmp);
}
pub export fn realPower(base: *const real_t, exponent: *const real_t, res: *real_t, ctx: *realContext_t) callconv(.c) void {
    var tmp: real_t = undefined;
    _ = decNumberPower(&tmp, base, exponent, ctx);
    _ = decNumberCopy(res, &tmp);
}
// c47 PowerReal(y, x) = y^x; for the finite positive bases the GEV path uses it
// is equivalent to decNumberPower.
pub export fn PowerReal(y: *const real_t, x: *const real_t, res: *real_t, ctx: *realContext_t) callconv(.c) void {
    var tmp: real_t = undefined;
    _ = decNumberPower(&tmp, y, x, ctx);
    _ = decNumberCopy(res, &tmp);
}
pub export fn realSetZero(value: *real_t) callconv(.c) void {
    _ = decNumberZero(value);
}
pub export fn realSetOne(value: *real_t) callconv(.c) void {
    _ = decNumberFromUInt32(value, 1);
}
pub export fn realSetPlusInfinity(value: *real_t) callconv(.c) void {
    _ = decNumberCopy(value, &inf_storage);
}
pub export fn realSetNaN(value: *real_t) callconv(.c) void {
    _ = decNumberCopy(value, &nan_storage);
}
// Compare via subtraction (decNumberSubtract is exercised and safe here);
// decNumberCompare was overrunning the caller frame in this harness link.
inline fn diffIsZero(d: *const real_t) bool {
    return d.digits == 1 and d.lsu[0] == 0 and (d.bits & 0x70) == 0;
}
pub export fn realCompareLessThan(a: *const real_t, b: *const real_t) callconv(.c) bool {
    var d: real_t = undefined;
    _ = decNumberSubtract(&d, a, b, &ctxtReal39);
    return (d.bits & 0x80) != 0 and !diffIsZero(&d); // a - b < 0
}
pub export fn realCompareEqual(a: *const real_t, b: *const real_t) callconv(.c) bool {
    var d: real_t = undefined;
    _ = decNumberSubtract(&d, a, b, &ctxtReal39);
    return diffIsZero(&d);
}
pub export fn realCompareGreaterThan(a: *const real_t, b: *const real_t) callconv(.c) bool {
    var d: real_t = undefined;
    _ = decNumberSubtract(&d, a, b, &ctxtReal39);
    return (d.bits & 0x80) == 0 and !diffIsZero(&d); // a - b > 0
}
// comparisonReals.c builds these from a sign-bit test on decNumberCompare's
// result, so a NaN operand makes GreaterEqual answer TRUE and LessEqual FALSE.
// The owners call the real ones now instead of re-deriving them from LessThan and
// Equal, which got exactly those two cases backwards; the shims mirror the same
// shape over this lane's subtract-based comparison.
pub export fn realCompareGreaterEqual(a: *const real_t, b: *const real_t) callconv(.c) bool {
    var d: real_t = undefined;
    _ = decNumberSubtract(&d, a, b, &ctxtReal39);
    return (d.bits & 0x80) == 0 or diffIsZero(&d);
}
pub export fn realCompareLessEqual(a: *const real_t, b: *const real_t) callconv(.c) bool {
    var d: real_t = undefined;
    _ = decNumberSubtract(&d, a, b, &ctxtReal39);
    return (d.bits & 0x80) != 0 or diffIsZero(&d);
}
pub export fn realIsAnInteger(value: *const real_t) callconv(.c) bool {
    var integral: real_t = undefined;
    _ = decNumberToIntegralValue(&integral, value, &ctxtReal39);
    return realCompareEqual(&integral, value);
}
pub export fn realToIntegralValue(source: *const real_t, destination: *real_t, mode: c_int, ctx: *realContext_t) callconv(.c) void {
    const saved = ctx.round;
    ctx.round = mode;
    _ = decNumberToIntegralValue(destination, source, ctx);
    ctx.round = saved;
}
// Linear interpolation res = a + (b - a) * p. The harness only exercises finite
// inputs, so the NaN/infinity guards of c47's linpol are not needed here.
pub export fn linpol(a: *const real_t, b: *const real_t, p: *const real_t, res: *real_t) callconv(.c) void {
    var diff: real_t = undefined;
    var scaled: real_t = undefined;
    _ = decNumberSubtract(&diff, b, a, &ctxtReal39);
    _ = decNumberMultiply(&scaled, &diff, p, &ctxtReal39);
    _ = decNumberAdd(res, a, &scaled, &ctxtReal39);
}
pub export fn WP34S_ExpM1(x: *const real_t, res: *real_t, ctx: *realContext_t) callconv(.c) void {
    var e: real_t = undefined;
    _ = decNumberExp(&e, x, ctx);
    _ = decNumberSubtract(res, &e, &const1_storage, ctx);
}
pub export fn WP34S_Ln1P(x: *const real_t, res: *real_t, ctx: *realContext_t) callconv(.c) void {
    var s: real_t = undefined;
    _ = decNumberAdd(&s, x, &const1_storage, ctx);
    _ = decNumberLn(res, &s, ctx);
}
pub export fn WP34S_Ln(x: *const real_t, res: *real_t, ctx: *realContext_t) callconv(.c) void {
    _ = decNumberLn(res, x, ctx);
}
pub export fn z47_math_wrappers_const_0() callconv(.c) *const real_t {
    return &const0_storage;
}
pub export fn z47_math_wrappers_const_1() callconv(.c) *const real_t {
    return &const1_storage;
}
pub export fn z47_math_wrappers_const_2() callconv(.c) *const real_t {
    return &const2_storage;
}
pub export fn z47_math_wrappers_const_1on2() callconv(.c) *const real_t {
    return &const1on2_storage;
}

// ---- wp34s.c's distribution surface ----
//
// The entry points the owners reach in wp34s.c, transliterated from it over this
// lane's decNumber-backed registers and comparisons.

const REGISTER_X: i16 = 100;
const REGISTER_Z: i16 = 102;
const REGISTER_R: i16 = 116;
const ERR_REGISTER_LINE: i16 = REGISTER_Z;
const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN: u8 = 1;
const ERROR_INVALID_DISTRIBUTION_PARAM: u8 = 16;
const ERROR_NO_ROOT_FOUND: u8 = 20;
const FLAG_SPCRES: i32 = 0x8017;
const amNone: c_int = 5;

const DECNAN: u8 = 0x20;
const DECSNAN: u8 = 0x10;
const DECSPECIAL: u8 = 0x70;

inline fn isSpecial(value: *const real_t) bool {
    return (value.bits & DECSPECIAL) != 0;
}
inline fn isNaN(value: *const real_t) bool {
    return (value.bits & (DECNAN | DECSNAN)) != 0;
}
inline fn isZero(value: *const real_t) bool {
    return value.lsu[0] == 0 and value.digits == 1 and !isSpecial(value);
}
inline fn getExponent(value: *const real_t) i32 {
    return value.digits + value.exponent - 1;
}

pub const DomainRule = *const fn (registers_valid: bool, x: *real_t, first: ?*real_t, second: ?*real_t, third: ?*real_t, parameter: u16) callconv(.c) bool;

pub export fn WP34S_CheckDistributionParameters(x: *real_t, first_register: i16, first: ?*real_t, second_register: i16, second: ?*real_t, third_register: i16, third: ?*real_t, parameter: u16, domain_rule: DomainRule) callconv(.c) bool {
    if (!saveLastX()) {
        return false;
    }

    const registers_valid = getRegisterAsReal(REGISTER_X, x) and
        (first == null or getRegisterAsReal(first_register, first.?)) and
        (second == null or getRegisterAsReal(second_register, second.?)) and
        (third == null or getRegisterAsReal(third_register, third.?));
    if (!registers_valid) {
        _ = domain_rule(false, x, first, second, third, parameter);
        if (getSystemFlag(FLAG_SPCRES)) {
            convertRealToResultRegister(const_NaN, REGISTER_X, amNone);
        }
        return false;
    }
    if (!domain_rule(true, x, first, second, third, parameter)) {
        if (getSystemFlag(FLAG_SPCRES)) {
            convertRealToResultRegister(const_NaN, REGISTER_X, amNone);
        }
        return false;
    }
    return true;
}

pub export fn WP34S_IsPositiveFinite(value: *const real_t) callconv(.c) bool {
    return !isSpecial(value) and realCompareGreaterThan(value, &const0_storage);
}

pub export fn WP34S_MarkProbability(value: *real_t, ctx: *realContext_t) callconv(.c) void {
    if (isZero(value)) {
        _ = decNumberNextToward(value, value, &const1_storage, ctx);
    } else if (realCompareEqual(value, &const1_storage)) {
        _ = decNumberNextToward(value, value, &const0_storage, ctx);
    }
}

pub export fn WP34S_MarkPositive(value: *real_t, ctx: *realContext_t) callconv(.c) void {
    if (isZero(value)) {
        _ = decNumberNextToward(value, value, &const1_storage, ctx);
    }
}

pub export fn WP34S_HasCancellation(left: *const real_t, right: *const real_t, result: *const real_t, places: i32) callconv(.c) bool {
    if (isZero(left) or isZero(right) or isSpecial(result)) {
        return false;
    }
    if (isZero(result)) {
        return true;
    }
    const input_exponent = @max(getExponent(left), getExponent(right));
    return input_exponent - getExponent(result) > places;
}

// fnDistribution and its descriptor table. Of the four owners this lane drives,
// only exponential dispatches through the table, so the table here holds that one
// row, as wp34s.c writes it, over the owner's own domain rule and kernels. A row
// this lane does not model stops the run rather than answering for it.
const DIST_P: u16 = 0;
const DIST_I: u16 = 3;
const DIST_EXPON: u16 = 0;
const DIST_CTX_39: u8 = 0;
const DIST_CTX_51: u8 = 1;
const DIST_CTX_75: u8 = 2;
const DIST_INV_NAN_ARG: u8 = 0x01;
const DIST_INV_REPORT_FIRST: u8 = 0x02;
const DIST_INV_NOROOT: u8 = 0x04;
const DIST_INV_NOROOT_NAN: u8 = 0x08;
const DIST_ERR_RETURNS: u8 = 0x10;
const DIST_PDF_INTEGER_ONLY: u8 = 0x20;
const DIST_PDF_NAN_IS_ERROR: u8 = 0x40;

const Kernel1 = *const fn (x: *const real_t, a: *const real_t, res: *real_t, ctx: *realContext_t) callconv(.c) void;

const Distribution = struct {
    first_register: i16,
    flags: u8,
    context: [4]u8,
    domain_rule: DomainRule,
    kernel: [4]Kernel1,
};

const exponential = owners.exponential;
const expon_row: Distribution = .{
    .first_register = REGISTER_R,
    .flags = DIST_INV_NOROOT | DIST_INV_NOROOT_NAN | DIST_ERR_RETURNS,
    .context = @splat(DIST_CTX_39),
    .domain_rule = @ptrCast(&exponential.checkDomain),
    .kernel = .{ @ptrCast(&exponential.wp34sPdfExpon), @ptrCast(&exponential.wp34sCdfExpon), @ptrCast(&exponential.wp34sCdfuExpon), @ptrCast(&exponential.wp34sQfExpon) },
};

fn reportArgumentOutsideZeroOne() void {
    displayDomainErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE);
    moreInfoOnError("In function fnDistribution:", "the argument must be 0 < x < 1", null, null);
}

pub export fn fnDistribution(param: u16) callconv(.c) void {
    if (param >> 2 != DIST_EXPON) @panic("fnDistribution: this lane models the exponential row only");
    const d = &expon_row;
    const which = param & 3;
    const flags = d.flags;
    var val: real_t = undefined;
    var first: real_t = undefined;
    var ans: real_t = undefined;

    if (!WP34S_CheckDistributionParameters(&val, d.first_register, &first, 0, null, 0, null, 0, d.domain_rule)) {
        return;
    }

    if (which == DIST_I and (((flags & DIST_INV_NAN_ARG) != 0 and isNaN(&val)) or realCompareLessEqual(&val, &const0_storage) or realCompareGreaterEqual(&val, &const1_storage))) {
        if ((flags & DIST_INV_REPORT_FIRST) != 0) {
            reportArgumentOutsideZeroOne();
            if (getSystemFlag(FLAG_SPCRES)) {
                convertRealToResultRegister(const_NaN, REGISTER_X, amNone);
            }
        } else if (getSystemFlag(FLAG_SPCRES)) {
            convertRealToResultRegister(const_NaN, REGISTER_X, amNone);
        } else {
            reportArgumentOutsideZeroOne();
        }
        return;
    }

    const ctx: *realContext_t = switch (d.context[which]) {
        DIST_CTX_75 => &ctxtReal75,
        DIST_CTX_51 => &ctxtReal51,
        else => &ctxtReal39,
    };
    if (which == DIST_P and (flags & DIST_PDF_INTEGER_ONLY) != 0 and !realIsAnInteger(&val)) {
        realSetZero(&ans);
    } else {
        d.kernel[which](&val, &first, &ans, ctx);
    }

    if (isNaN(&ans) and which == DIST_I and (flags & DIST_INV_NOROOT) != 0) {
        displayDomainErrorMessage(ERROR_NO_ROOT_FOUND, ERR_REGISTER_LINE);
        moreInfoOnError("In function fnDistribution:", "the quantile did not produce a finite result", null, null);
        if ((flags & DIST_INV_NOROOT_NAN) != 0 and getSystemFlag(FLAG_SPCRES)) {
            convertRealToResultRegister(const_NaN, REGISTER_X, amNone);
        }
        if ((flags & DIST_ERR_RETURNS) != 0) {
            return;
        }
    } else if (isNaN(&ans) and which == DIST_P and (flags & DIST_PDF_NAN_IS_ERROR) != 0) {
        displayDomainErrorMessage(ERROR_INVALID_DISTRIBUTION_PARAM, ERR_REGISTER_LINE);
        moreInfoOnError("In function fnDistribution:", "a parameter is invalid", null, null);
    } else {
        convertRealToResultRegister(&ans, REGISTER_X, amNone);
    }
    adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
}
