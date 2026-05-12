const builtin = @import("builtin");
const std = @import("std");

const c = @cImport({
    @cInclude("stdio.h");
    @cInclude("stdlib.h");
    @cInclude("stdint.h");
    @cInclude("ft2build.h");
    @cInclude("freetype/freetype.h");
    @cInclude("freetype/ftsnames.h");
});

const GeneratorError = std.mem.Allocator.Error || error{
    FileOpenFailed,
    FileWriteFailed,
    XlsxConversionFailed,
    InvalidCsv,
    MissingGlyphRank,
    FreetypeInitFailed,
    FreetypeFaceFailed,
    FreetypeSizeFailed,
    FreetypeLoadFailed,
};

const GlyphRank = struct {
    code_point: u16,
    rank1: i16,
    rank2: i16,
};

const FontSpec = struct {
    file_name: []const u8,
    symbol_name: []const u8,
    id: u8,
    uses_ranks: bool,
};

const fonts = [_]FontSpec{
    .{ .file_name = "C47__NumericFont.ttf", .symbol_name = "numericFont", .id = 0, .uses_ranks = false },
    .{ .file_name = "C47__StandardFont.ttf", .symbol_name = "standardFont", .id = 1, .uses_ranks = true },
    .{ .file_name = "C47__TinyFont.ttf", .symbol_name = "tinyFont", .id = 2, .uses_ranks = false },
};

pub fn main(init: std.process.Init) !void {
    const allocator = std.heap.page_allocator;

    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();

    _ = args.next();
    const fonts_path = args.next() orelse {
        std.debug.print("Usage: ttf2RasterFonts <font dir> <output file>\n", .{});
        std.process.exit(1);
    };
    const output_path = args.next() orelse {
        std.debug.print("Usage: ttf2RasterFonts <font dir> <output file>\n", .{});
        std.process.exit(1);
    };

    const glyph_ranks = try loadGlyphRanks(allocator, fonts_path);
    defer allocator.free(glyph_ranks);

    const c_output_path = try dupeZ(allocator, output_path);
    defer allocator.free(c_output_path);

    const output_file = c.fopen(c_output_path.ptr, "wb") orelse return error.FileOpenFailed;
    defer _ = c.fclose(output_file);

    try writeHeader(output_file);

    var library: c.FT_Library = undefined;
    if (c.FT_Init_FreeType(&library) != c.FT_Err_Ok) return error.FreetypeInitFailed;
    defer _ = c.FT_Done_FreeType(library);

    for (fonts) |font| {
        try exportFont(allocator, output_file, library, glyph_ranks, fonts_path, font);
    }
}

fn loadGlyphRanks(allocator: std.mem.Allocator, fonts_path: []const u8) GeneratorError![]GlyphRank {
    const csv_path = try allocPrintZ(allocator, "{s}/sortingOrder.xlsx.sortingOrder.csv", .{fonts_path});
    defer allocator.free(csv_path);
    _ = c.remove(csv_path.ptr);

    const command = try buildXlsxCommand(allocator, fonts_path);
    defer allocator.free(command);

    if (c.system(command.ptr) != 0) return error.XlsxConversionFailed;
    defer _ = c.remove(csv_path.ptr);

    const file = c.fopen(csv_path.ptr, "rb") orelse return error.FileOpenFailed;
    defer _ = c.fclose(file);

    var line_buffer: [4096:0]u8 = [_:0]u8{0} ** 4096;
    if (c.fgets(@ptrCast(&line_buffer), line_buffer.len, file) == null) {
        return error.InvalidCsv;
    }

    var ranks = try std.ArrayList(GlyphRank).initCapacity(allocator, 0);
    errdefer ranks.deinit(allocator);

    while (c.fgets(@ptrCast(&line_buffer), line_buffer.len, file) != null) {
        const line = trimLineEnding(std.mem.sliceTo(&line_buffer, 0));
        if (line.len == 0) continue;
        try ranks.append(allocator, try parseGlyphRankLine(line));
    }

    return try ranks.toOwnedSlice(allocator);
}

fn buildXlsxCommand(allocator: std.mem.Allocator, fonts_path: []const u8) std.mem.Allocator.Error![:0]u8 {
    return switch (builtin.target.os.tag) {
        .linux => allocPrintZ(
            allocator,
            "LD_LIBRARY_PATH=\"$HOME/.local/lib${{LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}}\" xlsxio_xlsx2csv -b \"{s}/sortingOrder.xlsx\" >/dev/null",
            .{fonts_path},
        ),
        .macos => allocPrintZ(
            allocator,
            "DYLD_LIBRARY_PATH=\"$HOME/.local/lib${{DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}}\" xlsxio_xlsx2csv -b \"{s}/sortingOrder.xlsx\" >/dev/null",
            .{fonts_path},
        ),
        else => allocPrintZ(allocator, "xlsxio_xlsx2csv -b \"{s}/sortingOrder.xlsx\"", .{fonts_path}),
    };
}

