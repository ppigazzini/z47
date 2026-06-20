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

// keyboardTweak.c fnCla: clear the whole AIM/EIM entry buffer.
pub export fn fnCla(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    if (runtime.calcMode == runtime.CM_AIM) {
        // Not using calcModeAim because some modes are reset which should not be.
        runtime.aimBuffer[0] = 0;
        runtime.T_cursorPos = 0;
        runtime.nextChar = runtime.scrLock;
        runtime.xCursor = 1;
        runtime.yCursor = runtime.Y_POSITION_OF_AIM_LINE + 6;
        runtime.cursorFont = runtime.standardFont;
        runtime.cursorEnabled = true;
        runtime.clearRegisterLine(runtime.AIM_REGISTER_LINE, true, true);
        runtime.refreshRegisterLine(runtime.AIM_REGISTER_LINE); // force the 5/2 line check
        runtime.screenUpdatingMode &= ~runtime.SCRUPD_MANUAL_STACK;
    } else if (runtime.calcMode == runtime.CM_EIM) {
        runtime.fnEqCla();
        runtime.refreshRegisterLine(runtime.NIM_REGISTER_LINE);
        runtime.screenUpdatingMode &= ~runtime.SCRUPD_MANUAL_STACK;
    }
}

// keyboardTweak.c fnT_ARROW: move the multiline-edit cursor (TEXT_MULTILINE_EDIT).
pub export fn fnT_ARROW(command: u16) callconv(.c) void {
    const showUpTo = struct {
        // showStringEdC47(multiEdLines, offset, cursor, buf, 1, -100, vmNormal, 1,1,1)
        fn call() void {
            _ = runtime.showStringEdC47(runtime.multiEdLines, runtime.displayAIMbufferoffset, runtime.T_cursorPos, runtime.aimBuffer, 1, @bitCast(@as(i32, -100)), runtime.vmNormal, true, true, true);
        }
    };

    switch (@as(i32, command)) {
        runtime.ITM_T_LEFT_ARROW => {
            runtime.T_cursorPos = runtime.stringPrevGlyph(runtime.aimBuffer, runtime.T_cursorPos);
            if (runtime.T_cursorPos < runtime.displayAIMbufferoffset and runtime.displayAIMbufferoffset > 0) {
                runtime.displayAIMbufferoffset = runtime.stringPrevGlyph(runtime.aimBuffer, runtime.displayAIMbufferoffset);
            }
        },
        runtime.ITM_T_RIGHT_ARROW => {
            runtime.T_cursorPos = runtime.stringNextGlyph(runtime.aimBuffer, runtime.T_cursorPos);
            runtime.incOffset();
        },
        runtime.ITM_T_LLEFT_ARROW => {
            var ixx: u16 = 0;
            while (ixx < 10) : (ixx += 1) {
                fnT_ARROW(runtime.ITM_T_LEFT_ARROW);
            }
        },
        runtime.ITM_T_RRIGHT_ARROW => {
            var ixx: u16 = 0;
            while (ixx < 10) : (ixx += 1) {
                fnT_ARROW(runtime.ITM_T_RIGHT_ARROW);
            }
        },
        runtime.ITM_T_UP_ARROW => {
            var ixx: u16 = 0;
            const x_old = runtime.current_cursor_x;
            const y_old = runtime.current_cursor_y;
            fnT_ARROW(runtime.ITM_T_RIGHT_ARROW);
            while (ixx < 75 and (@as(u32, runtime.current_cursor_x) >= @as(u32, x_old) + 5 or runtime.current_cursor_y == y_old)) : (ixx += 1) {
                fnT_ARROW(runtime.ITM_T_LEFT_ARROW);
                showUpTo.call();
            }
        },
        runtime.ITM_T_DOWN_ARROW => {
            var ixx: u16 = 0;
            const x_old = runtime.current_cursor_x;
            const y_old = runtime.current_cursor_y;
            fnT_ARROW(runtime.ITM_T_LEFT_ARROW);
            while (ixx < 75 and (@as(u32, runtime.current_cursor_x) + 5 <= @as(u32, x_old) or runtime.current_cursor_y == y_old)) : (ixx += 1) {
                fnT_ARROW(runtime.ITM_T_RIGHT_ARROW);
                showUpTo.call();
            }
        },
        runtime.ITM_UP1 => { // HOME
            runtime.T_cursorPos = 0;
            runtime.displayAIMbufferoffset = 0;
        },
        runtime.ITM_DOWN1 => { // END
            runtime.T_cursorPos = @as(i16, @intCast(runtime.strlen(runtime.aimBuffer))) - 1;
            runtime.T_cursorPos = runtime.stringNextGlyph(runtime.aimBuffer, runtime.T_cursorPos);
            fnT_ARROW(runtime.ITM_T_RIGHT_ARROW);
            runtime.findOffset();
        },
        else => {},
    }

    const last = runtime.stringNextGlyph(runtime.aimBuffer, runtime.stringLastGlyph(runtime.aimBuffer));
    if (runtime.T_cursorPos > last) {
        runtime.T_cursorPos = last;
    }
    if (runtime.T_cursorPos < 0) {
        runtime.T_cursorPos = 0;
    }
}

// keyboardTweak.c refreshModeGui: sync the on-screen-keyboard mode to calcMode.
// calcMode*Gui are empty macros on the DMCP lane, so the calls are host-only.
pub export fn refreshModeGui() callconv(.c) void {
    if (runtime.tam.mode == 0) {
        switch (runtime.calcMode) {
            runtime.CM_AIM, runtime.CM_EIM => {
                if (comptime !is_dmcp_build) runtime.calcModeAimGui();
            },
            runtime.CM_NORMAL => {
                if (comptime !is_dmcp_build) runtime.calcModeNormalGui();
            },
            runtime.CM_PEM => {
                if (runtime.getSystemFlag(runtime.FLAG_ALPHA)) {
                    if (comptime !is_dmcp_build) runtime.calcModeAimGui();
                } else {
                    if (comptime !is_dmcp_build) runtime.calcModeNormalGui();
                }
            },
            else => {},
        }
    }
}

// keyboardTweak.c showAlphaModeonGui: refresh the alpha-mode indicator/keyboard.
pub export fn showAlphaModeonGui() callconv(.c) void {
    // The PC_BUILD jm_show_comment trace is a no-op (PC_BUILD_VERBOSE2 only).
    if (runtime.calcMode == runtime.CM_AIM or runtime.calcMode == runtime.CM_EIM or runtime.tam.mode != 0) {
        runtime.showHideAlphaMode();
        if (comptime !is_dmcp_build) runtime.calcModeAimGui();
    }
    runtime.screenUpdatingMode &= ~runtime.SCRUPD_MANUAL_MENU;
    runtime.screenUpdatingMode &= ~runtime.SCRUPD_SKIP_MENU_ONE_TIME;
}

// keyboardTweak.c fnCln: clear to a clean "+0" entry (clear-number).
pub export fn fnCln(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    _ = runtime.strcpy(runtime.aimBuffer, "+0");
    runtime.fnKeyBackspace(0);
    runtime.setSystemFlag(runtime.FLAG_ASLIFT);
    runtime.screenUpdatingMode = runtime.SCRUPD_AUTO;
    runtime.screenUpdatingMode |= runtime.SCRUPD_SKIP_STATUSBAR_ONE_TIME;
}
