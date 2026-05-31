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
const gtk_image_new_from_file = gtk_decls.gtk_image_new_from_file;
const gtk_fixed_put = gtk_decls.gtk_fixed_put;
const gtk_label_new = gtk_decls.gtk_label_new;
const gtk_widget_set_size_request = gtk_decls.gtk_widget_set_size_request;
const gtk_drawing_area_new = gtk_decls.gtk_drawing_area_new;
const gtk_widget_set_tooltip_text = gtk_decls.gtk_widget_set_tooltip_text;

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
const GTK_WINDOW_TOPLEVEL: c_int = 0;
const GTK_WIN_POS_CENTER: c_int = 1;
const GDK_CONFIGURE: c_int = 13;
const BIG_SCREEN_COEF: c_int = 1;
const NARROW_SCREEN: bool = false;
const CAIRO_FORMAT_RGB24: c_int = 1;
const SCREEN_WIDTH: c_int = 400;
const SCREEN_HEIGHT: c_int = 240;
const ITM_SHIFTf: i16 = 1731;
const ITM_SHIFTg: i16 = 1732;
const DELTA_KEYS_X: c_int = 78;

extern var calcModel: u8;
extern var calcAutoLandscapePortrait: bool;
extern var calcLandscape: bool;
extern var modelString: [50]u8;
extern var frmCalc: ?*GtkWidget;
extern var grid: ?*GtkWidget;
extern var backgroundImage: ?*GtkWidget;
extern var lblFKey2: ?*GtkWidget;
extern var lblGKey2: ?*GtkWidget;
extern var kbd_usr: [37]calcKey_t;
extern var screen: ?*GtkWidget;
extern var screenStride: i16;
extern var screenData: [*]u32;

extern fn z47_destroyCalc(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int;
extern fn z47_keyPressed_wrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int;
extern fn z47_keyReleased_wrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int;
extern fn z47_onConfigureEvent(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int;
extern fn z47_onUIActivity(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int;
extern fn cairo_format_stride_for_width(format: c_int, width: c_int) c_int;
extern fn malloc(size: usize) ?*anyopaque;
extern fn exit(code: c_int) noreturn;
extern fn moreInfoOnError(prefix: [*:0]const u8, message: [*:0]const u8, third: ?[*:0]const u8, fourth: ?[*:0]const u8) void;
extern fn z47_drawScreen_wrapper(widget: ?*anyopaque, cr: ?*anyopaque, data: ?*anyopaque) c_int;

fn isR47FAM() bool {
    return calcModel == USER_R47f_g or calcModel == USER_R47bk_fg or calcModel == USER_R47fg_bk or calcModel == USER_R47fg_g;
}

fn ensureModelString() void {
    if (modelString[0] == 0) {
        const base = if (isR47FAM()) "R47" else "C47";
        var idx: usize = 0;
        modelString[0] = 'r';
        modelString[1] = 'e';
        modelString[2] = 's';
        modelString[3] = '/';
        idx = 4;
        for (base) |ch| {
            modelString[idx] = ch;
            idx += 1;
        }
        if (calcLandscape) {
            const suffix = "short.png";
            for (suffix) |ch| {
                modelString[idx] = ch;
                idx += 1;
            }
        } else {
            const suffix = ".png";
            for (suffix) |ch| {
                modelString[idx] = ch;
                idx += 1;
            }
        }
        modelString[idx] = 0;
    } else {
        const prefix = "res/";
        var idx: usize = 0;
        for (prefix) |ch| {
            modelString[idx] = ch;
            idx += 1;
        }
        for (modelString[0..]) |ch| {
            if (ch == 0) break;
            modelString[idx] = ch;
            idx += 1;
        }
        modelString[idx] = 0;
    }
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

pub fn setupBackgroundImage() void {
    ensureModelString();

    if (!NARROW_SCREEN) {
        backgroundImage = gtk_image_new_from_file(@as([*:0]const u8, @ptrCast(&modelString[0])));
        gtk_fixed_put(@ptrCast(grid), backgroundImage, 0, 0);
    } else {
        backgroundImage = gtk_image_new_from_file("res/dm42l_L1_narrow_screen.png");
        gtk_fixed_put(@ptrCast(grid), backgroundImage, 0, 240);
    }
}

pub fn setupSoftkeyLabels() void {
    lblFKey2 = gtk_label_new("");
    gtk_widget_set_name(lblFKey2, "fSoftkeyArea");
    if (kbd_usr[10].primary == ITM_SHIFTf) {
        gtk_widget_set_size_request(lblFKey2, 61 - 8 - 2 - 2, 5 - 2);
        gtk_fixed_put(@ptrCast(grid), lblFKey2, 350 + 4 + 2, 563 - 1);
    }

    lblGKey2 = gtk_label_new("");
    gtk_widget_set_name(lblGKey2, "gSoftkeyArea");
    if (kbd_usr[11].primary == ITM_SHIFTg) {
        gtk_widget_set_size_request(lblGKey2, 61 - 8 - 2 - 2, 5 - 2);
        gtk_fixed_put(@ptrCast(grid), lblGKey2, 350 + 4 + 2 + DELTA_KEYS_X, 563 - 1);
    }
}

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