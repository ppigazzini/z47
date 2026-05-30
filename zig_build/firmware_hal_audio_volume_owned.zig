const FLAG_QUIET: u16 = 0x8019;
const REGISTER_X: i16 = 100;

extern fn start_buzzer_freq(frequency: u32) void;
extern fn sys_delay(ms: u32) void;
extern fn stop_buzzer() void;
extern fn getSystemFlag(flag: u16) c_int;
extern fn get_beep_volume() u16;
extern fn beep_volume_up() void;
extern fn beep_volume_down() void;
extern fn liftStack() void;
extern fn convertUInt64ToShortIntegerRegister(sign: i16, value: u64, base: u32, regist: i16) void;
extern fn convertShortIntegerRegisterToLongIntegerRegister(source: i16, destination: i16) void;

pub fn audioTone(frequency: u32) void {
    start_buzzer_freq(frequency);
    sys_delay(250);
    stop_buzzer();
}

pub fn dm42Squeak() void {
    if (getSystemFlag(FLAG_QUIET) == 0) {
        start_buzzer_freq(1835000);
        sys_delay(125);
        stop_buzzer();
    }
}

pub fn fnSetVolume(volume: u16) void {
    var current = get_beep_volume();
    while (current < volume) : (current += 1) {
        beep_volume_up();
    }
    while (current > volume) : (current -= 1) {
        beep_volume_down();
    }
}

pub fn getBeepVolume() u16 {
    return get_beep_volume();
}

pub fn fnGetVolume(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    liftStack();
    convertUInt64ToShortIntegerRegister(0, get_beep_volume(), 10, REGISTER_X);
    convertShortIntegerRegisterToLongIntegerRegister(REGISTER_X, REGISTER_X);
}

pub fn fnVolumeUp(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    beep_volume_up();
    audioTone(440000);
}

pub fn fnVolumeDown(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    beep_volume_down();
    audioTone(440000);
}
