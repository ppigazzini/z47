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
//! found and of the matrix-capacity defect M-SAFE-1 fixed. The spatial class
//! stays invisible until those regions become slices.
//!
//! So the namespace is chosen by target, not by build mode: freestanding traps,
//! everything else keeps Zig's default handler exactly as if this file did not
//! exist. A safety check that fires on the device becomes a `udf` -- the
//! calculator resets, which is the correct outcome for a state no one can trust,
//! and strictly better than the silent wrong number `ReleaseSmall` gives today.
//!
//! `std.debug.simple_panic` cannot serve as the freestanding branch: it writes
//! the message to stderr and does not compile for a target without an OS.
//! `std.debug.FullPanic` cannot either -- it formats before calling the handler
//! it is given, which is the cost being avoided.

const std = @import("std");
const builtin = @import("builtin");

/// Install in an object root as `pub const panic = abi.trap_panic.namespace;`.
/// The decl must live in the ROOT source file of the compilation: `std.builtin`
/// reads `root.panic`, and a namespace exported from anywhere else is ignored
/// without a diagnostic.
pub const namespace = if (builtin.target.os.tag == .freestanding)
    Trap
else
    std.debug.FullPanic(std.debug.defaultPanic);

/// Every safety failure traps with no message and no writer. The decl set
/// mirrors `std.debug.simple_panic`; a missing one is a compile error at the
/// site the compiler tries to lower, so this list must stay complete.
const Trap = struct {
    pub fn call(_: []const u8, _: ?usize) noreturn {
        @branchHint(.cold);
        @trap();
    }
    pub fn sentinelMismatch(expected: anytype, found: @TypeOf(expected)) noreturn {
        _ = .{ expected, found };
        @trap();
    }
    pub fn unwrapError(err: anyerror) noreturn {
        _ = &err;
        @trap();
    }
    pub fn outOfBounds(index: usize, len: usize) noreturn {
        _ = .{ index, len };
        @trap();
    }
    pub fn startGreaterThanEnd(start: usize, end: usize) noreturn {
        _ = .{ start, end };
        @trap();
    }
    pub fn inactiveUnionField(active: anytype, accessed: @TypeOf(active)) noreturn {
        _ = .{ active, accessed };
        @trap();
    }
    pub fn sliceCastLenRemainder(src_len: usize) noreturn {
        _ = src_len;
        @trap();
    }
    pub fn reachedUnreachable() noreturn {
        @trap();
    }
    pub fn unwrapNull() noreturn {
        @trap();
    }
    pub fn castToNull() noreturn {
        @trap();
    }
    pub fn incorrectAlignment() noreturn {
        @trap();
    }
    pub fn invalidErrorCode() noreturn {
        @trap();
    }
    pub fn integerOutOfBounds() noreturn {
        @trap();
    }
    pub fn integerOverflow() noreturn {
        @trap();
    }
    pub fn shlOverflow() noreturn {
        @trap();
    }
    pub fn shrOverflow() noreturn {
        @trap();
    }
    pub fn divideByZero() noreturn {
        @trap();
    }
    pub fn exactDivisionRemainder() noreturn {
        @trap();
    }
    pub fn integerPartOutOfBounds() noreturn {
        @trap();
    }
    pub fn corruptSwitch() noreturn {
        @trap();
    }
    pub fn shiftRhsTooBig() noreturn {
        @trap();
    }
    pub fn invalidEnumValue() noreturn {
        @trap();
    }
    pub fn forLenMismatch() noreturn {
        @trap();
    }
    pub fn copyLenMismatch() noreturn {
        @trap();
    }
    pub fn memcpyAlias() noreturn {
        @trap();
    }
    pub fn noreturnReturned() noreturn {
        @trap();
    }
};

test "the hosted branch keeps Zig's default handler" {
    // The point of the target switch: a host test that trips a safety check must
    // still get the message and the stack trace, so the hosted branch has to be
    // the exact default `std.builtin.panic` would have selected.
    try std.testing.expect(namespace == std.debug.FullPanic(std.debug.defaultPanic));
}

/// Every handler `std.builtin.panic` can dispatch to. Spelled out rather than
/// reflected: `@typeInfo(...).@"struct".decls` reads the set on Zig 0.16 but the
/// field is gone on 0.17, and a version guard is not an option here. The list is
/// therefore the contract, and the test below holds it against the stdlib's own
/// reference implementation in both directions so neither can drift silently.
const handler_names = [_][:0]const u8{
    "call",                   "sentinelMismatch",    "unwrapError",
    "outOfBounds",            "startGreaterThanEnd", "inactiveUnionField",
    "sliceCastLenRemainder",  "reachedUnreachable",  "unwrapNull",
    "castToNull",             "incorrectAlignment",  "invalidErrorCode",
    "integerOutOfBounds",     "integerOverflow",     "shlOverflow",
    "shrOverflow",            "divideByZero",        "exactDivisionRemainder",
    "integerPartOutOfBounds", "corruptSwitch",       "shiftRhsTooBig",
    "invalidEnumValue",       "forLenMismatch",      "copyLenMismatch",
    "memcpyAlias",            "noreturnReturned",
};

test "the freestanding branch declares every handler the compiler can call" {
    // A missing decl only fails where some lowering reaches for it -- possibly a
    // different target, possibly a later Zig -- so catch a gap here instead.
    inline for (handler_names) |name| {
        try std.testing.expect(@hasDecl(Trap, name));
        // ...and the name is one the stdlib's reference handler still declares,
        // so a rename upstream fails this test rather than silently leaving Trap
        // with a handler the compiler no longer calls.
        try std.testing.expect(@hasDecl(std.debug.simple_panic, name));
    }
}
