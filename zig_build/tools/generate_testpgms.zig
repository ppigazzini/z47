const builtin = @import("builtin");
const std = @import("std");

const c = @import("c_bindings");

const real34_t = c.decQuad;
const last_item = 2732;

const FunctionPtr = ?*const fn (u16) callconv(.c) void;

const Item = extern struct {
    func: FunctionPtr,
    param: u16,
    itemCatalogName: [16]u8,
    itemSoftmenuName: [16]u8,
    tamMinMax: u16,
    status: u16,
};

const KeyPrefix = union(enum) {
    direct: u8,
    reg: u8,
    variable: []const u8,
};

const KeyTarget = union(enum) {
    byte: u8,
    label: []const u8,
    reg: u8,
    variable: []const u8,
};

const preprocess_dir = ".zig-cache/tmp/generate_testpgms";
const preprocess_header_path = preprocess_dir ++ "/c47.h";
const preprocess_source_path = "src/generateTestPgms/generateTestPgms.c";

const fake_c47_header =
    "#include <stdbool.h>\n" ++
    "#include <stdint.h>\n" ++
    "#include <stdio.h>\n" ++
    "#include <stdlib.h>\n" ++
    "#include <string.h>\n" ++
    "#include \"defines.h\"\n" ++
    "#include \"decContext.h\"\n" ++
    "#include \"decNumber.h\"\n" ++
    "#include \"decQuad.h\"\n" ++
    "#include \"decimal128.h\"\n" ++
    "#include \"mathematics/pcg_basic.h\"\n" ++
    "#include \"realType.h\"\n" ++
    "#include \"typeDefinitions.h\"\n" ++
    "#include \"longIntegerType.h\"\n" ++
    "#include \"fonts.h\"\n" ++
    "#include \"items.h\"\n";

const ParseError = error{
    FileOpenFailed,
    FileWriteFailed,
    PreprocessFailed,
    MissingStartMarker,
    MissingEndMarker,
    UnexpectedToken,
    UnterminatedString,
    InvalidInteger,
    InvalidByte,
    MemoryOverflow,
    UnsupportedStatement,
};

extern const indexOfItems: [last_item]Item;
extern fn isFunctionOldParam16(func: u16) bool;

const cimke_label = "C\x80\xedmke";
const var_alpha_name = "Var\x83\xb1";
const french_message = "Une cha\x80\xeene en fran\x80\xe7ais";

