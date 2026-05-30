const runtime = @import("math_command_wrappers_runtime.zig");

const BranchFn = *const fn () callconv(.c) void;
const no_register = @as(runtime.calcRegister_t, -1);

fn selectRemainingAddBranch(type_y: u32, type_x: u32) ?BranchFn {
    return switch (type_y) {
        runtime.dtLongInteger => switch (type_x) {
            runtime.dtTime => &runtime.addLonITime,
            runtime.dtDate => &runtime.addLonIDate,
            runtime.dtComplex34 => &runtime.addLonICplx,
            runtime.dtReal34Matrix => &runtime.addLonIRema,
            runtime.dtComplex34Matrix => &runtime.addLonICxma,
            else => null,
        },
        runtime.dtShortInteger => switch (type_x) {
            runtime.dtComplex34 => &runtime.addShoICplx,
            runtime.dtReal34Matrix => &runtime.addShoIRema,
            runtime.dtComplex34Matrix => &runtime.addShoICxma,
            else => null,
        },
        runtime.dtReal34 => switch (type_x) {
            runtime.dtTime => &runtime.addRealTime,
            runtime.dtDate => &runtime.addRealDate,
            runtime.dtComplex34 => &runtime.addRealCplx,
            runtime.dtReal34Matrix => &runtime.addRealRema,
            runtime.dtComplex34Matrix => &runtime.addRealCxma,
            else => null,
        },
        runtime.dtComplex34 => switch (type_x) {
            runtime.dtLongInteger => &runtime.addCplxLonI,
            runtime.dtShortInteger => &runtime.addCplxShoI,
            runtime.dtReal34 => &runtime.addCplxReal,
            runtime.dtComplex34 => &runtime.addCplxCplx,
            runtime.dtReal34Matrix => &runtime.addCplxRema,
            runtime.dtComplex34Matrix => &runtime.addCplxCxma,
            else => null,
        },
        runtime.dtTime => switch (type_x) {
            runtime.dtLongInteger => &runtime.addTimeLonI,
            runtime.dtTime => &runtime.addTimeTime,
            runtime.dtReal34 => &runtime.addTimeReal,
            else => null,
        },
        runtime.dtDate => switch (type_x) {
            runtime.dtLongInteger => &runtime.addDateLonI,
            runtime.dtReal34 => &runtime.addDateReal,
            else => null,
        },
        runtime.dtReal34Matrix => switch (type_x) {
            runtime.dtLongInteger => &runtime.addRemaLonI,
            runtime.dtShortInteger => &runtime.addRemaShoI,
            runtime.dtReal34 => &runtime.addRemaReal,
            runtime.dtComplex34 => &runtime.addRemaCplx,
            runtime.dtReal34Matrix => &runtime.addRemaRema,
            runtime.dtComplex34Matrix => &runtime.addRemaCxma,
            else => null,
        },
        runtime.dtComplex34Matrix => switch (type_x) {
            runtime.dtLongInteger => &runtime.addCxmaLonI,
            runtime.dtShortInteger => &runtime.addCxmaShoI,
            runtime.dtReal34 => &runtime.addCxmaReal,
            runtime.dtComplex34 => &runtime.addCxmaCplx,
            runtime.dtReal34Matrix => &runtime.addCxmaRema,
            runtime.dtComplex34Matrix => &runtime.addCxmaCxma,
            else => null,
        },
        else => null,
    };
}

