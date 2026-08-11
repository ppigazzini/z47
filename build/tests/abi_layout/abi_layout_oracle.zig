// SPDX-License-Identifier: GPL-3.0-only
//
// abi struct-layout parity oracle (seam-and-core roadmap, Phase 1 crux harness).
//
// abi/types.zig hand-mirrors the pinned upstream C numeric ABI. The colocated
// comptime block in that file pins the ZIG side against hardcoded offsets, but
// that is self-referential: it cannot catch upstream drift, and it cannot prove
// a future GENERATED abi/types.zig matches the C. This oracle closes that gap by
// comparing the abi mirrors DIRECTLY against the translate-c'd upstream headers
// (`@sizeOf`/`@offsetOf` of the real C `decNumber`/`decQuad`/`decContext`), so a
// wrong layout fails the build here -- the silent-corruption class (M10.4/M16)
// that sim+test do not surface.
//
// Run via `zig build abi-layout-parity`. This must gate green against the
// hand-maintained abi/types.zig before that file is generated; afterward it is
// the adjudicator that a regenerated seam still byte-matches the C.

const std = @import("std");
const testing = std.testing;
const c = @import("c_bindings");
const abi = @import("abi");

/// Assert a named field sits at the same byte offset in the C type and the abi
/// mirror. comptime so a mismatch is a compile error, not a late runtime fail.
fn expectSameOffset(comptime C: type, comptime Z: type, comptime field: []const u8) !void {
    try testing.expectEqual(@offsetOf(C, field), @offsetOf(Z, field));
}

fn expectSameSizeAlign(comptime C: type, comptime Z: type) !void {
    try testing.expectEqual(@sizeOf(C), @sizeOf(Z));
    try testing.expectEqual(@alignOf(C), @alignOf(Z));
}

test "abi.Real matches C decNumber (size + every field offset)" {
    try expectSameSizeAlign(c.decNumber, abi.Real);
    inline for (.{ "digits", "exponent", "bits", "lsu" }) |f| {
        try expectSameOffset(c.decNumber, abi.Real, f);
    }
}

test "abi.Real34 matches C decQuad (size)" {
    // decQuad is an opaque 16-byte union (natural align 4). abi.Real34 is a
    // `{ bytes: [16]u8 }` blob DELIBERATELY at align 1 so registers.zig can view
    // unaligned register storage as `*align(1) Real34`; that align-1 is benign
    // because Real34 only ever sits at 16-byte-aligned offsets in the abi
    // composites (Complex34, matrices). The contract for this opaque blob is its
    // size, so assert that and not the intentional align divergence.
    try testing.expectEqual(@sizeOf(c.decQuad), @sizeOf(abi.Real34));
}

test "abi.RealContext matches C decContext (every mirrored field offset)" {
    // decContext may carry extra members under DECSUBSET, so compare the field
    // offsets abi mirrors rather than the total size.
    inline for (.{ "digits", "emax", "emin", "round", "traps", "status", "clamp" }) |f| {
        try expectSameOffset(c.decContext, abi.RealContext, f);
    }
}

test "abi.Complex is two back-to-back C decNumbers" {
    try testing.expectEqual(@as(usize, 2) * @sizeOf(c.decNumber), @sizeOf(abi.Complex));
    try testing.expectEqual(@sizeOf(c.decNumber), @offsetOf(abi.Complex, "Imag"));
}

test "abi.Complex34 is two back-to-back C decQuads" {
    try testing.expectEqual(@as(usize, 2) * @sizeOf(c.decQuad), @sizeOf(abi.Complex34));
    try testing.expectEqual(@sizeOf(c.decQuad), @offsetOf(abi.Complex34, "imag"));
}

