const STATE_FILE_NAME_VAR_LENGTH: usize = 20;

const USER_DM42: u8 = 45;
const USER_C47: u8 = 46;
const USER_R47f_g: u8 = 61;
const USER_R47bk_fg: u8 = 62;
const USER_R47fg_bk: u8 = 63;
const USER_R47fg_g: u8 = 64;
const USER_R47: u8 = 66;

const SAVE_FILE_C47 = "C47.sav";
const SAVE_FILE_R47 = "R47.sav";
const AUTO_SAVE_FILE_C47 = "C47auto.sav";
const AUTO_SAVE_FILE_R47 = "R47auto.sav";

extern fn strlen(s: [*c]const u8) usize;
extern var calcModel: u8;

pub fn selectedFileNameSource(filename: [*c]u8) [*c]u8 {
    const length = strlen(filename);
    const min_start = if (length + 1 > STATE_FILE_NAME_VAR_LENGTH)
        length - STATE_FILE_NAME_VAR_LENGTH + 1
    else
        0;

    var start = length;
    while (start > min_start) : (start -= 1) {
        const ch = filename[start - 1];
        if (ch == '/' or ch == '\\' or ch == 0) break;
    }

    return filename + start;
}

pub fn isR47Family(model: u8) bool {
    return switch (model) {
        USER_R47, USER_R47f_g, USER_R47bk_fg, USER_R47fg_bk, USER_R47fg_g => true,
        else => false,
    };
}

pub fn saveFileName() [*c]const u8 {
    return if (isR47Family(calcModel)) SAVE_FILE_R47 else SAVE_FILE_C47;
}

pub fn autoSaveFileName() [*c]const u8 {
    return if (isR47Family(calcModel)) AUTO_SAVE_FILE_R47 else AUTO_SAVE_FILE_C47;
}

pub fn backupFileName() [*c]const u8 {
    return switch (calcModel) {
        USER_C47, USER_DM42 => "backup.cfg",
        else => "backupR47.cfg",
    };
}
