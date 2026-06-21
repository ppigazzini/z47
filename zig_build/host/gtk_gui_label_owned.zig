// SPDX-License-Identifier: GPL-3.0-only
//
// Host GTK label/text helpers ported from src/c47-gtk/gtkGui.c. Starts with the
// pure UTF-8 validator used by the button-label consistency diagnostics; this
// owner is the intended home for the rest of the label-rendering cluster.

extern fn printf(fmt: [*c]const u8, ...) c_int;

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
