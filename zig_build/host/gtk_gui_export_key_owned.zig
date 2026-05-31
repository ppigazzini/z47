const key_wrapper_owned = @import("gtk_gui_key_wrapper_owned.zig");

pub fn keyPressedWrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int {
    return key_wrapper_owned.keyPressedWrapper(widget, event, data);
}

pub fn keyReleasedWrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int {
    return key_wrapper_owned.keyReleasedWrapper(widget, event, data);
}

pub fn keyPressedImpl(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int {
    return key_wrapper_owned.keyPressedImpl(widget, event, data);
}

pub fn keyReleasedImpl(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int {
    return key_wrapper_owned.keyReleasedImpl(widget, event, data);
}
