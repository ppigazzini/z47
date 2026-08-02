const runtime = @import("../runtime/stack_runtime.zig");
const memory_owned = @import("../runtime/register_memory.zig");

fn registerWithOffset(base: runtime.calcRegister_t, offset: u16) runtime.calcRegister_t {
    return base + @as(runtime.calcRegister_t, @intCast(offset));
}

pub fn liftStack() void {
    const stack_top = runtime.getStackTop();

    if (runtime.getSystemFlag(runtime.FLAG_ASLIFT)) {
        if (runtime.currentInputVariable != runtime.INVALID_VARIABLE) {
            runtime.currentInputVariable |= @as(u16, 0x8000);
        }
        memory_owned.freeRegisterData(stack_top);

        var reg = stack_top;
        while (reg > runtime.REGISTER_X) : (reg -= 1) {
            runtime.setGlobalDescriptor(reg, runtime.globalDescriptor(reg - 1));
        }
    } else {
        memory_owned.freeRegisterData(runtime.REGISTER_X);
    }

    memory_owned.setRegisterDataPointer(runtime.REGISTER_X, runtime.allocC47Blocks(runtime.real34SizeInBlocks()));
    runtime.setRegisterDataType(runtime.REGISTER_X, @intCast(runtime.dtReal34), runtime.amNone);
}

pub fn saveLastX() bool {
    runtime.copySourceRegisterToDestRegister(runtime.REGISTER_X, runtime.REGISTER_L);
    return runtime.lastErrorCode == runtime.ERROR_NONE;
}

pub fn getLocalRegisterCount() void {
    liftStack();
    runtime.storeLocalRegisterCountInX();
}

pub fn drop(reg: runtime.calcRegister_t) void {
    const stack_top = runtime.getStackTop();
    if (reg == stack_top) {
        return;
    }

    memory_owned.freeRegisterData(reg);

    var current = reg;
    while (current < stack_top) : (current += 1) {
        runtime.setGlobalDescriptor(current, runtime.globalDescriptor(current + 1));
    }

    const size_in_blocks = runtime.getRegisterFullSizeInBlocks(stack_top);
    const data_ptr = runtime.allocC47Blocks(size_in_blocks);
    if (data_ptr != null) {
        memory_owned.setRegisterDataPointer(stack_top - 1, data_ptr);
        memory_owned.copyBlocks(
            runtime.getRegisterDataPointer(stack_top - 1),
            runtime.getRegisterDataPointer(stack_top),
            size_in_blocks,
        );
    } else {
        runtime.lastErrorCode = runtime.ERROR_RAM_FULL;
    }
}

pub fn dropX() void {
    drop(runtime.REGISTER_X);
}

pub fn dropY() void {
    drop(runtime.REGISTER_Y);
}

pub fn dropZ() void {
    drop(runtime.REGISTER_Z);
}

pub fn dropT() void {
    drop(runtime.REGISTER_T);
}

pub fn dropN(number: u16) void {
    const count: u16 = @min(number, @as(u16, 8));
    var index: u16 = 0;
    while (index < count) : (index += 1) {
        dropX();
    }
}

pub fn dupN(number: u16) void {
    const count: u16 = @min(number, @as(u16, 4));
    var index: u16 = 0;
    while (index < count) : (index += 1) {
        runtime.setSystemFlag(runtime.FLAG_ASLIFT);
        runtime.fnRecall(@intCast(registerWithOffset(runtime.REGISTER_X, number - 1)));
    }
}

pub fn fillStack() void {
    const stack_top = runtime.getStackTop();
    const data_type_x = runtime.getRegisterDataType(runtime.REGISTER_X);
    const data_size_x_in_blocks = runtime.getRegisterFullSizeInBlocks(runtime.REGISTER_X);
    const tag = runtime.getRegisterTag(runtime.REGISTER_X);

    var reg = runtime.REGISTER_Y;
    while (reg <= stack_top) : (reg += 1) {
        memory_owned.freeRegisterData(reg);
        runtime.setRegisterDataType(reg, @intCast(data_type_x), tag);

        const new_data_pointer = runtime.allocC47Blocks(data_size_x_in_blocks);
        if (new_data_pointer != null) {
            memory_owned.setRegisterDataPointer(reg, new_data_pointer);
            memory_owned.copyBlocks(new_data_pointer, runtime.getRegisterDataPointer(runtime.REGISTER_X), data_size_x_in_blocks);
        } else {
            runtime.lastErrorCode = runtime.ERROR_RAM_FULL;
            return;
        }
    }
}

pub fn getStackSize() void {
    liftStack();
    runtime.storeStackSizeInX(if (runtime.getSystemFlag(runtime.FLAG_SSIZE8)) 8 else 4);
}

pub fn fillStackWithReal0() void {
    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
    memory_owned.zeroReal34(runtime.getRegisterDataPointer(runtime.REGISTER_X));
    fillStack();
}