const Scanner = struct {
    source: []const u8,
    index: usize = 0,

    fn skipWhitespace(self: *Scanner) void {
        while (self.index < self.source.len) {
            switch (self.source[self.index]) {
                ' ', '\t', '\r', '\n' => self.index += 1,
                else => return,
            }
        }
    }

    fn consumeChar(self: *Scanner, expected: u8) !void {
        self.skipWhitespace();
        if (self.index >= self.source.len or self.source[self.index] != expected) {
            return error.UnexpectedToken;
        }
        self.index += 1;
    }

    fn consumeString(self: *Scanner, expected: []const u8) !void {
        self.skipWhitespace();
        if (!std.mem.startsWith(u8, self.source[self.index..], expected)) {
            return error.UnexpectedToken;
        }
        self.index += expected.len;
    }

    fn parseIdentifier(self: *Scanner) ![]const u8 {
        self.skipWhitespace();
        if (self.index >= self.source.len) return error.UnexpectedToken;

        const start = self.index;
        const first = self.source[self.index];
        if (!std.ascii.isAlphabetic(first) and first != '_') return error.UnexpectedToken;

        self.index += 1;
        while (self.index < self.source.len) {
            const ch = self.source[self.index];
            if (!std.ascii.isAlphanumeric(ch) and ch != '_') break;
            self.index += 1;
        }

        return self.source[start..self.index];
    }

    fn parseStringLiteral(self: *Scanner, allocator: std.mem.Allocator) ![]const u8 {
        self.skipWhitespace();
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
                    if (escaped == 'x' or escaped == 'X') {
                        self.index += 1;
                        const hex_start = self.index;
                        while (self.index < self.source.len and std.ascii.isHex(self.source[self.index])) {
                            self.index += 1;
                        }
                        if (self.index == hex_start) return error.UnterminatedString;
                        const value = try std.fmt.parseUnsigned(u8, self.source[hex_start..self.index], 16);
                        try out.append(allocator, value);
                        continue;
                    }

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
            self.skipWhitespace();
            if (self.index >= self.source.len or self.source[self.index] != '"') break;
            const part = try self.parseStringLiteral(allocator);
            try out.appendSlice(allocator, part);
            found_any = true;
        }

        if (!found_any) return error.UnexpectedToken;
        return try out.toOwnedSlice(allocator);
    }

    fn parseSignedInteger(self: *Scanner) !i64 {
        self.skipWhitespace();
        const start = self.index;
        if (self.index < self.source.len and (self.source[self.index] == '+' or self.source[self.index] == '-')) {
            self.index += 1;
        }
        const unsigned = try self.parseUnsignedDigits();
        if (start == self.index) return error.InvalidInteger;

        if (self.source[start] == '-') {
            const magnitude = try parseUnsignedToken(unsigned);
            if (magnitude > @as(u64, @intCast(std.math.maxInt(i64))) + 1) return error.InvalidInteger;
            if (magnitude == @as(u64, @intCast(std.math.maxInt(i64))) + 1) return std.math.minInt(i64);
            return -@as(i64, @intCast(magnitude));
        }

        return @as(i64, @intCast(try parseUnsignedToken(if (self.source[start] == '+') self.source[start + 1 .. self.index] else self.source[start..self.index])));
    }

    fn parseUnsignedInteger(self: *Scanner) !u64 {
        self.skipWhitespace();
        if (self.index < self.source.len and self.source[self.index] == '+') {
            self.index += 1;
        }
        const start = self.index;
        _ = try self.parseUnsignedDigits();
        return parseUnsignedToken(self.source[start..self.index]);
    }

    fn parseUnsignedDigits(self: *Scanner) ![]const u8 {
        const start = self.index;
        if (self.index >= self.source.len) return error.InvalidInteger;

        if (self.source[self.index] == '0' and self.index + 1 < self.source.len and (self.source[self.index + 1] == 'x' or self.source[self.index + 1] == 'X')) {
            self.index += 2;
            const hex_start = self.index;
            while (self.index < self.source.len and std.ascii.isHex(self.source[self.index])) {
                self.index += 1;
            }
            if (self.index == hex_start) return error.InvalidInteger;
            return self.source[start..self.index];
        }

        while (self.index < self.source.len and std.ascii.isDigit(self.source[self.index])) {
            self.index += 1;
        }
        if (self.index == start) return error.InvalidInteger;
        return self.source[start..self.index];
    }

    fn parseExpression(self: *Scanner) ParseError!i64 {
        return self.parseAdditive();
    }

    fn parseAdditive(self: *Scanner) ParseError!i64 {
        var value = try self.parseBitwiseAnd();
        while (true) {
            self.skipWhitespace();
            if (self.index >= self.source.len) break;
            const op = self.source[self.index];
            if (op != '+' and op != '-') break;
            self.index += 1;
            const rhs = try self.parseBitwiseAnd();
            value = if (op == '+') value + rhs else value - rhs;
        }
        return value;
    }

    fn parseBitwiseAnd(self: *Scanner) ParseError!i64 {
        var value = try self.parseShift();
        while (true) {
            self.skipWhitespace();
            if (self.index >= self.source.len or self.source[self.index] != '&') break;
            self.index += 1;
            const rhs = try self.parseShift();
            value &= rhs;
        }
        return value;
    }

    fn parseShift(self: *Scanner) ParseError!i64 {
        var value = try self.parsePrimaryExpression();
        while (true) {
            self.skipWhitespace();
            if (!std.mem.startsWith(u8, self.source[self.index..], ">>")) break;
            self.index += 2;
            const rhs = try self.parsePrimaryExpression();
            if (rhs < 0 or rhs > 63) return error.InvalidInteger;
            const shift_amount: u6 = @intCast(rhs);
            value >>= shift_amount;
        }
        return value;
    }

    fn parsePrimaryExpression(self: *Scanner) ParseError!i64 {
        self.skipWhitespace();
        if (self.index >= self.source.len) return error.InvalidInteger;

        return switch (self.source[self.index]) {
            '(' => blk: {
                self.index += 1;
                const value = try self.parseExpression();
                try self.consumeChar(')');
                break :blk value;
            },
            '\'' => self.parseCharLiteral(),
            '+', '-' => self.parseSignedInteger(),
            else => |ch| blk: {
                if (std.ascii.isDigit(ch)) break :blk try self.parseSignedInteger();
                if (std.ascii.isAlphabetic(ch) or ch == '_') {
                    const name = try self.parseIdentifier();
                    break :blk try lookupExpressionConstant(name);
                }
                return error.InvalidInteger;
            },
        };
    }

    fn parseCharLiteral(self: *Scanner) ParseError!i64 {
        if (self.index >= self.source.len or self.source[self.index] != '\'') return error.InvalidInteger;
        self.index += 1;
        if (self.index >= self.source.len) return error.InvalidInteger;

        const value: u8 = switch (self.source[self.index]) {
            '\\' => blk: {
                self.index += 1;
                if (self.index >= self.source.len) return error.InvalidInteger;
                const escaped = self.source[self.index];
                break :blk switch (escaped) {
                    '\\' => '\\',
                    '\'' => '\'',
                    'n' => '\n',
                    'r' => '\r',
                    't' => '\t',
                    else => escaped,
                };
            },
            else => self.source[self.index],
        };
        self.index += 1;
        if (self.index >= self.source.len or self.source[self.index] != '\'') return error.InvalidInteger;
        self.index += 1;
        return value;
    }

    fn skipStringLiteral(self: *Scanner) ParseError!void {
        self.skipWhitespace();
        if (self.index >= self.source.len or self.source[self.index] != '"') return error.UnterminatedString;
        self.index += 1;
        while (self.index < self.source.len) {
            switch (self.source[self.index]) {
                '"' => {
                    self.index += 1;
                    return;
                },
                '\\' => {
                    self.index += 2;
                },
                else => self.index += 1,
            }
        }

        return error.UnterminatedString;
    }
};

