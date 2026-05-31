const printer_owned = @import("firmware_hal_printer_owned.zig");

pub fn getLineDelay() u32 {
    return printer_owned.getLineDelay();
}

pub fn setLineDelay(delay: u16) void {
    printer_owned.setLineDelay(delay);
}

pub fn sendByteIR(byte: u8) void {
    printer_owned.sendByteIR(byte);
}
