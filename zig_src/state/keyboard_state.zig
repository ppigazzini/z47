const builtin = @import("builtin");
const runtime = @import("keyboard_state_runtime.zig");
const shared = @import("keyboard_state_shared.zig").implementation(runtime);

// Force-compile the DMCP key ring-buffer owner into this object. It currently
// exports nothing (the bridge still owns the C copies), so this only validates
// that the module and its per-model build option compile on every lane ahead of
// the wiring slice that renames the C copies and exports the Zig ones.
comptime {
    _ = @import("keyboard_state_ringbuffer.zig");
    _ = @import("keyboard_state_dmcp.zig");
}

const is_dmcp_build = builtin.target.os.tag == .freestanding;

// processKeyAction is exported for ALL lanes. 714 of its 717 lines are
// lane-independent and exercised by the host testSuite; its 3 DMCP-specific
// branches are faithful ports of the upstream `#if defined(DMCP_BUILD)` snippets
// (keyboard.c 2722-2729 key_pop/key_push/wait_for_key_release around
// addItemToBuffer, and 2795-2799 lcd_refresh), which are pure key-queue / LCD
// I/O now backed by the runtime ROM trampolines. Verified by faithful-port
// review + dmcp/dmcp5 link+fit (a calc-state diff harness would not cover these
// I/O side effects).
pub export fn processKeyAction(item: i16) callconv(.c) void {
    shared.processKeyAction(item);
}

pub export fn processAimInput(item: i16) callconv(.c) void {
    shared.processAimInput(item);
}

// leavePem and checkKeyShifts have no DMCP `#ifdef` divergence (C and shared.*
// identical across lanes, reaching only lane-independent program-memory / flag
// helpers), so they are exported for ALL lanes (M1). Host is unchanged.
pub export fn leavePem() callconv(.c) void {
    shared.leavePem();
}

