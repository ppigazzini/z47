const std = @import("std");
const build_common = @import("zig_build/common.zig");
const dist_steps = @import("zig_build/dist.zig");
const firmware_steps = @import("zig_build/firmware.zig");
const host_steps = @import("zig_build/host.zig");

pub fn build(b: *std.Build) void {
    buildImpl(b) catch |err| {
        std.debug.panic("build.zig configuration failed: {s}", .{@errorName(err)});
    };
}

fn buildImpl(b: *std.Build) !void {
    registerCDependencyAuditStep(b);
    registerNativeUnitTests(b);

    const optimize = b.standardOptimizeOption(.{});
    const ci_commit_tag = b.option([]const u8, "ci-commit-tag", "Commit tag for version information") orelse "";
    const raspberry = b.option(bool, "raspberry", "Enable Raspberry Pi layout") orelse false;
    const decnumber_fastmul = b.option(bool, "decnumber-fastmul", "Enable DECNUMBER_FASTMUL") orelse true;
    const dmcp_package = b.option(u8, "dmcp-package", "Select the upstream DMCP package variant") orelse 4;

    const host_context = try host_steps.prepareContext(b, optimize, ci_commit_tag, raspberry, decnumber_fastmul);
    const host_outputs = host_steps.registerSteps(b, host_context, optimize);

    const firmware_bundle = firmware_steps.registerSteps(
        b,
        host_context,
        optimize,
        dmcp_package,
        decnumber_fastmul,
    );

    const dist_version = if (ci_commit_tag.len > 0)
        ci_commit_tag
    else
        build_common.commandOutput(b, &.{ "git", "describe", "--match=NeVeRmAtCh", "--always", "--abbrev=8", "--dirty=-mod" }) orelse "unknown";

    try dist_steps.registerSteps(
        b,
        host_context,
        host_outputs,
        firmware_bundle,
        ci_commit_tag,
        dist_version,
    );
}

// REPORT-27 M-IDIOM-3: native Zig unit tests that run without the upstream C
// oracle. Only self-contained, std-only pure-logic modules belong here (no
// global calculator state, no C extern, no build_options). This gives a
// correctness signal independent of the C testSuite. Extend `pure_modules` as
// more owners are made standalone-testable.
fn registerNativeUnitTests(b: *std.Build) void {
    const pure_modules = [_][]const u8{
        "zig_src/abi/float_format.zig",
        "zig_src/abi/types.zig",
        "zig_src/shortint/shortint_core.zig",
        "zig_src/state/calc_state_progmem.zig",
        "zig_src/state/register_metadata_payload_bytes.zig",
        "zig_src/state/stack_runtime_register_range.zig",
        "zig_src/mathematics/math_real_predicates.zig",
        "zig_src/abi/int_math.zig",
        "zig_src/abi/shortint_arith.zig",
        "zig_src/abi/sci_format.zig",
        "zig_src/abi/glyph_code.zig",
        "zig_src/abi/complex_text.zig",
        "zig_src/abi/pcg32.zig",
        "zig_src/abi/c47_string.zig",
        "zig_src/frontier/keycode_remap.zig",
        "zig_src/frontier/lr_selection.zig",
        "zig_src/frontier/display_string_transform.zig",
        "zig_src/frontier/conversion_name_codec.zig",
        "zig_src/frontier/string_edit.zig",
        "zig_src/frontier/glyph_text_lookup.zig",
        "zig_src/frontier/glyph_export.zig",
        "zig_src/frontier/register_data_type.zig",
        "zig_src/abi/block_math.zig",
    };
    const target = b.resolveTargetQuery(.{});
    // Some pure owners reference the std-only L1 ABI types via @import("abi");
    // provide that module so they stay self-contained under test:unit.
    const abi_module = b.createModule(.{
        .root_source_file = b.path("zig_src/abi/types.zig"),
        .target = target,
        .optimize = .Debug,
    });
    const step = b.step("test:unit", "Run native Zig unit tests (no C oracle)");
    for (pure_modules) |src| {
        const mod = b.createModule(.{
            .root_source_file = b.path(src),
            .target = target,
            .optimize = .Debug,
        });
        mod.addImport("abi", abi_module);
        const unit = b.addTest(.{ .root_module = mod });
        step.dependOn(&b.addRunArtifact(unit).step);
    }
}

fn registerCDependencyAuditStep(b: *std.Build) void {
    const phase_i_policy_cmd = b.addSystemCommand(&.{
        "bash",
        ".github/project/check-c-dependency-phase-i-policy.sh",
        ".",
    });

    const phase_i_policy_step = b.step(
        "check-c-deps-policy",
        "Run Phase I dependency policy (baseline transition to external-only zero gates)",
    );
    phase_i_policy_step.dependOn(&phase_i_policy_cmd.step);

    const audit_cmd = b.addSystemCommand(&.{
        "python3",
        ".github/project/check-c-dependency-allowlist.py",
        "--repo-root",
        ".",
        "--config",
        ".github/project/c-dependency-allowlist.json",
    });

    const audit_step = b.step("check-c-deps", "Audit C dependency allowlist and first-party baseline");
    audit_step.dependOn(&audit_cmd.step);

    const strict_zero_cmd = b.addSystemCommand(&.{
        "python3",
        ".github/project/check-c-dependency-allowlist.py",
        "--repo-root",
        ".",
        "--config",
        ".github/project/c-dependency-allowlist.json",
        "--max-first-party",
        "0",
    });

    const strict_zero_step = b.step("check-c-deps-zero", "Fail when any first-party C dependency remains in build wiring");
    strict_zero_step.dependOn(&strict_zero_cmd.step);

    const product_audit_cmd = b.addSystemCommand(&.{
        "python3",
        ".github/project/check-c-dependency-allowlist.py",
        "--repo-root",
        ".",
        "--config",
        ".github/project/c-dependency-product-allowlist.json",
    });

    const product_audit_step = b.step("check-c-deps-product", "Audit product-lane C dependencies with oracle/test lanes excluded");
    product_audit_step.dependOn(&product_audit_cmd.step);

    const product_zero_cmd = b.addSystemCommand(&.{
        "python3",
        ".github/project/check-c-dependency-allowlist.py",
        "--repo-root",
        ".",
        "--config",
        ".github/project/c-dependency-product-allowlist.json",
        "--max-first-party",
        "0",
    });

    const product_zero_step = b.step("check-c-deps-product-zero", "Fail when any first-party C dependency remains in product lanes");
    product_zero_step.dependOn(&product_zero_cmd.step);
}
