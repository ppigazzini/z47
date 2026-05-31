const gtk_decls = @import("gtk_gui_host_decls.zig");
const GtkWidget = gtk_decls.GtkWidget;
const gtk_label_new = gtk_decls.gtk_label_new;
const gtk_widget_set_name = gtk_decls.gtk_widget_set_name;
const gtk_widget_set_size_request = gtk_decls.gtk_widget_set_size_request;
const gtk_fixed_put = gtk_decls.gtk_fixed_put;

const calcKey_t = extern struct {
    keyId: i16,
    primary: i16,
    fShifted: i16,
    gShifted: i16,
    keyLblAim: i16,
    primaryAim: i16,
    fShiftedAim: i16,
    gShiftedAim: i16,
    primaryTam: i16,
};

const ITM_SHIFTf: i16 = 1731;
const ITM_SHIFTg: i16 = 1732;
const DELTA_KEYS_X: c_int = 78;

extern var grid: ?*GtkWidget;
extern var lblFKey2: ?*GtkWidget;
extern var lblGKey2: ?*GtkWidget;
extern var kbd_usr: [37]calcKey_t;

pub fn setupSoftkeyLabels() void {
    lblFKey2 = gtk_label_new("");
    gtk_widget_set_name(lblFKey2, "fSoftkeyArea");
    if (kbd_usr[10].primary == ITM_SHIFTf) {
        gtk_widget_set_size_request(lblFKey2, 61 - 8 - 2 - 2, 5 - 2);
        gtk_fixed_put(@ptrCast(grid), lblFKey2, 350 + 4 + 2, 563 - 1);
    }

    lblGKey2 = gtk_label_new("");
    gtk_widget_set_name(lblGKey2, "gSoftkeyArea");
    if (kbd_usr[11].primary == ITM_SHIFTg) {
        gtk_widget_set_size_request(lblGKey2, 61 - 8 - 2 - 2, 5 - 2);
        gtk_fixed_put(@ptrCast(grid), lblGKey2, 350 + 4 + 2 + DELTA_KEYS_X, 563 - 1);
    }
}
