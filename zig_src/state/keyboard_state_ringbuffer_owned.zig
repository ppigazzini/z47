// SPDX-License-Identifier: GPL-3.0-only
//
// DMCP internal key ring buffer — Zig owner for the `#if defined(DMCP_BUILD)`
// ring buffer in src/c47/c47Extensions/keyboardTweak.c (1073-1403). Porting it
// (plus keyBuffer_pop and the btn entry handlers) was part of retiring the
// keyboard_state_legacy.c bridge, which brought product first-party C to 0.
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
const builtin = @import("builtin");

const is_dmcp_build = builtin.target.os.tag == .freestanding;

// CALCMODEL == USER_R47 for the firmware build this object is linked into. Only
// keyBuffer_pop's convertKeyCode remap depends on it: the upstream
// `#if CALCMODEL == USER_R47` is a compile-time model gate, and the keyboard-state
// object is shared between a board's C47 and R47 builds, so it is threaded as a
// build option (true for dmcpr47 / dmcp5r47).
const build_options = @import("keyboard_state_build_options");
pub const built_for_r47: bool = build_options.is_r47;

// key_pop is a DMCP ROM function-table macro (lft_ifc.h, LIBRARY_FN_BASE + 392);
// keyBuffer_pop drains it on firmware only. convertKeyCode is the (Zig-owned,
// frontier-exported) DM42 key remap, applied before buffering on R47 builds.
const LIBRARY_FN_BASE: usize = if (builtin.target.cpu.model == &std.Target.arm.cpu.cortex_m4) 0x08000201 else 0x08000301;
fn romKeyPop() c_int {
    const f: *const fn () callconv(.c) c_int = @ptrFromInt(LIBRARY_FN_BASE + 392);
    return f();
}
extern fn convertKeyCode(key: c_int) c_int;

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
var buffer: KeyBuffer = .{};

// C-ABI wrappers matching the keyboardTweak.h prototypes exactly (bool_t = bool;
// the BUFFER_CLICK_DETECTION-off outKeyBuffer takes a single uint8_t*, and
// outKeyBufferDoubleClick is the `#else` stub returning 255). @export'd onto the
// DMCP lanes below; the bridge renames the upstream C copies away so these win.
fn c_inKeyBuffer(byte: u8) callconv(.c) u8 {
    return buffer.push(byte);
}
fn c_outKeyBuffer(p_byte: [*c]u8) callconv(.c) u8 {
    var k: u8 = undefined;
    const result = buffer.pop(&k);
    if (result == BUFFER_SUCCESS) p_byte[0] = k;
    return result;
}
fn c_outKeyBufferDoubleClick() callconv(.c) u8 {
    return 255; // BUFFER_CLICK_DETECTION off -> the `#else` stub
}
fn c_fullKeyBuffer() callconv(.c) bool {
    return buffer.full();
}
fn c_emptyKeyBuffer() callconv(.c) bool {
    return buffer.empty();
}
fn c_clearKeyBuffer() callconv(.c) void {
    buffer.clear();
}
// The keyBuffer_pop drain loop, factored out of c_keyBuffer_pop so it can be
// EXECUTED and asserted on host: the firmware path (romKeyPop via the DMCP ROM
// table) is otherwise never run anywhere. popFn and convertFn are comptime
// parameters, so each instantiation inlines them directly -- the firmware
// instantiation (romKeyPop + the R47 convertKeyCode) is byte-identical to the
// previous inline loop, while the tests below instantiate it over a scripted
// key source. Drains popFn into buf until it returns < 0 OR buf is full,
// applying convertFn (the R47 key remap) first when non-null, and dropping a
// key equal to the previous one (the KeyBuffer.push duplicate suppression).
fn drainKeys(
    buf: *KeyBuffer,
    comptime popFn: fn () c_int,
    comptime convertFn: ?fn (c_int) callconv(.c) c_int,
) void {
    var tmp_key: c_int = undefined;
    while (true) {
        tmp_key = -1;
        if (!buf.full()) {
            tmp_key = popFn();
            if (convertFn) |cf| tmp_key = cf(tmp_key);
            if (tmp_key >= 0) _ = buf.push(@intCast(tmp_key));
        }
        if (tmp_key < 0) break;
    }
}

fn c_keyBuffer_pop() callconv(.c) void {
    drainKeys(&buffer, romKeyPop, if (built_for_r47) convertKeyCode else null);
}

