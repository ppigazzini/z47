const selectors_coordinator = @import("math_arithmetic_dispatch_selectors_coordinator_owned.zig");

pub fn tryRemainingAdd() bool {
    return selectors_coordinator.tryRemainingAdd();
}

pub fn tryRemainingSubtract() bool {
    return selectors_coordinator.tryRemainingSubtract();
}

pub fn tryRemainingMultiply() bool {
    return selectors_coordinator.tryRemainingMultiply();
}

pub fn tryRemainingDivideDispatch() bool {
    return selectors_coordinator.tryRemainingDivideDispatch();
}
