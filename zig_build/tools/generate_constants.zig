const std = @import("std");

const c = @cImport({
    @cInclude("stdbool.h");
    @cInclude("stdint.h");
    @cInclude("stddef.h");
    @cInclude("stdio.h");
    @cInclude("stdlib.h");
    @cInclude("string.h");
    @cInclude("defines.h");
    @cInclude("decContext.h");
    @cInclude("decNumber.h");
    @cInclude("decQuad.h");
});

const realContext_t = c.decContext;
const real_t = c.decNumber;
const real34_t = c.decQuad;

const ParseError = error{
    UnsupportedPreprocessorDirective,
    MissingGenerateAllConstants,
    MissingFunctionBody,
    MissingMain,
    UnexpectedToken,
    UnterminatedBlockComment,
    UnterminatedString,
    InvalidInteger,
};

const RealConstant = struct {
    name: []const u8,
    digits: usize,
    exact: bool,
    value: []const u8,
};

const Real34Constant = struct {
    name: []const u8,
    value: []const u8,
};

const ParsedConstant = union(enum) {
    real: RealConstant,
    real34: Real34Constant,
};

const Scanner = struct {
    source: []const u8,
    index: usize = 0,

    fn skipWhitespaceAndComments(self: *Scanner) !void {
        while (self.index < self.source.len) {
            switch (self.source[self.index]) {
                ' ', '\t', '\r', '\n' => self.index += 1,
                '/' => {
                    if (self.index + 1 >= self.source.len) return;
                    const next = self.source[self.index + 1];
                    if (next == '/') {
                        self.index += 2;
                        while (self.index < self.source.len and self.source[self.index] != '\n') {
                            self.index += 1;
                        }
                    } else if (next == '*') {
                        const rel_end = std.mem.indexOf(u8, self.source[self.index + 2 ..], "*/") orelse return error.UnterminatedBlockComment;
                        self.index += rel_end + 4;
                    } else {
                        return;
                    }
                },
                else => return,
            }
        }
    }

    fn consumeChar(self: *Scanner, expected: u8) !void {
        try self.skipWhitespaceAndComments();
        if (self.index >= self.source.len or self.source[self.index] != expected) {
            return error.UnexpectedToken;
        }
        self.index += 1;
    }

    fn parseIdentifier(self: *Scanner) ![]const u8 {
        try self.skipWhitespaceAndComments();
        if (self.index >= self.source.len) return error.UnexpectedToken;

        const start = self.index;
        const first = self.source[self.index];
        if (!std.ascii.isAlphabetic(first) and first != '_') {
            return error.UnexpectedToken;
        }

        self.index += 1;
        while (self.index < self.source.len) {
            const ch = self.source[self.index];
            if (!std.ascii.isAlphanumeric(ch) and ch != '_') break;
            self.index += 1;
        }

        return self.source[start..self.index];
    }

    fn parseInteger(self: *Scanner) !usize {
        try self.skipWhitespaceAndComments();
        if (self.index >= self.source.len or !std.ascii.isDigit(self.source[self.index])) {
            return error.InvalidInteger;
        }

        const start = self.index;
        while (self.index < self.source.len and std.ascii.isDigit(self.source[self.index])) {
            self.index += 1;
        }

        return std.fmt.parseInt(usize, self.source[start..self.index], 10) catch error.InvalidInteger;
    }

    fn parseStringLiteral(self: *Scanner, allocator: std.mem.Allocator) ![]const u8 {
        try self.skipWhitespaceAndComments();
        if (self.index >= self.source.len or self.source[self.index] != '"') {
            return error.UnexpectedToken;
        }

        self.index += 1;
        var out = try std.ArrayList(u8).initCapacity(allocator, 0);
        errdefer out.deinit(allocator);

        while (self.index < self.source.len) {
            const ch = self.source[self.index];
            switch (ch) {
                '"' => {
                    self.index += 1;
                    return try out.toOwnedSlice(allocator);
                },
                '\\' => {
                    self.index += 1;
                    if (self.index >= self.source.len) return error.UnterminatedString;
                    const escaped = self.source[self.index];
                    const value: u8 = switch (escaped) {
                        '\\' => '\\',
                        '"' => '"',
                        'n' => '\n',
                        'r' => '\r',
                        't' => '\t',
                        else => escaped,
                    };
                    try out.append(allocator, value);
                    self.index += 1;
                },
                else => {
                    try out.append(allocator, ch);
                    self.index += 1;
                },
            }
        }

        return error.UnterminatedString;
    }

    fn parseConcatenatedStringLiterals(self: *Scanner, allocator: std.mem.Allocator) ![]const u8 {
        var out = try std.ArrayList(u8).initCapacity(allocator, 0);
        errdefer out.deinit(allocator);
        var found_any = false;

        while (true) {
            try self.skipWhitespaceAndComments();
            if (self.index >= self.source.len or self.source[self.index] != '"') break;

            const part = try self.parseStringLiteral(allocator);
            defer allocator.free(part);
            try out.appendSlice(allocator, part);
            found_any = true;
        }

        if (!found_any) return error.UnexpectedToken;
        return try out.toOwnedSlice(allocator);
    }
};

