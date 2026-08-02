const runtime = @import("calc_state_runtime.zig");

pub const HeaderInfo = struct {
    saved_calc_model: u16 = 0,
    loaded_version: u32 = 0,
};

pub fn parseSaveFileRevision() HeaderInfo {
    var header_key: [256]u8 = undefined;
    var ignored_revision: [256]u8 = undefined;
    var calculator_id: [256]u8 = undefined;
    var version_line: [256]u8 = undefined;
    var info = HeaderInfo{};

    runtime.readLine(header_key[0..]);
    if (runtime.lineEquals(header_key[0..], "SAVE_FILE_REVISION")) {
        runtime.readLine(ignored_revision[0..]);
        runtime.readLine(calculator_id[0..]);
        runtime.readLine(version_line[0..]);

        if (runtime.lineEquals(calculator_id[0..], "C47_save_file_00")) {
            info.saved_calc_model = runtime.USER_C47;
        } else if (runtime.lineEquals(calculator_id[0..], "R47_save_file_00")) {
            info.saved_calc_model = runtime.USER_R47;
        }

        if (info.saved_calc_model == runtime.USER_C47 or info.saved_calc_model == runtime.USER_R47) {
            info.loaded_version = runtime.parseU32Line(version_line[0..]);
            if (info.loaded_version < 10_000_000 or info.loaded_version > 20_000_000) {
                info.loaded_version = 0;
            }
        }
    }

    runtime.setSavedCalcModel(info.saved_calc_model);
    runtime.setLoadedVersion(info.loaded_version);
    return info;
}
