const file_io_core_owned = @import("firmware_hal_file_io_core_owned.zig");
const io_path_owned = @import("firmware_hal_io_path_owned.zig");

const FILE_ERROR: c_int = file_io_core_owned.FILE_ERROR;
const FILE_OK: c_int = file_io_core_owned.FILE_OK;

pub fn ioFileSeek(position: u32) void {
    _ = file_io_core_owned.f_lseek(file_io_core_owned.ppgm_fp, position);
}

pub fn ioFileRemove(path: c_int, error_number: ?*u32) c_int {
    var filename: [40]u8 = [_]u8{0} ** 40;

    file_io_core_owned.sys_disk_write_enable(1);
    const ret = io_path_owned.ioFileNameFromFilePath(path, &filename);
    if (ret != FILE_OK) {
        file_io_core_owned.sys_disk_write_enable(0);
        return ret;
    }

    const result = file_io_core_owned.f_unlink(&filename);
    if (result != 0 and error_number != null) {
        error_number.?.* = result;
    }
    file_io_core_owned.sys_disk_write_enable(0);
    return if (result == 0) FILE_OK else FILE_ERROR;
}