const many_spaces = "                                                                ";
const dec_digits_per_unit: usize = @intCast(c.DECDPUN);
const max_real_digits = 12321;
const max_real_digits_rounded = ((max_real_digits + 2) / 6) * 6 + 3;
const max_real_bytes = 10 + @sizeOf(c.decNumberUnit) * (max_real_digits_rounded / dec_digits_per_unit);
const max_real_words = (max_real_bytes + 3) / 4;

const Generator = struct {
    allocator: std.mem.Allocator,
    external_declarations: std.ArrayList(u8),
    real_array: std.ArrayList(u8),
    real_t_array: std.ArrayList(u8),
    offset: usize = 0,
    real_count: usize = 0,

    fn init(allocator: std.mem.Allocator) !Generator {
        var external_declarations = try std.ArrayList(u8).initCapacity(allocator, 0);
        errdefer external_declarations.deinit(allocator);
        try external_declarations.appendSlice(allocator, "  extern const uint8_t constants[];\n");

        var real_array = try std.ArrayList(u8).initCapacity(allocator, 0);
        errdefer real_array.deinit(allocator);
        try real_array.appendSlice(allocator, "TO_QSPI const uint8_t constants[] = {\n");

        var real_t_array = try std.ArrayList(u8).initCapacity(allocator, 0);
        errdefer real_t_array.deinit(allocator);
        try real_t_array.appendSlice(allocator, "\nTO_QSPI const real_t *realtConstants[NOUC] = {\n");

        return .{
            .allocator = allocator,
            .external_declarations = external_declarations,
            .real_array = real_array,
            .real_t_array = real_t_array,
        };
    }

    fn deinit(self: *Generator) void {
        self.external_declarations.deinit(self.allocator);
        self.real_array.deinit(self.allocator);
        self.real_t_array.deinit(self.allocator);
    }

    fn appendFormat(self: *Generator, buffer: *std.ArrayList(u8), comptime fmt: []const u8, args: anytype) !void {
        const text = try std.fmt.allocPrint(self.allocator, fmt, args);
        defer self.allocator.free(text);
        try buffer.appendSlice(self.allocator, text);
    }

    fn emitConstant(self: *Generator, name: []const u8, prefix: []const u8, type_name: []const u8, header_padding: usize, bytes: []const u8) !void {
        const array_padding = 21 - name.len - prefix.len;

        try self.appendFormat(
            &self.external_declarations,
            "  #define {s}{s}{s} (({s} *)(constants + {d}))\n",
            .{ prefix, name, many_spaces[0..header_padding], type_name, self.offset },
        );

        try self.appendFormat(
            &self.real_array,
            "  /* {s}{s}{s} */  ",
            .{ prefix, name, many_spaces[0..array_padding] },
        );

        for (bytes, 0..) |byte, index| {
            const gap = switch (index) {
                3, 7, 8, 9 => " ",
                else => "",
            };
            try self.appendFormat(&self.real_array, "0x{x:0>2},{s}", .{ byte, gap });
        }
        try self.real_array.appendSlice(self.allocator, "\n");
        self.offset += bytes.len;
    }

    fn emitRealConstant(self: *Generator, spec: RealConstant, ctxt_real: *realContext_t) !void {
        const max_digits = ((spec.digits + 2) / 6) * 6 + 3;
        const len_in_bytes = 10 + @sizeOf(c.decNumberUnit) * (max_digits / dec_digits_per_unit);
        var storage: [max_real_words]u32 = [_]u32{0} ** max_real_words;
        const real_ptr: *real_t = @ptrCast(&storage[0]);

        ctxt_real.digits = @intCast(max_digits);
        const c_value = try self.allocator.dupeZ(u8, spec.value);
        defer self.allocator.free(c_value);

        _ = c.decNumberFromString(real_ptr, c_value.ptr, ctxt_real);
        _ = c.decNumberReduce(real_ptr, real_ptr, ctxt_real);

        var dynamic_prefix: ?[]u8 = null;
        const prefix: []const u8 = if (spec.exact)
            "const_"
        else blk: {
            const text = try std.fmt.allocPrint(self.allocator, "const{d}_", .{max_digits});
            dynamic_prefix = text;
            break :blk text;
        };
        defer if (dynamic_prefix) |text| self.allocator.free(text);

        try self.emitConstant(
            spec.name,
            prefix,
            "real_t",
            25 - spec.name.len - prefix.len,
            std.mem.asBytes(&storage)[0..len_in_bytes],
        );

        self.real_count += 1;
        if (self.real_count <= @as(usize, @intCast(c.NOUC))) {
            try self.appendFormat(&self.real_t_array, "  {s}{s},\n", .{ prefix, spec.name });
        }
    }

    fn emitReal34Constant(self: *Generator, spec: Real34Constant, ctxt_real34: *realContext_t) !void {
        var real34: real34_t = std.mem.zeroes(real34_t);
        const c_value = try self.allocator.dupeZ(u8, spec.value);
        defer self.allocator.free(c_value);

        _ = c.decQuadFromString(&real34, c_value.ptr, ctxt_real34);
        _ = c.decQuadReduce(&real34, &real34, ctxt_real34);

        try self.emitConstant(
            spec.name,
            "const34_",
            "real34_t",
            15 - spec.name.len,
            std.mem.asBytes(&real34),
        );
    }

    fn finish(self: *Generator) !void {
        try self.real_array.appendSlice(self.allocator, "};\n");
    }
};

