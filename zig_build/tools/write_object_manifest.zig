//! Writes its object-path arguments to a file, one per line.
//!
//! This is how the build DECLARES the object set it links, so a gate can consume
//! the declaration instead of guessing at it from outside. Every wrong object-set
//! number this project has produced came from asking something other than the
//! build: a `.zig-cache` glob picked up a test artefact, a `c47-` prefix filter
//! dropped five `host-*` objects (14 reported against 19 linked), and
//! `--verbose-link` prints nothing at all on a cached build. The build cannot
//! disagree with what it links.
//!
//! argv[1] is the output path; argv[2..] are the object paths, passed by the build
//! as `addFileArg(obj.getEmittedBin())` so it resolves them and orders this step
//! after every object it names.

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();

    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, arena);
    defer args.deinit();
    _ = args.next(); // argv[0]

    const output_path = args.next() orelse return error.MissingOutputPath;

    var manifest: std.ArrayList(u8) = .empty;
    var count: usize = 0;
    while (args.next()) |object_path| {
        try manifest.appendSlice(arena, object_path);
        try manifest.append(arena, '\n');
        count += 1;
    }

    // A manifest with no objects is not a product: it is a broken measurement, and
    // a graph gate handed one would report a clean tree from nothing.
    if (count == 0) return error.EmptyObjectSet;

    try std.Io.Dir.cwd().writeFile(init.io, .{
        .sub_path = output_path,
        .data = manifest.items,
    });
}