const Generator = struct {
    memory: [65536]u8 = std.mem.zeroes([65536]u8),
    current_step: usize = 0,
    ctxt_real34: c.decContext,

    fn init() Generator {
        var ctxt_real34: c.decContext = undefined;
        _ = c.decContextDefault(&ctxt_real34, c.DEC_INIT_DECQUAD);
        ctxt_real34.traps = 0;
        return .{ .ctxt_real34 = ctxt_real34 };
    }

    fn appendByte(self: *Generator, value: u8) !void {
        if (self.current_step >= self.memory.len) return error.MemoryOverflow;
        self.memory[self.current_step] = value;
        self.current_step += 1;
    }

    fn appendSlice(self: *Generator, data: []const u8) !void {
        for (data) |byte| {
            try self.appendByte(byte);
        }
    }

    fn insertItem(self: *Generator, item: i32) !void {
        if (item < 0 or item > std.math.maxInt(i16)) return error.InvalidInteger;
        if (item < 128) {
            try self.appendByte(@intCast(item));
        } else {
            try self.appendByte(@intCast((item >> 8) | 0x80));
            try self.appendByte(@intCast(item & 0xff));
        }
    }

    fn insertString(self: *Generator, s: []const u8) !void {
        if (s.len > std.math.maxInt(u8)) return error.InvalidInteger;
        try self.appendByte(@intCast(s.len));
        try self.appendSlice(s);
    }

    fn insertLabelVariableString(self: *Generator, s: []const u8) !void {
        try self.appendByte(@intCast(c.STRING_LABEL_VARIABLE));
        try self.insertString(s);
    }

    fn insertReal34StringLiteral(self: *Generator, s: []const u8) !void {
        try self.insertItem(c.ITM_LITERAL);
        try self.appendByte(@intCast(c.STRING_REAL34));
        try self.insertString(s);
    }

    fn insertTimeStringLiteral(self: *Generator, s: []const u8) !void {
        try self.insertItem(c.ITM_LITERAL);
        try self.appendByte(@intCast(c.STRING_TIME));
        try self.insertString(s);
    }

    fn insertDateStringLiteral(self: *Generator, s: []const u8) !void {
        try self.insertItem(c.ITM_LITERAL);
        try self.appendByte(@intCast(c.STRING_DATE));
        try self.insertString(s);
    }

    fn insertAngleDegreeStringLiteral(self: *Generator, s: []const u8) !void {
        try self.insertItem(c.ITM_LITERAL);
        try self.appendByte(@intCast(c.STRING_ANGLE_DEGREE));
        try self.insertString(s);
    }

    fn insertAngleDmsStringLiteral(self: *Generator, s: []const u8) !void {
        try self.insertItem(c.ITM_LITERAL);
        try self.appendByte(@intCast(c.STRING_ANGLE_DMS));
        try self.insertString(s);
    }

    fn insertAngleGradStringLiteral(self: *Generator, s: []const u8) !void {
        try self.insertItem(c.ITM_LITERAL);
        try self.appendByte(@intCast(c.STRING_ANGLE_GRAD));
        try self.insertString(s);
    }

    fn insertAngleMultpiStringLiteral(self: *Generator, s: []const u8) !void {
        try self.insertItem(c.ITM_LITERAL);
        try self.appendByte(@intCast(c.STRING_ANGLE_MULTPI));
        try self.insertString(s);
    }

    fn insertAngleRadianStringLiteral(self: *Generator, s: []const u8) !void {
        try self.insertItem(c.ITM_LITERAL);
        try self.appendByte(@intCast(c.STRING_ANGLE_RADIAN));
        try self.insertString(s);
    }

    fn insertReal34BinaryLiteral(self: *Generator, s: []const u8) !void {
        var value: real34_t = undefined;
        const c_string = try std.heap.page_allocator.dupeSentinel(u8, s, 0);
        defer std.heap.page_allocator.free(c_string);

        try self.insertItem(c.ITM_LITERAL);
        try self.appendByte(@intCast(c.BINARY_REAL34));
        _ = c.decQuadFromString(&value, c_string.ptr, &self.ctxt_real34);
        try self.appendSlice(std.mem.asBytes(&value));
    }

    fn insertLongIntegerStringLiteral(self: *Generator, s: []const u8) !void {
        try self.insertItem(c.ITM_LITERAL);
        try self.appendByte(@intCast(c.STRING_LONG_INTEGER));
        try self.insertString(s);
    }

    fn insertShortIntegerStringLiteral(self: *Generator, s: []const u8, base: u8) !void {
        try self.insertItem(c.ITM_LITERAL);
        try self.appendByte(@intCast(c.STRING_SHORT_INTEGER));
        try self.appendByte(base);
        try self.insertString(s);
    }

    fn insertShortIntegerBinaryLiteral(self: *Generator, value: u64, base: u8) !void {
        try self.insertItem(c.ITM_LITERAL);
        try self.appendByte(@intCast(c.BINARY_SHORT_INTEGER));
        try self.appendByte(base);
        try self.appendSlice(std.mem.asBytes(&value));
    }

    fn insertComplex34StringLiteral(self: *Generator, s: []const u8) !void {
        try self.insertItem(c.ITM_LITERAL);
        try self.appendByte(@intCast(c.STRING_COMPLEX34));
        try self.insertString(s);
    }

    fn insertComplex34BinaryLiteral(self: *Generator, real: []const u8, imag: []const u8) !void {
        var real_value: real34_t = undefined;
        var imag_value: real34_t = undefined;
        const c_real = try std.heap.page_allocator.dupeSentinel(u8, real, 0);
        defer std.heap.page_allocator.free(c_real);
        const c_imag = try std.heap.page_allocator.dupeSentinel(u8, imag, 0);
        defer std.heap.page_allocator.free(c_imag);

        try self.insertItem(c.ITM_LITERAL);
        try self.appendByte(@intCast(c.BINARY_COMPLEX34));
        _ = c.decQuadFromString(&real_value, c_real.ptr, &self.ctxt_real34);
        try self.appendSlice(std.mem.asBytes(&real_value));
        _ = c.decQuadFromString(&imag_value, c_imag.ptr, &self.ctxt_real34);
        try self.appendSlice(std.mem.asBytes(&imag_value));
    }

    fn insertStringLiteral(self: *Generator, s: []const u8) !void {
        try self.insertItem(c.ITM_LITERAL);
        try self.appendByte(@intCast(c.STRING_LABEL_VARIABLE));
        try self.insertString(s);
    }

    fn insertComment(self: *Generator, s: []const u8) !void {
        try self.insertItem(c.ITM_REM);
        try self.appendByte(@intCast(c.STRING_LABEL_VARIABLE));
        try self.insertString(s);
    }

    fn insertIndirectAccessVariable(self: *Generator, s: []const u8) !void {
        try self.appendByte(@intCast(c.INDIRECT_VARIABLE));
        try self.insertString(s);
    }

    fn insertIndirectAccessRegister(self: *Generator, reg: u8) !void {
        try self.appendByte(@intCast(c.INDIRECT_REGISTER));
        try self.appendByte(reg);
    }

    fn bytes(self: *const Generator) []const u8 {
        return self.memory[0..self.current_step];
    }
};

