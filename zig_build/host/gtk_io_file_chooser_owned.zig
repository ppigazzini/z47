const std = @import("std");
const base_dir_owned = @import("gtk_io_base_dir_owned.zig");

const FILE_ERROR: c_int = 0;
const FILE_OK: c_int = 1;
const FILE_CANCEL: c_int = 2;

const GTK_FILE_CHOOSER_ACTION_OPEN: c_int = 0;
const GTK_FILE_CHOOSER_ACTION_SAVE: c_int = 1;
const GTK_RESPONSE_ACCEPT: c_int = -3;
const DEFAULT_SAVE_NAME_BUFFER_LENGTH: usize = 7 * 11 + 1;

const GtkFileChooserNative = opaque {};
const GtkFileChooser = opaque {};
const GtkFileFilter = opaque {};
const GtkNativeDialog = opaque {};

extern fn strcpy(dest: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strcat(dest: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn g_free(mem: ?*anyopaque) void;
extern fn g_object_unref(object: ?*anyopaque) void;
extern fn gtk_file_chooser_native_new(
    title: [*c]const u8,
    parent: ?*anyopaque,
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
        base_dir_owned.parentWindow(),
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
