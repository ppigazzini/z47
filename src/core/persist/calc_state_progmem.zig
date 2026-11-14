// SPDX-License-Identifier: GPL-3.0-only
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

/// The C47 RAM pool (`ram`, RAM_SIZE_IN_BLOCKS 4-byte blocks) and the geometry
/// the save and restore owners read it with. A program-memory pointer is held as
/// its byte offset from `base` while it is computed on, and becomes a pointer
/// again by adding that offset to `base`.
pub const Ram = struct {
    base: [*]align(4) u8,
    size_in_blocks: u32,
    /// True for the OLD_HW (DMCP / original DM42) firmware lane.
    old_hw: bool,

    pub fn of(words: [*]u32, size_in_blocks: u32, old_hw: bool) Ram {
        return .{
            .base = std.mem.sliceAsBytes(words[0..size_in_blocks]).ptr,
            .size_in_blocks = size_in_blocks,
            .old_hw = old_hw,
        };
    }

    /// The whole pool as bytes.
    pub fn bytes(self: Ram) []align(4) u8 {
        return self.base[0 .. @as(usize, self.size_in_blocks) * 4];
    }

    /// Byte offset of `p` from the RAM base.
    pub fn offsetOf(self: Ram, p: [*]const u8) usize {
        return p - self.base;
    }

    /// The byte `offset` bytes after the RAM base.
    pub fn at(self: Ram, offset: usize) [*]u8 {
        return self.base + offset;
    }

    /// TO_C47MEMPTR: block index of a RAM byte pointer, or C47_NULL for null.
    pub fn toC47memptr(self: Ram, p: ?[*]const u8) u16 {
        const q = p orelse return C47_NULL;
        return @intCast(self.offsetOf(q) / 4);
    }

    /// Byte offset of a RAM pointer within its block.
    pub fn offsetWithinBlock(self: Ram, p: [*]const u8) u32 {
        return @intCast(self.offsetOf(p) % 4);
    }

    /// TO_PCMEMPTR: the first byte of a block, or null for C47_NULL.
    pub fn toPcmemptr(self: Ram, blk: u16) ?[*]u8 {
        if (blk == C47_NULL) return null;
        return self.at(@as(usize, blk) * 4);
    }

    /// currentSizeInBlocks = RAM_SIZE_IN_BLOCKS - TO_C47MEMPTR(beginOfProgramMemory)
    pub fn programSizeInBlocks(self: Ram, begin_of_program_memory: [*]const u8) u16 {
        return @intCast(self.size_in_blocks - self.toC47memptr(begin_of_program_memory));
    }
};

/// Program-memory positions as byte offsets from the RAM base (`Ram.offsetOf`).
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
///
/// C compares firstFreeProgramByte + freeProgramBytes with the byte two short of
/// the end of program memory, and the OLD_HW test subtracts diff first. Every
/// comparison here moves the subtracted term to the other side, so no offset
/// goes below the RAM base on input C reads without trouble. The correction
/// itself wraps, as C's pointer arithmetic does on a file whose step precedes it.
pub fn relocatePrograms(in: RelocInput, old_hw: bool) RelocOutput {
    const diff: usize = @as(usize, (RAM_SIZE_IN_BLOCKS_NEW_HW - RAM_SIZE_IN_BLOCKS_OLD_HW)) << 2;
    var current_step = in.current_step;
    var first_free = in.first_free_program_byte;
    const end = in.begin_of_program_memory + (@as(usize, in.number_of_blocks) << 2);
    const reached = first_free + in.free_program_bytes + 2;
    if (reached != end) {
        if (old_hw) {
            if (reached == end + diff) {
                current_step -%= diff;
                first_free -%= diff;
            }
        } else {
            if (reached + diff == end) {
                current_step +%= diff;
                first_free +%= diff;
            }
        }
    }
    return .{ .current_step = current_step, .first_free_program_byte = first_free };
}

// ===================== harness =====================

// One pool as large as the NEW_HW geometry; the OLD_HW tests view its start.
var test_words: [RAM_SIZE_IN_BLOCKS_NEW_HW]u32 = undefined;

test "toC47memptr / offsetWithinBlock / toPcmemptr round-trip (both geometries)" {
    for ([_]u32{ RAM_SIZE_IN_BLOCKS_OLD_HW, RAM_SIZE_IN_BLOCKS_NEW_HW }) |size| {
        const ram = Ram.of(&test_words, size, size == RAM_SIZE_IN_BLOCKS_OLD_HW);
        // null maps to C47_NULL and back to null.
        try std.testing.expectEqual(@as(u16, C47_NULL), ram.toC47memptr(null));
        try std.testing.expectEqual(@as(?[*]u8, null), ram.toPcmemptr(C47_NULL));
        // C's TO_C47MEMPTR is uint32_t* pointer subtraction (truncating
        // byte-offset/4), so the within-block offset is always 0..3. A pointer
        // 3 bytes into block 100 (byte 403) is block 100, offset 3.
        const p = ram.at(100 * 4 + 3);
        try std.testing.expectEqual(@as(u16, 100), ram.toC47memptr(p));
        try std.testing.expectEqual(@as(u32, 3), ram.offsetWithinBlock(p));
        try std.testing.expectEqual(ram.at(100 * 4), ram.toPcmemptr(ram.toC47memptr(p)).?);
        try std.testing.expectEqual(@as(usize, size) * 4, ram.bytes().len);
    }
}

test "programSizeInBlocks differs by hardware geometry" {
    const ram_old = Ram.of(&test_words, RAM_SIZE_IN_BLOCKS_OLD_HW, true);
    const ram_new = Ram.of(&test_words, RAM_SIZE_IN_BLOCKS_NEW_HW, false);
    // beginOfProgramMemory at block 100
    try std.testing.expectEqual(@as(u16, 16384 - 100), ram_old.programSizeInBlocks(ram_old.at(100 * 4)));
    try std.testing.expectEqual(@as(u16, 65534 - 100), ram_new.programSizeInBlocks(ram_new.at(100 * 4)));
}

test "relocatePrograms: no correction when pointers already align" {
    const begin: usize = 1000;
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
    const begin: usize = diff + 4096;
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
    const begin: usize = 8192;
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

test "relocatePrograms: an OLD_HW image with nothing to correct stays put" {
    // Program memory ends well inside the 64 KiB OLD_HW pool, so first_free + free
    // is far below diff; the comparison must not subtract diff from it.
    const begin: usize = 60000;
    const nblocks: u16 = 100;
    const in = RelocInput{
        .first_free_program_byte = begin + 64,
        .free_program_bytes = 10,
        .begin_of_program_memory = begin,
        .number_of_blocks = nblocks,
        .current_step = begin + 4,
    };
    const out = relocatePrograms(in, true);
    try std.testing.expectEqual(in.current_step, out.current_step);
    try std.testing.expectEqual(in.first_free_program_byte, out.first_free_program_byte);
}
