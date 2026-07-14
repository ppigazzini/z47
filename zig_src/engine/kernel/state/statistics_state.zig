// SPDX-License-Identifier: GPL-3.0-only
//
// Statistics/linear-regression model state the stat and curve-fit engine
// reads.
//
// Base calculator state relocated out of the shell globals hub; symbols, types
// and initialisers are byte-identical, so every extern consumer resolves as before.

pub export var lrChosen: u16 = 0; // the chosen linear-regression model
pub export var lrSelection: u16 = 0; // the linear-regression model selection bitmap
