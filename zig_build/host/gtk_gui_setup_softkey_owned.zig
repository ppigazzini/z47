const GtkWidget = opaque {};

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

extern fn gtk_label_new(str: [*:0]const u8) ?*GtkWidget;
extern fn gtk_widget_set_name(widget: ?*GtkWidget, name: [*:0]const u8) void;
extern fn gtk_widget_set_size_request(widget: ?*GtkWidget, width: c_int, height: c_int) void;
extern fn gtk_fixed_put(fixed: ?*GtkWidget, widget: ?*GtkWidget, x: c_int, y: c_int) void;

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
