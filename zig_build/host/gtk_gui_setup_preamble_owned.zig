const setup_background_owned = @import("gtk_gui_setup_background_owned.zig");
const setup_window_owned = @import("gtk_gui_setup_window_owned.zig");
const setup_softkey_owned = @import("gtk_gui_setup_softkey_owned.zig");
const setup_screen_owned = @import("gtk_gui_setup_screen_owned.zig");
fn configureWindowLayout() void {
    setup_window_owned.configureWindowLayout();
}

fn setupBackgroundImage() void {
    setup_background_owned.setupBackgroundImage();
}

fn setupSoftkeyLabels() void {
    setup_softkey_owned.setupSoftkeyLabels();
}

fn setupScreenBuffer() void {
    setup_screen_owned.setupScreenBuffer();
}

pub fn setupUiPreamble() void {
    configureWindowLayout();
    setupBackgroundImage();
    setupSoftkeyLabels();
    setupScreenBuffer();
}