fn parseGlyphRankLine(line: []const u8) GeneratorError!GlyphRank {
    const first_comma = std.mem.indexOfScalar(u8, line, ',') orelse return error.InvalidCsv;
    const second_comma = std.mem.indexOfScalarPos(u8, line, first_comma + 1, ',') orelse return error.InvalidCsv;
    const third_comma = std.mem.indexOfScalarPos(u8, line, second_comma + 1, ',') orelse return error.InvalidCsv;

    const code_field = line[0..first_comma];
    if (!std.mem.startsWith(u8, code_field, "U+")) return error.InvalidCsv;

    return .{
        .code_point = std.fmt.parseUnsigned(u16, code_field[2..], 16) catch return error.InvalidCsv,
        .rank1 = std.fmt.parseInt(i16, line[first_comma + 1 .. second_comma], 10) catch return error.InvalidCsv,
        .rank2 = std.fmt.parseInt(i16, line[second_comma + 1 .. third_comma], 10) catch return error.InvalidCsv,
    };
}

fn exportFont(
    allocator: std.mem.Allocator,
    output_file: *c.FILE,
    library: c.FT_Library,
    glyph_ranks: []const GlyphRank,
    fonts_path: []const u8,
    font: FontSpec,
) GeneratorError!void {
    const face_path = try allocPrintZ(allocator, "{s}/{s}", .{ fonts_path, font.file_name });
    defer allocator.free(face_path);

    var face: c.FT_Face = undefined;
    if (c.FT_New_Face(library, face_path.ptr, 0, &face) != c.FT_Err_Ok) return error.FreetypeFaceFailed;
    defer _ = c.FT_Done_Face(face);

    const units_per_em: i32 = @intCast(face.*.units_per_EM);
    const one_pixel_size: i32 = if (units_per_em == 1000) 50 else 32;
    const font_height_pixels: c_uint = @intCast(@divTrunc(units_per_em, one_pixel_size));
    if (c.FT_Set_Pixel_Sizes(face, 0, font_height_pixels) != c.FT_Err_Ok) return error.FreetypeSizeFailed;

    var char_codes = try std.ArrayList(u32).initCapacity(allocator, 0);
    defer char_codes.deinit(allocator);

    var glyph_index: c.FT_UInt = 0;
    var char_code: c.FT_ULong = c.FT_Get_First_Char(face, &glyph_index);
    while (glyph_index != 0) {
        if (char_code >= 32 and char_code <= 0x7fff) {
            try char_codes.append(allocator, @intCast(char_code));
        }
        char_code = c.FT_Get_Next_Char(face, char_code, &glyph_index);
    }
    insertionSort(u32, char_codes.items);

    const ascender_pixels: i32 = @divTrunc(@as(i32, @intCast(face.*.ascender)), one_pixel_size);
    var pen = c.FT_Vector{
        .x = 0,
        .y = @intCast((@as(i32, @intCast(font_height_pixels)) - ascender_pixels) * 64),
    };
    c.FT_Set_Transform(face, null, &pen);

    try writeAll(output_file, "TO_QSPI const font_t ");
    try writeAll(output_file, font.symbol_name);
    try writeAll(output_file, " = {\n");
    try writeAll(output_file, "  .id             = ");
    try writeUnsigned(output_file, font.id);
    try writeAll(output_file, ",\n");
    try writeAll(output_file, "  .numberOfGlyphs = ");
    try writeUnsigned(output_file, char_codes.items.len);
    try writeAll(output_file, ",\n");
    try writeAll(output_file, "  .glyphs = {\n\n");

    for (char_codes.items, 0..) |sorted_char_code, glyph_number| {
        glyph_index = c.FT_Get_Char_Index(face, sorted_char_code);
        if (glyph_index == 0) continue;

        if (glyph_number != 0) {
            try writeAll(output_file, ",\n\n");
        }

        var glyph_name: [100:0]u8 = [_:0]u8{0} ** 100;
        _ = c.FT_Get_Glyph_Name(face, glyph_index, @ptrCast(&glyph_name), glyph_name.len);
        const glyph_name_slice = std.mem.sliceTo(&glyph_name, 0);

        if (c.FT_Load_Glyph(face, glyph_index, c.FT_LOAD_RENDER) != c.FT_Err_Ok) {
            return error.FreetypeLoadFailed;
        }

        const glyph_slot = face.*.glyph;
        var cols_before_glyph: i32 = @divTrunc(@as(i32, @intCast(glyph_slot.*.metrics.horiBearingX)), 64);
        var cols_glyph: i32 = @intCast(glyph_slot.*.bitmap.width);
        const hori_advance: i32 = @divTrunc(@as(i32, @intCast(glyph_slot.*.metrics.horiAdvance)), 64);
        const cols_after_glyph: i32 = hori_advance - cols_before_glyph - cols_glyph;
        if (cols_before_glyph < 0) {
            cols_glyph += cols_before_glyph;
            cols_before_glyph = 0;
        }

        var rows_above_glyph: i32 = ascender_pixels - @divTrunc(@as(i32, @intCast(glyph_slot.*.metrics.horiBearingY)), 64);
        var rows_glyph: i32 = @intCast(glyph_slot.*.bitmap.rows);
        const descender_pixels: i32 = @divTrunc(@as(i32, @intCast(face.*.descender)), one_pixel_size);
        const hori_bearing_y: i32 = @divTrunc(@as(i32, @intCast(glyph_slot.*.metrics.horiBearingY)), 64);
        const rows_below_glyph: i32 = hori_bearing_y - descender_pixels - rows_glyph;
        if (rows_above_glyph < 0) {
            rows_glyph += rows_above_glyph;
            rows_above_glyph = 0;
        }

        const ranks = if (font.uses_ranks)
            try findGlyphRank(glyph_ranks, @intCast(sorted_char_code))
        else
            GlyphRank{ .code_point = @intCast(sorted_char_code), .rank1 = 0, .rank2 = 0 };

        if (glyph_name_slice.len == 0) {
            try writeAll(output_file, "    //\n");
        } else {
            try writeAll(output_file, "    // ");
            try writeAll(output_file, glyph_name_slice);
            try writeAll(output_file, "\n");
        }

        const encoded_char_code: u16 = if (sorted_char_code >= 0x80)
            @intCast(sorted_char_code | 0x8000)
        else
            @intCast(sorted_char_code);

        try writeAll(output_file, "    {.charCode=0x");
        try writeHex4(output_file, encoded_char_code);
        try writeAll(output_file, ", .colsBeforeGlyph=");
        try writePaddedSigned(output_file, cols_before_glyph, 2);
        try writeAll(output_file, ", .colsGlyph=");
        try writePaddedSigned(output_file, cols_glyph, 2);
        try writeAll(output_file, ", .colsAfterGlyph=");
        try writePaddedSigned(output_file, cols_after_glyph, 2);
        try writeAll(output_file, ", .rowsAboveGlyph=");
        try writePaddedSigned(output_file, rows_above_glyph, 2);
        try writeAll(output_file, ", .rowsGlyph=");
        try writePaddedSigned(output_file, rows_glyph, 2);
        try writeAll(output_file, ", .rowsBelowGlyph=");
        try writePaddedSigned(output_file, rows_below_glyph, 2);
        try writeAll(output_file, ", .rank1=");
        try writePaddedSigned(output_file, ranks.rank1, 3);
        try writeAll(output_file, ", .rank2=");
        try writePaddedSigned(output_file, ranks.rank2, 3);
        try writeAll(output_file, ",\n");
        try writeAll(output_file, "     .data=\"");
        try writeGlyphData(output_file, glyph_slot, rows_glyph, cols_glyph);
        try writeAll(output_file, "\"}");
    }

    try writeAll(output_file, "}\n};\n");
}

