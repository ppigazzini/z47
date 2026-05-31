const key_event_owned = @import("gtk_gui_key_event_owned.zig");

pub fn keyPressedWrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int {
    return keyPressedImpl(widget, event, data);
}

pub fn keyReleasedWrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int {
    return keyReleasedImpl(widget, event, data);
}

pub fn keyPressedImpl(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int {
    return key_event_owned.keyPressedImpl(widget, event, data);
}

pub fn keyReleasedImpl(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int {
    return key_event_owned.keyReleasedImpl(widget, event, data);
}
