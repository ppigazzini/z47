const std = @import("std");
const random_primitives_owned = @import("random_primitives.zig");
const runtime = @import("../command_wrappers_runtime.zig");

fn readSeedWord(lsu_bytes: *const [50]u8, offset: usize) u64 {
    const word_bytes: *const [8]u8 = @ptrCast(&lsu_bytes[offset]);
    return std.mem.readInt(u64, word_bytes, .native);
}

fn seedDefaults(seed_value: *u64, sequence: *u64) void {
    if (runtime.harness_surface_is_fake) {
        runtime.z47_math_wrappers_seed_defaults(seed_value, sequence);
        return;
    }
    if (runtime.is_testsuite_build) {
        seed_value.* = 0xDeadBeef;
        sequence.* = 0xBadCafeFace;
        return;
    }
    seed_value.* = (@as(u64, runtime.getUptimeMs()) << 32) + @as(u64, runtime.getFreeRamMemory());
    sequence.* = (@as(u64, runtime.getUptimeMs()) << 32) + @as(u64, runtime.getFreeFlash());
}

pub fn seed(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    var register_x = std.mem.zeroes(runtime.real_t);

    if (!runtime.saveLastX()) {
        return;
    }

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &register_x)) {
        return;
    }

    runtime.fnDrop(0);

    const lsu_bytes: *const [50]u8 = @ptrCast(&register_x.lsu);
    var seed_value = readSeedWord(lsu_bytes, 0);
    var sequence = readSeedWord(lsu_bytes, @sizeOf(u64));

    if (seed_value == 0 and sequence == 0) {
        seedDefaults(&seed_value, &sequence);
    }

    random_primitives_owned.pcg32Srandom(seed_value, sequence);
}
