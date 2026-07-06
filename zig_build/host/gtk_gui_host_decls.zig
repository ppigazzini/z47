pub const GtkWidget = opaque {};
pub const GtkDisplay = opaque {};
pub const GdkMonitor = opaque {};

pub const GdkRectangle = extern struct {
    x: c_int,
    y: c_int,
    width: c_int,
    height: c_int,
};

pub extern fn gdk_display_get_default() ?*GtkDisplay;
pub extern fn gdk_display_get_monitor(display: ?*GtkDisplay, monitor_num: c_int) ?*GdkMonitor;
pub extern fn gdk_monitor_get_geometry(monitor: ?*GdkMonitor, geometry: *GdkRectangle) void;

pub extern fn gtk_window_new(window_type: c_int) ?*GtkWidget;
pub extern fn gtk_window_set_default_size(window: ?*GtkWidget, width: c_int, height: c_int) void;
pub extern fn gtk_widget_set_name(widget: ?*GtkWidget, name: [*:0]const u8) void;
pub extern fn gtk_window_set_resizable(window: ?*GtkWidget, resizable: c_int) void;
pub extern fn gtk_window_set_title(window: ?*GtkWidget, title: [*:0]const u8) void;
pub extern fn gtk_window_set_decorated(window: ?*GtkWidget, setting: c_int) void;
pub extern fn gtk_window_set_position(window: ?*GtkWidget, position: c_int) void;
pub extern fn gtk_widget_add_events(widget: ?*GtkWidget, events: c_int) void;

pub extern fn gtk_fixed_new() ?*GtkWidget;
pub extern fn gtk_container_add(container: ?*GtkWidget, widget: ?*GtkWidget) void;
pub extern fn gtk_image_new_from_file(filename: [*:0]const u8) ?*GtkWidget;
pub extern fn gtk_fixed_put(fixed: ?*GtkWidget, widget: ?*GtkWidget, x: c_int, y: c_int) void;
pub extern fn gtk_label_new(str: [*:0]const u8) ?*GtkWidget;
pub extern fn gtk_widget_set_size_request(widget: ?*GtkWidget, width: c_int, height: c_int) void;
pub extern fn gtk_drawing_area_new() ?*GtkWidget;
pub extern fn gtk_widget_set_tooltip_text(widget: ?*GtkWidget, text: [*:0]const u8) void;

pub extern fn g_signal_connect_data(instance: ?*anyopaque, detailed_signal: [*:0]const u8, c_handler: ?*const anyopaque, data: ?*anyopaque, destroy_data: ?*const anyopaque, connect_flags: c_int) c_ulong;
