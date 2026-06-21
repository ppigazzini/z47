// SPDX-License-Identifier: GPL-3.0-only
//
// Host GTK calc-mode display functions ported from src/c47-gtk/gtkGui.c
// (calcModeTamGui and siblings): repaint the button/label matrix for the
// current calculator mode. They read the widget globals (gtk_gui_widgets.zig)
// and the per-key caption renderers (gtk_gui_label_owned.zig).

const widgets = @import("gtk_gui_widgets.zig");
const label = @import("gtk_gui_label_owned.zig");

const calcKey_t = label.calcKey_t;

const USER_C47: u8 = 46;
const USER_DM42: u8 = 45;
const USER_R47f_g: u8 = 61;
const USER_R47bk_fg: u8 = 62;
const USER_R47fg_bk: u8 = 63;
const USER_R47fg_g: u8 = 64;
const FLAG_USER: i32 = 32788;

extern var calcModel: u8;
extern var kbd_usr: [37]calcKey_t;
extern const kbd_std_C47: [37]calcKey_t;
extern const kbd_std_DM42: [37]calcKey_t;
extern const kbd_std_R47f_g: [37]calcKey_t;
extern const kbd_std_R47bk_fg: [37]calcKey_t;
extern const kbd_std_R47fg_bk: [37]calcKey_t;
extern const kbd_std_R47fg_g: [37]calcKey_t;

extern fn getSystemFlag(sf: i32) bool;
extern fn gtk_widget_show(widget: ?*anyopaque) void;
extern fn hideAllWidgets() void;
extern fn moveLabels() void;

// kbd_std macro (c47.h): model-dependent standard keyboard layout.
fn kbdStd() [*]const calcKey_t {
    return switch (calcModel) {
        USER_C47 => &kbd_std_C47,
        USER_DM42 => &kbd_std_DM42,
        USER_R47f_g => &kbd_std_R47f_g,
        USER_R47bk_fg => &kbd_std_R47bk_fg,
        USER_R47fg_bk => &kbd_std_R47fg_bk,
        USER_R47fg_g => &kbd_std_R47fg_g,
        else => &kbd_std_C47,
    };
}

// The 37 caption-bearing keys, in the order calcMode*Gui walks `keys`.
const tam_buttons = .{
    &widgets.btn21, &widgets.btn22, &widgets.btn23, &widgets.btn24, &widgets.btn25, &widgets.btn26,
    &widgets.btn31, &widgets.btn32, &widgets.btn33, &widgets.btn34, &widgets.btn35, &widgets.btn36,
    &widgets.btn41, &widgets.btn42, &widgets.btn43, &widgets.btn44, &widgets.btn45,
    &widgets.btn51, &widgets.btn52, &widgets.btn53, &widgets.btn54, &widgets.btn55,
    &widgets.btn61, &widgets.btn62, &widgets.btn63, &widgets.btn64, &widgets.btn65,
    &widgets.btn71, &widgets.btn72, &widgets.btn73, &widgets.btn74, &widgets.btn75,
    &widgets.btn81, &widgets.btn82, &widgets.btn83, &widgets.btn84, &widgets.btn85,
};

// All 43 visible keys shown in TAM mode (rows 1..8).
const tam_show = .{
    &widgets.btn11, &widgets.btn12, &widgets.btn13, &widgets.btn14, &widgets.btn15, &widgets.btn16,
    &widgets.btn21, &widgets.btn22, &widgets.btn23, &widgets.btn24, &widgets.btn25, &widgets.btn26,
    &widgets.btn31, &widgets.btn32, &widgets.btn33, &widgets.btn34, &widgets.btn35, &widgets.btn36,
    &widgets.btn41, &widgets.btn42, &widgets.btn43, &widgets.btn44, &widgets.btn45,
    &widgets.btn51, &widgets.btn52, &widgets.btn53, &widgets.btn54, &widgets.btn55,
    &widgets.btn61, &widgets.btn62, &widgets.btn63, &widgets.btn64, &widgets.btn65,
    &widgets.btn71, &widgets.btn72, &widgets.btn73, &widgets.btn74, &widgets.btn75,
    &widgets.btn81, &widgets.btn82, &widgets.btn83, &widgets.btn84, &widgets.btn85,
};

pub fn calcModeTamGui() void {
    var keys: [*]const calcKey_t = if (getSystemFlag(FLAG_USER)) &kbd_usr else kbdStd();

    hideAllWidgets();

    inline for (tam_buttons) |btn| {
        label.labelCaptionTam(&keys[0], btn.*);
        keys += 1;
    }

    hideAllWidgets();

    inline for (tam_show) |btn| {
        gtk_widget_show(btn.*);
    }

    moveLabels();
}
