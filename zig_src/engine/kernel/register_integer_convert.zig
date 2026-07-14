// SPDX-License-Identifier: GPL-3.0-only
//
// Register value conversions extracted from the shell register_value_conversions
// god-adapter: reading a register as a real, and converting long/short integer
// registers to/from reals and integers. These are pure value-model operations on
// the calculator's own registers; every dependency is now engine-side (register
// metadata, the decNumber contexts, GMP, the kernel byte copy and error report)
// or reached through the host boundary (the bug screen and the debug type-name
// enrichment), so the whole closure moves to the base kernel. The math and
// distribution parity oracles keep their fake-real versions (they do not link the
// kernel); the real implementations are exercised by the testSuite.

const std = @import("std");
const abi = @import("abi");
const consts = abi.constants;

const calcRegister_t = i16;
const real_t = abi.Real;
const real34_t = abi.Real34;
const realContext_t = abi.RealContext;
const mpz_struct = abi.Mpz;
const mp_limb_t = usize;

const dtLongInteger: u32 = 0;
const dtReal34: u32 = 1;
const dtComplex34: u32 = 2;
const dtTime: u32 = 3;
const dtDate: u32 = 4;
const dtShortInteger: u32 = 8;

const REGISTER_Z: calcRegister_t = 102;
const REGISTER_T: calcRegister_t = 103;
const ERR_REGISTER_LINE: calcRegister_t = REGISTER_Z;
const ERROR_INVALID_DATA_TYPE_FOR_OP: u8 = 24;
const REAL34_SIZE_IN_BYTES: u32 = 16;
const LIMB_SIZE: u32 = @sizeOf(mp_limb_t);
const LI_NEGATIVE: u32 = 1;
const SIM_1COMPL: u8 = 1;
const SIM_2COMPL: u8 = 2;
const SIM_SIGNMT: u8 = 3;
const SIM_UNSIGN: u8 = 0;
const TMP_STR_LENGTH: i32 = 2560;
const const_2p32 = consts.const_2p32;
const reg34 = abi.registerReal34;
const regShortInt = abi.registerShortInteger;

extern var ctxtReal34: realContext_t;
extern var ctxtReal75: realContext_t;
extern var shortIntegerMode: u8;
extern var shortIntegerMask: u64;
extern var shortIntegerSignBit: u64;
extern var errorMessage: [*c]u8;
extern var tmpString: [*c]u8;

extern fn getRegisterDataType(regist: calcRegister_t) u32;
extern fn getRegisterTag(regist: calcRegister_t) u32;
extern fn getRegisterMaxDataLengthInBlocks(regist: calcRegister_t) u16;
extern fn reallocateRegister(regist: calcRegister_t, data_type: u32, size_blocks: u16, tag: u32) void;
extern fn displayCalcErrorMessage(errorCode: u8, errMessageRegisterLine: calcRegister_t, disUsedCanBeRemoved: calcRegister_t) void;
extern fn longIntegerToAllocatedString(lgInt: [*c]const mpz_struct, str: [*c]u8, strLen: i32) void;
extern fn xcopy(dest: ?*anyopaque, source: ?*const anyopaque, nIn: u32) ?*anyopaque;
extern fn decNumberFromString(r: *real_t, s: [*c]const u8, ctx: *realContext_t) *real_t;
extern fn decNumberFromUInt32(r: *real_t, v: u32) *real_t;
extern fn decNumberFMA(r: *real_t, a: *align(1) const real_t, b: *align(1) const real_t, c: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decQuadIsZero(v: *align(1) const real34_t) u32;
extern fn decimal128ToNumber(src: *align(1) const real34_t, dst: *real_t) *real_t;
extern fn __gmpz_init2(p: *mpz_struct, bits: c_ulong) void;
extern fn __gmpz_clear(p: *mpz_struct) void;
const mpz_init2 = __gmpz_init2;
const mpz_clear = __gmpz_clear;

pub export fn badTypeError(reg: calcRegister_t) callconv(.c) void {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_T);
    // the extra_info diagnostic enrichment (register type name) is a shell-side
    // debug concern, routed through the host boundary; a no-op unless installed.
    abi.host.reportBadTypeDetail(reg);
}

pub export fn getRegisterAsReal(reg: calcRegister_t, val: *real_t) callconv(.c) bool {
    const res = getRegisterAsRealQuiet(reg, val);
    if (!res) {
        badTypeError(reg);
    }
    return res;
}

pub export fn getRegisterAsRealQuiet(reg: calcRegister_t, val: *real_t) callconv(.c) bool {
    const t = getRegisterDataType(reg);
    if (t == dtDate or t == dtTime) {
        return false;
    }
    return getRegisterAsAnyRealQuiet(reg, val);
}

pub export fn getRegisterAsAnyRealQuiet(reg: calcRegister_t, val: *real_t) callconv(.c) bool {
    switch (getRegisterDataType(reg)) {
        dtLongInteger => convertLongIntegerRegisterToReal(reg, val, &ctxtReal75),
        dtShortInteger => convertShortIntegerRegisterToReal(reg, val, &ctxtReal34),
        dtDate, dtTime, dtReal34 => real34ToReal(reg34(reg), val),
        dtComplex34 => {
            if (real34IsZero(regImag34(reg))) {
                real34ToReal(reg34(reg), val);
            } else {
                return false;
            }
        },
        else => return false,
    }
    return true;
}

