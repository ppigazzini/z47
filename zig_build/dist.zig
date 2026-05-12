const std = @import("std");
const build_common = @import("common.zig");
const firmware_steps = @import("firmware.zig");
const host_steps = @import("host.zig");

const dist_script_path = "zig_build/zig_dist.py";

const FirmwarePackageKind = enum {
    dmcp,
    dmcpr47,
    dmcp5,
    dmcp5r47,
};

const FirmwarePackageSpec = struct {
    step_name: []const u8,
    description: []const u8,
    archive_name: []const u8,
    base_stage_name: []const u8,
    kind: FirmwarePackageKind,
    include_packages: bool = false,
    use_dist_version: bool = false,
};

const VariantStep = struct {
    package: u8,
    step: *std.Build.Step,
};

const firmware_package_specs = [_]FirmwarePackageSpec{
    .{
        .step_name = "dist_dmcp",
        .description = "Create the DMCP distribution package with Zig-owned packaging",
        .archive_name = "c47-dmcp.zip",
        .base_stage_name = "c47-dmcp",
        .kind = .dmcp,
        .include_packages = true,
    },
    .{
        .step_name = "dist_dmcpr47",
        .description = "Create the DMCP R47 distribution package with Zig-owned packaging",
        .archive_name = "r47-dmcp.zip",
        .base_stage_name = "r47-dmcp",
        .kind = .dmcpr47,
    },
    .{
        .step_name = "dist_dmcp5",
        .description = "Create the DMCP5 distribution package with Zig-owned packaging",
        .archive_name = "c47-dmcp5.zip",
        .base_stage_name = "c47-dmcp5",
        .kind = .dmcp5,
    },
    .{
        .step_name = "dist_dmcp5r47",
        .description = "Create the DMCP5 R47 distribution package with Zig-owned packaging",
        .archive_name = "r47-dmcp5.zip",
        .base_stage_name = "r47-dmcp5",
        .kind = .dmcp5r47,
        .use_dist_version = true,
    },
};

