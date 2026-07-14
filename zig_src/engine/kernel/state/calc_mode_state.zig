// SPDX-License-Identifier: GPL-3.0-only
//
// Calculator operating-mode state the engine reads across its computation: the
// overall mode, the angular mode, the short-integer word/sign model and the
// integer base.
//
// Base calculator state relocated out of the shell globals hub; symbols, types
// and initialisers are byte-identical, so every extern consumer resolves as before.

const angularMode_t = c_int;

pub export var calcMode: u8 = 0; // the calculator mode (CM_NORMAL/CM_BUG_ON_SCREEN/...); read in 166 sites
pub export var currentAngularMode: angularMode_t = 0; // active angular mode (amNone/amDegree/...); read across trig
pub export var shortIntegerMode: u8 = 0; // short-integer sign mode (2's complement/...)
pub export var shortIntegerMask: u64 = 0; // word-size mask derived from the mode
pub export var shortIntegerSignBit: u64 = 0; // sign-bit mask derived from the mode
pub export var shortIntegerWordSize: u8 = 0; // short-integer word size in bits
pub export var lastIntegerBase: u32 = 0; // last integer base (2..16)
