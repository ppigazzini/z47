const setup_preamble_owned = @import("gtk_gui_setup_preamble_owned.zig");
const startup_owned = @import("gtk_gui_startup_owned.zig");
const shell_owned = @import("gtk_gui_shell_owned.zig");

pub fn setupUiPreamble() void {
    setup_preamble_owned.setupUiPreamble();
}

pub fn setupUiNoKeyboardShell() void {
    shell_owned.setupUiNoKeyboardShell();
}

pub fn startupInitUi(argc: *c_int, argv: [*]?[*:0]u8) void {
    startup_owned.startupInitUi(argc, argv);
}

pub fn startupEnterMainloop() void {
    startup_owned.startupEnterMainloop();
}
