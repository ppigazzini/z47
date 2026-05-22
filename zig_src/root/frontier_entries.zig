const runtime = @import("frontier_runtime.zig");

pub export fn fnSNAP(unused_but_mandatory_parameter: u16) callconv(.c) void {
    runtime.z47_frontier_retained_fnSNAP(unused_but_mandatory_parameter);
}