// SPDX-License-Identifier: GPL-3.0-only
//
// Formerly the shell owner for src/c47/realType.c. Its contents -- the real_t
// special-value setters and the real_t <-> integer conversions -- are pure
// numeric primitives with no shell coupling, so they now live in the base kernel
// (engine/kernel/real_special_values.zig and register_real34_convert.zig). This
// module survives only as the re-declaration shim the shell owners reach these
// symbols through; the definitions link from the kernel.

const abi = @import("abi"); // shared ABI bindings
const real_t = abi.Real;

pub extern fn realSetZero(r: *real_t) callconv(.c) void;
pub extern fn realSetOne(r: *real_t) callconv(.c) void;
pub extern fn realSetNaN(r: *real_t) callconv(.c) void;
pub extern fn realSetPlusInfinity(r: *real_t) callconv(.c) void;
pub extern fn realSetMinusInfinity(r: *real_t) callconv(.c) void;

pub extern fn realToInt32C47(r: *const real_t, err: ?*bool) callconv(.c) i32;
pub extern fn realToUint32C47(r: *const real_t, err: ?*bool) callconv(.c) u32;
