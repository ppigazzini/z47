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
extern fn reallocateRegister(regist: calcRegister_t, data_type: u32, size_blocks: u16, tag: u32) void;

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
