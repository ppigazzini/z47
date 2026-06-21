const shortcut_owned = @import("gtk_gui_shortcut_owned.zig");
const events_owned = @import("gtk_gui_events_owned.zig");
const setup_owned = @import("gtk_gui_setup_owned.zig");
const shell_owned = @import("gtk_gui_shell_owned.zig");
const keymap_owned = @import("gtk_gui_keymap_owned.zig");
const label_owned = @import("gtk_gui_label_owned.zig");
const css_owned = @import("gtk_gui_css_owned.zig");
const display_owned = @import("gtk_gui_display_owned.zig");
const keypress_owned = @import("gtk_gui_keypress_owned.zig");
const setup_ui_owned = @import("gtk_gui_setup_ui_owned.zig");
// The ported GTK entry point main() + program globals (was c47-gtk.c via the
// retired gtk_c47_gtk_legacy.c shim).
comptime {
    _ = @import("gtk_c47_main_owned.zig");
}

extern fn gtk_init(argc: *c_int, argv: [*]?[*:0]u8) void;
extern fn gtk_main() void;
extern fn drawScreen(widget: ?*anyopaque, cr: ?*anyopaque, data: ?*anyopaque) c_int;
extern fn btnPressed(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) void;
extern fn btnReleased(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) void;
extern fn gtk_events_pending() c_int;
extern fn gtk_main_iteration() c_int;

fn settleUiModePass() void {
    display_owned.calcModeAimGui();
    while (gtk_events_pending() != 0) {
        _ = gtk_main_iteration();
    }
    display_owned.calcModeNormalGui();
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

pub export fn z47_is_valid_utf8(s: [*c]const u8, error_offset: [*c]usize) callconv(.c) bool {
    return label_owned.isValidUtf8(s, error_offset);
}

pub export fn z47_prepareCssData() callconv(.c) void {
    css_owned.prepareCssData();
}

pub export fn z47_print_label_bytes(data: [*c]const u8, length: c_int) callconv(.c) void {
    label_owned.printLabelBytes(data, length);
}

pub export fn z47_check_label_consistency(lbl: [*c]const u8, context: [*c]const u8) callconv(.c) bool {
    return label_owned.checkLabelConsistency(lbl, context);
}

pub export fn z47_check_utf_string(widget_name: [*c]const u8, what: [*c]const u8, s: [*c]const u8) callconv(.c) bool {
    return label_owned.checkUtfString(widget_name, what, s);
}

pub export fn z47_labelCaptionTam(key: *const label_owned.calcKey_t, button: ?*anyopaque) callconv(.c) void {
    label_owned.labelCaptionTam(key, button);
}

pub export fn z47_labelCaptionAimFa(key: *const label_owned.calcKey_t, lbl_f: ?*anyopaque) callconv(.c) void {
    label_owned.labelCaptionAimFa(key, lbl_f);
}

pub export fn z47_labelCaptionNormal(key: *const label_owned.calcKey_t, button: ?*anyopaque, lbl_f: ?*anyopaque, lbl_g: ?*anyopaque, lbl_l: ?*anyopaque) callconv(.c) void {
    label_owned.labelCaptionNormal(key, button, lbl_f, lbl_g, lbl_l);
}

pub export fn calcModeTamGui() callconv(.c) void {
    display_owned.calcModeTamGui();
}

pub export fn hideAllWidgets() callconv(.c) void {
    display_owned.hideAllWidgets();
}

pub export fn calcModeAimGui() callconv(.c) void {
    display_owned.calcModeAimGui();
}

pub export fn calcModeNormalGui() callconv(.c) void {
    display_owned.calcModeNormalGui();
}

pub export fn moveLabels() callconv(.c) void {
    display_owned.moveLabels();
}

pub export fn debugLabelConsistency(lbl: [*c]const u8, ctx: [*c]const u8, key: ?*const label_owned.calcKey_t, btn: ?*anyopaque, show_btn: bool) callconv(.c) bool {
    return display_owned.debugLabelConsistency(lbl, ctx, key, btn, show_btn);
}

pub export fn z47_labelCaptionAim(key: *const label_owned.calcKey_t, button: ?*anyopaque, lbl_g: ?*anyopaque, lbl_l: ?*anyopaque) callconv(.c) void {
    label_owned.labelCaptionAim(key, button, lbl_g, lbl_l);
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

pub export fn z47_keyPressed_c_impl(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    return keypress_owned.keyPressedCImpl(widget, event, data);
}

pub export fn setupUI() callconv(.c) void {
    setup_ui_owned.setupUI();
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