fn findGlyphRank(glyph_ranks: []const GlyphRank, code_point: u16) GeneratorError!GlyphRank {
    for (glyph_ranks) |glyph_rank| {
        if (glyph_rank.code_point == code_point) return glyph_rank;
    }
    return error.MissingGlyphRank;
}

fn writeGlyphData(output_file: *c.FILE, glyph_slot: c.FT_GlyphSlot, rows_glyph: i32, cols_glyph: i32) GeneratorError!void {
    if (rows_glyph <= 0 or cols_glyph <= 0) return;

    const bitmap_width: usize = @intCast(glyph_slot.*.bitmap.width);
    const buffer = @as([*]const u8, @ptrCast(glyph_slot.*.bitmap.buffer));
    const rows: usize = @intCast(rows_glyph);
    const cols: usize = @intCast(cols_glyph);

    var row: usize = 0;
    while (row < rows) : (row += 1) {
        var packed_byte: u8 = 0;
        var num_bits: u8 = 0;

        var col: usize = 0;
        while (col < cols) : (col += 1) {
            const bit: u8 = if (buffer[row * bitmap_width + col] >= 128) 1 else 0;
            packed_byte <<= 1;
            packed_byte |= bit;
            num_bits += 1;
            if (num_bits == 8) {
                try writeHexEscape(output_file, packed_byte);
                packed_byte = 0;
                num_bits = 0;
            }
        }

        while (num_bits != 0) {
            packed_byte <<= 1;
            num_bits += 1;
            if (num_bits == 8) {
                try writeHexEscape(output_file, packed_byte);
                packed_byte = 0;
                num_bits = 0;
            }
        }
    }
}

