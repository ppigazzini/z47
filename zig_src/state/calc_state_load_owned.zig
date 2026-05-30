const builtin = @import("builtin");
const header_owned = @import("calc_state_header_owned.zig");
const runtime = @import("calc_state_runtime.zig");

const is_dmcp_build = builtin.target.os.tag == .freestanding;

fn isAutoLoadCompatibleVersion(loaded_version: u32) bool {
    return loaded_version >= runtime.versionAllowed() and loaded_version <= runtime.configFileVersion();
}

fn canEnableLoad(load_mode: u16, load_type: u16, loaded_version: u32) bool {
    switch (load_type) {
        runtime.manualLoad => switch (load_mode) {
            runtime.LM_ALL,
            runtime.LM_PROGRAMS,
            runtime.LM_REGISTERS,
            runtime.LM_SYSTEM_STATE,
            runtime.LM_SUMS,
            runtime.LM_NAMED_VARIABLES,
            => return true,
            else => return false,
        },
        runtime.stateLoad => return load_mode == runtime.LM_ALL,
        runtime.autoLoad => return load_mode == runtime.LM_ALL and isAutoLoadCompatibleVersion(loaded_version),
        else => return false,
    }
}

fn setPostLoadTemporaryInformation(load_mode: u16, load_type: u16, loaded_version: u32) void {
    if (load_type == runtime.manualLoad and load_mode == runtime.LM_ALL) {
        runtime.temporaryInformation = runtime.TI_BACKUP_RESTORED;
        runtime.stampLastStateFileOpened();
        return;
    }

    if (load_type == runtime.autoLoad and load_mode == runtime.LM_ALL and isAutoLoadCompatibleVersion(loaded_version)) {
        runtime.temporaryInformation = runtime.TI_BACKUP_RESTORED;
        runtime.stampLastStateFileOpened();
        return;
    }

    if (load_type == runtime.stateLoad) {
        runtime.temporaryInformation = runtime.TI_STATEFILE_RESTORED;
        runtime.stampLastStateFileOpened();
        return;
    }

    switch (load_mode) {
        runtime.LM_PROGRAMS => runtime.temporaryInformation = runtime.TI_PROGRAMS_RESTORED,
        runtime.LM_REGISTERS => runtime.temporaryInformation = runtime.TI_REGISTERS_RESTORED,
        runtime.LM_SYSTEM_STATE => runtime.temporaryInformation = runtime.TI_SETTINGS_RESTORED,
        runtime.LM_SUMS => runtime.temporaryInformation = runtime.TI_SUMS_RESTORED,
        runtime.LM_NAMED_VARIABLES => runtime.temporaryInformation = runtime.TI_VARIABLES_RESTORED,
        else => {},
    }
}

fn doSave(save_type: u16) void {
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
    if (is_dmcp_build) {
        runtime.doLoadRetained(load_mode, s, n, d, load_type);
        return;
    }

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
    if (canEnableLoad(load_mode, load_type, header.loaded_version)) {
        const allow_user_keys = runtime.allowUserKeys(header.saved_calc_model);
        while (runtime.restoreOneSection(load_mode, s, n, d, allow_user_keys)) {}
        runtime.fixupR47ShiftKeys();
    }

    runtime.lastErrorCode = runtime.ERROR_NONE;
    runtime.previousErrorCode = runtime.lastErrorCode;

    runtime.closeFile();
    runtime.restartPostLoadTimers();
    setPostLoadTemporaryInformation(load_mode, load_type, header.loaded_version);
    runtime.cachedDynamicMenu = 0;
}

pub fn load(load_mode: u16) void {
    if (is_dmcp_build) {
        runtime.loadRetained(load_mode);
        return;
    }

    runtime.showLoadingStatus();
    if (load_mode == runtime.LM_STATE_LOAD) {
        doLoad(runtime.LM_ALL, 0, 0, 0, runtime.stateLoad);
    } else {
        doLoad(load_mode, 0, 0, 0, runtime.manualLoad);
    }
    runtime.finishLoadUi(94);
}

pub fn loadAuto() void {
    doLoad(runtime.LM_ALL, 0, 0, 0, runtime.autoLoad);
    runtime.finishLoadUi(95);
}

pub fn saveAuto(unused_but_mandatory_parameter: u16) void {
    if (is_dmcp_build) {
        runtime.saveAutoRetained(unused_but_mandatory_parameter);
        return;
    }
}

pub fn save(save_mode: u16) void {
    if (is_dmcp_build) {
        runtime.saveRetained(save_mode);
        return;
    }

    if (save_mode == runtime.SM_MANUAL_SAVE) {
        doSave(runtime.manualSave);
    } else if (save_mode == runtime.SM_STATE_SAVE) {
        doSave(runtime.stateSave);
    }
}