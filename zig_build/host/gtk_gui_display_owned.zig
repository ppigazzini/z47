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
extern fn printf(fmt: [*c]const u8, ...) c_int;
extern fn printStringToConsole(str: [*c]const u8, before: [*c]const u8, after: [*c]const u8) void;

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

fn getButtonName(widget: ?*anyopaque) [*c]const u8 {
    if (widget == null) return "NULL";
    if (widget == widgets.btn11) return "btn11";
    if (widget == widgets.btn12) return "btn12";
    if (widget == widgets.btn13) return "btn13";
    if (widget == widgets.btn14) return "btn14";
    if (widget == widgets.btn15) return "btn15";
    if (widget == widgets.btn16) return "btn16";
    if (widget == widgets.btn21) return "btn21";
    if (widget == widgets.btn22) return "btn22";
    if (widget == widgets.btn23) return "btn23";
    if (widget == widgets.btn24) return "btn24";
    if (widget == widgets.btn25) return "btn25";
    if (widget == widgets.btn26) return "btn26";
    if (widget == widgets.btn21A) return "btn21A";
    if (widget == widgets.btn22A) return "btn22A";
    if (widget == widgets.btn23A) return "btn23A";
    if (widget == widgets.btn24A) return "btn24A";
    if (widget == widgets.btn25A) return "btn25A";
    if (widget == widgets.btn26A) return "btn26A";
    if (widget == widgets.lbl21F) return "lbl21F";
    if (widget == widgets.lbl22F) return "lbl22F";
    if (widget == widgets.lbl23F) return "lbl23F";
    if (widget == widgets.lbl24F) return "lbl24F";
    if (widget == widgets.lbl25F) return "lbl25F";
    if (widget == widgets.lbl26F) return "lbl26F";
    if (widget == widgets.lbl21G) return "lbl21G";
    if (widget == widgets.lbl22G) return "lbl22G";
    if (widget == widgets.lbl23G) return "lbl23G";
    if (widget == widgets.lbl24G) return "lbl24G";
    if (widget == widgets.lbl25G) return "lbl25G";
    if (widget == widgets.lbl26G) return "lbl26G";
    if (widget == widgets.lbl21L) return "lbl21L";
    if (widget == widgets.lbl22L) return "lbl22L";
    if (widget == widgets.lbl23L) return "lbl23L";
    if (widget == widgets.lbl24L) return "lbl24L";
    if (widget == widgets.lbl25L) return "lbl25L";
    if (widget == widgets.lbl26L) return "lbl26L";
    if (widget == widgets.lbl21Gr) return "lbl21Gr";
    if (widget == widgets.lbl22Gr) return "lbl22Gr";
    if (widget == widgets.lbl23Gr) return "lbl23Gr";
    if (widget == widgets.lbl24Gr) return "lbl24Gr";
    if (widget == widgets.lbl25Gr) return "lbl25Gr";
    if (widget == widgets.lbl26Gr) return "lbl26Gr";
    if (widget == widgets.lbl21Fa) return "lbl21Fa";
    if (widget == widgets.lbl22Fa) return "lbl22Fa";
    if (widget == widgets.lbl23Fa) return "lbl23Fa";
    if (widget == widgets.lbl24Fa) return "lbl24Fa";
    if (widget == widgets.lbl25Fa) return "lbl25Fa";
    if (widget == widgets.lbl26Fa) return "lbl26Fa";
    if (widget == widgets.btn31) return "btn31";
    if (widget == widgets.btn32) return "btn32";
    if (widget == widgets.btn33) return "btn33";
    if (widget == widgets.btn34) return "btn34";
    if (widget == widgets.btn35) return "btn35";
    if (widget == widgets.btn36) return "btn36";
    if (widget == widgets.btn31A) return "btn31A";
    if (widget == widgets.btn32A) return "btn32A";
    if (widget == widgets.btn33A) return "btn33A";
    if (widget == widgets.btn34A) return "btn34A";
    if (widget == widgets.btn35A) return "btn35A";
    if (widget == widgets.btn36A) return "btn36A";
    if (widget == widgets.lbl31F) return "lbl31F";
    if (widget == widgets.lbl32F) return "lbl32F";
    if (widget == widgets.lbl33F) return "lbl33F";
    if (widget == widgets.lbl34F) return "lbl34F";
    if (widget == widgets.lbl35F) return "lbl35F";
    if (widget == widgets.lbl36F) return "lbl36F";
    if (widget == widgets.lbl31G) return "lbl31G";
    if (widget == widgets.lbl32G) return "lbl32G";
    if (widget == widgets.lbl33G) return "lbl33G";
    if (widget == widgets.lbl34G) return "lbl34G";
    if (widget == widgets.lbl35G) return "lbl35G";
    if (widget == widgets.lbl36G) return "lbl36G";
    if (widget == widgets.lbl31L) return "lbl31L";
    if (widget == widgets.lbl32L) return "lbl32L";
    if (widget == widgets.lbl33L) return "lbl33L";
    if (widget == widgets.lbl34L) return "lbl34L";
    if (widget == widgets.lbl35L) return "lbl35L";
    if (widget == widgets.lbl36L) return "lbl36L";
    if (widget == widgets.lbl31Gr) return "lbl31Gr";
    if (widget == widgets.lbl32Gr) return "lbl32Gr";
    if (widget == widgets.lbl33Gr) return "lbl33Gr";
    if (widget == widgets.lbl34Gr) return "lbl34Gr";
    if (widget == widgets.lbl35Gr) return "lbl35Gr";
    if (widget == widgets.lbl36Gr) return "lbl36Gr";
    if (widget == widgets.lbl31Fa) return "lbl31Fa";
    if (widget == widgets.lbl32Fa) return "lbl32Fa";
    if (widget == widgets.lbl33Fa) return "lbl33Fa";
    if (widget == widgets.lbl34Fa) return "lbl34Fa";
    if (widget == widgets.lbl35Fa) return "lbl35Fa";
    if (widget == widgets.lbl36Fa) return "lbl36Fa";
    if (widget == widgets.btn41) return "btn41";
    if (widget == widgets.btn42) return "btn42";
    if (widget == widgets.btn43) return "btn43";
    if (widget == widgets.btn44) return "btn44";
    if (widget == widgets.btn45) return "btn45";
    if (widget == widgets.btn42A) return "btn42A";
    if (widget == widgets.btn43A) return "btn43A";
    if (widget == widgets.btn44A) return "btn44A";
    if (widget == widgets.lbl41F) return "lbl41F";
    if (widget == widgets.lbl42F) return "lbl42F";
    if (widget == widgets.lbl43F) return "lbl43F";
    if (widget == widgets.lbl44F) return "lbl44F";
    if (widget == widgets.lbl45F) return "lbl45F";
    if (widget == widgets.lbl41G) return "lbl41G";
    if (widget == widgets.lbl42G) return "lbl42G";
    if (widget == widgets.lbl43G) return "lbl43G";
    if (widget == widgets.lbl44G) return "lbl44G";
    if (widget == widgets.lbl45G) return "lbl45G";
    if (widget == widgets.lbl41L) return "lbl41L";
    if (widget == widgets.lbl42L) return "lbl42L";
    if (widget == widgets.lbl43L) return "lbl43L";
    if (widget == widgets.lbl44L) return "lbl44L";
    if (widget == widgets.lbl45L) return "lbl45L";
    if (widget == widgets.lbl41Gr) return "lbl41Gr";
    if (widget == widgets.lbl42Gr) return "lbl42Gr";
    if (widget == widgets.lbl43Gr) return "lbl43Gr";
    if (widget == widgets.lbl44Gr) return "lbl44Gr";
    if (widget == widgets.lbl45Gr) return "lbl45Gr";
    if (widget == widgets.lbl41Fa) return "lbl41Fa";
    if (widget == widgets.lbl42Fa) return "lbl42Fa";
    if (widget == widgets.lbl43Fa) return "lbl43Fa";
    if (widget == widgets.lbl44Fa) return "lbl44Fa";
    if (widget == widgets.lbl45Fa) return "lbl45Fa";
    if (widget == widgets.btn51) return "btn51";
    if (widget == widgets.btn52) return "btn52";
    if (widget == widgets.btn53) return "btn53";
    if (widget == widgets.btn54) return "btn54";
    if (widget == widgets.btn55) return "btn55";
    if (widget == widgets.btn52A) return "btn52A";
    if (widget == widgets.btn53A) return "btn53A";
    if (widget == widgets.btn54A) return "btn54A";
    if (widget == widgets.btn55A) return "btn55A";
    if (widget == widgets.lbl51F) return "lbl51F";
    if (widget == widgets.lbl52F) return "lbl52F";
    if (widget == widgets.lbl53F) return "lbl53F";
    if (widget == widgets.lbl54F) return "lbl54F";
    if (widget == widgets.lbl55F) return "lbl55F";
    if (widget == widgets.lbl51G) return "lbl51G";
    if (widget == widgets.lbl52G) return "lbl52G";
    if (widget == widgets.lbl53G) return "lbl53G";
    if (widget == widgets.lbl54G) return "lbl54G";
    if (widget == widgets.lbl55G) return "lbl55G";
    if (widget == widgets.lbl51L) return "lbl51L";
    if (widget == widgets.lbl52L) return "lbl52L";
    if (widget == widgets.lbl53L) return "lbl53L";
    if (widget == widgets.lbl54L) return "lbl54L";
    if (widget == widgets.lbl55L) return "lbl55L";
    if (widget == widgets.lbl51Gr) return "lbl51Gr";
    if (widget == widgets.lbl52Gr) return "lbl52Gr";
    if (widget == widgets.lbl53Gr) return "lbl53Gr";
    if (widget == widgets.lbl54Gr) return "lbl54Gr";
    if (widget == widgets.lbl55Gr) return "lbl55Gr";
    if (widget == widgets.lbl51Fa) return "lbl51Fa";
    if (widget == widgets.lbl52Fa) return "lbl52Fa";
    if (widget == widgets.lbl53Fa) return "lbl53Fa";
    if (widget == widgets.lbl54Fa) return "lbl54Fa";
    if (widget == widgets.lbl55Fa) return "lbl55Fa";
    if (widget == widgets.btn61) return "btn61";
    if (widget == widgets.btn62) return "btn62";
    if (widget == widgets.btn63) return "btn63";
    if (widget == widgets.btn64) return "btn64";
    if (widget == widgets.btn65) return "btn65";
    if (widget == widgets.btn62A) return "btn62A";
    if (widget == widgets.btn63A) return "btn63A";
    if (widget == widgets.btn64A) return "btn64A";
    if (widget == widgets.btn65A) return "btn65A";
    if (widget == widgets.lbl61F) return "lbl61F";
    if (widget == widgets.lbl62F) return "lbl62F";
    if (widget == widgets.lbl63F) return "lbl63F";
    if (widget == widgets.lbl64F) return "lbl64F";
    if (widget == widgets.lbl65F) return "lbl65F";
    if (widget == widgets.lbl61G) return "lbl61G";
    if (widget == widgets.lbl62G) return "lbl62G";
    if (widget == widgets.lbl63G) return "lbl63G";
    if (widget == widgets.lbl64G) return "lbl64G";
    if (widget == widgets.lbl65G) return "lbl65G";
    if (widget == widgets.lbl61L) return "lbl61L";
    if (widget == widgets.lbl62L) return "lbl62L";
    if (widget == widgets.lbl63L) return "lbl63L";
    if (widget == widgets.lbl64L) return "lbl64L";
    if (widget == widgets.lbl65L) return "lbl65L";
    if (widget == widgets.lbl61Gr) return "lbl61Gr";
    if (widget == widgets.lbl62Gr) return "lbl62Gr";
    if (widget == widgets.lbl63Gr) return "lbl63Gr";
    if (widget == widgets.lbl64Gr) return "lbl64Gr";
    if (widget == widgets.lbl65Gr) return "lbl65Gr";
    if (widget == widgets.lbl61Fa) return "lbl61Fa";
    if (widget == widgets.lbl62Fa) return "lbl62Fa";
    if (widget == widgets.lbl63Fa) return "lbl63Fa";
    if (widget == widgets.lbl64Fa) return "lbl64Fa";
    if (widget == widgets.lbl65Fa) return "lbl65Fa";
    if (widget == widgets.btn71) return "btn71";
    if (widget == widgets.btn72) return "btn72";
    if (widget == widgets.btn73) return "btn73";
    if (widget == widgets.btn74) return "btn74";
    if (widget == widgets.btn75) return "btn75";
    if (widget == widgets.btn71A) return "btn71A";
    if (widget == widgets.btn72A) return "btn72A";
    if (widget == widgets.btn73A) return "btn73A";
    if (widget == widgets.btn74A) return "btn74A";
    if (widget == widgets.btn75A) return "btn75A";
    if (widget == widgets.lbl71F) return "lbl71F";
    if (widget == widgets.lbl72F) return "lbl72F";
    if (widget == widgets.lbl73F) return "lbl73F";
    if (widget == widgets.lbl74F) return "lbl74F";
    if (widget == widgets.lbl75F) return "lbl75F";
    if (widget == widgets.lbl71G) return "lbl71G";
    if (widget == widgets.lbl72G) return "lbl72G";
    if (widget == widgets.lbl73G) return "lbl73G";
    if (widget == widgets.lbl74G) return "lbl74G";
    if (widget == widgets.lbl75G) return "lbl75G";
    if (widget == widgets.lbl71L) return "lbl71L";
    if (widget == widgets.lbl72L) return "lbl72L";
    if (widget == widgets.lbl73L) return "lbl73L";
    if (widget == widgets.lbl74L) return "lbl74L";
    if (widget == widgets.lbl75L) return "lbl75L";
    if (widget == widgets.lbl71Gr) return "lbl71Gr";
    if (widget == widgets.lbl72Gr) return "lbl72Gr";
    if (widget == widgets.lbl73Gr) return "lbl73Gr";
    if (widget == widgets.lbl74Gr) return "lbl74Gr";
    if (widget == widgets.lbl75Gr) return "lbl75Gr";
    if (widget == widgets.lbl71Fa) return "lbl71Fa";
    if (widget == widgets.lbl72Fa) return "lbl72Fa";
    if (widget == widgets.lbl73Fa) return "lbl73Fa";
    if (widget == widgets.lbl74Fa) return "lbl74Fa";
    if (widget == widgets.lbl75Fa) return "lbl75Fa";
    if (widget == widgets.btn81) return "btn81";
    if (widget == widgets.btn82) return "btn82";
    if (widget == widgets.btn83) return "btn83";
    if (widget == widgets.btn84) return "btn84";
    if (widget == widgets.btn85) return "btn85";
    if (widget == widgets.btn82A) return "btn82A";
    if (widget == widgets.btn83A) return "btn83A";
    if (widget == widgets.btn84A) return "btn84A";
    if (widget == widgets.btn85A) return "btn85A";
    if (widget == widgets.lbl81F) return "lbl81F";
    if (widget == widgets.lbl82F) return "lbl82F";
    if (widget == widgets.lbl83F) return "lbl83F";
    if (widget == widgets.lbl84F) return "lbl84F";
    if (widget == widgets.lbl85F) return "lbl85F";
    if (widget == widgets.lbl81G) return "lbl81G";
    if (widget == widgets.lbl82G) return "lbl82G";
    if (widget == widgets.lbl83G) return "lbl83G";
    if (widget == widgets.lbl84G) return "lbl84G";
    if (widget == widgets.lbl85G) return "lbl85G";
    if (widget == widgets.lbl81L) return "lbl81L";
    if (widget == widgets.lbl82L) return "lbl82L";
    if (widget == widgets.lbl83L) return "lbl83L";
    if (widget == widgets.lbl84L) return "lbl84L";
    if (widget == widgets.lbl85L) return "lbl85L";
    if (widget == widgets.lbl81Gr) return "lbl81Gr";
    if (widget == widgets.lbl82Gr) return "lbl82Gr";
    if (widget == widgets.lbl83Gr) return "lbl83Gr";
    if (widget == widgets.lbl84Gr) return "lbl84Gr";
    if (widget == widgets.lbl85Gr) return "lbl85Gr";
    if (widget == widgets.lbl82Fa) return "lbl82Fa";
    if (widget == widgets.lbl83Fa) return "lbl83Fa";
    if (widget == widgets.lbl84Fa) return "lbl84Fa";
    if (widget == widgets.lbl85Fa) return "lbl85Fa";
    return "UNKNOWN_WIDGET";
}

