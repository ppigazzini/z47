pub const calcRegister_t = i16;
pub const rounding_t = c_int;
pub const trigType_t = c_int;

pub const REGISTER_X: calcRegister_t = 100;
pub const REGISTER_Y: calcRegister_t = 101;

pub const DEC_ROUND_CEILING: rounding_t = 0;
pub const DEC_ROUND_FLOOR: rounding_t = 6;

pub const trigCos: trigType_t = 1;

pub const VoidCallback = ?*const fn () callconv(.c) void;

pub extern fn saveLastX() bool;
pub extern fn registerMin(regist1: calcRegister_t, regist2: calcRegister_t, dest: calcRegister_t) void;
pub extern fn registerMax(regist1: calcRegister_t, regist2: calcRegister_t, dest: calcRegister_t) void;
pub extern fn adjustResult(
    res: calcRegister_t,
    drop_y: bool,
    set_cpx_res: bool,
    op1: calcRegister_t,
    op2: calcRegister_t,
    op3: calcRegister_t,
) void;

pub extern fn processRealComplexMonadicFunction(realf: VoidCallback, complexf: VoidCallback) void;
pub extern fn processIntRealComplexMonadicFunction(
    realf: VoidCallback,
    complexf: VoidCallback,
    shortintf: VoidCallback,
    longintf: VoidCallback,
) void;

pub extern fn integerPartNoOp() void;
pub extern fn integerPartReal(mode: rounding_t) void;
pub extern fn integerPartCplx(mode: rounding_t) void;

pub extern fn sinhCoshReal(trig_type: trigType_t) void;
pub extern fn sinhCoshCplx(trig_type: trigType_t) void;
