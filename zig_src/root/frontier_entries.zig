const runtime = @import("frontier_runtime.zig");

pub export fn fnSNAP(unused_but_mandatory_parameter: u16) callconv(.c) void {
    runtime.z47_frontier_retained_fnSNAP(unused_but_mandatory_parameter);
}

pub export fn fnDisplayFormatFix(display_format_n: u16) callconv(.c) void {
    runtime.z47_frontier_retained_fnDisplayFormatFix(display_format_n);
}

pub export fn fnDynamicMenu(unused_but_mandatory_parameter: u16) callconv(.c) void {
    runtime.z47_frontier_retained_fnDynamicMenu(unused_but_mandatory_parameter);
}

pub export fn fnNop(unused_but_mandatory_parameter: u16) callconv(.c) void {
    runtime.z47_frontier_retained_fnNop(unused_but_mandatory_parameter);
}