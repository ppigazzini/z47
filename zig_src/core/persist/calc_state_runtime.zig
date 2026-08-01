const std = @import("std");
const io_owned = @import("calc_state_io.zig");
const line_parse = @import("line_parse.zig"); // std-only line match / integer parse

pub const FILE_OK: c_int = 1;
pub const FILE_CANCEL: c_int = 2;

pub const VERSION_ALLOWED: u32 = 10000005;
pub const CONFIG_FILE_VERSION: u32 = 10000026; // C saveRestoreCalcState.c:7 configFileVersion (FLAG_SBadm bump)

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
pub extern fn z47_calc_state_restore_one_section(load_mode: u16, s: u16, n: u16, d: u16, allow_user_keys: bool) bool;
pub extern fn ioFileRead(buffer: ?*anyopaque, size: u32) u32;
pub extern fn ioEof() c_int;

// The line helpers are a std-only pure core; see line_parse.zig for why they
// take the caller's buffer rather than a pointer into it, and for the saturation
// the version parse depends on. Lifted there so they are natively testable --
// this owner reaches libc and the file-I/O globals, so it is only reachable
// through the C oracle.

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
    return VERSION_ALLOWED;
}

pub inline fn configFileVersion() u32 {
    return CONFIG_FILE_VERSION;
}

pub inline fn restoreOneSection(load_mode: u16, s: u16, n: u16, d: u16, allow_user_keys: bool) bool {
    return z47_calc_state_restore_one_section(load_mode, s, n, d, allow_user_keys);
}

pub inline fn checkPower() bool {
    return io_owned.checkPower();
}

pub inline fn openSave(save_type: u16) c_int {
    return io_owned.openSave(save_type);
}

pub inline fn openLoad(load_type: u16) c_int {
    return io_owned.openLoad(load_type);
}

pub inline fn closeFile() void {
    io_owned.closeFile();
}

pub inline fn displayWriteError() void {
    io_owned.displayWriteError();
}

pub inline fn displayReadError() void {
    io_owned.displayReadError();
}

pub inline fn unwindAllSubroutines() void {
    io_owned.unwindAllSubroutines();
}

pub inline fn readLine(buffer: []u8) void {
    io_owned.readLineInto(buffer.ptr, buffer.len);
}

pub inline fn lineEquals(line: []const u8, expected: []const u8) bool {
    return line_parse.equals(line, expected);
}

pub inline fn parseU32Line(line: []const u8) u32 {
    return line_parse.parseU32(line);
}

pub inline fn allowUserKeys(saved_calc_model: u16) bool {
    return io_owned.allowUserKeys(saved_calc_model);
}

pub inline fn fixupR47ShiftKeys() void {
    io_owned.fixupR47ShiftKeys();
}

pub inline fn restartPostLoadTimers() void {
    io_owned.restartPostLoadTimers();
}

pub inline fn stampLastStateFileOpened() void {
    io_owned.stampLastStateFileOpened();
}

pub inline fn showSavingStatus() void {
    io_owned.showSavingStatus();
}

pub inline fn showLoadingStatus() void {
    io_owned.showLoadingStatus();
}

pub inline fn writeSaveSections() void {
    io_owned.writeSaveSections();
}

pub inline fn finishLoadUi(refresh_code: u16) void {
    io_owned.finishLoadUi(refresh_code);
}

pub inline fn saveCalcBackup() void {
    io_owned.saveCalc();
}

pub inline fn restoreCalcBackup() void {
    io_owned.restoreCalc();
}

extern var shortIntegerWordSize: u8;
extern var shortIntegerMask: u64;
extern var shortIntegerSignBit: u64;

// Port of config.c updateShortIntegerMasks: rederive the word-size-dependent
// short-integer masks from shortIntegerWordSize. The state file stores neither
// the mask nor the sign bit, so doLoad must recompute both after restoring the
// word size -- otherwise the mask keeps its pre-load value (-1 when a narrow
// state is loaded into the 64-bit default) and later short-integer operations
// mask against the wrong width.
pub fn updateShortIntegerMasks() void {
    // Match config.c exactly, including its reliance on the x86 shift-count mask
    // (only the low 6 bits count): a degenerate word size of 0 yields mask 0 and
    // sign bit 1<<63, as it does in C, rather than a Zig shift/underflow panic.
    // For the live 1..64 range this is the ordinary (1<<ws)-1 / 1<<(ws-1).
    const ws = shortIntegerWordSize;
    shortIntegerMask = if (ws == 64)
        ~@as(u64, 0)
    else
        (@as(u64, 1) << @truncate(ws)) - 1;
    shortIntegerSignBit = @as(u64, 1) << @truncate(ws -% 1);
}
