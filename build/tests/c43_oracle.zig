// SPDX-License-Identifier: GPL-3.0-only
//
// The compile-from-c43 parity-harness recipe, in one place.
//
// A parity oracle must be, or be compiled from, unmodified c43 source -- a
// hand-transliterated one cannot see c43 move, so the lane whose purpose is
// catching a c43 change becomes the reason nobody sees it. See
// docs/70-tests-and-verification.md.
//
// The first two conversions each did that with a per-lane mock `c47.h`.
// Measuring the alternative showed it wins outright: upstream's own
// `src/c47/c47.h` compiles in a headless harness given four include roots and six
// placeholder typedefs, so every constant, struct and prototype comes from the pin
// instead of from a copy. A conversion is then `#define` renames plus one
// `#include` of the c43 `.c`.
//
// WHY A HELPER AND NOT A COMMENT IN A RUNBOOK. Three conversions were queued when
// this landed. Rediscovering the include roots per lane is exactly how the mock
// headers drifted apart in the first place; `check-harness-constant-copies.py` is
// the gate that keeps them from drifting again, and this is the thing that makes
// not-copying easy.
//
// NOT RETROFITTED ONTO flags / program_serialization, deliberately: both are
// green, verified and seen-to-fail against their own mock `c47.h`. Churning two
// working lanes to make the tree stylistically uniform risks the only two
// conversions that exist for no verification gain. The divergence in style is a
// recorded decision, not an oversight -- it is noted in both harness headers.
//
// NOTHING CALLS THIS TODAY, and that is worth stating rather than hiding. The
// three most recent conversions -- calc_state, register_metadata,
// keyboard_state -- all took the FULL-CORE shape instead, because in each case
// the environment a unit harness would have to model IS the thing under test
// (the register pool, the value codecs, the GTK-bound entry path). A full core
// shares all of it by construction and needs no include roots of its own.
//
// It is kept, not deleted, for two reasons. It is the recorded recipe for the
// next UNIT conversion, which is the shape `flags` and `program_serialization`
// use and the shape the harness-constant backlog will need. And it does not rot
// unnoticed: `.github/project/check-harness-constant-copies.py` compiles every
// hand-declared harness constant against exactly these four include roots and
// the same prelude, on every gate run, so a root that stopped working would fail
// there. Keep the two in step -- the gate says so too.

const std = @import("std");
const build_common = @import("../common.zig");
const host_platform = @import("../host/platform.zig");
const host_types = @import("../host/types.zig");

/// Put the four include roots a compiled-from-c43 oracle needs on `module`, plus
/// the same PC_BUILD/platform/word-size macros the product host build uses.
///
/// The macros are not a detail: `defines.h` refuses to compile without one of
/// PC_BUILD / DMCP_BUILD, and picking a different set here would make the oracle
/// a DIFFERENT CONFIGURATION of c43 rather than c43. Take the host build's.
///
/// Root order matters. `build/tests/common` goes first so its stub
/// `gtk/gtk.h` and `gdk/gdk.h` shadow the system toolkit headers -- a headless
/// unit harness must not pull real GTK in.
pub fn addUpstreamHeaderRoots(
    b: *std.Build,
    module: *std.Build.Module,
    common: host_types.CommonConfig,
) void {
    host_platform.addHostMacros(module, common);

    // Stub gtk/gdk + the six placeholder typedefs. MUST precede the system paths.
    module.addIncludePath(b.path("build/tests/common"));
    // decQuad/decNumber types the core headers declare fields with.
    module.addIncludePath(build_common.upstreamPath(b, "dep/decNumberICU"));
    // constantPointers.h, which c47.h includes. It is NOT committed: `zig build
    // update_constants` writes it here from the generator's output, so this root
    // only resolves in a tree where that has run. A lane that must work from a
    // bare checkout should take the generator's LazyPath from the build graph
    // instead, the way the constants parity lane does.
    module.addIncludePath(build_common.upstreamPath(b, "src/generated"));
    // c43's own headers -- the point of the exercise.
    module.addIncludePath(build_common.upstreamPath(b, "src/c47"));
}