pub fn debugLabelConsistency(lbl: [*c]const u8, ctx: [*c]const u8, key: ?*const calcKey_t, btn: ?*anyopaque, show_btn: bool) bool {
    if (!label.checkLabelConsistency(lbl, ctx)) {
        return false;
    }
    if (key) |k| {
        label.printLabelBytes(lbl, 16);
        if (show_btn and btn != null) {
            _ = printf("     : key details - btn:=%s\n", getButtonName(btn));
        }
        _ = printf("       key->primaryAim = %d ", @as(c_int, k.primaryAim));
        printStringToConsole(label.softmenuName(k.primaryAim), "...itemSoftmenuName =", " ");
        printStringToConsole(label.softmenuName(k.primaryAim), "primaryAim AA:", "\n");
        _ = printf("       key->fShiftedAim = %d ", @as(c_int, k.fShiftedAim));
        printStringToConsole(label.softmenuName(k.fShiftedAim), "...itemSoftmenuName =", " ");
        printStringToConsole(label.softmenuName(k.fShiftedAim), "fShiftedAim AA:", "\n");
        _ = printf("       key->gShiftedAim = %d ", @as(c_int, k.gShiftedAim));
        printStringToConsole(label.softmenuName(k.gShiftedAim), "...itemSoftmenuName =", " ");
        printStringToConsole(label.softmenuName(k.gShiftedAim), "gShiftedAim AA:", "\n\n");
    }
    return true;
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
