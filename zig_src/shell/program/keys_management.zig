const frontier_addons = @import("../extensions/addons.zig");
const frontier_config = @import("../config.zig");
const frontier_softmenus = @import("../display/softmenus/softmenus.zig");
const TO_USER: u16 = 29;
const FROM_USER: u16 = 30;

const USER_C47: u16 = 46;
const USER_ARESET: u16 = 48;
const USER_MRESET: u16 = 49;
const USER_KRESET: u16 = 50;
const USER_HRESET: u16 = 58;
const USER_PRESET: u16 = 59;
const USER_R47f_g: u16 = 61;
const USER_R47bk_fg: u16 = 62;
const USER_R47fg_bk: u16 = 63;
const USER_R47fg_g: u16 = 64;
const USER_DM42: u16 = 45;

const ITM_RIBBON_C47: u16 = 2509;
const ITM_RIBBON_R47: u16 = 2511;

const MNU_HOME: i16 = 1921;
const MNU_PFN: i16 = 1403;
const MNU_MyMenu: i16 = 1349;

const FLAG_USER: u16 = 0x8014;
const FLAG_MYM_TRIPLE: u16 = 0x805f;
const FLAG_HOME_TRIPLE: u16 = 0x8060;

fn applyToUser() void {
    frontier_config.z47_frontier_keys_to_user_case();
}

fn applyFromUser() void {
    frontier_config.z47_frontier_keys_from_user_case();
}

fn applyKReset(choice: u16) void {
    frontier_config.fnShowVersion(choice);
    frontier_config.z47_frontier_keys_user_layout_reset_case();
}

fn applyModelChoice(choice: u16) void {
    calcModel = @as(u8, @intCast(choice));
    fnClearFlag(FLAG_USER);
    applyKReset(USER_KRESET);

    if (choice == USER_R47bk_fg) {
        fnClearFlag(FLAG_HOME_TRIPLE);
        fnSetFlag(FLAG_MYM_TRIPLE);
    } else {
        fnSetFlag(FLAG_HOME_TRIPLE);
        fnClearFlag(FLAG_MYM_TRIPLE);
    }

    frontier_config.fnShowVersion(choice);
}

fn applyHReset(choice: u16) void {
    _ = frontier_softmenus.createHOME();
    frontier_softmenus.showSoftmenu(-MNU_HOME);
    frontier_config.fnShowVersion(choice);
}

fn applyPReset(choice: u16) void {
    _ = frontier_softmenus.createPFN();
    frontier_softmenus.showSoftmenu(-MNU_PFN);
    frontier_config.fnShowVersion(choice);
}

fn applyMReset(choice: u16) void {
    frontier_addons.fnRESET_MyM(0);
    frontier_config.fnShowVersion(choice);
}

fn applyAReset(choice: u16) void {
    frontier_addons.fnRESET_Mya();
    frontier_config.fnShowVersion(choice);
}

fn applyRibbon(choice: u16) void {
    frontier_addons.fnRESET_MyM(choice);
    frontier_config.fnShowVersion(choice);
    frontier_softmenus.showSoftmenu(-MNU_MyMenu);
}

pub fn run(choice: u16) void {
    switch (choice) {
        TO_USER => applyToUser(),
        FROM_USER => applyFromUser(),
        USER_R47f_g, USER_R47bk_fg, USER_R47fg_bk, USER_R47fg_g, USER_C47, USER_DM42 => applyModelChoice(choice),
        USER_KRESET => applyKReset(choice),
        USER_HRESET => applyHReset(choice),
        USER_PRESET => applyPReset(choice),
        USER_MRESET => applyMReset(choice),
        USER_ARESET => applyAReset(choice),
        ITM_RIBBON_C47, ITM_RIBBON_R47 => applyRibbon(choice),
        else => {},
    }
}

extern var calcModel: u8;

extern fn fnClearFlag(flag: u16) void;
extern fn fnSetFlag(flag: u16) void;
