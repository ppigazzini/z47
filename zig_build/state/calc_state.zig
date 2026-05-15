const builtin = @import("builtin");
const runtime = @import("calc_state_runtime.zig");

const is_dmcp_build = builtin.target.os.tag == .freestanding;

fn saveCalcHost() callconv(.c) void {
    runtime.saveCalcBackup();
}

fn restoreCalcHost() callconv(.c) void {
    runtime.restoreCalcBackup();
}

comptime {
    if (!is_dmcp_build) {
        @export(&saveCalcHost, .{ .name = "saveCalc" });
        @export(&restoreCalcHost, .{ .name = "restoreCalc" });
    }
}

const HeaderInfo = struct {
    saved_calc_model: u16 = 0,
    loaded_version: u32 = 0,
};

fn parseSaveFileRevision() HeaderInfo {
    var header_key: [256]u8 = undefined;
    var ignored_revision: [256]u8 = undefined;
    var calculator_id: [256]u8 = undefined;
    var version_line: [256]u8 = undefined;
    var info = HeaderInfo{};

    runtime.readLine(header_key[0..]);
    if (runtime.lineEquals(header_key[0..].ptr, "SAVE_FILE_REVISION")) {
        runtime.readLine(ignored_revision[0..]);
        runtime.readLine(calculator_id[0..]);
        runtime.readLine(version_line[0..]);

        if (runtime.lineEquals(calculator_id[0..].ptr, "C47_save_file_00")) {
            info.saved_calc_model = runtime.USER_C47;
        } else if (runtime.lineEquals(calculator_id[0..].ptr, "R47_save_file_00")) {
            info.saved_calc_model = runtime.USER_R47;
        }

        if (info.saved_calc_model == runtime.USER_C47 or info.saved_calc_model == runtime.USER_R47) {
            info.loaded_version = runtime.parseU32Line(version_line[0..].ptr);
            if (info.loaded_version < 10_000_000 or info.loaded_version > 20_000_000) {
                info.loaded_version = 0;
            }
        }
    }

    runtime.setSavedCalcModel(info.saved_calc_model);
    runtime.setLoadedVersion(info.loaded_version);
    return info;
}

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

pub export fn doLoad(load_mode: u16, s: u16, n: u16, d: u16, load_type: u16) void {
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

    const header = parseSaveFileRevision();
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

pub export fn fnLoad(load_mode: u16) void {
    runtime.showLoadingStatus();
    if (load_mode == runtime.LM_STATE_LOAD) {
        doLoad(runtime.LM_ALL, 0, 0, 0, runtime.stateLoad);
    } else {
        doLoad(load_mode, 0, 0, 0, runtime.manualLoad);
    }
    runtime.finishLoadUi(94);
}

pub export fn fnLoadAuto() void {
    doLoad(runtime.LM_ALL, 0, 0, 0, runtime.autoLoad);
    runtime.finishLoadUi(95);
}

pub export fn fnSaveAuto(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    if (is_dmcp_build) {
        doSave(runtime.autoSave);
    }
}

pub export fn fnSave(save_mode: u16) void {
    if (save_mode == runtime.SM_MANUAL_SAVE) {
        doSave(runtime.manualSave);
    } else if (save_mode == runtime.SM_STATE_SAVE) {
        doSave(runtime.stateSave);
    }
}
