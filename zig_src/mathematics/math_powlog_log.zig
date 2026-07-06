const runtime = @import("math_command_wrappers_runtime.zig");

fn log2LonI() callconv(.c) void {
    runtime.logxyLonI(runtime.z47_math_wrappers_const_ln2());
}

fn log2ShoI() callconv(.c) void {
    runtime.registerShortIntegerPtr(runtime.REGISTER_X).* = runtime.WP34S_intLog2(
        runtime.registerShortIntegerPtr(runtime.REGISTER_X).*,
    );
}

fn log2Real() callconv(.c) void {
    runtime.logxyReal(runtime.z47_math_wrappers_const_ln2());
}

fn log2Cplx() callconv(.c) void {
    runtime.logxyCplx(runtime.z47_math_wrappers_const_ln2());
}

fn log10LonI() callconv(.c) void {
    runtime.logxyLonI(runtime.z47_math_wrappers_const_ln10());
}

fn log10ShoI() callconv(.c) void {
    runtime.registerShortIntegerPtr(runtime.REGISTER_X).* = runtime.WP34S_intLog10(
        runtime.registerShortIntegerPtr(runtime.REGISTER_X).*,
    );
}

fn log10Real() callconv(.c) void {
    runtime.logxyReal(runtime.z47_math_wrappers_const_ln10());
}

fn log10Cplx() callconv(.c) void {
    runtime.logxyCplx(runtime.z47_math_wrappers_const_ln10());
}

pub fn fnLog10(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    runtime.processIntRealComplexMonadicFunction(&log10Real, &log10Cplx, &log10ShoI, &log10LonI);
}

pub fn fnLog2(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    runtime.processIntRealComplexMonadicFunction(&log2Real, &log2Cplx, &log2ShoI, &log2LonI);
}
