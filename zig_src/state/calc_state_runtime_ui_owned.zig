pub extern fn z47_calc_state_runtime_allow_user_keys(saved_calc_model: u16) bool;
pub extern fn z47_calc_state_runtime_fixup_r47_shift_keys() void;
pub extern fn z47_calc_state_runtime_restart_post_load_timers() void;
pub extern fn z47_calc_state_runtime_stamp_last_state_file_opened() void;
pub extern fn z47_calc_state_runtime_show_saving_status() void;
pub extern fn z47_calc_state_runtime_show_loading_status() void;
pub extern fn z47_calc_state_runtime_write_save_sections() void;
pub extern fn z47_calc_state_runtime_finish_load_ui(refresh_code: u16) void;
pub extern fn z47_calc_state_retained_saveCalc() void;
pub extern fn z47_calc_state_retained_restoreCalc() void;

pub inline fn allowUserKeys(saved_calc_model: u16) bool {
    return z47_calc_state_runtime_allow_user_keys(saved_calc_model);
}

pub inline fn fixupR47ShiftKeys() void {
    z47_calc_state_runtime_fixup_r47_shift_keys();
}

pub inline fn restartPostLoadTimers() void {
    z47_calc_state_runtime_restart_post_load_timers();
}

pub inline fn stampLastStateFileOpened() void {
    z47_calc_state_runtime_stamp_last_state_file_opened();
}

pub inline fn showSavingStatus() void {
    z47_calc_state_runtime_show_saving_status();
}

pub inline fn showLoadingStatus() void {
    z47_calc_state_runtime_show_loading_status();
}

pub inline fn writeSaveSections() void {
    z47_calc_state_runtime_write_save_sections();
}

pub inline fn finishLoadUi(refresh_code: u16) void {
    z47_calc_state_runtime_finish_load_ui(refresh_code);
}

pub inline fn saveCalcBackup() void {
    z47_calc_state_retained_saveCalc();
}

pub inline fn restoreCalcBackup() void {
    z47_calc_state_retained_restoreCalc();
}
