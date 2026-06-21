const shortcut_owned = @import("gtk_gui_shortcut_owned.zig");
const events_owned = @import("gtk_gui_events_owned.zig");
const setup_owned = @import("gtk_gui_setup_owned.zig");
const shell_owned = @import("gtk_gui_shell_owned.zig");
const keymap_owned = @import("gtk_gui_keymap_owned.zig");
// The ported GTK entry point main() + program globals (was c47-gtk.c via the
// retired gtk_c47_gtk_legacy.c shim).
comptime {
    _ = @import("gtk_c47_main_owned.zig");
}

extern fn gtk_init(argc: *c_int, argv: [*]?[*:0]u8) void;
extern fn setupUI() void;
extern fn gtk_main() void;
extern fn drawScreen(widget: ?*anyopaque, cr: ?*anyopaque, data: ?*anyopaque) c_int;
extern fn btnPressed(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) void;
extern fn btnReleased(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) void;
extern fn calcModeAimGui() void;
extern fn calcModeNormalGui() void;
extern fn gtk_events_pending() c_int;
extern fn gtk_main_iteration() c_int;

fn settleUiModePass() void {
    calcModeAimGui();
    while (gtk_events_pending() != 0) {
        _ = gtk_main_iteration();
    }
    calcModeNormalGui();
    while (gtk_events_pending() != 0) {
        _ = gtk_main_iteration();
    }
}

pub export fn z47_setupUI_preamble() callconv(.c) void {
    setup_owned.configureWindowLayout();
    setup_owned.setupBackgroundImage();
    setup_owned.setupSoftkeyLabels();
    setup_owned.setupScreenBuffer();
}

pub export fn z47_setupUI_no_keyboard_shell() callconv(.c) void {
    shell_owned.setupShellWindow();
    shell_owned.wireShellEvents();
    shell_owned.setupShellScreen();
}

pub export fn z47_startup_init_ui(argc: *c_int, argv: [*]?[*:0]u8) callconv(.c) void {
    gtk_init(argc, argv);
    setupUI();
    settleUiModePass();
}

pub export fn z47_startup_enter_mainloop() callconv(.c) void {
    gtk_main();
}

pub export fn z47_keyCodeFromGdkKey(gdk_key: u32) callconv(.c) i16 {
    return keymap_owned.keyCodeFromGdkKey(gdk_key);
}

pub export fn z47_btnPressed_signal(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    btnPressed(widget, event, data);
    return 0;
}

pub export fn z47_btnReleased_signal(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    btnReleased(widget, event, data);
    return 0;
}

pub export fn btnClicked_NU(widget: ?*anyopaque, data: ?*anyopaque) callconv(.c) void {
    shortcut_owned.btnClickedNU(widget, data);
}

pub export fn sendKey(sent: i16) callconv(.c) void {
    shortcut_owned.sendKey(sent);
}

pub export fn checkNormal(key_nr: i16, item: i16) callconv(.c) bool {
    return shortcut_owned.checkNormal(key_nr, item);
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
    return shortcut_owned.shortCutCommand(
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
    return shortcut_owned.shortCutFnCommand(
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
    return events_owned.btnFnPressedWrapper(widget, event, data);
}

pub export fn z47_btnFnReleased_wrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return events_owned.btnFnReleasedWrapper(widget, event, data);
}

pub export fn z47_keyPressed_wrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return events_owned.keyPressedImpl(widget, event, data);
}

pub export fn z47_keyReleased_wrapper(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return events_owned.keyReleasedImpl(widget, event, data);
}

pub export fn z47_keyPressed_impl(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return events_owned.keyPressedImpl(widget, event, data);
}

pub export fn z47_keyReleased_impl(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return events_owned.keyReleasedImpl(widget, event, data);
}

pub export fn z47_drawScreen_wrapper(widget: ?*anyopaque, cr: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return drawScreen(widget, cr, data);
}

pub export fn z47_destroyCalc(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return events_owned.destroyCalc(widget, event, data);
}

pub export fn z47_onConfigureEvent(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return events_owned.onConfigureEvent(widget, event, data);
}

pub export fn z47_onUIActivity(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return events_owned.onUiActivity(widget, event, data);
}