// The typeDefinitions.h calc structs. Size is the fork-reconciliation invariant
// (a wrong field type or dropped padding shifts sizeof, the exact bug class
// [[extern-struct-fork-reconciliation]] documents); alignment is asserted only
// where abi does not intentionally use an align-1 view. Each pair is
// {C type, abi type, name} so a mismatch names the culprit struct.
//
// Size alone does not pin the layout: transposing two equal-width members leaves
// sizeof untouched. Every field is therefore offset-checked as well, by name,
// against the C struct -- see the offset test below.
const SIZE_PAIRS = .{
    .{ c.calcKey_t, abi.CalcKey, "CalcKey" },
    .{ c.softmenu_t, abi.Softmenu, "Softmenu" },
    .{ c.item_t, abi.Item, "Item" },
    .{ c.dtConfigDescriptor_t, abi.DtConfigDescriptor, "DtConfigDescriptor" },
    .{ c.dynamicSoftmenu_t, abi.DynamicSoftmenu, "DynamicSoftmenu" },
    .{ c.fInMim_t, abi.FInMim, "FInMim" },
    .{ c.font_t, abi.Font, "Font" },
    .{ c.formulaHeader_t, abi.FormulaHeader, "FormulaHeader" },
    .{ c.freeMemoryRegion_t, abi.FreeMemoryRegion, "FreeMemoryRegion" },
    .{ c.glyph_t, abi.Glyph, "Glyph" },
    .{ c.glyphMartelPrinter_t, abi.GlyphMartelPrinter, "GlyphMartelPrinter" },
    .{ c.glyphPrinter_t, abi.GlyphPrinter, "GlyphPrinter" },
    .{ c.labelList_t, abi.LabelList, "LabelList" },
    .{ c.normKey_t, abi.NormKey, "NormKey" },
    .{ c.printerState_t, abi.PrinterState, "PrinterState" },
    .{ c.programList_t, abi.ProgramList, "ProgramList" },
    .{ c.programmableMenu_t, abi.ProgrammableMenu, "ProgrammableMenu" },
    .{ c.softmenuStack_t, abi.SoftmenuStack, "SoftmenuStack" },
    .{ c.strLgIntHeader_t, abi.StrLgIntHeader, "StrLgIntHeader" },
    .{ c.subroutineLevelHeader_t, abi.SubroutineLevelHeader, "SubroutineLevelHeader" },
    .{ c.subroutineLevels_t, abi.SubroutineLevels, "SubroutineLevels" },
    .{ c.tamState_t, abi.TamState, "TamState" },
    .{ c.userMenuItem_t, abi.UserMenuItem, "UserMenuItem" },
    .{ c.userMenu_t, abi.UserMenu, "UserMenu" },
    .{ c.confirmationTI_t, abi.ConfirmationTI, "ConfirmationTI" },
    .{ c.nameAlias_t, abi.NameAlias, "NameAlias" },
    .{ c.summationRegisterName_t, abi.SummationRegisterName, "SummationRegisterName" },
    .{ c.reservedVariableDescStr_t, abi.ReservedVariableDescStr, "ReservedVariableDescStr" },
    .{ c.letteredFlagDisplay_t, abi.LetteredFlagDisplay, "LetteredFlagDisplay" },
    .{ c.upperLower_t, abi.UpperLower, "UpperLower" },
    .{ c.calcKeyboard_t, abi.CalcKeyboard, "CalcKeyboard" },
    .{ c.cplx_t, abi.CmplxPair, "CmplxPair" },
    .{ c.__mpz_struct, abi.Mpz, "Mpz" },
};

test "abi calc structs match upstream C size" {
    inline for (SIZE_PAIRS) |pair| {
        testing.expectEqual(@sizeOf(pair[0]), @sizeOf(pair[1])) catch |err| {
            std.debug.print("size mismatch on {s}: C={d} abi={d}\n", .{ pair[2], @sizeOf(pair[0]), @sizeOf(pair[1]) });
            return err;
        };
    }
}

// The abi mirrors that deliberately rename a member. Each entry is
// {C type, abi type, name, .{ .{c field, abi field}, ... }}; everything else is
// matched by name in the test below.
const RENAMED_FIELDS = .{
    .{ c.cplx_t, abi.CmplxPair, "CmplxPair", .{ .{ "Real", "r" }, .{ "Imag", "i" } } },
};

// Fields the by-name sweep cannot look up on the C side, each with the reason.
// A field may only be listed here because translate-c cannot represent it -- not
// because it fails.
const UNMATCHABLE_FIELDS = .{
    // font_t's `glyph_t glyphs[]` is a flexible array member; translate-c emits
    // no field for it. Its offset is oracled through the C companion below.
    .{ abi.Font, "glyphs" },
};

fn skipsNameMatch(comptime Z: type, comptime field: []const u8) bool {
    inline for (RENAMED_FIELDS) |entry| {
        if (entry[1] != Z) continue;
        inline for (entry[3]) |mapping| {
            if (std.mem.eql(u8, mapping[1], field)) return true;
        }
    }
    inline for (UNMATCHABLE_FIELDS) |entry| {
        if (entry[0] == Z and std.mem.eql(u8, entry[1], field)) return true;
    }
    return false;
}

