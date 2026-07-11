//! Space-label patch -- the pure core of gtk_gui_label's patchSpaceLabel.
//!
//! A key label that is a lone ASCII space is rendered as the UTF-8 middle-dot
//! sequence so it is visible. It is a pure in-place buffer transform. Lift it
//! here for native coverage -- the GTK label owner otherwise renders widgets.

const std = @import("std");

/// Replace a lone-space (0x20, 0x00) label with the middle-dot glyph sequence.
pub fn patchSpaceLabel(lbl: *[22]u8) void {
    if (lbl[0] == 32 and lbl[1] == 0) {
        lbl[0] = 0xC2;
        lbl[1] = 0xB7;
        lbl[2] = '_';
        lbl[3] = 0xc2;
        lbl[4] = 0xb7;
        lbl[5] = 0;
    }
}

test "a lone space becomes the middle-dot sequence" {
    var lbl: [22]u8 = undefined;
    @memset(&lbl, 0);
    lbl[0] = 32;
    patchSpaceLabel(&lbl);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 0xC2, 0xB7, '_', 0xc2, 0xb7 }, std.mem.sliceTo(&lbl, 0));
}

test "a non-space label is left unchanged" {
    var lbl: [22]u8 = undefined;
    @memset(&lbl, 0);
    lbl[0] = 'A';
    patchSpaceLabel(&lbl);
    try std.testing.expectEqualStrings("A", std.mem.sliceTo(&lbl, 0));
}
