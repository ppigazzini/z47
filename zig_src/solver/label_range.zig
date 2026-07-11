//! Solver label/register band predicates -- the pure core of solve_runtime's
//! isLabel / isStackRegister / isInvalidVariable / labelToProgram.
//!
//! The solver classifies a target id as a global label, a stack register, or an
//! invalid variable by simple range checks over the address-band constants, and
//! turns a label id into a program index by subtracting the first-label base.
//! These are pure integer predicates. Lift them here for native coverage -- the
//! solver runtime is only reachable through the C oracle.

const std = @import("std");

/// The address-band bounds the predicates test against.
pub const Bands = struct {
    first_label: u16,
    last_label: u16,
    reg_x: i16,
    reg_t: i16,
    invalid_variable: u16,
};

/// Whether `label` is in the global-label band.
pub fn isLabel(b: Bands, label: u16) bool {
    return b.first_label <= label and label <= b.last_label;
}

/// Whether `label` is one of the X..T stack registers.
pub fn isStackRegister(b: Bands, label: u16) bool {
    const l: i16 = @intCast(label);
    return b.reg_x <= l and l <= b.reg_t;
}

/// Whether `variable` is the invalid-variable sentinel.
pub fn isInvalidVariable(b: Bands, variable: u16) bool {
    return variable == b.invalid_variable;
}

/// The program index for a label id.
pub fn labelToProgram(b: Bands, label: u16) u16 {
    return label - b.first_label;
}

const test_bands = Bands{ .first_label = 2200, .last_label = 6999, .reg_x = 100, .reg_t = 103, .invalid_variable = 2199 };

test "isLabel spans the label band inclusively" {
    try std.testing.expect(isLabel(test_bands, 2200));
    try std.testing.expect(isLabel(test_bands, 6999));
    try std.testing.expect(!isLabel(test_bands, 2199));
    try std.testing.expect(!isLabel(test_bands, 7000));
}

test "isStackRegister spans X..T" {
    try std.testing.expect(isStackRegister(test_bands, 100));
    try std.testing.expect(isStackRegister(test_bands, 103));
    try std.testing.expect(!isStackRegister(test_bands, 104));
    try std.testing.expect(!isStackRegister(test_bands, 99));
}

test "isInvalidVariable matches the sentinel and labelToProgram shifts by base" {
    try std.testing.expect(isInvalidVariable(test_bands, 2199));
    try std.testing.expect(!isInvalidVariable(test_bands, 2200));
    try std.testing.expectEqual(@as(u16, 0), labelToProgram(test_bands, 2200));
    try std.testing.expectEqual(@as(u16, 100), labelToProgram(test_bands, 2300));
}
