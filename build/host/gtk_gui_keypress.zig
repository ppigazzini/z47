// Owner module for z47_keyPressed_c_impl (ported from src/c47-gtk/gtkGui.c
// keyPressed handler). Host-sim only (PC_BUILD / on-screen keyboard). The full
// C body is reproduced here faithfully; control flow that used C goto/return is
// modelled with labeled blocks (see keyPressedCImpl).
const shortcut_owned = @import("gtk_gui_shortcut.zig");
const keymap_owned = @import("gtk_gui_keymap.zig");

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

const softmenu_t = extern struct {
    menuItem: i16,
    numItems: i16,
    softkeyItem: ?*const i16,
};

const softmenuStack_t = extern struct {
    softmenuId: i16,
    firstItem: i16,
    userMenuId: i16,
    calcMode: u8,
};

const GdkEventKey = extern struct {
    type: c_int,
    window: ?*anyopaque,
    send_event: c_int,
    time: c_uint,
    state: c_uint,
    keyval: c_uint,
    length: c_int,
    string: ?[*:0]u8,
    hardware_keycode: c_uint,
    group: c_uint,
    is_modifier: c_uint,
};

// --- constants the macros/switches need (kept untyped so they coerce to
// c_int / u16 / i16 at each use site) ---
const FLAG_ALPHA: u16 = 0x800e;
const FLAG_USER: u16 = 0x8014;
const AC_UPPER = 0;
const AC_LOWER = 1;
const KEY_fg = 1893;
const USER_R47f_g = 61;
const USER_R47fg_g = 64;
const TI_SHOW_REGISTER = 14;
const TI_SHOW_REGISTER_BIG = 75;
const TI_SHOW_REGISTER_SMALL = 76;
const TI_SHOW_REGISTER_TINY = 77;
const TI_SHOWNOTHING = 93;
const MNU_ALPHA = 1922;
const MNU_M_EDIT = 1348;
const MNU_EQ_EDIT = 1399;
const MNU_SYSFL = 1379;
const MNU_VAR = 1389;
const MNU_PROG = 1392;
const MNU_ALPHA_OMEGA = 1377;
const MNU_alpha_omega = 1383;
const MNU_ALPHAMISC = 1378;
const MNU_ALPHAMATH = 1375;
const MNU_ALPHAINTL = 1374;
const MNU_ALPHAintl = 1384;
const GDK_KEY_Shift_L = 65505;
const GDK_KEY_Shift_R = 65506;
const GDK_KEY_Alt_R = 65514;
const GDK_KEY_A = 65;
const GDK_KEY_B = 66;
const GDK_KEY_BackSpace = 65288;
const GDK_KEY_C = 67;
const GDK_KEY_Control_L = 65507;
const GDK_KEY_Control_R = 65508;
const GDK_KEY_D = 68;
const GDK_KEY_Delete = 65535;
const GDK_KEY_Down = 65364;
const GDK_KEY_E = 69;
const GDK_KEY_End = 65367;
const GDK_KEY_F = 70;
const GDK_KEY_F1 = 65470;
const GDK_KEY_F10 = 65479;
const GDK_KEY_F11 = 65480;
const GDK_KEY_F2 = 65471;
const GDK_KEY_F3 = 65472;
const GDK_KEY_F4 = 65473;
const GDK_KEY_F5 = 65474;
const GDK_KEY_F6 = 65475;
const GDK_KEY_F7 = 65476;
const GDK_KEY_F8 = 65477;
const GDK_KEY_F9 = 65478;
const GDK_KEY_G = 71;
const GDK_KEY_H = 72;
const GDK_KEY_Home = 65360;
const GDK_KEY_I = 73;
const GDK_KEY_J = 74;
const GDK_KEY_K = 75;
const GDK_KEY_KP_Delete = 65439;
const GDK_KEY_KP_Enter = 65421;
const GDK_KEY_L = 76;
const GDK_KEY_Left = 65361;
const GDK_KEY_M = 77;
const GDK_KEY_N = 78;
const GDK_KEY_O = 79;
const GDK_KEY_P = 80;
const GDK_KEY_Q = 81;
const GDK_KEY_R = 82;
const GDK_KEY_Return = 65293;
const GDK_KEY_Right = 65363;
const GDK_KEY_S = 83;
const GDK_KEY_T = 84;
const GDK_KEY_Tab = 65289;
const GDK_KEY_U = 85;
const GDK_KEY_Up = 65362;
const GDK_KEY_V = 86;
const GDK_KEY_W = 87;
const GDK_KEY_X = 88;
const GDK_KEY_Y = 89;
const GDK_KEY_Z = 90;
const GDK_KEY_a = 97;
const GDK_KEY_ampersand = 38;
const GDK_KEY_apostrophe = 39;
const GDK_KEY_asciicircum = 94;
const GDK_KEY_at = 64;
const GDK_KEY_b = 98;
const GDK_KEY_backslash = 92;
const GDK_KEY_bar = 124;
const GDK_KEY_c = 99;
const GDK_KEY_colon = 58;
const GDK_KEY_comma = 44;
const GDK_KEY_d = 100;
const GDK_KEY_dollar = 36;
const GDK_KEY_e = 101;
const GDK_KEY_eacute = 233;
const GDK_KEY_equal = 61;
const GDK_KEY_exclam = 33;
const GDK_KEY_f = 102;
const GDK_KEY_g = 103;
const GDK_KEY_greater = 62;
const GDK_KEY_h = 104;
const GDK_KEY_i = 105;
const GDK_KEY_j = 106;
const GDK_KEY_k = 107;
const GDK_KEY_l = 108;
const GDK_KEY_less = 60;
const GDK_KEY_m = 109;
const GDK_KEY_n = 110;
const GDK_KEY_numbersign = 35;
const GDK_KEY_o = 111;
const GDK_KEY_p = 112;
const GDK_KEY_percent = 37;
const GDK_KEY_period = 46;
const GDK_KEY_q = 113;
const GDK_KEY_question = 63;
const GDK_KEY_quotedbl = 34;
const GDK_KEY_r = 114;
const GDK_KEY_s = 115;
const GDK_KEY_semicolon = 59;
const GDK_KEY_t = 116;
const GDK_KEY_twosuperior = 178;
const GDK_KEY_u = 117;
const GDK_KEY_v = 118;
const GDK_KEY_w = 119;
const GDK_KEY_x = 120;
const GDK_KEY_y = 121;
const GDK_KEY_z = 122;
const CM_AIM = 1;
const CM_ASSIGN = 4;
const CM_EIM = 13;
const CM_MIM = 12;
const CM_NIM = 2;
const CM_NORMAL = 0;
const CM_PEM = 3;
const CST_09 = 136;
const ITM_10x = 67;
const ITM_1ONX = 73;
const ITM_AIM = 1740;
const ITM_ARG = 1706;
const ITM_CHS = 97;
const ITM_CONSTpi = 109;
const ITM_DRG = 1873;
const ITM_ENTER = 35;
const ITM_EXP = 65;
const ITM_EXPONENT = 990;
const ITM_GTO = 2;
const ITM_HASH_JM = 1872;
const ITM_LASTX = 1502;
const ITM_LBL = 1;
const ITM_LN = 69;
const ITM_LOG10 = 71;
const ITM_MAGNITUDE = 105;
const ITM_PC = 1695;
const ITM_PR = 1724;
const ITM_RCL = 51;
const ITM_REG_A = 531;
const ITM_REG_B = 532;
const ITM_REG_C = 533;
const ITM_REG_D = 534;
const ITM_REG_E = 2342;
const ITM_REG_F = 2343;
const ITM_REG_G = 2344;
const ITM_REG_H = 2345;
const ITM_REG_I = 536;
const ITM_REG_J = 537;
const ITM_REG_K = 538;
const ITM_REG_L = 535;
const ITM_REG_M = 2336;
const ITM_REG_N = 2337;
const ITM_REG_O = 2346;
const ITM_REG_P = 2338;
const ITM_REG_Q = 2339;
const ITM_REG_R = 2340;
const ITM_REG_S = 2341;
const ITM_REG_T = 530;
const ITM_REG_U = 2347;
const ITM_REG_V = 2348;
const ITM_REG_W = 2349;
const ITM_REG_X = 527;
const ITM_REG_Y = 528;
const ITM_REG_Z = 529;
const ITM_RI = 1871;
const ITM_RTN = 4;
const ITM_Rdown = 40;
const ITM_Rup = 39;
const ITM_SHIFTf = 1731;
const ITM_SHIFTg = 1732;
const ITM_SIGMAPLUS = 433;
const ITM_SI_M = 1806;
const ITM_SI_k = 1805;
const ITM_SI_m = 1804;
const ITM_SI_n = 1802;
const ITM_SI_u = 1803;
const ITM_SQUARE = 58;
const ITM_SQUAREROOTX = 61;
const ITM_STO = 44;
const ITM_STOP = 70;
const ITM_TGLFRT = 1422;
const ITM_T_RIGHT_ARROW = 1953;
const ITM_USERMODE = 1729;
const ITM_XEQ = 3;
const ITM_XFACT = 108;
const ITM_XTHROOT = 63;
const ITM_XexY = 36;
const ITM_YX = 60;
const ITM_arccos = 81;
const ITM_arcsin = 83;
const ITM_arctan = 85;
const ITM_cos = 74;
const ITM_dotD = 1741;
const ITM_ms = 1909;
const ITM_op_j = 1830;
const ITM_op_j_pol = 1795;
const ITM_sin = 76;
const ITM_tan = 79;
const ITM_toPOL2 = 1849;
const ITM_toREC2 = 1850;
const KEY_COMPLEX = 1848;
const MNU_DISP = 1326;
const MNU_EXP = 1328;
const MNU_HOME = 1921;
const MNU_MODE = 1346;
const MNU_MVAR = 1398;
const MNU_MyMenu = 1349;
const MNU_PREF = 2037;
const MNU_PREFIX = 2229;
const MNU_STK = 1363;
const NOPARAM = 9876;
const SCRUPD_AUTO = 0;
const TM_FLAGR = 10004;
const TM_FLAGW = 10005;
const TM_REGISTER = 10003;
const TM_STORCL = 10006;
const USER_C47 = 46;
const USER_R47 = 66;
const USER_R47bk_fg = 62;
const USER_R47fg_bk = 63;