pub fn main(init: std.process.Init) !void {
    const allocator = std.heap.page_allocator;

    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();

    _ = args.next();
    const parsed_args = parseUpstreamRoot(&args);
    const output_c = parsed_args.first_positional orelse {
        std.debug.print("Usage: generateConstants [--upstream-root <path>] <c file> <h file> <c file2>\n", .{});
        std.process.exit(1);
    };
    const output_h = args.next() orelse {
        std.debug.print("Usage: generateConstants [--upstream-root <path>] <c file> <h file> <c file2>\n", .{});
        std.process.exit(1);
    };
    const output_c2 = args.next() orelse {
        std.debug.print("Usage: generateConstants [--upstream-root <path>] <c file> <h file> <c file2>\n", .{});
        std.process.exit(1);
    };

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    const parsed_constants = try parseConstants(arena.allocator(), parsed_args.upstream_root);

    var ctxt_real34: realContext_t = undefined;
    var ctxt_real: realContext_t = undefined;
    _ = c.decContextDefault(&ctxt_real34, c.DEC_INIT_DECQUAD);
    _ = c.decContextDefault(&ctxt_real, c.DEC_INIT_DECQUAD);
    ctxt_real.traps = 0;

    var generator = try Generator.init(allocator);
    defer generator.deinit();

    for (parsed_constants) |constant| {
        switch (constant) {
            .real => |spec| try generator.emitRealConstant(spec, &ctxt_real),
            .real34 => |spec| try generator.emitReal34Constant(spec, &ctxt_real34),
        }
    }
    try generator.finish();

    const header_text = try std.fmt.allocPrint(allocator,
        \\// SPDX-License-Identifier: GPL-3.0-only
        \\// SPDX-FileCopyrightText: Copyright The C47 Authors
        \\
        \\/*************************************************************************************************
        \\ * Do not edit this file manually! It's automagically generated by the program generateConstants *
        \\ *************************************************************************************************/
        \\
        \\/**
        \\ * \\file constantPointers.h
        \\ */
        \\#if !defined(CONSTANTPOINTERS_H)
        \\  #define CONSTANTPOINTERS_H
        \\
        \\{s}
        \\  #define NUMBER_OF_REAL_T_CONSTANTS {d}
        \\#endif // !CONSTANTPOINTERS_H
    , .{ generator.external_declarations.items, generator.real_count });
    defer allocator.free(header_text);

    const constants_text = try std.fmt.allocPrint(allocator,
        \\// SPDX-License-Identifier: GPL-3.0-only
        \\// SPDX-FileCopyrightText: Copyright The C47 Authors
        \\
        \\/*************************************************************************************************
        \\ * Do not edit this file manually! It's automagically generated by the program generateConstants *
        \\ *************************************************************************************************/
        \\
        \\#include "c47.h"
        \\
        \\{s}
    , .{generator.real_array.items});
    defer allocator.free(constants_text);

    const real_t_array_text = try std.fmt.allocPrint(allocator,
        \\// SPDX-License-Identifier: GPL-3.0-only
        \\// SPDX-FileCopyrightText: Copyright The C47 Authors
        \\
        \\/*************************************************************************************************
        \\ * Do not edit this file manually! It's automagically generated by the program generateConstants *
        \\ *************************************************************************************************/
        \\
        \\#include "c47.h"
        \\
        \\{s}}};
    , .{generator.real_t_array.items});
    defer allocator.free(real_t_array_text);

    try writeFile(output_c, constants_text);
    try writeFile(output_h, header_text);
    try writeFile(output_c2, real_t_array_text);
}

