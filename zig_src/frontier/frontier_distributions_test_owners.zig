// SPDX-License-Identifier: GPL-3.0-only
//
// Aggregator root for the distributions parity harness. It re-exports every
// ported distribution owner through a single module so the harness driver can
// import them all without a file belonging to two Zig modules. This file is
// referenced only by the `distribution_parity` build step; the product build
// reaches the owners through frontier.zig and never imports this aggregator.

pub const exponential = @import("frontier_exponential_owned.zig");
pub const pareto = @import("frontier_pareto_owned.zig");
pub const uniform = @import("frontier_uniform_owned.zig");
pub const gev = @import("frontier_gev_owned.zig");