// Keyboard-event globals (were defined in gtkGui.c). They now live here, the
// only remaining consumer besides events_owned (which keeps its own prologue
// copies). Initializers match the original C definitions.
pub export var CTRL_State: u32 = 0;
pub export var SHIFT_State: u32 = 0;
pub export var event_keyval: u32 = 99999999;
pub export var event_command_shift: u32 = 0;
pub export var event_key_command: u32 = 99999999;
pub export var previousEventStateP: u32 = 0;
pub export var previousEventKeyP: u32 = 0;

extern var calcMode: u8;
extern var calcModel: u8;
extern var catalog: i16;
extern var temporaryInformation: u8;
extern var screenUpdatingMode: u8;
extern var shiftF: bool;
extern var shiftG: bool;
extern var lastshiftF: bool;
extern var lastshiftG: bool;
extern var alphaCase: u8;
extern var itemToBeAssigned: i16;
extern var swapCtrlCode: bool;
extern var tam: tamState_t;
extern var kbd_usr: [37]calcKey_t;
extern const softmenu: [256]softmenu_t;
extern var softmenuStack: [8]softmenuStack_t;

extern fn btnClicked(widget: ?*anyopaque, data: [*:0]const u8) void;
extern fn btnFnClicked(widget: ?*anyopaque, data: [*:0]const u8) void;
extern fn btnFnClickedP(widget: ?*anyopaque, data: [*:0]const u8) void;
extern fn getSystemFlag(flag: u16) bool;
extern fn currentMenu() i16;
extern fn refreshStatusBar() void;
extern fn showShiftState() void;
extern fn resetShiftState() void;
extern fn refreshScreen(source: u16) void;
extern fn refreshLcd(unusedData: ?*anyopaque) c_int;
extern fn addItemToBuffer(item: u16) void;
extern fn fnT_ARROW(command: u16) void;
extern fn fnSNAP(unused: u16) void;
extern fn copyScreenToClipboard() void;
extern fn copyMenuToClipboard() void;
extern fn copyRegisterXToClipboard() void;
extern fn copyStackRegistersToClipboard() void;
extern fn copyAllRegistersToClipboard() void;
extern fn printf(format: [*:0]const u8, ...) c_int;

fn eventKeyStripCapslock(event: *GdkEventKey) u32 {
    const kv = event.keyval;
    if ((kv >= 'A' and kv <= 'Z') or (kv >= 'a' and kv <= 'z')) {
        return (kv & 0xFFFFDF) + (0x20 & ~(event_command_shift >> (16 - 5)));
    }
    return kv;
}

fn showMode() bool {
    return calcMode == CM_NORMAL and (temporaryInformation == TI_SHOW_REGISTER or
        temporaryInformation == TI_SHOW_REGISTER_BIG or temporaryInformation == TI_SHOW_REGISTER_SMALL or
        temporaryInformation == TI_SHOW_REGISTER_TINY or temporaryInformation == TI_SHOWNOTHING);
}

fn isR47FAM() bool {
    return calcModel == USER_R47f_g or calcModel == USER_R47bk_fg or
        calcModel == USER_R47fg_bk or calcModel == USER_R47fg_g;
}

fn tamArrowsMacro() bool {
    return shortcut_owned.isLabelText() or tam.mode == TM_FLAGW or tam.mode == TM_FLAGR;
}

