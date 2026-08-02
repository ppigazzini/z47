//! Matrix shape predicates and the register-capacity clamp -- the pure core
//! shared by the register codec and the matrix editor.
//!
//! A real-matrix register is treated as a geometric vector when its shape is
//! 1x2/2x1 (2D) or 1x3/3x1 (3D). The shape test is a pure predicate over the row
//! and column counts; the owners add the data-type and tag reads around it. Lift
//! it here for native coverage -- the register/matrix owners are only reachable
//! through the C oracle.

const std = @import("std");

/// A matrix shape as the state file states it, before or after clamping.
pub const Dims = struct {
    rows: u16,
    cols: u16,

    /// Upstream spells a refused matrix `rows = cols = 0`, which makes both the
    /// element restore and the element skip read nothing.
    pub const refused: Dims = .{ .rows = 0, .cols = 0 };
};

/// Blocks a `rows`x`cols` matrix register occupies, header included.
///
/// Returned as u64 on purpose: `rows * cols` alone reaches 0xFFFE0001, and the
/// caller's bound test is only meaningful if the product cannot wrap before it
/// is compared. Upstream casts to `uint64_t` at the same spot and for the same
/// reason.
pub fn registerBlocks(dims: Dims, element_blocks: u32, header_blocks: u32) u64 {
    return @as(u64, dims.rows) * @as(u64, dims.cols) * element_blocks + header_blocks;
}

/// Refuse file-supplied matrix dimensions that do not fit a register.
///
/// A register's data size is a u16 block count (`reallocateRegister`'s
/// `data_size_without_data_len_blocks`), and `rows`/`cols` come straight out of
/// a `.sav` / `.d47` the calculator did not write. Without this test the block
/// count truncates, the register is under-allocated, and the element restore
/// writes past it into the neighbouring block -- inside the `ram` pool, where no
/// sanitizer can see it. Port of the guard in upstream `saveRestoreCalcState.c`
/// (`restoreRegister`'s `Rema`/`Cxma` branches and the shared skip path).
///
/// Refusing rather than truncating is what keeps the restore and the skip sides
/// agreeing on how many elements the entry consumes; a clamp on one side only
/// desynchronises the file position for every later section.
pub fn clampToRegisterCapacity(dims: Dims, element_blocks: u32, header_blocks: u32) Dims {
    if (registerBlocks(dims, element_blocks, header_blocks) > std.math.maxInt(u16)) return .refused;
    return dims;
}

/// Whether a `rows`x`cols` matrix is a 2D vector (1x2 or 2x1).
pub fn is2dVector(rows: u16, cols: u16) bool {
    return (rows == 1 and cols == 2) or (rows == 2 and cols == 1);
}

/// Whether a `rows`x`cols` matrix is a 3D vector (1x3 or 3x1).
pub fn is3dVector(rows: u16, cols: u16) bool {
    return (rows == 1 and cols == 3) or (rows == 3 and cols == 1);
}

test "2D vectors are 1x2 or 2x1" {
    try std.testing.expect(is2dVector(1, 2));
    try std.testing.expect(is2dVector(2, 1));
    try std.testing.expect(!is2dVector(1, 3));
    try std.testing.expect(!is2dVector(2, 2));
    try std.testing.expect(!is2dVector(1, 1));
}

test "3D vectors are 1x3 or 3x1" {
    try std.testing.expect(is3dVector(1, 3));
    try std.testing.expect(is3dVector(3, 1));
    try std.testing.expect(!is3dVector(1, 2));
    try std.testing.expect(!is3dVector(3, 3));
    try std.testing.expect(!is3dVector(2, 3));
}

// The two matrix element widths and the header, in 4-byte blocks, as the
// register codec passes them: real34 is 16 bytes, complex34 is 32, and
// matrixHeader_t is 4.
const test_real34_blocks: u32 = 4;
const test_complex34_blocks: u32 = 8;
const test_header_blocks: u32 = 1;

fn clampReal(rows: u16, cols: u16) Dims {
    return clampToRegisterCapacity(.{ .rows = rows, .cols = cols }, test_real34_blocks, test_header_blocks);
}

test "a matrix that fits a register keeps its dimensions" {
    try std.testing.expectEqual(Dims{ .rows = 1, .cols = 1 }, clampReal(1, 1));
    try std.testing.expectEqual(Dims{ .rows = 2, .cols = 2 }, clampReal(2, 2));
    try std.testing.expectEqual(Dims{ .rows = 0, .cols = 0 }, clampReal(0, 0));
    // An empty row/column count is a real shape the save side can emit.
    try std.testing.expectEqual(Dims{ .rows = 0, .cols = 7 }, clampReal(0, 7));
}

