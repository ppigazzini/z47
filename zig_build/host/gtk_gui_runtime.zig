const profile_owned = @import("gtk_gui_profile_owned.zig");
const shortcut_owned = @import("gtk_gui_shortcut_owned.zig");
const lifecycle_owned = @import("gtk_gui_lifecycle_owned.zig");

const GtkWidget = opaque {};
const GtkCssProvider = opaque {};
const GtkStyleProvider = opaque {};
const GtkWindow = opaque {};
const GtkContainer = opaque {};
const GtkFixed = opaque {};
const GdkDisplay = opaque {};
const GdkScreen = opaque {};
const GdkMonitor = opaque {};
const GError = opaque {};

const GdkRectangle = extern struct {
    x: c_int,
    y: c_int,
    width: c_int,
    height: c_int,
};

const GdkEventKey = extern struct {
    type: c_int,
    window: ?*anyopaque,
    send_event: c_int,
    time: c_uint,
    state: c_uint,
    keyval: c_uint,
    length: c_int,
    string: ?[*:0]u8,
    hardware_keycode: c_uint,
    group: c_uint,
    is_modifier: c_uint,
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

const KEY_fg: i16 = 1893;
const ITM_SHIFTf: i16 = 1731;
const ITM_SHIFTg: i16 = 1732;
const FLAG_USER: u16 = 0x8014;
const GDK_KEY_Shift_L: u32 = 65505;
const GDK_KEY_Shift_R: u32 = 65506;
const GDK_KEY_Control_L: u32 = 65507;
const GDK_KEY_Control_R: u32 = 65508;
const GDK_KEY_Alt_R: u32 = 65514;
const GDK_KEY_F1: u32 = 65470;
const GDK_KEY_F2: u32 = 65471;
const GDK_KEY_F3: u32 = 65472;
const GDK_KEY_F4: u32 = 65473;
const GDK_KEY_F5: u32 = 65474;
const GDK_KEY_F6: u32 = 65475;
const GDK_KEY_Up: u32 = 65362;
const GDK_KEY_Down: u32 = 65364;
const GDK_KEY_f: u32 = 102;
const GDK_KEY_g: u32 = 103;
const GTK_WINDOW_TOPLEVEL: c_int = 0;
const GTK_WIN_POS_CENTER: c_int = 1;
const GDK_CONFIGURE: c_int = 13;
const CAIRO_FORMAT_RGB24: c_int = 1;
const SCREEN_WIDTH: c_int = 400;
const SCREEN_HEIGHT: c_int = 240;
const BIG_SCREEN_COEF: c_int = 1;
const DELTA_KEYS_X: c_int = 78;
const KEY_WIDTH_1: c_int = 47;
const X_LEFT_PORTRAIT: c_int = 45;
const X_LEFT_LANDSCAPE: c_int = 544;
const Y_TOP_PORTRAIT: c_int = 376;
const Y_TOP_LANDSCAPE: c_int = 30;
const NARROW_SCREEN: bool = false;
const CSSFILE = "res/c47_pre.css";

const tamState_t = extern struct {
    mode: u16,
    function: i16,
    alpha: bool,
    currentOperation: i16,
    dot: bool,
    indirect: bool,
    digitsSoFar: i16,
    value0: i16,
    value: i16,
    min: i16,
    max: i16,
    key: i16,
    keyAlpha: bool,
    keyDot: bool,
    keyIndirect: bool,
    keyInputFinished: bool,
};

const USER_DM42: u8 = 45;
const USER_C47: u8 = 46;
const USER_R47f_g: u8 = 61;
const USER_R47bk_fg: u8 = 62;
const USER_R47fg_bk: u8 = 63;
const USER_R47fg_g: u8 = 64;
const USER_R47: u8 = 66;
const ITM_NULL: i16 = 0;
const ITM_SIGMAPLUS: i16 = 433;
const FLAG_ALPHA: u16 = 0x800e;
const FLAG_NUMLOCK: u16 = 0x8043;
const CM_NORMAL: u8 = 0;
const CM_NIM: u8 = 2;
const CM_PEM: u8 = 3;
const CM_AIM: u8 = 1;
const CM_EIM: u8 = 13;
const CM_TIMER: u8 = 14;
const TM_FLAGR: u16 = 10004;
const TM_FLAGW: u16 = 10005;
const TM_STORCL: u16 = 10006;
const TM_LABEL: u16 = 10009;
const TM_SOLVE: u16 = 10010;
const TM_MENU: u16 = 10017;
const TM_LBLONLY: u16 = 10018;
const MNU_MVAR: i16 = 1398;
const TI_NO_INFO: u8 = 0;
const SCRUPD_AUTO: u8 = 0x00;

extern var calcModel: u8;
extern var calcMode: u8;
extern var catalog: i16;
extern var temporaryInformation: u8;
extern var screenUpdatingMode: u8;
extern var shiftF: bool;
extern var shiftG: bool;
extern var swapCtrlCode: bool;
extern var tam: tamState_t;
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
extern var kbd_std_C47: [37]calcKey_t;
extern var kbd_std_DM42: [37]calcKey_t;
extern var kbd_std_R47f_g: [37]calcKey_t;
extern var kbd_std_R47bk_fg: [37]calcKey_t;
extern var kbd_std_R47fg_bk: [37]calcKey_t;
extern var kbd_std_R47fg_g: [37]calcKey_t;

extern fn btnClicked(widget: ?*anyopaque, data: [*:0]const u8) void;
extern fn refreshStatusBar() void;
extern fn showShiftState() void;
extern fn showHideAlphaMode() void;
extern fn processAimInput(item: i16) void;
extern fn pemAlpha(item: i16) void;
extern fn clearSystemFlag(flag: u16) void;
extern fn setSystemFlag(flag: u16) void;
extern fn getSystemFlag(flag: u16) bool;
extern fn Check_Norm_Key_00_Assigned(result: *i16, tempkey: i16) i16;
extern fn currentMenu() i16;
extern fn showSoftmenu(id: i16) void;
extern fn runFunction(func: i16) void;
extern fn closeNim() void;
extern fn refreshScreen(source: u16) void;
extern fn btnFnClicked(widget: ?*anyopaque, data: [*:0]const u8) void;
extern fn gtk_css_provider_new() ?*GtkCssProvider;
extern fn gdk_display_get_default() ?*GdkDisplay;
extern fn gdk_display_get_default_screen(display: ?*GdkDisplay) ?*GdkScreen;
extern fn gtk_style_context_add_provider_for_screen(screen: ?*GdkScreen, provider: ?*GtkStyleProvider, priority: c_uint) void;
extern fn gtk_css_provider_load_from_data(provider: ?*GtkCssProvider, data: [*c]const u8, length: c_long, gerror: ?*anyopaque) c_int;
extern fn g_object_unref(object: ?*anyopaque) void;
extern fn gdk_display_get_monitor(display: ?*GdkDisplay, monitor_num: c_int) ?*GdkMonitor;
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
extern fn gtk_drawing_area_new() ?*GtkWidget;
extern fn gtk_fixed_put(fixed: ?*GtkWidget, widget: ?*GtkWidget, x: c_int, y: c_int) void;
extern fn gtk_label_new(str: [*:0]const u8) ?*GtkWidget;
extern fn gtk_widget_set_size_request(widget: ?*GtkWidget, width: c_int, height: c_int) void;
extern fn gtk_widget_set_tooltip_text(widget: ?*GtkWidget, text: [*:0]const u8) void;
extern fn gtk_button_new_with_label(label: [*:0]const u8) ?*GtkWidget;
extern fn gtk_button_new() ?*GtkWidget;
extern fn gtk_widget_set_focus_on_click(widget: ?*GtkWidget, setting: c_int) void;
extern fn cairo_format_stride_for_width(format: c_int, width: c_int) c_int;
extern fn malloc(size: usize) ?*anyopaque;
extern fn free(ptr: ?*anyopaque) void;
extern fn exit(code: c_int) noreturn;
extern fn moreInfoOnError(prefix: [*:0]const u8, message: [*:0]const u8, third: ?[*:0]const u8, fourth: ?[*:0]const u8) void;

fn isR47FAM() bool {
    return calcModel == USER_R47f_g or calcModel == USER_R47bk_fg or calcModel == USER_R47fg_bk or calcModel == USER_R47fg_g;
}

fn setupUiPreamble() void {
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

    if (modelString[0] == 0) {
        const base = if (isR47FAM()) "R47" else "C47";
        var idx: usize = 0;
        modelString[0] = 'r'; modelString[1] = 'e'; modelString[2] = 's'; modelString[3] = '/'; idx = 4;
        for (base) |ch| {
            modelString[idx] = ch;
            idx += 1;
        }
        if (calcLandscape) {
            const suffix = "short.png";
            for (suffix) |ch| { modelString[idx] = ch; idx += 1; }
        } else {
            const suffix = ".png";
            for (suffix) |ch| { modelString[idx] = ch; idx += 1; }
        }
        modelString[idx] = 0;
    } else {
        const prefix = "res/";
        var idx: usize = 0;
        for (prefix) |ch| { modelString[idx] = ch; idx += 1; }
        for (modelString[0..]) |ch| {
            if (ch == 0) break;
            modelString[idx] = ch;
            idx += 1;
        }
        modelString[idx] = 0;
    }

    if (!NARROW_SCREEN) {
        backgroundImage = gtk_image_new_from_file(@as([*:0]const u8, @ptrCast(&modelString[0])));
        gtk_fixed_put(@ptrCast(grid), backgroundImage, 0, 0);
    } else {
        backgroundImage = gtk_image_new_from_file("res/dm42l_L1_narrow_screen.png");
        gtk_fixed_put(@ptrCast(grid), backgroundImage, 0, 240);
    }

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

    screen = gtk_drawing_area_new();
    gtk_widget_set_size_request(screen, SCREEN_WIDTH, SCREEN_HEIGHT);
    gtk_widget_set_tooltip_text(screen, "Copy to clipboard:\n CTRL+h: Screen image\n CTRL+m: Menu image\n CTRL+c/x: X Register\n CTRL+d: Lettered Registers\n CTRL+a: All Registers\nCTRL+s: SNAP\n");
    if (!NARROW_SCREEN) {
        gtk_fixed_put(@ptrCast(grid), screen, 63, 72);
    } else {
        gtk_fixed_put(@ptrCast(grid), screen, 0, 0);
    }

    screenStride = @intCast(@divTrunc(cairo_format_stride_for_width(CAIRO_FORMAT_RGB24, SCREEN_WIDTH), 4));
    const numBytes: usize = @as(usize, @intCast(screenStride)) * SCREEN_HEIGHT * 4;
    const raw = malloc(numBytes);
    if (raw == null) {
        moreInfoOnError("In function setupUI:", "error allocating screenData", null, null);
        exit(1);
    }
    screenData = @ptrCast(@alignCast(raw.?));
    _ = g_signal_connect_data(screen, "draw", @ptrCast(&z47_drawScreen_wrapper), null, null, 0);
}

pub export fn z47_setupUI_preamble() callconv(.c) void {
    setupUiPreamble();
}

pub export fn z47_setupUI_no_keyboard_shell() callconv(.c) void {
    frmCalc = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_default_size(@ptrCast(frmCalc), SCREEN_WIDTH * BIG_SCREEN_COEF, SCREEN_HEIGHT * BIG_SCREEN_COEF);
    gtk_window_set_decorated(@ptrCast(frmCalc), 0);
    gtk_window_set_position(@ptrCast(frmCalc), GTK_WIN_POS_CENTER);

    gtk_widget_set_name(frmCalc, "mainWindow");
    gtk_window_set_resizable(@ptrCast(frmCalc), 0);
    _ = g_signal_connect_data(frmCalc, "destroy", @ptrCast(&z47_destroyCalc), null, null, 0);
    _ = g_signal_connect_data(frmCalc, "key_press_event", @ptrCast(&z47_keyPressed_wrapper), null, null, 0);
    _ = g_signal_connect_data(frmCalc, "key_release_event", @ptrCast(&z47_keyReleased_wrapper), null, null, 0);

    gtk_widget_add_events(frmCalc, GDK_CONFIGURE);

    grid = gtk_fixed_new();
    gtk_container_add(@ptrCast(frmCalc), grid);

    screen = gtk_drawing_area_new();
    gtk_widget_set_size_request(screen, SCREEN_WIDTH * BIG_SCREEN_COEF, SCREEN_HEIGHT * BIG_SCREEN_COEF);
    gtk_fixed_put(@ptrCast(grid), screen, 0, 0);

    screenStride = @intCast(@divTrunc(cairo_format_stride_for_width(CAIRO_FORMAT_RGB24, SCREEN_WIDTH), 4));
    const numBytes: usize = @as(usize, @intCast(screenStride)) * SCREEN_HEIGHT * 4;
    const raw = malloc(numBytes);
    if (raw == null) {
        moreInfoOnError("In function setupUI:", "error allocating screenData", null, null);
        exit(1);
    }
    screenData = @ptrCast(@alignCast(raw.?));

    _ = g_signal_connect_data(screen, "draw", @ptrCast(&z47_drawScreen_wrapper), null, null, 0);
}

pub export fn z47_startup_init_ui(argc: *c_int, argv: [*]?[*:0]u8) callconv(.c) void {
    gtk_init(argc, argv);
    setupUI();

    // Keep the legacy settle pass that aligns shifted labels before restore.
    calcModeAimGui();
    while (gtk_events_pending() != 0) {
        _ = gtk_main_iteration();
    }
    calcModeNormalGui();
    while (gtk_events_pending() != 0) {
        _ = gtk_main_iteration();
    }
}

pub export fn z47_startup_enter_mainloop() callconv(.c) void {
    gtk_main();
}

fn normKey00ItemInLayout() i16 {
    return profile_owned.normKey00ItemInLayout();
}

fn shortcutProfileValue() u8 {
    return profile_owned.shortcutProfileValue();
}

fn currentStdKeyboard() *const [37]calcKey_t {
    return @ptrCast(profile_owned.currentStdKeyboard());
}

fn isLabelText() bool {
    return profile_owned.isLabelText();
}

fn alphaArrowsOffAndUpDn() bool {
    return profile_owned.alphaArrowsOffAndUpDn();
}

pub export fn btnClicked_NU(widget: ?*anyopaque, data: ?*anyopaque) callconv(.c) void {
    shortcut_owned.btnClickedNU(widget, data);
}

pub export fn sendKey(sent: i16) callconv(.c) void {
    shortcut_owned.sendKey(sent);
}

pub export fn checkNormal(keyNr: i16, item: i16) callconv(.c) bool {
    return profile_owned.checkNormal(keyNr, item);
}

pub export fn shortCutCommand(
    widget: ?*anyopaque,
    key: c_int,
    keyCode: c_int,
    condition1: bool,
    exitIfInNIM: bool,
    disable: bool,
    shift: [*:0]const u8,
    keyForBtnClicked: [*:0]const u8,
    modes: u16,
    requiredCalcMode2: i16,
    itemForRunFunction: i16,
) callconv(.c) bool {
    return shortcut_owned.shortCutCommand(widget, key, keyCode, condition1, exitIfInNIM, disable, shift, keyForBtnClicked, modes, requiredCalcMode2, itemForRunFunction);
}

pub export fn shortCutFNCommand(
    widget: ?*anyopaque,
    key: c_int,
    keyCode: c_int,
    condition1: bool,
    disable: bool,
    shift: [*:0]const u8,
    keyForBtnClicked: [*:0]const u8,
    modes: u16,
    requiredCalcMode2: i16,
    itemForRunFunction: i16,
) callconv(.c) bool {
    return shortcut_owned.shortCutFNCommand(widget, key, keyCode, condition1, disable, shift, keyForBtnClicked, modes, requiredCalcMode2, itemForRunFunction);
}

pub export fn z47_btnFnPressed_wrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    btnFnPressed(widget, event, data);
    return 0;
}

