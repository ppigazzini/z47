const builtin = @import("builtin");
const runtime = @import("keyboard_state_runtime.zig");
const shared = @import("keyboard_state_shared.zig").implementation(runtime);

const is_dmcp_build = builtin.target.os.tag == .freestanding;

fn processKeyActionHost(item: i16) callconv(.c) void {
    shared.processKeyAction(item);
}

fn keyEnterHost(unused_but_mandatory_parameter: u16) callconv(.c) void {
    shared.keyEnter(unused_but_mandatory_parameter);
}

fn keyExitHost(unused_but_mandatory_parameter: u16) callconv(.c) void {
    shared.keyExit(unused_but_mandatory_parameter);
}

fn keyCCHost(complex_type: u16) callconv(.c) void {
    shared.keyCC(complex_type);
}

fn keyBackspaceHost(unused_but_mandatory_parameter: u16) callconv(.c) void {
    shared.keyBackspace(unused_but_mandatory_parameter);
}

fn keyUpHost(unused_but_mandatory_parameter: u16) callconv(.c) void {
    shared.keyUp(unused_but_mandatory_parameter);
}

fn keyDownHost(unused_but_mandatory_parameter: u16) callconv(.c) void {
    shared.keyDown(unused_but_mandatory_parameter);
}

fn keyDotDHost(unused_but_mandatory_parameter: u16) callconv(.c) void {
    shared.keyDotD(unused_but_mandatory_parameter);
}

fn btnPressedHost(not_used: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) void {
    runtime.btnPressedHostOverlay(not_used, event, data);
}

fn btnClickedHost(not_used: ?*anyopaque, data: ?*anyopaque) callconv(.c) void {
    runtime.btnClickedHostOverlay(not_used, data);
}

fn btnPressedDmcp(data: ?*anyopaque) callconv(.c) void {
    runtime.btnPressedDmcpOverlay(data);
}

fn btnClickedDmcp(unused: ?*anyopaque, data: ?*anyopaque) callconv(.c) void {
    runtime.btnClickedDmcpOverlay(unused, data);
}

comptime {
    if (!is_dmcp_build) {
        @export(&processKeyActionHost, .{ .name = "processKeyAction" });
        @export(&keyEnterHost, .{ .name = "fnKeyEnter" });
        @export(&keyExitHost, .{ .name = "fnKeyExit" });
        @export(&keyCCHost, .{ .name = "fnKeyCC" });
        @export(&keyBackspaceHost, .{ .name = "fnKeyBackspace" });
        @export(&keyUpHost, .{ .name = "fnKeyUp" });
        @export(&keyDownHost, .{ .name = "fnKeyDown" });
        @export(&keyDotDHost, .{ .name = "fnKeyDotD" });
        @export(&btnPressedHost, .{ .name = "btnPressed" });
        @export(&btnClickedHost, .{ .name = "btnClicked" });
    } else {
        @export(&btnPressedDmcp, .{ .name = "btnPressed" });
        @export(&btnClickedDmcp, .{ .name = "btnClicked" });
    }
}

pub export fn caseReplacements(id: u8, lower_case_selected: runtime.bool_t, item: i16, item_out: *i16) runtime.bool_t {
    _ = id;
    return shared.caseReplacements(lower_case_selected, item, item_out);
}

pub export fn keyReplacements(item: i16, item1: *i16, numlock_enabled: runtime.bool_t, f_shift: runtime.bool_t, g_shift: runtime.bool_t) runtime.bool_t {
    return shared.keyReplacements(item, item1, numlock_enabled, f_shift, g_shift);
}

pub export fn numlockReplacements(id: u16, item: i16, numlock_enabled: runtime.bool_t, f_shift: runtime.bool_t, g_shift: runtime.bool_t) u16 {
    _ = id;
    return shared.numlockReplacements(item, numlock_enabled, f_shift, g_shift);
}

pub export fn setLastKeyCode(key: i32) void {
    shared.setLastKeyCode(key);
}

// keyboardTweak.c shift-key item handlers (dispatched via indexOfItems[].func).
pub export fn fnSHIFTf(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.shiftF = true;
    runtime.shiftG = false;
}

pub export fn fnSHIFTg(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.shiftF = false;
    runtime.shiftG = true;
}

pub export fn fnSHIFTfg(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    // f+g chord = the same path as clicking key 27 (the f/g longpress combo).
    const key27: [*:0]const u8 = "27";
    if (is_dmcp_build) {
        runtime.btnClickedDmcpOverlay(null, @ptrCast(@constCast(key27)));
    } else {
        runtime.btnClickedHostOverlay(null, @ptrCast(@constCast(key27)));
    }
}
