const gtk_decls = @import("gtk_gui_host_decls.zig");
const GtkWidget = gtk_decls.GtkWidget;
const GdkRectangle = gtk_decls.GdkRectangle;
const gdk_display_get_default = gtk_decls.gdk_display_get_default;
const gdk_display_get_monitor = gtk_decls.gdk_display_get_monitor;
const gdk_monitor_get_geometry = gtk_decls.gdk_monitor_get_geometry;
const gtk_window_new = gtk_decls.gtk_window_new;
const gtk_window_set_default_size = gtk_decls.gtk_window_set_default_size;
const gtk_widget_set_name = gtk_decls.gtk_widget_set_name;
const gtk_window_set_resizable = gtk_decls.gtk_window_set_resizable;
const gtk_window_set_title = gtk_decls.gtk_window_set_title;
const g_signal_connect_data = gtk_decls.g_signal_connect_data;
const gtk_window_set_decorated = gtk_decls.gtk_window_set_decorated;
const gtk_window_set_position = gtk_decls.gtk_window_set_position;
const gtk_widget_add_events = gtk_decls.gtk_widget_add_events;
const gtk_fixed_new = gtk_decls.gtk_fixed_new;
const gtk_container_add = gtk_decls.gtk_container_add;

const USER_R47f_g: u8 = 61;
const USER_R47bk_fg: u8 = 62;
const USER_R47fg_bk: u8 = 63;
const USER_R47fg_g: u8 = 64;
const GTK_WINDOW_TOPLEVEL: c_int = 0;
const GTK_WIN_POS_CENTER: c_int = 1;
const GDK_CONFIGURE: c_int = 13;
const BIG_SCREEN_COEF: c_int = 1;
const NARROW_SCREEN: bool = false;

extern var calcModel: u8;
extern var calcAutoLandscapePortrait: bool;
extern var calcLandscape: bool;
extern var frmCalc: ?*GtkWidget;
extern var grid: ?*GtkWidget;

extern fn z47_destroyCalc(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int;
extern fn z47_keyPressed_wrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int;
extern fn z47_keyReleased_wrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int;
extern fn z47_onConfigureEvent(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int;
extern fn z47_onUIActivity(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int;

fn isR47FAM() bool {
    return calcModel == USER_R47f_g or calcModel == USER_R47bk_fg or calcModel == USER_R47fg_bk or calcModel == USER_R47fg_g;
}

pub fn configureWindowLayout() void {
    var monitor: GdkRectangle = undefined;
    gdk_monitor_get_geometry(gdk_display_get_monitor(gdk_display_get_default(), 0), &monitor);
    if (calcAutoLandscapePortrait) {
        calcLandscape = monitor.height < 1025;
    }

    frmCalc = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    if (calcLandscape) {
        gtk_window_set_default_size(@ptrCast(frmCalc), 1000, 540);
    } else if (NARROW_SCREEN) {
        gtk_window_set_default_size(@ptrCast(frmCalc), 400, 862);
    } else {
        gtk_window_set_default_size(@ptrCast(frmCalc), 526, 980);
    }

    gtk_widget_set_name(frmCalc, "mainWindow");
    gtk_window_set_resizable(@ptrCast(frmCalc), 0);
    gtk_window_set_title(@ptrCast(frmCalc), if (isR47FAM()) "R47" else "C47");
    _ = g_signal_connect_data(frmCalc, "destroy", @ptrCast(&z47_destroyCalc), null, null, 0);
    _ = g_signal_connect_data(frmCalc, "key_press_event", @ptrCast(&z47_keyPressed_wrapper), null, null, 0);
    _ = g_signal_connect_data(frmCalc, "key_release_event", @ptrCast(&z47_keyReleased_wrapper), null, null, 0);
    _ = g_signal_connect_data(frmCalc, "configure-event", @ptrCast(&z47_onConfigureEvent), null, null, 0);
    _ = g_signal_connect_data(frmCalc, "configure-event", @ptrCast(&z47_onUIActivity), null, null, 0);
    _ = g_signal_connect_data(frmCalc, "button-press-event", @ptrCast(&z47_onUIActivity), null, null, 0);
    _ = g_signal_connect_data(frmCalc, "focus-in-event", @ptrCast(&z47_onUIActivity), null, null, 0);
    _ = g_signal_connect_data(frmCalc, "focus-out-event", @ptrCast(&z47_onUIActivity), null, null, 0);

    if (BIG_SCREEN_COEF > 1 or NARROW_SCREEN) {
        gtk_window_set_decorated(@ptrCast(frmCalc), 0);
        gtk_window_set_position(@ptrCast(frmCalc), GTK_WIN_POS_CENTER);
    }

    gtk_widget_add_events(frmCalc, GDK_CONFIGURE);
    grid = gtk_fixed_new();
    gtk_container_add(@ptrCast(frmCalc), grid);
}
