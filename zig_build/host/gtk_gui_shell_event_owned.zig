const gtk_decls = @import("gtk_gui_host_decls.zig");
const GtkWidget = gtk_decls.GtkWidget;
const g_signal_connect_data = gtk_decls.g_signal_connect_data;
const gtk_widget_add_events = gtk_decls.gtk_widget_add_events;

const GDK_CONFIGURE: c_int = 13;

extern var frmCalc: ?*GtkWidget;

extern fn z47_destroyCalc(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int;
extern fn z47_keyPressed_wrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int;
extern fn z47_keyReleased_wrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int;

pub fn wireShellEvents() void {
    _ = g_signal_connect_data(frmCalc, "destroy", @ptrCast(&z47_destroyCalc), null, null, 0);
    _ = g_signal_connect_data(frmCalc, "key_press_event", @ptrCast(&z47_keyPressed_wrapper), null, null, 0);
    _ = g_signal_connect_data(frmCalc, "key_release_event", @ptrCast(&z47_keyReleased_wrapper), null, null, 0);
    gtk_widget_add_events(frmCalc, GDK_CONFIGURE);
}
