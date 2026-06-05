const build_options = @import("stack_state_build_options");
const runtime = @import("stack_runtime.zig");

const use_fake_stack_state_harness_surface =
    @hasDecl(build_options, "use_fake_stack_state_harness_surface") and
    build_options.use_fake_stack_state_harness_surface;

// Upstream real34SetZero(dest) expands to decQuadZero(dest); a real34 zero is the
// decimal128 +0 encoding, not an all-zero byte pattern, so call decQuadZero. The
// parity harness stubs real34SetZero without decQuadZero, so keep routing through
// the fake double there.
extern fn decQuadZero(dest: ?*anyopaque) ?*anyopaque;
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
    if (use_fake_stack_state_harness_surface) {
        z47_stack_runtime_real34_set_zero(dest);
        return;
    }
    _ = decQuadZero(dest);
}