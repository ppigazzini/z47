const builtin = @import("builtin");
const runtime = @import("keyboard_state_runtime.zig");
const shared = @import("keyboard_state_shared.zig").implementation(runtime);

const is_dmcp_build = builtin.target.os.tag == .freestanding;

fn processKeyActionHost(item: i16) callconv(.c) void {
    shared.processKeyAction(item);
}

fn fnKeyEnterHost(unused_but_mandatory_parameter: u16) callconv(.c) void {
    shared.fnKeyEnter(unused_but_mandatory_parameter);
}

fn fnKeyExitHost(unused_but_mandatory_parameter: u16) callconv(.c) void {
    shared.fnKeyExit(unused_but_mandatory_parameter);
}

fn fnKeyCCHost(complex_type: u16) callconv(.c) void {
    shared.fnKeyCC(complex_type);
}

fn fnKeyBackspaceHost(unused_but_mandatory_parameter: u16) callconv(.c) void {
    shared.fnKeyBackspace(unused_but_mandatory_parameter);
}

fn fnKeyUpHost(unused_but_mandatory_parameter: u16) callconv(.c) void {
    shared.fnKeyUp(unused_but_mandatory_parameter);
}

fn fnKeyDownHost(unused_but_mandatory_parameter: u16) callconv(.c) void {
    shared.fnKeyDown(unused_but_mandatory_parameter);
}

fn fnKeyDotDHost(unused_but_mandatory_parameter: u16) callconv(.c) void {
    shared.fnKeyDotD(unused_but_mandatory_parameter);
}

comptime {
    if (!is_dmcp_build) {
        @export(&processKeyActionHost, .{ .name = "processKeyAction" });
        @export(&fnKeyEnterHost, .{ .name = "fnKeyEnter" });
        @export(&fnKeyExitHost, .{ .name = "fnKeyExit" });
        @export(&fnKeyCCHost, .{ .name = "fnKeyCC" });
        @export(&fnKeyBackspaceHost, .{ .name = "fnKeyBackspace" });
        @export(&fnKeyUpHost, .{ .name = "fnKeyUp" });
        @export(&fnKeyDownHost, .{ .name = "fnKeyDown" });
        @export(&fnKeyDotDHost, .{ .name = "fnKeyDotD" });
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
