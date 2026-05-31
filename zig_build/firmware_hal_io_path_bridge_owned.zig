const io_path_owned = @import("firmware_hal_io_path_owned.zig");

pub fn ioFileNameFromFilePath(path: c_int, filename: [*c]u8) c_int {
    return io_path_owned.ioFileNameFromFilePath(path, filename);
}
