const file_io_core_owned = @import("firmware_hal_file_io_core_owned.zig");

const FILE_ERROR: c_int = file_io_core_owned.FILE_ERROR;
const FILE_OK: c_int = file_io_core_owned.FILE_OK;

const FA_READ: u8 = file_io_core_owned.FA_READ;
const FA_WRITE: u8 = file_io_core_owned.FA_WRITE;
const FA_OPEN_EXISTING: u8 = file_io_core_owned.FA_OPEN_EXISTING;
const FA_CREATE_ALWAYS: u8 = file_io_core_owned.FA_CREATE_ALWAYS;

const IO_MODE_READ: c_int = file_io_core_owned.IO_MODE_READ;
const IO_MODE_WRITE: c_int = file_io_core_owned.IO_MODE_WRITE;
const IO_MODE_UPDATE: c_int = file_io_core_owned.IO_MODE_UPDATE;

pub fn ioFileOpen(path: c_int, mode: c_int, io_write_enabled: *c_int, io_read_enabled: *c_int) c_int {
    var filename: [40]u8 = [_]u8{0} ** 40;
    var filemode: u8 = 0;

    file_io_core_owned.fileNameSelected[0] = 0;

    const ret = file_io_core_owned._ioFileNameFromFilePath(path, &filename);
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
        file_io_core_owned.sys_disk_write_enable(1);
    }

    const result = file_io_core_owned.f_open(file_io_core_owned.ppgm_fp, &filename, filemode);
    if (result != 0) {
        if (mode != IO_MODE_READ) {
            file_io_core_owned.sys_disk_write_enable(0);
        }
        io_write_enabled.* = 0;
        io_read_enabled.* = 0;
        return FILE_ERROR;
    }

    if (mode == IO_MODE_READ) {
        var jj: c_int = file_io_core_owned.stringByteLength(&filename);
        const kk: c_int = file_io_core_owned.max(0, jj - file_io_core_owned.stateFileNameVarLength + 1);
        while (jj > kk) {
            const c = filename[@intCast(jj - 1)];
            if (c != '\\' and c != '/' and c != 0) {
                jj -= 1;
            } else {
                break;
            }
        }
        const selected: [*c]const u8 = @ptrCast((&filename)[@intCast(jj)..].ptr);
        file_io_core_owned.stringCopy(file_io_core_owned.fileNameSelected, selected);
    }

    return FILE_OK;
}
