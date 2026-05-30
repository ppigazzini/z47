const std = @import("std");

const FILE_ERROR: c_int = 0;
const FILE_OK: c_int = 1;

const GtkWidget = opaque {};

extern var frmCalc: ?*GtkWidget;
extern fn g_get_current_dir() [*c]u8;
extern fn g_free(mem: ?*anyopaque) void;
extern fn strcpy(dest: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strcat(dest: [*c]u8, src: [*c]const u8) [*c]u8;

pub fn createDir(path: [*c]const u8) c_int {
    const zpath: [*:0]const u8 = @ptrCast(path);
    switch (std.posix.errno(std.posix.system.mkdir(zpath, 0o775))) {
        .SUCCESS, .EXIST => return 0,
        else => return -1,
    }
}

pub fn parentWindow() ?*anyopaque {
    return if (frmCalc) |window| @ptrCast(window) else null;
}

pub fn populateProgramBaseDir(base_dir: [*c]u8, dir_name: [*c]const u8) c_int {
    const current_dir = g_get_current_dir();
    if (current_dir == null) return FILE_ERROR;
    defer g_free(current_dir);

    _ = strcpy(base_dir, current_dir);
    _ = strcat(base_dir, "/");
    _ = strcat(base_dir, dir_name);
    return FILE_OK;
}
