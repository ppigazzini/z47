const shortcut_owned = @import("gtk_gui_shortcut_owned.zig");

pub fn btnClickedNU(widget: ?*anyopaque, data: ?*anyopaque) void {
    shortcut_owned.btnClickedNU(widget, data);
}

pub fn sendKey(sent: i16) void {
    shortcut_owned.sendKey(sent);
}

pub fn shortCutCommand(
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
) bool {
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

pub fn shortCutFnCommand(
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
) bool {
    return shortcut_owned.shortCutFNCommand(
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
