// LR / orthogonal-fit curve-selection dispatch (src/c47/statistics plotstat.c).
// The pure 10-bit selection state machine lives in the tested
// plot_regression_selection module; this owner is the thin runtime shim that
// reads the three ambient plot globals into a Context, delegates the selection
// walk, and writes the result back.

const sel = @import("plot_regression_selection.zig");

extern var plotSelection: u16;
extern var lrSelection: u16;
extern var lrChosen: u16;

fn initContext(plot_mode: u16) sel.Context {
    return .{
        .command = sel.decodeCommand(plot_mode),
        .selection = plotSelection,
        .lr_selection_mask = if (lrSelection == 0) sel.FULL_LR_SELECTION_MASK else lrSelection,
        .chosen = lrChosen,
    };
}

fn finalize(ctx: sel.Context) void {
    plotSelection = if (ctx.selection >= sel.SELECTION_OVERFLOW_LIMIT) 0 else ctx.selection;
    if (ctx.command == .orthof) {
        lrChosen = ctx.chosen;
    }
}

pub fn run(plot_mode: u16) void {
    var ctx = initContext(plot_mode);
    sel.applyCommand(&ctx);
    finalize(ctx);
}

pub export fn fnPlotRegressionLine(plot_mode: u16) callconv(.c) void {
    run(plot_mode);
}