pub fn registerSteps(
    b: *std.Build,
    context: host_steps.Context,
    bundle: firmware_steps.Bundle,
    ci_commit_tag: []const u8,
    dist_version: []const u8,
) !void {
    const dist_host_optimize: std.builtin.OptimizeMode = if (context.host_target.result.os.tag == .linux)
        .Debug
    else
        .ReleaseFast;
    const dist_c47 = host_steps.addSimulator(
        b,
        context.host_target,
        "c47",
        "c47-dist",
        dist_host_optimize,
        context.core_sources,
        context.gtk_sources,
        context.common,
        context.version_headers_dir,
        context.generated,
        context.shortint_leaf_objects,
        context.stack_state_objects,
        "USER_C47",
        null,
    );
    const dist_r47 = host_steps.addSimulator(
        b,
        context.host_target,
        "r47",
        "r47-dist",
        dist_host_optimize,
        context.core_sources,
        context.gtk_sources,
        context.common,
        context.version_headers_dir,
        context.generated,
        context.shortint_leaf_objects,
        context.stack_state_objects,
        "USER_R47",
        null,
    );

    const dist_step = b.step("dist", "Build the current-host distribution archive plus all DMCP package archives");
    const test_pgms_txt = b.path("res/testPgms/testPgms.txt");
    const dist_testpgms_zip = addTestPgmsZipStep(b, dist_c47.getEmittedBin(), context.generated.test_pgms_bin, test_pgms_txt);

    const windows_stage_name = distDirName(b, "c47-windows", ci_commit_tag);
    const macos_stage_name = distDirName(b, "c47-macos", ci_commit_tag);
    const linux_stage_name = distDirName(b, "c47-linux", ci_commit_tag);

    const dist_windows_step: *std.Build.Step = if (context.host_target.result.os.tag == .windows) blk: {
        const zip = addHostDistZipStep(b, "windows", "c47-windows.zip", windows_stage_name, dist_c47.getEmittedBin(), dist_r47.getEmittedBin(), context.generated.test_pgms_bin, test_pgms_txt, dist_testpgms_zip.path, null);
        const install = b.addInstallFileWithDir(zip.path, .prefix, "dist/c47-windows.zip");
        const step = b.step("dist_windows", "Create the Windows distribution package with Zig-owned packaging");
        step.dependOn(&install.step);
        break :blk step;
    } else addUnsupportedStep(b, "dist_windows", "dist_windows requires running zig build on a Windows host");

    const dist_macos_step: *std.Build.Step = if (context.host_target.result.os.tag == .macos) blk: {
        const zip = addHostDistZipStep(b, "macos", "c47-macos.zip", macos_stage_name, dist_c47.getEmittedBin(), dist_r47.getEmittedBin(), context.generated.test_pgms_bin, test_pgms_txt, dist_testpgms_zip.path, null);
        const install = b.addInstallFileWithDir(zip.path, .prefix, "dist/c47-macos.zip");
        const step = b.step("dist_macos", "Create the macOS distribution package with Zig-owned packaging");
        step.dependOn(&install.step);
        break :blk step;
    } else addUnsupportedStep(b, "dist_macos", "dist_macos requires running zig build on a macOS host");

    const dist_linux_step: *std.Build.Step = if (context.host_target.result.os.tag == .linux) blk: {
        const zip = addHostDistZipStep(b, "linux", "c47-linux.zip", linux_stage_name, dist_c47.getEmittedBin(), dist_r47.getEmittedBin(), context.generated.test_pgms_bin, test_pgms_txt, dist_testpgms_zip.path, null);
        const install = b.addInstallFileWithDir(zip.path, .prefix, "dist/c47-linux.zip");
        const step = b.step("dist_linux", "Create the Linux distribution package with Zig-owned packaging");
        step.dependOn(&install.step);
        break :blk step;
    } else addUnsupportedStep(b, "dist_linux", "dist_linux requires running zig build on a Linux host");

    switch (context.host_target.result.os.tag) {
        .windows => dist_step.dependOn(dist_windows_step),
        .macos => dist_step.dependOn(dist_macos_step),
        else => dist_step.dependOn(dist_linux_step),
    }

    for (firmware_package_specs) |spec| {
        dist_step.dependOn(addFirmwarePackageStep(
            b,
            ci_commit_tag,
            dist_version,
            context.generated.test_pgms_bin,
            test_pgms_txt,
            dist_testpgms_zip.path,
            bundle,
            spec,
        ));
    }

    const variant_steps = try b.allocator.alloc(VariantStep, bundle.dmcp_variants.len);
    for (bundle.dmcp_variants, 0..) |variant, index| {
        const step = addDmcpVariantStep(
            b,
            ci_commit_tag,
            context.generated.test_pgms_bin,
            test_pgms_txt,
            dist_testpgms_zip.path,
            variant,
        );
        variant_steps[index] = .{ .package = variant.package, .step = step };
        dist_step.dependOn(step);
    }

    const dist_dmcp_pkgs_all = b.step("dist_dmcp_pkgs_all", "Create all DMCP package variant archives with Zig-owned packaging");
    for (variant_steps) |variant| {
        dist_dmcp_pkgs_all.dependOn(variant.step);
    }

    const dist_dmcp_pkgs_1_2 = b.step("dist_dmcp_pkgs_1_2", "Create DMCP package 1 and 2 archives with Zig-owned packaging");
    dist_dmcp_pkgs_1_2.dependOn(findVariantStep(variant_steps, 1));
    dist_dmcp_pkgs_1_2.dependOn(findVariantStep(variant_steps, 2));

    const dist_dmcp_pkgs_small = b.step("dist_dmcp_pkgs_small", "Create the smaller DMCP package 2 and 3 archives with Zig-owned packaging");
    dist_dmcp_pkgs_small.dependOn(findVariantStep(variant_steps, 2));
    dist_dmcp_pkgs_small.dependOn(findVariantStep(variant_steps, 3));

    const distS_step = b.step("distS", "Run the aggregate distribution build sequence under Zig-only orchestration");
    distS_step.dependOn(dist_step);
}

