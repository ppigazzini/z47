const std = @import("std");
const host_platform = @import("../host/platform.zig");

pub const RuntimeObjects = struct {
    math_command_wrappers: *std.Build.Step.Compile,

    pub fn addToCommand(self: RuntimeObjects, cmd: *std.Build.Step.Run) void {
        for (runtime_helper_sources) |source| {
            cmd.addArg(source);
        }
        cmd.addFileArg(self.math_command_wrappers.getEmittedBin());
    }
};

pub const RuntimeObjectOptions = struct {
    strip: ?bool = null,
    unwind_tables: ?std.builtin.UnwindTables = null,
    stack_protector: ?bool = null,
    stack_check: ?bool = null,
    omit_frame_pointer: ?bool = null,
    error_tracing: ?bool = null,
};

const replaced_core_sources = [_][]const u8{
    "mathematics/min.c",
    "mathematics/max.c",
    "mathematics/percent.c",
    "mathematics/ceil.c",
    "mathematics/floor.c",
    "mathematics/integerPart.c",
    "mathematics/integerPartLonginteger.c",
    "mathematics/integerPartShortinteger.c",
    "mathematics/fractionalPart.c",
    "mathematics/sinc.c",
    "mathematics/sincpi.c",
    "mathematics/arcsin.c",
    "mathematics/arccos.c",
    "mathematics/arctan.c",
    "mathematics/arcsinh.c",
    "mathematics/arccosh.c",
    "mathematics/arctanh.c",
    "mathematics/arg.c",
    "mathematics/atan2.c",
    "mathematics/pcg_basic.c",
    "mathematics/random.c",
    "mathematics/2pow.c",
    "mathematics/10pow.c",
    "mathematics/log2.c",
    "mathematics/ln.c",
    "mathematics/lnPOne.c",
    "mathematics/log10.c",
    "mathematics/minusOnePow.c",
    "mathematics/bn.c",
    "mathematics/exp.c",
    "mathematics/expMOne.c",
    "mathematics/expt.c",
    "mathematics/erf.c",
    "mathematics/erfc.c",
    "mathematics/factorial.c",
    "mathematics/gcd.c",
    "mathematics/imaginaryPart.c",
    "mathematics/ixyz.c",
    "mathematics/lcm.c",
    "mathematics/mant.c",
    "mathematics/magnitude.c",
    "mathematics/modulo.c",
    "mathematics/neighb.c",
    "mathematics/remainder.c",
    "mathematics/realPart.c",
    "mathematics/roundi.c",
    "mathematics/sqrt1Px2.c",
    "mathematics/conjugate.c",
    "mathematics/swapRealImaginary.c",
    "mathematics/ulp.c",
    "mathematics/eulersFormula.c",
    "mathematics/invert.c",
    "mathematics/sign.c",
    "mathematics/changeSign.c",
    "mathematics/sin.c",
    "mathematics/cos.c",
    "mathematics/tan.c",
    "mathematics/sinh.c",
    "mathematics/cosh.c",
    "mathematics/tanh.c",
    "mathematics/w_inverse.c",
    "mathematics/w_negative.c",
    "mathematics/w_positive.c",
    "mathematics/square.c",
    "mathematics/cube.c",
    "mathematics/addition.c",
    "mathematics/subtraction.c",
    "mathematics/multiplication.c",
    "mathematics/division.c",
    "mathematics/idiv.c",
    "mathematics/idivr.c",
    "mathematics/dblMultiplication.c",
    "mathematics/round.c",
    "mathematics/decomp.c",
    "mathematics/int.c",
    "mathematics/incDec.c",
    "mathematics/compare.c",
    "mathematics/checkValue.c",
    "mathematics/comparisonReals.c",
    "mathematics/dblDivision.c",
    "mathematics/logxy.c",
    "mathematics/toPolar.c",
    "mathematics/toRect.c",
    "mathematics/parallel.c",
    "mathematics/unitVector.c",
    "mathematics/shiftDigits.c",
    "mathematics/squareRoot.c",
    "mathematics/cubeRoot.c",
    "mathematics/percentMRR.c",
    "mathematics/percentPlusMG.c",
    "mathematics/percentT.c",
    "mathematics/deltaPercent.c",
    "mathematics/fib.c",
    "mathematics/linpol.c",
    "mathematics/cross.c",
    "mathematics/dot.c",
    "mathematics/agm.c",
    "mathematics/bessel.c",
    "mathematics/beta.c",
    "mathematics/cpyx.c",
    "mathematics/cxToRe.c",
    "mathematics/deltaPercentXmean.c",
    "mathematics/elliptic.c",
    "mathematics/gamma.c",
    "mathematics/gammaX.c",
    "mathematics/gd.c",
    "mathematics/iteration.c",
    "mathematics/lnbeta.c",
    "mathematics/matrix.c",
    "mathematics/mean.c",
    "mathematics/median.c",
    "mathematics/opmod.c",
    "mathematics/ortho_polynom.c",
    "mathematics/percentSigma.c",
    "mathematics/percentSigmaDeltaPercentXmean.c",
    "mathematics/power.c",
    "mathematics/prime.c",
    "mathematics/rdp.c",
    "mathematics/reToCx.c",
    "mathematics/rsd.c",
    "mathematics/slvc.c",
    "mathematics/slvq.c",
    "mathematics/variance.c",
    "mathematics/wp34s.c",
    "mathematics/xfn.c",
    "mathematics/xthRoot.c",
    "mathematics/zeta.c",
};

