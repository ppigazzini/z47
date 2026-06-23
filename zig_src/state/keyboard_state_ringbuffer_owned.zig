// SPDX-License-Identifier: GPL-3.0-only
//
// DMCP internal key ring buffer — Zig owner for the `#if defined(DMCP_BUILD)`
// ring buffer in src/c47/c47Extensions/keyboardTweak.c (1073-1403). This is the
// last firmware-only keyboard subsystem still served by the keyboard_state_legacy.c
// bridge; porting it (plus keyBuffer_pop and the btn entry handlers) clears the
// bridge for deletion (product first-party C 1 -> 0).
//
// The compiled buffer is the SIMPLE variant: the upstream BUFFER_CLICK_DETECTION
// and BUFFER_KEY_COUNT options are `#define`d then immediately `#undef`d
// (defines.h:409-413), so the time[] array, double-click detection and key-count
// paths are all compiled out. Verified against the actual DMCP preprocessor.
// kb_buffer_t therefore reduces to { data[8], read, write } with BUFFER_SIZE 8.
//
// keyBuffer_pop (the key_pop() drain, with its CALCMODEL==USER_R47 convertKeyCode
// remap) is intentionally NOT here yet: it needs the ROM key_pop trampoline and a
// per-model build signal, which is wired when the keyboard-state firmware object
// is split per calc model. The pure buffer mechanics below carry the whole
// risk surface (index wrap, full/empty edges, duplicate suppression) and are
// covered by the embedded tests (`zig build keyboard_ringbuffer_test`).
const std = @import("std");

// CALCMODEL == USER_R47 for the firmware build this object is linked into. Only
// keyBuffer_pop's convertKeyCode remap depends on it (a later slice); exposed now
// so the per-model build-option plumbing is exercised on every lane.
const build_options = @import("keyboard_state_build_options");
pub const built_for_r47: bool = build_options.is_r47;

// keyboardTweak.h: BUFFER_SIZE 8 (must be 2^n), BUFFER_MASK = BUFFER_SIZE - 1,
// BUFFER_FAIL = 0, BUFFER_SUCCESS = 1.
const BUFFER_SIZE: u8 = 8;
const BUFFER_MASK: u8 = BUFFER_SIZE - 1;
pub const BUFFER_FAIL: u8 = 0;
pub const BUFFER_SUCCESS: u8 = 1;

// kb_buffer_t (keyboardTweak.h, BUFFER_CLICK_DETECTION off): `read` points at the
// oldest stored byte, `write` always points at an empty slot. A full buffer keeps
// one slot empty, so capacity is BUFFER_SIZE - 1 = 7 bytes.
pub const KeyBuffer = struct {
    data: [BUFFER_SIZE]u8 = [_]u8{0} ** BUFFER_SIZE,
    read: u8 = 0,
    write: u8 = 0,

    // fullKeyBuffer(): true when one more write would collide with read.
    pub fn full(self: *const KeyBuffer) bool {
        return self.read == ((self.write +% 1) & BUFFER_MASK);
    }

    // emptyKeyBuffer(): true when read has caught up to write.
    pub fn empty(self: *const KeyBuffer) bool {
        return self.read == self.write;
    }

    // clearKeyBuffer(): drop everything by collapsing read onto write.
    pub fn clear(self: *KeyBuffer) void {
        self.read = self.write;
    }

    // inKeyBuffer(byte): store one byte. Returns BUFFER_FAIL on full OR when the
    // byte equals the previously written one (upstream's "only key changes
    // stored" suppression — note this also drops a byte that equals the stale
    // zero already in the slot behind `write`, faithfully reproduced).
    pub fn push(self: *KeyBuffer, byte: u8) u8 {
        const next = (self.write +% 1) & BUFFER_MASK;
        if (self.read == next) {
            return BUFFER_FAIL; // full
        }
        if (self.data[(self.write -% 1) & BUFFER_MASK] == byte) {
            return BUFFER_FAIL; // duplicate
        }
        self.data[self.write & BUFFER_MASK] = byte;
        self.write = next;
        return BUFFER_SUCCESS;
    }

    // outKeyBuffer(pKey): fetch one byte. Returns BUFFER_FAIL when empty.
    pub fn pop(self: *KeyBuffer, p_key: *u8) u8 {
        if (self.read == self.write) {
            return BUFFER_FAIL; // empty
        }
        p_key.* = self.data[self.read];
        self.read = (self.read +% 1) & BUFFER_MASK;
        return BUFFER_SUCCESS;
    }
};

// The single firmware instance (keyboardTweak.c: `kb_buffer_t buffer = {{}, 0, 0}`).
// The thin `pub fn` wrappers below mirror the upstream symbol names and are the
// surface the export wiring will bind once the bridge copies are renamed.
var buffer: KeyBuffer = .{};

pub fn inKeyBuffer(byte: u8) u8 {
    return buffer.push(byte);
}
pub fn outKeyBuffer(p_key: *u8) u8 {
    return buffer.pop(p_key);
}
pub fn fullKeyBuffer() bool {
    return buffer.full();
}
pub fn emptyKeyBuffer() bool {
    return buffer.empty();
}
pub fn clearKeyBuffer() void {
    buffer.clear();
}

