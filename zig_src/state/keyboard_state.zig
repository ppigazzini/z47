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

fn checkKeyShiftsHost(data: [*c]const u8) callconv(.c) runtime.bool_t {
    return shared.checkKeyShifts(data);
}

// btnFnClicked: a function-key click runs the function directly. Host-only
// export (its body reaches executeFunction -> clearScreen -> lcd_fill_rect,
// which only resolves on the host lane); DMCP keeps the canonical C.  This is
// also the live caller that forces executeFunction's compile-analysis.
fn btnFnClickedHost(not_used: ?*anyopaque, data: ?*anyopaque) callconv(.c) void {
    _ = not_used;
    shared.executeFunction(@ptrCast(data), 0);
}

fn determineFunctionKeyItem_C47Host(data: [*c]const u8, shiftF: runtime.bool_t, shiftG: runtime.bool_t) callconv(.c) i16 {
    return shared.determineFunctionKeyItem_C47(data, shiftF, shiftG);
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

// Minimal GdkEventButton view: only `type` (offset 0) and `button` (offset 52)
// are read; the layout matches the GTK ABI on the host lane.
const GdkEventButton = extern struct {
    type: c_int,
    _reserved: [48]u8,
    button: c_uint,
};
const GDK_DOUBLE_BUTTON_PRESS: c_int = 5;
const GDK_TRIPLE_BUTTON_PRESS: c_int = 6;

// Full keyboard.c btnPressed (1778-1943) for the host lane. The C program-stop
// path clears the status-bar flags with a buggy `&= !(mask)` (logical not);
// the previous btnPressedHostOverlay patched it afterwards, and that fix is
// folded in here as the correct `&= ~(mask)`.  DMCP keeps the C body via the
// btnPressedDmcp overlay.
fn btnPressedHost(not_used: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) void {
    _ = not_used;
    const ev: *const GdkEventButton = @ptrCast(@alignCast(event));
    const dat: [*c]u8 = @ptrCast(data);

    runtime.reDraw = false;
    runtime.nimWhenButtonPressed = (runtime.calcMode == runtime.CM_NIM);
    runtime.lastT_cursorPos = runtime.T_cursorPos;

    const keyCode: c_int = (@as(c_int, dat[0]) - '0') * 10 + @as(c_int, dat[1]) - '0';
    runtime.currentKeyCode = @intCast(keyCode);
    runtime.asnKey[0] = dat[0];
    runtime.asnKey[1] = dat[1];
    runtime.asnKey[2] = 0;

    if (runtime.programRunStop == runtime.PGM_RUNNING or runtime.programRunStop == runtime.PGM_PAUSED) {
        shared.setLastKeyCode(keyCode + 1);
    } else {
        runtime.lastKeyCode = 0;
    }

    if (ev.type == GDK_DOUBLE_BUTTON_PRESS or ev.type == GDK_TRIPLE_BUTTON_PRESS) {
        return;
    }
    if (ev.button == 2) {
        runtime.shiftF = true;
        runtime.shiftG = false;
    }
    if (ev.button == 3) {
        runtime.shiftF = false;
        runtime.shiftG = true;
    }

    const f = runtime.shiftF;
    const g = runtime.shiftG;
    const ff = runtime.lastshiftF;
    const gg = runtime.lastshiftG;
    runtime.lastshiftF = runtime.shiftF;
    runtime.lastshiftG = runtime.shiftG;

    const item = shared.determineItem(dat);
    runtime.lastKeyItemDetermined = item;

    if (runtime.programRunStop == runtime.PGM_RUNNING or runtime.programRunStop == runtime.PGM_PAUSED) {
        if ((item == runtime.ITM_RS or item == runtime.ITM_EXIT1) and !runtime.getSystemFlag(runtime.FLAG_INTING) and !runtime.getSystemFlag(runtime.FLAG_SOLVING)) {
            runtime.screenUpdatingMode &= ~(runtime.SCRUPD_MANUAL_STATUSBAR | runtime.SCRUPD_SKIP_STATUSBAR_ONE_TIME);
            runtime.programRunStop = runtime.PGM_WAITING;
            runtime.showFunctionNameItem = 0;
            // IR_PRINTING (defined on host): trace the STOP.
            runtime.refreshStatusBar();
            runtime.printTrace(runtime.ITM_STOP, runtime.NOPARAM);
        } else if (runtime.programRunStop == runtime.PGM_PAUSED) {
            runtime.programRunStop = runtime.PGM_KEY_PRESSED_WHILE_PAUSED;
        }
        return;
    }

    var funcParam: [*c]const u8 = "";
    runtime.keyStateCode = @intCast((if (runtime.getSystemFlag(runtime.FLAG_ALPHA)) @as(c_int, 3) else 0) + (if (g) @as(c_int, 2) else if (f) @as(c_int, 1) else 0));
    if (runtime.getSystemFlag(runtime.FLAG_USER)) {
        funcParam = runtime.getNthString(runtime.userKeyLabel, @intCast(keyCode * 6 + runtime.keyStateCode));
        _ = runtime.xcopy(runtime.tmpString, funcParam, @intCast(runtime.stringByteLength(funcParam) + 1));
    } else if ((@as(i16, runtime.currentKeyCode) == runtime.normKey00Key()) and (runtime.keyStateCode == 0) and runtime.Norm_Key_00.used and !(runtime.lastIntegerBase >= 2 and runtime.getSystemFlag(runtime.FLAG_TOPHEX))) {
        funcParam = &runtime.Norm_Key_00.funcParam;
        _ = runtime.xcopy(runtime.tmpString, funcParam, @intCast(runtime.stringByteLength(funcParam) + 1));
    } else {
        runtime.tmpString[0] = 0;
    }

    runtime.showFunctionNameItem = 0;

    if (item != runtime.ITM_NOP and item != runtime.ITM_NULL) {
        shared.processKeyAction(item);
        if (!runtime.keyActionProcessed) {
            runtime.showFunctionName(item, 1000, funcParam);
        }
    } else if (runtime.calcMode == runtime.CM_REGISTER_BROWSER) {
        runtime.screenUpdatingMode = runtime.SCRUPD_AUTO;
        runtime.screenUpdatingMode |= runtime.SCRUPD_SKIP_STATUSBAR_ONE_TIME;
        runtime.refreshScreen(126);
    }

    switch (runtime.tam.function) {
        runtime.ITM_DENMAX2, runtime.ITM_WSIZE, runtime.ITM_SETFDIGS => {
            runtime.screenUpdatingMode &= ~runtime.SCRUPD_MANUAL_STATUSBAR;
            runtime.refreshStatusBar();
        },
        else => {},
    }

    if (runtime.calcMode == runtime.CM_ASSIGN and runtime.itemToBeAssigned != 0 and runtime.tamBuffer[0] == 0) {
        runtime.shiftF = f;
        runtime.shiftG = g;
        runtime.lastshiftF = ff;
        runtime.lastshiftG = gg;
    }
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
        @export(&checkKeyShiftsHost, .{ .name = "checkKeyShifts" });
        @export(&btnFnClickedHost, .{ .name = "btnFnClicked" });
        @export(&determineFunctionKeyItem_C47Host, .{ .name = "determineFunctionKeyItem_C47" });
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
