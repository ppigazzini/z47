// SPDX-License-Identifier: GPL-3.0-only
//
// longIntegerToAllocatedString: format a GMP long integer as its base-10 string.
// It is pure GMP arithmetic and byte copying with no shell coupling -- the only
// reasons it lived in the shell display owner were the shared errorMessage
// buffer and displayBugScreen, both of which are now core-owned (the buffer) or
// reached through the host boundary (the bug screen). So it belongs in the base
// kernel, where the register codecs that format long integers reach it intra-core.
// The size-check bug path signals the host through abi.host.showBugScreen.

const abi = @import("abi");

const mpz_struct = abi.Mpz;
const longInteger_t = [1]mpz_struct;

extern var errorMessage: [*c]u8;

extern fn __gmpz_init2(op: [*c]mpz_struct, n: c_ulong) void;
extern fn __gmpz_clear(op: [*c]mpz_struct) void;
extern fn __gmpz_add_ui(rop: [*c]mpz_struct, op1: [*c]const mpz_struct, op2: c_ulong) void;
extern fn __gmpz_tdiv_q_ui(q: [*c]mpz_struct, n: [*c]const mpz_struct, d: c_ulong) c_ulong;
extern fn __gmpz_tdiv_ui(n: [*c]const mpz_struct, d: c_ulong) c_ulong;
extern fn __gmpz_sizeinbase(op: [*c]const mpz_struct, base: c_int) usize;
extern fn xcopy(dest: ?*anyopaque, source: ?*const anyopaque, nIn: u32) ?*anyopaque;

pub export fn longIntegerToAllocatedString(lgInt: [*c]const mpz_struct, str: [*c]u8, strLen: i32) callconv(.c) void {
    var numberOfDigits: i32 = undefined;
    var stringLen: i32 = undefined;
    var counter: i32 = undefined;
    var x: longInteger_t = undefined;

    str[0] = '0';
    str[1] = 0;
    if (lgInt[0]._mp_size == 0) {
        return;
    }

    numberOfDigits = @intCast(__gmpz_sizeinbase(lgInt, 10));
    if (lgInt[0]._mp_size < 0) {
        stringLen = numberOfDigits + 2;
        str[0] = '-';
    } else {
        stringLen = numberOfDigits + 1;
    }

    if (strLen < stringLen) {
        abi.fmtBufZ(errorMessage[0..512], "In function longIntegerToAllocatedString: the string str ({d} bytes) is too small to hold the base 10 representation of lgInt, {d} are needed!", .{ strLen, stringLen });
        abi.host.showBugScreen(errorMessage);
        return;
    }

    str[@intCast(stringLen - 1)] = 0;

    __gmpz_init2(&x[0], @intCast(__gmpz_sizeinbase(lgInt, 2)));
    __gmpz_add_ui(&x[0], lgInt, 0);
    x[0]._mp_size = if (x[0]._mp_size < 0) -x[0]._mp_size else x[0]._mp_size;

    stringLen -= 2;
    counter = numberOfDigits;
    while (x[0]._mp_size != 0) {
        str[@intCast(stringLen)] = '0' + @as(u8, @intCast(__gmpz_tdiv_ui(&x[0], 10)));
        stringLen -= 1;
        _ = __gmpz_tdiv_q_ui(&x[0], &x[0], 10);
        counter -= 1;
    }

    if (counter == 1) {
        _ = xcopy(str + @as(usize, @intCast(stringLen)), str + @as(usize, @intCast(stringLen + 1)), @intCast(numberOfDigits));
    }

    __gmpz_clear(&x[0]);
}
