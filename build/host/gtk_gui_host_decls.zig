// SPDX-License-Identifier: GPL-3.0-only
pub const GtkWidget = opaque {};
pub const GtkDisplay = opaque {};
pub const GdkMonitor = opaque {};

pub const GdkRectangle = extern struct {
    x: c_int,
    y: c_int,
    width: c_int,
    height: c_int,
};

// The leading fields of GdkEventKey, as far as keyval: the key handlers read the
// event through GTK's pointer and never copy it.
pub const GdkEventKey = extern struct {
    type: c_int,
    window: ?*anyopaque,
    send_event: i8,
    time: u32,
    state: c_uint,
    keyval: c_uint,
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

// GLib never writes through `data`, only hands it back to the handler, so it is
// bound const and takes the key strings the keyboard connects. Any function
// pointer coerces to `c_handler`.
pub extern fn g_signal_connect_data(instance: ?*anyopaque, detailed_signal: [*:0]const u8, c_handler: ?*const anyopaque, data: ?*const anyopaque, destroy_data: ?*const anyopaque, connect_flags: c_int) c_ulong;
