const gtk_decls = @import("gtk_gui_host_decls.zig");
const GtkWidget = gtk_decls.GtkWidget;
const gtk_drawing_area_new = gtk_decls.gtk_drawing_area_new;
const gtk_widget_set_size_request = gtk_decls.gtk_widget_set_size_request;
const gtk_widget_set_tooltip_text = gtk_decls.gtk_widget_set_tooltip_text;
const gtk_fixed_put = gtk_decls.gtk_fixed_put;
const g_signal_connect_data = gtk_decls.g_signal_connect_data;

const CAIRO_FORMAT_RGB24: c_int = 1;
const SCREEN_WIDTH: c_int = 400;
const SCREEN_HEIGHT: c_int = 240;
const NARROW_SCREEN: bool = false;

extern var screen: ?*GtkWidget;
extern var grid: ?*GtkWidget;
extern var screenStride: i16;
extern var screenData: [*]u32;

extern fn cairo_format_stride_for_width(format: c_int, width: c_int) c_int;
extern fn malloc(size: usize) ?*anyopaque;
extern fn exit(code: c_int) noreturn;
extern fn moreInfoOnError(prefix: [*:0]const u8, message: [*:0]const u8, third: ?[*:0]const u8, fourth: ?[*:0]const u8) void;

extern fn z47_drawScreen_wrapper(widget: ?*anyopaque, cr: ?*anyopaque, data: ?*anyopaque) c_int;

pub fn setupScreenBuffer() void {
    screen = gtk_drawing_area_new();
    gtk_widget_set_size_request(screen, SCREEN_WIDTH, SCREEN_HEIGHT);
    gtk_widget_set_tooltip_text(screen, "Copy to clipboard:\n CTRL+h: Screen image\n CTRL+m: Menu image\n CTRL+c/x: X Register\n CTRL+d: Lettered Registers\n CTRL+a: All Registers\nCTRL+s: SNAP\n");
    if (!NARROW_SCREEN) {
        gtk_fixed_put(@ptrCast(grid), screen, 63, 72);
    } else {
        gtk_fixed_put(@ptrCast(grid), screen, 0, 0);
    }

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
