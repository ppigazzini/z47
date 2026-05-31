const FILE_ERROR: c_int = 0;
const FILE_OK: c_int = 1;

extern fn f_lseek(fp: ?*anyopaque, pos: u32) c_uint;
extern fn f_unlink(path: [*c]const u8) c_uint;
extern fn sys_disk_write_enable(enabled: c_int) void;
extern fn _ioFileNameFromFilePath(path: c_int, filename: [*c]u8) c_int;
extern var ppgm_fp: ?*anyopaque;

pub fn ioFileSeek(position: u32) void {
    _ = f_lseek(ppgm_fp, position);
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
