// SPDX-License-Identifier: GPL-3.0-only
//
// Pure LR / orthogonal-fit curve-selection state machine, lifted from
// frontier_plot_regression.zig (src/c47/statistics plotstat.c). Given a plot
// command it advances a 10-bit selection word to the next/previous ALLOWED fit
// model (bit-shift scanning filtered by the lr-selection mask, with overflow wrap
// at bit 1024). It is std-only u16 bit arithmetic over a Context value -- the
// three ambient plot globals (plotSelection/lrSelection/lrChosen) are read into
// the Context and written back only at the owner's boundary -- so it lives here as
// a module exercised natively under `zig build test:unit`. The owner keeps its
// initContext/finalize/run shim (the global reads/writes + the C-ABI entry) and
// delegates applyCommand.
//
// testSuite-BLIND at the unit level (the selection walk is only exercised through
// the C plotstat.c oracle), so the native tests below are its first direct
// coverage -- notably the NXT-vs-REV shift asymmetry, the overflow clamp, and the
// mask-filtered scan. Transcription is verbatim.

const std = @import("std");

pub const PLOT_ORTHOF: u16 = 0;
pub const PLOT_NXT: u16 = 1;
pub const PLOT_REV: u16 = 2;
pub const PLOT_LR: u16 = 3;
pub const PLOT_START: u16 = 4;
pub const PLOT_NOTHING: u16 = 5;

pub const CF_ORTHOGONAL_FITTING: u16 = 512;
pub const FULL_LR_SELECTION_MASK: u16 = 1023;
pub const SELECTION_OVERFLOW_LIMIT: u16 = 1024;

pub const Command = enum {
    orthof,
    next,
    prev,
    lr,
    start,
    nothing,
    unknown,
};

pub const Context = struct {
    command: Command,
    selection: u16,
    lr_selection_mask: u16,
    chosen: u16,
};

const SelectionCursor = struct {
    mask: u16,
    selection: u16,

    fn init(mask: u16, selection: u16) SelectionCursor {
        return .{ .mask = mask, .selection = selection };
    }

    fn isAllowed(self: SelectionCursor) bool {
        return self.selection == (self.mask & self.selection);
    }

    fn isWithinBounds(self: SelectionCursor) bool {
        return self.selection < SELECTION_OVERFLOW_LIMIT;
    }

    fn isPositive(self: SelectionCursor) bool {
        return self.selection > 0;
    }

    fn isZero(self: SelectionCursor) bool {
        return self.selection == 0;
    }

    fn shiftLeft(self: *SelectionCursor) void {
        self.selection <<= 1;
    }

    fn shiftRight(self: *SelectionCursor) void {
        self.selection >>= 1;
    }

    fn clampOverflow(self: *SelectionCursor) void {
        if (self.selection >= SELECTION_OVERFLOW_LIMIT) {
            self.selection = 0;
        }
    }

    fn scanForward(self: *SelectionCursor) void {
        while (!self.isAllowed() and self.isWithinBounds()) {
            self.shiftLeft();
        }
    }

    fn scanBackward(self: *SelectionCursor) void {
        while (!self.isAllowed() and self.isWithinBounds() and self.isPositive()) {
            self.shiftRight();
        }
    }
};

pub fn decodeCommand(plot_mode: u16) Command {
    return switch (plot_mode) {
        PLOT_ORTHOF => .orthof,
        PLOT_NXT => .next,
        PLOT_REV => .prev,
        PLOT_LR => .lr,
        PLOT_START => .start,
        PLOT_NOTHING => .nothing,
        else => .unknown,
    };
}

fn applyNext(ctx: *Context) void {
    var cursor = SelectionCursor.init(ctx.lr_selection_mask, ctx.selection);
    // C PLOT_NXT (plotstat.c:1933) shifts FIRST with only a post-shift zero-check;
    // there is no pre-shift check here (unlike PLOT_REV / applyPrev).
    cursor.shiftLeft();
    if (cursor.isZero()) {
        cursor.selection = 1;
    }
    cursor.scanForward();
    cursor.clampOverflow();
    ctx.selection = cursor.selection;
}

fn applyPrev(ctx: *Context) void {
    var cursor = SelectionCursor.init(ctx.lr_selection_mask, ctx.selection);
    if (cursor.isZero()) {
        cursor.selection = SELECTION_OVERFLOW_LIMIT;
    }
    cursor.shiftRight();
    cursor.clampOverflow();
    cursor.scanBackward();
    ctx.selection = cursor.selection;
}

