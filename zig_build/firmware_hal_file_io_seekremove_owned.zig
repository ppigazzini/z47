const file_io_core_owned = @import("firmware_hal_file_io_core_owned.zig");
const io_path_owned = @import("firmware_hal_io_path_owned.zig");

const FILE_ERROR: c_int = file_io_core_owned.FILE_ERROR;
const FILE_OK: c_int = file_io_core_owned.FILE_OK;

const RemoveTarget = struct {
    filename: [40]u8,
};

const RemoveOutcome = struct {
    status: c_int,
    error_code: u32,
};

fn resolveRemoveTarget(path: c_int) struct { ret: c_int, target: RemoveTarget } {
    var target = RemoveTarget{ .filename = [_]u8{0} ** 40 };
    const ret = io_path_owned.ioFileNameFromFilePath(path, &target.filename);
    return .{ .ret = ret, .target = target };
}

fn executeRemove(target: *const RemoveTarget) RemoveOutcome {
    file_io_core_owned.sys_disk_write_enable(1);
    defer file_io_core_owned.sys_disk_write_enable(0);

    const result = file_io_core_owned.f_unlink(&target.filename);
    if (result == 0) {
        return .{ .status = FILE_OK, .error_code = 0 };
    }
    return .{ .status = FILE_ERROR, .error_code = result };
}

pub fn ioFileSeek(position: u32) void {
    _ = file_io_core_owned.f_lseek(file_io_core_owned.ppgm_fp, position);
}

pub fn ioFileRemove(path: c_int, error_number: ?*u32) c_int {
    const resolved = resolveRemoveTarget(path);
    const ret = resolved.ret;
    if (ret != FILE_OK) {
        return ret;
    }

    const outcome = executeRemove(&resolved.target);
    if (outcome.status != FILE_OK and error_number != null) {
        error_number.?.* = outcome.error_code;
    }
    return outcome.status;
}
