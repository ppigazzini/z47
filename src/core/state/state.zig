// SPDX-License-Identifier: GPL-3.0-only
//
// Root of the calculator's scalar-state module: the leaf contexts (base/), the
// scalar state owners (scalars/) and the register value conversions (value/).
//
// Its only job is to force those owners into the object that imports this module.
// They are `pub export` definitions that every other owner reaches by extern, so
// nothing imports them by path and nothing would otherwise pull them into a
// compilation.
//
// This root exists so that no unrelated subsystem has to carry them. The calc-state
// (persistence) owner was previously conscripted as their compilation carrier,
// which pinned persistence to this directory: moving it dropped twelve owners out
// of every build. Importing this module by NAME is directory-free, so the owners
// and their consumers can each live where they belong.
comptime {
    _ = @import("base/byte_copy.zig");
    _ = @import("base/decimal_context.zig");
    _ = @import("base/error_report.zig");
    _ = @import("base/solver_context.zig");
    _ = @import("scalars/app_state.zig");
    _ = @import("scalars/calc_mode_state.zig");
    _ = @import("scalars/display_state.zig");
    _ = @import("scalars/keyboard_input_state.zig");
    _ = @import("scalars/memory_state.zig");
    _ = @import("scalars/program_state.zig");
    _ = @import("value/real_special_values.zig");
    _ = @import("value/register_conversions.zig");
}
