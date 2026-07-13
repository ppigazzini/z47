// SPDX-License-Identifier: GPL-3.0-only
//
// The shared decNumber working contexts. These are pure decimal-math state --
// the calculator's real_t arithmetic runs against ctxtReal39 (and the 34/51/75
// guard-digit variants) -- consumed by ~36 engine owners via `extern var`. They
// were defined in the shell globals hub (c47.zig); they belong in the base
// kernel so the headless engine does not reach up into shell for them. The
// symbols, types and zero-initialisers are unchanged, so every extern consumer
// resolves exactly as before.

const std = @import("std");
const abi = @import("abi");

const realContext_t = abi.RealContext; // size 28, align 4

pub export var ctxtReal4: realContext_t = std.mem.zeroes(realContext_t);
pub export var ctxtReal34: realContext_t = std.mem.zeroes(realContext_t);
pub export var ctxtReal39: realContext_t = std.mem.zeroes(realContext_t);
pub export var ctxtReal51: realContext_t = std.mem.zeroes(realContext_t);
pub export var ctxtReal75: realContext_t = std.mem.zeroes(realContext_t);
