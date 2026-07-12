const std = @import("std");

fn rangeExceedsLimit(start: u16, count: u16, exclusive_upper_bound: u16) bool {
    return @as(u32, start) + @as(u32, count) >= @as(u32, exclusive_upper_bound);
}

fn resolveRegisterRange(start: u16, count: *u16, exclusive_upper_bound: u16, error_out_of_range: u8, error_none: u8) u8 {
    if (rangeExceedsLimit(start, count.*, exclusive_upper_bound)) {
        return error_out_of_range;
    }

    if (count.* == 0) {
        count.* = exclusive_upper_bound - start;
    }

    return error_none;
}

pub fn validateRegisterSourceRange(
    load_into_memory: ?bool,
    start: u16,
    count: *u16,
    register_x: u16,
    first_local_register: u16,
    current_local_register_count: u16,
    error_out_of_range: u8,
    error_none: u8,
) u8 {
    const local_limit = first_local_register + current_local_register_count;

    if (start < register_x) {
        return resolveRegisterRange(start, count, register_x, error_out_of_range, error_none);
    }

    if (start < first_local_register) {
        return resolveRegisterRange(start, count, first_local_register, error_out_of_range, error_none);
    }

    if (start < local_limit) {
        if (load_into_memory != null and load_into_memory.?) {
            return error_out_of_range;
        }

        return resolveRegisterRange(start, count, local_limit, error_out_of_range, error_none);
    }

    return error_out_of_range;
}

pub fn validateRegisterDestinationRange(
    start: u16,
    count: u16,
    register_x: u16,
    first_local_register: u16,
    current_local_register_count: u16,
    error_out_of_range: u8,
    error_none: u8,
) u8 {
    const local_limit = first_local_register + current_local_register_count;

    if (start < register_x) {
        return if (rangeExceedsLimit(start, count, register_x)) error_out_of_range else error_none;
    }

    if (start < first_local_register) {
        return if (rangeExceedsLimit(start, count, first_local_register)) error_out_of_range else error_none;
    }

    if (start < local_limit) {
        return if (rangeExceedsLimit(start, count, local_limit)) error_out_of_range else error_none;
    }

    return error_out_of_range;
}

// Native unit tests (REPORT-27 M-IDIOM-3). Pure register-range validation; no C
// oracle, no global state. Fixture: register_x=112, first_local=1000, 8 locals
// (local_limit=1008), OOR=1 / NONE=0.
const testing = std.testing;
const OOR: u8 = 1;
const NONE: u8 = 0;

test "validateRegisterSourceRange" {
    var c: u16 = 5;
    try testing.expectEqual(NONE, validateRegisterSourceRange(false, 0, &c, 112, 1000, 8, OOR, NONE));
    c = 0;
    try testing.expectEqual(NONE, validateRegisterSourceRange(false, 0, &c, 112, 1000, 8, OOR, NONE));
    try testing.expectEqual(@as(u16, 112), c); // count auto-filled to register_x - start
    c = 5;
    try testing.expectEqual(OOR, validateRegisterSourceRange(false, 110, &c, 112, 1000, 8, OOR, NONE));
    c = 2;
    try testing.expectEqual(OOR, validateRegisterSourceRange(true, 1002, &c, 112, 1000, 8, OOR, NONE)); // load into local block
    c = 2;
    try testing.expectEqual(NONE, validateRegisterSourceRange(false, 1002, &c, 112, 1000, 8, OOR, NONE));
    c = 1;
    try testing.expectEqual(OOR, validateRegisterSourceRange(false, 2000, &c, 112, 1000, 8, OOR, NONE));
}

test "validateRegisterDestinationRange" {
    try testing.expectEqual(NONE, validateRegisterDestinationRange(0, 5, 112, 1000, 8, OOR, NONE));
    try testing.expectEqual(OOR, validateRegisterDestinationRange(110, 5, 112, 1000, 8, OOR, NONE));
    try testing.expectEqual(NONE, validateRegisterDestinationRange(500, 3, 112, 1000, 8, OOR, NONE));
    try testing.expectEqual(OOR, validateRegisterDestinationRange(2000, 1, 112, 1000, 8, OOR, NONE));
}
