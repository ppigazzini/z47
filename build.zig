const std = @import("std");
const build_common = @import("zig_build/common.zig");
const dist_steps = @import("zig_build/dist.zig");
const firmware_steps = @import("zig_build/firmware.zig");
const host_steps = @import("zig_build/host.zig");
const object_manifest = @import("zig_build/object_manifest.zig");

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

    // The object graph is what the linker builds, and it is orthogonal to the
    // @import graph a reader navigates: moving a file between directories changes
    // the second and cannot change the first. Here the build DECLARES the object
    // set of each product so check-object-graph.py can consume the declaration.
    // Every wrong object-set number produced against this codebase came from
    // asking something other than the build -- a cache glob, a name-prefix filter,
    // a --verbose-link scrape that prints nothing on a cached build.
    {
        const writer = object_manifest.addWriter(b, host_context.host_target, optimize);
        const step = b.step(
            "object-manifest",
            "Declare the linked object set of each product target for the object-graph gate",
        );

        // The simulator hands its objects to a module, so the manifest walks it.
        step.dependOn(&b.addInstallFile(
            object_manifest.add(b, writer, "sim", host_outputs.c47_exe),
            "object-graph/sim-objects.txt",
        ).step);

        // The firmware drives arm-none-eabi-gcc directly, so its object set is the
        // same named list the link command consumes.
        for ([_]struct { name: []const u8, build: firmware_steps.Build }{
            .{ .name = "dmcp", .build = firmware_bundle.dmcp },
            .{ .name = "dmcp5", .build = firmware_bundle.dmcp5 },
        }) |target| {
            const pending = object_manifest.start(b, writer, target.name);
            target.build.objects.addToCommand(pending.run);
            step.dependOn(&b.addInstallFile(
                pending.path,
                b.fmt("object-graph/{s}-objects.txt", .{target.name}),
            ).step);
        }
    }

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
        "zig_src/core/numeric/integer/core.zig",
        "zig_src/core/persist/calc_state_progmem.zig",
        "zig_src/core/state/register_metadata/register_metadata_payload_bytes.zig",
        "zig_src/core/state/register_metadata/register_descriptor_codec.zig",
        "zig_src/core/memory/block_availability_pure.zig",
        "zig_src/core/state/flags/flag_classify.zig",
        "zig_src/core/persist/vector_shape.zig",
        "zig_src/core/state/stack/register_range_ops.zig",
        "zig_src/core/persist/data_file_bytes.zig",
        "zig_src/core/state/register_metadata/name_glyph.zig",
        "zig_src/core/persist/word_scan.zig",
        "zig_src/core/state/stack/real34_sign.zig",
        "zig_src/core/state/register_metadata/reserved_register.zig",
        "zig_src/core/input/solver_status.zig",
        "zig_src/core/state/flags/flag_bits.zig",
        "zig_src/core/input/keyboard_hit_test.zig",
        "zig_src/shell/display/statusbar/status_bar_geometry.zig",
        "zig_src/shell/display/softmenus/softmenu_math.zig",
        "zig_src/core/state/runtime/stack_runtime_register_range.zig",
        "zig_src/core/numeric/compare/real_predicates.zig",
        "zig_src/core/numeric/compare/register_classify.zig",
        "zig_src/core/numeric/number_theory/small_prime_list.zig",
        "zig_src/core/numeric/matrix/kinds.zig",
        "zig_src/core/numeric/compare/type_encode.zig",
        "zig_src/core/numeric/matrix/mim_util.zig",
        "zig_src/abi/int_math.zig",
        "zig_src/abi/shortint_arith.zig",
        "zig_src/abi/sci_format.zig",
        "zig_src/abi/glyph_code.zig",
        "zig_src/abi/complex_text.zig",
        "zig_src/abi/pcg32.zig",
        "zig_src/abi/c47_string.zig",
        "zig_src/shell/input/keycode_remap.zig",
        "zig_src/shell/display/lr_selection.zig",
        "zig_src/shell/plot/plot_viewport.zig",
        "zig_src/shell/convert/conversion_pairs.zig",
        "zig_src/shell/display/fonts/glyph_font_search.zig",
        "zig_src/shell/program/program_step_width.zig",
        "zig_src/shell/print/printer_text_width.zig",
        "zig_src/shell/print/printer_glyph_search.zig",
        "zig_src/core/analysis/label_range.zig",
        "zig_src/shell/timer_math.zig",
        "zig_src/shell/input/adm_encoding.zig",
        "zig_src/shell/plot/plot_regression_selection.zig",
        "zig_src/shell/word_size_math.zig",
        "zig_src/shell/print/printer_char_map.zig",
        "zig_src/shell/display/text/numeral_grouping.zig",
        "zig_src/shell/program/numeral_decode.zig",
        "zig_src/shell/display/text/glyph_case.zig",
        "zig_src/shell/display/text/alpha_substring.zig",
        "zig_src/shell/convert/fraction_encode.zig",
        "zig_src/shell/display/text/label_truncate.zig",
        "zig_src/shell/vbat_integrator.zig",
        "zig_src/shell/program/program_step_opcode.zig",
        "zig_src/shell/plot/plot_zoom.zig",
        "zig_src/shell/display/text/str_concat.zig",
        "zig_src/shell/display/text/word_break.zig",
        "zig_src/shell/display/text/gap_char_codec.zig",
        "zig_src/shell/display/text/integer_separators.zig",
        "zig_src/shell/matrix_editor/matrix_wrap.zig",
        "zig_src/shell/store_register_range.zig",
        "zig_src/shell/program/ks_register_remap.zig",
        "zig_src/shell/display/text/gap_insert.zig",
        "zig_src/shell/display/text/display_string_transform.zig",
        "zig_src/shell/convert/conversion_name_codec.zig",
        "zig_src/shell/display/text/string_edit.zig",
        "zig_src/shell/display/text/glyph_text_lookup.zig",
        "zig_src/shell/display/text/glyph_export.zig",
        "zig_src/shell/register_data_type.zig",
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
