const lifecycle_owned = @import("gtk_gui_lifecycle_owned.zig");

pub fn destroyCalc(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int {
    return lifecycle_owned.destroyCalc(widget, event, data);
}

pub fn onConfigureEvent(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int {
    return lifecycle_owned.onConfigureEvent(widget, event, data);
}

pub fn onUiActivity(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int {
    return lifecycle_owned.onUiActivity(widget, event, data);
}
