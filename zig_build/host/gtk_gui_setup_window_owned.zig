const GtkWidget = opaque {};
const GtkDisplay = opaque {};
const GdkMonitor = opaque {};

const GdkRectangle = extern struct {
    x: c_int,
    y: c_int,
    width: c_int,
    height: c_int,
};

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

extern fn gdk_display_get_default() ?*GtkDisplay;
extern fn gdk_display_get_monitor(display: ?*GtkDisplay, monitor_num: c_int) ?*GdkMonitor;
extern fn gdk_monitor_get_geometry(monitor: ?*GdkMonitor, geometry: *GdkRectangle) void;
extern fn gtk_window_new(window_type: c_int) ?*GtkWidget;
extern fn gtk_window_set_default_size(window: ?*GtkWidget, width: c_int, height: c_int) void;
extern fn gtk_widget_set_name(widget: ?*GtkWidget, name: [*:0]const u8) void;
extern fn gtk_window_set_resizable(window: ?*GtkWidget, resizable: c_int) void;
extern fn gtk_window_set_title(window: ?*GtkWidget, title: [*:0]const u8) void;
extern fn g_signal_connect_data(instance: ?*anyopaque, detailed_signal: [*:0]const u8, c_handler: ?*const anyopaque, data: ?*anyopaque, destroy_data: ?*const anyopaque, connect_flags: c_int) c_ulong;
extern fn gtk_window_set_decorated(window: ?*GtkWidget, setting: c_int) void;
extern fn gtk_window_set_position(window: ?*GtkWidget, position: c_int) void;
extern fn gtk_widget_add_events(widget: ?*GtkWidget, events: c_int) void;
extern fn gtk_fixed_new() ?*GtkWidget;
extern fn gtk_container_add(container: ?*GtkWidget, widget: ?*GtkWidget) void;

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
