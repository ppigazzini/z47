// SPDX-License-Identifier: GPL-3.0-only
//
// First-pass screen of a program file, before anything is loaded, using the
// grammar tables paramTailBytes() and literalTailBytes() in the nextStep owner
// (src/c47/saveRestorePrograms.c _programFileRefused and helpers).
// It refuses a declared label name longer than MAX_LABEL_NAME_LENGTH, and any
// non-item opcode, which the in-memory walker decodes as a zero-parameter step,
// so quitting silently there would let a crafted file hide an overlong label
// behind one. A step the walker cannot otherwise decode ends the screening,
// without refusing, because scanLabelsAndPrograms() truncates the program area
// there anyway.
//
// Real-surface only: the program_serialization parity harness's fake surface
// models the pre-screen load flow and has no item table; its callers gate on
// use_fake_harness_surface, so nothing here is analyzed in that build.

const abi = @import("abi");
const runtime = @import("program_serialization_runtime.zig");

const item_t = abi.Item;

const LAST_ITEM: u32 = 2870;
const ITM_KEY: u16 = 1497;
const ITM_42KEY: u16 = 2794;
// Longest label name the calculator can produce (defines.h MAX_LABEL_NAME_LENGTH).
const MAX_LABEL_NAME_LENGTH: u8 = 14;

const PTP_STATUS: u16 = 0x1e00;
const PTP_NONE: u16 = 0 << 9;
const PTP_KEYG_KEYX: u16 = 8 << 9;
const PTP_LITERAL: u16 = 13 << 9;
const PTP_REM: u16 = 14 << 9;
const PTP_DISABLED: u16 = 15 << 9;
const PARAM_NUMBER_8: u16 = 5;
const PARAM_DECLARE_LABEL: u16 = 1;

// Shared parameter-tail grammar sentinels (nextStep.h).
const PARAM_TAIL_INVALID: i16 = -1;
const PARAM_TAIL_LENGTH_PREFIXED: i16 = -2;
const PARAM_TAIL_BASE_LENGTH_PREFIXED: i16 = -3;

extern const indexOfItems: [LAST_ITEM + 1]item_t;
extern fn paramTailBytes(paramMode: u16, op: u16, opParam: u8) i16;
extern fn literalTailBytes(literalType: u8) i16;

fn readFileProgramByte(remaining: *u32, value: *u8) bool {
    var buffer: [256]u8 = undefined; // one program byte per line
    if (remaining.* == 0) {
        return false;
    }
    runtime.readLine(buffer[0..]);
    value.* = runtime.parseU8Line(buffer[0..].ptr);
    remaining.* -= 1;
    return true;
}

fn skipFileProgramBytes(remaining: *u32, count_in: u32) bool {
    var count = count_in;
    var value: u8 = undefined;
    while (count > 0) : (count -= 1) {
        if (!readFileProgramByte(remaining, &value)) {
            return false;
        }
    }
    return true;
}

// Consumes one step; returns false at end of stream, on an undecodable step, or with refuse.* set.
// allowKeyParam limits the embedded second parameter of KEY and 42KEY to one level, exactly like findNextStep().
fn screenFileStep(remaining: *u32, refuse: *bool, allowKeyParam: bool) bool {
    var byte: u8 = undefined;
    var length: u8 = undefined;
    var tail: i16 = undefined;
    var declaredLabel = false;

    if (!readFileProgramByte(remaining, &byte)) {
        return false;
    }
    var op: u16 = byte;
    if (byte & 0x80 != 0) {
        if (!readFileProgramByte(remaining, &byte)) {
            return false;
        }
        op = (@as(u16, op & 0x7f) << 8) | byte;
    }
    if (op == 0x7fff) { // .END.
        return false;
    }
    if (op >= LAST_ITEM) { // non-item opcode: only a corrupt or crafted file contains one
        refuse.* = true;
        return false;
    }

    const ptp: u16 = indexOfItems[op].status & PTP_STATUS;
    if (ptp == PTP_NONE or ptp == PTP_DISABLED) {
        tail = 0;
    } else if (ptp == PTP_LITERAL or ptp == PTP_REM) {
        if (!readFileProgramByte(remaining, &byte)) { // literal type
            return false;
        }
        tail = literalTailBytes(byte);
        if (tail == PARAM_TAIL_BASE_LENGTH_PREFIXED) {
            if (!readFileProgramByte(remaining, &byte)) { // base
                return false;
            }
            tail = PARAM_TAIL_LENGTH_PREFIXED;
        }
    } else {
        const paramMode: u16 = if (ptp == PTP_KEYG_KEYX) PARAM_NUMBER_8 else ptp >> 9;
        if (!readFileProgramByte(remaining, &byte)) { // first parameter byte
            return false;
        }
        tail = paramTailBytes(paramMode, op, byte);
        declaredLabel = (paramMode == PARAM_DECLARE_LABEL); // its length-prefixed tails are exactly the named-label forms
    }

    var ok: bool = undefined;
    if (tail == PARAM_TAIL_INVALID) {
        return false;
    } else if (tail == PARAM_TAIL_LENGTH_PREFIXED) {
        if (!readFileProgramByte(remaining, &length)) {
            return false;
        }
        if (declaredLabel and length > MAX_LABEL_NAME_LENGTH) { // the check this screen exists for
            refuse.* = true;
            return false;
        }
        ok = skipFileProgramBytes(remaining, length);
    } else {
        ok = skipFileProgramBytes(remaining, @intCast(tail));
    }
    if (ok and allowKeyParam and (op == ITM_KEY or op == ITM_42KEY)) {
        return screenFileStep(remaining, refuse, false);
    }
    return ok;
}

pub fn programFileRefused(pgmSizeInByte: u32) bool {
    var remaining: u32 = pgmSizeInByte;
    var refuse = false;
    while (remaining > 0 and screenFileStep(&remaining, &refuse, true)) {}
    return refuse;
}