fn alphaArrowsMacro() bool {
    const idx: usize = @intCast(softmenuStack[0].softmenuId);
    const mi = softmenu[idx].menuItem;
    return mi == -MNU_SYSFL or mi == -MNU_VAR or mi == -MNU_PROG or
        mi == -MNU_ALPHA_OMEGA or mi == -MNU_alpha_omega or mi == -MNU_ALPHAMISC or
        mi == -MNU_ALPHAMATH or mi == -MNU_ALPHAINTL or mi == -MNU_ALPHAintl;
}

fn isSimArrowAllowedInMenu(menu: i16, key: u32) bool {
    return (menu == -MNU_ALPHA and (key == GDK_KEY_Up or key == GDK_KEY_Down or key == GDK_KEY_Left or key == GDK_KEY_Right)) or
        (menu == -MNU_M_EDIT and (key == GDK_KEY_Up or key == GDK_KEY_Down or key == GDK_KEY_Left or key == GDK_KEY_Right)) or
        (menu == -MNU_EQ_EDIT and (key == GDK_KEY_Left or key == GDK_KEY_Right));
}

fn nu(widget: ?*anyopaque, s: [*:0]const u8) void {
    shortcut_owned.btnClickedNU(widget, @ptrCast(@constCast(s)));
}

pub fn keyPressedCImpl(w: ?*anyopaque, event_opaque: ?*anyopaque, data: ?*anyopaque) c_int {
    _ = data;
    const event: *GdkEventKey = @ptrCast(@alignCast(event_opaque.?));
    const shortCutCommand = shortcut_owned.shortCutCommand;
    const shortCutFNCommand = shortcut_owned.shortCutFNCommand;
    const shortcutProfile = shortcut_owned.shortcutProfileValue();
    const std_kbd = shortcut_owned.currentStdKeyboard();

    event_keyval = event.keyval + CTRL_State;

    const ctrl_pressed = if (swapCtrlCode)
        (event.keyval == GDK_KEY_Control_L and (event.state & 0b00100) == 0)
    else
        (event.keyval == GDK_KEY_Control_L and (event.state & 0b00100) != 0);
    const altgr_pressed = event.keyval == GDK_KEY_Alt_R and (event.state & 0b10100) != 0;
    const allow_altgr = !altgr_pressed and !ctrl_pressed and (event.state & 0b11100) != 0;

    body: {
        middle: {
            if (ctrl_pressed) break :middle;

            if (altgr_pressed) {
                SHIFT_State = 0;
                event_command_shift = 0;
                CTRL_State = 0;
                shiftF = false;
                shiftG = false;
                refreshStatusBar();
                showShiftState();
                break :body;
            }

            SHIFT_State = 0;
            switch (event_keyval) {
                GDK_KEY_Shift_L, GDK_KEY_Shift_R => {
                    SHIFT_State = 65536;
                    event_command_shift = 65536;
                },
                GDK_KEY_Control_L, GDK_KEY_Control_R => {
                    CTRL_State = 65536;
                },
                else => {},
            }

            if (CTRL_State == 65536 and !ctrl_pressed) break :middle;

            const in_text_modes = calcMode == CM_AIM or calcMode == CM_EIM or tam.mode != 0 or
                (calcMode == CM_PEM and getSystemFlag(FLAG_ALPHA)) or tam.alpha;
            if (!in_text_modes) {
                switch (eventKeyStripCapslock(event)) {
                    GDK_KEY_f => {
                        if (shortcut_owned.checkNormal(0, ITM_SHIFTf)) btnClicked(w, "00") else if (shortcut_owned.checkNormal(10, ITM_SHIFTf)) btnClicked(w, "10") else if (shortcut_owned.checkNormal(11, ITM_SHIFTf)) btnClicked(w, "11") else if ((if (getSystemFlag(FLAG_USER)) kbd_usr[10].primary else std_kbd[10].primary) == ITM_SHIFTf) btnClicked(w, "10") else if ((if (getSystemFlag(FLAG_USER)) kbd_usr[11].primary else std_kbd[11].primary) == ITM_SHIFTf) btnClicked(w, "11") else if ((if (getSystemFlag(FLAG_USER)) kbd_usr[10].primary else std_kbd[10].primary) == KEY_fg) btnClicked(w, "10") else if ((if (getSystemFlag(FLAG_USER)) kbd_usr[11].primary else std_kbd[11].primary) == KEY_fg) btnClicked(w, "11") else if ((if (getSystemFlag(FLAG_USER)) kbd_usr[27].primary else std_kbd[27].primary) == KEY_fg) btnClicked(w, "27");
                    },
                    GDK_KEY_g => {
                        if (shortcut_owned.checkNormal(0, ITM_SHIFTg)) btnClicked(w, "00") else if (shortcut_owned.checkNormal(10, ITM_SHIFTg)) btnClicked(w, "10") else if (shortcut_owned.checkNormal(11, ITM_SHIFTg)) btnClicked(w, "11") else if ((if (getSystemFlag(FLAG_USER)) kbd_usr[11].primary else std_kbd[11].primary) == ITM_SHIFTg) btnClicked(w, "11") else if ((if (getSystemFlag(FLAG_USER)) kbd_usr[10].primary else std_kbd[10].primary) == ITM_SHIFTg) btnClicked(w, "10") else {
                            shiftF = false;
                            shiftG = !shiftG;
                            refreshStatusBar();
                            showShiftState();
                        }
                    },
                    else => {},
                }
            }

            if ((CTRL_State != 65536 or allow_altgr) and
                (catalog == 0 or (catalog != 0 and currentMenu() == -MNU_MVAR)) and
                (!(tamArrowsMacro() or tam.mode == TM_STORCL or tam.mode == TM_MENU) or @as(u8, @truncate(event.keyval)) == GDK_KEY_apostrophe) and
                (calcMode == CM_NORMAL or calcMode == CM_NIM or calcMode == CM_PEM or calcMode == CM_TIMER or (calcMode == CM_ASSIGN and itemToBeAssigned == 0)) and
                !getSystemFlag(FLAG_ALPHA))
            {
                event_key_command = eventKeyStripCapslock(event);
                const ekc: c_int = @bitCast(event_key_command);

                switch (event_keyval) {
                    GDK_KEY_backslash, GDK_KEY_z => {
                        if (showMode()) {
                            btnClicked(w, "35");
                            break :body;
                        }
                    },
                    else => {},
                }

                if (shortCutCommand(w, ekc, GDK_KEY_a, shortcutProfile == USER_C47, true, tam.mode != 0, "", "00", 0b0100000000001101, -1, ITM_SIGMAPLUS)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_v, shortcutProfile == USER_C47, true, tam.mode != 0, "", "01", 0b01101, -1, ITM_1ONX)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_q, shortcutProfile == USER_C47, true, tam.mode != 0, "", "02", 0b01101, -1, ITM_SQUAREROOTX)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_o, shortcutProfile == USER_C47, true, tam.mode != 0, "", "03", 0b01101, -1, ITM_LOG10)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_l, shortcutProfile == USER_C47, true, tam.mode != 0, "", "04", 0b01101, -1, ITM_LN)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_x, shortcutProfile == USER_C47, false, false, "", "05", 0b01101, -1, ITM_XEQ)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_m, shortcutProfile == USER_C47, true, tam.mode != 0, "", "06", 0b01101, -1, ITM_STO)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_r, shortcutProfile == USER_C47, true, tam.mode != 0, "", "07", 0b01101, -1, ITM_RCL)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_d, shortcutProfile == USER_C47, true, tam.mode != 0, "", "08", 0b01101, -1, ITM_Rdown)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_s, shortcutProfile == USER_C47, true, tam.mode != 0, "", "09", 0b01101, -1, ITM_sin)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_i, shortcutProfile == USER_C47, false, tam.mode != 0, "g", "09", 0b11101, -1, ITM_op_j)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_j, shortcutProfile == USER_C47, false, tam.mode != 0, "g", "09", 0b11101, -1, ITM_op_j)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_k, shortcutProfile == USER_C47, false, tam.mode != 0, "", "-01", 0b01101, -1, ITM_op_j_pol)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_c, shortcutProfile == USER_C47, true, tam.mode != 0, "", "10", 0b01101, -1, ITM_cos)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_t, shortcutProfile == USER_C47, true, tam.mode != 0, "", "11", 0b01101, -1, ITM_tan)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_Return, false, false, false, "", "12", 0b01101, -1, ITM_ENTER)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_Tab, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, false, tam.mode != 0, "", "13", 0b01101, -1, ITM_XexY)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_w, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, false, tam.mode != 0, "", "13", 0b01101, -1, ITM_XexY)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_n, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, false, tam.mode != 0, "", "14", 0b01101, -1, ITM_CHS)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_e, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, false, tam.mode != 0, "", "15", 0b01101, -1, ITM_EXPONENT)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_greater, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, true, tam.mode != 0, "", "-01", 0b01101, -1, ITM_DRG)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_Y, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, true, tam.mode != 0, "", "-01", 0b01101, -1, ITM_YX)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_X, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, true, tam.mode != 0, "", "-01", 0b01101, -1, KEY_COMPLEX)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_R, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, true, tam.mode != 0, "", "-01", 0b01101, -1, ITM_toREC2)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_P, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, true, tam.mode != 0, "", "-01", 0b01101, -1, ITM_toPOL2)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_p, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, true, tam.mode != 0, "", "-01", 0b01101, -1, ITM_CONSTpi)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_V, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, true, tam.mode != 0, "", "-01", 0b01101, -1, ITM_1ONX)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_y, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, true, tam.mode != 0, "", "-01", 0b01101, -1, ITM_XTHROOT)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_C, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, true, tam.mode != 0, "", "-01", 0b01101, -1, ITM_arccos)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_S, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, true, tam.mode != 0, "", "-01", 0b01101, -1, ITM_arcsin)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_T, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, true, tam.mode != 0, "", "-01", 0b01101, -1, ITM_arctan)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_L, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, true, tam.mode != 0, "", "-01", 0b01101, -1, ITM_EXP)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_O, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, true, tam.mode != 0, "", "-01", 0b01101, -1, ITM_10x)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_Q, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, true, tam.mode != 0, "", "-01", 0b01101, -1, ITM_SQUARE)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_D, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, true, tam.mode != 0, "", "-01", 0b01101, -1, ITM_Rup)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_I, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, false, false, "", "-01", 0b0000011000000001101, -1, -MNU_DISP)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_J, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, false, false, "", "-01", 0b0000011000000001101, -1, -MNU_EXP)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_K, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, false, false, "", "-01", 0b0000011000000001101, -1, -MNU_STK)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_M, shortcutProfile == USER_C47, false, false, "", "-01", 0b0000011000000001101, -1, -MNU_MODE)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_F, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, false, false, "", "-01", 0b0000011000000001101, -1, -MNU_PREFIX)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_percent, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, true, tam.mode != 0, "", "-01", 0b01101, -1, ITM_PC)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_exclam, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, true, tam.mode != 0, "", "-01", 0b01101, -1, ITM_XFACT)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_U, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, true, false, "", "-01", 0xffff, -1, ITM_USERMODE)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_apostrophe, shortcutProfile == USER_C47, true, false, "f", "05", 0b11101, -1, ITM_AIM)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_G, shortcutProfile == USER_C47, true, false, "g", "05", 0b01101, -1, ITM_GTO)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_A, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, true, tam.mode != 0, "", "-01", 0b01101, -1, ITM_ARG)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_Z, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, true, tam.mode != 0, "", "-01", 0b01101, -1, ITM_MAGNITUDE)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_bar, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, true, tam.mode != 0, "", "-01", 0b01101, -1, ITM_MAGNITUDE)) break :body;
                if (shortCutCommand(w, ekc, 126, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, true, tam.mode != 0, "", "-01", 0b01101, -1, ITM_MAGNITUDE)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_F7, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, true, tam.mode != 0, "", "-01", 0b01101, -1, ITM_SI_n)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_F8, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, true, tam.mode != 0, "", "-01", 0b01101, -1, ITM_SI_u)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_F9, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, true, tam.mode != 0, "", "-01", 0b01101, -1, ITM_SI_m)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_F10, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, true, tam.mode != 0, "", "-01", 0b01101, -1, ITM_SI_k)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_F11, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, true, tam.mode != 0, "", "-01", 0b01101, -1, ITM_SI_M)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_W, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, true, tam.mode != 0, "", "-01", 0b01101, -1, ITM_LASTX)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_equal, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, true, tam.mode != 0, "", "-01", 0b01101, -1, ITM_dotD)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_E, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, true, tam.mode != 0, "", "-01", 0b01101, -1, CST_09)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_N, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, true, false, "f", "35", 0b01101, CM_PEM, ITM_PR)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_b, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, true, tam.mode != 0, "", "-01", 0b01101, CM_PEM, ITM_LBL)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_u, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, true, false, "f", "16", 0b01101, CM_PEM, ITM_PR)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_H, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, false, false, "", "-01", 0b0000011000000001101, -1, -MNU_HOME)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_B, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, false, false, "", "-01", 0b0000011000000001101, -1, -MNU_MyMenu)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_less, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, true, tam.mode != 0, "", "-01", 0b01101, -1, ITM_RTN)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_twosuperior, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, true, tam.mode != 0, "", "-01", 0b01101, -1, ITM_SQUARE)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_colon, shortcutProfile == USER_C47, true, tam.mode != 0, "g", "00", 0b01101, -1, ITM_TGLFRT)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_numbersign, shortcutProfile == USER_C47, false, tam.mode != 0, "g", "01", 0b11101, -1, ITM_HASH_JM)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_quotedbl, shortcutProfile == USER_C47, false, tam.mode != 0, "g", "01", 0b11101, -1, ITM_HASH_JM)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_at, shortcutProfile == USER_C47, false, tam.mode != 0, "g", "03", 0b11101, -1, ITM_dotD)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_eacute, shortcutProfile == USER_C47, false, tam.mode != 0, "g", "03", 0b11101, -1, ITM_dotD)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_asciicircum, shortcutProfile == USER_C47, true, tam.mode != 0, "f", "01", 0b01101, -1, ITM_YX)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_dollar, shortcutProfile == USER_C47, false, tam.mode != 0, "g", "02", 0b11101, -1, ITM_ms)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_ampersand, shortcutProfile == USER_C47, false, tam.mode != 0, "f", "00", 0b11101, -1, ITM_RI)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_backslash, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, false, false, "", "35", 0b0100000000001101, -1, ITM_STOP)) break :body;
                if (shortCutCommand(w, ekc, 96, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, false, false, "", "35", 0b01101, -1, ITM_STOP)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_z, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, false, false, "", "35", 0b01101, -1, ITM_STOP)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_Q, shortcutProfile == USER_R47, true, tam.mode != 0, "", "00", 0b01101, -1, ITM_SQUARE)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_i, shortcutProfile == USER_R47, false, tam.mode != 0, "f", "00", 0b11101, -1, ITM_op_j)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_j, shortcutProfile == USER_R47, false, tam.mode != 0, "f", "00", 0b11101, -1, ITM_op_j)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_q, shortcutProfile == USER_R47, true, tam.mode != 0, "", "01", 0b01101, -1, ITM_SQUAREROOTX)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_k, shortcutProfile == USER_R47, false, tam.mode != 0, "f", "01", 0b11101, -1, ITM_op_j_pol)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_v, shortcutProfile == USER_R47, true, tam.mode != 0, "", "02", 0b01101, -1, ITM_1ONX)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_Y, shortcutProfile == USER_R47, true, tam.mode != 0, "", "03", 0b01101, -1, ITM_YX)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_asciicircum, shortcutProfile == USER_R47, true, tam.mode != 0, "", "03", 0b01101, -1, ITM_YX)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_o, shortcutProfile == USER_R47, true, tam.mode != 0, "", "04", 0b01101, -1, ITM_LOG10)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_l, shortcutProfile == USER_R47, true, tam.mode != 0, "", "05", 0b01101, -1, ITM_LN)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_m, shortcutProfile == USER_R47, true, tam.mode != 0, "", "06", 0b01101, -1, ITM_STO)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_r, shortcutProfile == USER_R47, true, tam.mode != 0, "", "07", 0b01101, -1, ITM_RCL)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_d, shortcutProfile == USER_R47, true, tam.mode != 0, "", "08", 0b01101, -1, ITM_Rdown)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_greater, shortcutProfile == USER_R47, true, tam.mode != 0, "", "09", 0b01101, -1, ITM_DRG)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_f, false, false, tam.mode != 0, "", "10", 0b01101, -1, ITM_SHIFTf)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_g, false, false, tam.mode != 0, "", "11", 0b01101, -1, ITM_SHIFTg)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_E, false, false, false, "", "12", 0b01101, -1, ITM_ENTER)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_w, false, false, tam.mode != 0, "", "13", 0b01101, -1, ITM_XexY)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_n, false, false, tam.mode != 0, "", "14", 0b01101, -1, ITM_CHS)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_e, false, false, tam.mode != 0, "", "15", 0b01101, -1, ITM_EXPONENT)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_a, shortcutProfile == USER_R47, true, tam.mode != 0, "", "-01", 0b01101, -1, ITM_SIGMAPLUS)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_x, shortcutProfile == USER_R47, false, false, "", "17", 0b01101, -1, ITM_XEQ)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_apostrophe, shortcutProfile == USER_R47, true, false, "f", "17", 0b01101, -1, ITM_AIM)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_G, shortcutProfile == USER_R47, true, false, "g", "17", 0b01101, -1, ITM_GTO)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_M, shortcutProfile == USER_R47, false, false, "", "-01", 0b0000011000000001101, -1, -MNU_PREF)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_s, shortcutProfile == USER_R47, true, tam.mode != 0, "", "-01", 0b01101, -1, ITM_sin)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_c, shortcutProfile == USER_R47, true, tam.mode != 0, "", "-01", 0b01101, -1, ITM_cos)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_t, shortcutProfile == USER_R47, true, tam.mode != 0, "", "-01", 0b01101, -1, ITM_tan)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_V, shortcutProfile == USER_R47, true, tam.mode != 0, "", "-01", 0b01101, -1, ITM_1ONX)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_colon, shortcutProfile == USER_R47, true, tam.mode != 0, "g", "34", 0b01101, -1, ITM_TGLFRT)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_numbersign, shortcutProfile == USER_R47, false, tam.mode != 0, "g", "05", 0b11101, -1, ITM_HASH_JM)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_quotedbl, shortcutProfile == USER_R47, false, tam.mode != 0, "g", "05", 0b11101, -1, ITM_HASH_JM)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_at, shortcutProfile == USER_R47, false, tam.mode != 0, "g", "03", 0b11101, -1, ITM_dotD)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_eacute, shortcutProfile == USER_R47, false, tam.mode != 0, "g", "03", 0b11101, -1, ITM_dotD)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_asciicircum, shortcutProfile == USER_R47, true, tam.mode != 0, "", "03", 0b01101, -1, ITM_YX)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_dollar, shortcutProfile == USER_R47, false, tam.mode != 0, "g", "02", 0b11101, -1, ITM_ms)) break :body;
                if (shortCutCommand(w, ekc, GDK_KEY_ampersand, shortcutProfile == USER_R47, false, tam.mode != 0, "g", "04", 0b11101, -1, ITM_RI)) break :body;
            } else if ((CTRL_State != 65536 or allow_altgr) and (calcMode == CM_NORMAL or calcMode == CM_PEM) and !getSystemFlag(FLAG_ALPHA)) {
                const ekv_raw: c_int = @bitCast(event.keyval);
                const ekv: c_int = @bitCast(event_keyval);
                if (tam.mode == TM_STORCL) {
                    if (shortCutCommand(w, ekv_raw, GDK_KEY_Up, shortcutProfile == USER_C47, false, false, "", "17", 0b01001, -1, 0)) return 0 else if (shortCutCommand(w, ekv_raw, GDK_KEY_Down, shortcutProfile == USER_C47, false, false, "", "22", 0b01001, -1, 0)) return 0 else if (shortCutCommand(w, ekv_raw, GDK_KEY_Up, shortcutProfile == USER_R47, false, false, "", "22", 0b01001, -1, 0)) return 0 else if (shortCutCommand(w, ekv_raw, GDK_KEY_Down, shortcutProfile == USER_R47, false, false, "", "27", 0b01001, -1, 0)) return 0 else if (shortCutFNCommand(w, ekv, GDK_KEY_Right, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, false, "", "1", 0b01001, -1, 0)) break :body else if (shortCutCommand(w, ekv_raw, '/', shortcutProfile == USER_C47 or shortcutProfile == USER_R47, false, false, "", "21", 0b01001, -1, 0)) return 0 else if (shortCutCommand(w, ekv_raw, '*', shortcutProfile == USER_C47 or shortcutProfile == USER_R47, false, false, "", "26", 0b01001, -1, 0)) return 0 else if (shortCutCommand(w, ekv_raw, '-', shortcutProfile == USER_C47 or shortcutProfile == USER_R47, false, false, "", "31", 0b01001, -1, 0)) return 0 else if (shortCutCommand(w, ekv_raw, '+', shortcutProfile == USER_C47 or shortcutProfile == USER_R47, false, false, "", "36", 0b01001, -1, 0)) return 0 else if ((event.keyval >= GDK_KEY_A and event.keyval <= GDK_KEY_Z) or (event.keyval >= GDK_KEY_a and event.keyval <= GDK_KEY_z)) {
                        switch (event.keyval) {
                            GDK_KEY_X, GDK_KEY_x => {
                                addItemToBuffer(ITM_REG_X);
                                screenUpdatingMode = SCRUPD_AUTO;
                                refreshScreen(3);
                                return 0;
                            },
                            GDK_KEY_Y, GDK_KEY_y => {
                                addItemToBuffer(ITM_REG_Y);
                                screenUpdatingMode = SCRUPD_AUTO;
                                refreshScreen(3);
                                return 0;
                            },
                            GDK_KEY_Z, GDK_KEY_z => {
                                addItemToBuffer(ITM_REG_Z);
                                screenUpdatingMode = SCRUPD_AUTO;
                                refreshScreen(3);
                                return 0;
                            },
                            GDK_KEY_T, GDK_KEY_t => {
                                addItemToBuffer(ITM_REG_T);
                                screenUpdatingMode = SCRUPD_AUTO;
                                refreshScreen(3);
                                return 0;
                            },
                            GDK_KEY_A, GDK_KEY_a => {
                                addItemToBuffer(ITM_REG_A);
                                screenUpdatingMode = SCRUPD_AUTO;
                                refreshScreen(3);
                                return 0;
                            },
                            GDK_KEY_B, GDK_KEY_b => {
                                addItemToBuffer(ITM_REG_B);
                                screenUpdatingMode = SCRUPD_AUTO;
                                refreshScreen(3);
                                return 0;
                            },
                            GDK_KEY_C, GDK_KEY_c => {
                                addItemToBuffer(ITM_REG_C);
                                screenUpdatingMode = SCRUPD_AUTO;
                                refreshScreen(3);
                                return 0;
                            },
                            GDK_KEY_D, GDK_KEY_d => {
                                addItemToBuffer(ITM_REG_D);
                                screenUpdatingMode = SCRUPD_AUTO;
                                refreshScreen(3);
                                return 0;
                            },
                            GDK_KEY_L, GDK_KEY_l => {
                                addItemToBuffer(ITM_REG_L);
                                screenUpdatingMode = SCRUPD_AUTO;
                                refreshScreen(3);
                                return 0;
                            },
                            GDK_KEY_I, GDK_KEY_i => {
                                addItemToBuffer(ITM_REG_I);
                                screenUpdatingMode = SCRUPD_AUTO;
                                refreshScreen(3);
                                return 0;
                            },
                            GDK_KEY_J, GDK_KEY_j => {
                                addItemToBuffer(ITM_REG_J);
                                screenUpdatingMode = SCRUPD_AUTO;
                                refreshScreen(3);
                                return 0;
                            },
                            GDK_KEY_K, GDK_KEY_k => {
                                addItemToBuffer(ITM_REG_K);
                                screenUpdatingMode = SCRUPD_AUTO;
                                refreshScreen(3);
                                return 0;
                            },
                            GDK_KEY_M, GDK_KEY_m => {
                                addItemToBuffer(ITM_REG_M);
                                screenUpdatingMode = SCRUPD_AUTO;
                                refreshScreen(3);
                                return 0;
                            },
                            GDK_KEY_N, GDK_KEY_n => {
                                addItemToBuffer(ITM_REG_N);
                                screenUpdatingMode = SCRUPD_AUTO;
                                refreshScreen(3);
                                return 0;
                            },
                            GDK_KEY_P, GDK_KEY_p => {
                                addItemToBuffer(ITM_REG_P);
                                screenUpdatingMode = SCRUPD_AUTO;
                                refreshScreen(3);
                                return 0;
                            },
                            GDK_KEY_Q, GDK_KEY_q => {
                                addItemToBuffer(ITM_REG_Q);
                                screenUpdatingMode = SCRUPD_AUTO;
                                refreshScreen(3);
                                return 0;
                            },
                            GDK_KEY_R, GDK_KEY_r => {
                                addItemToBuffer(ITM_REG_R);
                                screenUpdatingMode = SCRUPD_AUTO;
                                refreshScreen(3);
                                return 0;
                            },
                            GDK_KEY_S, GDK_KEY_s => {
                                addItemToBuffer(ITM_REG_S);
                                screenUpdatingMode = SCRUPD_AUTO;
                                refreshScreen(3);
                                return 0;
                            },
                            GDK_KEY_E, GDK_KEY_e => {
                                addItemToBuffer(ITM_REG_E);
                                screenUpdatingMode = SCRUPD_AUTO;
                                refreshScreen(3);
                                return 0;
                            },
                            GDK_KEY_F, GDK_KEY_f => {
                                addItemToBuffer(ITM_REG_F);
                                screenUpdatingMode = SCRUPD_AUTO;
                                refreshScreen(3);
                                return 0;
                            },
                            GDK_KEY_G, GDK_KEY_g => {
                                addItemToBuffer(ITM_REG_G);
                                screenUpdatingMode = SCRUPD_AUTO;
                                refreshScreen(3);
                                return 0;
                            },
                            GDK_KEY_H, GDK_KEY_h => {
                                addItemToBuffer(ITM_REG_H);
                                screenUpdatingMode = SCRUPD_AUTO;
                                refreshScreen(3);
                                return 0;
                            },
                            GDK_KEY_O, GDK_KEY_o => {
                                addItemToBuffer(ITM_REG_O);
                                screenUpdatingMode = SCRUPD_AUTO;
                                refreshScreen(3);
                                return 0;
                            },
                            GDK_KEY_U, GDK_KEY_u => {
                                addItemToBuffer(ITM_REG_U);
                                screenUpdatingMode = SCRUPD_AUTO;
                                refreshScreen(3);
                                return 0;
                            },
                            GDK_KEY_V, GDK_KEY_v => {
                                addItemToBuffer(ITM_REG_V);
                                screenUpdatingMode = SCRUPD_AUTO;
                                refreshScreen(3);
                                return 0;
                            },
                            GDK_KEY_W, GDK_KEY_w => {
                                addItemToBuffer(ITM_REG_W);
                                screenUpdatingMode = SCRUPD_AUTO;
                                refreshScreen(3);
                                return 0;
                            },
                            else => {},
                        }
                    }
                } else if (tamArrowsMacro() and !getSystemFlag(FLAG_ALPHA)) {
                    if (shortCutCommand(w, ekv_raw, GDK_KEY_Up, shortcutProfile == USER_C47, false, false, "", "17", 0b01001, -1, 0)) return 0 else if (shortCutCommand(w, ekv_raw, GDK_KEY_Down, shortcutProfile == USER_C47, false, false, "", "22", 0b01001, -1, 0)) return 0 else if (shortCutCommand(w, ekv_raw, GDK_KEY_Up, shortcutProfile == USER_R47, false, false, "", "22", 0b01001, -1, 0)) return 0 else if (shortCutCommand(w, ekv_raw, GDK_KEY_Down, shortcutProfile == USER_R47, false, false, "", "27", 0b01001, -1, 0)) return 0;
                }
            }

            // New Matrix arrows
            if ((CTRL_State != 65536 or allow_altgr) and catalog == 0 and
                (calcMode == CM_NORMAL or calcMode == CM_MIM or calcMode == CM_EIM) and
                isSimArrowAllowedInMenu(currentMenu(), event_keyval))
            {
                const ekv: c_int = @bitCast(event_keyval);
                if (shortCutFNCommand(w, ekv, GDK_KEY_Up, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, false, "", "1", 3 << 13, -1, 0)) break :body else if (shortCutFNCommand(w, ekv, GDK_KEY_Down, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, false, "", "2", 3 << 13, -1, 0)) break :body else if (shortCutFNCommand(w, ekv, GDK_KEY_Left, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, false, "", "5", 3 << 13, -1, 0)) break :body else if (shortCutFNCommand(w, ekv, GDK_KEY_Right, shortcutProfile == USER_C47 or shortcutProfile == USER_R47, false, "", "6", 3 << 13, -1, 0)) break :body;
            }

            // New ALPHA SECTION
            if ((CTRL_State != 65536 or allow_altgr) and
                ((catalog != 0 and currentMenu() != -MNU_MVAR) or
                    calcMode == CM_AIM or calcMode == CM_EIM or
                    (calcMode == CM_PEM and getSystemFlag(FLAG_ALPHA)) or
                    (calcMode == CM_ASSIGN and getSystemFlag(FLAG_ALPHA)) or
                    (calcMode == CM_NORMAL and (tam.mode == TM_REGISTER or tam.mode == TM_FLAGW or tam.mode == TM_FLAGR)) or
                    shortcut_owned.isLabelText()))
            {
                const alphaCase_MEM = alphaCase;
                var ll: i32 = @bitCast(event.keyval);

                if ('A' <= ll and ll <= 'Z' and alphaCase == AC_UPPER) {
                    ll += ('a' - 'A');
                    alphaCase = AC_LOWER;
                } else if ('A' <= ll and ll <= 'Z' and alphaCase == AC_LOWER) {
                    alphaCase = AC_UPPER;
                } else if ('a' <= ll and ll <= 'z' and alphaCase == AC_UPPER) {
                    ll -= ('a' - 'A');
                } else if ('a' <= ll and ll <= 'z' and alphaCase == AC_LOWER) {}

                const code: i16 = keymap_owned.keyCodeFromGdkKey(@as(u32, @bitCast(ll)));
                if (code > 0) {
                    lastshiftF = shiftF;
                    lastshiftG = shiftG;
                    shortcut_owned.sendKey(code);
                    screenUpdatingMode = SCRUPD_AUTO;
                    refreshStatusBar();
                    refreshScreen(8);
                    _ = refreshLcd(null);
                    resetShiftState();
                    alphaCase = alphaCase_MEM;
                    break :body;
                } else if (code == -1) {
                    screenUpdatingMode = SCRUPD_AUTO;
                    alphaCase = alphaCase_MEM;
                    refreshStatusBar();
                    refreshScreen(8);
                    _ = refreshLcd(null);
                    resetShiftState();
                    break :body;
                }
                alphaCase = alphaCase_MEM;
            }
        }

        // continueWithOldDetections
        switch (event_keyval) {
            GDK_KEY_H + 65536, GDK_KEY_h + 65536 => {
                CTRL_State = 0;
                _ = printf("key pressed: CTRL+h Hardcopy\n");
                copyScreenToClipboard();
            },
            GDK_KEY_M + 65536, GDK_KEY_m + 65536 => {
                CTRL_State = 0;
                _ = printf("key pressed: CTRL+m Menu copy\n");
                copyMenuToClipboard();
            },
            83 + 65536, 115 + 65536 => {
                CTRL_State = 0;
                _ = printf("key pressed: CTRL+s SNAP\n");
                fnSNAP(NOPARAM);
            },
            120 + 65536, 88 + 65536, 99 + 65536, 67 + 65536 => {
                CTRL_State = 0;
                _ = printf("key pressed: CTRL+c/x Copy x register to clipboard\n");
                copyRegisterXToClipboard();
            },
            100 + 65536, 68 + 65536 => {
                CTRL_State = 0;
                _ = printf("key pressed: CTRL+d Copy Stack registers to clipboard\n");
                copyStackRegistersToClipboard();
            },
            97 + 65536, 65 + 65536 => {
                CTRL_State = 0;
                _ = printf("key pressed: CTRL+d Copy All registers to clipboard\n");
                copyAllRegistersToClipboard();
            },
            else => {},
        }

        // JM ALPHA SECTION FOR ALPHAMODE
        if (calcMode == CM_AIM or calcMode == CM_EIM or tam.mode != 0 or
            (calcMode == CM_PEM and getSystemFlag(FLAG_ALPHA)) or tam.alpha)
        {
            _ = printf(">>>>> ALPHA SECTION Keyboard Key Code = %d\n", @as(c_int, @bitCast(event_keyval)));
            switch (event_keyval) {
                GDK_KEY_Up => {
                    if (alphaArrowsMacro()) {
                        btnClicked(w, if (isR47FAM()) "22" else "17");
                    } else if (calcMode == CM_EIM) {
                        btnClicked(w, if (isR47FAM()) "22" else "17");
                    } else {
                        if (tam.mode == 0) {
                            btnFnClicked(w, "1");
                        }
                    }
                },
                GDK_KEY_Down => {
                    if (alphaArrowsMacro()) {
                        btnClicked(w, if (isR47FAM()) "27" else "22");
                    } else if (calcMode == CM_EIM) {
                        btnClicked(w, if (isR47FAM()) "27" else "22");
                    } else {
                        btnFnClicked(w, "2");
                    }
                },
                GDK_KEY_Left => {
                    if (alphaArrowsMacro()) {} else {
                        btnFnClicked(w, "5");
                    }
                },
                GDK_KEY_Right => {
                    if (alphaArrowsMacro()) {} else {
                        btnFnClicked(w, "6");
                    }
                },
                GDK_KEY_F1 => {
                    if (calcMode == CM_EIM or alphaArrowsMacro() or shortcut_owned.isLabelText()) btnFnClickedP(w, "1") else btnFnClicked(w, "1");
                },
                GDK_KEY_F2 => {
                    if (calcMode == CM_EIM or alphaArrowsMacro() or shortcut_owned.isLabelText()) btnFnClickedP(w, "2") else btnFnClicked(w, "2");
                },
                GDK_KEY_F3 => {
                    if (calcMode == CM_EIM or alphaArrowsMacro() or shortcut_owned.isLabelText()) btnFnClickedP(w, "3") else btnFnClicked(w, "3");
                },
                GDK_KEY_F4 => {
                    if (calcMode == CM_EIM or alphaArrowsMacro() or shortcut_owned.isLabelText()) btnFnClickedP(w, "4") else btnFnClicked(w, "4");
                },
                GDK_KEY_F5 => {
                    if (calcMode == CM_EIM or alphaArrowsMacro() or shortcut_owned.isLabelText()) btnFnClickedP(w, "5") else btnFnClicked(w, "5");
                },
                GDK_KEY_F6 => {
                    if (calcMode == CM_EIM or alphaArrowsMacro() or shortcut_owned.isLabelText()) btnFnClickedP(w, "6") else btnFnClicked(w, "6");
                },
                65, 66, 67, 68, 69, 70, 94, 71, 72, 73, 74, 75, 76, 124 => {},
                77, 78, 79, 177, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 95, 58, 59, 44, 63, 32 => {
                    _ = printf("-------------------------------------------\n\n\n######## MISSING OLD TEXT OUTPUT A %i ########\n\n", @as(c_int, @bitCast(event_keyval)));
                },
                GDK_KEY_KP_Enter, GDK_KEY_Return => {
                    btnClicked(w, "12");
                },
                GDK_KEY_BackSpace => {
                    btnClicked(w, "16");
                },
                GDK_KEY_KP_Delete, GDK_KEY_Delete => {
                    fnT_ARROW(ITM_T_RIGHT_ARROW);
                    btnClicked(w, "16");
                },
                GDK_KEY_Home => {
                    btnClicked(w, "17");
                },
                GDK_KEY_End => {
                    btnClicked(w, "22");
                },
                65463, 48 + 7 => nu(w, "18"),
                65464, 48 + 8 => nu(w, "19"),
                65465, 48 + 9 => nu(w, "20"),
                65460, 48 + 4 => nu(w, "23"),
                65461, 48 + 5 => nu(w, "24"),
                65462, 48 + 6 => nu(w, "25"),
                65457, 48 + 1 => nu(w, "28"),
                65458, 48 + 2 => nu(w, "29"),
                65459, 48 + 3 => nu(w, "30"),
                65456, 48 + 0 => nu(w, "33"),
                46, 65454 => nu(w, "34"),
                65455, 47 => nu(w, "21"),
                65450, 42 => nu(w, "26"),
                65453, 45 => nu(w, "31"),
                65451, 43 => nu(w, "36"),
                65307 => btnClicked(w, "32"),
                else => {},
            }
            break :body;
        } else {
            switch (event_keyval) {
                GDK_KEY_question => {
                    if (calcModel == USER_R47fg_bk and (calcMode == CM_NORMAL or calcMode == CM_NIM)) {
                        btnClicked(w, "11");
                    } else if (calcModel == USER_R47bk_fg and (calcMode == CM_NORMAL or calcMode == CM_NIM)) {
                        btnClicked(w, "10");
                    }
                },
                GDK_KEY_Left => btnFnClicked(w, "5"),
                GDK_KEY_Right => btnFnClicked(w, "6"),
                GDK_KEY_F1 => btnFnClickedP(w, "1"),
                GDK_KEY_F2 => btnFnClickedP(w, "2"),
                GDK_KEY_F3 => btnFnClickedP(w, "3"),
                GDK_KEY_F4 => btnFnClickedP(w, "4"),
                GDK_KEY_F5 => btnFnClickedP(w, "5"),
                GDK_KEY_F6 => btnFnClickedP(w, "6"),
                97, 118, 113, 111, 108, 120, 109, 114, 100, 112, 61, 121, 115, 99, 116 => {
                    _ = printf("-------------------------------------------\n\n\n######## MISSING OLD TEXT OUTPUT B %i ########\n\n", @as(c_int, @bitCast(event_keyval)));
                },
                GDK_KEY_KP_Enter, 65293 => btnClicked(w, "12"),
                119 => btnClicked(w, "13"),
                110 => btnClicked(w, "14"),
                101 => btnClicked(w, "15"),
                GDK_KEY_BackSpace => btnClicked(w, "16"),
                GDK_KEY_Up => btnClicked(w, if (isR47FAM()) "22" else "17"),
                55, 65463 => btnClicked(w, "18"),
                56, 65464 => btnClicked(w, "19"),
                57, 65465 => btnClicked(w, "20"),
                47, 65455 => btnClicked(w, "21"),
                GDK_KEY_Down => btnClicked(w, if (isR47FAM()) "27" else "22"),
                52, 65460 => btnClicked(w, "23"),
                53, 65461 => btnClicked(w, "24"),
                54, 65462 => btnClicked(w, "25"),
                42, 65450 => btnClicked(w, "26"),
                49, 65457 => btnClicked(w, "28"),
                50, 65458 => btnClicked(w, "29"),
                51, 65459 => btnClicked(w, "30"),
                45, 65453 => btnClicked(w, "31"),
                65307 => btnClicked(w, "32"),
                48, 65456 => btnClicked(w, "33"),
                44, 46, 65454 => btnClicked(w, "34"),
                43, 65451 => btnClicked(w, "36"),
                GDK_KEY_Control_L, GDK_KEY_Control_R => {
                    CTRL_State = 65536;
                },
                else => {},
            }
        }
    }

    previousEventStateP = event.state;
    previousEventKeyP = event.keyval;
    return 0;
}

const CM_TIMER = 14;
const TM_MENU = 10017;
