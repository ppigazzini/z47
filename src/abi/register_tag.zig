// SPDX-License-Identifier: GPL-3.0-only
//
// The register tag and the macros registers.h builds on it (src/c47/registers.h).
//
// The tag is the 9-bit field of registerHeader_t: bits 0-3 hold the angular or
// time mode (amAngleMask), bit 4 the Polar flag (amPolar), and bits 5-8 the
// expFixed nibble that keeps a temporary ENG exponent step on the register. A
// short integer keeps its base and a long integer its sign in the low bits.
//
// These are the tag-to-tag halves of the macros: an owner reads the tag with
// getRegisterTag, passes it through one of these, and writes the result back
// with setRegisterTag. Keeping the bit arithmetic here means a change to the
// layout lands once instead of in every owner that expands a macro.

const std = @import("std");

pub const amAngleMask: u32 = 15;
pub const amPolar: u32 = 16;
pub const amNone: u32 = 5;

// The expFixed nibble holds V in 0..15 and stands for the signed step V - 8:
// V = 0 (step -8) is off and out of range, V = 1..15 is step -7..+7. The shown
// exponent moves by three times the step; the stored value never changes.
pub const EXP_FIELD_SHIFT: u5 = 5;
pub const EXP_FIELD_MASK: u32 = 15 << EXP_FIELD_SHIFT;
pub const EXP_STEP_OFF: i16 = -8;

/// getRegisterExpField: the raw 0..15 nibble, 0 when off.
pub fn expField(tag: u32) u32 {
    return (tag >> EXP_FIELD_SHIFT) & 15;
}

/// getRegisterExpFixed: on when the nibble is not 0.
pub fn expFixed(tag: u32) bool {
    return expField(tag) != 0;
}

/// getRegisterExpStep: the signed step, -8 (EXP_STEP_OFF) when off.
pub fn expStep(tag: u32) i16 {
    return @as(i16, @intCast(expField(tag))) - 8;
}

/// clearRegisterExpFixed: the nibble set to 0, the angle and Polar bits kept.
pub fn withoutExpFixed(tag: u32) u32 {
    return tag & ~EXP_FIELD_MASK;
}

/// setRegisterExpStep: step + 8 stored in the nibble, the angle and Polar bits
/// kept. Only the low four bits of step + 8 are kept, as the C mask does.
pub fn withExpStep(tag: u32, step: i16) u32 {
    const field: u32 = @as(u32, @bitCast(@as(i32, step) + 8)) & 15;
    return (tag & ~EXP_FIELD_MASK) | (field << EXP_FIELD_SHIFT);
}

/// setComplexRegisterAngularMode: the angle replaced, the Polar bit and the
/// expFixed nibble kept. A display-mode change is not an operation, so it does
/// not clear the fixed exponent.
pub fn complexWithAngularMode(tag: u32, am: u32) u32 {
    return (am & amAngleMask) | (tag & (amPolar | EXP_FIELD_MASK));
}

/// setComplexRegisterPolarMode: with the Polar bit of pm clear the angle becomes
/// amNone, with it set the angle is kept; the expFixed nibble is kept either way.
pub fn complexWithPolarMode(tag: u32, pm: u32) u32 {
    const angle: u32 = if ((pm & amPolar) != 0) tag & amAngleMask else amNone;
    return angle | (pm & amPolar) | (tag & EXP_FIELD_MASK);
}

test "the nibble decodes to a signed step and 0 is off" {
    try std.testing.expect(!expFixed(amPolar | 3));
    try std.testing.expectEqual(EXP_STEP_OFF, expStep(amPolar | 3));
    const tag = withExpStep(amPolar | 3, -2);
    try std.testing.expect(expFixed(tag));
    try std.testing.expectEqual(@as(i16, -2), expStep(tag));
    try std.testing.expectEqual(@as(u32, amPolar | 3), tag & (amPolar | amAngleMask));
    try std.testing.expectEqual(@as(u32, amPolar | 3), withoutExpFixed(tag));
    try std.testing.expectEqual(@as(i16, 7), expStep(withExpStep(0, 7)));
    try std.testing.expectEqual(@as(i16, -7), expStep(withExpStep(0, -7)));
}

test "the complex setters keep the expFixed nibble" {
    const tag = withExpStep(amPolar | 2, 1);
    try std.testing.expectEqual(withExpStep(amPolar | 4, 1), complexWithAngularMode(tag, 4));
    try std.testing.expectEqual(withExpStep(amNone, 1), complexWithPolarMode(tag, 0));
    try std.testing.expectEqual(tag, complexWithPolarMode(tag, amPolar));
}