pub export fn z47_btnFnReleased_wrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    btnFnReleased(widget, event, data);
    return 0;
}

pub export fn z47_keyPressed_wrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return z47_keyPressed_impl(widget, event, data);
}

pub export fn z47_keyReleased_wrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return z47_keyReleased_impl(widget, event, data);
}

pub export fn z47_keyPressed_impl(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    if (event == null) return z47_keyPressed_c_impl(widget, event, data);

    const key_event: *GdkEventKey = @ptrCast(@alignCast(event.?));
    event_keyval = key_event.keyval + CTRL_State;

    const altgr_pressed = key_event.keyval == GDK_KEY_Alt_R and (key_event.state & 0b10100) != 0;
    const ctrl_pressed = if (swapCtrlCode)
        (key_event.keyval == GDK_KEY_Control_L and (key_event.state & 0b00100) == 0)
    else
        (key_event.keyval == GDK_KEY_Control_L and (key_event.state & 0b00100) != 0);

    if (ctrl_pressed) {
        previousEventStateP = key_event.state;
        previousEventKeyP = key_event.keyval;
        return z47_keyPressed_c_impl(widget, event, data);
    }

    if (altgr_pressed) {
        SHIFT_State = 0;
        event_command_shift = 0;
        CTRL_State = 0;
        shiftF = false;
        shiftG = false;
        refreshStatusBar();
        showShiftState();
        previousEventStateP = key_event.state;
        previousEventKeyP = key_event.keyval;
        return 0;
    }

    SHIFT_State = 0;
    switch (event_keyval) {
        GDK_KEY_Shift_L, GDK_KEY_Shift_R => {
            SHIFT_State = 65536;
            event_command_shift = 65536;
            previousEventStateP = key_event.state;
            previousEventKeyP = key_event.keyval;
            return 0;
        },
        GDK_KEY_Control_L, GDK_KEY_Control_R => {
            CTRL_State = 65536;
            previousEventStateP = key_event.state;
            previousEventKeyP = key_event.keyval;
            return 0;
        },
        else => {},
    }

    if (CTRL_State == 65536 and !ctrl_pressed) {
        previousEventStateP = key_event.state;
        previousEventKeyP = key_event.keyval;
        return z47_keyPressed_c_impl(widget, event, data);
    }

    const in_text_modes = calcMode == CM_AIM or calcMode == CM_EIM or tam.mode != 0 or (calcMode == CM_PEM and getSystemFlag(FLAG_ALPHA)) or tam.alpha;
    if (!in_text_modes) {
        const key_strip = stripCapsLockForCommand(key_event.keyval);
        const standard_keys = currentStdKeyboard();

        switch (key_strip) {
            GDK_KEY_f => {
                if (checkNormal(0, ITM_SHIFTf)) btnClicked(widget, "00") else
                if (checkNormal(10, ITM_SHIFTf)) btnClicked(widget, "10") else
                if (checkNormal(11, ITM_SHIFTf)) btnClicked(widget, "11") else
                if ((if (getSystemFlag(FLAG_USER)) kbd_usr[10].primary else standard_keys[10].primary) == ITM_SHIFTf) btnClicked(widget, "10") else
                if ((if (getSystemFlag(FLAG_USER)) kbd_usr[11].primary else standard_keys[11].primary) == ITM_SHIFTf) btnClicked(widget, "11") else
                if ((if (getSystemFlag(FLAG_USER)) kbd_usr[10].primary else standard_keys[10].primary) == KEY_fg) btnClicked(widget, "10") else
                if ((if (getSystemFlag(FLAG_USER)) kbd_usr[11].primary else standard_keys[11].primary) == KEY_fg) btnClicked(widget, "11") else
                if ((if (getSystemFlag(FLAG_USER)) kbd_usr[27].primary else standard_keys[27].primary) == KEY_fg) btnClicked(widget, "27");

                previousEventStateP = key_event.state;
                previousEventKeyP = key_event.keyval;
                return 0;
            },
            GDK_KEY_g => {
                if (checkNormal(0, ITM_SHIFTg)) btnClicked(widget, "00") else
                if (checkNormal(10, ITM_SHIFTg)) btnClicked(widget, "10") else
                if (checkNormal(11, ITM_SHIFTg)) btnClicked(widget, "11") else
                if ((if (getSystemFlag(FLAG_USER)) kbd_usr[11].primary else standard_keys[11].primary) == ITM_SHIFTg) btnClicked(widget, "11") else
                if ((if (getSystemFlag(FLAG_USER)) kbd_usr[10].primary else standard_keys[10].primary) == ITM_SHIFTg) btnClicked(widget, "10") else {
                    shiftF = false;
                    shiftG = !shiftG;
                    refreshStatusBar();
                    showShiftState();
                }

                previousEventStateP = key_event.state;
                previousEventKeyP = key_event.keyval;
                return 0;
            },
            else => {},
        }
    }

    previousEventStateP = key_event.state;
    previousEventKeyP = key_event.keyval;
    return z47_keyPressed_c_impl(widget, event, data);
}

