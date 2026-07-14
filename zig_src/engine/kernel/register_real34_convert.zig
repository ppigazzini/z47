// SPDX-License-Identifier: GPL-3.0-only
//
// The real_t -> real34 result-register conversions, lifted out of the shell
// register_value_conversions god-adapter. convertRealToReal34ResultRegister
// rounds a real_t to the working precision and stores it into a register as a
// real34; convertRealToResultRegister reallocates the register first. These are
// pure value-model operations the engine performs on its own registers, with no
// shell coupling -- they were only stranded in the shell adapter by the C-to-Zig
// conversion. Their numeric dependencies (rounding, the decNumber contexts, the
// register reallocation) are all engine-side, so the cluster moves cleanly to
// the base kernel.
//
// The math-command-wrapper parity oracle keeps its own fake-real versions of
// these (it models real_t as int32 and must not run the real decNumber
// conversion); it does not link the kernel, so there is no collision. The real
// implementation is exercised by the full testSuite.

const abi = @import("abi");

const real_t = abi.Real;
const real34_t = abi.Real34;
const realContext_t = abi.RealContext;
const calcRegister_t = i16;
const angularMode_t = c_int;
const dtReal34: u32 = 1;
const REAL34_SIZE_IN_BLOCKS: u16 = 4;
const reg34 = abi.registerReal34;

extern var significantDigits: u8;
extern var ctxtReal34: realContext_t;
extern var ctxtReal75: realContext_t;

extern fn roundToSignificantDigits(source: *const real_t, destination: *real_t, digits: u16, real_context: *realContext_t) void;
extern fn decimal128FromNumber(dst: *real34_t, src: *const real_t, ctx: *realContext_t) *real34_t;
extern fn decNumberToIntegralValue(dst: *real_t, src: *const real_t, ctx: *realContext_t) *real_t;
extern fn reallocateRegister(regist: calcRegister_t, data_type: u32, size_blocks: u16, tag: u32) void;

// realToIntegralValue: round a real_t to an integral value under an explicit
// rounding mode, restoring the context's mode afterwards. A pure decNumber
// operation; it was stranded in the shell adapter. The math/distribution oracles
// keep their fake-real versions (they do not link the kernel); the real one is
// exercised by the testSuite.
pub export fn realToIntegralValue(source: *const real_t, destination: *real_t, mode: c_int, realContext: *realContext_t) callconv(.c) void {
    const savedRoundingMode: c_int = realContext.round;
    realContext.round = mode;
    realContext.status = 0;
    _ = decNumberToIntegralValue(destination, source, realContext);
    realContext.round = savedRoundingMode;
}

inline fn realToReal34(src: *const real_t, dst: *real34_t) void {
    _ = decimal128FromNumber(dst, src, &ctxtReal34);
}

pub export fn convertRealToReal34ResultRegister(real: *const real_t, dest: calcRegister_t) callconv(.c) void {
    var rounded: real_t = undefined;
    roundToSignificantDigits(real, &rounded, if (significantDigits == 0) 34 else significantDigits, &ctxtReal75);
    realToReal34(&rounded, reg34(dest));
}

pub export fn convertRealToResultRegister(x: *const real_t, dest: calcRegister_t, angle: angularMode_t) callconv(.c) void {
    reallocateRegister(dest, dtReal34, REAL34_SIZE_IN_BLOCKS, @bitCast(angle));
    convertRealToReal34ResultRegister(x, dest);
}

// real_t -> integer conversions (from src/c47/realType.c). Pure decNumber /
// coefficient arithmetic with no shell coupling; they call the kernel-local
// realToIntegralValue above.
const DECDPUN = 3;
const DECNEG: u8 = 0x80;
const DECSPECIAL: u8 = 0x70;
const DEC_ROUND_DOWN: c_int = 5; // decContext.h rounding enum order

extern var ctxtReal39: realContext_t;

inline fn realIsSpecial(r: *const real_t) bool {
    return (r.bits & DECSPECIAL) != 0;
}
inline fn realIsNegative(r: *const real_t) bool {
    return (r.bits & DECNEG) != 0;
}

fn realToInt(r: *const real_t, magnitude_limit: u64, round: c_int, err: ?*bool) u64 {
    if (realIsSpecial(r)) {
        return 0;
    }

    var integer: real_t = undefined;
    realToIntegralValue(r, &integer, round, &ctxtReal39);

    var value: u64 = 0;
    var i: i32 = @divTrunc(integer.digits - 1, DECDPUN);
    while (i >= 0) : (i -= 1) {
        value = value * 1000 + integer.lsu[@intCast(i)]; // 1000 = 10^DECDPUN
        if (value > magnitude_limit) {
            return 0;
        }
    }

    var e: i32 = integer.exponent;
    while (e > 0) : (e -= 1) {
        value *= 10;
        if (value > magnitude_limit) {
            return 0;
        }
    }

    if (err) |ep| ep.* = false;
    return value;
}

pub export fn realToInt32C47(r: *const real_t, err: ?*bool) callconv(.c) i32 {
    const sign = realIsNegative(r);
    const magnitude_limit: u64 = @as(u64, 2147483647) + @intFromBool(sign); // INT32_MAX (+1 if negative)
    if (err) |ep| ep.* = true;
    const value: i64 = @intCast(realToInt(r, magnitude_limit, DEC_ROUND_DOWN, err));
    return if (sign) @intCast(-value) else @intCast(value);
}

pub export fn realToUint32C47(r: *const real_t, err: ?*bool) callconv(.c) u32 {
    if (err) |ep| ep.* = true;

    if (realIsNegative(r)) {
        return 0;
    }

    const magnitude_limit: u64 = 4294967295; // UINT32_MAX
    return @intCast(realToInt(r, magnitude_limit, DEC_ROUND_DOWN, err));
}
