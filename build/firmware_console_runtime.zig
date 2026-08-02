// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

//! Console sinks for the DMCP firmware -- the Zig owner of upstream's
//! src/c47-dmcp/hal/console.c and src/c47-dmcp5/hal/console.c.
//!
//! There is no console on DMCP hardware, so every console entry point discards
//! its output. Defining them here is not cosmetic: it is what keeps newlib's
//! buffered stdio out of the link. Left undefined, the linker resolves
//! printf/puts/fputs/... against libc_nano and pulls in findfp.o, whose __sf
//! array of FILE structs is 316 bytes of SRAM2 -- and on the DM42 (OLD_HW)
//! .data + .bss share only the 8Kb below the DMCP system data block at
//! 0x10002000, a bound stm32_program.ld asserts on _ebss. Defining them also
//! intercepts printing from inside the libraries (gmp, assert).
//!
//! sprintf/snprintf are deliberately NOT defined: they format into a caller's
//! buffer without touching FILE machinery, and the calculator relies on
//! newlib's string formatter for them.
//!
//! `exit` is the subtle one, and upstream added it in the 4697e526a resync with
//! the note "newlib's exit references __stdio_exit_handler, which links
//! findfp.o and its 312 byte __sf FILE array into SRAM2". Overriding exit is
//! what actually keeps findfp out; stubbing the printers alone is not enough.
//! Upstream applies it only to the DM42 copy (the DMCP5 has RAM to spare), but
//! there is nothing to return to on either board once the program calls exit,
//! so parking the CPU is correct for both and costs a handful of bytes.

const std = @import("std");

/// Opaque stand-in for newlib's FILE. The stubs never dereference it; it exists
/// so the exported signatures match the ones the C library and callers expect.
const FILE = anyopaque;

/// Opaque stand-in for newlib's `struct _reent` (the re-entrancy context that
/// the _r-suffixed entry points take as their first argument).
const reent = anyopaque;

pub export fn printf(format: [*c]const u8, ...) callconv(.c) c_int {
    _ = format;
    return 0;
}

// newlib-nano rewrites printf to iprintf for integer-only formats, so the
// integer variants need sinks of their own or the rewrite reaches libc_nano.
pub export fn iprintf(format: [*c]const u8, ...) callconv(.c) c_int {
    _ = format;
    return 0;
}

pub export fn puts(s: [*c]const u8) callconv(.c) c_int {
    _ = s;
    return 0;
}

pub export fn putchar(c: c_int) callconv(.c) c_int {
    return c;
}

pub export fn fputs(s: [*c]const u8, stream: ?*FILE) callconv(.c) c_int {
    _ = s;
    _ = stream;
    return 0;
}

pub export fn fputc(c: c_int, stream: ?*FILE) callconv(.c) c_int {
    _ = stream;
    return c;
}

pub export fn fprintf(stream: ?*FILE, format: [*c]const u8, ...) callconv(.c) c_int {
    _ = stream;
    _ = format;
    return 0;
}

pub export fn fiprintf(stream: ?*FILE, format: [*c]const u8, ...) callconv(.c) c_int {
    _ = stream;
    _ = format;
    return 0;
}

pub export fn fflush(stream: ?*FILE) callconv(.c) c_int {
    _ = stream;
    return 0;
}

pub export fn _fflush_r(r: ?*reent, stream: ?*FILE) callconv(.c) c_int {
    _ = r;
    _ = stream;
    return 0;
}

pub export fn exit(status: c_int) callconv(.c) noreturn {
    _ = status;
    while (true) {}
}