fn selectRemainingSubtractBranch(type_y: u32, type_x: u32) ?BranchFn {
    return switch (type_y) {
        runtime.dtLongInteger => switch (type_x) {
            runtime.dtTime => &runtime.subLonITime,
            runtime.dtComplex34 => &runtime.subLonICplx,
            runtime.dtReal34Matrix => &runtime.subLonIRema,
            runtime.dtComplex34Matrix => &runtime.subLonICxma,
            else => null,
        },
        runtime.dtShortInteger => switch (type_x) {
            runtime.dtComplex34 => &runtime.subShoICplx,
            runtime.dtReal34Matrix => &runtime.subShoIRema,
            runtime.dtComplex34Matrix => &runtime.subShoICxma,
            else => null,
        },
        runtime.dtReal34 => switch (type_x) {
            runtime.dtTime => &runtime.subRealTime,
            runtime.dtComplex34 => &runtime.subRealCplx,
            runtime.dtReal34Matrix => &runtime.subRealRema,
            runtime.dtComplex34Matrix => &runtime.subRealCxma,
            else => null,
        },
        runtime.dtComplex34 => switch (type_x) {
            runtime.dtLongInteger => &runtime.subCplxLonI,
            runtime.dtShortInteger => &runtime.subCplxShoI,
            runtime.dtReal34 => &runtime.subCplxReal,
            runtime.dtComplex34 => &runtime.subCplxCplx,
            runtime.dtReal34Matrix => &runtime.subCplxRema,
            runtime.dtComplex34Matrix => &runtime.subCplxCxma,
            else => null,
        },
        runtime.dtTime => switch (type_x) {
            runtime.dtLongInteger => &runtime.subTimeLonI,
            runtime.dtTime => &runtime.subTimeTime,
            runtime.dtReal34 => &runtime.subTimeReal,
            else => null,
        },
        runtime.dtDate => switch (type_x) {
            runtime.dtLongInteger => &runtime.subDateLonI,
            runtime.dtDate => &runtime.subDateDate,
            runtime.dtReal34 => &runtime.subDateReal,
            else => null,
        },
        runtime.dtReal34Matrix => switch (type_x) {
            runtime.dtLongInteger => &runtime.subRemaLonI,
            runtime.dtShortInteger => &runtime.subRemaShoI,
            runtime.dtReal34 => &runtime.subRemaReal,
            runtime.dtComplex34 => &runtime.subRemaCplx,
            runtime.dtReal34Matrix => &runtime.subRemaRema,
            runtime.dtComplex34Matrix => &runtime.subRemaCxma,
            else => null,
        },
        runtime.dtComplex34Matrix => switch (type_x) {
            runtime.dtLongInteger => &runtime.subCxmaLonI,
            runtime.dtShortInteger => &runtime.subCxmaShoI,
            runtime.dtReal34 => &runtime.subCxmaReal,
            runtime.dtComplex34 => &runtime.subCxmaCplx,
            runtime.dtReal34Matrix => &runtime.subCxmaRema,
            runtime.dtComplex34Matrix => &runtime.subCxmaCxma,
            else => null,
        },
        else => null,
    };
}

fn selectRemainingMultiplyBranch(type_y: u32, type_x: u32) ?BranchFn {
    return switch (type_y) {
        runtime.dtLongInteger => switch (type_x) {
            runtime.dtTime => &runtime.mulLonITime,
            runtime.dtComplex34 => &runtime.mulLonICplx,
            runtime.dtReal34Matrix => &runtime.mulLonIRema,
            runtime.dtComplex34Matrix => &runtime.mulLonICxma,
            else => null,
        },
        runtime.dtShortInteger => switch (type_x) {
            runtime.dtTime => &runtime.mulShoITime,
            runtime.dtComplex34 => &runtime.mulShoICplx,
            runtime.dtReal34Matrix => &runtime.mulShoIRema,
            runtime.dtComplex34Matrix => &runtime.mulShoICxma,
            else => null,
        },
        runtime.dtReal34 => switch (type_x) {
            runtime.dtTime => &runtime.mulRealTime,
            runtime.dtComplex34 => &runtime.mulRealCplx,
            runtime.dtReal34Matrix => &runtime.mulRealRema,
            runtime.dtComplex34Matrix => &runtime.mulRealCxma,
            else => null,
        },
        runtime.dtComplex34 => switch (type_x) {
            runtime.dtLongInteger => &runtime.mulCplxLonI,
            runtime.dtShortInteger => &runtime.mulCplxShoI,
            runtime.dtReal34 => &runtime.mulCplxReal,
            runtime.dtComplex34 => &runtime.mulCplxCplx,
            runtime.dtReal34Matrix => &runtime.mulCplxRema,
            runtime.dtComplex34Matrix => &runtime.mulCplxCxma,
            else => null,
        },
        runtime.dtTime => switch (type_x) {
            runtime.dtLongInteger => &runtime.mulTimeLonI,
            runtime.dtShortInteger => &runtime.mulTimeShoI,
            runtime.dtReal34 => &runtime.mulTimeReal,
            else => null,
        },
        runtime.dtReal34Matrix => switch (type_x) {
            runtime.dtLongInteger => &runtime.mulRemaLonI,
            runtime.dtShortInteger => &runtime.mulRemaShoI,
            runtime.dtReal34 => &runtime.mulRemaReal,
            runtime.dtComplex34 => &runtime.mulRemaCplx,
            runtime.dtReal34Matrix => &runtime.mulRemaRema,
            runtime.dtComplex34Matrix => &runtime.mulRemaCxma,
            else => null,
        },
        runtime.dtComplex34Matrix => switch (type_x) {
            runtime.dtLongInteger => &runtime.mulCxmaLonI,
            runtime.dtShortInteger => &runtime.mulCxmaShoI,
            runtime.dtReal34 => &runtime.mulCxmaReal,
            runtime.dtComplex34 => &runtime.mulCxmaCplx,
            runtime.dtReal34Matrix => &runtime.mulCxmaRema,
            runtime.dtComplex34Matrix => &runtime.mulCxmaCxma,
            else => null,
        },
        else => null,
    };
}

