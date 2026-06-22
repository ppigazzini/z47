const std = @import("std");
const builtin = @import("builtin");
const load_owned = @import("calc_state_load_owned.zig");
const runtime = @import("calc_state_runtime.zig");
const save_owned = @import("calc_state_save_owned.zig");
const restore_owned = @import("calc_state_restore_owned.zig");

const is_dmcp_build = builtin.target.os.tag == .freestanding;

var compat_saved_calc_model: u16 = 0;
var compat_loaded_version: u32 = 0;

fn parseIntCompat(comptime T: type, str: [*:0]const u8) T {
    return std.fmt.parseInt(T, std.mem.span(str), 10) catch 0;
}

fn saveCalcBackupHost() callconv(.c) void {
    runtime.saveCalcBackup();
}

fn restoreCalcBackupHost() callconv(.c) void {
    runtime.restoreCalcBackup();
}

comptime {
    if (!is_dmcp_build) {
        @export(&saveCalcBackupHost, .{ .name = "saveCalc" });
        @export(&restoreCalcBackupHost, .{ .name = "restoreCalc" });
    }
}

pub export fn doLoad(load_mode: u16, s: u16, n: u16, d: u16, load_type: u16) void {
    load_owned.doLoad(load_mode, s, n, d, load_type);
}

pub export fn fnLoad(load_mode: u16) void {
    load_owned.load(load_mode);
}

pub export fn fnLoadAuto() void {
    load_owned.loadAuto();
}

pub export fn fnSaveAuto(unused_but_mandatory_parameter: u16) void {
    load_owned.saveAuto(unused_but_mandatory_parameter);
}

pub export fn fnSave(save_mode: u16) void {
    load_owned.save(save_mode);
}

pub export fn z47_calc_state_reset_load_context() void {
    compat_saved_calc_model = 0;
    compat_loaded_version = 0;
}

pub export fn z47_calc_state_set_saved_calc_model(saved_calc_model: u16) void {
    compat_saved_calc_model = saved_calc_model;
}

pub export fn z47_calc_state_get_saved_calc_model() u16 {
    return compat_saved_calc_model;
}

pub export fn z47_calc_state_set_loaded_version(version: u32) void {
    compat_loaded_version = version;
}

pub export fn z47_calc_state_get_loaded_version() u32 {
    return compat_loaded_version;
}

pub export fn z47_calc_state_get_version_allowed() u32 {
    return runtime.VERSION_ALLOWED;
}

pub export fn z47_calc_state_get_config_file_version() u32 {
    return runtime.CONFIG_FILE_VERSION;
}

pub export fn z47_calc_state_restore_one_section(load_mode: u16, s: u16, n: u16, d: u16, allow_user_keys: bool) bool {
    // Host-only: DMCP firmware loads via the C retained path, so this symbol is
    // never called there. `comptime` forces the host branch out of firmware.
    return restore_owned.restoreOneSection(load_mode, s, n, d, allow_user_keys);
}

pub export fn z47_calc_state_save_sections() void {
    // Host-only: the DMCP firmware saves via the C retained path
    // (z47_calc_state_legacy_*), so this symbol is never called there. Gating it
    // keeps the Zig section writer out of firmware (byte-identical flash) while
    // still resolving the io_owned extern.
    save_owned.writeSaveSections();
}

pub export fn stringToUint8(str: [*:0]const u8) u8 {
    return parseIntCompat(u8, str);
}

pub export fn stringToUint32(str: [*:0]const u8) u32 {
    return parseIntCompat(u32, str);
}

pub export fn stringToInt16(str: [*:0]const u8) i16 {
    return parseIntCompat(i16, str);
}

pub export fn stringToInt32(str: [*:0]const u8) i32 {
    return parseIntCompat(i32, str);
}

pub export fn toInt32(str: [*:0]const u8) i32 {
    return stringToInt32(str);
}

pub export fn readLine(line: [*c]u8) void {
    const out = line orelse return;
    var idx: usize = 0;

    if (runtime.ioEof() == 0) {
        _ = runtime.ioFileRead(&out[idx], 1);
        while ((out[idx] == '\n' or out[idx] == '\r') and runtime.ioEof() == 0) {
            _ = runtime.ioFileRead(&out[idx], 1);
        }

        while (out[idx] != '\n' and out[idx] != '\r' and runtime.ioEof() == 0) {
            idx += 1;
            _ = runtime.ioFileRead(&out[idx], 1);
        }
    }

    out[idx] = 0;
}

pub export fn fnDeleteBackup(confirmation: u16) void {
    _ = confirmation;
}

pub export fn fnLoadedFile(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
}
