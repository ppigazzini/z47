const std = @import("std");
const base_dir_owned = @import("gtk_io_base_dir_owned.zig");
const path_policy_owned = @import("gtk_io_path_policy_owned.zig");

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
const DEFAULT_SAVE_NAME_BUFFER_LENGTH: usize = 7 * 11 + 1;
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

const GtkWidget = opaque {};
const GtkWindow = opaque {};
const GtkDialog = opaque {};
const GtkFileChooserNative = opaque {};
const GtkFileChooser = opaque {};
const GtkFileFilter = opaque {};
const GtkNativeDialog = opaque {};

var io_file_handle: ?*anyopaque = null;

extern fn fopen(filename: [*c]const u8, mode: [*c]const u8) ?*anyopaque;
extern fn fwrite(ptr: ?*const anyopaque, size: usize, nitems: usize, stream: ?*anyopaque) usize;
extern fn fread(ptr: ?*anyopaque, size: usize, nitems: usize, stream: ?*anyopaque) usize;
extern fn fseek(stream: ?*anyopaque, offset: c_long, whence: c_int) c_int;
extern fn fclose(stream: ?*anyopaque) c_int;
extern fn feof(stream: ?*anyopaque) c_int;
extern fn remove(pathname: [*c]const u8) c_int;
extern fn strcpy(dest: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strcat(dest: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strcmp(lhs: [*c]const u8, rhs: [*c]const u8) c_int;
extern fn strlen(s: [*c]const u8) usize;
extern fn snprintf(str: [*c]u8, size: usize, format: [*c]const u8, ...) c_int;
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

pub export fn file_selection_screen(
    title: [*c]const u8,
    base_dir: [*c]const u8,
    ext: [*c]const u8,
    disp_save: c_int,
    overwrite_check: c_int,
    data: ?*anyopaque,
) callconv(.c) c_int {
    const data_buffer = data orelse return FILE_ERROR;
    const filename: [*c]u8 = @ptrCast(data_buffer);
    var untitled: [DEFAULT_SAVE_NAME_BUFFER_LENGTH]u8 = [_]u8{0} ** DEFAULT_SAVE_NAME_BUFFER_LENGTH;

    _ = strcpy(&untitled, filename);
    _ = strcat(&untitled, ext + 1);

    const native = gtk_file_chooser_native_new(
        title,
        @ptrCast(base_dir_owned.parentWindow()),
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

pub export fn _ioFileNameFromFilePath(path: c_int, filename: [*c]u8) callconv(.c) c_int {
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

pub export fn ioFileOpen(path: c_int, mode: c_int) callconv(.c) c_int {
    if (io_file_handle != null) return FILE_ERROR;

    var filename: [400]u8 = [_]u8{0} ** 400;
    _ = strcpy(&filename, "untitled");
    fileNameSelected[0] = 0;

    const ret = _ioFileNameFromFilePath(path, &filename);
    if (ret != FILE_OK) return ret;

    const filemode: [*c]const u8 = switch (mode) {
        IO_MODE_READ => "rb",
        IO_MODE_WRITE => "wb",
        IO_MODE_UPDATE => "r+b",
        else => return FILE_ERROR,
    };

    io_file_handle = fopen(&filename, filemode);
    if (io_file_handle != null) {
        if (mode == IO_MODE_READ) {
            _ = strcpy(&fileNameSelected[0], path_policy_owned.selectedFileNameSource(&filename));
        }
        return FILE_OK;
    }
    return FILE_ERROR;
}

pub export fn ioFileWrite(buffer: ?*const anyopaque, size: u32) callconv(.c) void {
    if (io_file_handle) |f| {
        _ = fwrite(buffer, 1, size, f);
    }
}

pub export fn ioFileRead(buffer: ?*anyopaque, size: u32) callconv(.c) u32 {
    if (io_file_handle) |f| {
        return @intCast(fread(buffer, 1, size, f));
    }
    return 0;
}

pub export fn ioFileSeek(position: u32) callconv(.c) void {
    if (io_file_handle) |f| {
        _ = fseek(f, @intCast(position), 0);
    }
}

pub export fn ioFileClose() callconv(.c) void {
    if (io_file_handle) |f| {
        _ = fclose(f);
        io_file_handle = null;
    }
}

pub export fn ioEof() callconv(.c) c_int {
    if (io_file_handle) |f| {
        return feof(f);
    }
    return 1;
}

pub export fn ioFileRemove(path: c_int, error_number: ?*u32) callconv(.c) c_int {
    var filename: [400]u8 = [_]u8{0} ** 400;
    const ret = _ioFileNameFromFilePath(path, &filename);
    if (ret != FILE_OK) return ret;

    const result = remove(&filename);
    if (result == -1 and error_number != null) {
        error_number.?.* = @intCast(std.c._errno().*);
    }
    return if (result != -1) FILE_OK else FILE_ERROR;
}

pub export fn show_warning(string: [*c]u8) callconv(.c) void {
    const dialog = gtk_message_dialog_new(
        @ptrCast(base_dir_owned.parentWindow()),
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

pub export fn fnDiskInfo(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
}
