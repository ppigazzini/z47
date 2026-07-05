const runtime = @import("math_command_wrappers_runtime.zig");

pub const BranchFn = *const fn () callconv(.c) void;

pub fn selectMultiplyBranch(type_y: u32, type_x: u32) ?BranchFn {
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

pub fn selectDivideBranch(type_y: u32, type_x: u32) ?BranchFn {
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