test "abi calc structs match upstream C field offsets" {
    @setEvalBranchQuota(20000);
    inline for (SIZE_PAIRS) |pair| {
        inline for (@typeInfo(pair[1]).@"struct".fields) |field| {
            if (comptime skipsNameMatch(pair[1], field.name)) continue;
            testing.expectEqual(@offsetOf(pair[0], field.name), @offsetOf(pair[1], field.name)) catch |err| {
                std.debug.print("offset mismatch on {s}.{s}: C={d} abi={d}\n", .{
                    pair[2],
                    field.name,
                    @offsetOf(pair[0], field.name),
                    @offsetOf(pair[1], field.name),
                });
                return err;
            };
        }
    }
}

test "abi mirrors that rename a member still match the C offsets" {
    inline for (RENAMED_FIELDS) |entry| {
        inline for (entry[3]) |mapping| {
            testing.expectEqual(@offsetOf(entry[0], mapping[0]), @offsetOf(entry[1], mapping[1])) catch |err| {
                std.debug.print("offset mismatch on {s}.{s} (C {s}): C={d} abi={d}\n", .{
                    entry[2],
                    mapping[1],
                    mapping[0],
                    @offsetOf(entry[0], mapping[0]),
                    @offsetOf(entry[1], mapping[1]),
                });
                return err;
            };
        }
    }
}

// registerHeader_t and matrixHeader_t are C bitfield types; translate-c demotes
// them to opaque{}, so the sizeof/offset machinery above cannot reach the bit
// positions of the fields inside the 32-bit word. The C companion
// (abi_layout_c_asserts.c) returns each field's true packed mask; these tests set
// the SAME field all-ones in the abi packed struct, bitcast to u32, and require
// an exact match -- proving abi's hand-written packing is bit-identical to the C
// bitfield (a wrong bit position keeps sizeof==4 but mis-routes register/matrix
// dispatch). The all-ones value per field is its declared bit width.
extern fn z47_reg_header_field_mask(field: c_int) u32;
extern fn z47_matrix_header_field_mask(field: c_int) u32;

test "abi.RegisterHeaderBits packs bit-identically to C registerHeader_t" {
    const FIELDS = .{
        .{ "pointerToRegisterData", @as(u16, 0xFFFF), 0 },
        .{ "dataType", @as(u4, 0xF), 1 },
        .{ "tag", @as(u5, 0x1F), 2 },
        .{ "readOnly", @as(u1, 1), 3 },
        .{ "notUsed", @as(u6, 0x3F), 4 },
    };
    inline for (FIELDS) |f| {
        var z: abi.RegisterHeaderBits = @bitCast(@as(u32, 0));
        @field(z, f[0]) = f[1];
        const zmask: u32 = @bitCast(z);
        testing.expectEqual(z47_reg_header_field_mask(f[2]), zmask) catch |err| {
            std.debug.print("registerHeader bit mismatch on {s}: C=0x{x:0>8} abi=0x{x:0>8}\n", .{ f[0], z47_reg_header_field_mask(f[2]), zmask });
            return err;
        };
    }
}

// The aggregates that embed one of those two bitfield words are opaque{} to
// translate-c as well, so they cannot go in SIZE_PAIRS. The C companion hands
// their layout over by index; the lists below must stay in step with its
// switches.
extern fn z47_bitfield_aggregate_size(which: c_int) usize;
extern fn z47_bitfield_aggregate_align(which: c_int) usize;
extern fn z47_bitfield_aggregate_field_offset(which: c_int) usize;

const BITFIELD_AGGREGATES = .{
    .{ abi.Real34Matrix, "Real34Matrix", 0 },
    .{ abi.Complex34Matrix, "Complex34Matrix", 1 },
    .{ abi.Any34Matrix, "Any34Matrix", 2 },
    .{ abi.NamedVariableHeader, "NamedVariableHeader", 3 },
    .{ abi.ReservedVariableHeader, "ReservedVariableHeader", 4 },
};

const BITFIELD_AGGREGATE_FIELDS = .{
    .{ abi.Real34Matrix, "Real34Matrix", "header", 0 },
    .{ abi.Real34Matrix, "Real34Matrix", "matrixElements", 1 },
    .{ abi.Complex34Matrix, "Complex34Matrix", "header", 2 },
    .{ abi.Complex34Matrix, "Complex34Matrix", "matrixElements", 3 },
    .{ abi.NamedVariableHeader, "NamedVariableHeader", "header", 4 },
    .{ abi.NamedVariableHeader, "NamedVariableHeader", "variableName", 5 },
    .{ abi.ReservedVariableHeader, "ReservedVariableHeader", "header", 6 },
    .{ abi.ReservedVariableHeader, "ReservedVariableHeader", "reservedVariableName", 7 },
};

