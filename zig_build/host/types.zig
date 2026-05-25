const std = @import("std");
const keyboard_state = @import("../state/keyboard_state.zig");
const shortint = @import("../leaf/shortint.zig");
const stack = @import("../state/stack.zig");

pub const CommonConfig = struct {
    platform_define: []const u8,
    word_size_define: []const u8,
    raspberry: bool,
    decnumber_fastmul: bool,
    with_pulseaudio: bool,
    needs_gnu_source: bool,
    have_dladdr: bool,
    needs_libdl: bool,
};

pub const GeneratedOutputs = struct {
    raster_fonts_data: std.Build.LazyPath,
    softmenu_catalogs: std.Build.LazyPath,
    constant_pointers_c: std.Build.LazyPath,
    constant_pointers_h: std.Build.LazyPath,
    constant_pointers2_c: std.Build.LazyPath,
    test_pgms_bin: std.Build.LazyPath,
};

pub const ShortIntLeafObjects = shortint.RuntimeObjects;
pub const KeyboardStateObjects = keyboard_state.RuntimeObjects;
pub const StackStateObjects = stack.RuntimeObjects;

pub const Context = struct {
    host_target: std.Build.ResolvedTarget,
    common: CommonConfig,
    raw_core_sources: [][]const u8,
    core_sources: [][]const u8,
    gtk_sources: [][]const u8,
    test_sources: [][]const u8,
    version_headers_dir: std.Build.LazyPath,
    generated: GeneratedOutputs,
    shortint_leaf_objects: ShortIntLeafObjects,
    keyboard_state_objects: KeyboardStateObjects,
    stack_state_objects: StackStateObjects,
};

pub const SimulatorOutputs = struct {
    c47_bin: std.Build.LazyPath,
    r47_bin: std.Build.LazyPath,
};
