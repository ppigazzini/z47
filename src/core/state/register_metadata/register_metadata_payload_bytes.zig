const std = @import("std");
const abi = @import("abi");

pub const Z47_LOCAL_MATRIX_ROWS_MASK: u32 = 0x00000fff;
pub const Z47_LOCAL_MATRIX_COLUMNS_MASK: u32 = 0x00fff000;
pub const Z47_LOCAL_MATRIX_TAG_MASK: u32 = 0x3f000000;
pub const Z47_LOCAL_MATRIX_ROWS_SHIFT: u5 = 0;
pub const Z47_LOCAL_MATRIX_COLUMNS_SHIFT: u5 = 12;
pub const Z47_LOCAL_MATRIX_TAG_SHIFT: u5 = 24;

pub const strLgIntHeader_t = abi.StrLgIntHeader;

// Only @sizeOf(matrixHeader_t) (== 4) is used here; the raw-u32 mask helpers
// below operate on the serialized bytes directly.
pub const matrixHeader_t = abi.MatrixHeader;

pub fn bytesPerBlock() comptime_int {
    return 4;
}

pub fn toBlocks(bytes: usize) u16 {
    return @intCast((bytes + (bytesPerBlock() - 1)) / bytesPerBlock());
}

pub fn copyBytesToValue(comptime T: type, data_ptr: ?[*]const u8) T {
    const ptr = data_ptr orelse return std.mem.zeroes(T);
    return std.mem.bytesToValue(T, ptr[0..@sizeOf(T)]);
}

pub fn copyValueToBytes(comptime T: type, data_ptr: ?[*]u8, value: *const T) void {
    const ptr = data_ptr orelse return;
    @memcpy(ptr[0..@sizeOf(T)], std.mem.asBytes(value));
}

pub fn readMatrixHeaderDescriptor(data_ptr: ?[*]const u8) u32 {
    return copyBytesToValue(u32, data_ptr);
}

pub fn matrixRows(data_ptr: ?[*]const u8) u16 {
    return @intCast((readMatrixHeaderDescriptor(data_ptr) & Z47_LOCAL_MATRIX_ROWS_MASK) >> Z47_LOCAL_MATRIX_ROWS_SHIFT);
}

pub fn matrixColumns(data_ptr: ?[*]const u8) u16 {
    return @intCast((readMatrixHeaderDescriptor(data_ptr) & Z47_LOCAL_MATRIX_COLUMNS_MASK) >> Z47_LOCAL_MATRIX_COLUMNS_SHIFT);
}

pub fn setMatrixRowsColumns(data_ptr: ?[*]u8, rows: u16, columns: u16) void {
    var descriptor = readMatrixHeaderDescriptor(data_ptr);
    descriptor &= ~(Z47_LOCAL_MATRIX_ROWS_MASK | Z47_LOCAL_MATRIX_COLUMNS_MASK);
    descriptor |= (@as(u32, rows) & 0x0fff) << Z47_LOCAL_MATRIX_ROWS_SHIFT;
    descriptor |= (@as(u32, columns) & 0x0fff) << Z47_LOCAL_MATRIX_COLUMNS_SHIFT;
    copyValueToBytes(u32, data_ptr, &descriptor);
}

pub fn setMatrixTag(data_ptr: ?[*]u8, tag: u16) void {
    var descriptor = readMatrixHeaderDescriptor(data_ptr);
    descriptor &= ~Z47_LOCAL_MATRIX_TAG_MASK;
    descriptor |= (@as(u32, tag) & 0x3f) << Z47_LOCAL_MATRIX_TAG_SHIFT;
    copyValueToBytes(u32, data_ptr, &descriptor);
}

// Native unit tests. Pure byte/bit codec; no C oracle, no
// global state.
const testing = std.testing;

test "toBlocks and byte-value roundtrip" {
    try testing.expectEqual(@as(u16, 0), toBlocks(0));
    try testing.expectEqual(@as(u16, 1), toBlocks(1));
    try testing.expectEqual(@as(u16, 1), toBlocks(4));
    try testing.expectEqual(@as(u16, 2), toBlocks(5));
    try testing.expectEqual(@as(u16, 2), toBlocks(8));
    var buf: u32 = 0;
    const v: u32 = 0xDEADBEEF;
    copyValueToBytes(u32, std.mem.asBytes(&buf), &v);
    try testing.expectEqual(@as(u32, 0xDEADBEEF), copyBytesToValue(u32, std.mem.asBytes(&buf)));
    try testing.expectEqual(@as(u32, 0), copyBytesToValue(u32, null));
}

test "matrix header rows/columns pack-unpack" {
    var desc: u32 = 0xAA000000; // high byte lives outside the row/col fields
    const desc_bytes = std.mem.asBytes(&desc);
    setMatrixRowsColumns(desc_bytes, 3, 5);
    try testing.expectEqual(@as(u16, 3), matrixRows(desc_bytes));
    try testing.expectEqual(@as(u16, 5), matrixColumns(desc_bytes));
    try testing.expectEqual(@as(u32, 0xAA000000), desc & 0xff000000); // preserved
    setMatrixRowsColumns(desc_bytes, 0xFFF, 0xFFF);
    try testing.expectEqual(@as(u16, 0xFFF), matrixRows(desc_bytes));
    try testing.expectEqual(@as(u16, 0xFFF), matrixColumns(desc_bytes));
}
