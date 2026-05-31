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

const FixedPathSpec = struct {
    io_path: c_int,
    required_dir: ?[*:0]const u8,
    target_path: [*:0]const u8,
};

const DialogPathSpec = struct {
    io_path: c_int,
    title: [*:0]const u8,
    base_dir: [*:0]const u8,
    ext: [*:0]const u8,
    callback: ?*const anyopaque,
    disp_save: c_int,
    overwrite_check: c_int,
};

const fixed_path_specs = [_]FixedPathSpec{
    .{ .io_path = IO_PATH_MANUAL_SAVE, .required_dir = "SAVFILES", .target_path = "SAVFILES\\C47.sav" },
    .{ .io_path = IO_PATH_AUTO_SAVE, .required_dir = "SAVFILES", .target_path = "SAVFILES\\C47auto.sav" },
    .{ .io_path = IO_PATH_PGM_FILE, .required_dir = "LIBRARY", .target_path = "LIBRARY\\C47.dat" },
    .{ .io_path = IO_PATH_TEST_PGMS, .required_dir = null, .target_path = "testPgms.bin" },
};

const dialog_path_specs = [_]DialogPathSpec{
    .{
        .io_path = IO_PATH_SAVE_STATE_FILE,
        .title = "Save Calculator State",
        .base_dir = "STATE",
        .ext = ".s47",
        .callback = @ptrCast(&save_statefile),
        .disp_save = 1,
        .overwrite_check = 1,
    },
    .{
        .io_path = IO_PATH_LOAD_STATE_FILE,
        .title = "Load Calculator State",
        .base_dir = "STATE",
        .ext = ".s47",
        .callback = @ptrCast(&load_statefile),
        .disp_save = 0,
        .overwrite_check = 0,
    },
    .{
        .io_path = IO_PATH_SAVE_PROGRAM,
        .title = "Save Program",
        .base_dir = "PROGRAMS",
        .ext = ".p47",
        .callback = @ptrCast(&save_programfile),
        .disp_save = 1,
        .overwrite_check = 1,
    },
    .{
        .io_path = IO_PATH_EXPORT_RTF_PROGRAM,
        .title = "Export Program RTF",
        .base_dir = "PROGRAMS",
        .ext = ".rtf",
        .callback = @ptrCast(&save_programfile),
        .disp_save = 1,
        .overwrite_check = 1,
    },
    .{
        .io_path = IO_PATH_LOAD_PROGRAM,
        .title = "Load Program",
        .base_dir = "PROGRAMS",
        .ext = ".p47",
        .callback = @ptrCast(&load_programfile),
        .disp_save = 0,
        .overwrite_check = 0,
    },
};

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
extern fn save_statefile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) c_int;
extern fn load_statefile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) c_int;
extern fn save_programfile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) c_int;
extern fn load_programfile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) c_int;

fn writeZ(dest: [*c]u8, src: [*:0]const u8) void {
    var i: usize = 0;
    while (src[i] != 0) : (i += 1) {
        dest[i] = src[i];
    }
    dest[i] = 0;
}

fn applyFixedPath(path: c_int, filename: [*c]u8) ?c_int {
    inline for (fixed_path_specs) |spec| {
        if (spec.io_path == path) {
            if (spec.required_dir) |dir| {
                check_create_dir(@ptrCast(dir));
            }
            writeZ(filename, spec.target_path);
            return FILE_OK;
        }
    }
    return null;
}

fn applyDialogPath(path: c_int, filename: [*c]u8) ?c_int {
    inline for (dialog_path_specs) |spec| {
        if (spec.io_path == path) {
            check_create_dir(@ptrCast(spec.base_dir));
            const ret = file_selection_screen(
                @ptrCast(spec.title),
                @ptrCast(spec.base_dir),
                @ptrCast(spec.ext),
                spec.callback,
                spec.disp_save,
                spec.overwrite_check,
                filename,
            );
            return if (ret == MRET_EXIT) FILE_CANCEL else FILE_OK;
        }
    }
    return null;
}

pub fn ioFileNameFromFilePath(path: c_int, filename: [*c]u8) c_int {
    if (path == IO_PATH_REG_DUMP) {
        return FILE_OK;
    }

    if (applyFixedPath(path, filename)) |ret| {
        return ret;
    }

    if (applyDialogPath(path, filename)) |ret| {
        return ret;
    }

    return FILE_ERROR;
}