pub fn main(init: std.process.Init) !void {
    const allocator = std.heap.page_allocator;

    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();

    _ = args.next();
    const parsed_args = parseUpstreamRoot(&args);
    const output_path = parsed_args.first_positional orelse {
        std.debug.print("Usage: generateTestPgms [--upstream-root <path>] <output file>\n", .{});
        std.process.exit(1);
    };

    const preprocessed = try preprocessSource(allocator, init, parsed_args.upstream_root);
    defer allocator.free(preprocessed);

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    var generator = Generator.init();
    try parseProgram(preprocessed, arena.allocator(), &generator);
    try writeOutput(output_path, &generator);
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

fn preprocessSource(allocator: std.mem.Allocator, init: std.process.Init, upstream_root: []const u8) ![]u8 {
    try std.Io.Dir.cwd().createDirPath(init.io, preprocess_dir);
    try writeFile(preprocess_header_path, fake_c47_header);

    const decnumber_include = try upstreamPath(allocator, upstream_root, "dep/decNumberICU");
    defer allocator.free(decnumber_include);

    const c47_include = try upstreamPath(allocator, upstream_root, "src/c47");
    defer allocator.free(c47_include);

    const source_path = try upstreamPath(allocator, upstream_root, preprocess_source_path);
    defer allocator.free(source_path);

    var argv = try std.ArrayList([]const u8).initCapacity(allocator, 0);
    defer argv.deinit(allocator);

    try argv.appendSlice(allocator, &.{
        "zig",
        "cc",
        "-E",
        "-P",
        "-DGENERATE_TESTPGMS",
        "-DPC_BUILD=1",
        "-DDECNUMBER_FASTMUL=1",
    });

    switch (builtin.target.os.tag) {
        .linux => try argv.append(allocator, "-DLINUX=1"),
        .macos => try argv.append(allocator, "-DOSX=1"),
        .windows => try argv.append(allocator, "-DWIN32=1"),
        else => {},
    }
    if (builtin.target.ptrBitWidth() == 64) {
        try argv.append(allocator, "-DOS64BIT=1");
    } else {
        try argv.append(allocator, "-DOS32BIT=1");
    }

    try argv.appendSlice(allocator, &.{
        "-I",
        preprocess_dir,
        "-I",
        decnumber_include,
        "-I",
        c47_include,
        source_path,
    });

    const result = try std.process.run(allocator, init.io, .{
        .argv = argv.items,
        .environ_map = init.environ_map,
    });

    const ok = switch (result.term) {
        .exited => |code| code == 0,
        else => false,
    };
    if (!ok) {
        defer allocator.free(result.stdout);
        defer allocator.free(result.stderr);
        std.debug.print("{s}", .{result.stderr});
        return error.PreprocessFailed;
    }

    allocator.free(result.stderr);
    return result.stdout;
}

fn parseProgram(source: []const u8, allocator: std.mem.Allocator, generator: *Generator) !void {
    const start_marker = "currentStep = memory;";
    const end_marker = "testPgms = fopen(argv[1], \"wb\");";

    const start = std.mem.indexOf(u8, source, start_marker) orelse return error.MissingStartMarker;
    const body_start = start + start_marker.len;
    const end_rel = std.mem.indexOf(u8, source[body_start..], end_marker) orelse return error.MissingEndMarker;

    var scanner = Scanner{ .source = source[body_start .. body_start + end_rel] };
    while (true) {
        scanner.skipWhitespace();
        if (scanner.index >= scanner.source.len) break;

        if (std.mem.startsWith(u8, scanner.source[scanner.index..], "int32_t item;")) {
            try emitAllOps(generator);
            try skipAllOpsBlock(&scanner);
            continue;
        }

        switch (scanner.source[scanner.index]) {
            '{', '}' => {
                scanner.index += 1;
            },
            '*' => try parseByteWrite(&scanner, generator),
            '_' => try parseCall(&scanner, allocator, generator),
            else => return error.UnsupportedStatement,
        }
    }
}

fn parseByteWrite(scanner: *Scanner, generator: *Generator) !void {
    try scanner.consumeString("*(currentStep++)");
    try scanner.consumeChar('=');
    const value = try scanner.parseExpression();
    try scanner.consumeChar(';');

    if (value < 0 or value > std.math.maxInt(u8)) return error.InvalidByte;
    try generator.appendByte(@intCast(value));
}

fn lookupExpressionConstant(name: []const u8) !i64 {
    if (std.mem.eql(u8, name, "FIRST_LC_LOCAL_LABEL")) return c.FIRST_LC_LOCAL_LABEL;
    if (std.mem.eql(u8, name, "FIRST_LOCAL_FLAG")) return c.FIRST_LOCAL_FLAG;
    if (std.mem.eql(u8, name, "FIRST_LOCAL_REGISTER_IN_KS_CODE")) return c.FIRST_LOCAL_REGISTER_IN_KS_CODE;
    if (std.mem.eql(u8, name, "FLAG_IGN1ER")) return c.FLAG_IGN1ER;
    if (std.mem.eql(u8, name, "FLAG_K")) return c.FLAG_K;
    if (std.mem.eql(u8, name, "FLAG_M")) return c.FLAG_M;
    if (std.mem.eql(u8, name, "FLAG_W")) return c.FLAG_W;
    if (std.mem.eql(u8, name, "FLAG_X")) return c.FLAG_X;
    if (std.mem.eql(u8, name, "INDIRECT_REGISTER")) return c.INDIRECT_REGISTER;
    if (std.mem.eql(u8, name, "INDIRECT_VARIABLE")) return c.INDIRECT_VARIABLE;
    if (std.mem.eql(u8, name, "LAST_LOCAL_REGISTER_IN_KS_CODE")) return c.LAST_LOCAL_REGISTER_IN_KS_CODE;
    if (std.mem.eql(u8, name, "LAST_LOCAL_FLAG")) return c.LAST_LOCAL_FLAG;
    if (std.mem.eql(u8, name, "NUMBER_OF_SYSTEM_FLAGS")) return c.NUMBER_OF_SYSTEM_FLAGS;
    if (std.mem.eql(u8, name, "REGISTER_I_IN_KS_CODE")) return c.REGISTER_I_IN_KS_CODE;
    if (std.mem.eql(u8, name, "REGISTER_J_IN_KS_CODE")) return c.REGISTER_J_IN_KS_CODE;
    if (std.mem.eql(u8, name, "REGISTER_K_IN_KS_CODE")) return c.REGISTER_K_IN_KS_CODE;
    if (std.mem.eql(u8, name, "REGISTER_L_IN_KS_CODE")) return c.REGISTER_L_IN_KS_CODE;
    if (std.mem.eql(u8, name, "REGISTER_M_IN_KS_CODE")) return c.REGISTER_M_IN_KS_CODE;
    if (std.mem.eql(u8, name, "REGISTER_W_IN_KS_CODE")) return c.REGISTER_W_IN_KS_CODE;
    if (std.mem.eql(u8, name, "REGISTER_X_IN_KS_CODE")) return c.REGISTER_X_IN_KS_CODE;
    if (std.mem.eql(u8, name, "REGISTER_Y_IN_KS_CODE")) return c.REGISTER_Y_IN_KS_CODE;
    if (std.mem.eql(u8, name, "REGISTER_Z_IN_KS_CODE")) return c.REGISTER_Z_IN_KS_CODE;
    if (std.mem.eql(u8, name, "SYSTEM_FLAG_NUMBER")) return c.SYSTEM_FLAG_NUMBER;
    if (std.mem.eql(u8, name, "VALUE_0")) return c.VALUE_0;
    if (std.mem.eql(u8, name, "VALUE_1")) return c.VALUE_1;
    if (std.mem.eql(u8, name, "STRING_LABEL_VARIABLE")) return c.STRING_LABEL_VARIABLE;
    return error.InvalidInteger;
}

fn parseCall(scanner: *Scanner, allocator: std.mem.Allocator, generator: *Generator) !void {
    const name = try scanner.parseIdentifier();
    try scanner.consumeChar('(');

    if (std.mem.eql(u8, name, "_insertItem")) {
        const value = try scanner.parseExpression();
        try scanner.consumeChar(')');
        try scanner.consumeChar(';');
        try generator.insertItem(@intCast(value));
        return;
    }
    if (std.mem.eql(u8, name, "_insertLabelVariableString")) {
        const value = try scanner.parseConcatenatedStringLiterals(allocator);
        try scanner.consumeChar(')');
        try scanner.consumeChar(';');
        try generator.insertLabelVariableString(value);
        return;
    }
    if (std.mem.eql(u8, name, "_insertReal34StringLiteral")) {
        const value = try scanner.parseConcatenatedStringLiterals(allocator);
        try scanner.consumeChar(')');
        try scanner.consumeChar(';');
        try generator.insertReal34StringLiteral(value);
        return;
    }
    if (std.mem.eql(u8, name, "_insertTimeStringLiteral")) {
        const value = try scanner.parseConcatenatedStringLiterals(allocator);
        try scanner.consumeChar(')');
        try scanner.consumeChar(';');
        try generator.insertTimeStringLiteral(value);
        return;
    }
    if (std.mem.eql(u8, name, "_insertDateStringLiteral")) {
        const value = try scanner.parseConcatenatedStringLiterals(allocator);
        try scanner.consumeChar(')');
        try scanner.consumeChar(';');
        try generator.insertDateStringLiteral(value);
        return;
    }
    if (std.mem.eql(u8, name, "_insertAngleDegreeStringLiteral")) {
        const value = try scanner.parseConcatenatedStringLiterals(allocator);
        try scanner.consumeChar(')');
        try scanner.consumeChar(';');
        try generator.insertAngleDegreeStringLiteral(value);
        return;
    }
    if (std.mem.eql(u8, name, "_insertAngleDmsStringLiteral")) {
        const value = try scanner.parseConcatenatedStringLiterals(allocator);
        try scanner.consumeChar(')');
        try scanner.consumeChar(';');
        try generator.insertAngleDmsStringLiteral(value);
        return;
    }
    if (std.mem.eql(u8, name, "_insertAngleGradStringLiteral")) {
        const value = try scanner.parseConcatenatedStringLiterals(allocator);
        try scanner.consumeChar(')');
        try scanner.consumeChar(';');
        try generator.insertAngleGradStringLiteral(value);
        return;
    }
    if (std.mem.eql(u8, name, "_insertAngleMultpiStringLiteral")) {
        const value = try scanner.parseConcatenatedStringLiterals(allocator);
        try scanner.consumeChar(')');
        try scanner.consumeChar(';');
        try generator.insertAngleMultpiStringLiteral(value);
        return;
    }
    if (std.mem.eql(u8, name, "_insertAngleRadianStringLiteral")) {
        const value = try scanner.parseConcatenatedStringLiterals(allocator);
        try scanner.consumeChar(')');
        try scanner.consumeChar(';');
        try generator.insertAngleRadianStringLiteral(value);
        return;
    }
    if (std.mem.eql(u8, name, "_insertReal34BinaryLiteral")) {
        const value = try scanner.parseConcatenatedStringLiterals(allocator);
        try scanner.consumeChar(')');
        try scanner.consumeChar(';');
        try generator.insertReal34BinaryLiteral(value);
        return;
    }
    if (std.mem.eql(u8, name, "_insertLongIntegerStringLiteral")) {
        const value = try scanner.parseConcatenatedStringLiterals(allocator);
        try scanner.consumeChar(')');
        try scanner.consumeChar(';');
        try generator.insertLongIntegerStringLiteral(value);
        return;
    }
    if (std.mem.eql(u8, name, "_insertShortIntegerStringLiteral")) {
        const value = try scanner.parseConcatenatedStringLiterals(allocator);
        try scanner.consumeChar(',');
        const base = try scanner.parseExpression();
        try scanner.consumeChar(')');
        try scanner.consumeChar(';');
        try generator.insertShortIntegerStringLiteral(value, @intCast(base));
        return;
    }
    if (std.mem.eql(u8, name, "_insertShortIntegerBinaryLiteral")) {
        const value = try scanner.parseUnsignedInteger();
        try scanner.consumeChar(',');
        const base = try scanner.parseUnsignedInteger();
        try scanner.consumeChar(')');
        try scanner.consumeChar(';');
        try generator.insertShortIntegerBinaryLiteral(value, @intCast(base));
        return;
    }
    if (std.mem.eql(u8, name, "_insertComplex34StringLiteral")) {
        const value = try scanner.parseConcatenatedStringLiterals(allocator);
        try scanner.consumeChar(')');
        try scanner.consumeChar(';');
        try generator.insertComplex34StringLiteral(value);
        return;
    }
    if (std.mem.eql(u8, name, "_insertComplex34BinaryLiteral")) {
        const real = try scanner.parseConcatenatedStringLiterals(allocator);
        try scanner.consumeChar(',');
        const imag = try scanner.parseConcatenatedStringLiterals(allocator);
        try scanner.consumeChar(')');
        try scanner.consumeChar(';');
        try generator.insertComplex34BinaryLiteral(real, imag);
        return;
    }
    if (std.mem.eql(u8, name, "_insertStringLiteral")) {
        const value = try scanner.parseConcatenatedStringLiterals(allocator);
        try scanner.consumeChar(')');
        try scanner.consumeChar(';');
        try generator.insertStringLiteral(value);
        return;
    }
    if (std.mem.eql(u8, name, "_insertComment")) {
        const value = try scanner.parseConcatenatedStringLiterals(allocator);
        try scanner.consumeChar(')');
        try scanner.consumeChar(';');
        try generator.insertComment(value);
        return;
    }
    if (std.mem.eql(u8, name, "_insertIndirectAccessVariable")) {
        const value = try scanner.parseConcatenatedStringLiterals(allocator);
        try scanner.consumeChar(')');
        try scanner.consumeChar(';');
        try generator.insertIndirectAccessVariable(value);
        return;
    }
    if (std.mem.eql(u8, name, "_insertIndirectAccessRegister")) {
        const reg = try scanner.parseExpression();
        try scanner.consumeChar(')');
        try scanner.consumeChar(';');
        try generator.insertIndirectAccessRegister(@intCast(reg));
        return;
    }

    return error.UnsupportedStatement;
}

fn parseUnsignedToken(token: []const u8) !u64 {
    if (token.len == 0) return error.InvalidInteger;
    const base: u8 = if (token.len > 2 and token[0] == '0' and (token[1] == 'x' or token[1] == 'X')) 16 else 10;
    const digits = if (base == 16) token[2..] else token;
    return std.fmt.parseUnsigned(u64, digits, base) catch error.InvalidInteger;
}

fn skipAllOpsBlock(scanner: *Scanner) !void {
    try scanner.consumeString("int32_t item;");

    var depth: usize = 0;
    while (scanner.index < scanner.source.len) {
        switch (scanner.source[scanner.index]) {
            '"' => try scanner.skipStringLiteral(),
            '{' => {
                depth += 1;
                scanner.index += 1;
            },
            '}' => {
                if (depth == 0) {
                    scanner.index += 1;
                    return;
                }
                depth -= 1;
                scanner.index += 1;
            },
            else => scanner.index += 1,
        }
    }

    return error.UnexpectedToken;
}

fn emitAllOps(generator: *Generator) !void {
    var item: usize = 1;
    while (item < last_item) : (item += 1) {
        switch (indexOfItems[item].status & c.PTP_STATUS) {
            c.PTP_NONE => if (item != c.ITM_END) try generator.insertItem(@intCast(item)),
            c.PTP_DECLARE_LABEL => try emitLabelForms(generator, item, false),
            c.PTP_LABEL => try emitLabelForms(generator, item, true),
            c.PTP_REGISTER => try emitRegisterForms(generator, item),
            c.PTP_FLAG => try emitFlagForms(generator, item),
            c.PTP_NUMBER_8 => try emitNumber8Forms(generator, item),
            c.PTP_NUMBER_16 => try emitNumber16Forms(generator, item),
            c.PTP_COMPARE => try emitCompareForms(generator, item),
            c.PTP_KEYG_KEYX => try emitKeyGKeyXForms(generator),
            c.PTP_SKIP_BACK => try emitSkipBackForms(generator, item),
            c.PTP_NUMBER_8_16 => try emitNumber816Forms(generator, item),
            c.PTP_SHUFFLE => try emitShuffleForms(generator, item),
            c.PTP_MENU => try emitMenuForms(generator, item),
            c.PTP_LITERAL => try emitLiteralForms(generator),
            c.PTP_REM => try generator.insertComment("This is a comment."),
            c.PTP_DISABLED => {},
            else => {},
        }
    }
    try generator.insertItem(c.ITM_END);
}

fn tamMin(item: usize) u16 {
    const shift_amount: u4 = @intCast(c.TAM_MAX_BITS);
    return indexOfItems[item].tamMinMax >> shift_amount;
}

fn tamMax(item: usize) u16 {
    return indexOfItems[item].tamMinMax & @as(u16, @intCast(c.TAM_MAX_MASK));
}

fn emitItemByte(generator: *Generator, item: usize, value: i64) !void {
    if (value < 0 or value > std.math.maxInt(u8)) return error.InvalidByte;
    try generator.insertItem(@intCast(item));
    try generator.appendByte(@intCast(value));
}

fn emitItemU16LittleEndian(generator: *Generator, item: usize, value: u16) !void {
    try generator.insertItem(@intCast(item));
    try generator.appendByte(@intCast(value & 0xff));
    try generator.appendByte(@intCast(value >> 8));
}

fn emitItemU16BigEndian(generator: *Generator, item: usize, value: u16) !void {
    try generator.insertItem(@intCast(item));
    try generator.appendByte(@intCast(value >> 8));
    try generator.appendByte(@intCast(value & 0xff));
}

fn emitItemLabel(generator: *Generator, item: usize, label: []const u8) !void {
    try generator.insertItem(@intCast(item));
    try generator.insertLabelVariableString(label);
}

fn emitItemIndirectRegister(generator: *Generator, item: usize, reg: u8) !void {
    try generator.insertItem(@intCast(item));
    try generator.insertIndirectAccessRegister(reg);
}

fn emitItemIndirectVariable(generator: *Generator, item: usize, name: []const u8) !void {
    try generator.insertItem(@intCast(item));
    try generator.insertIndirectAccessVariable(name);
}

fn emitLabelForms(generator: *Generator, item: usize, include_indirect: bool) !void {
    try emitItemByte(generator, item, tamMin(item));
    try emitItemByte(generator, item, tamMax(item));
    try emitItemByte(generator, item, 100);
    try emitItemByte(generator, item, 111);
    try emitItemByte(generator, item, c.FIRST_LC_LOCAL_LABEL);
    try emitItemByte(generator, item, c.FIRST_LC_LOCAL_LABEL + ('l' - 'a'));
    try emitItemLabel(generator, item, cimke_label);

    if (!include_indirect) return;

    const regs = [_]u8{
        0,
        99,
        @intCast(c.REGISTER_X_IN_KS_CODE),
        @intCast(c.REGISTER_W_IN_KS_CODE),
        @intCast(c.FIRST_LOCAL_REGISTER_IN_KS_CODE),
        @intCast(c.LAST_LOCAL_REGISTER_IN_KS_CODE),
    };
    for (regs) |reg| try emitItemIndirectRegister(generator, item, reg);
    try emitItemIndirectVariable(generator, item, var_alpha_name);
}

fn emitRegisterForms(generator: *Generator, item: usize) !void {
    try emitItemByte(generator, item, tamMin(item));
    try emitItemByte(generator, item, tamMax(item));

    const direct_regs = [_]u8{
        @intCast(c.REGISTER_X_IN_KS_CODE),
        @intCast(c.REGISTER_W_IN_KS_CODE),
        @intCast(c.FIRST_LOCAL_REGISTER_IN_KS_CODE),
        @intCast(c.LAST_LOCAL_REGISTER_IN_KS_CODE),
    };
    for (direct_regs) |reg| try emitItemByte(generator, item, reg);
    try emitItemLabel(generator, item, "Var");

    const indirect_regs = [_]u8{ 0, 99 } ++ direct_regs;
    for (indirect_regs) |reg| try emitItemIndirectRegister(generator, item, reg);
    try emitItemIndirectVariable(generator, item, "Var");
}

fn emitFlagForms(generator: *Generator, item: usize) !void {
    try emitItemByte(generator, item, tamMin(item));
    try emitItemByte(generator, item, tamMax(item));

    const direct_flags = [_]i64{ c.FLAG_X, c.FLAG_K, c.FLAG_M, c.FLAG_W, c.FIRST_LOCAL_FLAG, c.LAST_LOCAL_FLAG };
    for (direct_flags) |flag| try emitItemByte(generator, item, flag);
    try emitItemByte(generator, item, c.SYSTEM_FLAG_NUMBER);
    try generator.appendByte(0);
    try emitItemByte(generator, item, c.SYSTEM_FLAG_NUMBER);
    try generator.appendByte(@intCast(c.NUMBER_OF_SYSTEM_FLAGS - 1));

    const indirect_regs = [_]u8{
        0,
        99,
        @intCast(c.REGISTER_X_IN_KS_CODE),
        @intCast(c.REGISTER_W_IN_KS_CODE),
        @intCast(c.FIRST_LOCAL_REGISTER_IN_KS_CODE),
        @intCast(c.LAST_LOCAL_FLAG),
    };
    for (indirect_regs) |reg| try emitItemIndirectRegister(generator, item, reg);
    try emitItemIndirectVariable(generator, item, "Var");
}

fn emitNumber8Forms(generator: *Generator, item: usize) !void {
    try emitItemByte(generator, item, tamMin(item));
    try emitItemByte(generator, item, tamMax(item));

    const indirect_regs = [_]u8{
        0,
        99,
        @intCast(c.REGISTER_X_IN_KS_CODE),
        @intCast(c.REGISTER_W_IN_KS_CODE),
        @intCast(c.FIRST_LOCAL_REGISTER_IN_KS_CODE),
        @intCast(c.LAST_LOCAL_REGISTER_IN_KS_CODE),
    };
    for (indirect_regs) |reg| try emitItemIndirectRegister(generator, item, reg);
    try emitItemIndirectVariable(generator, item, "Var");
}

fn emitNumber16Forms(generator: *Generator, item: usize) !void {
    if (isFunctionOldParam16(@intCast(item))) {
        try emitItemU16LittleEndian(generator, item, tamMin(item));
        try emitItemU16LittleEndian(generator, item, tamMax(item));
        return;
    }

    try emitItemU16BigEndian(generator, item, tamMin(item));
    try emitItemU16BigEndian(generator, item, tamMax(item));

    const indirect_regs = [_]u8{
        0,
        99,
        @intCast(c.REGISTER_X_IN_KS_CODE),
        @intCast(c.REGISTER_W_IN_KS_CODE),
        @intCast(c.FIRST_LOCAL_REGISTER_IN_KS_CODE),
        @intCast(c.LAST_LOCAL_REGISTER_IN_KS_CODE),
    };
    for (indirect_regs) |reg| try emitItemIndirectRegister(generator, item, reg);
    try emitItemIndirectVariable(generator, item, "Var");
}

fn emitCompareForms(generator: *Generator, item: usize) !void {
    const values = [_]i64{
        c.VALUE_0,
        c.VALUE_1,
        0,
        99,
        c.REGISTER_X_IN_KS_CODE,
        c.REGISTER_W_IN_KS_CODE,
        c.FIRST_LOCAL_REGISTER_IN_KS_CODE,
        c.LAST_LOCAL_REGISTER_IN_KS_CODE,
    };
    for (values) |value| try emitItemByte(generator, item, value);
    try emitItemLabel(generator, item, "Var");

    const indirect_regs = [_]u8{
        0,
        99,
        @intCast(c.REGISTER_X_IN_KS_CODE),
        @intCast(c.REGISTER_W_IN_KS_CODE),
        @intCast(c.FIRST_LOCAL_REGISTER_IN_KS_CODE),
        @intCast(c.LAST_LOCAL_REGISTER_IN_KS_CODE),
    };
    for (indirect_regs) |reg| try emitItemIndirectRegister(generator, item, reg);
    try emitItemIndirectVariable(generator, item, "Var");
}

fn emitKeyInvocation(generator: *Generator, prefix: KeyPrefix, op: u8, target: KeyTarget) !void {
    try generator.insertItem(c.ITM_KEY);
    switch (prefix) {
        .direct => |value| try generator.appendByte(value),
        .reg => |value| try generator.insertIndirectAccessRegister(value),
        .variable => |name| try generator.insertIndirectAccessVariable(name),
    }
    try generator.appendByte(op);
    switch (target) {
        .byte => |value| try generator.appendByte(value),
        .label => |name| try generator.insertLabelVariableString(name),
        .reg => |value| try generator.insertIndirectAccessRegister(value),
        .variable => |name| try generator.insertIndirectAccessVariable(name),
    }
}

fn emitKeyGKeyXForms(generator: *Generator) !void {
    const ops = [_]u8{ @intCast(c.ITM_GTO), @intCast(c.ITM_XEQ) };
    const prefixes = [_]KeyPrefix{
        .{ .direct = 1 },
        .{ .direct = 21 },
        .{ .reg = 0 },
        .{ .reg = 99 },
        .{ .reg = @intCast(c.REGISTER_X_IN_KS_CODE) },
        .{ .reg = @intCast(c.REGISTER_W_IN_KS_CODE) },
        .{ .reg = @intCast(c.FIRST_LOCAL_REGISTER_IN_KS_CODE) },
        .{ .reg = @intCast(c.LAST_LOCAL_REGISTER_IN_KS_CODE) },
        .{ .variable = "Var" },
    };
    const targets = [_]KeyTarget{
        .{ .byte = 0 },
        .{ .byte = 99 },
        .{ .byte = 100 },
        .{ .byte = 104 },
        .{ .label = "Label" },
        .{ .reg = 0 },
        .{ .reg = 99 },
        .{ .reg = @intCast(c.REGISTER_X_IN_KS_CODE) },
        .{ .reg = @intCast(c.REGISTER_W_IN_KS_CODE) },
        .{ .reg = @intCast(c.FIRST_LOCAL_REGISTER_IN_KS_CODE) },
        .{ .reg = @intCast(c.LAST_LOCAL_REGISTER_IN_KS_CODE) },
        .{ .variable = "Var" },
    };

    for (ops) |op| {
        for (prefixes) |prefix| {
            for (targets) |target| {
                try emitKeyInvocation(generator, prefix, op, target);
            }
        }
    }
}

fn emitSkipBackForms(generator: *Generator, item: usize) !void {
    try emitItemByte(generator, item, tamMin(item));
    try emitItemByte(generator, item, tamMax(item));
}

fn emitNumber816Forms(generator: *Generator, item: usize) !void {
    try emitItemByte(generator, item, 1);
    try emitItemByte(generator, item, 79);

    const indirect_regs = [_]u8{
        0,
        99,
        @intCast(c.REGISTER_X_IN_KS_CODE),
        @intCast(c.REGISTER_W_IN_KS_CODE),
        @intCast(c.FIRST_LOCAL_REGISTER_IN_KS_CODE),
        @intCast(c.LAST_LOCAL_REGISTER_IN_KS_CODE),
    };
    for (indirect_regs) |reg| try emitItemIndirectRegister(generator, item, reg);
    try emitItemIndirectVariable(generator, item, "Var");
}

fn emitShuffleForms(generator: *Generator, item: usize) !void {
    for ([_]u8{ 0, 27, 228, 255 }) |value| {
        try emitItemByte(generator, item, value);
    }
}

fn emitMenuForms(generator: *Generator, item: usize) !void {
    try emitItemLabel(generator, item, "Menu");
    const indirect_regs = [_]u8{
        0,
        99,
        @intCast(c.REGISTER_X_IN_KS_CODE),
        @intCast(c.REGISTER_K_IN_KS_CODE),
        @intCast(c.REGISTER_M_IN_KS_CODE),
        @intCast(c.REGISTER_W_IN_KS_CODE),
        @intCast(c.FIRST_LOCAL_REGISTER_IN_KS_CODE),
        @intCast(c.LAST_LOCAL_REGISTER_IN_KS_CODE),
    };
    for (indirect_regs) |reg| try emitItemIndirectRegister(generator, item, reg);
    try emitItemIndirectVariable(generator, item, "Var");
}

fn emitLiteralForms(generator: *Generator) !void {
    const short_value: u64 = 0xf807060504030201;
    for ([_]u8{ 2, 3, 4, 8, 10, 16 }) |base| {
        try generator.insertShortIntegerBinaryLiteral(short_value, base);
    }
    try generator.insertItem(c.ITM_NOP);
    try generator.insertReal34BinaryLiteral("4.224835011040144513774020064192513e-6083");
    try generator.insertComplex34BinaryLiteral(
        "4.224835011040144513774020064192513e-6083",
        "4.81839027104401517790084321196529e-1924",
    );
    try generator.insertShortIntegerStringLiteral("ABCDEF", 16);
    try generator.insertShortIntegerStringLiteral("-ABCDEF", 16);
    try generator.insertLongIntegerStringLiteral("-12345");
    try generator.insertComplex34StringLiteral("1-i2");
    try generator.insertTimeStringLiteral("21.2345");
    try generator.insertTimeStringLiteral("-1.2345");
    try generator.insertDateStringLiteral("2456789");
    try generator.insertAngleDmsStringLiteral("71.2345");
    try generator.insertAngleDmsStringLiteral("-1.2345");
    try generator.insertAngleRadianStringLiteral("1.2345");
    try generator.insertAngleRadianStringLiteral("-1.2345");
    try generator.insertAngleGradStringLiteral("198.2345");
    try generator.insertAngleGradStringLiteral("-1.2345");
    try generator.insertAngleDegreeStringLiteral("179.2345");
    try generator.insertAngleDegreeStringLiteral("-1.2345");
    try generator.insertAngleMultpiStringLiteral("1.2345");
    try generator.insertAngleMultpiStringLiteral("-1.2345");
    try generator.insertStringLiteral("");
    try generator.insertStringLiteral("A message in English");
    try generator.insertStringLiteral(french_message);
}

fn writeOutput(path: []const u8, generator: *const Generator) !void {
    var size_of_programs: u32 = @intCast(generator.bytes().len);
    const file_path = try std.heap.page_allocator.dupeSentinel(u8, path, 0);
    defer std.heap.page_allocator.free(file_path);

    const file = c.fopen(file_path.ptr, "wb") orelse return error.FileOpenFailed;
    defer _ = c.fclose(file);

    try writeAll(file, std.mem.asBytes(&size_of_programs));
    try writeAll(file, generator.bytes());
}

fn writeFile(path: []const u8, contents: []const u8) !void {
    const c_path = try std.heap.page_allocator.dupeSentinel(u8, path, 0);
    defer std.heap.page_allocator.free(c_path);

    const file = c.fopen(c_path.ptr, "wb") orelse return error.FileOpenFailed;
    defer _ = c.fclose(file);

    try writeAll(file, contents);
}

fn writeAll(file: *c.FILE, contents: []const u8) !void {
    if (contents.len == 0) return;
    if (c.fwrite(contents.ptr, 1, contents.len, file) != contents.len) return error.FileWriteFailed;
}

pub export fn xcopy(dest: ?*anyopaque, source: ?*const anyopaque, n: u32) ?*anyopaque {
    const out_ptr = dest orelse return dest;
    const src_ptr = source orelse return dest;
    const out = @as([*]u8, @ptrCast(out_ptr));
    const src = @as([*]const u8, @ptrCast(src_ptr));

    if (@intFromPtr(src) > @intFromPtr(out)) {
        var index: usize = 0;
        while (index < n) : (index += 1) {
            out[index] = src[index];
        }
    } else if (@intFromPtr(src) < @intFromPtr(out)) {
        var index: usize = n;
        while (index > 0) {
            index -= 1;
            out[index] = src[index];
        }
    }

    return dest;
}
