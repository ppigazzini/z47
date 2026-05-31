const callback_bridge_owned = @import("gtk_gui_callback_bridge_owned.zig");

pub fn btnFnPressedWrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int {
    return callback_bridge_owned.btnFnPressedWrapper(widget, event, data);
}

pub fn btnFnReleasedWrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int {
    return callback_bridge_owned.btnFnReleasedWrapper(widget, event, data);
}

pub fn drawScreenWrapper(widget: ?*anyopaque, cr: ?*anyopaque, data: ?*anyopaque) c_int {
    return callback_bridge_owned.drawScreenWrapper(widget, cr, data);
}
