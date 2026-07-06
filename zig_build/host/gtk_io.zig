const std = @import("std");

const FILE_ERROR: c_int = 0;
const FILE_OK: c_int = 1;
const FILE_CANCEL: c_int = 2;

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

const GTK_FILE_CHOOSER_ACTION_OPEN: c_int = 0;
const GTK_FILE_CHOOSER_ACTION_SAVE: c_int = 1;
const GTK_DIALOG_DESTROY_WITH_PARENT: c_int = 1 << 1;
const GTK_MESSAGE_WARNING: c_int = 1;
const GTK_BUTTONS_OK: c_int = 1;
const GTK_RESPONSE_ACCEPT: c_int = -3;

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

const IO_MODE_READ: c_int = 0;
const IO_MODE_WRITE: c_int = 1;
const IO_MODE_UPDATE: c_int = 2;
const STATE_FILE_NAME_VAR_LENGTH: usize = 20;
const DEFAULT_SAVE_NAME_BUFFER_LENGTH: usize = 7 * 11 + 1;

const USER_DM42: u8 = 45;
const USER_C47: u8 = 46;
const USER_R47f_g: u8 = 61;
const USER_R47bk_fg: u8 = 62;
const USER_R47fg_bk: u8 = 63;
const USER_R47fg_g: u8 = 64;
const USER_R47: u8 = 66;

const SAVE_FILE_C47 = "C47.sav";
const SAVE_FILE_R47 = "R47.sav";
const AUTO_SAVE_FILE_C47 = "C47auto.sav";
const AUTO_SAVE_FILE_R47 = "R47auto.sav";

const GtkWidget = opaque {};
const GtkWindow = opaque {};
const GtkDialog = opaque {};
const GtkFileChooserNative = opaque {};
const GtkFileChooser = opaque {};
const GtkFileFilter = opaque {};
const GtkNativeDialog = opaque {};