const ParsedArgs = struct {
    upstream_root: []const u8,
    first_positional: ?[]const u8,
};

fn parseUpstreamRoot(args: *std.process.Args.Iterator) ParsedArgs {
    const next_arg = args.next() orelse return .{ .upstream_root = ".", .first_positional = null };
    if (!std.mem.eql(u8, next_arg, "--upstream-root")) {
        return .{ .upstream_root = ".", .first_positional = next_arg };
    }

    const upstream_root = args.next() orelse {
        std.debug.print("missing value for --upstream-root\n", .{});
        std.process.exit(1);
    };

    return .{ .upstream_root = upstream_root, .first_positional = args.next() };
}

fn upstreamPath(allocator: std.mem.Allocator, upstream_root: []const u8, relative: []const u8) ![]const u8 {
    if (std.mem.eql(u8, upstream_root, ".")) return allocator.dupe(u8, relative);
    return std.fs.path.join(allocator, &.{ upstream_root, relative });
}

fn parseConstants(allocator: std.mem.Allocator, upstream_root: []const u8) ![]ParsedConstant {
    const source_path = try upstreamPath(allocator, upstream_root, "src/generateConstants/generateConstants.c");
    defer allocator.free(source_path);

    const source = try readFileAlloc(allocator, source_path);

    const start = std.mem.indexOf(u8, source, "void generateAllConstants(void)") orelse return error.MissingGenerateAllConstants;
    const body_open_rel = std.mem.indexOfScalar(u8, source[start..], '{') orelse return error.MissingFunctionBody;
    const body_start = start + body_open_rel + 1;
    const main_rel = std.mem.indexOf(u8, source[body_start..], "int main(") orelse return error.MissingMain;
    const preprocessed_body = try preprocessConstantsBody(allocator, source[body_start .. body_start + main_rel]);

    var scanner = Scanner{ .source = preprocessed_body };
    var constants = try std.ArrayList(ParsedConstant).initCapacity(allocator, 0);
    errdefer constants.deinit(allocator);

    while (scanner.index < scanner.source.len) {
        scanner.skipWhitespaceAndComments() catch |err| return err;
        if (scanner.index >= scanner.source.len) break;

        const ch = scanner.source[scanner.index];
        if (!std.ascii.isAlphabetic(ch) and ch != '_') {
            scanner.index += 1;
            continue;
        }

        const ident = try scanner.parseIdentifier();
        if (std.mem.eql(u8, ident, "generateConstant")) {
            try scanner.consumeChar('(');
            const name = try scanner.parseConcatenatedStringLiterals(allocator);
            try scanner.consumeChar(',');
            const digits = try scanner.parseInteger();
            try scanner.consumeChar(',');
            const exact_ident = try scanner.parseIdentifier();
            const exact = if (std.mem.eql(u8, exact_ident, "EXACT"))
                true
            else if (std.mem.eql(u8, exact_ident, "APPROX"))
                false
            else
                return error.UnexpectedToken;
            try scanner.consumeChar(',');
            const value = try scanner.parseConcatenatedStringLiterals(allocator);
            try scanner.consumeChar(')');
            try scanner.consumeChar(';');
            try constants.append(allocator, .{ .real = .{
                .name = name,
                .digits = digits,
                .exact = exact,
                .value = value,
            } });
            continue;
        }

        if (std.mem.eql(u8, ident, "generateConstant34")) {
            try scanner.consumeChar('(');
            const name = try scanner.parseConcatenatedStringLiterals(allocator);
            try scanner.consumeChar(',');
            const value = try scanner.parseConcatenatedStringLiterals(allocator);
            try scanner.consumeChar(')');
            try scanner.consumeChar(';');
            try constants.append(allocator, .{ .real34 = .{
                .name = name,
                .value = value,
            } });
        }
    }

    return try constants.toOwnedSlice(allocator);
}

