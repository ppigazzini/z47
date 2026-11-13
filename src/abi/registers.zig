// SPDX-License-Identifier: GPL-3.0-only
//
// Typed register-data accessors. registers.h reinterprets a register's data block
// as a real34 / complex34 / matrix header / short-integer / string; each view here
// is that reinterpretation, over the shared abi layout types, so owners never
// reach the block untyped.
//
// A data block is C47 pool memory, which the allocator hands out in 4-byte
// blocks, so getRegisterDataPointer is declared 4-aligned and every view below
// keeps that alignment in its type: std.mem.bytesAsValue and bytesAsSlice check
// the size at compile time and carry the alignment of the bytes they view.
//
// The extern binding of getRegisterDataPointer lives in this file (an approved
// check-zig-c-boundaries boundary) rather than the pure-layout types.zig;
// types.zig re-exports these accessors by name so owners reach them as
// abi.registerReal34(...). The inline fns codegen only where used.

const std = @import("std");
const types = @import("primitives.zig");
const Real34 = types.Real34;
const Complex34 = types.Complex34;
const MatrixHeader = types.MatrixHeader;
const DtConfigDescriptor = types.DtConfigDescriptor;
const StrLgIntHeader = types.StrLgIntHeader;

/// The C `void *getRegisterDataPointer(calcRegister_t)`, read as the pool bytes
/// it points at.
pub extern fn getRegisterDataPointer(reg: i16) callconv(.c) ?[*]align(4) u8;

// registers.c's queries over a register's type, tag and matrix header, declared
// once for every object that calls them.
pub extern fn copyRegisterStringTo(dest: [*c]u8, regist: i16) void;
pub extern fn isRegisterMatrix3dVector(regist: i16) bool;
pub extern fn isRegisterMatrix2dVector(regist: i16) bool;
pub extern fn isRegisterMatrixVector(regist: i16) bool;
pub extern fn getVectorRegisterPolarMode(regist: i16) u32;
pub extern fn setVectorRegisterPolarMode(regist: i16, polarMode: u32) void;
pub extern fn registerIsNoAngle(regist: i16) bool;
pub extern fn isXFNregisterValid3r(regist: i16) bool;

/// A register's data block: asserts the register has one.
inline fn block(reg: i16) [*]align(4) u8 {
    return getRegisterDataPointer(reg).?;
}

/// The `T` stored `offset` bytes into a register's data block.
inline fn blockValue(comptime T: type, reg: i16, comptime offset: usize) *align(4) T {
    return std.mem.bytesAsValue(T, block(reg)[offset..][0..@sizeOf(T)]);
}

pub inline fn registerReal34(reg: i16) *Real34 {
    return blockValue(Real34, reg, 0);
}
pub inline fn registerImag34(reg: i16) *Real34 {
    return blockValue(Real34, reg, @sizeOf(Real34));
}
pub inline fn registerComplex34(reg: i16) *Complex34 {
    return blockValue(Complex34, reg, 0);
}
/// c43 reads this payload as `(uint64_t *)getRegisterDataPointer(a)`: a 64-bit
/// value at a block address, which is 4-aligned and not necessarily 8-aligned.
pub inline fn registerShortInteger(reg: i16) *align(4) u64 {
    return blockValue(u64, reg, 0);
}
pub inline fn registerString(reg: i16) [*]align(4) u8 {
    return block(reg) + @sizeOf(StrLgIntHeader);
}
/// Raw byte view of a register's data block, for the owners that copy or walk
/// the block themselves.
pub inline fn registerBytes(reg: i16) [*]align(4) u8 {
    return block(reg);
}
/// Config-descriptor view of a register's data block (dtConfigDescriptor_t). Its
/// u64 members want align 8, which a pool block does not guarantee, so the view
/// is align 4 like the block.
pub inline fn registerConfig(reg: i16) *align(4) DtConfigDescriptor {
    return blockValue(DtConfigDescriptor, reg, 0);
}
pub inline fn registerMatrixHeader(reg: i16) *MatrixHeader {
    return blockValue(MatrixHeader, reg, 0);
}

// The pool block is 4-aligned whichever name an owner reaches it by.
pub const registerReal34Aligned = registerReal34;
pub const registerImag34Aligned = registerImag34;
pub const registerComplex34Aligned = registerComplex34;
pub const registerMatrixHeaderAligned = registerMatrixHeader;
pub const registerShortIntegerAligned = registerShortInteger;

/// The first element after a matrix register's header. Its address does not
/// depend on what the header says, so it is right before the header is written.
inline fn firstMatrixElement(comptime T: type, reg: i16) *[1]T {
    return blockValue(T, reg, @sizeOf(MatrixHeader));
}
/// The elements after a matrix register's header, as many as the header says.
pub inline fn registerMatrixElements(comptime T: type, reg: i16) []T {
    const header = registerMatrixHeader(reg);
    const elements: [*]T = firstMatrixElement(T, reg);
    return elements[0 .. @as(usize, header.matrixRows) * header.matrixColumns];
}
pub inline fn registerReal34MatrixElements(reg: i16) [*]Real34 {
    return firstMatrixElement(Real34, reg);
}
pub inline fn registerComplex34MatrixElements(reg: i16) [*]Complex34 {
    return firstMatrixElement(Complex34, reg);
}

// Matrix element views: reinterpret a matrix header's `.matrixElements`
// buffer as its typed element array -- the C `real34_t */complex34_t *
// matrixElements` union field. Takes the header struct by `anytype` so it serves
// both real34Matrix_t and complex34Matrix_t (each has a `.matrixElements`); these
// replace the identical realElems/complexElems quartet reimplemented per matrix
// owner.
//
// The unit harness surface declares `.matrixElements` as an inline array rather
// than a pointer; the element view is then the array itself, so an owner reads
// its matrices the same way on both surfaces.
inline fn elementsAreInline(comptime Matrix: type) bool {
    const Child = switch (@typeInfo(Matrix)) {
        .pointer => |info| info.child,
        else => Matrix,
    };
    return @typeInfo(@FieldType(Child, "matrixElements")) == .array;
}
pub inline fn matrixRealElems(matrix: anytype) [*]Real34 {
    if (comptime elementsAreInline(@TypeOf(matrix))) return &matrix.matrixElements;
    return matrix.matrixElements;
}
pub inline fn matrixConstRealElems(matrix: anytype) [*]const Real34 {
    if (comptime elementsAreInline(@TypeOf(matrix))) return &matrix.matrixElements;
    return matrix.matrixElements;
}
pub inline fn matrixComplexElems(matrix: anytype) [*]Complex34 {
    if (comptime elementsAreInline(@TypeOf(matrix))) return &matrix.matrixElements;
    return matrix.matrixElements;
}
pub inline fn matrixConstComplexElems(matrix: anytype) [*]const Complex34 {
    if (comptime elementsAreInline(@TypeOf(matrix))) return &matrix.matrixElements;
    return @ptrCast(matrix.matrixElements);
}
/// Whether a matrix has element storage: false after a failed allocation, the
/// C `matrix.matrixElements != NULL`. Inline storage always has it.
pub inline fn matrixHasElements(matrix: anytype) bool {
    if (comptime elementsAreInline(@TypeOf(matrix))) return true;
    return matrix.matrixElements != null;
}
