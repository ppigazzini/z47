const base_dir_owned = @import("gtk_io_base_dir_owned.zig");

const GTK_DIALOG_DESTROY_WITH_PARENT: c_int = 1 << 1;
const GTK_MESSAGE_WARNING: c_int = 1;
const GTK_BUTTONS_OK: c_int = 1;

const GtkWidget = opaque {};
const GtkWindow = opaque {};
const GtkDialog = opaque {};

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

pub fn showWarning(string: [*c]u8) void {
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
