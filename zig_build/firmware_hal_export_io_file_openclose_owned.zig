const file_io_bridge_owned = @import("firmware_hal_file_io_bridge_owned.zig");

pub fn ioFileOpen(path: c_int, mode: c_int, io_write_enabled: *c_int, io_read_enabled: *c_int) c_int {
    return file_io_bridge_owned.ioFileOpen(path, mode, io_write_enabled, io_read_enabled);
}

pub fn ioFileClose(io_write_enabled: *c_int, io_read_enabled: *c_int) void {
    file_io_bridge_owned.ioFileClose(io_write_enabled, io_read_enabled);
}
