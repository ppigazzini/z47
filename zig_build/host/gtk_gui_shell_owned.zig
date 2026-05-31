const shell_window_owned = @import("gtk_gui_shell_window_owned.zig");
const shell_event_owned = @import("gtk_gui_shell_event_owned.zig");
const shell_screen_owned = @import("gtk_gui_shell_screen_owned.zig");

pub fn setupUiNoKeyboardShell() void {
    shell_window_owned.setupShellWindow();
    shell_event_owned.wireShellEvents();

    shell_screen_owned.setupShellScreen();
}
