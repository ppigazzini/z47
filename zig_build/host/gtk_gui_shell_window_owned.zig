const GtkWidget = opaque {};

const GTK_WINDOW_TOPLEVEL: c_int = 0;
const GTK_WIN_POS_CENTER: c_int = 1;
const SCREEN_WIDTH: c_int = 400;
const SCREEN_HEIGHT: c_int = 240;
const BIG_SCREEN_COEF: c_int = 1;

extern var frmCalc: ?*GtkWidget;

extern fn gtk_window_new(window_type: c_int) ?*GtkWidget;
extern fn gtk_window_set_default_size(window: ?*GtkWidget, width: c_int, height: c_int) void;
extern fn gtk_window_set_decorated(window: ?*GtkWidget, setting: c_int) void;
extern fn gtk_window_set_position(window: ?*GtkWidget, position: c_int) void;
extern fn gtk_widget_set_name(widget: ?*GtkWidget, name: [*:0]const u8) void;
extern fn gtk_window_set_resizable(window: ?*GtkWidget, resizable: c_int) void;

pub fn setupShellWindow() void {
    frmCalc = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_default_size(@ptrCast(frmCalc), SCREEN_WIDTH * BIG_SCREEN_COEF, SCREEN_HEIGHT * BIG_SCREEN_COEF);
    gtk_window_set_decorated(@ptrCast(frmCalc), 0);
    gtk_window_set_position(@ptrCast(frmCalc), GTK_WIN_POS_CENTER);

    gtk_widget_set_name(frmCalc, "mainWindow");
    gtk_window_set_resizable(@ptrCast(frmCalc), 0);
}
