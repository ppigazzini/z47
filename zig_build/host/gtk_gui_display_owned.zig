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
const CM_AIM: u8 = 1;

// Label-geometry macros (defines.h) used by moveLabels.
const X_LEFT_LANDSCAPE: i32 = 544;
const X_LEFT_PORTRAIT: i32 = 45;
const Y_TOP_LANDSCAPE: i32 = 30;
const Y_TOP_PORTRAIT: i32 = 376;
const DELTA_KEYS_X: i32 = 78;
const DELTA_KEYS_Y: i32 = 74;
const KEY_WIDTH_1: i32 = 47;
const KEY_WIDTH_2: i32 = 56;
const GAP: i32 = 6;
const Y_OFFSET_Aim: i32 = 25;
const LARGE_KEY_SPACING_1: i32 = 18;
const LARGE_KEY_SPACING_2: i32 = 17;

const GtkRequisition = extern struct {
    width: c_int,
    height: c_int,
};

extern var calcMode: u8;
extern var calcLandscape: bool;
extern fn gtk_widget_get_preferred_size(widget: ?*anyopaque, minimum: ?*GtkRequisition, natural: ?*GtkRequisition) void;
extern fn gtk_fixed_move(fixed: ?*anyopaque, widget: ?*anyopaque, x: c_int, y: c_int) void;

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