const ConditionalFrame = struct {
    parent_active: bool,
    branch_active: bool,
};

fn preprocessConstantsBody(allocator: std.mem.Allocator, body: []const u8) ![]u8 {
    var out = try std.ArrayList(u8).initCapacity(allocator, body.len);
    errdefer out.deinit(allocator);

    var frames = try std.ArrayList(ConditionalFrame).initCapacity(allocator, 0);
    defer frames.deinit(allocator);

    var line_iter = std.mem.splitScalar(u8, body, '\n');
    var active = true;
    while (line_iter.next()) |line_with_possible_cr| {
        const line = trimLineEnding(line_with_possible_cr);
        const trimmed = trimAsciiLeft(line);

        if (std.mem.startsWith(u8, trimmed, "#if")) {
            const condition = try evaluatePreprocessorCondition(trimmed[3..]);
            try frames.append(allocator, .{
                .parent_active = active,
                .branch_active = condition,
            });
            active = active and condition;
            continue;
        }
        if (std.mem.startsWith(u8, trimmed, "#else")) {
            if (frames.items.len == 0) return error.UnsupportedPreprocessorDirective;
            const frame = &frames.items[frames.items.len - 1];
            frame.branch_active = !frame.branch_active;
            active = frame.parent_active and frame.branch_active;
            continue;
        }
        if (std.mem.startsWith(u8, trimmed, "#endif")) {
            if (frames.items.len == 0) return error.UnsupportedPreprocessorDirective;
            const frame = frames.pop() orelse unreachable;
            active = frame.parent_active;
            continue;
        }

        if (!active) continue;
        try out.appendSlice(allocator, line);
        try out.append(allocator, '\n');
    }

    if (frames.items.len != 0) return error.UnsupportedPreprocessorDirective;
    return try out.toOwnedSlice(allocator);
}

fn evaluatePreprocessorCondition(condition: []const u8) !bool {
    const trimmed = trimAscii(condition);
    if (trimmed.len == 0) return error.UnsupportedPreprocessorDirective;

    if (std.mem.startsWith(u8, trimmed, "defined(")) {
        const close = std.mem.indexOfScalar(u8, trimmed, ')') orelse return error.UnsupportedPreprocessorDirective;
        const name = trimAscii(trimmed[8..close]);
        return lookupPreprocessorDefined(name);
    }

    var expression = trimmed;
    if (expression[0] == '(' and expression[expression.len - 1] == ')') {
        expression = trimAscii(expression[1 .. expression.len - 1]);
    }

    if (std.mem.indexOf(u8, expression, "==")) |eq| {
        const name = trimAscii(expression[0..eq]);
        const rhs = trimAscii(expression[eq + 2 ..]);
        return try lookupPreprocessorInteger(name) == try std.fmt.parseInt(i64, rhs, 10);
    }

    if (std.mem.indexOf(u8, expression, "!=")) |neq| {
        const name = trimAscii(expression[0..neq]);
        const rhs = trimAscii(expression[neq + 2 ..]);
        return try lookupPreprocessorInteger(name) != try std.fmt.parseInt(i64, rhs, 10);
    }

    return error.UnsupportedPreprocessorDirective;
}

