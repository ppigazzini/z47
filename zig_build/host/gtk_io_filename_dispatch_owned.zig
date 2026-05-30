const base_dir_owned = @import("gtk_io_base_dir_owned.zig");
const path_policy_owned = @import("gtk_io_path_policy_owned.zig");

const FILE_ERROR: c_int = 0;
const FILE_OK: c_int = 1;

const SAVE_DIR = "SAVFILES";
const STATE_DIR = "STATE";
const PROGRAMS_DIR = "PROGRAMS";
const ALL_PROGRAMS_SUBDIR = "ALLPGMS";
const LIB_DIR = "LIBRARY";
const LIB_FILE = "C47.dat";
const STATE_PATTERN = "*.s47";
const PROGRAM_PATTERN = "*.p47";
const RTF_PATTERN = "*.rtf";
const PROGRAM_EXT = ".p47";
const RTF_EXT = ".rtf";
const FILENAME_BUFFER_LENGTH: usize = 400;

const IO_PATH_MANUAL_SAVE: c_int = 0;
const IO_PATH_AUTO_SAVE: c_int = 1;
const IO_PATH_PGM_FILE: c_int = 2;
const IO_PATH_TEST_PGMS: c_int = 3;
const IO_PATH_BACKUP: c_int = 4;
const IO_PATH_REG_DUMP: c_int = 5;
const IO_PATH_SAVE_STATE_FILE: c_int = 6;
const IO_PATH_LOAD_STATE_FILE: c_int = 7;
const IO_PATH_SAVE_PROGRAM: c_int = 8;
const IO_PATH_EXPORT_RTF_PROGRAM: c_int = 10;
const IO_PATH_LOAD_PROGRAM: c_int = 11;
const IO_PATH_SAVE_ALL_PROGRAMS: c_int = 12;
const IO_PATH_EXPORT_RTF_ALL_PROGRAMS: c_int = 13;

