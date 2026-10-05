//! The panic namespace the load-path object roots install, so that raising
//! `@setRuntimeSafety(true)` over an untrusted parse costs the firmware almost
//! nothing.
//!
//! Zig's default handler formats its message -- "index out of bounds: 5 >= 4" --
//! through `std.Io.Writer` before trapping. That is the right behaviour on the
//! host, where the message and the stack trace are the whole point of a safety
//! check firing in a test. On the DMCP firmware there is nowhere to print it: the
//! formatting machinery measured **~710 bytes of flash** on this target and
//! pulled in `__aeabi_memcpy` / `__aeabi_memset` as new link dependencies, to
//! buy a string no one can read. Trapping directly costs neither.
//!
//! What the checks actually buy is narrower than "the parse is now bounds
//! checked", and the number says so: covering 19 load-path functions emitted
//! **4 trap sites** and cost **64 bytes** of flash in total. Almost every access
//! on that path goes through a many-item C pointer, which carries no length, so
//! there is no bound for a check to test -- what safety catches here is the
//! INTEGER class:
//! overflowing arithmetic and out-of-range `@intCast`. That is not a
//! consolation prize. It is precisely the class of the three bugs the M1 fuzz
//! found and of the matrix-capacity defect. The spatial class
//! stays invisible until those regions become slices.
//!
//! So the namespace is chosen by target, not by build mode: freestanding traps,
//! everything else keeps Zig's default handler exactly as if this file did not
//! exist. A safety check that fires on the device becomes a `udf` -- the
//! calculator resets, which is the correct outcome for a state no one can trust,
//! and strictly better than the silent wrong number `small` mode gives.
//!
//! The freestanding branch is `std.debug.no_panic`, whose every handler is a bare
//! `@trap()`. The stdlib keeps that namespace complete for the compiler it ships
//! with, so a handler a later Zig adds is covered without a change here.
//! `std.debug.simple_panic` cannot serve: it writes the message to stderr and does
//! not compile for a target without an OS. `std.debug.FullPanic` cannot either --
//! it formats before calling the handler it is given, which is the cost being
//! avoided.

const std = @import("std");
const builtin = @import("builtin");

/// Install in an object root as `pub const panic = abi.trap_panic.namespace;`.
/// The decl must live in the ROOT source file of the compilation: `std.lang`
/// reads `root.panic`, and a namespace exported from anywhere else is ignored
/// without a diagnostic.
pub const namespace = if (builtin.target.os.tag == .freestanding)
    std.debug.no_panic
else
    std.debug.FullPanic(std.debug.defaultPanic);

test "the hosted branch keeps Zig's default handler" {
    // The point of the target switch: a host test that trips a safety check must
    // still get the message and the stack trace, so the hosted branch has to be
    // the exact default `std.lang.panic` would have selected.
    try std.testing.expect(namespace == std.debug.FullPanic(std.debug.defaultPanic));
}
