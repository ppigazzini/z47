// SPDX-License-Identifier: GPL-3.0-only
//
// Base calculator globals: shared app/execution state the headless engine reads
// and writes, distinct from the DISPLAY-output directives (screenUpdatingMode,
// temporaryInformation) that stay in shell for later callback decoupling. These
// were defined in the shell globals hub (c47.zig); they belong in the base kernel
// so the engine does not reach up into shell. Symbols, types and zero-init are
// unchanged, so every extern consumer resolves as before.

pub export var currentKeyCode: u8 = 0; // last key code; the engine polls it for R/S/EXIT during long ops
pub export var numberOfLabels: u16 = 0; // count of program labels
pub export var dynamicMenuItem: i16 = 0; // current dynamic soft-menu item; the engine sets -1 to disable menu-driven behaviour
