// SPDX-License-Identifier: GPL-3.0-only
//
// The base pointers into the calculator's memory model -- core-owned state the
// headless engine reads and writes to reach the RAM image, the named-variable
// table, the statistical sums, the current subroutine level and the program
// memory frontier. They start null and the shell allocates their backing at
// startup; the engine then uses them throughout. They were declared in the shell
// globals hub only as a legacy of the conversion; they belong in the base kernel.
// Symbols, types and null initialisers are unchanged, so every extern consumer
// resolves as before.

pub export var ram: ?[*]u32 = null; // the calculator RAM image
pub export var statisticalSumsPointer: ?*anyopaque = null; // the statistical sums block (real_t*)
pub export var allNamedVariables: ?*anyopaque = null; // the named-variable table
pub export var currentSubroutineLevelData: ?*anyopaque = null; // the active subroutine level
pub export var firstFreeProgramByte: ?[*]u8 = null; // first free byte of program memory
pub export var beginOfProgramMemory: ?[*]u8 = null; // start of program memory
pub export var allFormulae: ?*anyopaque = null; // the equation/formula table
