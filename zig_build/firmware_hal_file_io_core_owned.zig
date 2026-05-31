pub const FILE_ERROR: c_int = 0;
pub const FILE_OK: c_int = 1;

pub const FA_READ: u8 = 0x01;
pub const FA_WRITE: u8 = 0x02;
pub const FA_OPEN_EXISTING: u8 = 0x00;
pub const FA_CREATE_ALWAYS: u8 = 0x08;

pub const IO_MODE_READ: c_int = 0;
pub const IO_MODE_WRITE: c_int = 1;
pub const IO_MODE_UPDATE: c_int = 2;

pub extern fn f_open(fp: ?*anyopaque, path: [*c]const u8, mode: u8) c_uint;
pub extern fn f_write(fp: ?*anyopaque, buffer: ?*const anyopaque, size: u32, written: [*c]u32) c_uint;
pub extern fn f_read(fp: ?*anyopaque, buffer: ?*anyopaque, size: u32, read: [*c]u32) c_uint;
pub extern fn f_lseek(fp: ?*anyopaque, pos: u32) c_uint;
pub extern fn f_close(fp: ?*anyopaque) c_uint;
pub extern fn f_eof(fp: ?*anyopaque) c_int;
pub extern fn f_unlink(path: [*c]const u8) c_uint;
pub extern fn sys_disk_write_enable(enabled: c_int) void;
pub extern fn _ioFileNameFromFilePath(path: c_int, filename: [*c]u8) c_int;
pub extern fn stringByteLength(s: [*c]const u8) c_int;
pub extern fn stringCopy(dst: [*c]u8, src: [*c]const u8) void;
pub extern fn max(a: c_int, b: c_int) c_int;

pub extern var stateFileNameVarLength: c_int;
pub extern var ppgm_fp: ?*anyopaque;
pub extern var fileNameSelected: [*c]u8;