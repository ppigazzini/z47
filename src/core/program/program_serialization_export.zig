// SPDX-License-Identifier: GPL-3.0-only
//
// The RTF export half of the program serializer: EXPORTP writes the current
// program as an RTF document rather than the `.p47` byte dump WRITEP produces
// (src/c47/saveRestorePrograms.c fnPExport / _fnExportProgram / _exportProgram).
//
// The listing is decoded step by step through decodeOneStep_XPORT, which writes
// into the shared tmpString, so every buffer here is that same scratch area or a
// local staging copy of it -- a private buffer would lose the decode.

const std = @import("std");
const runtime = @import("program_serialization_runtime.zig");

/// One row of the indent table: an instruction-name pattern and what it does to
/// the listing's layout. `indent` and `add_next_line_indent` are column counts,
/// negative to outdent; upstream stores them in uint8_t fields and relies on the
/// int8_t accumulator wrapping -2 back down.
const IndentRow = struct {
    item_name: []const u8,
    previous_new_line: bool,
    indent: i8,
    add_next_line_indent: i8,
};

fn indentRow(item_name: []const u8, previous_new_line: bool, indent: i8, add_next_line_indent: i8) IndentRow {
    return .{
        .item_name = item_name,
        .previous_new_line = previous_new_line,
        .indent = indent,
        .add_next_line_indent = add_next_line_indent,
    };
}

const STD_LEFT_SINGLE_QUOTE = "\xa0\x18";

/// Long enough for the widest header line: four decimal fields and the fixed
/// text around them.
const TMP_HEADER_LENGTH: usize = 128;

// The first row whose pattern matches stops the search, so order is meaningful.
const indents = [_]IndentRow{
    indentRow("REM", false, 0, 0),
    indentRow("ENDP", false, 0, 0),
    indentRow(STD_LEFT_SINGLE_QUOTE, false, 0, 0),
    // [TEST]
    indentRow("ENTRY?", false, 0, 2),
    indentRow("KEY?", false, 0, 2),
    indentRow("LBL?", false, 0, 2),
    indentRow("STRI?", false, 0, 2),
    indentRow("CONVG?", false, 0, 2),
    indentRow("TOP?", false, 0, 2),
    indentRow("INT?", false, 0, 2),
    indentRow("EVEN?", false, 0, 2),
    indentRow("ODD?", false, 0, 2),
    indentRow("PRIME?", false, 0, 2),
    indentRow("LEAP?", false, 0, 2),
    indentRow("FP?", false, 0, 2),
    indentRow("x* ?", false, 0, 2),
    indentRow("x** ?", false, 0, 2),
    indentRow("x=*0?", false, 0, 2),
    indentRow("SPEC?", false, 0, 2),
    indentRow("NaN?", false, 0, 2),
    indentRow("M.SQR?", false, 0, 2),
    indentRow("MATR?", false, 0, 2),
    indentRow("CPX?", false, 0, 2),
    indentRow("REAL?", false, 0, 2),
    // [LOOP]
    indentRow("DSE", false, 0, 2),
    indentRow("DSZ", false, 0, 2),
    indentRow("DSL", false, 0, 2),
    indentRow("ISE", false, 0, 2),
    indentRow("ISZ", false, 0, 2),
    indentRow("ISG", false, 0, 2),
    // [P.FN1]
    indentRow("LBL", true, -2, 0),
    indentRow("GTO", false, -2, 0),
    indentRow("XEQ", false, -2, 0),
    indentRow("RTN", false, -2, 0),
    indentRow("END", false, -2, 0),
    indentRow(".END.", false, -2, 0),
};

/// Prefix comparison in which '*' on either side matches any byte, active from
/// the second byte on. A pattern longer than the decoded step is a mismatch, so
/// "RE" cannot claim the "REAL?" row.
fn subStrWildCardCompare(in1: []const u8, in2: []const u8) bool {
    var i: usize = 0;
    while (i < in2.len and i < in1.len) : (i += 1) {
        if (!(i >= 1 and (in1[i] == '*' or in2[i] == '*'))) {
            if (in1[i] != in2[i]) {
                return false;
            }
        }
    }
    if (i >= in1.len and i < in2.len) {
        return false;
    }
    return true;
}

/// Matches the decoded step now in tmpString against the indent table, applying
/// the matched row's layout to the three outputs. Returns the matched row index,
/// or indents.len when nothing matched -- the caller only compares that value
/// with the previous line's, so the miss value has to be stable, not valid.
fn findIndents(new_line: *bool, indent: *i8, add_next_line_indent: *i8) i16 {
    var jj: i16 = 0;
    for (indents) |row| {
        if (subStrWildCardCompare(runtime.tmpStringContent(), row.item_name)) {
            new_line.* = row.previous_new_line;
            indent.* +%= row.indent;
            add_next_line_indent.* = row.add_next_line_indent;
            return jj;
        }
        jj += 1;
    }
    return jj;
}

fn appendClamped(buffer: []u8, length: *usize, text: []const u8) void {
    if (length.* + 1 >= buffer.len) {
        return;
    }
    const n = @min(text.len, buffer.len - 1 - length.*);
    @memcpy(buffer[length.*..][0..n], text[0..n]);
    length.* += n;
    buffer[length.*] = 0;
}

