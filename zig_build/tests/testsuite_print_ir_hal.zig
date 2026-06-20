// SPDX-License-Identifier: GPL-3.0-only
//
// Zig replacement for src/testSuite/hal/print_ir — the testSuite's infrared
// printer HAL. The testSuite has no real printer, so the three HAL entry points
// (getLineDelay / setLineDelay / sendByteIR) are inert: getLineDelay reports a
// zero line delay and the writers do nothing. The product sim and firmware
// provide their own real HAL symbols, so this object is linked ONLY into the
// testSuite executables (where print_ir.c used to be compiled), avoiding any
// duplicate-symbol clash.

pub export fn getLineDelay() callconv(.c) u32 {
    return 0;
}

pub export fn setLineDelay(delay: u16) callconv(.c) void {
    _ = delay;
}

pub export fn sendByteIR(byte: u8) callconv(.c) void {
    _ = byte;
}
