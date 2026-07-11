//! Solver equation-mode predicates -- the pure core of keyboard_state_runtime's
//! isEqnIntegrate / isEqn1stDer / isEqn2ndDer.
//!
//! In interactive solver mode the keyboard checks which equation operation is
//! active by masking the solver status word. These are pure bit-mask predicates
//! over the status and the mode constants. Lift them here for native coverage --
//! the keyboard owner is only reachable through the C oracle.

const std = @import("std");

/// The solver-status masks the predicates test against.
pub const SolverMasks = struct {
    eqn_mode: u16,
    interactive: u16,
    uses_formula: u16,
    integrate: u16,
    first_deriv: u16,
    second_deriv: u16,
};

pub fn isEqnIntegrate(status: u16, m: SolverMasks) bool {
    return (status & m.eqn_mode) == m.integrate and (status & m.interactive) != 0;
}

pub fn isEqn1stDer(status: u16, m: SolverMasks) bool {
    return (status & m.uses_formula) != 0 and (status & m.interactive) != 0 and (status & m.eqn_mode) == m.first_deriv;
}

pub fn isEqn2ndDer(status: u16, m: SolverMasks) bool {
    return (status & m.uses_formula) != 0 and (status & m.interactive) != 0 and (status & m.eqn_mode) == m.second_deriv;
}

const test_masks = SolverMasks{
    .eqn_mode = 0x0300,
    .interactive = 0x0400,
    .uses_formula = 0x0800,
    .integrate = 0x0100,
    .first_deriv = 0x0200,
    .second_deriv = 0x0300,
};

test "isEqnIntegrate needs the integrate mode and interactive bit" {
    try std.testing.expect(isEqnIntegrate(0x0100 | 0x0400, test_masks));
    try std.testing.expect(!isEqnIntegrate(0x0100, test_masks)); // not interactive
    try std.testing.expect(!isEqnIntegrate(0x0200 | 0x0400, test_masks)); // wrong mode
}

test "the derivative predicates need the formula and interactive bits" {
    try std.testing.expect(isEqn1stDer(0x0800 | 0x0400 | 0x0200, test_masks));
    try std.testing.expect(!isEqn1stDer(0x0400 | 0x0200, test_masks)); // no formula
    try std.testing.expect(isEqn2ndDer(0x0800 | 0x0400 | 0x0300, test_masks));
    try std.testing.expect(!isEqn2ndDer(0x0800 | 0x0400 | 0x0200, test_masks)); // wrong mode
}
