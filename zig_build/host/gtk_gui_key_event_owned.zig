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

const KEY_fg: i16 = 1893;
const ITM_SHIFTf: i16 = 1731;
const ITM_SHIFTg: i16 = 1732;
const FLAG_USER: u16 = 0x8014;
const FLAG_ALPHA: u16 = 0x800e;
const CM_AIM: u8 = 1;
const CM_NIM: u8 = 2;
const CM_PEM: u8 = 3;
const CM_EIM: u8 = 13;
const SCRUPD_AUTO: u8 = 0x00;

const GDK_KEY_Shift_L: u32 = 65505;
const GDK_KEY_Shift_R: u32 = 65506;
const GDK_KEY_Control_L: u32 = 65507;
const GDK_KEY_Control_R: u32 = 65508;
const GDK_KEY_Alt_R: u32 = 65514;
const GDK_KEY_F1: u32 = 65470;
const GDK_KEY_F2: u32 = 65471;
const GDK_KEY_F3: u32 = 65472;
const GDK_KEY_F4: u32 = 65473;
const GDK_KEY_F5: u32 = 65474;
const GDK_KEY_F6: u32 = 65475;
const GDK_KEY_f: u32 = 102;
const GDK_KEY_g: u32 = 103;

pub var CTRL_State: u32 = 0;
pub var SHIFT_State: u32 = 0;
pub var event_keyval: u32 = 99999999;
pub var event_command_shift: u32 = 0;
pub var previousEventStateR: u32 = 0;
pub var previousEventKeyR: u32 = 0;
pub var previousEventStateP: u32 = 0;
pub var previousEventKeyP: u32 = 0;

