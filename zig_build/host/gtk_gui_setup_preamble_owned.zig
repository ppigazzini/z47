const GtkWidget = opaque {};
const GtkCssProvider = opaque {};
const GtkStyleProvider = opaque {};
const GtkDisplay = opaque {};
const GdkScreen = opaque {};
const GdkMonitor = opaque {};
const setup_background_owned = @import("gtk_gui_setup_background_owned.zig");
const setup_window_owned = @import("gtk_gui_setup_window_owned.zig");
const setup_softkey_owned = @import("gtk_gui_setup_softkey_owned.zig");
const setup_screen_owned = @import("gtk_gui_setup_screen_owned.zig");

const GdkRectangle = extern struct {
    x: c_int,
    y: c_int,
    width: c_int,
    height: c_int,
};

const calcKey_t = extern struct {
    keyId: i16,
    primary: i16,
    fShifted: i16,
    gShifted: i16,
    keyLblAim: i16,
    primaryAim: i16,
    fShiftedAim: i16,
    gShiftedAim: i16,
    primaryTam: i16,
};

const USER_R47f_g: u8 = 61;
const USER_R47bk_fg: u8 = 62;
const USER_R47fg_bk: u8 = 63;
const USER_R47fg_g: u8 = 64;
const ITM_SHIFTf: i16 = 1731;
const ITM_SHIFTg: i16 = 1732;
const GTK_WINDOW_TOPLEVEL: c_int = 0;
const GTK_WIN_POS_CENTER: c_int = 1;
const GDK_CONFIGURE: c_int = 13;
const CAIRO_FORMAT_RGB24: c_int = 1;
const SCREEN_WIDTH: c_int = 400;
const SCREEN_HEIGHT: c_int = 240;
const BIG_SCREEN_COEF: c_int = 1;
const DELTA_KEYS_X: c_int = 78;
const NARROW_SCREEN: bool = false;

extern var calcModel: u8;
extern var calcAutoLandscapePortrait: bool;
extern var calcLandscape: bool;
extern var modelString: [50]u8;
extern var screenStride: i16;
extern var screenData: [*]u32;
extern var frmCalc: ?*GtkWidget;
extern var screen: ?*GtkWidget;
extern var grid: ?*GtkWidget;
extern var backgroundImage: ?*GtkWidget;
extern var lblFKey2: ?*GtkWidget;
extern var lblGKey2: ?*GtkWidget;
extern var kbd_usr: [37]calcKey_t;

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
extern fn gtk_image_new_from_file(filename: [*:0]const u8) ?*GtkWidget;
extern fn gtk_fixed_put(fixed: ?*GtkWidget, widget: ?*GtkWidget, x: c_int, y: c_int) void;
extern fn gtk_label_new(str: [*:0]const u8) ?*GtkWidget;
extern fn gtk_widget_set_size_request(widget: ?*GtkWidget, width: c_int, height: c_int) void;
extern fn gtk_drawing_area_new() ?*GtkWidget;
extern fn gtk_widget_set_tooltip_text(widget: ?*GtkWidget, text: [*:0]const u8) void;
extern fn cairo_format_stride_for_width(format: c_int, width: c_int) c_int;
extern fn malloc(size: usize) ?*anyopaque;
extern fn exit(code: c_int) noreturn;
extern fn moreInfoOnError(prefix: [*:0]const u8, message: [*:0]const u8, third: ?[*:0]const u8, fourth: ?[*:0]const u8) void;

extern fn z47_destroyCalc(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int;
extern fn z47_keyPressed_wrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int;
extern fn z47_keyReleased_wrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int;
extern fn z47_onConfigureEvent(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int;
extern fn z47_onUIActivity(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int;
extern fn z47_drawScreen_wrapper(widget: ?*anyopaque, cr: ?*anyopaque, data: ?*anyopaque) c_int;

fn isR47FAM() bool {
    return calcModel == USER_R47f_g or calcModel == USER_R47bk_fg or calcModel == USER_R47fg_bk or calcModel == USER_R47fg_g;
}

fn configureWindowLayout() void {
    setup_window_owned.configureWindowLayout();
}

fn setupBackgroundImage() void {
    setup_background_owned.setupBackgroundImage();
}

fn setupSoftkeyLabels() void {
    setup_softkey_owned.setupSoftkeyLabels();
}

fn setupScreenBuffer() void {
    setup_screen_owned.setupScreenBuffer();
}

pub fn setupUiPreamble() void {
    configureWindowLayout();
    setupBackgroundImage();
    setupSoftkeyLabels();
    setupScreenBuffer();
}
