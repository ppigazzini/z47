const file_io_open_owned = @import("firmware_hal_file_io_open_owned.zig");

const FILE_ERROR: c_int = 0;
const FILE_OK: c_int = 1;

const FA_READ: u8 = 0x01;
const FA_WRITE: u8 = 0x02;
const FA_OPEN_EXISTING: u8 = 0x00;
const FA_CREATE_ALWAYS: u8 = 0x08;

const IO_MODE_READ: c_int = 0;
const IO_MODE_WRITE: c_int = 1;
const IO_MODE_UPDATE: c_int = 2;

extern fn f_open(fp: ?*anyopaque, path: [*c]const u8, mode: u8) c_uint;
extern fn f_write(fp: ?*anyopaque, buffer: ?*const anyopaque, size: u32, written: [*c]u32) c_uint;
extern fn f_read(fp: ?*anyopaque, buffer: ?*anyopaque, size: u32, read: [*c]u32) c_uint;
extern fn f_lseek(fp: ?*anyopaque, pos: u32) c_uint;
extern fn f_close(fp: ?*anyopaque) c_uint;
extern fn f_eof(fp: ?*anyopaque) c_int;
extern fn f_unlink(path: [*c]const u8) c_uint;
extern fn sys_disk_write_enable(enabled: c_int) void;
extern fn _ioFileNameFromFilePath(path: c_int, filename: [*c]u8) c_int;
extern fn stringByteLength(s: [*c]const u8) c_int;
extern fn stringCopy(dst: [*c]u8, src: [*c]const u8) void;
extern fn max(a: c_int, b: c_int) c_int;
extern var stateFileNameVarLength: c_int;
extern var ppgm_fp: ?*anyopaque;
extern var fileNameSelected: [*c]u8;

pub fn ioFileOpen(path: c_int, mode: c_int, io_write_enabled: *c_int, io_read_enabled: *c_int) c_int {
    return file_io_open_owned.ioFileOpen(path, mode, io_write_enabled, io_read_enabled);
}

pub fn ioFileWrite(buffer: ?*const anyopaque, size: u32) void {
    var bytes_written: u32 = 0;
    _ = f_write(ppgm_fp, buffer, size, &bytes_written);
}

pub fn ioFileRead(buffer: ?*anyopaque, size: u32) u32 {
    var bytes_read: u32 = 0;
    _ = f_read(ppgm_fp, buffer, size, &bytes_read);
    return bytes_read;
}

pub fn ioFileSeek(position: u32) void {
    _ = f_lseek(ppgm_fp, position);
}

pub fn ioFileClose(io_write_enabled: *c_int, io_read_enabled: *c_int) void {
    _ = f_close(ppgm_fp);
    if (io_write_enabled.* != 0) {
        sys_disk_write_enable(0);
    }
    io_write_enabled.* = 0;
    io_read_enabled.* = 0;
}

pub fn ioEof() c_int {
    return f_eof(ppgm_fp);
}

pub fn ioFileRemove(path: c_int, error_number: ?*u32) c_int {
    var filename: [40]u8 = [_]u8{0} ** 40;

    sys_disk_write_enable(1);
    const ret = _ioFileNameFromFilePath(path, &filename);
    if (ret != FILE_OK) {
        sys_disk_write_enable(0);
        return ret;
    }

    const result = f_unlink(&filename);
    if (result != 0 and error_number != null) {
        error_number.?.* = result;
    }
    sys_disk_write_enable(0);
    return if (result == 0) FILE_OK else FILE_ERROR;
}
