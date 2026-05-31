const file_io_core_owned = @import("firmware_hal_file_io_core_owned.zig");

pub fn ioFileClose(io_write_enabled: *c_int, io_read_enabled: *c_int) void {
    _ = file_io_core_owned.f_close(file_io_core_owned.ppgm_fp);
    if (io_write_enabled.* != 0) {
        file_io_core_owned.sys_disk_write_enable(0);
    }
    io_write_enabled.* = 0;
    io_read_enabled.* = 0;
}
