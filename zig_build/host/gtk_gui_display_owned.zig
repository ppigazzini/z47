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

pub fn calcModeNormalGui() void {
    var keys: [*]const calcKey_t = if (getSystemFlag(FLAG_USER)) &kbd_usr else kbdStd();

    hideAllWidgets();
    gtk_widget_show(widgets.lblFKey2);
    gtk_widget_show(widgets.lblGKey2);
    label.labelCaptionNormal(&keys[0], widgets.btn21, widgets.lbl21F, widgets.lbl21G, widgets.lbl21L);
    keys += 1;
    label.labelCaptionNormal(&keys[0], widgets.btn22, widgets.lbl22F, widgets.lbl22G, widgets.lbl22L);
    keys += 1;
    label.labelCaptionNormal(&keys[0], widgets.btn23, widgets.lbl23F, widgets.lbl23G, widgets.lbl23L);
    keys += 1;
    label.labelCaptionNormal(&keys[0], widgets.btn24, widgets.lbl24F, widgets.lbl24G, widgets.lbl24L);
    keys += 1;
    label.labelCaptionNormal(&keys[0], widgets.btn25, widgets.lbl25F, widgets.lbl25G, widgets.lbl25L);
    keys += 1;
    label.labelCaptionNormal(&keys[0], widgets.btn26, widgets.lbl26F, widgets.lbl26G, widgets.lbl26L);
    keys += 1;
    label.labelCaptionNormal(&keys[0], widgets.btn31, widgets.lbl31F, widgets.lbl31G, widgets.lbl31L);
    keys += 1;
    label.labelCaptionNormal(&keys[0], widgets.btn32, widgets.lbl32F, widgets.lbl32G, widgets.lbl32L);
    keys += 1;
    label.labelCaptionNormal(&keys[0], widgets.btn33, widgets.lbl33F, widgets.lbl33G, widgets.lbl33L);
    keys += 1;
    label.labelCaptionNormal(&keys[0], widgets.btn34, widgets.lbl34F, widgets.lbl34G, widgets.lbl34L);
    keys += 1;
    label.labelCaptionNormal(&keys[0], widgets.btn35, widgets.lbl35F, widgets.lbl35G, widgets.lbl35L);
    keys += 1;
    label.labelCaptionNormal(&keys[0], widgets.btn36, widgets.lbl36F, widgets.lbl36G, widgets.lbl36L);
    keys += 1;
    label.labelCaptionNormal(&keys[0], widgets.btn41, widgets.lbl41F, widgets.lbl41G, widgets.lbl41L);
    keys += 1;
    label.labelCaptionNormal(&keys[0], widgets.btn42, widgets.lbl42F, widgets.lbl42G, widgets.lbl42L);
    keys += 1;
    label.labelCaptionNormal(&keys[0], widgets.btn43, widgets.lbl43F, widgets.lbl43G, widgets.lbl43L);
    keys += 1;
    label.labelCaptionNormal(&keys[0], widgets.btn44, widgets.lbl44F, widgets.lbl44G, widgets.lbl44L);
    keys += 1;
    label.labelCaptionNormal(&keys[0], widgets.btn45, widgets.lbl45F, widgets.lbl45G, widgets.lbl45L);
    keys += 1;
    label.labelCaptionNormal(&keys[0], widgets.btn51, widgets.lbl51F, widgets.lbl51G, widgets.lbl51L);
    keys += 1;
    label.labelCaptionNormal(&keys[0], widgets.btn52, widgets.lbl52F, widgets.lbl52G, widgets.lbl52L);
    keys += 1;
    label.labelCaptionNormal(&keys[0], widgets.btn53, widgets.lbl53F, widgets.lbl53G, widgets.lbl53L);
    keys += 1;
    label.labelCaptionNormal(&keys[0], widgets.btn54, widgets.lbl54F, widgets.lbl54G, widgets.lbl54L);
    keys += 1;
    label.labelCaptionNormal(&keys[0], widgets.btn55, widgets.lbl55F, widgets.lbl55G, widgets.lbl55L);
    keys += 1;
    label.labelCaptionNormal(&keys[0], widgets.btn61, widgets.lbl61F, widgets.lbl61G, widgets.lbl61L);
    keys += 1;
    label.labelCaptionNormal(&keys[0], widgets.btn62, widgets.lbl62F, widgets.lbl62G, widgets.lbl62L);
    keys += 1;
    label.labelCaptionNormal(&keys[0], widgets.btn63, widgets.lbl63F, widgets.lbl63G, widgets.lbl63L);
    keys += 1;
    label.labelCaptionNormal(&keys[0], widgets.btn64, widgets.lbl64F, widgets.lbl64G, widgets.lbl64L);
    keys += 1;
    label.labelCaptionNormal(&keys[0], widgets.btn65, widgets.lbl65F, widgets.lbl65G, widgets.lbl65L);
    keys += 1;
    label.labelCaptionNormal(&keys[0], widgets.btn71, widgets.lbl71F, widgets.lbl71G, widgets.lbl71L);
    keys += 1;
    label.labelCaptionNormal(&keys[0], widgets.btn72, widgets.lbl72F, widgets.lbl72G, widgets.lbl72L);
    keys += 1;
    label.labelCaptionNormal(&keys[0], widgets.btn73, widgets.lbl73F, widgets.lbl73G, widgets.lbl73L);
    keys += 1;
    label.labelCaptionNormal(&keys[0], widgets.btn74, widgets.lbl74F, widgets.lbl74G, widgets.lbl74L);
    keys += 1;
    label.labelCaptionNormal(&keys[0], widgets.btn75, widgets.lbl75F, widgets.lbl75G, widgets.lbl75L);
    keys += 1;
    label.labelCaptionNormal(&keys[0], widgets.btn81, widgets.lbl81F, widgets.lbl81G, widgets.lbl81L);
    keys += 1;
    label.labelCaptionNormal(&keys[0], widgets.btn82, widgets.lbl82F, widgets.lbl82G, widgets.lbl82L);
    keys += 1;
    label.labelCaptionNormal(&keys[0], widgets.btn83, widgets.lbl83F, widgets.lbl83G, widgets.lbl83L);
    keys += 1;
    label.labelCaptionNormal(&keys[0], widgets.btn84, widgets.lbl84F, widgets.lbl84G, widgets.lbl84L);
    keys += 1;
    label.labelCaptionNormal(&keys[0], widgets.btn85, widgets.lbl85F, widgets.lbl85G, widgets.lbl85L);
    keys += 1;
    gtk_widget_show(widgets.btn11);
    gtk_widget_show(widgets.btn12);
    gtk_widget_show(widgets.btn13);
    gtk_widget_show(widgets.btn14);
    gtk_widget_show(widgets.btn15);
    gtk_widget_show(widgets.btn16);
    gtk_widget_show(widgets.btn21);
    gtk_widget_show(widgets.btn22);
    gtk_widget_show(widgets.btn23);
    gtk_widget_show(widgets.btn24);
    gtk_widget_show(widgets.btn25);
    gtk_widget_show(widgets.btn26);
    gtk_widget_show(widgets.lbl21F);
    gtk_widget_show(widgets.lbl21G);
    gtk_widget_show(widgets.lbl21L);
    gtk_widget_show(widgets.lbl22F);
    gtk_widget_show(widgets.lbl22G);
    gtk_widget_show(widgets.lbl22L);
    gtk_widget_show(widgets.lbl23F);
    gtk_widget_show(widgets.lbl23G);
    gtk_widget_show(widgets.lbl23L);
    gtk_widget_show(widgets.lbl24F);
    gtk_widget_show(widgets.lbl24G);
    gtk_widget_show(widgets.lbl24L);
    gtk_widget_show(widgets.lbl25F);
    gtk_widget_show(widgets.lbl25G);
    gtk_widget_show(widgets.lbl25L);
    gtk_widget_show(widgets.lbl26L);
    gtk_widget_show(widgets.lbl26F);
    gtk_widget_show(widgets.lbl26G);
    gtk_widget_show(widgets.btn31);
    gtk_widget_show(widgets.btn32);
    gtk_widget_show(widgets.btn33);
    gtk_widget_show(widgets.btn34);
    gtk_widget_show(widgets.btn35);
    gtk_widget_show(widgets.btn36);
    gtk_widget_show(widgets.lbl31F);
    gtk_widget_show(widgets.lbl31G);
    gtk_widget_show(widgets.lbl31L);
    gtk_widget_show(widgets.lbl32F);
    gtk_widget_show(widgets.lbl32G);
    gtk_widget_show(widgets.lbl32L);
    gtk_widget_show(widgets.lbl33F);
    gtk_widget_show(widgets.lbl33G);
    gtk_widget_show(widgets.lbl33L);
    gtk_widget_show(widgets.lbl34F);
    gtk_widget_show(widgets.lbl34G);
    gtk_widget_show(widgets.lbl34L);
    gtk_widget_show(widgets.lbl35L);
    gtk_widget_show(widgets.lbl36L);
    gtk_widget_show(widgets.lbl35F);
    gtk_widget_show(widgets.lbl35G);
    gtk_widget_show(widgets.lbl36F);
    gtk_widget_show(widgets.lbl36G);
    gtk_widget_show(widgets.btn41);
    gtk_widget_show(widgets.btn42);
    gtk_widget_show(widgets.btn43);
    gtk_widget_show(widgets.btn44);
    gtk_widget_show(widgets.btn45);
    gtk_widget_show(widgets.lbl41F);
    gtk_widget_show(widgets.lbl41G);
    gtk_widget_show(widgets.lbl42F);
    gtk_widget_show(widgets.lbl42G);
    gtk_widget_show(widgets.lbl42L);
    gtk_widget_show(widgets.lbl43F);
    gtk_widget_show(widgets.lbl43G);
    gtk_widget_show(widgets.lbl43L);
    gtk_widget_show(widgets.lbl44F);
    gtk_widget_show(widgets.lbl44G);
    gtk_widget_show(widgets.lbl44L);
    gtk_widget_show(widgets.lbl45F);
    gtk_widget_show(widgets.lbl45G);
    gtk_widget_show(widgets.btn51);
    gtk_widget_show(widgets.btn52);
    gtk_widget_show(widgets.btn53);
    gtk_widget_show(widgets.btn54);
    gtk_widget_show(widgets.btn55);
    gtk_widget_show(widgets.lbl51F);
    gtk_widget_show(widgets.lbl51G);
    gtk_widget_show(widgets.lbl51L);
    gtk_widget_show(widgets.lbl52F);
    gtk_widget_show(widgets.lbl52G);
    gtk_widget_show(widgets.lbl52L);
    gtk_widget_show(widgets.lbl53F);
    gtk_widget_show(widgets.lbl53G);
    gtk_widget_show(widgets.lbl53L);
    gtk_widget_show(widgets.lbl54F);
    gtk_widget_show(widgets.lbl54G);
    gtk_widget_show(widgets.lbl54L);
    gtk_widget_show(widgets.lbl55F);
    gtk_widget_show(widgets.lbl55G);
    gtk_widget_show(widgets.lbl55L);
    gtk_widget_show(widgets.btn61);
    gtk_widget_show(widgets.btn62);
    gtk_widget_show(widgets.btn63);
    gtk_widget_show(widgets.btn64);
    gtk_widget_show(widgets.btn65);
    gtk_widget_show(widgets.lbl61F);
    gtk_widget_show(widgets.lbl61G);
    gtk_widget_show(widgets.lbl61L);
    gtk_widget_show(widgets.lbl62F);
    gtk_widget_show(widgets.lbl62G);
    gtk_widget_show(widgets.lbl62L);
    gtk_widget_show(widgets.lbl63F);
    gtk_widget_show(widgets.lbl63G);
    gtk_widget_show(widgets.lbl63L);
    gtk_widget_show(widgets.lbl64F);
    gtk_widget_show(widgets.lbl64G);
    gtk_widget_show(widgets.lbl64L);
    gtk_widget_show(widgets.lbl65F);
    gtk_widget_show(widgets.lbl65G);
    gtk_widget_show(widgets.lbl65L);
    gtk_widget_show(widgets.btn71);
    gtk_widget_show(widgets.btn72);
    gtk_widget_show(widgets.btn73);
    gtk_widget_show(widgets.btn74);
    gtk_widget_show(widgets.btn75);
    if (calcModel != USER_C47 and calcModel != USER_DM42) {
    gtk_widget_show(widgets.lbl71F);
    gtk_widget_show(widgets.lbl71G);
    }
    gtk_widget_show(widgets.lbl71L);
    gtk_widget_show(widgets.lbl72F);
    gtk_widget_show(widgets.lbl72G);
    gtk_widget_show(widgets.lbl72L);
    gtk_widget_show(widgets.lbl73F);
    gtk_widget_show(widgets.lbl73G);
    gtk_widget_show(widgets.lbl73L);
    gtk_widget_show(widgets.lbl74F);
    gtk_widget_show(widgets.lbl74G);
    gtk_widget_show(widgets.lbl74L);
    gtk_widget_show(widgets.lbl75F);
    gtk_widget_show(widgets.lbl75G);
    gtk_widget_show(widgets.lbl75L);
    gtk_widget_show(widgets.btn81);
    gtk_widget_show(widgets.btn82);
    gtk_widget_show(widgets.btn83);
    gtk_widget_show(widgets.btn84);
    gtk_widget_show(widgets.btn85);
    gtk_widget_show(widgets.lbl81F);
    gtk_widget_show(widgets.lbl81G);
    gtk_widget_show(widgets.lbl81L);
    gtk_widget_show(widgets.lbl82F);
    gtk_widget_show(widgets.lbl82G);
    gtk_widget_show(widgets.lbl82L);
    gtk_widget_show(widgets.lbl83F);
    gtk_widget_show(widgets.lbl83G);
    gtk_widget_show(widgets.lbl83L);
    gtk_widget_show(widgets.lbl84F);
    gtk_widget_show(widgets.lbl84G);
    gtk_widget_show(widgets.lbl84L);
    gtk_widget_show(widgets.lbl85F);
    gtk_widget_show(widgets.lbl85G);
    gtk_widget_show(widgets.lbl85L);
    moveLabels();
}

