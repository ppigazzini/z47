const export_shortcut_owned = @import("gtk_gui_export_shortcut_owned.zig");
const export_key_owned = @import("gtk_gui_export_key_owned.zig");
const export_lifecycle_owned = @import("gtk_gui_export_lifecycle_owned.zig");
const export_callback_owned = @import("gtk_gui_export_callback_owned.zig");
const export_setup_owned = @import("gtk_gui_export_setup_owned.zig");

pub export fn z47_setupUI_preamble() callconv(.c) void {
    export_setup_owned.setupUiPreamble();
}

pub export fn z47_setupUI_no_keyboard_shell() callconv(.c) void {
    export_setup_owned.setupUiNoKeyboardShell();
}

pub export fn z47_startup_init_ui(argc: *c_int, argv: [*]?[*:0]u8) callconv(.c) void {
    export_setup_owned.startupInitUi(argc, argv);
}

pub export fn z47_startup_enter_mainloop() callconv(.c) void {
    export_setup_owned.startupEnterMainloop();
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
    return export_callback_owned.btnFnPressedWrapper(widget, event, data);
}

pub export fn z47_btnFnReleased_wrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return export_callback_owned.btnFnReleasedWrapper(widget, event, data);
}

pub export fn z47_keyPressed_wrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return export_key_owned.keyPressedWrapper(widget, event, data);
}

pub export fn z47_keyReleased_wrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return export_key_owned.keyReleasedWrapper(widget, event, data);
}

pub export fn z47_keyPressed_impl(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return export_key_owned.keyPressedImpl(widget, event, data);
}

pub export fn z47_keyReleased_impl(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return export_key_owned.keyReleasedImpl(widget, event, data);
}

pub export fn z47_drawScreen_wrapper(widget: ?*anyopaque, cr: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return export_callback_owned.drawScreenWrapper(widget, cr, data);
}

pub export fn z47_destroyCalc(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return export_lifecycle_owned.destroyCalc(widget, event, data);
}

pub export fn z47_onConfigureEvent(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return export_lifecycle_owned.onConfigureEvent(widget, event, data);
}

pub export fn z47_onUIActivity(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return export_lifecycle_owned.onUiActivity(widget, event, data);
}
