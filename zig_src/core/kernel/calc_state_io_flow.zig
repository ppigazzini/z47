const abi = @import("abi");
const std = @import("std");
const header_owned = @import("calc_state_header.zig");
const policy_owned = @import("calc_state_policy.zig");
const runtime = @import("calc_state_runtime.zig");
const codec = @import("calc_state_register_codec.zig");

// --- Data-file (register import) primitives ---
extern fn ioFileOpen(path: c_int, mode: c_int) c_int;
extern fn ioFileClose() void;
extern fn liftStack() void;
extern fn show_warning(string: [*c]u8) void;
const refreshScreen = abi.host.requestRefresh; // routed through the host-callback boundary
extern fn showHideHourGlass() void;
extern fn displayCalcErrorMessage(error_code: u8, errMessageRegisterLine: i16, errRegisterLine: i16) void;
extern fn sprintf(str: [*c]u8, format: [*c]const u8, ...) c_int;
extern var screenUpdatingMode: u8;
extern var temporaryInformation: u8;
extern var hourGlassIconEnabled: bool;

const ioPathRegImport: c_int = 14;
const ioModeRead: c_int = 0;
const SCRUPD_AUTO: u8 = 0x00;
const TI_DATA_LOADED: u16 = 142;
const ERROR_CANNOT_READ_FILE: u8 = 35;
const ERR_REGISTER_LINE: i16 = 102; // REGISTER_Z
const REGISTER_X_LINE: i16 = 100;

pub fn doSave(save_type: u16) void {
    runtime.showSavingStatus();

    if (runtime.checkPower()) {
        return;
    }

    const ret = runtime.openSave(save_type);
    if (ret != runtime.FILE_OK) {
        if (ret == runtime.FILE_CANCEL) {
            return;
        }

        runtime.displayWriteError();
        return;
    }
    defer runtime.closeFile();

    runtime.writeSaveSections();
    runtime.temporaryInformation = runtime.TI_SAVED;
}

pub fn doLoad(load_mode: u16, s: u16, n: u16, d: u16, load_type: u16) void {
    runtime.resetLoadContext();

    const ret = runtime.openLoad(load_type);
    if (ret != runtime.FILE_OK) {
        if (ret == runtime.FILE_CANCEL) {
            return;
        }

        runtime.displayReadError();
        return;
    }

    if (load_mode == runtime.LM_ALL) {
        runtime.unwindAllSubroutines();
    }

    const header = header_owned.parseSaveFileRevision();
    if (policy_owned.canEnableLoad(load_mode, load_type, header.loaded_version)) {
        const allow_user_keys = runtime.allowUserKeys(header.saved_calc_model);
        while (runtime.restoreOneSection(load_mode, s, n, d, allow_user_keys)) {}
        runtime.fixupR47ShiftKeys();
    }

    runtime.lastErrorCode = runtime.ERROR_NONE;
    runtime.previousErrorCode = runtime.lastErrorCode;

    runtime.closeFile();
    runtime.restartPostLoadTimers();
    policy_owned.setPostLoadTemporaryInformation(load_mode, load_type, header.loaded_version);
    runtime.cachedDynamicMenu = 0;
}

// Load a register data file (DATA_FILE format) written by doSaveDataFile.
// Faithful port of saveRestoreCalcState.c doLoadDataFile: validate the two
// header lines, then replay each section via restoreOneSection until EOF.
// restoreOneSection only returns false after SYSTEM_STATE (absent from data
// files), so the loop is driven by ioEof() instead.
pub fn doLoadDataFile(load_mode: u16, s: u16, n: u16, d: u16) void {
    const ret = ioFileOpen(ioPathRegImport, ioModeRead);
    if (ret != runtime.FILE_OK) {
        if (ret == runtime.FILE_CANCEL) {
            screenUpdatingMode = SCRUPD_AUTO;
            refreshScreen(2998);
            return;
        } else {
            displayCalcErrorMessage(ERROR_CANNOT_READ_FILE, ERR_REGISTER_LINE, REGISTER_X_LINE);
            return;
        }
    }

    hourGlassIconEnabled = true;
    showHideHourGlass();

    codec.dataFileMode = true; // accept compact complex form / free-form matrix whitespace

    var line: [4000]u8 = undefined;
    runtime.readLine(line[0..]); // line 1 must be "DATA_FILE_REVISION"
    if (!runtime.lineEquals(&line[0], "DATA_FILE_REVISION")) {
        abi.fmtBufZ(line[0..4000], " \nThis is not a C47/R47 data file\n \nIt will not be loaded.", .{});
        show_warning(&line[0]);
        codec.dataFileMode = false;
        ioFileClose();
        return;
    }
    runtime.readLine(line[0..]); // line 2 must be exactly "0"
    if (!runtime.lineEquals(&line[0], "0")) {
        abi.fmtBufZ(line[0..4000], " \n   !!! Data file revision not supported !!!\nNot compatible with current version\n \nIt will not be loaded.", .{});
        show_warning(&line[0]);
        codec.dataFileMode = false;
        ioFileClose();
        return;
    }

    liftStack();

    while (runtime.ioEof() == 0) {
        _ = runtime.restoreOneSection(load_mode, s, n, d, false);
    }

    codec.dataFileMode = false;
    ioFileClose();
    temporaryInformation = TI_DATA_LOADED;

    screenUpdatingMode = SCRUPD_AUTO;
    refreshScreen(2999);
}
