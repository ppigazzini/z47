pub export fn z47_btnFnPressed_wrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    btnFnPressed(widget, event, data);
    return 0;
}

pub export fn z47_btnFnReleased_wrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    btnFnReleased(widget, event, data);
    return 0;
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
extern fn fnStopTimerApp() void;
extern fn saveCalc() void;
extern fn gtk_main_quit() void;
extern fn gtk_widget_queue_draw(widget: ?*anyopaque) void;
extern fn g_get_monotonic_time() i64;
extern fn g_source_remove(tag: c_uint) c_int;
extern fn g_timeout_add(interval: c_uint, function: *const fn (?*anyopaque) callconv(.c) c_int, data: ?*anyopaque) c_uint;
extern var ui_is_active: c_int;