test "abi bitfield-embedding aggregates match the C size and alignment" {
    inline for (BITFIELD_AGGREGATES) |entry| {
        const c_size = z47_bitfield_aggregate_size(entry[2]);
        testing.expectEqual(c_size, @sizeOf(entry[0])) catch |err| {
            std.debug.print("size mismatch on {s}: C={d} abi={d}\n", .{ entry[1], c_size, @sizeOf(entry[0]) });
            return err;
        };
        const c_align = z47_bitfield_aggregate_align(entry[2]);
        testing.expectEqual(c_align, @alignOf(entry[0])) catch |err| {
            std.debug.print("align mismatch on {s}: C={d} abi={d}\n", .{ entry[1], c_align, @alignOf(entry[0]) });
            return err;
        };
    }
}

test "abi bitfield-embedding aggregates match the C field offsets" {
    inline for (BITFIELD_AGGREGATE_FIELDS) |entry| {
        const c_offset = z47_bitfield_aggregate_field_offset(entry[3]);
        const z_offset = @offsetOf(entry[0], entry[2]);
        testing.expectEqual(c_offset, z_offset) catch |err| {
            std.debug.print("offset mismatch on {s}.{s}: C={d} abi={d}\n", .{ entry[1], entry[2], c_offset, z_offset });
            return err;
        };
    }
}

extern fn z47_flexible_array_member_offset(which: c_int) usize;

test "abi.Font's glyphs array starts where font_t's flexible member does" {
    const c_offset = z47_flexible_array_member_offset(0);
    try testing.expectEqual(c_offset, @offsetOf(abi.Font, "glyphs"));
}

// dt_t / tm_t live in the DMCP SDK (dmcp.h), which is a git submodule the
// firmware build needs and this host lane deliberately does not: making the
// layout gate require it would break the lane on a clone without submodules.
// The mirrors are pinned here against the SDK declaration instead, so a hand
// edit to either mirror still fails a gate.
test "abi.DateShort mirrors the SDK dt_t" {
    try testing.expectEqual(@as(usize, 4), @sizeOf(abi.DateShort));
    try testing.expectEqual(@as(usize, 0), @offsetOf(abi.DateShort, "year"));
    try testing.expectEqual(@as(usize, 2), @offsetOf(abi.DateShort, "month"));
    try testing.expectEqual(@as(usize, 3), @offsetOf(abi.DateShort, "day"));
}

test "abi.TimeShort mirrors the SDK tm_t" {
    try testing.expectEqual(@as(usize, 5), @sizeOf(abi.TimeShort));
    try testing.expectEqual(@as(usize, 0), @offsetOf(abi.TimeShort, "hour"));
    try testing.expectEqual(@as(usize, 1), @offsetOf(abi.TimeShort, "min"));
    try testing.expectEqual(@as(usize, 2), @offsetOf(abi.TimeShort, "sec"));
    try testing.expectEqual(@as(usize, 3), @offsetOf(abi.TimeShort, "csec"));
    try testing.expectEqual(@as(usize, 4), @offsetOf(abi.TimeShort, "dow"));
}

test "abi.MatrixHeader packs bit-identically to C matrixHeader_t" {
    const FIELDS = .{
        .{ "matrixRows", @as(u12, 0xFFF), 0 },
        .{ "matrixColumns", @as(u12, 0xFFF), 1 },
        .{ "mtag", @as(u6, 0x3F), 2 },
        .{ "notUsed", @as(u2, 0x3), 3 },
    };
    inline for (FIELDS) |f| {
        var z: abi.MatrixHeader = @bitCast(@as(u32, 0));
        @field(z, f[0]) = f[1];
        const zmask: u32 = @bitCast(z);
        testing.expectEqual(z47_matrix_header_field_mask(f[2]), zmask) catch |err| {
            std.debug.print("matrixHeader bit mismatch on {s}: C=0x{x:0>8} abi=0x{x:0>8}\n", .{ f[0], z47_matrix_header_field_mask(f[2]), zmask });
            return err;
        };
    }
}
