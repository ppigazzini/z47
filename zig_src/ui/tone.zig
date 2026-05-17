const runtime = @import("tone_runtime.zig");

const frequency = [10]u32{ 164814, 220000, 246942, 277183, 293665, 329628, 369995, 415305, 440000, 554365 };

fn tonePlay(tone_num: u16) void {
    if (runtime.getSystemFlag(runtime.FLAG_QUIET)) {
        return;
    }

    if (tone_num < frequency.len) {
        runtime.audioTone(frequency[tone_num]);
    }
}

fn refreshDisplay() void {
    runtime.zigToneRefreshDisplay();
}

pub export fn fnTone(tone_num: u16) callconv(.c) void {
    refreshDisplay();
    tonePlay(tone_num);
}

pub export fn fnBeep(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    refreshDisplay();
    tonePlay(8);
    tonePlay(5);
    tonePlay(9);
    tonePlay(8);
}
