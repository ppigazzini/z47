const std = @import("std");
const base_dir_owned = @import("gtk_io_base_dir_owned.zig");
const file_handle_owned = @import("gtk_io_file_handle_owned.zig");
const file_chooser_owned = @import("gtk_io_file_chooser_owned.zig");
const filename_dispatch_owned = @import("gtk_io_filename_dispatch_owned.zig");
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
    return file_chooser_owned.fileSelectionScreen(title, base_dir, ext, disp_save, overwrite_check, data);
}

pub export fn _ioFileNameFromFilePath(path: c_int, filename: [*c]u8) callconv(.c) c_int {
    return filename_dispatch_owned.ioFileNameFromFilePath(path, filename);
}

pub export fn ioFileOpen(path: c_int, mode: c_int) callconv(.c) c_int {
    return file_handle_owned.ioFileOpen(&io_file_handle, path, mode, &fileNameSelected[0]);
}

pub export fn ioFileWrite(buffer: ?*const anyopaque, size: u32) callconv(.c) void {
    file_handle_owned.ioFileWrite(io_file_handle, buffer, size);
}

pub export fn ioFileRead(buffer: ?*anyopaque, size: u32) callconv(.c) u32 {
    return file_handle_owned.ioFileRead(io_file_handle, buffer, size);
}

pub export fn ioFileSeek(position: u32) callconv(.c) void {
    file_handle_owned.ioFileSeek(io_file_handle, position);
}

pub export fn ioFileClose() callconv(.c) void {
    file_handle_owned.ioFileClose(&io_file_handle);
}

pub export fn ioEof() callconv(.c) c_int {
    return file_handle_owned.ioEof(io_file_handle);
}

pub export fn ioFileRemove(path: c_int, error_number: ?*u32) callconv(.c) c_int {
    return file_handle_owned.ioFileRemove(path, error_number);
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
