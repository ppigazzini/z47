// SPDX-License-Identifier: GPL-3.0-only
//
// Base error state. lastErrorCode is THE error status of the calculator: every
// operation across the engine sets and checks it via `extern var`, and it is
// part of the saved backup. errorMessageRegisterLine is the companion state --
// which register line the pending error message annotates -- set on the normal
// error-report path and part of the saved backup too. Both were defined in the
// shell globals hub (c47.zig), so the headless engine reached up into shell for
// its own error status. The interactive bug-screen DISPLAY stays in
// shell/error.zig; only the state lives here. Symbols, types and zero
// initialisers are unchanged, so every extern consumer resolves as before.

pub export var lastErrorCode: u8 = 0;
pub export var errorMessageRegisterLine: i16 = 0;
