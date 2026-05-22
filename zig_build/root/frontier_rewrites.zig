const std = @import("std");

const replaced_core_sources = [_][]const u8{
    "assign.c",
    "bufferize.c",
    "c47.c",
    "c47Extensions/graphText.c",
    "c47Extensions/graphs.c",
    "c47Extensions/inlineTest.c",
    "c47Extensions/jm.c",
    "c47Extensions/radioButtonCatalog.c",
    "c47Extensions/textfiles.c",
    "c47Extensions/xeqm.c",
    "charString.c",
    "c47Extensions/addons.c",
    "config.c",
    "core/freeList.c",
    "curveFitting.c",
    "display.c",
    "distributions/binomial.c",
    "distributions/cauchy.c",
    "distributions/chi2.c",
    "distributions/exponential.c",
    "distributions/f.c",
    "distributions/geometric.c",
    "distributions/gev.c",
    "distributions/hyper.c",
    "distributions/logistic.c",
    "distributions/negBinom.c",
    "distributions/normal.c",
    "distributions/pareto.c",
    "distributions/poisson.c",
    "distributions/t.c",
    "distributions/uniform.c",
    "distributions/weibull.c",
    "items.c",
    "plotstat.c",
    "programming/clcvar.c",
    "programming/decode.c",
    "programming/input.c",
    "programming/lblGtoXeq.c",
    "programming/manage.c",
    "programming/nextStep.c",
    "programming/programmableMenu.c",
    "printing/print.c",
    "registerValueConversions.c",
    "browsers/asnBrowser.c",
    "browsers/flagBrowser.c",
    "browsers/fontBrowser.c",
    "browsers/registerBrowser.c",
    "softmenus.c",
    "screen.c",
    "stats.c",
    "ui/matrixEditor.c",
};

const runtime_helper_sources = [_][]const u8{
    "zig_bridge/root/assign_retained.c",
    "zig_bridge/root/addons_retained.c",
    "zig_bridge/root/asn_browser_retained.c",
    "zig_bridge/root/bufferize_retained.c",
    "zig_bridge/root/binomial_retained.c",
    "zig_bridge/root/c47_retained.c",
    "zig_bridge/root/cauchy_retained.c",
    "zig_bridge/root/char_string_retained.c",
    "zig_bridge/root/chi2_retained.c",
    "zig_bridge/root/clcvar_retained.c",
    "zig_bridge/root/config_retained.c",
    "zig_bridge/root/core_free_list_retained.c",
    "zig_bridge/root/curve_fitting_retained.c",
    "zig_bridge/root/decode_retained.c",
    "zig_bridge/root/display_retained.c",
    "zig_bridge/root/exponential_retained.c",
    "zig_bridge/root/f_distribution_retained.c",
    "zig_bridge/root/flag_browser_retained.c",
    "zig_bridge/root/font_browser_retained.c",
    "zig_bridge/root/geometric_retained.c",
    "zig_bridge/root/gev_retained.c",
    "zig_bridge/root/graph_text_retained.c",
    "zig_bridge/root/graphs_retained.c",
    "zig_bridge/root/hyper_retained.c",
    "zig_bridge/root/inline_test_retained.c",
    "zig_bridge/root/input_retained.c",
    "zig_bridge/root/items_retained.c",
    "zig_bridge/root/jm_retained.c",
    "zig_bridge/root/lbl_gto_xeq_retained.c",
    "zig_bridge/root/logistic_retained.c",
    "zig_bridge/root/manage_retained.c",
    "zig_bridge/root/matrix_editor_retained.c",
    "zig_bridge/root/neg_binom_retained.c",
    "zig_bridge/root/next_step_retained.c",
    "zig_bridge/root/normal_retained.c",
    "zig_bridge/root/pareto_retained.c",
    "zig_bridge/root/plotstat_retained.c",
    "zig_bridge/root/poisson_retained.c",
    "zig_bridge/root/programmable_menu_retained.c",
    "zig_bridge/root/print_retained.c",
    "zig_bridge/root/radio_button_catalog_retained.c",
    "zig_bridge/root/register_browser_retained.c",
    "zig_bridge/root/register_value_conversions_retained.c",
    "zig_bridge/root/softmenus_retained.c",
    "zig_bridge/root/screen_retained.c",
    "zig_bridge/root/stats_retained.c",
    "zig_bridge/root/t_distribution_retained.c",
    "zig_bridge/root/textfiles_retained.c",
    "zig_bridge/root/uniform_retained.c",
    "zig_bridge/root/weibull_retained.c",
    "zig_bridge/root/xeqm_retained.c",
};

fn addRuntimeObject(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    name_prefix: []const u8,
) *std.Build.Step.Compile {
    return b.addObject(.{
        .name = b.fmt("{s}-frontier-root", .{name_prefix}),
        .root_module = b.createModule(.{
            .root_source_file = b.path("zig_src/root/frontier_entries.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
}

pub fn filterCoreSources(b: *std.Build, core_sources: [][]const u8) ![][]const u8 {
    var filtered = try std.ArrayList([]const u8).initCapacity(b.allocator, core_sources.len);
    errdefer filtered.deinit(b.allocator);

    outer: for (core_sources) |source| {
        for (replaced_core_sources) |removed| {
            if (std.mem.eql(u8, source, removed)) {
                continue :outer;
            }
        }
        try filtered.append(b.allocator, source);
    }

    return try filtered.toOwnedSlice(b.allocator);
}

pub fn addToModule(
    b: *std.Build,
    module: *std.Build.Module,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    name_prefix: []const u8,
    c_flags: []const []const u8,
) void {
    for (runtime_helper_sources) |source| {
        module.addCSourceFile(.{ .file = b.path(source), .flags = c_flags });
    }
    const runtime_object = addRuntimeObject(b, target, optimize, name_prefix);
    module.addObject(runtime_object);
}