// SPDX-License-Identifier: GPL-3.0-only
//
// Host GTK label/text helpers ported from src/c47-gtk/gtkGui.c. Starts with the
// pure UTF-8 validator used by the button-label consistency diagnostics; this
// owner is the intended home for the rest of the label-rendering cluster.

extern fn printf(fmt: [*c]const u8, ...) c_int;
extern fn strcmp(a: [*c]const u8, b: [*c]const u8) c_int;
extern fn stringToUtf8(str: [*c]const u8, utf8: [*c]u8) void;
extern fn gtk_button_set_label(button: ?*anyopaque, label: [*c]const u8) void;
extern fn gtk_widget_set_name(widget: ?*anyopaque, name: [*c]const u8) void;

pub const calcKey_t = extern struct {
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

const item_t = extern struct {
    func: ?*const anyopaque,
    param: u16,
    itemCatalogName: [16]u8,
    itemSoftmenuName: [16]u8,
    tamMinMax: u16,
    status: u16,
};

const indexOfItems = @extern([*c]const item_t, .{ .name = "indexOfItems" });

const ITM_NULL: i16 = 0;
const ITM_SHIFTf: i16 = 1731;
const ITM_SHIFTg: i16 = 1732;
const KEY_fg: i16 = 1893;

/// gtkGui.c labelCaptionTam: renders a key's TAM-mode (prompt) caption onto its
/// button and assigns the CSS name (shift keys, fg, oversized operators).
pub fn labelCaptionTam(key: *const calcKey_t, button: ?*anyopaque) void {
    var lbl: [22]u8 = undefined;
    lbl[0] = 0;
    if (key.primaryTam != ITM_NULL) {
        stringToUtf8(&indexOfItems[@intCast(key.primaryTam)].itemSoftmenuName, &lbl);
    }

    // THIS IS FOR TAM
    gtk_button_set_label(button, &lbl);

    if (strcmp(&lbl, "/") == 0 and key.keyId == 55) { // if "/", re-do to "divide"
        gtk_button_set_label(button, "÷");
    }

    if (key.primaryTam == ITM_SHIFTf) {
        gtk_widget_set_name(button, "calcKeyF");
    } else if (key.primaryTam == ITM_SHIFTg) {
        gtk_widget_set_name(button, "calcKeyG");
    } else if (key.primaryTam == KEY_fg) {
        gtk_widget_set_name(button, "calcKeyFG");
    } else if (strcmp(&lbl, "/") == 0 and key.keyId == 55) {
        gtk_widget_set_name(button, "calcNumericKey");
    } else if (strcmp(&lbl, "×") == 0 and key.keyId == 65) {
        gtk_widget_set_name(button, "calcNumericKey");
    } else if (strcmp(&lbl, "-") == 0 and key.keyId == 75) {
        gtk_widget_set_name(button, "calcNumericKey");
    } else if (strcmp(&lbl, "+") == 0 and key.keyId == 85) {
        gtk_widget_set_name(button, "calcNumericKey");
    } else {
        gtk_widget_set_name(button, "calcKey");
    }
}

/// Hex / printable-char / decimal dump of a label's raw bytes (gtkGui.c
/// print_label_bytes). Used by the UTF-8 consistency diagnostics.
pub fn printLabelBytes(data: [*c]const u8, length: c_int) void {
    var i: c_int = 0;
    while (i < length) : (i += 1) {
        _ = printf("0x%02x ", @as(c_int, data[@intCast(i)]));
    }
    _ = printf("(");
    i = 0;
    while (i < length) : (i += 1) {
        const b = data[@intCast(i)];
        _ = printf("%c", @as(c_int, if (b >= 32 and b < 127) b else '.'));
    }
    _ = printf("  dec: ");
    i = 0;
    while (i < length) : (i += 1) {
        _ = printf("%03d ", @as(c_int, data[@intCast(i)]));
    }
    _ = printf(")\n");
}

/// gtkGui.c check_utf_string: validates a widget string and, on failure, prints
/// the offending widget/field plus a hex dump. Returns true when an issue was
/// found (the caller ORs these into a per-widget consistency flag).
pub fn checkUtfString(widget_name: [*c]const u8, what: [*c]const u8, s: [*c]const u8) bool {
    if (s == null) {
        return false;
    }
    var bad_pos: usize = 0;
    if (!isValidUtf8(s, &bad_pos)) {
        _ = printf("*** UTF-8 ERROR in %s %s at byte offset %zu ***\n", widget_name, what, bad_pos);
        _ = printf("Corrupted string: ");
        var p = s;
        while (p[0] != 0) : (p += 1) {
            _ = printf("\\x%02x", @as(c_int, p[0]));
        }
        _ = printf("\n");
        return true;
    }
    return false;
}

/// gtkGui.c check_label_consistency: warns on NULL or non-UTF-8 button-label
/// text (length-capped at 22) and returns true when an issue was reported.
pub fn checkLabelConsistency(lbl: [*c]const u8, context: [*c]const u8) bool {
    if (lbl == null) {
        _ = printf("GTK3 Setup utf issue: NULL label in %s\n", context);
        return true;
    }

    // Calculate length safely (stop at 22 or null terminator).
    var len: c_int = 0;
    while (lbl[@intCast(len)] != 0 and len < 22) {
        len += 1;
    }

    if (len == 0) {
        return false; // Empty string is OK
    }

    var bad_pos: usize = 0;
    if (!isValidUtf8(lbl, &bad_pos)) {
        _ = printf("GTK3 Setup utf issue: Invalid UTF-8 at position %zu in %s: ", bad_pos, context);
        printLabelBytes(lbl, len);
        return true;
    }

    return false; // All good
}

/// Faithful port of gtkGui.c is_valid_utf8(): validates a NUL-terminated string
/// as well-formed UTF-8, rejecting overlong forms, surrogates, and the U+xxFFFE
/// / U+xxFFFF noncharacters. On the first invalid byte it records that byte
/// offset in error_offset (when non-null) and returns false.
pub fn isValidUtf8(s: [*c]const u8, error_offset: [*c]usize) bool {
    var i: usize = 0;
    while (s[i] != 0) {
        const c0 = s[i];
        if (c0 < 0x80) {
            i += 1;
        } else if ((c0 & 0xE0) == 0xC0) {
            if ((s[i + 1] & 0xC0) != 0x80 or (c0 & 0xFE) == 0xC0) {
                if (error_offset != null) error_offset[0] = i;
                return false;
            }
            i += 2;
        } else if ((c0 & 0xF0) == 0xE0) {
            if ((s[i + 1] & 0xC0) != 0x80 or (s[i + 2] & 0xC0) != 0x80) {
                if (error_offset != null) error_offset[0] = i;
                return false;
            }
            const cp: u32 = (@as(u32, c0 & 0x0F) << 12) |
                (@as(u32, s[i + 1] & 0x3F) << 6) |
                @as(u32, s[i + 2] & 0x3F);
            if (cp < 0x800 or (cp >= 0xD800 and cp <= 0xDFFF)) {
                if (error_offset != null) error_offset[0] = i;
                return false;
            }
            if (cp == 0xFFFE or cp == 0xFFFF) {
                if (error_offset != null) error_offset[0] = i;
                return false;
            }
            i += 3;
        } else if ((c0 & 0xF8) == 0xF0) {
            if ((s[i + 1] & 0xC0) != 0x80 or (s[i + 2] & 0xC0) != 0x80 or (s[i + 3] & 0xC0) != 0x80) {
                if (error_offset != null) error_offset[0] = i;
                return false;
            }
            const cp: u32 = (@as(u32, c0 & 0x07) << 18) |
                (@as(u32, s[i + 1] & 0x3F) << 12) |
                (@as(u32, s[i + 2] & 0x3F) << 6) |
                @as(u32, s[i + 3] & 0x3F);
            if (cp < 0x10000 or cp > 0x10FFFF) {
                if (error_offset != null) error_offset[0] = i;
                return false;
            }
            if ((cp & 0xFFFF) == 0xFFFE or (cp & 0xFFFF) == 0xFFFF) {
                if (error_offset != null) error_offset[0] = i;
                return false;
            }
            i += 4;
        } else {
            if (error_offset != null) error_offset[0] = i;
            return false;
        }
    }
    return true;
}