pub export fn convertLongIntegerRegisterToReal(source: calcRegister_t, destination: *real_t, ctxt: *realContext_t) callconv(.c) void {
    var lgInt: mpz_struct = undefined;

    convertLongIntegerRegisterToLongInteger(source, &lgInt);
    convertLongIntegerToReal(&lgInt, destination, ctxt);
    mpz_clear(&lgInt);
}

pub export fn convertLongIntegerToReal(source: *mpz_struct, destination: *real_t, ctxt: *realContext_t) callconv(.c) void {
    longIntegerToAllocatedString(source, tmpString, TMP_STR_LENGTH);
    stringToReal(tmpString, destination, ctxt);
}

pub export fn convertLongIntegerRegisterToLongInteger(regist: calcRegister_t, lgInt: *mpz_struct) callconv(.c) void {
    var sizeInBytes: u32 = toBytes(getRegisterMaxDataLengthInBlocks(regist));

    mpz_init2(lgInt, 8 * @as(c_ulong, @max(sizeInBytes, LIMB_SIZE)));

    _ = xcopy(@ptrCast(lgInt._mp_d), @ptrCast(regLongIntData(regist)), sizeInBytes);

    // Trim trailing zero limbs.
    while (sizeInBytes >= LIMB_SIZE and lgInt._mp_d[sizeInBytes / LIMB_SIZE - 1] == 0) {
        sizeInBytes -= LIMB_SIZE;
    }

    if (sizeInBytes > 0 and getRegisterLongIntegerSign(regist) == LI_NEGATIVE) {
        lgInt._mp_size = -@as(c_int, @intCast(sizeInBytes / LIMB_SIZE));
    } else {
        lgInt._mp_size = @intCast(sizeInBytes / LIMB_SIZE);
    }
}

pub export fn convertShortIntegerRegisterToReal(source: calcRegister_t, destination: *real_t, ctxt: *realContext_t) callconv(.c) void {
    var value: u64 = undefined;
    var sign: i16 = undefined;
    var lowWord: real_t = undefined;

    convertShortIntegerRegisterToUInt64(source, &sign, &value);

    uInt32ToReal(@intCast(value >> 32), destination);
    uInt32ToReal(@intCast(value & 0x00000000ffffffff), &lowWord);
    realFMA(destination, const_2p32(), &lowWord, destination, ctxt);

    if (sign != 0) {
        realSetNegativeSign(destination);
    }
}

pub export fn convertShortIntegerRegisterToUInt64(regist: calcRegister_t, sign: *i16, value: *u64) callconv(.c) void {
    value.* = regShortInt(regist).* & shortIntegerMask;

    if (shortIntegerMode == SIM_UNSIGN) {
        sign.* = 0;
    } else {
        if ((value.* & shortIntegerSignBit) != 0) { // Negative value
            sign.* = 1;

            if (shortIntegerMode == SIM_2COMPL) {
                value.* = ((~value.*) +% 1) & shortIntegerMask;
            } else if (shortIntegerMode == SIM_1COMPL) {
                value.* = (~value.*) & shortIntegerMask;
            } else if (shortIntegerMode == SIM_SIGNMT) {
                value.* -%= shortIntegerSignBit;
            } else {
                abi.host.showBugScreen("convertShortIntegerRegisterToUInt64: bad shortIntegerMode");
                sign.* = 0;
                value.* = 0;
            }
        } else { // Positive value
            sign.* = 0;
        }
    }
}

inline fn real34ToReal(src: *align(1) const real34_t, dst: *real_t) void {
    _ = decimal128ToNumber(src, dst);
}

inline fn real34IsZero(v: *align(1) const real34_t) bool {
    return decQuadIsZero(v) != 0;
}

inline fn regImag34(reg: calcRegister_t) *align(1) real34_t {
    return @ptrCast(dataPtr(reg) + REAL34_SIZE_IN_BYTES);
}

inline fn dataPtr(reg: calcRegister_t) [*]u8 {
    return abi.registerBytes(reg);
}

inline fn regLongIntData(reg: calcRegister_t) [*]u8 {
    return dataPtr(reg) + 4; // sizeof(strLgIntHeader_t)
}

inline fn getRegisterLongIntegerSign(reg: calcRegister_t) u32 {
    return getRegisterTag(reg);
}

inline fn toBytes(n: u16) u32 {
    return @as(u32, n) << 2;
}

inline fn uInt32ToReal(src: u32, dst: *real_t) void {
    _ = decNumberFromUInt32(dst, src);
}

inline fn realFMA(f1: *align(1) const real_t, f2: *align(1) const real_t, term: *align(1) const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberFMA(res, f1, f2, term, ctx);
}

inline fn realSetNegativeSign(v: *real_t) void {
    v.bits |= 0x80;
}

inline fn stringToReal(src: [*c]const u8, dst: *real_t, ctx: *realContext_t) void {
    _ = decNumberFromString(dst, src, ctx);
}
