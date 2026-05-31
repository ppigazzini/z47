const gtk_decls = @import("gtk_gui_host_decls.zig");
const GtkWidget = gtk_decls.GtkWidget;
const gtk_image_new_from_file = gtk_decls.gtk_image_new_from_file;
const gtk_fixed_put = gtk_decls.gtk_fixed_put;

const USER_R47f_g: u8 = 61;
const USER_R47bk_fg: u8 = 62;
const USER_R47fg_bk: u8 = 63;
const USER_R47fg_g: u8 = 64;
const NARROW_SCREEN: bool = false;

extern var calcModel: u8;
extern var calcLandscape: bool;
extern var modelString: [50]u8;
extern var grid: ?*GtkWidget;
extern var backgroundImage: ?*GtkWidget;

fn isR47FAM() bool {
    return calcModel == USER_R47f_g or calcModel == USER_R47bk_fg or calcModel == USER_R47fg_bk or calcModel == USER_R47fg_g;
}

fn ensureModelString() void {
    if (modelString[0] == 0) {
        const base = if (isR47FAM()) "R47" else "C47";
        var idx: usize = 0;
        modelString[0] = 'r';
        modelString[1] = 'e';
        modelString[2] = 's';
        modelString[3] = '/';
        idx = 4;
        for (base) |ch| {
            modelString[idx] = ch;
            idx += 1;
        }
        if (calcLandscape) {
            const suffix = "short.png";
            for (suffix) |ch| {
                modelString[idx] = ch;
                idx += 1;
            }
        } else {
            const suffix = ".png";
            for (suffix) |ch| {
                modelString[idx] = ch;
                idx += 1;
            }
        }
        modelString[idx] = 0;
    } else {
        const prefix = "res/";
        var idx: usize = 0;
        for (prefix) |ch| {
            modelString[idx] = ch;
            idx += 1;
        }
        for (modelString[0..]) |ch| {
            if (ch == 0) break;
            modelString[idx] = ch;
            idx += 1;
        }
        modelString[idx] = 0;
    }
}

pub fn setupBackgroundImage() void {
    ensureModelString();

    if (!NARROW_SCREEN) {
        backgroundImage = gtk_image_new_from_file(@as([*:0]const u8, @ptrCast(&modelString[0])));
        gtk_fixed_put(@ptrCast(grid), backgroundImage, 0, 0);
    } else {
        backgroundImage = gtk_image_new_from_file("res/dm42l_L1_narrow_screen.png");
        gtk_fixed_put(@ptrCast(grid), backgroundImage, 0, 240);
    }
}
