const std = @import("std");

pub const Z47_LOCAL_MATRIX_ROWS_MASK: u32 = 0x00000fff;
pub const Z47_LOCAL_MATRIX_COLUMNS_MASK: u32 = 0x00fff000;
pub const Z47_LOCAL_MATRIX_ROWS_SHIFT: u5 = 0;
pub const Z47_LOCAL_MATRIX_COLUMNS_SHIFT: u5 = 12;

pub const strLgIntHeader_t = extern struct {
    dataMaxLengthInBlocks: u16,
    unused: u16,
};

pub const matrixHeader_t = extern struct {
    descriptor: u32,
};

pub fn bytesPerBlock() comptime_int {
    return 4;
}

pub fn toBlocks(bytes: usize) u16 {
    return @intCast((bytes + (bytesPerBlock() - 1)) / bytesPerBlock());
}

pub fn copyBytesToValue(comptime T: type, data_ptr: ?*const anyopaque) T {
    var value = std.mem.zeroes(T);
    const ptr = data_ptr orelse return value;
    const src: [*]const u8 = @ptrCast(ptr);
    const dst: [*]u8 = @ptrCast(&value);
    @memcpy(dst[0..@sizeOf(T)], src[0..@sizeOf(T)]);
    return value;
}

pub fn copyValueToBytes(comptime T: type, data_ptr: ?*anyopaque, value: *const T) void {
    const ptr = data_ptr orelse return;
    const src: [*]const u8 = @ptrCast(value);
    const dst: [*]u8 = @ptrCast(ptr);
    @memcpy(dst[0..@sizeOf(T)], src[0..@sizeOf(T)]);
}

pub fn readMatrixHeaderDescriptor(data_ptr: ?*const anyopaque) u32 {
    return copyBytesToValue(u32, data_ptr);
}

pub fn matrixRows(data_ptr: ?*const anyopaque) u16 {
    return @intCast((readMatrixHeaderDescriptor(data_ptr) & Z47_LOCAL_MATRIX_ROWS_MASK) >> Z47_LOCAL_MATRIX_ROWS_SHIFT);
}

pub fn matrixColumns(data_ptr: ?*const anyopaque) u16 {
    return @intCast((readMatrixHeaderDescriptor(data_ptr) & Z47_LOCAL_MATRIX_COLUMNS_MASK) >> Z47_LOCAL_MATRIX_COLUMNS_SHIFT);
}

pub fn setMatrixRowsColumns(data_ptr: ?*anyopaque, rows: u16, columns: u16) void {
    var descriptor = readMatrixHeaderDescriptor(data_ptr);
    descriptor &= ~(Z47_LOCAL_MATRIX_ROWS_MASK | Z47_LOCAL_MATRIX_COLUMNS_MASK);
    descriptor |= (@as(u32, rows) & 0x0fff) << Z47_LOCAL_MATRIX_ROWS_SHIFT;
    descriptor |= (@as(u32, columns) & 0x0fff) << Z47_LOCAL_MATRIX_COLUMNS_SHIFT;
    copyValueToBytes(u32, data_ptr, &descriptor);
}