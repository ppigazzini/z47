// SPDX-License-Identifier: GPL-3.0-only
//
// Host GTK label/text helpers ported from src/c47-gtk/gtkGui.c. Starts with the
// pure UTF-8 validator used by the button-label consistency diagnostics; this
// owner is the intended home for the rest of the label-rendering cluster.

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