fn selectRemainingDivideBranch(type_y: u32, type_x: u32) ?BranchFn {
    return switch (type_y) {
        runtime.dtLongInteger => switch (type_x) {
            runtime.dtTime => &runtime.divLonITime,
            runtime.dtComplex34 => &runtime.divLonICplx,
            runtime.dtReal34Matrix => &runtime.divLonIRema,
            runtime.dtComplex34Matrix => &runtime.divLonICxma,
            else => null,
        },
        runtime.dtShortInteger => switch (type_x) {
            runtime.dtTime => &runtime.divShoITime,
            runtime.dtComplex34 => &runtime.divShoICplx,
            runtime.dtReal34Matrix => &runtime.divShoIRema,
            runtime.dtComplex34Matrix => &runtime.divShoICxma,
            else => null,
        },
        runtime.dtReal34 => switch (type_x) {
            runtime.dtTime => &runtime.divRealTime,
            runtime.dtComplex34 => &runtime.divRealCplx,
            runtime.dtReal34Matrix => &runtime.divRealRema,
            runtime.dtComplex34Matrix => &runtime.divRealCxma,
            else => null,
        },
        runtime.dtComplex34 => switch (type_x) {
            runtime.dtLongInteger => &runtime.divCplxLonI,
            runtime.dtShortInteger => &runtime.divCplxShoI,
            runtime.dtReal34 => &runtime.divCplxReal,
            runtime.dtComplex34 => &runtime.divCplxCplx,
            runtime.dtReal34Matrix => &runtime.divCplxRema,
            runtime.dtComplex34Matrix => &runtime.divCplxCxma,
            else => null,
        },
        runtime.dtTime => switch (type_x) {
            runtime.dtLongInteger => &runtime.divTimeLonI,
            runtime.dtShortInteger => &runtime.divTimeShoI,
            runtime.dtReal34 => &runtime.divTimeReal,
            runtime.dtTime => &runtime.divTimeTime,
            else => null,
        },
        runtime.dtReal34Matrix => switch (type_x) {
            runtime.dtLongInteger => &runtime.divRemaLonI,
            runtime.dtShortInteger => &runtime.divRemaShoI,
            runtime.dtReal34 => &runtime.divRemaReal,
            runtime.dtComplex34 => &runtime.divRemaCplx,
            runtime.dtReal34Matrix => &runtime.divRemaRema,
            runtime.dtComplex34Matrix => &runtime.divRemaCxma,
            else => null,
        },
        runtime.dtComplex34Matrix => switch (type_x) {
            runtime.dtLongInteger => &runtime.divCxmaLonI,
            runtime.dtShortInteger => &runtime.divCxmaShoI,
            runtime.dtReal34 => &runtime.divCxmaReal,
            runtime.dtComplex34 => &runtime.divCxmaCplx,
            runtime.dtReal34Matrix => &runtime.divCxmaRema,
            runtime.dtComplex34Matrix => &runtime.divCxmaCxma,
            else => null,
        },
        else => null,
    };
}

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
    const branch = selectRemainingDivideBranch(runtime.getRegisterDataType(runtime.REGISTER_Y), runtime.getRegisterDataType(runtime.REGISTER_X)) orelse return false;

    runtime.copySourceRegisterToDestRegister(runtime.REGISTER_X, runtime.REGISTER_L);
    branch();
    runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, runtime.REGISTER_Y, no_register);
    return true;
}

pub fn tryRemainingAdd() bool {
    return tryRemainingArithmetic(&selectRemainingAddBranch);
}

pub fn tryRemainingSubtract() bool {
    return tryRemainingArithmetic(&selectRemainingSubtractBranch);
}

pub fn tryRemainingMultiply() bool {
    return tryRemainingArithmetic(&selectRemainingMultiplyBranch);
}

pub fn tryRemainingDivideDispatch() bool {
    return tryRemainingDivide();
}