pub fn calcModeAimGui() void {
    var keys: [*]const calcKey_t = if (getSystemFlag(FLAG_USER)) &kbd_usr else kbdStd();

    hideAllWidgets();
    label.labelCaptionAimFa(&keys[0], widgets.lbl21Fa);
    label.labelCaptionAim(&keys[0], widgets.btn21A, widgets.lbl21Gr, widgets.lbl21L);
    keys += 1;
    label.labelCaptionAimFa(&keys[0], widgets.lbl22Fa);
    label.labelCaptionAim(&keys[0], widgets.btn22A, widgets.lbl22Gr, widgets.lbl22L);
    keys += 1;
    label.labelCaptionAimFa(&keys[0], widgets.lbl23Fa);
    label.labelCaptionAim(&keys[0], widgets.btn23A, widgets.lbl23Gr, widgets.lbl23L);
    keys += 1;
    label.labelCaptionAimFa(&keys[0], widgets.lbl24Fa);
    label.labelCaptionAim(&keys[0], widgets.btn24A, widgets.lbl24Gr, widgets.lbl24L);
    keys += 1;
    label.labelCaptionAimFa(&keys[0], widgets.lbl25Fa);
    label.labelCaptionAim(&keys[0], widgets.btn25A, widgets.lbl25Gr, widgets.lbl25L);
    keys += 1;
    label.labelCaptionAimFa(&keys[0], widgets.lbl26Fa);
    label.labelCaptionAim(&keys[0], widgets.btn26A, widgets.lbl26Gr, widgets.lbl26L);
    keys += 1;
    label.labelCaptionAimFa(&keys[0], widgets.lbl31Fa);
    label.labelCaptionAim(&keys[0], widgets.btn31A, widgets.lbl31Gr, widgets.lbl31L);
    keys += 1;
    label.labelCaptionAimFa(&keys[0], widgets.lbl32Fa);
    label.labelCaptionAim(&keys[0], widgets.btn32A, widgets.lbl32Gr, widgets.lbl32L);
    keys += 1;
    label.labelCaptionAimFa(&keys[0], widgets.lbl33Fa);
    label.labelCaptionAim(&keys[0], widgets.btn33A, widgets.lbl33Gr, widgets.lbl33L);
    keys += 1;
    label.labelCaptionAimFa(&keys[0], widgets.lbl34Fa);
    label.labelCaptionAim(&keys[0], widgets.btn34A, widgets.lbl34Gr, widgets.lbl34L);
    keys += 1;
    label.labelCaptionAimFa(&keys[0], widgets.lbl35Fa);
    label.labelCaptionAim(&keys[0], widgets.btn35A, widgets.lbl35Gr, widgets.lbl35L);
    keys += 1;
    label.labelCaptionAimFa(&keys[0], widgets.lbl36Fa);
    label.labelCaptionAim(&keys[0], widgets.btn36A, widgets.lbl36Gr, widgets.lbl36L);
    keys += 1;
    label.labelCaptionAimFa(&keys[0], widgets.lbl41Fa);
    label.labelCaptionAim(&keys[0], widgets.btn41, widgets.lbl41Gr, widgets.lbl41L);
    keys += 1;
    label.labelCaptionAimFa(&keys[0], widgets.lbl42Fa);
    label.labelCaptionAim(&keys[0], widgets.btn42A, widgets.lbl42Gr, widgets.lbl42L);
    keys += 1;
    label.labelCaptionAimFa(&keys[0], widgets.lbl43Fa);
    label.labelCaptionAim(&keys[0], widgets.btn43A, widgets.lbl43Gr, widgets.lbl43L);
    keys += 1;
    label.labelCaptionAimFa(&keys[0], widgets.lbl44Fa);
    label.labelCaptionAim(&keys[0], widgets.btn44A, widgets.lbl44Gr, widgets.lbl44L);
    keys += 1;
    label.labelCaptionAimFa(&keys[0], widgets.lbl45Fa);
    label.labelCaptionAim(&keys[0], widgets.btn45, widgets.lbl45Gr, widgets.lbl45L);
    keys += 1;
    label.labelCaptionAimFa(&keys[0], widgets.lbl51Fa);
    label.labelCaptionAim(&keys[0], widgets.btn51, widgets.lbl51Gr, widgets.lbl51L);
    keys += 1;
    label.labelCaptionAimFa(&keys[0], widgets.lbl52Fa);
    label.labelCaptionAim(&keys[0], widgets.btn52A, widgets.lbl52Gr, widgets.lbl52L);
    keys += 1;
    label.labelCaptionAimFa(&keys[0], widgets.lbl53Fa);
    label.labelCaptionAim(&keys[0], widgets.btn53A, widgets.lbl53Gr, widgets.lbl53L);
    keys += 1;
    label.labelCaptionAimFa(&keys[0], widgets.lbl54Fa);
    label.labelCaptionAim(&keys[0], widgets.btn54A, widgets.lbl54Gr, widgets.lbl54L);
    keys += 1;
    label.labelCaptionAimFa(&keys[0], widgets.lbl55Fa);
    label.labelCaptionAim(&keys[0], widgets.btn55A, widgets.lbl55Gr, widgets.lbl55L);
    keys += 1;
    label.labelCaptionAimFa(&keys[0], widgets.lbl61Fa);
    label.labelCaptionAim(&keys[0], widgets.btn61, widgets.lbl61Gr, widgets.lbl61L);
    keys += 1;
    label.labelCaptionAimFa(&keys[0], widgets.lbl62Fa);
    label.labelCaptionAim(&keys[0], widgets.btn62A, widgets.lbl62Gr, widgets.lbl62L);
    keys += 1;
    label.labelCaptionAimFa(&keys[0], widgets.lbl63Fa);
    label.labelCaptionAim(&keys[0], widgets.btn63A, widgets.lbl63Gr, widgets.lbl63L);
    keys += 1;
    label.labelCaptionAimFa(&keys[0], widgets.lbl64Fa);
    label.labelCaptionAim(&keys[0], widgets.btn64A, widgets.lbl64Gr, widgets.lbl64L);
    keys += 1;
    label.labelCaptionAimFa(&keys[0], widgets.lbl65Fa);
    label.labelCaptionAim(&keys[0], widgets.btn65A, widgets.lbl65Gr, widgets.lbl65L);
    keys += 1;
    label.labelCaptionAimFa(&keys[0], widgets.lbl71Fa);
    label.labelCaptionAim(&keys[0], widgets.btn71A, widgets.lbl71Gr, widgets.lbl71L);
    keys += 1;
    label.labelCaptionAimFa(&keys[0], widgets.lbl72Fa);
    label.labelCaptionAim(&keys[0], widgets.btn72A, widgets.lbl72Gr, widgets.lbl72L);
    keys += 1;
    label.labelCaptionAimFa(&keys[0], widgets.lbl73Fa);
    label.labelCaptionAim(&keys[0], widgets.btn73A, widgets.lbl73Gr, widgets.lbl73L);
    keys += 1;
    label.labelCaptionAimFa(&keys[0], widgets.lbl74Fa);
    label.labelCaptionAim(&keys[0], widgets.btn74A, widgets.lbl74Gr, widgets.lbl74L);
    keys += 1;
    label.labelCaptionAimFa(&keys[0], widgets.lbl75Fa);
    label.labelCaptionAim(&keys[0], widgets.btn75A, widgets.lbl75Gr, widgets.lbl75L);
    keys += 1;
    label.labelCaptionAim(&keys[0], widgets.btn81, widgets.lbl81Gr, widgets.lbl81L);
    keys += 1;
    label.labelCaptionAimFa(&keys[0], widgets.lbl82Fa);
    label.labelCaptionAim(&keys[0], widgets.btn82A, widgets.lbl82Gr, widgets.lbl82L);
    keys += 1;
    label.labelCaptionAimFa(&keys[0], widgets.lbl83Fa);
    label.labelCaptionAim(&keys[0], widgets.btn83A, widgets.lbl83Gr, widgets.lbl83L);
    keys += 1;
    label.labelCaptionAimFa(&keys[0], widgets.lbl84Fa);
    label.labelCaptionAim(&keys[0], widgets.btn84A, widgets.lbl84Gr, widgets.lbl84L);
    keys += 1;
    label.labelCaptionAimFa(&keys[0], widgets.lbl85Fa);
    label.labelCaptionAim(&keys[0], widgets.btn85A, widgets.lbl85Gr, widgets.lbl85L);
    keys += 1;
    gtk_widget_show(widgets.btn11);
    gtk_widget_show(widgets.btn12);
    gtk_widget_show(widgets.btn13);
    gtk_widget_show(widgets.btn14);
    gtk_widget_show(widgets.btn15);
    gtk_widget_show(widgets.btn16);
    gtk_widget_show(widgets.btn21A);
    gtk_widget_show(widgets.btn22A);
    gtk_widget_show(widgets.btn23A);
    gtk_widget_show(widgets.btn24A);
    gtk_widget_show(widgets.btn25A);
    gtk_widget_show(widgets.btn26A);
    gtk_widget_show(widgets.lbl21Fa);
    gtk_widget_show(widgets.lbl22Fa);
    gtk_widget_show(widgets.lbl23Fa);
    gtk_widget_show(widgets.lbl24Fa);
    gtk_widget_show(widgets.lbl25Fa);
    gtk_widget_show(widgets.lbl26Fa);
    gtk_widget_show(widgets.lbl21Gr);
    gtk_widget_show(widgets.lbl22Gr);
    gtk_widget_show(widgets.lbl23Gr);
    gtk_widget_show(widgets.lbl24Gr);
    gtk_widget_show(widgets.lbl25Gr);
    gtk_widget_show(widgets.lbl26Gr);
    gtk_widget_show(widgets.btn31A);
    gtk_widget_show(widgets.btn32A);
    gtk_widget_show(widgets.btn33A);
    gtk_widget_show(widgets.btn34A);
    gtk_widget_show(widgets.btn35A);
    gtk_widget_show(widgets.btn36A);
    gtk_widget_show(widgets.lbl31Fa);
    gtk_widget_show(widgets.lbl32Fa);
    gtk_widget_show(widgets.lbl33Fa);
    gtk_widget_show(widgets.lbl34Fa);
    gtk_widget_show(widgets.lbl35Fa);
    gtk_widget_show(widgets.lbl36Fa);
    gtk_widget_show(widgets.lbl31Gr);
    gtk_widget_show(widgets.lbl32Gr);
    gtk_widget_show(widgets.lbl33Gr);
    gtk_widget_show(widgets.lbl34Gr);
    gtk_widget_show(widgets.lbl35Gr);
    gtk_widget_show(widgets.lbl36Gr);
    gtk_widget_show(widgets.btn41);
    gtk_widget_show(widgets.btn42A);
    gtk_widget_show(widgets.btn43A);
    gtk_widget_show(widgets.btn44A);
    gtk_widget_show(widgets.btn45);
    gtk_widget_show(widgets.lbl41Fa);
    gtk_widget_show(widgets.lbl42Fa);
    gtk_widget_show(widgets.lbl43Fa);
    gtk_widget_show(widgets.lbl44Fa);
    gtk_widget_show(widgets.lbl41Gr);
    gtk_widget_show(widgets.lbl42Gr);
    gtk_widget_show(widgets.lbl43Gr);
    gtk_widget_show(widgets.lbl44Gr);
    gtk_widget_show(widgets.lbl45Fa);
    gtk_widget_show(widgets.btn51);
    gtk_widget_show(widgets.btn52A);
    gtk_widget_show(widgets.btn53A);
    gtk_widget_show(widgets.btn54A);
    gtk_widget_show(widgets.btn55A);
    gtk_widget_show(widgets.lbl51L);
    gtk_widget_show(widgets.lbl51Fa);
    gtk_widget_show(widgets.lbl52Fa);
    gtk_widget_show(widgets.lbl53Fa);
    gtk_widget_show(widgets.lbl54Fa);
    gtk_widget_show(widgets.lbl55Fa);
    gtk_widget_show(widgets.lbl51Gr);
    gtk_widget_show(widgets.lbl52Gr);
    gtk_widget_show(widgets.lbl53Gr);
    gtk_widget_show(widgets.lbl54Gr);
    gtk_widget_show(widgets.lbl55Gr);
    gtk_widget_show(widgets.btn61);
    gtk_widget_show(widgets.btn62A);
    gtk_widget_show(widgets.btn63A);
    gtk_widget_show(widgets.btn64A);
    gtk_widget_show(widgets.btn65A);
    gtk_widget_show(widgets.lbl61Fa);
    gtk_widget_show(widgets.lbl62Fa);
    gtk_widget_show(widgets.lbl63Fa);
    gtk_widget_show(widgets.lbl64Fa);
    gtk_widget_show(widgets.lbl65Fa);
    gtk_widget_show(widgets.lbl61Gr);
    gtk_widget_show(widgets.lbl62Gr);
    gtk_widget_show(widgets.lbl63Gr);
    gtk_widget_show(widgets.lbl64Gr);
    gtk_widget_show(widgets.lbl65Gr);
    gtk_widget_show(widgets.btn71);
    gtk_widget_show(widgets.btn71A);
    gtk_widget_show(widgets.btn72A);
    gtk_widget_show(widgets.btn73A);
    gtk_widget_show(widgets.btn74A);
    gtk_widget_show(widgets.btn75A);
    gtk_widget_show(widgets.lbl71Fa);
    gtk_widget_show(widgets.lbl72Fa);
    gtk_widget_show(widgets.lbl73Fa);
    gtk_widget_show(widgets.lbl74Fa);
    gtk_widget_show(widgets.lbl75Fa);
    gtk_widget_show(widgets.lbl71Gr);
    gtk_widget_show(widgets.lbl72Gr);
    gtk_widget_show(widgets.lbl73Gr);
    gtk_widget_show(widgets.lbl74Gr);
    gtk_widget_show(widgets.lbl75Gr);
    gtk_widget_show(widgets.btn81);
    gtk_widget_show(widgets.btn82A);
    gtk_widget_show(widgets.btn83A);
    gtk_widget_show(widgets.btn84A);
    gtk_widget_show(widgets.btn85A);
    gtk_widget_show(widgets.lbl81F);
    gtk_widget_show(widgets.lbl81G);
    gtk_widget_show(widgets.lbl82Fa);
    gtk_widget_show(widgets.lbl83Fa);
    gtk_widget_show(widgets.lbl84Fa);
    gtk_widget_show(widgets.lbl85Fa);
    gtk_widget_show(widgets.lbl82Gr);
    gtk_widget_show(widgets.lbl83Gr);
    gtk_widget_show(widgets.lbl84Gr);
    gtk_widget_show(widgets.lbl85Gr);
    moveLabels();
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
