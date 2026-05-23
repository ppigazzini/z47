const std = @import("std");

const FILE_ERROR: c_int = 0;
const FILE_OK: c_int = 1;
const FILE_CANCEL: c_int = 2;

const IO_PATH_MANUAL_SAVE: c_int = 0;
const IO_PATH_AUTO_SAVE: c_int = 1;
const IO_PATH_PGM_FILE: c_int = 2;
const IO_PATH_TEST_PGMS: c_int = 3;
const IO_PATH_BACKUP: c_int = 4;
const IO_PATH_REG_DUMP: c_int = 5;
const IO_PATH_SAVE_STATE_FILE: c_int = 6;
const IO_PATH_LOAD_STATE_FILE: c_int = 7;
const IO_PATH_SAVE_PROGRAM: c_int = 8;
const IO_PATH_EXPORT_RTF_PROGRAM: c_int = 10;
const IO_PATH_LOAD_PROGRAM: c_int = 11;
const IO_PATH_SAVE_ALL_PROGRAMS: c_int = 12;
const IO_PATH_EXPORT_RTF_ALL_PROGRAMS: c_int = 13;

const IO_MODE_READ: c_int = 0;
const IO_MODE_WRITE: c_int = 1;
const IO_MODE_UPDATE: c_int = 2;

var io_file_handle: ?*anyopaque = null;

