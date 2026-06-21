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
extern fn gtk_widget_hide(widget: ?*anyopaque) void;
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

const hide_all = .{
        &widgets.lblFKey2, &widgets.lblGKey2, &widgets.btn11, &widgets.btn12, &widgets.btn13, &widgets.btn14,
        &widgets.btn15, &widgets.btn16, &widgets.btn21, &widgets.btn22, &widgets.btn23, &widgets.btn24,
        &widgets.btn25, &widgets.btn26, &widgets.btn21A, &widgets.btn22A, &widgets.btn23A, &widgets.btn24A,
        &widgets.btn25A, &widgets.btn26A, &widgets.lbl21F, &widgets.lbl21G, &widgets.lbl21L, &widgets.lbl22F,
        &widgets.lbl22G, &widgets.lbl22L, &widgets.lbl23F, &widgets.lbl23G, &widgets.lbl23L, &widgets.lbl24F,
        &widgets.lbl24G, &widgets.lbl24L, &widgets.lbl25F, &widgets.lbl25G, &widgets.lbl25L, &widgets.lbl26F,
        &widgets.lbl26G, &widgets.lbl26L, &widgets.lbl21Gr, &widgets.lbl22Gr, &widgets.lbl23Gr, &widgets.lbl24Gr,
        &widgets.lbl25Gr, &widgets.lbl26Gr, &widgets.lbl21Fa, &widgets.lbl22Fa, &widgets.lbl23Fa, &widgets.lbl24Fa,
        &widgets.lbl25Fa, &widgets.lbl26Fa, &widgets.btn31, &widgets.btn32, &widgets.btn33, &widgets.btn34,
        &widgets.btn35, &widgets.btn36, &widgets.btn31A, &widgets.btn32A, &widgets.btn33A, &widgets.btn34A,
        &widgets.btn35A, &widgets.btn36A, &widgets.lbl31F, &widgets.lbl31G, &widgets.lbl31L, &widgets.lbl32F,
        &widgets.lbl32G, &widgets.lbl32L, &widgets.lbl33F, &widgets.lbl33G, &widgets.lbl33L, &widgets.lbl34F,
        &widgets.lbl34G, &widgets.lbl34L, &widgets.lbl35F, &widgets.lbl35G, &widgets.lbl35L, &widgets.lbl36F,
        &widgets.lbl36G, &widgets.lbl36L, &widgets.lbl31Gr, &widgets.lbl32Gr, &widgets.lbl33Gr, &widgets.lbl34Gr,
        &widgets.lbl35Gr, &widgets.lbl36Gr, &widgets.lbl31Fa, &widgets.lbl32Fa, &widgets.lbl33Fa, &widgets.lbl34Fa,
        &widgets.lbl35Fa, &widgets.lbl36Fa, &widgets.btn41, &widgets.btn42, &widgets.btn43, &widgets.btn44,
        &widgets.btn45, &widgets.btn42A, &widgets.btn43A, &widgets.btn44A, &widgets.lbl41F, &widgets.lbl41G,
        &widgets.lbl41L, &widgets.lbl42F, &widgets.lbl42G, &widgets.lbl42L, &widgets.lbl43F, &widgets.lbl43G,
        &widgets.lbl43L, &widgets.lbl44F, &widgets.lbl44G, &widgets.lbl44L, &widgets.lbl45F, &widgets.lbl45G,
        &widgets.lbl45L, &widgets.lbl41Gr, &widgets.lbl42Gr, &widgets.lbl43Gr, &widgets.lbl44Gr, &widgets.lbl45Gr,
        &widgets.lbl41Fa, &widgets.lbl42Fa, &widgets.lbl43Fa, &widgets.lbl44Fa, &widgets.lbl45Fa, &widgets.btn51,
        &widgets.btn52, &widgets.btn53, &widgets.btn54, &widgets.btn55, &widgets.btn52A, &widgets.btn53A,
        &widgets.btn54A, &widgets.btn55A, &widgets.lbl51F, &widgets.lbl51G, &widgets.lbl51L, &widgets.lbl52F,
        &widgets.lbl52G, &widgets.lbl52L, &widgets.lbl53F, &widgets.lbl53G, &widgets.lbl53L, &widgets.lbl54F,
        &widgets.lbl54G, &widgets.lbl54L, &widgets.lbl55F, &widgets.lbl55G, &widgets.lbl55L, &widgets.lbl51Gr,
        &widgets.lbl52Gr, &widgets.lbl53Gr, &widgets.lbl54Gr, &widgets.lbl55Gr, &widgets.lbl51Fa, &widgets.lbl52Fa,
        &widgets.lbl53Fa, &widgets.lbl54Fa, &widgets.lbl55Fa, &widgets.btn61, &widgets.btn62, &widgets.btn63,
        &widgets.btn64, &widgets.btn65, &widgets.btn62A, &widgets.btn63A, &widgets.btn64A, &widgets.btn65A,
        &widgets.lbl61F, &widgets.lbl61G, &widgets.lbl61L, &widgets.lbl62F, &widgets.lbl62G, &widgets.lbl62L,
        &widgets.lbl63F, &widgets.lbl63G, &widgets.lbl63L, &widgets.lbl64F, &widgets.lbl64G, &widgets.lbl64L,
        &widgets.lbl65F, &widgets.lbl65G, &widgets.lbl65L, &widgets.lbl61Gr, &widgets.lbl62Gr, &widgets.lbl63Gr,
        &widgets.lbl64Gr, &widgets.lbl65Gr, &widgets.lbl61Fa, &widgets.lbl62Fa, &widgets.lbl63Fa, &widgets.lbl64Fa,
        &widgets.lbl65Fa, &widgets.btn71, &widgets.btn72, &widgets.btn73, &widgets.btn74, &widgets.btn75,
        &widgets.btn71A, &widgets.btn72A, &widgets.btn73A, &widgets.btn74A, &widgets.btn75A, &widgets.lbl71F,
        &widgets.lbl71G, &widgets.lbl71L, &widgets.lbl72F, &widgets.lbl72G, &widgets.lbl72L, &widgets.lbl73F,
        &widgets.lbl73G, &widgets.lbl73L, &widgets.lbl74F, &widgets.lbl74G, &widgets.lbl74L, &widgets.lbl75F,
        &widgets.lbl75G, &widgets.lbl75L, &widgets.lbl71Gr, &widgets.lbl72Gr, &widgets.lbl73Gr, &widgets.lbl74Gr,
        &widgets.lbl75Gr, &widgets.lbl71Fa, &widgets.lbl72Fa, &widgets.lbl73Fa, &widgets.lbl74Fa, &widgets.lbl75Fa,
        &widgets.btn81, &widgets.btn82, &widgets.btn83, &widgets.btn84, &widgets.btn85, &widgets.btn82A,
        &widgets.btn83A, &widgets.btn84A, &widgets.btn85A, &widgets.lbl81F, &widgets.lbl81G, &widgets.lbl81L,
        &widgets.lbl82F, &widgets.lbl82G, &widgets.lbl82L, &widgets.lbl83F, &widgets.lbl83G, &widgets.lbl83L,
        &widgets.lbl84F, &widgets.lbl84G, &widgets.lbl84L, &widgets.lbl85F, &widgets.lbl85G, &widgets.lbl85L,
        &widgets.lbl81Gr, &widgets.lbl82Gr, &widgets.lbl83Gr, &widgets.lbl84Gr, &widgets.lbl85Gr, &widgets.lbl82Fa,
        &widgets.lbl83Fa, &widgets.lbl84Fa, &widgets.lbl85Fa,
};

/// gtkGui.c hideAllWidgets: hide every key button and label in the matrix.
pub fn hideAllWidgets() void {
    inline for (hide_all) |w| {
        gtk_widget_hide(w.*);
    }
}

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
