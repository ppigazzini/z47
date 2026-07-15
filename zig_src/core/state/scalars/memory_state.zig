// SPDX-License-Identifier: GPL-3.0-only
//
// The calculator's memory-model state: the shared scratch string buffers and the
// base pointers into the RAM image, named-variable table, statistical sums,
// subroutine level, program memory and formula table. The headless engine reads
// and writes these throughout; the shell allocates their backing at startup.
// Relocated out of the shell globals hub; symbols, types and null initialisers are
// unchanged, so every extern consumer resolves as before.

pub export var tmpString: ?[*]u8 = null; // general-purpose temporary string workspace
pub export var errorMessage: ?[*]u8 = null; // error/bug-report formatting workspace
pub export var ram: ?[*]u32 = null; // the calculator RAM image
pub export var statisticalSumsPointer: ?*anyopaque = null; // the statistical sums block (real_t*)
pub export var allNamedVariables: ?*anyopaque = null; // the named-variable table
pub export var currentSubroutineLevelData: ?*anyopaque = null; // the active subroutine level
pub export var firstFreeProgramByte: ?[*]u8 = null; // first free byte of program memory
pub export var beginOfProgramMemory: ?[*]u8 = null; // start of program memory
pub export var allFormulae: ?*anyopaque = null; // the equation/formula table
