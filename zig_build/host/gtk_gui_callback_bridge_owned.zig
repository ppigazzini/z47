const callback_button_owned = @import("gtk_gui_callback_button_owned.zig");
const callback_draw_owned = @import("gtk_gui_callback_draw_owned.zig");

const BridgeRoute = enum {
    btn_pressed,
    btn_released,
    draw_screen,
};

const BridgeHandler = *const fn (?*anyopaque, ?*anyopaque, ?*anyopaque) c_int;

const BridgeDispatchEntry = struct {
    route: BridgeRoute,
    handler: BridgeHandler,
};

const bridge_dispatch = [_]BridgeDispatchEntry{
    .{ .route = .btn_pressed, .handler = &callback_button_owned.btnFnPressedWrapper },
    .{ .route = .btn_released, .handler = &callback_button_owned.btnFnReleasedWrapper },
    .{ .route = .draw_screen, .handler = &callback_draw_owned.drawScreenWrapper },
};

fn dispatchBridge(comptime route: BridgeRoute, widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int {
    inline for (bridge_dispatch) |entry| {
        if (entry.route == route) {
            return entry.handler(widget, event, data);
        }
    }
    unreachable;
}

pub fn btnFnPressedWrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int {
    return dispatchBridge(.btn_pressed, widget, event, data);
}

pub fn btnFnReleasedWrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int {
    return dispatchBridge(.btn_released, widget, event, data);
}

pub fn drawScreenWrapper(widget: ?*anyopaque, cr: ?*anyopaque, data: ?*anyopaque) c_int {
    return dispatchBridge(.draw_screen, widget, cr, data);
}
