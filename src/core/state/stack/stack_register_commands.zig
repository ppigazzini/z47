const runtime = @import("../runtime/stack_runtime.zig");
const register_range_ops = @import("register_range_ops.zig"); // std-only register-range geometry

// Port of registers.c sortReg: a recursive merge sort of the register descriptors
// across the range, ordered by registerCmp (value comparison). Swapping the 32-bit
// descriptors moves the register contents. The merge takes the left run on every
// res <= 0, so registers that compare equal but are distinguishable -- a long
// integer 1, a real34 1. and a short integer 1 in the same range -- keep their
// input order. The scratch run is one block per register, taken from the register
// pool: a range too large to buffer is refused, not sorted in place. A pair
// registerCmp cannot compare (returns false) leaves the output slot holding
// whatever the scratch block held. This is the full-build body behind
// z47_registers_sort_reg (the parity harness supplies its own fake).
pub fn sortRegisterRange(range_start: u16, range_end: u16) void {
    var res: i8 = 0;

    if (range_start == range_end) {
        return;
    }

    if (@as(u32, range_start) + 1 == range_end) {
        if (runtime.registerCmp(@intCast(range_start), @intCast(range_end), &res) and res > 0) {
            const saved = runtime.globalDescriptor(@intCast(range_start));
            runtime.setGlobalDescriptor(@intCast(range_start), runtime.globalDescriptor(@intCast(range_end)));
            runtime.setGlobalDescriptor(@intCast(range_end), saved);
        }
        return;
    }

    const range_span: u16 = range_end - range_start;
    const range_center: u16 = range_span / 2 + range_start;
    var pos1: u16 = range_start;
    var pos2: u16 = range_center + 1;
    // TO_BLOCKS(sizeof(registerHeader_t)) is 1: the descriptor is a single block.
    const scratch_blocks: usize = @as(usize, range_span) + 1;
    const scratch = runtime.allocC47Blocks(scratch_blocks);
    if (runtime.lastErrorCode == runtime.ERROR_RAM_FULL) {
        return;
    }

    if (scratch) |block| {
        const sorted: [*]runtime.register_descriptor_t = @ptrCast(@alignCast(block));

        sortRegisterRange(range_start, range_center);
        sortRegisterRange(range_center + 1, range_end);

        var i: u16 = 0;
        while (i <= range_span) : (i += 1) {
            if (runtime.registerCmp(@intCast(pos1), @intCast(pos2), &res)) {
                if (pos2 > range_end) {
                    sorted[i] = runtime.globalDescriptor(@intCast(pos1));
                    pos1 += 1;
                } else if (pos1 > range_center) {
                    sorted[i] = runtime.globalDescriptor(@intCast(pos2));
                    pos2 += 1;
                } else if (res > 0) {
                    sorted[i] = runtime.globalDescriptor(@intCast(pos2));
                    pos2 += 1;
                } else {
                    sorted[i] = runtime.globalDescriptor(@intCast(pos1));
                    pos1 += 1;
                }
            }
        }

        i = 0;
        while (i <= range_span) : (i += 1) {
            runtime.setGlobalDescriptor(@intCast(range_start + i), sorted[i]);
        }

        runtime.freeC47Blocks(block, scratch_blocks);
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE, runtime.NIM_REGISTER_LINE);
    }
}

pub fn regClr() void {
    var s: u16 = 0;
    var n: u16 = 0;

    runtime.lastErrorCode = runtime.getRegClrRange(&s, &n);
    if (runtime.lastErrorCode == runtime.ERROR_NONE) {
        var reg = s;
        while (reg < s + n) : (reg += 1) {
            runtime.clearRegister(@intCast(reg));
        }
        return;
    }

    runtime.reportRegisterCommandError(runtime.lastErrorCode);
}

