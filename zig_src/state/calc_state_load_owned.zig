const entrypoints_owned = @import("calc_state_entrypoints_owned.zig");
const io_flow_owned = @import("calc_state_io_flow_owned.zig");
const runtime = @import("calc_state_runtime.zig");


pub fn doLoad(load_mode: u16, s: u16, n: u16, d: u16, load_type: u16) void {
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