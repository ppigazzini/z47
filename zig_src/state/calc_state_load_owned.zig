const builtin = @import("builtin");
const entrypoints_owned = @import("calc_state_entrypoints_owned.zig");
const io_flow_owned = @import("calc_state_io_flow_owned.zig");
const retained_owned = @import("calc_state_retained_owned.zig");

const is_dmcp_build = builtin.target.os.tag == .freestanding;

pub fn doLoad(load_mode: u16, s: u16, n: u16, d: u16, load_type: u16) void {
    if (is_dmcp_build) {
        retained_owned.doLoadRetained(load_mode, s, n, d, load_type);
        return;
    }

    io_flow_owned.doLoad(load_mode, s, n, d, load_type);
}

pub fn load(load_mode: u16) void {
    entrypoints_owned.load(load_mode, doLoad);
}

pub fn loadAuto() void {
    entrypoints_owned.loadAuto(doLoad);
}

pub fn saveAuto(unused_but_mandatory_parameter: u16) void {
    entrypoints_owned.saveAuto(unused_but_mandatory_parameter);
}

pub fn save(save_mode: u16) void {
    entrypoints_owned.save(save_mode);
}