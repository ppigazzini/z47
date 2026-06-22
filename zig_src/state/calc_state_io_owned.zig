const builtin = @import("builtin");
const backup_owned = @import("calc_state_backup_owned.zig");
const build_options = @import("calc_state_build_options");

const use_fake_calc_state_harness_surface =
    @hasDecl(build_options, "use_fake_calc_state_harness_surface") and
    build_options.use_fake_calc_state_harness_surface;

const calc_model_user_id: u16 = if (@hasDecl(build_options, "calc_model_user_id"))
    build_options.calc_model_user_id
else
    46; // USER_C47

const is_dmcp_build = builtin.target.os.tag == .freestanding;

const REGISTER_X: i16 = 100;
const REGISTER_Z: i16 = 102;
const ERR_REGISTER_LINE: i16 = REGISTER_Z;

const ioPathManualSave: c_int = 0;
const ioPathAutoSave: c_int = 1;
const ioPathSaveStateFile: c_int = 6;
const ioPathLoadStateFile: c_int = 7;
const ioModeRead: c_int = 0;
const ioModeWrite: c_int = 1;

const autoLoad: u16 = 0;
const manualLoad: u16 = 1;
const autoSave: u16 = 3;
const manualSave: u16 = 4;

const ERROR_CANNOT_READ_FILE: u8 = 35;
const ERROR_CANNOT_WRITE_FILE: u8 = 55;

const FLAG_USER: u16 = 32788;
const SCRUPD_MANUAL_MENU: u8 = 4;
const SAVING_STATE_FILE: usize = 101;
const LOADING_STATE_FILE: usize = 100;
const force: u8 = 1;

const USER_R47bk_fg: u8 = 62;
const USER_R47f_g: u8 = 61;
const USER_R47fg_bk: u8 = 63;
const USER_R47fg_g: u8 = 64;

const TIMER_IDX_REFRESH_SLEEP: c_int = 0;
const TO_KB_ACTV: u16 = 10;
const TO_KB_ACTV_MEDIUM: u32 = 6000;

const ERROR_MESSAGE_COUNT: usize = 127;
const ERROR_MESSAGE_SIZE: usize = 48;

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

const subroutineLevelHeader_t = extern struct {
    returnProgramNumber: i16,
    returnLocalStep: u16,
    numberOfLocalFlags: u8,
    numberOfLocalRegisters: u8,
    subroutineLevel: u16,
    ptrToNextLevel: u16,
    ptrToPreviousLevel: u16,
};

comptime {
    @import("std").debug.assert(@sizeOf(calcKey_t) == 18);
    @import("std").debug.assert(@offsetOf(subroutineLevelHeader_t, "subroutineLevel") == 6);
}

extern var currentSubroutineLevelData: ?*subroutineLevelHeader_t;
extern var lastStateFileOpened: [32]u8;
extern var fileNameSelected: [20]u8;
extern const errorMessages: [ERROR_MESSAGE_COUNT][ERROR_MESSAGE_SIZE]u8;
extern var screenUpdatingMode: u8;
extern var calcModel: u8;
extern var kbd_usr: [37]calcKey_t;
extern const kbd_std_R47f_g: [37]calcKey_t;
extern const kbd_std_R47bk_fg: [37]calcKey_t;
extern const kbd_std_R47fg_bk: [37]calcKey_t;
extern const kbd_std_R47fg_g: [37]calcKey_t;

extern fn ioFileOpen(path: c_int, mode: c_int) c_int;
extern fn ioFileClose() void;
extern fn displayCalcErrorMessage(error_code: u8, err_message_register_line: i16, err_register_line: i16) void;
extern fn fnReturn(skip: u16) void;
extern fn getDateString(date_string: [*c]u8) void;
extern fn printStatus(row: u8, line1: [*c]const u8, forced: u8) void;
extern fn fnClearFlag(flag: u16) void;
extern fn refreshScreen(source: u16) void;
extern fn readLine(line: [*c]u8) void;
extern fn z47_calc_state_legacy_saveCalc() void;
extern fn z47_calc_state_legacy_restoreCalc() void;
extern fn z47_calc_state_save_sections() void;

