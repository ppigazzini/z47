// SPDX-License-Identifier: GPL-3.0-only
//
// Number/fraction/time display-format parameters the engine's formatting reads
// (the format parity oracle covers them); the config UI sets them.
//
// Base calculator state relocated out of the shell globals hub; symbols, types
// and initialisers are byte-identical, so every extern consumer resolves as before.

pub export var displayFormat: u8 = 0; // number display mode (SCI/ENG/FIX/ALL)
pub export var displayFormatDigits: u8 = 0; // significant/decimal digits for the display mode
pub export var timeDisplayFormatDigits: u8 = 0; // fractional-second digits for time display
pub export var dispBase: u8 = 0; // integer display base (2..16)
pub export var fractionDigits: u8 = 0; // denominator digits for fraction display
pub export var denMax: u32 = 0; // max denominator for fraction display
pub export var lastDenominator: u32 = 4; // last fraction denominator used
pub export var bcdDisplaySign: u8 = 0; // BCD display sign
