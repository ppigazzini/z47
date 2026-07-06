const PLOT_ORTHOF: u16 = 0;
const PLOT_NXT: u16 = 1;
const PLOT_REV: u16 = 2;
const PLOT_LR: u16 = 3;
const PLOT_START: u16 = 4;
const PLOT_NOTHING: u16 = 5;

const CF_ORTHOGONAL_FITTING: u16 = 512;
const FULL_LR_SELECTION_MASK: u16 = 1023;
const SELECTION_OVERFLOW_LIMIT: u16 = 1024;

const Command = enum {
    orthof,
    next,
    prev,
    lr,
    start,
    nothing,
    unknown,
};

const Context = struct {
    command: Command,
    selection: u16,
    lr_selection_mask: u16,
    chosen: u16,

    fn init(plot_mode: u16) Context {
        return .{
            .command = decodeCommand(plot_mode),
            .selection = plotSelection,
            .lr_selection_mask = if (lrSelection == 0) FULL_LR_SELECTION_MASK else lrSelection,
            .chosen = lrChosen,
        };
    }
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

fn decodeCommand(plot_mode: u16) Command {
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

fn applyCommand(ctx: *Context) void {
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

fn finalize(ctx: Context) void {
    plotSelection = if (ctx.selection >= SELECTION_OVERFLOW_LIMIT) 0 else ctx.selection;
    if (ctx.command == .orthof) {
        lrChosen = ctx.chosen;
    }
}

pub fn run(plot_mode: u16) void {
    var ctx = Context.init(plot_mode);
    applyCommand(&ctx);
    finalize(ctx);
}

extern var plotSelection: u16;
extern var lrSelection: u16;
extern var lrChosen: u16;
