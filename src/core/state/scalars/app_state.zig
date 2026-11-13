// SPDX-License-Identifier: GPL-3.0-only
//
// Application state the math apps read: the linear-regression model choice and
// selection the statistics/curve-fit engine reads, and the amortization period
// bounds the TVM engine reads. Defined here rather than in the shell globals hub
// (c47.zig) with c47.c's symbols, types and initialisers, so every extern
// consumer resolves to them.

pub export var lrChosen: u16 = 0; // the chosen linear-regression model
pub export var lrSelection: u16 = 0; // the linear-regression model selection bitmap
pub export var amortP1: u16 = 0; // amortization period start
pub export var amortP2: u16 = 0; // amortization period end
