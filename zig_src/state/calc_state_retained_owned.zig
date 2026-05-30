const runtime = @import("calc_state_runtime.zig");

pub fn doLoadRetained(load_mode: u16, s: u16, n: u16, d: u16, load_type: u16) void {
    runtime.doLoadRetained(load_mode, s, n, d, load_type);
}