extern fn strcpy(dest: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strcat(dest: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn stringToASCII(str: [*c]const u8, ascii: [*c]u8) void;
extern fn file_selection_screen(
    title: [*c]const u8,
    base_dir: [*c]const u8,
    ext: [*c]const u8,
    disp_save: c_int,
    overwrite_check: c_int,
    data: ?*anyopaque,
) c_int;
extern var tmpStringLabelOrVariableName: [*c]u8;

pub fn ioFileNameFromFilePath(path: c_int, filename: [*c]u8) c_int {
    var base_dir: [FILENAME_BUFFER_LENGTH]u8 = [_]u8{0} ** FILENAME_BUFFER_LENGTH;

    switch (path) {
        IO_PATH_MANUAL_SAVE => {
            if (base_dir_owned.createDir(SAVE_DIR) != 0) return FILE_ERROR;
            _ = strcpy(filename, SAVE_DIR ++ "/");
            _ = strcat(filename, path_policy_owned.saveFileName());
            return FILE_OK;
        },
        IO_PATH_AUTO_SAVE => {
            if (base_dir_owned.createDir(SAVE_DIR) != 0) return FILE_ERROR;
            _ = strcpy(filename, SAVE_DIR ++ "/");
            _ = strcat(filename, path_policy_owned.autoSaveFileName());
            return FILE_OK;
        },
        IO_PATH_PGM_FILE => {
            if (base_dir_owned.createDir(LIB_DIR) != 0) return FILE_ERROR;
            _ = strcpy(filename, LIB_DIR ++ "/" ++ LIB_FILE);
            return FILE_OK;
        },
        IO_PATH_TEST_PGMS => {
            _ = strcpy(filename, "res/testPgms/testPgms.bin");
            return FILE_OK;
        },
        IO_PATH_BACKUP => {
            _ = strcpy(filename, path_policy_owned.backupFileName());
            return FILE_OK;
        },
        IO_PATH_REG_DUMP => {
            return FILE_OK;
        },
        IO_PATH_SAVE_STATE_FILE => {
            if (base_dir_owned.createDir(STATE_DIR) != 0) return FILE_ERROR;
            if (base_dir_owned.populateProgramBaseDir(&base_dir, STATE_DIR) != FILE_OK) return FILE_ERROR;
            return file_selection_screen("Save State File", &base_dir, STATE_PATTERN, 1, 1, filename);
        },
        IO_PATH_LOAD_STATE_FILE => {
            if (base_dir_owned.createDir(STATE_DIR) != 0) return FILE_ERROR;
            if (base_dir_owned.populateProgramBaseDir(&base_dir, STATE_DIR) != FILE_OK) return FILE_ERROR;
            return file_selection_screen("Load State File", &base_dir, STATE_PATTERN, 0, 0, filename);
        },
        IO_PATH_SAVE_PROGRAM => {
            if (base_dir_owned.createDir(PROGRAMS_DIR) != 0) return FILE_ERROR;
            if (base_dir_owned.populateProgramBaseDir(&base_dir, PROGRAMS_DIR) != FILE_OK) return FILE_ERROR;
            stringToASCII(tmpStringLabelOrVariableName, filename);
            return file_selection_screen("Save Program File", &base_dir, PROGRAM_PATTERN, 1, 1, filename);
        },
        IO_PATH_EXPORT_RTF_PROGRAM => {
            if (base_dir_owned.createDir(PROGRAMS_DIR) != 0) return FILE_ERROR;
            if (base_dir_owned.populateProgramBaseDir(&base_dir, PROGRAMS_DIR) != FILE_OK) return FILE_ERROR;
            stringToASCII(tmpStringLabelOrVariableName, filename);
            return file_selection_screen("Export Program File RTF", &base_dir, RTF_PATTERN, 1, 1, filename);
        },
        IO_PATH_LOAD_PROGRAM => {
            if (base_dir_owned.createDir(PROGRAMS_DIR) != 0) return FILE_ERROR;
            if (base_dir_owned.populateProgramBaseDir(&base_dir, PROGRAMS_DIR) != FILE_OK) return FILE_ERROR;
            return file_selection_screen("Load Program File", &base_dir, PROGRAM_PATTERN, 0, 0, filename);
        },
        IO_PATH_SAVE_ALL_PROGRAMS => {
            if (base_dir_owned.createDir(PROGRAMS_DIR) != 0) return FILE_ERROR;
            if (base_dir_owned.createDir(PROGRAMS_DIR ++ "/" ++ ALL_PROGRAMS_SUBDIR) != 0) return FILE_ERROR;
            stringToASCII(tmpStringLabelOrVariableName, filename);
            var filename_all: [FILENAME_BUFFER_LENGTH]u8 = [_]u8{0} ** FILENAME_BUFFER_LENGTH;
            _ = strcpy(&filename_all, PROGRAMS_DIR ++ "/" ++ ALL_PROGRAMS_SUBDIR ++ "/");
            _ = strcat(&filename_all, filename);
            _ = strcpy(filename, &filename_all);
            _ = strcat(filename, PROGRAM_EXT);
            return FILE_OK;
        },
        IO_PATH_EXPORT_RTF_ALL_PROGRAMS => {
            if (base_dir_owned.createDir(PROGRAMS_DIR) != 0) return FILE_ERROR;
            if (base_dir_owned.createDir(PROGRAMS_DIR ++ "/" ++ ALL_PROGRAMS_SUBDIR) != 0) return FILE_ERROR;
            stringToASCII(tmpStringLabelOrVariableName, filename);
            var filename_all: [FILENAME_BUFFER_LENGTH]u8 = [_]u8{0} ** FILENAME_BUFFER_LENGTH;
            _ = strcpy(&filename_all, PROGRAMS_DIR ++ "/" ++ ALL_PROGRAMS_SUBDIR ++ "/");
            _ = strcat(&filename_all, filename);
            _ = strcpy(filename, &filename_all);
            _ = strcat(filename, RTF_EXT);
            return FILE_OK;
        },
        else => return FILE_ERROR,
    }
}
