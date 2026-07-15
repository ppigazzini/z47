const runtime = @import("calc_state_runtime.zig");

fn isAutoLoadCompatibleVersion(loaded_version: u32) bool {
    return loaded_version >= runtime.versionAllowed() and loaded_version <= runtime.configFileVersion();
}

pub fn canEnableLoad(load_mode: u16, load_type: u16, loaded_version: u32) bool {
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

pub fn setPostLoadTemporaryInformation(load_mode: u16, load_type: u16, loaded_version: u32) void {
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
