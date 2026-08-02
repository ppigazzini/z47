const runtime = @import("../runtime/stack_runtime.zig");
fn shuffleOrder(regist_order: u16) [4]u16 {
    var out: [4]u16 = undefined;
    var i: u16 = 0;
    while (i < 4) : (i += 1) out[i] = (regist_order >> @intCast(i * 2)) & 3;
    return out;
}

fn registerWithOffset(base: runtime.calcRegister_t, offset: u16) runtime.calcRegister_t {
    return base + @as(runtime.calcRegister_t, @intCast(offset));
}

fn swapRegs(src_reg: runtime.calcRegister_t, target_reg: u16) void {
    const saved_descriptor = runtime.globalDescriptor(src_reg);
    var target_descriptor: runtime.register_descriptor_t = 0;

    if (runtime.tryGetSwapTargetDescriptor(target_reg, &target_descriptor)) {
        runtime.setGlobalDescriptor(src_reg, target_descriptor);
        _ = runtime.trySetSwapTargetDescriptor(target_reg, saved_descriptor);
        return;
    }

    runtime.reportInvalidSwapTarget(target_reg);
}

pub fn swapX(reg: u16) void {
    swapRegs(runtime.REGISTER_X, reg);
}

pub fn swapY(reg: u16) void {
    swapRegs(runtime.REGISTER_Y, reg);
}

pub fn swapZ(reg: u16) void {
    swapRegs(runtime.REGISTER_Z, reg);
}

pub fn swapT(reg: u16) void {
    swapRegs(runtime.REGISTER_T, reg);
}

pub fn swapN(number: u16) void {
    const count: u16 = @min(number, @as(u16, 4));
    var index: u16 = 0;
    while (index < count) : (index += 1) {
        swapRegs(registerWithOffset(runtime.REGISTER_X, index), @intCast(registerWithOffset(runtime.REGISTER_X, number + index)));
    }
}

pub fn rollUp() void {
    const stack_top = runtime.getStackTop();
    const saved_descriptor = runtime.globalDescriptor(stack_top);

    var reg = stack_top;
    while (reg > runtime.REGISTER_X) : (reg -= 1) {
        runtime.setGlobalDescriptor(reg, runtime.globalDescriptor(reg - 1));
    }
    runtime.setGlobalDescriptor(runtime.REGISTER_X, saved_descriptor);
}

pub fn rollDown() void {
    const stack_top = runtime.getStackTop();
    const saved_descriptor = runtime.globalDescriptor(runtime.REGISTER_X);

    var reg = runtime.REGISTER_X;
    while (reg < stack_top) : (reg += 1) {
        runtime.setGlobalDescriptor(reg, runtime.globalDescriptor(reg + 1));
    }
    runtime.setGlobalDescriptor(stack_top, saved_descriptor);
}

pub fn swapXY() void {
    const saved_descriptor = runtime.globalDescriptor(runtime.REGISTER_X);
    runtime.setGlobalDescriptor(runtime.REGISTER_X, runtime.globalDescriptor(runtime.REGISTER_Y));
    runtime.setGlobalDescriptor(runtime.REGISTER_Y, saved_descriptor);
}

pub fn shuffle(regist_order: u16) void {
    var index: u16 = 0;
    while (index < 4) : (index += 1) {
        const current_reg = registerWithOffset(runtime.REGISTER_X, index);
        const saved_reg = registerWithOffset(runtime.SAVED_REGISTER_X, index);
        const saved_descriptor = runtime.globalDescriptor(current_reg);
        runtime.setGlobalDescriptor(current_reg, runtime.globalDescriptor(saved_reg));
        runtime.setGlobalDescriptor(saved_reg, saved_descriptor);
    }

    const order = shuffleOrder(regist_order);
    index = 0;
    while (index < 4) : (index += 1) {
        runtime.copySourceRegisterToDestRegister(registerWithOffset(runtime.SAVED_REGISTER_X, order[index]), registerWithOffset(runtime.REGISTER_X, index));
    }
}
