const startup_settle_owned = @import("gtk_gui_startup_settle_owned.zig");

extern fn gtk_init(argc: *c_int, argv: [*]?[*:0]u8) void;
extern fn setupUI() void;

pub fn startupInitUi(argc: *c_int, argv: [*]?[*:0]u8) void {
    gtk_init(argc, argv);
    setupUI();

    // Keep the legacy settle pass that aligns shifted labels before restore.
    startup_settle_owned.settleUiModePass();
}
