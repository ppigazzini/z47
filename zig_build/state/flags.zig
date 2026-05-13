const builtin = @import("builtin");
const runtime = @import("flags_runtime.zig");

pub export var systemFlags0Changed: u64 = ~@as(u64, 0);
pub export var systemFlags1Changed: u64 = ~@as(u64, 0);
pub export var systemFlags2Changed: u64 = ~@as(u64, 0);

const FlagAction = enum(u2) {
    clear = 0,
    set = 1,
    flip = 2,
};

fn needsRefreshState(system_flag: u16) bool {
    return switch (system_flag) {
        0x8000,
        0xc001,
        0xc002,
        0xc003,
        0x8004,
        0x8017,
        0x8005,
        0x8006,
        0x800d,
        0x8009,
        0x800a,
        0x8018,
        0x801b,
        0x801c,
        0xc029,
        0x802b,
        0x8056,
        0x803c,
        0x8043,
        0x8044,
        0x8045,
        0x800b,
        0x800c,
        0x8041,
        0x8046,
        0xc00f,
        0x803d,
        0x8011,
        0x804b,
        0x804c,
        0x804d,
        0x804e,
        0x805a,
        0x804f,
        0x8050,
        0x8051,
        0x8052,
        0x8053,
        0x8054,
        0x8058,
        0x8064,
        => true,
        else => false,
    };
}

fn needsClearStatusBar(system_flag: u16) bool {
    return switch (system_flag) {
        0x802c,
        0x802e,
        0x802f,
        0x8030,
        0x8032,
        0x8033,
        0x8034,
        0x8035,
        0x8036,
        0x8037,
        0x8038,
        0x8039,
        0x803a,
        0x803b,
        runtime.FLAG_SBfrac,
        runtime.FLAG_SBwoy,
        runtime.FLAG_SBtime,
        runtime.FLAG_FRACT,
        runtime.FLAG_IRFRAC,
        runtime.FLAG_IRFRQ,
        => true,
        else => false,
    };
}

fn maskedFlagFromSigned(sf: i32) i32 {
    return sf & 0x3fff;
}

fn maskedFlagFromUnsigned(sf: u16) i32 {
    return @as(i32, sf & 0x3fff);
}

fn setSystemFlagBit(system_flag: u16) void {
    const flag = maskedFlagFromUnsigned(system_flag);

    if (flag < 64) {
        const shift: u6 = @intCast(flag);
        const bit = @as(u64, 1) << shift;
        systemFlags0Changed |= ~runtime.systemFlags0 & bit;
        runtime.systemFlags0 |= bit;
    } else {
        const shift: u6 = @intCast(flag - 64);
        const bit = @as(u64, 1) << shift;
        systemFlags1Changed |= ~runtime.systemFlags1 & bit;
        runtime.systemFlags1 |= bit;
    }
}

fn clearSystemFlagBit(system_flag: u16) void {
    const flag = maskedFlagFromUnsigned(system_flag);

    if (flag < 64) {
        const shift: u6 = @intCast(flag);
        const bit = @as(u64, 1) << shift;
        systemFlags0Changed |= runtime.systemFlags0 & bit;
        runtime.systemFlags0 &= ~bit;
    } else {
        const shift: u6 = @intCast(flag - 64);
        const bit = @as(u64, 1) << shift;
        systemFlags1Changed |= runtime.systemFlags1 & bit;
        runtime.systemFlags1 &= ~bit;
    }
}

fn flipSystemFlagBit(system_flag: u16) void {
    const flag = maskedFlagFromUnsigned(system_flag);

    if (flag < 64) {
        const shift: u6 = @intCast(flag);
        const bit = @as(u64, 1) << shift;
        systemFlags0Changed |= bit;
        runtime.systemFlags0 ^= bit;
    } else {
        const shift: u6 = @intCast(flag - 64);
        const bit = @as(u64, 1) << shift;
        systemFlags1Changed |= bit;
        runtime.systemFlags1 ^= bit;
    }
}

