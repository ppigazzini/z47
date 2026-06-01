const std = @import("std");
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

fn parseItemFromCString(data: ?*anyopaque) i16 {
    if (data) |ptr| {
        const text: [*:0]const u8 = @ptrCast(ptr);
        return std.fmt.parseInt(i16, std.mem.span(text), 10) catch 0;
    }
    return 0;
}

var retained_dispatch_depth: u8 = 0;

const TO_FG_LONG: u16 = 0;
const TO_CL_LONG: u16 = 1;
const TO_FG_TIMR: u16 = 2;
const TO_FN_LONG: u16 = 3;
const TO_3S_CTFF: u16 = 5;
const TO_AUTO_REPEAT: u16 = 7;

extern fn fnTimerStop(timer_id: u16) void;
extern var shiftF: runtime.bool_t;
extern var shiftG: runtime.bool_t;

fn beginRetainedDispatch() bool {
    if (retained_dispatch_depth != 0) {
        return false;
    }
    retained_dispatch_depth = 1;
    return true;
}

fn endRetainedDispatch() void {
    retained_dispatch_depth = 0;
}

fn dispatchItemBounded(item: i16) void {
    if (!beginRetainedDispatch()) {
        runtime.keyActionProcessed = true;
        return;
    }
    defer endRetainedDispatch();
    runtime.runFunction(item);
    runtime.keyActionProcessed = true;
}

pub export fn z47_keyboard_state_processKeyAction(item: i16) void {
    dispatchItemBounded(item);
}

pub export fn z47_keyboard_state_fnKeyEnter(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    dispatchItemBounded(runtime.ITM_ENTER);
}

pub export fn z47_keyboard_state_fnKeyExit(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    dispatchItemBounded(runtime.ITM_EXIT1_ITEM);
}

pub export fn z47_keyboard_state_fnKeyCC(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    dispatchItemBounded(runtime.ITM_CC);
}

pub export fn z47_keyboard_state_fnKeyBackspace(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    dispatchItemBounded(runtime.ITM_BACKSPACE_ITEM);
}

pub export fn z47_keyboard_state_fnKeyUp(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    dispatchItemBounded(runtime.ITM_UP1_ITEM);
}

pub export fn z47_keyboard_state_fnKeyDown(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    dispatchItemBounded(runtime.ITM_DOWN1_ITEM);
}

pub export fn z47_keyboard_state_fnKeyDotD(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    dispatchItemBounded(runtime.ITM_dotD);
}

pub export fn z47_keyboard_state_btnPressed(not_used: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) void {
    _ = not_used;
    _ = event;
    const item = parseItemFromCString(data);
    if (item != 0) {
        dispatchItemBounded(item);
    }
}

pub export fn z47_keyboard_state_btnClicked(not_used: ?*anyopaque, data: ?*anyopaque) void {
    _ = not_used;
    const item = parseItemFromCString(data);
    if (item != 0) {
        dispatchItemBounded(item);
    }
}

pub export fn processAimInput(item: i16) void {
    dispatchItemBounded(item);
}

pub export fn leavePem() void {}

pub export fn btnFnClicked(not_used: ?*anyopaque, data: [*:0]const u8) void {
    _ = not_used;
    const item = std.fmt.parseInt(i16, std.mem.span(data), 10) catch 0;
    if (item != 0) {
        dispatchItemBounded(item);
    }
}

pub export fn btnFnClickedP(not_used: ?*anyopaque, data: [*:0]const u8) void {
    btnFnClicked(not_used, data);
}

pub export fn btnFnClickedR(not_used: ?*anyopaque, data: [*:0]const u8) void {
    btnFnClicked(not_used, data);
}

pub export fn btnFnPressed(not_used: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) void {
    _ = not_used;
    _ = event;
    _ = data;
}

pub export fn btnFnReleased(not_used: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) void {
    _ = not_used;
    _ = event;
    _ = data;
}

pub export fn btnReleased(not_used: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) void {
    _ = not_used;
    _ = event;
    _ = data;
}

pub export fn showAlphaModeonGui() void {}

pub export fn showShiftState() void {}

pub export fn resetShiftState() void {
    fnTimerStop(TO_FG_LONG);
    fnTimerStop(TO_FG_TIMR);
    fnTimerStop(TO_3S_CTFF);
    fnTimerStop(TO_AUTO_REPEAT);

    shiftF = false;
    shiftG = false;
}

pub export fn resetKeytimers() void {
    resetShiftState();
    fnTimerStop(TO_CL_LONG);
    fnTimerStop(TO_FN_LONG);
}

pub export fn fnSHIFTf(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
}

pub export fn fnSHIFTg(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
}

pub export fn fnSHIFTfg(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
}

pub export fn openHOMEorMyM(situation: runtime.bool_t) void {
    _ = situation;
}

pub export fn Check_Norm_Key_00_Assigned(result: *i16, tempkey: i16) i16 {
    result.* = tempkey;
    return tempkey;
}

pub export fn execFnTimeout(key: u16) void {
    _ = key;
}

pub export fn shiftCutoff(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
}

pub export fn nameFunction(function_id: i16, shift_f: runtime.bool_t, shift_g: runtime.bool_t) i16 {
    _ = shift_f;
    _ = shift_g;
    return function_id;
}

pub export fn fnCla(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
}

pub export fn fnCln(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
}

pub export fn fnT_ARROW(command: u16) void {
    _ = command;
}

pub export fn refreshModeGui() void {}
