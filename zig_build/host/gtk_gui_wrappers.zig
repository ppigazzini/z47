const tamState_t = extern struct {
    mode: u16,
    function: i16,
    alpha: bool,
    currentOperation: i16,
    dot: bool,
    indirect: bool,
    digitsSoFar: i16,
    value0: i16,
    value: i16,
    min: i16,
    max: i16,
    key: i16,
    keyAlpha: bool,
    keyDot: bool,
    keyIndirect: bool,
    keyInputFinished: bool,
};

const USER_DM42: u8 = 45;
const USER_C47: u8 = 46;
const USER_R47f_g: u8 = 61;
const USER_R47bk_fg: u8 = 62;
const USER_R47fg_bk: u8 = 63;
const USER_R47fg_g: u8 = 64;
const ITM_NULL: i16 = 0;
const ITM_SIGMAPLUS: i16 = 433;
const FLAG_ALPHA: u16 = 0x800e;
const FLAG_NUMLOCK: u16 = 0x8043;
const CM_NORMAL: u8 = 0;
const CM_NIM: u8 = 2;
const CM_PEM: u8 = 3;
const CM_AIM: u8 = 1;
const CM_EIM: u8 = 13;
const CM_TIMER: u8 = 14;
const TI_NO_INFO: u8 = 0;
const SCRUPD_AUTO: u8 = 0x00;

extern var calcModel: u8;
extern var calcMode: u8;
extern var catalog: i16;
extern var temporaryInformation: u8;
extern var screenUpdatingMode: u8;
extern var shiftF: bool;
extern var shiftG: bool;
extern var tam: tamState_t;

extern fn btnClicked(widget: ?*anyopaque, data: [*:0]const u8) void;
extern fn refreshStatusBar() void;
extern fn showHideAlphaMode() void;
extern fn processAimInput(item: i16) void;
extern fn pemAlpha(item: i16) void;
extern fn clearSystemFlag(flag: u16) void;
extern fn setSystemFlag(flag: u16) void;
extern fn getSystemFlag(flag: u16) bool;
extern fn Check_Norm_Key_00_Assigned(result: *i16, tempkey: i16) i16;

fn normKey00ItemInLayout() i16 {
    return switch (calcModel) {
        USER_C47, USER_DM42 => ITM_SIGMAPLUS,
        USER_R47f_g => -1,
        USER_R47bk_fg, USER_R47fg_bk => ITM_NULL,
        USER_R47fg_g => ITM_NULL,
        else => -1,
    };
}

pub export fn btnClicked_NU(widget: ?*anyopaque, data: ?*anyopaque) callconv(.c) void {
    const numLockMem = getSystemFlag(FLAG_NUMLOCK);

    clearSystemFlag(FLAG_NUMLOCK);
    shiftF = false;
    shiftG = true;
    if (data) |raw_data| {
        btnClicked(widget, @as([*:0]const u8, @ptrCast(raw_data)));
    }

    if (numLockMem) {
        setSystemFlag(FLAG_NUMLOCK);
    } else {
        clearSystemFlag(FLAG_NUMLOCK);
    }
    refreshStatusBar();
}

pub export fn sendKey(sent: i16) callconv(.c) void {
    showHideAlphaMode();
    if (calcMode == CM_PEM and tam.mode == 0 and getSystemFlag(FLAG_ALPHA) and catalog == 0) {
        pemAlpha(sent);
    } else {
        processAimInput(sent);
    }
}

pub export fn checkNormal(keyNr: i16, item: i16) callconv(.c) bool {
    var result: i16 = normKey00ItemInLayout();
    const ss = Check_Norm_Key_00_Assigned(&result, keyNr);
    return ss == item;
}

pub export fn z47_btnFnPressed_wrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    btnFnPressed(widget, event, data);
    return 0;
}

pub export fn z47_btnFnReleased_wrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    btnFnReleased(widget, event, data);
    return 0;
}

pub export fn z47_keyPressed_wrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return z47_keyPressed_impl(widget, event, data);
}

pub export fn z47_keyReleased_wrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return z47_keyReleased_impl(widget, event, data);
}

pub export fn z47_drawScreen_wrapper(widget: ?*anyopaque, cr: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return drawScreen(widget, cr, data);
}

pub export fn z47_destroyCalc(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    _ = widget;
    _ = event;
    _ = data;

    fnStopTimerApp();
    saveCalc();
    gtk_main_quit();
    return 0;
}

pub export fn z47_onConfigureEvent(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    _ = event;
    _ = data;

    gtk_widget_queue_draw(widget);
    return 0;
}

var ui_settle_timer: c_uint = 0;
var first_call_time_us: i64 = 0;

fn z47_clear_ui_active_flag(data: ?*anyopaque) callconv(.c) c_int {
    _ = data;
    ui_is_active = 0;
    ui_settle_timer = 0;
    return 0;
}

pub export fn z47_onUIActivity(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    _ = widget;
    _ = event;
    _ = data;

    if (first_call_time_us == 0) {
        first_call_time_us = g_get_monotonic_time();
    }

    if ((g_get_monotonic_time() - first_call_time_us) < 500000) {
        return 0;
    }

    ui_is_active = 1;
    if (ui_settle_timer != 0) {
        _ = g_source_remove(ui_settle_timer);
    }
    ui_settle_timer = g_timeout_add(100, z47_clear_ui_active_flag, null);
    return 0;
}

extern fn btnFnPressed(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) void;
extern fn btnFnReleased(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) void;
extern fn z47_keyPressed_impl(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int;
extern fn z47_keyReleased_impl(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int;
extern fn drawScreen(widget: ?*anyopaque, cr: ?*anyopaque, data: ?*anyopaque) c_int;
extern fn fnStopTimerApp() void;
extern fn saveCalc() void;
extern fn gtk_main_quit() void;
extern fn gtk_widget_queue_draw(widget: ?*anyopaque) void;
extern fn g_get_monotonic_time() i64;
extern fn g_source_remove(tag: c_uint) c_int;
extern fn g_timeout_add(interval: c_uint, function: *const fn (?*anyopaque) callconv(.c) c_int, data: ?*anyopaque) c_uint;
extern var ui_is_active: c_int;
