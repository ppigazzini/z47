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
const ERROR_INVALID_CORRUPTED_DATA: u8 = 18;
const ERR_REGISTER_LINE: i16 = 102; // REGISTER_Z
const REGISTER_X_LINE: i16 = 100;
const CONFIRMED: u16 = 9877; // items.h: confirmation for RESET, CLPALL, CLALL

// Post-restore program-memory screen (manage.c owner, shell object).
extern fn programMemoryHasOverlongLabelName(step: [*c]u8) bool;
extern fn fnClPAll(confirmation: u16) void;
extern var beginOfProgramMemory: [*c]u8;

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
    @setRuntimeSafety(true); // untrusted file input -- see calc_state.zig's panic decl
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
    const enable_load = policy_owned.canEnableLoad(load_mode, load_type, header.loaded_version);
    if (enable_load) {
        const allow_user_keys = runtime.allowUserKeys(header.saved_calc_model);
        // restoreOneSection() only returns false at END_CONFIG, which a file that
        // stops short -- truncated, or with a count that swallowed its last section --
        // never reaches: every further call then reads an empty section name, matches
        // nothing and returns true. Loop on ioEof() as well, as doLoadDataFile() does.
        while (runtime.ioEof() == 0 and runtime.restoreOneSection(load_mode, s, n, d, allow_user_keys)) {}
        runtime.fixupR47ShiftKeys();

        // The register section precedes shortIntegerWordSize in the file and the
        // file stores neither mask, so rederive both from the loaded word size
        // (config.c updateShortIntegerMasks) before any later short-integer op.
        runtime.updateShortIntegerMasks();
    }

    runtime.lastErrorCode = runtime.ERROR_NONE;
    runtime.previousErrorCode = runtime.lastErrorCode;

    // The PROGRAMS section is applied in place, so a file claiming a label name longer than MAX_LABEL_NAME_LENGTH leaves nothing to roll back to.
    // Clear the program area to an empty .END. and report the file as corrupt. fnClPAll also removes all XEQ key assignments, the right scope once every label is gone.
    if (enable_load and (load_mode == runtime.LM_ALL or load_mode == runtime.LM_PROGRAMS) and
        programMemoryHasOverlongLabelName(beginOfProgramMemory))
    {
        fnClPAll(CONFIRMED);
        displayCalcErrorMessage(ERROR_INVALID_CORRUPTED_DATA, ERR_REGISTER_LINE, REGISTER_X_LINE);
    }

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
    @setRuntimeSafety(true); // untrusted file input -- see calc_state.zig's panic decl
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