test "the real34 capacity boundary is exact" {
    // 16383 elements: 16383*4 + 1 == 65533 blocks, the largest that fits a u16.
    try std.testing.expectEqual(Dims{ .rows = 3, .cols = 5461 }, clampReal(3, 5461));
    // 16384 elements: 16384*4 + 1 == 65537, one block past the u16 count. This
    // is the 128x128 case, which is a plausible matrix rather than a hostile one.
    try std.testing.expectEqual(Dims.refused, clampReal(128, 128));
    try std.testing.expectEqual(Dims.refused, clampReal(4, 4096));
}

test "the complex34 boundary is half the real34 one" {
    const clampCplx = struct {
        fn f(rows: u16, cols: u16) Dims {
            return clampToRegisterCapacity(.{ .rows = rows, .cols = cols }, test_complex34_blocks, test_header_blocks);
        }
    }.f;
    // 8191 elements fit (8191*8 + 1 == 65529); 8192 do not (65537).
    try std.testing.expectEqual(Dims{ .rows = 1, .cols = 8191 }, clampCplx(1, 8191));
    try std.testing.expectEqual(Dims.refused, clampCplx(1, 8192));
    try std.testing.expectEqual(Dims.refused, clampCplx(128, 128));
}

test "the largest dimensions a file can state do not wrap the product" {
    // rows*cols alone is 0xFFFE0001 here, so a u32 product would still hold it
    // but a u16 block count cannot. The u64 widening is what makes the test
    // meaningful; without it the *4 wraps to 0xFFF80004 and the comparison is
    // against a number the file never claimed.
    const max: u16 = std.math.maxInt(u16);
    try std.testing.expectEqual(
        @as(u64, max) * max * test_real34_blocks + test_header_blocks,
        registerBlocks(.{ .rows = max, .cols = max }, test_real34_blocks, test_header_blocks),
    );
    try std.testing.expectEqual(Dims.refused, clampReal(max, max));
}

test "surviving the clamp is what makes the element block count fit a u16" {
    // The register codec narrows `registerBlocks(dims, element_blocks, 0)` to the
    // u16 `reallocateRegister` takes, and calls that cast in-range by
    // construction. This is that construction: sweep both element widths over
    // every row count, take the widest column count each one admits, and assert
    // the elements alone still fit. If the clamp ever stops implying this, the
    // codec's @intCast becomes reachable and this test fails first.
    const max_u16 = std.math.maxInt(u16);
    for ([_]u32{ test_real34_blocks, test_complex34_blocks }) |element_blocks| {
        var rows: u16 = 0;
        while (true) : (rows += 1) {
            // Widest column count this row count admits, computed rather than
            // searched: rows*cols*element_blocks + header <= max_u16.
            const admitted: u32 = if (rows == 0)
                max_u16
            else
                @min(max_u16, (max_u16 - test_header_blocks) / (@as(u32, rows) * element_blocks));
            const cols: u16 = @intCast(admitted);

            const dims: Dims = .{ .rows = rows, .cols = cols };
            // The clamp accepts it, and the ELEMENTS alone fit the u16 block count
            // the codec narrows to. That second half is the codec's proof obligation.
            try std.testing.expectEqual(dims, clampToRegisterCapacity(dims, element_blocks, test_header_blocks));
            try std.testing.expect(registerBlocks(dims, element_blocks, 0) <= max_u16);

            // One more column must be refused, or `cols` was not the widest and
            // the bound this test claims to pin is not the real one.
            if (cols < max_u16) {
                try std.testing.expectEqual(Dims.refused, clampToRegisterCapacity(
                    .{ .rows = rows, .cols = cols + 1 },
                    element_blocks,
                    test_header_blocks,
                ));
            }
            if (rows == max_u16) break;
        }
    }
}

test "a refused matrix reads and skips zero elements" {
    // Both sides multiply the dimensions to get an element count, so refusing
    // with 0x0 is what keeps restoreMatrixData and skipMatrixData agreeing.
    const refused = clampReal(128, 128);
    try std.testing.expectEqual(@as(u32, 0), @as(u32, refused.rows) * @as(u32, refused.cols));
}
