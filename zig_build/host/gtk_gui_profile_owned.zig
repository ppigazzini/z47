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

const USER_DM42: u8 = 45;
const USER_C47: u8 = 46;
const USER_R47f_g: u8 = 61;
const USER_R47bk_fg: u8 = 62;
const USER_R47fg_bk: u8 = 63;
const USER_R47fg_g: u8 = 64;
const USER_R47: u8 = 66;
const ITM_NULL: i16 = 0;
const ITM_SIGMAPLUS: i16 = 433;
const FLAG_ALPHA: u16 = 0x800e;
const TM_FLAGR: u16 = 10004;
const TM_FLAGW: u16 = 10005;
const TM_STORCL: u16 = 10006;
const TM_LABEL: u16 = 10009;
const TM_SOLVE: u16 = 10010;
const TM_MENU: u16 = 10017;
const TM_LBLONLY: u16 = 10018;

extern var calcModel: u8;
extern var tam: tamState_t;
extern var kbd_usr: [37]calcKey_t;
extern var kbd_std_C47: [37]calcKey_t;
extern var kbd_std_DM42: [37]calcKey_t;
extern var kbd_std_R47f_g: [37]calcKey_t;
extern var kbd_std_R47bk_fg: [37]calcKey_t;
extern var kbd_std_R47fg_bk: [37]calcKey_t;
extern var kbd_std_R47fg_g: [37]calcKey_t;
extern fn getSystemFlag(flag: u16) bool;
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
