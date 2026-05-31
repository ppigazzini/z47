const profile_bridge_owned = @import("gtk_gui_profile_bridge_owned.zig");
const shortcut_bridge_owned = @import("gtk_gui_shortcut_bridge_owned.zig");
const key_wrapper_owned = @import("gtk_gui_key_wrapper_owned.zig");
const lifecycle_bridge_owned = @import("gtk_gui_lifecycle_bridge_owned.zig");
const callback_bridge_owned = @import("gtk_gui_callback_bridge_owned.zig");
const setup_preamble_owned = @import("gtk_gui_setup_preamble_owned.zig");
const startup_owned = @import("gtk_gui_startup_owned.zig");
const shell_owned = @import("gtk_gui_shell_owned.zig");

pub export fn z47_setupUI_preamble() callconv(.c) void {
    setup_preamble_owned.setupUiPreamble();
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

pub export fn checkNormal(key_nr: i16, item: i16) callconv(.c) bool {
    return profile_bridge_owned.checkNormal(key_nr, item);
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
    return shortcut_bridge_owned.shortCutCommand(
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
    return shortcut_bridge_owned.shortCutFnCommand(
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
