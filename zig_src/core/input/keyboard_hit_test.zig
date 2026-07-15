//! Click-coordinate to key hit-test -- the pure core of keyboard_state's
//! convertXYToKey.
//!
//! A mouse click is mapped to a key by scanning the 43-entry key-geometry table,
//! bounding-box testing (x, y) against each key's rectangle for the current bezel
//! (key 10 has a special enlarged rectangle in some TAM modes), and encoding the
//! matched index into one or two ASCII digit bytes. The scan and encode are pure
//! over the geometry table; the owner reads the bezel and the TAM-mode special
//! case and writes the mouse-key bytes. Lift it here for native coverage -- the
//! keyboard owner is only reachable through the C oracle.

const std = @import("std");
const abi = @import("abi");

/// The matched key encoded as up to two ASCII digit bytes.
pub const KeyHit = struct {
    b0: u8,
    b1: u8,
    matched: bool,
};

/// Hit-test (x, y) against the 43 keys. `bezel` selects the rectangle size;
/// `key10_special` forces key 10's enlarged (bezel-3) rectangle.
pub fn convertXYToKey(keyboard: []const abi.CalcKeyboard, x: c_int, y: c_int, bezel: c_int, key10_special: bool) KeyHit {
    var i: usize = 0;
    while (i < 43) : (i += 1) {
        const x_min = keyboard[i].x;
        const y_min = keyboard[i].y;
        var x_max: c_int = undefined;
        var y_max: c_int = undefined;
        if (i == 10 and key10_special) {
            x_max = x_min + keyboard[10].width[3];
            y_max = y_min + keyboard[10].height[3];
        } else {
            x_max = x_min + keyboard[i].width[@intCast(bezel)];
            y_max = y_min + keyboard[i].height[@intCast(bezel)];
        }
        if (x_min <= x and x <= x_max and y_min <= y and y <= y_max) {
            if (i < 6) {
                return .{ .b0 = @intCast(@as(usize, '1') + i), .b1 = 0, .matched = true };
            }
            return .{
                .b0 = @intCast(@as(usize, '0') + (i - 6) / 10),
                .b1 = @intCast(@as(usize, '0') + (i - 6) % 10),
                .matched = true,
            };
        }
    }
    return .{ .b0 = 0, .b1 = 0, .matched = false };
}

fn makeKeyboard() [43]abi.CalcKeyboard {
    var kb: [43]abi.CalcKeyboard = undefined;
    for (&kb) |*k| k.* = std.mem.zeroes(abi.CalcKeyboard);
    kb[0].x = 10;
    kb[0].y = 10;
    kb[0].width[0] = 5;
    kb[0].height[0] = 5;
    kb[8].x = 100;
    kb[8].y = 100;
    kb[8].width[0] = 5;
    kb[8].height[0] = 5;
    kb[10].x = 200;
    kb[10].y = 200;
    kb[10].width[0] = 2;
    kb[10].height[0] = 2;
    kb[10].width[3] = 20;
    kb[10].height[3] = 20;
    return kb;
}

test "a click in one of the first six keys encodes a single digit" {
    const kb = makeKeyboard();
    const hit = convertXYToKey(&kb, 12, 12, 0, false);
    // key 0 -> '1', single digit.
    try std.testing.expectEqual(KeyHit{ .b0 = '1', .b1 = 0, .matched = true }, hit);
}

test "a click in a later key encodes two digits" {
    const kb = makeKeyboard();
    const hit = convertXYToKey(&kb, 102, 102, 0, false);
    // key 8 -> (8-6)=2 -> '0','2'.
    try std.testing.expectEqual(@as(u8, '0'), hit.b0);
    try std.testing.expectEqual(@as(u8, '2'), hit.b1);
    try std.testing.expect(hit.matched);
}

test "a click outside every key does not match" {
    const kb = makeKeyboard();
    const hit = convertXYToKey(&kb, 500, 500, 0, false);
    try std.testing.expect(!hit.matched);
    try std.testing.expectEqual(@as(u8, 0), hit.b0);
}

test "key 10's special rectangle only applies when requested" {
    const kb = makeKeyboard();
    // (210,210) is inside key 10's enlarged bezel-3 rectangle (200..220).
    try std.testing.expect(convertXYToKey(&kb, 210, 210, 0, true).matched);
    // Without the special case its bezel-0 rectangle is only 200..202, so no hit.
    try std.testing.expect(!convertXYToKey(&kb, 210, 210, 0, false).matched);
}
