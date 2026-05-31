const gtk_decls = @import("gtk_gui_host_decls.zig");
const GtkWidget = gtk_decls.GtkWidget;
const gtk_fixed_new = gtk_decls.gtk_fixed_new;
const gtk_container_add = gtk_decls.gtk_container_add;
const gtk_drawing_area_new = gtk_decls.gtk_drawing_area_new;
const gtk_widget_set_size_request = gtk_decls.gtk_widget_set_size_request;
const gtk_fixed_put = gtk_decls.gtk_fixed_put;
const g_signal_connect_data = gtk_decls.g_signal_connect_data;

const CAIRO_FORMAT_RGB24: c_int = 1;
const SCREEN_WIDTH: c_int = 400;
const SCREEN_HEIGHT: c_int = 240;
const BIG_SCREEN_COEF: c_int = 1;

extern var frmCalc: ?*GtkWidget;
extern var screen: ?*GtkWidget;
extern var grid: ?*GtkWidget;
extern var screenStride: i16;
extern var screenData: [*]u32;
extern fn cairo_format_stride_for_width(format: c_int, width: c_int) c_int;
extern fn malloc(size: usize) ?*anyopaque;
extern fn exit(code: c_int) noreturn;
extern fn moreInfoOnError(prefix: [*:0]const u8, message: [*:0]const u8, third: ?[*:0]const u8, fourth: ?[*:0]const u8) void;

extern fn z47_drawScreen_wrapper(widget: ?*anyopaque, cr: ?*anyopaque, data: ?*anyopaque) c_int;

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
