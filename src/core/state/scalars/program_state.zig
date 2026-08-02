// SPDX-License-Identifier: GPL-3.0-only
//
// Program-model state the engine reads while running and editing programs:
// label and named-variable counts, run/stop status, the current program and
// step, and the dynamic soft-menu item.
//
// Base calculator state relocated out of the shell globals hub; symbols, types
// and initialisers are byte-identical, so every extern consumer resolves as before.

pub export var numberOfLabels: u16 = 0; // count of program labels
pub export var programRunStop: u8 = 0; // program run/stop status; polled in the long-computation loops
pub export var numberOfNamedVariables: u16 = 0; // count of user named variables
pub export var currentProgramNumber: u16 = 0; // the current program
pub export var currentLocalStepNumber: u16 = 0; // the current program step
pub export var dynamicMenuItem: i16 = -1; // -1: no dynamic menu item selected; fnGoto and goToGlobalStep divert to a dynamic menu label only when this is >= 0