fn systemFlagAction(system_flag: u16, action: FlagAction) void {
    if (needsRefreshState(system_flag)) {
        runtime.fnRefreshState();
    }

    if (needsClearStatusBar(system_flag)) {
        if (builtin.target.os.tag == .freestanding) {
            runtime.reallyClearStatusBar(201);
        }
        runtime.fnRefreshState();
        runtime.screenUpdatingMode &= ~@as(u8, runtime.SCRUPD_MANUAL_STATUSBAR);
    }

    if (system_flag == runtime.FLAG_BCD) {
        if (getSystemFlag(@intCast(system_flag)) and action != .clear and runtime.lastIntegerBase == 0) {
            runtime.fnChangeBaseJM(10);
        }
    }

    switch (system_flag) {
        runtime.FLAG_SBfrac => runtime.lastIntegerBase = 0,
        runtime.FLAG_SBwoy, runtime.FLAG_SBtime => {
            if (system_flag == runtime.FLAG_SBtime and getSystemFlag(@intCast(runtime.FLAG_SBtime))) {
                clearSystemFlagBit(runtime.FLAG_SBwoy);
            } else if (system_flag == runtime.FLAG_SBwoy and getSystemFlag(@intCast(runtime.FLAG_SBwoy))) {
                clearSystemFlagBit(runtime.FLAG_SBtime);
            }
        },
        runtime.FLAG_FRACT => {
            if (getSystemFlag(@intCast(runtime.FLAG_FRACT))) {
                clearSystemFlagBit(runtime.FLAG_IRFRAC);
                clearSystemFlagBit(runtime.FLAG_IRFRQ);
            }
        },
        runtime.FLAG_IRFRAC => {
            if (getSystemFlag(@intCast(runtime.FLAG_IRFRAC))) {
                clearSystemFlagBit(runtime.FLAG_FRACT);
                setSystemFlagBit(runtime.FLAG_IRFRQ);
            }
        },
        runtime.FLAG_IRFRQ => {
            if (getSystemFlag(@intCast(runtime.FLAG_FRACT))) {
                clearSystemFlagBit(runtime.FLAG_FRACT);
                setSystemFlagBit(runtime.FLAG_IRFRAC);
            }
        },
        else => {},
    }
}

pub export fn setSystemFlag(sf: u32) void {
    if (builtin.target.os.tag == .freestanding) {
        runtime.retainedSetSystemFlag(sf);
        return;
    }

    const system_flag: u16 = @intCast(sf & 0xffff);
    setSystemFlagBit(system_flag);
    systemFlagAction(system_flag, .set);
}

pub export fn clearSystemFlag(sf: u32) void {
    if (builtin.target.os.tag == .freestanding) {
        runtime.retainedClearSystemFlag(sf);
        return;
    }

    const system_flag: u16 = @intCast(sf & 0xffff);
    clearSystemFlagBit(system_flag);
    systemFlagAction(system_flag, .clear);
}

pub export fn flipSystemFlag(sf: u32) void {
    if (builtin.target.os.tag == .freestanding) {
        runtime.retainedFlipSystemFlag(sf);
        return;
    }

    const system_flag: u16 = @intCast(sf & 0xffff);
    flipSystemFlagBit(system_flag);
    systemFlagAction(system_flag, .flip);
}

pub export fn getSystemFlag(sf: i32) bool {
    if (builtin.target.os.tag == .freestanding) {
        return runtime.retainedGetSystemFlag(sf);
    }

    const flag = maskedFlagFromSigned(sf);

    if (flag < 64) {
        const shift: u6 = @intCast(flag);
        return (runtime.systemFlags0 & (@as(u64, 1) << shift)) != 0;
    }

    const shift: u6 = @intCast(flag - 64);
    return (runtime.systemFlags1 & (@as(u64, 1) << shift)) != 0;
}

pub export fn didSystemFlagChange(sf: i32) bool {
    if (builtin.target.os.tag == .freestanding) {
        return runtime.retainedDidSystemFlagChange(sf);
    }

    const flag = maskedFlagFromSigned(sf);

    if (flag < 64) {
        const shift: u6 = @intCast(flag);
        const bit = @as(u64, 1) << shift;
        const changed = (systemFlags0Changed & bit) != 0;
        systemFlags0Changed &= ~bit;
        return changed;
    }

    if (flag < 128) {
        const shift: u6 = @intCast(flag - 64);
        const bit = @as(u64, 1) << shift;
        const changed = (systemFlags1Changed & bit) != 0;
        systemFlags1Changed &= ~bit;
        return changed;
    }

    const shift: u6 = @intCast(flag - 128);
    const bit = @as(u64, 1) << shift;
    const changed = (systemFlags2Changed & bit) != 0;
    systemFlags2Changed &= ~bit;
    return changed;
}

pub export fn setSystemFlagChanged(sf: i32) void {
    if (builtin.target.os.tag == .freestanding) {
        runtime.retainedSetSystemFlagChanged(sf);
        return;
    }

    const flag = maskedFlagFromSigned(sf);

    if (flag < 64) {
        systemFlags0Changed |= @as(u64, 1) << @as(u6, @intCast(flag));
    } else if (flag < 128) {
        systemFlags1Changed |= @as(u64, 1) << @as(u6, @intCast(flag - 64));
    } else {
        systemFlags2Changed |= @as(u64, 1) << @as(u6, @intCast(flag - 128));
    }
}

pub export fn setAllSystemFlagChanged() void {
    if (builtin.target.os.tag == .freestanding) {
        runtime.retainedSetAllSystemFlagChanged();
        return;
    }

    systemFlags0Changed = ~@as(u64, 0);
    systemFlags1Changed = ~@as(u64, 0);
    systemFlags2Changed = ~@as(u64, 0);
}

pub export fn forceSystemFlag(sf: u32, set: c_int) void {
    if (builtin.target.os.tag == .freestanding) {
        runtime.retainedForceSystemFlag(sf, set);
        return;
    }

    if (set != 0) {
        setSystemFlag(sf);
    } else {
        clearSystemFlag(sf);
    }
}
