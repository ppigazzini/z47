const std = @import("std");
const frontier_print = @import("frontier_print.zig"); // M-callconv: Zig-to-Zig

fn bufPrintZ(buffer: []u8, comptime format: []const u8, args: anytype) ![:0]u8 {
    const slice = try std.fmt.bufPrint(buffer[0 .. buffer.len - 1], format, args);
    buffer[slice.len] = 0;
    return buffer[0..slice.len :0];
}

const FLAG_PRTACT: c_uint = 0xc020;
const TI_PRINT_COMPLETE: u8 = 136;

const PrintAllItemsStage = enum {
    initialize,
    validate_printer,
    print_header,
    iterate_items,
    finalize,
};

const print_all_items_stage_sequence = [_]PrintAllItemsStage{
    .initialize,
    .validate_printer,
    .print_header,
    .iterate_items,
    .finalize,
};

const PrintAllItemsContext = struct {
    line_buf: [128]u8 = undefined,
    item: u16 = 1,

    fn initialize(self: *PrintAllItemsContext) void {
        _ = self;
        currentKeyCode = 255;
    }

    fn validatePrinter(self: *PrintAllItemsContext) bool {
        _ = self;
        return getSystemFlag(@as(c_int, @intCast(FLAG_PRTACT)));
    }

    fn printHeader(self: *PrintAllItemsContext) void {
        _ = self;
        frontier_print.printLine("item catname  menuname", 1);
    }

    fn printCurrent(self: *PrintAllItemsContext) void {
        const catalog_name = frontier_print.z47_frontier_item_catalog_name(self.item);
        const softmenu_name = frontier_print.z47_frontier_item_softmenu_name(self.item);

        const left = bufPrintZ(&self.line_buf, "{d: >4} {s}", .{ self.item, catalog_name }) catch return;
        frontier_print.printLine(left, 0);
        frontier_print.printTab(97);

        const right = bufPrintZ(&self.line_buf, "{s} ", .{softmenu_name}) catch return;
        frontier_print.printLine(right, 1);
    }

    fn iterateItems(self: *PrintAllItemsContext) void {
        const last_item = frontier_print.z47_frontier_last_item();
        while (self.item < last_item) : (self.item += 1) {
            self.printCurrent();
            if (frontier_print.z47_frontier_print_exit_pressed()) {
                break;
            }
        }
    }

    fn finalize(self: *PrintAllItemsContext) void {
        _ = self;
        temporaryInformation = TI_PRINT_COMPLETE;
    }
};

const PrintAllItemsRunner = struct {
    ctx: PrintAllItemsContext = .{},

    fn run(self: *PrintAllItemsRunner) void {
        for (print_all_items_stage_sequence) |stage| {
            if (!self.executeStage(stage)) {
                return;
            }
        }
    }

    fn executeStage(self: *PrintAllItemsRunner, stage: PrintAllItemsStage) bool {
        switch (stage) {
            .initialize => {
                self.ctx.initialize();
                return true;
            },
            .validate_printer => return self.ctx.validatePrinter(),
            .print_header => {
                self.ctx.printHeader();
                return true;
            },
            .iterate_items => {
                self.ctx.iterateItems();
                return true;
            },
            .finalize => {
                self.ctx.finalize();
                return true;
            },
        }
    }
};

pub fn run() void {
    var runner = PrintAllItemsRunner{};
    runner.run();
}

extern var currentKeyCode: u8;
extern var temporaryInformation: u8;

extern fn getSystemFlag(sf: c_int) bool;
