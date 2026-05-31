const file_io_core_owned = @import("firmware_hal_file_io_core_owned.zig");
const io_path_owned = @import("firmware_hal_io_path_owned.zig");

const FILE_ERROR: c_int = file_io_core_owned.FILE_ERROR;
const FILE_OK: c_int = file_io_core_owned.FILE_OK;

const FA_READ: u8 = file_io_core_owned.FA_READ;
const FA_WRITE: u8 = file_io_core_owned.FA_WRITE;
const FA_OPEN_EXISTING: u8 = file_io_core_owned.FA_OPEN_EXISTING;
const FA_CREATE_ALWAYS: u8 = file_io_core_owned.FA_CREATE_ALWAYS;

const IO_MODE_READ: c_int = file_io_core_owned.IO_MODE_READ;
const IO_MODE_WRITE: c_int = file_io_core_owned.IO_MODE_WRITE;
const IO_MODE_UPDATE: c_int = file_io_core_owned.IO_MODE_UPDATE;

const OpenModeSpec = struct {
    io_mode: c_int,
    file_mode: u8,
    enable_write: c_int,
    enable_read: c_int,
    requires_disk_write: bool,
};

const open_mode_specs = [_]OpenModeSpec{
    .{
        .io_mode = IO_MODE_READ,
        .file_mode = FA_READ,
        .enable_write = 0,
        .enable_read = 1,
        .requires_disk_write = false,
    },
    .{
        .io_mode = IO_MODE_WRITE,
        .file_mode = FA_CREATE_ALWAYS | FA_WRITE,
        .enable_write = 1,
        .enable_read = 0,
        .requires_disk_write = true,
    },
    .{
        .io_mode = IO_MODE_UPDATE,
        .file_mode = FA_READ | FA_WRITE | FA_OPEN_EXISTING,
        .enable_write = 1,
        .enable_read = 1,
        .requires_disk_write = true,
    },
};

fn findOpenModeSpec(mode: c_int) ?OpenModeSpec {
    inline for (open_mode_specs) |spec| {
        if (spec.io_mode == mode) {
            return spec;
        }
    }
    return null;
}

fn cStringLength(src: [*c]const u8) c_int {
    var idx: c_int = 0;
    while (src[@intCast(idx)] != 0) : (idx += 1) {}
    return idx;
}

fn copyCStringBounded(dst: [*c]u8, src: [*c]const u8, max_len: c_int) void {
    var idx: c_int = 0;
    if (max_len <= 0) return;
    while (src[@intCast(idx)] != 0 and idx < (max_len - 1)) : (idx += 1) {
        dst[@intCast(idx)] = src[@intCast(idx)];
    }
    dst[@intCast(idx)] = 0;
}

fn basenameStartIndex(path: [*c]const u8, name_len: c_int, keep_window: c_int) c_int {
    const min_start = if (name_len - keep_window + 1 > 0) name_len - keep_window + 1 else 0;
    var start = name_len;
    while (start > min_start) {
        const c = path[@intCast(start - 1)];
        if (c == '\\' or c == '/' or c == 0) {
            break;
        }
        start -= 1;
    }
    return start;
}

pub fn ioFileOpen(path: c_int, mode: c_int, io_write_enabled: *c_int, io_read_enabled: *c_int) c_int {
    var filename: [40]u8 = [_]u8{0} ** 40;
    const mode_spec = findOpenModeSpec(mode) orelse return FILE_ERROR;

    file_io_core_owned.fileNameSelected[0] = 0;

    const ret = io_path_owned.ioFileNameFromFilePath(path, &filename);
    if (ret != FILE_OK) return ret;

    io_write_enabled.* = mode_spec.enable_write;
    io_read_enabled.* = mode_spec.enable_read;

    if (mode_spec.requires_disk_write) {
        file_io_core_owned.sys_disk_write_enable(1);
    }

    const result = file_io_core_owned.f_open(file_io_core_owned.ppgm_fp, &filename, mode_spec.file_mode);
    if (result != 0) {
        if (mode_spec.requires_disk_write) {
            file_io_core_owned.sys_disk_write_enable(0);
        }
        io_write_enabled.* = 0;
        io_read_enabled.* = 0;
        return FILE_ERROR;
    }

    if (mode == IO_MODE_READ) {
        const full_len = cStringLength(&filename);
        const name_start = basenameStartIndex(&filename, full_len, file_io_core_owned.stateFileNameVarLength);
        const selected: [*c]const u8 = @ptrCast((&filename)[@intCast(name_start)..].ptr);
        copyCStringBounded(file_io_core_owned.fileNameSelected, selected, file_io_core_owned.stateFileNameVarLength);
    }

    return FILE_OK;
}
