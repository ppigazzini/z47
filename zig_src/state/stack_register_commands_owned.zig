const runtime = @import("stack_runtime.zig");

pub fn regClr() void {
    var s: u16 = 0;
    var n: u16 = 0;

    runtime.lastErrorCode = runtime.getRegClrRangeRetained(&s, &n);
    if (runtime.lastErrorCode == runtime.ERROR_NONE) {
        var reg = s;
        while (reg < s + n) : (reg += 1) {
            runtime.clearRegister(@intCast(reg));
        }
        return;
    }

    runtime.reportRegisterCommandError(runtime.lastErrorCode);
}

pub fn regSwap() void {
    var s: u16 = 0;
    var n: u16 = 0;
    var d: u16 = 0;

    runtime.lastErrorCode = runtime.getRegSwapRangeRetained(&s, &n, &d);
    if (runtime.lastErrorCode != runtime.ERROR_NONE) {
        runtime.reportRegisterCommandError(runtime.lastErrorCode);
        return;
    }

    if (d < s + n and s < d + n) {
        runtime.reportRegisterCommandError(runtime.ERROR_OUT_OF_RANGE);
        return;
    }

    var index: u16 = 0;
    while (index < n) : (index += 1) {
        const src = @as(runtime.calcRegister_t, @intCast(s + index));
        const dst = @as(runtime.calcRegister_t, @intCast(d + index));
        const saved_descriptor = runtime.globalDescriptor(src);
        runtime.setGlobalDescriptor(src, runtime.globalDescriptor(dst));
        runtime.setGlobalDescriptor(dst, saved_descriptor);
    }
}

pub fn regCopy(unused_but_mandatory_parameter: u16) void {
    var f = false;
    var s: u16 = 0;
    var n: u16 = 0;
    var d: u16 = 0;

    runtime.lastErrorCode = runtime.getRegCopyParamsRetained(&f, &s, &n, &d);
    if (runtime.lastErrorCode != runtime.ERROR_NONE) {
        runtime.reportRegisterCommandError(runtime.lastErrorCode);
        return;
    }

    if (f) {
        _ = unused_but_mandatory_parameter;
        runtime.doPartialRegisterLoad(s, n, d);
        return;
    }

    if (s > d) {
        var index: u16 = 0;
        while (index < n) : (index += 1) {
            runtime.copySourceRegisterToDestRegister(
                @as(runtime.calcRegister_t, @intCast(s + index)),
                @as(runtime.calcRegister_t, @intCast(d + index)),
            );
            if (runtime.lastErrorCode == runtime.ERROR_RAM_FULL) {
                return;
            }
        }
        return;
    }

    if (s < d) {
        var index = n;
        while (index > 0) {
            index -= 1;
            runtime.copySourceRegisterToDestRegister(
                @as(runtime.calcRegister_t, @intCast(s + index)),
                @as(runtime.calcRegister_t, @intCast(d + index)),
            );
            if (runtime.lastErrorCode == runtime.ERROR_RAM_FULL) {
                return;
            }
        }
    }
}

pub fn regSort() void {
    var s: u16 = 0;
    var n: u16 = 0;

    runtime.lastErrorCode = runtime.getRegClrRangeRetained(&s, &n);
    if (runtime.lastErrorCode != runtime.ERROR_NONE) {
        runtime.reportRegisterCommandError(runtime.lastErrorCode);
        return;
    }

    switch (runtime.getRegisterDataType(@as(runtime.calcRegister_t, @intCast(s)))) {
        runtime.dtLongInteger, runtime.dtShortInteger, runtime.dtReal34 => {
            var index: u16 = s + 1;
            while (index < s + n) : (index += 1) {
                const data_type = runtime.getRegisterDataType(@as(runtime.calcRegister_t, @intCast(index)));
                if (data_type != runtime.dtLongInteger and data_type != runtime.dtShortInteger and data_type != runtime.dtReal34) {
                    runtime.reportRegisterCommandError(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP);
                    return;
                }
            }
        },
        runtime.dtTime, runtime.dtDate, runtime.dtString => {
            const first_type = runtime.getRegisterDataType(@as(runtime.calcRegister_t, @intCast(s)));
            var index: u16 = s + 1;
            while (index < s + n) : (index += 1) {
                if (runtime.getRegisterDataType(@as(runtime.calcRegister_t, @intCast(index))) != first_type) {
                    runtime.reportRegisterCommandError(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP);
                    return;
                }
            }
        },
        else => {},
    }

    if (runtime.lastErrorCode == runtime.ERROR_NONE) {
        runtime.sortRegisterRange(s, s + n - 1);
    }
}