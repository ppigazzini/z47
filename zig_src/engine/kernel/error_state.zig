// SPDX-License-Identifier: GPL-3.0-only
//
// Base error state. lastErrorCode is THE error status of the calculator: every
// operation across the engine sets and checks it via `extern var`, and it is
// part of the saved backup. It was defined in the shell globals hub (c47.zig),
// so the headless engine reached up into shell for its own error status. This is
// the base half of the error subsystem -- the DISPLAY side (displayCalcErrorMessage,
// displayBugScreen) stays in shell/error.zig. Symbol, type and zero-initialiser
// are unchanged, so every extern consumer resolves as before.

pub export var lastErrorCode: u8 = 0;
