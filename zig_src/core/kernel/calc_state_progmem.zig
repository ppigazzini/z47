// Pure, parameterized program-memory pointer arithmetic shared by the save and
// restore owners. This is the ONLY part of the save/load codec whose result
// depends on the hardware RAM geometry (RAM_SIZE_IN_BLOCKS) and on the
// cross-hardware relocation correction — i.e. the part that differs between the
// NEW_HW lane (host / DMCP5 / DM42n, 65534 blocks) and the OLD_HW lane (DMCP /
// original DM42, 16384 blocks).
//
// The host parity round-trip exercises only the NEW_HW geometry (the host build
// is hardwired to NEW_HW: defines.h forces RAM_SIZE_IN_BLOCKS_NEW_HW when
// !DMCP_BUILD). To make the OLD_HW firmware lane VERIFIABLE without a device,
// every geometry-dependent operation is a pure function of its inputs (RAM base,
// RAM size, the raw pointers) and is covered by the embedded `test` blocks below
// for BOTH geometries. Run with `zig build state-progmem-test`.
//
// The save/restore owners call these with the live `ram` base and the
// build-selected geometry; the firmware lanes select OLD_HW vs NEW_HW via the
// `state_old_hw` build option.

const std = @import("std");

pub const RAM_SIZE_IN_BLOCKS_OLD_HW: u32 = 16384;
pub const RAM_SIZE_IN_BLOCKS_NEW_HW: u32 = 65534;
const C47_NULL: u16 = 65535;

pub const Geometry = struct {
    /// @intFromPtr of the RAM base (the C `ram`, a uint32_t*).
    ram_base: usize,
    /// RAM_SIZE_IN_BLOCKS for the target hardware.
    ram_size_in_blocks: u32,
    /// True for the OLD_HW (DMCP / original DM42) firmware lane.
    old_hw: bool,
};

/// TO_C47MEMPTR: block index of a RAM byte pointer, or C47_NULL for null.
pub fn toC47memptr(g: Geometry, p: usize) u16 {
    if (p == 0) return C47_NULL;
    return @intCast((p - g.ram_base) / 4);
}

/// Byte offset of a RAM pointer within its block.
pub fn offsetWithinBlock(g: Geometry, p: usize) u32 {
    const blk = toC47memptr(g, p);
    return @intCast(p - (g.ram_base + @as(usize, blk) * 4));
}

/// TO_PCMEMPTR: RAM byte address for a block index, or 0 (null) for C47_NULL.
pub fn toPcmemptr(g: Geometry, blk: u16) usize {
    if (blk == C47_NULL) return 0;
    return g.ram_base + @as(usize, blk) * 4;
}

/// currentSizeInBlocks = RAM_SIZE_IN_BLOCKS - TO_C47MEMPTR(beginOfProgramMemory)
pub fn programSizeInBlocks(g: Geometry, begin_of_program_memory: usize) u16 {
    return @intCast(g.ram_size_in_blocks - toC47memptr(g, begin_of_program_memory));
}

pub const RelocInput = struct {
    first_free_program_byte: usize,
    free_program_bytes: u16,
    begin_of_program_memory: usize,
    number_of_blocks: u16,
    current_step: usize,
};

pub const RelocOutput = struct {
    current_step: usize,
    first_free_program_byte: usize,
};

/// Cross-hardware relocation correction applied after reading the PROGRAMS
/// pointers (saveRestoreCalcState.c restore, lines ~2792-2805). When a state
/// file saved on a different RAM geometry is loaded, the program pointers land
/// `diff = TO_BYTES(NEW_HW - OLD_HW)` bytes off; nudge currentStep /
/// firstFreeProgramByte back into place. The sign flips between the OLD_HW
/// (DMCP, `- diff`) and NEW_HW (host/DMCP5, `+ diff`) lanes.
pub fn relocatePrograms(in: RelocInput, old_hw: bool) RelocOutput {
    const diff: usize = @as(usize, (RAM_SIZE_IN_BLOCKS_NEW_HW - RAM_SIZE_IN_BLOCKS_OLD_HW)) << 2;
    var current_step = in.current_step;
    var first_free = in.first_free_program_byte;
    const target = in.begin_of_program_memory + (@as(usize, in.number_of_blocks) << 2) - 2;
    if (first_free + in.free_program_bytes != target) {
        if (old_hw) {
            if (first_free + in.free_program_bytes - diff == target) {
                current_step -= diff;
                first_free -= diff;
            }
        } else {
            if (first_free + in.free_program_bytes + diff == target) {
                current_step += diff;
                first_free += diff;
            }
        }
    }
    return .{ .current_step = current_step, .first_free_program_byte = first_free };
}

// ===================== harness =====================

const test_base: usize = 0x40000000; // synthetic RAM base (16-aligned)

