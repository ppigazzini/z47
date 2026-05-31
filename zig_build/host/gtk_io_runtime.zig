const gtk_io_owned = @import("gtk_io_owned.zig");

const STATE_FILE_NAME_VAR_LENGTH: usize = 20;

var io_file_handle: ?*anyopaque = null;

extern var fileNameSelected: [STATE_FILE_NAME_VAR_LENGTH]u8;

pub export fn file_selection_screen(
    title: [*c]const u8,
    base_dir: [*c]const u8,
    ext: [*c]const u8,
    disp_save: c_int,
    overwrite_check: c_int,
    data: ?*anyopaque,
) callconv(.c) c_int {
    return gtk_io_owned.fileSelectionScreen(title, base_dir, ext, disp_save, overwrite_check, data);
}

pub export fn _ioFileNameFromFilePath(path: c_int, filename: [*c]u8) callconv(.c) c_int {
    return gtk_io_owned.ioFileNameFromFilePath(path, filename);
}

pub export fn ioFileOpen(path: c_int, mode: c_int) callconv(.c) c_int {
    return gtk_io_owned.ioFileOpen(&io_file_handle, path, mode);
}

pub export fn ioFileWrite(buffer: ?*const anyopaque, size: u32) callconv(.c) void {
    gtk_io_owned.ioFileWrite(io_file_handle, buffer, size);
}

pub export fn ioFileRead(buffer: ?*anyopaque, size: u32) callconv(.c) u32 {
    return gtk_io_owned.ioFileRead(io_file_handle, buffer, size);
}

pub export fn ioFileSeek(position: u32) callconv(.c) void {
    gtk_io_owned.ioFileSeek(io_file_handle, position);
}

pub export fn ioFileClose() callconv(.c) void {
    gtk_io_owned.ioFileClose(&io_file_handle);
}

pub export fn ioEof() callconv(.c) c_int {
    return gtk_io_owned.ioEof(io_file_handle);
}

pub export fn ioFileRemove(path: c_int, error_number: ?*u32) callconv(.c) c_int {
    return gtk_io_owned.ioFileRemove(path, error_number);
}

pub export fn show_warning(string: [*c]u8) callconv(.c) void {
    gtk_io_owned.showWarning(string);
}

pub export fn fnDiskInfo(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
}