// power_check_screen is a DMCP function-table macro, not a link symbol; route
// through the C wrapper. The remaining DMCP symbols are referenced only under
// is_dmcp_build (firmware).
extern fn z47_state_power_check_screen() bool;
extern fn sys_timer_disable(timer: c_int) void;
extern fn sys_timer_start(timer: c_int, time_ms: u32) void;
extern fn fnTimerStart(nr: u8, param: u16, time: u32) void;

extern fn z47_calc_state_runtime_check_power() bool;
extern fn z47_calc_state_runtime_open_save(save_type: u16) c_int;
extern fn z47_calc_state_runtime_open_load(load_type: u16) c_int;
extern fn z47_calc_state_runtime_close_file() void;
extern fn z47_calc_state_runtime_display_write_error() void;
extern fn z47_calc_state_runtime_display_read_error() void;
extern fn z47_calc_state_runtime_unwind_all_subroutines() void;
extern fn z47_calc_state_runtime_read_line(buffer: [*c]u8) void;
extern fn z47_calc_state_runtime_allow_user_keys(saved_calc_model: u16) bool;
extern fn z47_calc_state_runtime_fixup_r47_shift_keys() void;
extern fn z47_calc_state_runtime_restart_post_load_timers() void;
extern fn z47_calc_state_runtime_stamp_last_state_file_opened() void;
extern fn z47_calc_state_runtime_show_saving_status() void;
extern fn z47_calc_state_runtime_show_loading_status() void;
extern fn z47_calc_state_runtime_write_save_sections() void;
extern fn z47_calc_state_runtime_finish_load_ui(refresh_code: u16) void;
extern fn z47_calc_state_runtime_save_calc() void;
extern fn z47_calc_state_runtime_restore_calc() void;

fn cStringLength(text: [*c]const u8) usize {
    var len: usize = 0;
    while (text[len] != 0) : (len += 1) {}
    return len;
}

pub fn saveCalc() void {
    if (use_fake_calc_state_harness_surface) {
        z47_calc_state_runtime_save_calc();
        return;
    }
    backup_owned.saveCalc();
}

pub fn restoreCalc() void {
    if (use_fake_calc_state_harness_surface) {
        z47_calc_state_runtime_restore_calc();
        return;
    }
    backup_owned.restoreCalc();
}

pub fn checkPower() bool {
    if (use_fake_calc_state_harness_surface) {
        return z47_calc_state_runtime_check_power();
    }
    return z47_state_power_check_screen();
}

pub fn openSave(save_type: u16) c_int {
    if (use_fake_calc_state_harness_surface) {
        return z47_calc_state_runtime_open_save(save_type);
    }
    const path: c_int = if (save_type == autoSave)
        ioPathAutoSave
    else if (save_type == manualSave)
        ioPathManualSave
    else
        ioPathSaveStateFile;
    return ioFileOpen(path, ioModeWrite);
}

pub fn openLoad(load_type: u16) c_int {
    if (use_fake_calc_state_harness_surface) {
        return z47_calc_state_runtime_open_load(load_type);
    }
    const path: c_int = if (load_type == autoLoad)
        ioPathAutoSave
    else if (load_type == manualLoad)
        ioPathManualSave
    else
        ioPathLoadStateFile;
    return ioFileOpen(path, ioModeRead);
}

pub fn closeFile() void {
    if (use_fake_calc_state_harness_surface) {
        z47_calc_state_runtime_close_file();
        return;
    }
    ioFileClose();
}

pub fn displayWriteError() void {
    if (use_fake_calc_state_harness_surface) {
        z47_calc_state_runtime_display_write_error();
        return;
    }
    displayCalcErrorMessage(ERROR_CANNOT_WRITE_FILE, ERR_REGISTER_LINE, REGISTER_X);
}

pub fn displayReadError() void {
    if (use_fake_calc_state_harness_surface) {
        z47_calc_state_runtime_display_read_error();
        return;
    }
    displayCalcErrorMessage(ERROR_CANNOT_READ_FILE, ERR_REGISTER_LINE, REGISTER_X);
}

