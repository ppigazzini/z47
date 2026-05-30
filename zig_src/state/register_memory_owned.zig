const runtime = @import("stack_runtime.zig");

extern fn z47_stack_runtime_real34_set_zero(dest: ?*anyopaque) void;

fn constOpaque(ptr: ?*anyopaque) ?*const anyopaque {
    return if (ptr) |value| @ptrCast(value) else null;
}

pub fn bytesFromBlocks(size_in_blocks: usize) u32 {
    return @intCast(size_in_blocks << 2);
}

pub fn copyBlocks(dest: ?*anyopaque, source: ?*const anyopaque, size_in_blocks: usize) void {
    _ = runtime.xcopy(dest, source, bytesFromBlocks(size_in_blocks));
}

pub fn freeRegisterData(reg: runtime.calcRegister_t) void {
    runtime.freeC47Blocks(runtime.getRegisterDataPointer(reg), runtime.getRegisterFullSizeInBlocks(reg));
}

pub fn setRegisterDataPointer(reg: runtime.calcRegister_t, mem_ptr: ?*anyopaque) void {
    runtime.setRegisterDataPointer(reg, constOpaque(mem_ptr));
}

pub fn zeroReal34(dest: ?*anyopaque) void {
    z47_stack_runtime_real34_set_zero(dest);
}