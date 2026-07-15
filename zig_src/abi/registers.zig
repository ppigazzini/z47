// SPDX-License-Identifier: GPL-3.0-only
//
// Typed register-data accessors. registers.h reinterprets
// a register's data block as a real34 / complex34 / matrix header / short-integer
// / string. Centralizing that reinterpretation here -- one @ptrCast per shape,
// over the shared abi layout types -- replaces the raw per-owner casts of
// getRegisterDataPointer scattered across ~40 owners.
//
// The extern binding of getRegisterDataPointer lives in this file (an approved
// check-zig-c-boundaries boundary) rather than the pure-layout types.zig;
// types.zig re-exports these accessors by name so owners reach them as
// abi.registerReal34(...). The inline fns codegen only where used.

const types = @import("primitives.zig");
const Real34 = types.Real34;
const Complex34 = types.Complex34;
const MatrixHeader = types.MatrixHeader;
const DtConfigDescriptor = types.DtConfigDescriptor;
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
// Raw byte view of a register's data block: the base pointer as bytes, for the
// owners that memcpy / pointer-walk the block or reinterpret it themselves. This
// centralizes the bare `@ptrCast(getRegisterDataPointer(reg).?)` -> [*]u8 that
// was scattered across ~12 owners; coerces to [*c]u8 / [*]const u8 / [*]align(1)
// u8 at the call site.
pub inline fn registerBytes(reg: i16) [*]u8 {
    return @ptrCast(getRegisterDataPointer(reg).?);
}
// Config-descriptor view of a register's data block (dtConfigDescriptor_t). The
// register block is 4-byte aligned, so the view is *align(4) (DtConfigDescriptor
// has u64 members whose natural align-8 the block does not guarantee).
pub inline fn registerConfig(reg: i16) *align(4) DtConfigDescriptor {
    return @ptrCast(@alignCast(getRegisterDataPointer(reg).?));
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
pub inline fn registerComplex34MatrixElements(reg: i16) [*]align(1) Complex34 {
    const base: [*]align(1) u8 = @ptrCast(getRegisterDataPointer(reg).?);
    return @ptrCast(base + @sizeOf(MatrixHeader));
}

// Matrix element views: reinterpret a matrix header's `.matrixElements`
// buffer as its typed element array -- the C `real34_t */complex34_t *
// matrixElements` union field. Takes the header struct by `anytype` so it serves
// both real34Matrix_t and complex34Matrix_t (each has a `.matrixElements`); these
// replace the identical realElems/complexElems quartet reimplemented per matrix
// owner.
pub inline fn matrixRealElems(matrix: anytype) [*]Real34 {
    return @ptrCast(matrix.matrixElements);
}
pub inline fn matrixConstRealElems(matrix: anytype) [*]const Real34 {
    return @ptrCast(matrix.matrixElements);
}
pub inline fn matrixComplexElems(matrix: anytype) [*]Complex34 {
    return @ptrCast(matrix.matrixElements);
}
pub inline fn matrixConstComplexElems(matrix: anytype) [*]const Complex34 {
    return @ptrCast(matrix.matrixElements);
}
