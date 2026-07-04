// SPDX-License-Identifier: GPL-3.0-only
//
// L1 typed register-data accessors (M22 / REPORT-23 §5). registers.h reinterprets
// a register's data block as a real34 / complex34 / matrix header / short-integer
// / string. Centralizing that reinterpretation here -- one @ptrCast per shape,
// over the shared abi layout types -- replaces the raw per-owner casts of
// getRegisterDataPointer scattered across ~40 owners.
//
// The extern binding of getRegisterDataPointer lives in this file (an approved
// check-zig-c-boundaries boundary) rather than the pure-layout types.zig;
// types.zig re-exports these accessors by name so owners reach them as
// abi.registerReal34(...). The inline fns codegen only where used.

const types = @import("types.zig");
const Real34 = types.Real34;
const Complex34 = types.Complex34;
const MatrixHeader = types.MatrixHeader;
const StrLgIntHeader = types.StrLgIntHeader;

pub extern fn getRegisterDataPointer(reg: i16) callconv(.c) ?*anyopaque;

pub inline fn registerReal34(reg: i16) *align(1) Real34 {
    return @ptrCast(getRegisterDataPointer(reg).?);
}
pub inline fn registerImag34(reg: i16) *align(1) Real34 {
    const bytes: [*]align(1) u8 = @ptrCast(getRegisterDataPointer(reg).?);
    return @ptrCast(bytes + @sizeOf(Real34));
}
pub inline fn registerComplex34(reg: i16) *align(1) Complex34 {
    return @ptrCast(getRegisterDataPointer(reg).?);
}
pub inline fn registerShortInteger(reg: i16) *align(1) u64 {
    return @ptrCast(getRegisterDataPointer(reg).?);
}
pub inline fn registerString(reg: i16) [*]u8 {
    const bytes: [*]u8 = @ptrCast(getRegisterDataPointer(reg).?);
    return bytes + @sizeOf(StrLgIntHeader);
}
pub inline fn registerMatrixHeader(reg: i16) *align(1) MatrixHeader {
    return @ptrCast(getRegisterDataPointer(reg).?);
}

// Fully-aligned variants: some owners @alignCast the register data pointer to a
// naturally-aligned view instead of the *align(1) one above. Same C symbol, same
// data; the alignment assumption is the owner's (preserved here verbatim).
pub inline fn registerReal34Aligned(reg: i16) *Real34 {
    return @ptrCast(@alignCast(getRegisterDataPointer(reg).?));
}
pub inline fn registerImag34Aligned(reg: i16) *Real34 {
    const bytes: [*]align(1) u8 = @ptrCast(getRegisterDataPointer(reg).?);
    return @ptrCast(@alignCast(bytes + @sizeOf(Real34)));
}
pub inline fn registerComplex34Aligned(reg: i16) *Complex34 {
    return @ptrCast(@alignCast(getRegisterDataPointer(reg).?));
}
pub inline fn registerMatrixHeaderAligned(reg: i16) *MatrixHeader {
    return @ptrCast(@alignCast(getRegisterDataPointer(reg).?));
}
pub inline fn registerShortIntegerAligned(reg: i16) *u64 {
    return @ptrCast(@alignCast(getRegisterDataPointer(reg).?));
}
pub inline fn registerReal34MatrixElements(reg: i16) [*]align(1) Real34 {
    const base: [*]align(1) u8 = @ptrCast(getRegisterDataPointer(reg).?);
    return @ptrCast(base + @sizeOf(MatrixHeader));
}
