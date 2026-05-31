const file_io_bridge_owned = @import("firmware_hal_file_io_bridge_owned.zig");

pub fn ioFileSeek(position: u32) void {
    file_io_bridge_owned.ioFileSeek(position);
}

pub fn ioFileRemove(path: c_int, error_number: ?*u32) c_int {
    return file_io_bridge_owned.ioFileRemove(path, error_number);
}