fn lookupPreprocessorDefined(name: []const u8) bool {
    if (std.mem.eql(u8, name, "DEBUG")) return false;
    if (std.mem.eql(u8, name, "PC_BUILD")) return true;
    return false;
}

fn lookupPreprocessorInteger(name: []const u8) !i64 {
    if (std.mem.eql(u8, name, "DECDPUN")) return c.DECDPUN;
    if (std.mem.eql(u8, name, "MMHG_PA_133_3224")) return c.MMHG_PA_133_3224;
    return error.UnsupportedPreprocessorDirective;
}

fn trimLineEnding(line: []const u8) []const u8 {
    var end = line.len;
    while (end > 0 and (line[end - 1] == '\r' or line[end - 1] == '\n')) {
        end -= 1;
    }
    return line[0..end];
}

fn trimAsciiLeft(text: []const u8) []const u8 {
    var start: usize = 0;
    while (start < text.len and (text[start] == ' ' or text[start] == '\t')) {
        start += 1;
    }
    return text[start..];
}

fn trimAscii(text: []const u8) []const u8 {
    var start: usize = 0;
    var end: usize = text.len;
    while (start < end and (text[start] == ' ' or text[start] == '\t')) {
        start += 1;
    }
    while (end > start and (text[end - 1] == ' ' or text[end - 1] == '\t')) {
        end -= 1;
    }
    return text[start..end];
}

fn writeFile(path: []const u8, contents: []const u8) !void {
    const c_path = try std.heap.page_allocator.dupeZ(u8, path);
    defer std.heap.page_allocator.free(c_path);

    const file = c.fopen(c_path.ptr, "wb") orelse return error.FileOpenFailed;
    defer _ = c.fclose(file);

    const written = c.fwrite(contents.ptr, 1, contents.len, file);
    if (written != contents.len) return error.FileWriteFailed;
}

fn readFileAlloc(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    const c_path = try allocator.dupeZ(u8, path);
    defer allocator.free(c_path);

    const file = c.fopen(c_path.ptr, "rb") orelse return error.FileOpenFailed;
    defer _ = c.fclose(file);

    if (c.fseek(file, 0, c.SEEK_END) != 0) return error.FileReadFailed;
    const size_long = c.ftell(file);
    if (size_long < 0) return error.FileReadFailed;
    if (c.fseek(file, 0, c.SEEK_SET) != 0) return error.FileReadFailed;

    const size: usize = @intCast(size_long);
    const buffer = try allocator.alloc(u8, size);
    errdefer allocator.free(buffer);

    const read_count = c.fread(buffer.ptr, 1, size, file);
    if (read_count != size) return error.FileReadFailed;

    return buffer;
}

pub export fn xcopy(dest: ?*anyopaque, source: ?*const anyopaque, n: u32) ?*anyopaque {
    if (dest == null or source == null or n == 0) return dest;

    const dest_bytes: [*]u8 = @ptrCast(dest.?);
    const source_bytes: [*]const u8 = @ptrCast(source.?);

    if (@intFromPtr(source_bytes) > @intFromPtr(dest_bytes)) {
        var index: usize = 0;
        while (index < n) : (index += 1) {
            dest_bytes[index] = source_bytes[index];
        }
    } else if (@intFromPtr(source_bytes) < @intFromPtr(dest_bytes)) {
        var index: usize = n;
        while (index > 0) {
            index -= 1;
            dest_bytes[index] = source_bytes[index];
        }
    }

    return dest;
}
