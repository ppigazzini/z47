const callback_button_owned = @import("gtk_gui_callback_button_owned.zig");

extern fn drawScreen(widget: ?*anyopaque, cr: ?*anyopaque, data: ?*anyopaque) c_int;

pub fn btnFnPressedWrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int {
    return callback_button_owned.btnFnPressedWrapper(widget, event, data);
}

pub fn btnFnReleasedWrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int {
    return callback_button_owned.btnFnReleasedWrapper(widget, event, data);
}

pub fn drawScreenWrapper(widget: ?*anyopaque, cr: ?*anyopaque, data: ?*anyopaque) c_int {
    return drawScreen(widget, cr, data);
}