fn stripCapsLockForCommand(keyval: u32) u32 {
    const is_alpha = (keyval >= 'A' and keyval <= 'Z') or (keyval >= 'a' and keyval <= 'z');
    if (!is_alpha) return keyval;

    return (keyval & 0xFFFFDF) + (0x20 & ~(event_command_shift >> (16 - 5)));
}

pub export fn z47_keyReleased_impl(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    _ = data;

    const key_event: *GdkEventKey = @ptrCast(@alignCast(event.?));

    if (event_keyval == key_event.keyval + CTRL_State) {
        event_keyval = 99999999;
    }

    const ctrl_released = (key_event.keyval == GDK_KEY_Control_L and (key_event.state & 0b00000) != 0) and
        (previousEventKeyP == GDK_KEY_Control_L and previousEventStateP == 0b00100);
    if (ctrl_released) {
        previousEventStateR = key_event.state;
        previousEventKeyR = key_event.keyval;
        return 0;
    }

    const altgr_released = (key_event.keyval == GDK_KEY_Alt_R and (key_event.state & 0b00000) != 0) and
        (previousEventKeyR == GDK_KEY_Control_L and previousEventStateR == 0b1000);
    if (altgr_released) {
        SHIFT_State = 0;
        event_command_shift = 0;
        CTRL_State = 0;
        shiftF = false;
        shiftG = false;
        refreshStatusBar();
        showShiftState();
        previousEventStateR = key_event.state;
        previousEventKeyR = key_event.keyval;
        return 0;
    }

    const standard_keys = currentStdKeyboard();

    switch (key_event.keyval) {
        GDK_KEY_Shift_L, GDK_KEY_Shift_R => {
            event_command_shift = 0;
            if (SHIFT_State != 0) {
                if (checkNormal(0, KEY_fg)) btnClicked(widget, "00") else
                if (checkNormal(10, KEY_fg)) btnClicked(widget, "10") else
                if (checkNormal(11, KEY_fg)) btnClicked(widget, "11") else
                if (checkNormal(0, ITM_SHIFTf)) btnClicked(widget, "00") else
                if (checkNormal(10, ITM_SHIFTf)) btnClicked(widget, "10") else
                if (checkNormal(11, ITM_SHIFTf)) btnClicked(widget, "11") else
                if ((if (getSystemFlag(FLAG_USER)) kbd_usr[10].primary else standard_keys[10].primary) == ITM_SHIFTf) btnClicked(widget, "10") else
                if ((if (getSystemFlag(FLAG_USER)) kbd_usr[0].primary else standard_keys[0].primary) == KEY_fg) btnClicked(widget, "00") else
                if ((if (getSystemFlag(FLAG_USER)) kbd_usr[10].primary else standard_keys[10].primary) == KEY_fg) btnClicked(widget, "10") else
                if ((if (getSystemFlag(FLAG_USER)) kbd_usr[11].primary else standard_keys[11].primary) == KEY_fg) btnClicked(widget, "11") else
                if ((if (getSystemFlag(FLAG_USER)) kbd_usr[27].primary else standard_keys[27].primary) == KEY_fg) btnClicked(widget, "27") else {
                    shiftF = !shiftF;
                    shiftG = false;
                    refreshStatusBar();
                    showShiftState();
                }
            }
            SHIFT_State = 0;
        },

        GDK_KEY_Control_L, GDK_KEY_Control_R => {
            if (CTRL_State != 0) {
                if (checkNormal(0, KEY_fg)) btnClicked(widget, "00") else
                if (checkNormal(10, KEY_fg)) btnClicked(widget, "10") else
                if (checkNormal(11, KEY_fg)) btnClicked(widget, "11") else
                if (checkNormal(0, ITM_SHIFTg)) btnClicked(widget, "00") else
                if (checkNormal(10, ITM_SHIFTg)) btnClicked(widget, "10") else
                if (checkNormal(11, ITM_SHIFTg)) btnClicked(widget, "11") else
                if ((if (getSystemFlag(FLAG_USER)) kbd_usr[11].primary else standard_keys[11].primary) == ITM_SHIFTg) btnClicked(widget, "11") else {
                    shiftF = false;
                    shiftG = !shiftG;
                    refreshStatusBar();
                    showShiftState();
                }
            }
            CTRL_State = 0;
        },

        GDK_KEY_F1 => if (isLabelText() or tam.mode == 0 or alphaArrowsOffAndUpDn()) btnFnClickedR(widget, "1"),
        GDK_KEY_F2 => if (isLabelText() or tam.mode == 0 or alphaArrowsOffAndUpDn()) btnFnClickedR(widget, "2"),
        GDK_KEY_F3 => if (isLabelText() or tam.mode == 0 or alphaArrowsOffAndUpDn()) btnFnClickedR(widget, "3"),
        GDK_KEY_F4 => if (isLabelText() or tam.mode == 0 or alphaArrowsOffAndUpDn()) btnFnClickedR(widget, "4"),
        GDK_KEY_F5 => if (isLabelText() or tam.mode == 0 or alphaArrowsOffAndUpDn()) btnFnClickedR(widget, "5"),
        GDK_KEY_F6 => if (isLabelText() or tam.mode == 0 or alphaArrowsOffAndUpDn()) btnFnClickedR(widget, "6"),
        else => {},
    }

    if (key_event.keyval != GDK_KEY_Shift_L and key_event.keyval != GDK_KEY_Shift_R) {
        SHIFT_State = 0;
    }

    previousEventStateR = key_event.state;
    previousEventKeyR = key_event.keyval;
    return 0;
}

