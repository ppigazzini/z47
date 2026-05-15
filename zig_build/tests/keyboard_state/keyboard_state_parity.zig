const runtime = @import("keyboard_state_parity_runtime.zig");
const shared = @import("z47_keyboard_state_shared").implementation(runtime);

pub export fn processKeyAction(item: i16) void {
    shared.processKeyAction(item);
}

pub export fn fnKeyEnter(unused_but_mandatory_parameter: u16) void {
    shared.fnKeyEnter(unused_but_mandatory_parameter);
}

pub export fn fnKeyExit(unused_but_mandatory_parameter: u16) void {
    shared.fnKeyExit(unused_but_mandatory_parameter);
}

pub export fn fnKeyCC(complex_type: u16) void {
    shared.fnKeyCC(complex_type);
}

pub export fn fnKeyBackspace(unused_but_mandatory_parameter: u16) void {
    shared.fnKeyBackspace(unused_but_mandatory_parameter);
}

pub export fn fnKeyUp(unused_but_mandatory_parameter: u16) void {
    shared.fnKeyUp(unused_but_mandatory_parameter);
}

pub export fn fnKeyDown(unused_but_mandatory_parameter: u16) void {
    shared.fnKeyDown(unused_but_mandatory_parameter);
}

pub export fn fnKeyDotD(unused_but_mandatory_parameter: u16) void {
    shared.fnKeyDotD(unused_but_mandatory_parameter);
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