fn addFirmwarePackageStep(
    b: *std.Build,
    ci_commit_tag: []const u8,
    dist_version: []const u8,
    test_pgms_bin: std.Build.LazyPath,
    test_pgms_txt: std.Build.LazyPath,
    test_pgms_zip: std.Build.LazyPath,
    bundle: firmware_steps.Bundle,
    spec: FirmwarePackageSpec,
) *std.Build.Step {
    const stage_name = distDirName(b, spec.base_stage_name, ci_commit_tag);
    const outputs = outputsForKind(bundle, spec.kind);
    const version = if (spec.use_dist_version) dist_version else null;
    const zip = switch (spec.kind) {
        .dmcp => addDmcpDistZipStep(b, "package-dmcp", spec.archive_name, stage_name, outputs, test_pgms_bin, test_pgms_txt, test_pgms_zip, null, spec.include_packages, version),
        .dmcpr47 => addDmcpDistZipStep(b, "package-dmcpr47", spec.archive_name, stage_name, outputs, test_pgms_bin, test_pgms_txt, test_pgms_zip, null, spec.include_packages, version),
        .dmcp5 => addDmcp5DistZipStep(b, "package-dmcp5", spec.archive_name, stage_name, outputs, test_pgms_bin, test_pgms_txt, test_pgms_zip, version),
        .dmcp5r47 => addDmcp5DistZipStep(b, "package-dmcp5r47", spec.archive_name, stage_name, outputs, test_pgms_bin, test_pgms_txt, test_pgms_zip, version),
    };
    const install = b.addInstallFileWithDir(zip.path, .prefix, b.fmt("dist/{s}", .{spec.archive_name}));
    const step = b.step(spec.step_name, spec.description);
    step.dependOn(&install.step);
    return step;
}

fn addDmcpVariantStep(
    b: *std.Build,
    ci_commit_tag: []const u8,
    test_pgms_bin: std.Build.LazyPath,
    test_pgms_txt: std.Build.LazyPath,
    test_pgms_zip: std.Build.LazyPath,
    variant: firmware_steps.VariantBuild,
) *std.Build.Step {
    const base_stage_name = distDirName(b, "c47-dmcp", ci_commit_tag);
    const stage_name = b.fmt("{s}-pkg{d}", .{ base_stage_name, variant.package });
    const archive_name = b.fmt("c47-dmcp-pkg{d}.zip", .{variant.package});
    const zip = addDmcpDistZipStep(
        b,
        "package-dmcp",
        archive_name,
        stage_name,
        variant.build.outputs,
        test_pgms_bin,
        test_pgms_txt,
        test_pgms_zip,
        null,
        true,
        null,
    );
    const install = b.addInstallFileWithDir(zip.path, .prefix, b.fmt("dist/{s}", .{archive_name}));
    const step = b.step(
        b.fmt("dist_dmcp_pkg{d}", .{variant.package}),
        b.fmt("Create the DMCP package {d} distribution archive with Zig-owned packaging", .{variant.package}),
    );
    step.dependOn(&install.step);
    return step;
}

fn outputsForKind(bundle: firmware_steps.Bundle, kind: FirmwarePackageKind) firmware_steps.Outputs {
    return switch (kind) {
        .dmcp => bundle.dmcp.outputs,
        .dmcpr47 => bundle.dmcpr47.outputs,
        .dmcp5 => bundle.dmcp5.outputs,
        .dmcp5r47 => bundle.dmcp5r47.outputs,
    };
}

fn findVariantStep(variant_steps: []const VariantStep, package: u8) *std.Build.Step {
    for (variant_steps) |variant| {
        if (variant.package == package) return variant.step;
    }
    @panic("missing DMCP package variant step");
}

fn addTestPgmsZipStep(
    b: *std.Build,
    c47_bin: std.Build.LazyPath,
    test_pgms_bin: std.Build.LazyPath,
    test_pgms_txt: std.Build.LazyPath,
) build_common.StepFile {
    const cmd = b.addSystemCommand(&.{ "python3", dist_script_path, "make-testpgms" });
    cmd.setCwd(b.path("."));
    const output = cmd.addOutputFileArg("testPgms.zip");
    cmd.addFileArg(c47_bin);
    cmd.addFileArg(test_pgms_bin);
    cmd.addFileArg(test_pgms_txt);
    return .{ .step = &cmd.step, .path = output };
}

