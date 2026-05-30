const builtin = @import("builtin");
const io_flow_owned = @import("calc_state_io_flow_owned.zig");
const runtime = @import("calc_state_runtime.zig");

const is_dmcp_build = builtin.target.os.tag == .freestanding;

pub fn doLoad(load_mode: u16, s: u16, n: u16, d: u16, load_type: u16) void {
    if (is_dmcp_build) {
        runtime.doLoadRetained(load_mode, s, n, d, load_type);
        return;
    }

    io_flow_owned.doLoad(load_mode, s, n, d, load_type);
}

pub fn load(load_mode: u16) void {
    if (is_dmcp_build) {
        runtime.loadRetained(load_mode);
        return;
    }

    runtime.showLoadingStatus();
    if (load_mode == runtime.LM_STATE_LOAD) {
        doLoad(runtime.LM_ALL, 0, 0, 0, runtime.stateLoad);
    } else {
        doLoad(load_mode, 0, 0, 0, runtime.manualLoad);
    }
    runtime.finishLoadUi(94);
}

pub fn loadAuto() void {
    doLoad(runtime.LM_ALL, 0, 0, 0, runtime.autoLoad);
    runtime.finishLoadUi(95);
}

pub fn saveAuto(unused_but_mandatory_parameter: u16) void {
    if (is_dmcp_build) {
        runtime.saveAutoRetained(unused_but_mandatory_parameter);
        return;
    }
}

pub fn save(save_mode: u16) void {
    if (is_dmcp_build) {
        runtime.saveRetained(save_mode);
        return;
    }

    if (save_mode == runtime.SM_MANUAL_SAVE) {
        io_flow_owned.doSave(runtime.manualSave);
    } else if (save_mode == runtime.SM_STATE_SAVE) {
        io_flow_owned.doSave(runtime.stateSave);
    }
}