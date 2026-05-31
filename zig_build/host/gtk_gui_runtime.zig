const export_shortcut_owned = @import("gtk_gui_export_shortcut_owned.zig");
const key_event_owned = @import("gtk_gui_key_event_owned.zig");
const lifecycle_bridge_owned = @import("gtk_gui_lifecycle_bridge_owned.zig");
const callback_bridge_owned = @import("gtk_gui_callback_bridge_owned.zig");
const setup_background_owned = @import("gtk_gui_setup_background_owned.zig");
const setup_window_owned = @import("gtk_gui_setup_window_owned.zig");
const setup_softkey_owned = @import("gtk_gui_setup_softkey_owned.zig");
const setup_screen_owned = @import("gtk_gui_setup_screen_owned.zig");
const shell_window_owned = @import("gtk_gui_shell_window_owned.zig");
const shell_event_owned = @import("gtk_gui_shell_event_owned.zig");
const shell_screen_owned = @import("gtk_gui_shell_screen_owned.zig");
const startup_settle_owned = @import("gtk_gui_startup_settle_owned.zig");

extern fn gtk_init(argc: *c_int, argv: [*]?[*:0]u8) void;
extern fn setupUI() void;
extern fn gtk_main() void;

pub export fn z47_setupUI_preamble() callconv(.c) void {
    setup_window_owned.configureWindowLayout();
    setup_background_owned.setupBackgroundImage();
    setup_softkey_owned.setupSoftkeyLabels();
    setup_screen_owned.setupScreenBuffer();
}

pub export fn z47_setupUI_no_keyboard_shell() callconv(.c) void {
    shell_window_owned.setupShellWindow();
    shell_event_owned.wireShellEvents();
    shell_screen_owned.setupShellScreen();
}

pub export fn z47_startup_init_ui(argc: *c_int, argv: [*]?[*:0]u8) callconv(.c) void {
    gtk_init(argc, argv);
    setupUI();
    startup_settle_owned.settleUiModePass();
}

pub export fn z47_startup_enter_mainloop() callconv(.c) void {
    gtk_main();
}

pub export fn btnClicked_NU(widget: ?*anyopaque, data: ?*anyopaque) callconv(.c) void {
    export_shortcut_owned.btnClickedNU(widget, data);
}

pub export fn sendKey(sent: i16) callconv(.c) void {
    export_shortcut_owned.sendKey(sent);
}

pub export fn checkNormal(key_nr: i16, item: i16) callconv(.c) bool {
    return export_shortcut_owned.checkNormal(key_nr, item);
}

pub export fn shortCutCommand(
    widget: ?*anyopaque,
    key: c_int,
    key_code: c_int,
    condition1: bool,
    exit_if_in_nim: bool,
    disable: bool,
    shift: [*:0]const u8,
    key_for_btn_clicked: [*:0]const u8,
    modes: u16,
    required_calc_mode2: i16,
    item_for_run_function: i16,
) callconv(.c) bool {
    return export_shortcut_owned.shortCutCommand(
        widget,
        key,
        key_code,
        condition1,
        exit_if_in_nim,
        disable,
        shift,
        key_for_btn_clicked,
        modes,
        required_calc_mode2,
        item_for_run_function,
    );
}

pub export fn shortCutFNCommand(
    widget: ?*anyopaque,
    key: c_int,
    key_code: c_int,
    condition1: bool,
    disable: bool,
    shift: [*:0]const u8,
    key_for_btn_clicked: [*:0]const u8,
    modes: u16,
    required_calc_mode2: i16,
    item_for_run_function: i16,
) callconv(.c) bool {
    return export_shortcut_owned.shortCutFnCommand(
        widget,
        key,
        key_code,
        condition1,
        disable,
        shift,
        key_for_btn_clicked,
        modes,
        required_calc_mode2,
        item_for_run_function,
    );
}

pub export fn z47_btnFnPressed_wrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return callback_bridge_owned.btnFnPressedWrapper(widget, event, data);
}

pub export fn z47_btnFnReleased_wrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return callback_bridge_owned.btnFnReleasedWrapper(widget, event, data);
}

pub export fn z47_keyPressed_wrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return key_event_owned.keyPressedImpl(widget, event, data);
}

pub export fn z47_keyReleased_wrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return key_event_owned.keyReleasedImpl(widget, event, data);
}

pub export fn z47_keyPressed_impl(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return key_event_owned.keyPressedImpl(widget, event, data);
}

pub export fn z47_keyReleased_impl(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return key_event_owned.keyReleasedImpl(widget, event, data);
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
