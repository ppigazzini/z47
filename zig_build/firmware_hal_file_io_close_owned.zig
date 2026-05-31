extern fn f_close(fp: ?*anyopaque) c_uint;
extern fn sys_disk_write_enable(enabled: c_int) void;
extern var ppgm_fp: ?*anyopaque;

pub fn ioFileClose(io_write_enabled: *c_int, io_read_enabled: *c_int) void {
    _ = f_close(ppgm_fp);
    if (io_write_enabled.* != 0) {
        sys_disk_write_enable(0);
    }
    io_write_enabled.* = 0;
    io_read_enabled.* = 0;
}
