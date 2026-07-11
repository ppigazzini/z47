//! Saved-register mapping -- the pure core of stack_undo's savedRegisterFor.
//!
//! Each live stack register has a saved-shadow register a fixed offset away
//! (SAVED_REGISTER_X - REGISTER_X). Mapping a live register to its shadow is a
//! pure offset bijection. Lift it here for native coverage -- the stack-undo
//! owner is only reachable through the C oracle.

const std = @import("std");

/// The saved-shadow register for a live register, given the fixed
/// saved-minus-live `offset`.
pub fn savedRegisterFor(reg: i16, offset: i16) i16 {
    return offset + reg;
}

test "savedRegisterFor shifts by the fixed offset" {
    // SAVED_REGISTER_X (126) - REGISTER_X (100) = 26.
    try std.testing.expectEqual(@as(i16, 126), savedRegisterFor(100, 26));
    try std.testing.expectEqual(@as(i16, 129), savedRegisterFor(103, 26));
}
