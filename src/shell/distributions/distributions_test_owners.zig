// SPDX-License-Identifier: GPL-3.0-only
//
// Aggregator root for the distributions parity harness. It re-exports the four
// owners that harness drives through a single module so the driver can import
// them without a file belonging to two Zig modules; the other twelve owners are
// covered by the c43 testSuite alone. This file is referenced only by the
// `distribution_parity` build step; the product build reaches the owners through
// frontier.zig and never imports this aggregator.

pub const exponential = @import("exponential.zig");
pub const pareto = @import("pareto.zig");
pub const uniform = @import("uniform.zig");
pub const gev = @import("gev.zig");
