const export_io_file_openclose_owned = @import("firmware_hal_export_io_file_openclose_owned.zig");
const export_io_file_stream_owned = @import("firmware_hal_export_io_file_stream_owned.zig");
const export_io_file_seekremove_owned = @import("firmware_hal_export_io_file_seekremove_owned.zig");

pub fn ioFileOpen(path: c_int, mode: c_int, io_write_enabled: *c_int, io_read_enabled: *c_int) c_int {
    return export_io_file_openclose_owned.ioFileOpen(path, mode, io_write_enabled, io_read_enabled);
}

pub fn ioFileWrite(buffer: ?*const anyopaque, size: u32) void {
    export_io_file_stream_owned.ioFileWrite(buffer, size);
}

pub fn ioFileRead(buffer: ?*anyopaque, size: u32) u32 {
    return export_io_file_stream_owned.ioFileRead(buffer, size);
}

pub fn ioFileSeek(position: u32) void {
    export_io_file_seekremove_owned.ioFileSeek(position);
}

pub fn ioFileClose(io_write_enabled: *c_int, io_read_enabled: *c_int) void {
    export_io_file_openclose_owned.ioFileClose(io_write_enabled, io_read_enabled);
}

pub fn ioEof() c_int {
    return export_io_file_stream_owned.ioEof();
}

pub fn ioFileRemove(path: c_int, error_number: ?*u32) c_int {
    return export_io_file_seekremove_owned.ioFileRemove(path, error_number);
}
