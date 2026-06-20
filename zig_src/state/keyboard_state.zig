const builtin = @import("builtin");
const runtime = @import("keyboard_state_runtime.zig");
const shared = @import("keyboard_state_shared.zig").implementation(runtime);

const is_dmcp_build = builtin.target.os.tag == .freestanding;

fn processKeyActionHost(item: i16) callconv(.c) void {
    shared.processKeyAction(item);
}

fn processAimInputHost(item: i16) callconv(.c) void {
    shared.processAimInput(item);
}

fn leavePemHost() callconv(.c) void {
    shared.leavePem();
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
        @export(&processAimInputHost, .{ .name = "processAimInput" });
        @export(&leavePemHost, .{ .name = "leavePem" });
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

// keyboardTweak.c key-click helpers. The DM42_KEYCLICK / CLICK_REFRESHSCR /
// DM42_POWERMARKS / DM42_POWERMARK_KEYPRESS feature flags are never defined, so
// these expand to no-ops on every build (host and DMCP alike).
pub export fn @"_keyClick"(length_ms: u8, f: u32) callconv(.c) void {
    _ = .{ length_ms, f };
}
pub export fn keyClick(length_ms: u8) callconv(.c) void {
    _ = length_ms;
}
pub export fn powerMarkerMsF(length_ms: u8, f: u32) callconv(.c) void {
    _ = .{ length_ms, f };
}

// keyboardTweak.c openHOMEorMyM: f/g triple/long-press opens HOME or MyMenu.
pub export fn openHOMEorMyM(situation: runtime.bool_t) callconv(.c) void {
    const graphmode = runtime.calcMode == runtime.CM_PLOT_STAT or runtime.calcMode == runtime.CM_GRAPH;
    if (!((runtime.getSystemFlag(runtime.FLAG_HOME_TRIPLE) or runtime.getSystemFlag(runtime.FLAG_MYM_TRIPLE)) and !graphmode and runtime.calcMode != runtime.CM_EIM and runtime.calcMode != runtime.CM_MIM)) {
        return;
    }
    // f/g long-press is temporarily disabled in EIM and MIM.

    var target_HOME: i16 = if (runtime.calcMode == runtime.CM_PEM) -runtime.MNU_PFN else -runtime.MNU_HOME;
    const target_MYM: i16 = if (runtime.calcMode == runtime.CM_PEM) -runtime.MNU_PFN else -runtime.MNU_MyMenu;

    var baseOverrideOnce: runtime.bool_t = false;
    runtime.BASE_OVERRIDEONCE = baseOverrideOnce;

    if (runtime.getSystemFlag(runtime.FLAG_ALPHA)) {
        runtime.leaveTamModeIfEnabled();
        if (runtime.getSystemFlag(runtime.FLAG_HOME_TRIPLE)) {
            if (runtime.currentMenu() == -runtime.MNU_MyAlpha or runtime.currentMenu() == -runtime.MNU_AIMCATALOG or runtime.isAlphabeticSoftmenu()) {
                runtime.popSoftmenu();
            }
            if (runtime.tam.alpha) {
                runtime.showSoftmenu(-runtime.MNU_TAMALPHA);
            } else {
                runtime.showSoftmenu(-runtime.MNU_ALPHA);
            }
        } else if (runtime.getSystemFlag(runtime.FLAG_MYM_TRIPLE)) {
            runtime.showSoftmenu(-runtime.MNU_MyAlpha);
        }
    } else {
        runtime.leaveTamModeIfEnabled();

        const keyCode: c_int = if (runtime.calcModel == runtime.USER_R47bk_fg)
            11
        else if (runtime.calcModel == runtime.USER_R47fg_bk or runtime.calcModel == runtime.USER_R47fg_g)
            10
        else if (runtime.calcModel == runtime.USER_C47 or runtime.calcModel == runtime.USER_DM42)
            27
        else
            9999;
        if (keyCode != 9999) {
            const item = runtime.kbd_usr[@intCast(keyCode)].gShifted;
            if (runtime.calcMode == runtime.CM_NIM and runtime.getSystemFlag(runtime.FLAG_USER) and
                item != runtime.ITM_ms and item != runtime.ITM_CC and item != runtime.ITM_op_j and
                item != runtime.ITM_op_j_pol and item != runtime.ITM_dotD and item != runtime.ITM_HASH_JM and
                item != runtime.ITM_toINT and item != runtime.ITM_BACKSPACE and
                !runtime.itemFuncIsAddItemToBuffer(item))
            {
                runtime.delayCloseNim = false;
                runtime.closeNim();
                runtime.screenUpdatingMode &= ~runtime.SCRUPD_MANUAL_MENU;
            }
            if (runtime.getSystemFlag(runtime.FLAG_USER)) { // USER mode
                if (runtime.calcMode != runtime.CM_AIM and runtime.calcMode != runtime.CM_EIM and item > 0) {
                    runtime.@"_executeItem"(item, keyCode); // LONGPRESS_CFG is defined
                    runtime.screenUpdatingMode = runtime.SCRUPD_AUTO;
                    runtime.refreshScreen(1000);
                } else {
                    if (item < 0) {
                        if (item == -runtime.MNU_DYNAMIC) {
                            const funcParam = runtime.getNthString(runtime.userKeyLabel, @intCast(keyCode * 6 + 1));
                            _ = runtime.setCurrentUserMenu(item, funcParam);
                        }
                        target_HOME = if (item == -runtime.MNU_HOME and runtime.getSystemFlag(runtime.FLAG_MYM_TRIPLE)) -runtime.MNU_MyMenu else item;
                        runtime.showSoftmenu(target_HOME);
                    } else {
                        if (runtime.getSystemFlag(runtime.FLAG_HOME_TRIPLE)) {
                            runtime.leaveTamModeIfEnabled();
                            runtime.showSoftmenu(target_HOME);
                        } else if (runtime.getSystemFlag(runtime.FLAG_MYM_TRIPLE)) {
                            runtime.leaveTamModeIfEnabled();
                            if (situation == runtime.keypress_fff) {
                                runtime.BASE_OVERRIDEONCE = true;
                            }
                            runtime.showSoftmenu(target_MYM);
                        }
                    }
                }
            } else { // Normal mode
                if (runtime.getSystemFlag(runtime.FLAG_HOME_TRIPLE)) {
                    runtime.leaveTamModeIfEnabled();
                    runtime.showSoftmenu(target_HOME);
                } else if (runtime.getSystemFlag(runtime.FLAG_MYM_TRIPLE)) {
                    if (runtime.getSystemFlag(runtime.FLAG_BASE_MYM) or runtime.getSystemFlag(runtime.FLAG_BASE_HOME)) {
                        runtime.leaveTamModeIfEnabled();
                        if (situation == runtime.keypress_fff) {
                            baseOverrideOnce = true;
                        }
                        runtime.BASE_OVERRIDEONCE = baseOverrideOnce;
                        runtime.showSoftmenu(target_MYM);
                    } else {
                        baseOverrideOnce = false;
                        runtime.BASE_OVERRIDEONCE = baseOverrideOnce;
                        runtime.fnExitAllMenus(0); // both clear: return to the blank base menu
                    }
                }
            }
        }
    }
    runtime.BASE_OVERRIDEONCE = baseOverrideOnce;
    runtime.showSoftmenuCurrentPart();
    runtime.BASE_OVERRIDEONCE = baseOverrideOnce; // for the upcoming refresh
    runtime.screenUpdatingMode = runtime.SCRUPD_AUTO;
    runtime.refreshScreen(23);
}

// keyboardTweak.c showShiftState: draw the f/g shift indicator (T register line).
pub export fn showShiftState() callconv(.c) void {
    if (!runtime.isShowMode() and runtime.temporaryInformation != runtime.TI_SHOW_REGISTER) {
        if (runtime.shiftF) {
            runtime.showShiftStateF();
            runtime.show_f_jm();
            runtime.showHideAlphaMode();
        } else if (runtime.shiftG) {
            runtime.showShiftStateG();
            runtime.show_g_jm();
            runtime.showHideAlphaMode();
        } else {
            runtime.clearShiftState();
            runtime.clear_fg_jm();
            runtime.showHideAlphaMode();
            runtime.cleanupAfterShift = true;
        }
    }
}

// keyboardTweak.c resetShiftState: clear the f/g shift and its screen area.
pub export fn resetShiftState() callconv(.c) void {
    runtime.fnTimerStop(runtime.TO_FG_LONG);
    runtime.fnTimerStop(runtime.TO_FG_TIMR);
    // make sure a repeated key does not restart the f shift just reset
    runtime.fnTimerStop(runtime.TO_3S_CTFF);
    runtime.fnTimerStop(runtime.TO_AUTO_REPEAT);

    if (runtime.shiftF or runtime.shiftG) {
        runtime.shiftF = false;
        runtime.shiftG = false;
        runtime.screenUpdatingMode &= ~runtime.SCRUPD_MANUAL_SHIFT_STATUS;
        showShiftState();
        runtime.screenUpdatingMode |= runtime.SCRUPD_SKIP_STACK_ONE_TIME;
        runtime.force_refresh(runtime.timed);
        refreshModeGui();
    }
}

// keyboardTweak.c resetKeytimers: reset shift plus the CL/FN long-press timers.
pub export fn resetKeytimers() callconv(.c) void {
    resetShiftState();
    runtime.fnTimerStop(runtime.TO_CL_LONG);
    runtime.fnTimerStop(runtime.TO_FN_LONG);
}

// keyboardTweak.c shiftCutoff: 3x-shift-within-1s cutoff stops the HOME timer.
pub export fn shiftCutoff(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.fnTimerStop(runtime.TO_3S_CTFF);
}

// keyboardTweak.c execFnTimeout: delayed click of the primary function key.
// VERBOSEKEYS tracing is dropped (never #defined on these lanes).
pub export fn execFnTimeout(key: u16) callconv(.c) void {
    var charKey: [3]u8 = undefined;
    charKey[1] = 0;
    charKey[0] = @truncate(key + 11); // key + (-37 + 48)
    if (!runtime.FN_timed_out_to_NOP_or_Executed) {
        runtime.btnFnClicked(null, @ptrCast(&charKey));
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
