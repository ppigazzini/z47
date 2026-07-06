const firmware_print_ir_build_options = @import("firmware_print_ir_build_options");

const FLAG_PRTACT: u16 = 0xc020;
const print_byte_offset: usize = 300;
const printer_get_delay_offset: usize = 304;
const printer_set_delay_offset: usize = 308;

const PrintByteFn = *const fn (u8) callconv(.c) void;
const PrinterGetDelayFn = *const fn () callconv(.c) u16;
const PrinterSetDelayFn = *const fn (u16) callconv(.c) u16;

extern fn getSystemFlag(flag: u16) c_int;

fn printerGetDelay() u16 {
    const get_delay: PrinterGetDelayFn = @ptrFromInt(firmware_print_ir_build_options.library_fn_base + printer_get_delay_offset);
    return get_delay();
}

fn printerSetDelay(delay: u16) void {
    const set_delay: PrinterSetDelayFn = @ptrFromInt(firmware_print_ir_build_options.library_fn_base + printer_set_delay_offset);
    _ = set_delay(delay);
}

fn printByte(byte: u8) void {
    const print_byte: PrintByteFn = @ptrFromInt(firmware_print_ir_build_options.library_fn_base + print_byte_offset);
    print_byte(byte);
}

pub export fn getLineDelay() callconv(.c) u32 {
    return @divTrunc(printerGetDelay(), 100);
}

pub export fn setLineDelay(delay: u16) callconv(.c) void {
    printerSetDelay(delay * 100);
}

pub export fn sendByteIR(byte: u8) callconv(.c) void {
    if (getSystemFlag(FLAG_PRTACT) != 0) {
        printByte(byte);
    }
}
