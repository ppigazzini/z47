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

extern fn btnFnPressed(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) void;
extern fn btnFnReleased(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) void;
extern fn fnStopTimerApp() void;
extern fn saveCalc() void;
extern fn gtk_main_quit() void;
extern fn gtk_widget_queue_draw(widget: ?*anyopaque) void;
