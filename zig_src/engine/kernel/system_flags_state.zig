// SPDX-License-Identifier: GPL-3.0-only
//
// The live system-flag words. systemFlags0 and systemFlags1 are the two 64-bit
// bitmaps that back the calculator's system flags (the flags owner reads and
// mutates them across the engine). They are base calculator state -- part of the
// saved backup and read throughout the headless engine -- so they belong in the
// base kernel rather than the shell globals hub they were declared in. The
// symbols, type and zero-initialiser are unchanged, so every extern consumer
// resolves exactly as before.

pub export var systemFlags0: u64 = 0;
pub export var systemFlags1: u64 = 0;
