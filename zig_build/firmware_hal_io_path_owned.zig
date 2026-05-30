const FILE_ERROR: c_int = 0;
const FILE_OK: c_int = 1;
const FILE_CANCEL: c_int = 2;

const MRET_EXIT: c_int = -2;

const IO_PATH_MANUAL_SAVE: c_int = 0;
const IO_PATH_AUTO_SAVE: c_int = 1;
const IO_PATH_PGM_FILE: c_int = 2;
const IO_PATH_TEST_PGMS: c_int = 3;
const IO_PATH_REG_DUMP: c_int = 5;
const IO_PATH_SAVE_STATE_FILE: c_int = 6;
const IO_PATH_LOAD_STATE_FILE: c_int = 7;
const IO_PATH_SAVE_PROGRAM: c_int = 8;
const IO_PATH_EXPORT_RTF_PROGRAM: c_int = 10;
const IO_PATH_LOAD_PROGRAM: c_int = 11;

extern fn check_create_dir(path: [*c]const u8) void;
extern fn file_selection_screen(
    title: [*c]const u8,
    base_dir: [*c]const u8,
    ext: [*c]const u8,
    callback: ?*const anyopaque,
    disp_save: c_int,
    overwrite_check: c_int,
    data: ?*anyopaque,
) c_int;
extern fn strcpy(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn save_statefile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) c_int;
extern fn load_statefile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) c_int;
extern fn save_programfile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) c_int;
extern fn load_programfile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) c_int;

pub fn ioFileNameFromFilePath(path: c_int, filename: [*c]u8) c_int {
    var ret: c_int = 0;
    switch (path) {
        IO_PATH_MANUAL_SAVE => {
            check_create_dir("SAVFILES");
            _ = strcpy(filename, "SAVFILES\\C47.sav");
            return FILE_OK;
        },
        IO_PATH_AUTO_SAVE => {
            check_create_dir("SAVFILES");
            _ = strcpy(filename, "SAVFILES\\C47auto.sav");
            return FILE_OK;
        },
        IO_PATH_PGM_FILE => {
            check_create_dir("LIBRARY");
            _ = strcpy(filename, "LIBRARY\\C47.dat");
            return FILE_OK;
        },
        IO_PATH_TEST_PGMS => {
            _ = strcpy(filename, "testPgms.bin");
            return FILE_OK;
        },
        IO_PATH_REG_DUMP => return FILE_OK,
        IO_PATH_SAVE_STATE_FILE => {
            check_create_dir("STATE");
            ret = file_selection_screen("Save Calculator State", "STATE", ".s47", @ptrCast(&save_statefile), 1, 1, filename);
            return if (ret == MRET_EXIT) FILE_CANCEL else FILE_OK;
        },
        IO_PATH_LOAD_STATE_FILE => {
            check_create_dir("STATE");
            ret = file_selection_screen("Load Calculator State", "STATE", ".s47", @ptrCast(&load_statefile), 0, 0, filename);
            return if (ret == MRET_EXIT) FILE_CANCEL else FILE_OK;
        },
        IO_PATH_SAVE_PROGRAM => {
            check_create_dir("PROGRAMS");
            ret = file_selection_screen("Save Program", "PROGRAMS", ".p47", @ptrCast(&save_programfile), 1, 1, filename);
            return if (ret == MRET_EXIT) FILE_CANCEL else FILE_OK;
        },
        IO_PATH_EXPORT_RTF_PROGRAM => {
            check_create_dir("PROGRAMS");
            ret = file_selection_screen("Export Program RTF", "PROGRAMS", ".rtf", @ptrCast(&save_programfile), 1, 1, filename);
            return if (ret == MRET_EXIT) FILE_CANCEL else FILE_OK;
        },
        IO_PATH_LOAD_PROGRAM => {
            check_create_dir("PROGRAMS");
            ret = file_selection_screen("Load Program", "PROGRAMS", ".p47", @ptrCast(&load_programfile), 0, 0, filename);
            return if (ret == MRET_EXIT) FILE_CANCEL else FILE_OK;
        },
        else => return FILE_ERROR,
    }
}
