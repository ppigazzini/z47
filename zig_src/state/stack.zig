const descriptor_owned = @import("stack_descriptor_owned.zig");
const clear_owned = @import("stack_clear_owned.zig");
const register_commands_owned = @import("stack_register_commands_owned.zig");
const result_owned = @import("stack_result_owned.zig");
const runtime = @import("stack_runtime.zig");

fn registerWithOffset(base: runtime.calcRegister_t, offset: u16) runtime.calcRegister_t {
    return base + @as(runtime.calcRegister_t, @intCast(offset));
}

pub export fn fnClX(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    clear_owned.clearX();
}

pub export fn fnClearStack(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    clear_owned.clearStack();
}

pub export fn clearRegister(reg: runtime.calcRegister_t) void {
    clear_owned.clearRegister(reg);
}

pub export fn fnClearRegisters(confirmation: u16) void {
    clear_owned.clearRegisters(confirmation);
}

pub export fn fnRegClr(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    register_commands_owned.regClr();
}

pub export fn fnRegSwap(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    register_commands_owned.regSwap();
}

pub export fn fnRegCopy(unused_but_mandatory_parameter: u16) void {
    register_commands_owned.regCopy(unused_but_mandatory_parameter);
}

pub export fn fnRegSort(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    register_commands_owned.regSort();
}

pub export fn fnToReal(unused_but_mandatory_parameter: u16) void {
    result_owned.toReal(unused_but_mandatory_parameter);
}

pub export fn adjustResult(res: runtime.calcRegister_t, drop_y: bool, set_cpx_res: bool, op1: runtime.calcRegister_t, op2: runtime.calcRegister_t, op3: runtime.calcRegister_t) void {
    result_owned.adjustResult(res, drop_y, set_cpx_res, op1, op2, op3);
}

pub export fn liftStack() void {
    const stack_top = runtime.getStackTop();

    if (runtime.getSystemFlag(runtime.FLAG_ASLIFT)) {
        if (runtime.currentInputVariable != runtime.INVALID_VARIABLE) {
            runtime.currentInputVariable |= @as(u16, 0x8000);
        }
        runtime.freeRegisterData(stack_top);

        var reg = stack_top;
        while (reg > runtime.REGISTER_X) : (reg -= 1) {
            runtime.setGlobalDescriptor(reg, runtime.globalDescriptor(reg - 1));
        }
    } else {
        runtime.freeRegisterData(runtime.REGISTER_X);
    }

    runtime.setRegisterDataPointerMutable(runtime.REGISTER_X, runtime.allocC47Blocks(runtime.real34SizeInBlocks()));
    runtime.setRegisterDataType(runtime.REGISTER_X, @intCast(runtime.dtReal34), runtime.amNone);
}

pub export fn saveLastX() bool {
    runtime.copySourceRegisterToDestRegister(runtime.REGISTER_X, runtime.REGISTER_L);
    return runtime.lastErrorCode == runtime.ERROR_NONE;
}

pub export fn fnGetLocR(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    liftStack();
    runtime.storeLocalRegisterCountInX();
}

pub export fn _Drop(reg: runtime.calcRegister_t) void {
    const stack_top = runtime.getStackTop();
    if (reg == stack_top) {
        return;
    }

    runtime.freeRegisterData(reg);

    var current = reg;
    while (current < stack_top) : (current += 1) {
        runtime.setGlobalDescriptor(current, runtime.globalDescriptor(current + 1));
    }

    const size_in_blocks = runtime.getRegisterFullSizeInBlocks(stack_top);
    const data_ptr = runtime.allocC47Blocks(size_in_blocks);
    if (data_ptr != null) {
        runtime.setRegisterDataPointerMutable(stack_top - 1, data_ptr);
        runtime.xcopyBlocks(
            runtime.getRegisterDataPointer(stack_top - 1),
            runtime.getRegisterDataPointer(stack_top),
            size_in_blocks,
        );
    } else {
        runtime.lastErrorCode = runtime.ERROR_RAM_FULL;
    }
}

pub export fn fnDrop(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    _Drop(runtime.REGISTER_X);
}

pub export fn fnDropY(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    _Drop(runtime.REGISTER_Y);
}

pub export fn fnDropZ(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    _Drop(runtime.REGISTER_Z);
}

pub export fn fnDropT(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    _Drop(runtime.REGISTER_T);
}

pub export fn fnDropN(number: u16) void {
    const count: u16 = @min(number, @as(u16, 8));
    var index: u16 = 0;
    while (index < count) : (index += 1) {
        _Drop(runtime.REGISTER_X);
    }
}

pub export fn fnRollUp(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    descriptor_owned.rollUp();
}

pub export fn fnRollDown(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    descriptor_owned.rollDown();
}

pub export fn fnDisplayStack(number_of_stack_lines: u16) void {
    runtime.displayStack = @intCast(number_of_stack_lines);
}

pub export fn fnSwapX(reg: u16) void {
    descriptor_owned.swapX(reg);
}

pub export fn fnSwapY(reg: u16) void {
    descriptor_owned.swapY(reg);
}

pub export fn fnSwapZ(reg: u16) void {
    descriptor_owned.swapZ(reg);
}

pub export fn fnSwapT(reg: u16) void {
    descriptor_owned.swapT(reg);
}

pub export fn fnSwapN(number: u16) void {
    descriptor_owned.swapN(number);
}

pub export fn fnDupN(number: u16) void {
    const count: u16 = @min(number, @as(u16, 4));
    var index: u16 = 0;
    while (index < count) : (index += 1) {
        runtime.setSystemFlag(runtime.FLAG_ASLIFT);
        runtime.fnRecall(@intCast(registerWithOffset(runtime.REGISTER_X, number - 1)));
    }
}

pub export fn fnSwapXY(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    descriptor_owned.swapXY();
}

pub export fn fnShuffle(regist_order: u16) void {
    descriptor_owned.shuffle(regist_order);
}

pub export fn fnFillStack(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    const stack_top = runtime.getStackTop();
    const data_type_x = runtime.getRegisterDataType(runtime.REGISTER_X);
    const data_size_x_in_blocks = runtime.getRegisterFullSizeInBlocks(runtime.REGISTER_X);
    const tag = runtime.getRegisterTag(runtime.REGISTER_X);

    var reg = runtime.REGISTER_Y;
    while (reg <= stack_top) : (reg += 1) {
        runtime.freeRegisterData(reg);
        runtime.setRegisterDataType(reg, @intCast(data_type_x), tag);

        const new_data_pointer = runtime.allocC47Blocks(data_size_x_in_blocks);
        if (new_data_pointer != null) {
            runtime.setRegisterDataPointerMutable(reg, new_data_pointer);
            runtime.xcopyBlocks(new_data_pointer, runtime.getRegisterDataPointer(runtime.REGISTER_X), data_size_x_in_blocks);
        } else {
            runtime.lastErrorCode = runtime.ERROR_RAM_FULL;
            return;
        }
    }
}

pub export fn fnGetStackSize(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    liftStack();
    runtime.storeStackSizeInX(if (runtime.getSystemFlag(runtime.FLAG_SSIZE8)) 8 else 4);
}

pub export fn saveForUndo() void {
    runtime.saveForUndoRetained();
}

pub export fn fnUndo(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    if (runtime.thereIsSomethingToUndo) {
        undo();
    }
}

pub export fn undo() void {
    runtime.undoRetained();
}

pub export fn fillStackWithReal0() void {
    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
    runtime.real34SetZero(runtime.getRegisterDataPointer(runtime.REGISTER_X));
    fnFillStack(0);
}
