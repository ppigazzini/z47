const descriptor_owned = @import("stack_descriptor_owned.zig");
const clear_owned = @import("stack_clear_owned.zig");
const register_commands_owned = @import("stack_register_commands_owned.zig");
const mutation_owned = @import("stack_mutation_owned.zig");
const result_owned = @import("stack_result_owned.zig");
const undo_owned = @import("stack_undo_owned.zig");
const runtime = @import("stack_runtime.zig");

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
    mutation_owned.liftStack();
}

pub export fn saveLastX() bool {
    return mutation_owned.saveLastX();
}

pub export fn fnGetLocR(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    mutation_owned.getLocalRegisterCount();
}

pub export fn _Drop(reg: runtime.calcRegister_t) void {
    mutation_owned.drop(reg);
}

pub export fn fnDrop(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    mutation_owned.dropX();
}

pub export fn fnDropY(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    mutation_owned.dropY();
}

pub export fn fnDropZ(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    mutation_owned.dropZ();
}

pub export fn fnDropT(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    mutation_owned.dropT();
}

pub export fn fnDropN(number: u16) void {
    mutation_owned.dropN(number);
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
    mutation_owned.dupN(number);
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
    mutation_owned.fillStack();
}

pub export fn fnGetStackSize(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    mutation_owned.getStackSize();
}

pub export fn saveForUndo() void {
    undo_owned.saveForUndo();
}

pub export fn fnUndo(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    undo_owned.fnUndo();
}

pub export fn undo() void {
    undo_owned.undo();
}

pub export fn fillStackWithReal0() void {
    mutation_owned.fillStackWithReal0();
}
