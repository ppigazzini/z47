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

const ClearSetPair = struct {
    clear_config: u16,
    set_config: u16,
    flag: u16,
};

const clear_set_pairs = [_]ClearSetPair{
    .{ .clear_config = runtime.TF_H12, .set_config = runtime.TF_H24, .flag = runtime.FLAG_TDM24 },
    .{ .clear_config = runtime.CU_I, .set_config = runtime.CU_J, .flag = runtime.FLAG_CPXj },
    .{ .clear_config = runtime.PS_DOT, .set_config = runtime.PS_CROSS, .flag = runtime.FLAG_MULTx },
    .{ .clear_config = runtime.SS_4, .set_config = runtime.SS_8, .flag = runtime.FLAG_SSIZE8 },
    .{ .clear_config = runtime.CM_RECTANGULAR, .set_config = runtime.CM_POLAR, .flag = runtime.FLAG_POLAR },
    .{ .clear_config = runtime.DO_SCI, .set_config = runtime.DO_ENG, .flag = runtime.FLAG_ENGOVR },
};

const flip_flags = [_]u16{
    runtime.FLAG_HPRP,
    runtime.FLAG_MNUp1,
    runtime.FLAG_HPBASE,
    runtime.FLAG_2TO10,
    runtime.FLAG_AMORT_HP12C,
    runtime.FLAG_PROPFR,
    runtime.FLAG_PRTACT,
    runtime.FLAG_LEAD0,
    runtime.FLAG_CPXRES,
    runtime.FLAG_SPCRES,
    runtime.FLAG_ERPN,
    runtime.FLAG_CARRY,
    runtime.FLAG_OVERFLOW,
    runtime.FLAG_FRCYC,
    runtime.FLAG_CPXMULT,
    runtime.FLAG_CPXPLOT,
    runtime.FLAG_SHOWX,
    runtime.FLAG_SHOWY,
    runtime.FLAG_PBOX,
    runtime.FLAG_PCURVE,
    runtime.FLAG_PCROS,
    runtime.FLAG_PPLUS,
    runtime.FLAG_PLINE,
    runtime.FLAG_SCALE,
    runtime.FLAG_VECT,
    runtime.FLAG_NVECT,
    runtime.FLAG_TOPHEX,
    runtime.FLAG_BCD,
    runtime.FLAG_LARGELI,
    runtime.FLAG_FRACT,
    runtime.FLAG_IRFRAC,
    runtime.FLAG_G_DOUBLETAP,
    runtime.FLAG_SHFT_4s,
    runtime.FLAG_FGGR,
    runtime.FLAG_TRACE,
    runtime.FLAG_NORM,
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

fn isWriteProtectedSystemFlag(flag: u16) bool {
    return (flag & 0x4000) != 0;
}

fn setUserFlag(flag: u16) void {
    if (flag <= runtime.FLAG_K) {
        const index: usize = @intCast(flag / 16);
        const shift: u4 = @intCast(flag % 16);
        runtime.globalFlags[index] |= @as(u16, 1) << shift;
        return;
    }

    if (flag <= runtime.LAST_LOCAL_FLAG) {
        if (runtime.currentLocalFlags != null) {
            const local_flag = flag - runtime.NUMBER_OF_GLOBAL_FLAGS;
            if (local_flag < runtime.NUMBER_OF_LOCAL_FLAGS) {
                const shift: u5 = @intCast(local_flag);
                runtime.currentLocalFlags[0] |= @as(u32, 1) << shift;
            }
        }
        return;
    }

    if (flag >= runtime.FLAG_M and flag <= runtime.FLAG_W) {
        const extra_flag = flag - 99;
        const index: usize = @intCast(extra_flag / 16);
        const shift: u4 = @intCast(extra_flag % 16);
        runtime.globalFlags[index] |= @as(u16, 1) << shift;
    }
}

fn clearUserFlag(flag: u16) void {
    if (flag <= runtime.FLAG_K) {
        const index: usize = @intCast(flag / 16);
        const shift: u4 = @intCast(flag % 16);
        runtime.globalFlags[index] &= ~(@as(u16, 1) << shift);
        return;
    }

    if (flag <= runtime.LAST_LOCAL_FLAG) {
        if (runtime.currentLocalFlags != null) {
            const local_flag = flag - runtime.NUMBER_OF_GLOBAL_FLAGS;
            if (local_flag < runtime.NUMBER_OF_LOCAL_FLAGS) {
                const shift: u5 = @intCast(local_flag);
                runtime.currentLocalFlags[0] &= ~(@as(u32, 1) << shift);
            }
        }
        return;
    }

    if (flag >= runtime.FLAG_M and flag <= runtime.FLAG_W) {
        const extra_flag = flag - 99;
        const index: usize = @intCast(extra_flag / 16);
        const shift: u4 = @intCast(extra_flag % 16);
        runtime.globalFlags[index] &= ~(@as(u16, 1) << shift);
    }
}

fn flipUserFlag(flag: u16) void {
    if (flag <= runtime.FLAG_K) {
        const index: usize = @intCast(flag / 16);
        const shift: u4 = @intCast(flag % 16);
        runtime.globalFlags[index] ^= @as(u16, 1) << shift;
        return;
    }

    if (flag <= runtime.LAST_LOCAL_FLAG) {
        if (runtime.currentLocalFlags != null) {
            const local_flag = flag - runtime.NUMBER_OF_GLOBAL_FLAGS;
            if (local_flag < runtime.NUMBER_OF_LOCAL_FLAGS) {
                const shift: u5 = @intCast(local_flag);
                runtime.currentLocalFlags[0] ^= @as(u32, 1) << shift;
            }
        }
        return;
    }

    if (flag >= runtime.FLAG_M and flag <= runtime.FLAG_W) {
        const extra_flag = flag - 99;
        const index: usize = @intCast(extra_flag / 16);
        const shift: u4 = @intCast(extra_flag % 16);
        runtime.globalFlags[index] ^= @as(u16, 1) << shift;
    }
}

fn setTemporaryInformationTrueFalse(condition: bool) void {
    runtime.temporaryInformation = runtime.TI_FALSE + @as(u8, @intFromBool(condition));
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

pub export fn getFlag(flag: u16) bool {
    if (builtin.target.os.tag == .freestanding) {
        return false;
    }

    if ((flag & 0x8000) != 0) {
        return getSystemFlag(@as(i32, @intCast(flag)));
    }

    if (flag <= runtime.FLAG_K) {
        const index: usize = @intCast(flag / 16);
        const shift: u4 = @intCast(flag % 16);
        return (runtime.globalFlags[index] & (@as(u16, 1) << shift)) != 0;
    }

    if (flag <= runtime.LAST_LOCAL_FLAG) {
        if (runtime.currentLocalFlags != null) {
            const local_flag = flag - runtime.NUMBER_OF_GLOBAL_FLAGS;
            if (local_flag < runtime.NUMBER_OF_LOCAL_FLAGS) {
                const shift: u5 = @intCast(local_flag);
                return (runtime.currentLocalFlags[0] & (@as(u32, 1) << shift)) != 0;
            }
        }

        return false;
    }

    if (flag >= runtime.FLAG_M and flag <= runtime.FLAG_W) {
        const extra_flag = flag - 99;
        const index: usize = @intCast(extra_flag / 16);
        const shift: u4 = @intCast(extra_flag % 16);
        return (runtime.globalFlags[index] & (@as(u16, 1) << shift)) != 0;
    }

    return false;
}

pub export fn fnGetSystemFlag(system_flag: u16) void {
    runtime.temporaryInformation = if (getSystemFlag(@as(i32, @intCast(system_flag))))
        runtime.TI_TRUE
    else
        runtime.TI_FALSE;
}

pub export fn fnSetFlag(flag: u16) void {
    if ((flag & 0x8000) != 0) {
        if (isWriteProtectedSystemFlag(flag)) {
            runtime.handleWriteProtectedFlag();
        } else if (flag == runtime.FLAG_ALPHA) {
            runtime.leaveTamModeIfEnabled();
            runtime.enterAlphaMode();
        } else {
            setSystemFlag(flag);
        }
        return;
    }

    setUserFlag(flag);
}

pub export fn fnClearFlag(flag: u16) void {
    if ((flag & 0x8000) != 0) {
        if (isWriteProtectedSystemFlag(flag)) {
            runtime.handleWriteProtectedFlag();
        } else if (flag == runtime.FLAG_ALPHA) {
            runtime.leaveTamModeIfEnabled();
            runtime.leaveAlphaMode();
        } else {
            clearSystemFlag(flag);
        }
        return;
    }

    clearUserFlag(flag);
}

pub export fn fnFlipFlag(flag: u16) void {
    if ((flag & 0x8000) != 0) {
        if (isWriteProtectedSystemFlag(flag)) {
            runtime.handleWriteProtectedFlag();
        } else if (flag == runtime.FLAG_ALPHA) {
            runtime.leaveTamModeIfEnabled();
            if (getSystemFlag(@as(i32, @intCast(runtime.FLAG_ALPHA)))) {
                runtime.leaveAlphaMode();
            } else {
                runtime.enterAlphaMode();
            }
        } else {
            flipSystemFlag(flag);
        }
        return;
    }

    flipUserFlag(flag);
}

pub export fn fnClFAll(confirmation: u16) void {
    if (confirmation == runtime.NOT_CONFIRMED and runtime.programRunStop != runtime.PGM_RUNNING) {
        runtime.requestClFAllConfirmation();
        return;
    }

    for (&runtime.globalFlags) |*entry| {
        entry.* = 0;
    }

    if (runtime.currentLocalFlags != null) {
        runtime.currentLocalFlags[0] = 0;
    }

    runtime.temporaryInformation = if (runtime.programRunStop != runtime.PGM_RUNNING)
        runtime.TI_CLEAR_ALL_FLAGS
    else
        runtime.TI_NO_INFO;
    runtime.screenUpdatingMode = runtime.SCRUPD_AUTO;
}

pub export fn fnIsFlagClear(flag: u16) void {
    setTemporaryInformationTrueFalse(!getFlag(flag));
}

pub export fn fnIsFlagSet(flag: u16) void {
    setTemporaryInformationTrueFalse(getFlag(flag));
}

pub export fn fnIsFlagClearClear(flag: u16) void {
    setTemporaryInformationTrueFalse(!getFlag(flag));
    fnClearFlag(flag);
}

pub export fn fnIsFlagSetClear(flag: u16) void {
    setTemporaryInformationTrueFalse(getFlag(flag));
    fnClearFlag(flag);
}

pub export fn fnIsFlagClearSet(flag: u16) void {
    setTemporaryInformationTrueFalse(!getFlag(flag));
    fnSetFlag(flag);
}

pub export fn fnIsFlagSetSet(flag: u16) void {
    setTemporaryInformationTrueFalse(getFlag(flag));
    fnSetFlag(flag);
}

pub export fn fnIsFlagClearFlip(flag: u16) void {
    setTemporaryInformationTrueFalse(!getFlag(flag));
    fnFlipFlag(flag);
}

pub export fn fnIsFlagSetFlip(flag: u16) void {
    setTemporaryInformationTrueFalse(getFlag(flag));
    fnFlipFlag(flag);
}

pub export fn SetSetting(jm_config: u16) void {
    for (clear_set_pairs) |pair| {
        if (jm_config == pair.clear_config) {
            fnClearFlag(pair.flag);
            runtime.fnRefreshState();
            return;
        }

        if (jm_config == pair.set_config) {
            fnSetFlag(pair.flag);
            runtime.fnRefreshState();
            return;
        }
    }

    for (flip_flags) |flag| {
        if (jm_config == flag) {
            fnFlipFlag(jm_config);
            runtime.fnRefreshState();
            return;
        }
    }

    switch (jm_config) {
        runtime.JC_NL => {
            fnFlipFlag(runtime.FLAG_NUMLOCK);
            runtime.showAlphaModeonGui();
        },
        runtime.FLAG_DENANY => {
            fnFlipFlag(jm_config);
            clearSystemFlag(runtime.FLAG_DENFIX);
        },
        runtime.FLAG_DENFIX => {
            fnFlipFlag(jm_config);
            clearSystemFlag(runtime.FLAG_DENANY);
        },
        runtime.FLAG_HOME_TRIPLE => {
            fnFlipFlag(jm_config);
            if (getSystemFlag(@as(i32, @intCast(runtime.FLAG_HOME_TRIPLE)))) {
                clearSystemFlag(runtime.FLAG_MYM_TRIPLE);
            }
        },
        runtime.FLAG_MYM_TRIPLE => {
            fnFlipFlag(jm_config);
            if (getSystemFlag(@as(i32, @intCast(runtime.FLAG_MYM_TRIPLE)))) {
                clearSystemFlag(runtime.FLAG_HOME_TRIPLE);
            }
        },
        runtime.FLAG_BASE_MYM => {
            fnFlipFlag(jm_config);
            if (getSystemFlag(@as(i32, @intCast(runtime.FLAG_BASE_MYM)))) {
                clearSystemFlag(runtime.FLAG_BASE_HOME);
            }
        },
        runtime.FLAG_BASE_HOME => {
            fnFlipFlag(jm_config);
            if (getSystemFlag(@as(i32, @intCast(runtime.FLAG_BASE_HOME)))) {
                clearSystemFlag(runtime.FLAG_BASE_MYM);
            }
        },
        runtime.FLAG_FGLNFUL => {
            fnFlipFlag(jm_config);
            if (getSystemFlag(@as(i32, @intCast(runtime.FLAG_FGLNFUL)))) {
                clearSystemFlag(runtime.FLAG_FGLNLIM);
            }
        },
        runtime.FLAG_FGLNLIM => {
            fnFlipFlag(jm_config);
            if (getSystemFlag(@as(i32, @intCast(runtime.FLAG_FGLNLIM)))) {
                clearSystemFlag(runtime.FLAG_FGLNFUL);
            }
        },
        runtime.ITM_DREAL => fnFlipFlag(runtime.FLAG_DREAL),
        runtime.JC_UC => {
            runtime.alphaCase = if (runtime.alphaCase == runtime.AC_LOWER)
                runtime.AC_UPPER
            else
                runtime.AC_LOWER;
        },
        runtime.JC_SS => {
            runtime.scrLock = switch (runtime.scrLock) {
                runtime.NC_NORMAL => runtime.NC_SUBSCRIPT,
                runtime.NC_SUBSCRIPT => runtime.NC_SUPERSCRIPT,
                runtime.NC_SUPERSCRIPT => runtime.NC_NORMAL,
                else => runtime.NC_NORMAL,
            };
            runtime.nextChar = runtime.scrLock;
            runtime.showAlphaModeonGui();
        },
        else => {},
    }

    runtime.fnRefreshState();
}
