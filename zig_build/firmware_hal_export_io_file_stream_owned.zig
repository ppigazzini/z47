const file_io_bridge_owned = @import("firmware_hal_file_io_bridge_owned.zig");

pub fn ioFileWrite(buffer: ?*const anyopaque, size: u32) void {
    file_io_bridge_owned.ioFileWrite(buffer, size);
}

pub fn ioFileRead(buffer: ?*anyopaque, size: u32) u32 {
    return file_io_bridge_owned.ioFileRead(buffer, size);
}

pub fn ioEof() c_int {
    return file_io_bridge_owned.ioEof();
}
