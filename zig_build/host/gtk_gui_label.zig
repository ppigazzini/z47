const gtk_int = @import("gtk_int.zig"); // std-only GTK integer helpers
// SPDX-License-Identifier: GPL-3.0-only
//
// Host GTK label/text helpers ported from src/c47-gtk/gtkGui.c. Starts with the
// pure UTF-8 validator used by the button-label consistency diagnostics; this
// owner is the intended home for the rest of the label-rendering cluster.

extern fn printf(fmt: [*c]const u8, ...) c_int;
extern fn strcmp(a: [*c]const u8, b: [*c]const u8) c_int;
extern fn strcpy(dest: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn stringToUtf8(str: [*c]const u8, utf8: [*c]u8) void;
extern fn gtk_button_set_label(button: ?*anyopaque, label: [*c]const u8) void;
extern fn gtk_widget_set_name(widget: ?*anyopaque, name: [*c]const u8) void;

pub const calcKey_t = extern struct {
    keyId: i16,
    primary: i16,
    fShifted: i16,
    gShifted: i16,
    keyLblAim: i16,
    primaryAim: i16,
    fShiftedAim: i16,
    gShiftedAim: i16,
    primaryTam: i16,
};

const item_t = extern struct {
    func: ?*const anyopaque,
    param: u16,
    itemCatalogName: [16]u8,
    itemSoftmenuName: [16]u8,
    tamMinMax: u16,
    status: u16,
};

const indexOfItems = @extern([*c]const item_t, .{ .name = "indexOfItems" });

const ITM_NULL: i16 = 0;
const ITM_SHIFTf: i16 = 1731;
const ITM_SHIFTg: i16 = 1732;
const KEY_fg: i16 = 1893;
const ITM_A: i16 = 550;
const ITM_Z: i16 = 575;
const MNU_TAMALPHA: i16 = 1913;
const MNU_ALPHA: i16 = 1922;
const MNU_MyAlpha: i16 = 1350;
const CHR_caseUP: i16 = 1878;
const CHR_caseDN: i16 = 1879;
const AC_LOWER: u8 = 1;
const AC_UPPER: u8 = 0;
const FLAG_NUMLOCK: i32 = 32835;
const FLAG_HOME_TRIPLE: i32 = 32864;
const FLAG_MYM_TRIPLE: i32 = 32863;
const USER_R47f_g: u8 = 61;
const USER_R47bk_fg: u8 = 62;
const USER_R47fg_bk: u8 = 63;
const USER_R47fg_g: u8 = 64;
const USER_C47: u8 = 46;
const USER_DM42: u8 = 45;
const ITM_op_j: i16 = 1830;
const ITM_op_j_pol: i16 = 1795;
const ITM_EE_EXP_TH: i16 = 1816;
const ITM_AIM: i16 = 1740;
const ITM_0: i16 = 540;
const ITM_9: i16 = 549;
const ITM_PERIOD: i16 = 820;
const ITM_XEQ: i16 = 3;
const ITM_RCL: i16 = 51;
const ITM_SIGMAPLUS: i16 = 433;
const MNU_DYNAMIC: i16 = 1394;
const MNU_HOME: i16 = 1921;
const MNU_MyMenu: i16 = 1349;
const FLAG_CPXj: i32 = 32773;
const FLAG_USER: i32 = 32788;
const CM_NORMAL: u8 = 0;
const CM_NIM: u8 = 2;
const CM_PEM: u8 = 3;
const CM_TIMER: u8 = 14;

const STD_HAMBURGER: [*:0]const u8 = "\xa1\xcc";
const STD_SST: [*:0]const u8 = "\xa1\xcb";
const STD_BST: [*:0]const u8 = "\xa1\xc9";
const STD_DOWN_BLOCKARROW: [*:0]const u8 = "\xab\x63";
const STD_UP_BLOCKARROW: [*:0]const u8 = "\xab\x61";

const normKey_t = extern struct {
    func: i16,
    funcParam: [16]u8,
    used: bool,
};

extern var calcMode: u8;
extern var Norm_Key_00: normKey_t;
extern var userKeyLabel: [*c]u8;
extern var userKeyLabelSize: u16;

extern fn strcat(dest: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn getNthString(ptr: [*c]u8, n: i16) [*c]u8;

// Norm_Key_00_keyID / Norm_Key_00_item_in_layout (defines.h), model-dependent.
fn normKey00KeyID() i16 {
    return switch (calcModel) {
        USER_C47, USER_DM42 => 21,
        USER_R47bk_fg => 35,
        USER_R47fg_bk => 36,
        else => -1,
    };
}
fn normKey00ItemInLayout() i16 {
    return switch (calcModel) {
        USER_C47, USER_DM42 => ITM_SIGMAPLUS,
        USER_R47bk_fg, USER_R47fg_bk => ITM_NULL,
        else => -1,
    };
}

const tamState_t = extern struct {
    mode: u16,
    function: i16,
    alpha: bool,
    currentOperation: i16,
    dot: bool,
    indirect: bool,
    digitsSoFar: i16,
    value0: i16,
    value: i16,
    min: i16,
    max: i16,
    key: i16,
    keyAlpha: bool,
    keyDot: bool,
    keyIndirect: bool,
    keyInputFinished: bool,
};

extern var calcModel: u8;
extern var shiftF: bool;
extern var shiftG: bool;
extern var alphaCase: u8;
extern var tam: tamState_t;

extern fn getSystemFlag(sf: i32) bool;
extern fn numlockReplacements(id: u16, item: i16, nl: bool, shft: bool, gshft: bool) u16;
extern fn gtk_label_set_label(label: ?*anyopaque, str: [*c]const u8) void;
extern fn debugLabelConsistency(lbl: [*c]const u8, ctx: [*c]const u8, key: *const calcKey_t, btn: ?*anyopaque, show_btn: bool) bool;

fn isR47FAM() bool {
    return calcModel == USER_R47f_g or calcModel == USER_R47bk_fg or
        calcModel == USER_R47fg_bk or calcModel == USER_R47fg_g;
}

// max(item, -item) from gtkGui.c, i.e. abs, computed in i32 to match C's
// integer promotion (so i16 MIN can't trap).
fn absItem(x: i16) i16 {
    return gtk_int.absItem(x);
}

pub fn softmenuName(idx: i16) [*c]const u8 {
    return &indexOfItems[@intCast(idx)].itemSoftmenuName;
}

fn strEq(a: [*c]const u8, b: [*c]const u8) bool {
    return strcmp(a, b) == 0;
}

// gtkGui.c's "space -> middle-dot" label patch (lbl was a lone 0x20).
fn patchSpaceLabel(lbl: *[22]u8) void {
    if (lbl[0] == 32 and lbl[1] == 0) {
        lbl[0] = 0xC2;
        lbl[1] = 0xB7;
        lbl[2] = '_';
        lbl[3] = 0xc2;
        lbl[4] = 0xb7;
        lbl[5] = 0;
    }
}

/// gtkGui.c labelCaptionNormal: renders a key's primary button caption plus the
/// f-shift / g-shift / letter label faces in NORMAL mode, including the
/// Sigma+/Norm-key override, user-key-label substitution, R47FAM longpress
/// colouring, and the CSS key-name assignment.
pub fn labelCaptionNormal(key: *const calcKey_t, button: ?*anyopaque, lbl_f: ?*anyopaque, lbl_g: ?*anyopaque, lbl_l: ?*anyopaque) void {
    var lbl: [22]u8 = undefined;

    var key_logical_id: i16 = undefined;
    if (key.keyId < 30) {
        key_logical_id = key.keyId - 21;
    } else if (key.keyId < 40) {
        key_logical_id = key.keyId - 25;
    } else if (key.keyId < 50) {
        key_logical_id = key.keyId - 29;
    } else if (key.keyId < 60) {
        key_logical_id = key.keyId - 34;
    } else if (key.keyId < 70) {
        key_logical_id = key.keyId - 39;
    } else if (key.keyId < 80) {
        key_logical_id = key.keyId - 44;
    } else {
        key_logical_id = key.keyId - 49;
    }

    var r47_longpress = false;
    var sstmp: [16]u8 = undefined;

    if (key.primary == 0) {
        lbl[0] = 0;
    } else {
        _ = strcpy(&sstmp, softmenuName(absItem(key.primary)));
        if ((key.primary == ITM_op_j or key.primary == ITM_op_j_pol) and getSystemFlag(FLAG_CPXj)) {
            sstmp[1] +%= 1;
        }
        if (key.primary == ITM_EE_EXP_TH and getSystemFlag(FLAG_CPXj)) {
            sstmp[3] +%= 1;
        }
        stringToUtf8(&sstmp, &lbl);
        if (userKeyLabelSize > 0 and (strEq(&lbl, "DYNMNU") or strEq(&lbl, "XEQ") or strEq(&lbl, "RCL"))) {
            const s = getNthString(userKeyLabel, key_logical_id * 6);
            if (s[0] != 0) {
                stringToUtf8(s, &lbl);
            }
        }
    }

    const norm_key_00_used = (calcMode == CM_NORMAL or calcMode == CM_NIM or calcMode == CM_PEM or calcMode == CM_TIMER) and
        key.keyId == normKey00KeyID() and
        Norm_Key_00.func != normKey00ItemInLayout() and
        !getSystemFlag(FLAG_USER);

    if (norm_key_00_used) {
        if (Norm_Key_00.funcParam[0] != 0 and (Norm_Key_00.func == -MNU_DYNAMIC or Norm_Key_00.func == ITM_XEQ or Norm_Key_00.func == ITM_RCL)) {
            _ = strcpy(&sstmp, &Norm_Key_00.funcParam);
        } else {
            _ = strcpy(&sstmp, softmenuName(absItem(Norm_Key_00.func)));
            if ((Norm_Key_00.func == ITM_op_j or Norm_Key_00.func == ITM_op_j_pol) and getSystemFlag(FLAG_CPXj)) {
                sstmp[1] +%= 1;
            }
            if (Norm_Key_00.func == ITM_EE_EXP_TH and getSystemFlag(FLAG_CPXj)) {
                sstmp[3] +%= 1;
            }
        }
        stringToUtf8(&sstmp, &lbl);
    }

    gtk_button_set_label(button, &lbl);

    if ((key.primary == ITM_AIM and getSystemFlag(FLAG_USER) and calcMode == CM_NORMAL and key.keyId == normKey00KeyID()) or
        (key.primary == normKey00ItemInLayout() and calcMode == CM_NORMAL and Norm_Key_00.func == ITM_AIM and key.keyId == normKey00KeyID()))
    {
        gtk_widget_set_name(button, "AlphaKey");
    } else if (key.primary == ITM_SHIFTf or (key.primary == normKey00ItemInLayout() and Norm_Key_00.func == ITM_SHIFTf and key.keyId == normKey00KeyID())) {
        gtk_widget_set_name(button, "calcKeyF");
    } else if (key.primary == ITM_SHIFTg or (key.primary == normKey00ItemInLayout() and Norm_Key_00.func == ITM_SHIFTg and key.keyId == normKey00KeyID())) {
        gtk_widget_set_name(button, "calcKeyG");
    } else if (key.primary == KEY_fg or (key.primary == normKey00ItemInLayout() and Norm_Key_00.func == KEY_fg and key.keyId == normKey00KeyID())) {
        gtk_widget_set_name(button, "calcKeyFG");
    } else if ((key.primary >= ITM_0 and key.primary <= ITM_9) or key.primary == ITM_PERIOD) {
        gtk_widget_set_name(button, "calcNumericKey");
    } else if (strEq(&lbl, "÷") and key.keyId == 55) {
        gtk_widget_set_name(button, "calcNumericKey");
    } else if (strEq(&lbl, "×") and key.keyId == 65) {
        gtk_widget_set_name(button, "calcNumericKey");
    } else if (strEq(&lbl, "-") and key.keyId == 75) {
        gtk_widget_set_name(button, "calcNumericKey");
    } else if (strEq(&lbl, "+") and key.keyId == 85) {
        gtk_widget_set_name(button, "calcNumericKey");
    } else {
        gtk_widget_set_name(button, "calcKey");
    }

    if (key.fShifted == 0) {
        sstmp[0] = 0;
    } else {
        _ = strcpy(&sstmp, softmenuName(absItem(key.fShifted)));
    }
    if ((key.fShifted == ITM_op_j or key.fShifted == ITM_op_j_pol) and getSystemFlag(FLAG_CPXj)) {
        sstmp[1] +%= 1;
    }
    if (key.fShifted == ITM_EE_EXP_TH and getSystemFlag(FLAG_CPXj)) {
        sstmp[3] +%= 1;
    }
    stringToUtf8(&sstmp, &lbl);
    if (userKeyLabelSize > 0 and (strEq(&lbl, "DYNMNU") or strEq(&lbl, "XEQ") or strEq(&lbl, "RCL"))) {
        const s = getNthString(userKeyLabel, key_logical_id * 6 + 1);
        if (s[0] != 0) {
            stringToUtf8(s, &lbl);
        }
    }
    if (strEq(&lbl, "SST")) {
        var tt: [20]u8 = undefined;
        _ = strcpy(&tt, STD_HAMBURGER);
        _ = strcat(&tt, if (isR47FAM()) STD_DOWN_BLOCKARROW else STD_SST);
        stringToUtf8(&tt, &lbl);
    } else if (strEq(&lbl, "BST")) {
        var tt: [20]u8 = undefined;
        _ = strcpy(&tt, STD_HAMBURGER);
        _ = strcat(&tt, if (isR47FAM()) STD_UP_BLOCKARROW else STD_BST);
        stringToUtf8(&tt, &lbl);
    }
    if (key.primary == ITM_SHIFTg and key.keyId == 71) {
        _ = strcpy(&lbl, "      ");
    }
    gtk_label_set_label(lbl_f, &lbl);
    if (r47_longpress) {
        gtk_widget_set_name(lbl_f, "letter");
    } else if (key.fShifted < 0) {
        gtk_widget_set_name(lbl_f, "fShiftedUnderline");
    } else {
        gtk_widget_set_name(lbl_f, "fShifted");
    }

    if (isR47FAM() and key.primary == ITM_SHIFTf) {
        _ = strcpy(&sstmp, softmenuName(if (key.gShifted == ITM_NULL) MNU_HOME else absItem(key.gShifted)));
        r47_longpress = true;
    } else if (isR47FAM() and key.primary == ITM_SHIFTg) {
        _ = strcpy(&sstmp, softmenuName(if (key.gShifted == ITM_NULL) MNU_MyMenu else absItem(key.gShifted)));
        r47_longpress = true;
    } else if (isR47FAM() and key.primary == KEY_fg) {
        if (getSystemFlag(FLAG_HOME_TRIPLE) or getSystemFlag(FLAG_MYM_TRIPLE)) {
            if (key.gShifted == ITM_NULL) {
                if (getSystemFlag(FLAG_HOME_TRIPLE)) {
                    _ = strcpy(&sstmp, softmenuName(MNU_HOME));
                } else if (getSystemFlag(FLAG_MYM_TRIPLE)) {
                    _ = strcpy(&sstmp, softmenuName(MNU_MyMenu));
                }
            } else {
                _ = strcpy(&sstmp, softmenuName(absItem(key.gShifted)));
            }
        } else {
            sstmp[0] = 0;
        }
        r47_longpress = true;
    } else if (key.gShifted == 0) {
        lbl[0] = 0;
    } else {
        _ = strcpy(&sstmp, softmenuName(absItem(key.gShifted)));
    }
    if ((key.gShifted == ITM_op_j or key.gShifted == ITM_op_j_pol) and getSystemFlag(FLAG_CPXj)) {
        sstmp[1] +%= 1;
    }
    if (key.gShifted == ITM_EE_EXP_TH and getSystemFlag(FLAG_CPXj)) {
        sstmp[3] +%= 1;
    }
    stringToUtf8(&sstmp, &lbl);
    if (userKeyLabelSize > 0 and (strEq(&lbl, "DYNMNU") or strEq(&lbl, "XEQ") or strEq(&lbl, "RCL"))) {
        const s = getNthString(userKeyLabel, key_logical_id * 6 + 2);
        if (s[0] != 0) {
            stringToUtf8(s, &lbl);
        }
    }
    if (strEq(&lbl, "MODE#") and key.keyId == 22) {
        _ = strcpy(&lbl, "#");
    } else if (strEq(&lbl, "LINPOL")) {
        _ = strcpy(&lbl, "LIN");
    }
    gtk_label_set_label(lbl_g, &lbl);
    if (r47_longpress) {
        gtk_widget_set_name(lbl_g, "letter");
    } else if (key.gShifted < 0) {
        gtk_widget_set_name(lbl_g, "gShiftedUnderline");
    } else {
        gtk_widget_set_name(lbl_g, "gShifted");
    }

    stringToUtf8(softmenuName(key.primaryAim), &lbl);
    if (key.primaryAim == 0) {
        lbl[0] = 0;
    }
    patchSpaceLabel(&lbl);

    if (debugLabelConsistency(&lbl, "Normal", key, button, true)) {
        return;
    }
    gtk_label_set_label(lbl_l, &lbl);
    gtk_widget_set_name(lbl_l, "letter");
}

/// gtkGui.c labelCaptionAimFa: f-shift face caption in AIM mode.
pub fn labelCaptionAimFa(key: *const calcKey_t, lbl_f: ?*anyopaque) void {
    var lbl: [22]u8 = undefined;
    var r47_longpress = false;

    if (key.primaryAim == ITM_NULL) {
        lbl[0] = 0;
    } else if (isR47FAM() and key.fShiftedAim == ITM_NULL and key.primaryAim == ITM_SHIFTf) {
        stringToUtf8(softmenuName(if (tam.alpha) MNU_TAMALPHA else MNU_ALPHA), &lbl);
        r47_longpress = true;
    } else if (isR47FAM() and key.fShiftedAim == ITM_NULL and key.primaryAim == ITM_SHIFTg) {
        stringToUtf8(softmenuName(MNU_MyAlpha), &lbl);
        r47_longpress = true;
    } else if (isR47FAM() and key.primaryAim == KEY_fg) {
        if (getSystemFlag(FLAG_HOME_TRIPLE)) {
            stringToUtf8(softmenuName(if (tam.alpha) MNU_TAMALPHA else MNU_ALPHA), &lbl);
        } else if (getSystemFlag(FLAG_MYM_TRIPLE)) {
            stringToUtf8(softmenuName(MNU_MyAlpha), &lbl);
        } else {
            lbl[0] = 0;
        }
        r47_longpress = true;
    } else {
        stringToUtf8(softmenuName(@intCast(numlockReplacements(4, absItem(key.fShiftedAim), getSystemFlag(FLAG_NUMLOCK), true, false))), &lbl);
    }

    if (lbl[0] == 32 and lbl[1] == 0) {
        patchSpaceLabel(&lbl);
    } else if (key.fShiftedAim == CHR_caseUP or key.fShiftedAim == CHR_caseDN) {
        lbl[5] = 0;
    }

    if (debugLabelConsistency(&lbl, "labelCaptionAimFa", key, null, false)) {
        return;
    }
    gtk_label_set_label(lbl_f, &lbl);
    if (r47_longpress) {
        gtk_widget_set_name(lbl_f, "letter");
    } else if (key.primary < 0) {
        gtk_widget_set_name(lbl_f, "fShiftedUnderline");
    } else {
        gtk_widget_set_name(lbl_f, "fShifted");
    }
}

/// gtkGui.c labelCaptionAim: primary/g-shift faces in AIM mode.
pub fn labelCaptionAim(key: *const calcKey_t, button: ?*anyopaque, lbl_g: ?*anyopaque, lbl_l: ?*anyopaque) void {
    var lbl: [22]u8 = undefined;

    if (key.keyLblAim == ITM_SHIFTf) {
        _ = strcpy(&lbl, softmenuName(ITM_SHIFTf));
    } else if (key.keyLblAim == ITM_SHIFTg) {
        _ = strcpy(&lbl, softmenuName(ITM_SHIFTg));
    } else if (key.keyLblAim == KEY_fg) {
        _ = strcpy(&lbl, softmenuName(KEY_fg));
    } else if (key.primaryAim == ITM_NULL or key.gShiftedAim == ITM_NULL) {
        lbl[0] = 0;
    } else {
        if (shiftG and (ITM_A <= key.primaryAim and key.primaryAim <= ITM_Z)) {
            stringToUtf8(softmenuName(@intCast(numlockReplacements(5, absItem(key.gShiftedAim), getSystemFlag(FLAG_NUMLOCK), shiftF, shiftG))), &lbl);
        } else if (((!shiftF and (alphaCase == AC_LOWER)) or (shiftF and (alphaCase == AC_UPPER))) and (ITM_A <= key.primaryAim and key.primaryAim <= ITM_Z)) {
            stringToUtf8(softmenuName(@intCast(numlockReplacements(5, absItem(key.primaryAim) + 26, getSystemFlag(FLAG_NUMLOCK), shiftF, shiftG))), &lbl);
        } else {
            if (shiftF) {
                stringToUtf8(softmenuName(@intCast(numlockReplacements(6, absItem(key.fShiftedAim), getSystemFlag(FLAG_NUMLOCK), shiftF, shiftG))), &lbl);
            } else if (shiftG) {
                stringToUtf8(softmenuName(@intCast(numlockReplacements(6, absItem(key.gShiftedAim), getSystemFlag(FLAG_NUMLOCK), shiftF, shiftG))), &lbl);
            } else {
                stringToUtf8(softmenuName(@intCast(numlockReplacements(6, absItem(key.primaryAim), getSystemFlag(FLAG_NUMLOCK), shiftF, shiftG))), &lbl);
            }
        }
    }

    if (lbl[0] == 32 and lbl[1] == 0) {
        patchSpaceLabel(&lbl);
    }

    gtk_button_set_label(button, &lbl);

    if (key.keyLblAim == ITM_SHIFTf) {
        gtk_widget_set_name(button, "calcKeyF");
    } else if (key.keyLblAim == ITM_SHIFTg) {
        gtk_widget_set_name(button, "calcKeyG");
    } else if (key.keyLblAim == KEY_fg) {
        gtk_widget_set_name(button, "calcKeyFG");
    } else {
        gtk_widget_set_name(button, "calcKey");
    }

    stringToUtf8(softmenuName(@intCast(numlockReplacements(10, key.gShiftedAim, getSystemFlag(FLAG_NUMLOCK), false, true))), &lbl);

    if (key.gShiftedAim == 0) {
        lbl[0] = 0;
    }

    gtk_label_set_label(lbl_g, &lbl);

    if (key.gShiftedAim < 0) {
        gtk_widget_set_name(lbl_g, "gShiftedUnderline");
    } else {
        gtk_widget_set_name(lbl_g, "AimfShifted");
    }

    if (key.primaryAim == 0) {
        lbl[0] = 0;
    } else {
        stringToUtf8(softmenuName(key.primaryAim), &lbl);
    }

    if (lbl[0] == 32 and lbl[1] == 0) {
        lbl[0] = 0xC2;
        lbl[1] = 0xB7;
        lbl[2] = ' ';
        lbl[3] = 0xc2;
        lbl[4] = 0xb7;
        lbl[5] = 0;
    }

    if (debugLabelConsistency(&lbl, "labelCaptionAim", key, button, true)) {
        return;
    }
    gtk_label_set_label(lbl_l, &lbl);
    gtk_widget_set_name(lbl_l, "letter");
}

/// gtkGui.c labelCaptionTam: renders a key's TAM-mode (prompt) caption onto its
/// button and assigns the CSS name (shift keys, fg, oversized operators).
pub fn labelCaptionTam(key: *const calcKey_t, button: ?*anyopaque) void {
    var lbl: [22]u8 = undefined;
    lbl[0] = 0;
    if (key.primaryTam != ITM_NULL) {
        stringToUtf8(&indexOfItems[@intCast(key.primaryTam)].itemSoftmenuName, &lbl);
    }

    // THIS IS FOR TAM
    gtk_button_set_label(button, &lbl);

    if (strcmp(&lbl, "/") == 0 and key.keyId == 55) { // if "/", re-do to "divide"
        gtk_button_set_label(button, "÷");
    }

    if (key.primaryTam == ITM_SHIFTf) {
        gtk_widget_set_name(button, "calcKeyF");
    } else if (key.primaryTam == ITM_SHIFTg) {
        gtk_widget_set_name(button, "calcKeyG");
    } else if (key.primaryTam == KEY_fg) {
        gtk_widget_set_name(button, "calcKeyFG");
    } else if (strcmp(&lbl, "/") == 0 and key.keyId == 55) {
        gtk_widget_set_name(button, "calcNumericKey");
    } else if (strcmp(&lbl, "×") == 0 and key.keyId == 65) {
        gtk_widget_set_name(button, "calcNumericKey");
    } else if (strcmp(&lbl, "-") == 0 and key.keyId == 75) {
        gtk_widget_set_name(button, "calcNumericKey");
    } else if (strcmp(&lbl, "+") == 0 and key.keyId == 85) {
        gtk_widget_set_name(button, "calcNumericKey");
    } else {
        gtk_widget_set_name(button, "calcKey");
    }
}

/// Hex / printable-char / decimal dump of a label's raw bytes (gtkGui.c
/// print_label_bytes). Used by the UTF-8 consistency diagnostics.
pub fn printLabelBytes(data: [*c]const u8, length: c_int) void {
    var i: c_int = 0;
    while (i < length) : (i += 1) {
        _ = printf("0x%02x ", @as(c_int, data[@intCast(i)]));
    }
    _ = printf("(");
    i = 0;
    while (i < length) : (i += 1) {
        const b = data[@intCast(i)];
        _ = printf("%c", @as(c_int, if (b >= 32 and b < 127) b else '.'));
    }
    _ = printf("  dec: ");
    i = 0;
    while (i < length) : (i += 1) {
        _ = printf("%03d ", @as(c_int, data[@intCast(i)]));
    }
    _ = printf(")\n");
}

/// gtkGui.c check_utf_string: validates a widget string and, on failure, prints
/// the offending widget/field plus a hex dump. Returns true when an issue was
/// found (the caller ORs these into a per-widget consistency flag).
pub fn checkUtfString(widget_name: [*c]const u8, what: [*c]const u8, s: [*c]const u8) bool {
    if (s == null) {
        return false;
    }
    var bad_pos: usize = 0;
    if (!isValidUtf8(s, &bad_pos)) {
        _ = printf("*** UTF-8 ERROR in %s %s at byte offset %zu ***\n", widget_name, what, bad_pos);
        _ = printf("Corrupted string: ");
        var p = s;
        while (p[0] != 0) : (p += 1) {
            _ = printf("\\x%02x", @as(c_int, p[0]));
        }
        _ = printf("\n");
        return true;
    }
    return false;
}

/// gtkGui.c check_label_consistency: warns on NULL or non-UTF-8 button-label
/// text (length-capped at 22) and returns true when an issue was reported.
pub fn checkLabelConsistency(lbl: [*c]const u8, context: [*c]const u8) bool {
    if (lbl == null) {
        _ = printf("GTK3 Setup utf issue: NULL label in %s\n", context);
        return true;
    }

    // Calculate length safely (stop at 22 or null terminator).
    var len: c_int = 0;
    while (lbl[@intCast(len)] != 0 and len < 22) {
        len += 1;
    }

    if (len == 0) {
        return false; // Empty string is OK
    }

    var bad_pos: usize = 0;
    if (!isValidUtf8(lbl, &bad_pos)) {
        _ = printf("GTK3 Setup utf issue: Invalid UTF-8 at position %zu in %s: ", bad_pos, context);
        printLabelBytes(lbl, len);
        return true;
    }

    return false; // All good
}

/// Faithful port of gtkGui.c is_valid_utf8(): validates a NUL-terminated string
/// as well-formed UTF-8, rejecting overlong forms, surrogates, and the U+xxFFFE
/// / U+xxFFFF noncharacters. On the first invalid byte it records that byte
/// offset in error_offset (when non-null) and returns false.
pub fn isValidUtf8(s: [*c]const u8, error_offset: [*c]usize) bool {
    var i: usize = 0;
    while (s[i] != 0) {
        const c0 = s[i];
        if (c0 < 0x80) {
            i += 1;
        } else if ((c0 & 0xE0) == 0xC0) {
            if ((s[i + 1] & 0xC0) != 0x80 or (c0 & 0xFE) == 0xC0) {
                if (error_offset != null) error_offset[0] = i;
                return false;
            }
            i += 2;
        } else if ((c0 & 0xF0) == 0xE0) {
            if ((s[i + 1] & 0xC0) != 0x80 or (s[i + 2] & 0xC0) != 0x80) {
                if (error_offset != null) error_offset[0] = i;
                return false;
            }
            const cp: u32 = (@as(u32, c0 & 0x0F) << 12) |
                (@as(u32, s[i + 1] & 0x3F) << 6) |
                @as(u32, s[i + 2] & 0x3F);
            if (cp < 0x800 or (cp >= 0xD800 and cp <= 0xDFFF)) {
                if (error_offset != null) error_offset[0] = i;
                return false;
            }
            if (cp == 0xFFFE or cp == 0xFFFF) {
                if (error_offset != null) error_offset[0] = i;
                return false;
            }
            i += 3;
        } else if ((c0 & 0xF8) == 0xF0) {
            if ((s[i + 1] & 0xC0) != 0x80 or (s[i + 2] & 0xC0) != 0x80 or (s[i + 3] & 0xC0) != 0x80) {
                if (error_offset != null) error_offset[0] = i;
                return false;
            }
            const cp: u32 = (@as(u32, c0 & 0x07) << 18) |
                (@as(u32, s[i + 1] & 0x3F) << 12) |
                (@as(u32, s[i + 2] & 0x3F) << 6) |
                @as(u32, s[i + 3] & 0x3F);
            if (cp < 0x10000 or cp > 0x10FFFF) {
                if (error_offset != null) error_offset[0] = i;
                return false;
            }
            if ((cp & 0xFFFF) == 0xFFFE or (cp & 0xFFFF) == 0xFFFF) {
                if (error_offset != null) error_offset[0] = i;
                return false;
            }
            i += 4;
        } else {
            if (error_offset != null) error_offset[0] = i;
            return false;
        }
    }
    return true;
}
