// SPDX-License-Identifier: GPL-3.0-only
//
// Application state the math apps read: the linear-regression model choice and
// selection the statistics/curve-fit engine reads, and the amortization period
// bounds the TVM engine reads. Relocated out of the shell globals hub; symbols,
// types and initialisers are unchanged, so every extern consumer resolves as before.

pub export var lrChosen: u16 = 0; // the chosen linear-regression model
pub export var lrSelection: u16 = 0; // the linear-regression model selection bitmap
pub export var amortP1: u16 = 0; // amortization period start
pub export var amortP2: u16 = 0; // amortization period end
