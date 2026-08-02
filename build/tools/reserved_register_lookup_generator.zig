const std = @import("std");
const Io = std.Io;

const NameEntry = struct {
    name: [7]u8,
    reg: []const u8,
};

const names = [_]NameEntry{
    .{ .name = .{ 3, 'A', 'D', 'M', 0, 0, 0 }, .reg = "RESERVED_VARIABLE_ADM" },
    .{ .name = .{ 5, 'D', '.', 'M', 'A', 'X', 0 }, .reg = "RESERVED_VARIABLE_DENMAX" },
    .{ .name = .{ 3, 'I', 'S', 'M', 0, 0, 0 }, .reg = "RESERVED_VARIABLE_ISM" },
    .{ .name = .{ 6, 'R', 'E', 'A', 'L', 'D', 'F' }, .reg = "RESERVED_VARIABLE_REALDF" },
    .{ .name = .{ 4, '#', 'D', 'E', 'C', 0, 0 }, .reg = "RESERVED_VARIABLE_NDEC" },
    .{ .name = .{ 3, 'A', 'C', 'C', 0, 0, 0 }, .reg = "RESERVED_VARIABLE_ACC" },
    .{ .name = .{ 5, 161, 145, 'L', 'i', 'm', 0 }, .reg = "RESERVED_VARIABLE_ULIM" },
    .{ .name = .{ 5, 161, 147, 'L', 'i', 'm', 0 }, .reg = "RESERVED_VARIABLE_LLIM" },
    .{ .name = .{ 2, 'F', 'V', 0, 0, 0, 0 }, .reg = "RESERVED_VARIABLE_FV" },
    .{ .name = .{ 4, 'I', '%', '/', 'a', 0, 0 }, .reg = "RESERVED_VARIABLE_IPONA" },
    .{ .name = .{ 5, 'N', 'P', 'P', 'E', 'R', 0 }, .reg = "RESERVED_VARIABLE_NPPER" },
    .{ .name = .{ 6, 'P', 'P', 'E', 'R', '/', 'a' }, .reg = "RESERVED_VARIABLE_PPERONA" },
    .{ .name = .{ 3, 'P', 'M', 'T', 0, 0, 0 }, .reg = "RESERVED_VARIABLE_PMT" },
    .{ .name = .{ 2, 'P', 'V', 0, 0, 0, 0 }, .reg = "RESERVED_VARIABLE_PV" },
    .{ .name = .{ 6, 'G', 'R', 'A', 'M', 'O', 'D' }, .reg = "RESERVED_VARIABLE_GRAMOD" },
    .{ .name = .{ 3, 161, 145, 'X', 0, 0, 0 }, .reg = "RESERVED_VARIABLE_UX" },
    .{ .name = .{ 3, 161, 147, 'X', 0, 0, 0 }, .reg = "RESERVED_VARIABLE_LX" },
    .{ .name = .{ 6, 'C', 'P', 'E', 'R', '/', 'a' }, .reg = "RESERVED_VARIABLE_CPERONA" },
    .{ .name = .{ 5, 161, 145, 'E', 'S', 'T', 0 }, .reg = "RESERVED_VARIABLE_UEST" },
    .{ .name = .{ 5, 161, 147, 'E', 'S', 'T', 0 }, .reg = "RESERVED_VARIABLE_LEST" },
    .{ .name = .{ 3, 161, 145, 'Y', 0, 0, 0 }, .reg = "RESERVED_VARIABLE_UY" },
    .{ .name = .{ 3, 161, 147, 'Y', 0, 0, 0 }, .reg = "RESERVED_VARIABLE_LY" },
};

fn writeAll(out: *Io.Writer, bytes: []const u8) !void {
    try out.writeAll(bytes);
}

fn writeByte(out: *Io.Writer, byte: u8) !void {
    const one = [1]u8{byte};
    try writeAll(out, &one);
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var stdout_buffer: [256]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const out = &stdout_writer.interface;

    try writeAll(
        out,
        "struct reservedRegister {\n" ++
            "  char name[7];\n" ++
            "  calcRegister_t reg;\n" ++
            "};\n\n" ++
            "%%\n",
    );

    for (names) |entry| {
        const n = entry.name[0];
        try writeByte(out, '"');
        var index: usize = 1;
        while (index <= n) : (index += 1) {
            const ch = entry.name[index];
            if (ch == '\\' or ch == '"') {
                try writeByte(out, '\\');
            }
            try writeByte(out, ch);
        }

        var line_buffer: [96]u8 = undefined;
        const line = try std.fmt.bufPrint(&line_buffer, "\",{s}\n", .{entry.reg});
        try writeAll(out, line);
    }

    try out.flush();
}
