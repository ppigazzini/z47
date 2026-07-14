// SPDX-License-Identifier: GPL-3.0-only
//
// Time-value-of-money state the TVM engine reads: the amortization period
// bounds.
//
// Base calculator state relocated out of the shell globals hub; symbols, types
// and initialisers are byte-identical, so every extern consumer resolves as before.

pub export var amortP1: u16 = 0; // amortization period start
pub export var amortP2: u16 = 0; // amortization period end
