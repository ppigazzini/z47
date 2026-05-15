pub const FILE_OK: c_int = 1;
pub const FILE_CANCEL: c_int = 2;

pub const autoLoad: u16 = 0;
pub const manualLoad: u16 = 1;
pub const stateLoad: u16 = 2;
pub const autoSave: u16 = 3;
pub const manualSave: u16 = 4;
pub const stateSave: u16 = 5;

pub const SM_MANUAL_SAVE: u16 = 0;
pub const SM_STATE_SAVE: u16 = 1;

pub const LM_ALL: u16 = 0;
pub const LM_PROGRAMS: u16 = 1;
pub const LM_REGISTERS: u16 = 2;
pub const LM_NAMED_VARIABLES: u16 = 3;
pub const LM_SUMS: u16 = 4;
pub const LM_SYSTEM_STATE: u16 = 5;
pub const LM_STATE_LOAD: u16 = 7;

pub const USER_C47: u16 = 46;
pub const USER_R47: u16 = 66;

pub const ERROR_NONE: u8 = 0;

pub const TI_SAVED: u8 = 32;
pub const TI_BACKUP_RESTORED: u8 = 33;
pub const TI_STATEFILE_RESTORED: u8 = 71;
pub const TI_PROGRAMS_RESTORED: u8 = 87;
pub const TI_REGISTERS_RESTORED: u8 = 88;
pub const TI_SETTINGS_RESTORED: u8 = 89;
pub const TI_SUMS_RESTORED: u8 = 90;
pub const TI_VARIABLES_RESTORED: u8 = 91;

pub extern var lastErrorCode: u8;
pub extern var previousErrorCode: u8;
pub extern var temporaryInformation: u8;
pub extern var cachedDynamicMenu: i16;

pub extern fn z47_calc_state_reset_load_context() void;
pub extern fn z47_calc_state_set_saved_calc_model(saved_calc_model: u16) void;
pub extern fn z47_calc_state_get_saved_calc_model() u16;
pub extern fn z47_calc_state_set_loaded_version(version: u32) void;
pub extern fn z47_calc_state_get_loaded_version() u32;
pub extern fn z47_calc_state_get_version_allowed() u32;
pub extern fn z47_calc_state_get_config_file_version() u32;
pub extern fn z47_calc_state_restore_one_section(load_mode: u16, s: u16, n: u16, d: u16, allow_user_keys: bool) bool;

pub extern fn z47_calc_state_runtime_check_power() bool;
pub extern fn z47_calc_state_runtime_open_save(save_type: u16) c_int;
pub extern fn z47_calc_state_runtime_open_load(load_type: u16) c_int;
pub extern fn z47_calc_state_runtime_close_file() void;
pub extern fn z47_calc_state_runtime_display_write_error() void;
pub extern fn z47_calc_state_runtime_display_read_error() void;
pub extern fn z47_calc_state_runtime_unwind_all_subroutines() void;
pub extern fn z47_calc_state_runtime_read_line(buffer: [*c]u8) void;
pub extern fn z47_calc_state_runtime_line_equals(line: [*c]const u8, expected: [*c]const u8) bool;
pub extern fn z47_calc_state_runtime_parse_u32_line(line: [*c]const u8) u32;
pub extern fn z47_calc_state_runtime_allow_user_keys(saved_calc_model: u16) bool;
pub extern fn z47_calc_state_runtime_fixup_r47_shift_keys() void;
pub extern fn z47_calc_state_runtime_restart_post_load_timers() void;
pub extern fn z47_calc_state_runtime_stamp_last_state_file_opened() void;
pub extern fn z47_calc_state_runtime_show_saving_status() void;
pub extern fn z47_calc_state_runtime_show_loading_status() void;
pub extern fn z47_calc_state_runtime_write_save_sections() void;
pub extern fn z47_calc_state_runtime_finish_load_ui(refresh_code: u16) void;
pub extern fn z47_calc_state_runtime_save_calc() void;
pub extern fn z47_calc_state_runtime_restore_calc() void;

pub inline fn resetLoadContext() void {
    z47_calc_state_reset_load_context();
}

pub inline fn setSavedCalcModel(saved_calc_model: u16) void {
    z47_calc_state_set_saved_calc_model(saved_calc_model);
}

pub inline fn getSavedCalcModel() u16 {
    return z47_calc_state_get_saved_calc_model();
}

pub inline fn setLoadedVersion(version: u32) void {
    z47_calc_state_set_loaded_version(version);
}

pub inline fn getLoadedVersion() u32 {
    return z47_calc_state_get_loaded_version();
}

pub inline fn versionAllowed() u32 {
    return z47_calc_state_get_version_allowed();
}

pub inline fn configFileVersion() u32 {
    return z47_calc_state_get_config_file_version();
}

pub inline fn restoreOneSection(load_mode: u16, s: u16, n: u16, d: u16, allow_user_keys: bool) bool {
    return z47_calc_state_restore_one_section(load_mode, s, n, d, allow_user_keys);
}

pub inline fn checkPower() bool {
    return z47_calc_state_runtime_check_power();
}

pub inline fn openSave(save_type: u16) c_int {
    return z47_calc_state_runtime_open_save(save_type);
}

pub inline fn openLoad(load_type: u16) c_int {
    return z47_calc_state_runtime_open_load(load_type);
}

pub inline fn closeFile() void {
    z47_calc_state_runtime_close_file();
}

pub inline fn displayWriteError() void {
    z47_calc_state_runtime_display_write_error();
}

pub inline fn displayReadError() void {
    z47_calc_state_runtime_display_read_error();
}

pub inline fn unwindAllSubroutines() void {
    z47_calc_state_runtime_unwind_all_subroutines();
}

pub inline fn readLine(buffer: []u8) void {
    z47_calc_state_runtime_read_line(buffer.ptr);
}

pub inline fn lineEquals(line: [*c]const u8, expected: [*c]const u8) bool {
    return z47_calc_state_runtime_line_equals(line, expected);
}

pub inline fn parseU32Line(line: [*c]const u8) u32 {
    return z47_calc_state_runtime_parse_u32_line(line);
}

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
    z47_calc_state_runtime_save_calc();
}

pub inline fn restoreCalcBackup() void {
    z47_calc_state_runtime_restore_calc();
}