pub fn regSwap() void {
    var s: u16 = 0;
    var n: u16 = 0;
    var d: u16 = 0;

    runtime.lastErrorCode = runtime.getRegSwapRange(&s, &n, &d);
    if (runtime.lastErrorCode != runtime.ERROR_NONE) {
        runtime.reportRegisterCommandError(runtime.lastErrorCode);
        return;
    }

    if (register_range_ops.rangesOverlap(s, d, n)) {
        runtime.reportRegisterCommandError(runtime.ERROR_OUT_OF_RANGE);
        return;
    }

    var index: u16 = 0;
    while (index < n) : (index += 1) {
        const src = @as(runtime.calcRegister_t, @intCast(s + index));
        const dst = @as(runtime.calcRegister_t, @intCast(d + index));
        const saved_descriptor = runtime.globalDescriptor(src);
        runtime.setGlobalDescriptor(src, runtime.globalDescriptor(dst));
        runtime.setGlobalDescriptor(dst, saved_descriptor);
    }
}

pub fn regCopy(unused_but_mandatory_parameter: u16) void {
    var f = false;
    var s: u16 = 0;
    var n: u16 = 0;
    var d: u16 = 0;

    runtime.lastErrorCode = runtime.getRegCopyParams(&f, &s, &n, &d);
    if (runtime.lastErrorCode != runtime.ERROR_NONE) {
        runtime.reportRegisterCommandError(runtime.lastErrorCode);
        return;
    }

    if (f) {
        _ = unused_but_mandatory_parameter;
        runtime.doPartialRegisterLoad(s, n, d);
        return;
    }

    switch (register_range_ops.copyDirection(s, d)) {
        .ascending => {
            var index: u16 = 0;
            while (index < n) : (index += 1) {
                runtime.copySourceRegisterToDestRegister(
                    @as(runtime.calcRegister_t, @intCast(s + index)),
                    @as(runtime.calcRegister_t, @intCast(d + index)),
                );
                if (runtime.lastErrorCode == runtime.ERROR_RAM_FULL) {
                    return;
                }
            }
        },
        .descending => {
            var index = n;
            while (index > 0) {
                index -= 1;
                runtime.copySourceRegisterToDestRegister(
                    @as(runtime.calcRegister_t, @intCast(s + index)),
                    @as(runtime.calcRegister_t, @intCast(d + index)),
                );
                if (runtime.lastErrorCode == runtime.ERROR_RAM_FULL) {
                    return;
                }
            }
        },
        .none => {},
    }
}

pub fn regSort() void {
    var s: u16 = 0;
    var n: u16 = 0;

    runtime.lastErrorCode = runtime.getRegClrRange(&s, &n);
    if (runtime.lastErrorCode != runtime.ERROR_NONE) {
        runtime.reportRegisterCommandError(runtime.lastErrorCode);
        return;
    }

    switch (runtime.getRegisterDataType(@as(runtime.calcRegister_t, @intCast(s)))) {
        runtime.dtLongInteger, runtime.dtShortInteger, runtime.dtReal34 => {
            var index: u16 = s + 1;
            while (index < s + n) : (index += 1) {
                const data_type = runtime.getRegisterDataType(@as(runtime.calcRegister_t, @intCast(index)));
                if (data_type != runtime.dtLongInteger and data_type != runtime.dtShortInteger and data_type != runtime.dtReal34) {
                    runtime.reportRegisterCommandError(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP);
                    return;
                }
            }
        },
        runtime.dtTime, runtime.dtDate, runtime.dtString => {
            const first_type = runtime.getRegisterDataType(@as(runtime.calcRegister_t, @intCast(s)));
            var index: u16 = s + 1;
            while (index < s + n) : (index += 1) {
                if (runtime.getRegisterDataType(@as(runtime.calcRegister_t, @intCast(index))) != first_type) {
                    runtime.reportRegisterCommandError(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP);
                    return;
                }
            }
        },
        else => {},
    }

    if (runtime.lastErrorCode == runtime.ERROR_NONE) {
        runtime.sortRegisterRange(s, s + n - 1);
    }
}
