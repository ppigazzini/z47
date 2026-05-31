const profile_owned = @import("gtk_gui_profile_owned.zig");
const key_event_owned = @import("gtk_gui_key_event_owned.zig");
const shortcut_owned = @import("gtk_gui_shortcut_owned.zig");
const lifecycle_owned = @import("gtk_gui_lifecycle_owned.zig");
const setup_preamble_owned = @import("gtk_gui_setup_preamble_owned.zig");
const startup_owned = @import("gtk_gui_startup_owned.zig");
const shell_owned = @import("gtk_gui_shell_owned.zig");
const profile_bridge_owned = @import("gtk_gui_profile_bridge_owned.zig");
const shortcut_bridge_owned = @import("gtk_gui_shortcut_bridge_owned.zig");
const key_wrapper_owned = @import("gtk_gui_key_wrapper_owned.zig");
const lifecycle_bridge_owned = @import("gtk_gui_lifecycle_bridge_owned.zig");
const callback_bridge_owned = @import("gtk_gui_callback_bridge_owned.zig");

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

fn setupUiPreamble() void {
    setup_preamble_owned.setupUiPreamble();
}

pub export fn z47_setupUI_preamble() callconv(.c) void {
    setupUiPreamble();
}

pub export fn z47_setupUI_no_keyboard_shell() callconv(.c) void {
    shell_owned.setupUiNoKeyboardShell();
}

pub export fn z47_startup_init_ui(argc: *c_int, argv: [*]?[*:0]u8) callconv(.c) void {
    startup_owned.startupInitUi(argc, argv);
}

pub export fn z47_startup_enter_mainloop() callconv(.c) void {
    startup_owned.startupEnterMainloop();
}

pub export fn btnClicked_NU(widget: ?*anyopaque, data: ?*anyopaque) callconv(.c) void {
    shortcut_bridge_owned.btnClickedNU(widget, data);
}

pub export fn sendKey(sent: i16) callconv(.c) void {
    shortcut_bridge_owned.sendKey(sent);
}

pub export fn checkNormal(keyNr: i16, item: i16) callconv(.c) bool {
    return profile_bridge_owned.checkNormal(keyNr, item);
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
    return shortcut_bridge_owned.shortCutCommand(widget, key, keyCode, condition1, exitIfInNIM, disable, shift, keyForBtnClicked, modes, requiredCalcMode2, itemForRunFunction);
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
    return shortcut_bridge_owned.shortCutFnCommand(widget, key, keyCode, condition1, disable, shift, keyForBtnClicked, modes, requiredCalcMode2, itemForRunFunction);
}

pub export fn z47_btnFnPressed_wrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return callback_bridge_owned.btnFnPressedWrapper(widget, event, data);
}

pub export fn z47_btnFnReleased_wrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return callback_bridge_owned.btnFnReleasedWrapper(widget, event, data);
}

pub export fn z47_keyPressed_wrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return key_wrapper_owned.keyPressedWrapper(widget, event, data);
}

pub export fn z47_keyReleased_wrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return key_wrapper_owned.keyReleasedWrapper(widget, event, data);
}

pub export fn z47_keyPressed_impl(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return key_wrapper_owned.keyPressedImpl(widget, event, data);
}

pub export fn z47_keyReleased_impl(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return key_wrapper_owned.keyReleasedImpl(widget, event, data);
}

pub export fn z47_drawScreen_wrapper(widget: ?*anyopaque, cr: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return callback_bridge_owned.drawScreenWrapper(widget, cr, data);
}

pub export fn z47_destroyCalc(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return lifecycle_bridge_owned.destroyCalc(widget, event, data);
}

pub export fn z47_onConfigureEvent(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return lifecycle_bridge_owned.onConfigureEvent(widget, event, data);
}

pub export fn z47_onUIActivity(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return lifecycle_bridge_owned.onUiActivity(widget, event, data);
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
