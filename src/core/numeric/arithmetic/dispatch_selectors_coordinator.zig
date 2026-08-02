const runtime = @import("../command_wrappers/runtime.zig");
const selectors_add_sub = @import("dispatch_selectors_add_sub.zig");
const selectors_mul_div = @import("dispatch_selectors_mul_div.zig");

const BranchFn = selectors_add_sub.BranchFn;
const no_register = @as(runtime.calcRegister_t, -1);

fn tryRemainingArithmetic(select_branch: *const fn (u32, u32) ?BranchFn) bool {
    const branch = select_branch(runtime.getRegisterDataType(runtime.REGISTER_Y), runtime.getRegisterDataType(runtime.REGISTER_X)) orelse return false;

    if (!runtime.saveLastX()) {
        return true;
    }

    branch();
    runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, runtime.REGISTER_Y, no_register);
    return true;
}

fn tryRemainingDivide() bool {
    const branch = selectors_mul_div.selectDivideBranch(runtime.getRegisterDataType(runtime.REGISTER_Y), runtime.getRegisterDataType(runtime.REGISTER_X)) orelse return false;

    runtime.copySourceRegisterToDestRegister(runtime.REGISTER_X, runtime.REGISTER_L);
    branch();
    runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, runtime.REGISTER_Y, no_register);
    return true;
}

pub fn tryRemainingAdd() bool {
    return tryRemainingArithmetic(&selectors_add_sub.selectAddBranch);
}

pub fn tryRemainingSubtract() bool {
    return tryRemainingArithmetic(&selectors_add_sub.selectSubtractBranch);
}

pub fn tryRemainingMultiply() bool {
    return tryRemainingArithmetic(&selectors_mul_div.selectMultiplyBranch);
}

pub fn tryRemainingDivideDispatch() bool {
    return tryRemainingDivide();
}
