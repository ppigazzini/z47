const io_path_bridge_owned = @import("firmware_hal_io_path_bridge_owned.zig");

pub fn ioFileNameFromFilePath(path: c_int, filename: [*c]u8) c_int {
    return io_path_bridge_owned.ioFileNameFromFilePath(path, filename);
}
