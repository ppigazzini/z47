pub const calcRegister_t = i16;

pub const REGISTER_X: calcRegister_t = 100;
pub const SOLVER_STATUS_READY_TO_EXECUTE: u16 = 0x0001;

pub extern var currentSolverStatus: u16;

pub extern fn liftStack() void;
pub extern fn adjustResult(
    res: calcRegister_t,
    drop_y: bool,
    set_cpx_res: bool,
    op1: calcRegister_t,
    op2: calcRegister_t,
    op3: calcRegister_t,
) void;
pub extern fn setLastintegerBasetoZero() void;

extern fn z47_constants_runtime_validate_constant(constant: u16) bool;
extern fn z47_constants_runtime_store_constant_in_x(constant: u16) void;
extern fn z47_constants_runtime_store_pi_in_x() void;

pub inline fn validateConstant(constant: u16) bool {
    return z47_constants_runtime_validate_constant(constant);
}

pub inline fn storeConstantInX(constant: u16) void {
    z47_constants_runtime_store_constant_in_x(constant);
}

pub inline fn storePiInX() void {
    z47_constants_runtime_store_pi_in_x();
}

pub inline fn setLastIntegerBaseToZero() void {
    setLastintegerBasetoZero();
}
