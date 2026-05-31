const printer_bridge_owned = @import("firmware_hal_printer_bridge_owned.zig");

pub fn getLineDelay() u32 {
    return printer_bridge_owned.getLineDelay();
}

pub fn setLineDelay(delay: u16) void {
    printer_bridge_owned.setLineDelay(delay);
}

pub fn sendByteIR(byte: u8) void {
    printer_bridge_owned.sendByteIR(byte);
}