const runtime_helper_sources = [_][]const u8{
    "zig_bridge/mathematics/math_wrappers_runtime_helpers.c",
    "zig_bridge/mathematics/math_wrappers_runtime_dispatch_helpers.c",
    "zig_bridge/mathematics/math_wrappers_runtime_transform_helpers.c",
    "zig_bridge/mathematics/math_wrappers_runtime_percent_helpers.c",
    "zig_bridge/mathematics/math_wrappers_runtime_misc_helpers.c",
    "zig_bridge/mathematics/random_runtime_helpers.c",
    "zig_bridge/mathematics/math_wrappers_runtime_agm.c",
    "zig_bridge/mathematics/math_wrappers_runtime_bessel.c",
    "zig_bridge/mathematics/math_wrappers_runtime_beta.c",
    "zig_bridge/mathematics/math_wrappers_runtime_cpyx.c",
    "zig_bridge/mathematics/math_wrappers_runtime_cxToRe.c",
    "zig_bridge/mathematics/math_wrappers_runtime_deltaPercentXmean.c",
    "zig_bridge/mathematics/math_wrappers_runtime_elliptic.c",
    "zig_bridge/mathematics/math_wrappers_runtime_gamma.c",
    "zig_bridge/mathematics/math_wrappers_runtime_gammaX.c",
    "zig_bridge/mathematics/math_wrappers_runtime_gd.c",
    "zig_bridge/mathematics/math_wrappers_runtime_iteration.c",
    "zig_bridge/mathematics/math_wrappers_runtime_lnbeta.c",
    "zig_bridge/mathematics/math_wrappers_runtime_matrix.c",
    "zig_bridge/mathematics/math_wrappers_runtime_mean.c",
    "zig_bridge/mathematics/math_wrappers_runtime_median.c",
    "zig_bridge/mathematics/math_wrappers_runtime_opmod.c",
    "zig_bridge/mathematics/math_wrappers_runtime_ortho_polynom.c",
    "zig_bridge/mathematics/math_wrappers_runtime_percentSigma.c",
    "zig_bridge/mathematics/math_wrappers_runtime_percentSigmaDeltaPercentXmean.c",
    "zig_bridge/mathematics/math_wrappers_runtime_power.c",
    "zig_bridge/mathematics/math_wrappers_runtime_prime.c",
    "zig_bridge/mathematics/math_wrappers_runtime_rdp.c",
    "zig_bridge/mathematics/math_wrappers_runtime_reToCx.c",
    "zig_bridge/mathematics/math_wrappers_runtime_rsd.c",
    "zig_bridge/mathematics/math_wrappers_runtime_slvc.c",
    "zig_bridge/mathematics/math_wrappers_runtime_slvq.c",
    "zig_bridge/mathematics/math_wrappers_runtime_variance.c",
    "zig_bridge/mathematics/math_wrappers_runtime_wp34s.c",
    "zig_bridge/mathematics/math_wrappers_runtime_xfn.c",
    "zig_bridge/mathematics/math_wrappers_runtime_xthRoot.c",
    "zig_bridge/mathematics/math_wrappers_runtime_zeta.c",
};

