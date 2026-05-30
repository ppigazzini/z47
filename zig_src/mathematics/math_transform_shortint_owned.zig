const runtime = @import("math_command_wrappers_runtime.zig");

pub fn shortIntegerData(reg: runtime.calcRegister_t) *align(1) u64 {
    return @as(*align(1) u64, @ptrCast(runtime.getRegisterDataPointer(reg).?));
}
