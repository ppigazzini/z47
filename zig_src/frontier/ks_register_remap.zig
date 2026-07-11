//! KS-code to C register index remap -- the pure core of frontier_lbl_gto_xeq's
//! regKStoC.
//!
//! A program step stores a register as a "KS code" (the DM42 keyboard-scan
//! ordering); translating it to the internal C register index is a piecewise
//! linear remap: the stat/spare band shifts down past the local registers, and
//! the local band shifts up to its C base. It is pure arithmetic over the KS code
//! and the fixed layout constants. Lift it here for native coverage -- the
//! lbl/gto/xeq owner is only reachable through the C oracle.

const std = @import("std");

/// The KS-code register layout bounds.
pub const KsLayout = struct {
    first_stat: i16,
    last_spare: u8,
    first_local_ks: i16,
    last_local_ks: i16,
    num_local: i16,
    first_local: i16,
};

/// Translate a KS-code register `regKS` to its internal C register index.
pub fn regKStoC(regKS: u8, layout: KsLayout) i16 {
    const k: i16 = @intCast(regKS);
    const stat: i16 = if (layout.first_stat <= k and regKS <= layout.last_spare) layout.num_local else 0;
    const local: i16 = if (layout.first_local_ks <= k and k <= layout.last_local_ks) (layout.first_local - layout.first_local_ks) else 0;
    return k - stat + local;
}

const test_layout = KsLayout{
    .first_stat = 211,
    .last_spare = 224,
    .first_local_ks = 112,
    .last_local_ks = 210,
    .num_local = 99,
    .first_local = 7000,
};

fn remap(regKS: u8) i16 {
    return regKStoC(regKS, test_layout);
}

test "global registers map through unchanged" {
    try std.testing.expectEqual(@as(i16, 100), remap(100));
    try std.testing.expectEqual(@as(i16, 111), remap(111));
}

test "the local band shifts up to its C base" {
    try std.testing.expectEqual(@as(i16, 7000), remap(112)); // first local
    try std.testing.expectEqual(@as(i16, 7098), remap(210)); // last local
}

test "the stat/spare band shifts down past the locals" {
    try std.testing.expectEqual(@as(i16, 112), remap(211)); // first stat
    try std.testing.expectEqual(@as(i16, 125), remap(224)); // last spare
}