/// Writes the whole listing of the currently selected program to the open file.
/// A modified copy of the PEM display walk, so the two step-by-step listings
/// stay recognisably the same shape.
pub fn programExportListing() void {
    // The error-message buffer is unusable during a disk write, so the staged
    // line lives in a local of its own.
    var ascii_string: [448]u8 = undefined;
    var line_number_text: [30]u8 = undefined;
    const number_of_steps = runtime.numberOfSteps();

    runtime.firstDisplayedLocalStepNumber = 0;
    runtime.defineFirstStep();

    var step = runtime.firstDisplayedStep;
    runtime.programListEnd = false;
    runtime.lastProgramListEnd = false;

    var first_line: u16 = 0;
    if (runtime.firstDisplayedLocalStepNumber == 0) {
        var header: [TMP_HEADER_LENGTH]u8 = undefined;
        const text = std.fmt.bufPrint(&header, "0000: {{ Prgm #{d}/{d}: {d} bytes / {d} step{s} }}", .{
            runtime.currentProgramNumber,
            runtime.numberOfPrograms,
            runtime.programSize(),
            number_of_steps,
            if (number_of_steps == 1) "" else "s",
        }) catch header[0..0];
        runtime.tmpStringSet(text);
        runtime.tmpStringAppend(" \\par");
        runtime.tmpStringAppend("\n");
        runtime.writeTmpString();
        first_line = 1;
    }

    var add_next_line_indent: i8 = 0;
    var last_command_found: i16 = 0;

    var line: u16 = first_line;
    while (line < 9999) : (line += 1) {
        const next = runtime.nextStep(step);

        runtime.decodeStepForExport(step);

        var indent: i8 = 2;
        var new_line = false;
        if (add_next_line_indent == 0) {
            last_command_found = findIndents(&new_line, &indent, &add_next_line_indent);
        } else {
            // Only carry the pending indent when this line is a different
            // command from the last, so a run of tests does not stair-step.
            var rubbish: i8 = 0;
            var rubbish_new_line = false;
            if (last_command_found != findIndents(&rubbish_new_line, &rubbish, &rubbish)) {
                indent +%= add_next_line_indent;
            }
            add_next_line_indent = 0;
        }

        if (indent > 0) {
            runtime.tmpStringIndent(@intCast(indent), ascii_string[0..]);
        }

        ascii_string[0] = 0;
        var ascii_length: usize = 0;

        if (new_line) {
            appendClamped(ascii_string[0..], &ascii_length, "\\par\n");
        }

        const displayed = @as(i32, runtime.firstDisplayedLocalStepNumber) + @as(i32, line);
        const numbered = std.fmt.bufPrint(&line_number_text, "{d:0>4}:  ", .{displayed}) catch line_number_text[0..0];
        appendClamped(ascii_string[0..], &ascii_length, numbered);

        appendClamped(ascii_string[0..], &ascii_length, runtime.tmpStringContent());
        appendClamped(ascii_string[0..], &ascii_length, "\\par\n");

        runtime.tmpStringToRTFInPlace(&ascii_string);
        runtime.writeTmpString();

        if (runtime.isAtEndOfProgram(step)) {
            runtime.programListEnd = true;
            if (next[0] == 255 and next[1] == 255) {
                runtime.lastProgramListEnd = true;
            }
            break;
        }
        if (step[0] == 255 and step[1] == 255) {
            runtime.programListEnd = true;
            runtime.lastProgramListEnd = true;
            break;
        }
        step = next;
    }
}

const rtf_preamble = "{\\rtf1\\ansi\\ansicpg1252\\deff0\\nouicompat{\\fonttbl{\\f0\\fnil\\fcharset0 C47__StandardFont;}}{\\pard\\sl240\\slmult1\\f0\\fs24\\lang9\\f0\\loch\n";

fn exportProgramToPath(path: c_int) void {
    const ret = runtime.openSaveProgram(path);
    if (ret != runtime.FILE_OK) {
        if (ret != runtime.FILE_CANCEL) {
            runtime.displayExportWriteError();
        }
        return;
    }

    runtime.tmpStringSet(rtf_preamble);
    runtime.writeTmpString();

    var version_line: [TMP_HEADER_LENGTH]u8 = undefined;
    const text = std.fmt.bufPrint(&version_line, "C47 Program file export: Export format version {d}, C47 program version {d}.\n", .{
        runtime.EXPORT_VERSION,
        runtime.PROGRAM_VERSION,
    }) catch version_line[0..0];
    runtime.tmpStringSet(text);
    runtime.writeTmpString();

    runtime.tmpStringSet(" \\par\n");
    runtime.writeTmpString();

    programExportListing();

    runtime.tmpStringSet("}}\n");
    runtime.writeTmpString();

    runtime.closeFile();
}

/// EXPORTP, and the per-program half of the simulator's export-all walk. With
/// the printer active and PRPROG the invoking command, the listing goes to the
/// IR printer instead of to a file.
pub fn exportProgram(label: u16, path: c_int) void {
    const saved_position = runtime.EditorPosition.save();

    if (runtime.checkPower()) {
        return;
    }

    runtime.selectProgram(label);
    if (runtime.systemFlag(runtime.FLAG_PRTACT) and runtime.lastFunction() == runtime.ITM_PRINTERPROG) {
        runtime.printProgramListing(runtime.PROG, 0);
        runtime.temporaryInformation = runtime.TI_PRINT_COMPLETE;
    } else {
        exportProgramToPath(path);
        runtime.temporaryInformation = runtime.TI_SAVED;
    }

    saved_position.restore();
}