fn applyLr(ctx: *Context) void {
    var cursor = SelectionCursor.init(ctx.lr_selection_mask, ctx.chosen);
    if (cursor.isZero()) {
        cursor.selection = 1;
    }
    cursor.scanForward();
    cursor.clampOverflow();
    ctx.selection = cursor.selection;
}

pub fn applyCommand(ctx: *Context) void {
    switch (ctx.command) {
        .orthof => {
            ctx.selection = CF_ORTHOGONAL_FITTING;
            ctx.chosen = CF_ORTHOGONAL_FITTING;
        },
        .next => applyNext(ctx),
        .prev => applyPrev(ctx),
        .lr => applyLr(ctx),
        .start, .nothing, .unknown => {},
    }
}

const testing = std.testing;

fn ctxOf(command: Command, selection: u16, mask: u16, chosen: u16) Context {
    return .{ .command = command, .selection = selection, .lr_selection_mask = mask, .chosen = chosen };
}

test "decodeCommand maps every plot mode, unknown otherwise" {
    try testing.expectEqual(Command.orthof, decodeCommand(PLOT_ORTHOF));
    try testing.expectEqual(Command.next, decodeCommand(PLOT_NXT));
    try testing.expectEqual(Command.prev, decodeCommand(PLOT_REV));
    try testing.expectEqual(Command.lr, decodeCommand(PLOT_LR));
    try testing.expectEqual(Command.start, decodeCommand(PLOT_START));
    try testing.expectEqual(Command.nothing, decodeCommand(PLOT_NOTHING));
    try testing.expectEqual(Command.unknown, decodeCommand(6));
    try testing.expectEqual(Command.unknown, decodeCommand(999));
}

test "orthof pins both selection and chosen to the orthogonal-fitting bit" {
    var ctx = ctxOf(.orthof, 7, FULL_LR_SELECTION_MASK, 3);
    applyCommand(&ctx);
    try testing.expectEqual(CF_ORTHOGONAL_FITTING, ctx.selection);
    try testing.expectEqual(CF_ORTHOGONAL_FITTING, ctx.chosen);
}

test "next shifts first, then advances to the next allowed bit" {
    // All bits allowed: 1 -> 2.
    var ctx = ctxOf(.next, 1, FULL_LR_SELECTION_MASK, 0);
    applyCommand(&ctx);
    try testing.expectEqual(@as(u16, 2), ctx.selection);
}

test "next from zero seeds bit 1 (post-shift zero check)" {
    var ctx = ctxOf(.next, 0, FULL_LR_SELECTION_MASK, 0);
    applyCommand(&ctx);
    try testing.expectEqual(@as(u16, 1), ctx.selection);
}

test "next skips mask-disallowed bits" {
    // Only bit 8 allowed: from 1, shift to 2 then scan 2->4->8.
    var ctx = ctxOf(.next, 1, 8, 0);
    applyCommand(&ctx);
    try testing.expectEqual(@as(u16, 8), ctx.selection);
}

test "next overflows to zero when no further bit matches" {
    // Only bit 1 allowed: from 1, shift to 2, scan past 1024 -> clamp to 0.
    var ctx = ctxOf(.next, 1, 1, 0);
    applyCommand(&ctx);
    try testing.expectEqual(@as(u16, 0), ctx.selection);
}

test "prev checks zero BEFORE shifting (asymmetry vs next)" {
    // Zero seeds 1024, shift right to 512, which is allowed under the full mask.
    var ctx = ctxOf(.prev, 0, FULL_LR_SELECTION_MASK, 0);
    applyCommand(&ctx);
    try testing.expectEqual(@as(u16, 512), ctx.selection);
}

test "prev decrements to the previous allowed bit" {
    var ctx = ctxOf(.prev, 4, FULL_LR_SELECTION_MASK, 0);
    applyCommand(&ctx);
    try testing.expectEqual(@as(u16, 2), ctx.selection);
}

test "lr scans forward starting from the chosen bit" {
    var ctx = ctxOf(.lr, 99, FULL_LR_SELECTION_MASK, 8);
    applyCommand(&ctx);
    try testing.expectEqual(@as(u16, 8), ctx.selection);
    // chosen == 0 seeds bit 1.
    var ctx0 = ctxOf(.lr, 99, FULL_LR_SELECTION_MASK, 0);
    applyCommand(&ctx0);
    try testing.expectEqual(@as(u16, 1), ctx0.selection);
}

test "start / nothing / unknown leave the selection untouched" {
    for ([_]Command{ .start, .nothing, .unknown }) |cmd| {
        var ctx = ctxOf(cmd, 42, FULL_LR_SELECTION_MASK, 7);
        applyCommand(&ctx);
        try testing.expectEqual(@as(u16, 42), ctx.selection);
    }
}
