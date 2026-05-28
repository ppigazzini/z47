const builtin = @import("builtin");
const runtime = @import("keyboard_state_runtime.zig");
const shared = @import("keyboard_state_shared.zig").implementation(runtime);

const isDmcpBuild = builtin.target.os.tag == .freestanding;

fn processKeyActionHost(item: i16) callconv(.c) void {
    shared.processKeyAction(item);
}

fn keyEnterHost(unusedButMandatoryParameter: u16) callconv(.c) void {
    shared.keyEnter(unusedButMandatoryParameter);
}

fn keyExitHost(unusedButMandatoryParameter: u16) callconv(.c) void {
    shared.keyExit(unusedButMandatoryParameter);
}

fn keyCCHost(complexType: u16) callconv(.c) void {
    shared.keyCC(complexType);
}

fn keyBackspaceHost(unusedButMandatoryParameter: u16) callconv(.c) void {
    shared.keyBackspace(unusedButMandatoryParameter);
}

fn keyUpHost(unusedButMandatoryParameter: u16) callconv(.c) void {
    shared.keyUp(unusedButMandatoryParameter);
}

fn keyDownHost(unusedButMandatoryParameter: u16) callconv(.c) void {
    shared.keyDown(unusedButMandatoryParameter);
}

fn keyDotDHost(unusedButMandatoryParameter: u16) callconv(.c) void {
    shared.keyDotD(unusedButMandatoryParameter);
}

comptime {
    if (!isDmcpBuild) {
        @export(&processKeyActionHost, .{ .name = "processKeyAction" });
        @export(&keyEnterHost, .{ .name = "fnKeyEnter" });
        @export(&keyExitHost, .{ .name = "fnKeyExit" });
        @export(&keyCCHost, .{ .name = "fnKeyCC" });
        @export(&keyBackspaceHost, .{ .name = "fnKeyBackspace" });
        @export(&keyUpHost, .{ .name = "fnKeyUp" });
        @export(&keyDownHost, .{ .name = "fnKeyDown" });
        @export(&keyDotDHost, .{ .name = "fnKeyDotD" });
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
