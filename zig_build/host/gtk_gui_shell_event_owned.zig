const GtkWidget = opaque {};

const GDK_CONFIGURE: c_int = 13;

extern var frmCalc: ?*GtkWidget;

extern fn g_signal_connect_data(instance: ?*anyopaque, detailed_signal: [*:0]const u8, c_handler: ?*const anyopaque, data: ?*anyopaque, destroy_data: ?*const anyopaque, connect_flags: c_int) c_ulong;
extern fn gtk_widget_add_events(widget: ?*GtkWidget, events: c_int) void;

extern fn z47_destroyCalc(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int;
extern fn z47_keyPressed_wrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int;
extern fn z47_keyReleased_wrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int;

pub fn wireShellEvents() void {
    _ = g_signal_connect_data(frmCalc, "destroy", @ptrCast(&z47_destroyCalc), null, null, 0);
    _ = g_signal_connect_data(frmCalc, "key_press_event", @ptrCast(&z47_keyPressed_wrapper), null, null, 0);
    _ = g_signal_connect_data(frmCalc, "key_release_event", @ptrCast(&z47_keyReleased_wrapper), null, null, 0);
    gtk_widget_add_events(frmCalc, GDK_CONFIGURE);
}
