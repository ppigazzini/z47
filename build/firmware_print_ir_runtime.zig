// SPDX-License-Identifier: GPL-3.0-only
const rom = @import("dmcp_rom");

const FLAG_PRTACT: u16 = 0xc020;

extern fn getSystemFlag(flag: i32) bool;

fn printerGetDelay() u32 {
    return rom.printer_get_delay();
}

fn printerSetDelay(delay: u32) void {
    rom.printer_set_delay(delay);
}

fn printByte(byte: u8) void {
    rom.print_byte(byte);
}

pub export fn getLineDelay() callconv(.c) u32 {
    return @divTrunc(printerGetDelay(), 100);
}

// The delay is in ticks; the ROM takes milliseconds. C promotes the uint16_t
// before multiplying, so a delay above 655 does not wrap.
pub export fn setLineDelay(delay: u16) callconv(.c) void {
    printerSetDelay(@as(u32, delay) * 100);
}

pub export fn sendByteIR(byte: u8) callconv(.c) void {
    if (getSystemFlag(FLAG_PRTACT)) {
        printByte(byte);
    }
}