// Export the upstream symbol names on the DMCP lanes only (the buffer is
// `#if defined(DMCP_BUILD)`; the host sim has no key ring buffer).
comptime {
    if (is_dmcp_build) {
        @export(&c_inKeyBuffer, .{ .name = "inKeyBuffer" });
        @export(&c_outKeyBuffer, .{ .name = "outKeyBuffer" });
        @export(&c_outKeyBufferDoubleClick, .{ .name = "outKeyBufferDoubleClick" });
        @export(&c_fullKeyBuffer, .{ .name = "fullKeyBuffer" });
        @export(&c_emptyKeyBuffer, .{ .name = "emptyKeyBuffer" });
        @export(&c_clearKeyBuffer, .{ .name = "clearKeyBuffer" });
        @export(&c_keyBuffer_pop, .{ .name = "keyBuffer_pop" });
    }
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

// A scripted stand-in for the DMCP ROM key_pop: yields the next queued code,
// then -1 (no more keys) -- exactly the ROM contract keyBuffer_pop drains.
const ScriptedRom = struct {
    var queue: []const c_int = &.{};
    var idx: usize = 0;
    fn load(codes: []const c_int) void {
        queue = codes;
        idx = 0;
    }
    fn pop() c_int {
        if (idx >= queue.len) return -1;
        defer idx += 1;
        return queue[idx];
    }
};

fn plusOne(key: c_int) callconv(.c) c_int {
    // Stand-in for the R47 convertKeyCode remap. It MUST pass negatives through
    // unchanged: the real convertKeyCode only switches on specific positive key
    // codes (else-> unchanged), so the key_pop() "no key" sentinel (-1) survives
    // the remap and still terminates the drain. A remap that mapped -1 to a
    // non-negative value would make both the firmware and this loop spin forever.
    return if (key < 0) key else key + 1;
}

test "drainKeys: ROM keys buffered, consecutive duplicate suppressed, -1 ends" {
    ScriptedRom.load(&.{ 5, 5, 6, -1 });
    var b: KeyBuffer = .{};
    drainKeys(&b, ScriptedRom.pop, null);
    var k: u8 = 0;
    try std.testing.expectEqual(BUFFER_SUCCESS, b.pop(&k));
    try std.testing.expectEqual(@as(u8, 5), k);
    try std.testing.expectEqual(BUFFER_SUCCESS, b.pop(&k));
    try std.testing.expectEqual(@as(u8, 6), k); // the second 5 was dup-suppressed
    try std.testing.expect(b.empty());
}

test "drainKeys: convertFn (R47 remap) is applied before buffering" {
    ScriptedRom.load(&.{ 10, 20, -1 });
    var b: KeyBuffer = .{};
    drainKeys(&b, ScriptedRom.pop, plusOne);
    var k: u8 = 0;
    try std.testing.expectEqual(BUFFER_SUCCESS, b.pop(&k));
    try std.testing.expectEqual(@as(u8, 11), k);
    try std.testing.expectEqual(BUFFER_SUCCESS, b.pop(&k));
    try std.testing.expectEqual(@as(u8, 21), k);
    try std.testing.expect(b.empty());
}

test "drainKeys: stops at buffer-full (capacity 7), leaving excess keys in ROM" {
    // 10 distinct keys, never -1: the drain fills 7 then the full-guard breaks,
    // holding 8/9/10 in the ROM (the firmware "keep key in DM42 buffer" path).
    ScriptedRom.load(&.{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 });
    var b: KeyBuffer = .{};
    drainKeys(&b, ScriptedRom.pop, null);
    try std.testing.expect(b.full());
    try std.testing.expectEqual(@as(usize, 7), ScriptedRom.idx); // only 7 popped
    var expected: u8 = 1;
    while (expected <= 7) : (expected += 1) {
        var k: u8 = 0;
        try std.testing.expectEqual(BUFFER_SUCCESS, b.pop(&k));
        try std.testing.expectEqual(expected, k);
    }
    try std.testing.expect(b.empty());
}

test "module-level C wrappers operate on the shared firmware instance" {
    // keyBuffer_pop is excluded here: it reaches the ROM key_pop and is firmware
    // only. The buffer-manipulation wrappers carry the host-testable mechanics.
    c_clearKeyBuffer();
    try std.testing.expect(c_emptyKeyBuffer());
    try std.testing.expectEqual(BUFFER_SUCCESS, c_inKeyBuffer(77));
    try std.testing.expect(!c_emptyKeyBuffer());
    var key: u8 = 0;
    try std.testing.expectEqual(BUFFER_SUCCESS, c_outKeyBuffer(&key));
    try std.testing.expectEqual(@as(u8, 77), key);
    try std.testing.expect(c_emptyKeyBuffer());
    try std.testing.expectEqual(@as(u8, 255), c_outKeyBufferDoubleClick());
}
