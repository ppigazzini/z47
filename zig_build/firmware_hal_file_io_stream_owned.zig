extern fn f_write(fp: ?*anyopaque, buffer: ?*const anyopaque, size: u32, written: [*c]u32) c_uint;
extern fn f_read(fp: ?*anyopaque, buffer: ?*anyopaque, size: u32, read: [*c]u32) c_uint;
extern fn f_eof(fp: ?*anyopaque) c_int;
extern var ppgm_fp: ?*anyopaque;

pub fn ioFileWrite(buffer: ?*const anyopaque, size: u32) void {
    var bytes_written: u32 = 0;
    _ = f_write(ppgm_fp, buffer, size, &bytes_written);
}

pub fn ioFileRead(buffer: ?*anyopaque, size: u32) u32 {
    var bytes_read: u32 = 0;
    _ = f_read(ppgm_fp, buffer, size, &bytes_read);
    return bytes_read;
}

pub fn ioEof() c_int {
    return f_eof(ppgm_fp);
}
