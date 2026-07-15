const frontier = @import("../../frontier.zig");
const frontier_curve_fitting = @import("curve_fitting.zig");
const frontier_error = @import("../error.zig");
const frontier_plotstat = @import("plotstat.zig");
const frontier_screen = @import("../display/screen.zig");
const frontier_softmenus = @import("../display/softmenus/softmenus.zig");
const frontier_stats = @import("../stats.zig");
const frontier_status_bar = @import("../display/statusbar/status_bar.zig");
const FLAG_SCALE: c_uint = 0x8052;

const CM_NORMAL: u8 = 0;
const CM_PLOT_STAT: u8 = 8;
const CM_GRAPH: u8 = 15;

const ERROR_NO_SUMMATION_DATA: u8 = 28;

const REGISTER_X: i16 = 100;
const ERR_REGISTER_LINE: i16 = 102;

const PLOT_ORTHOF: u16 = 0;
const PLOT_NXT: u16 = 1;
const PLOT_REV: u16 = 2;
const PLOT_LR: u16 = 3;
const PLOT_START: u16 = 4;
const PLOT_NOTHING: u16 = 5;
const H_PLOT: u16 = 7;
const H_NORM: u16 = 8;

const CF_GAUSS_FITTING: u16 = 256;

const MNU_PLOT_SCATR: i16 = 1395;
const MNU_PLOT_ASSESS: i16 = 1396;
const MNU_HPLOT: i16 = 1402;

const PlotStatModeClass = enum {
    regression,
    histogram,
    histogram_normal,
    other,
};

const PlotStatContext = struct {
    effective_mode: u16,
    class: PlotStatModeClass,

    fn init(plot_mode: u16) PlotStatContext {
        return .{
            .effective_mode = plot_mode,
            .class = classifyMode(plot_mode),
        };
    }
};

fn classifyMode(mode: u16) PlotStatModeClass {
    return switch (mode) {
        PLOT_ORTHOF, PLOT_START, PLOT_REV, PLOT_NXT, PLOT_LR => .regression,
        H_PLOT => .histogram,
        H_NORM => .histogram_normal,
        else => .other,
    };
}

fn configureRegressionPreset() void {
    drawHistogram = 0;
    frontier_plotstat.z47_frontier_plot_set_plotstatmx_stats();
}

fn configureHistogramPreset() void {
    drawHistogram = 1;
    frontier_plotstat.z47_frontier_plot_set_plotstatmx_histo();
}

fn configureHistogramNormPreset(ctx: *PlotStatContext) void {
    drawHistogram = 1;
    frontier_plotstat.z47_frontier_plot_set_statmx_histo();
    frontier_stats.calcSigma(0);
    ctx.effective_mode = PLOT_LR;
    lastPlotMode = PLOT_START;
    lrSelectionHistobackup = lrSelection;
    lrChosenHistobackup = lrChosen;
    frontier_curve_fitting.fnCurveFitting(CF_GAUSS_FITTING);
}

fn configureModePre(ctx: *PlotStatContext) void {
    switch (ctx.class) {
        .regression => configureRegressionPreset(),
        .histogram => configureHistogramPreset(),
        .histogram_normal => configureHistogramNormPreset(ctx),
        .other => {},
    }
}

fn needGraphEntryClear() bool {
    return calcMode != CM_PLOT_STAT and calcMode != CM_GRAPH;
}

fn ensureGraphEntryState() void {
    if (needGraphEntryClear()) {
        frontier_plotstat.z47_frontier_plot_clear_screen_for_graph_entry();
    }
}

fn activateHourglass() void {
    hourGlassIconEnabled = true;
    frontier_status_bar.showHideHourGlass();
    frontier_status_bar.refreshStatusBar();
}

fn validateSource() bool {
    return frontier_plotstat.z47_frontier_plot_has_source_data();
}

fn normalizeEffectiveModeFromLast(ctx: *PlotStatContext) void {
    if (lastPlotMode != PLOT_NOTHING and lastPlotMode != PLOT_START) {
        ctx.effective_mode = lastPlotMode;
    }
}

fn prepareRuntime(ctx: *PlotStatContext) void {
    clearSystemFlag(FLAG_SCALE);
    normalizeEffectiveModeFromLast(ctx);
    calcMode = CM_PLOT_STAT;
    frontier_plotstat.statGraphReset();
}

fn applyModeSelection(ctx: *PlotStatContext) void {
    if (ctx.effective_mode == PLOT_START) {
        plotSelection = 0;
        roundedTicks = false;
        return;
    }

    if (ctx.effective_mode == PLOT_LR and lrSelection != 0) {
        plotSelection = lrSelection;
        roundedTicks = false;
        return;
    }

    if (ctx.effective_mode == H_PLOT or ctx.effective_mode == H_NORM) {
        calcMode = CM_PLOT_STAT;
    }
}

fn refreshPlotLcd() void {
    _ = frontier_screen.refreshLcd(null);
}

fn showSoftmenuForMode(ctx: PlotStatContext) void {
    switch (ctx.effective_mode) {
        H_PLOT, H_NORM => frontier_softmenus.showSoftmenu(-MNU_HPLOT),
        PLOT_LR => {
            if (drawHistogram == 0) {
                frontier_softmenus.showSoftmenu(-MNU_PLOT_ASSESS);
            } else {
                frontier_softmenus.showSoftmenu(-MNU_HPLOT);
            }
        },
        PLOT_NXT, PLOT_REV => frontier_softmenus.showSoftmenu(-MNU_PLOT_ASSESS),
        PLOT_ORTHOF, PLOT_START => {
            setSystemFlag(FLAG_SCALE);
            frontier_softmenus.showSoftmenu(-MNU_PLOT_SCATR);
        },
        PLOT_NOTHING => {},
        else => {},
    }
}

fn updateRegressionLine(ctx: *PlotStatContext) void {
    if (ctx.effective_mode != PLOT_START and ctx.effective_mode != H_PLOT and ctx.effective_mode != H_NORM) {
        frontier.fnPlotRegressionLine(ctx.effective_mode);
    } else {
        lastPlotMode = ctx.effective_mode;
    }
}

fn finishFailure() void {
    calcMode = CM_NORMAL;
    frontier_error.displayCalcErrorMessage(ERROR_NO_SUMMATION_DATA, ERR_REGISTER_LINE, REGISTER_X);
}

pub fn run(plot_mode: u16) void {
    var ctx = PlotStatContext.init(plot_mode);

    configureModePre(&ctx);
    ensureGraphEntryState();
    activateHourglass();

    if (!validateSource()) {
        finishFailure();
        return;
    }

    prepareRuntime(&ctx);
    applyModeSelection(&ctx);
    refreshPlotLcd();
    showSoftmenuForMode(ctx);
    updateRegressionLine(&ctx);
}

extern var calcMode: u8;
extern var hourGlassIconEnabled: bool;
extern var drawHistogram: u8;
extern var roundedTicks: bool;
extern var plotSelection: u16;
extern var lrSelection: u16;
extern var lrChosen: u16;
extern var lastPlotMode: u16;
extern var lrSelectionHistobackup: u16;
extern var lrChosenHistobackup: u16;

extern fn clearSystemFlag(sf: c_uint) void;
extern fn setSystemFlag(sf: c_uint) void;
