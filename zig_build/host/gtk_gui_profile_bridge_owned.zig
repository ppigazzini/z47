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

pub fn normKey00ItemInLayout() i16 {
    return profile_owned.normKey00ItemInLayout();
}

pub fn shortcutProfileValue() u8 {
    return profile_owned.shortcutProfileValue();
}

pub fn currentStdKeyboard() *const [37]calcKey_t {
    return @ptrCast(profile_owned.currentStdKeyboard());
}

pub fn isLabelText() bool {
    return profile_owned.isLabelText();
}

pub fn alphaArrowsOffAndUpDn() bool {
    return profile_owned.alphaArrowsOffAndUpDn();
}

pub fn checkNormal(key_nr: i16, item: i16) bool {
    return profile_owned.checkNormal(key_nr, item);
}