fn addRuntimeObject(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    name_prefix: []const u8,
    options: RuntimeObjectOptions,
) *std.Build.Step.Compile {
    return b.addObject(.{
        .name = b.fmt("{s}-math-command-wrappers", .{name_prefix}),
        .root_module = b.createModule(.{
            .root_source_file = b.path("zig_src/mathematics/math_command_wrappers.zig"),
            .target = target,
            .optimize = optimize,
            .strip = options.strip,
            .unwind_tables = options.unwind_tables,
            .stack_protector = options.stack_protector,
            .stack_check = options.stack_check,
            .omit_frame_pointer = options.omit_frame_pointer,
            .error_tracing = options.error_tracing,
        }),
    });
}

pub fn addRuntimeObjects(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    name_prefix: []const u8,
) RuntimeObjects {
    return addRuntimeObjectsWithOptions(b, target, optimize, name_prefix, .{});
}

pub fn addRuntimeObjectsWithOptions(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    name_prefix: []const u8,
    options: RuntimeObjectOptions,
) RuntimeObjects {
    return .{
        .math_command_wrappers = addRuntimeObject(b, target, optimize, name_prefix, options),
    };
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
    const runtime_object = addRuntimeObject(b, target, optimize, name_prefix, .{});
    module.addObject(runtime_object);
}

pub fn addParityExecutable(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) *std.Build.Step.Compile {
    const runtime_object = addRuntimeObject(b, target, optimize, "parity", .{});
    const exe = b.addExecutable(.{
        .name = "math-command-wrappers-parity",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    exe.root_module.addIncludePath(b.path("zig_build/tests/math_wrappers"));
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_bridge/mathematics/math_wrappers_runtime_helpers.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_bridge/mathematics/random_runtime_helpers.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/math_wrappers/math_wrappers_fake_runtime.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/math_wrappers/math_wrappers_oracle.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/math_wrappers/math_wrappers_retained_link_stubs.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/math_wrappers/math_wrappers_parity.c"), .flags = &.{} });
    host_platform.linkGmp(exe.root_module, target);
    exe.root_module.addObject(runtime_object);
    return exe;
}

pub fn addRandomParityExecutable(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) *std.Build.Step.Compile {
    const runtime_object = addRuntimeObject(b, target, optimize, "random-parity", .{});
    const exe = b.addExecutable(.{
        .name = "math-random-parity",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    exe.root_module.addIncludePath(b.path("zig_build/tests/math_wrappers"));
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_bridge/mathematics/math_wrappers_runtime_helpers.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_bridge/mathematics/random_runtime_helpers.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/math_wrappers/math_wrappers_fake_runtime.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/math_wrappers/math_random_oracle.c"), .flags = &.{} });
    exe.root_module.addCSourceFile(.{ .file = b.path("zig_build/tests/math_wrappers/math_random_parity.c"), .flags = &.{} });
    host_platform.linkGmp(exe.root_module, target);
    exe.root_module.addObject(runtime_object);
    return exe;
}
