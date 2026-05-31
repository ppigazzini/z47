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
extern fn sys_disk_write_enable(enabled: c_int) void;
extern fn _ioFileNameFromFilePath(path: c_int, filename: [*c]u8) c_int;
extern fn stringByteLength(s: [*c]const u8) c_int;
extern fn stringCopy(dst: [*c]u8, src: [*c]const u8) void;
extern fn max(a: c_int, b: c_int) c_int;
extern var stateFileNameVarLength: c_int;
extern var ppgm_fp: ?*anyopaque;
extern var fileNameSelected: [*c]u8;

pub fn ioFileOpen(path: c_int, mode: c_int, io_write_enabled: *c_int, io_read_enabled: *c_int) c_int {
    var filename: [40]u8 = [_]u8{0} ** 40;
    var filemode: u8 = 0;

    fileNameSelected[0] = 0;

    const ret = _ioFileNameFromFilePath(path, &filename);
    if (ret != FILE_OK) return ret;

    switch (mode) {
        IO_MODE_READ => {
            filemode = FA_READ;
            io_read_enabled.* = 1;
        },
        IO_MODE_WRITE => {
            filemode = FA_CREATE_ALWAYS | FA_WRITE;
            io_write_enabled.* = 1;
        },
        IO_MODE_UPDATE => {
            filemode = FA_READ | FA_WRITE | FA_OPEN_EXISTING;
            io_write_enabled.* = 1;
            io_read_enabled.* = 1;
        },
        else => return FILE_ERROR,
    }

    if (mode != IO_MODE_READ) {
        sys_disk_write_enable(1);
    }

    const result = f_open(ppgm_fp, &filename, filemode);
    if (result != 0) {
        if (mode != IO_MODE_READ) {
            sys_disk_write_enable(0);
        }
        io_write_enabled.* = 0;
        io_read_enabled.* = 0;
        return FILE_ERROR;
    }

    if (mode == IO_MODE_READ) {
        var jj: c_int = stringByteLength(&filename);
        const kk: c_int = max(0, jj - stateFileNameVarLength + 1);
        while (jj > kk) {
            const c = filename[@intCast(jj - 1)];
            if (c != '\\' and c != '/' and c != 0) {
                jj -= 1;
            } else {
                break;
            }
        }
        const selected: [*c]const u8 = @ptrCast((&filename)[@intCast(jj)..].ptr);
        stringCopy(fileNameSelected, selected);
    }

    return FILE_OK;
}