fn addHostDistZipStep(
    b: *std.Build,
    flavor: []const u8,
    zip_name: []const u8,
    stage_name: []const u8,
    c47_bin: std.Build.LazyPath,
    r47_bin: std.Build.LazyPath,
    test_pgms_bin: std.Build.LazyPath,
    test_pgms_txt: std.Build.LazyPath,
    test_pgms_zip: std.Build.LazyPath,
    wiki_dir: ?std.Build.LazyPath,
) build_common.StepFile {
    const cmd = b.addSystemCommand(&.{ "python3", dist_script_path, "package-host", flavor });
    cmd.setCwd(b.path("."));
    const output = cmd.addOutputFileArg(zip_name);
    cmd.addArg(stage_name);
    cmd.addFileArg(c47_bin);
    cmd.addFileArg(r47_bin);
    cmd.addFileArg(test_pgms_bin);
    cmd.addFileArg(test_pgms_txt);
    cmd.addFileArg(test_pgms_zip);
    if (wiki_dir) |dir| cmd.addDirectoryArg(dir);
    return .{ .step = &cmd.step, .path = output };
}

fn addDmcpDistZipStep(
    b: *std.Build,
    command: []const u8,
    zip_name: []const u8,
    stage_name: []const u8,
    outputs: firmware_steps.Outputs,
    test_pgms_bin: std.Build.LazyPath,
    test_pgms_txt: std.Build.LazyPath,
    test_pgms_zip: std.Build.LazyPath,
    wiki_dir: ?std.Build.LazyPath,
    include_packages: bool,
    version: ?[]const u8,
) build_common.StepFile {
    _ = version;
    const cmd = b.addSystemCommand(&.{ "python3", dist_script_path, command });
    cmd.setCwd(b.path("."));
    const output = cmd.addOutputFileArg(zip_name);
    cmd.addArg(stage_name);
    cmd.addFileArg(outputs.program);
    cmd.addFileArg(outputs.qspi);
    cmd.addFileArg(outputs.map);
    cmd.addFileArg(test_pgms_bin);
    cmd.addFileArg(test_pgms_txt);
    cmd.addFileArg(test_pgms_zip);
    if (wiki_dir) |dir| cmd.addDirectoryArg(dir);
    if (std.mem.eql(u8, command, "package-dmcp")) {
        cmd.addArg(if (include_packages) "with-packages" else "without-packages");
    }
    return .{ .step = &cmd.step, .path = output };
}

fn addDmcp5DistZipStep(
    b: *std.Build,
    command: []const u8,
    zip_name: []const u8,
    stage_name: []const u8,
    outputs: firmware_steps.Outputs,
    test_pgms_bin: std.Build.LazyPath,
    test_pgms_txt: std.Build.LazyPath,
    test_pgms_zip: std.Build.LazyPath,
    version: ?[]const u8,
) build_common.StepFile {
    const cmd = b.addSystemCommand(&.{ "python3", dist_script_path, command });
    cmd.setCwd(b.path("."));
    const output = cmd.addOutputFileArg(zip_name);
    cmd.addArg(stage_name);
    cmd.addFileArg(outputs.program);
    cmd.addFileArg(outputs.map);
    cmd.addFileArg(test_pgms_bin);
    cmd.addFileArg(test_pgms_txt);
    cmd.addFileArg(test_pgms_zip);
    if (version) |value| cmd.addArg(value);
    return .{ .step = &cmd.step, .path = output };
}

fn addUnsupportedStep(b: *std.Build, step_name: []const u8, message: []const u8) *std.Build.Step {
    const cmd = build_common.addBashCommandFmt(b,
        \\echo '{s}' >&2
        \\exit 1
    , .{message});
    const step = b.step(step_name, message);
    step.dependOn(&cmd.step);
    return step;
}

fn distDirName(b: *std.Build, base: []const u8, ci_commit_tag: []const u8) []const u8 {
    if (ci_commit_tag.len == 0) return base;
    return b.fmt("{s}-{s}", .{ base, ci_commit_tag });
}