pub fn moveLabels() void {
    var xPos: i32 = undefined;
    var yPos: i32 = undefined;
    var lblF: GtkRequisition = undefined;
    var lblG: GtkRequisition = undefined;
    if (calcLandscape) {
    xPos = X_LEFT_LANDSCAPE;
    yPos = Y_TOP_LANDSCAPE;
    } else {
    xPos = X_LEFT_PORTRAIT;
    yPos = Y_TOP_PORTRAIT + DELTA_KEYS_Y;
    }
    yPos += 5;
    gtk_widget_get_preferred_size(widgets.lbl21F, null, &lblF);
    gtk_widget_get_preferred_size(widgets.lbl21G, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl21F, @divTrunc((2*xPos+KEY_WIDTH_1-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl21G, @divTrunc((2*xPos+KEY_WIDTH_1+lblF.width+GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl21Gr, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl21Gr, xPos+@divTrunc(KEY_WIDTH_1*2, 3), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl21Fa, null, &lblF);
    gtk_fixed_move(widgets.grid, widgets.lbl21Fa, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    xPos += DELTA_KEYS_X;
    gtk_widget_get_preferred_size(widgets.lbl22F, null, &lblF);
    gtk_widget_get_preferred_size(widgets.lbl22G, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl22F, @divTrunc((2*xPos+KEY_WIDTH_1-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl22G, @divTrunc((2*xPos+KEY_WIDTH_1+lblF.width+GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl22Gr, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl22Gr, xPos+@divTrunc(KEY_WIDTH_1*2, 3), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl22Fa, null, &lblF);
    gtk_fixed_move(widgets.grid, widgets.lbl22Fa, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    xPos += DELTA_KEYS_X;
    gtk_widget_get_preferred_size(widgets.lbl23F, null, &lblF);
    gtk_widget_get_preferred_size(widgets.lbl23G, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl23F, @divTrunc((2*xPos+KEY_WIDTH_1-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl23G, @divTrunc((2*xPos+KEY_WIDTH_1+lblF.width+GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl23Gr, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl23Gr, xPos+@divTrunc(KEY_WIDTH_1*2, 3), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl23Fa, null, &lblF);
    gtk_fixed_move(widgets.grid, widgets.lbl23Fa, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    xPos += DELTA_KEYS_X;
    gtk_widget_get_preferred_size(widgets.lbl24F, null, &lblF);
    gtk_widget_get_preferred_size(widgets.lbl24G, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl24F, @divTrunc((2*xPos+KEY_WIDTH_1-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl24G, @divTrunc((2*xPos+KEY_WIDTH_1+lblF.width+GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl24Gr, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl24Gr, xPos+@divTrunc(KEY_WIDTH_1*2, 3), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl24Fa, null, &lblF);
    gtk_fixed_move(widgets.grid, widgets.lbl24Fa, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    xPos += DELTA_KEYS_X;
    gtk_widget_get_preferred_size(widgets.lbl25F, null, &lblF);
    gtk_widget_get_preferred_size(widgets.lbl25G, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl25F, @divTrunc((2*xPos+KEY_WIDTH_1-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl25G, @divTrunc((2*xPos+KEY_WIDTH_1+lblF.width+GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl25Gr, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl25Gr, xPos+@divTrunc(KEY_WIDTH_1*2, 3), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl25Fa, null, &lblF);
    gtk_fixed_move(widgets.grid, widgets.lbl25Fa, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    xPos += DELTA_KEYS_X;
    gtk_widget_get_preferred_size(widgets.lbl26F, null, &lblF);
    gtk_widget_get_preferred_size(widgets.lbl26G, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl26F, @divTrunc((2*xPos+KEY_WIDTH_1-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl26G, @divTrunc((2*xPos+KEY_WIDTH_1+lblF.width+GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl26Gr, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl26Gr, xPos+@divTrunc(KEY_WIDTH_1*2, 3), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl26Fa, null, &lblF);
    gtk_fixed_move(widgets.grid, widgets.lbl26Fa, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    xPos = if (calcLandscape) X_LEFT_LANDSCAPE else X_LEFT_PORTRAIT;
    yPos += DELTA_KEYS_Y;
    gtk_widget_get_preferred_size(widgets.lbl31F, null, &lblF);
    gtk_widget_get_preferred_size(widgets.lbl31G, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl31F, @divTrunc((2*xPos+KEY_WIDTH_1-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl31G, @divTrunc((2*xPos+KEY_WIDTH_1+lblF.width+GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl31Gr, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl31Gr, xPos+@divTrunc(KEY_WIDTH_1*2, 3), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl31Fa, null, &lblF);
    gtk_fixed_move(widgets.grid, widgets.lbl31Fa, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    xPos += DELTA_KEYS_X;
    gtk_widget_get_preferred_size(widgets.lbl32F, null, &lblF);
    gtk_widget_get_preferred_size(widgets.lbl32G, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl32F, @divTrunc((2*xPos+KEY_WIDTH_1-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl32G, @divTrunc((2*xPos+KEY_WIDTH_1+lblF.width+GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl32Gr, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl32Gr, xPos+@divTrunc(KEY_WIDTH_1*2, 3), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl32Fa, null, &lblF);
    gtk_fixed_move(widgets.grid, widgets.lbl32Fa, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    xPos += DELTA_KEYS_X;
    gtk_widget_get_preferred_size(widgets.lbl33F, null, &lblF);
    gtk_widget_get_preferred_size(widgets.lbl33G, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl33F, @divTrunc((2*xPos+KEY_WIDTH_1-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl33G, @divTrunc((2*xPos+KEY_WIDTH_1+lblF.width+GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl33Gr, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl33Gr, xPos+@divTrunc(KEY_WIDTH_1*2, 3), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl33Fa, null, &lblF);
    gtk_fixed_move(widgets.grid, widgets.lbl33Fa, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    xPos += DELTA_KEYS_X;
    gtk_widget_get_preferred_size(widgets.lbl34F, null, &lblF);
    gtk_widget_get_preferred_size(widgets.lbl34G, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl34F, @divTrunc((2*xPos+KEY_WIDTH_1-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl34G, @divTrunc((2*xPos+KEY_WIDTH_1+lblF.width+GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl34Gr, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl34Gr, xPos+@divTrunc(KEY_WIDTH_1*2, 3), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl34Fa, null, &lblF);
    gtk_fixed_move(widgets.grid, widgets.lbl34Fa, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    xPos += DELTA_KEYS_X;
    gtk_widget_get_preferred_size(widgets.lbl35F, null, &lblF);
    gtk_widget_get_preferred_size(widgets.lbl35G, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl35F, @divTrunc((2*xPos+KEY_WIDTH_1-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl35G, @divTrunc((2*xPos+KEY_WIDTH_1+lblF.width+GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl35Gr, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl35Gr, xPos+@divTrunc(KEY_WIDTH_1*2, 3), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl35Fa, null, &lblF);
    gtk_fixed_move(widgets.grid, widgets.lbl35Fa, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    xPos += DELTA_KEYS_X;
    gtk_widget_get_preferred_size(widgets.lbl36F, null, &lblF);
    gtk_widget_get_preferred_size(widgets.lbl36G, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl36F, @divTrunc((2*xPos+KEY_WIDTH_1-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl36G, @divTrunc((2*xPos+KEY_WIDTH_1+lblF.width+GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl36Gr, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl36Gr, xPos+@divTrunc(KEY_WIDTH_1*2, 3), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl36Fa, null, &lblF);
    gtk_fixed_move(widgets.grid, widgets.lbl36Fa, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    xPos = if (calcLandscape) X_LEFT_LANDSCAPE else X_LEFT_PORTRAIT;
    yPos += DELTA_KEYS_Y;
    gtk_widget_get_preferred_size(widgets.lbl41F, null, &lblF);
    gtk_widget_get_preferred_size(widgets.lbl41G, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl41F, @divTrunc((2*xPos+KEY_WIDTH_1+DELTA_KEYS_X-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl41G, @divTrunc((2*xPos+KEY_WIDTH_1+DELTA_KEYS_X+lblF.width+GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl41Gr, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl41Gr, xPos+@divTrunc(KEY_WIDTH_1*4, 3), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl41Fa, null, &lblF);
    gtk_fixed_move(widgets.grid, widgets.lbl41Fa, xPos-KEY_WIDTH_1*0, yPos - Y_OFFSET_Aim);
    xPos += 2*DELTA_KEYS_X;
    gtk_widget_get_preferred_size(widgets.lbl42F, null, &lblF);
    gtk_widget_get_preferred_size(widgets.lbl42G, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl42F, @divTrunc((2*xPos+KEY_WIDTH_1-lblF.width-@divTrunc(GAP, 2)-lblG.width+2), 2)-@divTrunc(GAP, 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl42G, @divTrunc((2*xPos+KEY_WIDTH_1+lblF.width+@divTrunc(GAP, 2)-lblG.width+2), 2)-@divTrunc(GAP, 2), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl42Gr, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl42Gr, xPos+@divTrunc(KEY_WIDTH_1*2, 3), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl42Fa, null, &lblF);
    gtk_fixed_move(widgets.grid, widgets.lbl42Fa, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    xPos += DELTA_KEYS_X;
    gtk_widget_get_preferred_size(widgets.lbl43F, null, &lblF);
    gtk_widget_get_preferred_size(widgets.lbl43G, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl43F, @divTrunc((2*xPos+KEY_WIDTH_1-lblF.width-@divTrunc(GAP, 2)-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl43G, @divTrunc((2*xPos+KEY_WIDTH_1+lblF.width+@divTrunc(GAP, 2)-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl43Gr, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl43Gr, xPos+@divTrunc(KEY_WIDTH_1*2, 3), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl43Fa, null, &lblF);
    gtk_fixed_move(widgets.grid, widgets.lbl43Fa, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    xPos += DELTA_KEYS_X;
    gtk_widget_get_preferred_size(widgets.lbl44F, null, &lblF);
    gtk_widget_get_preferred_size(widgets.lbl44G, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl44F, @divTrunc((2*xPos+KEY_WIDTH_1-lblF.width-@divTrunc(GAP, 2)-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl44G, @divTrunc((2*xPos+KEY_WIDTH_1+lblF.width+@divTrunc(GAP, 2)-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl44Gr, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl44Gr, xPos+@divTrunc(KEY_WIDTH_1*2, 3), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl44Fa, null, &lblF);
    gtk_fixed_move(widgets.grid, widgets.lbl44Fa, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    xPos += DELTA_KEYS_X;
    gtk_widget_get_preferred_size(widgets.lbl45F, null, &lblF);
    gtk_widget_get_preferred_size(widgets.lbl45G, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl45F, @divTrunc((2*xPos+KEY_WIDTH_1-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl45G, @divTrunc((2*xPos+KEY_WIDTH_1+lblF.width+GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl45Fa, null, &lblF);
    gtk_fixed_move(widgets.grid, widgets.lbl45Fa, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    xPos = if (calcLandscape) X_LEFT_LANDSCAPE else X_LEFT_PORTRAIT;
    yPos += DELTA_KEYS_Y + 1;
    if (calcMode != CM_AIM) {
    gtk_widget_get_preferred_size(widgets.lbl51F, null, &lblF);
    gtk_widget_get_preferred_size(widgets.lbl51G, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl51F, @divTrunc((2*xPos+KEY_WIDTH_1-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl51G, @divTrunc((2*xPos+KEY_WIDTH_1+lblF.width+GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    }
    gtk_widget_get_preferred_size(widgets.lbl51Gr, null, &lblG);
    gtk_widget_get_preferred_size(widgets.lbl51Fa, null, &lblF);
    gtk_fixed_move(widgets.grid, widgets.lbl51Gr, @divTrunc((2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl51Fa, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_1;
    gtk_widget_get_preferred_size(widgets.lbl52F, null, &lblF);
    gtk_widget_get_preferred_size(widgets.lbl52G, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl52F, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl52G, @divTrunc((2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl52Gr, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl52Gr, xPos+@divTrunc(KEY_WIDTH_2*2, 3), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl52Fa, null, &lblF);
    gtk_fixed_move(widgets.grid, widgets.lbl52Fa, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_2;
    gtk_widget_get_preferred_size(widgets.lbl53F, null, &lblF);
    gtk_widget_get_preferred_size(widgets.lbl53G, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl53F, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl53G, @divTrunc((2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl53Gr, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl53Gr, xPos+@divTrunc(KEY_WIDTH_2*2, 3), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl53Fa, null, &lblF);
    gtk_fixed_move(widgets.grid, widgets.lbl53Fa, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_2;
    gtk_widget_get_preferred_size(widgets.lbl54F, null, &lblF);
    gtk_widget_get_preferred_size(widgets.lbl54G, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl54F, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl54G, @divTrunc((2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl54Gr, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl54Gr, xPos+@divTrunc(KEY_WIDTH_2*2, 3), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl54Fa, null, &lblF);
    gtk_fixed_move(widgets.grid, widgets.lbl54Fa, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_2;
    gtk_widget_get_preferred_size(widgets.lbl55F, null, &lblF);
    gtk_widget_get_preferred_size(widgets.lbl55G, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl55F, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl55G, @divTrunc((2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl55Gr, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl55Gr, xPos+@divTrunc(KEY_WIDTH_2*2, 3), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl55Fa, null, &lblF);
    gtk_fixed_move(widgets.grid, widgets.lbl55Fa, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    xPos = if (calcLandscape) X_LEFT_LANDSCAPE else X_LEFT_PORTRAIT;
    yPos += DELTA_KEYS_Y + 1;
    if (calcMode != CM_AIM) {
    gtk_widget_get_preferred_size(widgets.lbl61F, null, &lblF);
    gtk_widget_get_preferred_size(widgets.lbl61G, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl61F, @divTrunc((2*xPos+KEY_WIDTH_1-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl61G, @divTrunc((2*xPos+KEY_WIDTH_1+lblF.width+GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    }
    gtk_widget_get_preferred_size(widgets.lbl61Gr, null, &lblG);
    gtk_widget_get_preferred_size(widgets.lbl61Fa, null, &lblF);
    gtk_fixed_move(widgets.grid, widgets.lbl61Gr, @divTrunc((2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl61Fa, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_1;
    gtk_widget_get_preferred_size(widgets.lbl62F, null, &lblF);
    gtk_widget_get_preferred_size(widgets.lbl62G, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl62F, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl62G, @divTrunc((2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl62Gr, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl62Gr, xPos+@divTrunc(KEY_WIDTH_2*2, 3), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl62Fa, null, &lblF);
    gtk_fixed_move(widgets.grid, widgets.lbl62Fa, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_2;
    gtk_widget_get_preferred_size(widgets.lbl63F, null, &lblF);
    gtk_widget_get_preferred_size(widgets.lbl63G, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl63F, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl63G, @divTrunc((2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl63Gr, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl63Gr, xPos+@divTrunc(KEY_WIDTH_2*2, 3), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl63Fa, null, &lblF);
    gtk_fixed_move(widgets.grid, widgets.lbl63Fa, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_2;
    gtk_widget_get_preferred_size(widgets.lbl64F, null, &lblF);
    gtk_widget_get_preferred_size(widgets.lbl64G, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl64F, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl64G, @divTrunc((2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl64Gr, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl64Gr, xPos+@divTrunc(KEY_WIDTH_2*2, 3), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl64Fa, null, &lblF);
    gtk_fixed_move(widgets.grid, widgets.lbl64Fa, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_2;
    gtk_widget_get_preferred_size(widgets.lbl65F, null, &lblF);
    gtk_widget_get_preferred_size(widgets.lbl65G, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl65F, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl65G, @divTrunc((2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl65Gr, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl65Gr, xPos+@divTrunc(KEY_WIDTH_2*2, 3), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl65Fa, null, &lblF);
    gtk_fixed_move(widgets.grid, widgets.lbl65Fa, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    xPos = if (calcLandscape) X_LEFT_LANDSCAPE else X_LEFT_PORTRAIT;
    yPos += DELTA_KEYS_Y + 1;
    if (calcModel != USER_C47 and calcModel != USER_DM42) {
    if (calcMode != CM_AIM) {
    gtk_widget_get_preferred_size(widgets.lbl71F, null, &lblF);
    gtk_widget_get_preferred_size(widgets.lbl71G, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl71F, @divTrunc((2*xPos+KEY_WIDTH_1-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl71G, @divTrunc((2*xPos+KEY_WIDTH_1+lblF.width+GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    }
    gtk_widget_get_preferred_size(widgets.lbl71Gr, null, &lblG);
    gtk_widget_get_preferred_size(widgets.lbl71Fa, null, &lblF);
    gtk_fixed_move(widgets.grid, widgets.lbl71Gr, @divTrunc((2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl71Fa, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    }
    xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_1;
    gtk_widget_get_preferred_size(widgets.lbl72F, null, &lblF);
    gtk_widget_get_preferred_size(widgets.lbl72G, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl72F, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl72G, @divTrunc((2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl72Gr, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl72Gr, xPos+@divTrunc(KEY_WIDTH_2*2, 3), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl72Fa, null, &lblF);
    gtk_fixed_move(widgets.grid, widgets.lbl72Fa, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_2;
    gtk_widget_get_preferred_size(widgets.lbl73F, null, &lblF);
    gtk_widget_get_preferred_size(widgets.lbl73G, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl73F, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl73G, @divTrunc((2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl73Gr, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl73Gr, xPos+@divTrunc(KEY_WIDTH_2*2, 3), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl73Fa, null, &lblF);
    gtk_fixed_move(widgets.grid, widgets.lbl73Fa, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_2;
    gtk_widget_get_preferred_size(widgets.lbl74F, null, &lblF);
    gtk_widget_get_preferred_size(widgets.lbl74G, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl74F, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl74G, @divTrunc((2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl74Gr, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl74Gr, xPos+@divTrunc(KEY_WIDTH_2*2, 3), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl74Fa, null, &lblF);
    gtk_fixed_move(widgets.grid, widgets.lbl74Fa, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_2;
    gtk_widget_get_preferred_size(widgets.lbl75F, null, &lblF);
    gtk_widget_get_preferred_size(widgets.lbl75G, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl75F, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl75G, @divTrunc((2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl75Gr, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl75Gr, xPos+@divTrunc(KEY_WIDTH_2*2, 3), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl75Fa, null, &lblF);
    gtk_fixed_move(widgets.grid, widgets.lbl75Fa, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    xPos = if (calcLandscape) X_LEFT_LANDSCAPE else X_LEFT_PORTRAIT;
    yPos += DELTA_KEYS_Y + 1;
    gtk_widget_get_preferred_size(widgets.lbl81F, null, &lblF);
    gtk_widget_get_preferred_size(widgets.lbl81G, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl81F, @divTrunc((2*xPos+KEY_WIDTH_1-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl81G, @divTrunc((2*xPos+KEY_WIDTH_1+lblF.width+GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_1;
    gtk_widget_get_preferred_size(widgets.lbl82F, null, &lblF);
    gtk_widget_get_preferred_size(widgets.lbl82G, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl82F, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl82G, @divTrunc((2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl82Gr, null, &lblG);
    gtk_widget_get_preferred_size(widgets.lbl82Fa, null, &lblF);
    gtk_fixed_move(widgets.grid, widgets.lbl82Gr, @divTrunc((2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl82Fa, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_2;
    gtk_widget_get_preferred_size(widgets.lbl83F, null, &lblF);
    gtk_widget_get_preferred_size(widgets.lbl83G, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl83F, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl83G, @divTrunc((2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl83Gr, null, &lblG);
    gtk_widget_get_preferred_size(widgets.lbl83Fa, null, &lblF);
    gtk_fixed_move(widgets.grid, widgets.lbl83Gr, @divTrunc((2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl83Fa, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_2;
    gtk_widget_get_preferred_size(widgets.lbl84F, null, &lblF);
    gtk_widget_get_preferred_size(widgets.lbl84G, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl84F, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl84G, @divTrunc((2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl84Gr, null, &lblG);
    gtk_widget_get_preferred_size(widgets.lbl84Fa, null, &lblF);
    gtk_fixed_move(widgets.grid, widgets.lbl84Gr, @divTrunc((2*xPos+KEY_WIDTH_2+lblF.width+GAP*4-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl84Fa, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_2;
    gtk_widget_get_preferred_size(widgets.lbl85F, null, &lblF);
    gtk_widget_get_preferred_size(widgets.lbl85G, null, &lblG);
    gtk_fixed_move(widgets.grid, widgets.lbl85F, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl85G, @divTrunc((2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_widget_get_preferred_size(widgets.lbl85Gr, null, &lblG);
    gtk_widget_get_preferred_size(widgets.lbl85Fa, null, &lblF);
    gtk_fixed_move(widgets.grid, widgets.lbl85Gr, @divTrunc((2*xPos+KEY_WIDTH_2+lblF.width+2*GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
    gtk_fixed_move(widgets.grid, widgets.lbl85Fa, @divTrunc((2*xPos+KEY_WIDTH_2-lblF.width-2*GAP-lblG.width+2), 2), yPos - Y_OFFSET_Aim);
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