pub fn unwindAllSubroutines() void {
    if (use_fake_calc_state_harness_surface) {
        z47_calc_state_runtime_unwind_all_subroutines();
        return;
    }
    while (true) {
        const level = currentSubroutineLevelData orelse break;
        if (level.subroutineLevel == 0) break;
        fnReturn(0);
    }
}

pub fn readLineInto(buffer: [*c]u8) void {
    if (use_fake_calc_state_harness_surface) {
        z47_calc_state_runtime_read_line(buffer);
        return;
    }
    readLine(buffer);
}

pub fn allowUserKeys(saved_calc_model: u16) bool {
    if (use_fake_calc_state_harness_surface) {
        return z47_calc_state_runtime_allow_user_keys(saved_calc_model);
    }
    return saved_calc_model == calc_model_user_id;
}

pub fn fixupR47ShiftKeys() void {
    if (use_fake_calc_state_harness_surface) {
        z47_calc_state_runtime_fixup_r47_shift_keys();
        return;
    }
    const std_kbd: *const [37]calcKey_t = switch (calcModel) {
        USER_R47f_g => &kbd_std_R47f_g,
        USER_R47bk_fg => &kbd_std_R47bk_fg,
        USER_R47fg_bk => &kbd_std_R47fg_bk,
        USER_R47fg_g => &kbd_std_R47fg_g,
        else => return,
    };
    var i: usize = 10;
    while (i <= 11) : (i += 1) {
        kbd_usr[i].primary = std_kbd[i].primary;
        kbd_usr[i].keyLblAim = std_kbd[i].keyLblAim;
        kbd_usr[i].primaryAim = std_kbd[i].primaryAim;
        kbd_usr[i].primaryTam = std_kbd[i].primaryTam;
    }
}

pub fn restartPostLoadTimers() void {
    if (use_fake_calc_state_harness_surface) {
        z47_calc_state_runtime_restart_post_load_timers();
        return;
    }
    if (is_dmcp_build) {
        sys_timer_disable(TIMER_IDX_REFRESH_SLEEP);
        sys_timer_start(TIMER_IDX_REFRESH_SLEEP, 1000);
        fnTimerStart(@intCast(TO_KB_ACTV), TO_KB_ACTV, TO_KB_ACTV_MEDIUM);
    }
}

pub fn stampLastStateFileOpened() void {
    if (use_fake_calc_state_harness_surface) {
        z47_calc_state_runtime_stamp_last_state_file_opened();
        return;
    }
    getDateString(&lastStateFileOpened[0]);
    var len = cStringLength(&lastStateFileOpened[0]);
    if (len + 2 < lastStateFileOpened.len) {
        // Upstream appends ": " then stringCopy (stpcpy) of the file name. Copy
        // the null-terminated name with the same bound as the fixed buffer.
        lastStateFileOpened[len] = ':';
        lastStateFileOpened[len + 1] = ' ';
        len += 2;
        var src: usize = 0;
        while (len < lastStateFileOpened.len - 1 and fileNameSelected[src] != 0) : ({
            len += 1;
            src += 1;
        }) {
            lastStateFileOpened[len] = fileNameSelected[src];
        }
        lastStateFileOpened[len] = 0;
    }
}

pub fn showSavingStatus() void {
    if (use_fake_calc_state_harness_surface) {
        z47_calc_state_runtime_show_saving_status();
        return;
    }
    printStatus(0, &errorMessages[SAVING_STATE_FILE][0], force);
}

pub fn showLoadingStatus() void {
    if (use_fake_calc_state_harness_surface) {
        z47_calc_state_runtime_show_loading_status();
        return;
    }
    printStatus(0, &errorMessages[LOADING_STATE_FILE][0], force);
}

pub fn writeSaveSections() void {
    if (use_fake_calc_state_harness_surface) {
        z47_calc_state_runtime_write_save_sections();
        return;
    }
    z47_calc_state_save_sections();
}

pub fn finishLoadUi(refresh_code: u16) void {
    if (use_fake_calc_state_harness_surface) {
        z47_calc_state_runtime_finish_load_ui(refresh_code);
        return;
    }
    fnClearFlag(FLAG_USER);
    screenUpdatingMode &= ~SCRUPD_MANUAL_MENU;
    refreshScreen(refresh_code);
}
