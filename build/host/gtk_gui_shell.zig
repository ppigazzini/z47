const gtk_decls = @import("gtk_gui_host_decls.zig");
const GtkWidget = gtk_decls.GtkWidget;
const gtk_window_new = gtk_decls.gtk_window_new;
const gtk_window_set_default_size = gtk_decls.gtk_window_set_default_size;
const gtk_window_set_decorated = gtk_decls.gtk_window_set_decorated;
const gtk_window_set_position = gtk_decls.gtk_window_set_position;
const gtk_widget_set_name = gtk_decls.gtk_widget_set_name;
const gtk_window_set_resizable = gtk_decls.gtk_window_set_resizable;
const g_signal_connect_data = gtk_decls.g_signal_connect_data;
const gtk_widget_add_events = gtk_decls.gtk_widget_add_events;
const gtk_fixed_new = gtk_decls.gtk_fixed_new;
const gtk_container_add = gtk_decls.gtk_container_add;
const gtk_drawing_area_new = gtk_decls.gtk_drawing_area_new;
const gtk_widget_set_size_request = gtk_decls.gtk_widget_set_size_request;
const gtk_fixed_put = gtk_decls.gtk_fixed_put;

const GTK_WINDOW_TOPLEVEL: c_int = 0;
const GTK_WIN_POS_CENTER: c_int = 1;
const GDK_CONFIGURE: c_int = 13;
const CAIRO_FORMAT_RGB24: c_int = 1;
const SCREEN_WIDTH: c_int = 400;
const SCREEN_HEIGHT: c_int = 240;
const BIG_SCREEN_COEF: c_int = 1;

extern var frmCalc: ?*GtkWidget;
extern var screen: ?*GtkWidget;
extern var grid: ?*GtkWidget;
extern var screenStride: i16;
extern var screenData: [*]u32;

extern fn z47_destroyCalc(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int;
extern fn z47_keyPressed_wrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int;
extern fn z47_keyReleased_wrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int;
extern fn z47_drawScreen_wrapper(widget: ?*anyopaque, cr: ?*anyopaque, data: ?*anyopaque) c_int;
extern fn cairo_format_stride_for_width(format: c_int, width: c_int) c_int;
extern fn malloc(size: usize) ?*anyopaque;
extern fn exit(code: c_int) noreturn;
extern fn moreInfoOnError(prefix: [*:0]const u8, message: [*:0]const u8, third: ?[*:0]const u8, fourth: ?[*:0]const u8) void;

pub fn setupShellWindow() void {
    frmCalc = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_default_size(@ptrCast(frmCalc), SCREEN_WIDTH * BIG_SCREEN_COEF, SCREEN_HEIGHT * BIG_SCREEN_COEF);
    gtk_window_set_decorated(@ptrCast(frmCalc), 0);
    gtk_window_set_position(@ptrCast(frmCalc), GTK_WIN_POS_CENTER);

    gtk_widget_set_name(frmCalc, "mainWindow");
    gtk_window_set_resizable(@ptrCast(frmCalc), 0);
}

pub fn wireShellEvents() void {
    _ = g_signal_connect_data(frmCalc, "destroy", @ptrCast(&z47_destroyCalc), null, null, 0);
    _ = g_signal_connect_data(frmCalc, "key_press_event", @ptrCast(&z47_keyPressed_wrapper), null, null, 0);
    _ = g_signal_connect_data(frmCalc, "key_release_event", @ptrCast(&z47_keyReleased_wrapper), null, null, 0);
    gtk_widget_add_events(frmCalc, GDK_CONFIGURE);
}

pub fn setupShellScreen() void {
    grid = gtk_fixed_new();
    gtk_container_add(@ptrCast(frmCalc), grid);

    screen = gtk_drawing_area_new();
    gtk_widget_set_size_request(screen, SCREEN_WIDTH * BIG_SCREEN_COEF, SCREEN_HEIGHT * BIG_SCREEN_COEF);
    gtk_fixed_put(@ptrCast(grid), screen, 0, 0);

    screenStride = @intCast(@divTrunc(cairo_format_stride_for_width(CAIRO_FORMAT_RGB24, SCREEN_WIDTH), 4));
    const num_bytes: usize = @as(usize, @intCast(screenStride)) * SCREEN_HEIGHT * 4;
    const raw = malloc(num_bytes);
    if (raw == null) {
        moreInfoOnError("In function setupUI:", "error allocating screenData", null, null);
        exit(1);
    }
    screenData = @ptrCast(@alignCast(raw.?));

    _ = g_signal_connect_data(screen, "draw", @ptrCast(&z47_drawScreen_wrapper), null, null, 0);
}
