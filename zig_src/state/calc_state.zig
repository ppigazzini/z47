const builtin = @import("builtin");
const runtime = @import("calc_state_runtime.zig");

const isDmcpBuild = builtin.target.os.tag == .freestanding;

fn saveCalcBackupHost() callconv(.c) void {
    runtime.saveCalcBackup();
}

fn restoreCalcBackupHost() callconv(.c) void {
    runtime.restoreCalcBackup();
}

comptime {
    if (!isDmcpBuild) {
        @export(&saveCalcBackupHost, .{ .name = "saveCalc" });
        @export(&restoreCalcBackupHost, .{ .name = "restoreCalc" });
    }
}

const HeaderInfo = struct {
    savedCalcModel: u16 = 0,
    loadedVersion: u32 = 0,
};

fn parseSaveFileRevision() HeaderInfo {
    var headerKey: [256]u8 = undefined;
    var ignoredRevision: [256]u8 = undefined;
    var calculatorId: [256]u8 = undefined;
    var versionLine: [256]u8 = undefined;
    var info = HeaderInfo{};

    runtime.readLine(headerKey[0..]);
    if (runtime.lineEquals(headerKey[0..].ptr, "SAVE_FILE_REVISION")) {
        runtime.readLine(ignoredRevision[0..]);
        runtime.readLine(calculatorId[0..]);
        runtime.readLine(versionLine[0..]);

        if (runtime.lineEquals(calculatorId[0..].ptr, "C47_save_file_00")) {
            info.savedCalcModel = runtime.USER_C47;
        } else if (runtime.lineEquals(calculatorId[0..].ptr, "R47_save_file_00")) {
            info.savedCalcModel = runtime.USER_R47;
        }

        if (info.savedCalcModel == runtime.USER_C47 or info.savedCalcModel == runtime.USER_R47) {
            info.loadedVersion = runtime.parseU32Line(versionLine[0..].ptr);
            if (info.loadedVersion < 10_000_000 or info.loadedVersion > 20_000_000) {
                info.loadedVersion = 0;
            }
        }
    }

    runtime.setSavedCalcModel(info.savedCalcModel);
    runtime.setLoadedVersion(info.loadedVersion);
    return info;
}

fn isAutoLoadCompatibleVersion(loadedVersion: u32) bool {
    return loadedVersion >= runtime.versionAllowed() and loadedVersion <= runtime.configFileVersion();
}

fn canEnableLoad(loadMode: u16, loadType: u16, loadedVersion: u32) bool {
    switch (loadType) {
        runtime.manualLoad => switch (loadMode) {
            runtime.LM_ALL,
            runtime.LM_PROGRAMS,
            runtime.LM_REGISTERS,
            runtime.LM_SYSTEM_STATE,
            runtime.LM_SUMS,
            runtime.LM_NAMED_VARIABLES,
            => return true,
            else => return false,
        },
        runtime.stateLoad => return loadMode == runtime.LM_ALL,
        runtime.autoLoad => return loadMode == runtime.LM_ALL and isAutoLoadCompatibleVersion(loadedVersion),
        else => return false,
    }
}

fn setPostLoadTemporaryInformation(loadMode: u16, loadType: u16, loadedVersion: u32) void {
    if (loadType == runtime.manualLoad and loadMode == runtime.LM_ALL) {
        runtime.temporaryInformation = runtime.TI_BACKUP_RESTORED;
        runtime.stampLastStateFileOpened();
        return;
    }

    if (loadType == runtime.autoLoad and loadMode == runtime.LM_ALL and isAutoLoadCompatibleVersion(loadedVersion)) {
        runtime.temporaryInformation = runtime.TI_BACKUP_RESTORED;
        runtime.stampLastStateFileOpened();
        return;
    }

    if (loadType == runtime.stateLoad) {
        runtime.temporaryInformation = runtime.TI_STATEFILE_RESTORED;
        runtime.stampLastStateFileOpened();
        return;
    }

    switch (loadMode) {
        runtime.LM_PROGRAMS => runtime.temporaryInformation = runtime.TI_PROGRAMS_RESTORED,
        runtime.LM_REGISTERS => runtime.temporaryInformation = runtime.TI_REGISTERS_RESTORED,
        runtime.LM_SYSTEM_STATE => runtime.temporaryInformation = runtime.TI_SETTINGS_RESTORED,
        runtime.LM_SUMS => runtime.temporaryInformation = runtime.TI_SUMS_RESTORED,
        runtime.LM_NAMED_VARIABLES => runtime.temporaryInformation = runtime.TI_VARIABLES_RESTORED,
        else => {},
    }
}

fn doSave(saveType: u16) void {
    runtime.showSavingStatus();

    if (runtime.checkPower()) {
        return;
    }

    const openResult = runtime.openSave(saveType);
    if (openResult != runtime.FILE_OK) {
        if (openResult == runtime.FILE_CANCEL) {
            return;
        }

        runtime.displayWriteError();
        return;
    }
    defer runtime.closeFile();

    runtime.writeSaveSections();
    runtime.temporaryInformation = runtime.TI_SAVED;
}

pub export fn doLoad(loadMode: u16, s: u16, n: u16, d: u16, loadType: u16) void {
    if (isDmcpBuild) {
        runtime.doLoadRetained(loadMode, s, n, d, loadType);
        return;
    }

    runtime.resetLoadContext();

    const openResult = runtime.openLoad(loadType);
    if (openResult != runtime.FILE_OK) {
        if (openResult == runtime.FILE_CANCEL) {
            return;
        }

        runtime.displayReadError();
        return;
    }

    if (loadMode == runtime.LM_ALL) {
        runtime.unwindAllSubroutines();
    }

    const header = parseSaveFileRevision();
    if (canEnableLoad(loadMode, loadType, header.loadedVersion)) {
        const allowUserKeys = runtime.allowUserKeys(header.savedCalcModel);
        while (runtime.restoreOneSection(loadMode, s, n, d, allowUserKeys)) {}
        runtime.fixupR47ShiftKeys();
    }

    runtime.lastErrorCode = runtime.ERROR_NONE;
    runtime.previousErrorCode = runtime.lastErrorCode;

    runtime.closeFile();
    runtime.restartPostLoadTimers();
    setPostLoadTemporaryInformation(loadMode, loadType, header.loadedVersion);
    runtime.cachedDynamicMenu = 0;
}

pub export fn fnLoad(loadMode: u16) void {
    if (isDmcpBuild) {
        runtime.loadRetained(loadMode);
        return;
    }

    runtime.showLoadingStatus();
    if (loadMode == runtime.LM_STATE_LOAD) {
        doLoad(runtime.LM_ALL, 0, 0, 0, runtime.stateLoad);
    } else {
        doLoad(loadMode, 0, 0, 0, runtime.manualLoad);
    }
    runtime.finishLoadUi(94);
}

pub export fn fnLoadAuto() void {
    doLoad(runtime.LM_ALL, 0, 0, 0, runtime.autoLoad);
    runtime.finishLoadUi(95);
}

pub export fn fnSaveAuto(unusedButMandatoryParameter: u16) void {
    if (isDmcpBuild) {
        runtime.saveAutoRetained(unusedButMandatoryParameter);
        return;
    }
}

pub export fn fnSave(saveMode: u16) void {
    if (isDmcpBuild) {
        runtime.saveRetained(saveMode);
        return;
    }

    if (saveMode == runtime.SM_MANUAL_SAVE) {
        doSave(runtime.manualSave);
    } else if (saveMode == runtime.SM_STATE_SAVE) {
        doSave(runtime.stateSave);
    }
}
