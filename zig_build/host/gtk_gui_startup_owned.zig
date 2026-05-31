const startup_init_owned = @import("gtk_gui_startup_init_owned.zig");

extern fn gtk_main() void;

pub fn startupInitUi(argc: *c_int, argv: [*]?[*:0]u8) void {
    startup_init_owned.startupInitUi(argc, argv);
}

pub fn startupEnterMainloop() void {
    gtk_main();
}