test "toC47memptr / offsetWithinBlock / toPcmemptr round-trip (both geometries)" {
    for ([_]u32{ RAM_SIZE_IN_BLOCKS_OLD_HW, RAM_SIZE_IN_BLOCKS_NEW_HW }) |size| {
        const g = Geometry{ .ram_base = test_base, .ram_size_in_blocks = size, .old_hw = (size == RAM_SIZE_IN_BLOCKS_OLD_HW) };
        // null maps to C47_NULL and back to null.
        try std.testing.expectEqual(@as(u16, C47_NULL), toC47memptr(g, 0));
        try std.testing.expectEqual(@as(usize, 0), toPcmemptr(g, C47_NULL));
        // C's TO_C47MEMPTR is uint32_t* pointer subtraction (truncating
        // byte-offset/4), so the within-block offset is always 0..3. A pointer
        // 3 bytes into block 100 (byte 403) is block 100, offset 3.
        const p = test_base + 100 * 4 + 3;
        try std.testing.expectEqual(@as(u16, 100), toC47memptr(g, p));
        try std.testing.expectEqual(@as(u32, 3), offsetWithinBlock(g, p));
        try std.testing.expectEqual(test_base + 100 * 4, toPcmemptr(g, toC47memptr(g, p)));
    }
}

test "programSizeInBlocks differs by hardware geometry" {
    const begin = test_base + 100 * 4; // beginOfProgramMemory at block 100
    const g_old = Geometry{ .ram_base = test_base, .ram_size_in_blocks = RAM_SIZE_IN_BLOCKS_OLD_HW, .old_hw = true };
    const g_new = Geometry{ .ram_base = test_base, .ram_size_in_blocks = RAM_SIZE_IN_BLOCKS_NEW_HW, .old_hw = false };
    try std.testing.expectEqual(@as(u16, 16384 - 100), programSizeInBlocks(g_old, begin));
    try std.testing.expectEqual(@as(u16, 65534 - 100), programSizeInBlocks(g_new, begin));
}

test "relocatePrograms: no correction when pointers already align" {
    const begin = test_base + 1000;
    const nblocks: u16 = 50;
    const target = begin + (@as(usize, nblocks) << 2) - 2;
    // first_free + free_bytes == target  -> untouched on both lanes
    const in = RelocInput{
        .first_free_program_byte = target - 8,
        .free_program_bytes = 8,
        .begin_of_program_memory = begin,
        .number_of_blocks = nblocks,
        .current_step = begin + 16,
    };
    inline for (.{ false, true }) |old_hw| {
        const out = relocatePrograms(in, old_hw);
        try std.testing.expectEqual(in.current_step, out.current_step);
        try std.testing.expectEqual(in.first_free_program_byte, out.first_free_program_byte);
    }
}

test "relocatePrograms: NEW_HW lane nudges +diff" {
    const diff: usize = @as(usize, (RAM_SIZE_IN_BLOCKS_NEW_HW - RAM_SIZE_IN_BLOCKS_OLD_HW)) << 2;
    const begin = test_base + 4096;
    const nblocks: u16 = 200;
    const target = begin + (@as(usize, nblocks) << 2) - 2;
    // first_free+free is diff short of target -> +diff correction.
    const in = RelocInput{
        .first_free_program_byte = target - diff - 10,
        .free_program_bytes = 10,
        .begin_of_program_memory = begin,
        .number_of_blocks = nblocks,
        .current_step = begin + 100,
    };
    const out = relocatePrograms(in, false);
    try std.testing.expectEqual(in.current_step + diff, out.current_step);
    try std.testing.expectEqual(in.first_free_program_byte + diff, out.first_free_program_byte);
}

test "relocatePrograms: OLD_HW lane nudges -diff" {
    const diff: usize = @as(usize, (RAM_SIZE_IN_BLOCKS_NEW_HW - RAM_SIZE_IN_BLOCKS_OLD_HW)) << 2;
    const begin = test_base + 8192;
    const nblocks: u16 = 200;
    const target = begin + (@as(usize, nblocks) << 2) - 2;
    // first_free+free is diff past target -> -diff correction (OLD_HW only).
    const in = RelocInput{
        .first_free_program_byte = target + diff - 10,
        .free_program_bytes = 10,
        .begin_of_program_memory = begin,
        .number_of_blocks = nblocks,
        .current_step = begin + diff + 100,
    };
    const out = relocatePrograms(in, true);
    try std.testing.expectEqual(in.current_step - diff, out.current_step);
    try std.testing.expectEqual(in.first_free_program_byte - diff, out.first_free_program_byte);
    // The NEW_HW lane would NOT apply the -diff correction for this input.
    const out_new = relocatePrograms(in, false);
    try std.testing.expectEqual(in.current_step, out_new.current_step);
}
