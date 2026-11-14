// SPDX-License-Identifier: GPL-3.0-only
//! Upstream's complete bodies of the arithmetic, comparison and increment
//! commands: saveLastX, the type dispatch and adjustResult, ported line by line
//! in the owners imported below. Each command's front calls its body for every
//! case it does not handle itself. The parity harness that builds the fronts on
//! the fake surface builds none of these owners, and there each body does
//! nothing.

const runtime = @import("command_wrappers/runtime.zig");

// Each body is declared noinline in its owner: called directly, it would
// otherwise be inlined into its front and leave the section it is placed in,
// which is QSPI on the DM42 packages.

const fake = runtime.harness_surface_is_fake;

const absent = struct {
    pub fn fnAdd(_: u16) void {}
    pub fn fnSubtract(_: u16) void {}
    pub fn fnMultiply(_: u16) void {}
    pub fn fnDivide(_: u16) void {}
    pub fn fnIDiv(_: u16) void {}
    pub fn fnIDivR(_: u16) void {}
    pub fn fnDblMultiply(_: u16) void {}
    pub fn fnDblDivide(_: u16) void {}
    pub fn fnDblDivideRemainder(_: u16) void {}
    pub fn fnRound(_: u16) void {}
    pub fn fnXLessThan(_: u16) void {}
    pub fn fnXLessEqual(_: u16) void {}
    pub fn fnXGreaterThan(_: u16) void {}
    pub fn fnXGreaterEqual(_: u16) void {}
    pub fn fnXEqualsTo(_: u16) void {}
    pub fn fnXNotEqual(_: u16) void {}
    pub fn fnXAlmostEqual(_: u16) void {}
    pub fn fnDec(_: u16) void {}
    pub fn fnInc(_: u16) void {}
};

const addition = if (fake) absent else @import("arithmetic/addition_cells.zig");
const subtraction = if (fake) absent else @import("arithmetic/subtraction_cells.zig");
const multiplication = if (fake) absent else @import("arithmetic/multiplication_cells.zig");
const division = if (fake) absent else @import("arithmetic/division_cells.zig");
const integer_division = if (fake) absent else @import("arithmetic/integer_division_cells.zig");
const register_compare = if (fake) absent else @import("compare/register_compare.zig");

pub const fnAdd = addition.fnAdd;
pub const fnSubtract = subtraction.fnSubtract;
pub const fnMultiply = multiplication.fnMultiply;
pub const fnDivide = division.fnDivide;
pub const fnIDiv = integer_division.fnIDiv;
pub const fnIDivR = integer_division.fnIDivR;
pub const fnDblMultiply = integer_division.fnDblMultiply;
pub const fnDblDivide = integer_division.fnDblDivide;
pub const fnDblDivideRemainder = integer_division.fnDblDivideRemainder;
pub const fnRound = integer_division.fnRound;
pub const fnXLessThan = register_compare.fnXLessThan;
pub const fnXLessEqual = register_compare.fnXLessEqual;
pub const fnXGreaterThan = register_compare.fnXGreaterThan;
pub const fnXGreaterEqual = register_compare.fnXGreaterEqual;
pub const fnXEqualsTo = register_compare.fnXEqualsTo;
pub const fnXNotEqual = register_compare.fnXNotEqual;
pub const fnXAlmostEqual = register_compare.fnXAlmostEqual;
pub const fnDec = register_compare.fnDec;
pub const fnInc = register_compare.fnInc;
