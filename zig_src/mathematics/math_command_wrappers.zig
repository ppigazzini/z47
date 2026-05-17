const runtime = @import("math_command_wrappers_runtime.zig");

const no_register = @as(runtime.calcRegister_t, -1);

fn ceilReal() callconv(.c) void {
    runtime.integerPartReal(runtime.DEC_ROUND_CEILING);
}

fn ceilCplx() callconv(.c) void {
    runtime.integerPartCplx(runtime.DEC_ROUND_CEILING);
}

fn floorReal() callconv(.c) void {
    runtime.integerPartReal(runtime.DEC_ROUND_FLOOR);
}

fn floorCplx() callconv(.c) void {
    runtime.integerPartCplx(runtime.DEC_ROUND_FLOOR);
}

fn integerPartNoOpForward() callconv(.c) void {
    runtime.integerPartNoOp();
}

fn coshReal() callconv(.c) void {
    runtime.sinhCoshReal(runtime.trigCos);
}

fn coshCplx() callconv(.c) void {
    runtime.sinhCoshCplx(runtime.trigCos);
}

pub export fn fnMin(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    if (!runtime.saveLastX()) {
        return;
    }

    runtime.registerMin(runtime.REGISTER_X, runtime.REGISTER_Y, runtime.REGISTER_X);
    runtime.adjustResult(runtime.REGISTER_X, true, false, runtime.REGISTER_X, no_register, no_register);
}

pub export fn fnMax(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    if (!runtime.saveLastX()) {
        return;
    }

    runtime.registerMax(runtime.REGISTER_X, runtime.REGISTER_Y, runtime.REGISTER_X);
    runtime.adjustResult(runtime.REGISTER_X, true, false, runtime.REGISTER_X, no_register, no_register);
}

pub export fn fnCeil(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexMonadicFunction(
        &ceilReal,
        &ceilCplx,
        &integerPartNoOpForward,
        &integerPartNoOpForward,
    );
}

pub export fn fnFloor(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexMonadicFunction(
        &floorReal,
        &floorCplx,
        &integerPartNoOpForward,
        &integerPartNoOpForward,
    );
}

pub export fn fnCosh(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&coshReal, &coshCplx);
}
