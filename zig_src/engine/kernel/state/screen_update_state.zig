// SPDX-License-Identifier: GPL-3.0-only
//
// screenUpdatingMode: the display-refresh mode word (SCRUPD_AUTO,
// SCRUPD_MANUAL_MENU, the SKIP_STATUSBAR / one-time flags, ...). The headless
// engine read-modify-writes it in 128 sites (|=, &= ~ over the SCRUPD_* masks)
// to control when and how much of the screen is redrawn during a computation,
// so it is core-owned mode state, not a one-way UI directive. It was declared in
// the shell globals hub as a legacy of the C-to-Zig conversion; it belongs in
// the base kernel, where the engine's mask edits become intra-core and the
// shell's own reads become a downstream shell->core dependency.
//
// Plain state relocation with no ABI cost: the symbol, u8 type and
// zero-initialiser are unchanged, so every extern consumer resolves as before.

pub export var screenUpdatingMode: u8 = 0;
