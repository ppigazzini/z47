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

pub export fn caseReplacements(id: u8, lowerCaseSelected: runtime.bool_t, item: i16, itemOut: *i16) runtime.bool_t {
    _ = id;
    return shared.caseReplacements(lowerCaseSelected, item, itemOut);
}

pub export fn keyReplacements(item: i16, replacementItem: *i16, numlockEnabled: runtime.bool_t, fShift: runtime.bool_t, gShift: runtime.bool_t) runtime.bool_t {
    return shared.keyReplacements(item, replacementItem, numlockEnabled, fShift, gShift);
}

pub export fn numlockReplacements(id: u16, item: i16, numlockEnabled: runtime.bool_t, fShift: runtime.bool_t, gShift: runtime.bool_t) u16 {
    _ = id;
    return shared.numlockReplacements(item, numlockEnabled, fShift, gShift);
}

pub export fn setLastKeyCode(key: i32) void {
    shared.setLastKeyCode(key);
}