extern fn fopen(filename: [*c]const u8, mode: [*c]const u8) ?*anyopaque;
extern fn fwrite(ptr: ?*const anyopaque, size: usize, nitems: usize, stream: ?*anyopaque) usize;
extern fn fread(ptr: ?*anyopaque, size: usize, nitems: usize, stream: ?*anyopaque) usize;
extern fn fseek(stream: ?*anyopaque, offset: c_long, whence: c_int) c_int;
extern fn fclose(stream: ?*anyopaque) c_int;
extern fn feof(stream: ?*anyopaque) c_int;
extern fn remove(pathname: [*c]const u8) c_int;
extern fn strcpy(dest: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strcat(dest: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strlen(s: [*c]const u8) usize;
extern fn g_get_current_dir() [*c]u8;
extern fn g_free(mem: ?*anyopaque) void;
extern fn g_object_unref(object: ?*anyopaque) void;
extern fn stringToASCII(str: [*c]const u8, ascii: [*c]u8) void;

extern fn gtk_file_chooser_native_new(
    title: [*c]const u8,
    parent: ?*GtkWindow,
    action: c_int,
    accept_label: [*c]const u8,
    cancel_label: [*c]const u8,
) ?*GtkFileChooserNative;
extern fn gtk_file_chooser_set_do_overwrite_confirmation(chooser: ?*GtkFileChooser, do_overwrite_confirmation: c_int) void;
extern fn gtk_file_chooser_set_current_folder(chooser: ?*GtkFileChooser, folder: [*c]const u8) c_int;
extern fn gtk_file_chooser_set_current_name(chooser: ?*GtkFileChooser, name: [*c]const u8) void;
extern fn gtk_file_filter_new() ?*GtkFileFilter;
extern fn gtk_file_filter_add_pattern(filter: ?*GtkFileFilter, pattern: [*c]const u8) void;
extern fn gtk_file_chooser_add_filter(chooser: ?*GtkFileChooser, filter: ?*GtkFileFilter) void;
extern fn gtk_native_dialog_run(dialog: ?*GtkNativeDialog) c_int;
extern fn gtk_file_chooser_get_filename(chooser: ?*GtkFileChooser) [*c]u8;
extern fn gtk_message_dialog_new(
    parent: ?*GtkWindow,
    flags: c_int,
    message_type: c_int,
    buttons: c_int,
    message_format: [*c]const u8,
    ...,
) ?*GtkWidget;
extern fn gtk_window_set_title(window: ?*GtkWindow, title: [*c]const u8) void;
extern fn gtk_dialog_run(dialog: ?*GtkDialog) c_int;
extern fn gtk_widget_destroy(widget: ?*GtkWidget) void;

extern var fileNameSelected: [STATE_FILE_NAME_VAR_LENGTH]u8;
extern var calcModel: u8;
extern var frmCalc: ?*GtkWidget;
extern var tmpStringLabelOrVariableName: [*c]u8;

fn createDir(path: [*c]const u8) c_int {
    const zpath: [*:0]const u8 = @ptrCast(path);
    switch (std.posix.errno(std.posix.system.mkdir(zpath, 0o775))) {
        .SUCCESS, .EXIST => return 0,
        else => return -1,
    }
}

fn parentWindow() ?*anyopaque {
    return if (frmCalc) |window| @ptrCast(window) else null;
}

fn populateProgramBaseDir(base_dir: [*c]u8, dir_name: [*c]const u8) c_int {
    const current_dir = g_get_current_dir();
    if (current_dir == null) return FILE_ERROR;
    defer g_free(current_dir);

    _ = strcpy(base_dir, current_dir);
    _ = strcat(base_dir, "/");
    _ = strcat(base_dir, dir_name);
    return FILE_OK;
}

fn selectedFileNameSource(filename: [*c]u8) [*c]u8 {
    const length = strlen(filename);
    const min_start = if (length + 1 > STATE_FILE_NAME_VAR_LENGTH)
        length - STATE_FILE_NAME_VAR_LENGTH + 1
    else
        0;

    var start = length;
    while (start > min_start) : (start -= 1) {
        const ch = filename[start - 1];
        if (ch == '/' or ch == '\\' or ch == 0) break;
    }

    return filename + start;
}

fn isR47Family(model: u8) bool {
    return switch (model) {
        USER_R47, USER_R47f_g, USER_R47bk_fg, USER_R47fg_bk, USER_R47fg_g => true,
        else => false,
    };
}

fn saveFileName() [*c]const u8 {
    return if (isR47Family(calcModel)) SAVE_FILE_R47 else SAVE_FILE_C47;
}

fn autoSaveFileName() [*c]const u8 {
    return if (isR47Family(calcModel)) AUTO_SAVE_FILE_R47 else AUTO_SAVE_FILE_C47;
}

fn backupFileName() [*c]const u8 {
    return switch (calcModel) {
        USER_C47, USER_DM42 => "backup.cfg",
        else => "backupR47.cfg",
    };
}

pub fn fileSelectionScreen(
    title: [*c]const u8,
    base_dir: [*c]const u8,
    ext: [*c]const u8,
    disp_save: c_int,
    overwrite_check: c_int,
    data: ?*anyopaque,
) c_int {
    const data_buffer = data orelse return FILE_ERROR;
    const filename: [*c]u8 = @ptrCast(data_buffer);
    var untitled: [DEFAULT_SAVE_NAME_BUFFER_LENGTH]u8 = [_]u8{0} ** DEFAULT_SAVE_NAME_BUFFER_LENGTH;

    _ = strcpy(&untitled, filename);
    _ = strcat(&untitled, ext + 1);

    const native = gtk_file_chooser_native_new(
        title,
        @ptrCast(parentWindow()),
        if (disp_save != 0) GTK_FILE_CHOOSER_ACTION_SAVE else GTK_FILE_CHOOSER_ACTION_OPEN,
        if (disp_save != 0) "_Save" else "_Load",
        "_Cancel",
    ) orelse return FILE_ERROR;
    defer g_object_unref(@ptrCast(native));

    const chooser: ?*GtkFileChooser = @ptrCast(native);
    const dialog: ?*GtkNativeDialog = @ptrCast(native);

    if (overwrite_check != 0) {
        gtk_file_chooser_set_do_overwrite_confirmation(chooser, 1);
    }

    _ = gtk_file_chooser_set_current_folder(chooser, base_dir);
    if (disp_save != 0) {
        gtk_file_chooser_set_current_name(chooser, &untitled);
    }

    const filter = gtk_file_filter_new();
    if (filter != null) {
        gtk_file_filter_add_pattern(filter, ext);
        gtk_file_chooser_add_filter(chooser, filter);
    }

    const response = gtk_native_dialog_run(dialog);
    if (response != GTK_RESPONSE_ACCEPT) {
        return FILE_CANCEL;
    }

    const selected_filename = gtk_file_chooser_get_filename(chooser);
    if (selected_filename == null) {
        return FILE_ERROR;
    }
    defer g_free(selected_filename);

    _ = strcpy(filename, selected_filename);
    if (disp_save != 0) {
        const chosen = std.mem.sliceTo(selected_filename, 0);
        const ext_suffix = std.mem.sliceTo(ext + 1, 0);
        if (!std.mem.endsWith(u8, chosen, ext_suffix)) {
            _ = strcat(filename, ext + 1);
        }
    }

    return FILE_OK;
}

pub fn ioFileNameFromFilePath(path: c_int, filename: [*c]u8) c_int {
    var base_dir: [FILENAME_BUFFER_LENGTH]u8 = [_]u8{0} ** FILENAME_BUFFER_LENGTH;

    switch (path) {
        IO_PATH_MANUAL_SAVE => {
            if (createDir(SAVE_DIR) != 0) return FILE_ERROR;
            _ = strcpy(filename, SAVE_DIR ++ "/");
            _ = strcat(filename, saveFileName());
            return FILE_OK;
        },
        IO_PATH_AUTO_SAVE => {
            if (createDir(SAVE_DIR) != 0) return FILE_ERROR;
            _ = strcpy(filename, SAVE_DIR ++ "/");
            _ = strcat(filename, autoSaveFileName());
            return FILE_OK;
        },
        IO_PATH_PGM_FILE => {
            if (createDir(LIB_DIR) != 0) return FILE_ERROR;
            _ = strcpy(filename, LIB_DIR ++ "/" ++ LIB_FILE);
            return FILE_OK;
        },
        IO_PATH_TEST_PGMS => {
            _ = strcpy(filename, "res/testPgms/testPgms.bin");
            return FILE_OK;
        },
        IO_PATH_BACKUP => {
            _ = strcpy(filename, backupFileName());
            return FILE_OK;
        },
        IO_PATH_REG_DUMP => {
            return FILE_OK;
        },
        IO_PATH_SAVE_STATE_FILE => {
            if (createDir(STATE_DIR) != 0) return FILE_ERROR;
            if (populateProgramBaseDir(&base_dir, STATE_DIR) != FILE_OK) return FILE_ERROR;
            return fileSelectionScreen("Save State File", &base_dir, STATE_PATTERN, 1, 1, filename);
        },
        IO_PATH_LOAD_STATE_FILE => {
            if (createDir(STATE_DIR) != 0) return FILE_ERROR;
            if (populateProgramBaseDir(&base_dir, STATE_DIR) != FILE_OK) return FILE_ERROR;
            return fileSelectionScreen("Load State File", &base_dir, STATE_PATTERN, 0, 0, filename);
        },
        IO_PATH_SAVE_PROGRAM => {
            if (createDir(PROGRAMS_DIR) != 0) return FILE_ERROR;
            if (populateProgramBaseDir(&base_dir, PROGRAMS_DIR) != FILE_OK) return FILE_ERROR;
            stringToASCII(tmpStringLabelOrVariableName, filename);
            return fileSelectionScreen("Save Program File", &base_dir, PROGRAM_PATTERN, 1, 1, filename);
        },
        IO_PATH_EXPORT_RTF_PROGRAM => {
            if (createDir(PROGRAMS_DIR) != 0) return FILE_ERROR;
            if (populateProgramBaseDir(&base_dir, PROGRAMS_DIR) != FILE_OK) return FILE_ERROR;
            stringToASCII(tmpStringLabelOrVariableName, filename);
            return fileSelectionScreen("Export Program File RTF", &base_dir, RTF_PATTERN, 1, 1, filename);
        },
        IO_PATH_LOAD_PROGRAM => {
            if (createDir(PROGRAMS_DIR) != 0) return FILE_ERROR;
            if (populateProgramBaseDir(&base_dir, PROGRAMS_DIR) != FILE_OK) return FILE_ERROR;
            return fileSelectionScreen("Load Program File", &base_dir, PROGRAM_PATTERN, 0, 0, filename);
        },
        IO_PATH_SAVE_ALL_PROGRAMS => {
            if (createDir(PROGRAMS_DIR) != 0) return FILE_ERROR;
            if (createDir(PROGRAMS_DIR ++ "/" ++ ALL_PROGRAMS_SUBDIR) != 0) return FILE_ERROR;
            stringToASCII(tmpStringLabelOrVariableName, filename);
            var filename_all: [FILENAME_BUFFER_LENGTH]u8 = [_]u8{0} ** FILENAME_BUFFER_LENGTH;
            _ = strcpy(&filename_all, PROGRAMS_DIR ++ "/" ++ ALL_PROGRAMS_SUBDIR ++ "/");
            _ = strcat(&filename_all, filename);
            _ = strcpy(filename, &filename_all);
            _ = strcat(filename, PROGRAM_EXT);
            return FILE_OK;
        },
        IO_PATH_EXPORT_RTF_ALL_PROGRAMS => {
            if (createDir(PROGRAMS_DIR) != 0) return FILE_ERROR;
            if (createDir(PROGRAMS_DIR ++ "/" ++ ALL_PROGRAMS_SUBDIR) != 0) return FILE_ERROR;
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

pub fn ioFileOpen(handle: *?*anyopaque, path: c_int, mode: c_int) c_int {
    if (handle.* != null) return FILE_ERROR;

    var filename: [400]u8 = [_]u8{0} ** 400;
    _ = strcpy(&filename, "untitled");
    fileNameSelected[0] = 0;

    const ret = ioFileNameFromFilePath(path, &filename);
    if (ret != FILE_OK) return ret;

    const filemode: [*c]const u8 = switch (mode) {
        IO_MODE_READ => "rb",
        IO_MODE_WRITE => "wb",
        IO_MODE_UPDATE => "r+b",
        else => return FILE_ERROR,
    };

    handle.* = fopen(&filename, filemode);
    if (handle.* != null) {
        if (mode == IO_MODE_READ) {
            _ = strcpy(&fileNameSelected, selectedFileNameSource(&filename));
        }
        return FILE_OK;
    }
    return FILE_ERROR;
}

pub fn ioFileWrite(handle: ?*anyopaque, buffer: ?*const anyopaque, size: u32) void {
    if (handle) |f| {
        _ = fwrite(buffer, 1, size, f);
    }
}

pub fn ioFileRead(handle: ?*anyopaque, buffer: ?*anyopaque, size: u32) u32 {
    if (handle) |f| {
        return @intCast(fread(buffer, 1, size, f));
    }
    return 0;
}

pub fn ioFileSeek(handle: ?*anyopaque, position: u32) void {
    if (handle) |f| {
        _ = fseek(f, @intCast(position), 0);
    }
}

pub fn ioFileClose(handle: *?*anyopaque) void {
    if (handle.*) |f| {
        _ = fclose(f);
        handle.* = null;
    }
}

pub fn ioEof(handle: ?*anyopaque) c_int {
    if (handle) |f| {
        return feof(f);
    }
    return 1;
}

pub fn ioFileRemove(path: c_int, error_number: ?*u32) c_int {
    var filename: [400]u8 = [_]u8{0} ** 400;
    const ret = ioFileNameFromFilePath(path, &filename);
    if (ret != FILE_OK) return ret;

    const result = remove(&filename);
    if (result == -1 and error_number != null) {
        error_number.?.* = @intCast(std.c._errno().*);
    }
    return if (result != -1) FILE_OK else FILE_ERROR;
}

pub fn showWarning(string: [*c]u8) void {
    const dialog = gtk_message_dialog_new(
        @ptrCast(parentWindow()),
        GTK_DIALOG_DESTROY_WITH_PARENT,
        GTK_MESSAGE_WARNING,
        GTK_BUTTONS_OK,
        "%s",
        string,
    ) orelse return;
    gtk_window_set_title(@ptrCast(dialog), "Warning");
    _ = gtk_dialog_run(@ptrCast(dialog));
    gtk_widget_destroy(dialog);
}
