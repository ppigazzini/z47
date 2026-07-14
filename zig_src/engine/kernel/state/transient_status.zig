// SPDX-License-Identifier: GPL-3.0-only
//
// temporaryInformation: the transient status word (TI_SOLVER_FAILED,
// TI_SHOW_REGISTER, TI_NO_INFO, ...). Despite the "information" name it is not a
// one-way display directive: the headless engine both writes it (141 sites) and
// READS it for control flow (35 sites -- comparisons against the TI_* codes that
// steer keyboard handling, comparison results, the solver), so it is
// core-owned computational state, not a UI callback. It was declared in the
// shell globals hub as a legacy of the C-to-Zig conversion; it belongs in the
// base kernel. The shell reads and writes it too (for the transient display),
// which is a downstream shell->core dependency, the allowed direction.
//
// This is a plain state relocation with no ABI cost: the symbol, u8 type and
// zero-initialiser are unchanged, so every extern consumer resolves as before.

pub export var temporaryInformation: u8 = 0;