extern var calcMode: u8;
extern var screenUpdatingMode: u8;
extern var shiftF: bool;
extern var shiftG: bool;
extern var swapCtrlCode: bool;
extern var tam: tamState_t;
extern var kbd_usr: [37]calcKey_t;
extern fn getSystemFlag(flag: u16) bool;
extern fn btnClicked(widget: ?*anyopaque, data: [*:0]const u8) void;
extern fn btnFnClickedR(widget: ?*anyopaque, data: [*:0]const u8) void;
extern fn refreshStatusBar() void;
extern fn showShiftState() void;
extern fn z47_keyPressed_c_impl(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int;

fn stripCapsLockForCommand(keyval: u32) u32 {
    const is_alpha = (keyval >= 'A' and keyval <= 'Z') or (keyval >= 'a' and keyval <= 'z');
    if (!is_alpha) return keyval;

    return (keyval & 0xFFFFDF) + (0x20 & ~(event_command_shift >> (16 - 5)));
}

pub fn keyPressedImpl(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int {
    if (event == null) return z47_keyPressed_c_impl(widget, event, data);

    const key_event: *GdkEventKey = @ptrCast(@alignCast(event.?));
    event_keyval = key_event.keyval + CTRL_State;

    const altgr_pressed = key_event.keyval == GDK_KEY_Alt_R and (key_event.state & 0b10100) != 0;
    const ctrl_pressed = if (swapCtrlCode)
        (key_event.keyval == GDK_KEY_Control_L and (key_event.state & 0b00100) == 0)
    else
        (key_event.keyval == GDK_KEY_Control_L and (key_event.state & 0b00100) != 0);

    if (ctrl_pressed) {
        previousEventStateP = key_event.state;
        previousEventKeyP = key_event.keyval;
        return z47_keyPressed_c_impl(widget, event, data);
    }

    if (altgr_pressed) {
        SHIFT_State = 0;
        event_command_shift = 0;
        CTRL_State = 0;
        shiftF = false;
        shiftG = false;
        refreshStatusBar();
        showShiftState();
        previousEventStateP = key_event.state;
        previousEventKeyP = key_event.keyval;
        return 0;
    }

    SHIFT_State = 0;
    switch (event_keyval) {
        GDK_KEY_Shift_L, GDK_KEY_Shift_R => {
            SHIFT_State = 65536;
            event_command_shift = 65536;
            previousEventStateP = key_event.state;
            previousEventKeyP = key_event.keyval;
            return 0;
        },
        GDK_KEY_Control_L, GDK_KEY_Control_R => {
            CTRL_State = 65536;
            previousEventStateP = key_event.state;
            previousEventKeyP = key_event.keyval;
            return 0;
        },
        else => {},
    }

    if (CTRL_State == 65536 and !ctrl_pressed) {
        previousEventStateP = key_event.state;
        previousEventKeyP = key_event.keyval;
        return z47_keyPressed_c_impl(widget, event, data);
    }

    const in_text_modes = calcMode == CM_AIM or calcMode == CM_EIM or tam.mode != 0 or (calcMode == CM_PEM and getSystemFlag(FLAG_ALPHA)) or tam.alpha;
    if (!in_text_modes) {
        const key_strip = stripCapsLockForCommand(key_event.keyval);
        const standard_keys = profile_owned.currentStdKeyboard();

        switch (key_strip) {
            GDK_KEY_f => {
                if (profile_owned.checkNormal(0, ITM_SHIFTf)) btnClicked(widget, "00") else
                if (profile_owned.checkNormal(10, ITM_SHIFTf)) btnClicked(widget, "10") else
                if (profile_owned.checkNormal(11, ITM_SHIFTf)) btnClicked(widget, "11") else
                if ((if (getSystemFlag(FLAG_USER)) kbd_usr[10].primary else standard_keys[10].primary) == ITM_SHIFTf) btnClicked(widget, "10") else
                if ((if (getSystemFlag(FLAG_USER)) kbd_usr[11].primary else standard_keys[11].primary) == ITM_SHIFTf) btnClicked(widget, "11") else
                if ((if (getSystemFlag(FLAG_USER)) kbd_usr[10].primary else standard_keys[10].primary) == KEY_fg) btnClicked(widget, "10") else
                if ((if (getSystemFlag(FLAG_USER)) kbd_usr[11].primary else standard_keys[11].primary) == KEY_fg) btnClicked(widget, "11") else
                if ((if (getSystemFlag(FLAG_USER)) kbd_usr[27].primary else standard_keys[27].primary) == KEY_fg) btnClicked(widget, "27");

                previousEventStateP = key_event.state;
                previousEventKeyP = key_event.keyval;
                return 0;
            },
            GDK_KEY_g => {
                if (profile_owned.checkNormal(0, ITM_SHIFTg)) btnClicked(widget, "00") else
                if (profile_owned.checkNormal(10, ITM_SHIFTg)) btnClicked(widget, "10") else
                if (profile_owned.checkNormal(11, ITM_SHIFTg)) btnClicked(widget, "11") else
                if ((if (getSystemFlag(FLAG_USER)) kbd_usr[11].primary else standard_keys[11].primary) == ITM_SHIFTg) btnClicked(widget, "11") else
                if ((if (getSystemFlag(FLAG_USER)) kbd_usr[10].primary else standard_keys[10].primary) == ITM_SHIFTg) btnClicked(widget, "10") else {
                    shiftF = false;
                    shiftG = !shiftG;
                    refreshStatusBar();
                    showShiftState();
                }

                previousEventStateP = key_event.state;
                previousEventKeyP = key_event.keyval;
                return 0;
            },
            else => {},
        }
    }

    previousEventStateP = key_event.state;
    previousEventKeyP = key_event.keyval;
    return z47_keyPressed_c_impl(widget, event, data);
}

pub fn keyReleasedImpl(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int {
    _ = data;

    const key_event: *GdkEventKey = @ptrCast(@alignCast(event.?));

    if (event_keyval == key_event.keyval + CTRL_State) {
        event_keyval = 99999999;
    }

    const ctrl_released = (key_event.keyval == GDK_KEY_Control_L and (key_event.state & 0b00000) != 0) and
        (previousEventKeyP == GDK_KEY_Control_L and previousEventStateP == 0b00100);
    if (ctrl_released) {
        previousEventStateR = key_event.state;
        previousEventKeyR = key_event.keyval;
        return 0;
    }

    const altgr_released = (key_event.keyval == GDK_KEY_Alt_R and (key_event.state & 0b00000) != 0) and
        (previousEventKeyR == GDK_KEY_Control_L and previousEventStateR == 0b1000);
    if (altgr_released) {
        SHIFT_State = 0;
        event_command_shift = 0;
        CTRL_State = 0;
        shiftF = false;
        shiftG = false;
        refreshStatusBar();
        showShiftState();
        previousEventStateR = key_event.state;
        previousEventKeyR = key_event.keyval;
        return 0;
    }

    const standard_keys = profile_owned.currentStdKeyboard();

    switch (key_event.keyval) {
        GDK_KEY_Shift_L, GDK_KEY_Shift_R => {
            event_command_shift = 0;
            if (SHIFT_State != 0) {
                if (profile_owned.checkNormal(0, KEY_fg)) btnClicked(widget, "00") else
                if (profile_owned.checkNormal(10, KEY_fg)) btnClicked(widget, "10") else
                if (profile_owned.checkNormal(11, KEY_fg)) btnClicked(widget, "11") else
                if (profile_owned.checkNormal(0, ITM_SHIFTf)) btnClicked(widget, "00") else
                if (profile_owned.checkNormal(10, ITM_SHIFTf)) btnClicked(widget, "10") else
                if (profile_owned.checkNormal(11, ITM_SHIFTf)) btnClicked(widget, "11") else
                if ((if (getSystemFlag(FLAG_USER)) kbd_usr[10].primary else standard_keys[10].primary) == ITM_SHIFTf) btnClicked(widget, "10") else
                if ((if (getSystemFlag(FLAG_USER)) kbd_usr[0].primary else standard_keys[0].primary) == KEY_fg) btnClicked(widget, "00") else
                if ((if (getSystemFlag(FLAG_USER)) kbd_usr[10].primary else standard_keys[10].primary) == KEY_fg) btnClicked(widget, "10") else
                if ((if (getSystemFlag(FLAG_USER)) kbd_usr[11].primary else standard_keys[11].primary) == KEY_fg) btnClicked(widget, "11") else
                if ((if (getSystemFlag(FLAG_USER)) kbd_usr[27].primary else standard_keys[27].primary) == KEY_fg) btnClicked(widget, "27") else {
                    shiftF = !shiftF;
                    shiftG = false;
                    refreshStatusBar();
                    showShiftState();
                }
            }
            SHIFT_State = 0;
        },

        GDK_KEY_Control_L, GDK_KEY_Control_R => {
            if (CTRL_State != 0) {
                if (profile_owned.checkNormal(0, KEY_fg)) btnClicked(widget, "00") else
                if (profile_owned.checkNormal(10, KEY_fg)) btnClicked(widget, "10") else
                if (profile_owned.checkNormal(11, KEY_fg)) btnClicked(widget, "11") else
                if (profile_owned.checkNormal(0, ITM_SHIFTg)) btnClicked(widget, "00") else
                if (profile_owned.checkNormal(10, ITM_SHIFTg)) btnClicked(widget, "10") else
                if (profile_owned.checkNormal(11, ITM_SHIFTg)) btnClicked(widget, "11") else
                if ((if (getSystemFlag(FLAG_USER)) kbd_usr[11].primary else standard_keys[11].primary) == ITM_SHIFTg) btnClicked(widget, "11") else {
                    shiftF = false;
                    shiftG = !shiftG;
                    refreshStatusBar();
                    showShiftState();
                }
            }
            CTRL_State = 0;
        },

        GDK_KEY_F1 => if (profile_owned.isLabelText() or tam.mode == 0 or profile_owned.alphaArrowsOffAndUpDn()) btnFnClickedR(widget, "1"),
        GDK_KEY_F2 => if (profile_owned.isLabelText() or tam.mode == 0 or profile_owned.alphaArrowsOffAndUpDn()) btnFnClickedR(widget, "2"),
        GDK_KEY_F3 => if (profile_owned.isLabelText() or tam.mode == 0 or profile_owned.alphaArrowsOffAndUpDn()) btnFnClickedR(widget, "3"),
        GDK_KEY_F4 => if (profile_owned.isLabelText() or tam.mode == 0 or profile_owned.alphaArrowsOffAndUpDn()) btnFnClickedR(widget, "4"),
        GDK_KEY_F5 => if (profile_owned.isLabelText() or tam.mode == 0 or profile_owned.alphaArrowsOffAndUpDn()) btnFnClickedR(widget, "5"),
        GDK_KEY_F6 => if (profile_owned.isLabelText() or tam.mode == 0 or profile_owned.alphaArrowsOffAndUpDn()) btnFnClickedR(widget, "6"),
        else => {},
    }

    if (key_event.keyval != GDK_KEY_Shift_L and key_event.keyval != GDK_KEY_Shift_R) {
        SHIFT_State = 0;
    }

    previousEventStateR = key_event.state;
    previousEventKeyR = key_event.keyval;
    return 0;
}
