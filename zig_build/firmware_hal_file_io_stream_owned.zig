const file_io_core_owned = @import("firmware_hal_file_io_core_owned.zig");

pub fn ioFileWrite(buffer: ?*const anyopaque, size: u32) void {
    var bytes_written: u32 = 0;
    _ = file_io_core_owned.f_write(file_io_core_owned.ppgm_fp, buffer, size, &bytes_written);
}

pub fn ioFileRead(buffer: ?*anyopaque, size: u32) u32 {
    var bytes_read: u32 = 0;
    _ = file_io_core_owned.f_read(file_io_core_owned.ppgm_fp, buffer, size, &bytes_read);
    return bytes_read;
}

pub fn ioEof() c_int {
    return file_io_core_owned.f_eof(file_io_core_owned.ppgm_fp);
}
