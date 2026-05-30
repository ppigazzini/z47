const profile_owned = @import("gtk_gui_profile_owned.zig");

const calcKey_t = extern struct {
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

const KEY_fg: i16 = 1893;
const ITM_SHIFTf: i16 = 1731;
const ITM_SHIFTg: i16 = 1732;
const FLAG_NUMLOCK: u16 = 0x8043;
const FLAG_USER: u16 = 0x8014;
const FLAG_ALPHA: u16 = 0x800e;
const CM_NORMAL: u8 = 0;
const CM_NIM: u8 = 2;
const CM_PEM: u8 = 3;
const TI_NO_INFO: u8 = 0;
const SCRUPD_AUTO: u8 = 0x00;

extern var calcMode: u8;
extern var catalog: i16;
extern var temporaryInformation: u8;
extern var screenUpdatingMode: u8;
extern var shiftF: bool;
extern var shiftG: bool;
extern var tam: tamState_t;
extern var kbd_usr: [37]calcKey_t;

extern fn btnClicked(widget: ?*anyopaque, data: [*:0]const u8) void;
extern fn refreshStatusBar() void;
extern fn showHideAlphaMode() void;
extern fn processAimInput(item: i16) void;
extern fn pemAlpha(item: i16) void;
extern fn clearSystemFlag(flag: u16) void;
extern fn setSystemFlag(flag: u16) void;
extern fn getSystemFlag(flag: u16) bool;
extern fn currentMenu() i16;
extern fn showSoftmenu(id: i16) void;
extern fn runFunction(func: i16) void;
extern fn closeNim() void;
extern fn refreshScreen(source: u16) void;
extern fn btnFnClicked(widget: ?*anyopaque, data: [*:0]const u8) void;

pub fn btnClickedNU(widget: ?*anyopaque, data: ?*anyopaque) void {
    const num_lock_mem = getSystemFlag(FLAG_NUMLOCK);

    clearSystemFlag(FLAG_NUMLOCK);
    shiftF = false;
    shiftG = true;
    if (data) |raw_data| {
        btnClicked(widget, @as([*:0]const u8, @ptrCast(raw_data)));
    }

    if (num_lock_mem) {
        setSystemFlag(FLAG_NUMLOCK);
    } else {
        clearSystemFlag(FLAG_NUMLOCK);
    }
    refreshStatusBar();
}

pub fn sendKey(sent: i16) void {
    showHideAlphaMode();
    if (calcMode == CM_PEM and tam.mode == 0 and getSystemFlag(FLAG_ALPHA) and catalog == 0) {
        pemAlpha(sent);
    } else {
        processAimInput(sent);
    }
}

pub fn shortCutCommand(
    widget: ?*anyopaque,
    key: c_int,
    keyCode: c_int,
    condition1: bool,
    exitIfInNIM: bool,
    disable: bool,
    shift: [*:0]const u8,
    keyForBtnClicked: [*:0]const u8,
    modes: u16,
    requiredCalcMode2: i16,
    itemForRunFunction: i16,
) bool {
    _ = currentMenu;
    _ = profile_owned.shortcutProfileValue;
    if (disable) return false;

    if (profile_owned.isLabelText() and key != '\'' and key != 65362 and key != 65364) {
        return false;
    }

    if ((shiftF or shiftG) and
        !(shift[0] == 0 and keyForBtnClicked[0] != '-') and
        !(shiftF and shift[0] == 'f' and keyForBtnClicked[0] != '-') and
        !(shiftG and shift[0] == 'g' and keyForBtnClicked[0] != '-')) {
        return false;
    }

    if (key == keyCode and condition1) {
        temporaryInformation = TI_NO_INFO;

        if (exitIfInNIM and calcMode == CM_NIM and calcMode != requiredCalcMode2) {
            closeNim();
        }

        if (itemForRunFunction < 0) {
            showSoftmenu(itemForRunFunction);
            screenUpdatingMode = SCRUPD_AUTO;
            refreshScreen(1);
            return true;
        }

        if (((@as(u32, 1) << @as(u5, @intCast(calcMode))) & @as(u32, modes)) != 0 or calcMode == @as(u8, @intCast(requiredCalcMode2))) {
            if (keyForBtnClicked[0] != '-') {
                if (shift[0] == 'f') {
                    shiftF = true;
                    shiftG = false;
                } else if (shift[0] == 'g') {
                    shiftF = false;
                    shiftG = true;
                }
                btnClicked(widget, keyForBtnClicked);
                screenUpdatingMode = SCRUPD_AUTO;
                refreshScreen(2);
                return true;
            }

            if (itemForRunFunction >= 0) {
                runFunction(itemForRunFunction);
                screenUpdatingMode = SCRUPD_AUTO;
                refreshScreen(3);
                return true;
            }
        }
    }

    return false;
}

pub fn shortCutFNCommand(
    widget: ?*anyopaque,
    key: c_int,
    keyCode: c_int,
    condition1: bool,
    disable: bool,
    shift: [*:0]const u8,
    keyForBtnClicked: [*:0]const u8,
    modes: u16,
    requiredCalcMode2: i16,
    itemForRunFunction: i16,
) bool {
    if (disable) return false;
    if (profile_owned.isLabelText()) return false;

    if (key == keyCode and condition1) {
        temporaryInformation = TI_NO_INFO;

        if (((@as(u32, 1) << @as(u5, @intCast(calcMode))) & @as(u32, modes)) != 0 or calcMode == @as(u8, @intCast(requiredCalcMode2))) {
            if (keyForBtnClicked[0] != '-') {
                if (shift[0] == 'f') {
                    shiftF = true;
                    shiftG = false;
                } else if (shift[0] == 'g') {
                    shiftF = false;
                    shiftG = true;
                }
                btnFnClicked(widget, keyForBtnClicked);
                screenUpdatingMode = SCRUPD_AUTO;
                refreshScreen(5);
                return true;
            }

            if (itemForRunFunction >= 0) {
                runFunction(itemForRunFunction);
                screenUpdatingMode = SCRUPD_AUTO;
                refreshScreen(6);
                return true;
            }
        }
    }

    return false;
}
