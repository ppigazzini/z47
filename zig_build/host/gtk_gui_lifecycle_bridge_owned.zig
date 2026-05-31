const lifecycle_owned = @import("gtk_gui_lifecycle_owned.zig");

const BridgeRoute = enum {
    destroy,
    configure,
    ui_activity,
};

const BridgeHandler = *const fn (?*anyopaque, ?*anyopaque, ?*anyopaque) c_int;

const BridgeDispatchEntry = struct {
    route: BridgeRoute,
    handler: BridgeHandler,
};

const bridge_dispatch = [_]BridgeDispatchEntry{
    .{ .route = .destroy, .handler = &lifecycle_owned.destroyCalc },
    .{ .route = .configure, .handler = &lifecycle_owned.onConfigureEvent },
    .{ .route = .ui_activity, .handler = &lifecycle_owned.onUiActivity },
};

fn dispatchBridge(comptime route: BridgeRoute, widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int {
    inline for (bridge_dispatch) |entry| {
        if (entry.route == route) {
            return entry.handler(widget, event, data);
        }
    }
    unreachable;
}

pub fn destroyCalc(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int {
    return dispatchBridge(.destroy, widget, event, data);
}

pub fn onConfigureEvent(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int {
    return dispatchBridge(.configure, widget, event, data);
}

pub fn onUiActivity(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int {
    return dispatchBridge(.ui_activity, widget, event, data);
}