fn insertionSort(comptime T: type, items: []T) void {
    var i: usize = 1;
    while (i < items.len) : (i += 1) {
        const value = items[i];
        var j = i;
        while (j > 0 and items[j - 1] > value) {
            items[j] = items[j - 1];
            j -= 1;
        }
        items[j] = value;
    }
}

fn writeHeader(output_file: *c.FILE) GeneratorError!void {
    try writeAll(output_file, "// SPDX-License-Identifier: GPL-3.0-only\n");
    try writeAll(output_file, "// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors\n\n");
    try writeAll(output_file, "/********************************************//**\n");
    try writeAll(output_file, " * \\file rasterFontsData.c C structures of the raster fonts\n");
    try writeAll(output_file, " ***********************************************/\n\n");
    try writeAll(output_file, "/**********************************************************************************************\n");
    try writeAll(output_file, "* Do not edit this file manually! It's automagically generated by the program ttf2RasterFonts *\n");
    try writeAll(output_file, "***********************************************************************************************/\n\n");
    try writeAll(output_file, "#include \"c47.h\"\n\n");
}

fn writePaddedSigned(output_file: *c.FILE, value: i32, width: usize) GeneratorError!void {
    var buffer: [32]u8 = undefined;
    const text = std.fmt.bufPrint(&buffer, "{d}", .{value}) catch unreachable;
    if (text.len < width) {
        try writeSpaces(output_file, width - text.len);
    }
    try writeAll(output_file, text);
}

fn writeUnsigned(output_file: *c.FILE, value: anytype) GeneratorError!void {
    var buffer: [32]u8 = undefined;
    const text = std.fmt.bufPrint(&buffer, "{d}", .{value}) catch unreachable;
    try writeAll(output_file, text);
}

fn writeSpaces(output_file: *c.FILE, count: usize) GeneratorError!void {
    var remaining = count;
    while (remaining > 0) : (remaining -= 1) {
        try writeAll(output_file, " ");
    }
}

fn writeHex4(output_file: *c.FILE, value: u16) GeneratorError!void {
    var buffer: [4]u8 = undefined;
    _ = std.fmt.bufPrint(&buffer, "{x:0>4}", .{value}) catch unreachable;
    try writeAll(output_file, &buffer);
}

fn writeHexEscape(output_file: *c.FILE, value: u8) GeneratorError!void {
    var buffer: [4]u8 = .{ '\\', 'x', 0, 0 };
    const digits = "0123456789abcdef";
    buffer[2] = digits[value >> 4];
    buffer[3] = digits[value & 0x0f];
    try writeAll(output_file, &buffer);
}

fn allocPrintZ(allocator: std.mem.Allocator, comptime fmt: []const u8, args: anytype) std.mem.Allocator.Error![:0]u8 {
    const text = try std.fmt.allocPrint(allocator, fmt, args);
    defer allocator.free(text);
    return try dupeZ(allocator, text);
}

fn dupeZ(allocator: std.mem.Allocator, text: []const u8) std.mem.Allocator.Error![:0]u8 {
    const sentinel = try allocator.alloc(u8, text.len + 1);
    @memcpy(sentinel[0..text.len], text);
    sentinel[text.len] = 0;
    return sentinel[0..text.len :0];
}

fn trimLineEnding(line: []const u8) []const u8 {
    var end = line.len;
    while (end > 0 and (line[end - 1] == '\r' or line[end - 1] == '\n')) {
        end -= 1;
    }
    return line[0..end];
}

fn writeAll(output_file: *c.FILE, contents: []const u8) GeneratorError!void {
    if (contents.len == 0) return;
    if (c.fwrite(contents.ptr, 1, contents.len, output_file) != contents.len) return error.FileWriteFailed;
}