// SPDX-License-Identifier: GPL-3.0-only
//
// Pure stopwatch elapsed-time math, lifted from timer.zig
// (src/c47/timer.c). The timer polls a wall clock; antirewinder corrects for the
// clock wrapping past midnight or rolling over an hour between reads, and
// timerElapsed returns the accumulated milliseconds. It is std-only u32 arithmetic
// -- the three ambient timer globals thread in as a value struct and out as the
// updated struct, so the RTC read stays in the owner -- exercised natively under
// `zig build test:unit`.
//
// testSuite-BLIND (the timer app is not in the oracle suite), so the native tests
// below are the first automated coverage of the wraparound corrections.
// Transcription is verbatim.

const std = @import("std");

const TIMER_APP_STOPPED: u32 = 0xFFFFFFFF;
const MS_PER_DAY: u32 = 86400000;
const MS_PER_HOUR: u32 = 3600000;

pub const TimerState = struct {
    startTime: u32,
    value: u32,
    totalTime: u32,
};

/// Correct the state for the wall clock wrapping past midnight (currTime dropped
/// below startTime) or rolling over an hour since the last read.
///
/// Every operation here is uint32_t arithmetic in the source and is written
/// modular for that reason: an accumulated value or total past 2^32 ms rolls over
/// and the stopwatch keeps running with a wrong reading.
pub fn antirewinder(state: TimerState, currTime: u32) TimerState {
    var s = state;
    if (currTime < s.startTime) {
        s.value +%= MS_PER_DAY -% s.startTime;
        if (s.totalTime > 0) {
            s.totalTime +%= MS_PER_DAY -% s.startTime;
        }
        s.startTime = 0;
    } else if (currTime >= s.startTime +% MS_PER_HOUR) {
        s.value +%= MS_PER_HOUR;
        if (s.totalTime > 0) {
            s.totalTime +%= MS_PER_HOUR;
        }
        s.startTime +%= MS_PER_HOUR;
    }
    return s;
}

/// Elapsed timer milliseconds for wall-clock reading `currTime`, plus the state to
/// write back. A STOPPED timer returns its held value with the state unchanged.
pub fn timerElapsed(state: TimerState, currTime: u32) struct { state: TimerState, elapsed: u32 } {
    if (state.startTime == TIMER_APP_STOPPED) {
        return .{ .state = state, .elapsed = state.value };
    }
    const s = antirewinder(state, currTime);
    return .{ .state = s, .elapsed = currTime -% s.startTime +% s.value };
}

const testing = std.testing;

test "antirewinder leaves an in-window read untouched" {
    const s = antirewinder(.{ .startTime = 1000, .value = 500, .totalTime = 0 }, 2000);
    try testing.expectEqual(TimerState{ .startTime = 1000, .value = 500, .totalTime = 0 }, s);
}

test "antirewinder folds a midnight wrap into value/total and resets start" {
    const s = antirewinder(.{ .startTime = 86000000, .value = 100, .totalTime = 5000 }, 50);
    try testing.expectEqual(@as(u32, 0), s.startTime);
    try testing.expectEqual(@as(u32, 100 + (MS_PER_DAY - 86000000)), s.value);
    try testing.expectEqual(@as(u32, 5000 + (MS_PER_DAY - 86000000)), s.totalTime);
}

test "antirewinder advances an hour rollover" {
    const s = antirewinder(.{ .startTime = 1000, .value = 200, .totalTime = 0 }, 1000 + MS_PER_HOUR);
    try testing.expectEqual(@as(u32, 1000 + MS_PER_HOUR), s.startTime);
    try testing.expectEqual(@as(u32, 200 + MS_PER_HOUR), s.value);
    try testing.expectEqual(@as(u32, 0), s.totalTime); // totalTime==0 stays 0
}

test "accumulation past 2^32 ms rolls over instead of refusing the value" {
    const s = antirewinder(.{ .startTime = 1000, .value = 0xFFFF_FFFF - 1000, .totalTime = 1 }, 1000 + MS_PER_HOUR);
    try testing.expectEqual(@as(u32, MS_PER_HOUR -% 1001), s.value);
    try testing.expectEqual(@as(u32, 1 + MS_PER_HOUR), s.totalTime);
}

test "a recalled value near 2^32 wraps the elapsed sum" {
    // fnRecallTimerApp can set value from a register, so the final addition is
    // not bounded by the wall clock.
    const r = timerElapsed(.{ .startTime = 1000, .value = 0xFFFF_FFFF, .totalTime = 0 }, 2000);
    try testing.expectEqual(@as(u32, 999), r.elapsed); // 2000 - 1000 + 0xFFFFFFFF
}

test "timerElapsed sums, and a stopped timer returns its held value" {
    const r = timerElapsed(.{ .startTime = 1000, .value = 500, .totalTime = 0 }, 2000);
    try testing.expectEqual(@as(u32, 1500), r.elapsed); // 2000 - 1000 + 500
    const stopped = timerElapsed(.{ .startTime = TIMER_APP_STOPPED, .value = 999, .totalTime = 0 }, 123);
    try testing.expectEqual(@as(u32, 999), stopped.elapsed);
    try testing.expectEqual(@as(u32, TIMER_APP_STOPPED), stopped.state.startTime);
}
