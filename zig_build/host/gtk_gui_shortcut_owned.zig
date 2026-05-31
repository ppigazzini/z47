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
const USER_DM42: u8 = 45;
const USER_C47: u8 = 46;
const USER_R47f_g: u8 = 61;
const USER_R47bk_fg: u8 = 62;
const USER_R47fg_bk: u8 = 63;
const USER_R47fg_g: u8 = 64;
const USER_R47: u8 = 66;
const ITM_NULL: i16 = 0;
const ITM_SIGMAPLUS: i16 = 433;
const TI_NO_INFO: u8 = 0;
const SCRUPD_AUTO: u8 = 0x00;
const TM_FLAGR: u16 = 10004;
const TM_FLAGW: u16 = 10005;
const TM_STORCL: u16 = 10006;
const TM_LABEL: u16 = 10009;
const TM_SOLVE: u16 = 10010;
const TM_MENU: u16 = 10017;
const TM_LBLONLY: u16 = 10018;

extern var calcMode: u8;
extern var calcModel: u8;
extern var catalog: i16;
extern var temporaryInformation: u8;
extern var screenUpdatingMode: u8;
extern var shiftF: bool;
extern var shiftG: bool;
extern var tam: tamState_t;
extern var kbd_usr: [37]calcKey_t;
extern var kbd_std_C47: [37]calcKey_t;
extern var kbd_std_DM42: [37]calcKey_t;
extern var kbd_std_R47f_g: [37]calcKey_t;
extern var kbd_std_R47bk_fg: [37]calcKey_t;
extern var kbd_std_R47fg_bk: [37]calcKey_t;
extern var kbd_std_R47fg_g: [37]calcKey_t;

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
extern fn Check_Norm_Key_00_Assigned(result: *i16, tempkey: i16) i16;

pub fn normKey00ItemInLayout() i16 {
    return switch (calcModel) {
        USER_C47, USER_DM42 => ITM_SIGMAPLUS,
        USER_R47f_g => -1,
        USER_R47bk_fg, USER_R47fg_bk => ITM_NULL,
        USER_R47fg_g => ITM_NULL,
        else => -1,
    };
}

pub fn shortcutProfileValue() u8 {
    if (calcModel == USER_C47) return USER_C47;
    if (calcModel == USER_R47f_g or calcModel == USER_R47bk_fg or calcModel == USER_R47fg_bk or calcModel == USER_R47fg_g) {
        return USER_R47;
    }
    return 0;
}

pub fn currentStdKeyboard() *const [37]calcKey_t {
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

pub fn isLabelText() bool {
    return (tam.mode == TM_MENU or tam.mode == TM_LABEL or tam.mode == TM_LBLONLY or tam.mode == TM_SOLVE or tam.mode == TM_STORCL or tam.alpha) and getSystemFlag(FLAG_ALPHA);
}

pub fn alphaArrowsOffAndUpDn() bool {
    return tam.mode == TM_FLAGR or tam.mode == TM_FLAGW or tam.mode == TM_STORCL or tam.mode == TM_MENU;
}

pub fn checkNormal(key_nr: i16, item: i16) bool {
    var result: i16 = normKey00ItemInLayout();
    const ss = Check_Norm_Key_00_Assigned(&result, key_nr);
    return ss == item;
}

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
    _ = shortcutProfileValue;
    if (disable) return false;

    if (isLabelText() and key != '\'' and key != 65362 and key != 65364) {
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
    if (isLabelText()) return false;

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
    return shortCutFNCommand(
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
