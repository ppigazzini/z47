extern fn calcModeAimGui() void;
extern fn calcModeNormalGui() void;
extern fn gtk_events_pending() c_int;
extern fn gtk_main_iteration() c_int;

pub fn settleUiModePass() void {
    calcModeAimGui();
    while (gtk_events_pending() != 0) {
        _ = gtk_main_iteration();
    }
    calcModeNormalGui();
    while (gtk_events_pending() != 0) {
        _ = gtk_main_iteration();
    }
}
