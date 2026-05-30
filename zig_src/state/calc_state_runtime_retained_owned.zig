pub extern fn z47_calc_state_retained_doLoad(load_mode: u16, s: u16, n: u16, d: u16, load_type: u16) void;
pub extern fn z47_calc_state_retained_fnSave(save_mode: u16) void;
pub extern fn z47_calc_state_retained_fnLoad(load_mode: u16) void;
pub extern fn z47_calc_state_retained_fnSaveAuto(unused_but_mandatory_parameter: u16) void;

pub inline fn doLoadRetained(load_mode: u16, s: u16, n: u16, d: u16, load_type: u16) void {
    z47_calc_state_retained_doLoad(load_mode, s, n, d, load_type);
}

pub inline fn saveRetained(save_mode: u16) void {
    z47_calc_state_retained_fnSave(save_mode);
}

pub inline fn loadRetained(load_mode: u16) void {
    z47_calc_state_retained_fnLoad(load_mode);
}

pub inline fn saveAutoRetained(unused_but_mandatory_parameter: u16) void {
    z47_calc_state_retained_fnSaveAuto(unused_but_mandatory_parameter);
}