pub export fn checkKeyShifts(data: [*c]const u8) callconv(.c) runtime.bool_t {
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

// M1 batch: these handlers are all `#ifdef`-free in both the upstream C and
// shared.* (identical across lanes, reaching only lane-independent calc / display
// helpers), so they are exported for ALL lanes. keyCC stays host-only below — it
// carries a DMCP `#ifdef` branch (M2). Host behaviour is unchanged.
pub export fn determineFunctionKeyItem_C47(data: [*c]const u8, shiftF: runtime.bool_t, shiftG: runtime.bool_t) callconv(.c) i16 {
    return shared.determineFunctionKeyItem_C47(data, shiftF, shiftG);
}

pub export fn fnKeyEnter(unused_but_mandatory_parameter: u16) callconv(.c) void {
    shared.keyEnter(unused_but_mandatory_parameter);
}

// keyExit + keyBackspace are now exported for ALL lanes. Both are divergence-free;
// they reach clearScreen -> lcd_fill_rect and jm_show_calc_state, which are now
// lane-aware ROM trampolines / no-ops in the runtime, so they link and run on the
// DMCP lanes. keyCC stays host-only (DMCP `#ifdef` divergence → M2).
pub export fn fnKeyExit(unused_but_mandatory_parameter: u16) callconv(.c) void {
    shared.keyExit(unused_but_mandatory_parameter);
}

// keyCC's only DMCP divergence is the host-only EXTRA_INFO_ON_CALC_ERROR console
// block (off on firmware, where the macro is 0 — defines.h:2351), so the firmware
// path carries no active DMCP-specific behaviour and its calc logic is the
// host-tested one. Exported for ALL lanes.
pub export fn fnKeyCC(complex_type: u16) callconv(.c) void {
    shared.keyCC(complex_type);
}

pub export fn fnKeyBackspace(unused_but_mandatory_parameter: u16) callconv(.c) void {
    shared.keyBackspace(unused_but_mandatory_parameter);
}

pub export fn fnKeyUp(unused_but_mandatory_parameter: u16) callconv(.c) void {
    shared.keyUp(unused_but_mandatory_parameter);
}

pub export fn fnKeyDown(unused_but_mandatory_parameter: u16) callconv(.c) void {
    shared.keyDown(unused_but_mandatory_parameter);
}

// fnKeyDotD has no DMCP `#ifdef` divergence: the C handler and shared.keyDotD are
// identical across lanes and reach only lane-independent calc functions, so it is
// exported for ALL lanes — the first keyboard handler taken off the C on firmware
// (M1 leaf). Host behaviour is unchanged (it already used this Zig owner).
pub export fn fnKeyDotD(unused_but_mandatory_parameter: u16) callconv(.c) void {
    shared.keyDotD(unused_but_mandatory_parameter);
}

// Minimal GdkEventButton view matching the GTK ABI offsets on the host lane:
// type@0, x@24, y@32, button@52.
const GdkEventButton = extern struct {
    type: c_int,
    _pad0: [20]u8,
    x: f64,
    y: f64,
    _pad1: [12]u8,
    button: c_uint,
};
const GDK_DOUBLE_BUTTON_PRESS: c_int = 5;
const GDK_TRIPLE_BUTTON_PRESS: c_int = 6;

// keyboard.c `key[3]` (the mouse-coordinate dispatch state), now Zig-owned.
var mouse_key: [3]u8 = .{ 0, 0, 0 };

// keyboard.c convertXYToKey (1949-1978): map a click coordinate to a key string.
fn convertXYToKey(x: c_int, y: c_int) void {
    mouse_key[0] = 0;
    mouse_key[1] = 0;
    mouse_key[2] = 0;
    var i: usize = 0;
    while (i < 43) : (i += 1) {
        const xMin = runtime.calcKeyboard[i].x;
        const yMin = runtime.calcKeyboard[i].y;
        var xMax: c_int = undefined;
        var yMax: c_int = undefined;
        if (i == 10 and runtime.currentBezel == 2 and (runtime.tam.mode == runtime.TM_LABEL or runtime.tam.mode == runtime.TM_LBLONLY or (runtime.tam.mode == runtime.TM_SOLVE and (runtime.tam.function != runtime.ITM_SOLVE or runtime.calcMode != runtime.CM_PEM)) or (runtime.tam.mode == runtime.TM_KEY and runtime.tam.keyInputFinished))) {
            xMax = xMin + runtime.calcKeyboard[10].width[3];
            yMax = yMin + runtime.calcKeyboard[10].height[3];
        } else {
            xMax = xMin + runtime.calcKeyboard[i].width[@intCast(runtime.currentBezel)];
            yMax = yMin + runtime.calcKeyboard[i].height[@intCast(runtime.currentBezel)];
        }
        if (xMin <= x and x <= xMax and yMin <= y and y <= yMax) {
            if (i < 6) {
                mouse_key[0] = @intCast(@as(usize, '1') + i);
            } else {
                mouse_key[0] = @intCast(@as(usize, '0') + (i - 6) / 10);
                mouse_key[1] = @intCast(@as(usize, '0') + (i - 6) % 10);
            }
            break;
        }
    }
}

// keyboard.c frmCalcMouseButtonPressed (1980-1994).
fn frmCalcMouseButtonPressedHost(not_used: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) void {
    _ = not_used;
    _ = data;
    if (mouse_key[0] == 0) {
        const ev: *const GdkEventButton = @ptrCast(@alignCast(event));
        convertXYToKey(@intFromFloat(ev.x), @intFromFloat(ev.y));
        if (mouse_key[0] == 0) {
            return;
        }
        if (mouse_key[1] == 0) {
            btnFnPressedHost(null, event, &mouse_key);
        } else {
            btnPressedHost(null, event, &mouse_key);
        }
    }
}

// keyboard.c frmCalcMouseButtonReleased (1996-2009).
fn frmCalcMouseButtonReleasedHost(not_used: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) void {
    _ = not_used;
    _ = data;
    if (mouse_key[0] == 0) {
        return;
    }
    if (mouse_key[1] == 0) {
        btnFnReleasedHost(null, event, &mouse_key);
    } else {
        btnReleasedHost(null, event, &mouse_key);
    }
    mouse_key[0] = 0;
}

// keyboard.c btnPressed (1778-1943), lane-merged: the host body plus the DMCP
// divergences gated by comptime is_dmcp_build (btnPressedDmcp wraps it for the
// DMCP signature). The C program-stop path clears the status-bar flags with a
// buggy `&= !(mask)` (logical not); that fix is folded in here as `&= ~(mask)`.
fn btnPressedHost(not_used: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) void {
    _ = not_used;
    // event is the GdkEvent on the host lane only; the DMCP btnPressed body takes
    // just the key string and has no double/triple-click or middle/right shift.
    if (comptime is_dmcp_build) _ = &event;
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
        if (comptime is_dmcp_build) {
            runtime.lastKeyCode = @intCast(keyCode);
        } else {
            shared.setLastKeyCode(keyCode + 1);
        }
    } else {
        runtime.lastKeyCode = 0;
    }

    if (comptime !is_dmcp_build) {
        const ev: *const GdkEventButton = @ptrCast(@alignCast(event));
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
    }

    const f = runtime.shiftF;
    const g = runtime.shiftG;
    const ff = runtime.lastshiftF;
    const gg = runtime.lastshiftG;
    runtime.lastshiftF = runtime.shiftF;
    runtime.lastshiftG = runtime.shiftG;

    const item = shared.determineItem(dat);
    runtime.lastKeyItemDetermined = item;

    // Host: a key during a running/paused program stops or interrupts it (early
    // return). DMCP has no such block here; instead it restores the f/g shift on a
    // PEM SST/BST (keyboard.c 1864-1869) and falls through.
    if (comptime !is_dmcp_build) {
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
    } else {
        if (runtime.calcMode == runtime.CM_PEM and (item == runtime.ITM_SST or item == runtime.ITM_BST)) {
            runtime.shiftF = f;
            runtime.shiftG = g;
        }
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

// keyboard.c btnFnPressed (579-742) for the host lane (the large /* */ block in
// the C is dead code).  A soft-function-key press; the actual buffering goes
// through btnFnPressed_StateMachine to pick up long/double-press conditions.
fn btnFnPressedHost(not_used: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) void {
    _ = not_used;
    // event is the GdkEvent on the host lane only; the DMCP btnFnPressed body takes
    // just the key string and has no double/triple-click or middle/right shift. The
    // rest of the body is lane-identical (keyboard.c 593-744 has no other #ifdef).
    if (comptime is_dmcp_build) _ = &event;
    if (comptime !is_dmcp_build) {
        const ev: *const GdkEventButton = @ptrCast(@alignCast(event));
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
    }

    const dat: [*c]u8 = @ptrCast(data);
    if (runtime.showMode() or runtime.currentMenu() == -runtime.MNU_SHOW) {
        runtime.closeShowMenu();
    }

    runtime.FN_timed_out_to_NOP_or_Executed = false;
    runtime.releaseOverride = false;
    runtime.temporaryInformation = runtime.TI_NO_INFO;
    runtime.FN_key_pressed = @as(i16, dat[0]) - '0' + 37;
    runtime.asnKey[0] = dat[0];
    runtime.asnKey[1] = 0;

    if (runtime.programRunStop == runtime.PGM_RUNNING or runtime.programRunStop == runtime.PGM_PAUSED) {
        shared.setLastKeyCode((@as(i32, dat[0]) - '0') + 37);
    } else {
        runtime.lastKeyCode = 0;
    }

    if (runtime.programRunStop == runtime.PGM_PAUSED) {
        runtime.programRunStop = runtime.PGM_KEY_PRESSED_WHILE_PAUSED;
        return;
    }

    // Timer menu fast path: activate the primary function on press.
    if (!runtime.shiftF and runtime.currentMenu() == -runtime.MNU_TIMERF) {
        const softkeyItem = runtime.softmenu[@intCast(runtime.softmenuStack[0].softmenuId)].softkeyItem;
        const _item = softkeyItem[@intCast(runtime.asnKey[0] - '1')];
        runtime.reallyRunFunction(_item, runtime.NOPARAM);
        runtime.hourGlassIconEnabled = false;
        if (_item == runtime.ITM_TIMER_R_S) {
            runtime.screenUpdatingMode |= runtime.SCRUPD_SKIP_STACK_ONE_TIME;
        } else {
            runtime.screenUpdatingMode &= ~runtime.SCRUPD_MANUAL_STACK;
        }
        runtime.refreshScreen(136);
        runtime.releaseOverride = true;
        return;
    }

    runtime.lastshiftF = runtime.shiftF;
    runtime.lastshiftG = runtime.shiftG;

    if (runtime.tam.mode == runtime.TM_KEY and !runtime.tam.keyInputFinished) {
        return;
    }

    if (runtime.calcMode == runtime.CM_ASSIGN and runtime.itemToBeAssigned != 0 and !(runtime.tam.alpha and runtime.tam.mode != runtime.TM_NEWMENU)) {
        var item = shared.determineFunctionKeyItem_C47(dat, runtime.shiftF, runtime.shiftG);
        switch (-runtime.currentMenu()) {
            runtime.MNU_MENUS => {
                if (item <= runtime.ASSIGN_USER_MENU) {
                    runtime.currentUserMenu = @intCast(@as(i32, runtime.ASSIGN_USER_MENU) - @as(i32, item));
                    item = -runtime.MNU_DYNAMIC;
                }
                runtime.showFunctionNameItem = item; // C falls through to the CAT case
            },
            runtime.MNU_CATALOG, runtime.MNU_CHARS, runtime.MNU_PROGS, runtime.MNU_VARS => {
                runtime.showFunctionNameItem = item;
            },
            else => {
                runtime.updateAssignTamBuffer();
            },
        }
        shared._closeCatalog();
    } else if (runtime.calcMode != runtime.CM_REGISTER_BROWSER and runtime.calcMode != runtime.CM_FLAG_BROWSER and runtime.calcMode != runtime.CM_ASN_BROWSER and runtime.calcMode != runtime.CM_FONT_BROWSER) {
        runtime.lastErrorCode = 0;
        runtime.btnFnPressed_StateMachine(null, data);
    }
}

// keyboard.c btnFnReleased (811-917) for the host lane; `event` is unused.  The
// soft-function-key release: TAM-key digit pairs, the assign-to-menu commit,
// and otherwise the long/double-press state machine.
fn btnFnReleasedHost(not_used: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) void {
    _ = not_used;
    _ = event;
    const dat: [*c]u8 = @ptrCast(data);

    if (runtime.catalog != 0) {
        runtime.resetAlphaSelectionBuffer();
    }
    if (runtime.programRunStop == runtime.PGM_KEY_PRESSED_WHILE_PAUSED) {
        runtime.programRunStop = runtime.PGM_RESUMING;
        runtime.screenUpdatingMode &= ~runtime.SCRUPD_ONE_TIME_FLAGS;
        return;
    }

    if (runtime.calcMode != runtime.CM_REGISTER_BROWSER and runtime.calcMode != runtime.CM_FLAG_BROWSER and runtime.calcMode != runtime.CM_ASN_BROWSER and runtime.calcMode != runtime.CM_FONT_BROWSER) {
        if (runtime.tam.mode == runtime.TM_KEY and !runtime.tam.keyInputFinished) {
            if (runtime.tam.digitsSoFar == 0) {
                // Digit item codes are a mix of u16/i16 in the runtime; alias as u16.
                const d0: u16 = @intCast(runtime.ITM_0);
                const d1: u16 = @intCast(runtime.ITM_1);
                const d2: u16 = @intCast(runtime.ITM_2);
                const d3: u16 = @intCast(runtime.ITM_3);
                const d4: u16 = @intCast(runtime.ITM_4);
                const d5: u16 = @intCast(runtime.ITM_5);
                const d6: u16 = @intCast(runtime.ITM_6);
                const d7: u16 = @intCast(runtime.ITM_7);
                const d8: u16 = @intCast(runtime.ITM_8);
                const d9: u16 = @intCast(runtime.ITM_9);
                switch (dat[0]) {
                    '1' => {
                        runtime.tamProcessInput(if (runtime.shiftG) d1 else d0);
                        runtime.tamProcessInput(if (runtime.shiftG) d3 else if (runtime.shiftF) d7 else d1);
                    },
                    '2' => {
                        runtime.tamProcessInput(if (runtime.shiftG) d1 else d0);
                        runtime.tamProcessInput(if (runtime.shiftG) d4 else if (runtime.shiftF) d8 else d2);
                    },
                    '3' => {
                        runtime.tamProcessInput(if (runtime.shiftG) d1 else d0);
                        runtime.tamProcessInput(if (runtime.shiftG) d5 else if (runtime.shiftF) d9 else d3);
                    },
                    '4' => {
                        runtime.tamProcessInput(if (runtime.shiftG or runtime.shiftF) d1 else d0);
                        runtime.tamProcessInput(if (runtime.shiftG) d6 else if (runtime.shiftF) d0 else d4);
                    },
                    '5' => {
                        runtime.tamProcessInput(if (runtime.shiftG or runtime.shiftF) d1 else d0);
                        runtime.tamProcessInput(if (runtime.shiftG) d7 else if (runtime.shiftF) d1 else d5);
                    },
                    '6' => {
                        runtime.tamProcessInput(if (runtime.shiftG or runtime.shiftF) d1 else d0);
                        runtime.tamProcessInput(if (runtime.shiftG) d8 else if (runtime.shiftF) d2 else d6);
                    },
                    else => {},
                }
                runtime.shiftF = false;
                runtime.shiftG = false;
                runtime.refreshScreen(107);
            }
            runtime.screenUpdatingMode &= ~runtime.SCRUPD_ONE_TIME_FLAGS;
            return;
        }

        if (runtime.calcMode == runtime.CM_ASSIGN and runtime.itemToBeAssigned != 0 and !(runtime.tam.alpha and runtime.tam.mode != runtime.TM_NEWMENU)) {
            if (shared.assignToMenu(dat)) {
                if (runtime.previousCalcMode == runtime.CM_AIM) {
                    runtime.showSoftmenu(-runtime.MNU_ALPHA);
                    runtime.screenUpdatingMode &= ~runtime.SCRUPD_MANUAL_STACK;
                    runtime.refreshScreen(108);
                }
                return;
            }
        }

        if (!runtime.releaseOverride) {
            runtime.btnFnReleased_StateMachine(null, data);
            runtime.releaseOverride = false;
        }

        if (runtime.calcMode == runtime.CM_AIM) {
            runtime.refreshRegisterLine(runtime.REGISTER_T);
        }
        if (runtime.tam.alpha) {
            runtime.displayShiftAndTamBuffer();
        }
    }
    runtime.screenUpdatingMode &= ~runtime.SCRUPD_MANUAL_STATUSBAR;
    runtime.fnTimerStop(runtime.TO_3S_CTFF);
    runtime.fnTimerStop(runtime.TO_CL_LONG);
}

// Full keyboard.c btnReleased (2032-2306) for the host lane; `event` is unused.
// The C `goto RELEASE_END` is modeled as a labeled block so the release tail
// runs on every non-early-return exit.  DMCP keeps the C body.
fn btnReleasedHost(not_used: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) void {
    _ = not_used;
    _ = event;
    const dat: [*c]u8 = @ptrCast(data);
    const keyCode: c_int = (@as(c_int, dat[0]) - '0') * 10 + @as(c_int, dat[1]) - '0';

    if (runtime.showMode() and (runtime.lastItem == runtime.KEY_fg or runtime.lastItem == runtime.ITM_SHIFTf) and runtime.lastItem != runtime.SCREENDUMP) {
        runtime.fg_processing_jm();
        runtime.shiftF = true;
        runtime.shiftG = false;
        runtime.lastshiftF = runtime.shiftF;
        runtime.lastshiftG = runtime.shiftG;
        runtime.lastItem = 0;
        if (runtime.showMode() or runtime.currentMenu() == -runtime.MNU_SHOW) {
            runtime.closeShowMenu();
        }
        runtime.showShiftState();
        runtime.refreshModeGui();
        runtime.screenUpdatingMode &= ~runtime.SCRUPD_MANUAL_SHIFT_STATUS;
    }
    if (runtime.showMode()) {
        runtime.lastItem = 0;
    }
    if (runtime.temporaryInformation == runtime.TI_SHOWNOTHING) {
        return;
    }

    runtime.Shft_timeouts = false;
    runtime.Shft_LongPress_f_g = false;
    runtime.JM_auto_longpress_enabled = 0;

    if (runtime.programRunStop == runtime.PGM_KEY_PRESSED_WHILE_PAUSED) {
        runtime.programRunStop = runtime.PGM_RESUMING;
        runtime.screenUpdatingMode &= ~runtime.SCRUPD_ONE_TIME_FLAGS;
        return;
    }

    rel: {
        if (runtime.calcMode == runtime.CM_ASN_BROWSER and runtime.lastItem == runtime.ITM_PERIOD) {
            runtime.fnAsnDisplayUSER = true;
            runtime.lastItem = 0;
            break :rel;
        }
        if (runtime.calcMode == runtime.CM_LISTXY) {
            return;
        }

        runtime.screenUpdatingMode |= runtime.SCRUPD_MANUAL_MENU;
        runtime.screenUpdatingMode &= ~runtime.SCRUPD_SKIP_MENU_ONE_TIME;

        if (runtime.calcMode == runtime.CM_NORMAL and runtime.showFunctionNameItem == 0 and runtime.lastKeyItemDetermined == runtime.ITM_RS and !runtime.showMode() and runtime.calcMode != runtime.CM_REGISTER_BROWSER) {
            runtime.showFunctionNameItem = runtime.ITM_RS;
            runtime.temporaryInformation = runtime.TI_NO_INFO;
            runtime.refreshRegisterLine(runtime.REGISTER_T);
        }

        if (runtime.calcMode == runtime.CM_ASSIGN and runtime.itemToBeAssigned != 0 and runtime.tamBuffer[0] == 0) {
            runtime.assignToKey(dat);
            if (runtime.previousCalcMode == runtime.CM_AIM) {
                runtime.showSoftmenu(-runtime.MNU_ALPHA);
            }
            runtime.calcMode = runtime.previousCalcMode;
            runtime.shiftF = false;
            runtime.shiftG = false;
            runtime.screenUpdatingMode = runtime.SCRUPD_AUTO;
            runtime.screenUpdatingMode |= runtime.SCRUPD_SKIP_STATUSBAR_ONE_TIME;
            runtime.refreshScreen(116);
        } else if (runtime.showFunctionNameItem != 0) {
            const item = runtime.showFunctionNameItem;

            if (runtime.calcMode == runtime.CM_NIM and runtime.delayCloseNim and item != runtime.ITM_ms and item != runtime.ITM_CC and item != runtime.ITM_op_j and item != runtime.ITM_op_j_pol and item != runtime.ITM_dotD and item != runtime.ITM_HASH_JM and item != runtime.ITM_toINT) {
                runtime.delayCloseNim = false;
                runtime.closeNim();
                runtime.screenUpdatingMode &= ~runtime.SCRUPD_MANUAL_MENU;
            }

            runtime.fnTimerStop(runtime.TO_3S_CTFF);
            runtime.hideFunctionName();

            const Norm_Key_00_released = !runtime.getSystemFlag(runtime.FLAG_USER) and (runtime.keyStateCode == 0) and (@as(i16, runtime.currentKeyCode) == runtime.normKey00Key()) and runtime.Norm_Key_00.used and !(runtime.lastIntegerBase >= 2 and runtime.getSystemFlag(runtime.FLAG_TOPHEX));

            var funcParam: [*c]u8 = if (Norm_Key_00_released) &runtime.Norm_Key_00.funcParam else runtime.getNthString(runtime.userKeyLabel, @intCast(keyCode * 6 + runtime.keyStateCode));
            if (runtime.showFunctionNameArg != null) {
                funcParam = runtime.showFunctionNameArg;
            }

            if (item < 0) {
                _ = runtime.setCurrentUserMenu(item, funcParam);
                runtime.showSoftmenu(item);
                runtime.screenUpdatingMode &= ~runtime.SCRUPD_MANUAL_MENU;
            } else {
                if (item == runtime.ITM_RS or item == runtime.ITM_XEQ) {
                    mouse_key[0] = 0;
                }

                if (item != runtime.ITM_NOP and runtime.tam.alpha and !runtime.itemFuncIsAddItemToBuffer(item) and runtime.aimBuffer[0] == 0) {
                    if (item == runtime.ITM_EXIT1) {
                        if (runtime.currentMenu() == -runtime.MNU_TAMALPHA) {
                            runtime.popSoftmenu();
                            runtime.numberOfTamMenusToPop -= 1;
                            runtime.tam.alpha = false;
                        }
                    } else if (item != runtime.ITM_BACKSPACE) {
                        runtime.leaveTamModeIfEnabled();
                    }
                }
                if (item == runtime.ITM_EXIT1 and runtime.tam.alpha and runtime.aimBuffer[0] != 0) {
                    if (runtime.currentMenu() == -runtime.MNU_TAMALPHA) {
                        runtime.popSoftmenu();
                        runtime.numberOfTamMenusToPop -= 1;
                        runtime.aimBuffer[0] = 0;
                        runtime.tam.alpha = false;
                    }
                }
                if (item == runtime.ITM_RCL and (runtime.getSystemFlag(runtime.FLAG_USER) or Norm_Key_00_released) and funcParam[0] != 0) {
                    const variable = runtime.findNamedVariable(funcParam);
                    if (variable != @as(i16, @intCast(runtime.INVALID_VARIABLE))) {
                        if (runtime.calcMode == runtime.CM_PEM) {
                            runtime.insertUserItemInProgram(item, funcParam);
                        } else {
                            runtime.reallyRunFunction(item, @bitCast(variable));
                        }
                    } else {
                        runtime.displayCalcErrorMessage(runtime.ERROR_UNDEF_SOURCE_VAR, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
                        if (comptime !runtime.is_dmcp_build) {
                            runtime.fmtCStr(runtime.errorMessage, "string '{s}' is not a named variable", .{@as([*:0]const u8, funcParam)});
                            runtime.moreInfoOnError("In function btnReleased:", runtime.errorMessage, null, null);
                        }
                    }
                } else if (item == runtime.ITM_XEQ and (runtime.getSystemFlag(runtime.FLAG_USER) or Norm_Key_00_released) and funcParam[0] != 0) {
                    const label = runtime.findNamedLabel(funcParam);
                    if (label != @as(i16, @intCast(runtime.INVALID_VARIABLE))) {
                        if (runtime.calcMode == runtime.CM_PEM) {
                            runtime.insertUserItemInProgram(item, funcParam);
                        } else {
                            runtime.reallyRunFunction(item, @bitCast(label));
                        }
                    } else {
                        runtime.displayCalcErrorMessage(runtime.ERROR_LABEL_NOT_FOUND, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
                        if (comptime !runtime.is_dmcp_build) {
                            runtime.fmtCStr(runtime.errorMessage, "string '{s}' is not a named label", .{@as([*:0]const u8, funcParam)});
                            runtime.moreInfoOnError("In function btnReleased:", runtime.errorMessage, null, null);
                        }
                    }
                } else {
                    if (item == runtime.ITM_SNAP) {
                        runtime.refreshScreen(137);
                    }
                    // The C guards this with the truthy CM_NIM constant (not a
                    // calcMode test); replicated faithfully.
                    if (runtime.CM_NIM != 0 and (item == runtime.ITM_AIM or item == runtime.ITM_XEQ or item == runtime.ITM_GTO) and runtime.nimNumberPart == runtime.NP_INT_BASE and runtime.aimBuffer[runtime.strlen(runtime.aimBuffer) - 1] == '#') {
                        break :rel;
                    }
                    if (item == runtime.ITM_BASEMENU) {
                        runtime.leaveTamModeIfEnabled();
                    }
                    runtime.runFunction(item);
                }
            }
        }

        if (runtime.programRunStop == runtime.PGM_SINGLE_STEP) {
            runtime.programRunStop = runtime.PGM_STOPPED;
            runtime.runProgram(true, runtime.INVALID_VARIABLE);
        }
    }

    // RELEASE_END:
    switch (runtime.last_CM) {
        runtime.CM_REGISTER_BROWSER, runtime.CM_FLAG_BROWSER, runtime.CM_ASN_BROWSER, runtime.CM_FONT_BROWSER => {
            runtime.screenUpdatingMode = runtime.SCRUPD_AUTO;
        },
        else => {
            if (runtime.showingProbMenu()) {
                runtime.screenUpdatingMode &= ~(runtime.SCRUPD_MANUAL_STACK | runtime.SCRUPD_SKIP_STACK_ONE_TIME);
            }
            runtime.screenUpdatingMode |= runtime.SCRUPD_SKIP_STATUSBAR_ONE_TIME;
        },
    }

    const preventRefresh = (!runtime.shiftKeyClearsError and shared.checkKeyShifts(dat)) or ((runtime.lastKeyItemDetermined == runtime.ITM_UP1 or runtime.lastKeyItemDetermined == runtime.ITM_DOWN1) and runtime.calcMode == runtime.CM_GRAPH);
    if (!preventRefresh) {
        runtime.refreshScreen(117);
    }
    runtime.screenUpdatingMode &= ~runtime.SCRUPD_ONE_TIME_FLAGS;
    runtime.shiftKeyClearsError = false;
    runtime.fnTimerStop(runtime.TO_CL_LONG);
}

// btnClicked / btnClickedP/R / btnFnClickedP/R synthesize a left-click GdkEvent
// (type 0, button 1) and drive the now-Zig press/release handlers.  Host-only;
// DMCP keeps the C btnClicked via btnClickedDmcp.
fn btnClickedHost(not_used: ?*anyopaque, data: ?*anyopaque) callconv(.c) void {
    var ev: GdkEventButton = undefined;
    ev.button = 1;
    ev.type = 0;
    btnPressedHost(not_used, &ev, data);
    btnReleasedHost(not_used, &ev, data);
}

fn btnClickedPHost(w: ?*anyopaque, data: ?*anyopaque) callconv(.c) void {
    var ev: GdkEventButton = undefined;
    ev.button = 1;
    ev.type = 0;
    btnPressedHost(w, &ev, data);
}

fn btnClickedRHost(w: ?*anyopaque, data: ?*anyopaque) callconv(.c) void {
    var ev: GdkEventButton = undefined;
    ev.button = 1; // btnReleased ignores event.type, so it is left undefined as in C
    btnReleasedHost(w, &ev, data);
}

fn btnFnClickedPHost(not_used: ?*anyopaque, data: ?*anyopaque) callconv(.c) void {
    var ev: GdkEventButton = undefined;
    ev.button = 1;
    ev.type = 0;
    btnFnPressedHost(not_used, &ev, data);
}

fn btnFnClickedRHost(not_used: ?*anyopaque, data: ?*anyopaque) callconv(.c) void {
    var ev: GdkEventButton = undefined;
    ev.button = 1;
    ev.type = 0;
    btnFnReleasedHost(not_used, &ev, data);
}

fn btnPressedDmcp(data: ?*anyopaque) callconv(.c) void {
    btnPressedHost(null, null, data);
}

fn btnClickedDmcp(unused: ?*anyopaque, data: ?*anyopaque) callconv(.c) void {
    runtime.btnClickedDmcpOverlay(unused, data);
}

// DMCP btn entry wrappers. The firmware bodies take a single `void *data` (the key
// string) with no GdkEvent. btnReleased/btnFnReleased ignore the event and
// btnFnClicked just runs the function, and their host bodies are already
// lane-aware (or divergence-free), so they serve the DMCP lane directly.
// btnPressed/btnFnPressed are NOT here yet: their host ports are PC-only and lack
// the DMCP-specific blocks, so they keep their C copies until the lane-merge slice.
fn btnReleasedDmcp(data: ?*anyopaque) callconv(.c) void {
    btnReleasedHost(null, null, data);
}
fn btnFnReleasedDmcp(data: ?*anyopaque) callconv(.c) void {
    btnFnReleasedHost(null, null, data);
}
fn btnFnClickedDmcp(unused: ?*anyopaque, data: ?*anyopaque) callconv(.c) void {
    btnFnClickedHost(unused, data);
}
fn btnFnPressedDmcp(data: ?*anyopaque) callconv(.c) void {
    btnFnPressedHost(null, null, data);
}

comptime {
    if (!is_dmcp_build) {
        @export(&btnFnClickedHost, .{ .name = "btnFnClicked" });
        @export(&btnPressedHost, .{ .name = "btnPressed" });
        @export(&btnFnPressedHost, .{ .name = "btnFnPressed" });
        @export(&btnReleasedHost, .{ .name = "btnReleased" });
        @export(&btnFnReleasedHost, .{ .name = "btnFnReleased" });
        @export(&btnClickedPHost, .{ .name = "btnClickedP" });
        @export(&btnClickedRHost, .{ .name = "btnClickedR" });
        @export(&btnFnClickedPHost, .{ .name = "btnFnClickedP" });
        @export(&btnFnClickedRHost, .{ .name = "btnFnClickedR" });
        @export(&frmCalcMouseButtonPressedHost, .{ .name = "frmCalcMouseButtonPressed" });
        @export(&frmCalcMouseButtonReleasedHost, .{ .name = "frmCalcMouseButtonReleased" });
        @export(&btnClickedHost, .{ .name = "btnClicked" });
    } else {
        @export(&btnPressedDmcp, .{ .name = "btnPressed" });
        @export(&btnClickedDmcp, .{ .name = "btnClicked" });
        @export(&btnReleasedDmcp, .{ .name = "btnReleased" });
        @export(&btnFnReleasedDmcp, .{ .name = "btnFnReleased" });
        @export(&btnFnClickedDmcp, .{ .name = "btnFnClicked" });
        @export(&btnFnPressedDmcp, .{ .name = "btnFnPressed" });
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

// keyboardTweak.c fg_processing_jm (266-307): cycle the f/g/fg shift state,
// with the triple-shift HOME/MyMenu timer activation.
pub export fn fg_processing_jm() callconv(.c) void {
    var toExecute = false;
    if (runtime.getSystemFlag(runtime.FLAG_SHFT_4s) or (runtime.getSystemFlag(runtime.FLAG_HOME_TRIPLE) or runtime.getSystemFlag(runtime.FLAG_MYM_TRIPLE))) {
        if ((runtime.getSystemFlag(runtime.FLAG_HOME_TRIPLE) or runtime.getSystemFlag(runtime.FLAG_MYM_TRIPLE)) and !(runtime.calcMode == runtime.CM_PLOT_STAT or runtime.calcMode == runtime.CM_GRAPH)) {
            if (runtime.fnTimerGetStatus(runtime.TO_3S_CTFF) == runtime.TMR_RUNNING) {
                runtime.JM_SHIFT_HOME_TIMER1 += 1;
                if (runtime.JM_SHIFT_HOME_TIMER1 >= 3) {
                    runtime.fnTimerStop(runtime.TO_FG_TIMR);
                    runtime.fnTimerStop(runtime.TO_3S_CTFF);
                    runtime.shiftF = false;
                    runtime.shiftG = true;
                    runtime.leaveTamModeIfEnabled();
                    toExecute = true;
                }
            }
            if (runtime.fnTimerGetStatus(runtime.TO_3S_CTFF) == runtime.TMR_STOPPED) {
                runtime.JM_SHIFT_HOME_TIMER1 = 1;
                runtime.fnTimerStart(runtime.TO_3S_CTFF, @intCast(runtime.TO_3S_CTFF), runtime.JM_TO_3S_CTFF);
            }
        }
    }

    if (!runtime.shiftF and !runtime.shiftG) {
        runtime.shiftF = true;
        runtime.shiftG = false;
    } else if (runtime.shiftF and !runtime.shiftG) {
        runtime.shiftF = false;
        runtime.shiftG = true;
    } else if (!runtime.shiftF and runtime.shiftG) {
        runtime.shiftF = false;
        runtime.shiftG = false;
    } else if (runtime.shiftF and runtime.shiftG) {
        runtime.shiftF = false;
        runtime.shiftG = false;
    }
    if (toExecute) {
        openHOMEorMyM(runtime.keypress_fff);
    }
}

// keyboardTweak.c Check_Norm_Key_00_Assigned (310-323): map a key to the
// assigned Norm-key function, returning the shift override if any.
pub export fn Check_Norm_Key_00_Assigned(result: [*c]i16, tempkey: i16) callconv(.c) i16 {
    if (!runtime.getSystemFlag(runtime.FLAG_USER) and (runtime.normKey00Key() != -1) and
        (runtime.calcMode == runtime.CM_NORMAL or runtime.calcMode == runtime.CM_NIM or runtime.calcMode == runtime.CM_PEM or runtime.calcMode == runtime.CM_TIMER or runtime.calcMode == runtime.CM_ASSIGN) and
        !runtime.tam.alpha and runtime.tam.mode != runtime.TM_STORCL and runtime.tam.mode != runtime.TM_LABEL and
        (runtime.catalog == 0 or (runtime.catalog != 0 and (runtime.Norm_Key_00.func != runtime.ITM_SHIFTg and runtime.Norm_Key_00.func != runtime.ITM_SHIFTf and runtime.Norm_Key_00.func != runtime.KEY_fg))) and
        (!(runtime.lastIntegerBase >= 2 and runtime.getSystemFlag(runtime.FLAG_TOPHEX))) and
        ((((!runtime.shiftF and !runtime.shiftG) or runtime.isR47FAM()) and (tempkey == runtime.normKey00Key()) and (runtime.kbdStdAt(@intCast(runtime.normKey00Key())).primary == result.*)) or
            ((runtime.Norm_Key_00.func == runtime.KEY_fg) and (tempkey == runtime.normKey00Key()) and (runtime.kbdStdAt(@intCast(runtime.normKey00Key())).primary == result.*))))
    {
        result.* = runtime.Norm_Key_00.func;
        return if (runtime.Norm_Key_00.func == runtime.ITM_SHIFTg or runtime.Norm_Key_00.func == runtime.ITM_SHIFTf or runtime.Norm_Key_00.func == runtime.KEY_fg) runtime.Norm_Key_00.func else 0;
    }
    return 0;
}

// keyboardTweak.c Setup_MultiPresses (326-341): arm the backspace double-press
// DROP timer and stop the long-press timers.
pub export fn Setup_MultiPresses(result: i16) callconv(.c) void {
    runtime.JM_auto_doublepress_autodrop_enabled = 0;
    var tmp: i16 = 0;
    if (runtime.calcMode == runtime.CM_NORMAL and result == runtime.ITM_BACKSPACE and runtime.tam.mode == 0 and !runtime.getSystemFlag(runtime.FLAG_CLX_DROP)) {
        tmp = runtime.ITM_DROP;
    }
    if (tmp != 0) {
        if (runtime.fnTimerGetStatus(runtime.TO_CL_DROP) == runtime.TMR_RUNNING) {
            runtime.JM_auto_doublepress_autodrop_enabled = tmp;
        }
        runtime.fnTimerStart(runtime.TO_CL_DROP, @intCast(runtime.TO_CL_DROP), runtime.JM_CLRDROP_TIMER);
    }
    runtime.fnTimerStop(runtime.TO_FG_LONG);
    runtime.fnTimerStop(runtime.TO_FN_LONG);
}

// keyboardTweak.c btnFnPressed_StateMachine (729-866): function-key press
// state machine (longpress / double-g detection). `data` is unused (the C
// FN_key_pressed assignment is commented out).  DEBUGSFN is true, so the
// dynmenu-label override is dead but kept for fidelity.
pub export fn btnFnPressed_StateMachine(unused: ?*anyopaque, data: ?*anyopaque) callconv(.c) void {
    _ = unused;
    _ = data;
    var exexute_double_g: bool = undefined;
    var double_click_detected: bool = undefined;

    runtime.FN_timed_out_to_RELEASE_EXEC = false;

    if (runtime.FN_state == runtime.ST_2_REL1) {
        runtime.FN_state = runtime.ST_3_PRESS2;
    } else {
        runtime.FN_state = runtime.ST_1_PRESS1;
    }

    if (runtime.FN_state == runtime.ST_3_PRESS2 and runtime.fnTimerGetStatus(runtime.TO_FN_EXEC) != runtime.TMR_RUNNING) {
        runtime.underline_softkey(@as(u16, 1) << @intCast(runtime.FN_key_pressed - 38), 3);
        runtime.hideFunctionName();
        runtime.FN_timeouts_in_progress = false;
        runtime.FN_state = runtime.ST_1_PRESS1;
    }

    if (runtime.fnTimerGetStatus(runtime.TO_FN_EXEC) == runtime.TMR_RUNNING) {
        if (runtime.FN_key_pressed_last != runtime.FN_key_pressed) {
            runtime.fnTimerExec(runtime.TO_FN_EXEC);
            runtime.FN_handle_timed_out_to_EXEC = true;
            exexute_double_g = false;
        } else {
            runtime.FN_handle_timed_out_to_EXEC = false;
            exexute_double_g = true;
            runtime.fnTimerStop(runtime.TO_FN_EXEC);
        }
        if (runtime.menu(0) == -runtime.MNU_EQ_EDIT) {
            exexute_double_g = false;
        }
    } else {
        runtime.FN_handle_timed_out_to_EXEC = true;
        exexute_double_g = false;
    }

    if (runtime.FN_state == runtime.ST_1_PRESS1) {
        runtime.FN_key_pressed_last = runtime.FN_key_pressed;
    }

    double_click_detected = false;
    if (runtime.getSystemFlag(runtime.FLAG_G_DOUBLETAP) and !runtime.blockDoublepressMenu(runtime.currentMenu(), runtime.FN_key_pressed - 38, 0)) {
        if (exexute_double_g) {
            if (runtime.FN_key_pressed != 0 and runtime.FN_key_pressed == runtime.FN_key_pressed_last) {
                runtime.shiftF = false;
                runtime.shiftG = true;
                double_click_detected = true;
                runtime.FN_handle_timed_out_to_EXEC = false;
            }
        } else {
            runtime.FN_timeouts_in_progress = false;
            runtime.fnTimerStop(runtime.TO_FN_LONG);
        }
    }

    if ((runtime.FN_state == runtime.ST_1_PRESS1 or runtime.FN_state == runtime.ST_3_PRESS2) and (!runtime.FN_timeouts_in_progress or double_click_detected) and runtime.FN_key_pressed != 0) {
        runtime.FN_timeouts_in_progress = true;
        runtime.fnTimerStart(runtime.TO_FN_LONG, @intCast(runtime.TO_FN_LONG), if (runtime.FN_state == runtime.ST_1_PRESS1) runtime.TIME_FN_12XX_TO_F else runtime.TIME_FN_DOUBLE_G_TO_NOP);
        runtime.FN_timed_out_to_NOP_or_Executed = false;

        if (!runtime.shiftF and !runtime.shiftG) {
            var varCatalogItem: [*c]const u8 = "SF:U";
            const Dyn = nameFunction(runtime.FN_key_pressed - 37, runtime.shiftF, runtime.shiftG);
            if (runtime.dynamicMenuItem > -1 and !runtime.DEBUGSFN) {
                varCatalogItem = runtime.dynmenuGetLabel(runtime.dynamicMenuItem);
            }
            runtime.showFunctionName(Dyn, 0, varCatalogItem);
            runtime.underline_softkey(@as(u16, 1) << @intCast(runtime.FN_key_pressed - 38), 0);
        } else if (runtime.shiftF and !runtime.shiftG) {
            var varCatalogItem: [*c]const u8 = "SF:V";
            const Dyn = nameFunction(runtime.FN_key_pressed - 37, runtime.shiftF, runtime.shiftG);
            if (runtime.dynamicMenuItem > -1 and !runtime.DEBUGSFN) {
                varCatalogItem = runtime.dynmenuGetLabel(runtime.dynamicMenuItem);
            }
            runtime.showFunctionName(Dyn, 0, varCatalogItem);
            runtime.underline_softkey(@as(u16, 1) << @intCast(runtime.FN_key_pressed - 38), 1);
        } else if (!runtime.shiftF and runtime.shiftG) {
            var varCatalogItem: [*c]const u8 = "SF:W";
            const Dyn = nameFunction(runtime.FN_key_pressed - 37, runtime.shiftF, runtime.shiftG);
            if (runtime.dynamicMenuItem > -1 and !runtime.DEBUGSFN) {
                varCatalogItem = runtime.dynmenuGetLabel(runtime.dynamicMenuItem);
            }
            runtime.showFunctionName(Dyn, 0, varCatalogItem);
            runtime.underline_softkey(@as(u16, 1) << @intCast(runtime.FN_key_pressed - 38), 2);
        }
    }
}

// keyboardTweak.c btnFnReleased_StateMachine (870-957): function-key release
// state machine; executes the long-press / double-release result.
pub export fn btnFnReleased_StateMachine(unused: ?*anyopaque, data: ?*anyopaque) callconv(.c) void {
    _ = data;
    if (runtime.FN_state == runtime.ST_3_PRESS2) {
        runtime.FN_state = runtime.ST_4_REL2;
    } else {
        runtime.FN_state = runtime.ST_2_REL1;
    }

    if (runtime.getSystemFlag(runtime.FLAG_G_DOUBLETAP) and !runtime.blockDoublepressMenu(runtime.currentMenu(), runtime.FN_key_pressed - 38, 0) and runtime.FN_state == runtime.ST_2_REL1 and runtime.FN_handle_timed_out_to_EXEC) {
        var offset: i16 = 0;
        if (runtime.shiftF and !runtime.shiftG) {
            offset = 6;
        } else if (!runtime.shiftF and runtime.shiftG) {
            offset = 12;
        }
        runtime.fnTimerStart(runtime.TO_FN_EXEC, @intCast(runtime.FN_key_pressed + offset), runtime.TIME_FN_DOUBLE_RELEASE);
    }

    var charKey: [3]u8 = undefined;
    charKey[0] = 0;
    const EXEC_pri = runtime.FN_timeouts_in_progress and (runtime.FN_key_pressed != 0);
    if (runtime.FN_timed_out_to_RELEASE_EXEC or runtime.FN_timed_out_to_NOP_or_Executed or EXEC_pri) {
        runtime.underline_softkey(@as(u16, 1) << @intCast(runtime.FN_key_pressed - 38), 3);
        charKey[1] = 0;
        charKey[0] = @intCast(runtime.FN_key_pressed + (-37 + 48));
        runtime.hideFunctionName();
        if (!runtime.FN_timed_out_to_NOP_or_Executed and runtime.fnTimerGetStatus(runtime.TO_FN_EXEC) != runtime.TMR_RUNNING) {
            runtime.btnFnClicked(unused, @ptrCast(&charKey));
        }
        const screenUpdatingModeMeM = runtime.screenUpdatingMode;
        runtime.resetShiftState();
        runtime.screenUpdatingMode = screenUpdatingModeMeM;
        runtime.screenUpdatingMode &= ~runtime.SCRUPD_MANUAL_STATUSBAR;
        if (!(runtime.calcMode == runtime.CM_REGISTER_BROWSER or runtime.calcMode == runtime.CM_FLAG_BROWSER or runtime.calcMode == runtime.CM_ASN_BROWSER or runtime.calcMode == runtime.CM_FONT_BROWSER or (runtime.calcMode == runtime.CM_PLOT_STAT or runtime.calcMode == runtime.CM_GRAPH) or runtime.calcMode == runtime.CM_LISTXY)) {
            if ((runtime.calcMode == runtime.CM_ASSIGN and runtime.itemToBeAssigned == 0) or runtime.FN_timed_out_to_NOP_or_Executed) {
                runtime.showSoftmenuCurrentPart();
            }
        }
        FN_cancel();
    }
}

// keyboardTweak.c nameFunction (643-658): the item for a function-key number.
pub export fn nameFunction(fn_: i16, f_shift: runtime.bool_t, g_shift: runtime.bool_t) callconv(.c) i16 {
    var str: [3]u8 = undefined;
    str[0] = @intCast(@as(i16, '0') + fn_);
    str[1] = 0;
    const func = shared.determineFunctionKeyItem_C47(&str, f_shift, g_shift);
    runtime.lastKeyItemDetermined = func;
    return if (func < 0) -func else func;
}

// keyboardTweak.c FN_cancel (721-725): cancel the pending function-key timeout.
pub export fn FN_cancel() callconv(.c) void {
    runtime.FN_key_pressed = 0;
    runtime.FN_timeouts_in_progress = false;
    runtime.fnTimerStop(runtime.TO_FN_LONG);
}

// keyboardTweak.c Check_MultiPresses (351-639): build the longpress key cycle
// for the pressed key and arm the long-press timer (TAMALPHA_f branch taken).
pub export fn Check_MultiPresses(result: [*c]i16, key_no: i8) callconv(.c) void {
    var lp1: i16 = 0;
    runtime.longpressDelayedkey2 = 0;
    runtime.longpressDelayedkey3 = 0;

    const usr = runtime.getSystemFlag(runtime.FLAG_USER);
    const ki: usize = @intCast(key_no);
    var tmpp_: i16 = if (usr) runtime.kbd_usr[ki].primary else runtime.kbdStdAt(ki).primary;
    var tmpf: i16 = 0;
    var tmpf_: i16 = if (usr) runtime.kbd_usr[ki].fShifted else runtime.kbdStdAt(ki).fShifted;
    var tmpg: i16 = 0;
    var tmpg_: i16 = if (usr) runtime.kbd_usr[ki].gShifted else runtime.kbdStdAt(ki).gShifted;

    if ((runtime.calcMode == runtime.CM_NORMAL or runtime.calcMode == runtime.CM_NIM) and runtime.tam.mode == 0) {
        if (((key_no >= 0 and key_no < 15) and (runtime.LongPressM == runtime.RBX_M1234 or runtime.LongPressM == runtime.RBX_M124)) or ((tmpp_ == runtime.ITM_DRG and tmpf_ == runtime.ITM_USERMODE)) or (tmpp_ == runtime.ITM_XEQ and tmpf_ == runtime.ITM_AIM)) {
            if (!runtime.shiftF and !runtime.shiftG and !(runtime.lastIntegerBase >= 2 and runtime.getSystemFlag(runtime.FLAG_TOPHEX) and key_no >= 0 and key_no <= 5)) {
                lp1 = tmpf_;
                tmpf = tmpf_;
                if (runtime.LongPressM == runtime.RBX_M1234) {
                    runtime.longpressDelayedkey3 = tmpg_;
                    tmpg = tmpg_;
                }
            }
        }
    } else if ((runtime.calcMode == runtime.CM_AIM or runtime.calcMode == runtime.CM_EIM or (runtime.calcMode == runtime.CM_PEM and runtime.getSystemFlag(runtime.FLAG_ALPHA))) and runtime.tam.mode == 0) {
        tmpp_ = if (usr) runtime.kbd_usr[ki].primaryAim else runtime.kbdStdAt(ki).primaryAim;
        tmpg_ = if (usr) runtime.kbd_usr[ki].gShiftedAim else runtime.kbdStdAt(ki).gShiftedAim;
        if ((key_no != 32 and tmpp_ != runtime.ITM_SHIFTf and tmpp_ != runtime.ITM_SHIFTg and tmpp_ != runtime.KEY_fg and tmpp_ != runtime.ITM_BACKSPACE) and (runtime.LongPressM == runtime.RBX_M1234 or runtime.LongPressM == runtime.RBX_M124)) {
            if (!runtime.shiftF and !runtime.shiftG) {
                lp1 = tmpg_;
                tmpg = tmpg_;
            }
        }
    } else if (runtime.tam.alpha) {
        tmpp_ = if (usr) runtime.kbd_usr[ki].primaryAim else runtime.kbdStdAt(ki).primaryAim;
        tmpf_ = if (usr) runtime.kbd_usr[ki].fShiftedAim else runtime.kbdStdAt(ki).fShiftedAim;
        if ((key_no != 32 and tmpp_ != runtime.ITM_SHIFTf and tmpp_ != runtime.ITM_SHIFTg and tmpp_ != runtime.KEY_fg and tmpp_ != runtime.ITM_BACKSPACE) and (runtime.LongPressM == runtime.RBX_M1234 or runtime.LongPressM == runtime.RBX_M124) and !((key_no == 12 or key_no == 36) and (runtime.tam.mode == runtime.TM_LABEL or runtime.tam.mode == runtime.TM_STORCL or runtime.tam.mode == runtime.TM_CMP or runtime.tam.mode == runtime.TM_KEY or runtime.tam.mode == runtime.TM_LBLONLY or runtime.tam.mode == runtime.TM_SOLVE or runtime.tam.mode == runtime.TM_MENU or runtime.tam.mode == runtime.TM_INTEGRATE or runtime.tam.mode == runtime.TM_REGISTER))) {
            if (!runtime.shiftF and !runtime.shiftG) {
                lp1 = tmpf_;
                tmpg = tmpf_;
            }
        }
    }

    const funcParam = runtime.getNthString(runtime.userKeyLabel, key_no);

    if (runtime.calcMode == runtime.CM_NORMAL and result.* == runtime.ITM_RS) {
        lp1 = runtime.ITM_NOP;
    }
    if (runtime.calcMode == runtime.CM_NORMAL and result.* == runtime.ITM_UP1) {
        lp1 = runtime.ITM_NOP;
    } else if (runtime.calcMode == runtime.CM_NORMAL and result.* == runtime.ITM_DOWN1) {
        lp1 = runtime.ITM_NOP;
    } else if (runtime.calcMode == runtime.CM_ASSIGN and result.* == runtime.ITM_EXIT1) {
        lp1 = -runtime.MNU_MyMenu;
        runtime.longpressDelayedkey2 = -runtime.MNU_HOME;
        runtime.longpressDelayedkey3 = -runtime.MNU_PFN;
    } else if (runtime.calcMode == runtime.CM_NORMAL and result.* >= runtime.ITM_A and result.* <= runtime.ITM_F and runtime.lastIntegerBase >= 2 and runtime.getSystemFlag(runtime.FLAG_TOPHEX)) {
        const ri: usize = @intCast(result.* - runtime.ITM_A);
        lp1 = if (usr) runtime.kbd_usr[ri].primary else runtime.kbdStdAt(ri).primary;
        runtime.longpressDelayedkey2 = if (usr) runtime.kbd_usr[ri].fShifted else runtime.kbdStdAt(ri).fShifted;
        runtime.longpressDelayedkey3 = if (usr) runtime.kbd_usr[ri].gShifted else runtime.kbdStdAt(ri).gShifted;
    } else if (((runtime.calcMode == runtime.CM_NORMAL or runtime.calcMode == runtime.CM_NIM) and result.* == runtime.ITM_XEQ) and runtime.tam.mode == 0 and funcParam[0] == 0 and (if (usr) runtime.kbd_usr[ki].primary == runtime.kbdStdAt(ki).primary else true)) {
        if (runtime.getSystemFlag(runtime.FLAG_SH_LONGPRESS)) {
            if (tmpp_ == runtime.ITM_XEQ and tmpf == runtime.ITM_AIM) {
                if (runtime.LongPressM == runtime.RBX_M14) {
                    lp1 = runtime.ITM_AIM;
                    runtime.longpressDelayedkey2 = 0;
                    runtime.longpressDelayedkey3 = 0;
                } else if (runtime.LongPressM == runtime.RBX_M124) {
                    lp1 = runtime.ITM_AIM;
                    runtime.longpressDelayedkey2 = 0;
                    runtime.longpressDelayedkey3 = 0;
                } else if (runtime.LongPressM == runtime.RBX_M1234) {
                    lp1 = runtime.ITM_AIM;
                    runtime.longpressDelayedkey2 = 0;
                    runtime.longpressDelayedkey3 = tmpg;
                }
            } else {
                lp1 = tmpf_;
                runtime.longpressDelayedkey2 = 0;
                runtime.longpressDelayedkey3 = tmpg_;
            }
        }
    } else if (runtime.calcMode == runtime.CM_NORMAL and result.* == runtime.ITM_BACKSPACE and runtime.tam.mode == 0) {
        lp1 = runtime.ITM_CLSTK;
        runtime.longpressDelayedkey2 = 0;
        runtime.longpressDelayedkey3 = runtime.ITM_EDIT;
    } else if ((runtime.calcMode == runtime.CM_NORMAL or runtime.calcMode == runtime.CM_NIM) and result.* == runtime.ITM_EXIT1) {
        lp1 = runtime.longpressExit1();
        runtime.longpressDelayedkey2 = 0;
        runtime.longpressDelayedkey3 = runtime.ITM_CLRMOD;
    } else if ((runtime.calcMode == runtime.CM_NORMAL or runtime.calcMode == runtime.CM_NIM) and result.* == runtime.ITM_DRG) {
        lp1 = 0;
        runtime.longpressDelayedkey2 = 0;
        runtime.longpressDelayedkey3 = 0;
        if (tmpp_ == runtime.ITM_DRG) {
            if (runtime.LongPressM == runtime.RBX_M14) {
                lp1 = if (tmpf == runtime.ITM_USERMODE and runtime.getSystemFlag(runtime.FLAG_SH_LONGPRESS)) runtime.ITM_USERMODE else 0;
            } else if (runtime.LongPressM == runtime.RBX_M124) {
                lp1 = runtime.ITM_USERMODE;
            } else if (runtime.LongPressM == runtime.RBX_M1234) {
                lp1 = runtime.ITM_USERMODE;
                runtime.longpressDelayedkey3 = tmpg;
            }
        }
    } else {
        switch (runtime.calcMode) {
            runtime.CM_NIM => {
                if (result.* == runtime.ITM_BACKSPACE and runtime.tam.mode == 0) {
                    lp1 = runtime.ITM_CLN;
                }
            },
            runtime.CM_AIM => switch (result.*) {
                runtime.ITM_BACKSPACE => {
                    if (runtime.tam.mode == 0) {
                        lp1 = runtime.ITM_CLA;
                        runtime.longpressDelayedkey2 = 0;
                        runtime.longpressDelayedkey3 = runtime.ITM_EDIT;
                    }
                },
                runtime.ITM_EXIT1 => {
                    lp1 = -runtime.MNU_MyAlpha;
                    runtime.longpressDelayedkey2 = 0;
                    runtime.longpressDelayedkey3 = runtime.ITM_CLRMOD;
                },
                runtime.ITM_ENTER => {
                    if (runtime.tam.mode == 0) {
                        lp1 = runtime.ITM_XEDIT;
                        runtime.longpressDelayedkey2 = 0;
                        runtime.longpressDelayedkey3 = runtime.ITM_CR;
                    }
                },
                else => {},
            },
            runtime.CM_EIM => switch (result.*) {
                runtime.ITM_BACKSPACE => {
                    if (runtime.tam.mode == 0) {
                        lp1 = runtime.ITM_CLA;
                        runtime.longpressDelayedkey3 = runtime.ITM_EDIT;
                    }
                },
                runtime.ITM_EXIT1 => {
                    lp1 = -runtime.MNU_MyAlpha;
                    runtime.longpressDelayedkey2 = 0;
                    runtime.longpressDelayedkey3 = runtime.ITM_CLRMOD;
                },
                runtime.ITM_ENTER => {
                    if (runtime.tam.mode == 0) {
                        lp1 = runtime.ITM_XEDIT;
                        runtime.longpressDelayedkey2 = 0;
                        runtime.longpressDelayedkey3 = runtime.ITM_CR;
                    }
                },
                else => {},
            },
            runtime.CM_PEM => switch (result.*) {
                runtime.ITM_BACKSPACE => {
                    lp1 = runtime.ITM_EDIT;
                },
                runtime.ITM_EXIT1 => {
                    lp1 = -runtime.MNU_PFN;
                    runtime.longpressDelayedkey2 = runtime.longpressExit1();
                    runtime.longpressDelayedkey3 = runtime.ITM_CLRMOD;
                },
                else => {},
            },
            else => switch (result.*) {
                runtime.ITM_EXIT1 => {
                    if (runtime.calcModel == runtime.USER_C47) {
                        lp1 = runtime.ITM_CLRMOD;
                        runtime.longpressDelayedkey2 = 0;
                        runtime.longpressDelayedkey3 = 0;
                    } else {
                        lp1 = runtime.ITM_SNAP;
                        runtime.longpressDelayedkey2 = 0;
                        runtime.longpressDelayedkey3 = runtime.ITM_CLRMOD;
                    }
                },
                else => {},
            },
        }
    }

    if (runtime.calcMode == runtime.CM_NIM) {
        const lp2 = runtime.longpressDelayedkey2;
        const lp3 = runtime.longpressDelayedkey3;
        if ((result.* == runtime.ITM_ms or lp1 == runtime.ITM_ms or lp2 == runtime.ITM_ms or lp3 == runtime.ITM_ms) or
            (result.* == runtime.ITM_CC or lp1 == runtime.ITM_CC or lp2 == runtime.ITM_CC or lp3 == runtime.ITM_CC) or
            (result.* == runtime.ITM_dotD or lp1 == runtime.ITM_dotD or lp2 == runtime.ITM_dotD or lp3 == runtime.ITM_dotD) or
            (result.* == runtime.ITM_HASH_JM or lp1 == runtime.ITM_HASH_JM or lp2 == runtime.ITM_HASH_JM or lp3 == runtime.ITM_HASH_JM) or
            (result.* == runtime.ITM_toINT or lp1 == runtime.ITM_toINT or lp2 == runtime.ITM_toINT or lp3 == runtime.ITM_toINT) or
            (result.* == runtime.ITM_op_j or lp1 == runtime.ITM_op_j or lp2 == runtime.ITM_op_j or lp3 == runtime.ITM_op_j) or
            (result.* == runtime.ITM_op_j_pol or lp1 == runtime.ITM_op_j_pol or lp2 == runtime.ITM_op_j_pol or lp3 == runtime.ITM_op_j_pol))
        {
            runtime.delayCloseNim = true;
        }
    }

    if (lp1 != 0) {
        runtime.JM_auto_longpress_enabled = lp1;
        runtime.fnTimerStart(runtime.TO_CL_LONG, @intCast(runtime.TO_CL_LONG), runtime.JM_TO_CL_LONG);
        if (runtime.JM_auto_doublepress_autodrop_enabled != 0) {
            runtime.hideFunctionName();
            runtime.showFunctionName(runtime.JM_auto_doublepress_autodrop_enabled, runtime.FUNCTION_NOPTIME, "SF:M");
            result.* = runtime.JM_auto_doublepress_autodrop_enabled;
            runtime.fnTimerStop(runtime.TO_CL_DROP);
            runtime.setSystemFlag(runtime.FLAG_ASLIFT);
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