// ---------------------------------------------------------------------------
// Tests — exercise the index wrap, full/empty edges and duplicate suppression
// that a firmware off-by-one would silently corrupt (the host testSuite cannot
// reach this `#if DMCP_BUILD` code).
// ---------------------------------------------------------------------------
test "empty buffer: empty()=true, pop()=FAIL, full()=false" {
    var b: KeyBuffer = .{};
    try std.testing.expect(b.empty());
    try std.testing.expect(!b.full());
    var key: u8 = 0xAA;
    try std.testing.expectEqual(BUFFER_FAIL, b.pop(&key));
    try std.testing.expectEqual(@as(u8, 0xAA), key); // untouched on FAIL
}

test "single push/pop round-trips the byte and returns to empty" {
    var b: KeyBuffer = .{};
    try std.testing.expectEqual(BUFFER_SUCCESS, b.push(42));
    try std.testing.expect(!b.empty());
    var key: u8 = 0;
    try std.testing.expectEqual(BUFFER_SUCCESS, b.pop(&key));
    try std.testing.expectEqual(@as(u8, 42), key);
    try std.testing.expect(b.empty());
}

test "capacity is BUFFER_SIZE-1 (=7) distinct bytes; the 8th push FAILs (full)" {
    var b: KeyBuffer = .{};
    // 1..7 are distinct and non-zero (avoids the stale-zero duplicate edge).
    var i: u8 = 1;
    while (i <= 7) : (i += 1) {
        try std.testing.expectEqual(BUFFER_SUCCESS, b.push(i));
    }
    try std.testing.expect(b.full());
    try std.testing.expectEqual(BUFFER_FAIL, b.push(8)); // full, byte lost
    // FIFO drain preserves order 1..7.
    var expected: u8 = 1;
    while (expected <= 7) : (expected += 1) {
        var key: u8 = 0;
        try std.testing.expectEqual(BUFFER_SUCCESS, b.pop(&key));
        try std.testing.expectEqual(expected, key);
    }
    try std.testing.expect(b.empty());
}

test "consecutive duplicate byte is suppressed; an interleaved change is stored" {
    var b: KeyBuffer = .{};
    try std.testing.expectEqual(BUFFER_SUCCESS, b.push(5));
    try std.testing.expectEqual(BUFFER_FAIL, b.push(5)); // duplicate of last write
    try std.testing.expectEqual(BUFFER_SUCCESS, b.push(6));
    try std.testing.expectEqual(BUFFER_SUCCESS, b.push(5)); // change again -> stored
    var key: u8 = 0;
    try std.testing.expectEqual(BUFFER_SUCCESS, b.pop(&key));
    try std.testing.expectEqual(@as(u8, 5), key);
    try std.testing.expectEqual(BUFFER_SUCCESS, b.pop(&key));
    try std.testing.expectEqual(@as(u8, 6), key);
    try std.testing.expectEqual(BUFFER_SUCCESS, b.pop(&key));
    try std.testing.expectEqual(@as(u8, 5), key);
    try std.testing.expect(b.empty());
}

test "read/write indices wrap correctly across the 8-slot boundary" {
    var b: KeyBuffer = .{};
    // Push/pop 20 alternating distinct bytes so write and read each wrap twice.
    var n: u8 = 0;
    var last: u8 = 0;
    while (n < 20) : (n += 1) {
        const byte: u8 = if (n & 1 == 0) 100 else 101; // alternate so never duplicate
        try std.testing.expectEqual(BUFFER_SUCCESS, b.push(byte));
        var key: u8 = 0;
        try std.testing.expectEqual(BUFFER_SUCCESS, b.pop(&key));
        try std.testing.expectEqual(byte, key);
        last = byte;
    }
    try std.testing.expect(b.empty());
    // Indices stayed masked to 0..7 throughout.
    try std.testing.expect(b.read < BUFFER_SIZE and b.write < BUFFER_SIZE);
}

test "clear() empties a partially-filled buffer" {
    var b: KeyBuffer = .{};
    _ = b.push(11);
    _ = b.push(12);
    try std.testing.expect(!b.empty());
    b.clear();
    try std.testing.expect(b.empty());
    var key: u8 = 0;
    try std.testing.expectEqual(BUFFER_FAIL, b.pop(&key));
}

test "module-level wrappers operate on the shared firmware instance" {
    clearKeyBuffer();
    try std.testing.expect(emptyKeyBuffer());
    try std.testing.expectEqual(BUFFER_SUCCESS, inKeyBuffer(77));
    try std.testing.expect(!emptyKeyBuffer());
    var key: u8 = 0;
    try std.testing.expectEqual(BUFFER_SUCCESS, outKeyBuffer(&key));
    try std.testing.expectEqual(@as(u8, 77), key);
    try std.testing.expect(emptyKeyBuffer());
}