extern fn mkdir(pathname: [*c]const u8, mode: c_uint) c_int;
extern fn fopen(filename: [*c]const u8, mode: [*c]const u8) ?*anyopaque;
extern fn fwrite(ptr: ?*const anyopaque, size: usize, nitems: usize, stream: ?*anyopaque) usize;
extern fn fread(ptr: ?*anyopaque, size: usize, nitems: usize, stream: ?*anyopaque) usize;
extern fn fseek(stream: ?*anyopaque, offset: c_long, whence: c_int) c_int;
extern fn fclose(stream: ?*anyopaque) c_int;
extern fn feof(stream: ?*anyopaque) c_int;
extern fn remove(pathname: [*c]const u8) c_int;
extern fn strcpy(dest: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strcat(dest: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strlen(s: [*c]const u8) usize;
extern fn snprintf(str: [*c]u8, size: usize, format: [*c]const u8, ...) c_int;

extern var errno: c_int;
extern var fileNameSelected: [*c]u8;

fn createDir(path: [*c]const u8) c_int {
    if (mkdir(path, 0o775) != 0 and errno != 17) {
        return -1;
    }
    return 0;
}

pub export fn file_selection_screen(
    title: [*c]const u8,
    base_dir: [*c]const u8,
    ext: [*c]const u8,
    disp_save: c_int,
    overwrite_check: c_int,
    data: ?*anyopaque,
) callconv(.c) c_int {
    _ = title;
    _ = base_dir;
    _ = ext;
    _ = disp_save;
    _ = overwrite_check;
    _ = data;
    // Deterministic non-interactive fallback for now.
    return FILE_CANCEL;
}

pub export fn _ioFileNameFromFilePath(path: c_int, filename: [*c]u8) callconv(.c) c_int {
    switch (path) {
        IO_PATH_MANUAL_SAVE => {
            if (createDir("./SAVFILES") != 0) return FILE_ERROR;
            _ = strcpy(filename, "SAVFILES/C47.sav");
            return FILE_OK;
        },
        IO_PATH_AUTO_SAVE => {
            if (createDir("./SAVFILES") != 0) return FILE_ERROR;
            _ = strcpy(filename, "SAVFILES/C47auto.sav");
            return FILE_OK;
        },
        IO_PATH_PGM_FILE => {
            if (createDir("./LIBRARY") != 0) return FILE_ERROR;
            _ = strcpy(filename, "LIBRARY/C47.dat");
            return FILE_OK;
        },
        IO_PATH_TEST_PGMS => {
            _ = strcpy(filename, "res/testPgms/testPgms.bin");
            return FILE_OK;
        },
        IO_PATH_BACKUP => {
            _ = strcpy(filename, "backup.cfg");
            return FILE_OK;
        },
        IO_PATH_REG_DUMP => {
            return FILE_OK;
        },
        IO_PATH_SAVE_STATE_FILE => {
            if (createDir("./STATE") != 0) return FILE_ERROR;
            _ = strcpy(filename, "STATE/state.s47");
            return FILE_OK;
        },
        IO_PATH_LOAD_STATE_FILE => {
            _ = strcpy(filename, "STATE/state.s47");
            return FILE_OK;
        },
        IO_PATH_SAVE_PROGRAM => {
            if (createDir("./PROGRAMS") != 0) return FILE_ERROR;
            _ = strcpy(filename, "PROGRAMS/program.p47");
            return FILE_OK;
        },
        IO_PATH_EXPORT_RTF_PROGRAM => {
            if (createDir("./PROGRAMS") != 0) return FILE_ERROR;
            _ = strcpy(filename, "PROGRAMS/program.rtf");
            return FILE_OK;
        },
        IO_PATH_LOAD_PROGRAM => {
            _ = strcpy(filename, "PROGRAMS/program.p47");
            return FILE_OK;
        },
        IO_PATH_SAVE_ALL_PROGRAMS => {
            if (createDir("./PROGRAMS") != 0) return FILE_ERROR;
            if (createDir("./PROGRAMS/ALLPGMS") != 0) return FILE_ERROR;
            _ = strcpy(filename, "PROGRAMS/ALLPGMS/all.p47");
            return FILE_OK;
        },
        IO_PATH_EXPORT_RTF_ALL_PROGRAMS => {
            if (createDir("./PROGRAMS") != 0) return FILE_ERROR;
            if (createDir("./PROGRAMS/ALLPGMS") != 0) return FILE_ERROR;
            _ = strcpy(filename, "PROGRAMS/ALLPGMS/all.rtf");
            return FILE_OK;
        },
        else => return FILE_ERROR,
    }
}

pub export fn ioFileOpen(path: c_int, mode: c_int) callconv(.c) c_int {
    if (io_file_handle != null) return FILE_ERROR;

    var filename: [400]u8 = [_]u8{0} ** 400;
    _ = strcpy(&filename, "untitled");
    fileNameSelected[0] = 0;

    const ret = _ioFileNameFromFilePath(path, &filename);
    if (ret != FILE_OK) return ret;

    const filemode: [*c]const u8 = switch (mode) {
        IO_MODE_READ => "rb",
        IO_MODE_WRITE => "wb",
        IO_MODE_UPDATE => "r+b",
        else => return FILE_ERROR,
    };

    io_file_handle = fopen(&filename, filemode);
    if (io_file_handle != null) {
        if (mode == IO_MODE_READ) {
            // Keep selected filename behavior simple and bounded.
            _ = strcpy(fileNameSelected, &filename);
        }
        return FILE_OK;
    }
    return FILE_ERROR;
}

pub export fn ioFileWrite(buffer: ?*const anyopaque, size: u32) callconv(.c) void {
    if (io_file_handle) |f| {
        _ = fwrite(buffer, 1, size, f);
    }
}

pub export fn ioFileRead(buffer: ?*anyopaque, size: u32) callconv(.c) u32 {
    if (io_file_handle) |f| {
        return @intCast(fread(buffer, 1, size, f));
    }
    return 0;
}

pub export fn ioFileSeek(position: u32) callconv(.c) void {
    if (io_file_handle) |f| {
        _ = fseek(f, @intCast(position), 0);
    }
}

pub export fn ioFileClose() callconv(.c) void {
    if (io_file_handle) |f| {
        _ = fclose(f);
        io_file_handle = null;
    }
}

pub export fn ioEof() callconv(.c) c_int {
    if (io_file_handle) |f| {
        return feof(f);
    }
    return 1;
}

pub export fn ioFileRemove(path: c_int, error_number: ?*u32) callconv(.c) c_int {
    var filename: [400]u8 = [_]u8{0} ** 400;
    const ret = _ioFileNameFromFilePath(path, &filename);
    if (ret != FILE_OK) return ret;

    const result = remove(&filename);
    if (result == -1 and error_number != null) {
        error_number.?.* = @intCast(errno);
    }
    return if (result != -1) FILE_OK else FILE_ERROR;
}

pub export fn show_warning(string: [*c]u8) callconv(.c) void {
    _ = string;
}

pub export fn fnDiskInfo(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
}
