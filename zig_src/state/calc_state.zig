const builtin = @import("builtin");
const load_owned = @import("calc_state_load_owned.zig");
const runtime = @import("calc_state_runtime.zig");

const is_dmcp_build = builtin.target.os.tag == .freestanding;

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