pub export fn z47_drawScreen_wrapper(widget: ?*anyopaque, cr: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return drawScreen(widget, cr, data);
}

pub export fn z47_destroyCalc(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return lifecycle_owned.destroyCalc(widget, event, data);
}

pub export fn z47_onConfigureEvent(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return lifecycle_owned.onConfigureEvent(widget, event, data);
}

var CTRL_State: u32 = 0;
var SHIFT_State: u32 = 0;
var event_keyval: u32 = 99999999;
var event_command_shift: u32 = 0;
var previousEventStateR: u32 = 0;
var previousEventKeyR: u32 = 0;
var previousEventStateP: u32 = 0;
var previousEventKeyP: u32 = 0;

pub export fn z47_onUIActivity(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return lifecycle_owned.onUiActivity(widget, event, data);
}

extern fn btnFnPressed(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) void;
extern fn btnFnReleased(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) void;
extern fn btnFnClickedR(widget: ?*anyopaque, data: [*:0]const u8) void;
extern fn gtk_init(argc: *c_int, argv: [*]?[*:0]u8) void;
extern fn setupUI() void;
extern fn calcModeAimGui() void;
extern fn calcModeNormalGui() void;
extern fn gtk_events_pending() c_int;
extern fn gtk_main_iteration() c_int;
extern fn gtk_main() void;
extern fn z47_keyPressed_c_impl(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int;
extern fn z47_keyReleased_c_impl(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int;
extern fn drawScreen(widget: ?*anyopaque, cr: ?*anyopaque, data: ?*anyopaque) c_int;
extern fn fnStopTimerApp() void;
extern fn saveCalc() void;
extern fn gtk_main_quit() void;
extern fn gtk_widget_queue_draw(widget: ?*anyopaque) void;
extern fn g_get_monotonic_time() i64;
extern fn g_source_remove(tag: c_uint) c_int;
extern fn g_timeout_add(interval: c_uint, function: *const fn (?*anyopaque) callconv(.c) c_int, data: ?*anyopaque) c_uint;
extern var ui_is_active: c_int;
