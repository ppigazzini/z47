const builtin = @import("builtin");
const io_flow_owned = @import("calc_state_io_flow_owned.zig");
const runtime = @import("calc_state_runtime.zig");

const is_dmcp_build = builtin.target.os.tag == .freestanding;


pub fn load(load_mode: u16, do_load: *const fn (load_mode: u16, s: u16, n: u16, d: u16, load_type: u16) void) void {
    runtime.showLoadingStatus();
    if (load_mode == runtime.LM_STATE_LOAD) {
        do_load(runtime.LM_ALL, 0, 0, 0, runtime.stateLoad);
    } else {
        do_load(load_mode, 0, 0, 0, runtime.manualLoad);
    }
    runtime.finishLoadUi(94);
}

pub fn loadAuto(do_load: *const fn (load_mode: u16, s: u16, n: u16, d: u16, load_type: u16) void) void {
    do_load(runtime.LM_ALL, 0, 0, 0, runtime.autoLoad);
    runtime.finishLoadUi(95);
}

pub fn saveAuto(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    // Faithful to C fnSaveAuto: auto-save exists only on DMCP firmware
    // (`#if defined(DMCP_BUILD)`); on host/PC it is a no-op.
    if (is_dmcp_build) {
        io_flow_owned.doSave(runtime.autoSave);
    }
}

pub fn save(save_mode: u16) void {
    if (save_mode == runtime.SM_MANUAL_SAVE) {
        io_flow_owned.doSave(runtime.manualSave);
    } else if (save_mode == runtime.SM_STATE_SAVE) {
        io_flow_owned.doSave(runtime.stateSave);
    }
}