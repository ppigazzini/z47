// SPDX-License-Identifier: GPL-3.0-only
//
// Shared scratch string buffers. tmpString is the calculator's general-purpose
// temporary string workspace, written and read across the engine (number
// formatting, register codecs, program listing). The pointer is core-owned
// workspace the shell allocates real backing for at startup (config.zig); it was
// declared in the shell globals hub only as a legacy of the conversion. The
// symbol, type and null initialiser are unchanged, so every extern consumer
// resolves as before.

pub export var tmpString: ?[*]u8 = null;

// errorMessage is the workspace the error/bug-report paths format diagnostics
// into before display. Same story: core-owned workspace, shell-allocated backing.
pub export var errorMessage: ?[*]u8 = null;
