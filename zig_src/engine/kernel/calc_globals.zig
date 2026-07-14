// SPDX-License-Identifier: GPL-3.0-only
//
// Base calculator globals: shared app/execution state the headless engine reads
// and writes. Ownership, not display intent, decides the home: a symbol the
// engine reads for its own control flow is core state, even when the shell also
// reads it to render -- so the status/mode words that were once thought of as
// "display directives" (temporaryInformation, screenUpdatingMode) live in the
// kernel too. These were all defined in the shell globals hub (c47.zig); they
// belong in the base kernel so the engine does not reach up into shell. Symbols,
// types and zero-init are unchanged, so every extern consumer resolves as before.

const angularMode_t = c_int;

pub export var currentKeyCode: u8 = 0; // last key code; the engine polls it for R/S/EXIT during long ops
pub export var numberOfLabels: u16 = 0; // count of program labels
pub export var dynamicMenuItem: i16 = 0; // current dynamic soft-menu item; the engine sets -1 to disable menu-driven behaviour
pub export var programRunStop: u8 = 0; // program run/stop status; polled across the long-computation loops
pub export var currentAngularMode: angularMode_t = 0; // active angular mode (amNone/amDegree/...); read across trig
pub export var lastIntegerBase: u32 = 0; // last integer base (2..16); read by the shortint/base ops
pub export var numberOfNamedVariables: u16 = 0; // count of user named variables; the named-variable model
pub export var denMax: u32 = 0; // max denominator for fraction display; read by the fraction formatter
pub export var lastDenominator: u32 = 4; // last fraction denominator used; read by the fraction math
pub export var firstGregorianDay: u32 = 0; // Gregorian calendar epoch; read by the date functions
pub export var lastCenturyHighUsed: u16 = 0; // two-digit-year century pivot; read by the date parser
pub export var calcMode: u8 = 0; // the calculator mode (CM_NORMAL/CM_BUG_ON_SCREEN/...); read across the engine (166 sites)
pub export var shortIntegerMode: u8 = 0; // short-integer sign mode (2's complement/...); read by the integer ops
pub export var shortIntegerMask: u64 = 0; // word-size mask derived from the mode; read by the integer ops
pub export var shortIntegerSignBit: u64 = 0; // sign-bit mask derived from the mode; read by the integer ops
