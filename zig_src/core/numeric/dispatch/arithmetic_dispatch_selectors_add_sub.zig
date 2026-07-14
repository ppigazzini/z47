const runtime = @import("command_wrappers_runtime.zig");

pub const BranchFn = *const fn () callconv(.c) void;

pub fn selectAddBranch(type_y: u32, type_x: u32) ?BranchFn {
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

pub fn selectSubtractBranch(type_y: u32, type_x: u32) ?BranchFn {
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
