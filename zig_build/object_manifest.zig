//! The object manifest: the build naming its own product object set.
//!
//! WHAT THIS IS FOR. z47 has two dependency graphs and they are orthogonal. The
//! MODULE graph is `@import` over `zig_src/` -- what a reader navigates, gated by
//! `check-module-graph.py`. The OBJECT graph is what the linker builds: its nodes
//! are the build roots declared in `zig_build/`, and its edges are undefined
//! symbols resolved against other objects' defined symbols. Moving a file between
//! directories changes the first graph and cannot change the second. The object
//! graph is the one that decides what a firmware package must carry and what a
//! parity suite can link standalone, and until now nothing pinned it.
//!
//! WHY IT IS A BUILD STEP AND NOT A SCRIPT. Every wrong object-set number produced
//! against this codebase came from asking something other than the build. A
//! `.zig-cache` glob included a test artefact. A `c47-` prefix filter dropped the
//! five `host-*` objects: 14 reported against 19 linked. And `zig build --verbose-link`
//! emits the object list ONLY when a link actually runs -- on a cached build it
//! prints nothing, and neither removing the installed binary nor deleting the
//! linked exe from the cache forces a relink. A gate built on that scrape would
//! observe the true set in CI and silently observe NOTHING locally, which is worse
//! than no gate.
//!
//! `Module.link_objects` is the list the linker is assembled from. Reading it
//! cannot disagree with what gets linked, on any target, cached or cold.

const std = @import("std");

/// Every `*Step.Compile` reachable from `root`, in deterministic order.
///
/// Objects arrive by two routes and both must be walked: `module.addObject(o)`
/// appends to `link_objects`, and an imported module contributes its own objects
/// to the link (`host/gtk_gui.zig` builds four runtime objects and attaches them
/// to a module the exe imports). Walking only the root's `link_objects` would miss
/// those; walking only the import table would miss the ones attached directly.
fn collect(
    arena: std.mem.Allocator,
    root: *std.Build.Module,
    out: *std.ArrayList(*std.Build.Step.Compile),
    seen_modules: *std.AutoHashMapUnmanaged(*std.Build.Module, void),
    seen_objects: *std.AutoHashMapUnmanaged(*std.Build.Step.Compile, void),
) void {
    const module_gop = seen_modules.getOrPut(arena, root) catch @panic("OOM");
    if (module_gop.found_existing) return;

    for (root.link_objects.items) |link_object| switch (link_object) {
        .other_step => |compile| {
            const gop = seen_objects.getOrPut(arena, compile) catch @panic("OOM");
            if (!gop.found_existing) {
                out.append(arena, compile) catch @panic("OOM");
                // An object may itself link further objects.
                collect(arena, compile.root_module, out, seen_modules, seen_objects);
            }
        },
        // C sources, assembly and system libraries are compiled INTO the object
        // that names them; they are not nodes of the object graph.
        else => {},
    };

    for (root.import_table.values()) |imported| {
        collect(arena, imported, out, seen_modules, seen_objects);
    }
}

/// Declare `exe`'s object set as a file, and return its path.
///
/// The returned `LazyPath` carries the dependency edge, so the manifest is written
/// only after every object it names has been emitted.
pub fn add(
    b: *std.Build,
    writer_exe: *std.Build.Step.Compile,
    target_name: []const u8,
    exe: *std.Build.Step.Compile,
) std.Build.LazyPath {
    var objects: std.ArrayList(*std.Build.Step.Compile) = .empty;
    var seen_modules: std.AutoHashMapUnmanaged(*std.Build.Module, void) = .empty;
    var seen_objects: std.AutoHashMapUnmanaged(*std.Build.Step.Compile, void) = .empty;
    collect(b.allocator, exe.root_module, &objects, &seen_modules, &seen_objects);

    const run = b.addRunArtifact(writer_exe);
    const manifest = run.addOutputFileArg(b.fmt("{s}-objects.txt", .{target_name}));
    for (objects.items) |object| run.addFileArg(object.getEmittedBin());
    return manifest;
}

/// A manifest under construction, for products whose objects are handed to a link
/// COMMAND rather than to a module -- the firmware drives `arm-none-eabi-gcc`
/// directly, so there is no `Module.link_objects` to walk. The caller appends the
/// same object set it gives the linker, via that set's own `addToCommand`.
pub const Pending = struct {
    run: *std.Build.Step.Run,
    path: std.Build.LazyPath,
};

/// Begin declaring a manifest for a command-linked product.
pub fn start(
    b: *std.Build,
    writer_exe: *std.Build.Step.Compile,
    target_name: []const u8,
) Pending {
    const run = b.addRunArtifact(writer_exe);
    return .{ .run = run, .path = run.addOutputFileArg(b.fmt("{s}-objects.txt", .{target_name})) };
}

/// The tool that writes a manifest. Built once and shared by every target.
pub fn addWriter(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) *std.Build.Step.Compile {
    return b.addExecutable(.{
        .name = "writeObjectManifest",
        .root_module = b.createModule(.{
            .root_source_file = b.path("zig_build/tools/write_object_manifest.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
}
