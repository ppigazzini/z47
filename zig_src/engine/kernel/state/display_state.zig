// SPDX-License-Identifier: GPL-3.0-only
//
// Display state the headless engine drives: the number/fraction/time format
// parameters and calendar rules its formatting reads (the format parity oracle
// covers these), plus the transient-info and screen-update status it sets for the
// shell to render. Relocated out of the shell globals hub; symbols, types and
// initialisers are byte-identical, so every extern consumer resolves as before.

pub export var displayFormat: u8 = 0; // number display mode (SCI/ENG/FIX/ALL)
pub export var displayFormatDigits: u8 = 0; // significant/decimal digits for the display mode
pub export var timeDisplayFormatDigits: u8 = 0; // fractional-second digits for time display
pub export var dispBase: u8 = 0; // integer display base (2..16)
pub export var fractionDigits: u8 = 0; // denominator digits for fraction display
pub export var denMax: u32 = 0; // max denominator for fraction display
pub export var lastDenominator: u32 = 4; // last fraction denominator used
pub export var bcdDisplaySign: u8 = 0; // BCD display sign
pub export var firstGregorianDay: u32 = 0; // Gregorian calendar epoch
pub export var lastCenturyHighUsed: u16 = 0; // two-digit-year century pivot
pub export var firstDayOfWeek: u8 = 1; // first day of the week
pub export var firstWeekOfYearDay: u8 = 4; // first-week-of-year rule day
pub export var temporaryInformation: u8 = 0; // transient status message the shell renders
pub export var screenUpdatingMode: u8 = 0; // screen-refresh mode the engine masks (|=/&=~)
