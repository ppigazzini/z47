const callback_button_owned = @import("gtk_gui_callback_button_owned.zig");
const callback_draw_owned = @import("gtk_gui_callback_draw_owned.zig");

pub fn btnFnPressedWrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int {
    return callback_button_owned.btnFnPressedWrapper(widget, event, data);
}

pub fn btnFnReleasedWrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int {
    return callback_button_owned.btnFnReleasedWrapper(widget, event, data);
}

pub fn drawScreenWrapper(widget: ?*anyopaque, cr: ?*anyopaque, data: ?*anyopaque) c_int {
    return callback_draw_owned.drawScreenWrapper(widget, cr, data);
}
