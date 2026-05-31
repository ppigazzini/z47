const GtkWidget = opaque {};
const shell_window_owned = @import("gtk_gui_shell_window_owned.zig");
const shell_event_owned = @import("gtk_gui_shell_event_owned.zig");

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

extern fn gtk_window_new(window_type: c_int) ?*GtkWidget;
extern fn gtk_window_set_default_size(window: ?*GtkWidget, width: c_int, height: c_int) void;
extern fn gtk_window_set_decorated(window: ?*GtkWidget, setting: c_int) void;
extern fn gtk_window_set_position(window: ?*GtkWidget, position: c_int) void;
extern fn gtk_widget_set_name(widget: ?*GtkWidget, name: [*:0]const u8) void;
extern fn gtk_window_set_resizable(window: ?*GtkWidget, resizable: c_int) void;
extern fn g_signal_connect_data(instance: ?*anyopaque, detailed_signal: [*:0]const u8, c_handler: ?*const anyopaque, data: ?*anyopaque, destroy_data: ?*const anyopaque, connect_flags: c_int) c_ulong;
extern fn gtk_widget_add_events(widget: ?*GtkWidget, events: c_int) void;
extern fn gtk_fixed_new() ?*GtkWidget;
extern fn gtk_container_add(container: ?*GtkWidget, widget: ?*GtkWidget) void;
extern fn gtk_drawing_area_new() ?*GtkWidget;
extern fn gtk_widget_set_size_request(widget: ?*GtkWidget, width: c_int, height: c_int) void;
extern fn gtk_fixed_put(fixed: ?*GtkWidget, widget: ?*GtkWidget, x: c_int, y: c_int) void;
extern fn cairo_format_stride_for_width(format: c_int, width: c_int) c_int;
extern fn malloc(size: usize) ?*anyopaque;
extern fn exit(code: c_int) noreturn;
extern fn moreInfoOnError(prefix: [*:0]const u8, message: [*:0]const u8, third: ?[*:0]const u8, fourth: ?[*:0]const u8) void;

extern fn z47_destroyCalc(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int;
extern fn z47_keyPressed_wrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int;
extern fn z47_keyReleased_wrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int;
extern fn z47_drawScreen_wrapper(widget: ?*anyopaque, cr: ?*anyopaque, data: ?*anyopaque) c_int;

pub fn setupUiNoKeyboardShell() void {
    shell_window_owned.setupShellWindow();
    shell_event_owned.wireShellEvents();

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
