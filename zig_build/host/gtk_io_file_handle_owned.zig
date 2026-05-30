const std = @import("std");
const path_policy_owned = @import("gtk_io_path_policy_owned.zig");

const FILE_ERROR: c_int = 0;
const FILE_OK: c_int = 1;

const IO_MODE_READ: c_int = 0;
const IO_MODE_WRITE: c_int = 1;
const IO_MODE_UPDATE: c_int = 2;

extern fn fopen(filename: [*c]const u8, mode: [*c]const u8) ?*anyopaque;
extern fn fwrite(ptr: ?*const anyopaque, size: usize, nitems: usize, stream: ?*anyopaque) usize;
extern fn fread(ptr: ?*anyopaque, size: usize, nitems: usize, stream: ?*anyopaque) usize;
extern fn fseek(stream: ?*anyopaque, offset: c_long, whence: c_int) c_int;
extern fn fclose(stream: ?*anyopaque) c_int;
extern fn feof(stream: ?*anyopaque) c_int;
extern fn remove(pathname: [*c]const u8) c_int;
extern fn strcpy(dest: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn _ioFileNameFromFilePath(path: c_int, filename: [*c]u8) c_int;

pub fn ioFileOpen(handle: *?*anyopaque, path: c_int, mode: c_int, file_name_selected: [*c]u8) c_int {
    if (handle.* != null) return FILE_ERROR;

    var filename: [400]u8 = [_]u8{0} ** 400;
    _ = strcpy(&filename, "untitled");
    file_name_selected[0] = 0;

    const ret = _ioFileNameFromFilePath(path, &filename);
    if (ret != FILE_OK) return ret;

    const filemode: [*c]const u8 = switch (mode) {
        IO_MODE_READ => "rb",
        IO_MODE_WRITE => "wb",
        IO_MODE_UPDATE => "r+b",
        else => return FILE_ERROR,
    };

    handle.* = fopen(&filename, filemode);
    if (handle.* != null) {
        if (mode == IO_MODE_READ) {
            _ = strcpy(file_name_selected, path_policy_owned.selectedFileNameSource(&filename));
        }
        return FILE_OK;
    }
    return FILE_ERROR;
}

pub fn ioFileWrite(handle: ?*anyopaque, buffer: ?*const anyopaque, size: u32) void {
    if (handle) |f| {
        _ = fwrite(buffer, 1, size, f);
    }
}

pub fn ioFileRead(handle: ?*anyopaque, buffer: ?*anyopaque, size: u32) u32 {
    if (handle) |f| {
        return @intCast(fread(buffer, 1, size, f));
    }
    return 0;
}

pub fn ioFileSeek(handle: ?*anyopaque, position: u32) void {
    if (handle) |f| {
        _ = fseek(f, @intCast(position), 0);
    }
}

pub fn ioFileClose(handle: *?*anyopaque) void {
    if (handle.*) |f| {
        _ = fclose(f);
        handle.* = null;
    }
}

pub fn ioEof(handle: ?*anyopaque) c_int {
    if (handle) |f| {
        return feof(f);
    }
    return 1;
}

pub fn ioFileRemove(path: c_int, error_number: ?*u32) c_int {
    var filename: [400]u8 = [_]u8{0} ** 400;
    const ret = _ioFileNameFromFilePath(path, &filename);
    if (ret != FILE_OK) return ret;

    const result = remove(&filename);
    if (result == -1 and error_number != null) {
        error_number.?.* = @intCast(std.c._errno().*);
    }
    return if (result != -1) FILE_OK else FILE_ERROR;
}
