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
    z47_frontier_plot_set_plotstatmx_stats();
}

fn configureHistogramPreset() void {
    drawHistogram = 1;
    z47_frontier_plot_set_plotstatmx_histo();
}

fn configureHistogramNormPreset(ctx: *PlotStatContext) void {
    drawHistogram = 1;
    z47_frontier_plot_set_statmx_histo();
    calcSigma(0);
    ctx.effective_mode = PLOT_LR;
    lastPlotMode = PLOT_START;
    lrSelectionHistobackup = lrSelection;
    lrChosenHistobackup = lrChosen;
    fnCurveFitting(CF_GAUSS_FITTING);
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
        z47_frontier_plot_clear_screen_for_graph_entry();
    }
}

fn activateHourglass() void {
    hourGlassIconEnabled = true;
    showHideHourGlass();
    refreshStatusBar();
}

fn validateSource() bool {
    return z47_frontier_plot_has_source_data();
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
    statGraphReset();
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
    refreshLcd(null);
}

fn showSoftmenuForMode(ctx: PlotStatContext) void {
    switch (ctx.effective_mode) {
        H_PLOT, H_NORM => showSoftmenu(-MNU_HPLOT),
        PLOT_LR => {
            if (drawHistogram == 0) {
                showSoftmenu(-MNU_PLOT_ASSESS);
            } else {
                showSoftmenu(-MNU_HPLOT);
            }
        },
        PLOT_NXT, PLOT_REV => showSoftmenu(-MNU_PLOT_ASSESS),
        PLOT_ORTHOF, PLOT_START => {
            setSystemFlag(FLAG_SCALE);
            showSoftmenu(-MNU_PLOT_SCATR);
        },
        PLOT_NOTHING => {},
        else => {},
    }
}

fn updateRegressionLine(ctx: *PlotStatContext) void {
    if (ctx.effective_mode != PLOT_START and ctx.effective_mode != H_PLOT and ctx.effective_mode != H_NORM) {
        fnPlotRegressionLine(ctx.effective_mode);
    } else {
        lastPlotMode = ctx.effective_mode;
    }
}

fn finishFailure() void {
    calcMode = CM_NORMAL;
    displayCalcErrorMessage(ERROR_NO_SUMMATION_DATA, ERR_REGISTER_LINE, REGISTER_X);
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
extern fn showSoftmenu(menu: i16) void;
extern fn refreshLcd(surface: ?*anyopaque) void;
extern fn calcSigma(max_offset: u16) void;
extern fn fnCurveFitting(curve_fitting: u16) void;
extern fn showHideHourGlass() void;
extern fn refreshStatusBar() void;
extern fn statGraphReset() void;
extern fn z47_frontier_plot_set_plotstatmx_stats() void;
extern fn z47_frontier_plot_set_plotstatmx_histo() void;
extern fn z47_frontier_plot_set_statmx_histo() void;
extern fn z47_frontier_plot_has_source_data() bool;
extern fn z47_frontier_plot_clear_screen_for_graph_entry() void;
extern fn displayCalcErrorMessage(error_code: u8, err_message_register_line: i16, err_register_line: i16) void;
extern fn fnPlotRegressionLine(plot_mode: u16) void;