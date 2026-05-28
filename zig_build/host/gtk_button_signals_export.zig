pub export fn z47_btnPressed_signal(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    btnPressed(widget, event, data);
    return 0;
}

pub export fn z47_btnReleased_signal(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    btnReleased(widget, event, data);
    return 0;
}

extern fn btnPressed(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) void;
extern fn btnReleased(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) void;
