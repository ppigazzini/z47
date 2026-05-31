const gtk_decls = @import("gtk_gui_host_decls.zig");
const GtkWidget = gtk_decls.GtkWidget;
const gtk_window_new = gtk_decls.gtk_window_new;
const gtk_window_set_default_size = gtk_decls.gtk_window_set_default_size;
const gtk_window_set_decorated = gtk_decls.gtk_window_set_decorated;
const gtk_window_set_position = gtk_decls.gtk_window_set_position;
const gtk_widget_set_name = gtk_decls.gtk_widget_set_name;
const gtk_window_set_resizable = gtk_decls.gtk_window_set_resizable;

const GTK_WINDOW_TOPLEVEL: c_int = 0;
const GTK_WIN_POS_CENTER: c_int = 1;
const SCREEN_WIDTH: c_int = 400;
const SCREEN_HEIGHT: c_int = 240;
const BIG_SCREEN_COEF: c_int = 1;

extern var frmCalc: ?*GtkWidget;

pub fn setupShellWindow() void {
    frmCalc = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_default_size(@ptrCast(frmCalc), SCREEN_WIDTH * BIG_SCREEN_COEF, SCREEN_HEIGHT * BIG_SCREEN_COEF);
    gtk_window_set_decorated(@ptrCast(frmCalc), 0);
    gtk_window_set_position(@ptrCast(frmCalc), GTK_WIN_POS_CENTER);

    gtk_widget_set_name(frmCalc, "mainWindow");
    gtk_window_set_resizable(@ptrCast(frmCalc), 0);
}
