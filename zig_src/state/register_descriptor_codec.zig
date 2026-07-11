//! Register descriptor bit-field codec -- the pure core of
//! register_metadata_descriptor.zig.
//!
//! Each register's metadata is packed into a 32-bit descriptor: the memory
//! pointer in bits 0..15, the data type in bits 16..19, and the tag in bits
//! 20..24. Reading a field and rewriting a field are pure mask/shift bijections
//! over that word; the descriptor owner adds the register-band dispatch and the
//! global reads/writes around them.
//!
//! Lifting the codec here gives the pack/unpack its first native coverage -- the
//! descriptor owner is only reachable through the C oracle. The owner keeps thin
//! wrappers so its many call sites are unchanged.

const std = @import("std");

/// The 32-bit register descriptor word (register_descriptor_t).
pub const Descriptor = u32;

const pointer_mask: Descriptor = 0x0000ffff;
const data_type_mask: Descriptor = 0x000f0000;
const tag_mask: Descriptor = 0x01f00000;
const data_type_shift: u5 = 16;
const tag_shift: u5 = 20;

/// The data-type field (bits 16..19).
pub fn dataType(descriptor: Descriptor) u32 {
    return (descriptor & data_type_mask) >> data_type_shift;
}

/// The tag field (bits 20..24).
pub fn tag(descriptor: Descriptor) u32 {
    return (descriptor & tag_mask) >> tag_shift;
}

/// The memory-pointer field (bits 0..15).
pub fn pointer(descriptor: Descriptor) u16 {
    return @intCast(descriptor & pointer_mask);
}

/// `descriptor` with the data-type and tag fields replaced.
pub fn withDataTypeTag(descriptor: Descriptor, data_type: u16, new_tag: u32) Descriptor {
    return (descriptor & ~(data_type_mask | tag_mask)) |
        ((@as(Descriptor, data_type) & 0xf) << data_type_shift) |
        ((new_tag & 0x1f) << tag_shift);
}

/// `descriptor` with the tag field replaced.
pub fn withTag(descriptor: Descriptor, new_tag: u32) Descriptor {
    return (descriptor & ~tag_mask) | ((new_tag & 0x1f) << tag_shift);
}

/// `descriptor` with the memory-pointer field replaced.
pub fn withPointer(descriptor: Descriptor, mem_ptr: u16) Descriptor {
    return (descriptor & ~pointer_mask) | @as(Descriptor, mem_ptr);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

test "fields unpack from their bit ranges" {
    // tag 0x1a (bits 20..24), data type 0xb (bits 16..19), pointer 0x1234.
    const d: Descriptor = (0x1a << 20) | (0xb << 16) | 0x1234;
    try std.testing.expectEqual(@as(u32, 0xb), dataType(d));
    try std.testing.expectEqual(@as(u32, 0x1a), tag(d));
    try std.testing.expectEqual(@as(u16, 0x1234), pointer(d));
}

test "withPointer replaces only the low 16 bits" {
    const d: Descriptor = 0x01bf_ffff;
    const r = withPointer(d, 0x00aa);
    try std.testing.expectEqual(@as(u16, 0x00aa), pointer(r));
    // The data-type and tag fields are preserved.
    try std.testing.expectEqual(dataType(d), dataType(r));
    try std.testing.expectEqual(tag(d), tag(r));
}

test "withTag replaces only the tag field and masks to five bits" {
    const d: Descriptor = 0;
    const r = withTag(d, 0xff); // 0xff masked to 0x1f
    try std.testing.expectEqual(@as(u32, 0x1f), tag(r));
    try std.testing.expectEqual(@as(u32, 0), dataType(r));
    try std.testing.expectEqual(@as(u16, 0), pointer(r));
}

test "withDataTypeTag replaces both fields, masks, and preserves the pointer" {
    const d: Descriptor = 0x0000_5678;
    const r = withDataTypeTag(d, 0x1f, 0x3f); // data type masked to 0xf, tag to 0x1f
    try std.testing.expectEqual(@as(u32, 0xf), dataType(r));
    try std.testing.expectEqual(@as(u32, 0x1f), tag(r));
    try std.testing.expectEqual(@as(u16, 0x5678), pointer(r));
}

test "pack then unpack round-trips every field" {
    var d: Descriptor = 0;
    d = withPointer(d, 0xbeef);
    d = withDataTypeTag(d, 0x9, 0x15);
    try std.testing.expectEqual(@as(u16, 0xbeef), pointer(d));
    try std.testing.expectEqual(@as(u32, 0x9), dataType(d));
    try std.testing.expectEqual(@as(u32, 0x15), tag(d));
}
