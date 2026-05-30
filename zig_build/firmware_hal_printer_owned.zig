const FLAG_PRTACT: u16 = 0xc020;

extern fn getSystemFlag(flag: u16) c_int;
extern fn print_byte(byte: u8) void;
extern fn printer_get_delay() u16;
extern fn printer_set_delay(delay: u16) u16;

pub fn getLineDelay() u32 {
    return @divTrunc(printer_get_delay(), 100);
}

pub fn setLineDelay(delay: u16) void {
    _ = printer_set_delay(delay * 100);
}

pub fn sendByteIR(byte: u8) void {
    if (getSystemFlag(FLAG_PRTACT) != 0) {
        print_byte(byte);
    }
}
