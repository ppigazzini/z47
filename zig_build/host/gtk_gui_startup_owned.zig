extern fn gtk_init(argc: *c_int, argv: [*]?[*:0]u8) void;
extern fn setupUI() void;
extern fn calcModeAimGui() void;
extern fn calcModeNormalGui() void;
extern fn gtk_events_pending() c_int;
extern fn gtk_main_iteration() c_int;
extern fn gtk_main() void;

pub fn startupInitUi(argc: *c_int, argv: [*]?[*:0]u8) void {
    gtk_init(argc, argv);
    setupUI();

    // Keep the legacy settle pass that aligns shifted labels before restore.
    calcModeAimGui();
    while (gtk_events_pending() != 0) {
        _ = gtk_main_iteration();
    }
    calcModeNormalGui();
    while (gtk_events_pending() != 0) {
        _ = gtk_main_iteration();
    }
}

pub fn startupEnterMainloop() void {
    gtk_main();
}
